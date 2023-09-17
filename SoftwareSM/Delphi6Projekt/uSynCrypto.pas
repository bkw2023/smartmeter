unit uSynCrypto;

interface

{$A+} // force normal alignment
{$H+} // we use long strings
{$R-} // disable Range checking in our code
{$S-} // disable Stack checking in our code
{$X+} // expect extended syntax
{$W-} // disable stack frame generation
{$Q-} // disable overflow checking in our code
{$B-} // expect short circuit boolean
{$V-} // disable Var-String Checking
{$T-} // Typed @ operator
{$Z1} // enumerators stored as byte by default
{$P+} // Open string params

uses
  Windows, SysUtils, RTLConsts, Classes;

const
  /// hide all AES Context complex code
  AESContextSize = 276+sizeof(pointer)+sizeof(pointer);
  /// power of two for a standard AES block size during cypher/uncypher
  // - to be used as 1 shl AESBlockShift or 1 shr AESBlockShift for fast div/mod
  AESBlockShift = 4;
  /// bit mask for fast modulo of AES block size
  AESBlockMod = 15;

type
  PtrInt = integer;
  PtrUInt = cardinal;
  QWord = Int64;

  TCardinalArray = array[0..MaxInt div SizeOf(cardinal)-1] of cardinal;
  PCardinalArray = ^TCardinalArray;

  /// store a 128-bit hash value
  THash128 = array[0..15] of byte;
  TBlock128 = array[0..3] of cardinal;

  /// 128 bits memory block for AES data cypher/uncypher
  TAESBlock = THash128;
  /// points to a 128 bits memory block, as used for AES data cypher/uncypher
  PAESBlock = ^TAESBlock;

  /// 128 bits memory block for AES key storage
  TAESKey = THash128;

  /// binary access to an unsigned 64-bit value (8 bytes in memory)
  TQWordRec = record
    case integer of
    0: (V: Qword);
    1: (L,H: cardinal);
  end;

type
  PAES = ^TAES;
  // handle AES cypher/uncypher
  // this is the default Electronic codebook (ECB) mode
  TAES = object
  private
    Context: packed array[1..AESContextSize] of byte;
  public
    // Initialize AES contexts for cypher
    function EncryptInit(const Key; KeySize: cardinal): boolean;
    // encrypt an AES data block into another data block
    procedure Encrypt(const BI: TAESBlock; var BO: TAESBlock); overload;
    procedure Done;
  end;

type
  // low-level AES-GCM processing
  // implements standard AEAD (authenticated-encryption with associated-data)
  // algorithm, as defined by NIST
  TAESGCMEngine = object
  private
    // standard AES encryption context
    actx: TAES;
    // ghash value of the Authentication Data
    aad_ghv: TAESBlock;
    // ghash value of the Ciphertext
    txt_ghv: TAESBlock;
    // ghash H current value
    ghash_h: TAESBlock;
    // number of Authentication Data bytes processed
    aad_cnt: TQWordRec;
    // number of bytes of the Ciphertext
    atx_cnt: TQWordRec;
    // initial 32-bit ctr val - to be reused in Final()
    y0_val: integer;
    // current 0..15 position in encryption block
    blen: byte;
    // the state of this context
    flags: set of (flagInitialized, flagFinalComputed, flagFlushed);
    // lookup table for fast Galois Finite Field multiplication
    // is defined as last field of the object for better code generation
    gf_t4k: array[byte] of TAESBlock;
    // build the gf_t4k[] internal table - assuming set to zero by caller
    procedure Make4K_Table;
    // compute a * ghash_h in Galois Finite Field 2^128
    procedure gf_mul_h(var a: TAESBlock); 
    // low-level AES-CTR encryption
    procedure internal_crypt(ptp, ctp: PByte; ILen: PtrUInt);
    // low-level GCM authentication
    procedure internal_auth(ctp: PByte; ILen: PtrUInt;
      var ghv: TAESBlock; var gcnt: TQWordRec);
  public
    // initialize the AES-GCM structure for the supplied Key
    function Init(const Key; KeyBits: PtrInt): boolean;
    // start AES-GCM encryption with a given 12 Byte Initialization Vector
    function Reset(pIV: pointer; IV_len: PtrInt): boolean;
    // encrypt a buffer with AES-GCM, updating the associated authentication data
    function Encrypt(ptp, ctp: Pointer; ILen: PtrInt): boolean;
    // decrypt a buffer with AES-GCM, updating the associated authentication data
    // also validate the GMAC with the supplied ptag/tlen if ptag<>nil,
    // and skip the AES-CTR phase if the authentication doesn't match
    function Decrypt(ctp, ptp: Pointer; ILen: PtrInt; ptag: pointer=nil; tlen: PtrInt=0): boolean;
    // finalize the AES-GCM encryption, returning the authentication tag
    // will also flush the AES context to avoid forensic issues, unless
    // andDone is forced to false
    function Final(out tag: TAESBlock; andDone: boolean=true): boolean;
    // flush the AES context to avoid forensic issues
    // do nothing if Final() has been already called
    procedure Done;
    // append some data to be authenticated, but not encrypted
    function Add_AAD(pAAD: pointer; aLen: PtrInt): boolean;
    // single call AES-GCM encryption and authentication process
    function FullEncryptAndAuthenticate(const Key; KeyBits: PtrInt;
      pIV: pointer; IV_len: PtrInt; pAAD: pointer; aLen: PtrInt;
      ptp, ctp: Pointer; pLen: PtrInt; out tag: TAESBlock): boolean;
    // single call AES-GCM decryption and verification process
    function FullDecryptAndVerify(const Key; KeyBits: PtrInt;
      pIV: pointer; IV_len: PtrInt; pAAD: pointer; aLen: PtrInt;
      ctp, ptp: Pointer; pLen: PtrInt; ptag: pointer; tLen: PtrInt): boolean;
  end;

implementation

procedure XorBlock16(A,B: PCardinalArray);overload;
begin
  A[0] := A[0] xor B[0];
  A[1] := A[1] xor B[1];
  A[2] := A[2] xor B[2];
  A[3] := A[3] xor B[3];
end;

procedure XorBlock16(A,B,C: PCardinalArray);overload;
begin
  B[0] := A[0] xor C[0];
  B[1] := A[1] xor C[1];
  B[2] := A[2] xor C[2];
  B[3] := A[3] xor C[3];
end;

const
  AESMaxRounds = 14;
  RCon: array[0..9] of cardinal = ($01,$02,$04,$08,$10,$20,$40,$80,$1b,$36);

type
  TKeyArray = packed array[0..AESMaxRounds] of TAESBlock;

  // low-level content of TAES.Context (AESContextSize bytes)
  // is defined privately in the implementation section
  // don't change the structure below: it is fixed in the asm code
  TAESContext = packed record
    RK: TKeyArray;   // Key (encr. or decr.)
    IV: TAESBlock;   // IV or CTR
    buf: TAESBlock;  // Work buffer
    DoBlock: procedure(const ctxt, source, dest); // main AES function
    AesNi32: pointer;
    Initialized: boolean;
    Rounds: byte;    // Number of rounds
    KeyBits: word;   // Number of bits in key (128/192/256)
  end;

  // helper types for better code generation
  TWA4  = TBlock128;     // AES block as array of cardinal
  TAWk  = packed array[0..4*(AESMaxRounds+1)-1] of cardinal; // Key as array of cardinal
  PWA4  = ^TWA4;
  PAWk  = ^TAWk;

// AES computed tables - don't change the order below!
var
  Td0, Td1, Td2, Td3, Te0, Te1, Te2, Te3: array[byte] of cardinal;
  SBox, InvSBox: array[byte] of byte;
  Xor32Byte: TByteArray absolute Td0;  // 2^13=$2000=8192 bytes of XOR tables ;)

procedure ComputeAesStaticTables;
var i, x,y: byte;
    pow,log: array[byte] of byte;
    c: cardinal;
begin // 835 bytes of code to compute 4.5 KB of tables
  x := 1;
  for i := 0 to 255 do begin
    pow[i] := x;
    log[x] := i;
    if x and $80<>0 then
      x := x xor (x shl 1) xor $1B else
      x := x xor (x shl 1);
  end;
  SBox[0] := $63;
  InvSBox[$63] := 0;
  for i := 1 to 255 do begin
    x := pow[255-log[i]]; y := (x shl 1)+(x shr 7);
    x := x xor y; y := (y shl 1)+(y shr 7);
    x := x xor y; y := (y shl 1)+(y shr 7);
    x := x xor y; y := (y shl 1)+(y shr 7);
    x := x xor y xor $63;
    SBox[i] := x;
    InvSBox[x] := i;
  end;
  for i := 0 to 255 do begin
    x := SBox[i];
    y := x shl 1;
    if x and $80<>0 then
      y := y xor $1B;
    Te0[i] := y+x shl 8+x shl 16+(y xor x)shl 24;
    Te1[i] := Te0[i] shl 8+Te0[i] shr 24;
    Te2[i] := Te1[i] shl 8+Te1[i] shr 24;
    Te3[i] := Te2[i] shl 8+Te2[i] shr 24;
    x := InvSBox[i];
    if x=0 then continue;
    c := log[x]; // Td0[c] = Si[c].[0e,09,0d,0b] -> e.g. log[$0e]=223 below
    Td0[i] := pow[(c+223)mod 255]+pow[(c+199)mod 255]shl 8+
        pow[(c+238)mod 255]shl 16+pow[(c+104)mod 255]shl 24;
    Td1[i] := Td0[i] shl 8+Td0[i] shr 24;
    Td2[i] := Td1[i] shl 8+Td1[i] shr 24;
    Td3[i] := Td2[i] shl 8+Td2[i] shr 24;
  end;
end;

{ TAES }

procedure aesencrypt386(const ctxt: TAESContext; bi, bo: PWA4);
asm // rolled optimized encryption asm version by A. Bouchez
        push    ebx
        push    esi
        push    edi
        push    ebp
        add     esp,  - 24
        mov     [esp + 4], ecx
        mov     ecx, eax // ecx=pk
        movzx   eax, byte ptr[eax].taescontext.rounds
        dec     eax
        mov     [esp + 20], eax
        mov     ebx, [edx]
        xor     ebx, [ecx]
        mov     esi, [edx + 4]
        xor     esi, [ecx + 4]
        mov     eax, [edx + 8]
        xor     eax, [ecx + 8]
        mov     edx, [edx + 12]
        xor     edx, [ecx + 12]
        lea     ecx, [ecx + 16]
@1:     // pk=ecx s0=ebx s1=esi s2=eax s3=edx
        movzx   edi, bl
        mov     edi, dword ptr[4 * edi + te0]
        movzx   ebp, si
        shr     ebp, $08
        xor     edi, dword ptr[4 * ebp + te1]
        mov     ebp, eax
        shr     ebp, $10
        and     ebp, $ff
        xor     edi, dword ptr[4 * ebp + te2]
        mov     ebp, edx
        shr     ebp, $18
        xor     edi, dword ptr[4 * ebp + te3]
        mov     [esp + 8], edi
        mov     edi, esi
        and     edi, 255
        mov     edi, dword ptr[4 * edi + te0]
        movzx   ebp, ax
        shr     ebp, $08
        xor     edi, dword ptr[4 * ebp + te1]
        mov     ebp, edx
        shr     ebp, $10
        and     ebp, 255
        xor     edi, dword ptr[4 * ebp + te2]
        mov     ebp, ebx
        shr     ebp, $18
        xor     edi, dword ptr[4 * ebp + te3]
        mov     [esp + 12], edi
        movzx   edi, al
        mov     edi, dword ptr[4 * edi + te0]
        movzx   ebp, dh
        xor     edi, dword ptr[4 * ebp + te1]
        mov     ebp, ebx
        shr     ebp, $10
        and     ebp, 255
        xor     edi, dword ptr[4 * ebp + te2]
        mov     ebp, esi
        shr     ebp, $18
        xor     edi, dword ptr[4 * ebp + te3]
        mov     [esp + 16], edi
        and     edx, 255
        mov     edx, dword ptr[4 * edx + te0]
        shr     ebx, $08
        and     ebx, 255
        xor     edx, dword ptr[4 * ebx + te1]
        shr     esi, $10
        and     esi, 255
        xor     edx, dword ptr[4 * esi + te2]
        shr     eax, $18
        xor     edx, dword ptr[4 * eax + te3]
        mov     ebx, [ecx]
        xor     ebx, [esp + 8]
        mov     esi, [ecx + 4]
        xor     esi, [esp + 12]
        mov     eax, [ecx + 8]
        xor     eax, [esp + 16]
        xor     edx, [ecx + 12]
        lea     ecx, [ecx + 16]
        dec     byte ptr[esp + 20]
        jne     @1
        mov     ebp, ecx // ebp=pk
        movzx   ecx, bl
        mov     edi, esi
        movzx   ecx, byte ptr[ecx + SBox]
        shr     edi, $08
        and     edi, 255
        movzx   edi, byte ptr[edi + SBox]
        shl     edi, $08
        xor     ecx, edi
        mov     edi, eax
        shr     edi, $10
        and     edi, 255
        movzx   edi, byte ptr[edi + SBox]
        shl     edi, $10
        xor     ecx, edi
        mov     edi, edx
        shr     edi, $18
        movzx   edi, byte ptr[edi + SBox]
        shl     edi, $18
        xor     ecx, edi
        xor     ecx, [ebp]
        mov     edi, [esp + 4]
        mov     [edi], ecx
        mov     ecx, esi
        and     ecx, 255
        movzx   ecx, byte ptr[ecx + SBox]
        movzx   edi, ah
        movzx   edi, byte ptr[edi + SBox]
        shl     edi, $08
        xor     ecx, edi
        mov     edi, edx
        shr     edi, $10
        and     edi, 255
        movzx   edi, byte ptr[edi + SBox]
        shl     edi, $10
        xor     ecx, edi
        mov     edi, ebx
        shr     edi, $18
        movzx   edi, byte ptr[edi + SBox]
        shl     edi, $18
        xor     ecx, edi
        xor     ecx, [ebp + 4]
        mov     edi, [esp + 4]
        mov     [edi + 4], ecx
        mov     ecx, eax
        and     ecx, 255
        movzx   ecx, byte ptr[ecx + SBox]
        movzx   edi, dh
        movzx   edi, byte ptr[edi + SBox]
        shl     edi, $08
        xor     ecx, edi
        mov     edi, ebx
        shr     edi, $10
        and     edi, 255
        movzx   edi, byte ptr[edi + SBox]
        shl     edi, $10
        xor     ecx, edi
        mov     edi, esi
        shr     edi, $18
        movzx   edi, byte ptr[edi + SBox]
        shl     edi, $18
        xor     ecx, edi
        xor     ecx, [ebp + 8]
        mov     edi, [esp + 4]
        mov     [edi + 8], ecx
        and     edx, 255
        movzx   edx, byte ptr[edx + SBox]
        shr     ebx, $08
        and     ebx, 255
        xor     ecx, ecx
        mov     cl, byte ptr[ebx + SBox]
        shl     ecx, $08
        xor     edx, ecx
        shr     esi, $10
        and     esi, 255
        xor     ecx, ecx
        mov     cl, byte ptr[esi + SBox]
        shl     ecx, $10
        xor     edx, ecx
        shr     eax, $18
        movzx   eax, byte ptr[eax + SBox]
        shl     eax, $18
        xor     edx, eax
        xor     edx, [ebp + 12]
        mov     eax, [esp + 4]
        mov     [eax + 12], edx
        add     esp, 24
        pop     ebp
        pop     edi
        pop     esi
        pop     ebx
end;


procedure TAES.Encrypt(const BI: TAESBlock; var BO: TAESBlock);
begin
  TAESContext(Context).DoBlock(Context,BI,BO);
end;


function TAES.EncryptInit(const Key; KeySize: cardinal): boolean;
  procedure Shift(KeySize: cardinal; pk: PAWK);
  var i: integer;
      temp: cardinal;
  begin
    // 32 bit use shift and mask
    for i := 0 to 9 do begin
      temp := pK^[3];
      // SubWord(RotWord(temp)) if "word" count mod 4 = 0
      pK^[4] := ((SBox[(temp shr  8) and $ff])       ) xor
                ((SBox[(temp shr 16) and $ff]) shl  8) xor
                ((SBox[(temp shr 24)        ]) shl 16) xor
                ((SBox[(temp       ) and $ff]) shl 24) xor
                pK^[0] xor RCon[i];
      pK^[5] := pK^[1] xor pK^[4];
      pK^[6] := pK^[2] xor pK^[5];
      pK^[7] := pK^[3] xor pK^[6];
      inc(PByte(pK),4*4);
    end;
  end;
var Nk: integer;
    ctx: TAESContext absolute Context;
begin
  result := KeySize=128;
  ctx.Initialized := result;
  if not result then exit;

  Nk := KeySize div 32;
  System.Move(Key, ctx.RK, 4*Nk);
  ctx.DoBlock := @aesencrypt386;
  ctx.Rounds  := 6+Nk;
  ctx.KeyBits := KeySize;
  // Calculate encryption round keys
  Shift(KeySize,pointer(@ctx.RK));
end;


procedure TAES.Done;
var ctx: TAESContext absolute Context;
begin
  Fillchar(ctx,sizeof(ctx),0); // always erase key in memory after use
end;


{ AES-GCM Support }

const
  // lookup table as used by mul_x/gf_mul/gf_mul_h
  gft_le: array[byte] of word = (
     $0000, $c201, $8403, $4602, $0807, $ca06, $8c04, $4e05,
     $100e, $d20f, $940d, $560c, $1809, $da08, $9c0a, $5e0b,
     $201c, $e21d, $a41f, $661e, $281b, $ea1a, $ac18, $6e19,
     $3012, $f213, $b411, $7610, $3815, $fa14, $bc16, $7e17,
     $4038, $8239, $c43b, $063a, $483f, $8a3e, $cc3c, $0e3d,
     $5036, $9237, $d435, $1634, $5831, $9a30, $dc32, $1e33,
     $6024, $a225, $e427, $2626, $6823, $aa22, $ec20, $2e21,
     $702a, $b22b, $f429, $3628, $782d, $ba2c, $fc2e, $3e2f,
     $8070, $4271, $0473, $c672, $8877, $4a76, $0c74, $ce75,
     $907e, $527f, $147d, $d67c, $9879, $5a78, $1c7a, $de7b,
     $a06c, $626d, $246f, $e66e, $a86b, $6a6a, $2c68, $ee69,
     $b062, $7263, $3461, $f660, $b865, $7a64, $3c66, $fe67,
     $c048, $0249, $444b, $864a, $c84f, $0a4e, $4c4c, $8e4d,
     $d046, $1247, $5445, $9644, $d841, $1a40, $5c42, $9e43,
     $e054, $2255, $6457, $a656, $e853, $2a52, $6c50, $ae51,
     $f05a, $325b, $7459, $b658, $f85d, $3a5c, $7c5e, $be5f,
     $00e1, $c2e0, $84e2, $46e3, $08e6, $cae7, $8ce5, $4ee4,
     $10ef, $d2ee, $94ec, $56ed, $18e8, $dae9, $9ceb, $5eea,
     $20fd, $e2fc, $a4fe, $66ff, $28fa, $eafb, $acf9, $6ef8,
     $30f3, $f2f2, $b4f0, $76f1, $38f4, $faf5, $bcf7, $7ef6,
     $40d9, $82d8, $c4da, $06db, $48de, $8adf, $ccdd, $0edc,
     $50d7, $92d6, $d4d4, $16d5, $58d0, $9ad1, $dcd3, $1ed2,
     $60c5, $a2c4, $e4c6, $26c7, $68c2, $aac3, $ecc1, $2ec0,
     $70cb, $b2ca, $f4c8, $36c9, $78cc, $bacd, $fccf, $3ece,
     $8091, $4290, $0492, $c693, $8896, $4a97, $0c95, $ce94,
     $909f, $529e, $149c, $d69d, $9898, $5a99, $1c9b, $de9a,
     $a08d, $628c, $248e, $e68f, $a88a, $6a8b, $2c89, $ee88,
     $b083, $7282, $3480, $f681, $b884, $7a85, $3c87, $fe86,
     $c0a9, $02a8, $44aa, $86ab, $c8ae, $0aaf, $4cad, $8eac,
     $d0a7, $12a6, $54a4, $96a5, $d8a0, $1aa1, $5ca3, $9ea2,
     $e0b5, $22b4, $64b6, $a6b7, $e8b2, $2ab3, $6cb1, $aeb0,
     $f0bb, $32ba, $74b8, $b6b9, $f8bc, $3abd, $7cbf, $bebe);

procedure mul_x(var a: TAESBlock; const b: TAESBlock);
var t: cardinal;
    y: TWA4 absolute b;
const
  MASK_80 = cardinal($80808080);
  MASK_7F = cardinal($7f7f7f7f);
begin
  t := gft_le[(y[3] shr 17) and MASK_80];
  TWA4(a)[3] :=  ((y[3] shr 1) and MASK_7F) or (((y[3] shl 15) or (y[2] shr 17)) and MASK_80);
  TWA4(a)[2] :=  ((y[2] shr 1) and MASK_7F) or (((y[2] shl 15) or (y[1] shr 17)) and MASK_80);
  TWA4(a)[1] :=  ((y[1] shr 1) and MASK_7F) or (((y[1] shl 15) or (y[0] shr 17)) and MASK_80);
  TWA4(a)[0] := (((y[0] shr 1) and MASK_7F) or ( (y[0] shl 15) and MASK_80)) xor t;
end;

procedure gf_mul(var a: TAESBlock; const b: TAESBlock);
var p: array[0..7] of TAESBlock;
    x: TWA4;
    t: cardinal;
    i: PtrInt;
    j: integer;
    c: byte;
begin
  p[0] := b;
  for i := 1 to 7 do mul_x(p[i], p[i-1]);
  fillchar(TAESBlock(x),sizeof(TAESBlock),0);
  for i:=0 to 15 do begin
    c := a[15-i];
    if i>0 then begin
      // inlined mul_x8()
      t := gft_le[x[3] shr 24];
      x[3] := ((x[3] shl 8) or  (x[2] shr 24));
      x[2] := ((x[2] shl 8) or  (x[1] shr 24));
      x[1] := ((x[1] shl 8) or  (x[0] shr 24));
      x[0] := ((x[0] shl 8) xor t);
    end;
    for j:=0 to 7 do begin
      if c and ($80 shr j) <> 0 then begin
        x[3] := x[3] xor TWA4(p[j])[3];
        x[2] := x[2] xor TWA4(p[j])[2];
        x[1] := x[1] xor TWA4(p[j])[1];
        x[0] := x[0] xor TWA4(p[j])[0];
      end;
    end;
  end;
  a := TAESBlock(x);
end;


{ TAESGCMEngine }

procedure TAESGCMEngine.Make4K_Table;
var j, k: PtrInt;
begin
  gf_t4k[128] := ghash_h;
  j := 64;
  while j>0 do begin
    mul_x(gf_t4k[j],gf_t4k[j+j]);
    j := j shr 1;
  end;
  j := 2;
  while j<256 do begin
    for k := 1 to j-1 do
      XorBlock16(@gf_t4k[k],@gf_t4k[j+k],@gf_t4k[j]);
    inc(j,j);
  end;
end;

procedure TAESGCMEngine.gf_mul_h(var a: TAESBlock);
var
  x: TWA4;
  i: PtrUInt;
  t: cardinal;
  p: PWA4;
  tab: TWordArray absolute gft_le;
begin
  x := TWA4(gf_t4k[a[15]]);
  for i := 14 downto 0 do begin
    p := @gf_t4k[a[i]];
    t := tab[x[3] shr 24];
    // efficient mul_x8 and xor using pre-computed table entries
    x[3] := ((x[3] shl 8) or  (x[2] shr 24)) xor p^[3];
    x[2] := ((x[2] shl 8) or  (x[1] shr 24)) xor p^[2];
    x[1] := ((x[1] shl 8) or  (x[0] shr 24)) xor p^[1];
    x[0] := ((x[0] shl 8) xor t) xor p^[0];
  end;
  a := TAESBlock(x);
end;

procedure GCM_IncCtr(var x: TAESBlock);
begin
  // in AES-GCM, CTR covers only 32 LSB Big-Endian bits, i.e. x[15]..x[12]
  inc(x[15]);
  if x[15]<>0 then exit;
  inc(x[14]);
  if x[14]<>0 then exit;
  inc(x[13]);
  if x[13]=0 then inc(x[12]);
end;

procedure TAESGCMEngine.internal_crypt(ptp, ctp: PByte; ILen: PtrUInt);
var b_pos: PtrUInt;
begin
  b_pos := blen;
  inc(blen,ILen);
  blen := blen and AESBlockMod;
  if b_pos=0 then b_pos := SizeOf(TAESBlock)
  else
    while (ILen>0) and (b_pos<SizeOf(TAESBlock)) do begin
      ctp^ := ptp^ xor TAESContext(actx).buf[b_pos];
      inc(b_pos);
      inc(ptp);
      inc(ctp);
      dec(ILen);
    end;
  while ILen>=SizeOf(TAESBlock) do begin
    GCM_IncCtr(TAESContext(actx).IV);
    actx.Encrypt(TAESContext(actx).IV,TAESContext(actx).buf); // maybe AES-NI
    XorBlock16(pointer(ptp),pointer(ctp),@TAESContext(actx).buf);
    inc(PAESBlock(ptp));
    inc(PAESBlock(ctp));
    dec(ILen,SizeOf(TAESBlock));
  end;
  while ILen>0 do begin
    if b_pos=SizeOf(TAESBlock) then begin
      GCM_IncCtr(TAESContext(actx).IV);
      actx.Encrypt(TAESContext(actx).IV,TAESContext(actx).buf);
      b_pos := 0;
    end;
    ctp^ := TAESContext(actx).buf[b_pos] xor ptp^;
    inc(b_pos);
    inc(ptp);
    inc(ctp);
    dec(ILen);
  end;
end;

procedure TAESGCMEngine.internal_auth(ctp: PByte; ILen: PtrUInt;
  var ghv: TAESBlock; var gcnt: TQWordRec);
var b_pos: PtrUInt;
begin
  b_pos := gcnt.L and AESBlockMod;
  inc(gcnt.V,ILen);
  if (b_pos=0) and (gcnt.V<>0) then
    gf_mul_h(ghv);
  while (ILen>0) and (b_pos<SizeOf(TAESBlock)) do begin
    ghv[b_pos] := ghv[b_pos] xor ctp^;
    inc(b_pos);
    inc(ctp);
    dec(ILen);
  end;
  while ILen>=SizeOf(TAESBlock) do begin
    gf_mul_h(ghv);
    XorBlock16(@ghv,pointer(ctp));
    inc(PAESBlock(ctp));
    dec(ILen,SizeOf(TAESBlock));
  end;
  while ILen>0 do begin
    if b_pos=SizeOf(TAESBlock) then begin
      gf_mul_h(ghv);
      b_pos := 0;
    end;
    ghv[b_pos] := ghv[b_pos] xor ctp^;
    inc(b_pos);
    inc(ctp);
    dec(ILen);
  end;
end;

function TAESGCMEngine.Init(const Key; KeyBits: PtrInt): boolean;
begin
  Fillchar(self,SizeOf(self),0);
  result := actx.EncryptInit(Key,KeyBits);
  if not result then exit;
  actx.Encrypt(ghash_h, ghash_h);
  Make4K_Table;
end;

const
  CTR_POS  = 12;

function TAESGCMEngine.Reset(pIV: pointer; IV_len: PtrInt): boolean;
begin
  result := not ((pIV=nil) or (IV_len<>CTR_POS));
  if not result then exit;

  // Initialization Vector size matches perfect size of 12 bytes
  System.Move(pIV^,TAESContext(actx).IV,CTR_POS);
  TWA4(TAESContext(actx).IV)[3] := $01000000;

  // reset internal state and counters
  y0_val := TWA4(TAESContext(actx).IV)[3];
  fillchar(aad_ghv,sizeof(aad_ghv),0);
  fillchar(txt_ghv,sizeof(txt_ghv),0);
  aad_cnt.V := 0;
  atx_cnt.V := 0;
  flags := [];
end;

function TAESGCMEngine.Encrypt(ptp, ctp: Pointer; ILen: PtrInt): boolean;
begin
  result := not (ILen>0);
  if result then exit;
  result := not ((ptp=nil) or (ctp=nil) or (flagFinalComputed in flags));
  if not result then exit;

  if (ILen and AESBlockMod=0) and (blen=0) then begin
    inc(atx_cnt.V,ILen);
    ILen := ILen shr AESBlockShift;
    repeat // loop optimized e.g. for PKCS7 padding
      GCM_IncCtr(TAESContext(actx).IV);
      actx.Encrypt(TAESContext(actx).IV,TAESContext(actx).buf);
      XorBlock16(ptp,ctp,@TAESContext(actx).buf);
      gf_mul_h(txt_ghv);
      XorBlock16(@txt_ghv,ctp);
      inc(PAESBlock(ptp));
      inc(PAESBlock(ctp));
      dec(ILen);
    until ILen=0;
  end else begin // generic process in dual steps
    internal_crypt(ptp,ctp,iLen);
    internal_auth(ctp,ILen,txt_ghv,atx_cnt);
  end;
end;

function IsEqual(const A,B; count: PtrInt): boolean; overload;
var perbyte: boolean; // ensure no optimization takes place
begin
  result := true;
  while count>0 do begin
    dec(count);
    perbyte := PByteArray(@A)[count]=PByteArray(@B)[count];
    result := result and perbyte;
  end;
end;

function TAESGCMEngine.Decrypt(ctp, ptp: Pointer; ILen: PtrInt;
  ptag: pointer; tlen: PtrInt): boolean;
var tag: TAESBlock;
begin
  result := not (ILen>0);
  if result then exit;
  result := not ((ptp=nil) or (ctp=nil) or (flagFinalComputed in flags)); 
  if not result then exit;

    if (ILen and AESBlockMod=0) and (blen=0) then begin
      inc(atx_cnt.V,ILen);
      ILen := ILen shr AESBlockShift;
      repeat // loop optimized e.g. for PKCS7 padding
        gf_mul_h(txt_ghv);
        XorBlock16(@txt_ghv,ctp);
        GCM_IncCtr(TAESContext(actx).IV);
        actx.Encrypt(TAESContext(actx).IV,TAESContext(actx).buf);
        XorBlock16(ctp,ptp,@TAESContext(actx).buf);
        inc(PAESBlock(ptp));
        inc(PAESBlock(ctp));
        dec(ILen);
      until ILen=0;
      if (ptag<>nil) and (tlen>0) then begin
        Final(tag,{anddone=}false);  
        result := IsEqual(tag,ptag^,tlen);
        if not result then exit; // check authentication after single pass encryption + auth
      end;
    end else begin // generic process in dual steps
      internal_auth(ctp,ILen,txt_ghv,atx_cnt);
      if (ptag<>nil) and (tlen>0) then begin
        Final(tag,{anddone=}false);
        result := IsEqual(tag,ptag^,tlen);
        if not result then exit; // check authentication before encryption
      end;
      internal_crypt(ctp,ptp,iLen);
    end;
end;

function bswap32(a: cardinal): cardinal;
asm
  bswap eax
end;

function TAESGCMEngine.Final(out tag: TAESBlock; andDone: boolean): boolean;
var
  tbuf: TAESBlock;
  ln: cardinal;
begin
  if not (flagFinalComputed in flags) then begin
    include(flags,flagFinalComputed);
    // compute GHASH(H, AAD, ctp)
    gf_mul_h(aad_ghv);
    gf_mul_h(txt_ghv);
    // compute len(AAD) || len(ctp) with each len as 64-bit big-endian
    ln := (atx_cnt.V+AESBlockMod) shr AESBlockShift;
    if (aad_cnt.V>0) and (ln<>0) then begin
      tbuf := ghash_h;
      while ln<>0 do begin
        if odd(ln) then
          gf_mul(aad_ghv,tbuf);
        ln := ln shr 1;
        if ln<>0 then
          gf_mul(tbuf,tbuf);
      end;
    end;
    TWA4(tbuf)[0] := bswap32((aad_cnt.L shr 29) or (aad_cnt.H shl 3));
    TWA4(tbuf)[1] := bswap32((aad_cnt.L shl  3));
    TWA4(tbuf)[2] := bswap32((atx_cnt.L shr 29) or (atx_cnt.H shl 3));
    TWA4(tbuf)[3] := bswap32((atx_cnt.L shl  3));
    XorBlock16(@tbuf,@txt_ghv);
    XorBlock16(@aad_ghv,@tbuf);
    gf_mul_h(aad_ghv);
    // compute E(K,Y0)
    tbuf := TAESContext(actx).IV;
    TWA4(tbuf)[3] := y0_val;
    actx.Encrypt(tbuf,tbuf);
    // GMAC = GHASH(H, AAD, ctp) xor E(K,Y0)
    XorBlock16(@aad_ghv,@tag,@tbuf);
    if andDone then
      Done;
    result := true;
  end else begin
    Done;
    result := false;
  end;
end;

procedure TAESGCMEngine.Done;
begin
  if flagFlushed in flags then
    exit;
  actx.Done;
  include(flags,flagFlushed);
end;


function TAESGCMEngine.Add_AAD(pAAD: pointer; aLen: PtrInt): boolean;
begin
  if aLen>0 then begin
    if (pAAD=nil) or (flagFinalComputed in flags) then begin
      result := false;
      exit;
    end;
    internal_auth(pAAD,aLen,aad_ghv,aad_cnt);
  end;
  result := true;
end;

function TAESGCMEngine.FullEncryptAndAuthenticate(const Key; KeyBits: PtrInt;
  pIV: pointer; IV_len: PtrInt; pAAD: pointer; aLen: PtrInt; ptp, ctp: Pointer;
  pLen: PtrInt; out tag: TAESBlock): boolean;
begin
  result := Init(Key,KeyBits) and Reset(pIV,IV_len) and Add_AAD(pAAD,aLen) and
            Encrypt(ptp,ctp,pLen) and Final(tag);
  Done;
end;

function TAESGCMEngine.FullDecryptAndVerify(const Key; KeyBits: PtrInt;
  pIV: pointer; IV_len: PtrInt; pAAD: pointer; aLen: PtrInt; ctp, ptp: Pointer;
  pLen: PtrInt; ptag: pointer; tLen: PtrInt): boolean;
begin
  result := Init(Key,KeyBits) and Reset(pIV,IV_len) and Add_AAD(pAAD,aLen) and
            Decrypt(ctp,ptp,pLen,ptag,tlen);
  Done;
end;


initialization
  ComputeAesStaticTables;
  assert(sizeof(TAESContext)=AESContextSize);
  assert(AESContextSize<=300);
  assert(1 shl AESBlockShift=sizeof(TAESBlock));
end.

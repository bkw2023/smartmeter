unit ucomport;
{ 
  write/read einen String/ByteBuffer über ein serial Port 
  Hinweis: write/read kann applikations blockieren sein,  
           d.h. ggf in einen eigenen Thread verwenden
  In ReadFile, WriteFile als letzter Parameter nil für nonoverlapped Mode,
  d.h. blockierend.
}

interface

uses windows;

function OpenCom(var h:THandle; p:string):boolean;
procedure CloseCom(var h:THandle);

function SetupCom(var h:THandle; var c:string):integer;
function GetConfigCom(p:String; var c:TCommConfig):integer;

function GetInCountCom(var h:THandle):integer;

function SendStringCom(var h:THandle; s:string):integer;
function ReadStringCom(var h:THandle; var s:string):integer;

function SendBBufCom(var h:THandle; const b; const l:integer):integer;
function ReadBBufCom(var h:THandle; var b; const bmax:integer):integer;

implementation

uses SysUtils, StrUtils;

function OpenCom(var h:THandle; p:string):boolean;
var d:array[0..80] of Char;
begin
  StrPCopy(d, p);
  h := CreateFile(d, GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  result := h <> INVALID_HANDLE_VALUE;
end;

procedure CloseCom(var h:THandle);
begin CloseHandle(h); end;

function SetupCom(var h:THandle; var c:string):integer;
const
  cRxBufferSize = 256;
  cTxBufferSize = 256;
var
  d : TDCB;
  ct: TCommTimeouts;
begin
  result := -1;
  if not SetupComm(h, cRxBufferSize, cTxBufferSize) then exit;
  result := -2;
  if not GetCommState(h, d) then exit;

  if c='' then c := 'baud=9600 parity=n data=8 stop=1';
  result := -2;
  if not BuildCommDCB(@c[1], d) then exit;
  result := -3;
  if not SetCommState(h, d) then exit;

  with ct do begin
    ReadIntervalTimeout         := 0;
    ReadTotalTimeoutMultiplier  := 0;
    ReadTotalTimeoutConstant    := 1000;
    WriteTotalTimeoutMultiplier := 0;
    WriteTotalTimeoutConstant   := 1000;
  end;
  result := -4;
  if not SetCommTimeouts(h, ct) then exit;
  result := 0;
end;

function GetConfigCom(p:String; var c:TCommConfig):integer;
{ Gets the comm port settings (use '\\.\' for com 10..99) }
var size: cardinal;
begin
  size := sizeof(c);
  FillChar(c, size, 0);
  c.dwSize := size;
  //strip trailing : as it does not work with it
  if RightStr(p, 1) = ':' then p := LeftStr(p, Length(p)-1);
  result := -1;
  try
    if not GetDefaultCommConfig(@p[1], c, size) then begin
      // if port is not found add unc path and check again
      p:='\\.\' + p;
      if not GetDefaultCommConfig(@p[1], c, size) then exit;
    end;
{
    if not GetDefaultCommConfig(PChar(p), c, size) then
      // if port is not found add unc path and check again
      if not GetDefaultCommConfig( PChar('\\.\' + p), c, size) then exit;
}
  except
    exit;
  end;
  result := 0;
end;

{ Return the number of bytes waiting in the queue }
function GetInCountCom(var h:THandle):integer;
var
  s : TCOMSTAT;
  err : DWord;
begin
  result := -1;
  if h = INVALID_HANDLE_VALUE then exit;
  ClearCommError(h, err, @s);
  result := s.cbInQue; // kein longint mögl. rangefail 
end;

function SendStringCom(var h:THandle; s:string):integer;
var bw:DWORD;
begin
  result := -1;
  if h = INVALID_HANDLE_VALUE then exit;
  bw := 0;
  s:=s+#13+#10; // Zeilenende für Empfänger
  WriteFile(h, s[1], length(s), bw, nil);
  result := bw; // ev. -2
end;

function ReadStringCom(var h:THandle; var s:string):integer;
var
  br, b2r: DWord;
  d: array[1..80] of Char;
  i: Integer;
begin
  Result := GetInCountCom(h);
  if result <= 0 then exit; 
  if result > 80 then b2r := 80 
                 else b2r := result; 
  result := -2;
  // wird hier bis CR LF gelesen?
  if not ReadFile(h, d, b2r, br, nil) then exit;
  s := '';
  for i := 1 to br do s := s + d[i];
  result := length(s);
end;

// l:=sizeof(b) bzw kleiner je nach Anzahl zu sendeenden Bytes
function SendBBufCom(var h:THandle; const b; const l:integer):integer;
var bw, b2w : DWORD;
begin
  result := -1;
  if h = INVALID_HANDLE_VALUE then exit;
  bw := 0;
  b2w := l;
  result := -2;
  if not WriteFile(h, b, b2w, bw, nil) then exit;
  result := bw;
end;

// bmax kann auch 1 sein
function ReadBBufCom(var h:THandle; var b; const bmax:integer):integer;
var br, b2r: DWord;
begin
  Result := GetInCountCom(h);
  if result <= 0 then exit;   
  if result > bmax then b2r:= bmax 
                   else b2r:= result; 
  br := 0;
  result := -2;
  if not ReadFile(h, b, b2r, br, nil) then exit;
  result := br;
end;


//var ...;
//initialization 
//finalization
end.
unit uSMWienerNetze;
{
Wiener Netze GmbH
Uhrzeit und Datum
Wirkenergie +A (Wh)
Wirkenergie -A (Wh)
Blindenergie +R (varh)
Blindenergie -R (varh)
Momentanleistung +P (W)
Momentanleistung -P (W)
Momentanleistung +Q (var)
Momentanleistung -Q (var)

06.05.23 15:36:07 (pv: 312 rz:   0 pn:   0 Bytes: 0 Zyklen: 2001) - warte
06.05.23 15:36:07 lt:  749  (pv: 515 rz: 203 pn: 203 Bytes: 125 Zyklen: 369):
7E A0 7B CF 00 02 00 23 13 62 B1 E6 E7 00 DB 08 
53 4D 53 67 70 08 43 DC 61 20 00 67 0A D7 86 1C 
D6 11 6F 71 21 DE 79 4E E7 23 91 AA 5A 10 B0 45 
89 4D B8 22 63 8C E0 E8 CD AB D7 6D 39 16 2D 59 
62 E4 61 48 F6 DF 7E 3A F6 9B 9B 76 F6 29 97 B5 
61 67 FE F7 72 CE 40 35 2A 07 36 D9 E4 E6 09 40 
EB EB B9 D0 1A A1 1B 25 AE 39 88 5C D9 8C A9 98 
A5 16 15 64 7B 96 C0 0D 7A DE 29 64 7E 

7E A0 7B CF 00 02 00 23 13 62 B1 E6 
E7 00 DB 
         08 53 4D 53 67 70 08 43 DC             // String $08=len 'SMS'-$67-$70-$0843DC
61 20                                           // $61=6*16 + 1 = 97
00 67 0A D7                                     // Msg Nr
86 1C D6 11 6F 71 21 DE 79 4E E7 23 91 AA 5A 10 // Data 5*16+12 = 92 
B0 45 89 4D B8 22 63 8C E0 E8 CD AB D7 6D 39 16 
2D 59 62 E4 61 48 F6 DF 7E 3A F6 9B 9B 76 F6 29 
97 B5 61 67 FE F7 72 CE 40 35 2A 07 36 D9 E4 E6 
09 40 EB EB B9 D0 1A A1 1B 25 AE 39 88 5C D9 8C 
A9 98 A5 16 15 64 7B 96 C0 0D 7A DE 
                                    29 64       // crc
                                          7E    // Msg Ende
decoded:

0F 00 60 B0 9D 

   0C    07 E7 05 01 01 13 39 27 00 FF 88 80    Zeit

02 0A -> Strukt 10 Elemente
1)
09 10    53 4D 53 31 30 33 30 37 30 30 35 34 31 36 36 30 // SMS1030700541660
2)
09 0C    07 E7 05 01 01 13 39 27 00 FF 88 80    Zeit 2023-5-1 Montag 19:57:39 0 
         jj jj mm dd wd hh mi ss hs gmtde st
3)
06 00 1B 19 C7                1776071    Wirkenergie +A [Wh]
4)
06 00 01 43 B8                  82872    Wirkenergie -A [Wh]
5)
06 00 00 C1 09                  49417    Blindenergie +R [VArh]
6)
06 00 08 1C 6C                 531564    Blindenergie -R [VArh]
7)
06 00 00 00 EF                    239    Momentanwert Wirkleistung +P [W] Verbrauch
8)   
06 00 00 00 00                      0    Momentanwert Wirkleistung -P [W] Einspeisung
9) 
06 00 00 00 00                      0    Momentanwert Blindleistung +Q [VAr]
10)
06 00 00 00 73                    115    Momentanwert Blindleistung -Q [VAr]

D4 6C EC 4C E0  

}

interface

type
  TSMWienerNetze = record
                     zaehler:string;
                     zeit:TDateTime;   // Uhrzeit und Datum
                     kWh_v,            // Wirkenergie +A 
                     kWh_e,            // Wirkenergie -A 
                     W_v,              // Momentanleistung +P 
                     W_e:double;       // Momentanleistung -P
                   end;
  TOBISDateTime = packed record
                    year:word;
                    month,day,weekday,hour,minute,second,hsec:byte;
                    gmt_derivation:word;
                    clockstatus:byte;                    
                  end;
  Tuint32 = array[0..3] of byte;
  Tobis = packed record
            kopf:array[0..4] of byte; //                  +20
            l0:byte; // $0C
            msgzeit:TOBISDateTime;
            stru:array[0..1] of byte; // $02 $0A obis sruct 10 felder
            c1:byte; // $09 = ordered sequence of octets  +18
            l1:byte; // $10
            zaehler:array[0..15] of char;
            c2:byte; // $09                               +14
            l2:byte; // $0C
            zeit:TOBISDateTime;
            l3:byte; // $06 = unsigned integer 32 bit     +40
            wap:Tuint32;
            l4:byte; // $06 
            wan:Tuint32;
            l5:byte; // $06 
            bap:Tuint32;
            l6:byte; // $06 
            ban:Tuint32;
            l7:byte; // $06 
            wpp:Tuint32;
            l8:byte; // $06 
            wpn:Tuint32;
            l9:byte; // $06 
            bpp:Tuint32;
            l10:byte; // $06 
            bpn:Tuint32;
            reserve:array[0..127-92] of byte;
          end;

function GetSMMsgData(const b; const n:integer; var d:TSMWienerNetze):integer;
function ReadSMKey(fname:string):boolean;

implementation

uses Windows, SysUtils, uSynCrypto;

type 
  TBuf = array[0..255] of byte;
  PBuf = ^TBuf;

var aesgcmengine:TAESGCMEngine; // uSynCrypto
    pb:PBuf;
    TheIV : TAESBlock; // uSynCrypto: = array[0..15] of byte;   
    obis:TObis;

const ckey : TAESBlock =
  ($36, $C6, $66, $39, $E4, $8A, $8C, $A4, $D6, $BC, $8B, $28, $2A, $79, $3B, $BB);

var vkey : TAESBlock;
function ReadSMKey(fname:string):boolean;
var txt:text;
begin
  result := FileExists(fname);
  if not result then exit;
  AssignFile(txt, fname);
  reset(txt);
  readln(txt,vkey[0],vkey[1],vkey[2],vkey[3],vkey[4],vkey[5],vkey[6],vkey[7],
             vkey[8],vkey[9],vkey[10],vkey[11],vkey[12],vkey[13],vkey[14],vkey[15]);
  CloseFile(txt);
end;

function TOBISDateTimeToTDateTime(const t:TOBISDateTime):TDateTime;
var st:TSystemTime;
begin
  st.wYear := Swap(t.year);
  st.wMonth := t.month;
  st.wDayOfWeek := t.weekday;
  st.wDay := t.day;
  st.wHour := t.hour;
  st.wMinute := t.minute;
  st.wSecond := t.second;
  st.wMilliseconds := t.hsec;
  st.wMilliseconds := st.wMilliseconds*100;
  result:=SystemTimeToDateTime(st);
end; 

function Tuint32ToDouble(const i:Tuint32):double;
begin
  result := i[0];
  result := result*256 + i[1];
  result := result*256 + i[2];
  result := result*256 + i[3];
end; 

function GetSMMsgData(const b; const n:integer; var d:TSMWienerNetze):integer;
begin
  result:=-1;
  if n<>125 then exit;
  pb := @b;  
  result:=-2;
  if pb^[24] <> $61 then exit;
  fillchar(TheIV,sizeof(TheIV),0); 
  System.Move(pb^[16], TheIV[0], 8);
  System.Move(pb^[26], TheIV[8], 4);
  fillchar(obis,sizeof(obis),0); 
  with aesgcmengine do begin
    result:=-3;
    if not init(vkey, sizeof(vkey)*8) then exit; // -> initialization
    result:=-4;
    if not Reset(@TheIV, 12) then exit;
    result:=-5;
    if not decrypt(@pb^[30], @obis, 92) then exit; 
  end;
  with obis do begin
    result:=-6;
    if l0 <> $0C then exit;
    d.zeit:=TOBISDateTimeToTDateTime(msgzeit);
    result:=-7;
    if (stru[0]<>$02) or (stru[1]<>$0A) then exit;
    result:=-8;
    if (c1<>$09) or (l1<>$10) then exit;
    d.zaehler := zaehler[0]+zaehler[1]+zaehler[2]+zaehler[3]+
                 zaehler[4]+zaehler[5]+zaehler[6]+zaehler[7]+
                 zaehler[8]+zaehler[9]+zaehler[10]+zaehler[11]+
                 zaehler[12]+zaehler[13]+zaehler[14]+zaehler[15];
    result:=-9;
    if (c2<>$09) or (l2<>$0C) then exit;
    d.zeit:=TOBISDateTimeToTDateTime(zeit);
    result:=-10;
    if l3 <> $06 then exit;
    d.kWh_v:=Tuint32ToDouble(wap)/1000;
    result:=-11;
    if l4 <> $06 then exit;
    d.kWh_e:=Tuint32ToDouble(wan)/1000;
    result:=-12;
    if l5 <> $06 then exit;
    if l6 <> $06 then exit;
    result:=-13;
    if l7 <> $06 then exit;
    d.W_v:=Tuint32ToDouble(wpp);
    result:=-14;
    if l8 <> $06 then exit;
    d.W_e:=Tuint32ToDouble(wpn);
  end;
  result:=0;
end;

initialization
  vkey := ckey;
end.


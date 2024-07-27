unit csvfile;

interface
type Tdvec=array of double;
type Tcvec=array of cardinal;

function readxy(fname:string; var x,y:Tdvec; var xm,ym:double):integer;

function readsmhist(fname,zname:string; e:double; var ht,hn:Tcvec):integer;

var
  fs:char;

implementation

uses
  Classes, SysUtils;

var
  List,Tab: TStrings;
  sa,su:array[0..1,1..366] of integer;
// Ergebnis in List[0] ... List[List. -1]
function split(s:string):integer;
begin
  if assigned(List) then
    List.clear
  else
    List := TStringList.Create;
  s:=s+chr(0);
  try
    result := ExtractStrings([fs], [], PChar(s), List);
//    WriteLn(List.Text);
//    ReadLn;
//    result := List.Count;
  except
    result := -1;
  end;
end;

function splitfs(s:string;fs:char):integer;
begin
  if assigned(Tab) then
    Tab.clear
  else
    Tab := TStringList.Create;
  s:=s+chr(0);
  try
    result := ExtractStrings([fs], [], PChar(s), Tab);
//    WriteLn(Tab.Text);
//    ReadLn;
//    result := Tab.Count;
  except
    result := -1;
  end;
end;


function readxy(fname:string; var x,y:Tdvec; var xm,ym:double):integer;
var txt:text;
    xx,yy:double;
    i,n,m:integer;
    s,t:string;
label l_fehler;
begin
  result:=-1;
  if not FileExists(fname) then exit;
  AssignFile(txt, fname);
  Reset(txt);
  xm:=0;
  ym:=0;
  n:=5;
  setlength(x,n);
  setlength(y,n);
  while not eof(txt) do begin
    Readln(txt, s);
    if split(s) > 1 then begin
      t:=trim(List[0]);
      val(t,xx,i);
      if i<>0 then begin
        if t[i]=',' then begin
          t[i]:='.';
          val(t,xx,i);
        end;
        if i<>0 then goto l_fehler;
      end;

      t:=trim(List[1]);
      val(t,yy,i);
      if i<>0 then begin
        if t[i]=',' then begin
          t[i]:='.';
          val(t,yy,i);
        end;
        if i<>0 then goto l_fehler;
      end;
    end else goto l_fehler;
    inc(result);
    m:=length(x);
    if m <= result then begin
      m:=m+n;
      setlength(x,m);
      setlength(y,m);
    end;
    x[result] := xx;
    y[result] := yy;
    xm:=xm+xx;
    ym:=ym+yy;
  end;
  l_fehler:;
  CloseFile(txt);
  if result>=0 then begin
    inc(result);
    setlength(x,result);
    setlength(y,result);
    xm:=xm/result;
    ym:=ym/result;
  end else writeln('Error readcsv: ',s);
end;

function StringToDouble(s:string; var d:double):boolean;
var i:integer;
begin
  val(s,d,i);
  result:= i=0;
  if not result then begin
    if s[i]=',' then begin
      s[i]:='.';
      val(s,d,i);
      result:= i=0;
    end;
  end;
end;

// ermittelt ob hell ist
function IsTag(h,t,j:integer; var tag:boolean):boolean;
begin
  j:=j-2023;
  result:=false;
  if j<0 then exit;
  if j>1 then exit;
  if t<0 then exit;
  if t>366 then exit;
  if h<0 then exit;
  if h>24*4 then exit;

  if sa[j,t]=0 then exit;
  if su[j,t]=0 then exit;

  tag:=(h+4>=sa[j,t]) and (h+4<su[j,t]);
  result:=true;
end;

function IsNumber(s:string; var i:integer):boolean;
var j:integer;
begin
  val(s,i,j);
  result:=j=0;
end;

function IsSchaltjahr(j:integer):integer;
begin
  result:=-1;
  if j<2023 then exit;
  if j>2024 then exit;
  case j of
  (2024): result:=1;
  else
    result:=0;
  end;
end;

const caTab:array[1..12] of integer = ( 0,31,59,90,120,151,181,212,243,273,304,334);
const cmTab:array[1..12] of integer = (31,29,31,30, 31, 30, 31, 31, 30, 31, 30, 31);
function IsDatum(datum:string; var t,j:integer):boolean;
var n,m:integer;
begin
  n:=splitfs(datum,'.');
  result:=n=3;
  if not result then exit;

  val(Tab[2],j,n);
  result:=n=0;
  if not result then exit;

  val(Tab[1],m,n);
  result:=n=0;
  if not result then exit;
  result:=m<13;
  if not result then exit;
  result:=m>0;
  if not result then exit;

  val(Tab[0],t,n);
  result:=n=0;
  if not result then exit;
  result:=t<=cmTab[m];
  if not result then exit;
  result:=t>0;
  if not result then exit;

  t:=t+caTab[m];
  if m<3 then exit;
  // Schaltjahre
  n:=IsSchaltjahr(j);
  result:=n<>-1;
  if not result then exit;
  t:=t+n;
end;

function IsZeit(Zeit:string; var h:integer):boolean;
var n:integer;
    s:string;
begin
  n:=splitfs(Zeit,':');
  result:=n>1;
  if not result then exit;

  s:=trim(Tab[0]);
  result:=IsNumber(s,h);
  if not result then exit;
  result:=(h>=0) and (h<24);
  if not result then exit;

  s:=trim(Tab[1]);
  result:=IsNumber(s,n);
  if not result then exit;
  result:=(n>=0) and (n<60);
  if not result then exit;
  n:=n div 15;

  h:=h*4+n;
end;

function IsMonat(s:string; var h:integer):boolean;
begin
  s:=uppercase(s);
  result:=(s[1]='J') and (s[2]<>'U'); h:=1;
  if result then exit;
  result:=s[1]='F'; inc(h);
  if result then exit;
  result:=(s[1]='M') and (s[3]<>'I'); inc(h);
  if result then exit;
  result:=(s[1]='A') and (s[3]='R'); inc(h);
  if result then exit;
  result:=(s[1]='M') and (s[3]='I'); inc(h);
  if result then exit;
  result:=(s[1]='J') and (s[3]='N'); inc(h);
  if result then exit;
  result:=(s[1]='J') and (s[3]='L'); inc(h);
  if result then exit;
  result:=(s[1]='A') and (s[3]='G'); inc(h);
  if result then exit;
  result:=s[1]='S'; inc(h);
  if result then exit;
  result:=s[1]='O'; inc(h);
  if result then exit;
  result:=s[1]='N'; inc(h);
  if result then exit;
  result:=s[1]='D'; inc(h);
end;

function readsmhist(fname,zname:string; e:double; var ht,hn:Tcvec):integer;
var txt:text;
    datum,zeit:string;
    x:double;
    i,j,n,iJahr,iTag,iStunde,iMonat,z:integer;
    s,t,ss,tt:string;
    tag,calctag:boolean;
label l_fehler, l_read_sm, l_exit, l_next, l_cont, l_close;
begin
  result:=-1;
  tag:=true; calctag:=false;
  // read Sonnenaufgang, Sonnenuntergang
  if not FileExists(zname) then goto l_read_sm;
  AssignFile(txt, zname);
  Reset(txt);
  z:=0;
  while not eof(txt) do begin
    inc(z);
//    writeln(z);
    Readln(txt, s);
    t:=StringReplace(s, ''+char(9), ' ',[rfReplaceAll, rfIgnoreCase]);
    n:=splitfs(t,' ');
    ss:=trim(Tab[0]);
    tt:=StringReplace(ss, '.', ' ',[rfReplaceAll, rfIgnoreCase]);
    ss:=trim(tt);
    if not IsNumber(ss,iTag) then goto l_cont;
    if n<5 then goto l_cont;
    ss:=trim(Tab[1]);
    if not IsMonat(ss,iMonat) then goto l_cont;
    i:=iTag+caTab[iMonat];
//    if i=151 then begin
//      writeln(i);
//    end;
    ss:=trim(Tab[2]);
    if not IsNumber(ss,iJahr) then goto l_cont;
    if iMonat>2 then begin
      // Schaltjahre
      j:=IsSchaltjahr(iJahr);
      if j<>-1 then i:=i+j else writeln('Fehler: Schaltjahr nicht bestimmbar');
    end;
    j:=iJahr-2023;
    if j<0 then goto l_close;
    if j>1 then goto l_close;

    ss:=trim(Tab[3]);
    tt:=trim(Tab[4]);
    if not IsZeit(ss,iStunde) then goto l_cont;
    sa[j,i]:=iStunde;
    if not IsZeit(tt,iStunde) then goto l_cont;
    su[j,i]:=iStunde;
  l_cont:;
  end;
  calctag:=true;
l_close:;
  CloseFile(txt);
l_read_sm:;
  if not FileExists(fname) then exit;
  AssignFile(txt, fname);
  Reset(txt);
  n:=trunc(1.5/e)+1; // 6kWh davon 1 viertel
  setlength(ht,n);
  setlength(hn,n);
  z:=0;
  while not eof(txt) do begin
    inc(z);
//    writeln(z);
//    if z=14494 then begin
//      writeln('bin da');
//    end;
    Readln(txt, s);
    i:=split(s);
    if i < 3 then goto l_fehler;
    datum:=trim(List[0]);
    if not IsDatum(datum,iTag,iJahr) then goto l_next;
    zeit:=trim(List[1]);
    if not IsZeit(Zeit,iStunde) then goto l_next;
//  zeit:=trim(List[2]);
    if i > 3 then t:=trim(List[3]) else goto l_next; // ? x:=0;
    if not StringToDouble(t,x) then goto l_fehler;
// echte Nullwerte sind echte Einspeisung
    if x<1e-6 then i:=0 else i:=trunc(x/e)+1;
    if calctag then begin
      calctag:=IsTag(iStunde,iTag,iJahr,tag);
      if not calctag then begin
        writeln('Fehler: Tageszeit nicht bestimmbar in Zeile ',z);
        writeln(s);
        tag:=true;
      end;
    end;
    if tag then inc(ht[i]) else inc(hn[i]);
  l_next:;
  end;
  result:=n;
  goto l_exit;
l_fehler:;
  writeln('Fehler in Zeile: ',z);
  writeln(s);
l_exit:;
  CloseFile(txt);
end;


initialization

List := nil;
Tab := nil;
fs := ';';

finalization

List.Free;
Tab.Free;
end.
 
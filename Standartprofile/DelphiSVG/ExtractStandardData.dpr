program ExtractStandardData;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes;

var fbatch:boolean;

function splitfs(s:string;fs:char;var Tab: TStrings):integer;
begin
  if assigned(Tab) then Tab.clear
                   else Tab := TStringList.Create;
  s:=s+chr(0);
  try
    result := ExtractStrings([fs], [], PChar(s), Tab);
  except
    result := -1;
  end;
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

function von2bis(s:string):string;
var x: TStrings;
    i:integer;
    t:string;
label l_exit;
begin
  if splitfs(s,':',x)<>2 then begin
    l_exit:;
    writeln('fehler in von2bis ',s);
    if not fbatch then begin
      writeln('fertig, druecke Returntaste');
      readln;
    end;
    halt(0);
  end;

  i:=strtoint(x[0]);
  inc(i);
  if i<24 then begin
    t:=inttostr(i);
    if i<10 then t:='0'+t;
  end else t:='00';

  case x[1][1] of
  '0': result:=x[0]+':15';
  '1': result:=x[0]+':30';
  '3': result:=x[0]+':45';
  '4': result:=t+':00';
  else
    goto l_exit;
  end;
  result:=trim(result);
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

var
  sfname, dfname, tag, line, s, t : string;
  svg,txt:text;
  i,j:integer;
  found:boolean;
  x: TStrings;
  d:double;
label l_parafehler, l_fertig;
begin
  { TODO -oUser -cConsole Main : Hier Code einfügen }
  fbatch:=false;
  if paramCount=0 then begin
    l_parafehler:;
    writeln('Useage: ExtractStandardData.exe file.txt [-b]');
    if not fbatch then begin
      writeln('fertig, druecke Returntaste');
      readln;
    end;
    halt(0);
  end else if paramCount>1 then fbatch:=uppercase(paramstr(2))='-B';
  sfname:=paramstr(1);
  dfname:=uppercase(ExtractFileExt(sfname));
  if dfname<>'.TXT' then goto l_parafehler;
  dfname:= ChangeFileExt(sfname, '.csv');

  if not FileExists(sfname) then begin
    writeln('File not exist: ',sfname);
    if not fbatch then begin
      writeln('fertig, druecke Returntaste');
      readln;
    end;
    halt(0);
  end;

  AssignFile(svg,sfname);
  reset(svg);
  AssignFile(txt,dfname);
  rewrite(txt);

  while not eof(svg) do begin
    readln(svg,line);

    if line[1]='<' then begin
      i:=pos(' ',line);
      if i>0 then tag:=copy(line,2,i-2)
             else tag:='';
    end;

    if found then begin
      if tag='path' then begin
        i:=pos('aria-label=',line);
        j:=pos('Leistung(Vergleich)',line);
        if (i>0) and (j>i) then begin
          i:=i+12;
          j:=j-2;
          s:=copy(line,i,j-i);
          t:=StringReplace(s,', ','; ',[rfReplaceAll, rfIgnoreCase]);
          j:=splitfs(t,';',x);
          if j<>4 then begin
            writeln('split first: ',j);
            if not fbatch then begin
              writeln('fertig, druecke Returntaste');
              readln;
            end;
            halt(0);
          end;
          s:=trim(x[3]);
          // habe Lastkurve in kW brauche aber Verbrauch in kWh
          if StringToDouble(s,d) then begin
            d:=d/4;
            s:=trim(format('%10.6f',[d]));
          end else begin
            writeln('kein Wert: ',s);
            if not fbatch then begin
              writeln('fertig, druecke Returntaste');
              readln;
            end;
            halt(0);
          end;

          s:=trim(x[2])+':00;'+von2bis(x[2])+':00;'+s+';;';
          t:=x[1];
          j:=splitfs(t,' ',x);
          if j<>2 then begin
            writeln('split second: ',j);
            if not fbatch then begin
              writeln('fertig, druecke Returntaste');
              readln;
            end;
            halt(0);
          end;

          if not IsMonat(x[0], i) then begin
            writeln('not IsMonat');
            if not fbatch then begin
              writeln('fertig, druecke Returntaste');
              readln;
            end;
            halt(0);
          end;
          t:=inttostr(i);
          if length(t)=1 then t:='0'+t;
          s:=t+'.2023;'+s;

          t:=x[1];
          if length(t)=1 then t:='0'+t;
          s:=t+'.'+s;
          writeln(s);
          writeln(txt,s);
        end;
      end;
      if tag='/g' then goto l_fertig;

    end else begin
      if tag='g' then begin
        i:=pos('Leistung(Vergleich)',line);
        if i>0 then begin
          i:=pos('Linie mit 96 Datenpunktpunkten',line);
          if i>0 then found:=true;
        end;
      end;
    end;

  end;

l_fertig:;
  CloseFile(svg);
  CloseFile(txt);
  if not fbatch then begin
    writeln('fertig, druecke Returntaste');
    readln;
  end;
end.


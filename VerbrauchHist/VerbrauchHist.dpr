program VerbrauchHist;

{$APPTYPE CONSOLE}

uses
  SysUtils, csvfile;

procedure calc_ng(ht:Tcvec;e:double;var ng:Tdvec);
var en,ee,pw:double;
    i,j,n:integer;
begin
  n:=length(ht)-1;
  setlength(ng,17);
  ng[0]:=100;
  for i:=1 to 16 do begin
    pw:=i*e;        // Wechselrichterleistung
    ee:=ht[0]*pw/4; // Einspeisung bei 0 Verbrauch
    en:=0;
    for j:=1 to n do begin
      if j<=i then begin
        ee := ee + ht[j]*(pw - j*e)/4;
        en := en + ht[j]*j*e/4;
      end else begin
        en := en + ht[j]*pw/4;
      end;
    end;
    ng[i]:=100*en/(en+ee);
  end;

end;

var i,n:integer;
    e:double;
    ht,hn:Tcvec;
    ng:Tdvec;
    txt:Text;
    fname:string;
begin
  { TODO -oUser -cConsole Main : Hier Code einfügen }
  e:=0.8*0.25/16; // 800W Viertelstunde in [kWh] und davon 1/16 ... also 50W Auflösung
  writeln('Einheit in kWh: ',e);
  n:=csvfile.readsmhist('VIERTELSTUNDENWERTE.csv','Astronomische_Sonne_Wien.txt',e,ht,hn);
  if n>0 then begin
    calc_ng(ht,e,ng);
    fname:='VerbrauchHist.csv';
//  if FileExists(fname) then
    AssignFile(txt, fname);
    Rewrite(txt);
    for i:=0 to length(ht)-1 do
      if i<=16 then writeln(txt,i:3,' ; ',i*e*1000,' ; ',ht[i],' ; ',hn[i],' ; ',ng[i]:5:1,' ;')
               else writeln(txt,i:3,' ; ',i*e*1000,' ; ',ht[i],' ; ',hn[i],' ; ;');
    CloseFile(txt);
  end;
  writeln('done, press <return>');
  readln;
end.

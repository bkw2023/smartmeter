program DelphiSplitXML;

{$APPTYPE CONSOLE}

uses
  SysUtils;

var
  sfname, dfname, tag : string;
  svg,txt:text;
  c:char;
  warreturn,warbegin,warend, tagbegin, tagend, fbatch:boolean;
label l_parafehler;
begin
  { TODO -oUser -cConsole Main : Hier Code einfügen }
  fbatch:=false;
  case paramCount of
  0: begin
    l_parafehler:;
      writeln('Useage: DelphiSplitXML.exe file.svg [-b]');
      if not fbatch then begin
        writeln('fertig, druecke Returntaste');
        readln;
      end;
      halt(0);
    end;
  1:;
  else
    fbatch:=uppercase(paramstr(2))='-B';
  end;
//  sfname:=ExtractFilePath(paramstr(0));
//  sfname:=ExtractFileName(paramstr(0));
  sfname:=paramstr(1);
  dfname:=uppercase(ExtractFileExt(sfname));
  if dfname<>'.SVG' then goto l_parafehler;
  dfname:= ChangeFileExt(sfname, '.txt');

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

  warreturn:=true;
  warbegin:=false;
  warend:=false;
  tagbegin:=false;
  tagend:=false;
  tag:='';
  while not eof(svg) do begin
    read(svg,c);
    case c of
    '<': begin
           if warreturn then begin
             write(txt,c);
           end else begin
             writeln(txt);
             write(txt,c);
             warreturn:=true;
           end;
           warbegin:=true;
           warend:=false;
           tagbegin:=true;
           tagend:=false;
           tag:='';
         end;
    '>': begin
           if warreturn then begin
             write(txt,c);
           end else begin
             write(txt,c);
             writeln(txt);
             warreturn:=true;
           end;
           warbegin:=false;
           warend:=true;
           tagend:=true;
         end;
    char($0D): // CR
         if warreturn then  // ignor
         else writeln(txt);
    char($0A): // LF  -> ignor
         ;
    else
      write(txt,c);
      warreturn:=false;
      warbegin:=false;
      warend:=false;
      if c=' ' then tagend:=true;
    end;
    if tagbegin then begin
      if tagend then begin
        tagbegin:=false;
        tagend:=false;
          if not fbatch then writeln(tag);
      end else begin
        if c<>'<' then tag:=tag+c;
      end;
    end;

  end;

  CloseFile(svg);
  CloseFile(txt);
  if not fbatch then begin
    writeln('fertig, druecke Returntaste');
    readln;
  end;
end.

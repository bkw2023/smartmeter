program testme;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  Messages,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  ComCtrls,
  StdCtrls,
  Menus,
  ExtCtrls,
  uunluremouseevent in 'uunluremouseevent.pas';

var
  dwFlags: DWORD;
  fx:DWORD;
  fy:DWORD;
  lx:longint absolute fx;
  ly:longint absolute fy;
  s:string;
  px,py:integer;
  p:TPoint;
  i:integer;
  txt:text;
  me:TME;
begin
  AssignFile(txt,'testme.csv');
  Rewrite(txt);
  { TODO -oUser -cConsole Main : Hier Code einfügen }
  dwFlags := MOUSEEVENTF_MOVE;
  px:=300;
  py:=300;
  for i:=0 to 255 do begin
    SetCursorPos(px, py);
    p:=mouse.CursorPos;
    if (px<>p.x) or (py<>p.y) then writeln('*** Error Start Position failed');

//    fx:=i;
//    if i<=16 then fx:=i
//             else fx:=((i*8+80) div 13);
//    if i<=16 then fx:=-i
//             else fx:=-((i*8+80) div 13);
//    fy:=0;

//    fy:=i;
    if i<=16 then fy:=i
             else fy:=((i*8+80) div 13);
//    if i<=16 then fx:=-i
//             else fx:=-((i*8+80) div 13);
    fx:=0;


    mouse_event(dwFlags, fx, fy, 0, 0);  // relative
////    sleep(100);
//    mouse_event(dwFlags, 1, 0, 0, 0);  // relative
    mouse_event(dwFlags, 0, 1, 0, 0);  // relative
    sleep(100);
(*
    me.dwFlags:=dwFlags;
    me.dx:=lx;
    me.dy:=ly;
    while unstupid_mouse_event(me) do begin
      sleep(100);
//      s:=Format('%d ; %d ; %d ; ;',[i,px,me.dx]);
//      writeln(txt,s);
    end;
    if me.res then begin
      sleep(100);
//      s:=Format('%d ; %d ; %d ; ;',[i,px,me.dx]);
//      writeln(txt,s);
    end;
*)
    p:=mouse.CursorPos;
    s:=Format('%4d : (%d,%d) + (%d,%d) -> (%d,%d)',[i,px,py,lx,ly,p.x,p.y]);
    writeln(s);
//    s:=Format('%d ; %d ; %d ; %d ;',[i,px,lx,p.x]);
    s:=Format('%d ; %d ; %d ; %d ;',[i,py,ly,p.y]);
    writeln(txt,s);
  end;
  CloseFile(txt);
  writeln('finish, press return');
  readln;
end.

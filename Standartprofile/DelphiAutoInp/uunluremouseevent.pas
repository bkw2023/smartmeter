unit uunluremouseevent;

interface

uses
  SysUtils,
  Windows,
  Messages;

type
  TME = record
          dwFlags:cardinal;
          dx,dy:longint;
         end;

function unstupid_mouse_event(var me:TME):integer;

implementation

function unstupid_mouse_event(var me:TME):integer;
var mFlags:DWORD;
  x,y:longint;
  ix:cardinal absolute x;
  iy:cardinal absolute y;
begin
  result := 0;
  with me do begin 
    if (dx=0) and (dy=0) then begin
      if dwFlags <> MOUSEEVENTF_MOVE then begin
        mouse_event(dwFlags, 0, 0, 0, 0);
        result := 1;
      end;
    end else begin
      if abs(dx)<=16 then x:=dx
      else x:=(abs(dx)*8+80) div 13;
      if dx<0 then x:=-x;
      if abs(dy)<=16 then y:=dy
      else y:=(abs(dy)*8+80) div 13;
      if dy<0 then y:=-y;
      mFlags:=MOUSEEVENTF_MOVE;
      mouse_event(mFlags, ix, iy, 0, 0);
      mouse_event(mFlags, 1, 0, 0, 0);
      if dwFlags <> MOUSEEVENTF_MOVE then result:=2
                                     else result:=1;
      dx:=0;
      dy:=0;
    end;
  end;
end;

end.

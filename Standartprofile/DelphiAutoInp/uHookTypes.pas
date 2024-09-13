unit uHookTypes;

interface

uses
  Windows,
  Messages;

const
  WM_MyMHook = WM_USER + 3000;
  WM_MyKHook = WM_USER + 3001;

  cBool2str:array[false..true] of string = ('F','T');

type
  TIntPoint = packed record
    x,y:Smallint;
  end;

function Hex2Longint(s:string; var l:longint):integer;
function mousemsgstr(wm:WParam):string;
function IntPoint2str(p:TIntPoint):string;
function IntPoint2LParam(p:TIntPoint):LParam;

implementation

uses SysUtils;

function Hex2Longint(s:string; var l:longint):integer;
var c:cardinal absolute l;
begin
  trim(s);
  if s[1] <> '$' then s:='$' + s;
  try
    c:=StrToInt(s);
    result := 0;
  except
    result := -1;
  end;
end;

function mousemsgstr(wm:WParam):string;
begin
case wm of
  WM_MOUSEMOVE        : result:='move ';
  WM_LBUTTONDOWN      : result:='LB-d ';
  WM_LBUTTONUP        : result:='LB-u ';
  WM_LBUTTONDBLCLK    : result:='LB-dc';
  WM_RBUTTONDOWN      : result:='RB-d ';
  WM_RBUTTONUP        : result:='RB-u ';
  WM_RBUTTONDBLCLK    : result:='RB-dc';
  WM_MBUTTONDOWN      : result:='MB-d ';
  WM_MBUTTONUP        : result:='MB-u ';
  WM_MBUTTONDBLCLK    : result:='MB-dc';
  WM_MOUSEWHEEL       : result:='wheel';

  WM_NCMOUSEMOVE      : result:='MOVE ';
  WM_NCLBUTTONDOWN    : result:='LB-D ';
  WM_NCLBUTTONUP      : result:='LB-U ';
  WM_NCLBUTTONDBLCLK  : result:='LB-DC';
  WM_NCRBUTTONDOWN    : result:='RB-D ';
  WM_NCRBUTTONUP      : result:='RB-U ';
  WM_NCRBUTTONDBLCLK  : result:='RB-DC';
  WM_NCMBUTTONDOWN    : result:='MB-D ';
  WM_NCMBUTTONUP      : result:='MB-U ';
  WM_NCMBUTTONDBLCLK  : result:='MB-DC';
else
  result:=Format('$%4x',[wm]);
end;
  result:=result+Format(' $%4x',[wm]);
end;

function IntPoint2str(p:TIntPoint):string;
begin
  result:=Format('x: %4d y: %4d',[p.x,p.y]);
end;

function IntPoint2LParam(p:TIntPoint):LParam;
var l:LParam absolute p;
begin
  result:=l;
end;

function keyupdown(c:LParam):string;
begin
  if  (c and $80000000) <> 0 then result:='k-d'
                             else result:='k-u';
end;

end.

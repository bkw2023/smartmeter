library HookInp;

{ Wichtiger Hinweis zur DLL-Speicherverwaltung: ShareMem muß sich in der
  ersten Unit der unit-Klausel der Bibliothek und des Projekts befinden (Projekt-
  Quelltext anzeigen), falls die DLL Prozeduren oder Funktionen exportiert, die
  Strings als Parameter oder Funktionsergebnisse übergeben. Das gilt für alle
  Strings, die von oder an die DLL übergeben werden -- sogar für diejenigen, die
  sich in Records und Klassen befinden. Sharemem ist die Schnittstellen-Unit zur
  Verwaltungs-DLL für gemeinsame Speicherzugriffe, BORLNDMM.DLL.
  Um die Verwendung von BORLNDMM.DLL zu vermeiden, können Sie String-
  Informationen als PChar- oder ShortString-Parameter übergeben. }
  

uses
  Windows,
  Messages,
  uHookTypes in 'uHookTypes.pas';

{$R *.res}

var
  MHook, KHook: HHOOK;
  Master: HWND;   // z.B. Master := FindWindow('Delphi Auto Input', nil)
                  //      Master := HWND_BROADCAST versendet an alle
  fMouse,fKeys:Boolean;
  vMM:WParam;
  pM:TIntPoint;
  z:cardinal;
  rmsg:boolean;

function MHookProc(_nCode: integer; _MsgID: WParam; _Data: LParam): LResult; stdcall;
{ 
wParam: 
  Dieser Parameter kann eine der folgenden Nachrichten sein: 
    WM_LBUTTONDOWN
    WM_LBUTTONUP 
    WM_MOUSEMOVE 
    WM_MOUSEWHEEL 
    WM_RBUTTONDOWN
    WM_RBUTTONUP
lParam: Pointer auf
  MOUSEHOOKSTRUCT = packed record
    pt: TPoint;  // Koordinaten des Cursors in Bildschirmkoordinaten.  ?= record x,y:longint;end;
    hwnd: HWND;
    wHitTestCode: UINT;
    dwExtraInfo: DWORD;
  end;
}
var
  Data: PMouseHookStruct absolute _Data;
  MylParam: DWORD;
  p:TIntPoint absolute MylParam;
//  _p:^TIntPoint absolute _Data;
  msg:WParam;
begin
  try
    Result := 0;
    if _nCode <> HC_ACTION then exit;
    inc(z);

    case _MsgID of
      WM_NCMOUSEMOVE:     msg:= WM_MOUSEMOVE;
      WM_NCLBUTTONDOWN:   msg:= WM_LBUTTONDOWN;
      WM_NCLBUTTONUP:     msg:= WM_LBUTTONUP;
      WM_NCLBUTTONDBLCLK: msg:= WM_LBUTTONDBLCLK;
      WM_NCRBUTTONDOWN:   msg:= WM_RBUTTONDOWN;
      WM_NCRBUTTONUP:     msg:= WM_RBUTTONUP;
      WM_NCRBUTTONDBLCLK: msg:= WM_RBUTTONDBLCLK;
      WM_NCMBUTTONDOWN:   msg:= WM_MBUTTONDOWN;
      WM_NCMBUTTONUP:     msg:= WM_MBUTTONUP;
      WM_NCMBUTTONDBLCLK: msg:= WM_MBUTTONDBLCLK;
      WM_MOUSEMOVE..WM_MBUTTONDBLCLK: msg:= _MsgID;
    else
      exit;
    end;

    p.x := Data^.pt.x;
    p.y := Data^.pt.y;
    if (msg=WM_MOUSEMOVE) and (pM.x=p.x) and (pM.y=p.y) then exit;
    if vMM=msg then begin
      pM.x:=p.x;
      pM.y:=p.y;
      rmsg:=true;
      exit;
    end;
    if rmsg then begin
      rmsg:=false;
      if (pM.x<>p.x) or (pM.y<>p.y) then
        PostMessage(Master, WM_MyMHook, vMM, LParam(pM));
    end;

//    if (vMM=WM_MOUSEMOVE) and (pM.x=p.x) and (pM.y=p.y) then exit;

    vMM:=msg;
    pM.x:=p.x;
    pM.y:=p.y;
    // forwart to Logger
    PostMessage(Master, WM_MyMHook, msg, MylParam);
  finally
    Result := CallNextHookEx(MHook, _nCode, _MsgID, _Data);
  end;
end;

function HookOffMouse():boolean; stdcall; export;
begin
  Result := true;
  if MHook = 0 then exit;
  Result := UnhookWindowsHookEx(MHook);
  if Result then MHook := 0;
end;

function HookOnMouse: HHOOK; stdcall; export;
begin
  vMM:=0;
  z:=0;
  rmsg:=false;
  if MHook <> 0 then HookOffMouse();
  MHook := SetWindowsHookEx(WH_MOUSE, @MHookProc, HInstance, 0);
  Result := MHook;
end;

function KHookProc(_nCode: integer; _MsgID: WParam; _Data: LParam): LResult; stdcall;
{ keyPressed  := lParam and $80000000 <> 0;
  scancode    := (lParam and $00ff0000) shr 16; 
  extendedkey := lParam and $01000000 <> 0;
  altkey      := lParam and $20000000 <> 0;
Bits 	Description
0-15 	The repeat count. The value is the number of times the keystroke is repeated as a result of the user's holding down the key.
16-23 	The scan code. The value depends on the OEM.
24 	Indicates whether the key is an extended key, such as a function key or a key on the numeric keypad. The value is 1 if the key is an extended key; otherwise, it is 0.
25-28 	Reserved.
29 	The context code. The value is 1 if the ALT key is down; otherwise, it is 0.
30 	The previous key state. The value is 1 if the key is down before the message is sent; it is 0 if the key is up.
31 	The transition state. The value is 0 if the key is being pressed and 1 if it is being released.
}
begin
  try
    Result := 0;
    if _nCode <> HC_ACTION then exit;
    // forwart to Logger
    PostMessage(Master, WM_MyKHook, _MsgID, _Data);
  finally
    Result := CallNextHookEx(KHook, _nCode, _MsgID, _Data);
  end;
end;

function HookOffKeys():boolean; stdcall; export;
begin
  Result := true;
  if KHook = 0 then exit;
  Result := UnhookWindowsHookEx(KHook);
  if Result then KHook := 0;
end;

function HookOnKeys: HHOOK; stdcall; export;
begin
  if KHook <> 0 then HookOffKeys();
  KHook := SetWindowsHookEx(WH_KEYBOARD, @KHookProc, HInstance, 0);
  Result := KHook;
end;

procedure SetLogingMaster(_master:HWND; _mouse,_keys:Boolean); stdcall; export;
begin
  Master := _master;
  fMouse := _mouse;
  fKeys  := _keys;
end;

procedure LogingOn(); stdcall; export;
begin
  if Master = 0 then exit;
  if fMouse then HookOnMouse;
  if fKeys  then HookOnKeys;
end;

procedure LogingOff(var err:cardinal); stdcall; export;
begin
  if fMouse then HookOffMouse;
  if fKeys  then HookOffKeys;
  err:=z;
end;

exports
  HookOffMouse,
  HookOnMouse,
  HookOffKeys,
  HookOnKeys,
  SetLogingMaster,
  LogingOn,
  LogingOff;

begin
  MHook := 0;
  KHook := 0;
  Master := 0;
end.

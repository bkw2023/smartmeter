unit uhook;

interface

uses
  Windows;

function HookOffMouse():boolean; stdcall; 
function HookOnMouse: HHOOK; stdcall; 

function HookOffKeys():boolean; stdcall; 
function HookOnKeys: HHOOK; stdcall; 

procedure SetLogingMaster(_master:HWND; _mouse,_keys:Boolean); stdcall; 
procedure LogingOn(); stdcall; 
procedure LogingOff(var err:cardinal); stdcall;


implementation

function HookOffMouse;     external 'HookInp.dll' Name 'HookOffMouse';    stdcall; 
function HookOnMouse;      external 'HookInp.dll' Name 'HookOnMouse';     stdcall; 

function HookOffKeys;      external 'HookInp.dll' Name 'HookOffKeys';     stdcall; 
function HookOnKeys;       external 'HookInp.dll' Name 'HookOnKeys';      stdcall; 

procedure SetLogingMaster; external 'HookInp.dll' Name 'SetLogingMaster'; stdcall; 
procedure LogingOn;        external 'HookInp.dll' Name 'LogingOn';        stdcall; 
procedure LogingOff;       external 'HookInp.dll' Name 'LogingOff';       stdcall; 

end.
 
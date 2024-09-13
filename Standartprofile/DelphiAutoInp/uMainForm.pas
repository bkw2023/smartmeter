unit uMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Menus, ExtCtrls,
  uunluremouseevent;

type
  TEventEntry = record
    Msg: Cardinal;
    WParam: Longint;
    LParam: Longint;
    Time: Cardinal; // ms
  end;
  TAoTEventEntry = array[0..1023] of TEventEntry;

type
  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    Memo: TMemo;
    StatusBar: TStatusBar;
    File1: TMenuItem;
    Start1: TMenuItem;
    Stop1: TMenuItem;
    Load1: TMenuItem;
    Save1: TMenuItem;
    Exit1: TMenuItem;
    Run1: TMenuItem;
    Single1: TMenuItem;
    Loop1: TMenuItem;
    Repeatn1: TMenuItem;
    Timer: TTimer;
    SaveDialog: TSaveDialog;
    OpenDialog: TOpenDialog;
    procedure WndProc(var Message: TMessage); override;
    procedure Start1Click(Sender: TObject);
    procedure Stop1Click(Sender: TObject);
    procedure DoOnCreate(Sender: TObject);
    procedure Single1Click(Sender: TObject);
    procedure DoOnTimer(Sender: TObject);
    procedure DoOnDestroy(Sender: TObject);
    procedure WMHotKey(var Message:TMessage); message WM_HOTKEY;
    procedure Save1Click(Sender: TObject);
    procedure Load1Click(Sender: TObject);
    procedure Repeatn1Click(Sender: TObject);
  private
    { Private-Deklarationen }
    fLastTime, fTime: longint;
    fIn,fi:cardinal;
    fList:TAoTEventEntry;
    fWraped,fRecord,fPlay:boolean;
    fMaster:HWND;
    fStatus,fErr,fRepeatCount:integer;
  public
    { Public-Deklarationen }
  end;

var
  MainForm: TMainForm;
  scrx,scry:DWORD;
  me:TME;
  px:longint;
  py:longint;

implementation

{$R *.dfm}

uses uHookTypes, uhook;

const cmh2me:array[0..9] of DWORD = (
        MOUSEEVENTF_MOVE,
        MOUSEEVENTF_LEFTDOWN,
        MOUSEEVENTF_LEFTUP,
        MOUSEEVENTF_LEFTDOWN,
        MOUSEEVENTF_RIGHTDOWN,
        MOUSEEVENTF_RIGHTUP,
        MOUSEEVENTF_RIGHTDOWN,
        MOUSEEVENTF_MIDDLEDOWN,
        MOUSEEVENTF_MIDDLEUP,
        MOUSEEVENTF_MIDDLEDOWN
        );
const cmh2rme:array[0..9] of DWORD = (
        0,
        MOUSEEVENTF_LEFTUP,
        MOUSEEVENTF_LEFTDOWN,
        MOUSEEVENTF_LEFTUP,
        MOUSEEVENTF_RIGHTUP,
        MOUSEEVENTF_RIGHTDOWN,
        MOUSEEVENTF_RIGHTUP,
        MOUSEEVENTF_MIDDLEUP,
        MOUSEEVENTF_MIDDLEDOWN,
        MOUSEEVENTF_MIDDLEUP
        );

function SimSingleInput(const e:TEventEntry;var i:integer):integer;
var bVk, bScan : Byte;
    dwFlags : DWORD;
    p : TPoint;
begin with e do begin
  if msg=WM_MyKHook then begin

    bVk:=wParam;
    bScan := lo(hiword(lParam));
    if  (lParam and $80000000) <> 0 then dwFlags:=0
                                    else dwFlags:=KEYEVENTF_KEYUP;
    keybd_event(bVk, bScan, dwFlags, 0);
    result:=0;

  end else begin

    p:=mouse.CursorPos;
    px := TIntPoint(lParam).x;
    py := TIntPoint(lParam).y;
    with me do begin
      if i<2 then begin
        dx:=px-p.x;
        dy:=py-p.y;
        dwFlags := cmh2me[wParam-WM_MOUSEMOVE];
      end else begin
        if (dwFlags = MOUSEEVENTF_LEFTDOWN) or
           (dwFlags = MOUSEEVENTF_RIGHTDOWN) or
           (dwFlags = MOUSEEVENTF_MIDDLEDOWN) then
          if (px<>p.x) or (py<>p.y) then begin
            SetCursorPos(px, py);
            Application.ProcessMessages;
          end;
      end;
    end;

    result:=unstupid_mouse_event(me);
    if result=2 then exit;

    result:=0;
    // double click
    case wParam of
     WM_LBUTTONDBLCLK,
     WM_RBUTTONDBLCLK,
     WM_MBUTTONDBLCLK: ;
    else
      exit;
    end;

    dwFlags := cmh2rme[wParam-WM_MOUSEMOVE];
    Application.ProcessMessages;
    mouse_event(dwFlags, 0, 0, 0, 0);
    Application.ProcessMessages;
    mouse_event(me.dwFlags, 0, 0, 0, 0);
    Application.ProcessMessages;
    mouse_event(dwFlags, 0, 0, 0, 0);

  end;
end; end;

procedure TMainForm.WndProc(var Message: TMessage);
(* TMessage = packed record
    Msg: Cardinal;
    case Integer of
      0: (
        WParam: Longint;
        LParam: Longint;
        Result: Longint);
      1: (
        WParamLo: Word;
        WParamHi: Word;
        LParamLo: Word;
        LParamHi: Word;
        ResultLo: Word;
        ResultHi: Word);

  end; *)
begin
  if (Message.Msg = WM_MyMHook) or (Message.Msg = WM_MyKHook) then begin
    Message.Result := 0;
    if fWraped then exit;
    fList[fIn].Msg:=Message.Msg;
    fList[fIn].WParam:=Message.WParam;
    fList[fIn].LParam:=Message.LParam;
    fTime:=GetTickCount(); // ms Ticks seit Systemstart. Mehr als vier Tage wraparound.
    fList[fIn].Time:=fTime-fLastTime;
    fLastTime:=fTime;
    if fIn < length(fList) then inc(fIn)
                           else begin fWraped:=true; Stop1Click(nil); end;
    statusbar.SimpleText := Format('%4d %s',[fIn, cBool2str[fWraped]]);
    exit;
  end;
  inherited WndProc(Message);
end;

procedure TMainForm.Start1Click(Sender: TObject);
begin
  fLastTime:=GetTickCount();
  fIn:=0;
  fWraped:=false;
  fRecord:=true;
  Visible:=false;
  LogingOn();
end;


// Ergebnis in t[0] ... t[t.Count-1]
function splitfs(s:string;fs:char;var t: TStrings):integer;
begin
  if assigned(t) then
    t.clear
  else
    t := TStringList.Create;
  s:=s+chr(0);
  try
    result := ExtractStrings([fs], [], PChar(s), t);
  except
    result := -1;
  end;
end;

function str2entry(s:string; var e:TEventEntry):integer;
var t:TStrings;
    i,n:integer;
    p:TIntPoint;
begin
  result:=-1;
  n:=splitfs(s,' ',t);
  if n<3 then exit;
  with e do begin
    result:=-2;
    val(t[1],Time,i);
    if i<>0 then exit;
    if t[2]='vk:' then begin
      result:=-3;
      if n<6 then exit;
      Msg:=WM_MyKHook;
      result:=-4;
      i:=Hex2Longint(t[4],WParam);
      if i<0 then exit;
      result:=-5;
      i:=Hex2Longint(t[5],LParam);
      if i<0 then exit;
      exit;
    end;
    result:=-6;
    if n<7 then exit;
    Msg:=WM_MyMHook;
    result:=-7;
    i:=Hex2Longint(t[3],WParam);
    if i<0 then exit;
    result:=-8;
    val(t[5],p.x,i);
    if i<0 then exit;
    result:=-9;
    val(t[7],p.y,i);
    if i<0 then exit;
    LParam:=IntPoint2LParam(p);
  end;
  result:=0;
end;

function entry2str(i:integer; const e:TEventEntry):string;
begin with e do begin
    if msg=WM_MyMHook then begin
      result:=Format('%4d %5d %s %s',[i, Time, mousemsgstr(WParam), IntPoint2str(TIntPoint(LParam))]);
    end else begin
      result:=Format('%4d %5d %s %s %8x %8x',[i, Time, 'vk:', char(WParam), WParam, LParam]);
    end;
end; end;

procedure TMainForm.Stop1Click(Sender: TObject);
var i:integer;
    s:string;
    z:cardinal;
begin
  LogingOff(z);
  fRecord:=false;
  Visible:=true;

  Memo.Lines.Clear;
  // fList in Memo anzeigen
  for i:=0 to fIn-1 do begin
//    with fList[i] do s:=Format('%4d %5d %8x %8x %8x',[i, Time, msg, WParam, LParam]);
    s:=entry2str(i,fList[i]);
    Memo.Lines.Add(s);
  end;
  statusbar.SimpleText := Format('%8d %s',[z, cBool2str[fWraped]]);
end;

procedure TMainForm.DoOnCreate(Sender: TObject);
begin
  fMaster:=MainForm.Handle;
  SetLogingMaster(fMaster, true, true);
  fStatus:=0;
  fRecord:=false;
  fPlay:=false;
  fRepeatCount:=0;

// Infos zu den Paramater
// MOD_ALT ALT muß gedrückt sein
// MOD_CONTROL CTRL muß gedrückt sein
// MOD_SHIFT SHIFT muß gedrückt sein
// MOD_WIN WINDOWS-Taste muß gedrückt sein
  RegisterHotKey(fMaster,1,0,vk_F10);
end;

procedure TMainForm.DoOnDestroy(Sender: TObject);
begin
  UnRegisterHotKey(fMaster,1);
end;

procedure TMainForm.Single1Click(Sender: TObject);
var t:cardinal;
begin
  if assigned(Sender) then fRepeatCount:=0;
  with fList[0] do begin
    px := TIntPoint(lParam).x;
    py := TIntPoint(lParam).y;
  end;
  fStatus:=0;
  fErr:=0;
  fPlay:=true;
  Visible:=false;

  SetCursorPos(px, py);
  fi:=0;
  t:=fList[0].time;
  if t>1000 then t:=1000
  else if t<50 then t:=50;
  Timer.Interval:= t;
  Timer.Enabled := true;
end;

procedure TMainForm.DoOnTimer(Sender: TObject);
var t:cardinal;
begin
  Timer.Enabled := false;
  if not fPlay then exit;
  if fErr>500 then begin
    fPlay:=false;
    Visible:=true;
    statusbar.SimpleText := 'Error in DoOnTimer';
    exit;
  end;
  inc(fErr);

  fStatus:=SimSingleInput(fList[fi],fStatus);
  if fStatus=2 then begin
    Timer.Interval:= 50;
    Timer.Enabled := true;
    exit;
  end;

  fStatus:=0;
  inc(fi);
  if fRepeatCount>0 then
    if fi>=fIn then begin
      Single1Click(nil);
      dec(fRepeatCount);
      exit;
  end;
  if fi<fIn then begin
    fErr:=0;
    t:=fList[fi].time;
    if t>1000 then t:=1000
    else if t<50 then t:=50;
    Timer.Interval:= t;
    Timer.Enabled := true;
  end else begin
    Visible:=true;
  end;
end;

procedure TMainForm.WMHotKey(var Message:TMessage);
begin
  If Message.wParam=1 then begin
    if fRecord then Stop1Click(nil);
    if fPlay then fPlay := false;
    Visible:=true;
  end;
end;

procedure TMainForm.Save1Click(Sender: TObject);
begin
  if SaveDialog.Execute then
    Memo.Lines.SaveToFile(SaveDialog.FileName);
end;

procedure TMainForm.Load1Click(Sender: TObject);
var i:integer;
begin
  if OpenDialog.Execute then begin
    Memo.Lines.LoadFromFile(OpenDialog.FileName);
    if Memo.Lines.Capacity>1024 then begin
      statusbar.SimpleText := 'Error to much Lines (max 1024)';
      exit;
    end;
    fillchar(fList,sizeof(fList),0);
    for i:=0 to Memo.Lines.Capacity-1 do begin
      fErr:=str2entry(memo.Lines[i], fList[i]);
      if fErr<>0 then begin
        statusbar.SimpleText := Format('Error %d in Line %d',[fErr,i]);
        exit;
      end;
    end;
    statusbar.SimpleText := Format('Lines loaded: %d',[Memo.Lines.Capacity]);
  end;
end;

procedure TMainForm.Repeatn1Click(Sender: TObject);
var
  InputString:string;
  i:integer;
begin
  InputString:= InputBox('Repeat Count Input', 'Anzahl der Wiederholungen: ', '0');
  val(InputString, fRepeatCount, i);
  if i<>0 then begin
    fRepeatCount:=0;
    statusbar.SimpleText := 'Error in Inputnumber';
    exit;
  end;
  Single1Click(nil);
end;

initialization
  scrx:=screen.Width;  // 1280
  scry:=screen.Height; //  720
end.


unit umainform;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls, Grids, ComCtrls, ExtCtrls;

type
  TBuffer=array[0..511] of byte;

type
  TMainForm = class(TForm)
    Memo: TMemo;
    MainMenu: TMainMenu;
    File1: TMenuItem;
    Comport: TMenuItem;
    Save: TMenuItem;
    SaveDialog: TSaveDialog;
    StatusBar: TStatusBar;
    StringGrid: TStringGrid;
    erminal1: TMenuItem;
    Connect1: TMenuItem;
    Disconnect1: TMenuItem;
    Timer: TTimer;
    LogAll1: TMenuItem;
    procedure SaveClick(Sender: TObject);
    procedure ComportClick(Sender: TObject);
    procedure Terminal1Click(Sender: TObject);
    procedure Connect1Click(Sender: TObject);
    procedure Disconnect1Click(Sender: TObject);
    procedure OnCreateForm(Sender: TObject);

    procedure OnEditMask(Sender: TObject; ACol, ARow: Integer; var Value: String);
    procedure OnGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: String);
    procedure OnTimerDo(Sender: TObject);
    procedure OnCloseFrame(Sender: TObject; var Action: TCloseAction);
    procedure LogAll1Click(Sender: TObject);
  private
    okkey:boolean;
    fh:THandle;
    fp,fc:string;
    { StringGridEndEdit }
    fvalue:string;
    frow, fcol:integer;
    fEditMode:boolean;
    procedure EndEdit(ACol, ARow: Integer);
  public
    { Public-Deklarationen }
    fZeit1, fZeit2, fZeit3, fZeit4, ltzeit : TDateTime;
    fbr : integer;
    fBuf : TBuffer;
    fLogAll : boolean;
//
    oEditMode:boolean;
//    ototrue,otofalse:integer;
    procedure OnIdleApp(Sender: TObject; var Done: Boolean);
  end;

var
  MainForm: TMainForm;

implementation

uses ucomport, uSMWienerNetze;

{$R *.dfm}

type string2=string[2];

function hex(b:byte):string2;
type twb=array[0..15]of char;
const wb:twb=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
begin hex:=wb[b shr 4]+wb[b and $0f];end;

function ReadSMComPort(fname:string):string;
var txt:text;
begin
  result := 'COM6';
  if not FileExists(fname) then exit;
  AssignFile(txt, fname);
  reset(txt);
  readln(txt, result);
  CloseFile(txt);
end;

procedure TMainForm.ComportClick(Sender: TObject);
begin
  frow:=-1;
  fcol:=-1;
  fvalue :=''; 
  fEditMode:=false;

  StringGrid.Visible := true;
  Memo.Visible := false;
end;

procedure TMainForm.OnCreateForm(Sender: TObject);
begin
  StringGrid.Cells[0,0] :='Comport:';
  StringGrid.Cells[0,1] :='Baudrate:';
  StringGrid.Cells[0,2] :='Parity:';
  StringGrid.Cells[0,3] :='Stopbits:';
  StringGrid.Cells[1,0] :='COM6';
  StringGrid.Cells[1,1] :='9600';
  StringGrid.Cells[1,2] :='N';
  StringGrid.Cells[1,3] :='1';

  StringGrid.Cells[1,0] := ReadSMComPort('SMComPort.txt');

  fLogAll := false;

  frow := -1;
  fcol := -1;
  fvalue := ''; 
  fEditMode := false;

  oEditMode := Stringgrid.EditorMode;

  Application.OnIdle := OnIdleApp;

  fh := INVALID_HANDLE_VALUE;

  okkey := ReadSMKey('SMKey.txt');
  if not okkey then StatusBar.simpletext := 'Fehler beim Lesen von SMKey.txt';
end;

procedure TMainForm.OnCloseFrame(Sender: TObject; var Action: TCloseAction);
begin
  Disconnect1Click(Sender);
end;

procedure TMainForm.OnIdleApp(Sender: TObject; var Done: Boolean);
var em:boolean;
begin
  em:=Stringgrid.EditorMode;
  if em<>oEditMode then begin
    oEditMode:=em;
    if not em then EndEdit(fCol, fRow);
  end;
end;

procedure TMainForm.OnGetEditText(Sender: TObject; ACol, ARow: Integer;
  var Value: String);
begin
  fEditMode:=true;
  fvalue:=StringGrid.Cells[1,ARow];
  frow:=ARow;
  fcol:=ACol;
end;

procedure TMainForm.SaveClick(Sender: TObject);
begin
  if not SaveDialog.Execute then exit;
  memo.lines.SaveToFile(SaveDialog.FileName);
  memo.lines.clear;
end;

procedure TMainForm.Terminal1Click(Sender: TObject);
begin
  StringGrid.Visible := false;
  Memo.Visible := true;
end;

function checkbaud(br:integer):integer;
begin
  result := 2400;
  if br<= result then exit;
  result := 4800;
  if br<= result then exit;
  result := 9600;
  if br<= result then exit;
  result := 19200;
  if br<= result then exit;
  result := 38400;
  if br<= result then exit;
  result := 57600;
  if br<= result then exit;
  result := 115200;
end;

procedure TMainForm.OnEditMask(Sender: TObject; ACol, ARow: Integer; var Value: String);
begin
  Value:='';
  case ARow of
  0: Value:='\COM09';
  1: Value:='!990000';
  2: Value:='C';
  3: Value:='0';
  end;
end;

procedure TMainForm.EndEdit(ACol, ARow: Integer);
var i,ok:integer;
    s:string;
begin
  if ARow = -1 then exit;
  if not fEditMode then exit;
  s:=uppercase(StringGrid.Cells[1,ARow]);
  case ARow of
  1: begin val(s,i,ok);
       if ok<>0 then StringGrid.Cells[1,1]:=fvalue
                else StringGrid.Cells[1,1]:=inttostr(checkbaud(i));
     end;
  2: begin
       if (s<>'N') or (s <> 'E') or (s <> 'O')
         then StringGrid.Cells[1,2] := s
         else StringGrid.Cells[1,2]:=fvalue;
     end;
  3: if (s<>'1') and (s <> '2') then StringGrid.Cells[1,3]:=fvalue;
  end;
  fEditMode := false;
  fvalue:=StringGrid.Cells[1,ARow];
  fRow:=-1;
  fCol:=-1;
end;

procedure TMainForm.Disconnect1Click(Sender: TObject);
begin
  Timer.Enabled := false;
  CloseCom(fh);
  fh := INVALID_HANDLE_VALUE;
end;

procedure TMainForm.Connect1Click(Sender: TObject);
var ok:integer;
begin
  if not okkey then exit;
  fzeit1:=now;
  StatusBar.simpletext := '                                               ';
  if fh <> INVALID_HANDLE_VALUE then begin
    StatusBar.simpletext := 'bereits verbunden';
    exit;
  end;
  fp:=StringGrid.Cells[1,0];
  if not OpenCom(fh, fp) then begin
    StatusBar.simpletext := 'OpenCom misslungen';
    exit;
  end;
  fc:='';
  ok := SetupCom(fh, fc);
  if ok<0 then begin
    StatusBar.simpletext := 'SetupCom misslungen '+inttostr(ok);
    CloseCom(fh);
    fh := INVALID_HANDLE_VALUE;
    exit;
  end;
  OnTimerDo(nil);
end;

{ Meldungen kommen alle 1s
  Die Meldung ist spätestens nach 50ms vollständig da.
}
const c1s = 24.0*60.0*60.0;
var SMData:TSMWienerNetze;
procedure TMainForm.OnTimerDo(Sender: TObject);
var ok:integer;
    t:cardinal;
    rflag,pvrflag,pnrflag:boolean;
    rzd,pvrzd,pnrzd:TDateTime;
    s:string;
begin
  Timer.Enabled := false;
  rflag:=false; pvrflag:=false; pnrflag:=false;
  // leseschleife
  t:=0; fbr:=0; rzd:=0; pvrzd:=0; pnrzd:=0;
  repeat
    fzeit2 := now; // Zeitstempel
    ok:=ReadBBufCom(fh, fBuf[fbr], sizeof(fBuf)-fbr);
    if ok<0 then begin
      StatusBar.simpletext := 'ReadBBufCom misslungen '+inttostr(ok);
      CloseCom(fh);
      fh := INVALID_HANDLE_VALUE;
      exit;
    end else if ok>0 then begin
      if not rflag then begin ltzeit:=fzeit1; fzeit1 := fzeit2; rflag:= true; fbr:=0; end; // Start Zeitstempel
      // byte zählen
      fbr := fbr + ok;
      t:=0;
      pnrflag := false;
      pnrzd := 0;
    end else begin
      if rflag then begin
        if not pnrflag then begin fzeit3:=fzeit2; pnrflag :=true; end;
        pvrflag := false;
      end else begin
        if not pvrflag then begin fzeit4:=fzeit2; pvrflag :=true; end;
      end;
      inc(t);
    end;
    if rflag then begin rzd := fzeit2-fzeit1; rzd:=rzd*c1s*1000; end; // in ms
    if pnrflag then begin pnrzd := fzeit2-fzeit3; pnrzd:=pnrzd*c1s*1000; end; // in ms
    if pvrflag then begin pvrzd := fzeit2-fzeit4; pvrzd:=pvrzd*c1s*1000; end; // in ms

    StatusBar.simpletext :=  format('pv: %3.0f rz: %3.0f pn: %3.0f Bytes: %d Zyklen: %d          ',[pvrzd,rzd,pnrzd,fbr,t]);
    Application.ProcessMessages;
  until (t>2000) or (pvrflag and (pvrzd>50)) or (pnrzd > 50) or (fbr>=sizeof(fBuf));
  if not rflag then begin
    timer.Interval:=100;
  end else begin
    // Anzeigen
    rzd := fzeit1-ltzeit; rzd:=rzd*c1s*1000;
    s:=DateTimeToStr(fzeit1)+format(' lt: %4.0f ',[rzd])+' ('+trim(StatusBar.simpletext)+')';
    ok:=GetSMMsgData(fbuf, fbr, SMData);
    if ok<>0 then begin
      s:=s+format(' *** Fehler %d ',[ok]);
      Memo.Lines.Append(s);
    end;
    with SMData do begin
      if not fLogAll then begin
        if Memo.Lines.Count > 19 then Memo.Lines.Delete(0);
        if Memo.Lines.Count > 19 then Memo.Lines.Delete(0);
      end;
      s:=zaehler+' '+DateTimeToStr(zeit)+format('   P+:%4.0f A+:%9.3f  P-:%4.0f A-:%9.3f',[W_v,kWh_v,W_e,kWh_e]);
      Memo.Lines.Append(s);
    end;
    timer.Interval:=600;
  end;
  if Memo.Lines.Count < 36000 then Timer.Enabled := true
  else StatusBar.simpletext := Trim(StatusBar.simpletext) + ' -> bin fertig';
end;


procedure TMainForm.LogAll1Click(Sender: TObject);
const b2s:array[boolean] of string = ('False', 'True');
begin
  fLogAll := not fLogAll;
  StatusBar.simpletext := 'Set LogAll to '+b2s[fLogAll];
end;

end.

program DelphiAutoInp;

uses
  Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uhook in 'uhook.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

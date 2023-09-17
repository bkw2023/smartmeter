program DelphiSMLesen;

uses
  Forms,
  umainform in 'umainform.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

program Pin2Taskbar;

uses
  Vcl.Forms,
  main in 'main.pas' {Form2},
  RegChangeThread in 'RegChangeThread.pas',
  TaskbarPinner in 'TaskbarPinner.pas',
  GUIDs in 'GUIDs.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.

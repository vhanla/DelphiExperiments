program fmxAcrylic;

uses
  System.StartUpCopy,
  FMX.Forms,
  main in 'main.pas' {Form2},
  shadow in 'shadow.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

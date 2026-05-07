program TxtToPDF;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UImprimeTxt in 'UImprimeTxt.pas';

begin
  try
    TImprimeTxt.ImprimirTxt('C:\COPLOG\TRANS\XXX.TXT');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

program TxtToPDF;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UImprimeTxt in 'UImprimeTxt.pas',
  UExportaExcel in 'UExportaExcel.pas';

const
  ARQUIVO_TXT_PDF = 'C:\COPLOG\TRANS\XXX.TXT';
  ARQUIVO_TXT_EXCEL = '\TRANS\EXC.TXT';

procedure Executar;
var
  Formato: string;
begin
  if ParamCount = 0 then
    Formato := '/pdf'
  else
    Formato := LowerCase(ParamStr(1));

  if Formato = '/pdf' then
    TImprimeTxt.ImprimirTxt(ARQUIVO_TXT_PDF)
  else if Formato = '/excel' then
    TExportaExcel.ExportarTxt(ARQUIVO_TXT_EXCEL)
  else
    raise Exception.CreateFmt('Parametro invalido: %s. Use /pdf ou /excel.', [ParamStr(1)]);
end;

begin
  try
    Executar;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

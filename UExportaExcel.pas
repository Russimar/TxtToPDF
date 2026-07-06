unit UExportaExcel;

interface

uses
  System.SysUtils, System.Classes;

type
  TExportaExcel = class
  public
    class procedure ExportarTxt(const ATxtFile: string);
  end;

implementation

uses
  System.Win.ComObj, System.Variants;

type
  TRegistroCooperado = record
    CodCooperado: string;
    Nome: string;
    ValorTotal: Double;
  end;

class procedure TExportaExcel.ExportarTxt(const ATxtFile: string);
var
  SL: TStringList;
  Registros: TArray<TRegistroCooperado>;
  Qtd: Integer;
  I: Integer;
  Linha: string;
  Reg: TRegistroCooperado;
  TrechoCod, TrechoNome, TrechoValor: string;
  ValorInteiro: Int64;
  ExcelApp: OleVariant;
  Workbook: OleVariant;
  Sheet: OleVariant;
  LinhaPlanilha: Integer;
  NomeSaida: string;

  function ExtrairCampo(const S: string; APosInicial, ATamanho: Integer): string;
  begin
    if Length(S) >= APosInicial then
      Result := Copy(S, APosInicial, ATamanho)
    else
      Result := '';
  end;

begin
  if not FileExists(ATxtFile) then
    raise Exception.Create('Arquivo TXT não encontrado: ' + ATxtFile);

  SL := TStringList.Create;
  try
    SL.LoadFromFile(ATxtFile, TEncoding.ANSI);

    Qtd := 0;
    SetLength(Registros, SL.Count);

    for I := 0 to SL.Count - 1 do
    begin
      Linha := SL[I];

      // ignora linhas em branco (inclusive as do final do arquivo)
      if Trim(Linha) = '' then
        Continue;

      TrechoCod := ExtrairCampo(Linha, 1, 5);
      TrechoNome := ExtrairCampo(Linha, 6, 30);
      TrechoValor := ExtrairCampo(Linha, 36, 10);

      if not TryStrToInt64(Trim(TrechoValor), ValorInteiro) then
        raise Exception.CreateFmt('Linha inválida (valor não numérico) na linha %d: %s', [I + 1, Linha]);

      Reg.CodCooperado := Trim(TrechoCod);
      Reg.Nome := Trim(TrechoNome);
      Reg.ValorTotal := ValorInteiro / 100;

      Registros[Qtd] := Reg;
      Inc(Qtd);
    end;

    SetLength(Registros, Qtd);
  finally
    SL.Free;
  end;

  try
    ExcelApp := CreateOleObject('Excel.Application');
  except
    on E: Exception do
      raise Exception.Create('Excel não está instalado nesta máquina (ou não foi possível iniciar o Excel.Application): ' + E.Message);
  end;

  try
    ExcelApp.Visible := False;
    ExcelApp.DisplayAlerts := False;

    Workbook := ExcelApp.Workbooks.Add;
    Sheet := Workbook.Worksheets.Item[1];

    Sheet.Cells[1, 1] := 'Cod.Cooperado';
    Sheet.Cells[1, 2] := 'Nome';
    Sheet.Cells[1, 3] := 'Valor Total';

    LinhaPlanilha := 2;
    for I := 0 to High(Registros) do
    begin
      Sheet.Cells[LinhaPlanilha, 1] := Registros[I].CodCooperado;
      Sheet.Cells[LinhaPlanilha, 2] := Registros[I].Nome;
      Sheet.Cells[LinhaPlanilha, 3] := Registros[I].ValorTotal;
      Inc(LinhaPlanilha);
    end;

    Sheet.Columns.Item[2].ColumnWidth := 40;

    NomeSaida := ExtractFilePath(ATxtFile) +
      ChangeFileExt(ExtractFileName(ATxtFile), '') +
      '_' + FormatDateTime('hhnn', Now) + '.xlsx';

    Workbook.SaveAs(NomeSaida, 51); // 51 = xlOpenXMLWorkbook (.xlsx)
    Workbook.Close(False);
  finally
    ExcelApp.Quit;
    ExcelApp := Unassigned;
  end;
end;

end.

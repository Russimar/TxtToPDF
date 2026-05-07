unit uTxtToPdf;

interface

uses
  System.SysUtils, System.Classes;

type
  TTxtToPdf = class
  private
    class function LimparControles(const S: string): string;
    class function ContemFormFeed(const S: string): Boolean;
  public
    class procedure Converter(const ATxtFile, APdfFile: string);
  end;

implementation

uses
  SynPdf;

class function TTxtToPdf.LimparControles(const S: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];

    // Mantém TAB e FF apenas se precisar tratar separadamente
    if (C = #9) or (C = #12) or (Ord(C) >= 32) then
      Result := Result + C;
  end;
end;

class function TTxtToPdf.ContemFormFeed(const S: string): Boolean;
begin
  Result := Pos(#12, S) > 0;
end;

class procedure TTxtToPdf.Converter(const ATxtFile, APdfFile: string);
const
  MARGEM_ESQ = 40;
  MARGEM_SUP = 40;
  ALTURA_LINHA = 12;
  LINHAS_POR_PAGINA = 66;
var
  SL: TStringList;
  Pdf: TPdfDocumentGDI;
  I: Integer;
  Y: Integer;
  Linha: string;

  procedure NovaPagina;
  begin
    Pdf.AddPage;
    Pdf.VCLCanvas.Font.Name := 'Courier New';
    Pdf.VCLCanvas.Font.Size := 9;
    Y := MARGEM_SUP;
  end;

  procedure EscreverLinha(const ATexto: string);
  begin
    Pdf.VCLCanvas.TextOut(MARGEM_ESQ, Y, ATexto);
    Inc(Y, ALTURA_LINHA);
  end;

begin
  if not FileExists(ATxtFile) then
    raise Exception.CreateFmt('Arquivo não encontrado: %s', [ATxtFile]);

  SL := TStringList.Create;
  Pdf := TPdfDocumentGDI.Create;
  try
    // Ajuste conforme a origem real do arquivo
    SL.LoadFromFile(ATxtFile, TEncoding.ANSI);

    Pdf.DefaultPageWidth := ppA4;
    Pdf.DefaultPageLandscape := False;
    Pdf.UseOutlines := False;
    Pdf.Info.Author := 'Conversor Delphi 11';
    Pdf.Info.Title := ExtractFileName(APdfFile);
    Pdf.Info.Subject := 'Relatório convertido de TXT para PDF';
    Pdf.Info.Creator := 'Aplicação Delphi 11';

    NovaPagina;

    for I := 0 to SL.Count - 1 do
    begin
      Linha := LimparControles(SL[I]);

      if ContemFormFeed(Linha) then
      begin
        Linha := StringReplace(Linha, #12, '', [rfReplaceAll]);
        if Linha <> '' then
          EscreverLinha(Linha);

        NovaPagina;
        Continue;
      end;

      if (Y > MARGEM_SUP + (LINHAS_POR_PAGINA * ALTURA_LINHA)) then
        NovaPagina;

      EscreverLinha(Linha);
    end;

    Pdf.SaveToFile(APdfFile);
  finally
    Pdf.Free;
    SL.Free;
  end;
end;

end.

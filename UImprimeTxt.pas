unit UImprimeTxt;

interface

uses
  System.SysUtils, System.Classes;

type
  TImprimeTxt = class
  public
    class procedure SelecionarImpressora(const ANomeImpressora: string);
    class procedure ImprimirTxt(const ATxtFile: string);
  end;


implementation

uses
  Vcl.Printers, Vcl.Graphics, Winapi.Windows;

class procedure TImprimeTxt.ImprimirTxt(const ATxtFile: string);
var
  SL: TStringList;
  I: Integer;
  Y: Integer;
  AlturaLinha: Integer;
  MargemEsq: Integer;
  MargemSup: Integer;
  Linha: string;
  JaIniciouPagina: Boolean;

  function LimparControles(const S: string): string;
  var
    X: Integer;
    C: Char;
  begin
    Result := '';
    for X := 1 to Length(S) do
    begin
      C := S[X];

      // mantém apenas caracteres imprimíveis e TAB
      if (C = #9) or (Ord(C) >= 32) then
        Result := Result + C;
    end;
  end;

  function EhCabecalhoPagina(const S: string): Boolean;
  begin
    Result :=
      (Pos('COOPLOGEXPRESS', UpperCase(S)) > 0) and
      (Pos('PAG:', UpperCase(S)) > 0);
  end;

begin
  if not FileExists(ATxtFile) then
    raise Exception.Create('Arquivo TXT não encontrado: ' + ATxtFile);

  SL := TStringList.Create;
  try
    SL.LoadFromFile(ATxtFile, TEncoding.ANSI);

    SelecionarImpressora('Microsoft Print to PDF (2 redirecionada)');

    Printer.Orientation := poLandscape;
    Printer.BeginDoc;
    try
      Printer.Canvas.Font.Name := 'Courier New';
      Printer.Canvas.Font.Size := 8;

      AlturaLinha := Printer.Canvas.TextHeight('W');
      MargemEsq := 60;
      MargemSup := 60;
      Y := MargemSup;
      JaIniciouPagina := False;

      for I := 0 to SL.Count - 1 do
      begin
        Linha := LimparControles(SL[I]);

        // ignora linhas totalmente vazias no começo absoluto
        if (not JaIniciouPagina) and (Trim(Linha) = '') then
          Continue;

        // se encontrou novo cabeçalho de página e já havia conteúdo,
        // força nova página antes de imprimir o cabeçalho
        if EhCabecalhoPagina(Linha) then
        begin
          if JaIniciouPagina then
          begin
            Printer.NewPage;
            Y := MargemSup;
          end;

          JaIniciouPagina := True;
        end;

        // quebra por limite físico da página
        if Y + AlturaLinha > Printer.PageHeight - MargemSup then
        begin
          Printer.NewPage;
          Y := MargemSup;
        end;

        Printer.Canvas.TextOut(MargemEsq, Y, Linha);
        Inc(Y, AlturaLinha);
      end;
    finally
      Printer.EndDoc;
    end;
  finally
    SL.Free;
  end;
end;

class procedure TImprimeTxt.SelecionarImpressora(const ANomeImpressora: string);
var
  I: Integer;
  Encontrou: Boolean;
begin
  Encontrou := False;
  for I := 0 to Printer.Printers.Count - 1 do
  begin
    if SameText(Printer.Printers[I], ANomeImpressora) then
    begin
      Printer.PrinterIndex := I;
      Encontrou := True;
      Break;
    end;
  end;
  if not Encontrou then
    raise Exception.CreateFmt('Impressora não encontrada: %s', [ANomeImpressora]);
end;

end.

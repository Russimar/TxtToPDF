unit UImprimeTxt;

interface

uses
  System.SysUtils, System.Classes;

type
  TImprimeTxt = class
  public
    class procedure SelecionarImpressora(const ATrechoNomeImpressora: string);
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

      // mant�m apenas caracteres imprim�veis e TAB
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
    raise Exception.Create('Arquivo TXT n�o encontrado: ' + ATxtFile);

  SL := TStringList.Create;
  try
    SL.LoadFromFile(ATxtFile, TEncoding.ANSI);

    SelecionarImpressora('Microsoft Print to PDF');

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

        // ignora linhas totalmente vazias no come�o absoluto
        if (not JaIniciouPagina) and (Trim(Linha) = '') then
          Continue;

        // se encontrou novo cabe�alho de p�gina e j� havia conte�do,
        // for�a nova p�gina antes de imprimir o cabe�alho
        if EhCabecalhoPagina(Linha) then
        begin
          if JaIniciouPagina then
          begin
            Printer.NewPage;
            Y := MargemSup;
          end;

          JaIniciouPagina := True;
        end;

        // quebra por limite f�sico da p�gina
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

class procedure TImprimeTxt.SelecionarImpressora(const ATrechoNomeImpressora: string);
var
  I: Integer;
  Encontrou: Boolean;
begin
  Encontrou := False;
  for I := 0 to Printer.Printers.Count - 1 do
  begin
    if Pos(UpperCase(ATrechoNomeImpressora), UpperCase(Printer.Printers[I])) > 0 then
    begin
      Printer.PrinterIndex := I;
      Encontrou := True;
      Break;
    end;
  end;
  if not Encontrou then
    raise Exception.CreateFmt('Nenhuma impressora encontrada contendo: %s', [ATrechoNomeImpressora]);
end;

end.

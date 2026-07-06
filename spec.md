# Spec — TxtToPDF

## Visão geral

Aplicativo console em Delphi que converte relatórios de texto fixo gerados pelo COBOL (`C:\COPLOG\TRANS\*.TXT`) em saída impressa/PDF. O projeto vai evoluir para também suportar exportação para Excel, e remover a dependência de um nome fixo de impressora PDF.

## Estado atual

- [TxtToPDF.dpr](TxtToPDF.dpr) — console app. Roteia por `ParamStr(1)`: `/pdf` chama `TImprimeTxt.ImprimirTxt` com `C:\COPLOG\TRANS\XXX.TXT` (hardcoded); `/excel` chama `TExportaExcel.ExportarTxt` com `C:\COPLOG\TRANS\EXC.TXT` (hardcoded, arquivo diferente).
- [UImprimeTxt.pas](UImprimeTxt.pas) — única unit compilada no `.dproj`. Lê o TXT, limpa caracteres de controle, detecta cabeçalho de página (`COOPLOGEXPRESS` + `PAG:`) e imprime via `Vcl.Printers`.
  - `SelecionarImpressora` busca pelo nome **exato** `"Microsoft Print to PDF (2 redirecionada)"` — isso só funciona na máquina onde esse nome foi configurado.
- [uTxtToPdf.pas](uTxtToPdf.pas) — protótipo órfão (não está no `.dproj`), gera PDF nativamente via `SynPdf`, sem depender de impressora.
- [View.Principal.pas](View.Principal.pas) / `.dfm` — form VCL vazia, órfã, não compilada no projeto.

## Mudanças planejadas

### 1. Remover dependência do nome fixo de impressora PDF

Hoje `SelecionarImpressora` exige o nome exato `"Microsoft Print to PDF (2 redirecionada)"`. Isso quebra em máquinas onde a impressora PDF tem outro nome/sufixo (ex: sem o "(2 redirecionada)", ou outro número de instância).

**Abordagem definida:** buscar entre as impressoras instaladas qualquer nome que **contenha** `"Microsoft Print to PDF"` (case-insensitive, ignorando sufixos como "(2 redirecionada)", "(redirecionado N)", etc.), em vez de exigir igualdade exata de string.

- Se nenhuma impressora corresponder ao padrão, deve lançar erro claro indicando que nenhuma impressora "Microsoft Print to PDF" foi encontrada.
- Mantém a abordagem atual via `Vcl.Printers` (impressão para impressora virtual), não migra para geração nativa via `SynPdf` neste momento.

### 2. Exportação para Excel

O executável passa a receber um **parâmetro de linha de comando** indicando o formato de saída desejado: PDF ou Excel. Cada formato lê um arquivo de origem **diferente**, ambos fixos/hardcoded (não parametrizados nesta etapa), pois são relatórios distintos com layouts distintos:

- `/pdf` (ou ausência de parâmetro) → lê `C:\COPLOG\TRANS\XXX.TXT` (relatório COBOL completo, layout de largura variável).
- `/excel` → lê `C:\COPLOG\TRANS\EXC.TXT` (relatório simples de posição fixa, ver seção "Exportação para Excel" abaixo).

- Sintaxe definida: `TxtToPDF.exe /pdf` ou `TxtToPDF.exe /excel`. Sem parâmetro, equivale a `/pdf` (mantém o comportamento atual). Qualquer outro valor é parâmetro inválido e deve gerar erro claro, sem crash.

**Layout de colunas (decidido):** o arquivo de origem para exportação Excel usa **posição fixa** de 45 colunas por linha, sem cabeçalho, rodapé ou linhas de totais/resumo a filtrar — um cooperado por linha:

| Campo | Posição | Largura | Observação |
|---|---|---|---|
| Código do cooperado | 1–5 | 5 | numérico |
| Nome | 6–35 | 30 | texto, padding de espaços à direita |
| Valor total | 36–45 | 10 | 8 dígitos inteiros + 2 decimais implícitos (ex: `0000016000` = 160,00) |

Exemplo de arquivo real: [documents/EXC.TXT](documents/EXC.TXT).

**Nota histórica:** a análise anterior era sobre um arquivo diferente ([documents/XXX.TXT](documents/XXX.TXT), relatório COBOL completo com cabeçalhos, bloco de detalhe por cooperado, bloco "resumo por função" e totais), que motivou a decisão de usar split por 2+ espaços em vez de posição fixa. `EXC.TXT` é o arquivo real de referência para a Sprint 3 e tem um layout muito mais simples — **essa estratégia de split foi descartada**. Não há linhas a filtrar nem blocos a mesclar neste formato.

**Colunas na planilha:** `Cod.Cooperado`, `Nome`, `Valor Total` (valor formatado como número decimal, ex: `160.00`).

**Importante:** essas regras valem **apenas para a geração do Excel**. A impressão/geração de PDF continua usando exclusivamente a lógica já existente em `EhCabecalhoPagina` (detecção de `COOPLOGEXPRESS` + `PAG:`) — nenhuma mudança no fluxo de impressão.

**Geração do arquivo Excel:** via **COM Automation** (`Excel.Application`/`Vcl.ComObj`), instanciando o Excel instalado na máquina para criar a planilha, escrever cabeçalhos e linhas, e salvar. Sem fallback nativo por ora — se a instanciação do COM falhar (Excel não instalado), lança erro claro.

**Nome do arquivo de saída:** dinâmico, baseado no nome do TXT de origem + hora e minuto atuais, salvo na mesma pasta do TXT. Convenção: `<NomeBase>_HHmm.xlsx` (ex: `EXC_1432.xlsx`).

## Pendências / a definir antes de implementar

- [x] Layout exato de posições fixas das colunas do TXT (`EXC.TXT`: 5 + 30 + 10 = 45 colunas).
- [x] Biblioteca/abordagem para geração do Excel: COM Automation, sem fallback nativo por ora.
- [x] Nome do arquivo de saída: `<NomeBase>_HHmm.xlsx`, mesma pasta do TXT de origem.

## Fora de escopo (por ora)

- Migração da impressão para geração de PDF nativa via `SynPdf` (arquivo [uTxtToPdf.pas](uTxtToPdf.pas) permanece como protótipo, não integrado).
- Interface gráfica ([View.Principal.pas](View.Principal.pas)) — não será desenvolvida nesta etapa.
- Parametrização do caminho dos arquivos TXT de origem (continuam hardcoded, um para cada formato).
- Fallback nativo de geração `.xlsx`/`.csv` sem Excel instalado (COM Automation é a única via por ora).

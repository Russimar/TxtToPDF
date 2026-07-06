# Plan — TxtToPDF

Referência: [spec.md](spec.md). Cada sprint assume que a anterior foi concluída e validada.

## Sprint 0 — Levantamento de pendências (bloqueante)

Sem produção de código. Bloqueia o início da Sprint 3 (parser de colunas) e deve ser resolvida antes dela.

- [ ] Receber do usuário o layout exato de posições fixas das colunas do TXT do COBOL (campo, posição inicial, posição final/largura).
- [ ] Confirmar a sintaxe exata do parâmetro de linha de comando para escolher PDF vs Excel (ex: `/pdf`, `/excel`).
- [ ] Confirmar convenção de nome/diretório de saída dos arquivos gerados (PDF e Excel).
- [ ] Decidir biblioteca para geração nativa de `.xlsx` sem COM (fallback da Sprint 4).

**Saída esperada:** spec.md atualizado, pendências fechadas, sprints seguintes liberadas.

---

## Sprint 1 — Impressora PDF por nome parcial ✅ concluída

Mudança pequena e isolada, sem dependências externas.

- [x] Alterar `TImprimeTxt.SelecionarImpressora` em [UImprimeTxt.pas](UImprimeTxt.pas) para buscar impressora cujo nome **contenha** `"Microsoft Print to PDF"` (case-insensitive), em vez de igualdade exata.
- [x] Lançar erro claro quando nenhuma impressora correspondente for encontrada (mensagem deve mencionar o padrão buscado, não o nome antigo fixo).
- [ ] Testar em pelo menos dois nomes de impressora diferentes (ex: `"Microsoft Print to PDF"` e `"Microsoft Print to PDF (2 redirecionada)"`) para validar o match parcial — **pendente de teste manual em máquina real**, build apenas validado via `dcc32`.

**Saída esperada:** impressão funciona independente do sufixo/numeração da impressora PDF instalada na máquina.

---

## Sprint 2 — Parâmetro de linha de comando e roteamento PDF/Excel ✅ concluída

Introduz a interface de seleção de formato, sem ainda implementar a exportação Excel de fato.

- [x] Definir e implementar leitura do parâmetro de linha de comando em [TxtToPDF.dpr](TxtToPDF.dpr) (usando `ParamStr`/`ParamCount`). Sintaxe: `/pdf` (ou ausência de parâmetro) e `/excel`.
- [x] Roteamento: `/pdf`/ausência chama `TImprimeTxt.ImprimirTxt`; `/excel` chama `TExportaExcel.ExportarTxt` (nova unit [UExportaExcel.pas](UExportaExcel.pas), stub que lança "não implementado" até a Sprint 4).
- [x] Validar parâmetro desconhecido/inválido com mensagem de erro clara (sem crash) — testado manualmente via `dcc32` build + execução.
- [x] Manter caminho do TXT de origem hardcoded, conforme spec. **Atualizado:** cada formato usa um arquivo de origem hardcoded diferente — `ARQUIVO_TXT_PDF = 'C:\COPLOG\TRANS\XXX.TXT'` e `ARQUIVO_TXT_EXCEL = 'C:\COPLOG\TRANS\EXC.TXT'` (constantes separadas em [TxtToPDF.dpr](TxtToPDF.dpr)), já que são relatórios distintos.

**Saída esperada:** `TxtToPDF.exe` aceita o parâmetro de formato e roteia corretamente, mesmo que o caminho Excel ainda não esteja implementado (pode ser um stub que lança "não implementado" até a Sprint 4).

---

## Sprint 3 — Parser de colunas fixas → campos ✅ concluída

Arquivo real de referência recebido: `documents/EXC.TXT`. Layout simples de posição fixa (45 colunas, sem cabeçalho/rodapé/totais). A estratégia anterior de split por 2+ espaços (baseada em `documents/XXX.TXT`) foi **descartada** — não se aplica a este formato.

- [x] Receber e analisar `documents/EXC.TXT`: layout fixo código (1-5) + nome (6-35) + valor (36-45, 8+2 implícitos).
- [x] Decidir estratégia de parsing: slice por posição fixa (sem split por espaços, sem classificação de linha — todo registro é uma linha de cooperado).
- [x] Implementar parsing em `UExportaExcel.pas`: lê cada linha, extrai código/nome/valor, converte valor para decimal dividindo por 100.

**Saída esperada:** dado o TXT de origem, conseguimos obter uma lista de registros (código, nome, valor) prontos para virar linhas de planilha.

---

## Sprint 4 — Geração do Excel via COM Automation ✅ concluída

Depende da Sprint 3 (dados já estruturados) e da Sprint 2 (roteamento já existente).

- [x] Implementar geração via COM Automation (`Excel.Application` / `Vcl.ComObj`): criar planilha, escrever cabeçalhos (`Cod.Cooperado`, `Nome`, `Valor Total`) e linhas a partir dos registros parseados, salvar arquivo.
- [x] Nome do arquivo de saída: `<NomeBase>_HHmm.xlsx`, salvo na mesma pasta do TXT de origem.
- [x] Erro claro se COM Automation falhar ao instanciar `Excel.Application` (Excel não instalado) — sem fallback nativo por ora (fora de escopo, ver spec.md).
- [ ] Testar em máquina real com Excel instalado — **pendente de teste manual**, build validado apenas via `dcc32`.

**Saída esperada:** `TxtToPDF.exe /excel` gera planilha `.xlsx` com as 3 colunas corretas, desde que o Excel esteja instalado na máquina.

---

## Sprint 5 — Validação final e documentação

- [ ] Testar fluxo completo PDF (Sprint 1) e Excel (Sprint 4) lado a lado, no mesmo arquivo de origem.
- [ ] Atualizar [README.md](README.md) com instruções de uso do parâmetro de linha de comando.
- [ ] Revisar spec.md e marcar pendências resolvidas.
- [ ] Limpeza: decidir destino dos arquivos órfãos ([uTxtToPdf.pas](uTxtToPdf.pas), [View.Principal.pas](View.Principal.pas)) — manter como protótipo documentado ou remover, conforme decisão do usuário (fora de escopo até aqui).

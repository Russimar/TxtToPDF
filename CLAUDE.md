# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project does

Delphi console application that converts fixed-width COBOL report output (`C:\COPLOG\TRANS\*.TXT`) into a printed PDF. It is being extended to also export to Excel. See [spec.md](spec.md) for the full functional spec and [plan.md](plan.md) for the sprint breakdown — **read both before making changes**, they are the source of truth for in-progress work and open decisions (column layout, CLI parameter syntax, output file naming are still pending).

## Build

This is a Delphi/VCL project (Delphi 11, Win32). There is no command-line test runner or linter — building is done through the Delphi IDE or `msbuild` with the RAD Studio toolchain (`TxtToPDF.dproj`, targets `Debug`/`Release`, platform `Win32`). There are no automated tests in this repo; validation is manual (run the produced `.exe` against a sample `.TXT` file).

## Architecture

- [TxtToPDF.dpr](TxtToPDF.dpr) — the only entry point, `{$APPTYPE CONSOLE}`. Currently calls `TImprimeTxt.ImprimirTxt` with a **hardcoded** source path (`C:\COPLOG\TRANS\XXX.TXT`).
- [TxtToPDF.dproj](TxtToPDF.dproj) — the actual compiled unit list (`DCCReference`). **This is the source of truth for what's part of the build**, not just the presence of a `.pas` file in the folder.
- [UImprimeTxt.pas](UImprimeTxt.pas) — the only unit referenced in `.dproj` besides the `.dpr`. `TImprimeTxt` class:
  - `ImprimirTxt`: loads the TXT (ANSI encoding), strips control characters (keeps TAB and printables), detects report page headers via `EhCabecalhoPagina` (looks for `COOPLOGEXPRESS` + `PAG:`), and prints via `Vcl.Printers` in landscape, Courier New 8pt, with manual page-break logic based on text height.
  - `SelecionarImpressora`: picks a printer by **exact name match**. Currently hardcoded to `"Microsoft Print to PDF (2 redirecionada)"` — this is the dependency spec.md Sprint 1 plans to remove (match by substring instead of exact name, since the PDF printer name varies per machine).

### Orphaned files (not in `.dproj`, do not compile into the project)

- [uTxtToPdf.pas](uTxtToPdf.pas) — prototype using `SynPdf` (Synopse/mORMot, present as prebuilt `.dcu`s under `Win32\Debug\`) to generate PDF natively without going through a virtual printer. Detects form-feed (`#12`) instead of the textual header to break pages. Not wired into the build; kept as reference for a possible future approach (see "Fora de escopo" in spec.md).
- [View.Principal.pas](View.Principal.pas) / `.dfm` — empty VCL form skeleton, also excluded from `.dproj`. No functionality yet.

Treat anything not in `TxtToPDF.dproj`'s `DCCReference` list as **not part of the running application**, even if it sits in the repo root.

## Current implementation state (2026-06-29)

- **Sprint 1** ✅ — `SelecionarImpressora` in [UImprimeTxt.pas](UImprimeTxt.pas) now matches by substring (`"Microsoft Print to PDF"`), not exact name.
- **Sprint 2** ✅ — [TxtToPDF.dpr](TxtToPDF.dpr) reads `ParamStr(1)`: `/pdf` (or no arg) → print flow; `/excel` → `TExportaExcel.ExportarTxt` stub in new [UExportaExcel.pas](UExportaExcel.pas) (also registered in `.dproj`). Source path extracted as constant `ARQUIVO_TXT`.
- **Sprint 3** ⏸ — Parser strategy decided (split by 2+ spaces — see below), awaiting new TXT file from user to validate and implement.
- **Sprints 4–5** 🔒 blocked on Sprint 3.

## Source data shape (important for the Excel work)

The COBOL TXT reports (see [documents/XXX.TXT](documents/XXX.TXT) for a real example) mix multiple structurally different line types in the same file: page headers, report metadata (`RFAT171:`), letter-spaced section titles (e.g. `R E S U M O   P O R   F U N C A O`), dashed/equals separators, a cooperado detail block, and a "resumo por função" block with a different (but overlapping) column set. spec.md documents exactly which lines must be filtered out and how the two data blocks should be merged into one Excel table — this logic is **Excel-export only**; the existing PDF/print path (`EhCabecalhoPagina`) must not change.

**Parser strategy (decided):** do NOT use fixed character-position slicing — long field values (e.g. rubrica "DESCANSO SEM. REMUNERADO") overflow their column and corrupt adjacent fields. Use **split by 2+ consecutive spaces** as the column separator instead. The COBOL report uses generous inter-column spacing, making this reliable. The parser must classify each line before splitting: `detalhe` (has numeric c.cop at start) / `continuacao` (blank c.cop/nome/fun/funcao — inherits those from previous cooperado) / `total_cooperado` / `resumo_funcao` / `total_funcao` / `filtrada`. Filtered lines never reach the Excel path.

## Working agreement on this repo

- Do not write implementation code until explicitly asked to — spec.md and plan.md are built up first, in conversation, before any `.pas` changes.
- spec.md and plan.md must stay in sync with decisions made in conversation; update them as part of any planning discussion, not just code changes.

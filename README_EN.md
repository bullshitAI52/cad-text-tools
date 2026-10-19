# CAD Text Tools: MT2CSV, FONTFIX and EXPLODEATT

This repository contains three AutoCAD AutoLISP utilities.

## MT2CSV

MT2CSV extracts `TEXT` and `MTEXT` objects from a drawing and saves them as a CSV file that can be opened in Excel. It removes CAD formatting codes and supports two ordering modes:

- **Select order**: text is exported in the order you click it.
- **XY order**: text is arranged by drawing position, generally top-to-bottom and left-to-right.

### How to use MT2CSV

1. Open AutoCAD and run `APPLOAD`.
2. Load `plugins/mt2csv/MT2CSV-V4.lsp`.
3. Run the `MT2CSV` command.
4. Choose the ordering mode. Press Enter for the default mode, or enter `XY` for coordinate-based ordering.
5. Select the text objects and press Enter.
6. Find the generated, time-stamped CSV file on the desktop.

## FONTFIX

FONTFIX helps repair text that displays incorrectly because of inconsistent or missing fonts. It changes selected text, or all text in the drawing, to the `STANDARD` text style.

### How to use FONTFIX

1. Load `plugins/fontfix/FONTFIX.LSP` with `APPLOAD`.
2. Run `FONTFIX`.
3. Enter `A` to process the whole drawing, or `S` to select objects manually.
4. Follow the command-line prompts.

Always test on a copy first because the command changes text styles.

## EXPLODEATT

EXPLODEATT converts attribute values inside blocks, especially dynamic blocks, into ordinary editable text. It is useful when the built-in `EXPLODE` or `X` command creates overlapping, incorrect, or unusable attribute text.

### How to use EXPLODEATT

1. Load `plugins/explodeatt/EXPLODEATT-V6.LSP` with `APPLOAD`.
2. Run `EXPLODEATT`.
3. Select the blocks to process and press Enter.
4. Wait for the completion message and review the generated text.

`XATT` is also available as a shortcut command.

## Recommended workflow

For attributes inside dynamic blocks, run EXPLODEATT first, review the result, and then use MT2CSV to export the ordinary text. If the drawing already contains normal `TEXT` or `MTEXT`, MT2CSV can be used directly.

Use copies of drawings for testing. The utilities may modify attributes, text styles, or create new text objects.

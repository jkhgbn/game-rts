# lens portrait: wizard_portraits

2026-09-27 08:47:58 - `tools/lens/run_lens.ps1 portrait wizard_portraits` - hash `3670f62ac843a2fe`

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 5 PASS, 0 info, 0 skipped, 11 s

## Improve next

## Spec
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | spec | PASS 100 | 0 shots, 0 icon groups, 4 portraits | 0 errors |  |

## Portrait rule (LensSolver size on the Head pivot, head top 8 % down, centred)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R_vessa | vessa head framing | PASS 100 | head 71 % of the height (target 71 %), top 9 %, centre -1 % | +-10 % of the target, top 8 +- 5 %, centre +- 10 % |  |
| R_malrik | malrik head framing | PASS 100 | head 62 % of the height (target 61 %), top 6 %, centre +2 % | +-10 % of the target, top 8 +- 5 %, centre +- 10 % |  |
| R_torvald | torvald head framing | PASS 100 | head 77 % of the height (target 78 %), top 9 %, centre +0 % | +-10 % of the target, top 8 +- 5 %, centre +- 10 % |  |
| R_ysolde | ysolde head framing | PASS 100 | head 70 % of the height (target 69 %), top 7 %, centre -0 % | +-10 % of the target, top 8 +- 5 %, centre +- 10 % |  |

## Images
- vessa: [../../../../../art/portraits/vessa.png](../../../../../art/portraits/vessa.png)
- malrik: [../../../../../art/portraits/malrik.png](../../../../../art/portraits/malrik.png)
- torvald: [../../../../../art/portraits/torvald.png](../../../../../art/portraits/torvald.png)
- ysolde: [../../../../../art/portraits/ysolde.png](../../../../../art/portraits/ysolde.png)
- sheet: [portraits_sheet.png](portraits_sheet.png)

## Notes
- Portraits written to art/portraits/<speaker>.png (cinematics.md 1 folder). One rule: the LensSolver size of the line (default cu; the wizards use mcu so hats / antlers fit), head top 8 % down, centred, 3/4 view, kingdom gradient.

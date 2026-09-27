# Build Lab scorecard: review-blocked

2026-09-27 07:38 - lab v1.0 - preset **Windows Desktop** (release) - build: `C:\Users\elzzo\Documents\four-wizards-builds\review-blocked`

## Result: **BLOCKED** - no score (this PC cannot export)

**Godot 4.7.2.stable export templates are not installed on this PC (windows_release_x86_64.exe).** Nothing is wrong with the game; the export, boot, smoke, sizes and zip did not run. The preset's filter settings were still checked (table below).

0 FAIL - 0 WARN. Score = 100 - 40 per failed export / boot / smoke - 20 per other FAIL - 5 per WARN (0 if the export failed).

## Improve next
1. **Export** (BLOCKED): Godot 4.7.2.stable export templates are not installed on this PC (windows_release_x86_64.exe); looked in: C:\Users\elzzo\AppData\Roaming\Godot\export_templates\4.7.2.stable\windows_release_x86_64.exe ; C:\Godot\editor_data\export_templates\4.7.2.stable\windows_release_x86_64.exe. Nothing is wrong with the game: an export needs the templates (~1 GB download; the lab never downloads). -> Install them once (Editor > Manage Export Templates > Download and Install), or run the Build Lab on the PC that has them. No earlier build under C:\Users\elzzo\Documents\four-wizards-builds to re-test.

## Checks
| Check | Result | Detail |
|---|---|---|
| Export | BLOCKED | Godot 4.7.2.stable export templates are not installed on this PC (windows_release_x86_64.exe); looked in: C:\Users\elzzo\AppData\Roaming\Godot\export_templates\4.7.2.stable\windows_release_x86_64.exe ; C:\Godot\editor_data\export_templates\4.7.2.stable\windows_release_x86_64.exe. Nothing is wrong with the game: an export needs the templates (~1 GB download; the lab never downloads). |
| Filter: excludes dev folders | PASS | exclude_filter = tests/*, docs/*, tools/*, art/preview/* |
| Filter: includes *.json | PASS | include_filter = *.json |

## Sizes
| Item | Size | Previous (2026-09-26_2350) | Delta |
|---|---|---|---|
| FourWizards.exe (with embedded pack) | 0.0 MB | 138.8 MB | -138.8 MB |
| pack | 0.0 MB | 34.7 MB | -34.7 MB |
| engine part (exe - pack) | 0.0 MB | 104.1 MB | -104.1 MB |

## Playtest copy (the lab never copies to OneDrive)
No zip this run.

Logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\build\lab\review-blocked\logs`. Re-run: `tools\build_lab\build_lab.ps1` (see docs/plan/build-lab.md).

# Build Lab: one-click Windows export, smoke test of the EXPORTED build, size report, playtest zip

The Build Lab (Labs program item 7 in `docs/plan/waves.md`) exports the game with the existing preset in
`export_presets.cfg` into a folder **outside the repo**, checks that the exported exe really runs (boot + the gameplay
smoke test on the exported exe, not the editor), reports exe / pack sizes and the biggest files (with the change vs the
previous build), checks the export filter, and zips the build. It **never copies anything to OneDrive**: it prints the
ready zip path and the copy command, which the lead runs only after asking the user. Scorecard in the labs' format
(PASS / WARN / FAIL, score 0-100, "Improve next") + a history line per run. It never edits game files and never runs git.

Files: `tools/build_lab/build_lab.ps1` (the whole lab, Windows PowerShell 5.1), self-test `tools/build_lab/test_build_lab.ps1`
(`PASS build_lab`; synthetic pack formats 2 + 3, embedded and side `.pck`, fake project, no Godot, ~4 s). Output: `docs/build/lab/<run>/`
(`scorecard.md`, `scorecard.json`, `logs/export.log`, `logs/boot.log`, `logs/smoke.log`) and `docs/build/lab/history.jsonl`.
The build itself: `C:\Users\elzzo\Documents\four-wizards-builds\<run>\` (`game\FourWizards.exe` +
`game\FourWizards.console.exe`, `FourWizards-<date>.zip`, `pck_files.json` = full pack listing for the next diff,
`smoke\smoke_test.gd` = the copy the exported exe runs).

## 1. Commands
```powershell
cd C:\Users\elzzo\Documents\four-wizards-rts
tools\build_lab\build_lab.ps1                                  # export + boot + smoke + sizes + filter + zip
tools\build_lab\build_lab.ps1 -SkipSmoke                       # boot check only (faster, ~1 min after the export)
tools\build_lab\build_lab.ps1 -BuildDir C:\Users\elzzo\Documents\four-wizards-builds\<run>   # re-test a build, no export
tools\build_lab\build_lab.ps1 -AnalyzeOnly -BuildDir <dir>     # sizes + filter checks only, no Godot at all (~1.5 min)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build_lab\test_build_lab.ps1   # self-test
```
| Parameter | Meaning |
|---|---|
| `-Preset` | preset name (default: the first `Windows Desktop` preset, today `"Windows Desktop"`) |
| `-BuildsRoot` | default `C:\Users\elzzo\Documents\four-wizards-builds` (refused if inside the repo or OneDrive) |
| `-BuildDir` | re-use an existing build folder (skips the export; finds `game\*.exe` or any exe below) |
| `-ExportDebug` | `--export-debug` instead of `--export-release` |
| `-SkipBoot` / `-SkipSmoke` / `-SkipZip` | skip that step |
| `-AnalyzeOnly` | no Godot, no zip: pack listing, sizes, filter checks |
| `-BootFrames` (600) / `-SmokeFrames` (7000) | `--quit-after` caps, at `--fixed-fps 60` |
| `-ExportTimeoutSec` (3600) / `-RunTimeoutSec` (1800) | wall-clock kill of the lab's own process tree |
| `-GrowthWarnPct` (10) | WARN when the exe grew more than this vs the previous build |
| `-Run`, `-OutDir`, `-HistoryFile`, `-NoHistory`, `-TopN` (25) | as in the other labs |
| `-ProjectRoot` | tests only: analyse against a fake project folder instead of the repo |

Exit code: 1 on FAIL, 0 otherwise.

## 2. What it does
1. **Export**: `Godot_console.exe --headless --path <repo> --export-release "Windows Desktop" <build>\game\FourWizards.exe`,
   launched through `tools/godot_run.ps1` (the Godot gate). The preset embeds the pack in the exe
   (`binary_format/embed_pck=true`) and writes a console wrapper (`FourWizards.console.exe`).
   FAIL: timeout, no exe, non-zero exit. WARN: error lines in the export log.
2. **Pack listing**: reads the Godot pack directory straight from the exe (embedded pack trailer `GDPC`; formats 2-4)
   or from a side `.pck`. Maps `.godot/imported/*` back to their source via the repo's `*.import` files, and
   `.godot/exported/*/export-*-x.scn|res` (text scenes converted to binary) back to `x.tscn|tres` when the name is unique.
3. **Sizes**: exe, pack, engine part (exe - pack), zip, file count, pack by top folder, top 25 files, and the 15 biggest
   per-file changes vs the previous build (from its `pck_files.json`). WARN if the exe grew > 10 %.
4. **Export filter**:
   - `exclude_filter` contains `docs/*`, `tools/*`, `tests/*` (FAIL if not); `include_filter` contains `*.json` (WARN if not).
   - nothing from `docs/ tools/ tests/ build/ .claude/ art/preview/`, no `.md .ps1 .blend .psd` in the pack (FAIL).
   - every non-resource data file (`json txt csv cfg ini`) in the game folders is in the pack (FAIL).
   - every existing `res://` path named by a game `.gd/.tscn/.tres/.gdshader` is in the pack (as itself, `.remap`,
     `.import` or `.gdc`) (FAIL). Game code naming `docs/ tools/ tests/` paths = WARN (art preview scripts = INFO).
   - main scene + autoloads in the pack (FAIL).
   - scripts that list `res://` folders with `DirAccess` without `.remap` handling (WARN: exports list `x.tres.remap`).
5. **Boot (exported)**: `FourWizards.console.exe --headless --fixed-fps 60 --quit-after 600` (the main menu). FAIL on
   non-zero exit, hang, or any `SCRIPT ERROR / Parse Error / Failed to load / ERROR:` line (exit-time leak noise ignored).
6. **Smoke (exported pack)**: `tests/` is not in the build, so the lab copies `tests/smoke_test.gd` next to the build.
   The **release template ignores `-s`** (tested 2026-09-26: it boots the main menu and never runs the script), so
   the smoke runs the exported pack with the Godot console exe, through the gate, from the build folder (no `--path`):
   `Godot_console.exe --headless --main-pack <build>\game\FourWizards.exe -s <build>/smoke/smoke_test.gd --fixed-fps 60 --quit-after 7000`.
   Everything the game loads comes from the exported pack (`.gdc` scripts, converted `.scn`, imported textures, filters);
   only the engine binary differs from the shipped exe, and the boot check (step 5) covers that exe.
   PASS needs `victory=true`; errors with a victory = WARN; no `Navigation baked` / `GAME OVER` line = FAIL.
   The boot run takes a slot of the same `Local\FourWizardsGodotGate` semaphore as `tools/godot_run.ps1`.
   Release exports have no `FourWizards.console.exe` (preset `debug/export_console_wrapper=1` = debug only): INFO;
   the GUI exe's output is captured through the cmd redirection anyway.
7. **Zip**: `<build>\FourWizards-<yyyy-MM-dd>.zip` of the `game\` folder. Then it prints (never runs):
   `Copy-Item -LiteralPath "<zip>" -Destination "$env:USERPROFILE\OneDrive\FourWizards-<date>.zip" -Force`

Score = 100 - 40 per failed export / boot / smoke - 20 per other FAIL - 5 per WARN (0 if the export failed).

## 3. Lead workflow (playtest build)
1. `tools\build_lab\build_lab.ps1` on a green tag (it exports the working folder as it is).
2. Read `docs/build/lab/<run>/scorecard.md`. FAIL -> fix agent (Error Lab brief for errors in `logs/`).
3. **Ask the user** if the zip may replace the OneDrive copy; only then run the printed `Copy-Item` line.

## 4. Status / next steps
**v1 built 2026-09-26 (23:28-00:00).** One export done: build `C:\Users\elzzo\Documents\four-wizards-builds\2026-09-26_2337`
(export 222 s through the gate on a busy PC; exe 138.8 MB = 104.1 MB engine + 34.7 MB pack, 3211 files; zip 55.1 MB).
Runs in `docs/build/lab/`:
- `2026-09-26_2337` (the export run): smoke FAIL = **lab bug**, fixed: the release template ignores `-s` and just boots
  the menu; the smoke now uses `--main-pack`. Export WARN = exit-time `PagedAllocator` noise, now ignored.
- `2026-09-26_2345` (same build re-tested): smoke PASS (`GAME OVER at frame 3720: victory=true`, 104 s), boot PASS;
  one false FAIL (autumn files an art agent added *after* the export), fixed: files newer than the exe are INFO
  ("Repo changed since the build").
- `2026-09-26_2350` (same build, lab fixed) = the clean v1 result: **PASS 100 / 100** - boot PASS (4 s), smoke PASS
  (`GAME OVER at frame 3780: victory=true`, 188 s on the busy PC), every filter check PASS, zip 55.1 MB ready.
First findings: filter is right (no docs / tools / tests in the pack, main scene + autoloads + every referenced file
ship, no game `.json` yet); **306 art preview / render tool files (1.2 MB) ship** (`art/**/tools/*`, `*_preview.*`,
`render_*.gd`) - harmless, an `art/*/tools/*` style exclude would drop them (lead owns `export_presets.cfg`).
Biggest files: `map_cliffs.res` 1.9 MB, `nature_keep.tscn` 1.8 MB, `map_cliffs_closed.res` 1.3 MB; `art/` = 90 % of the pack.

Next steps:
1. `-Tag <name>` to name the build folder after a git tag (the lead passes it; the lab still never runs git).
2. Warn when the working folder has files newer than the last green tag (export = working folder, not the tag).
3. Optional debug export (`-ExportDebug`) + boot on `FourWizards.console.exe` to catch debug-only errors.
4. Per-folder size budget (e.g. pack < 60 MB, zip < 100 MB) as WARN lines once the art pass lands.

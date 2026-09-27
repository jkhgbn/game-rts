# Build Lab scorecard: 2026-09-26_2337

2026-09-26 23:44 - lab v1.0 - preset **Windows Desktop** (release) - build: `C:\Users\elzzo\Documents\four-wizards-builds\2026-09-26_2337`

## Result: **FAIL** - score **45 / 100**

1 FAIL - 3 WARN. Score = 100 - 40 per failed export / boot / smoke - 20 per other FAIL - 5 per WARN (0 if the export failed).

## Improve next
1. **Smoke (exported)** (FAIL): no victory=true (exit 0, 5,7 s): no GAME OVER line -> Compare with the editor smoke test; if that passes, the export is missing something (logs/smoke.log).
2. **Export** (WARN): exported in 221.8 s with 2 unique error lines in the export log, first: ERROR: Pages in use exist at exit in PagedAllocator: N12VariantPools11BucketSmallE -> Fix the resources named in logs/export.log (they may be broken in the build).
3. **Console wrapper** (WARN): FourWizards.console.exe missing: logs come from the GUI exe -> Keep debug/export_console_wrapper=1 in the preset.

## Checks
| Check | Result | Detail |
|---|---|---|
| Export | WARN | exported in 221.8 s with 2 unique error lines in the export log, first: ERROR: Pages in use exist at exit in PagedAllocator: N12VariantPools11BucketSmallE |
| PCK listing | INFO | 3211 files, 34,7 MB (embedded in the exe), pack format 4, Godot 4.7.2 |
| Size vs previous | INFO | exe 138,8 MB, pack 34,7 MB; first build in the history |
| Filter: excludes dev folders | PASS | exclude_filter = tests/*, docs/*, tools/*, art/preview/* |
| Filter: includes *.json | PASS | include_filter = *.json |
| Filter: no dev files in pack | PASS | no docs/ tools/ tests/ art/preview/ .md .ps1 source-art files in the pack |
| Filter: data files ship | PASS | 0 non-resource data files (json/txt/csv/cfg) in game folders, all in the pack |
| Filter: referenced files ship | PASS | every existing res:// path named in 1341 game .gd/.tscn/.tres/.gdshader files is in the pack |
| Filter: game code uses dev folders | WARN | 5 references from game code into docs/ tools/ tests/ (excluded from the build), e.g. docs/art/screens/icons_sheet_wip.png <- art/icons/render_icons.gd; docs/art/screens/champion_class_icons.png <- art/icons/render_champion_icons.gd; docs/art/screens/icons_sheet.png <- art/icons/render_icons.gd |
| Preview scripts in the build | INFO | 28 docs/ paths named by art preview / lab scripts (screenshot outputs; they ship but never run in the game) |
| Main scene + autoloads | PASS | in the pack: scenes/ui/main_menu.tscn, scripts/core/events.gd |
| Runtime folder listing | PASS | no res:// DirAccess listing without .remap handling |
| Console wrapper | WARN | FourWizards.console.exe missing: logs come from the GUI exe |
| Boot (exported) | PASS | main menu ran 600 frames headless, exit 0, no errors (5.2 s) |
| Smoke (exported) | **FAIL** | no victory=true (exit 0, 5,7 s): no GAME OVER line |
| Zip | PASS | C:\Users\elzzo\Documents\four-wizards-builds\2026-09-26_2337\FourWizards-2026-09-26.zip (55,1 MB, 9 s) |

## Sizes
| Item | Size | Previous (none) | Delta |
|---|---|---|---|
| FourWizards.exe (with embedded pack) | 138,8 MB | - | - |
| pack | 34,7 MB | - | - |
| engine part (exe - pack) | 104,1 MB | - | - |
| zip | 55,1 MB | - | - |
| files in pack | 3211 | - | - |

## Pack by folder
| Folder | Size | Files | Share |
|---|---|---|---|
| art/ | 31,3 MB | 2556 | 90,2% |
| scripts/ | 1,7 MB | 272 | 5,0% |
| assets/ | 1,1 MB | 112 | 3,1% |
| data/ | 0,2 MB | 258 | 0,5% |
| .godot (engine) | 0,1 MB | 2 | 0,3% |
| scenes/ | 0,0 MB | 8 | 0,0% |
| missions/ | 0,0 MB | 2 | 0,0% |
| root files | 0,0 MB | 1 | 0,0% |

## Biggest files (top 25)
| # | Source | Packed as | Size |
|---|---|---|---|
| 1 | art/environment/meshes/map_cliffs.res | art/environment/meshes/map_cliffs.res | 1,9 MB |
| 2 | art/buildings/nature_keep.tscn | .godot/exported/133200997/export-856d4fd4d47171f1bae2b1eb647fda54-nature_keep.scn | 1,8 MB |
| 3 | art/environment/river_mouths/map_cliffs_closed.res | art/environment/river_mouths/map_cliffs_closed.res | 1,3 MB |
| 4 | art/environment/bridges/lane_bridge.res | art/environment/bridges/lane_bridge.res | 0,6 MB |
| 5 | art/environment/landmarks/meshes/standing_stones.res | art/environment/landmarks/meshes/standing_stones.res | 0,5 MB |
| 6 | art/environment/landmarks/meshes/colossus.res | art/environment/landmarks/meshes/colossus.res | 0,5 MB |
| 7 | art/environment/camps/meshes/gloomcap_base.res | art/environment/camps/meshes/gloomcap_base.res | 0,5 MB |
| 8 | art/environment/horizon/meshes/horizon_south_east.res | art/environment/horizon/meshes/horizon_south_east.res | 0,4 MB |
| 9 | art/environment/horizon/meshes/horizon_north_west.res | art/environment/horizon/meshes/horizon_north_west.res | 0,4 MB |
| 10 | art/environment/lairs/meshes/heath_wallow.res | art/environment/lairs/meshes/heath_wallow.res | 0,4 MB |
| 11 | art/environment/camps/meshes/bristleback_base.res | art/environment/camps/meshes/bristleback_base.res | 0,4 MB |
| 12 | art/environment/ruin_peddler.tscn | .godot/exported/133200997/export-e98069621094f323bf7d974ce41a71a8-ruin_peddler.scn | 0,4 MB |
| 13 | art/environment/horizon/meshes/horizon_north_east.res | art/environment/horizon/meshes/horizon_north_east.res | 0,4 MB |
| 14 | art/environment/horizon/meshes/horizon_south_west.res | art/environment/horizon/meshes/horizon_south_west.res | 0,4 MB |
| 15 | assets/audio/music/music_match.wav | .godot/imported/music_match.wav-04196686a520c79afeccbaa387747266.sample | 0,4 MB |
| 16 | art/buildings/fire_keep.tscn | .godot/exported/133200997/export-3b24666c1c4699e29455061b2b09fc15-fire_keep.scn | 0,4 MB |
| 17 | art/environment/horizon/meshes/horizon_north.res | art/environment/horizon/meshes/horizon_north.res | 0,4 MB |
| 18 | art/environment/camps/meshes/hollow_stag_base.res | art/environment/camps/meshes/hollow_stag_base.res | 0,4 MB |
| 19 | art/environment/horizon/meshes/horizon_west.res | art/environment/horizon/meshes/horizon_west.res | 0,4 MB |
| 20 | art/environment/lairs/meshes/crag_nest.res | art/environment/lairs/meshes/crag_nest.res | 0,4 MB |
| 21 | art/environment/horizon/meshes/horizon_south.res | art/environment/horizon/meshes/horizon_south.res | 0,4 MB |
| 22 | art/environment/horizon/meshes/horizon_east.res | art/environment/horizon/meshes/horizon_east.res | 0,3 MB |
| 23 | assets/audio/music/music_menu.wav | .godot/imported/music_menu.wav-7d19ae11fbd516a17b9dc9bf9019f3d0.sample | 0,3 MB |
| 24 | art/environment/landmarks/meshes/giant_stump.res | art/environment/landmarks/meshes/giant_stump.res | 0,3 MB |
| 25 | art/environment/landmarks/meshes/aqueduct.res | art/environment/landmarks/meshes/aqueduct.res | 0,3 MB |

## Playtest copy (the lab never copies to OneDrive)
Zip ready: `C:\Users\elzzo\Documents\four-wizards-builds\2026-09-26_2337\FourWizards-2026-09-26.zip`. **Ask the user first**, then the lead runs:
```powershell
Copy-Item -LiteralPath "C:\Users\elzzo\Documents\four-wizards-builds\2026-09-26_2337\FourWizards-2026-09-26.zip" -Destination "$env:USERPROFILE\OneDrive\FourWizards-2026-09-26.zip" -Force
```

Logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\build\lab\2026-09-26_2337\logs`. Re-run: `tools\build_lab\build_lab.ps1` (see docs/plan/build-lab.md).

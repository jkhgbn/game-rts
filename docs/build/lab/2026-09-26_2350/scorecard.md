# Build Lab scorecard: 2026-09-26_2350

2026-09-26 23:55 - lab v1.0 - preset **Windows Desktop** (release) - build: `C:\Users\elzzo\Documents\four-wizards-builds\2026-09-26_2337`

## Result: **PASS** - score **100 / 100**

0 FAIL - 0 WARN. Score = 100 - 40 per failed export / boot / smoke - 20 per other FAIL - 5 per WARN (0 if the export failed).

## Improve next
1. Biggest file: `art/environment/meshes/map_cliffs.res` 1,9 MB - check its import settings (size / compression) if the build must shrink.
2. Biggest file: `art/buildings/nature_keep.tscn` 1,8 MB - check its import settings (size / compression) if the build must shrink.

## Checks
| Check | Result | Detail |
|---|---|---|
| Export | INFO | skipped (re-using C:\Users\elzzo\Documents\four-wizards-builds\2026-09-26_2337\game\FourWizards.exe) |
| PCK listing | INFO | 3211 files, 34,7 MB (embedded in the exe), pack format 4, Godot 4.7.2 |
| Size vs previous | PASS | exe 138,8 MB (+0 KB, +0,0%) vs 2026-09-26_2345 (138,8 MB) |
| Filter: excludes dev folders | PASS | exclude_filter = tests/*, docs/*, tools/*, art/preview/* |
| Filter: includes *.json | PASS | include_filter = *.json |
| Filter: no dev files in pack | PASS | no docs/ tools/ tests/ art/preview/ .md .ps1 source-art files in the pack |
| Art tool scripts in the pack | INFO | 306 files (1,2 MB) from art preview / render tools ship (e.g. art/units/kit/tools/kitfix_glow_check.tscn, art/units/fire/blaze_rider/tools/blaze_rider_preview.tscn); an exclude like `art/*/tools/*` would drop them |
| Filter: data files ship | PASS | 0 non-resource data files (json/txt/csv/cfg) in game folders, all in the pack |
| Filter: referenced files ship | PASS | every existing res:// path named in 1351 game .gd/.tscn/.tres/.gdshader files is in the pack |
| Repo changed since the build | INFO | 5 referenced files are not in the pack but were added / changed after the exe (23:40), e.g. art/environment/autumn/nature_autumn.gdshader, art/environment/autumn/horizon_autumn.gdshader, art/environment/autumn/autumn_ground_params.gd |
| Preview scripts in the build | INFO | 33 docs/ paths named by art preview / lab scripts (screenshot outputs; they ship but never run in the game) |
| Main scene + autoloads | PASS | in the pack: scenes/ui/main_menu.tscn, scripts/core/events.gd |
| Runtime folder listing | PASS | no res:// DirAccess listing without .remap handling |
| Console wrapper | INFO | none for release exports (preset debug/export_console_wrapper=1); the lab reads the GUI exe's redirected output |
| Boot (exported) | PASS | main menu ran 600 frames headless, exit 0, no errors (4.3 s) |
| Smoke (exported) | PASS | GAME OVER at frame 3780: victory=true player=4 enemy=3 (188 s, exit 0) |
| Zip | PASS | C:\Users\elzzo\Documents\four-wizards-builds\2026-09-26_2337\FourWizards-2026-09-26.zip (55,1 MB, 8 s) |

## Sizes
| Item | Size | Previous (2026-09-26_2345) | Delta |
|---|---|---|---|
| FourWizards.exe (with embedded pack) | 138,8 MB | 138,8 MB | +0 KB |
| pack | 34,7 MB | 34,7 MB | +0 KB |
| engine part (exe - pack) | 104,1 MB | 104,1 MB | +0 KB |
| zip | 55,1 MB | 55,1 MB | +0 KB |
| files in pack | 3211 | 3211 | 0 |

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

Logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\build\lab\2026-09-26_2350\logs`. Re-run: `tools\build_lab\build_lab.ps1` (see docs/plan/build-lab.md).

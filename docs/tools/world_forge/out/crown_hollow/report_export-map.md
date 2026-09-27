# world_forge export-map: crown_hollow

2026-09-27 08:06:42 - `tools/world_forge/run_world_forge.ps1 export-map crown_hollow` - hash `ddbe2dda6264`

## Result: **PASS** - quality **100 / 100**

0 FAIL, 0 WARN, 2 PASS, 0 info, 0 skipped, 19 s

## Improve next

## Export
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| E3 | Live path table | PASS 100 | 1275 spot pairs, 1 navmesh region(s) saved | NavigationServer3D.map_get_path (optimized, the Map Lab's call) between every pair of live spots |  |
| E1 | Live spots exported | PASS 100 | 51 spots: 25 twin pairs, 1 on the centre, 0 solo; 8 crossings, 3 river arms | every Map Lab spot kind of the live scene is in the .map |  |

## Notes
- Files: `data/maps/crown_hollow_navmesh.res`, `data/maps/crown_hollow.map`, `docs/tools/world_forge/out/crown_hollow/export_spots.json`, `docs/tools/world_forge/out/crown_hollow/export_paths.json`

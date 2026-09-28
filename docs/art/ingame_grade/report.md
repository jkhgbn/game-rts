# In-game art grade (2026-09-28)

Method: `ingame_capture.gd` (this folder) runs a real skirmish at 1600x900, real RTS camera, both keeps at tier 3, every building and non-worker unit spawned, hero fight with level 8 wizards and 2 champions per side. Two runs: Fire vs Shadow, Ice vs Nature. 30 screenshots in `shots/`. Grade = 0.4 x Art Lab + 0.6 x in-game look (in-game only where there is no lab score). Art Lab data is from the 2026-09-26/27 sweep, not re-run.

| Category | Lab | In-game | Grade |
|---|---|---|---|
| Fire units T1-T3 | 92.6 | 76 | 83 |
| Shadow units | 93.2 | 78 | 84 |
| Ice units | 93.6 | 60 | 73 |
| Nature units | 91.7 | 56 | 70 |
| 12 placeholder T3 / extra units | - | 15 | 15 |
| Wizards | 90.5 | 74 | 81 |
| Champions | 88 | 55 | 68 |
| Titans (still props) | 91.8 | 82 | 86 |
| Keeps T3 | 88.6 | 78 | 82 |
| Other kingdom buildings | 86.5 | 74 | 79 |
| Stables x4 | - | 5 | 5 |
| Neutral buildings | 84.1 | 80 | 82 |
| Spell VFX | - | 65 | 65 |
| Combat / hit VFX | 100 (1 asset) | 62 | 62 |
| Terrain / river / biomes | 89.3 | 84 | 86 |
| Landmarks and props | 92.6 | 90 | 91 |
| Neutral creatures | 92 | not seen | 92 (lab only) |

Cross-cutting: faction colour clarity Fire vs Shadow 86, Ice vs Nature 50; scale consistency 72; clutter 65; animation about 75 (stills only); consistency between factions 70.

## Worst 5 and the fix
1. Stables x4 (5): model files `art/buildings/stables/<k>/<k>_stables.tscn` do not exist, flat boxes show. Build the 4 models (stopgap: point `model_path` at the lair model).
2. 12 placeholder T3 units (15): emberdart_harrier, pyrehoof_lancer, sunforge_cataphract, barrow_knight, duskbolt_harrier, veilborn_dreadrider, frostcrown_juggernaut, rime_harrier, snowdrift_rider, bramble_harrier, spirit_wolf, thornback_charger. One art agent per unit, then an Art Lab run.
3. Ice turns white (army 60, spell VFX 52, hit VFX 60, keep 68): tint ice VFX cyan/steel, alpha blend instead of additive, emission <= 1.5, halve hit puffs, steel-blue armour mid-tones with white only on crests, hard-edged 1 m snow rim.
4. Nature on meadow (56): bark / straw / pale moss main masses, team colour on top-facing cloth (>= 15 % of visible body), pale sage canopy.
5. Champions (55): scale 1.15x, one bright class colour, distinct weapon silhouette per class, B8 material merge.

## Best 5
Crown Isle centre, Fire Keep T3 (lab 94.6), Shadow army and cavalry, crystal nodes, river with waterfalls and bridges.

Full per-asset list of everything under 90: `under_90.md`.

Limits: titans cannot be trained yet (placed as props); neutral creatures barely on screen; the right help panel and objective text hide about 25 % of the 3D view (UI, not graded).

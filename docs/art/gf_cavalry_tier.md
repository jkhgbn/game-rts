# G-F: Art Lab cavalry tier (2026-10-15)

## Problem
`ArtLabBudgets.guess_tier` gave every `*_rider.tscn` the `unit/cavalry` tier, which is the RIDER ALONE
(cavalry-mounts.md 10: <= 20 meshes / <= 12 draws, mount separate: <= 12 meshes / <= 8 draws). The cavalry unit scenes
(`blaze_rider.tscn` = Boar + Rider, `gloam_rider.tscn`, `rimehorn_rider.tscn`...) hold both, so they FAILed B2 on a tier
error. Cavalry scenes not named `*_rider.tscn` (Stagrunner, Glade Outrider, Barrow Knight) fell to `heavy` (16 draws) and
FAILed too.

## Fix (`tools/art_lab/lab_budgets.gd`)
- New row `unit/cavalry_mounted` = cavalry + mount: meshes 32, draws 20, frame 0.01 ms; soft verts 8500, casters 6,
  separate 12. Particle systems stay 1 (the spec gives mounts none), face allowance 1200 (already rider + mount faces).
- `is_mounted_scene(path)`: the saved scene's root has an instanced child named `Rider` plus another instanced child
  (the mount). A .tscn is read as text (no script compiled). `guess_tier` checks it (or a `mounted` hint) after
  wizard / champion / neutral / worker, before the `_rider.tscn` rule. Exactly 16 of the 652 scenes under `art/` match:
  every other scene keeps its old tier (rider-only `*_rider.tscn` parts stay `cavalry`).
- Test: `tests/test_gf_cavalry_tier.gd` (16 mounted scenes -> `cavalry_mounted`; rider part, Shade, Shadow Knight,
  Dusk Steed, Vessa, Mirefang keep cavalry / soldier / heavy / mount / wizard / creature). `test_art_lab` still PASS.

## Re-run (windowed batch, `docs/art/lab/<id>/`)
| Scene | Before (tier, verdict, B2) | After (cavalry_mounted) |
|---|---|---|
| blaze_rider | cavalry, FAIL, B2 18 FAIL | WARN 93, B2 18 PASS |
| emberdart_harrier | rider, WARN, 15 | WARN 94, 15 |
| pyrehoof_lancer | rider, WARN, 15 | WARN 93, 15 |
| sunforge_cataphract | rider, WARN, 14 | WARN 94, 14 |
| frostcrown_juggernaut | cavalry, PASS, 12 | PASS 98, 12 |
| rimehorn_rider | cavalry, FAIL, B2 17 FAIL (B6 2 FAIL in gc_leftovers) | WARN 92, 17, B6 1 |
| rime_harrier | cavalry, PASS, 12 | PASS 96, 12 |
| snowdrift_rider | cavalry, PASS (B6 2 FAIL in gc_leftovers) | PASS 94, 12, B6 1 |
| bramble_harrier | cavalry, PASS, 12 | WARN 93, 12 |
| glade_outrider | heavy, FAIL, B2 20 FAIL | WARN 90, 20 |
| stagrunner | heavy, FAIL, B2 20 FAIL | WARN 90, 20 |
| thornback_charger | cavalry, PASS, 12 | WARN 94, 12 |
| barrow_knight | heavy, WARN, 15 | WARN 93, 15 |
| duskbolt_harrier | rider (gc_leftovers: soldier, FAIL B2 15 / B4) | WARN 93, 15 |
| gloam_rider | cavalry, FAIL, B2 20 FAIL | WARN 92, 20 |
| veilborn_dreadrider | rider, WARN, 14 | WARN 92, 14 |

"Before" = the folder's previous scorecard (blaze_rider: `gc_leftovers/after/`). Remaining WARNs are B4 soft verts,
R8w lances / antlers above the head line, R10 footprint vs selection radius: not tier issues.

## The gc_leftovers B2 / B6 FAILs
- B2 (blaze 18, gloam 20, rimehorn 17, duskbolt 15, stagrunner / glade 20): all **tier errors**. Each is within
  cavalry + mount (20); none needs merged rider pivots.
- duskbolt B4 FAIL: tier error too (it was read as a soldier, 2500 verts).
- B6 (rimehorn, snowdrift, 2 systems): **not a tier error** (the limit stays 1), but it does not reproduce today: both
  scenes count 1 system and one node fewer (43 -> 42, 37 -> 36) than in the G-C run, so a later change removed an
  emitter. If it comes back, it is real: one shared emitter (emission points) instead of two.
- Note for the lead: `docs/plan/art-lab.md` (tier table and the `tier=` default list) does not list
  `unit/cavalry_mounted` yet (`art_lab.gd -- table` prints the new table).

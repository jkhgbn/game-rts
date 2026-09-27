# New unit: Frostbow (Ice T2 marksman), Art Lab v3 phase 4.2, medium effort

- Start 2026-09-27 11:29 (laptop time), end 11:48: **about 19 minutes** (the stop was 75 min / 17:15).
- Scene: `art/units/ice/frostbow/frostbow.tscn` + `frostbow.gd` (extends `IceModel`, no `class_name`).
- Art Lab output: `docs/art/lab/new-units/frostbow/` (scorecard.md / .json, fixes.json, contact_sheet.png, strike_side.jpg, diff_sheet.png).
- Stopped because there were no FAIL and no WARN, and quality had stopped rising (96 in runs 6, 8 and 10).
- Note: `docs/handoff/for-game-designer.md` (13b.D1) says the gameplay Frostbow was dropped (the Rifleman took its role). This brief
  (phase 4.2) still asks for the art, so I built it. The lead should decide whether it ships.

## Art Lab runs
Base command: `.\tools\art_lab\run_art_lab.ps1 art/units/ice/frostbow/frostbow.tscn unit ice -Extra 'out=docs/art/lab/new-units/frostbow','ref=frostrune_rifleman,rimeshield,shardcaster'` (runs 3-10 add `'compare=prev'`). Wall = the whole PowerShell call.

| # | Change before the run | Wall s | Quality | FAIL | WARN |
|---|---|---|---|---|---|
| 1 | first build | 15 | 61 | 2 (R1, R3: script parse error, `_glow_written` already in the kit) | 1 (A1) |
| 2 | variable renamed | 39 | 94 | 0 | 0 |
| 3 | lathe torso, tapered legs + boots, rounded cape, two eyes instead of a band, attack stance | 8 | 92 (not valid) | 1 (B4 2719 verts) | 0 |
| 4 | same + fewer sides (the lab was mid-edit in run 3; waited 45 s) | 42 | 95 | 0 | 0 |
| 5 | bent tapered arms (shoulder / elbow / wrist), dark scarf over the lower face | 38 | 95 | 0 | 0 |
| 6 | top "Improve next" (C1 shape richness): big masses to 11-12 sides | 40 | 96 | 0 | 0 |
| 7 | face deeper in the hood, dark fur face ring, skirt / capelet tilted | 40 | 95 | 0 | 0 |
| 8 | face ring back to pale fur (P4 busy) | 43 | 96 | 0 | 0 |
| 9 | string glow written less often (B13 frame cost) | 41 | 94 | 0 | 0 |
| 10 | string pulse only goes UP from the ready level (P5 had lost the glow in run 9) | 41 | 96 | 0 | 0 |

## Final
- **Quality 96** (runs 6, 8, 10). Before / after: 94 -> 96 (first valid run).
- **FAIL: none. WARN: none.** 32 PASS, 17 INFO.
- **9 meshes / 9 draw instances** at rest (6 merged pivots, BowBody, String, blob; StringDrawn / Arrow / VetTrim hidden), **2483 vertices** (budget 2500),
  **1 glow point** (the bow string), 0 lights, 4 shadow casters.
- Key reads: R3 meadow dE 57; R4k snow dE 26 (worst ground); R6 team colour 61 %; R2 max IoU 0.62 vs the Shardcaster (0.61 Rifleman);
  A3 strike changes 39 % of the silhouette; P1 outline 2.46; P5 glow in the upper half; B13 0.0036 ms per instance.

## What I built
1. A tall slim 1.7 m hooded archer: dark fur legs in tall boots with pale fur cuffs, a lathe leather jerkin, team tabard strip, silver belt.
2. A deep ROUNDED team hood with a pale fur face ring and a dark scarf (the Shardcaster's hood is pointed, the Rifleman wears a pale mantle).
3. The hook: a 1.95 m faceted ice longbow held upright in the left hand (taller than the body), recurve tips with ice shards, leather grip.
4. The only glow: the bow string, bright and pulsing while Hamstring Shot is ready (`set_hamstring_ready` / `set_status(&"hamstring_ready")`), dim while it cools down.
5. `bow_draw` (0.6 s, release 0.15): the bow arm comes up level with the bow kept upright, side-on stance, V string + crystal arrow, loose with motes; `play_cast` = slow Hamstring draw that looses at 0.65. Walk, fidget, shatter death.

## Next steps
1. Snow (dE 26, 41 % melt): a darker value on the hood top or the capelet on snow maps, checked with `focus=R3,R4,R4k`.
2. Bow at 437 verts: fewer limb segments would free budget for a real forearm bend on the draw hand.
3. Gameplay hook-up (step 16 code): call `set_hamstring_ready(false)` on the Hamstring cooldown; `get_bow_tip_position()` for the arrow origin.

## Art Lab notes
- Run 3 hit a half-edited lab (`declared_reach()` / `check_hooks` parse errors from another session's fix round) yet still wrote a scorecard (quality 92, 2 s). It would help if a lab that fails to compile its own checks said so in the result line instead of scoring.
- P5 (glow placement) flips 0 <-> 100 on a glow that pulses: in run 9 the pulse dipped below the rest level at the capture and the lab picked no glow. Worth sampling the glow at 2-3 times.
- The new `strike_side.jpg` strip was very useful for a bow: it shows the upright bow and the draw clearly, where the 3/4 front strike frame foreshortens it.
- B1 lists "Bow 2" (bow body + string) but the bow body has 2 surfaces (ice + leather); only B11 shows that surfaces cost draw calls too.

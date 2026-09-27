# New unit: Pyre Adept (Fire T2 caster), Art Lab v3 phase 4.2

- Start 2026-09-27 11:29:39, end 11:46, **about 17 minutes** (well inside the 75-minute / 17:15 stop).
- Effort: Opus 5.5 medium. Brief: `docs/plan/new-units-brief.md`; `rush-balance.md` 5.1 / 5.4 (robed pyromancer, brazier-headed staff held high, vertical read, flames flare on Flame Burst, glow "bowl", hook `play_cast()`).
- Scene: `art/units/fire/pyre_adept/pyre_adept.tscn` + `pyre_adept.gd` (extends `FireModel`, `fire_kind = &"adept"`; no `class_name`, so no import needed). Parts built in code (`_build_parts`, the Vinelasher kit pattern), palette materials only, 0 lights.
- Art Lab output: `docs/art/lab/new-units/pyre_adept/` (scorecard.md / .json, fixes.json, contact_sheet.png, diff_sheet.png).
- Stopped because there was no FAIL and no WARN, and quality sat at 97 (97.2 / 97.4 / 97.4) for the last 3 runs.

## Art Lab runs
Base command: `.\tools\art_lab\run_art_lab.ps1 art/units/fire/pyre_adept/pyre_adept.tscn unit fire -Extra 'out=docs/art/lab/new-units/pyre_adept','ref=ember_archer,flame_guard,vessa'` (runs 2-9 add `'compare=prev'`). Wall = the whole PowerShell call; the lab's own time was 30-33 s.

| # | Change before the run | Wall s | Quality | FAIL | WARN |
|---|---|---|---|---|---|
| 1 | first build | 36 | 93 (92.6) | 0 | 3 (R8w brazier 0.47 m wide; R3t nature team dE 14.4; R6cb protan fire/nature 12.2, deutan vs ground 8.5) |
| 2 | ash robe, narrower bowl, boxes -> cylinders (parse error: duplicate var name) | 17 | 61 | 2 (R1, R3: script failed to load) | 1 |
| 3 | same, name clash fixed | 38 | 96 | 0 | 1 (R6cb deutan body vs ground 8.9) |
| 4 | robe in dark soot leather (tops light, bottoms dark), more secondary shapes (clasps, tassels, pouch, token, nose, hood drapes, cuff) | 37 | 97 | 0 | 0 |
| 5 | vertex trim (2475 -> 2402), varied flame tongues, left hand forward | 45 | 97 (96.6) | 0 | 0 |
| 6 | bell robe (hem r 0.43, R2 vs Ember Archer 0.63 -> 0.59), fewer staff / rim segments | 38 | 97 (96.8) | 0 | 0 |
| 7 | vertex trim (-> 2250), bowl fire idle glow x1.3 (R5c) | 47 | 97 (97.2) | 0 | 0 |
| 8 | tilted belt / mantle / torso / sleeve bell (C1 normal variety 0.85 -> 0.87) | 40 | 97 (97.4) | 0 | 0 |
| 9 | same (repeat for stability) | 41 | 97 (97.4) | 0 | 0 |

## Final
- **Quality 97 (97.4)**. Before / after: 92.6 -> 97.4.
- **FAIL: none. WARN: none.** 32 PASS.
- 9 meshes drawn / **10 draw instances** at rest, **2250 vertices** (ArmR merged 616, Hips 375, Chest 356, Head 348), **1 glow point** (BowlFire, upper half), 0 lights, 3 shadow casters, 5 particle systems (1 looping: BowlEmbers, 5 motes).
- Key reads: R3 meadow PASS, R3t worst team colour (nature) PASS 100, R4 worst ground heath dE ~39, R4k ash dE ~50, R6cb PASS (deutan vs ground dE 15.2), R2 max IoU 0.59 (Ember Archer; Vessa 0.45), R8w PASS (bowl 0.33 m wide), A3 strike changes 42 % of the silhouette.

## What I built
1. A 1.7 m hooded pyromancer: deep crimson team hood with a gold face rim (face in shadow), team torso and bell sleeves, crimson mantle with bronze clasps, a gold stole with tassels down the front.
2. A dark soot bell cassock with a bronze hem and a team-dark front panel: tops light, bottoms dark; the bell shape and the hood keep it apart from Vessa (tall hat, cape, caged sun) and the narrow Ember Archer.
3. The hook: a 2.2 m staff held high in the right hand, crowned by an open bronze brazier on three prongs with a fire of 5 tongues (the one glow point, ~2.5-2.9 m up), idle flicker + a few rising embers.
4. `caster_fire` attack (0.6 s, release 0.15 s): the staff tips the brazier at the target, flame flare + spark spit, left palm pushes. `play_cast(&"flame_burst")` (0.9 s, release 0.4 s): hoist the staff, flame x1.9 / glow x3, drive it down with a big spark burst.
5. FireModel coal-burn death with its own ember / ash emitters; the bowl fire gutters out; revive restores everything. No allocation after `_ready` (pre-built emitters, instance uniforms).

## Next steps
1. A side-view check of the Flame Burst cast (the lab strip only shows the attack): confirm the hoist / slam reads at 40 m and the flare is not clipped by the HP bar.
2. Unit icon (`art/icons/units/pyre_adept.png`) and the step-16 code task: UnitType `model_scene`, call `play_cast(&"flame_burst")` at the 0.4 s cast.
3. Optional: a scorch-ring one-shot at the burst point is gameplay VFX (terrain `add_scorch` already covers the ground mark).

## Art Lab notes
- R8w's hint ("narrow the staff head") was exact and enough: bowl radius 0.21 -> 0.15 cleared it in one run.
- R6cb had two parts to its rule (pair dE >= 6 and body vs ground >= 10 under deutan); the WARN in run 3 came only from the second part while the headline number shown first was the pair dE 6.6, which read like a pass. Putting the failing part first in the message would help.
- A darker lower body (soot robe) fixed R3t and R6cb together: team colour off the biggest mass, as the R3t hint said.
- C1 counts 10-segment cylinders as "prisms" (<= 10 face directions); raising segments to lower that fights B4. Tilting parts moved normal variety a little (0.85 -> 0.87) at no vertex cost.
- A script parse error gives a scorecard with quality 61 and "0 px" FAILs rather than a clear "script failed to load" line at the top (the error is printed above it by the wrapper); `compare=prev` then compares against that broken run.

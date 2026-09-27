# Effort trial: Vinelasher, level xhigh (Opus 5.5)

Brief: `docs/plan/effort-trial-brief.md`. Model: `art/units/_effort_trial/xhigh/vinelasher.tscn` + `vinelasher.gd`
(extends `NatureWarModel`). Art Lab output: `docs/art/lab/effort-trial/xhigh/` (last scorecard, contact sheet, diff sheet).
Extra tool (my folder only): `art/units/_effort_trial/xhigh/tools/preview_lash.gd`, a windowed preview grid of the lash
and snare frames (side + top camera), because the lab shoots only one attack moment and no cast for a soldier.

## Time
- Start **10:49** (brief read), end **11:21** (report written): **32 minutes** of the 75.
- Stopped because quality stopped rising: 95.8 / 95.8 / 96.1 / 96.1 / 96.0 / 96.1 over runs 3-8, 0 FAIL / 0 WARN.
- Build: 10:49-11:01 (reading 5 min, design + code 7 min); lab loop 11:01-11:19; report 11:19-11:21.

## Art Lab runs
Command for every run (PowerShell, in the project folder); runs 2-8 add `'compare=prev'`:
`.\tools\art_lab\run_art_lab.ps1 art/units/_effort_trial/xhigh/vinelasher.tscn unit nature -Extra 'out=docs/art/lab/effort-trial/xhigh','ref=thornling,bramblehorn,burr_slinger'`

| Run | Time | Wall s (lab s) | Quality | Result | FAIL | WARN | Change before the run |
|---|---|---|---|---|---|---|---|
| 1 | 11:01 | 43 (29) | 96 | PASS | 0 | 0 | first build |
| 2 | 11:06 | 40 (30) | 93 | WARN | 0 | 2 (R4k Old Wood dE 19.8, R4 heath dE 9.6) | pauldron + ribbons team-dark, pale crest, fewer whip thorns: meadow up, dark grounds down |
| 3 | 11:08 | 37 (29) | 95.8 | PASS | 0 | 0 | pale bark-tan pauldron plate + team leaves, pale right shoulder, bigger chest plate |
| 4 | 11:11 | 46 (29) | 95.8 | PASS | 0 | 0 | red-bark (russet) torso for the heath / autumn floors (heath 10.2 -> 11.3) |
| 5 | 11:13 | 51 (36) | 96.1 | PASS | 0 | 0 | thicker vine (radius 0.056-0.03 -> 0.07-0.036 m), coil radius 0.16 -> 0.17: the ring reads at 40 m |
| 6 | 11:15 | 38 (29) | 96.1 | PASS | 0 | 0 | polish: brow + slanted eye slits, sturdier legs, bark greaves |
| 7 | 11:17 | 50 (29) | 96.0 | PASS | 0 | 0 | coil helix 24 -> 20 samples (B4) |
| 8 | 11:18 | 45 (28) | 96.1 | PASS | 0 | 0 | none (repeat for the median) |

Run 1 and 2 qualities are the rounded console / log values; runs 3-8 are `scorecard.json` (95.80, 95.83, 96.08, 96.06,
95.99, 96.05). Wall = wrapper incl. Godot start and gate; lab s = the lab's own "in N s".

## Final
- **Quality 96.0** (median of runs 7 and 8: 95.99, 96.05). **PASS, 0 FAIL, 0 WARN** (32 PASS, 12 INFO).
- Lowest scored checks (all PASS / INFO): R4 other grounds 77 (heath dE 11.8), R6cb colour-blind fire / nature 79,
  R12 night light 83 (dE 16.9), R3 meadow 91 (dE 30.6), B4 93, S1 autumn style bible INFO 11 (dE 12.1).
- Final scorecard: **9 meshes drawn** after the merge (budget 26), **9 draw instances** (14), **2 083 vertices** (2 500;
  whip 506), **1 glow point** (the whip tip; 1-3), 0 lights, 1 keep_separate part, 3 shadow casters, 0 allocations
  after `_ready`, frame cost 0.0024 ms per unit, silhouette 457 px at 40 m, attack changes 66 % of the silhouette,
  R2 max IoU 0.47 (Thornling).

## What I built
1. A lean 1.8 m bark warrior: red-bark torso, pale bark-tan chest plate, face, crest and left pauldron plate (tops light),
   dark bark legs with bark greaves (bottoms dark), team sash, loincloth, ribbons, bracer and shoulder leaves.
2. The hook: a russet thorn vine coiled twice around the right forearm in horizontal loops (a ring from pitch 55), its
   tail rising over the right shoulder like a poised snake, the glowing bud tip hooked forward (the only glow, upper half).
3. `vine_lash` attack (0.7 s): arm overhead with the vine trailing, snap at 0.14 (release), the vine cracks out 3 m to the
   front, a pink blossom opens on the handle's pommel, drops, is dragged back and coils again.
4. `play_cast` Snare Lash (0.9 s): low sidearm sweep, the vine's end winds into a snare ring 2.5 m ahead, a yank back.
5. The whip is ONE keep_separate node swapping 12 cached meshes (coil + 11 lash shapes: vine, thorns, glow tip as 3
   surfaces), counter-rotated by the arm's pitch so the shapes are authored in the chest frame: 0 nodes / materials per action.

## With more time
1. Heath / autumn floors (khaki / ochre, mid L*): a stronger non-yellow value accent; the palette has no blue / violet,
   so a pale-plus-dark top pattern tested on all 4 grounds at once.
2. Smoother lash: 2x the frames (or a skinned vine on a small Skeleton3D) and a crack burst of thorn petals at the tip.
3. A hollow coil ring at 40 m (the forearm fills the hole today) and a walk-cycle sway of the vine tail.

## Art Lab notes
- **The attack strip shoots a fixed 0.1 s for melee units** (`attack_windup` 0): with an own timeline that is the
  mid-throw frame, not the crack at 0.14. A3 samples 4 moments; the strip could show A3's best moment (or 3 moments).
- **`play_cast` is never shot or checked for a soldier** (no cast frame in the strip, no A-check). The Snare Lash was only
  verified with my own preview grid. A cast frame at ~40 % of the cast would help units with a cast hook.
- **No reach check**: nothing tells whether a 3 m whip actually reaches 3 m at the strike. A "reach at strike" value
  (max horizontal distance of the silhouette from the origin during A3) would catch it.
- **R5 names the glow part "Merged"**, but the glow is the tip of the keep_separate node `Whip` (ArmR). The part label seems
  to come from another node; misleading when choosing what to dim or boost.
- **R10 uses the default radius 0.45** when there is no UnitType, although rush-balance.md 5.1 gives the Vinelasher 0.5.
  INFO only, but the value reads as "too wide" (x 0.69 vs 0.63).
- **Contrast checks pull in opposite directions** (not a bug, but costly to discover): darkening the top for the meadow
  (run 2: R3 +4) turned R4k Old Wood and R4 heath into WARNs. A one-line "all grounds at once" summary per run (meadow / heath /
  Old Wood / autumn dE side by side) at the top of the scorecard would save a run.
- **S1 (autumn style bible) is INFO but seems to weigh in the quality** (INFO 34 -> 16 was listed as "worse" and moved the
  score). If it is not a rule yet, it should not move the quality.
- `compare=prev` and the diff list were very useful; `fixes.json` is empty when nothing FAILs / WARNs (fine, but the
  "Improve next" items could go there too).
- Process note: `docs/art/lab/improvement-log.md` is shared by all levels. Reading its tail at 11:09 showed me 2 rows of
  another level's runs (quality only); I did not use them and filtered to my own rows afterwards.

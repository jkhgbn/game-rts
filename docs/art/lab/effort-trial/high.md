# Effort trial: Vinelasher at level **high**

- Start 10:49:39, end 11:16 (report written), **~27 minutes** total. Stopped because there was no FAIL and the quality
  score stopped rising (95 on runs 3, 5, 7 and 8), well before the 75-minute limit.
- Scene: `art/units/_effort_trial/high/vinelasher.tscn` + `vinelasher.gd` (extends `NatureWarModel`). Helper (not part of
  the unit): `lash_preview.gd`, a windowed script that shoots the whip poses from the side (the lab has no such frame).
- Art Lab output: `docs/art/lab/effort-trial/high/` (scorecard, fixes.json, contact sheet, diff sheet, `preview_*.png`).

## Art Lab runs
Command (runs 2-8 add `'compare=prev'`):
`.\tools\art_lab\run_art_lab.ps1 art/units/_effort_trial/high/vinelasher.tscn unit nature -Extra 'out=docs/art/lab/effort-trial/high','ref=thornling,bramblehorn,burr_slinger'`

| Run | Change before the run | Wall s (lab s) | Quality | FAIL / WARN |
|---|---|---|---|---|
| 1 | first build | 43 (29) | 91.3 | 0 / 2 (R3 meadow dE 18.7, R3t nature 18.7) |
| 2 | leaf skirt + back tabard russet (less team green), smaller tabard, two sunk eye slits; lash aimed flatter (was digging into the ground at ~1.8 m, seen in my side preview), thicker lash | 50 (34) | 94 | 0 / 1 (R6cb: fire colour under deutan vs ground dE 9.5) |
| 3 | whip in dark bark, tabard front in team-dark (value step in the team area) | 40 (29) | 95 | 0 / 0 |
| 4 | pale blossom circlet on the head (was a team-dark leaf), tan back plate (top "Improve next": light top / pale crest) | 38 (29) | 94 | 1 / 0 (B4 2 558 vertices > 2 500) |
| 5 | coil spikes 10 -> 5 (bigger) | 37 (29) | 95.4 | 0 / 0 |
| 6 | experiment: dark chest / back plates ("dark saddle" hint) | 47 (29) | 94 | 0 / 1 (R4 heath dE 9.8) -> reverted |
| 7 | plates back to tan, whip back to light thorn (heath 11.5 -> 15.1, meadow 28.4 -> 26.1) | 51 (30) | 95.3 | 0 / 0 |
| 8 | none (repeat for the median) | 46 (29) | 95.3 | 0 / 0 |

Plus 3 runs of my preview helper through `tools\godot_run.ps1` (~13 s each).

## Final
- **Quality 95.3** (median of runs 7 and 8: 95.3 / 95.3). Result **PASS**, 0 FAIL, 0 WARN, 32 PASS.
- Lowest scored checks (all PASS / INFO): S1 autumn floor INFO 21 (dE 14.8), R6cb 76, R4 81 (heath dE 15.2),
  P4 81 (detail 11.8 at 25 m), R12 82 (night dE 15.8), B4 86, R3 88 (meadow dE 26.0, hue gap 24 deg).
- Budgets (final scorecard): **9 meshes drawn** after the merge (ArmR 2, root 1, ArmL 1, Chest 1, Head 1, Hips 1, legs),
  **9 draw instances** at rest (budget 14), **2 433 vertices** (budget 2 500), **1 glow point** (the whip tip; median 1/1/1,
  in the upper half), 0 lights, 3 shadow casters, 0 runtime materials / nodes, frame cost 0.0016 ms per unit.
- Attack A3: the strike changes 62 % of the 40 m silhouette (t 0.24 s, the whip fully out).

## What I built
1. A lean 1.8 m bark warrior: dark bark legs, bark torso with light bark-tan chest / back plates, shoulders and mask
   (tops light, bottoms dark: +57 L\*), russet leaf skirt; team colour on a sash, left leaf pauldron, bracer and tabard.
2. The hook: a 3 m thorn whip coiled in three wide loops around the right arm (circle read), its tail rising over the
   shoulder like a raised sting with the glowing tip bud by the head (the only glow point); a pink bud on the handle.
3. `whip_lash` attack (0.75 s): overhead wind-up, the coil hides and a pre-built 2.5 m lash (+0.3 m handle) unrolls
   (length scale + flick rotation), snaps down at 0.24 s (release), reaches ~3 m, a pink blossom opens on the handle
   with a petal burst, then the whip reels back into the coil.
4. `play_cast` Snare Lash (1.0 s): a low forward lash, the tip lands on the ground at ~2.8 m, a hard yank back with the
   blossom; also a coil-flex fidget, a stalking walk, the Nature hit / death layer.
5. All meshes built in code and cached per type (swept tubes with parallel-transport frames, multi-surface whip meshes);
   no new materials (palette only), no allocation per action.

## With more time
1. A travelling-wave unroll (2-3 keep_separate lash segments or a bend in a vertex shader) instead of the length scale.
2. Heath (dE 15) and the autumn floor (S1 dE 14.8): a paler upper-torso bark tone needs a new palette entry
   (`tools/make_materials.gd`, owner request), since tan / dark swaps only trade meadow against heath.
3. A snare VFX (roots at the tip) with the gameplay side, and a glow flare on the crack.

## Art Lab notes
- **Recipe vs kit rule:** fixes.json #1 (run 1) proposed changing the shared `nature_skin` colour and "give vinelasher its
  own copy first", but the kit README forbids new materials in a unit scene (palette only). A recipe that proposes
  palette swaps / area changes would be usable as is.
- **Contradicting advice across grounds:** R3 (meadow, L\* 63) wants lighter / a dark saddle, R4 heath (darker) wants a
  lighter body, S1 autumn wants the main mass out of L\* 25-55. The dark-saddle hint cost heath 11.5 -> 9.8 (WARN) for
  +1 dE on meadow. A combined hint ("best single change over all grounds") would save a run.
- **Missed problem:** in run 1 the lash hit the ground at ~1.8 m (strike aimed too low) and A3 still PASSed (59 %). The
  lab never shows the extended weapon from the side, and the "attack (strike)" anim tile showed the wind-up. Suggest a
  side frame at each A3 sample and a reach check for melee units (weapon tip distance vs `attack_range` / a declared reach).
- **R6cb hint misleading:** run 2's WARN came from "worst vs ground: fire colour (deutan) dE 9.5" (< 10), but the
  Improve-next text only said "add a value step inside the team-colour area" (the pair metric, 12.8, passed).
- **R5 part name:** the single glow point is on the keep_separate `Coil` node, the value names it "Merged".
- **Report nits:** the run-2 diff table listed R3 / R4 / R3t twice; the scorecard header still says "lab v2.0"; B3 counts
  only visible keep_separate parts (1 of 4: Lash, Bloom and VetTrim are hidden at rest) without saying so.

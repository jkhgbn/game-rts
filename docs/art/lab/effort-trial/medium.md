# Effort trial: Vinelasher, level **medium**

- Start 2026-09-27 10:49:40 (-04:00), end 11:06, **total about 17 minutes** (well under the 75-minute stop).
- Scene: `art/units/_effort_trial/medium/vinelasher.tscn` + `vinelasher.gd` (extends `NatureWarModel`, no `class_name` so the 4 trial levels cannot clash).
- Art Lab output: `docs/art/lab/effort-trial/medium/` (scorecard.md / .json, fixes.json, contact_sheet.png, diff_sheet.png).
- Stopped because there was no FAIL and no WARN, and quality sat at 95 for the last 3 full runs of the final design.

## Art Lab runs
Base command: `.\tools\art_lab\run_art_lab.ps1 art/units/_effort_trial/medium/vinelasher.tscn unit nature -Extra 'out=docs/art/lab/effort-trial/medium','ref=thornling,bramblehorn,burr_slinger'` (runs 2-8 add `'compare=prev'`). Wall = the whole PowerShell call; the lab's own time was 28-37 s.

| # | Change before the run | Wall s | Quality | FAIL | WARN |
|---|---|---|---|---|---|
| 1 | first build | 35 | 93 | 1 (B4 vertices 2793 > 2500) | 0 |
| 2 | whip coil 36 -> 20 segments, loop 20 -> 12, 5 sides; pauldron leaf -> pale thorn; loop moved out | 45 | 93 | 0 | 0 |
| 3 | top "Improve next" (P5 glow placement): whip tail climbs behind the arm, glowing tip on the shoulder | 46 | 94 | 0 | 1 (R4 heath dE 9.7) |
| 4 | pauldron back to the team leaf (heath contrast) | 43 | 95 | 0 | 0 |
| 5 | experiment: torso in deep sap bark (heath) | 40 | 94 | 0 | 0 |
| 6 | torso back to bark (= run 4 design) | 76 | 95 | 0 | 0 |
| 7 | final: lash angled 20 deg outward on the strike; loop hidden once the body lies down | 49 | 95 | 0 | 0 |
| 8 | same (repeat for the median) | 47 | 95 (94.9) | 0 | 0 |

## Final
- **Quality 95** (median of runs 7 and 8: 95 / 94.9). Before / after: 93 -> 95.
- **FAIL: none. WARN: none.** 32 PASS, 12 INFO.
- Final scorecard: 10 meshes drawn / **10 draw instances** at rest, **2223 vertices**, **1 glow point** (WhipLoopTip), 0 lights, 3 shadow casters.
- Key reads: R3 meadow dE 28.7 (3 % melt, hue gap 21 deg); R4k old wood dE 23.8; R4 worst heath dE 11.8; R6 team colour 35 %; R2 max IoU 0.46 vs the Thornling; A3 strike changes 68 % of the silhouette; R5w walk glow 1 in every frame; P5 glow in the upper half.

## What I built
1. A lean 1.8 m bark warrior: brown bark body and dark bark limbs, so the main mass is off the grass hue (R3 dE 29-33).
2. Team green only on a crossed sash, a leaf skirt, a left leaf pauldron with 3 thorns (the asymmetry) and a swept leaf hood; pale thorn horns keep the top light.
3. The hook: a thorn whip wound 3 times round the right arm that drops into a big hanging loop (the circle read, tilted back for the pitch-55 camera), its tail climbing back to the shoulder where the tip glows (the only glow point).
4. `whip_lash` attack (0.7 s): the loop is swapped for a 3 m lash that cracks forward and a little outward, pink blossom on the handle; `play_cast` (Snare Lash, 1.0 s) whirls the lash overhead and slams it down in front.
5. Walk, fidget (wrist roll), NatureWarModel hit / death bloom; 4 keep_separate whip parts toggled with `visible` (no allocation, B10 PASS).

## With more time
1. Heath contrast (worst ground, dE 11.8): try a lighter bark value on the legs or a pale thorn belt, checked with `focus=R3,R4,R4k` so old wood and meadow do not drop.
2. Make the lash a bent, travelling curve (2-3 keyframed meshes or a bone-like chain) so the crack reads as a whip, not a stick, from the side view.
3. A small blossom burst on the handle at the strike (pre-built one-shot petals) and a root-snare decal for the cast.

## Art Lab notes
- The anim strip's "attack (strike)" frame is a 3/4 front view and uses the A3 frame (t 0.24 s in run 1, 0.14 s in run 8): a forward lash is foreshortened to almost nothing there, so the strip under-sells a whip or spear; a side view of the strike would help reach weapons.
- P5 "glow in the upper half" pushes against the brief's "glow: whip tip only" for a whip that hangs low; I solved it by parking the tip on the shoulder, but the hint could mention that a weapon tip at rest may legitimately sit low.
- R4 heath dE is noisy for this model (13.4 / 10.5 / 9.7 / 12.0 / 11.8) and swings around the WARN line of 10 with small material changes; one WARN (run 3) came from that alone.
- B3 reports 2 keep_separate parts while the model has 4 whip parts + the vet trim; the lab counts only the visible ones at rest ("3 hidden parts" in the notes). Fine, but the label could say "visible at rest".
- B4's first hint ("`Merged` 1046 -> 738") was accurate and enough on its own: fewer path segments fixed it in one run.

# Art Lab v3 phase 2: trial results and the fix list (2026-09-27)

Trials run by fresh agents with only CLAUDE.md + art-lab.md. Fix round starts only AFTER the effort trial
(`effort-trial-brief.md`) is done, so all 4 effort levels use the same lab.

| Trial | Item | Runs to green | Minutes | Quality |
|---|---|---|---|---|
| 2.1 | nature_keep R3 (green on grass) | 5 (2 are `focus=` re-checks of 14-15 s; full runs ~140-155 s) | ~11 | 75 -> 85 |
| 2.2 | fire_tower + shadow_tower B5 (real light) | 2 + 1 focus each | ~7 | 85 -> 89 (fire), 92 (shadow) |
Target was <= 3 runs: met for 2.2, not for 2.1 (a recipe missed the team colour, a noise FAIL cost one run).

## Fix list (from the trials' "Art Lab notes")
1. Manual: `compare=` / `focus=` missing from the art-lab.md argument table, with no example; say which checks a focus
   set re-measures (and that `focus=R3` must also refresh R3t / R4k).
2. Recipes must know team-coloured materials: `set_team_color` overwrites Leaves `base_color`, so the R3 recipe must
   target the team-colour path (or a default-colour constant) instead.
3. R3 predictions ~2x too optimistic (18.3 predicted, 10.1 measured): calibrate the predictor against measured deltas.
4. B5 (real light) has no fake-glow recipe: add one (camera-facing halo / emissive card, shared material) and note that
   the fix adds 1 material (B8) and may lower R6 when the light was team-coloured.
5. B8 recipe proposed merging materials with dE 98 (Leaves + DarkStone): only propose merges below a colour-distance limit.
6. Noise: B13 frame cost FAIL 0.28 ms then 0 on re-run (use the noise band / repeat before FAIL); R5 glow count drifts
   35 -> 41 with no change (fix the phase / median).
7. Report consistency: scorecard "+3" vs console "+4"; final line "83 -> 85" when the previous run printed 82.
8. Silhouette diff flags a change when only the reference order changed: sort references before comparing.
9. backlog.md gives wrong paths (`art/buildings/fire/`): keeps and towers live in `art/buildings/`.

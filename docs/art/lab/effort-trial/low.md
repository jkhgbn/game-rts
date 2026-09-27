# Effort trial: low

- Start 10:49, end 10:54 (local), total 5 minutes.

## Art Lab runs
| # | Command | Wall s | Quality | FAIL / WARN |
|---|---|---|---|---|
| 1 | `run_art_lab.ps1 art/units/_effort_trial/low/vinelasher.tscn unit nature -Extra 'out=docs/art/lab/effort-trial/low','ref=thornling,bramblehorn,burr_slinger'` | 36 | 95 | 0 / 1 |
| 2 | same + `compare=prev` (after the whip material swap) | 46 | 95 | 0 / 1 |
| 3 | same + `compare=prev` (repeat, no change) | 57 | 95 | 0 / 1 |

Final quality: **95** (median of runs 2-3). FAIL: none. WARN: R4k contrast on old_wood (dE 15.3 -> 17.5, want >= 24).
Final scorecard (run 1 numbers, geometry unchanged since): 9 meshes after merge, 9 draws at rest, 969 vertices, 1 glow point.

## What I built
- Lean 1.8 m bark body (cylinder torso, straight legs, team leaf skirt and shoulder mantle, leaf cap, L4 gold trim).
- Thorn whip coiled as two wide rings around the right forearm (circle read) with a dark handle in the fist.
- Hidden 3 m thorn lash on ArmR (keep_separate), shown 0.12-0.45 s into `play_attack()` / `play_cast()` while the coil hides.
- One glow point (nature_glow sphere) at the whip tip, on the coil.
- Kit `melee_swing` attack, `fall` death, hit burst, death bloom, shadow blob. Whip uses `nature_sec_slinger_c` (lighter ochre) for contrast.

## Next with more time
- Real lash animation: segmented tapered_path whip that uncoils along an arc, blossom on the handle, tip glow travelling with it.
- Fix R4k (old_wood): a pale value accent on the shoulders/crest instead of reusing the ochre.
- Own attack timeline (wind-up over the shoulder) and a distinct Snare Lash cast pose.

## Art Lab notes
- The top fix recipe suggests editing a shared material (`nature_thorn`) while the kit README says never add materials in a unit scene; the only in-rules route is snapping to another palette entry, which the recipe doesn't propose.
- `run_art_lab.ps1` cannot run from Git Bash `powershell -File` (execution policy); fine from the PowerShell tool.
- The lash is hidden at rest, so the lab never scores the 3 m whip at 40 m; there is no attack-frame reach check.

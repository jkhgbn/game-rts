# cine build: c1_offer

2026-10-08 01:32:30 - `tools/cine/run_cine.ps1 build c1_offer` - hash `a0acccef7450621a` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 98, +1)

0 FAIL, 0 WARN, 34 PASS, 13 info, 0 skipped, 2 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 80 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 18 actors, 28 markers, 9 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 81.00 s (9 shots) | 72..90 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | O1 face guard_w | PASS 100 | worst u 0.46 v 0.60 at 6.50 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | O2 face malrik | PASS 100 | worst u 0.51 v 0.44 at 1.50 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | O3 face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | O4 face malrik | PASS 100 | worst u 0.50 v 0.50 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | O5 face torvald | PASS 100 | worst u 0.75 v 0.38 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | O5 face malrik | PASS 97 | worst u 0.21 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | O6 face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | O7 face torvald | PASS 100 | worst u 0.50 v 0.50 at 4.75 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | O8 face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | O9 face torvald | PASS 100 | worst u 0.65 v 0.33 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut O1>O2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut O2>O3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut O3>O4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut O4>O5 axis | PASS 100 | same side: malrik-torvald | 180-degree rule |  |
| C5 | cut O5>O6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut O6>O7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut O7>O8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut O8>O9 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | O1 line 1 (src 35) | PASS 93 | narrator "Two days after Emberfall, the Bishop of .." 14.2 cps, 4.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | O2 line 1 (src 41) | PASS 95 | malrik "Cold in here. You should let Vessa redec.." 13.7 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | O3 line 1 (src 45) | PASS 96 | torvald "You sent knives after her in the night, .." 13.2 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | O4 line 1 (src 51) | PASS 93 | malrik "Your lake holds the second relic. She'll.." 14.2 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | O5 line 1 (src 56) | PASS 96 | torvald "Ice does not march for your mistakes, Bi.." 13.2 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | O5 line 2 (src 57) | PASS 95 | malrik "Not mistakes. Opportunities. Just until .." 13.5 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | O6 line 1 (src 60) | PASS 100 | torvald "Sensible hands. Yours." 7.9 cps, 2.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | O6 line 2 (src 61) | PASS 100 | malrik "Ours, if you like." 7.5 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | O7 line 1 (src 68) | PASS 100 | torvald "No. My lake stays out of your war." 11.3 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | O7 line 2 (src 69) | PASS 97 | torvald "And hear me: some doors under Crown Holl.." 12.9 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | O8 line 1 (src 73) | PASS 97 | malrik "For now, then. Doors are only closed unt.." 12.9 cps, 4.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | O9 line 1 (src 79) | PASS 100 | narrator "Ice said no. For now." 8.1 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 12 / 12 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | a0acccef7450621a / a0acccef7450621a | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 3fb49aa42f2abf87) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c1_offer.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (malrik in O1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c1_offer.cine` (80 lines), 81.0 s, 9 shots, stage: set forge_intro_torvald

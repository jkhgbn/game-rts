# cine build: c_e2_ashes

2026-10-08 01:05:50 - `tools/cine/run_cine.ps1 build c_e2_ashes` - hash `256ea392d9d2c4fc` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 98, +1)

0 FAIL, 0 WARN, 33 PASS, 15 info, 0 skipped, 2 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 90 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 16 actors, 24 markers, 9 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 75.00 s (9 shots) | 66..90 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | A1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | A2 face ysolde | PASS 100 | worst u 0.50 v 0.50 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | A3 face ysolde | PASS 100 | worst u 0.66 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | A4 face ysolde | PASS 100 | worst u 0.50 v 0.50 at 11.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | A5 face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | A6 face vessa | PASS 98 | worst u 0.23 v 0.30 at 10.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | A6 face ysolde | PASS 100 | worst u 0.71 v 0.42 at 10.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | A7 face maelis | PASS 100 | worst u 0.30 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | A8 face ysolde | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | A9 face vessa | PASS 100 | worst u 0.74 v 0.36 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | A9 face vey | PASS 98 | worst u 0.23 v 0.52 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut A1>A2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut A2>A3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut A3>A4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut A4>A5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut A5>A6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut A6>A7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut A7>A8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut A8>A9 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | A2 line 1 (src 43) | PASS 100 | ysolde "Forty-one. Forty-two. Forty-three." 8.5 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | A3 line 1 (src 51) | PASS 100 | ysolde "No jokes tonight?" 7.7 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | A3 line 2 (src 52) | PASS 100 | vessa "Not tonight." 6.7 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | A4 line 1 (src 57) | PASS 94 | ysolde "Torvald didn't come for my wood. He came.." 14.1 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | A4 line 2 (src 58) | PASS 94 | ysolde "Malrik told him the Hollow is waking. He.." 14.1 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | A5 line 1 (src 60) | PASS 97 | vessa "Then don't stand here alone. Come with u.." 13.1 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | A6 line 1 (src 63) | PASS 97 | ysolde "The wood can't fight this winter. I can." 12.9 cps, 3.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | A6 line 2 (src 66) | PASS 100 | ysolde "Keep it until the wood can." 9.0 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | A7 line 1 (src 80) | PASS 96 | maelis "This is all of us who can still hold a b.." 13.2 cps, 3.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | A8 line 1 (src 82) | PASS 98 | ysolde "Then it's enough. We march with Fire." 12.6 cps, 2.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | A9 line 1 (src 88) | PASS 99 | vessa "You still owe me a story, old man." 12.3 cps, 2.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | A9 line 2 (src 89) | PASS 100 | vey "On the way down." 6.4 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 12 / 12 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 256ea392d9d2c4fc / 256ea392d9d2c4fc | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was befc5683c330d540) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c_e2_ashes.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (vey in A9 (cine 130, runtime 130 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e2_ashes.cine` (90 lines), 75.0 s, 9 shots, stage: set forge_intro_ysolde
- the .cine has 90 lines (demo budget <= 80)

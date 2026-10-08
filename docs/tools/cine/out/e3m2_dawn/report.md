# cine build: e3m2_dawn

2026-10-07 21:22:29 - `tools/cine/run_cine.ps1 build e3m2_dawn` - hash `5b89090faf0b76e8` (2 runs identical)

## Result: **WARN** - quality **97 / 100** (previous run 97, +0)

0 FAIL, 1 WARN, 16 PASS, 11 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 28 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 4 actors, 0 markers, 4 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 30.00 s (4 shots) | 28..32 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | W1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | W2 face ysolde | PASS 100 | worst u 0.72 v 0.45 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | W2 face vessa | PASS 100 | worst u 0.32 v 0.38 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | W3 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F5 | W4 face malrik | PASS 100 | worst u 0.50 v 0.50 at 2.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut W1>W2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut W2>W3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut W3>W4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | W2 line 1 (src 19) | PASS 91 | ysolde "Then the people go south today. All of t.." 15.0 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | W3 line 1 (src 22) | PASS 98 | hush "There is always another night, Bishop." 12.7 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | W3 line 2 (src 23) | PASS 100 | malrik "And every one of them is mine." 11.8 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | **WARN** 50 | 0 / 3 lines voiced: missing W2 "Then the people go south", W3 "There is always another ", W3 "And every one of them is" | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) | render the lines with Voice Forge (tools/voice_forge) or fix the text so it matches the manifest |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 5b89090faf0b76e8 / 5b89090faf0b76e8 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/e3m2_dawn.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (ysolde in W1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/e3m2_dawn.cine` (28 lines), 30.0 s, 4 shots, stage: cine-built (props / cast)

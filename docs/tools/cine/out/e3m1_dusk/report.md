# cine build: e3m1_dusk

2026-10-07 21:22:22 - `tools/cine/run_cine.ps1 build e3m1_dusk` - hash `f482a2d82dd1fd76` (2 runs identical)

## Result: **WARN** - quality **97 / 100** (previous run 97, +0)

0 FAIL, 1 WARN, 16 PASS, 12 info, 0 skipped, 0 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 34 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 2 actors, 0 markers, 5 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 30.00 s (5 shots) | 28..32 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | D1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | D2 face malrik | PASS 100 | worst u 0.50 v 0.50 at 4.50 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | D3 face malrik | PASS 100 | worst u 0.50 v 0.50 at 3.25 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | D4 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F5 | D5 face malrik | PASS 100 | worst u 0.50 v 0.50 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut D1>D2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut D2>D3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut D3>D4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut D4>D5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | D2 line 1 (src 19) | PASS 96 | malrik "The ford is mine. The tree is not. Not t.." 13.3 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | D4 line 1 (src 28) | PASS 90 | narrator "The ford fell at dusk. The golden tree s.." 15.2 cps, 5.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | D5 line 1 (src 33) | PASS 94 | malrik "Tell me to stop again tomorrow, Ysolde. .." 14.1 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | **WARN** 50 | 0 / 3 lines voiced: missing D2 "The ford is mine. The tr", D4 "The ford fell at dusk. T", D5 "Tell me to stop again to" | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) | render the lines with Voice Forge (tools/voice_forge) or fix the text so it matches the manifest |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | f482a2d82dd1fd76 / f482a2d82dd1fd76 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/e3m1_dusk.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (malrik in D1 (cine 60, runtime 60 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/e3m1_dusk.cine` (34 lines), 30.0 s, 5 shots, stage: cine-built (props / cast)

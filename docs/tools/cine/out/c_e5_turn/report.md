# cine build: c_e5_turn

2026-10-08 13:35:13 - `tools/cine/run_cine.ps1 build c_e5_turn` - hash `0cda3f0a462b091b` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 99, +0)

0 FAIL, 0 WARN, 15 PASS, 13 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 60 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 16 actors, 24 markers, 5 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 30.00 s (5 shots) | 28..33 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | U1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | U2 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F3 | U3 face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | U4 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F5 | U4B face malrik_young | PASS 100 | worst u 0.50 v 0.52 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut U1>U2 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C2 | cut U2>U3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut U3>U4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut U4>U4B axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | U1 line 1 (src 38) | PASS 94 | narrator "The same winter, far to the east, the ot.." 14.0 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | U3 line 1 (src 48) | PASS 94 | malrik "Everyone thinks the dark found me. I fou.." 13.9 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 2 / 2 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 0cda3f0a462b091b / 0cda3f0a462b091b | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 07fbc4885acd5a97) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c_e5_turn.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (hound1 in U1 (cine 200, runtime -160 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e5_turn.cine` (60 lines), 30.0 s, 5 shots, stage: set forge_intro_malrik

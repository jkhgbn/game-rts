# cine build: ep2_ending

2026-10-08 13:29:54 - `tools/cine/run_cine.ps1 build ep2_ending` - hash `7d15253c2c9c54f8` (2 runs identical)

## Result: **PASS** - quality **100 / 100** (previous run 98, +1)

0 FAIL, 0 WARN, 29 PASS, 21 info, 0 skipped, 1 s

## Improve next
1. **S3 face vessa** (PASS): keep vessa nearer the band centre in S3 _(from F3 S3 face vessa, shot S3)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 57 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 5 actors, 0 markers, 12 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 85.00 s (12 shots) | 82..96 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | S1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | S2 face vessa | PASS 100 | worst u 0.50 v 0.53 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | S3 face vessa | PASS 97 | worst u 0.21 v 0.59 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | S4 face master | PASS 100 | worst u 0.50 v 0.50 at 0.50 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | S5 face master | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | S6 face vessa | PASS 100 | worst u 0.50 v 0.48 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | S7 face master | PASS 100 | worst u 0.50 v 0.50 at 4.25 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | S8 face vey | PASS 100 | worst u 0.27 v 0.51 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | S8 face vessa | PASS 98 | worst u 0.77 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | S9 face ysolde | PASS 100 | worst u 0.50 v 0.41 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | S10 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F12 | U1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F13 | T1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut S1>S2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut S2>S3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut S3>S4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut S4>S5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut S5>S6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut S6>S7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut S7>S8 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut S8>S9 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut S9>S10 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C10 | cut S10>U1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C11 | cut U1>T1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | S2 line 1 (src 23) | PASS 100 | vessa "Master. Open it. Please." 7.5 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | S4 line 1 (src 30) | PASS 100 | master "My joy. You came all this way." 10.0 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | S4 line 2 (src 31) | PASS 95 | master "I cannot open it. If I let go, what is u.." 13.6 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | S5 line 1 (src 33) | PASS 100 | master "It takes four hands to turn this lock." 11.2 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | S6 line 1 (src 35) | PASS 100 | vessa "Then tell me how!" 6.5 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | S7 line 1 (src 37) | PASS 100 | master "All four of you, or none." 7.4 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | S8 line 1 (src 44) | PASS 100 | vey "Especially Malrik. He always said that." 11.5 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | U1 line 1 (src 51) | PASS 97 | narrator "The door held. The war went looking for .." 13.0 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | U1 line 2 (src 52) | PASS 100 | narrator "and found the last green country: Evenme.." 11.3 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 9 / 9 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 7d15253c2c9c54f8 / 7d15253c2c9c54f8 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was a85e8accd1d63cd3) |  |  |
| B1 | bake | PASS 100 | data/cinematics/ep2_ending.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (vessa in S1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep2_ending.cine` (57 lines), 85.0 s, 12 shots, stage: cine-built (props / cast)

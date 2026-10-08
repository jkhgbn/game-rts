# cine check: c_e4_turnback

2026-10-08 10:54:01 - `tools/cine/run_cine.ps1 check c_e4_turnback` - hash `707b5bcd918de599` (2 runs identical)

## Result: **WARN** - quality **97 / 100**

0 FAIL, 1 WARN, 29 PASS, 17 info, 0 skipped, 5 s

## Improve next
1. **T1 line 1 (src 36)** (WARN): aim for <= 17 chars/s: more time or fewer words _(from S1 T1 line 1 (src 36), shot T1)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 100 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 43 actors, 96 markers, 9 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 70.00 s (9 shots) | 66..76 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | T1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | T2 face ysolde | PASS 100 | worst u 0.50 v 0.35 at 10.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | T3 face maelis | PASS 100 | worst u 0.50 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | T4 face ysolde | PASS 100 | worst u 0.29 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | T4 face maelis | PASS 100 | worst u 0.56 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | T5 face ashby | PASS 100 | worst u 0.46 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | T6 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F8 | T7 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F9 | T8 face ysolde | PASS 100 | worst u 0.50 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | T9 face ysolde | PASS 100 | worst u 0.44 v 0.52 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | T9 face maelis | PASS 100 | worst u 0.33 v 0.54 at 0.25 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut T1>T2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut T2>T3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut T3>T4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut T4>T5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut T5>T6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut T6>T7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut T7>T8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut T8>T9 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | T1 line 1 (src 36) | **WARN** 52 | 17.1 chars/s: narrator "Cinderwatch, on the Fire border. Every b.." 17.1 cps, 4.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot | aim for <= 17 chars/s: more time or fewer words |
| S2 | T2 line 1 (src 40) | PASS 86 | ysolde "Vessa. They are all inside your wall. As.." 16.7 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | T2 line 2 (src 41) | PASS 96 | ysolde "I am not staying. You knew that before I.." 13.2 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | T3 line 1 (src 47) | PASS 94 | maelis "The scouts are back from the Sighing Woo.." 14.0 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | T3 line 2 (src 48) | PASS 90 | maelis "Rime on every trunk. Aldra's totems in a.." 15.3 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | T4 line 1 (src 54) | PASS 88 | maelis "They didn't freeze it to hold it. They f.." 15.9 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | T4 line 2 (src 55) | PASS 100 | ysolde "Then it is waiting for someone." 11.9 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | T5 line 1 (src 62) | PASS 92 | ashby "From the queen, my lady. She said you'd .." 14.7 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | T7 line 1 (src 71) | PASS 100 | vessa "I think the wood can now. V." 9.3 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | T8 line 1 (src 76) | PASS 100 | ysolde "So do I." 5.0 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | T9 line 1 (src 98) | PASS 100 | maelis "Back into the cold, then?" 11.4 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | T9 line 2 (src 99) | PASS 100 | ysolde "Back home." 6.2 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 12 / 12 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 707b5bcd918de599 / 707b5bcd918de599 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | first run |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (guard1 in T1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e4_turnback.cine` (100 lines), 70.0 s, 9 shots, stage: set forge_ep2_feast
- the .cine has 100 lines (demo budget <= 80)

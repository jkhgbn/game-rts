# cine check: ep8_opening

2026-10-08 12:13:59 - `tools/cine/run_cine.ps1 check ep8_opening` - hash `9d6e05d082082471` (2 runs identical)

## Result: **PASS** - quality **98 / 100** (previous run 98, +0)

0 FAIL, 0 WARN, 37 PASS, 26 info, 0 skipped, 12 s

## Improve next
1. **O9 face courier** (PASS): keep courier nearer the band centre in O9 _(from F13 O9 face courier, shot O9)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 176 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 94 actors, 168 markers, 15 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 120.00 s (15 shots) | 116..124 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | O1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | O2A faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F3 | O2B faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F4 | O2C faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F5 | O3 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F6 | O4 face malrik_malrik | PASS 100 | worst u 0.49 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | O5 face malrik_malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | O6 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F9 | O7 face vey | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | O8 face watch_keep_vessa | PASS 100 | worst u 0.39 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | O8 face vey | PASS 100 | worst u 0.25 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | O9 face watch_keep_vessa | PASS 100 | worst u 0.59 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | O9 face courier | PASS 87 | worst u 0.08 v 0.50 at 10.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | O10 face watch_keep_vessa | PASS 100 | worst u 0.69 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F15 | O10 face wren | PASS 100 | worst u 0.40 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F16 | O11 face watch_keep_vessa | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F17 | O12 face watch_keep_vessa | PASS 100 | worst u 0.44 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F18 | O12 face vey | PASS 100 | worst u 0.50 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F19 | O13 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut O1>O2A | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C2 | cut O2A>O2B | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C3 | cut O2B>O2C | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C4 | cut O2C>O3 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C5 | cut O3>O4 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut O4>O5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut O5>O6 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut O6>O7 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C9 | cut O7>O8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C10 | cut O8>O9 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C11 | cut O9>O10 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C12 | cut O10>O11 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C13 | cut O11>O12 axis | PASS 100 | same side: vey-watch_keep_vessa (on the axis) | 180-degree rule |  |
| C14 | cut O12>O13 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | O1 line 1 (src 49) | PASS 92 | narrator "Spring, after the Coinwater. Every battl.." 14.7 cps, 5.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | O2A line 1 (src 68) | PASS 99 | narrator "And the ground ran one way. Down, into t.." 12.5 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | O2C line 1 (src 83) | PASS 100 | narrator "The war itself was opening the door." 12.0 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | O4 line 1 (src 110) | PASS 95 | obren "Hear me, Bishop. No more whispers. Every.." 13.6 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | O5 line 1 (src 114) | PASS 95 | malrik "You've found your voice. Pity. I liked y.." 13.7 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | O7 line 1 (src 133) | PASS 100 | vey "He can't hold it. Not alone. Not any mor.." 11.7 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | O8 line 1 (src 138) | PASS 100 | vessa "Then he won't be. Ashby! Your fastest me.." 12.0 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | O9 line 1 (src 145) | PASS 95 | vessa "The Orb goes north to Torvald. It lay in.." 13.8 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | O9 line 2 (src 147) | PASS 97 | vessa "Tell him: we need all four of you." 13.1 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | O10 line 1 (src 155) | PASS 95 | vessa "The Signet slept in Ysolde's tree. Take .." 13.6 cps, 4.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | O10 line 2 (src 156) | PASS 96 | wren "Before moonrise. I promise." 13.5 cps, 2.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | O11 line 1 (src 164) | PASS 93 | vey "You gave two away. Without a fight. Are .." 14.2 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | O11 line 2 (src 166) | PASS 95 | vessa "Three keys. The fourth is in Malrik's po.." 13.6 cps, 3.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | O12 line 1 (src 170) | PASS 96 | vey "Then we go and ask him. He asked for all.." 13.3 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 14 / 14 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 9d6e05d082082471 / 9d6e05d082082471 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 1d04cc1d7075b0aa) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (stag in O1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep8_opening.cine` (176 lines), 120.0 s, 15 shots, stage: set forge_evenmead
- the .cine has 176 lines (demo budget <= 80)

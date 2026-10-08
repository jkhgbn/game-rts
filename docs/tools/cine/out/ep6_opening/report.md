# cine build: ep6_opening

2026-10-08 13:49:09 - `tools/cine/run_cine.ps1 build ep6_opening` - hash `ad80649902c4ded2` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 99, +0)

0 FAIL, 0 WARN, 61 PASS, 34 info, 0 skipped, 13 s

## Improve next
1. **T08 face messenger** (PASS): keep messenger nearer the band centre in T08 _(from F14 T08 face messenger, shot T08)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 269 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 66 actors, 132 markers, 24 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 180.00 s (24 shots) | 174..186 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | S05 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | S07 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F3 | S22 face torvald | PASS 100 | worst u 0.52 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | S26 face ysolde_young | PASS 100 | worst u 0.45 v 0.35 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | S13 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F6 | T01 face torvald | PASS 100 | worst u 0.45 v 0.44 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | T01 face aldra | PASS 100 | worst u 0.58 v 0.45 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | T02 face t_boy | PASS 100 | worst u 0.51 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | T03 face t_boy | PASS 100 | worst u 0.51 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | T04 face t_boy | PASS 100 | worst u 0.56 v 0.53 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | T05 face hooded | PASS 100 | worst u 0.50 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | T06 face torvald | PASS 100 | worst u 0.50 v 0.59 at 4.75 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | T07 face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | T08 face messenger | PASS 97 | worst u 0.40 v 0.72 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F15 | T09 face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F16 | T10 face torvald | PASS 100 | worst u 0.39 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F17 | T10 face aldra | PASS 100 | worst u 0.63 v 0.44 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F18 | Y01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F19 | Y02 face yy | PASS 100 | worst u 0.59 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F20 | Y03 face ysolde | PASS 100 | worst u 0.50 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F21 | S27 face ysolde | PASS 100 | worst u 0.36 v 0.59 at 2.25 s | head inside the 2.39 band safe area (90 %) |  |
| F22 | S28 messenger | INFO | hidden during the shot |  |  |
| F23 | Y06 face yy | PASS 100 | worst u 0.50 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F24 | Y07 face evenmead_ysolde | PASS 98 | worst u 0.77 v 0.32 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F25 | Y07 face maelis | PASS 98 | worst u 0.23 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F26 | Y08 face evenmead_ysolde | PASS 100 | worst u 0.50 v 0.44 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F27 | Y09 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut S05>S07 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut S07>S22 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C3 | cut S22>S26 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C4 | cut S26>S13 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C5 | cut S13>T01 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut T01>T02 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C7 | cut T02>T03 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut T03>T04 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut T04>T05 axis | PASS 100 | same side: hooded-t_boy (on the axis) | 180-degree rule |  |
| C10 | cut T05>T06 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C11 | cut T06>T07 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C12 | cut T07>T08 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C13 | cut T08>T09 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C14 | cut T09>T10 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C15 | cut T10>Y01 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C16 | cut Y01>Y02 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C17 | cut Y02>Y03 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C18 | cut Y03>S27 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C19 | cut S27>S28 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C20 | cut S28>Y06 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C21 | cut Y06>Y07 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C22 | cut Y07>Y08 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C23 | cut Y08>Y09 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | S05 line 1 (src 34) | PASS 100 | master "Kings brought him their quarrels, and we.." 10.4 cps, 5.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | S07 line 1 (src 38) | PASS 100 | master "Then, between one breath and the next, h.." 10.9 cps, 4.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | S22 line 1 (src 57) | PASS 100 | master "Torvald, the eldest. Where he stands, th.." 11.0 cps, 6.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | S26 line 1 (src 69) | PASS 100 | master "Ysolde. I found her coaxing a sapling th.." 8.4 cps, 6.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | S13 line 1 (src 76) | PASS 100 | master "I know this tale well, child. I was that.." 9.2 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | T01 line 1 (src 96) | PASS 94 | torvald "Ysolde once asked me what I remember of .." 14.0 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | T02 line 1 (src 105) | PASS 90 | torvald "I was a boy on a mountain pass, keeping .." 15.3 cps, 5.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | T03 line 1 (src 117) | PASS 100 | torvald "They never came back. I kept it lit all .." 11.7 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | T04 line 1 (src 125) | PASS 100 | master "All winter? For men who were not coming?" 11.8 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | T04 line 2 (src 126) | PASS 100 | torvald "Someone had to keep the light, I said." 11.9 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | T05 line 1 (src 130) | PASS 100 | master "Then come with me. I need someone who ke.." 11.8 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | T06 line 1 (src 142) | PASS 95 | torvald "He gave me the north. One winter, he gav.." 13.8 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | T07 line 1 (src 154) | PASS 94 | torvald "Something came for it every winter, for .." 14.1 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | T08 line 1 (src 166) | PASS 100 | torvald "He said I wait too long." 12.0 cps, 2.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S15 | T08 line 2 (src 168) | PASS 96 | torvald "Once a rider hammered at my gate, and I .." 13.3 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S16 | T09 line 1 (src 179) | PASS 92 | torvald "He called me his patience. Twelve years .." 14.8 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S17 | T10 line 1 (src 182) | PASS 98 | aldra "You could stop waiting." 12.8 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S18 | T10 line 2 (src 183) | PASS 93 | torvald "No. It is the one thing I am good at." 14.2 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S19 | Y01 line 1 (src 200) | PASS 89 | ysolde "You know how he found me. A girl, a sapl.." 15.8 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S20 | Y02 line 1 (src 207) | PASS 95 | ysolde "After that, for twenty years, he brought.." 13.6 cps, 6.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S21 | Y03 line 1 (src 219) | PASS 100 | ysolde "Every time, he said the same thing." 11.7 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S22 | Y03 line 2 (src 222) | PASS 100 | master "Show me again." 7.0 cps, 2.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S23 | S27 line 1 (src 230) | PASS 94 | ysolde "He gave me the west and told me to keep .." 14.0 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S24 | S28 line 1 (src 240) | PASS 94 | ysolde "He said I would not take a side, not eve.." 14.1 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S25 | S28 line 2 (src 242) | PASS 100 | ysolde "He was right. For far too long." 9.7 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S26 | Y06 line 1 (src 249) | PASS 93 | ysolde "He called me his heart. A heart is the p.." 14.5 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S27 | Y07 line 1 (src 257) | PASS 100 | maelis "You never speak of the night he went." 10.9 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S28 | Y07 line 2 (src 258) | PASS 100 | ysolde "I promised not to. So did someone else." 10.8 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 28 / 28 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | ad80649902c4ded2 / ad80649902c4ded2 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/ep6_opening.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (foe in S22 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep6_opening.cine` (269 lines), 180.0 s, 24 shots, stage: set forge_citadel
- the .cine has 269 lines (demo budget <= 80)

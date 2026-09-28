# cine build: ep4_opening

2026-09-28 18:46:45 - `tools/cine/run_cine.ps1 build ep4_opening` - hash `b7769bb7010d056a` (2 runs identical)

## Result: **PASS** - quality **98 / 100** (previous run 98, +0)

0 FAIL, 0 WARN, 35 PASS, 25 info, 0 skipped, 14 s

## Improve next
1. **S02 face ysolde** (PASS): keep ysolde nearer the band centre in S02 _(from F2 S02 face ysolde, shot S02)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 87 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 50 actors, 88 markers, 14 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 88.00 s (14 shots) | 85..91 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | B01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | S02 face ysolde | PASS 97 | worst u 0.79 v 0.67 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | H03 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F4 | H04 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F5 | H05 face y_child | PASS 100 | worst u 0.29 v 0.35 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | S06 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F7 | S07 face ysolde | PASS 100 | worst u 0.63 v 0.55 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | H08 face y_ysolde | PASS 100 | worst u 0.51 v 0.37 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | H09 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F10 | S10 face ysolde | PASS 100 | worst u 0.51 v 0.39 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | S11 face ysolde | PASS 100 | worst u 0.74 v 0.51 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | S11 face vessa | PASS 100 | worst u 0.35 v 0.51 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | S12 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F14 | S13 face ysolde | PASS 100 | worst u 0.51 v 0.62 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F15 | B14R faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut B01>S02 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut S02>H03 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C3 | cut H03>H04 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut H04>H05 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut H05>S06 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut S06>S07 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut S07>H08 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut H08>H09 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut H09>S10 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C10 | cut S10>S11 axis | PASS 100 | same side: vessa-ysolde | 180-degree rule |  |
| C11 | cut S11>S12 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C12 | cut S12>S13 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C13 | cut S13>B14R axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | B01 line 1 (src 28) | PASS 91 | ysolde "Malrik tells his life as a list of wound.." 15.0 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | S02 line 1 (src 32) | PASS 93 | ysolde "I was born on that hill, the year nothin.." 14.2 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | H03 line 1 (src 38) | PASS 92 | ysolde "My mother buried seed in the snow. The v.." 14.7 cps, 5.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | H04 line 1 (src 41) | PASS 92 | ysolde "In spring it came up green. I have never.." 14.8 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | H05 line 1 (src 44) | PASS 92 | ysolde "A tall man with a burning hem found me c.." 14.7 cps, 5.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | S06 line 1 (src 49) | PASS 94 | ysolde "He said: show me again. So I did, for tw.." 14.0 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | S07 line 1 (src 53) | PASS 94 | ysolde "They call me soft. Neutral. Slow. Slow i.." 14.0 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | H08 line 1 (src 60) | PASS 95 | ysolde "Last winter they burned my wood and froz.." 13.8 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | H09 line 1 (src 65) | PASS 92 | ysolde "I knelt in the black, and I waited. Some.." 14.6 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | S10 line 1 (src 71) | PASS 90 | ysolde "That is my strength. Not fire. Not knive.." 15.3 cps, 5.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | S11 line 1 (src 74) | PASS 91 | ysolde "The Master planted this country with his.." 15.1 cps, 5.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | S12 line 1 (src 77) | PASS 89 | ysolde "Malrik stands up there with his candle, .." 15.7 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | S12 line 2 (src 78) | PASS 97 | ysolde "Let them come. Cut it. Burn it. Freeze i.." 13.1 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | S13 line 1 (src 81) | PASS 98 | vessa "Ysolde. They're moving." 12.8 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S15 | S13 line 2 (src 82) | PASS 100 | ysolde "It will not stop." 8.5 cps, 2.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 15 / 15 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | b7769bb7010d056a / b7769bb7010d056a | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/ep4_opening.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg, position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep4_opening.cine` (87 lines), 88.0 s, 14 shots, stage: set forge_evenmead
- the .cine has 87 lines (demo budget <= 80)

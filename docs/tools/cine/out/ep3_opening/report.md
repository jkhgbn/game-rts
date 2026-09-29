# cine build: ep3_opening

2026-09-28 20:05:50 - `tools/cine/run_cine.ps1 build ep3_opening` - hash `b22831560f12fa71` (2 runs identical)

## Result: **PASS** - quality **97 / 100** (previous run 97, +0)

0 FAIL, 0 WARN, 36 PASS, 25 info, 0 skipped, 6 s

## Improve next
1. **N02 face malrik** (PASS): keep malrik nearer the band centre in N02 _(from F2 N02 face malrik, shot N02)_
2. **N07 face hush** (PASS): keep hush nearer the band centre in N07 _(from F8 N07 face hush, shot N07)_
3. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 116 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 53 actors, 100 markers, 14 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 91.00 s (14 shots) | 88..94 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | B01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | N02 face malrik | PASS 86 | worst u 0.71 v 0.83 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | G03 face m_boy | PASS 100 | worst u 0.64 v 0.46 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | G04 face m_sage | PASS 100 | worst u 0.47 v 0.47 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | N05 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F6 | G06 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F7 | N07 face malrik | PASS 100 | worst u 0.33 v 0.55 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | N07 face hush | PASS 95 | worst u 0.66 v 0.73 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | W02 vessa | INFO | hidden during the shot |  |  |
| F10 | G09 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F11 | N10 face stone | PASS 100 | worst u 0.31 v 0.60 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | N11 face malrik | PASS 100 | worst u 0.73 v 0.48 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | N11 face torvald | PASS 100 | worst u 0.36 v 0.55 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | N12 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F15 | N13 face malrik | PASS 100 | worst u 0.50 v 0.56 at 5.50 s | head inside the 2.39 band safe area (90 %) |  |
| F16 | B14 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut B01>N02 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut N02>G03 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C3 | cut G03>G04 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut G04>N05 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C5 | cut N05>G06 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut G06>N07 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C7 | cut N07>W02 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut W02>G09 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut G09>N10 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C10 | cut N10>N11 axis | PASS 100 | same side: malrik-stone | 180-degree rule |  |
| C11 | cut N11>N12 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C12 | cut N12>N13 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C13 | cut N13>B14 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | B01 line 1 (src 26) | PASS 99 | malrik "Everyone tells my story wrong. Let me tr.." 12.4 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | N02 line 1 (src 30) | PASS 91 | malrik "I was a gravedigger's son. I grew up amo.." 15.0 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | G03 line 1 (src 36) | PASS 92 | malrik "The Master found me reading tombstones b.." 14.8 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | G04 line 1 (src 40) | PASS 92 | malrik "Too. Fourth of four. Fire was his joy, i.." 14.6 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | N05 line 1 (src 45) | PASS 92 | malrik "And me? He gave me what was left over. T.." 14.8 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | G06 line 1 (src 51) | PASS 92 | malrik "Then he vanished and left us nothing. So.." 14.8 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | N07 line 1 (src 68) | PASS 91 | malrik "I took the dark and taught it to kneel. .." 15.0 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | W02 line 1 (src 72) | PASS 91 | malrik "She missed. Emberfall. Then the Hollow. .." 15.1 cps, 5.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | G09 line 1 (src 77) | PASS 92 | malrik "I kept something. A candle. A knife. A s.." 14.6 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | N10 line 1 (src 95) | PASS 92 | malrik "It whispers. Let it. I am the one who li.." 14.6 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | N11 line 1 (src 99) | PASS 92 | malrik "That is how a gravedigger's son grows st.." 14.6 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | N12 line 1 (src 104) | PASS 91 | malrik "Look at it. The last green country. Flow.." 15.1 cps, 5.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | N12 line 2 (src 105) | PASS 90 | malrik "They will stand there and tell me to sto.." 15.3 cps, 4.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | N13 line 1 (src 109) | PASS 99 | malrik "I have heard “stop” all my life." 12.3 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S15 | N13 line 2 (src 110) | PASS 100 | malrik "I will not stop." 8.0 cps, 2.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 15 / 15 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | b22831560f12fa71 / b22831560f12fa71 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/ep3_opening.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (m_boy in G04 (cine -200, runtime 160 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep3_opening.cine` (116 lines), 91.0 s, 14 shots, stage: set forge_evenmead
- the .cine has 116 lines (demo budget <= 80)

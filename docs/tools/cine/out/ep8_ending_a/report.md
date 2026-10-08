# cine check: ep8_ending_a

2026-10-08 12:21:46 - `tools/cine/run_cine.ps1 check ep8_ending_a` - hash `0f6f153d19cc7685` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 98, +1)

0 FAIL, 0 WARN, 47 PASS, 26 info, 0 skipped, 3 s

## Improve next
1. **E10 face master** (PASS): keep master nearer the band centre in E10 _(from F14 E10 face master, shot E10)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 140 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 20 actors, 24 markers, 17 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 110.00 s (17 shots) | 106..114 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | E01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | E02A face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | E02B face ysolde | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | E02C face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | E02D face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | E03 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F7 | E04 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F8 | E05 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F9 | E06 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F10 | E07 face vey | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | E08 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F12 | E09 face vessa | PASS 100 | worst u 0.25 v 0.39 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | E09 face master | PASS 100 | worst u 0.63 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | E10 face master | PASS 95 | worst u 0.50 v 0.74 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F15 | E11 face master | PASS 100 | worst u 0.53 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F16 | E11 face vessa | PASS 100 | worst u 0.44 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F17 | E11 face malrik | PASS 100 | worst u 0.58 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F18 | E11B face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F19 | E12 face master | PASS 100 | worst u 0.36 v 0.44 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F20 | E12 face vey | PASS 100 | worst u 0.69 v 0.49 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F21 | E13 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut E01>E02A axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut E02A>E02B axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut E02B>E02C axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut E02C>E02D axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut E02D>E03 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut E03>E04 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut E04>E05 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut E05>E06 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut E06>E07 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C10 | cut E07>E08 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C11 | cut E08>E09 axis | PASS 100 | same side: master-vessa | 180-degree rule |  |
| C12 | cut E09>E10 axis | PASS 100 | same side: master-vessa | 180-degree rule |  |
| C13 | cut E10>E11 axis | PASS 100 | same side: master-vessa | 180-degree rule |  |
| C14 | cut E11>E11B axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C15 | cut E11B>E12 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C16 | cut E12>E13 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | E01 line 1 (src 50) | PASS 100 | vessa "Now! All four! Together!" 10.0 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | E02A line 1 (src 54) | PASS 100 | torvald "Together, then." 9.4 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | E02B line 1 (src 57) | PASS 100 | ysolde "Together." 6.4 cps, 1.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | E02C line 1 (src 60) | PASS 99 | obren "Keep me, Bishop. I made you strong." 12.5 cps, 2.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | E02D line 1 (src 65) | PASS 97 | malrik "You made me hungry. Different thing." 12.9 cps, 2.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | E04 line 1 (src 78) | PASS 100 | obren "I only wanted... to build something that.." 10.4 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | E05 line 1 (src 84) | PASS 100 | master "You did, Obren. It held me twelve years." 10.0 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | E08 line 1 (src 105) | PASS 100 | vey "There he is. Took his time." 10.4 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | E09 line 1 (src 111) | PASS 100 | vessa "Master!" 4.4 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | E09 line 2 (src 113) | PASS 100 | master "My joy. Still never waits." 10.0 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | E10 line 1 (src 116) | PASS 100 | master "A thousand years I held the world in one.." 12.1 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | E10 line 2 (src 117) | PASS 96 | master "The harder I held, the more it slipped." 13.4 cps, 2.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | E11 line 1 (src 120) | PASS 96 | master "Kings. Cities. Even you four. I gave you.." 13.3 cps, 4.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | E11B line 1 (src 124) | PASS 94 | malrik "In fairness, it was a great deal of gold.." 14.1 cps, 2.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S15 | E12 line 1 (src 127) | PASS 100 | master "So I will not hold it again." 10.8 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S16 | E12 line 2 (src 128) | PASS 100 | vey "So. The lightning." 10.0 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S17 | E12 line 3 (src 129) | PASS 100 | vessa "FINALLY." 5.0 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S18 | E12 line 4 (src 131) | PASS 100 | vey "His. Lent to me to keep you four alive. .." 11.4 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S19 | E13 line 1 (src 139) | PASS 100 | master "Whoever sits there holds the world, as I.." 10.0 cps, 4.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S20 | E13 line 2 (src 140) | PASS 90 | master "Someone will always want that seat. Choo.." 15.4 cps, 3.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 20 / 20 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 0f6f153d19cc7685 / 0f6f153d19cc7685 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 5c904e66897db417) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (vey in E01 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep8_ending_a.cine` (140 lines), 110.0 s, 17 shots, stage: set forge_intro_malrik
- the .cine has 140 lines (demo budget <= 80)

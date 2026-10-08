# cine check: ep8_ending_b

2026-10-08 12:27:36 - `tools/cine/run_cine.ps1 check ep8_ending_b` - hash `68aa3bb31ce13594` (2 runs identical)

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 30 PASS, 15 info, 0 skipped, 7 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 197 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 74 actors, 116 markers, 9 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 67.00 s (9 shots) | 64..70 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | E15 face vessa | PASS 100 | worst u 0.32 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | E15 face malrik | PASS 100 | worst u 0.44 v 0.44 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | E16 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F4 | E17 face torvald_torvald | PASS 100 | worst u 0.52 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | E18 face ysolde_ysolde | PASS 100 | worst u 0.51 v 0.48 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | E18B face ysolde | PASS 100 | worst u 0.45 v 0.33 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | E19 face malrik | PASS 100 | worst u 0.50 v 0.38 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | E20 face watch_keep_vessa | PASS 100 | worst u 0.50 v 0.56 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | E21 face dacian | PASS 100 | worst u 0.57 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | E21 face seraphine | PASS 100 | worst u 0.40 v 0.49 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | E22 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut E15>E16 axis | PASS 100 | same side: malrik-vessa | 180-degree rule |  |
| C2 | cut E16>E17 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C3 | cut E17>E18 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C4 | cut E18>E18B axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut E18B>E19 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut E19>E20 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C7 | cut E20>E21 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut E21>E22 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | E15 line 1 (src 71) | PASS 100 | vessa "Nobody sits. Not ever again." 10.8 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | E15 line 2 (src 85) | PASS 100 | master "Good." 3.1 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | E17 line 1 (src 110) | PASS 100 | master "Torvald opened his gate, and he kept it .." 10.0 cps, 4.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | E18 line 1 (src 126) | PASS 100 | master "Ysolde planted the Hollow with oaks. She.." 11.2 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | E19 line 1 (src 152) | PASS 93 | master "Malrik kept watch over the deep. The dar.." 14.2 cps, 4.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | E19 line 2 (src 154) | PASS 100 | master "It never frightened him." 9.2 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | E20 line 1 (src 166) | PASS 96 | master "Vessa rebuilt my observatory, and taught.." 13.5 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | E20 line 2 (src 169) | PASS 100 | master "Mostly." 4.4 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | E21 line 1 (src 184) | PASS 100 | master "The two harbour cities fought one more d.." 11.0 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | E22 line 1 (src 197) | PASS 100 | master "And the throne stayed empty. That was th.." 11.0 cps, 6.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 10 / 10 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 68aa3bb31ce13594 / 68aa3bb31ce13594 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was a50d4df40858363f) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (vessa in E15 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep8_ending_b.cine` (197 lines), 67.0 s, 9 shots, stage: set forge_intro_malrik
- the .cine has 197 lines (demo budget <= 80)

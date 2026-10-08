# cine check: ep5_ending

2026-10-08 11:19:06 - `tools/cine/run_cine.ps1 check ep5_ending` - hash `3e63aea3e1a18d39` (2 runs identical)

## Result: **PASS** - quality **99 / 100**

0 FAIL, 0 WARN, 26 PASS, 13 info, 0 skipped, 2 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 78 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 20 actors, 80 markers, 7 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 40.00 s (7 shots) | 38..43 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | S06 face master | PASS 99 | worst u 0.50 v 0.70 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | N2 face y_vessa | PASS 100 | worst u 0.43 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | N2 face y_malrik | PASS 100 | worst u 0.59 v 0.38 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | N3 face y_vessa | PASS 100 | worst u 0.73 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | N3 face y_malrik | PASS 100 | worst u 0.73 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | N4 face master | PASS 100 | worst u 0.57 v 0.51 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | N5 face vessa | PASS 100 | worst u 0.50 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | N5B faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F9 | N6 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut S06>N2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut N2>N3 axis | PASS 100 | same side: y_malrik-y_vessa (on the axis) | 180-degree rule |  |
| C3 | cut N3>N4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut N4>N5 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C5 | cut N5>N5B | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut N5B>N6 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | N2 line 1 (src 32) | PASS 94 | master "Vessa. Malrik. The two harbour cities ar.." 13.8 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | N2 line 2 (src 34) | PASS 86 | vessa "Of course, Master! No problem at all!" 16.8 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | N2 line 3 (src 35) | PASS 99 | malrik "None whatsoever." 12.3 cps, 1.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | N3 line 1 (src 40) | PASS 96 | vessa "I'm taking the gold one!" 13.3 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | N3 line 2 (src 42) | PASS 100 | malrik "Naturally." 8.3 cps, 1.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | N4 line 1 (src 49) | PASS 98 | vey "You heard her. No problem at all." 12.7 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | N4 line 2 (src 50) | PASS 100 | master "I heard them both." 8.2 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | N5 line 1 (src 59) | PASS 90 | narrator "Three years later he was gone, and the p.." 15.3 cps, 5.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 8 / 8 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 3e63aea3e1a18d39 / 3e63aea3e1a18d39 | same spec + seed = same bytes |  |
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
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (master in N2 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep5_ending.cine` (78 lines), 40.0 s, 7 shots, stage: set forge_citadel

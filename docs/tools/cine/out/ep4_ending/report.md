# cine build: ep4_ending

2026-10-08 14:08:48 - `tools/cine/run_cine.ps1 build ep4_ending` - hash `456e3372a926cf53` (2 runs identical)

## Result: **PASS** - quality **100 / 100** (previous run 99, +0)

0 FAIL, 0 WARN, 27 PASS, 16 info, 0 skipped, 6 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 119 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 69 actors, 156 markers, 9 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 60.00 s (9 shots) | 57..64 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | W1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | W2 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F3 | W3 face ysolde | PASS 100 | worst u 0.32 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | W3 face vessa | PASS 100 | worst u 0.68 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | W4 face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | W4B face ysolde | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | W5 face malrik_malrik | PASS 100 | worst u 0.49 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | W6 face torvald_torvald | PASS 100 | worst u 0.44 v 0.44 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | W6 face aldra | PASS 100 | worst u 0.59 v 0.44 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | W7 face vey | PASS 100 | worst u 0.51 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | W8 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut W1>W2 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C2 | cut W2>W3 axis | PASS 100 | same side: vessa-ysolde | 180-degree rule |  |
| C3 | cut W3>W4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut W4>W4B axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut W4B>W5 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut W5>W6 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C7 | cut W6>W7 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut W7>W8 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | W1 line 1 (src 37) | PASS 94 | narrator "The blizzard closed the passes, and the .." 13.9 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | W3 line 1 (src 45) | PASS 100 | vessa "You'll keep it?" 9.4 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | W3 line 2 (src 46) | PASS 100 | ysolde "Until spring." 8.1 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | W4 line 1 (src 51) | PASS 100 | vessa "And then?" 6.4 cps, 1.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | W4B line 1 (src 54) | PASS 100 | ysolde "Then we'll see what grows." 10.8 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | W5 line 1 (src 75) | PASS 99 | obren "Four keys, Bishop. Count them in your sl.." 12.2 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | W8 line 1 (src 116) | PASS 91 | narrator "Four wizards, four fires, one long winte.." 15.0 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 7 / 7 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 456e3372a926cf53 / 456e3372a926cf53 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 43e59f237e99f2a2) |  |  |
| B1 | bake | PASS 100 | data/cinematics/ep4_ending.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (ysolde in W1 (cine 90, runtime 90 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep4_ending.cine` (119 lines), 60.0 s, 9 shots, stage: set forge_evenmead
- the .cine has 119 lines (demo budget <= 80)

# cine build: c_e2_stair

2026-10-08 01:06:08 - `tools/cine/run_cine.ps1 build c_e2_stair` - hash `01a3d7a7e9c6726b` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 98, +1)

0 FAIL, 0 WARN, 36 PASS, 19 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 81 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 7 actors, 16 markers, 12 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 85.00 s (12 shots) | 70..96 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | T1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | T2 face vessa | PASS 100 | worst u 0.50 v 0.50 at 5.25 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | T3 face vessa | PASS 100 | worst u 0.68 v 0.47 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | T3 face vey | PASS 100 | worst u 0.33 v 0.51 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | T4 face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | T5 face vey | PASS 100 | worst u 0.50 v 0.50 at 2.50 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | T6 face vessa | PASS 100 | worst u 0.74 v 0.45 at 9.50 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | T6 face vey | PASS 100 | worst u 0.29 v 0.52 at 9.50 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | T7 face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | T8 face vey | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | T9 face wren | PASS 100 | worst u 0.48 v 0.38 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | T10 face wren | PASS 100 | worst u 0.50 v 0.50 at 0.25 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | T11 face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | T12 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

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
| C8 | cut T8>T9 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut T9>T10 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C10 | cut T10>T11 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C11 | cut T11>T12 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | T2 line 1 (src 34) | PASS 96 | vessa "Ashby says the seal was older than the k.." 13.3 cps, 3.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | T3 line 1 (src 39) | PASS 93 | vey "Older than the kingdom. He sealed it the.." 14.5 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | T4 line 1 (src 42) | PASS 93 | vessa "You talk about the Master like you knew .." 14.2 cps, 4.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | T5 line 1 (src 45) | PASS 93 | vey "Before the four of you, there was a swor.." 14.2 cps, 4.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | T5 line 2 (src 46) | PASS 94 | vey "I stood behind his throne when kings sti.." 14.0 cps, 3.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | T6 line 1 (src 49) | PASS 96 | vessa "And the lightning? No kingdom throws lig.." 13.5 cps, 3.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | T6 line 2 (src 50) | PASS 92 | vey "It's his storm, not mine. He lent it to .." 14.6 cps, 4.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | T7 line 1 (src 55) | PASS 99 | vessa "And when were you going to tell me?" 12.4 cps, 2.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | T8 line 1 (src 57) | PASS 100 | vey "On the way down." 6.4 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | T9 line 1 (src 68) | PASS 100 | wren "Vessa! Word from Ysolde." 9.6 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | T10 line 1 (src 70) | PASS 93 | wren "Nature's army follows you down. All of i.." 14.4 cps, 4.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | T11 line 1 (src 73) | PASS 100 | vessa "Then we don't keep them waiting." 12.0 cps, 2.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | T12 line 1 (src 80) | PASS 100 | vey "Mind the seventh step. It bites." 12.0 cps, 2.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 13 / 13 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 01a3d7a7e9c6726b / 01a3d7a7e9c6726b | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 7c0542833cf93bbc) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c_e2_stair.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (wren in T1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e2_stair.cine` (81 lines), 85.0 s, 12 shots, stage: set forge_watch_keep
- the .cine has 81 lines (demo budget <= 80)

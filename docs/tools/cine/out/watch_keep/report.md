# cine build: watch_keep

2026-09-27 08:33:05 - `tools/cine/run_cine.ps1 build watch_keep` - hash `af7e0dbbd2bb85ee` (2 runs identical)

## Result: **PASS** - quality **100 / 100** (previous run 100, +0)

0 FAIL, 0 WARN, 22 PASS, 13 info, 0 skipped, 2 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 40 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 2 actors, 9 markers, 8 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 46.00 s (8 shots) | 45..60 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | S1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | S2 face vessa | PASS 100 | worst u 0.50 v 0.33 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | S3 face shade | PASS 100 | worst u 0.50 v 0.39 at 1.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | S4 face vessa | PASS 100 | worst u 0.50 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | S5 face vessa | PASS 98 | worst u 0.22 v 0.45 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | S5 face shade | PASS 97 | worst u 0.79 v 0.48 at 3.25 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | S6 face shade | PASS 100 | worst u 0.50 v 0.44 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | S7 face vessa | PASS 100 | worst u 0.50 v 0.41 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | S8 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut S1>S2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut S2>S3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut S3>S4 axis | PASS 100 | same side: shade-vessa (on the axis) | 180-degree rule |  |
| C4 | cut S4>S5 axis | PASS 100 | same side: shade-vessa | 180-degree rule |  |
| C5 | cut S5>S6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut S6>S7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut S7>S8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | S2 line 1 (src 19) | PASS 98 | vessa "The watch fires are out. All of them." 12.6 cps, 2.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | S4 line 1 (src 26) | PASS 97 | vessa "You are a long way from the dark, shade." 12.9 cps, 3.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | S5 line 1 (src 28) | PASS 100 | shade "The keep sleeps. So should you." 11.9 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | S7 line 1 (src 36) | PASS 100 | vessa "Not tonight." 4.8 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | af7e0dbbd2bb85ee / af7e0dbbd2bb85ee | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/watch_keep.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (vessa in S1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/watch_keep.cine` (40 lines), 46.0 s, 8 shots, stage: cine-built (props / cast)

# cine check: forge_watch_keep_probe

2026-09-27 08:10:19 - `tools/cine/run_cine.ps1 check forge_watch_keep_probe` - hash `b95d66afab1fd88b` (2 runs identical)

## Result: **WARN** - quality **98 / 100** (previous run 98, +0)

0 FAIL, 1 WARN, 14 PASS, 9 info, 0 skipped, 1 s

## Improve next
1. **W02 line 1 (src 6)** (WARN): cast the speaker or use narrator _(from S1 W02 line 1 (src 6), shot W02)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 9 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 3 actors, 16 markers, 5 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 22.00 s (5 shots) | 10..40 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | W01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | W02 face vessa | PASS 100 | worst u 0.50 v 0.45 at 4.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | W03 face guard_w | PASS 100 | worst u 0.50 v 0.49 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | W04 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F5 | F1 face vessa | PASS 100 | worst u 0.50 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut W01>W02 axis | PASS 100 | same side: guard_e-guard_w, guard_e-vessa, guard_w-vessa | 180-degree rule |  |
| C2 | cut W02>W03 axis | PASS 100 | same side: guard_e-vessa (on the axis) | 180-degree rule |  |
| C3 | cut W03>W04 axis | PASS 100 | same side: guard_e-guard_w, guard_e-vessa (on the axis), guard_w-vessa (on the axis) | 180-degree rule |  |
| C4 | cut W04>F1 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | W02 line 1 (src 6) | **WARN** 69 | speaker "vessa" not cast: vessa "The watch fires are out." 9.6 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot | cast the speaker or use narrator |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | b95d66afab1fd88b / b95d66afab1fd88b | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 4739b7ad9b77d91d) |  |  |

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
- source `docs/tools/world_forge/cine/forge_watch_keep_probe.cine` (9 lines), 22.0 s, 5 shots, stage: set forge_watch_keep

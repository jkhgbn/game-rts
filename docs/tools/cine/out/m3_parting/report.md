# cine build: m3_parting

2026-10-08 00:40:24 - `tools/cine/run_cine.ps1 build m3_parting` - hash `39aeee4e94cb7be5` (2 runs identical)

## Result: **PASS** - quality **100 / 100** (previous run 98, +2)

0 FAIL, 0 WARN, 22 PASS, 8 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 36 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 3 actors, 0 markers, 4 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 40.00 s (4 shots) | 36..44 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | P1 face ysolde | PASS 100 | worst u 0.68 v 0.53 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | P1 face vessa | PASS 100 | worst u 0.50 v 0.50 at 5.50 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | P2 face vessa | PASS 100 | worst u 0.50 v 0.50 at 8.50 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | P3 face ysolde | PASS 100 | worst u 0.50 v 0.50 at 0.25 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | P4 face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.75 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut P1>P2 axis | PASS 100 | same side: vessa-ysolde | 180-degree rule |  |
| C2 | cut P2>P3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut P3>P4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | P1 line 1 (src 21) | PASS 100 | ysolde "I warned you. You didn't listen. Neither.." 8.6 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | P2 line 1 (src 24) | PASS 100 | vessa "Then help me stop it. Please." 8.1 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | P2 line 2 (src 25) | PASS 100 | ysolde "Nature doesn't take sides, Vessa." 7.5 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | P3 line 1 (src 28) | PASS 100 | ysolde "But when your war comes for my wood, and.." 10.0 cps, 8.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | P4 line 1 (src 34) | PASS 97 | narrator "Fire is at war with Shadow, while Ice an.." 12.8 cps, 7.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 5 / 5 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 39aeee4e94cb7be5 / 39aeee4e94cb7be5 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was c43466049764bf37) |  |  |
| B1 | bake | PASS 100 | data/cinematics/m3_parting.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (vessa in P1 (cine 90, runtime 90 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/m3_parting.cine` (36 lines), 40.0 s, 4 shots, stage: cine-built (props / cast)

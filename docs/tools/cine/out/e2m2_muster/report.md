# cine build: e2m2_muster

2026-10-07 21:39:58 - `tools/cine/run_cine.ps1 build e2m2_muster` - hash `e866f3d421d2f9fd` (2 runs identical)

## Result: **WARN** - quality **96 / 100** (previous run 96, +0)

0 FAIL, 1 WARN, 15 PASS, 9 info, 0 skipped, 0 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 21 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 3 actors, 0 markers, 3 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 19.50 s (3 shots) | 17..22 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | M1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | M2 face ysolde | PASS 100 | worst u 0.50 v 0.50 at 5.75 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | M3 face vessa | PASS 100 | worst u 0.50 v 0.50 at 2.75 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut M1>M2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut M2>M3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | M1 line 1 (src 14) | PASS 90 | narrator "Nature had no kingdom left, only seed. F.." 15.4 cps, 5.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | M2 line 1 (src 17) | PASS 90 | ysolde "Three groves along your line, Vessa. Giv.." 15.3 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | M3 line 1 (src 20) | PASS 91 | vessa "Three trees? I can do three trees. Torva.." 15.1 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | **WARN** 50 | 0 / 3 lines voiced: missing M1 "Nature had no kingdom le", M2 "Three groves along your ", M3 "Three trees? I can do th" | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) | render the lines with Voice Forge (tools/voice_forge) or fix the text so it matches the manifest |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | e866f3d421d2f9fd / e866f3d421d2f9fd | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/e2m2_muster.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (ysolde in M1 (cine 120, runtime 120 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/e2m2_muster.cine` (21 lines), 19.5 s, 3 shots, stage: cine-built (props / cast)

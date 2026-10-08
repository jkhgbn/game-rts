# cine build: e3m3_offer

2026-10-08 14:11:34 - `tools/cine/run_cine.ps1 build e3m3_offer` - hash `3a27fe04bdc1c138` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 99, +0)

0 FAIL, 0 WARN, 16 PASS, 7 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 22 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 2 actors, 0 markers, 2 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 12.00 s (2 shots) | 10..14 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | O1 face malrik | PASS 100 | worst u 0.50 v 0.50 at 2.00 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | O2 face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.25 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut O1>O2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | O1 line 1 (src 15) | PASS 94 | obren "They are mine now, Bishop. Ask me nicely.." 14.1 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | O2 line 1 (src 20) | PASS 95 | malrik "You raised my dead, and now you sell me .." 13.8 cps, 3.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | O2 line 2 (src 21) | PASS 89 | obren "Not sell. Lend. You will hardly notice t.." 15.8 cps, 3.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 3 / 3 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 3a27fe04bdc1c138 / 3a27fe04bdc1c138 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was fc8297e3e74607d0) |  |  |
| B1 | bake | PASS 100 | data/cinematics/e3m3_offer.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (malrik in O1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/e3m3_offer.cine` (22 lines), 12.0 s, 2 shots, stage: cine-built (props / cast)

# cine build: e3m4_return

2026-10-07 23:56:39 - `tools/cine/run_cine.ps1 build e3m4_return` - hash `6c78f6b622c76fe1` (2 runs identical)

## Result: **PASS** - quality **99 / 100**

0 FAIL, 0 WARN, 17 PASS, 11 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 32 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 3 actors, 0 markers, 4 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 21.50 s (4 shots) | 19..23 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | R1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | R2 face torvald | PASS 100 | worst u 0.50 v 0.50 at 2.50 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | R3 face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.50 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | R4 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut R1>R2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut R2>R3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut R3>R4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | R1 line 1 (src 19) | PASS 90 | narrator "Three days later. Malrik came back from .." 15.3 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | R2 line 1 (src 22) | PASS 90 | torvald "Every dusk the old man walks down to the.." 15.2 cps, 5.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | R3 line 1 (src 26) | PASS 100 | malrik "Looks. Not crosses?" 7.6 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | R4 line 1 (src 29) | PASS 93 | torvald "Not yet. I think he was waiting for you..." 14.5 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 4 / 4 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 6c78f6b622c76fe1 / 6c78f6b622c76fe1 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | first run |  |  |
| B1 | bake | PASS 100 | data/cinematics/e3m4_return.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (torvald in R1 (cine 250, runtime -110 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/e3m4_return.cine` (32 lines), 21.5 s, 4 shots, stage: cine-built (props / cast)

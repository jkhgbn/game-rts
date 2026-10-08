# cine build: e3m4_whisper

2026-10-07 21:22:44 - `tools/cine/run_cine.ps1 build e3m4_whisper` - hash `19220c1a584663fa` (2 runs identical)

## Result: **WARN** - quality **97 / 100** (previous run 97, +0)

0 FAIL, 1 WARN, 16 PASS, 8 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 26 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 4 actors, 0 markers, 3 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 16.50 s (3 shots) | 14..18 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | H1 face vey | PASS 100 | worst u 0.50 v 0.50 at 2.50 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | H2 face malrik | PASS 100 | worst u 0.50 v 0.50 at 1.25 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | H3 face torvald | PASS 100 | worst u 0.50 v 0.50 at 6.25 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut H1>H2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut H2>H3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | H2 line 1 (src 19) | PASS 91 | obren "Torvald. Old frost. You feel it too. Joi.." 14.9 cps, 4.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | H3 line 1 (src 23) | PASS 100 | torvald "...It knows my name." 8.0 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | H3 line 2 (src 25) | PASS 93 | malrik "It knows everyone's name. It is a stone .." 14.5 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | **WARN** 50 | 0 / 3 lines voiced: missing H2 "Torvald. Old frost. You ", H3 "...It knows my name.", H3 "It knows everyone's name" | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) | render the lines with Voice Forge (tools/voice_forge) or fix the text so it matches the manifest |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 19220c1a584663fa / 19220c1a584663fa | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/e3m4_whisper.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (malrik in H1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/e3m4_whisper.cine` (26 lines), 16.5 s, 3 shots, stage: cine-built (props / cast)

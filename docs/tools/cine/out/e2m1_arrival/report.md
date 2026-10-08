# cine build: e2m1_arrival

2026-10-07 21:39:40 - `tools/cine/run_cine.ps1 build e2m1_arrival` - hash `6ef4b96e6c26e422` (2 runs identical)

## Result: **WARN** - quality **96 / 100** (previous run 95, +0)

0 FAIL, 1 WARN, 14 PASS, 10 info, 0 skipped, 0 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 24 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 3 actors, 0 markers, 3 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 21.00 s (3 shots) | 19..23 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | A1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | A2 face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.50 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | A3 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut A1>A2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut A2>A3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | A1 line 1 (src 14) | PASS 89 | narrator "The Sighing Wood kept out of every quarr.." 15.5 cps, 6.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | A2 line 1 (src 17) | PASS 92 | vessa "Fire AND frost. They didn't just burn it.." 14.8 cps, 4.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | A3 line 1 (src 21) | PASS 95 | messenger "The Heartwood is past the old tree. She'.." 13.8 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | **WARN** 50 | 0 / 3 lines voiced: missing A1 "The Sighing Wood kept ou", A2 "Fire AND frost. They did", A3 "The Heartwood is past th" | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) | render the lines with Voice Forge (tools/voice_forge) or fix the text so it matches the manifest |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 6ef4b96e6c26e422 / 6ef4b96e6c26e422 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/e2m1_arrival.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (vessa in A1 (cine 150, runtime 150 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/e2m1_arrival.cine` (24 lines), 21.0 s, 3 shots, stage: cine-built (props / cast)

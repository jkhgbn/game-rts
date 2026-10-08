# cine build: e2m5_cavern

2026-10-07 21:40:41 - `tools/cine/run_cine.ps1 build e2m5_cavern` - hash `99dc71e6201fc14b` (2 runs identical)

## Result: **WARN** - quality **96 / 100** (previous run 95, +0)

0 FAIL, 1 WARN, 16 PASS, 11 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 28 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 5 actors, 0 markers, 4 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 26.00 s (4 shots) | 24..28 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | C1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | C2 face vessa | PASS 100 | worst u 0.50 v 0.50 at 1.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | C3 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F4 | C4 face shadow_hero | PASS 100 | worst u 0.50 v 0.50 at 0.75 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut C1>C2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut C2>C3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut C3>C4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | C1 line 1 (src 16) | PASS 90 | narrator "Under the roots of the world, a door. An.." 15.3 cps, 5.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | C2 line 1 (src 20) | PASS 92 | vessa "That's it. That's the door. Vey, he's ri.." 14.5 cps, 4.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | C3 line 1 (src 23) | PASS 90 | vey "Four seals. Wake them with the relics an.." 15.5 cps, 6.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | C4 line 1 (src 27) | PASS 90 | malrik "Good evening, Vessa. Mind the statue. It.." 15.4 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | **WARN** 50 | 0 / 4 lines voiced: missing C1 "Under the roots of the w", C2 "That's it. That's the do", C3 "Four seals. Wake them wi", C4 "Good evening, Vessa. Min" | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) | render the lines with Voice Forge (tools/voice_forge) or fix the text so it matches the manifest |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 99dc71e6201fc14b / 99dc71e6201fc14b | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/e2m5_cavern.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (shadow_hero in C1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/e2m5_cavern.cine` (28 lines), 26.0 s, 4 shots, stage: cine-built (props / cast)

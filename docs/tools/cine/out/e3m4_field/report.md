# cine build: e3m4_field

2026-10-07 21:22:47 - `tools/cine/run_cine.ps1 build e3m4_field` - hash `cce23de4d4ae7670` (2 runs identical)

## Result: **WARN** - quality **97 / 100** (previous run 97, +0)

0 FAIL, 1 WARN, 20 PASS, 13 info, 0 skipped, 1 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 37 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 5 actors, 0 markers, 6 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 45.00 s (6 shots) | 43..47 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | F1 face vey | PASS 100 | worst u 0.50 v 0.50 at 5.25 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | F2 face vey | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | F3 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F4 | F4 face malrik | PASS 100 | worst u 0.50 v 0.50 at 0.25 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | F5 face torvald | PASS 100 | worst u 0.50 v 0.50 at 0.50 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | F6 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut F1>F2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut F2>F3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut F3>F4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut F4>F5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut F5>F6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | F1 line 1 (src 17) | PASS 93 | vey "That's enough. My storm is borrowed, and.." 14.3 cps, 4.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | F2 line 1 (src 21) | PASS 100 | vessa "Vey! Get up! We're not done!" 11.2 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | F2 line 2 (src 22) | PASS 96 | vey "We are today, girl. Today the ridge is h.." 13.2 cps, 3.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | F4 line 1 (src 29) | PASS 95 | malrik "The ridge is mine. The valley next. I wi.." 13.8 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | F5 line 1 (src 32) | PASS 100 | torvald "No. I don't think you can." 10.4 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | F6 line 1 (src 36) | PASS 90 | narrator "The ridge fell to Shadow. Torvald had he.." 15.4 cps, 5.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | **WARN** 50 | 0 / 6 lines voiced: missing F1 "That's enough. My storm ", F2 "Vey! Get up! We're not d", F2 "We are today, girl. Toda", F4 "The ridge is mine. The v" | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) | render the lines with Voice Forge (tools/voice_forge) or fix the text so it matches the manifest |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | cce23de4d4ae7670 / cce23de4d4ae7670 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/e3m4_field.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (malrik in F1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/e3m4_field.cine` (37 lines), 45.0 s, 6 shots, stage: cine-built (props / cast)

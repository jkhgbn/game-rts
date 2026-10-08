# cine check: ep3_ending

2026-10-07 21:44:19 - `tools/cine/run_cine.ps1 check ep3_ending` - hash `90044f67aa09c0f0` (2 runs identical)

## Result: **WARN** - quality **97 / 100**

0 FAIL, 1 WARN, 15 PASS, 18 info, 0 skipped, 3 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 59 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 37 actors, 68 markers, 7 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 58.00 s (7 shots) | 56..64 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | B14 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | N05 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F3 | T03 face torvald | PASS 100 | worst u 0.50 v 0.35 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | N07 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F5 | N13 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F6 | N12 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F7 | B14R faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut B14>N05 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut N05>T03 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut T03>N07 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C4 | cut N07>N13 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut N13>N12 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut N12>B14R | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | T03 line 1 (src 33) | PASS 100 | aldra "You heard it." 5.2 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | T03 line 2 (src 35) | PASS 97 | torvald "I heard it ask. I did not hear him say n.." 13.1 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | N07 line 1 (src 41) | PASS 100 | obren "Now the tree." 5.2 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | N13 line 1 (src 48) | PASS 100 | malrik "Tomorrow." 4.1 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | N12 line 1 (src 54) | PASS 99 | malrik "I have heard “stop” all my life." 12.3 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | **WARN** 50 | 1 / 5 lines voiced: missing T03 "You heard it.", T03 "I heard it ask. I did no", N07 "Now the tree.", N13 "Tomorrow." | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) | render the lines with Voice Forge (tools/voice_forge) or fix the text so it matches the manifest |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 90044f67aa09c0f0 / 90044f67aa09c0f0 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | first run |  |  |

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
- source `data/cinematics/src/ep3_ending.cine` (59 lines), 58.0 s, 7 shots, stage: set forge_evenmead

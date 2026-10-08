# cine build: c_e3_knife

2026-10-08 14:00:51 - `tools/cine/run_cine.ps1 build c_e3_knife` - hash `ec90788b5215e715` (2 runs identical)

## Result: **PASS** - quality **99 / 100** (previous run 99, +0)

0 FAIL, 0 WARN, 29 PASS, 16 info, 0 skipped, 3 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 68 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 36 actors, 68 markers, 9 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 68.00 s (9 shots) | 62..74 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | B14 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | K2 face malrik | PASS 100 | worst u 0.50 v 0.36 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | K3 face malrik | PASS 100 | worst u 0.33 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | K3 face hush | PASS 100 | worst u 0.57 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | K4 face hush | PASS 100 | worst u 0.50 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | K5 face tokens | PASS 100 | worst u 0.50 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | K6 face torvald | PASS 98 | worst u 0.50 v 0.70 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | K7 face malrik | PASS 100 | worst u 0.50 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | K8 face hush | PASS 100 | worst u 0.68 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | K8 face malrik | PASS 100 | worst u 0.38 v 0.32 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | N12 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut B14>K2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut K2>K3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut K3>K4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut K4>K5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut K5>K6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut K6>K7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut K7>K8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut K8>N12 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | K2 line 1 (src 29) | PASS 92 | malrik "Ford mud. My father said the same of gra.." 14.7 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | K3 line 1 (src 35) | PASS 100 | malrik "You missed her, at Emberfall." 11.6 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | K3 line 2 (src 36) | PASS 100 | hush "Once." 2.0 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | K4 line 1 (src 39) | PASS 94 | hush "Once is enough to remember, Bishop. Who .." 14.0 cps, 3.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | K5 line 1 (src 43) | PASS 91 | malrik "Not who. What. Four wagons on the south .." 14.9 cps, 4.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | K5 line 2 (src 44) | PASS 100 | malrik "Bring me back their axle pins." 11.8 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | K6 line 1 (src 49) | PASS 96 | torvald "You send a knife at farmers' carts, Malr.." 13.2 cps, 3.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | K7 line 1 (src 53) | PASS 94 | malrik "At an army's supper, Torvald. Hungry sol.." 14.0 cps, 3.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | K8 line 1 (src 56) | PASS 99 | hush "Sleep well, Bishop. Someone won't." 12.3 cps, 2.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 9 / 9 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | ec90788b5215e715 / ec90788b5215e715 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 2f7489a27fee86bc) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c_e3_knife.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (hush in K3 (cine 10, runtime 10 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e3_knife.cine` (68 lines), 68.0 s, 9 shots, stage: set forge_evenmead

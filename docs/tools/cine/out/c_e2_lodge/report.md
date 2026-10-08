# cine build: c_e2_lodge

2026-10-08 01:06:00 - `tools/cine/run_cine.ps1 build c_e2_lodge` - hash `add7a5ba9efb042a` (2 runs identical)

## Result: **PASS** - quality **98 / 100** (previous run 97, +1)

0 FAIL, 0 WARN, 33 PASS, 15 info, 0 skipped, 1 s

## Improve next
1. **L9 face ysolde** (PASS): keep ysolde nearer the band centre in L9 _(from F13 L9 face ysolde, shot L9)_
2. **L4 face ysolde** (PASS): keep ysolde nearer the band centre in L4 _(from F6 L4 face ysolde, shot L4)_
3. **L9 face vey** (PASS): keep vey nearer the band centre in L9 _(from F12 L9 face vey, shot L9)_
4. **L4 face vey** (PASS): keep vey nearer the band centre in L4 _(from F5 L4 face vey, shot L4)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 60 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 4 actors, 56 markers, 9 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 61.50 s (9 shots) | 56..72 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | L1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | L2 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F3 | L3 face vey | PASS 100 | worst u 0.50 v 0.50 at 2.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | L4 face vessa | PASS 100 | worst u 0.50 v 0.36 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | L4 face vey | PASS 94 | worst u 0.83 v 0.46 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | L4 face ysolde | PASS 93 | worst u 0.16 v 0.43 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | L5 face ysolde | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | L6 face vey | PASS 100 | worst u 0.50 v 0.50 at 3.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | L7 face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | L8 face pell | PASS 100 | worst u 0.64 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | L9 face vessa | PASS 100 | worst u 0.50 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | L9 face vey | PASS 94 | worst u 0.83 v 0.52 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | L9 face ysolde | PASS 93 | worst u 0.15 v 0.49 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut L1>L2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut L2>L3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut L3>L4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut L4>L5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut L5>L6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut L6>L7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut L7>L8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut L8>L9 axis | PASS 100 | same side: pell-vessa (on the axis), pell-vey (on the axis), vessa-vey | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | L2 line 1 (src 32) | PASS 97 | vessa "All three of them, pointing at the floor.." 13.0 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | L3 line 1 (src 35) | PASS 93 | vey "Not the floor. Under it. The old Warden .." 14.3 cps, 4.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | L3 line 2 (src 36) | PASS 100 | vey "Nobody living has walked them." 11.8 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | L4 line 1 (src 39) | PASS 100 | vessa "Then we walk in blind." 9.2 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | L4 line 2 (src 40) | PASS 85 | vey "Not quite. The Greywater Lodge has mappe.." 16.9 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | L4 line 3 (src 41) | PASS 93 | vey "They sell that map to nobody." 14.5 cps, 2.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | L5 line 1 (src 43) | PASS 100 | ysolde "They sell everything to somebody." 12.2 cps, 2.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | L6 line 1 (src 45) | PASS 96 | vey "Gold. Six wagons of it, delivered to the.." 13.4 cps, 6.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | L7 line 1 (src 47) | PASS 97 | vessa "Gold? We have crystals. Lots of crystals.." 13.0 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | L8 line 1 (src 58) | PASS 100 | pell "Did somebody say a trade road?" 11.8 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 10 / 10 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | add7a5ba9efb042a / add7a5ba9efb042a | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 360c4a9218de8f1e) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c_e2_lodge.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (vessa in L8 (cine -180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e2_lodge.cine` (60 lines), 61.5 s, 9 shots, stage: set forge_ep2_feast

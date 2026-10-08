# cine check: c_e4_refuge

2026-10-08 10:51:35 - `tools/cine/run_cine.ps1 check c_e4_refuge` - hash `3c9bda4291f2f893` (2 runs identical)

## Result: **PASS** - quality **98 / 100** (previous run 90, +8)

0 FAIL, 0 WARN, 36 PASS, 17 info, 0 skipped, 4 s

## Improve next
1. **R7 face ysolde** (PASS): keep ysolde nearer the band centre in R7 _(from F11 R7 face ysolde, shot R7)_
2. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
3. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 99 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 37 actors, 68 markers, 11 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 70.00 s (11 shots) | 66..76 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | R1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | R2 face wren | PASS 100 | worst u 0.50 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | R3 face vessa | PASS 100 | worst u 0.69 v 0.37 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | R3 face ysolde | PASS 100 | worst u 0.31 v 0.34 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | R4 face vessa | PASS 100 | worst u 0.50 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | R4B face ysolde | PASS 100 | worst u 0.50 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | R5 face maelis | PASS 100 | worst u 0.51 v 0.40 at 4.25 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | R6 face maelis | PASS 100 | worst u 0.70 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | R6 face vessa | PASS 100 | worst u 0.43 v 0.32 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | R6 face ysolde | PASS 97 | worst u 0.29 v 0.29 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | R7 face ysolde | PASS 97 | worst u 0.67 v 0.28 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | R8 face ysolde | PASS 100 | worst u 0.53 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | R9 face vessa | PASS 100 | worst u 0.50 v 0.45 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | R10 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut R1>R2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut R2>R3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut R3>R4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut R4>R4B axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut R4B>R5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut R5>R6 axis | PASS 100 | same side: maelis-vessa (on the axis) | 180-degree rule |  |
| C7 | cut R6>R7 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut R7>R8 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut R8>R9 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C10 | cut R9>R10 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | R1 line 1 (src 39) | PASS 86 | narrator "Night under the golden tree. Every famil.." 16.8 cps, 5.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | R3 line 1 (src 48) | PASS 94 | vessa "Here. Ashby packs bread like he expects .." 14.1 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | R3 line 2 (src 50) | PASS 100 | ysolde "He usually gets one." 11.1 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | R4 line 1 (src 53) | PASS 96 | vessa "You'd have let him have the ford all alo.." 13.4 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | R4B line 1 (src 57) | PASS 100 | ysolde "Fords don't bleed." 10.0 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | R5 line 1 (src 65) | PASS 90 | maelis "The wagons are burning. All of them, on .." 15.3 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | R5 line 2 (src 66) | PASS 97 | maelis "Nobody saw the knife. Nobody ever does." 13.0 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | R6 line 1 (src 72) | PASS 92 | ysolde "Mother Hush. So that's where she went." 14.6 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | R6 line 2 (src 73) | PASS 94 | maelis "No grain, no carts. The valley can't fee.." 14.2 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | R7 line 1 (src 80) | PASS 90 | ysolde "Then they walk. West, through the old wo.." 15.2 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | R8 line 1 (src 85) | PASS 88 | vessa "Through Malrik's hunters? With grandmoth.." 15.9 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | R8 line 2 (src 86) | PASS 100 | ysolde "Slowly. Slow is alive." 9.2 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | R9 line 1 (src 92) | PASS 95 | vessa "Then I'll tell Ashby to leave the gate o.." 13.7 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 13 / 13 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 3c9bda4291f2f893 / 3c9bda4291f2f893 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 8b2b3a3f58ad41f1) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (vessa in R1 (cine 165, runtime 165 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c_e4_refuge.cine` (99 lines), 70.0 s, 11 shots, stage: set forge_evenmead
- the .cine has 99 lines (demo budget <= 80)

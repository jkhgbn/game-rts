# cine check: watch_keep_bugs

2026-09-27 14:03:44 - `tools/cine/run_cine.ps1 check watch_keep_bugs` - hash `c6c459a48e10876a` (2 runs identical)

## Result: **FAIL** - quality **79 / 100** (previous run 79, +0)

4 FAIL, 1 WARN, 17 PASS, 12 info, 2 skipped, 2 s

## Improve next
1. **clip shade draw_knfe (line 33)** (FAIL): did you mean "draw_knife"? _(from R1 clip shade draw_knfe (line 33))_
2. **marker @S8_frm (line 40)** (FAIL): did you mean "@S8_from"? add `mark S8_frm (x, y, z)` or the marker to the set _(from R2 marker @S8_frm (line 40))_
3. **cut S4>S5 axis** (FAIL): keep S5's camera on S4's side of shade-vessa _(from C4 cut S4>S5 axis, shot S5)_
4. **S2 line 1 (src 22)** (FAIL): split it into two lines (two `line` actions) or cut words: <= 96 chars _(from S1 S2 line 1 (src 22), shot S2)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 43 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | clip shade draw_knfe (line 33) | **FAIL** 0 | unknown clip | clip ids = Motion Lab files or the fallback table | did you mean "draw_knife"? |
| R2 | marker @S8_frm (line 40) | **FAIL** 0 | missing (from=) | every @marker exists in the set or a mark line | did you mean "@S8_from"? add `mark S8_frm (x, y, z)` or the marker to the set |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 46.00 s (8 shots) | 45..60 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | S1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | S2 face vessa | PASS 100 | worst u 0.50 v 0.33 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | S3 face shade | PASS 100 | worst u 0.50 v 0.39 at 1.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | S4 face vessa | PASS 100 | worst u 0.50 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | S5 face vessa | PASS 98 | worst u 0.22 v 0.45 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | S5 face shade | PASS 97 | worst u 0.79 v 0.48 at 3.25 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | S6 face shade | PASS 100 | worst u 0.50 v 0.44 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | S7 face vessa | PASS 100 | worst u 0.50 v 0.41 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | S8 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut S1>S2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut S2>S3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut S3>S4 axis | PASS 100 | same side: shade-vessa (on the axis) | 180-degree rule |  |
| C4 | cut S4>S5 axis | **FAIL** 0 | camera crosses the line shade-vessa | 180-degree rule: both shots on the same side of the line between two on-screen actors | S4 and S5 film shade-vessa from opposite sides: move one camera across (keep the side the other shots use), or cut through a neutral / fade shot |
| C5 | cut S5>S6 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut S6>S7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut S7>S8 | SKIP | proxy camera |  |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | S2 line 1 (src 22) | **FAIL** 20 | 120 chars = 3 lines of <= 48: vessa "The watch fires are out, all of them, ev.." 16.0 cps, 7.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot | split it into two lines (two `line` actions) or cut words: <= 96 chars |
| S2 | S4 line 1 (src 29) | PASS 97 | vessa "You are a long way from the dark, shade." 12.9 cps, 3.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | S5 line 1 (src 31) | PASS 100 | shade "The keep sleeps. So should you." 11.9 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | S7 line 1 (src 39) | PASS 100 | vessa "Not tonight." 4.8 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | **WARN** 50 | 3 / 4 lines voiced: missing S2 "The watch fires are out," | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) | render the lines with Voice Forge (tools/voice_forge) or fix the text so it matches the manifest |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | c6c459a48e10876a / c6c459a48e10876a | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was ebbcc563e833d1f1) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | SKIP | no player or FAILs |  |  |

## Notes
- source `data/cinematics/src/watch_keep_bugs.cine` (43 lines), 46.0 s, 8 shots, stage: cine-built (props / cast)

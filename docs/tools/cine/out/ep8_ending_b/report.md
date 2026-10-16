# cine build: ep8_ending_b

2026-10-16 09:42:13 - `tools/cine/run_cine.ps1 build ep8_ending_b` - hash `567ba31748159f52` (2 runs identical)

## Result: **WARN** - quality **99 / 100** (previous run 99, +0)

0 FAIL, 2 WARN, 44 PASS, 23 info, 0 skipped, 19 s

## Improve next
1. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_
2. **Timing sheet** (IDEA): run `sheet` and read timing.png: line bars show CPS colour _(from cine)_
3. **Two-run hash** (IDEA): the hash in the history must stay the same while the .cine is unchanged _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 336 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 74 actors, 116 markers, 17 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 106.40 s (17 shots) | 64..108 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | E15V face vessa | PASS 100 | worst u 0.32 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F2 | E15M face malrik | PASS 100 | worst u 0.44 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | E15T face torvald | PASS 100 | worst u 0.32 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | E15Y face ysolde | PASS 100 | worst u 0.69 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | E15 face vessa | PASS 100 | worst u 0.32 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | E15 face malrik | PASS 100 | worst u 0.44 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | E16 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F8 | E17 face torvald_torvald | PASS 100 | worst u 0.52 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | E18 face ysolde_ysolde | PASS 100 | worst u 0.51 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | E18B face ysolde | PASS 99 | worst u 0.45 v 0.30 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | E19 face malrik | PASS 100 | worst u 0.50 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | E20 face watch_keep_vessa | PASS 100 | worst u 0.50 v 0.53 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | E17L face torvald_torvald | PASS 100 | worst u 0.52 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | E18L face ysolde_ysolde | PASS 100 | worst u 0.51 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F15 | E18BL face ysolde | PASS 99 | worst u 0.45 v 0.30 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F16 | E19L face malrik | PASS 100 | worst u 0.50 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F17 | E21 face dacian | PASS 100 | worst u 0.57 v 0.49 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F18 | E21 face seraphine | PASS 100 | worst u 0.40 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F19 | E22 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut E15V>E15M | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C2 | cut E15M>E15T | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C3 | cut E15T>E15Y | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C4 | cut E15Y>E15 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C5 | cut E15>E16 axis | PASS 100 | same side: malrik-vessa | 180-degree rule |  |
| C6 | cut E16>E17 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C7 | cut E17>E18 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut E18>E18B axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut E18B>E19 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C10 | cut E19>E20 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C11 | cut E20>E17L | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C12 | cut E17L>E18L | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C13 | cut E18L>E18BL axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C14 | cut E18BL>E19L | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C15 | cut E19L>E21 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C16 | cut E21>E22 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | E15V line 1 (src 74) | PASS 100 | vessa "Nobody sits. Not ever again." 10.8 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | E15M line 1 (src 91) | PASS 100 | malrik "Nobody sits. Not ever again." 10.8 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | E15T line 1 (src 108) | PASS 100 | torvald "Nobody sits. Not ever again." 10.8 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | E15Y line 1 (src 125) | PASS 100 | ysolde "Nobody sits. Not ever again." 10.8 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | E15 line 1 (src 153) | PASS 100 | master "Good." 3.1 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | E17 line 1 (src 178) | PASS 100 | master "Torvald opened his gate, and he kept it .." 10.0 cps, 4.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | E18 line 1 (src 194) | PASS 100 | master "Ysolde planted the Hollow with oaks. She.." 11.2 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | E19 line 1 (src 223) | PASS 93 | master "Malrik kept watch over the deep. The dar.." 14.2 cps, 4.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | E19 line 2 (src 225) | PASS 100 | master "It never frightened him." 9.2 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | E20 line 1 (src 237) | PASS 96 | master "Vessa rebuilt my observatory, and taught.." 13.5 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | E20 line 2 (src 240) | PASS 100 | master "Mostly." 4.4 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | E17L line 1 (src 260) | PASS 100 | master "Torvald opened his gate, and he kept it .." 10.0 cps, 4.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | E18L line 1 (src 275) | PASS 100 | master "Ysolde planted the Hollow with oaks. She.." 11.2 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | E19L line 1 (src 303) | PASS 93 | master "Malrik kept watch over the deep. The dar.." 14.2 cps, 4.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S15 | E19L line 2 (src 305) | PASS 100 | master "It never frightened him." 9.2 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S16 | E21 line 1 (src 320) | PASS 100 | master "The two harbour cities fought one more d.." 11.0 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S17 | E22 line 1 (src 336) | PASS 100 | master "And the throne stayed empty. That was th.." 11.0 cps, 6.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 17 / 17 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 567ba31748159f52 / 567ba31748159f52 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | same |  |  |
| B1 | bake | PASS 100 | data/cinematics/ep8_ending_b.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | **WARN** 50 | worst 27.234 m (E15T at 12.00 s) | <= 0.05 m at the middle of every shot | the runtime and cine disagree: note it in docs/handoff/for-systems-coder.md |
| RT2 | runtime actors = cine actors | **WARN** 50 | worst facing 180.0 deg (ysolde in E16 (cine -150, runtime 30 deg)), position 8.820 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot | the runtime turns puppets another way than the game: see docs/handoff/for-systems-coder.md |

## Notes
- source `data/cinematics/src/ep8_ending_b.cine` (336 lines), 106.4 s, 17 shots, stage: set forge_intro_malrik
- the .cine has 336 lines (demo budget <= 80)

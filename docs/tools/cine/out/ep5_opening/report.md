# cine check: ep5_opening

2026-10-08 11:19:51 - `tools/cine/run_cine.ps1 check ep5_opening` - hash `8d1d8d20a7c507bc` (2 runs identical)

## Result: **PASS** - quality **98 / 100** (previous run 97, +2)

0 FAIL, 0 WARN, 68 PASS, 45 info, 0 skipped, 12 s

## Improve next
1. **S08 face vessa** (PASS): keep vessa nearer the band centre in S08 _(from F5 S08 face vessa, shot S08)_
2. **MD1 face l_malrik** (PASS): keep l_malrik nearer the band centre in MD1 _(from F33 MD1 face l_malrik, shot MD1)_
3. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 300 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 65 actors, 156 markers, 32 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 180.00 s (32 shots) | 174..186 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | S01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | S02 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F3 | S06 face master | PASS 99 | worst u 0.50 v 0.70 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | S07 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F5 | S08 face vessa | PASS 95 | worst u 0.50 v 0.74 at 1.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | S09 face malrik | PASS 100 | worst u 0.46 v 0.42 at 1.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | S10 face torvald | PASS 100 | worst u 0.50 v 0.38 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | S11 face ysolde | PASS 100 | worst u 0.50 v 0.48 at 0.50 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | S12 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F10 | S30 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F11 | S13 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F12 | V1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F13 | V2 face watch_keep_vessa | PASS 100 | worst u 0.50 v 0.41 at 9.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | VA1 face vessa_young | PASS 100 | worst u 0.44 v 0.55 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F15 | VA2 face vessa_young | PASS 100 | worst u 0.40 v 0.58 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F16 | VB1 face vessa_young | PASS 100 | worst u 0.42 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F17 | VB1 face vey | PASS 100 | worst u 0.71 v 0.38 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F18 | S15 face vessa | PASS 100 | worst u 0.33 v 0.53 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F19 | S16 face vessa | PASS 100 | worst u 0.48 v 0.54 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F20 | VC2 face vessa | PASS 100 | worst u 0.50 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F21 | VD1 face v12 | PASS 100 | worst u 0.50 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F22 | VD2 face v12 | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F23 | M1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F24 | S21 face malrik | PASS 100 | worst u 0.50 v 0.43 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F25 | S18 face malrik_young | PASS 100 | worst u 0.50 v 0.52 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F26 | MA2 face malrik_young | PASS 100 | worst u 0.50 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F27 | MB1 face malrik_young | PASS 100 | worst u 0.56 v 0.42 at 5.75 s | head inside the 2.39 band safe area (90 %) |  |
| F28 | MB2 face malrik_young | PASS 100 | worst u 0.50 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F29 | MC1 face a_vessa | PASS 100 | worst u 0.65 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F30 | MC1 face a_malrik | PASS 100 | worst u 0.52 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F31 | MC2 face a_vessa | PASS 100 | worst u 0.68 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F32 | MC2 face a_malrik | PASS 100 | worst u 0.38 v 0.35 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F33 | MD1 face l_malrik | PASS 96 | worst u 0.81 v 0.34 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F34 | MD2 face l_malrik | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F35 | T1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut S01>S02 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut S02>S06 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut S06>S07 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut S07>S08 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C5 | cut S08>S09 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut S09>S10 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut S10>S11 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut S11>S12 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut S12>S30 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C10 | cut S30>S13 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C11 | cut S13>V1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C12 | cut V1>V2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C13 | cut V2>VA1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C14 | cut VA1>VA2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C15 | cut VA2>VB1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C16 | cut VB1>S15 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C17 | cut S15>S16 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C18 | cut S16>VC2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C19 | cut VC2>VD1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C20 | cut VD1>VD2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C21 | cut VD2>M1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C22 | cut M1>S21 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C23 | cut S21>S18 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C24 | cut S18>MA2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C25 | cut MA2>MB1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C26 | cut MB1>MB2 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C27 | cut MB2>MC1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C28 | cut MC1>MC2 axis | PASS 100 | same side: a_malrik-a_vessa | 180-degree rule |  |
| C29 | cut MC2>MD1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C30 | cut MD1>MD2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C31 | cut MD2>T1 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | S01 line 1 (src 41) | PASS 96 | master "Once upon a time, the strongest wizard w.." 13.2 cps, 5.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | S02 line 1 (src 44) | PASS 97 | master "They called him only the Master. For a t.." 13.0 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | S06 line 1 (src 48) | PASS 97 | master "He raised four apprentices, and gave eac.." 13.0 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | S07 line 1 (src 52) | PASS 96 | master "Then, between one breath and the next, h.." 13.4 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | S12 line 1 (src 109) | PASS 100 | master "Four heirs. One empty throne." 10.4 cps, 2.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | S30 line 1 (src 118) | PASS 99 | master "I loved all four of them. And still, the.." 12.3 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | S13 line 1 (src 122) | PASS 97 | master "Now winter has stopped their war, child,.." 13.2 cps, 6.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | V2 line 1 (src 138) | PASS 92 | vessa "Vey's. He cut it off his own sword the d.." 14.8 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | V2 line 2 (src 139) | PASS 94 | vessa "But that wasn't the start. The start was.." 14.1 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | VA1 line 1 (src 155) | PASS 93 | vessa "I was six. It was our barn. Nobody clapp.." 14.3 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | VA2 line 1 (src 161) | PASS 99 | master "Smaller, next time. And not the barn." 12.3 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | VA2 line 2 (src 19) | PASS 95 | vessa "Nobody had ever said "next time" to me b.." 13.5 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | VB1 line 1 (src 169) | PASS 100 | vey "Again." 4.3 cps, 1.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | VB1 line 2 (src 172) | PASS 91 | vessa "Vey said fire was the easy part. I was v.." 15.0 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S15 | S15 line 1 (src 185) | PASS 92 | vessa "I never met a wall I couldn't turn into .." 14.7 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S16 | S16 line 1 (src 192) | PASS 100 | vey "Vessa! Wait!" 8.6 cps, 1.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S17 | S16 line 2 (src 193) | PASS 92 | vessa "Everyone always said wait. Nobody ever t.." 14.7 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S18 | VC2 line 1 (src 197) | PASS 93 | vessa "The Master had a saying about fire that .." 14.3 cps, 5.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S19 | VD1 line 1 (src 205) | PASS 100 | master "Again, my joy. Smaller." 10.5 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S20 | VD2 line 1 (src 208) | PASS 94 | vessa "He laughed when I laughed. Nobody else e.." 13.9 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S21 | S21 line 1 (src 228) | PASS 93 | malrik "She tells it with fireworks. Mine needs .." 14.2 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S22 | S18 line 1 (src 237) | PASS 94 | malrik "My father dug the graves. I read them. S.." 14.1 cps, 5.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S23 | MA2 line 1 (src 241) | PASS 94 | malrik "Hello, Tobin Marsh. Nobody visits you ei.." 14.1 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S24 | MB1 line 1 (src 252) | PASS 92 | malrik "The town boys dared me into the crypt fo.." 14.8 cps, 4.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S25 | MB2 line 1 (src 263) | PASS 92 | malrik "I came out at dawn. Bored. The shadows c.." 14.7 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S26 | MC1 line 1 (src 268) | PASS 92 | malrik "In the citadel there was always enough. .." 14.8 cps, 4.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S27 | MC2 line 1 (src 274) | PASS 94 | vessa "Malrik! Where's my bread?" 13.9 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S28 | MC2 line 2 (src 275) | PASS 100 | malrik "What bread?" 7.9 cps, 1.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S29 | MD1 line 1 (src 283) | PASS 94 | vey "He's not afraid of it. Most grown men ar.." 14.0 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S30 | MD1 line 2 (src 286) | PASS 99 | master "I know. That is why it is his." 12.5 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S31 | MD2 line 1 (src 291) | PASS 93 | malrik "He gave me the dark. What was left. He n.." 14.3 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 31 / 31 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 8d1d8d20a7c507bc / 8d1d8d20a7c507bc | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was bdbb67e986cf3a0e) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (tb2 in S01 (cine 230, runtime -130 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep5_opening.cine` (300 lines), 180.0 s, 32 shots, stage: set forge_citadel
- the .cine has 300 lines (demo budget <= 80)

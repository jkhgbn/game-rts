# cine build: ep7_opening

2026-10-08 13:48:25 - `tools/cine/run_cine.ps1 build ep7_opening` - hash `931a7e4223d17bfd` (2 runs identical)

## Result: **WARN** - quality **98 / 100** (previous run 98, +0)

0 FAIL, 1 WARN, 92 PASS, 53 info, 0 skipped, 14 s

## Improve next
1. **D09 face dacian** (PASS): keep dacian nearer the band centre in D09 _(from F13 D09 face dacian, shot D09)_
2. **D10 face dacian** (PASS): keep dacian nearer the band centre in D10 _(from F15 D10 face dacian, shot D10)_
3. **D09 face seraphine** (PASS): keep seraphine nearer the band centre in D09 _(from F14 D09 face seraphine, shot D09)_
4. **P02 face archon_d** (PASS): keep archon_d nearer the band centre in P02 _(from F52 P02 face archon_d, shot P02)_
5. **P02 face archon_g** (PASS): keep archon_g nearer the band centre in P02 _(from F51 P02 face archon_g, shot P02)_
6. **P03 face dacian** (PASS): keep dacian nearer the band centre in P03 _(from F53 P03 face dacian, shot P03)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 351 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 67 actors, 112 markers, 41 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 206.00 s (41 shots) | 200..212 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | D01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | D02 face herald | PASS 100 | worst u 0.46 v 0.56 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | D03 face dacian | PASS 100 | worst u 0.76 v 0.50 at 2.50 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | D04 face seraphine | PASS 99 | worst u 0.76 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | D05 face dacian | PASS 97 | worst u 0.22 v 0.51 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | D05 face seraphine | PASS 99 | worst u 0.77 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | D06 face dacian | PASS 100 | worst u 0.37 v 0.44 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | D06 face seraphine | PASS 100 | worst u 0.54 v 0.48 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | D07 face dacian | PASS 100 | worst u 0.48 v 0.54 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | D08 face dacian | PASS 100 | worst u 0.26 v 0.49 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | D08 face seraphine | PASS 97 | worst u 0.80 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | D08B faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F13 | D09 face dacian | PASS 89 | worst u 0.39 v 0.80 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | D09 face seraphine | PASS 92 | worst u 0.83 v 0.77 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F15 | D10 face dacian | PASS 91 | worst u 0.26 v 0.78 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F16 | D10 face seraphine | PASS 100 | worst u 0.72 v 0.61 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F17 | D11 face dacian | PASS 97 | worst u 0.21 v 0.48 at 3.25 s | head inside the 2.39 band safe area (90 %) |  |
| F18 | D11 face seraphine | PASS 98 | worst u 0.78 v 0.46 at 3.25 s | head inside the 2.39 band safe area (90 %) |  |
| F19 | D12 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F20 | D13 face dacian | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F21 | D14 face dacian | PASS 100 | worst u 0.39 v 0.51 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F22 | D14 face seraphine | PASS 100 | worst u 0.61 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F23 | D15 face dacian | PASS 100 | worst u 0.43 v 0.63 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F24 | D15 face seraphine | PASS 100 | worst u 0.57 v 0.60 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F25 | H01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F26 | H02 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F27 | H03 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F28 | H04 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F29 | H05 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F30 | H06 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F31 | H07 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F32 | H08 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F33 | H09 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F34 | H10 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F35 | H11 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F36 | H12 face hooded | PASS 96 | worst u 0.50 v 0.28 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F37 | H13 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F38 | H14 face hooded | PASS 100 | worst u 0.50 v 0.46 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F39 | H15 face hooded | PASS 100 | worst u 0.50 v 0.44 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F40 | H16 face old_a | PASS 100 | worst u 0.43 v 0.52 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F41 | H16 face old_b | PASS 100 | worst u 0.70 v 0.44 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F42 | H17 face hooded | PASS 100 | worst u 0.50 v 0.41 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F43 | H17B face hooded | PASS 97 | worst u 0.78 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F44 | H18 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F45 | H19 face y_vessa | PASS 100 | worst u 0.43 v 0.42 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F46 | H19 face y_malrik | PASS 100 | worst u 0.59 v 0.38 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F47 | H20 face y_vessa | PASS 100 | worst u 0.26 v 0.48 at 3.00 s | head inside the 2.39 band safe area (90 %) |  |
| F48 | H20 face y_malrik | PASS 100 | worst u 0.63 v 0.36 at 3.00 s | head inside the 2.39 band safe area (90 %) |  |
| F49 | P01 face dacian | PASS 100 | worst u 0.61 v 0.61 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F50 | P01 face seraphine | PASS 100 | worst u 0.75 v 0.54 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F51 | P02 face archon_g | PASS 92 | worst u 0.15 v 0.51 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F52 | P02 face archon_d | PASS 92 | worst u 0.85 v 0.49 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F53 | P03 face dacian | PASS 95 | worst u 0.29 v 0.74 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F54 | P03 face seraphine | PASS 100 | worst u 0.69 v 0.60 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F55 | P04 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut D01>D02 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut D02>D03 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut D03>D04 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut D04>D05 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut D05>D06 axis | PASS 100 | same side: dacian-seraphine | 180-degree rule |  |
| C6 | cut D06>D07 axis | PASS 100 | same side: dacian-seraphine | 180-degree rule |  |
| C7 | cut D07>D08 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut D08>D08B axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut D08B>D09 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C10 | cut D09>D10 axis | PASS 100 | same side: dacian-seraphine | 180-degree rule |  |
| C11 | cut D10>D11 axis | PASS 100 | same side: dacian-seraphine | 180-degree rule |  |
| C12 | cut D11>D12 axis | PASS 100 | same side: dacian-seraphine (on the axis) | 180-degree rule |  |
| C13 | cut D12>D13 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C14 | cut D13>D14 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C15 | cut D14>D15 axis | PASS 100 | same side: dacian-seraphine | 180-degree rule |  |
| C16 | cut D15>H01 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C17 | cut H01>H02 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C18 | cut H02>H03 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C19 | cut H03>H04 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C20 | cut H04>H05 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C21 | cut H05>H06 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C22 | cut H06>H07 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C23 | cut H07>H08 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C24 | cut H08>H09 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C25 | cut H09>H10 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C26 | cut H10>H11 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C27 | cut H11>H12 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C28 | cut H12>H13 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C29 | cut H13>H14 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C30 | cut H14>H15 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C31 | cut H15>H16 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C32 | cut H16>H17 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C33 | cut H17>H17B axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C34 | cut H17B>H18 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C35 | cut H18>H19 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C36 | cut H19>H20 axis | PASS 100 | same side: y_malrik-y_vessa | 180-degree rule |  |
| C37 | cut H20>P01 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C38 | cut P01>P02 axis | PASS 100 | same side: dacian-seraphine | 180-degree rule |  |
| C39 | cut P02>P03 axis | PASS 100 | same side: dacian-seraphine | 180-degree rule |  |
| C40 | cut P03>P04 axis | PASS 100 | same side: dacian-seraphine | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | D02 line 1 (src 68) | PASS 94 | herald "By the Truce of the Stilled Sea: first b.." 13.9 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | D03 line 1 (src 73) | PASS 100 | herald "For Aurivane, the Sunblade: Dacian Orrow.." 12.1 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | D04 line 1 (src 79) | PASS 97 | herald "For Adamarch, the Diamond Wall: Seraphin.." 13.1 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | D05 line 1 (src 87) | PASS 96 | dacian "Nine years I trained for this sand." 13.5 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | D05 line 2 (src 88) | PASS 93 | seraphine "Then don't waste it." 14.3 cps, 1.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | D10 line 1 (src 124) | PASS 100 | dacian "Yield, Diamond Wall." 11.1 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | D10 line 2 (src 125) | PASS 100 | seraphine "Walls don't yield." 11.2 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | D13 line 1 (src 144) | PASS 100 | herald "First blood! Adamarch!" 11.0 cps, 2.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | D14 line 1 (src 150) | PASS 100 | dacian "Well struck." 8.6 cps, 1.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | H01 line 1 (src 166) | PASS 96 | ossavar "They say he kept the peace for a thousan.." 13.2 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | H02 line 1 (src 173) | PASS 99 | ossavar "Two cities on one strait. Aurivane, of g.." 12.2 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | H04 line 1 (src 180) | PASS 98 | ossavar "Only the rich may live inside their wall.." 12.6 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | H05 line 1 (src 195) | PASS 90 | ossavar "Between them, one rock. Who holds it tax.." 15.5 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | H06 line 1 (src 198) | PASS 89 | ossavar "They fought over it for a thousand years.." 15.7 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S15 | H07 line 1 (src 206) | PASS 99 | ossavar "He tried everything. He sent them gold, .." 12.4 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S16 | H08 line 1 (src 215) | PASS 92 | ossavar "They bought more ships. So much gold san.." 14.6 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S17 | H09 line 1 (src 220) | PASS 99 | ossavar "He took us dragons away. They paid us mo.." 12.2 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S18 | H10 line 1 (src 225) | PASS 97 | ossavar "I burned Adamarch for Aurivane, then Aur.." 13.1 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S19 | H11 line 1 (src 235) | PASS 94 | ossavar "The harder he held them, the more they s.." 14.1 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S20 | H12 line 1 (src 241) | PASS 88 | ossavar "He had never stepped into a war in the o.." 16.1 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S21 | H13 line 1 (src 246) | PASS 100 | ossavar "He walked out, and the sea went still." 11.2 cps, 3.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S22 | H14 line 1 (src 249) | PASS 100 | master "Enough." 4.4 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S23 | H15 line 1 (src 254) | PASS 96 | ossavar "Every blade stopped. Every dragon came t.." 13.5 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S24 | H16 line 1 (src 270) | PASS 94 | ossavar "He gave them one duel a year instead of .." 13.9 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S25 | H17 line 1 (src 279) | PASS 92 | ossavar "They bowed to him. Then they bet their c.." 14.6 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S26 | H17B line 1 (src 285) | PASS 92 | ossavar "He left in anger, and never sat there ag.." 14.7 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S27 | H18 line 1 (src 297) | PASS 93 | ossavar "So he stopped holding the world alone, a.." 14.4 cps, 5.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S28 | H19 line 1 (src 302) | PASS 94 | master "Vessa. Malrik. The two harbour cities ar.." 13.8 cps, 5.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S29 | H19 line 2 (src 305) | PASS 86 | vessa "Of course, Master! No problem at all!" 16.8 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S30 | H19 line 3 (src 306) | PASS 99 | malrik "None whatsoever." 12.3 cps, 1.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S31 | H20 line 1 (src 314) | PASS 96 | ossavar "They heard gold, and soldiers, for free." 13.3 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S32 | P01 line 1 (src 329) | PASS 98 | ossavar "Now his chair is empty. And I am home." 12.7 cps, 3.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S33 | P02 line 1 (src 334) | PASS 96 | ossavar "So the old price stands. Whoever pays th.." 13.4 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S34 | P04 line 1 (src 349) | PASS 100 | ossavar "And look who has come to bid." 12.1 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 34 / 34 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 931a7e4223d17bfd / 931a7e4223d17bfd | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 49f1160dc379ae86) |  |  |
| B1 | bake | PASS 100 | data/cinematics/ep7_opening.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | **WARN** 50 | worst facing 33.5 deg (hooded in H17B (cine 25, runtime 59 deg)), position 4.800 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot | the runtime turns puppets another way than the game: see docs/handoff/for-systems-coder.md |

## Notes
- source `data/cinematics/src/ep7_opening.cine` (351 lines), 206.0 s, 41 shots, stage: set forge_intro_vessa
- the .cine has 351 lines (demo budget <= 80)

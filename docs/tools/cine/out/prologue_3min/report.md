# cine check: prologue_3min

2026-09-27 14:47:18 - `tools/cine/run_cine.ps1 check prologue_3min` - hash `a5b60f77ec0d0946` (2 runs identical)

## Result: **WARN** - quality **99 / 100** (previous run 99, +0)

0 FAIL, 1 WARN, 65 PASS, 51 info, 0 skipped, 43 s

## Improve next
1. **S16 face vessa** (PASS): keep vessa nearer the band centre in S16 _(from F18 S16 face vessa, shot S16)_
2. **S15U face scorchbow** (PASS): keep scorchbow nearer the band centre in S15U _(from F17 S15U face scorchbow, shot S15U)_
3. **S08 face vessa** (PASS): keep vessa nearer the band centre in S08 _(from F8 S08 face vessa, shot S08)_
4. **S20 face malrik** (PASS): keep malrik nearer the band centre in S20 _(from F23 S20 face malrik, shot S20)_
5. **S23U face colossus** (PASS): keep colossus nearer the band centre in S23U _(from F27 S23U face colossus, shot S23U)_
6. **S19U face hexweaver** (PASS): keep hexweaver nearer the band centre in S19U _(from F22 S19U face hexweaver, shot S19U)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 385 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 75 actors, 140 markers, 36 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 180.00 s (36 shots) | 170..185 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | S01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | S02 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F3 | S03 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F4 | S04 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F5 | S05 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F6 | S06 face master | PASS 99 | worst u 0.50 v 0.70 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | S07 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F8 | S08 face vessa | PASS 95 | worst u 0.50 v 0.74 at 3.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | S09 face malrik | PASS 100 | worst u 0.46 v 0.42 at 3.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | S10 face torvald | PASS 100 | worst u 0.50 v 0.38 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | S11 face ysolde | PASS 100 | worst u 0.50 v 0.48 at 1.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | S12 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F13 | S13 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F14 | S14 face vessa_young | PASS 100 | worst u 0.50 v 0.46 at 3.25 s | head inside the 2.39 band safe area (90 %) |  |
| F15 | S14B faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F16 | S15 face vessa | PASS 100 | worst u 0.33 v 0.53 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F17 | S15U face scorchbow | PASS 93 | worst u 0.16 v 0.48 at 3.50 s | head inside the 2.39 band safe area (90 %) |  |
| F18 | S16 face vessa | PASS 91 | worst u 0.42 v 0.78 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F19 | S17 face vessa | PASS 100 | worst u 0.50 v 0.54 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F20 | S18 face malrik_young | PASS 100 | worst u 0.50 v 0.52 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F21 | S19 face malrik | PASS 100 | worst u 0.56 v 0.44 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F22 | S19U face hexweaver | PASS 97 | worst u 0.20 v 0.56 at 3.50 s | head inside the 2.39 band safe area (90 %) |  |
| F23 | S20 face malrik | PASS 96 | worst u 0.42 v 0.27 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F24 | S21 face malrik | PASS 100 | worst u 0.50 v 0.43 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F25 | S22 face torvald | PASS 100 | worst u 0.52 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F26 | S23 face torvald | PASS 100 | worst u 0.50 v 0.59 at 2.00 s | head inside the 2.39 band safe area (90 %) |  |
| F27 | S23U face colossus | PASS 96 | worst u 0.20 v 0.59 at 3.50 s | head inside the 2.39 band safe area (90 %) |  |
| F28 | S24 face messenger | PASS 100 | worst u 0.53 v 0.54 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F29 | S25 face torvald | PASS 100 | worst u 0.50 v 0.68 at 2.50 s | head inside the 2.39 band safe area (90 %) |  |
| F30 | S25D faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F31 | S26 face ysolde_young | PASS 100 | worst u 0.45 v 0.35 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F32 | S27 face ysolde | PASS 100 | worst u 0.36 v 0.59 at 1.00 s | head inside the 2.39 band safe area (90 %) |  |
| F33 | S27U face vinelasher | PASS 100 | worst u 0.29 v 0.51 at 3.50 s | head inside the 2.39 band safe area (90 %) |  |
| F34 | S28 messenger | INFO | hidden during the shot |  |  |
| F35 | S29 face ysolde | PASS 100 | worst u 0.50 v 0.33 at 7.00 s | head inside the 2.39 band safe area (90 %) |  |
| F36 | S30 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut S01>S02 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut S02>S03 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut S03>S04 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut S04>S05 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut S05>S06 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut S06>S07 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut S07>S08 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut S08>S09 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut S09>S10 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C10 | cut S10>S11 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C11 | cut S11>S12 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C12 | cut S12>S13 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C13 | cut S13>S14 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C14 | cut S14>S14B axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C15 | cut S14B>S15 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C16 | cut S15>S15U axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C17 | cut S15U>S16 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C18 | cut S16>S17 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C19 | cut S17>S18 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C20 | cut S18>S19 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C21 | cut S19>S19U axis | PASS 100 | same side: hexweaver-malrik | 180-degree rule |  |
| C22 | cut S19U>S20 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C23 | cut S20>S21 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C24 | cut S21>S22 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C25 | cut S22>S23 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C26 | cut S23>S23U axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C27 | cut S23U>S24 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C28 | cut S24>S25 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C29 | cut S25>S25D axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C30 | cut S25D>S26 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C31 | cut S26>S27 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C32 | cut S27>S27U axis | PASS 100 | same side: vinelasher-ysolde | 180-degree rule |  |
| C33 | cut S27U>S28 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C34 | cut S28>S29 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C35 | cut S29>S30 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | S01 line 1 (src 49) | PASS 100 | master "Once upon a time, the strongest wizard o.." 11.8 cps, 5.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | S02 line 1 (src 52) | PASS 100 | master "They called him only the Master. For a t.." 11.2 cps, 6.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | S03 line 1 (src 55) | PASS 100 | master "His citadel rose above the clouds, a cit.." 10.9 cps, 6.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | S04 line 1 (src 58) | PASS 100 | master "Dragons great and small filled its sky, .." 10.8 cps, 6.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | S05 line 1 (src 61) | PASS 100 | master "Kings brought him their quarrels, and we.." 10.5 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | S06 line 1 (src 65) | PASS 100 | master "He raised four apprentices, and gave eac.." 10.7 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | S07 line 1 (src 69) | PASS 100 | master "Then, between one breath and the next, h.." 11.1 cps, 4.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | S08 line 1 (src 90) | PASS 100 | master "Vessa, of Fire." 5.6 cps, 2.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | S09 line 1 (src 102) | PASS 100 | master "Malrik, of Shadow." 6.7 cps, 2.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | S10 line 1 (src 118) | PASS 100 | master "Torvald, of Ice." 5.9 cps, 2.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | S11 line 1 (src 131) | PASS 100 | master "Ysolde, of Nature." 6.7 cps, 2.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | S12 line 1 (src 139) | PASS 100 | master "Four heirs. One empty throne." 10.4 cps, 2.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | S13 line 1 (src 145) | PASS 100 | master "I know this tale well, child. I was that.." 9.4 cps, 5.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | S14 line 1 (src 155) | PASS 100 | master "Vessa, the youngest. She lit her first s.." 11.7 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S15 | S15 line 1 (src 167) | PASS 100 | master "Give her a wall, and she will burn a doo.." 8.0 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S16 | S16 line 1 (src 195) | PASS 100 | master "But she never waits. And fire that will .." 10.5 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S17 | S17 line 1 (src 202) | PASS 100 | master "Still, she laughed like sunrise. Vessa w.." 8.9 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S18 | S18 line 1 (src 212) | PASS 100 | master "Malrik. I found him reading tombstones b.." 11.8 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S19 | S19 line 1 (src 220) | PASS 100 | master "Nothing is hidden from him. The dark its.." 9.7 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S20 | S20 line 1 (src 250) | PASS 100 | master "But he is never full. Whatever he holds,.." 9.8 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S21 | S21 line 1 (src 256) | PASS 100 | master "He thinks I gave him leftovers. I gave t.." 10.7 cps, 7.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S22 | S22 line 1 (src 266) | PASS 100 | master "Torvald, the eldest. Where he stands, th.." 11.2 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S23 | S23 line 1 (src 279) | PASS 100 | master "Nothing breaks him. Not armies, not wint.." 8.2 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S24 | S24 line 1 (src 311) | PASS 100 | master "But he waits too long, and trusts slow i.." 10.2 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S25 | S25 line 1 (src 318) | PASS 100 | master "I left him my coldest secret. Torvald wa.." 9.6 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S26 | S26 line 1 (src 334) | PASS 100 | master "Ysolde. I found her coaxing a sapling th.." 8.5 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S27 | S27 line 1 (src 343) | PASS 100 | master "Burn her forest down, and it grows back..." 10.0 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S28 | S28 line 1 (src 367) | PASS 100 | master "But she will not take a side, not even w.." 10.9 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S29 | S29 line 1 (src 373) | PASS 100 | master "I would say: show me again. And she alwa.." 10.3 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S30 | S30 line 1 (src 379) | PASS 100 | master "I loved all four of them. And still, the.." 9.6 cps, 5.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 30 / 30 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | a5b60f77ec0d0946 / a5b60f77ec0d0946 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 07f793dc3da2a3f2) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | **WARN** 50 | worst facing 10.0 deg (foe in S23U (cine 180, runtime 170 deg)), position 7.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot | the runtime turns puppets another way than the game: see docs/handoff/for-systems-coder.md |

## Notes
- source `data/cinematics/src/prologue_3min.cine` (385 lines), 180.0 s, 36 shots, stage: set forge_citadel
- the .cine has 385 lines (demo budget <= 80)

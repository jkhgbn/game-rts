# cine build: c2_two_fronts

2026-10-08 01:32:38 - `tools/cine/run_cine.ps1 build c2_two_fronts` - hash `64e4979071e9a792` (2 runs identical)

## Result: **PASS** - quality **98 / 100** (previous run 97, +1)

0 FAIL, 0 WARN, 33 PASS, 18 info, 0 skipped, 2 s

## Improve next
1. **S5 face ashby** (PASS): keep ashby nearer the band centre in S5 _(from F6 S5 face ashby, shot S5)_
2. **S6 face vessa** (PASS): keep vessa nearer the band centre in S6 _(from F7 S6 face vessa, shot S6)_
3. **Look at the pictures** (IDEA): run `stills` (windowed) and open stills.png: framing numbers do not judge beauty _(from cine)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 86 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R0 | every name resolves | PASS 100 | 16 actors, 40 markers, 10 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 83.50 s (10 shots) | 74..92 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | S1 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | S2 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F3 | S3 face vessa | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | S4 face ashby | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | S5 face vessa | PASS 98 | worst u 0.41 v 0.30 at 11.75 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | S5 face ashby | PASS 91 | worst u 0.86 v 0.44 at 11.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | S6 face vessa | PASS 93 | worst u 0.48 v 0.25 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F8 | S7 face vessa | PASS 100 | worst u 0.50 v 0.50 at 8.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | S8 face ysolde | PASS 100 | worst u 0.46 v 0.59 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | S8B face ysolde | PASS 100 | worst u 0.50 v 0.50 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | S9 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut S1>S2 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C2 | cut S2>S3 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C3 | cut S3>S4 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut S4>S5 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut S5>S6 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C6 | cut S6>S7 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut S7>S8 | INFO | fade / blend (scene break: the axis may reset) | 180-degree rule applies to cuts |  |
| C8 | cut S8>S8B axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut S8B>S9 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | S1 line 1 (src 31) | PASS 100 | narrator "Two relics. One enemy. One very tired ar.." 11.3 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | S2 line 1 (src 34) | PASS 95 | ashby "Shadow is massing on the Dusk road. Ice .." 13.6 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | S3 line 1 (src 36) | PASS 100 | vessa "So it's me and Malrik." 9.2 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | S4 line 1 (src 38) | PASS 94 | ashby "And whatever he sends in the night, my q.." 14.1 cps, 3.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | S5 line 1 (src 42) | PASS 88 | vessa "His scouts are already in Ysolde's wood..." 15.9 cps, 4.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | S5 line 2 (src 43) | PASS 100 | vessa "I go before he gets it." 11.5 cps, 2.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | S5 line 3 (src 44) | PASS 100 | ashby "Ysolde doesn't take sides." 11.8 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | S5 line 4 (src 45) | PASS 95 | vessa "Then she won't mind. I'll ask nicely." 13.7 cps, 2.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | S5 line 5 (src 46) | PASS 100 | ashby "With fire?" 7.1 cps, 1.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | S5 line 6 (src 47) | PASS 100 | vessa "Nicely. With fire." 9.0 cps, 2.0 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | S6 line 1 (src 57) | PASS 94 | whisper "The third sleeps in the old tree. Bring .." 13.9 cps, 6.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | S7 line 1 (src 62) | PASS 99 | vessa "Who's there? ...Great. Now the jewellery.." 12.4 cps, 6.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | S8B line 1 (src 82) | PASS 100 | ysolde "Not you, Vessa. Not Malrik. Not ever." 10.3 cps, 3.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | S9 line 1 (src 85) | PASS 97 | narrator "The war was coming to the Sighing Wood, .." 13.1 cps, 4.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 14 / 14 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | 64e4979071e9a792 / 64e4979071e9a792 | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was 34d13e3fefb52c1a) |  |  |
| B1 | bake | PASS 100 | data/cinematics/c2_two_fronts.tres | data/cinematics/<id>.tres (CinematicScript) |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (vessa in S1 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/c2_two_fronts.cine` (86 lines), 83.5 s, 10 shots, stage: set forge_watch_keep
- the .cine has 86 lines (demo budget <= 80)

# cine check: ep2_opening

2026-09-27 13:45:23 - `tools/cine/run_cine.ps1 check ep2_opening` - hash `d35684113a4d7b8a` (2 runs identical)

## Result: **WARN** - quality **92 / 100** (previous run 91, +2)

0 FAIL, 5 WARN, 58 PASS, 19 info, 0 skipped, 5 s

## Improve next
1. **set forge_ep2_feast (line 10)** (WARN): build it with World Forge (tool 6); animatic boxes are used meanwhile _(from R1 set forge_ep2_feast (line 10))_
2. **music res://assets/audio/forge/music/ep2_opening.wav (line 49)** (WARN): make it with Sound Forge (tool 9) _(from R2 music res://assets/audio/forge/music/ep2_opening.wav (line 49))_
3. **sfx res://assets/audio/forge/sfx/feast_crowd.wav (line 50)** (WARN): make it with Sound Forge (tool 9) _(from R3 sfx res://assets/audio/forge/sfx/feast_crowd.wav (line 50))_
4. **sfx res://assets/audio/forge/sfx/horn_far.wav (line 91)** (WARN): make it with Sound Forge (tool 9) _(from R4 sfx res://assets/audio/forge/sfx/horn_far.wav (line 91))_
5. **sfx res://assets/audio/forge/sfx/hooves_gallop.wav (line 98)** (WARN): make it with Sound Forge (tool 9) _(from R5 sfx res://assets/audio/forge/sfx/hooves_gallop.wav (line 98))_
6. **S06 face messenger** (PASS): keep messenger nearer the band centre in S06 _(from F8 S06 face messenger, shot S06)_

## Parse (grammar, keys, numbers)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P0 | grammar | PASS 100 | 166 lines, 0 errors | tools/cine/README.md grammar |  |

## Resolve (set, markers, actors, clips, vfx, audio, lines)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| R1 | set forge_ep2_feast (line 10) | **WARN** 50 | not found in res://art/cinematics/stage_sets/forge_ep2_feast | names resolve | build it with World Forge (tool 6); animatic boxes are used meanwhile |
| R2 | music res://assets/audio/forge/music/ep2_opening.wav (line 49) | **WARN** 50 | missing file res://assets/audio/forge/music/ep2_opening.wav | audio paths exist | make it with Sound Forge (tool 9) |
| R3 | sfx res://assets/audio/forge/sfx/feast_crowd.wav (line 50) | **WARN** 50 | missing file res://assets/audio/forge/sfx/feast_crowd.wav | audio paths exist | make it with Sound Forge (tool 9) |
| R4 | sfx res://assets/audio/forge/sfx/horn_far.wav (line 91) | **WARN** 50 | missing file res://assets/audio/forge/sfx/horn_far.wav | audio paths exist | make it with Sound Forge (tool 9) |
| R5 | sfx res://assets/audio/forge/sfx/hooves_gallop.wav (line 98) | **WARN** 50 | missing file res://assets/audio/forge/sfx/hooves_gallop.wav | audio paths exist | make it with Sound Forge (tool 9) |
| R0 | every name resolves | PASS 100 | 13 actors, 0 markers, 14 shots | sets, markers, actors, clips, vfx, audio exist |  |

## Timing
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| TM1 | total length | PASS 100 | 72.00 s (14 shots) | 66..76 s |  |
| TM2 | shot lengths | PASS 100 | all >= 1.0 s | >= 1.0 s (shorter reads as a flash cut) |  |
| TM3 | fade lengths | PASS 100 | fit | a fade fits in its shots |  |

## Framing (faces in the 2.39 band, 16:9 frame)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | S01 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F2 | S02 face vessa | PASS 100 | worst u 0.37 v 0.32 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F3 | S02 face dancer | PASS 100 | worst u 0.70 v 0.37 at 5.00 s | head inside the 2.39 band safe area (90 %) |  |
| F4 | S03 face vessa | PASS 97 | worst u 0.22 v 0.57 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F5 | S03 face vey | PASS 100 | worst u 0.64 v 0.43 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F6 | S04 face ashby | PASS 100 | worst u 0.50 v 0.36 at 4.00 s | head inside the 2.39 band safe area (90 %) |  |
| F7 | S05 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |
| F8 | S06 face messenger | PASS 85 | worst u 0.05 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F9 | S06 face vessa | PASS 100 | worst u 0.72 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F10 | S07 face messenger | PASS 100 | worst u 0.50 v 0.45 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F11 | S08 face messenger | PASS 99 | worst u 0.61 v 0.30 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F12 | S08 face vessa | PASS 100 | worst u 0.34 v 0.36 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F13 | S09 face vessa | PASS 100 | worst u 0.50 v 0.44 at 4.50 s | head inside the 2.39 band safe area (90 %) |  |
| F14 | S10 face messenger | PASS 100 | worst u 0.65 v 0.47 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F15 | S10 face vessa | PASS 90 | worst u 0.27 v 0.21 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F16 | S11 face vessa | PASS 100 | worst u 0.50 v 0.31 at 6.00 s | head inside the 2.39 band safe area (90 %) |  |
| F17 | S12 face vessa | PASS 100 | worst u 0.67 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F18 | S12 face vey | PASS 97 | worst u 0.21 v 0.40 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F19 | S13 face ashby | PASS 100 | worst u 0.50 v 0.37 at 0.00 s | head inside the 2.39 band safe area (90 %) |  |
| F20 | S14 faces | INFO | no named face | shots that show a face name it (look / pivot / frame / faces=) |  |

## Continuity (180-degree rule, jump cuts)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | cut S01>S02 axis | PASS 100 | same side: dancer-vessa (on the axis) | 180-degree rule |  |
| C2 | cut S02>S03 axis | PASS 100 | same side: dancer-vessa (on the axis), dancer-vey (on the axis), vessa-vey | 180-degree rule |  |
| C3 | cut S03>S04 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C4 | cut S04>S05 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C5 | cut S05>S06 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C6 | cut S06>S07 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C7 | cut S07>S08 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C8 | cut S08>S09 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C9 | cut S09>S10 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C10 | cut S10>S11 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C11 | cut S11>S12 axis | PASS 100 | same side: vessa-vey | 180-degree rule |  |
| C12 | cut S12>S13 axis | INFO | no pair on screen in both shots | 180-degree rule |  |
| C13 | cut S13>S14 axis | INFO | no pair on screen in both shots | 180-degree rule |  |

## Subtitles (2 x 48 chars, CPS, fit)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| S1 | S01 line 1 (src 56) | PASS 100 | reveler "To Vessa! To the Ember Queen!" 7.6 cps, 3.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S2 | S02 line 1 (src 62) | PASS 88 | dancer "Come on, my queen! One dance!" 16.1 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S3 | S02 line 2 (src 64) | PASS 92 | vessa "One dance. Then I'm eating everything." 14.6 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S4 | S03 line 1 (src 78) | PASS 95 | vessa "Vey! Get up and dance!" 13.8 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S5 | S03 line 2 (src 80) | PASS 100 | vey "I felled a mountain yesterday, girl. I'l.." 11.5 cps, 4.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S6 | S04 line 1 (src 86) | PASS 100 | ashby "Three relics! One Colossus! Drink!" 9.2 cps, 3.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S7 | S05 line 1 (src 99) | PASS 100 | ashby "Rider at the gate! Make way!" 10.8 cps, 2.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S8 | S06 line 1 (src 109) | PASS 100 | messenger "My... my lady?" 8.2 cps, 1.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S9 | S06 line 2 (src 111) | PASS 92 | messenger "The Ember Queen? Which one is..." 14.5 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S10 | S06 line 3 (src 114) | PASS 90 | vessa "Me. Breathe. Who sent you?" 15.3 cps, 1.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S11 | S07 line 1 (src 117) | PASS 100 | messenger "Lady Ysolde." 7.1 cps, 1.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S12 | S07 line 2 (src 118) | PASS 98 | messenger "The wood... Shadow came." 12.6 cps, 1.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S13 | S07 line 3 (src 119) | PASS 100 | messenger "And Ice. Together." 11.2 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S14 | S08 line 1 (src 123) | PASS 99 | messenger "The army... it's gone." 12.2 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S15 | S08 line 2 (src 125) | PASS 100 | messenger "All of it. I saw it burn." 11.9 cps, 2.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S16 | S08 line 3 (src 126) | PASS 93 | messenger "And then... then it froze." 14.4 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S17 | S09 line 1 (src 131) | PASS 100 | vey "So Torvald chose a side." 9.6 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S18 | S09 line 2 (src 132) | PASS 100 | vessa "Malrik's side." 9.3 cps, 1.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S19 | S10 line 1 (src 135) | PASS 100 | messenger "She said you'd laugh." 11.7 cps, 1.8 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S20 | S10 line 2 (src 136) | PASS 90 | messenger "She said... remember. She warned you." 15.4 cps, 2.4 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S21 | S10 line 3 (src 138) | PASS 100 | vessa "I'm not laughing." 11.3 cps, 1.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S22 | S11 line 1 (src 142) | PASS 88 | vessa "I know you're tired. I know we just won." 16.0 cps, 2.5 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S23 | S11 line 2 (src 143) | PASS 85 | vessa "But her people have no one else. I need .." 17.0 cps, 3.3 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S24 | S12 line 1 (src 146) | PASS 100 | vessa "Vey. Ride with me?" 11.2 cps, 1.6 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S25 | S12 line 2 (src 148) | PASS 99 | vey "The spark first, girl. Then the storm." 12.3 cps, 3.1 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S26 | S13 line 1 (src 152) | PASS 88 | ashby "Emberguard! Boots on! We march at first .." 15.9 cps, 2.9 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S27 | S14 line 1 (src 157) | PASS 95 | messenger "Thank you... thank you." 13.5 cps, 1.7 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| S28 | S14 line 2 (src 158) | PASS 92 | vessa "Hold on, Ysolde. Fire is coming." 14.5 cps, 2.2 s | <= 2 x 48 chars, <= 17 cps (max 22), fits the shot |  |
| V1 | voice files | PASS 100 | 28 / 28 lines voiced | every line has a WAV (data/voice/manifest.json, speaker + text, or voice=) |  |
| V2 | voice fits its slot | PASS 100 | all fit | the WAV ends before the next line starts |  |

## Determinism
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | 2 fresh runs (bake + 3600 frames at 60 fps) | PASS 100 | d35684113a4d7b8a / d35684113a4d7b8a | same spec + seed = same bytes |  |
| D2 | vs previous run | INFO | changed (was cbffc4d6c5f87d27) |  |  |

## Partner tools
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| T1 | tool 1 resources (bake .tres) | INFO | present | optional at bake time |  |
| T2 | tool 1 CinematicPlayer (play / record) | INFO | present | optional at bake time |  |
| T3 | tool 3 Lens | INFO | present | optional at bake time |  |
| T4 | tool 5 Motion Lab | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| T5 | tool 7 VFX Composer | INFO | missing (cine degrades: WARN + proxy when used) | optional at bake time |  |
| RT1 | runtime camera = cine camera | PASS 100 | worst 0.000 m | <= 0.05 m at the middle of every shot |  |
| RT2 | runtime actors = cine actors | PASS 100 | worst facing 0.0 deg (d3 in S01 (cine 180, runtime -180 deg)), position 0.000 m | same facing (+Z = model front, as unit.gd) and position at the middle of every shot |  |

## Notes
- source `data/cinematics/src/ep2_opening.cine` (166 lines), 72.0 s, 14 shots, stage: cine-built (props / cast)
- the .cine has 166 lines (demo budget <= 80)

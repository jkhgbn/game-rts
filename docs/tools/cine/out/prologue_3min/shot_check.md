# prologue_3min: shot-by-shot check (P5 assembly, 2026-09-27)

Source `data/cinematics/src/prologue_3min.cine` (36 shots, 180.0 s, 30 narration lines). Stills:
`docs/tools/cine/out/prologue_3min/stills/<shot>_<a|b|c>_1600.png` + `stills.png`; timing sheet `timing.png`.
`cine check prologue_3min`: **0 FAIL**, 1 WARN (RT2: the tool 1 runtime player's `seek()` does not replay `move` end
states from earlier shots; does not affect `record`, which uses cine's own player). Voices: 30 / 30 lines have their WAV
(V1 PASS), every WAV ends before the next line (V2 PASS).

Sets: forge_citadel (S01-S07, S12, S13, S30), forge_intro_vessa / malrik / torvald / ysolde (S08-S11, S14-S29) - all
built and wired (camera = the sets' marks by shot id, except S14B and S25 which have cine cameras). The set agents kept
polishing sets during this check, so late stills may look better than the grades below.

## Grade rubric (per shot, 0-100)
| Criterion | Points | What earns it |
|---|---|---|
| Subject reads + framing | 20 | the subject is clear, inside the 2.39 band, nothing blocks it |
| Matches the narration line | 20 | the picture shows what the Master says at that moment |
| Depth / layers | 15 | foreground, middle, background |
| Motion in frame | 15 | camera move, flock, units acting, effects |
| Epic moment / spectacle | 15 | big spell, heroic pose, army, dragons |
| Light and colour mood | 15 | readable light, the kingdom's colour, no wash-out / blow-out |

Film grade = duration-weighted mean. **Baseline 13:15: 68.5 (minute 1: 70.5). Round 2 (14:00): 72.3 (74.0). Round 3 FINAL (14:55, polished sets + their toggle actors wired): 76.4 (minute 1: 77.4).** Grades in the table = round 3.

## Shots
| Shot | Time | Line | What we see (stills b / c) | Grade | Status / fix |
|---|---|---|---|---|---|
| S01 | 0:00 | Once upon a time, the strongest wizard of all time ruled the world. | crane down through the cloud banks; the citadel appears, dragons rise off the spires (flock arrives 0-6 s) | 80 | PASS. Set haze washes the colour (set lighting) |
| S02 | 0:07 | They called him only the Master. For a thousand years... | the colossal mossy hooded statue on the Great Bridge, banners, dragons | 79 | PASS |
| S03 | 0:14 | His citadel rose above the clouds, a city of towers, bridges and bells. | hero wide: towers, dome, waterfalls, dragons, far flock | 84 | PASS |
| S04 | 0:21 | Dragons great and small filled its sky... | dolly past the great tower through a dense close flock (hero frost + cinder dragons, flights) | 74 | PASS (added `sky_s04` flock; was 58) |
| S05 | 0:28 | Kings brought him their quarrels, and went home as friends. | crane into the market terrace: stalls, crowd, the long table | 72 | PASS weak: kings not distinct (set) |
| S06 | 0:34 | He raised four apprentices, and gave each of them a kingdom. | behind the Master at the orrery; four coloured flames orbit beside him | 74 | PASS |
| S07 | 0:40 | Then, between one breath and the next, he was gone. | low angle on the orrery; regalia burst, four streaks shoot out through the dome; white fade | 70 | PASS (burst scaled down after the AVI test) |
| S08 | 0:45 | Vessa, of Fire. | red streak lands; Vessa casts, a fire pillar erupts behind her; army + cinder dragon | 86 | PASS |
| S09 | 0:48 | Malrik, of Shadow. | violet streak; shadow wave; shades and the Nightmare Knight stand up behind him | 82 | PASS |
| S10 | 0:51 | Torvald, of Ice. | blue streak; crane down; freeze wave across the lake, ice burst; his army | 80 | PASS |
| S11 | 0:54 | Ysolde, of Nature. | green streak; crane down; bloom wave + green pillar; Treant, stag | 76 | PASS |
| S12 | 0:57 | Four heirs. One empty throne. | top-down on the empty throne; four coloured streaks cross above it; dragons leave (57 s) | 79 | PASS |
| S13 | 1:00 | I know this tale well, child. I was that wizard. | years later: the ruined dome, one candle, darkened (fade 0.35), four tiny flames relight | 76 | PASS |
| S14 | 1:06 | Vessa, the youngest. She lit her first spark... | young Vessa, a spark rises from her hands | 72 | PASS |
| S14B | 1:09 | (line continues) | low heroic angle: grown Vessa hurls a house-sized fireball into the sky, cinder dragon | 82 | PASS |
| S15 | 1:13 | Give her a wall, and she will burn a door through it. | Vessa before the burnt gate, her army behind | 82 | PASS |
| S15U | 1:16 | (line continues) | the army pours through: Blaze Rider charges past the lens, Scorchbows loose, Musketeer fires, Pyre Adept fire column | 80 | PASS |
| S16 | 1:20 | But she never waits. And fire that will not wait burns its own house. | high wide: Vessa far ahead alone; fire pillars run wild by the wall behind her | 86 | PASS |
| S17 | 1:27 | Still, she laughed like sunrise. Vessa was my joy. | close-up among sparks (level-up sparkle), an ember drifts up | 70 | PASS (tight CU, top of hat cut) |
| S18 | 1:33 | Malrik. I found him reading tombstones by the light of one candle. | young Malrik among the standing stones; a tall hooded shadow walks up behind him | 76 | PASS |
| S19 | 1:39 | Nothing is hidden from him. The dark itself comes when he calls. | Malrik casts; shadow wave; hounds and Bleakbow appear, Nightmare Knight behind | 84 | PASS |
| S19U | 1:42 | (line continues) | Hexweaver, Shadow Knight, hounds charge; Umbral Shroud dome swallows the hall | 84 | PASS |
| S20 | 1:46 | But he is never full. Whatever he holds, he wants more. | over the trophy chest, army gone; a gold glint as he takes one more | 68 | PASS weak (no crown / letters props) |
| S21 | 1:52 | He thinks I gave him leftovers... | close-up, calm, glowing eyes; fades toward dark | 66 | PASS weak (candle pinch not staged) |
| S22 | 2:00 | Torvald, the eldest. Where he stands, the ice holds... | crane down over the lake: fire foes charge, Rimeshield wall, Frostbow / Rifleman fire, freeze wave | 84 | PASS |
| S23 | 2:07 | Nothing breaks him. Not armies, not winters. Not time. | arc around Torvald casting; ice burst | 76 | PASS (shield wall hidden: it blocked the orbit, was 57) |
| S23U | 2:10 | (line continues) | Rime Colossus, War Mammoth, Frostbow, Rifleman act; freeze wave | 78 | PASS |
| S24 | 2:14 | But he waits too long, and trusts slow ice more than quick friends. | over his shoulder: the messenger begs; snow covers the signal fire; he turns away | 68 | PASS weak (staff crosses frame after the turn) |
| S25 | 2:21 | I left him my coldest secret. Torvald was my patience. | CU on Torvald (2.6 s) | 68 | PASS |
| S25D | 2:24 | (line continues) | over his shoulder, tilt down through the clear ice: the Heartfrost glows far below (set mark S25D, fx_heart) | 76 | PASS (glow a little faint) |
| S26 | 2:27 | Ysolde. I found her coaxing a sapling through the frost. | young Ysolde in the snowy clearing, bloom ring; the tall hooded man beside her | 78 | PASS |
| S27 | 2:34 | Burn her forest down, and it grows back... | Ysolde casts Wild Bloom (green wave), the Treant | 78 | PASS |
| S27U | 2:37 | (line continues) | Wildwood Archers step out in pairs, Vinelashers whip, the stag charges, Treant attacks | 82 | PASS |
| S28 | 2:41 | But she will not take a side, not even while the world burns. | from behind her: the messenger at the root-closed road, smoke on the horizon, roots grow | 70 | PASS |
| S29 | 2:47 | I would say: show me again... Ysolde was my heart. | CU, a pink blossom glow opens before her | 72 | PASS |
| S30 | 2:54 | I loved all four of them. And still, they went to war. | crane up and out over the citadel; fade; title FOUR WIZARDS / Episode 1 | 76 | PASS (haze; the four army fires are small) |

## Round 3 wiring (set polish, 14:40-14:55)
The sets' toggle actors are shown / hidden per shot in the .cine: Vessa fx_pillar (S08), army_host + fx_columns (S15-S17), fx_volley (S15U), army_fallen + fx_embers (S16); Malrik fx_vortex (S09, S19), fx_master (S18), army_host + fx_tendrils (S19/S19U), fx_crown (S20); Torvald army_line / army_charge / fx_icewall / fx_cracks (S10, S22, S23U), fx_burst + fx_snow (S23-S24), fx_heart (S25D, new shot: S25 split 2.6 + 3.4 s); Ysolde fx_vines (S11, S27/S27U), fx_tree (S27U), fx_master (S26). My own duplicates (hooded figure casts, S08 pillar) were removed. Known: Vessa's fire columns bloom hot in S15U; the Master is a plain silhouette.

## Minute status
- Minute 1 (S01-S13, 0:00-1:06): solid; every shot has its set, marks, dragons, voice and the segue streaks.
- Minute 2 (S14-S21) and 3 (S22-S30): complete (sets, armies, spells, voices); weakest beats are the quiet weakness /
  love shots (S20, S21, S24, S25, S28): the story props (letters, crown, Heartfrost) are not built.

## Record
`.\tools\cine\run_cine.ps1 record prologue_3min fps=30` -> `%USERPROFILE%\Videos\four-wizards-rec\prologue_3min\prologue_3min.avi`
(or `movie=<path>.avi`). MJPEG 1600x900 with the 2.39 bars drawn + PCM 48 kHz stereo (narration + music at -21 dB).
Tested: 5 s from 0 s (167 frames, 11.9 MB) and 8 s from 40 s (242 frames, 19.3 MB; frames checked: subtitles in the
lower bar, voice present). Godot 4.7 Movie Maker ignores `--resolution` for the AVI size (1920x804 gave a stretched
1600x900 file), so `res=1920x804` applies only to `format=png`.

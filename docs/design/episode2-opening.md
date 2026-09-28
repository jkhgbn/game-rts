# Episode 2 opening (1:12): "The Feast and the Runner" - script, shot list, build list

Owner: story designer / cinematic writer. Written 2026-09-27. Status: **script draft for JS to judge by ear; visuals to
build.** Data: `data/cinematics/src/ep2_opening.cine` (self-staged draft, `cine check` 0 FAIL, 5 WARN = the set and the
Sound Forge cues not built yet), `data/voice/lines/ep2_opening.json` (28 voiced lines), listening mix (voices at their
movie times, no music) `C:\Users\elzzo\Documents\four-wizards-voice\out\ep2_opening.wav` (72.0 s, made by
`four-wizards-voice\listen_ep2_opening.py`).

User request (JS, 2026-09-27, verbatim): "script for episode 2 start party after then win 20 sec of happy and dance then
20 sec in a messenger that the allies army was destroyed tell the news and the last 30 is the wizard getting to know and
ask for help for then episode 2 battle".
Voice direction (JS, relayed): the messenger is "very scared and young and stumbling".

## 0. Reading and decisions
| Question | Decision | Why |
|---|---|---|
| Where it sits | Episode 2 "The Light Below" opens the **night after Episode 1's win** (M4 + `ep1_ending`): the Fire army feasts in the Emberfall watch-keep courtyard, where the war began (M0) | `story-episode-1.md` 10: "Episode 2 opens ... on the win"; the watch-keep is home, and M0's night of knives becomes a night of dancing |
| Who stars | **Vessa** (Fire), with **Old Vey** (her helper, back from the deep) and **Captain Ashby** | Vessa starred in Ep1 and in `mission-02`; ep1 10: "Vessa goes to her aid" |
| "The allies' army was destroyed" | **Ysolde's army**: Shadow **and Ice** struck the Sighing Wood together; the army burned, then froze | ep1 10 (Ice joins Shadow, Ysolde's army destroyed first, the wood "burns and freezes"); `ep4_opening` L8 already says "they burned my wood and froze the ashes. My army with it" |
| The messenger | **Wren**, a runner of the Sighing Wood (girl of about fifteen), on a Grove Stag; speaker `messenger` | New minor character; Nature's people are British, so a young British voice |
| "The wizard getting to know and ask for help" | Vessa takes the news in (Vey names it: Torvald chose Malrik), receives Ysolde's message ("remember, she warned you": her Ep1 line to Vessa), then **asks her tired army, and Vey, to march with her**. Vey answers with his motto; Ashby calls the march | The 2v1 turn of ep1 10; the call for help is Vessa's, the plea is Ysolde's (through Wren) |
| The battle it leads into | **Episode 2 mission 1 = "The Burning Grove"** (rescue Ysolde, hold her last Heartwood; ep1 10 mission idea 2). "Sunrise Road" (the descent) moves later | JS: "for then episode 2 battle": the opening must end at the march. Question 1 below |
| Dialogue or narrator | **Scene dialogue** (characters speak, no narrator) | The prologue is the Master's narration; Episode openings 3-4 are monologues; this one is a scene |
| Humour | Party beats keep Vessa's and Vey's humour (ep1 U3), then it drops out completely from the rider on | Tone: hope, then the hard news, then resolve |

## 1. The script (28 lines, 72 s; times = movie seconds)
```
0:00-0:20  THE FEAST
[0:01] REVELER    To Vessa! To the Ember Queen!
[0:05] DANCER     Come on, my queen! One dance!
[0:07] VESSA      One dance. Then I'm eating everything.
[0:10] VESSA      Vey! Get up and dance!
[0:12] VEY        I felled a mountain yesterday, girl. I'll clap.
[0:16] ASHBY      Three relics! One Colossus! Drink!
0:20-0:40  THE RUNNER
[0:20] ASHBY      Rider at the gate! Make way!
[0:23] WREN       My... my lady?
[0:25] WREN       The Ember Queen? Which one is...
[0:27] VESSA      Me. Breathe. Who sent you?
[0:29] WREN       Lady Ysolde.
[0:31] WREN       The wood... Shadow came.
[0:33] WREN       And Ice. Together.
[0:35] WREN       The army... it's gone.
[0:37] WREN       All of it. I saw it burn.
[0:39] WREN       And then... then it froze.
0:40-1:12  THE CALL
[0:41] VEY        So Torvald chose a side.
[0:43] VESSA      Malrik's side.
[0:45] WREN       She said you'd laugh.
[0:47] WREN       She said... remember. She warned you.
[0:49] VESSA      I'm not laughing.
[0:51] VESSA      I know you're tired. I know we just won.
[0:54] VESSA      But her people have no one else. I need you. All of you.
[0:57] VESSA      Vey. Ride with me?
[0:59] VEY        The spark first, girl. Then the storm.
[1:02] ASHBY      Emberguard! Boots on! We march at first light!
[1:05] WREN       Thank you... thank you.
[1:07] VESSA      Hold on, Ysolde. Fire is coming.
[1:09] Title: Episode 2 · The Light Below   (fade to black 1:11-1:12, then "The Burning Grove")
```
Wren's stumbles are **written into the spoken text** (Kokoro cannot act): repeats, broken starts, ellipses, and her news
cut into short lines with 0.4-0.6 s gaps, so the gaps play as gasps. Subtitles use the clean reading (`subtitle` field
in the lines file: "My lady?", "She said: remember, she warned you.", "Thank you. Thank you."). Every subtitle is
<= 2 x 48 characters and <= 17 characters / s (`cine check` S rules pass).
Echoes: "remember, she warned you" = Ysolde's Ep1 refusal ("when your war comes for my wood, remember I warned you");
"The spark first, then the storm" = Vey's motto (V1, M1, V4); "Fire is coming" answers Ysolde's "it grows back" (ep1 10).

## 2. Shot list (14 shots, 72 s, letterbox 2.39; one "what we see" per line)
Axis: Vessa - Wren runs north-south (x = 2.8, the gate to the north); every camera of the talk (S06-S13) stays on its
east side. Party shots S01-S04 are cut to keep each pair (Vessa-dancer, Vessa-Vey, Vessa-Ashby) on one side.
| Shot | Time | Camera | What we see | Lines |
|---|---|---|---|---|
| S01 | 0:00-0:05 | FADE_BLACK in; CRANE down over the lantern strings, fov 50 -> 44 | Night. The Emberfall watch-keep courtyard: warm lantern strings between posts, a big bonfire in a brazier, long tables with food and mugs, Fire banners; a ring of 5 soldiers (Flame Guards, Ember Archers, a Cinder Hand) dances around the fire, stepping one place round, hopping | Reveler: To Vessa! |
| S02 | 0:05-0:10 | MS two-shot Vessa + the archer, 3/4, eye, push | An Ember Archer grabs Vessa's hands; they spin as a pair (turns + hops) beside the ring; Vessa laughs, crown on her head | Dancer; Vessa: One dance... |
| S03 | 0:10-0:16 | DOLLY high from the north-east across the fire to the west table | The ring steps round again. Vessa, mid-spin, points at Old Vey sitting at the west table; he claps, badly off the beat (sword-arm swings) | Vessa: Vey! / Vey: I felled a mountain... |
| S04 | 0:16-0:20 | MS on Ashby, 3/4, low | Ashby on the east table, mug raised; behind him Vessa throws a fireball straight up and it bursts into sparks over the lanterns; everyone cheers. At 0:19 a far horn: heads turn | Ashby: Three relics! |
| S05 | 0:20-0:23 | STATIC low at the gate, looking north into the dark | Out of the dark a Grove Stag rider bursts through the gate at full gallop; the lanterns swing; two dancers jump aside; **the music cuts** | Ashby: Rider at the gate! |
| S06 | 0:23-0:29 | MS two-shot Wren + Vessa, 3/4, eye | The rider slides off the panting stag: a girl, scorched green cloak, ash on her face. She stumbles twice (hit flinch), looks from face to face; Vessa pushes through the crowd to her | Wren: My... my lady? / The Ember Queen? / Vessa: Me. Breathe. |
| S07 | 0:29-0:34.5 | CU on Wren, 3/4, eye | Wren shaking, eyes wet, the lantern light on the ash; she flinches on "Together" | Wren: Lady Ysolde. / The wood... / And Ice. |
| S08 | 0:34.5-0:40.5 | MLS two-shot, 3/4, high | Wider: the whole courtyard has gone silent around them; dancers frozen mid-step, mugs lowered. Vey gets up and walks to Vessa's side | Wren: The army... / All of it. / And then... it froze. |
| S09 | 0:40.5-0:45 | CU on Vessa, 3/4, eye, slow push | Firelight on Vessa's face; the joy drains out of it; Vey behind her shoulder, grave | Vey: So Torvald chose a side. / Vessa: Malrik's side. |
| S10 | 0:45-0:51 | MS two-shot, 3/4, low | Wren holds out Ysolde's token (a seed-pod on a cord); Vessa kneels and takes it in both hands | Wren: She said you'd laugh... / Vessa: I'm not laughing. |
| S11 | 0:51-0:57 | MLS on Vessa, front, low, push | Vessa stands and turns to her army: lantern-lit faces, silent, tired, still in feast clothes | Vessa: I know you're tired... I need you. All of you. |
| S12 | 0:57-1:02 | MS two-shot Vessa + Vey, 3/4, eye | Vessa turns to Vey. He stands, one hand on his sword; a spark of white-gold lightning runs down the blade | Vessa: Vey. Ride with me? / Vey: The spark first... |
| S13 | 1:02-1:05 | MS on Ashby, 3/4, low | Ashby jumps off the table and throws his mug aside; soldiers grab spears and helmets | Ashby: Emberguard! Boots on! |
| S14 | 1:05-1:12 | CRANE up and out to the north, fov 40 -> 48 | Lanterns come down, torches go up, the soldiers form ranks at the gate; Wren beside Vessa, the stag behind. Far north, a red-and-blue glow on the horizon (the wood burning and freezing). Title card, fade to black | Wren: Thank you... / Vessa: Hold on, Ysolde. Fire is coming. |

## 3. What must be built
| # | Item | Owner | Notes |
|---|---|---|---|
| B1 | World Forge set **`forge_ep2_feast`**: the Emberfall watch-keep courtyard at night (reuse `forge_watch_keep`'s keep, walls and gate), dressed for a feast | set agent (four-wizards-high) | Bonfire in a big brazier (emission), 4+ lantern posts + lantern strings, 2 long feast tables with food / mugs / a barrel, Fire banners, the north gate with lanterns, a dark road beyond it; a faint red-and-blue horizon glow to the north (S14). Reuse `forge_citadel/parts/` (`feast_table`, `lantern_post`, `lantern_string`, `brazier_tall`, `banner_fire`). 0 real lights (emission). Marks per shot id when built; the draft `.cine` stages the same layout with props so it checks today |
| B2 | Dancers: 5 soldiers in a ring + the Vessa pair | systems-coder (cine) | **Done 2026-09-27 (JS "make sure they have dance"):** the party uses the in-game dance clips (`clip <actor> dance_victory` for the crowd, `dance_random` for d3 / d5 / r2 / the archer, Vessa joins at 0:07, re-joins after her fireball; Vey claps with `play_attack`; everyone `stop_clip` at 0:20 when the rider bursts in). Set **B1 built** the same day (`forge_ep2_feast`, 101 draws, 0 lights, marks S01-S14). Was: `move` one ring step (72 deg) per shot + `play_level_up` hops + `face` turns (in the draft). Motion Lab later: a simple **bob / step-dance loop** clip for any `character_model` (0.5 s bob, arms up), a pair spin, a clap loop for Vey |
| B3 | Wren the runner | tech-artist | Stand-in today: Wildwood Archer (on foot) + `glade_outrider` (the approach) + a Grove Stag; later a young Nature runner model (small, scorched green cloak, ash on the face) |
| B4 | Stand-ins | - | Old Vey = Flame Guard until 19.V20; Ashby = Flame Guard until 19.V11 |
| B5 | Props / VFX | tech-artist | Ysolde's seed-pod token (S10), sparks burst over the lanterns (S04; `art/cinematics/fx/fire_burst.tscn` today), Vey's blade spark (S12), the horizon glow (S14) |
| B6 | Audio (Sound Forge, tool 9) | ui-coder | `assets/audio/forge/music/ep2_opening.wav`: a folk reel (fiddle, hand drum, whistle) 0:00-0:20, **hard cut** at 0:20.2 (rider), low drone 0:20-0:51, Vessa's fire motif rising 0:51-1:12, title sting. SFX: `feast_crowd` (cheers, mugs, laughter), `horn_far` (0:19), `hooves_gallop` (0:20). Missing = WARN in `cine check` |
| B7 | Voice | done | 28 lines rendered (below). Re-render only if a line or a voice changes |
| B8 | Timeline | systems-coder-high | Point `ep2_opening.cine` at the real set's marks once B1 lands, `cine stills` + `perf`, bake, hook into StoryFlow as the first thing Episode 2 plays |

## 4. Voices
| Speaker | Who | Voice | Speed | Notes |
|---|---|---|---|---|
| `vessa` | Vessa | af_heart | 1.12 | cast (existing) |
| `vey` | Old Vey | bm_daniel 0.6 + bm_lewis 0.4 | 0.85 | cast (existing) |
| `ashby` | Captain Ashby | am_eric | 1.0 | cast (existing) |
| `messenger` **new** | Wren, runner of the Sighing Wood | **bf_alice** | 1.15 | Auditioned bf_lily 215 Hz / **bf_alice 229 Hz** / af_sky 167 Hz: alice is the youngest-sounding (highest pitch). None is a main character's voice |
| `reveler` **new** | A Flame Guard at the feast | **am_liam** | 1.1 | Auditioned **am_liam** / am_adam: liam brighter, younger |
| `dancer` **new** | The Ember Archer who pulls Vessa in | **af_jessica** | 1.1 | Auditioned af_nova 164 Hz / **af_jessica 208 Hz**: lighter than Vessa's af_heart, never confused with her |
Audition files: `docs/tools/voice_forge/auditions/` (`messenger__*`, `reveler__*`, `dancer__*`). Rendered 2026-09-27
(`run_voice_forge.ps1 build`, 28 new WAVs): every line fits its slot (tightest: Wren "My... my lady?" 1.22 s in 1.7 s,
Vessa L23 2.88 s in 3.2 s).

## Questions for JS (recommendation first)
1. **Episode 2's first battle**: (a) **"The Burning Grove": ride to the Sighing Wood, save Wren's people and hold
   Ysolde's last Heartwood against Shadow + Ice (the 2v1 at its worst)** (b) keep "Sunrise Road" (the descent) first and
   play this opening before mission 2.
2. **The messenger**: (a) **Wren, a young girl runner of the wood (bf_alice)** (b) a boy runner (am_echo / am_liam
   family) (c) Maelis herself, wounded (a known face, but she is Ysolde's warden, not a runner).
3. **Where the feast is**: (a) **the Emberfall watch-keep courtyard (where the war began; reuses `forge_watch_keep`)**
   (b) the camp at Crown Hollow at sunrise (the Ep1 ending's own place).

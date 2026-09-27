# Prologue (3:00): "Once upon a time" - final script, shot list, build list

Owner: story designer / cinematic writer. Written 2026-09-27. Status: **script final (JS to approve by ear), visuals to
build after today's playtest.** Data: `data/cinematics/src/prologue_3min.cine` (draft timeline, `cine check` 0 FAIL),
`data/voice/lines/prologue_3min.json` (30 voiced lines), listening mix
`C:\Users\elzzo\Documents\four-wizards-voice\out\prologue_3min.wav`.

User requests (JS, 2026-09-27, verbatim):
1. "i want to finalize the first 1 min script and start like this once upon a time the strongest wizard of all time was
   ruling in a world that he brought peace to for 1k years the voice is a old brit man voice very kingly if it make
   sense and the visual is a mega big castle full of stuff dragon big and small flying all over the sky and many epic
   suggestion the last 20 sec must have a great segue to the introduction of the other 4 wizards"
2. "the last 2min is introduction of the last 4 whif the wizzard showing each strengh and weekness and why he love them"

This **replaces the narration and shot list of `docs/plan/prologue-movie-plan.md` 1.1 / 1.2** (same 3:00 length, same
skip lock at 0:30, same hand-off to the first mission). The plan's engine, overlay, lighting and reuse rules still apply.

## 0. Decisions
| Question | Decision | Why |
|---|---|---|
| Who narrates | **The Master himself** (speaker `master`). Minute 1 he tells his own legend in the third person, like an old king telling a bedtime story; at 1:00 the voice reveals itself: *"I know this tale well, child. I was that wizard."*; then he introduces his four apprentices | JS: the old king-wizard introduces the four and says why he loves them. One voice for the whole film; the reveal IS the segue |
| Voice | Old, kingly British man: Kokoro blend `bm_lewis 0.4 + bm_george 0.35 + bm_fable 0.25`, speed **0.82** (`data/voice/cast.json` `master`) | Picked from 3 auditions (section 4) |
| Does it spoil Episode 1 ("the Master is alive below")? | No. He speaks in the past tense ("I was that wizard"): a legend he left behind, or a voice from somewhere; the film never says which. Episode 1's ending gives the answer | Keeps the twist, adds a hook |
| Lore kept | Never named: "only the Master". 1000 years of peace (Obren was sealed 100 years ago: inside the peace). Four apprentices, a kingdom each; vanished "between one breath and the next" (the canon line). Order of the intros: **Vessa, Malrik, Torvald, Ysolde** (JS's order) | `story-episode-1.md` 1-2 |
| Echoes | Vessa "my joy", Torvald "my patience", Ysolde "my heart" = Malrik's own line in `ep3_opening` L4 ("Fire was his joy, ice his patience, the wood his heart"). Malrik's L3/L5 ("reading tombstones by one candle", "He gave me what was left over") are answered here: *"He thinks I gave him leftovers. I gave the dark to the one it could not frighten."* Ysolde's "show me again" (`ep4_opening` L6), "Burn her forest down and it grows back", Torvald "trusts slow ice more than quick friends" and his lake secret are all existing canon | The Master's side of the stories the wizards tell in Episodes 3-4 |
| Kept out | No Obren, no Vey face (only the swordsman silhouette at the door in S06), no lightning, no Hush | M0 / Episode 1 keep their reveals |

## 1. The narration (final text, 30 lines, all by the Master)
```
[0:01] Once upon a time, the strongest wizard of all time ruled the world.
[0:07] They called him only the Master. For a thousand years, he kept the peace.
[0:14] His citadel rose above the clouds, a city of towers, bridges and bells.
[0:21] Dragons great and small filled its sky, and not one breathed in anger.
[0:28] Kings brought him their quarrels, and went home as friends.
[0:34] He raised four apprentices, and gave each of them a kingdom.
[0:40] Then, between one breath and the next, he was gone.            <- the last 20 s: the segue
[0:45] Vessa, of Fire.
[0:48] Malrik, of Shadow.
[0:51] Torvald, of Ice.
[0:54] Ysolde, of Nature.
[0:57] Four heirs. One empty throne.
[1:00] I know this tale well, child. I was that wizard.              <- the voice reveals itself
[1:06] Vessa, the youngest. She lit her first spark before she could spell her name.
[1:13] Give her a wall, and she will burn a door through it.
[1:20] But she never waits. And fire that will not wait burns its own house.
[1:27] Still, she laughed like sunrise. Vessa was my joy.
[1:33] Malrik. I found him reading tombstones by the light of one candle.
[1:39] Nothing is hidden from him. The dark itself comes when he calls.
[1:46] But he is never full. Whatever he holds, he wants more.
[1:52] He thinks I gave him leftovers. I gave the dark to the one it could not frighten.
[2:00] Torvald, the eldest. Where he stands, the ice holds, and so does the line.
[2:07] Nothing breaks him. Not armies, not winters. Not time.
[2:14] But he waits too long, and trusts slow ice more than quick friends.
[2:21] I left him my coldest secret. Torvald was my patience.
[2:27] Ysolde. I found her coaxing a sapling through the frost.
[2:34] Burn her forest down, and it grows back. Every spring. Every time.
[2:41] But she will not take a side, not even while the world burns.
[2:47] I would say: show me again. And she always did. Ysolde was my heart.
[2:54] I loved all four of them. And still, they went to war.
[2:58] FOUR WIZARDS · Episode 1 · The Hollow Throne   (title card, then the first mission)
```
Each wizard block is the same 4 beats: **strength, strength, weakness, why he loves them** (the last beat is always a
close-up). Subtitles: every line wraps to <= 2 x 48 characters (the `subtitle` field of the lines file, `|` = break) and
reads at <= 12 characters / s (rule 17). Voiced lengths per line: section 4.

## 2. Shot list: one narration line = one shot = one "what we see" (30 shots, 3:00, letterbox 2.39)
Rule (JS): **the picture shows what the Master is saying at that moment**, plus extra-epic wizard moments (a big spell,
a heroic pose) and, in each wizard's block, **that kingdom's units in action** (the strength shot is always the army
shot). Sets (built now by the set agents): `forge_citadel` (the castle + the **dragon flock**, incl. the orrery dome and
its ruined state for S13, the throne room) and the vignettes `forge_intro_vessa`, `forge_intro_malrik`,
`forge_intro_torvald`, `forge_intro_ysolde`. **Camera marks are named by shot id**: `S01_from`, `S01_to`, `S01_look_from`,
`S01_look_to` ... `S30_*` (the cine reads them automatically: no `cam=` in the `.cine`). Minute 1 = S01-S12, the
Master's four = S13-S30. Block pattern per wizard: **origin / strength (army) / weakness / love** (the last beat is
always a close-up). Lines start 0.3 s into their shot (S01 1.2 s, S08-S12 0.2 / 0.1 s, S13 0.8 s).

| Shot | Time | Set | Camera (marks `<shot>_from/_to/_look_from/_look_to`) | What we see | Line |
|---|---|---|---|---|---|
| S01 | 0:00-0:07 | `forge_citadel` | FADE_BLACK in 1.5 s; CRANE down through a sea of clouds, fov 45 -> 38 | Dawn above the clouds. They part, and the citadel fills the frame: a whole mountain carved into a city, a thousand towers catching the sun one by one. A bell rings. The first dragons lift off the spires | Once upon a time, the strongest wizard of all time ruled the world. |
| S02 | 0:07-0:14 | `forge_citadel` | RAIL along the Great Bridge, 30 m up, toward the statue | A colossal statue of the hooded Master, green with a thousand years of moss, guards the Great Bridge. Under it: pilgrims, carts, four-colour banners snapping, children laying flowers at its feet. An elder dragon glides UNDER the bridge | They called him only the Master. For a thousand years, he kept the peace. |
| S03 | 0:14-0:21 | `forge_citadel` | HERO WIDE (the poster shot), slow push, fov 30 | The whole citadel: spiral towers, sky-bridges, hanging gardens, great bells swinging in open belfries, waterfalls pouring from every terrace into the clouds, a rainbow in the spray, the orrery dome on the summit | His citadel rose above the clouds, a city of towers, bridges and bells. |
| S04 | 0:21-0:28 | `forge_citadel` | FOLLOW a baby ember-dragon through the flock; it peels off to reveal the scale | The dragon flock: cathedral-sized elders drifting like clouds, flights of swallow-sized ones, a frost dragon and a cinder dragon wing to wing, dragons perched on towers like gargoyles, one carrying a bell. Nothing burns | Dragons great and small filled its sky, and not one breathed in anger. |
| S05 | 0:28-0:34 | `forge_citadel` | CRANE down into the market terrace | The market: awnings, spice smoke, jugglers with fire-sprites. Four kings in four colours arrive at the gate glaring, then sit at one long table and break bread. A child rides a baby dragon past them | Kings brought him their quarrels, and went home as friends. |
| S06 | 0:34-0:40 | `forge_citadel` | DOLLY in behind the Master (back to camera) in the orrery dome | The Master (very tall, hooded, a beard of white-gold light, his hem burning in four colours) at the giant brass orrery; four little flames, red, violet, blue, green, orbit his open hand. A swordsman guards the door, back to camera | He raised four apprentices, and gave each of them a kingdom. |
| S07 | 0:40-0:45 | `forge_citadel` | STATIC low angle; FADE_WHITE 0.6 s at the end | The orrery stops. The robe falls empty. The regalia burst up through the dome as sparks and the four flames shoot out as four streaks of colour. Every dragon in the sky turns its head | Then, between one breath and the next, he was gone. |
| S08 | 0:45-0:48 | `forge_intro_vessa` | FADE_WHITE in; low, fast push to a heroic low angle | The red streak falls south. Vessa on her keep wall raises her staff and a pillar of fire answers it into the sky (heroic pose) | Vessa, of Fire. |
| S09 | 0:48-0:51 | `forge_intro_malrik` | Slow push through violet mist | The violet streak falls east. Malrik's candle gutters; every shadow in the crypt stands up behind him | Malrik, of Shadow. |
| S10 | 0:51-0:54 | `forge_intro_torvald` | Crane down over the lake | The blue streak falls north. Torvald plants his staff; the whole lake freezes in one cracking wave | Torvald, of Ice. |
| S11 | 0:54-0:57 | `forge_intro_ysolde` | Down through the canopy | The green streak falls west. Ysolde opens her eyes; the whole wood blooms at once, leaves spiral up | Ysolde, of Nature. |
| S12 | 0:57-1:00 | `forge_citadel` | Top-down on the throne, tilt up | The throne room, empty. The four colours cross high above the seat and part again; the dragons circle once and fly away | Four heirs. One empty throne. |
| S13 | 1:00-1:06 | `forge_citadel` | FADE_BLACK in; static, slow push on the candle (the dome's RUINED state) | Years later: the orrery dome in ruins, moss, a broken roof, one candle. The stopped orrery's four tiny flames relight one by one | I know this tale well, child. I was that wizard. |
| S14 | 1:06-1:13 | `forge_intro_vessa` | CU on cupped hands, match-cut on the spark, then pull back wide | A small girl lights her first spark in cupped hands. Match-cut: grown Vessa hurls a fireball the size of a house into the sky, heroic pose | Vessa, the youngest. She lit her first spark before she could spell her name. |
| S15 | 1:13-1:20 | `forge_intro_vessa` | Low tracking, the charge passes the lens | Vessa on her ember boar blasts a door through a stone wall. Her army pours through: Flame Guards, Blaze Riders, a Scorchbow volley of burning arrows arcing overhead, Pyre Adepts raising fire columns, Cinderlock Musketeers firing; the cinder dragon roars over them | Give her a wall, and she will burn a door through it. |
| S16 | 1:20-1:27 | `forge_intro_vessa` | High, looking down | WEAKNESS: she has charged far ahead alone. The fire runs wild behind her and catches her own banner; her Flame Guards shout after her | But she never waits. And fire that will not wait burns its own house. |
| S17 | 1:27-1:33 | `forge_intro_vessa` | STATIC close-up, fov 30 | LOVE: Vessa laughing among the sparks, soot on her face; one ember drifts up to the stars | Still, she laughed like sunrise. Vessa was my joy. |
| S18 | 1:33-1:39 | `forge_intro_malrik` | Wide, a graveyard at night | A thin boy reads tombstones by one candle. A tall shadow with a burning hem stops behind him | Malrik. I found him reading tombstones by the light of one candle. |
| S19 | 1:39-1:46 | `forge_intro_malrik` | Low angle, DOLLY back as the army rises | Malrik raises one hand: the dark answers. Shades and Shadow Knights melt out of the walls, Hexweavers spin curses, Bleakbows loose bleeding arrows from the rooftops, Grave Hounds run, a Nightmare Knight's eyes open; his Umbral Shroud swallows the whole hall | Nothing is hidden from him. The dark itself comes when he calls. |
| S20 | 1:46-1:52 | `forge_intro_malrik` | Slow push over the table | WEAKNESS: a table of trophies and stolen letters; he pockets one more; a crown's reflection burns in his eyes | But he is never full. Whatever he holds, he wants more. |
| S21 | 1:52-2:00 | `forge_intro_malrik` | STATIC close-up | LOVE: Malrik alone with the candle. He pinches it out. In the dark he is calm, almost smiling: it never frightened him | He thinks I gave him leftovers. I gave the dark to the one it could not frighten. |
| S22 | 2:00-2:07 | `forge_intro_torvald` | CRANE down over the frozen lake | An enemy army charges Torvald across the lake. His Rimeshields lock a wall of ice-shields, a Frostbow volley slows the charge to a crawl, Frostrune Riflemen fire; the ice holds under his army and cracks under theirs | Torvald, the eldest. Where he stands, the ice holds, and so does the line. |
| S23 | 2:07-2:14 | `forge_intro_torvald` | ORBIT 70 degrees around him | A titan leaps at him; he flash-freezes it in mid-air. The frost dragon breathes over the lake, a War Mammoth and a Rime Colossus stand behind him. A time-lapse: a hundred winters pass over him and he does not move | Nothing breaks him. Not armies, not winters. Not time. |
| S24 | 2:14-2:21 | `forge_intro_torvald` | Over his shoulder | WEAKNESS: a rider hammers at his ice gate begging for help; he turns away; snow buries the rider's signal fire | But he waits too long, and trusts slow ice more than quick friends. |
| S25 | 2:21-2:27 | `forge_intro_torvald` | STATIC close-up, then tilt down through the ice | LOVE: Torvald looks down through clear ice at something vast sleeping far below (the Heartfrost) | I left him my coldest secret. Torvald was my patience. |
| S26 | 2:27-2:34 | `forge_intro_ysolde` | Low, in the snow | A small girl coaxes a sapling up through the frost. The tall man with the burning hem kneels beside her | Ysolde. I found her coaxing a sapling through the frost. |
| S27 | 2:34-2:41 | `forge_intro_ysolde` | DOLLY around her, low | Fire sweeps her wood. Ysolde raises her arms: Wild Bloom greens the ash in a wave, an Elder Treant stands up out of it, Vinelashers whip vines, Wildwood Archers step out of every tree two at a time, Grove Stags charge | Burn her forest down, and it grows back. Every spring. Every time. |
| S28 | 2:41-2:47 | `forge_intro_ysolde` | Wide from behind her | WEAKNESS: messengers at her border; she closes the road with roots; smoke rises on the horizon behind her | But she will not take a side, not even while the world burns. |
| S29 | 2:47-2:54 | `forge_intro_ysolde` | STATIC close-up | LOVE: a blossom opens in Ysolde's palm; she smiles at it like a child | I would say: show me again. And she always did. Ysolde was my heart. |
| S30 | 2:54-3:00 | `forge_citadel` | CRANE up and out through the roof, very wide; FADE_BLACK 0.8 s; title | The empty throne at dusk; four shafts of coloured light from four windows fall across it. Out over the citadel the dragons leave; on the four horizons, four armies' fires. Title card | I loved all four of them. And still, they went to war. |

Unit casting (JS's list + each kingdom's signatures): **Fire** Flame Guard, Blaze Rider, **Scorchbow**, **Pyre Adept**,
Cinderlock Musketeer, cinder dragon (S15) · **Shadow** Shade, Shadow Knight, **Hexweaver**, **Bleakbow**, Grave Hound,
Nightmare Knight (S19) · **Ice** Rimeshield, **Frostbow**, Frostrune Rifleman, frost dragon, War Mammoth, Rime Colossus
(S22-S23) · **Nature** **Vinelasher**, **Wildwood Archer** (stepping out in pairs = their Hunting Party upgrade),
Elder Treant, Grove Stag (S27). Wizard epic moments: Vessa's fire pillar (S08) and house-sized fireball (S14), Malrik's
Umbral Shroud swallowing the hall (S19), Torvald freezing the lake in one wave (S10) and a titan in mid-leap (S23),
Ysolde's Wild Bloom wave (S11, S27).

## 3. What must be built (after today's playtest)
| # | Item | Owner | Notes |
|---|---|---|---|
| B1 [H] | World Forge set **`forge_citadel`** ("the Master's citadel"): S01-S07, S12, S13, S30 | tech-artist / set agent (high effort) | Mountain city on a cloud sea: 1000-tower silhouette (tower kit + LOD cards / baked impostor far away), the Great Bridge with the colossal mossy statue of the hooded Master, sky-bridges, hanging gardens, open belfries with great bells, the market terrace (awnings, stalls, spice smoke, a long table), 4-colour banner rows, 6+ terrace waterfalls into the clouds (reuse `river_mouths` falls + mist, rainbow card), the orrery dome (brass orrery, 4 flames) + its **ruined state** (moss, broken roof, one candle) for S13, the throne room with 4 coloured windows. Marks `S01_*` ... per shot |
| B2 [H] | **Dragon flock** (in `forge_citadel`): elder "cloud" dragons (~5x the cinder dragon), the existing `cinder_dragon` + `frost_dragon`, swallow-sized flights, perched gargoyle dragons, a bell-carrying dragon, a baby ember-dragon for S04-S05 | tech-artist + systems-coder (MultiMesh on flight paths, wing-flap vertex anim) | "Not one breathed in anger": no fire in minute 1. S07: every head turns; S12 / S30: the flock leaves |
| B3 | Vignette sets `forge_intro_vessa / _malrik / _torvald / _ysolde` (S08-S11, S14-S29) | tech-artist / set agents | Vessa: keep wall, a stone wall to blast, a battlefield. Malrik: graveyard, crypt hall with rooftops, trophy table. Torvald: frozen lake (clear-ice patch for S25), ice gate + signal fire. Ysolde: snowy clearing, her wood (burning / blooming), a root-closed border road. Marks by shot id |
| B4 | Army staging in the vignettes: the units listed in section 2 in action (charge, volley, cast) | systems-coder (cine `cast` / cast proxy + anim hooks) + tech-artist | New models needed if not built yet: Scorchbow, Bleakbow, Frostbow, Wildwood Archer, Pyre Adept, Hexweaver, Vinelasher, Cinderlock Musketeer, Frostrune Rifleman |
| B5 | VFX: 4 colour streaks (S07-S11), orrery flames, regalia sparks, waterfall mist + rainbow, fire pillar, house-sized fireball, burning-arrow volley, fire columns, Umbral Shroud over a hall, lake-freeze wave, titan freeze, 100-winter time-lapse snow, Wild Bloom wave, leaves spiralling, candle pinch | tech-artist (SpellVfx / IceVfx / NatureVfx / TitanVfx hubs) | Most spell VFX exist; new: streaks, rainbow mist, freeze wave, time-lapse, leaf spiral |
| B6 | Characters: the Master stand-in (very tall, hooded, beard of white-gold light, hem burning in 4 colours), the colossal Master statue, young Vessa / Malrik / Ysolde (scaled, simplified), the swordsman silhouette (Vey hint), kings, pilgrims, messengers, a rider | tech-artist | The Master's face is never shown; children can be silhouettes |
| B7 | Music cue `prologue_3min` (~3:00): majestic 0:00-0:40, sting + silence at 0:40, four 3-s motifs 0:45-0:57, a tender solo 1:00-2:54 with a variation per wizard (fire, shadow, ice, nature), full swell + title 2:54-3:00; stingers `gone`, `title` | ui-coder (audio; Sound Forge tool 9 when it exists) | Placeholder today: `music_menu.wav`. The narration is timed to these sections |
| B8 | Timeline: `prologue_3min.cine` against the real sets (marks), `cine stills` + `perf`, bake, hook into StoryFlow in place of the old `prologue` shots | systems-coder-high | After each set lands |
| B9 | Voice: **done** (30 lines, speaker `master`, `data/voice/lines/prologue_3min.json`) | Voice Forge agent | Re-render only if a line or the voice changes |

## 4. Voice
Speaker `master`, voice `{bm_lewis 0.4, bm_george 0.35, bm_fable 0.25}`, speed 0.82. Auditions (line: "Once upon a
time, the strongest wizard of all time ruled the world.", files in `docs/tools/voice_forge/auditions/`):
| Candidate | Speed | Length | f0 | Rate | Verdict |
|---|---|---|---|---|---|
| **lewis 0.4 + george 0.35 + fable 0.25** | 0.82 | 5.14 s | 127 Hz | 13.0 ch/s | **Picked**: slowest and weightiest (kingly pace), deep lewis colour, no single wizard's voice dominates |
| george 0.5 + fable 0.5 | 0.85 | 4.72 s | 129 Hz | 14.2 ch/s | Too close to Malrik (half bm_george) |
| daniel 0.5 + fable 0.5 | 0.85 | 4.25 s | 127 Hz | 15.8 ch/s | Too quick for a king; daniel is Vey's colour |

The previous `master` voice (plain `bm_fable` 0.9) had no rendered line. The mission narrator stays `am_michael`.

Rendered 2026-09-27 (`run_voice_forge.ps1 build`, 30 new WAVs in `assets/audio/voice/master/`): every line fits its
slot (longest L03 5.63 s in 6.6 s; tightest L12 2.78 s in 2.8 s). Listening mix (lines at their shot times, no music):
`C:\Users\elzzo\Documents\four-wizards-voice\out\prologue_3min.wav`, 3:00.0, 24 kHz mono.
Tool note: `run_voice_forge.ps1 audition only=<speaker>` rewrites `auditions.md` with that speaker's rows only; a full
`audition` run restored the table (all speakers).

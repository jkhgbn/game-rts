# Campaign mission e5m4: "Leftovers" (young Malrik vs young Vessa; Episode 5 finale)

Written 2026-10-02 (`campaign-outline.md` 3.5, row 4). Episode 5 "The Spark and the Candle", mission 4 of 4, a
flashback and the episode's finale. Five years after Wickmoor, on the Master's practice field below the citadel, the
Master sets his two youngest apprentices a friendly 1v1: **first to hold three of five banners while the bell counts
thirty wins**. The player is Malrik (18); the bot is Vessa (17). She takes the field fast and never looks behind her;
he wins by **taking** what she leaves. It ends on the Master's quiet "Well played" and, straight after, `ep5_ending`
(0:40): the gift of the two harbour cities that Episode 7 remembers. Target **18-22 min** on normal. Episode rules
F1-F11 of `mission-e5-01.md` apply; the shadow rule is e5m3's (`mission-e5-03.md` D2). Format `mission-01.md`,
capture points as `mission-e3-01.md` ("Standards", `CapturePoint` kind `&"standard"`), 1v1 basics `skirmish-1v1.md`,
bot `ai.md`. New scene `missions/mission_e5_04.tscn` + `scripts/campaign/mission_e5_04.gd` (`MissionE504 extends
MissionBase`, id `e5m4`). Metres, seconds, `m:ss` of `mission_time()`; `(x, z)`, `+z` = south. Status: **design only**.
Recommended option taken.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | Map | **"The Proving Green"**: `main.gd` generator, 120 x 120, `MAP_SEED := 5104`, **point-mirrored** about `(0, 0)` (outline: "mirrored"); Malrik north-west, Vessa south-east; the Orrery Terrace (spectators) on the cliff north of the field, outside the bounds | A fair practice field; the terrace keeps the Master on screen without a unit |
| D2 | Win rule | 5 banners. A side that owns **3 at once** starts the **bell count (30 s)**; it **resets** if the side drops below 3. First count to finish wins | A race both sides can read; "first to take 3 banners" (outline) with a count so a steal can still answer |
| D3 | "Malrik wins by taking" | The light is not mirrored: the citadel's long afternoon shadow lies on Malrik's half and on 3 hedge / orchard patches. Malrik's units are **hidden** in shadow (e5m3 rule: seen only within 2.5 m). His side **neutralises Vessa-owned banners x2 faster** and each banner taken from Vessa pays **Spoils: 100 crystals**. Vessa's side captures **neutral** banners **x1.25 faster** | Their prologue blocks as rules: she charges and takes the empty field; he takes what she holds (`ep3_opening` L6 "So I took") |
| D4 | Vessa's weakness | The bot's banner plan is scripted (below): once she holds 3 she **charges** with most of her army and leaves her own home banner thin. The intended win is to let her overreach, then take her home banner from the orchard shadow | Pro. S16 "she never waits", the player's opening |
| D5 | Wizards falling | gdd rule kept: **Malrik at 0 HP = defeat** (here: "Malrik yields"). Vessa at 0 HP **yields**: she kneels, fades, and walks out of her keep **30 s** later at 50 % HP | The decided rule stays; the bot needs a 1v1-style return |
| D6 | Friendly | Flavour only: soldiers that fall raise a white flag and fade (no corpses, no blood VFX); no keep or Hall can be attacked for the first **6:00** (`invulnerable` until then; message `The Master forbids burning the practice yards before the sixth bell`) | A friendly match that still allows the late raid as a lever |
| D7 | Tier | Tier 1 only (F3: `max_tier = 1`), no casters | Outline 3.5 |
| D8 | Items | Base shop on (keep, Hall), **250 essence, +1 / s** for both | A 1v1 refresher includes items |
| D9 | After the win | `e5m4_bell` (0:30), then StoryFlow plays **`ep5_ending`** (0:40), built from `episode7-opening.md` H18-H19 (same marks, the same lines L27-L29 and their WAVs, the `&"apprentice"` looks) | Outline 3.5: "ends on the cities gift (Ep7 link)"; one recording, two films |

## Story setup (briefing text, 3 short paragraphs)
1. *Winter, the truce. Malrik counts something on his fingers. It is always the same list.*
2. Five years after Wickmoor, the Master's youngest apprentices were nearly grown, and still keeping score. Below the
   citadel lies the Proving Green, his practice field. On the terrace above it, the Master, Torvald and Ysolde sat to
   watch, and Old Vey took the bell-rope.
3. Five banners. The first to hold three while the bell counts thirty wins. Vessa chose her side first, the sunny one.
   Malrik got the other. He was used to that.

## Map: "The Proving Green" (120 x 120, generator, seed 5104, point-mirrored about (0, 0))
Late afternoon (preset `green_afternoon`: low sun from the south-east, long shadows to the north-west; tech-artist).
Camera bounds x -58..58, z -56..58; the north edge is the citadel cliff (impassable decor); the terrace sits above it.
Every row has its mirror `(-x, -z)` unless marked **one side**. Clearings: no trees / rocks inside.
| Thing | Malrik (north-west) | Vessa (south-east) | Clearing r | Notes |
|---|---|---|---|---|
| Start / wizard | `(-34, -34)` | `(34, 34)` | - | |
| Practice keep (`practice_keep_shadow` / `_fire`, keep copies) | `(-42, -42)` | `(42, 42)` | 16 | 2 500 HP, shoot, train workers, shop, drop-off; no tier button; invulnerable until 6:00 (D6) |
| Hall (pre-built) | Gloom Hall `(-28, -46)` | Ember Hall `(28, 46)` | - | Copies `shadow_barracks_e5m4` / `fire_barracks_e5m4`; invulnerable until 6:00 |
| Home nodes | `(-50, -32)`, `(-32, -52)` | `(50, 32)`, `(32, 52)` | - | **1 500** each |
| Expansion node | `(-48, 2)` | `(48, -2)` | 7 | **1 500** |
| **Home banner** | `bn_shadow` `(-22, -22)` | `bn_fire` `(22, 22)` | 5 | Owned by its side at 0:00 |
| **Near field banner** | `bn_west` `(-28, 20)` | `bn_east` `(28, -20)` | 5 | Neutral at 0:00; each side's nearer field banner (54 m vs 64 m) |
| **Centre banner** | `bn_orrery` `(0, 0)` | - | 6 | Neutral; a brass orrery sundial prop in the middle (decor, collider r 1) |
| Shadow zones (**one side**: not mirrored) | The Long Shadow: every point with `x + z < -36` (Malrik's yard and home banner); the Hedge Garden `(-18, 4)` r 7; the North Walk `(6, -18)` r 7; **the Old Orchard `(14, 31)` r 6** (11 m from `bn_fire`) | - | - | Dark-violet decal, softer than Wickmoor's (daylight) |
| Sunlit lawn (Vessa's half) | - | No zones | - | |
| **Orrery Terrace** (spectator actors) | `(0, -64)` | - | - | Outside the bounds: the Master, Torvald, Ysolde, Old Vey at the bell-rope (actors, no units) |
Distances (path): keep -> own home banner 28 m; home banner -> near field banner 42 m; home banner -> centre 31 m; centre
-> each field banner 34 m; Malrik's yard -> the Old Orchard 76 m (through the Hedge Garden: 4 shadow-hops of <= 22 m of
open lawn each).

**Banners** (`CapturePoint` kind `&"standard"`, `mission-e3-01.md` numbers): radius **6**, capture **12 s** at one unit,
the `map-fill.md` 4.3 rules (rate up to x1.75 with more units, an owned banner must be neutralised first, contested =
frozen, abandoned = decays 10 % / s back to the owner). D3 multipliers: Malrik's side x2 when neutralising a Vessa-owned
banner; Vessa's side x1.25 on a neutral banner. Counters: soldiers and wizards (count 2); workers do not count. Owner
effect: `SightMarker` sight 12. **Spoils**: +100 crystals to Malrik each time his side neutralises a Vessa-owned banner
(the cry `Spoils! +100`).
**The bell** (systems): when a side owns >= 3 banners the terrace bell starts counting (one toll per second, the count
shows on the objectives panel in that side's colour: `The bell counts for Vessa: 18`); dropping below 3 **resets** it.

## Start state
| Item | Malrik (player) | Vessa (bot) |
|---|---|---|
| Wizard | **Level 3** (Shadow Lance r2, Soul Siphon r1), **cap 5**, look `&"apprentice"` (F2) | Level 3 (Fireball r2, Ember Step r1), cap 5, `&"apprentice"` |
| Crystals / essence | 300 / 250 (+1 essence / s) | same |
| Buildings | Practice keep, Gloom Hall | Practice keep, Ember Hall |
| Workers | 5 Gloom Thralls (3 + 2 on the home nodes) | 5 Cinder Hands |
| Soldiers | **4 Shades + 2 Nightbolts + 2 Grave Hounds** (Soot and Bramble's pups, named in the tooltip) at `(-30, -28)` | **4 Flame Guards + 2 Ember Archers + 2 Blaze Riders** at `(30, 28)` |
| Population | 13 / 20 (Hovel max **2** = cap 40) | 15 / 20 (Hearth max 2) |
| Banners | `bn_shadow` | `bn_fire` |
Fog on; all 5 banners explored for both from 0:00. Champions, trade, river, camps, beasts, wells, casters off (F3).

## Unlocks (what exists in this mission)
| Kind | Malrik | Vessa (bot) |
|---|---|---|
| Buildings | Hovel (Z, max 2), Gloom Hall (X), Night Spire (C) | Hearth, Ember Hall, Ember Spire |
| Units | Keep Z Gloom Thrall; `shadow_barracks_e5m4`: **Z Shade, X Nightbolt, C Grave Hound, V Shadow Knight, N Barrow Ghoul** | `fire_barracks_e5m4`: Z Flame Guard, X Ember Archer, C Blaze Rider, V Ash Hurler, N Scorchling |
| Spells | Shadow Lance, Soul Siphon, **Umbral Shroud (L4)** | Fireball, Ember Step, Kindle (L4) |
| Items | Base shop (tops sold but out of reach: ~1 300 essence by 20:00) | same (`items.md` bot rules) |
| Locked | Tier 2+, casters, helpers, Bleakbow, stables | same |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_banners` | Primary | `Hold three banners while the bell counts thirty` (counter `Banners: Malrik n · Vessa m`) | Malrik's side completes a 30 s count |
| `obj_malrik` | Primary, always shown | `Malrik must not yield` | Malrik at 0 HP = defeat |
| `obj_vessa_count` | Primary, always shown (red) | `Don't let Vessa's bell finish` | Fails when Vessa's side completes a 30 s count = defeat |
| `sec_take` | Secondary | `Take Vessa's home banner` | `bn_fire` owned by Malrik's side at any moment |
| `sec_unseen` | Secondary | `Take a banner unseen` | A banner captured by Malrik's side while every capturing unit is hidden (no Vessa unit sees them during the last 12 s) |

## The bot: Vessa's banner plan (ai + systems; normal; easy / hard in Difficulty)
The Commander (`ai.md`, profile `mission_e5_04`) runs only the economy and training: normal knobs, `min_attack_pop` 99
(it never launches its own attacks), `worker_target_home` 8, expansion at **8:00**, no towers, up to **16 soldiers**,
`bots_upgrade = false`, Hall + 2 Hearths. The **mission script moves her army** (attack-moves, refreshed every 4 s):
| Step | Trigger | What she does |
|---|---|---|
| V1 | 1:30 | Vessa + her start army take `bn_east` |
| V2 | 4:30, or her army >= 10 soldiers | Everything takes `bn_orrery` (the centre) |
| V3 Hold | She owns 3 (home + east + centre) | Her army sits on the centre (the bell counts) |
| **V4 The Charge** | 20 s after V3 starts, or 9:00, whichever first; again every 150 s after | Vessa + **70 %** of her soldiers attack-move to the Malrik-owned banner nearest her army (usually `bn_west` or `bn_shadow`); new trainees rally to the centre; **her home banner keeps at most 2 soldiers** (the scripted overreach) |
| V5 Retake | She loses a banner | The nearest **half** of her army goes back to retake it (one retake group at a time); Vessa herself keeps charging unless her home banner is the one lost (then she goes home too) |
| V6 Riders | From 6:00, every **120 s** | 3 Blaze Riders (or the nearest fast units) raid Malrik's workers, then rejoin |
| V7 Yards | From 12:00, if Malrik owns 3 | 6 soldiers attack Malrik's Gloom Hall (D6 lifts at 6:00) |
Vessa retreats under 35 % HP (bot rule 8) and **yields** at 0 (D5). She casts as the `ai.md` / `spells.md` wizard bot.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (Briefing played.) Cutscene `e5m4_green` (HOLD 0:15); L1-L4; hint `Hold three of the five banners while the bell counts 30. Stand in a banner's ring to take it; more soldiers take it faster.` |
| E2 | 0:30 | Hint `The citadel's shadow is yours: in the violet shade your units are hidden unless an enemy comes within 2.5 m.` |
| E3 | V1 starts (1:30) | L5-L6 (terrace) |
| E4 | 2:00 | Hint `Your side takes Vessa's banners twice as fast, and each one pays 100 crystals. She takes empty banners faster.` |
| E5 | Vessa's bell starts the first time | L7-L8; the bell countdown appears in red |
| E6 | V4 The Charge (first) | L9; hint `She left her home banner thin. The Old Orchard's shade is 11 m from it.` |
| E7 | Malrik's side takes `bn_fire` (first) | L10-L11; `sec_take` done |
| E8 | First Spoils | L16 |
| E9 | `sec_unseen` done | L15 |
| E10 | Malrik's bell starts the first time | L12 |
| E11 | Vessa yields (first) | L13-L14 |
| E12 | Malrik reaches level 4 | Hint `Ctrl+E learns Umbral Shroud: E halves the damage Malrik takes for 5 s and speeds him up.` |
| E13 | 6:00 | Message `The sixth bell: the practice yards may be burned.` |
| E14 | Malrik's count completes | Cutscene `e5m4_bell` (HOLD 0:30) with L17-L21; victory; StoryFlow -> `ep5_ending` |
| E15 | Malrik at 0 HP | L22; `obj_malrik` failed; defeat after 3 s |
| E16 | Vessa's count completes | L23; `obj_vessa_count` failed; defeat after 3 s |
| E17 | Malrik's keep destroyed | Defeat (`Malrik's yard has burned`) |

## Dialogue (23 lines; 5 s each unless listed; <= 96 characters)
Colours: Malrik `(0.7, 0.3, 1.0)`, Vessa `(1.0, 0.45, 0.1)`, Master `(1.0, 0.92, 0.70)`, Vey `(0.95, 0.95, 0.55)`,
Torvald `(0.55, 0.80, 1.00)`, Ysolde `(0.55, 0.90, 0.35)`, Narrator `(0.9, 0.85, 0.7)`. Voice file
`data/voice/lines/e5m4.json`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Five years later, below the citadel. A friendly match. Supposedly. |
| L2 | E1 | master | Five banners. The first to hold three while the bell counts thirty wins. Nobody gets hurt. |
| L3 | E1 | vessa | Define hurt. ...Kidding! Malrik, you take the shady side. You like it there. |
| L4 | E1 | malrik | Of course. The side nobody picked. I have had a great deal of practice with those. |
| L5 | E3 | torvald | She'll take the field in five minutes. He'll take it in the last one. |
| L6 | E3 | ysolde | I'm cheering for the grass. Nobody ever cheers for the grass. |
| L7 | E5 | vessa | Three! Ring it, Vey! Ring it, ring it, ring it! |
| L8 | E5 | vey | Thirty, girl. Count with me. One... |
| L9 | E6 | malrik | There she goes. She never looks behind her. Somebody should. |
| L10 | E7 | vessa | Hey! That's MY banner! You can't just take it! |
| L11 | E7 | malrik | I was given the leftovers, Vessa. I have learned to take the rest. |
| L12 | E10 | master | The bell counts for Malrik. (3 s) |
| L13 | E11 | vessa | Ow! Fine! I yield! This counts as a tie! |
| L14 | E11 | vey | It does not count as a tie. |
| L15 | E9 | torvald | Did anyone see him move? No. Nobody ever does. |
| L16 | E8 | malrik | Her banner, her crystals. Fire is generous when it isn't looking. |
| L17 | E14 | master | Malrik wins. By taking. |
| L18 | E14 | malrik | You taught us to use what we were given. I was given leftovers. I used them. |
| L19 | E14 | master | ...Yes. Well played. (3 s) |
| L20 | E14 | vessa | Rematch. Now. Best of three. Best of five! |
| L21 | E14 | master | Later, my joy. Both of you, come up to the orrery. I have something for you. |
| L22 | E15 | malrik | I yield. ...This time. |
| L23 | E16 | vessa | Thirty! Fair and square! Malrik, you can keep the shade! |
Echoes: L11 and L18 are the "leftovers" grudge (`ep3_opening` L5, pro. L20) said to his face; the Master's silence in
L19 is the tragedy the prologue explains to the player only ("I gave the dark to the one it could not frighten"): he
never tells Malrik. L5 is Torvald's patience (pro. S22-S24) and L6 Ysolde's neutrality (pro. S28) in one breath each.
L21 "my joy" is pro. L15 and leads into `ep5_ending` (Ep7 H19: "The two harbour cities are yours now").

## Cinematic hooks (ENGINE, CinematicPlayer 19.C1; skippable; the mission clock stops while they play)
| Id | Kind | When | Length | Shots | End state (a skip must leave exactly this) |
|---|---|---|---|---|---|
| `e5m4_green` | ENGINE, **HOLD** | E1 | 0:15 | 1) WIDE from the terrace over the Proving Green: five banners, long shadows lying north-west; 2) MS on the terrace: the Master seated (back to camera, beard of light at the edge of frame), Torvald arms folded, Ysolde cross-legged on the balustrade, Vey with the bell-rope; 3) MS two-shot Vessa and Malrik at the terrace stair, bowing (she fast, he slow), then turning to walk down to their yards. L1-L2 | Both wizards at their starts, armies at their spots, no orders; banners as at 0:00 |
| `e5m4_bell` | ENGINE, **HOLD** | E14 | 0:30 | 1) CU the bell swinging, last toll; 2) MS Malrik on the last banner he took (usually `bn_fire` or the centre), 3/4, east of the axis: L17-L18; 3) LOW from the field up to the terrace: the Master stands; a long pause; L19; 4) MS Vessa storming up, soot and grass on her: L20; 5) WS the terrace: the Master turns toward the orrery dome: L21; FADE_WHITE (into `ep5_ending`'s first shot, the orrery) | Victory; StoryFlow plays `ep5_ending` |
`ep5_ending` (0:40, written with the Ep5 opening doc, `episode5-opening.md`, not here): the orrery dome, the Ep7 H18-H19
marks and lines L27-L29 (`master`: "Vessa. Malrik. The two harbour cities are yours now. Keep them in peace." /
`vessa`: "Of course, Master! No problem at all!" / `malrik`: "None whatsoever."), then a short present-day tail (the
winter truce) into Episode 6. Camera axis on the field: the Malrik - terrace line north-south; cameras on its east side.

## Win / lose
| Event | Result |
|---|---|
| Malrik's bell completes 30 | **Victory** after `e5m4_bell`, then `ep5_ending` |
| Vessa's bell completes 30 | **Defeat** |
| Malrik at 0 HP ("yields") | **Defeat** (gdd rule) |
| Malrik's keep destroyed | **Defeat** |
| Vessa yields | Nothing; she returns in 30 s |
| Vessa's keep destroyed (after 6:00) | Allowed; she rebuilds nothing and her trainees stop; not a win by itself (message `Vessa's yard is ash. The banners still decide.`) |

## Reward (F1: flags only)
`MISSION_REWARDS[&"e5m4"] = {"flags": {"e5m4_took_home": "sec_take", "e5m4_unseen": "sec_unseen"}, "next": &"e6m1"}` plus
`e5m4_time`, `e5m4_spoils` (count). Episode 5 complete: Theatre unlocks `ep5_opening`, every Ep5 cutscene, `ep5_ending`.
Ep7's `ep7_opening` H19 may play its "Malrik still thinks Vessa got the better half" beat unchanged.

## Economy
| Item | Value (both sides, normal) |
|---|---|
| Start | 300 crystals, 250 essence, 5 workers |
| Nodes | 2 x 1 500 home + 1 x 1 500 expansion each |
| Spoils | +100 per Vessa banner taken (expected 3-5 = 300-500 crystals): Malrik's catch-up lever |
| Expected (normal) | ~10 workers by 5:00; ~3 300 crystals mined by 20:00 (home nodes dry ~17:00: the expansion matters); armies ~20-26 pop by 12:00; essence ~1 400 by 20:00 (one mid + a top component; suggested Grave Pact line for Malrik) |

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Vessa's soldier cap | 10 | 16 | 22 |
| V4 charge share / home guard left | 85 % / 0-1 | 70 % / <= 2 | 55 % / <= 4 |
| V4 first charge | 20 s after V3 or 9:00 | same | 10 s after V3 or 7:30 |
| Vessa's neutral capture bonus | x1.0 | x1.25 | x1.5 |
| Bell count | 40 s for Vessa, 30 for Malrik | 30 / 30 | 30 / 30 |
| Vessa's return after yielding | 45 s | 30 s | 20 s |
| Start | +100 crystals, +2 Shades | as written | -50 crystals, no Grave Hounds |
| Expected time | 15-19 min | 18-22 min | 22-28 min |
Fight sizing (normal, F10; values crystals + wizard `170 + 30 x level`):
| Moment | Vessa side | Malrik side then | Ratio |
|---|---|---|---|
| Start armies | 360 + 200 + 360 + Vessa 260 = 1 180 | 320 + 200 + 140 + Malrik 260 = 920 | 128 %: **on purpose**: he cannot win the open field at 0:00; the shadow and the steal are the answer |
| V2 centre (~4:30) | ~1 500 | ~1 400 | 107 % |
| V4 charge group (~9:00) | ~70 % of ~1 900 = 1 330 at Malrik's banner | ~1 900 (+ hidden) | 70 % |
| Her home banner during V4 | <= 2 soldiers (~180) | a 6-8 unit steal squad (~550) | 33 % |
| V5 retake group | ~half of ~1 900 = 950 | his steal squad + Spoils-fuelled trainees ~900 | 105 %: the race the bell decides |
- A 1v1 with no tier is the episode's skill check: the open-field ratio leans to Vessa (her prologue strength: "give
  her a wall"), the timing leans to Malrik. Intended run: hold `bn_shadow` and `bn_west` in the Long Shadow, let V2 / V3
  happen, keep a 6-8 unit squad hidden in the Hedge Garden and the Old Orchard, take `bn_fire` during V4 (x2 + Spoils),
  hold the Long Shadow banner against the charge, start his own bell with home + west + fire, survive V5 for 30 s.
- A brute-force win (out-producing her) is possible but slower (~24 min); the scripted charge always comes.
- Watch in the first playtest: if the V4 charge takes `bn_shadow` before the player can react, delay V4 to 30 s after V3
  on normal; if `bn_fire` falls with no fight, keep 3 soldiers at home on normal.

## Target length (normal)
| Part | Time |
|---|---|
| `e5m4_green` | 0:15 |
| Opening, centre, first bell (`mission_time`) | 0:00-9:00 |
| The charge, the steal, the race | 9:00-20:00 |
| `e5m4_bell` | 0:30 |
| (`ep5_ending`, counted in the episode's films) | (0:40) |
| **Total** | **~18-22 min** (outline 3.5: 18-22) |

## Implementation tasks (proposed ids; the lead adds them to `waves.md`)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| **E5M4.S1** | systems | Scene + script map part: seed 5104, point-mirrored placements, both practice keeps and Halls (invulnerable until 6:00), nodes, 5 banners (`CapturePoint` `&"standard"` with the D3 multipliers and Spoils), the not-mirrored shadow zones (half-plane `x + z < -36` + 3 circles), the bell count (>= 3 starts, < 3 resets), F3 knobs, start state for both seats | MissionBase, `CapturePoint` (step 12), e5m3's hidden filter (E5M3.S2) | Test `tests/test_e5m4_s1.gd`: every pair mirrors within 0.5 m; a Malrik squad neutralises a Vessa banner in half the time of a neutral one; a Vessa squad takes a neutral banner x1.25 faster; owning 3 for 30 s fires the win; dropping to 2 at 29 s resets the count |
| **E5M4.S2 [H]** | systems-high | Objectives and events E1-E17; the banner plan V1-V7 (scripted attack-moves, 4 s refresh, retake groups, the charge share, home guard cap); Vessa's yield / 30 s return; Malrik's yield = defeat; secondaries (`sec_unseen`: no enemy sight on the capturers for the last 12 s); difficulty table; flags; StoryFlow hand-off to `ep5_ending` | E5M4.S1, E5M4.A1 | Scripted headless runs on normal: (a) the intended steal run wins in 18-22 game-minutes in 3 / 3 seeds; (b) a passive player (army at home) loses to Vessa's bell by ~12:00 |
| **E5M4.A1** | ai | Profile `mission_e5_04` (economy and training only, 16 soldiers, expansion at 8:00, no towers, Hall + 2 Hearths); the wizard bot casts and retreats as usual; the Commander never overrides the script's army orders | `ai.md` | Vessa's army count stays <= 16 on normal; her trainees rally to the centre during V4 |
| **E5M4.U1** | ui | Objectives panel: banner counter `Malrik n · Vessa m`, the bell count in the owning side's colour (red for Vessa), `Spoils! +100` float text, banner ownership on the minimap, the 6:00 yard message; terrace actors' portraits (`master`, `torvald`, `ysolde`, `vey`) | 19.U1 / 19.U3 | Readable at 1600 x 900 and 3440 x 1440; the bell count visible while the dialogue box shows |
| **E5M4.C1** | systems-high | `e5m4_green`, `e5m4_bell` with their end states; the FADE_WHITE hand-off into `ep5_ending` | 19.C1 / 19.C2 | Skips leave the end states; StoryFlow e5m4 -> `ep5_ending` -> Episode 6 card |
| **E5M4.V1** | tech-artist | The Proving Green kit: clipped lawn with mown stripes, hedges and the Hedge Garden, the Old Orchard, the orrery sundial, practice keeps and Halls (banner-dressed, painted wood "yard" look for both kingdoms), banner poles (owner cloth, neutral white), the Orrery Terrace with a bell frame on the cliff, `green_afternoon` preset with the long north-west shadows matching the zones; white-flag fade for fallen soldiers | E5.V1 (apprentice looks) | The shadow decals line up with the baked shadow look within 1 m; 0 dynamic lights except the preset; `PERF OK` with both armies (~50 units) on screen |
| **E5M4.O1** | Voice Forge agent | Render `e5m4.json` (L1-L23) | Lines frozen | Every WAV fits its slot |
| **E5M4.D1** | game-designer | Read the lines in game; check V4's timing and the passive-player loss from the first playtest | Playtest | Changes written back here |
| **E5.D2** | game-designer | `episode5-opening.md`: `ep5_opening` (~3:00: prologue recap 0:45 + the bigger Vessa and Malrik blocks) and `ep5_ending` (0:40, D9), with the young / apprentice looks of F2 and the lines that e5m1-e5m4 echo | This doc set | Scripts, shot lists and build list in the prologue format |

## Done when (acceptance checks)
- [ ] E5M4.S1: the Green builds mirrored from seed 5104 (shadow zones excepted); banners, multipliers, Spoils and the bell behave as D2 / D3 in tests.
- [ ] E5M4.S2 / A1: Vessa runs V1-V7 on a scripted run (charge at 20 s after V3 or 9:00, home guard <= 2 on normal); she yields and returns in 30 s; Malrik's yield and her completed bell both end in defeat; victory after `e5m4_bell` and StoryFlow plays `ep5_ending`.
- [ ] E5M4.U1 / C1 / V1 / O1: counters, bell, Spoils text, both cutscenes with their skip end states, the Green kit, the lines in game.
- [ ] Lead: the scripted steal run wins on normal in 18-22 game-minutes in 3 / 3 seeds; the passive run loses; smoke and perf tests pass; Episode 5 end to end (four missions + films or their cards) plays in ~73 min on normal (outline 5.1: 65 min of missions + 8 of films).

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Grave Hound.
- **Why here:** 5 banners, steals x2 faster with +100 Spoils, Vessa's open lawn and archers; the hound is fast and strong against archers and workers.
- **Moment:** V4, the Charge (9:00): hint E6, 4 hounds steal the Orchard banner while her army is away.
- **Intro card:** `Grave Hound. Fast teeth: go where her army isn't, take the banner, be gone.`

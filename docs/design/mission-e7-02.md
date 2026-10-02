# Campaign mission e7m2: "First Blood, and No Further" (Torvald + Aldra; Episode 7)

Written 2026-10-02 (`campaign-outline.md` 3.7 row 2). Episode 7 "Gold for Fire", mission 2 of 4. The morning after the
broken Laurel: Aurivane has walled the Tollrock and blames Adamarch; Adamarch blames Aurivane; Malrik has sailed home to
"mourn". Torvald alone takes the rock, gathers three clues, settles the Laurel the old way against Dacian, and catches the
real knife in the act: **Mother Hush**, Malrik's. This mission opens the **Citadel**, makes **Aldra Stillwater the callable
helper** and gives the **Shardguard**. Target **18-24 min** on normal. Same rules and format as `mission-e7-01.md` (read it
first: map, auction-free trade, story units), plus `t3-helpers.md` 2-4 and 7 (Aldra's kit, the Shardguard). New scene
`missions/mission_e7_02.tscn` + `scripts/campaign/mission_e7_02.gd` (`MissionE7_02 extends MissionBase`, mission id `e7m2`).
Metres, seconds, `m:ss`; positions `(x, z)`, `+z` = south (Aurivane). Status: **design only**. Recommended option taken
everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | Map | **`two_harbours.map` again** (E7.M1), the e7m1 Map table unchanged; this mission adds its own props (barricade, clues, strongboxes) and leaves seat 3 (Malrik) and seat 1 (Ysolde) **empty** (their keeps and halls are decor ruins of tents: not buildings, no collider targets) | The outline says "the Tollrock arena island": the island is the heart of the same map. One map for three missions saves a Map Lab cycle; the player learns one strait |
| D2 | Allies and enemies | Player alone (no ally bot). Enemy = **Vessa** (Fire bot, seat 0) + the **Aurivane garrison** (scripted Gilded Spears and Fire soldiers). Ysolde has gone back to the Evenmead truce (one line). **Seraphine** fights beside Torvald as a story ally (kneel rule) | One wizard against one, the truth is the objective, not the war; Seraphine's honour is the mirror of Torvald's doubt (e7o 7) |
| D3 | Tier | Start at the **Stronghold**; **Citadel** from 5:45 (`max_tier = 3`): the **Shardguard** (keep C) and **Call Aldra** (keep V) | campaign-outline D7 / C3: each new kingdom's episode opens the Citadel and the helper in its mission 2 |
| D4 | Aldra's first call price | **250 crystals + 100 essence, 30 s** in this mission (skirmish 350 + 200, 60 s); revive at the skirmish price | The e2m1 D4 precedent: the helper lands before the duel on a normal run (~9:00) |
| D5 | "Find the truth" | Three **clues**, each a channel (the `MissionBrazier` rule: Torvald within **3 m for 4 s**, leaving resets it, damage does not; refused while an enemy is within 8 m) | No "run the wizard in" cheese (the M1 lesson); the clues pull the army across the island and onto the south shore |
| D6 | The duel | **Torvald vs Dacian, first blood**: the duel ends when either drops below **75 %** HP. Losing is **not** a defeat (flag only) | The title is the rule; Torvald's patience against Dacian's glory is the episode's theme in one fight |
| D7 | Mother Hush | **Enemy story boss** (`hush_story` with boss numbers, 6.3); she **flees at 25 %** and cannot die (Ep8 needs her) | campaign-outline 4.2: she lives to the Shadow road |
| D8 | Vessa at the ambush | During the ambush, a **truce** puts Aurivane's units (and Vessa) on the knives' backs: they ignore side 0 and side 0 cannot target them; Vessa fights the knives (she knows them from M0) | One minute of Fire and Ice side by side against Shadow seeds Ep8's muster; the truce rule avoids friendly-fire confusion |
| D9 | Malrik | **Absent** (sailed to the Admiralty, D1). He is confronted in `c_e7_mask`, after the mission | The player's discovery must be Torvald's, not a bark |
| D10 | Trade | **On**: Frost Bazaar pre-built, the two north harbours as in e7m1 (posts open at 1:00, caravans max 4, no Magpies). **No auction** | Gold buys the wares that crack the barricade fight; the episode's spine stays visible without repeating e7m1 |

## Story setup (briefing text, 3 short paragraphs)
1. The morning after the Laurel, the Coinwater woke to two lies. Aurivane says Adamarch faked an attack to steal the duel.
   Adamarch says Aurivane hid knives in gold cloaks. Aurivane's spears now hold the Tollrock, and a barricade shuts the
   North Causeway.
2. Malrik sailed home to the Admiralty "to mourn". Seraphine did not: she stands at Torvald's camp with a bandaged hand and
   one question. Ossavar, on the Master's chair, gave his own advice: ask the herald where the knives came from.
3. Take the rock. Find what the knives left behind. Then settle it the only way both cities still respect: first blood,
   and no further.
Briefing objectives: `obj_rock`, `obj_truth`, the rule `Torvald must survive`, and the line `The herald saw the knives
arrive. He fled to the south shore.`

## Map: "Two Harbours" (the e7m1 table) + this mission's layer
Everything of `mission-e7-01.md` "Map" holds (seat 2 player base, harbours, crossings, island, strait, the rules of the
Tollrock point and the Diamond Harbour target). Changes and additions:
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| Seat 3 (Malrik's quarter) | `(42, -66)` area | - | Empty: struck tents and a cold brazier (decor); its nodes `(54, -56)` / `(30, -58)` **1 500** are free for the player (expansion, far); the **Admiralty Quay** `(22, -40)` is a player post (far route) |
| Seat 1 (Ysolde's quarter) | `(42, 66)` area | - | Empty Nature tents (decor); the Gilt Quay `(22, 40)` stays Aurivane's (held post) |
| **Sun Barricade** | On the North Causeway, `(0, -21)`, 6 m wide | - | Building, team ENEMY, **1 500 HP**, armor 10, `counts_for_defeat` false; blocks the causeway for side 0 (Aurivane's units pass its gate); `building_damage_mult` units (Frost Mortar) x1.5 |
| Ember Spire (island) | `(0, -12)` | - | 720 HP, range 11: covers the barricade's north face (9 m) |
| **Clue C1 "The knives"** | Arena sand `(0, 0)`: four bodies under a gold cloth | 3 | Channel (D5). If flag `e7m1_rune_saw_boat`: C1 starts **found** (Torvald already saw the violet boat) |
| **Clue C2 "The ledger"** | The Gold royal box, east rim `(11, 4)` | 2 | Channel (D5) |
| **Clue C3 "The herald"** | Among the bettors' boats, south shore `(-6, 34)` | 4 | Torvald within 3 m for 4 s (the herald is a story NPC hiding behind a boat, `herald_story`, invulnerable) |
| Strongbox S1 / S2 / S3 | `(8, -8)` (island), `(-60, 30)` (Gold Shoal south bank), `(60, 30)` (Silver Shoal south bank) | 2 | Bettors' strongboxes: any side-0 unit within 2 m opens one (the Lost Cache rule): **150 gold + 60 essence** each |
| Laurel ring (duel) | `(0, 0)`, r **8** | - | Closed to soldiers during the duel (soft push-out) |
| Hush's boat | Strait at `(12, -14)` (north-east of the island, in the moat) | - | Where Hush flees (6.3) |
| Wave spawns | Fire: Ember Hall `(-58, 68)`; garrison: South Causeway foot `(0, 30)`; knives: arena rim `(0, 8)`, `(-8, 0)`, `(8, 0)` | - | |
Distances (path): Rime Keep -> barricade 60 m; barricade -> rock `(0, 6)` 27 m; rock -> C3 via the South Causeway 32 m; Rime
Keep -> Gold Shoal -> C3 105 m (the long way round, slowed by the ford). The island is the only short way to the herald:
the barricade is the mission's first wall.

## Start state (Torvald's track)
| Item | Value |
|---|---|
| Torvald | **Level 5** with **4 unspent spell points** (Rime Bolt r1 known), **cap 8** |
| Artifacts / items | From the save: Heartfrost Splinter (slot 1); the 6 item slots |
| Crystals / essence / gold | **400** / **150 + carried** (50 %, cap 1 500) / 0 |
| Buildings | Rime Keep (**tier 2 Stronghold**, 3 600 HP), Frost Hall, Snow Lodge, **Frost Bazaar** (all complete) |
| Units | 6 Rime Haulers gathering (3 / 3); 2 Caravans (on the Diamond Harbour route); **6 Rimeshields + 4 Shardcasters + 1 Rime Seer + 1 Rimecarver + 1 Frost Mortar** at `(-36, -44)` (1 500 crystals of army) |
| Story units | **Seraphine** (`seraphine_story`, full speed 4.6, 1 000 HP) beside Torvald; **Aldra** at the keep door (story NPC until called, then the helper) |
| Population | 6 + 2 + 6 + 4 + 1 + 2 + 2 = **23 / 40** (keep 20 + Lodge 20; Lodges max 4) |
| Vessa (enemy bot, seat 0, Fire) | **Level 6** (Fireball r3, Ember Step r2, Kindle r1); Fire Keep at Stronghold, Ember Hall, Hearth, 5 Cinder Hands, 4 Flame Guards + 2 Ember Archers at her rally |
| Off | Ally bot, champions, Magpies, Lodges, camps, beasts, points (only the Tollrock point), auctions |
| No save / e7m1 not completed | Splinter equipped, empty slots, essence 150 + **500**; `e7m1_rune_saw_boat` false |

## Unlocks
| Kind | Available | Locked |
|---|---|---|
| Buildings | Snow Lodge, Frost Hall, Rime Spire, Ice Wall, Frost Bazaar (already built: max 1) | Stables, Lair, research |
| Units | e7m1's list (Frost Hall Z X C V N + M `,`; keep B Rimecarver; Bazaar Z Caravan) **+ from the Citadel: C Shardguard** (keep) | Frostbow, Rimehorn Rider, titans |
| Keep | **Citadel** (X, 300 crystals, 90 s, from **5:45**) | - |
| Helper | **Call Aldra** (keep V) once the Citadel stands: 250 crystals + 100 essence, 30 s, pop 4 (D4) | Other helpers |
| Spells | Rime Bolt, Flash Freeze, Rime Aegis; cap L8 | - |
| Items | Base shops, the 4 Ice items; strongbox loot | Peddler |
| Gold | Wares, exchange (as e7m1) | Bids |

## Tiers and the helper (`tiers.md` 6, `t3-helpers.md` 3)
| Item | Value |
|---|---|
| Code | `MissionE7_02._init`: `tiers_enabled`, `casters_enabled`, `t3_enabled`, `helpers_enabled`, `trade_enabled` = true; `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(2)` (3 600 HP, attack 16, no announcement) |
| Keep card | Z Rime Hauler · X **Citadel** (gold pulse when it can start) · C **Shardguard** (greyed `Requires Citadel`) · V **Call Aldra** (greyed `Needs a Citadel`), then `Revive Aldra` · B Rimecarver · Set Rally r3c1 |
| Citadel hint | Once, when the upgrade can start (12 s): `Your Stronghold can become a Citadel: select the Keep and press X (300 crystals, 90 s). It opens the Shardguard (C) and lets you call Aldra (V).` |
| Call hint | Citadel complete (10 s): `Call Aldra: select the Keep and press V. She fights on her own; her card sets where (Escort / Vanguard / Hold home).` |
| Aldra | `helper_aldra` kit (`t3-helpers.md` 4.4) at Torvald's level (L5: 800 HP, armor 15, 26 damage; x1.16 abilities; **Wake the Sentinel** from L5), stance Escort, F4 centres on her. Fallen = never a defeat; revive 120 + 20 x level essence, 25 + 5 x level s |
| Shardguard | 225 crystals, pop 3, 36 s (`t3-helpers.md` 7.2): **Hold the Line** stops the first charge, lunge or **blink** ending within 2.4 m every 10 s and freezes the attacker 1 s (heroes 0.5). It is the answer to Hush's Blink Strike on Dacian (hint at E14) |
| Enemy keep | Never upgrades; the garrison's tier-2 units are spawned, not trained |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_barricade` | Primary | `Break the Sun Barricade on the North Causeway` (HP bar) | The barricade is destroyed |
| `obj_rock` | Primary (after `obj_barricade`) | `Take the Tollrock` | Side 0 owns the Tollrock point (15 s capture) |
| `obj_truth` | Primary (appears with `obj_rock`) | `Find the truth (0 / 3): the knives, the ledger, the herald` | 3 clues channelled (any order; C3 needs the South Causeway or a ford) |
| `obj_duel` | Primary (after `obj_truth`) | `Meet Dacian on the sand: first blood, and no further` | The duel ends (either way, D6) |
| `obj_dacian` | Primary (appears at E13, the ambush) | `Keep Dacian alive` | Hush flees and every knife is dead with Dacian alive; **failed** if he dies = defeat |
| `obj_torvald` | Primary, always shown | `Torvald must survive` | Fails = defeat |
| `sec_aldra` | Secondary | `Raise a Citadel and call Aldra` | Aldra arrives |
| `sec_boxes` | Secondary | `Seize the bettors' strongboxes (0 / 3)` | 3 strongboxes opened |
| `sec_duel` | Secondary (appears with `obj_duel`) | `Draw first blood` | Torvald wins the duel |
While the duel runs, the Tollrock cannot change owner (both sides' units are out of the ring; the point freezes).

## Guards, waves and the bot (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units: team ENEMY, group `"scripted"`, no Commander, auto-aggro, leash 2x. Values as e7m1 (gold knife 110).
| Group | Where | Units | Value |
|---|---|---|---|
| G1 barricade | Behind the barricade on the island's north lip `(0, -14)` + the Ember Spire `(0, -12)` | 4 Gilded Spears + 2 Ember Archers (they shoot over the barricade, range 9) | 680 + spire |
| G2 rock garrison | Tollrock point `(0, 6)` ring r 4 | 4 Gilded Spears + 2 Flame Guards + 2 Ember Archers + 1 Pyre Adept | 990 |
| G3 royal box | `(11, 4)` | 2 Gilded Spears + 1 Cinder Arbalest | 375 |
| G4 the bettors' boats | `(-6, 34)` ring r 5 | 3 Flame Guards + 2 Ember Archers + 2 Gilded Spears | 710 |
| G5 Gold Shoal box | `(-60, 30)` | 2 Blaze Riders + 2 Ember Archers | 560 |
| G6 Silver Shoal box | `(60, 30)` | 3 Gilded Spears | 360 |

| Wave | Trigger | Units (spawn) | Order |
|---|---|---|---|
| W1 riders | **4:00** | 3 Blaze Riders (Ember Hall) | Gold Shoal -> the nearest caravan, else the nearest Hauler; home after 60 s or under 40 % |
| W2 Vessa's sortie | **8:00**, or the barricade destroyed, whichever is **earlier** | **Vessa** + 5 Flame Guards + 3 Ember Archers + 1 Kilnwarden (Ember Hall) | Gold Shoal -> the Rime Keep (a base raid while the army is on the causeway); Vessa retreats under 35 % |
| W3 rock counter | Side 0 takes the Tollrock (first time) | 4 Gilded Spears + 3 Flame Guards + 2 Pyre Adepts (South Causeway foot) | Attack-move to the Tollrock point, then Torvald |
| W4 the sun's answer | **13:00**, or 2 clues found, whichever is **later** | **Vessa** + 6 Flame Guards + 4 Ember Archers + 2 Cinder Arbalests + 2 Blaze Riders | South Causeway -> the Tollrock point (if side 0 owns it) else the Diamond Harbour |
| Relief | Every **150 s** from W3 until the duel, while the rock is side 0's | 3 Gilded Spears + 1 Ember Archer (South Causeway foot) | The Tollrock point |
| **Ambush** | The duel ends (E13) | 0 s: **Mother Hush** (6.3) + 6 gold knives (arena rim, 3 marks); 30 s: 4 gold knives (Hush's boat `(12, -14)`, wading in) | All on **Dacian**, then on whoever hits them (Torvald first) |
The garrison stops its waves at E12 (the duel is accepted): every Aurivane unit on the field walks to the South Causeway foot
and stands (no aggro on side 0 while the duel runs; the truce flag of D8 starts here and lasts to the end).
**Enemy bot** Vessa (`ai.md`, profile `mission_e7_02_enemy`): normal knobs, `min_attack_pop` 99, `worker_target_home` 5, no
expansion, 10 soldiers at her rally, `bots_upgrade = false`; she only defends and rides the scripted waves; after E12 her
Commander is paused (D8).

### 6.3 Mother Hush, the knife-master (enemy story boss, gameplay)
`hush_story` at **level 6** with boss numbers: **1 100 HP** (helper 695 x1.6), armor 10, 39 damage / 1.0 s, 5.4 m/s; her
`t3-helpers.md` 4.3 kit at L6 (x1.20): Mouthless Veil (+60 % opener), **Blink Strike** (cd 10, 0.5 s violet ring telegraph,
66 to the target), Smoke Cloak (cd 22), **Night of Knives** (cd 75, 6 strikes of 48, x1.5 on heroes). Brain: **Dacian first**
(Blink Strike every time it is ready; a Shardguard within 2.4 m of Dacian stops it and freezes her 0.5 s); Night of Knives when
Dacian and 3+ others are within 10 m. At **25 % HP** she casts Smoke Cloak, runs to her boat `(12, -14)` (untargetable after
2 s) and leaves the map: L22. Kills on her: none (she never dies); XP for reaching 25 %: **400** to Torvald (a hero kill's worth).
**Dacian** in the ambush: `dacian_story` (e7m1 6.5) at the HP the duel left him, team PLAYER for the ambush (not commandable),
fights the nearest knife; dies at 0 HP (D: `obj_dacian`). **Vessa** in the ambush (D8): her bot is paused, a story brain sends
her at the nearest knife; she and her units are untargetable by side 0 (the truce flag) and target only knives and Hush.

### 6.4 The duel (D6)
| Rule | Value |
|---|---|
| Start | E12 cutscene `e7m2_laurel_call`; then Torvald and Dacian stand at `(0, 5)` / `(0, -5)` inside the ring r 8. Every other unit is pushed out to r 10 and cannot enter (a soft wall: `Unit.displace` to the edge, message `The Laurel ring is for the duellists alone.`). Aldra and Seraphine wait at the rim |
| Dacian | `dacian_story` 950 HP, armor 10, 36 / 1.4 s, 5.0 m/s; **Sun Cleave** (cd 8, **1.0 s** gold-arc telegraph, 90 in a 3 m 120 deg arc); **Second Wind** once at 85 %: +2 m/s for 4 s. Brain: close, cleave when Torvald is inside the arc, else auto-attack |
| Torvald | As he is (level, items, mana); his spells work on Dacian (hero rules: Flash Freeze half duration) |
| End | The first to drop below **75 %** HP loses. Both stop at once (no further damage; a hit in flight is cancelled: "no further") |
| Outcome | Torvald wins: `sec_duel` done, L18a; Dacian wins: L18b. Either way: E13 |
| Guard | If the duel runs **90 s** with nobody below 75 %, the herald calls it a draw (L18c) and E13 fires |
Expected: Torvald needs ~238 damage (Rime Bolt r2 + autos + one Flash Freeze ~10-14 s of clean play); Dacian needs ~160 on
Torvald (two Sun Cleaves, or ~8 s of auto-attacks). Flash Freeze on a telegraphed cleave is the intended answer.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cinematic `e7m2_morning` (HOLD 0:12); L1-L3; hint `Break the barricade on the North Causeway. Frost Mortars hit walls hard; a Rimecarver's Scrying Rune shows what is behind it.` (10 s) |
| E2 | 1:00 | L4 (Aldra); `sec_boxes` and `sec_aldra` active |
| E3 | W1 launches | L5 |
| E4 | 5:45 (Citadel available) | The Citadel hint |
| E5 | Citadel complete | L6; the call hint |
| E6 | Aldra arrives (arrival set-piece, `t3-helpers.md` 10.2, no camera move) | Her arrival bark (`The mere remembers every footstep.`), then L7; `sec_aldra` done |
| E7 | Barricade destroyed | L8; `obj_barricade` done, `obj_rock` and `obj_truth` active; W2 if not yet launched |
| E8 | Tollrock taken | L9 (Ossavar); W3; relief armed |
| E9 | Clue C1 found (or pre-found by the flag: L10b at E8 instead) | L10 |
| E10 | Clue C2 found | L11-L12 |
| E11 | Clue C3 found | Cutscene `e7m2_herald` (PAUSE 0:15): L13-L15 |
| E11b | Third clue (any order) | L16 (Torvald); `obj_truth` done; `obj_duel` active; message `Dacian comes to the sand.`; Dacian walks from the South Causeway foot to `(0, -5)` |
| E12 | Torvald within 10 m of Dacian on the island | Cutscene `e7m2_laurel_call` (PAUSE 0:12): L17; the duel starts (6.4); the truce flag on (D8) |
| E13 | Duel ends | L18a / L18b / L18c; then 2 s later the **Ambush** (`e7m2_knives` HOLD 0:06: the knives drop, L19-L20); `obj_dacian` active |
| E14 | Hush's first Blink Strike | L21 (Vessa); hint (8 s) `A Shardguard beside Dacian stops her blink and freezes her.` |
| E15 | Hush at 25 % | L22; she flees (6.3) |
| E16 | Hush gone **and** every knife dead **and** Dacian alive | Cutscene `e7m2_mask` (PAUSE 0:30): L23-L27; `Events.mission_ended(true)` at its end |
| E17 | A strongbox opened | First time L28; `sec_boxes` counter |
| E18 | Dacian dies | L29; defeat after 3 s |
| E19 | Torvald dies | L30; defeat after 3 s |
| E20 | Rime Keep destroyed | Defeat after 3 s |

## Dialogue (33 lines incl. outcome variants; 5 s each unless listed)
Speakers: `torvald`, `aldra`, `vessa`, `hush` (exist); `ossavar`, `herald`, `dacian`, `seraphine` (**new**, added by E7M1.O1;
no further new speaker here). Colours and names as `mission-e7-01.md`; Hush `(0.60, 0.50, 0.75)`, name `Mother Hush`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | ossavar | Two cities, two lies, one rock. The rock, at least, is honest. |
| L2 | E1 | seraphine | They say Adamarch staged it. I bled on that sand, Ice-king. I would like to know for whom. |
| L3 | E1 | torvald | So would I. Malrik sailed home before the blood was dry. That is not mourning. |
| L4 | E2 | aldra | The bettors fled with their strongboxes and dropped half of them. Coin always runs downhill. |
| L5 | E3 | vessa | Back again, Torvald? You're the slowest man I know, and you're still everywhere. |
| L6 | E5 | torvald | The Citadel stands. Aldra. I would rather not do this one alone. |
| L7 | E6 | aldra | You never do anything alone, my lord. You only think you do. |
| L8 | E7 | seraphine | The barricade is down. Walls should know when to fall. Ours never did. |
| L9 | E8 | ossavar | You hold my rock. Look under the cloths. The dead are poor liars. |
| L10 | E9 | torvald | Aurivane's cloaks, on knives forged in the dark. The edges drink the light. Shadow steel. |
| L10b | E8 (flag) | torvald | The boat my rune saw left violet smoke. Gold cloaks do not row from the north. |
| L11 | E10 | aldra | The bettors' ledger. Someone wagered against both cities, on the same night, before the duel. |
| L12 | E10 | torvald | A man who bets on the war, not the winner. I know only one with that much patience. |
| L13 | E11 | herald | Don't hurt me! I only read the names! I saw the boat, a black boat, from the north side! |
| L14 | E11 | torvald | Easy. Who stepped out of it? |
| L15 | E11 | herald | A woman in a white mask. She never said a word. The knives followed her like ducklings. |
| L16 | E11b | torvald | A white mask. Then I know the knife, and I know the hand that throws it. |
| L17 | E12 | dacian | You want the truth told on my sand, Ice-king? Then by the old rule. First blood, and no further. |
| L18a | E13 (won) | dacian | Well struck. Twice now an Adamarch guest has cut me. I am starting to take it personally. |
| L18b | E13 (lost) | dacian | First blood to the Sun. Now say your truth, Ice-king, and I will listen. |
| L18c | E13 (draw) | herald | Neither bleeds! By the law, it is a draw, and the sand is quiet! |
| L19 | E13 | hush | Hush now, Sunblade. The war only needs one more death. |
| L20 | E13 | seraphine | Behind you, Dacian! The knives again! |
| L21 | E14 | vessa | I know those knives. I've had them at my throat. Hush! I owe you a night! |
| L22 | E15 | hush | There is always another night, Ice-king. Ask your friend how he spends his. |
| L23 | E16 | dacian | Those were never ours. You knew before you came to the sand. |
| L24 | E16 | torvald | Mother Hush. I have stood beside this mask in Malrik's camp. They were my ally's knives. |
| L25 | E16 | seraphine | Then your ally broke a truce that held for a hundred and thirty years. For what? |
| L26 | E16 | torvald | For a war that does not end. Wars are good for business, and better for that stone. |
| L27 | E16 | ossavar | First blood, and no further. The cities forgot. Let us see if you remember. (6 s) |
| L28 | E17 | aldra | Bettors' gold. It spends the same as honest gold, which is the whole trouble with gold. |
| L29 | E18 | seraphine | The Sunblade is down. Every bell in both cities will ring for war now. |
| L30 | E19 | torvald | Too late. I always arrive... too late. |
Echoes: L19 opens with Hush's own word; L22 is her M0 / e3m1 line "There is always another night" turned toward Malrik;
L21 pays off M0 (Hush led the knives at Vessa's throat); L24 is the outline's turn seed; L26 names the stone (Ep3 e3m3's
Hollow price); L27 hands the rule to e7m4. Every line <= 96 characters (L25 92); Ossavar's lines <= ~70 characters per
5 s at his 0.88 speed (L27 gets 6 s).

## Cinematic hooks (ENGINE, skippable)
| id | Kind | When | Shots | Lines | Skip end state |
|---|---|---|---|---|---|
| `e7m2_morning` | HOLD 0:12 | E1 | 1) Long lens from the Diamond Harbour to the Tollrock: the gold barricade across the causeway, crimson pennants; 2) MS Seraphine and Torvald on the quay, her hand bandaged; 3) insert: Ossavar on the chair, one eye open | L1-L2 | Camera on Torvald, L1-L2 as dialogue |
| `e7m2_herald` | PAUSE 0:15 | E11 | 1) MS behind a beached bettors' boat: the herald cowering, ledger pages blowing; 2) CU herald (L13); 3) OTS herald on Torvald, 3/4 (L14-L15) | L13-L15 | `obj_truth` counter updated, herald stays put (invulnerable) |
| `e7m2_laurel_call` | PAUSE 0:12 | E12 | 1) WS of the sand at noon, cameras east of the Torvald - Dacian axis (the e7o rule); 2) MS Dacian draws the Sunblade (L17); 3) CU Torvald's staff crystal snapping into a star | L17 | Both at their marks, the ring closed, the truce on |
| `e7m2_knives` | HOLD 0:06 | E13 | One shot: MS on Dacian, a violet ring blooms behind him; the knives drop from the rim | L19-L20 | Hush and 6 knives at their marks, `obj_dacian` active |
| `e7m2_mask` | PAUSE 0:30, then victory | E16 | 1) MS on the sand: a white mask lies where Hush vanished; 2) CU Torvald's hand picks it up (L24); 3) MS two-shot Dacian + Seraphine, back to back as in e7o D15, then lowering blades (L23, L25); 4) WS from the chair: Ossavar (L27); FADE_BLACK | L23-L27 | `Events.mission_ended(true)`, flags saved |
Fallbacks: missing cine = the lines as dialogue with a 2 s camera pan; the mask is a prop that spawns at Hush's exit point.

**Between-mission scene `c_e7_mask` "Mourning"** (ENGINE, ~1:10, after victory; E7.D2 writes it): Malrik's galley at the
Admiralty, night; Torvald drops the white mask on the chart table. Malrik does not deny it: "Wars need a first blow. I only
provided one." Torvald: "You broke a truce older than both of us." Malrik: "Truces are what weak men sign to sleep. You
signed one with me, Torvald." The stone pulses in his hand. Torvald, after a long silence: "For now, I sail with you."
Aldra, on the quay, closes her eyes: he is waiting again (his weakness, pro. S24). Ossavar's shadow crosses the moon.

## Economy
| Item | Value |
|---|---|
| Start | 400 crystals, 150 + carried essence, 0 gold, 23 / 40 pop, 6 Haulers, Bazaar + 2 caravans |
| Nodes | Home 2 x 1 500, Outwall west 2 000, **Malrik's empty quarter** 2 x 1 500 (far, east) |
| Gold | Diamond Harbour 24 / trip (~68 / min per caravan), Admiralty Quay 72 / trip (~96 / min, far), toll +30 / min once the rock is held, strongboxes 3 x 150. Expected ~**1 600-2 000** by 18:00 |
| What gold buys here | Wares (Quilted Gambesons and Tempered Steel make the G1 / G2 fights; Masons' Charter makes W2's base raid harmless), the exchange (gold -> crystals pays for the Citadel + Aldra in the 5:45-8:00 window) |
| Spending pressure | Citadel 300 + Aldra 250 / 100 essence + Shardguards 225 each vs Frost Mortars for the barricade (190) |
| Essence by 20:00 | carried + 150 + trickle ~1 200 + kills ~1 300 + boxes 180 + Hush 400 XP (not essence) = ~3 000 + carried |

## Win / lose
| Event | Result |
|---|---|
| E16 (Hush gone, knives dead, Dacian alive) | **Victory** (after `e7m2_mask`) |
| Torvald dies | **Defeat** |
| Rime Keep destroyed | **Defeat** |
| Dacian dies during the ambush | **Defeat** |
| Torvald loses the duel | Not a defeat (flag `e7m2_duel_won` false) |
| Aldra / Seraphine fallen or kneeling | Nothing (Aldra revives; Seraphine stands after 10 s) |
| Vessa killed (before the truce) | Not a win: `Vessa falls back to the Sun Gate`; respawn 60 s |

## Reward carried to e7m3
- Splinter kept; 6 item slots; essence 50 %, cap 1 500; **+300** first if `sec_boxes`, **+200** if `sec_duel`, **+150** if
  `sec_aldra`.
- Flags: `e7m2_duel_won`, `e7m2_aldra_called`, `e7m2_boxes`, `e7m2_time`, and always **`helper_aldra_unlocked`** (the Theatre
  reveal `helper_aldra` unlocks; later Ice missions may call her) and `e7_truth_known` (always true on a win).
- e7m4 reads `e7m2_duel_won` (Dacian's line at the truce) and `helper_aldra_unlocked`.
- `MISSION_REWARDS[&"e7m2"] = {"flags": {...}, "bonus_essence": {"sec_boxes": 300, "sec_duel": 200, "sec_aldra": 150}, "next": &"e7m3"}`.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6, no Cinder Arbalest, no Kilnwarden | as written | x 1.4 |
| Start | 500 crystals, +2 Rimeshields | as written | 300 crystals, no Frost Mortar |
| Barricade HP | 1 100 | 1 500 | 1 900 |
| Clue channel | 3 s | 4 s | 5 s |
| Duel: Dacian | 800 HP, cleave 70 | 950, 90 | 1 050, 105; Second Wind at 90 % |
| Hush | 850 HP | 1 100 | 1 400; Night of Knives cd 60 |
| Aldra call | 200 + 50 essence | 250 + 100 | 300 + 150, 45 s |
| Vessa | L5 | L6 | L7 |
| Expected time | 15-19 min | 18-22 min | 21-26 min |
Expected run on normal: W1 riders 4:00 -> barricade 5:30-7:30 (Frost Mortars + Rimecarver rune) -> W2 Vessa raid 7:30 ->
Citadel 5:45-8:00, Aldra ~8:30 -> rock ~9:30 (W3) -> C1 ~10:00, C2 ~11:00 -> W4 13:00 -> C3 ~14:30 (the herald) -> duel
~15:30-16:30 -> ambush 16:30-18:30 -> cutscene -> **~19:30**, 23 with retakes.
**Fight sizing** (normal; <= 70 % rule; Seraphine ~600, Aldra L5 ~400 counted when present):
| Fight | Enemy | Player side then | Ratio |
|---|---|---|---|
| W1 riders (4:00) | 540 | ~1 800 | 30 % |
| G1 barricade (+ spire chip) | 680 + spire | ~2 100 + Seraphine | 32 % (+ the spire) |
| W2 Vessa raid (~7:30) | 920 + Vessa 350 = 1 270 | ~2 300 (army split) | 55 % |
| G2 rock garrison (~9:30) + W3 at once | 990 + 1 010 = 2 000 | ~2 900 + Aldra + Seraphine ~ 3 900 | 51 % |
| W4 sun's answer (13:00) | 1 690 + 350 = 2 040 | ~3 300 + 1 000 | 47 % |
| G4 herald's boats | 710 | ~3 500 | 20 % |
| Ambush (0 s / +30 s) | 660 + Hush ~700 / 1 800 total | ~3 600 + Aldra + Seraphine + Dacian ~600 + Vessa | 30 % / 38 % (the danger is Dacian's HP, not the army) |
- The barricade is a siege check (Frost Mortar range 13 > the spire's 11; the G1 archers shoot over the wall); W2 arrives
  during it to punish an all-in.
- The ambush is a **protect** check: Hush's Blink Strike on Dacian every 10 s; the answers are a Shardguard at his side, Glass
  Aegis (Aldra) on him, Rime Aegis, Flash Freeze on Hush (half duration on a hero).
- Watch in the first playtest: if Dacian dies in > 30 % of runs, give him a 3 s `braced` at the ambush start.

## Acceptance checks
1. A scripted headless run on normal (Mortars on the barricade, Citadel, Aldra, rock, 3 clues, duel, ambush) ends
   `victory=true` in **18-24 game-minutes** in 3 / 3 runs.
2. A clue channel refuses while an enemy is within 8 m and completes in 4 s once clear; leaving 3 m resets it.
3. The duel stops both duellists the instant one drops below 75 % (no damage after: a Rime Bolt in flight is cancelled);
   soldiers cannot enter the ring; a 90 s stalemate calls a draw.
4. Hush never dies: at 25 % she reaches her boat and leaves; a Shardguard within 2.4 m of Dacian stops her Blink Strike and
   freezes her 0.5 s (unit test).
5. During the truce, side-0 attack-moves never target Vessa or Aurivane units, and they never target side 0.
6. The keep card shows Shardguard (C) and Call Aldra (V) only from the Citadel; Aldra's call price is 250 + 100 / 30 s here.
7. Every line <= 96 characters; every WAV fits its slot.

## Implementation tasks (proposed ids)
| Id | Owner | What | Done when |
|---|---|---|---|
| E7M2.S1 | systems | `missions/mission_e7_02.tscn` + `MissionE7_02` on `two_harbours.map`: empty seats 1 and 3 (decor), the barricade building (passable gate for ENEMY, wall for side 0), island Ember Spire, the 3 clues (`MissionBrazier` channel variant: 3 m, 4 s, enemy-within-8 m refusal), strongboxes, the duel ring push, start state, trade overrides (posts 1:00), tiers / helper switches and Aldra's mission price, the no-save fallback | `tests/test_e7m2_s1.gd`: start state; clue refusal and completion; the barricade blocks side 0 and passes ENEMY |
| E7M2.S2 | systems-high [H] | Objectives and events E1-E20, waves W1-W4 / relief / ambush, the truce flag (D8: mutual non-targeting for a set of units, `MissionBase.set_truce(units, on)`), the duel rules 6.4 (75 % stop, cancel in-flight damage, draw at 90 s), win / lose, difficulty, `MISSION_REWARDS[&"e7m2"]`, `helper_aldra_unlocked` | `tests/test_e7m2_s2.gd`: duel stop and draw; Dacian's death = defeat; a scripted run wins |
| E7M2.G1 | gameplay | `hush_story` boss numbers and the flee-to-boat rule; `dacian_story` duel brain (cleave in arc, Second Wind); `herald_story` (NPC, invulnerable); `helpers_enabled` + Aldra's kit in a mission scene; the Shardguard's Hold the Line also stops `hush_blink` | Unit tests |
| E7M2.A1 | ai | Profile `mission_e7_02_enemy`; Commander pause on the truce; a story brain for Vessa in the ambush (nearest knife / Hush only) | Vessa never targets side 0 during the truce |
| E7M2.U1 | ui | Clue counter with the 3 names (ticked), duel HP bars for both duellists with the 75 % line, `obj_dacian` marker, Aldra's portrait / F4, the Citadel and call hints | UI Lab screens |
| E7M2.C1 | systems-high | `e7m2_morning`, `e7m2_herald`, `e7m2_laurel_call`, `e7m2_knives`, `e7m2_mask` + skip end states; StoryFlow -> `c_e7_mask` | `cine check` 0 FAIL |
| E7M2.V1 | tech-artist | Sun Barricade (gilded timber and sun-disc shields; 3 damage states), bettors' boats and strongboxes, the four clue props (cloth-covered bodies, the ledger on the box rail, the herald's hiding spot), Hush's black boat, the white-mask prop, the Laurel ring wall decal; Aldra's game model and arrival (TH.V3-V5) if not built | 0 lights, Art Lab pass |
| E7M2.O1 | Voice Forge agent | Render the 33 lines | Every WAV fits |
| E7M2.D1 | game-designer | Read the lines in game; write `c_e7_mask` (1:10) | Script done |
| Lead | lead | Acceptance checks 1-7 | All pass |
Dependencies: everything of e7m1; the helper code (step TH) and the Shardguard (TH tier-3 units); `MissionBrazier`; 19.C1 for
the cutscenes only.

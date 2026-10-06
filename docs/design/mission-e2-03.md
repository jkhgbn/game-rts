# Campaign mission e2m3: "The Salt Road" (Vessa vs Malrik, the Magpies on the road)

Task: script for `campaign-outline.md` 3.2 row 3 (the Ep2 outline, "next up" after section 6). Episode 2 "The Light
Below", mission 3 (id `e2m3`, outline D6). Plays right after `c_e2_lodge` "The Price of the Road" (`mission-e2-02.md`
"Cinematic hooks"). The trade mission: **gold, the Bazaar, caravans, the Magpies, the Greywater Lodge**, and Vessa's
**Ember Boar** with the Stables. Target **18-24 min** on normal. Uses the rules of `mission-01.md` / `mission-e2-01.md`
(MissionBase, scripted groups, 70 % rule, difficulty multipliers), `market-trade.md` (sections 2-6 and 10: the first
campaign use it proposed), `cavalry-mounts.md` (2, 4, 6 and 12), `tiers.md` 6, `t3-helpers.md`, `items.md` campaign
rules, `champions.md` 11. New scene `missions/mission_e2_03.tscn` + script `scripts/campaign/mission_e2_03.gd`
(`MissionE2_03 extends MissionBase`, mission id `e2m3`). Metres, seconds, `m:ss` since the navmesh was ready; positions
`(x, z)`, `y = 0`, `+z` = south. Recommended option taken everywhere (no open questions).

## 0. Decisions (recommended option taken)
| # | Question | Decision | Why |
|---|---|---|---|
| D1 | Which map | The **Crown Hollow 1v1 layout** (its constants: river, crossings, ring road, 4 trading posts, 2 Dens, 2 Lodges, base slots) with a new tree / rock seed **`MAP_SEED := 1404`** and a **salt-marsh dressing**: "the Saltmarch". The central isle is **the Salt Tor** (a dry salt hill with a ruined toll-beacon: no crown, no pedestal, no Ruin Wardens) | The trade system is built and tuned on this layout (`market-trade.md` 2: posts, doors, ambush spots, route values); a new trade map would re-tune all of it. The dressing stops it reading as Crown Hollow (Ep1's finale) |
| D2 | Teams | Today's 3 teams: `PLAYER` (Fire), `ENEMY` (Malrik's bot), `NEUTRAL` (Magpies). **No step 20 needed** | Torvald is not here (he holds the north after e2m2's Vice); a 1v1 trade fight is the clearest first look at trade |
| D3 | "Run 6 gold caravans to the Hunters' Lodge" | **Tribute runs**: a caravan loads **250 gold** from Vessa's bank at the Bazaar and walks the ring road to the **north-west Greywater Lodge** door; 6 delivered = the Lodge's price paid (1 500 gold). Gold comes from normal trade, loot sacks and the Lodge's Magpie bounty | Gold is earned the skirmish way (the lesson), then spent on a goal the player watches cross the map (the escort). The Lodge stands **beside the Magpie Den** (`market-trade.md` 2.3): the last 10 m are the thieves' doorstep |
| D4 | What the Lodge sells | Its **deep-road map and two guides**: the old Warden roads under Emberfall, the Sunrise Road of e2m4 | `c_e2_lodge` beats; e2m4 needs a reason Vessa knows the way down |
| D5 | Trade timing in this mission | Posts open at **1:30** (skirmish 4:00); Magpie bands from **3:00** (5:00), tick **60 s** (75); worker raids from 8:00 (unchanged); Lodge contracts from **2:00** (5:00); the gold rules, route values and wares otherwise as `market-trade.md` | An 18-24 min mission cannot wait 4 minutes for its main system; the thieves must show up while the player still learns the road |
| D6 | Cavalry and the mount | `cavalry_enabled = true`: the **Ember Stables** (175, needs a Hall) train the Blaze Rider (Z) and sell Vessa's **Ember Boar** (X: 150 crystals **or 150 gold**, level 3). The Ember Hall card becomes the cavalry one (Z Flame Guard, X Ember Archer, C Ash Hurler, B Pyre Adept, N Cinder Arbalest). `titans_enabled = false` (no Lair) | `cavalry-mounts.md` 12 proposed the Stables and the Boar for the trade chapter; the Boar is the tool for chasing loot sacks (D8) |
| D7 | Pell | **Present** (Ruin Peddler at `(-22, -22)`, open at 0:00, also sells the Bazaar's exchange) whatever `m1_peddler_freed` says; the flag changes only his first line (L5 / L5b) | e2m1 D8: "he returns in e2m3"; `c_e2_lodge` shows him joining Fire |
| D8 | Stolen tribute | A tribute caravan that dies drops **all 250 gold** as a loot sack (mission rule; normal caravans drop 50 %); Magpies snatch **60 each**. A sack lives **45 s**: Vessa on the Ember Boar (6.6 m/s) can reach one 30 m away in time | Losing a tribute is recoverable, which makes chasing thieves a choice, not a punishment |
| D9 | Tier and Old Vey | Keep starts as a **Stronghold**, Citadel from 5:45, **Call Old Vey** 300 + 150 essence, 45 s (the Ep2 price, `mission-e2-02.md` D6) | Same ladder in every Ep2 mission |
| D10 | Mission name and id | `e2m3`, `mission-e2-03.md`, `missions/mission_e2_03.tscn`, `scripts/campaign/mission_e2_03.gd`, `CampaignState.MISSION_SCENES[&"e2m3"]`, in `MISSION_ORDER` after `e2m2` | Outline D6 |

## Story setup (briefing text, 3 short paragraphs)
1. The three relics point down, under Emberfall, along roads nobody living has walked. Nobody but the Greywater
   hunters, who mapped the deep for a hundred years and have never sold the map.
2. They will sell it now, for gold: six wagons of it, delivered to their Lodge's door at the far end of the Salt Road.
   Their neighbours across the road are the Magpies, who steal for a living. Malrik's men have started charging tolls.
3. Fire has never needed gold. Fire has crystals, and a short temper. Pell says that is a fine start for a merchant.
Briefing objectives: `obj_tribute`, the rules `Vessa must survive` and `The Emberwatch must stand`, and the line
`Build a Bazaar, send caravans to the trading posts, then send tribute to the Greywater Lodge.`

## Map: "The Saltmarch" (120 x 120, the Crown Hollow layout, **point-symmetric**, `MAP_SEED := 1404`, river on)
Everything below is the 1v1 Crown Hollow constant unless marked **mission**. Clearings: no tree or rock inside the radius.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / Fire keep "Saltwatch" | `(-36, 36)` / `(-43, 43)` | 18 | Pre-built, complete, **Stronghold** (3 000 HP) |
| Ember Hall / Hearths / Ember Spire | H1 `(-27, 45)` / V1 `(-50, 46)`, V2 `(-50, 52)` / S1 `(-37, 29)` | map | Pre-built, complete |
| Extra Ember Spire (if `e2m2_points_held`) | `(-46, 12)` on the west road, 4 m off the corridor | 3 | **mission**, pre-built |
| Home nodes / natural / rich | `(-46, 34)`, `(-34, 46)` / `(-16, 6)` / `(-40, -40)` | map | Skirmish amounts; the rich node is 15.8 m from the Lodge (a Magpie worker spot W2 covers it) |
| Bazaar slot M1 / Stables slot T2 | `(-45, 27)` / `(-55, 37)` | map | The natural spots (`market-trade.md` 4.1, `cavalry-mounts.md` 2.1) |
| Ring road | hub `(-36, 36)`, `w_door (-49, 1)`, `nw1 (-48, -44)`, `nw2 (-44, -48)`, `n_door (1, -49)`, and the mirrors | 2.5 corridor | `market-trade.md` 2.1 |
| Trading posts | Heron Ford `(-53, 1)` door `(-49, 1)` (near) · Millstone Cross `(-1, 53)` door `(-1, 49)` (near) · Saltgate `(1, -53)` door `(1, -49)` (far, Malrik's near) · Lantern Wharf `(53, -1)` door `(49, -1)` (far) | 5 | Open at **1:30** (D5) |
| **Greywater Lodge (north-west)** "the Old Lodge" | centre `(-45, -55)`, door `(-45, -51)` | 6 | **The tribute target**. Bettany Crook speaks for it (story NPC at the door, invulnerable, not selectable) |
| Magpie Den (north-west) | centre `(-55, -45)`, door `(-51, -45)` | 6 | 8 m from the Lodge door: the thieves' doorstep |
| Lodge / Den (south-east) | `(45, 55)` / `(55, 45)` | 6 | As the skirmish (contracts may leave from either Lodge; tribute only counts at the north-west one) |
| **Tribute route** | Bazaar -> `w_door` -> `nw1` -> `nw2` -> Lodge door | - | **mission**; ~80 m from M1; ambush spots A1 `(-44, 15)`, A3 `(-48, -22)` and the Den door on the way |
| **Malrik's Tollgate** | Night Spire `(-43, -25)` + guard ring r 4 | 4 | **mission**: appears at **6:00** (E8), 5.5 m east of the road between `w_door` and `nw1`, 3 m from ambush spot A3 |
| The Salt Tor | `(0, 0)`, the isle (r < 11) | map | **mission dressing**: a salt hill, a ruined toll-beacon, no crown, no wardens; the 4 crossings unchanged |
| Ruin Peddler "Pell" | `(-22, -22)` | 5 | Open at 0:00 (D7). The south-east peddler `(22, 22)` is closed decor |
| Taverns | `(-15, -15)`, `(15, 15)` | map | **Closed** decor (`tavern_enabled` false) |
| Lost Caches | `(-30, 0)`, `(0, 30)`, `(30, 0)`, `(0, -30)` | 3 | `items.md` loot, appear at 2:00, reopen 180 s |
| **Malrik's base** | Dusk Keep `(43, -43)`, Gloom Hall `(27, -45)`, Night Spire `(37, -29)`, Hovels `(50, -46)`, `(50, -52)`, Gloom Bazaar M1 `(45, -27)` | map | His bot trades on Saltgate / Lantern Wharf (his near posts) |
| Wave spawns | Shadow: the Gloom Hall spawn (else the Dusk Keep's, else `(56, -56)`) | - | - |
Distances (navmesh, approx.): Bazaar M1 -> Lodge door 80 m (a loaded caravan ~22 s); Bazaar -> Millstone Cross door 49 m;
Gloom Hall -> Tollgate 72 m; Dusk Keep -> Saltgate door 50 m. Generator check (E2M3.S1): with seed 1404 every listed
clearing and the road corridors hold; the Tollgate spire is >= 4 m from the corridor; a path exists from `PLAYER_START` to
each post door, both Lodge doors, the Tollgate and the Dusk Keep.

**Look** (E2M3.V1): bright cold winter noon, sun `(1.0, 0.97, 0.90)` energy 1.1, ambient `(0.60, 0.60, 0.62)`; ground
salt-white crust `(0.88, 0.86, 0.80)` broken by brown marsh grass, pools of black brine; the river (the Brine) grey-green;
the road ruts dark and wet; leaning salt-cairn markers every ~15 m along the ring road (cheap instanced decor); the Salt
Tor a white mound with a broken beacon tower. The Lodge has a hide-and-antler gable and lantern posts; the Den, washing
lines of stolen cloaks.

## Tribute (mission rule; systems)
| Rule | Value |
|---|---|
| Order | Bazaar card slot **X `Send tribute (250 gold)`** (Z stays Train caravan). Takes the first idle caravan at the Bazaar, else the next one to come home (queued: `Tribute: next caravan home`). Refusals in order: `"No Bazaar"`, `"Not enough gold"`, `"No caravan"`, `"Tribute already on the road"` (**one tribute at a time**) |
| Load | Spends 250 gold from the `GoldBank` at once (`spend`, reason `&"tribute"`); the caravan gets a red-gold banner and the modifier `cargo:load` (3.6 m/s) |
| Route | Bazaar -> `w_door` -> `nw1` -> `nw2` -> Lodge door (waypoints, `command_move`, never attack-move); the player may still move it by hand (it keeps its cargo; G / right-click on the Lodge resumes) |
| Pay | 2 s at the Lodge door: `obj_tribute` +1, floating `-250` in gold over the Lodge, message `The Greywater Lodge takes the tribute (2 / 6)`; the caravan walks home empty and resumes its normal route |
| Lost | A tribute caravan that dies drops a **250 gold** loot sack (D8); a Magpie snatch takes `min(cargo, 60)` per Magpie as `Caravan.steal`. Whatever the player picks back up returns to the bank; a new tribute must be sent from the Bazaar |
| Magpie weighting | A loaded tribute caravan adds **+200** to the weight of the tribute route (`market-trade.md` 5.2), so bands love it |
| Lodge reward on top | The normal 10 gold per Magpie killed (`market-trade.md` 6.3) |
The tribute caravan counts toward the 6-caravan limit. The objectives panel shows `Tribute on the road: 63 m to the Lodge`
and a gold dot on the minimap.

## Start state (from the campaign save, Vessa's track)
Order in `_on_navigation_ready`: spawn Vessa -> `CampaignState.open(...).apply_to_start(self)` -> companion -> flag
branches -> story NPCs (Pell, Bettany) -> scripted groups -> the trade services (`TradeNetwork.setup` with the mission
times of D5).
| Item | Value |
|---|---|
| Vessa | **Level 4 with 3 unspent spell points** (Fireball r1 known), **cap 8** |
| Artifacts / items | From the save: the 3 relics owned, 2 equipped (choice screen); the 6 slots |
| Essence / crystals / gold | Essence **150** + carried (cap 1 500); crystals **450** (easy 550, hard 350); gold **0** |
| Buildings | Keep (Stronghold), Ember Hall, Ember Spire, 2 Hearths (+ the west-road spire if `e2m2_points_held`) |
| Units | 6 Cinder Hands gathering (3 / 3); **6 Flame Guards, 4 Ember Archers, 2 Blaze Riders, 1 Kilnwarden** at `(-32, 32)` (1 450 crystals of army); the companion (if saved) |
| Population | 6 + 6 + 4 + 4 + 2 = **22 / 60** (+ the companion's 2) |
| Old Vey | Not on the field (he rides ahead to Emberfall to open the old stair: L4). Callable at the Citadel |
| Story NPCs | **Pell** at his peddler cart `(-22, -22)`; **Bettany Crook** at the Lodge door (both invulnerable, not selectable; Bettany shows a speech bubble icon when Vessa is within 12 m) |
| Malrik's side | Dusk Keep, Gloom Hall, Night Spire, 2 Hovels, **Gloom Bazaar** (pre-built), **6 Gloom Thralls**, **2 caravans** (they start trading at 1:30), **6 Shades + 3 Nightbolts** at the rally `(30, -30)`; **Malrik level 5** (Lance r2, Siphon r2, Shroud r1) |
| No save / Ep2 not reached | Crown + Signet equipped, Orb owned; empty slots; essence 150 + **600**; no companion; flags false; `helper_vey_unlocked` true |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Hearth, Ember Hall, Ember Spire, **Ember Bazaar** (B then B, max 1, within 20 m of the keep), **Ember Stables** (B then N, max 1) | Forge / Sanctum (e2m4), Lair, walls |
| Units | Cinder Hand; Ember Hall **Z Flame Guard, X Ember Archer, C Ash Hurler, B Pyre Adept, N Cinder Arbalest** (the cavalry card: the Blaze Rider moves to the Stables, `cavalry-mounts.md` 2.1); Stables **Z Blaze Rider**; Bazaar **Z Caravan**, **X Send tribute**; keep B Kilnwarden, **C Ashveil Saboteur** (Citadel) | Scorchbow, titans |
| Mount | **Ember Boar** at the Stables (X, 150 crystals or 150 gold, Vessa level 3+), Barding (C, 200, level 5) | - |
| Keep | Citadel (X, 300, 90 s, from 5:45) | - |
| Helper | Old Vey (V) at the Citadel, 300 + 150 essence, 45 s, pop 4 | - |
| Trade | Gold, the 4 posts, wares (Iron-shod Axles, Masons' Charter, Tempered Steel, Quilted Gambesons), the exchange, Lodge contracts (Outriders 120, Sweep 100), loot sacks | - |
| Spells / items | Fireball, Ember Step, Kindle; cap L8 · base shop (keep, Ember Hall), Pell's stock | Champions (taverns closed; the companion reads bounty flags), camps, beasts, capture points |

## Tiers and the helper
| Item | Value |
|---|---|
| Code | `MissionE2_03._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = true`, `helpers_enabled = true`, **`trade_enabled = true`**, **`cavalry_enabled = true`**, `titans_enabled = false`, `research_enabled = false`, `tavern_enabled = false`, `camps_enabled = false`, `points_enabled = false`, `beasts_enabled = false`, `river_enabled = true`; `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(2)` on both keeps |
| Keep card | The e2m1 card (Z Cinder Hand · X Citadel · C Saboteur · V Call Old Vey · B Kilnwarden) |
| Old Vey | `helper_vey` at Vessa's level; Escort; his Lunge hits the first Magpie that touches a caravan he escorts (brain: a stance-Escort helper also treats a Magpie within 10 m of Vessa as a threat) |
| Saboteur here | Max 4. **Eavesdrop** reads Malrik's Gloom Hall and Gloom Bazaar queues; Powder Charge on the Tollgate spire (720 HP) or Malrik's Bazaar (stops his caravans 10 s) |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_bazaar` | Primary (tutorial step) | `Build an Ember Bazaar and send caravans to a trading post` | The first caravan delivery of the player (any post) |
| `obj_tribute` | Primary | `Pay the Greywater Lodge: deliver tribute (0 / 6)` | 6 tribute deliveries |
| `obj_guides` | Primary (appears at the 6th tribute) | `Hold until the Lodge's guides reach you (1:30)` | The countdown ends with the Bazaar or the keep standing and Vessa alive |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `obj_keep` | Primary, always shown | `The Saltwatch must stand` | Fails = defeat |
| `sec_magpies` | Secondary (appears at the first band, E6) | `Hunt the Magpies for the Lodge (0 / 8)` | 8 Magpies killed by the player (any source credited to `PLAYER`) |
| `sec_raid` | Secondary (appears at E7) | `Take 300 gold from Malrik's caravans (0 / 300)` | 300 gold from loot sacks dropped by Malrik's caravans, picked up by the player's units |
| `sec_toll` | Secondary (appears at E8) | `Break Malrik's Tollgate` | The Tollgate Night Spire destroyed (both times if it is rebuilt: the counter shows `1 / 2`) |
States through `Events.objective_changed(id, state)`: `"active"`, `"done"`, `"failed"`.

## Guards, waves and AI (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units: team `ENEMY`, group `"scripted"`, not controlled by the Commander; guards hold their spot with
auto-aggro and a 2x leash. Waves attack-move as listed, refreshed every 3 s when the order says "then".
| Group | Where | Units | Value |
|---|---|---|---|
| G1 Saltgate watch | `(6, -44)`, beside Malrik's near post | 3 Shades + 2 Nightbolts | 440 |
| G2 Tollgate (from E8) | Ring r 4 around `(-43, -25)` | Night Spire (720 HP) + 4 Shades + 2 Nightbolts + 2 Grave Hounds | 660 + spire |
| G3 Wharf watch | `(44, -6)`, beside Lantern Wharf | 2 Shades + 1 Shadow Knight | 420 |
| Wave | Trigger | Units | Order |
|---|---|---|---|
| W1 probe | 3:30 | 3 Shades + 2 Grave Hounds (380) | Attack-move to the Ember Bazaar (else the Ember Hall) |
| Road raids | Every **150 s** from 4:30 | 2 Grave Hounds + 1 Shade (220) | Attack-move to the nearest **loaded** player caravan on the road, else the nearest player caravan, else a Fire worker |
| W2 post grab | 7:30 | 4 Shades + 2 Nightbolts (520) | Walk to **Millstone Cross** and hold its door (12 m: the post is held by the enemy, `market-trade.md` 2.2) until killed; Malrik's bot also routes a caravan there |
| W3 strike | 11:00 | 5 Shades + 3 Nightbolts + 1 Shadow Knight + 1 Gloom Deacon (1 110) + **Malrik** | Attack-move to the Ember Bazaar, then the Ember Stables, then Vessa |
| Tollgate rebuild | 12:00, only if the Tollgate fell before 11:00 | The Night Spire again (built in 20 s, VFX) + 3 Shades + 2 Nightbolts (440) | Hold as G2 |
| W4 Reprisal | `obj_guides` starts | 0 s: **Malrik L6** + 6 Shades + 3 Nightbolts + 2 Shadow Knights (1 300); 45 s: 4 Grave Hounds + 2 Nightbolts (480) | Attack-move to the Ember Bazaar, then Vessa; refreshed every 3 s |
| Withdraw | `obj_guides` done | Every scripted Shadow unit and Malrik | Walk to the Dusk Keep; despawn there |
Rules: if `sec_toll` is done, the road raids lose their Shade; if `sec_raid` is done, W4's second group is skipped
("his purse is empty"). Malrik respawns **60 s** after a death at the Dusk Keep (`Malrik has fallen back into the
shadows`); he stays at his rally except in W3 and W4.
**The bot** (`ai.md` + `ai_trade.gd`, profile `mission_e2_03`): Shadow normal knobs, `min_attack_pop` 99, workers 6, no
expansion, no towers beyond S1, up to 10 soldiers at `(30, -30)`, **trade on**: Bazaar pre-built, `caravan_target` **4**,
routes Saltgate and Lantern Wharf (near), never the far west posts; no Lodge contracts; never rebuilds the Tollgate itself
(the mission does). The Commander ignores every `"scripted"` unit and building.
**Magpies** (`ThievesGuild`, both Dens): the D5 times; cap 6 alive; the tribute weighting; band size 2, 3 from 9:00, 4
from 14:00 (mission: 12:00 / 15:00 in the skirmish).
**Greywater Lodge contracts** (the player's, key U): Outriders 120 / Sweep 100 gold, from 2:00 (D5), rules unchanged.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cinematic `e2m3_road` (HOLD 0:18); camera on Vessa; L1-L3; `obj_bazaar`, `obj_tribute`, `obj_vessa`, `obj_keep` active; hint `Build an Ember Bazaar: select a Cinder Hand, press B then B. It must stand within 20 m of the keep.` (10 s) |
| E2 | 0:25 | L4 (Old Vey leaves by the south-west edge `(-58, 58)`); if `e2m2_points_held`: L4b |
| E3 | Vessa within 12 m of Pell (first time) | L5 (L5b if `m1_peddler_freed` is false) |
| E4 | Bazaar complete | L6; hint `Train caravans (Z). They walk to a trading post and bring back gold. Far posts pay more, but the road is longer.` (10 s) |
| E5 | 1:30 | Posts open (message as the skirmish, `The trading posts open their gates`) |
| E6 | First Magpie band leaves (~3:00) | L7-L8; `sec_magpies` active; hint `Magpies rob loaded caravans. Escort them, hire Outriders at the Lodge (U), or chase the loot sack before it fades.` (10 s) |
| E7 | First caravan delivery (any post) | `obj_bazaar` done; L9; `sec_raid` active; hint `Send tribute from the Bazaar (X) once you have 250 gold.` (8 s) |
| E8 | 6:00 | The Tollgate rises (Night Spire built in 20 s at `(-43, -25)`, G2 spawns); L10-L11; `sec_toll` active |
| E9 | Ember Stables complete | L12; hint `Buy Vessa's Ember Boar at the Stables (X). Use the Mount button: she rides fast but cannot fight from the saddle.` (10 s) |
| E10 | First tribute delivered | Cinematic `e2m3_lodge` (PAUSE 0:15): L13-L14 |
| E11 | A tribute caravan dies or is robbed (first time) | L15 |
| E12 | Vessa picks up a loot sack while mounted (first time) | L16 |
| E13 | 5:45 / Citadel complete / Old Vey arrives | The Citadel hint / L17 + the call hint / his arrival bark + L18 |
| E14 | W2 holds Millstone Cross | L19 |
| E15 | W3 launches | L20 |
| E16 | Tollgate destroyed (first / second time) | L21 / L22 |
| E17 | 3rd tribute delivered | L23 (Bettany) |
| E18 | 8th Magpie killed | L24; `sec_magpies` done |
| E19 | `sec_raid` reaches 300 | L25; `sec_raid` done |
| E20 | 6th tribute delivered | Cinematic `e2m3_paid` (PAUSE 0:25): L26-L28; `obj_tribute` done; `obj_guides` active (1:30 countdown); W4 launches |
| E21 | `obj_guides` done | 6 Greywater Trackers walk out of the Lodge to Vessa (story, `leave_map` at the end); Withdraw; L29-L30; `Events.mission_ended(true)` 4 s later; StoryFlow then plays `c_e2_stair` |
| E22 | Vessa dies | L31; defeat after 3 s |
| E23 | Fire keep destroyed | L32; defeat after 3 s |
The intended rhythm: Bazaar ~1:00, 3-4 caravans near by 3:00, the first band and the first lesson in escorting at ~3-5
min, the Stables and the Boar at ~5:00, the first tribute ~6:00, the Tollgate and W2 cut the west road and the south post
in the 6:00-10:00 middle, the Citadel and Vey ~8-10, W3 at 11:00, the last tributes 13:00-18:00, the Reprisal hold to the
end. A player who takes the far Saltgate route earns twice the gold per trip and feeds Malrik's G1 and the Magpies.

## Dialogue (36 entries: L1-L32 + 4 "b" lines; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist). Colours: Vessa `(1.0, 0.45, 0.1)`, Old Vey `(0.95, 0.95, 0.55)`,
Pell `(0.85, 0.75, 0.5)`, Bettany `(0.80, 0.65, 0.45)`, Captain Ashby `(0.95, 0.60, 0.35)`, Malrik `(0.7, 0.3, 1.0)`,
Narrator `(0.9, 0.85, 0.7)`. Names shown: `Vessa`, `Old Vey`, `Pell`, `Bettany`, `Captain Ashby`, `Malrik`, `Narrator`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | The Salt Road runs from Emberfall to the sea. Everything on it has a price, even the road. |
| L2 | E1 | vessa | Six wagons of gold. I don't own one wagon of gold. I own a lot of rocks. Shiny ones. |
| L3 | E1 | pell | Rocks become gold at a post, my queen. Gold becomes everything else. Trust a professional. |
| L4 | E2 | vey | I'll ride to Emberfall and find the old stair. Pay the hunters, then call me. |
| L4b | E2 (`e2m2_points_held`) | ashby | Built you a tower on the west road, my queen. Learned that at the Millwatch. |
| L5 | E3 | pell | You again! The fire one. Last time you let me out of a cage. Today I let you into a market. |
| L5b | E3 (`m1_peddler_freed` false) | pell | You again! You left me in that cage, you know. I escaped. On my own. Thank you for asking. |
| L6 | E4 | pell | A Bazaar! Look at it. Smell it. Now put wheels on something and send it somewhere far. |
| L7 | E6 | bettany | Heads up, Firelady. The Magpies are out. They like their caravans full and their guards absent. |
| L8 | E6 | vessa | Bettany? I thought your tavern burned down. |
| L8b | E6 (continues) | bettany | It did. The Lodge pays better, and nobody here throws fire at the furniture. |
| L9 | E7 | pell | Gold! Your first gold. I'm not crying. It's the salt. |
| L10 | E8 | malrik | Every road charges a toll, Vessa. This one charges you. |
| L11 | E8 | vessa | A tollbooth. You built a tollbooth. That is the most Malrik thing you've ever done. |
| L12 | E9 | vessa | A boar? I asked for a horse. ... Okay, he's beautiful. His name is Sir Crackle. |
| L13 | E10 (`e2m3_lodge`) | bettany | One wagon. Five to go. The hunters count slow and they count twice. |
| L14 | E10 (`e2m3_lodge`) | vessa | What do they even want all this gold for? |
| L14b | E10 (continues) | bettany | Arrows, mostly. And never having to go down there again. |
| L15 | E11 | pell | They took the tribute! Get it back! That gold has my fingerprints on it! |
| L16 | E12 | vessa | Got it! Sir Crackle, you magnificent pork chop! |
| L17 | E13 | vessa | Vey, the Citadel's lit. The stair can wait. I've got thieves. |
| L18 | E13 | vey | Thieves AND a toll? Girl, you do know how to throw a party. |
| L19 | E14 | ashby | Shades sitting on Millstone Cross, my queen. No caravan's getting through there. |
| L20 | E15 | malrik | If I can't have the deep road, nobody walks it. Burn the market. |
| L21 | E16 (first) | vessa | Toll's paid. In fire. Keep the change. |
| L22 | E16 (second) | vessa | You rebuilt it?! You rebuilt the tollbooth? |
| L23 | E17 | bettany | Halfway. The old hunters are starting to like you. Don't let it go to your head. |
| L24 | E18 | bettany | Eight Magpies. The Lodge remembers who clears its road. |
| L25 | E19 | pell | Robbing Malrik's wagons! You're a natural. I've never been prouder. |
| L26 | E20 (`e2m3_paid`) | bettany | Six. Paid in full. Here's your road down: a stair under Emberfall, the Sunrise Road. |
| L27 | E20 (`e2m3_paid`) | bettany | Two of ours will guide you. Nobody else has walked it since the Master. (6 s) |
| L28 | E20 (`e2m3_paid`) | malrik | A map to the deep. How generous. I'll take it off your body. |
| L29 | E21 | bettany | Guides are with you. Go before the Bishop buys the next one. |
| L30 | E21 | vessa | Pell, keep the Bazaar running. Fire just learned what gold is for. |
| L31 | E22 | vessa | Should have... ridden faster... |
| L32 | E23 | ashby | The Saltwatch is lost! Get the queen out! |
Every line <= 2 lines of the dialogue box (<= 96 characters), 5 s at the cast speeds (L27 6 s); L8 / L8b and L14 / L14b
play back to back (two box entries). Echoes: L2 is Vessa's humour at its height before the descent; L8b answers e2m1's
burnt Crooked Lantern; L12 names the mount (a running gag for Ep4's Vessa bot barks); L26 names the next mission; L27
seeds e2m4's "nobody since the Master"; L28 keeps Malrik in the race down (e2m4, e2m5).

## Cinematic hooks
| id | Kind | When | Content | Owner |
|---|---|---|---|---|
| `c_e2_lodge` | stage film 1:00 (e2m2's hook) | Before the briefing | The price of the road | - |
| `e2m3_road` | ENGINE, **HOLD** 0:18 | E1 | 3 shots: CRANE along the salt-white ring road from the Fire base to the north-west corner, salt cairns passing (L1); MS Vessa at the keep, Pell's cart rattling in behind her (L2, L3); WS of the Lodge's antler gable and, across the road, the Den's washing lines of stolen cloaks, two Magpies watching from the roof | four-wizards-high (cine) |
| `e2m3_lodge` | ENGINE, **PAUSE** 0:15 | E10 | 2 shots: MS Bettany at the Lodge door counting coins into a hunter's hand (L13); two-shot Vessa (if within 20 m; else Bettany alone with a hunter) (L14, L14b) | four-wizards-high |
| `e2m3_paid` | ENGINE, **PAUSE** 0:25 | E20 | 3 shots: CU an old hide map unrolled on a barrel, a stair drawn under a burnt observatory, a white-gold sun drawn at the bottom (L26); MS two Greywater Trackers shouldering packs (L27); WS from the Tollgate side: Malrik's army forming up, Malrik looking at the Lodge (L28) | four-wizards-high |
| `c_e2_stair` "On the Way Down" | stage film **1:30** (outline 3.2) | After victory | Beats for its writer: night at the Emberfall watch-keep (the `forge_watch_keep` set, M0's courtyard); the old stair under the observatory, unsealed; Vey and Vessa at the top step, the Greywater guides lighting lanterns below; **Vey's story, half of it**: he was the Master's sword "before the four", he stood behind the throne when kings still knelt; the lightning: "It's his storm, not mine. He lent it to me to keep you four alive." Vessa: "And when were you going to tell me?" Vey: "On the way down." (paying off ep1 V5); Ysolde's message by Wren: Nature's army will follow them down; the last shot: the stair descending into a faint white-gold glow | game-designer (script) + four-wizards-high |
Fallbacks: `e2m3_road` = the camera on Vessa + L1-L3; `e2m3_lodge` / `e2m3_paid` = their lines as dialogue (L26-L28 with a
2 s camera pan to the Lodge). The end state is identical on skip (the counter, `obj_guides`, W4 launched).

## Win / lose
| Event | Result |
|---|---|
| `obj_guides` done | **Victory** |
| Vessa dies | **Defeat** (instant) |
| Fire keep destroyed | **Defeat** |
| The Bazaar destroyed | Not a loss: rebuild it (the gold bank is kept; a tribute on the road continues) |
| All caravans dead | Not a loss: train more (75 crystals each) |
| Malrik killed | Not a win: 60 s respawn |
| Malrik's base destroyed | Allowed: his caravans and the bot stop, scripted waves still come from `(56, -56)`; the Lodge's price is unchanged |

## Reward carried to e2m4
- No new artifact. Gold is not carried (`market-trade.md` 10); the 6 slots; essence 50 %, cap 1 500, **+150 first if
  `sec_magpies`**, **+300 first if `sec_raid`**, **+150 first if `sec_toll`**.
- The **Ember Boar** is not carried (mounts are per mission, `cavalry-mounts.md` 6.1); Vessa can buy it again where Stables
  exist. The companion: the champion rule.
- `CampaignState.MISSION_REWARDS[&"e2m3"] = {"flags": {"e2m3_magpies_hunted": "sec_magpies", "e2m3_malrik_robbed":
  "sec_raid", "e2m3_toll_broken": "sec_toll"}, "bonus_essence": {"sec_magpies": 150, "sec_raid": 300, "sec_toll": 150},
  "set_flags": {"e2m3_lodge_paid": true}, "next": &"e2m4"}`.
- Later hooks: `e2m3_lodge_paid` = in **e2m4** two Greywater guides walk with Vessa (each hall's layout revealed on entry);
  `e2m3_magpies_hunted` = in e2m4 a third guide and the Lodge's deep lanterns (**+2 sight** for Vessa's army in the dark);
  `e2m3_malrik_robbed` = in **e2m5** Malrik's bot starts with **-300 crystals and 2 fewer Shadow Knights**;
  `e2m3_toll_broken` = Pell's line in e2m5's briefing card (no gameplay).
- Level not carried.

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6, no Knight in W3, no Deacon | as written | x 1.4 |
| Start crystals | 550 + 2 extra Flame Guards | 450 | 350 |
| Tribute | 6 x **200** | 6 x 250 | 6 x **300** |
| Magpies | First band 4:00, cap 4 | 3:00, cap 6 | 3:00, cap 6, band +1 from 9:00 |
| `obj_guides` | 1:00 | 1:30 | 2:00 |
| Malrik | L4 (W4 L5) | L5 (W4 L6) | L6 (W4 L7) |
| Old Vey call | 250 + 100 | 300 + 150 | 350 + 200, 60 s |
| Expected time | 15-19 min | 18-24 min | 22-28 min |
**Fight sizing (normal, <= 70 % of the army the player can have then).** Crystal income with 6-9 workers ~300-400 / min;
gold ~50-115 per minute per caravan.
| Fight | When | Enemy | Player army then (crystals) | Ratio |
|---|---|---|---|---|
| W1 | 3:30 | 380 | 1 450 + Vessa L4 | 26 % |
| G2 Tollgate | 6:00-10:00 | 660 + spire (720 HP) | ~1 900-2 300 | 29-35 % + the spire: a detachment fight |
| W2 holding the post | 7:30 | 520 | ~2 100 | 25 % |
| G1 Saltgate watch (far-route players) | any | 440 | >= 1 600 | <= 28 % |
| W3 | 11:00 | 1 110 + Malrik L5 | ~2 600 + Vey | 43 % |
| W4 Reprisal | ~16:00-20:00 | 1 780 + Malrik L6 | ~3 000 + Vey L6 | 59 % |
- Gold budget (normal): 1 500 tribute + Boar 150 (or crystals) + one Outriders 120 + ~250 lost to Magpies = **~2 000 gold**
  over ~15 minutes of trade = ~135 gold / min: 3 caravans on the near posts reach it, a far route reaches it faster and
  riskier, wares are the trap that delays the end. A player who buys Tempered Steel (350) and Gambesons (350) adds ~5 min.
- The intended answers: Outriders on the tribute (120 gold buys ~1.5 runs of safety), Vessa on the Boar riding beside the
  tribute and dismounting to Fireball a band; break the Tollgate with Blaze Riders + Kilnwarden Slag Rain on its guard;
  take Millstone Cross back with the army while the caravans use Heron Ford.

## Code reuse (recommendation to the lead)
`MissionBase`; the built trade stack (`TradeNetwork.setup` with mission times, `GoldBank`, `Market`, `Caravan`,
`ThievesGuild`, `HuntersGuild`, `LootSack`) and the step-13 Stables / mount code; `RuinPeddler` for Pell; `LostCache`.
New: the tribute order on the Bazaar card (a `Caravan` mission mode: a fixed waypoint list ending at a `GuildHouse` door, a
pay callback), the 100 % tribute sack rule, the tribute weighting hook in `ThiefBand` target selection (one extra weight
term a mission can set), the Tollgate build-and-guard sequence, Bettany as a talking prop at the Lodge door.

## Acceptance checks
1. `missions/mission_e2_03.tscn` loads headless with seed 1404; every road corridor and listed clearing holds; posts open at
   1:30, Lodge contracts at 2:00, the first Magpie band leaves at 3:00 (+-1 tick); the Tollgate rises at 6:00.
2. `Send tribute` refuses in order (`No Bazaar`, `Not enough gold`, `No caravan`, `Tribute already on the road`); with 250
   gold it spends 250, walks Bazaar -> `w_door` -> `nw1` -> `nw2` -> Lodge door, pays in 2 s and counts 1.
3. A tribute caravan killed drops a 250-gold sack; a Magpie snatch takes 60; a sack picked up by Vessa adds to the bank.
4. The Ember Hall card in this mission has no Blaze Rider; the Stables train it; the Ember Boar costs 150 crystals or 150
   gold and needs Vessa level 3; mounted Vessa moves at 6.6 m/s and does not auto-attack.
5. W2 holds Millstone Cross: player caravans routed there wait 45 s and go home empty (the held-post rule).
6. The 6th tribute plays `e2m3_paid`, starts the 1:30 hold and W4; the hold ends in victory with Vessa and the keep alive;
   skipping any cinematic leaves the same state.
7. Victory saves `MISSION_REWARDS[&"e2m3"]` with the 3 flags, the bonuses and `e2m3_lodge_paid`; gold is not saved.
8. A scripted headless run on normal (Bazaar, 3 near caravans, Stables + Boar, Outriders on each tribute, break the
   Tollgate, Citadel, Vey) ends `victory=true` in **18-24 game-minutes**; W1 leaves >= 11 of 13 start soldiers in 5 / 5
   runs; `PERF OK` with 12 caravans, 6 Magpies, trackers and W4 on the field.

## Done when (proposed ids; the lead adds them to `waves.md`)
- [ ] E2M3.S1 (systems): `missions/mission_e2_03.tscn` + `MissionE2_03` on the Crown Hollow layout with seed 1404 and the
  Saltmarch dressing hooks (no crown, no isle wardens, closed taverns and south-east peddler), pre-built Fire base at tier
  2 (+ the flag spire), Malrik's base with a Gloom Bazaar, the trade services with the D5 times, Pell and Bettany NPCs,
  start state via `apply_to_start` and the no-save fallback, the tribute order (refusals, load, route, pay, 100 % sack,
  one at a time), the switches of "Tiers and the helper". Test `tests/test_e2m3_s1.gd`: checks 1-3.
- [ ] E2M3.S2 (systems-high): objectives and events E1-E23 in order, the 36 lines, guards, W1-W4 / raids / the Tollgate
  rebuild / Withdraw, the `sec_toll` and `sec_raid` wave rules, the `sec_raid` gold counter (sacks from Malrik's
  caravans only), the Magpie size schedule and the tribute weighting, the win / lose table, the difficulty table,
  `MISSION_REWARDS[&"e2m3"]`, `MISSION_SCENES[&"e2m3"]`. Test `tests/test_e2m3_s2.gd`: checks 5-7.
- [ ] E2M3.G1 (gameplay): `cavalry_enabled` honoured in a mission scene (the cavalry Ember Hall card, the Stables, the
  Boar purchase in crystals or gold), the Magpie-as-threat rule for an Escort-stance helper. Test: check 4; Vey lunges at a
  Magpie hitting a caravan within 10 m of Vessa.
- [ ] E2M3.A1 (ai): profile `mission_e2_03` (Shadow normal, `min_attack_pop` 99, workers 6, max 10, trade on, caravan
  target 4, near routes only, ignore `"scripted"`); `ThiefBand` reads a mission weight term (the tribute +200). Test: the
  bot keeps 4 caravans on Saltgate / Lantern Wharf; with a loaded tribute on the road the next band targets its route.
- [ ] E2M3.U1 (ui): briefing, objectives panel (`2 / 6` tribute, the distance line, `0 / 8` Magpies, `0 / 300` gold, the
  Toll counter, the guides countdown), the Bazaar card's X `Send tribute (250 gold)` with its refusal tooltips, the
  tribute caravan's banner and minimap gold dot, Bettany's door bubble, speaker colours for `pell`, `bettany`, `ashby`;
  layout from ui-designer (`ui-trade.md` style).
- [ ] E2M3.V1 (tech-artist): the Saltmarch dressing (salt crust ground, marsh grass, brine pools, salt cairns, the Salt
  Tor mound and broken beacon, Lodge antler gable, Den washing lines), the tribute banner on the caravan, the Tollgate
  build VFX; `PERF OK`.
- [ ] E2M3.C1 (four-wizards-high): `e2m3_road`, `e2m3_lodge`, `e2m3_paid` as cine timelines; `cine check` 0 FAIL; fallbacks.
- [ ] E2M3.VO (Voice Forge agent): render the 36 lines (`data/voice/lines/e2m3.json`); no new speaker.
- [ ] E2M3.D1 (game-designer): read the lines in game once, trim any line over 2 box lines; write `c_e2_stair` (1:30,
  `episode2-opening.md` format) from the beats above.
- [ ] Lead: acceptance check 8; a save with no Ep2 progress starts on the fallback.

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Emberdart Harrier (spec change: Stables V; X stays the Ember Boar).
- **Why here:** Magpie bands (melee) and slow Shade raids on a caravan road; hit-and-run is strong against slow melee and workers.
- **Moment:** the first Magpie band (3:00) on caravan 1: "Emberdarts: throw and fall back. The Magpies chase you, not the wagon.".
- **Intro card:** `Emberdart Harrier. Javelins on a gallop: throw, turn, throw. Nothing on foot catches it.`

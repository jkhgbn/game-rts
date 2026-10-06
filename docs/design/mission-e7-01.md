# Campaign mission e7m1: "The Dragon Auction" (Torvald + Aldra, with Malrik; Episode 7)

Written 2026-10-02 (`campaign-outline.md` 3.7 row 1). Episode 7 "Gold for Fire", mission 1 of 4, the first **Ice** mission
of the story and the first mission played from the **north shore of the Coinwater**: Torvald (player, seat 2 "Adamarch
west") and Malrik (allied Shadow bot, seat 3 "Adamarch east") against Vessa (Fire bot, seat 0) and Ysolde (Nature bot,
seat 1) on the south shore. It plays right after `ep7_opening` (the 3:26 film of `episode7-opening.md`, "e7o"), on the
ground that film shows. Target **22-28 min** on normal. Uses the rules of `skirmish-1v1.md` (2v2 seat form of
`ai-2v2.md` 3.1), `levels.md`, `items.md`, `tiers.md` 6, `caster-units.md` 5.2, `kingdom-ice.md`, `market-trade.md` 3-4
(gold, Bazaar, caravans), `titans-2.md` 3 (dragon numbers), `map-fill.md` 2 and 4 (river, crossings, capture points) and the
format of `mission-01.md` / `mission-e3-01.md`. New scene `missions/mission_e7_01.tscn` + `scripts/campaign/mission_e7_01.gd`
(`MissionE7_01 extends MissionBase`, mission id `e7m1`, campaign-outline D6). Metres, seconds, `m:ss` since the navmesh was
ready; positions `(x, z)`, `+z` = south (Aurivane), `-z` = north (Adamarch). Status: **design only**; nothing is built.
Recommended option taken everywhere (no questions).

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map file | `data/maps/two_harbours.map` does **not exist yet** (2026-10-02: `data/maps/` holds crown_hollow, fourfold_hollow, gloamspine_divide, kinhearth_vale). Every map number below comes from the draft in e7o 7 (fourfold symmetry, canonical quadrant south-west) with the four seat frames applied by hand. The "Map" table is the **binding gameplay layer** that task **E7.M1** (was E5.M1) writes into `two_harbours.map`; e7m2 and e7m4 use the same table | The film and the missions must be the same ground at 1:1 (the Evenmead rule, e34. 7) |
| D2 | Seats | Player = **seat 2** (Adamarch west, keep `(-42, -66)`), Malrik = **seat 3** (Adamarch east, `(42, -66)`), Vessa = seat 0 (Aurivane west), Ysolde = seat 1 (Aurivane east). Side 0 = Torvald + Malrik in the seat API (`ai-2v2.md` 3.1: side 0 is always the human's) | e7o D5: Shadow + Ice court Adamarch, Fire + Nature court Aurivane |
| D3 | Who is auctioned | Auctions 1 and 2 sell two of **Ossavar's brood** (a gilt dragon, then a prism dragon); auction 3 sells **Ossavar himself** ("Whoever pays the most, I burn for", e7o L32) | The film's promise lands at the climax; e7m4 needs Ossavar unbought by anyone for good |
| D4 | Losing the auctions | The objective needs **2 wins of 3**. Aurivane winning 2 = **defeat** at once (E-line L33). A lost auction also turns its dragon against the player for 3 min | A clear goal the player can count; the difficulty table moves Aurivane's ceilings, not the rule |
| D5 | Gold | **Trade on** in this mission (`trade_enabled = true`): GoldBank, Frost Bazaar, caravans, wares, exchange. **Magpies and the Hunters' Lodge off** (no Dens, no Lodges on this map). Posts open at **2:00** (skirmish 4:00) | Episode 7 is "Gold for Fire": gold is the mission's spine. Trade was taught in e2m3 (Vessa's track); Magpies would split the focus from the auction |
| D6 | Torvald's save track | Torvald's track **starts here** (campaign-outline D8; Ep6 is an origin episode and carries nothing): **level 4, cap 7**, empty item slots, **400 essence**, new artifact **Heartfrost Splinter** owned + equipped in slot 1 | He lost the Heartfrost (M2) and the Orb (Vessa holds it until Ep8); the splinter is what Aldra saved from the lake |
| D7 | Aldra | **Story NPC** at the Rime Keep (invulnerable, not selectable, no fight), 4 lines. She becomes the **callable helper in e7m2** at the Citadel (campaign-outline C3) | One new system per mission: here gold and auctions, next the Citadel and Aldra |
| D8 | Tier | **Stronghold only** (`max_tier = 2`); the Citadel opens in e7m2 (campaign-outline D7) | Same rule as e3m1 |
| D9 | Who throws the knives at the Laurel | Mother Hush's Shades in gold cloaks (`gold_knife`, D10 of e7m2), sent by Malrik to frame Aurivane. **Not revealed here**: the only clue is a puff of violet smoke when a knife dies (`violet_smoke` VFX) and Dacian's "Those aren't mine!" | The truth is e7m2's objective; the clue is fair play |
| D10 | Ossavar in the field | When won, a dragon is an **allied flyer for 3 min** that the player cannot order (it follows the player's army, 6.3); when lost, it fights for Aurivane for 3 min. It then flies back to the Tollrock roost. No dragon ever dies in this mission (at 15 % HP it leaves early) | e7o 7 rule; dragons are e7m4's big cast and must all be alive there |
| D11 | Speaker for the narrator | **`ossavar`** replaces `narrator` for the whole of Episode 7 (he narrates the film) | The outline: "narrator Ossavar" |

## Story setup (briefing text, 3 short paragraphs; shown after `ep7_opening`)
1. The winter truce holds on the green fields of Evenmead. It says nothing about the south. On the Coinwater, two harbour
   cities who have hated each other for a thousand years have just watched their duel end, and a dragon land on the
   Master's empty chair.
2. Ossavar the Twice-Sold has named the old price: gold for fire. Three auctions, three skies for sale. Adamarch, the
   Diamond City, has opened its harbour to Malrik and to Torvald. Across the water, Aurivane flies Vessa's red sails and
   Ysolde's green ones.
3. Torvald came to keep a peace. Malrik came to buy a war. Hold the Diamond Harbour, win the sky, and count the coin
   carefully. Somebody else is counting too.
Briefing objectives: `obj_auction`, `obj_harbour`, the rule `Torvald must survive`, and the line `Gold comes by caravan
from the Diamond Harbour. Bid at your Bazaar when a dragon lands on the Tollrock.`

## Map: "Two Harbours" (180 x 180, `data/maps/two_harbours.map`, fourfold, seed 71)
Terrain, water and city backdrops come from the e7o 7 draft and `forge_tollrock` (the arena island is the map centre at
1:1). Playable bounds x -88..88, z -80..80 (camera bounds 3 m inside; the city wall blocks at `z = +-84` and the backdrops
beyond are decor). Clearings: no tree or rock inside the listed radius. Seat frames: seat 0 identity, seat 1 `mirror_x`,
seat 2 `mirror_z`, seat 3 `rot180`.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Torvald) / Aldra | `(-36, -56)` / `(-44, -62)` | 5 | Aldra stands by the keep door all mission (D7) |
| **Rime Keep** (player, Stronghold-able) | `(-42, -66)` | 16 | Seat 2 keep (canonical `(-42, 66)` mirrored) |
| Frost Hall (pre-built, complete) | `(-58, -68)` | - | 12.6 m from node a, 16.1 m from the keep |
| Snow Lodge (pre-built) | `(-34, -74)` | - | +20 pop (mission value, D note under Start state) |
| Bazaar spot (player builds it) | `(-48, -50)` suggested | - | 17.1 m from the keep (the 20 m rule); hint arrow at E2 |
| Node `e7_home_a` / `e7_home_b` | `(-54, -56)` / `(-30, -58)` | - | **1 500** each |
| Node `e7_outwall_w` | `(-78, -74)` | 6 | **2 000**; the Outwall shanties around it (e7o 7: "the poor quarter feeds the rich city"); hall spot `(-70, -66)` |
| **Diamond Harbour** (trade post, player-held) | `(-22, -40)` | 6 | The rich harbour (route values below). A **target** in this mission: 2 500 HP, armor 10, team PLAYER, `counts_for_defeat` false, its own lose rule |
| Facetguard post (allied) | Adamarch west gate `(-40, -78)` | 4 | 4 Facetguards (story units, team PLAYER, hold, leash 2x) |
| Watchtower `shoal_tower_w` | `(-60, -22)` | 4 | Decor this mission (points off) |
| **Malrik's Dusk Keep** (ally bot, seat 3) | `(42, -66)` | 16 | Gloom Hall `(58, -68)`, Hovel `(34, -74)`, nodes `(54, -56)` / `(30, -58)` 1 500, Outwall node `(78, -74)` 2 000 |
| **Admiralty Quay** (Malrik's trade post) | `(22, -40)` | 6 | The far route for the player's caravans (below) |
| Shore road (north) | `(-48,-50) (-22,-40) (0,-34) (22,-40) (48,-50)` | - | Caravans walk it; it passes the **North Causeway foot** `(0, -30)` |
| **The Tollrock** (arena island) | Island disc r **16** at `(0, 0)` inside the moat (water ring r 16-26) | - | `forge_tollrock` 1:1 |
| Arena sand (the Laurel ring) | `(0, 0)`, r **8** | - | The duel spot; the Master's stone chair on the west rim `(-9, 0)` |
| **Dragon roost** | `(0, -6)` | - | Where each auctioned dragon lands (e7o map `lair dragon_roost solo`) |
| **Tollrock point** (lighthouse) | `(0, 6)` | - | `CapturePoint` kind `&"shrine"`, radius 6 (rules below) |
| North / South Causeway | `(0, -21)` / `(0, 21)` | - | Bridge roads, width 6, over the moat |
| Gold Shoal / Silver Shoal | `(-55, 0)` / `(55, 0)` | - | Fords, width 9 (`terrain:ford` -35 %) |
| Lane bridges | `(-82, 0)` / `(82, 0)` | - | Width 5 |
| The strait | River polylines `(-90,0)-(-26,0)` and `(26,0)-(90,0)`, half width 9; moat centre `(0,0)` r 21 half width 5 | - | `RiverSystem.setup` by the mission (map-fill 11); deep water carved |
| **Vessa's Fire Keep** (enemy bot, seat 0) | `(-42, 66)` | 16 | Ember Hall `(-58, 68)`, Hearth `(-34, 74)`, nodes `(-54, 56)` / `(-30, 58)`; rally `(-36, 44)` |
| **Ysolde's Heartwood** (enemy bot, seat 1) | `(42, 66)` | 16 | Grove Hall `(58, 68)`, Seed Hollow `(34, 74)`, nodes `(54, 56)` / `(30, 58)`; rally `(36, 44)` |
| Sun Harbour / Gilt Quay (Aurivane posts) | `(-22, 40)` / `(22, 40)` | 6 | Enemy-held posts: player caravans refused (`held post` rule) |
| Gilded Spear posts (enemy) | Aurivane gates `(-40, 78)` / `(40, 78)` | 4 | 4 Gilded Spears each (guards, never leave) |
| Player rally / Malrik rally | `(-36, -44)` / `(36, -44)` | - | |
| Wave spawns | Fire: Ember Hall spawn; Nature: Grove Hall spawn; Aurivane guards / knives: South Causeway foot `(0, 30)` | - | The keep's spawn if the hall is gone |
Distances (path): Rime Keep -> Diamond Harbour 33 m; Rime Keep -> North Causeway foot 58 m; Rime Keep -> Tollrock centre 80 m;
Fire Keep -> South Causeway foot 58 m; Ember Hall -> Gold Shoal 70 m; Gold Shoal -> Diamond Harbour 51 m. Every way across
the water is slowed (fords) or narrow (causeways, lane bridges): the enemy comes by four doors the player can see.

**Crossings and the river**: `map-fill.md` 2.4 unchanged (ford slow, building refused within 1 m of water, within 8 m of a
crossing `"Too close to a crossing"`). `Skirmish.river_enabled` stays false; the mission calls `RiverSystem.setup(polylines,
9.0, moat, crossings)` itself (moat ring as in e7o 7).

**Tollrock point** (`CapturePoint`, kind `&"shrine"`, a lighthouse prop, no footprint): radius **6**, capture **15 s** (the
`map-fill.md` 4.3 rules: rate up to x1.75 with more units, neutralise first, contested freezes, decay). Owner effects: sight
**20** over the water (a SightMarker), the **toll** **+30 gold / min** (paid every 10 s), and the **rock's word** at the
auctions (see "The Dragon Auction"). Either side may take it; the scripted waves walk over it.

**Diamond Harbour** (the player's post made a target): the trade-post model with a Building collider, **2 500 HP**, armor
10, sight 12, regrows **1 % / s** while no enemy is within 12 m. Destroyed = defeat (E20). The 4 Facetguards of the west gate
walk to it when it drops under 50 % (once).

**Look** (E7M1.V1): noon to late afternoon (light ramp over 25 min from `forge_tollrock`'s `warm` to a gold dusk); turquoise
water with the seabed gold glitter; crimson galleys at anchor off the south shore, silver-blue off the north (decor rows,
2 draws each, never targets); gulls (cosmetic critters). North shore ground = black basalt and white paving; south =
ochre sand.

## Start state
| Item | Value |
|---|---|
| Torvald | **Level 4** with **3 unspent spell points** (Rime Bolt r1 known), full HP / mana, **cap 7**; artifact slot 1 = **Heartfrost Splinter**; 6 empty slots |
| Crystals / essence / gold | 350 / **400** (+1 / s) / **0** |
| Buildings | Rime Keep (tier 1, 3 000 HP; Stronghold from 3:30), Frost Hall (complete), Snow Lodge (complete) |
| Units | 5 Rime Haulers gathering (3 on `e7_home_a`, 2 on `e7_home_b`); **6 Rimeshields + 3 Shardcasters + 1 Rime Seer** at the rally `(-36, -44)` (1 050 crystals of army) |
| Population | 15 / 40 (keep 20 + Snow Lodge 20; Snow Lodges max **4** this mission = cap 100, the house rule of e3m1) |
| Malrik (ally bot, seat 3, Shadow) | **Level 5** (Lance r2, Siphon r2, Shroud r1); Dusk Keep at the **Stronghold**, Gloom Hall, Hovel; 5 Gloom Thralls; 5 Shades + 2 Nightbolts + 1 Shadow Knight + 1 Gloom Deacon at `(36, -44)`. **Mother Hush is not on the field** (she is "at the Admiralty"; D9) |
| Vessa (enemy bot, seat 0, Fire) | **Level 5** (Fireball r2, Ember Step r2, Kindle r1) at her rally; Fire Keep at Stronghold, Ember Hall, Hearth; 5 Cinder Hands; 4 Flame Guards + 2 Ember Archers + 2 Blaze Riders |
| Ysolde (enemy bot, seat 1, Nature) | **Level 5** (Thornburst r2 and her kit as `kingdom-nature.md`) at her rally; Heartwood at Stronghold, Grove Hall, Seed Hollow; 5 Spriglings; 6 Thornlings + 3 Wildwood Archers |
| Aldra | Story NPC at `(-44, -62)` (D7) |
| Fog | On; the strait, the island, the four crossings, both shores' harbours and the two city gates explored from 0:00 (`FogOfWar.reveal(team, pos, 8)`) |
| Off | Champions / taverns, Magpies, Lodges, camps, beasts, wells / shrines (only the mission's Tollrock point), Grand Market, research |
| No save / Ep6 not completed (menu debug, tests) | Same as above (Torvald's track always starts here; D6) |

## Unlocks (what exists in this mission)
| Kind | Available | Locked (comes later) |
|---|---|---|
| Buildings | Snow Lodge (Z), Frost Hall (X), Rime Spire (C), Ice Wall (V), **Frost Bazaar** (B, `market-trade.md` 4.1: 175 crystals, needs the Frost Hall, within 20 m of the keep) | Stables, Lair (Glacier Den), research; Citadel (e7m2) |
| Units | Rime Hauler (keep Z); Frost Hall: **Z Rimeshield, X Shardcaster, C Rime Seer, V Rime Colossus, N Rimeling**; **from the Stronghold: M Hoarlight Magebow, `,` Frost Mortar** (Hall), **B Rimecarver** (keep); **Caravan** (Bazaar Z, max **4** this mission) | Frostbow (Hall B, skirmish only), Rimehorn Rider (Stables), Shardguard (Citadel, e7m2), titans |
| Keep | **Stronghold** (X, 200 crystals, 60 s, from 3:30) | Citadel, Call Aldra (e7m2) |
| Spells | Rime Bolt (L1), Flash Freeze (L2+), Rime Aegis (L4+); cap L7 | - |
| Items | Base shop (Rime Keep, Frost Halls): components, mids, tops, the 4 Ice items (`kingdom-ice.md` 6), Ember Draught, Dusk Vial, Homeward Seal | Owl Stone; peddler |
| Gold | Wares at the Bazaar (Iron-shod Axles 150, Masons' Charter 350, Tempered Steel 350, Quilted Gambesons 350), the exchange (100 gold -> 80 crystals or 40 essence), **bids** | Champion hire (no tavern) |
| "+" upgrades | At the Frost Hall from the Stronghold | - |

### The Rimecarver in this mission (`caster-units.md` 5.2, unchanged numbers)
The map is a map of doors (two causeways, two fords, two lane bridges), so the Rimecarver has a job from its first minute:
**Rime Bulwark** (50 mana, 4 m wall for 8 s) shuts the North Causeway (6 m wide: two walls) in front of a raid, or cuts the
Blaze Riders off a caravan; **Scrying Rune** (25 mana, vision r 10 for 20 s, fog allowed) watches a ford before a wave
arrives, and in the Laurel event it **reveals** what the gold knives are not (they are not disguised here, but a rune on the
arena sand shows the violet smoke trail of their boat at `(4, -14)` on the north side of the island: an optional clue for
e7m2, flag `e7m1_rune_saw_boat`). Two hints teach it (E4, E8).

### The Heartfrost Splinter (new campaign artifact; the items row is for the items owner, campaign-outline C7)
| id | Name | Given by | Stats / effect |
|---|---|---|---|
| `heartfrost_splinter` | Heartfrost Splinter | Torvald's track start (e7m1); Aldra took it from the lake after M2 | `max_hp` +80, `armor` +10, `mana_regen` +0.5; **Long Winter** (passive): `chill` applied by the wearer's spells lasts **+1 s**. `campaign_only`, never sold, never dropped |
Look: artifact icon `HS`, glass-teal border `(0.62, 0.95, 0.88)`; while equipped a thin frost ring under Torvald (0.3 alpha decal, no light).

## The Dragon Auction (new mission system, systems; reused by e7m4)
`DragonAuction` (`scripts/campaign/dragon_auction.gd`, one node in the mission, group `"auctions"`). e7o 7 rules, mission
numbers:
| Rule | Value |
|---|---|
| Schedule | **A1 at 8:00** (Kesh, a young gilt dragon), **A2 at 14:00** (Morrow-of-Glass, a prism dragon), **A3 at 20:00** (Ossavar). Message 30 s before: `A dragon is landing on the Tollrock. Auction in 0:30: bid at your Bazaar` |
| Landing | The dragon lands on the roost `(0, -6)`; it is invulnerable and untargetable while the hammer is up (45 s) |
| Window | **45 s**. A top-centre **auction banner**: dragon portrait + name, both sides' current bids, the countdown, and the rock's owner (a small lighthouse icon) |
| Bidding (player) | The player's **Frost Bazaar** card, during the window only: **C `Bid +50`**, **V `Bid +100`** (the bid must exceed the current top bid; refused `"Not enough gold"`, `"No Bazaar"`, `"You already lead"`). No Bazaar = cannot bid (the hint at E2 says so) |
| Bidding (Aurivane) | Scripted: opens at **100** at +5 s; whenever the player leads, answers **+50** after **3-6 s** (seeded rng) until its **ceiling** (normal: A1 **500**, A2 **800**, A3 **1 100**; difficulty table). At its ceiling it stops and the banner shows `Aurivane hesitates...` |
| Gold | Bids are promises: the winner pays its top bid when the hammer falls (`GoldBank.spend`); the loser pays nothing. A side whose bank holds less than its bid at the hammer loses the auction (`"Your coffers are short"`) |
| **The rock's word** | The side that **owns the Tollrock point when the hammer falls** wins if its bid is within **10 %** of the top bid (Ossavar: "The rock's master speaks last") |
| Malrik's purse | At **13:50** Malrik adds **200 gold** to the side bank (E11; stolen Outwall coin, the doubt thread). The ally bot never spends side gold otherwise (D5 of `ai-2v2.md` bank sharing) |
| Won | The dragon fights for side 0 for **3:00** (6.3), then flies back to the roost and leaves the map north-east (A1, A2) or settles on the empty chair (A3) |
| Lost | The dragon fights for Aurivane for 3:00: it attacks the Diamond Harbour first, then the player's units within 20 m of it, then the Rime Keep. While it fights, the concurrent scripted wave **loses 40 %** of its units (rounded down; the 70 % rule) |
| Count | `obj_auction` counts wins; Aurivane's second win = defeat (D4) |

### 6.3 The auction dragons (story units; gameplay; on the titan flyer code, `cavalry-mounts.md` / `titans-2.md`)
| id | Who | HP | Armor | Attack | Speed | Notes |
|---|---|---|---|---|---|---|
| `gilt_dragon` | **Kesh**, young gilt dragon (A1) | 1 400 | 5 | Breath 16 to every enemy in a 60 deg cone 6 m every 2.2 s + burning ground (the Cinder Dragon's) | 5.5 fly | Look: e7o A2 `gilt_dragon` flock kind as a game unit |
| `prism_dragon` | **Morrow-of-Glass**, prism dragon (A2) | 1 700 | 10 | Rime-glass breath 14, 60 deg, 6.5 m, every 2.4 s, + 25 frost + chill 2 s (the Frost Dragon's) | 5.0 fly | e7o A2 `prism_dragon` |
| `ossavar_story` | **Ossavar the Twice-Sold** (A3) | 3 600 | 20 | Breath **30** to every enemy in a 70 deg cone 8 m every 2.6 s + burning ground; **Old Price** (passive): buildings take x1.5 from him | 4.8 fly | e7o A1 game model (the film model at game budget) |
Common rules: flying (ranged and towers x2, melee cannot hit), titan tags (CC half, taunt / knockback immune), **not
commandable** (`commandable = false`), **not** in group `"beasts"` (towers and keeps may shoot them). **Brain** (`AuctionDragonBrain`,
ai): while it fights for a side, every 1 s pick the target: the enemy unit group nearest to the **centroid of its side's
largest army group** within 25 m, else the side's last ping (ally pings, `ai-2v2.md` 5.1), else it circles its side's
harbour. At **15 % HP** it disengages, flies to the roost and rests until its 3 min end (never dies, D10). Kill XP and
essence: none (it never dies).

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_auction` | Primary | `Win the Dragon Auctions (0 / 2 of 3)` (+ the next auction's time) | Side 0 wins 2 auctions; **failed** when Aurivane wins 2 = defeat |
| `obj_harbour` | Primary, always shown | `Hold the Diamond Harbour` (HP bar) | Never "done" on its own; fails when the harbour is destroyed = defeat |
| `obj_seraphine` | Primary (appears at E9, 12:20) | `Keep Seraphine alive: bring her to the Diamond Harbour` | Seraphine within 6 m of the Diamond Harbour; **failed** if she dies before = defeat |
| `obj_hold` | Primary (appears after the 3rd hammer, E15) | `Hold the harbour until Aurivane's fleet turns (2:00)` | 120 s pass with the harbour standing |
| `obj_torvald` | Primary, always shown | `Torvald must survive` | Fails = defeat |
| `sec_rock` | Secondary | `Hold the Tollrock when the hammer falls (0 / 3)` | Side 0 owns the Tollrock point at all 3 hammers |
| `sec_wares` | Secondary | `Arm Adamarch's guests: buy 2 wares` | 2 wares owned (any two) |
States through `Events.objective_changed(id, state)`: `"active"`, `"done"`, `"failed"`. Malrik's units count for the Tollrock.

## Guards, waves and the bots (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units: team ENEMY (Aurivane side) or PLAYER (Facetguards), group `"scripted"`, never controlled by a Commander;
guards hold with auto-aggro and a 2x leash. Waves spawn at the named spawn and attack-move as listed, targets refreshed
every 3 s when the order says "then". Value = crystals (Gilded Spear 120, gold knife 110; wizard `170 + 30 x level`).
| Group | Where | Units | Value |
|---|---|---|---|
| G1 island watch | Tollrock point `(0, 6)`, ring r 4 | 3 Gilded Spears + 2 Ember Archers (they hold the rock at 0:00) | 560 |
| G2 Gold Shoal pickets | South bank of the ford `(-55, 10)` | 3 Thornlings + 2 Burr Slingers | 305 |
| G3 Gilded gates | `(-40, 78)` / `(40, 78)` | 4 Gilded Spears each (never leave; not needed) | 480 each |
| F1 Facetguards (allied) | `(-40, -78)` | 4 Facetguards (team PLAYER, story, hold; to the harbour under 50 %) | - |

| Wave | Trigger | Units (spawn) | Order |
|---|---|---|---|
| W1 caravan raid | **4:30** | 3 Blaze Riders (Ember Hall) | Cross **Gold Shoal**, attack-move to the nearest player caravan, else the nearest Rime Hauler; retreat home after 60 s or under 40 % HP |
| W2 probe | **7:00** | 5 Thornlings + 3 Burr Slingers + 1 Bloomtender (Grove Hall) | South Causeway -> Tollrock point -> North Causeway -> the Diamond Harbour |
| W3 Fire column | **9:30** | **Vessa** + 4 Flame Guards + 3 Ember Archers + 1 Pyre Adept (Ember Hall) | Gold Shoal -> the Diamond Harbour, then Torvald; Vessa retreats under 35 % HP (bot rule 8) |
| Laurel knives | **12:20** (E9) | 4 **gold knives** on the arena rim `(0, 8)` | Attack Seraphine only; when she leaves the sand, follow her |
| Laurel guard | **12:40** | 4 Gilded Spears + 2 Ember Archers (South Causeway foot `(0, 30)`) | Attack-move to Seraphine, then the Tollrock point |
| W4 Ysolde's push | **15:30** | **Ysolde** + 6 Thornlings + 3 Wildwood Archers + 2 Vinelashers + 1 Bramblehorn (Grove Hall) | Silver Shoal -> along the north shore road -> the Diamond Harbour (she walks past Malrik's harbour: his army meets her, 6.4) |
| W5 riders | **17:30** | 4 Blaze Riders + 2 Thistle Darters | Gold Shoal -> the far caravan road (`(0, -34)`), then the Rime Haulers on `e7_outwall_w` |
| Final | **20:45** (after A3's hammer) | 0 s: **Vessa + Ysolde** + 6 Flame Guards + 4 Ember Archers + 6 Thornlings + 2 Greenheart Oathkeepers (both causeways and Gold Shoal, split by kingdom); 45 s: 2 Cinder Arbalests + 4 Gilded Spears (South Causeway) | The Diamond Harbour, then the nearest player building, refreshed every 3 s |
If Aurivane holds the A3 dragon (Ossavar) during the Final, the Final loses **30 %** of its units (rounded down; wizards stay).
**Enemy bots** (`ai.md` + `ai-2v2.md` side council, profile `mission_e7_01_enemy`): normal knobs, `min_attack_pop` 99 (they never
launch their own attacks), `worker_target_home` 5, no expansion, no new towers, up to **10 soldiers** at their rallies,
`bots_upgrade = false`; they do not trade (no Bazaar; their gold is the scripted ceilings). Wizards stay at their rallies except
when a wave carries them (W3, W4, Final); a dead enemy wizard respawns at its keep after the 2v2 timer and walks back.
**Ally bot Malrik** (`ai-2v2.md` 5, **Supportive**, profile `mission_e7_01_ally`): gathers, trains up to **16 army pop**, defends
both north bases and both harbours, answers the player's pings, never touches the player's nodes, **never spends side gold**
(one scripted gift, E11). Scripted pushes on top of the pings: at A1 and A3 his army walks to the North Causeway foot
`(0, -30)` (he wants the rock); at W4 it holds the shore road at `(22, -40)`; in the Final it covers the harbour's east side
`(-8, -40)`. Malrik dying or his keep falling is never a loss (2v2 respawn; his army falls back to the Rime Keep).
**6.4 Ysolde meets Malrik**: W4 passes the Admiralty Quay; if Malrik's army is there the two fight first (that is the point:
the player sees the ally pay in blood for the shore road), the wave's remainder then continues.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (`ep7_opening` played, then the briefing.) Cinematic `e7m1_arrival` (HOLD 0:15); dialogue L1-L4; hint `Your gold comes from the Diamond Harbour. Build a Frost Bazaar near the Keep (worker B, then B) and train caravans (Z).` (10 s) |
| E2 | 1:00 | L5 (Aldra); a ground arrow at the Bazaar spot `(-48, -50)` for 20 s; hint (8 s) `Posts open at 2:00. Caravans walk the shore road: the Diamond Harbour pays the most per minute, the Admiralty Quay the most per trip.` |
| E3 | First caravan delivery | L6 (Aldra); gold top-bar item flashes once |
| E4 | 3:30 (Stronghold available) | Hint (12 s) `Your Rime Keep can become a Stronghold: select it and press X (200 crystals). It opens Hoarlight Magebow, Frost Mortar (Frost Hall) · Rimecarver (Keep).` |
| E5 | W1 launches (4:30) | L7-L8; message `Riders on the Gold Shoal: they want your caravans` |
| E6 | Tollrock point first owned by side 0 | L9 (herald); hint `Hold the Tollrock when the hammer falls: its master wins a bid within 10 %.` (8 s) |
| E7 | 7:30 (A1 in 0:30) | L10 (Ossavar); the auction message; the banner pre-shows `Kesh` |
| E8 | First Rimecarver trained | Hint (12 s) `Rimecarver: Z Rime Bulwark raises a wall for 8 s (two close a causeway). V Scrying Rune sees through fog.` |
| E9a | Each hammer (A1 8:45, A2 14:45, A3 20:45) | Won: L11 / L23 / L28; lost: L12 / L24 / L29; the dragon takes its side (6.3); `obj_auction` counter; `sec_rock` check |
| E9 | **11:00** | L13 (herald); message `The Laurel duel begins at noon on the Tollrock (12:00)`; a gold ring on the arena sand |
| E10 | **12:00** | Dacian and Seraphine (story units) walk out on the sand; L14-L15; they duel (scripted 20 s exchange, 6.5) |
| E11 | **12:20** | Cutscene `e7m1_laurel` (PAUSE 0:14): the knives drop from the rim; L16-L17; Dacian is pulled south by two Gilded Spears and leaves the map at `(0, 60)`; `obj_seraphine` active; the knives attack |
| E12 | An Ice unit or Torvald within 6 m of Seraphine | L18; she follows Torvald (6.5) toward the harbour |
| E13 | Seraphine within 6 m of the Diamond Harbour | L19; `obj_seraphine` done; she stays as the harbour's defender (kneel rule) |
| E14 | **13:50** | L20-L22 (Malrik's gift, the Outwall stamp, the stone): +200 gold to the side bank |
| E15 | 13:30 (A2 in 0:30) | L23a (Ossavar) |
| E16 | W4 launches (15:30) | L25-L26 |
| E17 | 19:30 (A3 in 0:30) | L27 (Ossavar); cutscene-free set-piece: Ossavar lands on the empty chair (no camera move) |
| E18 | A3's hammer (20:45) | If side 0 has 2 wins: `obj_hold` active (2:00) + the Final; L30 |
| E19 | `obj_hold` done | Remaining Aurivane units walk home; cutscene `e7m1_dusk` (PAUSE 0:30): L31-L32-L34; `Events.mission_ended(true)` at its end |
| E20 | Diamond Harbour destroyed | L35; defeat after 3 s |
| E21 | Seraphine dies before E13 | L36; defeat after 3 s |
| E22 | Aurivane's 2nd auction win | L33; defeat after 3 s |
| E23 | Torvald dies | L37; defeat after 3 s |
| E24 | A knife dies (first time) | Violet smoke puff (`violet_smoke`); Torvald: L16b (once) |
| E25 | Second ware bought | `sec_wares` done; L38 (Aldra) |
The auctions' order is fixed; the waves are on the clock. A2 can decide the mission (two Aurivane wins), so E22 can fire at
14:45 at the earliest.

### 6.5 Seraphine and Dacian (story units, gameplay)
| id | HP | Armor | Attack | Speed | Kit |
|---|---|---|---|---|---|
| `seraphine_story` (Seraphine Vael, the Diamond Wall) | 1 000 | 25 | 28 / 1.7 m / 1.1 s | 4.6 (**3.0 in this mission: cut strap, wounded**) | **Diamond Wall** (cd 20): shield 300 for 6 s on herself; **Rainbow Bash** (cd 12): 40 + `dazed` 1 s on her target. Team PLAYER, not commandable. In the Laurel she **does not leave the sand** until a side-0 unit reaches her ("Walls don't run"), then follows Torvald 2-5 m behind and fights what attacks her. After E13: holds the harbour, kneels 10 s at 1 HP then stands at 50 % (cannot die) |
| `dacian_story` (Dacian Orrow, the Sunblade) | 950 | 10 | 36 / 1.9 m / 1.4 s | 5.0 | **Sun Cleave** (cd 8, 1.0 s windup, gold arc telegraph): 90 to enemies in a 3 m 120 deg arc. Team NEUTRAL-invulnerable here (he only duels and is led away) |
The Laurel duel (12:00-12:20) is a scripted exchange (no damage to anyone but the two, both end at 90 %): the e7o 3.1 beats
in miniature (cleave, deflect, the bind). Players who stand on the sand during it are pushed out of the ring r 8 (a soft
push, the Bulwark footprint rule) with the message `The Laurel ring is closed to soldiers.`

## Dialogue (41 lines incl. outcome variants; 5 s each unless listed)
Speaker ids from `data/voice/cast.json`: `torvald`, `aldra`, `malrik`, `vessa`, `ysolde`, `obren` (whisper voice) exist;
**new for the voice cast (to add to `cast.json`)**: `ossavar`, `herald`, `dacian`, `seraphine` (voices proposed in e7o 4.3;
this mission is their first in-game use). Colours: Torvald `(0.55, 0.80, 1.00)`, Aldra `(0.62, 0.95, 0.88)`, Malrik
`(0.7, 0.3, 1.0)`, Ossavar **new** `(0.95, 0.70, 0.30)`, Herald **new** `(0.85, 0.80, 0.60)`, Dacian **new** `(1.00, 0.80,
0.35)`, Seraphine **new** `(0.80, 0.88, 1.00)`, Vessa `(1.0, 0.45, 0.1)`, Ysolde `(0.55, 0.90, 0.35)`, Obren `(1.0, 0.80,
0.25)`. Names shown: `Torvald`, `Aldra`, `Malrik`, `Ossavar`, `Herald`, `Dacian`, `Seraphine`, `Vessa`, `Ysolde`, `Obren`.
Every line <= 96 characters (2 box lines) and fits 5 s at the cast speeds (Ossavar 0.88: <= ~70 characters per 5 s).
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | ossavar | Two harbours, one rock, a sky for sale. Bring gold. I take no promises. |
| L2 | E1 | malrik | The west harbour is yours, Torvald, the east is mine. Together we outbid the sun. |
| L3 | E1 | torvald | I came to keep the Coinwater's peace, Malrik. Not to buy a dragon like a cart-horse. |
| L4 | E1 | aldra | Then keep it with gold, my lord. Winter is patient. Markets are not. |
| L5 | E2 | aldra | Send the wagons to the harbour. And watch the shoals. The sun's riders are faster than ice. |
| L6 | E3 | aldra | The first coin is home. It smells of fish and diamonds. |
| L7 | E5 | vessa | Torvald! You came south for the sunshine? I'll show you sunshine. |
| L8 | E5 | torvald | Vessa. Still never waiting. One day, child, the road will be longer than you are. |
| L9 | E6 | herald | The rock is held! By the old law, its master speaks last at the hammer. |
| L10 | E7 | ossavar | The first of my brood. Kesh burns bright, and cheap. Who pays? |
| L11 | A1 won | torvald | Fly with us, then. And try not to enjoy it. |
| L12 | A1 lost | ossavar | Gold from the south. Kesh, burn the north. |
| L13 | E9 | herald | The Laurel at noon! By the Truce of the Stilled Sea: first blood, and no further! |
| L14 | E10 | dacian | No crowd worth the name today, Diamond Wall. Just us, and a great deal of money. |
| L15 | E10 | seraphine | Then let us disappoint the money. |
| L16 | E11 | seraphine | Gold cloaks, behind me. So this is how Aurivane wins now. |
| L17 | E11 | dacian | Those aren't mine! Seraphine, those are NOT mine! |
| L16b | E24 | torvald | That smoke is violet. Gold cloaks do not bleed violet. (4 s) |
| L18 | E12 | seraphine | Walls don't run, Ice-king. But they can walk, if you walk beside them. |
| L19 | E13 | seraphine | The harbour, then. I will hold it. It is the one thing today that hasn't lied to me. |
| L20 | E14 | malrik | For the second bid, Torvald. A gift. Two hundred, in good gold. |
| L21 | E14 | torvald | This coin carries the Outwall's stamp, Malrik. Dockers' wages. Where did you find it? |
| L22 | E14 | malrik | Lying in the street, Torvald. Where coin usually lies. |
| L22b | E14 | obren | Count it, Ice-king. Count all of it. Someone is counting you. (4 s) |
| L23a | E15 | ossavar | Morrow-of-Glass, my daughter. She remembers both your grandfathers' coin. |
| L23 | A2 won | torvald | Glass and frost. At least one of us will match the banners. |
| L24 | A2 lost | ossavar | Diamonds were never enough for her. Morrow, fly south. |
| L25 | E16 | ysolde | Torvald. You let me go once, on your wall. I remember. I will not hold back today. |
| L26 | E16 | torvald | Good. Holding back has always been my fault, not yours. |
| L27 | E17 | ossavar | And now the old price. Me. Whoever pays the most, I burn for. |
| L28 | A3 won | torvald | I have never owned anything this old. Except my regrets. |
| L29 | A3 lost | ossavar | Twice each, I said. Let us make it three. |
| L30 | E18 | vessa | Everything we have, Ysolde! Take that harbour while the sky is still for sale! |
| L31 | E19 | seraphine | Adamarch will remember who stood on the quay with her. Even if the Archon will not. |
| L32 | E19 | torvald | Remember who paid for it, Seraphine. I would like to know myself. |
| L34 | E19 | ossavar | The Laurel was broken by knives. Gold cloaks. Violet smoke. Somebody lied on my rock. (6 s) |
| L33 | E22 | ossavar | The sky has chosen its master, and it is not you. |
| L35 | E20 | aldra | The harbour is burning, my lord. Adamarch does not forgive a guest who loses its harbour. |
| L36 | E21 | dacian | No... she was the best of us. Both cities killed her today. |
| L37 | E23 | torvald | Too slow. Again... the ice gives way. |
| L38 | E25 | aldra | Steel and quilting. Adamarch's coin, wearing our colours. |
Echoes: L8 is Torvald's ep1 weariness turned on Vessa's prologue weakness ("she never waits"); L25-L26 pay off e4m4 (Torvald
stopped Aldra from finishing Ysolde) and his own weakness ("he waits too long"); L21-L22b is the doubt thread (e3m1 L16,
ep1 C3 "something counting"); L16b + L34 hand the knife mystery to e7m2; L27 repeats e7o L32 in the field.

## Cinematic hooks (ENGINE on the live mission scene, CinematicPlayer 19.C1; skippable; units frozen during PAUSE, the game runs during HOLD with input locked)
| id | Kind | When | Shots | Lines | Skip end state |
|---|---|---|---|---|---|
| `e7m1_arrival` | HOLD 0:15 | E1 | 1) The P04 mark of `forge_tollrock` reversed: CRANE down from the strait to the north shore, silver-blue sails gliding into the round harbour; 2) MS Torvald stepping off the quay at `(-36, -56)`, Aldra a step behind; 3) long lens (fov 24) across the water: Ossavar on the arena rim above the empty chair, wings folded | L1 over 1-2 | Camera on Torvald at `PLAYER_START`; L1 shown as dialogue; the clock starts at 0:00 either way |
| `e7m1_laurel` | PAUSE 0:14 | E11 | 1) MS on the sand, 3/4 (cameras east of the Dacian - Seraphine axis, the e7o duel rule): four gold-cloaked figures drop from the rim; 2) CU Seraphine, back to the chair, sword up (L16); 3) MS Dacian, two Gilded Spears dragging him by the arms (L17); 4) insert: a knife falls on the sand, a thread of **violet** smoke (soft focus, 1 s) | L16, L17 | Knives at their rim marks `(0, 8)`, Dacian already at `(0, 18)` walking south, `obj_seraphine` active, the Laurel guard timer at 20 s |
| `e7m1_dusk` | PAUSE 0:30, then victory | E19 | 1) WIDE from the Diamond Harbour west over the strait at golden dusk (light ramp to dusk over 6 s), the crimson sails turning south; 2) MS two-shot Seraphine + Torvald on the quay, 3/4 (L31, L32); 3) long lens to the Tollrock: Ossavar on the chair (or on the rim if he flew for Aurivane), head turned north (L34); FADE_BLACK | L31, L32, L34 | `Events.mission_ended(true)`; flags saved |
Camera axis: all three keep e7o's rule (cameras east of the north-south duel axis, x > 0, for the arena shots). Fallbacks
until 19.C1 / VFX Composer / Motion Lab exist: the knives simply spawn on the rim, the lines play as dialogue, missing VFX ids
are skipped, the duel uses hook clips (`play_attack`, `play_hit`).

**Between-mission scene `c_e7_ledger` "Clean Coin"** (ENGINE, ~1:10, after victory; written by E7.D2 in `episode2-opening.md`
format; beats): night in Torvald's quarters above the Diamond Harbour; Aldra stacks Malrik's 200 coins in towers by
candle, each with the Outwall's anchor stamp; Torvald: "Two hundred dockers' wages, given as a gift." Aldra: "Coin
remembers where it was taken." A shadow on the roof: Ossavar, listening. He says only: "Tomorrow, ask the herald where
the knives came from." Torvald blows out the candle: he waits; Aldra watches him wait.

## Tiers (`tiers.md` 6)
| Item | Value |
|---|---|
| Code | `MissionE7_01._init`: `tiers_enabled = true`, `casters_enabled = true`, `trade_enabled = true` (mission overrides: posts open 2:00, caravans max 4, Magpies / Lodges off); `_ready`: `tier_system.max_tier = 2`, `bots_upgrade = false` |
| Rime Keep card | Z Rime Hauler, **X Stronghold** (gold pulse when it can start), **B Rimecarver** (greyed `Requires Stronghold`), Set Rally r3c1; no Citadel, no Call button |
| Frost Hall card | Z X C V N as listed; **M Hoarlight Magebow, `,` Frost Mortar** greyed until the Stronghold; "+" page from the Stronghold |
| Frost Bazaar card | Z Caravan; **C `Bid +50`, V `Bid +100`** during an auction window (hidden otherwise); the trade window (U) for wares and the exchange |
| Bots | Malrik, Vessa and Ysolde start at the Stronghold and never reach the Citadel; scripted tier-2 units (Pyre Adept, Cinder Arbalest, Vinelasher, Greenheart Oathkeeper) are spawned, not trained |
Timing: Stronghold 3:30 -> 4:30 at the earliest; the first Rimecarver / Frost Mortar ~5:00-5:30, before W2 (7:00) and A1 (8:00).

## Economy
| Item | Value |
|---|---|
| Start | 350 crystals, 400 essence, 0 gold, 15 / 40 pop, 5 Haulers |
| Nodes (player) | Home 2 x 1 500; Outwall west 2 000 (raided by W5) |
| Routes (from the Bazaar spot `(-48, -50)`) | **Diamond Harbour** (near, L ~28 m): **24 gold / trip** (the `market-trade.md` 4.3 value 16 x **1.5** rich harbour), trip ~21 s, **~68 gold / min** per caravan. **Admiralty Quay** (far, L ~71 m, along the shore road past the North Causeway foot): **72 gold / trip** (48 x 1.5), trip ~45 s, **~96 gold / min**, but exposed to W1 / W5 and the causeway |
| Caravans | Max **4** (mission); 75 crystals, 20 s; loaded caravan killed = loot sack 50 % (enemy riders pick it up in 10 s, then it is gone) |
| Toll | Tollrock owner: **+30 gold / min** |
| Expected gold (normal, Bazaar ~2:30, caravans 1-4 by 6:30, near route) | ~**700** by A1 (8:00), **+1 500** by A2 (incl. Malrik's 200), **+1 500** by A3; ~3 700 over the mission before raids (-10-15 %) |
| Spending pressure (the design) | A1 ceiling 500 vs one ware (350) at ~7:00: **buy a ware or win Kesh**, not both. Winning all three auctions (500 + 800 + 1 100 = 2 400) leaves ~900 for wares; winning A2 + A3 and skipping A1 leaves ~1 600 (4 wares). Both are 2-of-3 wins. The far route pays more but needs escorts (the Rimecarver walls) |
| Essence (expected by 24:00) | 400 + trickle ~1 400 + kills ~1 500 = **~3 300**: one top for Torvald (suggested Rimebound Bracers -> Winterwall Aegis: the hold is his job) |
| Malrik | His own nodes; 16 army pop keeps him a helper; he does not trade |

## Win / lose
| Event | Result |
|---|---|
| `obj_hold` done | **Victory** (after `e7m1_dusk`) |
| Torvald dies | **Defeat** (`instant_loss_on_wizard_death = true`) |
| Rime Keep destroyed | **Defeat** |
| Diamond Harbour destroyed | **Defeat** |
| Seraphine dies before reaching the harbour | **Defeat** |
| Aurivane wins 2 auctions | **Defeat** |
| Malrik dies / his keep falls | Nothing (message `Malrik falls back to the Admiralty`); 2v2 respawn |
| An enemy keep destroyed | Allowed, not needed: `Aurivane's quarter burns, but the city's walls stand`; that bot's later waves spawn at its city gate |
| All Ice soldiers dead, Torvald alive | Nothing; he can rebuild |

## Reward carried to e7m2 (Torvald's track, campaign-outline D8)
- **Heartfrost Splinter** stays owned and equipped. The 6 item slots at victory; essence **50 %, cap 1 500**.
- `sec_rock` done: **+250 essence** at victory (before the cut). `sec_wares` done: **+150 essence**.
- Gold, wares, Bazaar and caravans are **not** carried (`market-trade.md` 10).
- Flags: `e7m1_auctions_won` (2 or 3), `e7m1_kesh_won`, `e7m1_morrow_won`, `e7m1_ossavar_won`, `e7m1_rock_held`,
  `e7m1_rune_saw_boat`, `e7m1_time`. e7m2 reads `e7m1_rune_saw_boat` (one clue starts found) and `e7m1_ossavar_won` (an
  Ossavar line); e7m4 reads `e7m1_ossavar_won` (his turn line, D in e7m4).
- `CampaignState.MISSION_REWARDS[&"e7m1"] = {"flags": {...}, "bonus_essence": {"sec_rock": 250, "sec_wares": 150}, "next": &"e7m2"}`.
- Level not carried (e7m2 sets its own start).

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave / guard counts | x 0.6, no Bramblehorn, no Cinder Arbalest | as written | x 1.4; Final wizards L6 |
| Start | 450 crystals, +2 Rimeshields | as written | 250 crystals, no Rime Seer |
| Aurivane ceilings A1 / A2 / A3 | 350 / 600 / 850 | **500 / 800 / 1 100** | 600 / 950 / 1 300 |
| Rock's word | 15 % | 10 % | 5 % |
| Harbour HP | 3 000 | 2 500 | 2 200 |
| Seraphine | 1 200 HP | 1 000 | 900 |
| Hold timer | 90 s | 120 s | 150 s |
| Malrik army cap | 20 pop | 16 | 12 |
| Expected time | 20-23 min | 23-26 min | 25-30 min |
Expected run on normal: Bazaar ~2:30 -> Stronghold ~4:30 -> W1 riders 4:30 (caravans) -> Rimecarver ~5:30 -> W2 7:00 ->
A1 8:00-8:45 -> W3 Vessa 9:30 -> Laurel 12:00, knives 12:20, Seraphine home ~13:30 -> Malrik's gift 13:50 -> A2 14:00-14:45 ->
W4 Ysolde 15:30 -> W5 17:30 -> A3 20:00-20:45 -> Final + hold 20:45-22:45 -> cutscene -> **~23:30**, 26 with retakes.
**Fight sizing** (army value in crystals + wizard worth `170 + 30 x level`; every guarded fight and wave <= 70 % of what the
player side can have then on normal, ep1 4.1 rule; Malrik counted only where his scripted push puts him):
| Fight | Enemy | Player side then | Ratio |
|---|---|---|---|
| G1 island watch (~6:00, optional) | 560 | ~1 800 | 31 % |
| W1 riders (4:30) | 540 | ~1 500 | 36 % |
| W2 probe (7:00) | 575 | ~2 000 | 29 % |
| W3 Fire column (9:30) | 790 + Vessa 320 = 1 110 (x0.6 if Kesh is Aurivane's, + Kesh ~700 = 1 370) | ~2 400 | 46 % / 57 % |
| Laurel knives + guard (12:20-12:40) | 440 + 720 = 1 160 | ~2 800 + Seraphine | 41 % |
| W4 Ysolde (15:30) | 1 075 + 320 = 1 395 (Malrik's army takes a share at the quay) | ~3 200 | 44 % |
| W5 riders (17:30) | 850 | ~3 400 | 25 % |
| Final (0 s / +45 s) | 1 610 + 640 wizards = 2 250 / 3 000 total (x0.7 if Ossavar is Aurivane's, + Ossavar ~1 500) | ~3 800 + Malrik ~1 200 + Seraphine + 4 Facetguards ~ 5 600 | 40 % / 54 % (63 % with an enemy Ossavar) |
- The skill checks are **the money**, not one fight: a player who buys nothing but soldiers cannot win two auctions; a player
  who only trades loses caravans to W1 / W5 and the harbour to W3. The intended line: Bazaar early, 3-4 caravans on the near
  route, the Rimecarver on the causeway at A1 / A3 (the rock's word), Kesh or Morrow skipped in favour of 2 wares.
- The Laurel is the second check: the North Causeway is the only short way to the sand. A Rime Bulwark across the South
  Causeway at 12:38 keeps the Laurel guard off Seraphine for 8 s, exactly the time the escort needs.
- Watch in the first playtest: if A1 is always skipped, lower its ceiling to 400; if the Final with Ossavar on Aurivane's side
  wipes the harbour, cut the Final reduction to 40 %.

## Acceptance checks (measurable; the lead runs them before marking the mission done)
1. A scripted headless run on normal (Bazaar, 4 near caravans, Stronghold, win A2 and A3, escort Seraphine, hold) ends
   `victory=true` in **22-28 game-minutes** in 3 / 3 runs.
2. With 4 near caravans from 6:30 and no ware bought, the side bank holds **>= 520 gold at 8:40** in 5 / 5 runs (A1 is
   winnable), and **< 500** if one 350-gold ware was bought at 7:00 (the choice is real).
3. A bid refused for lack of gold shows `"Not enough gold"`; a side whose bank is below its bid at the hammer loses with
   `"Your coffers are short"`; ties within 10 % go to the Tollrock owner (unit test on `DragonAuction` with fixed bids).
4. A won dragon never takes an order (`is_commandable()` false), attacks within 25 m of the side's largest group, and leaves
   at 15 % HP without dying; a lost one attacks the Diamond Harbour first.
5. Aurivane's 2nd win ends the mission in defeat within 3 s; Seraphine's death before E13 ends it; Malrik's death never does.
6. The Laurel knives target only Seraphine until she leaves the sand; each knife death plays `violet_smoke`.
7. Every line <= 96 characters; every WAV fits its slot (Ossavar at 0.88).
8. `PERF OK` with the Final on the field plus Ossavar breathing.

## Implementation tasks (proposed ids; the lead adds them to `waves.md`)
| Id | Owner | What | Done when |
|---|---|---|---|
| **E7.M1** | four-wizards-high | `data/maps/two_harbours.map` (was E5.M1): every row of the Map table at its coordinates +-0.5 m, river + moat + 6 crossings, the island and arena match `forge_tollrock` within 1 m; `two_harbours_duel.map` later | Map Lab >= 90 |
| E7M1.S1 | systems | `missions/mission_e7_01.tscn` + `MissionE7_01`: loads the map, `RiverSystem.setup`, 4 seats on 2 sides, start state exactly as the table (350 / 400 / 0 gold / 15 of 40, pre-built Hall + Lodge, Lodges max 4), the Diamond Harbour as a 2 500 HP target post, the Tollrock point (shrine, r 6, 15 s, toll +30 / min), Facetguards and Gilded Spear guards, trade overrides (posts 2:00, caravans 4, Magpies / Lodges off, route values x1.5 on both north harbours) | `tests/test_e7m1_s1.gd`: start state, a caravan delivers 24 gold at the Diamond Harbour, the toll pays 5 gold every 10 s |
| E7M1.S2 | systems-high [H] | `DragonAuction` (`scripts/campaign/dragon_auction.gd`, reused by e7m4): schedule, window, banner data, bids (player keys, scripted Aurivane curve and ceilings), promises paid at the hammer, the rock's word, Malrik's 200, won / lost dragon handover; objectives and events E1-E25, waves W1-W5 / Laurel / Final with the -40 % and -30 % dragon rules, win / lose table, difficulty table, `MISSION_REWARDS[&"e7m1"]` | `tests/test_e7m1_s2.gd`: fixed-bid auction outcomes (lead, short coffers, rock's word); 2 Aurivane wins = defeat; a scripted run wins |
| E7M1.G1 | gameplay | UnitTypes `gilt_dragon`, `prism_dragon`, `ossavar_story` (flyer titans, not commandable, not `"beasts"`, never die: disengage at 15 %), `seraphine_story` / `dacian_story` (kits 6.5), `gilded_spear` (180 HP, armor 10, 14 dmg, 2.2 m, 1.2 s, 4.6 m/s, sun-disc shield -20 % from ranged), `facetguard` (220 HP, armor 20, 16 dmg, 2.0 m, 1.4 s, 4.0 m/s), `gold_knife` (150 HP, armor 5, 14 dmg, 1.0 s, 5.4 m/s; death = `violet_smoke`) | Unit tests on each kit |
| E7M1.A1 | ai | `AuctionDragonBrain` (6.3 target rule); profiles `mission_e7_01_enemy` (defend only, 10 at the rally, no trade) and `mission_e7_01_ally` (Malrik: Supportive, 16 pop, pings, never spends side gold, the 3 scripted pushes, 6.4) | A dragon follows the side's largest group; Malrik never bids |
| E7M1.I1 | items | `heartfrost_splinter` ItemType (artifact, campaign_only) + Long Winter (+1 s on the wearer's spell chills) | Test: Rime Bolt chill 3 s -> 4 s with it |
| E7M1.U1 | ui | Auction banner (portrait, two bids, countdown, rock icon, `Aurivane hesitates...`), Bazaar card bid buttons C / V during the window, objectives panel (auction counter + next time, harbour HP bar, Seraphine marker), DialogueBox colours / names for `ossavar`, `herald`, `dacian`, `seraphine`, `aldra`; briefing after `ep7_opening`; layout by ui-designer | Screens in the UI Lab |
| E7M1.C1 | systems-high (after 19.C1 / 19.C2) | `e7m1_arrival`, `e7m1_laurel`, `e7m1_dusk` with the skip end states; StoryFlow `ep7_opening` -> briefing -> e7m1 -> `c_e7_ledger` | `cine check` 0 FAIL; skip lands in the listed states |
| E7M1.V1 | tech-artist | Mission dressing (the north / south shore paints, the trade-post-as-target damage states, the lighthouse capture prop, the Laurel ring decal, `violet_smoke` puff); the game models of Ossavar (e7o A1, game budget), Kesh / Morrow (A2 as units), Dacian / Seraphine (A3 / A4), Gilded Spear / Facetguard (A5) | 0 lights, Art Lab pass, contact sheet at 40 m |
| E7M1.O1 | Voice Forge agent | Audition and add `ossavar`, `herald`, `dacian`, `seraphine` to `cast.json` (e7o 4.3 proposals), then render the 41 lines | Every WAV fits its slot |
| E7M1.D1 | game-designer | Read the 41 lines in game once, trim over-long ones; write `c_e7_ledger` (1:10) from the beats above | Script in the episode-opening format |
| Lead | lead | Acceptance checks 1-8 | All pass |
Dependencies (must exist first): E7.M1 map; the D2 rename of `episode5-opening.md` (done: the file is `episode7-opening.md`; its
inner title and `E5.*` ids still read "Episode 5" for the lead's edit); step 10 trade (GoldBank, Market, Caravan); the 2v2 seat
API and ally layer (`ai-2v2.md`, step 20); `RiverSystem` / `CapturePoint` (step 12); `MissionBase` (M9.S1); the titan flyer code
(step 13 / 13c); 19.C1 / 19.C2 for the cutscenes only (the mission plays without them).

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Rimecarver.
- **Why here:** a map of doors (6 m causeways, fords, 5 m bridges): a Bulwark closes one with 2 casts; a Rune watches a ford.
- **Moment:** W1 (4:30), 3 Blaze Riders on a caravan; hint E8 "Bulwark the causeway: the riders stop, the caravan doesn't.".
- **Intro card:** `Rimecarver. The wall comes to you: close a door in front of the charge, see what hides behind it.`

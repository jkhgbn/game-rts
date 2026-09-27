# Fill the map: river, biomes, capturable points, neutral camps (Crown Hollow)

Task 12.D1, written 2026-09-26. Source of truth for step 12 (tasks in section 13). User request: Crown Hollow must feel
**full**; the user chose all four packages: (1) nature and decor (vegetation, biomes, ruins, landmarks, ambient critters;
cosmetic), (2) capturable points (watchtowers, shrines, essence wells), (3) neutral monster camps (essence / XP / items,
respawn, tiers), (4) a river with bridges and fords that fits the step-10 ring road. Every name, creature, rule and number
here is our own. Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `+x` east, `+z` south (down on
the minimap). **Point mirror**: everything at `(x, z)` on the player (south-west keep) side exists at `(-x, -z)` on the enemy
(north-east keep) side. Builds on `skirmish-1v1.md`, `balance-1.md`, `balance-2.md`, `items.md`, `champions.md`,
`market-trade.md` (step 10), `skills-rework.md` (step 11), `ai.md`, `fog-of-war.md`, `levels.md`, `docs/art/lighting.md`.
**Balance context:** bot-vs-bot games with champions end at ~9-11 min (target 15-20). Everything here is tuned to give
armies reasons to spread out, to add defender-friendly chokepoints and PvE income that both sides share, and **not** to
snowball the leader.

## 0. User decisions (final, 2026-09-26)
| # | Question | Decision |
|---|---|---|
| Q1 | River layout | **North-south river with Crown Isle**: 2 Crown Bridges + 2 Crown Steps onto the isle, 2 road bridges, 2 guarded fords (section 2). Each side has one tavern and one peddler on its own bank; the rich nodes stay contested |
| Q2 | Wayshrines | **Wake in turn**: both at 3:00, then one every 3 min, alternating banks (the side slower at 3:00 gets the next one on its bank) |
| Q3 | Anti-snowball | **Underdog bonus on camps** (+25 % XP, +50 % clear bonus for the side whose wizard is lower level) **and bot creeping** instead of weak attacks |
| Q4 | Critters | **Deer and rabbits are huntable** by an explicit attack order only (tiny reward, section 3.4); units never auto-aggro them. Birds, butterflies, fireflies, dragonflies, frogs and fish stay cosmetic. Rewards are a `reward: Dictionary` (`{essence: 5}`) so step 15 (food and supply) can add `food` later |
| + | Epic beasts (later request) | **4 kinds x 2 variants** of big, rare, roaming wild beasts (Tusker, Roc, Direwolf, Grizzlemaw; section 5.5), one lair per kind per bank, mirrored; XP, item drops with trophy hooks, `reward` dictionary for step-15 food; champions hunt them in parties and take Hunt flags |

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| River course | North edge -> Crown Isle moat -> south edge, **point-symmetric**, crossing the ring road once in the north and once in the south (road bridges) | A single river channel that is point-mirrored must pass through the centre; the crown is there, so the river splits around it (a moat). North-south separates the two keeps (west bank = player, east bank = enemy) |
| Crossings | **8**: 2 road bridges (on the ring road), 2 fords (guarded by a Mirefang nest), 2 Crown Bridges (on the lane) and 2 Crown Steps (shallow moat fords) onto the isle | Enough routes to avoid a stalemate, few enough to make real chokepoints |
| How the river blocks | **Navmesh carve** (`NavigationObstacle3D`, `affect_navigation_mesh`) of deep water; fords and bridge spans stay walkable. No physics colliders (no unreachable navmesh on top) | Pathing, clicks, fog, spells and projectiles all keep working on the flat ground |
| Look | The ground is **cut open** along the river (ground shader discard) over a trench mesh; water surface at y **-0.35**; bridges are real decks at y 0; fords are a thin water film on the ground | Real depth and real bridges on a flat collider |
| Fords | Walkable, **-35 % move speed** (modifier `terrain:ford`), no building | Slow flank routes |
| Capturable points | **4 watchtowers** (sight 22), **2 essence wells** (+0.4 essence / s), **2 Wayshrines** (60 s team blessing, wake in turn) | Information, income and timed fights, spread over every region |
| Capture | Stand near it with soldiers / wizard / champions, no enemy there; owner keeps it without presence | Same "presence" idea as the trading posts' held rule |
| Neutral camps | **8 camps** in 4 kinds, tiers 1-3, respawning, plus the Ruin Wardens (unchanged) | PvE XP / essence / items for both sides; the fords and the isle are guarded early |
| Epic beasts | 8 lairs (4 per bank), one beast each, variants alternate per spawn, first spawns 6:30-10:00, respawn 10-12 min; they fight only combatants and are never shot by towers | Big mid-game PvE fights away from the lane, a job for champion parties |
| Anti-snowball | Chokepoints favour the defender; camps pay both sides; underdog bonus (Q3); capturing on the enemy bank takes x1.25; blessings are sustain, not damage; the bot creeps when it cannot attack | Games must get **longer**, not shorter |
| Decor | 6 biomes (Hearth Meadow, Heath, Riverbank, Old Wood, Wildflower Glade, Crown Isle ruins), landmarks, cosmetic critters; MultiMesh, shader wind, visibility ranges | Cosmetic, cheap, no gameplay effect |
| Game critters (Q4) | 6 deer + 12 rabbits, huntable only on an explicit attack order: deer `{essence: 5}` + a small heal ("venison"), rabbit `{essence: 1}`; no XP; ~260 essence map-wide in 20 min even if farmed perfectly | A tiny, fun side-reward that never distracts automatic combat; the reward dictionary is the hook for step-15 food |
| Fairness | Every object that touches navmesh, fog or gameplay is point-mirrored; decor scatter is not (cosmetic) | Mirror runs must stay within 1.1x (`balance-2.md`) |

## 2. The river "Hollowmere" (systems 12.C1, look 12.V1-12.V5)
### 2.1 Course and sizes
| Part | Geometry (player half; the other half is the point mirror) | Size |
|---|---|---|
| North river | Centre polyline `N0 (-15, -62)`, `N1 (-12, -48.7)`, `N2 (-9, -38)`, `N3 (-8, -30)`, `N4 (-5, -21)`, `N5 (-2.5, -12.5)` (N0 lies 2 m outside the map, under the north cliffs) | Water **5 m** wide (half 2.5) |
| South river | Mirror: `S0 (15, 62)`, `S1 (12, 48.7)`, `S2 (9, 38)`, `S3 (8, 30)`, `S4 (5, 21)`, `S5 (2.5, 12.5)` | 5 m |
| Moat (Crown Isle) | Circle centre `(0, 0)`, centre-line radius **12.75**, water from r **11.0** to r **14.5**; N5 and S5 join it (at 258.7 deg and 78.7 deg) | 3.5 m |
| Crown Isle | Land r < 11: crown pedestal, pillar ring r 8, 4 Ruin Wardens at r 4 (all unchanged) | |
| Depth (visual) | Ground cut open where water is deep; water surface **y -0.35**, trench bed y -1.0, bank lip 0.35 m | |
Angles below: `atan2(z, x)` in degrees (0 = east, 90 = south, 180 = west, 270 = north).

### 2.2 Crossings (ids used by code, UI and the bot)
| id | Name | Kind | Centre | Size / orientation | Notes |
|---|---|---|---|---|---|
| `bridge_road_n` | Saltgate Bridge | Road bridge | `(-12, -48.7)` | Deck 6 m wide (along the river), 9 m long (along the road) | On ring segment `nw2 - n_door`. Player far route to Saltgate and enemy far route to Heron Ford cross it |
| `bridge_road_s` | Millstone Bridge | Road bridge | `(12, 48.7)` | Mirror | On `se2 - s_door`. Player far route to Lantern Wharf, enemy far route to Millstone Cross |
| `ford_n` | Reed Ford | Ford | `(-8.5, -34)` | Walkable circle r **3.5** across the channel | Reed Ford Nest (Mirefangs, section 5) sits in it |
| `ford_s` | Willow Ford | Ford | `(8.5, 34)` | Mirror | Willow Ford Nest |
| `bridge_crown_w` | West Crown Bridge | Lane bridge | `(-9.02, 9.02)` (135 deg, r 12.75) | Deck **8 m** wide, 6.5 m long, along the lane (radial) | The lane crosses the moat here |
| `bridge_crown_e` | East Crown Bridge | Lane bridge | `(9.02, -9.02)` (315 deg) | Mirror | |
| `steps_nw` | North-west Crown Steps | Moat ford | `(-9.02, -9.02)` (225 deg) | Walkable circle r **3.0** | 3.5 m from the west tavern's door `(-11.5, -11.5)` |
| `steps_se` | South-east Crown Steps | Moat ford | `(9.02, 9.02)` (45 deg) | Mirror | Beside the east tavern |
- **Banks.** The **west bank** (player) is all land connected to the player keep without using a crossing; the **east bank**
  (enemy) likewise; the **isle** is r < 11. `RiverSystem.bank_of(pos)` returns `Unit.Team.PLAYER`, `Unit.Team.ENEMY` or -1
  (isle or water). West bank holds: the player base, its natural, both west posts (Heron Ford, Millstone Cross), the
  north-west corner (rich node `(-40, -40)`, Den, Lodge), the west tavern `(-15, -15)` and peddler `(-22, -22)`.
- **Straight-line reach by path** (for checking fairness; mirror values are identical): player keep -> own rich node 83 m;
  enemy keep -> player-side rich node via Saltgate Bridge 85 m (the rich nodes stay contested, `balance-1.md` intent kept).
  Keep -> keep along the lane over the isle 122 m (unchanged); via a road bridge 152 m.
- Early game: the isle is guarded by the wardens (until ~7:00-9:00) and the fords by the nests (T2, from 0:00), so the
  **only safe early crossings are the two road bridges**: wizard harass paths become ~25 % longer.

### 2.3 How it fits the step-10 ring road and every existing spot
- The river crosses the ring road only at `bridge_road_n` / `bridge_road_s`; roads, road nodes, posts, guild houses, the M1
  Bazaar slot, S3 / S4 tower slots, ambush spots A1-A4 / W1-W2 (and mirrors), taverns, peddlers, halls, nodes, bot slots
  H1 / V1 / V2 / S1 / S2 / X1 / X2: **none moves**. Closest checks: tavern door 1.8 m from the moat edge, natural node edge
  1.4 m from the moat edge (workers mine from the west side), W1 3.4 m from the moat, S3 4.5 m.
- Route lengths and values of `market-trade.md` 4.3 are unchanged (roads unchanged). The waystone row skips 7 m around each
  road bridge. Caravans never use fords (they follow road waypoints over the bridges).
- **Coordinates that must move** (all mirrored):
| What | Old | New | Why | Owner |
|---|---|---|---|---|
| Lost Caches `CACHE_SPOTS[1]` / `[3]` | `(0, 30)` / `(0, -30)` | **`(-6, 27)` / `(6, -27)`** | 9.4 m from the ford nest: opening the chest would wake the Mirefangs. Keep -> cache 40.3 m (was 45; the other pair stays 45.6) | systems (skirmish.gd, 12.C1); `items.md` text |
| Crown camp drop `CAMP_DROP_POS` | `(0, 3)` (both items) | **Warden Scale at `(2, 2)`, Ember Draught at `(-2, -2)`** | Fairness fix noted in `balance-2.md` (drops were 58.7 vs 63.0 m from the keeps) | systems (12.C1) |
| Bot scout loop (`commander.gd SCOUT_PATH`, `ai.md` rule 6) | `(16, -6) -> (6, 16) -> (-16, 6) -> (-27, 27)` | **`(16, -6) -> (12, 22) -> (17, 47) -> (-2, 44) -> (-16, 6) -> (-27, 27) -> (-2, 44) -> (17, 47) -> rally`** (enemy bot; player-side bot mirrored) | `(6, 16)` is in the south river; the loop now crosses at Millstone Bridge instead of the guarded isle / ford | ai (12.A1) |

### 2.4 Navmesh, movement, building
| Rule | Value |
|---|---|
| Carve | `RiverSystem` adds `NavigationObstacle3D` children under the NavigationRegion3D before the first bake: `affect_navigation_mesh = true`, `carve_navigation_mesh = false` (the 0.5 m agent radius keeps units off the edge), `avoidance_enabled = false`, y -0.5, height 3. One convex-ish polygon per water piece: the river and moat **minus** the ford circles and the bridge deck rectangles (N river: 3 pieces, S river: 3, moat: 4 arcs between the crossings). The moat arcs: 153-211.5 deg, 238.5-297 deg, 333-31.5 deg, 58.5-117 deg (bridges span 36 deg, steps 27 deg at r 12.75). If the 12.C1 test finds navmesh inside deep water, the fallback is thin wall colliders (layer 1, 3 m tall) along each piece's outline, with the unreachable tops removed by `map_get_closest_point` checks: report it to the lead first |
| Safety | 5 Hz pass over `"units"`: a unit whose position is in deep water (knock-back, avoidance push) is moved to the nearest navmesh point (`map_get_closest_point`) with `reset_physics_interpolation()` |
| Fords | A unit inside a ford circle gets modifier `terrain:ford` `{"move_speed_pct": -0.35}`; removed when it leaves (same 5 Hz pass, hysteresis 0.3 m). Units in group `"amphibious"` (Mirefangs) are exempt |
| Bridges | Normal speed. Nothing special for pathing: the deck gap is ordinary navmesh |
| Building (`BuildGrid.check`, after "Blocked by an enemy unit", before crystals) | Any footprint cell within **1.0 m** of deep water, ford or bridge -> `"Can't build on water"`; any footprint cell within **8 m** of a crossing centre -> `"Too close to a crossing"` (no walling a bridge with Ice Walls or halls); within **8 m** of a camp spot -> `"Too close to a monster camp"` |
| Point targets | Spells may target water (area effects work there); Blink, Owl Stone and teleports snap to the nearest walkable point (already the rule for Blink); bounty Explore flags on water are refused `"Invalid target"` |
| Fog | Water does not block sight (fog has no line of sight). The minimap and the unexplored black cover the river like any ground |
| Magpies / trackers | Unchanged rules; the Den / Lodge "nearer" choice becomes **nearer by navmesh path length** (12.C5), so bands and trackers do not walk the long way round a river |

### 2.5 Fairness checks (tests in 12.C1)
- Every object with a collider, obstacle, fog or gameplay effect at `p` has its twin at `-p` (river polygons, crossings,
  points, camps, landmarks with colliders, Old Wood trees, willows).
- Navmesh path length from each keep's drop-off to each of these mirrored pairs differs by **< 1 %**: own natural, own rich
  node, the other rich node, both taverns, all 4 posts' doors, all 8 crossings, all 8 points, all 8 camps.

## 3. Biomes, decor, landmarks, critters (cosmetic; art 12.V2, 12.V6-12.V16)
### 3.1 Biome zones (first match wins; blend 4 m at borders; built only from mirrored features, so mirrored)
| # | Biome | Where | Ground (12.V2) | Decor set (per-biome agent) | Critters |
|---|---|---|---|---|---|
| 1 | Water | River and moat | Cut open (trench) | Lily pads, floating leaves on the surface; reeds in the trench edge | Dragonflies, frogs, rare leaping fish |
| 2 | **Riverbank** | Land within 6 m of the water edge | Wet dark earth to sand, pebbles at the lip | Reeds, cattails, river stones, driftwood, **willow trees** (real trees, 2.4) | Frogs, dragonflies, fireflies under willows |
| 3 | **Crown Isle ruins** | r < 11 (isle) and 3 m around landmarks | Existing broken flagstones (spot kind 1) + ember-scorched grass | Flagstone slabs, fallen column drums (flat, walk-through height < 0.4 m), ember moss, cracked statue bases, cold braziers | none (the wardens) |
| 4 | **Hearth Meadow** | Within 22 m of a base hub `(-36, 36)` / `(36, -36)` | Short bright lawn, clover | Short grass tufts, clover, daisies, dandelions, hay bales, a few fruit bushes | Rabbits, butterflies |
| 5 | **Old Wood** | Within 28 m of `(-50, -50)` / `(50, 50)` | Dark forest floor, needles, moss | Dark ferns, **glowing blue-cap mushrooms** (emissive, no lights), moss boulders, fallen trunks, roots, cobweb cards; + 2 extra tree clusters with colliders (2.6) | Deer, fireflies |
| 6 | **Heath** | `abs(x) > 44` or `abs(z) > 44` (the flanks by the posts) | Dry warm grass, purple / yellow blotches | Heather (purple), gorse (yellow), wind-bent tall grass, lichen stones | Birds, rabbits |
| 7 | **Wildflower Glade** | Everything else (midfields) | Today's lawn | Tall grass patches, flower clusters in 4 colours, butterfly bushes | Butterflies, birds |
Decor never grows within 1.2 m of a road / lane edge, on build slots, crystal nodes, points, camp spots, crossings or
landmarks (`MapDressingArt._blocked` + the river mask); construction sites still clear decor under them (existing).

### 3.2 Landmarks (fixed, mirrored; colliders on layer 1 before the bake unless "draw-only")
| id | Landmark | Player-side position | Collider | Biome |
|---|---|---|---|---|
| `lm_colossus` | **Fallen Colossus**: a toppled giant statue, head on its side + an open stone hand, moss in the eyes | `(-57, -16)` (mirror `(57, 16)`) | Within 3.5 m of the centre (head cylinder r 2.2 + hand box 3 x 1.5) | Heath |
| `lm_stump` | **Giant's Stump**: a hollow, cut stump of an enormous tree, 4 m wide, mushrooms and a burrow | `(-30, 20)` (`(30, -20)`) | Cylinder r 2.0 | Glade |
| `lm_stones` | **Standing Stones**: 6 leaning menhirs in a ring r 3, one fallen | `(-54, 20)` (`(54, -20)`) | 6 cylinders r 0.5 | Heath |
| `lm_aqueduct` | **Old Aqueduct**: two broken arches striding over the north river 6 m upstream of Saltgate Bridge | Piers `(-17.5, -55)` and `(-9.3, -55)` (mirror at the south river) | Piers r 0.9 on the banks; arches over the water draw-only | Riverbank |
| `lm_barge` | **Drowned Barge**: a half-sunk river barge with a broken mast | `(-6.2, -24.5)` in the north river (`(6.2, 24.5)`) | Draw-only (in deep water) | Water |
| `lm_mouths` | River mouths in the cliffs: a **waterfall** where the north river enters (and its mirror at the south edge: a gorge with rapids) | Map edge at `x -15 / 15` | Outside the map | Map dressing |
Each landmark keeps >= 6 m from roads, the lane corridor, slots, spots, points and camps (checked above).

### 3.3 Cosmetic critters (draw-only `CritterSystem`: not Units, no collider, no click, never in `"units"`, no fog source)
| Kind | Count (whole map) | Where | Behaviour |
|---|---|---|---|
| Birds (small finches / crows) | 3 flocks x 6 | 12 landing spots in glade / heath / meadow (mirrored list) | Peck on the ground; take off when a **visible** unit comes within 8 m, circle 6-10 s at 6-12 m height, land at another spot. **Not targetable** |
| Butterflies | 30 | Glade and meadow flower patches | Flutter loops within 3 m of their patch |
| Fireflies | 40 | Old Wood, under willows | Drift, blink (emissive dots) |
| Dragonflies | 12 | Over the water | Dart along the river, hover |
| Frogs | 10 | Banks, lily pads | Sit; jump into the water (y -0.35) when a visible unit comes within 4 m, reappear after 10 s |
| Leaping fish (optional) | - | Moat and rivers | One splash every 6-10 s somewhere in the camera view |
- **No information leak**: they react only to units **visible to the local player's team** (or own units), and are drawn
  only in cells the local team sees now (`FogOfWar` state 2). They are pure presentation (never read by gameplay).
- Only those within **50 m** of the camera focus animate (10 Hz logic + vertex animation); the rest are parked and hidden.
- "Map detail: Low" removes them. It never removes the game critters of 3.4 (same gameplay on every setting).

### 3.4 Game critters: huntable deer and rabbits (Q4; systems 12.C10, models 12.V15)
Deer and rabbits are **gameplay objects** (same state for both teams), hunted only on purpose.
| Kind | Count | HP | Armor | Radius | Speed (flee) | Home | Reward (`reward: Dictionary`) | Respawn |
|---|---|---|---|---|---|---|---|---|
| **Red deer** | 2 herds x 3 = **6** | **60** | 0 | 0.5 | 3.0 graze / **7.0** flee | North-west herd graze spots `(-36, -53)`, `(-52, -36)`, `(-44, -30)`, `(-30, -32)`, `(-56, -22)`, `(-40, -50)`; the south-east herd = mirrors | **`{essence: 5}`** to the hunter's team + **venison**: the unit that landed the killing blow heals **40 HP** and own units within 6 m heal **20 HP** | 1 deer per herd every **120 s** while the herd has < 3 |
| **Rabbit** | 6 per half = **12** | **12** | 0 | 0.25 | 2.0 hop / **6.0** bolt | Each wanders r 6 around a home: player half `(-30, 52)`, `(-52, 22)`, `(-24, 30)`, `(-40, 8)`, `(-10, 47)`, `(-54, -8)`; mirrors (every home and graze spot >= 14 m from camp spots, so a hunt never wakes a camp by accident) on the other half | **`{essence: 1}`** | Each one **90 s** after its death, at its own home |
| Rule | Value |
|---|---|
| Targeting | `team` NEUTRAL, `is_alive()`, `take_damage(amount, attacker)`, `target_radius()` (the "attack targets" contract), so `command_attack(critter)` works. They are **not** in `"units"` or `"buildings"`: **no auto-aggro, no attack-move, no tower / keep fire, no area spell, no Magpie, no camp creature** ever touches them. Only auto-attacks after an explicit order (right-click / A-click on the critter with units selected, or a wizard single-target attack) and champions' idle hunts (6) hurt them. Workers, caravans and trackers cannot hunt |
| Click | A small click shape on layer 2 that never collides with units (an `Area3D`; the selection ray also hits areas, 12.C6). Left-click = read-only card; right-click with units = attack; the attack cursor shows over them. Bounty flags on critters: `"Invalid target"` |
| Behaviour | Graze / hop between spots (navmesh path queries only when they move: at most one query per critter per 4 s). **Flee** when damaged, or when a PLAYER / ENEMY unit comes within **4 m** (deer) / **3 m** (rabbit) **and that unit is visible to every team whose fog shows the critter's cell** (so a critter never runs from a hidden unit in front of someone). Deer flee 12 m to the herd's graze spot farthest from the threat, rabbits bolt 5 m; never into water, never across a crossing |
| No information leak | Drawn and clickable only in cells the local team sees now (hidden like enemy units). A hidden hunter that damages a critter in a visible cell is revealed 2 m for 1 s (existing "hidden attacker" rule, extended to critters). Respawns happen only in cells **no team sees** (else it waits, retry every 5 s) |
| No farming power | No XP, no veterancy, no wizard share, no champion loot; kills count nowhere in the end-screen stats except `Game hunted 4`. Perfect farming of the whole map for 20 min: ~100 essence from deer + ~160 from rabbits (~7 % of one side's essence); normal play much less |
| Floating text | Own, visible only: `+5` essence (purple) and `+40` HP (green) on a deer kill; `+1` on a rabbit. No message line |
| Step 15 hook (food and supply) | Every critter reward is a `reward: Dictionary` handed to `CritterHerds.grant(team, reward, by)`; today only `essence` (and the venison heal) is paid. Step 15 extends the dictionaries (e.g. deer `{food: 10}` besides or instead of essence) without changing the hunt rules. Camp rewards (`NeutralCamp.reward_preview()`, `camp_cleared(camp, team, reward)`) use the same dictionary shape |

## 4. Capturable points (systems 12.C2; models 12.V17-12.V19; UI 12.D2 / 12.C6 / 12.C7)
### 4.1 The 8 points
| id | Name | Kind | Position | Mirror (id, name, position) | Nearer by path to |
|---|---|---|---|---|---|
| `tower_nw` | Rookwatch | Watchtower | `(-24, -41)` | `tower_se` Owlwatch `(24, 41)` | the **enemy** (70 m via Saltgate Bridge vs 86 m): a far-corner tower |
| `tower_s` | Millwatch | Watchtower | `(-6, 40)` | `tower_n` Saltwatch `(6, -40)` | the player (37 m vs ~100 m): a home tower over the south crossings |
| `well_w` | Mossmere Well | Essence well | `(-30, -24)` | `well_e` Stonemere Well `(30, 24)` | the player (68 m vs 76 m via Reed Ford) |
| `shrine_w` | West Wayshrine | Wayshrine | `(-22, -6)` | `shrine_e` East Wayshrine `(22, 6)` | the player (53 m vs ~80 m over the isle) |
Each tower sees both crossings of its river half (sight 22 reaches Saltgate Bridge / Reed Ford from Rookwatch and from
Saltwatch across the water). Clearances: >= 13 m from ford nests, >= 15 m from the stag, >= 8 m from peddlers, halls
and posts, >= 7 m from road centre lines.

### 4.2 The node (`CapturePoint`)
| Kind | Footprint (blocks grid and navmesh) | Capture radius | Capture time (1 unit) | Look |
|---|---|---|---|---|
| Watchtower | 4 x 4 (~9 m tall) | **7** | **12 s** | Ruined stone tower, rebuilt timber crown, a banner and brazier in the owner's colour |
| Essence well | 3 x 3 | **6** | **15 s** | Old stone well, violet essence mist rising, rim runes in the owner's colour |
| Wayshrine | **none** (a ground circle + a floating rune stone at y 1.6; units walk through) | **6** | **8 s** | Standing stone with a floating glyph; dark when dormant, bright when awake |
- Neutral (`team` NEUTRAL), **invulnerable, never a target**, ignored by every unit, clickable (layer 2, group
  `"capture_points"`), like trading posts. Clearing r 4 (tower), 3.5 (well), 3 (shrine: decor only).
- Fog: explored for **both teams from 0:00** (`FogOfWar.reveal(team, pos, 5)`: landmarks, like posts and taverns). Owner and
  shrine state are public (always shown once explored); the capture progress bar only where visible.

### 4.3 Capture rules (one pass per second, cached like `TradeNetwork` holders)
| Rule | Value |
|---|---|
| Who counts | Soldiers, wizards (**count 2**), champions. **Not**: workers, caravans, trackers, Magpies, camp creatures, buildings |
| Presence | Counters of team T within the capture radius; `n` = their count |
| Capturing | T has presence and the other team has none: progress += `rate / capture_time` per second, `rate = min(1 + 0.25 x (n - 1), 1.75)` |
| From the enemy | An enemy-owned point is first **neutralised** (full capture time, the point turns neutral: message), then captured (full time again) |
| Far bank | A point on the other team's bank (`bank_of(point) == other team`) takes **x1.25** time for T |
| Contested | Both teams present: progress frozen, ring flashes |
| Abandoned | Nobody present: progress decays **10 % / s** back to the current state (half-captured points revert) |
| Ownership | Kept without presence (no decay). Owner changes only by the rules above |
| Available | Towers and wells from 0:00; wells **pay** from **2:30** (`The essence wells are brimming`); shrines by their schedule (4.4) |
| Messages | `Your forces captured Rookwatch` / `The enemy captured Rookwatch` / `Rookwatch was neutralised` / `Your forces are capturing Mossmere Well` (first time per point per 60 s, own only) / `The enemy is taking Mossmere Well!` (own point, max once per 20 s) |
| Kind | Effect for the owner |
|---|---|
| **Watchtower** | A permanent fog source **sight 22** at the tower (a `SightMarker`, lifetime 0, re-created for the new owner); the minimap draws its sight circle (own) |
| **Essence well** | **+0.4 essence / s** (+2 every 5 s, `EssenceBank.add`; 24 / min) from 2:30; the owner's **wizard** within 8 m regenerates **+3 mana / s** |
| **Wayshrine** | Capturing an **awake** shrine grants the capturing team the **Wayfarer's Blessing** for **60 s** and puts the shrine to sleep (4.4) |
### 4.4 Wayshrines: schedule and blessing
| Rule | Value |
|---|---|
| First waking | **3:00**: **both** shrines wake (`The Wayshrines awaken`) |
| Then | Every **180 s** (6:00, 9:00, 12:00, ...) **one** shrine wakes, alternating banks. The first alternate (6:00) is the shrine on the bank of the team that captured its 3:00 shrine **later** (or not at all); both equal -> seeded coin flip (match rng, mirrored start) |
| Awake | Stays awake until captured (a second shrine may wake meanwhile). Awake shrine = gold glow, minimap pulse, message `The West Wayshrine awakens` |
| Captured | Blessing to the capturer; the shrine sleeps (shows the capturer's colour until it wakes again, then neutral) |
| Blessing (modifier `blessing:wayshrine`) | Every soldier, wizard and champion of the team, now and spawned during it: **`move_speed_pct` +0.12, `hp_regen` +1.5**; 60 s; capturing another shrine while blessed resets it to 60 s (no stack). Not on workers, caravans, trackers |
| Why sustain, not damage | It lets the smaller army walk away and heal; it does not win the next fight by itself |
| Messages | `Blessing of the Wayshrine: +12 % speed, +1.5 HP / s for 60 s` (own) / `The enemy received the Wayshrine's blessing` |

## 5. Neutral monster camps (systems 12.C3; creatures gameplay 12.C4; art 12.V20-12.V24)
### 5.1 The creatures (`data/units/<id>.tres`, team NEUTRAL, faction `&"neutral"`, `neutral_leash = true`, group `"creatures"`)
| id | Name | HP | Armor | Dmg | Range | CD | DPS | Speed | Aggro | Sight | Radius | Height | kill_xp | Strength | Ability |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `bristleback` | Bristleback | 200 | 5 | 11 | 1.4 | 1.2 | 9.2 | 4.6 | 6 | 8 | 0.55 | 1.1 | **25** | 100 | - |
| `mirefang` | Mirefang | 190 | 0 | 10 | 1.3 | 0.9 | 11.1 | 5.0 | 6 | 8 | 0.45 | 0.8 | **30** | 110 | amphibious (no ford slow) |
| `gloomcap_elder` | Gloomcap Elder | 420 | 5 | 14 (bolt, speed 14) | 6.0 | 1.6 | 8.8 | 3.2 | 7 | 9 | 0.6 | 1.9 | **50** | 220 | **Spore Burst** |
| `gloomcap_sprout` | Gloomcap Sprout | 120 | 0 | 7 | 1.2 | 1.0 | 7.0 | 4.0 | 6 | 7 | 0.35 | 0.7 | **12** | 50 | - |
| `hollow_stag` | Hollow Stag | 1 400 | 15 | 30 | 2.0 | 1.6 | 18.8 | 5.0 | 8 | 10 | 0.9 | 2.6 | **160** | 700 | **Antler Sweep** |
| Ability | Rule |
|---|---|
| Spore Burst (Elder) | Every 10 s while fighting: at its target's position, r 3: **20 damage** + status `marked` 4 s (damage taken x1.15; existing status) on PLAYER / ENEMY units |
| Antler Sweep (Stag) | Every 8 s while fighting, when 2+ enemies are within 3 m: **35 damage** to every enemy within 3 m of it |
Kill XP / essence use the normal victim rules (`levels.md`: killing blow team, 20 m wizard share, soldiers' veterancy;
essence 60 %; champion loot 25 %). Kills **by** creatures credit nobody. Creatures never level; their HP bar is the
neutral colour. Victim rows to add to `levels.md`: Bristleback 25, Mirefang 30, Gloomcap Elder 50, Gloomcap Sprout 12,
Hollow Stag 160.

### 5.2 The 8 camps
| id | Name | Tier | Creatures | Position | Mirror | Nearer by path to | First spawn |
|---|---|---|---|---|---|---|---|
| `camp_wallow_s` | Bristleback Wallow | 1 | 2 Bristlebacks | `(-14, 57)` | `camp_wallow_n` `(14, -57)` | player (32 m from its keep) | 0:00 |
| `camp_nest_s` | Willow Ford Nest | 2 | 3 Mirefangs, **in Willow Ford** | `(8.5, 34)` | `camp_nest_n` Reed Ford Nest `(-8.5, -34)` | player (52 m vs ~85 m) | 0:00 |
| `camp_hollow_nw` | Gloomcap Hollow | 2 | 1 Elder + 3 Sprouts | `(-55, -55)` (the nook behind the Den and Lodge) | `camp_hollow_se` `(55, 55)` | **both** (99 m vs 99 m): contested | 2:30 |
| `camp_stag_w` | Stag Glade | 3 | 1 Hollow Stag | `(-37, -10)` | `camp_stag_e` `(37, 10)` | player (51 m vs ~92 m) | 3:30 |
| (existing) | Ruin Wardens | 4 | 4 Ruin Wardens | Crown Isle | - | both | 0:00, never respawn |
- Creatures stand in a loose ring r 1.5-2 around the spot (the stag at the spot). Leash = aggro x 2 (existing rule).
- Clearances: every camp spot >= 9 m from road centre lines (caravans pass untouched), >= 14 m from crystal nodes and
  build slots, >= 10 m from ambush spots, cache opening points and guild doors (aggro + 2 m), and capture circles at least
  aggro + 2 m away. The Gloomcap nook is reached through a 5.7 m mouth between the Den and the Lodge: a tight fight on
  purpose.
- Fords: a living nest blocks its ford (units using it are attacked); the ford opens when the nest is cleared and closes
  again when it respawns.

### 5.3 Rewards, respawn, reset
| Rule | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| Camp XP (sum of kill_xp) | 50 | 90 (nest) / 86 (hollow) | 160 |
| **Clear bonus** (essence to the team credited with the last kill) | **10** | **25** | **50** |
| Item drop on the ground at the spot | 30 %: Ember Draught | 35 %: a random base component (the 10 "Base" ones of `items.md`), else 50 %: Ember Draught or Dusk Vial | **1** random base component + **40 %**: Warden Scale or Vital Root |
| Respawn after the last kill | **120 s** | **180 s** | **240 s** |
| Respawn blocked | While any PLAYER / ENEMY unit is within 16 m of the spot (retry every 5 s) | | |
| Camp level | +1 per respawn, max **3**: creatures HP +15 %, damage +10 %, kill_xp +10 %, clear bonus +10 % per level | | |
- **Reset (leash)**: a creature within 3 m of home and not damaged for 4 s regenerates 5 % max HP / s; when all creatures are
  home and undamaged for 6 s, the camp is healed in full (no chip-damage farming).
- **Underdog bonus (Q3)**: at each creature kill, if the killing team's wizard level is **lower** than the other wizard's,
  that kill's XP is x1.25; at the clear, the clear bonus is x1.5. Message (own) `Underdog bonus: +50 % from the Stag Glade`.
- Champions: their own killing blows give them loot (25 % of the victim's XP value, existing rule); the clear bonus always
  goes to the team bank. Items lie on the ground (wizards pick them up; champions never pick up ground items).
- Messages: `Stag Glade cleared: +50 essence` (own, and `+ Warden Scale dropped` when there is one) / `The enemy cleared the
  Gloomcap Hollow` (only if the spot is visible to you) / `The Hollow Stags roam the glades` (3:30, once).

### 5.4 Who can clear what (fight checks)
| Party | Camp | Result |
|---|---|---|
| L1 wizard + 3 Flame Guards (~59 effective DPS) | Bristleback Wallow (400 HP, 18 DPS) | ~7 s, ~125 damage taken, no loss: **the 1:30-2:30 creep** |
| L1 wizard alone | Bristleback Wallow | Loses (dies at ~20 s): needs 2+ soldiers |
| 6 soldiers + L2 wizard | Ford Nest (570 HP, 33 DPS) | ~6-7 s, ~1 soldier lost: **3:00-4:30** |
| 8 soldiers + wizard | Gloomcap Hollow (780 HP, ~30 DPS + marks) | ~8 s, 1 soldier lost |
| 10-12 soldiers + wizard | Hollow Stag (1 400 HP, armor 15, ~36 effective DPS vs a clump) | ~14 s, 2-3 soldiers lost: **5:00-8:00**, before or after the crown camp (1 200 HP, 64 DPS) |
| L3 Coin-Cutter alone (~348 HP, ~20 DPS) | Bristleback Wallow | Dies: champions solo a T1 only from **courage x power >= 1.6 x camp strength** (~L4 or a mid item) |
| L4 Oathwall (Sword and Shield) + L4 Mender (Wizard) | Hollow Stag | Wins with ~40 % HP each (Riposte, Draught, Circle) |

### 5.5 Epic beasts (user request; systems 12.C11, brain ai 12.A3, stats and abilities gameplay 12.C4, art 12.V27-12.V32)
Big, rare, dangerous wild animals. **4 kinds, each with 2 variants**; one beast per **lair**, 4 lairs per bank (8 on the map,
point-mirrored). They are not camps:
| | Camps (5.2, incl. the Hollow Stag) | Epic beasts |
|---|---|---|
| Position | Stand on a fixed spot, leash = aggro x 2 around it | **Roam a territory** (4 patrol points, 10-20 s pause at each) and fight anywhere inside it (leash = territory radius + 10 m around its centre) |
| Size / fights | 1-4 creatures, T3 = 1 400 HP | One beast, **1 300-3 000 HP**, 2 abilities, an enrage or escape phase |
| Targets | Any enemy unit in aggro (and buildings like any neutral) | Only **combatants** (soldiers, wizards, champions, trackers). **Ignore workers, caravans and buildings**; towers and keeps never shoot them (they cannot farm a beast) |
| Timing | 0:00-3:30 first spawns, respawn 2-4 min | First spawns **6:30-10:00**, respawn **10-12 min**, announced to both teams |
| Rewards | Clear bonus essence + small drop table | Big XP (normal victim rules, underdog x1.25), a **drop table** with a guaranteed component, **trophy hooks** and a **`reward` dictionary** for step-15 food |
| Brain | Built-in neutral leash | `BeastBrain` (like the Magpies' band brain): patrol, pick targets, leash reset, abilities through `CreatureAbilities` |

**Variants.** Each lair counts its spawns: spawns 1, 3, 5... are **variant A**, spawns 2, 4... **variant B** (the alpha, elder
or rarer breed). Mirrored lairs follow the same rule, so both sides see the same sequence. Variant B has a different look
(same scene, `set_variant(1)`), and one stat / ability / reward change.

| Kind (lair) | Variant A | Variant B | HP | Armor | Dmg / CD (DPS) | Range | Speed patrol / fight | Aggro | Radius | kill_xp (A / B) | Strength (A / B) | Abilities |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Tusker** (giant boar) | Ironhide Tusker | **Old Scarback** (scarred alpha, x1.15 size) | 1 800 (B 2 160) | 20 | 34 / 1.5 (22.7) | 1.8 | 3.5 / 5.5 | 8 | 1.0 | 110 / 130 | 900 / 1 080 | **Gore Charge** (every 12 s, a target 6-14 m away: dash at 12 m/s, 45 damage + `dazed` 0.8 s; 20 to units within 1.5 m of its path; **B**: full 45 + `dazed` 1.2 s to everyone on the path). **Bristle Hide** (passive): melee attackers take 4 damage per hit |
| **Roc** (sky bird; glides 2.5 m up but walks the navmesh, never crosses water) | Stormcrest Roc (storm-blue) | **Duskwing Roc** (dark breed) | 1 500 | 5 | 24 / 1.2 (20) | 3.0 | 3.5 / 6.5 | 10 | 0.9 | 100 / 100 | 800 / 800 | **Gale Swoop** (every 10 s: leaps up to 12 m onto the enemy with the most enemies within 3 m: 40 damage r 2.5 + `dazed` 0.5 s; **B** = Shrieking Dive: `marked` 5 s instead of the daze). **Updraft** (once per life at 40 % HP: `shroud` 4 s, flies to its nest, heals 15 % over 4 s) |
| **Direwolf** | Greymane Direwolf | **Moonpelt Direwolf** (silver breed) | 1 300 | 10 | 26 / 1.0 (26) | 1.6 | 4.5 / 7.0 (B 7.5) | 9 | 0.8 | 90 / 105 | 700 / 780 | **Pounce** (every 9 s, B every 6 s: leaps onto a target 5-10 m away, 35 damage + `rooted` 0.8 s). **Hamstring** (passive): its hits give `move_speed_pct` -0.25 for 3 s (modifier `beast:hamstring`) |
| **Grizzlemaw** (cave bear) | Grizzlemaw | **Elder Grizzlemaw** (white muzzle, larger) | 2 600 (B 3 000) | 25 | 42 / 1.8 (23.3) | 2.0 | 3.0 / 5.0 | 9 | 1.1 | 180 / 210 | 1 300 / 1 500 | **Maul** (every 9 s: 70 damage to its target + `marked` 5 s). **Rending Roar** (at 50 % HP, then every 30 s: enemies within 6 m `dazed` 1.0 s, half on heroes; **B**: also `taunted` 3 s on non-hero units). Below 30 % HP: `attack_cooldown_pct` -0.3 (enrage) |
All beasts: team NEUTRAL, faction `&"neutral"`, `neutral_leash = false` (the brain leashes them to the territory), group
`"beasts"`, `aggro_range` 0 in the `.tres` (the brain picks targets), sight 11-14. They never level; kills by beasts credit
nobody. Victim rows for `levels.md`: the kill_xp column.

| Lair (player bank; mirror) | Centre, radius | Patrol points | Kind | Nearer by path to | First spawn | Respawn |
|---|---|---|---|---|---|---|
| **West Heath** (beside the Standing Stones) | `(-53, 13)` r 4 (`(53, -13)`) | `(-53, 9)`, `(-57, 13)`, `(-52, 17)`, `(-49, 13)` | Tusker | player (32 m vs ~150 m) | **6:30** | 600 s |
| **Colossus Crag** (nest on the Fallen Colossus) | `(-53, -18)` r 5 (`(53, 18)`) | `(-53, -13)`, `(-48, -18)`, `(-53, -23)`, `(-57, -21)` | Roc | player (62 m vs 106 m) | **8:30** | 600 s |
| **Greymane Hollow** (among the Old Wood trees west of the Den) | `(-56, -34)` r 4 (`(56, 34)`) | `(-57, -38)`, `(-56, -30)`, `(-53, -34)` | Direwolf | player (78 m vs 102 m) | **7:30** | 600 s |
| **Old Wood Den** (below the Old Aqueduct) | `(-26, -54)` r 5 (`(26, 54)`) | `(-26, -49)`, `(-31, -54)`, `(-26, -59)`, `(-21, -54)` | Grizzlemaw | **enemy** (69 m via Saltgate Bridge vs 98 m) | **10:00** | 720 s |
- Every lair edge is >= 13 m from crystal nodes and keeps, >= 9 m from bot build slots (beasts ignore buildings and towers
  ignore beasts), >= 10 m from camp spots and capture circles' centres (the Den's north patrol point passes 7 m from Rookwatch:
  the far-corner tower is a dangerous place on purpose), >= 8.9 m from trading-post doors, and >= 14 m from another lair's
  centre. Roads may cross a territory: beasts ignore caravans and workers. Patrol points snap to the navmesh.
- **Respawn**: counted from the death; delayed while any PLAYER / ENEMY unit is within 25 m of the centre (retry every 5 s).
- **Reset**: beyond its leash, or 8 s without a valid target, the beast walks back to its centre; after 5 s undamaged it
  regenerates 3 % max HP / s, and heals in full after 10 s.
- **Rewards**: the normal kill XP / essence (60 %) / champion loot (25 %) of the killing blow (underdog x1.25 XP as camps),
  plus its **drop table** on the ground and its **`reward` dictionary** through `EpicBeasts.grant(team, reward, by)`: **empty
  today** (`{}`); step 15 adds food (e.g. Tusker `{food: 40}`, Grizzlemaw `{food: 60}`) without changing the rules.
| Drop table id | Variant A | Variant B (adds) | Reserved trophy ids (dropped only when `ItemType.find(id)` exists; none today) |
|---|---|---|---|
| `tusker` | 1 of Ironbark Plate, Bone Charm, Swiftsoles + 30 % Vital Root | + 1 more of the same list | `ironhide_tusk` / `scarback_tusk` |
| `roc` | 1 of Swiftsoles, Cinder Ring, Mana Thread + 30 % Warden Scale | Duskwing's list: Duskglass Lens, Gloom Ink, Mana Thread | `stormcrest_plume` / `duskwing_plume` |
| `direwolf` | 1 of Whetted Fang, Ember Shard, Swiftsoles | + 40 % Vital Root | `greymane_pelt` / `moonpelt_pelt` |
| `grizzlemaw` | 1 of Ember Shard, Ironbark Plate, Bone Charm + 60 % Warden Scale or Vital Root | Warden Scale guaranteed | `grizzlemaw_claw` / `elder_grizzlemaw_claw` |
- **Messages** (both teams): spawn `An Ironhide Tusker roams the West Heath` / `Old Scarback, an alpha Tusker, roams the West
  Heath!`; death `Your army slew the Grizzlemaw` (own, + the drops) / `The enemy slew the Grizzlemaw`.
- **Fight checks** (normal): 12-14 soldiers + wizard kill a Tusker in ~15 s losing 2-3 (charges + bristles); a Grizzlemaw needs
  ~16 soldiers + wizard, ~22 s, 3-4 lost; a Direwolf picks off ranged units (Pounce + root) and loses to 10 soldiers in ~12 s;
  the Roc escapes once (Updraft) and must be chased to its nest. **Three level-4 champions** (or two level-6 with items)
  kill a Tusker, Roc or Direwolf; the Grizzlemaw needs the army.

## 6. Champions and the wizard (ai 12.A2 brain, systems 12.C5 bounties)
| Hook | Change |
|---|---|
| Presence | Champions count for capture (4.3) with no brain change |
| Bounties | **Hunt** on a creature is already valid (visible neutral unit). **Guard** may now target an **own-held capture point** (pays champions within 14 m, ends and refunds the rest if the point changes owner). **Explore** placed within 7 m of a point that is not own-held becomes a **Claim**: it pays when the point becomes own-held (pursuing champions stand in the capture circle) instead of on arrival; flag card text `Claim Rookwatch` |
| R4 join a fight | Creatures are visible enemies: champions join fights their army picks with a camp; danger includes camp strength (5.1) |
| Wayfinder default (R8) | When nothing unexplored scores: its patrol loop is **caches + taverns + the own bank's watchtowers**; a neutral or enemy-held own-bank tower on the loop -> stand in its circle until captured (max 25 s). Never paths into a camp's aggro (danger check) |
| Oathwall default | Patrol adds **own-held wells and towers within 35 m of an own building** |
| Coin-Cutter default (Raid) | Adds: a **T1 camp** on its own bank, alive, explored, when `courage x power >= 1.6 x camp strength` (after workers and looting Magpies, before caches) |
| Mender | Unchanged (follows the army, so it creeps with it) |
| Epic beasts: Hunt flags | A Hunt flag on a visible beast is valid (visible neutral unit) and pays the contributors when it dies; `bounty_threshold` unchanged. Flag card `Hunt Old Scarback · 1 080 strength` |
| Epic beasts: hunting party (new R8 step, before the personality default) | When **2+ own champions** are free (R8 / R9, not fleeing, HP >= 70 %) and a beast is **visible** or was seen in the last 30 s within 40 m of one of them, and `sum(courage x power) >= 1.2 x beast strength` -> they all attack it together (intent `Hunting big game`); they abort when the sum falls below 0.8 x (a champion flees / dies) or the beast escapes its territory. Never with a single champion. R4 still makes champions join any army fight with a beast |
| Idle hunt (R9, Wayfinder and Coin-Cutter only) | While `Idle`: a game critter (3.4) **visible** to its team within **15 m** of its idle area -> `command_attack` it (intent `Hunting game`), at most once per **120 s** per champion; drops it if it flees beyond 20 m or anything of R1-R8 fires. The reward goes to the team (and the venison heal to the champion) |
| The wizard (player) | Nothing new to learn: capture by standing, camps by attacking. Right-click a creature = attack. The camp's hover card shows the reward (UI) |

## 7. The bot (ai 12.A1: rules 11-13 of `ai.md`, knobs in `AIProfile` / `data/ai/*.tres`)
The bot knows the map (river, crossings, points, camp spots) and sees creatures and points' capture progress only through
its fog, as today. Creatures count **0** in `seen_strength` / `own_strength`; a camp's **strength** = sum of 5.1 x (1 + 0.15 x
camp level), used only by the rules below.
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `creep_start` | 4:00 | 2:00 | 1:30 |
| `creep_ratio` (own_strength >= ratio x camp strength) | 2.0 | 1.5 | 1.3 |
| `creep_tiers` | [1] | [1, 2, 3] | [1, 2, 3] + the contested hollow |
| `capture_squad` (soldiers) | 0 (wizard only, when passing) | 2 | 3 |
| `steal_points_ratio` (take enemy-bank points when own_strength >= ratio x max(seen, 250)) | never | 1.5 | 1.2 |
| `shrine_play` | own shrine only | own + contest the enemy's when ahead | both, arrives 15 s early |
| Rule | Trigger -> action |
|---|---|
| **11a Creep** | No attack group out, no defence, rule 7 did **not** launch this tick, time >= `creep_start`, a camp of an allowed tier alive on the **own bank** (or the own-near ford nest, or the hollow on hard) with `own_strength >= creep_ratio x camp strength` and no enemy army seen within 25 m of it in 30 s -> the group (army at the rally minus the reserve) `command_attack_move`s the camp spot; the wizard joins for tier 1 and when `malrik_joins` says so. **Creeping replaces weak attacks**: the bot farms instead of throwing an army at a stronger enemy |
| 11b Creep end | Camp cleared, or group HP < 50 % of launch (retreat), or a rule-1 intrusion (recall) -> back to the rally. The wizard picks up dropped items within 12 m first (normal / hard) |
| 11c Order | Nearest first; the stag only when `own_strength >= 900` (like the crown camp) |
| **12a Capture squad** | Every 20 s: the next point in order (own well, own home tower, the other own-bank tower, then enemy-bank points when `steal_points_ratio` holds) that is neutral or enemy-owned and has no enemy seen within 20 m in 30 s -> the `capture_squad` cheapest idle soldiers at the rally walk there (`command_move`, never attack-move), stand until captured (max 40 s), come back. One squad out at a time. Easy: its wizard captures points within 15 m of its path |
| 12b Point defence | An enemy capturing an own point within 35 m of an own building = rule-1 intrusion. Farther: if the seen capturers' strength <= 0.8 x rally strength, the rally group attack-moves there; else the point is lost (it goes back to 12a later) |
| 12c Shrines | 15 s before a shrine wakes on the **own** bank (normal: at the waking), the capture squad (or the wizard if no squad) goes there. An awake **enemy-bank** shrine and own_strength >= `attack_ratio` x seen -> it becomes rule 7's first target row (attack-move to the shrine, capture, continue) |
| **13a Scout** | The new scout loop of 2.3 (never through the isle while the wardens live, never through a ford with a living nest) |
| 13b Attack route | Default: navmesh (the lane over the isle). Hard: when a seen enemy tower covers the exit of the enemy's Crown Bridge (within 12 m) or 5+ enemy soldiers were seen holding it in the last 60 s, the attack goes through the ford or road bridge on the side with fewer seen towers (a waypoint at that crossing) |
| Champion **B8** (normal, hard) | An own-bank tower is neutral / enemy-held and no squad is going -> **Explore (Claim) 25** on it (max 1) |
| Champion **B9** (hard) | Rule 11a targets the stag or the hollow -> **Hunt 75** on its strongest creature |
| Champion **B10** (normal, hard) | An enemy seen within 25 m of an own-held well in the last 30 s -> **Guard 50** on the well (max 1) |
| **11e Epic beasts** | Treated like a camp in 11a (same launch conditions), with `beast_ratio` (easy never, normal **1.4**, hard **1.2**) x the beast's strength and only when no enemy army was seen within 30 m of the lair in 30 s. Normal: the three lairs of its own bank; hard: also the Grizzlemaw across the road bridge. The wizard always joins. Beasts count 0 in `seen_strength` / `own_strength` |
| Champion **B11** (normal, hard) | Rule 11e sends the army to a beast -> **Hunt 100** on it (hard 150), so the champions join and are paid |
| **11d Game critters** | Easy / normal: **ignored** (strength 0, never targeted, never in `seen`). Hard: a member of a returning capture squad (12a) that is ranged may `command_attack` a visible deer within **10 m** of its path (max one per 120 s, drops it after 8 s); never a detour for rabbits. The bot's champions follow the idle-hunt rule of section 6 like the player's |
- Expected (normal): home wallow cleared ~2:00-2:30 with 3-4 soldiers + wizard; the own ford nest ~3:30-4:30; the 3:00 shrine
  by the squad; the stag ~6:00-8:00 (before or right after the crown camp); the far-corner tower (enemy-near) lost and
  retaken a few times; attacks start ~1 min later than today because 11a absorbs weak launches.

## 8. UI: what must be shown (layout, sizes, looks: ui-designer, `docs/design/ui-mapfill.md`, task 12.D2)
| Element | Content | Interaction |
|---|---|---|
| **Objectives strip** (under the top bar) | 8 small point icons in map order (towers, wells, shrines), each filled with the owner colour (own green, enemy red, neutral grey); an awake shrine glows gold with `0:42` until the next waking when asleep; the own blessing as a buff chip `Blessing 38 s` (and the enemy's, red, when active) | Hover = point tooltip; click = centre the camera on it |
| Point in the world | Ground ring at the capture radius in the owner colour; while capturing, a progress arc in the capturer's colour; contested = ring flashes white | Click = point panel |
| **Point panel** (click a point) | Name, kind, owner, state (`Capturing 7 / 12 s`, `Contested`, `Asleep: wakes in 1:40`, `Awake`), effect line (`Sight 22 for its owner`, `+0.4 essence / s · +3 mana / s to your wizard within 8 m`, `Blessing: +12 % speed, +1.5 HP / s for 60 s`), `On the enemy bank: capture takes 25 % longer` | Read only; `Guard` bounty (R) works on own-held points |
| Camp hover / creature inspect | Creature single view (existing, read only) + a camp line: `Gloomcap Hollow · Tier 2 · 3 of 4 left · ~86 XP · +25 essence · 35 % a component`; a cleared camp the team saw cleared shows a floating `1:20` over its spot while visible | |
| Minimap | Water `(0.25, 0.45, 0.65)` in the ground layer, fords `(0.45, 0.62, 0.72)`, bridges in the road colour; watchtower 5 x 5 square, well 5 x 5 circle, shrine 5 x 5 diamond (fill = owner, pulse when awake); camp 4 x 4 in tier colour (T1 `(0.85, 0.85, 0.75)`, T2 `(1.0, 0.6, 0.25)`, T3 `(1.0, 0.3, 0.25)`), hollow outline when last seen cleared; own towers' sight circles as a faint 1 px ring. Points: always once explored; camps: once explored, last-seen state | |
| Messages | Sections 4.3, 4.4, 5.3; first-time hint at 0:40: `Stand near a watchtower, well or shrine with soldiers to capture it` | `show_message`; point lines max once per 20 s per point |
| Unit panel | The blessing and `terrain:ford` shown as buff / debuff icons on units (tooltips `Wayfarer's Blessing 38 s`, `Wading: -35 % speed`) | |
| Settings | **Map detail: High / Low** (default High). Low: decor density x0.5, critters off, simpler water (no foam scroll) | Applies at the next match start |
| Help text | Adds `Capture: stand near towers, wells and shrines` | |
| Epic beasts | Hidden in fog like any enemy unit; boss-style HP bar (wider, name + variant above it) while visible; minimap 6 x 6 paw icon `(1.0, 0.75, 0.2)` while visible; each **lair** as a faint dashed circle once explored, with a small paw at its centre while the beast is known alive (a spawn announcement makes it known); inspect card: name, variant, HP, armor, the 2 abilities, drop preview (`Drops: a component · 30 % Vital Root`), `Hunt it with a bounty: R`; spawn / death messages of 5.5 and a distant roar sound on spawn | Right-click = attack; R = Hunt flag |
| Game critters | Shown only where the team sees now; attack cursor on hover with units selected; left-click = read-only card (`Red deer · 60 HP · Hunt it: +5 essence, venison heals the hunter 40 HP` / `Rabbit · +1 essence`); floating `+5` / `+40` / `+1` (own, visible); no minimap dot, no message line | Right-click / A-click = hunt (explicit attack only) |
| End screen | `Points held at the end 5 / 8 · Camps cleared 9 · Blessings 3 · Game hunted 4` | |
| Audio (ui-coder, SFX bus) | Capture chime (own), distant horn when a shrine wakes, soft bubble on own well ticks (visible, max once per 10 s), drum when a camp is cleared (visible), the stag's roar when a fight starts (visible), wading splashes (quiet, max 3 at once) | |
No new keys (the Keys line stays as it is).

## 9. Performance budget (200 units + all of this must keep `PERF OK`)
| Part | Budget |
|---|---|
| New logic total | **< 0.2 ms / frame** on average: RiverSystem 5 Hz pass (ford modifiers, push-out) < 0.03 ms; CapturePoints 1 Hz presence pass (one loop over `"units"`, cached) < 0.03 ms; CampManager 1 Hz < 0.02 ms (creatures are ordinary Units); CritterSystem 10 Hz, only critters within 50 m of the camera < 0.08 ms; blessing modifiers applied once on grant / spawn |
| Units | 20 creatures + 4 wardens alive at most. Normal match peak ~110 units + champions + 28 trade units + 24 creatures ~ **170** (< 200). The perf test adds the river, 8 points and 20 creatures to its 200 units and must still print `PERF OK`, stuck = 0 |
| Decor | <= **12 000** instances total (today ~5 000), <= **24** decor mesh kinds (3 shape variants per mesh through the variant mask of `nature_painted.gdshader`), 3 x 3 chunks of 40 m (existing); visibility ranges: tufts / flowers / pebbles / lily pads end **65 m** (fade 10), bushes / reeds / ferns / mushrooms **90 m**, critters **50 m**; only trees, logs, big rocks, landmarks and bridges cast shadows |
| Water | One trench mesh + one water mesh per river part (<= 6 000 triangles total), one opaque material, no screen / depth texture reads, no real lights |
| Cosmetic critters | <= 120 on the map, <= 60 animated; one MultiMesh per kind (5 draw calls), vertex-shader wing / leg motion, <= 300 triangles each |
| Epic beasts | At most **8** alive (ordinary Units: a normal peak becomes ~180 units, still < 200); `BeastBrain` thinks every 0.5 s, staggered, reading cached `"units"` lists (< 0.03 ms / frame for all 8); abilities through `CreatureAbilities`; hero budget models. The perf test adds all 8 |
| Game critters | 18 nodes (6 deer, 12 rabbits), **not** in `"units"` (so no other system's unit loop grows); logic at 5 Hz staggered, navmesh path query only on a move (<= 1 per critter per 4 s), fog visibility read at the fog's 5 Hz tick: **< 0.03 ms / frame**; one `Area3D` click shape each; models <= 1 200 triangles (deer) / 300 (rabbit), 1 material, 0 lights; the perf test adds them |
| Emissive decor | Glow mushrooms, fireflies, braziers: emission only (no `OmniLight3D`) |
| Rendered frame (lead check, windowed 1600 x 900, this PC and the RTX 3070 laptop) | Frame time at default zoom over the Crown Isle and over the Old Wood **<= +10 %** vs the step-11 build; >= 60 fps at max zoom (55) over the whole river |

## 10. Art list (tech-artists, one agent each; global style `art-keep.md` section 0: chunky, hand-painted, SC2 / LoL readable, 2-4 glow points at 40 m)
| Id | Asset | Look (the 40 m black test for objects) | Budget / hooks |
|---|---|---|---|
| 12.V1 | **Water** | `water.gdshader` + `water_mat.tres`: painted teal-green water, darker in the middle (UV.y across), flow-scrolling noise along UV.x, foam lines at the banks and around piers / stones, sun glint band, shallow ford film (lighter, stones visible), lily-pad-safe; `riverbed_mat.tres` for the trench walls (wet rock, roots) and bed | Opaque, no screen / depth reads; uniforms `flow_speed`, `foam_amount`, `shallow` (ford film); a `wade` ripple sprite for 12.V25 |
| 12.V2 | **Ground: river cut + banks + biome tint** | `ground.gdshader`: `discard` where the analytic river distance < half width (not inside ford circles); wet bank band 2.5 m (dark earth -> sand); biome tint weights from a mask texture (meadow bright, heath warm dry with purple / yellow blotches, Old Wood dark needles, glade = today) | Uniforms `river_segs` (vec4[16], a.xz b.xz), `river_count`, `river_half_width`, `moat` (vec4 cx, cz, r, half_w), `fords` (vec4[4] cx, cz, r, 0), `biome_mask` (sampler, 240 x 240 over the map), `biome_tints` (vec3[4]); `ground_material.tres` defaults = no river (missions unchanged) |
| 12.V3 | **Crown Bridges** (1 scene, used twice) | Wide pale-stone arched bridge, 8 m deck flush at y 0.0-0.03, low parapets with two cold ember braziers at each end, arches visible down into the trench; cracked, mossy, matches the crown ruins | `art/environment/bridges/lane_bridge.tscn`; <= 3 materials; no collider (navmesh does the work) |
| 12.V4 | **Road bridges + fords** | Timber deck on two stone piers, rope rails, a lantern post each end (`(1.0, 0.8, 0.4)` glow); ford dressing: stepping stones, marker poles with rags, foam rapids where the trench meets the ford film; Crown Steps: broken stone steps into the shallows | `road_bridge.tscn`, `ford_stones.tscn`, `crown_steps.tscn` |
| 12.V5 | **River mouths** | North: a waterfall pouring from the cliffs into the river (mist cards); south: a gorge with rapids leaving the map; cliffs regenerated with the two gaps | `build_env.gd`, `map_dressing.tscn`, `meshes/map_cliffs.res` |
| 12.V6 | **Biome scatter integration** | `BiomeMap` (biome weights at `(x, z)`, section 3.1) and the mask texture; `MapDressingArt` scatters each biome set, respects the river mask (bank / water placement), visibility ranges, Map detail Low | `map_dressing_art.gd`, `biomes/biome_map.gd`; reads the 6 set files below |
| 12.V7 | **Riverbank set** | Reeds, cattails, lily pads (flowers), river stones, driftwood; **willow tree** (drooping curtain crown, distinct at 40 m) | `biomes/riverbank/`, `meshes/tree_willow.res` (+ `_far`), collider footprint like other trees (r 0.45 s) |
| 12.V8 | **Hearth Meadow set** | Short tufts, clover, daisies, dandelions, hay bales, fruit bush | `biomes/meadow/` |
| 12.V9 | **Heath set** | Heather clumps (purple), gorse (yellow flowers), wind-bent tall grass, lichen stones | `biomes/heath/` |
| 12.V10 | **Old Wood set** | Dark ferns, blue-cap glow mushrooms (emissive 1.5-2.0), moss boulders, fallen trunk, roots, cobweb cards | `biomes/old_wood/` |
| 12.V11 | **Wildflower Glade set** | Tall grass patches, flower clusters in 4 colours, butterfly bush | `biomes/glade/` |
| 12.V12 | **Crown Isle ruins set** | Flat flagstone slabs, low column drums, ember moss (faint orange glow), cracked statue plinths, cold braziers | `biomes/ruins/` (existing `crown_ruin_dressing` stays) |
| 12.V13 | **Landmarks A** | Fallen Colossus (head + hand), Giant's Stump | `landmarks/colossus.tscn`, `giant_stump.tscn`; colliders sized as 3.2 |
| 12.V14 | **Landmarks B** | Old Aqueduct (2 arches + piers), Drowned Barge, Standing Stones | `landmarks/aqueduct.tscn`, `barge.tscn`, `standing_stones.tscn` |
| 12.V15 | **Game critters (models)** | Red deer (slim, antlered stag silhouette distinct from the Hollow Stag: brown coat, white rump, no glow) and rabbit (grey-brown, white tail): idle graze / sit, walk / hop, flee run, hit flinch, death (falls, fades after 4 s) | `art/units/neutral/critters/deer.tscn`, `rabbit.tscn`; hooks `play_idle()`, `play_move(speed: float)`, `play_flee()`, `play_hit()`, `play_death()`; budgets of section 9 |
| 12.V16 | **Cosmetic critters + CritterSystem** | Birds (flocks, take-off / land), butterflies, dragonflies, fireflies (blink), frogs (sit, jump), optional fish splash; the draw-only `CritterSystem` (section 3.3 rules, fog-aware, camera range) | `art/environment/critters/critter_system.gd` + meshes; MultiMesh per kind, vertex-shader flap / hop |
| 12.V17 | **Watchtower** | Dominant: a tall broken stone tower (~9 m) with a rebuilt timber crown; secondary: a banner pole + brazier; neutral = grey torn banner, owner = team colour banner and brazier glow | `art/buildings/capture/watchtower/watchtower.tscn`; `set_owner_color(c: Variant)` (null = neutral), `set_capture(color: Variant, ratio: float)`, `play_captured()`; tavern budget, 0 lights |
| 12.V18 | **Wayshrine** | Waist-high carved standing stone + a floating rune stone (y 1.6, slow spin); dormant = dark, awake = gold glow + light column, capturer colour after capture | `wayshrine/wayshrine.tscn`; `set_state(state: StringName)` (`&"asleep"`, `&"awake"`), `set_owner_color(c)`, `set_capture(color, ratio)`, `play_blessing(color)`; no collider |
| 12.V19 | **Essence well** | Round old well with a broken winch, violet essence mist, rim runes in the owner colour | `essence_well/essence_well.tscn`; `set_owner_color`, `set_capture`, `play_pulse()` (each income tick) |
| 12.V20 | **Bristleback** | Stocky boar, ridge of quills along the back, big tusks, muddy | `art/units/neutral/bristleback/`; soldier budget (art-units: <= 18 meshes, <= 10 draw instances, 0 lights), kit hooks (walk, attack, hit, death) |
| 12.V21 | **Mirefang** | Low, long river lizard, frilled jaw, wet green-bronze scales, amber eyes (glow point) | `art/units/neutral/mirefang/`; soldier budget |
| 12.V22 | **Gloomcap Elder + Sprout** | Walking mushroom folk: the Elder tall with a wide blue-grey cap, spore puffs, a root staff; sprouts knee-high | `art/units/neutral/gloomcap/`; `play_cast(&"spore_burst")` |
| 12.V23 | **Hollow Stag** | Huge pale stag, antlers of bare branches with small glowing leaves, a hollow chest with a faint green light (2 glow points) | `art/units/neutral/hollow_stag/`; hero budget (<= 26 meshes, <= 16 draw instances); `play_cast(&"antler_sweep")` |
| 12.V24 | **Camp sites** | Wallow (mud pit, bones, chewed logs), nest (reed nest mounds in the ford), mushroom ring (hollow), stag glade (antler cairn, moss altar) | `art/environment/camps/<kind>_site.tscn`, `set_cleared(bool)` (e.g. glow off, flattened reeds) |
| 12.V25 | **Map-fill VFX** | `capture_done` (ring burst in colour), `shrine_awaken` (gold column), `blessing` (small rune over each blessed unit, one MultiMesh <= 80), `well_pulse`, `camp_respawn` (dust + leaves), `camp_cleared`, `wade` (ripple rings, pooled <= 16), `spore_burst`, `antler_sweep`; forwards any unknown id to `art/vfx/mapfill_beast_vfx.gd` when that file exists (12.V31) | `art/vfx/mapfill_vfx.gd` (`class_name MapFillVfx`, group `"mapfill_vfx"`, `play(id, at, target)`), `art/vfx/mapfill_*` (not `mapfill_beast_*`) |
| 12.V27 | **Tusker** (both variants in one scene) | A: massive boar, iron-grey hide like plate, curved tusks, bristle ridge. B Old Scarback: x1.15, scarred, one broken tusk, a war-arrow still in its hide, darker bristles | `art/units/neutral/beasts/tusker/tusker.tscn`; hero budget (<= 26 meshes, <= 16 draw instances, 0 lights); `set_variant(v: int)`, kit hooks, `play_cast(&"gore_charge")` |
| 12.V28 | **Roc** | A Stormcrest: huge storm-blue bird of prey, crest of pale feathers, glides low (body offset 2.5 m, shadow blob on the ground). B Duskwing: near-black plumage with violet sheen, red eyes (glow) | `beasts/roc/roc.tscn`; same budget; `set_variant`, `play_cast(&"gale_swoop" / &"shrieking_dive" / &"updraft")` |
| 12.V29 | **Direwolf** | A Greymane: horse-sized grey wolf, shaggy mane. B Moonpelt: silver-white, faint pale-blue eye glow, leaner | `beasts/direwolf/direwolf.tscn`; same budget; `set_variant`, `play_cast(&"pounce")` |
| 12.V30 | **Grizzlemaw** | A: towering brown cave bear, moss on the shoulders, huge claws. B Elder: larger, white muzzle, grey-streaked, old bones and a rusted chain around the neck | `beasts/grizzlemaw/grizzlemaw.tscn`; same budget; `set_variant`, `play_cast(&"maul" / &"rending_roar")` |
| 12.V31 | **Beast VFX** | `gore_charge` (dust trail + impact), `gale_swoop` (wind ring), `shrieking_dive` (violet shriek ring), `updraft` (feather swirl), `pounce` (leap streak + root claw marks), `hamstring` (small red slash), `maul` (claw swipe), `rending_roar` (shock ring r 6), `beast_spawn` (a distant flock of birds rising over the lair) | Added to `MapFillVfx` as its own file set `art/vfx/mapfill_beast_*` + a `mapfill_beast_vfx.gd` that `mapfill_vfx.gd` loads if present |
| 12.V32 | **Lairs** | West Heath wallow (churned mud, tusk-marked stones), Colossus Crag nest (branches on the fallen head, eggshells), Greymane Hollow (bone pile, flattened ferns), Old Wood Den (cave mouth dug under a boulder beside the aqueduct pier) | `art/environment/lairs/<id>.tscn`, draw-only, `set_occupied(bool)` |
| 12.V26 | **Icons** (phase 2) | Watchtower, well, shrine (asleep / awake), blessing buff, wading debuff, 4 creatures, 3 camp tiers, 4 beasts (A and B), deer, rabbit | `art/icons/` (new files only) |
Biome set files (12.V7-12.V12) have **no class dependency**, so they can be made in parallel with 12.V6:
`art/environment/biomes/<id>/<id>_set.gd` (extends RefCounted) with `const BIOME_ID := &"<id>"`, `const GROUND_TINT := Color(...)`,
`const ENTRIES := [{"mesh": "res://...res", "per_100m2": 6.0, "scale": Vector2(0.8, 1.3), "cluster": 0.6, "shadow": false,
"range": 90.0, "place": &"land"}]` with `place` in `&"land"`, `&"bank"` (0-2.5 m from water), `&"water"` (on the surface),
`&"under_trees"`, `&"edge"`. Instance budget per set: riverbank 1 800, meadow 1 800, heath 1 600, Old Wood 900, glade 1 800,
ruins 300. Each set agent ships a preview screenshot `docs/art/screens/biome_<id>.png`.

## 11. Campaign
- Skirmish flags (exported, set before the scene enters the tree, like `trade_enabled`): `river_enabled`, `points_enabled`,
  `camps_enabled` (all **true** in the skirmish, **false** by default in missions); decor, biomes and critters follow the map
  (missions get the biome decor for free, without the river).
- The systems are placeable by missions: `RiverSystem.setup(...)` with the mission's own polylines, `CapturePoints.add_point(...)`,
  `CampManager.add_camp(...)`, `EpicBeasts.add_lair(...)`, `CritterHerds.setup(...)` (flag `beasts_enabled`, default false in
  missions; a lone Grizzlemaw makes a good optional mission boss).
- Proposed first use: **mission 3** (champions introduced): 2 Bristleback Wallows and one Wayshrine as optional objectives
  ("Take the shrine before the enemy does"); **mission 4** "The Salt Road" (`market-trade.md` 10): a river with one road
  bridge the caravans must hold. Missions 1-2 unchanged.

## 12. Balance
### 12.1 What map fill adds to a normal bot-vs-bot match (per side)
| Time | New events | Effect |
|---|---|---|
| 0:00-2:30 | Towers captured by squads / wizards; home wallow creep ~2:00 | Wizards reach L2 ~30 s earlier; harass needs the road bridges (+25 % walk) |
| 2:30-4:30 | Wells pay; shrines wake at 3:00 (both); own ford nest cleared | +24 essence / min each; one blessing each |
| 4:30-8:00 | Hollow Stags (3:30) and the crown camp (6:00) compete for the army; the far-corner tower changes hands; 6:00 shrine on one bank | Armies split or choose; creeping replaces weak attacks (rule 11a) |
| 8:00-15:00 | Camps respawn (level 2-3); shrines every 3 min alternate; fights at crossings | The side behind gets +25 % camp XP; defenders hold bridges |
| 6:30-18:00 | Epic beasts: Tusker 6:30, Direwolf 7:30, Roc 8:30, Grizzlemaw 10:00, then every 10-12 min (variant B on the 2nd spawn) | Big fights away from the lane; champions hunt in parties late; ~580 XP and ~350 essence per side if each side kills its own-bank beasts once or twice |
| Totals by ~18:00 | Camps ~780 XP to each wizard (x0.8 share), ~680 essence from camps + ~290 from one well; beasts ~470 XP (x0.8) and ~350 essence; critters negligible | **+~1.2 wizard levels, +~37 % essence** on both sides (balance-1 estimate 3 500 -> ~4 800); both sides gain alike, the underdog more |
### 12.2 Match length and anti-snowball
- **Longer**: road bridges are the only safe crossings early; the isle and the fords are guarded until ~4:00-8:00; lane
  bridges and fords are defender-friendly chokepoints (8 m / 6 m wide, fords -35 %); no building within 8 m of a crossing
  (no walls on bridges, but towers covering them are fine); the bot creeps instead of throwing weak attacks.
- **Comeback**: camps give PvE income that does not come from the enemy; underdog bonus; blessings are sustain; capturing
  on the enemy bank is slower; the well and home tower on your own bank are near your base.
- **Not a new snowball**: no point gives damage; wells are +24 / min (40 % of the base trickle); a tower gives sight only.
- Expected: even pairs **+2:00 to +4:00** median length (on top of steps 10-11). Champion snowball knobs stay in
  `champions.md` 12 / `skills-rework.md` 9.5.
### 12.3 Knobs (one at a time)
| Symptom | Knob |
|---|---|
| Games still < 14:00 median | Ford slow -35 % -> **-50 %**; nests first spawn 0:00 stays but T2 respawn 180 -> **120 s**; underdog x1.25 -> **x1.5** |
| Games > 22:00 or stalemates at a bridge | Crown Bridge width 8 -> **10 m**; ford slow -> **-20 %**; the "8 m from a crossing" build ban -> **12 m** |
| Camps ignored (bot or playtest) | Clear bonus x1.5; T3 respawn 240 -> **180 s** |
| Camps farmed too hard (essence at 18:00 > 4 800 or wizards L7 before 18:00) | kill_xp -20 %; T3 component 100 % -> **60 %**; camp level cap 3 -> **2** |
| Beasts too rewarding / too often killed | Beast respawn 600 / 720 -> **900 s**; beast kill_xp -25 %; drop table variant A without the 30-60 % extra row |
| Beasts never killed (bot or playtest) | `beast_ratio` normal 1.4 -> **1.2**; Grizzlemaw HP 2 600 -> **2 200**; hunting party threshold 1.2 -> **1.0** |
| Wells decide games | 0.4 -> **0.3** essence / s; pay from 2:30 -> **4:00** |
| Shrines irrelevant | Blessing 60 -> **90 s**; add `attack_cooldown_pct` -0.05 |
| Far-corner towers never contested | Sight 22 -> **26** |
| Side bias in mirror runs | Check 2.5 path lengths first; then the shrine coin-flip start |
### 12.4 Re-test plan (lead 12.L2, then 12.D3)
Harness: the 9.C11 / 10.L2 bot-vs-bot run (normal, cap 24:00) with a new `--no-mapfill` flag (river, points and camps off).
| Round | Pairs (both orders) | Runs | Pass |
|---|---|---|---|
| A | fire-shadow, nature-ice, shadow-nature | 2 with map fill + 2 `--no-mapfill` each = 12 | Median length with map fill >= control **+1:30**, and within **14:00-22:00**; no run over 24:00 without a winner more than once |
| B | same | - | Each side clears >= 4 camps per game; each point changes owner >= 1 time per game on average; each side gets >= 2 blessings by 15:00; each side kills >= 1 epic beast per game that reaches 12:00; no creature or beast stuck off its territory; 0 script errors |
| C | ice-ice, nature-nature mirrors | 2 each | Crystals and essence within **1.1x** at 10:00 (side bias) |
| Perf | perf test + river, 8 points, 20 creatures; windowed frame check of section 9 | 1 | `PERF OK`, stuck = 0 |

## 13. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 12.L1)
Rule for phase-1 agents (as in steps 9-10): never use another step-12 agent's new `class_name` as a static type; reach it
with `load()` guarded by `ResourceLoader.exists`, groups, `has_method()`, `get()`.
- **RiverSystem** (`scripts/world/river_system.gd`, `class_name RiverSystem extends Node3D`, group `"river"`, `static func
  instance(tree: SceneTree) -> RiverSystem`): `setup(polylines: Array[PackedVector2Array], half_width: float, moat: Vector4,
  crossings: Array[Dictionary])` (crossing: `{id, name, kind: &"bridge_road" / &"bridge_lane" / &"ford" / &"steps", center:
  Vector3, width: float, length: float, dir: Vector3}`), `WATER_Y := -0.35`, `FORD_SLOW := -0.35` (modifier `terrain:ford`,
  `move_speed_pct`), `is_water(pos: Vector3) -> bool` (deep, not walkable), `is_ford(pos) -> bool`, `is_bridge(pos) -> bool`,
  `distance_to_water(pos) -> float`, `bank_of(pos) -> int` (PLAYER / ENEMY / -1), `crossings() -> Array[Dictionary]`,
  `crossing(id: StringName) -> Dictionary`, `nearest_land(pos) -> Vector3`, `water_polygons() -> Array[PackedVector2Array]`,
  `mask_image() -> Image` (240 x 240, 0.5 m per pixel: R water, G ford, B bridge), `shader_params() -> Dictionary` (the 12.V2
  uniforms). Builds the carve obstacles, the trench and water meshes (materials from `art/environment/water/` when they exist,
  else plain colours) and the bridge / ford models (paths below, load-guarded). Amphibious units: group `"amphibious"`.
- **CapturePoint** (`scripts/world/capture_point.gd`, `class_name CapturePoint extends Node3D`, group `"capture_points"`, layer 2,
  NEUTRAL, invulnerable like `TradePost`): `point_id: StringName`, `kind: StringName` (`&"watchtower"`, `&"well"`, `&"shrine"`),
  `display_name`, `owner_team: int` (-1), `capture_team: int` (-1), `progress: float` (0-1), `capture_radius: float`,
  `capture_time: float`, `state: StringName` (`&"idle"`, `&"capturing"`, `&"neutralising"`, `&"contested"`, `&"asleep"`,
  `&"awake"`), `bank: int`, `is_contested() -> bool`, `time_until_awake() -> float` (shrines; INF when awake), `is_alive()`
  (true), `is_targetable()` (false), `is_invulnerable()` (true), `take_damage()` (no-op), `set_selected(bool)`,
  `footprint_rect() -> Rect2`, signals `owner_changed(point, new_team: int, old_team: int)`, `progress_changed(point, team: int,
  ratio: float)`, `awakened(point)`, `blessing_granted(point, team: int)`.
- **CapturePoints** (`scripts/world/capture_points.gd`, `class_name CapturePoints extends Node`, group `"capture_points_service"`,
  `static func instance(tree) -> CapturePoints`): `setup(points: Array)`, `add_point(kind, id, name, pos) -> Node3D`,
  `points(kind: StringName = &"") -> Array`, `held_by(team: int, kind: StringName = &"") -> Array`, `presence(team, point) -> int`,
  `blessing_time_left(team) -> float`, `BLESSING_TIME := 60.0`, `BLESSING_STATS := {"move_speed_pct": 0.12, "hp_regen": 1.5}`,
  `WELL_INCOME := 0.4`, `WELL_START := 150.0`, `SHRINE_FIRST := 180.0`, `SHRINE_INTERVAL := 180.0`, `next_waking() ->
  Dictionary` (`{point, time}`), signals `point_captured(point, team: int)`, `point_neutralised(point, old_team: int)`,
  `shrine_awakened(point)`, `blessing_started(team: int, seconds: float)`, `blessing_ended(team: int)`.
  `apply_blessing(unit)`: CapturePoints itself watches `SceneTree.node_added` while a blessing runs and applies it (deferred)
  to new Units of that team, so `unit.gd` does not change.
- **NeutralCamp** (`scripts/world/neutral_camp.gd`, `class_name NeutralCamp extends Node3D`, group `"neutral_camps"`): `camp_id`,
  `kind: StringName` (`&"bristleback"`, `&"mirefang"`, `&"gloomcap"`, `&"hollow_stag"`), `tier: int`, `display_name`,
  `camp_level: int`, `creatures() -> Array` (living), `is_cleared() -> bool`, `respawn_left() -> float`, `strength() -> float`,
  `reward_preview() -> Dictionary` (`{xp, essence, drop_text}`), `spawn()`, signals `cleared(camp, team: int, reward:
  Dictionary)`, `respawned(camp)`, `engaged(camp)`.
- **CampManager** (`scripts/world/camp_manager.gd`, `class_name CampManager extends Node`, group `"camp_manager"`, `static func
  instance(tree)`): `setup(spots: Array[Dictionary])` (`{id, name, kind, tier, pos, first_spawn}`), `add_camp(...) -> Node3D`,
  `camps() -> Array`, `camp_of(unit: Node) -> Node`, `CAMP_KINDS` (creatures per kind, tier, respawn, bonus, drops),
  `underdog_team() -> int` (-1 when levels are equal), signal `camp_cleared(camp, team: int, reward: Dictionary)`.
- **Creatures** (gameplay): the 5 `.tres` of 5.1 (`faction &"neutral"`, `neutral_leash = true`, `kill_xp`, `sight_radius`,
  `model_scene`); **CreatureAbilities** (`scripts/units/creature_abilities.gd`, `class_name CreatureAbilities extends Node`, a child
  `"CreatureAbilities"` the CampManager adds): `setup(unit: Unit, ability_ids: Array[StringName])`, ids `&"spore_burst"`,
  `&"antler_sweep"`, and for beasts `&"gore_charge"`, `&"bristle_hide"`, `&"gale_swoop"`, `&"shrieking_dive"`, `&"updraft"`,
  `&"pounce"`, `&"hamstring"`, `&"maul"`, `&"rending_roar"`, `&"enrage"`; `cast(id, target) -> String` (the BeastBrain calls it),
  `ready(id) -> bool`; calls the model's `play_cast(id)` and `MapFillVfx.play(id, ...)`.
- **Beasts** (gameplay): 8 `.tres` (one per variant): `data/units/ironhide_tusker.tres`, `old_scarback.tres`, `stormcrest_roc.tres`,
  `duskwing_roc.tres`, `greymane_direwolf.tres`, `moonpelt_direwolf.tres`, `grizzlemaw.tres`, `elder_grizzlemaw.tres` (numbers of 5.5,
  `neutral_leash = false`, `aggro_range` 0, `model_scene` = the kind's scene; the variant index goes to `set_variant`).
- **EpicBeasts** (`scripts/world/epic_beasts.gd`, `class_name EpicBeasts extends Node`, group `"epic_beasts"`, `static func
  instance(tree)`): `setup(lairs: Array[Dictionary])` (`{id, name, kind, center, radius, patrol: PackedVector3Array, first_spawn,
  respawn}`), `add_lair(...)`, `beasts() -> Array` (living), `lair_of(beast) -> Dictionary`, `spawn_count(lair_id) -> int`,
  `variant_of(lair_id) -> int`, `respawn_left(lair_id) -> float`, `strength_of(beast) -> float`, `DROP_TABLES` (ids `&"tusker"`,
  `&"roc"`, `&"direwolf"`, `&"grizzlemaw"`: rows `{items: Array[StringName], chance: float, variant: int}` + `trophy: [A id, B id]`),
  `REWARDS` (per kind: `{}` today), `grant(team: int, reward: Dictionary, by: Node)` (same shape as `CritterHerds.grant`), signals
  `beast_spawned(beast, lair_id: StringName, variant: int)`, `beast_slain(beast, team: int, drops: Array)`. Creates one `BeastBrain`
  child per beast (load-guarded).
- **BeastBrain** (`scripts/ai/beast_brain.gd`, `class_name BeastBrain extends Node`, group `"beast_brains"`): `setup(beast: Unit,
  lair: Dictionary)`, `state: StringName` (`&"patrol"`, `&"fight"`, `&"return"`, `&"escape"`), `target: Node3D`, thinks every 0.5 s
  (staggered): patrol, target combatants only (soldiers, wizards, champions, trackers) within aggro inside the leash, answer any
  attacker inside the leash, reset, abilities through `CreatureAbilities.cast`, Roc Updraft escape to its nest.
- **Towers / keeps** (`scripts/buildings/tower.gd` targeting): never pick a target in group `"beasts"`.
- **BuildGrid**: messages `MSG_WATER := "Can't build on water"`, `MSG_CROSSING := "Too close to a crossing"`, `MSG_CAMP := "Too close
  to a monster camp"`, checked after "Blocked by an enemy unit" (reads the RiverSystem and CampManager through groups).
- **BountyBoard**: Guard accepts an own-held `CapturePoint`; Explore within 7 m of a not-own-held point = Claim (`Bounty.is_claim()
  -> bool`, pays on `owner_changed` to the flag's team).
- **Skirmish** (`scripts/world/skirmish.gd`): `@export var river_enabled := true`, `points_enabled := true`, `camps_enabled := true`,
  `beasts_enabled := true` (also gates the game critters);
  constants `RIVER_POLYLINE_N`, `RIVER_HALF_WIDTH := 2.5`, `MOAT := Vector4(0, 0, 12.75, 1.75)`, `CROSSINGS`, `POINT_SPOTS`,
  `CAMP_SPOTS`, `LAIR_SPOTS`, `DEER_HERDS`, `RABBIT_HOMES`, `LANDMARK_SPOTS`, `OLD_WOOD_CLUSTERS`, `WILLOW_SEED := 17`; vars `river`,
  `capture_points`, `camp_manager`, `epic_beasts`, `critter_herds`;
  `bank_of(pos) -> int`; the moved `CACHE_SPOTS` / crown drop; end-screen line.
- **EnvProps**: `add_tree_kind(kind: String, pos: Vector3, s: float)` (`"tree_willow"`), `set_river(mat: ShaderMaterial, params:
  Dictionary) -> bool` (no-op when the shader lacks the uniforms).
- **Models / VFX paths**: `res://art/environment/water/water_mat.tres`, `riverbed_mat.tres`; `res://art/environment/bridges/lane_bridge.tscn`,
  `road_bridge.tscn`, `ford_stones.tscn`, `crown_steps.tscn`; `res://art/buildings/capture/watchtower/watchtower.tscn`,
  `wayshrine/wayshrine.tscn`, `essence_well/essence_well.tscn`; `res://art/units/neutral/<id>/<id>.tscn` (bristleback, mirefang,
  gloomcap (Elder and Sprout: `gloomcap_elder.tscn`, `gloomcap_sprout.tscn`), hollow_stag); `res://art/environment/camps/<kind>_site.tscn`;
  `res://art/environment/landmarks/<id>.tscn`; `res://art/environment/critters/critter_system.gd` (`class_name CritterSystem extends
  Node3D`, `setup(level: Node)`, `set_enabled(bool)`; the lead adds it next to the map dressing); `res://art/vfx/mapfill_vfx.gd`.
- **Settings**: `map_detail: StringName` (`&"high"` / `&"low"`) in the existing settings store (ui-coder), read by MapDressingArt,
  CritterSystem and the water material.
- **GameCritter** (`scripts/world/game_critter.gd`, `class_name GameCritter extends Node3D`, group `"game_critters"`, NOT in
  `"units"`): `kind: StringName` (`&"deer"`, `&"rabbit"`), `team` (NEUTRAL), `max_hp`, `hp`, `reward: Dictionary`
  (`{&"essence": 5}` / `{&"essence": 1}`; step 15 may add `&"food"`), `is_alive()`, `take_damage(amount: float, attacker: Node3D)`,
  `target_radius() -> float` (0.5 / 0.25), `is_game_critter() -> bool` (true), `is_fleeing() -> bool`, signals `hunted(critter,
  team: int, by: Node)`, `fled(critter)`. Click shape: `Area3D` on layer 2, `collision_mask` 0. On damage it applies the
  hidden-attacker rule itself: for each team that sees the critter's cell but not the attacker, a `SightMarker` (r 2, 1 s) at
  the attacker. Its `visible` follows the local team's fog like an enemy unit (CritterHerds reads `FogOfWar` state at 5 Hz; `fog_of_war.gd` does not change).
- **CritterHerds** (`scripts/world/critter_herds.gd`, `class_name CritterHerds extends Node`, group `"critter_herds"`, `static func
  instance(tree)`): `setup(herds: Array[Dictionary], rabbit_homes: Array[Vector3])`, `critters(kind := &"") -> Array`,
  `REWARDS := {&"deer": {&"essence": 5}, &"rabbit": {&"essence": 1}}`, `VENISON_HEAL := 40.0`, `VENISON_AREA_HEAL := 20.0`,
  `grant(team: int, reward: Dictionary, by: Node)` (pays every key it knows: today `essence` through `EssenceBank`; unknown keys are
  kept in `granted_totals` for step 15), `hunted_count(team) -> int`, signal `critter_hunted(critter, team: int, reward: Dictionary)`.
- **SelectionManager**: the selection ray also hits `Area3D`s on layer 2 (game critters); right-click on a visible critter with
  combat units selected = `command_attack`; workers / caravans ignore it.
- **Ownership**: `scripts/world/game_critter.gd`, `critter_herds.gd`, `epic_beasts.gd` = systems; `scripts/ai/beast_brain.gd` = ai;
  `data/units/<beasts>.tres` = gameplay; `art/units/neutral/critters/`, `art/units/neutral/beasts/`, `art/environment/lairs/`,
  `art/vfx/mapfill_beast_*` = tech-artist;
  `scripts/world/river_system.gd`, `capture_point.gd`, `capture_points.gd`, `neutral_camp.gd`, `camp_manager.gd` =
  systems; `scripts/units/creature_abilities.gd`, `data/units/<creatures>.tres` = gameplay; `scripts/ai/ai_mapfill.gd` = ai;
  `art/environment/water|bridges|biomes|landmarks|critters|camps/`, `art/buildings/capture/`, `art/units/neutral/<creatures>/`,
  `art/vfx/mapfill_*` = tech-artists. No `Events` change is needed.

## 14. What changes in other specs
- `skirmish-1v1.md`: the river, crossings, isle, points, camps, landmarks, moved caches and crown drop, flags, end-screen line.
- `items.md`: cache positions `(-6, 27)` / `(6, -27)`; camp drops (5.3); crown drop spots. `levels.md`: 5 victim rows (5.1).
- `fog-of-war.md`: points explored at 0:00, tower sight 22, critters never reveal, game critters hidden like enemy units and
  covered by the hidden-attacker rule. `ai.md`: rules 11-13 (11d game critters), scout loop, knobs, creature strength 0.
  `champions.md`: Guard on points, Claim, R8 additions (incl. the beast hunting party), R9 idle hunt, B8-B11. `levels.md`: 8 beast
  victim rows. `market-trade.md`: nothing moves; Den / Lodge "nearer" by path; waystones skip bridges. `buildings.md`: the
  three new placement messages; towers and keeps ignore beasts. `ui-hud.md`: objectives
  strip, Map detail. `CLAUDE.md` (lead): section 13 contracts, owner rows.

## 15. Task list (step 12; build after steps 10 / 11 integrate)
**Phase 0:** 12.L1 lead, 12.D2 ui-designer. **Phase 1 (in parallel, no shared files):** 12.C1-12.C5, 12.C10, 12.C11, 12.A3, 12.V1-12.V25,
12.V27-12.V32 (up to the agent cap; the art ones are independent). **Phase 1b (need 12.D2):** 12.C6, 12.C7. **Phase 2:** 12.C8, 12.C9, 12.A1, 12.A2,
12.V26, then 12.L2, then 12.D3 after the playtest. Phase-1 tests stub the other parts in their own `tests/test_12_<id>.gd`.
**Step-10 / 11 files touched** (schedule after): `skirmish.gd`, `env_props.gd` (10.C1, 10.L2 glue); `build_grid.gd` (10.C2);
`thieves_guild.gd` (10.C4), `hunters_guild.gd` (10.C5); `commander.gd`, `ai_profile.gd`, `data/ai/*.tres`, `ai_champions.gd`
(10.A3); `champion_brain.gd`, `champion_sense.gd` (10.A3, **11.A1**); `minimap.gd`, `selection_manager.gd` (10.C7); `hud.gd`,
`menus/game_settings.gd` (10.C8); `selection_panel.gd` (10.C7, **11.C4**); `ground.gdshader`, `ground_material.tres` (10.V10);
`tower.gd` (last changed in step 6; check no step-10 / 11 task is on it).
| Id | Agent | Task | Files |
|---|---|---|---|
| 12.L1 | lead | Freeze section 13 in `CLAUDE.md` (a "Map fill" bullet), owner rows, step-12 ids in `waves.md`, `step12-agent-rules.md` | `CLAUDE.md`, `docs/plan/` |
| 12.D2 | ui-designer | Layouts at 1600 x 900 for everything in section 8 | `docs/design/ui-mapfill.md` |
| 12.C1 | systems-coder-high [H] | RiverSystem (carve, masks, trench / water meshes, ford slow, push-out, bank_of), the map: river constants, corridors (no tree / rock within 1.2 m of water, after the rng draws), crossings, willows, Old Wood clusters (seed 13: `(-30, -56)` r 4 x 7 trees, `(-57, -32)` r 3.5 x 6, mirrored), landmark colliders, moved caches and crown drop, waystones skip bridges, points / camps spots, deer graze spots and rabbit homes (3.4), beast lairs (5.5), load-guarded creation of CapturePoints / CampManager / CritterHerds / EpicBeasts, fog reveals, the 4 flags, EnvProps willow + river params | `scripts/world/river_system.gd`, `skirmish.gd`, `env_props.gd` |
| 12.C2 | systems-coder | CapturePoint + CapturePoints: presence, capture / neutralise / contest / decay, far-bank x1.25, tower sight, well income + mana, shrine schedule and blessing, messages | `scripts/world/capture_point.gd`, `capture_points.gd` |
| 12.C3 | systems-coder | NeutralCamp + CampManager: spawn schedule, respawn and blocking, reset heal, camp levels, rewards, drops, underdog, strength, messages | `scripts/world/neutral_camp.gd`, `camp_manager.gd` |
| 12.C4 | gameplay-coder-high [H] | 5 creature `.tres` + 8 beast `.tres` (5.5), CreatureAbilities (Spore Burst, Antler Sweep and the 10 beast abilities incl. dashes / leaps on the navmesh, Bristle Hide reflect, Hamstring modifier, enrage), victim XP | `data/units/bristleback.tres`, `mirefang.tres`, `gloomcap_elder.tres`, `gloomcap_sprout.tres`, `hollow_stag.tres`, the 8 beast `.tres`, `scripts/units/creature_abilities.gd` |
| 12.C5 | systems-coder | BuildGrid water / crossing / camp rules; BountyBoard Guard on points + Claim; Den / Lodge nearer by path; towers and keeps never target beasts | `scripts/buildings/build_grid.gd`, `tower.gd`, `scripts/world/bounty_board.gd`, `thieves_guild.gd`, `hunters_guild.gd` |
| 12.C11 | systems-coder | EpicBeasts: lairs, schedule, variant alternation, respawn and blocking, drop tables with trophy hooks, `reward` dictionary + `grant`, underdog XP, announcements, BeastBrain creation (load-guarded) | `scripts/world/epic_beasts.gd` |
| 12.A3 | ai-coder | BeastBrain: patrol, combatant-only targets, leash and reset, ability casting, Roc escape to its nest | `scripts/ai/beast_brain.gd` |
| 12.C10 | systems-coder | GameCritter + CritterHerds (3.4): HP, flee rule with the both-teams visibility check, navmesh moves, rewards through `grant(team, reward, by)`, venison heal, respawn in unseen cells, local-fog visibility, hidden-attacker markers, hunted count | `scripts/world/game_critter.gd`, `critter_herds.gd` |
| 12.C6 | ui-coder | Minimap layers (water, crossings, points, camps, beast lairs and visible beasts, tower sight rings), click on points emits `neutral_building_clicked`, capture rings in the world, the selection ray hits game-critter areas (card on left-click, `command_attack` on right-click / A-click, attack cursor) | `scripts/ui/minimap.gd`, `selection_manager.gd`, `scripts/vfx/capture_rings.gd` (new) |
| 12.C7 | ui-coder | Objectives strip, point panel, camp line on creature inspect, beast boss bar + inspect card + spawn roar, game-critter card and floating `+5` / `+40` / `+1`, blessing / wading icons, messages, hint, Map detail setting, help text, end-screen line (with `Game hunted`), sounds | `scripts/ui/mapfill_bar.gd` (new), `point_panel.gd` (new), `hud.gd`, `selection_panel.gd`, `scripts/ui/menus/game_settings.gd`, `assets/audio/mapfill_*` |
| 12.V1-12.V25, 12.V27-12.V32 | tech-artist (one each) | Section 10 rows | Folders of section 10 |
| 12.C8 | systems-coder | Plug the models (water materials, bridges, fords, steps, landmarks, watchtower / shrine / well, camp sites, lairs, deer / rabbit) and their hooks and VFX calls | `river_system.gd`, `skirmish.gd`, `capture_point.gd`, `neutral_camp.gd`, `game_critter.gd`, `epic_beasts.gd` |
| 12.C9 | gameplay-coder | Plug the creature and beast models (`model_scene`, `set_variant`), `play_cast` hooks | `data/units/<creatures and beasts>.tres`, `creature_abilities.gd` |
| 12.A1 | ai-coder | Bot rules 11-13 (incl. 11d: critters ignored, hard squads may shoot a nearby deer; 11e: beasts), knobs, scout loop, creature and beast strength 0, B8-B11, concede unchanged | `scripts/ai/ai_mapfill.gd` (new), `commander.gd`, `ai_profile.gd`, `data/ai/*.tres`, `ai_champions.gd` |
| 12.A2 | ai-coder | ChampionBrain: Wayfinder towers, Oathwall points, Coin-Cutter T1 camps, Claim pursuit (stand in the circle), camp danger, beast hunting party, R9 idle hunt (Wayfinder, Coin-Cutter) | `scripts/ai/champion_brain.gd`, `champion_sense.gd` |
| 12.V26 | tech-artist | Icons | `art/icons/` (new files only) |
| 12.L2 | lead | Glue (MapFillVfx and CritterSystem in the skirmish scene, hud wiring from handoffs), `--no-mapfill`, perf test additions, runs of 12.4, CI, playtest copy | `tests/`, `scenes/`, `docs/plan/` |
| 12.D3 | game-designer | Balance from the 12.L2 logs and the playtest (knobs of 12.3) | `docs/design/map-fill.md` |

## Done when
- [ ] 12.L1: section 13 is in `CLAUDE.md`; owner rows for every new folder and data file; step-12 ids in `waves.md`; agent rules file.
- [ ] 12.D2: `ui-mapfill.md` gives positions / sizes / looks at 1600 x 900 for every element of section 8, consistent with `ui-style.md`, `ui-trade.md` and `ui-champions.md`.
- [ ] 12.C1: the navmesh has no polygon in deep water; `is_water` true at `(-6.5, -25.5)` and `(-12.75, 0)`, `is_ford` at `(-8.5, -34)` and `(-9.02, -9.02)`, `is_bridge` at `(-12, -48.7)` and `(-9.02, 9.02)`, mirrors too; `bank_of((-30, -24))` = PLAYER, `((30, 24))` = ENEMY, `((0, 0))` = -1; a unit walking from `(-20, 0)` to `(20, 0)` with the wardens removed never enters deep water and crosses the isle; a unit in a ford has `move_speed` x0.65 and loses it 0.3 m out; a unit teleported into deep water is back on land within 0.3 s; every step-10 constant unchanged; caches at `(-6, 27)` / `(6, -27)`, crown drops at `(2, 2)` / `(-2, -2)`; the mirror and path-length checks of 2.5 pass (< 1 %); `river_enabled = false` gives today's map (same rng forest); smoke test `victory=true`; `PERF OK`.
- [ ] 12.C2: capture times 12 / 15 / 8 s with 1 unit, x1.25 on the enemy bank, rate cap 1.75, the wizard counts 2, workers / caravans / creatures do not count; contest freezes; abandoned progress decays 10 %/s; enemy-owned points are neutralised then captured; the tower's sight 22 follows the owner; a well pays 2 essence every 5 s from 2:30 and +3 mana / s to the owner's wizard within 8 m; shrines wake both at 3:00, then one every 180 s alternating from the slower side's bank; the blessing gives +12 % speed and +1.5 HP / s for 60 s to soldiers, wizard and champions (and units spawned meanwhile), not workers, and refreshes without stacking; messages throttled.
- [ ] 12.C3: 8 camps at section 5.2 with first spawns 0:00 / 0:00 / 2:30 / 3:30; respawn 120 / 180 / 240 s, blocked while a PLAYER / ENEMY unit is within 16 m; camp level +1 per respawn (max 3) with the stat and reward increases; reset heal; clear bonus 10 / 25 / 50 to the last killer's team; drop tables; underdog x1.25 XP / x1.5 bonus only when the killer's wizard is lower level; creatures in group `"amphibious"` for Mirefangs.
- [ ] 12.C4: the five `.tres` with the numbers of 5.1; Spore Burst every 10 s (20 damage r 3 + `marked` 4 s), Antler Sweep every 8 s with 2+ enemies within 3 m (35 damage); creatures stay in their leash; kill XP 25 / 30 / 50 / 12 / 160. The 8 beast `.tres` carry the numbers of 5.5 and each beast ability works once cast (Gore Charge dash 6-14 m with daze, Bristle Hide 4 per melee hit, Gale Swoop / Shrieking Dive leap 12 m with daze / mark, Updraft once at 40 %, Pounce with root, Hamstring -25 % speed 3 s, Maul with mark, Rending Roar daze (+ taunt for the Elder), enrage below 30 %); dashes and leaps end on the navmesh, never in water.
- [ ] 12.C10: 6 deer and 12 rabbits at 3.4; not in `"units"`; a soldier idling next to one never attacks it, an attack-move passes it, a tower ignores it; `command_attack` kills it; the deer pays 5 essence + 40 HP to the killer and 20 HP to own units within 6 m, a rabbit 1 essence, through `grant(team, reward, by)` (an extra `food` key is stored, not paid); no XP; flees when damaged or when a unit visible to every team that sees it comes within 4 / 3 m, never from a hidden unit; hidden and unclickable for a team that does not see its cell; respawns (120 s per herd / 90 s) only in unseen cells; a hidden hunter is revealed 2 m for 1 s.
- [ ] 12.C11: 4 lairs per bank at 5.5 with first spawns 6:30 / 7:30 / 8:30 / 10:00 and respawn 600 / 720 s (blocked within 25 m); spawns alternate A, B, A... per lair; messages to both teams; drop tables per variant, trophy ids dropped only if the item exists; `grant` pays known keys and keeps unknown ones; underdog x1.25 XP; `beasts_enabled = false` spawns nothing.
- [ ] 12.A3: a beast patrols its 4 points, attacks soldiers / wizards / champions / trackers inside its leash, ignores workers, caravans and buildings, returns and heals after 8 s without a target or beyond the leash, casts its abilities on their triggers, and the Roc escapes to its nest once; 8 brains cost < 0.03 ms / frame.
- [ ] 12.C5: placing on water, within 8 m of a crossing or of a camp spot is refused with the three messages (after "Blocked by an enemy unit"); Guard on an own-held point pays champions within 14 m and refunds on an owner change; an Explore within 7 m of a not-own-held point pays on capture (Claim); Den / Lodge choice uses path length; a tower or keep with a beast and nothing else in range does not fire; step-9 / 10 tests still pass.
- [ ] 12.C6 / 12.C7: every element of section 8 as laid out in `ui-mapfill.md`; clicking a point opens its panel; right-click on a visible deer with soldiers selected attacks it; beasts show the boss bar and lairs on the minimap; Map detail Low halves decor and removes the cosmetic critters (never deer / rabbits) at the next match; nothing in `scripts/ui/` calls a `_private` function.
- [ ] 12.V1-12.V25, 12.V27-12.V32: each asset follows section 10 and `art-keep.md` 0 (silhouette test for the objects, palette, glow points, contact decal, painted shader), budgets and hooks as listed; a contact sheet or preview screenshot per task in `docs/art/screens/`; headless instantiation without errors; 12.V6 total decor <= 12 000 instances with the river on; 12.V16 critters react only to visible units and animate only within 50 m of the camera; 12.V27-12.V30 show both variants side by side in one contact sheet each (`set_variant(0 / 1)`), readable apart at 40 m.
- [ ] 12.C8 / 12.C9: models replace the placeholders; hooks called on the right events (`set_owner_color`, `set_capture`, `set_state`, `play_pulse`, `set_cleared`, `play_cast`); smoke test `victory=true`.
- [ ] 12.A1: normal bot: clears its home wallow by ~2:30 and its ford nest by ~4:30 (rule 11a, logged `CREEP`), sends a 2-soldier squad to its well and home tower, is at its own shrine at 3:00, creeps instead of attacking when `own_strength < attack_ratio x seen`, defends points near its buildings, uses the new scout loop (never through the isle while the wardens live), B8-B11 flags; kills its own-bank Tusker with the army when `own_strength >= 1.4 x` its strength (11e); never targets deer or rabbits (hard: a returning squad may shoot one deer within 10 m); hard takes the contested hollow and reroutes an attack around a towered bridge; `PERF OK`.
- [ ] 12.A2: a Wayfinder with a known map captures a neutral own-bank tower on its loop; an Oathwall patrols own points near buildings; a level-4 Coin-Cutter with enough power clears a T1 camp and a weaker one does not; champions on a Claim stand in the circle until it is captured; three free level-4 champions near a visible Tusker hunt it together and a single one never does; an idle Wayfinder shoots a visible deer within 15 m at most once per 120 s.
- [ ] 12.L2: the runs of 12.4 meet the pass lines; CI green; the windowed frame check of section 9; playtest copy moved.
- [ ] 12.D3: balance notes and knob changes written here (section 12) from the 12.L2 logs and the user's playtest.

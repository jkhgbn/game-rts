# 2v2 skirmish: the map "Fourfold Hollow" and its rules

Task 20.D1, written 2026-09-26 by the game-designer. Source of truth for the step-20 map, seat model, rules and the systems /
dressing tasks (section 7). User request (`waves.md` step 20): a 2v2 where the player controls **only their own kingdom**,
the ally is a bot on the same team, two enemy bots; "use a maximum of what we already have, but 2x": a map about twice
Crown Hollow built from its existing pieces, no new art beyond dressing. It also serves Story Episode 2 (the 2v1 -> 2v2
turn, `story-episode-1.md` 10). Parallel specs: **`ui-2v2.md`** (20.D2: lobby, 4-player HUD, ally pings) and
**`ai-2v2.md`** (20.D3: ally bot, 2v2 targeting, already written: its section 3 / 13 hooks are answered here, section 5).
Builds on `skirmish-1v1.md`, `map-fill.md`, `market-trade.md`, `grand-market.md`, `terrain.md`, `walls.md`,
`building-levels.md`, `rush-balance.md` and the real code (`scripts/world/skirmish.gd`, `main.gd`, `river_system.gd`,
`fog_of_war.gd`, `art/environment/*`). Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `+x` east,
`+z` south (down on the minimap). Everything named here is original.

## 0. User decisions (the answers go here; the recommendations below are used until then)
| # | Question (section 10) | Assumed now (recommended) |
|---|---|---|
| Q1 | Map layout | **Fourfold Hollow**: 4 corner bases, allies on the same bank, one river, one central Crown Isle |
| Q2 | You are knocked out, your ally still fights | **You watch with your team's vision and still share the win** |
| Q3 | Army size vs smoothness | **Same caps as the 1v1** (40, Nature 50) behind a perf gate, automatic -15 % fallback |
| Q4 | Gifts between allies | **None in v1** (separate resources) |
| - | Ally bot personality (user, `ai-2v2.md` Q1) | **Random each match** (Supportive / Aggressive / Economic; still choosable in the lobby) |
| - | Enemy bots' targeting (user, `ai-2v2.md` Q2) | **Fair target score**: no preference for the human, never a double rush on one player |
| - | A bot concedes while its teammate stands (user, `ai-2v2.md` Q3) | **Its kingdom crumbles**, the teammate plays on (rule 4.4) |

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Shape | **168 x 168 m** (half 84; 1.96x Crown Hollow's area), **4-way mirrored**: one canonical quadrant (the player's, south-west) and its 3 mirror images | Every seat gets the same map, so fairness is exact (the 1v1's point-mirror test, now with 4 twins) and any seat can be the human |
| Bases | The **1v1 base district is reused unchanged**, slid 32.5 m back along the diagonal (`T = (-23, 23)` from the Fire side): keeps at `(+-66, +-66)`, 18 m from both edges (1v1: 17) | The tuned base layout, bot build slots, walls and rush slots keep working through one transform per seat (`seat_frame`) |
| Teams | **Allies share a bank**: side A = the west bank (south-west = the player, north-west = the ally), side B = the east bank | Allies help each other by land; the river separates the teams as in the 1v1 |
| River | The Hollowmere runs **straight north-south along x = 0** through the central moat (the 4-way symmetry allows no bend); 10 crossings | Reuses `RiverSystem`, its moat, crossings, divider and `bank_of` (2 polylines, as today) |
| Centre | **One** Crown Isle, one Ember Crown (sealed until 6:00), **6** Ruin Wardens, 4 Crown Bridges (one per base) and 2 Crown Steps (one per side) | One prize for four wizards: the natural focal point; the isle and its crossings reuse the 1v1 coordinates |
| Distances | Keep -> facing enemy **~142 m** by path (1v1 lane 122), -> diagonal enemy **~187 m** (over the isle), -> ally **~142 m** (by road, own bank) | Each seat has one clear lane opponent; rush timings move by ~5 s only |
| Content | Per seat = the 1v1's per side (nodes, posts, tavern, peddler, camps, points, lairs...); services that sit **between allies** (Den, Lodge, Gloomcap Hollow, Wayshrine, a cache) are **one per side** on the ally midline | Doubles the map's content without cramming (section 2.8 counts) |
| Seats | **`team` becomes the seat** (owner): enum appended `ALLY = 3`, `ENEMY_2 = 4`; sides live in a tiny static table `Teams`; `Unit.are_allies(a, b)` (the `ui-2v2.md` name). One encoding for 20.D1 / D2 / D3 (4.1) | Per-player economies, banks, guilds, markets, selection and orders already work per `team`; only hostility, vision and a few loops change (section 6) |
| Vision | **Shared per side** (fog per side) | Free allied vision, the fog cost stays 2 passes |
| Resources | **Separate per seat** (crystals, essence, gold, pop); no gifts in v1 (Q4) | Clear ownership; the bots are balanced for it |
| Defeat | A seat is **out** when it has no living building (the 1v1 rule), concedes, or has no keep and no barracks for 120 s; a **side loses when all its seats are out**. An out seat **crumbles** (buildings collapse, units leave) | Consistent with the 1v1 and `ai-2v2.md` 7.3; no side can hide behind a lone house |
| Pop cap | **40 per seat** (Nature 50; step-18 house levels as in the 1v1), gate = the 2v2 perf test (300 units <= 15 ms); fallback `pop_cap_scale 0.85` | "The same but 2x" keeps the 1v1 army feel; the gate protects 60 fps |

## 2. The map "Fourfold Hollow"
### 2.1 How it is built from Crown Hollow
- **Four mirrors.** Every object of the canonical quadrant **A1** (the player's, `x < 0`, `z > 0`) at `(x, z)` also exists at
  `(x, -z)` (**A2**, the ally, north-west), `(-x, -z)` (**B1**, the 1v1 enemy seat, north-east) and `(-x, z)` (**B2**, the second
  enemy, south-east). Objects **on** the ally midline `z = 0` exist twice (`(x, 0)`, `(-x, 0)`: one per side); objects on
  `x = 0` are crossings only (the river). Every fairness test of `map-fill.md` 2.5 runs with 4 twins.
- **The base district is the 1v1 one.** The 1v1 Fire base (keep, home nodes, houses, barracks / tower / market / rush / wall
  slots, the natural expansion and the sealed Glade Vein with its Stag Glade) is placed **unchanged relative to its keep**, moved
  by `T = (-23, 23)`. T is parallel to the lane, so every lane offset stays as in the 1v1 (the natural node is 7.07 m off the
  lane in both). The **seat frames** (`Transform3D`, input = a Shadow-side 1v1 point, as `ai-2v2.md` 3.1 asks):
| Seat (`team`) | Quadrant | Frame: world = basis * p + origin | Keep | Start (hub) |
|---|---|---|---|---|
| `PLAYER` (0) | A1 south-west | basis `diag(-1, 1, -1)` (half turn), origin `(-23, 0, 23)` | `(-66, 66)` | `(-59, 59)` |
| `ALLY` (3) | A2 north-west | basis `diag(-1, 1, 1)` (mirror in x), origin `(-23, 0, -23)` | `(-66, -66)` | `(-59, -59)` |
| `ENEMY` (1) | B1 north-east | identity, origin `(23, 0, -23)` | `(66, -66)` | `(59, -59)` |
| `ENEMY_2` (4) | B2 south-east | basis `diag(1, 1, -1)` (mirror in z), origin `(23, 0, 23)` | `(66, 66)` | `(59, 59)` |
  (1v1: `ENEMY` identity, `PLAYER` half turn, origin 0.) A2 and B2 are **reflections** (determinant -1): code maps points and
  directions with `frame * p` / `frame.basis * d`; it must never read Euler angles or a Quaternion from a frame basis.
- **Everything else is placed by role** (tables 2.4-2.6): the 1v1's far north-west corner (rich node, Den, Lodge, hollow,
  lairs) does not fit behind a corner base, so its pieces go where their role is kept: the contested rich node by the
  facing enemy's road bridge, the guild houses and the hollow on the ally midline, the lairs on the heath and at the river mouths.
- **Why not the alternatives.** Two Crown Hollows side by side (240 x 120): a "wing" and a "centre" base per team, the centre
  one faces two enemies, and the seam puts each centre base 25-35 m from an enemy rich corner. A rotated (4-fold) layout:
  allies would be separated by a river exactly like enemies. Stacking two 1v1 west banks: the slanted river does not tile.

### 2.2 Size, axes and the sketch
Map `168 x 168` (`x, z` in `-84..84`); BuildGrid cells `-41..40` (the outer ring stays unbuildable); camera bounds `+-82`.
```
 z -84 +-------------------------------------+ | +-------------------------------------+
       | A2 ALLY            Copperhythe   Saltgate Br. (0,-72)   Saltgate        B1 ENEMY |
       |  keep (-66,-66)   ====road=====[bridge]=====road====     keep (66,-66)          |
       |  Owlgate post        rich     Millwatch |~|  Millwatch   rich     Lantern Wharf  |
       |   (-76,-24)          Reed Ford Nest ->  (0,-40)  <- ford                (76,-24) |
       |  stag  glade   natural   well       tavern|~|tavern      well  natural   glade   |
 z  0  | Den | Lodge  hollow  cache  shrine  steps (CROWN ISLE) steps  shrine cache hollow Lodge | Den |
       |  stag  glade   natural   well       tavern|~|tavern      well  natural   glade   |
       |   (-76, 24)          Willow Ford Nest -> (0, 40)  <- ford                (76, 24) |
       |  Heron Ford post     rich     Millwatch |~|  Millwatch   rich     Tallow Row     |
       |  keep (-66, 66)   ====road=====[bridge]=====road====     keep (66, 66)          |
       | A1 PLAYER        Millstone Cross  Millstone Br. (0,72)  Gull's Rest     B2 ENEMY_2 |
 z  84 +-------------------------------------+ | +-------------------------------------+
        x -84                    west bank = side A | side B = east bank                x 84
```
The diagonal lanes run A1 -> isle -> B1 and A2 -> isle -> B2 (through the Crown Bridges); the ring road links the four hubs
over the two road bridges; the west and east "connector" roads run between allies past the Den and Lodge.

### 2.3 The river and its 10 crossings (`RiverSystem.setup`, unchanged API)
| Part | Value |
|---|---|
| North arm | Polyline `(0, -86)`, `(0, -60)`, `(0, -30)`, `(0, -12.75)` (2 m outside the map, into the moat), half width **2.5** |
| South arm | `(0, 12.75)`, `(0, 30)`, `(0, 60)`, `(0, 86)`. Flow north -> south (fords' `dir` = `(0, 0, 1)`) |
| Moat | `(0, 0, 12.75, 1.75)` (water r 11.0-14.5), unchanged; the isle is r < 11 |
| Divider / banks | `RiverSystem._build_divider()` works unchanged (2 polylines joined along the moat's west side): `bank_of()` = **side** 0 (west, `player_bank_point` = the player's hub) / 1 (east) / -1 water and isle |
| id | Name | Kind | Centre | Size |
|---|---|---|---|---|
| `bridge_road_s` | Millstone Bridge | Road bridge | `(0, 72)` | Deck 6 m wide (along the river), 9 m long, `dir (1, 0, 0)` |
| `bridge_road_n` | Saltgate Bridge | Road bridge | `(0, -72)` | Same |
| `ford_s` | Willow Ford | Ford (Willow Ford Nest) | `(0, 40)` | r **3.5** |
| `ford_n` | Reed Ford | Ford (Reed Ford Nest) | `(0, -40)` | r 3.5 |
| `bridge_crown_sw` | South-west Crown Bridge | Lane bridge (A1) | `(-9.02, 9.02)` (= 1v1 `bridge_crown_w`) | 8 m wide, 6.5 m long, `dir (-1, 0, 1)` |
| `bridge_crown_nw` | North-west Crown Bridge | Lane bridge (A2) | `(-9.02, -9.02)` (1v1 steps spot) | `dir (-1, 0, -1)` |
| `bridge_crown_ne` | North-east Crown Bridge | Lane bridge (B1) | `(9.02, -9.02)` (= 1v1 `bridge_crown_e`) | `dir (1, 0, -1)` |
| `bridge_crown_se` | South-east Crown Bridge | Lane bridge (B2) | `(9.02, 9.02)` | `dir (1, 0, 1)` |
| `steps_w` | West Crown Steps | Moat ford (side A) | `(-12.75, 0)` | r **3.0** |
| `steps_e` | East Crown Steps | Moat ford (side B) | `(12.75, 0)` | r 3.0 |
Moat sectors fall between the crossing angles 0, 45, 135, 180, 225, 315 deg (the arms join at 90 / 270). Fords: 2 + steps 2 =
**4 uncut circles** (the ground shader's `fords[4]` is enough); river segments 6 (<= 16). Build bans unchanged (1 m water,
8 m crossing, 8 m camp). The arms are straight on purpose (4-way symmetry); the banks are dressed irregularly (20.V5).

### 2.4 The canonical quadrant A1 (the player's; mirror into A2 / B1 / B2 by 2.1)
Distances: "own" = straight to the own keep `(-66, 66)`; 1v1 value in brackets. Crystal amounts as the 1v1 (`balance-1.md`,
`grand-market.md`). "Frame" = placed by `seat_frame` from the 1v1 table; "level" = a per-seat level table (not framed).
| Object | Position | Source | Own (1v1) | Note |
|---|---|---|---|---|
| Keep | `(-66, 66)` | frame | 0 | `KEEP_OFFSET` from the hub, as the 1v1 |
| Hub / start (`start_position`) | `(-59, 59)` | frame | 9.9 | Clearing r 18; wizard + 3 workers (4 after step 18) as the 1v1 offsets |
| `node_<seat>_a` / `_b` | `(-69, 57)` / `(-57, 69)` | frame | 9.5 | 2 000 each |
| Houses V1 / V2 / V3 | `(-73, 69)` / `(-73, 75)` / `(-73, 81)` | frame | 7.6-16.6 | `HOUSE_SLOT` = V1 |
| Barracks H1, towers S1 / S2, Bazaar M1, rally | `(-50, 68)`, `(-60, 52)` / `(-48, 60)`, `(-68, 50)`, `(-53, 53)` | frame | as 1v1 | Rush slots (H2 / P1 / C1) and wall rings (18b) framed too |
| Natural `node_<seat>_mid` | `(-39, 29)` | frame | 45.8 (46) | 2 500; hall **X1** `(-46, 32)`, tower **S3** `(-42, 24)`, Magpie spot **W1** `(-31, 39)` |
| Glade Vein (step 17) + **Stag Glade** camp | node `(-64, 19.5)`, X3 `(-62, 28)`, SG `(-68, 22)`, W3 `(-75, 12)`; stag `(-60, 13)` | frame | 46.5 (46.5) | Sealed by the stag as in the 1v1 (the 7.6 m node-stag gap is that design); stag T3, first spawn 3:30 |
| **Rich** `node_<seat>_rich` ("the Mouth") | `(-14, 62)` | level | 52.2 (83) | 2 500; hall **X2** `(-23, 64)`, tower **S4** `(-9, 66)`, spot **W2** `(-31, 58)`. 16 m from Millstone Bridge: the facing enemy's rich node lies 28 m across the river; the hot district of each front |
| Millrace Vein (step 17) | node `(-16, 36)` | level | 58.3 (44.7) | 1 500; hall **X4** `(-23, 41)`, tower **SM** `(-11, 30)`, spot **W4** `(-12, 45)`; 16.5 m from Willow Ford (1v1 15.9) |
| Ford Vein (step 17) | - | - | - | Not on this map: the shared fords sit on the river line; the Millrace Vein takes the "vein by a nest ford" role |
| Trading post (west) | centre `(-76, 24)`, door `(-72, 24)` | level | 43.2 (37 door) | door = hub + `(-13, -35)`: the 1v1 hub -> west door leg |
| Trading post (south) | centre `(-24, 76)`, door `(-24, 72)` | level | 43.2 | door = hub + `(35, 13)`: the 1v1 hub -> south door leg |
| Tavern | `(-25, 9)`, door toward the West Crown Steps | level | 70.2 (64) | Opens 2:00; explored for every seat from 0:00; 16 m from the ally's tavern (one "tavern square" per side at the steps) |
| Ruin Peddler | `(-30, 50)` | level | 39.4 | Counter faces the map centre |
| Millwatch (watchtower) | `(-8, 52)` | level | 59.7 | Sight 22 covers Willow Ford (14.4 m) and Millstone Bridge (21.5 m) |
| Mossmere Well (essence well) | `(-32, 17)` | level | 59.6 (68) | +0.4 essence / s from 2:30 |
| Bristleback Wallow (T1) | `(-40, 80)` | level | 29.5 (32) | 0:00 |
| Heath lair | centre `(-78, 40)` r 4, patrol `(-78, 36)`, `(-82, 40)`, `(-78, 44)`, `(-74, 40)` | level | 28.6 (32) | **Tusker** at A1 / B1, **Direwolf** at A2 / B2 (2.9) |
| Mouth lair | centre `(-9, 80)` r 5, patrol `(-9, 75)`, `(-14, 79)`, `(-9, 82)`, `(-6, 78)` | level | 58.7 | **Roc** at A1 / B1, **Grizzlemaw** at A2 / B2; under the Old Aqueduct |
| Lost Cache | `(-50, 22)` | level | 46.8 (40-46) | + one per side on the midline (2.5) |
| Standing Stones (landmark) | `(-81, 47)` | level | 24 | Beside the heath lair (1v1: 7 m) |
| Giant's Stump (landmark) | `(-55, 38)` | level | 30 | |
| Old Wood cluster | `(-44, 10)` r 3.5, 6 trees | level | 60 | Seed `OLD_WOOD_SEED` |
| Rabbit homes (6) | `(-58, 80)`, `(-44, 46)`, `(-26, 22)`, `(-82, 62)`, `(-16, 50)`, `(-50, 27)` | level | | >= 14 m from camp spots |
All pairs were checked with a script (clearances of `map-fill.md` 4.1 / 5.2 / 5.5, `grand-market.md` 6.2, road 9 m for camps,
lane 5 m, crossings, water, edges): the only short gaps are the ones the 1v1 already has (keep-V1 7.6 m, the Glade seal,
S1 / S2 / H1 / M1 by the road, the natural 7.07 m off the lane).

### 2.5 The ally midline (one per side: side A at `x < 0`, side B mirrored at `-x`)
| Object | Position | Own keep (both allies) | Note |
|---|---|---|---|
| Magpie Den | centre `(-79, 0)`, door `(-75, 0)` on the connector road | 67.3 | One Den per side (1v1: one per bank) |
| Greywater Lodge | centre `(-63, 0)`, door `(-67, 0)` facing the Den across the road | 66.1 | The "Guild Crossroads" between the two allied bases |
| Gloomcap Hollow (T2 camp) | `(-50, 0)` | 67.9 | First spawn 2:30, as the 1v1 |
| Lost Cache | `(-39, 0)` | 71.3 | |
| Wayshrine | `(-30, 0)` | 75.2 | One per side: the 1v1 "wake in turn, alternating banks" schedule is unchanged |
| Old Wood biome centre | `(-62, 0)`, r 26 | | Dark forest floor round the Den, Lodge and hollow |
| Deer herd (4 deer, respawn 120 s) | graze `(-76, +-15)`, `(-82, +-30)`, `(-67, +-40)` | | One herd per side (8 deer; 1v1 6) |

### 2.6 The isle and the river line (global)
| Object | Value |
|---|---|
| Ember Crown | `(0, 0)`, sealed until 6:00 (balance-1), drops on the wearer's death |
| Ruin Wardens | **6** at r 4, angles 0, 60, ... 300 deg (1v1: 4); never respawn. The last (6th) death drops Warden Scale at `(0, 2)` and Ember Draught at `(0, -2)` (both on the river line: equal for both sides) |
| Pillar ring | r 8; of the 10 pillars (36 deg apart) **i = 1, 4, 6, 9 are left out** (gaps facing the 4 Crown Bridges); heights: pillars {0, 5} share one draw, {2, 3, 7, 8} another |
| Reed / Willow Ford Nests | 3 Mirefangs in each ford, T2, 0:00 (shared by the facing pair) |
| Old Aqueduct (landmark) | Over each mouth: piers `(-4.1, +-78)` and `(4.1, +-78)` (2 aqueducts) |
| Drowned Barge (landmark, draw-only) | In each arm at `(0, +-26)` |
| Willows | Both banks of both arms and the moat's outer bank (seed 17), mirrored 4 ways |

### 2.7 Roads, lanes, posts
- **Ring road (12 nodes, 12 segments; `road_segs[16]` is enough):** `hub_a1 (-59, 59)` -> `w_a1 (-72, 24)` -> `w_a2 (-72, -24)` ->
  `hub_a2 (-59, -59)` -> `n_a2 (-24, -72)` -> `n_b1 (24, -72)` -> `hub_b1 (59, -59)` -> `e_b1 (72, -24)` -> `e_b2 (72, 24)` ->
  `hub_b2 (59, 59)` -> `s_b2 (24, 72)` -> `s_a1 (-24, 72)` -> back. Each hub leg is the 1v1 leg (37.3 m); the connectors
  are 48 m (allies' connector on the own bank; the fronts' connector over a road bridge). Hub ids keep the `"hub"` prefix.
- **Lanes (forest clear 5 m):** `hub_a1 -> hub_b1` and `hub_a2 -> hub_b2`, both through the centre (`_in_path_lane` takes a list).
- **Trading posts (8; signs reused twice, `sign = index % 4`):**
| Seat | West / east post (id, name) | South / north post (id, name) |
|---|---|---|
| A1 | `heron_ford` Heron Ford `(-76, 24)` | `millstone_cross` Millstone Cross `(-24, 76)` |
| A2 | `owlgate` Owlgate `(-76, -24)` | `copperhythe` Copperhythe `(-24, -76)` |
| B1 | `lantern_wharf` Lantern Wharf `(76, -24)` | `saltgate` Saltgate `(24, -76)` |
| B2 | `tallow_row` Tallow Row `(76, 24)` | `gulls_rest` Gull's Rest `(24, 76)` |
- Magpie ambush spots: the 1v1's A1-A4 road spots re-laid on each hub leg and connector (A-spots at 40 % and 75 % of each leg,
  8 per side); worker spots W1-W4 of 2.4 per seat. `TradeNetwork.remote_nodes` = nodes > 30 m from their seat's keep.

### 2.8 Counts: 1v1 -> 2v2
| What | Crown Hollow | Fourfold Hollow | Rule |
|---|---|---|---|
| Area | 120 x 120 | 168 x 168 (1.96x) | |
| Bases / wizards | 2 | 4 | |
| Crystal sites | 8 (+6 with step 17) | 16 (+8 with step 17: no Ford Vein) | per seat = per side of the 1v1 |
| Crossings | 8 | 10 | |
| Trading posts / Dens / Lodges | 4 / 2 / 2 | 8 / 2 / 2 | guild houses one per side (midline) |
| Taverns / peddlers / Lost Caches | 2 / 2 / 4 | 4 / 4 / 6 | |
| Capture points | 8 (4 towers, 2 wells, 2 shrines) | **10** (4 Millwatches, 4 wells, 2 shrines) | shrines stay one per bank (schedule unchanged) |
| Camps | 8 + wardens (4) | **12** (4 wallows, 2 nests, 4 stags, 2 hollows) + wardens (6) | |
| Epic-beast lairs | 8 (4 kinds x 2) | **8** (4 kinds x 2, alive max 8 unchanged) | perf: the beast cap was already 8 |
| Deer / rabbits | 6 / 12 | 8 / 24 | |
| Landmarks | 10 | 12 (stones 4, stump 4, aqueduct 2, barge 2; no Fallen Colossus) | |
| Trees / rocks | ~120 / 22 | ~240 / 44 (9 clusters and 11 rocks drawn per quadrant) | |

### 2.9 Fairness targets (test 20.C5)
| Check | Target |
|---|---|
| Twins | Every collider, obstacle, fog source, point, camp, lair, node, slot at `p` in A1 has its 3 twins; midline objects their 1 twin |
| Path lengths (navmesh, from each keep's drop-off) | To each object and its twins: equal within **1 %** across the 4 seats |
| Keep -> facing enemy keep (A1 -> B2) | **~142 m** via Willow Ford or Millstone Bridge (1v1 lane 122); 136-148 |
| Keep -> diagonal enemy keep (A1 -> B1) | **~187 m** over the isle; >= 1.25x the facing distance (each seat has a clear lane opponent) |
| Keep -> ally keep | **~142 m** by the connector road, never crossing water |
| Keep -> crown | 93.3 m for every seat (1v1: 61) |
| Keep -> own natural / rich / facing enemy's rich | 46 / 52 / ~88 m by path (the rich pair is 28 m apart across Millstone Bridge) |
| Lairs | Each **team** has one of each kind (A1 Tusker + Roc, A2 Direwolf + Grizzlemaw; B mirrors A); per seat the beast strength differs by 300 (1 700 vs 2 000). Fallback if a seat test shows bias: Tusker x4 at the heath + Grizzlemaw x4 at the mouths (same data table) |

### 2.10 Forest, biomes, dressing
- Forest: the 1v1 generator draws **only in A1** (`x in -80..-4`, `z in 4..80`, 9 clusters, 11 rocks, seed 7) and places each
  tree / rock at its 3 twins; the same clearings / corridors (roads, lanes, river, crossings, map-fill spots) apply.
- Biomes (ground shader + `BiomeMap`): Hearth Meadow round the **4** hubs r 22; Old Wood round `(+-62, 0)` r 26; heath where
  `max(|x|, |z|) > 68`; riverbank 6 m of water; ruins on the isle and round stones / stumps; glade the rest.
- Decor density as today (~5 300 instances expected, budget 12 000), map dressing (cliff ring, plateau, border forest,
  horizon) rebuilt for the 168 m square with the **north waterfall and the south gorge at `x = 0`** (20.V1 / 20.V2).

## 3. Size, performance and memory
### 3.1 What grows
| Part | 1v1 | 2v2 | Note |
|---|---|---|---|
| Ground / collider / nav region | 120 m | 168 m | `main.gd` reads the level's `map_size` (section 5) |
| Navmesh (cell 0.25) | 480^2 cells | 672^2 (1.96x) | First bake ~2x the 1v1 time: 20.C3 logs `bake_ms`; target <= 2.5x the 1v1 and <= 5 s on the user's desktop |
| Runtime rebakes (every placement / destruction, threaded, coalesced) | 1 map | 1 map, ~2x longer, ~2x as frequent (4 builders) | If a 2v2 rebake takes > **1.5 s**: 20.C6 splits the navmesh into 4 quadrant regions (rebake only the touched one; also serves walls 18b) |
| Fog | 60 x 60 x 2 sides | **84 x 84 x 2 sides** | Per side, 2 m cells, 5 Hz per side: cost follows the unit count, not the seats; memory ~28 KB |
| BuildGrid | cells -29..28 | -41..40 | From `MapInfo` |
| River mask / near grid | 240^2 / 64^2 | 336^2 (339 KB) / 88^2 | `RiverSystem` reads `MapInfo` |
| Decor / trees / rocks | ~2 700 / ~120 / 22 | ~5 300 / ~240 / 44 | Chunks **3 x 3 of `map_size / 3`** (56 m): same draw-node count as today (<= 140) |
| Edge + horizon bakes | on disk ~4 MB | + ~4 MB (a second set, loaded only on this map) | |
| RAM (estimate) | | **+40-60 MB** vs a 1v1 match | navmesh, colliders, decor, second edge set |

### 3.2 Units and the pop cap (decided here; Q3 lets the user change it)
| Source (normal, map fill + trade + champions on) | 1v1 peak | 2v2 peak |
|---|---|---|
| Per seat: 12-14 workers, 16-20 soldiers, wizard, 3 champions, 4-6 caravans | ~2 x 40 | ~4 x 40 = 160 |
| Camp creatures (wallows 2, nests 3, stag 1, hollow 4, wardens) | 24 | 32 |
| Beasts / Magpies + trackers | 8 / ~20 | 8 / ~30 |
| **Total** | ~170 | **~230** (step-18 houses at 60 pop: ~280) |
- **Decision:** the 2v2 keeps the 1v1 caps (**40 per seat, Nature 50**, house levels as `building-levels.md`), and adds a gate:
  **`perf_test.gd -- map=2v2 units=300`** (4 Commanders, river, 12 camps, 8 beasts, trade, 12 champions) must print
  `PERF OK` at **<= 15.0 ms / frame** on the quiet PC (the 1v1 rule of 8 ms / 100 units would allow 24 ms: too slow for 60 fps);
  a 400-unit stress run must stay <= 22 ms with `stuck = 0`. Today 200 units cost ~11 ms (quiet), so ~12 % must be saved:
  `AIWorldCache` (20.A6), one shared unit grid for the 5 Hz / 1 Hz map-fill passes, idle units' think staggering (20.C7).
- **Fallback ladder** (lead, in order, each re-measured): (1) `Skirmish.pop_cap_scale = 0.85` in 2v2 (40 -> 34, Nature 50 -> 42,
  house levels scaled the same); (2) ThievesGuild `MAX_ALIVE` 8 -> 6; (3) camp creatures of tier 1 respawn once only. The user
  is told when a step is applied.

## 4. The player model and the rules
### 4.1 Seats and sides
| Term | Meaning | Code |
|---|---|---|
| **Seat** | One kingdom slot (human or bot): owner of units, buildings, economy, essence, gold, pop, champions, bounties, orders | **the existing `team` int**: `PLAYER 0`, `ENEMY 1`, `ALLY 3`, `ENEMY_2 4` (`NEUTRAL 2` is never a seat) |
| **Side** | A team of seats: hostility, fog, capture points, river bank, victory | `Teams.side_of(seat)`: 0 = `PLAYER` + `ALLY`, 1 = `ENEMY` + `ENEMY_2` |
- `enum Team { PLAYER, ENEMY, NEUTRAL, ALLY, ENEMY_2 }`: values only **appended** (saves, scenes and the literal `2` for
  NEUTRAL keep working). In the 1v1 the seats are `PLAYER` and `ENEMY`, one per side: every existing rule is unchanged.
- **Mapping to `ai-2v2.md`**: its "seat 0 / 1 / 2 / 3" are `PLAYER` / `ENEMY` / `ALLY` (value **3**) / `ENEMY_2` (value **4**);
  code never writes the numbers, only the enum names or `Teams.seats()`. Its `for_seat(seat)` calls are the existing
  `for_team(team)` (no rename). Its "one Commander per team" guard (`commander.gd _ready` 316-320) stays: each bot seat has
  its own `team` value.
- The human is always `PLAYER` (the lobby may later let them pick a quadrant: every quadrant is the same map).

**The encoding decision (the one contract for 20.D1, 20.D2 and 20.D3).** `ui-2v2.md` 14.1 assumes one `team` value per
player (`ALLY 3`, `ENEMY_2 4`, `Unit.are_allies`); `ai-2v2.md` 3.1 speaks of seats (0-3) + sides with "1v1: seat = side =
team". Both are the same model once `team` **is** the seat: this spec freezes **team = seat**, sides from `Teams`, and
`Unit.are_allies(a, b)` as the name the UI and gameplay call (it delegates to `Teams.is_ally`). Cost of the two ways:
| | **A: `team` = seat (chosen)** | B: `team` = side + a new owner field |
|---|---|---|
| Free | Per-player banks / economies / guilds / boards / markets (84 `for_team` / `of_team` calls); every "mine" check (`team == PLAYER`: ~40 in `selection_manager.gd` + 6 UI files, so the ally is never orderable); AI "own" lists; one Commander per seat (its guard in `_ready` stays) | Hostility, fog, capture presence, river banks (~110 sites) |
| Must change | Hostility (`is_enemy_of` once + ~30 raw sites, incl. the right-click-attacks-the-ally bug in `selection_manager.gd` 2037 / 2201 and tower targeting in `building_gun.gd` 115), friendly filters (~15), per-side systems (~35), seat loops (~40), base tables (~25) | All of A's seat loops and base tables, plus every per-player lookup and "mine" check (~150), an `owner` on every unit, building, projectile, summon, caravan and champion, save data |
| 1v1 risk | None: with 2 seats `is_hostile(a, b) == (a != b)` exactly | Every ownership path touched |
| Total | **~230 sites** (~130 of them loops / tables any 4-player map needs) | ~280+ sites and the ally is orderable until every UI check moves |

### 4.2 Alliance
| Rule | Value |
|---|---|
| Hostility | `Teams.is_hostile(a, b)`: different sides, or NEUTRAL against any seat. Allies **never** auto-attack, aggro, shoot (towers, keeps), splash or chain-hit each other; right-click on an ally = move / follow, never attack |
| Friendly effects | Heals, shields, auras, blessings, Rallying Cry, support autocasts and champion help apply to **allied** units too (`Teams.is_ally`) |
| Vision | Shared per side: an ally's units, buildings, towers and SightMarkers reveal for both; ally units are drawn like own ones (colour from 20.D2) |
| Control | The human can select and inspect ally units and buildings **read-only** (card, no command card), like champions. `selection_manager` "mine" = `team == PLAYER` stays right |
| Allied buildings | Shops: usable (paid from your own banks). Drop-off: **own** keep / barracks only. Home healing: **own** keep only. Garrison / Muster Bell: own seat only. Allied towers and walls protect you (hostility is by side) |
| Allied gates (18b) | Open for allies' units as for own ones |
| Taverns / posts | "Held by the enemy" = a hostile **side** is present (allies never block each other) |
| Chat / pings | 20.D2 (`AllyChannel`, `ai-2v2.md` 5.1) |

### 4.3 Resources
Separate per seat: crystals, essence, gold, pop, Bazaar, caravans, champion guild (hire / revive), bounty board, research,
building levels. **No gifts in v1** (Q4; if the user picks the Tribute option: 100 crystals / 50 gold / 50 essence per press,
10 % lost, 30 s cooldown per resource, the ally bot tributes back only when it banks > 800 crystals: a later task 20.C8).
Kill income, camp clear bonuses, beast rewards, loot sacks, caches and hunts pay the **seat** credited with the kill / opening.

### 4.4 Defeat, victory, crumble
| Event | Result |
|---|---|
| A seat has no living defeat-relevant building (1v1 rule: sites count, walls don't) | The seat is **out** |
| A seat has no keep and no barracks for **120 s** (2v2 only, `ai-2v2.md` F6) | Out (a lone house or tower cannot keep a side alive) |
| A bot concedes (`ai-2v2.md` 7.2) / the human presses F10 twice | That seat is out (the human's F10 in 2v2 shows `Press F10 again: your kingdom surrenders, your ally fights on`) |
| A seat goes out | `eliminate_seat(seat)`: its buildings **collapse** (no loot, no bounty payouts), its units, champions and caravans `leave_map()` over 3 s, its crown drops, its bounties end without refund, its capture-point income moves to the surviving ally (the side keeps the points), its posts' routes end. Message to all: `<Hero> has fallen. <Kingdom> is out of the war.` |
| **All seats of a side are out** | That side loses: `Events.mission_ended(victory)` with `victory = (side_of(PLAYER) != lost side)`; `match_ended(winner_side)` |
| Human out, ally alive (Q2) | The human **watches**: free camera, side vision, the ally's panel (20.D2), messages; banner `Your kingdom has fallen. Your ally fights on.`; the final VICTORY / DEFEAT is the side's. Pause menu `Leave match` = defeat for the side's human |
| Same tick | Both sides' last seats out together = the human's side loses (never a draw, as the 1v1) |
| Wizard death | Never a defeat: respawn per seat (30 + 15 s per death, max 90) at its own keep / oldest barracks |
Why not "both wizards dead": wizards respawn in every mode; buildings are the only rule that ends a match and scales to 4 seats.

### 4.5 Wizards, crown, map fill and trade with 4 seats
| System | 2v2 rule |
|---|---|
| Wizards | 4 wizards; groups: every wizard in **`"wizards"`** (new); the human's in `"heroes"`, allied bots' in **`"ally_heroes"`** (new), hostile bots' in `"enemy_heroes"`. AI casting is on for every non-human seat (`not Teams.is_human(team)`) |
| Ember Crown | One; any wizard; `worn_by_player` / `worn_by_ally` / `worn_by_enemy` objective states; crown messages use the hero's name |
| Capture points | Presence counted per **side** (allied counters add); `owner_side` (ring colour, sight, far-bank x1.25) + **`owner_seat`** = the seat with the most counters when the capture completes (ties: the seat whose `home_seat_of(point)` it is, then the lower `team` value); well essence and "your forces captured" go to `owner_seat`; income moves to the ally if that seat is out |
| Wayshrine blessing | The whole capturing **side** (both seats' soldiers, wizards, champions), 60 s; schedule unchanged (one shrine per bank) |
| Watchtower sight | A `SightMarker` of the `owner_seat`: fog is per side, so both allies see |
| Camps | Clear bonus / drops to the seat of the last kill; respawn blocked by any seat's unit within 16 m; **underdog** = the side whose living wizards' **average** level is lower (x1.25 XP, x1.5 clear bonus for any seat of it) |
| Epic beasts | As today (combatants of any seat); reward to the killer's seat; underdog per side; `MAX_ALIVE` 8 |
| Critters | Hunt reward to the hunter's seat; "visible to some seat" = any side |
| Magpies | Raid any seat's caravans (from 5:00) and remote-node workers (from 8:00); "home area" per seat keep; `MAX_ALIVE` **8** (1v1 6), `TICK` 75 s |
| Hunters (Lodge) | Contracts per seat; trackers leave the Lodge nearer by path (2 Lodges) |
| TradeNetwork | `base_positions` = the 4 hubs; any seat may route to any post (value by path length as today); ledgers per seat; posts held per side |
| Taverns | 4, open 2:00, any seat hires at any tavern through its own guild; hire name variants per guild as today |
| Stats / end screen | Per seat (4 rows; layout 20.D2) |

### 4.6 Start state (every seat = the 1v1 start)
250 crystals, keep, wizard at its hub, 3 gathering workers (2 on `a`, 1 on `b`; 4 workers after step 18), 3 / 20 pop, no
soldiers; fog explored r 20 round each hub **for its side**; taverns, posts, guild houses, points and landmarks explored for
both sides from 0:00. Kingdoms: any of the 4 per seat, mirrors allowed (lobby 20.D2). Start camera frames the own keep.

## 5. Contracts (proposed; the lead freezes them in `CLAUDE.md`: task 20.L1)
- **`Teams`** (`scripts/core/teams.gd`, `class_name Teams`, static only, lead): `configure(sides: Dictionary, human := PLAYER)`
  (seat -> side; the level calls it in `_init`; `main.gd` configures the 1v1 `{PLAYER: 0, ENEMY: 1}` by default so every
  mission and test gets the old behaviour), `seats() -> Array[int]`, `side_of(team) -> int` (-1 NEUTRAL / unknown),
  `seats_of_side(side)`, `is_ally(a, b)` (same side; a seat is its own ally; NEUTRAL with NEUTRAL true), `is_hostile(a, b)`
  (not ally), `allies_of(seat)` (excluding itself), `hostile_seats(seat)`, `is_human(seat)`, `human_seat()`,
  `opposing_side(side)`. 1v1: `is_hostile(a, b) == (a != b)` exactly.
- **`MapInfo`** (`scripts/core/map_info.gd`, static, lead): `size` (120 default), `half()`, `set_size(m)` (main.gd `_init` from
  the level's `map_size`), `contains(pos, margin := 0.0)`. Replaces the hard-coded 60 / 120 in fog, river, BuildGrid, minimap,
  camera bounds, bounty / champion bounds, commander scout grid and the art builders (they read their own copy of the value).
- **`Unit.Team`** appended `ALLY`, `ENEMY_2`; `static func Unit.are_allies(a: int, b: int) -> bool` (= `Teams.is_ally`:
  the same team, or two seats of one side; NEUTRAL is allied only with itself, so creatures still never fight each other);
  `Unit.is_enemy_of(other)` = `not are_allies`; new `Unit.is_ally_of(other)`; `team_color` / `team_hp_color` return the
  `ui-2v2.md` 2.3 colours for `ALLY` / `ENEMY_2` (20.C1).
- **Level seat API** (`Skirmish`, 1v1 values in brackets; names from `ai-2v2.md` 3.1): `seats()`, `side_of(seat)`,
  `seats_of_side(side)`, `hostile_seats(seat, alive_only := true)`, `ally_seat(seat)` (-1), `is_human(seat)`,
  `seat_alive(seat)`, `eliminate_seat(seat, message := "")` (= `surrender`), `seat_frame(seat) -> Transform3D` (2.1),
  `slot_override(seat, row_id) -> Vector3` (INF = none), `keep_of`, `wizard_of`, `kingdom_of`, `start_position`,
  `base_center`, `node_of(seat, suffix)` (ids `node_<seat name>_<suffix>`, seat names `fire` / `shadow` kept for the 1v1,
  `a1` / `a2` / `b1` / `b2` in the 2v2), `home_nodes`, `natural_node`, `rich_node`, `natural_hall_spot`, `rich_hall_spot`,
  `market_slot`, `tower_slot(seat, id)`, `rush_slot(seat, id)`, `respawn_point`, `respawn_time_left`, `stats_of(seat)`,
  `home_seat_of(pos) -> int` (nearest seat by cached path, 20 m cells; **-1** where a hostile seat is within 15 %: the isle,
  the fords, the rich pairs; allies' ties -> the lower `team` value), `home_side_of(pos)`, `lane_opponent(seat)`
  (A1 <-> B2, A2 <-> B1 [1v1: the other]), `shared_rally(side)` (`(-40, 0)` / `(40, 0)`), `staging_point(seat, target)`
  (22 m before the target hub on the attacker's path), `scout_path(seat)` (A1: `(-39, 29)`, `(-16, 36)`, `(-24, 72)`,
  `(24, 72)`, `(39, 29)`, `(24, 72)`, `(-24, 72)`, rally; mirrored per seat; never through the isle while wardens live, never
  a ford with a living nest), `map_size` (var), `winner_side`. Static helpers that assume the 1v1 (`enemy_team_of`,
  `_mirror`, `river_polylines`, `road_param`) become instance methods reading the level's layout.
- **Per-seat singletons**: `Economy / EssenceBank / GoldBank / ChampionGuild / BountyBoard / ChampionSense.for_team(seat)`,
  `Market.of_team(seat)`: unchanged API; the level creates one per `Teams.seats()`.
- **FogOfWar** per side: `state_at(team, pos)` / `is_visible(team, pos)` / `is_explored` accept a seat and read its side;
  `reveal(team, pos, r)` reveals for the side; `grid_image(team)`; `local_team` = the human seat (read everywhere, never
  assumed `PLAYER`); sources of allied seats stamp the same layer.
- **RiverSystem**: `bank_of(pos)` returns a **side** (0 / 1 / -1); `setup(...)` unchanged; sizes from `MapInfo`.
- **CapturePoints / CapturePoint**: `owner_side`, `owner_seat`, `capture_side`; `held_by(team)` means "held by that seat's
  side"; `held_by_seat(seat)` for income lists.
- **Hooks for 20.D2** (UI, `ui-2v2.md` 14.1, all on the level unless noted): `mode: StringName` (`&"1v1"` / `&"2v2"`),
  `slots: Array[Dictionary]` (written by the menu before `_ready`: kingdom, difficulty, style, personality per seat;
  `kingdom_of(seat)` reads it, the 1v1 fills it from `player_kingdom` / `enemy_kingdom`), `slot_info(team) -> Dictionary`
  `{name, kingdom, wizard, wizard_id, level, alive, respawn_left, defeated, defeated_at, role, side}`, `team_state(team)`
  (`&"standing"` / `&"defeated"` / `&"surrendered"` / `&"left"`), signals `kingdom_defeated(team)` and
  `team_alert(team, kind, pos)` (`&"attacked"`, `&"wizard_fallen"`, `&"wizard_back"`), `map_bounds() -> Rect2`
  (`Rect2(-84, -84, 168, 168)`; square, so the minimap keeps 1.31 px/m), `end_screen_table() -> Dictionary` (4 columns),
  objective / F10 texts (4.4), `MAP_2V2_NAME = "Fourfold Hollow"`, scene `res://scenes/skirmish_2v2.tscn`, root node
  `Skirmish2v2`; `FogOfWar.bounds()` / `grid_size()`; `RiverSystem.mask_rect()`; `Teams.relation(local, team)` (`&"self"` /
  `&"ally"` / `&"enemy"` / `&"neutral"`) for `TeamColors`; spectate = `team_state(PLAYER) != &"standing"` while the side stands.
- **Hooks for 20.D3** (AI): everything of `ai-2v2.md` 3.1 above, `eliminate_seat` + F6, `owner_seat`, side fog.

## 6. Code impact: every "exactly two players" assumption
Sweep of `scripts/` (+ `tests/perf_test.gd`, `art/environment/*`) on 2026-09-26: **248 hits** in 62 files from the two-team
sweep, plus **~35 friendly / hostile filters** that are right for two teams but wrong for allies (`team != x.team` as
"enemy", `team == x.team` as "friend"). With `team` = seat, **~50 are already right** (per-seat banks, guilds, markets,
boards, "mine" = own seat, one Commander per seat); **~230 sites in ~55 files need an edit**. Fix classes:
**H** hostility (`!=` team as "enemy" -> `Teams.is_hostile`), **F** friendly (`==` team as "friend" -> `Teams.is_ally`),
**S** per side (fog, capture, bank, blessing, underdog, "held", "some team sees"), **L** seat loops (`[PLAYER, ENEMY]`,
`1 - team`, `enemy_team_of`, `[0, 0]` arrays, `posmod(team, 2)` -> `Teams.seats()` / `hostile_seats()` / dictionaries),
**B** two hard-coded bases (keep / shadow_keep, hero / shadow_hero, `_mirror`, fire / shadow ids) -> seat tables + frames,
**M** map size 60 / 120 -> `MapInfo`, **W** wizard groups, **U** colour / text / per-seat HUD (20.D2 designs it).
| File | Where (function: lines) | Class | Fix |
|---|---|---|---|
| `units/unit.gd` | enum 25; `is_enemy_of` 1154-1158; aura / nearby filters 918; `team_color` 1184-1200; `_team_kingdom` 1784-1800 | E H F U B | Append enum; `Teams.is_hostile`; `is_ally_of`; friends = allies; colour by relation; kingdom from `level.kingdom_of(seat)` |
| `units/wizard.gd` | `_ready` "heroes" 109; `credit_kill` 230-251 | W OK | Groups `"wizards"` + by relation; kill credit per seat is right |
| `units/shadow_wizard.gd`, `ice_wizard.gd`, `nature_wizard.gd` | 60-61, 77 / 47-54 / 48-55 | W | `enemy_heroes` / AI cast when `team != PLAYER` -> relation groups, `not Teams.is_human(team)` |
| `units/champion.gd` | `owner_kingdom` 721-735; purse on death 548-564; own-team filters 243, 400, 487 | B OK F | Kingdom per seat; purse to killer seat (right); allied buildings count as friendly where it helps (400) |
| `units/champion_abilities.gd` | friend filters 803, 857, 884, 1941, 2077; bounds 1149, 1370 | F M | Allies are friends; `MapInfo` |
| `units/support_caster.gd` | heal filter 97 | F | Allies |
| `units/item_passives.gd`, `units/creature_abilities.gd`, `units/projectile.gd` | team filters (3 / 4 / 1) | F H | Allies friendly; creatures stay hostile to every seat |
| `spells/spell_caster.gd` | `_cast_rime_aegis` 504, `_cast_wild_bloom` 544 (+ other `get(&"team") != team` friend filters); `_is_enemy` 1117 | F OK | Allies; damage goes through `is_enemy_of` (fixed once) |
| `spells/spell_zone.gd` | `_is_enemy` 80 | OK | via `is_enemy_of` |
| `items/inventory.gd` | shop own team 395, NEUTRAL literal 409; HUD lines 799 | F U | Allied shops allowed; lines for the human seat |
| `items/item_actives.gd` | `_home_point` 635-651; Rallying Cry "heroes" 396 | B W | Own seat's keep; `"wizards"` / relation |
| `items/essence_bank.gd`, `recipes.gd`, `campaign/item_drops.gd` | per team | OK | per seat |
| `buildings/building_gun.gd` | target filter 115 | **H** | Towers / keeps never shoot allies |
| `buildings/building.gd` | colours 715, 745; `for_team` / `defeat_relevant` 70-118 | U OK | Relation colours; per seat right |
| `buildings/keep.gd` | default keep type 107 | B | Kingdom per seat |
| `buildings/build_grid.gd` | `MIN_CELL` / `MAX_CELL` 12-13 | M | From `MapInfo` |
| `buildings/market.gd`, `economy/*.gd` | per team | OK | per seat (creation loop in main.gd) |
| `economy/caravan.gd` | `LOCAL_TEAM = PLAYER` 41; HUD 161, 241, 487; own buildings 113, 628 | U OK | Human seat; own-seat buildings right |
| `economy/worker.gd` | `nearest_drop_off(team)` 365 | OK | Own seat only (rule 4.2) |
| `world/main.gd` | `MAP_SIZE` 7, `PLAYER_START` 8, economies 41-43 / `_add_economy` 485-490, fog reveal 57, ENEMY facing 163 | M B L U | `map_size` var + `MapInfo`, `_start_of(seat)` hook, one Economy per `Teams.seats()`, reveal per seat, facing toward the map centre |
| `world/skirmish.gd` | `SHADOW_START` / `KEEP_OFFSET` 38-39; kingdoms 308-311, 382-399, 1640-1691; `keep` / `shadow_keep`, `hero` / `shadow_hero` 331-332; `guilds` / `gold_banks` 339-343; `enemy_team_of` 393; `start_position` 413; `keep_of` 418; `base_center` 424 + `_mirror` 1710; node / slot helpers 429-489; `bank_of` 514-519; `wizard_of` 534; respawn 549-568, 1472-1521; `surrender` 588; `stats_of` 597-674; objective 685; ground spots 695; spawns 807-815, 1212-1246; fog reveals 1100, 1303, 1325; `_add_mapfill_service` / guilds / banks `local_team` 1067, 1312, 1352, 1380; `_setup_champions` 1301-1315; `_create_gold_banks` 1362-1387; `trade_network.base_positions` 1146; `_check_end` 1464-1469; `_home_healing` 1480; `_end_game` 1563; `_claim_wizard` 1697 | B L S W U | The seat refactor (20.C3): seat tables, `Teams.seats()` loops, `seat_kingdoms`, `eliminate_seat`, F6, side victory, per-seat stats; 1v1 behaviour identical |
| `world/fog_of_war.gd` | `SIZE` / `HALF` / `MAP_HALF` 21-25; layers 53-56; `state_at` 117-123; 142-186, 232-237, 268-298; `_team_pass [0, 0]` 65 / 148 / 261; alternation 226-227; sources 254; hide non-local 322-372, 418, 454 | M S L | `MapInfo`; layers per **side**; seats map to sides; hide units of hostile sides only |
| `world/river_system.gd` | `MAP_HALF` / `MASK_SIZE` / `GRID_HALF` 32-44; `PLAYER_TEAM` / `ENEMY_TEAM` 45-46; `bank_of` 195-204 | M S | `MapInfo`; returns sides |
| `world/capture_points.gd` | presence `[0, 0]` 291, 307, 337; `[team]` 185-187, 328; `blessed[t]` 313-328; `update_capture(dt, counts[0], counts[1])` 294; owners 413-429; wells 466-499; `_decide_alt_bank` 548-562; blessings 600-623; reveals 409; `_bank_of` 388 | S L | Presence per side, `owner_side` + `owner_seat` (4.5), blessings per side, income per seat |
| `world/capture_point.gd` | `owner_team` / `capture_team` 51-72; `update_capture(n_player, n_enemy)` 197-223; clamp 278; far factor 287; sight 344; colours 372 | S U | Sides; SightMarker of `owner_seat` |
| `world/camp_manager.gd` | `_cleared_counts` 84-99, 294; `underdog_team()` 178-183; `wizard_level` 206-226; local fallback 332 | L S B | Per seat counts; `underdog_side()` by average level |
| `world/neutral_camp.gd` | respawn block 322; credit 344-349; underdog 366, 395; reward 394-399 | L S | Any seat blocks; credit per seat; underdog per side |
| `world/epic_beasts.gd` | `grant` / killer 362, 521; `underdog_team` 402-408; `_award_underdog` 564-581; `_pay` 623-641; `_blocked` 687-698; `_wizard_of` 712-728 | L S B | Seats; underdog per side; wizard per seat |
| `world/critter_herds.gd`, `world/game_critter.gd` | `_hunted` 35-46, 133, 335; reward 145, 366; sees 374-379; 298, 314, 337, 440, 722 | L S | Seats; "seen by a side" |
| `world/trade_network.gd` | `base_positions` 70-71, 844-853; ledgers 92-105; `is_far` 313; `remote_nodes` 365-383; routes / hubs 259, 734-762; refresh 578-591; holders 632-654; filters 503, 596, 614, 721 | B L S | 4 hubs, ledgers per seat, holders per side |
| `world/thieves_guild.gd` / `ai/thief_band.gd` | loops 73, 254; `_remote_nodes` / `_keep_position` 533-565 / 249-259, 975-982; filters 205, 232, 623, 647 | L OK | Seat loops; per-seat keep lookups are right |
| `world/hunters_guild.gd`, `ai/tracker_contract.gd` | Magpie reward 562-573; lodge choice 466-479 | L OK | Seats; nearer Lodge by path |
| `world/bounty_board.gd`, `world/bounty.gd` | colours 115-124; HUNT victims 718-722; bounds 441; local fallbacks 800, 351 | U L M | Relation colours; any seat victim; `MapInfo` |
| `world/champion_guild.gd` | `variant_for` `1 - other` 293-301; `_wizard` 536-559 | L B | Variant by "claimed by any other guild"; wizard per seat |
| `world/tavern.gd`, `world/trade_post.gd` | `is_held_by_enemy_of` 139-153 / 115-130; colours 186 | S U | By side |
| `world/loot_sack.gd`, `world/lost_cache.gd`, `world/sight_marker.gd` | 30, 181 / 66 / 8 | L OK | Any seat |
| `ai/*` (`commander.gd`, `ai_trade.gd`, `ai_champions.gd`, `ai_mapfill.gd`, `ai_memory.gd`, `champion_sense.gd`, `champion_brain.gd`) | 52 sites listed in `ai-2v2.md` 2 (incl. `_side()` 412 / 2673, `X2_SPOT` 92, `RALLY` / `ANCHOR` / `SCOUT_PATH` 150-154, `enemy_team_of` 410, hostile filters 2405, `posmod(team, 2)` 119, `1 - team` 276, 837-847, scout grid `MAP_HALF` 450) | B L H M | 20.A1 / 20.A5 (ai-coder) through the seat API |
| `ui/selection_manager.gd` | "enemy" = `!= PLAYER` 220, 489, 1963, 1968, **2037, 2201** (right-click attack target), 2196; build checks 706-712, 774, 1698; `is_explored(PLAYER)` 1716 | **H** OK | Right-click on an ally never attacks; hidden = hostile side only; "mine" stays `PLAYER` |
| `ui/selection_panel.gd` | `is_own` 298-301; `respawn_time_left(hero.team)` 634 | OK U | Ally = read-only card (20.D2) |
| `ui/command_card.gd` | enemy inspect 554; `essence_of(PLAYER)` 575 | H OK | No command card on ally units |
| `ui/minimap.gd` | `map_size` 89 + fog rect 476; colours 32-37, 497-556, 625-694; `grid_image(PLAYER)` 208; waves 354; hunts 313 | M U S | `MapInfo`; relation colours; side fog (20.D2) |
| `ui/hud.gd`, `ui/top_bar.gd`, `ui/champion_bar.gd`, `ui/trade_window.gd`, `ui/post_panel.gd`, `ui/tavern_window.gd`, `ui/shop_window.gd` (304: allied shops), `ui/bounty_mode.gd` (40: `MAP_HALF_FALLBACK`), `ui/flag_card.gd`, `ui/portrait.gd`, `ui/rts_camera.gd` (`bounds` 14) | as the sweep | U M F OK | 20.D2's UI tasks; camera bounds and bounds fallbacks from `MapInfo` |
| `ui/menus/main_menu.gd`, `menu_flow.gd`, `pause_menu.gd` | 2 slots, `BOT_NODE "ShadowBot"`, `player_kingdom` / `enemy_kingdom`, surrender 116 | B U | Lobby (20.D2) writes the level's `slots` + per-seat bots; 1v1 path unchanged |
| `vfx/trade_popups.gd`, `vfx/route_line.gd` (176, 284: `team != 0`), `vfx/champion_barks.gd`, `audio/game_audio.gd` (237-404) | human-only popups / sounds | U | Human seat (`Teams.human_seat()`), ally events optional |
| `campaign/*`, `missions/*` | 1v1 missions | OK | `Teams` default config keeps them identical |
| `tests/perf_test.gd` | `team = PLAYER` 57; `main.tscn` only | M | `-- map=2v2` option (lead) |
| `art/environment/build_env.gd`, `map_dressing_art.gd`, `horizon/horizon_builder.gd`, `biomes/biome_map.gd`, `ground_params.gd`, `ground.gdshader` | `MAP_HALF 60`, 3 x 3 chunks of 40 m, 2 hubs / 1 lane / 4 spots / 2 woods / 8 ruins uniforms, mouths at x = -15 / 15 | M | 20.V1-20.V4 |

## 7. Tasks (step 20 map + rules; `ai-2v2.md` 12 has the 20.A* tasks, `ui-2v2.md` the UI tasks)
**Order:** 20.L1 -> 20.C1 + 20.C2 + 20.C3 (different folders, in parallel) -> 20.C4 -> 20.C5 + 20.V1-20.V6 -> 20.A6 / 20.A1
(ai-2v2.md) -> 20.C7 perf -> 20.C6 only if the rebake budget fails -> 20.L2. 1v1 first: every task keeps the smoke test
(`victory=true`), the 1v1 perf test and every existing test green.
| Id | Owner | Task | Files | Done when |
|---|---|---|---|---|
| 20.L1 | lead | Freeze section 5: `Teams`, `MapInfo`, enum append (one-line contract edit in `unit.gd` or delegated to 20.C1), CLAUDE.md contract lines, `perf_test.gd -- map=2v2 units=N` | `scripts/core/teams.gd`, `scripts/core/map_info.gd`, `CLAUDE.md`, `tests/perf_test.gd` | 1v1 smoke / perf / all tests unchanged; `Teams.is_hostile(a, b) == (a != b)` for every 1v1 pair (test); `MapInfo.half() == 60` by default |
| 20.C1 [H] | gameplay-coder | Hostility and friendship: `Unit.are_allies`, `is_enemy_of` / `is_ally_of`, `team_color` / `team_hp_color` for ALLY / ENEMY_2 (`ui-2v2.md` 2.3), every H / F site in `scripts/units/`, `scripts/spells/`, `scripts/items/` (section 6), wizard groups `"wizards"` / `"ally_heroes"`, AI cast rule, `_team_kingdom` / `owner_kingdom` per seat, `MapInfo` bounds in champion abilities | `scripts/units/*`, `scripts/spells/*`, `scripts/items/*`, `tests/test_20_c1.gd` | Test with `Teams` configured 2v2: an ALLY soldier next to PLAYER soldiers is never attacked by them, by a tower or by a Fireball / Thornburst / chain; Wild Bloom and Rime Aegis heal / shield ALLY units; an ENEMY_2 unit is attacked like an ENEMY one; the ALLY wizard autocasts, the PLAYER wizard never; 1v1 tests unchanged |
| 20.C2 [H] | systems-coder | World services per side / seat: fog per side + `MapInfo` sizes + `bounds()` / `grid_size()`, `RiverSystem` sizes + side banks + `mask_rect()`, BuildGrid range, capture points (`owner_side` / `owner_seat`, side presence, blessings), camps / beasts underdog per side, critters, trade network (4 hubs, seat ledgers, side holders), thieves / hunters guilds, bounty board victims, loot sack, taverns / posts held by side, champion guild variant, tower `building_gun` hostility | `scripts/world/*` (not skirmish), `scripts/buildings/building_gun.gd`, `build_grid.gd`, `tests/test_20_c2.gd` | Test (2v2 config, flat test map 168 m): an ALLY unit reveals fog for PLAYER; a point with 2 PLAYER + 2 ALLY counters is captured by side 0 with `owner_seat` = the seat with more counters; its well pays that seat; the blessing hits all 4 allied units; `bank_of` returns sides; an allied tower ignores PLAYER units and shoots ENEMY_2; a Magpie raids an ALLY caravan; fog / BuildGrid / river accept positions at +-83; 1v1 tests unchanged |
| 20.C3 [H] | systems-coder | Skirmish seat refactor (1v1 unchanged): seat API of section 5 incl. the 20.D2 hooks (`mode`, `slots`, `slot_info`, `team_state`, `kingdom_defeated` / `team_alert` signals, `map_bounds`, `end_screen_table`), per-seat keeps / wizards / economies / banks / guilds / boards, spawns and start state per seat, respawn and home healing per seat, `eliminate_seat` + crumble, F6, side victory, human spectate state, surrender per seat, per-seat stats, `map_size` var + `_start_of(seat)` in main.gd, static 1v1 helpers to instance methods, `bake_ms` log | `scripts/world/skirmish.gd`, `scripts/world/main.gd`, `tests/test_20_c3.gd` | 1v1: smoke `victory=true`, 2.S3 / 9.x / 10.x / 12.x tests pass; test with a 3-seat config: killing every ALLY building puts ALLY out (buildings collapse, units leave within 3 s, message), the match goes on; then every PLAYER building -> `mission_ended(false)`; a seat with only a house for 120 s is out; `seat_frame(ENEMY) * p == p` in the 1v1 |
| 20.C4 [H] | systems-coder | The Fourfold Hollow level: `Skirmish2v2 extends Skirmish` with every table of section 2 (frames, level tables, 10 crossings, 8 posts + ring road, midline services, 10 points, 12 camps, 8 lairs with per-lair kind, isle with 6 wardens / 6 pillars, deer / rabbits, landmarks, forest drawn in A1 + 3 twins, willows, Old Wood), `home_seat_of` / `lane_opponent` / `shared_rally` / `staging_point` / `scout_path`, 4 seats started | `scripts/world/skirmish_2v2.gd` (new), `scenes/skirmish_2v2.tscn` (new), `tests/test_20_c4.gd` | Headless: 4 keeps, wizards and 12 workers spawn gathering; 4 bot Commanders (plain, `--no-council`) play 10 min with 0 script errors; every H1 / X1 / M1 / S1-S4 framed slot passes `BuildGrid.check` for its seat; no navmesh in deep water; every crossing walkable; `bake_ms` logged |
| 20.C5 | systems-coder | Fairness test (section 2.9): twins, path lengths within 1 %, the distance table within +-4 m, `home_seat_of` sample points, lairs per team | `tests/test_20_c5.gd` | Prints `FAIRNESS OK` with the measured table; fails on any twin missing or > 1 % path gap |
| 20.C6 | systems-coder [conditional] | Quadrant nav regions (rebake only the touched quadrant) when a 2v2 rebake > 1.5 s | `scripts/buildings/build_grid.gd`, `main.gd` | Rebake of one quadrant <= 0.6 s; units path across quadrant seams (test); 1v1 unchanged (one region) |
| 20.C7 | systems-coder + gameplay-coder | Perf pass to the gate (3.2): shared unit grid for RiverSystem / CapturePoints / CampManager / critters, idle-unit think staggering, fog stamps per side; the fallback ladder knobs (`pop_cap_scale`, Magpies) | `scripts/world/*`, `scripts/units/unit.gd` | `perf_test.gd -- map=2v2 units=300` `PERF OK` <= 15 ms (quiet PC), stress 400 <= 22 ms, stuck 0; 1v1 perf not slower |
| 20.C8 | systems-coder [only if Q4 = Tribute] | Tribute (4.3) + bot answer hook | `skirmish.gd`, economy banks | Test: 100 crystals sent, 90 arrive, 30 s cooldown; refused to an out seat |
| 20.V1 | tech-artist | Map edge for 168 m: `build_env.gd` parameterised (`MAP_HALF` 84, mouths at x = 0: the north waterfall notch, the south gorge), `map_cliffs_2v2.res`, `map_plateau_2v2.res`, river-mouth meshes, `map_dressing_2v2.tscn` | `art/environment/build_env.gd`, `art/environment/meshes/`, `river_mouths/` | The 1v1 files are byte-identical after a 1v1 rebuild; the 2v2 ring closes round +-84 with both mouths on the river; no collider / navmesh effect |
| 20.V2 | tech-artist | Horizon re-bake for 168 m (`horizon_2v2.tscn`, reads the 2v2 plateau) | `art/environment/horizon/` | Seamless at zoom 40-55 at all 4 corners; 8 meshes, one material, no shadows |
| 20.V3 | tech-artist | Ground: `ground.gdshader` + `GroundParams` + `BiomeMap` for 4 hubs, 2 lanes, 5 spots, 16 ruins, midline woods, heath edge 68; `GroundParams.fourfold_biomes()`; 1v1 uniforms unchanged | `art/environment/ground.gdshader`, `ground_params.gd`, `biomes/biome_map.gd` | 2v2 biomes as 2.10 on a screenshot; 1v1 looks identical (screenshot diff); `BiomeMap` CPU mirror matches the shader at 20 sample points |
| 20.V4 | tech-artist | `MapDressingArt`: `MapInfo` size, chunks 3 x 3 of `map_size / 3`, reads the 2v2 spot tables; decor count and draw nodes | `art/environment/map_dressing_art.gd`, `biomes/*` | 2v2: <= 12 000 instances, <= 140 draw nodes (test_map_p1 style check), no decor on roads / slots / crossings; 1v1 counts unchanged |
| 20.V5 | tech-artist | River dressing for the straight arms: sand bars, bank rocks, reed beds, fallen logs that break the line (draw-only), the aqueducts over both mouths and the 2 barges re-placed | `art/environment/water/`, `landmarks/` placements via the level table | From zoom 55 the arms do not read as a canal (lead eye check); 0 colliders added |
| 20.V6 | tech-artist | Lobby map preview (top-down render 512 x 512, seat corners marked) for 20.D2 | `art/ui/maps/fourfold_hollow.png` | Matches the built map |
| 20.L2 | lead | Integration: glue, CI (1v1 suite), 2v2 smoke with 4 bots, fairness + perf gates, `bake_ms`, playtest build | `tests/`, `docs/plan/` | All gates green; playtest copy updated |
Playtest (user): a 2v2 as Fire with a Nature ally vs Shadow + Ice, normal: take your natural, hold Millstone Bridge, capture
your Millwatch, fight for the crown at 6:00 with your ally, lose your wizard once, then let the ally carry after your base falls.

## 8. Story Episode 2 hooks (the 2v1 -> 2v2 turn)
- `Skirmish2v2` must run with **3 seats** (`Teams.configure({PLAYER: 0, ENEMY: 1, ENEMY_2: 1})`): the unused quadrant is empty
  land (its nodes and posts stay; no keep), for "The Burning Grove" (2v1).
- `activate_seat(seat, kingdom, start_state: Dictionary)`: a seat joins mid-match (keep at its frame, workers, a scripted
  army), fog merges into its side at once: "Roots and Embers" (the war becomes 2v2). `Commander` for that seat with
  `ally_of_human = true` (`ai-2v2.md` 11).
- Scripted seats: a mission may mark a seat `scripted` (no Commander; mission orders only), or give the ALLY seat to a hero
  like Old Vey without a base (a seat with no buildings is not "out" while `scripted`).
- Missions keep `trade_enabled` / `river_enabled` / ... flags; a mission may use one half of the map (camera bounds and
  `MapInfo.set_size` per mission).

## 9. What changes in other specs
- `CLAUDE.md` (20.L1): Teams / sides, `MapInfo`, the seat API, the 2v2 rules line next to "1v1 rules".
- `skirmish-1v1.md`: note that the rules are now written per seat; the 1v1 is the 2-seat case (no behaviour change).
- `ai-2v2.md`: seat numbers 2 / 3 = `ALLY` (3) / `ENEMY_2` (4); `for_seat` = `for_team`; the defeat rule, pop cap and seat API
  are those of sections 3-5; one Crown Isle; home seats -1 at the isle, fords, rich pairs.
- `ui-2v2.md`: its team model (14.1 point 1) is the frozen one; `slot_info`, `team_state`, `map_bounds` and the other level
  hooks are in section 5; `MAP_2V2_NAME = "Fourfold Hollow"`; the map is square (168 m), 1.31 px/m on the minimap.
- `map-fill.md` / `market-trade.md` / `grand-market.md`: a line pointing to 2.8 for the 2v2 counts (no 1v1 change).
- `walls.md` / `building-levels.md` / `rush-balance.md`: slots and rings reach 2v2 seats through `seat_frame` (reflections allowed).

## 10. Questions for the user (recommendation first)
1. **Map layout?** (a) **Fourfold Hollow** (recommended): a square about twice Crown Hollow, one base in each corner, your
   ally on your side of the river, one Crown Isle in the middle for all four wizards, every corner identical (fair).
   (b) Two Crown Hollows side by side: two crowns, but one player of each team sits in the middle and fights both enemies.
   (c) Allies in opposite corners (4-player "free for all" style): you and your ally never share a border.
2. **If your kingdom falls but your ally still fights?** (a) **You keep watching with your team's vision and still win if
   your ally wins** (recommended) (b) The match ends as a defeat for you at once. (Either way a team loses only when both
   kingdoms are out, and a kingdom is out when it has no building left, like the 1v1.)
3. **Army size in 2v2?** (a) **The same as the 1v1** (40 population, Nature 50) with a speed check; if big fights drop
   below 60 fps, armies shrink by 15 % automatically and you are told (recommended) (b) Smaller from the start (30 / 38):
   always smooth, smaller battles (c) Bigger (50 / 62): huge battles, may stutter.
4. **Helping your ally with resources?** (a) **No gifts** (recommended for the first version: each kingdom manages its own,
   the ally bot is balanced for it) (b) A Tribute button: send 100 crystals / 50 gold / 50 essence (10 % lost on the way),
   and the ally bot sends some back when it is rich (c) One shared pool per team.

## Done when
- [ ] 20.L1: `Teams`, `MapInfo`, the appended enum and the contracts are in `CLAUDE.md`; the 1v1 suite is unchanged.
- [ ] 20.C1-20.C3: allies never hurt each other and friendly effects reach them; fog, points, banks and victory work per
      side; economies, orders and stats per seat; a 3- and a 4-seat config run headless; every 1v1 test still passes.
- [ ] 20.C4 / 20.C5: Fourfold Hollow builds as section 2 (168 m, 10 crossings, 8 posts, 10 points, 12 camps, 8 lairs, one
      crown with 6 wardens), 4 seats start as the 1v1, `FAIRNESS OK` (twins, paths within 1 %, distances of 2.9).
- [ ] 20.C7: the 2v2 perf gate passes (300 units <= 15 ms, 400 <= 22 ms, stuck 0) or the fallback ladder is applied and logged.
- [ ] 20.V1-20.V6: the map edge, horizon, ground, decor and river dressing fit the 168 m square; the 1v1 look is unchanged.
- [ ] 20.L2: a 2v2 with 4 bots ends with a winner and 0 script errors; the playtest build has the 2v2 map in the lobby (20.D2).

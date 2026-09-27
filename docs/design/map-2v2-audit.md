# 2v2 map audit: content per player, travel times, contested ground, fixes

2026-09-27, map designer / analyst (World Forge owner for `data/maps/`). User request (JS): "see if map 2v2 lacks things to do
or if 2x all of map one was enough, compute how fast to get to each objective and balance that way".
Maps: **Fourfold Hollow** (FH, built layout `data/maps/fourfold_hollow.map`), the two recommended 2v2 concepts of
`new-maps.md` 4.3 / 4.4 built from their draft specs (**Kinhearth Vale** KV `data/maps/kinhearth_vale.map`, **Gloamspine
Divide** GD `data/maps/gloamspine_divide.map`), against **Crown Hollow** (CH, 1v1, `crown_hollow.map` = the live map's navmesh).

## 0. Verdict (short)
- **Economy and services: 2x is enough.** Nodes, trading posts, taverns, peddlers are exactly 2x CH per team or more
  (FH gives 6 crystal sites per player vs 4 in the 1v1).
- **Mid-game objectives: the 2v2 lacks things to do.** Per player the 2v2 maps had **62 % of CH's capture points, 62-75 % of
  its camps (half its T2 camps), 50 % of its beast lairs** and one crown for four wizards.
- **The real gap is contested ground, not counts.** In CH, 13 of 49 objectives are reached by both players within 15 % of each
  other (19 within 0.75-1.33x): **6.5 contested objectives per player**. Every 2v2 map had **3 contested spots for 4 players**
  (the crown + the 2 ford nests): 0.75 per player. The fourfold layout gives each seat a private quadrant; the only ground
  both teams reach equally is the river line. "2x the 1v1" doubled the content but not the places to fight over.
- **Travel fairness between equivalent seats is exact** (map geometry, all 3 maps: max spread 0.67 %, target 5 %). The only
  seat differences come from the engine's polygon A* (NavigationServer paths up to ~13 % apart on the long diagonals), which is
  not a map fix (4.2 item 4).
- **Fixes applied** (all 3 specs): one river watchtower + one river T2 camp per seat (+4 points, +4 camps per map), placed by
  travel time so the facing enemy reaches them in 1.27-1.32x the owner's time (the 1v1's "raidable" band; KV 1.35-1.43x, see 4.2 item 5). FH: points 10 -> 14,
  camps 12 -> 16 (= 2x CH), contested + raidable spots 3 -> 11. Map Lab FH **97 -> 97** (same lab version), symmetry M1-M4 / F1
  PASS before and after.

## 1. Method
- **Content**: World Forge `L4` counts of each built layout (`docs/tools/world_forge/out/<map>/report_map.md`), split per
  team / per player; spots on an axis are shared (midline = the 2 allies, river line = 2 facing enemies, crown = all 4).
- **Travel**: new headless tool `tools/world_forge/travel_times.gd` (reads the World Forge preview of a map: the baked preview
  navmesh, or CH's live navmesh). It rasterises the navmesh with the Map Lab grid (0.5 m), runs a **16-neighbour Dijkstra**
  (straight-line error <= 2.7 %, exactly mirror-invariant) from **every walkable cell on each keep's rim** (units leave by any
  face; a single "nearest face" point is a tie that is not mirror-invariant and faked 10-70 % seat gaps in a first run), to
  every walkable cell within 1 m of each spot's nearest navmesh point; ford cells cost x1.54 (ford slow -35 %). Times: soldier
  **5.0 m/s** (Flame Guard, `data/units/flame_guard.tres`), worker **4.6 m/s** (Cinder Hand / Rime Hauler / Sprigling / Gloom
  Thrall). The NavigationServer path (what units walk today) is listed next to it (`nav`). Rows are grouped by the target's
  image in the A1 frame, so the 4 seats' numbers for "the same objective" sit on one row. Distances are **from the keep's rim**
  (the Map Lab measures from one keep face: its numbers are ~3-5 m longer).
  Run: `& .\tools\godot_run.ps1 --headless --path . -s res://tools/world_forge/travel_times.gd --fixed-fps 60 --quit-after 30000 '--' map=<id> out=<dir>`
  (~30-45 s; run `run_world_forge.ps1 map <id>` first). Output `<id>_travel.md` + `.json`: full table + "Contest per spot".
- **Contest**: per spot, the nearest seat of each side; ratio = side-0 time / side-1 time. **Contested** 0.87-1.15 (within
  15 %), **raidable** 0.75-1.33 (the enemy needs at most a third more time).
- Seats: A1 = player (team 0), A2 = ally (3), B1 = diagonal enemy (1), B2 = facing enemy (4, across the south river arm).

## 2. Content audit

### 2.1 Whole map
| Content | CH 1v1 | **2 x CH** | FH before | **FH after** | KV draft | KV after | GD draft | GD after |
|---|---|---|---|---|---|---|---|---|
| Crystal sites (home + expansions) | 8 (4 + 4) | 16 (8 + 8) | **24** (8 + 16) | 24 | 16 (8 + 8) | 16 | 20 (8 + 12) | 20 |
| Capture points (towers / wells / shrines) | 8 (4/2/2) | 16 (8/4/4) | **10** (4/4/2) | **14** (8/4/2) | 10 (4/4/2) | 14 | 10 (4/4/2) | 14 |
| Camps (T1 / T2 / T3) | 8 (2/4/2) | 16 (4/8/4) | **12** (4/4/4) | **16** (4/8/4) | 10 (4/2/4) | 14 (4/6/4) | 12 (4/4/4) | 16 (4/8/4) |
| Epic-beast lairs | 8 | 16 | **8** | 8 | 8 | 8 | 8 | 8 |
| Taverns | 2 | 4 | 4 | 4 | 4 | 4 | 4 | 4 |
| Trading posts | 4 | 8 | 8 | 8 | 8 | 8 | 8 | 8 |
| Peddlers | 2 | 4 | 4 | 4 | 4 | 4 | 4 | 4 |
| Guild houses (Den + Lodge) | 4 | 8 | 4 | 4 | 4 | 4 | 4 | 4 |
| Lost Caches | 4 | 8 | 6 | 6 | 6 | 6 | 4 | 4 |
| Ember Crown | 1 | 2 | 1 | 1 | 1 | 1 | 1 | 1 |
| River crossings | 8 | 16 | 10 | 10 | 6 | 6 | 8 | 8 |
| **Contested spots** (sides within 15 %) | **13** | 26 | **3** | 3 | 3 | 3 | 3 | 3 |
| **Contested + raidable** (0.75-1.33x) | **19** | 38 | **3** | **11** | 7 | 8 | 3 | **11** |

### 2.2 Per player (1v1: per side; 2v2: own + half of the team midline + quarter of the crown, half of each river spot)
| Per player | CH | FH before | FH after | KV after | GD after |
|---|---|---|---|---|---|
| Crystal sites | 4 | **6** | 6 | 4 | 5 |
| Capture points | 4 | **2.5** | 3.5 | 3.5 | 3.5 |
| Camps / of which T2 | 4 / 2 | **3 / 1** | 4 / 2 | 3.5 / 1.5 | 4 / 2 |
| Beast lairs | 4 | **2** | 2 | 2 | 2 |
| Crown share | 1/2 | **1/4** | 1/4 | 1/4 | 1/4 |
| Contested + raidable objectives | **9.5** | **0.75** | 2.75 | 2 | 2.75 |

**Where 2x is enough**: crystal (FH is above: the Glade Vein + Millrace pair), trade posts, taverns, peddlers, caches (6 vs 8
is fine: caches are one-shot). Guild houses one per team on the midline is a deliberate choice (shared services) and fine.
**Where the 2v2 lacks**: capture points (towers especially: 1 per seat vs 2), T2 camps (the 1v1's nest + hollow per side became
half a nest + half a hollow per seat), beast lairs (engine cap `EpicBeasts.MAX_ALIVE` 8: a spec cannot fix it, see 4.2),
the crown (one for four, 17 s away), and above all **contested mid-game objectives per player** (0.75 vs 9.5).
Why: CH puts its keeps on a diagonal, so the two side corners (rich nodes, hollows, guilds, tavern, peddler) are equidistant.
In a fourfold map the only line equidistant from both teams is `x = 0`, the river: every spot off it belongs to one team.
Contested ground per player has to be built on the river line (fixes in 4.1).

## 3. Travel times (A1 view; every seat's own-frame number within 0.65 %, so one column stands for all 4)
Soldier 5.0 m/s / worker 4.6 m/s, from the keep's rim. `nav` = the NavigationServer range across the 4 seats (engine).

### 3.1 Own objectives
| Objective | CH m (soldier s) | FH m (s) | KV m (s) | GD m (s) |
|---|---|---|---|---|
| Home nodes (worker s) | 2-2.5 (0.5) | 4.0 (0.9) | 4.0 (0.9) | 4.0 (0.9) |
| Natural expansion (worker s) | 37.4 (8.1) | 39.3 (8.6) | 26.6 (5.8) | 39.3 (8.6) |
| Second / third expansion | - | glade 41.5, millrace 51.8 | - | glade 41.5 |
| Rich node (worker s) | 76.1 (16.5) **contested** | 47.0 (10.2) safe | 54.0 (11.7) safe | 43.0 (9.3) safe |
| T1 camp | 26.1 (5.2) | 23.1 (4.6) | 38.2 (7.6) | 18.2 (3.6) |
| T3 stag | 48.4 (9.7) | 48.2 (9.6) | 46.2 (9.2) | 48.2 (9.6) |
| T2 camps | nest 48.6 (9.7), hollow 94.7 (18.9) | gloomcap 63.6 (12.7, midline), ford nest 67.1 (13.4), **bridge nest 56.0 (11.2) new** | ford nest 65.4 (13.1), **bridge nest 64.0 (12.8) new** | hollow 61.0 (12.2), ford nest 63.1 (12.6), **bridge nest 52.0 (10.4) new** |
| Towers | 29.5 (5.9), 79.6 (15.9) | 55.1 (11.0), **fordwatch 61.3 (12.3) new** | 56.4 (11.3), **fordwatch 54.0 (10.8) new** | 50.7 (10.1), **fordwatch 56.9 (11.4) new** |
| Well / shrine | 61.8 (12.4) / 47.8 (9.6) | 53.3 (10.7) / 68.5 (13.7) | 29.0 (5.8) / 40.3 (8.1) | 55.3 (11.1) / 57.7 (11.5) |
| Tavern | 55.0 (11.0) | 64.1 (12.8) | 39.6 (7.9) | 52.8 (10.6) |
| Trading posts | 34.4, 34.4 (6.9) | 38.2, 38.2 (7.6) | 25.1, 51.0 (5.0, 10.2) | 28.7, 28.7 (5.7) |
| Peddler | 62.2 (12.4) | 33.6 (6.7) | 32.1 (6.4) | 30.1 (6.0) |
| Beast lairs | 26.2, 57.2, 73.9, 94.8 | 22.7, 54.1 | 43.2, 71.4 | 18.3, 47.1 |
| **Crown** | **53.7 (10.7)** | **86.3 (17.3)** | 68.9 (13.8) | 80.6 (16.1) |

### 3.2 Keeps
| From A1 to | CH | FH | KV | GD |
|---|---|---|---|---|
| **Ally keep** m (soldier s) | - | **123.5 (24.7)** | **51.5 (10.3)** | 115.5 (23.1) (via a gate) |
| Facing enemy keep (B2) | 111.8 (22.4) | 124.0 (24.8) | 132.4 (26.5) | 116.0 (23.2) |
| Diagonal enemy keep (B1) | - | 176.2 (35.2) | 140.2 (28.0) | 164.9 (33.0) |
| Ally / facing enemy | - | **1.00** | **0.39** | 1.00 |
| nav (engine) facing / diagonal | 116 | 128-136 / 182-207 | 132-155 / 143-161 | 120-139 / 169-175 |

Full tables (every spot x every seat, soldier and worker seconds, `nav` range, contest ratios):
`docs/tools/world_forge/out/<map>/travel_times.md` (+ `.json`) for crown_hollow, fourfold_hollow, kinhearth_vale and
gloamspine_divide (after the fixes); regenerate with the tool (1.).

### 3.3 Fairness metrics
| Metric | CH | FH | KV | GD | Target |
|---|---|---|---|---|---|
| Max spread between equivalent seats, any objective (geometry) | 0.0 % | **0.59 %** | 0.65 % | 0.67 % | <= 5 % |
| Team vs team (sum of own-objective times) | equal | equal | equal | equal | equal |
| Engine path spread (NavigationServer), worst row | ~1 % | 13 % (keep -> diagonal keep 182-207 m) | 27 % (diagonal corner post 180-228 m) | 11 % | Map Lab F2 |
| Map Lab T1 (unit paths per seat, within 3 s) | - | WARN: caravan to the diagonal keep 0:45 vs 0:48 | PASS | WARN: worker to the facing keep 0:27 vs 0:30 | engine |
| Ally keep time / facing enemy time | - | 1.00 | 0.39 | 1.00 | < 0.8 for "help in time" |

All equivalent seats are within 5 % by construction: the three specs are exact fourfold mirrors and the navmesh mirrors to
0.00 % (Map Lab M3). What is not equal is what units really walk: Godot's polygon A* on a non-mirrored triangulation (Map Lab
F2 / T1 / D1 WARN rows). Those are engine noise, not spot positions.

## 4. Fixes

### 4.1 Applied (`.map` specs only)
Rule: a per-seat objective on its own river bank, next to the crossing the facing enemy uses, so the enemy reaches it in
1.25-1.35x the owner's time (CH's raidable band: its wells 0.86 / 1.17, far towers 0.76 / 1.31, hollow lairs 0.76 / 1.32).
Every line is written once in the canonical quadrant; World Forge places the 4 images. Final positions (after 2 nudges, below):
| Map | Added (canonical A1) | Owner (A1) | Facing enemy (B2) | Ratio | Clearances |
|---|---|---|---|---|---|
| FH | `point fordwatch at=(-8,31) sub=watchtower` (sees Willow Ford + the SW Crown Bridge) | 61.3 m / 12.3 s | 80.6 m / 16.1 s | **0.76** | 5.5 m from the bank, 16 m off the lane, 9.4 m from Millrace, 12 m from the ford nest |
| FH | `camp bridge_nest at=(-5,63) tier=2` (the Millstone Bridge approach) | 56.0 m / 11.2 s | 71.2 m / 14.2 s | **0.79** | 9 m from the ring road, 9.1 m from the rich node, 11.4 m from Millwatch, 2.5 m from the bank (like the ford nests) |
| KV | `point fordwatch at=(-9,33)`, `camp bridge_nest at=(-6,64) tier=2` | 54.0 / 64.0 m | 77.0 / 86.3 m | 0.70 / 0.74 | the wider river (half width 3) and the 10 m bridge add detour: just under the band (4.2 item 5) |
| GD | `point fordwatch at=(-8,29)`, `camp bridge_nest at=(-5,58) tier=2` | 56.9 / 52.0 m | 73.7 / 68.2 m | **0.77 / 0.76** | clear of the spine blocks and the lane |
Iterations: towers first at FH `(-6,28)` / KV `(-7,30)` / GD `(-6,26)` (0.78, but 3.5-4 m from the water: capture ring over the
river), then 3 m west (FH 0.74: out of the band), then 2-3 m toward the ford (final). Camps unchanged.
Result FH: capture points 10 -> 14 (per player 2.5 -> 3.5, two towers per seat like the 1v1), camps 12 -> 16 (**= 2x CH**, T2
per player 1 -> 2 like the 1v1), contested + raidable spots 3 -> 11 (0.75 -> 2.75 per player). Each player now has a tower
and a T2 camp on the river that the facing enemy can take from him: early mid-game (3-6 min) fights per lane, not only at the crown.

**Map Lab proof (Fourfold Hollow, `run_world_forge.ps1 map fourfold_hollow`)**. The Map Lab gained checks A1 / T1 today (lab
v1.0 + travel rows), so "before" was re-run on the unchanged spec with the same lab:
| Run | Score | FAIL / WARN checks | M1 / M2 / M3 / M4 / F1 | F2 pairs within 2 % | D1 / A1 / C1 / C2 | World Forge |
|---|---|---|---|---|---|---|
| Before, 08:10 (lab without A1 / T1) | 98 | 0 / 1 (F2) | PASS (95 spots) | 6316 / 6693 (94.4 %) | PASS | PASS 100 |
| Before, 14:48 (same spec, current lab) | **97** | 0 / 2 (F2, T1) | PASS (95 spots), F1 6693 / 6693 | 6316 / 6693 (94.4 %) | PASS | PASS 100 |
| **After, 15:40 (final spec)** | **97** | 0 / 2 (F2, T1) | **PASS (103 spots)**, F1 7875 / 7875 | 7441 / 7875 (94.5 %) | PASS | PASS 100 |
The T1 WARN (caravan to the diagonal keep 0:45 vs 0:48) is keep-to-keep and identical before and after (the new spots are
markers, not obstacles: the same 235 navmesh polygons / 27 073 m² before and after). KV after: Map Lab 90 (F1 1 WARN on
`corner_post`, F2, D1; T1 / A1 PASS), GD after: 92 (N3 spine-block tops, F2, D1, T1): the same WARN rows as their drafts
(KV draft 89, GD draft 93, both on the lab without A1 / T1), none on a new spot.

### 4.2 Proposed (not applied: engine, design or scene owners)
1. **Beast lairs** (lead + systems-coder): 8 lairs for 4 players is 2 per seat vs 4 in the 1v1, and `EpicBeasts.MAX_ALIVE` 8
   is already the whole map. If the 2v2 perf gate allows, `MAX_ALIVE` 12 on 2v2 maps + a third lair per seat on the heath
   (FH: a lair on the ally midline would be shared, not per seat). Otherwise shorter lair respawns in 2v2.
2. **Crown**: 86 m / 17 s from every FH keep (CH 54 m / 11 s), shared by 4. Keep it (a 2v2 crown fight should be a team
   decision), but its first spawn could come 1 min later than the 1v1 so the new river objectives come first.
3. **Ally distance** (FH, GD): the ally is as far as the facing enemy (123.5 vs 124.0 m, 25 s): an ally cannot reinforce before
   a rush lands (the Map Lab A1 rule "ally <= 1.25x enemy" passes at 0.91, but for "help in time" the ratio should be < 0.8).
   FH is a built design (district reused through `seat_frame`), so this is a map-choice fact, not a fix: **KV is the team-play
   map** (ally 51.5 m / 10 s, 0.39). Say it in the lobby hook lines.
4. **Engine path noise** (lead / systems-coder, Map Lab backlog): a finer bake (`edge_max_length`, `region_min_size`) or a
   string-pulling pass; worst FH rows keep -> diagonal keep 182-207 m (13 %), KV corner post 180-228 m (27 %).
5. **KV Map Lab 90**: the one F1 WARN (`corner_post` 39.8 vs 40.8 m, 2.4 %) is 1 m of grid alignment on a short route; D1 post
   2.2 % is engine noise. Before NM.F adoption, try `corner_post` 1 m inward and re-run; and move KV `fordwatch` /
   `bridge_nest` ~2 m nearer their crossings (0.70 / 0.74 -> ~0.76, inside the raidable band) if the bank clearance allows.
6. **GD**: the N3 islands are the tops of the spine blocks (box obstacles, 3 m high): the adopter's crag colliders must be
   unwalkable on top (or the islands are INFO once they are raised above the ground band).
7. **Scene adoption** (systems-coder, NM.C1 / 20.C4): the 2 new spots per seat on FH exist only in the spec; `skirmish_2v2`
   tables and `map-2v2.md` 2.8 counts (10 points / 12 camps) need the same 2 rows (map-2v2.md 2.4 "level" table) when the lead
   accepts this audit. Camp kind for `bridge_nest`: a Mirefang nest (T2, like the ford nests); tower = a Millwatch copy.

## 5. Files
- Specs changed: `data/maps/fourfold_hollow.map` (+2 lines), new `data/maps/kinhearth_vale.map`, `data/maps/gloamspine_divide.map`
  (new-maps.md 4.3 / 4.4 drafts + the 4.1 fixes; `terrain=` / `kind=` proposal keys left out, the zones keep `biome=`);
  rebuilt layouts `data/maps/*_layout.tres`, reports `docs/tools/world_forge/out/<map>/` (+ `travel_times.md` / `.json`).
- Tool: `tools/world_forge/travel_times.gd` (headless, reads a World Forge preview; no game code or scene touched). The Map
  Lab's new T1 table (keep -> 7 destinations, unit paths) and this tool agree to +-3-5 m (keep rim vs one keep face); the tool
  adds every spot, the 4-seat grouping in one frame and the contest ratios.

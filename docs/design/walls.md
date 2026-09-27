# City walls: the keep's city ring, player-built walls, gates, repair and one twist per kingdom

Task 18b.D1, written 2026-09-26, **revised the same day** around the user's direction (relayed by the lead): the **main city
(the keep) gets its walls per keep level**: each keep level-up (Stronghold, Citadel) grows the city wall **automatically**,
and at level 3 the city gets a **free "great wall"** that encloses every building close to the keep. The first request
(`docs/plan/waves.md`, "Step 18b") still applies where it fits: workers build wall segments (drag a line) and gates (own units
pass, enemies don't; open / lock toggle), corner towers that grow, repair, one look and one twist per kingdom, rushes safe,
navmesh rebake, siege bonuses, wood -> stone -> enchanted, the bot, art per kingdom per level.
**User answers (2026-09-26, folded in below):** Q1 twists = the recommended base set; Q2 the Stronghold gives **free defenders**
(towers or workers), **not** half a wall; the Citadel still gives the free Great Wall; Q3 player-built walls from 3:30; Q4 gates are
**real doors** (enemies can slip in behind your units while a gate is open).
Every name, rule and number here is our own. Metres, seconds, `m:ss` since the navmesh was ready. Built on the real code
(`scripts/buildings/build_grid.gd`, `building.gd`, `building_type.gd`, `scripts/world/main.gd` nav region, `scripts/units/unit.gd`,
`data/buildings/ice_wall.tres`) and on `buildings.md` (grid, placement), `building-levels.md` ("bl.": keep tiers = keep levels,
`team_tier`, key L), `worker-improvements.md` ("wi.": `command_repair`, worker Auto), `rush-balance.md` ("rb."), `research.md`
("rs.": Stronghold 200 / 60 s, Citadel 300 / 90 s, Packed-Ice Walls, Ossuary Walls, veil), `cavalry-mounts.md` / `titans-2.md`,
`kingdom-ice.md` (the Ice Wall), `map-fill.md`, `market-trade.md` (ring road), `skirmish-1v1.md` (keeps at `(-43, 43)` / `(43, -43)`),
`ai.md`. **Build with or after step 18.**

## 0. The idea in eight lines
1. The **main keep owns a city ring**: a closed loop of wall cells around every own building near the keep (2.2), with
   **gatehouse spots** where the roads and exits leave (2.3). Expansions stay outside.
2. **Keep (level 1)**: the ring is only **surveyed** (stakes on the ground, no collider): **nothing free before the Stronghold**.
3. **Stronghold (level 2)**: **free defenders, no free wall**: the player picks **Watch** (2 free gate towers on the survey) or
   **Hands** (3 free workers) (2.7). The ring stays survey; the player may pay for segments and gates on it.
4. **Citadel (level 3)**: the **Great Wall**: the whole ring closes for free, enchanted, with gatehouses at every exit and corner
   towers on every corner; all breaches are restored.
5. **Every wall levels with the keep** (free, at the tier-up): wood -> stone -> enchanted. There is no per-piece upgrade.
6. **Player-built walls stay as an optional extra** (from 3:30, paid, capped): close the ring's gaps early, wall an expansion or a
   choke. Pieces placed on the survey become part of the ring.
7. Gates are **real doors**: they swing open for your moving units and close behind them; while open **anyone** can slip through.
   **Lock** keeps a door shut, **Hold open** keeps it open. Siege x1.5, titans x2; one breach (or one open door) is enough.
8. Twists: **Fire Searing** (burns melee attackers), **Ice Frostbind** (early forward Ice Walls, chills), **Nature Regrowth**
   (cut hedges grow back), **Shadow Gloomward** (hides own units near the wall).

## 1. Decisions in one table (designer decisions; the user's questions are at the end)
| Question | Decision | Why |
|---|---|---|
| Who gets the ring | The team's **main keep** (the starting keep) only. Expansion halls never get a ring | "The main city" (user); expansions are the risk you take |
| What each keep level gives | L1: survey only. L2: **a free reward, the owner's choice**: **Watch** = 2 gate towers (L2 corner towers) beside the main gatehouse spot, or **Hands** = 3 workers (2.7); the ring stays survey. L3: the full Great Wall + gatehouses + corner towers on every corner + restore | User answer Q2 ("give free tower or worker"); "nothing free before the Stronghold" keeps rushes intact |
| Cost | The Great Wall raised by the Citadel is **free** (the price is the keep upgrade, rs. 300). Before it, the ring is paid piece by piece by the player (section 4). Rebuilding a breached ring piece costs 25 % of its value | User: "a FREE great wall" |
| Ring shape | Inflated convex hull of the own buildings and home crystal nodes within **22 m** of the keep, margin **4 m**, radius **14-26 m**, <= **72 cells**, rasterised on the 2 m grid (2.2) | Automatic, readable, same code for the bot |
| Gates | Where the team's paths to the enemy keep, its nodes outside the ring, its expansions, its Bazaar route and its Hall rallies cross the ring: **2-4 gatehouses** | "Gates where roads and exits leave" |
| Later buildings | A new own building completed within 22 m but outside the ring **bulges the ring** out (after the Citadel: raised free; cooldown 30 s) | "Buildings near the keep are automatically inside" |
| Levels | **All** own wall pieces (ring and player-built) take the keep's level at each tier-up, free. New player pieces are placed at the current level and pay for it | Folds "how do walls level up" into the keep rule |
| Player-built walls | **Kept** (user answer Q3): segments (cap **24**, Ice 32 with research; pieces on the survey are uncapped) and gates (cap **2**; gates on survey gatehouse spots are uncapped), from **3:30** (Ice segments from 0:00, 16 max before 3:30). **No player-built towers** (towers come from the Stronghold's Watch and the Great Wall) | The only way to wall the city before the Citadel, plus expansions and chokes; Ice keeps its existing tool |
| Armour | **Fortification** (share of normal damage that gets through): L1 **60 %**, L2 **45 %**, L3 **35 %**; siege x1.5, titans x2.0 (cap x3.0), spells x1.0 | Walls buy time; siege is the answer |
| HP | Segment base (Fire / Shadow) **420**, x2 at L2, x3 at L3; Ice x1.2 (**500 = today's Ice Wall**), Nature x0.9 | Wood -> stone -> enchanted is a material change |
| Gates | **Real doors** (user answer Q4). **Auto** (default): the door opens for own **moving** ground units within 4 m and closes 2 s after none is near and the doorway is clear; while open **anyone** passes (enemies slip in). **Locked** (Z): never opens, damage x0.75. **Hold open** (X): stays open for everyone | A door you must watch: sallies and supply runs have a price; lock it during a siege |
| Defeat | Wall pieces never count for defeat | A side with only walls left loses |
| Missions | `Skirmish.walls_enabled` true in the skirmish, **false** in missions 1-4 (no ring; Ice keeps its legacy Ice Wall) | Smoke test unchanged |
| Flyers | Ignore walls | They ignore the navmesh (cm. 1) |

## 2. The city ring
### 2.1 What each keep level gives
| Keep level | When (normal) | City ring | Look (all kingdoms) |
|---|---|---|---|
| **1 Keep** | 0:00 | **Survey only**: the planned ring shown as stakes and a faint chalk line (ground decal, **no collider, no nav effect**); gate spots marked with two taller stakes. Own team sees it always; the enemy where visible. Player-built pieces on survey cells become **ring pieces** (4.4) | Surveyor's stakes with kingdom-coloured flags |
| **2 Stronghold** | ~7:00 (research off 6:00) | **No free wall.** The owner picks the **Stronghold reward** (2.7): **Watch** (2 free L2 gate towers) or **Hands** (3 free workers). The ring stays survey; every own wall piece (player-built) turns stone. Segments and gates on the survey stay the player's to pay (section 4) | Survey + whatever the player built, now stone; Watch towers beside the main gatehouse spot |
| **3 Citadel** | ~12:00 (research off 11:00) | The **Great Wall**: every remaining ring cell raised free at level 3 (enchanted); a **gatehouse** at every gatehouse spot (a player gate standing there becomes that gatehouse); every ring piece, tower and player-built piece rises to level 3, ring pieces at full HP; **corner towers** on every ring corner with a turn >= 35 degrees (**max 6**, the 2 Watch towers included); every breach restored | The closed enchanted ring with its crest and glow |
- A keep that never upgrades keeps only the survey. A **destroyed** main keep: the ring stays as it is (pieces are independent),
  never grows again, survey stakes vanish.
- Research off (`--no-research`): no keep upgrade button (bl. 3.4); the ring rises by `team_tier()` at **6:00** and **11:00**.
### 2.2 How the ring is computed (systems 18b.C4, `CityWall.plan()`)
1. **Members**: the main keep; every own building with `counts_for_defeat` (completed or under construction) whose footprint's
   nearest point is within **22 m** of the keep centre; every **crystal node** whose centre is within 22 m (the home mining line
   stays inside). Never: walls, Roadside Posts, neutral buildings, expansions beyond 22 m.
2. **Hull**: the convex hull of the members' footprint corners (nodes: a 5 m radius, 8 points), **inflated by 4 m** (room to walk
   inside; nodes keep their 4 m clearance), corners chamfered to 45 degrees. Every hull point is clamped to **14-26 m** from the
   keep centre (a lone keep still gets a ring; a sprawling base is cut at 26 m).
3. **Rasterise**: the hull polygon becomes an 8-connected closed loop of 2 m cells (`BuildGrid.line_cells` per edge), thinned so
   every cell has exactly 2 ring neighbours. **Max 72 cells**: if more, drop the farthest member and recompute.
4. **Cells that cannot hold a piece**: water, cliffs / rocks (BuildGrid's obstacle probe), the map's outer edge. Skipped; the
   obstacle seals the ring (neighbour pieces get an end cap). **Map edge**: ring pieces may use the outer cell ring (normally
   unbuildable) so the ring meets the map border without a strip to walk through (the keeps at `(-43, 43)` / `(43, -43)` are ~15 m
   from the buildable edge). Crossings / neutral sites near a base (none on Crown Hollow): the ring is pulled inward to keep the
   8 m / 6 m clearances.
5. **Own buildings on ring cells** (one placed later between 22 and 26 m): the building becomes part of the wall (pieces join it
   with an end cap). **Enemy buildings or sites** on ring cells: skipped (a gap) until they are gone.
6. The plan is recomputed at every keep level-up **start** (the owner sees the ghost of what will rise), at its completion (only
   if members changed), and by the bulge rule (2.5).
### 2.3 Gatehouses (exits)
- **Exit points**: the team's navmesh paths (own layers, walls ignored) from the keep to: the enemy keep, each own crystal node
  outside the ring, each own expansion hall (and the natural X1 slot), the Bazaar's first ring-road segment (trade on), each Hall's
  rally point outside the ring. Where a path crosses the ring = an exit point.
- Exit points within **12 m** of each other merge (their mean). **2 to 4 gatehouses**: more than 4 -> keep the 4 used by the most
  paths; fewer than 2 -> add one on the side opposite the first.
- At each exit the ring is **squared** to 2 axis-aligned cells (the opening, 3.2 m) with a straight cell on each side; diagonal
  stretches bend locally. These are the **gatehouse spots** (two tall stakes on the survey).
- Before the Citadel a spot takes a **player gate** (paid, not counted in the cap of 2); the Citadel turns it into a **gatehouse**
  (free) or raises one on an empty spot. The **main** spot (the exit toward the enemy keep) is where Watch towers stand (2.7).
- Ring gatehouses and gates on spots do **not** count toward the player's 2-gate cap.
### 2.4 The raise moment (Citadel completion; the Watch towers at the Stronghold use the same steps)
| Step | Rule |
|---|---|
| During the upgrade (90 s) | Owner: the pieces that will rise show as ghost outlines; enemy: the survey only. Own message at 10 s left: `The Great Wall rises in 10 s` |
| At completion | Every new ring piece spawns completed (level 3, full HP) and plays `play_raise()` (3 s, stones rising, dust along the ring). **Colliders are on at once** |
| Units on ring cells | Pushed out of the cell: own units **inward**, enemy and neutral units **outward** (nearest free point 1 m beyond); enemies already inside the ring stay inside (they can breach out) |
| Navmesh | **One rebake** for the whole raise (a single `request_rebake()`), coalesced with any pending bake. Budget of 11.1 |
| Existing pieces | Every own wall piece (ring and player-built) takes the new level at once: HP x2 / x3 of base with its HP ratio kept; at L3 ring pieces go to full |
| Messages | Own `The Great Wall is complete!`; enemy (if the keep or the ring is visible) `The enemy raised its Great Wall` |
### 2.5 Buildings placed later, expansions
- **Bulge**: when an own member-eligible building (22 m rule) completes **outside** the current ring, the ring re-plans. Before
  the Citadel only the survey moves (player pieces on the old survey stay where they are and stay uncapped ring pieces). After the Citadel the changed arc's old
  pieces sink (removed, no refund) and the new arc rises free at level 3, one rebake, at most once per **30 s** per team (batched).
  The ring never shrinks when a building dies.
- **Placement guard**: nothing may be placed on a **raised** ring cell (`Blocked`). Survey cells are free to build on (the survey
  moves around the new building at the next plan).
- **Expansions** (halls beyond 22 m) stay outside; they can be walled with player-built pieces (section 4).
### 2.6 Breaches and restore
A destroyed ring piece (a player piece on the survey, or a Great Wall piece) leaves a **breach**: rubble for 3 s, then a breach
stake. Workers can **rebuild** it (right-click the stake or its card): cost **25 %** of its level value (stone segment 9, enchanted
15 crystals), time = its build time at that level (segment 10.5 s at L2, 14 s at L3). The Citadel restores every breach for free
(the Great Wall fills every survey cell). Nature's Regrowth (section 7) closes hedge breaches by itself.
### 2.7 The Stronghold reward: Watch or Hands (user answer Q2)
| Rule | Value |
|---|---|
| When | The Stronghold completes (research off: at 6:00). The keep panel shows a choice chip for **60 s**: **Watch** or **Hands** (buttons, no key; tooltip below). No pick in 60 s = **Watch** |
| **Watch** | 2 free **gate towers** (L2 corner towers of 3.4: 1 260 HP, 12 dmg, range 10) raised on the survey cells beside the **main gatehouse spot** (the exit toward the enemy keep), one on each side, 2 cells from the opening (nearest valid survey cell if blocked). They are ring towers (join the ring, rise to L3 with the Citadel, count among its 6 corner towers). One rebake. `play_raise()` |
| **Hands** | 3 free workers of the kingdom walk out of the keep at once. They use pop like any worker (the ones without pop room wait in the keep, free, and come out as room appears). They can staff buildings (bl. 4.2: pop-free inside) |
| Value | Watch ~240 crystals of towers (2 x the 120 corner-tower value) that defend now; Hands 150 crystals of workers + 36 s of keep time, ~+200 crystals / min of mining once they reach a node, pays back ~2 min later but costs 3 pop |
| Rushes | None: the Stronghold is ~7:00 (hard bot ~5:30), after every rush's raid window (rb. 6.2). Nothing is given at level 1 |
| Step 18 | Skirmish start is still 4 workers (bl. 4.5); Hands gives a Stronghold-time economic push that fits the step-18 staff demand (Forge / Sanctum / Stables crews arrive around then, bl. 4.5) |
| Missions / walls off | `walls_enabled` false: no reward (the Stronghold does what rs. says) |
| Tooltip | `Watch\n2 free gate towers beside your main gate.` · `Hands\n3 free workers.` |

## 3. Pieces and numbers (data: `data/buildings/<id>.tres`, 16 files; `ice_wall.tres` updated)
Kingdom rule of cm. 2.1: Ice +20 % HP and build time, Nature -10 % HP, -15 % build time and a little cheaper. **Value** = what a
player piece costs to place at that level; rebuild / repair percentages refer to it.
### 3.1 Segments (`kind` `&"wall"`, 1 x 1; ring and player-built share the type)
| id | Name | Value L1 / L2 / L3 | Build (L1) | HP L1 / L2 / L3 | Sight | kill_xp | Twist |
|---|---|---|---|---|---|---|---|
| `fire_wall` | Ember Palisade | 20 / 35 / 60 | 7 s | 420 / 840 / 1 260 | 0 | 10 | Searing |
| `shadow_wall` | Dusk Wall | 20 / 35 / 60 | 7 s | 420 / 840 / 1 260 | 0 | 10 | Gloomward |
| `ice_wall` (existing) | Ice Wall | 20 / 35 / 60 | 8 s | **500** / 1 000 / 1 500 | **4 -> 0** | 10 | Frostbind |
| `nature_wall` | Living Hedge | 18 / 33 / 58 | 6 s | 380 / 760 / 1 140 | 0 | 10 | Regrowth |
Visual height <= **2.2 m** (units stay readable behind a wall); collider 1.8 m (11.3). Build time x1.5 at L2, x2 at L3.
### 3.2 Player gates (`kind` `&"gate"`, 2 x 1 along the wall axis, 3.2 m opening; cap 2)
| id | Name | Value L1 / L2 / L3 | Build (L1) | HP L1 / L2 / L3 | Sight | kill_xp |
|---|---|---|---|---|---|---|
| `fire_gate` | Ember Gate | 60 / 100 / 160 | 20 s | 1 050 / 2 100 / 3 150 | 6 | 25 |
| `shadow_gate` | Dusk Gate | 60 / 100 / 160 | 20 s | 1 050 / 2 100 / 3 150 | 6 | 25 |
| `ice_gate` | Rime Gate | 60 / 100 / 160 | 24 s | 1 250 / 2 500 / 3 750 | 6 | 25 |
| `nature_gate` | Thorn Arch | 55 / 95 / 155 | 17 s | 950 / 1 900 / 2 850 | 6 | 25 |
### 3.3 Ring gatehouses (`kind` `&"gatehouse"`, 2 x 1 door + a flanking turret; raised by the Citadel only, L3; value 240)
A gatehouse is a door (section 5) with **1.5x** the L3 gate's HP and a turret that shoots like an L3 corner tower.
| id | Name | HP (L3) | Turret damage (cooldown 1.5) | Range | Sight | kill_xp |
|---|---|---|---|---|---|---|
| `fire_gatehouse` | Ember Gatehouse | 4 725 | 15 | 11 | 14 | 60 |
| `shadow_gatehouse` | Dusk Gatehouse | 4 725 | 15 | 11 | 14 | 60 |
| `ice_gatehouse` | Rime Gatehouse | 5 625 | 12 | 11 | 14 | 60 |
| `nature_gatehouse` | Thorn Gatehouse | 4 275 | 10 | 11 | 14 | 60 |
### 3.4 Corner towers (`kind` `&"wall_tower"`, 1 x 1; ring only: 2 from the Stronghold's Watch, up to 6 at the Citadel; value 120 / 180)
Damage = **80 % / 100 %** of the kingdom's Spire base damage at L2 / L3 ("an L3 corner tower hits like an L1 Spire"). No Garrison fire
(rb. 3.1 stays Spire / keep only). Research that names "towers" applies (Salamander Oil etc.).
| id | Name | HP L2 / L3 | Damage L2 / L3 | Range | Sight | kill_xp | L3 bolt effect |
|---|---|---|---|---|---|---|---|
| `fire_wall_tower` | Brazier Tower | 1 260 / 1 890 | 12 / 15 | 10 / 11 | 13 / 14 | 40 | `burn` 3 / s for 3 s (`apply_dot`, fire) |
| `shadow_wall_tower` | Gloomwatch | 1 260 / 1 890 | 12 / 15 | 10 / 11 | 13 / 14 | 40 | `marked` 3 s (x1.15 damage taken, champions.md 4.3) |
| `ice_wall_tower` | Rimewatch | 1 500 / 2 250 | 10 / 12 | 10 / 11 | 13 / 14 | 40 | `chill` 2 s (the Rime Spire status) |
| `nature_wall_tower` | Thornwatch | 1 140 / 1 710 | 8 / 10 | 10 / 11 | 13 / 14 | 40 | Mends own wall pieces within 8 m by **1 % max HP / s**, even in combat |
Towers and keeps (Spires, keeps, gatehouse turrets, corner towers) **never target wall pieces** (group `"walls"`).

## 4. Player-built walls (the optional extra; systems 18b.C2, ghosts ui 18b.U1)
### 4.1 The Walls page
Workers selected -> **B** -> **V** = **Walls** (r2c1, all kingdoms; for Ice it replaces the direct Ice Wall button): r1c1 **Wall Z**
(V also works: "B, V, V" as today for Ice), r1c2 **Gate X**, r1c4 **Back**. `walls_enabled` false: Ice sees its legacy **Ice Wall V**.
### 4.2 Drag-a-line (segments)
| Step | Rule |
|---|---|
| Aim | One-cell ghost on the 2 m grid; within 1 cell of an own wall end or a **survey cell** it snaps there (the survey glows while the tool is open) |
| Press / drag | Anchor A; the chain A -> B is 8-connected (a diagonal step joins with a diagonal arm, no leak). **Ctrl** = lock to 0 / 45 / 90 degrees. Clipped to the remaining cap (survey cells do not use the cap) |
| Per cell | Green / red with the reason on hover; counter `12 walls · 240 crystals` (+ `· 5 on the city ring`) (+ `· 2 skipped: Blocked`) |
| Release | Places every green cell from A: **one order, one navmesh rebake** (`BuildGrid.place_line`). Not enough crystals: as many as affordable from A (`Not enough crystals: 8 of 12 placed`) |
| Chain / single / cancel | **Shift** on release keeps the tool from B; click = one piece; Esc / right-click cancels the drag, then the tool |
| Builders | `command_build_line(sites)`: each worker takes the nearest unclaimed site, then the next; spare workers join (1 / 1.5 / 2 speed) |
Price and build time follow the current keep level (3.1: 20 / 35 / 60; time x1 / x1.5 / x2). Sites block paths at once (hp 10 %);
cancel refunds 75 %.
### 4.3 Player gates
A 2 x 1 ghost; over two own straight adjacent segments it replaces them (refund **50 %** of their value); free-standing: its axis is
the tangent around the own keep. Diagonal runs cannot take a gate. On a **survey gatehouse spot** it snaps there, is not counted in the
cap of 2, and becomes that spot's gatehouse at the Citadel (free).
### 4.4 Pieces on the city ring
A player segment placed on a **survey cell** is a **ring piece**: it does not count toward the cap of 24, it stays when the ring
rises (no refund; it simply takes the level), and a breach of it is restored free at the next keep level. This is how a player (or a
hard bot) closes the ring before the Citadel: pay for the gaps early.
### 4.5 Refusals (per cell, `BuildGrid.check` order; the first that applies)
Existing: `Outside the map`, `Blocked` (incl. raised ring cells), `Too close to a crystal node` (4 m), `Not on walkable ground`,
`Can't build on water`, `Too close to a crossing` (8 m), `Too close to a monster camp`, `Unexplored`. New, after them:
| Rule | Message |
|---|---|
| `walls_enabled`, match time >= 3:30 (Ice segments: always; **16 max** before 3:30) | `Available at 3:30` (+ countdown) |
| Within **24 m** of an own completed building with `counts_for_defeat` (Ice: own construction sites of such buildings too), or on an own survey cell | `Too far from your buildings` |
| >= **6 m** from trading posts, taverns, guild houses, capture circles, camp spots; >= 3 m from roadside plots | `Too close to a neutral site` |
| Gate: on a straight 2-cell run | `Gates need a straight run` |
| Segment on a survey cell of a gatehouse spot | `Gate spot: build a gate here` |
| Caps (sites and Nature stumps count; ring pieces and spot gates do not) | `Wall limit reached` (existing text) / `Gate limit reached (2)` |
| Crystals | `Not enough crystals` |
### 4.6 Trapped warning
After a placement's rebake, up to **12** own units within 30 m of the new pieces (workers, caravans first) ask for a path to the keep
(own layers). Any `no path`: `Warning: your wall traps 3 units` + a ping (once per placement). Nothing is refused.

## 5. Gates are real doors (player gates and ring gatehouses; systems 18b.C3, gameplay 18b.C7; user answer Q4)
### 5.1 Modes and the open / close rule
| Mode (gate card) | Door | Who passes |
|---|---|---|
| **Auto** (default) | **Opens** (0.6 s swing) when an own ground unit that is **moving** (speed > 0.5 m/s, or waiting at the door link) is within **4 m** of the opening. **Closes** (0.8 s) when no moving own unit has been within 4 m for **2 s** **and** the doorway (the 3.2 x 2 m box) is clear of every unit | Own units whenever they arrive; **anyone** while it is open (enemies slip in behind your workers and armies) |
| **Locked** (**Z**, toggle; Shift+Z = every own gate) | Shut; never opens. If a unit stands in the doorway, the lock waits until it is clear (`Locking...`). Damage taken **x0.75** (barred) | Nobody (own units path around to another door) |
| **Hold open** (**X**, toggle; Shift+X = every own gate) | Open until toggled back to Auto | Anyone |
- **Jammed**: an enemy (or anyone) standing in the doorway keeps an Auto door open: "hold the gate" fights happen there. The panel
  shows `Jammed` in red; a message `Enemies at the Ember Gate!` (once per 20 s). Knob 14.2 if it is abused.
- Idle own units standing near a door do **not** keep it open (only moving ones), so a parked army does not leave the door wide.
- Mode changes have a 1 s cooldown. Gates under construction are shut (a wall).
### 5.2 How it works in the navmesh and physics
| Part | What it is | Layers |
|---|---|---|
| Frame | End posts (0.4 m) + arms to neighbour pieces: thin colliders (11.3) | physics **1** (baked) |
| Doorway block | `NavigationObstacle3D` over the 3.2 x 1.0 m opening, `affect_navigation_mesh` on (map-fill's river precedent), projected like a collider: the baked navmesh never goes through a door | nav hole for everyone |
| **Owner links** | **Two** `NavigationLink3D` (bidirectional) at +-0.8 m, from 2.3 m in front to 2.3 m behind, on the owner's layer; **on** in Auto and Hold open, off when Locked | nav layer 2 (PLAYER) or 3 (ENEMY) |
| **Open links** | The same two links again on nav layer **1**; **on only while the door is open** (anyone may path through) | nav layer 1 |
| Door leaf body | `StaticBody3D` 3.2 x 1.8 x 0.6 in the opening: collision layer **1** while shut, **0** while open | physics 1 / none |
| Door sensor | `Area3D` (layer 0, mask 2) over the 4 m zone and the doorway box: counts moving own units and anything in the doorway (event-driven) | - |
| Click box | Full cells to the visual height, layer 2 only (`_in_group_upwards` finds the piece) | physics 2 |
- **Own units** (nav layers 1 + own) always have a path through their Auto doors. A unit whose next path point is a shut door's link
  **waits** at the link start (the sensor sees it waiting and opens the door); after 3 s shut (Locked meanwhile) it re-paths.
- **Enemies** (nav layers 1 + their own) only get a path while the door is open. When a door opens, enemy units within **20 m** that
  are in breach mode (5.3) or whose target is behind it **re-path** at once: if the new path goes through the door they drop the wall
  piece and **slip in**. When it shuts, units inside the doorway are never crushed: the door waits (Jammed).
- No navmesh rebake for opening, closing, locking or holding (links toggle; the leaf body is not in a bake while it moves: its layer-1
  collider is inside the already-carved hole).
- Physics: while open, nothing stops anyone physically; while shut the leaf is a normal layer-1 wall for everyone. **No team physics
  layers are needed.** Every direct path query in code (`map_get_path`, bot checks, WorkerAuto, the Ice hard wall rule, the trapped
  check, the ring's exit paths) passes the team's nav layers.
- Look: `set_door(open_ratio)` drives the swing; `set_locked(bool)` the crossbar; `set_jammed(bool)` a small warning banner.
### 5.2b Layers (contract change, lead 18b.L1)
Physics unchanged (1 world, 2 units / clicks). Navigation: **1** everyone (the baked region + open doors), **2** PLAYER door links,
**3** ENEMY door links. Unit agents: 1 + own (PLAYER 1+2, ENEMY 1+3, NEUTRAL 1). The bake and BuildGrid's probe are unchanged.
### 5.3 Breach rule (units)
| Rule | Value |
|---|---|
| When | An **attack** order (unit or building), an **attack-move**, or a champion / bot squad moving at an enemy, whose path cannot reach the target (`is_target_reachable()` false, or the path ends > 2.0 m + target radius away) |
| What | `WallNetwork.find_breach(path_end, target_pos, own_team)`: the enemy wall piece within **6 m** of the path end with the lowest `hp / wall_factor` (segments before gatehouses and towers in practice). Attack it, **keep the order**, resume after it falls and the rebake lands |
| Plain move | Never breaches: stops at the closest point; `Walls block the way` (once per 10 s) |
| Auto-aggro | Wall pieces are never auto-targets, except for `siege` units (in range, no enemy unit within `aggro_range`) |

## 6. Levels follow the keep (systems 18b.C5)
- **Wall level = keep level** (`team_tier()`, bl. 3.1): 1 Timber, 2 Stone, 3 Enchanted. At each tier-up every own wall piece (ring,
  gatehouse, corner tower, player segment, player gate) takes the new level **at once, free**: HP x2 / x3 of base (HP ratio kept;
  ring pieces go to full at L3), Fortification 60 % -> 45 % -> 35 %, twist step (section 7), new look (`set_level`).
- There is **no L key** on walls and no per-piece level cost. New player pieces pay the value of the current level (3.1).
- A lost keep tier (the keep destroyed) never lowers walls.
- Level names (tooltips; titles read `Ember Palisade · Level 2`):
| Kingdom | L1 (wood) | L2 (stone) | L3 (enchanted) |
|---|---|---|---|
| Fire | Timber | Brick-and-iron | Emberglass |
| Shadow | Bone-stake | Darkstone | Duskrune |
| Ice | Packed ice | Rimestone | Glacierglass |
| Nature | Bramble | Rootstone | Bloomwood |
- HP factors multiply with the Masons' Charter (x1.15), Ossuary Walls (Shadow +15 %) and Packed-Ice Walls (Ice, below).
| Research (rs. 4) | With 18b |
|---|---|
| Packed-Ice Walls (Ice) | Every Ice wall piece **+30 % max HP**, player segment cap **24 -> 32**, segment build 8 -> 6 s (other Ice buildings +10 % as today) |
| Ossuary Walls (Shadow) | Includes wall pieces (unchanged text) |
| Permafrost (Ice) | Unchanged (walls pulse 3 m); batched in WallNetwork's 1 Hz pass |
| "Tower" research (Salamander Oil...) | Also corner towers and gatehouse turrets |

## 7. The four kingdoms: look and twist (systems 18b.C6, gameplay 18b.C7)
Twists apply to every wall piece of the kingdom (ring and player-built) and step up with the keep level.
| Kingdom | Look L1 -> L2 -> L3 | Twist | L1 | L2 | L3 |
|---|---|---|---|---|---|
| **Fire** Ember Palisade | Ember-tipped log stakes -> dark brick with iron spikes and brazier cups -> black basalt veined with glowing cracks | **Searing**: every **melee** hit (attacker `attack_range` <= 3.0) on a Fire piece deals fire damage back to the attacker (kind `fire`: Mammoth / Treant x1.5); killer = the piece | **3** per hit | **5** | **7** + `burn` 2 / s for 3 s |
| **Ice** Ice Wall (today's, extended) | Jagged packed-ice blocks (today's model) -> rimestone with ice caps -> glacierglass with a white rune core | **Frostbind**: (1) player Ice segments from **0:00** (16 max before 3:30, as today); (2) **forward**: within 24 m of own construction sites too (Winter Siege, rb. 4.4); (3) melee attackers `chill`ed (-20 % DPS, -1.5 m/s) | chill **2 s** | **2.5 s** | **3 s**; ranged / siege attackers within 8 m chilled 1.5 s per hit |
| **Nature** Living Hedge | Thorny bramble with small flowers -> hedge around mossy standing stones -> living-wood lattice with glowing blossoms | **Regrowth**: a destroyed hedge piece (segment, gate, gatehouse) leaves a **root stump** (no collider, no nav block, not attackable); it regrows at its level when **no enemy unit is within 6 m** and no unit stands in its cells; once per 90 s per piece. Verdant regen (1 %/s after 10 s) applies too | after **60 s** at 30 % | **45 s** at 40 % | **30 s** at 50 % |
| **Shadow** Dusk Wall | Dark stakes lashed with bone ribs -> slate darkstone with pointed merlons -> obsidian with violet runes and low mist | **Gloomward**: own ground units (not titans) within the radius of an own completed Dusk piece that have not attacked or been hit for 3 s are **veiled** (Hushed Paws rule, rs. 4: seen only within 5 m of an enemy unit / building, skipped by enemy auto-targeting; attacking or being hit unveils 3 s) | radius **2.5 m** | **3 m** | **4 m** |
Intent: each twist is worth ~+20-25 % wall value in its own situation and nothing outside it. With the ring they matter mostly at
L2-L3; at L1 only on player-built pieces (Ice's early walls first).

## 8. Damage to walls and siege (gameplay 18b.C7)
Damage taken = raw x attacker's `building_damage_mult` x (1 + `building_damage_bonus`) x **wall factor**, with
`building_damage_mult x wall factor <= 3.0`; locked gates / gatehouses x0.75 more.
| Attacker | Wall factor | Examples |
|---|---|---|
| Normal units, champions, wizard auto-attacks | **Fortification** 0.60 / 0.45 / 0.35 (L1 / L2 / L3) | Flame Guard, Shade, Thornling, archers, cavalry |
| Tag **`&"siege"`** (new) | **1.5** | Ash Hurler, Bone Ballista, Frost Mortar, Bore Beetle, Cinderlock Musketeer, War Mammoth, Barrow Giant |
| Tag `&"titan"` | **2.0** (the higher of siege / titan) | Nightmare Knight, Elder Treant (0.5 x 2 = 1.0), War Mammoth (2 x 2 = 4 -> **3.0**), Barrow Giant (1.0 x 2) |
| Spells and champion abilities that hit buildings | **1.0** | Fireball, Soul Siphon |
| As armour | 60 % ~ armor 67, 45 % ~ 122, 35 % ~ 186 (`EHP = HP x (100 + armor) / 100`) | |
Every kingdom has siege when stone rises (Stronghold): Ash Hurler (T1), Bone Ballista / Frost Mortar / Bore Beetle (T2 Stables);
siege out-ranges corner towers and gatehouse turrets (12-13 m vs 10-11 m).

## 9. Repair (systems 18b.C5; reuses wi. 6)
| Rule | Value |
|---|---|
| Order | Right-click an own damaged piece with workers (hammer cursor), the piece card's **Repair** button, or worker Auto. `command_repair(piece)`; pieces answer `needs_repair()` |
| Speed | 0 -> 100 % in the piece's build time at its level (segment 7 / 10.5 / 14 s; gatehouses and corner towers 30 / 40 s) with 1 worker; 1.5 / 2.0 with 2 / 3 |
| Cost | **25 %** of the piece's value per full repair, charged per 10 % step; no crystals = pause |
| Under attack | Paused / refused within **4 s** of damage (`Under attack`) |
| Chain | Done workers take the next damaged piece of the same wall within 12 m |
| Breaches | Ring breaches: rebuild (2.6). Destroyed player pieces are gone (place again) |
| Worker Auto (wi. 7.2 job 3) | Also own wall pieces below 60 % not damaged for 8 s within 40 m of the keep, and ring breaches (1 worker each); away cap 3 |
| Demolish | Player pieces only: **Delete** twice within 2 s, no refund. Ring pieces cannot be demolished (card: `Part of the city wall`) |

## 10. Rushes and anti-turtle rules
### 10.1 Rush safety
| Time | Everyone | Ice |
|---|---|---|
| 0:00-3:30 | Survey only; no free wall, no player walls | Ice Walls as today (20, 8 s, 500 HP, max 16) |
| 3:00-4:30 | Rushes land and raid (rb. 1, 6.2); from 3:30 a defender may pay for player segments (10 by ~4:05, 200 crystals, workers exposed) | same, + gates from 3:30 |
| ~7:00 | Stronghold: Watch (2 gate towers) or Hands (3 workers), free; no free wall | |
| ~12:00 | Citadel: the Great Wall (free) | |
- **Nothing free before the Stronghold**: the rush window never meets a free wall, tower or worker. The Stronghold needs a Forge or
  Sanctum + a research (rs. 2.2): ~5:30 at the earliest (hard bot), after every rush's raid. Expected rush success change: **-2 to
  -6 %** (player walls from 3:30 only); knob 14.2 row 1 if a cell of rb. 4.5 drops under 20 %.
- **Doors cut both ways**: a defender who sends workers out through an Auto door during a raid opens it for the raiders (they slip in
  if they are within 20 m). Lock the door (Z) to stop it.
- The Rusher bot pays for no walls before TRANSITION. Ice's Winter Siege keeps its 2 forward Ice Walls.
### 10.2 Anti-turtle rules
1. The ring is fixed by the rules (22 m members, <= 72 cells): nobody can ring the map. Player caps 24 segments / 2 gates.
2. One breach (or one open door) is enough; siege x1.5, titans x2, spells x1.0; siege exists at every tier where stone stands.
3. Corner towers and gatehouse turrets <= an L1 Spire at L3, no Garrison fire, max 6 towers.
4. No free wall before the Citadel (~12:00); before it every wall piece is paid; the free ring comes when both sides have siege and
   titans are near.
5. Repair costs crystals and stops under fire; ring breaches cost 25 % to rebuild.
6. Walls give no vision (segments), never count for defeat or in the bot's `own_strength`.
7. Length guard: 18b.L2 runs keep the median in 15:00-20:00 and <= **+1:30** over the `--no-walls` control (14.3).

## 11. Pathing, navmesh rebake and limits (systems 18b.C2 / C3 / C4)
### 11.1 Rebakes
| Event | Rebakes |
|---|---|
| Citadel raise (the Great Wall) | **One** for the whole raise, at completion (the plan is ready from the upgrade start; on the completion frame only the pieces are added and units pushed) |
| Stronghold Watch towers | One (2 towers) when chosen. Hands: none |
| Player line / gate placed | One per placement |
| Piece destroyed / cancelled / demolished / sunk (bulge) | One each, coalesced by the existing pending flag (one running + one pending) |
| Ring bulge | One per batch, max once per 30 s per team |
| Door open / close / lock / hold, level changes | None (links toggle) |
| Nature regrowth | Batched: max once per 3 s per team |
The navmesh is `main.gd`'s one region (120 x 120 m, cell 0.25, agent radius 0.5), baked on a thread. Test 18b.C4 prints the bake time
of an L3 raise with both rings and both player caps; budget **<= 150 ms** thread, **< 4 ms** main-thread spike. Over budget: knob 14.2
"chunked navigation regions" (3 x 3 regions of 40 m; lead decision).
### 11.2 Limits
Per team: ring <= 72 cells (incl. <= 4 gatehouses of 2 cells) + <= 6 corner towers + player 24 segments (Ice 32) + 2 gates -> **<= 110
pieces**; map <= **220**. Systems that scan group `"buildings"` per cell or per frame (BuildGrid's `_overlaps_building`, bot slot scans,
per-frame UI lists) skip `"walls"` and ask `WallNetwork.piece_at(cell)` instead (18b.C1 audits them).
### 11.3 Colliders
| Piece | Layer-1 collider (baked) | Why |
|---|---|---|
| Segment | Post box 1.0 x **1.8** x 1.0 at the cell centre + one arm box (1.0 thick, 1.8 tall) to each connected own neighbour (1.0 m straight, 1.41 m diagonal) | 1.0 m thick < 2 x agent radius: **no navmesh island** on top; 1.8 m = the step-12 collider rule |
| Gate / gatehouse | End posts 0.4 x 1.8 x 1.0 + arms; the gatehouse turret a cylinder r 0.95, 1.8 m (visual up to 6.5 m); the door leaf 1.8 m, layer 1 only while shut (5.2) | Same |
| Corner tower | Cylinder r 0.95, **1.8 m** (visual 6-7 m) | Roof island <= 0.9 m wide, unreachable, like a Spire's |
| Click boxes | Layer 2 only, full cells to the visual height | Easy clicks; not baked |
| Survey stakes | None (decal + a MultiMesh of stakes) | No nav effect before the raise |
The art scenes carry **no** colliders; `WallPiece` builds them from its connection mask.

## 12. The bot (ai 18b.A1 / A2: new rule **18** of `ai.md`; knobs in `AIProfile` / `data/ai/*.tres`)
The ring is automatic for every bot (same `CityWall` code, raised by its keep upgrades as timed by rs. 8). Rule 18 only covers what the
bot **pays** for and how it attacks walls.
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `stronghold_reward` (2.7) | Watch | Hands, but Watch if it was attacked at home in the last 3 min or `seen_strength > own_strength` | same as normal |
| `wall_fill_max` (survey segments it pays for after the Stronghold) | 0 | **16** (the **front**: survey cells within +-50 degrees of the keep -> enemy keep bearing) + a gate on the main spot | **32** (front first, then the rest) + gates on every spot |
| `wall_fill_delay` (after the Stronghold) / `wall_reserve` | - | 60 s / 150 | 30 s / 100 |
| `wall_prebuild_front` (timber on the front survey before the Stronghold) | 0 | 0 | 12 segments from 4:30 |
| `wall_expansion_choke` (segments + 1 gate at its X1) | 0 | 0 | 8 |
| `wall_repair_workers` | 1 | 1 | 2 |
| Rule | Trigger -> action |
|---|---|
| 18a Survey fill | Stronghold + `wall_fill_delay`, crystals >= price + reserve, no rule 1 / 1b defence, no other build waiting -> `place_line` over the next stretch of survey cells (front first; hard: then nearest the enemy's last attack path), 2 workers not carrying crystals; the gate on the main spot with the first stretch; up to `wall_fill_max` |
| 18b Pre-build (hard) | From 4:30, after its X1 is placed: up to 12 timber segments on the front's survey cells (they turn stone for free at the Stronghold); counts toward `wall_fill_max` |
| 18j Reward | At the Stronghold's completion: picks `stronghold_reward` at once |
| 18c Expansion choke (hard) | After X1 completes: up to 8 segments + 1 gate across the X1's approach from the enemy (where the X1 -> enemy keep path crosses a 12 m circle around the X1), validated by `BuildGrid.check` and paths X1 -> its nodes |
| 18d Repair / rebuild | A piece < 60 % not damaged for 8 s, or a ring breach with no enemy within 15 m for 10 s -> up to `wall_repair_workers` workers repair / rebuild |
| 18e Doors | Auto. Normal and hard: **lock** every own door while rule 1 / 1b defends and back to Auto when it ends; hard also locks a door when >= 3 enemy soldiers are seen within 20 m of it outside. Workers sent out during a lock use another door or wait |
| 18f Styles | Rusher: pays for no walls before TRANSITION. Ice: the existing hard rule (2 Ice Walls beside S1) stays and counts toward the cap |
| 18g Attacking walls (all difficulties, 18b.A2) | An attack group whose target is unreachable (own layers) or whose detour is > 1.8 x the straight line + 20 m -> **siege mode**: up to 2 siege units join (rb. 7.2), attack `WallNetwork.find_breach` on the straight line, the army waits 4 m behind, then continues. Prefers an unwalled survey gap within 25 m of its path. **Slip-in**: an attack group within 20 m of an enemy door that opens drops the siege target and runs through (the unit re-path rule of 5.2). Champions use the unit breach rule |
| 18h Strength | Wall pieces add 0 to `own_strength`; corner towers and gatehouses count as towers (150 each) |
| 18i Keep upgrade | Unchanged (rs. 8): the Great Wall is simply part of what the Citadel brings |
Expected (normal): Stronghold reward ~7:00-8:00 (mostly Hands), a paid stone front + main gate by ~9:30 (~16 x 35 + 100 = ~660
crystals), Great Wall ~12:30-13:30.

## 13. UI (layout: ui-designer addendum `docs/design/ui-walls.md`, task 18b.U0; code 18b.U1 / U2)
| Element | Content | Interaction |
|---|---|---|
| **Keys** (physical) | Build menu **V** = Walls page (all kingdoms); page **Z** (or V) = Wall, **X** = Gate, Esc = back. Dragging: **Ctrl** = 45-degree lock, **Shift** on release = chain. Gate / gatehouse selected: **Z** = Lock / back to Auto (**Shift+Z** = all own doors), **X** = Hold open / back to Auto (**Shift+X** = all). Player piece(s) selected: **Delete** twice = demolish. Checked in `CLAUDE.md` and every `docs/design/*.md`: build-menu V was only the Ice Wall; Z and X on a gate card are free (gates train nothing); no L on walls (levels follow the keep's **N**) | AZERTY prints the same letters |
| Keep card | Stronghold / Citadel tooltips add `+ A free reward: 2 gate towers or 3 workers.` / `+ The Great Wall: the whole city ring (free).` After the Stronghold: the **reward chip** in the keep panel, two buttons **Watch** / **Hands** (no key) with a 60 s countdown (`Watch in 0:42 if you do not choose`) | During the Citadel upgrade the keep panel shows `Great Wall rises in 0:12` |
| Survey | Stakes and a faint chalk line; while the Walls tool is open or the keep is selected the survey glows (gatehouse spots brighter); owner-only ghost of the Great Wall during the Citadel upgrade | Hover a stake: `City wall (free with the Citadel, or build it now)` / `Gate spot` / `Breach: rebuild 9 crystals` |
| Build menu | r2c1 **Walls V**: `Walls  [V]\nWalls and gates for your expansions, or to close your city ring early.` + `Available at 3:30` | |
| Walls page tooltips | `Ember Palisade  [Z]\n20 crystals · 7 s · 420 HP\nDrag a line. On the city survey it becomes part of your city wall.` · `Ember Gate  [X]\n60 crystals · 20 s · 1 050 HP\nOpens for your units; while open, anyone can pass. Max 2 (gate spots on your city survey are free of the limit).` (values at the current keep level) | |
| Placement ghosts | Chain ghosts (kit meshes, alpha 0.5, green / red per cell), counter at the cursor, snap highlights on wall ends and the survey; gate ghost with doors and a through-arrow | 4.2 / 4.3 |
| Selection | Click = one piece; double-click = all own pieces of that kind on screen (the existing gesture); Shift+click adds. Box select never picks walls; walls never join groups | |
| Piece card | Gates / gatehouses: r1c1 **Lock Z**, r1c2 **Hold open X** (toggles, lit when active; both off = Auto). Every piece: r1c3 **Repair** (no key; disabled `Not damaged` / `Under attack` / `No free worker`), r1c4 **Demolish Delete** (player pieces only). Breach stake: r1c3 **Rebuild** (`9 crystals · 10.5 s`) | |
| Panel | `Ember Palisade · Level 2 (Brick-and-iron)` + level pips, `City wall` or `Built wall` tag, HP, `Fortification 45 %`, twist line (`Searing: 5 damage to melee attackers`), door chip `Auto · shut` / `Auto · open` / `Locked` / `Held open` / `Jammed` (red), Nature stump `Regrows in 0:32` (grey while an enemy is near). Many: `18 Ember Palisades · 7 560 / 15 120 HP` | |
| World | HP bar when selected, a site, or damaged in the last 8 s; doors swing (both teams see open doors); locked crossbar; held-open doors show a hook on the leaf; jammed doors a small red banner (own view) | |
| Minimap | Ring and walls: 2 x 2 px in the team colour darkened 30 %; gatehouses 3 px bar; corner towers 3 px dot; own survey 1 px dotted; enemy: last seen. Breach ping: red ring 3 s | |
| Messages (own) | `Choose your Stronghold reward: Watch or Hands` · `Gate towers raised` / `3 workers join you` · `The Great Wall rises in 10 s` · `The Great Wall is complete!` · `Your wall is under attack` (20 s per wall stretch, ping) · `Wall breached!` · **`Enemies slipped through the Ember Gate!`** (ping; once per 20 s per door) · `Enemies at the Ember Gate!` (jammed) · `Warning: your wall traps 3 units` · `Walls block the way` · `Gate locked` / `Gate held open` / `Gate on Auto`; enemy: `The enemy raised its Great Wall` (if visible) | Max one wall line per 3 s |
| Audio (SFX bus) | Raise rumble (kingdom tint), hits per material, breach crash, gate creak / lock clank, sear sizzle, chill crackle, regrowth rustle (max 2 / s each) | |
| End screen / settings / help | `Walls: built 34 · breaches suffered 3 · breaches made 2` · skirmish option `Walls: On / Off` (default On) · help `B, V: walls (drag a line)    Z / X (gate): lock / hold open` | |

## 14. Balance
### 14.1 Checks (level 1 units, no items; melee frontage ~4-5 per wall face)
| Case | Result |
|---|---|
| Ring size (Crown Hollow main base: keep, Hall, 2 houses, tower, Forge, Sanctum, Bazaar, 2 home nodes) | Radius ~18-24 m -> **~52-64 cells**, 3 gatehouses (enemy keep, natural X1, Bazaar road), 4-5 corners at L3 |
| Stronghold reward | **Watch** ~240 crystals of towers (2 x 1 260 HP, 8 DPS each) that defend the main door at once; **Hands** 150 crystals + 36 s of keep time, ~+200 crystals / min once mining (+3 pop). Hands pays more after ~2 min of peace; Watch wins if the enemy is at the door. Both are small next to the Stronghold's own value (rs. 2.2) |
| Paying for the ring before the Citadel | Stone front of ~16 cells + a main gate: 16 x 35 + 100 = **660** crystals; the whole ring ~60 x 35 + 3 gates = **~2 400**: few players close it before the Citadel, which is the point of the free Great Wall |
| Door slip-in | Workers leaving through an Auto door keep it open ~3-4 s (the 2 s rule + swing); a raiding pack within 20 m re-paths and gets in. Locking costs your own units the detour to another door or a wait |
| L3 Great Wall | ~60 enchanted pieces (1 260) + gatehouses + 4-6 towers ~ **100 000 HP**; one breach opens it |
| 5 Flame Guards on an L2 Dusk Wall (840, 45 %) | 27 DPS -> **31 s**; an unwalled survey gap or an open door is the fast way in |
| 2 Bore Beetles (45 DPS each vs walls) on L2 / L3 segments | **9.3 s / 14 s** |
| 4 Ash Hurlers / 2 Bone Ballistas / 2 Frost Mortars on L2 (840) | 13 s (10 s with Blasting Powder) / 14 s / 25 s, from 12-13 m, out of tower range |
| 5 Shades on an L3 Ember Palisade (1 260, 35 %) | 19.3 DPS -> **65 s**: armies need siege by the Citadel |
| War Mammoth on L3 (net x3.0) | ~11 hits |
| L3 corner tower vs a Flame Guard (130 HP) | 15 per 1.5 s -> 13 s: a delay, not a killer |
| Player walls at 3:30 (Fire, 10 segments, 200 crystals) | 5 Flame Guards breach one in **11.7 s** (Searing 3 / hit: ~35 damage each) |
| Match length | Expected **+0:45 to +1:45** vs `--no-walls` (the free L3 ring lands when games should end: watched by the length guard) |
### 14.2 Knobs (one at a time; 18b.D2 after the 18b.L2 runs)
| Symptom | Knob |
|---|---|
| A rush cell of rb. 4.5 under 20 % | Player walls 3:30 -> **4:30** (Ice segments unchanged) |
| Median > 20:00 or > +1:30 vs control | Great Wall rises **60 s after** the Citadel; L3 Fortification 35 % -> **45 %**; siege 1.5 -> **2.0** |
| One reward always picked (> 80 % of human / bot games) | Watch 2 -> **3** towers, or Hands 3 -> **2** workers (whichever dominates is cut, the other raised) |
| Stronghold reward too strong | Watch towers at 80 % -> **60 %** of Spire damage; Hands 3 -> **2** workers |
| Doors leak too much (defenders lose to slip-ins, playtest) | Auto close delay 2 -> **1 s**; own units must be within **3 m**; enemies re-path only within **12 m** |
| Jamming abused (one unit holds a door) | A door shuts after **4 s** jammed, pushing units in the doorway to the side they came from |
| Rings too big (perf, turtling) | Member radius 22 -> **18 m**; max ring cells 72 -> **56** |
| Nobody pays for gaps or player walls | Segment value 20 -> **15** (L2 35 -> 28); gap rebuild 25 % -> free |
| T1 armies cannot breach player walls before 7:00 | L1 HP 420 -> **350** |
| Searing kills rush units at player walls | 3 / 5 / 7 -> **2 / 3 / 5** |
| Regrowth frustrating | Delay +15 s at every level; once per **120 s** per piece |
| Gloomward too strong | Radius -1 m; ranged units never veiled |
| Packed-Ice too strong | +30 % -> **+20 %** |
| Rebake over budget | Chunked nav regions (3 x 3); raise split in 2 bakes 1 s apart (the half facing the enemy first) |
| Perf over budget with both rings | Ring render batching: intact ring segments drawn by one MultiMesh per team x level x kit part |
| Gate traffic jams | Gatehouse opening 2 -> **3 cells** |
| Nobody pays for survey cells before the Citadel | Survey segments at **-25 %** (they are "planned" wall) |
### 14.3 Re-test plan (lead 18b.L2, then 18b.D2)
Harness: the any-kingdom bot-vs-bot run (normal, cap 24:00), flag **`--no-walls`** as the control.
| Round | Pairs | Runs | Pass |
|---|---|---|---|
| A | 6 non-mirror pairs, both orders | 12 with walls, 6 control | Median 15:00-20:00 and <= +1:30 of the control; every kingdom 35-65 %; every ring's keep -> nodes / X1 / rally paths valid (0 trapped) |
| B | rb. rush rounds B / C with walls on | as rb. 11.3 | Every cell 20-50 %; <= 15 % of rush games end before 8:00 |
| C | Duels (`tests/test_18b_c7.gd`) | the rows of 14.1 + a door test (3 workers leave through an Auto door with 6 enemy soldiers 15 m outside) | Breach times within +-15 %; the soldiers slip in; with the door Locked they do not |
| D | Reward log (A runs) | - | Watch and Hands each picked in 30-70 % of bot Strongholds |
| Perf | perf test + both L3 rings + both player caps + 2 breaches rebuilt + Nature stumps regrowing | 1 | `PERF OK`, stuck 0, bake budget 11.1 |

## 15. Performance
| Item | Budget / rule |
|---|---|
| Pieces | `_physics_process` **off** once completed; ring, outline and HP bar created lazily. <= 6 nodes per segment, <= 14 per gate / gatehouse (+ obstacle, 4 links, door leaf, sensor, gun), <= 8 per corner tower |
| Scans | Group `"buildings"` scans per cell / per frame skip `"walls"` (11.2); WallNetwork's cell dictionary answers cell questions in O(1) |
| CityWall | Plans only on events (upgrade start / completion, member completed; at most 1 per 30 s); hull of <= 20 members + rasterise <= 72 cells + <= 8 exit paths: **< 5 ms** per plan, never on the raise frame |
| WallNetwork | One per team; events + a **1 Hz** pass (Verdant, stumps, Thornwatch, Permafrost), teams staggered: **< 0.03 ms / frame** average |
| Doors | Sensor `Area3D` events only (no per-frame polling); the enemy re-path on open touches only units within 20 m (a squared-distance pass over the cached enemy list, once per open) |
| Twists | Searing / Frostbind inside `take_damage`; Gloomward through the unit's existing 0.5 s veil tick (`near_own_wall`, a cell lookup) |
| Rebake | 11.1 |
| Fog | Segments are not fog sources; gates 6, gatehouses and towers 13-14. Enemy walls get fog ghosts (post + arms only) |
| Render | Shared kit meshes and materials per kingdom x level; 0 real lights; no shadows from thin parts; ember / mist / frost / sway are shaders (off beyond 60 m); survey stakes one MultiMesh per team |
| Total | New logic **< 0.05 ms / frame** average with both L3 rings and both player caps |

## 16. Art (tech-artists, one agent per row; style `art-keep.md` section 0: chunky, hand-painted, readable at 40 m)
### 16.1 Rules for every wall art task
- **Kit, not a mesh**: each segment level is a kit (`post`, `arm_straight` 1.0 m, `arm_diagonal` 1.41 m, `end_cap`, states);
  `set_connections(mask)` (8 bits N NE E SE S SW W NW) shows the arms. Pieces of one team join across kinds (segment, gate,
  gatehouse, tower) and against own buildings (end cap).
- **Heights**: segments <= **2.2 m** (L1 1.8, L2 2.0, L3 2.2 incl. crest); player gates <= 4.0 / 4.6 / 5.2 m; gatehouses (L3) <= 6.5 m;
  corner towers 6 / 7 m. Colliders are code (11.3): every layer-1 collider is 1.8 m tall; taller visuals are fine.
- **Silhouette**: a 40 m black-silhouette test tells L1 / L2 / L3 apart (jagged / organic top, squared blocks and merlons, crest + one
  glow point) and the four kingdoms apart. The L3 ring must read as "the Great Wall" from the default camera (continuous crest).
- **Budgets**: segment <= 3 visible mesh instances, <= 1 glow point (L3); gate <= 10 meshes, 2 glow points; gatehouse <= 14 meshes,
  3 glow points; tower <= 10 meshes, 2-3 glow points; shared materials (painted / rune_glow shaders of `art-keep.md` 5); **0 real
  lights**; no looping particles on wall pieces.
- **Hooks** (scene root, called by `WallPiece` if present): `set_connections(mask)`, `set_level(level)` (instant; fog ghosts too),
  `set_team_color(c)`, `set_construction_progress(p)`, `set_health_ratio(r)` (missing stakes / leaves / cracks under 50 %),
  `play_raise()` (3 s rise from the ground: the Great Wall and the Watch towers), `play_level_up()` (shader sweep, pieces that
  change level), `play_destroyed()` + signal `destroyed_finished`, `play_hit()`. Gates and gatehouses: **`set_door(open_ratio)`** (0-1,
  two leaves swing inward, 0.6 s open / 0.8 s close driven by code), `set_locked(bool)` (crossbar), `set_held(bool)` (hook on the leaf),
  `set_jammed(bool)` (small red banner, own view);
  gatehouses and towers: `play_shot()`; Nature pieces: `set_stump(bool)`, `play_regrow()`.
- Paths: `res://art/buildings/walls/<kingdom>/wall_l<N>_kit.tscn`, `gate.tscn`, `gatehouse.tscn`, `tower.tscn` (levels as `Level1-3`
  nodes), `res://art/buildings/walls/survey/`; previews `art/buildings/previews/walls_<kingdom>.png` (L1 player line, L2 survey with a
  paid stone front, a gate and the 2 Watch towers, L3 Great Wall around a keep); hooks listed in `docs/handoff/for-systems-coder.md`.
### 16.2 Art tasks
| Task | Asset | Look |
|---|---|---|
| 18b.V1 | Fire segment L1 Timber | Ember-tipped sharpened log stakes of uneven height, iron bands, charred base (flicker shader) |
| 18b.V2 | Fire segment L2 Brick-and-iron | Dark red brick courses, iron spike crest, a brazier cup on posts (glow material, not a light) |
| 18b.V3 | Fire segment L3 Emberglass | Black basalt veined with glowing orange cracks, flame-shaped post crests (1 glow point) |
| 18b.V4 | Shadow segment L1 Bone-stake | Dark timber stakes lashed with bone ribs, tattered violet cloth |
| 18b.V5 | Shadow segment L2 Darkstone | Slate-grey blocks, pointed merlons, iron rings, raven carvings on posts |
| 18b.V6 | Shadow segment L3 Duskrune | Obsidian with violet rune lines, a low mist band (UV-scroll shader), raven-skull post caps |
| 18b.V7 | Ice segment L1 Packed ice | Today's Ice Wall (3 tilted jagged prisms) cut into the kit, so existing games look the same |
| 18b.V8 | Ice segment L2 Rimestone | Blue-grey blocks capped with snow and icicles |
| 18b.V9 | Ice segment L3 Glacierglass | Translucent crystal slabs, white rune core glow, frost creep at the base |
| 18b.V10 | Nature segment L1 Bramble | Dense thorny hedge with small white flowers (sway shader) + the **root stump** (all levels) |
| 18b.V11 | Nature segment L2 Rootstone | The hedge grown around mossy standing stones |
| 18b.V12 | Nature segment L3 Bloomwood | Living-wood lattice with glowing blossoms |
| 18b.V13 | Fire player gate (L1-L3) | Log gate under an ember-tipped arch -> brick arch -> basalt arch; two door leaves on hinges (`set_door`), crossbar, hold-open hook |
| 18b.V14 | Shadow player gate (L1-L3) | Bone-lashed doors -> darkstone arch with a raven keystone -> obsidian arch with a violet rune eye |
| 18b.V15 | Ice player gate (L1-L3) | Ice-block posts with hide doors -> rimestone arch with icicle teeth -> glacierglass arch with a rune shield |
| 18b.V16 | Nature player gate (L1-L3) | Bramble arch with woven doors -> stone-root arch -> blossoming living-wood arch; the crossbar is a thick vine |
| 18b.V17 | Ember Gatehouse (Fire, L3 only) | Basalt gatehouse with a heavy two-leaf door, an ember crest over the arch and a flanking brazier turret |
| 18b.V18 | Dusk Gatehouse (Shadow, L3 only) | Obsidian gatehouse with iron-bound leaves, chains and a turret with a violet lantern eye |
| 18b.V19 | Rime Gatehouse (Ice, L3 only) | Glacierglass gatehouse with frosted leaves and a turret circled by an orbiting crystal shard |
| 18b.V20 | Thorn Gatehouse (Nature, L3 only) | Living-wood gatehouse with woven-root leaves and a turret crowned with a glowing bloom |
| 18b.V21 | Brazier Tower (Fire, L2-L3) | Brick tower with a brazier ring (the Watch towers) -> basalt tower with a large ember orb cage |
| 18b.V22 | Gloomwatch (Shadow, L2-L3) | Darkstone tower with a hooded top -> obsidian needle with a violet lantern eye |
| 18b.V23 | Rimewatch (Ice, L2-L3) | Rimestone tower with a snow cap -> glacierglass tower with an orbiting shard |
| 18b.V24 | Thornwatch (Nature, L2-L3) | Tower grown from a stone-gripping trunk -> living tower with a glowing bloom crown |
| 18b.V25 | Survey (shared, team tint) | Surveyor's stakes with kingdom-coloured flags (MultiMesh), faint chalk line decal, taller gate stakes, the owner-only ghost look of the next raise, the breach stake |
| 18b.V26 | Raise VFX (shared, kingdom tint) | `play_raise` companion: a dust wave running along the ring (Great Wall) or around a tower (Watch), pebbles and a ground crack line (<= 8 pooled bursts per raise, no particles per piece); the Hands reward: 3 workers stepping out of the keep door with a small banner puff |
| 18b.V27 | Shared wall VFX | Breach burst per material (splinters / stone chunks / ice shards / leaves, <= 24, pooled), repair ticks, level-up shader sweep, rubble decal |
| 18b.V28 | Fire twist VFX | Searing ember flash on the attacker (pooled, <= 8), scorch marks on L3 bases |
| 18b.V29 | Ice twist VFX | Chill puff on the attacker (reuse the chill mark if it reads), frost creep decal at L3 |
| 18b.V30 | Nature twist VFX | Stump idle sprouts, 2 s regrow tween + leaf burst (<= 16) |
| 18b.V31 | Shadow twist VFX | Own-view `veil` (reuse 14.V15), mist band shader on Dusk pieces |
| 18b.V32 | Icons | Walls page, Wall, Gate (x4 kingdoms), Lock, Hold open, Auto door, Watch reward, Hands reward, Demolish, Rebuild, city-wall badge, twist icons Searing / Frostbind / Regrowth / Gloomward; Repair reuses 17b.V3 (`art/icons/walls/`, 64 px, `ui-style.md`) |
No hard dependencies (V7 reuses today's Ice Wall model); gatehouse and tower tasks reuse their kingdom's L2 / L3 segment materials once
those land (V2-V3, V5-V6, V8-V9, V11-V12), or build them first and share.

## 17. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 18b.L1)
Phase-1 rule (as steps 9-18): never use another step-18b agent's new `class_name` as a static type; use groups, `has_method()`, `get()`.
- **Layers**: physics unchanged; navigation 1 = all (incl. open doors), 2 = PLAYER door links, 3 = ENEMY door links (5.2b). Unit agents:
  nav layers 1 + own. Every `map_get_path` passes the team's layers.
- **BuildingType**: kinds `&"wall"` (existing), `&"gate"`, `&"gatehouse"`, `&"wall_tower"`; `min_time` (step 13's field; 210 for player
  walls, 0 for Ice segments), `ring_only := false` (gatehouses, corner towers). Constants in `scripts/buildings/wall_rules.gd`
  (`class_name WallRules`): `FORTIFICATION := [0.6, 0.45, 0.35]`, `SIEGE_FACTOR := 1.5`, `TITAN_FACTOR := 2.0`, `MAX_NET := 3.0`,
  `LOCKED_MULT := 0.75`, `HP_MULT := [1.0, 2.0, 3.0]`, `TIME_MULT := [1.0, 1.5, 2.0]`, `VALUE_SEGMENT := [20, 35, 60]`,
  `VALUE_GATE := [60, 100, 160]`, `PLAYER_SEGMENTS := 24`, `ICE_EARLY_SEGMENTS := 16`, `PLAYER_GATES := 2`, `CITY_RADIUS := 24.0`,
  `NEUTRAL_CLEARANCE := 6.0`, `REPAIR_COST := 0.25`, `REPAIR_BLOCK := 4.0`, `REPLACE_REFUND := 0.5`, ring numbers
  `MEMBER_RADIUS := 22.0`, `RING_MARGIN := 4.0`, `RING_MIN := 14.0`, `RING_MAX := 26.0`, `RING_MAX_CELLS := 72`, `GATES_MIN := 2`,
  `GATES_MAX := 4`, `EXIT_MERGE := 12.0`, `CORNER_TURN := 35.0`, `CORNER_TOWERS_MAX := 6`, `BULGE_COOLDOWN := 30.0`, reward
  `WATCH_TOWERS := 2`, `HANDS_WORKERS := 3`, `REWARD_CHOICE_TIME := 60.0`, doors `DOOR_OPEN_RADIUS := 4.0`, `DOOR_CLOSE_DELAY := 2.0`,
  `DOOR_OPEN_TIME := 0.6`, `DOOR_CLOSE_TIME := 0.8`, `DOOR_REPATH_RADIUS := 20.0`, `DOOR_MODE_COOLDOWN := 1.0`, twist tables of section 7.
- **WallPiece** (`scripts/buildings/wall_piece.gd`, `class_name WallPiece extends Building`, groups `"buildings"`, `"walls"`):
  `piece_kind` (`&"segment"`, `&"gate"`, `&"gatehouse"`, `&"tower"`), `is_ring_piece() -> bool`, `cells() -> Array[Vector2i]`,
  `connections() -> int`, `refresh_connections()`, `wall_level() -> int`, `set_wall_level(level)`, `fortification() -> float`,
  `wall_factor_for(attacker: Node) -> float`, `needs_repair() -> bool`, `add_repairer(w)`, `remove_repairer(w)`,
  `repair_spot(from, reach) -> Vector3`, `demolish() -> String` (refused for ring pieces), `is_auto_target_for(attacker) -> bool`;
  gates / gatehouses (doors): `door_mode() -> StringName` (`&"auto"`, `&"locked"`, `&"held"`), `set_door_mode(mode) -> String`,
  `is_open() -> bool`, `is_jammed() -> bool`, signals `door_mode_changed(gate, mode)`, `door_opened(gate)`, `door_closed(gate)`,
  `slipped_through(gate, unit)` (an enemy crossed while open); signal `breached(piece, by_team: int)`. `counts_for_defeat() == false`.
- **CityWall** (`scripts/buildings/city_wall.gd`, `class_name CityWall extends Node`, one per team, group `"city_walls"`,
  `static func for_team(team) -> CityWall`): `plan() -> Dictionary` (`{cells, gate_spots, main_spot, corners}`), `survey_cells() ->
  Array[Vector2i]`, `is_survey_cell(cell) -> bool`, `is_gate_spot(cell) -> bool`, `raised_level() -> int`, `preview(level)` (keep
  upgrade start), `raise_to(level)` (keep upgrade completion; research off: the tier timer; L2 opens the reward, L3 raises the Great
  Wall), reward: `reward_pending() -> bool`, `reward_time_left() -> float`, `choose_reward(kind: StringName) -> String` (`&"watch"` /
  `&"hands"`), `reward_taken() -> StringName`; `breaches() -> Array[Vector2i]`, `rebuild_cost(cell) -> int`, `rebuild(cell, workers) ->
  String`, signals `ring_planned(team)`, `ring_raised(team, level)`, `reward_offered(team)`, `reward_chosen(team, kind)`.
- **WallNetwork** (`scripts/buildings/wall_network.gd`, one per team, group `"wall_networks"`, `static for_team(team)`,
  `static find_breach(from: Vector3, to: Vector3, attacker_team: int) -> Node`): `piece_at(cell)`, `count(kind, include_ring := false)
  -> int`, `near_own_wall(pos: Vector3, radius: float) -> bool`, `set_level_all(level)`, `stumps() -> Array[Dictionary]`,
  `check_trapped(near: Vector3)`, signals `wall_changed(team)`, `breached(piece, by_team)`.
- **Keep**: at tier-up start calls `preview(tier)` on its team's CityWall, at completion `raise_to(tier)` then the WallNetwork's
  `set_level_all(tier)` (through the groups; the keep never types these classes).
- **BuildGrid**: `line_cells(a, b, lock_45 := false) -> Array[Vector2i]`, `check_line(type, a, b, team) -> Array[String]`,
  `place_line(type, a, b, team, workers) -> Array[Building]` (one rebake), `snap_gate(pos, team) -> Dictionary`; ring cells in `check`
  (raised = `Blocked`; survey = free for walls); the outer cell ring allowed for ring pieces; messages of 4.5.
- **Worker**: `command_build_line(sites: Array)`; repair / rebuild through wi.'s `command_repair(target)` (breach stakes answer
  `needs_repair()`).
- **Unit** (gameplay): layers above; wall factor in the damage path (`target.wall_factor_for(self)` when present); tag `&"siege"` on
  `ash_hurler`, `bone_ballista`, `frost_mortar`, `bore_beetle`, `cinderlock_musketeer`, `war_mammoth`, `barrow_giant`; breach rule 5.3;
  door rules 5.2 (wait at a shut own door's link, re-path when a door within 20 m opens: `repath_now()`); auto-aggro skips `"walls"`
  unless `siege`; Gloomward via `near_own_wall`; Searing / Frostbind reach the unit through
  `take_damage(amount, piece)` (kind `fire` where available) and `apply_status(&"chill", t)`.
- **Towers / keeps**: skip `"walls"` targets. **Skirmish**: `@export var walls_enabled := true` (missions false), `--no-walls`, creates
  one CityWall and one WallNetwork per team, end-screen line. No `Events` change.
- **Ownership**: `scripts/buildings/wall_piece.gd`, `wall_network.gd`, `city_wall.gd`, `wall_rules.gd`, `data/buildings/*_wall*.tres`,
  `*_gate*.tres` = systems-coder; `scripts/units/` parts = gameplay-coder; `scripts/ui/` walls parts = ui-coder;
  `art/buildings/walls/**`, `art/vfx/wall_*`, `art/icons/walls/` = tech-artists; `scripts/ai/` = ai-coder.

## 18. What changes in other specs (18b.D2 writes the lines after the build)
- `research.md` 2.2: the Stronghold gives the Watch / Hands reward, the Citadel raises the Great Wall (tooltips); Packed-Ice Walls text (section 6).
- `building-levels.md` 4.5: Hands adds 3 workers at the Stronghold (staffing supply); the start stays 4 workers.
- `building-levels.md`: walls level with the keep (replaces "Ice Wall: never"), no L on walls.
- `buildings.md`: build menu r2c1 **Walls V** (page Z / X), ring cells in placement, outer cell ring for ring pieces.
- `kingdom-ice.md`: the Ice Wall becomes the Ice segment (caps, sight 0, levels, Frostbind, gates).
- `rush-balance.md` 3.5: "Kingdom extra" (Ice Walls as today; the others' player walls from 3:30; nothing free before the Stronghold;
  doors can be slipped through during a raid).
- `worker-improvements.md`: Auto job 3 includes walls and ring breaches. `cavalry-mounts.md` / `titans-2.md`: titans x2 vs walls.
- `levels.md`: victim rows (segment 10, gate 25, corner tower 40, gatehouse 60). `ai.md`: rule 18, path queries with layers.
- `ui-hud.md`: Walls page, piece card, keep tooltips. `CLAUDE.md` (lead): layers, contracts, Keys, owners.

## 19. Task list (step 18b; build with or after step 18)
**Phase 0:** 18b.L1, 18b.U0. **Phase 1 (parallel):** 18b.C1, 18b.C7, 18b.V1-18b.V32. **Phase 2:** 18b.C2, 18b.C3 (after C1).
**Phase 3:** 18b.C4 (after C2 / C3), 18b.C5, 18b.C6, 18b.C8. **Phase 4:** 18b.U1, 18b.U2, 18b.A1, 18b.A2, 18b.C9 (art plug).
**Phase 5:** 18b.A3, 18b.L2, 18b.D2.
| Id | Owner | Size | Task | Files | Done when |
|---|---|---|---|---|---|
| 18b.L1 | lead | S | Freeze section 17 (layers, contracts, Keys, owners), ids in `waves.md`, the user's answers | `CLAUDE.md`, `docs/plan/` | Written |
| 18b.U0 | ui-designer (Fable) | S | `docs/design/ui-walls.md`: Walls page, line / gate ghosts, survey and Great Wall ghost, keep tooltip lines, the Watch / Hands reward chip, door card (Lock / Hold open) and door chips, piece / breach cards, panels, minimap, messages | `docs/design/ui-walls.md` | Every element of section 13 has size, place and look at 1600 x 900 |
| 18b.C1 [H] | systems-coder-high | L | `WallPiece` + `WallRules`; 16 `.tres` (ice_wall updated); thin colliders from the mask, click box; auto-connect across kinds and to own buildings; wall factor; lazy ring / bar; process off; demolish (player only); the `"buildings"` scan audit (11.2) | `scripts/buildings/wall_piece.gd`, `wall_rules.gd`, `data/buildings/`, scan call sites in `scripts/buildings/` | Test: a segment with E and NE neighbours shows post + 2 arms, collider 1.8 m / 1.0 m thick; `wall_factor_for` 0.6 / 0.45 / 0.35, siege 1.5, Mammoth net 3.0; HP 420 / 840 / 1 260 (Ice 500 / 1 000 / 1 500, Nature 380 / 760 / 1 140); process off when complete; a ring piece refuses Delete; a side with only walls loses; `BuildGrid.check` time within +10 % with 220 wall pieces on the map |
| 18b.C2 [H] | systems-coder-high | L | Player walls: `line_cells`, `check_line`, `place_line` (one rebake, Ctrl lock), rules 4.5 (3:30, Ice early 16, city radius incl. Ice sites and survey cells, clearances, caps 24 / 2 with stumps, ring pieces uncapped), gate snap / replace, prices and times by keep level, `command_build_line`, trapped warning | `scripts/buildings/build_grid.gd`, `wall_network.gd` (cells), `scripts/economy/worker.gd` | Test: a 12-cell diagonal drag = 12 sites, 1 rebake, units cannot pass; a 25th player segment -> `Wall limit reached` while survey cells still accept pieces; Fire at 3:29 -> `Available at 3:30`, Ice at 0:30 ok, 17th Ice before 3:30 refused; 25 m from any building -> `Too far from your buildings`; at the Stronghold a new segment costs 35 and takes 10.5 s |
| 18b.C3 [H] | systems-coder-high | L | Real doors (5.1-5.2): doorway obstacle, owner links + open links, door leaf layer 1 / 0, sensor, Auto open / close (moving own units, 2 s, doorway clear, jam), Locked (x0.75, waits for a clear doorway), Hold open, 1 s mode cooldown, enemy re-path on open (20 m), `slipped_through` signal; `WallNetwork` core (cells, `find_breach`, `near_own_wall`, counts, signals) | `scripts/buildings/wall_piece.gd` (door part), `wall_network.gd` | Test: a player worker walking out opens an Auto door, which shuts 2 s after it is 4 m away; an enemy soldier 15 m outside with an attack order inside slips in while it is open and is stopped by the wall once it shuts; an enemy standing in the doorway keeps it open (`Jammed`); Locked: the worker goes around, the enemy never enters, damage x0.75; Hold open: both pass; no rebake on any door change; `find_breach` returns the weakest piece within 6 m |
| 18b.C4 [H] | systems-coder-high | L | `CityWall`: members, hull, clamp, rasterise, obstacles / map edge / own buildings, exits and 2-4 gate spots (main spot), the Stronghold reward (choice, 60 s default Watch, Watch towers beside the main spot with one rebake, Hands workers with pop waiting), L3 Great Wall (full ring, gatehouses on every spot incl. converting player gates, corners max 6, restore), preview at upgrade start, raise at completion (push-out, one rebake), bulge (30 s), breaches and rebuild, research-off timers, keep hooks, bake-time print | `scripts/buildings/city_wall.gd`, `keep.gd` (hook calls only), `build_grid.gd` (ring cells, outer ring) | Test on Crown Hollow, both sides: the L1 survey encloses keep, Hall, houses, tower, Forge, Sanctum, Bazaar and both home nodes with <= 72 cells and 2-4 gate spots on the paths to the enemy keep / X1 / Bazaar road; the Stronghold raises **no** wall; Watch raises 2 L2 towers beside the main spot in one rebake; Hands gives 3 workers (with pop 39 / 40: 1 comes out, 2 wait); no choice in 60 s = Watch; the Citadel closes the ring in **one** rebake (the enemy has no ground path in except breaches and open doors), turns a player gate on a spot into a gatehouse, restores breaches, and no unit ends inside a piece; own units reach every node and X1 through doors; a Hall completed at 21 m outside the ring bulges it within 30 s; research off gives the reward at 6:00 and the wall at 11:00; bake time printed within 11.1 |
| 18b.C5 | systems-coder | M | Levels follow the keep (`set_level_all` at tier-up, HP ratio, L3 ring full), research hooks (section 6), repair (cost, 4 s block, chain), ring rebuild cost and times, WorkerAuto job 3 (walls + breaches), line sites attended | `scripts/buildings/`, `scripts/economy/worker_auto.gd` | Test: at the Stronghold a 300 / 420 player Fire segment becomes 600 / 840 and a gate's max 2 100; repair 0 -> 100 % of an L1 Fire segment costs 5 and takes 7 s; refused 3 s after a hit; an L2 breach rebuilds for 9 in 10.5 s; Packed-Ice gives 650 HP at L1 and cap 32 |
| 18b.C6 | systems-coder | M | Twists (Searing, Frostbind incl. L3 ranged chill, Regrowth stumps with throttled rebake, Verdant / Permafrost batched), gatehouse turrets and corner towers (BuildingGun, damage by level, L3 bolt effects, Thornwatch mending, tower research), Spires / keeps skip `"walls"` | `scripts/buildings/wall_piece.gd`, `wall_network.gd`, `building_gun.gd`, `tower.gd`, `keep.gd` (targeting only) | Test: a Flame Guard hitting an L1 Ember Palisade takes 3 per hit; a Shade hitting an Ice Wall is chilled 2 s; an L1 hedge regrows at 30 % after 60 s with no enemy within 6 m, not while one stays; an L3 Rimewatch chills; a Spire never shoots an enemy wall; `PERF OK` |
| 18b.C7 [H] | gameplay-coder-high | M | Unit: nav layers per team, own `map_get_path` calls with layers, door waiting at a shut own door's link + `repath_now()` when a nearby door opens, wall factor, `siege` tag on 7 units, auto-aggro skip walls unless siege, breach rule with order resume, move-order message hook, Gloomward veil, duels and the door test of 14.1 / 14.3 | `scripts/units/unit.gd`, `data/units/*.tres` (tags), `tests/test_18b_c7.gd` | Test: 5 Flame Guards ordered at a keep behind a closed L1 palisade breach in 11.7 s +-15 % then hit the keep; a move order stops at the wall; 2 Bore Beetles break an L2 segment in 9.3 s +-15 %; a Shade 3 m from an L2 Dusk Wall is invisible to an enemy 8 m away and seen at 4 m; smoke test `victory=true` |
| 18b.C8 | systems-coder | S | Skirmish `walls_enabled` (missions false, legacy Ice Wall), `--no-walls`, CityWall + WallNetwork per team, end-screen line, message signals | `scripts/world/skirmish.gd` | Mission 1 smoke test unchanged; `--no-walls`: no survey, no Walls page, Ice has its old V; end screen shows the walls line |
| 18b.C9 | systems-coder | S | Plug kits, gates, gatehouses, towers, survey, raise and twist VFX hooks (16.1); fog ghosts post + arms only | `scripts/buildings/`, `data/buildings/` | Every piece shows arms, level, damage, site, destroyed; doors swing, lock, hold and jam; survey, raise and the Hands exit play; stumps regrow visibly; headless instantiation without errors |
| 18b.U1 | ui-coder | M | Build menu r2c1 Walls V (all kingdoms) + page (Z / V, X, Back); line ghost (per-cell colours and reasons, counter incl. ring cells, Ctrl lock, Shift chain, snaps to ends and survey); gate ghost; survey glow while the tool is open or the keep is selected; owner raise ghost during a keep upgrade | `scripts/ui/command_card.gd`, `selection_manager.gd`, `scripts/vfx/` (ghosts) | B, V, Z, drag, release places a line on AZERTY; survey cells show `· on the city ring`; nothing in `scripts/ui/` calls a `_private` function |
| 18b.U2 | ui-coder | M | Piece / breach cards (Lock Z / Shift+Z, Hold open X / Shift+X, Repair, Rebuild, Demolish twice), door chips (Auto / Locked / Held / Jammed), the Watch / Hands reward chip with its countdown, double-click selection, panels, keep tooltip lines + `Great Wall rises in` chip, right-click repair / rebuild, HP bar rule, minimap marks and pings, messages, audio, help, skirmish toggle, end screen | `scripts/ui/`, `scripts/ui/menus/`, `assets/audio/wall_*` | Every element of section 13 works with its limits; a ring piece's card has no Demolish and reads `Part of the city wall` |
| 18b.A1 | ai-coder | M | Rules 18a-18f, 18h-18j: reward choice, survey fill (front + main gate), hard pre-build and expansion choke, repair / rebuild, door locks while defending, Rusher / Ice rules, knobs | `scripts/ai/`, `data/ai/` | Normal bot pays for its stone front + main gate by 10:00 in >= 70 % of runs and never traps its own units (0 trapped warnings); it locks its doors while defending; easy pays for no walls; Rusher none before TRANSITION; round D reward mix 30-70 % |
| 18b.A2 | ai-coder | M | Rule 18g: siege mode, gap preference, slip-in through open doors, `find_breach`, army wait; all bot path queries with team layers | `scripts/ai/` | Attack groups reach a walled base in >= 90 % of attacks; none stuck > 20 s at a wall; a group waiting near a door that opens gets in |
| 18b.A3 | ai-coder | S | Harness `--no-walls`, CSV columns (ring level times, gap crystals, breaches, first breach time, bake ms max, trapped count) | `tests/test_18b_a3.gd` | CSV has the columns; the control runs with the flag |
| 18b.V1-18b.V32 | tech-artist (one per row of 16.2) | M (V17-V20 and V25-V32: S) | Kits, gates, gatehouses, towers, survey, VFX, icons | `art/buildings/walls/**`, `art/vfx/wall_*`, `art/icons/walls/` | 40 m silhouette test tells levels and kingdoms apart; heights and budgets of 16.1; 0 lights; hooks in the handoff; previews incl. the L3 Great Wall around a keep |
| 18b.L2 | lead | M | Runs of 14.3 (A, B, C, D, perf) | CI copy | Results in a `balance-2.md` style table |
| 18b.D2 | game-designer | S | Tune with 14.2 (one knob per re-run), write section 18 lines | `docs/design/` | 14.3 passes |

## Done when (step 18b)
- [ ] 18b.C1-18b.C9, 18b.U1-18b.U2, 18b.A1-18b.A3 done-when lists pass; smoke test `victory=true`; perf test `PERF OK` with both L3
  rings and both player caps, bake budget of 11.1.
- [ ] A playtest skirmish: the survey is visible from the start; the Stronghold offers Watch / Hands and gives it; B, V, drag builds a
  wall on the survey; a gate opens for own units and an enemy slips in behind them; Z locks it, X holds it open; the Citadel raises
  the Great Wall around every building near the keep in one moment with no hitch; a worker repairs and rebuilds; each kingdom's twist
  is visible.
- [ ] 14.3 rounds A-D pass (length, rush bands, breach times, door test, reward mix, 0 trapped).

## Questions for the user: all answered (2026-09-26)
1. **Twists** -> ANSWERED: the recommended base set (Fire Searing, Ice Frostbind, Nature Regrowth, Shadow Gloomward), section 7.
2. **What the Stronghold gives** -> ANSWERED: "give free tower or worker": no free wall at level 2; the **Watch or Hands** reward (2.7),
   designed as a choice (recommended over "both, smaller": one clear decision, each option big enough to feel). The Citadel still
   raises the free Great Wall.
3. **Player-built walls** -> ANSWERED: yes, from 3:30 (Ice's Ice Walls from the start), section 4.
4. **Gates** -> ANSWERED: **real doors**: open for own moving units, anyone can slip in while open, Lock / Hold open, section 5.
No open questions. Tuning after the 18b.L2 runs (knobs 14.2): the reward sizes, the door close delay and the jam rule.

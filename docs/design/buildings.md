# Buildings: Fire and Shadow (wave 2)

Source of truth for 2.S1 (grid placement, worker construction), 2.U1 (build menu, placement ghost) and the
wave 3 AI (`ai.md`). Written 2026-09-25 (task 1.D1). Metres and seconds.

## Grid
- Cell size **2.0 m**. World cell `(i, j)` covers `x in [2i, 2i + 2)`, `z in [2j, 2j + 2)`; `i, j in [-30, 29]`
  (map 120 x 120). A footprint of `w x d` cells has its min corner on a cell corner; the building centre is
  `min_corner + (w, d)` (an odd coordinate for 3 x 3, an even one for 2 x 2).
- Existing keeps already sit on the grid: Fire keep centre `PLAYER_START + (-7, 7)` = `(-43, 43)`, 3 x 3.
- The buildable area excludes the outer cell ring (`i` or `j` = -30 or 29).

## Building list (same numbers for both kingdoms; only colour and units differ)
| id (Fire / Shadow) | Display name (Fire / Shadow) | Cost | Build time | max_hp | Footprint | Height | Gives | Trains (keys) |
|---|---|---|---|---|---|---|---|---|
| `fire_keep` / `shadow_keep` | Keep / Dusk Keep | not buildable | - | 1500 | 3 x 3 | 6 | **+20 pop**, crystal drop-off | Worker Z · Set Rally: right-click (button without a key) |
| `fire_barracks` / `shadow_barracks` | Ember Hall / Gloom Hall | 150 | 45 | 900 | 3 x 3 | 4 | crystal drop-off too (`skirmish-1v1.md`) | Fire: Flame Guard Z, Ember Archer X, Blaze Rider C, Ash Hurler V. Shadow: Shade Z, Nightbolt X, Grave Hound C, Shadow Knight V. Set Rally: right-click |
| `fire_hearth` / `shadow_hovel` | Hearth / Hovel | 80 | 25 | 400 | 2 x 2 | 3 | **+10 pop**, max **2** per team (hard cap 40) | - |
| `fire_tower` / `shadow_tower` | Ember Spire / Night Spire | 120 | 35 | 600 | 1 x 1 | 5 | Attack: damage 14 (Shadow 16), range 11, cooldown 1.5, aggro 11, projectile = the kingdom's archer bolt, sight 16 | - |

- The keep trains **only workers** from wave 2; soldiers move to the barracks, training slots 1-4 on keys
  **Z X C V** (slot 5 = B, unused for now). The match starts with **keep only**: the player builds an Ember Hall first (250 start crystals).
- Barracks queue, cancel, rally and spawn rules = the keep's (`economy.md`). Spawn point = the footprint
  corner nearest `MID_CAMP` + 1 m outward; default rally = that corner + 4 m outward (Fire side: `centre +
  (4, -4)` / `centre + (7, -7)`; Shadow side: `centre + (-4, 4)` / `centre + (-7, 7)`).
- Towers pick targets like a unit with `aggro_range` 11, never move, prefer units over buildings.
- `BuildingType` resource (`data/buildings/<id>.tres`): `id`, `display_name`, `faction`, `cost`, `build_time`,
  `max_hp`, `footprint: Vector2i`, `height`, `pop_bonus`, `max_count` (0 = unlimited), `trains: Array[UnitType]`,
  `attack_damage`, `attack_range`, `attack_cooldown`, `sight_radius`, `hotkey_label`, `model_scene`.
  The lead adds `BuildingType` and a `Building` base (`Keep extends Building`) to the contracts.

## Placeholder look (built in code, `model_scene` for later)
| Building | Shape |
|---|---|
| Barracks | Box 6 x 4 x 6 in the kingdom colour darkened x0.7, a `PrismMesh` roof 6 x 1.5 x 6 in the kingdom colour |
| Hearth / Hovel | Box 4 x 3 x 4 `(0.55, 0.45, 0.35)` (Shadow `(0.35, 0.30, 0.40)`), cone roof (`CylinderMesh` top radius 0) height 1.5 in the kingdom colour |
| Tower | Cylinder radius 0.9 height 5 `(0.5, 0.5, 0.55)`, a 0.5 m emissive orb on top in the kingdom colour (bolt colour), the orb blinks 0.1 s on each shot |
| Under construction | Same shapes at alpha 0.35 with `y` scale = `0.2 + 0.8 * progress`; a 2 px wireframe box of the footprint on the ground in the kingdom colour |
| Selected | Same yellow ring as units, radius = half the footprint diagonal + 0.3 |

## Placement rules (2.S1 checks, 2.U1 shows)
A ghost placement is **valid** when all of these hold; the first failing rule is the message shown.
| Rule | Message |
|---|---|
| Every footprint cell is inside the buildable area | `Outside the map` |
| Every footprint cell centre is on the navmesh (`map_get_closest_point` within 0.3 m) | `Not on walkable ground` |
| No cell overlaps another building, construction site or ghost of a queued build | `Blocked` |
| Nearest footprint cell centre is >= **4.0 m** from every crystal node centre | `Too close to a crystal node` |
| No **enemy** unit stands inside the footprint (own units are pushed out on confirm, see below) | `Blocked` |
| Every footprint cell is explored or visible (`fog-of-war.md`) | `Unexplored` |
| `Economy.can_afford(cost)` | `Not enough crystals` |
| Hearth: fewer than 2 built or in construction | `Population limit reached` |
- On confirm: crystals are **spent at once**; own units inside the footprint get `command_move` to the nearest
  point 1 m outside it; a construction site is created (`hp = 10 % of max_hp`, progress 0); the navmesh
  region is **rebaked on a thread** (`bake_navigation_mesh(true)`) so units walk around it. Same rebake when a
  building is destroyed. The smoke and perf tests must still pass with rebakes.
- Buildings are on collision layer 2 (clickable) and group `"buildings"`; a left-click selects the building alone.

## Construction by workers
- Order: select worker(s), press **B** (build menu), then the building's key (**Z** Hearth, **X** Ember Hall,
  **C** Ember Spire), click a valid cell. Every selected worker gets
  `command_build(site)`: walk to the site edge (nearest footprint edge + own radius + 0.3), then build.
- Progress per second = `build_speed / build_time` where `build_speed` = 1.0 for the first worker on site,
  **+0.5 per extra worker, max 3 counted** (1 / 1.5 / 2.0). Workers beyond 3 stand and wait.
- `hp` rises linearly from 10 % to 100 % of `max_hp` with progress. Damage during construction is subtracted
  normally; a site at 0 hp is destroyed (no refund).
- A worker that leaves or dies pauses the site; progress is kept. Any worker can resume (right-click the site).
- Completion: `Events.building_completed(building)`, workers go back to what they did before (gathering the
  same node, else idle at the site edge). Pop bonus applies at completion; a destroyed Hearth removes it
  (`pop_used` may exceed `pop_cap` until units die; no new training meanwhile).
- **Cancel** (site selected, key **Delete**, r1c1): refund **75 % of cost, rounded down**; the site disappears; navmesh rebake.

## Command card slots (physical keys; extends the table in `ui-hud.md`)
| Selection | r1c1 | r1c2 | r1c3 | r1c4 | r2c1 | r2c2 | r2c3 | r2c4 |
|---|---|---|---|---|---|---|---|---|
| Worker(s) | Move M | Stop C | Hold H | Gather G | Build **B** | | | |
| Worker(s), build menu open (after B) | Hearth **Z** | Ember Hall **X** | Ember Spire **C** | Back (Esc / right-click) | | | | |
| Mixed with worker(s) | Move M | Stop C | Hold H | Attack-move X | spells F / Q / E (if wizard, see `spells.md`) | | | Gather G |
| Keep | Cinder Hand Z | Set Rally (no key) | | | | | | |
| Keep (skirmish, tiers on) | Worker **Z** | (tiers) **X** | tier-3 unit **C** | helper **V** | Caster **B** (T2, `caster-units.md`) | | | |
| Ember Hall | Flame Guard Z | Ember Archer X | Blaze Rider C | Ash Hurler V | Set Rally (no key) | | | |
| Hearth, Ember Spire | | | | | | | | |
| Construction site | Cancel **Delete** | | | | | | | |
- The Build button appears only when **every** selected unit is a worker. B swaps the card to the build menu
  (row 1 = the three buildings, the other slots hidden); Esc or right-click brings the normal card back, and
  so does confirming or cancelling a placement. The letters are QWERTY positions (`KEY_B`, `KEY_Z`, `KEY_X`,
  `KEY_C`, `KEY_V`, `KEY_DELETE`); the AZERTY keyboard prints B, W, X, C, V on those keys, as everywhere else.
  Z X C mean different things depending on what is selected (attack-move / stop with soldiers, buildings in
  the build menu, training slots with a building): the card always shows the current meaning.
- Tooltip: `Ember Hall  [X]\nCost 150 crystals · 45 s · 900 HP\nTrains Fire soldiers.` (+ `\nNot enough crystals` when disabled).
- Ghost (2.U1): the building's shape at alpha 0.5, `(0.3, 1.0, 0.4)` when valid, `(1.0, 0.3, 0.3)` when not,
  snapped to the grid under the cursor, plus a flat quad of the footprint cells; the message from the rule
  table is shown above the ghost (font 14). Left-click confirms, right-click or Esc cancels.
  A **selected building** shows its name, HP bar and (barracks / keep) its queue in the selection panel as the keep does today.

## Targeting rules with buildings
- Attack-move and auto-aggro engage **enemy units first**; buildings only when no enemy unit is within
  `aggro_range`. An explicit attack order on a building is always obeyed.
- Wizards, towers and units all use `take_damage(amount, attacker)` on buildings; Fireball and Soul Siphon hit buildings.

## Wave 2 map
The 1v1 map, both bases and the bot's build slots are in `skirmish-1v1.md` and `ai.md` (task 2.D1).

## Done when
- [ ] 2.S1: `BuildingType` resources for the 8 buildings above with those numbers; worker `command_build`; 1 / 1.5 / 2.0 build speed for 1 / 2 / 3 workers; hp 10 % -> 100 %; pop +10 per Hearth, 2 max, cap 40; cancel refunds 75 %; every placement rule refused with its message; navmesh rebaked so units path around a new building; barracks train the 4 soldiers and the keep trains only workers.
- [ ] 2.S1 test: place an Ember Hall (250 -> 100 crystals), 2 workers build it in 30 s +-1, it trains a Flame Guard; a Hearth raises the cap to 30; a 3rd Hearth is refused; cancelling a 120 site refunds 90.
- [ ] 2.U1: worker card shows Build B; B opens the build menu with Hearth Z, Ember Hall X, Ember Spire C and Esc / right-click closes it; ghost green / red with the reason; grid snap; site card shows Cancel Delete; building selection panel shows name, HP and queue; barracks slots train on Z X C V, keep on Z.
- [ ] Nothing in `scripts/ui/` calls a `_private` function.

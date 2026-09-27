# Fog of war (wave 2)

Source of truth for 2.S2 (fog states, grid, minimap) and the fog rules used by spells (`spells.md`) and
placement (`buildings.md`). Written 2026-09-25 (task 1.D1). Only the **player's team** has fog; the AI
(wave 3) knows the map and does not use it.

## States
| State | Ground | Enemy units | Enemy buildings | Crystal nodes | Artifact | Own things |
|---|---|---|---|---|---|---|
| Unexplored | Black (alpha 1.0) | Hidden | Hidden | Hidden | Hidden | n/a |
| Explored (seen once, not now) | Dark tint (black alpha 0.55) | Hidden | **Ghost**: grey copy at the last-seen position | Shown (true current state) | **Always shown** | Shown |
| Visible (in sight now) | Normal | Shown | Shown (ghost removed if the building is gone) | Shown | Shown | Shown |

- Hidden = `visible = false`, not clickable, not selectable, not a valid unit target, not drawn on the minimap.
  Hidden units still simulate normally (they move, fight, mine).
- A hidden enemy that **damages** a player unit or building reveals a 2 m circle around itself for 1.0 s.
- Ghosts: a `MeshInstance3D` copy of the building at alpha 0.5, grey `(0.5, 0.5, 0.55)`, no collision, in the
  group `"fog_ghosts"`; clicking one does nothing. It is deleted when its cell becomes visible again.
- Rules used elsewhere: point / area spells need an explored or visible target; unit spells need a visible
  unit; buildings can only be placed on explored or visible cells (`spells.md`, `buildings.md`).
- Mission start: the circle of radius **20 m** around `PLAYER_START` is visible, the rest unexplored.
- Debug toggle `F11` = fog off (everything visible); `FogOfWar.enabled` false in tests that need it.
  (F10 is surrender since wave 2, `skirmish-1v1.md`.)

## Sight radius (metres, from the unit's position)
| Who | Sight |
|---|---|
| Cinder Hand, Gloom Thrall | 8 |
| Flame Guard, Shade | 10 |
| Ember Archer, Nightbolt, Blaze Rider, Grave Hound | 12 |
| Shadow Knight | 11 |
| Ash Hurler | 14 |
| Vessa, Malrik | 14 |
| Keep | 16 |
| Barracks | 12 |
| Hearth / Hovel | 8 |
| Tower | 16 |
| Construction site (any) | 6 |
| Projectiles, scorch, siphon circles | 0 (reveal nothing) |
Add `sight_radius` to `UnitType` and `BuildingType`. Dead units reveal nothing.

## Grid and update rate (performance for 200 units)
- Grid **60 x 60 cells of 2.0 m** (same cells as the building grid, `x in [2i, 2i+2)`), stored as a
  `PackedByteArray` of 3600 bytes: 0 unexplored, 1 explored, 2 visible.
- Update every **0.2 s (5 Hz)**, not every frame: set every 2 -> 1, then for each living player unit and
  building stamp a circle (`radius / 2` cells around its cell, a precomputed offset list per radius) to 2.
  About 60 stamps of at most ~150 cells each = under 10 000 byte writes per update.
- Enemy visibility: each **enemy** unit/building checks its own cell right after the stamp pass (same 5 Hz
  tick) and sets `visible` accordingly. Ghost creation / removal happens in that same check.
- Rendering: a 60 x 60 `ImageTexture` (R8, 0 / 140 / 255) uploaded once per update, sampled with **linear
  filter** by a shader on a 120 x 120 m quad at `y = 0.25` above the ground (alpha from the table above, so
  edges are soft over about one cell). Units are hidden by `visible`, not by the quad.
- Public API: `FogOfWar.get_state(pos: Vector3) -> int` (0 / 1 / 2), `is_visible(pos)`, `is_explored(pos)`,
  `enabled: bool`, signal `updated` (emitted at 5 Hz, the minimap redraws on it).

## Minimap (adds to `ui-hud.md`)
| Layer | Unexplored | Explored | Visible |
|---|---|---|---|
| Ground | Black `(0, 0, 0)` | Ground colour x0.45 | Ground colour |
| Crystal node | Not drawn | 4 x 4 `(0.45, 0.85, 1.0)` | Same |
| Artifact | Not drawn | 5 x 5 `(1.0, 0.85, 0.3)` **always once explored** | Same |
| Enemy unit | Not drawn | Not drawn | 3 x 3 `(1.0, 0.3, 0.3)`; Malrik diamond |
| Enemy building | Not drawn | 6 x 6 ghost `(0.55, 0.55, 0.6)` | 6 x 6 in the Shadow colour |
| Own units and buildings | Always drawn | | |
- The minimap draws the fog as one 60 x 60 texture scaled to 220 x 220 px, over the ground layer and under the icons (`TextureRect` or `draw_texture_rect`).
- Redraw stays at 10 Hz; fog texture updates at 5 Hz. A minimap click on unexplored ground still moves the camera.

## Done when
- [ ] 2.S2: three states as in the state table; sight radii from the table on `UnitType` / `BuildingType`; 5 Hz `PackedByteArray` update; enemy units hidden and unselectable when not visible; ghosts for buildings; artifact shown once explored; start circle of 20 m; F11 toggle; `get_state` API.
- [ ] 2.S2 test: at start `get_state(PLAYER_START)` = 2 and `get_state(ARTIFACT_POS)` = 0; a Shade placed 30 m away is `visible == false`; after a Flame Guard walks within 10 m it is `visible == true`; after the guard leaves the cell reads 1 and the Shade is hidden again.
- [ ] 2.S2 perf: the perf test still prints `PERF OK` with fog enabled and 200 units.
- [ ] Minimap: fog texture drawn under the icons; enemy units only when visible; artifact once explored.
- [ ] Spells and placement refuse unexplored targets (`Invalid target` / `Unexplored`).

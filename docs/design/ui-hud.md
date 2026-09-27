# UI: HUD layout at 1600 x 900 (wave 1)

Source of truth for 1.U1 (top bar), 1.U2 (command card), 1.U3 (minimap) and the selection panel.
Builds on `scripts/ui/hud.gd`: keep its `_panel` style (bg `(0.06, 0.05, 0.08, 0.78)`, border `(0.75, 0.55, 0.25, 0.8)` 2 px, radius 6, margin 10), `_label` (black outline 4), `_bar`, `show_message`, `show_banner`, `set_objective`.
Positions are pixels from the top-left at 1600 x 900. Anchor top panels to the top and bottom panels to the bottom so other sizes still work.
**Keys (updated 2026-09-25, wave 2 / task 2.U1):** the **Keys** line in `CLAUDE.md` is the key scheme. It
supersedes every older key in `gdd.md` and `units-fire-shadow.md`: W A S D walk Vessa, F / Q / E are her spells,
X attack-move, C stop, H hold, G gather, B build menu, Z X C V B training slots, Delete cancels a site.
Letters W A S D Q E F are never used for anything else.

## Screen map
| Panel | x | y | w | h | Anchor |
|---|---|---|---|---|---|
| Objective (existing) | 16 | 16 | auto | auto | top-left |
| **Top bar** | 640 | 8 | 320 | 40 | top-centre |
| Controls help (existing, text updated) | right edge -16 | 16 | auto | auto | top-right |
| Message line (existing) | centre | 120 | | | top-centre |
| **Minimap** | 16 | 644 | 240 | 240 | bottom-left |
| **Selection panel** | 272 | 660 | 1002 | 224 | bottom |
| **Command card** | 1290 | 660 | 294 | 224 | bottom-right |

The old bottom-left hero panel is removed; its content moves into the selection panel's hero column.

## Top bar (1.U1)
- Panel 320 x 40. Two items, font 20, vertically centred, 48 px gap:
  - Crystal icon: a 16 px diamond (`Polygon2D` or 45° rotated square) in `(0.45, 0.85, 1.0)`, then the number, e.g. `250`.
  - Pop icon: a 16 x 16 white helmet shape (or the text `POP` at font 12 in `(0.8, 0.8, 0.8)`), then `12 / 20`.
- Colours: crystals text `(0.75, 0.92, 1.0)`; pop text white, `(0.95, 0.35, 0.3)` when `pop_used == pop_cap`.
- Failed `spend` flashes the crystal number red `(0.95, 0.35, 0.3)` for 0.4 s and calls `show_message("Not enough crystals")`.

## Command card (1.U2)
- Panel 294 x 224 at (1290, 660). Grid **4 columns x 3 rows**, buttons **64 x 64**, gap 6, top-left of the grid at (1300, 670).
- Button: icon area 64 x 64 (wave 1: a 2-letter abbreviation at font 18, e.g. `AM`, `FB`), hotkey letter bottom-right at font 12 in `(1.0, 0.85, 0.4)`. Selected/pending target order: border `(1.0, 0.85, 0.4)`.
- Disabled: `disabled = true`, modulate alpha 0.45, tooltip gains a third line with the reason.
- Tooltip (`tooltip_text`), format:
  - Orders: `Attack-move  [X]\nMove and fight anything met on the way.`
  - Training: `Flame Guard  [Z]\nCost 90 crystals · Pop 1 · 18 s\nMelee line unit.` (+ `\nNot enough crystals` / `\nPopulation cap reached` when disabled)
  - Fireball: `Fireball  [F]\n40 mana · 60 damage · radius 3.5\nBurns everything in the circle.` (+ `\nNot enough mana`)
- Slot layout (row, column). Empty slots are invisible. Wave 2 keys; the building rows are in `buildings.md`.
| Selection | r1c1 | r1c2 | r1c3 | r1c4 | r2c1 | r2c2 | r2c3 | r2c4 |
|---|---|---|---|---|---|---|---|---|
| Worker(s) | Move M | Stop C | Hold H | Gather G | Build B (opens the build menu, `buildings.md`) | | | |
| Soldier(s) | Move M | Stop C | Hold H | Attack-move X | | | | |
| Wizard | Move M | Stop C | Hold H | Attack-move X | Fireball F | Ember Step Q (wave 3) | Kindle E (wave 3) | |
| Mixed units | Move M | Stop C | Hold H | Attack-move X (if any soldier) | spells F / Q / E (if wizard) | | | Gather G (if any worker) |
| Keep | Cinder Hand Z | Set Rally (button only; right-click does the same) | | | | | | |
| Nothing | | | | | | | | |
- Pressing a targeted button (Move, Attack-move, Gather, Fireball, Set Rally) shows the cross cursor; left-click confirms, right-click or Esc cancels (reuse the Fireball targeting flow). Hold and Stop apply at once. Attack-move then a click on an enemy = plain attack.
- Hotkeys are physical keycodes (`KEY_X` etc.) handled by `SelectionManager`; the card only mirrors them. Letters shown are QWERTY positions (the user's AZERTY keyboard prints other letters; that is expected). Move keeps M (a free letter); there is no A key any more (A walks Vessa).
- **W A S D** walk Vessa whatever is selected (`Wizard.set_move_input`, camera-relative: W = away from the camera, S = toward it, A / D = left / right); the camera follows her while a key is held and stops following on release. Vessa's walking never changes the selection.

## Selection panel
- Panel 1002 x 224 at (272, 660). Two columns: **hero column** 300 px on the left (always visible), a 2 px separator, **selection area** 680 px.
- Hero column (replaces the old hero panel): name font 20, HP bar 22 px red `(0.8, 0.2, 0.2)` with `HP  350 / 350`, mana bar 22 px blue `(0.25, 0.45, 0.95)` with `Mana  100 / 100`. Click the name = select the wizard. Dead wizard: bars at 0, name greyed.
  Wave 3 (`levels.md`, 3.U1): level badge at (282, 670), name at x 318, XP bar 280 x 16 at (282, 762), spell-points chip at (492, 784); spell buttons get rank pips and a `+` learn chip; the single-unit view shows `Level n` for wizards and `Veteran / Elite / Champion` + `XP x / y` for soldiers; multi-select icons get 1-3 gold dots.
- Selection area:
| Selection | Shows |
|---|---|
| Nothing | `Nothing selected`, font 16, centred |
| 1 unit | Name font 20; HP bar 280 x 22 with `HP x / y`; one line font 14: `Damage 12 · Range 1.6 · Speed 5.0`; for the wizard also its mana bar |
| 2+ units | Grid of 48 x 48 icons, 4 px gap, 12 per row, max 2 rows (24). Each icon: unit abbreviation + a 4 px HP strip under it (green > 50 %, yellow > 25 %, red). Click an icon = select only that unit. Header line font 14: `9 selected:  5 Flame Guard, 4 Ember Archer` (existing format) |
| Keep | Name `Keep`, HP bar; then the **training queue**: 5 slots 48 x 48 in a row, slot 1 with a 48 x 6 progress bar under it in `(1.0, 0.85, 0.4)`; click a slot = cancel it; text `Rally: set` / `Rally: gather node` |

## Minimap (1.U3)
- Panel 240 x 240 at (16, 644); draw area 220 x 220 at (26, 654). World 120 x 120 m -> 1 px = 0.545 m; world x -> right, world z -> down, `MAP_SIZE / 2` at the centre.
- Redraw at 10 Hz (`_draw` with a 0.1 s timer), not every frame.
| Layer | Look |
|---|---|
| Ground | Fill `(0.20, 0.30, 0.15)`; tree and rock obstacles as 2 x 2 px `(0.13, 0.30, 0.14)` / `(0.46, 0.44, 0.42)` (optional in wave 1) |
| Crystal node | 4 x 4 px `(0.45, 0.85, 1.0)` |
| Keep | 6 x 6 px square in the team colour |
| Artifact | 5 x 5 px `(1.0, 0.85, 0.3)` |
| Own unit | 3 x 3 px `(0.3, 1.0, 0.4)`; selected units 4 x 4 |
| Own wizard | 6 x 6 px diamond `(1.0, 0.85, 0.3)` |
| Enemy unit | 3 x 3 px `(1.0, 0.3, 0.3)`; Malrik 6 x 6 diamond `(0.8, 0.4, 1.0)` |
| Camera | Project the 4 viewport corners on the ground and draw that quad, 1 px white `(1, 1, 1, 0.8)` |
- **Left-click / left-drag**: `camera_rig.focus_on(world_point)`.
- **Right-click**: `selection.formation_move(world_point)` for the current selection (plain move; gather if the click lands within 3 m of a node and workers are selected). Marker as for a ground order.
- Fog of war comes in wave 2; draw everything in wave 1.

## Control groups (1.G2 logic, HUD shows nothing new in wave 1)
- `Ctrl + 1..9` assigns the current selection to the group (replaces). `Shift + 1..9` adds to the group.
- `1..9` selects the group. A second press of the same key within **0.4 s** centres the camera on the group's average position.
- Dead units leave their group. The keep can be in a group. Physical keys `KEY_1`..`KEY_9` on the number row (no numpad needed).

## Controls help text (top-right, font 13), replace the existing lines with
```
Left click / drag: select    Shift: add    Double-click: all of a type
Right click: move / attack / gather / rally    X: attack-move    C: stop    H: hold    G: gather
W A S D: walk Vessa    F / Q / E: spells    B: build (workers)    Z X C V B: train    Delete: cancel a site
Ctrl+1-9 / 1-9: groups    F1: Vessa    Space: find Vessa    F9: restart    F10 twice: surrender
Arrows / edge: pan    Wheel: zoom    Middle drag: rotate
```

## Done when
- [ ] 1.U1: top bar at (640, 8) shows crystals and `12 / 20` at start, updates on `Economy.changed`, red at cap, flashes on failed spend.
- [ ] 1.U2: card at (1290, 660), 4 x 3 of 64 px; the slot table above holds for worker / soldier / wizard / mixed / keep / nothing; hotkey letters printed; disabled state + reason tooltip; Fireball button no longer in a hero panel.
- [ ] 2.U1: X / C / H / G / M act by physical keycode with units selected; A, S, W, D, Q, E, F never trigger an order or a training slot; W A S D walk Vessa and the camera follows while held; the help text is the block above; the card letters match the slot table; Keep shows `Cinder Hand Z`.
- [ ] 1.U3: minimap at (16, 644) with the colours above; left-click moves the camera, right-click moves the selection; camera quad drawn; 10 Hz.
- [ ] Selection panel: hero column always visible; single / multiple / keep views as in the table; queue slots cancel on click.
- [ ] Nothing in `scripts/ui/` calls a `_private` function of another script.

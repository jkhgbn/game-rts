# UI: the console HUD (SC2-style layout, 2026-10-13, JS: "a ui more like sc2")

Source of truth for tasks **SC2.U1-U6** (ui-coder). Only the **layout conventions** of a modern RTS console are borrowed: one
continuous bottom console, resources top-right, hero / idle buttons left of the minimap, 5 x 3 command card, portrait window.
Art, icons, fonts, names and shapes stay ours: every token, frame, bar, tooltip and animation of `ui-style.md` is unchanged.
Pixels are **virtual px at 1600 x 900** (`content_scale_factor`, ui-champions.md 2). Scale: **x1.2 at 1920 x 1080, x1.6 at
2560 x 1440 and 3440 x 1440** (the console's middle stretches on ultrawide, nothing else changes). Console height 216 px = 24 %.

## 1. Screen map (virtual px; anchor = what stays put when the window changes)
| Zone | Rect @1600 | @1080p | Anchor |
|---|---|---|---|
| Top-left buttons: Menu, `?`, Team (2v2 only) | 28 x 22 each at (8, 8), gap 4 | 34 x 26 | top-left |
| Objectives (mission text) | (8, 36), width <= 420, collapsible to its 1 header line | | top-left |
| Next hint (`NextStepHint`) | under the objectives, same width | | top-left |
| Map-fill strip / blessing chips / beast bars | y 8 / y 10, 34 / y 112, 168 (x as ui-mapfill.md: only y moves up) | | top-centre |
| Message line / banner | y 120 / centre (unchanged) | | top-centre |
| **Resources** | 4 items 96 wide, 32 tall, right edge x 1592, y 8 (`(1208, 8)` with gold, `(1304, 8)` without) | x 1.2 | top-right |
| Tier chip (`TierChip`) | under the resources, right edge 1592, y 44, auto x 24 | | top-right |
| Team panel (2v2) | 240 x 194 at (1344, 296) (unchanged) | | top-right |
| **Alert stack** | 36 x 36 at (8, 340 - 40 i), i = 0-4, newest at the bottom | 43 | bottom-left |
| **Champion slots** x3 | 240 x 52 at (8, 380), (8, 436), (8, 492) | 288 x 62 | bottom-left |
| **Hero tile** (wizard + inventory) | 240 x 100 at (8, 548) | 288 x 120 | bottom-left |
| **Quick row** | Idle F3 36 x 36 at (8, 648), Army F2 at (48, 648); match clock font 16 right-aligned to x 244 at y 658 | | bottom-left |
| **Control group bar** | tabs 56 x 32 from x 252, y 652, gap 4 (only groups that exist) | 67 x 38 | bottom-left |
| **Console frame** | full width, y 684-900 (216 tall), content margin 8 -> inner y 692-892 | 259 tall | bottom, stretches |
| Minimap zone | draw area 200 x 200 at (14, 692); divider x 232-236 | 240 | bottom-left |
| Selection block | x 244-1132, y 692-892 (888 x 200); on ultrawide its right edge follows the portrait zone | | left + right |
| Divider / **Portrait window** | divider x 1136-1140; portrait 136 x 136 at (1144, 696); status slate 136 x 44 at (1144, 840) | 163 | bottom-right |
| Divider / **Command card** | divider x 1284-1288; grid **5 x 3** of 56 px, gap 4, top-left (1292, 704) -> 296 x 176 | 67 px buttons | bottom-right |
Removed from the default screen: the top-centre bar, the top-right help block, the old hero column, the 240 x 228 champion bar.
The hero column's inventory, XP, points chip and status chips move to the hero tile (3.1) and the wizard's selection view (4.2).

Frame: ONE `PanelContainer` with the heavy frame (ui-style 3.1), drop shadow, studs only at the two top corners; dividers =
2 px `groove` + 1 px `frame_light` with the 6 x 6 diamond at each end (5.1). Ultrawide: the selection block widens, its
content stays left-aligned, the empty right part shows the kingdom emblem at alpha 0.06 (5.1). UI Lab gap check: one control.

## 2. Top
- **Resources** (`top_bar.gd`, now right-anchored, no slab): per item icon 16 px + number font 20 embolden 0.5, order
  crystals, essence, gold (only with a `GoldBank`), pop `12 / 20`. Bg: slate 3.2 per item (quiet). Pop at cap: number `WARN` +
  the item's slate border `WARN` pulsing alpha 0.4-0.9 at 2 Hz for 3 s on every refused `spend` ("supply-blocked flash"); the
  failed-spend shake and `Not enough crystals` message stay. Hover each item = tooltip (`Crystals: mined by workers` etc.).
- **Clock** (`0:00`, hourglass glyph) moves to the quick row (section 1); Wave Strike keeps its top strip clock.
- **Menu** button: a 3-bar glyph, tooltip `Menu  [F10]`, opens the pause menu. **`?`**: tooltip `Controls  [K]`, toggles the
  **help overlay**: the existing `help_text()` lines in a slate 480 x auto at (560, 140), font 13, title `Controls` Cinzel 16,
  closes on `?` / K / Esc / click outside. Key **K** (physical, free; F1 stays "select Vessa"). **Team** (2v2 only): ping wheel /
  chat as ui-2v2.md. Objectives: header row with a `v` / `>` glyph 12 px; click toggles; state kept for the match.

## 3. Left stack (bottom-left, SC2's hero / idle corner)
### 3.1 Hero tile 240 x 100 (`hero_tile.gd`, replaces the hero column; button, slate bg, kingdom `trim_glow` aura 5.1)
| Part | Rect in tile | Look |
|---|---|---|
| Portrait | 48 x 48 at (4, 4) | The `Portrait` viewport texture at 48 px (same SubViewport, second `TextureRect`) or the wizard icon; level medallion 20 px (5.2 look) over its bottom-right corner; `F1` badge 20 x 12 at (32, 2) |
| Name | (58, 4), width 140 | `wizard_short_name` Cinzel 15 `title`; dead: `text_muted` + `returns in 24 s` font 11 `WARN` at (58, 18) |
| HP / mana / XP | 140 x 12 at (58, 24), 140 x 12 at (58, 38), 140 x 6 at (58, 52) | Bar 5.3, text font 10 `350 / 350` on HP and mana only; low-HP pulse kept |
| Points chip | 36 x 14 at (162, 50) | Gold, `+2` font 11, pulse (unchanged); hidden at 0 |
| Items 1-6 | 32 x 32 at (2 + 33 i, 64) | `InventoryBar` slots (6.3 look at 32 px: icon 28, key digit font 9, cooldown sweep); numpad 1-6 / click as today |
| Artifacts | 32 x 32 at (204, 4) and (204, 38) | Artifact slots (6.3) |
Click the tile = select the wizard; double-click = centre (Space does too). Drag / drop / shop interactions of `InventoryBar` unchanged.
### 3.2 Champion slots 240 x 52 (compact `ChampionBar`): portrait 44 at (4, 4), level medallion 18, name Cinzel 13 at (54, 4),
HP bar 150 x 10 at (54, 22), intent line font 11 `text_muted` at (54, 36) (`Guarding the keep`), key badge `F5-F7` at (210, 4).
Empty: `+ Hire a champion` font 12 + `Y · tavern` / `Tavern opens at 2:00` (texts unchanged). Fallen: as ui-champions.md 3.
### 3.3 Quick row and alerts
- Idle worker button (existing, 36 px): worker glyph, count badge bottom-right font 10, `F3` badge; Ctrl+click all. Army button:
  sword glyph, army count badge, `F2` (Shift+click adds). Both hidden when the count is 0 (SC2 convention).
- **Alerts** (`alert_stack.gd`): 36 x 36 slate tiles, 1 px border in the alert colour, glyph 24 px: under attack (`WARN`,
  crossed swords), building done (`GOLD`, hammer), tier reached (`GOLD`, crown), champion fallen (`WARN`, skull), horn / wave
  (`trim_glow`, horn), hunt bounty on you (`WARN`, coin). Max 5, each fades after 12 s, same source merges (count badge). Click =
  `camera_rig.focus_on` the place; tooltip = the message. Every alert also pings the minimap (3 `WARN` rings 0.9 s, existing).

## 4. Console: selection block, portrait, command card
### 4.1 Control group bar (`control_group_bar.gd`): tab = key digit badge 12 x 12 top-left, 24 px icon of the most common
unit at (16, 4), count font 13 right; active tab gold rim + 2 px gold line (4.2 look). Buildings allowed (Tab cycles, unchanged).
### 4.2 Selection block views (x from 252, y from 696; rects inside the block)
| View | Layout |
|---|---|
| Nothing | `Nothing selected` font 16 `text_muted` centred; emblem alpha 0.06 |
| 1 unit | Name Cinzel 20 at (252, 696) + ` · Veteran` font 14 `text` + gold chevrons; HP bar 300 x 20 at (252, 724); mana (wizard, caster) 300 x 20 at (252, 748); **stat table** 2 x 2 font 14 at (252, 776): `Damage 12`, `Armor 2`, `Range 1.6`, `Speed 5.0` (glyph 12 px `text_muted` + number `text`); right part x 580: level medallion 28 + `Level 3` / `Veteran` Cinzel 16, XP bar 240 x 12 at (580, 724) `XP 320 / 450`; status chips 40 x 20 from (580, 748) (5.2 look); wizard adds the points chip + `Ctrl+F / Q / E: learn` font 12 `text_muted` at (580, 776). Champions / beasts / critters / posts / points: their inspect texts (ui-champions 4, ui-mapfill 4-7, ui-trade 9) in the same rects |
| 2+ units | **Type tabs** row at y 696: one tab 24 tall per type (icon 20 + count font 12), active = gold rim (the Tab key's subgroup); header `9 selected` font 13 `text_muted` right; grid of **40 x 40** icons at (252, 728), gap 4, **16 per row x 3 rows** (48 max; `+ 12 more` chip after). Icon = slot frame whose **rim colour follows HP**: green `(0.3, 0.85, 0.35)` > 50 %, yellow `(0.95, 0.8, 0.3)` > 25 %, else `WARN`; 3 px HP strip at the bottom; mana strip 2 px above it for casters; 1-3 gold dots; click = select that unit, Shift+click = remove it, click a tab = that type only |
| Building (keep, Hall, barracks...) | Name, HP bar as 1 unit; **queue** 5 slots 44 x 44 at (252, 776), gap 4, slot 1 progress 44 x 6 gold under it, `x` on hover (cancel kept); right part x 580: **tier line** `Stronghold rising` + bar 240 x 12 at (580, 724) (`TierSystem.status`), else `Tier 1 · next Stronghold 400` font 13; `Rally: set / gather node` font 13 at (580, 748); Bazaar block / post panel / flag card draw over x 252-1124 as today |
| Construction site | Name, progress bar 300 x 14 gold at (252, 724), `Cancel  [Delete]` button 150 x 32 at (252, 748) (WARN rim) |
### 4.3 Portrait window (136 x 136 at (1144, 696))
The existing `Portrait` SubViewport (ui-style 7.2) drawn at 136 px (viewport 192 x 192, `msaa_3d 2x`, 30 Hz while visible):
the selected thing's model kit instance (unit `model_scene` / building / champion with `set_weapon_class` / beast variant);
multi-select = the active type tab's unit. Button frame rim: own normal, enemy `(0.85, 0.30, 0.30)`, neutral `frame_dark`;
dead dimmed, low-HP vignette. Click the portrait = centre the camera on it (double-click selects all of that type on screen).
Status slate under it: team / kingdom line font 12 (`Fire · yours`, `Shadow · enemy`, `Neutral`) + `Pop 2` font 12 `text_muted`.
### 4.4 Command card 5 x 3 (`command_card.gd`: `COLUMNS 5`, `BUTTON_SIZE 56`, `GAP 4`, icon 48 inset 4)
- Keys by **grid position** (physical, labels through `KeyLabels.of`): row 1 = `Z X C V B`, row 2 = `N M , . /`, row 3 =
  context (Set Rally r3c1, Back `Esc` r3c5, `+` page r3c5 on Halls). Orders keep their own letters (M C H X/A G) on row 1,
  spells F / Q / E on row 2 c1-c3, caster spells Z / V on row 2 c1-c2, Build B row 3 c1. Every existing card of ui-hud.md
  "Every button shows its own key" keeps its **letters**; only slot indices move (4 -> 5 columns): `CASTER_SLOTS [5, 6]`,
  `RALLY_KEEP_SLOT 10`, `PLUS_SLOT 14`, `BUILD_KEY_SLOTS` Z X C V B -> 0-4, N M -> 5-6, Back -> 14.
- Key badge **18 x 14 at (36, 40)** (bottom-right corner, 6.2 look); cost tag 26 x 12 at (2, 42); pips / `+` chip unchanged.
- States: normal / hover / pressed / disabled (`modulate.a 0.45` + reason line) / selected-pending (gold pulse) as 3.3;
  cooldown = radial sweep + seconds (6.2); autocast = slowly turning gold border (caster-units.md); "do this now" breathing
  gold rim (tier button); locked = lock glyph 12 px over the icon + `Requires Stronghold` in the tooltip.
- Wizard selected: the three spell buttons also show the mana cost tag (blue `MANA` text) instead of crystals.

## 5. Tooltips (custom tooltip, ui-style 8; `tooltip_text` strings unchanged, the renderer parses them)
| Row | Content | Look |
|---|---|---|
| 1 | `Flame Guard` + key badge right-aligned + `Rank 2 / 3` | Cinzel 15 `title`; badge 18 x 14 gold |
| 2 | Cost line rendered as **icons + numbers**: `Cost 90 crystals · Pop 1 · 18 s` -> diamond 12 px `90`, shield `1`, hourglass `18 s`; `40 mana` -> drop glyph `MANA` colour; essence flame; gold coin | Font 13, numbers in their currency colours, `WARN` when short |
| 3 | Description | Font 13 `text_muted`, max width 320, wraps |
| 4 | Requirement / reason: `Requires Stronghold`, `Not enough crystals`, `Population cap reached`, `Not learned` | Font 13 `WARN`; learn hints (`Ctrl+F: rank 3 = ...`) gold |
Appears after 0.25 s, 8 px above the control, clamped on screen. Unit icons in the multi-select grid: `Name · HP x / y` (+ `Mana`).

## 6. What moves where (every function kept)
| Thing | Was | Now |
|---|---|---|
| Top bar (crystals, pop, timer, essence, gold) | 624 x 40 top-centre | Resources top-right (2) + clock in the quick row |
| Controls help | top-right block, always on | `?` button / **K** overlay; `help_text()` kept; pause menu "Controls" too |
| Tier chip / NextStepHint | under the top bar / objective | under the resources / under the objectives |
| Hero column (name, bars, XP, points, chips, inventory) | 300 px of the selection panel | Hero tile 3.1 (bars, XP, points, items) + wizard view 4.2 (chips, learn hint) |
| Champion bar 240 x 228 | (16, 408) | Three 52 px slots 3.2; F5-F7, Y, bounty texts unchanged |
| Minimap 220 draw | (26, 654) | 200 draw at (14, 692); layers, zoom, clicks, idle button (now in the quick row) unchanged |
| Portrait 96 | inside the selection area | Portrait window 136 (4.3), one SubViewport |
| Command card 4 x 3 of 64 | (1290, 660) | 5 x 3 of 56 at (1292, 704); letters unchanged, indices remapped (4.4) |
| Group tabs 64 x 36 at y 620 | | 56 x 32 at y 652 |
| Map-fill strip, blessing chips, beast bars | y 52 / 54 / 156 | y 8 / 10 / 112 (top-centre is free) |
| Bounty mode, flag card, post / point panels, Bazaar block | over the selection area | same, in the selection block (x 252-1124, y 696-888) |
| Shop / tavern / trade windows, end screen, score tab | fixed windows | unchanged (tavern / trade bottom edge y 620 < 652) |
| STR / INT panel, Wave Strike top strip, 2v2 team panel, pings | | unchanged |
- **Wave Strike** (ui-wave-strike.md 1): the Muster panel loses its own frame and fills the console's selection + portrait + card
  zones, x 244-1588, y 692-892: every rect of its sections 1-3 with **x - 346, y + 20**, supply bar 14 tall at y 856, hint
  line font 11 at y 874; its right column x 1416-1576 (unchanged x: the extra width sits between the cards and the column). The
  skirmish command card and portrait are hidden in WS; hero tile and champion slots stay as 3.1 / 3.2.
- Tests that read rects (`tests/test_6_u1.gd`, `test_9_c7`...) are updated by ui-coder to the new rects; tests that read
  letters, tooltip strings, `modulate.a 0.45`, `COLUMNS`-independent slot letters pass unchanged.

## Tasks for ui-coder, in order (done when)
- [ ] **SC2.U1** Console frame + zones (1): one framed `PanelContainer` at y 684-900, dividers, minimap at (14, 692), selection
  block, portrait window 136 (4.3), card 5 x 3 of 56 with remapped indices (4.4) and the old top bar / help / hero column / big
  champion bar hidden; UI Lab `hud`, `hud_keep`, `hud_caster` at 1600 x 900, 1920 x 1080, 3440 x 1440 with **no FAIL** (no
  gap, no overlap, no font under 9 px); `test_ui_card_hotkeys`, `test_ui_train_queue`, `test_ui_select_hotkeys` pass.
- [ ] **SC2.U2** Top (2): resources top-right with the supply-blocked flash, clock in the quick row, tier chip and hint moved,
  Menu / `?` / Team buttons, help overlay on `?` / K / Esc, collapsible objectives; map-fill strip and beast bars at their new y.
- [ ] **SC2.U3** Left stack (3): hero tile with bars, XP, points, 6 + 2 item slots (numpad keys, drag, shop sell still work),
  compact champion slots (F5-F7, hire texts), Idle / Army buttons hidden at 0, alert stack with 6 kinds + minimap pings;
  `test_ui_tavern_open_time`, the inventory and champion tests pass.
- [ ] **SC2.U4** Selection views (4.1-4.2): group tabs 56 x 32, stat table, level / XP / chips on the right, type tabs +
  HP-rimmed 40 px grid (48 max), building queue + tier line + rally, construction site; `test_ui_building_groups` passes.
- [ ] **SC2.U5** Tooltips (5) + card states (4.4): cost line as icons, requirement row in `WARN`, mana tag on spells, lock glyph;
  every `tooltip_text` string unchanged (`test_ui_card_hotkeys` tooltips).
- [ ] **SC2.U6** Wave Strike Muster inside the console (6) with WS2.U1; UI Lab `ws_buy` no FAIL at 1080p / 1440p.
- [ ] All: French (`-- --lang=fr`) fits every label (autowrap / shrink rules of ui-wave-strike.md 1.1 where text is long);
  `tests/test_ui_*.gd` pass; `PERF OK` with the portrait on screen.

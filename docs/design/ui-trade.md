# UI: gold, Bazaar, caravans, trading posts and the guilds (step 10, task 10.D2)

Written 2026-09-26. Source of truth for **10.C7** (build menu B, Bazaar and caravan cards and panels, G trade,
right-click post / Bazaar, route line + hover preview, post / guild click signal, minimap layers) and **10.C8** (top-bar
gold, trade window U with the Bazaar and Lodge tabs, tavern gold buttons, post / Den / Lodge panels, messages, floating
delivery text, audio, settings toggle, help text). It lays out every element of `market-trade.md` section 8 with the
skin of `ui-style.md` (tokens, fonts, frames, bars, tooltips) and moves **nothing** that `ui-hud.md`, `ui-style.md` or
`ui-champions.md` already place, except the top bar (it widens, section 3) and the controls-help text (it is reflowed,
section 14). Gameplay numbers, strings and contracts come from `market-trade.md` (sections 2-6, 8, 12); when this file
repeats one it is only so a coder does not have to look it up. If they ever disagree, `market-trade.md` wins for
gameplay, this file for pixels.

Conventions: as `ui-champions.md`. Pixels from the top-left at **1600 x 900** (virtual pixels, section 2); `(x, y)` =
top-left corner, `w x h`; colours are the `UIStyle` tokens (`title`, `text`, `text_muted`, `frame_metal`,
`frame_light`, `frame_dark`, `groove`, `trim_glow`, `panel_bg`, `panel_inner`, `slate_bg`) or the shared constants
`GOLD (1.0, 0.85, 0.4)`, `WARN (0.95, 0.35, 0.3)`, `HP`, `ESSENCE` / `ESSENCE_TEXT`, `CRYSTAL` / `CRYSTAL_TEXT`, plus
the new ones of section 16 (`GOLD_COIN (1.0, 0.78, 0.25)`, `GOLD_TEXT (1.0, 0.88, 0.5)`, `NEAR`, `FAR`, `OWNED`...).
"Cinzel n" = `UIStyle.display_label` at size n (uppercased display font); "font n" = the body font at n; "number font"
= `UIStyle.number_label` (embolden 0.5); "slot frame" = `UIStyle.button_frame` (3.3); "heavy frame" =
`UIStyle.frame_style`; "slate" = `UIStyle.slate_style`; "bar" = `UIStyle.bar`; "primary button" = the tavern's
`TavernWindow.style_primary` (trim_glow rim, tinted inside); "stud X" = the shop's round close button (6.4).
Both coders build their controls in code like the rest of `scripts/ui/` (no `.tscn`). Every text width quoted below was
measured with the project's fonts (`Font.get_string_size`), so the "fits" claims are real.

Other step-10 classes (`GoldBank`, `TradeNetwork`, `TradePost`, `GuildHouse`, `Market`, `Caravan`, `LootSack`,
`ThievesGuild`, `HuntersGuild`, `TrackerContract`) are reached **untyped**: groups (`"gold_banks"`, `"trade_network"`,
`"trade_posts"`, `"guilds"`, `"caravans"`, `"magpies"`, `"trackers"`, `"loot_sacks"`, `"thieves_guild"`,
`"hunters_guild"`, `"tracker_contracts"`), `load()` guarded by `ResourceLoader.exists`, `get()`, `has_method()`. When a
part is missing the UI shows its empty / disabled look and never errors.

---

## 1. Where everything goes

### 1.1 Screen map (existing panels unchanged unless marked; new ones in bold)
| Panel | Rect at 1600 x 900 | Anchor | Owner |
|---|---|---|---|
| Objective (skirmish) | (16, 16), auto: 511 x 70 with the 2-line skirmish text (the long line is 491 px at font 17) | top-left | existing |
| **Top bar** | **624 x 40 at (488, 8)** with gold (500 x 40 at (550, 8) when trade is off, as today) | top-centre | 10.C8 (section 3) |
| **Controls help** | right edge x 1584, y 16; **458 x 229** after the reflow to 11 lines of <= 438 px (section 14) | top-right | 10.C8 (`hud.gd`) |
| Message line | centred, y 120 (pushed under the help panel only when the text would touch it: messages wider than about 640 px) | top-centre | existing |
| Champion bar | 240 x 228 at (16, 408) | bottom-left | step 9 |
| Control group tabs | 64 x 36 from x 272, y 620-656 | bottom | existing |
| Minimap | 240 x 240 at (16, 644); draw area 220 x 220 at (26, 654) | bottom-left | existing (10.C7 adds layers, section 8) |
| Selection panel | 1002 x 224 at (272, 660); area content x 588-1264, y 670-874 | bottom | existing (10.C7 adds the Bazaar block, caravan and tracker lines) |
| Flag card | 676 x 204 at (588, 670) | bottom | step 9 |
| **Post / Den / Lodge panel** | **676 x 204 at (588, 670)**, drawn over the selection area like the flag card | bottom | 10.C8 (section 9) |
| Command card | 294 x 224 at (1290, 660); buttons 64 at (1300 + 70 c, 670 + 70 r) | bottom-right | existing (10.C7 adds the slots, section 4-6) |
| **Trade window** | **760 x 464 at (420, 156)**, the tavern window's rect (never open together) | fixed | 10.C8 (section 10) |
| Tavern window | 760 x 464 at (420, 156) | fixed | step 9 (10.C8 adds the gold buttons, section 11) |
| Shop window | 640 x 440 at (480, 200) | fixed | existing |
| **Route preview chip** | follows the mouse at mouse + (18, 12), height 26 (the bounty chip's style) | none | 10.C7 (section 7) |
| **Floating `+28`** | `Label3D` in the world above the Bazaar | world | 10.C8 (section 12) |

### 1.2 Free space measured from the code (why things go where they go)
- **Top**: `top_bar.gd` centres its row on x 800: 500 wide today (x 550-1050). The help slate is right-anchored at
  x 1584 and its widest line (line 8, added in step 9) measures **571 px** at font 13, so the panel is 591 px wide and
  starts at **x 993: it already overlaps the top bar by 57 px** (y 16-48). Adding the gold item makes the bar 624 wide
  (x 488-1112), so the help text is reflowed into 11 lines of at most 438 px (panel 458 wide, x 1126-1584, section 14):
  8 px clear of the bar. On the left the objective slate ends at x 527, its first line (`Skirmish: Crown Hollow`, 195 px)
  is the only one at the bar's height (y 26-46; the 491 px second line starts at y 49, under the bar's bottom edge 48).
- **Bottom centre** is full (dialogue box x 480-1120 to y 610, group tabs y 620-656, selection panel y 660-884): the
  Bazaar's extra lines go **inside the selection area**, in the empty right part x 1000-1264 that the keep view never uses
  (its queue row ends at x 966) and that the champion view uses for abilities.
- **Selection area** x 588-1264, y 670-874: the post / Den / Lodge panel paints over it exactly like the flag card.
- **Command card**: the keep view uses r1 only (training slots + rally); the Bazaar uses r1 (Caravan, Set Route, Wares)
  and r2 (the 4 route buttons); r3 stays empty. The build menu has r2c2 free (r2c1 = Ice Wall V).
- **Windows**: the shop, the tavern and the trade window share the centre and are exclusive (opening one closes the
  others); the trade window reuses the tavern rect so its title bar, rows and footer align with what the player knows.
- **Left column**: the champion bar (y 408-636) and minimap are untouched; nothing new goes there.

### 1.3 Full screen with the Bazaar selected (1 character = 16 x 20 px; rows are 20 px)
```
     0         1         2         3         4         5         6         7         8         9
     0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
  0                               <1 250   POP 12 / 20   7:42   ~ 140   (o) 2 140>                          
  1   +-objective---------+                                                  +-controls help (11 lines)---+
  2   | Skirmish: Crown H.|                                                  | Left click / drag: select  |
  3   | Destroy every ... |                                                  | Right click: move / ...    |
  4   +-------------------+                                                  | H: hold  G: gather  B: ... |
  5                                                                          | Delete: cancel a site ...  |
  6                  Saltgate is held by the enemy: your caravans wait       | Ctrl+F/Q/E: learn spell... |
  7                                        (message line, y 120)             | Groups 1-0: Ctrl set ...   |
  8                                                                          | F2: army  F3: idle ...     |
  9                                                                          | Arrows / edge: pan ...     |
 10                                                                          | R: bounty ...  Y: tavern   |
 11                                                                          | Flag: Z raise ... U: trade |
 12                                                                          | B, B: Bazaar  Bazaar: Z .. |
 13                                                                          +----------------------------+
 ..                                   (3D battlefield: the dashed gold route ribbon from the Bazaar to the post)
 20   +-champion 1-------+
 ..   |  ...             |
 31   +------------------+ [1 5FG] [2 3EA]                       (group tabs y 620-656)
 32   +-minimap----------+
 33   | roads, posts P   | +-selection panel----------------------------------------------+ +-command card----+
 34   |  D  o caravans   | | (3) VESSA          | [portrait] EMBER BAZAAR      Route: Millstone Cross (near) | | [CV][RT][WR][ ] |
 35   |    (o)   L       | | HP  350 / 350      | HP  1000 / 1000              28 gold per trip · ~56 / min  | | [HF][MC][SG][LW]|
 36   |  P   route ---   | | Mana 100 / 100     | [CV][CV][  ][  ][  ]         Caravans 4 / 6 (1 queued)    | | [  ][  ][ ][ ]  |
 ..   |                  | | XP ...             |                              Gold traded, last 3 min: 620  | |                 |
 44   +------------------+ +----------------------------------------------------------------+ +-----------------+
```

---

## 2. Scaling with the UI-size setting
Exactly as `ui-champions.md` section 2: `GameSettings.ui_scale` is `root.content_scale_factor`, every rect here is in
virtual pixels, the whole HUD scales uniformly, no per-element rules. What is anchored where:
- The top bar keeps `PRESET_CENTER_TOP` and recomputes its offsets from its content width (`SIZE.x` + `TIMER` +
  `ESSENCE_EXTRA` + `GOLD_EXTRA`), as it does today for essence.
- The trade window is fixed at (420, 156) like the tavern; the post panel is inside the bottom-anchored selection
  panel (offsets as the flag card: `offset_top -230`, `offset_bottom -26`, `offset_left 588`, `offset_right 1264`).
- The route chip follows the mouse in virtual pixels; the floating `+28` and the route ribbon are world objects
  (`pixel_size` / metres), the UI scale never touches them.
- Overlap-free virtual height stays 900 px and width **1600 px** (the top bar + help panel need x 488-1584):
  keep `ui_scale <= min(window_height / 900, window_width / 1600)`; the settings slider already caps at 1.5.

---

## 3. Top bar (10.C8, `scripts/ui/top_bar.gd`)

### 3.1 Layout
```
 488                                                                                              1112
  8  /------------------------------------------------------------------------------------------\
     | <> 1 250   |  POP 12 / 20   |  (hourglass) 7:42   |  ~ 140   |  (o) 2 140                 |
 48  \------------------------------------------------------------------------------------------/
     crystals 16+8+70   pop 28+8+80        timer 70         essence 16+8+52     gold 16+8+60
     gaps: 48 px between items (32 px separator control + 8 + 8), a 1 px frame_dark line 20 px tall in each
```
- A **5th item** after essence: `const GOLD_EXTRA := 124.0` (the same arithmetic as `ESSENCE_EXTRA`: gap 32 + 8 + coin
  16 + 8 + number 60). Width = 400 (timer) + 100 (essence) + 124 (gold) = **624 x 40 at (488, 8)**; `offset_left =
  -312`, `offset_right = 312`. With the timer but no gold bank: 500 at (550, 8) as today; the gold items are created
  hidden like `_essence_items` and shown when a bank is found.
- **Coin icon** 16 x 16, `size_flags_vertical SHRINK_CENTER`, drawn in code: `draw_circle` radius 8 `GOLD_COIN
  (1.0, 0.78, 0.25)`; a 1 px ring radius 7.5 `(0.55, 0.42, 0.10)`; an inner ring radius 5 `(0.85, 0.62, 0.18)` 1 px
  (a stamped coin); a highlight arc radius 6 from 200° to 290° 1.5 px `(1.0, 0.93, 0.65)`. Two-tone like the other icons.
- **Number**: `UIStyle.number_label("--", 20)`, `custom_minimum_size (60, 0)`, colour `GOLD_TEXT (1.0, 0.88, 0.5)`,
  vertical centre. `2 140` measures 52 px, `12 345` 64 px (the label grows and the bar recentres, fine).
  Thousands with a thin space like the end screen (`Skirmish._thousands`): `2 140`.
- Data: `GoldBank.for_team(0)` looked up like `find_essence_bank` (class list `GoldBank` -> `for_team`, then group
  `"gold_banks"` with `team == 0`), retried every 0.5 s while null. Text polls `bank.get("gold")` each frame like
  essence. Signals: `spend_failed` -> `flash_not_enough_gold()`.
- **Failed spend**: number `WARN` 0.4 s (`FLASH_TIME`) + the existing `shake()` (±4 px, 3 cycles, 0.3 s) +
  `message.emit("Not enough gold")`. `is_gold_flashing() -> bool` for tests.
- **Income pop** (cheap feedback for deliveries): when `gold` rises by >= 10 between two polls, the number scales
  1.0 -> 1.15 -> 1.0 over 0.2 s (`pivot_offset` centre). Never on spends.
- `apply_skin()` unchanged (gold colours are never skinned). The chamfered slab and separators need no change: the
  `_separator()` helper is reused for the gold gap.
- Tooltip (the bar is `MOUSE_FILTER_IGNORE` today; keep it so: no tooltip).

### 3.2 Constants for tests
`TopBar.GOLD_EXTRA = 124.0`; `gold_label: Label`; `gold_bank: Object`; `set_gold_bank(bank)`; `is_gold_flashing()`.
At 1600 x 900 with timer + essence + gold: `get_global_rect() == Rect2(488, 8, 624, 40)`.

---

## 4. Build menu (10.C7, `command_card.gd`)
- `BUILD_KEY_SLOTS` gains `"B": 5` (r2c2; r2c1 index 4 stays the Ice Wall V). The Bazaar's `hotkey_label` is `B`.
- Slot: abbreviation `EB` / `GB` / `FB` / `GB` (from `UIStyle.abbrev(display_name)`; Grove and Gloom both give `GB`,
  the icon `art/icons/buildings/<id>.png` tells them apart once 10.V12 lands) or the icon; cost tag `175` (`155` Grove)
  in the crystal colour, `WARN` when short; badge `B`.
- `_building_description` for `kind == &"market"`: `Sends caravans to the trading posts for gold. Within 20 m of your
  keep. One per kingdom.` (560 px at font 13: the custom tooltip wraps at its 320 px max width, 2 lines). Tooltip:
  `Ember Bazaar  [B]\nCost 175 crystals · 40 s · 1000 HP\nSends caravans ...` + `\n<reason>` from `sel.build_reason(type)`
  (`Needs a completed Hall`, `Only one Bazaar`, `Not enough crystals`, ...).
- **B with the build menu open** = `begin_placement(bazaar type)` (selection manager, 10.C7), like Z X C V. The
  placement ghost shows the grid's refusals as today (`Must be within 20 m of your keep` is just one more red reason).

---

## 5. The Bazaar selected (10.C7: `command_card.gd`, `selection_panel.gd`, `selection_manager.gd`)

### 5.1 Command card
```
 r1  [ CV ]  [ RT ]  [ WR ]  [    ]      Caravan Z · Set Route (no key) · Wares U · empty
 r2  [ HF ]  [ MC ]  [ SG ]  [ LW ]      one route button per post, value ascending from this Bazaar
 r3  [    ]  [    ]  [    ]  [    ]
```
| Slot | id | Abbr / key | Tooltip | Disabled reason | Look |
|---|---|---|---|---|---|
| r1c1 | `train_caravan` | `CV`, `Z` (`sel.train_key`) | `Caravan  [Z]\nCost 75 crystals · Pop 1 · 20 s\nTrades with a post and brings gold back. Max 6.` | `can_queue` (`Caravan limit reached`, `Not enough crystals`, `Population cap reached`) | Train button as today (cost tag `75`, icon `art/icons/units/caravan.png`) |
| r1c2 | `route` | `RT`, no key | `Set Route\nClick a trading post: caravans trade there from now on.\nRight-click a post does the same.` | `Trading posts open at 4:00` (`TradeNetwork.is_open()` false) | Targeted order `SelectionManager.ORDER_ROUTE := &"route"` (cross cursor, gold pulsing rim while pending; left-click a post confirms, right-click / Esc cancel). Clicking the ground while pending: `show_message("Right-click a trading post to set the route")`, the order stays pending |
| r1c3 | `wares` | `WR`, `U` | `Wares  [U]\nBuy one-time wares and exchange gold at the Bazaar.` | none | Opens the trade window on the Bazaar tab (`hud.get("trade_window")` + `has_method("open")`, argument `&"bazaar"`) |
| r2c1-r2c4 | `route_<post_id>` | 2 letters of the post (`HF`, `MC`, `SG`, `LW`) or the icon `art/icons/posts/<post_id>.png`; no key | `Millstone Cross · near\n28 gold per trip · ~56 / min per caravan\nRight-click the post does the same.`; the current route replaces line 3 with `Current route` (`GOLD`) | `Trading posts open at 4:00` -> shown as `Opens at 4:00`; `Held by the enemy` (from `TradeNetwork.route_reason`); `Route too short` | See below |
Route button extras (drawn by the card, same controls as the other decorations):
- **Value tag**: the cost-tag control (26 x 12 at (4, 48), bg `(0, 0, 0, 0.75)`) shows the route value in `GOLD_TEXT`
  font 10 (`154` = 18 px, fits). Data: `TradeNetwork.route_value(market, post)`.
- **Near / far chip**: 26 x 12 at (2, 2), bg `(0, 0, 0, 0.75)`, radius 2, text font 9 centred: `near` in `NEAR
  (0.4, 0.9, 0.4)` (21 px) or `far` in `FAR (1.0, 0.55, 0.2)` (13 px). Data: `TradeNetwork.is_far(team, post)`.
- **Current route**: the selected state (`GOLD` rim, not pulsing) on that button; `s["active"] = market.route_post == post`.
- **Held post**: the button is disabled (`modulate.a 0.45`) and a 1 px `WARN` rim replaces the frame rim.
- Order: the 4 posts sorted by `route_value` ascending (near ones first by construction). The buttons refresh at the
  card's 10 Hz (values only change when a post opens or is held).
- The Bazaar never shows `Set Rally`: for `building_type.kind == &"market"` the card puts Set Route in r1c2 instead of
  the rally slot, and the right-click ground rule of 5.4 applies.
- Under construction: the site view as today (Cancel Delete only).

### 5.2 Selection panel: the keep view + a Bazaar block at x 1000
```
 588        696                                      1000                                    1264
 670 +--------+ EMBER BAZAAR                           Route: Millstone Cross (near)          676 (font 13)
     |portrait| [HP  1000 / 1000 =================]     28 gold per trip · ~56 / min each      696
     | 96x96  |                                        Caravans 4 / 6 (1 queued)              716
     |        | [CV][CV][  ][  ][  ]  (queue 48, y 734) Gold traded, last 3 min: 620 · total 2 140   736
 766 +--------+ ====                                   Wares 1 / 4 owned · U                   756 (font 12 muted)
 792            Rally: set   -> hidden for the Bazaar
```
- The existing keep view (`_update_keep`) with `building_info` **empty** for markets (so the queue row stays at y 734)
  and `rally_label` hidden (`kind == &"market"`).
- **Bazaar block** (`market_block: Control` at (1000, 676), 264 x 100, `mouse_filter IGNORE`, only visible for an own
  completed market; enemy Bazaars show the plain keep view): 5 labels, `clip_text` + ellipsis, width 264:
| Line | Rect | Text | Colour |
|---|---|---|---|
| A | (1000, 676) font 13 | `Route: ` + post name + ` (near)` / ` (far)` (`Route: Millstone Cross (near)` = 181 px) | `Route: ` `text_muted`, name `GOLD`, `(near)` `NEAR` / `(far)` `FAR` (one `HBoxContainer`, separation 0) |
| B | (1000, 696) font 13 | `28 gold per trip · ~56 / min each` (213 px). Posts closed: `Posts open at 4:00 · caravans wait`; held: `Held by the enemy · caravans wait` | `text`; the two waiting forms `WARN` |
| C | (1000, 716) font 13 | `Caravans 4 / 6 (1 queued)` (`Caravans 4 / 6` when the queue is empty; `WARN` at 6 / 6) | `text` |
| D | (1000, 736) font 13 | `Gold traded, last 3 min: 620 · total 2 140` (248 px) | `text_muted` words, numbers `text` (plain label is fine: the whole line `text`) |
| E | (1000, 756) font 12 | `Wares 1 / 4 owned · U` | `text_muted`, the `U` on an inline 18 x 14 gold badge as the champion card's `[R]` |
- Data: `Market.route_post`, `route_value()`, `caravans().size()` + queued caravans in `queue`, `TradeNetwork.is_far`,
  `trade_income(team, 180)`, `GoldBank.earned(&"trade")`, `owned_wares.size()`. `~56 / min` = `route_value * 60 /
  (L / 4.0 + L / 3.6 + 4)` with `L = TradeNetwork.route_length(market, post)`, rounded.
- `current_view()` stays `"keep"`; add `market_block_text() -> String` (the 5 lines joined by `\n`, `""` when hidden) for tests.

### 5.3 Right-click rules with a Bazaar selected (10.C7, `selection_manager.gd`)
| Right-click on | Action |
|---|---|
| A trading post (layer-2 ray hit in group `"trade_posts"`, or the ground within 3.5 m of its centre, like `tavern_at`) | `market.set_route(post)`; a refusal string -> `message`; success -> the route button flips to the selected state and the route line redraws; no message |
| The ground / anything else | `show_message("Right-click a trading post to set the route")` (throttled: once per 2 s) instead of a rally |
| The minimap (right-click) within 4 m of a post centre | Same as the post (the minimap already resolves gather-near-node this way) |

---

## 6. Caravans and trackers selected (10.C7)

### 6.1 Caravan command card
| Slot | id | Abbr / key | Tooltip |
|---|---|---|---|
| r1c1 | `move` | `MV` M | as today |
| r1c2 | `stop` | `ST` C | as today |
| r1c3 | `hold` | `HD` H | as today |
| r1c4 | `trade` | `TR` G, order `ORDER_GATHER` | `Trade  [G]\nClick a trading post: trade there from now on.\nClick your Bazaar: go home and deliver.` |
- Caravans are commandable units: right-click ground = move, right-click a post = `command_trade(post)`, right-click the
  own Bazaar = `command_trade(market)`, right-click an enemy = nothing (they never fight; treat it as a move next to it).
- **Mixed selection with workers**: r1c4 stays the worker's `gather` slot with the tooltip `Gather / Trade  [G]\nWorkers
  gather at a crystal node; caravans trade at a post or go home to the Bazaar.` The G click resolves per unit: a node ->
  `command_gather` on workers (caravans walk next to it, as other units do today), a post / the own Bazaar ->
  `command_trade` on caravans (workers walk next to it), the ground -> a plain move for everyone.
- A caravan gets no Attack-move (`X`) even when mixed with soldiers (the soldiers do; the caravan is given `command_move`).

### 6.2 Caravan single view (`_update_single`, `u.is_in_group("caravans")`)
```
 588        696
 670 +--------+ CARAVAN
     |portrait| [HP  220 / 220 ===================]      700
     |        | (o) Cargo 119 gold · Route: Saltgate (far)   730 (font 14; the coin 12 px only while loaded)
 766 +--------+ Returning with 119                       750 (font 14, state colour)
```
| Element | Rect | Look |
|---|---|---|
| Stat line | (696, 730) font 14 | `Cargo 119 gold · Route: Saltgate (far)` (245 px) / `Empty · Route: Lantern Wharf (far)`; a 12 px coin glyph (3.1 at 12 px) before `Cargo` while `is_loaded()`; `Cargo n gold` in `GOLD_TEXT`, the rest `text_muted`, the post name `text`. No route (`route_post == null`): `Empty · No route: right-click a post` |
| State line | (696, 750) font 14 | `Caravan.state_text()` (`To Saltgate` `text`, `Loading` `text_muted`, `Trading` `GOLD`, `Returning with 119` `GOLD`, `Waiting: Saltgate is held` `WARN`, `Waiting: posts open at 4:00` `WARN`, `Idle` `text_muted`). Widest `Waiting: Lantern Wharf is held` = 205 px |
- Multi-select icons: a loaded caravan's 48 x 48 icon gets a 6 px gold coin (`GOLD_COIN` disc + 1 px `(0.55, 0.42,
  0.10)` ring) at its bottom-right corner (inset 3), under the veterancy dots' row. Header line as today
  (`4 selected:  4 Caravan`).
- Enemy caravan (visible): the single view as any enemy unit, the stat line `Cargo 119 gold` shown (raiders want to know).

### 6.3 Greywater Tracker (own or enemy, `is_commandable() == false`: the 9.C8 `inspected` mechanism)
- `selection.inspected` is set for any non-commandable unit; the panel branches on the group: `"champions"` -> the
  champion view, `"trackers"` -> the **single view** with: name `GREYWATER TRACKER` (Cinzel 20), HP bar, stat line
  (696, 730) `Damage 12 · Range 7.0 · Speed 5.4` as any unit, and a second line (696, 750) font 14 `Contract: Outriders ·
  1:42 left` (197 px; `TrackerContract` found in group `"tracker_contracts"` whose `trackers` contains the unit;
  `time_left()` as m:ss; enemy trackers: `Enemy hunters` `text_muted`). `current_view()` returns `"single"`.
- Command card: the inspect block (9.C8) with the texts `Hired hunters act on their own.` (font 14 `text_muted`, y 740)
  and `U: trade & hunters` (font 13, the `U` on the 18 x 14 gold badge, y 762); all 12 slots empty. Enemy tracker:
  second line `Hunt it with a bounty  [R]` as for enemy champions.
- Magpie clicked (a neutral enemy unit, commandable = true but never ours): the ordinary enemy single view, name
  `MAGPIE`, stat line + ` · Carrying 60 gold` in `GOLD_TEXT` when `get_meta(&"loot", 0) > 0`.

---

## 7. Route line and hover preview (10.C7, `scripts/vfx/route_line.gd`, `class_name RouteLine extends Node3D`, group `"route_line"`)

### 7.1 The ribbon
- `static func attach(hud: Node, selection: Node) -> RouteLine`: adds the 3D node to `hud.get_parent()` (the level)
  and the preview chip (7.2) under `hud`. `hud.gd` calls it through `attach_optional("res://scripts/vfx/route_line.gd",
  [self, selection])` (lead glue). Reached by others through the group.
- API: `show_route(points: PackedVector3Array, kind: StringName)` (`&"route"` / `&"preview"`), `hide_route(kind)`,
  `is_showing(kind) -> bool`, `shown_points(kind) -> PackedVector3Array` (tests).
- **When**: an own Bazaar selected (`selection.selected_building` is a market with `route_post != null`) or one or more
  own caravans selected (the route of the first caravan: `home_market` -> `route_post`; nothing if either is null).
  Points from `TradeNetwork.route_points(market, post)`. Rebuilt on `selection_changed`, on `Market.route_changed`, and
  every 1 s while shown (a caravan re-routed by G); **never per frame**.
- **Mesh**: one `MeshInstance3D` with an `ArrayMesh` rebuilt from the points: a flat strip **0.25 m** wide at
  **y 0.30**, one quad per segment (mitred at the bends is not needed: overlap the quads by 0.15 m), UV.x = distance
  along the route in metres. Material: `StandardMaterial3D` unshaded, `transparency ALPHA`, `cull_mode DISABLED`,
  `albedo_color (1.0, 0.85, 0.3, 0.8)`, `albedo_texture` = a 32 x 4 `ImageTexture` generated in code (pixels 0-19
  white, 20-31 transparent), `uv1_scale.x = 1 / 1.6` so the pattern reads **1.0 m dash, 0.6 m gap**; `_process`
  scrolls `uv1_offset.x -= 1.5 * delta` (dashes flow from the Bazaar toward the post). `cast_shadow OFF`,
  `no_depth_test false` (it lies on the ground, buildings hide it correctly).
- **End rings**: a flat ring (16 segments, radius 0.6 m, width 0.12 m) at the Bazaar's centre and at the post's
  `door_point()`, same material without the dash texture. The current caravan positions are not marked (the units
  are visible on the line anyway).
- **Preview** (`&"preview"`): the same strip in `(1.0, 0.85, 0.3, 0.45)`, no scroll, drawn while a Bazaar is selected
  and the mouse hovers a post that is not the current route. Both can show at once (route + preview).
- Perf: one rebuild is a few hundred vertices; the scroll is one material property per frame.

### 7.2 The hover preview chip (`RouteChip`, a `PanelContainer` following the mouse; `mouse_filter IGNORE`, `z_index 10`)
```
   mouse
     +-----------------------------------------------------------+
     | Saltgate · far · 119 gold / trip · ~104 / min             |    height 26, slate, 1 px frame_metal border
     +-----------------------------------------------------------+
```
- Shown while an own Bazaar is selected and `selection.hovered_post` (10.C7 adds it to the selection manager: the
  post under the mouse, resolved like `tavern_at`, updated in `_process` at 20 Hz, null otherwise) is not null and no
  window is open. Position `mouse + (18, 12)`, clamped to the screen with a 4 px margin (flip to `mouse + (-w - 6, 12)`
  at the right edge, as the bounty chip). Style = `UIStyle.slate_style(4.0, frame_metal)`, margins 6 / 4, height 26.
- Text, one `HBoxContainer` gap 0, font 13: post name `GOLD` + ` · near` `NEAR` / ` · far` `FAR` + ` · 119 gold / trip ·
  ~104 / min` `text`; when `route_reason` is not empty: ` · ` + the reason in `WARN` (`Held by the enemy`, `Opens at
  4:00`, `Route too short`). Widest (`Lantern Wharf · far · 154 gold / trip · ~115 / min · Held by the enemy`) = 421 px.
  Current route: ` · Current route` `GOLD` instead of the reason.
- While the Set Route order is pending (r1c2), the chip also shows over a hovered post; a right-click confirms as usual.

---

## 8. Minimap (10.C7, `minimap.gd`; colours of `market-trade.md` 2.5)
| Layer | Draw | Pass (existing order in `_draw`) |
|---|---|---|
| Roads | `TradeNetwork.road_segments()` (cached at `setup` and refreshed every 2 s while empty): each `PackedVector3Array` as a 2 px polyline `(0.55, 0.45, 0.30)` | Right after the ground fill, **before** the fog texture (black while unexplored) |
| Trading posts | 5 x 5 filled `(0.85, 0.65, 0.30)` + 1 px `draw_rect` unfilled border: `groove` when nobody holds it, `PLAYER_TEAM_COLOR` / `ENEMY_TEAM_COLOR` when `holder_team()` is 0 / 1 | After `_draw_taverns` (explored from 0:00; skip when `_fog.is_explored` is false, like taverns) |
| Magpie Den / Greywater Lodge | 6 x 6 `(0.45, 0.35, 0.55)` / `(0.40, 0.62, 0.35)` (`kind` `&"den"` / `&"lodge"`) + 1 px `groove` outline | Same pass, after the posts |
| Loot sack | 3 x 3 `(1.0, 0.85, 0.3)` | After the buildings, before the units (only `is_visible_in_tree()`: fogged sacks are hidden by the fog) |
| Caravan | In the units loop: `is_in_group("caravans")` -> a 4 x 3 px rect (4 along x, 3 along z, centred) in `OWN_COLOR` / `ENEMY_COLOR` (`Unit.team_color` for others), 5 x 4 when selected; a 1 px `(1.0, 0.85, 0.3)` dot at its centre while `is_loaded()` | Units pass |
| Magpie (visible) | `is_in_group("magpies")` -> 3 x 3 `(1.0, 0.65, 0.2)` (instead of the neutral colour) | Units pass |
| Greywater Tracker | As an own / enemy unit (3 x 3), nothing special | Units pass |
| Route | While `RouteLine.is_showing(&"route")` (group `"route_line"`): its `shown_points` as a 1 px polyline `(1.0, 0.85, 0.3)` | After the heroes, before the camera quad |
- Test counters (ints like `drawn_ghosts`): `drawn_roads` (segments), `drawn_posts`, `drawn_held_posts`, `drawn_guilds`,
  `drawn_sacks`, `drawn_caravans`, `drawn_loaded_caravans`, `drawn_magpies`; `route_drawn: bool`.
- Right-click on the minimap with a Bazaar selected within 4 m of a post centre = set route (5.3); with caravans
  selected the same click = `command_trade(post)`.
- Nothing else changes (10 Hz, fog texture, pings).

---

## 9. Post, Den and Lodge panels (10.C8, `scripts/ui/post_panel.gd`, `class_name PostPanel extends Control`; the click plumbing is 10.C7)

### 9.1 Plumbing (10.C7, `selection_manager.gd`)
- A left-click on a trading post or a guild house (layer-2 ray hit or the ground inside its 6 x 6 footprint, resolved
  like `tavern_at`) clears `selected`, `selected_building`, `inspected`, `selected_bounty`, sets
  **`selection.selected_neutral: Node3D`** and emits **`neutral_building_clicked(node)`**. Any other click, Esc or a
  box select clears `selected_neutral` (and emits `selection_changed`). The node's `set_selected(true / false)` is
  called on select / clear. Never an order target: right-click on a post with units selected is the trade / route rule.
- `hud.gd` (10.C8) connects `neutral_building_clicked`: a Lodge also opens the trade window on the Lodge tab
  (`trade_window.open(&"lodge")`); a Den or a post only shows the panel.

### 9.2 The panel
`static func attach(hud: Node, selection: Node) -> PostPanel` (lead glue in `hud.gd`, like the flag card). A `Control`
676 x 204 at (588, 670) (offsets as the flag card), painting `panel_bg` (alpha 1) over the selection area, visible only
while `selection.get("selected_neutral")` is a valid node; refresh at 4 Hz. Command card: all slots empty (the card's
`_build_slots` sees no units / building; the inspect block stays hidden).

**Trading post** (`node.is_in_group("trade_posts")`):
```
 588        696                                                        1104         1254
 670 +--------+ MILLSTONE CROSS · trading post                          [ Set as route ]   674 (150 x 32)
     |  tile  |
     | 96x96  | Open                                                   700
     |  (MC)  | For you: near · 28 gold per trip from your Bazaar      722
 766 +--------+ Held by the enemy · your caravans wait                  746
                Your trips here, last 2 min: 4 · caravans on this route: 2     770 (font 13 muted)
                Right-click with your Bazaar selected to set the route · G with caravans: trade here   806 (font 12 muted)
```
| Element | Rect | Look |
|---|---|---|
| Tile | 96 x 96 at (588, 670) | Slot frame (rim `frame_dark`: neutral, as the portrait's neutral rule), portrait gradient bg; the icon `art/icons/posts/<post_id>.png` 88 x 88 inset 4 (10.V12), fallback: the abbreviation `MC` Cinzel 28 `title` + a signpost glyph behind it at alpha 0.25 (pole 3 px `frame_dark` from (48, 20) to (48, 80), a 30 x 14 hanging sign rect at (52, 30) `GOLD_COIN`) |
| Title | (696, 670) | Cinzel 20 `title` `MILLSTONE CROSS` (`display_name`, 198 px) + ` · trading post` font 14 `text` |
| Button | 150 x 32 at (1104, 674) | `Set as route` font 14, primary style; only when `Market.for_team(0)` is not null; the current route: text `Current route`, disabled (`modulate.a 0.45`); tooltip `Set as route\nYour caravans trade here from now on.` + reason (`Route too short`). Calls `market.set_route(post)`; a refusal -> the HUD message |
| Status | (696, 700) font 14 | `Open` `NEAR`-green / `Opens at 4:00 · in 1:12` `WARN` (`time_until_open()` as m:ss) |
| Value | (696, 722) font 14 | `For you: near · 28 gold per trip from your Bazaar` (325 px; `near` / `far` in their colours, `28 gold` `GOLD_TEXT`) / without a Bazaar: `Build a Bazaar to trade` `text_muted` |
| Holder | (696, 746) font 14 | `Held by the enemy · your caravans wait` `WARN` (266 px) / `Held by you` `NEAR` / `Not held` `text_muted` (`holder_team()`) |
| Traffic | (696, 770) font 13 `text_muted` | `Your trips here, last 2 min: 4 · caravans on this route: 2` (342 px): `TradeNetwork.trips(0, post)` and the own caravans whose `route_post == post` |
| Hint | (696, 806) font 12 `text_muted` | `Right-click with your Bazaar selected to set the route · G with caravans: trade here` (475 px, fits the 568 px) |

**Magpie Den** (`is_in_group("guilds")` and `kind == &"den"`), read-only, no button:
| Element | Rect | Look |
|---|---|---|
| Tile | 96 at (588, 670) | Icon `art/icons/buildings/magpie_den.png`; fallback `MD` Cinzel 28 |
| Title | (696, 670) | `MAGPIE DEN` Cinzel 20 + ` · Thieves' Guild` font 14 `text` |
| Line 1 | (696, 700) font 13 `text` | `Thieves who rob caravans and remote workers. They answer to no one.` (447 px) |
| Line 2 | (696, 722) font 13 `text_muted` | `On the roads from 5:00 · raid remote mines from 8:00` |
| Line 3 | (696, 746) font 14 | `Magpies you can see: ` `text` + the count in `GOLD_TEXT` (`0` `text_muted`): visible units of group `"magpies"` (`is_visible_in_tree()`) |
| Line 4 | (696, 770) font 12 `text_muted` | `Killing a Magpie pays 10 gold (Greywater Lodge)` |

**Greywater Lodge** (`kind == &"lodge"`): the trade window opens on its tab (9.1) and the panel shows:
| Element | Rect | Look |
|---|---|---|
| Tile / title | as the Den | Icon `art/icons/buildings/greywater_lodge.png`, fallback `GL`; `GREYWATER LODGE` + ` · Hunters' Guild` |
| Button | 150 x 32 at (1104, 674) | `Contracts  [U]` font 14 primary (the `U` plain in the label; tooltip `Contracts  [U]\nHire Outriders or a Sweep for gold.`): opens the window on the Lodge tab |
| Line 1 | (696, 700) font 13 `text` | `Sells Outriders and Sweep contracts for gold · pays 10 gold per Magpie slain` (472 px) |
| Line 2 | (696, 722) font 14 | `Open` `NEAR` / `The Lodge opens at 5:00 · in 0:48` `WARN` |
| Line 3 | (696, 746) font 14 | Running contracts: `Outriders · 1:42 left` `text` (both, ` · ` joined) / `No contract running` `text_muted` |
| Line 4 | (696, 770) font 12 `text_muted` | `Trackers act on their own and leave when the contract ends` |

---

## 10. The trade window (10.C8, `scripts/ui/trade_window.gd`, `class_name TradeWindow extends PanelContainer`)

### 10.1 Frame, tabs, opening
- **760 x 464 at (420, 156)**, heavy frame (content margin 10 -> inner x 430-1170, y 166-610), drop shadow,
  `mouse_filter STOP`, hidden until opened. `static func attach(hud: Node) -> TradeWindow` like the tavern (under the
  HUD, `message` -> `hud.show_message`); `hud.gd` creates it in `setup` next to the tavern and wires the exclusivity:
  `shop_window.opened -> trade_window.close`, `tavern_window.opened -> trade_window.close`, `trade_window.opened ->
  shop_window.close` and `tavern_window.close`.
- `open(tab: StringName = &"")` (`&"bazaar"` / `&"lodge"`; empty = the last tab, Bazaar at first), `close()`,
  `toggle()`, `is_open()`, `current_tab() -> StringName`, signals `opened`, `closed`. `open` returns false and shows
  nothing when `GoldBank.for_team(0)` is null (trade off).
- **U** (physical `KEY_U`, no modifiers, `_unhandled_key_input` in `trade_window.gd`, ignored while the pause menu /
  briefing has focus) toggles it; **Esc** (`_input`, as the shop) and the stud X close it; the Bazaar's Wares button
  and a Lodge click open it on their tab. Closes when the match ends (`show_banner`).
- Data: `GoldBank.for_team(0)` (wares, exchange, gold), `Market.for_team(0)` (null = no Bazaar), `HuntersGuild.instance`
  (group `"hunters_guild"`), `TradeNetwork` (ledger), `ThievesGuild.magpies_alive()` is **not** used (only visible ones).
  Refresh at 4 Hz while open.

```
 430                                                                                                 1170
 166 TRADE   [ BAZAAR ] [ GREYWATER LODGE ]                        (o) 2 140   <> 1 250   ~ 140   (x)   194
 198 ------------------------------------------------------------------------------------------------ 1 px frame_light
 204 (tab content, y 204-582)
 588 footer left (font 12)                                                       footer right (font 12)   606
```
| Part | Rect | Look |
|---|---|---|
| Title | (430, 166), 28 tall | `TRADE` Cinzel 20 `title` (69 px) |
| Tab A | 100 x 28 at (516, 166) | `BAZAAR` Cinzel 14 centred (61 px) |
| Tab B | 176 x 28 at (622, 166) | `GREYWATER LODGE` Cinzel 14 centred (150 px); tooltip `Hunters' Guild: contracts paid in gold` |
| Tab look | | The control-group tab look (4.2): slot frame with the two top corners chamfered 6 px; **active**: `GOLD` rim + a 2 px gold line along the tab's bottom edge (over the rule), text `title`; inactive: `frame_metal` rim, text `text_muted`, hover `frame_light`. A tab is a `Button`, `focus_mode NONE` |
| Resources | right-aligned block ending at x 1134, y 170, 20 tall | coin 16 + 6 + gold number font 16 number `GOLD_TEXT`, 12 px, crystal diamond 16 + `1 250` `CRYSTAL_TEXT`, 12 px, essence flame 16 + `140` `ESSENCE_TEXT` (font 16 embolden). The gold number flashes `WARN` 0.4 s on `spend_failed` |
| Stud X | 24 x 24 at (1146, 168) | As the shop / tavern |
| Rule | 740 x 1 at (430, 198) | `frame_light` |
| Footer | (430, 588), 740 x 18 | Per tab (10.2 / 10.3): left font 12, right-aligned font 12 |

### 10.2 Bazaar tab (wares + exchange)
```
 430                                                                                                 1170
 204 +----+ IRON-SHOD AXLES                                                              (o) 150  one-time
     |[IA]| Caravans move 0.5 m/s faster and gain 60 HP                                  [    Buy     ]
 268 +----+ Applies to caravans alive now and built later
 274 +----+ MASONS' CHARTER · Owned                                                      Owned
     |[MC]| Every building of yours gets +15 % max HP, now and later
 338 +----+ Existing, under construction and future buildings; the gain is healed
 344 +----+ TEMPERED STEEL                                                               (o) 350  Not enough gold
     |[TS]| Your soldiers deal +8 % damage                                               [    Buy     ] (disabled)
 408 +----+ Soldiers only: not workers, caravans, wizards, champions or hunters
 414 ... QUILTED GAMBESONS (same shape)                                                                        478
 486 EXCHANGE ------------------------------------------------------------------------   Gold earned 2 140
 516 [ 100 gold  ->  80 crystals ]   [ 100 gold  ->  40 essence ]                        trade 1 890 · loot 160 · rewards 90
 558 Shift+click: 500 gold at once · no reverse exchange · needs your Bazaar             Gold traded, last 3 min: 620
 588 Wares are bought once and apply to units made later too                                        Bazaar: Ember Bazaar
```
**Ware rows**: 4 x (740 x 64) at (430, 204 + 70 k), k = 0..3 in `GoldBank.WARES` order (`iron_axles`,
`masons_charter`, `tempered_steel`, `gambesons`). Row bg `panel_inner` alpha 0.55, radius 3 (hover 0.8) like the tavern
rows; owned row: 1 px `GOLD` rim at alpha 0.6. Offsets from the row's top-left:
| Part | Rect | Content |
|---|---|---|
| Tile | 48 x 48 at (8, 8) | Slot frame (rim `frame_metal`; owned `GOLD`), portrait gradient bg, icon `art/icons/wares/<id>.png` 40 x 40 inset 4 (10.V12), fallback abbreviation Cinzel 16 `title`: `IA`, `MC`, `TS`, `QG` |
| Name | (68, 6), width 540 | Cinzel 15 `title` (`QUILTED GAMBESONS` 180 px); owned: ` · Owned` font 12 `OWNED (0.4, 0.95, 0.4)` after it (one `HBoxContainer`) |
| Effect | (68, 26) font 12 `text` | `Caravans move 0.5 m/s faster and gain 60 HP` / `Every building of yours gets +15 % max HP, now and later` (281 px) / `Your soldiers deal +8 % damage` / `Your soldiers take 9 % less damage (+10 armor)` |
| Who | (68, 44) font 11 `text_muted` | `Applies to caravans alive now and built later` / `Existing, under construction and future buildings; the gain is healed` / `Soldiers only: not workers, caravans, wizards, champions or hunters` (both soldier wares) |
| Price | (628, 4), 104 x 16 | coin 10 px + 4 px + `150` / `350` font 12 number `GOLD_TEXT` (`WARN` when `gold < price`); hidden when owned |
| Note | (628, 20), 104 x 12, font 10 | `one-time` `text_muted`; when refused the reason replaces it in `WARN` (`Not enough gold` 81 px, `No Bazaar`, `Already owned`); `clip_text` + ellipsis, full text in the button tooltip |
| Buy | 104 x 24 at (628, 34) | `Buy` primary button (display font like `Hire`); disabled (3.3 disabled, `modulate.a 0.45`) when `can_buy_ware(id) != ""`; tooltip `Buy Iron-shod Axles\n150 gold · once\n<effect line>` + `\n<reason>`. Owned: the button is hidden and `Owned` font 13 `OWNED` is centred in the 104 px at y 38 |
- `buy_ware(id) == ""`: the row flashes `GOLD` 0.3 s (as a hire), the tile rim turns gold, the message `Bought Masons'
  Charter` comes from the HUD's listener (section 13); the gold number in the title bar pops as the top bar's does.
- `press_buy(i) -> String` for tests.

**Exchange block** 740 x 96 at (430, 486):
| Part | Rect | Content |
|---|---|---|
| Sub-title | (438, 490) | `EXCHANGE` Cinzel 13 `text_muted`; a 1 px `frame_dark` rule from x 520 to 900 at y 498 |
| Button A | 220 x 36 at (438, 516) | `100 gold  ->  80 crystals` font 13 (144 px), primary style; Shift held: the label reads `500 gold  ->  400 crystals` (refresh on `Input.is_key_pressed(KEY_SHIFT)` at 4 Hz + on the click) |
| Button B | 220 x 36 at (672, 516) | `100 gold  ->  40 essence` / `500 gold  ->  200 essence` |
| Hint | (438, 558) font 12 `text_muted` | `Shift+click: 500 gold at once · no reverse exchange · needs your Bazaar` (406 px) |
| Ledger | (920, 516), 250 wide, 3 lines font 12 | `Gold earned 2 140` (`text`, number `GOLD_TEXT`), `trade 1 890 · loot 160 · rewards 90` (`text_muted`: `earned(&"trade")`, `&"loot"`, `&"reward"`), `Gold traded, last 3 min: 620` (`text_muted`; `TradeNetwork.trade_income(0)`) |
- Click: `exchange(100 or 500, &"crystals" / &"essence")`; a refusal string (`No Bazaar`, `Not enough gold`) -> the
  HUD message and a `WARN` flash of the button's rim 0.3 s. Buttons disabled (`modulate.a 0.45`) while `Market.for_team(0)`
  is null or gold < 100 (< 500 with Shift), tooltip `Exchange\n100 gold -> 80 crystals · Shift: x5\n<reason>`.
  Success: the message `Exchanged 100 gold for 80 crystals` (section 13) and the target number in the title bar pops.
- `press_exchange(to: StringName, times := 1) -> String` for tests.

**Footer (Bazaar tab)**: left `Wares are bought once and apply to units made later too` font 12 `text_muted`; **without
a Bazaar** the left text is `Build a Bazaar to buy wares and exchange gold` font 12 `WARN` (and every Buy / exchange
button is disabled with `No Bazaar`). Right-aligned: `Bazaar: Ember Bazaar` `text` (the own market's `display_name`) or
`No Bazaar` `WARN`.

### 10.3 Greywater Lodge tab (contracts)
```
 430                                                                                                 1170
 206 Greywater Lodge (Hunters' Guild) · contracts paid in gold · open from 5:00       (font 13 muted; WARN while closed)
 228 +--------+ OUTRIDERS                                                             (o) 120   No pop cost
     |  tile  | 2 Greywater Trackers · 180 s
     | 76x76  | Each tracker shadows one of your caravans and shoots any Magpie that
     |  (OR)  | comes near it.                                                         [    Hire    ]
 318 +--------+
 324 +--------+ SWEEP                                                                 Running
     |  (SW)  | 3 Greywater Trackers · 120 s                                          1:42 left
     |        | Three trackers walk your mines and roads in turn, attack every        [====------]   (104 x 6)
     |        | Magpie they find and chase looters.
 414 +--------+
 426 The Lodge pays 10 gold for every Magpie slain                                    Rewards received: 50 gold
 452 Bands lurk on the roads from 5:00 and raid remote mines from 8:00.
 470 Bands skip spots within 20 m of your towers. Soldiers, Hunt flags and hunters kill them.
 488 A dead Magpie drops its loot. Walk any unit over a sack to take it.
 588 Trackers act on their own for the contract's time, then leave                          Magpies you can see: 3
```
| Part | Rect | Content |
|---|---|---|
| Header | (438, 206) font 13 | `Greywater Lodge (Hunters' Guild) · contracts paid in gold · open from 5:00` (460 px) `text_muted`; before 5:00: `The Lodge opens at 5:00 · in 0:48` `WARN` (`HuntersGuild.is_open()`; the seconds from the level's match time vs `OPEN_TIME`) |
| Rows | 2 x (740 x 90) at (430, 228) and (430, 324) | `outriders`, `sweep` in `HuntersGuild.CONTRACTS` order. Row bg as the tavern rows; a running contract's row: 1 px `trim_glow` rim alpha 0.6 |
| Reward line | (438, 426) font 12 `text` | `The Lodge pays 10 gold for every Magpie slain` (`REWARD_PER_MAGPIE`); right-aligned at x 1162: `Rewards received: 50 gold` `text_muted` (`GoldBank.earned(&"reward")`) |
| Tips | (438, 452 / 470 / 488) font 12 `text_muted` | The three lines of the mock (394 / 505 / 377 px) |
| Footer | (430, 588) | left `Trackers act on their own for the contract's time, then leave` `text_muted`; right `Magpies you can see: 3` `text` (count `GOLD_TEXT`, `0` `text_muted`) |

**One contract row** (offsets from the row's top-left):
| Column | Rect | Content |
|---|---|---|
| Tile | 76 x 76 at (6, 7) | Slot frame (rim `frame_metal`; running `trim_glow`), portrait gradient bg, icon `art/icons/contracts/<kind>.png` 68 inset 4 (10.V12: Outriders, Sweep), fallback `OR` / `SW` Cinzel 22 |
| Name | (92, 4) | Cinzel 16 `title`: `OUTRIDERS` / `SWEEP` |
| Sub | (92, 26) font 12 `text_muted` | `2 Greywater Trackers · 180 s` / `3 Greywater Trackers · 120 s` (from `CONTRACTS`) |
| Description | (92, 44), width 530, font 12 `text`, `autowrap WORD_SMART`, 2 lines (h 32) | `Each tracker shadows one of your caravans and shoots any Magpie that comes near it.` (500 px -> 2 lines) / `Three trackers walk your mines and roads in turn, attack every Magpie they find and chase looters.` (573 px -> 2 lines) |
| C: hireable | (628, 4) coin 10 + `120` / `100` font 12 number `GOLD_TEXT` (`WARN` when short); (628, 22) `No pop cost` font 11 `text_muted`; (628, 62) **`Hire`** 104 x 24 primary | tooltip `Hire Outriders\n120 gold · 2 trackers · 180 s\n<reason>` |
| C: refused | as hireable + the reason font 11 `WARN` at (628, 36), autowrap, max 2 lines (`The Lodge opens at 5:00`, `Contract already running`, `On cooldown`, `No caravans to escort`, `Not enough gold`); Hire disabled | reasons from `can_hire(0, kind)`, in the guild's order |
| C: running | (628, 4) `Running` font 12 `NEAR`; (628, 22) `1:42 left` font 12 `text` (`contract_time_left`, m:ss, `WARN` under 10 s); (628, 42) a 104 x 6 bar: bg `panel_inner` + 1 px `groove`, fill `GOLD` = `time_left / duration`; no button | |
| C: cooldown | (628, 4) `On cooldown` font 12 `WARN`; (628, 22) `24 s` font 12 `text` (`cooldown_left`); Hire disabled at (628, 62) | |
- `hire(0, kind) == ""`: the row flashes `GOLD` 0.3 s; the message (`Outriders hired: 2 trackers guard your caravans`)
  comes from the HUD listener (section 13); the horn plays (section 14.5). A refusal string -> the HUD message + the
  row's reason. `press_hire(kind) -> String` for tests.

---

## 11. Tavern window: gold payment (10.C8, `tavern_window.gd`; layout of `ui-champions.md` 5.2 kept when trade is off)
When `GoldBank.for_team(0)` is null nothing changes. With gold, column C (x 626-734, 108 wide, buttons 104 wide) becomes:

```
 not hired (hireable / refused)            fallen                              reviving / hired: unchanged
 y  2  <> 250 · ~ 100      (font 12)        y  2  Fallen · Level 2  (WARN)
 y 16  (o) 250 · ~ 100     (font 11)        y 18  [   Revive 90    ]  (104 x 22, essence)
 y 29  Pop 2  |  <reason>  (font 10)        y 42  [ Revive 180 gold ]  (104 x 22, gold, font 12)
 y 40  [      HIRE       ]  (104 x 22)      y 66  [    Dismiss      ]  (104 x 22)
 y 64  [   HIRE · GOLD   ]  (104 x 22)
```
| Part | Rect | Look |
|---|---|---|
| Price A | (628, 2), h 14 | Crystal diamond 10 + `250` `CRYSTAL_TEXT` · flame 10 + `100` `ESSENCE_TEXT`, font 12 number (as today, 2 px higher) |
| Price B | (628, 16), h 14 | Coin 10 + `250` `GOLD_TEXT` · flame 10 + `100` `ESSENCE_TEXT`, font 11 number (`hire_cost(id, true)`: `gold` = the crystal part 1:1, `essence` unchanged); the gold number `WARN` when `can_hire(id, true) == "Not enough gold"` |
| Pop / reason | (628, 29), h 12, font 10 | `Pop 2` `text_muted`; when `can_hire(id)` refuses: the reason in `WARN` on that line instead (`Population cap reached` = 114 px, fits 106 with ellipsis at worst; the full text is in both buttons' tooltips) |
| Hire (crystals) | 104 x 22 at (628, 40) | As today (display font `HIRE`, primary); disabled when `can_hire(id) != ""`; tooltip `Hire  [Y]\n250 crystals · 100 essence · 2 pop\n<reason>` |
| Hire (gold) | 104 x 22 at (628, 64) | `HIRE · GOLD` display font 12 (82 px), primary style with the rim in `GOLD_COIN` instead of `trim_glow`; calls `guild.hire(id, true)`; disabled when `can_hire(id, true) != ""` (`Not enough gold` in place of crystals); tooltip `Hire with gold  [Y]\n250 gold · 100 essence · 2 pop\n<reason>` |
| Fallen: Revive (essence) | 104 x 22 at (628, 18) | `Revive 90` as today (font 13) |
| Fallen: Revive (gold) | 104 x 22 at (628, 42) | `Revive 180 gold` font 12 (90 px; `revive_cost(ch, true)` = 2 x essence), gold-rim primary; calls `guild.revive(ch, true)`; disabled + `Not enough gold` in the tooltip when refused |
| Fallen: Dismiss | 104 x 22 at (628, 66) | As today (2-click rule) |
| Hired / reviving / arriving rows | unchanged | |
- With gold the four column-C buttons are **22 px tall** (`BUTTON_GOLD := Vector2(104, 22)`) so two of them plus the
  texts fit the 90 px row; the fonts stay 13 (12 for the two gold labels). The rest of the row (columns A, B) never moves.
- Title bar: the gold item is added **before** crystals in the right block (coin 16 + number font 16 `GOLD_TEXT`, then
  the 12 px gap): the block ends at the same x (the stud X does not move); it is hidden when trade is off.
- Which key: `Y` still opens the window; there is no key for the gold buttons (the two Hire buttons sit one above the other).
- `press_hire_gold(i) -> String`, `press_revive_gold(i) -> String` for tests.

---

## 12. Floating texts and the event listener (10.C8, `scripts/vfx/trade_popups.gd`, `class_name TradePopups extends Node3D`, group `"trade_popups"`)
- `static func attach(hud: Node) -> TradePopups`: adds itself to `hud.get_parent()` (the level) and connects (guarded,
  `has_signal`) to `TradeNetwork.delivered / caravan_robbed / workers_raided / post_held_changed / posts_opened`,
  `LootSack.picked` (each sack's signal, found in group `"loot_sacks"` at 2 Hz for new ones), `HuntersGuild.
  contract_started / reward_paid`, `GoldBank.ware_bought`, `ThievesGuild.band_sent`, `Caravan.delivered` (through the
  network's signal, not each unit). It owns the trade **messages** (section 13), the **sounds** (14.5) and the
  **floating texts** below, so every rule lives in one file.
| Text | Where | Look |
|---|---|---|
| `+28` (delivery, own team) | At the Bazaar: `market.global_position + (0, 5.3, 0)` (the model tops at 4.5 m + 0.8) | `Label3D`: `font_size 40`, `pixel_size 0.006` (0.24 m tall, the stake label's size), `modulate GOLD_COIN (1.0, 0.85, 0.3)`, `outline_modulate` black, `outline_size 8`, `billboard ENABLED`, `no_depth_test true`, `cast_shadow OFF`. Rises **1.5 m over 1.0 s** (ease out), `modulate.a` fades 1 -> 0 over the last 0.4 s, then returns to the pool. Number with the thin-space thousands. Only when the delivering team is PLAYER |
| `+60` (loot sack, own team) | At the sack's position + (0, 1.2, 0) | Same look |
| `-119` (own caravan robbed, visible) | At the caravan + (0, `body_height` + 1.1, 0) | Same but `modulate WARN`, `font_size 40`; only when the caravan `is_visible_in_tree()` |
| `+10` (Lodge reward, own team) | Not shown (the `reward_paid` signal carries no position); the summed message suffices |
- Pool of **8** labels (`Label3D` children reused; a 9th event replaces the oldest). They are world labels: the camera
  and the fog decide what the player sees; the only test is the team (own events), since own buildings and units are
  always visible to their owner.
- The coin clink plays with the `+28` (14.5).

---

## 13. Messages (`GameHUD.show_message(text, seconds)`, gold font 22, outline 3, y 120)
All emitted by the 10.C8 listener (section 12) unless marked; texts exactly as `market-trade.md` section 8.
| Message | Seconds | Source / throttle |
|---|---|---|
| `The trading posts open their gates` then, 3 s later and once per match, `Build a Bazaar (B then B with a worker) to send caravans` | 3.0 each | **10.C1** (`TradeNetwork`, section 2.2 of the spec); the listener does not repeat them. The hint is skipped by 10.C1 when the player already owns a Bazaar (glue note) |
| `The Magpies are on the roads` | 3.0 | `ThievesGuild.band_sent`, first band only |
| `Magpies raid your miners at the natural node!` / `... at the rich node!` | 4.0 | `workers_raided(team 0, node)`; node name from `node.get("display_name")` (`the natural node` / `the rich node` fallback by distance); max once per 30 s |
| `Your caravan was robbed: -119 gold` / `Your caravans were robbed: -178 gold` (summed) | 3.0 | `caravan_robbed(team 0, ...)`; summed over 10 s, one line per 10 s |
| `Your caravan was destroyed` / `2 caravans destroyed` (summed) | 3.0 | `Events.unit_died` of an own unit in group `"caravans"`; summed over 10 s |
| `Saltgate is held by the enemy: your caravans wait` | 3.0 | **10.C3** (the caravan, max once per 30 s per the spec); the listener does not repeat it |
| `Picked up a loot sack: 60 gold` | 2.0 | `LootSack.picked(sack, 0, amount)` |
| `Outriders hired: 2 trackers guard your caravans` / `Sweep hired: 3 trackers clear your roads and mines` | 3.0 | `contract_started(0, kind, contract)` |
| `Greywater Lodge pays 20 gold for 2 Magpies` | 2.0 | `reward_paid(0, amount)`: summed at most once per 10 s (count = amount / 10) |
| `Bought Masons' Charter` | 2.0 | `ware_bought(id)` (own bank) |
| `Exchanged 100 gold for 80 crystals` / `... 500 gold for 400 crystals` / `... for 40 essence` | 2.0 | the trade window after a successful `exchange` |
| `Not enough gold` | 2.0 | the top bar on `spend_failed` (3.1) |
| `Right-click a trading post to set the route` | 2.0 | 10.C7 (5.3), once per 2 s |
| Refusals of Buy / exchange / Hire / route (`No Bazaar`, `Already owned`, `Contract already running`, `On cooldown`, `No caravans to escort`, `Route too short`, ...) | 2.0 | the UI that asked (10.C7 / 10.C8) |
Wide messages (`Sweep hired: 3 trackers clear your roads and mines` = 542 px) still sit at y 120: `_message_y` only
moves a message under the help panel when its right edge passes x 1118; that needs a text wider than about 636 px, none
of the lines above.

---

## 14. Help text, objective hint, end screen, settings, audio (10.C8)

### 14.1 Controls help (`GameHUD.help_text`, font 13 `text_muted`, slate at top-right): reflow to 11 lines
```
Left click / drag: select    Shift: add    Double-click: all of a type
Right click: move / attack / gather / rally    X: attack-move    C: stop
H: hold    G: gather    B: build (workers)    Z X C V B: train
Delete: cancel a site    W A S D: walk Vessa    F / Q / E: spells
Ctrl+F/Q/E: learn spell    F1: Vessa    Space: find Vessa    F9: restart
Groups 1-0: Ctrl set · Shift add · Alt steal · N N: centre
F2: army    F3: idle worker    F10 twice: surrender    Numpad 1-6: items
Arrows / edge: pan    Wheel: zoom    Middle drag: rotate    T: shop
R: bounty (Shift+click: stay)    Y: tavern    F5-F7: find champion
Flag: Z raise · Delete remove    U: trade & hunters    G: trade (caravans)
B, B: Bazaar    Bazaar: Z caravan · right-click a post: route
```
- Every key of today's 8 lines is kept (nothing removed, only re-cut) and the three trade items of the spec are added.
  Measured widths: 383, 412, 344, 365, 406, 329, 434, 405, 382, 438, 354 px -> the panel is **458 x 229 at (1126, 16)**.
  It ends 8 px right of the top bar (x 1112) and stays clear of the message line (13).
- The wizard-name placeholder appears three times (lines 4, 5, 5); with the fallback `Your wizard` line 5 grows to
  484 px (panel 504, x 1080): only in the no-hero case, acceptable.
- Tests that read `help_text` for substrings keep passing (`U: trade & hunters`, `R: bounty`, `Y: tavern`...).

### 14.2 Objective hint
`Build a Bazaar (B then B with a worker) to send caravans` is a **message** (463 px at font 17 would also fit the
objective slate, but the objective line is the crown's; do not touch it). Emitted by 10.C1 (13).

### 14.3 End screen (`Skirmish.end_screen_text`, 10.C1; note for the lead)
The spec's single line `Gold earned 2 140 (trade 1 890) · Caravans lost 3 · Workers lost to Magpies 2 · Magpies slain
5` measures **892 px** at font 20 (the panel would grow to 940 px). Ask 10.C1 to emit it as **two lines**:
`Gold earned 2 140 (trade 1 890)` (301 px) and `Caravans lost 3 · Workers lost to Magpies 2 · Magpies slain 5`
(576 px), between `Crystals gathered` and `F9: play again`. Both lines font 20 `text` like the other stats; nothing
else in `hud.gd`'s end panel changes.

### 14.4 Settings toggle `Trade and guilds`
- `GameSettings.trade_enabled := true` (static, saved to `user://settings.cfg` as `trade_enabled`, loaded with the others;
  `reset_defaults` sets true). 10.C8 owns `game_settings.gd`.
- UI: in the **skirmish setup screen** (`main_menu.gd`, after the `Opponent difficulty` row): a row `HBoxContainer`
  centred, separation 10: label `Trade and guilds` font 20 (min height 44, as the difficulty title) + two
  `_toggle_button`s `On` / `Off` in one `ButtonGroup`; default from `GameSettings.trade_enabled`; changing it sets the
  static and saves. Tooltip on both: `Trading posts, Bazaars, caravans, Magpies and the Greywater Lodges (skirmish only).`
- Plumbing: `MenuFlow.start_skirmish` sets `level.set(&"trade_enabled", GameSettings.trade_enabled)` when the level has
  that property (like `apply_kingdoms`), and the restart hook re-applies it. `main_menu.gd` / `menu_flow.gd` are not in
  10.C8's file list: **lead glue** (10.L2) unless the lead extends 10.C8's ownership to them. Missions ignore the setting
  (`trade_enabled` false in mission scenes).
- With trade off: no gold item, U does nothing, the trade window never opens, the Bazaar is absent from the build
  menu (its `BuildingType` is not buildable: 10.C1 / 10.C2), no minimap trade layers (the groups are empty).

### 14.5 Audio (SFX bus, played by the listener of section 12)
| Sound | File | When | Rule |
|---|---|---|---|
| Coin clink | `assets/audio/trade_coin.wav` (0.25 s, two short metallic ticks, generated placeholder) | own delivery, own sack pickup | at most one per 0.3 s; `volume_db -6` |
| Two-note whistle | `assets/audio/trade_whistle.wav` (0.5 s, rising then falling) | a band strikes a **visible** own caravan or own workers (`caravan_robbed` / `workers_raided` of team 0, target `is_visible_in_tree()`) | at most one per 5 s |
| Horn | `assets/audio/trade_horn.wav` (0.8 s, one low horn note) | `contract_started(0, ...)` | at most one per 2 s |
`AudioStreamPlayer` (2D, not positional: HUD feedback), `bus = &"SFX"`, three players kept as children.

---

## 15. Icons for 10.V12 (fallbacks work meanwhile)
| Path | Used by | Size on screen |
|---|---|---|
| `art/icons/buildings/<fire|shadow|ice|nature>_market.png` | build menu, portrait fallback | 56 |
| `art/icons/units/caravan.png`, `magpie.png`, `greywater_tracker.png` | train slot, multi-select, portraits | 56 / 40 |
| `art/icons/posts/heron_ford.png`, `millstone_cross.png`, `lantern_wharf.png`, `saltgate.png` | route buttons, post panel tile | 56 / 88 |
| `art/icons/buildings/magpie_den.png`, `greywater_lodge.png` | Den / Lodge panel tiles | 88 |
| `art/icons/wares/iron_axles.png`, `masons_charter.png`, `tempered_steel.png`, `gambesons.png` | trade window | 40 |
| `art/icons/contracts/outriders.png`, `sweep.png` | Lodge tab | 68 |
| `art/icons/orders/trade.png`, `route.png`, `wares.png` | caravan / Bazaar card | 56 |
| The gold coin, the exchange arrows and the two tab crests | drawn in code here; 10.V12 may replace them later (`art/icons/ui/gold_coin.png` 32 x 32) | 16 / 10 |
All 128 x 128, transparent, no baked border (`ui-style.md` 6.1); `HudSkin.icon(kind, id)` loads them.

---

## 16. Shared looks (both coders)
### 16.1 Colours (constants in `UIStyle` if 10.C8 adds them there, else local; never skinned)
| Name | Value | Used for |
|---|---|---|
| `GOLD_COIN` | `(1.0, 0.78, 0.25)` | coin icons, the top-bar coin, the gold-rim buttons |
| `GOLD_TEXT` | `(1.0, 0.88, 0.5)` | gold numbers everywhere (top bar, prices, cargo, values) |
| Route ribbon | `(1.0, 0.85, 0.3, 0.8)` / preview `(..., 0.45)` | 3D ribbon, minimap route, floating `+28` |
| `NEAR` | `(0.4, 0.9, 0.4)` | `near`, `Open`, `Running`, `Held by you` |
| `FAR` | `(1.0, 0.55, 0.2)` | `far` |
| `OWNED` | `(0.4, 0.95, 0.4)` (the shop's owned green) | `Owned` |
| Held / waiting / closed | `WARN` | `Held by the enemy`, `Waiting: ...`, `Opens at ...`, reasons |
| Minimap | post `(0.85, 0.65, 0.30)`, den `(0.45, 0.35, 0.55)`, lodge `(0.40, 0.62, 0.35)`, road `(0.55, 0.45, 0.30)`, Magpie `(1.0, 0.65, 0.2)`, sack / route / loaded dot `(1.0, 0.85, 0.3)` | section 8 |

### 16.2 The coin glyph (`UIStyle.draw_coin(ci, centre, radius)` or a local helper; used at 16, 12 and 10 px)
Disc `GOLD_COIN`; ring 1 px `(0.55, 0.42, 0.10)` at `radius - 0.5`; inner ring 1 px `(0.85, 0.62, 0.18)` at `0.62 r`;
highlight arc 1.5 px `(1.0, 0.93, 0.65)` radius `0.75 r` from 200° to 290°. At 10 px drop the inner ring.

### 16.3 Keys and who handles them
| Key | Where | Note |
|---|---|---|
| U | `trade_window.gd` (10.C8) | toggle the trade window; also closes the shop and the tavern |
| G (caravans) | `selection_manager.gd` (10.C7) | `ORDER_GATHER`, resolved per unit (6.1) |
| B in the build menu | `selection_manager.gd` (10.C7) | Bazaar placement (`BUILD_KEY_SLOTS["B"] = 5` in the card) |
| Z with a Bazaar selected | existing training slot 1 | caravan |
| Right-click post / own Bazaar | `selection_manager.gd` (10.C7) | route (Bazaar selected) / trade (caravans selected) |
| Esc | `trade_window.gd` | close (as the shop's `_input`) |
All physical keycodes, no modifiers unless written (Shift on the exchange buttons is a click modifier, not a key),
`set_input_as_handled()` after use, ignored while another window / the pause menu / the briefing has focus.

### 16.4 Glue for the lead (nothing in these files belongs to 10.C7 / 10.C8 unless listed)
- `hud.gd` (10.C8 owns it): `TradeWindow.attach(self)` + the exclusivity wiring; `attach_optional` for
  `res://scripts/ui/post_panel.gd` (own), `res://scripts/vfx/trade_popups.gd` (own), `res://scripts/vfx/route_line.gd`
  (10.C7's; guarded load so neither agent blocks the other); connect `selection.neutral_building_clicked` (guarded
  `has_signal`) to open the Lodge tab; the help text of 14.1; `show_banner` closes the trade window.
- `selection_manager.gd` (10.C7): `selected_neutral`, `neutral_building_clicked`, `hovered_post`, `ORDER_ROUTE`, the
  right-click rules of 5.3 / 6.1, the B placement, the minimap right-click on a post.
- `command_card.gd` (10.C7): `BUILD_KEY_SLOTS["B"]`, the market slots (5.1), the caravan `trade` slot, the tracker text.
- `selection_panel.gd` (10.C7): the Bazaar block, the caravan lines, the tracker line, the Magpie loot suffix.
- `minimap.gd` (10.C7): the layers of section 8 with the counters.
- 10.C1 / 10.C3 emit the opening, hint and held messages themselves (13); the listener never duplicates them.
- 10.C1: the end-screen line as two lines (14.3). `main_menu.gd` / `menu_flow.gd`: the toggle row and plumbing (14.4).
- Tracker inspect text is drawn by 10.C7 (it owns `selection_panel.gd` / `command_card.gd`), not 10.C8 as the task
  table says; nothing for 10.C8 there.

---

## 17. Sizes at 1600 x 900 (summary; new things only)
| Thing | Size / position |
|---|---|
| Top bar (trade on) | 624 x 40 at (488, 8); `GOLD_EXTRA 124`; coin 16, number font 20 min 60, `GOLD_TEXT` |
| Controls help | 458 x 229 at (1126, 16), 11 lines <= 438 px |
| Build menu | Bazaar at r2c2 (index 5), key B |
| Bazaar card | r1c1 Caravan Z, r1c2 Set Route (no key), r1c3 Wares U, r2c1-c4 route buttons (value tag 26 x 12 at (4, 48), near / far chip 26 x 12 at (2, 2)) |
| Bazaar block | 264 x 100 at (1000, 676): lines y 676 / 696 / 716 / 736 font 13, y 756 font 12 |
| Caravan view | stat line (696, 730), state line (696, 750), font 14; icon coin 6 px bottom-right |
| Tracker view | contract line (696, 750); card text y 740 / 762 |
| Route ribbon | 0.25 m wide at y 0.30, dash 1.0 m / gap 0.6 m, scroll 1.5 m/s, end rings r 0.6 |
| Route chip | mouse + (18, 12), height 26, font 13 |
| Minimap | roads 2 px; posts 5 x 5 + holder border; houses 6 x 6; sacks 3 x 3; caravans 4 x 3 (+ 1 px dot); Magpies 3 x 3; route 1 px |
| Post / Den / Lodge panel | 676 x 204 at (588, 670); tile 96 at (588, 670); title (696, 670); lines y 700 / 722 / 746 / 770 / 806; button 150 x 32 at (1104, 674) |
| Trade window | 760 x 464 at (420, 156); title (430, 166); tabs 100 x 28 at (516, 166) and 176 x 28 at (622, 166); resources end x 1134; X (1146, 168); rule y 198; footer (430, 588) |
| Bazaar tab | ware rows 740 x 64 at (430, 204 + 70 k); tile 48 at (8, 8); name (68, 6); effect (68, 26); who (68, 44); price (628, 4); note (628, 20); Buy 104 x 24 at (628, 34); exchange block (430, 486): buttons 220 x 36 at (438, 516) / (672, 516), hint (438, 558), ledger (920, 516) |
| Lodge tab | header (438, 206); rows 740 x 90 at (430, 228) / (430, 324); tile 76 at (6, 7); name (92, 4); sub (92, 26); description (92, 44) w 530; col C x 628: price y 4, pop y 22, reason y 36, Hire 104 x 24 y 62, running bar 104 x 6 y 42; reward line (438, 426); tips y 452 / 470 / 488 |
| Tavern col C (trade on) | price A y 2, price B y 16, pop / reason y 29 (font 10), Hire 104 x 22 y 40, Hire · gold y 64; fallen: Revive y 18, Revive gold y 42, Dismiss y 66 |
| Floating text | `Label3D` font 40, pixel_size 0.006, +1.5 m over 1.0 s, at Bazaar + 5.3 m |
| Messages | y 120, font 22, table of section 13 |

## Done when
- [ ] **10.C7 cards**: `B` places the Bazaar from the build menu at r2c2 (index 5) with the tooltip of section 4 and the
  grid's reasons; a selected own Bazaar shows `train_caravan` Z (r1c1), `route` (r1c2, no key, pending order
  `ORDER_ROUTE` with the cross cursor; a ground click while pending gives `Right-click a trading post to set the
  route`), `wares` U (r1c3) opening the trade window on the Bazaar tab, and 4 `route_<post_id>` buttons in r2 sorted by
  value with the value tag, the near / far chip, the selected state on the current route and the disabled reasons
  `Opens at 4:00` / `Held by the enemy`; no rally slot for markets; caravans show Move / Stop / Hold / `trade` G; mixed
  with workers the r1c4 slot is `gather` with the `Gather / Trade` tooltip; trackers and enemy trackers show the inspect
  block texts of 6.3; `slot_ids()` lists exactly these ids.
- [ ] **10.C7 selection**: `market_block_text()` returns the 5 lines of 5.2 for an own completed Bazaar (with the two
  `WARN` waiting forms), `""` for enemy Bazaars and other buildings, `building_info` empty and no rally line for markets;
  the caravan single view has the stat and state lines of 6.2 (coin only while loaded), loaded caravan icons carry the
  6 px coin; a tracker gives `current_view() == "single"` with the `Contract: ... left` line; a Magpie with loot shows
  ` · Carrying 60 gold`; G then a post orders `command_trade` on caravans, then the own Bazaar sends them home, then a
  node still makes workers gather; right-click a post with a Bazaar selected calls `set_route` (refusals to the message
  line), right-click the ground gives the throttled hint; clicking a post or a guild house sets `selected_neutral`,
  emits `neutral_building_clicked`, calls `set_selected(true)` and clears everything else (Esc clears it).
- [ ] **10.C7 route line**: `RouteLine.attach(hud, selection)` in group `"route_line"`; `show_route` / `hide_route` /
  `is_showing` / `shown_points`; the ribbon (0.25 m, y 0.30, dashed 1.0 / 0.6 m, scrolling, end rings) appears with an
  own Bazaar or own caravans selected and follows `route_changed`; the preview ribbon at alpha 0.45 and the chip
  (7.2 texts for a near post, a far post, a held post, the current route) while hovering a post with a Bazaar selected;
  no per-frame rebuild (a counter `rebuild_count` proves it); `PERF OK` with the ribbon shown.
- [ ] **10.C7 minimap**: the layers of section 8 in the stated passes with the counters `drawn_roads`, `drawn_posts`,
  `drawn_held_posts`, `drawn_guilds`, `drawn_sacks`, `drawn_caravans`, `drawn_loaded_caravans`, `drawn_magpies`,
  `route_drawn`; roads under the fog; a held post's border in the holder's colour; a fogged Magpie / sack not drawn;
  right-click near a post sets the route (Bazaar) or trades (caravans); nothing in `scripts/ui/` calls a `_private`
  function of another script.
- [ ] **10.C8 top bar**: with a `GoldBank` for team 0 the bar is 624 x 40 at (488, 8) with the coin + number in
  `GOLD_TEXT` after essence (`GOLD_EXTRA 124`); 500 x 40 at (550, 8) without one; `spend_failed` flashes `WARN` 0.4 s
  with the shake and sends `Not enough gold`; `is_gold_flashing()`; the income pop on a +10 rise; the help panel of
  14.1 measures at most 458 px wide and its rect never intersects the bar's.
- [ ] **10.C8 trade window**: 760 x 464 at (420, 156) with the title bar of 10.1 (two tabs, gold / crystals / essence,
  stud X); `open(&"bazaar")` from U and the Wares button, `open(&"lodge")` from a Lodge click, `toggle`, `close` on
  U / Esc / X / match end, `opened` closes the shop and the tavern and vice versa, `open()` returns false with no bank;
  Bazaar tab: 4 ware rows with name / effect / who / price / note / Buy (owned and refused states, reasons from
  `can_buy_ware` in the note and the tooltip, `press_buy` calling `buy_ware`), the exchange buttons (Shift x5 labels,
  `press_exchange`, refusals), the ledger, the footer with the `No Bazaar` warning; Lodge tab: header (open / closed),
  two contract rows with the four column-C states (hireable, refused with the guild's reason order, running with the
  time bar, cooldown), the reward line with `Rewards received`, the tips, the footer count; refresh 4 Hz; a test at
  1600 x 900 reads the rects of section 17.
- [ ] **10.C8 tavern**: with gold the column-C layout of section 11 (22 px buttons, price B, `HIRE · GOLD`, `Revive 180
  gold`), `press_hire_gold` -> `hire(id, true)`, `press_revive_gold` -> `revive(ch, true)`, disabled with `Not enough gold`
  in the tooltip; without gold the step-9 layout and tests unchanged; the title bar gold item.
- [ ] **10.C8 panels**: `PostPanel.attach(hud, selection)` 676 x 204 at (588, 670), visible only with `selected_neutral`;
  the post lines of 9.2 (status, value or `Build a Bazaar to trade`, holder, traffic, hint) and the `Set as route` /
  `Current route` button; the Den's read-only text with the visible-Magpie count; the Lodge lines with the `Contracts
  [U]` button; a Lodge click also opens the window on its tab.
- [ ] **10.C8 listener, texts, sounds**: `TradePopups.attach(hud)` in group `"trade_popups"`; every message of section
  13 with its throttle / summing, never duplicating 10.C1 / 10.C3's; the `+28` / `+60` / `-119` `Label3D` texts with the
  pool of 8; the three sounds on `bus = &"SFX"` with their rate limits; `GameSettings.trade_enabled` saved and loaded
  (the menu row and `MenuFlow` plumbing documented for the lead); the help text of 14.1 verbatim; `PERF OK`.

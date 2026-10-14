# UI: Wave Strike HUD (M2 Muster panel, task WS2.D1 for WS2.U1; Muster Pad WS3.D1 in 7, upgrades WS4.D1 in 8)

Written 2026-10-13. Source: `wave-strike.md` 14.4 (needs), 7.4 (M1 intent), `ui-style.md` (tokens, frames, fonts, tooltips,
animations). Pixels at 1600 x 900, bottom panels anchored bottom, right panels anchored right (`ui-hud.md`). Colours use the
`ui-style.md` section 1 tokens of the **player's kingdom** (`UIStyle.set_kingdom`, all 4 kingdoms exist in `UIStyle`);
`GOLD`, `WARN`, crystal `(0.45, 0.85, 1.0)` never skinned. M1's top strip (Bastion bars, horn, clock, bank line) stays;
M1's 330 px top-right buy panel is **removed** and replaced by the Muster panel below. The skirmish command card is hidden in
WS (lane units take no orders); the hero column (272-582) stays for the wizard when `wizards_enabled`.

## 1. Muster panel: 994 x 224 at (590, 660), heavy frame (3.1), drop shadow, content margin 10
| Zone | Rect | Content |
|---|---|---|
| Title row | (600, 670) 976 x 20 | `Muster` font 20 Cinzel `title` left; right: `Horn 7 in 0:42` font 16 `text` + the **horn ring** (1.4) 20 x 20 at (1556, 670) |
| Tier labels | y 694, font 12 Cinzel `text_muted`, one per group, centred over its group | `Keep · T1`, `Stronghold · T2`, `Citadel · T3`; the group of the current tier in `title`; a locked group adds ` · Requires Stronghold` / ` · Requires Citadel` once in `WARN` (French: `Forteresse requise`, `Citadelle requise`; 12 px fits 240 / 150 px: if wider, `WARN` lock glyph 10 x 12 + tooltip) |
| Cards | 72 x 118 at y 710, gap 6 | Group T1 x 600-978 (5), divider, T2 x 1000-1222 (3), divider, T3 x 1244-1394 (2). Divider = 22 px gap with a 2 px `groove` + 1 px `frame_light` vertical line, 6 x 6 `frame_light` diamond at each end (as 5.1 of ui-style) |
| Right column | x 1416-1576 (160 wide) | Coffer button 160 x 40 at y 710; Next tier 160 x 40 at y 756; **field counter** 160 x 54 at y 802 (section 3); `Next wave: 14 units` font 12 `text_muted` at y 860 |
| Supply bar | 794 x 18 at (600, 836) | Bar style 5.3, fill `GOLD`, text `Supply  38 / 52` font 13; `WARN` fill at cap; the next cap shown as a tick + `72` font 10 `text_muted` right of the bar when a tier is rising |
| Hint line | (600, 860) font 12 `text_muted` | `Key / click = buy  ·  Ctrl = rank  ·  Shift = upgrade  ·  Alt = sell  ·  P = pad  ·  L = arrange  ·  I = enemy` (French may wrap: max 2 lines, font 11 if wider than 794; with the pad / upgrades built, sections 7-8) |

### 1.1 Card anatomy (72 x 118, one `Button` + `_draw` overlay; `custom_minimum_size` locked so French text never resizes it)
| Part | Rect in card | Look |
|---|---|---|
| Frame | 0-72 x 0-118 | Button frame 3.3; rim colour **kingdom colour** (`UIStyle.kingdom_color`) at the normal state, so the four kingdoms read at a glance; inside `panel_inner` |
| Art slot | (4, 4) 64 x 64 | `res://art/icons/units/<id>.png` at 64 px (`LINEAR_WITH_MIPMAPS`), over a radial gradient `trim_glow` alpha 0.30 -> `panel_inner`; fallback: 2-letter abbreviation font 22 Cinzel `title` |
| Key badge | 20 x 14 at (2, 2) | Bg `(0, 0, 0, 0.75)`, 1 px `frame_dark`, radius 2, `KeyLabels.of(code)` font 11 `GOLD` (`,` `.` `/` `;` printed as-is) |
| Role tag | 32 x 12 at (38, 56) | Bg `(0, 0, 0, 0.7)`, text font 9 `text_muted`: `Melee` / `Ranged` / `Rider` / `Heavy` / `Support` / `Caster` (caster = `CasterKit.CASTERS`, support = `support_kind != &""`, rider = guide role `cavalry`, heavy = siege role or pop >= 3, else `attack_range <= 3.0` Melee / Ranged). French `Mêlée / Tir / Monté / Lourd / Soutien / Mage` |
| Name | (2, 70) 68 x 24 | Font 11 `text`, centred, 2 lines max, autowrap, font 10 if 3 lines would be needed, then ellipsis (longest ids: `frostcrown_juggernaut`, `veilborn_dreadrider`, `sunforge_cataphract`) |
| Price | (2, 96) left half | Crystal diamond 10 px + number font 12 embolden 0.5 crystal text colour `(0.75, 0.92, 1.0)`; `WARN` when unaffordable |
| Pop | (38, 96) right half | Shield glyph 10 px `text_muted` + `2` font 12 `text`; `WARN` when `pop_used + pop > cap` |
| Copies | (2, 108) | `x3` font 10 `text`; with `max_copies`: `3 / 4` and at the max `4 / 4` in `GOLD` |
| Rank pips | 6 x 6 diamonds at (54 + 8 j, 110), j = 0-1 | Filled `GOLD` = rank reached (Drilled, Elite), empty `(0.3, 0.3, 0.3)` (6.2 pips) |

### 1.2 Card states (rim = px 1-2 of the button frame)
| State | Rim | Inside / icon | Extra |
|---|---|---|---|
| Affordable (normal) | Kingdom colour | `panel_inner`, icon full | Price in crystal colour |
| Hover | `frame_light` | lightened 0.12 | 1 px `trim_glow` halo (fade in 0.08 s); tooltip 2 |
| Pressed | `frame_dark` | darkened 0.25 | Icon offset (+1, +1); Ctrl held: rim `GOLD`; Alt held / right button: rim `WARN` (sell preview) |
| Unaffordable / supply full | Kingdom colour at alpha 0.5 | Icon `self_modulate (0.55, 0.55, 0.55)` | `modulate.a 0.7` on the card; the failing number in `WARN`; a key press shakes the price ±3 px, 0.3 s |
| Locked tier (group) | `frame_dark` | Icon `(0.35, 0.35, 0.35)`, `modulate.a 0.45` | A 14 x 16 lock glyph `text_muted` centred on the art; the group label carries the reason, cards do not |
| Maxed (`copies == max_copies`) | `GOLD` | normal | Copies text gold; buy key -> message `Max 4 copies` + price shake |
| Just bought (0.35 s) | `trim_glow` -> normal | Icon scale 1.0 -> 1.10 -> 1.0 in 0.2 s | Copies text pops scale 1.4 -> 1.0; a +1 float `text` font 12 rises 16 px and fades |
| Rank up (0.5 s) | `GOLD` flash | | New pip pops 1.0 -> 1.6 -> 1.0 (ui-style 9) |
| Sold (0.35 s) | `WARN` -> normal | Icon `modulate.a` 1 -> 0.6 -> 1 | Copies pops; `-1` float in `WARN` |
| Empty slot (Fire slot 10) | `frame_dark` alpha 0.5 | `panel_inner` darkened 0.2, no icon | Key badge hidden; tooltip `Empty slot (later: Ember Crucible)` |

### 1.3 Coffer and next tier buttons (160 x 40, button frame 3.3, text font 13 left, key badge 20 x 14 at (4, 4))
| Button | Text (two lines font 13 / 11) | States |
|---|---|---|
| Coffer | `Coffer 3 / 8` + `420  ·  +10 / horn` | Normal / hover / pressed as 3.3; disabled (`can_buy_coffer != ""`) keeps `modulate.a 0.45`; all bought: `Coffers: all 8 bought`, no badge |
| Next tier | `Stronghold` + `600  ·  T2 cards, Drilled, supply 52` | **Primary look** (6.4: `trim_glow` rim + inside alpha 0.18) while affordable; rising: text `Stronghold rising: 38 s`, a 160 x 4 `GOLD` progress line along the bottom edge; max tier: `Citadel reached`, disabled, no badge |
On the tier change: the newly open group's cards flash `trim_glow` rim 0.4 s, its label goes `title`, the lock glyphs fade 0.3 s.

### 1.4 Horn countdown ring (20 x 20, title row; also 36 x 36 around the top strip's horn label glyph at its left)
`draw_arc` width 3 clockwise from 12 o'clock: remaining fraction `time_to_next_horn / horn_interval` in `GOLD` over a
`frame_dark` track; inside the last `horn_warning` seconds the arc turns `(1.0, 0.55, 0.35)` and pulses alpha 0.6-1.0 at 2 Hz;
at the horn: a `trim_glow` ring expands 20 -> 48 px over 0.5 s while fading (the M1 1 s horn flash stays). Last Horns: ring
colour `WARN`, label `LAST HORNS` (unchanged).

## 2. Tooltips (custom tooltip of ui-style 8; max width 320, 8 px above the card)
| Line | Card | Coffer / tier |
|---|---|---|
| 1 | `Flame Guard  [Z]` + `Rank 1 / 3` right (`Drilled` / `Elite` names) | `Coffer 4  [G]` / `Stronghold  [U]` |
| 2 | `120 crystals · 1 pop · 300 HP · 12 dmg · range 1.6 · speed 5.0` (currency colours) | `420 crystals · +10 crystals per horn` / `600 crystals · opens T2 cards, Drilled rank, supply 52` |
| 3 | Unit Guide role + first pro (`data/ui/unit_guide.json`), font 13 `text_muted`; caster: `In the lane: Slag Rain, Mana Scald on auto · Umbral Passage off` (14.1 table) | |
| 4 | Reason in `WARN` (`Not enough crystals`, `Supply full (52/52)`, `Requires Citadel`, `Max 4 copies`) or `Ctrl+Z: Drilled (needs Stronghold)` in gold; `Alt+Z / right-click: sell for 60` | Reason in `WARN` |
Role tag hover: `Casters autocast in the lane; max 4 copies` (short, one line).

## 3. Field counter (160 x 54 at (1416, 802), slate 3.2, 1 px `frame_metal` border)
- Line 1 font 12 `text_muted`: `On the field`; line 2 font 16 embolden 0.5 `text`: `187 / 200` (`level.field_count(seat)` /
  `rules.field_cap`); >= 90 %: number `(1.0, 0.75, 0.3)`; at cap `WARN`.
- Line 3 font 11, only when `held_last_horn(seat) > 0`: `12 held at home` in `WARN` with a 10 px pause glyph; the box border
  pulses `WARN` alpha 0.4-0.9 at 1.5 Hz for 3 s after the horn. Tooltip: `Lane cap reached: 12 units of this horn wait at the
  Bastion and march with the next horn`.
- Enemy field count lives in the enemy roster peek only (not on the panel).

## 4. Enemy roster peek (key **I** toggles; also hover the enemy Bastion bar = shows while hovered)
Slate panel 300 x 236 at (1284, 410), anchored right, `modulate.a` 0 -> 1 in 0.1 s. Title `Enemy roster · Shadow (Citadel)`
font 15 Cinzel in the enemy kingdom colour. Below: 10 mini cards 48 x 56 in the same 5 / 3 / 2 grouping (icon 40 at (4, 2),
count font 11 `text` bottom-right on a dark badge, pips 4 px, locked groups alpha 0.35), rows at y 440 and y 500 (T2 + T3 on
row 2 with the divider). Footer font 12 `text_muted`: `On the field 142 / 200 · Supply 44 / 72 · Last wave 23`. Never clickable
(`mouse_filter IGNORE` except the X stud 6.4). Full vision rule (Q6): data read live, refresh 0.5 s.

## 5. Keys (physical; shown with `KeyLabels.of`, AZERTY prints W X C V B N , ; : !)
| Keys (QWERTY) | Action |
|---|---|
| **Z X C V B** | Buy card slot 1-5 (T1) |
| **N M ,** | Buy card slot 6-8 (T2) |
| **. /** | Buy card slot 9-10 (T3) |
| Ctrl + card key / Ctrl+click | Rank up that line |
| Alt + card key / Alt+click / right-click | Sell one copy (50 % refund) |
| **G** | Buy next Coffer (was B) |
| **U** | Next tier (was N) |
| **I** | Toggle the enemy roster peek |
| **P** / **L** / **Ctrl+L** / Esc | Pad camera / auto-arrange / undo / cancel a ghost (section 7) |
| Shift + key / Shift+Ctrl + key / Shift+Alt + key, **R Y O** | Upgrade A / B / cancel, Armoury Weapons / Armour / Arcana (section 8) |
Unchanged: W A S D Q E F, Space, F1, T, J, Tab, F9 / F12. `,` `.` `/` by physical keycode (`KEY_COMMA`, `KEY_PERIOD`,
`KEY_SLASH`); the AZERTY labels come from `KeyLabels`, never hard-coded. Keys act only while no `LineEdit` has focus and the
match is not over (as M1).

## 6. Readability (1080p and 1440p)
`canvas_items` stretch keeps the 1600 x 900 layout: at 1920 x 1080 everything is x1.2 (smallest text font 9 -> 10.8 px, OK),
at 3440 x 1440 x1.6. Minimum sizes kept: card icon 64, key badge 14 tall, numbers >= font 12. Panel width 994 never grows;
French strings get the wrap / shrink rules of 1.1 and the two-line buttons of 1.3; test with `-- --lang=fr` in the UI Lab.

## 7. Muster Pad (WS3.D1 for WS3.U1 / U2; rules in wave-strike.md 15)
Everything on the pad is 3D and **unlit, `no_depth_test` off** (tokens must sit on the plate, never through the forest); 2D
parts (box select, messages, mini-pad) use the HUD tokens. Role colours (15.1) are **never skinned**: Melee `(0.85, 0.35, 0.30)`,
Ranged `(0.35, 0.70, 0.95)`, Rider `(0.95, 0.75, 0.30)`, Heavy `(0.70, 0.50, 0.90)`, Support `(0.45, 0.85, 0.50)`, Caster
`(0.95, 0.50, 0.85)`. Plate: stone `(0.30, 0.28, 0.27)`, 1 m rim `(0.22, 0.20, 0.19)`, own pad rim lit with `trim_glow` alpha 0.25.

### 7.1 Tokens (one per copy; 2 MultiMeshes per pad: discs 1x1 / 2x2, + one flat `Sprite3D` icon each)
| Part | 1x1 (cell 1.5 m) | 2x2 | Look |
|---|---|---|---|
| Disc | diameter 1.3 m, 0.15 m high | 2.8 m, 0.2 m high | Body `panel_inner` lightened 0.15 (enemy pad: enemy kingdom `panel_inner`); **rim** 0.12 m / 0.2 m in the role colour, full bright |
| Icon | 0.9 m square, 0.05 m above the disc | 2.0 m | `art/icons/units/<id>.png`, lying flat, **front edge toward row 0** (the icon reads from the camera behind the pad); fallback: the 2-letter abbreviation Cinzel in `title` on a dark disc |
| Rank band | a 0.1 m `GOLD` arc on the rim, 60° per rank (Drilled 60°, Elite 120°), from the back (row side) clockwise | same, 0.15 m | Reads rank without pips; tooltip has the name |
| Upgrade ticks (8.4) | 0.25 m gold triangle on the rim at 45° front-right (A) and 45° front-left (B) | 0.4 m | Only bought upgrades; 2 px gold corners on the mini-pad |
| Held marker | | | Copies past the field cap (back-most, 15.3): disc `modulate.a 0.55` + a 0.4 m `WARN` pause glyph on the icon; tooltip `Stays home this horn (lane cap)` |
States: **normal** as above; **hover** = rim lightened 0.3 + the unit's real model as a 50 % ghost standing on it (`modulate.a
0.5`, no shadow) + tooltip 7.5, 0.08 s fade; **selected** (box select 7.3) = a 0.1 m `GOLD` ring 0.2 m outside the rim, icon
`modulate` 1.15; **dragging** = the token lifts 0.4 m over 0.1 s, `modulate.a 0.7`, its source cells keep a dashed `frame_light`
outline (dash 0.3 m) until release; **just placed** (0.35 s) = disc scale 1.15 -> 1.0, `trim_glow` ring 0.8 -> 1.6 m fading;
**sold** (0.35 s) = `WARN` flash, scale 1.0 -> 0.6, alpha -> 0; **snap back** (refused move) = token flies back in 0.15 s with a
`WARN` rim flash 0.3 s. Tokens never cast shadows; max 84 icons per seat, rebuilt only on `MusterPad.changed`.

### 7.2 Grid, edges, spawn box
- Cells: 1 px lines (0.03 m quads) `frame_light` alpha 0.18 on the own pad, 0.10 on the enemy pad. Every 4th column a 0.05 m
  line alpha 0.30 (wing / centre reading: cols 4 and 12 = the Line wings). Row numbers `0`-`11` font 0.5 m `text_muted` alpha 0.5
  along the left edge; no column numbers.
- **Front edge** (row 0 side): 0.12 m `GOLD` line + a `GOLD` chevron 2 m wide, 1 m ahead of the plate, pointing to the enemy;
  label `FRONT` 0.6 m Cinzel `GOLD` alpha 0.7 under the chevron (French `AVANT`). Back edge: 0.06 m `frame_dark`.
- **Zone shading** (own pad only, toggles with the hover of the Arrange button, alpha 0 -> 0.12 in 0.15 s): the Line zones of
  15.4 tinted in their role colour, so "where will auto-place put this" is visible before pressing L.
- **Spawn box outline** (lane): one flat 24 x 18 m rectangle mesh, stroke 0.4 m `GOLD` alpha 0.35, front edge 0.6 m + the
  same chevron, 12 faint row lines alpha 0.12. Fades in 0.3 s at horn - 5 s (`horn_soon`), pulses alpha 0.25-0.45 at 1 Hz, flashes
  alpha 0.8 at the horn, fades 0.5 s after. Enemy spawn box: same in the enemy kingdom `frame_light`, alpha 0.25, no chevron.
- **Horn snapshot cue**: at the horn every own token blinks `trim_glow` 0.2 s (the shape was read); tokens moved after it get
  a 0.3 m `text_muted` hourglass on the icon until the next horn (tooltip `Moves after the horn count next horn`). Hourglass is
  the only per-token state the panel also shows (mini-pad cell hatched).

### 7.3 Ghosts, drag, box select, sell
| Interaction | Look |
|---|---|
| Place ghost (manual buy, 15.2) | The unit model `modulate.a 0.5` + a footprint quad on the hovered cells: free `(0.45, 0.85, 0.50)` alpha 0.45, blocked `WARN` alpha 0.45 (and the blocking token's rim flashes `WARN`); cursor off the pad: ghost hidden, cursor `CURSOR_FORBIDDEN`. Price follows the cursor: `120` crystal font 12 on a dark badge 8 px right of the cursor, `WARN` when unaffordable. Shift+click keeps the ghost: badge adds `· again` |
| Hover ghost | 7.1 hover (model 50 %), only on own tokens, never while dragging or placing |
| Drag | Press, move > 6 px: 7.1 dragging + the footprint quad under the cursor (green / red; **swap** = the target token's rim `GOLD` + quad `GOLD` alpha 0.35). Group drag: every selected token lifts, quads for each, one red = all red |
| Box select | 2D rectangle 1 px `GOLD` + fill `GOLD` alpha 0.12 (same as unit box select) from a press on empty cells; selection cleared by a click on empty cells / Esc / the horn. Max = all own tokens |
| Right-click a token | Sell: tooltip-sized confirm **not** needed; the card's 1.2 "Sold" state plays on the panel and the token 7.1 sold. Refund text floats `+60` crystal colour font 12 rising 1 m |
| Cancel | Esc or right-click with a ghost = ghost gone 0.1 s, nothing paid, message line nothing |

### 7.4 Messages, camera, setting, keys
- Refusal `No room on the pad` -> message line (y 120) in `WARN` as `No room on the pad  ·  L = auto-arrange`, 2.5 s, plus the
  card price shake (1.2) and the mini-pad border `WARN` flash 0.3 s. `Cell blocked` (click on a red ghost) = the quad shakes
  ±0.15 m 0.2 s, no message.
- **P** = camera to the pad: pivot (pad centre), yaw from behind the pad looking toward the front edge, distance so the plate
  fills ~70 % of the height, 0.35 s ease; P again (or any pan) = back to the saved camera. The hero tile / Space unchanged.
- **L** = auto-arrange: every own token flies to its new cell in 0.3 s (staggered 0.01 s), then message `Arranged · Ctrl+L =
  undo (5 s)` in `text` 2.5 s; **Ctrl+L** within 5 s = the reverse flight, message `Undone`.
- Setting `Place on buy` (Settings > Gameplay, `OptionButton` **Auto** / **Manual**, tooltip `Auto: new copies fill the Line
  formation, drag to fix · Manual: every buy shows a ghost on the pad`); mirrored by the mini-pad toggle 7.6.
| Keys (physical) | Action |
|---|---|
| **P** | Centre on the pad / back |
| **L** / **Ctrl+L** | Auto-arrange (Line) / undo within 5 s |
| Left-click / Shift+click (ghost) | Place / place and keep the ghost |
| Right-click, Esc | Cancel the ghost; right-click a token = sell |
| Drag / drag on empty / drag a selected token | Move or swap / box select / move the group |
Badges show `KeyLabels.of` (P, L print the same on AZERTY). I, G, U, card keys unchanged.

### 7.5 Tooltips (ui-style 8, 8 px above the cursor, max 320)
Own token: `Flame Guard  ·  Drilled` / `Cell (5, 2) · spawns row 2, left of centre` font 13 `text_muted` / upgrades bought
(`Shield Drill`) in `GOLD` / `Drag = move · right-click = sell for 60`. Enemy token: name + `x4` only. Pad button tooltips:
`Centre on the pad  [P]`, `Auto-arrange: Line formation  [L]`, `Undo the arrangement  [Ctrl+L] (3 s)`.

### 7.6 Enemy pad and the optional 2D mini-pad (console layout, ui-sc2-console.md 6)
- Enemy pad: tokens 7.1 with the enemy kingdom body, grid alpha 0.10, no hover ghost, no selection, no zone shading; its row
  numbers hidden. The I peek (4) gains a footer line `Front row: 4 Heavy · 6 Melee · wings 4 Rider` font 12 `text_muted`.
- **Mini-pad** (optional, build after WS3.U2 if JS keeps it): in the console's free band x 1056-1408 (between the T3 cards
  ending x 1048 and the right column), a slate 3.2 **114 x 86** at (1064, 780): 16 x 12 cells of 7 px, grid `frame_light` alpha
  0.18, front edge (top) 1 px `GOLD`, tokens = 5 x 5 (1x1) / 12 x 12 (2x2) rounded squares in the role colour, hatched when
  moved after the horn, 2 px gold corners for upgrades. Hover a cell = the token's tooltip 7.5; click = centre the camera on
  that cell (P-like); no placing in 2D. Buttons 108 x 24 (button frame 3.3, font 12, badge 20 x 14): `Pad [P]` at (1184, 780),
  `Arrange [L]` at (1184, 808), `Undo [Ctrl+L]` at (1184, 836) (disabled outside the 5 s, `modulate.a 0.45`). Status column
  x 1296-1404: `Pad 38 / 192` font 12 `text` at y 782, `Held 12` in `WARN` at y 800 when any, and a 108 x 24 toggle `Place:
  Auto` / `Place: Manual` at (1296, 836) bound to the setting. Pre-console layout (994 panel): no mini-pad, the three buttons
  become 50 x 24 at (1416, 860), (1470, 860), (1524, 860) replacing the `Next wave` line (moved into the field counter tooltip).

## 8. Card upgrades and Armoury (WS4.D1 for WS4.U1; rules in wave-strike.md 16)
### 8.1 Upgrade pips on the card (1.1 row `Rank pips` keeps x 54 / 62; copies text ends by x 26)
| Pip | Rect in card | Bought | Available (tier open) | Locked (tier) |
|---|---|---|---|---|
| A | 6 x 6 square at (30, 110) | Filled `GOLD` | 1 px `frame_light` outline, inside `panel_inner` | 1 px `(0.3, 0.3, 0.3)` outline |
| B | 6 x 6 square at (38, 110) | Filled `GOLD` | same | same |
Squares (not diamonds) so they never read as ranks. Hover a pip = that upgrade's tooltip lines only (8.3); click a pip = buy it
(same as Shift / Shift+Ctrl + key). **Bought flash** 0.5 s: the pip pops 1.0 -> 1.8 -> 1.0 in `trim_glow` -> `GOLD`, the card rim
`GOLD` 0.4 s, a float `Shield Drill` font 11 `GOLD` rises 16 px. **Cancel window** (5 s): the pip blinks `GOLD` alpha 0.5-1.0
at 2 Hz; Shift+Alt + key / Shift+Alt+click = pip back to outlined, `+145` refund float. Unaffordable press: price shake (1.2),
reason on the message line. Hint line (1) carries `Shift = upgrade`.

### 8.2 Armoury strip (console free band x 1056-1408; 3 buttons 108 x 40 at y 730: Weapons (1064), Armour (1180), Arcana (1296))
| Part | Look |
|---|---|
| Frame | Button frame 3.3; key badge 20 x 14 at (4, 4) `R` / `Y` / `O` (same on AZERTY) |
| Glyph | 24 px at (6, 10): crossed blades / kite shield / rune circle, `text` colour; drawn in code (6.1 fallback rules) |
| Text | Line 1 (34, 5) font 13 `text`: `Weapons II` (roman level reached, `Weapons` at level 0); 3 level pips 6 x 6 diamonds at (34 + 8 j, 23), filled `GOLD` per level (Arcana: 2 pips) |
| Price | (70, 22) right-aligned to x 102: crystal diamond 8 px + `350` font 11 crystal text colour; `WARN` unaffordable; at max: `Max` font 11 `GOLD`, no price |
| States | Normal / hover / pressed as 3.3; **gated** (`Requires Stronghold` / `Citadel`): `modulate.a 0.45` + a 10 x 12 lock glyph over the price; **max**: rim `GOLD`, disabled, no badge; **bought** flash: rim `trim_glow` 0.4 s, the new pip pops 1.0 -> 1.6 -> 1.0, every own token on the pad blinks the role rim 0.2 s |
Pre-console layout: the strip is 3 buttons 50 x 40 at (1416, 860), (1470, 860), (1524, 860) (glyph + pips only, text in the tooltip).

### 8.3 Tooltips (card tooltip 2 gains lines 5-6; Armoury tooltip)
| Line | Text (effect text from the templates below) |
|---|---|
| Card 5 (A) | `Shift+Z: Shield Drill (+3 armour) · 145` in `GOLD` when affordable, `text_muted` with ` · Requires Stronghold` in `WARN` when gated; bought: `Shield Drill: bought` `text_muted` + a 10 px check glyph `GOLD`; in the window: `Shift+Alt+Z: cancel Shield Drill (4 s)` `GOLD` |
| Card 6 (B) | `Shift+Ctrl+Z: War Cry (haste 4 s at release) · 240` same rules; T3: the signature name |
| Armoury 1 | `Weapons II  [R]` + right `Level 1 / 3` |
| Armoury 2 | `350 crystals · +6 % damage per level · next horn` (Arcana: `casters and support: +15 spell power, +20 % mana regen`) |
| Armoury 3 | Reason in `WARN` (`Requires Stronghold`, `Max level`, `Not enough crystals`); else `Applies to units spawned from the next horn` `text_muted` |
Effect templates (built from `card_upgrades.tres`, never hand-typed per card): `mods` flat -> `+3 armour` / `+6 HP/s` / `+25
spell power`, pct -> `+20 % HP` / `+40 % mana, +50 % regen`; `type` -> `+1.5 range`, `marked 3 s on hit (+15 % damage taken)`,
`chill 2 s on hit`, `on-hit lasts x1.5`, `support x1.4`, `interval x0.75`; `release` -> `haste 4 s at release`, `braced 6 s at
release`, `shroud 5 s at release`, `shield 150 for 10 s at release`. Stat names through `Loc`, numbers formatted `%g`.

### 8.4 Keys and token ticks
| Keys (physical) | Action |
|---|---|
| **Shift** + card key / Shift+click | Buy upgrade A |
| **Shift+Ctrl** + card key / Shift+Ctrl+click | Buy upgrade B |
| **Shift+Alt** + card key / Shift+Alt+click | Cancel the last upgrade of that card within 5 s |
| **R** / **Y** / **O** | Armoury Weapons / Armour / Arcana next level |
Modifier precedence while a card key is pressed: Shift+Ctrl > Shift+Alt > Shift > Ctrl > Alt > plain. Held Shift shows the
card rim in `GOLD` (pressed state), like Ctrl today. Token ticks: 7.1 (gold triangles A front-right, B front-left, 0.25 / 0.4 m);
a bought upgrade adds its tick on every token of the card in the 8.1 flash; ticks persist through moves and saves.

## Done when
- [ ] WS3.D1 (this spec, 7): tokens / grid / ghosts / box select / spawn box / messages / P L Ctrl+L / setting / mini-pad.
- [ ] WS3.U1 (ui-coder): tokens 7.1 (MultiMesh + icons, rank band, held marker), grid + front edge + zone shading 7.2, spawn-box
  outline on `horn_soon`, enemy pad 7.6, P camera; UI Lab `ws_pad` en / fr no FAIL; perf gate 15.5.
- [ ] WS3.U2 (ui-coder): place / hover / drag ghosts, swap, box select, right-click sell, `No room` message, L / Ctrl+L,
  `Place on buy` setting, tooltips 7.5, mini-pad if kept; `test_ws_ui` pad rows PASS.
- [ ] WS4.D1 (this spec, 8): pips, Armoury strip, keys, tooltips, token ticks.
- [ ] WS4.U1 (ui-coder): pips 8.1 with the flash / cancel blink, Armoury strip 8.2 in both layouts, tooltip lines 8.3 from the
  templates, Shift / Shift+Ctrl / Shift+Alt + key and R / Y / O, token ticks; `test_ws_ui` upgrade rows PASS; UI Lab `ws_buy`
  en / fr no FAIL; strings through `Loc` and merged in `data/i18n/fr/`.
- [ ] WS2.D1 (this spec): 10-slot panel with groups / lock / states, card anatomy, Coffer + tier buttons, horn ring, field
  counter, enemy peek, tooltips, key table G / U / I.
- [ ] WS2.U1 (ui-coder): panel 994 x 224 at (590, 660) with the rects of 1-3; the 10 physical keys + Ctrl / Alt + G / U / I
  pressed in `test_ws_ui` (slot 10 empty on Fire refuses quietly); `KeyLabels` labels on every badge; the 1.2 states
  switch on affordable / locked / maxed / bought; UI Lab shot `ws_buy` for Fire and Ice (10 cards, lock on T3, held warning)
  with no FAIL in English and French; M1 top-right panel removed; every string through `Loc` and merged in `data/i18n/fr/`.

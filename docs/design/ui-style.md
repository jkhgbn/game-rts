# UI: visual style of the HUD (Step 5, task 5.D1)

Written 2026-09-25. Source of truth for the Step 6 ui-coder tasks **6.U1** (panels, theme, fonts, hero column,
end screen, tooltips), **6.U2** (command card, inventory, shop) and **6.U3** (minimap, fog, portrait), and for the
tech-artist who renders the icons. It restyles the HUD; it does **not** move anything: every position, size,
key, text format and public function in `ui-hud.md`, `levels.md` (HUD), `items.md` (HUD), `spells.md` (2.U2),
`buildings.md` (card) and `skirmish-1v1.md` (timer, end screen) stays as written and the existing tests keep passing.
Pixels at 1600 x 900, anchored as today (top panels to the top, bottom panels to the bottom). Colours are
`(r, g, b)` in 0-1 with hex; alpha given when it is not 1.

Direction: a polished hero-RTS look (StarCraft II / League of Legends feel, our own shapes): heavy metal frames
with bevels and gem studs, dark stone panels, one glowing trim line in the kingdom's colour, big readable
numbers, icons in framed slots with a radial cooldown sweep. The **player's kingdom skins the HUD**
(Fire = bronze and ember, Shadow = tarnished silver and violet); gameplay colours (gold keys, HP, mana, tiers,
team colours) never change with the skin.

---

## 1. Kingdom skin tokens
`UIStyle` gets `set_kingdom(kingdom: StringName)` (`&"fire"` default, `&"shadow"`), called from `GameHUD.setup`
with the player wizard's `faction`. Every framed texture and colour below is rebuilt from these tokens.
| Token | Fire | Shadow | Used for |
|---|---|---|---|
| `frame_metal` | `(0.62, 0.40, 0.16)` #9E6629 | `(0.55, 0.52, 0.66)` #8C85A8 | Frame body, tooltip border |
| `frame_light` | `(0.85, 0.62, 0.30)` #D99E4D | `(0.78, 0.76, 0.88)` #C7C2E0 | Bevel top/left, studs, hover rim |
| `frame_dark` | `(0.36, 0.22, 0.09)` #5C3817 | `(0.30, 0.28, 0.40)` #4D4766 | Bevel bottom/right, disabled rim, slate border |
| `groove` | `(0.04, 0.03, 0.03)` #0A0808 | `(0.03, 0.02, 0.05)` #08050D | 1 px dark line inside the rim |
| `trim_glow` | `(1.00, 0.55, 0.15)` #FF8C26 | `(0.70, 0.30, 1.00)` #B34DFF | The glowing trim line, hover halo, portrait bg, ready flash |
| `panel_bg` | `(0.10, 0.08, 0.09, 0.92)` #1A1417 | `(0.09, 0.07, 0.13, 0.92)` #171221 | Framed panels |
| `panel_inner` | `(0.14, 0.11, 0.11)` #241C1C | `(0.13, 0.11, 0.18)` #211C2E | Button / slot interiors, bar backgrounds |
| `slate_bg` | `(0.06, 0.05, 0.08, 0.72)` | `(0.05, 0.04, 0.09, 0.72)` | Secondary panels (objective, help, tooltips) |
| `title` | `(1.00, 0.80, 0.45)` #FFCC73 | `(0.85, 0.70, 1.00)` #D9B3FF | Names, panel titles, banner |
| `text` | `(0.94, 0.92, 0.88)` #F0EBE0 | `(0.92, 0.92, 0.96)` #EBEBF5 | Body text, numbers |
| `text_muted` | `(0.66, 0.60, 0.55)` #A8998C | `(0.60, 0.58, 0.70)` #9994B3 | Labels (`POP`, `Rally:`), help text, "Nothing selected" |
Ice (later): metal `(0.70, 0.78, 0.88)`, glow `(0.75, 0.92, 1.00)`, bg `(0.30, 0.38, 0.48)` darkened x0.35. Nature: metal `(0.40, 0.28, 0.16)`, glow `(0.75, 1.00, 0.40)`, bg `(0.22, 0.20, 0.14)`.

**Shared, never skinned** (existing constants, tests read them): `GOLD (1.0, 0.85, 0.4)` keys / pending order / XP /
selected tab, `WARN (0.95, 0.35, 0.3)`, `HP (0.8, 0.2, 0.2)`, `MANA (0.25, 0.45, 0.95)`, crystals `(0.45, 0.85, 1.0)`
text `(0.75, 0.92, 1.0)`, essence `(0.75, 0.45, 1.0)` text `(0.9, 0.8, 1.0)`, health strip green / yellow / red,
item tier colours (`items.md`), minimap colours (`ui-hud.md`, `fog-of-war.md`).

## 2. Fonts
| Role | Font | Sizes (unchanged) | Notes |
|---|---|---|---|
| Display: hero name, unit / building names, panel titles, level number, `VICTORY / DEFEAT`, shop title | **Cinzel** (SIL OFL 1.1, free to ship; Regular + Bold) in `assets/fonts/cinzel/` with its `OFL.txt` | 20 names, 16 badge, 18 shop item, 64 banner | Uppercase-looking serif capitals; use **Bold** for the banner and the badge |
| Body: numbers, stats, tooltips, help, messages, bar text | **Godot's default (Noto Sans)**, nothing to ship | 22 message, 20 numbers, 17 objective, 16, 14, 13, 12, 11, 10 as today | Numbers use a `FontVariation` with `variation_embolden 0.5` (crystals, pop, timer, essence, bar text) |
- Outlines: **no outline inside framed panels** (the bg is opaque enough); outline 3 px `(0, 0, 0)` on text over
  the 3D world (message line, objective, help, floating texts) and on text over a bar fill (HP / mana / XP text,
  stack counts, key digits). `UIStyle.label(text, size)` keeps the outline; add `UIStyle.panel_label(text, size)` = no outline.
- If the user refuses an external font file: display = default font, `variation_embolden 0.8`, `spacing_glyph 1`, text uppercased.

## 3. Panel frames (drawn in code, no PNG in the repo)
### 3.1 The heavy frame (`UIStyle.frame_style()` -> `StyleBoxTexture`)
A **48 x 48 `Image`** generated at start (`Image.create`, `fill_rect`, `set_pixel`), `ImageTexture`, `StyleBoxTexture`
with texture margins **16** on every side, `draw_center true`. Rings from the outside in (px index from the edge):
| px | Colour | Meaning |
|---|---|---|
| 0 | `(0, 0, 0, 0.55)` | Soft edge |
| 1 | top + left rows `frame_light`, bottom + right rows `frame_dark` | Bevel |
| 2-3 | `frame_metal` | Rim body |
| 4 | `groove` | Groove |
| 5 | `trim_glow` at alpha 0.55 over `panel_bg` | The glowing trim line |
| 6 | `panel_bg` mixed 50 % with `groove` | Inner shadow |
| 7+ | `panel_bg` | Panel |
- **Corner stud** in each corner: a pixel diamond of radius 4 centred at (5, 5) (and mirrored), `frame_light`, its
  two bottom-right diagonal pixels `frame_dark`, centre pixel `trim_glow` (a lit gem). Drawn after the rings.
- Drop shadow: the panel also gets a `StyleBoxFlat` behind it (a `Panel` child at z -1, same rect grown by 6 px)
  with `shadow_size 8`, `shadow_color (0, 0, 0, 0.45)`, `shadow_offset (0, 3)`, bg transparent.
- Content margin stays **10** (24 for the end screen), so nothing inside moves.
- Used by: top bar (see 4.1, chamfered variant), minimap, selection panel, command card, shop window, end screen.

### 3.2 The slate (`UIStyle.slate_style()` -> `StyleBoxFlat`)
Bg `slate_bg`, border 1 px `frame_dark`, radius 2, margin 10 (8 for tooltips). Used by: objective, controls help,
tooltips (border `frame_metal`), status chips, drag ghosts. Quiet: it must not compete with the framed panels.

### 3.3 Button / slot frame (`UIStyle.button_frame(state)` -> `StyleBoxTexture`, one 24 x 24 image per state)
Texture margins 8. Rings: px 0 `(0, 0, 0, 0.8)`; px 1 bevel (light top/left, dark bottom/right); px 2 rim; px 3 `groove`;
inside `panel_inner`. The rim colour per state:
| State | Rim (px 1-2) | Inside | Extra |
|---|---|---|---|
| normal | `frame_metal` | `panel_inner` | |
| hover | `frame_light` | `panel_inner` lightened 0.12 | 1 px halo outside the frame in `trim_glow` alpha 0.6 (`draw_rect` unfilled, 65 x 65) |
| pressed | `frame_dark` | `panel_inner` darkened 0.25 | Icon offset (+1, +1) px |
| disabled | `frame_dark` | `panel_inner` | Keep `modulate.a 0.45` on the button (tests read it); icon `self_modulate (0.55, 0.55, 0.55)` |
| selected / pending / hold active | `GOLD` | `panel_inner` | Hotkey badge filled gold with black letter; rim pulses alpha 0.7-1.0 at 2 Hz while a target is pending |
| focus | none (`StyleBoxEmpty`, as today) | | |
Transitions are instant (Godot swaps styleboxes); only the halo fades in 0.08 s (`modulate` tween on a child `Control`).

## 4. Panels, one by one (positions unchanged)
| Panel | Rect at 1600 x 900 | Style |
|---|---|---|
| Objective | (16, 16), auto | Slate; text font 17 `title` colour, outline 3 |
| Top bar | **500 x 40 at (550, 8)** (400 without essence, 320 without timer, as today) | Chamfered frame, 4.1 |
| Controls help | right edge -16, y 16 | Slate; font 13 `text_muted`, `modulate.a 0.8` kept |
| Message line | centre, y 120 | Font 22 gold, outline 3, fades out over its last 0.3 s |
| Control group bar | tabs 64 x 36 from x 272, y 620-656, gap 4 | 4.2 |
| Minimap | 240 x 240 at (16, 644); draw area 220 x 220 at (26, 654) | Heavy frame; section 7 |
| Selection panel | 1002 x 224 at (272, 660) | Heavy frame; hero column 300 + divider + area 680; section 5 |
| Command card | 294 x 224 at (1290, 660); grid 4 x 3 of 64 at (1300, 670), gap 6 | Heavy frame; section 6 |
| Shop window | 640 x 440 at (480, 200) | Heavy frame; 6.4 |
| End screen | centred, margin 24 | Heavy frame over a full-screen `ColorRect (0, 0, 0, 0.45)`; 4.3 |

### 4.1 Top bar
- The `PanelContainer` uses `StyleBoxEmpty`; a `_draw` behind the row draws a **chamfered slab**: the 500 x 40 rect
  with its left and right ends cut at 45° by 12 px (hexagon), fill `panel_bg`, outline 2 px `frame_metal` with the
  top edge in `frame_light`, plus a 1 px `trim_glow` (alpha 0.55) line 3 px under the top edge running the full width.
- Between items (the 48 px gaps): a 1 px vertical `frame_dark` line 20 px tall, centred in the gap.
- Icons two-tone: crystal diamond 16 px = `(0.45, 0.85, 1.0)` with its top-left half `(0.75, 0.95, 1.0)`; essence
  flame = `(0.75, 0.45, 1.0)` with a `(0.95, 0.80, 1.0)` inner tongue (6 px); pop = a 16 x 16 shield polygon in
  `text_muted` (`POP` text allowed to stay if the polygon is skipped); timer = a 12 px hourglass polygon in `text_muted` before the digits.
- Numbers: font 20 embolden 0.5 in their colours; pop `WARN` at cap (unchanged); a failed spend keeps the 0.4 s red
  flash and adds a horizontal **shake** of the number: ±4 px, 3 cycles, 0.3 s.

### 4.2 Control group tabs
Button frame (3.3) with the two **top corners chamfered 6 px** (a `_draw` polygon over the frame's corners in the
panel's outside colour), the tabs visually "plug into" the selection panel below. Key digit in a 12 x 12 badge
top-left (bg `(0, 0, 0, 0.75)`, gold font 11); count + abbreviation font 14 `text` (later: the 24 x 24 icon of the most
common unit at (36, 6) instead of the abbreviation). Active tab: `GOLD` rim + a 2 px gold line along the tab's bottom edge.

### 4.3 End screen
Dim layer fades in over 0.3 s. Panel frame margin 24, min width 560. Banner font 64 Cinzel Bold in the caller's
colour (victory gold, defeat `(0.85, 0.30, 0.30)`), scale 1.2 -> 1.0 in 0.25 s (`Tween`, pivot centre), outline 0,
a `trim_glow` glow behind it (a second Label at alpha 0.35, scale 1.03). A 1 px `groove` + 1 px `frame_light` rule
(2 lines, 400 px wide, centred) between the banner and the stats. Stats font 20 `text`; the last line `F9: play again`
font 20 `text_muted`. Text formats unchanged (`skirmish-1v1.md`).

## 5. Selection panel
### 5.1 Divider and column backgrounds
- Hero column x 282-572 (300 incl. its margin), a **divider** at x 582-584: 2 px `groove` + 1 px `frame_light` on its
  right, with a 6 x 6 `frame_light` diamond at each end (y 672 and y 872).
- Hero column background: a vertical gradient `ColorRect` (`GradientTexture2D`, 1 x 64 px stretched) from `trim_glow`
  alpha 0.10 at the top to alpha 0 at 60 % height (a faint aura behind the hero).
- Selection area: plain `panel_bg`. "Nothing selected": font 16 `text_muted` centred; behind it the kingdom emblem
  at alpha 0.06, 120 x 120 centred: Fire = three flame tongues inside a ring; Shadow = a crescent over a thin spire
  (both `draw_colored_polygon`, our own shapes).

### 5.2 Hero column (same rects as `levels.md` / `items.md`)
| Element | Rect | New look |
|---|---|---|
| Level badge | 28 x 28 at (282, 670) | **Hexagonal medallion** (`draw_colored_polygon`, flat top): fill `(0.15, 0.12, 0.05)`, 2 px `GOLD` edge, 1 px `frame_light` inner facet on the upper half; number font 16 Cinzel Bold gold. Dead: gold -> `(0.45, 0.42, 0.35)` |
| Name (button) | font 20 at (318, 670) | Cinzel `title` colour; hover: `trim_glow` underline 2 px; pressed: `frame_light`. Dead: `text_muted` |
| Crown mark | right of the name | A 16 x 12 gold crown polygon (3 points) replaces plain text if a label is kept, tooltip `Wears the Ember Crown: +100 HP, +50 mana` |
| HP bar | 280 x 22 at (282, 706) | Bar style 5.3, fill `HP` |
| Mana bar | 280 x 22 at (282, 734) | Bar style 5.3, fill `MANA` |
| XP bar | 280 x 16 at (282, 762) | Bar style 5.3 with 4 px less height, fill gold on `(0.2, 0.17, 0.1)` (unchanged) |
| Status chips | 40 x 20 from (282, 784), gap 4 | Slate, 1 px border in the status colour (haste `(1.0, 0.6, 0.2)`, shroud `(0.7, 0.3, 1.0)`), letter font 12 in that colour + seconds font 12 `text` |
| Points chip | 70 x 20 at (492, 784) | Unchanged (gold, pulse 0.7-1.0 every 0.8 s), corners radius 3 |
| Return timer | font 13 at (318, 700) while dead | `WARN`, text `Vessa returns in 24 s` (unchanged); whole column `modulate (0.65, 0.65, 0.65)` while dead |
| Inventory | 36 x 36 at (282 + 40 i, 834); artifacts (526, 834), (526, 794) | Section 6.3 |

### 5.3 Bars (`UIStyle.bar`, same heights and text)
- Background: `StyleBoxFlat` `panel_inner`, border 1 px `groove`, radius 2, plus a 1 px `(0, 0, 0, 0.35)` inner top line.
- Fill: `StyleBoxTexture` from a **4 x 22 `GradientTexture2D`** (vertical): top 40 % = fill colour lightened 0.25,
  bottom = fill colour darkened 0.15; `axis_stretch_horizontal STRETCH`; radius 2 via the texture's transparent corner pixels.
- Ticks: 1 px `(0, 0, 0, 0.35)` at 25 / 50 / 75 % of the width, over the fill.
- Text: font 13 embolden 0.5, `text`, outline 3 (unchanged strings `HP  350 / 350`, `Mana  100 / 100`, `XP  320 / 450`).
- **Ghost damage**: a second fill behind the real one in `(1.0, 0.85, 0.8, 0.8)` that keeps the old value and
  tweens down to the new value over 0.5 s (`ease out`) whenever HP drops; on heal the fill flashes `(0.5, 1.0, 0.5)` for 0.15 s.
- **Low HP** (< 30 %): the fill lerps between `HP` and `(1.0, 0.45, 0.40)` on a 1.5 Hz sine; the hero column's trim line
  (3.1 px 5, redrawn as a `ColorRect` 1 px tall along the column top) turns `WARN` and pulses alpha 0.4-0.9; the
  portrait (7.2) gets a red vignette alpha 0.35. Stops the moment HP >= 30 %.
- **Shield** segment (items.md): white `(1, 1, 1, 0.85)` segment appended after the HP fill, capped at the bar's end.

### 5.4 Selection area views (the only layout addition: the portrait)
| View | Layout (x from 588, inside the area) |
|---|---|
| 1 unit | **Portrait 96 x 96 at (588, 670)** (7.2); name font 20 Cinzel `title` at (696, 670) (+ ` · Veteran` etc. in `text`, gold chevrons `^` font 14 after it); HP bar 280 x 22 at (696, 700); wizard: mana bar 280 x 22 at (696, 728) and the stat line at (696, 758); others: stat line font 14 `text_muted` with the numbers in `text` at (696, 730). Stat-line strings unchanged |
| 2+ units | No portrait. Header line font 14 at (588, 674); grid of 48 x 48 icons at (588, 700), 4 px gap, 12 per row, 2 rows. Icon = slot frame 3.3 + 40 x 40 unit icon (6.1) or the abbreviation; 4 px HP strip inside the frame bottom; 1-3 gold 3 x 3 dots top-right (unchanged); hover: `frame_light` rim; click = select that unit |
| Keep / building | Portrait 96 x 96 at (588, 670) of the building; name at (696, 670); HP bar 280 x 22 at (696, 700); training queue: 5 slots 48 x 48 at (696, 734), gap 6, slot frames, 48 x 6 gold progress under slot 1 (unchanged), a `x` mark font 10 `WARN` top-right of a slot on hover (click cancels, unchanged); `Rally: set / gather node` font 13 `text_muted` at (696, 792) |
| Construction site | Portrait; name; progress bar 280 x 14 gold at (696, 700); `Cancel  [Delete]` button 150 x 32 at (696, 724): button frame with `WARN` rim, text font 14 |

## 6. Icons, command card, inventory, shop
### 6.1 Icon assets (tech-artist, Step 6; the UI falls back to the 2-letter abbreviation until a file exists)
- Path `res://art/icons/<kind>/<id>.png`, `kind` = `units`, `buildings`, `spells`, `items`; **128 x 128**, transparent
  background, rendered from the 3D model with the painted shader: camera pitch -20°, yaw 30° (3/4 front), head and
  shoulders filling ~80 % of the height for units; whole building for buildings; the spell's VFX frozen at its best
  frame over a radial gradient `trim_glow` alpha 0.5 -> `panel_inner` for spells; the item's ground-cube model for items.
- No border baked into the PNG: the UI draws the frame. Team colour parts rendered in the **Fire** team colour for
  Fire units and Shadow for Shadow units (the icons are per faction anyway).
- Displayed sizes: 56 x 56 in the command card (inset 4 in the 64 slot), 40 x 40 in multi-select and queue slots
  (inset 4 in 48), 40 x 40 in the shop grid, 32 x 32 in the inventory (inset 2 in 36), 28 / 20 in the recipe tree.
  `texture_filter LINEAR_WITH_MIPMAPS`.

### 6.2 Command card buttons (64 x 64, grid unchanged)
| Part | Rect in the button | Look |
|---|---|---|
| Frame | 0-64 | Button frame 3.3 per state |
| Icon | (4, 4) 56 x 56 | Icon or abbreviation font 18 `text` (unchanged) |
| Hotkey badge | 18 x 14 at (44, 48) | Bg `(0, 0, 0, 0.75)`, 1 px `frame_dark` border, radius 2, letter font 12 `GOLD` centred (the letters and positions the tests read stay: the label is simply drawn on a badge) |
| Rank pips | 6 x 6 at (4 + 8 j, 54) | Drawn as **diamonds** (rotated squares), gold filled / `(0.3, 0.3, 0.3)` empty, 1 px `groove` edge; same rects |
| `+` learn chip | 16 x 16 at (2, 2) | Unchanged gold chip, radius 3, `+` font 14 black; pulses with the points chip |
| Cost tag (train / build buttons) | 26 x 12 at (4, 48) | Bg `(0, 0, 0, 0.75)`, crystal number font 10 in the crystal text colour; `WARN` when unaffordable |
- **Cooldown sweep** (replaces the bottom-up drain): a dark **radial fan** `(0, 0, 0, 0.65)` drawn with
  `draw_colored_polygon` (36 segments) from 12 o'clock **clockwise**, covering the still-remaining fraction
  (`cooldown_left / cooldown_total`); the cleared part opens clockwise as it recharges; a 1 px `trim_glow` edge on the
  sweep's leading radius; remaining seconds (rounded up) font 18 `text` outline 3 centred (unchanged numbers).
  **Ready flash**: when `cooldown_left` reaches 0, the rim flashes `trim_glow` -> normal over 0.25 s and the icon
  scales 1.0 -> 1.08 -> 1.0 in 0.2 s. `Not enough mana`: disabled state (unchanged), the mana line in the tooltip turns `WARN`.
- Targeted order pending: the selected state (gold rim, pulsing) on that button until confirmed or cancelled.
- Build-menu page (after B): the 4th slot `Back` shows a `<` glyph font 18 and the Esc badge text `Esc` font 10.

### 6.3 Inventory bar (36 x 36 slots, positions unchanged)
| Part | Look |
|---|---|
| Slot frame | Button frame 3.3 at 36 px (margins 8 fit) with the rim colour = **tier colour** (`items.md`): component `(0.85, 0.85, 0.85)`, mid `(0.30, 0.75, 1.00)`, top `(1.00, 0.60, 0.20)`, consumable `(0.40, 0.90, 0.40)`, artifact `(1.00, 0.85, 0.30)`; empty `(0.3, 0.3, 0.3)` rim, inside `panel_inner` darkened 0.2 |
| Top / artifact glow | 2 px outer halo in the tier colour alpha 0.35 (`draw_rect` unfilled, 40 x 40 around the slot) |
| Icon | 32 x 32 at (2, 2) or abbreviation font 14 (unchanged) |
| Key digit | Font 10 gold bottom-right on a 10 x 10 `(0, 0, 0, 0.75)` badge (passive-only items: none, unchanged) |
| Stack count | Font 10 `text` outline 3 bottom-left (unchanged) |
| Cooldown | Same radial sweep as 6.2, seconds font 12 |
| Hover | `frame_light` rim + halo; the item tooltip (8) 6 px above the slot (unchanged anchor) |
| Drag | The dragged icon at alpha 0.7 follows the cursor; the source slot shows an empty rim; a valid drop target gets the gold rim; the sell zone (shop) `WARN` rim |
| Artifact slots | Rim `(1.00, 0.85, 0.30)` even when empty (alpha 0.6), a 10 x 8 gold crown glyph at alpha 0.35 inside when empty |

### 6.4 Shop window (640 x 440 at (480, 200))
- Heavy frame; a **title bar** 28 px: `Keep shop` / `Ruin Peddler` font 20 Cinzel `title` left, essence flame + number
  right (font 16), a 1 px `frame_light` rule under it; **X** 24 x 24 = a stud-like round button (`frame_metal` fill, `frame_light` ring, `x` font 13 `text`), hover `WARN` ring.
- Left 380 px: row labels `Components / Mid / Top / Consumables` font 12 Cinzel `text_muted` with a 1 px `frame_dark`
  rule after the label; 48 x 48 slot frames rimmed in the tier colour, icon 40 x 40, total cost font 10 under it
  (essence colour, green `(0.4, 0.95, 0.4)` when owned parts lower it, unchanged); unaffordable alpha 0.45; not sold here alpha 0.3 (unchanged).
- Right 220 px: name font 18 Cinzel `title`, stat lines font 13 `text` (numbers) / `text_muted` (words), passive /
  active text font 13; recipe tree with slot frames (48 / 36 / 28), connector lines 1.5 px `frame_light` alpha 0.7,
  owned parts green rim, missing parts show their cost (unchanged).
- **Buy / Combine** 220 x 36: "primary" button = button frame with `trim_glow` rim and inside `trim_glow` alpha 0.18
  over `panel_inner`, text font 16 Cinzel `text`; disabled = 3.3 disabled + reason line font 12 `WARN` above it.
- **Sell** zone 220 x 28: dashed 1 px `WARN` alpha 0.6 border (draw 6 px dashes), text `Drop an item here to sell` font 12 `text_muted`; while dragging an item over it: solid `WARN` border, bg `WARN` alpha 0.15.

## 7. Minimap, fog, portrait (6.U3)
### 7.1 Minimap (240 x 240 at (16, 644), draw area 220 x 220 at (26, 654))
- Heavy frame with its 4 corner studs; inside, a 1 px `groove` line around the draw area and a 1 px `frame_dark`
  line outside it (a sunken map).
- Layers (colours from `ui-hud.md` / `fog-of-war.md`, unchanged): ground; **fog texture** 60 x 60 scaled to 220
  (`texture_filter NEAREST` so cells stay crisp; unexplored black, explored ground x0.45, visible full); obstacles;
  ghosts of explored enemy buildings `(0.55, 0.55, 0.6)`; icons; camera quad 1 px `(1, 1, 1, 0.8)`.
- Own wizard diamond gets a 1 px `groove` outline so it reads over the gold artifact; enemy wizard the same.
- A **ping** on the minimap when a message contains `under attack` (optional): 3 expanding `WARN` rings 0.9 s.
- Hover over the draw area: the cursor becomes the cross (targeted order) or stays default; no other change.

### 7.2 Portrait (one `SubViewport` for the whole HUD, shown in the single-unit and building views)
| Item | Value |
|---|---|
| Viewport | `SubViewport` 128 x 128, `transparent_bg true`, own `World3D`, `msaa_3d 2x`, shown in a 96 x 96 `TextureRect` (`LINEAR_WITH_MIPMAPS`) inside a button frame (3.3, normal rim) at (588, 670) |
| Background | Radial gradient `GradientTexture2D` 96 x 96: `trim_glow` alpha 0.35 at the centre -> `panel_inner` at the edge (behind the viewport texture) |
| Camera | `Camera3D` FOV 30°, at `(0, 0.85 h, 2.3 h)` looking at `(0, 0.65 h, 0)` for a unit of height `h` (from `UnitType` / the model's AABB); buildings: `(0.9 s, 0.9 s, 1.6 s)` looking at `(0, 0.35 s, 0)` for footprint size `s`; units face the camera (yaw 20°) |
| Light | One `DirectionalLight3D` yaw -35°, pitch -40°, colour `(1.0, 0.93, 0.82)` energy 1.2, no shadows; `Environment` ambient `(0.45, 0.52, 0.70)` energy 0.5, no glow |
| Content | An instance of the selected thing's `model_scene` (same painted shader, its team colour), idle animation if it has one; a `Label` with the 2-letter abbreviation font 28 `title` while `model_scene` is null |
| Update | `render_target_update_mode UPDATE_ONCE` triggered every 1/30 s while visible, `UPDATE_DISABLED` when the view is hidden or nothing is selected; the model is swapped only when the selection's type changes |
| States | Dead / destroyed: `TextureRect.modulate (0.5, 0.5, 0.5)`; low HP (< 30 %): a red radial vignette overlay alpha 0.35; enemy: rim `(0.85, 0.30, 0.30)`; neutral: rim `frame_dark` |
- Wizards show the same portrait when selected (the hero column keeps no portrait, so nothing there moves).

## 8. Tooltips
- Keep every `tooltip_text` string exactly (tests read them). Each button returns a **custom tooltip**
  (`_make_custom_tooltip`) built from those lines: slate style with a 1 px `frame_metal` border, margin 8, max width
  320, appears after 0.25 s, positioned 8 px above the control (clamped on screen, as `ItemTooltip` does).
| Line | Look |
|---|---|
| 1: `Name  [X]` (+ `Rank 2 / 3`) | Name font 15 Cinzel `title`; the key in an inline 18 x 14 gold badge (black letter); `Rank n / m` font 12 `text_muted` right-aligned; `Not learned` in `WARN` |
| 2: numbers | Font 13 `text`; mana / crystal / essence numbers in their currency colours |
| 3: description | Font 13 `text_muted` |
| 4: reason (`Not enough crystals`, `Population cap reached`, `No shop nearby`, `Needs Warden Scale (...)`) or `Ctrl+F: rank 3 = ...` | Reason in `WARN`; the learn hint in gold |
| Item tooltips (`ItemTooltip`) | Same panel; line 1 name in the **tier colour**, `Sell 325` font 12 `text_muted`, `Active:` line `trim_glow` |

## 9. Animations (all `Tween`s or `_process` sines; none longer than 0.5 s except pulses)
| Event | Animation |
|---|---|
| Level-up (wizard) | Badge scale 1.0 -> 1.4 -> 1.0 in 0.4 s (unchanged) + a gold ring (`draw_arc`, width 3) behind the badge growing from radius 14 to 40 px while fading over 0.5 s; XP bar white flash 0.2 s (unchanged); the hero column's trim line flashes gold 0.3 s |
| Learn a spell | Badge flash (unchanged); the button's rim flashes gold 0.3 s and the new pip pops scale 1.0 -> 1.6 -> 1.0 in 0.2 s |
| Damage taken (hero) | Ghost-damage segment drains in 0.5 s (5.3); the HP text does not shake |
| Low HP | 1.5 Hz fill pulse, trim line pulse, portrait vignette (5.3, 7.2) |
| Heal | Fill flash `(0.5, 1.0, 0.5)` 0.15 s |
| Cooldown ready | Rim flash 0.25 s + icon pop 0.2 s (6.2) |
| Failed spend | Number red 0.4 s (unchanged) + ±4 px shake 0.3 s (4.1) |
| Points available | Points chip and `+` chips pulse 0.7-1.0 alpha every 0.8 s (unchanged) |
| Selection change | The new view fades in over 0.1 s (`modulate.a` 0 -> 1); no slide |
| Hover | Halo fades in 0.08 s (3.3) |
| End screen | Dim 0.3 s, banner scale 1.2 -> 1.0 in 0.25 s (4.3) |
| Message line | Instant in, fade out over its last 0.3 s |
Everything pauses with the tree (`process_mode INHERIT`); nothing uses physics frames.

## 10. Sizes at 1600 x 900 (summary, all unchanged unless marked new)
| Thing | Size / position |
|---|---|
| Heavy frame image | 48 x 48, margins 16; button frame image 24 x 24, margins 8 |
| Top bar | 500 x 40 at (550, 8), chamfer 12 px |
| Group tabs | 64 x 36, y 620-656, from x 272, gap 4 |
| Selection panel / hero column / area | 1002 x 224 at (272, 660) / 300 px / 680 px; divider x 582-584 (new) |
| Level badge / name / bars | 28 x 28 at (282, 670) / x 318 / 280 x 22 at y 706 and 734, 280 x 16 at y 762 |
| Status chips / points chip | 40 x 20 from (282, 784) / 70 x 20 at (492, 784) |
| Inventory | 36 x 36 at (282 + 40 i, 834); artifacts (526, 834), (526, 794) |
| Portrait (new) | 96 x 96 at (588, 670), viewport 128 x 128 |
| Single-unit texts / bars | x 696: name y 670, HP y 700, mana y 728, stats y 758 (wizard) / y 730 (others) |
| Multi-select grid | 48 x 48 at (588, 700), gap 4, 12 x 2; header y 674 |
| Queue slots | 48 x 48 at (696, 734), gap 6, progress 48 x 6 |
| Command card | 294 x 224 at (1290, 660); buttons 64 at (1300 + 70 c, 670 + 70 r); icon 56; badge 18 x 14 at (44, 48); pips 6 at (4 + 8 j, 54); chip 16 at (2, 2) |
| Minimap | 240 x 240 at (16, 644); draw 220 x 220 at (26, 654) |
| Shop | 640 x 440 at (480, 200); grid 380 px, details 220 px; buttons 48; Buy 220 x 36; Sell 220 x 28 |
| Tooltip | max width 320, margin 8, 8 px above the control |
| End screen | centred, margin 24, min width 560 |

## What changed in other specs
- `ui-hud.md`: styles only. Panel bg alpha 0.78 -> 0.92 through the frame texture; `_panel` keeps its margin 10.
  The single-unit and building views gain the 96 x 96 portrait at x 588 and their texts start at x 696.
- `spells.md` 2.U2: the cooldown overlay becomes a clockwise radial sweep (same numbers, same seconds text).
- `levels.md` / `items.md` HUD rows: positions unchanged; looks as above.
- New folder `assets/fonts/cinzel/` (ui-coder owns `assets/`); new `art/icons/` (tech-artist).

## Done when
- [ ] 6.U1 (panels): `UIStyle.set_kingdom(&"fire" / &"shadow")` rebuilds the tokens of section 1; the 48 x 48 frame
  image and the 24 x 24 button images are generated in code (no PNG); every framed panel (top bar chamfered, minimap,
  selection panel, command card, shop, end screen) uses the heavy frame and objective / help / tooltips the slate;
  Cinzel (with `OFL.txt`) for names, titles, badge and banner, default font elsewhere, no outline inside panels;
  top bar separators, two-tone icons, failed-spend shake; group tabs chamfered with the gold active line; hero column
  medallion, divider, aura gradient, bars with gradient fill, ticks, ghost damage, heal flash, low-HP pulse, level-up
  ring; end screen dim + banner scale; custom tooltips render the 3-4 lines of section 8 from unchanged `tooltip_text`;
  a test `tests/test_6.U1.gd` checks the rects of section 10 at 1600 x 900 for both kingdoms and every existing UI test still passes.
- [ ] 6.U2 (command card + inventory + shop): 5 button states of 3.3 (hover halo, pressed offset, disabled keeps
  `modulate.a 0.45`, selected gold pulse); icons loaded from `res://art/icons/<kind>/<id>.png` at 56 / 40 / 32 px
  with the abbreviation fallback; hotkey badge, cost tag, diamond pips, `+` chip; the radial cooldown sweep with
  seconds and the ready flash on spells and items; inventory tier rims, top / artifact halo, empty artifact crown,
  drag ghost and drop highlights; shop title bar, stud X, tier rows, primary Buy button, dashed Sell zone; the slot
  tables of `ui-hud.md` / `buildings.md` / `spells.md` and every tooltip string unchanged.
- [ ] 6.U3 (minimap + fog + portrait): sunken minimap with studs; fog texture at `NEAREST` under the icons with the
  unexplored / explored / visible rules of `fog-of-war.md` and enemy building ghosts; wizard diamonds outlined; one
  `SubViewport` portrait 128 -> 96 px at (588, 670) with the camera, light and background of 7.2, model swapped on type
  change, updated at 30 Hz only while visible, abbreviation fallback, dead / low-HP / enemy states; `PERF OK` with the portrait on screen.

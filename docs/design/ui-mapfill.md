# UI: river, capturable points, camps, epic beasts and game critters (step 12, task 12.D2)

Written 2026-09-26. Source of truth for **12.C6** (minimap layers, point / critter clicks, the critter right-click and
cursor, capture rings and camp markers in the world) and **12.C7** (objectives strip, blessing chips, point panel, critter
card, camp lines, beast boss bar and inspect card, blessing / wading chips, floating `+5` / `+40` / `+1`, messages, hint,
Map detail setting, help text, end-screen lines, sounds). It lays out every element of `map-fill.md` section 8 with the
skin of `ui-style.md` (tokens, fonts, frames, bars, tooltips) and moves **nothing** that `ui-hud.md`, `ui-style.md`,
`ui-champions.md` or `ui-trade.md` already place, except the controls help (one more line, section 12). Gameplay numbers,
strings and contracts come from `map-fill.md` (sections 3.4, 4, 5, 8, 13) and the frozen contract in `CLAUDE.md`
("Map fill"); when this file repeats one it is only so a coder does not have to look it up. If they ever disagree,
`map-fill.md` wins for gameplay, this file for pixels.

Conventions: as `ui-trade.md`. Pixels from the top-left at **1600 x 900** (virtual pixels, `ui-champions.md` section 2:
the whole HUD scales with `GameSettings.ui_scale`, no per-element rules); `(x, y)` = top-left corner, `w x h`; colours
are the `UIStyle` tokens (`title`, `text`, `text_muted`, `frame_metal`, `frame_light`, `frame_dark`, `groove`,
`trim_glow`, `panel_bg`, `panel_inner`, `slate_bg`), the shared constants `GOLD (1.0, 0.85, 0.4)`,
`WARN (0.95, 0.35, 0.3)`, `HP`, `ESSENCE` / `ESSENCE_TEXT`, `DEFEAT`, the trade ones `NEAR (0.4, 0.9, 0.4)` /
`FAR (1.0, 0.55, 0.2)`, plus the new ones of section 15.1 (`OWN`, `ENEMY`, `POINT_NEUTRAL`, `BEAST`, tier colours...).
"Cinzel n" = `UIStyle.display_label` at size n; "font n" = the body font at n; "number font" = `UIStyle.number_label`;
"slot frame" = `UIStyle.button_frame` (3.3); "heavy frame" = `UIStyle.frame_style`; "slate" = `UIStyle.slate_style`;
"bar" = `UIStyle.bar` (5.3); "chip" = the bounty / route cursor chip style (`ui-champions.md` 6.2). Controls are built
in code like the rest of `scripts/ui/` (no `.tscn`). Text widths marked "est." are estimates at the project fonts
(about 0.55 em per character); the coder checks them with `Font.get_string_size` in the 12.C7 test.

Step-12 classes are reached **untyped** (step-12 agent rule): `CapturePoints.instance(tree)` is fine to call through
`load()` guarded by `ResourceLoader.exists`, else groups `"capture_points_service"`, `"capture_points"`, `"camp_manager"`,
`"neutral_camps"`, `"epic_beasts"`, `"beasts"`, `"critter_herds"`, `"game_critters"`, `"river"`; then `get()`,
`has_method()`, `has_signal()`. When a part is missing (missions, `--no-mapfill`, a flag off) its UI is simply absent
and never errors.

---

## 1. Where everything goes

### 1.1 Screen map (existing panels unchanged unless marked; new ones in bold)
| Panel | Rect at 1600 x 900 | Anchor | Owner |
|---|---|---|---|
| Objective (skirmish) / mission objectives | (16, 16), auto (skirmish: 511 x 70) | top-left | existing |
| Top bar | 624 x 40 at (488, 8) with gold (500 x 40 at (550, 8) without) | top-centre | existing |
| **Objectives strip** | **300 x 50 at (650, 52)** with 8 points (width follows the point count, centred on x 800) | top-centre | 12.C7 (section 2) |
| **Blessing chips** | **144 x 22 at (958, 54)** and **(958, 78)**, only while a blessing runs | top-centre | 12.C7 (section 2.6) |
| Controls help | right edge x 1584, y 16; **458 x 248** with the 12th line (section 12) | top-right | existing (`hud.gd`) |
| Message line | centred, y 120 (pushed under the help panel for texts wider than about 636 px) | top-centre | existing |
| **Beast boss bar** | **456 x 50 at (572, 156)**; a second one at (572, 212) | top-centre | 12.C7 (section 6.1) |
| Champion bar | 240 x 228 at (16, 408) | bottom-left | step 9 |
| Control group tabs | 64 x 36 from x 272, y 620-656 | bottom | existing |
| Minimap | 240 x 240 at (16, 644); draw area 220 x 220 at (26, 654) | bottom-left | existing (12.C6 adds layers, section 9) |
| Selection panel | 1002 x 224 at (272, 660); area x 588-1264, y 670-874 | bottom | existing (12.C7 adds camp lines, the beast block, the new chips) |
| **Point panel / critter card** | **676 x 204 at (588, 670)**, over the selection area like the post panel | bottom | 12.C7 (sections 4, 7) |
| Command card | 294 x 224 at (1290, 660) | bottom-right | existing (text blocks of 6.3 / 7.3) |
| **Camp hover chip** | mouse + (18, 12), height 26 | none | 12.C7 (section 5.2) |
| **World**: capture rings, camp respawn timers, floating `+5` / `+40` / `+1` | 3D | world | 12.C6 (rings, timers) / 12.C7 (floats) |

### 1.2 Free space measured from the code (why things go where they go)
- **Under the top bar**: the top bar ends at y 48; the message line starts at y 120 (font 22, about 30 px tall). The band
  y 52-112 between x 535 (8 px right of the skirmish objective slate, which ends at x 527 and y 86) and x 1118 (8 px left
  of the help panel at x 1126) is empty. The strip (x 650-950, y 52-102) and the blessing chips (x 958-1102, y 54-100)
  fit there with >= 18 px to the message line and >= 24 px to the help panel. Mission objective panels grow downward
  from (16, 16) and stay left of x 600, so they never meet the strip.
- **Boss bar**: the band y 156-270 (under the message line) is free between x 535 and x 1118; the help panel (x >= 1126,
  to y 264) and a pushed message (y = help bottom + 10 = 274) stay clear of the bars (x 572-1028, y 156-262).
- **Selection area** x 588-1264, y 670-874: the point panel and the critter card paint over it exactly like the post
  panel and the flag card; the camp lines and the beast block live inside the existing single view (the x 1000-1264
  block is free there: the Bazaar block only shows for a Bazaar).
- **Left column**: nothing new; the champion bar and the minimap are untouched.

### 1.3 Full screen (1 character = 16 x 20 px; rows are 20 px)
```
     0         1         2         3         4         5         6         7         8         9
     0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
  0                              <1 250   POP 12 / 20   7:42   ~ 140   (o) 2 140>
  1   +-objective---------+                                                  +-controls help (12 lines)---+
  2   | Skirmish: Crown H.|                    +-strip--------------+ [<> Blessing 38 s ] | Left click / drag ...  |
  3   | Destroy every ... |                    |[T][T][T][T]|[W][W]|[S][S]| [<> Enemy blessing] | ...
  4   +-------------------+                    |            1:12   0:42  |                   | ...
  5                                            +--------------------+                     | ...
  6                     The West Wayshrine awakens     (message line, y 120)              | ...
  7                                   +-(paw) OLD SCARBACK · Epic beast · alpha -----+     | ...
  8                                   | [=========== 1 620 / 2 160 ===========      ]|     | ...
  9                                   +-----------------------------------------------+     | ...
 10                                                                                         | Capture: stand near ... |
 11                                                                                         +---------------------------+
 ..                  (3D battlefield: capture rings on the ground, "1:20" over a cleared camp, "+5" over a deer)
 31   +-champion 3-------+ [1 5FG] [2 3EA]
 32   +-minimap----------+
 33   | ~~ river ~~  [] o| +-selection panel----------------------------------------------+ +-command card----+
 34   |  <> shrine  (paw)| | (3) VESSA          | [tile] ROOKWATCH · watchtower             | |                 |
 35   | ::camp  ( ) lair | | HP  350 / 350      |        Held by the enemy                  | |                 |
 36   |   tower ring ... | | Mana 100 / 100     |        The enemy is capturing 7 / 12 s    | |                 |
 44   +------------------+ +----------------------------------------------------------------+ +-----------------+
```

---

## 2. Objectives strip (12.C7, `scripts/ui/mapfill_bar.gd`, `class_name MapfillBar extends Control`)

### 2.1 Placement and data
- `static func attach(hud: Node, selection: Node) -> MapfillBar` (lead glue in `hud.gd`, like the flag card): a
  `Control` under the HUD root, `PRESET_CENTER_TOP`, `mouse_filter IGNORE` on the holder. It finds `CapturePoints`
  (class list, then group `"capture_points_service"`, retried every 1 s while null) and hides itself while there is none
  or `points()` is empty.
- **Order** ("map order"): grouped by kind **watchtowers, wells, shrines**; inside a group from west to east (`x`
  ascending, then `z`). On Crown Hollow: `Rookwatch (-24,-41)`, `Millwatch (-6,40)`, `Saltwatch (6,-40)`, `Owlwatch
  (24,41)` | `Mossmere Well`, `Stonemere Well` | `West Wayshrine`, `East Wayshrine`. So in each group the points on the
  player's (west) bank come first. Built once at setup (points never move); a mission with one shrine gets one icon.
- Refresh at **10 Hz** (colours, timers, progress); the tooltips rebuild on hover.

### 2.2 Layout (8 points; the widths follow the formula below for other counts)
```
 650  661     693     725     757   785  793  802     834   862  870  879     911   939       950
  52 +---------------------------------------------------------------------------------------+
  58 |  [T]     [T]     [T]     [T]         |    [W]     [W]          |    [S]     [S]           |   icons 28 x 28
  86 |                                      |                         |                          |
  88 |  ===                                      1:12    1:12                 0:42               |   row 2: progress / timers
 102 +---------------------------------------------------------------------------------------+
```
| Part | Rect | Look |
|---|---|---|
| Panel | 300 x 50 at (650, 52) | Slate (`slate_bg`, 1 px `frame_dark` border, radius 2), no drop shadow. Width = 22 + sum over groups of (28 n + 4 (n - 1)) + 17 per separator; x = 800 - width / 2 |
| Icons | `Button`s 28 x 28 at x 661, 693, 725, 757 (towers), 802, 834 (wells), 879, 911 (shrines), y 58 | Slot frame 3.3 at 28 px (margins 8 fit), `focus_mode NONE`; the **point glyph** 18 x 18 at (5, 5) inside (2.3) filled with the owner colour |
| Separators | 1 x 20 at x 793 and x 870, y 62 | `frame_dark` (the top bar's separator) |
| Row 2 | y 88-100 under each icon | Either the **progress strip** 28 x 3 at (icon x, 90) in the capturer's colour (width = `progress` x 28, only while the point's cell is visible, 4.2 of the spec), or the **countdown** number font 11 `text_muted`, centred under the icon at y 87 (height 13): asleep shrines `0:42` (`time_until_awake()` as m:ss, nothing when INF), wells before 2:30 `1:12` (time to `WELL_START`). Last 10 s: `GOLD`. Progress wins over the countdown |

### 2.3 The point glyphs (drawn in code, `_draw`, box s x s, all coordinates x s / 18; 1 px `groove` outline)
Same shapes as the minimap (square / circle / diamond, section 9), so the strip reads like the map.
| Kind | Shape |
|---|---|
| Watchtower | Filled owner colour: body rect (5, 7)-(13, 17), platform rect (3, 4)-(15, 7), three merlons (3, 1)-(6, 4), (7.5, 1)-(10.5, 4), (12, 1)-(15, 4) |
| Essence well | Filled circle centre (9, 11) r 6 in the owner colour; inner disc r 3 `(0.35, 0.20, 0.50)` (the violet mist); roof chevron (3, 5) -> (9, 1) -> (15, 5) 2 px `frame_light`; posts (4, 5)-(4, 10) and (14, 5)-(14, 10) 1.5 px `frame_light` |
| Wayshrine | Diamond (9, 5), (14.5, 11), (9, 17), (3.5, 11) filled in the owner colour; the floating rune = a circle (9, 2) r 1.5, `GOLD` when awake, else `text_muted` |
Owner colour: `OWN` for `owner_team == 0`, `ENEMY` for 1, `POINT_NEUTRAL` for -1 (section 15.1). The same glyphs are used at
18 px (strip), 12 px (blessing chip: the shrine only), 60 px (point panel tile fallback).

### 2.4 Icon states (first matching row wins for the rim; glyph effects add up)
| State | Look |
|---|---|
| Hover | `frame_light` rim + the 1 px `trim_glow` halo (3.3) |
| Selected (its point panel is open) | `GOLD` rim, steady |
| Own point being taken (enemy `capturing` / `neutralising` it, cell visible) | Rim `WARN`, alpha pulse 0.6-1.0 at 2 Hz |
| Awake shrine | Glyph `GOLD`, rim `GOLD` pulsing alpha 0.7-1.0 at 2 Hz, plus a 2 px outer halo `GOLD` alpha 0.35 (32 x 32, like the top-item halo 6.3) |
| Asleep shrine | Glyph at alpha 0.45 in its colour (the last capturer's until it wakes again, then neutral) + the countdown |
| Contested (visible) | Glyph colour lerps to white `(1, 1, 1)` and back at 3 Hz; progress strip frozen |
| Otherwise | Normal rim `frame_metal`, glyph in the owner colour |
Owner changes flash the icon: scale 1.0 -> 1.2 -> 1.0 in 0.25 s (`pivot_offset` centre).

### 2.5 Input and tooltip
- **Click** (left): `camera_rig.focus_on(point.global_position)` (the `RTSCamera` found as `minimap.setup` does). It never
  selects the point (the panel opens on a world click, section 4). No keys.
- **Tooltip** (`tooltip_text`, the custom panel of `ui-style.md` 8; the strip is at the top of the screen, so the tooltip
  opens **below** the icon, 8 px under it, clamped on screen):
  1. `Rookwatch` (Cinzel 15 `title`) + right-aligned `Watchtower` / `Essence well` / `Wayshrine` (muted)
  2. Owner + state, the point panel's two texts joined by ` · `: `Held by the enemy · The enemy is capturing 7 / 12 s`
     (colours as 4.2)
  3. The effect line of 4.2 (`text_muted`)
  4. `On the enemy bank: capture takes 25 % longer` in `FAR` (only for points on the other team's bank)
  5. `Click: centre the camera` in `GOLD` (the learn-hint look)
  Tests read the string (lines joined by `\n`).

### 2.6 Blessing chips (the own and the enemy Wayfarer's Blessing)
| Part | Rect / look |
|---|---|
| Slots | 144 x 22 at (958, 54) and (958, 78). The first **running** blessing takes the upper slot (own first); none running = nothing shown |
| Chip | Chip style: `UIStyle.slate_style(4.0, border)`, margins 6 / 3, radius 2; border `GOLD` (own) / `ENEMY` (enemy) |
| Content | `HBoxContainer` gap 4: the shrine glyph 12 x 12 (2.3) in `GOLD` / `ENEMY`, then font 12: `Blessing` in `GOLD` + ` 38 s` `text` (own); `Enemy blessing` in `ENEMY` + ` 38 s` `text` (enemy). Est. widths 95 / 128 px, so 144 fits both |
| Last 10 s | Seconds `WARN`, chip alpha pulse 0.6-1.0 at 2 Hz |
| Start / refresh | Fade in 0.2 s + scale 1.1 -> 1.0 (0.2 s) on `blessing_started`; the same pop on a refresh to 60 s |
| Tooltip | Own: `Wayfarer's Blessing 38 s\n+12 % speed, +1.5 HP / s for your soldiers, wizard and champions\nTake another awake shrine to reset it to 60 s`. Enemy: `Enemy blessing 38 s\n+12 % speed, +1.5 HP / s for their soldiers, wizard and champions` |
Data: `CapturePoints.blessing_time_left(team)` polled at 10 Hz (0 = hidden), `ceili` for the seconds.

---

## 3. Capture rings in the world (12.C6, `scripts/vfx/capture_rings.gd`, `class_name CaptureRings extends Node3D`, group `"capture_rings"`)
- `static func attach(hud: Node, selection: Node) -> CaptureRings`: adds itself to `hud.get_parent()` (the level), finds
  `CapturePoints` (retry every 1 s), and makes one ring per point. Lead glue: `hud.attach_optional(...)`.
- **Mesh**: per point one `MeshInstance3D` with a flat `QuadMesh` (size `2 x (capture_radius + 0.6)` m, rotated to lie on
  the ground) at the point's `(x, 0.20, z)`, `cast_shadow OFF`, and a `ShaderMaterial` from one shared `Shader` built in
  code (unshaded, `blend_mix`, `cull_disabled`, depth test on so units stand on it). Uniforms: `radius`, `width`, `color`,
  `dashes` (0 = solid), `dash_phase`, `arc_color`, `progress` (0-1), `flash` (0-1), `glow` (0-1). Only uniforms change
  (10 Hz); nothing is rebuilt. 8 quads, 8 materials.
- **Shader look** (distance `d` from the centre in metres): ring band `|d - radius| < width / 2` in `color`; inner glow
  band `radius - 0.6 < d < radius` with alpha `color.a x 0.25 x (d - radius + 0.6) / 0.6 x glow`; dashes: the ring is cut
  into `dashes` segments at 60 % duty, rotated by `dash_phase`; arc: where `angle` (0 at north `-z`, clockwise seen from
  above) `< progress x TAU` the band widens to `width x 1.8` in `arc_color`; `flash` mixes the ring colour toward white.
| Point state | Ring | Arc |
|---|---|---|
| Neutral | `POINT_NEUTRAL` lightened to `(0.85, 0.85, 0.85)` alpha 0.40, width 0.20 m, **24 dashes**, glow 0 | - |
| Own / enemy held | `OWN` / `ENEMY` alpha 0.70, solid, width 0.20 m, glow 1 | - |
| Capturing / neutralising (cell visible) | Stays the current owner's look | Capturer's `OWN` / `ENEMY` alpha 0.9, `progress` |
| Contested (cell visible) | `flash` = 0.5 + 0.5 sin(3 Hz), alpha 0.9 | Frozen |
| Decaying (nobody there) | Owner's look | The arc shrinks with `progress` |
| Asleep shrine | `(0.60, 0.60, 0.65)` alpha 0.25, 24 dashes (the last capturer's colour at alpha 0.40, solid, while it keeps it) | - |
| Awake shrine | `GOLD`, alpha 0.5-0.9 pulse at 1 Hz, 24 dashes turning at 0.2 rad / s, glow 1 | As above when captured |
| Selected (panel open) | Width x 1.5, alpha + 0.2 | |
- The ring (owner and shrine state) is always drawn: points are explored for both teams from 0:00 (4.2). The **arc and the
  flash** only while `FogOfWar.is_visible(local_team, point_pos)`.
- Colours are the **relation** colours (own green / enemy red), not the kingdom team colours: the model's banner already
  shows the kingdom colour, the ring answers "mine or theirs" at a glance, like the strip and the minimap.
- The `capture_done` burst is the tech-artist's (`MapFillVfx`), not this node's.

### 3.1 Camp respawn timers and camp memory (12.C6, same node)
- **Camp memory** (read by the minimap, section 9): per camp `{state: &"unknown" / &"alive" / &"cleared", known_cleared:
  bool}`. Every 0.5 s, for each camp whose spot is **visible** to the local team: `state = &"cleared" if is_cleared() else
  &"alive"`; fogged camps keep their last state; a camp first seen explored but never visible = `&"alive"`.
  `known_cleared` = true on `camp_cleared(camp, team, reward)` when `team` is the local team or the spot is visible at that
  moment; false on the camp's `respawned`. `camp_state(camp) -> StringName`, `is_known_cleared(camp) -> bool` (public).
- **Floating `1:20`**: over each camp with `known_cleared` while its spot is visible now: a `Label3D` at the camp +
  (0, 1.0, 0), text `respawn_left()` as m:ss (refreshed at 2 Hz), `font_size 40`, `pixel_size 0.006` (the stake label's
  size), `modulate (0.85, 0.85, 0.80)`, last 10 s `GOLD`, `outline_modulate` black, `outline_size 8`, `billboard ENABLED`,
  `no_depth_test true`, `cast_shadow OFF`. Hidden when the timer reads 0 (respawn blocked by units: the camp simply waits).

---

## 4. Point panel (12.C7, `scripts/ui/point_panel.gd`, `class_name PointPanel extends Control`; the click plumbing is 12.C6)

### 4.1 Plumbing (12.C6, `selection_manager.gd`)
- A left-click on a capture point (layer-2 ray with `collide_with_areas = true`, walking up to the node in group
  `"capture_points"`; or the ground within `capture_radius x 0.5` of a watchtower / well centre) does what a post click
  does (`ui-trade.md` 9.1): clears the other selections, sets `selection.selected_neutral = point`, calls
  `set_selected(true)` and emits `neutral_building_clicked(point)`. Right-click on a point with units selected = a normal
  ground move to that spot (points are never targets).
- `static func attach(hud: Node, selection: Node) -> PointPanel` (lead glue in `hud.gd`, like the post panel). Visible
  only while `selection.selected_neutral` is in group `"capture_points"` (the post panel ignores it: it checks its own
  groups). Refresh at **10 Hz**. Command card: empty, no text block.

### 4.2 Layout (676 x 204 at (588, 670), `panel_bg` alpha 1 over the selection area)
```
 588        696                                            860                     1264
 670 +--------+ ROOKWATCH · watchtower
     |  tile  |
     | 96x96  | Held by the enemy                                          700
     | (glyph)| The enemy is capturing 7 / 12 s    [========      ]        722  (bar 200 x 10 at (860, 727))
 766 +--------+ Sight 22 for its owner                                     746
                On the enemy bank: capture takes 25 % longer               770
                Capture: stand in the ring with soldiers, champions or your wizard · R: Guard it when yours   806
```
| Element | Rect | Look |
|---|---|---|
| Tile | 96 x 96 at (588, 670) | Slot frame, rim = owner (`OWN` / `DEFEAT` / `frame_dark` for neutral), the portrait's radial gradient bg; icon `art/icons/points/<kind>.png` 88 x 88 inset 4 (asleep shrine: `shrine_asleep.png`; 12.V26), fallback: the glyph (2.3) at 60 px centred, alpha 0.9. Awake shrine: rim `GOLD` pulsing 0.7-1.0 at 2 Hz |
| Title | (696, 670) | Cinzel 20 `title` `ROOKWATCH` (`display_name`) + ` · watchtower` / ` · essence well` / ` · wayshrine` font 14 `text` |
| Owner | (696, 700) font 14 | Towers and wells: `Held by you` `NEAR` / `Held by the enemy` `WARN` / `Neutral` `text_muted`. Shrines: `Last captured by you` / `Last captured by the enemy` / `Not captured yet` (same colours) |
| State | (696, 722) font 14 | See the table below. Hidden (empty) when idle with no progress |
| Progress bar | 200 x 10 at (860, 727) | Bar style 5.3 without text or ticks, fill = the capturer's `OWN` / `ENEMY`; only with a capturing / neutralising / decaying state and the cell visible |
| Effect | (696, 746) font 13 `text` | Watchtower `Sight 22 for its owner`; well `+0.4 essence / s · +3 mana / s to your wizard within 8 m` (est. 330 px) + before 2:30 `  ·  pays from 2:30` `WARN`; shrine `Blessing: +12 % speed, +1.5 HP / s for 60 s` |
| Far bank | (696, 770) font 13 `FAR` | `On the enemy bank: capture takes 25 % longer` when `bank` is the other team's bank (not the isle, not own); else hidden |
| Hint | (696, 806) font 12 `text_muted` | `Capture: stand in the ring with soldiers, champions or your wizard · R: Guard it when yours` (est. 500 px, fits 568) |

| `state` (+ who) | State text (font 14) | Colour |
|---|---|---|
| `capturing`, own team | `Capturing 7 / 12 s` | `NEAR` |
| `capturing`, enemy | `The enemy is capturing 7 / 12 s` | `WARN` |
| `neutralising`, own / enemy | `Neutralising 4 / 12 s` / `The enemy is neutralising 4 / 12 s` | `NEAR` / `WARN` |
| `contested` | `Contested: both sides are here` | `FAR` |
| `idle` with progress > 0 (decaying) | `Capture fading 4 / 12 s` | `text_muted` |
| `asleep` | `Asleep: wakes in 1:40` (`time_until_awake()`; INF -> `Asleep`) | `text_muted` |
| `awake` | `Awake: capture it for the blessing` | `GOLD` |
| any, cell **not visible** | `Not in sight` (owner line still shown) | `text_muted` |
Seconds: `floori(progress x T)` / `T` with `T = time_for(capture_team, 1)` (includes the x1.25 far bank), `ceili` on T.
Test helper: `panel_lines() -> PackedStringArray` (title, owner, state, effect, far bank, hint as shown).

---

## 5. Camps: creature inspect lines and hover chip (12.C7)

### 5.1 Camp lines in the single view (`selection_panel.gd` `_update_single`, creatures only)
When the viewed unit belongs to a camp (`CampManager.camp_of(u)` not null; the Ruin Wardens have none), two rows are
shown under the stat line; everything else of the read-only single view is unchanged (portrait with the neutral rim,
name, HP bar, stat line at y 730).
```
 696
 670 BRISTLEBACK
 700 [HP  200 / 200 ===================]
 730 Damage 11 · Range 1.4 · Speed 4.6 · Armor 5
 752 Gloomcap Hollow · Tier 2 · 3 of 4 left · Level 1            (font 13)
 772 ~86 XP · +25 essence · 35 % a component · Underdog bonus    (font 13)
 796 [M 3]                                                       (status chips, existing row)
```
| Row | Rect | Text and colours |
|---|---|---|
| Camp row | (696, 752) font 13, `HBoxContainer` gap 0 | `Gloomcap Hollow` `text` + ` · ` `text_muted` + `Tier 2` in the tier colour (15.1) + ` · 3 of 4 left` `text` (`creatures().size()` of `reward_preview().creatures`) + ` · Level 1` `text_muted` only when `camp_level > 0` |
| Reward row | (696, 772) font 13 | `~86 XP` `GOLD` + ` · ` + `+25 essence` `ESSENCE_TEXT` + ` · ` + `35 % a component` `text_muted` (`drop_text`) + ` · Underdog bonus` `NEAR` when `CampManager.underdog_team()` is the local team |
| Status chips | (696, 796) | The existing row moves down under the two rows (VBox order) |
- Longest (Stag Glade, tier 3): `~160 XP · +50 essence · a component · 40 % Warden Scale or Vital Root · Underdog bonus`
  est. 520 px, fits the 568 px to x 1264. The two rows stay on screen when the creature dies (the view shows the dead
  unit until the selection clears, as today).
- Test helper `camp_line_text() -> String` = the spec's single line: `Gloomcap Hollow · Tier 2 · 3 of 4 left · ~86 XP ·
  +25 essence · 35 % a component` (no level, no underdog).

### 5.2 Camp hover chip (`mapfill_bar.gd`; the "camp hover card" of map-fill 6)
- Shown while the mouse rests **0.25 s** over a visible camp creature (`selection.unit_at(selection.mouse_position())`,
  polled at 10 Hz, then `camp_of`), no window open, no pending order, not in bounty mode (its chip wins), and no route
  chip showing. Position mouse + (18, 12), clamped with a 4 px margin (flip left at the right edge), `z_index 10`,
  `mouse_filter IGNORE`.
- Chip style (`slate_style(4.0, frame_metal)`, margins 6 / 4, height 26), one `HBoxContainer` gap 0, font 13:
  `Gloomcap Hollow` `GOLD` + ` · Tier 2` in the tier colour + ` · ~86 XP · +25 essence` `text`. Widest (`Bristleback
  Wallow · Tier 1 · ~50 XP · +10 essence`) est. 300 px.

---

## 6. Epic beasts (12.C7)

### 6.1 Boss bar (`mapfill_bar.gd`; a reusable `BossBar` inner class, also for `titans-2.md` and the story bosses)
```
 572                                                                                   1028
 156 +------------------------------------------------------------------------------------+
 158 | (paw) OLD SCARBACK  · Epic beast · alpha                              Enraged       |   name row
 180 |  [==================== 1 620 / 2 160 ===============               ]              |   bar 440 x 18
 206 +------------------------------------------------------------------------------------+
```
| Part | Rect | Look |
|---|---|---|
| Panel | 456 x 50 at (572, 156) (2nd bar at (572, 212)), `PRESET_CENTER_TOP` | Slate with a 1 px `BEAST` border at alpha 0.6, radius 2, drop shadow as the heavy frame's (3.1) |
| Paw | 14 x 14 at (582, 160) | The paw glyph (9.3) in `BEAST` |
| Name | (600, 158) | Cinzel 16 in `BEAST`: `OLD SCARBACK` (the beast's `unit_type.display_name`, else the `NAMES` table's second entry capitalised) |
| Subtitle | right after the name, font 13 | ` · Epic beast` `text_muted`; variant B adds ` · alpha` (Tusker) / ` · dark breed` (Roc) / ` · silver breed` (Direwolf) / ` · elder` (Grizzlemaw) in `GOLD` |
| State | right-aligned, right edge x 1018, y 160, font 12 | `Enraged` `WARN` (a Grizzlemaw below 30 % HP), `Escaping` `FAR` (a Roc with the `shroud` status: its Updraft); later titans add `Airborne` / `Grounded 4 s`. Empty otherwise |
| Bar | 440 x 18 at (580, 180) | Bar 5.3 (gradient fill, ticks, **ghost damage**, heal flash, low-HP pulse under 30 %) with fill `HP`; text number font 13 `1 620 / 2 160` (thin-space thousands, `SelectionPanel.thousands`), outline 3. Optional phase marks for later bosses: 2 px `frame_light` ticks at given ratios |
- **Which beasts** (checked at 4 Hz): living nodes of group `"beasts"` with `is_visible_in_tree()` (the fog hides them
  like enemy units), and either **engaged** (it took damage or hit a local-team unit in the last 5 s: `damage_taken`
  and the victims' `damage_taken` with `attacker` in `"beasts"`) or **on screen** (its position projects inside the
  viewport). Priority: engaged first, then the nearest to the screen centre. At most **2** bars; the first slot is the top one.
- **Appear**: `modulate.a` 0 -> 1 in 0.2 s (no slide). **Leave** (not qualifying for 1.5 s, or hidden by the fog): fade
  out 0.3 s. **Death**: the bar drains to 0, flashes white 0.2 s, fades out over 0.5 s.
- **Click** on a bar: `camera_rig.focus_on(beast.global_position)` (never selects it). No tooltip.
- The beast's own world HP bar (gameplay, `unit.gd`) is unchanged.

### 6.2 Inspect card (`selection_panel.gd`: the single view for a unit in group `"beasts"`)
Clicking a visible beast opens the read-only single view as for any neutral unit; beasts add a block. Layout:
```
 588        696                                                  1000      1058      1116
 670 +--------+ OLD SCARBACK · Epic beast · alpha                   +------+  +------+
     |portrait|                                                     |  GC  |  |  BH  |    676 (48 x 48)
     | 96x96  | [HP  1 620 / 2 160 ===============]                 +------+  +------+    724
 766 +--------+ Damage 34 · Range 1.8 · Speed 5.5 · Armor 20         Gore Ch.  Bristle.    728 (font 11)
                Drops: 2 components · 30 % Vital Root                                     752
                Roams the West Heath                                                      774
                [D 1]                                                                     796 (status chips)
```
| Element | Rect | Look |
|---|---|---|
| Portrait | 96 x 96 at (588, 670) | Existing portrait (neutral rim `frame_dark`); the model's variant follows `beast_variant` (the portrait instance calls `set_variant` when the model has it) |
| Name row | (696, 670) | Cinzel 20 `title` name + the boss-bar subtitle at font 14 (` · Epic beast` `text` + the variant word in `GOLD`) |
| HP bar / stat line | (696, 700) / (696, 730) | Existing (the stat line already ends with ` · Armor 20` when armor > 0) |
| Drops | (696, 752) font 13 | `Drops: ` `text_muted` + the drop text `text` (rule below) |
| Lair | (696, 774) font 13 `text_muted` | `Roams the West Heath` (`lair_of(beast).name`) |
| Status chips | (696, 796) | Existing row |
| Abilities | slots 48 x 48 at (1000 + 58 j, 676), j < 3 (the Grizzlemaw has 3) | As the champion ability slots (`ui-champions.md` 4): slot frame, icon `art/icons/abilities/<id>.png` 40 x 40 or the abbreviation font 14; the **radial cooldown sweep** from `CreatureAbilities.cooldown_left(id)` (child `"CreatureAbilities"` of the beast; total = the cooldown of the table below; none for passives), no ready flash. Beasts are PvE, so their timers are shown (unlike enemy champions) |
| Ability names | (1000 + 58 j, 728), width 54, font 11 `text_muted` | Clipped with an ellipsis |
| Ability tooltip | section-8 panel | `Gore Charge\nEvery 12 s · a target 6-14 m away\n<effect>` (table) |

**Drop text rule** (from `EpicBeasts.DROP_TABLES[kind].rows` for the beast's variant: rows with `variant` -1 or equal):
rows with `chance 1.0` and several items count as components (`a component`, `2 components`); a `chance 1.0` row with one
item names it (`Warden Scale`); a row under 1.0 reads `30 % Vital Root` / `60 % Warden Scale or Vital Root`; joined with
` · `; ` · a trophy` is appended when the variant's trophy id exists (`ItemType.find(id)`). Examples: Ironhide Tusker
`a component · 30 % Vital Root`; Old Scarback `2 components · 30 % Vital Root`; Elder Grizzlemaw `a component · 60 %
Warden Scale or Vital Root · Warden Scale`. Item names from `ItemType.find(id).display_name`.

| id | Name / abbr | Line 2 | Line 3 (effect) |
|---|---|---|---|
| `gore_charge` | Gore Charge / GC | `Every 12 s · a target 6-14 m away` | `Dashes at it: 45 damage and dazed 0.8 s; 20 damage near its path` (Old Scarback: `45 damage and dazed 1.2 s to everyone on its path`) |
| `bristle_hide` | Bristle Hide / BH | `Passive` | `Melee attackers take 4 damage per hit` |
| `gale_swoop` | Gale Swoop / GS | `Every 10 s · leaps up to 12 m` | `Onto the most crowded spot: 40 damage within 2.5 m, dazed 0.5 s` |
| `shrieking_dive` | Shrieking Dive / SD | `Every 10 s · leaps up to 12 m` | `Onto the most crowded spot: 40 damage within 2.5 m, marked 5 s` |
| `updraft` | Updraft / UD | `Once, at 40 % HP` | `Shrouded 4 s, flies to its nest and heals 15 %: chase it` |
| `pounce` | Pounce / PO | `Every 9 s (Moonpelt: 6 s) · a target 5-10 m away` | `Leaps on it: 35 damage and rooted 0.8 s` |
| `hamstring` | Hamstring / HS | `Passive` | `Its hits slow by 25 % for 3 s` |
| `maul` | Maul / MA | `Every 9 s` | `70 damage to its target and marked 5 s` |
| `rending_roar` | Rending Roar / RR | `At 50 % HP, then every 30 s` | `Dazes enemies within 6 m for 1 s (half on heroes)` (Elder: `+ taunts soldiers 3 s`) |
| `enrage` | Enrage / EN | `Below 30 % HP` | `Attacks 30 % faster` |

### 6.3 Command card with a beast viewed (`command_card.gd`)
All slots empty; the champion inspect text block (`ui-champions.md` 4) with: `Epic beast: attack it with your army.` font 14
`text_muted` at y 740 and `Hunt it with a bounty  [R]` font 13 `text` with the inline 18 x 14 gold badge at y 762 (the
enemy champion's second line, same string). `inspect_text()` returns both lines.

### 6.4 Spawn roar
On `beast_spawned(beast, lair_id, variant)`: the roar sound (section 14) and a **minimap ping** at the lair centre (3
expanding rings as the hunt-warning ping, `ui-champions.md` 9, in `BEAST` instead of `WARN`). The spawn message is the
service's (section 10).

---

## 7. Game critters (12.C6 clicks, 12.C7 card and floats)

### 7.1 Clicks, right-click, cursor (12.C6, `selection_manager.gd`)
- The selection ray (left-click, right-click, hover) sets `collide_with_areas = true` on mask 2 and walks up from the hit
  `Area3D` ("ClickArea") to the node with `is_game_critter()`. Hidden or dead critters have layer 0, so the existing
  `_is_hidden()` check is enough.
- **Left-click**: like a post click: `selected_neutral = critter`, `neutral_building_clicked(critter)`; cleared when the
  critter dies or hides (checked at 4 Hz), on Esc and on any other selection.
- **Right-click / A-click** on a visible critter: `command_attack(critter)` for every selected unit that can hunt =
  `not u.is_non_combatant() and not u.has_method(&"command_gather")`, not in `"caravans"`, not in `"trackers"`. The
  others **ignore the critter**: they get the order the same click gives on the ground under it (a move / attack-move to
  that point). Never `Worker.command_attack(critter)` (typed, it would error).
- **Cursor**: while at least one hunter is selected, no order is pending and the mouse is over a visible critter:
  `Input.CURSOR_CROSS` + the selection manager's ring (`show_bounty_ring(pos, target_radius() + 0.3, (0.95, 0.35, 0.3,
  0.7))`); back to `CURSOR_ARROW` / hidden ring when it leaves. Bounty mode on a critter: its chip shows `Hunt · Invalid
  target` (`BountyBoard.kind_for` refuses it).

### 7.2 Critter card (12.C7, `point_panel.gd`, the same 676 x 204 panel, shown while `selected_neutral.is_game_critter()`)
```
 588        696
 670 +--------+ RED DEER · game
     |  tile  |
     | 96x96  | [HP  45 / 60 ======================]              700
     |  (RD)  | Hunt it: +5 essence, venison heals the hunter 40 HP   730
 766 +--------+ Your units within 6 m heal 20 HP                   752
                Grazing                                            774
                Right-click with soldiers or your wizard selected to hunt it · workers and caravans ignore it   806
```
| Element | Rect | Look |
|---|---|---|
| Tile | 96 x 96 at (588, 670) | Slot frame, neutral rim `frame_dark`, portrait gradient bg; icon `art/icons/critters/<kind>.png` 88 x 88 (12.V26) or `UIStyle.abbrev(display_name)` Cinzel 28 `title` |
| Title | (696, 670) | Cinzel 20 `title` `RED DEER` / `RABBIT` + ` · game` font 14 `text` |
| HP bar | 280 x 22 at (696, 700) | Bar, fill `HP`, `HP  45 / 60` |
| Reward | (696, 730) font 14 | Deer: `Hunt it: ` `text_muted` + `+5 essence` `ESSENCE_TEXT` + `, venison heals the hunter ` `text` + `40 HP` `NEAR`. Rabbit: `Hunt it: ` + `+1 essence`. Numbers from `reward` and `CritterHerds.VENISON_HEAL`; unknown reward keys (step 15 `food`) are appended as `+10 food` `text` |
| Venison | (696, 752) font 13 `text_muted` | Deer only: `Your units within 6 m heal 20 HP` (`VENISON_AREA_HEAL`) |
| State | (696, 774) font 13 | `Grazing` `text` / `Fleeing` `FAR` (`is_fleeing()`) |
| Hint | (696, 806) font 12 `text_muted` | `Right-click with soldiers or your wizard selected to hunt it · workers and caravans ignore it` (est. 510 px) |
Command card: empty; the text block (6.3 layout) with `Game: hunt it with soldiers or your wizard.` only (no `[R]` line:
flags are refused on critters). Test helper `card_text()` = the spec strings: `Red deer · 60 HP · Hunt it: +5 essence,
venison heals the hunter 40 HP` / `Rabbit · +1 essence`. No minimap dot, no message line.

### 7.3 Floating `+5` / `+40` / `+1` (12.C7, `scripts/vfx/mapfill_popups.gd`, `class_name MapfillPopups extends Node3D`, group `"mapfill_popups"`)
On `CritterHerds.critter_hunted(critter, team, reward)` with `team` = the local team and the critter visible at that moment:
| Text | Where | Look |
|---|---|---|
| `+5` (deer) / `+1` (rabbit): the reward's essence | critter position + (0, 1.6, 0) deer / (0, 0.8, 0) rabbit | `Label3D` as the trade `+28` (`ui-trade.md` 12): `font_size 40`, `pixel_size 0.006`, outline 8 black, billboard, `no_depth_test`, rises 1.5 m over 1.0 s (ease out), fades over the last 0.4 s; `modulate ESSENCE (0.75, 0.45, 1.0)` |
| `+40` (deer only, the venison heal) | the hunter `by` + (0, `body_height` + 0.9, 0), 0.15 s after the `+5`; skipped if `by` is freed | Same, `modulate NEAR (0.4, 0.9, 0.4)` |
Pool of **6** labels (a 7th replaces the oldest). Unknown reward keys (step 15) get their own label later; nothing today.

---

## 8. Blessing and wading chips on units (12.C7, `selection_panel.gd` status rows)
Added to the **three** existing status rows (hero column at (282, 784), single view, champion view), after the timed
status chips, in this order: blessing, wading.
| Chip | Size | Look | Shown while | Tooltip |
|---|---|---|---|---|
| Blessing | 40 x 20 | Slate chip with a 1 px `GOLD` border (the status-chip style), the shrine glyph 10 x 10 in `GOLD` at (4, 5), seconds font 12 `text` right of it (`38`) | `u.has_modifier(&"blessing:wayshrine")`; seconds = `CapturePoints.blessing_time_left(u.team)` | `Wayfarer's Blessing 38 s\n+12 % speed, +1.5 HP / s` |
| Wading | 20 x 20 | Slate chip, 1 px `WARN` border (a debuff), the wave glyph 12 x 8 centred: three 1.5 px sine polylines (amplitude 1 px, period 6 px) at y 2 / 5 / 8 in `WADE (0.60, 0.78, 0.88)` | `u.has_modifier(&"terrain:ford")` | `Wading: -35 % speed` |
- The hero column row (x 282-488 before the points chip) fits four 40 px chips + one 20 px chip with 4 px gaps.
- `status_row_text()` adds `Blessing 38` and `Wading` for tests. `terrain.md` (step 12b) later generalises the wading
  chip into its terrain chip (same 20 x 20 place, rim green / red / grey).
- Multi-select icons and the world get nothing new (the blessing rune over units is the tech-artist's `MapFillVfx`).

---

## 9. Minimap (12.C6, `minimap.gd`)

### 9.1 Layers and pass order
Map scale: 220 px for 120 m = **1.833 px / m**.
| Layer | Draw | Pass |
|---|---|---|
| Water, fords, bridges | Once at setup (retry every 2 s while `RiverSystem` is null): `mask_image()` (240 x 240, 0.5 m / px: R water, G ford, B bridge) turned into an `ImageTexture` (alpha 0 where all channels are 0; water `WATER (0.25, 0.45, 0.65)`, ford `FORD (0.45, 0.62, 0.72)`, bridge `ROAD_COLOR (0.55, 0.45, 0.30)`; bridge wins, then ford), drawn over the whole map rect with `LINEAR` filtering | Right after the ground fill, **before** the roads and the fog (black while unexplored, like roads) |
| Own tower sight rings | For each watchtower with `owner_team == 0`: `draw_arc` radius `22 x 1.833 = 40.3` px, 48 points, 1 px, `OWN` at alpha 0.35 | After the fog, before the buildings |
| Lairs | For each lair (`EpicBeasts.lairs()`) whose centre is explored: a dashed circle radius `(radius + 3) x 1.833` px (Tusker 12.8 px), 16 arcs drawn every other one (8 dashes), 1 px, `BEAST` alpha 0.45; while the beast is **known alive** a 4 x 4 paw (9.3) at the centre, `BEAST` alpha 0.7 | After the trade buildings, before the loot sacks |
| Camps | For each camp whose spot is explored: 4 x 4 in its tier colour with a 1 px `groove` border (6 x 6 overall); last seen cleared (`CaptureRings.camp_state == &"cleared"`): the 4 x 4 **outline only** (1 px, tier colour), no border | Same pass, after the lairs |
| Capture points | Always (explored from 0:00): watchtower 5 x 5 **square**, well 5 x 5 **circle** (`draw_circle` r 2.5), shrine 5 x 5 **diamond**, filled `OWN` / `ENEMY` / `POINT_NEUTRAL` + 1 px `groove` outline. Awake shrine: fill `GOLD` + a ring growing from r 4 to r 7 px while its alpha falls 0.8 -> 0 every 1.0 s. Asleep shrine: fill at alpha 0.5. Selected point: + a 1 px `GOLD` square / ring 2 px outside | After the camps (icons over ground info) |
| Visible beasts | In the units loop, units in group `"beasts"` skip the 3 x 3 square; after the champions and before the heroes: a **6 x 6 paw** in `BEAST` with a 1 px `groove` outline behind each pad (circles r + 0.5) | Units pass |
| Creatures, game critters | Creatures stay the neutral 3 x 3 squares (unchanged). Game critters: **no dot** (they are not in `"units"`) | - |
- Lair "known alive": true after `beast_spawned` for that lair (the announcement reaches both teams), false after
  `beast_slain`; at setup `EpicBeasts.beast_of(lair_id) != null`.
- Test counters (ints, like `drawn_ghosts`): `drawn_points`, `drawn_held_points`, `drawn_awake_shrines`, `drawn_camps`,
  `drawn_cleared_camps`, `drawn_lairs`, `drawn_lair_paws`, `drawn_beasts`, `drawn_sight_rings`; `water_drawn: bool`.
- Minimap clicks unchanged (a point or a lair is not a click target; bounty mode clicks still place Explore flags).
  Nothing else changes (10 Hz redraw, fog texture, pings).

### 9.2 Colour check
Neutral points `(0.62, 0.64, 0.70)` (cool grey, outlined, 5 px) stay apart from the fog ghosts `(0.55, 0.55, 0.6)` (6 px,
no outline) and the tier-1 camps `(0.85, 0.85, 0.75)` (warm, 4 px). Tier-3 camps `(1.0, 0.3, 0.25)` are close to enemy units
`(1.0, 0.3, 0.3)`: the camp's 6 x 6 dark-bordered square vs the unit's plain 3 x 3 square tells them apart.

### 9.3 The paw glyph (box s, centre c; used at 4, 6, 14 px)
Main pad: a circle r `0.28 s` at `c + (0, 0.15 s)`; three toes: circles r `0.14 s` at `c + (-0.30 s, -0.18 s)`,
`c + (0, -0.32 s)`, `c + (0.30 s, -0.18 s)`. Filled; at 4 px drop the outline.

---

## 10. Messages (`GameHUD.show_message(text, seconds)`, gold font 22, outline 3, y 120)
Texts exactly as the services emit them (`map-fill.md` 4.3, 4.4, 5.3, 5.5); all come with 4.0 s.
| Message | Source |
|---|---|
| `Your forces captured Rookwatch` / `The enemy captured Rookwatch` / `Rookwatch was neutralised` / `Your forces are capturing Mossmere Well` / `The enemy is taking Mossmere Well!` | `CapturePoints.message` (the service throttles the last two) |
| `The essence wells are brimming` (2:30) / `The Wayshrines awaken` (3:00) / `The West Wayshrine awakens` | `CapturePoints.message` |
| `Blessing of the Wayshrine: +12 % speed, +1.5 HP / s for 60 s` / `The enemy received the Wayshrine's blessing` | `CapturePoints.message` |
| `Stag Glade cleared: +50 essence` (+ ` + Warden Scale dropped`) / `The enemy cleared the Gloomcap Hollow` / `Underdog bonus: +50 % from the Stag Glade` / `The Hollow Stags roam the glades` | `CampManager.message` |
| `An Ironhide Tusker roams the West Heath` / `Old Scarback, an alpha Tusker, roams the West Heath!` / `Your army slew the Grizzlemaw` / `The enemy slew the Grizzlemaw` | `EpicBeasts.message` |
| **Hint** at 0:40 of match time, once: `Stand near a watchtower, well or shrine with soldiers to capture it` | 12.C7 listener; only when `CapturePoints` has points; skipped when the player already holds one |
- **Routing** (12.C7, `mapfill_popups.gd`): connect the three services' `message(text, seconds)` signals to one handler
  (once connected the services stop calling `hud.show_message` themselves) that forwards to `show_message`, **dropping a
  line identical to one shown in the last 20 s** (this gives "point lines max once per 20 s per point": every point line
  carries the point's name).
- Widths: most lines are under 600 px; the hint (est. 690 px) and `A Duskwing Roc, a dark breed, roams the Colossus Crag!`
  (est. 590) sit at y 120 or, when wider than about 636 px, under the help panel by the existing `_message_y` rule. Fine.

---

## 11. Settings: Map detail (12.C7)
- `GameSettings` (`game_settings.gd`): `static var map_detail: StringName = &"high"` (`&"high"` / `&"low"`), saved as
  `map_detail` `"high"` / `"low"` with the others, loaded (unknown text = high), `reset_defaults` sets high, plus
  `static func set_map_detail(v: StringName)` (reads the file first like `set_trade_enabled`, saves). The CritterSystem
  already reads it through `ensure_read()` + `get(&"map_detail")` (handoff 12.V16); MapDressingArt and the water
  material read it at match start.
- `SettingsPanel` (`settings_panel.gd`, main menu and pause menu): a row after the controls hint, before `Back`:
  `HBoxContainer` separation 12: label `Map detail` font 18 min width 190 (as `Controls`) + `OptionButton` font 18
  expanding, items `High` (id 0) and `Low (faster)` (id 1); under it a hint label font 14 `text_muted`: `Applies from the
  next match. Deer and rabbits stay on every setting.` Tooltip on the option: `High: full plants and flowers, birds,
  butterflies and frogs, animated water.\nLow: half the plants, no small animals, simpler water.` The panel grows about
  64 px (still inside 900).
- Nothing changes mid-match (the in-game pause menu changes the saved value only).

## 12. Controls help (`GameHUD.help_text`): a 12th line
`Capture: stand near towers, wells and shrines` (est. 285 px at font 13) appended as the last line. Panel **458 x 248 at
(1126, 16)** (the widest line is still line 10, 438 px). No new keys.

## 13. End screen (`Skirmish.end_screen_text`, systems / lead glue)
Today the code emits one line `Points held at the end 5 / 8 · Camps cleared 9 · Blessings 3 · Game hunted 4` (est. 690
px at font 20: the panel would grow to about 740 px). Emit it as **two lines**, both font 20 `text`, after the trade lines
and before `F9: play again`: `Points held at the end 5 / 8 · Blessings 3` (est. 400 px) and `Camps cleared 9 · Game hunted
4` (est. 310 px). Each part stays conditional on its service as now. The end panel keeps its widest line at the trade
line (576 px); nothing in `hud.gd` changes.

## 14. Audio (12.C7, SFX bus, 2D `AudioStreamPlayer`s kept as children of `mapfill_popups.gd` except the splashes)
| Sound | File (placeholder, generated like the trade ones) | When | Rule |
|---|---|---|---|
| Capture chime | `assets/audio/mapfill_chime.wav` (0.4 s, two rising bell notes) | `point_captured(point, local team)` | `volume_db -6` |
| Distant horn | `mapfill_horn.wav` (1.2 s, one low horn with echo) | `shrine_awakened` | once per 2 s |
| Soft bubble | `mapfill_bubble.wav` (0.3 s) | every 5 s from 2:30 while the local team owns a well that is **on screen** (the service has no tick signal) | at most once per 10 s, `-12` dB |
| Drum | `mapfill_drum.wav` (0.6 s, two low hits) | `camp_cleared` with the spot visible | `-6` dB |
| Stag roar | `mapfill_stag.wav` (1.0 s bellow) | `engaged(camp)` of a `hollow_stag` camp with the spot visible | once per 20 s per camp |
| Beast roar | `mapfill_roar.wav` (1.5 s, low-passed, far away) | `beast_spawned` | `-8` dB |
| Wading splash | `mapfill_splash.wav` (0.25 s) | a visible unit on screen gains `terrain:ford` (edge seen by a 5 Hz scan of the units on screen) | 3 pooled `AudioStreamPlayer3D` at the unit, `-18` dB, `max_distance 60`, at most 3 at once, once per 4 s per unit |
All players `bus = &"SFX"`; "visible" = `FogOfWar.is_visible(local_team, pos)`; the camp / stag sounds also need the spot
within 60 m of the camera focus (no noise from the far corner).

---

## 15. Shared looks and glue

### 15.1 Colours (constants in `UIStyle` or local; never skinned)
| Name | Value | Used for |
|---|---|---|
| `OWN` | `(0.3, 1.0, 0.4)` (= `Minimap.OWN_COLOR`) | Own points (strip, rings, minimap), tile rim, progress |
| `ENEMY` | `(1.0, 0.3, 0.3)` (= `Minimap.ENEMY_COLOR`) | Enemy points, enemy blessing chip |
| `POINT_NEUTRAL` | `(0.62, 0.64, 0.70)` | Neutral points (ring: `(0.85, 0.85, 0.85)` alpha 0.40) |
| Shrine / blessing | `GOLD (1.0, 0.85, 0.4)` | Awake shrine glow, blessing chips |
| `BEAST` | `(1.0, 0.75, 0.2)` | Paws, lairs, boss bar name and border, spawn ping |
| `TIER_1` / `TIER_2` / `TIER_3` | `(0.85, 0.85, 0.75)` / `(1.0, 0.6, 0.25)` / `(1.0, 0.3, 0.25)` | Camp tier word, minimap camps, hover chip |
| `WATER` / `FORD` | `(0.25, 0.45, 0.65)` / `(0.45, 0.62, 0.72)` | Minimap |
| `WADE` | `(0.60, 0.78, 0.88)` | Wading glyph |
| Camp timer | `(0.85, 0.85, 0.80)` | Floating `1:20` |
| `NEAR` / `FAR` / `WARN` | trade / shared | Own action, far bank / contested, enemy action |

### 15.2 Icons for 12.V26 (fallbacks drawn in code work meanwhile; 128 x 128, transparent, no baked border, `ui-style.md` 6.1)
| Path | Used by | Size on screen |
|---|---|---|
| `art/icons/points/watchtower.png`, `well.png`, `shrine.png`, `shrine_asleep.png` | point panel tile | 88 |
| `art/icons/status/blessing.png`, `wading.png` | optional: chips (the code glyphs stay fine at 10-12 px) | 12 |
| `art/icons/units/<creature id>.png` (5), `art/icons/units/<beast type id>.png` (8) | portrait fallback, multi-select | 56 / 40 |
| `art/icons/abilities/<beast ability id>.png` (10) | beast inspect slots | 40 |
| `art/icons/critters/deer.png`, `rabbit.png` | critter card tile | 88 |
| `art/icons/camps/tier_1.png` ... `tier_3.png` | not used by this layout (optional) | - |

### 15.3 Keys
None new (map-fill 8: the Keys line stays). R (bounty) works on own-held points (Guard) and beasts (Hunt) through the
existing bounty mode; Esc clears `selected_neutral` (points, critters) as for posts.

### 15.4 Glue for the lead (nothing in these files belongs to 12.C6 / 12.C7 unless listed)
- `hud.gd` (12.C7): `attach_optional` for `res://scripts/ui/mapfill_bar.gd` `[self, selection]`,
  `res://scripts/ui/point_panel.gd` `[self, selection]`, `res://scripts/vfx/mapfill_popups.gd` `[self]` (own) and
  `res://scripts/vfx/capture_rings.gd` `[self, selection]` (12.C6's; guarded so neither agent blocks the other); the 12th
  help line.
- **Outside 12.C7's file list** (ui-coder owns them; the lead adds them to 12.C7 or does the glue): `command_card.gd` (the
  text blocks of 6.3 / 7.2), `settings_panel.gd` (the Map detail row), `scripts/vfx/mapfill_popups.gd` (new; if the lead
  prefers, its content can live in `mapfill_bar.gd`). **12.C6** gets `scripts/vfx/capture_rings.gd` with the camp memory
  and the floating camp timers (world markers, section 3.1).
- `skirmish.gd` (systems / lead): the two end-screen lines (13); optionally connect nothing to the three services'
  `message` signals (the 12.C7 listener does it).

## 16. For ui-coder: element -> file -> data source
| Element | Task / file | Data source |
|---|---|---|
| Strip icons, order, owner colour, states | 12.C7 `mapfill_bar.gd` | `CapturePoints.points()`; per point `kind`, `display_name`, `owner_team`, `capture_team`, `progress`, `state`, `bank`, `is_contested()`, `is_awake()`, `time_until_awake()`; `CapturePoints.WELL_START`, `match_time()`; `FogOfWar.is_visible(0, pos)` for progress; `selection.selected_neutral` for the selected rim |
| Strip click | 12.C7 | `RTSCamera.focus_on(pos)` |
| Blessing chips | 12.C7 `mapfill_bar.gd` | `CapturePoints.blessing_time_left(0 / 1)`; signals `blessing_started(team, seconds)`, `blessing_ended(team)` for the pop / hide |
| Capture rings | 12.C6 `capture_rings.gd` | same point fields as the strip; `capture_radius`; `owner_changed`, `progress_changed`, `awakened` to refresh at once; fog |
| Camp memory, floating `1:20` | 12.C6 `capture_rings.gd` | `CampManager.camps()`, `camp_cleared(camp, team, reward)`, camp `respawned`, `is_cleared()`, `respawn_left()`, `global_position`; fog |
| Point panel | 12.C7 `point_panel.gd` | `selection.selected_neutral` (group `"capture_points"`), point fields, `time_for(team, 1)`, `sight_radius()`; `CapturePoints.match_time()` / `WELL_START` |
| Point click | 12.C6 `selection_manager.gd` | layer-2 ray + areas; `select_neutral(point)`, `neutral_building_clicked` |
| Camp lines | 12.C7 `selection_panel.gd` | `CampManager.camp_of(u)`, camp `display_name`, `tier`, `camp_level`, `creatures()`, `reward_preview()` `{xp, essence, drop_text, tier, camp_level, creatures}`, `CampManager.underdog_team()` |
| Camp hover chip | 12.C7 `mapfill_bar.gd` | `selection.unit_at(selection.mouse_position())`, `camp_of`, `reward_preview()` |
| Boss bar | 12.C7 `mapfill_bar.gd` | group `"beasts"` (Units: `hp`, `max_hp`, `unit_type.id` / `display_name`, `has_status(&"shroud")`, signal `damage_taken`); meta `&"beast_variant"`; `EpicBeasts.kind_of(beast)`, `NAMES` |
| Beast inspect block | 12.C7 `selection_panel.gd` | `EpicBeasts.lair_of(beast)` (`name`), `variant_of(lair_id)`, `ABILITIES[type id]`, `DROP_TABLES[kind]`; child `"CreatureAbilities"` `cooldown_left(id)`; `ItemType.find(id)` |
| Beast card text | `command_card.gd` | `u.is_in_group(&"beasts")` |
| Spawn roar + ping | 12.C7 (`mapfill_popups.gd`) / 12.C6 (`minimap.ping`-style ring in `BEAST`) | `EpicBeasts.beast_spawned(beast, lair_id, variant)`, `lairs()` centre |
| Minimap water / crossings | 12.C6 `minimap.gd` | `RiverSystem.instance(tree).mask_image()` |
| Minimap points, sight rings | 12.C6 | `CapturePoints.points()`, `held_by(0, &"watchtower")`, `sight_radius()` |
| Minimap camps | 12.C6 | `CampManager.camps()`, `CaptureRings.camp_state(camp)` (group `"capture_rings"`), fog explored |
| Minimap lairs, beasts | 12.C6 | `EpicBeasts.lairs()`, `beast_of(id)`, `beast_spawned` / `beast_slain`; group `"beasts"` + `is_visible_in_tree()` |
| Critter click / right-click / cursor | 12.C6 `selection_manager.gd` | `ClickArea` (layer 2, `collide_with_areas`), `is_game_critter()`, `is_alive()`; hunters = `not is_non_combatant()`, no `command_gather`, not `"caravans"` / `"trackers"`; `show_bounty_ring` |
| Critter card | 12.C7 `point_panel.gd` | `display_name`, `hp`, `max_hp`, `reward`, `kind`, `is_fleeing()`; `CritterHerds.VENISON_HEAL` / `VENISON_AREA_HEAL` |
| Floating `+5` / `+40` / `+1` | 12.C7 `mapfill_popups.gd` | `CritterHerds.critter_hunted(critter, team, reward)` (group `"critter_herds"`); `by` from `GameCritter.hunted(critter, team, by)` when the hunter position is needed |
| Blessing / wading chips | 12.C7 `selection_panel.gd` | `u.has_modifier(&"blessing:wayshrine")`, `u.has_modifier(&"terrain:ford")`, `CapturePoints.blessing_time_left(u.team)` |
| Messages, hint | 12.C7 `mapfill_popups.gd` | `message(text, seconds)` of `CapturePoints`, `CampManager`, `EpicBeasts`; `match_time()` for 0:40 |
| Map detail | 12.C7 `game_settings.gd` (+ `settings_panel.gd`) | `GameSettings.map_detail` |
| Help line | 12.C7 `hud.gd` | static text |
| End-screen lines | systems / lead `skirmish.gd` | `mapfill_stats_of(team)`: `points_held`, `points_total`, `blessings`, `camps_cleared`, `game_hunted` |
| Sounds | 12.C7 `mapfill_popups.gd`, `assets/audio/mapfill_*` | the signals of section 14 |

## 17. Sizes at 1600 x 900 (summary; new things only)
| Thing | Size / position |
|---|---|
| Objectives strip | 300 x 50 at (650, 52) (8 points); icons 28 at x 661 / 693 / 725 / 757 / 802 / 834 / 879 / 911, y 58; separators x 793 / 870 (y 62-82); row 2 y 88-100 (strip 28 x 3 at y 90, timer font 11 at y 87); glyph 18 at (5, 5) |
| Blessing chips | 144 x 22 at (958, 54) / (958, 78); glyph 12, font 12 |
| Boss bar | 456 x 50 at (572, 156), 2nd at (572, 212); paw 14 at (582, 160); name Cinzel 16 at (600, 158); state right edge 1018; bar 440 x 18 at (580, 180) |
| Point panel / critter card | 676 x 204 at (588, 670); tile 96 at (588, 670); title (696, 670); lines y 700 / 722 / 746 / 770 / 806 (critter: bar y 700, lines 730 / 752 / 774 / 806); capture bar 200 x 10 at (860, 727) |
| Camp lines | (696, 752) and (696, 772), font 13; status chips move to y 796 |
| Beast block | drops (696, 752), lair (696, 774), chips (696, 796); abilities 48 at (1000 + 58 j, 676), names y 728 |
| Unit chips | blessing 40 x 20, wading 20 x 20, in the status rows |
| Camp hover chip | mouse + (18, 12), height 26, font 13 |
| Help panel | 458 x 248 at (1126, 16), 12 lines |
| World | capture ring quad `2 (r + 0.6)` m at y 0.20, ring 0.20 m (x 1.8 arc, x 1.5 selected); camp timer `Label3D` font 40 px-size 0.006 at +1.0 m; floats font 40 px-size 0.006, +1.5 m over 1.0 s |
| Minimap | points 5 x 5 (square / circle / diamond) + outline; camps 4 x 4 + 1 px border; lair dashed circle `(r + 3) x 1.833` px + 4 px paw; beast paw 6 x 6; sight ring 40.3 px; water texture from the 240 x 240 mask |

## Done when
- [ ] **12.C6 minimap**: water, fords and bridges from `mask_image()` under the roads and the fog; points in their three
  shapes with owner fills and outlines, awake-shrine pulse, own tower sight rings, camps in tier colours with the
  cleared outline from the camp memory, lairs as dashed circles with the known-alive paw, visible beasts as 6 x 6 paws
  (no neutral square for them); the counters of 9.1; `PERF OK` with the layers on.
- [ ] **12.C6 world and clicks**: one ring per point with the looks of section 3 (arc and flash only where visible); the
  camp memory and the floating `1:20` of 3.1; clicking a point or a critter sets `selected_neutral` and emits
  `neutral_building_clicked`; right-click / A-click on a visible deer with soldiers selected attacks it, while selected
  workers, caravans and trackers never get `command_attack` on it; the cross cursor and red ring over a critter with
  hunters selected.
- [ ] **12.C7 strip and chips**: `MapfillBar` at the rects of section 17 with the 8 icons in map order, owner colours,
  the states of 2.4, shrine / well countdowns, progress strips only where visible, click centres the camera, the 5-line
  tooltip; blessing chips with the running seconds for both teams; hidden without `CapturePoints`.
- [ ] **12.C7 panels**: point panel lines and state texts of 4.2 for a tower, a well before / after 2:30, an asleep and an
  awake shrine, a far-bank point, an enemy capture; critter card with `card_text()` equal to the spec strings; camp rows
  with `camp_line_text()`; the beast inspect block (subtitle, drops text rule, abilities with sweep, lair line) and the
  command card lines; the boss bar (max 2, engaged first, ghost damage, death fade, click centres); blessing and wading
  chips in the three status rows.
- [ ] **12.C7 rest**: floating `+5` / `+40` / `+1` (own, visible); messages routed with the 20 s duplicate filter and the
  0:40 hint; `GameSettings.map_detail` saved / loaded with the settings row; the 12th help line; the sounds of section 14
  on the SFX bus; nothing in `scripts/ui/` calls a `_private` function; every existing UI test still passes.

## Open questions (for the lead)
1. **Boss bar placement**: this spec puts it on screen (top centre, under the message line), which also serves the
   titan and story boss bars later. The alternative, a wider world bar over the beast with its name above, needs a
   `unit.gd` change (gameplay-owned). Keep the screen bar?
2. **End screen**: split the map-fill stats into two lines (section 13) in `skirmish.gd`, like the trade line in step 10?
3. **Ownership**: `command_card.gd` (text blocks), `settings_panel.gd` (Map detail row) and the new
   `scripts/vfx/mapfill_popups.gd` are outside 12.C7's file list, and the camp memory / timers are given to 12.C6's
   `capture_rings.gd`. OK to extend the two tasks' file lists this way?

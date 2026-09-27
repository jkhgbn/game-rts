# UI: champions, taverns and bounties (step 9, task 9.D3)

Written 2026-09-26. Source of truth for **9.C7** (champion bar, inspect view, tavern window, keys Y / F5-F7) and
**9.C8** (bounty mode R, flag card, world flag labels, minimap icons, selection filter, barks, messages). It lays
out every element of `champions.md` section 9 with the skin of `ui-style.md` (tokens, fonts, frames, bars,
tooltips) and moves **nothing** that `ui-hud.md` / `ui-style.md` already place. Gameplay numbers, strings and
contracts come from `champions.md` (sections 3, 6, 9, 13); when this file repeats one it is only so a coder does not
have to look it up. If they ever disagree, `champions.md` wins for gameplay, this file for pixels.

Conventions: pixels from the top-left at **1600 x 900** (virtual pixels, section 2); `(x, y)` = top-left corner,
`w x h`; colours are the `UIStyle` tokens (`title`, `text`, `text_muted`, `frame_metal`, `frame_light`, `frame_dark`,
`groove`, `trim_glow`, `panel_bg`, `panel_inner`, `slate_bg`) or the shared constants `GOLD (1.0, 0.85, 0.4)`,
`WARN (0.95, 0.35, 0.3)`, `HP`, `ESSENCE (0.75, 0.45, 1.0)` / `ESSENCE_TEXT (0.9, 0.8, 1.0)`,
`CRYSTAL (0.45, 0.85, 1.0)` / `CRYSTAL_TEXT (0.75, 0.92, 1.0)`. "Cinzel" = `UIStyle.display_label` (uppercased, the
display font); "font n" = the default body font at size n; "slot frame" = `UIStyle.button_frame` (3.3);
"heavy frame" = `UIStyle.frame_style`; "slate" = `UIStyle.slate_style`; "bar" = `UIStyle.bar` (5.3).
Both coders build their controls in code like the rest of `scripts/ui/` (no `.tscn`).
Step 11 (champion classes: bar badge, inspect title + 6 abilities, tavern class line, prices, tooltips) is the
addendum in **section 15** (task 11.D2, for 11.C4).

---

## 1. Where everything goes

### 1.1 Screen map (existing panels unchanged, new ones in bold)
| Panel | Rect at 1600 x 900 | Anchor | Owner |
|---|---|---|---|
| Objective (skirmish) / mission objectives panel | (16, 16), auto; grows down to about y 210 with 6 rows | top-left | existing |
| Top bar | 500 x 40 at (550, 8) | top-centre | existing |
| Controls help | right edge x 1584, y 16, ~520 x 164 with the new 8th line (section 12) | top-right | existing (`hud.gd`, 9.C7 edits the text) |
| Message line | centred, y 120 (pushed under the help panel when they would touch) | top-centre | existing |
| Mission dialogue box | 640 wide, centred (x 480-1120), bottom edge y 610 | bottom-centre | existing |
| **Champion bar** (3 slots) | **240 x 228 at (16, 408)**: slots 240 x 72 at y 408, 486, 564 | bottom-left | 9.C7 |
| Control group tabs | 64 x 36 from x 272, y 620-656 | bottom | existing |
| Minimap | 240 x 240 at (16, 644); draw area 220 x 220 at (26, 654) | bottom-left | existing (9.C8 adds icons) |
| Selection panel | 1002 x 224 at (272, 660); area content x 588-1264, y 670-874 | bottom | existing (9.C7 adds the **inspect view**) |
| **Flag card** | 676 x 204 at (588, 670), drawn over the selection area | bottom | 9.C8 |
| Command card | 294 x 224 at (1290, 660) | bottom-right | existing (9.C8 adds the flag slots and the champion text) |
| **Tavern window** | **760 x 464 at (420, 156)** (bottom edge y 620 = top of the group tabs) | centre (fixed position like the shop) | 9.C7 |
| Shop window | 640 x 440 at (480, 200) | fixed | existing (never open together with the tavern: opening one closes the other) |
| **Bounty cursor chip** | follows the mouse at mouse + (18, 12) | none | 9.C8 |

### 1.2 Free space measured from the code (why the bar is a left column)
- `hud.gd`: the objective slate is at (16, 16) and auto-sized; `objectives_panel.gd` (missions) sits at the same
  spot and grows with its rows (font 17 / 15, 6 rows are about 190 px tall, bottom near y 210). The minimap
  frame starts at **y 644** (`_anchor_bottom_left(map_panel, 16, 16)`, 240 + 2 x 10 margin) and its drop shadow at
  y 638. So the strip **x 16-256, y 210-636** (426 px) is free. The champion bar takes its bottom 228 px (y 408-636),
  leaving 8 px to the minimap shadow and about 200 px for objectives to grow.
- Bottom centre is full: `dialogue_box.gd` puts the mission dialogue at x 480-1120 with its bottom edge at y 610
  (`BOTTOM_GAP 290`) so it clears the group tabs at y 620-656 (`control_group_bar.gd`). A horizontal bar there
  would collide with one of them, hence the column.
- Top: `top_bar.gd` spans x 550-1050 with essence + timer; the help slate is right-anchored and about 520 px wide
  (its comment says its lines are kept short so it stays right of the top bar). Only one more help line fits.
- The selection area content starts at x 588 (`SelectionPanel`: hero column 300 + divider 3 + margin 3) and ends
  at x 1264, y 670-874: the inspect view and the flag card live there. The command card grid is at (1300, 670).
- The champion bar sits **next to**: the minimap (below it, 8 px), the group tabs and selection panel (right of
  it, 16 px: x 256 vs 272), the objectives (above it, >= 200 px). It never touches the dialogue box, the top bar or
  the help panel. Edge-pan works as it does over the minimap (the bar stops mouse events like every panel).

### 1.3 Full screen (1 character = 16 x 20 px; rows are 20 px)
```
     0         1         2         3         4         5         6         7         8         9
     0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
  0                                    <250   POP 12 / 20   7:42   ~ 140>                                  
  1   +-objective---------+                                            +-controls help (8 lines)----------+
  2   | Destroy the keep  |                                            | Left click / drag: select ...    |
  3   +-------------------+                                            | Right click: move / attack ...   |
  4                                                                    | H: hold  G: gather  B: build ... |
  5                                                                    | W A S D: walk Vessa  F / Q / E...|
  6                    Tamsin Farrow joins you   (message line, y 120) | Groups 1-0: Ctrl set ...         |
  7                                                                    | Arrows / edge: pan ... T: shop   |
  8                                                                    | Space: find Vessa  F9 ...        |
  9                                                                    | R: bounty  Y: tavern  F5-F7 ...  |
 10                                                                    +----------------------------------+
 11
 12                                   (3D battlefield)
 ..
 19
 20   +-champion 1-------+
 21   |[TF] TAMSIN F.  F5|
 22   |[  ] 210 / 302    |
 23   | (3) Hunting  ~85 |
 24   +-champion 2-------+
 25   |[GS] GARRAN S.  F6|                              +-dialogue box (missions), bottom y 610-+
 26   |[  ] 520 / 520    |                              |  Vessa: ...                            |
 27   | (1) Guarding ~50 |                              +----------------------------------------+
 28   +-champion 3-------+
 29   |   +    Hire a    |
 30   |        champion  |
 31   +------------------+ [1 5FG] [2 3EA]                       (group tabs y 620-656)
 32   +-minimap----------+
 33   |  o  .   ..       | +-selection panel----------------------------------------------+ +-command card----+
 34   |    (o) flags     | | (3) VESSA          | [portrait] TAMSIN FARROW · the Wayfinder | | [+25][RM][ ][ ] |
 35   |  o champions     | | HP  350 / 350      | HP  210 / 302        [FA] [SL] [TB]       | | [  ][  ][ ][ ]  |
 36   |     T taverns    | | Mana 100 / 100     | XP  120 / 400                            | | [  ][  ][ ][ ]  |
 ..   |                  | | XP ...             | Level 3 · Damage 13 · Range 8.0 ...      | |                 |
 44   +------------------+ +----------------------------------------------------------------+ +-----------------+
```

---

## 2. Scaling with the UI-size setting
- `GameSettings.ui_scale` (0.75-1.5, `settings_panel.gd` slider "UI scale") is applied as
  `root.content_scale_factor` (`game_settings.gd apply_window`). The project viewport is 1600 x 900
  (`project.godot window/size`), stretch mode default. So every rect in this file is in **virtual pixels**; the
  virtual screen is `window size / ui_scale`, and the whole HUD (existing and new) scales uniformly. Nothing here
  changes size or layout per scale step: **no per-element rules, no compact variants**.
- Anchors decide what stays put: the champion bar is anchored **bottom-left** like the minimap (`offset_top =
  -(900 - 408) = -492`, `offset_bottom = -264`, `offset_left = 16`, `offset_right = 256`), so it keeps its 8 px to
  the minimap whatever the window size. The tavern window keeps a fixed position like the shop (`position = (420,
  156)`); the flag card and inspect view live inside the bottom-anchored selection panel; the cursor chip follows
  the mouse in virtual pixels; the help panel is top-right anchored.
- Overlap-free virtual height is **900 px** (the bar's top at 408 must stay under the objectives, and the bottom
  panels already need 900): keep `ui_scale <= window_height / 900`. At 1600 x 900 that is 1.0; on the user's
  3440 x 1440 screen the maximum 1.5 gives 2293 x 960, still fine. Below 1.0 everything simply shrinks.
- 3D things (`Label3D` barks, flag stake labels, the hunted-coin marker) are world objects: `pixel_size` sets their
  size in metres, the UI scale never touches them.

---

## 3. Champion bar (9.C7, `scripts/ui/champion_bar.gd`, `class_name ChampionBar extends Control`)

### 3.1 Placement and data
- A `Control` 240 x 228 at (16, 408), `mouse_filter IGNORE` on the holder; three **`Button`** slots 240 x 72 at
  y offsets 0, 78, 156 (gap 6), `focus_mode NONE`. Slot k (0-2) = roster slot k of `ChampionGuild.for_team(0)`
  (`champions[k]`, hire order; alive, reviving or fallen all count). Reached untyped: `load("res://scripts/world/champion_guild.gd")`
  guarded by `ResourceLoader.exists`, `get("champions")`, `has_method`; when the script is missing the bar shows three
  empty slots. Refresh at **10 Hz** (`_process` timer 0.1 s) like the command card; HP text every frame is fine.
- Added by `hud.gd` in `_ready` next to the minimap (`champion_bar = ChampionBar.new(); root.add_child(champion_bar)`)
  and wired in `setup` (`champion_bar.setup(selection, rig)`, rig = the `RTSCamera` found as `minimap.setup` does).
  `apply_skin()` re-applies tokens (the HUD calls it on every child that has it).
- Always visible in skirmish and in missions with `tavern_enabled`; hidden (`visible = false`) when the current
  scene has no node in group `"taverns"` 1 s after `setup` (missions 1-2).

### 3.2 One slot (240 x 72; offsets relative to the slot's top-left)
```
 0        8              64  72                                        208      232 240
 +--------------------------------------------------------------------------------------+ 0
 |  +----------------+     TAMSIN FARROW                                  [F5]           | 6
 |  |                |                                                                   |
 |  |   portrait     |     [=========== 210 / 302 =================]                     | 26 (bar 160 x 14)
 |  |   56 x 56      |                                                                   |
 |  |          +-----+     Hunting bounty                              ~ 85             | 46 (font 12)
 |  +----------| (3) |                                                                   |
 +-------------+-----+-------------------------------------------------------------------+ 72
```
| Part | Rect in the slot | Look |
|---|---|---|
| Frame | 0-240 x 0-72 | Slot frame 3.3: normal `frame_metal` rim, hover `frame_light` + halo (fades in 0.08 s), pressed offset (+1, +1) on the content, inside `panel_inner`. The slot is a `Button` with `StyleBoxEmpty` focus; tooltip in 3.4 |
| Portrait | 56 x 56 at (8, 8) | 1 px `groove` border; inside the radial gradient of the portrait (7.2: `trim_glow` alpha 0.35 centre -> `panel_inner`); the champion icon `res://art/icons/units/<champion_id>.png` (6.1; `HudSkin.icon("units", id)`, variant B uses the same file) drawn 52 x 52 at (2, 2), `LINEAR_WITH_MIPMAPS`; fallback: the 2-letter abbreviation (`UIStyle.abbrev(display_name)`, `TF`) Cinzel 18 `title` centred. No `SubViewport` here (three live portraits would cost three viewports; the single-unit portrait shows the model when inspected) |
| Level medallion | 22 x 22 hexagon (flat top) centred at (60, 58), over the portrait's bottom-right corner | As the wizard's badge (5.2) at 22 px: fill `(0.15, 0.12, 0.05)`, 1.5 px `GOLD` edge, `frame_light` facet 1 px on the upper half, number Cinzel Bold 11 `GOLD`; `pivot_offset` centre. Fallen: edge and number `(0.45, 0.42, 0.35)` |
| Name | (72, 6), max width 132 (x 72-204), height 18 | Cinzel 15 `title` (uppercased by `display_label`), `clip_text`, `OVERRUN_TRIM_ELLIPSIS`; `text_muted` when fallen |
| Key badge | 24 x 14 at (208, 7) | Bg `(0, 0, 0, 0.75)`, 1 px `frame_dark`, radius 2, `F5` / `F6` / `F7` font 10 `GOLD` centred |
| HP bar | 160 x 14 at (72, 26) | `UIStyle.bar(HP, 14.0)`; its text label font **10** (number font, outline 2 instead of 3): `210 / 302` (no `HP` prefix). Low HP (< 30 %): fill lerps `HP` <-> `(1.0, 0.45, 0.40)` at 1.5 Hz (5.3). No ghost-damage segment (kept cheap). Shield: white segment as 5.3. Fallen: value 0, text `0 / 302` |
| Intent | (72, 46), max width 100 (x 72-172), font 12 | The intent text in its colour (table 13.1); `clip_text` + ellipsis. Fallen: `Fallen` `text_muted`; reviving: `Returns in 24 s` `WARN` (`ceili(revive_time_left)`); unpaid: `Unpaid!` `(0.6, 0.6, 0.6)` |
| Purse | right-aligned, right edge x 232, y 46, max width 56 | Essence flame 10 x 12 (the top bar's two-tone flame scaled to 10 px) + 4 px + number font 12 embolden `ESSENCE_TEXT`. Shown while fallen too |
| Empty slot | whole slot | Frame at `modulate.a 0.6`; a `+` Cinzel 26 `title` centred in the portrait square (no border on the square); `Hire a champion` font 12 `text_muted` at (72, 18); `Y · tavern` font 11 `GOLD` at (72, 40); before 2:00 that line reads `Tavern opens at 2:00` font 11 `text_muted`. Hover: full alpha + `frame_light` rim |

Text budget: `GARRAN STONEWARD` (16 chars) at Cinzel 15 is about 128 px, fits the 132 px; `Hunting bounty`
(14 chars) at font 12 is about 88 px, fits the 100 px; `Returns in 24 s` fits too.

### 3.3 States and animations (all `Tween` / `_process` sines, none longer than 0.5 s except pulses)
| Event | Look |
|---|---|
| Hired | The slot goes from the empty look to the full one with a `modulate.a` 0 -> 1 fade in 0.2 s; the portrait pops scale 1.0 -> 1.08 -> 1.0 in 0.2 s |
| Level up (`level_changed`) | Medallion scale 1.0 -> 1.4 -> 1.0 in 0.4 s + a gold ring (`draw_arc`, width 3) growing from radius 12 to 30 px while fading over 0.5 s, drawn by the bar (`_draw`) centred on the medallion; the HP bar flashes white 0.2 s |
| Bounty paid / loot (`purse_changed` with a positive delta) | The purse number turns `GOLD` for 0.3 s and a `+100` float font 11 `GOLD` outline 2 rises 12 px from the purse over 0.6 s while fading |
| Damage taken | Nothing (the HP bar just drops); heal: fill flash `(0.5, 1.0, 0.5)` 0.15 s |
| Fallen (`champion_fallen`) | Portrait `modulate (0.55, 0.55, 0.55)` over 0.3 s, medallion greyed, name `text_muted`, intent `Fallen` |
| Revived | Back to normal over 0.3 s; portrait pop as on hire |
| Dismissed | Slot fades to the empty look over 0.3 s |
| Unpaid | Intent `Unpaid!`; the key badge border turns `WARN` while unpaid (a cheap flag the player can spot) |
| Hover | `frame_light` rim + halo (3.3); the portrait border becomes `trim_glow` |

### 3.4 Input and tooltip
- **Click** on a slot with a living champion: `camera_rig.focus_on(champion.global_position)`. **Never** selects it,
  never orders it, never changes `selection` (do not call `select_units`; the inspect view is a separate click in the
  world). Click on a fallen, reviving or empty slot: `TavernWindow.open(slot_index)` (section 5): fallen /
  reviving -> the window highlights that champion's row; empty -> no highlight.
- **F5 / F6 / F7** (physical `KEY_F5`..`KEY_F7`, `_unhandled_key_input`, no modifiers): the same as a click on slot
  1 / 2 / 3 (a living champion centres the camera; else opens the tavern). Handled in `champion_bar.gd`.
  **Y** (physical `KEY_Y`, no modifiers) toggles the tavern window (also in `champion_bar.gd`, next to the HUD's T handler
  pattern).
- **Tooltip** (`tooltip_text`, section-8 custom panel through `_make_custom_tooltip`, 8 px above the slot; for slot 1
  at y 408 it opens upward, clamped on screen), lines:
  1. `Tamsin Farrow  [F5]` + right-aligned `the Wayfinder` (the title, muted; carried after the `]` like `Rank n / m`)
  2. `Level 3 · XP 120 / 400 · HP 210 / 302 · Purse 85` (`XP MAX` at level 6)
  3. Personality line (`champions.md` 4.2), `text_muted`
  4. `Hunting bounty: Gloom Hall (150)` in the intent colour (intent text, `: ` + target name, ` (stake)` for
     bounties; `Fleeing` / `Resting` / `Exploring` alone; `Unpaid: ignores bounties` in `WARN`)
  5. `Items: Swiftsoles, Ember Draught x2` (`Items: none`); the custom tooltip **replaces this line with an icon
     row**: four 28 x 28 slot frames, gap 4, rim = tier colour (6.3), 24 x 24 item icon inset 2 or the abbreviation
     font 11, empty slots rim `(0.3, 0.3, 0.3)`. Tests read the string form.
  Empty slot tooltip: `Hire a champion  [Y]\nOpen the tavern (Y) or click a tavern.\nTavern opens at 2:00`
  (third line only while closed, `text_muted`).

---

## 4. Inspect view (9.C7 in `selection_panel.gd`; the command card text is 9.C8 in `command_card.gd`)
Shown when the player single-clicks a champion in the world (own, or an enemy one that is visible). The selection
manager (9.C8) exposes it as **`selection.inspected: Unit`** (null when nothing is inspected; set only for units
with `is_commandable() == false`; cleared on any other selection change, on Esc, and when the champion is freed;
kept while it is fallen). `selected` stays empty while inspecting. `SelectionPanel.refresh` checks
`selection.get("inspected")` (guarded: the field may not exist yet) **before** the building / units branches and
shows `champion_view`; `current_view()` returns `"champion"`. Views fade in 0.1 s like the others.

```
 588        696                                      1000      1058      1116          1264
 670 +--------+ TAMSIN FARROW · the Wayfinder           +------+  +------+  +------+
     |portrait|                                         |  FA  |  |  SL  |  |  TB  |   676 (48 x 48)
     | 96x96  | [HP  210 / 302 ====================]     |  12  |  |      |  | L4   |
     |        | [XP  120 / 400 ---------------]          +------+  +------+  +------+   724
 766 +--------+ Level 3 · Damage 13 · Range 8.0 · Speed 5.8 · Armor 0    Flare Ar. Snare L.  Trailbl.   728 (font 11)
 786            Hunting bounty: Gloom Hall  ·  Purse ~ 85           Autocast · 3rd ability at level 4   746
 806            [H 7] [S 3]           (status chips)
 826            [Sw][ED][  ][  ]      (4 item slots 36 x 36)
 874
```
| Element | Rect | Look |
|---|---|---|
| Portrait | 96 x 96 at (588, 670) | The existing `Portrait` (7.2): `set_target(champion)` works as for units (`model_scene`, `body_height`); rim normal for own, `DEFEAT` for an enemy (existing team rule); fallen = dimmed (existing dead rule) |
| Name row | (696, 670), height 24 | Cinzel 20 `title` `TAMSIN FARROW` (`display_name`), then ` · the Wayfinder` font 14 `text` (`champion_type.title`), one `HBoxContainer` |
| HP bar | 280 x 22 at (696, 700) | Bar, `HP  210 / 302` (existing string format) |
| XP bar | 280 x 14 at (696, 726) | Bar height 14, fill `GOLD` on bg `(0.2, 0.17, 0.1)` (as the hero XP bar), text font 11 `XP  120 / 400` / `XP  MAX`. Enemy: hidden (the stat line still shows the level) |
| Stat line | (696, 746), font 14 `text` | `Level 3 · Damage 13 · Range 8.0 · Speed 5.8 · Armor 0` (numbers through `get_stat` like the single view; armor always shown for champions) |
| Intent line | (696, 766), font 14 | Intent text in its colour (13.1) + `: ` + target name when there is one, then `  ·  Purse ` `text_muted` + flame 12 px + `85` `ESSENCE_TEXT`. Fallen: `Fallen` / `Returns in 24 s` (`WARN`). Enemy: `Enemy champion` `text_muted`, no intent, no purse |
| Status chips | (696, 786) | The existing status row (`_build_status_row`) plus chips for `taunted` (`T`), `dazed` (`D`), `braced` (`B`), `marked` (`M`) with the colours of `Unit.STATUSES` (`status_color`); add their `STATUS_INFO` lines: `Taunted: attacks the Oathwall only`, `Dazed: can't move or act`, `Braced: takes 30 % less damage`, `Marked: takes 15 % more damage` |
| Items | 4 slots 36 x 36 at (696 + 40 i, 826) | Slot frames as 6.3 (tier rim, halo on top items, 32 px icon or abbreviation, stack count); **read-only**: no click, no drag, no key digit; tooltip = `ItemTooltip.describe(type, "", count)`. Shown for enemies too (they are visible on the model anyway) |
| Abilities | 3 slots 48 x 48 at (1000 + 58 j, 676) | Slot frame; icon `res://art/icons/abilities/<ability_id>.png` (new icon kind `abilities`, 128 x 128 like 6.1) 40 x 40 inset 4, fallback abbreviation font 14 (`FA`, `SL`, `TB`...); own champion: radial cooldown sweep + seconds font 14 (6.2, from `abilities.cooldown_left(id)`; total = the 4.3 cooldown) and the ready flash; locked (3rd ability below level 4): `modulate.a 0.45` + a 20 x 14 `GOLD` badge `L4` at (26, 32) inside the slot (bg `(0, 0, 0, 0.75)`, font 10); enemy: no sweep. Never clickable (`disabled = false` but no action; `mouse_filter STOP` only for the tooltip) |
| Ability names | (1000 + 58 j, 728), width 54, font 11 `text_muted` | `clip_text` + ellipsis (`Flare Arrow` -> `Flare Ar…`) |
| Autocast line | (1000, 746), font 11 `text_muted` | `Autocast · 3rd ability at level 4` (own, below level 4) / `Autocast` (else) |
| Ability tooltip (section 8) | | `Flare Arrow\nCooldown 18 s · Range 20\n<effect at the champion's level>\nAutocast: <when>` + `Unlocks at level 4` (`WARN`) when locked. Effect and "when" texts: section 5.4 |

**Command card while inspecting** (9.C8, `command_card.gd` `_build_slots`: when `selection.inspected != null` and
no building / units are selected): all 12 slots empty (`slot_ids()` all `""`), and the card shows a centred text
block (a `VBoxContainer` over the grid, `mouse_filter IGNORE`): `Champions act on their own.` font 14 `text_muted`
centred at y 740 (panel-relative: y 80) and `Bounty  [R]` font 13 `text` with the key in an inline 18 x 14 gold badge
at y 762. For an enemy champion the second line is `Hunt it with a bounty  [R]`. The block is hidden whenever a slot is
filled.

**Nothing can be ordered**: right-click on a champion never gives an order (own: nothing; enemy: the selected units
attack it as any enemy, that is fine). Box select, double-click, Ctrl/Shift/Alt groups and F2 skip units with
`is_commandable() == false` (9.C8 in `selection_manager.gd`). Clicking a champion while units are selected replaces the
selection with the inspect (like clicking any other single unit).

---

## 5. Tavern window (9.C7, `scripts/ui/tavern_window.gd`, `class_name TavernWindow extends PanelContainer`)

### 5.1 Frame and opening
- **760 x 464 at (420, 156)**, heavy frame (content margin 10 -> inner x 430-1170, y 166-610), drop shadow,
  `mouse_filter STOP`, hidden until opened. `static func attach(hud: Node) -> TavernWindow` like `ShopWindow.attach`
  (adds itself under the HUD, routes `message` to `hud.show_message`); `hud.gd` creates it in `setup` next to the shop.
- `open(highlight_slot := -1)`, `close()`, `toggle()`, `is_open()`. Opens on **Y**, on a tavern click (9.C8's
  selection manager calls `hud.tavern_window.open()` through `get_node`/`has_method`, no static type), on a fallen /
  empty champion-bar slot. Closes on **Y**, **Esc** (`_input`, as the shop), the stud X, or when the match ends.
  Opening it closes the shop window and vice versa. Works from anywhere on the map (no range).
- Data through `ChampionGuild.for_team(0)` (guarded load): `is_open()`, `hire_cost(id)`, `can_hire(id)`,
  `hire(id)`, `can_revive(ch)`, `revive(ch)`, `revive_time_left(ch)`, `dismiss(ch)`, `champions`, signals
  `roster_changed`, `champion_hired`, `champion_fallen`, `champion_revived`. Row order = `ChampionType.all()` order
  (`wayfinder`, `oathwall`, `coin_cutter`, `mender`); if `ChampionType` does not exist yet the window shows four
  rows with the 4.1 names and `Champions not available` in the footer. Refresh at 4 Hz while open.

### 5.2 Layout
```
 430                                                                                               1170
 166 TAVERN                         The tavern opens at 2:00 (WARN, only while closed)   <250   ~140   (x)   194
 198 ---------------------------------------------------------------------------------------- 1 px frame_light
 204 +--------+ TAMSIN FARROW · the Wayfinder          Flare Arrow · 20 dmg, reveals a spot 6 s   <200 ~75
     |portrait| Scout, ranged                          Snare Line · 15 dmg + roots 1.5 s         Pop 2
     | 76x76  | 260 HP · 13 damage · 8.0 range · 5.8 speed   [L4] Trailblaze · haste 5 s, allies 8 m   Not enough crystals
     |        | Goes where the map is blank.                                                     [   Hire   ]
 294 +--------+
 300 +--------+ GARRAN STONEWARD · the Oathwall        Oath of Iron · taunts 3 s, +20 armor      Hired · Level 3
     |        | Guardian, melee                        Shield Bash · 30 dmg + dazes 0.8 s        Guarding: Ember Hall
     |        | 520 HP · 15 damage · 1.8 range · 4.3 speed · 20 armor   [L4] Bulwark Stand · ...  ~ 50
     |        | Would rather stand at your door than walk to theirs.                             [  Dismiss  ]
 390 +--------+
 396 ... (Coin-Cutter row)                                                                        Fallen · Level 2
                                                                                                  [ Revive 120 ]
                                                                                                  [  Dismiss   ]
 492 ... (Mender row)
 588 Upkeep 1 essence / 10 s per champion · Tavern opens at 2:00                                Roster 1 / 3
 606
```
| Part | Rect | Look |
|---|---|---|
| Title bar | 740 x 28 at (430, 166) | `TAVERN` Cinzel 20 `title` left; centre: the closed line `The tavern opens at 2:00` font 14 `WARN` while `not is_open()`, or `Enemies hold both taverns` `WARN` while `can_hire` answers that for every row, else empty; right: crystal diamond 16 px + number font 16 embolden `CRYSTAL_TEXT` (`Economy.crystals`), 12 px gap, essence flame 16 px + number font 16 `ESSENCE_TEXT`, 12 px gap, the stud **X** 24 x 24 (6.4) |
| Rule | 740 x 1 at (430, 198) | `frame_light` |
| Rows | 4 x (740 x 90) at (430, 204 + 96 k), k = 0..3 (gap 6) | Row bg: `panel_inner` at alpha 0.55, radius 3; hover: alpha 0.8; **highlighted row** (opened from a fallen slot): 1 px `GOLD` rim, and it flashes `GOLD` -> normal over 0.5 s on open; row of a hired champion: 1 px `trim_glow` rim alpha 0.6 |
| Footer | (430, 588), 740 x 18 | Left font 12 `text_muted`: `Upkeep 1 essence / 10 s per champion · Tavern opens at 2:00`; right-aligned font 12 `text`: `Roster 1 / 3` (`WARN` at 3 / 3) |

**One row** (offsets from the row's top-left; row = 740 x 90):
| Column | Rect | Content |
|---|---|---|
| Portrait tile | 76 x 76 at (6, 7) | Slot frame (rim: not hired `frame_metal`; hired `trim_glow`; fallen `frame_dark` + content `modulate (0.55, 0.55, 0.55)`), portrait gradient bg, the 128 px champion icon at 68 x 68 inset 4, fallback abbreviation Cinzel 22 `title`. Hired: the level medallion 22 x 22 (3.2) over the tile's bottom-right corner, centred at (74, 78) |
| A: identity, x 92-362 (270 wide) | name at (92, 4) | Cinzel 16 `title` (the name the **player would get**: `names[0]` if no team has hired this archetype, else `names[1]`; hired: the champion's `display_name`) + ` · the Wayfinder` font 13 `text` |
| | role at (92, 26) | font 12 `text_muted`: `Scout, ranged` (`ChampionType.role`) |
| | stats at (92, 44) | font 12 `text`: `260 HP · 13 damage · 8.0 range · 5.8 speed` + ` · 20 armor` only when armor > 0 (level-1 numbers from the type; hired: the champion's current `max_hp` / damage) |
| | personality at (92, 64) | font 12 in `title` at alpha 0.85: the personality line (4.2) |
| B: abilities, x 372-622 (250 wide) | three labels at (372, 8), (372, 32), (372, 56), height 16 | font 12: name in `text` + ` · ` + short effect in `text_muted` (table 5.4, <= 38 chars); the third line starts with a 20 x 14 badge `L4` (bg `(0, 0, 0, 0.75)`, font 10 `GOLD`) then 4 px then the text. Hired at level >= 4: the badge becomes a filled gold badge with black `L4`. Each label has `mouse_filter STOP` and the full tooltip (5.4) |
| C: price / status, x 626-734 (108 wide) | see states below | Buttons are 104 x 24 at x 628, font 13; `Hire` and `Revive` use the primary style (6.4: `trim_glow` rim, tinted inside), `Dismiss` the normal slot frame with a `WARN` rim on hover |

Row states (column C):
| State | Lines and buttons |
|---|---|
| Not hired, hireable | (628, 4): crystal diamond 10 px + `250` font 12 embolden `CRYSTAL_TEXT`, 8 px, essence flame 10 px + `100` `ESSENCE_TEXT` (the n-th price, `hire_cost(id)`); (628, 22): `Pop 2` font 11 `text_muted`; (628, 62): **`Hire`** 104 x 24 primary |
| Not hired, refused | Same, plus the reason from `can_hire(id)` font 11 `WARN` at (628, 36), `autowrap`, max 2 lines (`Population cap reached` wraps); the button disabled (3.3 disabled, `modulate.a 0.45`, tooltip = `Hire  [Y]\n250 crystals · 100 essence · 2 pop\n<reason>`). Price numbers turn `WARN` individually when that resource is short |
| Hired, alive | (628, 4): `Hired · Level 3` font 12 `title`; (628, 22): intent text in its colour font 11 (with `: target` when it fits, ellipsis); (628, 40): flame 10 px + purse `85` font 11 `ESSENCE_TEXT`; (628, 62): **`Dismiss`** 104 x 24. First click: the button reads `Confirm?` with a `WARN` rim for 3 s (`champions.md` 3.3: click twice within 3 s); second click calls `dismiss(ch)`; tooltip `Dismiss\nThe team gets 50 % of its purse and 50 % of its items' value.` |
| Hired, fallen | (628, 4): `Fallen · Level 2` font 12 `WARN`; (628, 34): **`Revive 120`** 104 x 24 primary (`60 + 30 x level`; disabled with `Not enough essence` in the tooltip and the number in `WARN`; the button label keeps the number); (628, 62): **`Dismiss`** 104 x 24 (same 2-click rule) |
| Hired, reviving | (628, 4): `Fallen · Level 2` `WARN`; (628, 34): `Returns in 24 s` font 12 `WARN` (no Revive button); (628, 62): `Dismiss` |
| Tavern closed | Every not-hired row shows the price, `Tavern closed` in `WARN` and the disabled `Hire` |

Hire feedback: on `hire(id) == ""` the row flashes `GOLD` 0.3 s, the window stays open; the message
`Tamsin Farrow joins you` comes from the guild (`champions.md` 3.1). A refusal string returned by `hire` / `revive` is
shown through `message` (the HUD line) and as the row's reason.

### 5.3 Mock of a hired row (Oathwall, level 3, guarding)
```
 +--------+ GARRAN STONEWARD · the Oathwall        Oath of Iron · taunts 3 s, +20 armor      Hired · Level 3
 |  (GS)  | Guardian, melee                        Shield Bash · 30 dmg + dazes 0.8 s        Guarding: Ember Hall
 |     (3)| 645 HP · 18.6 damage · 1.8 range · 4.3 speed · 20 armor   [L4] Bulwark Stand · braces allies 6 s   ~ 50
 +--------+ Would rather stand at your door than walk to theirs.                             [   Dismiss   ]
```

### 5.4 Ability texts (used by the tavern lines, the inspect tooltips and the bar tooltip)
| id | Short line (tavern, <= 38 chars) | Tooltip line 2 | Tooltip line 3 (effect, `{n}` = the level-scaled number) | Tooltip line 4 (`Autocast: ...`) |
|---|---|---|---|---|
| `flare_arrow` | `Flare Arrow · 20 dmg, reveals a spot 6 s` | `Cooldown 18 s · Range 20` | `Arrow to a point: {20} damage in radius 2; the point stays visible 6 s (radius 8).` | `while exploring: ahead on its path; in a fight: where an enemy just vanished` |
| `snare_line` | `Snare Line · 15 dmg + roots 1.5 s` | `Cooldown 14 s · Range 8` | `{15} damage and roots one enemy for 1.5 s.` | `when fleeing from a chaser, or when its hunt target runs` |
| `trailblaze` | `Trailblaze · haste 5 s, allies 8 m` | `Cooldown 30 s · Self, radius 8` | `Itself and own soldiers within 8 m get Haste for 5 s.` | `when fleeing, or walking more than 25 m to a flag` |
| `oath_of_iron` | `Oath of Iron · taunts 3 s, +20 armor` | `Cooldown 16 s · Self, radius 6` | `Enemies within 6 m must attack it for 3 s; it gains 20 armor for 3 s.` | `when 2+ enemies hit an ally, or 3+ target it` |
| `shield_bash` | `Shield Bash · 30 dmg + dazes 0.8 s` | `Cooldown 10 s · Range 2.2` | `{30} damage and dazes the target 0.8 s (no move, no act).` | `on its target; prefers one hitting your building or wizard` |
| `bulwark_stand` | `Bulwark Stand · braces allies 6 s` | `Cooldown 40 s · Self, radius 5` | `Plants its shield 6 s: it cannot move; allies within 5 m take 30 % less damage.` | `when 3+ enemies are near while guarding or near a building` |
| `cutpurse` | `Cutpurse · next hit +25 dmg, +15 purse` | `Cooldown 8 s · Melee` | `Its next attack deals {25} extra damage; a kill adds 15 to its purse.` | `on a target below 50 % HP or a worker` |
| `smoke_pouch` | `Smoke Pouch · shroud 3 s, drops targets` | `Cooldown 25 s · Self, radius 3` | `Shroud 3 s (half damage, faster); enemies within 6 m lose it as a target.` | `when hurt near its flee point, or when 3+ enemies target it` |
| `marked_for_coin` | `Marked for Coin · +15 % damage taken` | `Cooldown 20 s · Range 8` | `Marks one enemy 6 s: it takes 15 % more damage from everything.` | `on its hunt or raid target` |
| `mending_draught` | `Mending Draught · heals 50` | `Cooldown 7 s · Range 9` | `Heals the most hurt ally within 9 m by {50}.` | `when an ally within 9 m is below 70 % HP` |
| `soothing_circle` | `Soothing Circle · 6 HP / s for 5 s` | `Cooldown 24 s · Range 9, radius 5` | `A circle that heals allies inside by {6} HP / s for 5 s.` | `when 3+ allies stand together below 80 % HP` |
| `lifeline` | `Lifeline · 100 shield 5 s` | `Cooldown 35 s · Range 9` | `A {100} shield for 5 s on one ally.` | `when the wizard or a champion is below 35 % HP` |
Tooltip line 1 is the name (`Flare Arrow`, no key badge; `Locked` in `WARN` after it when the champion is below
level 4, like `Not learned`); line 5 `Unlocks at level 4` in `WARN` for the third ability while locked.

---

## 6. Bounty mode (9.C8, `scripts/ui/bounty_mode.gd`, `class_name BountyMode extends Control`)
### 6.1 Entering, leaving, clicking
- **R** (physical `KEY_R`, no modifiers) enters the mode (also the `Bounty [R]` hint has no button: the mode is
  key-only). Refused at once with the message `No champions` when the roster is empty (`BountyBoard.place` would say
  so; check first so the cursor never appears) and `Too many bounties` at 5 flags.
- In the mode: hardware cursor `Input.CURSOR_CROSS` (as targeted orders), every other pending order is cancelled,
  the command card shows nothing new. **Left-click** places at the minimum stake and leaves the mode;
  **Shift+left-click** places and stays; **right-click / Esc** leave the mode (cursor back to `CURSOR_ARROW`).
  Clicks on HUD panels do nothing (the panels stop the event as usual). Minimap clicks in the mode: an Explore flag at
  that map point (like a targeted order on the minimap).
- What is under the cursor decides the kind (`BountyBoard.kind_for(target)`): a visible enemy / neutral unit,
  champion, wizard or enemy building (ghost included) = **Hunt**; an own completed building = **Guard**; an own living
  unit = **Escort**; ground = **Explore**. Hovering something that already carries **your** flag = **Raise** (+25).
  Own champions are not targets (hovering one = the ground under it).
- **World highlight**: the selection manager's target ring (the orange spell ring, `_target_ring`; 9.C8 owns the
  file, add a public `show_bounty_ring(pos: Vector3, radius: float, color: Color)` / `hide_bounty_ring()`) shown in
  `(1.0, 0.85, 0.3, 0.8)` under the hovered target (radius = its `target_radius()` + 0.3) or at the ground point
  (radius 1.0 m for Explore). Refused targets: the ring in `WARN` at alpha 0.6.

### 6.2 The cursor chip (a `PanelContainer` following the mouse; `mouse_filter IGNORE`, `z_index 10`)
```
 mouse
   +--------------------------------+
   | |>  Hunt · 75 essence          |    height 26, slate, 1 px frame_metal border
   +--------------------------------+
```
- Position: `mouse + (18, 12)`, clamped to the screen with a 4 px margin (flip to `mouse + (-w - 6, 12)` at the right
  edge, as `ItemTooltip` clamps). Updated every frame while in the mode; hidden otherwise.
- Style: `UIStyle.slate_style(4.0, frame_metal)` (bg `slate_bg` at alpha 0.94 like tooltips), content margin 6 left /
  right, 4 top / bottom, radius 2. Height 26.
- Content, one `HBoxContainer` gap 6: the **flag glyph** 20 x 20 (`Control` `_draw`: pole 2 px `frame_dark` from
  (5, 2) to (5, 18); pennant triangle (7, 3) (17, 7) (7, 11) in the **player's team colour** (`Unit.team_color(PLAYER)`);
  coin `draw_circle` radius 5 at (13, 14) `GOLD`-coin `(1.0, 0.85, 0.3)` with a 1 px `(0.55, 0.42, 0.1)` ring and the
  **kind icon** (13.2) at 6 px in `(0.35, 0.25, 0.05)`), then the text font 13: the kind word in its **kind colour**
  (13.2) + ` · 75 essence` in `text`.
- Texts: `Hunt · 75 essence`, `Explore · 25 essence`, `Guard · 50 essence`, `Escort · 50 essence`;
  raise: `Raise +25 · Hunt 150 -> 175` (kind word in its colour; `Shift: +100` is in the flag card, not here);
  refusal: kind word + ` · ` + the reason in `WARN` (`Hunt · Not enough essence`, `Guard · Invalid target` for a site,
  `Explore · Invalid target` off the map, `Raise · Max bounty`). `Invalid target` also when the Hunt target is not
  visible (a fogged ghost is valid: it is an explored enemy building).
- On a successful click: the chip flashes `GOLD` (text) 0.2 s; the flag appears in the world (9.C4 / 9.V6) with its
  stake label (section 8). Refused click: the chip shakes +-3 px 0.2 s and `show_message(reason)`.

---

## 7. Flag card (9.C8, `scripts/ui/flag_card.gd`, `class_name FlagCard extends Control`)
A flag is selected by clicking it in the world (layer 2, group `"bounties"`; the selection manager sets
**`selection.selected_bounty: Node`**, clears `selected`, `selected_building` and `inspected`; any other click
clears it; Esc clears it). Own flags always, enemy flags only while visible. The card is a `Control` **676 x 204 at
(588, 670)** (anchored bottom like the selection panel: `offset_top = -230`, `offset_bottom = -26`, `offset_left =
588`, `offset_right = 1264`), added by `static func attach(hud: Node) -> FlagCard` (lead glue in `hud.gd`), visible
only while `selection.selected_bounty != null`; it paints `panel_bg` (opaque, alpha 1) over the selection area so
the `Nothing selected` text under it does not show. Refresh at 4 Hz + on `bounty_paid` / `bounty_ended`.

```
 588        696                                                                           1264
 670 +--------+ HUNT BOUNTY
     |  flag  |
     | glyph  | Target: Gloom Hall                                    700
     | 96x96  | (o) 150   ·  Paid 0                                   722
 766 +--------+ Until the target dies                                 746
                Pursuers  [SQ] [TF]                                   770  (chips 28 x 28)
                Z: raise +25  ·  Shift+Z: +100  ·  Delete: remove    806  (font 12 muted)
```
| Element | Rect | Look |
|---|---|---|
| Tile | 96 x 96 at (588, 670) | Slot frame (normal rim; enemy flag: `DEFEAT` rim), portrait gradient bg; the flag glyph at 4x the chip's: pole 3 px `frame_dark` from (30, 14) to (30, 84); pennant (34, 16) (74, 27) (34, 40) in the flag's team colour; coin radius 20 centred (60, 60), `(1.0, 0.85, 0.3)` with a 2 px `(0.55, 0.42, 0.1)` ring; kind icon 20 px `(0.35, 0.25, 0.05)` |
| Title | (696, 670) | Cinzel 20 `title`: `HUNT BOUNTY` / `EXPLORE BOUNTY` / `GUARD BOUNTY` / `ESCORT BOUNTY`; enemy: `ENEMY HUNT BOUNTY` etc. |
| Target line | (696, 700), font 14 | `Target: ` `text_muted` + name `text` (`Gloom Hall`, `Vessa`, `Shade`); Explore: `Point: unexplored ground` / `Point: explored ground` (fog state at the point); Guard: `Guarding: Ember Hall`; Escort: `Escorting: Flame Guard` (`Vessa`) |
| Stake line | (696, 722) | Coin 14 px (glyph coin only) + 6 px + stake font 18 embolden `GOLD` (`150`), then font 13 `text_muted`: `  ·  Paid 50` (`paid`); at 500: ` · max` |
| Time line | (696, 746), font 13 | Guard / Escort: `Time left 1:30` `text` (`time_left()`, `WARN` under 10 s); Hunt with the target unseen: `Target lost · refund in 42 s` `WARN`; Hunt: `Until the target dies` `text_muted`; Explore: `Until a champion reaches it` `text_muted` |
| Pursuers | label at (696, 770) font 13 `text_muted` `Pursuers`; chips 28 x 28 at (770 + 32 i, 766), i < 3 | Slot frame normal rim, the champion's icon 24 x 24 inset 2 or abbreviation font 11 `title`; tooltip `Sable Quint · Hunting bounty`; none: `none yet` `text_muted` at (770, 770). Enemy flag: the row is hidden |
| Hint | (696, 806), font 12 `text_muted` | `Z: raise +25  ·  Shift+Z: +100  ·  Delete: remove`; enemy flag: `An enemy bounty: kill or protect its target.` |
| Enemy flag | | Title with `ENEMY`, target and stake shown, no paid / pursuers / hint, no command card buttons |

**Command card with a flag selected** (9.C8, `command_card.gd`; `selection.selected_bounty != null` takes priority
over the champion text):
| Slot | id | Abbr / key | Tooltip | Disabled reason |
|---|---|---|---|---|
| r1c1 | `raise` | `+25`, key `Z` | `Raise +25  [Z]\nStake 150 -> 175 (max 500)\nShift+Z: +100` | `Max bounty` at 500, `Not enough essence` |
| r1c2 | `remove` | `RM`, key `Del` (font 10 as `Esc`) | `Remove  [Delete]\nRefund 150 (100 %): nobody pursues it.` / `Remove  [Delete]\nRefund 75 (50 %) · 75 to the 2 pursuers` | none |
Keys: **Z** raises +25, **Shift+Z** +100, **Delete** removes, only while a flag is selected (then Z is not a training
slot and Delete is not "cancel a site": nothing else is selected). The remove tooltip's numbers come from
`BountyBoard` (the unpaid part and `pursuers.size()`); the raise cost is `25` / `100` essence.
After a raise the stake number on the card pops scale 1.0 -> 1.3 -> 1.0 in 0.2 s and turns `GOLD` -> white -> `GOLD`.
After a remove the card closes (the flag is freed).

---

## 8. World labels (9.C8, all in `scripts/vfx/champion_barks.gd`: it scans group `"bounties"` at 2 Hz and adds a `Label3D` child named `StakeLabel` to any flag that lacks one; `bounty.gd` belongs to 9.C4 and is not touched)
| Thing | Spec |
|---|---|
| Flag stake label | A `Label3D` child of each `Bounty` node (added by the barks node): `text = str(stake)`, `font_size 40`, `pixel_size 0.006` (0.24 m tall), `modulate (1.0, 0.85, 0.3)` (coin gold), `outline_modulate` black, `outline_size 8`, `billboard ENABLED`, `no_depth_test true`, `cast_shadow OFF`, `position.y = 2.3` (the 9.V6 pole is 1.6 m + the spinning coin; the label floats just above). Updated on `raise`. Own flags always; enemy flags are hidden with the flag node by the fog (`visible`), nothing to do. Guard / Escort: the text is `150 · 1:20` (stake + `time_left` as m:ss) refreshed each second. Hunt with the target lost: `150 · 42 s` in `WARN` |
| Hunted-coin marker | For the **owner** of a hunted thing (always) and for the hunter's team (while the thing is visible): a billboard `QuadMesh` 0.3 x 0.3 m, unshaded, no depth test, texture generated once in code (24 x 24 image: a gold `(1.0, 0.85, 0.3)` disc radius 11 with a 2 px `(0.55, 0.42, 0.1)` ring, transparent corners), at `body_height + 0.9` for units (above the HP bar at `body_height + 0.5`, under the bark) and `height + 1.0` for buildings; bobs +-0.05 m at 1 Hz. Two flags on the same target = one marker. Removed when the bounty ends. Read `BountyBoard.hunts_on(team)` at 2 Hz |
| Champion HP bar | 9.C10 frames it in gold; nothing for the UI coders |

---

## 9. Minimap icons (9.C8, `minimap.gd`; colours of `ui-hud.md` / `fog-of-war.md` unchanged)
| Icon | Draw | When | Pass |
|---|---|---|---|
| Tavern | 6 x 6 square `(1.0, 0.75, 0.35)` filled + 1 px `groove` outline (`draw_rect` unfilled at the same rect) | nodes in group `"taverns"` with fog state >= explored (both are explored from 0:00: in practice always) | with the buildings, before units |
| Own champion | `draw_circle` radius 2.5 `OWN_COLOR (0.3, 1.0, 0.4)` + `draw_arc` radius 3, 1 px `GOLD` | group `"champions"`, `team == PLAYER`, alive (fallen: not drawn) | after the units, before the heroes |
| Enemy champion | radius 2.5 `ENEMY_COLOR (1.0, 0.3, 0.3)` + 1 px `GOLD` ring | `is_visible_in_tree()` (the fog hides it) | same pass |
| Bounty flag | `draw_circle` radius 2 `(1.0, 0.85, 0.3)` + `draw_arc` radius 2.5, 1 px in the flag's team colour (`PLAYER_TEAM_COLOR` / `ENEMY_TEAM_COLOR`); the selected flag: radius 3 + a 1 px `GOLD` ring at 4 | group `"bounties"`; own always; enemy only while `is_visible_in_tree()` | after the units, before champions |
| Hunt warning ping | when the player receives `A bounty of ... is on ...`: 3 expanding `WARN` rings 0.9 s at the hunted thing (the same look as the optional under-attack ping of 7.1) | once per warning message | overlay |
Test counters: add `drawn_champions`, `drawn_flags`, `drawn_taverns` (ints, like `drawn_ghosts`).

---

## 10. Barks (9.C8, `scripts/vfx/champion_barks.gd`, one node in the level or an autoload-free singleton in group `"champion_barks"`)
- Trigger: `Champion` emits (or the brain calls) `bark(situation)` (`champions.md` 4.5); the barks node listens to
  every champion in group `"champions"` (connect on `roster_changed` / a 1 Hz scan) and creates the label. One label
  per champion at a time (a new bark replaces the old one); max one per champion per 20 s is enforced by gameplay.
- Only when the champion is visible to the local team (`is_visible_in_tree()`), both teams' champions.
- `Label3D`: `font_size 32`, `pixel_size 0.006` (0.19 m tall), white `(1, 1, 1)`, `outline_modulate` black,
  `outline_size 2` (the spec's 2 px; note the chevrons use 8 at font 48: 2 keeps the text light), `billboard ENABLED`,
  `no_depth_test true`, `cast_shadow OFF`, `autowrap_mode WORD_SMART`, `width 560` px (= 3.4 m; the longest bark, 59
  chars, wraps to 2 lines), `horizontal_alignment CENTER`, `vertical_alignment BOTTOM` so a 2-line bark grows upward.
  Position `y = body_height + 1.1` (0.6 m above the HP bar at `body_height + 0.5`; above the hunted coin at + 0.9;
  the Wayfinder's lantern pole tops at 2.6 m and its bark sits at 2.9 m).
- Life: 3 s; `modulate.a` fades 1 -> 0 over the last 0.5 s; freed after. Pops in with scale 0.8 -> 1.0 over 0.1 s.
- Also the HUD line? No: barks never go through `show_message` (that line is for events).

---

## 11. Messages (`GameHUD.show_message(text, seconds)`, gold font 22, outline 3, y 120)
| Message | Seconds | Emitted by |
|---|---|---|
| `Tamsin Farrow joins you` / `Malrik hired Tobin Farrow` (enemy door visible) | 3.0 | guild (9.C3) through the HUD's `show_message` found on the level's `hud` |
| `Garran Stoneward has fallen` / `... returns in 30 s` / `... leaves your service` | 3.0 | guild |
| `The taverns open their doors` then, 3 s later and once per match, `Y: hire champions` | 3.0 each | tavern (9.C3) + 9.C7 for the hint |
| `Your champions are unpaid: they ignore bounties` | 4.0 | guild |
| `Sable Quint took your bounty on the Gloom Hall` | 2.0 | board (9.C4) |
| `Bounty paid: 100 to Sable Quint` / `Bounty refunded: 75` | 2.0 | board |
| `A bounty of 150 is on Vessa!` / `... on your Ember Hall!` | 4.0 (+ the minimap ping, section 9) | board |
| `Tithe from Sable Quint: 40` (summed, at most once per 10 s) | 2.0 | inventory (9.C6) |
| Refusals of place / raise / remove / hire / revive (`Not enough essence`, `Max bounty`, `Too many bounties`...) | 2.0 | the UI that asked (9.C7 / 9.C8) |
The gameplay agents call `show_message` on the level's HUD (`get_tree().current_scene.get("hud")`, `has_method`);
the UI coders only add their own refusals. Two messages in a row replace each other (single line): the callers above
are spaced by gameplay, the hint after the opening is delayed 3 s on purpose.

---

## 12. Controls help (9.C7 edits `GameHUD.help_text`): add an 8th line, nothing else changes
```
R: bounty (Shift+click: stay)    Y: tavern    F5-F7: find champion    Flag: Z raise · Delete remove
```
Font 13 `text_muted` like the others, about 470 px wide (shorter than line 3, so the panel keeps clearing the top
bar at x 1050). The panel grows from 7 to 8 lines (about 164 px tall); `_message_y` already moves long messages under it.

---

## 13. Shared looks (both coders)
### 13.1 Intent colours (`champions.md` section 9; used by the bar, the inspect view, the tavern rows, chips)
| Intent id / text | Colour |
|---|---|
| `Fighting` | `(1.0, 0.55, 0.2)` |
| `Fleeing` | `(0.95, 0.35, 0.3)` |
| `Resting` | `(0.4, 0.9, 0.4)` |
| `Hunting bounty` | `(1.0, 0.85, 0.4)` |
| `Exploring`, `Scouting bounty` | `(0.45, 0.85, 1.0)` |
| `Guarding`, `Escorting` | `(0.6, 0.75, 1.0)` |
| `Shopping` | `(0.75, 0.45, 1.0)` |
| `Unpaid!` | `(0.6, 0.6, 0.6)` |
| `Fallen`, `Returns in n s` | `text_muted` / `WARN` (see 3.2) |
| everything else (`Patrolling`, `Raiding`, `With the army`, `Idle`) | white `(1, 1, 1)` |
Intent text = `String(champion.intent).capitalize()` unless the id already carries the display text; the coders key
the table by the ids of `champions.md` 8.1 (`fighting`, `fleeing`, `resting`, `hunting_bounty`, `scouting_bounty`,
`guarding`, `escorting`, `shopping`, `unpaid`, `exploring`, `patrolling`, `raiding`, `with_the_army`, `idle`,
`fallen`, `reviving`) and fall back to `capitalize()` + white for unknown ids.

### 13.2 Bounty kinds: colours and icons (chip, flag card, minimap, tooltips)
| Kind | Word colour | Icon (drawn in code inside a coin of radius r, centre c, colour `(0.35, 0.25, 0.05)` on gold; line width `max(1, r / 4)`) |
|---|---|---|
| Hunt | `(1.0, 0.85, 0.4)` (Hunting) | Crossed blades: two lines `c + (-0.55 r, -0.55 r)` -> `c + (0.55 r, 0.55 r)` and `c + (-0.55 r, 0.55 r)` -> `c + (0.55 r, -0.55 r)` |
| Explore | `(0.45, 0.85, 1.0)` (Scouting) | Eye: a 16-point ellipse outline rx 0.65 r, ry 0.4 r, plus a filled pupil circle radius 0.18 r |
| Guard | `(0.6, 0.75, 1.0)` (Guarding) | Shield outline: `(-0.5 r, -0.55 r)`, `(0.5 r, -0.55 r)`, `(0.5 r, 0.05 r)`, `(0, 0.6 r)`, `(-0.5 r, 0.05 r)` |
| Escort | `(0.6, 0.75, 1.0)` (Escorting) | Linked rings: two circle outlines radius 0.32 r centred at `c + (-0.2 r, 0)` and `c + (0.2 r, 0)` |
The 3D flag (9.V6) carries the same four icons; the 2D ones only have to read at 6-20 px.

### 13.3 Keys and who handles them
| Key | Where | Note |
|---|---|---|
| Y | `champion_bar.gd` (9.C7) | toggle the tavern window; also closes the shop |
| F5 / F6 / F7 | `champion_bar.gd` (9.C7) | centre on champion 1-3, else open the tavern |
| R | `bounty_mode.gd` (9.C8) | bounty mode; Shift+click stays; right-click / Esc cancel |
| Z / Shift+Z / Delete | `selection_manager.gd` (9.C8) | only while `selected_bounty != null` |
All physical keycodes, no modifiers unless written, `get_viewport().set_input_as_handled()` after use, ignored while
the shop / tavern / pause menu / briefing has focus (`visible`), like the T handler in `hud.gd`.

### 13.4 Glue for the lead (nothing in these files belongs to 9.C7 / 9.C8 unless listed)
- `hud.gd` (9.C7 owns it): creates `ChampionBar`, `TavernWindow.attach(self)`, `FlagCard.attach(self)` (the class of
  9.C8, reached by `load("res://scripts/ui/flag_card.gd")` guarded, so the two agents never block each other), and the
  `BountyMode` chip (`load("res://scripts/ui/bounty_mode.gd")` guarded). If 9.C7 cannot see those files when it works,
  it leaves the two guarded loads in place and the lead confirms them after both land.
- `selection_manager.gd` (9.C8): `inspected`, `selected_bounty`, the commandable filter, the bounty ring helper,
  `open the tavern on a tavern click` through `hud.get("tavern_window")` + `has_method("open")`.
- `command_card.gd` (9.C8): the flag slots and the champion text block.
- `selection_panel.gd` (9.C7): the champion view; it reads `selection.get("inspected")` guarded.
- `minimap.gd` (9.C8): the four icons. `champion_barks.gd` (9.C8): barks + the hunted-coin marker; the lead adds the node
  to `skirmish.tscn` / the mission scenes (or the barks node adds itself from `Skirmish._ready` through a guarded load).
- Icons for the tech-artist (later, fallbacks work meanwhile): `art/icons/units/<champion_id>.png` (4) and
  `art/icons/abilities/<ability_id>.png` (12), 128 x 128 as `ui-style.md` 6.1.

---

## 14. Sizes at 1600 x 900 (summary; new things only)
| Thing | Size / position |
|---|---|
| Champion bar | 240 x 228 at (16, 408); slots 240 x 72 at y 408 / 486 / 564; anchored bottom-left |
| Slot parts | portrait 56 at (8, 8); medallion 22 centred (60, 58); name Cinzel 15 at (72, 6) w 132; key badge 24 x 14 at (208, 7); HP bar 160 x 14 at (72, 26); intent font 12 at (72, 46) w 100; purse right edge 232, y 46 |
| Inspect view | portrait 96 at (588, 670); name (696, 670); HP 280 x 22 at (696, 700); XP 280 x 14 at (696, 726); stats (696, 746); intent + purse (696, 766); chips (696, 786); items 36 at (696 + 40 i, 826); abilities 48 at (1000 + 58 j, 676), names y 728, autocast line (1000, 746) |
| Command card texts | `Champions act on their own.` y 740, `Bounty  [R]` y 762, centred in x 1290-1584; flag slots r1c1 raise, r1c2 remove |
| Tavern window | 760 x 464 at (420, 156); title bar 740 x 28 at (430, 166); rule y 198; rows 740 x 90 at (430, 204 + 96 k); footer (430, 588) |
| Tavern row | portrait 76 at (6, 7); col A x 92-362 (y 4 / 26 / 44 / 64); col B x 372-622 (y 8 / 32 / 56); col C x 626-734, buttons 104 x 24 at x 628 (y 62; fallen: 34 and 62) |
| Bounty chip | mouse + (18, 12), height 26, slate margin 6 / 4, glyph 20 x 20, text font 13 |
| Flag card | 676 x 204 at (588, 670); tile 96 at (588, 670); title (696, 670); lines y 700 / 722 / 746 / 770 / 806; pursuer chips 28 at (770 + 32 i, 766) |
| World | stake `Label3D` font 40 px-size 0.006 at y 2.3; hunted coin 0.3 m at body_height + 0.9; bark font 32 px-size 0.006 width 560 at body_height + 1.1 |
| Minimap | tavern 6 x 6; champion circle r 2.5 + gold ring r 3; flag coin r 2 + team ring r 2.5 (selected r 3 + gold r 4) |
| Help text | 8th line, panel about 520 x 164 |

## Done when
- [ ] 9.C7 bar: three 240 x 72 slots at (16, 408 / 486 / 564) with the parts of 3.2 at those offsets; intent text in
  the 13.1 colour; fallen / reviving / empty looks; click centres the camera and `selection.selected` stays empty;
  F5-F7 and Y work; the tooltip string has the 5 lines of 3.4; a test at 1600 x 900 reads the rects.
- [ ] 9.C7 inspect: `current_view() == "champion"` with the rects of section 4, XP bar, 4 read-only item slots, 3 ability
  slots with sweep / `L4` badge, enemy variant without intent / purse / XP.
- [ ] 9.C7 tavern: 760 x 464 at (420, 156), 4 rows of 90 px with columns A / B / C, the five row states, the closed
  line, the footer, Esc / Y / X close, opening from a fallen slot highlights the row, the shop and the tavern never
  open together.
- [ ] 9.C8 bounty mode: chip texts of 6.2 for the 4 kinds, raise and refusals; cross cursor; Shift+click stays; the
  ring under the target; minimap click places Explore.
- [ ] 9.C8 flag card: rects of section 7, Z / Shift+Z / Delete only with a flag selected, tooltips with the refund
  numbers, enemy variant.
- [ ] 9.C8 world / minimap / barks: stake `Label3D` per flag; hunted coin; the four minimap icons with the test
  counters; barks as section 10 (font 32, width 560, 3 s, fade 0.5 s, `body_height + 1.1`).
- [ ] Help text has the 8th line; nothing existing moved (the `ui-style.md` section 10 rects still pass their test).

---

## 15. Step 11: classes (task 11.D2, for 11.C4)

Written 2026-09-26. Source of truth for **11.C4** (`champion_bar.gd`, `tavern_window.gd`, `selection_panel.gd`): the
class icon on the bar, the inspect title and its **6 abilities in 2 rows of 3**, the tavern class line and the new
prices, the class tooltips, the class-choice message. Gameplay numbers and strings come from `skills-rework.md`
(sections 2, 3, 4, 7, 9, 10): `ChampionClass` (`class_id()` = `spear` / `sword_shield` / `two_hand` / `wizard`, `&""`
before level 2), the draw at level 2, the 12 class skills, hire 225+75 / 275+100 / 325+125, revive `80 + 35 x level`.
Same conventions as section 1 (pixels at 1600 x 900, tokens, "slot frame", "bar"). Everything the step-9 layout placed
stays where it is **except the inspect view's ability block** (15.3: it moves 104 px right and grows to 2 rows; 11.C4
updates the 9.C7 test numbers, per the step-11 rules). Data is read duck-typed as in section 3 (`has_method`, `get`);
until 11.C1 lands, the UI falls back to the tables of 15.6 so it runs headless with stubs.

### 15.1 The class glyph (shared by the bar, the tavern tile and the tavern class line)
A **16 x 16 badge**: bg `(0, 0, 0, 0.75)`, 1 px `frame_dark` border, radius 3 (the key badge's look); inside, the class
icon `res://art/icons/classes/<class_id>.png` (128 x 128 as 6.1, from 11.V7; drawn 14 x 14 inset 1,
`LINEAR_WITH_MIPMAPS`) **or**, when the file is missing, a glyph drawn in code in `text` colour, line width 1.5, in a
box of side s with centre c and r = 0.375 s (6 px at 16):
| Class | Glyph (like the 13.2 bounty icons: read at 14-20 px) |
|---|---|
| `spear` | Shaft: a line `c + (-0.8 r, 0.8 r)` -> `c + (0.8 r, -0.8 r)`; leaf blade: filled triangle `c + (0.95 r, -0.95 r)`, `c + (0.3 r, -0.65 r)`, `c + (0.65 r, -0.3 r)` |
| `sword_shield` | The 13.2 Guard shield outline (`(-0.5 r, -0.55 r)`, `(0.5 r, -0.55 r)`, `(0.5 r, 0.05 r)`, `(0, 0.6 r)`, `(-0.5 r, 0.05 r)`) filled at alpha 0.35 + outline; over it a sword line `c + (-0.75 r, 0.75 r)` -> `c + (0.75 r, -0.75 r)` |
| `two_hand` | Blade: line `c + (0, 0.5 r)` -> `c + (0, -0.95 r)` width 2; cross-guard `c + (-0.55 r, 0.35 r)` -> `c + (0.55 r, 0.35 r)`; grip `c + (0, 0.35 r)` -> `c + (0, 0.85 r)`; pommel `draw_circle` radius 0.15 r at `c + (0, 0.92 r)` |
| `wizard` | Staff: line `c + (-0.3 r, 0.95 r)` -> `c + (0.3 r, -0.45 r)`; crystal: a 4-point diamond radius 0.35 r centred `c + (0.4 r, -0.65 r)` filled `(0.6, 0.75, 1.0)` (the bolt colour) |
Fallen: the badge follows the portrait's `modulate (0.55, 0.55, 0.55)`. Hover of the parent slot: the border becomes
`trim_glow` like the portrait border. The badge is a child `Control` with `mouse_filter PASS` and its own
`tooltip_text` = the class tooltip (15.5), so the click still reaches the slot under it.

### 15.2 Champion bar (3.2 + the class badge)
```
 0     6  8              64  72                                          208      232 240
 +-------------------------------------------------------------------------------------+ 0
 |  +----------------+     GARRAN STONEWARD                               [F6]          | 6
 |  |                |                                                                  |
 |  |   portrait     |     [=========== 520 / 561 =================]                    | 26
 |  |                |                                                                  |
 | [SS]        +-----+     Guarding                                   ~ 50              | 46 .. 50 (badge)
 |  +----------| (2) |                                                                  |
 +-------------+-----+----------------------------------------------------------------+ 72
```
| Part | Rect in the slot | Look |
|---|---|---|
| Class badge | **16 x 16 at (6, 50)**, centre (14, 58): the portrait's **lower-left** corner (the level medallion already owns the lower-right, centre (60, 58); the two badges sit on one line) | 15.1. Shown only when `class_id() != &""`. **No class yet (before level 2): nothing** (no badge, no placeholder; the slot is exactly the step-9 slot). Not shown on `arriving` / empty slots |
| Tooltip line 1 | | After the choice: `Garran Stoneward  [F6]  the Oathwall · Sword and Shield` (the class rides on the muted title part after the `]`). Before the choice the 5 lines of 3.4 are **unchanged** (the step-9 tooltip tests keep passing) |
| Class chosen (animation) | | The badge appears with a scale pop 0 -> 1.25 -> 1.0 over 0.3 s (`pivot_offset` centre; matches the model's 0.3 s weapon scale-in) at the same moment as the level-2 medallion ring of 3.3. Loaded from a save with a class: no pop (the bar's `_last_class` starts equal) |
| Prices | | `FALLBACK_COSTS` -> `(225, 75)`, `(275, 100)`, `(325, 125)`; `revive_cost` fallback -> `80 + 35 x level`. The guild's `hire_cost` / `revive_cost` win when present |
Detection: connect `class_chosen(champion, class_id)` when `ch.has_signal(&"class_chosen")`, else compare `class_id_of(ch)`
with the slot's `_last_class` at the 10 Hz refresh. Reading the class (static helper `ChampionBar.class_id_of(ch) ->
StringName`): `ch.call(&"class_id")` when it has the method, else `ch.get("champion_class")` -> its `id`, else `&""`.

### 15.3 Inspect view (section 4 + title + 6 abilities)
```
 588        696                                          1088  1104      1158      1212  1260
 670 +--------+ GARRAN STONEWARD · the Oathwall · Sword and Shield   the Oathwall                 670 (caption font 10)
     |portrait|                                                 +------+  +------+  +------+
     | 96x96  | [HP  520 / 561 ==================]              |  OI  |  |  SB  |  |  BS  |    684 (48 x 48)
     |        | [XP  210 / 500 ---------------]                 |  9   |  |      |  | L4   |
 766 +--------+ Level 2 · Damage 13 · Range 1.8 · Speed 4.1 · Armor 30   +------+  +------+  +------+    732
 786            Guarding: Ember Hall (50)  ·  Purse ~ 50        Oath of… Shield … Bulwar…       734 (font 11)
 806            [T 2]                       (status chips)      Sword and Shield                752 (caption, title colour)
 826            [  ][  ][  ][  ]            (4 item slots)      +------+  +------+  +------+
                                                                |  RP  |  |  SW  |  |  ST  |    766
                                                                |      |  | L3   |  | L5   |
                                                                +------+  +------+  +------+    814
                                                                Riposte  Second … Shield …      816
                                                                Autocast · next at level 3      834
 874
```
(Level-2 Sword and Shield Oathwall: HP 520 x 1.08 = 561, armor 20 + 10 = 30, damage 12 x 1.08 = 13, speed 4.3 - 0.2 = 4.1.)

| Element | Rect | Look |
|---|---|---|
| Name row | (696, 670), **392 x 24** (was 290; view-relative (108, 0)), one `HBoxContainer`, `clip_contents` | `GARRAN STONEWARD` Cinzel 20 `title`, then ` · the Oathwall` **font 13** `text` (one size down, the tavern's size for the same suffix, so the longest title fits: `GARRAN STONEWARD · the Oathwall · Sword and Shield` is about 390 px), then the class part: ` · Sword and Shield` font 13 `title` (`ChampionClass.display_name`, e.g. `Spear`, `Sword and Shield`, `Two-Hand Sword`, `Wizard`), or ` · no class yet` font 13 `text_muted` before level 2. The class label has `mouse_filter STOP` and the class tooltip (15.5); the "no class yet" label the lean tooltip. String form for tests: `champion_name.text + champion_title.text + champion_class_label.text` = `GARRAN STONEWARD · the Oathwall · Sword and Shield` |
| HP / XP bars | unchanged: 280 x 22 at (696, 700); 280 x 14 at (696, 726) | XP reads the new table by itself (`xp_to_next`): `XP  210 / 500` at level 2 |
| Stat line | (696, 746), width 392, `clip_text` + ellipsis | Unchanged format; the numbers come from the champion (`get_stat` for damage / speed / armor, the `attack_range` field), so a class shows through: `Range 2.4` for a Spear, `Range 7.5` for a Wizard, `Armor 30` for a Sword and Shield Oathwall |
| Intent row | (696, 766), **width 392** (was 560, it would run under row 2) | Intent label max width 260 with ellipsis, then the purse as today |
| Status chips / items | unchanged: (696, 786); 36 at (696 + 40 i, 826) | |
| Row 1 caption | (1104, 670), 156 x 12, font 10 `text_muted` | The archetype's title: `the Oathwall` |
| **Row 1 (archetype)** | 3 slots 48 x 48 at **(1104 + 54 j, 684)**, j = 0..2 (step 54 = gap 6, like the queue slots; view-relative (516 + 54 j, 14)) | The 3 archetype ids in `ChampionType` order (ch. 4.3), exactly the step-9 slot look: icon 40 inset 4 or abbreviation, sweep + seconds (own), ready flash, locked = `modulate.a 0.45` + `L4` badge. `flare_arrow` is displayed **Signal Flare** (its icon file keeps the id) |
| Row 1 names | (1104 + 54 j, 734), 50 x 14, font 11 `text_muted`, ellipsis | `Oath of…`, `Shield …`, `Bulwar…` |
| Row 2 caption | (1104, 752), 156 x 12, font 10 | After the choice: the class name in `title` colour (`Sword and Shield`), tooltip = class tooltip; before: `Class at level 2` `text_muted`, tooltip = lean tooltip. `mouse_filter STOP` |
| **Row 2 (class)** | 3 slots 48 x 48 at **(1104 + 54 j, 766)** | After the choice: the class's 3 skill ids in unlock order (`ChampionClass.ability_ids`; icons `art/icons/abilities/<id>.png` like the archetype ones, abbreviation fallback), same look as row 1; locked ones (below 3 / 5) show their real icon at `modulate.a 0.45` with the badge `L3` / `L5` (the player sees what is coming). **Before the choice: three `?` slots**: `modulate.a 0.45`, a `?` Cinzel 18 `text_muted` centred instead of an icon, badges `L2` / `L3` / `L5`, tooltip = the lean tooltip (15.5); enemy: the base-weights version |
| Row 2 names | (1104 + 54 j, 816), 50 x 14 | `Riposte`, `Second …`, `Shield …`; before the choice `Skill 1` / `Skill 2` / `Skill 3` |
| Autocast line | (1104, 834), 156 x 14, font 11 `text_muted` | `Autocast · next at level 3` (the lowest unlock level still locked across the 6, own champions) / `Autocast` when all 6 are owned, and for enemies |
| Locked / cooldown data | | `abilities.ability_ids()` (6 after the choice, 3 before), `is_unlocked(id)`, `cooldown_left(id)` as today; total cooldown from the 15.6 table for the 12 new ids. `champion_abilities` becomes 6 `AbilitySlot`s (index 0-2 row 1, 3-5 row 2); `champion_ability_list()` lists the visible names of both rows, row 1 first |
| Class chosen (animation) | | If that champion is inspected: the title's class part fades in 0.3 s; the row-2 caption flashes `GOLD` -> `title` over 0.5 s; the three `?` swap to the class skills, each pops 1.0 -> 1.08 -> 1.0 in 0.2 s staggered 0.05 s; slot 1 (unlocked) plays the ready flash. Enemy champion: the same, when visible |
| Enemy champion | | Title with its class when chosen (`· no class yet` else); both rows shown, no sweeps (unchanged rule); `?` tooltips use the archetype's base weights and no bounty hint |
Nothing here is clickable (unchanged). The block stays inside x 1104-1260 (the hover halo at 1261 < 1264) and y
670-848 (< 874).

### 15.4 Tavern window (section 5 + the class line + prices)
Column B grows from 3 to **4 lines at a 20 px step**: labels at (372, 6), (372, 26), (372, 46), **(372, 66)**, height 16
(x 372-622 as before). The `L4` badge moves to (372, 47) (its text at x 396); the new **`L2` badge** (same look: 20 x
14, bg `(0, 0, 0, 0.75)`, font 10 `GOLD`) sits at (372, 67). Columns A and C do not move.
```
 +--------+ GARRAN STONEWARD · the Oathwall        Oath of Iron · taunts 3 s, +20 armor            <225  ~75
 |  (GS)  | Guardian, melee                        Shield Bash · 30 dmg + dazes 0.8 s              Pop 2
 |        | 520 HP · 15 damage · 1.8 range · 4.3 speed · 20 armor   [L4] Bulwark Stand · braces allies 6 s
 +--------+ Would rather stand at your door than walk to theirs.   [L2] Class · usually Sword and Shield    [   Hire   ]

 +--------+ GARRAN STONEWARD · the Oathwall        Oath of Iron · taunts 3 s, +20 armor            Hired · Level 3
 |  (GS)  | Guardian, melee                        Shield Bash · 30 dmg + dazes 0.8 s              Guarding: Ember Hall
 | [SS](3)| 603 HP · 13.9 damage · 1.8 range · 4.1 speed · 30 armor  [L4] Bulwark Stand · braces allies 6 s   ~ 50
 +--------+ Would rather stand at your door than walk to theirs.   [ss] Sword and Shield · skills 2 / 3     [  Dismiss  ]
```
| Part | Content |
|---|---|
| Line 4, not hired | `[L2]` badge + 4 px + `Class` (`text`) + ` · usually Sword and Shield` (`text_muted`): the class with the highest **base** weight of the archetype (`ChampionType.class_weights`, table 2.1; ties: the table's order). The line is at most 33 characters (about 215 px + 24 = 239 <= 250). Tooltip: the lean tooltip with the base weights (15.5) |
| Line 4, hired below level 2 (`arriving` too) | `[L2]` badge + `Class` + ` · leans Sword and Shield (71 %)` with the **live** weights (`ChampionClass.weights_for(champion)`, bounties included); tooltip = the live lean tooltip |
| Line 4, hired with a class | The 16 x 16 class glyph (15.1) at (372, 66) instead of the badge, then at x 396: `Sword and Shield` (`text`) + ` · skills 2 / 3` (`text_muted`; class skills unlocked of 3, from `is_unlocked` on the 3 class ids). Tooltip = the class tooltip (numbers at the champion's level). Fallen / reviving rows: the same line, dimmed with the row |
| Portrait tile | Hired with a class: the class badge 16 x 16 at (6, 70) (centre (14, 78), the tile's lower-left; the medallion keeps the lower-right at (74, 78)) |
| Column A stats, hired | Read the champion, not the type: `max_hp`, `get_stat(attack_damage)`, the `attack_range` field, `get_stat(move_speed)`, `get_stat(armor)` (` · 30 armor`; still omitted when 0). Not hired: level-1 archetype numbers as today |
| Column C, not hired | Prices from `hire_cost(id)`: `225` / `75`, `275` / `100`, `325` / `125` (fallback table 15.2); tooltip `Hire  [Y]\n225 crystals · 75 essence · 2 pop` (+ reason) |
| Column C, hired | **Unchanged** (`Hired · Level 3`, intent, purse, `Dismiss`): the column is 108 px wide, so the class of section 7's `Hired · Level 3 · Sword and Shield · Guarding` lives on line 4 of column B and on the tile |
| Column C, fallen | `Revive 150` for a level-2 champion (`80 + 35 x level`: 115 / 150 / 185 / 220 / 255 / 290); tooltip `Revive  \n150 essence · returns at your keep` (+ `Not enough essence`); `Fallen · Level 2` |
| Class chosen while open | The row's line 4 swaps to the class form and the row flashes `GOLD` 0.3 s (the hire flash) |
| Footer, title bar, rule, row states | Unchanged |
Signal Flare: the Wayfinder's first line reads `Signal Flare · 20 dmg, reveals a spot 6 s` (id `flare_arrow`, same
icon, same numbers); its tooltip effect line is `Hurls a flare up to 20 m: {20} damage around it, and the spot stays
in sight for 6 s.` (skills-rework 4.1). 11.C4 updates the 9.C7 test that reads `Flare Arrow`.

### 15.5 Tooltips (section-8 panel; `styled_tooltip` colours `Locked` / `Unlocks at level n` / `Unpaid:` in `WARN` and, new, a line starting with `Your bounties` in `GOLD`)
**Class tooltip** (bar badge, inspect title class part and row-2 caption, tavern line 4 with a class):
```
Sword and Shield
melee · 12 damage every 1.1 s · reach 1.8
+10 armor · -0.2 speed
Riposte L2 · Second Wind L3 · Shield Throw L5
```
Line 1 Cinzel 15 `title`; line 2 font 13 `text` (the damage is the champion's current `get_stat(attack_damage)` when
one is given: `13.9 damage every 1.1 s` at level 3; the type's level-1 number in the tavern's not-hired rows never
shows this tooltip); line 3 font 13 `text_muted`: the class stat changes (`+0.2 speed` / `+10 armor · -0.2 speed` /
`no stat change` / `-10 % max HP`); line 4 font 13 `text_muted`: the 3 class skills with their unlock levels. Per class:
| Class | Line 2 | Line 3 | Line 4 |
|---|---|---|---|
| Spear | `melee · 13 damage every 0.95 s · reach 2.4` | `+0.2 speed` | `Lunge L2 · Hobbling Javelin L3 · Skewer L5` |
| Sword and Shield | `melee · 12 damage every 1.1 s · reach 1.8` | `+10 armor · -0.2 speed` | `Riposte L2 · Second Wind L3 · Shield Throw L5` |
| Two-Hand Sword | `melee · 24 damage every 1.55 s · reach 2.1` | `no stat change` | `Cleave L2 · Crushing Blow L3 · Whirlwind L5` |
| Wizard | `ranged 7.5 · 11 damage every 1.3 s` | `-10 % max HP` | `Arc Bolt L2 · Slipstep L3 · Starfall L5` |

**Lean tooltip** (the `?` slots, the inspect `no class yet` / `Class at level 2` labels, the tavern line 4 before a class):
```
Class skill 1  Locked
Chooses a class at level 2 · leans Sword and Shield (71 %)
Sword and Shield 71 % · Two-Hand Sword 14 % · Spear 11 % · Wizard 4 %
Your bounties before level 2 steer its class
Unlocks at level 2
```
Line 1: `Class skill 1` / `2` / `3` + `Locked` (`WARN`) on the `?` slots; `Class` on the caption and tavern labels (then no
line 5). Line 2 font 13 `text`: the leading class and its percentage. Line 3 font 13 `text_muted`: all four, highest
first, `roundi(100 x weight / sum)`. Line 4 in `GOLD` (the learn-hint look): the bounty hint, **own champions and
not-hired rows only** (never for an enemy champion). Line 5 `WARN`: the slot's unlock level (`2` / `3` / `5`).
Weights: `ChampionClass.weights_for(champion)` when the script exists (`ResourceLoader.exists` + `has_method`, reached
by `load`, never as a static type); else `ChampionType.class_weights` (`res.get("class_weights")` in `type_info`);
else the table of 15.6. The example is an Oathwall paid 2 Guard bounties (100 / 20 / 15 / 5 of 140); with none it
reads `leans Sword and Shield (60 %)` / `Sword and Shield 60 % · Two-Hand Sword 20 % · Spear 15 % · Wizard 5 %`.

**Class skill tooltip** (row 2 slots; the 5.4 format, line 1 marks it as a class skill):
```
Riposte  (class, level 2)
Cooldown 22 s · Self, 4 s
Melee attackers take 10 damage per hit.
Autocast: when 2+ melee enemies attack it
Unlocks at level 3            <- only while locked, WARN (with `Locked` after line 1 as in 5.4)
```
`(class, level 2)` is drawn right-aligned, font 12 `text_muted`, like `Rank n / m` (the string form keeps it inline).
Archetype tooltips are unchanged (no `(archetype)` mark: the 9.C7 tests read them). Texts of the 12: 15.6.

### 15.6 Data for 11.C4 (fallback tables in `champion_bar.gd`, overlaid by `data/champion_classes/<id>.tres` when it exists, like `type_info`)
`CLASSES` (keys `display_name`, `ranged`, `attack_damage`, `attack_cooldown`, `attack_range`, `mods` (line 3 text),
`ability_ids`, `unlock_levels` `[2, 3, 5]`; `ChampionBar.class_info(id)`, `class_name_of(ch)`, `class_tooltip(id, damage := -1.0)`,
`lean_tooltip(weights, slot := 0, own := true)`, `class_weights_for(ch_or_id) -> Dictionary`):
| id | display_name | ranged | damage / cooldown / range | ability_ids |
|---|---|---|---|---|
| `spear` | Spear | no | 13 / 0.95 / 2.4 | `lunge`, `hobbling_javelin`, `skewer` |
| `sword_shield` | Sword and Shield | no | 12 / 1.10 / 1.8 | `riposte`, `second_wind`, `shield_throw` |
| `two_hand` | Two-Hand Sword | no | 24 / 1.55 / 2.1 | `cleave`, `crushing_blow`, `whirlwind` |
| `wizard` | Wizard | yes | 11 / 1.30 / 7.5 | `arc_bolt`, `slipstep`, `starfall` |
`CLASS_WEIGHTS` (archetype -> class -> base weight, skills-rework 2.1): wayfinder 50 / 10 / 15 / 25, oathwall 15 / 60 /
20 / 5, coin_cutter 25 / 5 / 55 / 15, mender 15 / 20 / 5 / 60 (order spear, sword_shield, two_hand, wizard).

`ABILITIES` gains the 12 ids (`unlock` = the class unlock level; `short` is unused in the tavern but filled for
completeness; `{n}` grows as `ability_effect` does; Second Wind's 20 % has no `{}`):
| id | name | unlock | cooldown | Tooltip line 2 | Line 3 (effect) | Line 4 (`Autocast: ...`) |
|---|---|---|---|---|---|---|
| `lunge` | Lunge | 2 | 14 | `Cooldown 14 s · Range 6` | `Darts to its target and strikes: {25} damage, dazed 0.5 s.` | `on a ranged enemy or caster 3-6 m away, or a hunt target slipping away` |
| `hobbling_javelin` | Hobbling Javelin | 3 | 16 | `Cooldown 16 s · Range 10` | `A javelin: {25} damage and hobbles the target 3 s (-1.5 speed).` | `on an enemy below 60 % HP that runs, or its hunt target` |
| `skewer` | Skewer | 5 | 25 | `Cooldown 25 s · Line 5 m` | `A thrust through a 5 m line: {40} damage to every enemy in it.` | `when 3+ enemies stand in a line` |
| `riposte` | Riposte | 2 | 22 | `Cooldown 22 s · Self, 4 s` | `Melee attackers take {10} damage per hit.` | `when 2+ melee enemies attack it` |
| `second_wind` | Second Wind | 3 | 45 | `Cooldown 45 s · Self` | `Heals itself 20 % of its max HP over 4 s.` | `below 50 % HP, hit in the last 2 s` |
| `shield_throw` | Shield Throw | 5 | 20 | `Cooldown 20 s · Range 8` | `Throws its shield: {30} damage, then {20} and {10} to two more enemies within 4 m.` | `on a ranged enemy hitting an ally, or a target out of reach 3-8 m away` |
| `cleave` | Cleave | 2 | 10 | `Cooldown 10 s · Melee` | `Its next attack also hits every enemy within 2.5 m of the target for full damage.` | `when its target has 2+ enemies beside it` |
| `crushing_blow` | Crushing Blow | 3 | 20 | `Cooldown 20 s · Melee` | `{30} damage; an enemy unit loses 20 armor for 6 s.` | `on an armored target (10+), a hero or a costly unit` |
| `whirlwind` | Whirlwind | 5 | 30 | `Cooldown 30 s · Self, radius 3` | `Spins 2 s: {12} damage every 0.5 s to every enemy within 3 m ({48} each).` | `when 3+ enemies are within 3 m` |
| `arc_bolt` | Arc Bolt | 2 | 10 | `Cooldown 10 s · Range 12` | `A bolt: {40} damage to one enemy.` | `on an enemy it can finish, else a hero, else the one hitting the most hurt ally` |
| `slipstep` | Slipstep | 3 | 22 | `Cooldown 22 s · Self, 8 m` | `Blinks up to 8 m away from the nearest melee enemy.` | `when a melee enemy closes in below 70 % HP, or while fleeing` |
| `starfall` | Starfall | 5 | 35 | `Cooldown 35 s · Range 12, radius 3.5` | `A star falls after 1 s: {45} damage to every enemy and building within 3.5 m.` | `on the enemy with the most neighbours (3+ within 3.5 m)` |
`ability_tooltip(id, level, ...)` appends `  (class, level n)` to line 1 for these 12 ids (`unlock` levels 2 / 3 / 5 tell
them apart from the archetype ids; a locked class skill still says `Locked` after the name and `Unlocks at level n`).
`flare_arrow`: `name` -> `Signal Flare`, `effect` -> the 15.4 text. Icons: `abilities/<id>.png` for the 12 skills,
`classes/<class_id>.png` for the 4 classes (`IconLibrary.icon_for(&"classes", id)`; a code glyph until 11.V7 lands).

### 15.7 Message and feedback (section 11 + one row; the bark and the VFX are gameplay / 11.V6)
| Message | Seconds | Emitted by |
|---|---|---|
| `Garran Stoneward takes up the Sword and Shield` (own champion; `takes up the Spear` / `the Two-Hand Sword` / `the Wizard's staff` for `wizard`) · enemy champion, only if `is_visible_in_tree()` at that moment: `Gerda Stoneward takes up the Spear` | 3.0 | `champion_bar.gd` (11.C4) on `class_chosen` of every node in group `"champions"` (own: from the roster; enemy: a 1 Hz group scan connects the signal once per champion), through `hud.show_message` found as section 11 says. Never on a save load (`apply_save_state` restores the class silently: the bar compares against its `_last_class` only after the first refresh of that champion) |
The bark of skills-rework 2.2 replaces the level-2 level-up bark (gameplay); the `class_chosen` ring is 11.V6. Nothing
new in the help text, no new key.

### 15.8 Sizes at 1600 x 900 (summary of the additions)
| Thing | Size / position |
|---|---|
| Bar class badge | 16 x 16 at (6, 50) in the slot (centre (14, 58)); icon 14 inset 1; tooltip = class tooltip |
| Inspect title | name row (696, 670) 392 x 24: Cinzel 20 + font 13 suffix ` · the Oathwall · Sword and Shield` / ` · no class yet` |
| Inspect stat / intent rows | width 392 (x 696-1088), intent label max 260 |
| Inspect captions | (1104, 670) and (1104, 752), 156 x 12, font 10 |
| Inspect ability rows | row 1 slots 48 at (1104 + 54 j, 684), names (1104 + 54 j, 734) 50 x 14; row 2 slots at (1104 + 54 j, 766), names y 816; autocast (1104, 834) |
| Tavern column B | 4 lines at (372, 6 / 26 / 46 / 66), height 16; `L4` badge (372, 47); `L2` badge or class glyph (372, 66/67); text x 396 |
| Tavern tile class badge | 16 x 16 at (6, 70) (centre (14, 78)) |
| Tavern prices / revive | `225 · 75`, `275 · 100`, `325 · 125`; `Revive 115 / 150 / 185 / 220 / 255 / 290` at levels 1-6 |
| Tooltips | class 4 lines; lean 4-5 lines; class skill 4-5 lines with `(class, level n)` right-aligned |

### Done when (11.C4)
- [ ] Bar: a slot shows the 16 x 16 class badge at (6, 50) only when `ChampionBar.class_id_of(ch) != &""` (none before
  level 2, none on arriving / empty slots); the glyph draws without any PNG and the PNG replaces it when present; the
  badge's tooltip is the 4-line class tooltip of 15.5; tooltip line 1 gains ` · Sword and Shield` after the choice and
  the 5 lines of 3.4 are unchanged before it; the badge pops 0.3 s on `class_chosen` and not on a save load;
  `FALLBACK_COSTS` 225+75 / 275+100 / 325+125 and the revive fallback `80 + 35 x level`; the message of 15.7 is shown
  exactly once per champion (own always, enemy only while visible), 3.0 s.
- [ ] Inspect: `champion_abilities.size() == 6`; row 1 at (1104 + 54 j, 684) and row 2 at (1104 + 54 j, 766), names at
  y 734 / 816, captions at (1104, 670) / (1104, 752), autocast line at (1104, 834); the name row is 392 wide and reads
  `GARRAN STONEWARD · the Oathwall · Sword and Shield` after the choice and `... · no class yet` before; before the
  choice row 2 is three `?` at alpha 0.45 with badges `L2` / `L3` / `L5`, names `Skill 1-3`, and their tooltip is the
  lean tooltip with the **live** weights (an Oathwall paid 2 Guard bounties reads `leans Sword and Shield (71 %)`; with
  none `60 %`; an enemy champion gets the base weights and no `Your bounties` line); after the choice row 2 shows the
  3 class ids in unlock order with `L3` / `L5` on the locked ones and `(class, level n)` in their tooltips;
  `champion_ability_list()` = `Oath of Iron, Shield Bash, Bulwark Stand, Riposte, Second Wind, Shield Throw`; the
  autocast line reads `Autocast · next at level 3` at level 2 and `Autocast` at level 5+; the stat line shows the class
  range / armor / speed (Spear `Range 2.4`, Sword and Shield Oathwall `Armor 30`); `flare_arrow` displays `Signal
  Flare`; the 9.C7 test numbers that moved (ability slots, name row width) are updated in the same task.
- [ ] Tavern: column B has 4 labels at y 6 / 26 / 46 / 66 with the `L4` badge at (372, 47); line 4 reads `Class ·
  usually Sword and Shield` (`[L2]` badge) for an unhired Oathwall, `Class · leans Sword and Shield (71 %)` once hired
  with 2 Guard bounties below level 2, and `Sword and Shield · skills 1 / 3` (class glyph) at level 2; its tooltips are
  the lean / class tooltips of 15.5; a hired row's stats line reads the champion's range, speed and armor; prices show
  `225` / `75` for the first hire (guild or fallback) and `Revive 150` for a level-2 fallen champion; the hired tile
  shows the class badge at (6, 70); the row flashes gold when its champion chooses a class while the window is open.
- [ ] `tests/test_11_c4.gd` reads the rects above at 1600 x 900 with stub champions (a `class_id()` method, a stub
  `abilities` with `ability_ids` / `is_unlocked` / `cooldown_left`, a `class_chosen` signal) and without any step-11
  script present (fallback tables); the step-9 UI tests still pass; nothing in `scripts/ui/` calls a `_private`
  function of another script; no step-11 `class_name` is used as a static type.

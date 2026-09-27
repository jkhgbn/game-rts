# UI: 2v2 skirmish (lobby, 4-player HUD, ally pings and commands, minimap, end screen) (step 20, task 20.D2)

Written 2026-09-26. Source of truth for the ui-coder tasks **20.U1-20.U6** (section 15). It lays out everything the player
sees in the 2v2 skirmish of `waves.md` "Step 20": the player controls **only their own kingdom**, one **ally bot** is on
the same team, **two enemy bots** on the other. It uses the skin of `ui-style.md` (tokens, fonts, frames, bars, tooltips)
and the conventions of `ui-champions.md`, `ui-trade.md` and `ui-mapfill.md`, and moves **nothing** those files place in
the 1v1: every rule here is "2v2 only" unless marked. Gameplay rules (defeat rule, map, sizes, allied vision, resources)
come from `map-2v2.md` (20.D1) and the ally bot from `ai-2v2.md` (20.D3), both written in parallel with this file; where
this file needs something from them it says so in section 14 ("APIs needed"). If they ever disagree, 20.D1 / 20.D3 win for
gameplay, this file for pixels.

Conventions: as `ui-mapfill.md`. Pixels from the top-left at **1600 x 900** (virtual pixels, `ui-champions.md` section 2:
the whole HUD scales with `GameSettings.ui_scale`, no per-element rules); `(x, y)` = top-left corner, `w x h`; colours are
the `UIStyle` tokens (`title`, `text`, `text_muted`, `frame_metal`, `frame_light`, `frame_dark`, `groove`, `trim_glow`,
`panel_bg`, `panel_inner`, `slate_bg`), the shared constants `GOLD (1.0, 0.85, 0.4)`, `WARN (0.95, 0.35, 0.3)`, `HP`,
`DEFEAT (0.85, 0.30, 0.30)`, `NEAR (0.4, 0.9, 0.4)`, `FAR (1.0, 0.55, 0.2)`, the map-fill `OWN (0.3, 1.0, 0.4)` / `ENEMY
(1.0, 0.3, 0.3)`, and the new **slot colours** of section 2. "Cinzel n" = `UIStyle.display_label` at size n; "font n" = the
body font at n; "number font" = `UIStyle.number_label`; "slot frame" = `UIStyle.button_frame` (3.3); "heavy frame" =
`UIStyle.frame_style`; "slate" = `UIStyle.slate_style`; "bar" = `UIStyle.bar` (5.3); "chip" = the bounty cursor chip style
(`ui-champions.md` 6.2); "section-8 tooltip" = `UIStyle.make_tooltip`. Controls are built in code (no `.tscn`). Text widths
marked "est." use ~0.55 em per character; the coder checks them with `Font.get_string_size` in the task tests.

---

## 0. Decisions in one page
| Topic | Decision (details in the section) |
|---|---|
| Team model the UI assumes | Each player has its **own `team` value** (`PLAYER` 0 you, `ENEMY` 1, `NEUTRAL` 2, **`ALLY` 3**, **`ENEMY_2` 4**) and an alliance table decides friend / foe. The ~40 `team == PLAYER` checks of the selection manager then keep the ally non-orderable for free (14.1). |
| Colours | **Cool = friends, warm = foes**: you green (unchanged `OWN`), ally **blue**, enemy 1 red (unchanged `ENEMY`), enemy 2 **rose**. Side-level things (points, crown, blessings) stay green / red (2) |
| Lobby | The Skirmish panel gets a `1v1 / 2v2` switch. 2v2 = two team columns, one **slot row** per player: kingdom tiles (+ Random), difficulty and style per bot, fixed slot colour (3) |
| Ally info | A **team panel** top-right under the help: ally card (wizard HP, level, army, workers, status, 4 order buttons) + one row per enemy. **Ally resources hidden** (recommended, Q2) (4) |
| Notifications | `Your ally is under attack!` (+ ping, sound, card pulse), `Ally wizard fallen: ...`, kingdom-fallen lines, ally replies; enemy level-ups no longer spam the message line (5) |
| Pings / ally orders | **Alt+click** = context ping, **Alt+drag** (or hold the **²** / **`** key) = 4-way wheel: Attack here / Defend here / Help me / Retreat, centre = Look here; the ally card buttons do the same; **F4** = find your ally (6) |
| Minimap | Same 240 x 240 panel; scale = `220 / max(map width, map depth)`, non-square maps letterboxed; slot colours; coloured pings with glyphs; the ally's current order as a dashed line (7) |
| Allied things | Left-click = **read-only inspect**; never selected, grouped, boxed or ordered; right-click / A-click on them = a plain move to that spot (8) |
| End screen | 4 columns (your team | enemy team), one row per stat, best value in gold (9) |

---

## 1. Where everything goes

### 1.1 Screen map in the 2v2 (existing panels unchanged unless marked; new ones in bold)
| Panel | Rect at 1600 x 900 | Anchor | Owner |
|---|---|---|---|
| Objective (skirmish) | (16, 16), auto (511 x 70; text of 5.4) | top-left | existing (text from the level) |
| Top bar | 624 x 40 at (488, 8) with gold | top-centre | existing, **unchanged** (your own economy only) |
| Objectives strip / blessing chips | 300 x 50 at (650, 52) / 144 x 22 at (958, 54 / 78) | top-centre | step 12 (width follows the point count; section 2.2 colours) |
| Controls help | right edge x 1584, y 16; **458 x 267 with a 13th line** (5.5) | top-right | existing (`hud.gd`) |
| Message line | centred, y 120 (pushed under the help panel for wide texts) | top-centre | existing |
| Beast boss bars | 456 x 50 at (572, 156) / (572, 212) | top-centre | step 12 |
| **Team panel** | **240 x 194 at (1344, 296)**: ally card 240 x 124 at y 296, enemy rows 240 x 30 at y 426 and 460 | top-right (`offset_left -256`, `offset_right -16`, `offset_top 296`) | 20.U3 (section 4) |
| **Kingdom-fallen notice** | **560 x 104 at (520, 300)**, 6 s, no dim | centre | 20.U3 (5.3) |
| **Ping wheel** | 160 x 160 centred on the press point (+ label under it to y + 90) | mouse | 20.U4 (6.3) |
| **Ping targeting chip** | mouse + (18, 12), height 26 | mouse | 20.U4 (6.4) |
| **Off-screen ping arrows** | 28 x 28 on the edge of the view rect (24, 60)-(1576, 612) | screen | 20.U4 (6.6) |
| Champion bar | 240 x 228 at (16, 408) | bottom-left | step 9 (unchanged) |
| Control group tabs | 64 x 36 from x 272, y 620-656 | bottom | existing |
| Minimap | 240 x 240 at (16, 644); draw area 220 x 220 at (26, 654) | bottom-left | existing (**20.U2**: scale, slot colours, markers, ally order line; section 7) |
| Selection panel | 1002 x 224 at (272, 660) | bottom | existing (**20.U5**: ally inspect views, section 8) |
| Command card | 294 x 224 at (1290, 660) | bottom-right | existing (**20.U5**: ally text block) |
| End screen | centred, **min width 900** in the 2v2, margin 24 | centre | existing frame (**20.U6**: 4-column table, section 9) |

### 1.2 Free space measured from the code (why things go where they go)
- **Right column**: the help slate is right-anchored at x 1126-1584 and grows to y 264 with 12 lines (`ui-mapfill.md` 12);
  the 13th line makes it about 267 px tall (bottom y 283). Under it, the band **x 1344-1584, y 296-650** is empty down to
  the command card (y 660): no window opens there (tavern / trade 420-1180, shop 480-1120, dialogue box 480-1120, boss bars
  572-1028), and a message pushed under the help (y 293, centred, at most ~700 px wide) ends before x 1150. The team panel
  (y 296-490) sits there with 13 px to the help and 170 px to the command card.
- **Left column is full**: objective (16, 16) to y 86 in the skirmish (missions grow to ~y 210, and Story Episode 2 will
  be a 2v2 mission), champion bar y 408-636, minimap from y 644. Putting the ally card there would stack a 900 px wall of
  panels on one side; the right side balances the screen (champions = your hired heroes on the left, the other kingdoms on
  the right).
- **Kingdom-fallen notice** at y 300-404 in the middle: clear of the boss bars (end y 262) and the message line (y 120).
- The minimap cannot grow: x 256-272 is the gap to the group tabs, y 636-644 the gap to the champion bar (section 7 scales
  the picture inside the same panel instead).

### 1.3 Full screen (1 character = 16 x 20 px; rows are 20 px)
```
     0         1         2         3         4         5         6         7         8         9
     0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
  0                              <1 250   POP 32 / 60   14:02   ~ 140   (o) 2 140>
  1   +-objective---------------+                                           +-controls help (13 lines)-----+
  2   | Skirmish 2v2: Twin H.   |          +-strip---------------+          | Left click / drag: select ...|
  3   | Destroy both enemy k... |          |[T][T][T][T]|[W]|[S] |          | ...                          |
  4   | 2 of 2 standing         |          +---------------------+          | ...                          |
  5   +-------------------------+                                           | Capture: stand near ...      |
  6                   Your ally is under attack!   (message line, y 120)    | Alt+click: ping · ...        |
  ..                                                                         +------------------------------+
 14                                                                                 +-ally card---------------+
 15                                                                                 |[TV] TORVALD (3) ALLY·ICE|
 16                       (3D battlefield: ping markers on the ground,              |     [HP 310 / 420 ====] |
 17                        "!" icons over them, edge arrows for far pings)          |     Army 24 · Workers 12|
 18                                                                                 |     Under attack!       |
 19                                                                                 |[ATK][DEF][HELP][RETR]   |
 20                                                                                 +-------------------------+
 21                                                                                 |(o) MALRIK  Shadow   Lv 4|
 22                                                                                 |(o) YSOLDE  Nature Fallen|
 23                                                                                 +-------------------------+
 ..
 31   +-champion 3-------+ [1 5FG] [2 3EA]
 32   +-minimap----------+
 33   | green . blue .   | +-selection panel----------------------------------------------+ +-command card----+
 34   |  (!) ping  -- -->| | (3) VESSA          | [portrait] FROST GUARD · ally (Torvald)   | |  Your ally's    |
 35   | red .  rose .    | | HP  350 / 350      | HP  180 / 180                             | |  unit.          |
 44   +------------------+ +----------------------------------------------------------------+ +-----------------+
```

---

## 2. Colours for four players

### 2.1 Slot colours (per player; constants in the new `TeamColors`, never skinned)
| Slot | Team value (14.1) | Name | Colour | Lightened for text (+0.35) | Why |
|---|---|---|---|---|---|
| You | `PLAYER` (0) | `OWN` | `(0.30, 1.00, 0.40)` green (= `Minimap.OWN_COLOR`, unchanged) | - | Your eye keeps finding your own army as in the 1v1 |
| Ally | `ALLY` (3) | `ALLY` | `(0.30, 0.65, 1.00)` blue | `(0.55, 0.78, 1.00)` | Cool like green: "friend" at a glance, but clearly not yours |
| Enemy 1 | `ENEMY` (1) | `ENEMY` | `(1.00, 0.30, 0.30)` red (= `Minimap.ENEMY_COLOR`, unchanged) | `(1.00, 0.55, 0.55)` | Unchanged foe colour |
| Enemy 2 | `ENEMY_2` (4) | `ENEMY_2` | `(1.00, 0.40, 0.75)` rose | `(1.00, 0.65, 0.85)` | Warm like red: "foe" at a glance, and still tells the two enemies apart |
| Neutral | `NEUTRAL` (2) | - | `Unit.team_color(NEUTRAL)` `(0.9, 0.78, 0.42)` (unchanged) | - | |

**The rule the player learns once: cool colours are friends, warm colours are foes.** Green vs red stays exactly as in the
1v1 (own vs enemy readability is kept); blue and rose are the "second" friend and foe.

- `TeamColors.of_team(t: int) -> Color`, `text_of_team(t) -> Color` (lightened), `hp_of_team(t) -> Color` (2.3),
  `is_friend(t) -> bool` (`t == PLAYER` or allied with it), `is_foe(t) -> bool`, `relation(node) -> StringName`
  (`&"own"`, `&"ally"`, `&"enemy"`, `&"neutral"`), `slot_label(t) -> String` (`"you"`, `"ally"`, `"enemy"`), all static,
  reading the alliance through `Unit.are_allies` when it exists (14.1) and falling back to `team == PLAYER` / else foe
  (1v1 behaviour) when it does not. **Every UI file asks `TeamColors` instead of comparing teams itself.**
- In the **1v1** nothing changes: `of_team(PLAYER)` = green, `of_team(ENEMY)` = red, and the minimap keeps its current
  building colours (7.3).

### 2.2 Side colours (team-level things stay two-colour)
Things that belong to a **side** rather than a player keep the map-fill relation colours: capture points, capture rings,
the objectives strip, blessing chips, the Ember Crown line, the boss-bar "engaged" rule. Owner = you **or your ally** ->
`OWN` green; owner = either enemy -> `ENEMY` red. Texts say who: the point panel's owner line becomes `Held by you` /
`Held by your ally` (`NEAR`) / `Held by the enemy` (`WARN`), the strip tooltip line 2 likewise; blessing chips `Blessing`
(own side) / `Enemy blessing` (unchanged). Reason: "can I use it / must I take it back" is a side question; five colours
on a 28 px glyph would not read.

### 2.3 Where each slot colour shows
| Place | Look | Owner |
|---|---|---|
| Minimap units, champions (circle), caravans, flags' team ring, building squares | Slot colour (buildings darkened 0.25, 7.3) | 20.U2 |
| Minimap hero diamonds | Own: gold diamond (unchanged). Others: slot colour lightened 0.2 with a 1 px `GOLD` outline ("gold rim = wizard") | 20.U2 |
| World selection / hover ring under units (`Unit.team_color`) | Slot colour | gameplay (handoff, 14.4) |
| World HP bars over units (`Unit.team_hp_color`) | You `(0.25, 0.9, 0.3)`, ally `(0.30, 0.62, 0.95)`, enemy `(0.9, 0.25, 0.25)` (unchanged values), enemy 2 `(0.95, 0.38, 0.70)` | gameplay (handoff) |
| Portrait rim in the single / inspect view | Own: normal rim; ally: `ALLY`; enemy 1: `DEFEAT` (existing rule); enemy 2: `ENEMY_2` darkened 0.15 | 20.U5 |
| Team panel, lobby slot rows, end-screen columns | Stripe / swatch / name text in the slot colour | 20.U1 / U3 / U6 |
| Ping markers (ring, minimap rings, edge arrow) | The **pinger's** slot colour (you green, ally blue) | 20.U4 |
| Models / banners | Kingdom colour (unchanged; mirrors are allowed, so relation always comes from the ring and the minimap) | - |

### 2.4 Colour check
- `ALLY (0.30, 0.65, 1.00)` vs crystal nodes `(0.45, 0.85, 1.0)`: the nodes are pale and 4 x 4, fixed next to bases; ally
  dots are deeper blue and 3 x 3. Vs water `(0.25, 0.45, 0.65)`: ally dots are twice as bright. Vs Guarding blue
  `(0.6, 0.75, 1.0)` (defend glyph, intents): lavender vs saturated blue, and the glyph always sits on a disc.
- `ENEMY_2 (1.00, 0.40, 0.75)` vs essence violet `(0.75, 0.45, 1.0)` and the 1v1 enemy-hero violet `(0.8, 0.4, 1.0)`: in
  the 2v2 the hero diamonds use slot colours, so the violet diamond is not on the map; rose (hue 330) stays apart from
  violet (hue 275). Vs `ENEMY` red: close on purpose (both foes); the enemy rows of the team panel name them.
- Colour-blind note: blue for the ally is the safest pick for red-green colour blindness; the existing green / red own /
  enemy pair is unchanged (a colour-blind palette setting is a later backlog item, not in step 20).

---

## 3. Skirmish lobby (20.U1)

### 3.1 Mode switch (both modes)
- The main menu button reads **`Skirmish`** (was `Skirmish 1v1`). The skirmish panel's title reads `Skirmish` (Cinzel-less
  label 34 `GOLD`, unchanged style) and under it a **mode row**: two `_toggle_button`s `1v1` / `2v2` (150 x 44, one
  `ButtonGroup`, `allow_unpress false`), centred. Tooltips: `You against one bot on Crown Hollow.` / `You and an ally bot
  against two bots on <map name>. You command only your own kingdom.` (map name from 20.D1, `MenuFlow.MAP_2V2_NAME`).
- **1v1 mode**: today's content exactly (matchup line, YOU / ENEMY card rows, difficulty, trade row, Back / Start). The
  only change is the **options row** (3.5), which replaces the trade row in both modes.
- **2v2 mode**: section 3.2. Switching modes swaps the content (`visible`), the panel re-centres (it is in a
  `CenterContainer`), focus goes to `Start`. The last mode is remembered (3.7).
- While the skirmish panel is open (either mode) the main menu **tagline and its 20 px spacer are hidden** (the title
  stays): the 2v2 panel is 668 px tall and the column must fit 900 (title ~110 + 18 + 668 = 796, 52 px free top and bottom).
  The 1v1 panel with the mode row grows to about 670 px, so it needs the same room.

### 3.2 2v2 layout (panel 1200 x 668, centred: about (200, 180); `UIStyle.panel(parent, 24.0)`, VBox separation 14)
```
 224                                 784  816                                1376
 204  +--------------------------------- Skirmish -------------------------------+   title 34 GOLD
 264                        [ 1v1 ]  [ 2v2 ]                                     |   mode row 150 x 44
 322              Vessa & Torvald   vs   Malrik & Ysolde                         |   matchup font 18
 361      Map: Twin Hollow · about twice Crown Hollow · mirrors allowed          |   font 14 muted
 394  YOUR TEAM          You + an ally bot    ENEMY TEAM               Two bots  |   headers Cinzel 20
 430  +slot row: YOU----------------------+   +slot row: ENEMY 1------------------+   560 x 112
 550  +slot row: ALLY---------------------+   +slot row: ENEMY 2------------------+   560 x 112
 676       All bots  [Easy] [Normal] [Hard]        [ Random kingdoms ]          |   36 high
 726   Trade and guilds [On][Off]        Map life [On][Off]                     |   36 high
 776                        [  Back  ]   [   Start   ]                           |   48 high
 848  +---------------------------------------------------------------------------+
```
| Element | Rect / look |
|---|---|
| Title, mode row | As 3.1 (title h 46, mode row h 44) |
| Matchup line | Font 18, `modulate (1, 1, 1, 0.85)` like `foe_label`: `Vessa & Torvald  vs  Malrik & Ysolde` (you first, then your ally; enemies in slot order). A Random slot shows `?`: `Vessa & ?  vs  ? & Ysolde`. Mirrors repeat the name as it is (`Torvald & Vessa  vs  Torvald & Malrik`): the rows' colours tell them apart (est. <= 420 px) |
| Map line | Font 14 `(0.72, 0.68, 0.64)` (the card-row sub colour): `Map: <name> · about twice Crown Hollow · mirrors allowed` |
| Team columns | `HBoxContainer` separation 32; each column a `VBoxContainer` 560 wide, separation 8 |
| Team header | Row 560 x 28: `YOUR TEAM` Cinzel 20 `GOLD` / `ENEMY TEAM` Cinzel 20 `(0.95, 0.55, 0.45)` (the 1v1 ENEMY tag colour) left; right-aligned font 13 `(0.72, 0.68, 0.64)`: `You + an ally bot` / `Two bots` |
| Slot rows | 3.3; order: YOU, ALLY / ENEMY 1, ENEMY 2 |
| Bots row | `HBoxContainer` centred, separation 10: label `All bots` font 18 + three `_toggle_button`s 110 x 36 font 16 `Easy` / `Normal` / `Hard` (**not** a ButtonGroup: pressing one sets every bot's difficulty and then shows pressed only while all three bots share it); 24 px spacer; button `Random kingdoms` 200 x 36 font 16 (`_menu_button` style), tooltip `Pick a kingdom for each bot now (you can still change them).` |
| Options row | 3.5 |
| Actions | Unchanged: `Back` 180 x 48, `Start` 220 x 48 with the `GOLD` rim |

### 3.3 One slot row (560 x 112; offsets inside the row)
```
 0 6   16                 144      222      300      378      456    528   560
 +-+----------------------------------------------------------------------+ 0
 |S| ALLY                [tile ]  [tile ]  [tile ]  [tile ]  [ ?  ]       |  8  tiles 72 x 64
 |T| Bot · fights with you|FIRE  | |SHADOW| | ICE  | |NATURE| |RANDOM|     |
 |R| [#] Blue            +------+  +------+  +------+  +------+  +------+   |
 |I|                                                                      | 72
 |P| Torvald of Ice      [ Normal bot        v]  [ Style: Random     v]    | 78  OptionButtons 186 x 28 at x 144 / 342
 +-+----------------------------------------------------------------------+ 112
```
| Part | Rect in the row | Look |
|---|---|---|
| Row background | 0-560 x 0-112 | `UIStyle.slate_style(0.0)` (bg `slate_bg`, 1 px `frame_dark` border, radius 2). Not a button |
| Stripe | 6 x 112 at (0, 0) | Filled with the **slot colour** (2.1) |
| Role tag | (16, 8), Cinzel 20 | `YOU` `GOLD` / `ALLY` in `ALLY` lightened / `ENEMY 1`, `ENEMY 2` in `(0.95, 0.55, 0.45)` |
| Role line | (16, 34), font 13 `(0.72, 0.68, 0.64)` | `Your kingdom` / `Bot · fights with you` / `Bot` |
| Colour swatch | 12 x 12 at (16, 58) + font 12 muted at (34, 56) | Swatch filled in the slot colour, 1 px `groove` border; text `Green` / `Blue` / `Red` / `Rose`; tooltip `Your team colour: cool colours are friends, warm colours are foes.` |
| Wizard line | (16, 84), font 13 in the kingdom colour lightened 0.25 | `Torvald of Ice` (`KingdomCard.wizard_name_of` + `kingdom_name_of`); Random: `Random kingdom` in `text_muted` |
| Kingdom tiles | 5 tiles **72 x 64** at x **144, 222, 300, 378, 456** (x 144 + 78 i, gap 6, ending x 528), y 8 | `KingdomTile` (3.4); one `ButtonGroup` per row |
| Bot settings (bots only) | `OptionButton` 186 x 28 at (144, 78) and (342, 78), font 15 | Difficulty items `Easy bot` / `Normal bot` / `Hard bot` (ids 0-2 = `Commander.Difficulty`, default Normal); style items `Style: Random` / `Style: Balanced` / `Style: Rusher` (ids from `AIProfile` styles, `rush-balance.md` 6.1; default Random) plus any ally-only style 20.D3 adds (the list comes from `MenuFlow.bot_styles(role)`, 14.3). Tooltips: `How well this bot plays.` / `Random: Balanced, or a Rusher 25 % of the time.` |
| Your style line (YOU row only, instead of the two options) | (144, 82), font 13 `(0.92, 0.90, 0.86)`, max width 384, `clip_text` + ellipsis | The kingdom's play-style line (`KingdomCard.INFO[k].style`); Random: `A random kingdom, picked when the match starts.` |

### 3.4 Kingdom tile (`scripts/ui/menus/kingdom_tile.gd`, `class_name KingdomTile extends Button`; the `KingdomCard` look at 72 x 64)
- `static func create(k: StringName) -> KingdomTile` (`&"random"` allowed), `toggle_mode true`, `focus_mode ALL`, `text ""`,
  `CURSOR_POINTING_HAND`. Styles as `KingdomCard._apply_styles` with radius **6** and the top stripe **4 px**: normal bg
  `base.lerp(col, 0.10)` + rim `col` alpha 0.55 2 px, hover rim alpha 0.95, selected `GOLD` rim 3 px + `shadow_size 8`
  in `col` alpha 0.45, disabled grey (the card's disabled look + `Coming soon` tooltip line).
- Content: emblem 32 x 32 centred at (36, 26) (IconLibrary `emblems/<k>` or `UIStyle.draw_emblem` like the card's
  fallback, radius 13); wizard name font 11 centred at y 46 (`Vessa`, `Malrik`, `Torvald`, `Ysolde`), `text` when selected,
  `(0.78, 0.74, 0.70)` otherwise.
- Random tile: bg `panel_inner` token, rim `frame_metal`, stripe `frame_light`; a `?` Cinzel 30 `title` centred at (36, 24)
  and `Random` font 11 at y 46; selected = `GOLD` rim. Tooltip `Random kingdom\nPicked when the match starts (mirrors allowed).`
- Tooltip of a kingdom tile = `KingdomCard.tooltip_for(k)` (unchanged text).

### 3.5 Options row (both modes; replaces the 1v1 trade row)
`HBoxContainer` centred, separation 10, h 36:
- `Trade and guilds` font 18 + `On` / `Off` toggles **90 x 36** font 16 (one ButtonGroup), the existing tooltip `Trading
  posts, Bazaars, caravans, Magpies and the Greywater Lodges (skirmish only).`, pressed from `GameSettings.trade_enabled`,
  `pressed -> GameSettings.set_trade_enabled(on)` (unchanged calls).
- 32 px spacer, then `Map life` font 18 + `On` / `Off` 90 x 36: tooltip `Capture points, monster camps and epic beasts.
  The river always flows.`; bound to the new `GameSettings.map_life_enabled` (3.7).
- Est. width 150 + 2 x 90 + 32 + 80 + 2 x 90 + 4 x 10 = 662 px: fits the 1v1 panel (~964) and the 2v2 one (1152).

### 3.6 Random, defaults, start
- Defaults the first time: You = the 1v1 `player_kingdom` (Fire), Ally = Ice, Enemy 1 = the 1v1 `enemy_kingdom` (Shadow),
  Enemy 2 = Nature; every bot Normal, style Random. Unavailable kingdoms (`MainMenu.kingdom_available`) fall back as the 1v1
  does (`_pick_available`).
- `Random kingdoms` sets each **bot** row to a concrete random available kingdom now (visible; your row is untouched).
  The `?` tile is the hidden random: resolved at **Start** (uniform among available kingdoms, mirrors allowed) and kept for
  `F9` restarts of that match (`MenuFlow.slots` stores the resolved kingdom next to `&"random"`); a new match from the
  menu rolls again.
- `Start`: `MenuFlow.start_skirmish_2v2(tree, slots)` (3.7). Never disabled (there is always an available kingdom).
- Esc: back to the main panel (existing `_unhandled_input`).

### 3.7 Data and settings (20.U1)
- `MenuFlow` (static): `mode: StringName = &"1v1"`, `slots: Array[Dictionary]` (4 entries, index = slot 0 you, 1 ally,
  2 enemy 1, 3 enemy 2): `{ "role": &"you" / &"ally" / &"enemy", "team": int (14.1), "kingdom": StringName (&"random"
  allowed), "resolved": StringName, "difficulty": int, "style": StringName }`; `start_skirmish_2v2(tree, slots) -> Node`
  instances `SKIRMISH_2V2` (scene path from 20.D1), sets `mode`, `slots` (resolved kingdoms), `trade_enabled` and the map-
  life flags on the level **before** it enters the tree (like `apply_kingdoms`), and the restart hook re-applies them to a
  reloaded node named as the 2v2 root (name from 20.D1). Per-bot difficulty / style are read by the level from `slots`
  (preferred over naming bot nodes in MenuFlow); if 20.D3 keeps named Commander nodes, the hook sets each one's
  `difficulty` / `style` from the slot with the same team.
- `MenuFlow.bot_styles(role: StringName) -> Array` of `[id, label]`, default `[[&"random", "Random"], [&"balanced",
  "Balanced"], [&"rusher", "Rusher"]]`, extended by 20.D3 for the ally if it wants (14.3).
- `GameSettings`: `static var map_life_enabled := true` saved as `map_life_enabled`, `set_map_life_enabled(v)` (reads the
  file first like `set_trade_enabled`), `apply_map_life(level)` sets `points_enabled`, `camps_enabled`, `beasts_enabled`
  on the level when it has them (never `river_enabled`); `static var skirmish_mode := "1v1"` and `skirmish_slots := ""`
  (the 4 slots as a JSON string: kingdom, difficulty, style per slot) so the lobby opens as the player left it.
  `reset_defaults` sets map life on, mode 1v1, slots "".
- 1v1 start (`start_skirmish`) also calls `GameSettings.apply_map_life(level)`.

---

## 4. Team panel (20.U3, `scripts/ui/team_panel.gd`, `class_name TeamPanel extends Control`)

### 4.1 Placement and data
- `static func attach(hud: Node, selection: Node) -> TeamPanel` (lead glue / 20.U3 in `hud.gd`); a `Control` 240 x 194,
  anchored top-right (`offset_left -256`, `offset_right -16`, `offset_top 296`, `offset_bottom 490`), `mouse_filter IGNORE`
  on the holder. Shown only when the level reports a 2v2 (`level.get("mode") == &"2v2"` or `slots` has an ally), else
  `visible = false` and nothing runs (1v1 and missions without allies are untouched).
- Refresh at **10 Hz** (like the champion bar); HP text every frame is fine. `apply_skin()` re-applies tokens.
- Data: `level.slot_info(team)` (14.1) for names, kingdoms, wizard, state; `Economy.for_team(ALLY)` `pop_used`; a 1 Hz
  count of the ally's workers (group `"units"`, `team == ALLY`, `has_method("command_gather")`) and buildings (group
  `"buildings"`, `team == ALLY`, alive); the ally brain (group `"ally_brains"`, 14.2) for the status text and the order
  cooldowns.

### 4.2 Ally card (240 x 124 at (1344, 296); offsets inside the card)
```
 0  4 10          58  66                                   166      232 240
 +----------------------------------------------------------------------+ 0
 |S| +----------+     TORVALD                          ALLY · ICE   [F4]| 6
 |T| | portrait |     [=========== 310 / 420 ============]              | 26  HP bar 160 x 12
 |R| |  48 x 48 |     Army 24  ·  Workers 12                            | 42  font 12
 |I| +-----(3)--+     Defending your mark                               | 60  status font 12
 |P| [ /X\  ][  (U) ][  (!)  ][  \/  ]                                  | 80  buttons 52 x 38
 | | Attack  Defend   Help    Retreat                                   |
 +----------------------------------------------------------------------+ 124
```
| Part | Rect in the card | Look |
|---|---|---|
| Frame | 0-240 x 0-124 | A `Button` (`focus_mode NONE`) with the slot frame (3.3): normal `frame_metal` rim, hover `frame_light` + halo, pressed offset; inside `panel_inner` |
| Stripe | 3 x 116 at (4, 4) | `ALLY` colour (grey `(0.4, 0.4, 0.4)` when the ally is defeated) |
| Portrait | 48 x 48 at (10, 8) | 1 px `groove` border; radial gradient `ALLY` alpha 0.35 centre -> `panel_inner` edge; wizard icon `art/icons/units/<wizard id>.png` (`vessa`, `malrik`, `torvald`, `ysolde` exist) 44 x 44 inset 2, `LINEAR_WITH_MIPMAPS`; fallback: the kingdom emblem (`UIStyle.draw_emblem`, radius 18) in the kingdom colour |
| Level medallion | 22 x 22 hexagon centred at (54, 52) | As the champion slot's (`ui-champions.md` 3.2): fill `(0.15, 0.12, 0.05)`, 1.5 px `GOLD` edge, number Cinzel Bold 11 `GOLD`; greyed while the wizard is dead |
| Name | (66, 6), max width 100, Cinzel 15 | `TORVALD` in `ALLY` lightened (2.1), `clip_text` + ellipsis; `text_muted` when defeated |
| Tag | right edge x 206, y 9, font 10 `text_muted` | `ALLY · ICE` (kingdom name uppercased) |
| Key badge | 24 x 14 at (210, 7) | As the champion key badge: bg `(0, 0, 0, 0.75)`, 1 px `frame_dark`, radius 2, `F4` font 10 `GOLD` |
| HP bar | 160 x 12 at (66, 26) | `UIStyle.bar(HP, 12.0)`, text number font 10 outline 2: `310 / 420`. Wizard dead: value 0, text `Returns in 24 s` in `WARN` (from `slot_info.respawn_left`). Low HP (< 30 %): the 1.5 Hz fill pulse of 5.3 |
| Army line | (66, 42), font 12 | `Army ` `text_muted` + `24` `text` + `  ·  Workers ` `text_muted` + `12` `text`. Army = the ally economy's `pop_used` minus its workers' pop |
| Status line | (66, 60), font 12, max width 166, clip + ellipsis | The ally's state, first match wins: `Defeated` (`text_muted`) / `Under attack!` (`WARN`, alpha pulse 0.6-1.0 at 2 Hz, for 8 s after an alert, 5.1) / the ally brain's `status_text()` in its colour (table 4.3) / `Building up` (`text`) as fallback |
| Order buttons | 4 `Button`s **52 x 38** at (8, 80), (64, 80), (120, 80), (176, 80) | Slot frame (3.3) states; glyph 16 x 16 centred at (26, 12) in the kind colour (6.2); word font 10 `text` centred at y 24 (`Attack`, `Defend`, `Help`, `Retreat`; `Retreat` est. 38 px). Cooldown: the radial sweep of 6.2 (`ui-style.md`) over the glyph area (r 12 around (26, 12)) + seconds font 11 outline 3; ready flash on 0. Disabled (ally dead-and-defeated or ally brain missing): `modulate.a 0.45` |
| Hover | whole card | `frame_light` rim + halo; the portrait border becomes `trim_glow` |

### 4.3 Status texts (from `AllyBrain.status_text()`; the UI only colours them by the order kind)
| Ally state (20.D3) | Example text | Colour |
|---|---|---|
| Following your `attack` order | `Attacking your mark` | Fighting `(1.0, 0.55, 0.2)` |
| Following `defend` | `Defending your mark` | Guarding `(0.6, 0.75, 1.0)` |
| Following `help` | `Coming to help you` | `GOLD` |
| Following `retreat` | `Falling back` | `text_muted` |
| Own plan: attacking / defending / expanding / gathering | `Attacking Malrik` / `Defending its base` / `Taking an expansion` / `Gathering an army` | Fighting / Guarding / white / white |
The UI keys the colour on `current_order().kind` (or `status_kind()` if 20.D3 gives one) and falls back to white.

### 4.4 Enemy rows (240 x 30 at (1344, 426) and (1344, 460); enemy 1 then enemy 2)
```
 0  6   28    32                                         232 240
 +-----------------------------------------------------------+ 0
 | (emb) MALRIK   Shadow                          Lv 4       | 8
 +-----------------------------------------------------------+ 30
```
| Part | Rect | Look |
|---|---|---|
| Row | 240 x 30 | A flat `Button` (`focus_mode NONE`) with `UIStyle.slate_style(0.0, slot colour at alpha 0.6)` (1 px border in the slot colour), hover border alpha 1.0 |
| Emblem | 20 x 20 at (6, 5) | `UIStyle.draw_emblem` in the kingdom colour on a disc `(0, 0, 0, 0.45)` |
| Name | (32, 7), Cinzel 13 | `MALRIK` in the slot colour lightened (2.1), then font 11 `text_muted` ` Shadow` |
| Right text | right edge x 232, y 8, font 11 | Alive: `Lv 4` `text`. Wizard dead: `Fallen · 24 s` `WARN` (respawns are public: the 1v1 already announces them). Kingdom defeated: `Defeated` `text_muted`, the row at `modulate.a 0.5`, a 1 px `text_muted` line through the name |
| Click | row | `camera_rig.focus_on` the enemy wizard **only if it is visible** (`is_visible_in_tree()`), else its last seen keep ghost (group `"fog_ghosts"` matching the team, if any), else nothing. Never selects |
| Tooltip | section-8 | `Malrik  ·  Shadow  ·  enemy (red)` / `Level 4 · wizard alive` (or `returns in 24 s`) / `Kingdom standing` (or `Defeated at 18:20`) |
No enemy army or resource numbers (the fog decides what you know about enemies).

### 4.5 Card input, tooltip and key
- **Click** on the card (outside the buttons) or **F4** (physical `KEY_F4`, no modifiers; free in `CLAUDE.md` "Keys"): centre
  the camera on the ally wizard; if dead, on the ally keep; if defeated, nothing. **F4 twice within 0.4 s**: centre on the
  ally army's average position (the group-key "N N" rule). Never selects, never inspects (a world click inspects, 8.2).
  F4 is handled in `team_panel.gd` `_unhandled_key_input`, ignored while a window / pause / briefing is up (as Y).
- **Order buttons**: 6.4 (targeted for Attack / Defend, instant for Help / Retreat).
- **Card tooltip** (section-8 tooltip, opens to the **left** of the card, 8 px, clamped on screen), lines:
  1. `Torvald  [F4]` + right-aligned `ally · Ice`
  2. `Level 3 · HP 310 / 420 · Mana 90 / 120`
  3. `Army 24 pop · Workers 12 · Buildings 9`
  4. The status line in its colour (4.3)
  5. `Click: find Torvald · Alt+drag: order wheel` in `GOLD` (learn-hint look)
  Tests read the string (`\n`-joined).
- **Ally resources**: hidden (crystals, essence, gold are never shown). Reason: resources are separate (20.D1 default) and
  the player cannot act on them; the army / workers / buildings numbers answer "is my ally strong or struggling". If the
  user picks "show" (Q2), line 3 of the tooltip gains `· 420 crystals · 85 essence` and nothing else changes.

### 4.6 States and animations
| Event | Look |
|---|---|
| Ally under attack (5.1) | Card rim `WARN`, alpha pulse 0.6-1.0 at 2 Hz for 8 s; status `Under attack!`; stripe flashes white 0.2 s |
| Ally wizard falls | Portrait `modulate (0.55, 0.55, 0.55)` over 0.3 s, medallion grey, HP bar `Returns in 30 s` |
| Ally wizard returns | Back over 0.3 s; portrait pop 1.0 -> 1.08 -> 1.0 in 0.2 s |
| Ally level up | Medallion pop + gold ring (the champion-bar animation, 3.3 there) |
| Ally order accepted (6.7) | The pressed button's rim flashes `GOLD` 0.3 s; status updates |
| Ally order refused | The button shakes ±3 px 0.2 s (the bounty-chip shake) |
| Ally defeated | Card `modulate.a 0.6` over 0.5 s, stripe grey, status `Defeated`, buttons disabled |
| Enemy wizard falls / returns | Right text switches; the row flashes its border white 0.2 s |
| Enemy defeated | Row fades to 0.5 over 0.5 s, strike line draws left -> right in 0.3 s |

---

## 5. Notifications, objective line, help (20.U3)

### 5.1 Alerts (`scripts/ui/team_alerts.gd`, `class_name TeamAlerts extends Node`, group `"team_alerts"`)
Prefer the level's signal `team_alert(team: int, kind: StringName, pos: Vector3)` (14.1). Fallback when it does not exist:
a **2 Hz scan** of the ally's buildings (`hp` dropped since the last scan) and the ally wizard (`hp` dropped with a visible
foe unit within 12 m). One alert per **zone** (30 m cell) per **30 s**; the first alert of a fight wins.
| Kind | Message (`show_message`, s) | Also |
|---|---|---|
| Ally base / army under attack | `Your ally is under attack!` (3.0) | Minimap ping 3 rings in `WARN` at `pos` + an `ALLY`-coloured "!" marker for 4 s (7.4); `ally_alert.wav`; card pulse (4.6) |
| Ally wizard fallen | `Ally wizard fallen: Torvald returns in 30 s` (3.0) | `ally_fallen.wav`; card state |
| Ally wizard back | `Torvald is back` (2.0) | - |
| Ally kingdom destroyed | `Your ally's kingdom has fallen. Fight on!` (4.0) | `ally_fallen.wav`; card defeated |
| Enemy wizard fallen | `Enemy wizard fallen: Malrik` (2.5) | Row state (4.4) |
| Enemy kingdom destroyed | `Ysolde's kingdom has fallen` (4.0), then 2 s later `One enemy kingdom left` (3.0) | Row state; objective line |
| **Optional, same code**: your own base under attack | `Your base is under attack!` (3.0) | `WARN` minimap ping at `pos`. In the 1v1 too if the lead wants it (nothing tells the player today) |
- **Mirror names**: when two living wizards share a name, texts say `Ally Torvald` / `Enemy Torvald`
  (`TeamColors.display_name(team)`), never the bare name.
- **Level-up messages** (`hud.gd _check_hero_levels`): in the 2v2 only your wizard (`Vessa reaches level 3`) and your ally
  (`Torvald (ally) reaches level 3`) use the message line; an enemy level-up only pops the `Lv n` text of its team-panel
  row (scale 1.0 -> 1.3 -> 1.0 in 0.2 s). The 1v1 keeps today's rule.
- Messages still go through the single message line; alerts are spaced by the 30 s rule, replies by the ping cooldowns.

### 5.2 The ally's own pings and replies (from 20.D3)
- `AllyBrain.pinged(kind, pos, text)`: a marker in `ALLY` colour (6.5) + message `Torvald: Help me!` / `Torvald: Attack
  here!` (2.5 s; `text` from 20.D3, the UI prefixes the name) + the kind's sound. The UI caps them at one per 6 s.
- `AllyBrain.replied(kind, accepted, text)`: message `Torvald: "On my way."` (2.5 s, quotes added by the UI) +
  `ally_ack.wav` (accepted) / `ui_error.wav` (refused).

### 5.3 Your kingdom falls while your ally stands (only if 20.D1's defeat rule allows it; else skip)
- **Notice**: a heavy-frame panel 560 x 104 at (520, 300), no dim, margin 16: `YOUR KINGDOM HAS FALLEN` Cinzel 28
  `DEFEAT` centred at y 316; `Torvald fights on. Watch the battle, keep giving orders, or press F10 twice to leave.` font 15
  `text` centred, autowrap, at y 356. Fades in 0.3 s, stays 6 s, fades out 0.5 s. `defeat.wav` at -6 dB.
- After it: the hero column shows the wizard greyed with `Kingdom fallen` `text_muted` (no timer); selection empty,
  command card empty; **F1 / Space centre on the ally wizard**; the team panel stays live and **its order buttons and the
  ping wheel keep working** (you can still lead your ally); the fog is the team's (allied vision).
- F10 twice = leave: the end screen as `DEFEAT` (first press: `Press F10 again to leave (counts as a defeat)`).
- While both kingdoms stand, F10 twice surrenders the **team** (single player: your call): first press `Press F10 again
  to surrender (your team loses)`. Texts are the level's (`skirmish.gd`), listed here so they read the same everywhere.

### 5.4 Objective line (level text, systems / lead; listed for consistency)
```
Skirmish 2v2: <map name>
Destroy both enemy kingdoms · 2 of 2 standing
Ember Crown: worn by Malrik                      (the existing crown line)
```
`1 of 2 standing` after one enemy falls; after your own fall (5.3) line 2 reads `Your kingdom has fallen · Torvald fights
on`. Est. widths <= 380 px at font 17: the 511 px slate is unchanged. There is **no running score**: the team panel says
who still stands, the end screen compares (section 9).

### 5.5 Controls help: a 13th line (2v2 only)
`Alt+click: ping · Alt+drag / ² : order wheel · F4: ally` (the `²` / `` ` `` label from `KeyLabels.of(KEY_QUOTELEFT)`;
est. 395 px at font 13, under the 438 px widest line). `GameHUD.help_text(wizard_name, two_v_two := false)` appends it;
the panel becomes about **458 x 267** at (1126, 16). The 1v1 help is unchanged.

---

## 6. Pings and ally commands (20.U4: `scripts/ui/ally_pings.gd`, `class_name AllyPings extends Control`, group `"ally_pings"`; world markers `scripts/vfx/ping_markers.gd`)

### 6.1 Kinds
| Kind | id | Glyph (6.2) | Kind colour | Wheel place | Orders the ally? | Order cooldown | Marker life |
|---|---|---|---|---|---|---|---|
| Look here | `look` | Eye | `(0.95, 0.95, 0.95)` | centre | No (information; 20.D3 may use it to scout) | - | 3 s |
| Attack here | `attack` | Crossed blades | `(1.0, 0.45, 0.25)` | up | Yes: the ally attacks toward the spot | **8 s** | 5 s |
| Defend here | `defend` | Shield | `(0.6, 0.75, 1.0)` | right | Yes: the ally guards the spot | **8 s** | 5 s |
| Help me | `help` | `!` in a ring | `GOLD` | left | Yes: the ally sends its army to you | **20 s** | 6 s |
| Retreat | `retreat` | Chevron pointing down | `(0.85, 0.85, 0.80)` | down | Yes: the ally pulls its army back home | **10 s** | 4 s |
- The cooldowns are the UI's defaults; when the ally brain exposes `cooldown_left(kind)` / `cooldown_total(kind)` (14.2)
  the UI shows its numbers instead.
- **Spam guard** (all kinds, UI-side): at least 0.75 s between two pings; at most 4 pings in 8 s, then `Too many pings`
  (2.0 s, `ui_error.wav`) and nothing is placed.
- A command kind during its cooldown is **refused**: `Ally order ready in 4 s` (2.0 s) — no marker (a marker the ally
  ignores would mislead). `look` is never on cooldown.
- No ally, or the ally defeated: command kinds are refused with `Your ally has fallen`; `look` still works.

### 6.2 Glyphs (drawn in code in a box s x s, centre c; 1 px `groove` outline at s >= 14; used at 9, 14, 16, 22 px)
| Glyph | Shape |
|---|---|
| Eye | The bounty Explore eye (`ui-champions.md` 13.2): ellipse outline rx 0.42 s, ry 0.26 s + pupil r 0.12 s |
| Crossed blades | The Hunt glyph: two lines corner to corner at +-0.36 s, width `max(1.5, s / 8)`, plus two 0.14 s cross-guards |
| Shield | The Guard shield outline filled at alpha 0.35 + outline 1.5 px |
| `!` ring | Circle outline r 0.42 s, 1.5 px; bar (c.x - 0.06 s, c.y - 0.26 s)-(c.x + 0.06 s, c.y + 0.08 s) + dot r 0.07 s at c + (0, 0.2 s) |
| Chevron down | Polyline c + (-0.32 s, -0.16 s) -> c + (0, 0.18 s) -> c + (0.32 s, -0.16 s), width `max(2, s / 7)`, plus a shorter one 0.2 s above |
Filled / stroked in the **kind colour**. `AllyPings.draw_glyph(ci: CanvasItem, kind, c: Vector2, s: float, col)` is public
(the team panel, the minimap and the end screen reuse it); `glyph_texture(kind, px := 64) -> ImageTexture` bakes one for
the world marker (cached).

### 6.3 Input: Alt+click, Alt+drag wheel, the ² key
Handled in `ally_pings.gd` **`_input`** (before the GUI and the selection manager, so the minimap's `_gui_input` and the
selection's `_unhandled_input` never see a ping click); only while the 2v2 is on, no window / pause / briefing is up, no
targeted order or bounty mode is active (their clicks win).
| Input | Result |
|---|---|
| **Alt + left press** (world or minimap; Ctrl+Alt counts too: AltGr on AZERTY) | Records the press point `c` (screen) and the ping point `P`: minimap -> `minimap.map_to_world(local)`; world -> `selection.ground_point(pos)` (the ground under the cursor). Also records the thing under the cursor (`selection.unit_at` / building ray) for the context rule. Marks the event handled |
| Release before the mouse moved 12 px (a **tap**) | **Context ping**: a visible foe unit / building (or a fog ghost) under the press -> `attack`; your or your ally's building / unit -> `defend`; otherwise -> `look` |
| Mouse moves > 12 px while held | The **wheel** opens at `c` (6.4); release picks the hovered sector; release inside the dead zone = `look` |
| Hold the physical **`KEY_QUOTELEFT`** (`²` on AZERTY, `` ` `` on QWERTY; free in "Keys") | Same as an Alt press at the current mouse position; the wheel opens after 0.15 s held (or at once when the mouse moves 12 px); key release picks; a tap (< 0.15 s, no move) = context ping |
| Right-click or Esc while the wheel is open | Cancel (nothing sent) |
| Alt + right-click | Nothing (reserved) |
Alt+digit (group steal) is untouched: this handler only takes mouse buttons and `KEY_QUOTELEFT`.

### 6.4 The wheel (drawn by `ally_pings.gd` `_draw`, `z_index 20`, `mouse_filter IGNORE`)
```
                 ATTACK
             .----------.
           /  \  /X\   /  \          outer radius 64
     HELP |  (!)  (o)  (U) | DEFEND   inner (dead zone) 20
           \  /  \/   \  /
             '----------'
                RETREAT
            ATTACK HERE                label at c + (0, 82)
```
| Part | Look |
|---|---|
| Centre | `c` clamped so the whole wheel stays on screen (90 px from every edge) |
| Sectors | 4 wedges of 90° centred on up / right / down / left, between radius 20 and 64: `draw_colored_polygon` (24 arc points) filled `slate_bg` at alpha 0.92; 1 px `frame_metal` lines on the outer circle, the inner circle and the 4 diagonals |
| Hovered sector | Direction of the mouse from `c` when the distance > 20 px: fill = kind colour alpha 0.30; outer arc 2 px `GOLD`; glyph scale 1.15 |
| Glyphs | 22 px at radius 42 in each sector's direction, kind colour |
| Cooling sector | Glyph alpha 0.4; seconds font 12 `text` outline 3 under the glyph (`ceili`) |
| Dead zone | Disc r 18 `panel_inner` alpha 0.9, eye glyph 14 px white alpha 0.8; hovered (mouse within 20 px): rim 1.5 px `GOLD` |
| Pointer line | 1 px `GOLD` alpha 0.6 from `c` to the mouse while outside the dead zone |
| Label | Cinzel 14 `title` outline 3 centred at `c + (0, 82)`: `ATTACK HERE` / `DEFEND HERE` / `HELP ME` / `RETREAT` / `LOOK HERE`; cooling: + ` · ready in 4 s` font 12 `WARN`; no ally: + ` · no ally` font 12 `text_muted` (command sectors dimmed) |
| Open / close | Fade in 0.08 s + scale 0.9 -> 1.0 (pivot `c`); closes at once |
| Minimap wheels | Same wheel at the mouse; `P` stays the map point pressed |

### 6.5 World marker (`scripts/vfx/ping_markers.gd`, `class_name PingMarkers extends Node3D`, group `"ping_markers"`)
- `static func attach(hud: Node) -> PingMarkers` (adds itself to the level); `add(kind: StringName, pos: Vector3, color:
  Color, life: float) -> void`. Pool of **6** markers (a 7th replaces the oldest); a new ping of the same pinger within 3 m
  of a live one replaces it.
- **Ground ring**: a flat `QuadMesh` 4 x 4 m at `(x, 0.22, z)` (above the capture rings at 0.20), `cast_shadow OFF`, a
  shared unshaded ring shader (depth test on): radius tweens 0.4 -> 1.6 m in 0.35 s (ease out), width 0.14 m, colour =
  the **pinger's** slot colour alpha 0.9, then alpha pulse 0.6-0.9 at 2 Hz; a second faint ring expands 1.6 -> 3.0 m every
  1.0 s while its alpha falls 0.5 -> 0.
- **Icon**: a `Sprite3D` billboard at y 2.6, `no_depth_test`, `pixel_size 0.012` (0.77 m for 64 px), texture = a 64 x 64
  image: disc r 28 in the pinger colour darkened 0.6, 3 px rim in the pinger colour, the kind glyph at 36 px in the kind
  colour; drops from y 4.0 to 2.6 in 0.25 s (ease out back), then bobs +-0.08 m at 1.5 Hz.
- Fade: the whole marker's alpha 1 -> 0 over its last 0.5 s, then hidden (pooled).
- A refused order (6.7) greys the marker: ring and icon desaturate to `(0.6, 0.6, 0.6)` over 0.2 s, life cut to 1.5 s.

### 6.6 Minimap marker and off-screen arrow
- Minimap (20.U2 API, 7.4): `minimap.add_marker(pos, pinger_color, kind, life)`: the 3 expanding rings of `ping()` in the
  pinger colour, then the kind glyph at **9 px** on a disc r 5 (pinger colour darkened 0.5, 1 px pinger-colour rim) for
  the life, fading over the last 0.5 s. `look` pings use the rings only.
- **Off-screen arrow** (`ally_pings.gd`): while a live marker's point projects outside the view rect **(24, 60)-(1576,
  612)** (or behind the camera), a 28 x 28 arrow sits on that rect's edge on the line from the rect centre to the point: a
  disc r 12 in the pinger colour darkened 0.5 with a 2 px pinger-colour rim, the glyph at 14 px, and an 8 px triangle tip
  pointing outward; alpha pulse 0.7-1.0 at 2 Hz; **click** = `camera_rig.focus_on(pos)` (the arrows are the only
  `mouse_filter STOP` part of this Control). At most 3 arrows (newest first).

### 6.7 Sending, replies, the ally order line
- On a placed ping: marker (6.5) + minimap marker (6.6) + the kind's sound (section 11) + for command kinds
  `AllyBrain.request(kind, P) -> String` (14.2): `""` = sent (the reply may come later through `replied`), else the reason
  at once (`show_message(reason, 2.0)`, marker greyed).
- Your own pings are never messages (you know what you clicked); the ally's reply is (5.2).
- **Ally order line** (drawn by the minimap, 7.4): while `AllyBrain.current_order()` is a player order (`attack`,
  `defend`, `help`), a dashed line from the ally army's centre to the order point.

### 6.8 Order buttons of the ally card (6.1 kinds, 4.2 buttons)
| Button | Click | Point sent |
|---|---|---|
| Attack | Enters **ping targeting**: `Input.CURSOR_CROSS`, every other pending order cancelled, the chip (below) follows the mouse; left-click on the world or the minimap = send; right-click / Esc = cancel. Shift+click does not stay | The clicked ground / map point |
| Defend | Same | The clicked point |
| Help | Sent at once | Your wizard's position if alive, else the average of your army (the F2 set), else your keep |
| Retreat | Sent at once | The ally army's average position (the bot decides where "home" is) |
- **Targeting chip** (chip style, mouse + (18, 12), height 26, `z_index 10`): glyph 16 px + font 13: kind word in the kind
  colour + ` · click the map or the world` `text`; cooling / no ally: the reason in `WARN` (as the bounty chip's refusals).
- Button tooltips (section-8): `Attack here  [Alt+drag up]\nClick, then click the map or the world: Torvald attacks
  there.\nCooldown 8 s` / `Defend here  [Alt+drag right]\n...Torvald guards that spot.\nCooldown 8 s` / `Help me  [Alt+drag
  left]\nTorvald sends his army to you.\nCooldown 20 s` / `Retreat  [Alt+drag down]\nTorvald pulls his army back home.\n
  Cooldown 10 s` (+ the reason line in `WARN` while refused). The pronoun comes from the wizard (`his` / `her`:
  Vessa, Ysolde = her; Malrik, Torvald = his) via `TeamColors.pronoun(team)`.

---

## 7. Minimap for four players and a bigger map (20.U2, `minimap.gd`)

### 7.1 Scale rule (the panel never moves: 240 x 240 at (16, 644), draw area 220 x 220 at (26, 654))
- The level publishes its bounds: `map_bounds() -> Rect2` (world x / z: `position` = the min corner, `size` = width x
  depth; 14.1), else the constant `MAP_SIZE` (square, centred on 0) as today.
- `scale = 220 / max(width, depth)` px per metre; the map picture `R` = `(width x scale, depth x scale)`, **centred** in the
  220 x 220 area. `world_to_map` / `map_to_world` use `R` and the bounds; clicks outside `R` clamp to its nearest edge.
- Outside `R` (letterbox bands of a non-square map): `panel_inner` darkened 0.35, and a 1 px `frame_dark` line along `R`'s
  edge (the sunken-map lines of `ui-style.md` 7.1 run around `R`, not the whole area).
- **Icon sizes stay in pixels** (3 / 4 / 5 / 6 px squares, diamonds, glyphs): on a bigger map the dots cover more metres but
  stay readable. Anything given **in metres** is converted with `scale` (in `ui-mapfill.md` 9.1 the tower sight ring
  `22 x 1.833` becomes `22 x scale`, the lair ring `(r + 3) x 1.833` becomes `(r + 3) x scale`; the ping max radius stays
  12 px).
| Map | Scale | Picture | 3 x 3 dot covers |
|---|---|---|---|
| Crown Hollow 120 x 120 (1v1) | 1.833 px/m | 220 x 220 | 1.6 m |
| **~170 x 170** (2x area, square) | 1.294 px/m | 220 x 220 | 2.3 m |
| 192 x 144 (2x area, 4:3) | 1.146 px/m | 220 x 165 | 2.6 m |
| 240 x 120 (2x area, two Crown Hollows side by side) | 0.917 px/m | 220 x 110 | 3.3 m |
**Note for 20.D1** (map designer, working in parallel): any size works, but a **square or at most 4:3** map keeps the
minimap useful (a 2:1 map wastes half the minimap and halves the detail). Keep base / node / camp **proportions** of Crown
Hollow; the UI only needs `map_bounds()`.
- Fog texture: the fog's own bounds and grid (`FogOfWar.bounds() -> Rect2` and `grid_size()`, 14.1; fallback
  `+-MAP_HALF` as today) drawn over its rect with `NEAREST`. River mask: `RiverSystem.mask_image()` over `mask_rect()`
  (fallback: the map bounds). Roads unchanged (world points).
- Camera bounds: `RTSCamera.bounds` = the map bounds shrunk by 2 m, set by `hud.setup` from `map_bounds()` when the level
  has it (today the scene's export `Rect2(-58, -58, 116, 116)`). `BountyMode.valid` Explore check uses the same bounds
  instead of `MAP_HALF_FALLBACK`.

### 7.2 Units, heroes, champions, caravans, flags
| Thing | 1v1 (unchanged) | 2v2 |
|---|---|---|
| Unit square 3 x 3 (4 x 4 selected) | own green / enemy red | `TeamColors.of_team(u.team)` (only your own units can be selected) |
| Wizard diamond 6 x 6 | own gold, enemy violet | Own gold (unchanged); ally / enemies: slot colour lightened 0.2 + 1 px `GOLD` outline; enemies only while visible |
| Champion circle r 2.5 + gold ring | own / enemy | Slot colour + gold ring |
| Caravan 4 x 3 (+ gold dot) | own / enemy | Slot colour |
| Bounty flag coin + team ring | own / enemy ring | Ring in the slot colour; ally flags shown like own ones (allied vision) |
| Hunt-warning ping (`_scan_hunt_pings`) | enemy boards hunting you | Boards of **foe** teams only (`TeamColors.is_foe(board.team)`): an ally's board must never ping you. Hunts on your ally's things ping only if 20.D1 says so (default no) |
| `drawn_enemy_icons` counter | team != PLAYER | Foes only; new counters `drawn_ally_icons`, `drawn_enemy2_icons` |

### 7.3 Buildings
- 1v1: `PLAYER_TEAM_COLOR` / `ENEMY_TEAM_COLOR` as today.
- 2v2: the slot colour **darkened 0.25** (you `(0.23, 0.75, 0.30)`, ally `(0.23, 0.49, 0.75)`, enemy `(0.75, 0.23, 0.23)`,
  enemy 2 `(0.75, 0.30, 0.56)`), same sizes (3-6 px from the footprint), construction sites hollow, plus a 1 px `groove`
  outline so a base reads as a block next to its units. Fog ghosts stay `GHOST_COLOR` (they no longer say whose, as
  today).

### 7.4 Markers, pings and the ally order line
- `ping(world: Vector3, color := WARN)`: the existing 3 expanding rings, now coloured (alerts `WARN`, pings the pinger's
  colour, beasts `BEAST`).
- `add_marker(world: Vector3, color: Color, kind: StringName, life: float)`: rings + the glyph (6.6); drawn on the overlay
  (redrawn every frame only while a marker lives, like the pings). Counter `markers_drawn`.
- **Ally order line**: at 4 Hz read `AllyBrain.current_order()`; while its kind is `attack`, `defend` or `help` and it came
  from the player: a dashed line (4 px on, 3 px off, 1 px wide) in `ALLY` alpha 0.7 from the ally army centre
  (`order.from` if 20.D3 gives it, else the average of visible ally non-worker units) to `order.pos`, and the kind glyph
  at 7 px at `order.pos`. Hidden when the order ends. `ally_line_drawn: bool` for tests.
- Alt+click / Alt+drag on the minimap are taken by `ally_pings.gd` before `_gui_input` (6.3): the minimap needs no input
  change.

---

## 8. Allied units and buildings: selection and right-click rules (20.U5)

### 8.1 Rules
Assumes the team model of 14.1 (the ally has its own team value). "Ally thing" = anything with `team == ALLY`
(units, wizard, champions, buildings, caravans, flags).
| Action | On an ally unit / wizard / champion | On an ally building | Note |
|---|---|---|---|
| Left-click | **Inspect** (read-only single view): `selection.inspected = it` (the 9.C8 mechanism), `selected` empty | **Inspect** building view: new `selection.inspected_building` (8.3) | Esc clears, any other selection clears |
| Shift+click, box select, double-click, Ctrl+N / Shift+N / Alt+N, F2, F3, N N | **Skipped** (never added) | Skipped | Most checks already test `team == PLAYER`; `is_commandable_unit` stays the gate |
| Right-click with own units | A plain **move** to the ground point under it (never attack, never follow) | Move; workers: no drop-off, no build / repair help (unless 20.D1 allows repair) | Today's code attacks anything with `team != PLAYER` (`selection_manager.gd` target checks near lines 2037 / 2201): must become `TeamColors.is_foe(target.team)` |
| A / X + click | Attack-move to the ground point (never attacks allies) | Same | |
| Spells (F / Q / E) | Friendly spells (heals, shields, haste) may target ally units if gameplay allows (`command_cast` decides); foe-only spells refuse `Invalid target` as today | | UI shows gameplay's reason |
| Items (Numpad 1-6) | As spells | | |
| Bounty mode (R) | Whatever `BountyBoard.kind_for` answers (Escort / Guard on ally things if 20.D1 allows, else `Invalid target`) | Same | No UI rule of its own |
| Caravans (right-click an ally Bazaar / post it holds) | Move only, unless 20.D1 allows allied trade | | |
| Hover | Default arrow, no attack cross, no red ring | Same | |
| Rally (building selected, right-click an ally unit / building) | Rally to that ground point | | |

### 8.2 Ally unit / wizard / champion inspect (`selection_panel.gd`)
- The existing read-only views (`inspected_unit()` single view, champion view, wizard view) with:
  - Portrait rim `ALLY` (2.3).
  - Name row: Cinzel 20 `title` name + font 14 in `ALLY` lightened: ` · ally (Torvald)` (units, buildings) / ` · your ally`
    (the ally wizard).
  - Ally wizard: HP, mana, level, stat line, the 3 spell slots read-only **with** their cooldown sweeps (it is your team),
    the items read-only (the enemy-champion item rule of `ui-champions.md` 4), no learn chips, no `+` points chip.
  - Ally champions: the own-champion view (intent, purse shown: allied info) but the command card never offers `R` raise
    on its flags.
- Enemy-2 things use the enemy views (rim `ENEMY_2` darkened 0.15).
- `current_view()` returns `"ally_unit"`, `"ally_wizard"`, `"ally_building"` for tests (enemy ones unchanged).

### 8.3 Ally building inspect (`selection_manager.gd` + `selection_panel.gd`)
- `selection.inspected_building: Node3D` (null when none), set by a left-click on an ally building, cleared as `inspected`.
- View = the building view (portrait, name, HP) with: name row ` · ally (Torvald)`; the **training queue read-only**
  (5 slots, icons, progress on slot 1; no `x` cancel, no hover cancel); no `Rally:` line; a line (696, 792) font 13
  `text_muted`: `Owner: Torvald (ally) · you can't give it orders`.
- Construction site: progress bar only, no `Cancel` button.

### 8.4 Command card while inspecting an ally thing (`command_card.gd`)
All 12 slots empty (`slot_ids()` all `""`) and the centred text block of `ui-champions.md` 4 (y 740 / 762):
`Your ally's unit.` / `Your ally's building.` / `Your ally, Torvald.` font 14 `text_muted`, then
`Ping: Alt+click  ·  Ally orders: team panel` font 13 `text`. `inspect_text()` returns both lines.

---

## 9. End screen with four columns (20.U6, `scripts/ui/end_table.gd`, `class_name EndTable extends VBoxContainer`)

### 9.1 When
`hud.show_banner` already calls `level.end_screen_text()`; when the level **also** has `end_screen_table()` (14.1) the HUD
hides `end_body` and adds an `EndTable` (guarded `attach_optional`-style load) under the rule; `end_panel.custom_minimum_size
= (900, 0)`. The 1v1 is unchanged.

### 9.2 Layout (panel min width 900, margin 24; everything centred in it)
```
                         V I C T O R Y                                  Cinzel Bold 64 (unchanged)
                     Your team won in 23:41                             font 18 text
                 ---------------------------------                      the 400 px rule (unchanged)
                         YOUR TEAM          ||        ENEMY TEAM        Cinzel 16
                    [VS]         [TV]       ||    [MA]         [YS]      icons 32
                    VESSA        TORVALD    ||    MALRIK       YSOLDE    Cinzel 15 slot colour
                    Fire · you   Ice · ally ||    Shadow ·     Nature ·  font 12 muted
                                 Normal     ||    Hard ·Rush.  Normal
 Result             Standing     Standing   ||    Fell 18:20   Fell 23:41
 Units trained        61           48       ||      52           57
 Units lost           33           29       ||      71           64
 Enemy units killed   58           44       ||      30           32
 ...
                          F9: play again                                 font 20 muted (unchanged)
```
| Part | Rect / look |
|---|---|
| Subtitle | Font 18 `text`, under the banner: `Your team won in 23:41` / `Your team was defeated at 23:41` / `You left the match at 12:02` (the level's `subtitle`) |
| Grid | `GridContainer` 6 columns: label column **210** px, value columns **150** px (you, ally), team gap **24** px (a 2 px `frame_dark` vertical line centred in it, full table height), value columns 150 px (enemy 1, enemy 2). Total 210 + 4 x 150 + 24 = **834** px |
| Team header row | h 26: `YOUR TEAM` Cinzel 16 `GOLD` centred over the two left value columns; `ENEMY TEAM` Cinzel 16 `(0.95, 0.55, 0.45)` over the right two |
| Player header | h 64 per column, centred: wizard icon 32 x 32 (the ally-card portrait rule, 2 px ring in the slot colour); name Cinzel 15 in the slot colour lightened (`VESSA`); font 12 `text_muted`: `Fire · you` / `Ice · ally · Normal` / `Shadow · Hard · Rusher` (difficulty + resolved style for bots) |
| Result row | h 26; label `Result` font 16 `text_muted`; values font 16: `Standing` `NEAR` / `Fell at 18:20` `WARN` / `Surrendered 12:02` `WARN` / `Left 12:02` `text_muted` |
| Stat rows | h 26 each; label font 16 `text_muted` left-aligned; values number font 18 `text` right-aligned in their column (8 px padding); **best value of the row among the 4** in `GOLD` (all tied values gold; rows marked `best: &"min"` such as `Units lost` use the smallest); `0` in `text_muted`; every other row a bg `panel_inner` alpha 0.5 across the table |
| Rows (in order; a row is present when the level sends it) | `Units trained`, `Units lost` (min), `Enemy units killed`, `Buildings destroyed`, `Crystals gathered`, `Wizard level`, `Wizard deaths` (min), `Champions hired` (champions on), `Gold earned` (trade on), `Points held at the end` (map life on), `Camps cleared`, `Game hunted` |
| Footer | `F9: play again` font 20 `text_muted` (unchanged string) |
Height: banner ~76 + subtitle 26 + rule 2 + headers 26 + 64 + result 26 + 12 x 26 + footer 30 + VBox gaps (12 x 6)
+ margins 48 ~ **680 px** (fits 900). Width 834 + 48 = 882 (min 900).
- Numbers: thousands with the thin space (`SelectionPanel.thousands`).
- Test helper `EndTable.table_text() -> String`: one line per row, cells joined by ` | ` (headers included).

---

## 10. Settings and what the level must set (summary)
| Where | What | Task |
|---|---|---|
| `GameSettings` | `map_life_enabled`, `skirmish_mode`, `skirmish_slots` (+ setters, save / load / reset), `apply_map_life(level)` | 20.U1 |
| `MenuFlow` | `mode`, `slots`, `start_skirmish_2v2`, `bot_styles(role)`, restart hook for the 2v2 root, `MAP_2V2_NAME`, `SKIRMISH_2V2` | 20.U1 |
| Level (20.D1 / systems) | `mode`, `slots`, `slot_info`, `map_bounds`, `team_alert`, `end_screen_table`, the objective text, the F10 texts | 14.1 |
| `SettingsPanel` | Nothing new (Map detail stays where step 12 put it) | - |

---

## 11. Audio (20.U3 / 20.U4; placeholders generated like the trade ones, `assets/audio/`, every player `bus = &"SFX"`)
| Sound | File | When | Rule |
|---|---|---|---|
| Look ping | `ping_look.wav` (0.15 s soft wooden tick) | `look` placed (yours or the ally's) | -10 dB |
| Attack ping | `ping_attack.wav` (0.35 s two sharp brass hits) | `attack` placed | -6 dB |
| Defend ping | `ping_defend.wav` (0.4 s low bell) | `defend` | -6 dB |
| Help ping | `ping_help.wav` (0.5 s rising double chime, urgent) | `help` (the ally's "help me" too) | -4 dB |
| Retreat ping | `ping_retreat.wav` (0.4 s two falling notes) | `retreat` | -6 dB |
| Ally acknowledges | `ally_ack.wav` (0.2 s soft rising click) | `replied(..., accepted = true)` | -8 dB |
| Refused | existing `sfx/ui_error.wav` | a refused ping / order | -6 dB |
| Ally under attack | `ally_alert.wav` (0.8 s three war-drum hits + short horn) | alert (5.1); also the optional own-base alert | once per 30 s |
| Ally fallen | `ally_fallen.wav` (1.0 s low gong) | ally wizard fallen, ally kingdom destroyed | once per 5 s |
| Your kingdom fallen | existing `sfx/defeat.wav` | 5.3 notice | -6 dB |
2D `AudioStreamPlayer`s (pings are HUD feedback); the same sound at most once per 0.5 s.

---

## 12. Sizes at 1600 x 900 (summary; new things only)
| Thing | Size / position |
|---|---|
| Lobby panel (2v2) | 1200 x 668 centred (~(200, 180)); team columns 560 wide at x 224 / 816, gap 32; headers h 28; slot rows 560 x 112 at y ~430 / ~550 |
| Slot row parts | stripe 6 x 112; role tag Cinzel 20 (16, 8); role line font 13 (16, 34); swatch 12 at (16, 58); wizard line (16, 84); tiles 72 x 64 at x 144 / 222 / 300 / 378 / 456, y 8; options 186 x 28 at (144, 78) / (342, 78); your style line (144, 82) w 384 |
| Lobby rows | mode 2 x 150 x 44; bots row toggles 110 x 36 + `Random kingdoms` 200 x 36; options toggles 90 x 36; Back 180 x 48, Start 220 x 48 |
| Team panel | 240 x 194 at (1344, 296); ally card 240 x 124; enemy rows 240 x 30 at y 426 / 460 |
| Ally card parts | stripe 3 x 116 at (4, 4); portrait 48 at (10, 8); medallion 22 centred (54, 52); name Cinzel 15 (66, 6) w 100; tag right edge 206 y 9; key badge 24 x 14 at (210, 7); HP bar 160 x 12 at (66, 26); army (66, 42); status (66, 60) w 166; buttons 52 x 38 at x 8 / 64 / 120 / 176, y 80 (glyph 16 at (26, 12), word font 10 y 24) |
| Enemy row parts | emblem 20 at (6, 5); name Cinzel 13 (32, 7); right text right edge 232, y 8 |
| Help panel (2v2) | 458 x 267 at (1126, 16), 13 lines |
| Kingdom-fallen notice | 560 x 104 at (520, 300) |
| Ping wheel | outer r 64, dead zone r 20, glyphs 22 at r 42, label at c + (0, 82); 90 px screen margin |
| Ping chip / arrows | chip mouse + (18, 12) h 26; arrows 28 x 28 on the rect (24, 60)-(1576, 612) |
| World marker | ring quad 4 x 4 m at y 0.22 (r 0.4 -> 1.6 m, width 0.14 m); icon `Sprite3D` 64 px, pixel_size 0.012, y 2.6 |
| Minimap | scale `220 / max(w, d)`, picture centred; marker glyph 9 px on disc r 5; ally line dashes 4 / 3 px, glyph 7 px |
| End screen (2v2) | min width 900; grid 210 + 150 x 2 + 24 + 150 x 2; rows h 26; header h 64; icons 32 |

---

## 13. For ui-coder: element -> file -> data source / API
| Element | Task / file | Data source (API owner in brackets) |
|---|---|---|
| Mode switch, 1v1 content kept | 20.U1 `main_menu.gd` | `MenuFlow.mode` |
| 2v2 panel, slot rows, bots row | 20.U1 new `scripts/ui/menus/lobby_2v2.gd` (`class_name Lobby2v2 extends VBoxContainer`, built by `main_menu.gd`) | `KingdomCard.INFO`, `MainMenu.kingdom_available`, `MenuFlow.bot_styles(role)` [20.D3 extends], `TeamColors` |
| Kingdom tiles | 20.U1 new `scripts/ui/menus/kingdom_tile.gd` | `KingdomCard.INFO`, `UIStyle.kingdom_color`, `IconLibrary` emblems |
| Options row (trade, map life) | 20.U1 `main_menu.gd`, `game_settings.gd` | `GameSettings.trade_enabled`, `map_life_enabled`; level flags `points_enabled`, `camps_enabled`, `beasts_enabled` [exist] |
| Start / restart | 20.U1 `menu_flow.gd` | `SKIRMISH_2V2` scene, level `mode` / `slots` properties, root node name [20.D1] |
| Slot colours, relation, names, pronouns | 20.U2 new `scripts/ui/team_colors.gd` (`class_name TeamColors extends RefCounted`) | `Unit.Team` values + `Unit.are_allies(a, b)` [20.D1 / lead contract]; `level.slot_info(team)` [20.D1] |
| Side colours in the strip, point panel, rings | 20.U2 `mapfill_bar.gd`, `point_panel.gd`, `scripts/vfx/capture_rings.gd` | `TeamColors.is_friend(point.owner_team)` |
| Minimap scale, letterbox, fog / mask rects | 20.U2 `minimap.gd` | `level.map_bounds()` [20.D1], `FogOfWar.bounds()` / `grid_size()` [systems], `RiverSystem.mask_rect()` [systems] |
| Minimap slot colours, hero diamonds, counters | 20.U2 `minimap.gd` | `TeamColors` |
| `ping(world, color)`, `add_marker(...)`, ally order line | 20.U2 `minimap.gd` | `AllyBrain.current_order()` [20.D3] |
| Camera bounds, Explore check | 20.U2 `rts_camera.gd` (set from `hud.setup`, see U3), `bounty_mode.gd` | `level.map_bounds()` [20.D1] |
| Team panel: ally card, enemy rows, F4 | 20.U3 new `scripts/ui/team_panel.gd` | `level.slot_info(team)` (name, kingdom, wizard, level, hp, max_hp, mana, alive, respawn_left, defeated, defeated_at) [20.D1]; `Economy.for_team(ALLY).pop_used`; groups `"units"` / `"buildings"`; `AllyBrain.status_text()`, `current_order()`, `cooldown_left(kind)`, `cooldown_total(kind)` [20.D3] |
| Alerts, messages, level-up filter | 20.U3 new `scripts/ui/team_alerts.gd`, `hud.gd` | `level.team_alert(team, kind, pos)` [20.D1] (fallback 2 Hz scan); `AllyBrain.pinged`, `replied` [20.D3] |
| Kingdom-fallen notice, F1 / Space on the ally | 20.U3 `hud.gd` (notice), 20.U5 `selection_manager.gd` (F1 / Space) | `level.kingdom_defeated(team)` signal + `team_state(team)` [20.D1] |
| Help line 13 | 20.U3 `hud.gd` | static text + `KeyLabels.of(KEY_QUOTELEFT)` |
| HUD glue | 20.U3 `hud.gd` | guarded `attach_optional` for `team_panel.gd`, `team_alerts.gd`, `ally_pings.gd`, `ping_markers.gd`, `end_table.gd`; camera bounds from `map_bounds()` |
| Ping input, wheel, chip, arrows, spam guard | 20.U4 new `scripts/ui/ally_pings.gd` | `selection.ground_point`, `unit_at`, building ray, `get_pending_order`, `bounty_mode.active`; `minimap.map_to_world`, `get_global_rect`; `AllyBrain.request(kind, pos) -> String` [20.D3] |
| World markers | 20.U4 new `scripts/vfx/ping_markers.gd` | - |
| Ping sounds | 20.U4 `assets/audio/ping_*.wav`, `ally_ack.wav` | - |
| Alert sounds | 20.U3 `assets/audio/ally_alert.wav`, `ally_fallen.wav` | - |
| Ally selection rules, right-click fix, `inspected_building` | 20.U5 `selection_manager.gd` | `TeamColors.is_foe / relation`, `is_commandable_unit` |
| Ally inspect views | 20.U5 `selection_panel.gd` | `TeamColors`, `level.slot_info` |
| Ally text block | 20.U5 `command_card.gd` | `selection.inspected` / `inspected_building` + `TeamColors.relation` |
| 4-column end screen | 20.U6 new `scripts/ui/end_table.gd` | `level.end_screen_table()` [20.D1 / systems], `stats_of(team)` (exists) |

---

## 14. APIs needed from the other step-20 specs (for the lead to relay)

### 14.1 From 20.D1 (map + rules) / systems / the lead's contract
1. **Team model**: per-player `team` values (`Unit.Team` gains `ALLY` = 3 and `ENEMY_2` = 4, appended so `PLAYER` 0 /
   `ENEMY` 1 / `NEUTRAL` 2 keep their numbers), `static func Unit.are_allies(a: int, b: int) -> bool` (PLAYER+ALLY,
   ENEMY+ENEMY_2; NEUTRAL with nobody), `is_enemy_of` through it; `Economy`, `EssenceBank`, `GoldBank`, `ChampionGuild`,
   `BountyBoard` stay per team (so the player's top bar / guild / board keep reading team 0). **If 20.D1 instead keeps
   `team` = side and adds an owner slot**, every `team == PLAYER` check in `selection_manager.gd`, `minimap.gd`,
   `command_card.gd`, `top_bar.gd`, `selection_panel.gd`, `champion_bar.gd`, `bounty_mode.gd` must switch to the owner: a
   much bigger UI change (tell the ui-coder before 20.U5 starts).
2. Level (the 2v2 skirmish node): `mode: StringName` (`&"2v2"`), `slots: Array[Dictionary]` (set by the menu before
   `_ready`, 3.7), `slot_info(team) -> Dictionary` `{name, kingdom, wizard: Node, wizard_id, level, alive, respawn_left,
   defeated: bool, defeated_at: float, role, side}`, `team_state(team) -> StringName` (`&"standing"` / `&"defeated"` /
   `&"surrendered"` / `&"left"`), signals `kingdom_defeated(team)` and `team_alert(team, kind, pos)` (kinds `&"attacked"`,
   `&"wizard_fallen"`, `&"wizard_back"`), `map_bounds() -> Rect2`, `end_screen_table() -> Dictionary` (9.2 fields:
   `subtitle`, `columns` [{team, name, kingdom, wizard_id, role, detail, result, result_kind}], `rows` [{label, values,
   best}], `footer`), the objective text of 5.4 and the F10 texts of 5.3, `MAP_2V2_NAME`, the scene path and root node name.
3. `FogOfWar`: variable bounds (`bounds()`, `grid_size()`), **allied vision** (team 0's `is_visible` includes the ally's
   sight; enemy things the ally sees get `visible = true`); `RiverSystem.mask_rect()`.
4. Defeat rule and the "own kingdom fallen, ally stands" state (5.3): the UI needs to know it exists (`team_state(0)`).
5. Points / crown / blessings in the 2v2: `owner_team` may be any team; the UI maps it to a side with `are_allies`.

### 14.2 From 20.D3 (ally bot)
An ally brain reachable in group **`"ally_brains"`** (one per allied bot; `team` property):
`request(kind: StringName, pos: Vector3) -> String` (`""` = accepted, else the reason text shown as is; kinds `&"attack"`,
`&"defend"`, `&"help"`, `&"retreat"`, `&"look"`), `cooldown_left(kind) -> float`, `cooldown_total(kind) -> float`,
`current_order() -> Dictionary` `{kind, pos, from: Vector3, by_player: bool}` (empty when none), `status_text() -> String`
(+ optional `status_kind() -> StringName`), signals `replied(kind, accepted: bool, text: String)` and `pinged(kind, pos,
text)` (its own pings to the player, at most one per 6 s). Optional: an ally-only bot style id for the lobby list.

### 14.3 From the lead
`CLAUDE.md` "Keys": add **Alt+click / Alt+drag = ping and ally order wheel, ² / ` (physical `KEY_QUOTELEFT`) = the same
wheel, F4 = find your ally**. The lobby button rename `Skirmish 1v1` -> `Skirmish` (tests that look for the old text).

### 14.4 From gameplay (handoff; `unit.gd` is gameplay's)
`Unit.team_color(t)` and `team_hp_color(t)` return the 2.3 colours for `ALLY` and `ENEMY_2` (the world selection ring and
HP bars).

---

## 15. Tasks (all ui-coder; build after 20.D1 / 20.D3 land and the 2v2 scene exists)
| Task | Files (only these) | Done when |
|---|---|---|
| **20.U1 Lobby** | `scripts/ui/menus/main_menu.gd`, `menu_flow.gd`, `game_settings.gd`, new `scripts/ui/menus/lobby_2v2.gd`, new `kingdom_tile.gd` | The main button reads `Skirmish`; the mode switch shows the unchanged 1v1 content or the 2v2 panel of 3.2 (1200 x 668, two columns of slot rows at the rects of 3.3 / section 12); tiles select per row (Random included), bot difficulty and style options, `All bots` and `Random kingdoms` work; tagline hidden while the panel is open; options row with `Trade and guilds` (unchanged calls) and `Map life`; the matchup line with `?` and mirror names; Start calls `start_skirmish_2v2` with 4 resolved slots set before `_ready`; F9 restart keeps them; the lobby reopens as left (saved mode / slots); test `tests/test_20.U1.gd` reads the rects at 1600 x 900 and starts a 2v2 with a Random slot |
| **20.U2 Colours + minimap** | new `scripts/ui/team_colors.gd`, `minimap.gd`, `mapfill_bar.gd`, `point_panel.gd`, `scripts/vfx/capture_rings.gd`, `rts_camera.gd`, `bounty_mode.gd` | `TeamColors` API of 2.1 (1v1 answers unchanged); minimap scale / letterbox / clamp from `map_bounds()` with the table of 7.1 checked for a 170 x 170 and a 240 x 120 rect; fog and river rects; slot colours for units, heroes (gold outline), champions, caravans, flags, buildings (darkened, outlined); foe-only hunt pings; coloured `ping()`, `add_marker()`, the ally order line; counters; side colours + `Held by your ally`; camera bounds and Explore check from the map bounds; `PERF OK` with 4 players' icons; every existing minimap / map-fill UI test passes |
| **20.U3 Team panel + alerts + HUD glue** | new `scripts/ui/team_panel.gd`, new `scripts/ui/team_alerts.gd`, `hud.gd`, `assets/audio/ally_alert.wav`, `ally_fallen.wav` | Team panel at (1344, 296) only in the 2v2, ally card parts at the offsets of 4.2, states of 4.6, statuses coloured (4.3), enemy rows (4.4), click / F4 / F4 F4 centre, the 5-line tooltip; alerts and messages of 5.1 with the 30 s zone rule, mirror names, ally level-ups only; ally pings / replies as messages (5.2); kingdom-fallen notice (5.3); help line 13 and the 458 x 267 panel; guarded glue for the U4 / U6 files and the camera bounds; test `tests/test_20.U3.gd` (fake level with `slot_info`) |
| **20.U4 Pings + ally orders** | new `scripts/ui/ally_pings.gd`, new `scripts/vfx/ping_markers.gd`, `assets/audio/ping_*.wav`, `ally_ack.wav` | Alt+tap context ping (attack / defend / look), Alt+drag wheel (sectors, dead zone, label, cooldown seconds, cancel), the ² key hold / tap, minimap presses give map points and never move the camera; spam guard and refusals (6.1); world marker (ring, icon, drop, bob, fade, pool of 6, grey on refusal); minimap markers through `add_marker` (guarded); off-screen arrows clickable; card-button targeting with the chip; `AllyBrain.request` called with kind and point, replies handled; sounds (11); the team panel's buttons call `AllyPings.begin_command(kind)` (group `"ally_pings"`); test `tests/test_20.U4.gd` with a fake ally brain |
| **20.U5 Allied selection rules** | `selection_manager.gd`, `selection_panel.gd`, `command_card.gd` | The table of 8.1: ally things inspect on click and are never selected / boxed / grouped / F2-ed; right-click and A-click on them = move / attack-move to the point (the `team != PLAYER` attack checks now use `TeamColors.is_foe`); `inspected_building` with the read-only building view (8.3); ally unit / wizard / champion views (8.2) with `current_view()` names; command card text block (8.4); F1 / Space centre on the ally wizard after your kingdom fell; test `tests/test_20.U5.gd`: a right-click on an ally unit never calls `command_attack`, box select skips ally units |
| **20.U6 End screen** | new `scripts/ui/end_table.gd` (the glue line in `hud.gd` is 20.U3's) | With `end_screen_table()`: subtitle, the 6-column grid of 9.2 (widths, team gap line, headers with icons, result row, stat rows, best value gold, zebra), footer; panel min width 900 and height <= 700 at 1600 x 900; `table_text()`; without it the 1v1 end screen is unchanged; test `tests/test_20.U6.gd` with a fake table |
Order: U2 first (TeamColors is used by all), then U1 / U3 / U4 / U5 / U6 in parallel (no shared files: `hud.gd` is only
U3's, `minimap.gd` only U2's; U4 reaches the minimap and the team panel only through `has_method` / groups).

---

## Questions for the user (max 3; recommendation first)
1. **Team colours for four players.** (A, recommended) *Cool = friends, warm = foes*: you green, ally blue, enemy 1 red,
   enemy 2 rose — green / red stay as in the 1v1. (B) StarCraft-style: you green, ally yellow, both enemies red (simpler,
   but yellow clashes with the many gold things: crown, bounties, beasts, shrines). (C) Every player in their kingdom's
   colour (orange, violet, ice blue, green) and friend / foe only from the ground rings.
2. **Your ally's resources on screen.** (A, recommended) Hidden: the ally card shows the wizard, army size, workers and
   what the ally is doing, not its crystals / essence / gold (you can't use them). (B) Shown in the ally card's tooltip
   only. (C) A small second line under your top bar with the ally's crystals and pop.
3. **How you ping and give orders to your ally.** (A, recommended) Alt+click = quick ping, Alt+drag (or holding the ²
   key) = the 4-way wheel Attack / Defend / Help me / Retreat, plus the four buttons on the ally card and F4 to find your
   ally. (B) Only the four buttons on the ally card (click, then click the map). (C) The wheel on a letter key instead of
   Alt (for example N), buttons kept.

## Notes for the lead
- The "your kingdom fell, your ally still stands" state (5.3) only exists if 20.D1's defeat rule says a team loses when
  **both** kingdoms are down; if 20.D1 picks "you lose when your kingdom falls", skip 5.3 and the `Left` result.
- The optional own-base `Your base is under attack!` alert (5.1) costs nothing once `team_alert` exists and would also help
  the 1v1; say if the 1v1 should get it.
- Story Episode 2 (the 2v1 -> 2v2 turn): the team panel, pings and end table only need a level that answers `slots` /
  `slot_info`, so a mission can reuse them (Old Vey, an autonomous ally, would show in the ally card with its order
  buttons hidden if the mission has no ally brain).

> **Lead note (2026-09-26):** the team encoding is frozen in map-2v2.md section 4: team = seat, Team enum appended with ALLY = 3 and ENEMY_2 = 4, sides from a static Teams class, Unit.are_allies(a, b). This spec's assumption matches it.

# UI: Wave Strike HUD (M2 Muster panel, task WS2.D1 for WS2.U1)

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
| Hint line | (600, 860) font 12 `text_muted` | `Key / click = buy  ·  Ctrl = rank up  ·  Alt / right-click = sell  ·  I = enemy roster` (French may wrap: max 2 lines, font 11 if wider than 794) |

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
Unchanged: W A S D Q E F, Space, F1, T, J, Tab, F9 / F12. `,` `.` `/` by physical keycode (`KEY_COMMA`, `KEY_PERIOD`,
`KEY_SLASH`); the AZERTY labels come from `KeyLabels`, never hard-coded. Keys act only while no `LineEdit` has focus and the
match is not over (as M1).

## 6. Readability (1080p and 1440p)
`canvas_items` stretch keeps the 1600 x 900 layout: at 1920 x 1080 everything is x1.2 (smallest text font 9 -> 10.8 px, OK),
at 3440 x 1440 x1.6. Minimum sizes kept: card icon 64, key badge 14 tall, numbers >= font 12. Panel width 994 never grows;
French strings get the wrap / shrink rules of 1.1 and the two-line buttons of 1.3; test with `-- --lang=fr` in the UI Lab.

## Done when
- [ ] WS2.D1 (this spec): 10-slot panel with groups / lock / states, card anatomy, Coffer + tier buttons, horn ring, field
  counter, enemy peek, tooltips, key table G / U / I.
- [ ] WS2.U1 (ui-coder): panel 994 x 224 at (590, 660) with the rects of 1-3; the 10 physical keys + Ctrl / Alt + G / U / I
  pressed in `test_ws_ui` (slot 10 empty on Fire refuses quietly); `KeyLabels` labels on every badge; the 1.2 states
  switch on affordable / locked / maxed / bought; UI Lab shot `ws_buy` for Fire and Ice (10 cards, lock on T3, held warning)
  with no FAIL in English and French; M1 top-right panel removed; every string through `Loc` and merged in `data/i18n/fr/`.

# UI Lab scorecard

2026-10-06 09:59:45 · lab v2.0 · 132 s

## Result: **FAIL** · quality **90 / 100**

1 FAIL · 2 WARN · 15 PASS · 0 skipped

Contact sheet (rows = resolutions, columns = screens, frame = worst status): [contact_sheet.jpg](contact_sheet.jpg)

## Improve next
1. **Off-screen on settings** (FAIL): anchor it to the screen edge it belongs to, or clamp its position to the viewport. e.g. SettingsPanel > Label "Off by default. When on, each ..": 78 px outside the 1600x900 screen (at 1600x900)
2. **Bleed-through on pause** (WARN): make the modal panel opaque, put a dimmer behind it, or hide the HUD text while it is open. e.g. StrIntPanel > Label "Choose your path (locked for t..": shows through the modal panel PauseMenu > PanelContainer (background alpha 0.92 < 0.95) (at 1600x900)
3. **Icon contrast on settings** (WARN): give the off state a visible track / outline; icons need a lighter or darker core than their button. e.g. SettingsPanel > CheckButton "Fullscreen": switch (off): only 16 % of the icon area is drawn (min 25 %): the track / outline is invisible, the control reads as empty (at 1600x900)

## Matrix (status, items found)
| Screen @ resolution | Text overflow | Off-screen | Overlaps | Min font size | Contrast | Tooltips | Hotkeys | Bottom-bar gaps | Bleed-through | Icon contrast | Edge margin | Shot |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| settings @ 1600x900 | PASS | **FAIL** 2 | PASS | PASS | PASS | PASS | - | - | PASS | **WARN** 2 | PASS | [jpg](1600x900/settings.jpg) |
| pause @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | **WARN** 3 | PASS | PASS | [jpg](1600x900/pause.jpg) |

## Rules
| Check | Rule | Fix hint |
|---|---|---|
| Text overflow | text fits its own rect and its frame (tol 2 px) | widen the frame / label, shorten the text, or allow wrapping |
| Off-screen | every text / button fully on screen | anchor it to the screen edge it belongs to, or clamp its position to the viewport |
| Overlaps | no two text / button rects overlap (>= 12 % of the smaller, >= 24 px2) | move one of them, or hide the lower-priority one while the other shows |
| Min font size | effective size >= 11 px (FAIL < 9) | raise the font size (ui-style.md sizes: 12+) |
| Contrast | WCAG AA: 4.5 (small) / 3.0 (large >= 24 px); FAIL under 2/3 of that | brighter text, darker / more opaque panel, or a 2-3 px outline |
| Tooltips | abbreviated / icon buttons have a tooltip (in-game: every button) | set tooltip_text (the action, its key and its cost) |
| Hotkeys | no letter twice on the command card; help keys unique outside a context | give each slot its own key; in the help, qualify context keys ("Flag: Z raise") |
| Bottom-bar gaps | HUD: no empty gap > 25 % of the width between the bottom panels (FAIL > 40 %) | anchor the bottom panels to the screen width (stretch the centre bar or spread the blocks), so ultrawide has no hole |
| Bleed-through | modal panels: no outside text drawn over them or visible through them (bg alpha >= 0.95) | make the modal panel opaque, put a dimmer behind it, or hide the HUD text while it is open |
| Icon contrast | switches / check boxes / icon buttons: 3:1 inside the icon (WCAG 1.4.11), FAIL < 2 | give the off state a visible track / outline; icons need a lighter or darker core than their button |
| Edge margin | big panels are flush with a screen edge or >= 8 px from it | move it clear of the edge (>= 8 px; shrink it at small sizes) or flush it |

## Details (FAIL / WARN cells, up to 8 items each)

**settings @ 1600x900 · Off-screen: FAIL (2)**
- SettingsPanel > Label "Off by default. When on, each ..": 78 px outside the 1600x900 screen
- SettingsPanel > Button "Back": 132 px outside the 1600x900 screen

**settings @ 1600x900 · Icon contrast: WARN (2)**
- SettingsPanel > CheckButton "Fullscreen": switch (off): only 16 % of the icon area is drawn (min 25 %): the track / outline is invisible, the control reads as empty
- SettingsPanel > CheckButton "Help improve the game: record ..": switch (off): only 17 % of the icon area is drawn (min 25 %): the track / outline is invisible, the control reads as empty

**pause @ 1600x900 · Bleed-through: WARN (3)**
- StrIntPanel > Label "Choose your path (locked for t..": shows through the modal panel PauseMenu > PanelContainer (background alpha 0.92 < 0.95)
- StrIntPanel > Button "STRENGTH  +15 % attack damage ..": shows through the modal panel PauseMenu > PanelContainer (background alpha 0.92 < 0.95)
- StrIntPanel > Button "INTELLECT  +15 spell power (+1..": shows through the modal panel PauseMenu > PanelContainer (background alpha 0.92 < 0.95)

## Window sizes obtained
- 1600x900 -> 1600x900

## Notes
- 1600x900: match clock stuck at 0 s

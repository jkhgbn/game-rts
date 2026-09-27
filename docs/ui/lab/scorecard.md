# UI Lab scorecard

2026-09-27 07:44:07 · lab v2.0 · 74 s

## Result: **FAIL** · quality **96 / 100** (previous run 96, +0)

2 FAIL · 8 WARN · 96 PASS · 6 skipped

Contact sheet (rows = resolutions, columns = screens, frame = worst status): [contact_sheet.jpg](contact_sheet.jpg)

## Improve next
1. **Contrast on hud** (FAIL): brighter text, darker / more opaque panel, or a 2-3 px outline. e.g. CommandCard > Label "Q": 3.61 : 1 (rule 4.5; text 816c37 on 191310) (inside a disabled button: WARN only) (at 1600x900, 1920x1080)
2. **Bleed-through on end_score** (WARN): make the modal panel opaque, put a dimmer behind it, or hide the HUD text while it is open. e.g. SelectionPanel > Label "4 selected:  1 Vessa, Fire Wiz..": shows through the modal panel GameHUD > PanelContainer (background alpha 0.92 < 0.95) (at 1600x900)
3. **Min font size on hud** (WARN): raise the font size (ui-style.md sizes: 12+). e.g. ChampionBar > Label "F5": 10.0 px (min 11) (at 1600x900, 1920x1080)
4. **Hotkeys on hud** (WARN): give each slot its own key; in the help, qualify context keys ("Flag: Z raise"). e.g. help key G: gather; trade (caravans) (at 1600x900, 1920x1080)
5. **Edge margin on skirmish_setup** (WARN): move it clear of the edge (>= 8 px; shrink it at small sizes) or flush it. e.g. MainMenu > PanelContainer: 4 px from the bottom edge (flush it or keep >= 8 px) (at 1600x900)
6. **Icon contrast on settings** (WARN): give the off state a visible track / outline; icons need a lighter or darker core than their button. e.g. SettingsPanel > CheckButton "Fullscreen": switch (off): only 16 % of the icon area is drawn (min 25 %): the track / outline is invisible, the control reads as empty (at 1600x900, 1920x1080)

## Matrix (status, items found)
| Screen @ resolution | Text overflow | Off-screen | Overlaps | Min font size | Contrast | Tooltips | Hotkeys | Bottom-bar gaps | Bleed-through | Icon contrast | Edge margin | Shot |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| main_menu @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1600x900/main_menu.jpg) |
| skirmish_setup @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | **WARN** 1 | [jpg](1600x900/skirmish_setup.jpg) |
| settings @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | PASS | **WARN** 1 | PASS | [jpg](1600x900/settings.jpg) |
| hud @ 1600x900 | PASS | PASS | PASS | **WARN** 3 | **FAIL** 10 | PASS | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1600x900/hud.jpg) |
| pause @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | PASS | PASS | PASS | [jpg](1600x900/pause.jpg) |
| end_score @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | **WARN** 5 | PASS | PASS | [jpg](1600x900/end_score.jpg) |
| main_menu @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1920x1080/main_menu.jpg) |
| skirmish_setup @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1920x1080/skirmish_setup.jpg) |
| settings @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | PASS | **WARN** 1 | PASS | [jpg](1920x1080/settings.jpg) |
| hud @ 1920x1080 | PASS | PASS | PASS | **WARN** 3 | **FAIL** 11 | PASS | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1920x1080/hud.jpg) |
| pause @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | PASS | PASS | PASS | [jpg](1920x1080/pause.jpg) |
| end_score @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | PASS | PASS | PASS | [jpg](1920x1080/end_score.jpg) |
| main_menu @ 3440x1440 | SKIP | - | - | - | - | - | - | - | - | - | - | - |
| skirmish_setup @ 3440x1440 | SKIP | - | - | - | - | - | - | - | - | - | - | - |
| settings @ 3440x1440 | SKIP | - | - | - | - | - | - | - | - | - | - | - |
| hud @ 3440x1440 | SKIP | - | - | - | - | - | - | - | - | - | - | - |
| pause @ 3440x1440 | SKIP | - | - | - | - | - | - | - | - | - | - | - |
| end_score @ 3440x1440 | SKIP | - | - | - | - | - | - | - | - | - | - | - |

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

**skirmish_setup @ 1600x900 · Edge margin: WARN (1)**
- MainMenu > PanelContainer: 4 px from the bottom edge (flush it or keep >= 8 px)

**settings @ 1600x900 · Icon contrast: WARN (1)**
- SettingsPanel > CheckButton "Fullscreen": switch (off): only 16 % of the icon area is drawn (min 25 %): the track / outline is invisible, the control reads as empty

**hud @ 1600x900 · Min font size: WARN (3)**
- ChampionBar > Label "F5": 10.0 px (min 11)
- ChampionBar > Label "F6": 10.0 px (min 11)
- ChampionBar > Label "F7": 10.0 px (min 11)

**hud @ 1600x900 · Contrast: FAIL (10)**
- CommandCard > Label "Q": 3.61 : 1 (rule 4.5; text 816c37 on 191310) (inside a disabled button: WARN only)
- CommandCard > Label "E": 3.58 : 1 (rule 4.5; text 856f38 on 221912) (inside a disabled button: WARN only)
- ChampionBar > Label "F5": 3.69 : 1 (rule 4.5; text bc9b4c on 583f25)
- **FAIL** ChampionBar > Label "Hire a champion": 3.00 : 1 (rule 4.5; text 746863 on 251f24)
- **FAIL** ChampionBar > Label "Tavern opens at 2:00": 2.70 : 1 (rule 4.5; text 7a6e67 on 352e2e)
- **FAIL** ChampionBar > Label "Hire a champion": 2.15 : 1 (rule 4.5; text 85786b on 4f4639)
- **FAIL** ChampionBar > Label "Tavern opens at 2:00": 2.13 : 1 (rule 4.5; text 85786c on 50473b)
- **FAIL** ChampionBar > Label "Hire a champion": 2.19 : 1 (rule 4.5; text 84776b on 4d443a)
- ... 2 more

**hud @ 1600x900 · Hotkeys: WARN (1)**
- help key G: gather; trade (caravans)

**end_score @ 1600x900 · Bleed-through: WARN (5)**
- SelectionPanel > Label "4 selected:  1 Vessa, Fire Wiz..": shows through the modal panel GameHUD > PanelContainer (background alpha 0.92 < 0.95)
- SelectionPanel > Button "VF": shows through the modal panel GameHUD > PanelContainer (background alpha 0.92 < 0.95)
- SelectionPanel > Button "CH": shows through the modal panel GameHUD > PanelContainer (background alpha 0.92 < 0.95)
- SelectionPanel > Button "CH": shows through the modal panel GameHUD > PanelContainer (background alpha 0.92 < 0.95)
- SelectionPanel > Button "CH": shows through the modal panel GameHUD > PanelContainer (background alpha 0.92 < 0.95)

**settings @ 1920x1080 · Icon contrast: WARN (1)**
- SettingsPanel > CheckButton "Fullscreen": switch (off): only 16 % of the icon area is drawn (min 25 %): the track / outline is invisible, the control reads as empty

**hud @ 1920x1080 · Min font size: WARN (3)**
- ChampionBar > Label "F5": 10.0 px (min 11)
- ChampionBar > Label "F6": 10.0 px (min 11)
- ChampionBar > Label "F7": 10.0 px (min 11)

**hud @ 1920x1080 · Contrast: FAIL (11)**
- CommandCard > Label "Q": 3.61 : 1 (rule 4.5; text 816b36 on 1a120f) (inside a disabled button: WARN only)
- CommandCard > Label "E": 3.58 : 1 (rule 4.5; text 856f38 on 221912) (inside a disabled button: WARN only)
- ChampionBar > Label "F5": 3.69 : 1 (rule 4.5; text bd9b4b on 593f23)
- **FAIL** ChampionBar > Label "Hire a champion": 2.62 : 1 (rule 4.5; text 7d6f66 on 3d302c)
- **FAIL** ChampionBar > Label "Tavern opens at 2:00": 2.15 : 1 (rule 4.5; text 85786c on 4f463b)
- ChampionBar > Label "F6": 4.04 : 1 (rule 4.5; text b49a4a on 443b21)
- **FAIL** ChampionBar > Label "Hire a champion": 2.19 : 1 (rule 4.5; text 84776b on 4d443a)
- **FAIL** ChampionBar > Label "Tavern opens at 2:00": 2.21 : 1 (rule 4.5; text 84776b on 4d433a)
- ... 3 more

**hud @ 1920x1080 · Hotkeys: WARN (1)**
- help key G: gather; trade (caravans)

## Skipped
- main_menu @ 3440x1440 overflow (screen too small for 3440x1440 (got 1920x1080))
- skirmish_setup @ 3440x1440 overflow (screen too small for 3440x1440 (got 1920x1080))
- settings @ 3440x1440 overflow (screen too small for 3440x1440 (got 1920x1080))
- hud @ 3440x1440 overflow (screen too small for 3440x1440 (got 1920x1080))
- pause @ 3440x1440 overflow (screen too small for 3440x1440 (got 1920x1080))
- end_score @ 3440x1440 overflow (screen too small for 3440x1440 (got 1920x1080))

## Window sizes obtained
- 1600x900 -> 1600x900
- 1920x1080 -> 1920x1080
- 3440x1440 -> 1920x1080

## Notes
- **3440x1440 NOT CHECKED**: the window came out 1920x1080 (screen 1920x1080). Run this size on a screen at least that big (desktop ultrawide).

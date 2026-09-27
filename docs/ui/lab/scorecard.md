# UI Lab scorecard

2026-09-26 23:57:04 · lab v1.0 · 82 s

## Result: **FAIL** · quality **96 / 100** (previous run 96, +0)

3 FAIL · 6 WARN · 102 PASS · 0 skipped

Contact sheet (rows = resolutions, columns = screens, frame = worst status): [contact_sheet.jpg](contact_sheet.jpg)

## Improve next
1. **Contrast on hud** (FAIL): brighter text, darker / more opaque panel, or a 2-3 px outline. e.g. CommandCard > Label "Q": 3.61 : 1 (rule 4.5; text 816c37 on 191310) (inside a disabled button: WARN only) (at 1600x900, 1920x1080, 3440x1440)
2. **Min font size on hud** (WARN): raise the font size (ui-style.md sizes: 12+). e.g. ChampionBar > Label "F5": 10.0 px (min 11) (at 1600x900, 1920x1080, 3440x1440)
3. **Hotkeys on hud** (WARN): give each slot its own key; in the help, qualify context keys ("Flag: Z raise"). e.g. help key G: gather; trade (caravans) (at 1600x900, 1920x1080, 3440x1440)

## Matrix (status, items found)
| Screen @ resolution | Text overflow | Off-screen | Overlaps | Min font size | Contrast | Tooltips | Hotkeys | Shot |
|---|---|---|---|---|---|---|---|---|
| main_menu @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](1600x900/main_menu.jpg) |
| skirmish_setup @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](1600x900/skirmish_setup.jpg) |
| settings @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](1600x900/settings.jpg) |
| hud @ 1600x900 | PASS | PASS | PASS | **WARN** 3 | **FAIL** 10 | PASS | **WARN** 1 | [jpg](1600x900/hud.jpg) |
| pause @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](1600x900/pause.jpg) |
| end_score @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](1600x900/end_score.jpg) |
| main_menu @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](1920x1080/main_menu.jpg) |
| skirmish_setup @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](1920x1080/skirmish_setup.jpg) |
| settings @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](1920x1080/settings.jpg) |
| hud @ 1920x1080 | PASS | PASS | PASS | **WARN** 3 | **FAIL** 11 | PASS | **WARN** 1 | [jpg](1920x1080/hud.jpg) |
| pause @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](1920x1080/pause.jpg) |
| end_score @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](1920x1080/end_score.jpg) |
| main_menu @ 3440x1440 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](3440x1440/main_menu.jpg) |
| skirmish_setup @ 3440x1440 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](3440x1440/skirmish_setup.jpg) |
| settings @ 3440x1440 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](3440x1440/settings.jpg) |
| hud @ 3440x1440 | PASS | PASS | PASS | **WARN** 3 | **FAIL** 9 | PASS | **WARN** 1 | [jpg](3440x1440/hud.jpg) |
| pause @ 3440x1440 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](3440x1440/pause.jpg) |
| end_score @ 3440x1440 | PASS | PASS | PASS | PASS | PASS | PASS | - | [jpg](3440x1440/end_score.jpg) |

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

## Details (FAIL / WARN cells, up to 8 items each)

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

**hud @ 1920x1080 · Min font size: WARN (3)**
- ChampionBar > Label "F5": 10.0 px (min 11)
- ChampionBar > Label "F6": 10.0 px (min 11)
- ChampionBar > Label "F7": 10.0 px (min 11)

**hud @ 1920x1080 · Contrast: FAIL (11)**
- CommandCard > Label "Q": 3.61 : 1 (rule 4.5; text 816b36 on 1a120f) (inside a disabled button: WARN only)
- CommandCard > Label "E": 3.58 : 1 (rule 4.5; text 856f38 on 221912) (inside a disabled button: WARN only)
- ChampionBar > Label "F5": 3.67 : 1 (rule 4.5; text c3984a on 68371f)
- **FAIL** ChampionBar > Label "Hire a champion": 2.62 : 1 (rule 4.5; text 7d6f66 on 3d302c)
- **FAIL** ChampionBar > Label "Tavern opens at 2:00": 2.15 : 1 (rule 4.5; text 85786c on 4f463b)
- ChampionBar > Label "F6": 4.03 : 1 (rule 4.5; text b59a49 on 453b1e)
- **FAIL** ChampionBar > Label "Hire a champion": 2.19 : 1 (rule 4.5; text 84776b on 4d443a)
- **FAIL** ChampionBar > Label "Tavern opens at 2:00": 2.21 : 1 (rule 4.5; text 84776b on 4d433a)
- ... 3 more

**hud @ 1920x1080 · Hotkeys: WARN (1)**
- help key G: gather; trade (caravans)

**hud @ 3440x1440 · Min font size: WARN (3)**
- ChampionBar > Label "F5": 10.0 px (min 11)
- ChampionBar > Label "F6": 10.0 px (min 11)
- ChampionBar > Label "F7": 10.0 px (min 11)

**hud @ 3440x1440 · Contrast: FAIL (9)**
- CommandCard > Label "Q": 3.61 : 1 (rule 4.5; text 816c37 on 191310) (inside a disabled button: WARN only)
- CommandCard > Label "E": 3.58 : 1 (rule 4.5; text 846f3b on 1f1818) (inside a disabled button: WARN only)
- **FAIL** ChampionBar > Label "Hire a champion": 2.77 : 1 (rule 4.5; text 796d65 on 332a2b)
- **FAIL** ChampionBar > Label "Tavern opens at 2:00": 2.74 : 1 (rule 4.5; text 7b6d65 on 362b2a)
- **FAIL** ChampionBar > Label "Hire a champion": 2.74 : 1 (rule 4.5; text 7a6d66 on 352b2c)
- **FAIL** ChampionBar > Label "Tavern opens at 2:00": 2.78 : 1 (rule 4.5; text 796d65 on 332a29)
- **FAIL** ChampionBar > Label "Hire a champion": 2.80 : 1 (rule 4.5; text 786c65 on 30292b)
- **FAIL** ChampionBar > Label "Tavern opens at 2:00": 2.68 : 1 (rule 4.5; text 7c6e65 on 392e2b)
- ... 1 more

**hud @ 3440x1440 · Hotkeys: WARN (1)**
- help key G: gather; trade (caravans)

## Window sizes obtained
- 1600x900 -> 1600x900
- 1920x1080 -> 1920x1080
- 3440x1440 -> 3440x1440

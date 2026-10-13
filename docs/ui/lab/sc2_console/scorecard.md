# UI Lab scorecard

2026-10-13 16:35:30 · lab v2.0 · 261 s

## Result: **WARN** · quality **85 / 100**

0 FAIL · 24 WARN · 36 PASS · 0 skipped

Contact sheet (rows = resolutions, columns = screens, frame = worst status): [contact_sheet.jpg](contact_sheet.jpg)

## Improve next
1. **Contrast on hud_keep** (WARN): brighter text, darker / more opaque panel, or a 2-3 px outline. e.g. CommandCard > Label "X": 3.56 : 1 (rule 4.5; text 786632 on 090808) (inside a disabled button: WARN only) (at 1600x900, 1920x1080)
2. **Contrast on hud** (WARN): brighter text, darker / more opaque panel, or a 2-3 px outline. e.g. CommandCard > Label "Q": 3.57 : 1 (rule 4.5; text 796631 on 0c0806) (inside a disabled button: WARN only) (at 1600x900, 1920x1080)
3. **Min font size on hud_keep** (WARN): raise the font size (ui-style.md sizes: 12+). e.g. CommandCard > Label "50": 10.0 px (min 11) (at 1600x900, 1920x1080)
4. **Min font size on hud** (WARN): raise the font size (ui-style.md sizes: 12+). e.g. CommandCard > Label "40": 10.0 px (min 11) (at 1600x900, 1920x1080)
5. **Contrast on hud_caster** (WARN): brighter text, darker / more opaque panel, or a 2-3 px outline. e.g. CommandCard > Label "Z": 3.56 : 1 (rule 4.5; text 786632 on 090808) (inside a disabled button: WARN only) (at 1600x900, 1920x1080)
6. **Min font size on hud_caster** (WARN): raise the font size (ui-style.md sizes: 12+). e.g. HeroTile > F1Badge "F1": 9.0 px (min 11) (at 1600x900, 1920x1080)

## Matrix (status, items found)
| Screen @ resolution | Text overflow | Off-screen | Overlaps | Min font size | Contrast | Tooltips | Hotkeys | Bottom-bar gaps | Bleed-through | Icon contrast | Edge margin | Shot |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| hud @ 1600x900 | PASS | PASS | PASS | **WARN** 6 | **WARN** 5 | **WARN** 1 | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1600x900/hud.jpg) |
| hud_keep @ 1600x900 | PASS | PASS | PASS | **WARN** 8 | **WARN** 7 | **WARN** 1 | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1600x900/hud_keep.jpg) |
| hud_caster @ 1600x900 | PASS | PASS | PASS | **WARN** 3 | **WARN** 2 | **WARN** 1 | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1600x900/hud_caster.jpg) |
| hud @ 1920x1080 | PASS | PASS | PASS | **WARN** 6 | **WARN** 5 | **WARN** 1 | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1920x1080/hud.jpg) |
| hud_keep @ 1920x1080 | PASS | PASS | PASS | **WARN** 8 | **WARN** 7 | **WARN** 1 | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1920x1080/hud_keep.jpg) |
| hud_caster @ 1920x1080 | PASS | PASS | PASS | **WARN** 3 | **WARN** 2 | **WARN** 1 | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1920x1080/hud_caster.jpg) |

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

**hud @ 1600x900 · Min font size: WARN (6)**
- CommandCard > Label "40": 10.0 px (min 11)
- CommandCard > Label "30": 10.0 px (min 11)
- CommandCard > Label "50": 10.0 px (min 11)
- HeroTile > F1Badge "F1": 9.0 px (min 11)
- ArmyButton > Label "F2": 10.0 px (min 11)
- ArmyButton > Label "1": 10.0 px (min 11)

**hud @ 1600x900 · Contrast: WARN (5)**
- CommandCard > Label "Q": 3.57 : 1 (rule 4.5; text 796631 on 0c0806) (inside a disabled button: WARN only)
- CommandCard > Label "30": 2.69 : 1 (rule 4.5; text 465678 on 0c0a0a) (inside a disabled button: WARN only)
- CommandCard > Label "E": 3.58 : 1 (rule 4.5; text 7a6734 on 0d0a0b) (inside a disabled button: WARN only)
- CommandCard > Label "50": 2.67 : 1 (rule 4.5; text 495576 on 120906) (inside a disabled button: WARN only)
- ArmyButton > Label "1": 3.13 : 1 (rule 4.5; text 000000 on 6b5a2e)

**hud @ 1600x900 · Tooltips: WARN (1)**
- GameHUD > Button "Objective": no tooltip

**hud @ 1600x900 · Hotkeys: WARN (1)**
- help key G: gather; trade (caravans)

**hud_keep @ 1600x900 · Min font size: WARN (8)**
- CommandCard > Label "50": 10.0 px (min 11)
- CommandCard > Label "300": 10.0 px (min 11)
- CommandCard > Label "200": 10.0 px (min 11)
- CommandCard > Label "350": 10.0 px (min 11)
- CommandCard > Label "120": 10.0 px (min 11)
- HeroTile > F1Badge "F1": 9.0 px (min 11)
- ArmyButton > Label "F2": 10.0 px (min 11)
- ArmyButton > Label "1": 10.0 px (min 11)

**hud_keep @ 1600x900 · Contrast: WARN (7)**
- CommandCard > Label "X": 3.56 : 1 (rule 4.5; text 786632 on 090808) (inside a disabled button: WARN only)
- CommandCard > Label "300": 3.75 : 1 (rule 4.5; text 5b6e77 on 090808) (inside a disabled button: WARN only)
- CommandCard > Label "C": 3.56 : 1 (rule 4.5; text 786632 on 090808) (inside a disabled button: WARN only)
- CommandCard > Label "200": 3.75 : 1 (rule 4.5; text 5b6e77 on 090808) (inside a disabled button: WARN only)
- CommandCard > Label "V": 3.56 : 1 (rule 4.5; text 786632 on 090808) (inside a disabled button: WARN only)
- CommandCard > Label "350": 3.75 : 1 (rule 4.5; text 5b6e77 on 090808) (inside a disabled button: WARN only)
- ArmyButton > Label "1": 3.13 : 1 (rule 4.5; text 000000 on 6b5a2e)

**hud_keep @ 1600x900 · Tooltips: WARN (1)**
- GameHUD > Button "Objective": no tooltip

**hud_keep @ 1600x900 · Hotkeys: WARN (1)**
- help key G: gather; trade (caravans)

**hud_caster @ 1600x900 · Min font size: WARN (3)**
- HeroTile > F1Badge "F1": 9.0 px (min 11)
- ArmyButton > Label "F2": 10.0 px (min 11)
- ArmyButton > Label "1": 10.0 px (min 11)

**hud_caster @ 1600x900 · Contrast: WARN (2)**
- CommandCard > Label "Z": 3.56 : 1 (rule 4.5; text 786632 on 090808) (inside a disabled button: WARN only)
- ArmyButton > Label "1": 3.13 : 1 (rule 4.5; text 000000 on 6b5a2e)

**hud_caster @ 1600x900 · Tooltips: WARN (1)**
- GameHUD > Button "Objective": no tooltip

**hud_caster @ 1600x900 · Hotkeys: WARN (1)**
- help key G: gather; trade (caravans)

**hud @ 1920x1080 · Min font size: WARN (6)**
- CommandCard > Label "40": 10.0 px (min 11)
- CommandCard > Label "30": 10.0 px (min 11)
- CommandCard > Label "50": 10.0 px (min 11)
- HeroTile > F1Badge "F1": 9.0 px (min 11)
- ArmyButton > Label "F2": 10.0 px (min 11)
- ArmyButton > Label "1": 10.0 px (min 11)

**hud @ 1920x1080 · Contrast: WARN (5)**
- CommandCard > Label "Q": 3.57 : 1 (rule 4.5; text 796631 on 0c0806) (inside a disabled button: WARN only)
- CommandCard > Label "30": 2.69 : 1 (rule 4.5; text 465678 on 0c0a0a) (inside a disabled button: WARN only)
- CommandCard > Label "E": 3.58 : 1 (rule 4.5; text 7a6734 on 0d0a0b) (inside a disabled button: WARN only)
- CommandCard > Label "50": 2.67 : 1 (rule 4.5; text 495576 on 120906) (inside a disabled button: WARN only)
- ArmyButton > Label "1": 3.13 : 1 (rule 4.5; text 000000 on 6b5a2e)

**hud @ 1920x1080 · Tooltips: WARN (1)**
- GameHUD > Button "Objective": no tooltip

**hud @ 1920x1080 · Hotkeys: WARN (1)**
- help key G: gather; trade (caravans)

**hud_keep @ 1920x1080 · Min font size: WARN (8)**
- CommandCard > Label "50": 10.0 px (min 11)
- CommandCard > Label "300": 10.0 px (min 11)
- CommandCard > Label "200": 10.0 px (min 11)
- CommandCard > Label "350": 10.0 px (min 11)
- CommandCard > Label "120": 10.0 px (min 11)
- HeroTile > F1Badge "F1": 9.0 px (min 11)
- ArmyButton > Label "F2": 10.0 px (min 11)
- ArmyButton > Label "1": 10.0 px (min 11)

**hud_keep @ 1920x1080 · Contrast: WARN (7)**
- CommandCard > Label "X": 3.56 : 1 (rule 4.5; text 786632 on 090808) (inside a disabled button: WARN only)
- CommandCard > Label "300": 3.75 : 1 (rule 4.5; text 5b6e77 on 090808) (inside a disabled button: WARN only)
- CommandCard > Label "C": 3.56 : 1 (rule 4.5; text 786632 on 090808) (inside a disabled button: WARN only)
- CommandCard > Label "200": 3.75 : 1 (rule 4.5; text 5b6e77 on 090808) (inside a disabled button: WARN only)
- CommandCard > Label "V": 3.56 : 1 (rule 4.5; text 786632 on 090808) (inside a disabled button: WARN only)
- CommandCard > Label "350": 3.75 : 1 (rule 4.5; text 5b6e77 on 090808) (inside a disabled button: WARN only)
- ArmyButton > Label "1": 3.13 : 1 (rule 4.5; text 000000 on 6b5a2e)

**hud_keep @ 1920x1080 · Tooltips: WARN (1)**
- GameHUD > Button "Objective": no tooltip

**hud_keep @ 1920x1080 · Hotkeys: WARN (1)**
- help key G: gather; trade (caravans)

**hud_caster @ 1920x1080 · Min font size: WARN (3)**
- HeroTile > F1Badge "F1": 9.0 px (min 11)
- ArmyButton > Label "F2": 10.0 px (min 11)
- ArmyButton > Label "1": 10.0 px (min 11)

**hud_caster @ 1920x1080 · Contrast: WARN (2)**
- CommandCard > Label "Z": 3.56 : 1 (rule 4.5; text 786632 on 090808) (inside a disabled button: WARN only)
- ArmyButton > Label "1": 3.13 : 1 (rule 4.5; text 000000 on 6b5a2e)

**hud_caster @ 1920x1080 · Tooltips: WARN (1)**
- GameHUD > Button "Objective": no tooltip

**hud_caster @ 1920x1080 · Hotkeys: WARN (1)**
- help key G: gather; trade (caravans)

## Window sizes obtained
- 1600x900 -> 1600x900
- 1920x1080 -> 1920x1080

## Notes
- 1600x900: match clock stuck at 0 s
- 1920x1080: match clock stuck at 0 s

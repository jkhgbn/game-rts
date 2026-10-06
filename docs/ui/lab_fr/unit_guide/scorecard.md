# UI Lab scorecard

2026-10-06 09:13:57 · lab v2.0 · 18 s

## Result: **PASS** · quality **100 / 100** (previous run 100, +0)

0 FAIL · 0 WARN · 32 PASS · 0 skipped

Contact sheet (rows = resolutions, columns = screens, frame = worst status): [contact_sheet.jpg](contact_sheet.jpg)

## Improve next
1. **Tooltips everywhere in game** (IDEA): every HUD button gets a tooltip with its key and cost, even when its text is clear
2. **Headroom for French** (IDEA): French text runs ~20 % longer: keep 20 % spare width in fixed-size frames
3. **Ultrawide layout** (IDEA): at 3440x1440 check that HUD blocks stay anchored to their edges and the centre stays clear

## Matrix (status, items found)
| Screen @ resolution | Text overflow | Off-screen | Overlaps | Min font size | Contrast | Tooltips | Hotkeys | Bottom-bar gaps | Bleed-through | Icon contrast | Edge margin | Shot |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| unit_guide @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1600x900/unit_guide.jpg) |
| unit_guide_compare @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1600x900/unit_guide_compare.jpg) |
| unit_guide @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1920x1080/unit_guide.jpg) |
| unit_guide_compare @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1920x1080/unit_guide_compare.jpg) |

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

## Window sizes obtained
- 1600x900 -> 1600x900
- 1920x1080 -> 1920x1080

## Notes
- Language: fr (Loc.set_language)

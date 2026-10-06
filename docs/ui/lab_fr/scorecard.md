# UI Lab scorecard

2026-10-06 10:20:59 · lab v2.0 · 279 s

## Result: **FAIL** · quality **90 / 100**

16 FAIL · 17 WARN · 145 PASS · 0 skipped

Contact sheet (rows = resolutions, columns = screens, frame = worst status): [contact_sheet.jpg](contact_sheet.jpg)

## Improve next
1. **Bleed-through on end_score** (FAIL): make the modal panel opaque, put a dimmer behind it, or hide the HUD text while it is open. e.g. SelectionPanel > Button "Vessa, sorcière du Feu": shows through the modal panel GameHUD > PanelContainer (background alpha 0.92 < 0.95) (at 1600x900, 1920x1080)
2. **Contrast on hud_keep** (FAIL): brighter text, darker / more opaque panel, or a 2-3 px outline. e.g. CommandCard > Label "X": 3.56 : 1 (rule 4.5; text 786632 on 0a0808) (inside a disabled button: WARN only) (at 1600x900, 1920x1080)
3. **Contrast on hud** (FAIL): brighter text, darker / more opaque panel, or a 2-3 px outline. e.g. CommandCard > Label "Q": 3.57 : 1 (rule 4.5; text 796632 on 0b0807) (inside a disabled button: WARN only) (at 1600x900, 1920x1080)
4. **Contrast on hud_caster** (FAIL): brighter text, darker / more opaque panel, or a 2-3 px outline. e.g. CommandCard > Label "Z": 3.56 : 1 (rule 4.5; text 786632 on 0a0808) (inside a disabled button: WARN only) (at 1600x900, 1920x1080)
5. **Overlaps on hud** (FAIL): move one of them, or hide the lower-priority one while the other shows. e.g. GameHUD > Label "Clic gauche / glisser : sélect.."  x  GameHUD > Label "Cliquez sur votre donjon pour ..": 6898 px2 (21 % of the smaller) (at 1600x900, 1920x1080)
6. **Overlaps on hud_keep** (FAIL): move one of them, or hide the lower-priority one while the other shows. e.g. GameHUD > Label "Clic gauche / glisser : sélect.."  x  GameHUD > Label "Cliquez sur votre donjon pour ..": 6898 px2 (21 % of the smaller) (at 1600x900, 1920x1080)

## Matrix (status, items found)
| Screen @ resolution | Text overflow | Off-screen | Overlaps | Min font size | Contrast | Tooltips | Hotkeys | Bottom-bar gaps | Bleed-through | Icon contrast | Edge margin | Shot |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| main_menu @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1600x900/main_menu.jpg) |
| skirmish_setup @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | **WARN** 1 | [jpg](1600x900/skirmish_setup.jpg) |
| settings @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | PASS | **WARN** 1 | PASS | [jpg](1600x900/settings.jpg) |
| unit_guide @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1600x900/unit_guide.jpg) |
| unit_guide_compare @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1600x900/unit_guide_compare.jpg) |
| hud @ 1600x900 | PASS | PASS | **FAIL** 2 | **WARN** 3 | **FAIL** 8 | PASS | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1600x900/hud.jpg) |
| hud_keep @ 1600x900 | PASS | PASS | **FAIL** 2 | **WARN** 6 | **FAIL** 8 | PASS | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1600x900/hud_keep.jpg) |
| hud_caster @ 1600x900 | PASS | PASS | **FAIL** 2 | **WARN** 3 | **FAIL** 7 | PASS | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1600x900/hud_caster.jpg) |
| pause @ 1600x900 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | **WARN** 3 | PASS | PASS | [jpg](1600x900/pause.jpg) |
| end_score @ 1600x900 | PASS | PASS | PASS | PASS | **FAIL** 2 | PASS | - | - | **FAIL** 5 | PASS | PASS | [jpg](1600x900/end_score.jpg) |
| main_menu @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1920x1080/main_menu.jpg) |
| skirmish_setup @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1920x1080/skirmish_setup.jpg) |
| settings @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | PASS | **WARN** 2 | PASS | [jpg](1920x1080/settings.jpg) |
| unit_guide @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1920x1080/unit_guide.jpg) |
| unit_guide_compare @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | - | PASS | PASS | [jpg](1920x1080/unit_guide_compare.jpg) |
| hud @ 1920x1080 | PASS | PASS | **FAIL** 1 | **WARN** 3 | **FAIL** 8 | PASS | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1920x1080/hud.jpg) |
| hud_keep @ 1920x1080 | PASS | PASS | **FAIL** 1 | **WARN** 6 | **FAIL** 8 | PASS | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1920x1080/hud_keep.jpg) |
| hud_caster @ 1920x1080 | PASS | PASS | **FAIL** 1 | **WARN** 3 | **FAIL** 7 | PASS | **WARN** 1 | PASS | - | PASS | PASS | [jpg](1920x1080/hud_caster.jpg) |
| pause @ 1920x1080 | PASS | PASS | PASS | PASS | PASS | PASS | - | - | **WARN** 3 | PASS | PASS | [jpg](1920x1080/pause.jpg) |
| end_score @ 1920x1080 | PASS | PASS | PASS | PASS | **FAIL** 2 | PASS | - | - | **FAIL** 4 | PASS | PASS | [jpg](1920x1080/end_score.jpg) |

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
- MainMenu > PanelContainer: 5 px from the bottom edge (flush it or keep >= 8 px)

**settings @ 1600x900 · Icon contrast: WARN (1)**
- SettingsPanel > CheckButton "Plein écran": switch (off): only 16 % of the icon area is drawn (min 25 %): the track / outline is invisible, the control reads as empty

**hud @ 1600x900 · Overlaps: FAIL (2)**
- **FAIL** GameHUD > Label "Clic gauche / glisser : sélect.."  x  GameHUD > Label "Cliquez sur votre donjon pour ..": 6898 px2 (21 % of the smaller)
- **FAIL** GameHUD > Label "Cliquez sur votre donjon pour .."  x  NextStepHint > Label "Prochaine étape : construisez ..": 8041 px2 (59 % of the smaller)

**hud @ 1600x900 · Min font size: WARN (3)**
- ChampionBar > Label "F5": 10.0 px (min 11)
- ChampionBar > Label "F6": 10.0 px (min 11)
- ChampionBar > Label "F7": 10.0 px (min 11)

**hud @ 1600x900 · Contrast: FAIL (8)**
- CommandCard > Label "Q": 3.57 : 1 (rule 4.5; text 796632 on 0b0807) (inside a disabled button: WARN only)
- CommandCard > Label "E": 3.59 : 1 (rule 4.5; text 7c6631 on 100906) (inside a disabled button: WARN only)
- **FAIL** ChampionBar > Label "Engager un champion": 3.01 : 1 (rule 4.5; text 73695f on 24201b)
- **FAIL** ChampionBar > Label "Taverne ouverte à 2:00": 3.01 : 1 (rule 4.5; text 73695f on 24201b)
- **FAIL** ChampionBar > Label "Engager un champion": 3.01 : 1 (rule 4.5; text 73695f on 23201a)
- **FAIL** ChampionBar > Label "Taverne ouverte à 2:00": 3.01 : 1 (rule 4.5; text 73695f on 23201a)
- ChampionBar > Label "Engager un champion": 3.04 : 1 (rule 4.5; text 72685e on 211f18)
- ChampionBar > Label "Taverne ouverte à 2:00": 3.04 : 1 (rule 4.5; text 73685e on 221e19)

**hud @ 1600x900 · Hotkeys: WARN (1)**
- help key G : récolter; commerce (caravanes)

**hud_keep @ 1600x900 · Overlaps: FAIL (2)**
- **FAIL** GameHUD > Label "Clic gauche / glisser : sélect.."  x  GameHUD > Label "Cliquez sur votre donjon pour ..": 6898 px2 (21 % of the smaller)
- **FAIL** GameHUD > Label "Cliquez sur votre donjon pour .."  x  NextStepHint > Label "Prochaine étape : construisez ..": 8041 px2 (59 % of the smaller)

**hud_keep @ 1600x900 · Min font size: WARN (6)**
- CommandCard > Label "50": 10.0 px (min 11)
- CommandCard > Label "300": 10.0 px (min 11)
- CommandCard > Label "120": 10.0 px (min 11)
- ChampionBar > Label "F5": 10.0 px (min 11)
- ChampionBar > Label "F6": 10.0 px (min 11)
- ChampionBar > Label "F7": 10.0 px (min 11)

**hud_keep @ 1600x900 · Contrast: FAIL (8)**
- CommandCard > Label "X": 3.56 : 1 (rule 4.5; text 786632 on 0a0808) (inside a disabled button: WARN only)
- CommandCard > Label "300": 3.76 : 1 (rule 4.5; text 5c6f77 on 0a0908) (inside a disabled button: WARN only)
- **FAIL** ChampionBar > Label "Engager un champion": 3.01 : 1 (rule 4.5; text 73695f on 24201b)
- **FAIL** ChampionBar > Label "Taverne ouverte à 2:00": 3.01 : 1 (rule 4.5; text 73695f on 24201b)
- **FAIL** ChampionBar > Label "Engager un champion": 3.01 : 1 (rule 4.5; text 73695f on 23201a)
- **FAIL** ChampionBar > Label "Taverne ouverte à 2:00": 3.01 : 1 (rule 4.5; text 73695f on 23201a)
- ChampionBar > Label "Engager un champion": 3.04 : 1 (rule 4.5; text 72685e on 211f18)
- ChampionBar > Label "Taverne ouverte à 2:00": 3.04 : 1 (rule 4.5; text 73685e on 221e19)

**hud_keep @ 1600x900 · Hotkeys: WARN (1)**
- help key G : récolter; commerce (caravanes)

**hud_caster @ 1600x900 · Overlaps: FAIL (2)**
- **FAIL** GameHUD > Label "Clic gauche / glisser : sélect.."  x  GameHUD > Label "Cliquez sur votre donjon pour ..": 6898 px2 (21 % of the smaller)
- **FAIL** GameHUD > Label "Cliquez sur votre donjon pour .."  x  NextStepHint > Label "Prochaine étape : construisez ..": 8041 px2 (59 % of the smaller)

**hud_caster @ 1600x900 · Min font size: WARN (3)**
- ChampionBar > Label "F5": 10.0 px (min 11)
- ChampionBar > Label "F6": 10.0 px (min 11)
- ChampionBar > Label "F7": 10.0 px (min 11)

**hud_caster @ 1600x900 · Contrast: FAIL (7)**
- CommandCard > Label "Z": 3.56 : 1 (rule 4.5; text 786632 on 0a0808) (inside a disabled button: WARN only)
- **FAIL** ChampionBar > Label "Engager un champion": 3.01 : 1 (rule 4.5; text 73695f on 24201b)
- **FAIL** ChampionBar > Label "Taverne ouverte à 2:00": 3.01 : 1 (rule 4.5; text 73695f on 24201b)
- **FAIL** ChampionBar > Label "Engager un champion": 3.01 : 1 (rule 4.5; text 73695f on 23201a)
- **FAIL** ChampionBar > Label "Taverne ouverte à 2:00": 3.01 : 1 (rule 4.5; text 73695f on 23201a)
- ChampionBar > Label "Engager un champion": 3.04 : 1 (rule 4.5; text 72685e on 211f18)
- ChampionBar > Label "Taverne ouverte à 2:00": 3.04 : 1 (rule 4.5; text 73685e on 221e19)

**hud_caster @ 1600x900 · Hotkeys: WARN (1)**
- help key G : récolter; commerce (caravanes)

**pause @ 1600x900 · Bleed-through: WARN (3)**
- StrIntPanel > Label "Choisissez votre voie (fixée p..": shows through the modal panel PauseMenu > PanelContainer (background alpha 0.92 < 0.95)
- StrIntPanel > Button "FORCE  +15 % dégâts d'attaque ..": shows through the modal panel PauseMenu > PanelContainer (background alpha 0.92 < 0.95)
- StrIntPanel > Button "INTELLECT  +15 puissance (+15 ..": shows through the modal panel PauseMenu > PanelContainer (background alpha 0.92 < 0.95)

**end_score @ 1600x900 · Contrast: FAIL (2)**
- ScorePanel > Label "595": 4.19 : 1 (rule 4.5; text ff8c26 on 1c4670)
- **FAIL** ScorePanel > Label "195": 2.61 : 1 (rule 4.5; text a85cff on 1c4670)

**end_score @ 1600x900 · Bleed-through: FAIL (5)**
- SelectionPanel > Button "Vessa, sorcière du Feu": shows through the modal panel GameHUD > PanelContainer (background alpha 0.92 < 0.95)
- GameHUD > Label "Cliquez sur votre donjon pour ..": shows through the modal panel GameHUD > PanelContainer (background alpha 0.92 < 0.95)
- **FAIL** StrIntPanel > Label "Choisissez votre voie (fixée p..": drawn OVER the modal panel GameHUD > PanelContainer (layer 60 vs 1)
- **FAIL** StrIntPanel > Button "FORCE  +15 % dégâts d'attaque ..": drawn OVER the modal panel GameHUD > PanelContainer (layer 60 vs 1)
- **FAIL** StrIntPanel > Button "INTELLECT  +15 puissance (+15 ..": drawn OVER the modal panel GameHUD > PanelContainer (layer 60 vs 1)

**settings @ 1920x1080 · Icon contrast: WARN (2)**
- SettingsPanel > CheckButton "Plein écran": switch (off): only 16 % of the icon area is drawn (min 25 %): the track / outline is invisible, the control reads as empty
- SettingsPanel > CheckButton "Aider à améliorer le jeu : enr..": switch (off): only 17 % of the icon area is drawn (min 25 %): the track / outline is invisible, the control reads as empty

**hud @ 1920x1080 · Overlaps: FAIL (1)**
- **FAIL** GameHUD > Label "Cliquez sur votre donjon pour .."  x  NextStepHint > Label "Prochaine étape : construisez ..": 4521 px2 (33 % of the smaller)

**hud @ 1920x1080 · Min font size: WARN (3)**
- ChampionBar > Label "F5": 10.0 px (min 11)
- ChampionBar > Label "F6": 10.0 px (min 11)
- ChampionBar > Label "F7": 10.0 px (min 11)

**hud @ 1920x1080 · Contrast: FAIL (8)**
- CommandCard > Label "Q": 3.57 : 1 (rule 4.5; text 796632 on 0b0807) (inside a disabled button: WARN only)
- CommandCard > Label "E": 3.59 : 1 (rule 4.5; text 7c6631 on 100906) (inside a disabled button: WARN only)
- **FAIL** ChampionBar > Label "Engager un champion": 3.01 : 1 (rule 4.5; text 73695f on 23201a)
- **FAIL** ChampionBar > Label "Taverne ouverte à 2:00": 3.01 : 1 (rule 4.5; text 73695f on 24201b)
- ChampionBar > Label "Engager un champion": 3.03 : 1 (rule 4.5; text 73685f on 231f1a)
- ChampionBar > Label "Taverne ouverte à 2:00": 3.04 : 1 (rule 4.5; text 73685f on 231e1a)
- ChampionBar > Label "Engager un champion": 3.06 : 1 (rule 4.5; text 72675e on 211d19)
- ChampionBar > Label "Taverne ouverte à 2:00": 3.07 : 1 (rule 4.5; text 71675d on 1f1d16)

**hud @ 1920x1080 · Hotkeys: WARN (1)**
- help key G : récolter; commerce (caravanes)

**hud_keep @ 1920x1080 · Overlaps: FAIL (1)**
- **FAIL** GameHUD > Label "Cliquez sur votre donjon pour .."  x  NextStepHint > Label "Prochaine étape : construisez ..": 4521 px2 (33 % of the smaller)

**hud_keep @ 1920x1080 · Min font size: WARN (6)**
- CommandCard > Label "50": 10.0 px (min 11)
- CommandCard > Label "300": 10.0 px (min 11)
- CommandCard > Label "120": 10.0 px (min 11)
- ChampionBar > Label "F5": 10.0 px (min 11)
- ChampionBar > Label "F6": 10.0 px (min 11)
- ChampionBar > Label "F7": 10.0 px (min 11)

**hud_keep @ 1920x1080 · Contrast: FAIL (8)**
- CommandCard > Label "X": 3.56 : 1 (rule 4.5; text 786632 on 0a0808) (inside a disabled button: WARN only)
- CommandCard > Label "300": 3.75 : 1 (rule 4.5; text 5c6e77 on 0a0808) (inside a disabled button: WARN only)
- **FAIL** ChampionBar > Label "Engager un champion": 3.01 : 1 (rule 4.5; text 73695f on 23201a)
- **FAIL** ChampionBar > Label "Taverne ouverte à 2:00": 3.01 : 1 (rule 4.5; text 73695f on 24201b)
- ChampionBar > Label "Engager un champion": 3.03 : 1 (rule 4.5; text 73685f on 231f1a)
- ChampionBar > Label "Taverne ouverte à 2:00": 3.04 : 1 (rule 4.5; text 73685f on 231e1a)
- ChampionBar > Label "Engager un champion": 3.06 : 1 (rule 4.5; text 72675e on 211d19)
- ChampionBar > Label "Taverne ouverte à 2:00": 3.07 : 1 (rule 4.5; text 71675d on 1f1d16)

**hud_keep @ 1920x1080 · Hotkeys: WARN (1)**
- help key G : récolter; commerce (caravanes)

**hud_caster @ 1920x1080 · Overlaps: FAIL (1)**
- **FAIL** GameHUD > Label "Cliquez sur votre donjon pour .."  x  NextStepHint > Label "Prochaine étape : construisez ..": 4521 px2 (33 % of the smaller)

**hud_caster @ 1920x1080 · Min font size: WARN (3)**
- ChampionBar > Label "F5": 10.0 px (min 11)
- ChampionBar > Label "F6": 10.0 px (min 11)
- ChampionBar > Label "F7": 10.0 px (min 11)

**hud_caster @ 1920x1080 · Contrast: FAIL (7)**
- CommandCard > Label "Z": 3.56 : 1 (rule 4.5; text 786632 on 0a0808) (inside a disabled button: WARN only)
- **FAIL** ChampionBar > Label "Engager un champion": 3.01 : 1 (rule 4.5; text 73695f on 23201a)
- **FAIL** ChampionBar > Label "Taverne ouverte à 2:00": 3.01 : 1 (rule 4.5; text 73695f on 24201b)
- ChampionBar > Label "Engager un champion": 3.03 : 1 (rule 4.5; text 73685f on 231f1a)
- ChampionBar > Label "Taverne ouverte à 2:00": 3.04 : 1 (rule 4.5; text 73685f on 231e1a)
- ChampionBar > Label "Engager un champion": 3.06 : 1 (rule 4.5; text 72675e on 211d19)
- ChampionBar > Label "Taverne ouverte à 2:00": 3.07 : 1 (rule 4.5; text 71675d on 1f1d16)

**hud_caster @ 1920x1080 · Hotkeys: WARN (1)**
- help key G : récolter; commerce (caravanes)

**pause @ 1920x1080 · Bleed-through: WARN (3)**
- StrIntPanel > Label "Choisissez votre voie (fixée p..": shows through the modal panel PauseMenu > PanelContainer (background alpha 0.92 < 0.95)
- StrIntPanel > Button "FORCE  +15 % dégâts d'attaque ..": shows through the modal panel PauseMenu > PanelContainer (background alpha 0.92 < 0.95)
- StrIntPanel > Button "INTELLECT  +15 puissance (+15 ..": shows through the modal panel PauseMenu > PanelContainer (background alpha 0.92 < 0.95)

**end_score @ 1920x1080 · Contrast: FAIL (2)**
- ScorePanel > Label "595": 4.19 : 1 (rule 4.5; text ff8c26 on 1c4670)
- **FAIL** ScorePanel > Label "195": 2.61 : 1 (rule 4.5; text a85cff on 1c4670)

**end_score @ 1920x1080 · Bleed-through: FAIL (4)**
- GameHUD > Label "Cliquez sur votre donjon pour ..": shows through the modal panel GameHUD > PanelContainer (background alpha 0.92 < 0.95)
- **FAIL** StrIntPanel > Label "Choisissez votre voie (fixée p..": drawn OVER the modal panel GameHUD > PanelContainer (layer 60 vs 1)
- **FAIL** StrIntPanel > Button "FORCE  +15 % dégâts d'attaque ..": drawn OVER the modal panel GameHUD > PanelContainer (layer 60 vs 1)
- **FAIL** StrIntPanel > Button "INTELLECT  +15 puissance (+15 ..": drawn OVER the modal panel GameHUD > PanelContainer (layer 60 vs 1)

## Window sizes obtained
- 1600x900 -> 1600x900
- 1920x1080 -> 1920x1080

## Notes
- Language: fr (Loc.set_language)
- 1600x900: match clock stuck at 0 s
- 1920x1080: match clock stuck at 0 s

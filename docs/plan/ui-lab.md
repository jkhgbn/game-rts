# UI Lab: screenshot and check every screen at every resolution

Labs program item 2 (`docs/plan/waves.md`). The UI Lab opens each screen of the game the way the player sees it, at
**1600x900**, **1920x1080** (laptop) and **3440x1440** (ultrawide), saves a screenshot of each, measures the live
Control tree and writes a **scorecard** like the other labs: PASS / WARN / FAIL per check, a **quality score 0-100**,
an **"Improve next"** list (always >= 3 items) and a row in `docs/ui/lab/improvement-log.md`.

Files: `tools/ui_lab/ui_lab.gd` (entry + screen driver), `tools/ui_lab/ui_lab_checks.gd` (`UILabChecks`, the
measurements, **all thresholds at the top**), `tools/ui_lab/ui_lab_report.gd` (`UILabReport`, scorecard), test
`tests/test_ui_lab.gd` (headless: `PASS ui_lab`). Output: `docs/ui/lab/`.

## 1. One command
Windowed (screenshots and pixel contrast need a window; `--headless` runs the Control checks only and takes contrast
from the style boxes). Launch through the Godot gate; quote `'--'` so PowerShell passes it on, and quote any comma list (`'res=1600x900,1920x1080'`): unquoted, PowerShell turns it into an array and only the first size runs:
```powershell
cd C:\Users\elzzo\Documents\four-wizards-rts
& .\tools\godot_run.ps1 --path . -s res://tools/ui_lab/ui_lab.gd --quit-after 200000 '--' 'res=1600x900,1920x1080,3440x1440'
```
| Arg (after `--`) | Meaning |
|---|---|
| `res=` | comma list of `WxH` (default the three above). A size >= the screen opens borderless at the screen origin; if the OS gives a smaller window, the scorecard says so under "Window sizes obtained" |
| `screens=` | comma list, default all: `main_menu`, `skirmish_setup`, `settings`, `hud`, `pause`, `end_score` |
| `out=` | output folder, default `res://docs/ui/lab` |
| `match_s=` / `timescale=` | match time before the HUD shot (default 60 s) / game speed while waiting (default 8) |
| `ui_scale=` | UI scale forced for the run (default 1.0; the saved settings file is never written) |
| `log=0` | no improvement-log row |

Exit code **1 on any FAIL**, 0 otherwise, 2 = bad arguments, 3 = watchdog (900 s). The console ends with one line per
FAIL / WARN cell and `UI LAB: <RESULT> quality <N> (...)`. Runtime ~1.5-3 min for 3 resolutions (3 skirmish loads).

Output: `docs/ui/lab/scorecard.md`, `scorecard.json`, `improvement-log.md`, `contact_sheet.jpg`, and `docs/ui/lab/<WxH>/<screen>.jpg`.

## 2. What it opens (per resolution)
1. Main menu (`scenes/ui/main_menu.tscn`, `show_main`), 2. Skirmish setup (`show_skirmish_setup`), 3. Settings
(`show_settings`, scope = the SettingsPanel), 4. **HUD**: `start_skirmish()` with the menu's choices, waits for the
navmesh bake, runs the clock to 1:00 at x8, selects every commandable player unit (wizard + workers: mixed selection,
command card of the group), 5. **Pause menu** (the level's PauseMenu `open()`), 6. **End screen, Score tab**
(`surrender(PLAYER)`, 1.2 s for the banner tween; scope = `hud.end_panel`).
Each check looks only at the screen's scope (menu / settings panel / HUD layer / pause layer / end panel), visible
branches only (hidden or alpha < 0.05 skipped, SubViewports = 3D backdrops skipped).

## 3. The checks (`UILabChecks`, thresholds at the top of `ui_lab_checks.gd`)
| Check | Rule | FAIL when | WARN when |
|---|---|---|---|
| Text overflow | the text rect (font-measured, alignment applied) stays inside its frame: nearest Panel / PanelContainer / Button / clip_contents ancestor, 2 px tolerance | sticks out > 6 px | sticks out 2-6 px, or text cut in its own rect (clip_text / ellipsis / max_lines) |
| Off-screen | every text / interactive control fully inside the window | any | - |
| Overlaps | text / button rects of the same canvas layer, neither inside the other, overlapping >= 24 px2 and >= 12 % of the smaller | overlap >= 150 px2 | smaller overlaps |
| Min font size | effective px (font size x global scale) >= 11 | < 9 px | 9-10 px |
| Contrast | WCAG AA: 4.5 small text, 3.0 large (>= 24 px, or >= 19 px with a non-default font). Text colour x modulate, blended by its alpha over the **background sampled from the screenshot** (median pixel of the text rect + 3 px); outlined text (>= 2 px) may count the text / outline contrast; disabled buttons exempt | < 2/3 of the rule | under the rule |
| Tooltips | buttons with `get_tooltip()` empty. Menus / pause / end: only abbreviation / icon buttons (<= 3 chars). HUD: every button | short / icon button without tooltip | HUD text button without tooltip |
| Bottom-bar gaps (HUD, v2) | panels in the bottom 25 % of the screen: the empty x-gap between two of them | gap > 40 % of the width | gap > 25 % |
| Bleed-through (pause, end, settings, v2) | text outside the modal's main panel that lies on it: drawn over it (higher layer / later in the tree), or under a panel whose background alpha < 0.95 (StyleBoxTexture: the texture centre's alpha) | drawn over, or alpha < 0.8 | alpha 0.8-0.95 |
| Icon contrast (v2, windowed) | CheckButton / CheckBox icon area, icon-only buttons (inner 70 %): 97th vs 3rd luminance percentile >= 3:1 (WCAG 1.4.11); switches: >= 25 % of the icon area drawn (a lone knob dot reads as empty) | < 2:1 | < 3:1, or switch coverage < 25 % |
| Edge margin (v2) | outermost panels >= 120 x 60: flush with a screen edge (0 px) or >= 8 px from it | - | 0.5-8 px from an edge |
| Hotkeys (HUD) | command card: visible key badges (`CommandCard.key_labels`) all different; help (`GameHUD.help_text`): a key listed twice with different actions and no context (`Flag: Z raise`, `Bazaar: Z caravan`, `B, B` sequences are context) | duplicate badge | duplicate help key |

Score: each (screen, resolution, check) cell scores 1.0 on PASS, else `1 / (1 + 0.3 x items + 0.5 x fail items)`;
weights overflow 2, offscreen 2, hotkeys 2, overlap 1.5, contrast 1.5, font 1, tooltip 1. "Improve next" merges the
same problem across resolutions into one line, FAIL first.

## 4. Progress and next steps
v1 built 2026-09-26 (23:30-00:10): driver, 7 checks, scorecard, `contact_sheet.jpg` (rows = resolutions, columns =
screens, frame colour = worst status), self-test `tests/test_ui_lab.gd` (`PASS ui_lab`: every check finds a planted
problem and passes a clean layout). Item names show the owning script class (`ChampionBar > Label "Hire a champion"`).
The run takes ~80 s for 3 resolutions on the GTX 1660 (plus the Godot gate wait).

First results (quality **96**, FAIL: 3 cells, WARN: 6, PASS: 102; menus, settings, pause and end screen PASS at all
three sizes; every problem is on the HUD):
- **Contrast FAIL**: the empty champion slots ("Hire a champion" / "Tavern opens at 2:00") are 2.1-3.0 : 1 over the
  battlefield (rule 4.5). The Q / E spell badges of unlearned spells are 3.6 : 1 but sit in disabled buttons (WARN).
- **Font WARN**: the champion slot key badges F5 / F6 / F7 are 10 px (min 11).
- **Hotkeys WARN**: the help lists G twice ("gather", "trade (caravans)") without a context prefix.
- Seen on the shots, not yet measured: at 3440x1440 the HUD keeps its 1600 px layout (bottom bar ~37 % of the width,
  ~1,500 px gap before the command card); the end panel lets the selection panel text show through; the settings
  "Fullscreen" switch (off) is almost invisible (icon contrast); the skirmish setup panel ends ~5 px above the bottom
  at 1600x900.

### v2 (2026-09-27, lab review, laptop RTX 3070 Laptop, 1920x1080 screen)
- **4 new checks** (table above) for what v1 only saw on the shots: bottom-bar gaps, bleed-through, icon contrast /
  switch coverage, edge margin. Weights: gaps 1.5, bleed 2, icons 1, edge 1. Self-test extended (planted ultrawide gap,
  0.6-alpha modal, text drawn over a lower modal, flat vs drawn switch icon, a panel 5 px from the edge).
- **Window-size honesty**: v1 trusted `root.size`, which keeps the requested size when the OS clamps the window. On
  the laptop the "3440x1440" run really rendered and checked **1920x1080** and reported it as 3440. v2 reads the
  rendered texture / real window size; a size the screen cannot show is **skipped** (console `UI LAB WARNING`, a
  "NOT CHECKED" note in the scorecard), never faked. So the ultrawide checks only run on a screen >= 3440x1440
  (the desktop); the gap check is proven by the self-test.
- Laptop run (1600x900 + 1920x1080): **FAIL 96** (2 FAIL, 8 WARN, 96 PASS). New findings = 3 of the 4 v1 "seen, not
  measured" items: WARN edge (skirmish setup panel **4 px** from the bottom at 1600x900), WARN icons (settings
  "Fullscreen" switch off: only 16 % of its icon drawn, a lone knob dot), WARN bleed (end screen: the selection panel
  text shows through the end panel, frame texture centre alpha 0.92). The 4th (HUD at 3440) needs the desktop. The v1
  items are unchanged (champion slot contrast FAIL, F5-F7 10 px, help G twice). Handoff: `docs/handoff/for-ui-coder.md`.

Next steps (v3):
- Run the 3440x1440 size on the desktop once (the bottom-bar gap check should FAIL there until the HUD stretches).
- More screens: campaign panel, briefing / dialogue / objectives (mission 1), shop (T), tavern (Y), trade (U),
  item tooltip, selection of a building (Keep command card), build menu (B), bounty flag card, the Summary end tab.
- Tooltip pass: hover each HUD button and measure the tooltip panel (off-screen near the edges, font, contrast).
- French readiness: re-run the overflow check with every text x1.25 (pseudo-localisation) to find tight frames.
- UI scale runs (`ui_scale=0.75` and `1.5`) in the default matrix.
- Per-check allow-list (`tools/ui_lab/ui_lab_allow.gd`) for intended overlaps / tiny decorative text, reviewed by the
  ui-designer, so the score reflects real issues only.
- History graph in the improvement log; `--screens` presets per agent (ui-coder runs `screens=hud,end_score`).

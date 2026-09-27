# Data Lab: validate every game data file

The Data Lab is the headless check of all game data (Labs program item 5, `docs/plan/waves.md`). It loads every
`.tres` under `data/` plus the code tables that data points at (ability ids, wares, AI presets, wizard spell lists),
checks them against the rules below and writes a **scorecard** in the Art Lab format: PASS / WARN / FAIL, the measured
value, the rule and a fix hint per check, a **score 0-100**, an **"Improve next"** list (always at least 3 items), every
finding (resource, field, what is wrong, the fix), a cross-kingdom balance table and a row in the history log.
It never edits game data: it lists the fixes for the owners.

Files: `tools/data_lab/` (`data_lab.gd` entry, `data_lab_checks.gd` every check, `data_lab_rules.gd` **all numbers
and lists**, `data_lab_text.gd` text width / placeholder / UI string scan, `data_lab_report.gd` scorecard + history),
test `tests/test_data_lab.gd` (`PASS data_lab`). No `class_name` in the lab (preloaded), so it needs no editor import.

## 1. One command
```powershell
cd C:\Users\elzzo\Documents\four-wizards-rts
& tools\godot_run.ps1 --headless --path . -s res://tools/data_lab/data_lab.gd --quit-after 600
& tools\godot_run.ps1 --headless --path . -s res://tools/data_lab/data_lab.gd --quit-after 600 '--' run=my-test log=0
```
(`tools\godot_run.ps1` = the Godot gate in front of `C:\Godot\Godot_v4.7.2-stable_win64_console.exe`; quote `'--'`.)
| Arg (after `--`) | Meaning |
|---|---|
| `out=` | output folder, default `docs/data/lab/<run>/` |
| `run=` | run name, default the date and time (`2026-09-26_2310`) |
| `log=0` | no row in `docs/data/lab/history.md` (use it for experiments) |
| `ui=0` | skip the hard-coded UI string scan (T7) |

Runtime ~10 s (9 s of it is loading the `.tres` files with their model scenes; the checks take 0.3 s). Exit code **1 on
any FAIL**, 0 otherwise. The console ends with `DATA LAB: <RESULT> score <N> / 100 (...)` and one line per FAIL / WARN
check. Output: `scorecard.md`, `scorecard.json` in the out folder, one row in `docs/data/lab/history.md`.

Test: `& tools\godot_run.ps1 --headless --path . -s tests/test_data_lab.gd --fixed-fps 60 --quit-after 900` (runs the lab on the
real data without a history row, feeds it synthetic bad data and checks every rule class fires, checks the history log).

## 2. What it scans
38 units, 21 buildings, 4 champions, 4 classes, 43 items, 12 spells, 7 AI profiles (`data/**`), plus
`BuildingType.ALL_IDS`, `ChampionType.IDS`, `ChampionClass.IDS`, `CreatureAbilities` (`ABILITIES`, `CREATURES`,
`BEASTS`, `AUTOCAST_ORDER`), `ChampionAbilities` (`ABILITIES`, `CLASS_SKILLS`, `AUTOCAST_ORDER`), `ItemActives`
(`ACTIVES`, `ALIASES`), `GoldBank.WARES`, `Unit.STATUSES` / `Unit.STAT_NAMES`, the wizards' `default_spell_ids`
(parsed from `scripts/units/*wizard.gd`), the 12 AI presets `AIProfile.for_id(id_for_faction(k), 0..2)` and the
literal strings of `scripts/ui/**`.

## 3. The checks (numbers in `tools/data_lab/data_lab_rules.gd`)
Each check is scored from its share of clean items (a PASS = 100, a WARN 35-69, a FAIL 0-34), so fixing one of five
problems moves the score. Group weights: load x2, fields / refs / keys x1.5, text / AI x1, balance x0.5.

| # | Check | Rule |
|---|---|---|
| L1 | Every data .tres loads | each file under `data/` loads as its data script (FAIL) |
| L2 | Ids match file names | `find(id)` loads `DIR/<id>.tres` (FAIL) |
| L3 | Code id lists have data files | `ALL_IDS`, `ChampionType.IDS`, `ChampionClass.IDS`, creature / beast tables -> files (FAIL); a building file missing from `ALL_IDS` = WARN |
| F1 | Required fields set | `Rules.REQUIRED` per kind (id, names, HP, abilities...) (FAIL) |
| F2 | No NaN / inf | every float, array and dictionary number (FAIL) |
| F3 | No negative cost / HP / damage / time | fields named cost / hp / damage / cooldown / time / range / speed / pop / radius / duration... (FAIL); documented sentinels allowed (`Rules.SENTINELS`: `first_scout_time -1`) |
| F4 | Stats inside hard bounds | `Rules.HARD_BOUNDS` per kind: broken values only (FAIL) |
| F5 | Internal consistency | ranged units have a projectile speed, supports have amount / interval / range, towers shoot, keeps / barracks train, spell rank arrays = `max_rank`, `level_required` rising, class skills 3 + unlock levels ascending, class tooltip numbers = the fields, recipes have parts (campaign rewards INFO), items with a passive / active have a tooltip, soldiers' `kill_xp` ~ cost / 2 (levels.md, WARN outside 0.3-0.8 x cost) |
| F6 | Stat outliers vs their group | HP, speed, damage, cooldown, aggro, cost within x2.5 of the group median (WARN). Groups: barracks slot Z / X / C / V across the 4 kingdoms (same role), workers, camp creatures, beasts (+ the hollow guardian, strength >= 500), champions, towers. A spread table is printed |
| R1 | Model files exist | `model_scene` / `model_path` point at existing scenes; units without a model = INFO |
| R2 | model_path without model_scene | **UnitType never loads `model_path`**: a finished model only there = FAIL (buildings load it at runtime: INFO) |
| R3 | Ability ids known | creature / beast / champion / class ability ids exist, owners match, class skills = `CLASS_SKILLS` and unlock levels, every ability is in `AUTOCAST_ORDER`, attack styles, bounty kinds, bark triggers (all 6 written) |
| R4 | Item ids known | champion wishlists exist and are buyable (WARN when artifact / campaign only / unavailable / sold nowhere), item actives known to `ItemActives` |
| R5 | Statuses, stats, kinds known | statuses in `Unit.STATUSES` (+ smoulder, glacier_shell), stat keys in `Unit.STAT_NAMES` (+ `_pct`) for items / classes / auras / wares, factions, building kinds, `requires_kind` (tech prerequisite), ware rows |
| R6 | Spell references | every wizard spell has a file, summon ids exist, every spell has a caster |
| R7 | Training lists resolve | `trains` / `train_ids` entries are unit files of the building's kingdom |
| R8 | Icons / sounds / research | INFO: no icon / sound paths in data yet, research has no data table yet |
| K1 | Training card keys | <= 5 units per building (Z X C V B by slot), `card_key` unique per card |
| K2 | Build menu keys | `hotkey_label` in Z X C V B (`command_card.gd BUILD_KEY_SLOTS`), unique per kingdom menu (trade on = every entry) |
| K3 | Spell keys | each wizard's `default_spell_ids` carry F, Q, E in order |
| K4 | Reserved keys respected | no data key on W A S D Q E F (Hero WASD walk + spells, CLAUDE.md Keys): build key FAIL; unit `card_key` WARN (no code reads it today) |
| T1 | Names and tooltips exist | display names, class / spell / active-item tooltips, champion lines, ability texts, ware texts (FAIL when a name / tooltip is empty) |
| T2 | No placeholder or broken text | no TODO / TBD / FIXME / xxx / lorem, no mojibake (`Â·`, `Ã©`), no double spaces |
| T3 | Text fits its UI width | measured with the project font (engine fallback today): names <= 240 px at 18 px, tooltips <= 6 lines at 300 px / 13 px, one-line texts <= 2 lines, `icon_abbrev` <= 3 letters (WARN) |
| T4 | Display names unique per kind | (WARN) |
| T5 | Tooltip numbers match the data | every number printed in a champion ability text (+ the archetype's `ability_texts`), an item tooltip or a spell tooltip exists in its data: the value, x100 for shares, or a product / ratio of two-three values (4 per tick x 2 s / 0.5 s = 16); level / rank words are skipped (WARN) |
| T7 | Hard-coded UI strings | INFO: literal UI strings per `scripts/ui/**` script, how many go through `tr()` (French-UI backlog) |
| A1 | Every kingdom has easy / normal / hard | `AIProfile.for_id` resolves the 12 profiles; the source table says data (`data/ai/*.tres`) or code preset (Fire and Shadow play the code `shadow_default`, ai.md) |
| A2 | AI knobs in range | `Rules.AI_BOUNDS` (from the `ai_profile.gd` comments / ai.md), floor <= ratio, late caravans >= early, S2 after S1 |
| A3 | AI references | `item_build` items exist and are buyable, `champion_order`, `retreat_spell` is the kingdom's own spell, `ware_order`, `spell_order` (`F2`...), build rows, flag rules |
| A4 | Army mixes | 4 shares >= 0 summing to 1 |
| A5 | Difficulty order | easy -> normal -> hard: decision / reaction / build delay and attack ratio go down, home workers / champions / memory go up (WARN) |
| B1 | Cross-kingdom cost efficiency | EHP (HP x (1 + armor / 100)) and DPS per 100 crystals per card slot, x1.6 from the slot median = WARN, never FAIL. The table is the Balance Lab's starting point |

## 4. Score, "Improve next", history
- **Score 0-100** = weighted mean of the check scores (see 3). **Result** FAIL if any check FAILs, WARN if any WARNs.
- **Improve next**: FAIL checks first, then WARN, then the most weighted headroom; each item names its first finding and
  the fix. Topped up with lab ideas so there are always >= 3.
- **`docs/data/lab/history.md`**: one row per run (when, run, score + delta vs the previous row, result, finding
  counts, top 3, scorecard path).

## 5. Rule to add
The lead pastes this into the agent rules of the next steps (every agent that touches `data/**`, a data script, an AI
profile, an ability / item / ware table or a hotkey):

> **N. Data Lab (every task that adds or changes game data, `docs/plan/data-lab.md`).** Before your report, run
> `& tools\godot_run.ps1 --headless --path . -s res://tools/data_lab/data_lab.gd --quit-after 600` (about 10 s) and open
> `docs/data/lab/<run>/scorecard.md`. **No new FAIL** may come from your files (fix it; if the rule is wrong for your
> data, say why in the report). Fix every new WARN that makes sense; a WARN you keep needs one line of reason. Your
> report gives the score before / after and ends with **"Data Lab notes"**: false alarms (check id, the value) and
> checks you would add. Never edit `tools/data_lab/` yourself; new sentinels, bounds or ids go through the lead.

## 6. Validation (2026-09-26, lab v1.0, first runs on the real data)
First scorecard: `docs/data/lab/2026-09-26_2240/scorecard.md` (history: `docs/data/lab/history.md`).
**Result WARN, score 98 / 100: 0 FAIL, 3 WARN checks (10 WARN findings), 28 PASS, 3 info.** All 64 ability / item /
spell texts print numbers that exist in their data (T5). Every file loads, every id
resolves, no NaN / negative / out-of-bound value, no key clash, every AI profile resolves with sane knobs.

Real findings (for the owners, the lab does not edit data):
| Finding | Owner | Fix |
|---|---|---|
| K4: `flame_guard` card_key **W**, `cinder_hand` **Q**, `ember_archer` **E** (plus `blaze_rider` R, `ash_hurler` T): the old keep keys Q W E R T. No code reads `UnitType.card_key` any more (slots are Z X C V B by index), so today it is a stale trap: wiring it would clash with Hero WASD / spells. Other kingdoms use Z X C V or nothing | gameplay-coder | clear `card_key` on the Fire units (or set the slot letters), or remove the field |
| B1: `grave_hound` (Shadow slot C) 16.3 DPS per 100 crystals vs slot median 7.4 (x2.2) | game-designer / Balance Lab | cheapest slot-C unit (70 crystals) with the highest DPS: check cost vs damage; slot C mixes cavalry (Blaze Rider, Grave Hound) and supports (Rime Seer, Bloomtender) |
| B1: `rime_seer` 3.3 and `bloomtender` 3.7 DPS / 100 vs 7.4 (supports, likely intended) | game-designer | note it in the spec or accept |
| B1 / F6: `ash_hurler` (Fire slot V) 43 EHP per 100 crystals vs 187 (x0.23), 60 HP vs slot V median 430: Fire's slot V is a fragile siege unit while the other kingdoms put a heavy there | game-designer | intended? then the AI mix / docs should treat slot V as "heavy or siege" |
| F6: `blaze_rider` 220 HP / 18 damage vs slot C median 70 / 7 (a cavalry unit among supports) | game-designer | same slot-role note |

False alarms found and fixed while tuning (so they stay fixed): item components have no tooltip by design (only items
with a passive / active need one); `first_scout_time = -1` is a documented sentinel; `oath_of_embers` is a campaign
reward with no recipe (INFO); champion names are shown without the title (measured apart); soldiers are compared per
card slot, not all together (heavies are not outliers); melee vs ranged range is a role, not an outlier; the Hollow
Stag (strength 700) sits with the beasts; status numbers (Hobbling Javelin's "-1.5 speed" = the `smoulder` modifier in
`Unit.STATUSES`) count as data for T5.

## 7. Known limits
- Hard bounds are lab defaults for broken values; the design tables (`units-fire-shadow.md`, `kingdom-*.md`,
  `items.md`...) are not parsed yet, so a value that is sane but off-spec only shows as a spread outlier.
- Text width uses the engine fallback font (the HUD has no custom font yet) and fixed widths from `ui_style.gd` /
  `selection_panel.gd`; real labels may use other sizes.
- Hotkeys come from data and a few code consts; key handling in `selection_manager.gd` (global keys, groups) is not
  parsed, so a clash between two code-defined global keys is not seen.
- Tooltip numbers are only cross-checked for champion classes ("N damage every S s", "reach N m").
- Loading takes ~9 s because the `.tres` files pull their model scenes.

## 7b. v1.1 (2026-09-27 lab review, group C): actionable reports
- Every finding has an **owner** (CLAUDE.md folders: `data/units/` gameplay-coder, `data/buildings/` systems-coder,
  `data/items/` items-coder, `data/ai/` ai-coder, `scripts/ui/` ui-coder...; balance checks B1 / F6 = game-designer;
  else the lead): an Owner column in "Findings" and a new **"Fix list by owner"** section right under "Improve next":
  one line per (check, fix) with every file it applies to, ready to paste into `docs/handoff/for-<owner>.md`.
- **T7 is actionable**: the lab writes `ui_strings.csv` next to the scorecard (key, file, line, text of every literal
  UI string, suggested `UI_...` keys, unique per text) = the key list for a CSV Translation + `tr(KEY)` pass; the T7 row
  names the distinct count and the 3 biggest scripts.
- INFO findings that only differ by a letter / number (the 12 "card_key X is set but no code reads it") collapse into
  one row with every place.
- Handoffs written 2026-09-27: gameplay-coder (stale Fire `card_key` W / Q / E / R / T), ui-coder (T7 + ui_strings.csv),
  game-designer (slot C / V roles, B1 / F6). Result unchanged: WARN 98 / 100, 0 FAIL (`docs/data/lab/review-after/`).

## 8. Next steps (Data Lab v2 backlog; agents' "Data Lab notes" go here)
- Parse the design stat tables (Markdown) into per-unit expected values: FAIL when data drifts from the spec.
- Cross-check spell / item / ability tooltip numbers against the fields (damage, cooldown, radius, duration).
- Read the key handling in `selection_manager.gd` / `command_card.gd` into one key map per context and check clashes
  there too; include the Ctrl / Shift / Alt layers.
- A strings table + `tr()` pass for the French UI (T7 is the list), then a French length check (French runs ~20 % longer).
- Research / tech tree data once `research.md` is implemented.

Progress: v1.0 done 2026-09-26 (all checks above, test PASS, first scorecard written).

# Unit Guide (main menu + pause menu)

Written 2026-10-05 for JS's request "a unit list with pros and cons you can see in the menu".

## 1. What the player sees
- **Main menu > Unit Guide** (between Campaign and Settings) and **pause menu > Unit Guide**. Back / Esc returns.
- Left: the list, grouped by kingdom (Fire, Ice, Nature, Shadow, Neutral), one row per unit: portrait, name,
  `T<tier> · <role> · <class>`. Right: the selected unit.
- Detail: portrait, name, kingdom / tier / role / class, **where it comes from** (building + card key), cost line
  (crystals, essence, pop, time), one-line summary, **stats** (HP, damage, DPS, range, speed, armour, sight, attack
  interval, effective HP = HP x (1 + armour / 100), crystals, pop, train time), regeneration / on-hit status, **abilities**
  with their key (`Z`, `V`, `G`, `Auto`, `Passive`, `Auto, L5`...), **Pros** (3), **Cons** (2-3) and the tags
  **Strong against / Weak against / Good with**.
- Filters: kingdom (All + 5), tier (All, T1-T3), role (melee, ranged, cavalry, caster, siege, support, titan, helper,
  champion, worker), search box (name, class, role, kingdom, building, tags; every word must match).
- **Compare**: the current unit becomes A, pick B in the list; stats side by side, the better value in green
  (lower is better for attack interval, crystals, pop, train time); `Swap A / B`.
- Keys: Up / Down browse (the detail follows the focus), Ctrl+F or `/` search, Enter in the search box jumps to the
  list, Esc closes.
- Portraits: `art/icons/units/<id>.png` when it exists (cached), else the unit's abbreviation (`UIStyle.abbrev`) in its
  kingdom colour. No 3D render (cheap; a model viewport can come later).

## 2. Where the numbers come from (never stale)
`scripts/ui/menus/unit_guide_data.gd` (`UnitGuideData`, static, cached):
- **Roster** (`roster()`): built from the game's own tables, per kingdom: the keep's `.tres` list (worker), the Hall's
  `.tres` list, `BowmanKit.HALL_BOWMAN`, `NewUnits12.HALL_UNITS`, `Stables16.ROSTER`, `CasterKit.BY_FACTION`,
  `T3Kit.KEEP_UNITS`, `HelperType.for_kingdom`; then the Caravan, `ChampionType.IDS`, the Stormbottle Genie and the
  Greywater Tracker. A unit added to one of those tables appears in the guide by itself (and the test fails until its
  text exists).
- **Stats** (`stats_of`): `UnitType` / `ChampionType` / `HelperType` fields; sight = `sight_radius` or
  `FogOfWar.UNIT_SIGHT`; champions cost `ChampionGuild.HIRE_COSTS[0]`; helpers `call_crystals` + `call_essence`.
- **Abilities**: casters from `CasterKit.SPELLS` / `PASSIVES` (keys Z / V), the 12 Hall units from `NewUnits12`,
  champions from `ChampionAbilities.ABILITIES` + `ChampionType.ability_name/_text`, Stables rank-ups from `Stables16`;
  the JSON adds the rest (bowmen, T3 units, helpers, workers, caravan, tracker).
- **Summary**: the JSON `summary` if set, else the game's tooltip line (`CasterKit` / `NewUnits12` / `Stables16` /
  `T3Kit` description, `CommandCard.TRAIN_DESCRIPTIONS`).

## 3. `data/ui/unit_guide.json`
```json
{ "version": 1, "units": {
  "<unit id>": {
    "role": "melee|ranged|cavalry|caster|siege|support|titan|helper|champion|worker",
    "class": "Line infantry",                 // free text, shown after the role
    "summary": "optional one line (<= 140)",   // else the game's tooltip line
    "abilities": [{"name": "Hamstring Shot", "key": "Auto", "text": "..."}],   // optional extra rows
    "pros": ["3 lines, <= 80 characters each"],
    "cons": ["2 or 3 lines, <= 80 characters each"],
    "strong_against": ["tags <= 24 chars"], "weak_against": ["..."], "good_with": ["..."]
  } } }
```
**Rank claims are checked.** A pro / con containing one of these phrases followed by `in the <Kingdom> army` or
`in any army` must be true today, or the test fails:
`highest hp`, `lowest hp`, `highest dps`, `lowest dps`, `hardest hitter`, `highest damage per hit`, `longest range`,
`fastest`, `slowest`, `most armour`, `longest sight`, `highest effective hp`, `lowest effective hp`,
`best / worst hp per crystal`, `best / worst dps per crystal`, `cheapest`, `most expensive`; and
`Top N for <hp | dps | range | speed | armour | sight | effective hp | hp per crystal | dps per crystal | damage per hit>
in ...`. The group = that kingdom's army (or all four), workers, helpers and neutral hires excluded; ties count as
first. Write other numbers sparingly (they are not checked): prefer a rank claim or a plain word ("slow", "fragile").
Counters must match real mechanics: armour is a percentage cut (it is not "strong vs many small hits"); there is no
anti-cavalry bonus in the game (cavalry-mounts.md's charge / anti-mount rules are not built), so counters to riders are
chill, roots, taunts, Hold the Line, towers and simply more HP.

## 4. Adding a unit
1. Add it to the game as usual (its `.tres` and the kit / building table that trains it).
2. Run the generator: `& tools/godot_run.ps1 --headless --path . -s res://tools/unit_guide/gen_guide.gd --quit-after 3000 '--' write`
   It adds a skeleton block (suggested role, claims that hold, suggested tags, `TODO` lines) for every roster id the
   JSON lacks, and never touches existing blocks.
3. Edit the block by hand: replace every `TODO`, keep 3 pros and 2-3 cons, check the tags.
4. Run the generator without `write` (exit 0 = clean) and `tests/test_unit_guide.gd`.
Generator output per unit: every stat with its rank in its army and in any army, the claims that hold, tag
suggestions, then `PROBLEM:` lines (lint + false claims). `'--' only=frostbow,shade` limits the print.

## 5. Checks
- `tests/test_unit_guide.gd`: roster coverage (every commandable kingdom `.tres` with a model and a cost, the 4
  champions, the 4 helpers, Caravan / Genie / Tracker), no stale JSON id, lint, claims (and that the checker catches
  a false one), stats = resources, the screen headless (filters, search, empty state, labels = data, compare + swap,
  every entry renders), main menu and pause menu open / close it.
- UI Lab screens `unit_guide` (Sunforge Cataphract) and `unit_guide_compare` (Blaze Rider vs Frostcrown Juggernaut).

## 6. Limits / later
- Titans (titans-2.md) are not in the game data yet: the `titan` role filter shows the empty line until they land.
- Wizards are not listed (heroes, not units); neutral camp creatures and epic beasts are not listed (not player units).
- Numbers are level 1 (no veterancy, research, items or Stables rank-up applied; the rank-up is listed as an ability).

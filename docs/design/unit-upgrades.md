# Unit upgrades: the Forge (2026-10-06)

JS: "we should have an upgrade building where you upgrade units", then "also some UNIT-SPECIFIC upgrades". Before this,
only the Hall's per-unit "+" (tiers.md 5, `UnitUpgrades`) and the Bazaar's gold wares (Tempered Steel...) existed.

## 1. The building
- One **Forge** per kingdom: Ember Forge (Fire), Gloom Forge (Shadow), Frost Forge (Ice), Grove Forge (Nature).
  `data/buildings/<kingdom>_forge.tres`, kind `&"forge"`, script `ForgeBuilding` (`scripts/buildings/forge_building.gd`,
  extends TrainingBuilding: the research IS its queue, so progress bar, cancel (full refund) and queue icons come free).
- 125 crystals, 40 s, 900 HP, 3 x 3, max 1 per team, **tier 1** (needs only the keep), build menu key **M** (r2c4).
  Not a drop-off, not a shop, no rally. Destroyed = the queued research is refunded (TrainingBuilding).
- Only in skirmish-type games (`ForgeKit.enabled_here()`: the scene's script inherits `skirmish.gd`, missions and
  Wave Strike excluded; tests set `ForgeKit.force_enabled`). The switch is `ForgeKit.ENABLED`.

## 2. Research (command card of the Forge)
Each button queues the next level of one line (key = its slot, test_ui_card_hotkeys rules). One level of a line in the
queue at a time; queue max 5; levels are permanent and apply to **every living and future soldier** of the team
(GoldBank.is_soldier_unit: not workers, wizards, champions, caravans, trackers). Modifier id `forge` (stats API),
range is a plain field: `+1` per level, tracked in the unit meta `forge_range`.

| Key | Line | Per level | Levels | Price / time | Tier per level |
|---|---|---|---|---|---|
| Z | Weapons | +6 % attack damage | 3 | 100 / 150 / 200 crystals, 35 / 45 / 55 s | 1 / 2 / 3 |
| X | Armor | +6 armor | 3 | same | 1 / 2 / 3 |
| C | Kingdom line (below) | see below | 3 | same | 1 / 2 / 3 |
| V B N | Unit-specific (below) | see below | 1 | 125 crystals, 40 s | 2 (Stronghold) |

Kingdom line: Fire **Kindled Fury** +4 % attack speed; Shadow **Shroudstep** +4 % move speed; Ice **Rimeforged Hide**
+5 % max HP; Nature **Sapblood** +0.25 HP/s regeneration.

Unit-specific (JS examples: lancer charge, archer range, caster mana, shield block):
| Kingdom | V | B | N |
|---|---|---|---|
| Fire | Ember Bowstrings: Ember Archer, Scorchbow +1 range | Lance Drill: Blaze Rider, Pyrehoof Lancer +10 % damage, +0.3 speed | Kiln Focus: Kilnwarden +25 % max mana and mana regen |
| Shadow | Nightstring: Nightbolt, Bleakbow +1 range | Dread Charge: Shadow Knight, Barrow Knight +10 % damage, +0.3 speed | Vigil Focus: Gloom Deacon +25 % max mana and mana regen |
| Ice | Rime Fletching: Shardcaster, Frostbow +1 range | Shield Wall: Rimeshield +6 armor | Carver's Focus: Rimecarver +25 % max mana and mana regen |
| Nature | Thornstring: Wildwood Archer, Burr Slinger +1 range | Barkskin: Thornling +6 armor | Sage's Focus: Bramblesage +25 % max mana and mana regen |

Everything maxed = +18 % damage, +18 armor (~15 % less damage taken) and the kingdom line at 3: modest next to the Hall
"+" (+10 % HP / damage) and the wares; the total costs 1 350 + 375 crystals and ~7 min of Forge time.

## 3. Balance
The Unit Lab and the balance matrices run at **level 0** (no Forge node: nothing applies). Numbers are knobs in
`ForgeKit.LINES` / `UNIT_LINES`; re-run the mixes before raising them.

## 4. Bots
`ForgeKit.bot_step` (Commander rule 5, after the Stables step, never before a due champion hire): build the Forge from
9:00 / 6:30 / 5:00 (easy / normal / hard) when crystals >= cost + reserve (never saves for it); then, every 8 s with an
empty Forge queue, research the cheapest open line up to level 1 / 2 / 3 (unit-specific lines: normal and hard, when the
team has >= 2 of those units) while crystals >= price + 300 / 200 / 150.

## 5. UI
- Build menu: M = the Forge (tooltip: what it researches). Forge card: the 6 research buttons (cost, time, effect,
  current level, `Requires Stronghold / Citadel`, `Max level`, `Already in progress`).
- Selection panel (one own soldier): a `Forge: Weapons 2 · Armor 1 · ...` row when any line applies to it.
- Unit Guide: every soldier lists "Forge upgrades" (the 3 lines at level 3); units with a unit-specific line list it.
- French: `data/i18n/fr/*.po` (Forge = Forge; names stay English per the glossary).

## 6. Tests
`tests/test_unit_upgrades.gd`: data, card keys / press, research and apply (living + new units), refund, tier gates,
unit-specific (range, armor, mana), missions off, bot research, French strings.

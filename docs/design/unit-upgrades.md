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

**2026-10-14: V B N leave the Forge** (section 7). The 12 unit-specific lines move, same ids and numbers, to unit
research at the building that trains the unit; the Forge card keeps Z X C only. The table below stays as history.

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

---

# Unit-specific upgrades at the training building (spec 2026-10-14, not built)

JS (2026-10-14): "add unit specique upgrade to most unit and a way in the barrack to upgrade that specique unit".
Skirmish only (plain skirmish + layout maps; missions and Wave Strike off, Unit Lab at level 0).

## 7. What exists today, and what changes
| System | Where | Per unit? | UI today | After this spec |
|---|---|---|---|---|
| "+" (`UnitUpgrades`, tiers.md 5) | Hall, Stronghold | 32 units, same +10 % HP / damage | Hall "+" page | unchanged effect; shown on the new unit page (slot Z) |
| Bowman upgrades (`BowmanUpgrades`, bowmen.md 4) | Hall | 7 rows, 4 bowmen | **none (never wired)** | rows move into `UnitResearch` (same ids, prices, code), finally buyable |
| Forge V B N unit lines (`ForgeKit.UNIT_LINES`) | Forge | 12 lines | Forge card | **move** to `UnitResearch` (same ids and numbers), Forge keeps Z X C |
| Stables rank-3 (`Stables16`, stables.md 3) | Stables, Citadel | 8 units | Stables B / N | unchanged; also shown on the unit page |
| **New unit research** | the building that trains the unit | 55 new rows | new unit page | this spec |

One table (`UnitResearch.ROWS`) holds the 55 new rows, the 12 moved Forge lines and the 7 bowman rows. A row can list
several units (the moved Forge lines do: Ember Bowstrings = Ember Archer + Scorchbow): one research, shown on each of
those units' pages, buyable at any own building that trains one of them.

**Who gets research:** every trainable combat unit of the 4 kingdoms (Hall 8, Stables 4, keep caster, keep tier-3 unit =
14 per kingdom). Excluded: workers, caravans; **champions** (they already grow by level, class and their own skill tree,
and the player never orders them); **helpers** (their level is the wizard's); the **Stormbottle Genie** (a neutral
tavern hire, one per team). Two Stables heavies (Rimehorn Rider, Thornback Charger) get no new row: their rank-3 is
their unit-specific upgrade.

## 8. Rules
- Researched **once per team**, permanent, applies to every living and future unit of the listed types (same apply path
  as the Forge: at completion to the living ones, `node_added` for new ones).
- **Where:** an own, completed, living building whose trainable list holds one of the row's units (Hall, Stables, keep).
- **Price:** crystals only (no essence: essence stays the wizard's item / champion currency). Bands by tier gate:

| Gate | Price | Time | Used for |
|---|---|---|---|
| Tier 1 (no gate) | 75 (unit cost <= 100) / 100 (otherwise) | 30 / 35 s | the first row of a tier-1 unit |
| Tier 2 Stronghold | 125 (unit cost < 250) / 150 (otherwise, or a strong mechanic) | 40 / 45 s | second rows, tier-2 units, moved Forge lines |
| Tier 3 Citadel | 175 (unit cost < 350) / 200 (otherwise) | 50 / 60 s | tier-3 units, caster second rows |
Bowman rows keep their bowmen.md 4 numbers (75-200, no tier gate, `needs` chains).
- **Queue:** research never blocks training. Each building has **one research slot**, shared by the "+" and unit
  research (a Hall cannot run a "+" and a unit row at once); Stables rank-3 keeps its own slot. No queue behind it: a
  second press while busy is refused. Two Halls = two research at once.
- **Refusals** (first that applies; logic text, shown through `Loc.sink`):
  `"No upgrade for that unit"`, `"Already researched"`, `"Already in progress"`,
  `"Needs a completed building that trains it"` (new), `"Requires Stronghold"` / `"Requires Citadel"`
  (`TierSystem.gate_reason`), `"Needs %s"` (bowman chains; the name of the missing row), `"Busy with another upgrade"`
  (new; replaces `"The Hall is busy with another upgrade"` in `UnitUpgrades` too), `"Not enough crystals"` (flashes the
  top bar through `Economy.spend` failing, as today).
- **Cancel:** full refund (the row's key again on the unit page, or the research chip's cancel in the building view).
  Building destroyed mid-research: **75 %** refund (as "+" / bowman rows). Completion message:
  `Research complete: {name} ({unit})` + the building-done alert.
- **Tier lost** (the Stronghold keep dies): done research stays; a research in progress continues.

## 9. The rows
Kinds (how the effect is built, section 10): **M** = stat modifier `research:<id>`; **R** = + attack range; **H** = an
on-hit / on-damage / on-kill rule in `ResearchEffects` (new gameplay code); **S** = support numbers; **K** = a kit number
read through `UnitResearch.param` (the unit's ability code reads it). Order in each unit = its key on the unit page
(X, C, V...). Moved rows are marked (F) Forge or (B) bowmen.md.

### 9.1 Fire (16 rows + 2 bowman)
| Unit (building) | id | Name | Gate | Price / time | Effect | Kind |
|---|---|---|---|---|---|---|
| Flame Guard (Hall) | `flame_guard_kindled_mail` | Kindled Mail | 1 | 75 / 30 | +5 armor | M `armor 5` |
| Flame Guard | `flame_guard_backdraft` | Backdraft | 2 | 125 / 40 | melee attackers take 3 damage per hit they land on it | H thorns 3 |
| Ember Archer (Hall) | `ember_archer_quick_nock` | Quick Nock | 1 | 75 / 30 | -10 % attack cooldown | M `attack_cooldown_pct -0.10` |
| Ember Archer, Scorchbow | `fire_bowstrings` (F) | Ember Bowstrings | 2 | 125 / 40 | +1 attack range | R 1 |
| Blaze Rider (Hall, Stables) | `blaze_rider_running_start` | Running Start | 1 | 100 / 35 | first hit on a fresh target +12 damage | H first_hit 12 |
| Blaze Rider, Pyrehoof Lancer | `fire_lances` (F) | Lance Drill | 2 | 125 / 40 | +10 % damage, +0.3 speed | M |
| Ash Hurler (Hall) | `ash_hurler_wheeled_mantlet` | Wheeled Mantlet | 1 | 100 / 35 | +35 % max HP (60 -> 81) | M `max_hp_pct 0.35` |
| Ash Hurler | `ash_hurler_packed_shot` | Packed Shot | 2 | 150 / 45 | each shot also hits enemy units within 1.5 m of the target for 40 % | H splash 1.5 / 0.4 |
| Scorchbow (Hall) | `scorchbow_heavy_draw`, `scorchbow_pitch_arrows` (B) | Heavy Draw, Pitch Arrows | - | 100 / 35, 125 / 45 | bowmen.md 4 | as built |
| Scorchling (Hall) | `scorchling_volatile_core` | Volatile Core | 1 | 75 / 30 | Flashpoint 15 -> 25 damage, radius 2 -> 2.5 m | K |
| Pyre Adept (Hall) | `pyre_adept_kindling_lore` | Kindling Lore | 2 | 125 / 40 | Flame Burst fires on 2+ enemies (was 3), radius 2.5 -> 3 m | K |
| Cinder Arbalest (Hall) | `cinder_arbalest_barbed_bolts` | Barbed Bolts | 2 | 125 / 40 | pierce to the enemy behind 50 % -> 80 % | K |
| Emberdart Harrier (Stables) | `emberdart_harrier_firebrand` | Firebrand Javelins | 1 | 100 / 35 | hits burn 2 / s for 3 s (DoT `burn`, the Scorchbow rule) | H dot |
| Sunforge Cataphract (Stables) | `sunforge_cataphract_dawnshield` | Dawnshield | 3 | 200 / 60 | hit after 5 s unhurt: shield 120 for 6 s (once per 20 s) | H combat_shield |
| Kilnwarden (keep) | `fire_caster` (F) | Kiln Focus | 2 | 125 / 40 | +25 % max mana and mana regen | M |
| Kilnwarden | `kilnwarden_molten_slag` | Molten Slag | 3 | 175 / 50 | Slag Rain 12 -> 18 damage, radius 3 -> 3.5 m | K |
| Ashveil Saboteur (keep) | `ashveil_saboteur_double_powder` | Double Powder | 3 | 175 / 50 | Powder Charge 250 -> 325 damage, training pause 10 -> 14 s | K |
Pyrehoof Lancer: Lance Drill + rank-3.

### 9.2 Shadow (17 rows + 1 bowman)
| Unit (building) | id | Name | Gate | Price / time | Effect | Kind |
|---|---|---|---|---|---|---|
| Shade (Hall) | `shade_siphoning_blades` | Siphoning Blades | 1 | 75 / 30 | 15 % lifesteal | M `lifesteal 15` |
| Shade | `shade_shroudcloak` | Shroudcloak | 2 | 125 / 40 | +8 % speed, +5 armor | M |
| Nightbolt (Hall) | `nightbolt_hexed_bolts` | Hexed Bolts | 2 | 125 / 40 | hits mark the target 2 s (`marked`: takes +15 % damage) | H on_hit_status |
| Nightbolt, Bleakbow | `shadow_bowstrings` (F) | Nightstring | 2 | 125 / 40 | +1 attack range | R 1 |
| Grave Hound (Hall) | `grave_hound_pack_hunger` | Pack Hunger | 1 | 75 / 30 | +2 damage while another Grave Hound is within 5 m | H pack_aura |
| Grave Hound | `grave_hound_bone_fed` | Bone-Fed | 2 | 125 / 40 | +25 % max HP | M |
| Shadow Knight (Hall) | `shadow_knight_grim_reprisal` | Grim Reprisal | 1 | 100 / 35 | falls under 50 % HP: `braced` 4 s (damage taken x0.7), once per 30 s | H low_hp_status |
| Shadow Knight, Barrow Knight | `shadow_knights` (F) | Dread Charge | 2 | 125 / 40 | +10 % damage, +0.3 speed | M |
| Bleakbow (Hall) | `bleakbow_serrated_barbs` (B) | Serrated Barbs | - | 100 / 40 | bowmen.md 4 | as built |
| Barrow Ghoul (Hall) | `barrow_ghoul_gorge` | Gorge | 1 | 75 / 30 | Grave Feast heal on a kill 30 % -> 50 % | K |
| Hexweaver (Hall) | `hexweaver_deepening_hex` | Deepening Hex | 2 | 125 / 40 | Wither Hex 6 -> 8 s and -1 move speed | K |
| Hollow Oathsworn (Hall) | `hollow_oathsworn_oath_unending` | Oath Unending | 2 | 150 / 45 | Unbroken Vow cooldown 45 -> 30 s, shield 50 -> 80 | K |
| Gloam Rider (Stables) | `gloam_rider_nightdrinker` | Nightdrinker | 1 | 100 / 35 | 20 % lifesteal | M `lifesteal 20` |
| Duskbolt Harrier (Stables) | `duskbolt_harrier_bleeding_bolts` | Bleeding Bolts | 1 | 100 / 35 | hits bleed 2 / s for 4 s (DoT `dusk_bleed`, refresh, own id: never stacks with Bleakbow stacks) | H dot |
| Veilborn Dreadrider (Stables) | `veilborn_dreadrider_veil_ride` | Veil Ride | 3 | 200 / 60 | falls under 50 % HP: `shroud` 4 s (+2 speed, damage taken x0.5), once per 30 s | H low_hp_status |
| Gloom Deacon (keep) | `shadow_caster` (F) | Vigil Focus | 2 | 125 / 40 | +25 % max mana and mana regen | M |
| Gloom Deacon | `gloom_deacon_hungering_tithe` | Hungering Tithe | 3 | 175 / 50 | Blood Tithe heal 10 -> 14 / s, drain 5 -> 7 / s | K |
| Nightblood Reaver (keep) | `nightblood_reaver_crimson_thirst` | Crimson Thirst | 3 | 175 / 50 | heals 35 % -> 45 % of its damage; Blood Frenzy under 50 % HP (was 40) | K |
Barrow Knight: Dread Charge + rank-3.

### 9.3 Ice (17 rows + 1 bowman)
| Unit (building) | id | Name | Gate | Price / time | Effect | Kind |
|---|---|---|---|---|---|---|
| Rimeshield (Hall) | `rimeshield_frostrim` | Frostrim Shields | 1 | 75 / 30 | hits chill 1 s | H on_hit_status |
| Rimeshield | `ice_shields` (F) | Shield Wall | 2 | 125 / 40 | +6 armor | M |
| Shardcaster (Hall) | `shardcaster_deep_chill` | Deep Chill | 1 | 100 / 35 | chill per hit 1.5 -> 2.5 s | H on_hit_status |
| Shardcaster, Frostbow | `ice_bowstrings` (F) | Rime Fletching | 2 | 125 / 40 | +1 attack range | R 1 |
| Rime Seer (Hall) | `rime_seer_thick_rime` | Thick Rime | 1 | 100 / 35 | ward shield 60 -> 85 | S amount |
| Rime Seer | `rime_seer_quick_ward` | Quick Ward | 2 | 125 / 40 | a ward every 9 s (was 12) | S interval |
| Rime Colossus (Hall) | `rime_colossus_glacial_stride` | Glacial Stride | 1 | 100 / 35 | +0.6 move speed (3.4 -> 4.0) | M `move_speed 0.6` |
| Rime Colossus | `rime_colossus_shatter_blow` | Shatter Blow | 2 | 150 / 45 | +20 % damage to a chilled or frozen target | H bonus_vs_status |
| Frostbow (Hall) | `frostbow_rimed_shafts` (B) | Rimed Shafts | - | 100 / 40 | bowmen.md 4 | as built |
| Rimeling (Hall) | `rimeling_thick_furs` | Thick Furs | 1 | 75 / 30 | +25 % max HP | M |
| Hoarlight Magebow (Hall) | `hoarlight_magebow_needle_volley` | Needle Volley | 2 | 125 / 40 | Frost Needle cooldown 8 -> 6 s, damage 20 -> 26 | K |
| Frost Mortar (Hall) | `frost_mortar_wide_shells` | Wide Shells | 2 | 150 / 45 | Frost Shell radius 2 -> 2.75 m | K |
| Snowdrift Rider (Stables) | `snowdrift_rider_snowblind_charge` | Snowblind Charge | 1 | 100 / 35 | first hit on a fresh target +10 damage and chill 2 s | H first_hit |
| Rime Harrier (Stables) | `rime_harrier_hoarfrost_tips` | Hoarfrost Tips | 1 | 100 / 35 | chill per hit 1 -> 2 s | H on_hit_status |
| Frostcrown Juggernaut (Stables) | `frostcrown_juggernaut_glacier_heart` | Glacier Heart | 3 | 200 / 60 | +20 % max HP, +5 armor | M |
| Rimecarver (keep) | `ice_caster` (F) | Carver's Focus | 2 | 125 / 40 | +25 % max mana and mana regen | M |
| Rimecarver | `rimecarver_deep_bulwark` | Deep Bulwark | 3 | 175 / 50 | Rime Bulwark lasts 12 s (was 8), 5 m long (was 4) | K |
| Shardguard (keep) | `shardguard_shard_ward` | Shard Ward | 3 | 175 / 50 | Hold the Line also shields it 100 for 6 s | K |
Rimehorn Rider: rank-3 only.

### 9.4 Nature (17 rows + 3 bowman)
| Unit (building) | id | Name | Gate | Price / time | Effect | Kind |
|---|---|---|---|---|---|---|
| Thornling (Hall) | `thornling_briar_coat` | Briar Coat | 1 | 75 / 30 | melee attackers take 2 damage per hit they land on it | H thorns 2 |
| Thornling | `nature_bark` (F) | Barkskin | 2 | 125 / 40 | +6 armor | M |
| Burr Slinger (Hall) | `burr_slinger_sticky_burrs` | Sticky Burrs | 1 | 75 / 30 | every 5th hit roots the target 0.5 s | H every_nth |
| Burr Slinger, Wildwood Archer | `nature_bowstrings` (F) | Thornstring | 2 | 125 / 40 | +1 attack range | R 1 |
| Bloomtender (Hall) | `bloomtender_deep_roots` | Deep Roots | 1 | 75 / 30 | heal 12 -> 16 | S amount |
| Bloomtender | `bloomtender_wide_bloom` | Wide Bloom | 2 | 125 / 40 | heal range 7 -> 9 m | S range |
| Bramblehorn (Hall) | `bramblehorn_gorehorn` | Gorehorn | 1 | 100 / 35 | first hit on a fresh target +12 damage | H first_hit |
| Bramblehorn | `bramblehorn_mossback` | Mossback | 2 | 150 / 45 | +5 armor, out-of-combat regen 2 -> 3 % / s | M + H idle_regen |
| Wildwood Archer (Hall) | `wildwood_keen_eye`, `wildwood_heartseeker`, `wildwood_hunting_party` (B) | Keen Eye, Heartseeker Points, Hunting Party | - | bowmen.md 4 | bowmen.md 4 | as built |
| Thistle Darter (Hall) | `thistle_darter_quickfoot` | Quickfoot | 1 | 75 / 30 | Skitter +1.5 speed for 2.5 s (was +1 / 1.5 s) | K |
| Vinelasher (Hall) | `vinelasher_strangling_vines` | Strangling Vines | 2 | 125 / 40 | Snare Lash 10 -> 18 damage, root 1.5 -> 2 s | K |
| Greenheart Oathkeeper (Hall) | `greenheart_oathkeeper_heartwood_oath` | Heartwood Oath | 2 | 150 / 45 | Grove Oath radius 5 -> 6.5 m, brace 4 -> 5 s | K |
| Stagrunner (Stables) | `stagrunner_wild_gallop` | Wild Gallop | 1 | 100 / 35 | its attack kills a unit: `haste` 3 s | H kill_status |
| Bramble Harrier (Stables) | `bramble_harrier_pollen_darts` | Pollen Darts | 1 | 100 / 35 | every 3rd hit: `hazed` 1.5 s (ranged enemies only shoot within 2.5 m) | H every_nth |
| Glade Outrider (Stables) | `glade_outrider_far_sight` | Far Sight | 3 | 200 / 60 | +2 attack range (8 -> 10) | R 2 |
| Bramblesage (keep) | `nature_caster` (F) | Sage's Focus | 2 | 125 / 40 | +25 % max mana and mana regen | M |
| Bramblesage | `bramblesage_deep_snag` | Deep Snag | 3 | 175 / 50 | Snagroot drags 9 m (was 7; heroes 4 unchanged), root 1 -> 1.5 s (heroes 0.5 unchanged) | K |
| Briar Roc (keep) | `briar_roc_thornstorm` | Thornstorm | 3 | 200 / 60 | Seed Storm every 12 s (was 16), 30 -> 40 damage | K |
Thornback Charger: rank-3 only.

**Count:** Fire 16, Shadow 17, Ice 17, Nature 17 = **67 rows** (55 new + 12 moved from the Forge), plus the 7 bowman
rows now buyable. Every one of the 56 combat units has at least one unit-specific upgrade ("+", rank-3 or a row);
54 of them have a row of this table.

## 10. Effects as data (`UnitResearch.ROWS` shape)
```
&"flame_guard_kindled_mail": {"name": "Kindled Mail", "units": [&"flame_guard"], "tier": 1, "price": 75,
    "time": 30.0, "needs": &"", "text": "+5 armor",
    "mods": {&"armor": 5.0},          # M: Unit modifier "research:<id>" (Stats contract keys, lifesteal included)
    "range": 0.0,                     # R: + attack_range, tracked in the runtime meta "_research_range" (Forge pattern)
    "effect": {},                     # H: {"kind": ..., params} read by ResearchEffects
    "kit": {}},                       # K / S: {param_key: value} read by UnitResearch.param()
```
**H kinds** (gameplay-coder, `scripts/units/research_effects.gd`, static, called from `Unit`):
| kind | Params | Rule |
|---|---|---|
| `on_hit_status` | status, seconds | each landed hit on a Unit applies it (after the type's own; `apply_status` keeps the longer) |
| `every_nth` | n, status, seconds | counter in runtime meta `_rs_nth`; every n-th landed hit on a Unit applies it |
| `first_hit` | damage, status?, seconds? | the first hit on a target this unit has not hit in the last 6 s deals +damage (a second `take_damage` from the unit) and the status; at most once per 4 s per unit |
| `bonus_vs_status` | statuses, pct | a hit on a target that had one of the statuses **before** this hit deals +pct of the hit (checked before the on-hit statuses land) |
| `splash` | radius, ratio | ratio x dealt to every other enemy Unit within radius of the target (no buildings, no further on-hit) |
| `dot` | id, dps, seconds | `apply_dot` (refresh, the stronger wins) |
| `thorns` | damage | an enemy Unit with `attack_range <= 2.5` within 3.5 m that damages this unit takes `damage` from it (armor applies; once per attacker per 0.5 s; never buildings) |
| `combat_shield` | amount, seconds, idle, cooldown | damage taken after `seconds_since_damage() >= idle`: `add_shield(amount, seconds)`, once per cooldown |
| `low_hp_status` | pct, status, seconds, cooldown | HP falls under pct x max: `apply_status(status, seconds, true)`, once per cooldown |
| `kill_status` | status, seconds | its attack leaves the target dead: `apply_status` on itself |
| `pack_aura` | radius, stats | `apply_aura(&"research_pack_hunger", radius, stats, filter = another living unit of the same type, not self)` |
| `idle_regen` | pct | `set_idle_regen_pct(pct)` |
**K / S param keys** (the ability code reads `UnitResearch.param(unit, key, default)`; default = today's constant):
`flashpoint_damage 25`, `flashpoint_radius 2.5`, `flame_burst_min_count 2`, `flame_burst_radius 3`, `pierce_ratio 0.8`,
`grave_feast_heal_pct 0.5`, `wither_time 8`, `wither_move_speed -1`, `vow_cd 30`, `vow_shield 80`,
`frost_needle_cd 6`, `frost_needle_damage 26`, `frost_shell_radius 2.75`, `skitter_speed 1.5`, `skitter_time 2.5`,
`snare_damage 18`, `snare_root 2`, `grove_oath_radius 6.5`, `grove_oath_brace 5`, `slag_rain_damage 18`,
`slag_rain_radius 3.5`, `tithe_heal 14`, `tithe_drain 7`, `bulwark_time 12`, `bulwark_length 5`, `snag_drag 9`,
`snag_root 1.5`, `powder_damage 325`, `powder_pause 14`, `reaver_lifesteal 0.45`, `frenzy_hp_pct 0.5`,
`hold_line_shield 100`, `hold_line_shield_time 6`, `seed_storm_cd 12`, `seed_storm_damage 40`,
`support_amount` (Seer 85, Bloomtender 16), `support_interval 9`, `support_range 9`.
Flagged as new gameplay code: every H kind (one file + call sites in `Unit._on_attack_hit`, `take_damage`, and the
apply path) and each K read (one line per constant in its kit). M and R need nothing new.

## 11. Command card and UI needs (looks and positions: ui-designer)
- **Research page** = today's Hall "+" page, generalised: button r3c5 (label `+`, keys `=` / numpad + as today) on an own
  **Hall, Stables or keep** that trains at least one unit with a "+" or a row. On the page each trainable unit sits on its
  training slot with its training key (Z X C V B N M , on a Hall); a unit with nothing to research is empty. Back = Esc /
  r3c5. While open, unit keys never train (as today).
- **Unit page** (new): pressing a unit's key (or clicking it) on the research page opens that unit's page:
  **Z** = its "+" (empty when it has none), **X C V B** = its rows in table order (moved rows included), then the Stables
  rank-3 on the next free key (Blaze Rider: Z "+", X Running Start, C Lance Drill, V rank-3; Wildwood Archer: Z "+",
  X Keen Eye, C Heartseeker Points, V Hunting Party, B Thornstring). Esc / r3c5 = back to the research page, `+` closes
  both. Max 5 buttons (checked by the test). Change for players: on the research page the unit key no longer buys the
  "+" directly; it is `+`, unit key, Z.
- Row button states: ready / short of crystals / locked (lock glyph + `Requires Stronghold`) / researching (progress %,
  pressing it again = cancel, full refund, tooltip says so) / done (`Researched`). Tooltip: name + key, cost and time,
  effect text, the reason line.
- Stables keep B / N for rank-3 on their main card (unchanged shortcut).
- The building view shows the running research (icon, progress, cancel) beside the training queue.
- Training button tooltip of a unit: one line `Research: 1 / 2 done` (+ "+" and rank-3 counted).
- One own soldier selected: a `Research:` line with the names done for it (+ "+", rank-3); hover = their effects. The Forge
  row (section 5) no longer lists unit lines.
- Unit Guide: each unit lists its research rows (name, building, tier, price, effect) in an "Upgrades" block, generated
  from the table (`UnitGuideData`), replacing the Forge unit-line entries and the hand-written "Hall research" lines of
  the bowmen in `unit_guide.json`.
- Icons: `art/icons/research/<id>.png` when present, else the unit icon with a small "+" badge (no art task needed).

## 12. Balance, bots, save, text
**Balance.** Each row is worth about +10-15 % of its unit's value; the expensive mechanics sit at tier 2-3. Researching
everything costs ~2 000 crystals per kingdom; a normal army comp uses 4-6 rows (~500-700 crystals). Knobs: the row's
numbers in `UnitResearch.ROWS`. Measuring:
1. Unit Lab: for each K / H row, `run_unit_lab.ps1 "<n> <unit> vs <n> <counter>"` with and without the row (`-Variants`
   arm that grants it); an upgraded unit's win rate vs its counter rises by <= 15 points.
2. Bot-vs-bot: `python tools/balance_lab/faster_games/run_fg.py --run ur1 --arms baseline,ur_off --levels normal,hard
   --seeds 1-3` (all 4 x 4 pairs; arm `ur_off` = a variant that sets `UnitResearch.lab_off = true`). Pass: no kingdom
   above 55 % (or 5 points worse than its `ur_off` number), each row bought in >= 10 % of the games where its unit was
   massed, game length within 10 % of `ur_off`. First knobs if a kingdom jumps: Pack Hunger, Packed Shot, Hexed Bolts.

**Bots** (ai-coder, `scripts/ai/ai_research.gd`, called by Commander rule 5 in place of `BowmanUpgrades.bot_try_buy`):
every 6 s, one buy at most per pass, shared with the "+" (`UnitUpgrades.bot_try_buy` runs first in the same pass; if
it bought, skip). Pick the own unit type with the most living units that meets the count (pop 1: >= 3; pop 2+: >= 2;
casters >= 2; tier-3 >= 1; hard: one less), then its next open row in table order; buy at a building that can, when
crystals >= price + reserve. Never saves for research; skipped while the Stronghold / Citadel or a champion hire is
being saved for.

| Difficulty | Rows allowed | Max rows per match | Reserve |
|---|---|---|---|
| Easy | tier-1 rows only | 2 | 300 |
| Normal | all | 6 | 200 |
| Hard | all | no cap | 150 |
Bowman rows follow the same rule (bowmen.md 6 thresholds replaced). Log line `research <id>` in the bot log.

**Save / load.** `UnitResearch` (one node per team, groups `"unit_research"` and `"saved_state"`): `save_key()` =
`"unit_research_<team>"`, `save_state()` = `{done: [ids], work: [{id, building save id, left, paid}]}`, `load_state`
grants the done rows (re-applies to every unit) and restores the work; static `create_for_save(level, key)`. Unit
modifiers `research:<id>` are **not** saved with the unit (re-applied on load, like `forge`); runtime state lives in
`_`-prefixed metas (`_rs_nth`, `_rs_first_hit`, `_rs_cd_<kind>`, `_research_range`), absolute times only in `_` metas.
Old saves: ForgeKit unit-line levels and BowmanUpgrades done ids load as granted rows. `tests/test_save_metas.gd` passes.

**Text.** Row names are proper names (glossary: never translated). Effect texts and the new refusals / messages are
logic text in English, shown through `Loc.sink`; templates (`Research complete: {name} ({unit})`, `Research: {done} /
{total} done`, `Needs %s`) through `Loc.t`, no concatenated fragments. French in `data/i18n/fr/game_logic.po` (texts)
and `ui.po` (templates); `tools/i18n/extract_strings.gd '--' merge`, then `tests/test_i18n.gd`.

## 13. API (systems-coder, `scripts/buildings/unit_research.gd`, `class_name UnitResearch`)
`ENABLED`, `static var lab_off`, `ROWS`, `MODIFIER_PREFIX = "research:"`; static `for_team(team, create := true)`,
`enabled_here()` (ForgeKit rule; missions only with a `research_enabled` knob, default off), `rows_for_unit(unit_id)`,
`unit_ids_for_building(b)`, `team_has(team, id)`, `has(unit, id)`, `param(unit, key, default) -> float`,
`effects_of(unit) -> Array[Dictionary]`, `apply_to(unit)` (modifier, range, then `ResearchEffects.on_applied(unit)`
through a load guard), `building_busy(b) -> bool` (counts the "+" too), `options_for_unit(b, unit_id)` (UI rows: id,
name, text, crystals, time, state ready / working / done / locked, progress, reason); instance `can_buy(id, b)`,
`buy(id, b)`, `cancel(id)`, `grant(id)`, `is_working(id)`, `progress(id)`, `working_at(b) -> StringName`, signals
`research_started(id)`, `research_completed(id)`, `research_cancelled(id, refund)`.

## 14. Tasks
Order: UR.S1 first; then the rest in parallel except UR.G2 (after UR.G1) and UR.U2 (after UR.U1). No two parallel tasks
share a file.
| Id | Owner | Files | Task | Done when |
|---|---|---|---|---|
| UR.S1 | systems-coder | `scripts/buildings/unit_research.gd` (new) | Section 13: table (67 rows + 7 bowman rows), buy / cancel / busy / refunds / tier gates, apply (M, R, `param`, `effects_of`), save / load, `lab_off` | `tests/test_unit_research.gd`: every row's data valid (units exist, gate, price band); refusal order; one slot per building shared with "+"; 75 % refund on destroy; living + new units get `research:<id>`; range +1 not doubled after save / load; missions and Wave Strike off |
| UR.S2 | systems-coder | `forge_kit.gd`, `forge_building.gd`, `unit_upgrades.gd` | Forge card Z X C only, `UNIT_LINES` removed (moved), old-save mapping; "+" uses `UnitResearch.building_busy` and the new busy text | `tests/test_unit_upgrades.gd` updated PASS; old Forge save with `fire_lances` 1 loads as the granted row |
| UR.G1 | gameplay-coder | `scripts/units/research_effects.gd` (new), `unit.gd` call sites | H kinds on the hit path: on_hit_status, every_nth, first_hit, bonus_vs_status, splash, dot | `tests/test_research_effects.gd` rows per kind PASS; smoke + perf PASS |
| UR.G2 | gameplay-coder (after G1) | same two files | H kinds off the hit path: thorns, combat_shield, low_hp_status, kill_status, pack_aura, idle_regen, `on_applied` | `tests/test_research_passives.gd` PASS (thorns never hit buildings, cooldowns hold) |
| UR.G3 | gameplay-coder | `new_units_12.gd`, `support_caster.gd` | K reads for the 12 Hall units' rows, S reads (amount, interval, range) | `tests/test_research_kits_hall.gd`: each key changes the number only for the team that has the row |
| UR.G4 | gameplay-coder | `caster_kit.gd`, `caster_ability.gd`, `t3_unit_ability.gd` (+ the Saboteur charge file) | K reads for the 4 caster rows and 4 tier-3 rows | `tests/test_research_kits_keep.gd` PASS; Unit Lab C1-C7 unchanged without research |
| UR.G5 | gameplay-coder | `bowman_upgrades.gd`, `bowman_kit.gd` | `BowmanUpgrades` becomes a facade over `UnitResearch` (same ids / effects), old saves map | `tests/test_bowmen.gd` (existing) PASS + `tests/test_research_bowmen.gd` (chains, Hunting Party) PASS |
| UR.D1 | ui-designer | `docs/design/ui-sc2-console.md` | Look of the research page, unit page, research chip in the building view, selection line, alert | Section 11 needs placed and drawn |
| UR.U1 | ui-coder | `command_card.gd`, `selection_manager.gd` | Research page on Hall / Stables / keep, unit page keys, cancel, tooltips, messages | `tests/test_research_card.gd` (keys Z-B per page, max 5, cancel refund, locked reasons) + `test_ui_card_hotkeys` PASS |
| UR.U2 | ui-coder (after U1) | `selection_panel.gd`, building view, `unit_guide_data.gd`, `unit_guide.json`, `data/i18n/fr/*.po` | Selection line, research chip, Unit Guide block, French strings | `test_unit_guide`, `test_i18n` PASS; UI Lab shots en / fr no FAIL |
| UR.A1 | ai-coder | `scripts/ai/ai_research.gd` (new), `commander.gd` | Section 12 bot rule, replaces the bowman call | `tests/test_research_bot.gd`: hard buys >= 3 rows by 15:00, easy only tier-1 rows and <= 2; Forge / "+" / tier saving not delayed |
| UR.B1 | game-designer + labs | variant `ur_off`, `docs/balance/` | Section 12 measuring plan | Pass bars met, or the knobs changed and re-run |

## 15. Defaults taken
| Question | Default |
|---|---|
| Essence in the price? | No: crystals only, bands 75-100 / 125-150 / 175-200 |
| Forge V B N | Moved to unit research (same ids and numbers); the Forge keeps Z X C |
| Champions, helpers, Genie | No research (own growth systems / neutral hire) |
| Research blocks training? | No; one research slot per building, shared with the "+"; no queue behind it |
| Keys | `+` = research page, unit key = unit page, Z = "+", X C V B = rows; Stables B / N rank-3 stay |
| Bowman upgrades | Join the table, finally buyable (they had no button) |
| Two rows or one | Two for the Hall's 4 core units and the casters; one for the rest; Rimehorn / Thornback keep only rank-3 |

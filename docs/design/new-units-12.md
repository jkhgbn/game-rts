# New units 12: three new units per kingdom, tier 1 to tier 2 (JS 2026-09-27)

JS (verbatim): "add 3 new units each, T1 to T2, to each wizard". Built by gameplay-coder in one pass (spec + data + code +
test), while JS playtested (headless only). Status: **playable in skirmish** behind `NewUnits12.ENABLED`
(`scripts/units/new_units_12.gd`); 3 units have real art, 9 run on marked placeholders (section 6).

## 1. Defaults taken (no questions until after the playtest)
| Question | Default |
|---|---|
| Which units | `rush-balance.md` 5 first (Scorchling, Pyre Adept, Hexweaver, Rimeling, Frost Mortar, Vinelasher), then JS's ideas from `ideas-inbox.md`: crossbowman (Fire **Cinder Arbalest**), weak fast T2 mage archer (Ice **Hoarlight Magebow**), the two "honour and backbone" swordsmen of the two main wizards (Shadow / Malrik **Hollow Oathsworn**, Nature / Ysolde **Greenheart Oathkeeper**). Two kingdoms lacked a T1: Shadow **Barrow Ghoul**, Nature **Thistle Darter** (new) |
| Not in this batch | Sparkwing (needs flyers), Bone Ballista and Bore Beetle (need `min_attack_range` / `building_damage_mult` and the Stables of `cavalry-mounts.md`). They stay designed in `rush-balance.md` 5 for the Stables step |
| Split per kingdom | 1 T1 + 2 T2 each (the bowmen do not count) |
| Where trained | The kingdom's Hall, slots 6-8 after the bowman: keys **N / M / ,** (physical, the bottom row after Z X C V B). Skirmish only: missions (`Skirmish` subclasses) and `scenes/main.tscn` never list them (`enabled_here()`, same rule as the bowmen) |
| Tier 2 gate | The tier system of `docs/plan/tiers-wave.md`: the 8 T2 `.tres` set `requires_tier = 2`, `TrainingBuilding.can_queue` refuses **"Requires Stronghold"** until `TierSystem.tier_of(team) >= 2` (the Stronghold keep upgrade). A stop-gap gate ("a completed Bazaar or a second Hall", `NewUnits12.t2_open`) was built first and stays in the file behind `OWN_T2_GATE = false` |
| One switch | `NewUnits12.ENABLED`. `false` = no Hall lists them, bots never train them, no ability node attaches |

## 2. The twelve units (`data/units/<id>.tres`, level 1, no items)
| Kingdom | Tier / key | id | Name | Role | HP | Armor | Dmg | Range | CD | Speed | Cost | Pop | Train | kill_xp |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Fire | T1 N | `scorchling` | Scorchling | fast swarm imp, death burst | 55 | 0 | 7 | 1.4 | 0.8 | 6.0 | 50 | 1 | 12 | 25 |
| Fire | T2 M | `pyre_adept` | Pyre Adept | anti-swarm caster | 80 | 0 | 10 | 8.0 | 1.6 | 4.8 | 130 | 1 | 26 | 65 |
| Fire | T2 , | `cinder_arbalest` | Cinder Arbalest | crossbow, bolt pierces a line | 95 | 5 | 20 | 10.0 | 2.2 | 4.4 | 135 | 1 | 26 | 65 |
| Shadow | T1 N | `barrow_ghoul` | Barrow Ghoul | cheap melee that feeds on kills | 75 | 0 | 8 | 1.5 | 0.9 | 5.2 | 60 | 1 | 12 | 30 |
| Shadow | T2 M | `hexweaver` | Hexweaver | anti-heavy curse caster | 85 | 0 | 8 | 8.5 | 1.4 | 4.6 | 125 | 1 | 24 | 65 |
| Shadow | T2 , | `hollow_oathsworn` | Hollow Oathsworn | Malrik's sworn blade (duelist) | 260 | 10 | 20 | 1.7 | 1.2 | 4.6 | 170 | 2 | 30 | 85 |
| Ice | T1 N | `rimeling` | Rimeling | cheap chilling raider | 65 | 10 | 7 | 1.4 | 1.0 | 5.0 | 55 | 1 | 13 | 30 |
| Ice | T2 M | `hoarlight_magebow` | Hoarlight Magebow | weak, cheap, quick mage archer | 70 | 5 | 7 | 9.5 | 1.3 | 4.8 | 95 | 1 | 14 | 45 |
| Ice | T2 , | `frost_mortar` | Frost Mortar | area siege, chills clumps | 160 | 10 | 26 | 13.0 | 3.5 | 3.4 | 190 | 2 | 42 | 95 |
| Nature | T1 N | `thistle_darter` | Thistle Darter | kiting skirmisher | 50 | 0 | 6 | 8.0 | 1.1 | 5.6 | 65 | 1 | 12 | 30 |
| Nature | T2 M | `vinelasher` | Vinelasher | whip, roots riders / divers | 170 | 5 | 13 | 3.0 | 1.3 | 4.8 | 120 | 1 | 20 | 60 |
| Nature | T2 , | `greenheart_oathkeeper` | Greenheart Oathkeeper | Ysolde's sworn shield (taunt tank) | 300 | 15 | 15 | 1.7 | 1.3 | 4.4 | 170 | 2 | 32 | 85 |
Aggro / sight / radius / bolt speed are in the `.tres`. Speed exceptions: Hoarlight Magebow 4.8 is Ice's third unit above
the 4.6 line (JS: "ez fast"). No Nature unit has idle regen (research Q3).

### 2.1 Combat value (`bowmen.md` 2.1 method: CE = EHP x DPS / cost² x 100, PE = EHP x DPS / pop² / 100)
| Unit | EHP | DPS | CE | PE | Note |
|---|---|---|---|---|---|
| Flame Guard (ref) | 130 | 12 | 19.3 | 15.6 | line infantry; Ember Archer 5.3 / 5.3 |
| Scorchling | 55 | 8.8 | 19.3 | 4.8 | + 15 burst on death |
| Barrow Ghoul | 75 | 8.9 | 18.5 | 6.7 | + 30 % heal per kill |
| Rimeling | 71.5 | 7.0 | 16.5 | 5.0 | + chill on every hit |
| Thistle Darter | 50 | 5.5 | 6.4 | 2.7 | ranged band; + kiting speed |
| Pyre Adept | 80 | 6.3 | 3.0 | 5.0 | + 30 x 3+ targets every 14 s (~6.4 area DPS) |
| Hexweaver | 85 | 5.7 | 3.1 | 4.8 | + one enemy at -20 % damage |
| Cinder Arbalest | 99.8 | 9.1 | 5.0 | 9.1 | + 4.5 DPS on the unit behind |
| Hoarlight Magebow | 73.5 | 5.4 + 2.5 needle = 7.9 | 6.4 | 5.8 | cheapest T2, 14 s train |
| Frost Mortar | 176 | 7.4 per target | 3.6 | 3.3 | full damage in 2 m: x3 on a clump |
| Vinelasher | 178.5 | 10 | 12.4 | 17.9 | + root |
| Hollow Oathsworn | 286 | 16.7 | 16.5 | 11.9 | + 100 shield and +30 % damage once per 45 s |
| Greenheart Oathkeeper | 345 | 11.5 | 13.7 | 9.9 | + taunt, damage taken x0.7 for 4 s every 14 s |
All T1 sit in their band (melee ~17-19, ranged ~6); T2 are below line infantry per crystal and pay back with the ability.

## 3. The tier-2 gate
T2 = `requires_tier = 2` (tiers-wave.md, `TierSystem.gate_reason`): the Hall card shows the button greyed with
"Requires Stronghold"; the bot skips any slot whose `can_queue` starts with "Requires" (commander `_pick_soldier`), so
rule 5 never stalls on a gated pick. Stop-gap (off): `NewUnits12.OWN_T2_GATE` / `t2_open(team)` = a completed own
Bazaar or two completed own Halls ("Requires a Bazaar or a second Hall").

## 4. Abilities (`NewUnits12`, one node `NewUnitAbility` under each unit; autocasts checked every 0.5 s, staggered)
| Unit | id | Rule | Counters |
|---|---|---|---|
| Scorchling | `flashpoint` | On death: **15** to enemy units within **2.0 m** (not buildings, not own units) | archers, towers, armor, chill |
| Pyre Adept | `flame_burst` | Cd **14 s**: the enemy spot within **8 m** with the most enemies within **2.5 m**; if >= **3**: **30** to each | cavalry / hounds diving it, range 9 |
| Cinder Arbalest | `piercing_bolt` | Passive: each bolt that hits a unit goes on to the nearest enemy unit **behind** it within **3 m** for **50 %** of attack damage | spread units, melee divers |
| Barrow Ghoul | `grave_feast` | Passive: a hit that kills a unit heals **30 %** max HP | ranged kiting, area damage |
| Hexweaver | `wither_hex` | Cd **10 s**, range **9**: the highest-cost enemy non-worker, non-wizard unit not already withered -> modifier `status_withered` `attack_damage_pct -0.20` for **6 s** (champions 3 s). (`healing_taken` x0.5 of rush-balance waits for a healing stat) | swarms, cavalry |
| Hollow Oathsworn | `unbroken_vow` | The hit that leaves it under **35 %** HP (every **45 s**): shield **100** for 6 s + `attack_damage_pct +0.30` for **6 s** | burst, chill / root, kiting |
| Rimeling | `frostbite` | Data `on_hit_status` `chill` **1.0 s** on every hit | area damage, heavies |
| Hoarlight Magebow | `frost_needle` | Cd **8 s**, range **10**: its target (else the nearest enemy unit): **20** + `chill` **1.0 s** | cavalry, anything that reaches it (70 HP) |
| Frost Mortar | `frost_shell` | Passive on each shell: **full damage** to other enemy units within **2.0 m** of the target, `chill` **1.5 s** on all of them; a building target takes **x1.5**. (No `min_attack_range` yet; bolt, no arc: art / VFX later) | cavalry dives, flyers later |
| Thistle Darter | `skitter` | Passive: each landed dart gives `move_speed +1.0` for **1.5 s** (`ability:skitter`) | cavalry, area damage |
| Vinelasher | `snare_lash` | Cd **10 s**, range **5**: the nearest enemy unit: **10** + `rooted` **1.5 s** (heroes half, `apply_status`) | ranged kiting |
| Greenheart Oathkeeper | `grove_oath` | Cd **14 s** when an enemy unit is within **5 m**: `taunted` **2.5 s** on each (source = it; wizards immune) + itself `braced` (damage taken x0.7) **4 s** | ranged, spells, being ignored by casters |
Model hook: every autocast calls `play_cast(<ability id>)` when the model has it.

## 5. Bots
`NewUnits12.bot_share`: T1 **0.06**, T2 **0.05** of soldier pop (after the 4 AIProfile slots and the bowman 0.08-0.10),
same rule-5 "slot furthest below its share". Gated units are skipped. No micro: all abilities are passive or autocast.

## 6. Art (TASK B, for medium tech-artist agents after the playtest)
Placeholders = an inherited scene of an existing kingdom unit, scaled, with `PlaceholderTint` (`scripts/units/placeholder_tint.gd`)
laying a translucent tint on every mesh. Path `art/units/<kingdom>/<id>/placeholder/<id>_placeholder.tscn`; the real model
goes to `art/units/<kingdom>/<id>/<id>.tscn`, then point `model_scene` / `model_path` of the `.tres` at it and delete the
placeholder folder. Hooks: the kit's (`set_moving`, `play_attack`, `play_hit`, `play_death`, `death_finished`), plus
`play_cast(spell_id)` for the autocasters. Icons: `art/icons/units/<id>.png` for all 12 + one ability icon each.
| Unit | Art now | Needed (brief; `art-units.md` style: chunky, silhouette = role, 1-2 glow points at 40 m, 0 lights) |
|---|---|---|
| Scorchling | placeholder (Flame Guard x0.7, orange) | `rush-balance.md` 5.4: knee-high fire imp, huge head, coal belly pulsing faster as HP falls; death pop + ember ring (`play_burst()` or `play_death`) |
| Pyre Adept | **real** (`art/units/fire/pyre_adept/`) | icon only; `play_cast(&"flame_burst")` bowl flare exists |
| Cinder Arbalest | placeholder (Ember Archer x1.08, soot) | Fire arbalester in a leather-and-bronze coat, a **heavy crossbow with a cranequin** held at the hip, powder-horn at the belt; bolt tip glows ember; reload crank on `play_attack` |
| Barrow Ghoul | placeholder (Shade x0.85, pale green) | hunched grave-eater, long arms, bone-white skin with violet veins, torn shroud; feeding lean on a kill (`play_cast(&"grave_feast")`); eyes glow |
| Hexweaver | **real** (`art/units/shadow/hexweaver/`) | icon only |
| Hollow Oathsworn | placeholder (Shade x1.2, crimson) | Malrik's sworn blade: 2.0 m knight in black plate with a **hollow-bishop mitre crest**, a long single-edged sword held two-handed, a torn red sash; `play_cast(&"unbroken_vow")` = the sword flares violet-red, a sigil ring at the feet. Duel cutscene partner of the Oathkeeper (ideas inbox, `episode3-4-opening.md`) |
| Rimeling | placeholder (Rimeshield x0.7, pale ice) | `rush-balance.md` 5.4: squat frost goblin in fur, two icicle shivs, frost-breath puffs |
| Hoarlight Magebow | placeholder (Shardcaster x0.95, lilac) | slim Ice mage-archer with a **bow of light** (a glass-rune stave that draws a glowing string), short cape; needle = a white-violet shard (VFX); glow on the string |
| Frost Mortar | placeholder (Rime Hauler x1.25, deep blue) | `rush-balance.md` 5.4: ice-bound mortar tube on a sled, 2 Hauler crew, frost vapour after each shot; lobbed shell VFX with an arc + splash ring |
| Thistle Darter | placeholder (Burr Slinger x0.9, yellow-green) | small quick sprite-like hunter with a **blowpipe** and a thistle-down cloak; skitter = a hop with seed fluff trail |
| Vinelasher | **real** (`art/units/nature/vinelasher/`) | icon only |
| Greenheart Oathkeeper | placeholder (Thornling x1.35, gold) | Ysolde's sworn shield: 2.0 m bark-armoured warden, **broad leaf-shaped greatshield** and a heartwood sword, a green heart-knot glowing on the chest; `play_cast(&"grove_oath")` = shield raised, a ring of leaves; duel partner of the Oathsworn |

## 7. Files
New: `scripts/units/new_units_12.gd`, `scripts/units/placeholder_tint.gd`, 12 `data/units/<id>.tres`, 9 placeholder scenes,
`tests/test_new_units_12.gd`. Hooks (one line or a few each, tagged `new-units-12.md`): `scripts/units/unit.gd` `_ready`,
`scripts/buildings/training_building.gd` (`trainable_types`, `can_queue`), `scripts/ai/commander.gd` `_pick_soldier`,
`scripts/ui/selection_manager.gd` (`SLOT_KEYS` / `SLOT_LETTERS` 8 slots), `scripts/ui/command_card.gd` (8 training
buttons + rally, tooltip fallback `NewUnits12.description`). Tests updated for the 8-slot Hall: `test_bowmen.gd`, `test_2_u1.gd`.

## 8. Open points
- Keys N M , : AZERTY users see the physical positions (N , ;). `train_key` prints QWERTY letters (as for Z X C V B).
- Pyre Adept `splash_ratio`, Frostbow-style `bonus_vs_mounted`, Frost Mortar `min_attack_range`, Hexweaver `healing_taken`
  wait for stats that do not exist yet.
- "+" upgrades (tiers-wave.md) should cover these 12 too: the tier agent's table can add one row each.
- Balance: first knobs if a unit dominates the Balance Lab: Scorchling burst 15 -> 12, Oathsworn Vow cd 45 -> 60,
  Oathkeeper taunt 2.5 -> 1.5 s, Magebow train 14 -> 18 s.

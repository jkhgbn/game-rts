# Balance pass 1: the 1v1 vs bot (Fire vs Shadow)

Task 5.D2. Applied in step 6 ("gameplay applies balance-1"; proposed ids 6.B1-6.B4 below). Written 2026-09-25
from the current data (`data/units`, `data/buildings`, `data/spells`, `data/items`, `skirmish.gd`, `unit.gd`,
`essence_bank.gd`) and the step 3-5 test notes: bot vs bot ended at **6:21 and 7:18, Fire won both**; Malrik
wears the crown at **~4:18**; **every crystal node is empty by 6-7 min**.
Goal: a normal 1v1 lasts **15-20 min**, wizards reach **level 5-6**, each side buys **1 top item + 1-2 mids**.
This file overrides the numbers in `economy.md`, `skirmish-1v1.md`, `units-fire-shadow.md`, `buildings.md`,
`spells.md`, `levels.md`, `items.md` and `ai.md` where they differ; those specs keep everything else.

## 1. What the numbers say (diagnosis)
| # | Problem | Evidence (current data) |
|---|---|---|
| P1 | **Economy runs dry at 6-7 min** | Per side: 250 + 3 nodes x 900 = **2 950 crystals for the whole match**. 6 workers mine 420 / min (10 crystals per ~8.5 s trip each), so the 1 800 home crystals last ~4.5 min; the natural (900) lasts ~4 min with 3 workers. After 7 min nobody can rebuild, so the first won fight ends the game |
| P2 | **Buildings melt** | 10 soldiers (~100 DPS) kill the 1 500 HP keep in 15 s and a 900 HP hall in 9 s. The defender has no time to react, even with towers (a tower is ~10 DPS) |
| P3 | **Fire soldiers are simply better per crystal** | Fight value = HP x DPS / cost² (Lanchester): Flame Guard 130 x 12 / 90² = **0.193**; Shade 90 x 10 / 80² = **0.141** (-27 %). Shadow Knight 420 x 18.6 / 300² = **0.087** and pop 3. Archer 0.053 vs Nightbolt 0.050 are fine. The bot's default mix is 40 % Shades + 15 % Knights, so Shadow loses every even trade |
| P4 | **Crown too early** | The camp is 4 x 150 HP, 48 DPS total: 6 Shades clear it with ~1 loss. At ~4:18 Malrik gets +100 HP / +50 mana, 240 XP (a level), 240 essence, a Warden Scale and a Draught: a snowball before the player has an army |
| P5 | **Late game never happens** | Matches end at wizard level ~3: spell 3 (level 4) is never learned; essence at 7:00 is ~1 300, so no top item (1 400-1 950) is ever bought. Levels, items and veterancy were tuned for 15-25 min |
| P6 | **Late spell spike (once matches are long)** | Fireball has no cooldown: level 8 + Staff of Cinders (+60) + Duskglass = 85 x 1.75 = **149 damage every ~3 s** with 12+ mana regen: it one-shots every Fire and Shadow soldier except Knights and Riders. The +100 spell power cap allows it |
| P7 | **Tower asymmetry for no reason** | Ember Spire 14 dmg vs Night Spire 16 (+14 %) with identical cost / HP; Shadow does not need it once P3 is fixed |
| P8 | **Essence would overflow** in a 20-min match with a bigger economy | Kill essence = 100 % of the victim's XP; with ~2x the units killed, a 20-min match gives ~5 000+ essence (3 top items): wizards would outgrow armies |

## 2. Changes (apply mechanically; `file / field: old -> new`)
### 2a. Economy and map (systems-coder, 6.B2)
| File / field | Old -> new | Why |
|---|---|---|
| `scripts/world/skirmish.gd` / `NODE_CRYSTALS` (one value for all nodes) | `900` -> replaced by a per-node table `NODE_AMOUNTS := {&"a": 2000, &"b": 2000, &"mid": 2500, &"rich": 2500}` (key = the suffix after `node_fire_` / `node_shadow_`) | P1 |
| `scripts/world/skirmish.gd` / `FIRE_NODES` | add `&"node_fire_rich": Vector3(-40.0, 0.0, -40.0)` (mirror `node_shadow_rich` at `(40, 40)`) | P1: a 4th node per side, **contested** (83 m from both keeps) |
| `scripts/world/skirmish.gd` / generator clearings | add a clearing r **7** at `(-40, -40)` (mirrored) | Room for the rich node + a hall |
| New constant `RICH_HALL_SPOT` in `skirmish.gd` | `Vector3(-33.0, 0.0, -33.0)` (Shadow `(33, 33)`), kept free of trees/rocks like `NATURAL_HALL_SPOT` | Where a forward hall fits (9.9 m from the node) |
| `scripts/economy/worker.gd` / `MINE_TIME`, `CARRY_AMOUNT` | unchanged (4.0 s, 10) | Income rate is fine; the **total** was the problem |
| `scripts/economy/economy.gd` / `START_CRYSTALS` | unchanged 250 | Opening (hall at 0:00) stays |

New totals per side: 250 + 2 000 + 2 000 + 2 500 = **6 750** own + a share of 2 x 2 500 contested = **~9 000**.
Drain check (3 workers per node max, 70 / min each): home nodes (6 workers, 420 / min) last ~9.5 min -> empty
~10:30; natural (taken ~5:30, 210 / min) empty ~17:30; rich (taken ~9:00) empty ~21:00. Income peaks at
~840 / min around 9:00-10:30 (12 workers), then falls: **the map itself ends the match around 18-22 min**.

### 2b. Buildings (systems-coder, 6.B2)
| File / field | Old -> new | Why |
|---|---|---|
| `data/buildings/fire_keep.tres`, `shadow_keep.tres` / `max_hp` | 1500 -> **2500** | P2: 25 s under 10 soldiers |
| same / `attack_damage`, `attack_range`, `attack_cooldown` | 0 / 0 / (1.5) -> **12 / 10.0 / 1.5** (keep shoots like a spire, kingdom bolt, prefers units). Code: the keep reuses `tower.gd`'s targeting (S task) | P2, early raids on workers are answered |
| `data/buildings/fire_barracks.tres`, `shadow_barracks.tres` / `max_hp` | 900 -> **1300** | P2 |
| `data/buildings/fire_hearth.tres`, `shadow_hovel.tres` / `max_hp` | 400 -> **500** | P2 |
| `data/buildings/fire_tower.tres` / `attack_damage` | 14 -> **15** | P7 |
| `data/buildings/shadow_tower.tres` / `attack_damage` | 16 -> **15** | P7 |
| `fire_tower.tres`, `shadow_tower.tres` / `max_hp` | 600 -> **750** | Towers hold a lane ~12 s against 10 soldiers instead of 6 s |
| `fire_tower.tres`, `shadow_tower.tres` / `max_count` | 0 -> **4** | Longer games must not end in tower carpets |
| Cost, build time, pop of every building | unchanged | Opening timings and tests stay |

### 2c. Units (gameplay-coder, 6.B1)
| File / field | Old -> new | Why |
|---|---|---|
| `data/units/shade.tres` / `max_hp` | 90 -> **110** | P3 |
| `data/units/shade.tres` / `attack_damage` | 10 -> **11** | P3: value 110 x 11 / 80² = 0.189 (Guard 0.193) |
| `data/units/shadow_knight.tres` / `cost` | 300 -> **260** | P3 |
| `data/units/shadow_knight.tres` / `max_hp` | 420 -> **480** | P3: value 480 x 18.6 / 260² = 0.132 (Rider 0.136) |
| `data/units/shadow_knight.tres` / `kill_xp` | 150 -> **130** | Kill XP = cost / 2 rule of `levels.md` |
| `data/units/grave_hound.tres` / `max_hp` | 60 -> **70** | Survives one rank-1 Fireball (60) like every other soldier |
| `data/units/ruin_warden.tres` / `max_hp` | 150 -> **300** | P4: camp 1 200 HP |
| `data/units/ruin_warden.tres` / `attack_damage` | 12 -> **16** | P4: camp 64 DPS; 6 soldiers lose ~3, a 10-unit army + wizard wins |
| `data/units/ruin_warden.tres` / `kill_xp` | 60 -> **90** | Harder camp pays more (camp = 360 XP) |
| Fire units, Nightbolt, workers | unchanged | Already on target |
Rank-1 Fireball (60) one-shots no soldier; rank 2 (72) kills a Grave Hound (70), deliberate (fragile raider);
rank 3 (85) still does not one-shot a Shade (110) or a Flame Guard (130).

### 2d. Spells and items (gameplay-coder 6.B1, items-coder 6.B3)
| File / field | Old -> new | Why |
|---|---|---|
| `data/spells/fireball.tres` / `cooldown`, `cooldown_by_rank` | `0.0`, `[0, 0, 0]` -> **`3.0`, `[3.0, 3.0, 2.5]`** | P6: burst stays, spam goes; CDR now helps Vessa too (40 % CDR -> 1.5 s) |
| Stat cap `spell_power` (the items stat-cap table, `items.md`; wherever 4.I1 / 4.G1 put it) | 100 -> **60** | P6 |
| `data/items/staff_of_cinders.tres` / `stats.spell_power` | 60 -> **45** | P6: max Fireball = 85 x 1.6 = 136 every 2.5 s; a Flame Guard (130) dies only at full spell power, a Knight (480) takes four |
| `scripts/items/essence_bank.gd` / kill essence | 100 % of the victim's XP value -> **60 %**, rounded to the nearest integer (new const `KILL_ESSENCE_RATIO := 0.6`) | P8 |
| `scripts/items/essence_bank.gd` / `START_ESSENCE`, `TRICKLE_PER_SECOND` | unchanged 150 / 1.0 | |
| Item costs | unchanged | Prices were built for a 20-min income; now the match actually lasts 20 min |
Essence check at 18:00 (normal, active player): 150 + trickle 1 080 + kills 0.6 x ~2 500 = 1 500 + camp 0.6 x 360 = 216
+ buildings ~240 + chests ~300 = **~3 500** = one top (~1 900) + one mid (~650) + components. At 10:00: ~1 700 = two mids.

### 2e. Crown and veterancy (systems 6.B2, gameplay 6.B1)
| File / field | Old -> new | Why |
|---|---|---|
| `scripts/campaign/ember_crown.gd` / new `SEAL_TIME := 360.0` | Pickup refused before **6:00** of match time (pedestal glows red; a wizard in range sees `The Ember Crown is sealed until 6:00`). At 5:30 `show_message("The Ember Crown stirs...")`, at 6:00 `The Ember Crown awakens` | P4: floor on crown timing, whatever the camp does |
| Crown target time | ~4:18 -> **7:00-9:00** | Tougher camp (2c) + seal |
| `scripts/units/unit.gd` / `VETERANCY_XP` | `[0, 100, 300, 700]` -> **`[0, 120, 350, 800]`** | Longer matches = more kills; Champions stay rare (~17 kills' worth) |
| `scripts/units/wizard.gd` / level curve, growth | unchanged | Built for 15-25 min; now reachable (L5 ~12:00, L6 ~16:00) |

### 2f. The bot (ai-coder, 6.B4; `AIProfile` knobs wherever 2.A1 stored them)
| Knob / rule (`ai.md`) | Old -> new | Why |
|---|---|---|
| `worker_target_expanded` easy / normal / hard | 6 / 9 / 9 -> **6 / 9 / 9** after X1, then **- / 12 / 12** after X2 | Uses the rich node |
| New slot **X2** (forward hall at the rich node) | Shadow `(33, 33)` = `RICH_HALL_SPOT` mirror | |
| Rule 3 expansion trigger (X1) | home a + b < 700 or 6:00 -> **home a + b < 2 000 or 5:00** | Same moment in the match with bigger nodes |
| Rule 3 second expansion (X2, new) | - -> **home a + b < 800 or 9:00**, crystals >= 150, no attack out; normal and hard only | |
| Rule 7 crown-camp attack | `own_strength >= 350` -> **`own_strength >= 900` and match time >= 5:30** | P4 |
| Rule 8 crown pickup | as written, plus "crown not sealed" | |
| Strength of a Ruin Warden | 100 -> **200** | Camp HP doubled |
| Strength of a tower | 120 -> **150** | 750 HP now |

## 3. Expected match flow (normal bot, active player, both sides roughly even)
| Time | Economy (each side) | Army / wizards | Key events |
|---|---|---|---|
| 0:00-1:00 | Hall at 0:00, workers to 6 by ~1:00; income 210 -> 420 / min | - | Wizards may poke workers (keep now shoots back) |
| 1:00-3:00 | 420 / min; Hearth 1 ~2:30 | 3-6 soldiers; first scouting fights on the lane | Lost Caches appear at 2:00 |
| 3:00-5:00 | Natural hall placed ~5:00; Spire 1 | 8-12 pop of soldiers; wizard **L2** (~3:30); first skirmish at the natural | Crown stirs 5:30 |
| 5:00-7:00 | 9 workers, 630 / min; Hearth 2 (cap 40) | 15-20 soldier pop; first Veterans; **L3** ~6:30 | Crown unseals 6:00; camp fight ~6:30-8:00 |
| 7:00-10:00 | Rich node contested ~9:00 (12 workers, ~840 / min peak); home nodes near empty | First big fight (~30 pop each); first mid item (~7:30); **L4** ~9:00 (Kindle / Shroud) | Crown worn (**7:00-9:00**); first base raid on a forward hall |
| 10:00-13:00 | Home nodes empty ~10:30; income ~420-630 | Maxed 40 pop armies; Elites; second mid / first top parts; **L5** ~12:00 | Crown changes hands on a wizard kill; towers + keep fire decide defences |
| 13:00-16:00 | Natural runs low; rich node is the prize | Knights / Riders in numbers; first **top item** ~14:00-16:00; **L6** ~16:00 | Decisive army wipe usually here |
| 16:00-20:00 | Natural empty ~17:30; rich ~21:00; exchange surplus crystals to essence | Last armies; Champions rare | The side that holds the rich node pushes and razes the base: **match ends 15-20 min** |

## 4. Risks and what the lead checks
- Smoke map (`scenes/main.tscn`, old mission-1 layout) uses Shades, Knights and wardens: the Shadow block gets ~15 % tougher.
  Run the smoke test 5 times; if `victory=true` drops below 5 / 5, the lead removes 2 pre-placed Shades from the smoke scene.
- Tests with old numbers must be updated by their owners in the same step: 2.S1 (hall 900 HP), 3.G2 (veterancy 100 / 300 / 700),
  3.G3 / 2.G2 (Fireball cooldown 0), 4.I1 (kill essence 100 %), 2.S3 (node 900).
- Perf: 12 workers per side (was 9) + 40 pop armies = ~110 units plus wardens: inside the 200-unit perf budget.
- Knobs if playtest says matches are still short: keep HP 2500 -> 3000, nodes +20 %. Too long (> 22 min): rich nodes 2500 -> 1800.
  Crown still early: `SEAL_TIME` 360 -> 420. Shadow now too strong: Shade HP 110 -> 100.

## Done when (proposed step 6 ids; the lead adds them to `waves.md`)
- [ ] 6.B1 (gameplay): the unit table 2c, Fireball cooldown `[3.0, 3.0, 2.5]` and `VETERANCY_XP [0, 120, 350, 800]` are in the data; test: Shade 110 HP / 11 dmg, Knight 260 / 480, warden 300 / 16 / 90 XP; Fireball refuses `On cooldown` 1 s after a cast; a soldier reaches Veteran at 120 XP, not 100.
- [ ] 6.B2 (systems): 8 nodes (2 000 / 2 000 / 2 500 / 2 500 per side, rich at `(-40, -40)` / `(40, 40)` with clearings); keep 2 500 HP and shooting (12 dmg, range 10, cooldown 1.5); halls 1 300, hearths 500, spires 750 HP / 15 dmg / max 4; crown pickup refused before 6:00 with the messages at 5:30 / 6:00.
- [ ] 6.B3 (items): kill essence = 60 % of the victim's XP (a Shade kill gives 24); `spell_power` cap 60; Staff of Cinders +45.
- [ ] 6.B4 (ai): X2 slot and second expansion; camp attack at strength >= 900 and >= 5:30; warden 200 / tower 150 strength.
- [ ] Lead: bot vs bot at normal, 3 runs: each lasts **14:00-22:00**; the crown is first worn between **6:00 and 9:30**; each wizard reaches level **5+**; each side buys at least one top item or is within 500 essence of one; neither kingdom wins all 3.

# Kingdom: Ice (Torvald). Step 7

Written 2026-09-25 (task 5.D3). Source of truth for Step 7 tasks 7.L1-7.V5 (list at the end). Same units and
formats as `units-fire-shadow.md`, `buildings.md`, `spells.md`, `levels.md`, `items.md`, `art-keep.md`, `art-units.md`,
`ai.md`. Metres, seconds. Everything here is original. Nature (`kingdom-nature.md`) reuses the shared mechanics
defined in section 2, so section 2 is built once, in Step 7.

## 1. Identity and play style
| | Ice (Torvald) |
|---|---|
| One line | **The fortress that walks forward slowly.** Tough, armored, slow units; everything chills or freezes; the base is the hardest to crack. |
| Kingdom passive "Permafrost" | Ice soldiers have base `armor` (per unit below). Ice buildings have **+20 % HP** and **+20 % build time** vs Fire. The Rime Spire chills on hit. Ice can build **Ice Walls**. |
| How it wins | Holds the crown area and its expansion with spires and walls, trades efficiently at pop cap (best HP per pop), freezes clumps with Flash Freeze and pushes with a shielded ball. |
| vs Fire | Fire hits hard and fast; Ice armor + Rime Aegis blunt the burst, chill kills the Blaze Rider's hit-and-run. Fire must win **before 8:00** or raid the slow Ice army's far side. |
| vs Shadow | Armor reduces spell damage too, so Shadow Lance and Soul Siphon hit less and Malrik heals less. But Grave Hounds out-run everything Ice has: worker raids hurt. |
| **Weakness** | **Slow.** No Ice unit is faster than 4.6 m/s (worker) and soldiers walk 3.4-4.4: it cannot chase, cannot catch raiders, loses the race to the crown and to expansions. Units cost more per crystal and train 10-20 % slower: a fast early attack (3:00-5:00) catches it with few units. |

## 2. Shared mechanics (built in Step 7, reused by Nature)
### 2.1 New statuses (extends the `spells.md` status table; `apply_status(id, duration)`, refresh, never stack)
| id | Attack cooldown x | Move speed | Can move / attack / cast | Wizards | Buildings | Look (7.V5) |
|---|---|---|---|---|---|---|
| `chill` | 1.25 | -1.5 m/s (floor 1.0 m/s total) | yes / yes / yes | full duration | immune | body modulate `(0.70, 0.85, 1.00)`, 12 frost motes |
| `frozen` | - | 0 | **no / no / no** (orders are kept and resume) | **half duration** | immune | ice block `BoxMesh` (radius x 2.2, height x 1.1, radius x 2.2) `(0.75, 0.92, 1.00, 0.45)`, emission 0.5 |
| `rooted` (Nature) | 1.0 | 0 | no / yes / yes (Ember Step, Blink still work) | half duration | immune | 3 thorn cones r 0.08 h 0.5 at the feet `(0.30, 0.45, 0.15)` |
- `chill` stacks with `haste` multiplicatively (0.70 x 1.25 = 0.875; +1.5 - 1.5 = 0).
- After `frozen` ends the unit is **immune to `frozen` for 2 s** (no perma-lock). Damage taken is unchanged while frozen.
- `Unit.can_move() -> bool`, `Unit.can_act() -> bool` (public, for the AI and UI).

### 2.2 New `UnitType` fields (the lead adds them to the contract, 7.L1)
| Field | Type, default | Used by |
|---|---|---|
| `armor` | float, 0 | Ice soldiers. Same formula as `items.md` (`100 / (100 + armor)`), feeds `get_stat("armor")` as base |
| `idle_regen_pct` | float, 0 | Nature: % of max HP per s after **4 s** without taking damage |
| `on_hit_status`, `on_hit_duration` | StringName `&""`, float 0 | Shardcaster, Rime Colossus (`chill`) |
| `support_kind` | StringName `&""` | `&"shield"` (Rime Seer) or `&"heal"` (Bloomtender) |
| `support_amount`, `support_interval`, `support_range`, `support_duration` | float | see 2.3 |
| `lifetime` | float, 0 (= permanent) | Nature Saplings (summons) |
`faction` gains `&"ice"` and `&"nature"`. `kill_xp` = cost / 2 rounded to 5 (workers 15), as `levels.md`.

### 2.3 Support autocast (one script for both kingdoms)
Every `support_interval` s, while alive and `can_act()`: pick the friendly **soldier or wizard** (never workers,
buildings or itself) within `support_range` with the **lowest HP ratio below 0.80**; `shield`: skip units that already
carry this unit type's shield. Apply: `shield` -> `add_shield(support_amount, support_duration)`; `heal` -> `heal(support_amount)`.
Independent of the attack timer (the unit keeps shooting). Nothing found: retry next interval. Visual: a 0.25 s beam
(glow colour of the kingdom) from the caster's hands to the target. Healing and shields give no XP.

### 2.4 New `BuildingType` fields
`on_hit_status`, `on_hit_duration` (towers), `idle_regen_pct` (Nature, **10 s** without damage), `aura_radius`,
`aura_stats: Dictionary` (through `apply_aura`, Nature tower). Ice Wall uses the existing fields only.

## 3. Units (UnitType; trained at the Frost Hall, worker at the keep)
| id | Display name | Role | max_hp | armor | dmg | range | cooldown | speed | aggro | radius | height | Colour (secondary cloth) | Cost | Pop | Train (s) | Key | kill_xp | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `rime_hauler` | Rime Hauler | Worker | 60 | 0 | 4 | 1.4 | 1.2 | 4.6 | 0 | 0.4 | 1.4 | `(0.70, 0.78, 0.85)` | 50 | 1 | 12 | Z (keep) | 15 | `is_worker` |
| `rimeshield` | Rimeshield | Melee line, armored | 150 | 15 | 11 | 1.6 | 1.1 | 4.2 | 8 | 0.5 | 1.7 | `(0.40, 0.62, 0.85)` | 100 | 1 | 22 | Z | 50 | - |
| `shardcaster` | Shardcaster | Ranged, chills | 80 | 5 | 9 | 9.0 | 1.4 | 4.4 | 10 | 0.45 | 1.6 | `(0.60, 0.85, 1.00)`, bolt `(0.75, 0.92, 1.00)` | 110 | 1 | 22 | X | 55 | on hit `chill` 1.5 s |
| `rime_seer` | Rime Seer | Support, shields | 70 | 5 | 6 | 8.0 | 1.5 | 4.2 | 10 | 0.45 | 1.6 | `(0.85, 0.92, 1.00)`, bolt `(0.60, 0.90, 1.00)` | 120 | 1 | 24 | C | 60 | `shield` 60 for 6 s, every 12 s, range 8 |
| `rime_colossus` | Rime Colossus | Heavy elite | 520 | 20 | 28 | 1.9 | 1.8 | 3.4 | 10 | 0.8 | 2.6 | `(0.30, 0.45, 0.65)` | 330 | 3 | 52 | V | 165 | on hit `chill` 2 s |
Bot rule: Rime Colossus only when crystals >= 330 and soldier pop >= 8 (as the Shadow Knight).
Caster (step 21): **Rimecarver** (`rimecarver`), trained at the keep on **B** from the Stronghold (tier 2), 150 / pop 2 /
30 s, armour 5: Rime Bulwark (Z), Scrying Rune (V), Stillness. Numbers and spells: `caster-units.md` 4-5.

## 4. The wizard: Torvald, Ice Wizard (pop 0)
| id | max_hp | armor | dmg | range | cooldown | speed | aggro | radius | height | Body / hat / orb | Mana | Regen /s |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `torvald` | 440 | 10 | 15 | 6.5 | 1.5 | 4.2 | 9 | 0.55 | 2.1 | `(0.35, 0.60, 0.85)` / `(0.15, 0.35, 0.60)` / `(0.75, 0.92, 1.00)` | 100 | 4 |
Growth (`levels.md` format): **+30 HP / +2 dmg / +10 mana / +0.25 regen** per level -> L6 590 / 25 / 150 / 5.25, L8 650 / 29 / 170 / 5.75.
Armor 10 is his base `armor` stat (items add on top; the item cap counts items only). XP value as any wizard.

### 4.1 Spells, rank 1 (`spells.md` format; slots r2c1-r2c3, keys F / Q / E)
| id | Name | Key | Target | Mana | Cooldown | Range | Radius | Effect |
|---|---|---|---|---|---|---|---|---|
| `rime_bolt` | Rime Bolt | F | unit | 35 | 6 | 13 | - | Ice shard projectile (26 m/s, r 0.16, `(0.75, 0.92, 1.00)`): 45 damage + `chill` 3 s |
| `flash_freeze` | Flash Freeze | Q | area | 50 | 20 | 12 | 3.0 | Enemy units inside: 20 damage + `frozen` 1.5 s, then `chill` 3 s |
| `rime_aegis` | Rime Aegis | E | self | 60 | 40 | - | 8 | Torvald and friendly non-worker units within 8 m: shield 80 for 8 s (`add_shield`) |
Tooltips: `Rime Bolt  [F]\n35 mana · 45 damage · range 13\nChills the target: slower attacks and movement.` ·
`Flash Freeze  [Q]\n50 mana · 20 s cooldown · radius 3\nFreezes every enemy in the circle.` ·
`Rime Aegis  [E]\n60 mana · 40 s cooldown · radius 8\nShields Torvald and nearby soldiers.` Icons `RB`, `FF`, `RA`.

### 4.2 Ranks (`levels.md` format; same level requirements: F 1/3/5, Q 2/4/6, E 4/7)
| Spell | Rank 1 | Rank 2 | Rank 3 |
|---|---|---|---|
| Rime Bolt (F), 35 mana, range 13 | 45 damage, chill 3 s, cooldown 6 | 58 damage, chill 4 s, cooldown 5.5 | 72 damage, chill 5 s, cooldown 5 |
| Flash Freeze (Q), 50 mana, range 12 | radius 3.0, 20 damage, frozen 1.5 s, cooldown 20 | radius 3.25, 30 damage, frozen 2.0 s, cooldown 18 | radius 3.5, 40 damage, frozen 2.5 s, cooldown 16 |
| Rime Aegis (E), 60 mana | shield 80 for 8 s, radius 8, cooldown 40 | shield 120 for 8 s, radius 10, cooldown 35 | - |

### 4.3 AI cast rules (bot Torvald; checked every 0.5 s, first rule that applies, one cast per check, skip unlearned)
1. **Rime Aegis**: ready, mana >= 60, and (HP < 50 %, or >= 4 own soldiers within 8 m and >= 3 enemy units within 10 m).
2. **Flash Freeze**: ready, mana >= 50, and an enemy unit within 12 m has >= 3 enemy units within 3 m of it (itself
   included); centre = the one with the most (a group containing the enemy wizard wins ties).
3. **Rime Bolt**: ready, mana >= 35: the enemy wizard in range if not chilled; else the highest-cost enemy unit in
   range not chilled; else the nearest.
`ai.md` rule 8 retreat (HP < 35 %): Rime Aegis first if ready.

## 5. Buildings (BuildingType; `buildings.md` rules unless listed)
| id | Display name | Cost | Build time | max_hp | Footprint | Height | Gives | Trains / attack | Build key |
|---|---|---|---|---|---|---|---|---|---|
| `ice_keep` | Rime Keep | - | - | 1800 | 3 x 3 | 6 | +20 pop, drop-off, shop | Rime Hauler Z (+ Rimecarver B from the Stronghold, `caster-units.md`) | - |
| `ice_barracks` | Frost Hall | 150 | 54 | 1080 | 3 x 3 | 4 | drop-off, shop | Rimeshield Z, Shardcaster X, Rime Seer C, Rime Colossus V | X |
| `ice_lodge` | Snow Lodge | 80 | 30 | 480 | 2 x 2 | 3 | +10 pop, max 2 (cap 40) | - | Z |
| `ice_tower` | Rime Spire | 130 | 42 | 720 | 1 x 1 | 5 | sight 16 | dmg 12, range 11, cooldown 1.5, aggro 11, on hit `chill` 2 s, bolt `(0.75, 0.92, 1.00)` | C |
| `ice_wall` | Ice Wall | 20 | 8 | 500 | 1 x 1 | 2.5 | blocks paths (navmesh rebake as any building), sight 4, `max_count` 16 | - | **V** (build menu r2c1) |
- Ice Wall: counts as a building for the "no building left = defeat" rule? **No**: walls are ignored by the
  defeat check (`skirmish-1v1.md`); systems adds `BuildingType.counts_for_defeat` (default true, false on walls).
- Building XP (`levels.md`): Frost Hall 100, Snow Lodge 40, Rime Spire 80, Rime Keep 200, **Ice Wall 10**; essence the same.
- Build menu for Ice workers: Snow Lodge Z, Frost Hall X, Rime Spire C, Back r1c4, **Ice Wall V at r2c1**.
  Tooltip `Ice Wall  [V]\nCost 20 crystals · 8 s · 500 HP\nBlocks the way. Max 16.`

## 6. Items (add to `items.md`; sold at every base shop, any wizard may buy)
| id | Name | Tier | Parts + recipe = total | Stats | Passive / active |
|---|---|---|---|---|---|
| `frostglass_shard` | Frostglass Shard | Component | 200 | `armor` +10, `max_mana` +20 | - |
| `rimebound_bracers` | Rimebound Bracers | Mid | Frostglass Shard + Ironbark Plate + 250 = **630** | `armor` +25, `max_hp` +60 | **Numbing Touch**: auto-attacks apply `chill` 1.5 s |
| `glacier_heart` | Glacier Heart | Mid | Frostglass Shard + Mana Thread + 250 = **630** | `spell_power` +15, `max_mana` +50, `armor` +10 | **Frostbite**: enemies damaged by the wizard's spells get `chill` 1.5 s |
| `winterwall_aegis` | Winterwall Aegis | Top | Rimebound Bracers + Warlord's Horn + 500 = **1 860** | `armor` +40, `max_hp` +200 | **Frost Ward** (aura): soldiers within 8 m `armor` +10; **Glacier Shell** (active, self): the wizard is `frozen` 2.5 s and takes **no damage**; cooldown 75, 0 mana |
Bot lists (4.A1 format) for Torvald: **Normal** Frostglass Shard, Ironbark Plate, **Rimebound Bracers**, Ember Draught,
Frostglass Shard, Mana Thread, **Glacier Heart**, Bone Charm, Ironbark Plate, **Warlord's Horn**, **Winterwall Aegis**.
Easy = the first 5 entries. Hard = Normal + Ember Draught after Glacier Heart. Glacier Shell: HP < 25 % and an enemy within 6 m.

## 7. Bot differences (extends `ai.md`; same rules 1-8 unless listed)
| Rule | Ice change |
|---|---|
| Profile | `data/ai/ice_<difficulty>.tres`: `attack_ratio` +0.2 (normal 1.5), `min_attack_pop` +2 (normal 8), defend radius **32 m** (was 28) |
| Build | Frost Hall at 0:00 as H1; **Rime Spire S1 at 3:30** (not 5:00); S2 at 7:00; expansion X1 at **7:00** (not 6:00) or home nodes < 700 |
| Walls (hard only) | After S1: 2 Ice Walls at S1 offset `(-2, 0)` and `(+2, 0)`, only if `BuildGrid.check` is ok **and** the keep -> rally navmesh path stays < 1.5 x the straight line; else skip |
| Mix (default / vs ranged / vs melee) | Rimeshield 40 / 50 / 30 %, Shardcaster 30 / 20 / 40 %, Rime Seer 10 / 10 / 15 %, Rime Colossus 20 / 20 / 15 % |
| Retreat | Group retreats at **30 %** HP (was 40 %) |
| Scout | Rime Hauler before 1:30, then the cheapest soldier (no fast unit) |
| Strength | Unchanged formula (`cost x (0.8 + 0.2 x level)`) |

## 8. Art direction (brief; `art-keep.md` section 0 and `art-units.md` rules apply)
Palette (building, `art-keep.md` 0.2 Ice row): team `(0.45, 0.75, 0.95)`, glow `(0.75, 0.92, 1.00)`, stone `(0.62, 0.70, 0.78)`,
dark stone `(0.30, 0.38, 0.48)`, trim silver-blue `(0.70, 0.78, 0.88)`, cloth shadow `(0.15, 0.35, 0.60)`. Units (1.3 split):
team cloth `(0.45, 0.75, 0.95)`, team dark `(0.15, 0.35, 0.60)`, skin pale `(0.86, 0.82, 0.84)`, metal silver-blue
`(0.70, 0.78, 0.88)`, glow `(0.75, 0.92, 1.00)`, fur / dark base `(0.16, 0.20, 0.28)`. Ground decal: frost `(0.85, 0.92, 1.00, 0.45)`.

### 8.1 Rime Keep ("the Glacier Throne"), 3 x 3, max height 16 m
Read at 40 m: a wide stepped fortress of pale ice-stone with three terraces, a **huge three-pointed frost crystal** rising
from the centre, a ring of 6 ice shards orbiting it, frost mist at its feet. Mood: glacier, patience, cold light inside.
| Part | Shape, size | Position | Colour / emission |
|---|---|---|---|
| Plinth | Box 6.4 x 0.8 x 6.4 | (0, 0.4, 0) | dark stone |
| Terraces (3) | Boxes 5.6 / 4.4 / 3.2 wide, 1.4 high, stacked | y 1.5 / 2.9 / 4.3 | stone, tops snow `(0.92, 0.95, 1.00)` |
| Gate | Arch: box 1.8 x 2.2 x 0.8 + half cylinder r 0.9 | local -Z face | dark stone, frame silver |
| Crown crystal | 3 hexagonal prisms (`CylinderMesh` 6 seg, top r 0) r 0.9 h 9 / r 0.6 h 6 / r 0.6 h 6, the two small tilted 20° outward | centre, base y 5.0 | team, `rune_glow` core cylinder r 0.3 energy 3.0 |
| Shard halo | `MultiMesh` 6 prisms r 0.25 h 1.2 on a ring r 2.4 | y 9.5, turns 8°/s | glow 2.5 |
| Banners (2) | `banner.gdshader` 0.9 x 2.2 | gate sides | team |
| Icicle fringe | `MultiMesh` 24 cones r 0.12 h 0.6 hanging under each terrace lip | lips | stone lightened x1.2 |
| Light | 1 OmniLight3D `(0.70, 0.88, 1.00)` energy 1.5 range 10 | y 8 | shadows off |
| Particles | snow motes 40 falling from y 12, mist 24 at the plinth (MIX) | - | - |
Glowing points at 40 m: crystal core, halo, gate slit (3). Hooks and states: `art-keep.md` section 8 unchanged
(damage = cracks in `crack_color (0.80, 0.95, 1.00)`; destroyed = the crown crystal topples and shatters into 12 shards).
Frost Hall: a long hall 6 x 4 x 6 with a sloped ice roof and one 4 m crystal on the ridge. Snow Lodge: a domed hut
(half sphere r 1.8) with a chimney crystal. Rime Spire: a 5 m hexagonal ice needle, a glow orb that blinks on each shot.
Ice Wall: a 2 x 2.5 x 2 block of jagged ice (3 tilted prisms), no glow.

### 8.2 Characters (silhouette = role; `art-units.md` part-table format when built; budget as there)
| Unit | Height / radius | Concept | Silhouette at 40 m | Signature detail | Glow points |
|---|---|---|---|---|---|
| **Torvald** | 2.1 / 0.55 | A broad old frost-king in a fur mantle, a **tall crown of jagged ice spikes** and a staff topped by a floating snowflake crystal | Wide shoulders (mantle 1.4 m across), crown spikes, staff | The crystal snowflake (6 flat prisms) spins 30°/s; on cast it flares and snaps into a star | staff crystal 3.0, crown gem, eye bar |
| Rime Hauler | 1.4 / 0.4 | A stocky ice-cutter in a fur hood with a **sledge-pick** and an ice-block crate on the back | Round, tool over shoulder, box on back | Frost breath puff every 3 s (4 particles) | lantern on the crate 1.5 |
| Rimeshield | 1.7 / 0.5 | A square armored guard behind a **round shield of clear ice**, short axe | Widest line unit: shield 0.9 m diameter | Shield is translucent team glow at 0.4 alpha with a silver rim | visor 1.5 |
| Shardcaster | 1.6 / 0.45 | A hooded caster **holding a long crystal rod sideways**, quiver of shards | Narrow, long horizontal rod | 3 shards orbit the rod tip | rod tip 1.5 |
| Rime Seer | 1.6 / 0.45 | A robed seer with a **tall hooked staff carrying a hanging ice lantern** | Bell robe + tall hook (vertical extra) | The lantern swings; beam comes from it | lantern 1.5 |
| Rime Colossus | 2.6 / 0.8 | A hunched giant of packed ice and stone, **one massive club-arm**, glacier plates on its back | Tallest, asymmetric (club arm reaches the ground) | Back plates are 4 jagged prisms; frost cracks glow when hit | chest core 3.0 |

## 9. Balance sanity check vs Fire and Shadow (level 1 / Recruit, no items)
`EHP = HP x (100 + armor) / 100`. `DPS = dmg / cooldown`. **CE** = EHP x DPS / cost² x 100 (combat value per crystal,
Lanchester square). **PE** = EHP x DPS / pop² / 100 (value per pop at the cap).
| Unit | EHP | DPS | Cost | Pop | CE | PE | Speed | Note |
|---|---|---|---|---|---|---|---|---|
| Flame Guard | 130 | 12.0 | 90 | 1 | **19.3** | 15.6 | 5.0 | Fire line |
| Shade | 90 | 10.0 | 80 | 1 | 14.1 | 9.0 | 4.8 | Shadow line |
| **Rimeshield** | 173 | 10.0 | 100 | 1 | 17.3 | **17.3** | 4.2 | -10 % CE, +11 % PE vs Flame Guard |
| Ember Archer / Nightbolt | 70 / 65 | 7.5 / 7.7 | 100 | 1 | 5.3 / 5.0 | 5.3 / 5.0 | 5.2 / 5.0 | ranged 9 |
| **Shardcaster** | 84 | 6.4 | 110 | 1 | 4.5 | 5.4 | 4.4 | + chill: the target's DPS -20 % |
| **Rime Seer** | 74 | 4.0 | 120 | 1 | 2.0 | 2.9 | 4.2 | + 60 shield / 12 s = 5 HP/s |
| Blaze Rider | 220 | 20.0 | 180 | 2 | 13.6 | 11.0 | 7.5 | |
| Shadow Knight | 420 | 18.6 | 300 | 3 | 8.7 | 8.7 | 4.0 | |
| **Rime Colossus** | 624 | 15.6 | 330 | 3 | 8.9 | 10.8 | 3.4 | + chill on hit |
| Torvald vs Vessa / Malrik (L1) | 484 vs 350 / 400 | 10.0 vs 10.8 / 12.3 | - | 0 | - | - | 4.2 vs 4.6 / 4.4 | tankiest, least burst |
- 1 000 crystals of melee line (square law N² x value): Flame Guard 193 k, **Rimeshield 173 k**, Shade 141 k. At the
  40-pop cap: 40 Flame Guards 2.50 M vs **40 Rimeshields 2.76 M**. Ice loses cheap early fights, wins maxed ones.
- Spells: Fireball rank 1 (60) on a Rimeshield deals 52 (armor 15): Ice shrugs off Fire's burst; Rime Bolt (45) is
  weaker than Shadow Lance (50) but chills. Flash Freeze 2.5 s at rank 3 is the strongest control in the game: kept
  in check by radius 3.5, 16 s cooldown, half on wizards, 2 s freeze immunity.
- Timing: Frost Hall 54 s (+9 s), soldiers +10-20 % train time: Ice's first attack ~4:30 (Fire/Shadow ~3:30).
- Knobs if playtest 7 says Ice is too strong: Rimeshield armor 15 -> 10 (CE 16.5); Flash Freeze rank 3 2.5 -> 2.0 s;
  too weak: Rimeshield cost 100 -> 95; Rime Spire chill 2 -> 3 s.

## 10. Step 7 task list (20-minute boxes; files never overlap inside the step)
| Id | Task | Owner | Files |
|---|---|---|---|
| 7.L1 | Contracts: UnitType / BuildingType fields (2.2, 2.4), statuses, `can_move` / `can_act`, factions `ice` / `nature`, skirmish `enemy_kingdom` | lead | `CLAUDE.md`, `docs/plan/` |
| 7.G1 **[H]** | Statuses `chill` / `frozen` / `rooted` + immunity, `armor` and `idle_regen_pct` from UnitType, on-hit status, support autocast (2.3), `lifetime` | gameplay-high | `scripts/units/unit.gd`, new `scripts/units/support_caster.gd` |
| 7.G2 | 5 Ice `UnitType` .tres; Torvald's stats, armor and growth row | gameplay | `data/units/ice_*.tres`, `scripts/units/wizard.gd` |
| 7.G3 **[H]** | Rime Bolt, Flash Freeze, Rime Aegis + ranks (`SpellType` .tres), Torvald AI cast rules 4.3 | gameplay-high | `scripts/spells/`, `data/spells/rime_*.tres`, `flash_freeze.tres` |
| 7.S1 | 5 Ice `BuildingType` .tres, tower on-hit chill, Ice Wall (+ `counts_for_defeat`), 4th build entry | systems | `scripts/buildings/`, `data/buildings/ice_*.tres` |
| 7.S2 | Skirmish `enemy_kingdom`: spawns the right keep, 3 workers and wizard per kingdom (Fire player vs Ice bot) | systems | `scripts/world/skirmish.gd` |
| 7.U1 | Build menu V slot (r2c1), Torvald card, tooltips, status marks in the selection panel, menu option "Enemy: Shadow / Ice" | ui | `scripts/ui/` |
| 7.I1 | 4 Ice items + Numbing Touch, Frostbite, Frost Ward aura, Glacier Shell | items | `data/items/`, `scripts/items/item_actives.gd` |
| 7.A1 | Ice bot: profile, build and wall rules, mix, Torvald casts, item list | ai | `scripts/ai/`, `data/ai/ice_*.tres` |
| 7.V1 | Rime Keep (8.1) + states | tech-artist | `art/buildings/ice_keep*` |
| 7.V2 | Frost Hall, Snow Lodge, Rime Spire, Ice Wall + states | tech-artist | `art/buildings/ice_{hall,lodge,spire,wall}*` |
| 7.V3 | Torvald + Rime Hauler + Rimeshield | tech-artist | `art/units/wizards/torvald*`, `art/units/ice/{hauler,rimeshield}*` |
| 7.V4 | Shardcaster, Rime Seer, Rime Colossus | tech-artist | `art/units/ice/{shardcaster,seer,colossus}*` |
| 7.V5 | VFX: statuses (2.1), Rime Bolt, Flash Freeze (ice burst ring r 3, 20 shards), Rime Aegis (dome shimmer per unit), support beam | tech-artist | `art/vfx/ice_*` |

## 11. Done when
- [ ] 7.G1: `chill` = x1.25 cooldown and -1.5 m/s (floor 1.0); `frozen` stops move / attack / cast and resumes orders, half on wizards, 2 s immunity after; `rooted` stops movement only; buildings immune; a Rimeshield takes 87 from a 100 hit (armor 15); a Rime Seer shields the lowest-ratio soldier under 80 % within 8 m every 12 s; `PERF OK`.
- [ ] 7.G2: the 5 units and Torvald match sections 3-4 exactly; Torvald L6 = 590 HP / 25 dmg / 150 mana.
- [ ] 7.G3: test: Rime Bolt 45 + chill 3 s; Flash Freeze freezes 3 Shades for 1.5 s and Malrik for 0.75 s; Rime Aegis gives 80 shield to units within 8 m; rank tables 4.2 exact; bot Torvald follows 4.3.
- [ ] 7.S1: numbers of section 5; a Rime Spire hit chills 2 s; 17th wall refused with the message `Wall limit reached`; a side with only walls left loses.
- [ ] 7.S2 / 7.U1: the menu starts Fire vs Ice; Ice workers see V = Ice Wall; tooltips as written.
- [ ] 7.I1: 4 items with those numbers; Glacier Shell = 2.5 s of no damage and no action.
- [ ] 7.A1: headless normal run: Frost Hall at 0:00, Rime Spire by 3:45, first attack 4:00-5:30 with >= 8 pop, retreat at 30 %.
- [ ] 7.V1-7.V5: silhouette sheet names every Ice unit and building; `PERF OK` with 200 Ice units.

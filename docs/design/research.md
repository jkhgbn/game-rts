# Research: Technology and Magic for the four kingdoms

Task 14.D1, written 2026-09-26. Source of truth for step 14 (tasks in section 15). Approved direction (lead's proposal, user
"ok"): two research tracks per kingdom, **Technology** (paid in crystals + **gold**) and **Magic** (crystals + **essence**),
**3 tiers**, tier 3 unlocks the kingdom's **ultimate unit** from step 13 (`cavalry-mounts.md`: the titans `cinder_dragon`,
`nightmare_knight`, `war_mammoth`, `elder_treant`, trained at each kingdom's Lair, no max count), **12 upgrades per kingdom**
(6 tech, 6 magic) and one unique mechanic per kingdom: Fire **Heat**, Shadow **Souls**, Ice **Frostbite** (control), Nature
**Growth rings**. Two goals besides fun: research must **lengthen games** (bot-vs-bot games end at 9-11 min, target 15-20) and
must **fix, not worsen** the `balance-2.md` results (Nature too strong, Ice too weak; Fire now also wins most games).
Every name, number and rule is our own. Metres, seconds, `m:ss` since the navmesh was ready, positions `(x, z)` on Crown Hollow;
point mirror as in `market-trade.md`. Numbers build on the real data (`data/units/*.tres`, `data/buildings/*.tres` as of today),
`balance-1.md`, `balance-2.md` (Results), `levels.md`, `items.md`, `champions.md`, `skills-rework.md`, `market-trade.md`,
`map-fill.md`.

## 0. Decisions of the user (answered 2026-09-26)
| # | Question | Decision |
|---|---|---|
| Q1 | Where does research happen? | **Two small buildings per kingdom**: a **Forge** (Technology) and a **Sanctum** (Magic), 125 crystals each, one of each per team |
| Q2 | What opens tiers 2 and 3? | **Keep upgrades**: Keep -> **Stronghold** (tier 2) -> **Citadel** (tier 3), keep +20 % / +40 % HP. The Citadel opens tier-3 research and the Lair (step 13), so the titans |
| Q3 | Nature's regeneration | User: **"only 1 unit, make it T3"**. Regeneration is **no longer an army-wide Nature trait**: `idle_regen_pct` of every ordinary Nature unit goes to **0** (section 4.5, data change); the regeneration identity lives in **one unit, the tier-3 Elder Treant** (its grove aura and Seedlings, `cavalry-mounts.md` 5.2) and in the tier-3 magic **Heartroot** that buffs it. No army-wide regen research at tiers 1-2. Nature buildings keep their idle regen. Nature's early / mid game is compensated with base numbers and combat research (4.5, 9.3) so it does not become the weakest |
| Q4 | Shadow's Souls | **Autocast rites**, each with an on / off toggle in the research window (Raise the Dead, Dread Toll) |

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Buildings | Per kingdom a **Forge** (tech, build key **J**) and a **Sanctum** (magic, key **L**), 2 x 2, 125 crystals (Nature 105), one each, need a completed Hall | Two researches in parallel; raid targets; readable progression in the base. N / M of the build menu belong to step 13 (Stables / Lair) |
| Tiers | Tier 1 = the building; tier 2 = **Stronghold**; tier 3 = **Citadel** (keep upgrades) + 1 research of the previous tier **in the same track** | One gate for both tracks, visible on the map, lengthens sieges |
| Step-13 tiers | Stables (cavalry, mounts) keep their step-13 rule (a Hall). The **Lair** (titans) needs the **Citadel** when research is on (it replaces the 8:00 gate) | One tier ladder: the titan is the kingdom's tier 3 |
| Upgrades | **12 per kingdom**, 2 per tier per track; slot keys **Z X C V B N** on the building card | Fits the command card; same shape for all four kingdoms |
| Prices | Tech: crystals (tier 1) then crystals + gold (tiers 2-3). Magic: crystals + essence. Keystone (the mechanic unlock) is the cheapest research of its kingdom | Gold only flows from ~6:00 (posts open 4:00): tier-1 tech must not wait for it |
| No trade | Gold part paid **in crystals 1:1** when the team has no GoldBank (missions, "Trade Off") | Research never needs the trade system |
| Unique mechanics | Heat, Souls, Frostbite, Growth rings; **all off until the kingdom's keystone (magic tier 1, slot Z)** | A match without research plays exactly like today: the balance-2 baseline stays valid |
| Ultimate unit (titan) | Cinder Dragon, Nightmare Knight, War Mammoth, Elder Treant (`cavalry-mounts.md` 5), trained at the Lair; the Lair needs a **Citadel** (`BuildingType.required_keep_tier = 3`); no max count | "Tier 3 unlocks the ultimate" |
| Nature regen (Q3) | Ordinary Nature units: no idle regen. Only the Elder Treant (tier 3) regenerates and heals around it; Heartroot (tier-3 magic) makes that its army role | User decision "only 1 unit, make it T3" |
| Effects | Permanent for the match; on living and future units / buildings (`research:<id>` modifiers, like the wares' `ware:<id>`) | Same pattern as `GoldBank.apply_wares` |
| Enemy view | Research is hidden; the enemy sees buildings, keep tier (art) and effects (glow, Risen, frost...) | Scouting the Forge / Sanctum / keep reads the enemy's plan |
| Missions | `research_enabled` false in missions 1-4 | One new system per mission |

## 2. Where research happens
### 2.1 The research buildings (systems 14.C2)
| id | Name | Track | Cost | Build time | max_hp | Footprint | Height | Sight | kill_xp / essence | Build key |
|---|---|---|---|---|---|---|---|---|---|---|
| `fire_forge` | Ember Forge | Tech | 125 | 40 | 1000 | 2 x 2 | 5 | 10 | 60 | J |
| `fire_sanctum` | Cinder Sanctum | Magic | 125 | 40 | 1000 | 2 x 2 | 5.5 | 10 | 60 | L |
| `shadow_forge` | Bone Foundry | Tech | 125 | 40 | 1000 | 2 x 2 | 5 | 10 | 60 | J |
| `shadow_sanctum` | Soul Crypt | Magic | 125 | 40 | 1000 | 2 x 2 | 5.5 | 10 | 60 | L |
| `ice_forge` | Rime Forge | Tech | 125 | **48** (x1.2) | **1200** | 2 x 2 | 5 | 10 | 60 | J |
| `ice_sanctum` | Rune Sanctum | Magic | 125 | **48** | **1200** | 2 x 2 | 5.5 | 10 | 60 | L |
| `nature_forge` | Root Nursery | Tech | **105** | **34** (x0.85) | **900** | 2 x 2 | 5 | 10 | 60 | J |
| `nature_sanctum` | Wildroot Sanctum | Magic | **105** | **34** | **900** | 2 x 2 | 5.5 | 10 | 60 | L |
(The Nature Sanctum is not called "Elder Circle": step 13 gives that name to the Nature Lair.)
- `kind` `&"forge"` / `&"sanctum"`, `max_count` **1** (limit message `"Only one Forge"` / `"Only one Sanctum"`), `requires_kind`
  `&"barracks"` (`"Needs a completed Hall"`, the Bazaar's rule and message), no keep-distance rule, counts for defeat, not a shop,
  not a drop-off, no training. Nature ones have `idle_regen_pct` 1.0 like every Nature building.
- Build menu (`buildings.md`; row 2 is full with Wall V, Bazaar B and step 13's **Stables N / Lair M**): **J** = Forge at r3c1,
  **L** = Sanctum at r3c2 (the keys either side of K, the research window: the "research cluster"; with the build menu open
  they mean the buildings, as Z X C already do). J and L are free everywhere else.
  Tooltip: `Ember Forge  [J]\nCost 125 crystals · 40 s · 1000 HP\nResearches Technology. One per kingdom.`
- Placeholder look (until 14.V1-14.V8): Forge = box 3.6 x 3 x 3.6 in the body colour + a chimney cylinder r 0.4 h 2.5 with an
  emissive top in the kingdom glow; Sanctum = a ring of 6 pillars (r 1.5, h 3) around a floating 0.6 m octahedron (glow).
- Bot slots **R1** (Forge) **`(56, -46)`** and **R2** (Sanctum) **`(40, -54)`** on the enemy side, mirrored `(-56, 46)` /
  `(-40, 54)` on the player side. Checked against today's slots and step 13's T2 Stables `(55, -37)` / T3 Lair `(33, -55)`: no
  overlap with the keep, H1, V1, V2, V3, S1, S2, M1, T2, T3 (R1 is 2 m from V1 and 4 m from T2; R2 2 m from T3); nearest cell
  centre 8.6 m from node b, R1 far from node a (>= 4 m rule); both inside the buildable area (x <= 58). 14.C3 clears them of
  trees and rocks (like `HOUSE_SLOT`); if step 12 put props there, the next valid offset (`SLOT_SHIFTS`).

### 2.2 Keep tiers: Keep -> Stronghold -> Citadel (systems 14.C2)
| Tier | Name | Upgrade price / time | Needs (checked when the upgrade starts) | Keep effect | Opens |
|---|---|---|---|---|---|
| 1 | Keep (Rime Keep, Heartwood...) | - | - | today's numbers | Tier-1 research |
| 2 | **Stronghold** | **200 crystals, 60 s** | A completed own Forge **or** Sanctum, and 1 completed research | `max_hp` x **1.2** of the type's base (Fire / Shadow 3 000, Ice 3 600, Nature 2 700), attack damage +4 (12 -> 16) | Tier-2 research |
| 3 | **Citadel** | **300 crystals, 90 s** | Stronghold, a completed Forge **and** Sanctum, 2 completed tier-2 researches (any tracks) | `max_hp` x **1.4** (3 500 / 4 200 / 3 150), attack damage +8 (20) | Tier-3 research, **the Lair** (step 13), so the titan |
- The upgrade runs **beside** the worker queue (the keep keeps training). Button on the keep card (key **N**, section 7); cancel =
  click its chip in the keep panel, **full refund**. The HP gained is healed; the Masons' Charter (x1.15) multiplies on top.
- No kingdom time multiplier on upgrades (the Ice +20 % / Nature -15 % rule is for construction).
- The team's tier = the highest tier of its living keeps. A tier lost with the keep keeps every finished research, but new
  tier-2 / tier-3 research is refused (`"Needs a Stronghold"`).
- Messages: `The Keep is now a Stronghold` / `... a Citadel: you can build a Dragon Roost` (own; the kingdom's Lair name); `The enemy keep has become a
  Citadel` only if the enemy keep is visible when it completes.
- The keep model shows its tier (`set_tier(tier)`, 14.V9-14.V12): the enemy can read it when scouting.

### 2.3 Research rules (systems 14.C1 / 14.C2)
| Rule | Value |
|---|---|
| Where | Each research belongs to its track's building. Only a **completed, living** own Forge / Sanctum researches |
| Parallel | **One research at a time per building** (so at most one tech and one magic at once); queue **3** per building |
| Pay | Everything (crystals, gold, essence) is paid when queued, as unit training |
| Cancel (player) | Click the queue slot: **full refund**; cancelling slot 1 loses its progress |
| Building destroyed | Queued, not started: full refund. The one in progress: **75 % refund** (the construction-cancel ratio); progress lost |
| Done | Permanent for the match; applies at once to living units / buildings and to everything spawned later |
| Order inside a track | Tier N needs the keep tier N **and** one completed research of tier N-1 in the **same** track. Inside a tier the 2 researches are free choices |
| Duplicates | A research can only be in one queue and only be done once |
| Keystone | Magic slot Z of each kingdom (Kindled Blood, Soul Harvest, Deep Winter, Rings of the Old Wood). It turns the unique mechanic on |
Refusals (`can_research(id) -> String`, first that applies): `"Unknown research"`, `"Already researched"`, `"Already queued"`,
`"Needs an Ember Forge"` (or the right building name: missing, destroyed or under construction), `"Needs a Stronghold"` /
`"Needs a Citadel"`, `"Needs a Tier 1 Tech research"` (the right tier / track), `"Queue is full"`, `"Not enough crystals"`,
`"Not enough gold"`, `"Not enough essence"`. Money refusals also flash the resource in the top bar (`spend_failed`).

### 2.4 Standard prices (per research; exceptions are marked in the trees of section 4)
| Tier | Tech | Magic | Time |
|---|---|---|---|
| 1 | **100 crystals** | **50 crystals + 60 essence** (keystone **50 + 50**, 35 s) | 40 s |
| 2 | **100 crystals + 100 gold** | **75 crystals + 125 essence** | 55 s |
| 3 | **125 crystals + 175 gold** | **100 crystals + 175 essence** | 70 s |
- **No trade** (`GoldBank.for_team(team) == null`): the gold part is added to the crystal part (tier-2 tech = 200 crystals). The
  UI shows the folded price.
- **Totals for one kingdom, everything**: buildings 250 (Nature 210) + keep upgrades 500 + tech 650 crystals / 550 gold + magic
  450 crystals / 710 essence = **~1 850 crystals, 550 gold, 710 essence** (Ice ~1 755 crystals, 690 essence; Nature ~1 810
  crystals).
  A 20-minute side gathers ~6 000-7 500 crystals, ~2 500-4 000 gold (both sides trading) and ~3 800 essence (`items.md`): the full
  tree is ~25-30 % of the crystals, a real "army or research" choice.

## 3. The four kingdom mechanics (gameplay 14.G1 / 14.G2, counters in ResearchBank 14.C1)
All four are **off until the keystone** is researched. "Soldiers" = the wares' rule (`GoldBank.is_soldier_unit`: not workers,
caravans, wizards, champions, trackers); the ultimate unit is a soldier.

### 3.1 Heat (Fire): damage ramps up the longer a fight lasts
| Rule | Value |
|---|---|
| Who | Every Fire soldier (per unit, 0 to the cap) |
| In combat | The unit landed an attack or took damage in the last **3.0 s** |
| Gain | **+1 Heat per 2.5 s** spent in combat without a break (a timer that resets when the unit leaves combat) |
| Loss | Out of combat: **-1 per 1.0 s** (Everburning: -1 per 3.0 s) |
| Effect | Modifier `mech:heat` = `attack_damage_pct` **+0.03 per Heat**; rewritten only when the count changes |
| Cap | **3** (Kindled Blood, +9 %) -> **5** (White Heat, +15 %). White Heat: at full Heat also `move_speed` +0.5 |
| Extra sources | Everburning: Kindle gives +3 Heat to every unit it hastes; Ember Rebirth: a reborn unit rises with 3 Heat |
| Look | Model hook `set_heat(ratio 0-1)` (ember cracks glow); at full Heat pooled ember sparks (14.V14); the single-unit panel shows `Heat 4 / 5 (+12 % damage)` |
Average bonus over a 20 s fight at cap 5: about +10 % damage (0 -> 15 % in 12.5 s, then 15 %). Tick: 0.5 s, on the idle-regen tick.

### 3.2 Souls (Shadow): a small resource from kills, spent by rites
| Rule | Value |
|---|---|
| Bank | `ResearchBank.souls`, team counter, **cap 20** (Legion of Night: 40). Not saved, not carried |
| Gain | Every kill credited to the team (the essence credit rule of `items.md` / `levels.md`): **+1** for a pop-1 unit (soldiers, workers, caravans, neutral Magpies and creatures), **+2** for a pop >= 2 unit or a completed building, **+4** for a champion or a wizard. **0** for summons (Saplings, Risen) and construction sites |
| Soul Harvest | Each soul gained also heals the killer **12 HP** if it is a living Shadow soldier or Malrik |
| Rite: **Raise the Dead** (research) | When an enemy soldier, worker or champion dies within **10 m** of a living Shadow soldier and souls >= **3**: spend 3; **1.0 s** later a **Risen** climbs out at the corpse. Legion of Night: own soldier deaths count too (never a Risen dying) |
| Risen (`data/units/risen.tres`) | HP **80**, damage **9**, cooldown **1.0**, range 1.5, speed 4.6, aggro 10, armor 0, radius 0.4, height 1.6, `lifetime` **30 s**, pop 0, **0 XP, 0 essence, 0 souls** to anyone, never levels. Attack-moves to the nearest enemy within 10 m, else holds (the Sapling rule). Max **6** alive per team (Legion: **10**, +50 % HP and damage = 120 / 13.5) |
| Rite: **Dread Toll** (with Dread) | Checked every 1 s per Shadow Knight (and Nightmare Knight): >= **4** enemy soldiers within **6 m** and souls >= **5** -> spend 5, those enemies get `feared` **1.5 s**. Per-Knight cooldown 20 s; one Toll per team per 5 s |
| Reserve | While Dread Toll is on and a Knight lives, Raise the Dead never spends below 5 souls |
| Toggles | Each rite has an on / off switch in the research window (default **on**); the bot keeps both on |
| Look | A soul wisp flies from the victim to the killer (14.V15); top-bar chip `Souls 12 / 20` (Shadow only, once Soul Harvest is done) |
Expected: a Shadow side kills ~40-70 things in a 20-minute game -> ~50-80 souls -> ~12-18 Risen and a few Tolls.

### 3.3 Frostbite (Ice control): chills pile up into a freeze
| Rule | Value |
|---|---|
| Who | Every non-allied unit (enemy or neutral) hit by an Ice frost source of a team that owns **Deep Winter**. Buildings immune |
| Meter | `frost` 0-100 per unit (`Unit.add_frost(amount, source_team)`) |
| Gains | Shardcaster hit **15**, Rime Colossus hit **30**, Avalanche cleave **10** per unit, Rime Spire hit **15**, Frost Bombard splash **10**, Rime Bolt **40**, Permafrost pulse **5**, a Rimeward shield break **15**, Torvald's Numbing Touch / Frostbite item passives **10**. Heart of Winter: **x1.5** |
| Freeze | At **100**: `frozen` **1.0 s** (wizards and champions 0.5 s, the existing `hero_mult`), frost -> 0. During the existing 2 s frozen immunity, frost stops at **90** |
| Decay | After **1.5 s** without a gain: **-25 / s** |
| Look | Frost creeps up the victim's model (hook `set_frost(ratio)` if present) and a thin light-blue line under its HP bar, **for the Ice viewer only**; the freeze pops with the Frostbite burst (14.V16) |
Example: 6 Shardcasters focusing one Blaze Rider (15 x 6 / 1.4 s = 64 frost / s) freeze it after ~1.6 s, then every ~3.4 s
(1 s frozen + 2 s immunity + refill): about **-30 %** of its time acting, on top of `chill` (-20 % attack rate, -1.5 m/s).

### 3.4 Growth rings (Nature): stronger as the game goes on
| Rule | Value |
|---|---|
| Counter | `ResearchBank.rings` 0-**8**: **+1 ring every 90 s** after Rings of the Old Wood completes (8 rings 12:00 later) |
| Soldiers | Modifier `mech:rings`: `max_hp_pct` **+0.015** and `attack_damage_pct` **+0.01** per ring (8 rings: +12 % HP, +8 % damage), on living and new Nature soldiers (the Elder Treant included) |
| Buildings | Nature buildings `max_hp` x **(1 + 0.015 x rings)** (research HP factor, section 13) |
| Look | Each new ring: a ring pulse and a leaf burst at the Heartwood (14.V17); top-bar chip `Rings 3 / 8 · next 0:42` (Nature only) |
Growth is now Nature's army-wide identity (regeneration is the Treant's, Q3): rings give HP and damage, never regeneration.
With the keystone at ~6:00, Nature gains ~1 % army value per 90 s until ~18:00.

## 4. The research trees (48 upgrades; ids `data/research/<id>.tres`)
Columns: slot key on the building card (Z X C V B N = tier 1, 1, 2, 2, 3, 3), id, name, price (c crystals, g gold, e essence),
time, exact effect. "How" says which hook does it (section 4.5). Unit ids in brackets are today's `data/units` ids. The effect
line in quotes is the tooltip's third line.

### 4.1 Fire (Vessa): forge and alchemy
**Ember Forge (Technology)**
| Key | id | Name | Price | Time | Effect | How |
|---|---|---|---|---|---|---|
| Z | `fire_quenched_blades` | Quenched Blades | 100 c | 40 | `attack_damage` Flame Guard +1 (13), Blaze Rider +2 (20), Ember Archer +1 (10). "Flame Guards +1, Blaze Riders +2, Ember Archers +1 damage." | modifier per unit id |
| X | `fire_ember_mail` | Ember Mail | 100 c | 40 | Flame Guard, Blaze Rider `armor` +6; Ember Archer, Ash Hurler `max_hp` +10 | modifier |
| C | `fire_great_bellows` | Great Bellows | 100 c + 100 g | 55 | Ember Halls and the keep train **15 % faster** (progress x1.15) | `train_speed_mult` |
| V | `fire_blasting_powder` | Blasting Powder | 100 c + 100 g | 55 | Ash Hurler: `building_damage_bonus` +0.30; every shot also deals 40 % of its damage to other enemy units within 1.5 m of the target | stats + splash |
| B | `fire_firebrand_flasks` | Firebrand Flasks | 125 c + 175 g | 70 | Ember Archer and Ash Hurler hits apply `burn` 4 damage per 1 s for 3 s (refreshes, never stacks) | on-hit DoT |
| N | `fire_salamander_oil` | Salamander Oil | 125 c + 175 g | 70 | Ember Spires and the keep +3 damage, +1 range, hits `burn` 4 / s for 3 s; every Fire building +10 % max HP | tower bonus, HP factor |

**Cinder Sanctum (Magic)**
| Key | id | Name | Price | Time | Effect | How |
|---|---|---|---|---|---|---|
| Z | `fire_kindled_blood` | Kindled Blood (keystone) | 50 c + 50 e | 35 | Turns **Heat** on, cap 3 (3.1) | mechanic |
| X | `fire_flame_rites` | Flame Rites | 50 c + 60 e | 40 | A dying Fire soldier leaves burning ground: r 2.0 (Blaze Rider and the ultimate 2.5), 3 s, 3 damage per 0.5 s to enemy units inside (not buildings). Max 8 zones per team (the oldest ends first) | death hook, `SpellZone` (the Ember Step scorch) |
| C | `fire_white_heat` | White Heat | 75 c + 125 e | 55 | Heat cap 3 -> **5**; at full Heat `move_speed` +0.5 | mechanic |
| V | `fire_ember_rebirth` | Ember Rebirth | 75 c + 125 e | 55 | Blaze Riders and Fire soldiers of veterancy Elite or Paragon: the first lethal hit leaves them at 1 HP with status `rebirth` 2.0 s (no move, no act, no damage taken, ignored by auto-targeting), then they heal to **40 %** max HP with 3 Heat. Once per unit life; never the ultimate unit | `death_guard`, status |
| B | `fire_splitting_flame` | Splitting Flame | 100 c + 175 e | 70 | Vessa's Fireball: 0.3 s after impact, 3 embers land 2.5 m from the centre (120° apart), each dealing **35 %** of the Fireball's damage (after `spell_power`) in r 1.5 to enemy units and buildings | spell hook |
| N | `fire_everburning` | Everburning | 100 c + 175 e | 70 | Heat decays 1 per **3 s** (was 1 s); Kindle gives **+3 Heat** to every unit it hastes | mechanic, spell hook |

### 4.2 Shadow (Malrik): necro-engineering
**Bone Foundry (Technology)**
| Key | id | Name | Price | Time | Effect | How |
|---|---|---|---|---|---|---|
| Z | `shadow_bone_plating` | Bone Plating | 100 c | 40 | Shade `armor` +8, Shadow Knight `armor` +12, Grave Hound `max_hp` +10 | modifier |
| X | `shadow_rot_bolts` | Grave-Rot Bolts | 100 c | 40 | Nightbolt `attack_damage` +1 (11); its hits apply `blighted` 4 s: healing, `hp_regen` and idle regen received **x0.5** (shields unaffected) | on-hit status |
| C | `shadow_catacombs` | Catacombs | 100 c + 100 g | 55 | Shadow Knights cost **2 pop** (was 3), living and queued ones included; the Nightmare Knight 4 -> **3** pop | `Economy.pop_of_type` |
| V | `shadow_ossuary_walls` | Ossuary Walls | 100 c + 100 g | 55 | Every Shadow building +15 % max HP; Night Spires +3 damage | HP factor, tower bonus |
| B | `shadow_grave_carts` | Grave Carts | 125 c + 175 g | 70 | Shade, Grave Hound, Shadow Knight (and Nightmare Knight) `building_damage_bonus` +0.25 | stat |
| N | `shadow_black_iron` | Black-Iron Barding | 125 c + 175 g | 70 | Shadow Knight `max_hp` +80, `move_speed` +0.4; Grave Hound `armor` +5 | modifier |

**Soul Crypt (Magic)**
| Key | id | Name | Price | Time | Effect | How |
|---|---|---|---|---|---|---|
| Z | `shadow_soul_harvest` | Soul Harvest (keystone) | 50 c + 50 e | 35 | Turns **Souls** on; each soul heals the killer 12 HP (3.2) | mechanic |
| X | `shadow_hushed_paws` | Hushed Paws | 50 c + 60 e | 40 | Grave Hounds that have not attacked or been damaged for 3 s are **veiled**: the enemy sees them only within **5 m** of one of its units or buildings, and enemy auto-targeting skips them. Attacking or being hit unveils for 3 s | fog rule, `hide_from_auto_target` |
| C | `shadow_raise_dead` | Raise the Dead | 75 c + 125 e | 55 | Rite: Risen from enemy corpses for 3 souls (3.2) | rite |
| V | `shadow_dread` | Dread | 75 c + 125 e | 55 | Shadow Knights (and Nightmare Knights) pulse every 1 s: enemy soldiers and champions within 6 m get `dread` 1.5 s (`attack_damage_pct` -0.10; wizards immune). Adds the rite **Dread Toll** (3.2) | pulse, status, rite |
| B | `shadow_legion` | Legion of Night | 100 c + 175 e | 70 | Soul cap 40; Risen +50 % HP and damage, max 10; own soldier deaths also raise | mechanic |
| N | `shadow_umbral_pact` | Umbral Pact | 100 c + 175 e | 70 | Malrik's Umbral Shroud also gives `shroud` 3 s to own soldiers within 6 m; Shadow Lance heals **75 %** of the damage dealt (was 50 %) | spell hook |

### 4.3 Ice (Torvald): frost engineering (the cheapest tier 1: the kingdom that needs help)
**Rime Forge (Technology)**
| Key | id | Name | Price | Time | Effect | How |
|---|---|---|---|---|---|---|
| Z | `ice_heavy_crossbows` | Heavy Crossbows | **75 c** | 40 | Shardcaster `attack_range` +1.5 (10.5), `attack_damage` +2 (11); Rime Spire range +1 (12) | stats, tower bonus |
| X | `ice_hauler_sledges` | Hauler Sledges | **75 c** | 40 | Rime Hauler `move_speed` +0.6 (5.2), `carry` +1 (11 crystals a trip): about **+17 %** income per worker | stats |
| C | `ice_hoarfrost_plate` | Hoarfrost Plate | **75 c** + 100 g | 55 | Rimeshield `armor` +8 (23); Rime Colossus `armor` +8 (28), `max_hp` +40; Shardcaster, Rime Seer `max_hp` +10 | modifier |
| V | `ice_avalanche_mauls` | Avalanche Mauls | 100 c + 100 g | 55 | Rime Colossus attacks cleave: 40 % of the damage to other enemy units within 2.0 m of the target, and `chill` 1.5 s on them | splash stats + chill |
| B | `ice_packed_walls` | Packed-Ice Walls | 125 c + 175 g | 70 | Ice Wall max HP 500 -> **800**, `max_count` 16 -> **24**, build time 8 -> 6 s; every other Ice building +10 % max HP | HP factor, limits |
| N | `ice_frost_bombards` | Frost Bombards | 125 c + 175 g | 70 | Rime Spire +3 damage (15) and its chill also hits enemy units within 2.5 m of the target; the Rime Keep's attack chills 2 s | tower bonus |

**Rune Sanctum (Magic)**
| Key | id | Name | Price | Time | Effect | How |
|---|---|---|---|---|---|---|
| Z | `ice_deep_winter` | Deep Winter (keystone) | **40 c + 40 e** | 35 | Turns **Frostbite** on (3.3) | mechanic |
| X | `ice_carved_runes` | Carved Runes | **40 c + 50 e** | 40 | Rimeshields, Rime Colossi (and War Mammoths) send back **10 %** of the damage they take from melee auto-attacks (after armor and shields) to the attacker, credited to Ice (the Barbs rule, `kingdom-nature.md` 5) | `reflect_melee` stat |
| C | `ice_permafrost` | Permafrost | 75 c + 125 e | 55 | Every completed Ice building pulses every 1 s: enemy units within **8 m** (walls: 3 m) get `chill` 1.5 s and 5 frost | building pulse |
| V | `ice_rimeward` | Rimeward Seers | 75 c + 125 e | 55 | Rime Seer shield 60 -> **90**, interval 12 -> **10 s**; a Seer shield that breaks chills enemy units within 3 m of its bearer (2 s, 15 frost) | `support_amount` / `support_interval` stats, shield hook |
| B | `ice_stasis` | Stasis | 100 c + 175 e | 70 | The first time an Ice soldier would die it is encased instead: 1 HP, status `stasis` 3.0 s (frozen look, no move, no act, no damage taken, ignored by auto-targeting), then it thaws at **25 %** max HP. Once per unit life; not workers, summons or titans | `death_guard`, status |
| N | `ice_heart_of_winter` | Heart of Winter | 100 c + 175 e | 70 | Frost gain x1.5; Torvald's Flash Freeze radius +0.5; Rime Bolt +50 % damage to a `frozen` target | mechanic, spell hook |

### 4.4 Nature (Ysolde): cultivation and druidism (Q3: no army regen; growth and combat early, the Treant's regeneration at tier 3)
Numbers below assume the Nature base data of 4.5 (no idle regen on ordinary units, compensation stats).
**Root Nursery (Technology)**
| Key | id | Name | Price | Time | Effect | How |
|---|---|---|---|---|---|---|
| Z | `nature_seasoned_bark` | Seasoned Bark | 100 c | 40 | Thornling, Burr Slinger, Bloomtender `armor` +5; Bramblehorn `armor` +10 | modifier |
| X | `nature_barbed_burrs` | Barbed Burrs | 100 c | 40 | Burr Slinger `attack_damage` +1 (8), `attack_range` +1 (9.5); Thornling `attack_damage` +1 (9) | modifier |
| C | `nature_seeding` | Seeding | 100 c + 100 g | 55 | A crystal node with crystals left and a completed own keep or Hall within 20 m regrows **+2 crystals every 5 s** (24 / min), never above its start amount (a node at 0 is gone) | node hook |
| V | `nature_oakheart_hide` | Oakheart Hide | 100 c + 100 g | 55 | Bramblehorn `max_hp` +60 (480), `attack_damage` +2 (20); Elder Treant `max_hp` +150; every Nature building +10 % max HP | modifier, HP factor |
| B | `nature_thorned_bastions` | Thorned Bastions | 125 c + 175 g | 70 | Grove Halls gain an attack (10 damage, range 9, cooldown 1.5, the Bramble Spire bolt); the Heartwood +4 damage; Bramble Spire aura radius 8 -> 10 | building attack, tower bonus |
| N | `nature_living_timber` | Living Timber | 125 c + 175 g | 70 | Nature buildings regenerate after **5 s** without damage (was 10) at **1.5 %** / s (was 1.0); Bramble Spire +2 damage (12). Buildings only | building regen, tower bonus |

**Wildroot Sanctum (Magic)**
| Key | id | Name | Price | Time | Effect | How |
|---|---|---|---|---|---|---|
| Z | `nature_old_rings` | Rings of the Old Wood (keystone) | 50 c + 50 e | 35 | Turns **Growth rings** on (3.4) | mechanic |
| X | `nature_entangling_roots` | Entangling Roots | 50 c + 60 e | 40 | Bramble Spire and Heartwood hits root enemy units **0.75 s** (heroes half); a unit is rooted this way at most once per 4 s | tower on-hit |
| C | `nature_sap_frenzy` | Sap Frenzy | 75 c + 125 e | 55 | Thornling `attack_cooldown_pct` **-0.12**, Burr Slinger **-0.10**; Bramblehorn and Stagrunner `move_speed` +0.4. No regeneration | modifier |
| V | `nature_wild_shape` | Wild Shape | 75 c + 125 e | 55 | Thornlings and Bramblehorns that reach Veteran (level 2; those already there at once) shift for good: **Thornbeast** (scale x1.2, `max_hp_pct` +0.25, `attack_damage` +2, `move_speed` -0.2) / **Old Bramblehorn** (scale x1.1, `armor` +10, `attack_damage` +3) | `level_changed` hook |
| B | `nature_heartroot` | **Heartroot** (the Treant's research) | 100 c + 175 e | 70 | Elder Treant: grove aura radius 8 -> **12** and it now also gives own Nature soldiers `idle_regen_pct` **+1.0** (the old Verdant regen, only near a Treant); the aura also works **while walking** (r 6, half values: `hp_regen` +2, idle regen +0.5); Seedlings every 15 -> **10 s**, max 3 -> **4**; the Treant's own `idle_regen_pct` 1.5 -> **2.5** | `TitanAbilities` params, aura stats |
| N | `nature_ysoldes_bloom` | Ysolde's Bloom | 100 c + 175 e | 70 | Wild Bloom also gives `armor` +10 while it heals; Call the Thicket summons +1 Sapling (4 / 6) | spell hook |
Nature's only army-wide regeneration is Heartroot's, and only around a living Elder Treant (tier 3, Citadel + Lair + 600 crystals):
"only one unit, at tier 3".

### 4.5 Nature base data (Q3; not research: a balance patch that can ship before step 14; gameplay 14.B1 + ai 14.B2)
`file / field: old -> new`. Goal: no army-wide idle regen, and Nature not the weakest kingdom (it wins 12 / 16 today mostly by
retreat-and-regrow; losing that is ~-15-20 % of its value over a game; the compensation below gives back ~+10 % in raw fights, the
tier-1 / 2 research the rest).
| File / field | Old -> new | Why |
|---|---|---|
| `data/units/thornling.tres`, `burr_slinger.tres`, `bloomtender.tres`, `sprigling.tres`, `sapling.tres` / `idle_regen_pct` | 1.0 -> **0.0** | Q3 |
| `data/units/bramblehorn.tres` / `idle_regen_pct` | 2.0 -> **0.0** | Q3 |
| `data/units/stagrunner.tres` (step 13) / `idle_regen_pct` | 1.0 -> **0.0** | Q3 (13.D1 gave it the Nature rule) |
| `data/units/elder_treant.tres` / `idle_regen_pct` | 1.5 (unchanged) | The one regenerating unit |
| `scripts/units/nature_wizard.gd` / `VERDANT_REGEN_PCT` | 1.5 (unchanged) | Ysolde is a hero, not the army; she is the frailest wizard |
| Nature buildings `idle_regen_pct`, Bramble Spire aura `hp_regen` +2 | unchanged | Buildings keep their regen (lead's rule); the Spire aura is local defence |
| `data/units/thornling.tres` / `cost` | 60 -> **55** (`kill_xp` 30 unchanged) | Undo the balance-2 round-1 nerf that was aimed at the regrow loop |
| `data/units/thornling.tres` / `max_hp` | 70 -> **75** | `kingdom-nature.md` 9 "too weak" knob: survives a rank-2 Fireball |
| `data/units/burr_slinger.tres` / `max_hp` | 50 -> **55** | Same, the most fragile ranged unit |
| `data/units/bramblehorn.tres` / `max_hp` | 380 -> **420** | The heavy loses the biggest regen (2 %/s) |
| `data/units/bloomtender.tres` / `support_amount` | 12 -> **14** | The only early sustain left is a unit you pay for (Shadow's Grave-Rot Bolts counter it) |
| `data/ai/nature_*.tres` / `retreat_hp` | 0.5 -> **0.4** | Retreating to regrow no longer heals: same rule as Fire / Shadow |
| `data/ai/nature_*.tres` / the relaunch rule (`regrow_wait` 45, "85 % HP") | -> **off** (`regrow_wait` 0; relaunch by `ai.md` rule 7 only) | Without regen the army never reaches 85 %: it would wait forever |
| `scripts/ai/ai_profile.gd` `nature()` fallback | same values | A missing .tres must not bring the old numbers back |
CE check (`kingdom-ice.md` 9): Thornling 75 x 8.9 / 55² x 100 = **22.1** (was 20.6 with regen on top; best line per crystal, worst
per pop, as designed); Bramblehorn EHP 420 (CE 15.8). If Nature then loses most games: first knob Thornling `max_hp` 75 -> 80.

### 4.6 New hooks the trees need (one place for the coders)
| Hook | Owner | Rule |
|---|---|---|
| Stat `attack_range` | gameplay | Becomes a Stats stat: base `UnitType.attack_range`, written back to the property on recompute (like `move_speed`) |
| Stat `building_damage_bonus` | gameplay | Auto-attack damage to a non-Unit target x `(1 + value)` |
| Stats `splash_ratio`, `splash_radius` | gameplay | After an auto-attack lands on a Unit: other enemy **units** within `splash_radius` of the target take `dealt x splash_ratio` (same attacker; no chain). Avalanche Mauls also chills them |
| Stat `reflect_melee` | gameplay | Reuse the Barbs code (`item_passives.gd`): a melee auto-attacker (attack_range <= 3) takes `value x damage taken` |
| Stat `idle_regen_pct` | gameplay | Base `UnitType.idle_regen_pct`; `set_idle_regen_pct` stays for code that sets the base |
| Stats `support_amount`, `support_interval` | gameplay | Flat bonus on the `UnitType` values, read by `SupportCaster` |
| Stat `carry` | systems | `Worker` carries `10 + carry` |
| Statuses | gameplay | `blighted` (`healing_taken` 0.5; new key read by `heal()`, idle regen and `hp_regen`), `dread` (`attack_damage_pct` -0.10, `wizard_immune`), `feared` (no act, `move_speed` -1.0, `hero_mult` 0.5, then **4 s immunity**: new generic key `"immunity"`), `rebirth` / `stasis` (no move, no act, `damage_taken` 0.0; `stasis` uses the frozen look) |
| On-hit | gameplay | In `_on_attack_hit`: research burn (`apply_dot(&"burn", ...)`), `blighted`, frost gain, splash |
| Death hooks | gameplay | Flame Rites zone on `die()`; Ember Rebirth and Stasis through `death_guard` (soldiers only; wizards keep the item guards) |
| Heat / Frost | gameplay | Per-unit counters on the 0.5 s tick (3.1, 3.3) |
| Pulses | gameplay (Dread) / systems (Permafrost) | 1 Hz, one loop over the cached `"units"` list per team, never per frame |
| Tower / keep bonus | systems | `ResearchBank.tower_bonus(building) -> Dictionary` (`damage`, `range`, `on_hit_status`, `on_hit_duration`, `burn`, `splash_chill_radius`, `root`), read by `building_gun.gd` |
| Building HP | systems | Effective `max_hp` = type base x keep tier x GoldBank factor x **research factor** (`ResearchBank.building_hp_mult(building)`) |
| Train speed, pop, walls, nodes | systems | `train_speed_mult()` in `TrainingBuilding`; `Economy.pop_of_type(type)`; wall limit / build time; `CrystalNode` regrowth |
| Spells | gameplay | Splitting Flame, Everburning Kindle, Umbral Pact, Heart of Winter, Ysolde's Bloom in `spell_caster.gd`, each behind `ResearchBank.team_has(team, id)` |
| Fog | systems | Veiled Grave Hounds (Hushed Paws): visible to a team only within 5 m of its units / buildings |
| Treant (Heartroot) | gameplay | `TitanAbilities` (step 13) reads `ResearchBank.team_has(team, &"nature_heartroot")`: grove aura radius / stats, walking aura, Seedlings interval / max, own idle regen |

## 5. The titans (step 13, `cavalry-mounts.md` 5) and the Citadel
| Kingdom | Titan id | Lair (step 13) | Pop | Research that touches it |
|---|---|---|---|---|
| Fire | `cinder_dragon` | `fire_lair` Dragon Roost | 6 | Heat (its breath is its attack), Flame Rites r 2.5; never Ember Rebirth |
| Shadow | `nightmare_knight` | `shadow_lair` Dread Paddock | 4 | Catacombs **-1 pop (4 -> 3)**, Grave Carts, Dread pulse and Toll, Black-Iron Barding does **not** apply (Knights only) |
| Ice | `war_mammoth` | `ice_lair` Glacier Den | 6 | Carved Runes, frost gain 30 per tusk hit; **not** Avalanche Mauls (it has Trample) and **not** Stasis (titans never come back) |
| Nature | `elder_treant` | `nature_lair` Elder Circle | 6 | Growth rings, Oakheart Hide +150 HP, **Heartroot**; never Wild Shape |
- **The gate is the Lair, not the unit**: new `BuildingType.required_keep_tier: int = 0`; the four `*_lair.tres` get **3**. While
  research is on, `BuildGrid.check` refuses the Lair with `"Needs a Citadel"` (after `"Needs completed Stables"`) and the step-13
  `min_time` 8:00 gate is **ignored** (the Citadel comes later anyway); with research off, step 13's 8:00 rule stays. Titans
  themselves need nothing more. The Lair button stays visible in the build menu with its reason, so the goal is on screen early.
- Stables (step-13 tier 2) keep their rule (a completed Hall): cavalry is not gated by the Stronghold (knob 9.6 if cavalry
  rushes dominate).
- Before the first titan a side now pays Stables 175 + Lair 300 (step 13) + ~1 350 of research and keep tiers: first titans move
  from ~11:00-12:00 (step 13 alone) to **~13:00-14:30** (normal bot).
- Message on the Citadel: `Citadel complete: you can build a Dragon Roost` (the kingdom's Lair name).

## 6. How research fits the other systems
| System | Rule |
|---|---|
| **Bazaar wares** (`market-trade.md` 3.2) | No duplicate. Wares are **generic, gold-only, all soldiers** (Tempered Steel +8 % damage, Quilted Gambesons +10 armor, Masons' Charter +15 % building HP, Iron-shod Axles caravans). Research is **per kingdom and per unit role**, flat numbers, and adds on top: modifiers `ware:*` and `research:*` sum like any Stats sources; building HP factors multiply (Charter x1.15 x Ossuary x1.15 = x1.32). The fire tech is called *Quenched Blades* so nobody mixes it up with Tempered Steel |
| Gold | Tech tiers 2-3 are the big new gold sink (550 per kingdom) next to the 1 200 of wares: the "gold piles up" knob of `market-trade.md` 11.5 becomes rare. The exchange (100 gold -> 40 essence) can fund magic |
| Essence | Magic research competes with items and champions (~3 800 per 20 min): full magic is ~19 % of a game's essence. The map-fill essence wells (+0.4 / s) help |
| **Items** | Research never changes items; item passives that chill (Numbing Touch, Frostbite) feed the frost meter. Item caps (`ITEM_FLAT_CAPS`) count items only, as today |
| **Champions** | Not soldiers: no research modifier, no Heat, no rings. Their kills give souls; they suffer `blighted`, `dread`, `feared`, frost like any unit |
| **The wizard** | Only through the one tier-3 magic per kingdom (Splitting Flame, Umbral Pact, Heart of Winter, Ysolde's Bloom) and Kindle (Everburning). No stat research on wizards: the wizard grows by levels and items |
| Veterancy | Unchanged; Wild Shape and Ember Rebirth read it. Research modifiers add to `veterancy` like any source |
| Map fill (`map-fill.md`) | The Wayshrine blessing stacks with research; camp creatures give souls (+1 / +2) and can be frozen by frost; Seeding regrows the map's nodes only while an own keep / Hall stands within 20 m |
| Mounts (step 13) | Hero mounts are untouched by research |
| Fog | Research buildings follow the fog rules of any building (sight 10). Hushed Paws is the only fog change |

## 7. UI: what must be shown (layout, sizes and looks: ui-designer, `docs/design/ui-research.md`, task 14.D2)
| Element | Content | Interaction |
|---|---|---|
| **Keys** (physical) | **K** = research window (toggle; Esc closes). Research building selected: **Z X C V B N** = its 6 researches (tier 1, 1, 2, 2, 3, 3). Keep selected: **N** = upgrade to Stronghold / Citadel. Build menu: **J** = Forge, **L** = Sanctum | Checked against step 13 (`cavalry-mounts.md` 8): Tab = mount, build menu N / M = Stables / Lair, Stables Z X C, Lair Z, Treant V: **no clash** (N with a keep or research building selected is a building-card key, like Z X C). Taken besides: W A S D Q E F, X C H G B M Z V R Y T U, digits, F1-F3, F5-F7, F9-F11, Delete, Space, Esc, Tab. J, K, L print the same letters on AZERTY. **Watch**: 13's fallback mount key is N if the user refuses Tab; then the keep upgrade moves to **L** (keep selected) |
| Build menu | Forge **J** r3c1, Sanctum **L** r3c2 (tooltips 2.1); row 2 = Wall V, Bazaar B, Stables N, Lair M | |
| Research building card | 6 buttons: r1c1 Z, r1c2 X (tier 1), r1c3 C, r1c4 V (tier 2), r2c1 B, r2c2 N (tier 3); r2c4 **Research window K**. States: available / queued (number) / researching (progress ring) / done (check, disabled) / locked (padlock, reason). Tooltip: `White Heat  [C]\n75 crystals · 125 essence · 55 s · Magic, tier 2\nHeat can reach 5 (+15 % damage). At full Heat +0.5 speed.` + `\nNeeds a Stronghold` when disabled | Click = queue; Shift+click = nothing special |
| Research building panel | Name, HP; `Researching White Heat 62 % · 21 s`; queue of **3** slots (the training queue look) | Click a slot = cancel (full refund) |
| Keep card / panel | r1c4 **Upgrade to Stronghold N** (then **Citadel N**): `Stronghold  [N]\n200 crystals · 60 s\nKeep +20 % HP and +4 damage. Opens tier-2 research.` + first missing need; during the upgrade a chip `Stronghold 35 % · 39 s` in the panel (click = cancel); the panel title shows the tier (`Keep · Stronghold`) | |
| **Research window (K)** | One window for the kingdom: header crest + keep tier strip (Keep / Stronghold / Citadel, the current one lit, the next one with its needs and an Upgrade button); **two columns** Technology / Magic, 3 tier rows x 2 cards (icon, name, price, time, state); the building line under each column (`Ember Forge · researching Quenched Blades 12 s` / `Build an Ember Forge (B, J)`); the **mechanic box** (name, one-line rule, live value: `Heat: up to 3 (+9 %)` / `Souls 12 / 20` + the rite toggles / `Frostbite: on` / `Rings 3 / 8 · next 0:42`); the titan row (`Cinder Dragon · Dragon Roost needs a Citadel` / `Dragon Roost can be built` / `Dragon Roost built`) | Click a card = queue at its building (refusal = message + flash); right-click a queued card = cancel it; toggles switch rites; K / Esc close. Works from anywhere (no range rule: the building does the research) |
| Top bar | Shadow: `Souls 12 / 20` chip; Nature: `Rings 3 / 8` chip; only once the keystone is done; after the gold item | Hover = tooltip with the rule |
| Unit panel | Single Fire soldier: `Heat 4 / 5 (+12 % damage)`; status icons for `blighted`, `dread`, `feared`, `stasis`, `rebirth`, veiled (own Grave Hound) with tooltips | |
| Messages | `Research complete: White Heat` · `The Keep is now a Stronghold` · `Citadel complete: you can build a Dragon Roost` · `The enemy keep has become a Citadel` (if visible) · `Your Ember Forge was destroyed: Quenched Blades cancelled (75 % refunded)` · `Souls full (20)` (once per 60 s) | `show_message`, max one research line per 3 s (summed) |
| End screen | `Research 9 / 12 · Citadel at 11:42 · Souls harvested 64` (per side) | |
| Settings | Skirmish option **Research: On / Off** (default On) | Sets `Skirmish.research_enabled` before the scene enters the tree |
| Help text | Adds `K: research    J, L: Forge, Sanctum (build menu)    N (keep): upgrade` | |
| Audio (ui-coder) | Research start click; research complete chime per kingdom (4); keep tier-up horn; soul gain whisper (max 2 / s); rite cast (Raise, Toll); Frostbite shatter; ring gained (Nature) | SFX bus |

## 8. The bot (ai 14.A1: rule 14 of `ai.md`, knobs in `AIProfile` / `data/ai/*.tres`)
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `research_enabled` | true | true | true |
| `forge_time` / `sanctum_time` (earliest placement) | 8:00 / 9:00 | **4:30 / 5:30** | 3:30 / 4:15 |
| `stronghold_time` / `citadel_time` (earliest) | 12:00 / never | **7:00 / 11:00** | 6:00 / 9:30 |
| `research_max` (researches per game) | 3 (the first 3 of the order, tier 1 only) | 12 | 12 |
| `research_reserve` (crystals kept after a research / upgrade) | 150 | **100** | 75 |
| `research_min_ratio` (research only when `own_strength >= ratio x seen_strength`) | 1.0 | **0.8** | 0.7 |
| Order | Its kingdom's list, first 3 | Its kingdom's list (below) | Same list |
| Lair (step 13 row 9) | never (no Citadel) | `lair_time` gains "and a Citadel" | same |
| Rule | Trigger -> action (first that applies each tick; at most one research or upgrade purchase per **10 s**; builds share the 20 s rule) |
|---|---|
| 14a Buildings | Time >= `forge_time` (then `sanctum_time`), a completed Hall, crystals >= price + 100, no build waiting -> place at **R1** / **R2** (`(56, -46)` / `(40, -54)`, player-side bot the mirror); after 3 refusals `SLOT_SHIFTS`. Build row **8** of rule 4. A destroyed one is rebuilt after 60 s with crystals >= 250 |
| 14b Keep | Time >= the knob, needs met (2.2), crystals >= price + `research_reserve`, no defence running -> upgrade |
| 14c Research | Next entry of the order whose needs are met: buy when crystals / gold / essence >= price + reserve (crystals `research_reserve`; essence: +50, and only if the next item is > 150 essence away or the entry is a keystone). An entry blocked by gold alone is skipped (the next one is tried); by tier: wait |
| 14d Pressure | While rule 1 (defend) runs, or `own_strength < research_min_ratio x seen_strength`: **no crystal spending** on research or upgrades; gold-only and essence-only parts still allowed (queued items stay). This is the comeback path: the side behind keeps its army and still turns gold into tech |
| 14e Rites | Both Shadow rites on; never toggled |
| 14f Titan | Once the Citadel is done, step 13's Lair row 9 and titan mix apply unchanged (`cavalry-mounts.md` 9.1; the Treant roots by 9.2) |
| 14g Strength | `own_strength` x `(1 + ResearchBank.bot_value_total())` (sum of each done research's `bot_value`, table 9.2 shares); a seen enemy keep adds +8 % per tier above 1 to `seen_strength` (the only research the bot "sees") |
| Kingdom | Normal order (**S** = Stronghold, **C** = Citadel) | Notes |
|---|---|---|
| Fire | Quenched Blades, Kindled Blood, **S**, White Heat, Ember Mail, Great Bellows, Flame Rites, **C**, Ember Rebirth, Splitting Flame, Everburning, Salamander Oil, Blasting Powder, Firebrand Flasks | |
| Shadow | Bone Plating, Soul Harvest, **S**, Raise the Dead, Grave-Rot Bolts, Catacombs, **C**, Dread, Legion of Night, Ossuary Walls, Black-Iron Barding, Grave Carts, Hushed Paws, Umbral Pact | vs Nature (Nature units >= 50 % of seen soldier pop): Grave-Rot Bolts first |
| Ice | Hauler Sledges, Heavy Crossbows, Deep Winter, **S**, Hoarfrost Plate, Carved Runes, Avalanche Mauls, **C**, Permafrost, Stasis, Heart of Winter, Frost Bombards, Rimeward Seers, Packed-Ice Walls | hard: Packed-Ice Walls after Permafrost |
| Nature | Rings of the Old Wood, Barbed Burrs, **S**, Sap Frenzy, Seasoned Bark, Wild Shape, **C**, Heartroot (right after the first Elder Treant starts), Oakheart Hide, Seeding, Entangling Roots, Ysolde's Bloom, Thorned Bastions, Living Timber | Keystone first: rings are Nature's growth and start the clock; combat before sustain |
Each order reaches the Citadel's needs (2 tier-2 researches) right before **C**. Expected (normal): Forge 4:30-5:00, first
research ~5:15, keystone ~6:15, Stronghold 7:00-7:45, Citadel 11:00-12:30, Lair ~12:00-13:00, first titan ~13:00-14:30, all 12
around 17:00-19:00.

## 9. Balance
### 9.1 What research changes in a normal bot-vs-bot match (both sides research)
| Time | Research (typical, normal bot) | Crystals in research (cum.) | Effect |
|---|---|---|---|
| 0:00-4:30 | Nothing | 0 | Openings and the 3:30-4:30 first attack unchanged |
| 4:30-6:30 | Forge, 1 tech, Sanctum, keystone | ~350-400 | About 4 soldiers fewer at the first big fight |
| 6:30-8:00 | Stronghold, 2nd tier 1 | ~700 | Armies **~15-20 % smaller** at 7:00-9:00 on both sides; keeps 3 000 HP |
| 8:00-11:00 | 2-3 tier 2 (gold starts to matter) | ~950-1 050 | Mechanics online (Heat 5, Risen, freezes, rings) |
| 11:00-14:30 | Citadel (keep x1.4), Lair, first titan | ~1 350 (+ Lair 300) | Bases much harder to crack; the decisive late fight moves past 12:00 |
| 13:30-19:00 | Tier 3, the rest | ~1 850 | Defensive tier-3s (Salamander Oil, Packed-Ice Walls, Frost Bombards, Ossuary Walls, Thorned Bastions) |

### 9.2 Power curve per kingdom (normal order; army combat value EHP x DPS vs the same army without research; typical mix, 20 s fights; economy and spells listed apart)
| Time | Fire | Shadow | Ice | Nature | What drives it |
|---|---|---|---|---|---|
| 5:00 | 1.00 | 1.00 | 1.00 (Sledges running) | 1.00 | Nothing done yet |
| 8:00 | 1.12 | 1.10 | 1.15, **+17 % income** | 1.10 | Blades + Heat 3 / Plating + souls / Crossbows + Frostbite / Barbed Burrs + 1-2 rings |
| 12:00 | 1.22 | 1.22 | **1.30** | 1.24 | White Heat, Mail / Risen, Dread, Bolts / Plate, Runes, Mauls / Sap Frenzy, Wild Shape, Bark, 4 rings |
| 16:00 | 1.28 | 1.30 | **1.40** | 1.33 | Rebirth / Legion / **Stasis** / 7 rings, Oakheart; + Heartroot around each Treant (not in the number) |
| 20:00 | 1.32 | 1.35 | **1.45** | 1.38 | All; Nature's 8 rings |
| `bot_value` share | Blades .05, Mail .03, Kindled .06, White Heat .04, Rebirth .03, rest .02 | Plating .05, Harvest .03, Raise .06, Dread .05, Legion .03, rest .02 | Crossbows .05, Deep Winter .07, Plate .05, Runes .04, Mauls .05, Stasis .06, rest .02 | Burrs .05, Bark .04, Rings .02 per ring (live), Sap Frenzy .06, Wild Shape .04, Heartroot .05 per Treant alive, rest .02 | per research (14g) |
**Nature's base (4.5) is not in this table**: versus today's Nature it is about **-15-20 %** over a game (no free regrow between
fights) and **+10 %** in raw fights (Thornling 55 / 75 HP, Slinger 55 HP, Bramblehorn 420, Bloomtender 14). Net vs today:
~**-8 %** at 5:00-10:00 (it was the strongest: target "middle of the pack"), about even by ~13:00 (research), stronger than
today after ~16:00 (rings + Heartroot Treants).
Order of strength today (Results of balance-2, with Vessa casting): **Fire > Nature > Shadow > Ice**. Research gives the most to
Ice (+45 % at 20:00, the cheapest tier 1, an income tech), then Shadow; Nature gets combat research early (it has no regen left
to lean on) and its sustain back only around a tier-3 Treant, so its power moves **later** (weaker than today until ~13:00,
stronger after ~16:00). Fire gets the least early (+12 % at 8:00): research does not fix Fire's casting lead (that is
9.D4 / 10.D3), it only does not feed it.

### 9.3 The Nature / Ice fixes, one by one
| Problem (balance-2) | Research answer |
|---|---|
| D1 Nature out-sustains everyone (retreat, regrow, relaunch) | Q3 (user): **no idle regen on ordinary Nature units at all**; the retreat-and-regrow bot rule is off (4.5); regeneration returns only within 12 m of a rooted Elder Treant with Heartroot (Citadel + Lair + 600-crystal titan + 275 of research: ~14:00+), and the Treant is weak to fire and immobile while rooted (walk past it). Growth rings give HP / damage, never regen. Shadow's **Grave-Rot Bolts** (tier 1) halve in-fight healing (Bloomtenders, Wild Bloom, the grove aura); Ice's **Carved Runes** and **Avalanche Mauls** punish the Thornling swarm |
| Nature must not become the weakest | Base compensation (4.5: Thornling back to 55 and 75 HP = the best line CE, Slinger 55 HP, Bramblehorn 420, Bloomtender 14); combat research at tiers 1-2 (Barbed Burrs, Sap Frenzy, Wild Shape, Seasoned Bark); rings every 90 s from the keystone at ~6:00; fastest start and 4:30 expansion unchanged |
| Nature's win comes from fights, not economy | No Nature eco research before tier 2 (Seeding is a late-game node refill, not tempo) |
| Ice attacks 3 times per game and loses its army defending | Cheapest tier 1 (75 / 40), the Hauler income tech (+17 % per worker from ~5:30), Frostbite and Hoarfrost Plate raise combat value (CE) — the thing Ice lacked, not patience |
| Ice's best phase is late | Stasis and Frost Bombards at tier 3; its keep at the Citadel is the toughest (4 200) |
| Games too short (D7, 9.D4) | Keep tiers, defensive tier-3s, 15-20 % smaller mid-game armies, titans after ~13:00 (Lair behind the Citadel) |

### 9.4 Match length
- **Longer, by design**: (1) ~700 crystals (~20 % of the spend) go to research by 8:00: both mid-game armies are smaller, so the
  9-11 min stomps need ~2 more minutes of income; (2) keeps at x1.2 by ~7:30 and x1.4 by ~12:00 (+ Charter): 10 Flame Guards need
  **27 s** for a Citadel keep instead of 19 s (31 s with the Charter), under keep fire 20 / 1.5 s; (3) Permafrost, Living Timber,
  Entangling Roots, Thorned Bastions, Salamander Oil, Frost Bombards, Ossuary / Packed walls make every base defend itself;
  (4) the titan's Lair needs the Citadel (~1 350 crystals of research and keep tiers first, then Lair 300 and the titan
  400-700), so the "big army" moment moves from step 13's ~11:00-12:00 to ~13:00-14:30; (5) Nature (Q3) no longer relaunches
  at full HP 45 s after each lost fight, the main reason its games ended early.
- **Comeback**: 14d (the side behind stops crystal research but keeps its army, and still turns flat trade gold into tier-2 / 3
  tech); defensive research is worth more to the defender; souls and rings do not snowball from economy (souls cap 20 / 40; rings
  are time only).
- **Expected**: even pairs **+2:30 to +4:00** median length on top of steps 10-12. With trade (+0:45-2:00) and map fill, the
  bot-vs-bot median should land in **15:00-20:00**. Too long (> 22:00) -> knobs 9.6.

### 9.5 Fight checks (level 1, no items, wares off)
| Fight | Result |
|---|---|
| Flame Guard (Blades, Mail, Heat 5) vs Rimeshield (Plate, Carved Runes), 1 vs 1 | Value = EHP x raw DPS. Today: FG 130 x 12 = 1 560, RS 172.5 x 10 = 1 725 (**Ice +11 %** per unit, loses per crystal and to Fire's spells). Researched: FG 137.8 x 14.3 (avg Heat ~+10 %) = 1 971 (+26 %); RS 184.5 x (10 + reflect 1.2) = 2 066 (+20 %): **Ice +5 %**. The Ice line alone gains less than Fire's; Ice's lead comes from Frostbite, Crossbows, Mauls and Stasis (9.2) |
| 6 Shardcasters (Crossbows, Frostbite) vs a Blaze Rider | 64 frost / s: frozen at ~1.6 s, then ~1 s in every 3.4 s; with `chill` its effective DPS drops ~45 %. The rider's hit-and-run dies before the 2nd pass |
| 10 Thornlings (8 rings, Sap Frenzy, Wild Shape on 4) vs 10 Shades (Bone Plating, Dread, 6 souls) | Thornbeasts 103 HP (75 x 1.37), the others 84, attacks every 0.79 s; Shades armor 8 (x0.93); Dread -10 % Nature damage within 6 m of the Knight; 2 Risen join after 6 kills: about even at 18:00 (Nature wins it today 6 / 6) |
| Nature army after a fight, at 50 % HP | Today: back to ~95 % in 45 s for free. Now: stays at 50 % unless Bloomtenders (14 HP / 3 s each), Wild Bloom, a Bramble Spire (+2 HP / s within 8 m) or a rooted Treant (+4 HP / s; with Heartroot +4 and 1 % / s within 12 m: a Thornling from 50 % to full in ~14 s) heal it. The retreat still saves units (retreat_hp 0.4) but not their HP |
| Elder Treant (Heartroot, rooted) at the front vs a Fire army | Weak to fire x1.5 and immobile: Ash Hurlers (12 m) out-range its 11 m volley; the grove only matters if Nature fights **at** the Treant. This is the intended "one unit" sustain: strong, local, answerable |
| Raise the Dead value | 3 souls ~ 1 Risen: 80 HP x 9 DPS for 30 s ~ half a Shade's lifetime value; 6 Risen = a free 3-Shade wing per big fight |
| Stasis, 10 Rimeshields losing a fight | Each comes back at 25 % after 3 s (the enemy wastes 3 s of focus): about **+30 %** line EHP once per unit, from ~15:00 |
| Citadel keep (Fire, 3 500, attack 20 / 1.5 s) vs 10 Flame Guards (13 dmg) | 27 s to fall (31 s with the Charter); the keep kills ~2 guards meanwhile; a Stronghold (3 000) 23 s |
| Great Bellows | 15 % faster training = +1 soldier per ~2 min per Hall: tempo, not stats; helps the defender reinforce as much as the attacker |
| Seeding (3 own nodes within 20 m of a keep / Hall) | +72 crystals / min while the nodes last; ~+700 over a 10-minute late game: keeps Nature fighting after ~17:30 when naturals run dry |

### 9.6 Knobs (one at a time; 14.D3)
| Symptom | Knob |
|---|---|
| Nobody researches before 8:00 (playtest) | Tier-1 tech 100 -> **75**; Forge / Sanctum 125 -> **100** |
| Research players lose to all-in armies before 8:00 | Stronghold 200 -> **150**; tier-1 magic essence 60 -> **40** |
| Games > 22:00 or many without a winner | Citadel keep x1.4 -> **x1.3**; Salamander Oil / Frost Bombards / Thorned Bastions damage bonuses halved |
| Games still < 14:00 | Stronghold keep x1.2 -> **x1.3**, Citadel x1.4 -> **x1.5**; `citadel_time` normal 11:00 -> **12:00** |
| Nature still wins > 60 % | Rings every 90 s -> **110 s**; Heartroot idle regen +1.0 -> **+0.6**; Thornling `max_hp` 75 -> **70** |
| Nature loses most games (< 35 %) | Thornling `max_hp` 75 -> **80**; Barbed Burrs 100 -> **75**; Sap Frenzy Thornling -0.12 -> **-0.15**. Never give regen back to ordinary units (user decision) |
| Ice still wins < 35 % | Frost freeze at 100 -> **80**; Hoarfrost Plate armor +8 -> **+10** |
| Ice wins > 60 % | Carved Runes 10 % -> **7 %**; Stasis thaw 25 % -> **15 %** |
| Fire still wins > 65 % | Heat per stack 0.03 -> **0.025**; Quenched Blades Blaze Rider +2 -> **+1** |
| Cavalry (step 13 Stables) rushes decide games before 8:00 | Stables need a **Stronghold** (`required_keep_tier` 2 on `*_stables.tres`) |
| Souls pile up / never | Soul cap 20 -> **15** / Raise the Dead 3 -> **2** souls |
| Frost freezes feel oppressive | Freeze 1.0 -> **0.75 s**; decay 25 -> **35 / s** |

### 9.7 Re-test plan (lead 14.L2, then 14.D3)
Harness: the any-kingdom bot-vs-bot run (normal, cap 24:00) with a new **`--no-research`** flag as the control (trade on, map fill
on, as shipped).
| Round | Pairs (both orders) | Runs | Pass |
|---|---|---|---|
| A | all 6 non-mirror pairs | 12 with research + 6 `--no-research` | Median length with research **15:00-20:00** and >= control + 1:30; Nature wins <= 7 of its 12 runs (<= 60 %); Ice wins >= 4 of 12 (>= 35 %); Fire <= 8 of 12; at most 2 runs without a winner |
| B | same runs | - | Each side: Forge by 5:30, Stronghold by 8:30, Citadel by 13:30 in >= 70 % of runs reaching it; 1 200-2 000 crystals in research by 15:00; >= 1 titan trained in >= 50 % of runs reaching 15:00; Nature (with 4.5) wins 35-60 % of its runs; souls harvested 30-90 (Shadow); >= 3 Frostbite freezes per Ice game; 0 script errors |
| C | ice-ice, nature-nature | 1 each | Mirrors within 1.1x crystals at 10:00 |
| Perf | perf test + every research forced on for both teams (200 units, 20 Risen, 16 walls, all pulses) | 1 | `PERF OK`, stuck 0 |

## 10. Performance
| Item | Budget / rule |
|---|---|
| Heat, frost, veil timers | On the existing 0.5 s unit tick; a modifier is rewritten only when a stack changes. Frost is a float on the unit, touched only when > 0 |
| Pulses (Dread, Permafrost) | 1 Hz; one pass over the cached `"units"` group per team per second (the TradeNetwork `strength_near` style), squared distances, no physics queries. <= 20 Ice buildings, <= 12 Knights |
| Rites | Driven by `Events.unit_died` (event, not polling) + the Dread Toll 1 Hz check |
| Heartroot | Reuses step 13's grove aura tick (every 0.25 s like any aura); only bigger radius / extra stat |
| Seeding | `CrystalNode` 0.2 Hz timer, only nodes below their start amount and with an own building in range (cached on building events) |
| Zones | Flame Rites: <= 8 zones per team, pooled `SpellZone`s; Risen <= 6 / 10 per team |
| VFX | Heat glow = one shader parameter per unit; full-Heat embers, blessing-like marks and frost creep in shared MultiMeshes (<= 80 instances each); pulse rings are one mesh per building, hidden beyond 60 m from the camera |
| Totals | New logic **< 0.15 ms / frame** average with 200 units, all research on (perf row of 9.7) |

## 11. Art, VFX and icons (tech-artists, one agent per line; global style `art-keep.md` section 0: chunky, hand-painted, readable at 40 m, 2-4 glow points)
| Id | Asset | Silhouette (40 m black test) and look | Budget / hooks |
|---|---|---|---|
| 14.V1 | **Ember Forge** (Fire) | Dominant: a squat brick forge with a **tall bellows-fed chimney** glowing at the mouth; secondary: an anvil yard with a quench trough (steam puffs) | 2 x 2 (4 x 4 m), ~5.5 m to the chimney top; 1 light max, shadows off; states of `art-keep.md` 8 (construction, damage, destroyed); `set_researching(bool)` (bellows pump, chimney brighter), `play_research_done()` (spark fountain) |
| 14.V2 | **Bone Foundry** (Shadow) | A workshop framed by a **giant ribcage**, a bone crane holding a cart wheel; violet furnace glow | Same |
| 14.V3 | **Rime Forge** (Ice) | Stone workshop with a **frozen waterwheel** on one side (dominant) and a crossbow rack; blue forge light | Same |
| 14.V4 | **Root Nursery** (Nature) | A **greenhouse dome of woven living branches** with glow-fruit, seedling beds outside | Same |
| 14.V5 | **Cinder Sanctum** (Fire) | Ring of 6 basalt pillars around a **floating brazier flame** shaped like a rising bird | 2 x 2, ~6 m; same hooks (the flame flares while researching) |
| 14.V6 | **Soul Crypt** (Shadow) | Sunken mausoleum with an open stair and a **tall obelisk circled by soul wisps** | Same; wisps speed up while researching |
| 14.V7 | **Rune Sanctum** (Ice) | Circle of **carved rune monoliths** around a floating ice rune disk (slow spin) | Same |
| 14.V8 | **Wildroot Sanctum** (Nature) | Ring of **ancient standing stumps** with a glowing sapling in the centre, growth rings drawn on the ground | Same; the sapling grows a size per ring (`set_rings(n)`) |
| 14.V9-14.V12 | **Keep tiers** (one agent per kingdom: Fire, Shadow, Ice, Nature) | Stronghold add-on: an outer wall ring / banners and one raised element; Citadel add-on: a taller crown element and one more glow point (Fire: a flame crown on the keep's top; Shadow: a second spire and chain bridges; Ice: a second crystal crown; Nature: a wider canopy with a second ring of lanterns) | <= 8 extra meshes per tier, no new light; `set_tier(tier: int)` (1-3), `play_tier_up()` (scaffold-free: a 1.5 s burst in the kingdom glow). Edits the existing keep scenes |
| 14.V13 | **Risen** (Shadow summon) | Lanky skeleton in rusted armour scraps, a notched sword, violet eye glow | Soldier budget (<= 18 meshes, <= 10 draw instances, 0 lights); `play_rise()` (claws out of the ground 1.0 s), attack, `play_death` (crumbles into bones), lifetime flicker in the last 3 s |
| 14.V14 | **Fire research VFX** | `heat` (shader param on the unit kit: ember cracks 0-1), full-Heat ember sparks (MultiMesh), `flame_rites` ground (the Ember Step scorch, 2.0-2.5 m), `ember_rebirth` (ash collapse, then a flame pillar and rise), `split_embers` (3 arcs + small bursts) | `ResearchVfx.play(id, at, target)` |
| 14.V15 | **Shadow research VFX** | `soul_wisp` (victim -> killer, 0.6 s), `raise_dead` (grave crack under the Risen), `dread_pulse` (thin violet ring r 6, subtle), `feared` mark (dark swirl over the head), `blighted` mark (green-black drips), `veil` (own view: alpha 0.35 + shimmer), `umbral_pact` (smoke dome r 6) | Same |
| 14.V16 | **Ice research VFX** | `frost` creep (shader param, the viewer's only), `frostbite` freeze burst + short ice block, `permafrost_pulse` (ground frost ring r 8 / 3, 1 Hz, very subtle), `stasis` (ice coffin, then thaw shatter), `reflect` spark, `avalanche_cleave` (snow arc), `bombard_splash` | Same |
| 14.V17 | **Nature research VFX** | `ring_gained` (concentric ring + leaf burst at the Heartwood), `heartroot` (the Treant's grove aura ring grows 8 -> 12 m + one green sparkle per unit regenerating in it, MultiMesh; extends step 13's grove pulse, 13.V19), `wild_shape` (bark burst, the model scales x1.1-1.2 and darkens), `root_on_hit` (reuse `rooted`), `seeding` (sprout motes on a regrowing node) | Same |
| 14.V18 | **Shared research VFX** + `research_vfx.gd` | `research_done` pulse in the kingdom glow on the building, `tier_up` column on the keep, `queue_started` glint | `art/vfx/research_vfx.gd` (`class_name ResearchVfx`, group `"research_vfx"`) |
| 14.V19-14.V22 | **Icons** per kingdom (one agent each) | 12 research icons + the mechanic icon (Heat / Souls / Frostbite / Rings) + Forge + Sanctum = **15** each | The existing icon renderer and size |
| 14.V23 | **Shared icons** | Stronghold, Citadel, tier pips I / II / III, padlock, research-window crest, Souls chip, Rings chip, Heat pip, frost pip, status icons `blighted`, `dread`, `feared`, `stasis`, `rebirth`, veiled | Same |
Paths: `res://art/buildings/research/<kingdom>/forge_<kingdom>.tscn`, `sanctum_<kingdom>.tscn`; `res://art/units/shadow/risen/risen.tscn`;
`res://art/vfx/research_*`; icons `art/icons/research_*`.

## 12. Campaign
- `Skirmish.research_enabled` (exported, like `trade_enabled`): true in the skirmish, **false in missions 1-4**.
- Proposed first use: **mission 5**, tier 1 + Stronghold only (Citadel and titans off through a mission knob
  `max_keep_tier := 2`). Research is not carried between missions.

## 13. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 14.L1)
Rule for phase-1 agents (as steps 9-10): never use another step-14 agent's new `class_name` as a static type; reach it with `load()`
guarded by `ResourceLoader.exists`, groups, `has_method()`, `get()`.
- **ResearchType** (`scripts/research/research_type.gd`, `class_name ResearchType extends Resource`, `data/research/<id>.tres`, 48
  files): `id`, `display_name`, `faction`, `track` (`&"tech"` / `&"magic"`), `tier` (1-3), `slot` (0-5 = keys Z X C V B N),
  `keystone: bool`, `crystals`, `gold`, `essence`, `research_time`, `text` (tooltip effect line), `icon_path`,
  `unit_mods: Array[Dictionary]` (`{"units": [ids]}` or `{"filter": &"soldiers" | &"workers"}` + `"stats": {...}`),
  `bot_value: float`; `static find(id)`, `static for_faction(faction) -> Array[ResearchType]` (track, tier, slot order).
- **ResearchBank** (`scripts/research/research_bank.gd`, `class_name ResearchBank extends Node`, one per team, group
  `"research_banks"`, created by the Skirmish when `research_enabled`): `static for_team(team) -> ResearchBank` (null when off),
  `static team_has(team: int, id: StringName) -> bool` (O(1), false when off), `static research_active() -> bool`, `team`,
  `faction`, `researched: Array[StringName]` (read only), `is_researched(id)`, `keep_tier() -> int`, `price(id) -> Dictionary`
  (`{crystals, gold, essence}`, gold folded into crystals without a GoldBank), `can_research(id) -> String` (2.3 order),
  `queue_research(id) -> String` (finds the building), `research_building(track) -> Node`, `in_progress(track) -> StringName`,
  `apply_research(unit: Node)` (idempotent, modifiers `research:<id>`; `Unit._ready` calls it through the group like wares, and
  the bank catches new units itself at the frame end), `building_requirement(type: BuildingType) -> String` (the Lair's
  `"Needs a Citadel"`), `train_speed_mult() -> float`,
  `pop_of_type(type: UnitType) -> int`, `building_hp_mult(building: Node) -> float`, `tower_bonus(building: Node) -> Dictionary`,
  `wall_limit_bonus() -> int`, `heat_cap() -> int`, `heat_decay_time() -> float`, `frost_mult() -> float`,
  `souls: int`, `souls_cap() -> int`, `add_souls(n: int)`, `spend_souls(n: int) -> bool`, `rite_enabled(id) -> bool`,
  `set_rite_enabled(id, on: bool)`, `rings: int`, `ring_time_left() -> float`, `bot_value_total() -> float`; signals
  `research_queued(id)`, `research_completed(id)`, `research_cancelled(id, refund: Dictionary)`, `souls_changed(souls: int)`,
  `rings_changed(rings: int)`, `tier_changed(tier: int)`. The ring timer lives here.
- **ResearchBuilding** (`scripts/buildings/research_building.gd`, `class_name ResearchBuilding extends Building`, kinds `&"forge"` /
  `&"sanctum"`, group `"research_buildings"`): `track: StringName`, `research_types() -> Array[ResearchType]` (slot order),
  `queue: Array[ResearchType]` (read only, max `MAX_QUEUE := 3`), `research_progress() -> float`, `time_left() -> float`,
  `can_queue_research(type) -> String`, `queue_research(type) -> String`, `cancel(slot: int)`, signals `queue_changed`,
  `research_done(building, type)`, `static of_team(team: int, track: StringName) -> ResearchBuilding` (completed, alive, or null).
  Model hooks `set_researching(bool)`, `play_research_done()` if present.
- **Keep** (tiers): `tier: int` (1-3), `tier_name() -> String`, `can_upgrade() -> String` (`"Already a Citadel"`, `"Upgrade in
  progress"`, the missing need, `"Not enough crystals"`), `upgrade() -> String`, `cancel_upgrade()`, `is_upgrading() -> bool`,
  `upgrade_progress() -> float`, `upgrade_time_left() -> float`, signal `tier_changed(keep, tier: int)`; model hooks `set_tier`,
  `play_tier_up`. HP and attack per 2.2.
- **BuildingType / BuildGrid / Building**: `ALL_IDS` gains the 8 ids (before each kingdom's market); kinds `&"forge"`, `&"sanctum"`;
  limit messages `"Only one Forge"` / `"Only one Sanctum"`; `Building.set_research_hp_mult(mult: float)` (heals the gain), effective
  `max_hp` = base x keep tier x GoldBank factor x research factor; `BuildingType.required_keep_tier := 0` (the 4 Lairs: 3;
  `BuildGrid.check` message `"Needs a Citadel"` after `"Needs completed Stables"`, and the Lair's `min_time` is skipped while
  research is on);
  walls read `ResearchBank.wall_limit_bonus()` and build time 6 s with Packed-Ice Walls.
- **TrainingBuilding**: progress x `ResearchBank.train_speed_mult()`; pop checks use `Economy.pop_of_type(type)`.
- **Economy**: `pop_of_type(type: UnitType) -> int` and `pop_of(unit)`; Catacombs re-counts living Knights (and Nightmare
  Knights) at once.
- **TitanAbilities** (step 13): reads `ResearchBank.team_has(team, &"nature_heartroot")` for the Treant's grove aura (radius 12,
  `idle_regen_pct` +1.0, walking r 6 at half), Seedlings (10 s, max 4) and its own idle regen 2.5.
- **Unit / UnitType** (gameplay): new stats `attack_range`, `building_damage_bonus`,
  `splash_ratio`, `splash_radius`, `reflect_melee`, `idle_regen_pct`, `support_amount`, `support_interval`, `carry`; statuses
  `blighted`, `dread`, `feared` (+ generic `"immunity"` key), `rebirth`, `stasis`; `heat: int` (read only), `frost: float` (read
  only), `add_frost(amount: float, source_team: int)`; `Unit._ready` calls `apply_research(self)` on the team's ResearchBank
  (group lookup, like wares); model hooks `set_heat(ratio)`, `set_frost(ratio)`, `set_wild_shape(bool)` if present. New
  `data/units/risen.tres` (faction `&"shadow"`, `lifetime` 30, pop 0, `kill_xp` 0).
- **SoulRites** (`scripts/units/soul_rites.gd`, `class_name SoulRites extends Node`, one per Shadow team with Souls on, child of
  its ResearchBank): Raise the Dead, Dread pulse, Dread Toll, Risen spawning and cap; signal `risen_raised(unit)`, `toll_rung(knight)`.
- **Skirmish**: `@export var research_enabled := true` (missions false), creates the two ResearchBanks, `research_slot(team,
  track) -> Vector3` (R1 / R2), clearings, end-screen line. **FogOfWar**: veiled units (Hushed Paws) visible to a team only within
  5 m of its units / buildings. **CrystalNode**: `regrow(amount)` capped at `start_amount`.
- **SelectionManager / keys**: K = research window; research building selected: Z X C V B N; keep selected: N = upgrade; build
  menu J / L (r3c1 / r3c2; row 2 keeps step 13's N / M). **Keys line** (lead): add `K = research window`, `build menu B then
  J / L = Forge / Sanctum`, `research building selected: Z X C V B N = researches`, `keep selected: N = Stronghold / Citadel`.
  No clash with step 13 (Tab mount, build N / M, Stables Z X C, Lair Z, Treant V); if Tab is refused and N becomes the mount
  key, the keep upgrade moves to L.
- **VFX**: `art/vfx/research_vfx.gd` (`class_name ResearchVfx`, group `"research_vfx"`, `play(id, at, target)`); ids in section 11.
- **Ownership**: `scripts/research/`, `data/research/` = systems-coder; `scripts/units/soul_rites.gd`, `data/units/risen.tres` =
  gameplay-coder; `art/buildings/research/`, `art/units/shadow/risen/`, `art/vfx/research_*`, `art/icons/research_*` =
  tech-artists; `scripts/ui/research_window.gd` = ui-coder. No `Events` change (the bank's signals are enough).

## 14. What changes in other specs
- `buildings.md`: build menu J / L at r3c1 / r3c2, the 8 buildings, keep tiers. `economy.md`: `pop_of_type`, worker `carry`.
- `levels.md`: victim rows Forge / Sanctum 60; Risen 0.
- `ai.md`: rule 14, build row 10 (R1 / R2; step 13 took rows 8-9), strength 14g, pressure 14d.
- `kingdom-nature.md` / `balance-2.md`: **Q3** — the "Verdant" passive is now "buildings and Ysolde regenerate; soldiers and
  workers do not"; the numbers of 4.5; the Nature bot's retreat / regrow rule off.
- `kingdom-ice.md`: wall limit and HP with Packed-Ice Walls. `spells.md`: the four wizard hooks + Kindle.
- `market-trade.md`: section 6 of this file (no duplicate wares; research as a gold sink). `cavalry-mounts.md`:
  the Lairs need a Citadel while research is on (replaces the 8:00 gate), Stagrunner `idle_regen_pct` 0, the Heartroot
  parameters of the Treant, research effects of section 5, bot row 9 + "a Citadel". `map-fill.md`: creatures give souls.
- `ui-hud.md` / `ui-trade.md` / `ui-mapfill.md`: top-bar chips, keys, help text (14.D2 merges). `CLAUDE.md` (lead): section 13.

## 15. Task list (step 14; build after steps 10-13 are merged)
**Phase 0:** 14.L1 lead, 14.D2 ui-designer. **Phase 1a (in parallel, no shared files):** 14.C1, 14.C2, 14.C3, 14.G1, 14.G2,
14.G3, 14.V1-14.V13. **Phase 1b (as slots free):** 14.C4 (needs 14.D2), 14.V14-14.V18. **Phase 2:** 14.A1, 14.C5, 14.C6,
14.V19-14.V23, then 14.L2, then 14.D3 after the playtest. Phase-1 tests stub the other parts in their own
`tests/test_14_<id>.gd`.
**Shared files with steps 10-13 (still in flight today):** `unit.gd` (10.C6, 11, 13), `building.gd` (10.C11), `keep.gd`,
`training_building.gd` (13: cavalry training), `economy.gd`, `worker.gd` (10.C3), `crystal_node.gd`, `skirmish.gd` (10.C1, 12.C1-C3,
13), `fog_of_war.gd` (12), `commander.gd` / `ai_profile.gd` / `data/ai/*.tres` (10.A3, 11.A1, 12.A1, 13), `command_card.gd`,
`selection_manager.gd`, `selection_panel.gd`, `top_bar.gd`, `hud.gd` (10.C7 / C8, 11.C4, 12.C6 / C7, 13), `spell_caster.gd` and the
keep scenes (13 mounts / art), `titan_abilities.gd` and the four `*_lair.tres` (13). Step 14 starts only when those step tasks
are merged. Keys checked against step 13 (section 7): no clash. **Exception: 14.B1 / 14.B2 (the Nature Q3 patch) can ship
right away** as a balance patch, before step 14, and should be re-measured on their own (balance-2 harness, rounds A-C).
| Id | Agent | Task | Files |
|---|---|---|---|
| 14.B1 | gameplay-coder | Nature Q3 data (4.5): `idle_regen_pct` 0 on thornling, burr_slinger, bloomtender, sprigling, sapling, bramblehorn (and stagrunner once step 13 exists); Thornling cost 55 / HP 75, Burr Slinger HP 55, Bramblehorn HP 420, Bloomtender heal 14; Treant and Ysolde unchanged | `data/units/thornling.tres`, `burr_slinger.tres`, `bloomtender.tres`, `sprigling.tres`, `sapling.tres`, `bramblehorn.tres` (`stagrunner.tres`) |
| 14.B2 | ai-coder | Nature bot: `retreat_hp` 0.4, regrow / 85 % relaunch rule off, same values in the `nature()` fallback | `data/ai/nature_*.tres`, `scripts/ai/ai_profile.gd`, `commander.gd` (the regrow branch) |
| 14.L1 | lead | Freeze section 13 in `CLAUDE.md`, the Keys line (K, keep N, build J / L, research Z-N), owner rows; step 14 ids in `waves.md`; `step14-agent-rules.md`; the Q1-Q4 answers | `CLAUDE.md`, `docs/plan/` |
| 14.D2 | ui-designer | `ui-research.md`: layouts at 1600 x 900 for everything in section 7 (research window, building card / panel, keep upgrade chip, top-bar chips next to gold and the map-fill objectives strip, status icons), consistent with `ui-style.md`, `ui-trade.md`, `ui-mapfill.md` | `docs/design/ui-research.md` |
| 14.C1 | systems-coder-high [H] | ResearchType + 48 `.tres` (numbers of section 4), ResearchBank (prices + no-trade fold, requirements, reasons, apply_research on units, building HP factor, tower bonus table, train speed, pop, souls counter + Soul Harvest heal, rings timer + modifiers, rite toggles, bot values) | `scripts/research/research_type.gd`, `research_bank.gd`, `data/research/*.tres` |
| 14.C2 | systems-coder-high [H] | ResearchBuilding + 8 BuildingType `.tres`; keep tiers (upgrade, HP, attack, cancel, messages); Building research HP factor; tower / keep bonuses in the gun (damage, range, burn, splash chill, root); Permafrost pulse; Living Timber; Thorned Bastions hall attack; walls (limit, HP, time); TrainingBuilding speed + `pop_of_type`; `BuildingType.required_keep_tier` + the Lair's `"Needs a Citadel"` (min_time skipped while research is on) | `scripts/buildings/research_building.gd` (new), `building.gd`, `keep.gd`, `tower.gd`, `building_gun.gd`, `building_type.gd`, `build_grid.gd`, `training_building.gd`, `data/buildings/*_forge.tres`, `*_sanctum.tres`, `*_lair.tres` (one field) |
| 14.C3 | systems-coder | Economy `pop_of_type` (Catacombs), worker `carry`, CrystalNode regrowth (Seeding), Skirmish `research_enabled` + banks + R1 / R2 slots and clearings + end-screen line, FogOfWar veil rule | `scripts/economy/economy.gd`, `worker.gd`, `crystal_node.gd`, `scripts/world/skirmish.gd`, `fog_of_war.gd` |
| 14.G1 | gameplay-coder-high [H] | Unit: the new stats (4.6), statuses, on-hit burn / blight / frost / splash / cleave, reflect, `healing_taken`, Heat, frost meter + freeze, Flame Rites zone, Ember Rebirth + Stasis guards, Wild Shape, veiled flag + auto-target skip, `apply_research` call, model hooks, SupportCaster stats, Frost / Heat lines on the HP bar | `scripts/units/unit.gd`, `support_caster.gd`, `unit_type.gd` |
| 14.G2 | gameplay-coder | SoulRites (Raise the Dead, Dread pulse, Dread Toll, Risen spawn / cap / Legion), `risen.tres`; Heartroot in the Treant's `TitanAbilities` (aura radius / idle regen / walking aura, Seedlings 10 s max 4, own regen 2.5) | `scripts/units/soul_rites.gd` (new), `data/units/risen.tres`, `scripts/units/titan_abilities.gd` |
| 14.G3 | gameplay-coder | Wizard hooks: Splitting Flame, Everburning Kindle, Umbral Pact, Heart of Winter, Ysolde's Bloom | `scripts/spells/spell_caster.gd`, `spell_zone.gd` |
| 14.C4 | ui-coder | Research window (K), research building card / panel / queue, keep upgrade button N + chip, build menu J / L (row 3), top-bar Souls / Rings chips, unit-panel Heat line + status icons, messages, help text, end screen, settings toggle, audio | `scripts/ui/research_window.gd` (new), `command_card.gd`, `selection_manager.gd`, `selection_panel.gd`, `top_bar.gd`, `hud.gd`, `scripts/ui/menus/game_settings.gd`, `assets/audio/research_*` |
| 14.V1-14.V4 | tech-artist (one each) | Ember Forge, Bone Foundry, Rime Forge, Root Nursery | `art/buildings/research/<kingdom>/forge_*` |
| 14.V5-14.V8 | tech-artist (one each) | Cinder Sanctum, Soul Crypt, Rune Sanctum, Wildroot Sanctum | `art/buildings/research/<kingdom>/sanctum_*` |
| 14.V9-14.V12 | tech-artist (one each) | Keep tier add-ons Fire / Shadow / Ice / Nature | the kingdom's keep scene folder |
| 14.V13 | tech-artist | Risen | `art/units/shadow/risen/` |
| 14.V14-14.V17 | tech-artist (VFX, one each) | Fire / Shadow / Ice / Nature research VFX | `art/vfx/research_fire_*`, `_shadow_*`, `_ice_*`, `_nature_*` |
| 14.V18 | tech-artist (VFX) | Shared VFX + `research_vfx.gd` | `art/vfx/research_vfx.gd`, `art/vfx/research_shared_*` |
| 14.A1 | ai-coder | Rule 14 (section 8), knobs, orders, R1 / R2, strength 14g, pressure 14d, rites on; Heat / Frost-aware casts not needed | `scripts/ai/ai_research.gd` (new), `commander.gd`, `ai_profile.gd`, `data/ai/*.tres` |
| 14.C5 | systems-coder | Plug the 8 building models and keep tiers (`model_path`, hooks, `ResearchVfx` calls) | `data/buildings/*_forge|sanctum.tres`, `scripts/buildings/research_building.gd`, `keep.gd` |
| 14.C6 | gameplay-coder | Plug Risen's model, unit hooks (`set_heat`, `set_frost`, `set_wild_shape`), `ResearchVfx` calls from units / spells | `data/units/risen.tres`, `scripts/units/` (hooks only), `scripts/spells/` (VFX calls) |
| 14.V19-14.V22 | tech-artist (one each) | Icons Fire / Shadow / Ice / Nature (15 each) | `art/icons/research_<kingdom>_*` (new files only) |
| 14.V23 | tech-artist | Shared icons | `art/icons/research_shared_*` |
| 14.L2 | lead | Glue (ResearchVfx node in both scenes, handoffs), `--no-research` harness flag, perf test "all research on", runs of 9.7, CI, playtest copy | `tests/`, `scenes/`, `docs/plan/` |
| 14.D3 | game-designer | Balance check from the 14.L2 logs and the playtest; knobs of 9.6 | `docs/design/research.md` |

## Done when
- [ ] 14.B1 / 14.B2: a Thornling at 20 HP regains nothing in 60 s without damage; Thornling 55 crystals / 75 HP, Slinger 55, Bramblehorn 420, Bloomtender heals 14; an Elder Treant still regenerates 1.5 % / s; a Grove Hall still regenerates 1 % / s; the Nature bot retreats at 40 % and relaunches by rule 7 only; balance-2 rounds A-C re-run: Nature wins 35-60 % of its non-mirror runs.
- [ ] 14.L1: section 13 is in `CLAUDE.md`; the Keys line has K, N (keep), build J / L, research Z X C V B N; owner rows for every new folder and file; ids in `waves.md`.
- [ ] 14.D2: `ui-research.md` gives positions / sizes / looks at 1600 x 900 for every element of section 7, with no overlap with the gold item, the map-fill objectives strip or the trade window.
- [ ] 14.C1: 48 `.tres` with the numbers of section 4 (test reads each price / time / tier / slot); `can_research` refuses in the 2.3 order (no building, no Stronghold, wrong tier in the track, queue full, each resource); with no GoldBank a tier-2 tech costs 200 crystals; a Flame Guard spawned after Quenched Blades has 13 damage and a living one too; Soul Harvest: a Shade kill gives +1 soul and heals the killer 12; souls stop at 20 (40 with Legion); rings +1 per 90 s up to 8, a Thornling at 4 rings has `max_hp_pct` +0.06; `pop_of_type(shadow_knight)` 3 -> 2 and `nightmare_knight` 4 -> 3 with Catacombs.
- [ ] 14.C2: Forge / Sanctum placeable with a Hall only, one each (`"Only one Forge"`); one research at a time, queue 3, full refund on cancel, 75 % for the one in progress when the building dies; Stronghold needs a research building + 1 research, 200 crystals, 60 s, Fire keep 2 500 -> 3 000 HP (healed) and 16 damage; Citadel needs both buildings + 2 tier-2 researches, 3 500 HP, 20 damage; Great Bellows makes an 18 s Flame Guard take 15.7 s; Permafrost chills a Shade 7 m from a Frost Hall within 1 s and not one at 9 m; Salamander Oil Spires burn 4 / s; Packed-Ice Walls: a 17th wall is placeable, the 25th refused, walls 800 HP; with research on a Dragon Roost is refused `"Needs a Citadel"` at 9:00 with a Stronghold and accepted with a Citadel at any time; with research off step 13's 8:00 rule holds; `PERF OK`.
- [ ] 14.C3: a Hauler with Sledges carries 11; a node at 1 000 / 2 000 with an own Nature keep within 20 m and Seeding regrows +24 in 60 s and stops at 2 000; a veiled Grave Hound 6 m from an enemy unit is not visible to that team and is at 4 m; `research_enabled = false` creates no bank and the build menu has no J / L; R1 / R2 are clear and pass `BuildGrid.check` on both sides; smoke test `victory=true`.
- [ ] 14.G1: Heat: a Flame Guard in combat has 1 Heat after 2.5 s, 3 after 7.5 s (cap 3), 5 with White Heat, loses 1 per s out of combat (per 3 s with Everburning); frost: 7 Shardcaster hits (15 each) freeze a Shade for 1.0 s, Malrik 0.5 s, frost stays <= 90 during the 2 s immunity and decays 25 / s after 1.5 s; `blighted` halves `heal(40)` to 20; Stasis: a Rimeshield taking lethal damage is encased 3 s taking 0, thaws at 25 % once, dies the second time; Ember Rebirth the same with 2 s / 40 %; Carved Runes: a Flame Guard hitting a Rimeshield for 10 after armor takes 1; Avalanche Mauls: 40 % to a unit 1.5 m from the target, none at 2.5 m; Shardcaster range 10.5 after Heavy Crossbows; Wild Shape: a Thornling reaching Veteran gets +25 % HP and scale 1.2; `PERF OK`.
- [ ] 14.G2: with Raise the Dead and 3 souls an enemy Shade dying 8 m from a Shade raises one Risen (80 HP, 30 s, 0 XP / essence / souls when killed), none at 12 m, never a 7th alive (11th with Legion); Dread gives -10 % damage to enemies within 6 m of a Knight, never to a wizard; Dread Toll fears 4 enemies for 1.5 s for 5 souls, not again from that Knight for 20 s; toggles off stop both rites. Heartroot: a rooted Treant gives own soldiers within 12 m `hp_regen` +4 and idle regen 1 % / s, walking within 6 m half of that; Seedlings every 10 s, max 4; a Thornling 13 m away gets nothing.
- [ ] 14.G3: Splitting Flame: a rank-1 Fireball lands 3 embers of 21 at 2.5 m; Everburning: Kindle gives +3 Heat; Umbral Pact shrouds soldiers within 6 m for 3 s and Shadow Lance heals 75 %; Heart of Winter: Flash Freeze radius +0.5, Rime Bolt 67.5 on a frozen target at rank 1; Ysolde's Bloom: +10 armor during Wild Bloom and 4 Saplings.
- [ ] 14.C4: K opens / closes the window from anywhere and it shows the 12 cards, tier strip, mechanic box and titan row with the right states; a research building's Z-N queue its researches with the tooltips of section 7; keep N upgrades; build menu J / L (step 13's N / M untouched); chips and messages as written; nothing in `scripts/ui/` calls a `_private` function.
- [ ] 14.A1: headless normal run per kingdom: Forge placed at R1 by 5:00, keystone by 7:00, Stronghold by 8:30, Citadel by 13:30 (if the game lasts), orders followed; no crystal research while defending or below 0.8 x seen strength; `PERF OK`.
- [ ] 14.V1-14.V23: every building, keep tier, Risen, VFX family and icon of section 11 exists at its path with its hooks; silhouette sheet names the 8 research buildings and the 3 keep tiers of each kingdom; `PERF OK` with all research VFX on.
- [ ] 14.L2 / 14.D3: section 9.7 rounds A-C pass (or 14.D3 lists the knobs applied and the re-run).

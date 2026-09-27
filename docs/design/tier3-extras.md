# Tier-3 extras: gunpowder infantry, the Mage Archer, Nature's riders and shell

Task 13b.D1, written 2026-09-26. Source of truth for step 13b (tasks in section 17). User request (`waves.md` "Step 13b"):
**Fire** gets alchemy **musketeers** (black-powder volleys, short range, big explosive damage, slow reload, smoke) and **Ice**
gets **frost-rune riflemen** (long range, freezing / slowing shots, slow and fragile up close): men with guns, **tier 3**
(the Citadel, `research.md` 2.2), not heroes, **no cap**, clearly distinct from each other. To balance, **Shadow** gets a
**Mage Archer**: really strong, a **unique NPC** (one per team), **autonomous** like a champion but fully allied. **Nature**
gets **two units**: **horse archers** (fast, hit-and-run) and a **strong slow unit**, each with clear pros and cons. Numbers
are knobs, tuned after the tests (13b.D3); each unit must be unique.
Builds on `cavalry-mounts.md` ("cm.": titans, Lairs, Stables, damage kinds, flying, anti-mount, MountModel kit),
`research.md` ("rs.": Stronghold / Citadel, Frostbite meter, Q3 Nature regen only on the Elder Treant), `rush-balance.md`
("rb.": the 10 step-16 units, `UnitAbilities`, 6 training slots, `required_keep_tier`, `unit_mix`, duel harness),
`champions.md` ("ch."), `champion-skill-tree.md` ("st.": the unique-NPC XP curve, class trees, picker), `levels.md`,
`items.md`, `kingdom-ice.md` 9 (CE / PE formulas). Every name, unit, number and rule here is our own. Metres, seconds,
`m:ss` since the navmesh was ready.

## 0. Decisions of the user (answered 2026-09-26)
| # | Question | User's answer (what this spec now says) |
|---|---|---|
| Q1 | **Where are the tier-3 units trained?** | **Split by role, yes**, always behind the **Citadel** (`required_keep_tier` 3): **Cinderlock Musketeers** at the **Ember Hall, slot N** (the mass unit: every Hall trains them); **Glade Outriders** at the **Grove Stables, slot B** (cavalry); **Mossback** at the **Elder Circle (Nature Lair), slot X**; the **Mage Archer** is *called* at the **Dread Paddock (Shadow Lair), slot X**. **Frostrune Riflemen**: at the **Frost Hall, slot N** (was the Glacier Den X: Q3 frees the Frostbow's Hall slot, so the rifle takes it, as the Cinderlock takes the Ember Hall's N) |
| Q2 | **The Mage Archer arrives late (Citadel ~11:00-13:00) but must feel "really strong"** | **Yes as recommended**: she arrives **level 3** (3 picks resolved at once), **drill 2 XP / s** (champions 1): **level 9 about 10 min after the call**. Base stats about **2x a champion** (560 HP, 23 DPS at range 11) and 3 own abilities. **300 crystals + 150 essence**, pop 4, no upkeep, revived at the Dread Paddock |
| Q3 | **Frostbow (step 16, T2) vs Frostrune Rifleman (T3)** | User: *"change the bow, but try to reuse what's already been made"*. **The Frostbow is dropped as a separate unit** (it was never built: no code, data or art exist). The **Frostrune Rifleman takes over its slot and role family** (Frost Hall N, long-range anti-cavalry *and* anti-big, 5.3). Ice keeps a **tier-2 answer to fast units** by moving the already-specified **Hamstring Shot** ability onto the **Shardcaster** from the Stronghold (a step-16 change, section 16a). Art and code **reuse**: the Rifleman is built on the existing **Shardcaster** scene / rig with a rifle prop (12); its shots reuse the projectile, `chill`, `frozen` and Frostbite code and looks |

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Tier | All five are **tier 3**: `required_keep_tier` **3** (the Citadel); research off -> an own completed **Lair** (`"Requires a Lair"`); titans off (missions) -> hidden | One ladder: the Citadel opens the kingdom's late game (titan + these) |
| Cap | **No cap** on Cinderlocks, Riflemen, Outriders, Mossbacks (cost, pop, train time and counters limit them). **Mage Archer: 1 per team** (alive, fallen or being called) | User decision |
| Roles (one identity each) | Fire **Cinderlock Musketeer**: short-range burst line, massed volleys, explosive splash, breaches buildings, slow reload, smoke. Ice **Frostrune Rifleman**: longest range in the game, armor-piercing freezing shots, +50 % vs mounted (it inherits the dropped Frostbow's anti-cavalry job), planted, fragile. Shadow **Mage Archer**: unique autonomous hero-sniper that levels. Nature **Glade Outrider**: horse archer that shoots on the move and kites on its own. Nature **Mossback**: slowest, toughest body with a canopy that blunts enemy shots on its friends | "Clearly distinct from each other"; each answers one of the others |
| One ability each | Cinderlock **Powder Volley** · Rifleman **Rime Lock** · Outrider **Parting Shots** · Mossback **Canopy** · Mage Archer **Sable Shaft, Grave Mark, Eclipse Volley** (it is a hero: 3 own abilities + the Wizard class tree, section 6) | User: "one ability each" for troops; the unique NPC grows like a champion |
| Guns in the damage model | Musket and rifle hits are kind **`ranged`** (projectile): x2 on flyers (cm. 3.3), reduced by the Mossback's Canopy and powder smoke. Cinderlock hits count as **fire** (Fire source: x1.5 on the War Mammoth and the Elder Treant) | No new damage kind |
| Mage Archer and champions | A **Champion** with `unique_npc` (reuses `Champion`, `ChampionBrain`, bounty flags, levels, inventory, purse, revive); **not** in the 3-champion roster, **not** hired at a tavern, no upkeep, no dismiss, fixed class **Wizard** | "Reuse the champion brain / bounty-flag steering"; the least new code |
| Nature regen (rs. Q3) | Neither Nature unit regenerates (`idle_regen_pct` 0). The Mossback **protects**, it does not heal | The Elder Treant stays the one regenerating unit |
| Missions | Off (tier-3 content follows `Skirmish.titans_enabled`; all five are `expansion` units) | Missions 1-4 unchanged |

## 2. Where they come from (systems)
| Unit | Building, slot (key) | Gate (first refusal that applies) | Queue |
|---|---|---|---|
| Cinderlock Musketeer | **Ember Hall r2c2, N** (the 6th Hall slot of rb. 5) | `"Needs a Citadel"` (research on) / `"Requires a Lair"` (research off) | the Hall's queue of 5 |
| Frostrune Rifleman | **Frost Hall r2c2, N** (the slot step 16 gave the dropped Frostbow) | `"Needs a Citadel"` / `"Requires a Lair"` | the Hall's queue of 5 |
| Glade Outrider | **Grove Stables r2c1, B** (after Z Stagrunner, X mount, C barding, V Bore Beetle) | `"Needs a Citadel"` / `"Requires a Lair"` | the Stables queue |
| Mossback | **Elder Circle r1c2, X** | as the Rifleman | the Lair queue (shared with the Treant) |
| Mage Archer | **Dread Paddock r1c2, X** "Call the Mage Archer" (then "Revive") | Lair gate, then `"Already called"` (alive, fallen or queued), `"Population cap reached"`, `"Not enough crystals"`, `"Not enough essence"` | the Lair queue (a stub `UnitType`, 15) |
- `required_keep_tier` 3 on the five types (rb. 13 field). Without a ResearchBank (`--no-research`) a tier-3 type needs an own
  completed Lair (`"Requires a Lair"`), which itself keeps step 13's `min_time` 8:00. With `titans_enabled` false the five
  are hidden like `expansion` types in missions.
- Keys (physical): Ember Hall and Frost Hall **N**, Elder Circle / Dread Paddock **X**, Grove Stables **B** (all training-slot
  keys of rb. 13 / cm. 8). No new building key. The Glacier Den keeps only its titan (Z).
- Tooltips: `Cinderlock Musketeer  [N]\nCost 130 crystals · Pop 1 · 26 s · Tier 3\nBlack-powder volleys at short range. Slow reload.` ·
  `Frostrune Rifleman  [N]\nCost 175 crystals · Pop 2 · 36 s · Tier 3\nLongest range. Its shots freeze and stop riders. Fragile up close.` ·
  `Glade Outrider  [B]\nCost 175 crystals · Pop 2 · 30 s · Tier 3\nHorse archer. Shoots on the move and keeps its distance.` ·
  `Mossback  [X]\nCost 340 crystals · Pop 4 · 60 s · Tier 3\nSlow living wall. Friends near it take less damage from shots.` ·
  `Call the Mage Archer  [X]\n300 crystals · 150 essence · Pop 4 · 45 s\nA unique hero who fights on her own. One at a time.`
- Kill XP = cost / 2 rounded to 5 (`levels.md`): Cinderlock 65, Rifleman 90, Outrider 90, Mossback 170. The Mage Archer is
  a champion victim with her own numbers (6.3).

## 3. Shared rules for the new units (gameplay)
| Rule | Value |
|---|---|
| **Bracing** (`attack_setup_time`) | After the unit stops moving it needs `attack_setup_time` s before its first shot (a braced state, shown on the model and panel); any move cancels it. Rifleman **1.0 s**. Auto-target and attack orders still pick targets; the first shot simply waits |
| **Fire on the move** (`fire_while_moving`, `moving_cooldown_mult`) | The unit keeps its attack timer while walking and shoots targets in range without stopping; cooldown x `moving_cooldown_mult` while moving. Outrider **x1.4** |
| **Auto-kite** (`kite_range`, `kite_distance`) | Not on Hold, not on a plain move order: when an enemy **melee** unit (attack range <= 3.0, cavalry included) that targets it is within `kite_range`, it moves `kite_distance` straight away from it (navmesh-clamped) and resumes its order; at most once per **2.5 s**. Outrider 4.0 / 5.0 |
| **Armor pierce** (`armor_pierce`) | Its attacks ignore that fraction of the target's positive armor (the cm. 3.2 **Lance** rule generalised: mounted attacks use `max(0.5, armor_pierce)`). Rifleman **0.5** |
| **Rune frost** (`frost_on_hit`) | Each hit adds that much to the target's Frostbite meter (rs. 3.3) **even without Deep Winter** (ungated source); Heart of Winter's x1.5 still applies; freeze and immunity per rs. 3.3. Rifleman **34** (3 hits = 102 = frozen 1.0 s; heroes and titans 0.5 s) |
| **Damage taken by kind** (statuses) | New status key `taken_by_kind` (kind -> multiplier, applied with the cm. 3.1 multipliers, before armor): status **`powder_smoke`** `{ranged: 0.75}`, status **`canopy`** `{ranged: 0.7, tower: 0.7}`. Refreshed every 0.5 s by their source; they never stack with themselves; with each other they multiply (0.525) |
| Veterancy, research | The four troops level 1-4 like soldiers and take the generic wares; research that names unit ids does not include them (rb. 5.1 rule); growth rings apply to the Nature ones; Heat applies to Cinderlocks (Fire soldiers). The Mage Archer follows the champion rules (no research modifiers; Soul Harvest's heal on her kills does apply: it is Shadow's own) |
| Crowd control | Normal (soldier) except the Mossback: `hero_mult` (half duration) and immune to knockback, trample and `taunted` (the titan list without the titan tag) |

## 4. Fire: Cinderlock Musketeer (`cinderlock`)
### 4.1 Stats
| HP | Armor | Dmg | Range | Cooldown (reload) | DPS | Speed | Aggro | Sight | Radius | Height | Cost | Pop | Train | kill_xp |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 120 | 5 | **40** | **6.5** | **4.2** | 9.5 (11.9 in a volley) | 4.6 | 9 | 10 | 0.45 | 1.7 | 130 | 1 | 26 | 65 |
Fields: `base_stats {splash_ratio: 0.35, splash_radius: 1.5}` (black powder: other enemy units within 1.5 m of the target take
35 %), `building_damage_mult` **1.5** (breaching charges), bullet speed 40 m/s, `abilities [&"powder_volley"]`, tags none,
colour (secondary cloth) `(0.70, 0.45, 0.20)`.
### 4.2 Powder Volley (`powder_volley`, passive + autocast; `UnitAbilities`)
| Part | Rule |
|---|---|
| Hold for the volley | A loaded Cinderlock with a target in range waits up to **0.5 s** ("Present!") while other own loaded Cinderlocks within **8 m** also have targets; all fire at the end of the wait, or at once when **5** are ready |
| Massed fire | When **>= 3** Cinderlocks fire within the same 0.25 s window, each of those shots deals **+25 %** to units (not buildings) and knocks the target back **0.6 m** (never titans, flyers, buildings); a mounted non-titan target is also `dazed` **0.3 s** (a volley breaks a charge: cm. 3.2 denial) |
| Powder smoke | Each volley (or a lone shot) leaves a cloud at the shooters' centre: r **2.5** + 0.3 per shooter (max 4.0), **3 s**; own units inside get `powder_smoke` (enemy ranged hits x0.75). Max **6** clouds per team (the oldest ends first). Clouds block nothing (no fog change) |
| Bark | `"Volley!"` over one shooter, max once per 10 s per team (visible units only) |
### 4.3 Role, pros, cons, counters
| Beats | Loses to | Why |
|---|---|---|
| Clumped lines at close range, charging cavalry (volley daze), buildings (x1.5), War Mammoth and Elder Treant (fire x1.5), a Mage Archer that wanders within 6.5 m | Anything that out-ranges it (archers 9, riflemen 15, towers 10-12, Mage Archer 11), line infantry that reaches it during the 4.2 s reload, Outriders (never catches them), the Mossback's Canopy (-30 % on its shots at everything behind it) | Burst then vulnerable: the reload window is its weakness |
Distinct from the **Pyre Adept** (T2 caster, range 8, small splash on every hit, Flame Burst on swarms): the Cinderlock is a
massed **alpha-strike line** (40 per shot, volleys, knockback, breaching) with the worst sustained DPS window of any ranged unit.

## 5. Ice: Frostrune Rifleman (`frostrune_rifleman`)
### 5.1 Stats
| HP | Armor | Dmg | Range | Min range | Cooldown | DPS | Speed | Aggro | Sight | Radius | Height | Cost | Pop | Train | kill_xp |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **100** | 5 | **52** | **15.0** | **4.0** | 3.2 | 16.3 | **3.6** | 15 | **12** | 0.45 | 1.8 | 175 | 2 | 36 | 90 |
Fields: `min_attack_range` 4 (rb. 13), `attack_setup_time` **1.0**, `armor_pierce` **0.5**, `on_hit_status` `chill` **2.0 s**,
`frost_on_hit` **34**, **`bonus_vs_mounted` 0.5** (78 per hit on a rider; taken over from the Frostbow), `building_damage_mult`
**0.25** (a rune slug barely scratches stone: riflemen out-range every tower but cannot siege), bullet speed 50 m/s (the
existing `Projectile`, Shardcaster bolt colour `(0.75, 0.92, 1.00)`), `abilities [&"rime_lock"]`, colour `(0.55, 0.80, 0.95)`.
Its `chill` 2 s on every hit already **denies a charge for 6 s** (cm. 3.2): the rifle line is also Ice's late anti-cavalry.
- **Sight 12 < range 15**: it shoots at 15 m only at enemies its team sees (fog rule; spotters, towers, Wayfinder flares, the
  Sparkwing). Alone it fights at 12.
- The Ice speed line (`kingdom-ice.md` 1): 3.6, the slowest Ice soldier after the Colossus.
### 5.2 Rime Lock (`rime_lock`, autocast)
Cooldown **20 s**, braced only. Picks the highest-value enemy in range (titan > wizard > champion or Mage Archer > mounted or
fast (`move_speed` >= 6.0) > highest cost), **aims 1.2 s** (a thin blue sight line from the rifle to the target, visible to **both** teams; the rifleman
keeps no other attack meanwhile), then fires: **x2 damage (104), ignores all armor**, adds **100 frost** (an instant freeze,
1.0 s; heroes and titans 0.5 s; freeze immunity per rs. 3.3 still applies). The aim cancels (cooldown 5 s) if the target
leaves range or vision, or the rifleman moves or is `dazed` / `frozen`.
### 5.3 The Frostbow is dropped: who answers fast units now (user Q3, "change the bow, reuse what exists")
The step-16 **Frostbow** (`frostbow`, T2, Frost Hall N) is removed from the roster before it was ever built. Its jobs move to
units and code that exist or are specified already:
| Frostbow job | Now done by | Reused |
|---|---|---|
| The Frost Hall slot **N** | **Frostrune Rifleman** (tier 3) | Hall 6-slot layout, `train_ids` entry (rb. 13) |
| Anti-cavalry damage (+50 % vs mounted) | **Frostrune Rifleman** `bonus_vs_mounted` 0.5 | cm. 14 field |
| Charge denial on fast targets (`hamstring_shot`: `chill` 3 s every 12 s) | **Shardcaster**, from the **Stronghold** (tier 2): the same ability id, numbers, icon and VFX on the existing T1 ranged unit (16a). Before the Stronghold: Shardcaster `chill` 1.5 s on hit, Rimelings, the Rime Spire, the Rimehorn Rider | `UnitAbilities.hamstring_shot` (16.C1), `ability_params` gate, the Shardcaster scene |
| Long-range anti-flyer | Shardcasters (range 9, x2 on flyers) at tier 2; Riflemen (15, x2) at tier 3; the Mammoth's howdah | cm. 3.3 |
| Late anti-cavalry line | Riflemen (78 per hit on riders, `chill` denies charges) behind Rimeshields (anti-mount +50 %) | |
Result: Ice has an anti-fast answer at every tier (T1 chill, T2 Hamstring Shardcasters, T3 Riflemen), one fewer model to
build, and no near-duplicate long-range shooter.
### 5.4 Role, pros, cons, counters
| Beats | Loses to |
|---|---|
| Titans (freeze locks the Dragon in the air, pierces the Mammoth's and Knight's armor), heroes and champions (Rime Lock), cavalry at range (78 per hit + charge denied), heavies, the Mossback (pierce), slow pushes into an Ice line, Cinderlocks walking in from 15 m (2-3 volleys before they fire) | Dives that arrive (min range 4, 100 HP, slow): Outriders kiting at 9 m, Hounds, a charge it did not see in time; flyers that close the gap; fighting without spotters (sight 12); buildings (x0.25); fog |

## 6. Shadow: the Mage Archer (unique autonomous NPC)
### 6.1 Identity
**Veyra Nightquill / Vesper Nightquill, *the Mage Archer*** (names A / B as the champion sibling rule: the first Shadow team to
call one gets A; only visible with a Shadow mirror). A hooded sorceress-archer of the Shadow court with a tall dark recurve bow
whose string is a violet thread of magic. She is **the Shadow kingdom's own champion**: she answers the Citadel's call, fights
with the army by her own judgement and cannot be ordered (`is_commandable()` false). Personality line: `Chooses her own
targets. Usually the ones you hoped for.`
### 6.2 Stats (level 1 base; she arrives at level 3: x1.04)
| HP | Armor | Dmg | Range | Cooldown | DPS | Speed | Aggro | Sight | Radius | Height | Flee under | Growth | Projectile |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **560** | 10 | **28** | **11.0** | 1.2 | 23.3 | 5.2 | 13 | 14 | 0.5 | 2.0 | **30 %** | 2 % / level | violet `(0.70, 0.30, 1.00)`, 32 m/s |
Kind `ranged` (her arrows hit flyers x2; `hero_mult` for crowd control, as champions). Compare: a level-1 Wayfinder 260 HP /
11.8 DPS; a Nightmare Knight 650 HP / 23.3 DPS.
### 6.3 Call, death, revive
| Rule | Value |
|---|---|
| Call | Dread Paddock slot **X**: **300 crystals + 150 essence**, **45 s** in the Lair queue, pop **4** (counted from the queue on, while alive and while fallen). She steps out of the Lair door with **150 XP (level 3)**, her 3 skill points spent at once (st. 6.1), full HP, **purse 100** |
| Unique | One per team: a second call is refused `"Already called"` while she is queued, alive or fallen. Not in the champion roster (the tavern's max 3, prices and pop are unchanged) |
| Upkeep | **None** (a kingdom unit, not a mercenary); never `Unpaid` |
| Dismiss | Not possible |
| Death | As a champion (ch. 3.3): intent `Fallen`, drops 30 % of her purse to the killer, items and levels kept. Victim XP **200 + 15 x level** (L3 245, L9 335) |
| Revive | Lair X becomes **Revive**: **150 + 15 x level essence** (L3 195, L9 285), back after **25 + 3 x level s** (L9 52 s) at the **Dread Paddock door**; the keep's spawn point if the Lair is gone. Also from her champion-bar slot. Refusals `"Not fallen"`, `"No home"`, `"Not enough essence"` |
| Lair lost | A living or fallen Mage Archer is kept; the first call needs a Lair |
| Warnings | Call start (enemy): `The enemy is calling a Mage Archer!` (own: `The Mage Archer answers the call`), ready: `Veyra Nightquill takes the field!`, death: `Veyra Nightquill has fallen` (both). Through `Events.titan_event(team, &"mage_archer", what)` (warnings only: no minimap diamond, she is not a titan) |
### 6.4 Levels and skills (the unique-NPC curve of st. 2.1)
- Levels **1-9** on `Champion.LEVEL_TOTAL_XP`; **drill 2 XP / s** (`ChampionType.drill_xp_per_second`; champions 1.0);
  other sources as champions. From 150 XP with ~175 XP / min: **level 6 ~3:30, level 9 ~10:00 after the call**.
- **Class: Wizard, fixed** (`class_weights {wizard: 1}`), its 9-skill tree (st. 5.4: Arc Bolt, Focus, Ward, Slipstep, Kindled
  Staff, Starfall, Gravity Well, Comet Rain / Astral Form) picked by the normal rule (st. 6) with her taste row: burst 1.4,
  area 1.1, control 1.2, guard 0.6, sustain 0.9, mobility 1.3, hunt **1.6**, support 0.6. Kindled Staff and Astral Form work on
  her arrows (they are her "bolts"). Her model keeps the bow (`weapon_override &"mage_bow"`).
- `power()` = **260 + 25 x level + 10 x ranks + items / 5** (L3 ~365, L9 ~575); champions' base is 170 + 20 x level.
### 6.5 Her own abilities (archetype row: `ChampionType.ability_ids`, unlock L1 / L1 / L6; amounts x `(1 + 0.02 x (level - 1))`, spell power applies)
| id | Name | Unlock | Cooldown | Range | Effect | Autocast when |
|---|---|---|---|---|---|---|
| `sable_shaft` | Sable Shaft | L1 | 12 | 16 | A shadow arrow in a 16 m line, 1 m wide: **55** to the first enemy unit, **60 %** to up to 2 more behind it (kind `spell`); can hit a flyer as its first target | The best target in range (enemy wizard < 50 % HP, champion, titan, then highest cost), or a line with 3+ enemy units |
| `grave_mark` | Grave Mark | L1 | 16 | 14 | `marked` **6 s** (x1.15 damage from every source) on one enemy; if it dies while marked, Sable Shaft is ready at once and she heals **40** | Its current target is a wizard, champion, titan, a unit of cost >= 150, or her Hunt bounty target |
| `eclipse_volley` | Eclipse Volley | **L6** | 50 | 14 (point), r 4 | A ring shown to both teams, then **3 waves** over 1.5 s: **22** each to enemy ground units inside (66) + `withered` **3 s** (rb. 5.2 status); buildings 25 %; never the flying Dragon (ground area) | 4+ enemy units within 4 m of a point in range, or 3+ with an enemy hero or champion among them |
Autocast order: her three first, then the tree (st. 7.1 order); the 1.0 s global cooldown and the team signature spacing apply.
### 6.6 Brain (ai: `ChampionBrain` with her `ChampionType`; rules R1-R9 of ch. 8.1 unchanged except as listed)
| Part | Rule |
|---|---|
| Traits | Greed **0.9**, Courage **1.3**, engage radius **13**; affinity Hunt **1.6** (x **1.3** on wizards, champions, titans: "trophy hunter"), Explore 0.3, Guard 1.0, Escort **1.4** (x1.2 on the own wizard) |
| R2 Flee / rest | Under 30 % HP; rest spots add the own **Lair** (home rest 2 % / s within 15 m) |
| R4 Fight | Target preference in range: enemy wizard under 50 % HP > champion / Mage Archer > titan > mounted > ranged > nearest. **Keeps her distance**: a melee enemy within 3 m -> step 4 m straight away (brain move, max once per 2 s; Slipstep, if learned, fires first) |
| R6 Bounties | Takes flags like a champion (utility of ch. 8.2 with her traits); payments go to her purse; bounty XP = half the payment |
| R7 Shopping | Wish list `Whetted Fang, Ember Draught, Ember Shard, Blazing Edge, Wisp Lantern, Ironbark Plate, Nightveil Cloak` (fits 4 slots; 20 % tithe to the bank) |
| R8 Default "**Overwatch**" | Follow the largest own soldier group (the Mender's centre rule, ch. 8.3) and stay **8 m** behind it on the side away from the nearest seen enemy. Fewer than 4 soldiers in the group: **Watch home**: stand between the keep and the Lair and fight intruders within 20 m. Intent text `Overwatch` / `Watching home` |
| Mount | Buys a Roan Courser at level 7 like a champion (cm. 6.3, st. 2.2) |
| Fog | Only her team's fog (ch. 8.4) |
### 6.7 Role, pros, cons, counters
| Beats | Loses to |
|---|---|
| Heroes and champions (marks, piercing shafts, levels), casters and ranged units in the open, cavalry that runs in a line (Sable Shaft), Treant Saplings and swarms (Eclipse Volley), flyers (ranged x2) | Being hunted: enemy Hunt bounties, champions built to hunt (Giant Slayer, Hunter's Oath), cavalry dives (5.2 m/s), Frostrune Riflemen (15 m out-range her 11, Rime Lock), a Cinderlock volley if she drifts within 6.5 m, Flash Freeze / Fireball, towers (her brain avoids them). She is **one** body the player cannot place: baited, she dies |

## 7. Nature: Glade Outrider and Mossback
### 7.1 Stats
| id | Name | HP | Armor | Dmg | Range | Cooldown | DPS | Speed | Aggro | Sight | Radius (coll.) | Height | Cost | Pop | Train | kill_xp | Tags / fields |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `glade_outrider` | Glade Outrider | 190 | 5 | 15 | 9.0 | 1.1 | 13.6 (9.7 moving) | **7.6** | 10 | 12 | 0.6 | 2.2 | 175 | 2 | 30 | 90 | `mounted`; `fire_while_moving` true, `moving_cooldown_mult` 1.4, `kite_range` 4.0, `kite_distance` 5.0; no charge (`charge_bonus` 0); `abilities [&"parting_shots"]`; arrow `(0.75, 1.00, 0.40)` |
| `mossback` | Mossback | **900** | **20** | 32 | 2.2 | 2.0 | 16.0 | **2.8** | 9 | 10 | 1.0 (0.8) | 2.6 | 340 | 4 | 60 | 170 | melee (cannot hit flyers); CC `hero_mult`, knockback / trample / taunt immune; `abilities [&"canopy"]` |
Both `idle_regen_pct` 0 (rs. Q3), `expansion` true, colours: Outrider cloth `(0.40, 0.70, 0.30)` on the Grove Stag, Mossback
shell `(0.30, 0.42, 0.20)` / skin `(0.45, 0.40, 0.30)`.
### 7.2 Abilities
| id | Unit | Rule |
|---|---|---|
| `parting_shots` | Glade Outrider | Passive: **fire on the move** (section 3, cooldown x1.4 while moving) and **auto-kite** (section 3: melee within 4 m -> 5 m away, every 2.5 s at most). The only unit that fights while retreating: the player orders the run, the Outrider keeps shooting |
| `canopy` | Mossback | Aura r **6**, refreshed every 0.5 s: own units (not other Mossbacks, not buildings) get status `canopy`: **ranged and tower hits x0.7** (spells, melee, DoTs unchanged). One Canopy per unit (no stacking). While active the shell's leaf canopy spreads (model hook); a faint ring r 6 when the Mossback is selected |
### 7.3 Pros and cons (the user's "clear ups and downs")
| | Glade Outrider (fast) | Mossback (strong, slow) |
|---|---|---|
| **Pros** | Fastest ranged unit (7.6); shoots while running; kites melee and slow armies on its own; raids workers and caravans; picks off Riflemen and Cinderlocks by staying outside 6.5 m / closing under 4 m; hits flyers | Toughest non-titan body (1 080 EHP), CC half, cannot be pushed; **Canopy** cuts gun, arrow and tower damage on everything around it by 30 % (Nature's answer to the gunmen); anchors a push under towers |
| **Cons** | 190 HP; `mounted`: line infantry, Vinelashers and Spear champions +50 %, Riflemen +50 %, Hamstring Shardcasters; weak vs armor (15 per arrow); 2 pop for 13.6 DPS; cannot hold ground; loses to other cavalry (it cannot out-run the Stagrunner or the Knight) | Slowest unit in the game (2.8); low DPS for 340 crystals; **cannot hit flyers**; kited by anything; armor pierce (Riflemen, Lance) halves its armor; 4 pop; big (blocks 2 m wall gaps and its own army in chokepoints); cannot reach a raid in time |
| Counters | Cavalry, Hamstring Shardcasters, Riflemen that see it coming, line infantry in a choke, towers, Rime Lock | Riflemen, cavalry (Lance), flyers, walking past it, Hexweaver's `withered`, spells |

## 8. The numbers side by side (level 1; CE / PE of `kingdom-ice.md` 9: CE = EHP x DPS / cost² x 100, PE = EHP x DPS / pop² / 100)
| Unit | EHP | DPS | Cost | Pop | CE | PE | Speed | Special value not in the numbers |
|---|---|---|---|---|---|---|---|---|
| Cinderlock | 126 | 9.5 (11.9 volley; ~+35 % splash on lines) | 130 | 1 | 7.1 (8.9) | 12.0 (15.0) | 4.6 | Breaching x1.5, charge-breaking volleys, smoke vs ranged |
| Frostrune Rifleman | 105 | 16.3 (+9 % vs armor 20; 24.4 vs mounted) | 175 | 2 | 5.6 (8.4 vs mounted) | 4.3 (6.4) | 3.6 | Range 15 (2-3 free volleys), freeze every 3rd hit, charge denial, Rime Lock |
| Glade Outrider | 200 | 13.6 (9.7 moving) | 175 | 2 | 8.9 | 6.8 | 7.6 | Never caught by infantry; kites |
| Mossback | 1 080 | 16.0 | 340 | 4 | 15.0 | 10.8 | 2.8 | Canopy: allies' EHP vs ranged x1.43 |
| Mage Archer (arrives L3) | 640 | 24.3 (+~8 abilities) | 300 + 150 e | 4 | ~10 | ~12.8 | 5.2 | Levels to 9 (value ~x2 by then, st. 10.1), picks targets |
| References | Flame Guard 19.3 / 15.6 · Ember Archer 5.3 / 5.3 · Pyre Adept 3.0 / 5.0 · Shardcaster 4.5 / 5.4 · Bramblehorn 15.8 · cavalry ~13 / ~11 · titans ~15 vs prey / 8-10 vs counter, PE 11-18 | | | | | | | |
Tier-3 troops sit **below line infantry per crystal** and at or above their kingdom's T2 units **per pop**: strong at the pop
cap (where late games are), never a better buy than a line early. Each carries one special that decides the right fight.

## 9. How the four kingdoms' late armies compare (Citadel on: titan + 13b)
| Kingdom | Titan (Lair Z) | 13b | Late identity | Wins by | Weak to | Its answer to the others' 13b |
|---|---|---|---|---|---|---|
| **Fire** | Cinder Dragon (flyer) | **Cinderlock Musketeers**, massed, no cap, from every Hall | **Shock and fire**: close in behind Flame Guards, delete the front rank with volleys, breach buildings, burn titans from above | Burst on clumps and charges; fire x1.5 on the Mammoth / Treant; breaching; the Dragon where there is no anti-air | Range: riflemen, archers, towers and the Mage Archer all out-range 6.5; the reload window; Canopy | Riflemen: close fast under smoke, behind a Guard wall · Mage Archer: out-numbered, one volley at 6.5 m · Outriders: cannot catch them (Blaze Riders / the Dragon do) · Mossback: walk past it; the Dragon ignores it |
| **Shadow** | Nightmare Knight (charging heavy cavalry) | **Mage Archer**, unique, levels | **The elite few**: Knights crash the back line while one untouchable-looking sniper-mage hunts heroes | Picking off wizards, champions, casters; lifesteal sustain (Knights); levels make her better every minute | Numbers (one Archer can be hunted and baited); anti-mount lines vs Knights; riflemen out-range her | Cinderlocks: Knights charge them in the reload window, the Archer shoots from 11 · Riflemen: Knights / Hounds dive (min range 4) · Outriders: Sable Shaft lines, Grave Hounds · Mossback: Hexweaver's wither, walk past |
| **Ice** | War Mammoth (siege, frost aura) | **Frostrune Riflemen**, from every Frost Hall (the Frostbow's slot) | **The frozen wall**: walls, Rimeshields and Seers in front, riflemen 15 m behind freezing whatever comes, the Mammoth grinding buildings | Locking titans and heroes, winning any fight the enemy must walk into | Dives (fragile, min range 4, slow), fog (sight 12), sieging with guns (x0.25) | Cinderlocks: 2-3 volleys before they fire · Mage Archer: out-ranged + Rime Lock · Outriders: Hamstring Shardcasters and Rimehorn Riders (riflemen only if spotted early: min range 4) · Mossback: armor pierce |
| **Nature** | Elder Treant (roots, heals) | **Glade Outriders** + **Mossback** | **Grow and roam**: Outriders bleed slow armies and raid, the Mossback shields the Burr Slingers and the rooted Treant from shots | Kiting Ice and Mossback-escorted pushes; attrition near a rooted Treant; growth rings | Area spells and cavalry on the Outriders; flyers and piercing on the Mossback; being pinned (Frostbite, Vinelasher-like roots) | Cinderlocks: Canopy -30 %, Outriders stay at 9 m · Riflemen: Outriders dive under 4 m · Mage Archer: Outriders + Vinelashers hunt her · (Mossback vs everyone's guns) |
Every kingdom has an answer to every 13b unit from its own roster, and each 13b unit has a hard counter in at least two other
kingdoms.

## 10. The bot (ai; extends cm. 9 and rb. 7; knobs in `AIProfile` / `data/ai/*.tres`)
### 10.1 Mix (`unit_mix` entries, `Vector3(default, vs_ranged, vs_melee)`; tier-3 types count only once trainable, rb. 7.2 spreading rule)
| Kingdom | New entries |
|---|---|
| Fire | Cinderlock **(0.20, 0.10, 0.25)** |
| Shadow | none (the Mage Archer is not in the mix: 10.3) |
| Ice | Frostrune Rifleman **(0.12, 0.08, 0.15)** |
| Nature | Glade Outrider **(0.12, 0.05, 0.20)**, Mossback **(0.06, 0.12, 0.04)** |
Extra rows (applied after rb. 7.3's, first match wins): **vs titans** (any seen): Rifleman 0.25, Cinderlock +0.05 vs Mammoth /
Treant; **vs ranged-heavy** (>= 50 % of seen soldier pop): Mossback 0.12; **vs slow armies** (seen soldiers' mean speed <= 4.2,
i.e. Ice or Mossback-heavy): Outrider 0.25; **vs mounted** (>= 25 %): Cinderlock +0.05, **Rifleman 0.20** (the row step 16
gave the Frostbow; before the Citadel Ice raises Shardcasters +0.10 instead, 16a).
### 10.2 Counter-mix on seen 13b units (memory, like cm. 9.1)
| Seen | Change |
|---|---|
| >= 4 Cinderlocks | cavalry +0.10, ranged +0.05 (out-range them); Nature Mossback +0.05 |
| >= 3 Frostrune Riflemen | cavalry +0.10 (dive); Fire: Sparkwing kept alive near the front (their spotter is the problem); Nature Outrider +0.05 |
| >= 3 Glade Outriders | Ice Shardcaster +0.10 and Rimehorn Rider +0.05; everyone cavalry +0.05; Nature Vinelasher 0.15 |
| A Mossback | Ice Rifleman +0.05; hard: attack groups skip the Mossback as a target while other enemy units are within 10 m (walk past) |
| A Mage Archer (`titan_event` read) | Hard: **B9** Hunt 150 on her when she is seen within 30 m of the bot's army and the bot has a champion; ranged +0.05 |
### 10.3 Using them
| Rule | Value |
|---|---|
| Calling the Mage Archer (Shadow) | As soon as the Dread Paddock is complete: crystals >= 300 + 150, essence >= 150 + 50, pop allows -> queue it **before** the first Knight. Revive at once when essence allows (before items, like champions). Easy: never (no Lair) |
| Riflemen | The rb. 7.2 min-range pullback applies (4 m); the bot does not re-order braced riflemen unless the group moves > 6 m (keeps the brace) |
| Cinderlocks | Attack-move with the line, never in front of it: their `command_attack_move` point is 3 m behind the group centre |
| Outriders | No micro (auto-kite); never in the reserve; in raids with cavalry (rb. rush rules unchanged) |
| Mossback | Joins attack groups; the group's move speed is not capped to it (it arrives late by design) except hard, where a group containing Burr Slingers waits for it within 12 m |
| Strength | Soldiers `cost x (0.8 + 0.2 x level)`; Mossback x1.2 when defending; the Mage Archer by her `power()` |
| Knob | `unique_call` (easy false / normal true / hard true) |

## 11. UI: what must be shown (layout: ui-designer, `docs/design/ui-tier3.md`, task 13b.D2)
| Element | Content | Interaction |
|---|---|---|
| Training cards | Ember Hall **N** Cinderlock, Frost Hall **N** Rifleman, Lair **X** (Mossback / Call the Mage Archer, then `Revive 195` when she is fallen, `Called` greyed while alive), Grove Stables **B** Outrider; tier pip III (14.V23) and padlock `Needs a Citadel` / `Requires a Lair` | Keys N / X / B with the building selected. Shardcaster card / panel: the Hamstring icon appears at the Stronghold (16a) |
| Unit panel | Cinderlock: reload bar `Reloading 2.1 s` / `Loaded`; Rifleman: `Bracing` / `Braced`, Rime Lock cooldown, frost pips on the target (Ice viewer); Outrider: tag `Shoots on the move`; Mossback: `Canopy: 6 m` + tag `Unstoppable`; the ability icon with its cooldown (rb. 10 pattern) | |
| Statuses | `powder_smoke`, `canopy`, `braced` icons with tooltips (`Shots against this unit deal 25 % less`, ...) | |
| World | Rime Lock aim line (both teams); Eclipse Volley ring (both teams); Mossback's canopy ring when selected | |
| **Mage Archer** | A **4th, unique slot** at the left of the champion bar (Shadow teams, from the first call): portrait, level, HP, intent (`Overwatch`, `Watching home`, the champion intents), purse; `Called 23 s` while queued; fallen: `Revive 195` | Click = centre camera (never orders); **F8** = centre on her; inspect view = the champion inspect (read-only: 3 abilities, the Wizard tree, pick history); command card text `The Mage Archer acts on her own. Bounty: R` |
| Messages | 6.3 warnings (enemy's in red), `Volley!` bark, `Veyra Nightquill learns Arc Bolt II` (merged as st. 8) | |
| Help text | Adds `F8: find the Mage Archer` | |
| Audio (ui-coder) | Musket volley boom (one sound per volley, not per shot; max 1 / 1.5 s), musket reload click, rifle crack + frost chime, Rime Lock hum during the aim, Outrider bow twang (quiet), Mossback stomp and canopy rustle, Mage Archer bowstring + violet whoosh, call horn at the Dread Paddock | SFX bus, throttled |
Keys for the lead's Keys line: Ember Hall / Frost Hall **N**, Elder Circle / Dread Paddock **X**, Grove Stables **B** (existing slot keys), **F8** = centre on the
Mage Archer (free: F4 and F8 were unused).

## 12. Art list (tech-artists; `art-units.md` style: chunky, silhouette = role, painted shaders, 1-2 glow points at 40 m; one agent per line, no time box)
Budgets: soldier budget (<= 26 meshes, <= 14 draw instances, 0 lights) for Cinderlock and Rifleman; the cavalry budget
(<= 20 parts, <= 12 instances) for the Outrider (rider only: the mount is the 13.V5 Grove Stag); the heavy / knight budget
(<= 30 meshes, <= 16 instances, <= 1 looping particle system) for the Mossback; the champion budget (<= 26 meshes, <= 16
instances, <= 5 materials) for the Mage Archer. Every scene: silhouette check in `docs/art/screens/`, headless instantiation,
`KITFIX AUDIT OK`.
**Reuse first (user Q3: "reuse what's already been made").** Each agent starts from the closest existing scene / builder and
adds only the new prop, pose and VFX; new meshes only where nothing fits:
| New asset | Built on (existing) | New work only |
|---|---|---|
| Frostrune Rifleman | **`art/units/ice/shardcaster.tscn` + `shardcaster.gd`** (hooded Ice ranged caster; same 7 pivots, parts, closed Ice palette): a new scene whose builder extends / calls the Shardcaster builder | The long rifle prop replacing the crystal rod (same ArmR mount, held level instead of sideways), fur mantle recolour, the kneel brace pose, `rifle_shot` / `play_aim` timelines |
| Cinderlock Musketeer | The Fire kit (`art/units/fire/fire_model.gd`, `build_fire_units.gd`): the **Ember Archer** body (coat, hood, legs, arms) with the Flame Guard's head / helm parts | Musket prop, plumed hat, flask bandolier, `musket_volley` / reload timelines |
| Glade Outrider | The **Stagrunner** (13.V9) scene: the same Grove Stag mount (13.V5) and seated rider | Bow in place of the shortspear, twisted-saddle shooting pose |
| Mossback | `art/units/kit/mount_model.gd` quadruped pivots (13.V1a) and the Nature closed palette / `nature_war_model.gd` parts | The shell-with-grove body (the one truly new creature) |
| Mage Archer | The champion kit: `champion_weapon_kit.gd` (a bow-holding pose from the **Wayfinder**), `CharacterModel` seated / cast hooks | The recurve bow with the violet string, rune quiver, her head / hood variants |
| Rifle / musket VFX | Existing Shardcaster bolt and Rime Spire projectile looks, the `chill` / `frozen` status looks (7.V5), the Frostbite freeze burst (14.V16), the Ash Hurler smoke emitter (4.5) | Muzzle flashes, the tracer, the Rime Lock aim line, the volley smoke cloud pool |
| Id | Asset | Silhouette (40 m black test) and look | Hooks |
|---|---|---|---|
| 13b.V1 | **Cinderlock Musketeer** + musket | Broad-brimmed hat with a tall plume, bandolier of glowing powder flasks, a **long bell-mouthed musket** held across the chest (the read: the flared muzzle), leather coat in Fire secondary; glow: flask row + muzzle ember | unit hooks, `attack_style &"musket_volley"` (shoulder 0.15 s, recoil kick), `play_reload(seconds)` (ramrod loop), `set_loaded(on)` |
| 13b.V2 | **Frostrune Rifleman** + rifle, **on the Shardcaster scene** | The Shardcaster's hooded caster turned sniper, fur and ice-silver, a **very long rune-etched rifle with a crystal scope** (longer than the body), a folded ice monopod; braced = kneels on one knee, monopod out; glow: 3 runes along the barrel + scope | unit hooks, `set_braced(on)` (1.0 s kneel), `play_aim(seconds)` (scope flares), `attack_style &"rifle_shot"` |
| 13b.V3 | **Glade Outrider** (rider on the 13.V5 Grove Stag, MountModel kit) | Light leaf-cloaked archer twisting in the saddle, **short curved bow held sideways**, a hood with two antler-like twigs; shooting pose works at a gallop (torso turns up to 90 deg to the target) | unit hooks via `set_seated`, `attack_style &"mounted_bow"`, gallop from `set_moving` |
| 13b.V4 | **Mossback** | A giant tortoise 2.6 m high, 4 m long; **a small grove on the shell** (3 young trees, moss, a stone ring) = the read; slow heavy stomp (4 legs), head bite; canopy = the trees' crowns spread and glow softly | unit hooks, quadruped gait (MountModel-style pivots, no rider), `set_canopy(on)`, `attack_style &"shell_bite"`, death = pulls into the shell and sinks |
| 13b.V5 | **Mage Archer** (+ variant B) | Tall hooded sorceress, half cape, **dark recurve bow taller than her with a glowing violet string** (the read), floating rune quiver of 5 shafts at her back; Shadow palette + a silver trim; variant B = hood down, braid | champion hooks, `weapon_override &"mage_bow"`, `attack_style &"arcane_bow"`, `play_cast(id)` for her 3 + the 6 Wizard-tree actives, `play_call()` (rises from the Lair's circle) |
| 13b.V6 | Gunpowder VFX (Fire) | Musket muzzle flash (orange cone + sparks), volley shock ring, **powder smoke cloud** (pooled MultiMesh puffs, r 2.5-4, 3 s), explosive impact (small fire burst + grit), breach sparks on buildings | `UnitVfx.play(&"musket_shot" / &"powder_volley" / &"powder_smoke" / &"musket_impact", at, target)` |
| 13b.V7 | Rune-rifle VFX (Ice) | Blue muzzle flash + snowflake burst, **frost tracer** (thin 15 m streak, 0.2 s), rime impact, brace rune circle, **Rime Lock aim line** (1.2 s beam) + freeze impact | `UnitVfx.play(&"rifle_shot" / &"frost_tracer" / &"rime_lock_aim" / &"rime_lock_hit" / &"brace", ...)` |
| 13b.V8 | Mage Archer VFX | Arcane arrow (violet streak + trail), Sable Shaft (a piercing beam-arrow through the line), Grave Mark sigil over the target, **Eclipse Volley** (ring telegraph + 3 waves of falling violet arrows), call ritual at the Lair (circle + rising column), revive column | `ChampionVfx.play(&"sable_shaft" / &"grave_mark" / &"eclipse_volley" / &"unique_call" / &"unique_revive", caster, target)` |
| 13b.V9 | Nature VFX | Outrider moving-shot arrows + kite dust puff, **Canopy** (leaf ring r 6 pulse every 4 s, a green leaf spark where a reduced shot lands) | `UnitVfx.play(&"parting_shot" / &"kite_dust" / &"canopy_pulse" / &"canopy_block", ...)` |
| 13b.V10 | Icons | 4 unit icons, Mage Archer portraits A / B (bar + inspect), 4 unit abilities (Powder Volley, Rime Lock, Parting Shots, Canopy), 3 archer abilities, statuses `powder_smoke`, `canopy`, `braced`, the "Call" button icon | existing icon pipeline, new files only |
The Frostbow's art task **16.V7 is cancelled** (16a); nothing was made for it.
Paths: `art/units/fire/cinderlock/`, `art/units/ice/frostrune_rifleman/` (reads `art/units/ice/shardcaster*`, never edits it), `art/units/nature/glade_outrider/`,
`art/units/nature/mossback/`, `art/units/champions/mage_archer/`, `art/vfx/unit_fire_gun*`, `art/vfx/unit_ice_rifle*`,
`art/vfx/unit_nature_t3*`, `art/vfx/champion_mage_archer*`, `art/icons/units/<ids>`, `art/icons/abilities/<ids>`,
`art/icons/champions/mage_archer*`.

## 13. Performance
- New logic < **0.05 ms / frame** on average with 200 units: volley grouping is one pass over own loaded Cinderlocks within 8 m
  when one becomes ready (event, not per frame); smoke clouds <= 6 per team, one 0.5 s tick each; Canopy on the aura tick
  (0.5 s) over the cached `"units"` list; bracing and kiting are one float / timer per unit.
- VFX: smoke puffs in one pooled MultiMesh per team (<= 60 instances), tracers pooled, no particles beyond 45 m.
- Perf test additions: 20 Cinderlocks volleying (6 clouds), 8 Riflemen, 6 Outriders kiting, 2 Mossbacks, 2 Mage Archers:
  `PERF OK`, stuck 0 (Mossback paths through a 3 m gap as the Mammoth).

## 14. Balance
### 14.1 Duels (level 1, no items; 13.2b / rb. 11.4 rules; the Outrider's auto-kite and the rifle's min-range pullback are part of the units)
| # | Duel | Expected | Pass band |
|---|---|---|---|
| D33 | 6 Cinderlocks (780) vs 9 Flame Guards (810), from 20 m | Guards win if they close | Guards win, >= 3 left |
| D34 | 6 Cinderlocks vs 4 Blaze Riders charging from 20 m | Volleys break the charge | Musketeers win, >= 2 left |
| D35 | 10 Cinderlocks vs a Citadel keep (3 500), no defenders | Breach | Keep falls in 20-35 s, >= 6 alive |
| D36 | 4 Frostrune Riflemen vs 1 Nightmare Knight from 20 m | Knight wins (dive) | Knight <= 40 % HP |
| D37 | 4 Riflemen + 4 Rimeshields vs 1 Nightmare Knight | Ice wins | >= 2 riflemen alive |
| D38 | 6 Riflemen vs 6 Ember Archers from 20 m | Range wins | Riflemen win, >= 4 alive |
| D39 | 8 Cinderlocks (1 040) vs 6 Riflemen (1 050) from 20 m, a spotter for Ice | Close | winner <= 50 % of its units |
| D40 | 3 Glade Outriders vs 6 Rimeshields, open ground | Kiting wins | Outriders win, all alive |
| D41 | 3 Glade Outriders vs 2 Blaze Riders | Cavalry beats ranged | Riders win, >= 1 alive |
| D42 | 8 Ember Archers vs 8 Burr Slingers + 1 Mossback (it does not attack) | Canopy decides | Nature wins |
| D43 | 1 Mossback vs 4 Riflemen from 15 m (pullback on) | Pierce wins | Riflemen win, >= 2 alive |
| D44 | Mage Archer L3 vs a L3 Coin-Cutter (Two-Hand) | She wins | >= 50 % HP |
| D45 | Mage Archer L9 vs 1 Cinder Dragon | About even | winner <= 40 % HP |
| D46 | Mage Archer L6 vs 8 Flame Guards | She kites, then flees | >= 3 guards dead before she flees or dies |
| D47 | 4 Frostrune Riflemen, braced, vs 2 Blaze Riders charging from 20 m (the dropped Frostbow's D25 job) | The first volley kills one rider and chills the other (charge denied) | Riflemen win, >= 2 alive |
### 14.2 Knobs (one at a time; 13b.D3)
| Symptom | Knob |
|---|---|
| Fire > 55 % after the Citadel (Fire bias watch, cm. 13.3) | Volley bonus +25 % -> **+15 %**; Cinderlock `building_damage_mult` 1.5 -> **1.25**; cost 130 -> **145** |
| Cinderlocks never used / always die | Reload 4.2 -> **3.8 s**; HP 120 -> **135** |
| Riflemen freeze-lock armies | `frost_on_hit` 34 -> **26** (4 hits); Rime Lock frost 100 -> **70** |
| Riflemen useless | Pop 2 -> **1** with HP 100 -> 80 and cost 175 -> 120; or setup 1.0 -> **0.6 s** |
| Ice cannot answer cavalry / Hounds before the Citadel (no Frostbow) | Shardcaster Hamstring cooldown 12 -> **9 s**; then Hamstring from the start (no Stronghold gate) |
| Mage Archer decides games | Drill 2.0 -> **1.5**; HP 560 -> **480**; call 300 + 150 -> **350 + 200** |
| Mage Archer irrelevant | Arrives level **4**; Sable Shaft 55 -> **70** |
| Outriders un-catchable raiders | Speed 7.6 -> **7.2**; `moving_cooldown_mult` 1.4 -> **1.7** |
| Mossback makes pushes unbreakable | Canopy 0.7 -> **0.8**; radius 6 -> **5** |
| Nature > 55 % late | Mossback cost 340 -> **380**; Outrider HP 190 -> **170** |
| Games shorter than the step-14 median | Tier-3 unit train times +20 %; Cinderlock breaching off (x1.0) |
### 14.3 Re-test (lead 13b.L2)
The step-16 matrix harness (rb. 11) with a new flag **`--no-t3-extras`** (the five hidden) as the control. Pass: median length
>= control - 0:30; no kingdom's win rate moves by more than 8 points vs the control; in games that reach the Citadel, each 13b
unit is >= 3 % of its kingdom's trained pop after it (the Mage Archer is called in >= 70 % of Shadow games that build a Lair);
duels D33-D47 in band; `PERF OK`.

## 15. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 13b.L1)
Rule for phase-1 agents (as steps 9-16): never use another 13b agent's new `class_name` as a static type; `load()` guarded by
`ResourceLoader.exists`, groups, `has_method()`, `get()`.
- **UnitType** (gameplay): `attack_setup_time := 0.0`, `fire_while_moving := false`, `moving_cooldown_mult := 1.0`,
  `kite_range := 0.0`, `kite_distance := 0.0`, `armor_pierce := 0.0`, `frost_on_hit := 0.0`, `spawns_champion: StringName = &""`
  (a stub type trained at a building: on completion the building asks the guild to spawn that champion instead of a Unit),
  `cc_like_titan := false` (Mossback: `hero_mult`, knockback / trample / taunt immune without the titan tag). Reused: `tier`,
  `required_keep_tier`, `min_attack_range`, `building_damage_mult`, `base_stats` (splash), `abilities`, `ability_params`,
  `expansion`, `tags`, `on_hit_status`, `sight_radius`.
- **Unit** (gameplay): bracing (`is_braced() -> bool`, `brace_progress() -> float`), fire on the move, auto-kite, `armor_pierce`
  in the damage path (Lance = `max(0.5, armor_pierce)` on mounted attackers), `attack_cooldown_left() -> float` (public, for the
  reload bar), status key `taken_by_kind` with statuses **`powder_smoke`**, **`canopy`**, **`braced`** (display only),
  `add_frost(amount, source_team, always := false)` (`always` skips the Deep Winter gate; rs. 3.3 otherwise).
- **UnitAbilities** (gameplay, rb. 13): ids **`powder_volley`**, **`rime_lock`**, **`parting_shots`**, **`canopy`**;
  `is_aiming() -> bool`, `aim_left() -> float`; `PowderSmoke` zones (pooled, <= 6 per team).
- **ChampionType** (gameplay): `unique_npc := false`, `kingdom: StringName = &""`, `start_xp := 0`, `drill_xp_per_second :=
  1.0`, `upkeep := true`, `power_base := 170.0`, `power_per_level := 20.0`, `victim_xp_base := 110`, `victim_xp_per_level :=
  10`, `revive_base := 100`, `revive_per_level := 15`, `revive_time_base := 20.0`, `revive_time_per_level := 2.0`,
  `weapon_override: StringName = &""`, `skill_affinity` (st.). New `data/champions/mage_archer.tres` (names A / B, stats 6.2,
  traits 6.6, `ability_ids` 6.5, `class_weights {wizard: 1}`, wish list, barks) and the stub `data/units/mage_archer_call.tres`
  (cost 300, essence 150 via a new `UnitType.essence_cost := 0` paid at queue, pop 4, train 45, `spawns_champion
  &"mage_archer"`, `required_keep_tier` 3, `expansion` true).
- **Champion** (gameplay): `is_unique_npc() -> bool`; unique: no upkeep, never unpaid, no dismiss, drill and victim XP / revive /
  `power()` numbers from the type, `start_xp` applied before the first picks, weapon override kept after `set_weapon_class`.
  ChampionAbilities gains `sable_shaft`, `grave_mark`, `eclipse_volley`.
- **ChampionGuild** (systems): `unique_npc: Node` (null / the Mage Archer), `can_call_unique(type_id) -> String`
  (`"Already called"` etc.), `spawn_unique(type_id, at_building: Node) -> Node` (called by TrainingBuilding), `unique_state() ->
  StringName` (`&"none"`, `&"calling"`, `&"alive"`, `&"fallen"`); `can_revive` / `revive` / `revive_time_left` work for it (type
  numbers, Lair door); pop counted while queued, alive or fallen; signals reused (`champion_hired`, `champion_fallen`,
  `champion_revived`, `roster_changed`); the roster `champions` array and its max 3 are unchanged.
- **TrainingBuilding / BuildingType** (systems): `can_queue` asks the guild for `spawns_champion` types; completion spawns
  through the guild; `essence_cost` paid and refunded like crystals; tier 3 without a ResearchBank = own completed Lair
  (`"Requires a Lair"`); tier-3 types hidden while `Skirmish.titans_enabled` is false; train lists: `fire_barracks` + `cinderlock`
  (slot 6), `ice_barracks` slot 6 = `frostrune_rifleman` (replaces step 16's `frostbow`), `nature_lair` + `mossback` / `shadow_lair`
  + `mage_archer_call` (slot 2), `nature_stables` + `glade_outrider` (slot 5). `ice_lair` unchanged (titan only).
- **UnitAbilities keep-tier gate** (gameplay, for 16a): `ability_params[id].min_keep_tier` (default 0): the ability stays
  inactive (greyed icon, `Needs a Stronghold`) until the team's keep tier reaches it; without a ResearchBank tier 2 = an own
  completed Stables (the rb. 13 fallback). Used by the Shardcaster's `hamstring_shot` (`min_keep_tier` 2).
  `Events.titan_event(team, &"mage_archer", what)` on call start / ready / fallen (TrainingBuilding / guild).
- **Skirmish** (systems): harness flag `--no-t3-extras` (hides the five).
- **AIProfile** (ai): `unit_mix` entries of 10.1, the rows of 10.1 / 10.2, knob `unique_call`. **ChampionBrain** (ai): the
  Mage Archer's traits come from her type; R8 default `&"overwatch"`; the keep-distance step; target preference 6.6.
- **Models / VFX**: hooks of section 12 (`play_reload`, `set_loaded`, `set_braced`, `play_aim`, `set_canopy`, `play_call`,
  styles `musket_volley`, `rifle_shot`, `mounted_bow`, `shell_bite`, `arcane_bow`, weapon `mage_bow`); UnitVfx / ChampionVfx ids
  of 12.
- **Keys**: F8 = centre on the Mage Archer; Ember Hall / Frost Hall N, Elder Circle / Dread Paddock X, Grove Stables B (slot keys).
- **Ownership**: `data/units/{cinderlock,frostrune_rifleman,glade_outrider,mossback,mage_archer_call}.tres`,
  `data/champions/mage_archer.tres` = gameplay; art paths of 12 = tech-artists; `docs/design/ui-tier3.md` = ui-designer.

## 16. What changes in other specs (13b.D3 writes them after the build)
`units-fire-shadow.md`: Cinderlock, the Mage Archer (pointer). `kingdom-ice.md`: Rifleman, the speed line, 5.3 table.
`kingdom-nature.md`: Outrider, Mossback. `cavalry-mounts.md`: Lair slot X, Grove Stables B, Lance = `armor_pierce`.
`research.md`: tier-3 units behind the Citadel, Rifleman `frost_on_hit` ungated, Heat / rings apply. `rush-balance.md`: the
**Frostbow removal** and the other items of **16a** (for its owner; this task did not edit it). `champions.md` / `champion-skill-tree.md`: unique NPC (not in the roster, own numbers,
Wizard class fixed). `levels.md`: victim rows. `ai.md`: 10. `ui-champions.md`: the unique slot (13b.D2). `CLAUDE.md` (lead): 15.

### 16a. Note for the owner of `rush-balance.md` (step 16): the Frostbow is removed (user 2026-09-26, 13b Q3)
Nothing of the Frostbow was built (no `data/units/frostbow.tres`, no code, no art), so this is a spec edit only. Apply in
`rush-balance.md` (16.D3 or before 16.L1 freezes it):
| Place in `rush-balance.md` | Change |
|---|---|
| Intro / 0 "Scope" and 1 "At a glance" (Ice row) | 10 new units -> **9**; Ice role units = **Frost Mortar** only; add the line "Frostbow dropped (user, 13b Q3): its slot and anti-cavalry role go to the tier-3 Frostrune Rifleman (`tier3-extras.md`); its **Hamstring Shot** moves to the Shardcaster at the Stronghold" |
| 2.1 combat-value table | Remove the Frostbow row; add "Shardcaster + Hamstring (Stronghold): 84 EHP, 6.4 DPS, chill 3 s on a fast target every 12 s" |
| 5 slot table (Frost Hall) | N = **Frostrune Rifleman** (tier 3, `tier3-extras.md`) instead of Frostbow (T2) |
| 5.1 stats | Remove the `frostbow` row; `shardcaster.tres` gains `abilities [&"hamstring_shot"]`, `ability_params {hamstring_shot: {min_keep_tier: 2}}` |
| 5.2 abilities | `hamstring_shot` owner: **Shardcaster** (active from the Stronghold; `tier3-extras.md` 15 gate) instead of Frostbow; numbers unchanged |
| 5.3 roles | Remove the Frostbow row; the "no near-duplicates" line becomes: Ice ranged = Shardcaster (9, chill, main line; Hamstring from T2) / Frost Mortar (13, lobbed area) / Frostrune Rifleman (15, T3, planted, anti-big and anti-cavalry) |
| 5.4 art briefs | Remove the Frostbow row (the Shardcaster's bow-string glow cue is not needed: its rod tip already glows; optional `glow_boost` 1.3 while Hamstring is ready) |
| 7.3 Ice mix | Remove `Frostbow (0.08, ...)`, add its 0.08 to Shardcaster (0.33, 0.23, 0.41); extra row **vs mounted**: Frostbow 0.20 -> **Shardcaster +0.10** (the Rifleman 0.20 once trainable, `tier3-extras.md` 10.1) |
| 9 data list | `ice_barracks.tres` / `train_ids`: + `rimeling` (B) only (N comes with 13b: `frostrune_rifleman`) |
| 11.4 duels | **D25** "4 Frostbows vs 2 Blaze Riders" -> "**5 Shardcasters (Stronghold, Hamstring) + 2 Rimeshields vs 2 Blaze Riders**: Ice wins, >= 3 Shardcasters alive" (the rifle version is 13b's D47) |
| 12.1 knobs | Ice > 55 %: "Frostbow damage 22 -> 20" -> "**Hamstring cooldown 12 -> 15 s**" |
| 13 contracts / 14 tasks | `hamstring_shot` belongs to the Shardcaster with the `min_keep_tier` gate; 16.C1 test "Hamstring chills a Blaze Rider 3 s" uses a Shardcaster after a Stronghold; 16.C2 makes 9 unit `.tres` (+ the Shardcaster ability fields); **16.V7 Frostbow cancelled**; 16.V12 keeps the Hamstring shot VFX (now from the Shardcaster's rod); 16.V15 keeps the Hamstring icon |
| 15 other specs / Done when | "10 new units" -> 9 |

## 17. Task list (step 13b; builds after steps 13, 14 and 16 are merged: it needs the Lairs, the Citadel, the frost meter,
`UnitAbilities`, 6 training slots, `required_keep_tier`, `unit_mix`)
**Phase 0:** 13b.L1 (incl. telling the step-16 owner about 16a), 13b.D2. **Phase 1a (new files only, can start now):** 13b.V1,
V2 (reads the built Shardcaster scene), V4, V5, V6, V7, V8, V9 (V3 after 13.V5 Grove Stag + 13.V9 Stagrunner; V4 after 13.V1a
MountModel; V5 after 11.V1 weapon kit). **Phase 1b (shared files free):** 13b.C1, C2, C3, C4, A2.
**Phase 2:** 13b.A1, 13b.U1 (needs 13b.D2), 13b.V10, 13b.C5, 13b.C6, then 13b.L2, playtest, 13b.D3.
| Id | Agent | Task | Files | Done when |
|---|---|---|---|---|
| 13b.L1 | lead | Freeze 15 in `CLAUDE.md`, Keys (F8; N / X / B slots), owner rows, 13b ids in `waves.md` (16.V7 struck), the user's Q1-Q3 answers; route 16a to the `rush-balance.md` owner | `CLAUDE.md`, `docs/plan/` | Contracts and keys written; 16a acknowledged |
| 13b.D2 | ui-designer (Fable) | `ui-tier3.md`: section 11 at 1600 x 900 (cards, reload / brace / canopy panel lines, status icons, aim line, the Mage Archer bar slot and inspect, warnings) | `docs/design/ui-tier3.md` | Every row of 11 has position, size, look |
| 13b.C1 [H] | gameplay-coder-high | UnitType fields; Unit bracing, fire on the move, auto-kite, armor pierce (Lance generalised), `taken_by_kind` + 3 statuses, `add_frost(always)`, `cc_like_titan`; UnitAbilities `powder_volley` (+ smoke zones), `rime_lock`, `parting_shots`, `canopy`; the `min_keep_tier` ability gate (15) if 16.C1 did not add it per 16a | `scripts/units/unit_type.gd`, `unit.gd`, `unit_abilities.gd`, `projectile.gd` (speed only) | Test: a braced Rifleman first fires 1.0 s after stopping and not within 4 m; its hit on a Rimeshield (armor 15) deals 52 x 100 / 107.5 = 48.4 and 3 hits freeze it; Rime Lock aims 1.2 s and freezes a titan 0.5 s; 3 Cinderlocks in one window deal 50 each + 0.6 m knockback + 0.3 s daze on a Blaze Rider, a lone one 40; smoke makes an Ember Archer's 9 into 6.75; Canopy makes a tower's 15 into 10.5 within 6 m and nothing at 7 m; an Outrider shoots while moving at 1.54 s and steps 5 m away from a Flame Guard within 4 m, not on Hold; `PERF OK` |
| 13b.C2 | gameplay-coder | The 5 unit `.tres` + `mage_archer.tres` (ChampionType) with the numbers of 4-7 | `data/units/*.tres` (5 new), `data/champions/mage_archer.tres` | Numbers exact (test reads them); kill_xp as listed |
| 13b.C3 [H] | gameplay-coder-high | Champion unique-NPC path (6.3-6.5): start XP, drill 2.0, no upkeep / dismiss, victim / revive / power numbers from the type, fixed Wizard class, weapon override, the 3 abilities + autocast, save state | `scripts/units/champion.gd`, `champion_type.gd`, `champion_abilities.gd` | Test: a spawned Mage Archer is level 3 with 3 picks, 582 HP, reaches level 6 after 4:40 of drill alone (560 XP at 2 XP / s); Sable Shaft hits 3 units in a line for 55 / 33 / 33; Grave Mark resets the shaft on a kill and heals 40; Eclipse Volley 3 x 22 + `withered` 3 s from level 6; victim XP 245 at L3; save round-trip |
| 13b.C4 | systems-coder | Slots and train lists (N / X / B), tier-3 gate and fallbacks, `spawns_champion` + `essence_cost` in TrainingBuilding, ChampionGuild unique call / revive at the Lair door, warnings, `--no-t3-extras` | `scripts/buildings/training_building.gd`, `building_type.gd`, `scripts/world/champion_guild.gd`, `skirmish.gd`, `data/buildings/fire_barracks.tres`, `ice_barracks.tres` (slot 6: `frostrune_rifleman`, no `frostbow`), `nature_lair.tres`, `shadow_lair.tres`, `nature_stables.tres` | Test: the Ember Hall N and the Frost Hall N read `Needs a Citadel` until the Citadel, `Requires a Lair` with research off, hidden in missions; the Dread Paddock X queues the call (300 + 150, pop 4), a second is refused `Already called`; she spawns at the Lair door; revive 195 essence after 34 s at L3; the enemy gets the warning; the Lair keeps its Z titan |
| 13b.A1 | ai-coder | Mix entries and rows (10.1-10.2), unique call / revive, rifle brace rule, Cinderlock placement, Mossback waiting (hard), B9 | `scripts/ai/commander.gd`, `ai_profile.gd`, `data/ai/*.tres` | Headless normal, games reaching the Citadel: Fire trains Cinderlocks, Ice Riflemen, Nature both units, Shadow calls the Mage Archer within 60 s of the Dread Paddock; seeing 3 Outriders raises Ice's Shardcaster share by 0.10 within 2 ticks; with >= 25 % mounted seen, Ice's Rifleman share is 0.20 once the Citadel stands; no `frostbow` anywhere in `data/ai/`; `PERF OK` |
| 13b.A2 | ai-coder | ChampionBrain for the Mage Archer: traits from the type, R8 Overwatch / Watching home, keep-distance step, target preference, Lair as a rest spot | `scripts/ai/champion_brain.gd`, `champion_sense.gd` | Test: she follows the largest group 8 m behind; with < 4 soldiers she watches home; she steps back from a Flame Guard at 3 m; she prefers a < 50 % HP wizard over a nearer Shade; takes a Hunt 100 flag on a champion at 40 m |
| 13b.U1 | ui-coder | Section 11 (cards, panel lines, statuses, aim line / rings, the unique bar slot, F8, inspect, warnings, help text, audio) | `scripts/ui/command_card.gd`, `selection_panel.gd`, `champion_bar.gd`, `hud.gd`, `minimap.gd` (no diamond for `mage_archer`), `assets/audio/gun_*`, `t3_*` | As 13b.D2; nothing in `scripts/ui/` calls a `_private` function |
| 13b.C5 | gameplay-coder | Plug the 5 models, hooks and VFX calls | `data/units/*.tres`, `data/champions/mage_archer.tres`, `scripts/units/` (hooks only) | Models replace placeholders; hooks fire; smoke `victory=true` |
| 13b.C6 | gameplay-coder | Duels D33-D47 in the harness | `tests/test_13_duels.gd` (rows only, after 13.C9 / 16.A3) | Prints PASS / FAIL per duel |
| 13b.V1-V10 | tech-artist (one per id) | Section 12 | Section 12 paths | Section 12 hooks, budgets, silhouette screenshot, headless clean, `KITFIX AUDIT OK` |
| 13b.L2 | lead | Integration (UnitVfx / ChampionVfx ids in both scenes), perf additions (13), runs of 14.3, playtest copy | `tests/`, `scenes/`, `docs/plan/` | 14.3 passes; CI green |
| 13b.D3 | game-designer | Balance from 13b.L2 logs + playtest, knobs of 14.2, section 16 edits | `docs/design/` | Notes and knob changes written here |
Playtest (user): a skirmish with each kingdom to the Citadel: do musketeer volleys and rifle freezes feel different? Does the
Mage Archer feel strong but huntable? Do Outriders kite and the Mossback protect as described?

## Done when (step 13b)
- [ ] Each kingdom trains its tier-3 extras at the slots of section 2 only after the Citadel (or a Lair with research off);
      missions list none.
- [ ] Cinderlock volleys, smoke, splash and breaching; Rifleman bracing, min range, pierce, freeze and Rime Lock; Outrider
      moving fire and auto-kite; Mossback Canopy and CC rules work as sections 3-7 (13b.C1 test).
- [ ] Shadow calls one Mage Archer at a time; she arrives at level 3, levels to 9 on her own, takes bounties, cannot be
      ordered, is revived at the Dread Paddock; the enemy is warned.
- [ ] Bots train / call them by section 10; duels D33-D47 in band; 14.3 passes; no `frostbow` left in data, AI profiles or tests; `PERF OK`, stuck 0; smoke test `victory=true`.

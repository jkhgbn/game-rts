# Cavalry, titans and hero mounts

Task 13.D1, written 2026-09-26 (revised the same day with the lead's relays of the user's answers). Source of truth for step 13
(tasks in section 16). User request: "add a dragon to one side and strong cavalry to the other", clarified: **every kingdom
can train a cavalry unit, and heroes have a mount system**; then: **the Dragon is a tier-3 army unit of one kingdom (not a hero,
not a mount)**, very expensive, very strong, with clear counters; **no max count** (players may mass tier-3 units; cost, pop,
train time and counters limit them); the opposing kingdom's tier 3 is a **very strong heavy cavalry**, and Ice and Nature get a
tier 3 of equal weight. Every name, unit, number and rule here is our own. Metres, seconds, `m:ss` since the navmesh was ready;
positions `(x, z)` on Crown Hollow, player side (south-west; the enemy side is the point mirror `(-x, -z)`). Numbers build on
`units-fire-shadow.md`, `kingdom-ice.md`, `kingdom-nature.md`, `balance-2.md`, `levels.md`, `champions.md`, `skills-rework.md`,
`market-trade.md` and today's `data/units/*.tres` (which override the older docs: Shade 110 HP, Shadow Knight 260 / 480 HP,
Grave Hound 70 HP, Thornling 60, Rimeshield 95, Rime Colossus 290).

## 0. Decisions for the user (recommendation first; the rest of this spec assumes the recommendations)
| # | Question | Recommendation | Alternatives |
|---|---|---|---|
| Q1 | **The four tier-3 "titans"** (no max count, each from a new tier-3 building). Keep these four? | **Fire: Cinder Dragon** (the dragon goes to Fire: it matches Vessa's pyromancy and gives Fire vs Shadow the "dragon on one side, heavy cavalry on the other" duel of the vertical slice). **Shadow: Nightmare Knight** (the very strong heavy cavalry). **Ice: War Mammoth** with a frost-archer howdah. **Nature: Elder Treant** that roots into a living tower. Numbers in section 5 | Give the dragon to Shadow (a bone dragon) and the knights to Fire; or swap Ice / Nature themes. Any number in section 5 is a knob |
| Q2 | **The dragon truly flies** (over walls, cliffs, buildings and units; only ranged units, towers / keeps, spells and ranged champions can hit it; melee cannot). OK? | **Yes, true flyer**, with the counters built in: ranged units, towers and keeps deal **x2** to flyers, it turns slowly, it is the most expensive unit in the game, and every kingdom has cheap ranged units and towers (plus the Mammoth's howdah and the rooted Treant shoot at air) | "Low flyer": it follows ground paths and melee can hit it at x0.5 (safer to build, less special) |
| Q3 | **Mounted heroes are travel-only**: faster (+2.0 m/s), but no auto-attacks while mounted; a spell or an attack order makes the hero hop off (0.3 s); being frozen, rooted, dazed or knocked back throws them off. Mounting takes 1 s and is refused within 3 s of taking damage. OK? | **Yes.** It speeds up rotation (defend sooner, rejoin after a respawn) without making heroes stronger in fights, so games do not get shorter | "Fight mounted": attacks and spells from the saddle, +HP while mounted (stronger heroes, shorter games) |
| Q4 | **A new tier-2 building, the Stables**, trains each kingdom's cavalry and sells the hero mounts; the Blaze Rider **moves** from the Ember Hall to the Ember Stables; line infantry (Flame Guard, Shade, Rimeshield, Thornling) deal **+50 % to mounted** units. OK? | **Yes.** Classic triangle: cavalry beats ranged, line infantry beats cavalry, ranged beats line. Moving the Blaze Rider behind a 175-crystal building also slows Fire's early aggression (Fire wins 11 / 12 of its bot games in `balance-2.md`) | Keep the Blaze Rider in the Hall (the Stables then trains a second Fire cavalry); no anti-mount bonus |
Mount key: **Tab** (physical; free today, next to the WASD / Q hand). Fallback if the user dislikes Tab: **N**.

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Tiers | **Tier 1** = keep + Hall (today). **Tier 2** = **Stables** (needs a completed Hall): cavalry + hero mounts. **Tier 3** = **Lair** (needs completed Stables, placeable from **8:00**): the kingdom's titan | A tech path the player reads; 475 crystals of buildings before the first titan keeps them late |
| Cavalry | One per kingdom, pop 2: **Blaze Rider** (Fire, existing), **Gloam Rider** (Shadow), **Rimehorn Rider** (Ice), **Stagrunner** (Nature) | "All can make a cav unit" |
| Shared cavalry rules | **Charge** (first hit after a 5 m run: bonus damage), **Lance** (mounted attacks ignore half the target's armor), **anti-mount** (+50 % from line infantry and Spear champions) | Strong cavalry with a clear counter |
| Titans | Tier 3, **no max count**, pop 4-6, 400-700 crystals, 50-85 s: Cinder Dragon, Nightmare Knight, War Mammoth, Elder Treant | User decision; limited by cost, pop, time and counters |
| Titan guard rails | Lair from 8:00; the enemy is warned when a titan starts training and titans show on the enemy minimap; crowd control lasts half (never immune); no veterancy; building damage x0.5 (the Mammoth x2: it is the siege titan) | A single titan must not end a game; the defender always gets time to answer |
| Flying | Only the Cinder Dragon. Moves in straight lines at 4 m height, ignores the navmesh; only ranged attacks, towers, keeps, spells and abilities hit it; ranged and towers deal x2 to it | The user's "flying over terrain and walls" with a readable counter |
| Fire weakness | War Mammoth and Elder Treant take **x1.5 from fire** (Fire-kingdom units, towers and spells, `burn` DoTs, burning ground) | The user's "weak to fire"; every kingdom can buy burn items |
| Hero mounts | Wizard: kingdom mount at the own Stables, **150 crystals** (or 150 gold), level 3; **Barding** 200 (or gold), level 5. Champions: a neutral **Roan Courser** for **120 purse essence**, level 3, bought at a tavern or the own Stables | Mounts are a mid-game purchase, never a level-1 rush tool |
| Mounted rules | Travel-only (Q3); speed cap **7.5 m/s** for mounted heroes; the Ember Crown's wearer cannot mount | Cavalry (7.2-8.0) can still run a mounted hero down; no crown-run exploit |
| Big units and paths | One navmesh (agent radius 0.5) as today. Physics capsule max **0.8**; avoidance / target radius up to **1.1**; map gaps meant for armies >= 3 m | No second navmesh bake (perf, rebakes) |
| Missions | `Skirmish.cavalry_enabled` (Stables, cavalry, mounts) and `titans_enabled` (Lairs, titans), both true in the skirmish, **false by default in missions** | One new system per mission (as trade) |

## 2. Buildings: Stables (tier 2) and Lairs (tier 3)
### 2.1 Numbers (kingdom rule: Ice +20 % HP and build time, Nature -10 % HP, -15 % build time, Nature -20 crystals)
| id | Name | Cost | Build | max_hp | Footprint | Height | Sight | kill_xp | Needs | Trains / sells |
|---|---|---|---|---|---|---|---|---|---|---|
| `fire_stables` | Ember Stables | 175 | 50 | 1100 | 3 x 3 | 4.5 | 12 | 90 | completed Hall | Blaze Rider **Z**; wizard mount **X**; Barding **C** |
| `shadow_stables` | Gloom Stables | 175 | 50 | 1100 | 3 x 3 | 4.5 | 12 | 90 | completed Hall | Gloam Rider Z; X; C |
| `ice_stables` | Frost Stables | 175 | 60 | 1320 | 3 x 3 | 4.5 | 12 | 90 | completed Hall | Rimehorn Rider Z; X; C |
| `nature_stables` | Grove Stables | 155 | 43 | 990 | 3 x 3 | 4.5 | 12 | 90 | completed Hall | Stagrunner Z; X; C |
| `fire_lair` | Dragon Roost | 300 | 70 | 1500 | 3 x 3 | 9 | 14 | 150 | completed Stables, match time >= 8:00 | Cinder Dragon Z |
| `shadow_lair` | Dread Paddock | 300 | 70 | 1500 | 3 x 3 | 6 | 14 | 150 | same | Nightmare Knight Z |
| `ice_lair` | Glacier Den | 300 | 84 | 1800 | 3 x 3 | 7 | 14 | 150 | same | War Mammoth Z |
| `nature_lair` | Elder Circle | 280 | 60 | 1350 | 3 x 3 | 8 | 14 | 150 | same | Elder Treant Z |
- `kind` `&"stables"` / `&"lair"`; `max_count` **1** each (a tech building; the titans themselves have no cap). Both count for
  defeat, are **not** shops or drop-offs, queue 5 like the barracks, rally by right-click. Essence on kill = the building rule.
- Placement messages (`BuildGrid.check`, after the Bazaar rules, before crystals): `"Needs a completed Hall"` (existing
  message), `"Needs completed Stables"`, `"Available at 8:00"` (`BuildingType.min_time` 480; the ghost shows the countdown),
  `"Only one Stables"` / `"Only one Lair"` for the limit.
- With cavalry on (skirmish), the Ember Hall trains **Flame Guard Z, Ember Archer X, Ash Hurler C** (the Blaze Rider leaves;
  the Hurler moves from V to C): halls never offer `mounted` types while `cavalry_enabled` is true. With cavalry off
  (missions 1-3), the Ember Hall keeps the Blaze Rider in slot C exactly as today, so `mission-01.md` (Brazier 2 unlock,
  `mission_01.gd` hall copy) and `mission-02.md` are unchanged. `fire_barracks.tres` keeps its 4 entries; the filter is code.
  The other Halls are unchanged (the Grave Hound stays in the Gloom Hall: it is a hound, not cavalry).
- Build menu (workers, after **B**): row 1 unchanged (house Z, Hall X, tower C), r2c1 Ice Wall **V** (Ice), r2c2 Bazaar **B**,
  **r2c3 Stables N**, **r2c4 Lair M** (inside the build menu M means Lair, as Z / X / C already mean buildings there).
- Tooltips: `Ember Stables  [N]\nCost 175 crystals · 50 s · 1100 HP\nTrains Blaze Riders. Sells your wizard's mount. Needs a Hall.` ·
  `Dragon Roost  [M]\nCost 300 crystals · 70 s · 1500 HP\nRaises Cinder Dragons. Needs Stables. From 8:00.`
- Bot and "natural" slots (verify with `BuildGrid.check`; shifts as `ai.md`): **T2** Stables `(-55, 37)` / enemy `(55, -37)`
  (7 m from home node a, clear of the keep, M1 and V1); **T3** Lair `(-33, 55)` / `(33, -55)` (7 m from node b, clear of H1).
  If step 12 (map fill) puts props there, 12.* moves them or the ai-coder picks the next valid offset.

### 2.2 The Stables as the mount shop (card and panel; layout by 13.D2)
| Button | Rule |
|---|---|
| Cavalry **Z** | Train (queue 5). Tooltip `Blaze Rider  [Z]\nCost 180 crystals · Pop 2 · 30 s\nFast shock cavalry. Charges; beats archers, loses to spearmen and guards.` |
| Wizard mount **X** | `Ember Boar  [X]\n150 crystals (or 150 gold) · needs Vessa level 3\nTab: ride. +2.0 speed. No attacks while riding.` Reasons in order: `"Stables not ready"`, `"Already owned"`, `"Needs level 3"`, `"Not enough crystals"` (Shift+click = pay in gold when trade is on: `"Not enough gold"`) |
| Barding **C** | `Ember Barding  [C]\n200 crystals (or 200 gold) · needs level 5 and a mount\n+0.5 speed and +15 armor while riding; mounts in 0.5 s.` Reasons: `"Stables not ready"`, `"No mount"`, `"Already owned"`, `"Needs level 5"`, `"Not enough crystals"` |
The wizard does not need to walk to the Stables: buying is from the building card anywhere (like the Bazaar wares).

## 3. Shared combat rules (gameplay)
### 3.1 Tags and damage kinds
- `UnitType.tags`: `&"mounted"` (every cavalry unit, the Nightmare Knight, and a hero while riding), `&"titan"`, `&"flying"`.
- Every hit has a **kind**: `&"melee"` (attacker `attack_range` <= 3.0, no projectile), `&"ranged"` (projectile unit
  attacks, champion ranged weapons), `&"tower"` (towers and keeps), `&"spell"` (wizard spells, champion abilities, titan
  specials), `&"dot"` (DoTs, burning ground). A hit is also **fire** when its source is a Fire-kingdom unit, building or
  wizard, a `burn` DoT, burning ground or the Cinder Dragon.
- The target applies `UnitType.damage_taken_mult[kind]`, then `[&"fire"]` if fire, then `[&"mounted"]` if the attacker is
  mounted (all multiplicative, default 1.0), **before** armor. The attacker applies its own `bonus_vs_mounted` (+50 % on a
  mounted target) and `building_damage_mult` (on buildings).

### 3.2 Cavalry
| Rule | Value |
|---|---|
| **Charge** | A mounted unit that has moved >= **5 m** continuously at >= **80 %** of its move speed (path movement, not knockback) and then lands an attack deals `charge_bonus` extra damage on that hit (+ `charge_status` for `charge_status_duration`, + knockback if set). Ready again **8 s** later (Knight 6 s) after a new run. Never on buildings. Readiness shows as a small mark (13.D2) |
| Charge denied | `chill`, `rooted`, `frozen`, `dazed`, `smoulder` on the rider cancel readiness and block it for **6 s** |
| **Lance** | Attacks from mounted units ignore **50 %** of the target's positive armor (Rimeshield 15 -> 7.5; War Mammoth 30 -> 15) |
| **Anti-mount** | `bonus_vs_mounted` **0.5** on `flame_guard`, `shade`, `rimeshield`, `thornling`, and on champions of the **Spear** class. A riding hero counts as mounted |
| Flee / leash | Unchanged (units do not hit-and-run on their own; the player can) |

### 3.3 Flying (Cinder Dragon only)
| Rule | Value |
|---|---|
| Movement | Straight line in x-z at `fly_height` 4.0 m, ignoring navmesh, walls, buildings, trees and ground units; clamped to the buildable area; turns at `turn_rate_deg` **120 deg/s** (it banks through turns); flyers push each other apart (radius 1.0) and never push ground units |
| Who can hit it | Ranged units (`attack_range` > 3.0), towers, keeps, spells, abilities, the Mammoth's howdah, a rooted Treant, other flyers. **Melee cannot**: auto-target skips it; an attack order on it from melee-only units is refused with `"Can't reach flying units"` (mixed selections: only the able units obey) |
| Damage it takes | `ranged` **x2.0**, `tower` **x2.0**, others x1.0 |
| Area effects | Area spells and abilities centred on the ground hit it at its x-z position (Fireball, Flash Freeze, Thornburst, Starfall...). Knockback, taunt and trample never affect it; `rooted` and `frozen` stop it in the air |
| Fog, clicks | Normal sight (14). Its click shape is a capsule around the body at 4 m; its selection ring and a small shadow blob stay on the ground under it |
| Crown, items, loot | A flyer never picks up the crown, ground items or loot sacks |

### 3.4 Titans (tier 3)
| Rule | Value |
|---|---|
| Count | **No maximum** (user decision) |
| Crowd control | `hero_mult` (half duration) for `chill`, `frozen`, `rooted`, `dazed`, `smoulder`; **immune to `taunted`** and to knockback (Knight charges push titans 1 m) |
| Veterancy | None (no chevrons); kill XP `cost / 2` rounded to 5 |
| Buildings | `building_damage_mult` **0.5**, except the War Mammoth **2.0** (the siege titan) |
| Warnings | When a titan **starts training**: owner `A Cinder Dragon is being raised`, enemy `The enemy is raising a Cinder Dragon!` (max once per 60 s per team, summed: `...2 Cinder Dragons!`). Ready: `The enemy's Cinder Dragon takes the field!` Death: `A Cinder Dragon has fallen` (both) |
| Minimap | Titans are drawn on the **enemy's minimap** too (not in the world under fog): "too big to hide" |
| Strength (bot) | `cost x 1.5` |

## 4. Cavalry units (tier 2, trained at the Stables slot Z)
| id | Name | Kingdom | Role | HP | Armor | Dmg | Range | Cooldown | DPS | Speed | Aggro | Radius | Height | Cost | Pop | Train | kill_xp | Charge | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `blaze_rider` | Blaze Rider | Fire | Shock | 220 | 0 | 18 | 1.7 | 0.9 | 20.0 | 7.5 | 9 | 0.6 | 1.9 | 180 | 2 | 30 | 90 | +18 | (stats unchanged; moves to the Stables) |
| `gloam_rider` | Gloam Rider | Shadow | Draining lancer | 240 | 5 | 16 | 1.8 | 0.9 | 17.8 | 7.2 | 9 | 0.6 | 2.0 | 185 | 2 | 30 | 95 | +16 | `lifesteal` 20 % (base stat) |
| `rimehorn_rider` | Rimehorn Rider | Ice | Armored breaker | 300 | 20 | 20 | 1.8 | 1.2 | 16.7 | 6.0 | 9 | 0.7 | 2.1 | 210 | 2 | 36 | 105 | +20, `chill` 2 s | - |
| `stagrunner` | Stagrunner | Nature | Fast skirmisher | 180 | 0 | 14 | 1.7 | 0.8 | 17.5 | 7.8 | 9 | 0.6 | 2.2 | 160 | 2 | 26 | 80 | +14, `rooted` 1 s | `idle_regen_pct` 1.0 |
All four: tags `[&"mounted"]`, `charge_run` 5, `charge_cooldown` 8, `tier` 2. Colours (team cloth / beast): Gloam
`(0.42, 0.22, 0.60)` / dusk horse `(0.16, 0.12, 0.20)`, Rimehorn `(0.45, 0.75, 0.95)` / woolly rhino `(0.55, 0.60, 0.66)`,
Stagrunner `(0.35, 0.70, 0.25)` / mossy stag `(0.40, 0.30, 0.18)`.
- **Ice identity note**: the Rimehorn (6.0 m/s) breaks the old "no Ice unit faster than 4.6" line on purpose: Ice is the
  weakest kingdom in every `balance-2.md` round and cannot catch raiders; it gets the slowest, toughest cavalry.
- Counters: every cavalry loses to line infantry of equal cost (anti-mount), to towers (charges never hit buildings) and to
  slows (charge denied). It beats ranged units, casters, workers and caravans.

## 5. Titans (tier 3, trained at the Lair slot Z)
### 5.1 Stats
| id | Name | Kingdom | HP | Armor | Attack | Speed | Aggro / sight | Radius (collision) | Height | Cost | Pop | Train | kill_xp | Tags |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `cinder_dragon` | Cinder Dragon | Fire | 1400 | 0 | Breath: 16 to every enemy in a **60 deg cone, 6 m**, every 2.2 s (0.35 s windup), + burning ground | 5.5 (flying) | 11 / 14 | 1.0 (none: flyer) | body at 4 m, span 7 m | **700** | **6** | **85** | 350 | titan, flying |
| `nightmare_knight` | Nightmare Knight | Shadow | 650 | 0, **+30 at the gallop** | 28, range 2.0, cooldown 1.2 (23.3 DPS) | **8.0** | 10 / 11 | 0.8 (0.8) | 2.8 | **400** | **4** | **50** | 200 | titan, mounted |
| `war_mammoth` | War Mammoth | Ice | 2000 | 30 | Tusks 40, range 2.4, cooldown 2.2 (18.2 DPS) + howdah archer | 3.4 | 10 / 12 | 1.1 (0.8) | 4.2 | **650** | **6** | **80** | 325 | titan |
| `elder_treant` | Elder Treant | Nature | 1600 | 10 (+20 rooted) | Walking: 30, range 2.4, cooldown 1.8 (16.7 DPS). Rooted: thorn volley 14, range 11, cooldown 1.4 | 3.8 (0 rooted) | 10 / 12 | 1.0 (0.8) | 4.0 | **600** | **6** | **75** | 300 | titan |
Training shows its time and the enemy warning (3.4). Titans rally like soldiers.

### 5.2 Specials (autocast or passive; one script `TitanAbilities`)
| Titan | Special | Numbers |
|---|---|---|
| Cinder Dragon | **Breath** (its attack, fire, kind `spell`) | Hits ground and air units in the cone; buildings in the cone take x0.5 (8). Breathes only at a target within +-30 deg of its facing (slow turn = flank it) |
| | **Burning ground** | A patch r **2.0**, centred 4 m ahead, lasts **3 s**: enemy ground units inside take **2 every 0.5 s** (fire, `dot`); one patch tick per unit per 0.5 s however many patches overlap |
| | **Airborne** | 3.3: ranged / towers x2, melee cannot hit |
| Nightmare Knight | **Charge** | Run >= 6 m: **+90**, knockback **3 m** (heroes 1.5 m, titans 1 m, never flyers or buildings), `dazed` 0.6 s; ready every 6 s |
| | **At the gallop** | Armor **+30** (modifier `gallop`) after 1 s above 4 m/s; lost 1 s after dropping below: "fragile once stopped" |
| | **Soul-fed** | `lifesteal` 30 % (base stat) |
| | Mounted | Anti-mount +50 % from line infantry / Spear champions; slows deny its charge (3.2) |
| War Mammoth | **Howdah archer** | A second, independent attack: 10 damage, range **9**, every 1.5 s, projectile, **hits air**, `chill` 1.5 s on hit; targets flyers first, then the nearest ranged unit, then the nearest enemy |
| | **Frost aura** | Enemy ground units within **5 m** are `chill`ed (1 s, refreshed every 0.5 s) |
| | **Trample** | While moving >= 1 m/s: every 1.0 s, enemy ground non-hero, non-titan units within 1.6 m of a point 1.2 m ahead take **15** and are pushed **1.2 m** aside |
| | **Siege** | `building_damage_mult` **2.0** (tusks: 80 per hit on a building) |
| | **Weak to fire** | `damage_taken_mult.fire` **1.5** |
| Elder Treant | **Take root / Uproot** (order, key **V**) | 3 s to root or uproot (no move, no attack during). Refused `"Too close to a building"` (< 3 m) or `"Busy"`. Rooted: immobile, armor +20, attack becomes the **thorn volley** (hits air) |
| | **Grove aura** (rooted) | Own soldiers, heroes and champions within **8 m**: `hp_regen` **+4** (aura `aura:elder`; does not stack with another Treant's) |
| | **Seedlings** (rooted) | Every **15 s** a Sapling (the existing `sapling` type, **lifetime 30 s**, 0 pop, 0 XP) sprouts within 3 m; max **3** alive per Treant |
| | **Verdant** | `idle_regen_pct` **1.5** (Nature rule) |
| | **Weak to fire** | `damage_taken_mult.fire` **1.5** |

### 5.3 Counters (what each kingdom answers with)
| Titan | Hard counters | Soft counters | It beats |
|---|---|---|---|
| Cinder Dragon | Ranged units and towers / keeps (x2); spells; Mammoth howdah, rooted Treant | Flanking (slow turn); another dragon | Melee blobs, workers, Knights (they cannot hit it), caravans |
| Nightmare Knight | Line infantry and Spear champions (+50 %); slows / roots / freezes (charge denied, then armor 0); towers | Ice Walls (break the run into a base); a Dragon (untouchable) | Ranged units, casters, wizards, champions, workers |
| War Mammoth | Fire (x1.5); cavalry and Knights (Lance halves its armor; it cannot catch them) | Kiting ranged (3.4 m/s); surrounding it (one tusk target) | Buildings (x2), clumped melee (trample + aura), flyers (howdah) |
| Elder Treant | Fire (x1.5); out-ranging it when rooted (Ash Hurler 12, spells); walking past it (immobile) | Area damage on the Saplings; sustained damage (no idle regen) | Attrition fights near its roots, siege on its base, flyers (rooted) |
Every kingdom has an anti-air answer: its ranged unit (Ember Archer, Nightbolt, Shardcaster, Burr Slinger), its tower and
keep (x2), its wizard's spells, and Ice / Nature their titan.

## 6. Hero mounts
### 6.1 Mount types (`MountType`, `data/mounts/<id>.tres`)
| id | Name | For | Model | Price | Level | Riding speed | Barding |
|---|---|---|---|---|---|---|---|
| `ember_boar` | Ember Boar | Fire wizard | the Blaze Rider's flame-maned boar | 150 crystals or 150 gold | 3 | +2.0 | 200 crystals / gold, level 5: +0.5 speed, +15 armor while riding, mounts in 0.5 s |
| `dusk_steed` | Dusk Steed | Shadow wizard | the Gloam Rider's horse | same | 3 | +2.0 | same |
| `rimehorn` | Rimehorn | Ice wizard | the Rimehorn Rider's rhino | same | 3 | +2.0 | same |
| `grove_stag` | Grove Stag | Nature wizard | the Stagrunner's stag | same | 3 | +2.0 | same |
| `roan_courser` | Roan Courser | any champion | a stocky neutral horse with saddlebags, team saddle-cloth | **120 purse essence** (20 % tithe to the team) | 3 | +1.8 | none |
Same numbers for every kingdom (fairness); the look differs. One mount per hero, owned for the whole match (kept through
death, not carried between missions except the champion companion's courser, 12).

### 6.2 Rules (wizard and champions alike)
| Rule | Value |
|---|---|
| Mount | Player: **Tab** (or the hero-column button). **1.0 s** standing still (0.5 s with Barding), a small progress arc. Cancelled by WASD / an order / any damage (`"Interrupted"`) |
| Refusals (`can_mount`, in order) | `"No mount"`, `"Dead"`, `"Already riding"`, `"Carrying the Crown"`, `"In combat"` (damaged in the last **3 s**), `"Can't ride now"` (a crowd-control status, or the remount cooldown) |
| Riding | modifier `mount`: `move_speed` +2.0 (+2.5 barded; champions +1.8), `armor` +15 if barded. **Speed cap 7.5 m/s** while riding (items included). Tag `mounted` (anti-mount applies to the rider) |
| No fighting from the saddle | No auto-attacks, no auto-aggro, no retaliation; items (potions) usable |
| Hop off (0.3 s, then the action) | Tab; a spell key; an attack or attack-move order; for champions, any ability cast |
| Thrown off | `frozen`, `rooted`, `dazed` or a knockback -> dismounted at once, `play_thrown`, remount cooldown **10 s** (3 s after a normal dismount) |
| Death / respawn | Dismounted; the mount is kept; respawns on foot |
| Crown | The wearer cannot mount; picking the crown up while riding dismounts |
| Size | Riding hero: avoidance / click radius 0.6, collision unchanged; model on the mount (art 10) |
Wizard speeds riding: Vessa 6.6 (7.1 barded), Malrik 6.4 (6.9), Torvald 6.2 (6.7), Ysolde 6.8 (7.3). Every cavalry except the
Rimehorn is faster, so a mounted hero can be run down; a mounted hero outruns line infantry and titans except the Knight.

### 6.3 Champions (autonomous; brain rules in 9.3)
- Buy: brain rule R7 (shopping) gains an entry: level >= 3, no mount, purse >= 120 -> the nearest of a not-held tavern door or
  the own completed Stables within 60 m; `MountRider.buy_with_purse(&"roan_courser", shop)`. Message
  `Sable Quint bought a Roan Courser` (own team) + the tithe line.
- Champions never buy Barding. The companion (campaign) keeps the courser (save key `mount`).

## 7. Pathing, navmesh, big models
| Topic | Rule |
|---|---|
| Navmesh | Unchanged: one bake, `agent_radius` 0.5 (`main.gd`). No second navmesh for big agents |
| Radii | `Unit` keeps `radius` for avoidance, target radius, selection ring; the **physics capsule** uses `min(radius, 0.8)` (`MAX_COLLISION_RADIUS` 0.8). `MAX_UNIT_RADIUS` 0.7 -> **1.1** (held units' search margin). Mammoth 1.1, Treant 1.0, Knight 0.8, cavalry 0.6-0.7 |
| Models bigger than footprints | The Mammoth (5 m long) and the Treant overlap neighbours visually; avoidance keeps others ~1 m off. Accepted, as the caravan today |
| Chokepoints | Every gap meant for armies >= **3 m** (step 12 bridges and fords, the ring road corridor 5 m, tavern and post clearings). An Ice Wall 1-cell gap (2 m) lets cavalry through but blocks the Mammoth and the Treant (their avoidance radius): intended (walls counter them) |
| Flyers | No agent path; `NavigationAgent3D` avoidance on a separate avoidance layer (flyers only); positions clamped to the buildable area |
| Treant rooted | A unit (not an obstacle): no navmesh rebake; avoidance priority 1.0 (others step around) |
| Test | Rimehorn, Mammoth and Treant path keep -> crown -> enemy keep and through a 2-cell wall gap without being stuck > 3 s; the perf test's stuck count stays 0 |

## 8. UI: what must be shown (layouts, sizes, looks: ui-designer, `docs/design/ui-cavalry.md`, task 13.D2)
| Element | Content | Interaction |
|---|---|---|
| Build menu | r2c3 **Stables N**, r2c4 **Lair M** (tooltips 2.1; reasons incl. `Available at 8:00` with a countdown) | N / M in the build menu |
| Stables card | Cavalry Z, Mount X (the kingdom mount name, price, `Owned`), Barding C, Set Rally | Shift+click X / C = pay in gold (trade on) |
| Lair card / panel | Titan Z with cost / pop / time, queue; panel line `Titans raised 2 · alive 1` | |
| Hero column | A **mount button** beside the XP bar: mount icon, key `Tab`, states `Buy at the Stables` (no mount), `Ready`, `Riding`, `Mounting` (arc), cooldown sweep, refusal reason on press (`In combat`) | Tab / click |
| Wizard in the world | Riding: the model on its mount; the ground ring grows to the mount size | |
| Cavalry / Knight | Charge-ready pip (a small gold chevron on the HP bar) while ready | |
| Treant card | **Take Root V** / **Uproot V** (3 s bar), rooted state in the panel | V |
| Flyer | Command card line for melee-only selections ordered on it: `Can't reach flying units` (message) | |
| Selection panel | `Mounted` / `Flying` / `Titan` tags in the stat line; `Charge ready`; the Mammoth / Treant specials as ability icons with cooldowns (howdah, Seedlings) | |
| Champion bar | A 12 x 12 horse icon on the portrait while riding; tooltip `Riding (+1.8 speed)` | |
| Titan warnings | Messages of 3.4 (red for the enemy's), a horn sound; enemy titans on the minimap as a 7 x 7 pulsing diamond in the enemy colour | |
| Tavern window | Champion row: `Roan Courser: owned` / `buys a mount at level 3` | |
| Help text | Adds `Tab: ride / dismount    N, M: Stables, Lair (build menu)    V: Treant root` | |
| Audio (ui-coder) | Charge horn (own charges on screen, max 1 / 2 s), mount whinny / snort, dragon roar on breath (max 1 / 4 s), Mammoth trumpet on trample start, root creak, titan warning horn | SFX bus |
| Settings | Skirmish options **Cavalry and mounts: On / Off**, **Titans: On / Off** (default On) | Set `Skirmish.cavalry_enabled` / `titans_enabled` before the scene enters the tree |
Keys (physical, for the lead's Keys line): **Tab** = ride / dismount (player's wizard, always); build menu **N** = Stables,
**M** = Lair; Stables selected **Z** cavalry, **X** mount, **C** barding; Lair selected **Z** titan; Treants selected **V** root /
uproot. Tab must be consumed before Godot's focus navigation (`set_input_as_handled`, controls `focus_mode` none).

## 9. The bot (ai; extends `ai.md`, knobs in `AIProfile` / `data/ai/*.tres`)
### 9.1 Build, train, mix
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `stables_time` (row 8 Stables T2: after X1 completed or at this time; crystals >= 175 + 100, soldier pop >= 8) | 9:00 | 6:00 | 5:00 |
| `lair_time` (row 9 Lair T3: Stables completed, X1 completed, soldier pop >= 14, crystals >= 300 + 200) | never | 9:00 | 8:00 |
| `titan_share` (mix index 5) | 0 | 0.20 | 0.25 |
| `titan_min_soldier_pop` (no titan below it) | - | 12 | 10 |
| `mount_buy` (wizard mount at level 3, crystals >= 150 + 100) / barding (level 5, crystals >= 200 + 150) | never / never | yes / no | yes / yes |
| `titan_retreat_hp` (a titan below this goes home alone) | 0.35 | 0.35 | 0.30 |
- Mix arrays grow from 4 to **6** entries: index 4 = cavalry (Stables), index 5 = titan (Lair). Defaults (hall shares are
  scaled by `1 - cav - titan`): cavalry **0.15** default / **0.25** vs ranged / **0.05** vs melee (Nature 0.10 / 0.20 / 0.05);
  titan share only once a Lair exists. The trainer picks the building of the chosen type (Hall, X1 hall, Stables, Lair).
- **Counter-mix** (enemy titans in memory, applied after the table; first match wins):
| Seen | Change |
|---|---|
| >= 1 Cinder Dragon | Ranged share >= **0.55** of soldiers (x 0.70 when >= 3 dragons), cavalry 0, own Knights 0 (they cannot hit air); an S2 tower now if missing; Ice / Nature keep their titan share (howdah / volley) |
| >= 1 Nightmare Knight | Line share >= **0.45**, cavalry 0.05; Ice hard: 2 walls at S1 as `kingdom-ice.md` 7 |
| >= 1 War Mammoth | Cavalry **0.30**; Fire: Ash Hurler share +0.10 |
| >= 1 Elder Treant | Fire: Ash Hurler +0.15; others cavalry 0.25 (catch it walking) |
- Strength: titans `cost x 1.5`; cavalry as soldiers (`cost x (0.8 + 0.2 x level)`).
- Messages the bot reads: `Events.titan_event` (3.4) puts the titan type in memory as "seen" for the counter-mix at once
  (the warning is public information).

### 9.2 Titans and the bot wizard
| Rule | Action |
|---|---|
| Titan behaviour | Joins attack groups and defences like a soldier; below `titan_retreat_hp` it walks home alone and rejoins at 85 % (keep heal applies to heroes only: titans heal only by Treant / Bloomtender / items) |
| Treant | Roots when rule 1 (defend) fires within 20 m of its building, or when its attack group attacks a building and no enemy unit is within 12 m; uproots when the group moves on |
| Dragon | Never ordered onto a target with >= 2 enemy towers within 11 m (reads its memory) |
| Knight | Attack-moves with the group; the bot does not micro charges |
| Wizard mount | Buys per the table. Rides (`command_toggle_mount`) when going >= 25 m to the anchor, the rally, the crown or home hurt and `can_mount() == ""`; dismounts when an enemy is within 14 m or on arrival. Never rides inside a fight |

### 9.3 Champion brain hooks (ai: `ChampionBrain`)
| Id | Rule |
|---|---|
| M1 Buy | R7 entry of 6.3 |
| M2 Ride | Owns a courser, `can_mount() == ""`, no visible enemy within engage radius + 4 m, and its R6-R9 destination >= **25 m** away -> mount (intent text unchanged; the bar shows the horse icon) |
| M3 Dismount | Within 10 m of the destination; a visible enemy within engage radius; R4 fires; an ability wants to cast; Guard / Escort service in range |
| M4 Flee | R2: tries to mount (works only if not hit for 3 s), else runs on foot |
| Hunt utility | Titans are worth `cost x 1.5` in danger checks; the Oathwall's taunt skips titans; bot hard adds **B8**: an enemy titan seen within 30 m of its base -> Hunt 150 on it |

## 10. Art list (tech-artists; `art-units.md` style: chunky, silhouette = role, painted shaders, 1-2 glow points at 40 m)
Split into small sub-elements, one agent each. Budgets: cavalry unit = Blaze Rider (<= 20 parts, <= 12 draw instances after the
merge, 0 lights, <= 1 particle system of <= 10); mount = <= 12 meshes / <= 8 draw instances; titan = <= 36 meshes / <= 20 draw
instances, 0 lights, <= 2 particle systems (stopped beyond 45 m); building = hall budget. Kit metas and the instance-uniform slot
table (`art/units/kit/README.md`) apply to every scene.
| Id | Asset | Silhouette (40 m black test) and look | Hooks |
|---|---|---|---|
| 13.V1a | **MountModel** base (kit, new file `art/units/kit/mount_model.gd`) | Quadruped pivots (Root, Body, Neck/Head, 4 legs, Tail), gait at `stride_speed`, gallop, idle, hit, death (fall on side), team saddle-cloth recolour, `Seat` marker | `set_moving`, `play_hit`, `play_death` + `death_finished`, `set_team_color`, `set_barded(on)`, `play_charge()`, `seat_transform()` |
| 13.V1b | **Seated rider** in `CharacterModel` (after 11.V1) | Seated pose (legs astride, hips locked), riding idle, rider bob synced to the mount gait, hop-on / hop-off (0.3 s), thrown (0.5 s tumble) | `set_seated(on, mount: Node3D)`, `play_mount()`, `play_dismount()`, `play_thrown()` |
| 13.V2 | Ember Boar (+ barding) | Extract the Blaze Rider's boar into a MountModel; barding = bronze face plate + flank plates (toggle) | as V1a |
| 13.V3 | Dusk Steed (+ barding) | Gaunt tall black horse, violet eye glow, smoky mane (static cones), tattered caparison; barding = tarnished silver chanfron | as V1a |
| 13.V4 | Rimehorn (+ barding) | Woolly rhino, one huge ice-plated horn, frost on the back; barding = silver-blue plates | as V1a |
| 13.V5 | Grove Stag (+ barding) | Giant mossy stag, **wide antlers with 3 glowing blossoms** (the read), bark hooves; barding = woven bark plates | as V1a |
| 13.V6 | Roan Courser | Stocky neutral horse, saddlebags, bedroll, team saddle-cloth only | as V1a |
| 13.V7 | Gloam Rider | Hooded lancer, long barbed lance with a violet pennon, on the Dusk Steed | unit hooks + `lance_charge` attack |
| 13.V8 | Rimehorn Rider | Fur-armored axeman with a round ice shield on the Rimehorn | unit hooks, `great_swing` |
| 13.V9 | Stagrunner | Light rider, bark shortspear, leaf cloak, on the Grove Stag | unit hooks, `lance_charge` |
| 13.V10 | Blaze Rider refresh | Use the shared Ember Boar (V2), charge pose (lance level, mane flare) | unchanged hooks + `play_charge` |
| 13.V11 | Wizards riding | Vessa, Malrik, Torvald, Ysolde on their mounts: seat offsets, cape / staff / crown clearance, riding idle, cast-hop-off check | per wizard scene |
| 13.V12 | Champions riding | Wayfinder (lantern pole!), Oathwall (door shield on the back), Coin-Cutter, Mender (backpack) on the Roan Courser, with each class weapon | per champion scene |
| 13.V13 | **Cinder Dragon** body + flight rig (own `flyer_model.gd` in its folder) | Long neck, horned crown, **huge wings (span 7 m)** = the read; black-red scales with glowing lava seams; tail with a flame spade. Pivots: Body, Neck (2), Head + Jaw, WingL / WingR (2 segments each), Tail (3), 4 legs tucked. Hover bob, flap cycle 1.2 s, glide when straight, bank on turns, breath pose (jaw open 0.6 s), death = spiral fall + crash | `set_moving`, `set_turning(rate)`, `play_attack` (= breath), `play_hit`, `play_death`, `set_team_color` (wing membrane tint) |
| 13.V14 | Dragon VFX | Breath cone (60 deg, 6 m, 0.6 s, billboards + sparks), burning-ground patch (r 2, 3 s, decal + low flames), ember trail while flying (< 45 m), crash dust | `TitanVfx.play(&"dragon_breath" / &"burning_ground" / &"dragon_crash", at, target)` |
| 13.V15 | **Nightmare Knight** | Tall jagged black plate, violet flame crest, long lance, on a huge gaunt nightmare horse with burning violet hooves and a smoke mane; charge = lance level, smoke trail | unit hooks, `play_charge`, gallop smoke toggle |
| 13.V16 | **War Mammoth** body | Shaggy blue-grey mammoth, **long ice-capped tusks** = the read, frost mist at the feet, trample gait (4 legs, trunk swing) | unit hooks, `play_trample` |
| 13.V17 | Mammoth howdah + frost archer | Timber-and-ice howdah with a team banner and a hooded archer (own pivots: ArmR draw) on the Mammoth's back (child scene) | `play_howdah_shot()` |
| 13.V18 | **Elder Treant** (both forms) | Ancient walking tree 4 m, bark face with green eye glow, branch arms, moss beard, blossom crown; **rooted**: legs sink and spread into roots, arms lift into a canopy with glowing seed pods (3 s morph) | unit hooks, `set_rooted(on)` (3 s), `play_volley()` |
| 13.V19 | Titan VFX (non-dragon) | Mammoth frost aura ring (r 5), trample dust + ice shards, howdah bolt; Treant root morph dust, grove aura pulse (r 8, every 4 s), thorn volley, sapling sprout; Knight charge impact + knockback dust | `TitanVfx.play(id, at, target)` |
| 13.V20 | Cavalry VFX | Charge streak + impact ring, lifesteal wisps (Gloam, Knight), mount / dismount puff, thrown-off dust, rider speed lines | `CavalryVfx.play(id, at, target)` |
| 13.V21-13.V24 | **Stables** x4 (Ember, Gloom, Frost, Grove) | Long low stable with half-doors, hay loft hoist (dominant), paddock fence with a hitching post; kingdom materials (Fire bronze + ember lanterns, Shadow iron + violet lanterns, Ice timber + ice roof, Nature living hedge) | building hooks + `play_trained()` (doors swing) |
| 13.V25 | **Dragon Roost** | Basalt spire 9 m with a **nest crown** of charred beams on top (dominant), lava seams, a perch ledge | building hooks + `play_raise()` (lava flare) |
| 13.V26 | **Dread Paddock** | Black iron-fenced yard, a tall spiked gatehouse (dominant), violet torches, smoke from the stalls | same |
| 13.V27 | **Glacier Den** | Ice cave mouth in a snow mound under a **tusk arch** (dominant), icicles, frost mist | same |
| 13.V28 | **Elder Circle** | A ring of 6 standing trees around a glowing root knot; the tallest tree 8 m (dominant) | same |
| 13.V29 | Icons (phase 2) | 4 cavalry, 4 titans, 5 mounts, barding, ride / dismount, root / uproot, charge, flying tag, 4 Stables, 4 Lairs, minimap titan diamond | existing icon pipeline, new files only |
Paths: `art/units/kit/mount_model.gd`, `art/units/mounts/<id>/`, `art/units/<kingdom>/<cavalry>*`, `art/units/titans/<id>/`,
`art/buildings/stables/<kingdom>/`, `art/buildings/lair/<kingdom>/`, `art/vfx/titan_*`, `art/vfx/cavalry_*`,
`art/vfx/titan_vfx.gd` (`class_name TitanVfx`, group `"titan_vfx"`), `art/vfx/cavalry_vfx.gd` (`CavalryVfx`, group `"cavalry_vfx"`).

## 11. Performance
- New logic < **0.1 ms per frame** on average: charge tracking = one float per mounted unit (distance run); flyer movement is a
  straight step; TitanAbilities tick every 0.25-0.5 s, staggered; aura / trample / breath queries use one pass over the cached
  `"units"` list within radius (no physics queries); burning-ground patches max 12 alive, one timer each.
- A riding hero adds one mount model (<= 8 draw instances). Titans: 2 particle systems each, stopped beyond 45 m.
- Perf test additions: 8 cavalry (2 per kingdom), 4 titans (incl. 2 dragons breathing), 2 riding heroes, on top of today's
  load: `PERF OK`, stuck = 0.

## 12. Campaign
- Missions 1-3 unchanged (`cavalry_enabled` and `titans_enabled` false). Proposed: **mission 4** introduces the Stables and
  Vessa's Ember Boar ("ride to the far shrine before the bridge falls"); a later Fire mission, "Egg of Embers", unlocks the
  Dragon Roost (hatch and defend the egg, then the first Cinder Dragon). Enemy campaigns can field Knights / Mammoths as bosses.
- Not carried between missions: wizard mounts, barding, titans. The champion companion keeps its Roan Courser (save key
  `companion.mount`, optional, default none).

## 13. Balance
### 13.1 Cavalry per crystal (`kingdom-ice.md` 9: CE = EHP x DPS / cost^2 x 100; PE = EHP x DPS / pop^2 / 100)
| Unit | EHP | DPS | Cost | Pop | CE | PE | Speed | Note |
|---|---|---|---|---|---|---|---|---|
| Blaze Rider | 220 | 20.0 | 180 | 2 | 13.6 | 11.0 | 7.5 | + charge 18 |
| Gloam Rider | 252 | 17.8 (+20 % drain) | 185 | 2 | 13.1 (~15 with drain) | 11.2 | 7.2 | |
| Rimehorn Rider | 360 | 16.7 | 210 | 2 | 13.6 | 15.0 | 6.0 | + chill charge |
| Stagrunner | 180 | 17.5 | 160 | 2 | 12.3 | 7.9 | 7.8 | + regen, root charge |
| Bramblehorn / Shadow Knight (reference) | 380 / 480 | 15.0 / 18.6 | 200 / 260 | 2 / 3 | 14.3 / 13.2 | | | |
Against line infantry (anti-mount +50 %) every cavalry's CE drops to ~9: a line of equal cost wins clearly.

### 13.2 Titans
| Titan | EHP (vs its prey) | EHP (vs its counter) | DPS | CE (prey / counter) | PE | Speed |
|---|---|---|---|---|---|---|
| Cinder Dragon | infinite vs melee | 700 vs ranged / towers | ~11 per unit hit (7.3 breath + 4 ground), 2-3 units = ~28 | - / 4.0 (archers vs air: 10.5) | 10.9 | 5.5 fly |
| Nightmare Knight | 845 galloping, 650 stopped | 433 vs line | 23.3 + 30 % drain (~30) + 90 per charge | 15.8 / 8.1 | 15.8 | 8.0 |
| War Mammoth | 2600 | 1730 vs fire, 2300 vs Lance | 18.2 + howdah 6.7 + trample + aura (~25) | 15.4 / 10.2 | 18.1 | 3.4 |
| Elder Treant (rooted) | 2080 | 1390 vs fire | volley 10 + Saplings ~18 (~28) + aura | 16.2 / 10.8 | 16.2 | 3.8 / 0 |
Titans are **worse per crystal** than line infantry (square law: one big body), better per pop than ranged, and carry a special
(air, charge, siege, sustain) that decides fights against the wrong army. Mass titans win only against an army that did not adapt.

### 13.2b Duel bands (the target; 13.C9 builds the harness, 13.D3 tunes to these bands)
Level 1 / Recruit, no items, no wizards, open ground, both sides attack-move from 20 m, no kiting. "Win" = last unit standing.
| # | Duel | Expected | Pass band |
|---|---|---|---|
| D1 | 1 Blaze Rider vs 2 Flame Guards | Guards win | 1 guard left |
| D2 | 1 Blaze Rider vs 2 Ember Archers | Rider wins | rider >= 50 % HP |
| D3 | 1 Rimehorn Rider vs 1 Blaze Rider | Close | winner <= 40 % HP |
| D4 | 1 Cinder Dragon vs 8 Flame Guards | Dragon untouched | dragon 100 %, all guards dead < 60 s |
| D5 | 1 Cinder Dragon vs 7 Ember Archers (700) | Archers win | 2-4 archers left |
| D6 | 1 Cinder Dragon vs 1 Ember Spire (tower alone) | Tower wins | tower >= 30 % HP |
| D7 | 2 Nightmare Knights vs 9 Flame Guards (810) | Guards win | >= 4 guards left |
| D8 | 2 Nightmare Knights vs 8 Ember Archers | Knights win | >= 1 knight at >= 50 % |
| D9 | 1 War Mammoth vs 8 Shades (880) | Mammoth wins | mammoth 25-60 % HP |
| D10 | 1 War Mammoth vs 4 Blaze Riders (720) | Riders win (Lance + fire) | >= 2 riders left |
| D11 | 1 Elder Treant, rooted, vs 1 Cinder Dragon | Treant wins (volley x2 on air) | treant >= 40 % |
| D12 | 1 Elder Treant, walking, vs 8 Flame Guards (fire) | Guards win | >= 3 guards left |
| D13 | 1 Elder Treant, rooted with 3 Saplings, vs 8 Shades (880) | Treant wins | treant >= 20 % |
| D14 | Riding Vessa (6.6) chased by 1 Blaze Rider from 6 m | Caught | within 25 m |
| D15 | Riding Vessa chased by 1 Flame Guard from 3 m | Escapes | gap >= 10 m after 10 s |
| D16 | Keep (2 500 HP) vs 1 Cinder Dragon attacking it | Keep wins | dragon dead, keep >= 50 % |
| D17 | 1 War Mammoth vs an undefended Ember Spire | Spire falls fast | < 25 s |

### 13.3 Timing and game length
| Side | Stables | Lair | First cavalry | First titan |
|---|---|---|---|---|
| Normal bot | 6:00-7:00 (after X1) | 9:00-9:30 | ~7:00 | ~11:00-12:00 (after saving 400-700) |
| Hard bot | 5:00 | 8:00 | ~5:45 | ~10:00 |
| A player rushing | ~2:00 | 8:00 (gate) | ~2:40 | ~10:15 (Knight 9:55) |
- **Not shorter**: 475 crystals of tech (about 5 soldiers) before the first titan; the Blaze Rider (Fire's early raider)
  now sits behind 175 crystals and 50 s; titans hit buildings at x0.5 (except the Mammoth, which is 3.4 m/s and fire-weak);
  the enemy is warned at training start and sees titans on its minimap; anti-mount makes cavalry trades worse against the
  main line. Mounts are travel-only: defenders arrive sooner (a small lengthening). Expected effect on the median bot-vs-bot
  length: **+0:00 to +1:00**. While games still end at ~11:00 (the step-9 champion snowball), titans will appear in few bot
  games: acceptable; do not lower the 8:00 gate to make them show up.
- **Mass titans** (no cap): at 40 pop, 5 Cinder Dragons (3 500 crystals, 30 pop) beat an unadapted 40-pop army (30 % ranged)
  but lose to one that shifted to >= 55 % ranged plus 2 towers (square law: 2 200 crystals of archers vs air = 50.8 M vs the
  dragons' 49 M: about even, and the towers, the wizard's spells and the dragons' slow turns decide it). The bot's counter-mix does that shift; players read the warning. Mass Knights lose to a line-heavy army;
  mass Mammoths are slow enough to be raided elsewhere; mass Treants must root to be strong and then cannot move.
- **Fire bias watch**: Fire gets the flyer and deals x1.5 to two enemy titans, and Fire already wins 11 / 12 of its games
  (`balance-2.md` Results). If step-13 runs confirm Fire > 60 % wins, use the Fire knobs below first.
- **Nature watch**: the Treant adds sustain to the kingdom that out-sustains everyone (`balance-2.md` D1): grove aura +4 is
  the first knob.

### 13.4 Knobs (one at a time, 13.D3)
| Symptom | Knob |
|---|---|
| Games shorter with titans than the `--no-titans` control | Lair `min_time` 8:00 -> **9:00**; titan train times +15 s |
| Mass dragons dominate | Dragon cost 700 -> **800** or breath 16 -> **14**; ranged / tower vs air x2.0 -> **x2.5** |
| Dragons never built / always die | Dragon HP 1400 -> **1600** |
| Knights dominate | Charge 90 -> **70**; lifesteal 30 -> **20 %** |
| Mammoths end games | Siege x2.0 -> **x1.5** |
| Treant sustain too strong | Grove aura +4 -> **+2**; Seedlings every 15 -> **20 s** |
| Fire > 60 % wins | Fire weakness x1.5 -> **x1.25**; Blaze Rider back to 30 -> **34 s** train |
| Cavalry too strong early | Stables cost 175 -> **200**; anti-mount +50 % -> **+75 %** |
| Mounts make heroes unkillable | Speed cap 7.5 -> **7.0**; mounting refused within 3 -> **5 s** of damage |
| Nobody buys mounts | Mount price 150 -> **100**; level 3 -> **2** |

### 13.5 Re-test plan (lead 13.L2, then 13.D3)
Harness: the `balance-2.md` / 10.L2 bot-vs-bot run (normal, cap 24:00) with new flags `--no-titans` and `--no-cavalry` as
controls, plus the duel harness (13.C9).
| Round | Runs | Pass |
|---|---|---|
| A | 6 pairs x 2 with everything, 6 x 1 `--no-titans` | Median length with titans >= control - 0:30; no kingdom wins > 70 % of its runs |
| B | Same logs | Every kingdom trains >= 3 cavalry per game after 7:00; titans in >= 30 % of games that pass 11:00; each titan type dies at least once to its hard counter across the runs |
| Duels | 13.C9 | D1-D17 inside their bands |
| Perf | perf test with the section 11 additions | `PERF OK`, stuck = 0 |

## 14. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 13.L1)
Rule for phase-1 agents: never use another step-13 agent's new `class_name` as a static type; reach it with `load()` guarded by
`ResourceLoader.exists`, groups, `has_method()`, `get()` (as steps 9-11).
- **UnitType** (gameplay), new group `"Cavalry and titans"`: `tier: int = 1`, `tags: Array[StringName] = []` (`&"mounted"`,
  `&"titan"`, `&"flying"`), `charge_bonus := 0.0`, `charge_run := 5.0`, `charge_cooldown := 8.0`, `charge_status: StringName`,
  `charge_status_duration := 0.0`, `charge_knockback := 0.0`, `bonus_vs_mounted := 0.0`, `damage_taken_mult: Dictionary = {}`
  (keys `&"melee"`, `&"ranged"`, `&"tower"`, `&"spell"`, `&"dot"`, `&"fire"`, `&"mounted"`), `building_damage_mult := 1.0`,
  `attack_shape: StringName = &""` (`&""` single, `&"cone"`), `attack_arc_deg := 0.0`, `fly_height := 0.0` (> 0 = flying),
  `turn_rate_deg := 0.0` (0 = instant), `base_stats: Dictionary = {}` (modifier `type:<id>`, e.g. `{"lifesteal": 30}`),
  `specials: Dictionary = {}` (special id -> params, read by TitanAbilities: `&"burning_ground"`, `&"gallop_armor"`,
  `&"howdah"`, `&"frost_aura"`, `&"trample"`, `&"take_root"`, `&"grove_aura"`, `&"seedlings"`). New `.tres`: `gloam_rider`,
  `rimehorn_rider`, `stagrunner`, `cinder_dragon`, `nightmare_knight`, `war_mammoth`, `elder_treant`; `blaze_rider` gains
  the cavalry fields; `flame_guard`, `shade`, `rimeshield`, `thornling` get `bonus_vs_mounted` 0.5.
- **Unit** (gameplay): `has_tag(tag) -> bool`, `is_mounted() -> bool` (tag, or a riding MountRider), `is_flying() -> bool`,
  `is_titan() -> bool`, `can_hit(target: Node3D) -> bool` (flyers only by ranged / towers / spells), `static damage_kind_of(attacker:
  Node, via_spell := false) -> StringName`, `take_typed_damage(amount: float, attacker: Node3D, kind: StringName) -> void`
  (applies 3.1 then `take_damage`; plain `take_damage` infers the kind from the attacker, so old callers keep working),
  `apply_knockback(from: Vector3, distance: float)`, `charge_ready() -> bool`, signal `charged(unit, target)`.
  Projectiles, towers (`building_gun.gd`), SpellCaster, ChampionAbilities, DoTs and TitanAbilities call `take_typed_damage` with
  their kind. `MAX_UNIT_RADIUS` 0.7 -> **1.1**, new `MAX_COLLISION_RADIUS := 0.8`. Auto-target and attack orders respect
  `can_hit`. Titans: `hero_mult` for CC, `taunted` immune, `can_gain_veterancy()` false.
- **TitanAbilities** (`scripts/units/titan_abilities.gd`, `class_name TitanAbilities extends Node`, child `"TitanAbilities"`
  created by `Unit._ready` when `unit_type.specials` is not empty and the script exists): `setup(unit)`, `is_rooted() -> bool`,
  `root_progress() -> float`, `saplings() -> Array`, signals `special_fired(unit, id: StringName)`, `rooted_changed(unit, on)`.
  **Unit** gains `command_root(on: bool) -> String` (`""`, `"Cannot root"`, `"Too close to a building"`, `"Busy"`) for types
  with `&"take_root"` (the UI checks `has_method` + the type).
- **MountType** (`scripts/units/mount_type.gd`, Resource, `data/mounts/<id>.tres`, ids of 6.1): `id`, `display_name`,
  `kingdom: StringName` (`&"neutral"` = champions), `price_crystals`, `price_gold`, `price_purse`, `level_required`,
  `speed_bonus`, `barding_price_crystals`, `barding_price_gold`, `barding_level`, `barding_speed`, `barding_armor`,
  `mount_time`, `barded_mount_time`, `seat_height`, `model_path`; `static find(id)`, `static for_kingdom(kingdom)`.
- **MountRider** (`scripts/units/mount_rider.gd`, `class_name MountRider extends Node`, child `"MountRider"` of every Wizard and
  Champion, created in `_ready` if the script exists, like SpellCaster): `setup(unit)`, `mount_type: MountType`, `barded: bool`,
  `has_mount()`, `is_riding()`, `is_mounting()`, `mount_progress() -> float`, `give_mount(id: StringName)`, `give_barding()`,
  `can_mount() -> String` (6.2 order), `mount() -> String`, `dismount(thrown := false)`, `remount_cooldown_left() -> float`,
  `buy_with_purse(id: StringName, shop: Node) -> String` (champions: `"Needs level 3"`, `"Already owned"`, `"Not enough coin"`,
  `"No mounts here"`), `get_save_state()` / `apply_save_state(d)`, constants `SPEED_CAP := 7.5`, `COMBAT_LOCK := 3.0`,
  `THROWN_COOLDOWN := 10.0`, signals `riding_changed(unit, on: bool)`, `mount_given(unit, id)`. Modifier id `mount`.
- **Wizard**: `mount_rider: Node`, `command_toggle_mount() -> String` (`""` or the reason; dismounts when riding);
  `command_cast` / `command_attack` / `command_attack_move` dismount first (0.3 s). **Champion**: `mount_rider`, save keys
  `mount`, `barded`; companion `mount`.
- **Stables** (`scripts/buildings/stables.gd`, `class_name Stables extends TrainingBuilding`, kind `&"stables"`, group
  `"stables"`): `static of_team(team) -> Stables` (completed, alive, or null), `mount_for(wizard) -> MountType`,
  `can_buy_mount(wizard, pay_gold := false) -> String`, `buy_mount(wizard, pay_gold := false) -> String`,
  `can_buy_barding(wizard, pay_gold := false) -> String`, `buy_barding(wizard, pay_gold := false) -> String`, signal
  `mount_sold(team: int, id: StringName)`. The tavern answers `sells_mounts() -> bool` (true) for champions.
- **BuildingType / BuildGrid**: kinds `&"stables"`, `&"lair"`; `ALL_IDS` gains the 8 ids; new field `min_time := 0.0`;
  `requires_kind` chain (stables <- barracks, lair <- stables); messages `MSG_NEEDS_STABLES := "Needs completed Stables"`,
  `MSG_MIN_TIME := "Available at %d:%02d"`, limits `"Only one Stables"`, `"Only one Lair"`. `TrainingBuilding.trainable_types()`
  leaves out `mounted` types on barracks while `cavalry_enabled` (missions keep the Blaze Rider in the Ember Hall; the `.tres`
  is unchanged).
- **Skirmish**: `@export var cavalry_enabled := true`, `@export var titans_enabled := true` (missions false; BuildGrid refuses the
  buildings with `"Not in this mission"`), `stables_slot(team)`, `lair_slot(team)` (T2 / T3).
- **Events** (lead): `titan_event(team: int, type_id: StringName, what: StringName)` (`&"training"`, `&"ready"`, `&"fallen"`),
  emitted by TrainingBuilding / Unit. `rider_changed` is not global (MountRider signal).
- **AIProfile**: mix arrays have **6** entries; new knobs of 9.1 (`stables_time`, `lair_time`, `titan_share`,
  `titan_min_soldier_pop`, `mount_buy`, `barding_buy`, `titan_retreat_hp`). `.tres` files with 4-entry mixes are padded
  `[.., 0.15, 0.0]` at load.
- **Models / VFX**: hooks of section 10; `CharacterModel.set_seated(on, mount)`, `play_mount`, `play_dismount`, `play_thrown`;
  `MountModel` (`art/units/kit/mount_model.gd`); `TitanVfx.play(id, at, target)` (group `"titan_vfx"`), `CavalryVfx.play(id, at,
  target)` (group `"cavalry_vfx"`); callers use `get_first_node_in_group` then `.play`.
- **Keys** (lead's Keys line): section 8.
- **Ownership**: `data/mounts/`, `scripts/units/mount_type.gd`, `mount_rider.gd`, `titan_abilities.gd` = gameplay;
  `scripts/buildings/stables.gd`, `data/buildings/*_stables.tres`, `*_lair.tres` = systems; `art/units/mounts/`,
  `art/units/titans/`, `art/units/kit/mount_model.gd`, `art/buildings/stables/`, `art/buildings/lair/`, `art/vfx/titan_*`,
  `art/vfx/cavalry_*` = tech-artists.

## 15. What changes in other specs
`units-fire-shadow.md`: Blaze Rider trains at the Ember Stables in the skirmish (Ember Hall in missions), gains the cavalry
fields. `buildings.md`: Stables and Lair rows, Ember Hall slots Z X C in the skirmish, build menu N / M, the two messages. `kingdom-ice.md` / `kingdom-nature.md`: Frost / Grove Stables and
Lairs, Rimehorn Rider, Stagrunner, the titans; Ice's speed line. `levels.md`: victim rows (Gloam 95, Rimehorn 105, Stagrunner 80,
titans cost / 2, Stables 90, Lair 150). `ai.md`: build rows 8-9, mix index 4-5, counter-mix, titan and wizard-mount rules.
`champions.md`: R7 mount entry, M1-M4, B8, companion mount; Spear class anti-mount. `skills-rework.md`: Spear `bonus_vs_mounted`.
`ui-hud.md`: hero-column mount button, keys, help text. `market-trade.md`: gold as an alternative payment for mounts / barding.
`fog-of-war.md`: titans on the enemy minimap. `CLAUDE.md` (lead): section 14 contracts, Keys, owner rows.

## 16. Task list (step 13)
Shared files still in flight in steps 10-12 decide the phases: `unit.gd`, `wizard.gd` (13.C1 / C4), `champion.gd` (11.C1),
`champion_abilities.gd` (11.C2), `champion_brain.gd` (10.A3, 11.A1), `commander.gd` / `ai_profile.gd` (10.A3, 12.*),
`building_type.gd` / `build_grid.gd` / `training_building.gd` (10.C2, 12.*), `skirmish.gd` (10.C1, 12.*),
`character_model.gd` (11.V1), `command_card.gd` / `selection_manager.gd` / `selection_panel.gd` / `hud.gd` / `minimap.gd` /
`champion_bar.gd` / `tavern_window.gd` (10.C7, 10.C8, 11.C4, 12.*). A step-13 task that edits one of them starts only after the
last step 10-12 task on that file is merged.
**Phase 0:** 13.L1, 13.D2. **Phase 1a (new files only, can start as soon as 13.L1 is in):** 13.V1a, 13.V2-13.V6 (after V1a),
13.V13-13.V20 (V17 after V16), 13.V21-13.V28. **Phase 1b (after the shared files are free):** 13.C1, 13.C3, 13.C4, 13.C5,
13.C6, 13.V1b, then 13.V7-13.V12 (need their mount scene and V1b). **Phase 2:** 13.C2 (needs 13.C1's fields), 13.A1, 13.A2, 13.U1, 13.U2, 13.V29, 13.C7,
13.C8, 13.C9, then 13.L2, then 13.D3 after the playtest.
| Id | Agent | Task | Files | Done when |
|---|---|---|---|---|
| 13.L1 | lead | Freeze section 14 in `CLAUDE.md`, Keys (Tab, build menu N / M, Stables Z X C, Lair Z, Treant V), owner rows, `Events.titan_event`, step-13 agent rules, ids in `waves.md` | `CLAUDE.md`, `docs/plan/`, `scripts/core/events.gd` | Contracts and keys in CLAUDE.md; signal exists; rules file written |
| 13.D2 | ui-designer | Layouts at 1600 x 900 for section 8 (build menu, Stables / Lair cards, hero-column mount button, charge pip, Treant root, titan warnings and minimap diamond, champion horse icon, tavern line, settings) | `docs/design/ui-cavalry.md` | Every element of section 8 has position, size, look, consistent with `ui-style.md` |
| 13.C1 [H] | gameplay-coder-high | UnitType fields; Unit tags, damage kinds + `take_typed_damage`, fire / mounted multipliers, anti-mount, Lance, charge (run tracking, bonus, status, knockback, denial), `apply_knockback`, flying movement (straight, height, turn rate, clamp, flyer avoidance layer, click capsule), `can_hit` in auto-target / orders, cone attack, titan CC rules, radius constants; kinds passed by projectiles, SpellCaster, ChampionAbilities, DoTs | `scripts/units/unit_type.gd`, `unit.gd`, `projectile.gd`, `champion_abilities.gd` (kind arg only), `scripts/spells/*` (kind arg only) | Test: a Flame Guard deals 18 to a Blaze Rider; a Blaze Rider's charge hit after 5 m deals 36 and none within 8 s or after a chill; Lance: 18 on a Rimeshield = 16.7 (armor 7.5); a melee unit cannot target a flyer and gets `"Can't reach flying units"`; an Ember Archer deals 18 to a flyer, a tower x2; a flyer crosses an Ice Wall line; cone hits only units within 60 deg / 6 m; a titan is frozen half as long and never taunted; old `take_damage` callers unchanged; `PERF OK` |
| 13.C2 | gameplay-coder | The 7 new unit `.tres` + Blaze Rider fields + 4 anti-mount units + Spear class `bonus_vs_mounted` | `data/units/*.tres`, `data/champion_classes/spear.tres` | Numbers of sections 4-5 exact; kill_xp as listed |
| 13.C3 [H] | gameplay-coder-high | TitanAbilities: burning ground, gallop armor, howdah, frost aura, trample, take root / uproot + `command_root`, grove aura, seedlings, lifesteal base stats, titan warnings (`Events.titan_event` on ready / fallen) | `scripts/units/titan_abilities.gd`, `unit.gd` (child creation + `command_root` only, after 13.C1) | Test: every row of 5.2 with its numbers; a rooted Treant grows a Sapling every 15 s, max 3; the Knight's armor is 30 at 5 m/s and 0 one second after stopping; burning ground ticks once per 0.5 s with 3 overlapping patches |
| 13.C4 [H] | gameplay-coder-high | MountType + 5 `.tres`; MountRider (rules 6.2, speed cap, thrown, crown rule, save state); Wizard `command_toggle_mount`, hop-off on cast / attack, no auto-attack while riding; Champion child + save keys | `scripts/units/mount_type.gd`, `mount_rider.gd`, `data/mounts/`, `scripts/units/wizard.gd`, `champion.gd` | Test: Vessa with an Ember Boar mounts in 1.0 s (0.5 barded), rides at 6.6 (7.1), refuses in the order of 6.2, is thrown by `rooted` with a 10 s cooldown, F while riding dismounts then casts, never auto-attacks riding, keeps the mount through respawn; speed cap 7.5 with Swiftsoles; a champion buys a courser for 120 purse (24 tithe) at level 3 |
| 13.C5 | systems-coder | 8 BuildingType `.tres`, `min_time`, `requires_kind` chain and messages, `Stables` (mount shop API, gold payment), Ember Hall without the Blaze Rider, tower kind `&"tower"`, titan `training` event, tavern `sells_mounts` | `scripts/buildings/stables.gd`, `building_type.gd`, `build_grid.gd`, `training_building.gd`, `building_gun.gd`, `data/buildings/*`, `scripts/world/tavern.gd` | Test: refusals in order (no Hall, no Stables, `Available at 8:00` at 7:59, second Stables); Stables trains its cavalry; `buy_mount` at level 2 -> `Needs level 3`, at 3 spends 150 (or 150 gold with Shift); in the skirmish the Ember Hall card is Guard Z, Archer X, Hurler C, in mission 1 it is unchanged (Blaze Rider after Brazier 2; `mission_01` tests still pass); a Lair queue emits `titan_event(training)` |
| 13.C6 | systems-coder | `cavalry_enabled` / `titans_enabled`, T2 / T3 slots, end-screen line `Titans raised 2 · lost 1`, companion mount in the campaign save, `--no-titans` / `--no-cavalry` flags plumbing | `scripts/world/skirmish.gd`, `scripts/campaign/campaign_state.gd` | Off = no Stables / Lair in the build menu (`Not in this mission`), no Tab; missions default off; companion `mount` saved and loaded, old saves fine |
| 13.A1 | ai-coder | Bot rows 8-9, 6-entry mixes, counter-mix, titan behaviour and retreat, Treant rooting, Dragon tower avoidance, wizard mount buy / ride, strength, knobs + `.tres` for 4 kingdoms x 3 difficulties | `scripts/ai/commander.gd`, `ai_profile.gd`, `data/ai/*.tres` | Headless normal: Stables 6:00-7:00, Lair 9:00-9:30, first titan by 12:30 when the game lasts; seeing a dragon raises ranged share >= 55 % within 2 ticks; bot wizard rides home when hurt and dismounts near enemies; easy never builds a Lair; `PERF OK` |
| 13.A2 | ai-coder | Champion brain M1-M4, R7 mount entry, titan danger, Oathwall taunt skip, B8 (hard) | `scripts/ai/champion_brain.gd`, `champion_sense.gd`, `ai_champions.gd` | A level-3 champion with 120 purse buys a courser at the nearest tavern / Stables; rides to a 40 m flag and dismounts 10 m before; never rides into visible enemies |
| 13.U1 | ui-coder | Everything in section 8 except audio (build menu N / M, Stables / Lair cards and tooltips, Tab and the hero-column button, charge pip, Treant V, flyer refusal message, selection panel tags, champion horse icon, tavern line, titan warnings, minimap diamond, settings toggles, help text) | `scripts/ui/command_card.gd`, `selection_manager.gd`, `selection_panel.gd`, `hud.gd`, `wizard_control.gd`, `minimap.gd`, `champion_bar.gd`, `tavern_window.gd`, `scripts/ui/menus/game_settings.gd` | As 13.D2; Tab never moves UI focus; nothing in `scripts/ui/` calls a `_private` function |
| 13.U2 | ui-coder | Audio of section 8 | `assets/audio/cavalry_*`, `assets/audio/titan_*`, `scripts/ui/hud.gd` (play calls) | Sounds on the SFX bus with their throttles |
| 13.C7 | gameplay-coder | Plug unit and mount models (`model_scene` / `model_path`), hooks `set_seated`, `play_charge`, `set_rooted`, `play_howdah_shot`, flyer model height | `data/units/*.tres`, `data/mounts/*.tres`, `scripts/units/` (hooks only) | Models replace placeholders; hooks fire on the right events; smoke `victory=true` |
| 13.C8 | systems-coder | Plug the 8 building models + `play_trained` / `play_raise` | `data/buildings/*_stables.tres`, `*_lair.tres`, `scripts/buildings/stables.gd` | Headless instantiation clean; hooks called |
| 13.C9 | gameplay-coder | Duel harness for 13.2b (`--duel=D5` or all), prints each result vs its band | `tests/test_13_duels.gd` | Runs D1-D17 headless and prints PASS / FAIL per duel |
| 13.V1a-13.V29 | tech-artist (one per id, section 10) | Section 10 | Section 10 paths | Each: silhouette check screenshot in `docs/art/screens/`, budgets held, hooks present, headless instantiation without errors, `KITFIX AUDIT OK` |
| 13.L2 | lead | Integration (TitanVfx / CavalryVfx nodes in both scenes), perf additions, runs of 13.5, playtest copy | `tests/`, `scenes/`, `docs/plan/` | Rounds A-B and duels pass; `PERF OK`; CI green |
| 13.D3 | game-designer | Balance from 13.L2 logs + playtest, knobs of 13.4 | `docs/design/cavalry-mounts.md` | Notes and knob changes written in section 13 |

## Done when (step 13)
- [ ] Every kingdom trains its cavalry at its Stables; the Ember Hall no longer trains Blaze Riders.
- [ ] Charge, Lance, anti-mount and the flying rules work as section 3; the duel harness passes D1-D17.
- [ ] Each kingdom raises its titan at its Lair from 8:00, without a count limit; warnings and minimap diamonds show.
- [ ] The player's wizard buys, rides (Tab) and loses the saddle by the rules of 6.2; champions buy and ride coursers on their own.
- [ ] Bots build Stables and Lairs, adapt their mix to seen titans, ride their wizard; normal bot-vs-bot median length is not
      shorter than the `--no-titans` control by more than 0:30.
- [ ] `PERF OK` with the section 11 load; smoke test `victory=true`; missions 1-3 unchanged.

# Second titans: Frost Dragon, Barrow Giant, the Wildcaller, the Ember Crucible, and a neutral Frost Wyrm

Task 13c.D1, written 2026-09-26. Source of truth for step 13c (tasks in section 15). User request (`waves.md` "Step 13c"):
every kingdom gets a **second tier-3 option at its Lair**. **Ice = Frost Dragon** (flying, freezing breath, built on the Cinder
Dragon's `FlyerModel` rig). For the three others the user set the kinds: one **rock-throwing GIANT** (mass-trainable, no cap),
one **WIZARD unique NPC** (one at a time, autonomous and friendly, the Mage Archer pattern), and one **BASE UPGRADE** instead of
a unit ("like it can make / units cost less; see if it's possible to balance first"). Plus a **neutral epic beast, the Frost
Wyrm** (5th epic beast, 2 variants, mirrored lairs, big rewards, same flyer rig): its rows are written here (section 7) for the
`map-fill.md` owner to merge. Every name, unit, number and rule here is our own. Metres, seconds, `m:ss` since the navmesh was
ready; positions `(x, z)` on Crown Hollow, player side, the enemy side is the point mirror `(-x, -z)`.
Builds on `cavalry-mounts.md` ("cm.": titans, Lairs, damage kinds, the flying rule 3.3, titan rules 3.4, `TitanAbilities`,
`FlyerModel`), `tier3-extras.md` ("t3.": the Mage Archer `unique_npc` path, Lair slot X, late-army table 9), `research.md`
("rs.": Citadel, Frostbite meter 3.3), `rush-balance.md` ("rb.": `UnitAbilities`, `frost_shell`, `bonus_vs_tags`, duel rules),
`map-fill.md` ("mf.": epic beasts 5.5), `champion-skill-tree.md` ("st.": the unique-NPC curve 2.1, Wizard tree 5.4),
`balance-2.md`, `levels.md`, `items.md`, `kingdom-ice.md` 9 (CE / PE formulas).

## 0. Decisions for the user (recommendation first; the rest of this spec assumes the recommendations)
| # | Question | Recommendation | Alternatives |
|---|---|---|---|
| Q1 | **Which kingdom gets which kind** (Ice = Frost Dragon is fixed) | **Fire = the BASE UPGRADE** (the *Ember Crucible*), **Shadow = the GIANT** (the *Barrow Giant*), **Nature = the WIZARD unique NPC** (the *Wildcaller*). Why: **Fire** is the strongest kingdom in every test (`balance-2.md`: 11 / 12 wins, `rb.` 12.1 expects "Fire > 55 %" first) and already owns the flashiest late roster (a flying dragon, massed musketeers, Pyre Adepts, a flying scout): it gets the option with the least raw fight power, the easiest one to tune with one number, and an industrial one that fits its forges and powder. **Shadow** already has a unique autonomous NPC (the Mage Archer): a second one would repeat the pattern and need a second unique slot in the UI; Shadow's "elite few" also lacks a cheap big body, so the massable Giant adds what it misses. **Nature** already has two big slow bodies (Elder Treant, Mossback): a giant would be a third; it has no hero-like unit and a free unique slot, so the druid NPC is new for it (and it must not heal armies: rs. Q3) | Fire = Giant, Shadow = upgrade, Nature = wizard (Fire gets stronger, not advised) · Nature = Giant, Shadow = wizard (two uniques for Shadow, three big bodies for Nature: not advised) |
| Q2 | **Form of Fire's base upgrade** (balance evaluated in 6.1-6.2) | **"The base makes"**: the *Ember Crucible*, lit once at the Dragon Roost (300 crystals, 75 s): while the Roost stands it **forges a free Flame Guard every 40 s** (pop counted, at most **6 forged Guards alive**). Its value is flat (the same for a rich or a poor side), bounded, visible and can be stopped by killing the Roost; it matches a titan's worth around 18-20 min | **"Units cost less"**: -15 % crystal cost on Fire soldiers pays back only at ~21:40 (a trap in a 15-20 min game); -30 % matches the Crucible's curve but grows without limit in long games, favours the richer side and makes Cinderlocks and Pyre Adepts 30 % cheaper (feeds the Fire bias). **Faster training** (-30 % train time): rejected, its value is unmeasurable before the tests and it shortens games |
| Q3 | **Is the Lair a choice (one option per match) or do both options stay open?** | **Both stay open** (no lock): the Lair trains its titan (Z), its 13b unit (X) and the 13c option (**C**), all paid, queued and countered normally. The "choice" is where the crystals go. Simple to read and to code; each option has hard counters | **Lock-in**: the first Z or C press at the Lair locks the other for the match (a real strategic choice, but a player who guessed wrong has no late answer; the bot needs a choice rule) |
| Q4 | **Where does the Frost Wyrm live?** | **Over the river**, on the frozen **Drowned Barge** (the existing landmark in each river half, 7): the only beast that flies, both banks can shoot it across the water, melee reaches it only when it lands; first spawn **13:00** (the titan era), respawn 12 min. The land flanks have no free spot that meets every `mf.` 5.5 clearance (checked, 7.2) | A land lair on the west flank after moving a rabbit home and the Heron Ford clearance rule (a map change for 12.C1's owner) |

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Where | Every 13c option is the Lair's slot **C** (r1c3): Glacier Den C Frost Dragon, Dread Paddock C Barrow Giant, Elder Circle C Wildcaller, Dragon Roost C Ember Crucible. Z stays the step-13 titan, X the 13b unit (Mossback / Mage Archer; empty at the Roost and the Den) | One key, one place: "C at the Lair = the second titan" for every kingdom |
| Gate | The Lair's own gate (the Citadel with research on, 8:00 with research off); the options need nothing more. Hidden while `Skirmish.titans_enabled` is false (missions) | One tier ladder, as step 13 / 13b |
| Cap | **No cap** on Frost Dragons and Barrow Giants; the **Wildcaller: 1 per team**; the **Crucible: once per Lair** | User decisions |
| Titan rules (cm. 3.4) | Frost Dragon and Barrow Giant are titans (tag `titan`: CC half, taunt and knockback immune, no veterancy, warnings, enemy minimap diamond, kill XP cost / 2). The Giant is the **cheap, massable** titan: 300 crystals, **pop 3** (the only titan under pop 4), 40 s | "Mass-trainable" = cheap and fast, not uncapped (all titans are uncapped) |
| Flying | Frost Dragon: the cm. 3.3 flyer rule exactly (ranged / towers x2, melee cannot hit). Frost Wyrm: the same rule while **airborne**, normal while **grounded** (a new runtime toggle, 13) | Reuse of the step-13 flyer code |
| Freezing | Frost Dragon and Frost Wyrm breath feed the **Frostbite meter** ungated (`add_frost(..., always = true)`, the Rifleman rule t3. 3) | One freeze system for all frost |
| Nature sustain (rs. Q3) | The Wildcaller **never heals** anyone: control and summons only | The Elder Treant stays Nature's one regenerating unit |
| Missions | 13c content follows `titans_enabled` (off); the Frost Wyrm follows the epic-beast toggle of `mf.` (skirmish only) | Missions 1-4 unchanged |

## 2. Where they come from (systems)
| Option | Building, slot (key) | Price | Pop | Time | Refusals (first that applies) | Queue |
|---|---|---|---|---|---|---|
| Frost Dragon | Glacier Den **r1c3, C** | 650 crystals | 6 | 85 s | Lair gate, `"Population cap reached"`, `"Not enough crystals"` | the Lair queue (5, shared with Z / X) |
| Barrow Giant | Dread Paddock **r1c3, C** | 300 crystals | 3 | 40 s | same | same |
| Call the Wildcaller | Elder Circle **r1c3, C** (then **Revive**) | 300 crystals + 150 essence | 4 | 45 s | Lair gate, `"Already called"` (queued, alive or fallen), pop, crystals, `"Not enough essence"` | same (a stub `UnitType`, t3. 15 pattern) |
| Light the Ember Crucible | Dragon Roost **r1c3, C** | 300 crystals | 0 | 75 s | Lair gate, `"Already lit"` (lit or queued), crystals | same (a stub `UnitType` with `grants_upgrade`, 13) |
- Tooltips:
  `Frost Dragon  [C]\nCost 650 crystals · Pop 6 · 85 s · Titan\nFlies. Its breath slows and freezes. Arrows and towers hurt it double.` ·
  `Barrow Giant  [C]\nCost 300 crystals · Pop 3 · 40 s · Titan\nHurls barrow-stones at range. Shrugs off arrows; weak up close and to flyers.` ·
  `Call the Wildcaller  [C]\n300 crystals · 150 essence · Pop 4 · 45 s\nA unique druid who fights on her own. One at a time.` ·
  `Light the Ember Crucible  [C]\n300 crystals · 75 s · Once\nThe Roost forges a free Flame Guard every 40 s (max 6 alive; uses population).`
- Kill XP (`levels.md`, cost / 2 rounded to 5): Frost Dragon **325**, Barrow Giant **150**, Spirit Wolf 0. The Wildcaller is a
  champion victim with her own numbers (5.3). Forged Flame Guards are ordinary Flame Guards (45).
- Missions: hidden (tier-3 content, `titans_enabled` false). With research off, the Lair's step-13 8:00 rule gates them.

## 3. Ice: Frost Dragon (`frost_dragon`)
### 3.1 Stats
| HP | Armor | Attack | Speed | Turn | Aggro / sight | Radius | Height | Cost | Pop | Train | kill_xp | Tags |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **1 700** | 10 | **Rime Breath**: **14** to every enemy in a **60 deg cone, 6.5 m**, every **2.4 s** (0.4 s windup), + frost + chill (3.2) | **5.0** (flying) | **110 deg/s** | 11 / 14 | 1.0 (none: flyer) | body at 4 m, span 7.5 m | **650** | **6** | **85** | 325 | titan, flying |
Compared with the Cinder Dragon (1 400 HP, 16 burn breath, 5.5 m/s, 700): **tougher (Ice +20 % HP rule), slower, less damage,
all control**. `fly_height` 4.0, `attack_shape &"cone"`, `attack_arc_deg` 60, colour (wing membrane tint) `(0.55, 0.80, 0.95)`.
### 3.2 Specials (`TitanAbilities`)
| Special | Numbers |
|---|---|
| **Rime Breath** (its attack, kind `spell`, not fire) | Hits ground and air units in the cone; each hit adds **25 frost** (`add_frost(25, team, true)`: 4 breaths = frozen 1.0 s, heroes and titans 0.5 s, then the 2 s freeze immunity of rs. 3.3) and `chill` **2 s** (a chilled rider cannot charge for 6 s, cm. 3.2). Buildings in the cone x0.5 (7), no frost. Breathes only at a target within +-30 deg of its facing (cm. 5.2 rule) |
| **Hoarfrost** | A patch r **2.5** centred 4 m ahead, **4 s**: enemy **ground** units inside are `chill`ed (refreshed every 0.5 s); **no damage**. Shares the burning-ground pool (max 12 patches alive in total) |
| **Airborne** | cm. 3.3: ranged / towers x2, melee cannot hit |
| Research | Heart of Winter's x1.5 frost applies (rs. 3.3); Stasis does not (titans never come back); generic soldier research applies |
### 3.3 Role and counters
| Beats | Loses to | Soft |
|---|---|---|
| Melee blobs and cavalry (they cannot hit it; chill denies charges; freezes), Nightmare Knights, Barrow Giants (cannot hit air), a Cinder Dragon in a long fight (it freezes it 0.5 s every ~10 s) | Ranged units, towers and keeps (x2), Bone Ballistas (x3.5 on flyers), Frostrune Riflemen of an Ice mirror, the Mammoth howdah, a rooted Treant, the Mage Archer | Flanking (slow turn), spread-out armies (fewer units per cone) |
Distinct from the Cinder Dragon: the Cinder **kills** clumps (16 + burning ground), the Frost Dragon **holds** them (slow, freeze) so
Ice's slow army and riflemen can finish them. It also gives Ice what it never had: something fast that catches raiders.

## 4. Shadow: Barrow Giant (`barrow_giant`)
### 4.1 Stats
| HP | Armor | Attack | Range | Cooldown | DPS | Speed | Aggro / sight | Radius (coll.) | Height | Cost | Pop | Train | kill_xp | Tags |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **950** | 5 | **Boulder**: **32**, lobbed, splash **50 % r 1.8** | **10.0** (no min range) | **3.2** | 10.0 (~15 vs a clump) | **3.8** | 11 / 12 | 1.0 (0.8) | 4.5 | **300** | **3** | **40** | 150 | titan |
Fields: `abilities [&"boulder_throw"]`, `damage_taken_mult {ranged: 0.8, tower: 0.8, melee: 1.25}` (**Stone Hide**, and
**Lumbering**: slow to strike at what clings to its knees), `building_damage_mult` **1.0** (boulders: the titan x0.5 rule is
overridden, it is Shadow's mass siege), **cannot hit flyers** (a lobbed stone), colour (burial shroud) `(0.42, 0.22, 0.60)`.
The only titan with pop 3 and under 400 crystals: **the massable titan** (user: "mass-trainable, no cap").
### 4.2 Boulder Throw (`boulder_throw`, `UnitAbilities`; the rb. 5.2 `frost_shell` lob path with other parameters)
| Part | Rule |
|---|---|
| Throw | Its attack is a lobbed barrow-stone: arc, **1.0 s** flight, lands **where the target was** (a unit that moves 2 m in that second dodges the main hit). Full damage to the target if still there, **50 %** to other enemy **ground** units within **1.8 m** of the landing point. Kind `ranged` (so the Mossback's Canopy and powder smoke reduce it) |
| Buildings | Main target only, x1.0 (32 per stone) |
| Air | Never targets flyers (auto-target skips them; attack order refused `"Can't reach flying units"`, cm. 3.3) |
| Bark | None (warnings only, 4.3) |
### 4.3 Titan rules and warnings
All cm. 3.4 rules. Warnings are summed per team per 60 s: `The enemy is raising 3 Barrow Giants!`; ready `Barrow Giants take the
field!` (once per 60 s); death `A Barrow Giant has fallen` (own only when more than one is alive: no spam). Every Giant shows as a
minimap diamond (too big to hide).
### 4.4 Role and counters
| Beats | Loses to |
|---|---|
| Ranged armies and casters in lines (Stone Hide x0.8, splash), towers and buildings from 10 m (Stone Hide vs tower shots), Cinderlocks (6.5 m reload window, splash on the volley line), Frostrune Riflemen that are not braced far enough (15 m > 10 m, but a Giant group closes), static defences | Line infantry and cavalry that reach it (melee **x1.25**, Lance halves its armor), anything that flies (Cinder / Frost Dragon, Sparkwing: it cannot hit them), armor pierce and titan hunters (Riflemen, Giant Slayer, Titanbreaker x2 on titans, Vinelasher roots, Bone Ballistas of a mirror), moving targets (the lob lands late), Hexweaver's `withered` |
Distinct from the Bone Ballista (a long single-target siege-sniper, 13 m, anti-titan, fragile) and the Nightmare Knight (a fast
charging duelist): the Giant is a slow, thick, massable **stone artillery** that wants a Shade line in front of it.

## 5. Nature: the Wildcaller (unique autonomous NPC)
### 5.1 Identity
**Maelis Oakenhollow / Corwen Oakenhollow, *the Wildcaller*** (names A / B by the champion sibling rule: the first Nature team to
call one gets A; B only shows in a Nature mirror). An old druid of the deep wood in a moss-and-feather cloak and an antlered hood,
with a living staff whose crown blossoms. She is **the Nature kingdom's own champion**: she answers the Elder Circle, fights by her
own judgement and cannot be ordered (`is_commandable()` false). She **calls the wild**: thorns that pin, spirit wolves that hunt,
a spirit-stag stampede. She never heals (rs. Q3). Personality line: `Listens to the forest. The forest has opinions.`
The Mage Archer is Shadow's **hunter-sniper** (single targets, heroes); the Wildcaller is Nature's **area controller and summoner**
(clumps, riders, the line).
### 5.2 Stats (level 1 base; she arrives at level 3: x1.04)
| HP | Armor | Dmg | Range | Cooldown | DPS | Speed | Aggro | Sight | Radius | Height | Flee under | Growth | Projectile |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **520** | 5 | **20** | **9.5** | 1.25 | 16.0 | 4.9 | 12 | 14 | 0.5 | 2.1 | **30 %** | 2 % / level | a green-gold thorn bolt `(0.60, 0.95, 0.35)`, 26 m/s |
Kind `ranged` (her bolts hit flyers x2); `hero_mult` for crowd control, as champions. Compare: the Mage Archer 560 HP / 23.3 DPS at
11 m; the Wildcaller has less DPS of her own and puts the rest in summons and control (5.5).
### 5.3 Call, death, revive (the t3. 6.3 rules with her names)
| Rule | Value |
|---|---|
| Call | Elder Circle slot **C**: **300 crystals + 150 essence**, **45 s** in the Lair queue, pop **4** (from the queue on, while alive and while fallen). She steps out of the Lair with **150 XP (level 3)**, her 3 skill points spent at once, full HP, **purse 100** |
| Unique | One per team: `"Already called"` while queued, alive or fallen. Not in the champion roster (the tavern's max 3, prices and pop unchanged) |
| Upkeep / dismiss | None / not possible |
| Death | As a champion: intent `Fallen`, drops 30 % of her purse to the killer, items and levels kept. Victim XP **200 + 15 x level** |
| Revive | Lair C becomes **Revive**: **150 + 15 x level essence**, back after **25 + 3 x level s** at the Elder Circle door (the keep's spawn point if the Lair is gone). Also from her unique slot. Refusals `"Not fallen"`, `"No home"`, `"Not enough essence"` |
| Warnings | `The enemy is calling a Wildcaller!` (own: `The Wildcaller answers the call`), ready `Maelis Oakenhollow takes the field!`, death `Maelis Oakenhollow has fallen` (both), through `Events.titan_event(team, &"wildcaller", what)`; no minimap diamond |
### 5.4 Levels and skills (the unique-NPC curve, st. 2.1)
- `Champion.LEVEL_TOTAL_XP`, **drill 2 XP / s** (the Mage Archer's number): level 6 ~3:30, level 9 ~10:00 after the call.
- **Class: Wizard, fixed** (`class_weights {wizard: 1}`), its 9-skill tree (st. 5.4) picked by the normal rule (st. 6) with her
  taste row: burst 0.8, **area 1.5**, **control 1.5**, guard 1.0, sustain 0.9, mobility 1.0, hunt 0.6, **support 1.3** (so Gravity
  Well, Starfall and Comet Rain come before Astral Form; the Mage Archer's row leans the other way). Her model keeps the staff
  (`weapon_override &"wild_staff"`).
- `power()` = **250 + 25 x level + 10 x ranks + items / 5** (L3 ~355, L9 ~565).
### 5.5 Her own abilities (archetype row `ChampionType.ability_ids`, unlock L1 / L1 / L6; amounts x `(1 + 0.02 x (level - 1))`, spell power applies; kind `spell`)
| id | Name | Unlock | Cooldown | Range | Effect | Autocast when |
|---|---|---|---|---|---|---|
| `thornsnare` | Thornsnare | L1 | 14 | 12 (point), r 2.5 | A ring shown to both teams, **0.6 s** later thorns burst: **20** to enemy **ground** units inside + `rooted` **1.2 s** (heroes, champions, titans 0.6 s; never flyers). Rooted denies a charge and ends the Knight's gallop armor | 3+ enemy units within 2.5 m of a point in range; or a mounted or charge-ready enemy within 10 m of her or of the own wizard |
| `call_the_pack` | Call the Pack | L1 | 28 | self | **2 Spirit Wolves** appear at her side (5.6), **20 s**; max 2 alive from her | An enemy within 10 m of her; or a melee enemy within 4 m (bodyguards) |
| `wild_stampede` | Wild Stampede | **L6** | 50 | a 16 m line from her, 3 m wide | Three spirit stags run the line in **1.2 s**: **45** to each enemy ground unit in it (max 8) + knockback **1.5 m** (never titans, flyers, buildings, the Mossback) + `dazed` **0.5 s** (heroes, champions, titans half); buildings 0 | 4+ enemy units in such a line; or 3+ with an enemy hero or champion among them |
Autocast order: her three first, then the tree (st. 7.1); the 1.0 s global cooldown and the team signature spacing apply.
### 5.6 Spirit Wolf (`spirit_wolf`, a summon; the Sapling pattern)
| HP | Armor | Dmg | Range | CD | Speed | Aggro | Radius | Height | Pop | XP / essence / souls | Lifetime | Commandable |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 150 | 0 | 12 | 1.5 | 1.0 | **6.5** | 10 | 0.45 | 0.9 | **0** | **0** | **20 s** | **false** (they follow her) |
They attack her current target, else the nearest enemy **ranged** unit within 10 m of her, else the nearest enemy; they never
leave 16 m from her (return). Kind `melee`. Not soldiers (no research, no rings, no Heat). Knockback / Stampede never hit own wolves.
### 5.7 Brain (ai: `ChampionBrain` with her `ChampionType`; ch. 8.1 rules R1-R9 unchanged except as listed)
| Part | Rule |
|---|---|
| Traits | Greed **0.8**, Courage **1.1**, engage radius **12**; affinity Guard **1.4**, Escort **1.3** (x1.2 on the own wizard), Hunt 0.8, Explore 0.4 |
| R2 Flee / rest | Under 30 % HP; rest spots add the own **Lair** (home rest 2 % / s within 15 m) |
| R4 Fight | Target preference in range: the enemy unit with the most enemy units within 2.5 m (for her snare) > mounted > ranged > nearest. Keeps her distance: a melee enemy within 3 m -> step 4 m away (max once per 2 s; Slipstep first if learned) |
| R6 Bounties | As a champion; Guard and Escort flags preferred |
| R7 Shopping | Wish list `Duskglass Lens, Mana Thread, Wisp Lantern, Pyre Staff, Cinder Ring, Nightveil Cloak` (4 slots; 20 % tithe) |
| R8 Default "**Grovewatch**" | Stay **6 m** behind the centre of the largest own soldier group (the Mender's centre rule). If an own **rooted Elder Treant** is within 40 m of that group, stand within **8 m** of the Treant instead (she guards the grove). Fewer than 4 soldiers: **Watching home** between the keep and the Lair, fighting intruders within 20 m. Intent text `Grovewatch` / `Guarding the grove` / `Watching home` |
| Mount | Buys a Roan Courser at level 7 like a champion |
### 5.8 Role and counters
| Beats | Loses to |
|---|---|
| Clumped lines (Thornsnare + Stampede), cavalry and Knight charges (root denies), casters and ranged units harassed by wolves, swarms (Stampede line), flyers at range (x2) | Being hunted (bounties, Hunter's Oath), cavalry dives (4.9 m/s), out-ranging (Riflemen 15, Mage Archer 11, towers), Cinderlock volleys if she drifts within 6.5 m, area spells on her wolves, fog (sight 14). One body the player cannot place: baited, she dies |

## 6. Fire: the Ember Crucible (base upgrade; balance first)
### 6.1 The value model (what "as strong as a titan" means over a 15-20 min game)
Normal bot timings (rs. 8): Citadel 11:00-12:30, Lair completed **~12:45**. From there each kingdom's option arrives: Frost
Dragon **14:10** (85 s), Barrow Giants from **13:25** (40 s each), the Wildcaller **13:30** (level 3, level 9 ~23:30), the
Crucible's first effect **14:00** (75 s). Median game end target **15:00-20:00** (rb. 8). So an option has **~1-6 minutes** of life
in a median game: anything that pays back slowly is a trap, anything that grows without a bound decides long games.
Late economy (rs. 2.4, `balance-2.md`): ~**550 crystals / min** per side, ~80 % on soldiers when below the pop cap (40; Nature 50),
and a side is below the cap ~70 % of the late game (it refills after fights) -> **~310 crystals / min** of soldier spending.
A **titan** (the reference) is worth its price the moment it fields and its value is lost when it dies: against the same crystals
of line infantry it nets about **-10 % to +40 %** depending on the enemy's answer (cm. 13.2): roughly **-70 to +280** for a 700 Dragon.
### 6.2 The forms compared (price 300 crystals each, effect from 14:00; net = value received - price, in crystals)
| Form | 15:00 | 17:30 | 20:00 | 25:00 | Bound | Who gains more | Counterplay | Verdict |
|---|---|---|---|---|---|---|---|---|
| A. Fire soldiers cost **-15 %** | -254 | -137 | -21 | +211 | none | the richer side (it spends more) | none | A trap in a normal game |
| B. Fire soldiers cost **-30 %** | -207 | +26 | +258 | +723 | none | the richer side; Cinderlocks and Pyre Adepts 30 % cheaper (Fire bias) | none | Grows without limit; feeds Fire's best units |
| C. Training **-30 %** time | ~0 while income < production; after a lost fight, re-maxes 30 % faster | | | | none | the side with a bank | none | Unmeasurable before tests; shortens games (rs. 9.4 goal) |
| **D. Forge: a free Flame Guard every 40 s** (pop counted, max 6 forged alive, only while the Roost stands) | -205 | **+31** | **+267** | ~+500 (flow only when forged Guards die; standing value <= 540) | 6 alive | **flat**: the same for rich and poor, relatively more for the side behind | kill the Dragon Roost (1 500 HP) | **Recommended** |
| Reference: one Cinder Dragon at 14:10 | its body: -70 to +280 vs the same crystals of line | | | | dies | | anti-air | |
D's flow: 90 crystals per 40 s = 135 / min, x 0.7 (paused at the pop cap or at 6 alive) = ~95 / min. It is weaker than a titan
before ~17:30, about equal at 18-20 min, and the 6-alive cap keeps a winning side (that loses no Guards) from banking free value:
**the forge only refills what dies**. It is visible (Guards march out of the Roost), readable (one timer), and one knob (40 s).
### 6.3 Rules (the recommended form D)
| Rule | Value |
|---|---|
| Light | Dragon Roost slot **C**: **300 crystals, 75 s** in the Lair queue (it blocks Dragon training meanwhile). Once per Roost. Refused `"Already lit"` |
| Forge | While the Roost stands and the Crucible is lit: every **40 s** one **Flame Guard** (`flame_guard`, the normal unit: veterancy, research, Heat, wares all apply) steps out of the Roost door and walks to the Roost's rally |
| Pauses | The timer holds (does not bank) while the team is at its pop cap (`"Paused: population cap"`) or while **6** forged Guards are alive (`"Paused: 6 forged Guards"`) |
| Pop | Each forged Guard uses 1 pop like a trained one; it is never reserved in advance |
| Lost | The Roost destroyed: the Crucible goes out; a new Roost can **relight** it for **150 crystals, 40 s**. Forged Guards alive stay |
| Victims | Forged Guards give normal kill XP (45), essence and souls: they are real soldiers |
| Warnings | Enemy: `The enemy is lighting an Ember Crucible` at the start, `The enemy's Ember Crucible burns` when lit (public like titan warnings; `Events.titan_event(team, &"ember_crucible", what)`); own: `The Ember Crucible is lit: a Flame Guard every 40 s`. No minimap diamond |
| Look | The Roost gains a crucible-and-anvil annex with a glowing pour; each forging flares it (sparks, steam) |
### 6.4 Role and counters
Fire's late army becomes **Cinderlocks and a Dragon behind an endless Guard wall**: the forge refills the front line after each
fight, the Hall's crystals go to musketeers and the Roost's to Dragons. Counters: raid or siege the **Dragon Roost** (War Mammoth
x2, Barrow Giants, Bore Beetles, Bone Ballistas, Cinderlocks of a mirror); area damage on Guard lines (Frost Mortar, Eclipse
Volley, Stampede, Giant splash, the Frost Dragon's freeze); the forged Guards are T1 bodies (CE 19.3, no titan power).

## 7. Neutral: the Frost Wyrm (rows for `map-fill.md` 5.5; the map-fill owner merges them)
### 7.1 The kind (row for the `mf.` 5.5 kind table, same columns)
| Kind (lair) | Variant A | Variant B | HP | Armor | Dmg / CD (DPS) | Range | Speed patrol / fight | Aggro | Radius | kill_xp (A / B) | Strength (A / B) | Abilities |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Frost Wyrm** (a long winged frost serpent; **flies at 4 m, lands to strike**; the only flying beast) | Rimescale Wyrm (pale ice-blue scales, frilled crest) | **Old Hoarfang** (the elder: x1.15, white-violet crystal horns, frost motes) | **3 400** (B 3 900) | 15 | Rime Breath 20 / 2.5 (8 per unit hit; ~3 units in the cone = 24) | cone 60 deg, **7.0** | 4.0 / 5.5 (flying) | 9 | 1.0 | **300 / 360** | **1 900 / 2 200** | **Rime Breath** (its attack, kind `spell`: every enemy in the cone takes 20 + **20 frost** ungated + `chill` 1.5 s; **B**: 30 frost). **Glacial Dive** (every **18 s** while fighting: a ring r 3 shown to both teams on the point with the most enemy units within 3 m, inside its leash; **1.0 s** later it lands there: **50** + `chill` 2 s + knockback 1.5 m (heroes 0.75 m, never titans) to enemies within 3 m; then it stays **grounded 6 s** and uses **Tail Lash**: **30** to enemies within 3.5 m every 2 s; takes off in 0.8 s). **Blizzard** (**B** only, once, at 50 % HP: 8 s, r 8 around it: enemy units inside `chill`ed (refreshed) and 5 damage per s). **Enrage** below 30 % HP: breath cooldown -30 % |
Rules for all Frost Wyrms (on top of the `mf.` 5.5 rules for beasts):
| Rule | Value |
|---|---|
| Airborne (default) | The cm. 3.3 flyer rule: ranged hits x2, melee cannot hit it, area spells hit at its x-z position; it moves in straight lines (no navmesh), so it hovers over water and crosses the river freely inside its territory |
| Grounded (6 s after each Glacial Dive) | `is_flying()` false: melee can hit it, ranged x1; it does not move; it cannot be knocked back or taunted |
| Crowd control | `hero_mult` (half); `frozen` / `rooted` while airborne stop it in the air (cm. 3.3) |
| Leash | Territory radius + **6 m** (not + 10: it keeps the fight off the Crown Isle and the tavern doors, 7.2) |
| Ignores | Workers, caravans, buildings, Magpies and trackers are never targets (the beast rule); towers never shoot it |
| Pre-warning | 30 s before a spawn: `An icy wind rises over the Hollowmere...` (both teams, once per spawn) |
### 7.2 The lairs (row for the `mf.` 5.5 lair table)
| Lair (player bank; mirror) | Centre, radius | Patrol points | Kind | Nearer by path to | First spawn | Respawn |
|---|---|---|---|---|---|---|
| **Icebound Barge** (the Drowned Barge in the south river, frozen over) | `(4.5, 20.5)` r 3.5 (`(-4.5, -20.5)`, the north river's barge) | `(4.5, 24.0)`, `(1.5, 21.5)`, `(3.5, 17.5)`, `(7.0, 22.0)` | Frost Wyrm | **player** (~55 m to the west shore vs ~78 m to the east shore); **both banks can shoot it across the 5 m water** | **13:00** | **720 s** |
Clearance check of the centre `(4.5, 20.5)` against the `mf.` 5.5 rules (edge = centre distance - 3.5; mirror identical):
| Rule | Nearest | Distance (edge) | OK |
|---|---|---|---|
| >= 13 m from crystal nodes and keeps | Fire natural `(-16, 6)` | 25.1 (21.6) | yes |
| >= 9 m from bot build slots | C1 `(-20, 13)`, S3 `(-19, 1)`, enemy S3 `(19, -1)` | 25.6 / 30.5 / 25.1 | yes |
| >= 10 m from camp spots and capture-circle centres | Willow Ford Nest `(8.5, 34)` / Millwatch `(-6, 40)` / East Wayshrine `(22, 6)` | 14.1 (**10.6**) / 22.1 / 22.7 | yes |
| >= 8.9 m from trading-post doors | `s_door (-1, 49)` | 29.0 | yes |
| >= 14 m from another lair's centre | its own mirror `(-4.5, -20.5)`, Grizzlemaw mirror `(26, 54)` | 42.0 / 39.8 | yes |
| Crossings (building rule 8 m, for information) | Crown Steps SE `(9.02, 9.02)`, Willow Ford `(8.5, 34)` | 12.3 / 14.1 | clear |
| Crown Isle (land r < 11) | the moat water begins at r 14.5 | centre at r 21.0; leash reaches r ~11.5 at most | it can chase over the moat water, never onto the isle |
| East tavern door `(11.5, 11.5)` (mirror: the west tavern for the north wyrm) | nearest patrol point `(3.5, 17.5)` | 10.0 (aggro 9); centre 11.4 > leash 9.5 | outside |
| Drowned Barge landmark `(6.2, 24.5)` | | 4.3 | inside the territory: it is the nest |
The patrol point `(1.5, 21.5)` is on the west-bank land 1.1 m from the water; the other three are over the water or the east
edge of the channel. A dive may land on either bank (it lands on enemies); a point over water snaps to the nearest walkable point.
If the 12.C1 fairness test finds an overlap the lead did not foresee, the systems-coder moves both centres along the river
(towards the barge, never closer than 10 m edge to the ford nests) and reports the new numbers.
### 7.3 Rewards (rows for the `mf.` 5.5 drop table and the `reward` dictionary)
| Drop table id | Variant A | Variant B (adds) | Reserved trophy ids |
|---|---|---|---|
| `frost_wyrm` | **2** of Ironbark Plate, Duskglass Lens, Mana Thread, Cinder Ring, Ember Shard + **60 %** Warden Scale or Vital Root | Warden Scale **and** Vital Root guaranteed (instead of the 60 %) | `rimescale_heart` / `hoarfang_heart` |
- `reward` dictionary (paid **today**, the first beast with a non-empty one): **`{essence: 120}`** (A) / **`{essence: 180}`** (B) to
  the team of the killing blow through `EpicBeasts.grant` (13); step 15 may add `food` (e.g. 80 / 100) without changing the rules.
- Kill XP normal victim rules (underdog x1.25). The biggest beast reward on the map: ~300-360 XP + 180-216 essence (60 % rule)
  + 120-180 essence + two components.
- Messages: spawn `A Rimescale Wyrm nests on the Icebound Barge` / `Old Hoarfang, the elder wyrm, nests on the Icebound Barge!`;
  death `Your army slew Old Hoarfang` (own, + the drops) / `The enemy slew the Rimescale Wyrm`.
### 7.4 Fight checks (normal; `mf.` 5.5 format)
- **16 soldiers with >= 6 ranged + the wizard**: ~25-35 s, 3-6 soldiers lost (breath freezes, dives): **ranged win it** (x2 on it
  airborne), melee joins during the 6 s landings.
- **A melee-only army** (14 Flame Guards): hits it only 6 s out of every ~24 s: ~70-90 s and heavy losses: it should not try.
- **Three level-6 champions** (one ranged): lose or flee; the Wyrm needs the army. The hunting-party rule (`mf.` 6) counts only
  ranged champions' power toward a Wyrm (melee ones at 25 %).
- **Contested across the river**: the other side's ranged units can shoot it from their bank and steal the killing blow: the
  Wyrm fight is also a fight over the water.
### 7.5 Other `mf.` sections to update (the map-fill owner merges)
| Section | Change |
|---|---|
| 0 / 1 / 5.5 intro | 4 kinds -> **5 kinds** x 2 variants; 8 lairs -> **10** (5 per bank); first spawns 6:30-**13:00** |
| 7 bot, rule 11e | The Frost Wyrm needs **>= 5 ranged units** in the group (or an own flyer, a Mammoth howdah or a rooted Treant with it) on top of `beast_ratio`; normal: its own-near Wyrm only; hard: also the far one when the other side's army was not seen within 40 m in 30 s |
| 8 UI | The epic-beast row applies; plus: the inspect card and boss bar show `Airborne` / `Grounded 4 s`; the Glacial Dive ring (both teams); the 30 s pre-warning message; the frozen barge as its lair look |
| 9 perf | Epic beasts at most **10** alive (~0.04 ms / frame for their brains); the perf test adds the 2 Wyrms |
| 10 art | Rows 13c.V8 / 13c.V9 of section 11 (they own the frozen-barge overlay; `landmarks/barge.tscn` stays untouched) |
| 12.1 balance | 13:00-25:00: the Frost Wyrm (every 12 min): ~330 XP and ~300-400 essence per kill; decides little alone, often a fight over the river |
| 12.3 knobs | Wyrms seldom fought -> first spawn 13:00 -> **12:00**; armies lose too much -> HP 3 400 -> **3 000** or dive every 18 -> **22 s**; the Wyrm snowballs -> `reward` essence 120 / 180 -> **80 / 120** |
| 13 contracts | `EpicBeasts` 5 kinds, `grant` pays `essence`; beast brain flyer mode (section 13 here) |

## 8. Balance
### 8.1 The new titans beside the old (cm. 13.2 format; CE = EHP x DPS / cost² x 100, PE = EHP x DPS / pop² / 100)
| Unit | EHP (vs its prey) | EHP (vs its counter) | DPS | CE (prey / counter) | PE | Speed |
|---|---|---|---|---|---|---|
| Cinder Dragon (ref.) | infinite vs melee | 700 vs ranged / towers | ~28 on 2-3 units | - / 4.0 | 10.9 | 5.5 fly |
| **Frost Dragon** | infinite vs melee | **935** vs ranged / towers | **~17.5** on 3 units + chill (-20 % enemy DPS) + a 1 s freeze per unit every ~10 s | - / **3.9** (~5 counting the control) | **9.1** | 5.0 fly |
| **Barrow Giant** | **1 250** vs ranged / towers (Stone Hide) | **800** vs melee (Lumbering) | 10.0 single, **~15** vs clumps | **20.8** vs ranged lines / **8.9** vs melee | **11.1** single / 16.7 clumps | 3.8 |
| Nightmare Knight / War Mammoth / Elder Treant (ref.) | 845 / 2 600 / 2 080 | 433 / 1 730 / 1 390 | ~30 / ~25 / ~28 | 15.8 / 8.1 · 15.4 / 10.2 · 16.2 / 10.8 | 15.8 / 18.1 / 16.2 | |
| **Wildcaller (L3)** | 570 | | 16.6 + wolves ~17 avg (24 for 20 s of 28) + snare / stampede | ~9 (675 crystal-eq.) | ~11 | 4.9 |
| Mage Archer (L3, ref.) | 640 | | 24.3 + ~8 abilities | ~10 | ~12.8 | 5.2 |
| **Ember Crucible** | not a unit: ~95 crystals / min of Flame Guards (CE 19.3 each) from 14:00, <= 6 alive (6.2) | | | | | |
The Giant is the cheapest titan and the best per crystal **against ranged lines** (its prey), the worst against melee: a hard
counter both ways. The Frost Dragon trades damage for control. Every new titan is **below line infantry per crystal** against its
counter, like step 13's.
### 8.2 How the four kingdoms' late armies compare (t3. 9 table, updated with 13c)
| Kingdom | Titan (Lair Z) | 13b | **13c (Lair C)** | Late identity | Wins by | Weak to |
|---|---|---|---|---|---|---|
| **Fire** | Cinder Dragon | Cinderlocks | **Ember Crucible** (free Flame Guard line) | **Shock behind an endless wall**: forged Guards hold, Cinderlocks volley, the Dragon burns from above | Burst, breaching, a front line that refills itself, fire x1.5 on Mammoth / Treant | Range (6.5 m muskets), losing the Roost (the forge stops), area damage on the Guard line |
| **Shadow** | Nightmare Knight | Mage Archer | **Barrow Giants** (massable stone artillery) | **The elite few + stone artillery**: Knights and the Archer pick targets, Giants shell ranged lines and bases from behind Shades | Crushing ranged armies and static defences, lifesteal, a hunter NPC | Line infantry and cavalry that reach the Giants, flyers (neither Giants nor Knights hit air), anti-titan units |
| **Ice** | War Mammoth | Frostrune Riflemen | **Frost Dragon** (flying control) | **The frozen wall with a frozen sky**: riflemen and the Dragon lock whatever comes, the Mammoth grinds bases | Freezing titans, riders and heroes; finally something fast that catches raiders | Dives on the riflemen, massed ranged + towers vs the Dragon (x2), fire on the Mammoth |
| **Nature** | Elder Treant | Glade Outriders + Mossback | **Wildcaller** (unique druid, levels) | **Grow and roam, with a keeper of the grove**: roots and stampedes pin the enemy while Outriders bleed it and the Treant sustains | Area control, anti-cavalry roots, attrition near a rooted Treant | Being hunted (one Wildcaller), flyers, piercing on the Mossback, burst on the Treant |
Every kingdom's answer to each 13c option (from its own roster):
| 13c option | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| Frost Dragon | Ember Archers + Spires (x2), Cinder Dragon | Nightbolts, Bone Ballistas (x3.5 on flyers), Mage Archer | (mirror) Riflemen, Shardcasters, Mammoth howdah | Burr Slingers, Outriders, a rooted Treant, Wildcaller bolts |
| Barrow Giants | Flame Guards (forged ones too), Blaze Riders, the Cinder Dragon (untouchable) | (mirror) Shades, Knights, Ballistas | Rimeshields, Rimehorn Riders, Riflemen (pierce), the Frost Dragon | Thornlings, Vinelashers (root titans), Stagrunners, Outriders kiting |
| Wildcaller | Cinderlock volley, Blaze Rider dive, Hunt bounty | Mage Archer (11 > 9.5 + Grave Mark), Grave Hounds | Riflemen (15 m + Rime Lock), Frost Dragon freeze | (mirror) Outriders, Vinelashers |
| Ember Crucible | (mirror) raid the Roost | Giants and Ballistas on the Roost; Eclipse Volley on Guard lines | Mammoth (siege x2), Frost Mortars on the Guard line | Bore Beetles on the Roost; Stampede on the line |
### 8.3 Duels (level 1, no items; cm. 13.2b / rb. 11.4 rules; D48-D62 for `tests/test_13_duels.gd`)
| # | Duel | Expected | Pass band |
|---|---|---|---|
| D48 | 1 Frost Dragon vs 8 Flame Guards | Dragon untouched | dragon 100 %, all guards dead < 100 s |
| D49 | 1 Frost Dragon vs 7 Ember Archers (700) | Archers win | 3-5 archers left |
| D50 | 1 Frost Dragon vs 1 Cinder Dragon | Close | winner <= 40 % HP |
| D51 | 1 Frost Dragon vs 4 Blaze Riders charging | Charges denied | dragon >= 60 %, riders never land a charge bonus |
| D52 | 3 Barrow Giants (900) vs 9 Ember Archers (900), from 20 m | Giants win | >= 2 Giants alive |
| D53 | 3 Barrow Giants vs 10 Flame Guards (900) | Guards win | >= 4 guards left |
| D54 | 2 Barrow Giants vs 1 Cinder Dragon | Dragon wins untouched | dragon >= 90 % |
| D55 | 4 Barrow Giants vs an Ember Spire + an Ember Hall, undefended | Artillery siege | Spire falls < 25 s, Hall < 50 s, >= 3 Giants alive |
| D56 | 4 Barrow Giants + 4 Shades vs 8 Cinderlocks (1 040) from 20 m | Giants shell the volley line | Shadow wins, >= 2 Giants alive |
| D57 | Wildcaller L3 vs a L3 Coin-Cutter (Two-Hand) | She wins (wolves tank, snare) | >= 40 % HP |
| D58 | Wildcaller L6 vs 8 Flame Guards | Stampede + snare, then flees | >= 4 guards dead before she flees or dies |
| D59 | Wildcaller L9 vs Mage Archer L9 | Close | winner <= 40 % HP |
| D60 | Frost Wyrm A vs 8 Flame Guards + 8 Ember Archers (no wizard) | Army wins | 25-40 s, 3-6 soldiers lost |
| D61 | Frost Wyrm A vs 14 Flame Guards (melee only) | Wyrm wins or holds | at 60 s the Wyrm has >= 40 % HP or all guards are dead |
| D62 | Old Hoarfang vs a L6 Wayfinder + L6 Oathwall + L6 Mender | Beast wins | champions flee or die; Hoarfang >= 40 % |
Crucible test (13c.C4, not a duel): over 300 s with free pop the Roost forges **7** Guards (first at 40 s); never more than 6
forged alive; at the pop cap the timer holds; the Roost destroyed stops it; relight costs 150.
### 8.4 Timing and game length
- Nothing arrives before **~13:25** (the Lair needs the Citadel): step 13c cannot shorten the 15-20 min median by itself.
- **Giants are the risk** (cheap, massable, full building damage): 8 Giants (2 400, 24 pop) shell a Citadel keep (3 500) in ~45 s
  from 10 m while the keep hits them at x0.8. They must first get through the enemy army, which beats them in melee. Watch the
  median in the 13c.L2 runs; knob 8.5.
- The Frost Dragon helps Ice (weakest kingdom): it gives Ice an army-speed answer to raids and freezes fights in Ice's favour.
- The Crucible is **not** a lengthening tool: it refills a front line, flat. It helps the side behind a little more than the
  side ahead (6-alive cap, flat rate).
- **Fire bias watch** (cm. 13.3, rb. 12.1): the Crucible is the smallest late bump of the four options (6.2); if Fire > 55 %
  after the Citadel, knob 8.5 first.
- **Nature watch**: the Wildcaller adds late control to the kingdom that is strongest after ~16:00 (rs. 9.2); drill is the knob.
### 8.5 Knobs (one at a time, 13c.D3)
| Symptom | Knob |
|---|---|
| Frost Dragons freeze-lock armies | frost 25 -> **20** per hit; chill 2 -> **1.5 s** |
| Frost Dragons never built / always die | HP 1 700 -> **1 900**; cost 650 -> **600** |
| Mass Giants end games / median < control - 0:30 | `building_damage_mult` 1.0 -> **0.75**; cost 300 -> **340**; train 40 -> **50 s** |
| Giants useless | Stone Hide 0.8 -> **0.7**; splash 50 % -> **65 %** |
| Wildcaller decides games | drill 2.0 -> **1.5**; Stampede 45 -> **35**; call 300 + 150 -> **350 + 200** |
| Wildcaller irrelevant | arrives level **4**; wolves 20 -> **25 s** |
| Crucible too strong / Fire > 55 % late | interval 40 -> **45 s**; max alive 6 -> **4** |
| Crucible never worth it | interval 40 -> **35 s**; price 300 -> **250** |
| A 13c option < 3 % of its kingdom's tier-3 spend in games that reach the Lair | check the bot rule (9) first, then its price -10 % |
### 8.6 Re-test (lead 13c.L2)
The rb. 11 matrix harness with a new flag **`--no-titans-2`** (the four C options hidden; the Frost Wyrm too) as the control, and
**`--no-wyrm`** alone. Pass: median length >= control - 0:30; no kingdom's win rate moves by more than 8 points vs the control; in
games that reach a completed Lair each option is used (Frost Dragon or Giant trained, Wildcaller called, Crucible lit) in >= 40 %
of its kingdom's games; each side kills >= 1 Frost Wyrm in >= 40 % of games that pass 15:00; duels D48-D62 in band; `PERF OK`.

## 9. The bot (ai; extends cm. 9, t3. 10, rb. 7; knobs in `AIProfile` / `data/ai/*.tres`)
### 9.1 Choosing at the Lair
The titan share (cm. 9.1 mix index 5 / `unit_mix` titan entries) is split between the Lair's Z titan and its C option by
**`second_titan_share: Vector3(default, vs_ranged, vs_melee)`** ("vs ranged" = seen soldier pop >= 50 % ranged, "vs melee" = >= 60 % melee):
| Kingdom | `second_titan_share` | Extra rows (first match wins) |
|---|---|---|
| Ice | Frost Dragon **(0.5, 0.25, 0.75)** | Enemy flyer seen (Cinder / Frost Dragon): 0.5 (dragon vs dragon); the attack group's target is a building: the next titan is a Mammoth |
| Shadow | Barrow Giant **(0.6, 0.8, 0.3)** | Enemy dragon seen: both Shadow titans 0 (neither hits air, cm. 9.1 "own Knights 0") -> the share goes to Nightbolts / Ballistas; Giant queue min 2 at a time (mass) |
| Nature | Wildcaller: **called, not mixed** (t3. 10.3 rule): as soon as the Elder Circle completes, crystals >= 300 + 150, essence >= 150 + 50, pop allows -> queue it **before** the first Treant or Mossback; revive at once when essence allows | - |
| Fire | Ember Crucible: **bought, not mixed**: when the Roost completes, no defence running, crystals >= 300 + 150 -> light it **before** the first Dragon; relight a new Roost at once (150) | - |
Knobs: `second_titan_share` (per kingdom profile), `crucible_buy` (easy false / normal true / hard true), `unique_call` (t3., now
also the Wildcaller). Easy never builds a Lair (unchanged), so easy never uses 13c.
### 9.2 Counter-mix on seen 13c (memory; after cm. 9.1 / t3. 10.2 rows, first match wins)
| Seen | Change |
|---|---|
| >= 1 Frost Dragon | The cm. 9.1 "Cinder Dragon" row applies to any dragon (ranged share >= 0.55, an S2 tower, cavalry 0, own Knights and Giants 0) |
| >= 3 Barrow Giants | line share +0.10, cavalry +0.10 (they close on the Giants); Fire / Ice titan share +0.10 toward their dragon; hard: attack groups target Giants first when within 12 m |
| A Wildcaller (`titan_event`) | Hard: **B9** (t3.) generalised: Hunt 150 on the enemy unique NPC when seen within 30 m of the bot's army and the bot has a champion; ranged +0.05 |
| An Ember Crucible lit | Hard: when the Dragon Roost is known and an attack group targets buildings, the Roost is the first building row |
### 9.3 Using them
| Rule | Value |
|---|---|
| Frost Dragon | The cm. 9.2 Dragon rule (never onto a target with >= 2 enemy towers within 11 m); attack-moves with the group |
| Barrow Giants | Attack-move **3 m behind** the group centre (the Cinderlock rule, t3. 10.3); the min-range pullback is not needed (no min range); **+2 Giants** join any attack group whose target row is a building |
| Forged Guards | Normal soldiers: the trainer counts them; the rally is the Roost's rally (set to the army rally by the bot) |
| Wildcaller | ChampionBrain with her type (5.7) |
| Frost Wyrm | `mf.` 7 rule 11e + 7.5 (>= 5 ranged); champion **B11** Hunt applies |
| Strength | Titans `cost x 1.5` (a Giant 450); the Wildcaller by her `power()`; the Crucible adds nothing to strength (its Guards count as soldiers) |

## 10. UI: what must be shown (layout: ui-designer addendum to `ui-tier3.md`, task 13c.D2)
| Element | Content | Interaction |
|---|---|---|
| Lair cards | Slot **C** (r1c3) on all four Lairs with the tooltips of section 2; tier pip III; Crucible states `Light C` / `Lighting 62 %` / `Lit` (check, disabled) / `Relight 150`; Wildcaller `Call` / `Called` (greyed) / `Revive 195` | Key C with the Lair selected |
| Lair panel | Dragon Roost: `Ember Crucible: next Flame Guard 23 s · forged 4 / 6 alive` and the pause reasons (`Paused: population cap`, `Paused: 6 forged Guards`); others unchanged (`Titans raised 2 · alive 1`) | |
| Unit panel | Frost Dragon: `Flying`, `Titan`, the breath and Hoarfrost icons; Barrow Giant: `Titan` + `Stone Hide: -20 % from arrows and towers` + `Lumbering: +25 % from melee`; Spirit Wolf: lifetime bar, `Summoned by Maelis` | |
| Forged Guards | A small anvil mark on the unit panel portrait (`Forged by the Ember Crucible`); otherwise ordinary Flame Guards | |
| **Unique slot** | The t3. 11 **4th unique slot** of the champion bar now serves **the kingdom's unique NPC** (Shadow: the Mage Archer; Nature: the Wildcaller): portrait, level, HP, intent (`Grovewatch`, `Guarding the grove`, `Watching home`, champion intents), purse, `Called 23 s`, `Revive 195` | Click = centre camera; **F8** = centre on the unique NPC (was "the Mage Archer"); inspect = read-only champion inspect (3 abilities, the Wizard tree, picks); command card `The Wildcaller acts on her own. Bounty: R` |
| World | Thornsnare ring and Wild Stampede line (both teams, 0.6 s / cast); Hoarfrost patch; boulder landing shadow (a dark disc during the 1.0 s flight, both teams: it can be dodged) | |
| Warnings | Messages of 4.3, 5.3, 6.3 (enemy's in red), titan minimap diamonds for Frost Dragons and Giants (7 x 7) | |
| Frost Wyrm | See 7.5 (UI row) | |
| Help text | `F8: find your unique hero (Mage Archer / Wildcaller)` | |
| Audio (ui-coder, SFX bus) | Frost Dragon roar (the dragon roar pitched down + ice crackle; max 1 / 4 s), rime breath hiss, freeze shatter (existing), Giant throw grunt + stone thud (max 3 / s), Crucible forge clang on each forged Guard (own, visible, max 1 / 10 s), Wildcaller call horn (the call horn of t3. 11), wolf howl, stampede drum-roll, Wyrm shriek, dive whoosh, landing crash, blizzard wind loop | Throttled |

## 11. Art list (tech-artists; `art-units.md` style; one agent per line, no time box; **reuse first**)
Budgets: titan budget (<= 36 meshes, <= 20 draw instances, 0 lights, <= 2 particle systems stopped beyond 45 m) for the Frost
Dragon, the Barrow Giant and the Frost Wyrm (epic-beast hero budget of `mf.` 10 is smaller: the Wyrm uses the **titan** budget,
the one exception); champion budget (<= 26 meshes, <= 16 instances, <= 5 materials) for the Wildcaller; Spirit Wolf <= 12 meshes.
Every scene: silhouette check in `docs/art/screens/`, headless instantiation, `KITFIX AUDIT OK`.
| New asset | Built on (existing) | New work only |
|---|---|---|
| **Frost Dragon** | **`art/units/titans/cinder_dragon/flyer_model.gd`** (`FlyerModel`: pivots, flap / glide / bank, breath pose, spiral death) and the Cinder Dragon's builder (`cinder_dragon.gd`) | Ice materials (pale-blue scales, frosted translucent-looking membrane, rime crust instead of lava seams), **a new horn set** (two long swept-back ice horns + a row of ice spines along the neck and tail instead of the horned crown and flame spade), an ice-shard tail tip, glow = pale cyan in the throat and spines |
| **Frost Wyrm** (A + B) | The same **`FlyerModel`** rig | Re-proportioned: long serpentine neck and body, tail pivots stretched, **only the two forelegs** (hind legs hidden), ragged ice-feathered wings (span 8.5 m), a frilled fin crest; **grounded pose** (`set_grounded(on)`, 0.8 s: wings folded, body coiled, head low) + tail-lash timeline; variant B = white-violet crystal horns, x1.15, frost motes. Silhouette must differ from the Frost Dragon: **dragon = horns + compact body; wyrm = long serpent + fin crest** |
| **Barrow Giant** | **`art/units/neutral/warden_model.gd`** (`WardenModel extends CharacterModel`: the hunched stone golem, its stomp, slam and crumble) | `BarrowGiantModel extends WardenModel` scaled to 4.5 m; Shadow palette (dark barrow stone, violet crack veins instead of amber, a tattered burial shroud over one shoulder, a crown of broken grave-markers); carries a gravestone; **`boulder_throw`** timeline (overhead lob, release at 0.6 s); death = collapses into a barrow mound with a violet soul wisp (the warden crumble recoloured) |
| **Wildcaller** (A + B) | The champion kit: `CharacterModel` + `champion_weapon_kit.gd`, the **Mender** (the Wizard-class champion) body and staff-cast poses | Antlered hood, moss-and-feather cloak, the living staff with a blossom crown (`weapon_override &"wild_staff"`), B = the man (hood down, braided beard); `play_cast(id)` for her 3 + the Wizard-tree actives, `play_call()` (rises from the Elder Circle's root knot) |
| **Spirit Wolves / stampede stags** | The **Direwolf** beast scene (12.V29) at x0.7; the **Grove Stag** mount (13.V5) | One shared **spirit material** (painted green-white glow, rim light, dissolve on expire), applied through the existing material slots; no new meshes |
| **Ember Crucible** | The **Dragon Roost** scene (13.V25) | A crucible-and-anvil annex (child scene) with a lava pour; `set_crucible(on)`, `play_forge()` (pour flare + sparks when a Guard is forged) |
| **VFX** | Dragon breath / burning ground (13.V14), Mammoth frost aura ring (13.V19), Frostbite freeze burst (14.V16), Frost Mortar shell arc (16.V*), warden slam shockwave, Vinelasher lash, ChampionVfx pools | Ice palettes and the new shapes listed per id below |
| Id | Asset | Silhouette (40 m black test) and look | Hooks |
|---|---|---|---|
| 13c.V1 | **Frost Dragon** (`art/units/titans/frost_dragon/`) | Horned head + 7.5 m wings, compact body; reads "the blue dragon" next to the red one | FlyerModel hooks (`set_moving`, `set_turning`, `play_attack` = breath, `play_hit`, `play_death`, `set_team_color`) |
| 13c.V2 | Frost Dragon VFX | Frost breath cone (60 deg, 6.5 m, 0.6 s: snow billboards + ice glints), **Hoarfrost** patch (r 2.5, 4 s: frost decal + low mist), ice-shard trail (< 45 m), crash = ice shatter | `TitanVfx.play(&"frost_breath" / &"hoarfrost" / &"frost_crash", at, target)` |
| 13c.V3 | **Barrow Giant** (`art/units/shadow/barrow_giant/`) | Hunched 4.5 m stone giant with a gravestone raised overhead (the read) | unit hooks, `attack_style &"boulder_throw"`, `play_hit`, `play_death` |
| 13c.V4 | Boulder VFX | Tumbling gravestone chunk on the arc, landing shadow disc, impact dust ring + stone chips + a violet spark | `UnitVfx.play(&"boulder_throw" / &"boulder_impact", at, target)` |
| 13c.V5 | **Wildcaller** (`art/units/champions/wildcaller/`) | Antlered hood + tall blossoming staff | champion hooks, `play_call()` |
| 13c.V6 | Wildcaller VFX + summons | Spirit material on the wolf and stag scenes (`art/units/champions/wildcaller/spirit_*`), Thornsnare (ring + bursting thorns), Call the Pack (green mist, howl ring), Wild Stampede (3 spirit stags on the line, dust lane), unique call / revive columns (green) | `ChampionVfx.play(&"thornsnare" / &"call_the_pack" / &"wild_stampede", caster, target)` |
| 13c.V7 | **Ember Crucible** annex | A glowing crucible beside the Roost's foot (does not change the Roost's dominant nest crown) | `set_crucible(on)`, `play_forge()` |
| 13c.V8 | **Frost Wyrm** (`art/units/neutral/beasts/frost_wyrm/`) | Long serpent in the air, coiled on the ground | beast hooks, `set_variant(v)`, `set_grounded(on)`, `play_cast(&"glacial_dive" / &"tail_lash" / &"blizzard")` |
| 13c.V9 | Frost Wyrm VFX + lair | Rime breath (13c.V2 scaled), dive telegraph ring + ice burst, tail-lash arc, Blizzard (snow cylinder r 8), 30 s pre-spawn cold mist over the river; **Icebound Barge** overlay (ice sheet r 5 on the water, icicles on the barge mast, draw-only, on top of `landmarks/barge.tscn`) | `MapFillVfx` ids `wyrm_breath`, `wyrm_dive`, `wyrm_tail`, `wyrm_blizzard`, `wyrm_warning`; `art/environment/lairs/icebound_barge.tscn` with `set_occupied(bool)` |
| 13c.V10 | Icons (phase 2) | Frost Dragon, Barrow Giant, Wildcaller portraits A / B, Ember Crucible (button + panel), Thornsnare, Call the Pack, Wild Stampede, Spirit Wolf, Stone Hide, frost breath, Frost Wyrm A / B, forged-Guard anvil mark | existing icon pipeline, new files only |
Rules: 13c.V1 / 13c.V8 **read** `flyer_model.gd` and the Cinder Dragon builder; if a parameter hook is needed there (materials,
horn set, leg visibility), it is added as an **optional** export with the Cinder Dragon's values as defaults, and
`cinder_dragon_preview` must still pass unchanged. 13c.V3 extends `WardenModel` the same way (the Ruin Warden unchanged).

## 12. Performance
- New logic < **0.05 ms / frame** on average with 200 units: Hoarfrost shares the burning-ground pool (12 patches), the breath is
  the cone pass of 13.C1; boulders are the pooled `frost_shell` projectiles; the Crucible is one timer; Spirit Wolves are ordinary
  units (max 2 per Wildcaller); the Wyrm's brain is the beast brain (0.5 s ticks), +2 beasts.
- Perf test additions: 2 Frost Dragons breathing, 8 Barrow Giants throwing, 1 Wildcaller with wolves and a Stampede, a lit
  Crucible forging, 2 Frost Wyrms (one diving): `PERF OK`, stuck 0 (Giants path through a 3 m gap like the Mammoth).

## 13. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 13c.L1)
Rule for phase-1 agents (as steps 9-16): never use another 13c agent's new `class_name` as a static type; `load()` guarded by
`ResourceLoader.exists`, groups, `has_method()`, `get()`.
- **UnitType** (gameplay): new `grants_upgrade: StringName = &""` (a stub type trained at a building: on completion the building
  installs that upgrade instead of spawning a unit; the t3. `spawns_champion` pattern). Reused: `tags`, `fly_height`,
  `turn_rate_deg`, `attack_shape` / `attack_arc_deg`, `damage_taken_mult`, `building_damage_mult`, `specials`, `abilities`,
  `ability_params`, `required_keep_tier`, `essence_cost`, `spawns_champion`, `lifetime`, `commandable`, `expansion`.
  New `.tres`: `frost_dragon`, `barrow_giant`, `spirit_wolf`, `wildcaller_call` (stub: 300 + 150 essence, pop 4, 45 s,
  `spawns_champion &"wildcaller"`), `ember_crucible` (stub: 300, pop 0, 75 s, `grants_upgrade &"ember_crucible"`), `frost_wyrm`
  (neutral beast, both variants via the beast variant rule).
- **TitanAbilities** (gameplay): specials `&"frost_breath"` (`{frost: 25, chill: 2.0}` on cone hits) and `&"hoarfrost_ground"`
  (`{radius: 2.5, duration: 4.0, ahead: 4.0}`), sharing the burning-ground pool.
- **UnitAbilities** (gameplay): `boulder_throw` = the `frost_shell` lob path with `ability_params` (`flight 1.0`, `splash_ratio
  0.5`, `splash_radius 1.8`, `status &""`, `hits_air false`, `building_mult 1.0`); `frost_shell` keeps its own numbers.
- **Unit** (gameplay): `set_airborne(on: bool)` and `is_airborne() -> bool` for units with `fly_height > 0` (default airborne):
  grounded = `is_flying()` false, standing at ground height, no movement; the model gets `set_grounded(on)`. Used by the Frost Wyrm.
- **Champion / ChampionType / ChampionAbilities** (gameplay): the t3. 15 unique-NPC path, second user: `data/champions/wildcaller.tres`
  (names A / B, stats 5.2, traits 5.7, `ability_ids [thornsnare, call_the_pack, wild_stampede]`, `class_weights {wizard: 1}`, taste
  row 5.4, wish list, `weapon_override &"wild_staff"`, `power_base 250`, `power_per_level 25`, victim / revive numbers of 5.3,
  `drill_xp_per_second 2.0`, `start_xp 150`, `kingdom &"nature"`). ChampionAbilities gains the 3 ids; `call_the_pack` spawns
  `spirit_wolf` units (team of the caster, `commandable` false, target follow rule 5.6).
- **ChampionGuild** (systems): `unique_npc` / `can_call_unique` / `spawn_unique` / `unique_state` / revive work for **any**
  kingdom's unique type (one per team; the kingdom decides which): unchanged signatures.
- **TrainingBuilding / Lair** (systems): completion of a `grants_upgrade` type calls `install_upgrade(id) -> void` on the building;
  `has_upgrade(id) -> bool`; `can_queue` refuses `"Already lit"` for an installed or queued upgrade. Train lists (slot 3 = C):
  `fire_lair` + `ember_crucible`, `ice_lair` + `frost_dragon`, `shadow_lair` + `barrow_giant`, `nature_lair` + `wildcaller_call`.
- **EmberCrucible** (systems, `scripts/buildings/ember_crucible.gd`, `class_name EmberCrucible extends Node`, child `"EmberCrucible"`
  of the Roost created by `install_upgrade`): `setup(building)`, `next_in() -> float`, `forged_alive() -> int`, `state() ->
  StringName` (`&"forging"`, `&"paused_pop"`, `&"paused_max"`), constants `INTERVAL := 40.0`, `MAX_ALIVE := 6`, `UNIT_ID :=
  &"flame_guard"`, `RELIGHT_COST := 150`, `RELIGHT_TIME := 40.0`, signal `forged(unit)`. Forged units carry the meta `forged`.
- **Events** (lead): `titan_event` gains the ids `frost_dragon`, `barrow_giant`, `wildcaller`, `ember_crucible` (warnings).
- **Epic beasts** (systems / gameplay / ai, `mf.` 13): `EpicBeasts` knows **5** kinds; `grant(team, reward, by)` pays the
  `essence` key through the EssenceBank now (unknown keys ignored until step 15); CreatureAbilities gains `rime_breath`,
  `glacial_dive`, `tail_lash`, `blizzard`, `enrage`; BeastBrain gains a **flyer mode** (straight-line patrol and chase inside the
  territory, leash in x-z, the landing cycle through `set_airborne`). Lair ids `wyrm_barge_s` / `wyrm_barge_n`.
- **AIProfile** (ai): `second_titan_share: Vector3`, `crucible_buy: bool`; `unique_call` covers the Wildcaller.
- **Skirmish** (systems): harness flags `--no-titans-2` (hides the four C options and the Wyrms) and `--no-wyrm`.
- **Models / VFX**: hooks of section 11 (`set_grounded`, `set_crucible`, `play_forge`, `play_call`, style `boulder_throw`,
  weapon `wild_staff`); `TitanVfx` / `UnitVfx` / `ChampionVfx` / `MapFillVfx` ids of 11.
- **Keys**: Lair **C** (slot key, r1c3); **F8** = centre on the own unique NPC (was the Mage Archer only).
- **Ownership**: `data/units/{frost_dragon,barrow_giant,spirit_wolf,wildcaller_call,ember_crucible,frost_wyrm}.tres`,
  `data/champions/wildcaller.tres` = gameplay; `scripts/buildings/ember_crucible.gd`, the four `*_lair.tres` train lists = systems;
  art paths of 11 = tech-artists; the `ui-tier3.md` addendum = ui-designer.

## 14. What changes in other specs (13c.D3 writes them after the build, except `map-fill.md`)
`cavalry-mounts.md`: Lair slot C, the titan table (Frost Dragon, Barrow Giant; "pop 4-6" -> "pop 3-6"), duels D48-D56.
`tier3-extras.md`: section 9 table (8.2 here), the unique slot and F8 now for the kingdom's unique NPC, B9 generalised.
`map-fill.md` (its owner merges **section 7 now**, before 12.C11 / 12.A3 / 12.C4 are built if possible): the Frost Wyrm rows.
`research.md` 5: the titans table gains Frost Dragon (Heart of Winter applies) and Barrow Giant (generic soldier research only).
`kingdom-ice.md`, `kingdom-nature.md`, `units-fire-shadow.md`: pointers to the new options. `levels.md`: victim rows (Frost Dragon
325, Barrow Giant 150, Wildcaller 200 + 15 x level, Frost Wyrm 300 / 360). `ai.md`: 9. `champions.md` / `champion-skill-tree.md`:
the second unique NPC. `ui-tier3.md`: 10 (13c.D2). `CLAUDE.md` (lead): 13.

## 15. Task list (step 13c; builds after steps 13 and 13b are merged: it needs the Lairs, `TitanAbilities`, `FlyerModel`, the
unique-NPC path, `UnitAbilities` / `frost_shell`; the Frost Wyrm after step 12's epic beasts 12.C11 / 12.C4 / 12.A3)
**Phase 0:** 13c.L1, 13c.D2, the `map-fill.md` merge of section 7 (its owner). **Phase 1a (new files only, can start now):**
13c.V1, V2, V3, V4, V5, V7, V8, V9 (V1 / V8 after 13.V13 is merged; V3 after A2.7; V6 after 12.V29 and 13.V5; V7 after 13.V25).
**Phase 1b (shared files free):** 13c.C1, C2, C3, C4, C5, A2. **Phase 2:** 13c.A1, 13c.U1, 13c.V6, 13c.V10, 13c.C6, 13c.C7,
then 13c.L2, playtest, 13c.D3.
| Id | Agent | Task | Files | Done when |
|---|---|---|---|---|
| 13c.L1 | lead | Freeze 13 in `CLAUDE.md`, Keys (Lair C, F8 generalised), `titan_event` ids, owner rows, 13c ids in `waves.md`, the user's Q1-Q4 answers; route section 7 to the `map-fill.md` owner | `CLAUDE.md`, `docs/plan/` | Contracts and keys written |
| 13c.D2 | ui-designer (Fable) | Addendum to `ui-tier3.md`: section 10 at 1600 x 900 (Lair slot C states, Crucible panel line, forged mark, unique slot for any kingdom, Wyrm airborne / grounded tag, telegraphs) | `docs/design/ui-tier3.md` | Every row of 10 has position, size, look |
| 13c.C1 [H] | gameplay-coder-high | TitanAbilities `frost_breath` + `hoarfrost_ground`; UnitAbilities `boulder_throw` (lob params); Stone Hide / Lumbering through `damage_taken_mult`; `Unit.set_airborne` / `is_airborne`; the `grants_upgrade` field | `scripts/units/titan_abilities.gd`, `unit_abilities.gd`, `unit.gd`, `unit_type.gd` | Test: a Frost Dragon breath hits 3 Flame Guards for 14 each and adds 25 frost + chill 2 s; the 4th breath freezes them 1.0 s (a titan 0.5 s); Hoarfrost chills a unit inside r 2.5 and not at 3 m, never a flyer; a Giant's stone lands 1.0 s later where the target was (a target that moved 2 m takes nothing), splash 16 within 1.8 m; an Ember Archer deals x0.8 and a Flame Guard x1.25 to it; a Giant cannot target a flyer; `set_airborne(false)` lets a Flame Guard hit a flyer and `true` refuses it again; `PERF OK` |
| 13c.C2 | gameplay-coder | The 6 unit `.tres` (+ the Wyrm's stats of 7.1) and `wildcaller.tres` with the numbers of 3-7 | `data/units/*.tres`, `data/champions/wildcaller.tres` | Numbers exact (test reads them); kill_xp as listed |
| 13c.C3 [H] | gameplay-coder-high | Wildcaller on the unique-NPC path (t3. 13b.C3 code, second user): numbers from her type, 3 abilities + autocast, Spirit Wolf follow rule, save state | `scripts/units/champion.gd` (only if the 13b path needs a generalisation), `champion_abilities.gd` | Test: a spawned Wildcaller is level 3 with 3 picks and 541 HP; Thornsnare roots 3 clumped Shades 1.2 s (a titan 0.6 s) and deals 20.8; Call the Pack gives 2 wolves for 20 s that attack her target; Stampede from L6 hits 5 units in a line for ~49 and pushes them 1.5 m, never a titan; victim XP 245 at L3; save round-trip |
| 13c.C4 | systems-coder | Lair slot C train lists; `grants_upgrade` + `install_upgrade` / `has_upgrade`; `EmberCrucible` (6.3); the unique call generalised to Nature; warnings; `--no-titans-2` / `--no-wyrm` flags | `scripts/buildings/training_building.gd`, `scripts/buildings/ember_crucible.gd`, `scripts/world/champion_guild.gd`, `skirmish.gd`, `data/buildings/*_lair.tres` | Test: C at each Lair queues its option with the right price / pop / time; the Crucible forges 7 Guards in 300 s, holds at 6 alive and at the pop cap, stops when the Roost dies, relights for 150; `Already lit`; the Elder Circle calls the Wildcaller (300 + 150), a second is `Already called`; the enemy gets each warning; missions list none |
| 13c.C5 | systems-coder | Epic beasts: the 5th kind, the two Icebound Barge lairs (7.2), 13:00 first spawn, 30 s pre-warning, `grant` essence, drop table `frost_wyrm`, the 10-beast cap | `scripts/world/` epic-beast files of 12.C11, `skirmish.gd` | Test: both Wyrms spawn at 13:00 at mirrored centres, the warning shows at 12:30; a kill pays 120 essence (B 180) + the drops; respawn 720 s later with variant B; the fairness test (mirror, path lengths) still passes |
| 13c.C6 | gameplay-coder | CreatureAbilities for the Wyrm (Rime Breath, Glacial Dive + grounded 6 s + Tail Lash, Blizzard (B), enrage) | `scripts/units/creature_abilities.gd` (12.C4's file) | Test: the dive telegraphs 1.0 s, lands on the densest clump for 50 + chill, grounds the Wyrm 6 s (melee can hit it), Tail Lash 30 every 2 s, takes off; B's Blizzard fires once at 50 %; enrage below 30 % |
| 13c.A1 | ai-coder | Bot 9.1-9.3: `second_titan_share`, Crucible buy / relight, Wildcaller call / revive, counter-mix rows, Giants' placement and siege adds, dragon rule for the Frost Dragon; profiles for 4 kingdoms x 3 difficulties | `scripts/ai/commander.gd`, `ai_profile.gd`, `data/ai/*.tres` | Headless normal, games reaching a completed Lair: Ice trains a Frost Dragon when the enemy is melee-heavy, Shadow trains Giants two at a time, Nature calls the Wildcaller within 60 s of the Elder Circle, Fire lights the Crucible before its first Dragon; seeing a Frost Dragon raises ranged share >= 55 % within 2 ticks; easy uses none; `PERF OK` |
| 13c.A2 | ai-coder | ChampionBrain for the Wildcaller (traits, Grovewatch / Guarding the grove / Watching home, keep-distance, target preference); BeastBrain flyer mode + the Wyrm's landing cycle; rule 11e's ranged requirement; hunting-party ranged rule | `scripts/ai/champion_brain.gd`, `champion_sense.gd`, the beast brain file of 12.A3, `commander.gd` (11e rows only, after 13c.A1) | Test: she stands 6 m behind the group, within 8 m of a rooted Treant when there is one; the Wyrm patrols its 4 points in straight lines over the water, never beyond its leash, lands only on enemies; a bot group with 3 ranged units skips the Wyrm, with 6 it attacks it |
| 13c.U1 | ui-coder | Section 10 (cards, panel lines, forged mark, unique slot for Nature, F8, telegraphs, warnings, Wyrm UI, audio) | `scripts/ui/command_card.gd`, `selection_panel.gd`, `champion_bar.gd`, `hud.gd`, `minimap.gd`, `assets/audio/titan2_*` | As 13c.D2; nothing in `scripts/ui/` calls a `_private` function |
| 13c.C7 | gameplay-coder | Plug the models and hooks (`set_grounded`, `set_crucible`, `play_forge`, styles, `wild_staff`, spirit material on the summons) + VFX calls | `data/units/*.tres`, `data/champions/wildcaller.tres`, `scripts/units/` (hooks only), `scripts/buildings/ember_crucible.gd` (hook calls, with the systems-coder's ok) | Models replace placeholders; hooks fire; smoke `victory=true` |
| 13c.C8 | gameplay-coder | Duels D48-D62 + the Crucible check in the harness | `tests/test_13_duels.gd` (rows only) | Prints PASS / FAIL per duel |
| 13c.V1-V10 | tech-artist (one per id) | Section 11 | Section 11 paths | Hooks, budgets, silhouette screenshot, headless clean, `KITFIX AUDIT OK`; `cinder_dragon_preview` and the Ruin Warden unchanged |
| 13c.L2 | lead | Integration (VFX ids in both scenes), perf additions (12), runs of 8.6, playtest copy | `tests/`, `scenes/`, `docs/plan/` | 8.6 passes; CI green |
| 13c.D3 | game-designer | Balance from 13c.L2 logs + playtest, knobs of 8.5, section 14 edits | `docs/design/` | Notes and knob changes written here |
Playtest (user): one skirmish per kingdom to the Lair: does the Frost Dragon feel different from the Cinder Dragon (control, not
burst)? Do massed Giants shell a ranged army and die to a Guard charge? Does the Wildcaller feel like a druid who calls the wild?
Is the Crucible's refilling Guard wall worth its 300? Is the Frost Wyrm a real fight over the river?

## Done when (step 13c)
- [ ] Each Lair offers its C option only behind the Lair gate; missions list none; the enemy is warned for each.
- [ ] Frost Dragon breath freezes and chills, Hoarfrost slows, the flyer rule holds; Barrow Giants lob stones that can be dodged,
      take x0.8 from arrows / towers and x1.25 from melee, never hit flyers, and can be massed without a cap.
- [ ] The Wildcaller is called once, arrives at level 3, levels to 9 on her own, snares, calls wolves, stampedes from level 6,
      never heals, cannot be ordered, is revived at the Elder Circle; the unique slot and F8 work for Shadow and Nature.
- [ ] The Ember Crucible forges a Flame Guard every 40 s up to 6 alive, pauses at the pop cap, stops with the Roost, relights for 150.
- [ ] Two Frost Wyrms spawn at 13:00 over the mirrored frozen barges, fly, dive and land, can be shot from both banks, and pay
      their rewards; `map-fill.md` lists 5 kinds.
- [ ] Bots use all four options by section 9; duels D48-D62 in band; 8.6 passes; `PERF OK`, stuck 0; smoke test `victory=true`.

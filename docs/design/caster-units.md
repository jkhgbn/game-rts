# Caster units: one spell-casting support unit per kingdom (JS 2026-09-30)

Owner: game-designer. Written 2026-09-30 (task CU.D1, design only: no code, data or art was touched).
JS (verbatim): "find a list of only caster unit like medivac or infestor sc2 and add 1 for the 4 wizzard".
Builds on `gdd.md`, `tiers.md` ("ti."), `new-units-12.md` ("nu."), `tier3-extras.md` ("t3x."), `t3-helpers.md` ("th."),
`units-fire-shadow.md`, `kingdom-ice.md` ("ki."), `kingdom-nature.md` ("kn."), `champions.md` ("ch."), `spells.md`,
`balance-1.md`, `balance-2.md` ("b2."), `ui-hud.md` ("hud."), `sound-plan.md`, the Balance Lab notes
(`docs/plan/balance-lab.md`) and the real roster in `data/units/*.tres` (read 2026-09-30).
Every name, line, look and number below is our own. Metres, seconds, crystals.

## 0. The answer in one table
| Kingdom | New caster (id) | Role | Tier / where / key | Z ability | V ability | Passive |
|---|---|---|---|---|---|---|
| Fire | **Kilnwarden** (`kilnwarden`) | debuff / anti-caster | T2, keep **B** | **Slag Rain**: melts armour in an area | **Mana Scald**: burns an enemy caster's mana into damage | Stoke |
| Ice | **Rimecarver** (`rimecarver`) | utility / zoning | T2, keep **B** | **Rime Bulwark**: a short ice wall for 8 s | **Scrying Rune**: vision + reveals hidden units | Stillness |
| Nature | **Bramblesage** (`bramblesage`) | crowd control | T2, keep **B** | **Snagroot**: pulls one enemy to it | **Pollen Haze**: blinds ranged units in a cloud | Seedcloak |
| Shadow | **Gloom Deacon** (`gloom_deacon`) | support | T2, keep **B** | **Blood Tithe**: heal-drain tether | **Umbral Passage**: recalls an army group to the Deacon | Vigil |
**Does this request change the plan? YES.** It adds one unit to each of the four rosters (4 units), a new unit class
(soldiers with **mana** and **manual spells**, the first commandable non-wizard casters), a keep training slot (**B**),
two unit-card keys (**Z / V**) and a new step in `docs/plan/waves.md`. Details and the exact doc edits: section 9.

---

## 1. Caster units in other RTS games (what they do, why they are fun)
"Caster" here = a unit whose value is its spells, not its weapon: fragile, little or no damage, an energy / mana bar.
Our own words; only the mechanic is described, never text or art.

### 1.1 StarCraft II
| Unit (race) | What it does | Why it is fun |
|---|---|---|
| **Medivac** (Terran) | Flying transport that heals nearby infantry from an energy pool; can boost its speed | The army suddenly lasts twice as long; the drop-and-pickup dance lets a player be in two places at once |
| **Raven** (Terran) | Flying detector; drops a short-lived auto-turret, an anti-armour missile, a disabling beam on mechanical units | A spotter that sees hidden things and turns a fight with one well-placed toy |
| **Ghost** (Terran) | Sniper-infantry: a shot that drains a caster's energy, a hard snipe on biological units, a map-wide nuke, cloaking | The "counter-caster" fantasy: one click erases the enemy spellcaster's plan |
| **Infestor** (Zerg) | Burrow-walking caster: a slowing / damaging fungal cloud, a mind-control tether, spawns expendable attackers | Huge swing moments: rooting a whole army, stealing the enemy's best unit |
| **Viper** (Zerg) | Flying caster: yanks one enemy unit to it, blinds ranged ground units in a cloud, a web that grounds air weapons | Pick-off plays: pull the siege tank or the enemy hero into your army; deny a ranged line |
| **Queen** (Zerg) | Trained at the town hall: heals one unit, spreads creep, boosts the town hall's larva | The support unit that is also part of the economy: a real choice between workers and her |
| **High Templar** (Protoss) | Slow robed psychic: an area lightning storm, drains energy and burns shields, merges into an archon | Skill-shot storms that decide fights; the "feedback" on an enemy caster is a hard read |
| **Sentry** (Protoss) | Cheap caster: a small wall of force that blocks movement, a shield-reducing field, illusions | Splitting armies, sealing a ramp, fake armies that bait: pure outplay tools |
| **Oracle** (Protoss) | Fast flying harasser: a beam that shreds workers, a revealing sweep, a stasis trap | Raids and scouting with one unit; the trap punishes a careless army |
| **Disruptor** (Protoss) | Fires a slow ball that explodes after a short delay | Everyone must dodge: a single shot changes where both armies stand |
| **Mothership** (Protoss) | Cloaks everything around it, mass-recalls the army home | Invisible pushes and last-second army rescues |

### 1.2 StarCraft (first game)
| Unit | What it does | Why it is fun |
|---|---|---|
| **Medic** (Terran) | Heals infantry, blinds, cleanses statuses | Infantry that would melt becomes a sustained wall |
| **Science Vessel** (Terran) | Detector: a damage-absorbing shield on an ally, an energy-draining pulse, a plague-killer on organics | The expert's unit: shield a tank, strip casters, kill Zerg clumps |
| **Defiler** (Zerg) | A dark cloud that makes ranged attacks miss units inside, a damage plague, eats its own units for energy | Rewrites the rules of a fight: ranged armies become useless under the swarm |
| **Queen** (Zerg) | Parasite vision on a target, ensnare slow, spawns broodlings to kill one unit | Cheap information and a surgical kill |
| **Arbiter** (Protoss) | Cloaks nearby units, recalls a group to itself, freezes an area in stasis | Teleport armies into the enemy base; freeze half of an army out of the fight |
| **Dark Archon** (Protoss) | Mind control, energy-burning feedback, a confusion that makes enemies fight each other | Steal the enemy's workers or its biggest unit |

### 1.3 Warcraft III and other RTS games
| Unit (game) | What it does | Why it is fun |
|---|---|---|
| **Priest** (WC3 Human) | Heals on autocast, dispels, a buff that raises armour | The autocast heal makes every small fight a sustain race |
| **Sorceress** (WC3 Human) | Slow on autocast, invisibility on an ally, turns an enemy into a harmless critter | Neutralise the one big enemy unit for a moment |
| **Spell Breaker** (WC3 Human) | Steals buffs, feeds on spells, can take control of summons | The anti-magic answer: casters become a liability |
| **Shaman / Witch Doctor** (WC3 Orc) | Bloodlust (attack and move speed buff), purge, lightning shield; wards that heal, reveal, stun | Timing the buff before the clash; wards turn ground into a tool |
| **Spirit Walker** (WC3 Orc) | Links allies so damage is shared, can resurrect | Tanky clumps that are hard to focus down |
| **Necromancer / Banshee** (WC3 Undead) | Raises skeletons from corpses, curses to-hit, possesses an enemy unit | Corpses become an army; stealing a unit is a highlight |
| **Druid of the Talon / Dryad** (WC3 Night Elf) | Faerie fire (armour down), cyclone that removes a unit briefly, dispel | Armour shred on a target turns an even fight |
| **Monk** (Age of Empires II) | Slowly heals, converts an enemy unit to your side | The long conversion is a race: kill the monk or lose your knight |
| **Engineer / Medic** (Command & Conquer) | Repairs / heals, captures buildings | Unit that changes the map ownership, not just fights |
| **Mage / priest units** (Total Annihilation: Kingdoms) | Casters with a slowly refilling pool, area spells and heals | Our genre ancestor: magic as an army resource |

### 1.4 What makes a caster work (the rules we keep)
1. **Energy pool, not a timer.** The player banks mana before the fight and spends it in the right second (SC2 energy).
2. **One clear job each.** Heal, shred, pull, wall, blind, recall: readable at 40 m by its effect.
3. **Fragile and slow to replace.** A caster that survives is the reward; killing it first is the counter-play.
4. **Autocast for the easy part, manual for the big part.** Heals and simple debuffs autocast; walls and recalls are manual
   (bots use the same rules through AI hooks).
5. **Counter-casters exist.** Mana burn, pulls, dives and detection answer casters, so no caster is untouchable.

---

## 2. What our roster already covers (so nothing duplicates)
Read from `data/units/*.tres` (T1/T2/T3 soldiers, riders, bowmen), the wizards' spells, the helpers (th.) and champions (ch.).
"-" = nobody in that kingdom does it.
| Role / mechanic | Fire | Ice | Nature | Shadow | Anyone (champions, items) |
|---|---|---|---|---|---|
| Heal others | - | - | **Bloomtender** (autocast heal 12 / 3 s), Ysolde **Wild Bloom**, Bramble Spire regen aura | - (Malrik, Barrow Ghoul, Nightblood Reaver heal **themselves** only) | Mender champion |
| Shield others | - | **Rime Seer** (autocast shield 60), Torvald **Rime Aegis**, Aldra Glass Aegis | - | - (Hollow Oathsworn shields itself) | items |
| Slow / freeze | - (Staff of Cinders item) | Shardcaster, Rimeling, Magebow, Frost Mortar, Rime Spire, Torvald (many) | - | - | - |
| Root / entangle | - | - | Ysolde **Thornburst**, **Vinelasher**, Briar Roc, Maelis | - | - |
| Damage debuff | - | - | - | **Hexweaver** (Wither -20 % damage) | - |
| Damage-taken debuff (`marked`) | - | - | - | Mage Archer / Mother Hush (hero kits) | - |
| **Armour shred** | - | - | - | - | - (t3x. armour pierce is an attack property, not a debuff) |
| **Mana burn / anti-caster** | - | - | - | - | - |
| Area burst | Vessa **Fireball**, **Pyre Adept**, Ash Hurler | Frost Mortar | Thornburst | Soul Siphon | Genie |
| Haste / attack buff | Vessa **Kindle**, Old Vey Stormcall | - | Maelis (wolves) | - | Warlord's Horn item |
| Taunt | - | Shardguard | Greenheart Oathkeeper | - | Oathwall champion |
| Summons | - | Aldra's Sentinel | Saplings, Maelis' wolves | (Raise the Dead is a **research rite**, research.md) | items (Risen) |
| **Vision / detection** | - | - | - | - | Wayfinder champion (scouting), towers |
| Stealth | Ashveil Saboteur disguise | - | - | Hush's veil, Umbral Shroud (damage cut) | Nightveil Cloak item |
| **Temporary walls / blocking** | - | Ice Walls (buildings, permanent) | - | - | - |
| **Forced movement (pull)** | - | - | - | - | - |
| **Anti-ranged zone (blind)** | - | - | (Mossback Canopy is specified in t3x. but not built) | Hush's Smoke Cloak | - |
| **Army teleport / recall** | Vessa's Ember Step moves **her** only | - | - | - | - |
Holes worth filling (bold rows): armour shred, mana burn, vision / detection, temporary walls, pull, blind, army recall, and
**healing for Fire / Ice / Shadow**. Each new caster takes two holes that fit its kingdom and none of its own wizard's spells:
| Caster | Fills | Does NOT copy |
|---|---|---|
| Kilnwarden (Fire) | armour shred, mana burn | Vessa's burst (Fireball), blink (Ember Step), haste (Kindle); Pyre Adept's anti-swarm burst |
| Rimecarver (Ice) | temporary walls, vision / detection | Torvald's freeze / slow / shield; the Rime Seer's shield; Ice Walls (buildings: permanent, built by workers) |
| Bramblesage (Nature) | pull, anti-ranged blind | Ysolde's root / heal / summon; the Vinelasher's root; the Bloomtender's heal |
| Gloom Deacon (Shadow) | heal others (as a drain), army recall | Malrik's self-drain, Soul Siphon, Umbral Shroud; the Hexweaver's wither; Raise the Dead (research) |

---

## 3. Shared rules for the four casters (gameplay)
### 3.1 One class, one switch
| Rule | Value |
|---|---|
| Switch | `CasterKit.ENABLED` (`scripts/units/caster_kit.gd`); `enabled_here()` = the T3Kit rule (plain skirmish and the 2v2 skirmish only; missions and `scenes/main.tscn` never list them). `false` = no keep slot, no card buttons, bots never train them |
| Mana | Every caster has **max 200**, **starts with 50**, regen **0.8 / s** (full from empty in 250 s). Stats `max_mana` / `mana_regen` exist in the Stats system (CLAUDE.md "Stats"); the current mana lives on the ability node (`CasterAbility.mana`, like the wizard's SpellCaster) |
| Data | Ability ids, mana costs, ranges and the autocast defaults live in a const table `CasterKit.CASTERS` (the NewUnits12 / T3Kit pattern): **no new UnitType contract field**. The `.tres` sets only the standard fields |
| Tier | `requires_tier = 2` (Stronghold; refusal "Requires Stronghold", ti. 2) |
| Where | The **keep**, slot 5 = r2c1, key **B** (section 3.3). Every own keep of tier >= 2 trains them (expansions included) |
| Cost / pop / time | **150 crystals, pop 2, 30 s**, kill_xp **75** (cost / 2). No essence, no gold |
| No "+" | Casters have no "+" upgrade (ti. 5 is researched at a Hall; casters are keep units, like workers). Their growth is mana (3.4) |
| Attack | A feeble bolt: **5** damage, range **7**, cooldown **1.6** (DPS 3.1), aggro 9. They defend themselves, they do not fight |
| Commandable | Yes: selectable, groupable, F2 army includes them. Spells are cast by the player (keys / buttons) or by autocast |
| Counts as | A soldier for pop, victory, veterancy XP, kill essence (+2: pop 2). Not a worker; not a hero (full crowd-control durations) |
| Casting | A cast is a **0.4 s** animation (`play_cast(id)`); the caster stops to cast (Blood Tithe and Scrying Rune excepted). Global cooldown per caster **1.0 s**. `dazed` / `frozen` interrupt; `rooted` does not |
| Spell kind | All damage from these spells is kind `spell` (armour applies as to wizard spells, ki. 1); healing x `spell_power` if a caster ever gets it (it does not today) |

### 3.2 Casting, autocast, smart-cast (the player's side)
| Rule | Value |
|---|---|
| Keys | **Z** = the caster's first spell, **V** = its second (physical keys; AZERTY reads **W** and **V**). They act whenever the selection holds that kingdom's casters, whatever the active subgroup (like F / Q / E always go to the wizard). No other unit order uses Z or V (Z / X / C only act with a flag, a helper or a building selected; B only with workers only) |
| Targeting | A targeted spell shows the cross cursor + the range ring + the area preview (the Fireball flow); left-click confirms, right-click / Esc cancels. **Smart-cast**: one click = one cast by the selected caster with the most mana among those in range (else the nearest, which walks into range). **Shift+click** keeps the cursor for the next caster |
| Autocast | Each spell has an autocast flag, per caster. Toggle: **right-click the button** or **Ctrl+Z / Ctrl+V** (all selected casters). A spell on autocast shows a slowly turning gold border on its button. Defaults per spell in section 5 (heals and debuffs on, walls and recall off) |
| Autocast checks | Every 0.5 s per caster, staggered (the NewUnits12 tick), only while the caster is not moving on a player move order and not channelling. First rule that applies, one cast per check |
| Refusals | `"Not enough mana"`, `"Out of range"`, `"No target"`, `"Recharging"` (Umbral Passage cooldown), `"Can't cast now"` (dazed / frozen), `"Invalid target"` (message line, as the wizard's `cast` reasons) |
| Fog | Targets and points must be visible to the caster's team (Scrying Rune excepted: any point in range) |

### 3.3 Where they are trained: the keep, slot B (hud. "Every button shows its own key")
The keep card today: r1c1 worker **Z** · r1c2 Stronghold / Citadel / Cancel **X** · r1c3 tier-3 unit **C** · r1c4 Call / Revive
helper **V** · Set Rally after them. The casters take **r2c1, key B** (training slot 5 of `SelectionManager.SLOT_KEYS`, the next
key of the Z X C V B row: **no new key**, AZERTY also reads B). **Set Rally moves to r3c1** (the Hall's place; it has no key,
so "the keys never move" still holds). Keys on the keep card after the change: Z X C V B, all different.
| Why the keep (not the Hall) | |
|---|---|
| The Hall is full | Hall = 8 units on Z X C V B N M , (nu. 1). A 9th unit would need the `.` key (AZERTY `:`), a 9th SLOT_KEYS entry and Data Lab K1 "<= 8" changes |
| The keep is the Stronghold | T2 is the keep upgrade itself: "the Stronghold opens its mage wing" reads right |
| A real choice | The caster shares the keep's queue with workers (the SC2 Queen trade-off): 30 s of caster = 2-3 fewer workers queued |
| Fallback (if JS prefers the Hall) | Hall r3c2, key `.` (physical period; AZERTY `:`), `SLOT_KEYS` + `SLOT_LETTERS` gain `.`, Data Lab K1 limit 9. Everything else in this spec is unchanged |
Tooltip format (hud. 1.U2): `Kilnwarden  [B]\nCost 150 crystals · Pop 2 · 30 s · Tier 2\nCaster: Slag Rain melts armour; Mana Scald burns an enemy caster's mana.`
Before the Stronghold the button is greyed with `Requires Stronghold` (the T3 slot's padlock look, ti. 3).

### 3.4 Levels
Casters level 1-4 like soldiers (`levels.md`), but gain XP from spells: **3 XP per enemy unit hit / slagged / pulled / hazed /
drained**, **1 XP per 20 HP healed**, **4 XP per unit carried by Umbral Passage**, max 20 XP per cast. Each level: **+10 %
max HP, +20 max mana, +0.05 mana / s** (not damage). Veterancy names and pips as soldiers.

### 3.5 New statuses (Unit.STATUSES; `apply_status`, refresh, never stack with themselves)
| id | Effect | hero_mult | Colour / look |
|---|---|---|---|
| `slagged` | `armor` **-20** (effective armour never below 0), `move_speed` **-0.6**, damage taken **x1.10** | 0.5 | `(0.95, 0.45, 0.10)`; dark orange crust on the lower body (model `set_status(&"slagged", on)` if present, else modulate) |
| `scalded` | none (marker: cannot be Mana-Scalded again while it lasts) | - | a thin steam wisp |
| `hazed` | new keys: `range_cap` **2.5** (attacks only at targets within 2.5 m; melee unaffected), `sight_cap` **4** | 1.0 | yellow-green motes around the head |
| `tithed` | none (marker for the tether VFX and the 2-tether cap) | - | the tether beam |
`range_cap` and `sight_cap` are the only new status keys; `sight_cap` may ship later (FogOfWar stamps sight): it is a knob.

---

## 4. The four units: stats (level 1, no items)
| id | Name | HP | Armor | Regen | Dmg | Range | CD | Speed | Aggro | Sight | Radius | Height | Cost | Pop | Train | kill_xp | Key | Tier |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `kilnwarden` | Kilnwarden | 100 | 0 | - | 5 | 7.0 | 1.6 | 4.6 | 9 | 11 | 0.5 | 1.75 | 150 | 2 | 30 | 75 | B | 2 |
| `rimecarver` | Rimecarver | 90 | 5 | - | 5 | 7.0 | 1.6 | 4.2 | 9 | 11 | 0.45 | 1.7 | 150 | 2 | 30 | 75 | B | 2 |
| `bramblesage` | Bramblesage | 85 | 0 | `idle_regen_pct` 1.0 | 5 | 7.0 | 1.6 | 4.8 | 9 | 11 | 0.45 | 1.8 | 150 | 2 | 30 | 75 | B | 2 |
| `gloom_deacon` | Gloom Deacon | 100 | 0 | - | 5 | 7.0 | 1.6 | 4.6 | 9 | 11 | 0.45 | 1.8 | 150 | 2 | 30 | 75 | B | 2 |
Colours (`body_color` = secondary cloth, `projectile_color` = bolt): Kilnwarden `(0.55, 0.30, 0.15)` / `(1.0, 0.55, 0.20)` ·
Rimecarver `(0.60, 0.70, 0.82)` / `(0.70, 0.92, 1.00)` · Bramblesage `(0.55, 0.62, 0.30)` / `(0.85, 0.95, 0.45)` · Gloom Deacon
`(0.30, 0.18, 0.40)` / `(0.75, 0.30, 0.55)`. Projectile speed 22.
- Speed lines kept: Fire 4.6 (the kiln on its back; Pyre Adept 4.8), Ice 4.2 (the Rime Seer's line), Nature 4.8 (Bloomtender),
  Shadow 4.6 (Hexweaver).
- EHP (EHP = HP x (1 + armor / 100)): 100 / 94.5 / 85 (+ regen) / 100: equal within 15 %. All die to **two Fireballs** (60 + 60),
  one Rime Bolt + one Grave Hound bite chain, a single Frost Mortar clump shot + follow-up. That fragility is the design.
- Combat value (CE = EHP x DPS / cost² x 100, bowmen.md 2.1): **~1.3**, the lowest of any trained unit (Pyre Adept 3.0).
  All their value is the spells (section 7).

---

## 5. Abilities
Format: `id` · key · mana · range · effect · **autocast default** · autocast rule. Amounts are level 1.

### 5.1 Fire: Kilnwarden (debuff / anti-caster: "melt the wall, silence the mage")
| id | Name | Key | Mana | Range | Effect | Autocast |
|---|---|---|---|---|---|---|
| `slag_rain` | **Slag Rain** | Z | **75** | 10 | Point, radius **3.0**. A glob of molten slag is flung (0.6 s arc; an orange ring on the ground for both teams during the flight), then lands: enemy units inside take **12** and get `slagged` **10 s** (armor -20, floor 0; move -0.6; damage taken x1.10; heroes, champions, helpers, titans 5 s). Buildings: unaffected | **ON**: a point in range with >= 4 enemy units within 3 m, or >= 2 enemy units with armor >= 10, or a titan; skipped if half of those units are already `slagged` for > 4 s |
| `mana_scald` | **Mana Scald** | V | **50** | 9 | Unit with mana (an enemy wizard or caster; units without mana are an invalid target). A steam lash (0.3 s): burns **min(60, its mana)** and deals that much `spell` damage; the target is `scalded` **6 s** (no second Scald from any Kilnwarden) | **ON**: an enemy caster in range with >= 50 mana (most mana first), else the enemy wizard with >= 40 mana |
| `stoke` | **Stoke** (passive) | - | - | - | When an enemy unit this Kilnwarden slagged dies while `slagged` (any killer), it gains **+8 mana** (max once per 0.5 s) | - |
Why it fits: Fire burns and melts. Vessa buffs her own army (Kindle) and deletes clumps (Fireball); the Kilnwarden makes the
**enemy** softer, which Fire lacked against Ice armour (Rimeshield 15 -> 0, Shardguard 25 -> 5, Frostcrown 35 -> 15) and against
enemy casters. Mana Scald on an enemy caster with 60 mana: 60 damage of its 85-100 HP and an empty bar.

### 5.2 Ice: Rimecarver (utility / zoning: "the wall comes to you")
| id | Name | Key | Mana | Range | Effect | Autocast |
|---|---|---|---|---|---|---|
| `rime_bulwark` | **Rime Bulwark** | Z | **50** | 10 | Point. An ice wall **4.0 m long, 0.9 m thick, 2.2 m high**, perpendicular to the line caster -> point (the cursor shows the ghost), rises in 0.3 s and stands **8 s**. Blocks **ground movement of both teams**; never blocks projectiles, spells, flyers or sight. Units in the footprint are pushed to its nearer long side. A **titan**, or any unit of **pop >= 3** that walks into it for **1.0 s**, shatters it. Max **4** Bulwarks alive per team (the oldest melts). Not on water or on a building | **OFF** (a micro spell; bots use 8.3) |
| `scrying_rune` | **Scrying Rune** | V | **25** | 12 | Point (fog allowed). A rune-stone sticks in the ground for **20 s**: vision radius **10** (a SightMarker, group `"fog_sources"`) and, inside it, **reveals** hidden or disguised enemies (Mother Hush's veil, the Ashveil Saboteur's disguise, any future stealth). Invulnerable. Max **3** runes per Rimecarver | **OFF** |
| `stillness` | **Stillness** (passive) | - | - | - | After **3 s** without moving: mana regen **x1.5** (1.2 / s) | - |
Why it fits: Ice is the patient kingdom of walls and fortresses (ki. 1), but its armies are slow and die to dives (b2. D5,
t3x. 5.4). A Bulwark in front of the Frost Mortar stops the Grave Hounds; one behind a retreat saves the slow army; one on a
bridge splits the enemy. Torvald freezes and shields; the Rimecarver **shapes the ground** and **sees** (spotters for the
13-range Frost Mortar and the future 15-range riflemen). Distinct from Ice Walls: those are buildings (workers, 20 crystals,
permanent, rebake the navmesh); a Bulwark is an 8-second spell.

### 5.3 Nature: Bramblesage (crowd control: "the forest reaches out")
| id | Name | Key | Mana | Range | Effect | Autocast |
|---|---|---|---|---|---|---|
| `snagroot` | **Snagroot** | Z | **75** | 9 | Enemy unit. A thorned vine hits in 0.25 s and **drags it 7 m** toward the Bramblesage over 0.5 s (**4 m** for wizards, champions, helpers; stops at obstacles, water edges and Bulwarks), then `rooted` **1.0 s** (heroes 0.5). Interrupts channels and aims (Blood Tithe, Umbral Passage, a future Rime Lock). **Immune**: titans, epic beasts, buildings, units of pop >= 4 | **ON**: an enemy caster in range -> enemy siege / artillery (Ash Hurler, Frost Mortar, Cinder Arbalest) -> the enemy wizard under 50 % HP when >= 3 own soldiers stand within 6 m of the Bramblesage. Never a unit already within 4 m |
| `pollen_haze` | **Pollen Haze** | V | **100** | 10 | Point, radius **3.5**, **6 s**, visible to both teams (a drifting yellow cloud). Enemy ground units inside get `hazed` (refreshed every 0.25 s, lingers 0.5 s after leaving): **ranged attacks only at targets within 2.5 m**, sight 4. Spells, melee, towers and flyers unaffected | **ON**: >= 4 enemy ranged units (attack range > 3) within 3.5 m of a point in range |
| `seedcloak` | **Seedcloak** (passive) | - | - | - | The first time it drops under **50 %** HP it bursts a free **2.5 m** Pollen Haze on itself for **3 s**; once per **45 s** | - |
Why it fits: Nature roots and entangles (kn. 1). Ysolde roots an area and heals; the Vinelasher roots one diver next to it;
the Bramblesage **moves** units (the pull) and **silences a ranged line** (the haze). It answers Nature's known weakness
(fragile swarms melted by archers and artillery, kn. 1 "Weakness") without adding sustain, which Nature already has too much
of (b2. D1).

### 5.4 Shadow: Gloom Deacon (support: "the dark tithes for the faithful")
| id | Name | Key | Mana | Range | Effect | Autocast |
|---|---|---|---|---|---|---|
| `blood_tithe` | **Blood Tithe** | Z | **2.5 / s** (channel; >= 10 to start) | 7 (breaks at 9) | Own unit (not buildings, not the Deacon itself; wizards, champions and helpers yes). A violet tether: the ally heals **10 HP / s**; the **nearest enemy unit within 5 m of the ally** loses **5 HP / s** (`spell`, drained toward the ally along a second thread). No enemy near: heal only. The Deacon may walk while channelling (not attack). Stops at full HP, death, range 9, or mana < 1. Max **2** tethers on one ally (`tithed`) | **ON**: the own non-worker unit within 7 m with the lowest HP % under **85 %** (wizard / champion / helper first when under 50 %) |
| `umbral_passage` | **Umbral Passage** | V | **100** | 45 | Point the team sees, max 45 m from the Deacon; cooldown **45 s**. A **2.5 s** channel: a violet rift opens at the point **and** at the Deacon (both visible to both teams). At the end, own **soldiers** (not wizards, champions, helpers, workers, caravans, titans) within **4 m** of the point, up to **10 pop**, step out of the rift in a ring around the Deacon. Cancelled (mana kept, cooldown 5 s) if the Deacon moves, is `dazed` / `frozen`, is pulled (Snagroot) or dies | **OFF** (bots use 8.3) |
| `vigil` | **Vigil** (passive) | - | - | - | **+5 mana** when an own soldier dies within 8 m (max once per 0.5 s) | - |
Why it fits: Shadow curses and drains (spells.md, nu. 2). Malrik drains **for himself**; the Deacon drains **for the army**, the
first healing Shadow soldiers get (Fire and Ice have none either, but Fire is strong and Ice has shields). Umbral Passage is the
Shadow fantasy of stepping through the dark: save a dying army, or open a second front. Shadow is the weakest kingdom in the
first Balance Lab batch (1 / 6 wins, balance-lab.md "First suggest"): its caster adds the most sustained power (section 7).
200 mana of Blood Tithe = 80 s = **800 HP healed + up to 400 drained**, the SC2 Medivac's budget. Compare the Bloomtender:
4 HP / s forever for 90 crystals and pop 1: slower, endless; the Deacon heals in bursts and runs dry.

### 5.5 The four side by side
| | Kilnwarden | Rimecarver | Bramblesage | Gloom Deacon |
|---|---|---|---|---|
| Role | debuff / anti-caster | utility / zoning | crowd control | support |
| Casts from a full bar (200) | 2 Slag Rains + 1 Scald | 4 Bulwarks, or 8 runes | 1 Haze + 1 Snagroot | 80 s of Tithe, or 2 Passages |
| First cast after training (start 50) | Scald at once; Slag Rain at 31 s | Bulwark at once | Snagroot at 31 s | Tithe at once (20 s of it) |
| Default autocast | both on | both off | both on | Tithe on, Passage off |
| Its hard counter | Snagroot, dives | Mana Scald, dives, pop-3 units shattering walls | Mana Scald, archers out of the haze, dives | Mana Scald, Snagroot (breaks the channel), burst |
Each kingdom's caster counters another's: Fire's Mana Scald empties any caster; Nature's Snagroot drags any caster into its
army and breaks Tithe / Passage channels; Ice's Scrying Rune reveals Shadow's stealth; Ice's Bulwark stops the dives that kill
casters; Shadow's Passage rescues a group caught in a Pollen Haze or on the wrong side of a Bulwark.

---

## 6. Counters and weaknesses (why they are casters, not soldiers)
| Unit | Beats (with mana) | Loses to | Weakness by design |
|---|---|---|---|
| Kilnwarden | Armoured lines (Ice line, knights, cataphracts, Shardguard), enemy casters and wizards low on mana, titans (x1.10 + armour) | Anything that reaches it (100 HP, 4.6 m/s): Grave Hounds, cavalry, Scorchlings; Snagroot (pulled into the enemy army); a Gloom Deacon's Tithe healing through the extra damage; armour-0 swarms (only the x1.10 applies) | Useless vs armour-0 swarms beyond the x1.10; Scald needs targets with mana (only wizards and casters) |
| Rimecarver | Dives and charges (walls), retreats, chokes and bridges, stealth (runes), fights in fog | Mana Scald (50 mana = one fewer wall), big units (pop >= 3) smashing walls, flyers and ranged units (walls stop legs, not arrows), being caught alone (4.2 m/s) | No damage at all from its spells: a badly placed wall traps its own army |
| Bramblesage | Ranged lines (Ember Archers, Nightbolts, Shardcasters, Magebows), artillery, lone casters and wounded wizards | Melee armies (the haze does nothing to them), Mana Scald, Grave Hounds and cavalry, area burst on its 85 HP | 100 mana for the haze: one per fight; the pull can drag a strong unit **into** a weak army |
| Gloom Deacon | Long fights, Shade / Knight pushes that trade slowly, rescuing armies, flanks | Burst (it heals 10 / s, not 100), Snagroot and Mana Scald (both break or starve the tether), a Pollen Haze-free rush on it, Fireball on the clump it tethers | Channel: it must stay within 9 m of the ally, in the fight; the Passage telegraphs 2.5 s to both teams |
Shared: pop 2 for ~3 DPS; 150 crystals; 30 s from the keep's worker queue; the enemy sees the mana bar (section 10) and the
telegraphs (Slag ring, Haze cloud, Passage rifts, Bulwark ghost is local only).

---

## 7. Balance across the four kingdoms
### 7.1 The power budget (what 150 crystals / 2 pop buy per fight)
A normal fight lasts 20-30 s (b2. 0). Per full bar, at level 1:
| Caster | Value in one fight (estimate) | Same crystals in the kingdom's T1 line | Verdict |
|---|---|---|---|
| Kilnwarden | Slag on ~5 units for 10 s: +10 % damage on armour-0 targets, **+30 %** on armour 20 -> ~+15-25 % army DPS for a third of the fight, x2 casts; Scald removes one enemy spell (~40-60 mana = a Fireball / Thornburst) | ~1.7 Flame Guards (CE 19.3) | Strong vs Ice / armour, weak vs Nature swarms: matchup unit |
| Rimecarver | 2-4 walls: denies 1-2 dives on the back line (~100-200 crystals of ranged units saved) or one lost retreat; runes: fights in fog like a watchtower | ~1.6 Rimeshields | Skill-dependent; strong in bot hands only with 8.3 |
| Bramblesage | One haze: 4+ ranged units deal ~0 for 6 s (a third of the fight); one pull: a caster / Mortar killed | ~2.5 Thornlings | Strong vs ranged mixes, weak vs melee rushes |
| Gloom Deacon | ~250-300 HP healed + ~150 drained in a fight (~2 Shades kept alive), then empty; Passage: saves ~10 pop once | ~1.9 Shades | The most **sustained** value, as Shadow needs (1 / 6) |
Targets for the Balance Lab (duels in 7.2 and the matrix): a caster makes its side **better** than the same crystals in its
kingdom's T1 line in its good matchup (+15 to +50 points of win rate in the duel) and **not worse by more than 10 points** in a
bad one. Nature and Fire (5 / 6 in the first batch) got the most expensive key spell (Haze 100) and the most matchup-bound
caster (Kilnwarden); Shadow and Ice (1 / 6) got the most bot-friendly sustain (Tithe autocast) and the dive answer (Bulwark).

### 7.2 Duels (Balance Lab, 10 seeds each, level 1, no items; the caster starts with **full mana** in the caster arm)
Each duel runs twice: the **caster arm** and a **control arm** with the caster replaced by the same crystals in its T1 line.
| # | Duel | Caster arm | Control arm | Pass band |
|---|---|---|---|---|
| C1 | 6 Flame Guards + Kilnwarden (690) vs 7 Rimeshields (665), open ground | autocast on | 8 Flame Guards (720) | caster arm win rate >= control + 20 points, <= control + 60 |
| C2 | 11 Thornlings + Bramblesage (810) vs 8 Ember Archers (800), from 20 m | autocast on | 13 Thornlings (780) | as C1 |
| C3 | 5 Shardcasters + Rimecarver (700) vs 6 Grave Hounds + 2 Shades (580) diving from 20 m | bot rule 8.3 a | 5 Shardcasters + 2 Rimeshields (740) | as C1 |
| C4 | 6 Shades + Gloom Deacon (630) vs 7 Flame Guards (630) | autocast on | 8 Shades (640) | as C1 |
| C5 | Bad matchups: Kilnwarden arm of C1 vs 12 Thornlings; Bramblesage arm vs 9 Flame Guards | autocast on | the control arms | caster arm >= control - 10 points |
| C6 | Counter-casters: 1 Kilnwarden vs 1 Bramblesage, both full mana, 10 m, casters only + 3 Flame Guards / 4 Thornlings | autocast on | - | Scald lands first (Kilnwarden kept its caster alive in >= 6 / 10), Snagroot lands in >= 8 / 10 |
| C7 | Retreat: 12 Shades at 40 % HP 30 m from home chased by 10 Flame Guards; a Deacon at home casts Passage | bot rule 8.3 | no Passage | >= 8 Shades alive vs <= 4 |
Knobs if a caster dominates (first ones to turn): Slag armour -20 -> -15; Bulwark 8 s -> 6 s; Haze 6 s -> 4 s; Tithe heal
10 -> 8 / s; Passage 10 pop -> 8. If one is useless: mana start 50 -> 75, cost 150 -> 135.

### 7.3 Fit with each kingdom's identity (and not the wizard's)
| Kingdom | Identity (gdd / kingdom docs) | Wizard's spells | The caster adds | Kept apart |
|---|---|---|---|---|
| Fire | Burst, haste, burn | Fireball, Ember Step, Kindle | Melts **enemy** armour, burns **enemy** mana | No haste, no burst, no blink |
| Ice | Patience, armour, walls, chill | Rime Bolt, Flash Freeze, Rime Aegis | Temporary walls, sight, stealth reveal | No slow, no freeze, no shield |
| Nature | Swarm that grows back, roots, heals | Thornburst, Wild Bloom, Call the Thicket | Pull, anti-ranged cloud | No heal, no area root, no summon |
| Shadow | Elite few, drain, curses, stealth | Shadow Lance, Soul Siphon, Umbral Shroud | Drain **for allies**, army recall | No self-drain, no damage curse, no stealth |

---

## 8. Bots (ai-coder; new file `scripts/ai/ai_casters.gd`, hooked like `T3Kit.bot_tick` from `commander._think`)
### 8.1 Training
| Rule | Easy | Normal | Hard |
|---|---|---|---|
| Casters kept alive | 0 | 1 at tier 2, 2 at tier 3 | 2 at tier 2, 3 at tier 3 |
| When | - | Tier >= 2, the keep's queue holds no worker (or workers >= target), crystals >= 150 + `BOT_RESERVE` 100 | same, and before the first T2 Hall unit |
| Cap | - | Casters <= 10 % of soldier pop (rounded up) | same |
| Where | the keep closest to the army's rally point | | |
Knobs: `CasterKit.BOT_KEEP := {0: 0, 1: 1, 2: 2}` (+1 at the Citadel), `BOT_SHARE_CAP 0.10`.

### 8.2 Positioning and protection (every 0.5 s per bot caster)
| Rule | Value |
|---|---|
| Follow | The largest own attack group: stand **4 m behind its centre**, on the side away from the nearest seen enemy (the Mender rule, ch. 8.3). No group: stand 6 m behind the own keep toward the map centre |
| Never lead | Its attack-move point is 4 m behind the group centre (the Cinderlock rule, t3x. 10.3) |
| Flee | A melee enemy within **3.5 m**, or HP < **50 %**: move **6 m** toward the group's rear / the nearest own tower; max once per 1.5 s |
| Retreat first | When the commander retreats a group, its casters leave first |
| Strength | A caster counts `cost x 0.5` in the commander's strength (it does not fight), `x 1.0` when its mana >= its cheapest spell's cost x 2 |
| Enemy casters | Target preference of every bot army gains **enemy caster** right after "enemy wizard under 30 % HP" (hard: cavalry and hounds dive them when >= 2 are seen) |
| Counter-mix | Seen >= 2 enemy casters: fast units (cavalry, hounds, Scorchlings, Thistle Darters) +0.05 |

### 8.3 Casting (all spells use their autocast rules of section 5 for bots, **all on**, plus these)
| Caster | Bot rule | Difficulty |
|---|---|---|
| Kilnwarden | Autocast rules; hard: Mana Scald waits for an enemy caster's cast (or 1.5 s) when the enemy wizard is in range too, then hits the caster | reaction: easy 1.5 s, normal 0.5 s, hard 0.25 s (all casters) |
| Rimecarver | **a) Dive guard**: an enemy melee or mounted unit within 9 m whose target is an own ranged unit, caster or the wizard, 3-9 m from it -> Bulwark 2.5 m in front of the victim, perpendicular to the diver's approach. **b) Retreat cover** (hard): the group retreats with enemies chasing within 8 m -> Bulwark behind the last own unit. Max one Bulwark per 3 s per team. **c) Runes**: every 30 s while attacking, a rune 10 m ahead of the group; an own unit hit by an unseen source -> a rune on it | normal: a only; hard: a, b, c |
| Bramblesage | Autocast rules; hard: holds Pollen Haze for a clump of >= 5 ranged units when the fight has just started (first 5 s) | |
| Gloom Deacon | Blood Tithe autocast. **Anchor**: with 2+ Deacons, one stays at home (the "anchor"). **Passage**: (normal, hard) the commander retreats a group whose centre is >= 25 m from a Deacon with 100 mana -> Passage on the group's densest point; (hard) the base is attacked while the main group is >= 35 m away -> Passage on the group centre, if the Deacon is at home | normal: retreat Passage only |
Test hook: `AICasters.last_cast(team) -> Dictionary` (id, target, time) for `tests/test_casters.gd`.

---

## 9. What changes in the plan (explicit)
**Yes: this request changes the plan.** It adds one caster to each of the four rosters (Fire, Ice, Nature, Shadow), a new unit
class (mana + manual / autocast spells on soldiers), keep slot **B**, unit-card keys **Z / V**, and a new step. It does **not**
change the tier ladder, the Hall rosters, the T3 units, the helpers, the wizards or any frozen contract signature (the data
sits in `CasterKit`, no new UnitType field). Frozen playtest build and its worktrees: untouched.

### 9.1 Plan docs to edit (the lead / owners, after JS says yes)
| Doc | Owner | Change |
|---|---|---|
| `docs/plan/waves.md` | lead | New section **"Step 21: Caster units (JS 2026-09-30)"**: the verbatim request, link to this spec, task ids of 9.2, the order (D2 -> C1 / C2 / U1 in parallel -> A1 -> V / S), "done when" = 9.3; add the 4 casters to the playtest checklist |
| `docs/plan/tiers-wave.md` | lead | Shared contracts: add "**Casters** [caster agent]: `caster-units.md`, `requires_tier = 2`, keep slot B" |
| `docs/design/tiers.md` | game-designer | 2 "What each tier unlocks", Stronghold row: add "the kingdom's **caster** at the keep (B): Kilnwarden, Rimecarver, Bramblesage, Gloom Deacon". 3 UI: keep card gains B, Set Rally r3c1 |
| `docs/design/ui-hud.md` | ui-designer | Keys table: Keep (skirmish) `... r1c4 V · r2c1 caster **B** · Set Rally r3c1`; Soldier(s) row: casters show **Z / V** at r2c1 / r2c2 (autocast border, right-click / Ctrl toggles); selection panel: caster **mana bar** (single view) and a 3 px mana strip (multi view); help text line `Z / V: caster spells (Ctrl: autocast)` |
| `docs/design/buildings.md` | game-designer | Keep row: `Worker Z · (tiers) X C V · Caster B (T2)` |
| `docs/design/units-fire-shadow.md`, `kingdom-ice.md` 3 / 5, `kingdom-nature.md` 2 / 4 | game-designer | One line each in the unit table: the caster (trained at the keep, B, T2), pointing here |
| `docs/design/balance-2.md` or a new `balance-3.md` | game-designer | After the Balance Lab run: the C1-C7 results and any knob from 7.2 |
| `docs/design/sound-plan.md` | ui-coder | New table "Casters" (section 11) |
| `CLAUDE.md` | lead | **Keys** line: `Units selected: ... **Z / V** = caster spells (Ctrl+Z / Ctrl+V autocast)`; `Building selected: ... keep B = caster (T2)`. Contracts: one line "**Casters** (step 21, `caster-units.md`): `CasterKit` (`scripts/units/caster_kit.gd`), `CasterAbility` node `\"CasterAbility\"` on each caster: `mana`, `max_mana()`, `cast(id, target) -> String`, `set_autocast(id, on)`, `autocast(id)`, signals `mana_changed`, `spell_cast(id)`; statuses `slagged`, `scalded`, `hazed`, `tithed`; `Unit.displace(to: Vector3, seconds: float)`" |
| `docs/plan/ideas-inbox.md` | lead | Mark JS's request as taken (-> step 21) |

### 9.2 Implementation tasks (step 21; one agent per line, owners from CLAUDE.md)
| Id | Agent (effort) | What | Files |
|---|---|---|---|
| CU.D2 | ui-designer (high) | Card layout for the caster buttons (autocast border, targeting ghosts: Bulwark wall, Haze cloud, Passage ring), mana bars, keep B + Set Rally r3c1, tooltips, help line; a short section in `ui-hud.md` | `docs/design/ui-hud.md` |
| CU.C1 **[H]** | gameplay-coder-high | `CasterKit` (switch, `CASTERS` table, `enabled_here`, `keep_types`, `gate_reason`, `description`), `CasterAbility` node (mana, regen, levels 3.4, 8 spells, 4 passives, autocast tick, smart-cast API), statuses 3.5 (`range_cap`, `sight_cap`), `Unit.displace` (navmesh-clamped, 0.5 s, cancels orders, respects water / Bulwarks), the Bulwark body (StaticBody3D on layer 1 + NavigationObstacle3D avoidance, **no navmesh rebake**; shatter rule; max 4), Scrying Rune on `SightMarker` + reveal hook for Hush's veil and the Saboteur's disguise, Passage teleport ring (nearest free navmesh points), 4 `.tres` | `scripts/units/caster_kit.gd`, `scripts/units/caster_ability.gd`, `scripts/units/rime_bulwark.gd`, `scripts/units/unit.gd` (statuses, `displace`, one `_ready` attach line), `data/units/{kilnwarden,rimecarver,bramblesage,gloom_deacon}.tres` |
| CU.C2 | systems-coder | Keep training slot 5 (B) from `CasterKit.keep_types` (after T3Kit's), queue sharing, spawn at the keep door; `requires_tier` gate | `scripts/buildings/training_building.gd` (hook lines tagged `caster-units.md`) |
| CU.U1 | ui-coder | Unit card Z / V (r2c1 / r2c2), autocast toggle (right-click, Ctrl+Z / Ctrl+V), targeting flow with previews, smart-cast, Shift queue; keep card B + Set Rally r3c1; mana bar + strips; tooltips; `KeyLabels` hints (AZERTY W / V); help text | `scripts/ui/command_card.gd`, `selection_manager.gd`, `selection_panel.gd`, `hud.gd` |
| CU.A1 **[H]** | ai-coder (high) | Section 8: training, positioning, flee, casting rules, anchor Deacon, target preference, counter-mix, difficulty knobs, `last_cast` test hook | `scripts/ai/ai_casters.gd`, `scripts/ai/commander.gd` (bot_tick + target preference lines) |
| CU.V1 | tech-artist (medium) | Kilnwarden model (10.1) | `art/units/fire/kilnwarden/` |
| CU.V2 | tech-artist (medium) | Rimecarver model (10.2) | `art/units/ice/rimecarver/` |
| CU.V3 | tech-artist (medium) | Bramblesage model (10.3) | `art/units/nature/bramblesage/` |
| CU.V4 | tech-artist (medium) | Gloom Deacon model (10.4) | `art/units/shadow/gloom_deacon/` |
| CU.V5 | tech-artist (medium) | VFX Fire + Ice (Slag Rain, slagged crust, Mana Scald, Bulwark rise / stand / shatter / melt, Scrying Rune) | `art/vfx/caster_fire*`, `art/vfx/caster_ice*`, `scripts/vfx/unit_vfx.gd` ids (ui-coder wires) |
| CU.V6 | tech-artist (medium) | VFX Nature + Shadow (Snagroot vine, Pollen Haze cloud, Seedcloak puff, Blood Tithe tether + drain thread, Passage rifts, Vigil wisp) | `art/vfx/caster_nature*`, `art/vfx/caster_shadow*` |
| CU.V7 | tech-artist (medium) | Icons: 4 unit icons, 8 spell icons, 4 status icons (`slagged`, `scalded`, `hazed`, `tithed`), autocast border sprite | `art/icons/units/`, `art/icons/abilities/` |
| CU.S1 | ui-coder | SFX (section 11) through `order_sfx_generator.gd` + `GameAudio.SOUND_PLAN`; 4 voice sets through the Voice Forge (`data/voice/cast.json` entries 11.2, lines rendered with Kokoro) | `assets/audio/`, `data/voice/`, `scripts/audio/game_audio.gd` |
| CU.T1 | lead (glue) | `tests/test_casters.gd` (9.3), updates to `test_ui_card_hotkeys.gd` (keep card Z X C V B; caster card Z / V never clash; AZERTY labels), `test_tiers.gd` (B greyed "Requires Stronghold"), perf test additions (12) | `tests/` |
| CU.L1 | lead / lab owners | Data Lab: new check **CU1** "Casters": each id of `CasterKit.CASTERS` has a `.tres`, `requires_tier` 2, pop 2, `card_key` "B", 2 spells + 1 passive known, mana fields > 0; K1 unchanged (keep = 5 slots). Balance Lab: casters are a **"caster" peer class** (like `support_kind` units: no DPS / cost knob), duels C1-C7 in the duel harness. Art Lab: the 4 models in the soldier budget census + standard shots. UI Lab: the keep card and a caster card at 1600x900 / 1920x1080 / 3440x1440 (no duplicate hotkeys) | `tools/data_lab/`, `tools/art_lab/`, `tools/balance_lab/` (or `tools/bot_lab/`), `tools/ui_lab/` |
| CU.D3 | game-designer (high) | After the first Balance Lab run: tune with the 7.2 knobs, write the results | this file, `balance-3.md` |
Parallelism: C1 first 15 min publishes `CasterAbility` API in `docs/handoff/casters.md`; C2, U1, A1 code against it with
`has_method` guards; V1-V7 and S1 are independent. ~14 agents; art at medium, C1 / A1 high (effort rule).

### 9.3 Done when
- [ ] CU.C1: `tests/test_casters.gd` PASS: mana 50 -> 200 at 0.8 / s; each spell's numbers (Slag armour 20 -> 0 floor, x1.10,
  10 s / heroes 5 s; Scald burns min(60, mana) and deals it, `scalded` 6 s; Bulwark blocks a unit for 8 s, a pop-3 unit shatters it
  in 1 s, max 4; Rune reveals a veiled Hush; Snagroot moves a Shade 7 m and a wizard 4 m, roots 1 s, never a titan; Haze stops an
  Ember Archer shooting at 9 m, not at 2 m; Tithe heals 10 / s and drains 5 / s at 2.5 mana / s, max 2 tethers; Passage moves
  <= 10 pop in 2.5 s, cancels on a move); autocast defaults; levels 3.4.
- [ ] CU.C2 / U1: keep card Z X C V B (B greyed before the Stronghold); caster card M C H X + Z V; AZERTY shows W for Z;
  `test_ui_card_hotkeys.gd` PASS for 4 kingdoms; right-click / Ctrl toggles autocast.
- [ ] CU.A1: bot-vs-bot normal, each kingdom: 1 caster by ~6:00 (the Stronghold ~5:00), >= 3 casts per fight, the caster alive
  after >= 50 % of fights; Rimecarver dive guard and Deacon retreat Passage seen in a hard run (`last_cast`).
- [ ] Smoke (`victory=true`), perf `PERF OK` with the 12 load, Data Lab CU1 PASS, Art Lab no FAIL, Balance Lab C1-C7 inside bands
  (or a knob change written in CU.D3).

---

## 10. Art briefs (tech-artist, medium effort; `art-units.md` style: chunky, silhouette = role, painted shaders, closed palette of
`art/units/kit/materials`, **1-2 glow points readable at 40 m**, **0 lights**, soldier budget **<= 26 meshes, <= 14 draw instances**,
<= 2 particle systems; `CharacterModel` hooks + `play_cast(id)` for each spell id; `set_status(&"slagged" | &"hazed", on)` optional)
Faces: every caster gets a **FaceKit** face (`art/units/kit/face/face_kit.gd`, `FaceKit.attach(...)` with **eyes, lips / mouth,
ears and hair** set, `detail: &"low"`, `_face.auto(self)` in `_extra_process` so casts show `shout` and deaths `worried`),
using the kingdom's face helper (`ShadowFaces`, `NatureFaces`, the Ice / Fire skins).
Reuse first: start from the kingdom kit (`fire_model.gd`, `ice_model.gd`, `nature_model.gd`, `shadow_model.gd`) and the nearest
caster (Pyre Adept, Rime Seer, Bloomtender, Hexweaver) for pivots and poses; never edit their files.

### 10.1 Kilnwarden (Fire, 1.75 m, `art/units/fire/kilnwarden/`)
- **Read at 40 m: a walking forge.** A broad, stooped smith-priest carrying **a small brick kiln on his back** like a pack, its
  short chimney rising above his head and puffing smoke; the kiln mouth glows orange (glow point 1). In his right hand **long
  smith's tongs gripping a glowing ingot** (glow point 2). Distinct from the Pyre Adept (tall staff + brazier) and the Cinderlock
  (musket).
- Body: team-colour cassock under a heavy **leather apron**, bronze gauntlets, soot on the hem (`fire_cloth`, `fire_leather`,
  `fire_bronze`).
- Face (FaceKit): preset `stern`, **ears round**, **hair none (bald crown) with a grey braided spade beard** (`beard: &"spade"`),
  heavy brows, amber eyes `(0.95, 0.65, 0.25)`, a firm closed mouth; skin `fire_skin` with soot cheeks.
- Motion: attack `caster_fire` (tongs flick a spark bolt); `play_cast(&"slag_rain")` 0.8 s = the tongs swing up and fling the
  ingot's drip in an arc, the kiln flares; `play_cast(&"mana_scald")` 0.6 s = the left palm opens toward the target and pulls,
  the kiln mouth flashes **white-blue** for 0.2 s. Death: FireModel burn; the kiln gutters out and cracks.
### 10.2 Rimecarver (Ice, 1.7 m, `art/units/ice/rimecarver/`)
- **Read at 40 m: a mason with a menhir.** A young rune-mason in a fur-lined hooded coat and a stone-grey apron, carrying **a
  tall slab of rune-ice strapped to his back** (taller than his head, a single cyan rune glowing on it: glow point 1) and a
  two-handed **mason's maul** whose head carries three small runes (glow point 2). Distinct from Aldra (chisel staff), the Rime
  Seer (orb staff), the Shardcaster (crystal rod).
- Palette: Ice closed palette of `ice_model.gd` (pale stone `(0.70, 0.78, 0.88)`, fur base, glow `(0.75, 0.92, 1.00)`).
- Face: preset `bright`, **ears round**, **hair `crop`, white-blond** `(0.90, 0.92, 0.95)`, a light stubble moustache
  (`beard: &"moustache"`, pale), ice-blue eyes `(0.55, 0.78, 0.95)`, a small determined smile; wind-red cheeks.
- Motion: attack = a small ice chip flicked from the maul head; `play_cast(&"rime_bulwark")` 0.7 s = maul raised, **slammed into
  the ground** (the wall rises at the target, a frost crack runs from his feet toward it); `play_cast(&"scrying_rune")` 0.5 s =
  plucks a rune-pebble from the apron and throws it underarm. Idle while `stillness` is active: the back rune pulses slowly.
### 10.3 Bramblesage (Nature, 1.8 m with the crown, `art/units/nature/bramblesage/`)
- **Read at 40 m: an antlered old druid with moth wings.** Stooped, a long robe of layered leaves and moss, a **mantle of two
  large pale moth-wing shapes** over the shoulders (mottled cream / moss), a **crown of branching twigs like antlers hung with 3-4
  glowing pollen pods** (glow point 1, yellow-green `(0.85, 0.95, 0.45)`), and a **hooked briar crook** (the vine of Snagroot
  leaves from its hook). Distinct from the Bloomtender (bell-flower hat, small, pink) and the Vinelasher (whip).
- Palette: `nature_model.gd` closed palette; Verdant look.
- Face: preset `elder`, **ears pointed**, **hair `long` white with moss-green tips** + a long mossy beard (`beard: &"full"`,
  beard tip green), hazel-green eyes (`NatureFaces.EYE_HAZEL`), a kind closed smile.
- Motion: attack = a seed-spit from the crook; `play_cast(&"snagroot")` 0.6 s = crook thrust forward, then yanked back with both
  hands (the pull); `play_cast(&"pollen_haze")` 0.8 s = the wings spread wide and beat once, the pods flare; Seedcloak = the
  wings wrap around him for 0.4 s. Death: sinks into a mound of leaves, pods go dark.
### 10.4 Gloom Deacon (Shadow, 1.8 m, `art/units/shadow/gloom_deacon/`)
- **Read at 40 m: a tall veiled cleric with a floating reliquary.** Tall and thin, layered black-violet vestments with a **high
  stiff collar**, a **mitre-shaped hood** (the hollow church of Malrik's court, echoing the Hollow Oathsworn's mitre crest), a
  long **taper-staff** crowned with a violet flame (glow point 1; the Tithe tether starts there), and a **small coffin-shaped
  reliquary floating behind her shoulder** with a violet eye-window (glow point 2; bobs with a lag). Distinct from the Hexweaver
  (hunched witch, cage lantern) and the Mender champion (censer-kettle).
- Palette: `shadow_model.gd` closed palette (`shadow_cloth`, `shadow_cloth_dark`, `shadow_silver` trim, `shadow_bone` reliquary).
- Face: `ShadowFaces` skin (pale), preset `gentle`, **ears none (under the hood)**, **hair `braid`, black-violet**, a thin veil
  line across the brow, violet eyes `(0.75, 0.35, 1.00)` (iris glow low), dark-plum lips, a serene closed mouth.
- Motion: attack = a thin violet bolt from the taper; `play_cast(&"blood_tithe")` = a held pose (taper pointed at the ally, left
  hand on the heart) while channelling; `play_cast(&"umbral_passage")` 2.5 s = taper raised high, the reliquary opens, the robe
  hem lifts in an updraft. Death: collapses into her vestments, the reliquary falls and closes.

### 10.5 VFX (CU.V5 / V6; `UnitVfx.play(id, at, target)`, pooled, no particles beyond 45 m, 0 lights)
| id | Look |
|---|---|
| `slag_rain` | An orange glob arcs from the ingot (0.6 s, a smoke trail), a ground ring r 3 for both teams during the flight; impact = a splash of dark-orange molten droplets and a crusted disc that cools from orange to grey over 10 s |
| `slagged` (status) | Dark crust with orange cracks on the target's legs (model hook) or an orange modulate + 6 slow drips |
| `mana_scald` | A white-blue steam lash from the Kilnwarden's palm to the target, the target's mana bar flashes, a burst of steam at the target's head |
| `rime_bulwark` | Rise: ice shards burst up along a 4 m line in 0.3 s, frost mist at the base; stand: a translucent blue slab with inner runes; shatter: 20 ice chunks + a crack sound; melt (timeout): slumps and drips in 0.5 s |
| `scrying_rune` | A small grey stone with a cyan rune, a slowly rotating ring r 10 on the ground (own team only), a soft vertical light pillar 2 m (both teams see the stone only if in their vision) |
| `snagroot` | A thorned green vine shoots from the crook's hook (0.25 s) and wraps the target; during the drag, a furrow of torn earth; root = the Vinelasher's root look |
| `pollen_haze` | A drifting yellow-green cloud r 3.5 (billboard puffs, max 24), motes float, fades in the last 1 s; `hazed` = motes circling the head |
| `seedcloak` | A small puff r 2.5 + wing-flutter particles |
| `blood_tithe` | A violet-red tether (beam, 0.08 m) from the taper flame to the ally, pulsing toward the ally; a thinner dark-red thread from the drained enemy to the ally; a heal shimmer on the ally |
| `umbral_passage` | Two violet rifts (vertical oval portals 2.5 m) at the point and at the Deacon, swirling for 2.5 s, units fade out / in with a violet silhouette |
| `vigil` | A tiny violet wisp flies from the dying ally to the Deacon's reliquary |

---

## 11. Sound and voice (ui-coder; `sound-plan.md` style, `order_sfx_generator.gd`, SFX bus, throttled)
### 11.1 SFX cues
| Cue | Sound | When (hook) | Who |
|---|---|---|---|
| `caster_trained` | a short magical chime over the `unit_trained` cue | a caster leaves the keep | own |
| `slag_fling` / `slag_land` **3x** | whoosh with a sizzle / a heavy hissing splat | `CasterAbility.spell_cast(&"slag_rain")` / landing | 3D |
| `mana_scald` | a kettle-shriek steam burst | `spell_cast(&"mana_scald")` | 3D |
| `bulwark_rise` / `bulwark_shatter` / `bulwark_melt` | deep ice groan + crack / glassy smash / soft drip | wall created / shattered / timed out | 3D |
| `scry_rune` | a crystal ping with a long tail | rune placed | own |
| `snagroot` **3x** | whip crack + creaking vine drag | `spell_cast(&"snagroot")` | 3D |
| `pollen_haze` | soft whoosh + distant wind-chime shimmer | haze created | 3D |
| `blood_tithe_loop` | a low heartbeat hum, max 2 at once, fades when the tether ends | tether active | 3D |
| `umbral_passage` | a rising reversed whoosh with a hollow choir, then a thump on arrival | channel start / end | 3D |
| `alert_enemy_passage` | a warning horn variant | enemy Passage rift opens in the player's vision | own |
| `ui_autocast_on` / `_off` | two-note up / down click | autocast toggled | own |
| `ui_no_mana` | the wizard's "not enough mana" cue | refusal `"Not enough mana"` | own |
Casters' attack / hit / death use the existing caster family of `UNIT_SFX_FAMILY` (Pyre Adept / Hexweaver family).
### 11.2 Voices (Kokoro through the Voice Forge; `data/voice/cast.json` entries in the approved accent spirit: Fire American,
Ice / Nature / Shadow British; 4 lines each: select, move, cast, low mana. Lines are ours)
| Entry | Voice (Kokoro) | Speed | Notes | Lines |
|---|---|---|---|---|
| `unit_kilnwarden` | `{"am_fenrir": 0.6, "am_onyx": 0.4}` | 0.92 | Fire caster: gruff old smith-priest, American | "The kiln is hot." · "Mind the sparks." · "Soften them up!" · "Fire's low. Give me a moment." |
| `unit_rimecarver` | `{"bm_lewis": 0.6, "bm_fable": 0.4}` | 1.0 | Ice caster: earnest young mason, British | "Stone and frost, ready." · "Carrying the slab." · "Wall going up!" · "Runes are dim." |
| `unit_bramblesage` | `{"bm_lewis": 0.6, "am_santa": 0.4}` | 0.86 | Nature caster: creaky old druid, British | "The pods are ripe." · "Slowly, slowly." · "Come here, little one." · "Let the roots drink." |
| `unit_gloom_deacon` | `{"bf_isabella": 0.7, "bf_emma": 0.3}` | 0.9 | Shadow caster: serene chanting deaconess, British, low | "The tithe is owed." · "I walk in the hush." · "Bleed for the faithful." · "My candle gutters." |

---

## 12. Performance
- Casters are few (<= 10 % of soldier pop for bots); the autocast tick is the NewUnits12 0.5 s staggered tick over cached lists
  (< 0.03 ms / frame with 16 casters).
- Bulwark: a StaticBody3D + avoidance obstacle, **no navmesh rebake** (8 s life, max 4 per team). Units pressing it slide along
  (avoidance) and path around its 4 m ends.
- Haze: one Area3D-free check (distance per 0.25 s over enemies near the point); `range_cap` is a float compare in the attack
  code. Tethers: one beam mesh each, max 2 per target.
- Perf test addition: 8 casters per side, 4 Bulwarks, 2 Hazes, 4 tethers, 1 Passage every 45 s -> `PERF OK`, stuck = 0.

## 13. Open points (defaults taken; JS can change them after the playtest)
| # | Question | Default taken |
|---|---|---|
| Q1 | Keep slot B (shares the worker queue) or the Hall (9th slot, key `.` / AZERTY `:`)? | **Keep B** (3.3) |
| Q2 | Manual spells on soldiers (a new habit) or all autocast like the other units? | **Both**: autocast on by default except Bulwark and Passage (manual micro); bots use all |
| Q3 | Mana or cooldowns? | **Mana** (SC2 energy; the thing that makes a caster a caster) |
| Q4 | Tier 2 or tier 3? | **Tier 2** (Stronghold): casters shape mid-game fights, as in SC2 |
| Q5 | Cap per team? | None (cost, pop and the bots' 10 % rule limit them); knob `CasterKit.MAX_PER_TEAM := 0` (0 = none) |

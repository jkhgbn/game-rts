# Campaign mission e3m2: "Another Night" (Mother Hush's knives, Malrik on the ridge; Episode 3)

Written 2026-10-02 (`campaign-outline.md` 3.3 row 2). Episode 3 "The Gravedigger's Son", mission 2 of 4. The night after
"Take the Ford" (`mission-e3-01.md`): the ford fell at dusk, Ysolde held the tree until nightfall (`e4m1`), and both
armies sleep in their armour on the same valley. The player runs **Mother Hush's commando** through the Fire-Nature camp
behind Lark Hill to spoil four supply wagons before dawn, then holds the ridge at first light with Malrik, where his keep
stands as a **Citadel** for the first time and **Hush becomes the callable helper**. It is the mirror of Episode 1's
prologue `mission-00.md` "The Night of Knives": the same woman, the other side of the knife, and the same line ("There is
always another night"). Target **14-18 min** on normal. Uses the rules of `mission-00.md` (night, sight scale, story
units), `mission-e3-01.md` (the Evenmead map table, binding), `t3-helpers.md` 2-4 (Hush's kit and the helper call),
`tiers.md` 6, `caster-units.md` 5.4, `items.md`, and the format of `mission-01.md`. New scene
`missions/mission_e3_02.tscn` + `scripts/campaign/mission_e3_02.gd` (`MissionE302 extends MissionBase`, mission id `e3m2`,
campaign-outline D6). Metres, seconds, `m:ss` of `mission_time()` (cinematics excluded); positions `(x, z)`, `+z` = south
(the `forge_evenmead` frame). Status: **design only**; nothing here is built. Recommended option taken everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map | **`data/maps/evenmead.map` again** (the `mission-e3-01.md` Map table, unchanged), with a **night layer** the mission spawns: watch-fires, wagons, tents, posts, patrol paths. No new map file | The outline's "camp behind Lark Hill" is exactly e3m1's south bases (Heartwood `(-32, 48)`, Fire Keep `(20, 50)`); the player has fought over this ground once and now sees it at night |
| D2 | "Commando, no base" vs "Citadel + Hush callable" (both in the outline row) | **Two phases.** Phase 1 **"The Night"** (~10 min): no base, no economy, the player commands Hush and a 9-unit squad. Phase 2 **"First Light"** (~3 min): the ridge base at dawn, the Dusk Keep already a **Citadel** (finished overnight), the player calls Hush with the keep's **V** and trains the first Nightblood Reavers while Vessa's reprisal hits the ridge | Keeps the commando pure and still teaches the two unlocks in a short, safe coda. e2m1 taught the Citadel by building it; here the episode's pace (14-18 min) has no room for a 90 s upgrade, so the story finishes it |
| D3 | Who the player controls in the night | **Mother Hush as the hero**: story hero `hush_commando` (`HushCommando extends Wizard`, F / Q / E = her three abilities, no mana, level 5 fixed, instant loss on her death). Malrik stays on the ridge crest as an invulnerable voice | A commando needs a commandable hero with keys; the helper is autonomous by contract (`t3-helpers.md` 2), so the night uses a separate story type built on her ability code. Playing her first makes the later call mean something |
| D4 | Stealth | **The dark is ours now** (the M0 rule reversed): enemy sight x 0.6, squad units are `concealed` outside fire-light; enemies who see a squad unit raise an alarm after a 3 s fuse; 3 alarms wake Vessa. Watch-fires reveal and can be snuffed | M0 taught "light pushes back the dark" from the victim's side; the mirror teaches it from the knife's side. One readable rule set, no new fog code |
| D5 | Old Vey | **On the field, untouchable**: an invulnerable vigil under the golden tree (`vey_vigil`), guarding one wagon. Never fought tonight: avoided (veiled Hush) or lured away by an alarm elsewhere | He is the e3m4 hero-boss; here he is a presence. "He was awake that night too" (M0) is the link |
| D6 | The villagers of Evenmead | **4 villager tent clusters** inside the camp, non-combatant buildings (auto-aggro skips them). Secondary `sec_villagers`: never damage one | Malrik is a villain the player understands (`episode3-4-opening.md` 1): he orders "wagons, not tents". The spoiled grain sends the villagers south: Ep4's `e4m2` "The Green Road" |
| D7 | Nightblood Reaver (T3, `t3-helpers.md` 7) | **2 in the squad** ("the Bishop's blood-guard, lent for the night"), then **trainable at the Citadel** (keep **C**) in phase 2 | Meet the unit in hand first, then buy it |
| D8 | Hush's call price | **0 crystals, 0 essence, 10 s** in this mission only (she is already home). Revive at the skirmish price. Skirmish price everywhere else in Ep3 | The call is a lesson here, not a choice |
| D9 | Torvald | **Voice in the night; ally bot at dawn** (`ai-2v2.md` ally layer, profile `mission_e3_02_ally`, 10 pop) | The 2v2 frame of e3m1 stays; his doubt grows (Ep3 between-scene, e3m4) |
| D10 | The Keystone Shard | **Passive only** (Heartbeat, as e3m1). Its active and Hollow cost arrive in `e3m3`; one whisper line at dawn seeds it | `items.md` C7 / e3m1 D6: "Its active and Hollow cost wait for e3m3" |

## Story setup (briefing text, 3 short paragraphs; shown after `c_e3_knife`, the between-scene that follows e3m1)
1. The ford fell at dusk. Ysolde held her hill until the light was gone, and now both armies sleep in their armour,
   a river apart, while the villagers of Evenmead huddle in tents behind Lark Hill.
2. Hungry armies march slowly. Four supply wagons came up the south road today: the villagers' winter grain, the Fire
   army's arrows, its lamp oil, its riders' fodder. Malrik wants all four spoiled before the sun is up.
3. He is sending the knife that never misses. She missed once, at Emberfall. Tonight is another night.
Briefing objectives: `obj_wagons`, `obj_hush`, and the line `Enemies see poorly in the dark, and clearly near a fire. Stay
out of the light.`

## Map: "Evenmead by night" (`data/maps/evenmead.map`, 150 x 120, the e3m1 table unchanged + the night layer below)
Everything in the `mission-e3-01.md` Map table stands where it stood (keeps, halls, nodes, fords, standards, crest
spires, the golden tree). Changes the mission makes at load: the **three standards** at the foot are owned by side 0 (the
e3m1 result; decals only, no capture this mission); the **Horn Spires are gone** (burnt in the evening); the bot bases
run **no economy** in phase 1 (workers asleep in the halls, removed from the map). Light: moonlight preset (19.V24 night
kit, cold moon from the north-east), the river a dark mirror, every watch-fire an emission ring on the grass (0 lights).
Phase-1 play area = the whole map (camera free); the player's ridge base is visible but locked (no training, economy
hidden) until phase 2.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| Squad start (Hush) | `(2, 19)` | - (in the Standard's ring) | Beside Ysolde's fallen Standard; the squad in a ring r 3 around her, facing south |
| **Safe line** | Every point with `z <= 22` | - | The Shadow pickets at the foot. Enemy hunters never follow a squad unit north of it (leash back after 10 s) |
| Malrik (story, phase 1) | `(0, -36)` (`crest_n`) | - | Invulnerable, not selectable; a candle in his hand |
| **Wagon WG1 "Grain"** (Nature, the villagers' winter grain) | `(-52, 46)` | 5 | 20 m west of the Heartwood; 10 m from the Grove Hall |
| **Wagon WG2 "Arrows"** (Fire) | `(-12, 56)` | 5 | Under the golden tree `(-16, 48.5)`, 8.5 m from its trunk: **Old Vey's vigil** |
| **Wagon WG3 "Lamp oil"** (Fire) | `(36, 56)` | 5 | 17 m east of the Fire Keep; 14.6 m from the Ember Hall |
| **Wagon WG4 "Fodder"** (Fire, the Blaze Riders') | `(46, 24)` | 5 | The east road's forward depot, 8.5 m from the untouched east expansion node `(52, 30)` |
| Watch-fires F1 / F2 / F3 (crest) | `(-18, 30)` / `(0, 30)` / `(14, 33)` | - | Along the crest, between the crest spires |
| Watch-fires F4 / F5 (Nature) | `(-40, 34)` / `(-48, 50)` | - | F5 lights WG1 (4.5 m) |
| Watch-fire F6 (the tree) | `(-10, 52)` | - | Lights WG2 (4.5 m) |
| Watch-fires F7 / F8 / F9 (Fire) | `(34, 52)` / `(44, 28)` / `(8, 44)` | - | F7 lights WG3, F8 lights WG4, F9 the Fire camp centre |
| Watch-fire F10 (Heartwood south) | `(-24, 54)` | - | |
| Villager tents VT1 / VT2 / VT3 / VT4 | `(-22, 42)` / `(-40, 54)` / `(2, 52)` / `(24, 38)` | 4 each | Non-combatant buildings (below) |
| Army tents ST1 (Nature) / ST2 (Fire) / ST3 (Fire) | `(-34, 30)` / `(12, 46)` / `(40, 48)` | 4 each | Sleeping soldiers (below) |
| **Vessa's tent** | `(16, 54)` | 3 | Vessa asleep inside (5.6 m from the Fire Keep) |
| **Vey's vigil path** | `(-17, 47)` <-> `(-11, 51)` | - | 15 s pause at each end; 10.3 m and 5.1 m from WG2 |
| Ridge base (phase 2) | Dusk Keep `(-12, -48)`, Gloom Hall `(1, -48)`, Hovel `(-14, -38)`, 2nd Hovel `(-24, -52)` | as e3m1 | The 2nd Hovel is new (7.6 m from node `e3_dusk_a`) |
| Reprisal path (phase 2) | Ember Hall `(32, 42)` -> Stone Ford `(4, 0)` -> Dusk Keep | - | 105 m on the navmesh |
Distances (path): squad start -> WG4 47 m, -> WG3 41 m, -> WG2 40 m, -> WG1 62 m (by the west slope). A full loop of
the four is ~190 m: ~1:00 of walking for the squad, the rest is waiting, snuffing and fighting.

**Watch-fire** (`MissionBrazier` reversed, systems): a stone ring with a log fire, lit at start. While lit it is a
`SightMarker` for team ENEMY of radius **15** (x 0.6 at night = **9 m**), and every squad unit inside that 9 m is
**lit** (never concealed, see "Stealth"). **Snuff**: any squad unit except Grave Hounds within **2 m for 2 s** (progress
ring; leaving or taking damage resets) puts it out, silently. **Relight**: an enemy patrol that passes within 4 m of a
snuffed fire stops 3 s and relights it (no alarm). During a camp alert (below) every fire within 30 m of the alarm relights
at once. Look: 19.V24 watch-fire with the warmth ring; snuffed = a thin smoke thread, embers dark.

**Supply wagon** (new prop, systems; `art/campaign/e3m2/wagon_*`): a 4 m covered wagon, team ENEMY, **500 HP**, armor 5,
`counts_for_defeat` false, group `"scripted"` + `"wagons"`. **Sabotage**: a squad unit except Grave Hounds within **2 m**
for **4 s** (Hush **2 s**): axle pins pulled, sacks slit, oil and arrows spilled in the grass; progress ring; resets if the
unit leaves 2 m or takes damage. **Destroying** it (HP 0) also counts, but is loud: an instant alarm at the wagon.
Sabotaged look: tilted on a broken wheel, cargo spilled, a sabotaged decal; no fire (the camp must not see a glow).

**Villager tents** (`villager_tents`, BuildingType copy of a Hovel look, systems): team ENEMY, 300 HP, armor 0,
`counts_for_defeat` false, group `"noncombatant"`: **no unit and no ability auto-targets them** (auto-aggro, Night of
Knives, Blink autotarget, splash all skip); only an explicit attack order hits them. Each holds 10 villagers (no units: a
counter for the flags). Damaging one fails `sec_villagers` and raises an instant alarm.

**Army tents** (`army_tents`): 2 tent props + their sleepers (scripted units, `_set_dormant`: no aggro, not targetable,
lying down). Sleepers wake (stand, 1.5 s) when their tent cluster is attacked, when a camp alert starts within 30 m, or at
Alarm 3. Woken sleepers join the alert, then walk back and sleep again when it ends.

## Stealth (phase 1 only; the mission drives it, no fog change)
| Rule | Value |
|---|---|
| Enemy sight | `FogOfWar.sight_scale[ENEMY] = 0.6` (the per-team array of M0 / M9.S2). Player sight is **not** scaled: the dark belongs to Shadow tonight |
| Concealed | A squad unit outside every lit fire's 9 m is `concealed` for team ENEMY: enemy units and towers **cannot auto-target or spot it beyond 6 m** (Hush veiled: **3 m**). Inside fire-light it is **lit**: seen at the viewer's full night sight. Attacking makes a unit **exposed** for 3 s (seen at full night sight wherever it is) |
| Spotting | An awake enemy unit (posts, patrols, guards, woken sleepers; not buildings, not Vessa asleep) that sees a non-concealed squad unit gets a **"!"** over its head and a **3 s fuse** (a ring that fills). Fuse full -> **Alarm** at that point. The fuse cancels if the spotter dies or no squad unit is visible to it for 1 s. A spotter killed within 0.3 s of the first hit raises nothing (a **silent kill**) |
| Instant alarms | A wagon destroyed (not sabotaged), a villager tent damaged, any building attacked (keeps, halls, crest spires, tents), Old Vey's detection |
| Camp alert (each alarm) | A horn (`ashby` or `messenger` line), 45 s: every awake enemy within **30 m** of the alarm attack-moves to it; the nearest army tent cluster within 30 m wakes; fires within 30 m relight. At the end, survivors walk back to their posts / loops |
| Alarm 2 | Also: each wagon not yet spoiled gets **+2 guards** from the nearest keep (Fire: 1 Flame Guard + 1 Ember Archer; Nature: 1 Thornling + 1 Burr Slinger) |
| Alarm 3 "The camp is up" | **Vessa wakes** (L6, bot wizard, `AIStoryCaster`) with **4 Blaze Riders** from the Fire Keep and hunts Hush for **90 s** (attack-move to her position, refreshed every 3 s), then walks back. Every fire relights; from now on enemy sight is **x 0.8** and concealment works only beyond **8 m**. Not a defeat: the wagons can still be done, much harder |
| Safe line | A squad unit with `z <= 22` cannot be chased: hunters stop 10 s later and leash back. Hush can always fall back to the foot to break a hunt |
| Hounds | Grave Hounds cannot snuff or sabotage (dogs). They are fast lures: a Hound seen deliberately is the cheapest alarm, used to pull an alert (and Vey) away |
| Counter | `Alarm 0 / 3` in the objectives panel; an eye icon over every spotter whose fuse runs (19.U-style ring, red) |

### Old Vey's vigil (`vey_vigil`, story unit, team ENEMY, invulnerable)
Model: `art/units/helpers/helper_vey/` with `set_look(&"m4")` (white-gold runes, but only a faint crackle: he is resting).
Walks the vigil path above at 2.0 m/s with 15 s pauses. **Detection**: any non-concealed squad unit within **9 m**, any
concealed one within **5 m**, a veiled Hush within **3 m** -> instant alarm + **Lightning Lunge** on that unit (**80**,
dazed 0.5 s) + a chase of up to 15 m from his path, then back. He cannot be damaged or slowed (story shield, a faint
white-gold shimmer when hit). **Lure**: when an alarm rings **25 m or more** from the golden tree, he walks to it for 45 s
(the alert time), then back. Intended answers for WG2: a **veiled Hush** times his walk (the wagon is 10.3 m from his
tree end and 5.1 m from his far end: both outside her 3 m), or the squad raises a cheap alarm on the other side of the
hill (a Hound at WG3) and spoils WG2 while he is away.

## Start state
| Item | Value |
|---|---|
| Hush (`hush_commando`, phase 1 hero) | **Level 5 fixed** (no XP), **900 HP**, armor 10, damage 34, range 1.6, cooldown 1.0, speed 5.4, sight 13; abilities on **F / Q / E** (below); regenerates **2 % / s** after 8 s out of combat |
| Squad (team PLAYER, commandable, veterancy 2) | **4 Shades, 2 Grave Hounds, 2 Nightblood Reavers** in a ring r 3 around Hush; value 320 + 140 + 520 = **980** |
| Malrik | Story unit at `(0, -36)` in phase 1 (invulnerable, not selectable); **Level 5** (Lance r2, Siphon r2, Shroud r1), **cap 6** from phase 2; artifact slot 1 = Keystone Shard (passive) |
| Inventory / economy (phase 1) | `items_locked = true` for the phase (Hush has no inventory: helper rule); crystals and essence hidden, essence trickle off; the ridge base locked (no training, no building) |
| Ridge base (phase 2, unlocked by `e3m2_embers`) | Dusk Keep **tier 3 Citadel** (`Keep.set_start_tier(3)`: 3 500 HP, attack 20, no announcement), Gloom Hall, 2 Hovels; 6 Gloom Thralls gathering (3 / 3 on `e3_dusk_a` / `e3_dusk_b`) |
| Crystals / essence (phase 2) | **600** / 150 + carried (the e3m1 50 % rule, cap 1 500); +1 / s |
| Population (phase 2) | Squad survivors + 6 Thralls (+4 when Hush is called) of **60** (keep 20 + 2 Hovels) |
| Torvald | Phase 1: voice only (his camp at the ridge, idle). Phase 2: ally bot, L5, Rime Keep at Stronghold, Rime Hall, 4 Rime Haulers, **4 Rimeshields + 2 Shardcasters + 1 Frost Mortar** at `(35, -28)` |
| Fire-Nature camp (phase 1) | As "Guards" below; **Vessa** asleep in her tent (L6); **Ysolde** inside the Heartwood (never on the field tonight) |
| Fog | On; the river, the 3 fords, the 3 standards, both crests, the 4 wagons (their markers) explored for the player from 0:00 |
| Off | Tavern, trade, camps, beasts, capture points (besides the e3m1 standards as decals), research, STR / INT, titans |
| No save / e3m1 not won (menu debug, tests) | Keystone Shard equipped, 6 empty slots, essence 150 + **500** |

### Hush in the night (`hush_commando`; `t3-helpers.md` 4.3 kit at level 5, story numbers)
| Key | Ability | Cooldown | Effect |
|---|---|---|---|
| Passive | **Mouthless Veil** | - | After 4 s without attacking or being hit she is **veiled**: unseen beyond 3 m (stealth), not auto-targeted beyond 5 m; her first strike out of the veil **+60 %**. Snuffing and sabotage do not break the veil |
| **F** | **Blink Strike** | 10 | Target an enemy unit within 14 m: 0.5 s violet ring, then she appears behind it and strikes for **65** (out of the veil: **104**, a one-strike kill on a Thornling, an archer or a Burr Slinger: a silent kill) |
| **Q** | **Smoke Cloak** | 22 | Smoke r 4 for 5 s at her spot: every squad unit inside is concealed even in fire-light, spotters looking into it lose sight (fuses cancel), she gets `shroud` 3 s and enemies targeting her drop her |
| **E** | **Night of Knives** | 75 | Vanishes 1.5 s (untargetable), then 6 strikes 0.25 s apart on up to 6 enemies within 10 m, **46** each (heroes x 1.5 + `marked` 4 s); reappears at the last. Exposes her (3 s) |
The command card shows the three abilities on F / Q / E (Hero WASD walks her). F1 selects her, Space centres on her.
Death = defeat (L29). The squad is ordinary units (Reavers drink 35 %, halved for 4 s by any fire hit: the Ember
Archers' burning arrows teach **Sunburn**, `t3-helpers.md` 7.2).

## Unlocks (what exists in this mission)
| Kind | Available | Locked (comes later) |
|---|---|---|
| Phase 1 | Hush's kit, the squad, snuff, sabotage | Everything else (no base, no economy) |
| Buildings (phase 2) | Hovel, Gloom Hall, Night Spire (no time to need them) | Dread Paddock (e3m4), Bazaar |
| Units (phase 2) | Gloom Thrall (keep Z), **Nightblood Reaver (keep C, Citadel)**, Gloom Deacon (keep B); Gloom Hall Z X C V N, M `,` as e3m1 | Nightmare Knight (e3m4) |
| Keep | Already a **Citadel**; **V Call Mother Hush** (D8 price), then Revive | - |
| Helper | **Mother Hush becomes the callable helper** (flag `helper_hush_unlocked`): stance Escort / Vanguard / Hold home, F4 centres on her | - |
| Spells | Malrik: Shadow Lance, Soul Siphon, Umbral Shroud; cap L6 | - |
| Items | Phase 2: the base shop at the Dusk Keep and Gloom Hall | The Shard's active (e3m3) |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_wagons` | Primary (phase 1) | `Spoil the supply wagons before dawn (0 / 4)` with `Dawn in 8:12` | 4 wagons sabotaged or destroyed; **failed** if dawn comes first (defeat) |
| `obj_hush` | Primary (phase 1, always shown) | `Mother Hush must survive` | Fails = defeat |
| `obj_light` | Primary (phase 2) | `Hold the ridge until the sun is up (2:30)` | The countdown ends with the Dusk Keep standing |
| `obj_malrik` | Primary (phase 2, always shown) | `Malrik must survive` | Fails = defeat |
| `sec_unseen` | Secondary (phase 1) | `Never wake the camp` with `Alarm 0 / 3` | Phase 1 ends with 0 alarms; **failed** at the first alarm |
| `sec_villagers` | Secondary (phase 1) | `Spare the villagers' tents` | Phase 1 ends with no villager tent damaged; **failed** at the first damage |
| `sec_call` | Secondary (phase 2) | `Call Mother Hush from the Citadel (V)` | Hush arrives (E15) |
States through `Events.objective_changed(id, state)`. Phase-1 objectives disappear from the panel at `e3m2_embers`
(their results kept); the phase-2 ones appear after it.

## Guards, patrols and waves (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
All team ENEMY, group `"scripted"`, never controlled by a Commander in phase 1 (the bots' Commanders are paused until
phase 2). Posts stand still facing north (aggro at night sight, leash 2x); patrols walk their loops at **2.5 m/s**.
| Group | Where | Units | Value |
|---|---|---|---|
| P1 / P2 crest west | `(-24, 28)` / `(-6, 27)` | 2 Thornlings / 1 Thornling + 1 Wildwood Archer | 120 / 145 |
| P3 / P4 crest east | `(10, 28)` / `(22, 30)` | 1 Flame Guard + 1 Ember Archer / 2 Flame Guards | 190 / 180 |
| P5 west flank | `(-46, 30)` | 1 Thornling + 1 Burr Slinger | 130 |
| P6 east road | `(40, 20)` | 1 Flame Guard + 1 Ember Archer | 190 |
| PT1 Nature patrol | Loop `(-44, 30) -> (-42, 44) -> (-30, 54) -> (-20, 40) -> back` (~75 m, ~30 s) | 2 Thornlings + 1 Wildwood Archer + 1 Burr Slinger | 275 |
| PT2 Fire patrol | Loop `(8, 32) -> (18, 44) -> (36, 48) -> (42, 30) -> back` (~80 m) | 3 Flame Guards + 1 Ember Archer + 1 Blaze Rider | 550 |
| PT3 crest patrol | `(-26, 31) <-> (22, 33)` | 2 Flame Guards + 1 Thornling | 240 |
| WG1 guard | Ring r 3 around the wagon | 2 Thornlings + 1 Wildwood Archer + 1 Bloomtender | 295 |
| WG2 guard | - | Old Vey's vigil only | - |
| WG3 guard | Ring r 3 | 2 Flame Guards + 1 Ember Archer | 280 |
| WG4 guard | Ring r 3 | 2 Flame Guards + 1 Ember Archer + 1 Blaze Rider | 460 |
| ST1 sleepers (Nature) | `(-34, 30)` | 5 Thornlings + 2 Wildwood Archers | 470 |
| ST2 sleepers (Fire) | `(12, 46)` | 4 Flame Guards + 2 Ember Archers | 560 |
| ST3 sleepers (Fire) | `(40, 48)` | 3 Flame Guards + 2 Ember Archers + 1 Pyre Adept | 600 |
| Crest spires | Bramble `(-24, 32)`, `(-10, 30)`; Ember `(6, 31)`, `(20, 34)` | Buildings (e3m1); night sight x 0.6; shoot only lit / exposed squad units in range; attacking one = instant alarm | - |
| Keeps | Heartwood, Fire Keep | Shoot lit / exposed squad units in range; attacking = instant alarm | - |

| Wave (phase 2) | Trigger | Units (spawn) | Order |
|---|---|---|---|
| R1 "Vessa's reprisal" | Phase 2 + 0:40 | **Vessa L6** + 3 Blaze Riders + 6 Flame Guards + 3 Ember Archers (Ember Hall), **+1 Flame Guard per alarm** raised in phase 1 | Cross Stone Ford, attack-move to the Dusk Keep, then Malrik; refreshed every 4 s |
| R2 | Phase 2 + 1:40 | 4 Flame Guards + 2 Pyre Adepts + 2 Blaze Riders (Ember Hall) | Same order |
| Withdraw | `obj_light` done | Every living Fire unit and Vessa | Walk back across the ford to the Fire Keep (no fighting unless attacked) |
In phase 2 the Fire bot (`mission_e3_02_enemy`: defend only, `min_attack_pop` 99) and the Nature bot (paused: Ysolde's
people are packing) launch nothing of their own. **Torvald** (`mission_e3_02_ally`, Supportive): 10 army pop, holds his
base, answers pings; scripted: at R1 his army attack-moves to the Stone Ford's north bank `(4, -6)` (a flank on the
reprisal) and stays there until the withdraw.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (`c_e3_knife` and the briefing played before the scene.) Cutscene `e3m2_slip` (HOLD 0:15); camera on Hush; L1-L4; hint (10 s) `Stay out of fire-light. A snuffed fire hides you: stand by it 2 s. Enemies who see you raise an alarm after 3 s; kill them first.`; `obj_wagons`, `obj_hush`, `sec_unseen`, `sec_villagers` active; dawn countdown starts (11:00) |
| E2 | First fire snuffed | L5; hint (6 s) `Hush is veiled after 4 s without fighting: only enemies within 3 m see her.` |
| E3 | First wagon spoiled | L6; `obj_wagons` 1 / 4 |
| E4 | Hush within 14 m of Old Vey (first time) | L7-L8; hint (8 s) `Old Vey cannot be hurt tonight. Slip past him veiled, or raise an alarm far away to draw him off.` |
| E5 | Hush within 12 m of Vessa's tent (first time) | L9-L10 |
| E6 | Alarm 1 / Alarm 2 | Horn; camp alert; L11 (1st) / L12 (2nd); `sec_unseen` failed at the 1st |
| E7 | Alarm 3 | L13-L14; Vessa wakes and hunts (90 s) |
| E8 | Old Vey detects a squad unit (first time) | L15 (then the instant alarm of E6) |
| E9 | Second wagon spoiled | L16 |
| E10 | Third wagon spoiled | L17 |
| E11 | Fourth wagon spoiled | L18-L19; `obj_wagons` done; phase 1 ends: world held; cutscene `e3m2_embers` (PAUSE 0:25); phase 2 set-up (its end state) |
| E12 | After `e3m2_embers` | **Phase 2**: hero = Malrik (`MissionBase.set_player_hero`); economy shown; L20; `obj_light` (2:30), `obj_malrik`, `sec_call` active; hint (10 s) `Your keep is a Citadel now. Select it: V calls Mother Hush, C trains the Nightblood Reaver.`; Torvald's Commander resumes |
| E13 | R1 launches (+0:40) | L21-L22 |
| E14 | First Keystone Shard Heartbeat in phase 2 | L24-L25 (once) |
| E15 | Hush arrives (helper arrival set-piece at the keep door, no camera move) | Her arrival bark (`t3-helpers.md` 10.4) then L23; `sec_call` done |
| E16 | `obj_light` done | Withdraw; cutscene `e3m2_dawn` (PAUSE 0:30) with L26-L28; `Events.mission_ended(true)` 2 s after it; StoryFlow then plays `c_e3_price` |
| E17 | Hush dies (phase 1) | L29; `obj_hush` failed; defeat after 3 s |
| E18 | Dawn countdown ends with fewer than 4 wagons spoiled | L30; `obj_wagons` failed; defeat after 3 s |
| E19 | Malrik dies (phase 2) | L31; `obj_malrik` failed; defeat after 3 s |
| E20 | Dusk Keep destroyed (phase 2) | Defeat after 3 s (no line) |
The wagons can be spoiled in any order; E9 / E10 follow the count. A veiled Hush can do WG2 alone; the intended rhythm on
normal: WG4 (the guard fight, silent kills on the archer first) -> WG3 -> WG2 (veiled) -> WG1 (the long west walk),
~8:30-10:00 of night.

## Dialogue (31 lines; speaker colours: Hush `(0.60, 0.50, 0.75)`, Malrik `(0.7, 0.3, 1.0)`, Torvald `(0.55, 0.80, 1.00)`, Vessa `(1.0, 0.45, 0.1)`, Old Vey `(0.95, 0.95, 0.55)`, Captain Ashby `(0.95, 0.60, 0.35)`, Wren `(0.80, 0.92, 0.60)`, Ysolde `(0.55, 0.90, 0.35)`, Obren `(1.0, 0.80, 0.25)`, Narrator `(0.9, 0.85, 0.7)`; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist): `narrator`, `hush`, `malrik`, `torvald`, `vessa`, `vey`, `ashby`,
`messenger` (Wren: her stumbles are written into the spoken text, the subtitle column is the clean reading, the e2m1
rule), `ysolde`, `obren` (alias of `whisper`). In phase 1 Malrik's lines come "through the dark" (the dialogue box shows
his portrait with a violet vignette; no unit speaks them). Every line <= 2 lines of the box (<= 96 characters).
| Line | Event | Speaker | Text (spoken) | Subtitle if different |
|---|---|---|---|---|
| L1 | E1 | narrator | Night on Lark Hill. Two armies asleep in their armour, and one woman who never sleeps. | - |
| L2 | E1 | malrik | Four wagons, Hush. Grain, arrows, oil, fodder. Hungry armies march slowly. | - |
| L3 | E1 | hush | And the people in the tents, Bishop? | - |
| L4 | E1 | malrik | Wagons. Not tents. I grew up burying people who starved in tents. | - |
| L5 | E2 | hush | Hush now. The dark only wants to be listened to. | - |
| L6 | E3 | hush | One wagon. Its wheels will not turn again. | - |
| L7 | E4 | hush | The old man. Awake, of course. He was awake that night too. | - |
| L8 | E4 | malrik | Then do not wake him further. Be the quiet thing in the dark. | - |
| L9 | E5 | hush | There she sleeps. The little queen. One step, Bishop. Just one. | - |
| L10 | E5 | malrik | Not tonight. Tonight we starve them. Knives are for another night. | - |
| L11 | E6 (1st) | ashby | Up! Up! Shadow in the camp! Torches, all of you! | - |
| L12 | E6 (2nd) | messenger | They're... they're in the... the Shadow's in the camp! Wake up! Wake... | The Shadow's in the camp! Wake up! |
| L13 | E7 | vessa | Hush! I know that smoke. Come out and finish what you started! | - |
| L14 | E7 | hush | Another night, little queen. There is always another night. | - |
| L15 | E8 | vey | I know those knives. Not in my girl's camp. Not twice. | - |
| L16 | E9 | malrik | Two. Ysolde will count her sacks at dawn and come up short. | - |
| L17 | E10 | torvald | Your shadows are thorough, Malrik. I am not certain that is a compliment. | - |
| L18 | E11 | hush | Four. The camp will wake hungry, Bishop. | - |
| L19 | E11 | malrik | Good. Come home. Bring the night with you. | - |
| L20 | E12 | narrator | First light. On Lark Hill, Vessa found her wagons. She did not wait. | - |
| L21 | E13 | vessa | MALRIK! You sent the knife-woman into my camp AGAIN? | - |
| L22 | E13 | malrik | I sent her to the wagons. You should be flattered she skipped your tent. | - |
| L23 | E15 | malrik | Stand with me, Hush. In daylight, for once. | - |
| L24 | E14 | obren | Let me do more than beat, Bishop. Let me help. | - |
| L25 | E14 | malrik | Not today. Today I have a knife. | - |
| L26 | E16 (`e3m2_dawn`) | ysolde | Then the people go south today. All of them. The road is safer than this hill. (6 s) | - |
| L27 | E16 (`e3m2_dawn`) | hush | There is always another night, Bishop. | - |
| L28 | E16 (`e3m2_dawn`) | malrik | And every one of them is mine. | - |
| L29 | E17 | hush | The knife bends... Not tonight. Not... | - |
| L30 | E18 | narrator | Dawn came up over Lark Hill, and the wagons rolled on. | - |
| L31 | E19 | malrik | Struck down at sunrise. How very Vessa. | - |
Hush's helper barks in phase 2 (arrival, Blink, low HP, fall, revive) are the `helper_hush_<event>` voice hooks of
`t3-helpers.md` 10.4 in the same `hush` voice; L23 is the only mission line around them. Echoes: L14 is M0 L8 word for
word (the mirror); L5 is Hush's audition line; L7 and L15 are the two sides of the M0 night; L10 keeps Malrik
understandable (`episode3-4-opening.md` 1); L24-L25 seed `e3m3` "The Stone's Price"; L26 hands the hill to `e4m2`
"The Green Road" (the villagers walk south because the grain is gone).

## Cinematic hooks (ENGINE, on the live mission scene, CinematicPlayer 19.C1; skippable; units frozen while they play)
| Id | When | Mode / length | Shots (camera, what we see) | Lines | End state (a skip leaves exactly this) |
|---|---|---|---|---|---|
| `c_e3_knife` "The Bishop's Knife" | Before the briefing (StoryFlow, after e3m1) | Stage film ~1:10 (`campaign-outline.md` 3.3 "Hush and Malrik after Evenmead") | Beats for its writer (E3M2.D1): dusk on the ridge after the ford; Malrik cleans the ford mud off his boots; Hush is already behind him; he does not turn ("You missed her, at Emberfall." / "Once."); he lays four wooden tokens on a map of the south camp; Torvald watches from his pavilion; Hush takes the tokens and is gone | - | StoryFlow continues to the briefing |
| `e3m2_slip` | E1 | HOLD 0:15 | 1) WIDE from the north-east bank (fov 46), moonlight on the river, the fallen green standard at the squad's feet; 2) MS Hush, her white mask catching the moon, 3/4-left (east of the north-south axis, the Ep3 rule); 3) long lens south up Lark Hill: ten watch-fires on the crest and behind it, the golden tree a dark shape | L1 over shot 1 | Squad at its start marks; camera on Hush; dawn countdown running from 11:00 |
| `e3m2_embers` | E11 | PAUSE 0:25 | 1) MS the last wagon tilting on its broken wheel, grain pouring into the grass; 2) WIDE from the crest: four dark wagons among the fires, nobody awake (or, after alarms, torches running); 3) Hush on the crest against the camp's light, dissolving into smoke; 4) the ridge at first grey light: masons lower the last stone onto the Dusk Keep's new Citadel spire, Malrik below with his candle; Hush steps out of his shadow, puts a cut axle pin in his hand, and fades back into the keep's shadow | - | Phase 2 set-up: every squad survivor at the Shadow rally `(-4, -28)` at full HP; `hush_commando` removed (no death event); the Dusk Keep a completed Citadel; dawn light preset fully on; economy shown; Malrik the hero at `(-6, -40)`; every phase-1 enemy unit removed except Vessa (back in the Fire Keep, awake); fires out |
| Hush's call | E15 | In-game set-piece (`t3-helpers.md` 10.2: the keep's shadow stretches, smoke, the mask surfaces first) | - | Arrival bark | - |
| `e3m2_dawn` | E16 | PAUSE 0:30 | 1) WIDE crane from Lark Hill's crest at sunrise: the spoiled wagons, villagers packing carts; 2) MS two-shot Ysolde and Vessa (west of the axis is Ep4's rule; here a frontal two-shot from the crest's north face) (L26); 3) long lens north across the valley to the ridge: Malrik and Hush side by side on the crest, the Citadel spire behind them (L27-L28); 4) CU Malrik's hand: the stone beats once, brighter; FADE_BLACK | L26-L28 | Victory 2 s later |
| `c_e3_price` "The Stone's First Price" | After victory (StoryFlow) | Stage film ~1:10 | Beats for its writer (E3M2.D1): that night, Malrik alone in his pavilion; the stone pulses without being asked; a rider in Shadow colours: "Duskbarrow, Bishop. The barrow candles have gone out. The dead are walking." Malrik: "Whose dead?" "Yours." He looks at the stone; the stone is very quiet. Hush: "Shall I come?" "Always." Torvald, at his door: "Go. I will keep your ridge cold." | - | StoryFlow continues to e3m3's briefing |
Camera axis: the Ep3 rule (cameras east of the north-south Malrik - Ysolde line) except `e3m2_dawn` shot 2. Fallbacks until
the cine tool and sets exist: `e3m2_slip` = camera on Hush + L1; `e3m2_embers` = a 1 s fade to black, its end state, a
message `First light. The Citadel stands.` (4 s); `e3m2_dawn` = L26-L28 as dialogue, then victory.

## Tiers and the helper (`tiers.md` 6, `t3-helpers.md` 3)
| Item | Value |
|---|---|
| Code | `MissionE302._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = true`, `helpers_enabled = true` (flags of `mission-e2-01.md`); `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`; the Dusk Keep set to tier 3 at the phase-2 switch (`Keep.set_start_tier(3)`, no announcement, no timer) |
| Dusk Keep card (phase 2) | Z Gloom Thrall · X empty (Citadel reached) · **C Nightblood Reaver** · **V Call Mother Hush** (D8: 0 / 0, 10 s), then `Revive Mother Hush` (skirmish price: 120 + 20 x level essence, 25 + 5 x level s) · B Gloom Deacon · Set Rally r3c1 |
| Gloom Hall card | As e3m1 (Z X C V N, M `,`), "+" page open |
| Hush (phase 2) | `helper_hush` kit at Malrik's level (L5 x1.16, Night of Knives on), stance Escort, F4 centres on her; death = fallen, never a defeat |
| Bots | Torvald at the Stronghold (never upgrades); the Fire Keep and Heartwood at the Stronghold (e3m1), never upgrade; R1 / R2 are spawned, not trained |

## Economy
| Item | Value |
|---|---|
| Phase 1 | None (hidden, no trickle; kills give nothing) |
| Phase 2 start | 600 crystals, essence 150 + carried, 6 Thralls already gathering |
| Phase 2 spend (expected) | Hush's call (free), **2 Nightblood Reavers** (520) or 1 Reaver + a Gloom Deacon; essence for one mid-item at the keep |
| Why so small | The coda is 3 minutes: the money buys the lesson (Reaver + call), not an economy |

## Win / lose
| Event | Result |
|---|---|
| `obj_light` done | **Victory** (after `e3m2_dawn`) |
| Hush dies in phase 1 | **Defeat** (she is the night's hero) |
| Dawn before 4 wagons | **Defeat** |
| Malrik dies in phase 2 | **Defeat** (`instant_loss_on_wizard_death = true`, re-pointed by `set_player_hero`) |
| Dusk Keep destroyed (phase 2) | **Defeat** |
| Alarm 3 | Nothing by itself (Vessa hunts) |
| All squad units dead, Hush alive | Nothing; she can finish alone (veiled, slowly) |
| Hush falls in phase 2 (helper) | Nothing; revive at the keep |
| Vessa killed in phase 2 | Not a win: `Vessa falls back to Lark Hill` (4 s); she respawns at the Fire Keep after 60 s and does not rejoin R1 |

## Reward carried to e3m3 (Malrik's track, campaign-outline D8)
- Keystone Shard stays owned and equipped. The 6 item slots at victory; essence 50 %, cap 1 500; **+200 first if
  `sec_unseen`**, **+150 first if `sec_villagers`**.
- `CampaignState.MISSION_REWARDS[&"e3m2"] = {"flags": {"e3m2_unseen": "sec_unseen", "e3m2_villagers_spared":
  "sec_villagers", "e3m2_hush_called": "sec_call"}, "bonus_essence": {"sec_unseen": 200, "sec_villagers": 150},
  "set_flags": {"helper_hush_unlocked": true, "e3m2_grain_spoiled": true}, "next": &"e3m3"}`; plus the mission-computed
  flag `e3m2_alarms` (0-3, written at E11).
- Hooks: `e4m2` "The Green Road" reads `e3m2_grain_spoiled` (why the villagers march south) and `e3m2_villagers_spared`
  (false: its convoy starts with **36** villagers instead of 40, recommendation for that writer). `e3m4` reads
  `e3m2_alarms` (0: Vey's opening line changes to "Not one alarm. She's getting better, Bishop.").
- Level not carried.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / patrol / sleeper / wave counts | x 0.6, no Blaze Rider in PT2 / WG4 | as written | x 1.4 |
| Dawn countdown | 13:00 | 11:00 | 10:00 |
| Hush HP / Blink damage | 1 100 / 75 | 900 / 65 | 750 / 60 |
| Spot fuse / alarms to wake Vessa | 4 s / 4 | 3 s / 3 | 2 s / 2 |
| Vey's detection (lit / concealed / veiled) | 7 / 4 / 2 m | 9 / 5 / 3 m | 11 / 6 / 3 m |
| Phase 2 hold / crystals | 2:00 / 800 | 2:30 / 600 | 3:00 / 500 |
| Expected time | 12-15 min | 14-18 min | 16-21 min |
**Fight sizing** (normal; the episode rule: every guarded fight <= 70 % of the player's force then; a camp alert is meant
to exceed it: the alarm is the punishment, the safe line the escape). The squad is 980 + Hush (~700: 900 HP, 34 DPS,
Blink, Knives).
| Fight | Enemy | Player then | Ratio |
|---|---|---|---|
| A crest post (P1-P6) | 120-190 | 1 680 | 7-11 % (silent kills: Blink from the veil one-shots the archer) |
| WG1 / WG3 guards | 295 / 280 | 1 680 | 17-18 % |
| WG4 guards (the first real fight) | 460 | 1 680 | 27 % |
| PT2 caught in the open | 550 | 1 680 | 33 % |
| Camp alert near the Fire camp (P3 + P4 + PT2 + ST2) | ~1 120 | 1 680 | 67 % (survivable, costly) |
| Alarm 3 (Vessa + 4 Riders + an alert) | ~1 900 + Vessa | 1 680 | > 100 %: run to the safe line |
| R1 (phase 2, 0 alarms) | 1 380 + Vessa L6 (350) | squad survivors ~800 + Malrik L5 + Hush L5 (~650) + 2 Reavers (520) + Citadel keep + Torvald ~1 000 | ~45 % |
| R1 + R2 overlap | 2 360 + Vessa | ~3 500 | ~67 % |
- The night is a puzzle with a fight in it, not a battle: a player who snuffs F8, kills the WG4 archer with a veiled
  Blink and lets the Reavers and Shades take the two Flame Guards and the Rider spoils WG4 with no alarm in ~1:00.
- **The Sunburn lesson**: the Ember Archers' burning arrows halve the Reavers' drinking for 4 s; kill the archers first.
- Watch in the first playtest: if players never find the veiled WG2 answer, add a hint at the second Vey sighting
  (`Veiled, Hush is unseen beyond 3 m. Wait for the old man to walk to the tree.`); if Alarm 3 is never reached on
  normal, the 3 s fuse is right; if it is reached in most runs, make it 4 s.

## Target length (normal)
| Part | Time |
|---|---|
| `c_e3_knife` + briefing (outside the mission) | ~1:30 (not counted) |
| `e3m2_slip` | 0:15 |
| The night (`mission_time`) | 8:30-10:30 |
| `e3m2_embers` | 0:25 |
| First Light (set-up 0:40 + hold 2:30) | 3:10 |
| `e3m2_dawn` + 2 s | 0:32 |
| **Total** | **~13:00-15:00 clean, 14-18 with one alarm and a retreat** |

## Implementation tasks (the lead adds them to `waves.md`)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| E3M2.S1 | systems | `missions/mission_e3_02.tscn` + `MissionE302`: load `evenmead.map`, `RiverSystem.setup` as e3m1; the night layer (10 watch-fires, 4 wagons, 4 villager tent clusters, 3 army tent clusters, Vessa's tent, posts, patrol loops, Vey's vigil path) at the table positions; standards as side-0 decals; Horn Spires absent; bot workers removed; the ridge base locked in phase 1 (`MissionBase.lock_base(true)`), economy hidden, `items_locked`; `FogOfWar.sight_scale[ENEMY] = 0.6`; watch-fire (enemy `SightMarker` r 15, snuff 2 s / 2 m, relight by patrols at 4 m); wagon (500 HP, sabotage 4 s / Hush 2 s, reset on leaving or damage, destroy = alarm); villager tents in `"noncombatant"` | E34.M1, M9.S1 | `tests/test_e3m2_s1.gd`: a Shade snuffs F8 in 2 s and the reset works; WG4 sabotaged by Hush in 2 s, by a Shade in 4 s, not by a Hound; a Thornling at 7 m does not auto-target a concealed Shade and does at 5 m; the same Shade within 9 m of a lit fire is targeted at 7 m; Night of Knives never hits a villager tent; a patrol relights a snuffed fire it passes |
| E3M2.S2 [H] | systems-high | Objectives and events E1-E20 in order; the spotting fuse (3 s, cancel rules, silent kill within 0.3 s), instant alarms, camp alert (45 s, 30 m, sleepers wake, fires relight), Alarm 2 guards, Alarm 3 (Vessa + 4 Riders hunt 90 s, sight x 0.8, concealment 8 m), safe line `z <= 22`; Vey's lure rule; the dawn countdown; **phase switch** (`MissionBase.set_player_hero(unit)` re-points F1 / Space / F-Q-E / instant loss; `Keep.set_start_tier(3)`; the `e3m2_embers` end state); R1 / R2 / Withdraw; D8 call price via a duplicated `HelperType`; win / lose; difficulty table; `MISSION_REWARDS[&"e3m2"]` + `e3m2_alarms` | E3M2.S1, E3M2.G1, TH.S1 | `tests/test_e3m2_s2.gd`: a scripted run spoils the 4 wagons with 0 alarms and wins after the 2:30 hold; a spotter left alive 3 s raises Alarm 1; killing it at 2.9 s raises nothing; 3 alarms wake Vessa; a hunted unit crossing `z = 22` is dropped within 11 s; dawn with 3 wagons = defeat; Hush's death = defeat; after the switch, Malrik's death = defeat and Hush's does not end it |
| E3M2.G1 [H] | gameplay-high | `HushCommando extends Wizard` (`scripts/units/hush_commando.gd`): F / Q / E = `hush_blink` / `hush_smoke` / `hush_knives` through `SpellType` resources with mana 0 (`data/spells/hush_*.tres`), the ability code of `HelperAbilities` (TH.G1) with the story numbers above, level 5 fixed, `add_xp` no-op, veil passive with the stealth radius hook; new status **`concealed`** + `Unit.is_hidden_from(team) -> bool` (true while `disguised` or `concealed` and the viewer is beyond the radius the mission sets), read by auto-aggro and towers (the TH.G2 `disguised` path); `vey_vigil` story unit (invulnerable, Lunge 80 on detect, chase 15 m, the `m4` look) | TH.G1, TH.G2 | `tests/test_e3m2_g1.gd`: Blink from the veil deals 104 and 65 otherwise; the veil comes back after 4 s idle and survives a sabotage channel; a `concealed` unit is ignored by a tower at 7 m and shot at 5 m; `vey_vigil` takes 0 damage; F / Q / E on Hush never ask for mana |
| E3M2.A1 | ai | Post and patrol brains for scripted units (`scripts/ai/ai_sentry.gd`: hold / loop at 2.5 m/s, report sightings to the mission, join alerts, walk back); `AIStoryCaster` for the woken Vessa (Fire rules, hunts Hush); profiles `mission_e3_02_enemy` (defend only, paused in phase 1) and `mission_e3_02_ally` (Torvald: 10 pop, pings, the R1 flank to `(4, -6)`) | E3M2.S1 | Test: a patrol completes its loop in 30 +- 3 s; a post never leaves its spot outside an alert; Torvald's army reaches `(4, -6)` within 40 s of R1 |
| E3M2.U1 | ui | Alarm counter `Alarm 0 / 3` + the spotter eye and fuse ring over enemy units; dawn countdown; Hush's command card (F / Q / E icons from her VFX family, cooldowns, no mana bar); the hero swap (portrait, F-Q-E labels, F1 / Space follow `set_player_hero`); Malrik's phase-1 "voice through the dark" portrait vignette; hints; layout from ui-designer | E3M2.S2 | Readable at 1600 x 900 and 3440 x 1440; the fuse ring visible at 40 m zoom; nothing calls a `_private` function |
| E3M2.C1 | four-wizards-high (cine) | `e3m2_slip`, `e3m2_embers`, `e3m2_dawn` as cine timelines on the mission scene (no new stage set) with the end states above | 19.C1, 19.C2, E3M2.S2 | `cine check` 0 FAIL; a skip of each leaves the listed end state (test asserts the phase-2 set-up after a skipped `e3m2_embers`) |
| E3M2.V1 | tech-artist | Night Evenmead: moonlight preset tuned for the meadow (19.V24 base), watch-fire (lit / snuffed, emission ring), 4 wagons (grain, arrows, oil, fodder) with the sabotaged state, villager tents, army tents with sleeper poses, Vessa's tent (Fire pennant), the Citadel spire scaffolding for `e3m2_embers`; 0 lights | - | Art Lab pass; `PERF OK` with the whole camp, the squad and an alert on screen at night |
| E3M2.V2 | tech-artist | Stealth readability: concealed squad units drawn at alpha 0.75 with a faint violet rim for the player only; lit units lose the rim; the snuff puff and the sabotage spill VFX (<= 2 particle systems each) | E3M2.G1 | A concealed and a lit Shade are told apart at 40 m on the contact sheet |
| E3M2.O1 | Voice Forge agent | Render `data/voice/lines/e3m2.json` (L1-L31), no new speaker | E3M2.D1 | Every WAV fits its slot (L26 6 s) |
| E3M2.D1 | game-designer | Read the 31 lines in game once, trim any over 2 box lines; write `c_e3_knife` and `c_e3_price` (~1:10 each, `episode2-opening.md` format) from the beats above | Playtest | Both scripts written; changes back in this doc |

## Acceptance checks
- [ ] E3M2.S1: the night layer stands at the table positions +-0.5 m on `evenmead.map`; every wagon, fire and tent is
  reachable by the navmesh from the squad start; the ridge base cannot train in phase 1.
- [ ] E3M2.S2: a scripted normal run (snuff F8, kill WG4's guards with Blink first, spoil WG4, WG3, WG2 veiled, WG1) ends
  phase 1 with 0 alarms in 5 / 5 seeds in 7:30-10:30 of mission time; a run that walks lit past P4 raises Alarm 1 within
  4 s; Alarm 3 wakes Vessa; the safe line drops every hunter.
- [ ] Phase 2: Malrik is the hero, the Dusk Keep reads tier 3, V calls Hush in 10 s for 0 / 0, C trains a Nightblood
  Reaver; R1 and R2 come at +0:40 / +1:40; the hold ends `victory=true` with Malrik alive in 5 / 5 runs using the
  scripted army (call Hush, 2 Reavers, Torvald flank).
- [ ] The victory saves `helper_hush_unlocked`, `e3m2_grain_spoiled`, the three secondary flags and `e3m2_alarms`; the
  e3m3 start reads them; Vessa's track is untouched.
- [ ] Total play time on normal 14-18 min with cutscene fallbacks; `PERF OK` with an alert and Vessa's hunt on screen.
- [ ] Lead: one human playtest on normal, reported in `docs/plan/usage-log.md`: night length, alarms raised, whether
  the veiled WG2 answer was found.

Dependencies (must exist first): E34.M1 `evenmead.map` and e3m1's build (MissionE301 patterns), `MissionBase` (M9.S1)
with `set_player_hero` / `lock_base` (added by E3M2.S2 if missing), the helper code and `HelperRoster` (TH.G1, TH.S1),
the Nightblood Reaver (TH.G2), the 2v2 ally layer (`ai-2v2.md`, 20.A*), 19.C1 / 19.C2 for the cutscenes (the mission
plays on the fallbacks without them).

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Mother Hush (helper; played as a hero in phase 1).
- **Why here:** a night raid, enemy sight x0.6, archer-guarded wagons; Hush is strong against casters, heroes and archers.
- **Moment:** WG2: Hush blinks past Old Vey's vigil (veil ring hint).
- **Intro card:** `Mother Hush. The knife in the dark: call her, and the enemy's archers and casters stop sleeping well.`

## Built (2026-10-07): the playable core
`missions/mission_e3_02.tscn` + `scripts/campaign/mission_e3_02.gd` (`MissionE3_02`), test `tests/test_e3m2.gd` (start,
night: snuff / sabotage / alarm, dawn: phase switch + hold, death). Deviations and what is missing:
- The Evenmead map of e3m1 in code; the night layer at the spec's positions with placeholder looks (fire rings, wagon
  and tent boxes); EmberfallNight lighting; no sight scale (`FogOfWar.sight_scale` is not built): concealment is
  mission-side (`Unit.hide_from_auto_target` for squad units no awake enemy sees: concealed 6 m, veiled Hush 3 m, lit
  9 m; attacking exposes 3 s).
- Hush in the night = a plain `Wizard` set up as her (the spec's 900 / 1 100 / 750 HP, 34 damage, the `helper_hush`
  model, no spells, no XP); Blink Strike (weakest enemy within 14 m), Smoke Cloak and Night of Knives are mission-side
  (F / Q / E caught by the mission's `_unhandled_input`, plus a button panel). No `HushCommando` class, no `concealed`
  status.
- Wagons and villager tents are under a full truce: a wagon is spoiled by sabotage only (no loud destroy), a tent can
  never be hit (sec_villagers cannot fail). Sleepers are dormant guards; posts are guards; patrols walk their loops
  (mission-driven); Old Vey's vigil is an invulnerable Ruin Warden stand-in (no Helper brain, no `m4` look).
- Missing: the `c_e3_knife` / `c_e3_price` films, the e3m2_slip / embers / dawn timelines (fallback end states), the
  Reaver Sunburn rule.
- **Finished (2026-10-07, second pass)**: `HushCommando extends Wizard` (`scripts/units/hush_commando.gd`: level 5 fixed,
  no XP, the veil, F / Q / E through `command_cast(&"hush_blink" / &"hush_smoke" / &"hush_knives")`, 2 % / s idle regen
  after 4 s, Unit's idle-regen delay, not the spec's 8 s); the `concealed` status (`Unit.is_concealed()`), set by the
  mission on squad units out of fire-light; towers and keeps never shoot a concealed squad unit no enemy sees
  (`BuildingGun.is_ignored`). Wagons and villager tents are attackable (group `"noncombatant"`: no auto-target): a
  destroyed wagon counts, loud; a hit tent fails `sec_villagers` with an instant alarm; at night the squad never
  auto-attacks a camp building and attacking one is an instant alarm. Alarm 3: sight 12 m (x 0.8), concealment 8 m.
  Patrols stop by a snuffed fire they pass and relight it (3 s). Smoke Cloak: no spotter sees a unit inside it, and
  enemies targeting one drop it. Fixes found by the sim: Vey's Lunge landed every 0.25 s tick (320 / s): now once, 12 s
  cooldown; posted guards walked home the moment they reached an alarm (now they stay the 45 s); camp units chasing
  north of the safe line walk back (P6, north of the line, still fights at its post); Vey's lure stops at z 26; the
  squad ring starts 2 m north of Hush (its south edge stood in F2's light and P2 raised Alarm 1 at 0:04).
- **Scripted runs (normal)**: `tests/test_e3m2_sim.gd` (slow list), the stealth player: WG2 first (F6 snuffed under
  Smoke Cloak while Vey rests at the tree, then the veiled sabotage), then WG4, WG3, WG1 emptied by a Nightblood Reaver
  lure 8.5 m from the wagon (the camp alert keeps the guards there 45 s) while Hush spoils the wagon from the other
  side; dawn: Hush called, 2 Reavers, the loose line south of the keep. The player watches 35 s from each staging spot,
  waits out patrols within 13 m (8 m after a minute) and goes for WG2 when Vey is 10.5+ m from the spot (his far pause
  is ~12 m). Results (normal, final code): 6 / 6 victories, play time 9:42-11:18 (night 5:58-7:34, 3 alarms, 0
  villagers hit); spec 14-18 (night 8:30-10:30): the scripted player is faster than the spec's estimate. Open: a
  human's night is longer (scouting the patrol loops); the `c_e3_*` films would add ~1 min each.
- Reliability fixes in the second pass (sim-found): the sabotage counts within `SABOTAGE_REACH` (the 2 m radius + 2.5,
  the wagon's own footprint) so a unit at the wagon's side is not 0.1 m short; Smoke Cloak drops enemy targets on the
  cast, not on the next tick.

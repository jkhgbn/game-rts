# Campaign mission e2m1: "The Burning Grove" (Vessa + Old Vey vs Malrik + Torvald)

Task: script for `campaign-outline.md` 6 item 5. Episode 2 "The Light Below", mission 1 (id `e2m1`, outline D6). Plays
right after `ep2_opening` "The Feast and the Runner" (`episode2-opening.md`). First mission of the **2v1**: Shadow and
Ice together against Fire, with Nature already broken. Target **20-25 min** on normal. Uses the rules of
`mission-01.md` / `mission-02.md` (MissionBase, scripted groups, 70 % rule, difficulty multipliers), `tiers.md` 6,
`t3-helpers.md` (Old Vey's kit, the Ashveil Saboteur), `caster-units.md` (Kilnwarden), `kingdom-ice.md` (Torvald and his
units), `items.md` campaign rules, `champions.md` 11 (companion). New scene `missions/mission_e2_01.tscn` + script
`scripts/campaign/mission_e2_01.gd` (`MissionE2_01 extends MissionBase`, mission id `e2m1`). Metres, seconds, `m:ss`
since the navmesh was ready; positions `(x, z)`, `y = 0`, `+z` = south. Angles `a` place a point at
`(cos a * r, sin a * r)` around a centre (the `mission-02.md` convention: 0 = east, 90 = south, 180 = west, 270 = north).
Recommended option taken everywhere (no open questions).

## 0. Decisions (recommended option taken)
| # | Question | Decision | Why |
|---|---|---|---|
| D1 | How to build a 2v1 before the 2v2 seat API (`map-2v2.md` 8, step 20) exists | Today's 3 teams: **Shadow and Ice are both team `ENEMY`**. Malrik's camp is run by the bot Commander (gather, train, defend); **Torvald's camp is scripted** (no workers, no Commander, group `"scripted"`; it only sends the scripted waves) | `Unit.Team` is `PLAYER / ENEMY / NEUTRAL` today; one Commander per team is how the code works. The mission does not wait for step 20; e2m2 "Roots and Embers" is the first one on the seat API |
| D2 | Where the player starts | The M3 layout: Fire keep pre-built at the wood's south-west edge (the **Emberwatch**, Fire's border keep that faces the wood), **already a Stronghold** | Episode 1 earned the Stronghold (outline D7: Citadel opens here, so the Stronghold must be in hand at 0:00) |
| D3 | Old Vey: story unit or callable helper | **Callable helper** (`t3-helpers.md` 2-4, his skirmish kit at Vessa's level), called at the Citadel. At 0:00 he is with the army (story NPC, 3 lines), then rides off to scout the north road; the Citadel's call brings him back by lightning | Outline D7 and C3: Vey becomes callable in e2m1. His motto does the teaching: "The spark first, then the storm" = Vessa goes first, the storm comes when called |
| D4 | Price of the first call | **250 crystals + 100 essence, 30 s** in this mission only (skirmish 350 + 200, 60 s). Revive at the skirmish price | He is already on the road; the cheaper call lands him mid-hold (~8:00-9:00) on a normal run, the beat the story needs |
| D5 | Wren and the 12 survivors | Team **`PLAYER`, not commandable** (`UnitType.commandable = false`, the caravan rule), not `NEUTRAL` | `NEUTRAL` is the enemy of both sides (`CLAUDE.md` Teams): the player's army would attack them. The brief's intent (story units the player escorts) is kept |
| D6 | Can Wren die | **No** (the scripted-saviour rule: at 1 HP she kneels 8 s, then stands at 50 %) | She rides through the Ep8 ending (`campaign-outline.md` 4.4 E18) |
| D7 | Aldra in this mission | **Yes, as a story unit only**: Torvald's Glass Warden channels the frost on the Heartwood, untargetable, 3 lines, walks away when the last Rime Totem breaks. Not a callable helper here | `t3-helpers.md` 1: "Episode 2 at Torvald's side". The first face of the Ice side the player meets, before Torvald himself |
| D8 | Pell, tavern, champions | No Pell (he returns in e2m3 "The Salt Road"); the Crooked Lantern is a burnt ruin (no hiring); the **companion** from the Ep1 save walks in beside Vessa | `champions.md` 11 carries the companion; a hiring tutorial here would split the mission's focus (the Citadel and Vey) |
| D9 | Terrain (ash + snow) | **Look now, rules later**: the art paints ash (south and east) and snow (north and west). If `TerrainSystem` exists when the mission is built (step 12b), the patches in "Map" are registered as `ash` / `snow` and the `terrain.md` 3.1 rows apply (Fire +10 % damage on ash, Ice +25 % speed on snow) | TerrainSystem is not built yet; the mission must not wait for it |
| D10 | Mission name and id | `e2m1`, `mission-e2-01.md`, `missions/mission_e2_01.tscn`, `scripts/campaign/mission_e2_01.gd`, `CampaignState.MISSION_SCENES[&"e2m1"]` | Outline D6 |

## Story setup (briefing text, 3 short paragraphs)
1. The feast ended at midnight. By first light the Emberguard was on the road north, and by noon it reached the
   Sighing Wood, or what is left of it: black trunks under white frost, ash that crunches like snow.
2. Shadow burned the wood and Ice froze the ashes so nothing could grow back. Wren says one heart still beats: the
   **Last Heartwood**, beside the dead Oldroot, where Ysolde fell back with her final wardens. Torvald's frost is
   creeping over it.
3. Malrik and Torvald hold the north of the wood, one camp each. Two wizards against one. Vessa has never been good at
   arithmetic, and she is not about to start.
Briefing objectives: `obj_heartwood`, `obj_hold`, the rule `Vessa must survive`, and the line `Torvald's frost is
creeping over the Heartwood. Reach it before it stops beating.`

## Map: "The Burning Grove" (120 x 120, the `main.gd` generator, **not mirrored**, `MAP_SEED := 1303`)
The Sighing Wood of M3 (`story-episode-1.md` 5.3), the same seed and generator, burnt and frozen: only broadleaf and old
oaks, all **charred** (no leaves, black bark) with **frost-rimed** tops; no fireflies; the M3 Root Heart glades are ash
circles. Four corners, four kingdoms (the 2v2 frame of `map-2v2.md` 2 read on a 1v1 map): Fire south-west, Ice
north-west, Shadow north-east, burnt Nature south-east. Clearings: no tree or rock inside the listed radius.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / Fire keep "Emberwatch" | `(-36, 36)` / `(-43, 43)` | 18 | Pre-built, complete, **tier 2 Stronghold** (3 000 HP) |
| Ember Hall / Hearth / Ember Spire | `(-27, 45)` / `(-36, 50)` / `(-32, 30)` | 4 / 3 / 3 | Pre-built, complete (M3 layout + the Spire on the north approach) |
| Nodes `e2m1_fire_a` / `e2m1_fire_b` | `(-46, 34)` / `(-34, 46)` | - | **1 500** each |
| Node `e2m1_west` (expansion) | `(-50, 8)` | 7 | **2 000**; hall spot `(-43, 9)`. The Ice raid path passes 30 m north of it |
| Node `e2m1_south` (expansion) | `(4, 50)` | 7 | **1 500**; hall spot `(-3, 51)` |
| **The dead Oldroot** | `(0, 0)` | - | The colossal M3 oak, dead: black, split, frozen; trunk obstacle r 3 (`"navigation_geometry"`); decor + landmark |
| **Heartglade** | centre `(0, 4)` | **14** | The hold zone. North half (z < 4) snow, south half ash (D9) |
| **The Last Heartwood** | `(0, 9)` | - | Story target, radius 2 (section "The Heartwood") |
| Rime Totems T1 / T2 / T3 | `(-7, 9)` west, `(7, 9)` east, `(0, 16)` south (r 7 around the Heartwood at 180 / 0 / 90) | - | Frost sources (section "The frost"), 400 HP each |
| Aldra's channel spot | `(-3, 14)` | - | Story unit (D7) |
| Survivor hideout **S1 "Fernhollow"** | `(-30, -4)` | 5 | 4 survivors + guard G3 |
| Survivor hideout **S2 "Charred Glade"** | `(26, 28)` | 6 | 4 survivors + guard G4 |
| Survivor hideout **S3 "Greenhold ruins"** | `(43, 43)` | 12 | Ysolde's burnt border keep (decor ruin, not a building); 4 survivors + guard G5 |
| Lost Caches | `(-15, -15)` (inside the burnt Crooked Lantern ruin) and `(30, 0)` | 3 | `items.md` loot, appear at 2:00, reopen 180 s |
| **Malrik's camp** | Dusk Keep `(43, -43)`, Gloom Hall `(27, -45)`, Night Spire `(37, -29)`, Hovel `(50, -46)` | 18 / 4 / 3 / 4 | Bot slots H1 / S1 / V1 (M1 / M3); nodes `(46, -34)` / `(34, -46)` 1 500 each; rally `(30, -30)` |
| **Torvald's camp** | Rime Keep `(-43, -43)` (3 000 HP), Frost Hall `(-27, -45)`, Rime Spire `(-37, -29)` (720 HP, chill 2 s), Snow Lodge `(-50, -46)` | 18 / 4 / 3 / 4 | The x-mirror of Malrik's camp. All group `"scripted"`, no workers; nodes `(-46, -34)` / `(-34, -46)` exist but stay unmined; Ice rally `(-30, -30)` |
| Wave spawns | Shadow: Gloom Hall spawn point (Dusk Keep's if the hall is gone) · Ice: Frost Hall spawn point (Rime Keep's if gone; the map corner `(-56, -56)` if both are gone) | - | Same for Malrik's |
| Vey's exit / return | Exit: north edge `(-10, -58)` | - | He returns by the helper arrival at the keep door |
Distances (navmesh, approx.): Fire keep -> Heartwood 55 m; Gloom Hall -> Heartwood 60 m; Frost Hall -> Heartwood 60 m
(both enemy sides arrive in about the same time: the waves alternate sides, not distances); Frost Hall -> Fire keep 89 m.
Generator check (E2M1.S1): every listed clearing is applied after the M3 clusters; a navmesh path exists from
`PLAYER_START` to each hideout, to the Heartglade and to both enemy camps.

**Look** (E2M1.V1): grey-white sky, low cold sun `(0.92, 0.90, 0.95)` energy 1.0, ambient `(0.55, 0.55, 0.62)`; ash ground
`(0.20, 0.19, 0.18)` with faint embers in the south and east; snow drifts `(0.86, 0.89, 0.94)` in the north and west and
on the Heartglade's north half; thin smoke columns from 6 trunks (cheap particle cards, 0 lights); the lane is trodden
ash-slush `(0.35, 0.33, 0.32)`. The Heartwood is the only green thing on the map.

## The Heartwood (new prop, systems; a `MissionBrazier` subclass with a `Building`-like target)
- A young tree 4 m tall growing from the dead Oldroot's south root, a green seed-heart 1.2 m in its trunk that pulses
  `(0.55, 0.90, 0.35)` (emission, 0 lights). Group `"scripted"`, always shown through the fog (like the M2 Heartfrost).
- **Before the kindle**: team `NEUTRAL`, invulnerable, ignored by every unit; frost decal over it grows with `frost`.
- **Kindle** (the brazier rule): Vessa within **4 m for 3 s** (progress ring; leaving the 4 m resets it, damage does
  not), **only while no enemy unit and no Rime Totem is within 10 m of the Heartwood** (Aldra and the wizards do not
  count). If one is, the ring stays grey and the message `Clear the glade first: the roots won't open while the enemy
  stands in it` shows once (4 s). Why: no "run Vessa in and channel" cheese (the M1 lesson).
- **After the kindle**: team `PLAYER`, **1 500 HP**, armor 10, radius 2, `counts_for_defeat` false (its own lose rule
  below); regrows **0.5 % / s** (7.5 HP/s) while no enemy is within 12 m; sight 14; **Sap Ward** aura r 8: own units
  inside get `idle_regen_pct` +1.0 (modifier `aura:sap`, the Riverside-mending numbers). Waves target it. HP bar as a
  building's. Destroyed = defeat.
- **Ysolde's last wardens**: at the kindle 3 Thornlings + 2 Bloomtenders climb out of the roots (team `PLAYER`,
  **commandable**, pop 0 "guests", veterancy level 2). The player's first Nature units: a taste of the 2v2.

## The frost (Torvald's clock before the kindle)
`frost` 0-100 %, shown from 0:00 in the objectives panel (`obj_heartwood`).
| Rule | Value |
|---|---|
| Rate | **0.278 % / s** with all 3 Rime Totems standing (100 % at **6:00** from 0:00) |
| Totems | Each Rime Totem destroyed removes **one third** of the rate (2 left 0.185, 1 left 0.093); 0 left = the frost stops (it does not go down) |
| Messages | `The frost has taken half the Heartwood` at 50 %, `The Heartwood is almost frozen` at 80 % (4 s each) |
| 100 % before the kindle | Defeat (E15) |
| After the kindle | `frost` is gone (the frost decal melts in 2 s) |
**Rime Totem** (new prop, systems; Ice building look, M2's Heartfrost family): a 2.6 m hex prism of ice on a rune base,
team `ENEMY`, a `Building` (400 HP, armor 10, `counts_for_defeat` false, not targetable before it is explored), a blue
frost beam to the Heartwood (cosmetic). It does not attack. Destroyed: 0.4 s shatter, 12 shards.

## Start state (from the campaign save, Vessa's track: outline D8)
Order in `_on_navigation_ready` (the M2 order): spawn Vessa -> `CampaignState.open(...).apply_to_start(self)` -> companion
-> story units -> scripted groups.
| Item | Value |
|---|---|
| Vessa | **Level 4 with 3 unspent spell points** (Fireball r1 known), **cap 8** (levels are never carried) |
| Artifacts / items | From the save: the 3 relics owned (Crown, Orb, Signet), 2 equipped as chosen on the choice screen; the 6 item slots |
| Essence | **150** + carried (already 50 %, cap 1 500); +1 / s |
| Crystals | **400** (easy 500, hard 300) |
| Buildings | Keep (tier 2 Stronghold, 3 000 HP), Ember Hall, Hearth, Ember Spire (all complete) |
| Units | 6 Cinder Hands gathering (3 / 3 on the two home nodes); 6 Flame Guards, 4 Ember Archers, 2 Blaze Riders, 2 Pyre Adepts at `(-32, 32)` (1 560 crystals of army); the companion beside Vessa (if saved) |
| Story units | **Wren** (D6) beside Vessa; **Old Vey** (story NPC, invulnerable, not selectable) at `(-34, 34)` until E2 |
| Population | 6 + 6 + 4 + 4 + 2 = **22 / 40** (keep 20 + Hearth 20); the companion counts 2 |
| No save / Ep1 not completed (menu debug, tests) | Crown + Signet equipped, Orb owned; empty slots; essence 150 + **600**; no companion |
| Malrik's side | Dusk Keep, Gloom Hall, Night Spire, Hovel, 5 Gloom Thralls gathering, 6 Shades + 2 Nightbolts at the rally; **Malrik level 5** (Lance r2, Siphon r2, Shroud r1) at `(30, -30)` |
| Torvald's side | Rime Keep, Frost Hall, Rime Spire, Snow Lodge (all `"scripted"`); 4 Rimeshields at `(-30, -30)`; **Torvald level 5** (Rime Bolt r2, Flash Freeze r2, Rime Aegis r1) at `(-30, -30)`; **Aldra** at her channel spot |

**Wren** (`wren`, new story UnitType, gameplay; model 19.V B3 of `episode2-opening.md`, stand-in Wildwood Archer): team
`PLAYER`, `commandable = false`, 260 HP, armor 0, speed 5.2, sight 12, no attack. Brain: stay 3-6 m behind Vessa; at
1 HP she kneels 8 s (untargetable while kneeling) then stands at 50 %. While she lives, every hideout not yet freed shows
a green ping on the minimap every 30 s ("Wren knows where they hide"). Survivors follow the first of Vessa or Wren.

**Wood-folk survivors** (`wood_folk`, new UnitType, gameplay; look = a Sprigling with an ash-grey cloak and a bundle):
team `PLAYER`, `commandable = false`, 45 HP, armor 0, speed 4.5, no attack, pop 0, kill_xp 15 for the killer. Hidden
(not shown, untargetable) until freed.

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Hearth, Ember Hall, Ember Spire | Research buildings, Bazaar, walls |
| Units | Cinder Hand; Ember Hall: Flame Guard, Ember Archer, Blaze Rider, Ash Hurler, Pyre Adept, Cinder Arbalest (the M2 card: Z X C V B N); keep: Kilnwarden (B); **from the Citadel: Ashveil Saboteur (keep, C)** | Scorchbow, cavalry mounts, titans |
| Keep | **Citadel** (X, 300 crystals, 90 s, from **5:45**) | - |
| Helper | **Old Vey** (keep, V) once the Citadel stands: 250 crystals + 100 essence, 30 s, pop 4 (D4) | Other helpers |
| Spells | Fireball, Ember Step, Kindle; cap L8 | - |
| Items | Base shop (keep, Ember Hall); the caches | Pell's stock, top items stay out of reach on purpose |

## Tiers and the helper (`tiers.md` 6, `t3-helpers.md` 3)
| Item | Value |
|---|---|
| Code | `MissionE2_01._init`: `tiers_enabled = true`, `casters_enabled = true`, **`t3_enabled = true`** (new mission opt-in read by `T3Kit.enabled_here()`, like `casters_enabled`), **`helpers_enabled = true`**; `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, the player's keep starts at tier 2 (`Keep.set_start_tier(2)`: HP 3 000, attack 16, no announcement) |
| Keep card | Z Cinder Hand · X **Citadel** (gold pulse when it can start) · C **Ashveil Saboteur** (greyed `Requires Citadel` until then) · V **Call Old Vey** (greyed `Needs a Citadel`), then `Revive Old Vey` when fallen · B Kilnwarden · Set Rally r3c1 |
| Citadel hint | Once, when the upgrade can start: message 12 s `Your Stronghold can become a Citadel: select the Keep and press X (300 crystals, 90 s). It opens the Ashveil Saboteur (C) and lets you call Old Vey (V).`; tier chip `Tier 2 Stronghold · Citadel ready: X` |
| Call hint | Citadel complete: the tiers.md completion message, then L17 and the hint `Call Old Vey: select the Keep and press V. He fights on his own; his card sets where (Escort / Vanguard / Hold home).` (10 s) |
| Old Vey | `helper_vey` kit at Vessa's level (L4 x1.12 ... signature Stormcall from L5), stance Escort, F4 = centre on him. Death = fallen (never a defeat), revive 120 + 20 x level essence, 25 + 5 x level s at the keep door |
| Saboteur here | Max 4. Powder Charge works on both camps' buildings (250, x1.5 breaching): two charges + a few soldiers burn the Frost Hall (`sec_frosthall`). **Eavesdrop (mission bonus)**: while a disguised Saboteur stands within 12 m of the Gloom Hall or the Frost Hall, the next wave from that side is announced 30 s before it leaves (`Eavesdrop: Ice wave in 0:30 · 4 Rimeshields, 3 Shardcasters, 1 Rime Seer`) |
| Enemy keeps | Never upgrade (`bots_upgrade = false`); scripted waves carry their own unit lists (T2 units included where listed) |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_heartwood` | Primary | `Reach the Heartwood before the frost takes it (37 %)` | The kindle completes (E7); **failed** at frost 100 % = defeat |
| `obj_hold` | Primary (after `obj_heartwood`) | `Hold the Heartwood (12:00)` (countdown) | The countdown ends with the Heartwood alive |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `sec_folk` | Secondary | `Bring Ysolde's people to the Emberwatch (0 / 12)` | **10+** survivors reached the Fire keep (within 8 m) by the end of the hold; **failed** when the 3rd survivor dies |
| `sec_frosthall` | Secondary | `Shatter Torvald's Frost Hall` | The Frost Hall at `(-27, -45)` is destroyed |
| `sec_storm` | Secondary (appears at E2) | `Raise a Citadel and call Old Vey` | Old Vey arrives (E11) |
States through `Events.objective_changed(id, state)`: `"active"`, `"done"`, `"failed"`.

## Guards and scripted waves (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units: team `ENEMY`, group `"scripted"`, never controlled by the Commander; guards hold their spot with normal
auto-aggro and a 2x leash (M1 rules). Waves attack-move as listed, refreshed every 3 s when the order says "then".
`T` = the moment of the kindle (E7).
| Group | Where | Units | Value |
|---|---|---|---|
| G1 burnt road | The lane at `(-20, 20)`, 20 m from the start | 3 Shades + 2 Nightbolts | 440 |
| G2 Heartglade siege | Ring r 7 around the Heartwood, between the totems | 3 Rimeshields + 2 Shardcasters + 1 Rime Seer + 3 Shades + 1 Nightbolt (+ the 3 Rime Totems) | 965 |
| G3 Fernhollow hunters | S1, ring r 4 | 3 Grave Hounds + 1 Shade | 290 |
| G4 Charred Glade watch | S2, ring r 4 | 2 Rimeshields + 2 Shardcasters | 410 |
| G5 Greenhold ruins | S3, ring r 6 | 3 Shades + 2 Nightbolts + 1 Rimeshield + 1 Rime Seer | 655 |
| G6 Ice camp guard | Ice rally `(-30, -30)` | 4 Rimeshields (start units; they defend the camp, leash 2x) + the Rime Spire | 380 |
| Wave | Trigger | Units | Order |
|---|---|---|---|
| P1 base probe (Shadow) | 3:00 | 3 Shades + 2 Grave Hounds | Attack-move to the Ember Hall (tests the base while the army is out) |
| H1 Shadow | T + 0:30 | 4 Shades + 2 Nightbolts + 2 Grave Hounds (660) | Attack-move to the Heartwood, then to Vessa |
| Raid (Shadow) | Every 150 s from T + 1:00 until the hold ends | 2 Grave Hounds | Attack-move to the nearest walking survivor, else the nearest Fire worker |
| H2 Ice | T + 2:30 | 4 Rimeshields + 3 Shardcasters + 1 Rime Seer (830) + **Torvald** | Attack-move to the Heartwood, then to Vessa; Torvald follows the wave |
| H3 Shadow | T + 4:30 | 5 Shades + 3 Nightbolts + 1 Shadow Knight + 1 Gloom Deacon (1 110) | Heartwood, then Vessa |
| H4 Ice | T + 6:30 | 4 Rimeshields + 2 Shardcasters + 1 Rime Colossus + 1 Frost Mortar (1 080) + Torvald | Heartwood, then Vessa |
| H5 pincer | T + 8:30 | Shadow 4 Shades + 2 Nightbolts + 1 Shadow Knight (780) **and** Ice 3 Rimeshields + 2 Shardcasters + 1 Rime Seer (625), same second, from both camps; **Malrik joins** (level 6: + Lance r3) | Heartwood, then Vessa |
| H6 final | T + 10:30 | Shadow 6 Shades + 3 Nightbolts + 1 Shadow Knight (1 040) and Ice 4 Rimeshields + 2 Shardcasters + 1 Rime Colossus (890); **both wizards** (Torvald level 6: + Rime Bolt r3) | Heartwood, then Vessa |
| Withdraw | `obj_hold` done | Every living scripted unit and both wizards | Walk to their own camp (no fighting unless attacked); despawn at the camp |
Rules: if `sec_frosthall` is done, every later **Ice** wave loses 40 % of its units (rounded down) and H4 / H6 have no
Colossus (the M1 rule). The two wizards respawn 60 s after a death at their own keep (`Malrik has fallen back into the
shadows` / `Torvald has fallen, the frost will bring him back`) and rejoin the current wave, or walk back to their
rally. Before H2 Torvald stays at `(-30, -30)`; before H5 Malrik stays at his rally (the bot's defence rule).
The bot (`ai.md`, profile `mission_e2_01`: Shadow normal knobs, `min_attack_pop` 99, `worker_target_home` 5, no
expansion, no towers beyond S1, keeps up to 10 soldiers at `(30, -30)`) gathers, trains and defends its camp only.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cinematic `e2m1_arrival` (HOLD 0:20, below), then camera on Vessa; L1-L3; `obj_heartwood` active, frost starts; hint `Reach the Heartwood past the dead oak. Clear the glade, then hold Vessa beside it to kindle it.` (10 s) |
| E2 | 0:25 (after L3) | L4-L5; Old Vey walks to `(-10, -58)` and leaves the map; `sec_storm` and `sec_folk` active; hint `Wren knows where the survivors hide (green pings). Free them and they walk to your keep.` |
| E3 | G1 first seen | L6 |
| E4 | 3:00 | P1 launches; Ashby: L7 |
| E5 | Vessa within 18 m of the Heartwood (first time) | Cinematic `e2m1_frostwarden` (PAUSE 0:12): L8, L9 |
| E6 | 3rd Rime Totem destroyed | L10; Aldra walks to the Ice camp and despawns there |
| E7 | Kindle complete | L11-L12; the Heartwood turns `PLAYER`, its wardens climb out; `obj_heartwood` done, `obj_hold` active (12:00 countdown); hint `Hold the glade. Shadow comes from the north-east, Ice from the north-west.` (8 s); waves armed |
| E8 | H1 launches | L13-L14 |
| E9 | H2 launches | L15-L16 |
| E10 | Citadel complete | L17; the call hint |
| E11 | Old Vey arrives (helper arrival set-piece at the keep door, no camera takeover) | His arrival bark (`t3-helpers.md` 10.4) then L18; `sec_storm` done |
| E12 | Vey's first Stormcall | L19 (once) |
| E13 | A hideout freed (its guards dead + Vessa or Wren within 6 m) | The 4 survivors rise and walk to the Fire keep; first time L20; each arrival counts in `sec_folk` |
| E14 | The 12th survivor reached the keep | L21 |
| E15 | `frost` reaches 100 % before the kindle | L29; defeat after 3 s |
| E16 | Frost Hall destroyed | L22; `sec_frosthall` done |
| E17 | H5 launches | L23 |
| E18 | H6 launches | L24 |
| E19 | Heartwood below 50 % HP (first time) | L25 |
| E20 | `obj_hold` done | Withdraw; L26; after 4 s cinematic `e2m1_ysolde` (PAUSE 0:30): L27-L28; `Events.mission_ended(true)` 2 s after it; StoryFlow then plays `c_e2_ashes` |
| E21 | Vessa dies | L30; `obj_vessa` failed; defeat after 3 s |
| E22 | Heartwood destroyed | L31; defeat after 3 s |
| E23 | Fire keep destroyed | Defeat after 3 s (no line) |
Hideouts and the Frost Hall can be done in any order, before or during the hold. The intended rhythm: S1 on the way north
(or skipped for the frost), the Heartglade by ~4:30, S2 with a detachment between H1 and H2, S3 and the Frost Hall
(Saboteurs, Blaze Riders) when the player feels strong, typically after Vey arrives.

## Dialogue (31 lines; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist; `vey` is the speaker, `torren` its alias; `messenger` = Wren).
Colours: Vessa `(1.0, 0.45, 0.1)`, Old Vey `(0.95, 0.95, 0.55)`, Wren **new** `(0.80, 0.92, 0.60)`, Captain Ashby
`(0.95, 0.60, 0.35)`, Malrik `(0.7, 0.3, 1.0)`, Torvald `(0.55, 0.80, 1.00)`, Aldra `(0.62, 0.95, 0.88)`, Ysolde
`(0.55, 0.90, 0.35)`, Narrator `(0.9, 0.85, 0.7)`. Names shown: `Vessa`, `Old Vey`, `Wren`, `Captain Ashby`, `Malrik`,
`Torvald`, `Aldra`, `Ysolde`, `Narrator`. Wren's stumbles are written into the spoken text (the e2o rule); the subtitle
column is the clean reading where it differs.
| Line | Event | Speaker | Text (spoken) | Subtitle if different |
|---|---|---|---|---|
| L1 | E1 | narrator | The Sighing Wood kept out of every quarrel for a century. Now it is ash, and the ash is frozen. | - |
| L2 | E1 | vessa | Fire AND frost. They didn't just burn it. They made sure it stayed dead. | - |
| L3 | E1 | messenger | The Heartwood... it's still... past the old tree. She's in there. She's inside it. | The Heartwood is past the old tree. She's inside it. |
| L4 | E2 | vey | I'll ride the north road and see what Torvald brought. Light the beacon when you want the storm. | - |
| L5 | E2 | vessa | You just got back, and you're leaving again? You're lucky I'm busy. | - |
| L6 | E3 | vessa | Shades in the ashes. Malrik never could resist a funeral. | - |
| L7 | E4 | ashby | Shadow at the camp, my queen! We'll hold the hall. Go! | - |
| L8 | E5 | aldra | Hold the rime. When the green stops beating, the wood is ours. | - |
| L9 | E5 | torvald | So the little ember comes to warm the wood. You are late, child. Winter got here first. | - |
| L10 | E6 | aldra | Cracked. Not broken. Torvald will hear of this. | - |
| L11 | E7 | vessa | You always said fire was the problem, Ysolde. Today it's the answer. | - |
| L12 | E7 | messenger | The roots... they're warm. They're warm again! | The roots are warm again! |
| L13 | E8 | malrik | Vessa. Have you noticed whose side the winter is on now? | - |
| L14 | E8 | vessa | Two of you, one of me. Sounds fair. For me. | - |
| L15 | E9 | torvald | I told Malrik no, once. Then I watched you carry three keys toward the Hollow. | - |
| L16 | E9 | vessa | So you picked the man who sends knives at night. Great judgement, Torvald. | - |
| L17 | E10 | vessa | The beacon's lit. Vey! You said call. I'm calling! | - |
| L18 | E11 | vessa | Twelve years late, then twelve hours. You're improving. | - |
| L19 | E12 | vey | The spark first. Then the storm! (4 s) | - |
| L20 | E13 (first) | messenger | You're alive! Go... go south. Follow the red banners! | You're alive! Go south, follow the red banners! |
| L21 | E14 | messenger | That's... that's everyone. Everyone who could still walk. | That's everyone who could still walk. |
| L22 | E16 | vessa | That's one hall Torvald won't need to keep cold any more. | - |
| L23 | E17 | narrator | Shadow from the east, frost from the north. The two new friends close the vice. | - |
| L24 | E18 | torvald | Now, Bishop. Before the spring remembers itself. | - |
| L25 | E19 | messenger | The heart's slowing! Please... please don't let it stop! | The heart's slowing! Please don't let it stop! |
| L26 | E20 | torvald | Spring is stubborn. So is winter. This is not over, child. | - |
| L27 | E20 (`e2m1_ysolde`) | ysolde | You came. I told you to remember. I didn't think you'd listen. (6 s) | - |
| L28 | E20 (`e2m1_ysolde`) | vessa | I never listen. I just show up. | - |
| L29 | E15 | aldra | The green has stopped. Winter keeps this wood now. | - |
| L30 | E21 | vessa | Ysolde... I came. I really came... | - |
| L31 | E22 | messenger | No... no, no. It's gone cold. | No. It's gone cold. |
Old Vey's own barks (arrival, Lunge, Stormcall, low HP, fall, revive) are the helper voice hooks of `t3-helpers.md` 10.4
(`helper_vey_<event>`), rendered in the same `vey` voice; L18-L19 are the only mission lines around them. Every line
<= 2 lines of the dialogue box (<= 96 characters) and fits 5 s at the cast speeds (L27 6 s).
Echoes: L11 answers Ysolde's Ep1 warning; L19 is the motto (V1, M1, ep2 opening); L26 seeds `e2m2`; "three keys" (L15)
is the ep1 10 reason Torvald turned.

## Cinematic hooks
| id | Kind | When | Content | Owner |
|---|---|---|---|---|
| `ep2_opening` | stage film 1:12 (built) | Before the briefing (StoryFlow) | `episode2-opening.md` | - |
| `e2m1_arrival` | ENGINE, **HOLD** 0:20 (the game runs, input locked, skippable) | E1 | 3 shots: CRANE down over the charred, frosted canopy from the south-west, smoke columns; the Fire column (Vessa, Wren on her stag, Vey on foot, the army) walks in at `(-36, 36)`; a slow push north to the dead Oldroot, a faint green pulse at its foot. L1 over shot 1 | four-wizards-high (cine) |
| `e2m1_frostwarden` | ENGINE, **PAUSE** 0:12 | E5 | 2 shots: MS on Aldra, staff raised, three blue beams from the totems into the Heartwood (L8); WS over the glade to the north-west, Torvald's silhouette on the snow ridge at `(-30, -30)` turning away (L9) | four-wizards-high |
| Old Vey's arrival | In-game set-piece (`t3-helpers.md` 10.2) | E11 | A white-gold bolt on the keep door, he stands up out of the flash; banner; no camera move | tech-artist / ui-coder (TH.V5) |
| `e2m1_ysolde` | ENGINE, **PAUSE** 0:30 | E20 | 4 shots: the Heartwood's bark opens; **Ysolde** steps out, wounded (one arm in a bark sling, cloak scorched), and falls to one knee; Vessa catches her (L27, L28); WS: Wren runs in, the wood-folk at the treeline; the Heartwood's green spreads 3 m into the ash (one new sapling decal) | four-wizards-high |
| `c_e2_ashes` "What the Frost Kept" | stage film 1:15 (outline in `campaign-outline.md` 3.2) | After victory | Beats for its writer: night in the Heartglade, Ysolde counts her dead; Vessa offers no jokes; Ysolde: Torvald chose Malrik because of the relics, the Hollow is waking; she gives Vessa the seed-pod token back ("Keep it until the wood can"); **she joins Fire** (Maelis rides in at the end with what is left of Nature's army); Vey and Vessa: "On the way down." the road to e2m2 | game-designer (script) + four-wizards-high |
Fallbacks: if the cine tool or a set is missing, `e2m1_arrival` = the camera on Vessa + L1; `e2m1_frostwarden` = L8-L9 as
dialogue with a 2 s camera pan to the Heartwood; `e2m1_ysolde` = Ysolde spawned as a neutral invulnerable story unit
beside the Heartwood (the M3 `m3_plea` pattern) + L27-L28 as dialogue. Ysolde stand-in: the Nature wizard model.

## Win / lose
| Event | Result |
|---|---|
| `obj_hold` done | **Victory** (after `e2m1_ysolde`) |
| Vessa dies | **Defeat** (instant loss, as M1) |
| Frost 100 % before the kindle | **Defeat** |
| Heartwood destroyed (after the kindle) | **Defeat** |
| Fire keep destroyed | **Defeat** |
| Malrik or Torvald killed | Not a win: the 60 s respawn text above |
| Old Vey fallen, Wren kneeling, all soldiers dead | Nothing; Vessa can still finish |
| Every enemy building of one camp destroyed | That camp's later waves spawn at its map corner; no win |

## Reward carried to e2m2
- No new artifact (the 3 relics stay; outline: `heartwood_seed` comes in e4m3).
- The 6 item slots at victory; essence 50 %, cap 1 500, **+300 first if `sec_folk`**, **+150 first if `sec_frosthall`**.
- Companion: the champion rule (`champions.md` 11).
- `CampaignState.MISSION_REWARDS[&"e2m1"] = {"flags": {"e2m1_folk_saved": "sec_folk", "e2m1_frosthall_shattered":
  "sec_frosthall", "e2m1_vey_called": "sec_storm"}, "bonus_essence": {"sec_folk": 300, "sec_frosthall": 150},
  "next": &"e2m2"}`; plus the always-set flag **`helper_vey_unlocked`** (later Fire missions may switch helpers on;
  the Theatre reveal `helper_vey` unlocks).
- e2m2 hooks: `e2m1_folk_saved` = 4 extra seed-carriers and Wren's thanks line; `e2m1_frosthall_shattered` = Torvald's
  forward Rime outpost starts with one fewer Rime Spire.
- Level not carried.

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6, no Colossus or Frost Mortar in waves, no Knight in H3 | as written | x 1.4 |
| Start crystals | 500 + 2 extra Flame Guards | 400 | 300, no Pyre Adepts |
| Frost (all totems) | 7:00 (0.238 % / s) | 6:00 | 5:00 (0.333 % / s) |
| Hold | **10:00**: H1-H4 as written, H5 skipped, H6 at T + 8:30 | **12:00** | **13:30**: as normal + **H7** at T + 12:00 (= H1 + H2 together, Malrik and Torvald) |
| Wizards | Malrik L4 / Torvald L4 (H5-H6: L5) | L5 (L6 at H5 / H6) | L6 (L7 at H5 / H6) |
| Old Vey call | 200 + 50 essence, 30 s | 250 + 100, 30 s | 300 + 150, 45 s |
| Heartwood | 1 800 HP | 1 500 | 1 300 |
| Expected time | 16-20 min | 20-25 min | 24-29 min |
**Fight sizing (normal, every guarded fight and wave <= 70 % of the army the player can have then; wizards on top are
the skill check).** Income with 6-8 workers ~300 crystals / min.
| Fight | When | Enemy units | Player army then (crystals) | Ratio |
|---|---|---|---|---|
| G1 | ~1:00 | 440 | 1 560 + Vessa L4 + companion | 28 %: must leave **13+ of the 14** start soldiers |
| G2 + totems | ~3:30-5:00 | 965 (+ 1 200 HP of totems, no damage) | ~2 000-2 300 | 42-48 % |
| G5 (hardest hideout) | any | 655 | >= 2 000 | <= 33 % (a detachment of ~1 000 is a fair fight) |
| H3 | T + 4:30 (~9:00) | 1 110 | ~2 600 after the Citadel (300) and Vey (250) | 43 % + Vey |
| H5 | T + 8:30 (~13:00) | 1 405 + Malrik L6 | ~3 000 | 47 % |
| H6 | T + 10:30 (~15:00) | 1 930 + both wizards | ~3 300 + Vey L6 | 58 % |
- The intended answers: G2 = kill the Rime Seer and the Shardcasters first (Fireball), Kilnwarden Slag Rain on the 3
  Rimeshields (armour 15 -> 0), soldiers on the totems; H2 / H4 (Ice) = Kilnwarden + Blaze Riders, fight on the ash side
  of the glade; H3 / H5 (Shadow) = Kindle on the line, Fireball the Nightbolts, Mana Scald on the Gloom Deacon.
- The Citadel is a real choice: 300 + 250 crystals in the 5:45-8:00 window is ~2 minutes of income that does not go into
  soldiers. A player who skips Vey can still win on normal (the waves fit the 70 % rule without him); with him, H5-H6
  become the "storm turns it" moments the mission is built around.
- The survivors pull the army apart on purpose: S2 is 26 m from the Heartwood, S3 45 m. Wren's pings and the 150 s
  hound raids make the escort a small, readable second front, never a second mission.

## Code reuse (recommendation to the lead)
`MissionBase` (extracted in M9.S1, `mission-02.md` "Code reuse") is a prerequisite; if M9.S1 has not run yet, E2M1.S1 does
the extraction with the same "no behaviour change for mission 1" test. Reused: `MissionBrazier` (the Heartwood's kindle),
`_spawn_group` / `_scaled` / `_mark_scripted` / `_tick_guards` / `_order_wave` / `_refresh_waves`, `_set_dormant` (hidden
survivors), `_seal_flash` (totem shatter colour `(0.75, 0.92, 1.00)`), `HelperRoster` (mission price via a duplicated
`HelperType` set before the roster reads it), the `Skirmish` kingdom table for Torvald's respawn text,
`ice_wizard.gd` for Torvald. New: `MissionHeartwood`, `RimeTotem`, the frost meter, the survivor walker (a 10-line
follow / walk-home brain), `wren` / `wood_folk` UnitTypes.

## Done when (proposed ids; the lead adds them to `waves.md`)
- [ ] E2M1.S1 (systems): `missions/mission_e2_01.tscn` + `MissionE2_01` build the map above (seed 1303, the burnt-wood
  generator variant: broadleaf / oak only, all charred; clearings; nodes 1 500 / 1 500 / 2 000 / 1 500; Fire base
  pre-built with the keep at tier 2; Malrik's camp; Torvald's scripted camp with no workers; dead Oldroot obstacle;
  hideouts; caches; the path test to every hideout, the glade and both camps); start state via `apply_to_start` (Vessa L4
  + 3 points, cap 8; 400 / 150 + carried; 22 / 40; companion) and the no-save fallback; the Heartwood (kindle 4 m / 3 s
  only with no enemy or totem within 10 m, then PLAYER 1 500 HP, regrow 0.5 % / s, Sap Ward) and its 5 wardens; Rime
  Totems; the frost meter (rates per totem, 50 / 80 % messages); survivors (hidden, freed by guards dead + Vessa / Wren
  within 6 m, walk home, counted at 8 m); section "Tiers and the helper" (`tiers_enabled`, `casters_enabled`,
  `t3_enabled`, `helpers_enabled`, `max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(2)`, mission call price).
  `tests/test_e2m1_s1.gd`: the kindle refuses with a Shade at 9 m and completes in 3 s once it dies; frost reaches 100 %
  at 6:00 ± 1 s with 3 totems and stops with 0; a survivor freed at S1 reaches the keep; the keep reads tier 2 at 0:00 and
  the Citadel button is greyed until 5:45.
- [ ] E2M1.S2 (systems-high): objectives and events E1-E23 in order, the 31 lines, waves P1 / H1-H6 / Raid / Withdraw (H7 on
  hard), the -40 % Ice rule after `sec_frosthall`, wizard levels and 60 s respawns, Aldra's story unit (untargetable,
  leaves at E6), Old Vey's story NPC at 0:00 and his exit, the Eavesdrop mission bonus, win / lose table, difficulty
  table, `MISSION_REWARDS[&"e2m1"]` + `helper_vey_unlocked`; `CampaignState.MISSION_SCENES[&"e2m1"]`. Test
  `tests/test_e2m1_s2.gd`: a scripted run kindles, holds 12:00 and ends `victory=true`; frost 100 % = defeat; Heartwood 0
  = defeat; Malrik killed respawns after 60 s.
- [ ] E2M1.G1 (gameplay): `T3Kit.enabled_here()` also reads a scene's `t3_enabled` (like `CasterKit` reads
  `casters_enabled`); `helpers_enabled` honoured by `HelperRoster` in a mission scene; UnitTypes `wren` (story,
  `commandable` false, 260 HP, no attack) and `wood_folk` (45 HP, pop 0, `commandable` false); `Keep.set_start_tier(t)`
  if TierSystem lacks a start hook (systems file: hand it to systems through `docs/handoff/` if so). Test: in the e2m1 scene
  the keep card lists the Saboteur on C and Call Old Vey on V; neither shows in mission 1.
- [ ] E2M1.A1 (ai): profile `mission_e2_01` (Shadow normal knobs, `min_attack_pop` 99, workers 5, no expansion, max 10
  soldiers at `(30, -30)`); the Commander ignores every `"scripted"` unit **and building** (Torvald's camp is not its base:
  no rebuild, no defend rule for it); **`AIStoryCaster`** (`scripts/ai/ai_story_caster.gd`): casts for a scripted wizard
  with its kingdom's rules (Torvald: `kingdom-ice.md` 4.3) and spends its points on the tick after levelling; Malrik
  stays home until H5, then follows it. Test: Torvald casts Flash Freeze on a clump of 3 within 12 m; the Commander never
  orders a Rimeshield.
- [ ] E2M1.U1 (ui): briefing (3 paragraphs + 2 primary objectives + the frost line), objectives panel (frost % turning
  orange at 50 %, red at 80 %; the hold countdown; `0 / 12` survivors), speaker colours and names for `vey`, `messenger`
  (Wren), `ashby`, `torvald`, `aldra`, `ysolde`; Heartwood HP bar; Wren's green hideout pings; the Eavesdrop message;
  layout from ui-designer.
- [ ] E2M1.V1 (tech-artist) **[H]**: the burnt-and-frozen wood: charred broadleaf / oak variants with frost tops, ash and
  snow ground paints (D9 patches), smoke cards, the dead Oldroot (split, black, frozen; r 3 base), the Last Heartwood
  (4 m young tree, pulsing seed-heart, frost decal 0-100 %, kindle burst, `set_team_look`), Rime Totem (+ beam, shatter),
  Greenhold ruin decor, burnt Crooked Lantern ruin; light preset of "Look"; `PERF OK` with H6 on the field.
- [ ] E2M1.V2 (tech-artist): Wren's game model (e2o B3) and the `wood_folk` survivor (Sprigling base, ash cloak, bundle),
  Aldra's channel pose on her helper model (TH.V4) or a stand-in; Art Lab contact sheet at 40 m.
- [ ] E2M1.C1 (four-wizards-high): `e2m1_arrival`, `e2m1_frostwarden`, `e2m1_ysolde` as cine timelines on the mission
  scene (no new stage set), `cine check` 0 FAIL; the fallbacks above when skipped or missing.
- [ ] E2M1.VO (Voice Forge agent): render the 31 lines (`data/voice/lines/e2m1.json`), every WAV fits its slot; no new
  speaker (all in `cast.json`).
- [ ] E2M1.D1 (game-designer): read the 31 lines in game once and trim any line over 2 box lines; write the
  `c_e2_ashes` script from the beats above (1:15, `episode2-opening.md` format).
- [ ] Lead: a scripted headless run on normal (G1, free S1, clear the glade, kindle, Citadel, call Vey, hold) ends
  `victory=true` in 20-25 game-minutes; the G1 fight leaves >= 13 of the 14 start soldiers alive in 5 / 5 runs; a run
  with no Citadel and no Vey still wins on normal in 3 / 5; a save with no Ep1 progress starts on the fallback.

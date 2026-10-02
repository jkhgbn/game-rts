# Campaign mission 3: "The Signet in the Sighing Wood" (Vessa vs Malrik, Ysolde's wood neutral)

Task 19.D2 (part 3 of 4; `campaign-outline.md` 6, item 3). Episode 1's **Twist** mission. Built in step 19 (ids M3.S1-M3.S3,
M3.U1, M3.A1, M3.V1, M3.VO1, M3.D1 at the end; they are the parts of ep1 19.C4, 19.A1, 19.V5 and 19.C9). Third Fire mission,
the **first with champions, the tavern and bounty flags**; target **20-25 min** on normal. Source of truth for the numbers:
`story-episode-1.md` 5.3 (binding; every change is listed in "Changes to the outline"). Uses `skirmish-1v1.md`, `levels.md`,
`items.md`, `champions.md` (taverns, hiring, flags, companion 11), `kingdom-nature.md` (wood guardians), `map-fill.md` 5.5
(Old Mossjaw), `t3-helpers.md` 4.5 (Maelis), `tiers.md` 6, `caster-units.md` 5.1 and the format of `mission-01.md` /
`mission-02.md`. New scene `missions/mission_03.tscn` + `scripts/campaign/mission_03.gd` (`Mission03 extends MissionBase`,
mission id `m03`, `CampaignState.MISSION_SCENES` / `MISSION_ORDER` from 19.C2). Metres, seconds, `m:ss` since the navmesh
was ready; positions `(x, z)`, `y = 0`, `+z` = south. Angles as `mission-02.md` (45 = south-east, 135 = south-west,
225 = north-west, 315 = north-east).

## Story setup (briefing text, 3 short paragraphs)
1. Two relics answer to fire now, and both hum toward the same place: the **Sighing Wood**, Ysolde's border forest, which
   has kept out of every quarrel for a hundred years.
2. The Master's third relic, the **Master's Signet**, sleeps inside the **Oldroot**, an oak older than the kingdoms. Three
   **Root Hearts** feed the thorns that guard it. Malrik's scouts are already in the wood, and his Thralls are draining them.
3. Vessa cannot burn a whole forest and win. So she will do what Malrik never would: pay people. The Crooked Lantern is
   full of sellswords who take no orders, only coin.

Briefing objectives shown: `obj_hearts`, `obj_signet` (as `Take the Master's Signet before Malrik`), `Vessa must survive`,
and the line `Malrik is racing you. If he carries the Signet home, the mission is lost.`

## Map: "Sighing Wood" (120 x 120, the `main.gd` generator, **not mirrored**, `MAP_SEED := 1303`)
Same generator as Emberfall (`mission_01.gd` `_build_map` order: clearings, clusters, rocks, then props), but a **forest**:
**16 tree clusters** of 6-10 trees (Emberfall: 10 of 5-9), cluster centres `randf_range(-52, 52)`, trees skipped outside
`|x|, |z| > 57`, in a clearing or in the lane (`_in_path_lane`, half-width 5, Fire start `(-36, 36)` to `_lane_end()` =
Shadow start `(36, -36)`). Trees: **broadleaf and old oak only** (no fir / pine), scale 0.9-1.5. 18 rocks (mossy). Old Wood
decor everywhere (`map-fill.md` 3.1 row 5: ferns, blue-cap mushrooms, fallen trunks, fireflies; no extra colliders beyond the
generator's), glades = the clearings below. River, points, camps, beasts (except Mossjaw), trade, research, cavalry, titans
**off**. Lights: forest preset (M3.V1). Every distance below was checked against the lane line and the other features.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / Fire keep | `(-36, 36)` / `(-43, 43)` | 18 | As missions 1-2 |
| Ember Hall (pre-built, complete) | `(-27, 45)` | 4 | As missions 1-2 |
| Hearth (pre-built, complete) | **`(-50, 46)`** | 3 | Fire slot V1 (mirror of the Hovel). The outline's `(-36, 50)` sits 4.5 m from node `m3_fire_b`: moved |
| Node `m3_fire_a` / `m3_fire_b` | `(-46, 34)` / `(-34, 46)` | - | **1 500** each |
| Node `m3_west` (expansion) | `(-50, 8)` | 7 | **2 000**; hall spot `(-43, 9)` (27.9 m off the lane, 27 m from RH1) |
| Node `m3_south` (expansion) | `(4, 50)` | 7 | **1 500**; hall spot `(-3, 51)`. 15 m from RH2 and from Mossjaw's centre: take it after RH2 burns and Mossjaw is down |
| **The Crooked Lantern** (tavern) | `(-15, -15)` | 6 | The only tavern (`TAVERN_SPOTS[0]`; the `(15, 15)` one is not built). Door `(-12, -12)`. Explored from 0:00. Opens **0:30** |
| Pell's stall (flag branch) | `(-21, -9)` | 6 | 8.5 m from the tavern; Pell as a `RuinPeddler`, or a Lost Cache (section "Campaign flag branches") |
| Lost Caches | `(-12, 30)` and `(26, 8)` | 3 | `items.md` loot, appear at 2:00, reopen 180 s (Pell's cache is a third, see branches) |
| **The Oldroot** (the Signet tree) | `(0, 0)` | **12** | Colossal oak. Trunk collider **r 1.6**; canopy visual r 10, no collider. The Signet floats inside the split at `(0, 1.6, 0)` |
| **Thorn barrier** | ring **r 7** around `(0, 0)` | - | 18 thorn segments (below). Invulnerable, layer 1, `"navigation_geometry"`. The lane is detoured through the clear band r 7-12 |
| **Root Heart RH1 "Mossgate"** | `(-44, -18)` | 8 | 54.6 m from the Fire start, 82 m from the Shadow start |
| **Root Heart RH2 "Hollowfen"** | `(18, 44)` | 8 | 54.6 m / 82 m; Bramble Spire at `(22, 40)` |
| **Root Heart RH3 "Stagwatch"** | `(44, 14)` | 8 | 83 m / 50.6 m: Malrik's side of the wood |
| Hint circles (minimap only) | RH1 `(-38, -13)` · RH2 `(12, 38)` · RH3 `(37, 10)`, r **15** | - | ~8 m off each heart toward the map centre: "somewhere here" |
| Old Mossjaw's territory | centre `(10, 36)`, roam r 12 | 6 at the centre | Spawns at 6:00 (E7), never respawns |
| Warden Gate **WG1** / **WG2** | `(-30, -36)` / `(32, 32)` | 6 | Ruined arches, closed (no collider beyond the arch footprint 4 x 2) until E11 |
| Dusk Keep (Malrik's forward camp) | `(43, -43)` | 18 | 2 500 HP (`balance-1.md`), shoots as any keep |
| Gloom Hall / Night Spire / Hovel | `(27, -45)` / `(37, -29)` / `(50, -46)` | 4 / 3 / 4 | Bot slots H1 / S1 / V1 (the mission 1 slots) |
| Shadow nodes | `(46, -34)` / `(34, -46)` | - | 1 500 each |
| Shadow rally | `(30, -30)` | - | Where the bot keeps its soldiers; Malrik's anchor |

**Thorn barrier** (new prop, systems): 18 segments **2.6 long x 1.6 tall x 1.2 deep**, centres every 20 degrees (0, 20, ...
340) at r 7, each tangent to the ring (they overlap slightly: 18 x 2.6 = 46.8 m over a 44 m ring, no gap). Static, layer 1,
group `"navigation_geometry"`, not attackable, no HP bar. **Wither** (E10): 5 s sink animation (M3.V1), then removed and the
navmesh rebakes (the M2 floe path). Test: before E10 no navmesh path reaches within 5 m of `(0, 0)`; a path from `(-40, 40)` to
`(40, -40)` exists and passes between r 7 and r 12; after the rebake a path reaches `(0, 2)`.

**Root Heart** (new prop, systems, `scripts/campaign/root_heart.gd`, `RootHeart`): a pulsing seed-pod 2.4 m tall in a root
cradle, radius 1.4, team `NEUTRAL`, group `"scripted"` + `"root_hearts"`, a `Building`-like target (`team`, `is_alive()`,
`take_damage(amount, attacker)`, `target_radius()`) but **not** in `"buildings"` (no auto-aggro, not counted for defeat).
**900 HP**, armor 0, regen **1 % / s** (9 HP/s) after **10 s** without damage. Hidden by fog until its cell is explored, then a
ghost (a building ghost) while not visible. Right-click by Fire units = attack. On death: `destroyed_by` = the team of the
killing blow (credit), the pod bursts (green spores), the thorn barrier loses a third of its height (visual), signal
`heart_down(heart, team)`. If the **player** killed it: an **Ember Stake** is planted on the spot.
- **Drain**: a Gloom Thrall ordered to drain stands within 2 m and channels a violet thread: **4 HP/s** per Thrall
  (`attacker` = the Thrall, so the killing blow can be Shadow's). The pod turns grey-violet as it drains (M3.V1).

**Ember Stake** (new, systems): a `Building` (team PLAYER, **400 HP**, armor 5, pre-built, footprint 1 x 1, **sight 10**,
`counts_for_defeat` false, not a drop-off, no shop). Valid **Guard** flag target (it is an own completed building). Look: a
charred stake with a fire banner and an ember glow (M3.V1).

**Warden Gate** (systems + gameplay, shared with M4: `story-episode-1.md` 19.V2 / 19.C6): a ruined arch, **1 800 HP**, armor
**20**, team `NEUTRAL`, not in `"buildings"`, always visible once E11 plays; attackable by everyone; Slag Rain does not affect it
(a structure). Spawns its Warden tide from the arch's front point (2 m in front, facing `(0, 0)`).

## Mechanic: the race for the Signet
- **The hearts.** The barrier falls when **all 3** hearts are down, by anyone. The objective counter shows each heart's credit:
  a flame icon (player) or a violet eye (Shadow). Shadow takes hearts with **drain squads** (section "Waves"); the player
  takes them with soldiers, Vessa and champions.
- **The muster** (added, see "Changes to the outline"): at E10 Malrik sounds a horn: `Malrik's army marches on the Oldroot in
  1:15` (objective sub-line with a countdown). The race army spawns at the Shadow wave spawn point (the Gloom Hall's; the Dusk
  Keep's if the hall is gone) at E10 and holds at the rally `(30, -30)`; at **75 s** it marches.
- **The march.** Malrik walks to the Signet; his army attack-moves beside him (refreshed every 3 s, leash to Malrik 10 m).
  From the rally to the tree is ~42 m at the group's pace (Shadow Knight 4.0 m/s): ~11-15 s. **Malrik reaches the tree
  ~90 s after the barrier falls if the player ignores it** (the outline's fairness target).
- **Taking it.** The first wizard within **2.2 m** of `(0, 0)` (ground distance) takes the Signet: Vessa = E11; Malrik =
  E10b. Only wizards can take it.
- **Malrik carries it** (the Ember Crown carry rule of `skirmish-1v1.md`: dropped at his death spot, nearest navmesh point, after
  **3 s**, takeable by either wizard). While carrying: `move_speed` x **0.35** (**1.6 m/s**; the Signet's roots drag at his feet,
  M3.V1 tendrils), no Shroud cast. He walks to the Dusk Keep; within **8 m of its centre** = defeat (E15). Path ~53 m: **~33 s**.
  His army escorts him (leash 6 m). The objective becomes `Kill Malrik before he gets home` with a distance bar (60 m -> 0).
- **The drop.** Malrik killed while carrying: the Signet drops (3 s); his army attack-moves to the Signet's spot and holds it
  (r 6) until he respawns at the Dusk Keep (**60 s**, as mission 1) and walks back for it. Vessa can take it at once.
- Why: the hearts reward Explore (find them first), Hunt (kill drain squads) and Guard (keep the stakes that show who is
  coming); the march gives the player a fair, visible window; the slow carry gives a last chance with Blaze Riders.

## Mechanic: champions and bounty flags (first time in the campaign)
`tavern_enabled = true` (`champions.md` 11). The full champion rules apply (roster 3, upkeep, revive, dismiss, the 4
archetypes) with these mission changes:
| Rule | Mission 3 value |
|---|---|
| Opening | **0:30** (`Tavern.open_time = 30.0`); message `The Crooked Lantern opens its doors` replaces `The taverns open their doors` |
| First hire | **0 crystals + 75 essence** + 2 pop ("first drink's on the house"); 2nd / 3rd at the normal 250 + 100 / 300 + 125 |
| Taverns | Only `(-15, -15)`. "Held by the enemy" works as written (a race army passing by can hold it) |
| Bot | Malrik **never hires** (`AIProfile.hire_champions = false` for `mission_03`): the lesson is the player's |
| Companion | None at the start (missions 1-2 had no tavern). After victory the choice screen lists the champions hired here |
Teaching chain (hints, each once): E2 hire, E3 Explore, E5 Hunt, E6 Guard (section "Scripted events"). Bounty flags as
`champions.md` 6 (Hunt on a heart is **invalid**: hearts are not units or enemy buildings; the hint never suggests it).

## Start state (from the campaign save)
Order in `_on_navigation_ready`: spawn Vessa -> `CampaignState.open(campaign_save_path).apply_to_start(self)` -> read
`get_meta(&"campaign_flags")` -> spawn the branch content (Pell or the cache).
| Item | Value |
|---|---|
| Artifacts | From the save: owned + the 2 equipped (normally Ember Crown slot 1, Stillwater Orb slot 2). Modifiers apply from 0:00 |
| Item slots | The 6 slots as saved (types + potion counts), incl. Oath of Embers if earned in M2 |
| Essence | **150** + the carried essence (already 50 %, cap 1 500); +1 / s |
| Vessa level | **Level 3** with **2 unspent spell points** (Fireball rank 1 known), **cap 7** (level rule of `mission-02.md`: never carried) |
| Crystals | **300** (easy 400, hard 250) |
| Buildings | Fire keep (tier 1, Stronghold from 3:30), Ember Hall, Hearth (all complete) |
| Units | 5 Cinder Hands gathering (3 on `m3_fire_a`, 2 on `m3_fire_b`); 4 Flame Guards, 2 Ember Archers, 2 Blaze Riders, 2 Ash Hurlers at `(-32, 32)` |
| Population | **17 / 40** (keep +20, Hearth +20; the outline's "19 / 30" predates the 2026-09-27 house change) |
| No save / m02 not completed (menu debug, tests) | Crown + orb owned and equipped, empty slots, essence 150 + **400**, all flags false |
| Malrik's side | Dusk Keep, Gloom Hall, Night Spire, Hovel; 4 Gloom Thralls gathering; 6 Shades + 2 Nightbolts at the rally; Malrik level **4** (Shadow Lance r2, Siphon r1, Shroud r1) at the rally |

## Unlocks (what exists in this mission)
| Kind | Available | Locked (comes later) |
|---|---|---|
| Buildings | Hearth, Ember Hall, Ember Spire | Bazaar, Stables, Forge / Sanctum (Ep2) |
| Units | Cinder Hand, Flame Guard, Ember Archer, Blaze Rider, Ash Hurler; from the Stronghold: Pyre Adept, Cinder Arbalest (Hall), **Kilnwarden** (keep, B) | Citadel units (Ashveil Saboteur), Scorchling / Scorchbow (skirmish only until Ep2), Ember Boar |
| Heroes | Vessa; **champions** (Wayfinder, Oathwall, Coin-Cutter, Mender), max 3 | Old Vey as a helper (Citadel, e2m1) |
| Spells | Fireball, Ember Step (L2+), Kindle (L4+); cap L7 | - |
| Items | Base shop (keep, Ember Hall) incl. the 4 Ice and 4 Nature items; Pell's stock if he is here; Mossjaw's drops | Top items stay mostly out of reach (~2 500 essence max on normal) |

## Tiers, the Citadel and the Fire helper (`tiers.md` 6, `campaign-outline.md` D7)
As missions 1-2: `tiers_enabled = true` in `_init`, `tier_system.max_tier = 2`, `bots_upgrade = false`, `casters_enabled = true`.
| Item | Value |
|---|---|
| Ember Hall copy | Z Flame Guard, X Ember Archer, C Blaze Rider, V Ash Hurler, **B Pyre Adept, N Cinder Arbalest** (greyed `Requires Stronghold`); the "+" upgrades at the Stronghold (the mission 2 layout, so no key moves between missions) |
| Keep | Z Cinder Hand, X Stronghold (200 crystals, 60 s, from **3:30**), **B Kilnwarden**; **no Citadel button, no C tier-3 slot, no V Call helper** (`can_upgrade` = `Not in this mission` past tier 2) |
| Why no Citadel / Old Vey | Episode 1 is Stronghold only (D7). The Fire helper is Old Vey, who fell into the Hollow in M0 and returns only in M4's storm; he becomes callable at the Citadel in e2m1. The tavern's champions are this mission's new power instead |
| Message | The mission 1 one-time Stronghold message (12 s) when the upgrade can start |
| Malrik | His keep never upgrades; scripted waves and guards unchanged |
Kilnwarden here: Mana Scald on Malrik (Malrik's mana) and on nothing else (Maelis, the champions and the wood guardians have no
mana); Slag Rain is the answer to the Shadow Knight (armor), Maelis's wolves (armor 5) and Ruin Warden packs.

## Campaign flag branches
| Flag | True | False |
|---|---|---|
| `m1_peddler_freed` | **Pell** (a normal `RuinPeddler`, open at 0:00) at `(-21, -9)`; E1: L20 after L3 | A **Lost Cache** at `(-21, -9)`, openable at once (no 2:00 wait), then the cache rules |
| `m1_outpost_burned`, `m2_emberguard_sworn`, `m2_dig_under_half` | Not read in M3 | - |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_hearts` | Primary | `Bring down the Root Hearts before Malrik (0 / 3)` + 3 credit icons | All 3 down (any side) |
| `obj_signet` | Primary (after E10) | `Take the Master's Signet (Malrik is racing you)`; sub-line `Malrik marches in 1:15` until he marches; after E10b `Kill Malrik before he gets home` + distance bar | Vessa takes the Signet (within 2.2 m of it, at the tree or where it dropped) |
| `obj_gates` | Primary (after E11) | `Break the Warden Gates (0 / 2)` | Both gates destroyed |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `sec_champion` | Secondary | `Hire a champion at the Crooked Lantern` | First hire |
| `sec_mossjaw` | Secondary (appears at 6:00) | `Put down Old Mossjaw` | Mossjaw dies (any credit, Shadow too) |
| `sec_stakes` | Secondary (appears with the first stake) | `Keep every Ember Stake standing` | Done at E10 if no stake fell; **failed** the moment one falls. Never appears if the player plants no stake (then it is not offered) |
States through `Events.objective_changed(id, state)` as missions 1-2.

## Guards and waves (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Guards: team `NEUTRAL` (Ysolde's wood; enemy of both sides), group `"scripted"`, hold their spot with normal auto-aggro and a
2x leash (mission 1 rules). Malrik's drain squads have to fight them too.
| Group | Where | Units |
|---|---|---|
| G1 Mossgate | RH1, ring r 3 | 3 Thornlings + 2 Burr Slingers |
| G2 Hollowfen | RH2, ring r 3; tower at `(22, 40)` | 1 Bramble Spire (`nature_tower`, set to **540 HP**) + 2 Bloomtenders + 4 Thornlings |
| G3 Stagwatch | RH3, ring r 3 | **Maelis Oakenhollow** (`helper_maelis`, team NEUTRAL, level **3**: Thornsnare, Call the Pack; no Wild Stampede before L5) + **2 Spirit Wolves** (permanent, scripted, no lifetime) + 4 Thornlings. Fallback if 13c / TH is not built: 2 Bramblehorns + 1 Bloomtender |
| Old Mossjaw | `(10, 36)`, roams r 12 (a new waypoint every 12-20 s), leash 18 | **Elder Grizzlemaw** (variant B, 3 000 HP, armor 25, Maul, Rending Roar, enrage; `map-fill.md` 5.5), named `Old Mossjaw`, from 6:00, never respawns. Fallback: a Hollow Stag |
Maelis is invulnerable to the Signet race rules (not a wizard: she cannot take it). She does not respawn. If 13c is built
but not TH, she uses the `t2.` 5.5 unique-druid kit at level 3.

Waves (Shadow, team `ENEMY`, group `"scripted"`, never controlled by the Commander; spawned at the Gloom Hall spawn point, the
Dusk Keep's if the hall is gone; orders refreshed every 3 s)
| Wave | Trigger | Units | Order |
|---|---|---|---|
| Drain squads D1 / D2 / D3 | 3:00, 7:00, 11:00 | 3 Gloom Thralls + 3 Shades | To the living heart nearest the Shadow camp in the fixed order **RH3, RH2, RH1**. Thralls drain it; Shades attack-move to it (they fight the guardians and any Fire unit there) |
| Late drains (added) | Every 240 s after 11:00 (15:00, 19:00...) while any heart lives | 4 Gloom Thralls + 3 Shades + 1 Shadow Knight | As the drain squads |
| W1 | 4:30 | 5 Shades + 2 Nightbolts | Attack-move to the Ember Hall |
| Stake raids | 30 s after each Ember Stake is planted | 3 Grave Hounds + 2 Shades | Attack-move to that stake; if it is gone, to the nearest Fire unit |
| W2 | The 2nd heart down (any side) | 6 Shades + 3 Nightbolts + 1 Shadow Knight | Attack-move to the Fire keep |
| The race | E10 (barrier down); march at +75 s | **Malrik (set to L5: + Shroud r2)** + 8 Shades + 3 Nightbolts + 1 Shadow Knight | Section "The race" |
| Warden tide | E11 until each gate falls | Each gate: 2 Ruin Wardens every **25 s** (max 8 alive per gate), team NEUTRAL, `neutral_leash` false | Attack-move to Vessa, refreshed every 3 s; they fight anything on the way (Shadow too) |
Drain squad Thralls that lose their heart (it died) walk to the next one in the order; Thralls never attack units (they flee
4 m when hit and resume). Shades of a squad whose Thralls are all dead attack-move to the nearest Fire stake, else go home.
After E11: every scripted Shadow unit and Malrik walk to the rally and hold it (they become guards with a 2x leash); the bot
defends only. The Warden tide still attacks them if they meet.

**The bot** (`ai.md`, profile `mission_03`: Shadow normal knobs, `min_attack_pop` 99, `worker_target_home` 4, no expansion,
no towers beyond S1, max 8 soldiers at the rally, `hire_champions` false, rule 5 off) gathers, trains and defends its camp.
The Commander ignores group `"scripted"` but still casts for Malrik (Shadow cast rules) while he holds the rally or leads the
race. Malrik defends his base from his anchor until E10.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Briefing (`c2_two_fronts` already played before the choice screen), then camera on Vessa; L1-L3 (+ L20 if Pell is here); hint `Hire champions at the Crooked Lantern. Find the Root Hearts in the fog before Malrik does.` (10 s) |
| E2 | 0:30 | Tavern opens; L4-L5; hint `Y: hire a champion. Champions choose their own jobs; bounty flags (R) pay them to do yours.` (10 s) |
| E3 | First hire | L6; `sec_champion` done; hint `R, then click the fog: an Explore flag. Explorers find the Root Hearts.` (10 s) |
| E4 | First heart explored (its cell seen by the player) | L7 |
| E5 | First drain squad unit seen by the player | L21; hint `Put a Hunt bounty on the drain squad (R, then click a Thrall).` (10 s) |
| E6 | A heart killed by the player | Ember Stake planted; `obj_hearts` count + flame icon; first time: L8 (Ysolde, voice only) + hint `Guard your Ember Stake (R, then click it): it shows you who is coming.` (10 s), `sec_stakes` appears; a stake raid in 30 s. A heart killed by Shadow: count + violet icon, message `Malrik's Thralls drained the Root Heart of <name>` (4 s) |
| E6b | The 2nd heart down (any side) | W2 |
| E7 | 6:00 | Old Mossjaw spawns (distant roar, minimap paw); L10; `sec_mossjaw` active |
| E8 | Mossjaw dies | L11; he drops a **Warden Scale** + a **Vital Root** at his feet; **+150 essence** to the player (whoever killed him); `sec_mossjaw` done |
| E9 | A Fire unit within 18 m of RH3 (first time) | L12 |
| E10 | All 3 hearts down | L13-L14; `sec_stakes` done if no stake fell; cutscene **`m3_oldroot`**; barrier gone + rebake; `obj_hearts` done, `obj_signet` active with the muster countdown; the race army spawns and musters |
| E10a | Muster ends (E10 + 75 s) | Message `Malrik marches on the Oldroot` (4 s); the race marches |
| E10b | Malrik takes the Signet | L19; objective sub-line `Kill Malrik before he gets home` + distance bar; Signet glow on Malrik |
| E10c (added) | Malrik dies while carrying | Signet drops after 3 s; L22; sub-line back to `Take the Master's Signet` |
| E11 | Vessa takes the Signet | Cutscene **`m3_plea`** -> **`m3_memory`** (VIDEO, fallback card) -> the Signet goes to artifact slot 2 for this mission (the M2 rule: replaces slot 2 if both are full); L15-L16; Malrik and every Shadow unit pull back (section "Waves"); WG1 / WG2 crack open (1 s, amber light); Warden tide starts; `obj_signet` done, `obj_gates` active; hint `The Wardens come for the Signet. Break both gates.` (8 s) |
| E12 | First gate destroyed | L17; its tide stops |
| E13 | Second gate destroyed | Remaining Wardens crumble (1 s, rubble puffs); cutscene **`m3_parting`**; `Events.mission_ended(true)` **3 s** after it ends |
| E14 | Vessa dies | L18; `obj_vessa` failed; defeat after 3 s |
| E15 | Fire keep destroyed, or Malrik within 8 m of the Dusk Keep with the Signet | Defeat after 3 s (`obj_signet` failed for the second) |

## Dialogue (22 ids, L9 unused; 5 s each unless listed)
Speaker colours (`story-episode-1.md` 2): Vessa `(1.0, 0.45, 0.1)`, Malrik `(0.7, 0.3, 1.0)`, Narrator `(0.9, 0.85, 0.7)`,
Pell `(0.85, 0.75, 0.5)`, **Bettany `(0.80, 0.65, 0.45)`, Ysolde `(0.55, 0.90, 0.35)`, Maelis `(0.60, 0.85, 0.50)`,
Whisper / Obren `(1.0, 0.80, 0.25)`**. Speaker ids are the `data/voice/cast.json` keys (all exist: `vessa`, `malrik`,
`narrator`, `pell`, `bettany`, `ysolde`, `maelis`, `whisper`, `obren` = alias of `whisper`). Display name `???` for
`whisper`, `Obren` from L15 on (19.U3).
| Line | Event | Speaker id | Text |
|---|---|---|---|
| L1 | E1 | `narrator` | The Sighing Wood has kept out of every quarrel for a hundred years. Today two armies walked in. |
| L2 | E1 | `vessa` | Malrik's already here. Of course he is. Then I'll borrow a forest. |
| L3 | E1 | `whisper` | The third one sleeps in the old tree. Wake it before he does. |
| L20 | E1, `m1_peddler_freed` | `pell` | A war! Terrible. Wonderful for business. Terrible. |
| L4 | E2 | `bettany` | The Crooked Lantern is open! Sellswords, cheap ale, no questions. First hire's on the house. |
| L5 | E2 | `vessa` | Sellswords who won't take orders. Perfect. I'll pay them to want what I want. |
| L6 | E3 | `bettany` | Mind the flags, Firelady. Coin on a flag is the only order that lot understands. |
| L7 | E4 | `vessa` | A heart made of roots, pumping green. That's the most Nature thing I have ever seen. |
| L21 | E5 | `vessa` | His Thralls are draining the hearts. If he opens that tree first, I lose it. |
| L8 | E6 (first) | `ysolde` | Fire and Shadow, burning my wood for a trinket. I will remember you both. |
| L10 | E7 | `narrator` | Old Mossjaw wakes in the Hollowfen, and he is hungry. |
| L11 | E8 | `vessa` | Somebody tell the sellswords their bounty's ready. And tell the bear I'm sorry. |
| L12 | E9 | `maelis` | Turn back, fire-child. The wolves already have your scent. |
| L13 | E10 | `ysolde` | Stop, both of you! You don't know what you're opening! |
| L14 | E10 | `vessa` | A tree. I'm opening a tree. Before HE does. |
| L19 | E10b | `malrik` | Mine. Thank you for the escort, little ember. |
| L22 (new) | E10c | `vessa` | Dropped something, Bishop? Finders keepers. (4 s) |
| L15 | E11 | `obren` | Three. Thank you, little ember. I'll take it from here. (6 s; first line under the name **Obren**) |
| L16 | E11 | `malrik` | Rubble with eyes. Your mess, Vessa. I'll be at my camp, enjoying the view. |
| L17 | E12 | `vessa` | One gate down. Stone breaks. Good to know. |
| L18 | E14 | `vessa` | Tell Malrik... he still dresses like a funeral. |
Plus the cutscene lines of `m3_plea`, `m3_memory` and `m3_parting` (`story-episode-1.md` 7.2, unchanged) and the champions' own
barks (`champions.md` 4.5). Lines never pause the game; queued lines wait (5 s each, the M1 queue).

## Cinematic hooks (`cinematics.md`; content in `story-episode-1.md` 7.2)
| Id | Kind / world mode | Trigger | Length | Actors / set-up before it plays | End state the mission must have after it (or after a skip) |
|---|---|---|---|---|---|
| `c2_two_fronts` | ENGINE stage | Before M3 (after M2's victory, before the choice screen) | 1:30 (1:20 without Pell) | Stage scene | Not part of M3; listed for order |
| `m3_oldroot` | ENGINE, PAUSE | E10, after L13-L14 start | 0:12 | Camera only | Barrier removed + rebake done; Signet glow visible at `(0, 1.6, 0)`; muster countdown starts **when control returns** |
| `m3_plea` | ENGINE, PAUSE | E11 | 0:40 | Ysolde = neutral, invulnerable story unit spawned at `(3, 0, -3)` (not in `"units"` targeting); Vessa snapped to the nearest navmesh point within 2.2 m of `(0, 0)` | Same black frame into `m3_memory` |
| `m3_memory` | **VIDEO** (later production) / fallback card 10 s | Right after `m3_plea` | 1:00 | - | Signet in Vessa's slot 2; Shadow units ordered home; gates cracked and spawning from the first second of control; Ysolde despawned (sinks into the roots, 1 s) |
| `m3_parting` | ENGINE, PAUSE | E13 | 0:40 | Ysolde teleported 3 m beside Vessa before the pause | Victory timer (3 s) starts when it ends |
| `c3_parley` | ENGINE stage | After M3's victory screen, before the M4 choice screen | 1:45 | Companion branch: `c3_parley` plays before the choice screen, so it shows the **first-hired living** champion (none if no champion lives) | Not part of M3 |
While a cinematic plays the mission clock pauses (`MissionBase.hold_world()`, 19.C2): the muster countdown, the wave timers and
the gate tides do not tick.

## Win / lose
| Event | Result |
|---|---|
| E13 (both gates down) + `m3_parting` | **Victory** (`Events.mission_ended(true)` 3 s after the cutscene) |
| Vessa dies | **Defeat** (instant loss, as missions 1-2) |
| Fire keep destroyed | **Defeat** |
| Malrik within 8 m of the Dusk Keep with the Signet | **Defeat** |
| Malrik killed (no Signet) | Not a win: `Malrik has fallen back into the shadows`; respawns at the Dusk Keep after **60 s**; before E10 he walks back to the rally, during the race he resumes it, after E11 he holds the rally |
| All hearts taken by Shadow | Not a loss by itself: the race still starts (the player has the muster window) |
| All Fire units dead, Vessa alive | Nothing |

## Reward carried to mission 4
- **Master's Signet** (`masters_signet`, already in `items.md` Campaign and `data/items/masters_signet.tres`: `max_hp` +100,
  `spell_power` +20, `cooldown_reduction` +10) owned; on the M4 choice screen equipped in slot 1 by default (crown slot 2, the
  orb stays owned): the 2-of-3 choice is real.
- **Companion** (`champions.md` 11): the choice screen lists the champions hired here (alive or fallen); one carried (items,
  purse 50 % cap 300, level 1).
- The 6 slots, essence 50 % cap 1 500, bonuses first: **+300 if `sec_stakes`**, **+150 if `sec_mossjaw`**.
- `CampaignState.MISSION_REWARDS[&"m03"] = {"artifact": "masters_signet", "flags": {"m3_mossjaw_slain": "sec_mossjaw",
  "m3_stakes_held": "sec_stakes", "m3_hired": "sec_champion"}, "bonus_essence": {"sec_stakes": 300, "sec_mossjaw": 150},
  "next": &"m04"}` (`m3_hired` added so M4 knows whether a companion can exist).
- Level not carried.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6; drain squads **2 Thralls** + 2 Shades | as written | x 1.4; race army + 1 Shadow Knight |
| Start crystals | 400 | 300 | 250 |
| Maelis | L3 | L3 | **L5** (Wild Stampede) |
| Old Mossjaw | Grizzlemaw variant A (2 600 HP) | Elder (B, 3 000) | Elder (B, 3 000), enrage below 40 % |
| Malrik (base / race) | L4 / L4 | L4 / L5 | L5 / L6 |
| Muster / carry speed | 90 s / 1.3 m/s (~41 s home) | 75 s / 1.6 m/s (~33 s) | 60 s / 2.0 m/s (~27 s) |
| Warden Gates | 1 400 HP, tide every 30 s | 1 800, 25 s | 2 200, 20 s |
| Expected time | 16-20 min | 20-25 min | 24-30 min |
**Fight sizing** (normal; every guarded fight <= 70 % of the army the player can have then; crystal values of the units):
| Fight | When | Enemy | Player army then | Ratio |
|---|---|---|---|---|
| G1 Mossgate | ~2:30-4:30 | 320 (3 Thornlings + 2 Burr Slingers) | 1 200 start army + Vessa L3 + 1 champion | 27 % (must leave **9+ of the 10** start soldiers) |
| W1 | 4:30 | 600 | ~1 450 | 41 % |
| Stake raid | ~5:30 | 370 | army near the stake + Guard champion | - |
| G2 Hollowfen | ~7:00-9:00 | ~670 (spire 540 HP + 6 units) | ~1 700 | 39 % |
| W2 | 2nd heart, ~8:30-10:00 | 1 040 | ~1 850 | 56 % |
| G3 Stagwatch | ~10:00-12:30 | ~1 050 (Maelis L3 + 2 wolves + 4 Thornlings; +2 summoned wolves 20 s) | ~2 000 + 2 champions | 52 % |
| Old Mossjaw (optional) | 6:00+ | ~1 500 (Elder) | ~2 200 at 11:00 | 68 % |
| The race | ~12:30-14:30 | 1 200 + Malrik L5 (~1 600) | ~2 400 | 67 % |
| Warden tide | 14:30-21:00 | 2 Wardens / 25 s per gate, max 16 alive | ~2 600 | peak ~74 % only if both gates are ignored for 3+ min |
- **If ignored** (the player never touches a heart and keeps the army home): RH3 falls to D2 ~9:30 (D1 softens G3), RH2 to
  D3 ~13:30 (Mossjaw roams there), RH1 to the 15:00 late drain ~16:30-17:30; barrier ~17:00, Malrik at the tree ~18:30, home
  ~19:00 = defeat. The race is therefore lost by default and won by taking 2 hearts before ~12:00.
- Skill check = **RH3** (Maelis + wolves): Hunt flags on Maelis with two champions plus the army; or Ash Hurlers (12 m) from
  outside her Thornsnare reach; or wait for D2 to soften her and take the heart after (the 3-way fight rewards timing).
- The Signet window: from E10 the player has **75 s + ~15 s** to reach `(0, 0)`; from anywhere on the Fire half Vessa needs
  10-15 s (4.6 m/s). Losing the race means a 33 s chase with Blaze Riders (7.5 m/s), which normal players should win.
- Champions and bounties cost essence: 75 (hire) + upkeep 6 / min each + flags 25-100. With ~1 300 essence earned in the
  mission plus the carry, two champions and steady flags still leave room for one mid item.

## Changes to the outline (`story-episode-1.md` 5.3; the owner applies them in 19.D3)
| # | Outline | This spec | Why |
|---|---|---|---|
| 1 | Hearth `(-36, 50)` | `(-50, 46)` (slot V1) | 4.5 m from node `m3_fire_b`: blocks the worker path |
| 2 | Pop 19 / 30 | **17 / 40** | Houses give +20 since 2026-09-27; the listed units are 17 pop |
| 3 | Race: Malrik "marches" at E10 | 75 s **muster**, then march | Without it Malrik reaches the tree in ~10 s, not the ~90 s fairness target |
| 4 | Carry: "walks home" | `move_speed` x 0.35 (1.6 m/s), defeat within 8 m of the Dusk Keep | A normal-speed walk home (~13 s) leaves no chase |
| 5 | Drain squads 3:00 / 7:00 / 11:00 only | + **late drains** every 240 s after 11:00 | Three squads cannot take G3 + G2 + G1 alone; without them an ignoring player stalls forever |
| 6 | - | L22 (Vessa, E10c), flag `m3_hired` | The drop needs a beat; M4 needs to know about the companion |
| 7 | Bramble Spire 540 HP | `nature_tower` (675) set to 540 | Kept the outline number |

## Code reuse (recommendation to the lead)
`MissionBase` (M9.S1 / 19.C2) for objectives, `_say`, `_after`, `_spawn_group` / `_scaled` / `_mark_scripted`, `_set_dormant`,
`_tick_guards`, `_order_wave` / `_refresh_waves`, `_raise_wizard`, the level cap, `_seal_flash`, `_end_game` + campaign save.
`RuinPeddler` for Pell, `LostCache` for the caches, the Ember Crown carry code (`EmberCrown` / `Artifact`) for the Signet's
carry and drop (an `Artifact` subclass `MasterSignetPickup`), the M2 snowbank / floe obstacle + rebake path for the thorn
barrier, `Tavern` (`open_time` export) and `ChampionGuild` (a `first_hire_crystals` override), `EpicBeast` for Mossjaw with
a fixed spawn and no respawn, `HelperType` `helper_maelis` spawned on team NEUTRAL with a 2x leash.

## Acceptance checks
1. `missions/mission_03.tscn` loads headless; the generator with seed 1303 places no tree or rock in any clearing above or in
   the lane; navmesh paths exist from `(-40, 40)` to each heart, each gate, the tavern door and the Shadow rally.
2. Before E10 no path reaches within 5 m of `(0, 0)`; after E10 a path reaches `(0, 2)` within 1 s of the wither.
3. A Root Heart regenerates 9 HP/s only after 10 s undamaged; 3 draining Thralls take a full heart in 75 s (+-2 s); the
   killing blow decides the credit; a player kill plants a 400 HP Ember Stake with sight 10.
4. Tavern opens at 0:30; the first hire costs 0 crystals + 75 essence; the bot never hires.
5. If ignored on normal, Malrik reaches `(0, 0)` 75-105 s after the barrier falls; carrying, he walks at 1.6 m/s; killed, the
   Signet drops after 3 s and Vessa can take it; reaching 8 m from the Dusk Keep with it = defeat.
6. E11 puts `masters_signet` in slot 2, pulls every Shadow unit back, opens both gates; each gate spawns 2 Wardens / 25 s,
   max 8 alive; E13 crumbles the rest and ends in victory 3 s after `m3_parting`.
7. Skipping any of the 4 in-mission cinematics leaves the same state as playing it (19.C9 test).
8. Victory saves `m03` with `MISSION_REWARDS[&"m03"]`: Signet owned, flags, +300 / +150 bonuses, companion candidates.
9. A scripted headless run on normal (hire, burn RH1 and RH2, let D2 take RH3 or burn it, win the race, both gates) ends
   `victory=true` in **20-25 game-minutes**; the G1 fight leaves >= 9 of 10 start soldiers in 5 / 5 runs; `PERF OK` with the
   16-cluster forest during a 60-unit fight.

## Done when (step 19 ids; the lead adds them to `waves.md`)
- [ ] M3.S1 (systems): `missions/mission_03.tscn` builds the Sighing Wood (seed 1303, 16 clusters, broadleaf only, clearings and
  positions above, nodes 1 500 / 1 500 / 2 000 / 1 500, Fire base pre-built incl. Hearth at `(-50, 46)`, Shadow camp, the one
  tavern opening at 0:30 with the free first hire); `RootHeart` (900 HP, regen, drain, credit, fog), `EmberStake`, thorn barrier
  (18 segments, wither + rebake), Warden Gates (shared with M4 / 19.C6 if it lands first); Pell / cache branch; start state via
  `apply_to_start` (L3 + 2 points, cap 7, 300 / 150 + carried, 17 of 40) and the no-save fallback; section "Tiers" (Hall copy
  with B / N, Kilnwarden, no Citadel); `tests/test_m3_map.gd` (checks 1-4). (Part of 19.C4.)
- [ ] M3.S2 (systems-high) **[H]**: objectives and events E1-E15 in order, guards G1-G3 + Mossjaw, waves (drains, late drains, W1,
  stake raids, W2, race with muster / march / carry / drop, Warden tide), Malrik's levels and 60 s respawn, win / lose table,
  difficulty table, the 22 line ids with the Pell branch; `tests/test_m3_race.gd` (check 5) and the scripted run (check 9).
  (Part of 19.C4.)
- [ ] M3.S3 (systems): victory saves `m03` (`MISSION_REWARDS[&"m03"]`, Signet, flags incl. `m3_hired`, bonuses), the companion
  candidates for the choice screen; the 4 cinematic hooks with their end states and skip test (check 7; the M3 part of 19.C9).
- [ ] M3.U1 (ui): briefing (3 paragraphs, objectives, the race line), `obj_hearts` counter with flame / eye credit icons, the
  muster countdown and the carry distance bar, hint circles on the minimap, Bettany / Ysolde / Maelis / Whisper -> Obren
  speakers (19.U3), Warden Gate HP bars; layout from ui-designer.
- [ ] M3.A1 (ai): profile `mission_03` (Shadow normal knobs, `min_attack_pop` 99, workers 4, no expansion, max 8 at `(30, -30)`,
  `hire_champions` false, defend only after E11); the Commander ignores `"scripted"` but casts for Malrik during the race;
  Maelis on team NEUTRAL uses her helper brain with a 2x leash (Hold home at RH3). (Part of 19.A1.)
- [ ] M3.V1 (tech-artist) **[H]**: the Sighing Wood kit of 19.V5: Oldroot (colossal oak, split trunk, Signet glow, 0 lights),
  thorn barrier segment + wither, Root Heart (healthy / drained grey-violet / burst), drain thread, Ember Stake, Warden Gate
  crack-open (19.V2), Signet carry tendrils on Malrik, forest light and fog preset (green-gold sun `(0.95, 0.92, 0.75)` 1.0,
  ambient `(0.45, 0.55, 0.40)`); `PERF OK` with the 16 clusters.
- [ ] M3.VO1 (voice, Voice Forge): render the 22 mission line ids (+ the 3 cutscene scripts) with the `cast.json` voices;
  every line fits its slot (5 s, L15 6 s, L22 4 s).
- [ ] M3.D1 (designer): read the lines in game once, trim any line longer than 2 lines of the dialogue box; write the
  "Changes to the outline" rows back into `story-episode-1.md` 5.3 (part of 19.D3).
- [ ] Lead: the scripted headless run of check 9 on normal ends `victory=true` in 20-25 game-minutes; the ignore run ends in
  defeat between 17:00 and 21:00; a save from mission 2 with `m1_peddler_freed` true and one with it false start mission 3
  with the right branch.

# Campaign mission 2: "The Orb Beneath the Ice" (Vessa vs Torvald)

Task 9.D1. Built in step 9 (ids M9.S1-M9.S3, M9.U1, M9.A1, M9.V1 at the end). Second Fire mission, first against
Ice; target **18-24 min** on normal. Uses the rules of `skirmish-1v1.md`, `levels.md`, `items.md`, `kingdom-ice.md`
(units, Torvald, statuses `chill` / `frozen`, Ice Wall) and the format of `mission-01.md`. New scene
`missions/mission_02.tscn` + `scripts/campaign/mission_02.gd` (`Mission02`, mission id `m02`, already listed in
`CampaignState.MISSION_SCENES`). Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `y = 0`,
`+z` = south. Angles `a` in degrees place a point at `(cos a * r, sin a * r)` (the pillar-ring convention of `mission_01.gd`):
45 = south-east, 135 = south-west, 225 = north-west, 315 = north-east.

## Story setup (briefing text, 3 short paragraphs)
1. The Ember Crown sits on Vessa's head and will not stop humming. It hums loudest toward the north, where the
   roads turn white and the rivers stop moving.
2. The Master's second relic, the **Stillwater Orb**, sank to the bottom of **Glasswater Mere**. Torvald of Ice froze
   the whole lake solid around it, and now his haulers are cutting down through the ice, one patient block at a time.
3. Torvald is old, slow and very sure of himself. Vessa is none of those things. Fire melts ice. Fire also cracks it.

## Map: "Glasswater Mere" (120 x 120, the `main.gd` generator, **not mirrored**, `MAP_SEED := 1202`)
Same generator as Emberfall (seeded clusters, lane from the Fire base to the Ice base, width 5), frozen theme
(M9.V1): **fir and pine only** (no broadleaf), rocks with snow caps, no tree or rock within **r 30** of `(0, 0)`.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / Fire keep | `(-36, 36)` / `(-43, 43)` | 18 | As mission 1 |
| Ember Hall (pre-built, complete) | `(-27, 45)` | 4 | As mission 1 |
| Node `m2_fire_a` / `m2_fire_b` | `(-46, 34)` / `(-34, 46)` | - | **1 500** each |
| Node `m2_west` (expansion) | `(-50, 10)` | 7 | **2 000**; hall spot `(-43, 12)` |
| Node `m2_south` (expansion) | `(4, 50)` | 7 | **1 500**; hall spot `(-3, 51)` |
| **Glasswater Mere** (frozen lake) | disc centre `(0, 0)`, **r 22** | - | Walkable ice; floes below. No building may be placed at r <= 23 |
| **Snowbank ridge** | ring r 25.5 around `(0, 0)` | - | 28 snowbanks, 4 gaps (below) |
| Shore gaps | centres at r 25.5, angles **135** SW `(-18, 18)`, **225** NW `(-18, -18)`, **45** SE `(18, 18)`, **315** NE `(18, -18)` | - | ~8 m wide; the lane runs through SW and NE |
| **The Heartfrost** (orb inside) | `(0, 0)` | - | 1 500 HP ice monolith, radius 1.5; see "Heartfrost" |
| Torvald's dig | ring r 3 around `(0, 0)` | - | 4 scripted Rime Haulers "dig" there |
| Frozen Emberguard **EG1 "West"** | `(-46, -14)` | 8 | Guard G2 |
| Frozen Emberguard **EG2 "South"** | `(24, 44)` | 8 | Guard G4 (neutral wardens) |
| Frozen Emberguard **EG3 "North"** | `(-14, -46)` | 8 | Guard G5 + a Rime Spire at `(-10, -41)` |
| Pell's cart spot | `(-32, 0)` | 6 | Branch on `m1_peddler_freed` (below) |
| Lost Caches | `(-12, 32)` and `(32, 10)` | 3 | `items.md` loot, appear at 2:00, reopen 180 s |
| **Sleeping Sentinels** | `(-26, 22)` and `(-22, 26)` | 3 | 2 Rime Colossi in ice shells beside the lane, **dormant** until E11 |
| Rime Keep (Torvald's base) | `(43, -43)` | 18 | Ice keep, 1 800 HP (`kingdom-ice.md` 5), shoots as any keep |
| Frost Hall / Rime Spire / Snow Lodge | `(27, -45)` / `(37, -29)` / `(50, -46)` | 4 / 3 / 4 | Bot slots H1 / S1 / V1 of `ai.md` (the mission 1 slots) |
| Ice nodes | `(46, -34)` / `(34, -46)` | - | 1 500 each |
| Ice rally | `(30, -30)` | - | Where the bot keeps its soldiers |
| Dusk raid entry (branch) | `(-56, -30)` | - | Map edge, only if `m1_outpost_burned` is false |

**Snowbank** (new prop, systems): a static box **5.0 long x 1.8 tall x 2.5 deep** (rounded look from M9.V1), layer 1,
group `"navigation_geometry"`, placed **tangent** to the ring at r 25.5 every **10 degrees** (centres 0, 10, ... 350),
**skipping** every centre within 10 degrees of a gap angle (40, 50, 130, 140, 220, 230, 310, 320). 36 - 8 = 28 banks.
Each gap is ~8 m wide. Test: a navmesh path from `(-40, 40)` to `(0, 0)` exists and passes within 5 m of the SW gap centre.

## Mechanic: thin ice (the floes of Glasswater Mere)
The lake is **Old Ice** (r <= 7, never breaks) plus **8 floes** `F0`-`F7` between r 7 and r 22. Floe `Fi` covers the
angles `[i x 45 - 22.5, i x 45 + 22.5)`: F3 (135, SW) and F7 (315, NE) carry the lane; F1 (SE) and F5 (NW) face the side gaps.
Each floe has **cracks** (float, 0 to 4). It **breaks at 4**.
| Crack source | Cracks | Credit (for kills when it breaks) |
|---|---|---|
| Fireball impact point on the floe | +1 | Vessa |
| Ember Step landing point on the floe | +1 (once per cast) | Vessa |
| Ash Hurler shot hitting a unit standing on the floe | +0.25 | Fire team |
| **Weight**: 12 or more pop of units on the floe at once (any team; wizards count 0) | +1 every 5 s while true | Nobody |
| Knitting: no new crack for 20 s | -1 every 20 s (floor 0) | - |
**Break** (in this order, one frame): every ground unit on the floe takes **80 damage** (wizards **40**; armor applies,
attacker = the credit above, nobody = no XP / essence) and `chill` **4 s**; it is moved to the nearest walkable point
outside the floe (the Ember Step closest-point rule); ground items on it move the same way; then the floe becomes
**open water**: a wedge obstacle (a `CollisionPolygon3D` prism, the arc sampled every 7.5 degrees) in group
`"navigation_geometry"`, and the navmesh rebakes (the same path as a new building). After **45 s** it refreezes:
obstacle removed, rebake, cracks 0. A floe cannot crack while it is open water.
Look (M9.V1): crack decal stages at 1 / 2 / 3 cracks, a 0.4 s white flash + 16 ice chunks on the break, open water
`(0.05, 0.15, 0.25)` with 6 floating chunks. The minimap draws open water as `(0.05, 0.15, 0.25)`.
Why: Fire's tool against a slow army. 4 Fireballs (160 mana) under a crossing Ice wave = 80 + chill on everything on
it, and the lane is cut for 45 s. The weight rule makes a big fight on the lake dangerous for **both** sides.

## Mechanic: blizzard
While a blizzard blows, the **player's** sight radii are **x 0.5** (floor 5 m); Ice units, buildings and the bot are
unaffected. Systems adds `FogOfWar.sight_scale: Array[float]` per team (default 1.0), applied in the stamp pass.
Look: snow particles following the camera and a white-blue world fog (M9.V1).
| Blizzard | When | Length |
|---|---|---|
| B1 | 11:00 (message `A blizzard is coming` at 10:50) | 45 s |
| B2 | From E11 (orb claimed) | Until the mission ends |

## The Heartfrost and Torvald's dig
- **Heartfrost**: a static target, radius 1.5, **1 500 HP**, team `NEUTRAL`, group `"scripted"`, not in `"units"` or
  `"buildings"` (no auto-aggro, not counted for defeat), always shown through the fog like the artifact. Only
  **Vessa** (attacks and spells) and **Ash Hurlers** damage it; a right-click on it by any other unit is a move order,
  and the first time it happens the message `Only fire melts the Heartfrost (Vessa, Ash Hurlers)` shows (4 s).
  It regenerates **15 HP/s** while any living Ice soldier or Torvald is within **10 m** of it. HP bar as a building's.
- **Dig**: from E2, `dig` rises by **0.02 % per second per working dig hauler** (max 4 count; a hauler works when it is
  alive within 5 m of the Heartfrost). 4 haulers from 2:00 = 100 % at about **22:50**. Relief: while fewer than 4 dig
  haulers live, the Rime Keep sends **1** new scripted Rime Hauler every **40 s** that walks to the dig ring
  (not scaled by difficulty). Dig haulers never join the Commander.
- Dig **100 %** = Torvald lifts the orb = defeat (E14). Messages at 50 / 75 / 90 %: `Torvald's dig: 50 %` (4 s).
- Look (M9.V1): the haulers play the gather animation facing the Heartfrost with ice-chip particles; a dig pit decal
  grows from r 1 to r 3 with `dig`; the Heartfrost shrinks in height from 100 % to 40 % with HP.

## Start state (from the campaign save)
Order in `_on_navigation_ready`: spawn Vessa -> `CampaignState.open(campaign_save_path).apply_to_start(self)` ->
read `get_meta(&"campaign_flags")` -> spawn the branch content (Pell or the cache, the Dusk raid timer).
| Item | Value |
|---|---|
| Artifacts | From the save: owned + the 2 equipped (normally Ember Crown in slot 1, slot 2 empty). The crown's modifier applies from 0:00 |
| Item slots | The 6 slots as saved (types + potion counts) |
| Essence | **150** + the carried essence (already 50 %, cap 1 500); +1 / s as the 1v1 |
| Vessa level | **Level rule: levels are never carried; each mission sets its start and cap.** Mission 2: **level 2** with **1 unspent spell point** (Fireball rank 1 known), **cap 6** |
| Crystals | 300 (easy 400, hard 250) |
| Buildings | Fire keep, Ember Hall (complete) |
| Units | 5 Cinder Hands gathering (3 on `m2_fire_a`, 2 on `m2_fire_b`); 4 Flame Guards, 2 Ember Archers, **2 Blaze Riders** at `(-32, 32)` |
| Population | 15 / 20 |
| No save / m01 not completed (menu debug, tests) | Ember Crown owned and equipped in slot 1 anyway, empty slots, essence 150 + **400**, both flags false |
| Torvald's side | Rime Keep, Frost Hall, Rime Spire, Snow Lodge; 4 Rime Haulers gathering; 4 Rimeshields at the rally; 4 dig haulers on the dig ring; Torvald (`scripts/units/ice_wizard.gd`) level **4** (Rime Bolt r2, Flash Freeze r1, Rime Aegis r1) at `(4, -4)` |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Hearth, Ember Hall, Ember Spire | - |
| Units | Cinder Hand, Flame Guard, Ember Archer, Blaze Rider, **Ash Hurler (new, V at the Ember Hall)** | - |
| Spells | Fireball, Ember Step (L2+), Kindle (L4+); cap L6 | - |
| Items | Base shop incl. the 4 Ice items (`kingdom-ice.md` 6); Pell's stock if he is here | Top items stay out of reach on purpose |

## Campaign flag branches
| Flag | True | False |
|---|---|---|
| `m1_peddler_freed` | **Pell** (a normal `RuinPeddler`, open at 0:00) stands at his frozen cart `(-32, 0)`. E3: L4a, and he drops a **Frostglass Shard** at his feet | The cart stands empty: it is a **Lost Cache** that can be opened at once (no 2:00 wait), then follows the cache rules. E3: L4b |
| `m1_outpost_burned` | 8:00: L6b only | 8:00: L6a and the **Dusk raid** (waves) |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_dig` | Primary (appears at E2) | `Stop Torvald's dig (37 %)` | Done at E10; **failed at 100 %** = defeat |
| `obj_heartfrost` | Primary | `Melt the Heartfrost (62 %)` (percent melted) | Heartfrost HP 0 |
| `obj_orb` | Primary (after `obj_heartfrost`) | `Claim the Stillwater Orb` | Vessa within 2.2 m of the orb (only Vessa can take it) |
| `obj_escape` | Primary (after `obj_orb`) | `Bring the orb home` | Vessa within **10 m** of the Fire keep |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `sec_emberguard` | Secondary | `Thaw the lost Emberguard (0 / 3)` | 3 ice blocks thawed |
| `sec_dig` | Secondary (appears at E2) | `Melt the Heartfrost before the dig reaches 50 %` | Done at E10 if `dig` < 50 %; **failed** the moment `dig` reaches 50 % |
States through `Events.objective_changed(id, state)` as mission 1. The briefing shows `obj_heartfrost`, `obj_orb`,
`obj_escape` and the rule `Vessa must survive`, plus the line `Torvald's haulers are digging. Do not let them reach the orb.`

**Frozen Emberguard** (reuse `MissionBrazier`, a subclass with its own look): Vessa within **3 m for 3 s** thaws it
(the brazier rule: progress ring, leaving resets). On thaw: the block fades in 1 s and **2 Flame Guards + 1 Ember
Archer** at veterancy **level 2** (`levels.md`) join the player beside it (they count toward pop and may exceed the
cap). After the 3rd: message `The Emberguard captain swears the Oath of Embers` (5 s) and **Oath of Embers**
(`oath_of_embers`, `items.md`) goes into Vessa's inventory, or on the ground at the block if full.

## Guards and scripted waves (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units are team `ENEMY` (wardens `NEUTRAL`), group `"scripted"`, never controlled by the Commander; guards hold
their spot with normal auto-aggro and a 2x leash (mission 1 rules).
| Group | Where | Units |
|---|---|---|
| G1 shore pickets | SW gap `(-19, 19)` | 2 Rimeshields + 1 Shardcaster |
| G2 west warders | EG1, ring r 2.5 around `(-44, -16)` | 2 Rimeshields + 2 Shardcasters |
| G3 dig guard | Heartfrost, ring r 6 | 3 Rimeshields + 2 Shardcasters + 2 Rime Seers; **Torvald** holds `(4, -4)` |
| G4 south wardens | EG2, ring r 3 | 3 Ruin Wardens (neutral, `balance-1.md` numbers) |
| G5 north watch | EG3 | 1 Rime Spire at `(-10, -41)` (720 HP, chill 2 s) + 2 Rimeshields |
| Sentinels | `(-26, 22)`, `(-22, 26)` | 2 Rime Colossi, **dormant** (mission 1 `_set_dormant`: no aggro, untargetable, no damage) until E11 |
| Wave | Trigger | Units (spawned at the Frost Hall spawn point; the Rime Keep's if the hall is gone) | Order |
|---|---|---|---|
| W1 | 5:00 | 3 Rimeshields + 2 Shardcasters | Attack-move to the Ember Hall (they cross the lake on the lane) |
| Dusk raid | 8:00, only if `m1_outpost_burned` is false | 3 Shades + 2 Nightbolts + 1 Grave Hound at `(-56, -30)` | Attack-move to the nearest Fire worker |
| W2 | 9:00 | 4 Rimeshields + 2 Shardcasters + 1 Rime Seer | Attack-move to the Fire keep |
| Relief | Every 40 s while < 4 dig haulers, until E10 | 1 Rime Hauler (not scaled) | Walk to its free spot on the dig ring |
| W3 | 15:00 or Heartfrost below 50 % HP, whichever is **earlier** | 3 Rimeshields + 2 Shardcasters + 1 Rime Colossus | Attack-move to the Heartfrost, then to Vessa |
| Pursuit | E11 | 4 Rimeshields + 3 Shardcasters + 1 Rime Seer at 0 s; 2 Rimeshields + 2 Shardcasters at 40 s; the Sentinels wake; Torvald joins (level 5: + Flash Freeze r2) | Attack-move to Vessa, refreshed every 3 s |
**Shore walls (E11)**: Torvald seals the SW, NW and SE gaps: at each, **2 rows of 5 Ice Walls** (500 HP each, normal
Ice Wall type, `counts_for_defeat` false, over the 16 cap), rows at r 24 and r 27, walls 2 m apart along the tangent,
centred on the gap line; snapped to `BuildGrid`, a cell already blocked is skipped. The NE gap (Ice side) stays open.
Test: after E11 no navmesh path leaves the lake through SW / NW / SE until a wall in both rows of that gap is destroyed.
The bot itself (`ai.md`, profile `mission_02`) gathers, trains and defends its base only.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Briefing, then camera on Vessa; L1-L2; hint `Ash Hurlers (V at the Ember Hall) melt ice. Fireballs crack it.` (10 s) |
| E2 | 2:00 | Dig starts; L3; `obj_dig` and `sec_dig` active |
| E3 | Vessa within 12 m of `(-32, 0)` (first time) | L4a + Frostglass Shard, or L4b (flag branch) |
| E4 | First Emberguard block thawed | L5; `sec_emberguard` 1 / 3 |
| E5 | Third block thawed | Oath of Embers given; `sec_emberguard` done |
| E6 | 8:00 | L6a + Dusk raid, or L6b |
| E7 | First floe breaks (any cause) | L7 |
| E8 | 10:50 / 11:00 | Blizzard warning, then B1 for 45 s |
| E9 | Vessa within 16 m of the Heartfrost (first time) | L8 |
| E10 | Heartfrost HP 0 | L9; the Heartfrost bursts (the mission 1 seal flash, colour `(0.75, 0.92, 1.00)`, r 12); the orb floats at `(0, 1, 0)`; `obj_heartfrost` and `obj_dig` done; `sec_dig` done if `dig` < 50 %; `obj_orb` active; living dig haulers walk to the Rime Keep |
| E11 | Orb claimed | L10; `obj_orb` done, `obj_escape` active; the orb goes to the free artifact slot (slot 2; if both are full it replaces slot 2 for this mission); B2 starts; shore walls rise; Sentinels wake (shells shatter); Pursuit; hint `Break through the ice walls and bring the orb home.` (8 s) |
| E12 | `obj_escape` done | L11-L12; living Ice units walk to the Rime Keep; `Events.mission_ended(true)` after 4 s |
| E13 | Vessa dies | L13; `obj_vessa` failed; defeat after 3 s |
| E14 | `dig` reaches 100 % | L14; `obj_dig` failed; defeat after 3 s |

## Dialogue (16 lines, 14 heard per run; 5 s each)
Speaker colours: Vessa `(1.0, 0.45, 0.1)`, **Torvald `(0.55, 0.80, 1.00)`**, Malrik `(0.7, 0.3, 1.0)`, Narrator
`(0.9, 0.85, 0.7)`, Pell `(0.85, 0.75, 0.5)`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | Narrator | Glasswater Mere has not thawed in a hundred winters. Something at the bottom still shines. |
| L2 | E1 | Vessa | Torvald froze an entire lake to guard one ball. That's not patience, that's a hobby. |
| L3 | E2 | Torvald | Little ember. My haulers cut a hand's depth of ice every hour. I have many hours. Do you? |
| L4a | E3, Pell freed | Pell | You again! My wheels froze to the road, so I suppose I'm open. Take this, it's on the house. The house is frozen too. |
| L4b | E3, Pell not freed | Vessa | Pell's cart, and no Pell. Maybe I should have opened that cage. Well. Finders keepers. |
| L5 | E4 | Vessa | Emberguard, on your feet! Stamp a bit. Your toes will come back. Probably. |
| L6a | E6, hall standing | Malrik | Torvald asked me for help. I said no, then sent some anyway. I do love a good view. |
| L6b | E6, hall burned | Malrik | I would send soldiers, Vessa, but someone burned my barracks. Very petty. I respect it. |
| L7 | E7 | Vessa | Thin ice! Ha! I am absolutely doing that again. |
| L8 | E9 | Torvald | You melt. I freeze. Let us see which of us is more stubborn, child. |
| L9 | E10 | Vessa | A hundred winters of ice, and it took me one afternoon. Somebody write that down. |
| L10 | E11 | Torvald | Take it, then. Now carry it home through my snow. |
| L11 | E12 | Torvald | Go. Keep it warm. The cold is patient, and so am I. |
| L12 | E12 | Narrator | Two of the Master's relics now answer to fire. The other apprentices stop pretending not to care. |
| L13 | E13 | Vessa | Too... cold... should have... brought a coat... |
| L14 | E14 | Torvald | Patience, little ember. It wins every time. |

## Win / lose
| Event | Result |
|---|---|
| `obj_escape` done | **Victory** |
| Vessa dies | **Defeat** (instant, as mission 1) |
| `dig` reaches 100 % | **Defeat** |
| Fire keep destroyed | **Defeat** (and `obj_escape` can no longer be done) |
| Torvald killed | Not a win: `Torvald has fallen, the frost will bring him back` (the `Skirmish.KINGDOMS` text); respawns at the Rime Keep after **60 s** and walks back to `(4, -4)` (before E11) or joins the Pursuit (after) |
| All Fire units dead, Vessa alive | Nothing |

## Reward carried to mission 3
- **Stillwater Orb** (new, add to `items.md` Campaign table): `stillwater_orb`, tier artifact, `is_artifact`,
  `campaign_only`, icon `SO`, glow `(0.60, 0.90, 1.00)`. Stats `max_mana` +60, `mana_regen` +1.5, `armor` +10.
  Passive **Stillwater**: `chill` and `frozen` on the wearer last **x 0.5** (after the wizard half rule, so frozen x 0.25).
  Tooltip `Stillwater Orb\n+60 mana · +1.5 mana regen · +10 armor\nStillwater: chill and freeze last half as long on you.\nArtifact (cannot be sold)`.
  Worn from E11 (so it already helps against the Pursuit's Flash Freeze). Owned artifacts after mission 2: crown + orb,
  both equipped by default, so mission 3's Master's Signet makes the 2-slot choice real.
- The 6 slots at victory (incl. Oath of Embers if earned); essence 50 %, cap 1 500, **+300 first if `sec_dig`**.
- `CampaignState.MISSION_REWARDS[&"m02"]` = `{"artifact": "stillwater_orb", "flags": {"m2_emberguard_sworn": "sec_emberguard",
  "m2_dig_under_half": "sec_dig"}, "bonus_essence": {"sec_dig": 300}, "next": &"m03"}`.
- Level not carried (the rule above).

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6, no Colossus in waves, 1 Sentinel | as written | x 1.4 |
| Start | 400 crystals | 300 | 250 |
| Dig rate per hauler | 0.015 %/s (~29:50) | 0.02 %/s (~22:50) | 0.025 %/s (~18:40) |
| Heartfrost HP / regen | 1 200 / 10 | 1 500 / 15 | 1 800 / 20 |
| Torvald start / at E11 | L3 (Rime Bolt r2, Flash Freeze r1) / L4 (+ Rime Aegis r1) | L4 / L5 (+ Flash Freeze r2) | L5 (+ Flash Freeze r2) / L6 (+ Flash Freeze r3) |
| Floe refreeze / blizzard sight | 60 s / x 0.6 | 45 s / x 0.5 | 30 s / x 0.4 |
| Expected time | 14-18 min | 18-24 min | 22-28 min |
- Fight sizing (every guarded fight <= 70 % of the army the player can have then, normal): G1 (310 crystals) vs the
  start army (920 + Vessa) must leave **7+ of the 8 soldiers**; G2 (420) at ~5:00 vs ~1 300; G4 = 3 wardens (900 HP,
  48 DPS) at ~8:00; G3 (760 + Torvald L4 + regen) at ~13:00-16:00 vs ~1 900.
- The intended Heartfrost answer: kill the Seers and Torvald's guard first (regen stops), 3-4 Ash Hurlers + Vessa on
  the ice (~60 DPS: 25 s), Fireball the dig ring (60 HP haulers). Vessa alone with no Hurler: ~22 DPS, ~70 s: possible, slow.
- The floe trap is strong but costs 160 mana and leaves Vessa dry for the next fight; the weight rule stops the
  player from parking a 20-pop ball on the lane.
- Ice cannot catch a running Fire army (4.2 vs 5.0+), so the escape is decided by the walls (1 000 HP per gap), the
  Sentinels on the SW exit (take NW or SE to dodge them) and the blizzard, not by a chase.

## Code reuse (recommendation to the lead)
`Mission01` already has everything generic: objectives API (`objectives()`, `objective_state()`, `briefing()`,
`_set_objective`), `_say` + `Events.dialogue`, `_after` timers, `_spawn_group` / `_scaled` / `_mark_scripted`,
`_set_dormant`, `_tick_guards`, `_order_wave` / `_refresh_waves`, `_raise_wizard`, the level cap, `_seal_flash`,
`_add_commander`, `_attach_mission_hud`, `_end_game` + campaign save. M9.S1 starts by moving those into
`scripts/campaign/mission_base.gd` (`MissionBase extends Skirmish`, tables such as `DIALOGUE`, `OBJ_ORDER`,
`SPEAKER_COLORS` become overridable vars) with **no behaviour change** for mission 1 (its headless tests still pass);
`Mission01` and `Mission02` extend it. `MissionBrazier` is reused for the ice blocks, `RuinPeddler` for Pell,
`LostCache` for the cart, the `Skirmish` kingdom table (`enemy_kingdom = &"ice"`) for Torvald and his respawn text.

## Done when (step 9 ids; the lead adds them to `waves.md`)
- [ ] M9.S1 (systems): `MissionBase` extracted, mission 1 tests still pass; `missions/mission_02.tscn` builds Glasswater Mere (seed 1202, nodes 1 500 / 1 500 / 2 000 / 1 500, lake disc r 22, 28 snowbanks with the 4 gaps and the path test, Ice base pre-built, clearings); Heartfrost (1 500 HP, damage only from Vessa and Ash Hurlers, regen 15 / s with Ice within 10 m); 3 ice blocks (3 m / 3 s, squads at veterancy 2); flag branches (Pell or the cart cache); Sentinels dormant; start state via `apply_to_start` (Vessa L2 + 1 point, cap 6, 300 / 150 + carried, 15 of 20) and the no-save fallback.
- [ ] M9.S2 (systems-high): floes F0-F7 (crack sources, weight 12 pop / 5 s, knitting, break at 4 with 80 / 40 damage + chill 4 s + displacement, wedge obstacle + rebake, refreeze 45 s, no building at r <= 23); `FogOfWar.sight_scale` per team and blizzards B1 / B2; the dig (0.02 % / s per working hauler, relief every 40 s, 50 / 75 / 90 % messages). Test: 4 Fireballs on F3 break it, a Rimeshield on it takes 70 and ends outside the hole, the lane path goes around it until it refreezes; `PERF OK` with a break during a 100-unit fight.
- [ ] M9.S3 (systems-high): objectives and events E1-E14 in order, the 16 lines with both flag branches, waves W1 / Dusk raid / W2 / Relief / W3 / Pursuit, shore walls at E11 (wall path test), Torvald's levels and 60 s respawn, win / lose table, difficulty table; victory saves `m02` with `MISSION_REWARDS[&"m02"]` (orb in owned + equipped, flags, +300 if `sec_dig`). Needs `data/items/stillwater_orb.tres` + the Stillwater passive (items-coder's files: the lead adds a small items task beside S3).
- [ ] M9.U1 (ui): briefing (3 paragraphs + 3 primary objectives + the dig line), objectives panel with the percent counters (`obj_dig` turns orange at 50 %, red at 75 %), Torvald's speaker colour, the Heartfrost HP bar, the blizzard warning; layout from ui-designer.
- [ ] M9.A1 (ai): profile `mission_02` (Ice normal knobs, `min_attack_pop` 99, workers 4, no expansion, no walls, max 8 soldiers at `(30, -30)`); the Commander ignores group `"scripted"` but still casts for Torvald with `kingdom-ice.md` 4.3 while he holds `(4, -4)` or follows the Pursuit.
- [ ] M9.V1 (tech-artist) **[H]**: frozen tileset and props: snow ground (`(0.88, 0.91, 0.96)`, lane packed snow `(0.70, 0.72, 0.76)`), lake ice shader (`(0.62, 0.80, 0.92)`, deep streaks `(0.35, 0.55, 0.75)`, faint floe seams), crack decals 1-3, open water + chunks, snowbank mesh, snow caps on fir / pine / rocks, Heartfrost (5 hex prisms, tallest r 1.2 h 5, `(0.70, 0.88, 1.00, 0.6)`, orb sphere r 0.4 `(0.60, 0.90, 1.00)` emission 3), Emberguard ice block (2.4 x 2.0 x 2.4 with 3 dim silhouettes), Sentinel shell + shatter (12 shards), dig pit decal, blizzard particles (400, box 40 x 20 x 40 on the camera) + fog; cold light (sun `(0.85, 0.92, 1.00)` 1.1, ambient `(0.55, 0.62, 0.75)`); `PERF OK`.
- [ ] Lead: a scripted headless run on normal (thaw 3 blocks, melt, claim, break a gap, reach the keep) ends `victory=true` in 18-24 game-minutes; the G1 fight leaves >= 7 of 8 start soldiers alive in 5 / 5 runs; a save from mission 1 with both flags true and one with both false each start mission 2 with the right branch.

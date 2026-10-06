# Campaign mission 2: "The Orb Beneath the Ice" (Vessa vs Malrik, on Torvald's lake)

Task 9.D1, **rewritten 2026-10-02 for the Episode 1 story** (task 19.D2, `story-episode-1.md` 5.2 rows 1-9,
`campaign-outline.md` 6 item 2). Built in step 9 (ids M9.S1-M9.S3, M9.I1, M9.U1, M9.A1, M9.V1, M9.O1 at the end; the
story hooks of step 19 are listed beside them). Episode 1 mission 2 of 5 ("First battles"), the second Fire mission,
**Fire against Shadow** on **neutral** ground: Torvald's lake. Target **18-24 min** on normal. Uses the rules of
`skirmish-1v1.md`, `levels.md`, `items.md`, `tiers.md` 6, `caster-units.md`, `kingdom-ice.md` (Ice Wall, Rime Colossus,
statuses `chill` / `frozen`) and the format of `mission-01.md`. New scene `missions/mission_02.tscn` +
`scripts/campaign/mission_02.gd` (`Mission02 extends MissionBase`, mission id `m02`, already listed in
`CampaignState.MISSION_SCENES`). Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `y = 0`,
`+z` = south. Angles `a` in degrees place a point at `(cos a * r, sin a * r)` (the pillar-ring convention of
`mission_01.gd`): 45 = south-east, 135 = south-west, 225 = north-west, 315 = north-east.

**M2 is not built yet** (2026-10-02: no `mission_02.gd`, no `MissionBase`), so M9.S1-S3 build this spec directly and the
re-skin task 19.C13 is dropped. What changed from the old Fire-vs-Ice spec (everything else is unchanged on purpose:
map, floes, thin ice, blizzard timing, Heartfrost HP, dig rate, Emberguard blocks, Pell branch, rewards):
| # | Old (Fire vs Ice) | Now (Fire vs Shadow, Torvald neutral) | Source |
|---|---|---|---|
| 1 | Torvald's Rime Keep base, Ice bot | **Malrik's dig expedition**: Dusk Keep (1 800 HP), Gloom Hall, Night Spire, Hovel in the same slots; `enemy_kingdom = &"shadow"`, bot profile `mission_02` = Shadow | ep1 5.2 #1 |
| 2 | Rime Hauler diggers | **Gloom Thralls** (same numbers, same relief) | #2 |
| 3 | Ice guards (Rimeshields, Shardcasters, Seers), Torvald at `(4, -4)` | Shadow guards; **Malrik** L4 holds `(4, -4)` | #3 |
| 4 | Heartfrost regen while Ice is near | Heartfrost NEUTRAL; regen **15 HP / s whenever no Fire unit has damaged it for 5 s** | #4 |
| 5 | Ice waves, Dusk raid branch | Shadow waves; the Dusk raid becomes Malrik's **reinforcements** | #5 |
| 6 | Sentinels, shore walls and blizzards were Ice weapons | **NEUTRAL** (Torvald's lake punishes both armies); blizzard sight x 0.5 for **both** teams | #6 |
| 7 | 16 lines | 19 lines: L2, L3, L6a, L6b, L8, L10, L11, L12, L14 rewritten, L15 Whisper, **L16-L17 Aldra** (her debut) | #7, `t3-helpers.md` Q1 |
| 8 | No cutscene | `m2_heartfrost` (E10, 0:10, PAUSE); `c1_offer` before, `c2_two_fronts` after | #8 |
| 9 | `MISSION_ORDER` `[m01, m02]` | `[m00, m01, m02, m03, m04]` (19.C2) | #9 |
| 10 | Fight sizing vs Ice | Re-checked vs Shadow units (section "Difficulty notes"); one new pacing rule: W2 waits while the reinforcements still live | `campaign-outline.md` 6 |

## Story setup (briefing text, 3 short paragraphs)
Plays after `c1_offer` (Torvald refused Malrik "for now"). Story mode: no pre-mission cinematic of its own.
1. The Ember Crown sits on Vessa's head and will not stop humming. It hums loudest toward the north, where the roads
   turn white and the rivers stop moving.
2. The Master's second relic, the **Stillwater Orb**, lies at the bottom of **Glasswater Mere**, sealed in Torvald's
   ice for a hundred winters. Torvald has closed his lake to both armies. Malrik came anyway: his diggers are cutting
   down through the ice, one patient block at a time.
3. Torvald will not fight for either side, but his lake fights everyone. Fire melts ice. Fire also cracks it.

## Map: "Glasswater Mere" (120 x 120, the `main.gd` generator, **not mirrored**, `MAP_SEED := 1202`)
Same generator as Emberfall (seeded clusters, lane from the Fire base to the Shadow camp, width 5), frozen theme
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
| **The Heartfrost** (orb inside) | `(0, 0)` | - | 1 500 HP NEUTRAL ice monolith, radius 1.5; see "Heartfrost" |
| Malrik's dig | ring r 3 around `(0, 0)` | - | 4 scripted Gloom Thralls "dig" there |
| Frozen Emberguard **EG1 "West"** | `(-46, -14)` | 8 | Guard G2 |
| Frozen Emberguard **EG2 "South"** | `(24, 44)` | 8 | Guard G4 (neutral wardens) |
| Frozen Emberguard **EG3 "North"** | `(-14, -46)` | 8 | Guard G5 + a Night Spire at `(-10, -41)` |
| Pell's cart spot | `(-32, 0)` | 6 | Branch on `m1_peddler_freed` (below) |
| Lost Caches | `(-12, 32)` and `(32, 10)` | 3 | `items.md` loot, appear at 2:00, reopen 180 s |
| **Sleeping Sentinels** | `(-26, 22)` and `(-22, 26)` | 3 | 2 Rime Colossi in ice shells beside the lane, **NEUTRAL**, **dormant** until E11 |
| **Glass Ridge** (Aldra's lookout) | outcrop `(-34, -26)` | 4 | Static rock outcrop 3 m tall (navigation geometry); Aldra stands on it at E11 only. 9 m from the NW gap line, 17 m from EG1, 16 m east of the reinforcement road |
| Dusk Keep (Malrik's expedition camp) | `(43, -43)` | 18 | Shadow keep, **1 800 HP** (an expedition keep, below the skirmish 2 500), shoots as any keep; tier 1 all mission |
| Gloom Hall / Night Spire / Hovel | `(27, -45)` / `(37, -29)` / `(50, -46)` | 4 / 3 / 4 | Bot slots H1 / S1 / V1 of `ai.md` (the mission 1 slots). Spire 750 HP |
| Shadow nodes | `(46, -34)` / `(34, -46)` | - | 1 500 each |
| Shadow rally | `(30, -30)` | - | Where the bot keeps its soldiers |
| Shadow road (reinforcement entry) | `(-56, -30)` | - | Map edge, only used if `m1_outpost_burned` is false |
| Fallback spawn corner | `(56, -56)` | 4 | Waves and Malrik's respawn when the Gloom Hall and the Dusk Keep are both gone |

**Snowbank** (new prop, systems): a static box **5.0 long x 1.8 tall x 2.5 deep** (rounded look from M9.V1), layer 1,
group `"navigation_geometry"`, placed **tangent** to the ring at r 25.5 every **10 degrees** (centres 0, 10, ... 350),
**skipping** every centre within 10 degrees of a gap angle (40, 50, 130, 140, 220, 230, 310, 320). 36 - 8 = 28 banks.
Each gap is ~8 m wide. Test: a navmesh path from `(-40, 40)` to `(0, 0)` exists and passes within 5 m of the SW gap centre.

## Mechanic: thin ice (the floes of Glasswater Mere)
Unchanged from the old spec. The lake is **Old Ice** (r <= 7, never breaks) plus **8 floes** `F0`-`F7` between r 7 and
r 22. Floe `Fi` covers the angles `[i x 45 - 22.5, i x 45 + 22.5)`: F3 (135, SW) and F7 (315, NE) carry the lane; F1
(SE) and F5 (NW) face the side gaps. Each floe has **cracks** (float, 0 to 4). It **breaks at 4**.
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
obstacle removed, rebake, cracks 0. A floe cannot crack while it is open water. Dig Thralls stand on Old Ice (r 3) and
are never hit by a break.
Look (M9.V1): crack decal stages at 1 / 2 / 3 cracks, a 0.4 s white flash + 16 ice chunks on the break, open water
`(0.05, 0.15, 0.25)` with 6 floating chunks. The minimap draws open water as `(0.05, 0.15, 0.25)`.
Why: Fire's tool against a bigger army. 4 Fireballs (160 mana) under a crossing Shadow wave = 80 + chill on everything
on it (a Shade has 110 HP, a Nightbolt 65: the Nightbolts die, the Shades limp), and the lane is cut for 45 s. The
weight rule makes a big fight on the lake dangerous for **both** sides (a Shadow Knight counts 3 pop).

## Mechanic: blizzard (Torvald's storms)
While a blizzard blows, **every team's** sight radii are **x 0.5** (floor 5 m): Torvald's storm does not take sides.
Systems adds `FogOfWar.sight_scale: Array[float]` per team (default 1.0), applied in the stamp pass; the mission sets
both `PLAYER` and `ENEMY`. Scripted waves keep their orders (attack-move targets are positions or units, not sight).
Look: snow particles following the camera and a white-blue world fog (M9.V1).
| Blizzard | When | Length |
|---|---|---|
| B1 | 11:00 (message `Torvald's storm is coming` at 10:50) | 45 s |
| B2 | From E11 (orb claimed) | Until the mission ends |

## The Heartfrost and Malrik's dig
- **Heartfrost** (Torvald's old ice): a static target, radius 1.5, **1 500 HP**, team `NEUTRAL`, group `"scripted"`,
  not in `"units"` or `"buildings"` (no auto-aggro, not counted for defeat), always shown through the fog like the
  artifact. Only **Vessa** (attacks and spells) and **Ash Hurlers** damage it; a right-click on it by any other unit is a
  move order, and the first time it happens the message `Only fire melts the Heartfrost (Vessa, Ash Hurlers)` shows
  (4 s). It **regenerates 15 HP / s whenever no Fire unit has damaged it for 5 s** (the ice heals itself; Shadow units
  never damage or heal it). HP bar as a building's.
- **Dig**: from E2, `dig` rises by **0.02 % per second per working dig Thrall** (max 4 count; a Thrall works when it is
  alive within 5 m of the Heartfrost). 4 Thralls from 2:00 = 100 % at about **22:50**. Relief: while fewer than 4 dig
  Thralls live, the Dusk Keep sends **1** new scripted Gloom Thrall (50 HP) every **40 s** that walks to its free spot
  on the dig ring (not scaled by difficulty). Dig Thralls never join the Commander. **Dusk Keep destroyed = no more
  relief** (the player's other answer to the dig; the keep is 1 800 HP behind the bot's 8 soldiers and the Night Spire).
- Dig **100 %** = Malrik lifts the orb = defeat (E14). Messages at 50 / 75 / 90 %: `Malrik's dig: 50 %` (4 s).
- Look (M9.V1): the Thralls play the gather animation facing the Heartfrost with ice-chip particles; a dig pit decal
  grows from r 1 to r 3 with `dig`; the Heartfrost shrinks in height from 100 % to 40 % with HP.

## Start state (from the campaign save)
Order in `_on_navigation_ready`: spawn Vessa -> `CampaignState.open(campaign_save_path).apply_to_start(self)` ->
read `get_meta(&"campaign_flags")` -> spawn the branch content (Pell or the cache, the reinforcement timer).
| Item | Value |
|---|---|
| Artifacts | From the save: owned + the 2 equipped (normally Ember Crown in slot 1, slot 2 empty). The crown's modifier applies from 0:00 |
| Item slots | The 6 slots as saved (types + potion counts) |
| Essence | **150** + the carried essence (already 50 %, cap 1 500); +1 / s as the 1v1 |
| Vessa level | Levels are never carried; each mission sets its start and cap. Mission 2: **level 2** with **1 unspent spell point** (Fireball rank 1 known), **cap 6** (ep1 4.1) |
| Crystals | 300 (easy 400, hard 250) |
| Buildings | Fire keep (tier 1), Ember Hall (complete) |
| Units | 5 Cinder Hands gathering (3 on `m2_fire_a`, 2 on `m2_fire_b`); 4 Flame Guards, 2 Ember Archers, **2 Blaze Riders** at `(-32, 32)` |
| Population | 15 / 20 |
| No save / m01 not completed (menu debug, tests) | Ember Crown owned and equipped in slot 1 anyway, empty slots, essence 150 + **400**, both flags false |
| Malrik's side | Dusk Keep, Gloom Hall, Night Spire, Hovel; 4 Gloom Thralls gathering; 4 Shades at the rally; 4 dig Thralls on the dig ring; Malrik (`scripts/units/shadow_wizard.gd`, the M1 Malrik) level **4** (Shadow Lance r2, Soul Siphon r1, Umbral Shroud r1) at `(4, -4)` |

## Economy
| Item | Value |
|---|---|
| Crystals | Start 300 (easy 400, hard 250); home nodes 2 x 1 500, expansions `m2_west` 2 000 (near EG1 and the Shadow road) and `m2_south` 1 500 (near EG2's wardens) |
| Pop | 15 / 20 at start; Hearths as the skirmish; Emberguard squads may exceed the cap |
| Essence | 150 + carried, +1 / s, kill income from `items.md` (Malrik counts as an enemy wizard); +300 at victory if `sec_dig` (before the 50 % cut) |
| Shops | Keep and Ember Hall (12 m), Pell if freed in M1 (open at 0:00) |
| Loot | 2 Lost Caches (2:00, reopen 180 s); Pell's cart cache when he is not here (open at once); Frostglass Shard from Pell (E3); Oath of Embers (`sec_emberguard`) |
| Spending pressure (the design) | ~3:30 the Stronghold (200, then tier-2 units) vs Ash Hurlers (140 each, the Heartfrost tool) vs an expansion; W1 lands at 5:00 |
| Malrik's bot | 4 Thralls on 2 x 1 500, trains to 8 soldiers at `(30, -30)`, never expands, never rebuilds the Gloom Hall |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Hearth, Ember Hall, Ember Spire | Citadel buildings |
| Units | Cinder Hand, Flame Guard, Ember Archer, Blaze Rider, **Ash Hurler (new, V at the Ember Hall)**; from the Stronghold: **Pyre Adept (B)**, **Cinder Arbalest (N)** at the Ember Hall, **Kilnwarden** (keep, B) | Tier-3 units (Ashveil Saboteur), Old Vey (helper; story: he is lost since M0) |
| Keep | **Stronghold** (X, 200 crystals, 60 s, from 3:30; section "Tiers") | Citadel (`campaign-outline.md` D7: from e2m1) |
| Spells | Fireball, Ember Step (L2+), Kindle (L4+); cap L6 | - |
| Items | Base shop incl. the 4 Ice items (`kingdom-ice.md` 6: it is Torvald's land); Pell's stock if he is here | Top items stay out of reach on purpose |
| Champions, tavern, bounty flags | - | Mission 3 (`champions.md` 11) |

## Tiers (2026-09-30, `tiers.md` 6; Episode 1 = Stronghold only)
As mission 1 "Tiers": `tiers_enabled = true` in `_init`, `tier_system.max_tier = 2`, `bots_upgrade = false` (Malrik's
Dusk Keep stays tier 1: no Hexweaver, Hollow Oathsworn or Gloom Deacon on his side), `casters_enabled = true` (the
Kilnwarden on the Fire keep, B). The Ember Hall copy lists Z Flame Guard, X Ember Archer, C Blaze Rider, V Ash Hurler,
**B Pyre Adept, N Cinder Arbalest** (greyed `Requires Stronghold` until then); the "+" upgrades open at the Stronghold.
The one-time message when the upgrade opens is the same as mission 1's. W1 lands at 5:00, the Stronghold at 4:30 at the
earliest: the player chooses between the upgrade and more Ash Hurlers for the Heartfrost. Why the caster earns its slot
here: Mana Scald drains Malrik (L4, ~40-60 mana per Scald) before the G3 fight; Slag Rain helps on the Shadow Knights
(armor) of W3 and the Pursuit.

## Campaign flag branches
| Flag (from M1) | True | False |
|---|---|---|
| `m1_peddler_freed` | **Pell** (a normal `RuinPeddler`, open at 0:00) stands at his frozen cart `(-32, 0)`. E3: L4a, and he drops a **Frostglass Shard** at his feet | The cart stands empty: it is a **Lost Cache** that can be opened at once (no 2:00 wait), then follows the cache rules. E3: L4b |
| `m1_outpost_burned` | 8:00: L6b only (Malrik brought fewer friends) | 8:00: L6a and the **reinforcements** (waves) |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_dig` | Primary (appears at E2) | `Stop Malrik's dig (37 %)` | Done at E10; **failed at 100 %** = defeat |
| `obj_heartfrost` | Primary | `Melt the Heartfrost (62 %)` (percent melted) | Heartfrost HP 0 |
| `obj_orb` | Primary (after `obj_heartfrost`) | `Claim the Stillwater Orb` | Vessa within 2.2 m of the orb (only Vessa can take it) |
| `obj_escape` | Primary (after `obj_orb`) | `Bring the orb home` | Vessa within **10 m** of the Fire keep |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `sec_emberguard` | Secondary | `Thaw the lost Emberguard (0 / 3)` | 3 ice blocks thawed |
| `sec_dig` | Secondary (appears at E2) | `Melt the Heartfrost before the dig reaches 50 %` | Done at E10 if `dig` < 50 %; **failed** the moment `dig` reaches 50 % |
States through `Events.objective_changed(id, state)` as mission 1. The briefing shows `obj_heartfrost`, `obj_orb`,
`obj_escape` and the rule `Vessa must survive`, plus the line `Malrik's diggers are cutting toward the orb. Do not let
them reach it.`

**Frozen Emberguard** (reuse `MissionBrazier`, a subclass with its own look): Fire scouts sent north before the war,
caught in Torvald's ice. Vessa within **3 m for 3 s** thaws it (the brazier rule: progress ring, leaving resets). On
thaw: the block fades in 1 s and **2 Flame Guards + 1 Ember Archer** at veterancy **level 2** (`levels.md`) join the
player beside it (they count toward pop and may exceed the cap). After the 3rd: message `The Emberguard captain swears
the Oath of Embers` (5 s) and **Oath of Embers** (`oath_of_embers`, `items.md`) goes into Vessa's inventory, or on the
ground at the block if full.

## Guards, waves and AI (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units are team `ENEMY` (Torvald's things and the wardens `NEUTRAL`), group `"scripted"`, never controlled by
the Commander; guards hold their spot with normal auto-aggro and a 2x leash (mission 1 rules). NEUTRAL units are the
enemy of both sides (`skirmish-1v1.md`): Malrik's waves fight them too.
| Group | Where | Units | Crystals |
|---|---|---|---|
| G1 shore pickets | SW gap `(-19, 19)` | 2 Shades + 1 Nightbolt | 260 |
| G2 west warders | EG1, ring r 2.5 around `(-44, -16)` | 2 Shades + 2 Nightbolts | 360 |
| G3 dig guard | Heartfrost, ring r 6 | 3 Shades + 2 Nightbolts + 1 Shadow Knight; **Malrik** (L4: Lance r2, Siphon r1, Shroud r1) holds `(4, -4)` | 700 + Malrik |
| G4 south wardens | EG2, ring r 3 | 3 Ruin Wardens (NEUTRAL, `balance-1.md` numbers) | - |
| G5 north watch | EG3 | 1 Night Spire at `(-10, -41)` (750 HP, the M1 Westwatch spire) + 2 Shades | 160 + spire |
| Sentinels | `(-26, 22)`, `(-22, 26)` | 2 Rime Colossi, **NEUTRAL**, **dormant** (mission 1 `_set_dormant`: no aggro, untargetable, no damage) until E11; then they fight anything within their 2x leash | - |

| Wave | Trigger | Units (spawned at the Gloom Hall spawn point; the Dusk Keep's if the hall is gone; `(56, -56)` if both are gone) | Order |
|---|---|---|---|
| W1 | 5:00 | 3 Shades + 2 Nightbolts | Attack-move to the Ember Hall (they cross the lake on the lane) |
| Reinforcements | 8:00, only if `m1_outpost_burned` is false | 3 Shades + 2 Nightbolts + 1 Grave Hound, spawned at the Shadow road `(-56, -30)` | Attack-move to the nearest Fire worker (a flank on the west, past EG1) |
| W2 | 9:00; **waits** (max 45 s) while 3+ reinforcement units still live | 4 Shades + 2 Nightbolts + 2 Grave Hounds | Attack-move to the Fire keep |
| Relief | Every 40 s while < 4 dig Thralls, until E10 or the Dusk Keep falls | 1 Gloom Thrall (not scaled) | Walk to its free spot on the dig ring |
| W3 | 15:00 or Heartfrost below 50 % HP, whichever is **earlier** | 3 Shades + 2 Nightbolts + 1 Shadow Knight | Attack-move to the Heartfrost, then to Vessa |
| Pursuit | E11 | 4 Shades + 3 Nightbolts + 1 Shadow Knight at 0 s; **Malrik** joins (level 5: + Siphon r2); 2 Shades + 2 Grave Hounds at 40 s | Attack-move to Vessa, refreshed every 3 s |
**Shore walls (E11)**: Torvald, through Aldra on the Glass Ridge, seals the SW, NW and SE gaps: at each, **2 rows of 5
Ice Walls** (500 HP each, normal Ice Wall type, team **NEUTRAL**, `counts_for_defeat` false, not under any wall cap),
rows at r 24 and r 27, walls 2 m apart along the tangent, centred on the gap line; snapped to `BuildGrid`, a cell already
blocked is skipped. The NE gap (toward Malrik's camp) stays open, so the Pursuit gets onto the lake and Vessa does not
get off it the short way. Neutral walls are attacked by both sides only when ordered or when they block a path (normal
building targeting; units prefer units). Test: after E11 no navmesh path leaves the lake through SW / NW / SE until a
wall in both rows of that gap is destroyed.
**The bot** (`ai.md`, profile `mission_02`: Shadow normal knobs, `min_attack_pop` 99 so it never launches its own
attacks, `worker_target_home` 4, no expansion, no towers beyond S1, keeps up to 8 soldiers at `(30, -30)`, never
rebuilds the Gloom Hall, `bots_upgrade` false) gathers, trains and defends its base only. The Commander ignores group
`"scripted"` but still casts for Malrik with his normal spell rules while he holds `(4, -4)` (G3) or follows the Pursuit.
Malrik leaves `(4, -4)` only at E11 (or to chase within his 2x leash of 12 m, then walks back).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Briefing, then camera on Vessa; L1-L2; hint `Ash Hurlers (V at the Ember Hall) melt ice. Fireballs crack it.` (10 s) |
| E2 | 2:00 | Dig starts; L3; `obj_dig` and `sec_dig` active |
| E3 | Vessa within 12 m of `(-32, 0)` (first time) | L4a + Frostglass Shard, or L4b (flag branch) |
| E4 | First Emberguard block thawed | L5; `sec_emberguard` 1 / 3 |
| E5 | Third block thawed | Oath of Embers given; `sec_emberguard` done |
| E6 | 8:00 | L6a + reinforcements, or L6b |
| E7 | First floe breaks (any cause) | L7 |
| E8 | 10:50 / 11:00 | Blizzard warning, then B1 for 45 s |
| E9 | Vessa within 16 m of the Heartfrost (first time) | L8 |
| E10 | Heartfrost HP 0 | Cutscene **`m2_heartfrost`** (section "Cinematic hooks"): L9; the Heartfrost bursts (the mission 1 seal flash, colour `(0.75, 0.92, 1.00)`, r 12); the orb floats at `(0, 1, 0)`. After it: `obj_heartfrost` and `obj_dig` done; `sec_dig` done if `dig` < 50 %; `obj_orb` active; living dig Thralls walk to the Dusk Keep |
| E11 | Orb claimed | L10, L15, L16; `obj_orb` done, `obj_escape` active; the orb goes to the free artifact slot (slot 2; if both are full it replaces slot 2 for this mission); B2 starts; **Aldra** appears on the Glass Ridge; shore walls rise; Sentinels wake (shells shatter); Pursuit; hint `Torvald's walls and Sentinels attack both armies. Break through and bring the orb home.` (8 s) |
| E11b | First gap opened (a wall down in both rows of one gap) | L17; Aldra fades from the ridge (1 s) if still there |
| E12 | `obj_escape` done | L11-L12; living Shadow units walk to the Dusk Keep (Sentinels go dormant again where they stand); `Events.mission_ended(true)` after 4 s; Story mode then plays `c2_two_fronts` |
| E13 | Vessa dies | L13; `obj_vessa` failed; defeat after 3 s |
| E14 | `dig` reaches 100 % | L14; `obj_dig` failed; defeat after 3 s |

**Aldra on the ridge** (E11, story actor, no gameplay): `aldra` actor (TH.V3 model, `t3-helpers.md` 1; fallback a 1.9 m
glass-teal placeholder figure with a staff) at `(-34, 3, -26)` facing the lake, team NEUTRAL, invulnerable,
untargetable, not in `"units"` / `"buildings"`, group `"scripted"`, always drawn through the fog and on the minimap as a
glass-teal dot `(0.62, 0.95, 0.88)` while she stands there. Gesture `raise_weapon` (staff up) as the walls rise:
glass-teal rune lines race from the ridge to the 3 sealed gaps and to the 2 Sentinels (1.5 s, VFX hook
`HelperVfx.play(&"aldra_sentinel", ...)` when TH.U2 exists, else a plain line mesh). She stays until E11b or 45 s,
then fades. The camera is never moved.

## Dialogue (19 lines, 17 heard per run; 5 s each unless listed)
Speaker ids as `Speakers.TABLE` / `data/voice/cast.json`. Colours: `vessa` `(1.0, 0.45, 0.1)`, `malrik`
`(0.7, 0.3, 1.0)`, `torvald` `(0.55, 0.80, 1.00)`, `narrator` `(0.9, 0.85, 0.7)`, `pell` `(0.85, 0.75, 0.5)`,
`whisper` `(1.0, 0.80, 0.25)` (shown as `???`), **`aldra` `(0.62, 0.95, 0.88)` (new in `Speakers.TABLE`, shown as
`Aldra`; voice already in `cast.json`)**. Torvald is a voice only all mission. Voice set:
`data/voice/lines/m02.json` (`{cine_id: "m02", lines: [{id, speaker, text, dur}]}`, read by Voice Forge).
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | `narrator` | Glasswater Mere has not thawed in a hundred winters. Something at the bottom still shines. |
| L2 | E1 | `vessa` | Malrik's diggers on Torvald's lake. Torvald must be thrilled. |
| L3 | E2 | `torvald` | Two children, fighting on my lake. Finish it quickly, and leave my ice alone. |
| L4a | E3, Pell freed | `pell` | You again! My wheels froze to the road, so I suppose I'm open. Take this, it's on the house. The house is frozen too. (6 s) |
| L4b | E3, Pell not freed | `vessa` | Pell's cart, and no Pell. Maybe I should have opened that cage. Well. Finders keepers. |
| L5 | E4 | `vessa` | Emberguard, on your feet! Stamp a bit. Your toes will come back. Probably. |
| L6a | E6, outpost standing | `malrik` | More diggers, more knives. You should have burned my hall when you had the chance. |
| L6b | E6, outpost burned | `malrik` | Someone burned my barracks, so I brought fewer friends. Very petty. I respect it. |
| L7 | E7 | `vessa` | Thin ice! Ha! I am absolutely doing that again. |
| L8 | E9 | `torvald` | That ice has kept a secret for a hundred winters, ember. Think before you melt it. |
| L9 | E10 (inside `m2_heartfrost`) | `vessa` | A hundred winters of ice, and it took me one afternoon. Somebody write that down. |
| L10 | E11 | `torvald` | So be it. My lake will see you out. Slowly. |
| L15 | E11, after L10 | `whisper` | Two. You're doing so well. (3 s) |
| L16 | E11, after L15 | `aldra` | Wake. We have guests. (3 s) |
| L17 | E11b | `aldra` | Through my glass already? Go, then. The mere remembers every footstep. |
| L11 | E12 | `torvald` | Run, little ember. Every relic you carry makes the Hollow hungrier. You will see. |
| L12 | E12 | `narrator` | Two relics answer to fire. In the north, Ice watches, and says nothing. |
| L13 | E13 | `vessa` | Too... cold... should have... brought a coat... |
| L14 | E14 | `malrik` | Patience was never my virtue. Luckily, I brought shovels. |
Line ids keep the ep1 numbering (L15 was added by ep1 5.2, L16-L17 here), so 19.C3 and Voice Forge never renumber.
Heard per run: 17 (one of L4a / L4b, one of L6a / L6b; L13 / L14 only on a defeat, L17 only if a gap is opened).

## Cinematic hooks
| Hook | When | Kind / length | What the mission does | Skip end state (19.C9 test) |
|---|---|---|---|---|
| `c1_offer` "The Offer" | Before the briefing (Story mode, StoryFlow; not on retries / the Missions list) | ENGINE stage, 1:20 | Nothing (it plays before the scene loads) | - |
| `m2_heartfrost` "A Hundred Winters" | E10 | ENGINE, **PAUSE**, 0:10 (ep1 7.2: 3 shots) | Calls `play_cutscene(&"m2_heartfrost")`; the cutscene's actions fire L9, the burst flash and the orb float; E10's objective changes run on `finished` | Heartfrost freed, orb at `(0, 1, 0)`, objectives as after E10, L9 queued once (never twice) |
| Aldra on the Glass Ridge | E11 | In-world beat, no camera takeover (the Pursuit is already moving) | Spawns the actor, rune lines, L16 | - |
| `c2_two_fronts` "One Front, Two Watchers" | After the victory screen (Story mode) | ENGINE stage, 1:30 (1:20 without Pell) | Nothing; StoryFlow reads `m1_peddler_freed` for shot 4 | - |
| `helper_aldra` Theatre reveal | Unlocked by the `m02` victory (TH.C1 reads `CampaignState` `completed`) | ENGINE stage, <= 0:45 (`t3-helpers.md` 10.3) | Nothing | - |
Before 19.C1 exists, `play_cutscene` falls back to the direct effects (the M1 `_seal_flash` path) so M2 is playable
without the cinematic player.

## Win / lose
| Event | Result |
|---|---|
| `obj_escape` done | **Victory** |
| Vessa dies | **Defeat** (instant, as mission 1) |
| `dig` reaches 100 % | **Defeat** |
| Fire keep destroyed | **Defeat** (and `obj_escape` can no longer be done) |
| Malrik killed | Not a win: `Malrik has fallen back into the shadows` (mission 1 text); respawns at the Dusk Keep (or `(56, -56)` if it is gone) after **60 s** and walks back to `(4, -4)` (before E11) or joins the Pursuit (after) |
| Dusk Keep destroyed | Not a win: relief Thralls stop; waves and Malrik's respawn move to `(56, -56)` |
| All Fire units dead, Vessa alive | Nothing |

## Reward carried to mission 3
- **Stillwater Orb** (already in `items.md` Campaign table; data file by M9.I1): `stillwater_orb`, tier artifact,
  `is_artifact`, `campaign_only`, icon `SO`, glow `(0.60, 0.90, 1.00)`. Stats `max_mana` +60, `mana_regen` +1.5,
  `armor` +10. Passive **Stillwater**: `chill` and `frozen` on the wearer last **x 0.5** (after the wizard half rule, so
  frozen x 0.25). Tooltip `Stillwater Orb\n+60 mana · +1.5 mana regen · +10 armor\nStillwater: chill and freeze last
  half as long on you.\nArtifact (cannot be sold)`. Worn from E11 (it already helps against floe-break chill and the
  Sentinels). Owned artifacts after mission 2: crown + orb, both equipped by default; mission 3's Master's Signet makes
  the 2-slot choice real. (Story: the Orb goes back to Torvald in Ep8, `campaign-outline.md` 4.1.)
- The 6 slots at victory (incl. Oath of Embers if earned); essence 50 %, cap 1 500, **+300 first if `sec_dig`**.
- `CampaignState.MISSION_REWARDS[&"m02"]` = `{"artifact": "stillwater_orb", "flags": {"m2_emberguard_sworn":
  "sec_emberguard", "m2_dig_under_half": "sec_dig"}, "bonus_essence": {"sec_dig": 300}, "next": &"m03"}` (unchanged).
- Level not carried (the rule above).

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6, no Shadow Knight in waves or G3, 1 Sentinel | as written | x 1.4 |
| Start | 400 crystals | 300 | 250 |
| Dig rate per Thrall | 0.015 %/s (~29:50) | 0.02 %/s (~22:50) | 0.025 %/s (~18:40) |
| Heartfrost HP / regen | 1 200 / 10 | 1 500 / 15 | 1 800 / 20 |
| Malrik start / at E11 | L3 (Lance r2, Siphon r1) / L4 (+ Shroud r1) | L4 (Lance r2, Siphon r1, Shroud r1) / L5 (+ Siphon r2) | L5 (+ Siphon r2) / L6 (+ Lance r3) |
| Floe refreeze / blizzard sight | 60 s / x 0.6 | 45 s / x 0.5 | 30 s / x 0.4 |
| Expected time | 14-18 min | 18-24 min | 22-28 min |
- Fight sizing vs Shadow (every guarded fight <= 70 % of the army the player can have then, normal; a wizard counts
  ~350 crystals at L1, ~500 at L4, ~550 at L5, `levels.md`): G1 (260) vs the start army (920 + Vessa) must leave **7+
  of the 8 soldiers** (28 %); G2 (360) at ~5:00 vs ~1 300 (28 %); W1 (440) at 5:00 vs ~1 300 (34 %); G4 = 3 wardens
  (900 HP, 48 DPS) at ~8:00; reinforcements (510) at 8:00 vs ~1 500 (34 %); W2 (660) at 9:00 vs ~1 600 (41 %): the two
  together would be 73 %, hence the W2 wait rule; G5 (spire + 160) ~9:00-12:00; G3 (700 + Malrik L4 ~500 = ~1 200)
  at ~13:00-16:00 vs ~1 900 (**63 %**, the skill check); W3 (700) vs ~1 900 (37 %).
- The intended Heartfrost answer: break G3 first (Fireball the Nightbolts, Kilnwarden Scald on Malrik, soldiers on the
  Knight), then 3-4 Ash Hurlers + Vessa on the ice (~60 DPS: 25 s, no regen while they keep firing), Fireball the dig
  ring (50 HP Thralls: one rank-1 Fireball each). Vessa alone with no Hurler: ~22 DPS, ~70 s: possible, slow, and any
  5 s pause (Ember Step away, a fight) lets it heal.
- The floe trap is strong but costs 160 mana and leaves Vessa dry for the next fight; the weight rule stops the
  player from parking a 20-pop ball on the lane, and stops Malrik's W3 + Knight from crossing as one block.
- The escape is no longer slow-army-vs-fast-army: Shades (4.8) and Nightbolts (5.0) keep pace with Flame Guards (5.0)
  and the 40 s Grave Hounds (7.0) catch stragglers; Blaze Riders (7.5) are the rear guard. It is decided by the walls
  (1 000 HP per gap), the NEUTRAL Sentinels on the SW exit (they hit both armies: lead the Pursuit into them, or take NW
  / SE to dodge them), a floe break on F7 behind Vessa (cuts the Pursuit for 45 s) and the blizzard (x 0.5 for both).
  The Pursuit (~1 430 at 0 s, + 300 at 40 s) is a running fight, not a guarded one: standing on the lake loses.

## Code reuse (recommendation to the lead)
`Mission01` already has everything generic: objectives API (`objectives()`, `objective_state()`, `briefing()`,
`_set_objective`), `_say` + `Events.dialogue`, `_after` timers, `_spawn_group` / `_scaled` / `_mark_scripted`,
`_set_dormant`, `_tick_guards`, `_order_wave` / `_refresh_waves`, `_raise_wizard`, the level cap, `_seal_flash`,
`_add_commander`, `_attach_mission_hud`, `_end_game` + campaign save. M9.S1 starts by moving those into
`scripts/campaign/mission_base.gd` (`MissionBase extends Skirmish`, tables such as `DIALOGUE`, `OBJ_ORDER`,
`SPEAKER_COLORS` become overridable vars) with **no behaviour change** for mission 1 (its headless tests still pass);
`Mission01` and `Mission02` extend it (19.C2 reuses the same class: whoever lands first extracts it, the other only
adds `hold_world()`). `MissionBrazier` is reused for the ice blocks, `RuinPeddler` for Pell, `LostCache` for the cart,
the `Skirmish` kingdom table (`enemy_kingdom = &"shadow"`) for Malrik and his respawn text, M1's Malrik setup for his
levels, and the Ice Wall `BuildingType` / Rime Colossus `UnitType` for Torvald's NEUTRAL walls and Sentinels.

## Acceptance checks
- [ ] Map: seed 1202; 28 snowbanks, 4 gaps, the SW path test; nodes 1 500 / 1 500 / 2 000 / 1 500; no building at
  r <= 23; every position in the map table lies on walkable ground outside the lake (except the Heartfrost and the dig).
- [ ] Teams: Dusk Keep and every wave / guard are `ENEMY` Shadow; Heartfrost, Sentinels, shore walls, wardens and Aldra
  are `NEUTRAL`; no Ice unit or building is `ENEMY` anywhere in the scene.
- [ ] Heartfrost: Shadow units never damage it; a Flame Guard's right-click is a move + the one-time message; regen
  starts exactly 5 s after the last Fire damage and stops on the next hit.
- [ ] Dig: 4 Thralls from 2:00 reach 100 % at 22:50 +- 5 s with no player input; relief 1 Thrall / 40 s; none after
  the Dusk Keep falls.
- [ ] Floes: 4 Fireballs on F3 break it; a Shade on it takes 80 and ends outside the hole; the lane path goes around it
  until it refreezes 45 s later.
- [ ] Blizzard: during B1 both teams' sight radii are halved (floor 5 m); B2 from E11 to the end.
- [ ] W2 starts at 9:00, or up to 45 s later while 3+ reinforcement units live.
- [ ] E11: walls rise at SW / NW / SE only (wall path test), both Sentinels wake NEUTRAL and attack a Shade within their
  leash, Aldra appears and L16 plays; E11b fires L17 once.
- [ ] Dialogue: every line id above is logged exactly once per run when its event fires (branch lines per flag); every
  speaker id is in `Speakers.TABLE` and `cast.json`.
- [ ] `m2_heartfrost` skip leaves the same state as a full play (19.C9).
- [ ] Victory saves `m02` with `MISSION_REWARDS[&"m02"]` (orb owned + equipped, flags, +300 if `sec_dig`); a save from
  mission 1 with both flags true and one with both false each start mission 2 with the right branch.
- [ ] Timing: a scripted headless run on normal (thaw 3 blocks, melt, claim, open a gap, reach the keep) ends
  `victory=true` in 18-24 game-minutes; the G1 fight leaves >= 7 of 8 start soldiers alive in 5 / 5 runs.
- [ ] `PERF OK` with a floe break during a 100-unit fight; smoke test still `victory=true`; mission 1 tests still pass.

## Done when (step 9 ids + step 19 hooks; the lead adds them to `waves.md`)
- [ ] M9.S1 (systems): `MissionBase` extracted (or reused from 19.C2), mission 1 tests still pass; `missions/mission_02.tscn` builds Glasswater Mere (seed 1202, nodes, lake disc r 22, 28 snowbanks with the 4 gaps and the path test, Glass Ridge outcrop, Malrik's camp pre-built with a 1 800 HP Dusk Keep, clearings); Heartfrost (NEUTRAL, 1 500 HP, damage only from Vessa and Ash Hurlers, regen 15 / s after 5 s without Fire damage); 3 ice blocks (3 m / 3 s, squads at veterancy 2); flag branches (Pell or the cart cache); NEUTRAL Sentinels dormant; start state via `apply_to_start` (Vessa L2 + 1 point, cap 6, 300 / 150 + carried, 15 of 20) and the no-save fallback; section "Tiers" (Stronghold only, the Hall copy with V / B / N, Kilnwarden on B; `tests/test_tier_path.gd` gets a mission 2 part).
- [ ] M9.S2 (systems-high): floes F0-F7 (crack sources, weight 12 pop / 5 s, knitting, break at 4 with 80 / 40 damage + chill 4 s + displacement, wedge obstacle + rebake, refreeze 45 s, no building at r <= 23); `FogOfWar.sight_scale` per team and blizzards B1 / B2 on **both** teams; the dig (0.02 % / s per working Thrall, relief every 40 s, stops with the Dusk Keep, 50 / 75 / 90 % messages). Test: the floe and dig checks above; `PERF OK` with a break during a 100-unit fight.
- [ ] M9.S3 (systems-high): objectives and events E1-E14 + E11b in order, the 19 lines with both flag branches, waves W1 / reinforcements / W2 (wait rule) / Relief / W3 / Pursuit, NEUTRAL shore walls at E11 (wall path test), Aldra's ridge actor, Malrik's levels, anchor and 60 s respawn (incl. the `(56, -56)` fallback), `play_cutscene(&"m2_heartfrost")` with the direct-effect fallback, win / lose table, difficulty table; victory saves `m02` with `MISSION_REWARDS[&"m02"]`.
- [ ] M9.I1 (items-coder): `data/items/stillwater_orb.tres` + the Stillwater passive (x 0.5 on `chill` / `frozen`, after the wizard half rule). `oath_of_embers` and `frostglass_shard` already exist.
- [ ] M9.U1 (ui): briefing (3 paragraphs + 3 primary objectives + the dig line), objectives panel with the percent counters (`obj_dig` turns orange at 50 %, red at 75 %), the Heartfrost HP bar, the blizzard warning, `&"aldra": ["Aldra", Color(0.62, 0.95, 0.88)]` in `Speakers.TABLE` (19.U3 owns the file if it lands first), Aldra's minimap dot; layout from ui-designer.
- [ ] M9.A1 (ai, part of 19.A1): profile `mission_02` (Shadow normal knobs, `min_attack_pop` 99, workers 4, no expansion, no extra towers, max 8 soldiers at `(30, -30)`, never rebuilds the Gloom Hall); the Commander ignores group `"scripted"` but casts for Malrik (M1 rules) while he holds `(4, -4)` or follows the Pursuit.
- [ ] M9.V1 (tech-artist) **[H]**: frozen tileset and props: snow ground (`(0.88, 0.91, 0.96)`, lane packed snow `(0.70, 0.72, 0.76)`), lake ice shader (`(0.62, 0.80, 0.92)`, deep streaks `(0.35, 0.55, 0.75)`, faint floe seams), crack decals 1-3, open water + chunks, snowbank mesh, snow caps on fir / pine / rocks, Heartfrost (5 hex prisms, tallest r 1.2 h 5, `(0.70, 0.88, 1.00, 0.6)`, orb sphere r 0.4 `(0.60, 0.90, 1.00)` emission 3), Emberguard ice block (2.4 x 2.0 x 2.4 with 3 dim silhouettes), Sentinel shell + shatter (12 shards, glass-teal rune glints), dig pit decal, Glass Ridge outcrop (snow-capped, 3 m), the Shadow camp in snow (snow caps on the Shadow buildings, violet tent dressing), blizzard particles (400, box 40 x 20 x 40 on the camera) + fog; cold light (sun `(0.85, 0.92, 1.00)` 1.1, ambient `(0.55, 0.62, 0.75)`); 0 new lights; `PERF OK`.
- [ ] M9.O1 (Voice Forge agent): `data/voice/lines/m02.json` with the 19 lines; render; every WAV fits its slot (5 s, or the listed 3 / 6 s).
- [ ] Step 19 hooks (owners there): 19.C9 wires `m2_heartfrost` (shot list ep1 7.2) with the skip test; 19.C8 builds `c2_two_fronts`; 19.C2 puts `m02` in `MISSION_ORDER` `[m00 .. m04]`; TH.C1 unlocks `helper_aldra` on the `m02` victory. 19.C13 is not needed (M2 is built from this spec).
- [ ] Lead: the "Timing" and save checks of "Acceptance checks" pass; playtest after M0 + M1 + M2 in Story mode.

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Ash Hurler.
- **Why here:** only Vessa and Hurlers damage the Heartfrost; hits crack floes; range 12 > Night Spire 11; a static dig camp; Lab 8 / 41 / 4 (exempt siege: it needs exactly this job).
- **Moment:** W1 (5:00) on floe F2: "Ash Hurlers crack the ice: shell the floe under them.".
- **Intro card:** `Ash Hurler. Slow, far, and it melts what swords can't: ice, towers, camps.`

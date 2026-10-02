# Campaign mission e6m1: "A Hundred Winters" (Torvald + young Aldra vs the Hollow's Wardens; Episode 6)

Written 2026-10-02 (`campaign-outline.md` 3.6, row 1). Episode 6 "The Lake and the Seed" (origins), mission 1 of 4, the
first mission the player plays as **Torvald** and the first Ice mission of the story. It plays right after `ep6_opening`
(~3:00, its own doc `episode6-opening.md`, not written here). Target **16-20 min** on normal. Uses `skirmish-1v1.md`,
`levels.md`, `items.md`, `tiers.md` 6, `kingdom-ice.md`, `t3-helpers.md` 4.4 (Aldra's kit), `caster-units.md` 5.2 (Rime
Bulwark), `mission-02.md` (the same lake: map table, floes, blizzard, Heartfrost) and the format of `mission-01.md` /
`mission-e3-01.md`. New scene `missions/mission_e6_01.tscn` + `scripts/campaign/mission_e6_01.gd` (`MissionE601 extends
MissionBase`, mission id `e6m1`, campaign-outline D6). Metres, seconds, `m:ss` since the navmesh was ready (held cinematic
time excluded); positions `(x, z)`, `y = 0`, `+z` = south. Status: **design only**; recommended option taken everywhere.

## 0. Episode 6 rules (shared by `mission-e6-01.md` ... `mission-e6-04.md`; the other three point here)
| # | Point | Decision | Why |
|---|---|---|---|
| ER1 | When each mission happens (years before Episode 1) | **e6m1 a hundred winters ago** (the winter after the Master sealed Obren) · **e6m2 forty winters ago** · **e6m3 thirty-two winters ago** · **e6m4 twelve years ago** (the vanishing). Each briefing opens on its year | The outline says "decades ago" for e6m1; the canon lines say the Heartfrost "has not thawed in a hundred winters" and the Orb was "sealed in Torvald's ice for a hundred winters" (`mission-02.md` L1, L8, briefing; `t3-helpers.md` 1). A hundred winters is the reading that breaks none of them. e6m3 follows `ep4_opening` L2-L6 (born the year nothing grew; found by the Master; "for twenty years, until he was gone" = 32 years ago). e6m4 is outline D5 (twelve years) |
| ER2 | How Torvald and Aldra are there a century ago | People bound to the Master's gifts **age slowly**: Old Vey was a grown swordsman when Obren was sealed (ep1 V2 shot 3) and looks seventy today; Torvald (the eldest) and Aldra (who takes the warden's oath here) are the same. Aldra looks ~20 in e6m1, ~40 in e6m2, "in her fifties" today (`t3-helpers.md` 1). The Master says it once (e6m1 L25: "The ice keeps its wardens") | Keeps the outline's "young Aldra" and the helper's age; no new lore beyond one line |
| ER3 | What carries | **Nothing** (outline D8: origins are the past). Each mission sets its own start (level, crystals, essence 400, empty slots, no artifact). Saved: completion + flags only (`e6m1_sentinels`, `e6m2_gate_opened`, `e6m2_town_saved`, `e6m2_saved_count`, `e6m3_all_gardens`, `e6m3_whitepelt`, `e6m4_seal_unbroken`). Ep8's Ice road reads `e6m2_town_saved` (outline 4.2) | Outline D8 and 4.2 |
| ER4 | Tiers and casters | **Tier 1 only** in e6m1-e6m3 (`tiers_enabled = true`, `max_tier = 1`, `casters_enabled = false`); **Stronghold** in e6m4 (`max_tier = 2`, Bramblesage on). The Rimecarver keeps its debut in e7m1; young Aldra's story kit **borrows Rime Bulwark** (she is the first rime-carver) so the player meets the spell here | Outline 3.5 ("origins: small armies, tier 1, low caps", same spirit as Ep5) and 3.7 (Ice kit + Rimecarver are e7m1's "new"); e4m1 already taught the Bramblesage |
| ER5 | Helpers, champions, trade, map-fill | `helpers_enabled = false`, `tavern_enabled`, `trade_enabled`, `camps_enabled`, `beasts_enabled`, `points_enabled` false. Aldra (e6m1, e6m2) and Maelis (e6m3) are **story units** that reuse the helper models / VFX / ability code with story numbers (`t3-helpers.md` 3 "Missions"); **the Master** is a story actor (the prologue stand-in, `prologue-3min.md` B6: very tall, hooded, beard of white-gold light, hem burning in four colours; invulnerable, never targeted) | `t3-helpers.md` 3; outline C3 (helpers become callable in their own episode: Aldra e7m2, Maelis e4m2) |
| ER6 | The enemy | **The Hollow's Ruin Wardens** (Obren reaching for his keys) in e6m1, e6m2 and e6m4; **frost wolves** in e6m3. One new story enemy shared by three missions: **Warden Breaker** (`warden_breaker`, below). No enemy wizard, no enemy Commander: every enemy unit is mission-spawned (group `"scripted"`) | The four kingdoms were at peace; the Hollow is the one thing that attacks a wizard in the Master's age, and it explains why the Orb's lake, Torvald's gate and the isle all draw Wardens |
| ER7 | Speakers | Existing `data/voice/cast.json` ids: `narrator`, `master`, `torvald`, `aldra`, `obren` (alias of `whisper`, shown **Obren**: the player knows him since Ep1; Torvald does not), `ysolde`, `maelis`. **One new id** in e6m2: `rider` (Bren of Hearthwick) | Minimal cast change |
| ER8 | Frame | Ep6 is what Torvald and Ysolde remember during the winter truce (ep4 ending). Short present-day **between-scenes** (`c_e6_lake`, `c_e6_gate`, `c_e6_seed`, ~0:40 ENGINE each) link the missions; `ep6_opening` / `ep6_ending` belong to `episode6-opening.md` | Outline 3.4 ending, 3.6; 5.1 budget (Ep6: 8 min of film) |

**Warden Breaker** (`warden_breaker`, gameplay; story enemy, never trained): the Ruin Warden model at **x1.5** with amber
cracks glowing through the stone (tech-artist variant). 900 HP, armor 15, 30 damage, range 1.8, cooldown 1.4, speed 3.6,
aggro 9, **x2 damage vs buildings and scripted targets** (the Heartfrost, the Frostgate, the Throne seal), `pop` 4 (so
Snagroot cannot pull it, `caster-units.md` 5.3), kill XP 150, essence as a 330-crystal unit. Named elite of the same type:
**the Stair-Breaker** (e6m1) / **the Gate-Breaker** (e6m2): 2 400 HP, 40 damage, scale x1.8, a boss bar. Ruin Warden
numbers are the existing `data/units/ruin_warden.tres` (300 HP, 16 damage, cooldown 1.0, 4.0 m/s).

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map | **Glasswater Mere**, `mission-02.md`'s map at 1:1 (seed 1202, lake disc r 22, 28 snowbanks, 4 gaps, floes F0-F7, Glass Ridge, Sentinel stones): the same lake a hundred winters earlier, without Fire's base or Malrik's camp | The film and M2 show this lake; reusing it is free and every M2 position is already checked |
| D2 | Torvald's camp | His first Rime Keep stands on the **south-west shore**, in M2's Fire keep slot `(-43, 43)` | A checked clearing r 18 with two 1 500 nodes; the Wardens come from the north-east, the far side |
| D3 | What attacks | Wardens climb out of three **amber cracks** (the Hollow's north stair) and walk to the Heartfrost. Three winters = three wave sets; two short thaws between them | Outline: "hold the lake through 3 winters (3 waves, blizzards)" |
| D4 | The floes | M2's floe rules, turned around: "**the ice holds under his army and cracks under theirs**" (`prologue-3min.md` S22). Wardens are heavy and stone does not swim | The lake is Torvald's weapon, as it was Vessa's trap in M2 |
| D5 | The Sentinels | Young Aldra **carves** the two Sleeping Sentinels of M2 here (secondary): each is a Rime Colossus that fights for Torvald, then sleeps in its ice shell at victory | M2's NEUTRAL Sentinels and the `helper_aldra` Theatre reveal ("Wake it only if they cross." / "They always cross.") get their origin |
| D6 | The Heartfrost | The Master brings it (the Stillwater Orb sealed in a block of deep ice) and leaves it with Torvald: "my coldest secret" (`prologue-3min.md` L24) | Outline: "the Master leaves him the Heartfrost"; matches M2's "sealed in Torvald's ice for a hundred winters" |

## Story setup (briefing text, 3 short paragraphs; shown after `ep6_opening`)
1. A hundred winters ago. The Master has just sealed something under Crown Hollow, and the four kingdoms are new. The
   north belongs to his eldest apprentice, Torvald, who has a keep, a lake, and no great love of visitors.
2. Tonight the Master walks out onto the lake with a block of blue ice in his arms. Something inside it shines. He asks
   Torvald to keep it cold until he comes back for it, and warns him that something will come for it every winter.
3. A fisher girl from the Stillwater huts has followed him onto the ice and will not go home. Her name is Aldra. Three
   winters are coming. Keep the Heartfrost.

## Map: "Glasswater Mere, a hundred winters ago" (120 x 120, `main.gd` generator, not mirrored, `MAP_SEED := 1202`)
Every row not listed is **absent** (no Fire keep or hall, no Dusk Keep / Gloom Hall / Night Spire / Hovel / Shadow nodes,
no Emberguard blocks, no Pell cart, no dig). Frozen theme of M9.V1 (fir and pine only, snow caps, no tree or rock within
r 30 of `(0, 0)`).
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Torvald) / Aldra | `(-36, 36)` / `(-34, 38)` | 18 (keep) | As M2's start |
| **Rime Keep** (player, tier 1) | `(-43, 43)` | 18 | 3 000 HP (`tiers.md` 1 Ice T1) |
| Frost Hall (pre-built, complete) | `(-27, 45)` | 4 | M2's Ember Hall slot |
| Node `e6_ice_a` / `e6_ice_b` | `(-46, 34)` / `(-34, 46)` | - | **1 500** each |
| Node `e6_west` (expansion) | `(-50, 10)` | 7 | **2 000**; hall spot `(-43, 12)` (M2 `m2_west`) |
| Node `e6_south` (expansion) | `(4, 50)` | 7 | **1 500**; hall spot `(-3, 51)` |
| **Glasswater Mere** | disc `(0, 0)`, r 22 | - | Walkable ice, Old Ice r <= 7, floes F0-F7 (M2); no building at r <= 23 |
| Snowbank ridge, 4 gaps | ring r 25.5; gaps SW `(-18, 18)`, NW `(-18, -18)`, SE `(18, 18)`, NE `(18, -18)` | - | M2 unchanged (28 banks) |
| **The Heartfrost** | `(0, 0)` | - | Appears at E1 (the Master sets it down); see "The Heartfrost" |
| **Stillwater longhouse** (Aldra's village) | `(24, 44)` | 8 | M2's EG2 spot. A Snow Lodge copy `stillwater_lodge` (team PLAYER, **800 HP**, +20 pop, `counts_for_defeat` false) + 4 fisher huts (decor, no collider beyond 1.5 m) on a ring r 5 |
| **Sentinel stones** S1 / S2 | `(-26, 22)` / `(-22, 26)` | 3 | M2's Sleeping Sentinel spots: two 3 m rune-scored ice boulders (carving targets, D5) |
| Glass Ridge | `(-34, -26)` | 4 | M2 outcrop (decor here) |
| Lost Caches | `(-12, 32)`, `(32, 10)` | 3 | `items.md` loot, appear at 2:00, reopen 180 s |
| **Amber crack `stair_ne`** | `(43, -43)` | 18 | M2's Dusk Keep clearing: a 6 m amber fissure (decal + glow, 19.V4 crack kit), the main spawn |
| **Amber crack `road_w`** | `(-56, -30)` | 6 | M2's Shadow road (map edge), opens in winter 2 |
| **Amber crack `barrow_n`** | `(-14, -46)` | 8 | M2's EG3 spot, opens in winter 3 |
| Shore spawn `shore_e` | `(58, 20)` | 6 | East edge path for the thaw raids on the longhouse |
| Torvald's rally (suggested) | `(-20, 20)` | - | Just inside the SW gap |
Paths (navmesh): `stair_ne` -> NE gap 36 m -> Heartfrost 26 m; `road_w` -> NW gap 40 m; `barrow_n` -> NW gap 29 m; Rime
Keep -> SW gap 35 m -> Heartfrost 26 m; `shore_e` -> longhouse 42 m. The Wardens always cross a floe (F7 from the NE gap,
F5 from the NW gap): the lake is where the fights happen.

## The Heartfrost (scripted target, systems)
M2's Heartfrost object with these changes: team **PLAYER**, group `"scripted"`, not in `"units"` / `"buildings"`,
**2 000 HP**, radius 1.5, always visible; attackable by ENEMY units only (scripted waves are ordered onto it; Breakers deal
x2). **Regen 10 HP / s** while Torvald stands within 8 m **and** no enemy is within 8 m. HP 0 = defeat (E15). HP bar as a
building's; minimap blue diamond. Look: M9.V1's Heartfrost (5 hex prisms, the orb inside, emission 3), plus a faint
blue pulse every 2 s while it regenerates.

## Mechanic: the floes in Torvald's hands (M2 floes; only the rows below change)
| Rule | e6m1 value |
|---|---|
| Weight | Only **ENEMY** units weigh: Ruin Warden **2**, Warden Breaker **4**. **8 or more** enemy weight on one floe -> **+1 crack every 4 s** |
| Rime Bolt | Hitting an enemy that stands on a floe: **+1 crack** on that floe (credit Torvald) |
| Flash Freeze | Centred on a floe and freezing at least one enemy there: **+1 crack** (credit Torvald). Centred on **open water**: the floe **refreezes at once** (cracks 0; units are never inside open water) |
| Knitting | -1 crack every 20 s without a new crack (M2) |
| Break (at 4) | **Ruin Wardens and Warden Breakers on the floe sink**: they die (XP and essence to Torvald's team; the named elite takes **600** damage instead and is displaced). Other enemy units: 80 damage + `chill` 4 s + displaced (M2). **PLAYER units on it are displaced with no damage** ("the ice holds under his army") |
| Open water | 45 s, then refreezes (M2); wedge obstacle + navmesh rebake as M2 |
Message the first time a floe has 2 cracks: `The ice is cracking under the Wardens. Rime Bolt and Flash Freeze crack it
further: stone does not swim.` (8 s).

## Mechanic: winters and thaws
| Season | Time (normal) | Effect |
|---|---|---|
| Autumn | 0:00-2:30 | Build up |
| **Winter 1** | 2:30-6:00 | Blizzard: **PLAYER** sight x 0.6 (floor 5 m; `FogOfWar.sight_scale`, M9.S2), every ENEMY unit `move_speed` -0.4 m/s (modifier `season:drift`); snow particles + white-blue fog (M9.V1) |
| Thaw 1 | 6:00-8:30 | Clear, cold light; the raid on the longhouse |
| **Winter 2** | 8:30-13:00 | Blizzard as winter 1; `road_w` opens |
| Thaw 2 | 13:00-15:00 | Clear |
| **Winter 3** ("the long night") | 15:00 until W3c is dead (max 20:00) | Blizzard; night light preset (the M0 moonlight); `barrow_n` opens |
Each season change shows a 4 s message (`Winter comes.` / `The thaw.`) and fades the light over 6 s. The objectives
panel shows `Winter 2 of 3` / `Thaw: winter in 1:12`.

## Start state
| Item | Value |
|---|---|
| Torvald | **Level 2**: Rime Bolt r1 known + **1 unspent spell point** (Flash Freeze), **cap 5**; full HP / mana (L2: 470 HP, 17 dmg, 110 mana) |
| Aldra (young) | Story unit `aldra_young` at `(-34, 38)` (see below) |
| Crystals / essence | 300 / **400** (essence +1 / s) |
| Buildings | Rime Keep (tier 1), Frost Hall (complete), the Stillwater longhouse (complete, +20) |
| Units | 5 Rime Haulers gathering (3 on `e6_ice_a`, 2 on `e6_ice_b`); **4 Rimeshields + 2 Shardcasters** at `(-32, 32)` |
| Population | 11 / 40 (keep 20 + longhouse 20); Snow Lodges **max 3 including the longhouse** this mission (cap 80) |
| Inventory | 6 empty slots, no artifact (ER3) |
| Fog | On; the lake disc and the 4 gaps explored from 0:00 |

## Unlocks (what exists in this mission)
| Kind | Available | Locked (comes later) |
|---|---|---|
| Buildings | Snow Lodge (Z), Frost Hall (X), Rime Spire (C), **Ice Wall (V, max 16)** | Stables, Bazaar; any tier 2+ building |
| Units | Rime Hauler (keep Z); Frost Hall **Z Rimeshield, X Shardcaster, C Rime Seer, N Rimeling** | V Rime Colossus (the Sentinels are this winter's giants; e6m2), B Frostbow (e6m2), every tier-2 unit, the Rimecarver (e7m1) |
| Keep | No tier button (`max_tier = 1`; the tier chip reads `Tier 1 Keep`, no next step) | Stronghold (e6m4 / e7m1) |
| Spells | Rime Bolt (L1), Flash Freeze (L2+), Rime Aegis (L4+); cap L5 | - |
| Items | Base shop (Rime Keep, Frost Hall, 12 m): components, mids, the 4 Ice items (`kingdom-ice.md` 6), potions, Homeward Seal | Top items stay out of reach (~2 300 essence max) |
| Helpers / champions / casters | - | Aldra callable from e7m2 |

### Young Aldra (story unit `aldra_young`, ER5)
Team PLAYER, **not commandable** (`is_commandable()` false; click = read-only inspect card, no stance buttons). Model: the
TH.V3 Aldra (`t3-helpers.md` 1) with the **young look**: ~20, hair loose under a fur hood, fisher's oilskin instead of the
white felt coat, a bone chisel instead of the crystal staff, no glass hauberk yet (tech-artist variant `set_look(&"young")`).
| Stat | Value |
|---|---|
| HP / armor / damage / range / cooldown / speed | 420 / 5 / 14 / 9.0 (glass shard, 24 m/s) / 1.3 / 4.4 |
| **Rime Bulwark** (from `caster-units.md` 5.2, no mana) | Cooldown **16 s**. Autocast: 3+ enemies within 10 m walking toward the Heartfrost or Torvald -> a 4 m wall 3 m in front of the nearest, perpendicular to their path; 8 s; the same shatter rule (pop >= 3: Breakers shatter it in 1 s) |
| **Shatterglass** (`t3-helpers.md` 4.4 at x0.8) | Cooldown 11 s: a 12 m line, 1.5 m wide, **40** damage to up to 6 enemies; autocast on 3+ in a line |
| Brain | Escort Torvald (3-7 m) with the R2 flee rule (under 25 % HP to the keep, rest 2 % / s). **Carving** (below) overrides it |
| Falls | At 0 HP: body fades, line L28b once (`aldra`: "Cracked. Not broken."), back at the keep door after **40 s** at full HP. Never a loss |
**Carving a Sentinel** (`sec_sentinels`): when Torvald stands within **8 m** of an uncarved Sentinel stone and no enemy is
within 12 m of it, Aldra walks to it and carves (channel **25 s**, progress ring on the stone, chips of glass-teal light;
paused, not reset, while an enemy is within 12 m or she is fleeing). Done: the shell cracks and a **Sentinel** stands up:
a Rime Colossus (`rime_colossus.tres`, level 1, team PLAYER, **commandable**, pop **0**, name `Sentinel`, glass-teal rune
glints on its back). Max 2. If a Sentinel dies it is gone (the stone stays broken).

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_winters` | Primary | `Keep the Heartfrost through three winters (Winter 1 of 3)` | Winter 3 ends (W3c dead, or 20:00) |
| `obj_heartfrost` | Primary, always shown | `The Heartfrost must not fall` (HP bar) | Fails = defeat |
| `obj_torvald` | Primary, always shown | `Torvald must survive` | Fails = defeat |
| `sec_sentinels` | Secondary (appears at E5, thaw 1) | `Help Aldra carve the Sentinels (0 / 2)` | Both carved |
| `sec_longhouse` | Secondary | `Keep the Stillwater longhouse standing` | It stands at victory; **failed** if destroyed |
States through `Events.objective_changed(id, state)`.

## Waves and the Wardens (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
No guards: the lake is empty when the mission starts. Every wave unit is team ENEMY, group `"scripted"`, spawned at the
named crack (rising out of it in 1.5 s, amber dust) and ordered: **attack-move to the Heartfrost**; within 10 m of it they
attack it; they fight what attacks them (normal auto-aggro, aggro 9). Raids attack-move to the longhouse instead.
| Wave | Time | Units | Spawn | Order |
|---|---|---|---|---|
| W1a | 3:00 | 3 Ruin Wardens | `stair_ne` | Heartfrost |
| W1b | 4:30 | 4 Ruin Wardens | `stair_ne` | Heartfrost |
| Raid 1 | 7:00 | 2 Ruin Wardens | `shore_e` | Longhouse, then the Heartfrost |
| W2a | 9:00 | 5 Ruin Wardens | `stair_ne` | Heartfrost |
| W2b | 10:30 | 4 Ruin Wardens | `road_w` | Heartfrost (via the NW gap) |
| W2c | 12:00 | 5 Ruin Wardens + **1 Warden Breaker** | `stair_ne` | Heartfrost |
| Raid 2 | 13:45 | 3 Ruin Wardens | `shore_e` | Longhouse, then the Heartfrost |
| W3a | 15:30 | 5 Ruin Wardens (`stair_ne`) + 4 Ruin Wardens (`road_w`) | two cracks | Heartfrost |
| W3b | 17:00 | 6 Ruin Wardens + **2 Warden Breakers** | `barrow_n` | Heartfrost |
| W3c | 18:15 | **The Stair-Breaker** + 5 Ruin Wardens | `stair_ne` | Heartfrost; the Stair-Breaker's boss bar appears |
Winter 3 ends the moment W3c's last unit dies (or at 20:00 if the player only holds). Units of earlier waves still alive
then crumble to rubble in 2 s (no XP).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cutscene `e6m1_heartfrost` (0:30, HOLD): the Master sets the Heartfrost down, L1-L7. After it: hint `Keep the Heartfrost alive through three winters. Wardens come from the cracks in the north-east. Ice Walls (V) can close a gap.` (10 s) |
| E2 | 2:30 | Winter 1; L8 |
| E3 | W1a first seen by the player | L9-L10 |
| E4 | First floe breaks | L11-L12; floe hint (if not shown yet) |
| E5 | 6:00 | Thaw 1; L13; `sec_sentinels` active; hint `Walk Torvald to a Sentinel stone (south-west shore): Aldra will carve it while no enemy is near.` (10 s) |
| E6 | First Sentinel carved | L14-L16 |
| E7 | 8:30 | Winter 2; `road_w` opens (crack decal grows in 2 s); L17 |
| E8 | W2c spawns | L18 |
| E9 | 13:00 | Thaw 2; message only |
| E10 | 15:00 | Winter 3 (night); `barrow_n` opens; L19 |
| E11 | W3c spawns | L20-L21 |
| E12 | Winter 3 ends | Cutscene `e6m1_return` (0:40, HOLD): L22-L27; the Sentinels walk to their stones and sleep in ice shells; victory at its end |
| E13 | Longhouse destroyed | L29; `sec_longhouse` failed |
| E14 | Torvald dies | L28; `obj_torvald` failed; defeat after 3 s |
| E15 | Heartfrost HP 0 | L30; `obj_heartfrost` failed; defeat after 3 s |
| E16 | Aldra falls (first time) | L28b |

## Dialogue (31 lines; 5 s each unless listed; every line <= 96 characters)
Speaker colours: `torvald` `(0.55, 0.80, 1.00)`, `aldra` `(0.62, 0.95, 0.88)`, `master` `(0.95, 0.93, 0.85)`, `obren`
`(1.0, 0.80, 0.25)`, `narrator` `(0.9, 0.85, 0.7)`. Voice file `data/voice/lines/e6m1.json` (the `m00.json` format).
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | A hundred winters ago, the lake had no name, and the north had one keeper. |
| L2 | E1 | master | Keep this cold, Torvald. Keep it until I come back for it. |
| L3 | E1 | torvald | What is it? |
| L4 | E1 | master | A promise I made to a stone. Something will come for it. Every winter. (6 s) |
| L5 | E1 | aldra | My lord? The ice is singing. Can you hear it? |
| L6 | E1 | torvald | Go home, girl. Winter is coming, and it is bringing guests. |
| L7 | E1 | aldra | This is my home. I'll stay, if it's all the same to you. |
| L8 | E2 | narrator | The first winter came down from the north, and it did not come alone. |
| L9 | E3 | obren | That is my key, frost-man. I made the lock. Give it back. |
| L10 | E3 | torvald | A talking stone. Wonderful. I was hoping for a quiet century. |
| L11 | E4 | torvald | The ice holds for us, and not for them. Remember that, girl. |
| L12 | E4 | aldra | Aldra. My name is Aldra. And I will remember. |
| L13 | E5 | narrator | Spring came late to the lake, and stayed only a little while. |
| L14 | E6 | aldra | Wake. We have guests. (3 s) |
| L15 | E6 | torvald | You carved a giant out of my lake. |
| L16 | E6 | aldra | You weren't using it. |
| L17 | E7 | obren | Every winter, frost-man. I have nothing left but winters. |
| L18 | E8 | torvald | Bigger ones. Of course there are bigger ones. |
| L19 | E10 | narrator | The third winter was the longest. The Hollow sent everything it had left. |
| L20 | E11 | obren | Step aside, little king of snow. I built stairs before your mountains had names. (6 s) |
| L21 | E11 | torvald | Stone is patient. Ice is older. |
| L22 | E12 | master | Three winters, and not one stone stood on your ice. |
| L23 | E12 | torvald | They will come back. |
| L24 | E12 | master | Then so will you. Every winter. You are my patience, Torvald. |
| L25 | E12 | master | Aldra Stillwater. Stay with it. The ice keeps its wardens. |
| L26 | E12 | aldra | Then I will keep it right back. |
| L27 | E12 | narrator | The lake froze around the Heartfrost that night. It did not thaw for a hundred winters. (6 s) |
| L28 | E14 | torvald | Too slow... forgive me. Too slow. |
| L28b | E16 | aldra | Cracked. Not broken. (3 s) |
| L29 | E13 | aldra | The longhouse... my mother's nets were in there. |
| L30 | E15 | obren | Mine. At last, mine. (3 s) |
Echoes: L14 is the line Aldra says again in M2 (L16) a hundred years later; L24 is the prologue's "Torvald was my
patience"; L27 sets up M2's L1 and Vessa's L9 ("A hundred winters of ice, and it took me one afternoon"); L4 / L9 seed
the keys (Ysolde says it outright in Ep1 M3). Torvald never learns Obren's name here (the Master names him in e6m4).

## Cinematic hooks (ENGINE on the live scene, CinematicPlayer 19.C1; skippable; units frozen while they play)
| Id | Kind | When | Length | Shots / actors | End state (a skip must leave exactly this) |
|---|---|---|---|---|---|
| `ep6_opening` | ENGINE stage | Story mode, before the briefing | ~3:00 | `episode6-opening.md` (not this doc) | - |
| `e6m1_heartfrost` | ENGINE, **HOLD** | E1 | 0:30 | Teleports at `at == 0`: Torvald `(-6, 6)`, Aldra `(-10, 10)`, the Master actor `(4, -8)`. 1) WIDE crane down over the snowbanks onto the night-blue lake; 2) MS the Master walks the ice carrying a man-sized block of blue ice, the orb's glow inside; 3) LOW: he sets it down at `(0, 0)`, the ice under it blooms white in a ring r 22 (the lake freezes "in one wave", prologue S10's freeze-wave VFX); 4) two-shot Master / Torvald (L2-L4); 5) MS Aldra at the edge of the light (L5-L7); the Master walks away north-east and fades into snow | Heartfrost at `(0, 0)`, 2 000 HP; the Master despawned; Torvald `(-30, 30)`, Aldra `(-32, 33)`; L1-L7 queued once; mission clock 0:00 |
| `e6m1_return` | ENGINE, **HOLD**, then victory | E12 | 0:40 | 1) WIDE: snow stops, grey dawn (night -> dawn preset over 6 s); 2) the Master walks out of the mist on the lake (actor at `(20, -20)` -> `(4, -4)`); 3) MS two-shot Torvald (moved to `(-4, 4)`) and the Master (L22-L24); 4) MS Aldra (moved to `(-7, 6)`), the Master's hand on her shoulder, glass-teal frost runs down her sleeve (L25-L26); 5) the Sentinels walk back to S1 / S2 and ice shells close over them; 6) CRANE up: the lake whitens to the shore, title-less fade (L27) | Victory; Sentinels dormant in shells at S1 / S2 (cosmetic, the mission is over); lines queued once |
| `c_e6_lake` | ENGINE stage, between-scene | After the victory screen (Story mode) | 0:40 | Present day, the winter truce: Torvald and Aldra (her TH look, fifties) at a fire on the same shore, the M2 hole in the ice frozen over. Torvald: `A hundred winters I kept it for him.` Aldra: `And a girl with a fire took it in an afternoon.` Torvald: `She did. I have worse things to remember.` (the gate: into e6m2) | - |
| Theatre | - | e6m1 won | - | Unlocks nothing new (`helper_aldra` already unlocks on M2); flag `e6m1_sentinels` lets the reveal show the young look as a 2 s flash-back insert if TH.C1 wants it | - |
Camera axis: the Master - Torvald line runs north-east / south-west; cameras stay on its south-east side.

## Tiers, casters, helpers (ER4, ER5)
| Item | Value |
|---|---|
| Code | `MissionE601._init`: `tiers_enabled = true`, `casters_enabled = false`, `helpers_enabled = false`; `_ready`: `tier_system.max_tier = 1`, `bots_upgrade = false` |
| Rime Keep card | Z Rime Hauler, Set Rally r3c1; no tier button, no B |
| Frost Hall card | Z Rimeshield, X Shardcaster, C Rime Seer, N Rimeling; no "+" page (tier 2) |
| Tier chip | `Tier 1 Keep` (systems: `TierSystem.status()` returns no next step when `max_tier` is reached) |

## Economy
| Item | Value |
|---|---|
| Start | 300 crystals, 400 essence, 11 / 40 pop, 5 Haulers |
| Nodes | Home 2 x 1 500; west expansion 2 000 (near `road_w`: raided from winter 2); south 1 500 |
| Expected (normal) | ~10 Haulers by 5:00; ~3 000 crystals mined by 18:00 (home nodes dry ~17:00) |
| Essence by 19:00 | 400 + trickle ~1 140 + kills ~950 (~55 Wardens x 15, 4 Breakers x 40, the Stair-Breaker 80) = **~2 500**: two mids. Suggested: Frostglass Shard -> Glacier Heart (Frostbite on every spell) |
| Spending pressure | Rimeshields and Shardcasters (the line) vs Ice Walls at the gaps (20 each) vs a Rime Spire on the NE shore (130) vs a second Snow Lodge |

## Win / lose
| Event | Result |
|---|---|
| Winter 3 ends | **Victory** after `e6m1_return` |
| Torvald dies | **Defeat** (`instant_loss_on_wizard_death = true`) |
| Heartfrost destroyed | **Defeat** |
| Rime Keep destroyed | **Defeat** (rare: Wardens are ordered onto the Heartfrost; they hit the keep only if it blocks them) |
| Longhouse destroyed | `sec_longhouse` failed; nothing else |
| Aldra falls | Nothing; back in 40 s |

## Reward and flags
- Nothing carried (ER3). `CampaignState.MISSION_REWARDS[&"e6m1"] = {"flags": {"e6m1_sentinels": "sec_sentinels"},
  "next": &"e6m2"}` (`sec_longhouse` gives **+300 essence** only for this mission's score screen; nothing is saved).
- Story flow: victory -> `c_e6_lake` -> e6m2 briefing.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave counts | x 0.6, no Breaker in W2c | as written | x 1.4 |
| Heartfrost HP / regen | 2 600 / 15 | 2 000 / 10 | 1 600 / 8 |
| Start | 400 crystals, +2 Rimeshields | 300 | 250, 1 Shardcaster |
| Stair-Breaker HP | 1 800 | 2 400 | 3 200 |
| Floe weight threshold | 6 | 8 | 10 |
| Expected time | 17-19 min (fixed seasons) | 18-20 min | 19-21 min |
Fight sizing (worth: Ruin Warden **120**, Breaker **330**, Stair-Breaker **800**; player side = crystals + Torvald
`170 + 30 x level` + Aldra ~300 + Sentinels 330 each; every fight <= 70 % of what the player can have then):
| Fight | Enemy | Player side then | Ratio |
|---|---|---|---|
| W1a (3:00) | 360 | ~1 150 (start army + Torvald L2 + Aldra) | 31 % |
| W1b (4:30) | 480 | ~1 400 | 34 % |
| Raid 1 (7:00) | 240 | ~1 700 | 14 % |
| W2a (9:00) | 600 | ~1 900 (+ 1 Sentinel ~2 200) | 27-32 % |
| W2b (10:30, flank) | 480 | ~2 100 | 23 % |
| W2c (12:00) | 930 | ~2 400 | 39 % |
| W3a (15:30) | 1 080 (two sides) | ~2 900 + Sentinels 660 | 30 % |
| W3b (17:00) | 1 380 | ~3 400 | 41 % |
| W3c (18:15) | 1 400 | ~3 400 | 41 % |
- The skill check is **winter 3**: the three sets land 1:30 / 1:15 apart, so a player who has not killed W3a when W3b
  arrives faces ~2 000 at once (59 %). The intended answers: Ice Walls in the NW gap (forces `road_w` / `barrow_n` round to
  the NE gap), a Rime Spire covering F7, Flash Freeze + Rime Bolt on the floe the Breakers cross (a sunk Breaker is 330 of
  fight value for 85 mana), the Sentinels as the line.
- The floes favour Torvald on purpose (origins are a refresher, outline 3.5); hard raises the weight threshold so the
  lake sinks fewer Wardens by itself.
- Watch in the first playtest: if winter 1 is trivial, move W1b to 4:00 with 5 Wardens; if winter 3 kills the Heartfrost
  often on normal, cut W3b to 1 Breaker.

## Target length (normal)
| Part | Time |
|---|---|
| `ep6_opening` (Story mode) | ~3:00 |
| Mission (`mission_time`), seasons fixed, winter 3 ends ~19:00 | ~19:00 |
| `e6m1_heartfrost` + `e6m1_return` | 1:10 |
| **Total (mission + its cutscenes)** | **~20 min** (17-20 inside the 16-20 target on a clean W3c) |

## Code reuse (recommendation to the lead)
`MissionBase` (M9.S1 / 19.C2) for objectives, dialogue, timers, `_spawn_group` / `_scaled`, the level cap and the save;
M9.S1-S2's **Heartfrost, floes, snowbanks and `FogOfWar.sight_scale`** (this mission needs M2's floe code with a
`weight_rule` / `break_rule` callable or a subclass, not a copy); M9.V1's frozen kit; `MissionBrazier`'s channel ring for
the carving; the Ice Wall / Rime Colossus types; 19.C1 for the two hooks (direct-effect fallback until it exists).

## Acceptance checks
- [ ] Map: seed 1202; M2's 28 snowbanks, 4 gaps and the SW path test pass; none of M2's Fire / Shadow / Emberguard rows exist; the 3 cracks, `shore_e`, the longhouse and both Sentinel stones resolve within 1.5 m of the table on walkable ground.
- [ ] Heartfrost: 2 000 HP, PLAYER, only ENEMY damage; regen 10 / s exactly while Torvald <= 8 m and no enemy <= 8 m; HP 0 = defeat in 3 s.
- [ ] Floes: 4 Ruin Wardens (weight 8) standing on F7 add a crack every 4 s; a break sinks every Warden on it (death, XP to Torvald); a Rimeshield on the same floe is displaced with full HP; Flash Freeze on open water refreezes it at once.
- [ ] Seasons: winters at 2:30 / 8:30 / 15:00 with PLAYER sight x 0.6 and ENEMY -0.4 m/s; cracks open on their winters.
- [ ] Waves W1a-W3c spawn at their times and cracks with the counts (easy x 0.6, hard x 1.4, min 1) and walk to the Heartfrost; raids to the longhouse.
- [ ] Aldra: not commandable; Bulwark autocast blocks a 3-Warden group walking at the Heartfrost; a Breaker shatters it in 1 s; carving needs Torvald <= 8 m, pauses with an enemy <= 12 m, makes a commandable pop-0 Sentinel; falls and returns in 40 s.
- [ ] Dialogue: each line id fires once per run on its event; every speaker id is in `Speakers.TABLE` and `cast.json`.
- [ ] Skipping `e6m1_heartfrost` and `e6m1_return` leaves their end states.
- [ ] Timing: a scripted headless run on normal (walls in the NW gap, hold the NE gap, carve both stones in thaws) ends `victory=true` at 18:00-20:00 mission time in 3 / 3 runs with the Heartfrost above 40 %; `PERF OK` with a floe break under 10 Wardens.

## Done when (proposed ids; the lead adds them to `waves.md`)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| **E6M1.S1** | systems | Scene + script, map from M2's table (D1 rows only), cracks / spawns / longhouse / Sentinel stones, start state, ER3-ER5 switches, `max_tier = 1` with the tier chip "no next step" | M9.S1 (`MissionBase`, M2 map code) | First 3 acceptance checks |
| **E6M1.S2 [H]** | systems-high | Floe rule changes (weight, Rime Bolt / Flash Freeze cracks, refreeze, sinking, own-units-spared), seasons, Heartfrost as PLAYER target with regen, waves W1a-W3c + raids, events E1-E16, objectives, win / lose, difficulty table, flags | E6M1.S1, M9.S2 | Floe / season / wave / timing checks |
| **E6M1.G1** | gameplay | `aldra_young` story unit (stats, Bulwark no-mana autocast, Shatterglass x0.8, Escort brain, carving override, fall / return); `warden_breaker` UnitType (+ the named elite values, x2 vs buildings / scripted targets) | TH.G1 helper code (story reuse) | Aldra check; a Breaker deals 60 to a building per hit |
| **E6M1.U1** | ui | Objectives panel (winter counter + thaw countdown, Heartfrost HP bar, Sentinels 0 / 2), boss bar for the Stair-Breaker, season messages, `aldra` / `master` / `obren` dialogue colours | 19.U3 | Readable at 1600 x 900 and 3440 x 1440 |
| **E6M1.C1** | systems-high | `e6m1_heartfrost`, `e6m1_return` (ENGINE, HOLD) with marks and end states; `c_e6_lake` stage; StoryFlow `ep6_opening` -> briefing -> e6m1 -> `c_e6_lake` -> e6m2 | 19.C1, 19.C2 | Skip tests pass |
| **E6M1.V1** | tech-artist | Young Aldra look (`set_look(&"young")`), amber crack spawn (rise + dust), Sentinel stone + carving chips + shell crack, Warden Breaker variant (x1.5, amber cracks; elite x1.8), longhouse + fisher huts in snow, season light ramps (autumn / blizzard / thaw / night) | M9.V1, TH.V3 | 0 lights, Art Lab pass, `PERF OK` |
| **E6M1.O1** | Voice Forge agent | `data/voice/lines/e6m1.json` (31 lines) + `c_e6_lake` (3 lines) rendered | Lines frozen | Every WAV fits its slot |
| **E6M1.D1** | game-designer | Read the lines in game, trim; first-playtest tuning of winter 3 | Playtest | Changes written back here |
| Lead | lead | Headless timing run (acceptance), commit | All | `victory=true` 3 / 3 |
Dependencies: M9.S1 / M9.S2 / M9.V1 (mission 2's lake code and kit), 19.C1 / 19.C2 (cutscenes only; the mission plays
without them), TH.G1 / TH.V3 (Aldra's code and model; a glass-teal placeholder figure until then).

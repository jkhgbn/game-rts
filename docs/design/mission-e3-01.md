# Campaign mission e3m1: "Take the Ford" (Malrik + Mother Hush, with Torvald; Episode 3)

Written 2026-10-02 (`campaign-outline.md` 6 item 6). Episode 3 "The Gravedigger's Son", mission 1 of 4, the first Shadow
mission and the first **2v2 mission** of the story: Malrik (player) and Torvald (allied Ice bot) on the north ridge of
**Evenmead** against Ysolde (Nature bot) and Vessa (Fire bot) on Lark Hill. It plays right after `ep3_opening`, on the
ground that film shows. Target **22-28 min** on normal. Uses the rules of `skirmish-1v1.md` (2v2 seat form from
`ai-2v2.md`), `levels.md`, `items.md`, `tiers.md` 6, `caster-units.md` 5.4, `t3-helpers.md` 4.3, `map-fill.md` 2 and 4
(river, fords, capture points) and the format of `mission-01.md`. New scene `missions/mission_e3_01.tscn` +
`scripts/campaign/mission_e3_01.gd` (`MissionE301 extends MissionBase`, mission id `e3m1`, campaign-outline D6).
Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `+z` = south (the `forge_evenmead` set frame).
Status: **design only**; nothing here is built. Recommended option taken everywhere (no questions).

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map file | `data/maps/evenmead.map` does **not exist yet** (2026-10-02: `data/maps/` has crown_hollow, fourfold_hollow, gloamspine_divide, kinhearth_vale). Every map number below is taken from the built set `art/cinematics/stage_sets/forge_evenmead/forge_evenmead.set` and its `tools/em_layout.gd` (river, ford, crests, banners, camps, tree), so the film and the mission are the same ground at 1:1. The table in "Map" is the **binding gameplay layer** that E34.M1 writes into `evenmead.map`; `mission-e4-01.md` must use the same table | The brief: "do not invent positions". The set is the only built source; e34. 7 says the set is the map's centre at 1:1 |
| D2 | Size and symmetry | **150 x 120** (the set's size, x -75..75, z -60..60), **`symmetry=none`** (e34. 7 said 120 m `mirror_z`) | The filmed river bends (`(-44,-3)`, `(26,-7)`) are not mirror-symmetric; a story map need not be fair (Emberfall is not mirrored either). A mirrored skirmish cut can come later |
| D3 | Bases on the map | The four bases stand where the film's camps stand: Shadow pavilion `(-1,-47.5)`, Ice pavilions `(17,-48.5)` / `(32.5,-47)`, Nature pavilions `(-17.5,53)` / `(-31,50.5)`, Fire pavilions `(8.6,56.6)` / `(21,50.5)` | The opening's B14 shot cuts to the mission start: the player sees the same tents become keeps |
| D4 | Tier | **Stronghold only** (`max_tier = 2`), Citadel from e3m2 (campaign-outline D7) | One new tier per episode, first mission readable |
| D5 | Mother Hush | **Story unit** `hush_story`: autonomous, Escort stance fixed, the t3-helpers 4.3 kit at Malrik's level, not callable, never lost (falls, returns after 45 s) | Brief; `t3-helpers.md` 3 "Missions": story units reuse the helper model / VFX / ability code |
| D6 | Keystone Shard | New campaign artifact `keystone_shard`, equipped in artifact slot 1, **passive only** (stats + "Heartbeat" mana trickle, no active, no cost). Its active and Hollow cost arrive in e3m3 | Brief: "whispers but has no active power yet"; campaign-outline C7 |
| D7 | Malrik's save track | Malrik starts his own track here (campaign-outline D8): **level 3, cap 6**, empty item slots, **400 essence**, Keystone Shard owned + equipped | New hero, nothing from Vessa's track; essence makes up for the empty slots |
| D8 | The golden tree | **Not an objective, not attackable** (decor, no collider target, outside every capture zone). The mission ends when the foot of Lark Hill is held | "The ford is his, the tree is not" (brief); Ep4 e4m1 saves it the same afternoon |
| D9 | Old Vey | **Not on the field** (his fight is e3m4). Seen once in the victory cutscene: white-gold lightning on Lark Hill's crest | Keeps e3m4's hero-boss fresh; pays off L13 of `ep3_opening` ("an old man's storm") |

## Story setup (briefing text, 3 short paragraphs; shown after `ep3_opening`)
1. Two summers ago the Master's door held, and the war came up out of the deep looking for open ground. It found
   Evenmead: knee-high flowers, one slow river, two hills, and the Master's golden tree on the far one.
2. Malrik holds the north ridge with Torvald's winter at his side. On Lark Hill wait Ysolde, who has nothing left but
   this valley, and Vessa, who never waits for anything. Between them runs the river, and one stone ford.
3. Take the ford. Then take the foot of their hill, and let them watch from the top. In Malrik's pocket, Obren's
   heart-stone beats, and has opinions.

## Map: "Evenmead" (150 x 120, `data/maps/evenmead.map`, seed 34, not mirrored)
Terrain, grass, woods, river look and camps come from `forge_evenmead` (E34.M1 bakes the gameplay map from the same
`terrain` / `ridge` / `hill` / `valley` statements). Playable bounds x -72..72, z -57..57 (camera bounds 3 m inside the
set edge; the flank woods start at |x| ~58 and are impassable decor beyond x +-64). Clearings: no trees / rocks inside.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Malrik) / Hush | `(0, -36)` / `(2.8, -37.5)` | 5 (`crest_n` pad) | Malrik's crest, as filmed |
| **Dusk Keep** (player, Stronghold-able) | `(-12, -48)` | 16 | Replaces the Shadow command pavilion's camp |
| Gloom Hall (pre-built, complete) | `(1, -48)` | - | On the command pavilion `(-1, -47.5)` |
| Hovel (pre-built) | `(-14, -38)` | - | |
| Node `e3_dusk_a` / `e3_dusk_b` | `(-21, -45)` / `(-6, -56)` | - | **1 500** each (9.5 m / 10 m from the keep) |
| Node `e3_ridge_w` (expansion) | `(-48, -32)` | 7 | **2 000**; hall spot `(-41, -36)` |
| Node `e3_reedfield` (rich, contested) | `(-24, -14)` | 6 | **2 500**, 17 m north of the river; Nature's raids aim here |
| **Torvald's Rime Keep** (ally bot) | `(28, -48)` | 16 | Ice pavilions `(17, -48.5)` / `(32.5, -47)` |
| Rime Hall (pre-built) / Ice nodes | `(16, -45)` / `(37, -46)`, `(27, -57)` | - | Nodes 1 500 |
| Node `e3_ridge_e` (Torvald's expansion) | `(52, -34)` | 7 | 2 000 |
| **The river** | Centre polyline `(-75,6) (-44,-3) (-18,4) (4,0) (26,-7) (50,-2) (75,5)` | - | `RiverSystem.setup`, half width **3.0**, no moat. The set's valley (20 m wide, 2.6 deep) is the look |
| **Stone Ford** `ford_stone` | `(4, 0)` | - | Ford circle r **4.5** (the set's `ford_bar` r 7); worn tracks `TRACK_N` / `TRACK_S` of `em_layout.gd` lead to it |
| Reed Ford `ford_reed` | `(-44, -3)` | - | Ford r **3.0** (west bend) |
| Birch Ford `ford_birch` | `(50, -2)` | - | Ford r **3.0** (east bend, birch flank) |
| **Ford zone** `zone_ford` | centre `(4, 2)`, r **7** | - | The objective ring: the ford and its south landing |
| Ford stones (landmark, collider) | `(12, 9)`, yaw 25 | - | `kit:standing_stones` (`ford_stones` tag); cover for ranged units |
| **Clover Stone** `std_clover` | `(-28, 20)` | 5 | Foot point 1 (19 m south of the river) |
| **Ysolde's Standard** `std_ysolde` | `(1.5, 21.5)` | 5 | Foot point 2: the great Nature standard of the film (`banner_s`) |
| **Lark Well** `std_well` | `(24, 18)` | 5 | Foot point 3 (old stone well) |
| Horn Spire West / East | `(-40, 10)` / `(48, 10)` | 4 | Secondary targets: a Bramble Spire with a great wooden horn (13 m / 12 m from their fords) |
| Lark Hill crest | `(-4, 34.8)` (`crest_s`), hill centre `(-6, 42)` r 30 | - | Ysolde's and Vessa's film spots |
| Crest spires (enemy) | Bramble Spires `(-24, 32)`, `(-10, 30)`; Ember Spires `(6, 31)`, `(20, 34)` | - | Range 10-11: they reach the south edge of the Standard's ring, not its centre |
| **The Master's golden tree** | `(-16, 48.5)` | 6 | Decor (D8) |
| **Heartwood** (Ysolde bot) | `(-32, 48)` | 16 | Nature pavilions; Grove Hall `(-44, 40)`, nodes `(-41, 44)` / `(-36, 56)` 1 500, expansion `(-56, 26)` 2 000 |
| **Fire Keep** (Vessa bot) | `(20, 50)` | 16 | Fire pavilions; Ember Hall `(32, 42)`, nodes `(29, 46)` / `(16, 58)` 1 500, expansion `(52, 30)` 2 000 |
| Shadow rally / Ice rally | `(-4, -28)` / `(35, -28)` | - | The film's Shade block / Rimeshield block |
| Enemy rallies | Nature `(-18, 26)`, Fire `(12, 26)` | - | The film's Nature / Fire host blocks |
Distances (path): Dusk Keep -> Stone Ford 51 m; Fire Keep -> Stone Ford 54 m; Heartwood -> Stone Ford 60 m;
Dusk Keep -> Ysolde's Standard 72 m. The three fords are the only crossings (**no bridge**): every crossing is slowed.

**Crossings and the river** (`map-fill.md` 2.4 rules unchanged): `terrain:ford` `move_speed_pct -0.35` inside a ford circle;
deep water carved from the navmesh; building within 1 m of water refused, within 8 m of a ford `"Too close to a crossing"`.
Scripted props are placed by the mission (exempt). `Skirmish.river_enabled` stays false; the mission calls
`RiverSystem.setup(polylines, 3.0, null, crossings)` itself (`map-fill.md` 11).

**Ford zone** (reuses `CapturePoint`, new kind `&"ford"`, no footprint, ring decal r 7 in the owner's colour): capture time
**60 s** at a fixed rate (no count bonus), counters = soldiers, wizards (count 2), Hush; contested = frozen (ring flashes);
abandoned = decays 10 % / s; side 0 (Malrik + Torvald) only. Once captured, `obj_ford` is done for good (the zone stays as a
decal, not re-capturable).
**Standards** (`CapturePoint`, new kind `&"standard"`: a 6 m pole with the owner's banner, no footprint): radius **6**,
capture time **12 s** (x1.25 on the far bank = **15 s**), the `map-fill.md` 4.3 rules (rate up to x1.75, neutralise first,
contested, decay). Owner effect: a `SightMarker` sight 14. The enemy bots may retake them (scripted waves aim at them).
**Horn Spire** (BuildingType copy of `nature_tower`, id `horn_spire`, 540 HP, team ENEMY, `counts_for_defeat = false`):
attacks as a Bramble Spire; while alive it "sounds" (see Waves).

## Start state
| Item | Value |
|---|---|
| Malrik | **Level 3** (Shadow Lance r2, Soul Siphon r1), full HP / mana, **level cap 6**; artifact slot 1 = **Keystone Shard**; 6 empty slots |
| Mother Hush | `hush_story` at Malrik's level (L3: 590 HP, 30 dmg), Escort stance |
| Crystals / essence | 300 / **400** (essence +1 / s) |
| Buildings | Dusk Keep (tier 1; Stronghold from 3:30), Gloom Hall (complete), Hovel (complete) |
| Units | 5 Gloom Thralls gathering (3 on `e3_dusk_a`, 2 on `e3_dusk_b`), **4 Shades + 2 Nightbolts + 2 Grave Hounds** at the rally `(-4, -28)` |
| Population | 13 / 40 (keep 20 + Hovel 20; Hovels max **4** this mission = cap 100) |
| Torvald (ally bot, seat 2, Ice) | Level 4 (Frost spells r2 / r1 / r1), Rime Keep **at Stronghold**, Rime Hall, 4 Rime Haulers, **4 Rimeshields + 2 Shardcasters + 1 Frost Mortar + 1 Rimecarver** at `(35, -28)` |
| Ysolde (enemy bot, seat 1, Nature) | Level 4 at `(-5, 34)`; Heartwood at Stronghold, Grove Hall, 2 Seed Hollows, 5 Spriglings, 6 Thornlings + 3 Wildwood Archers at her rally |
| Vessa (enemy bot, seat 3, Fire) | Level 4 (Fireball r2, Ember Step r1, Kindle r1) at `(-1.6, 35)`; Fire Keep at Stronghold, Ember Hall, 2 Hearths, 5 Cinder Hands, 4 Flame Guards + 2 Ember Archers at her rally |
| Fog | On; the river, the three fords, the three standards and both crests explored for everyone from 0:00 (`FogOfWar.reveal(team, pos, 6)`) |
| Champions, trade, camps, beasts, wells / shrines | Off (`tavern_enabled`, `trade_enabled`, `camps_enabled`, `beasts_enabled`, `points_enabled` false; the mission adds only its own 4 capture zones) |

## Unlocks (what exists in this mission)
| Kind | Available | Locked (comes later) |
|---|---|---|
| Buildings | Hovel, Gloom Hall, Night Spire | Gloom Stables, Bazaar (skirmish only); Citadel (e3m2) |
| Units | Gloom Thrall (keep Z); Gloom Hall: **Z Shade, X Nightbolt, C Grave Hound, V Shadow Knight, N Barrow Ghoul**; **from the Stronghold**: **M Hexweaver, `,` Hollow Oathsworn** (Gloom Hall), **B Gloom Deacon** (keep) | Bleakbow (Hall B, skirmish only), Nightblood Reaver (Citadel, e3m2) |
| Keep | **Stronghold** (X, 200 crystals, 60 s, from 3:30) | Citadel; Call Mother Hush (e3m2: Hush becomes the callable helper) |
| Spells | Shadow Lance (L1), Soul Siphon (L2+), Umbral Shroud (L4+) | Cap L6 |
| Items | Base shop (Dusk Keep, Gloom Halls): the 10 components, mids, tops, Ember Draught, Dusk Vial, Homeward Seal; no peddler | Owl Stone (fog wave); the Shard's active (e3m3) |
| "+" upgrades | At the Gloom Hall from the Stronghold (Shade+, Nightbolt+, Shadow Knight+ ...) | - |

### The Gloom Deacon in this mission (`caster-units.md` 5.4, unchanged numbers)
The mission is built so both Deacon spells have a job: **Blood Tithe** keeps Shadow Knights alive in the slow ford fight
(heal 10 / s, drain 5 / s from the nearest enemy); **Umbral Passage** (100 mana, 2.5 s, up to 10 pop within 4 m of a seen
point <= 45 m away) pulls a squad **back across the river with no ford slow**, or pulls the ford group to the Deacon on
the south bank when a standard is under attack. Two hints teach it (E4, E6).

### The Keystone Shard (new campaign artifact; the items row is for the items owner, campaign-outline C7)
| id | Name | Given by | Stats / effect |
|---|---|---|---|
| `keystone_shard` | Keystone Shard (Obren's heart-stone) | Malrik's track start (Ep1 V5; first equipped in e3m1) | `max_hp` +80, `spell_power` +10, `mana_regen` +0.5; **Heartbeat** (passive): **+3 mana** when any unit (either side) dies within **10 m** of Malrik, max once per 0.5 s. No active in e3m1 (e3m3 adds it with a Hollow cost). `campaign_only`, never sold, never dropped (the Crown's drop rule does not apply) |
Look: artifact icon `KS`, amber border; while equipped a faint amber pulse at Malrik's claw hand every 1.2 s (the
`heart_stone_pulse` VFX at 0.3 scale, no light), brighter for 0.4 s on each Heartbeat.

### Mother Hush (story unit `hush_story`, D5)
`t3-helpers.md` 4.1 / 4.3 numbers at Malrik's level (L3: 590 HP, armor 10, 30 damage, 5.4 m/s): Mouthless Veil, Blink
Strike (10 s), Smoke Cloak (22 s), **Night of Knives from L5** (Malrik reaches L5 around the foot fight). Brain: Escort
(3-7 m from Malrik, fights what threatens him first; R2 flee under 25 % to the Dusk Keep, rest 2 % / s). Not commandable
(`is_commandable()` false; clicking her = read-only inspect card, no stance buttons). **Falls**: body fades, line L19,
back at the keep door after **45 s** at full HP. Kills give essence and XP to Malrik's team as usual.

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_ford` | Primary | `Take the Stone Ford` (progress bar 0-100 %) | The ford zone is captured (60 s of uncontested presence) |
| `obj_foot` | Primary (appears after `obj_ford`) | `Take the foot of Lark Hill (0 / 3)` | Side 0 owns all 3 standards at the same moment |
| `obj_hold` | Primary (appears after `obj_foot`) | `Hold the foot of Lark Hill (2:00)` | 120 s with all 3 standards owned; the countdown **pauses** (text `(paused)`) while one is neutral or enemy, and never resets |
| `obj_malrik` | Primary, always shown | `Malrik must survive` | Fails = defeat |
| `sec_horns` | Secondary | `Silence the Lark horns (0 / 2)` | Both Horn Spires destroyed |
| `sec_vessa` | Secondary (appears at E5) | `Drive Vessa off the field` | Vessa (bot) dies once, any time after E5 |
States through `Events.objective_changed(id, state)`: `"active"`, `"done"`, `"failed"`. Torvald's units count for the ford
and the standards (side 0).

## Guards, waves and the bots (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted guards are team ENEMY, **not** controlled by any Commander: they hold their spot with auto-aggro and a 2x leash.
Wave units are spawned by the mission (not the bots) at the named spawn and given the order shown.
| Group | Where | Units |
|---|---|---|
| G1 ford pickets | South landing `(6, 8)` | 4 Thornlings + 2 Burr Slingers + 2 Flame Guards |
| G2 west horn | Horn Spire West `(-40, 10)`, ring r 3 | the spire + 3 Thornlings |
| G3 east horn | Horn Spire East `(48, 10)`, ring r 3 | the spire + 2 Burr Slingers + 1 Bramblehorn |
| G4 Clover Stone | `(-28, 20)` | 4 Thornlings + 1 Bloomtender |
| G5 Ysolde's honour guard | `(1.5, 21.5)` | 2 Greenheart Oathkeepers + 3 Wildwood Archers |
| G6 Lark Well | `(24, 18)` | 3 Flame Guards + 2 Ember Archers + 1 Pyre Adept |
| Crest | 4 spires (Map) | Buildings only; the bots' own armies stand at their rallies |

| Wave | Trigger | Units (spawn) | Order |
|---|---|---|---|
| W1 skirmishers | 5:00 | 4 Thornlings + 2 Thistle Darters (Grove Hall) | Cross Reed Ford, attack-move to the nearest Shadow worker (usually `e3_reedfield` / `e3_ridge_w`) |
| W2 Vessa's raid | 7:30 | **Vessa** + 3 Blaze Riders (Ember Hall) | Cross Birch Ford, attack-move to Torvald's workers, then the Dusk Keep's nodes; Vessa retreats under 35 % HP (bot rule 8) |
| W3 Ysolde's charge | Ford progress reaches **50 %** the first time | **Ysolde** + 6 Thornlings + 3 Burr Slingers + 2 Bloomtenders + 1 Bramblehorn (Grove Hall) | Attack-move to the ford zone centre |
| Horn relief | At E5, then every **120 s**, **per living Horn Spire** | 3 Thornlings + 1 Burr Slinger at that spire | Attack-move to the ford, then the nearest standard owned by side 0 |
| W4 Fire column | First standard captured by side 0 | **Vessa** + 4 Flame Guards + 3 Ember Archers + 2 Pyre Adepts + 1 Cinder Arbalest (Ember Hall) | Attack-move to that standard |
| Final | `obj_hold` starts | 0 s: **Ysolde L5 + Vessa L5** + 8 Thornlings + 4 Wildwood Archers + 2 Vinelashers + 2 Bloomtenders; 45 s: 4 Flame Guards + 2 Blaze Riders + 2 Pyre Adepts | Each group attack-moves to the standard side 0 owns that is nearest its spawn, refreshed every 4 s |
If `sec_horns` is done before the Final, the Final wave loses **25 %** of its units (rounded down; wizards stay) and the
horn relief stops for good (it also stops per spire as each falls).
**Enemy bots** (`ai.md` + `ai-2v2.md` side council, profile `mission_e3_01_enemy`): easy knobs, `min_attack_pop` 99 (they
never launch their own attacks), `worker_target_home` 5, no expansion, no new towers, keep up to **10 soldiers** at their
rallies, `bots_upgrade = false`. Their wizards stay at their crest anchors except when a scripted wave carries them
(W2, W3, W4, Final); a wizard killed respawns at its keep after the 2v2 timer and walks back to its anchor.
**Ally bot Torvald** (`ai-2v2.md` ally layer, Supportive, profile `mission_e3_01_ally`): gathers, trains up to **14 army
pop**, defends both north bases, answers the player's pings (attack / defend / help / retreat), never steals the player's
nodes. Scripted pushes on top of the pings: at W3 his army attack-moves **Birch Ford -> Horn Spire East** (a diversion that
pulls G3); at `obj_foot` his army goes to **Lark Well** and stays on it through the hold. Torvald dying is never a loss
(respawn as a 2v2 wizard); his Rime Keep falling is never a loss (his army falls back to the Dusk Keep).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (`ep3_opening` played before the scene, then the briefing screen.) Camera on Malrik at the crest; dialogue L1-L4; hint `Take the Stone Ford, due south. Fords slow every unit inside: win the fight on the bank, then cross.` |
| E2 | Malrik within 15 m of the river the first time | L5-L6 (the stone speaks; amber pulse on Malrik's hand) |
| E3 | 3:30 (Stronghold available) | Hint (12 s) `Your Dusk Keep can become a Stronghold: select it and press X (200 crystals). It opens Hexweaver, Hollow Oathsworn (Gloom Hall) · Gloom Deacon (Keep).` |
| E4 | First Gloom Deacon trained | Hint (12 s) `Gloom Deacon: Z Blood Tithe heals an ally and drains the enemy beside it. V Umbral Passage pulls up to 10 soldiers to the Deacon, even across the river.` |
| E5 | W2 spawns (7:30) | L7-L8; `sec_vessa` active |
| E6 | Ford progress 50 % the first time | L9 (Ysolde); W3 spawns; Torvald's diversion push |
| E7 | `obj_ford` done | Cutscene `e3m1_ford` (0:12); L10, then L11 if a Horn Spire lives; horn relief armed; `obj_foot` active; hint `Umbral Passage can bring your army over the water. The standards fall faster with more soldiers.` |
| E8 | A Horn Spire destroyed | L12 (first one only); `sec_horns` counter; at 2 / 2 done |
| E9 | First standard captured by side 0 | L13-L14; W4 spawns |
| E10 | Ysolde's Standard captured by side 0 (first time) | Cutscene `e3m1_standard` (0:10); L15-L17 |
| E11 | `obj_foot` done | L18; `obj_hold` active (2:00); Final wave; Torvald to Lark Well |
| E12 | Vessa dies the first time after E5 | L20-L21; `sec_vessa` done |
| E13 | Hush falls | L19 (once per mission); she returns after 45 s |
| E14 | `obj_hold` done | Cutscene `e3m1_dusk` (0:30) with L22-L24; remaining Nature / Fire units walk back to the crest; `Events.mission_ended(true)` at its end |
| E15 | Malrik dies | L25; `obj_malrik` failed; defeat after 3 s |
The standards can be taken in any order; E9 fires on the first, E10 only on Ysolde's Standard.

## Dialogue (25 lines; speaker colours: Malrik `(0.7, 0.3, 1.0)`, Hush `(0.60, 0.50, 0.75)`, Torvald `(0.55, 0.80, 1.00)`, Obren `(1.0, 0.80, 0.25)`, Ysolde `(0.55, 0.90, 0.35)`, Vessa `(1.0, 0.45, 0.1)`, Narrator `(0.9, 0.85, 0.7)`; 5 s each)
Speaker ids from `data/voice/cast.json` (all exist): `narrator`, `malrik`, `hush`, `torvald`, `obren` (alias of
`whisper`: same voice; shown as **Obren**, his name is known since Ep1), `ysolde`, `vessa`. Every line <= 2 lines of the
dialogue box (<= 96 characters).
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Evenmead. The last green country. By sundown, someone will own the ford. |
| L2 | E1 | malrik | Torvald, the east bank is yours. I will take the water. Hush, take whatever moves. |
| L3 | E1 | hush | Whatever moves, Bishop. And a few things that don't. |
| L4 | E1 | torvald | Quickly, then. Before that stone in your pocket finishes its sentence. |
| L5 | E2 | obren | So much green, Bishop. Let it grow red. I can help. |
| L6 | E2 | malrik | You can help by being quiet. Stones are usually good at that. |
| L7 | E5 | vessa | Malrik! You brought a whole winter to a picnic. |
| L8 | E5 | malrik | And you brought fire to a meadow. We all have our gifts, Vessa. |
| L9 | E6 | ysolde | That water is older than all four of us. Get out of it. |
| L10 | E7 | malrik | The ford is mine. Write it down, Ysolde. You like things that last. |
| L11 | E7 (a horn lives) | narrator | Across the river, the Lark horns call the whole valley to arms. |
| L12 | E8 | hush | One horn fewer. The valley will have to shout. |
| L13 | E9 | vessa | He's on our hill. I'm not waiting for him to plant a flag. |
| L14 | E9 | ysolde | Vessa, hold the crest. Please. Just once, wait. |
| L15 | E10 | obren | The flag falls. The tree is right there. Take it. TAKE it. |
| L16 | E10 | torvald | Malrik. Your hand is shaking. Is that you, or the stone? |
| L17 | E10 | malrik | It is me, Torvald. It has always been me. |
| L18 | E11 | ysolde | Every root on this hill knows your name now. That is not a kindness. |
| L19 | E13 | hush | There is always another night. |
| L20 | E12 | vessa | This isn't over, candle-man! |
| L21 | E12 | malrik | It never is. That is what I like about you. |
| L22 | E14 | malrik | The ford is mine. The tree is not. Not today. |
| L23 | E14 | malrik | Tell me to stop again tomorrow, Ysolde. I will not stop. |
| L24 | E14 | narrator | The ford fell at dusk. The golden tree still stood. Both hills called it a victory. |
| L25 | E15 | malrik | Not like this. Not... stopped. |
Echoes: L23 closes `ep3_opening` L14-L15 ("I have heard 'stop' all my life. / I will not stop."); L3 and L19 are Hush's
own barks from `t3-helpers.md` 10.4 and M0 L8; L13-L14 are Vessa's prologue weakness ("she never waits"); L16 seeds
Torvald's doubt (Ep3 between-scene, Ep7's turn); L24 hands the same afternoon to `e4m1` ("Hold Lark Hill": Ysolde saves
the tree until nightfall). Voice: render through Voice Forge with the cast as approved; `obren` uses the whisper voice.

## Cinematic hooks (ENGINE, on the live mission scene, CinematicPlayer 19.C1; skippable; units frozen while they play)
| id | When | Length | Shots (camera, what we see) | Lines |
|---|---|---|---|---|
| `e3m1_ford` | E7 | 0:12, HOLD | 1) LOW over the ford stones `(12, 9)` looking north-west: Shadow units wade out of the water; 2) MS Malrik's banner-bearer (a Shade) plants a violet standard in the ford bar at `(4, 0)`; violet ring sweeps the zone | L10 |
| `e3m1_standard` | E10 | 0:10, HOLD | 1) MS Ysolde's Standard: it tips and falls (2 s topple), green banner into the flowers; 2) the `N12` mark reversed: long lens (fov 22) from the standard's base up Lark Hill to the golden tree; amber `heart_stone_pulse` on Malrik's hand in the foreground (soft) | L15-L17 |
| `e3m1_dusk` | E14 | 0:30, then victory | 1) WIDE crane (the `B14` mark, `from=(70,40,0)`) over the valley as the light drops from golden to dusk (light ramp `preset_golden` -> dusk tint over 6 s); 2) MS Malrik on the ford stones, 3/4-left (east of the axis, the Ep3 rule); 3) CU his hand: the stone beats; 4) long lens up Lark Hill: Ysolde and Vessa on the crest under the golden tree, and **one white-gold lightning flicker** behind them (Vey, D9); 5) CU Malrik, front: L23; FADE_BLACK | L22-L24 |
Camera axis: all three keep the `ep3_opening` rule (cameras east of the north-south Malrik - Ysolde line). Fallbacks
until Motion Lab / VFX Composer exist: the standard topple is a 2 s rotation tween of the prop; missing VFX ids are skipped.

## Tiers (`tiers.md` 6)
| Item | Value |
|---|---|
| Code | `MissionE301._init`: `tiers_enabled = true`, `casters_enabled = true`; `_ready`: `tier_system.max_tier = 2`, `bots_upgrade = false` |
| Dusk Keep card | Z Gloom Thrall, **X Stronghold** (gold pulse when it can start), **B Gloom Deacon** (greyed `Requires Stronghold`), Set Rally r3c1; no Citadel, no Call button |
| Gloom Hall card | Z X C V N as listed; **M Hexweaver, `,` Hollow Oathsworn** greyed until the Stronghold; "+" page from the Stronghold |
| Bots | Torvald, Ysolde and Vessa start at the Stronghold (veterans) and never reach the Citadel; the enemy's scripted tier-2 units (Pyre Adept, Cinder Arbalest, Vinelasher, Greenheart Oathkeeper) are spawned, not trained |
Timing: Stronghold 3:30 -> 4:30 at the earliest; first Deacon / Hexweavers ~5:00-5:30, before W2 (7:30) and the ford
fight (8:00-11:00).

## Economy
| Item | Value |
|---|---|
| Start | 300 crystals, 400 essence, 13 / 40 pop, 5 Thralls |
| Nodes (player) | Home 2 x 1 500, west expansion 2 000, contested rich 2 500 (raided by W1 and the horn relief only if they wander) |
| Expected income (normal) | ~10 Thralls by 6:00; ~3 400 crystals mined by 20:00 (the home nodes run dry around 18:00: the west expansion matters) |
| Essence (expected by 22:00) | 400 start + trickle ~1 300 + kills ~1 300 (≈ 55 Nature / Fire units, two wizard kills) = **~3 000**: one top or two mids for Malrik (bot-free pick; suggested Grave Pact -> Gravemaw Idol, it feeds his drain kit) |
| Torvald | His own nodes; his army cap (14 pop) keeps him a helper, never the carry |

## Win / lose
| Event | Result |
|---|---|
| `obj_hold` done | **Victory** (after `e3m1_dusk`, `Events.mission_ended(true)`) |
| Malrik dies | **Defeat** (`instant_loss_on_wizard_death = true`; no respawn for the player's wizard in missions) |
| Dusk Keep destroyed | **Defeat** |
| Torvald dies / his keep falls | Nothing (message `Torvald falls back to the ridge`); he respawns as a 2v2 wizard |
| Hush falls | Nothing; back in 45 s |
| An enemy keep destroyed | Allowed, not needed; message `Lark Hill burns, but its people hold the crest` (the enemy wizard respawns at the other keep) |
| All Shadow soldiers dead, Malrik alive | Nothing; he can still rebuild |

## Reward carried to e3m2 (Malrik's track, campaign-outline D8)
- **Keystone Shard** stays owned and equipped (slot 1). The 6 item slots as they are at victory; essence **50 %, cap 1 500**.
- `sec_horns` done: **+300 essence** at victory (before the cut). `sec_vessa` done: **+200 essence** and flag.
- Flags saved: `e3m1_horns_silenced`, `e3m1_vessa_driven`, `e3m1_time` (seconds), `e3m1_standard_toppled` (always true on a win; e4m1's briefing may mention the fallen standard).
- Level not carried (e3m2 sets its own start, campaign rule).

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave / guard counts | x 0.6, no Bramblehorn, no Cinder Arbalest | as written | x 1.4; Final wizards L6 |
| Start | 450 crystals, +2 Shades | as written | 250 crystals, no Grave Hounds |
| Ford capture | 45 s | 60 s | 75 s |
| Hold timer | 90 s | 120 s | 150 s |
| Torvald army cap | 18 pop | 14 | 10 |
| Expected time | 18-22 min | 22-28 min | 26-34 min |
Expected run on normal: Stronghold ~4:30 -> W1 5:00 (raid, easy) -> Deacons / Knights 5:30-7:30 -> W2 Vessa raid 7:30 ->
ford fight 9:00-12:00 (G1, then W3 at 50 %) -> ford taken ~12:00 (cutscene) -> horns 12:00-16:00 (optional) -> first
standard ~15:00 (W4) -> Ysolde's Standard ~17:00-19:00 -> all three ~20:00-23:00 -> hold 2:00 -> **~22-25 min**, 28 with retakes.
Fight sizing (army value, crystals + wizard worth `170 + 30 x level`; every guarded fight <= 70 % of what the player
side can have then, ep1 4.1 rule; Torvald counted only where his scripted push puts him):
| Fight | Enemy | Player side then | Ratio |
|---|---|---|---|
| W1 (5:00) | 370 | ~1 100 (start army + first trains) + Malrik / Hush | 34 % |
| W2 Vessa raid (7:30) | 830 | ~1 500 + Torvald's 1 000 at his base | 33-55 % |
| G1 ford pickets (~9:00) | 560 | ~2 000 | 28 % |
| W3 Ysolde's charge (ford 50 %) | 1 240 | ~2 000 after G1 losses | 62 % |
| W4 Fire column (~15:00) | 1 345 | ~2 800 | 48 % |
| G5 honour guard + crest spires' edge | 595 + spire chip | ~2 800 | 25 % |
| Final (0 s / +45 s) | 1 880 / 2 860 total | ~3 500 + Torvald ~1 000 on Lark Well | 42 % / 64 % |
- The ford is the skill check: fighting **in** the ford loses (-35 % speed, Burr Slingers and Ember Archers on the bank).
  The intended answers: Nightbolts and Hexweavers on the north bank first, Knights in with Blood Tithe on them, or
  Umbral Passage to land a squad on the south landing behind G1.
- Ysolde's Standard sits just outside the crest spires' range at its centre; the hill side of its ring is inside it, so
  a careless army standing on the south edge gets shot. The hold is meant to be won by holding the Clover Stone and the
  Standard with the army while Torvald holds Lark Well.
- Watch in the first playtest: if W3 at 50 % wipes the player, move its trigger to 70 %; if the Final is trivial with
  `sec_horns` done, cut the reduction to 15 %.

## Done when (proposed ids; the lead adds them to `waves.md`)
- [ ] **E34.M1** (four-wizards-high, shared with e4m1): `data/maps/evenmead.map` 150 x 120, `symmetry=none`, holds every row of the Map table (keeps, halls, nodes and amounts, fords, zones, standards, horns, spires, tree, rallies) at the coordinates above +-0.5 m, and the river / ford / hills match `forge_evenmead` within 1 m; Map Lab >= 90.
- [ ] **E3M1.S1** (systems): `missions/mission_e3_01.tscn` + `scripts/campaign/mission_e3_01.gd` load `evenmead.map`; `RiverSystem.setup` with the polyline and 3 fords (ford slow active, no bridge); start state exactly as the table (300 / 400 / 13 of 40, pre-built Hall + Hovel, Hovel max 4); 4 seats on 2 sides (player + Torvald vs Ysolde + Vessa); `CapturePoint` kinds `&"ford"` (60 s fixed rate, side 0 only) and `&"standard"` (radius 6, 12 s); `horn_spire` building; guards G1-G6 at their spots with a 2x leash; the golden tree is decor, not a target.
- [ ] **E3M1.S2** (systems-high [H]): objectives and events E1-E15 in order; waves W1, W2, W3 (ford 50 %), horn relief (per living spire, every 120 s from E5), W4, Final (targets refreshed every 4 s); `obj_hold` pauses and never resets; `sec_horns` -25 % Final rule; instant loss on Malrik's death; Dusk Keep loss = defeat; Torvald / Hush never end the mission; `tiers_enabled`, `max_tier = 2`, `bots_upgrade = false`, `casters_enabled`; difficulty table.
- [ ] **E3M1.S3** (systems): victory saves Malrik's track (D8): Keystone Shard owned + equipped, 6 slots, essence 50 % cap 1 500 (+300 / +200 first), the 4 flags; a headless test loads e3m2's start and finds them; Vessa's track is untouched.
- [ ] **E3M1.G1** (gameplay): `hush_story` (helper kit of `t3-helpers.md` 4.3 at Malrik's level, Escort brain, not commandable, falls and returns in 45 s at the keep); test: she never stays dead and Blink Strike targets the lowest-HP-% enemy hero / caster within 14 m.
- [ ] **E3M1.I1** (items): `keystone_shard` ItemType (artifact, campaign_only) with the stats above and Heartbeat (+3 mana per death within 10 m, 0.5 s gate); test: 4 deaths in 2 s within 10 m give 12 mana, a death at 11 m gives none.
- [ ] **E3M1.A1** (ai): profiles `mission_e3_01_enemy` (defend only, 10 soldiers at the rally, wizards at their crest anchors except when a wave carries them) and `mission_e3_01_ally` (Torvald: 14 pop, pings, the two scripted pushes); scripted units never join a Commander.
- [ ] **E3M1.U1** (ui): objectives panel with the ford progress bar, the standards counter, the hold countdown with `(paused)`; DialogueBox colours for `hush`, `torvald`, `obren`, `ysolde`; briefing screen (3 paragraphs + primaries) after `ep3_opening`; ally / enemy wizard portraits in the 2v2 strip.
- [ ] **E3M1.C1** (systems-high, after 19.C1 / 19.C2): the 3 ENGINE cutscenes as listed; StoryFlow plays `ep3_opening` -> briefing -> e3m1 -> (e3m2's between-scene); skip works.
- [ ] **E3M1.V1** (tech-artist): Horn Spire look (Bramble Spire + a 2 m wooden horn, a sound-wave ring when it calls), standard prop with owner-coloured banner and a 2 s topple, violet ford standard, ford ring decal; 0 lights, Art Lab pass.
- [ ] **E3M1.O1** (Voice Forge agent): the 25 lines rendered with `cast.json` voices; every WAV fits its 5 s slot.
- [ ] **E3M1.D1** (designer): read the 25 lines in game once; trim any line over 2 lines of the box; check that `mission-e4-01.md` reuses the Map table unchanged.
- [ ] **Lead**: a scripted headless run on normal (take the ford, the 3 standards, hold) ends `victory=true` in 22-28 game-minutes in 3 / 3 runs; the W3 fight leaves Malrik alive in 5 / 5 runs with the scripted army.

Dependencies (must exist first): E34.M1 map, 19.C1 CinematicPlayer + 19.C2 StoryFlow (cutscenes only; the mission plays
without them), the 2v2 seat API and ally layer (`ai-2v2.md`, 20.A*), `RiverSystem` / `CapturePoint` (step 12),
`MissionBase` (M9.S1), the helper ability code (TH / 19.C12) for Hush.

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Gloom Deacon.
- **Why here:** fords slow 35 %; Umbral Passage carries 10 pop across with no slow; Blood Tithe in the slow grind; Lab Deacon + Shade 82 / 51 / 58.
- **Moment:** E7 at the ford fight: a rift ring behind G1, "Umbral Passage: bring the army over the water.".
- **Intro card:** `Gloom Deacon. Heals your soldiers with their enemies' blood, and opens a road through the dark.`

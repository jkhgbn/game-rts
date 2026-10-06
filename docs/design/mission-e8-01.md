# Campaign mission e8m1: "The Four Roads" (one spec, four variants; Episode 8, the finale)

Written 2026-10-02 (`campaign-outline.md` 3.8 and 4.2). Episode 8 "The Four Keys", mission 1 of 3 per playthrough. The
player has just picked a wizard on the Story menu's **"Whose road do you walk?"** card (`ep8_opening`, outline 4.1); this
mission is that wizard's road to Crown Hollow, and each road is the wizard's prologue weakness **turned around**
(`prologue-3min.md` S16 / S20 / S24 / S28). Four variants, four scenes, one shared base script:
| Variant | Mission id | Wizard (track) | Road title | Weakness (prologue line) | Map | Target (normal) |
|---|---|---|---|---|---|---|
| A | `e8m1_fire` | Vessa | **The Spark Waits** | "But she never waits." (S16, L15) | Crown Hollow, the west bank of the Hollowmere | **18-22 min** |
| B | `e8m1_shadow` | Malrik | **Put Down the Shovel** | "But he is never full." (S20, L19) | Duskbarrow, Malrik's crypt city | **18-22 min** |
| C | `e8m1_ice` | Torvald | **The Gate Opens** | "But he waits too long." (S24, L24) | The Hundredwinter Gate and Kettlewick | **18-22 min** |
| D | `e8m1_nature` | Ysolde | **Take a Side** | "But she will not take a side." (S28, L28) | The Closed Road, out of the Sighing Wood | **18-22 min** |
Uses `mission-01.md` / `mission-e3-01.md` / `mission-e2-01.md` (MissionBase, scripted groups, the 70 % rule, difficulty
multipliers), `mission-04.md` (Crown Hollow at war, Ruin Wardens, Warden Gates, the Hollow meter), `tiers.md` 6,
`caster-units.md` 5, `t3-helpers.md` 2-4 (the four helpers), `tier3-extras.md` (Veyra Nightquill), `items.md` campaign
rules, `champions.md` 11 (companion), `map-fill.md` 2 (river, crossings). Scenes `missions/mission_e8_01_<k>.tscn`,
scripts `scripts/campaign/mission_e8_01_<k>.gd` (`MissionE801Fire` / `Shadow` / `Ice` / `Nature`, each `extends
MissionE801`, which `extends MissionBase`; ids `e8m1_<k>`, outline D6). Metres, seconds, `m:ss` since the navmesh was
ready; positions `(x, z)`, `y = 0`, `+z` = south. Status: **design only**; nothing here is built. Recommended option taken
everywhere (no questions).

## 0. Decisions (recommended option taken)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | One spec, four scenes | One shared script `MissionE801` (track load, relic slot, Citadel + helper, Host and Stone-sworn types, the road-end save) and four thin variant scripts with their own map, objectives, waves and lines | The four roads share 60 % of their rules; one base keeps the finale's tests in one place |
| D2 | Which save | The picker writes `ep8_road` (`&"fire"` / `&"shadow"` / `&"ice"` / `&"nature"`) and loads **that wizard's track** (outline D8): its 6 item slots, owned artifacts, essence (already 50 %, cap 1 500), companion. The other three roads unlock for **replay** after the ending (Missions list, same track rule; no track = the fallback row of each variant) | D8; each road is the end of its own wizard's journey |
| D3 | The key relic | Artifact slot 1 is **forced** to the road's key: `ember_crown` / `keystone_shard` / `stillwater_orb` / `masters_signet` (greyed on the choice screen, tooltip `Your key. It goes where you go.`). Slot 2: any other owned artifact (Ysolde: `heartwood_seed`); **an empty slot 2 gives +300 essence** at the start (`The relics went home. The road provides.`) | `ep8_opening`: Vessa gives the Orb back to Torvald and the Signet to Ysolde; Vessa and Malrik own no second artifact any more, Ysolde does |
| D4 | Keys are not loot | In every Ep8 mission the key relic cannot drop, be sold or be swapped out (the Ember Crown's drop rule is off: `campaign_only` + `key_relic = true`) | A lost key would end the story, not the mission |
| D5 | Level | Wizard **level 5 with 4 unspent spell points** (spell 1 rank 1 known), **cap 8** (the max) | Levels are never carried; the finale opens at the top of the curve |
| D6 | Tiers | Keep **starts as a Stronghold** (`Keep.set_start_tier(2)`), `max_tier = 3`: the Citadel at the normal 300 crystals / 90 s / 5:45 floor. Hall tier-2 units, the "+" upgrades and the kingdom caster (keep **B**) open at 0:00 | Every kingdom earned its Citadel in its own episode (outline D7); the Citadel is still a decision, not a gift |
| D7 | Helper | Each road's helper is **callable at the Citadel** (keep **V**) at the mission price **250 crystals + 100 essence, 30 s**, pop 4 (e2m1 D4), skirmish revive. Vessa: **Old Vey**; Ysolde: **Maelis**; Torvald: **Aldra**; Malrik: **Veyra Nightquill**, the Mage Archer (D8). `helpers_enabled = true`, `t3_enabled = true`; `titans_enabled` stays **false** (titans open in e8m2) | "Everything of that kingdom, its helper" (outline 3.8) |
| D8 | Malrik's helper | **Mother Hush has gone over to the stone** and is the Shadow road's boss (outline 4.2). The Shadow Citadel's V calls **Veyra Nightquill** (`tier3-extras.md` Mage Archer, Shadow's unique NPC) as "the Bishop's other knife", same price and revive as D7. Hush flees at 25 % HP and returns in e8m3 (her "when the dark gets loud" promise) and in the ending (E19, the doorway) | Keeps the outline's boss and gives Malrik a helper; the same canon holds in all four playthroughs (Hush fled on every road) |
| D9 | Who the enemy is | **No enemy bot, no enemy economy** on any road: every enemy is scripted (team `ENEMY`, group `"scripted"`, never under a Commander). Two enemy families: the **Hollow Host** (Ruin Wardens, Warden Gates, the new Rubble Sentinel) and the **Stone-sworn** (the half of Malrik's army that followed the heart-stone's voice: Shadow units with the `stone_sworn` modifier) | The Host does not build; a bot would fight the story's pacing |
| D10 | Champions | Tavern off (`tavern_enabled = false`); the track's **companion** walks in beside the wizard (`champions.md` 11) | Four roads, four focused mechanics; hiring returns in e8m2 |
| D11 | Weakness as a rule, not a lecture | Each road's weakness is a **mechanic with a visible meter or clock** and a **secondary objective** that rewards the turned-around behaviour; the primaries can be won either way on normal | The outline: "each wizard's weakness, overcome": the player feels the pull, then chooses |
| D12 | Seeds and maps | Fire reuses `data/maps/crown_hollow.map` (the M4 post-Rise state); Shadow / Ice / Nature are new 120 x 120 generator maps, seeds **1812 / 1813 / 1814**, not mirrored (E8.M1 bakes them into `data/maps/duskbarrow.map`, `hundredwinter_gate.map`, `closed_road.map`) | Fire's road ends where the finale is fought; the other three start at home |
| D13 | Names | New places (our own): **Duskbarrow** (Malrik's crypt city; `e3m3` "The Stone's Price" must reuse this name), **Kettlewick** (the town beyond Torvald's gate; `e6m2` must reuse it), **the Closed Road** with the hamlets **Pipwell**, **Fernby**, **Hollins Cross** and the river **Thistlewater** | Section 9 lists the consistency notes for the doc owners |

## 1. Shared rules (`MissionE801`)
### 1.1 Story setup shared line
Every briefing ends with the same line: `Four keys. One door. Yours is on this road.` The briefing objectives are the
variant's primaries plus `<Wizard> must survive`.

### 1.2 Start order and fallback
Order in `_on_navigation_ready` (the e2m1 order): spawn the wizard -> `CampaignState.open(...).apply_to_start(self)`
(track `ep8_road`) -> force the key relic in slot 1 (D3) -> companion -> story units -> scripted groups.
| No track (menu debug, tests, a replay with no save) | The key relic + the slot-2 artifact of the table below; 6 empty slots; essence 150 + **900**; no companion; every flag false |
|---|---|
| Fire | `ember_crown` (slot 2 empty -> +300) |
| Shadow | `keystone_shard` (slot 2 empty -> +300) |
| Ice | `stillwater_orb` (slot 2 empty -> +300) |
| Nature | `masters_signet` + `heartwood_seed` |

### 1.3 Tiers, caster, helper (all four)
| Item | Value |
|---|---|
| Code | `MissionE801._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = true`, `helpers_enabled = true`, `tavern_enabled = false`, `titans_enabled = false`; `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(2)` on the player keep |
| Keep card | Z worker · X **Citadel** (gold pulse when it can start) · C the kingdom's tier-3 unit (**Ashveil Saboteur / Nightblood Reaver / Shardguard / Briar Roc**, greyed `Requires Citadel`) · V **Call <helper>** (greyed `Needs a Citadel`), then `Revive <helper>` · B the caster (**Kilnwarden / Gloom Deacon / Rimecarver / Bramblesage**) · Set Rally r3c1 |
| Hall card | The skirmish card of the kingdom (tier-2 units open at 0:00); "+" page open |
| Citadel hint | Once, when the upgrade can start: message 12 s `Your Stronghold can become a Citadel: select the Keep and press X (300 crystals, 90 s). It opens <tier-3 unit> (C) and lets you call <helper> (V).` |
| Helper | Arrival set-piece of `t3-helpers.md` 10.2 (no camera takeover); kit at the wizard's level (L5+: signature ability); stance Escort; F4 = centre on it; fallen = revive `120 + 20 x level` essence, `25 + 5 x level` s, never a defeat |
| Level cap | 8; the wizard starts L5 with 4 points (D5) |

### 1.4 The Hollow Host and the Stone-sworn (shared enemy types; also used by e8m2 / e8m3 as team NEUTRAL)
| Type | Source | Numbers (normal) | Value (sizing) | Notes |
|---|---|---|---|---|
| Ruin Warden | `ruin_warden.tres` (`balance-1.md`) | 300 HP, 16 damage | **150** | Host infantry; kill XP / essence as `balance-1.md` |
| **Rubble Sentinel** (`rubble_sentinel`, **new**) | Gameplay UnitType + art | **900 HP**, armor **20**, Crush **30** + 50 % splash r 1.5, cooldown 2.2, range 2.5 (melee), speed 3.4, sight 12, radius 1.0, height 4.0, pop 0, kill XP **120**, kill essence **30**; CC `hero_mult` (half), knockback immune | **400** | A 4 m stooped Warden of fused pillar stone, the Keystone Colossus's language at a third of the size; amber core |
| Warden Gate | `mission-03.md` / 19.C6 | **1 800 HP**, armor 20, structure (Slag Rain no effect); spawns from its front point (2 m) | - | Breakable spawner |
| Throne Crack | **new** prop (systems) | Invulnerable spawner, an amber fissure decal r 3 with a 1 Hz glow; not a target | - | Fire road (the isle pit); e8m2 / e8m3 reuse it |
| **Stone-sworn** | Shadow UnitTypes + modifier `stone_sworn` (`max_hp_pct` +0.15, `attack_damage_pct` +0.10) and the model hook `set_stone_sworn(true)` (amber eyes, amber cloak trim) | Shade / Nightbolt / Grave Hound / Shadow Knight / Barrow Ghoul / Barrow Knight / Hexweaver / Gloom Deacon | cost x 1.15 | Team ENEMY on the roads; their Deacons cast with the `AIStoryCaster` rules |
Host units: `neutral_leash` false; on the roads they are team `ENEMY` (one hostile team per mission). Kill income as
`items.md` (Host by the values above / 10, Stone-sworn by cost).

### 1.5 The road-end save (all four)
Victory saves the track (`resume = &"c_e8_muster"`): the 6 slots, the key relic (owned, equipped), the slot-2 artifact,
essence 50 % cap 1 500 (+ the variant's bonuses first), the companion (`champions.md` 11), and the flags of the variant
plus `e8m1_done = true`, `e8_road = <k>`, `e8_hush_fled = true` (canon on every road). StoryFlow then plays
`c_e8_muster` "Especially Malrik" (outline 3.8, 1:20; its beats are in `mission-e8-02.md` "Cinematic hooks") and loads
`e8m2`. A replay from the Missions list ends on the normal victory screen (no muster film).

---

## A. Fire: "The Spark Waits" (`e8m1_fire`, Vessa + Old Vey)
### A.1 Story setup (briefing, 3 short paragraphs)
1. Vessa gave two relics away in one morning and kept the third. Then she did what she always does: she rode for Crown
   Hollow at once, and got there two days before anyone else.
2. The Hollow is waking under the isle. Every few minutes it climbs out of the pit and tries the bridges. Old Vey drove
   six storm-stakes into the west bank: on this side of the water, the Hollow cannot feed.
3. Three keys are still on the road. Until they come, there is only one thing to do, and Vessa has never once done it.
   Wait.

### A.2 Map: "Crown Hollow, the west bank" (`data/maps/crown_hollow.map`, the skirmish seed, river on)
The `mission-04.md` map in its **post-Rise state** (the isle is the pit of the fallen Colossus: no pillar ring, no
pedestal, the cross-shaped amber crack, the moat glowing faintly; 19.V4 pit state). Off: capture points, camps, beasts,
trade, research, cavalry, titans, taverns, Pell. Light: grey spring dawn (sun `(0.95, 0.88, 0.80)`, energy 1.0), the
moat glow `(1.0, 0.75, 0.3)`; storm clouds roll in from 12:00 (19.V25 layer at 40 %, 100 % in `e8m1_fire_storm`).
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / Fire keep | `(-36, 36)` / `(-43, 43)` | 18 | Pre-built, **Stronghold** (3 000 HP) |
| Ember Hall / Ember Spire / Hearth | `(-27, 45)` / `(-37, 29)` / `(-50, 46)` | - | Pre-built, complete (M4 slots H1 / S1 / V1); Hearths max **6** |
| Nodes `e8f_fire_a` / `e8f_fire_b` | `(-46, 34)` / `(-34, 46)` | - | **1 500** each |
| Node `e8f_mid` (natural) | `(-16, 6)` | 7 | **2 000**; hall spot X1 `(-23, 9)`. 5 m from the moat: the most exposed node |
| Node `e8f_rich` | `(-40, -40)` | 7 | **2 000**; hall spot `(-33, -40)` |
| Lost Caches | `(-30, 0)`, `(-6, 27)` (west bank pair only) | 3 | `items.md` loot, from 2:00, reopen 180 s |
| **Storm Stakes** S1-S6 | Computed: the west-bank end of each crossing that touches the west bank (Saltgate Bridge, Reed Ford, North-west Crown Steps, West Crown Bridge, Willow Ford, Millstone Bridge) + **7 m toward the Fire hub**, snapped with `RiverSystem.nearest_land` | 2 | Decor + rule (A.4): 2.5 m rods of blackened steel, runes crackling white-gold; no collider, no nav effect |
| **Throne Crack** (Host spawn 1) | `(0, 0)` (the isle pit) | - | Invulnerable; Host from here crosses the West Crown Bridge or the North-west Steps |
| **Warden Gate WG-N** (Host spawn 2) | `(12.75, -21.25)` (M4's P3 spot, east bank) | 3 | 1 800 HP; front faces `(-1, 0)` (west); its Host crosses Reed Ford or Saltgate Bridge |
| **Warden Gate WG-S** (Host spawn 3) | `(15, 34)` (M4's P4 spot, east bank) | 3 | 1 800 HP; front faces west; its Host crosses Willow Ford or Millstone Bridge |
| Stone-sworn spawn | The Dusk Keep **ruin** `(43, -43)` (decor rubble, not a building) | - | Their Host-allied raids cross Saltgate Bridge |
| Ashby's scouts | The wagon road at `(30, -4)` (east bank) | 4 | Story event A.6 E8 |
| Vey's descent point | The pit edge `(-6, 6)` | - | He walks down into the crack at E1 |
Path distances (navmesh): Throne Crack -> Fire keep 61 m (the lane); WG-N -> keep via Reed Ford 104 m; WG-S -> keep via
Willow Ford 82 m. The three Host spawns are all on the far side: **the west bank is the whole fight**.

### A.3 Start state
| Item | Value |
|---|---|
| Vessa | L5, 4 unspent points (Fireball r1), cap 8; slot 1 `ember_crown` (forced); slot 2 empty (+300 essence) |
| Crystals / essence | **450** / 150 + carried (+300) (easy 550, hard 350) |
| Buildings | Keep (Stronghold), Ember Hall, Ember Spire, Hearth (all complete) |
| Units | 6 Cinder Hands gathering (3 / 3 on the home nodes); **8 Flame Guards, 4 Ember Archers, 2 Blaze Riders, 2 Pyre Adepts, 2 Ash Hurlers, 1 Kilnwarden** at `(-30, 30)` (2 170 crystals of army) |
| Population | **28 / 40** (computed from `UnitType.pop`) |
| Story units | **Old Vey** (story NPC, invulnerable, not selectable) beside Vessa until E1's film ends; **Captain Ashby** (`ashby_story`: a Flame Guard officer model, team PLAYER, not commandable, 600 HP, stays at the Ember Hall rally, at 1 HP kneels 8 s) |
| Companion | From the track, beside Vessa |

### A.4 Mechanics
**The line.** "West bank" = `RiverSystem.bank_of(pos) == 0` (the player's side). Everything else (east bank, isle, water,
fords) is **beyond the line**. The six Storm Stakes mark it (cosmetic); the rule reads the bank, not the stakes.

**The Hollow Hunger** (a meter 0-100 %, objectives-panel line `The Hollow hungers: 12 %`, orange at 50 %, red at 75 %):
| Source | Amount |
|---|---|
| Each pop of player units beyond the line (soldiers, casters, workers, the companion; Old Vey counts 4) | **+0.04 % / s** |
| Vessa beyond the line | **+0.4 % / s** (on top) |
| A player unit dies beyond the line | **+2 %** |
| Deaths on the west bank, Host deaths anywhere, time | **0** ("on this side of the water it cannot feed") |
| Meter at **100 %** | **The Surge**: the stakes go dark for 60 s (deaths on the west bank also feed +1 % during it); an **Overrun** wave spawns at all three Host spawns (x 1.5 of the next scheduled wave) and attack-moves to Vessa; the hold countdown **pauses** for those 60 s; then the meter drops to **40 %** |
Messages (4 s): 25 % `The water is warm under your feet.`, 50 % line L11, 75 % `The stakes are flickering.`

**The Gathering Storm** (waiting pays): a second bar under the hunger line, `Vey's storm gathers: 60 %`. It fills
**100 % in 120 s while Vessa stands on the west bank**, empties to 0 the moment she crosses the line. At 100 % the storm
strikes the largest Host clump (>= 3 Host units) that stands within 25 m of any stake: **8 bolts x 60** over 2 s
(Wardens and Sentinels x 2), the bar restarts. No clump in reach: the bar waits full. First strike: L18.

**Warden Gates.** Breaking WG-N or WG-S (beyond the line: it costs hunger) moves **50 %** (rounded down) of that gate's
later wave share to the Throne Crack. Allowed, never required.

### A.5 Objectives
| id | Type | Text | Done when |
|---|---|---|---|
| `obj_line` | Primary | `Hold the west bank until the keys arrive (14:00)` (countdown; `(paused)` during a Surge) | The countdown ends (starts at E2) |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `obj_keep` | Primary, always shown | `The Fire keep must stand` | Fails = defeat |
| `sec_waited` | Secondary | `The spark waits: keep the Hollow under 50 %` | The hold ends and the meter **never** reached 50 %; **failed** the moment it does |
| `sec_scouts` | Secondary (appears at E8) | `Bring Ashby's scouts home (0 / 4)` | **3+** of the 4 scouts reach the west bank |
| `sec_storm` | Secondary (appears at E5) | `Raise a Citadel and call Old Vey` | Old Vey arrives |

### A.6 Guards, waves and events (normal; easy x 0.6, hard x 1.4 of every count, rounded, min 1)
`T` = the start of the hold (E2, ~0:45). Every wave attack-moves to the Fire keep by the nearest crossing from its spawn,
retargets the nearest player unit within 12 m, and is refreshed every 3 s. Splits across spawns are listed.
| Wave | When | Spawn -> units | Value |
|---|---|---|---|
| H1 | T + 1:00 | WG-S: 6 Wardens | 900 |
| H2 | T + 2:30 | Crack: 8 Wardens | 1 200 |
| H3 | T + 4:00 | WG-N: 6 Wardens + 1 Sentinel | 1 300 |
| H4 | T + 5:30 | Crack: 6 Wardens · WG-S: 4 Wardens + 1 Sentinel | 1 900 |
| H5 | T + 7:00 | WG-N: 4 Wardens · Stone-sworn (ruin): 4 Shades + 2 Nightbolts + 1 Gloom Deacon | 1 520 |
| Pursuers | T + 8:00 (E8) | Ashby's wagon: 6 Wardens chasing the scouts | 900 |
| H6 | T + 9:00 | All three: 4 + 4 + 4 Wardens; Crack + 1 Sentinel, WG-N + 1 Sentinel | 2 600 |
| H7 | T + 11:00 | Crack: 8 Wardens · WG-N: 2 Sentinels · Stone-sworn: 4 Shades + 2 Nightbolts + 1 Shadow Knight | 3 300 |
| H8 | T + 12:30 | All three: 5 + 5 + 4 Wardens, 1 Sentinel each | 3 300 |
| Overrun | Each Surge | All three: x 1.5 of the next wave, at once, target Vessa | - |
| Great Storm | T + 14:00 | - | Victory film (E13) |
A broken gate's share moves to the Crack at 50 % (A.4). Host raids never target workers on purpose; the H7 Stone-sworn
target the rich node `e8f_rich` first (their old habit), then the keep.

| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (`ep8_opening` and the picker played before; briefing.) Cutscene `e8m1_fire_stakes` (HOLD 0:25): L1-L5; end state: the 6 stakes stand, Old Vey walks into the crack at `(-6, 6)` and despawns. RTS camera on Vessa; hint `The Hollow can't feed on the west bank. Hold the line at the water: crossing feeds it.` (10 s) |
| E2 | Film end | `obj_line` 14:00 countdown starts (`T`); Hunger and Gathering Storm bars shown |
| E3 | H1 first seen | L6-L7 |
| E4 | Vessa beyond the line the first time | L10 (Vey's voice from below), once |
| E5 | 3:30 | `sec_storm` active; when the Citadel can start, the 1.3 hint |
| E6 | T + 4:00 (with H3) | **The Taunt**: WG-N cracks to 50 % HP (900) with an amber flare; L8-L9 |
| E7 | Hunger 50 % (first) | L11; `sec_waited` failed |
| E8 | T + 8:00 | **The Stranded**: 4 Blaze Riders (`ashby_scouts`, team PLAYER, **not commandable** until they touch the west bank) appear at the wagon `(30, -4)` with the 6 pursuers; L12-L14; `sec_scouts` active. At T + 8:30 the scouts break out toward **Willow Ford** at 6 m/s (Millstone Bridge if a Host unit stands within 8 m of the ford's west end), fighting only what blocks them. Reaching the west bank: commandable, counted |
| E9 | 3rd scout home | L15; `sec_scouts` done |
| E10 | Citadel complete | Completion message; L16 is held for E11 |
| E11 | Old Vey arrives (helper arrival at the keep door) | L16-L17; `sec_storm` done |
| E12 | First Gathering Storm strike | L18 (once) |
| E13 | Countdown ends (T + 14:00) | World held; cutscene `e8m1_fire_storm` (0:40): L20-L24; `Events.mission_ended(true)` at its end |
| E14 | A Surge | L19 (first only); the Overrun |
| E15 | Fire keep under 30 % (once) | L26 |
| E16 | Vessa dies | L25; defeat after 3 s |
| E17 | Fire keep destroyed | Defeat after 3 s |
H8 (T + 12:30) adds narrator L20 at its spawn instead of at E13 when it fires; L20 then is not repeated.

### A.7 Economy and units
| Item | Value |
|---|---|
| Start | 450 crystals, 150 + carried + 300 essence, 28 / 40 pop |
| Nodes | Home 2 x 1 500, natural 2 000 (moat side), rich 2 000 (north-west corner): ~3 400 crystals mined by 16:00 with 8-10 workers |
| Units | Cinder Hand; Ember Hall (skirmish card incl. Blaze Rider, Ash Hurler, Scorchbow if the kingdom card has it, Pyre Adept, Cinder Arbalest); keep: Kilnwarden (B), Ashveil Saboteur (C, Citadel) |
| Spells / items | Fireball, Ember Step, Kindle; base shop at the keep and the Ember Hall; caches |
| Essence (by 20:00) | ~1 200 start + carry, + trickle ~1 100 + kills ~1 000 = **~3 300** |
| Expected army | ~3 500 crystals at T + 7:00, ~5 000 at T + 13:00 (cap 40 -> 80 with 2 more Hearths) |

### A.8 Dialogue (26 lines; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist): `narrator`, `vessa`, `vey`, `ashby`, `obren` (the whisper voice),
`torvald`, `ysolde`, `malrik`. Colours: `mission-e2-01.md` table (Vey `(0.95, 0.95, 0.55)`, Ashby `(0.95, 0.60, 0.35)`,
Obren `(1.0, 0.80, 0.25)`). Every line <= 96 characters.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Spring at Crown Hollow. Three keys are still on the road. One is already here, of course. |
| L2 | E1 | vessa | Two days early. I'm always early. That's the problem, isn't it? |
| L3 | E1 | vey | Six stakes, one line. The Hollow can't feed on this bank. Don't hand it the other one. |
| L4 | E1 | vessa | So I just... stand here. For fourteen minutes. |
| L5 | E1 | vey | The spark first, then the storm. Today the spark waits. I'll be below, talking to the sky. |
| L6 | E3 | obren | Little ember. You came alone. You always come alone. |
| L7 | E3 | vessa | Not alone. Early. There's a difference. I'm told. |
| L8 | E6 | obren | My door is open, Queen of Fire. Come and close it. You know you want to. |
| L9 | E6 | vessa | I really do. I'm not going to. Somebody write that down. |
| L10 | E4 | vey | Girl! The water is the line. Every step past it, it eats. (4 s) |
| L11 | E7 | obren | Yes. Closer. Hungry fire feeds me best. |
| L12 | E8 | ashby | Scouts on the far bank, my queen! Pinned at the old wagon road! |
| L13 | E8 | vessa | Hold the ford for them. They run to us. We do NOT run to them. |
| L14 | E8 | ashby | Did the queen just say "we do not run"? I'm putting that in the regiment book. |
| L15 | E9 | ashby | Every rider home! The queen waited! Somebody ring a bell! |
| L16 | E11 | vessa | Vey! I called. And look: still on my side of the river. |
| L17 | E11 | vey | I see it. First time in twenty years. Don't spoil it. |
| L18 | E12 | vey | That's what waiting buys you, girl. Lightning, on time. |
| L19 | E14 | obren | The line is broken. Feed me, little ember. Feed me everything. |
| L20 | E13 / H8 | narrator | The last tide climbs out of the Hollow. On the hills behind it, three banners rise. |
| L21 | E13 | torvald | Ice, on the north road. You waited for us, child? Truly? |
| L22 | E13 | ysolde | She waited. I watched her do it. I may need to sit down. |
| L23 | E13 | malrik | Don't all stare. I was invited. Especially, I'm told. |
| L24 | E13 | vessa | Four keys. One hole in the ground. Let's go and knock. |
| L25 | E16 | vessa | Too early... too early again... |
| L26 | E15 | ashby | They're at the keep! Emberguard, hold! HOLD! |
Echoes: L5 is the motto (ep1 V1, M1, e2m1 L19) bent toward waiting; L13 answers pro. S16 (her Flame Guards shouting
after her) with her own order; L17's "twenty years" counts from her first spark (ep1); L23 seeds `c_e8_muster`
"Especially Malrik". Old Vey's helper barks are his `t3-helpers.md` 10.4 hooks.

### A.9 Cinematic hooks (ENGINE on the live scene, CinematicPlayer 19.C1; skippable; units frozen while they play)
| id | When | Mode / length | Shots | Lines | End state (identical on skip) |
|---|---|---|---|---|---|
| `e8m1_fire_stakes` | E1 | HOLD 0:25 | 1) CRANE down over the grey pit, the amber crack breathing; 2) MS Vey drives a stake at the West Crown Bridge foot, white-gold runes flare, a line of light runs along the bank to the other five (one 1.5 s VFX each); 3) MS two-shot Vessa / Vey at the pit edge, 3/4; 4) WS Vey steps down into the crack's light | L1-L5 | 6 stakes placed; Vey despawned; hold not yet started (E2 fires on end) |
| `e8m1_fire_storm` | E13 | PAUSE 0:40 | 1) WIDE from the west bank: white-gold lightning walks across the east bank, every Host unit struck (bolt VFX on 12 of them, the rest fade); 2) LONG LENS north: Torvald's blue banner on the Saltgate road, Aldra beside him; 3) south-west: Ysolde's green banner, Wren on her stag; 4) east: a violet banner alone on the ruin of the Dusk Keep, Malrik under it; 5) CU Vessa, the Crown glowing; FADE_BLACK | L20-L24 | Every Host and Stone-sworn unit removed (no XP); WG-N / WG-S rubble; mission won and saved (1.5) |
Fallbacks: missing set marks -> camera on Vessa + the lines as dialogue; missing bolt VFX are skipped.

### A.10 Win / lose
| Event | Result |
|---|---|
| `obj_line` done | **Victory** (after `e8m1_fire_storm`) |
| Vessa dies | **Defeat** (instant, `instant_loss_on_wizard_death = true`) |
| Fire keep destroyed | **Defeat** |
| Old Vey fallen, Ashby kneeling, scouts dead | Nothing |
| Both Warden Gates broken | Allowed; their shares go to the Crack (A.4) |

### A.11 Rewards / flags
`MISSION_REWARDS[&"e8m1_fire"] = {"flags": {"e8m1_fire_waited": "sec_waited", "e8m1_fire_scouts": "sec_scouts",
"e8m1_fire_vey_called": "sec_storm"}, "bonus_essence": {"sec_waited": 300, "sec_scouts": 200}, "set_flags":
{"e8m1_done": true, "e8_road": &"fire", "e8_hush_fled": true}, "next": &"e8m2"}`. e8m2 hook: `e8m1_fire_waited` = Vey's
Gathering Storm also runs in e8m2 (`mission-e8-02.md` 5.4).

### A.12 Difficulty and sizing
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave counts | x 0.6, no Sentinel in H3 / H4 | as written | x 1.4 |
| Hold | 12:00 | 14:00 | 15:30 (+ H9 at T + 14:00 = H6 again) |
| Hunger rates | x 0.75 | as written | x 1.25 |
| Gathering Storm | 100 s | 120 s | 150 s |
| Start | 550 crystals, +2 Flame Guards | 450 | 350, no Ash Hurlers |
| Expected time | 15-18 min | 18-22 min | 21-25 min |
| Fight | When | Enemy | Player then (crystals + Vessa L5-L6) | Ratio |
|---|---|---|---|---|
| H1 | ~1:45 | 900 | 2 170 + 450 | 41 % (must leave **15+ of 19** start soldiers) |
| H3 + Taunt | ~4:45 | 1 300 | ~3 000 | 43 % |
| H6 | ~9:45 | 2 600 | ~4 200 + Vey | 62 % |
| H8 | ~13:15 | 3 300 | ~5 000 + Vey | 66 % |
- The intended answer is the defender's: Ash Hurlers and Archers behind the ford mouths, Flame Guards at the water's edge,
  Fireball on Host bunched in the fords (slowed -35 %), Kilnwarden Slag Rain on Sentinels (armor 20 -> 0). Crossing to
  break a gate is legal and sometimes right (the Taunt makes WG-N cheap), but it costs ~10-15 % hunger each time.
- The scouts are the real test of waiting: the correct play is to clear Willow Ford's west mouth and let them come.
- Watch in the first playtest: if `sec_waited` is trivial (no player crossed in 5 / 5 runs), raise the Taunt (WG-N to 30 %)
  before touching the rates.

---

## B. Shadow: "Put Down the Shovel" (`e8m1_shadow`, Malrik + Veyra Nightquill; boss Mother Hush)
### B.1 Story setup
1. Malrik came home to Duskbarrow with Obren's heart-stone in his pocket, and his city's dead got up to meet him. Not
   for him: for the stone. Their eyes are amber now.
2. Half his army heard the stone and went with it. Mother Hush leads them. She holds the Gravedigger's Stair, the only
   road out of the city, and she wants the stone for herself.
3. The others are waiting at Crown Hollow for the fourth key. All Malrik has to do is carry it there, and not use it.
   For a man who has never once had enough, that is the whole mission.

### B.2 Map: "Duskbarrow" (120 x 120, the `main.gd` generator, seed **1812**, not mirrored; `data/maps/duskbarrow.map`)
A walled city of crypts climbing a hill to the north-east: narrow cobbled lanes (width 6) between mausoleum blocks
(impassable, building-sized rocks of the generator's `crypt_block` kind), cypress and dead yew instead of trees, violet
lanterns. Night, low violet moon `(0.75, 0.65, 0.95)` energy 0.8; amber light from the open Barrow Doors.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / **Dusk Keep** "the Bishop's Keep" | `(-36, 36)` / `(-43, 43)` | 18 | Pre-built, **Stronghold** (3 000 HP) |
| Gloom Hall / Night Spire / Hovel | `(-27, 45)` / `(-37, 29)` / `(-50, 46)` | - | Pre-built; Hovels max **6** |
| Nodes `e8s_a` / `e8s_b` | `(-46, 34)` / `(-34, 46)` | - | **1 500** each |
| Node `e8s_ossuary` (expansion) | `(-10, 40)` | 7 | **2 000**; hall spot `(-17, 44)`; "Ossuary Square" |
| Node `e8s_chapel` (rich) | `(-44, -6)` | 7 | **2 000**; hall spot `(-37, -8)`; 12 m from BD1 (contested by its Risen) |
| **Barrow Door BD1** "The Old Ossuary" | `(-30, -10)` | 6 | Host-style door (section B.4) |
| **Barrow Door BD2** "Candle Row" | `(10, 10)` | 6 | The city's centre square |
| **Barrow Door BD3** "The Gravedigger's Yard" | `(36, 26)` | 8 | Malrik's father's grave; the story door |
| **Stair Gate** | `(38, -36)` | 6 | Warden Gate stats (1 800 HP, armor 20), Shadow look (a black iron portcullis in a crypt arch); **amber-warded (invulnerable) while any Barrow Door is open** |
| Hush's garrison | Ring r 6 around `(32, -30)` | - | B.6 G4 |
| **The Gravedigger's Stair** (exit) | Top at `(50, -50)`, zone r 5 | - | Victory zone (Malrik inside it) |
| Stone-sworn camp (raid spawn) | `(48, -12)` | - | Behind the east wall |
| Lost Caches ("grave goods") | `(-8, 18)`, `(24, -8)` | 3 | `items.md` loot, from 2:00 |
Path distances: start -> BD1 46 m, -> BD2 53 m, -> BD3 75 m; BD2 -> Stair Gate 52 m; Stair Gate -> exit 20 m.

### B.3 Start state
| Item | Value |
|---|---|
| Malrik | L5, 4 unspent points (Shadow Lance r1), cap 8; slot 1 `keystone_shard` (forced); slot 2 empty (+300) |
| Crystals / essence | 450 / 150 + carried + 300 |
| Buildings | Dusk Keep (Stronghold), Gloom Hall, Night Spire, Hovel |
| Units | 5 Gloom Thralls gathering; **6 Shades, 4 Nightbolts, 2 Grave Hounds, 1 Shadow Knight, 2 Hexweavers, 1 Gloom Deacon** at `(-30, 30)` (1 680 crystals) |
| Population | **24 / 40** |
| Story unit | A loyal Shade captain (`shade` speaker; a Shade model with a violet plume, team PLAYER, not commandable, stays at the Gloom Hall rally, kneels at 1 HP) |
| Fallback flag | `e3m3_stone_used` read from the track (false if missing) |

### B.4 Mechanics
**Barrow Doors** (new prop `BarrowDoor`, systems; a `MissionBrazier` subclass): a crypt door in a mausoleum front, open =
amber light pours out. Every **45 s** an open door raises its **Risen** at its front point: **3 Barrow Ghouls**, plus **1
Barrow Knight** from 6:00 (Stone-sworn modifier; max 10 alive per door). Invulnerable; never destroyed. **Lay to rest**:
Malrik within **3 m for 5 s** (progress ring; leaving resets) while no ENEMY unit is within **8 m** of the door (the ring
stays grey and `Clear the yard first` shows once). Laid to rest: the light goes out, spawns stop, **every living Risen of
that door lies down** (removed over 1 s, no XP, no essence).

**The Stone's Gift** (the shard's active, artifact slot 1; key and button as `e3m3` defines them; if e3m3 has not
defined an active yet, this mission's numbers are the definition): **40 s** cooldown, self: Malrik `spell_power` +40 for
10 s and every unit (any team, not wizards / bosses) that died within 10 m in the last 10 s rises as a **Barrow Ghoul**
under Malrik's control for 25 s (max 6; pop 0). Strong on purpose. **Cost**: each use adds +1 to `e8_stone_uses`
(saved; e8m3: the Hollow King **+5 % HP per use, max +25 %**, `mission-e8-03.md` 3.1), Obren speaks (L7 / L8), and the
amber pulse on Malrik's hand stays bright for 10 s. The tooltip says it plainly: `The stone remembers every time.`

**Hush, Stone-sworn** (boss, `hush_boss`: the `hush_story` model and kit at boss numbers, team ENEMY):
| HP | Armor | Damage | Speed | Abilities |
|---|---|---|---|---|
| **3 200** (easy 2 400, hard 4 200) | 10 | 40 / 1.0 s melee | 5.4 | Mouthless Veil (t3-helpers 4.3); **Blink Strike** every 8 s on Malrik if within 14 m, else the lowest-HP caster (80); **Smoke Cloak** 18 s; **Night of Knives** every 30 s (6 x 50, Malrik x 1.5 + `marked` 4 s); at **75 %** and **50 %** she calls 4 Stone-sworn Shades from the garrison ring |
At **25 %** she becomes untargetable and the cutscene `e8m1_shadow_hush` plays (she flees; she cannot be killed here).

### B.5 Objectives
| id | Type | Text | Done when |
|---|---|---|---|
| `obj_doors` | Primary | `Lay the dead of Duskbarrow to rest (0 / 3)` | 3 doors laid |
| `obj_hush` | Primary (appears when the Stair Gate's ward drops) | `Break the Stair Gate and face Mother Hush` | Hush flees (25 %) |
| `obj_stair` | Primary (after `obj_hush`) | `Carry the stone up the Gravedigger's Stair` | Malrik in the exit zone |
| `obj_malrik` | Primary, always shown | `Malrik must survive` | Fails = defeat |
| `obj_keep` | Primary, always shown | `The Bishop's Keep must stand` | Fails = defeat |
| `sec_shovel` | Secondary | `Put down the shovel: never use the stone's power` | Victory with `e8_stone_uses` unchanged this mission; **failed** on the first use |
| `sec_raids` | Secondary | `Burn the Stone-sworn camp` | The camp's two tents (`stone_tent`, 600 HP each, at `(48, -12)` +- 4 m) destroyed; raids stop |

### B.6 Guards, waves and events (normal; x 0.6 / x 1.4)
| Group | Where | Units | Value |
|---|---|---|---|
| G1 Ossuary yard | BD1, ring r 5 | 4 Barrow Ghouls + 1 Barrow Knight (Risen) | 570 |
| G2 Candle Row | BD2, ring r 6 | 4 Barrow Ghouls + 2 Stone-sworn Hexweavers + 1 Barrow Knight | 860 |
| G3 Gravedigger's Yard | BD3, ring r 7 | 6 Barrow Ghouls + 2 Barrow Knights | 1 000 |
| G4 Hush's garrison | `(32, -30)` r 6 | 6 Shades + 3 Nightbolts + 2 Shadow Knights + 2 Hexweavers + 1 Gloom Deacon (all Stone-sworn); **+2 Shades if `e3m3_stone_used`** ("the stone knows your taste") | 1 870 |
| Wave | When | Units (spawn) | Order |
|---|---|---|---|
| Risen | Every 45 s per open door (B.4) | 3 Ghouls (+1 Knight from 6:00) | Attack-move to the nearest player unit within 25 m, else hold the door |
| R1 raid | 4:00 | Camp: 4 Shades + 2 Grave Hounds | Attack-move to the Thralls on `e8s_a`, then the Gloom Hall |
| R2 raid | 9:00 | Camp: 4 Shades + 2 Nightbolts + 1 Shadow Knight | Gloom Hall, then the keep |
| R3 raid | BD2 laid | Camp: 6 Shades + 2 Nightbolts + 1 Hexweaver (Hush's warning, L12) | Malrik |
| R4 raid | 15:00 | Camp: 4 Shades + 2 Shadow Knights + 2 Nightbolts | The keep |
| Hush calls | 75 % / 50 % | 4 Shades each, from G4's ring | Malrik |
If `sec_raids` is done, R2-R4 do not spawn. Hush stands at `(32, -30)` (veiled) until Malrik is within 20 m of the Stair
Gate or the gate falls; then she engages (boss bar).

| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cutscene `e8m1_shadow_home` (HOLD 0:20): L1-L4; hint `Lay each Barrow Door to rest: Malrik within 3 m for 5 s, with the yard cleared.` |
| E2 | First door seen | L5 (the Shade captain), L6 |
| E3 | Stone's Gift used, first / second time | L7 / L8 (once each); `sec_shovel` failed on the first |
| E4 | A door laid to rest (BD1 or BD2), first time | L9 |
| E5 | Malrik within 10 m of BD3 | Cutscene `e8m1_shadow_father` (PAUSE 0:15): L10; Obren L10b; after it, the hint (once) `The stone offers. You can say no.` |
| E6 | BD3 laid | L11 |
| E7 | BD2 laid | R3 spawns; L12 |
| E8 | 3rd door laid | The Stair Gate's amber ward breaks (`_seal_flash` amber r 8); `obj_doors` done, `obj_hush` active |
| E9 | Hush engages | L13-L14; boss bar `Mother Hush, Stone-sworn` |
| E10 | Hush 50 % | L15-L16 |
| E11 | Hush 25 % | Cutscene `e8m1_shadow_hush` (PAUSE 0:20): L17-L18; `obj_hush` done, `obj_stair` active |
| E12 | Stair Gate destroyed | L19-L20 |
| E13 | Malrik in the exit zone | Cutscene `e8m1_shadow_stair` (PAUSE 0:25): L21-L22, then L24-L25 if `sec_shovel` holds; victory |
| E14 | Malrik dies | L23; defeat after 3 s |
| E15 | Keep destroyed | Defeat after 3 s |
| E16 | Citadel complete / Veyra arrives | Completion message / her arrival (`tier3-extras.md` warnings, own side) |
The doors can be laid in any order; the Stair Gate can be attacked only after E8, Hush is fought at or after it.

### B.7 Economy and units
| Item | Value |
|---|---|
| Start | 450 crystals, 150 + carried + 300 essence, 24 / 40 |
| Nodes | 2 x 1 500 home, Ossuary 2 000, Chapel 2 000 (BD1's Risen raid it until BD1 is laid) |
| Units | Gloom Thrall; Gloom Hall skirmish card (Shade, Nightbolt, Grave Hound, Shadow Knight, Barrow Ghoul, Bleakbow if on the card; Hexweaver, Hollow Oathsworn tier 2); keep: Gloom Deacon (B), Nightblood Reaver (C, Citadel), **Call Veyra Nightquill** (V, Citadel) |
| Spells | Shadow Lance, Soul Siphon, Umbral Shroud |
| Essence (by 20:00) | ~3 200 (Risen kills pay little: Ghoul 6, Knight 25) |

### B.8 Dialogue (25 lines + 1 short)
Speakers: `narrator`, `malrik`, `obren`, `hush`, `shade` (the loyal captain). Hush `(0.60, 0.50, 0.75)`, Shade (unit
grey) `(0.62, 0.60, 0.70)`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Duskbarrow, city of crypts. Its bishop came home with a stone, and the dead got up to meet it. |
| L2 | E1 | malrik | Every grave here, I dug, or my father did. They know my shovel. They don't know this. |
| L3 | E1 | obren | They are yours, Bishop. Take them back. Use me. Just a little. |
| L4 | E1 | malrik | A little. You always say a little. |
| L5 | E2 | shade | Bishop, the Old Ossuary is open. The dead are wearing amber. |
| L6 | E2 | malrik | Then we put them back to bed. Gently. They were somebody's. |
| L7 | E3 (1st) | obren | There. Doesn't that feel like enough? It never is. Again. |
| L8 | E3 (2nd) | malrik | I know what you are. You're the last biscuit in the tin, forever. |
| L9 | E4 | malrik | Rest. I'm sorry they woke you. It wasn't me. It was what I was holding. |
| L10 | E5 | malrik | Father. You taught me where to dig. You never taught me when to stop. |
| L10b | E5 | obren | Use me, and he will stand up and answer you. One question. Any question. (4 s) |
| L11 | E6 | malrik | I'm learning, late. You'd say that's the family way. Sleep, old man. |
| L12 | E7 | hush | Bishop. You taught me the knife. The stone taught me the rest. |
| L13 | E9 | hush | Give it to me. You never use it right. You use it SMALL. |
| L14 | E9 | malrik | That's the only way to use it, Hush. Small. Then never. |
| L15 | E10 | hush | There is always another night, Bishop! |
| L16 | E10 | malrik | There is. I'd like to sleep through one of them. |
| L17 | E11 | hush | You'll want me back. When the dark gets loud. |
| L18 | E11 | malrik | Go, then. Keep your knives sharp. I may need a friend who isn't a rock. |
| L19 | E12 | obren | You will use me at the end. Everyone does. Your Master did. |
| L20 | E12 | malrik | Then I'll be the first who didn't. I do so like being first. |
| L21 | E13 | malrik | I'm not using you. I'm carrying you. Like a parcel. To the hole you came from. |
| L22 | E13 | narrator | The Bishop walked out of his city with the stone in his fist, and for once the fist stayed shut. |
| L23 | E14 | malrik | Hungry... to the very last... |
| L24 | E13, `sec_shovel` | obren | Not once? Not ONCE? ...What ARE you? |
| L25 | E13, `sec_shovel` | malrik | Full, apparently. Who knew. |
Echoes: L2 / L10 are the gravedigger's son (Ep3's title, pro. S18); L8 / L24-L25 turn pro. L19 "he is never full";
L15 is Hush's own bark (M0 L8, e3m1 L19) and L17 is the promise e8m3 pays (`mission-e8-03.md` E9); L19 hints at the
Master's own weakness (ending L "The harder I held").

### B.9 Cinematic hooks
| id | When | Mode / length | Shots | Lines | End state (also on skip) |
|---|---|---|---|---|---|
| `e8m1_shadow_home` | E1 | HOLD 0:20 | 1) CRANE over the crypt roofs at night, three amber shafts rising from three doors; 2) MS Malrik at his keep gate, candle in one hand, the stone pulsing in the other; 3) CU: he pockets the stone, keeps the candle | L1-L4 | Camera on Malrik; doors open; G1-G4 placed |
| `e8m1_shadow_father` | E5 | PAUSE 0:15 | 1) MS a plain headstone with a shovel leaning on it (the only grave without amber); 2) CU Malrik, front, candlelight; 3) INSERT the stone flaring in his fist | L10, L10b | Nothing changes (a talk scene) |
| `e8m1_shadow_hush` | E11 | PAUSE 0:20 | 1) MS Hush on one knee, mask cracked; 2) two-shot, Malrik lowers his hand; 3) she backs into smoke and is gone; the garrison's survivors scatter | L17-L18 | Hush despawned (flag `e8_hush_fled`); every living Stone-sworn of G4 / Hush calls walks to the camp and despawns; raids stop |
| `e8m1_shadow_stair` | E13 | PAUSE 0:25 | 1) LOW behind Malrik climbing the stair, the city below; 2) CU his fist, shut, light leaking between the fingers; 3) WS from the top: the road to Crown Hollow at dawn; FADE_BLACK | L21-L22 (+ L24-L25) | Victory, save (1.5) |

### B.10 Win / lose
| Event | Result |
|---|---|
| Malrik in the exit zone after `obj_hush` | **Victory** |
| Malrik dies / Bishop's Keep destroyed | **Defeat** |
| Veyra fallen, the captain kneeling | Nothing |
| Hush at 25 % | She flees (cannot die); never a defeat |

### B.11 Rewards / flags
`MISSION_REWARDS[&"e8m1_shadow"] = {"flags": {"e8m1_shadow_shovel": "sec_shovel", "e8m1_shadow_raids": "sec_raids"},
"bonus_essence": {"sec_shovel": 400, "sec_raids": 150}, "set_flags": {"e8m1_done": true, "e8_road": &"shadow",
"e8_hush_fled": true}, "next": &"e8m2"}`. `e8_stone_uses` (int, written live by the mission, never reset by later
missions) feeds e8m3. The track keeps `keystone_shard`.

### B.12 Difficulty and sizing
| | Easy | Normal | Hard |
|---|---|---|---|
| Counts | x 0.6, no Knights before 9:00 | as written | x 1.4 |
| Risen interval | 60 s | 45 s | 35 s |
| Lay to rest | 4 s | 5 s | 6 s |
| Hush HP | 2 400 | 3 200 | 4 200 |
| Expected time | 15-18 min | 18-22 min | 21-26 min |
| Fight | When | Enemy | Player then | Ratio |
|---|---|---|---|---|
| G1 + one Risen tide | ~2:30 | 570 + 180 | 1 680 + Malrik L5 | 45 % (must leave **13+ of 16** start soldiers) |
| G2 | ~7:00 | 860 + tides | ~2 600 | 40-45 % |
| G3 | ~11:00 | 1 000 + tides | ~3 200 + Veyra | 40 % |
| G4 + Hush (3 200 HP, ~70 DPS) | ~15:00 | 1 870 + Hush (~1 100) | ~4 200 + Veyra | 70 % |
- The stone is the temptation the numbers are built around: a Gift at a Risen pile turns a hard yard fight into a free one.
  Every fight above is winnable without it on normal (the 70 % rule holds with no Gift).
- Hush is the skill check: Blink Strike punishes a Malrik who walks in front; the intended answer is Hexweavers and
  Nightbolts behind Knights, the Deacon's Blood Tithe on Malrik, Veyra's Grave Mark on Hush.

---

## C. Ice: "The Gate Opens" (`e8m1_ice`, Torvald + Aldra)
### C.1 Story setup
1. For a hundred winters Torvald kept one gate in one wall, and opened it for nobody. Spring came anyway, and with it a
   column of people walking south out of the cracked north, with the stone's hunters close behind.
2. Vessa sent back his lake's relic, the Stillwater Orb, with one line: "We need all four of you." He has read it eleven
   times.
3. The column will reach the Hundredwinter Gate within the hour. Torvald knows exactly how long he would like to wait.
   This time he will not.

### C.2 Map: "The Hundredwinter Gate" (120 x 120, seed **1813**, not mirrored; `data/maps/hundredwinter_gate.map`)
Snow fields and pine; the **Wall of a Hundred Winters** crosses the map west to east along `z = -18` (an ice cliff 9 m
high, 4 m thick, impassable, `"navigation_geometry"`); north of it the frozen north and Kettlewick, south of it Torvald's
march. Clear cold day, sun `(0.95, 0.97, 1.0)` energy 1.1, blowing snow cards.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / **Rime Keep** | `(-30, 6)` / `(-36, 12)` | 16 | Pre-built, **Stronghold** (3 600 HP) |
| Frost Hall / Rime Spire / Snow Lodge | `(-24, 4)` / `(-12, -8)` / `(-46, 18)` | - | Pre-built; the Spire covers the gate's south mouth; Snow Lodges max **6** |
| Nodes `e8i_a` / `e8i_b` | `(-45, 6)` / `(-34, 24)` | - | **1 500** each |
| Node `e8i_falls` (expansion) | `(-40, 40)` | 7 | **2 000**; hall spot `(-33, 42)` |
| **The Hundredwinter Gate** | `(0, -18)`, gap 8 m in the Wall | - | Gate building `hundredwinter_gate` (invulnerable, not a target): **closed** blocks the gap (nav obstacle), **open** = the gap is free. Starts closed |
| **Gate lever** | `(0, -12)` (south side) | 4 | `MissionBrazier` spot: Torvald within 4 m for 3 s toggles the gate (open / close); 10 s lockout after a toggle |
| **West Icefall** breach | `(-52, -18)`, gap 5 m | - | A frozen-falls ramp through the Wall; open from 0:00 (the hunters' flank) |
| **East Cliff** breach | `(52, -18)`, gap 5 m | - | Same, east |
| **Kettlewick** | Square `(0, -40)`, town ring r 12 | - | Decor town (`e6m2_gate_opened`: standing, smoke from chimneys; else a burnt ruin) |
| The Northway (column spawn) | `(0, -58)` | - | North edge |
| **Hearth Camp** (refugee rest) | `(-6, 20)`, r 7 | 7 | Braziers and blankets (decor) |
| **Southway Crack** | `(6, 36)` | 6 | Host rises here (C.6 W5) |
| **The Long Stair** | `(4, 46)` to `(0, 54)`, width 8 | - | A narrow ice-cut road; the last stretch |
| **Southway exit** | `(0, 56)`, zone r 6 | - | Refugees counted here |
| Hunter spawns | North: `(0, -54)` · West: `(-56, -30)` · East: `(56, -30)` | - | Stone-sworn come down the Northway or over the breaches |
Column route (waypoints): `(0, -58)` -> Kettlewick `(0, -40)` (rest 30 s) -> `(0, -24)` -> gate -> `(0, -6)` -> Hearth
Camp `(-6, 20)` (rest **240 s**) -> `(6, 32)` -> `(4, 46)` -> exit `(0, 56)`. ~130 m south of the gate.
Ice Walls (worker buildings, 20 crystals) may be built in the breaches (the ice-wall rules; the breaches are 5 m:
two segments close one), never on the gate gap.

### C.3 Start state
| Item | Value |
|---|---|
| Torvald | L5, 4 unspent points (Rime Bolt r1), cap 8; slot 1 `stillwater_orb` (forced); slot 2 empty (+300) |
| Crystals / essence | 450 / 150 + carried + 300 |
| Buildings | Rime Keep (Stronghold), Frost Hall, Rime Spire, Snow Lodge |
| Units | 5 Rime Haulers gathering; **6 Rimeshields, 4 Shardcasters, 2 Frostbows, 1 Rime Seer, 1 Frost Mortar, 1 Rimecarver** at `(-20, 0)` (1 750 crystals) |
| Population | **22 / 40** |
| Story units | **Aldra** (story NPC until she is called; see E1); **the rider** (`gate_rider`: a horse rider with a signal torch, team NEUTRAL-invulnerable decor until the gate opens, then team PLAYER, not commandable, walks to the Hearth Camp) at `(0, -22)` (north side of the gate) |
| Flags | `e6m2_gate_opened` from the track (false if missing) |

### C.4 Mechanics
**The column**: **40 refugees** (`refugee`, new UnitType on the `wood_folk` pattern: 60 HP, armor 0, speed **1.6** while
walking with the column (carts, children), no attack, pop 0, team PLAYER, `commandable = false`, kill XP 15 for the killer),
spawned at 3:30 in 5 families of 8 (2 s apart). The column walks the route as one group (head = the first family): it
**stops while any ENEMY unit is within 14 m of its head**, and stops at a **closed gate**. Refugees under attack keep
walking (they do not fight); each has a `follow` fallback to the nearest Ice soldier within 8 m if the route is blocked.
Counted at the exit (r 6); removed there (they walk on south).
**At a closed gate**: the column's tail is caught by its pursuers (the hunter group H0, real units on the north side):
the delay kills people because the hunters are real, not by a timer.
**Kettlewick's militia** (`e6m2_gate_opened` true): when the column leaves Kettlewick, **2 squads of 4 Rimeshields**
(team PLAYER, commandable, pop 0 guests, veterancy 2, `kettlewick_militia` banner) walk with it and become the player's at
the gate. False: the town is a ruin; narrator L9b instead.

### C.5 Objectives
| id | Type | Text | Done when |
|---|---|---|---|
| `obj_gate` | Primary | `Open the Hundredwinter Gate` | The gate opens (any time; the lever) |
| `obj_column` | Primary (at 3:30) | `Bring the column south (0 / 20)` (`saved / needed`, `lost` shown red) | 20 refugees at the exit **and** no living refugee left outside it (or 3:00 after the 20th arrives, the rest counted as lost) |
| `obj_torvald` | Primary, always | `Torvald must survive` | Fails = defeat |
| `obj_keep` | Primary, always | `The Rime Keep must stand` | Fails = defeat |
| `sec_early` | Secondary | `The gate opens: open it before the column reaches it` | Gate open before the column's head is within 10 m of it; **failed** otherwise |
| `sec_thirty` | Secondary | `Bring 30 of the 40 south` | 30+ at the exit |
| `sec_shut` | Secondary (appears when the last refugee is south of the gate) | `Close the gate behind them` | Gate closed with no refugee north of the Wall (stops the north hunters) |
Defeat also when **fewer than 20 refugees can still arrive** (saved + alive < 20).

### C.6 Guards, waves and events (normal; x 0.6 / x 1.4)
`G` = the moment the gate first opens. Hunters (Stone-sworn) attack-move to **the nearest refugee**, then the nearest
player unit; Host units attack-move along the route toward the exit.
| Wave | When | Spawn -> units | Value |
|---|---|---|---|
| H0 pursuers | 4:00 (behind the column) | North: 4 Shades + 2 Grave Hounds | 700 |
| H1 | G + 0:30, but not before the column's tail passes the gate | Through the gate if open, else West: 4 Shades + 2 Nightbolts | 600 |
| H2 | Column reaches the Hearth Camp | West: 4 Shades + 2 Nightbolts + 1 Hexweaver | 740 |
| H3 | Camp + 1:30 | East: 3 Grave Hounds + 3 Shades + 1 Shadow Knight | 815 |
| H4 | Camp + 3:00 | North (gate) if open, else West: 6 Shades + 2 Nightbolts + 1 Gloom Deacon | 1 040 |
| W5 Southway Crack | The column leaves the camp | Crack `(6, 36)`: 8 Ruin Wardens + 1 Rubble Sentinel (they rise from the ice and hold the road) | 1 600 |
| H6 the last hunt | The column's head at `(4, 46)` | West and East: 4 + 4 Shades, 2 + 1 Nightbolts, 1 + 1 Shadow Knights, 4 Barrow Ghouls | 2 200 |
If `sec_shut` is done, H4 always comes by the West breach and has 2 fewer Shades. Breaches walled with Ice Walls: the
hunters attack the walls (they are buildings) before passing; nothing else changes.

| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cutscene `e8m1_ice_gate` (HOLD 0:25): the rider hammers at the gate (pro. S24 from the reverse side); L1-L4; hint `Open the gate: Torvald at the lever for 3 s. The column arrives at 3:30, hunters close behind.` Aldra then walks to the West Icefall and despawns ("I'll hold the falls as long as glass holds") |
| E2 | Gate first opens | The rider walks in (L5); `obj_gate` done; if before the column's head is within 10 m, `sec_early` is done when the head reaches the gate |
| E3 | 3:30 | Column spawns; `obj_column` active; L6 |
| E4 | Column leaves Kettlewick | Militia join (flag) with L7-L8, or narrator L9b |
| E5 | Column head within 10 m of a **closed** gate | L9 (Aldra's voice) once; every 10 s while shut, the line `They're dying at the gate.` (message, 3 s) |
| E6 | Last refugee south of the Wall | `sec_shut` active; L10 |
| E7 | Column at the Hearth Camp | L11; H2 |
| E8 | Citadel complete / Aldra arrives | Completion message / helper arrival (her bark) + L12 |
| E9 | Column leaves the camp | L13; W5 rises |
| E10 | W5 cleared | L14 |
| E11 | H6 spawns | L15 |
| E12 | 20th refugee saved | L16 |
| E13 | `obj_column` done | Cutscene `e8m1_ice_south` (PAUSE 0:25): L17-L19; victory |
| E14 | Torvald dies | L20; defeat |
| E15 | Saved + alive < 20 | L21; defeat after 3 s |
| E16 | Keep destroyed | Defeat |

### C.7 Economy and units
| Item | Value |
|---|---|
| Start | 450 crystals, 150 + carried + 300 essence, 22 / 40 |
| Nodes | 2 x 1 500, Falls 2 000 (south-west, safe) |
| Units | Rime Hauler; Frost Hall skirmish card (Rimeshield, Shardcaster, Rime Seer, Frostbow, Rimeling, Rime Colossus where the card has it; Hoarlight Magebow, Frost Mortar tier 2); keep: Rimecarver (B), Shardguard (C, Citadel), **Call Aldra** (V); Ice Walls |
| Spells | Rime Bolt, Flash Freeze, Rime Aegis |
| Essence (by 20:00) | ~3 000 |
The Rimecarver is the mission's tool: **Rime Bulwark** across a breach or the Long Stair stops a hunter dive for 8 s;
**Scrying Rune** on the breaches shows the flank parties 20 s early.

### C.8 Dialogue (22 lines)
Speakers: `narrator`, `torvald`, `aldra`, `obren`. The rider and the militia are silent (barks only). Aldra
`(0.62, 0.95, 0.88)`, Torvald `(0.55, 0.80, 1.00)`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | The Hundredwinter Gate. Someone is knocking on it. Someone always was. |
| L2 | E1 | aldra | We don't know what follows them. We could wait. Just until we see. |
| L3 | E1 | torvald | I always waited until I saw. Then there was nothing left to see. |
| L4 | E1 | torvald | Not this year. Open the gate, Aldra. Or no. I will. My hands, this time. |
| L5 | E2 | torvald | Come in. Get warm. There is soup, I'm told. I've never been told that before. |
| L6 | E3 | narrator | Out of the cracked north comes a long dark line: carts, old men, children, and the hunt behind. |
| L7 | E4 (flag) | narrator | Kettlewick stands. It remembers who opened the gate once. Its shields come too. |
| L8 | E4 (flag) | torvald | Kettlewick. Twice now. Perhaps it's a habit. |
| L9b | E4 (no flag) | narrator | Kettlewick is a ruin. The gate stayed shut that winter. This column is what's left. |
| L9 | E5 | aldra | Torvald, they're at the gate. Whatever you're waiting for, it's here. |
| L10 | E6 | torvald | That's the last of them. Close it behind them. Gates are for closing too. |
| L11 | E7 | torvald | They rest here. Four minutes. They walked for three days. We hold for four minutes. |
| L12 | E8 | aldra | You called. Before I asked. Winter's changing. |
| L13 | E9 | obren | The ice cracks, Torvald. Even yours. Especially yours. |
| L14 | E10 | torvald | Then it cracks. Ice was never the point. The line was. |
| L15 | E11 | aldra | Both flanks! They want the children. Hold the stair! |
| L16 | E12 | torvald | Twenty. That's enough to be a town. Keep them coming. |
| L17 | E13 | torvald | Go south. Don't look back. There's nothing back there worth the look. |
| L18 | E13 | aldra | The orb is warm. It hasn't been warm in a hundred years. |
| L19 | E13 | torvald | Crown Hollow, then. Vessa waited. I can hurry. Watch me. |
| L20 | E14 | torvald | Too slow... once more... |
| L21 | E15 | aldra | Too many lost. The road is closed to them now. |
Echoes: L3 turns pro. L24 ("he waits too long"); L4 echoes the rider of S24 and `e6m2`; L19 crosses with the Fire road
("Vessa waited"); L13 is Obren's dig at Ep7's turn. Aldra's helper barks are `t3-helpers.md` 10.4.

### C.9 Cinematic hooks
| id | When | Mode / length | Shots | Lines | End state (also on skip) |
|---|---|---|---|---|---|
| `e8m1_ice_gate` | E1 | HOLD 0:25 | 1) **Reverse of pro. S24**: over the rider's shoulder, the ice gate and the signal torch (this time not buried); 2) MS Torvald on the gate's south side, Aldra beside him; 3) CU his hand on the lever, not pulling yet; 4) WS: Aldra walks west along the Wall | L1-L4 | Gate closed; Aldra despawned; the rider at `(0, -22)`; camera on Torvald |
| `e8m1_ice_south` | E13 | PAUSE 0:25 | 1) WIDE down the Long Stair: the column winding south into sun; 2) MS Torvald and Aldra at the top, the orb glowing; 3) LONG LENS south: the haze over Crown Hollow; FADE_BLACK | L17-L19 | Victory, save |

### C.10 Win / lose
| Event | Result |
|---|---|
| `obj_column` done (20+ saved) | **Victory** |
| Torvald dies / Rime Keep destroyed | **Defeat** |
| Saved + alive < 20 | **Defeat** |
| Aldra fallen, militia dead | Nothing |

### C.11 Rewards / flags
`MISSION_REWARDS[&"e8m1_ice"] = {"flags": {"e8m1_ice_open_early": "sec_early", "e8m1_ice_thirty": "sec_thirty",
"e8m1_ice_shut": "sec_shut"}, "bonus_essence": {"sec_early": 300, "sec_thirty": 300}, "set_flags": {"e8m1_done": true,
"e8_road": &"ice", "e8_hush_fled": true}, "next": &"e8m2"}`; mission-computed `e8m1_ice_saved` (int). e8m2 hook:
`e8m1_ice_saved >= 30` = the **Kettlewick Guard** (4 Rimeshields, guests) at the Ice seat in e8m2.

### C.12 Difficulty and sizing
| | Easy | Normal | Hard |
|---|---|---|---|
| Counts | x 0.6 | as written | x 1.4 |
| Column | 40, needed 16 | 40, needed 20 | 40, needed 24 |
| Camp rest | 180 s | 240 s | 270 s |
| Refugee HP | 80 | 60 | 50 |
| Expected time | 15-18 min | 18-22 min | 21-25 min |
| Fight | When | Enemy | Player then | Ratio |
|---|---|---|---|---|
| H0 (at the gate, if opened in time) | ~4:30 | 700 | 1 750 + Torvald L5 + 2 300 HP of Spire / walls | 40 % |
| H2 + H3 at the camp | 6:30-8:00 | 1 555 in two fronts | ~3 000 | 26 % per front, 52 % if both meet |
| W5 Crack | ~10:30 | 1 600 | ~3 600 + Aldra | 44 % |
| H6 (both flanks at the Stair) | ~13:30 | 2 200 | ~4 000 + Aldra | 55 % |
- The skill is splitting: two flanks and a column that dies to anything that reaches it. Bulwarks, Ice Walls in the
  breaches and Flash Freeze on the hounds are the intended answers; Frost Mortars at the camp kill the H3 hound pack.
- `sec_early` is free if the player listens to L3-L4; the trap is the old Torvald who "waits to see".

---

## D. Nature: "Take a Side" (`e8m1_nature`, Ysolde + Maelis)
### D.1 Story setup
1. Ysolde grew her wood back after the frost, and then she did what she has always done: she closed every road out of
   it with roots, so the war could not come in again.
2. Now she has to go out. The Signet is hers again, and it points east, to Crown Hollow, where the Hollow Host is
   raising gates on every bridge. Three walls of her own roots stand in her way. They only know one word: no.
3. And along the road, the messengers have started coming again, from hamlets that are burning. This time she will
   answer them.

### D.2 Map: "The Closed Road" (120 x 120, seed **1814**, not mirrored; `data/maps/closed_road.map`)
The regrown Sighing Wood's eastern border: young green forest, spring light `(1.0, 0.96, 0.85)` energy 1.1, pollen motes.
The **Border Road** runs west -> east. Three **root walls** cross the whole map north to south at `x = -24`, `x = -4`
and `x = 12` (living hedges of root and thorn, 4 m high, impassable, `"navigation_geometry"`), each with one **knot** on the
road. East of the third wall: open meadow, then the river **Thistlewater**, then the road to Crown Hollow.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / **Heartwood** (keep) | `(-39, 23)` / `(-46, 30)` | 16 | Pre-built, **Stronghold** (2 700 HP) |
| Grove Hall / Bramble Spire / Seed Hollow | `(-34, 38)` / `(-30, 18)` / `(-56, 38)` | - | Pre-built; Seed Hollows max **6** |
| Nodes `e8n_a` / `e8n_b` | `(-55, 24)` / `(-44, 42)` | - | **1 500** each |
| Node `e8n_moss` (expansion, strip 1) | `(-12, 42)` | 7 | **2 000**; hall spot `(-17, 46)` |
| **Root wall RW1 "the Thornhedge"** | Line `x = -24`, z -60..60; **knot K1** `(-24, 14)` | - | Opens an 8 m gap at the knot when unwoven |
| **Root wall RW2 "the Old Briar"** | Line `x = -4`; **knot K2** `(-4, 6)` | - | Same |
| **Root wall RW3 "the Border Root"** | Line `x = 12`; **knot K3** `(12, -2)` | - | Same; the last of her walls |
| Briar Ward Spires | 2 per knot, on the knot's east side at `knot + (6, +-7)` | 3 | Team **NEUTRAL** (her old ward, hostile to all), Bramble Spire copies `briar_ward_spire`, 540 HP; they die with nothing gained except the knot |
| Hamlet **Pipwell** (strip 1) | `(-14, -30)` | 8 | Messenger event D.6 E4 |
| Hamlet **Fernby** (strip 2) | `(4, 36)` | 8 | E7 |
| Hamlet **Hollins Cross** (strip 3) | `(18, -34)` | 8 | E10 |
| **Thistlewater** river | Centre polyline `(24, -62)`, `(22, -20)`, `(23, 0)`, `(22, 24)`, `(24, 62)`, half width **3.0**, no moat | - | `RiverSystem.setup` by the mission; no fords |
| **North Bridge** / **Road Bridge** / **South Bridge** | `(22.5, -30)` / `(23, -2)` / `(22.5, 30)` | - | Bridges 6 m wide; each closes at its time (D.4) |
| **Crown Hollow road** (exit) | Zone `(56, -4)`, r 8 | - | Victory zone |
| Host spawn (east) | `(58, -30)`, `(58, 30)` | - | The Host comes from Crown Hollow's side |
Strips: strip 0 = x < -24 (home), strip 1 = -24..-4, strip 2 = -4..12, strip 3 = 12..22 (to the river). Path distances:
start -> K1 26 m; K1 -> K2 21 m; K2 -> K3 18 m; K3 -> Road Bridge 11 m; Road Bridge -> exit 33 m. Hamlets sit 30-40 m
off the road, north or south: answering one is a detour of ~1:30.

### D.3 Start state
| Item | Value |
|---|---|
| Ysolde | L5, 4 unspent points (Thornburst r1), cap 8; slot 1 `masters_signet` (forced); slot 2 `heartwood_seed` if owned (else empty, +300) |
| Crystals / essence | 450 / 150 + carried |
| Buildings | Heartwood (Stronghold), Grove Hall, Bramble Spire, Seed Hollow |
| Units | 5 Spriglings gathering; **8 Thornlings, 4 Wildwood Archers, 2 Bloomtenders, 1 Bramblehorn, 2 Vinelashers, 1 Bramblesage** at `(-32, 24)` (1 590 crystals) |
| Population | **25 / 40** |
| Story units | **Wren** (`wren`, e2m1's story unit; at 1 HP kneels 8 s) beside Ysolde; she rides ahead to each hamlet as its messenger (D.4) |

### D.4 Mechanics
**Unweave** (a knot, `MissionBrazier` subclass `RootKnot`): Ysolde within **4 m for 5 s** while no ENEMY or NEUTRAL unit
within **8 m** (the two ward spires count while alive: they stand 9.2 m away and shoot 10). Unwoven: the knot uncoils
(1.5 s), an 8 m gap opens (navmesh rebake), the wall stays elsewhere.
**The bridges close** (the clock): a Warden Gate (1 800 HP, armor 20) rises on a bridge's east end at **11:00 North,
15:00 South, 19:00 Road** (normal): a closed bridge is blocked until its gate is broken, and it spawns **3 Ruin Wardens
every 45 s** toward Ysolde. Message 60 s before: `The Host is raising a gate on the North Bridge (1:00).`
**Messengers and hamlets** (the turned weakness): when Ysolde unwinds a knot, the next strip's hamlet sends its messenger
(Wren rides in, L-line): a raiding party attacks the hamlet and a **burn bar** (120 s) starts. Saved = every raider dead
before the bar ends. Saved: the hamlet's **militia** (2 Wildwood Archers + 2 Thornlings, pop 0 guests, commandable)
joins and its smoke stops; burned: a smoke column stays on the horizon (the S28 image) and nothing else happens.
**Burn her forest down** (keep rule): the Heartwood destroyed is **not** a defeat once per mission: it regrows in **90 s**
at 30 % HP (message `The Heartwood will grow back.`); a second destruction is a defeat.

### D.5 Objectives
| id | Type | Text | Done when |
|---|---|---|---|
| `obj_walls` | Primary | `Unweave your own walls (0 / 3)` | 3 knots unwoven |
| `obj_cross` | Primary (after `obj_walls`) | `Cross the Thistlewater and take the road to Crown Hollow` | Ysolde in the exit zone with **12+ pop** of army within 15 m of her (or all she has left if less) |
| `obj_ysolde` | Primary, always | `Ysolde must survive` | Fails = defeat |
| `sec_hamlets` | Secondary | `Answer the messengers (0 / 3)` | 3 hamlets saved |
| `sec_bridge` | Secondary | `Cross before the last bridge closes` | Ysolde on the east bank before 19:00 (normal) |

### D.6 Guards, waves and events (normal; x 0.6 / x 1.4)
| Group / wave | When | Where -> units | Value / order |
|---|---|---|---|
| Ward spires | 0:00 | 2 per knot (D.2) | 2 x 540 HP each |
| Raid P (Pipwell) | K1 unwoven + 20 s | Spawn north edge `(-14, -58)`: 4 Stone-sworn Shades + 2 Grave Hounds | 600; attack-move into the hamlet ring, then Ysolde |
| Raid F (Fernby) | K2 unwoven + 20 s | South edge `(4, 58)`: 3 Ruin Wardens + 3 Shades + 1 Nightbolt | 900 |
| Raid H (Hollins Cross) | K3 unwoven + 20 s | North-east `(20, -58)`: 4 Wardens + 1 Rubble Sentinel | 1 000 |
| T1 Host tide | 6:00 | East spawns: 6 Wardens across the open bridges | 900; they march to the first closed wall's east side and wait there (max 16 waiting) |
| T2 | 10:00 | 6 Wardens + 1 Sentinel | 1 300 |
| T3 | 14:00 | 8 Wardens + 2 Shades + 2 Nightbolts (Stone-sworn) | 1 860 |
| T4 | 17:00 | 8 Wardens + 2 Sentinels | 2 000 |
| Gate spawns | Each closed bridge, every 45 s | 3 Wardens | Ysolde |
| Bridgehead | Ysolde within 20 m of the Thistlewater | East bank `(36, -4)`: 6 Wardens + 2 Sentinels hold the road | 1 700 |
Raiders spawned for a hamlet whose strip the army has not reached wait until the knot is unwoven (they never spawn
earlier: the messenger comes only when Ysolde could answer).

| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cutscene `e8m1_nature_road` (HOLD 0:20): L1-L4; hint `Unweave the knot on the road: Ysolde within 4 m for 5 s. Your old ward spires still guard it.` |
| E2 | K1 unwoven | L5; Pipwell's messenger (Wren) L6; raid P |
| E3 | 3:30 | (Citadel path as 1.3) |
| E4 | Pipwell saved / burned | L7 / L8 |
| E5 | 60 s before each bridge gate | Message |
| E6 | K2 unwoven | Fernby's messenger L9; raid F |
| E7 | Fernby saved | L10 |
| E8 | Maelis arrives | Her arrival bark + L11 |
| E9 | K3 unwoven | L12; Hollins Cross messenger L13; raid H; `obj_walls` done, `obj_cross` active |
| E10 | Hollins Cross saved | L14 |
| E11 | Ysolde within 20 m of the river | Bridgehead spawns; L15 |
| E12 | Ysolde on the east bank | L16 (`sec_bridge` if before the Road gate) |
| E13 | `obj_cross` done | Cutscene `e8m1_nature_out` (PAUSE 0:25): L17-L19; victory |
| E14 | Heartwood destroyed (1st) | L20; regrow |
| E15 | Ysolde dies / Heartwood destroyed (2nd) | L21 / defeat |

### D.7 Economy and units
| Item | Value |
|---|---|
| Start | 450 crystals, 150 + carried (+300 if no seed) essence, 25 / 40 |
| Nodes | 2 x 1 500 home, Mossford 2 000 (strip 1; reachable after K1) |
| Units | Sprigling; Grove Hall skirmish card (Thornling, Burr Slinger, Bloomtender, Bramblehorn, Wildwood Archer, Thistle Darter; Vinelasher, Greenheart Oathkeeper tier 2); keep: Bramblesage (B), Briar Roc (C, Citadel), **Call Maelis** (V) |
| Spells | Thornburst, Wild Bloom, Call the Thicket |
| Essence (by 20:00) | ~2 900 + the seed's carry |
Reinforcements walk the road: the Grove Hall's rally is set at the newest unwoven knot automatically (the player may move it).

### D.8 Dialogue (21 lines)
Speakers: `narrator`, `ysolde`, `messenger` (Wren, stumbles written in; subtitle clean), `maelis`, `obren`. Maelis
`(0.60, 0.85, 0.50)`, Wren `(0.80, 0.92, 0.60)`.
| Line | Event | Speaker | Text (spoken) | Subtitle if different |
|---|---|---|---|---|
| L1 | E1 | narrator | The Closed Road. For a hundred years nobody came in. For a hundred years she never went out. | - |
| L2 | E1 | ysolde | I grew these walls to keep the war out. They did. They kept everything out. | - |
| L3 | E1 | maelis | They'll fight you, child. They only know the one word you taught them. (voice, before her call) | - |
| L4 | E1 | ysolde | Then I'll teach them a second word. It's a short one. Open. | - |
| L5 | E2 | ysolde | One down. It felt like pulling out my own hair. Two more. | - |
| L6 | E2 | messenger | My lady! Pipwell... Pipwell's burning. They... they asked for you. By name. | My lady! Pipwell's burning. They asked for you by name. |
| L7 | E4 saved | ysolde | Nobody burns while I watch. Not any more. Go home, Pipwell. Grow it back. | - |
| L8 | E4 burned | ysolde | Too slow. I was always too slow for the ones at the border. | - |
| L9 | E6 | messenger | Fernby! The... the old stones are walking. Into the houses! | Fernby! The old stones are walking into the houses! |
| L10 | E7 | ysolde | Two. I'm taking a side, Maelis. It's theirs. | - |
| L11 | E8 | maelis | You called me out of the wood. I've waited forty years to hear that. | - |
| L12 | E9 | ysolde | The last root. My first wall. Goodbye. | - |
| L13 | E9 | messenger | Hollins Cross... please. Please, they're... they're at the mill. | Hollins Cross, please! They're at the mill. |
| L14 | E10 | ysolde | Three messengers, three answers. I could get used to answering. | - |
| L15 | E11 | obren | Stay in your garden, gardener. You were always so good at it. | - |
| L16 | E12 | ysolde | I've left the garden. Show me again, Master. I'm showing you. | - |
| L17 | E13 | narrator | For the first time in a hundred years, the green went out of its own border. | - |
| L18 | E13 | ysolde | The Signet's warm. It's pointing at the others. Let's not keep them waiting. | - |
| L19 | E13 | messenger | My lady... you're really coming? Out here? With us? | My lady, you're really coming out here? With us? |
| L20 | E14 | ysolde | Burn it, then. It grows back. That's the one thing I've always known. | - |
| L21 | E15 | ysolde | I left... too late... | - |
Echoes: L2 / L4 turn pro. S28 (she closes the road with roots); L16 is "show me again" (pro. L27) said by her to him;
L20 is pro. L26 ("Burn her forest down, and it grows back"); Wren is the ending's messenger (E18 "Wren on her stag").

### D.9 Cinematic hooks
| id | When | Mode / length | Shots | Lines | End state (also on skip) |
|---|---|---|---|---|---|
| `e8m1_nature_road` | E1 | HOLD 0:20 | 1) **Reverse of pro. S28**: from the road outside, looking in at the root wall and Ysolde behind it; 2) MS Ysolde lays her palm on the Thornhedge, it flexes and hisses; 3) WS the three walls in a row toward the east horizon (smoke on the far left: Pipwell) | L1-L4 | Camera on Ysolde; knots closed; spires active |
| `e8m1_nature_out` | E13 | PAUSE 0:25 | 1) LOW on the Road Bridge: Nature's army crossing, Wren riding ahead; 2) MS Ysolde looks back once at the open walls; 3) WIDE east: the Hollow's amber haze on the horizon; FADE_BLACK | L17-L19 | Victory, save |

### D.10 Win / lose
| Event | Result |
|---|---|
| `obj_cross` done | **Victory** |
| Ysolde dies | **Defeat** |
| Heartwood destroyed the **second** time | **Defeat** (the first regrows) |
| Every bridge closed | Not a defeat: break a gate |
| Maelis fallen, Wren kneeling | Nothing |

### D.11 Rewards / flags
`MISSION_REWARDS[&"e8m1_nature"] = {"flags": {"e8m1_nature_hamlets": "sec_hamlets", "e8m1_nature_bridge": "sec_bridge"},
"bonus_essence": {"sec_hamlets": 300, "sec_bridge": 200}, "set_flags": {"e8m1_done": true, "e8_road": &"nature",
"e8_hush_fled": true}, "next": &"e8m2"}`; mission-computed `e8m1_nature_saved` (0-3). e8m2 hook: each saved hamlet = one
militia squad (2 Wildwood Archers + 2 Thornlings, guests) at the Nature seat in e8m2.

### D.12 Difficulty and sizing
| | Easy | Normal | Hard |
|---|---|---|---|
| Counts | x 0.6 | as written | x 1.4 |
| Unweave | 4 s | 5 s | 6 s |
| Bridge gates | 13 / 17 / 21:00 | 11 / 15 / 19:00 | 10 / 13 / 16:00 |
| Burn bar | 150 s | 120 s | 100 s |
| Expected time | 15-18 min | 18-22 min | 21-25 min |
| Fight | When | Enemy | Player then | Ratio |
|---|---|---|---|---|
| K1 spires (2 x 540 HP, ~2 x 12 DPS) | ~2:00 | ~500 | 1 590 + Ysolde L5 | 31 % (must leave **16+ of 18** start soldiers) |
| Raid P | ~4:00 | 600 | ~2 200 | 27 % |
| Raid F + T1 waiting at K3 | ~8:00-10:00 | 900 / 900 | ~2 900 | 31 % each |
| Raid H + T2/T3 | ~13:00 | 1 000 + up to 1 800 | ~3 600 + Maelis | 50-65 % |
| Bridgehead (+ gate spawns) | ~16:00 | 1 700 + 450 | ~4 000 + Maelis | 54 % |
- The hamlet detours cost ~1:30 each and the bridges close on a clock: answering all three and still crossing before
  19:00 is the full-marks run; skipping them is faster and shown on the horizon (smoke) every time.
- Watch: if the waiting Host pile at K3 wipes careless armies, cap it at 12 before touching the tides.

---

## 9. Consistency notes (for the doc owners)
| # | Where | Issue | Fix taken here |
|---|---|---|---|
| 1 | Outline 3.3 e3m3 "Malrik's crypt city" | No name | **Duskbarrow**; e3m3 reuses it and sets `e3m3_stone_used` (bool) and defines the Shard's active; if it defines none, B.4 is the definition |
| 2 | Outline 3.6 e6m2 "the town beyond" | No name, no flag | **Kettlewick** north of the Hundredwinter Gate; e6m2 writes `e6m2_gate_opened` (true = the town saved) |
| 3 | Outline 4.2 Shadow "Each time the player uses the stone's power, +5 % HP" | Cap and counter unnamed | Counter `e8_stone_uses` (int), cap **+25 %** (5 uses) in e8m3 |
| 4 | Outline 3.8 "Everything of that kingdom, its helper" vs Hush the boss | Malrik has no helper | D8: Veyra Nightquill is called at the Shadow Citadel in Ep8; Hush returns in e8m3 phase 3 and the ending |
| 5 | `items.md` campaign table | `heartwood_seed`, `keystone_shard` rows pending (outline C7) | This spec needs only `key_relic = true` on the four keys (D4) |
| 6 | `t3-helpers.md` 1 | Aldra was "proposed" | Used as built (Ep7 e7m2 makes her callable) |
| 7 | `ep8_opening` (outline 4.1) | The relics' handover is not saved | `ep8_opening`'s StoryFlow step removes `stillwater_orb` and `masters_signet` from Vessa's track and adds them to Torvald's / Ysolde's (flag `ep8_relics_returned`) |

## 10. Acceptance checks (the lead runs them; headless through `tools/godot_run.ps1`)
- Each variant: a scripted headless run on normal (the variant's intended route) ends `victory=true` in **18-22
  game-minutes** in 3 / 3 runs; the first fight leaves the listed survivors in 5 / 5 runs.
- Shared: the key relic sits in slot 1 and cannot be dropped, sold or swapped; slot 2 empty gives +300 essence once; the
  Citadel opens at 5:45 and the V button calls the road's helper for 250 + 100 in 30 s; titans are hidden; no Commander
  exists for team ENEMY; the fallback start loads with no save.
- Fire: hunger stays 0 with every unit on the west bank for 14:00; Vessa alone on the east bank for 10 s adds 4 %; a Surge
  pauses the countdown 60 s and resets the meter to 40 %; the Gathering Storm strikes once per 120 s of waiting.
- Shadow: a door refuses to close with a Ghoul at 7 m and closes in 5 s once it dies, removing its Risen; one Gift adds 1
  to `e8_stone_uses` and fails `sec_shovel`; the Stair Gate takes no damage until 3 doors are laid; Hush flees at 25 % and
  is never killable.
- Ice: the column stops at a closed gate and at an enemy within 14 m of its head; 40 refugees spawn at 3:30; the militia
  joins only with `e6m2_gate_opened`; saved + alive < 20 is a defeat; Ice Walls can be placed in a breach.
- Nature: a knot refuses while a ward spire stands; each bridge gate rises at its time and spawns 3 Wardens / 45 s;
  raiders never spawn before their strip's knot opens; the first Heartwood death regrows at 30 % after 90 s.
- Every cutscene's end state is identical on skip (`test_19_c9` pattern) and every line fits 5 s at the cast speeds.

## 11. Implementation tasks (proposed ids; the lead adds them to `waves.md`)
- [ ] **E8.M1** (four-wizards-high, World Forge): `data/maps/duskbarrow.map` (seed 1812, crypt blocks, lanes width 6),
  `hundredwinter_gate.map` (seed 1813, the Wall at z -18 with the 8 m gate gap and two 5 m breaches, Kettlewick standing
  and ruined variants), `closed_road.map` (seed 1814, three full-height root walls with knots, the Thistlewater and 3
  bridges); every row of B.2 / C.2 / D.2 at +-0.5 m; Map Lab >= 90; a path test from start to every objective.
- [ ] **E8M1.S0** (systems-high [H]): `MissionE801` base: track load by `ep8_road`, the key relic rule (forced slot 1,
  `key_relic` no drop / sell / swap), +300 per empty artifact slot, Stronghold start + `max_tier = 3`, helper price
  250 + 100 / 30 s, Veyra as the Shadow V slot, `tavern_enabled` false, team ENEMY with no Commander, the road-end save
  (1.5) and `CampaignState.MISSION_SCENES` for the four ids; `tests/test_e8m1_s0.gd`.
- [ ] **E8M1.G1** (gameplay): `rubble_sentinel` UnitType; the `stone_sworn` modifier + `set_stone_sworn(true)` hook;
  `refugee` UnitType; `hush_boss` (helper kit at boss numbers, untargetable flee at 25 %); `ashby_story` /
  `ashby_scouts` / `gate_rider` story types; test: a Sentinel's splash hits 2 Shades 1.2 m apart; Hush never drops
  below 25 %.
- [ ] **E8M1.SF** (systems-high [H]): variant A: stakes placement from `RiverSystem`, the Hunger meter (bank rule, Surge,
  pause), the Gathering Storm, WG-N / WG-S share rule, scouts' break-out, waves H1-H8, E1-E17.
- [ ] **E8M1.SS** (systems-high [H]): variant B: `BarrowDoor` (spawns, lay to rest, Risen removal), the Stair Gate ward,
  the Stone's Gift counter (`e8_stone_uses`, `sec_shovel`), Hush's engage rule, raids and the camp, E1-E16.
- [ ] **E8M1.SI** (systems-high [H]): variant C: the Hundredwinter Gate (open / close, nav toggle, lever), the column
  brain (waypoints, stops, rests, follow fallback, exit count), Kettlewick branch, hunters' targeting, defeat on < 20,
  E1-E16.
- [ ] **E8M1.SN** (systems-high [H]): variant D: `RootKnot` (unweave, gap rebake), bridge gates on a clock, hamlets
  (messenger, raid, burn bar, militia), the Heartwood regrow rule, the Thistlewater `RiverSystem.setup`, E1-E15.
- [ ] **E8M1.I1** (items): `key_relic` flag on `ember_crown`, `keystone_shard`, `stillwater_orb`, `masters_signet`; the
  Shard's active (B.4) if `e3m3` has not defined it; test: a key relic refuses `sell`, `drop` and leaves no ground item on
  death.
- [ ] **E8M1.A1** (ai): `AIStoryCaster` profiles for the Stone-sworn Deacons and Hush; scripted units never join a
  Commander; the column and the scouts never take orders.
- [ ] **E8M1.U1** (ui): Hunger + Gathering Storm bars, column counter (saved / needed / lost), door and knot rings, burn
  bars over hamlets, bridge-gate warnings, boss bar for Hush, the locked slot-1 tooltip; speaker colours for `ashby`,
  `shade`, `hush`, `aldra`, `maelis`, `messenger`; briefings.
- [ ] **E8M1.V1-V4** (tech-artist, one per road): V1 Storm Stakes + rune line VFX, Throne Crack decal, the pit's spring
  look; V2 Duskbarrow kit (crypt blocks, Barrow Door open / laid states, Stair Gate, stone tents), Hush's cracked-mask
  variant; V3 the Wall of a Hundred Winters + gate open / closed + breaches + Kettlewick (standing and ruined), refugee
  and cart look; V4 root walls + knot uncoil, Briar Ward Spire tint, hamlets (+ smoke), bridges with rising gates.
- [ ] **E8M1.V5** (tech-artist): `rubble_sentinel` model; Stone-sworn amber variant on the Shadow models.
- [ ] **E8M1.C1** (four-wizards-high, after 19.C1 / 19.C2): the 11 cutscenes of A.9 / B.9 / C.9 / D.9; StoryFlow
  `ep8_opening` -> picker -> briefing -> road -> `c_e8_muster`.
- [ ] **E8M1.VO** (Voice Forge agent): 94 lines (26 + 25 + 22 + 21), `data/voice/lines/e8m1_<k>.json`; no new speaker.
- [ ] **E8M1.D1** (game-designer): read the 94 lines in game; check the four roads against the e8m2 hooks.
- [ ] **Lead**: the four scripted runs and the shared checks of section 10.

Dependencies: 19.C1 / 19.C2 (cutscenes only), MissionBase (M9.S1), the helper code (TH), `CampaignState` tracks (outline
D8), `RiverSystem` (Fire, Nature), Warden Gate (19.C6), the Picker (F8 of the outline).

## Spotlight (`unit-spotlights.md`)
One spotlight per road (framework hook: `mission-framework.md` 7).
| Road | Unit | Why here | Moment | Intro card |
|---|---|---|---|---|
| `e8m1_fire` | Pyre Adept | a 14:00 hold; Warden tides of 6-14 clump in fords that slow 35 %; Lab 76 / 93 / 77 | H6 at Reed Ford: "Pyre Adepts behind the Guards: the ford is a furnace." | `Pyre Adept. A battle mage for crowds: let them bunch up in the water, then burn the bunch.` |
| `e8m1_shadow` | Hexweaver | boss hero Hush (3 200 HP) and Risen Barrow Knights; Lab 3 / 27 / 6 (exempt debuff: it needs a boss) | Hush at 75 %: "Hexweavers: hex Hush, not the Shades." | `Hexweaver. A curse for the big ones: heroes, knights and anything worth more than its friends.` |
| `e8m1_ice` | Frost Mortar | the 240 s Hearth Camp rest (static), the H3 hound pack, the Southway Crack Wardens; Lab 76 / 76 / 78 | H3 at the camp: one shell on the clumped hounds | `Frost Mortar. Far and heavy: when they bunch up, one shell freezes the lot.` |
| `e8m1_nature` | Greenheart Oathkeeper | hamlets raided by Stone-sworn Shades + Grave Hounds (divers): the taunt keeps them off the archers; Lab 87 / 78 / 86 | Raid P on Pipwell: "Greenheart Oathkeepers: the oath holds the hounds." | `Greenheart Oathkeeper. A sworn blade: it calls the divers to itself and doesn't let them pass.` |

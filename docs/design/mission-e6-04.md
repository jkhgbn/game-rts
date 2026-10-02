# Campaign mission e6m4: "The First Crack" (Ysolde + Torvald, with the Master, vs the Hollow Host; Episode 6)

Written 2026-10-02 (`campaign-outline.md` 3.6, row 4). Episode 6 "The Lake and the Seed" (origins), mission 4 of 4 and
its finale: **twelve years ago**, the lock under Crown Hollow fails for the first time. The Master kneels on the Throne
stone and holds the crack shut while Ysolde (player) and Torvald (allied Ice bot) hold the isle against the Hollow Host.
The only time Nature and Ice fight side by side before Episode 8. It explains why Ysolde knows the relics are a lock
(ep1 M3) and why Torvald "felt something counting" (ep1 C3), and it ends on the night the Master went down
(`ep6_ending`). Target **20-24 min** on normal. Episode rules ER1-ER8 and the Warden Breaker: `mission-e6-01.md` 0.
Uses `skirmish-1v1.md`, `map-fill.md` 2 (Hollowmere, crossings), `ai-2v2.md` (ally layer), `levels.md`, `items.md`,
`tiers.md` 6, `caster-units.md` 5.3 (Bramblesage), `kingdom-nature.md`, `kingdom-ice.md`, `mission-04.md` (the same
ground at war) and the format of `mission-01.md` / `mission-e3-01.md`. New scene `missions/mission_e6_04.tscn` +
`scripts/campaign/mission_e6_04.gd` (`MissionE604 extends MissionBase`, mission id `e6m4`). Metres, seconds, `m:ss` since
the navmesh was ready (held cinematic time excluded); positions `(x, z)`, `+z` = south. Status: **design only**.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map | **Crown Hollow** (`data/maps/crown_hollow.map`, the 1v1 layout, river on: Hollowmere + 8 crossings) twelve years ago: the 8 pillars of Crown Isle whole, no crown pedestal, the **Throne stone** at `(0, 0)` | Outline: "Crown Hollow, twelve years ago"; every spot below is a measured spot of the map file |
| D2 | Seats | Ysolde in the **south-west** seat (the player seat, `keep_t0`), Torvald in the **north-east** seat (`keep_t1`) as an **ally** (2v2 ally layer, one side). No enemy seat: the Host is mission-spawned | The isle sits between them: each holds one bank and one bridge, both meet on the isle |
| D3 | Where the Master goes down | Not on the isle. He **holds the crack shut from above** for the whole mission; at the end he says it cannot be held from up here and leaves in a white-gold flash. `ep6_ending` shows him stepping down through the orrery floor (ep1 V2 shot 7, prologue S07 "seen from below") | The vanishing happens at the orrery in three existing scripts (prologue S07, ep1 V1 shot 2, V2 shot 7); the outline's "while the Master goes down to hold the door" is kept as the mission's purpose and the ending's image |
| D4 | The secret | The Master tells them, on the isle: **tell no one** ("if the world knows, the world will dig") and **the regalia are the keys; never let them sit in one hand** | Answers outline C4 and why Ice and Nature stood aside in Ep1; plants Ep8's "four hands, not one" |
| D5 | Tier | **Stronghold** (`max_tier = 2`, from 3:30), the Bramblesage on the keep (B), the Hall's tier-2 units. Torvald starts at the Stronghold | ER4: the episode's finale; the Bramblesage was taught in e4m1 |
| D6 | "Something is counting" | The **Hollow counts the dead** (M4's Hollow meter, its first appearance): every soldier who dies near the isle weakens the seal | Torvald's ep1 line gets its origin; a reason not to throw units at the isle |
| D7 | Vessa, Malrik, Vey | Absent. The Master did not send for them (L6); Vey keeps the citadel (unseen) | Outline: Nature + Ice only; keeps Ep1's reveals |

## Story setup (briefing text, 3 short paragraphs; shown after `c_e6_seed`)
1. Twelve years ago. For eighty-eight years nothing under Crown Hollow had stirred. Then, on the first warm night of
   spring, the isle cracked, and amber light came up through the stones like water through ice.
2. The Master sent for two of his four apprentices, and only two: Ysolde from the west, Torvald from the north. When they
   arrived he was already on his knees at the old throne-stone, both hands pressed to the crack.
3. Something is climbing out of the moat. Hold the isle, both banks and both bridges, until the crack is shut. Do not
   let anything touch the stone.

## Map: "Crown Hollow, twelve years ago" (120 x 120, `crown_hollow.map`, rot180 symmetric, river on)
Off: capture points, camps (so the Mirefang ford nests are absent and Reed / Willow Fords are open), epic beasts, trade
(posts, guilds), taverns, peddlers, the 4 Crown Isle Ruin Wardens. On: Lost Caches, critters (cosmetic). Light: spring dusk
(sun `(1.0, 0.78, 0.55)`, low), amber moat glow growing with the seal damage (19.V4's 4 stages, reused in reverse: 4 = seal
full). The isle is the pre-war isle: 8 whole pillars on the ring r 8, flagstones, **no** crown pedestal.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Ysolde) / **Heartwood** | `(-36, 36)` / `(-43, 43)` | 18 | `keep_t0`; Nature keep 2 250 HP (Stronghold 2 700) |
| Grove Hall / Bramble Spire (pre-built) | `(-27, 45)` / `(-37, 29)` | - | Hall slot H1, spire slot S1 |
| Seed Hollows (pre-built x2) | `(-50, 46)` / `(-50, 52)` | - | V1 / V2 slots (+20 each) |
| Nodes `e6c_a` / `e6c_b` | `(-46, 34)` / `(-34, 46)` | - | **1 500** each |
| Node `e6c_mid` (natural) | `(-16, 6)` | 7 | **2 000**; hall spot `(-23, 9)`; 9 m from the West Crown Bridge |
| Node `e6c_rich` | `(-40, -40)` | 7 | **2 000**; near the north-west Warden Gate |
| **Torvald's Rime Keep** (ally) | `(43, -43)` | 18 | `keep_t1`; at the Stronghold (3 600 HP) |
| Frost Hall / Rime Spire / Snow Lodges (ally, pre-built) | `(27, -45)` / `(37, -29)` / `(50, -46)`, `(50, -52)` | - | Mirror slots |
| Ally nodes | `(46, -34)`, `(34, -46)` 1 500; `(16, -6)` 2 000; `(40, 40)` 2 000 | - | Mirrors |
| **The Throne stone** (the seal) | `(0, 0)` | 12 (isle) | See "The seal"; the Master kneels on it |
| Crossings | West / East Crown Bridge `(-9.02, 9.02)` / `(9.02, -9.02)`; NW / SE Crown Steps `(-9.02, -9.02)` / `(9.02, 9.02)`; Reed / Willow Ford `(-8.5, -34)` / `(8.5, 34)`; Saltgate / Millstone Bridge `(-12, -48.7)` / `(12, 48.7)` | - | `map-fill.md` 2.2, all open |
| **Warden Gate `wg_n`** (west bank) | `(-26, -54)` | 6 | `lair_den_w` spot; ENEMY, 1 800 HP, armor 10 |
| **Warden Gate `wg_w`** (west bank) | `(-53, 13)` | 6 | `lair_heath_w` spot |
| **Warden Gate `wg_s`** (east bank) | `(26, 54)` | 6 | `lair_den_e` |
| **Warden Gate `wg_e`** (east bank) | `(53, -13)` | 6 | `lair_heath_e` |
| Moat rises | at the NW Steps and the SE Steps | - | Wardens climb out of the moat onto the steps (1.5 s, amber water) |
| Lost Caches | `(-30, 0)`, `(-6, 27)`, `(30, 0)`, `(6, -27)` | 3 | `items.md` loot, 2:00, reopen 180 s |
| Rallies (suggested) | Ysolde `(-20, 20)`; Torvald `(30, -30)` | - | |
Paths (navmesh): Heartwood -> West Crown Bridge 48 m -> the stone 13 m; `wg_w` -> `e6c_mid` 40 m -> West Bridge 10 m; `wg_n`
-> NW Steps 47 m; Torvald's keep -> East Bridge 48 m. Banks: the west bank is Ysolde's, the east bank Torvald's
(`RiverSystem.bank_of`); the isle is shared.

## The seal and the Master's hold
**The Throne stone** (scripted target, systems): team PLAYER, group `"scripted"`, not in `"buildings"`, **4 000 HP** (the
seal), radius 2.0, always visible, a boss-style bar under the objectives (`The seal`). ENEMY units ordered onto it attack
it; Breakers x2. It **mends 3 HP / s** while no enemy is within 12 m. HP 0 = defeat.
**The Hollow counts** (D6): every death of a unit in group `"units"` (soldiers, workers, casters, any team; **not** Ruin
Wardens, Breakers, Saplings, or deaths while a cinematic holds the world) within **25 m** of `(0, 0)` costs the seal **15**.
The first one fires L7.
**The Master's hold** (`obj_hold`): 0-100 % over **960 s** of unpaused time, from **1:00**. It **pauses** while any ENEMY
unit is within **6 m** of `(0, 0)` (a white-gold ring r 6 on the flagstones flickers amber while paused; the objective
line adds `(paused)`). Never resets.
**The Master** (story actor, ER5): kneeling on the stone, both hands on it, white-gold light running from his hands into
the cracks, his hem burning in four colours. Invulnerable, not targetable, no collision beyond r 1.0, never moves until
`e6m4_down`.

## Start state
| Item | Value |
|---|---|
| Ysolde | **Level 4**: Thornburst r2, Wild Bloom r1 + **1 unspent point** (Call the Thicket); **cap 7**; full HP / mana (L4: 406 HP, 19 dmg, 146 mana) |
| Crystals / essence | 400 / 400 (+1 / s) |
| Buildings | Heartwood (tier 1; Stronghold from 3:30), Grove Hall, 2 Seed Hollows, Bramble Spire |
| Units | **6 Spriglings** (3 + 3 on the home nodes); **8 Thornlings + 4 Burr Slingers + 2 Bloomtenders + 1 Bramblehorn** at `(-30, 30)` |
| Population | 22 / 60; Seed Hollows **max 4** (cap 100) |
| Torvald (ally bot, seat 2) | **Level 5** (Rime Bolt r2, Flash Freeze r2, Rime Aegis r1); Rime Keep at the Stronghold, Frost Hall, Rime Spire, 2 Snow Lodges, 6 Rime Haulers, **6 Rimeshields + 3 Shardcasters + 2 Frostbows + 1 Rime Colossus + 1 Rimecarver** at `(30, -30)` |
| Inventory | 6 empty slots, no artifact (ER3) |
| Fog | On; the isle, both Crown Bridges and both Steps explored for both seats; allied vision shared (2v2 rule) |

## Unlocks
| Kind | Available | Locked |
|---|---|---|
| Buildings | Seed Hollow (Z, max 4), Grove Hall (X), Bramble Spire (C) | Citadel buildings, stables, Bazaar |
| Units | Sprigling (keep Z); Grove Hall **Z Thornling, X Burr Slinger, C Bloomtender, V Bramblehorn, B Wildwood Archer, N Thistle Darter**; **from the Stronghold**: **M Vinelasher, `,` Greenheart Oathkeeper** (Hall), **B Bramblesage** (keep) | Briar Roc and the Citadel (e4m2), Maelis as a helper (e4m2) |
| Keep | **Stronghold** (X, 200 crystals, 60 s, from 3:30) | Citadel |
| Spells | Thornburst, Wild Bloom, Call the Thicket; cap L7 | - |
| Items | Base shop (Heartwood, Grove Hall) incl. the Nature and Ice items | Tops out of reach (~2 800 essence by the end: one top is possible late) |
| "+" upgrades | At the Grove Hall from the Stronghold | - |

### The Bramblesage in this mission (`caster-units.md` 5.3, unchanged numbers)
The Host is all melee, so **Pollen Haze has nothing to blind** (the hint says so). The mission gives **Snagroot** its
clearest job in the campaign: it drags a Warden **7 m out of the Master's 6 m circle**, which un-pauses the hold at once.
Breakers (pop 4) are immune: they must be killed in place. Hint at the first Bramblesage (E5).

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_hold` | Primary | `The Master holds the crack: 37 %` (`(paused)` while an enemy is within 6 m of him) | 100 % |
| `obj_seal` | Primary, always shown | `Nothing may break the seal` (bar, 4 000) | Fails at 0 = defeat |
| `obj_ysolde` | Primary, always shown | `Ysolde must survive` | Fails = defeat |
| `obj_keep` | Primary, always shown | `The Heartwood must stand` | Fails = defeat |
| `sec_gates` | Secondary | `Break the Warden Gates on your bank (0 / 2)` | `wg_n` and `wg_w` destroyed |
| `sec_unbroken` | Secondary | `Keep the seal above half` | The seal never below 2 000; failed the first time it drops below |

## The Hollow Host (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
All ENEMY, group `"scripted"`, no Commander. Gate columns spawn under the arch (1 s amber flare); rises climb out of the
moat at the Steps. Columns fight what attacks them on the way (auto-aggro 9, leash none).
| Source | Trigger | Units | Order |
|---|---|---|---|
| `wg_n` columns (west) | Every **90 s** from **2:00** while the gate lives | 3 Ruin Wardens | Attack-move to the NW Steps, then the stone |
| `wg_w` columns (west) | Every **90 s** from **2:45** | 3 Ruin Wardens | Attack-move to `e6c_mid` `(-16, 6)`, then the West Crown Bridge, then the stone |
| `wg_s` / `wg_e` columns (east) | Mirrors, same times | 3 Ruin Wardens | Torvald's side: SE Steps / East Bridge, then the stone |
| Moat rises | **4:00**, then every **3:00** (7:00, 10:00, 13:00, 16:00 ...) | 4 Ruin Wardens at **each** Steps (NW and SE) | The stone |
| **First Crack** | `obj_hold` reaches **50 %** (expected 9:30-10:30) | Cutscene `e6m4_first_crack`, then **2 Warden Breakers + 6 Ruin Wardens** rise **inside the pillar ring** (r 6, at 0 / 60 / 120 ... degrees) | The stone |
| **The Deep Calls** | `obj_hold` **75 %** | Each living gate sends **1 extra column at once + 1 Warden Breaker** | Their column orders |
| **Last Rise** | `obj_hold` **90 %** | **1 Warden Breaker + 5 Ruin Wardens** at each Steps | The stone |
A destroyed gate stops its columns and its 75 % share. Rises never stop.

**Torvald, the ally** (`ai-2v2.md` ally layer, Supportive, profile `mission_e6_04_ally`; `bots_upgrade = false`, already
at the Stronghold): gathers, trains up to **18 army pop**, defends the east bank, the East Crown Bridge and the SE Steps,
answers pings. Scripted pushes on top: at **40 %** his army attack-moves to `wg_e` and breaks it; at **50 %** (First
Crack) **half** his army (by pop) goes onto the isle by the East Bridge for 60 s; at **70 %** he breaks `wg_s`; at **90 %**
his whole army holds the isle's east half until the end. If his push fails (the army falls under 6 pop) he returns home.
Torvald dying or his keep falling is never a loss (he respawns as a 2v2 wizard; message `Torvald falls back to the
north shore`).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cutscene `e6m4_crack` (0:30, HOLD): L1-L6. After it: hint `Keep every enemy out of the white circle around the Master: the crack only closes while it is clear. Your bank is the west.` (10 s) |
| E2 | First counted death within 25 m of the isle | L7; hint (8 s) `The Hollow counts the dead: every soldier who falls near the isle weakens the seal.` |
| E3 | 3:30 | Hint (12 s) `Your Heartwood can become a Stronghold: select it and press X (200 crystals). It opens Vinelasher, Greenheart Oathkeeper (Grove Hall) · Bramblesage (Keep).` |
| E4 | `obj_hold` 25 % | L8 |
| E5 | First Bramblesage trained | Hint (12 s) `Bramblesage: Z Snagroot drags one enemy 7 m toward it: pull Wardens out of the Master's circle. The Host is all melee: Pollen Haze has nothing to blind here.` |
| E6 | `obj_hold` 50 % | Cutscene `e6m4_first_crack` (0:12, PAUSE): L9-L11; the First Crack spawns; Torvald's half-army push |
| E7 | The First Crack's units all dead | L12 |
| E8 | A west Warden Gate destroyed | L26 (first); `sec_gates` counter |
| E9 | Torvald breaks an east gate | L27 (first) |
| E10 | `obj_hold` 75 % | L13-L15; The Deep Calls |
| E11 | `obj_hold` 90 % | L16; Last Rise; Torvald to the isle |
| E12 | Seal below 25 % (first time) | L23 (warning) |
| E13 | `obj_hold` 100 % | Cutscene `e6m4_down` (0:45, HOLD): L17-L22; every Host unit crumbles; victory at its end; Story mode then plays `ep6_ending` |
| E14 | Ysolde dies | L24; defeat after 3 s |
| E15 | Seal 0 | L25; defeat after 3 s |
| E16 | Heartwood destroyed | Defeat after 3 s (message `The Heartwood has fallen.`) |

## Dialogue (27 lines; 5 s each unless listed; <= 96 characters)
Speaker colours: `ysolde` `(0.55, 0.90, 0.35)`, `torvald` `(0.55, 0.80, 1.00)`, `master` `(0.95, 0.93, 0.85)`, `obren`
`(1.0, 0.80, 0.25)`, `narrator` `(0.9, 0.85, 0.7)`. File `data/voice/lines/e6m4.json`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Twelve years ago. The Master sent for two of his four. Only two. |
| L2 | E1 | master | Ysolde. Torvald. Hold the isle. Whatever climbs out of the water must not touch this stone. (6 s) |
| L3 | E1 | torvald | What is under it? |
| L4 | E1 | master | My first mistake. His name was Obren. |
| L5 | E1 | ysolde | Should we send for Vessa and Malrik? |
| L6 | E1 | master | Vessa would burn it open to see inside. Malrik would ask what it pays. No. (6 s) |
| L7 | E2 | torvald | Something under the isle is counting. Every one that falls, it counts. |
| L8 | E4 | obren | Master. You came yourself. I am honoured. Kneel a little longer. |
| L9 | E6 | narrator | Then the isle split, and the amber came up through the stones. |
| L10 | E6 | ysolde | Torvald! It's breaking on our side! |
| L11 | E6 | torvald | Then I am on your side. Hold. |
| L12 | E7 | master | It will not hold from up here. Not for long. |
| L13 | E10 | obren | Come down, old man. Hold my door yourself. Learn how long a year is in the dark. (6 s) |
| L14 | E10 | ysolde | Master. You can't go down there. |
| L15 | E10 | master | Someone must. I have always been the one who must. |
| L16 | E11 | obren | A wood-girl, a snowman and a tired old man. I can wait. Stone is patient. (6 s) |
| L17 | E13 | master | Listen, both of you. Tell no one what sleeps here. If the world knows, the world will dig. (6 s) |
| L18 | E13 | master | My regalia are its keys. When I go, they will scatter. Never let them sit in one hand. (6 s) |
| L19 | E13 | master | Ysolde, my heart: keep growing things. Torvald, my patience: wait for me. (6 s) |
| L20 | E13 | torvald | How long? (2 s) |
| L21 | E13 | master | Not too long. (3 s) |
| L22 | E13 | narrator | He went down that same night, to hold the door from below. He never said for how long. (6 s) |
| L23 | E12 | master | The seal! Keep them off the stone! (3 s) |
| L24 | E14 | ysolde | Master... forgive me... |
| L25 | E15 | obren | Open. At last, open. (3 s) |
| L26 | E8 | ysolde | That gate is closed. Roots don't forget. |
| L27 | E9 | torvald | One fewer door. Keep yours shut, Ysolde. |
Echoes: L4 is the first time either of them hears the name (Ysolde tells it to Vessa in ep1 M3); L6 is the prologue's
weaknesses in the Master's own voice ("she never waits", "he is never full"); L7 is ep1 C3's "felt something counting" and
M4's Hollow meter; L11 is the outline's "the only time side by side"; L17 explains Ep1's silence; L18 is the lock of ep1
M3 and the seed of Ep8's "four hands, not one"; L19 is the prologue's "my heart" / "my patience"; L20-L21 answer
Torvald's weakness (he waits too long) and ep1 C1 ("No. For now."); L22 hands over to `ep6_ending`.

## Cinematic hooks (ENGINE; skippable; units frozen; StoryFlow afterwards)
| Id | Kind | When | Length | Shots / actors | End state (a skip must leave exactly this) |
|---|---|---|---|---|---|
| `e6m4_crack` | ENGINE, **HOLD** | E1 | 0:30 | Teleports at `at == 0`: Ysolde `(-14, 14)` (west end of the West Bridge), Torvald `(14, -14)` (east end of the East Bridge). 1) CRANE down at dusk over the whole isle: amber cracks race out from the stone across the flagstones; 2) LOW behind the Master kneeling, hands on the stone, hem burning four colours; 3) WS the moat: stone heads break the surface; 4) two-shot from the isle, Ysolde and Torvald walking onto the two bridges from opposite sides (L2-L6); 5) CU the Master (face in shadow, beard of light) on L6 | Ysolde `(-30, 30)`, Torvald `(30, -30)` (back at their rallies with their armies' orders cleared); the Master kneeling at `(0, 0)`; seal 4 000; `obj_hold` 0 % (starts at 1:00); L1-L6 queued once |
| `e6m4_first_crack` | ENGINE, **PAUSE** | E6 | 0:12 | 1) TOP-DOWN on the isle: a cross-shaped amber crack splits it (19.V4 crack stage 1); 2) LOW inside the pillar ring: two Breakers haul themselves up out of the light (L9-L11) | The 2 Breakers + 6 Wardens alive at their ring marks with orders on the stone; crack decal stage 1; Torvald's half-army push ordered; L9-L11 queued once |
| `e6m4_down` | ENGINE, **HOLD**, then victory | E13 | 0:45 | Teleports: Ysolde `(-4, 5)`, Torvald `(4, -5)`; every Host unit crumbles to rubble in 2 s. 1) CU the Master's hands: the cracks close under them, amber fading to grey; 2) he stands for the first time (very tall), MLS from behind the two; 3) MS two-shot Ysolde / Torvald (L17-L18); 4) CU the Master (L19), Torvald (L20), the Master (L21, a faint smile in the beard of light); 5) WIDE: a white-gold flash, he is gone; the two alone on the darkening isle look at each other; 6) CRANE up, night falling (L22) | Victory; StoryFlow -> `ep6_ending` |
| `ep6_ending` | ENGINE stage | After the victory screen (Story mode) | ~0:50 | `episode6-opening.md` (not this doc): from under the earth, the vanishing (prologue S07 seen from below, ep1 V2 shot 7): he steps down through the orrery floor's crack and pulls the door shut; the regalia burst away; the four streaks of colour leave the citadel | - |
Camera axis: the West Bridge - East Bridge line (north-west / south-east through the stone); cameras stay on its south-west
side. Fallbacks until 19.C1: the direct effects (crack decal, spawns, crumble) and the lines play without the camera.

## Tiers, casters, helpers
| Item | Value |
|---|---|
| Code | `MissionE604._init`: `tiers_enabled = true`, `casters_enabled = true`, `helpers_enabled = false`; `_ready`: `tier_system.max_tier = 2`, `bots_upgrade = false`; Torvald's keep starts at tier 2 (`TierSystem.set_start_tier(team, 2)`, M4's helper) |
| Heartwood card | Z Sprigling, **X Stronghold** (gold pulse when ready), **B Bramblesage** (greyed `Requires Stronghold`), Set Rally r3c1 |
| Grove Hall card | Z X C V B N as listed; **M Vinelasher, `,` Greenheart Oathkeeper** greyed until the Stronghold; "+" page from the Stronghold |
| Timing | Stronghold 3:30 -> 4:30 at the earliest; first Bramblesage ~5:00, Vinelashers / Oathkeepers ~5:30, all before the First Crack (~10:00) |

## Economy
| Item | Value |
|---|---|
| Start | 400 crystals, 400 essence, 22 / 60, 6 Spriglings |
| Nodes | Home 2 x 1 500; natural 2 000 (on the `wg_w` column path: defended or raided); rich 2 000 (beside `wg_n`: only worth it after that gate falls) |
| Expected (normal) | ~12 Spriglings by 5:00; ~4 000 crystals mined by 20:00 |
| Essence by the end | 400 + trickle ~1 260 + kills ~1 300 (~70 Wardens, 6 Breakers, 2 gates x 100) = **~2 900**: one top late (Heart of the Grove: Overgrowth keeps the isle line alive) or two mids |
| Ally | Torvald's own nodes; 18 army pop cap keeps him a partner, not the carry |

## Win / lose
| Event | Result |
|---|---|
| `obj_hold` 100 % | **Victory** after `e6m4_down`, then `ep6_ending` |
| Ysolde dies | **Defeat** |
| The seal reaches 0 | **Defeat** |
| Heartwood destroyed | **Defeat** |
| Torvald dies / his keep falls | Nothing (message); he respawns; his army falls back to the Heartwood if his keep is gone |

## Reward and flags
- Nothing carried (ER3). `MISSION_REWARDS[&"e6m4"] = {"flags": {"e6m4_seal_unbroken": "sec_unbroken", "e6m4_gates":
  "sec_gates"}, "next": &"e7m1"}`. Episode 6 complete: the Story menu marks the "Origins" card done (outline C8).
- Story flow: victory -> `ep6_ending` -> Episode 7 card (`ep7_opening`).

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Host counts | x 0.6 | as written | x 1.4 |
| Hold length (unpaused) | 720 s | 960 s | 1 080 s |
| Seal HP / mend | 5 000 / 5 | 4 000 / 3 | 3 200 / 2 |
| "The Hollow counts" | 10 per death | 15 | 20 |
| Torvald army cap | 22 pop | 18 | 14 |
| Start | 500 crystals, +2 Thornlings | 400 | 300, no Bramblehorn |
| Expected time | 17-20 min | 20-23 min | 23-27 min |
Fight sizing (Warden 120, Breaker 330; player side = crystals + Ysolde `170 + 30 x level`; Torvald counted only where a
scripted push puts him; every fight <= 70 % of what the player side can have then):
| Fight | Enemy | Player side then | Ratio |
|---|---|---|---|
| A west column (from 2:00) | 360 per column, one every 45 s on the west bank | ~1 800 | 20 % |
| Moat rise, west share (4:00, every 3:00) | 480 at the NW Steps (Torvald takes the SE) | ~2 200 | 22 % |
| Column + rise together (worst, 7:00) | 840 | ~2 500 | 34 % |
| `wg_w` gate push (~8:00-12:00) | 1 800 HP gate + next column 360 | ~2 700 | 13 % + the gate |
| **First Crack** (~10:00) | 1 380 inside the ring, on the stone | ~3 000 + half of Torvald ~800 | **36 %** (the skill check: it pauses the hold and hits the seal at once) |
| The Deep Calls (75 %, ~15:00) | west: 2 columns + 2 Breakers = 1 380 (0 if both west gates are down) | ~3 400 | 41 % |
| Last Rise (90 %, ~18:00) | 1 330 per Steps | ~3 600 + Torvald's whole army ~1 200 on the isle | 28 % per side |
- The First Crack is the skill check: the Breakers appear **inside** the Master's circle (the hold pauses at once, each
  Breaker hits the seal for 43 / s). The intended answers: Thornburst (rooted Breakers still swing, but the Wardens around
  them stop pushing), Vinelashers and Oathkeepers on the Breakers, Snagroot on the Wardens to clear the circle, Wild Bloom
  on the line (every soldier who dies near the isle costs 15 more), and Torvald's half-army arriving by the East Bridge.
- Breaking the two west gates (`sec_gates`) before 75 % removes half of The Deep Calls: the expert route. A player who
  turtles on the isle wins too, slower (more pauses).
- Watch in the first playtest: if the First Crack breaks the seal more than 1 run in 4 on normal, spawn its Breakers at
  r 7.5 (just inside the ring) instead of r 6; if the hold never pauses after 50 %, add 1 Breaker to each rise.

## Target length (normal)
| Part | Time |
|---|---|
| Mission: hold from 1:00 + 960 s + ~3:00 of pauses | ~20:00 |
| `e6m4_crack` + `e6m4_first_crack` + `e6m4_down` | 1:27 |
| **Total** | **~21-23 min** (inside 20-24; `ep6_ending` ~0:50 after) |

## Code reuse (recommendation to the lead)
`MissionBase`; `crown_hollow.map` with M4's river setup and its off-switches; M4's Hollow meter code (deaths in group
`"units"` near a point) for "the Hollow counts", and its Crown Isle crack states (19.V4) and Warden Gate (19.V2); the e6m2
Warden Gate spawner; the e3m1 / `ai-2v2.md` ally seat and profile pattern for Torvald; the e6m1 PLAYER scripted target for
the seal; `TierSystem.set_start_tier` (M4); the prologue Master stand-in (B6) with a kneel / channel pose.

## Acceptance checks
- [ ] Map: `crown_hollow.map` with river on, the 8 crossings, no camps / points / taverns / peddlers / isle wardens / crown pedestal; the 4 Warden Gates at their lair spots on the right banks (`bank_of`); every position within 1.5 m of the table.
- [ ] Hold: 0-100 % over 960 s of unpaused time from 1:00; paused while an ENEMY is within 6 m of `(0, 0)` and never reset; a Warden Snagrooted from 5 m to 12 m un-pauses it on the same tick.
- [ ] Seal: 4 000 HP, Breakers x2, mends 3 / s with no enemy within 12 m; a Thornling dying at 20 m costs 15, at 30 m 0; a Ruin Warden dying costs 0.
- [ ] Host: columns per gate every 90 s (west offsets 2:00 / 2:45), rises at 4:00 + every 3:00 at both Steps, First Crack at 50 % inside r 6, The Deep Calls at 75 % per living gate, Last Rise at 90 %; destroyed gates stop.
- [ ] Ally: Torvald gathers and trains to 18 pop, defends the east, breaks `wg_e` at 40 % and `wg_s` at 70 % in a normal headless run, sends half his pop to the isle at 50 % and all at 90 %; his death never ends the mission.
- [ ] Tiers: Stronghold from 3:30; Bramblesage on B; Vinelasher / Oathkeeper greyed until then; Torvald at tier 2 from 0:00.
- [ ] Skipping each hook leaves its end state; `e6m4_down` -> `ep6_ending` in Story mode.
- [ ] Timing: a scripted headless run on normal (Stronghold, 2 Bramblesages on the isle, break `wg_w` then `wg_n`, hold the West Bridge and NW Steps) ends `victory=true` in 20-23 game-minutes in 3 / 3 runs with the seal above 30 %; `PERF OK` with the First Crack on screen.

## Done when (proposed ids)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| **E6M4.S1** | systems | Scene + script on `crown_hollow.map` (switches, isle without pedestal, Warden Gates on the lair spots), the seal target, "the Hollow counts", the hold (pause circle), start state, ally seat, tiers (Stronghold, Torvald at tier 2) | M4's 19.C5a river / Hollow code, E6M2.S1 (gate spawner), 2v2 seat API | Map / hold / seal / tier checks |
| **E6M4.S2 [H]** | systems-high | The Host (columns, rises, First Crack, The Deep Calls, Last Rise), events E1-E16, objectives, win / lose, difficulty, flags, StoryFlow to `ep6_ending` | E6M4.S1 | Host / timing checks |
| **E6M4.A1** | ai | Profile `mission_e6_04_ally` (Supportive, 18 pop, east-bank defence, pings, the 4 scripted pushes, fallback home under 6 pop) | 20.A* ally layer | Ally check |
| **E6M4.U1** | ui | Objectives (hold % with `(paused)`, seal bar, gates 0 / 2), the white-gold circle decal (flicker amber while paused), `master` speaker colour / portrait slot, ally portrait strip | 19.U3, E3M1.U1 | Both test sizes |
| **E6M4.C1** | systems-high | `e6m4_crack`, `e6m4_first_crack`, `e6m4_down` with marks and end states; StoryFlow e6m4 -> `ep6_ending` -> Ep7 card | 19.C1, 19.C2 | Skip tests |
| **E6M4.V1** | tech-artist | Pre-war Crown Isle state (8 whole pillars, flagstones, no pedestal), the Throne stone with crack-closing stages, the Master stand-in kneel / channel / stand poses and hand-light VFX, white-gold flash exit, Host crumble VFX, moat-rise amber water | 19.V2, 19.V4, prologue B6 | 0 lights, Art Lab, `PERF OK` |
| **E6M4.O1** | Voice Forge agent | `data/voice/lines/e6m4.json` (27 lines) | Lines frozen | Each WAV fits |
| **E6M4.D1** | game-designer | Lines in game; first-playtest tuning of the First Crack | Playtest | Written back here |
| Lead | lead | Headless timing run; commit; tick the Ep6 rows in `waves.md` | All | Acceptance "Timing" |
Dependencies: M4's isle / river / Hollow code (19.C5a-C5c) and art (19.V2, 19.V4), the 2v2 ally layer (20.A*), 19.C1 /
19.C2 for the hooks (the mission plays without them), `episode6-opening.md` for `ep6_opening` / `ep6_ending` (not written
here: the outline's next-up list should add it).

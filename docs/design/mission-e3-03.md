# Campaign mission e3m3: "The Stone's Price" (Malrik + Mother Hush; Episode 3)

Written 2026-10-02 (`campaign-outline.md` 3.3 row 3). Episode 3 "The Gravedigger's Son", mission 3 of 4. Two days after
"Another Night" (`mission-e3-02.md`): the barrow candles of **Duskbarrow**, the crypt city where Malrik grew up a
gravedigger's son, have gone out, and the city's own dead are walking as Obren's Wardens. Malrik leaves Torvald on the
Evenmead ridge and rides home. The player holds the **Great Crypt**, where the living of the city shelter, relights the
four barrow vigils one by one, and lays to rest **the Sexton**, a giant Obren builds from the old gravedigger's yard.
The **Keystone Shard's active power** arrives here, with its price: every use tightens **the stone's hold**, a Hollow
meter seen from the inside. Using it or refusing it is the episode's moral flag for Ep8. Target **20-25 min** on normal.
Uses the rules of `mission-04.md` (Hollow meter, Warden waves, boss), `mission-03.md` (Warden Gate), `mission-e2-01.md`
(the kindle rule, tiers / helper flags), `mission-e3-01.md` (the Shard, Malrik's track), `t3-helpers.md` (Hush, the
Nightblood Reaver), `caster-units.md` 5.4, `items.md`, `tiers.md` 6 and the format of `mission-01.md`. New scene
`missions/mission_e3_03.tscn` + `scripts/campaign/mission_e3_03.gd` (`MissionE303 extends MissionBase`, mission id
`e3m3`). Metres, seconds, `m:ss` of `mission_time()`; positions `(x, z)`, `y = 0`, `+z` = south. Status: **design only**;
nothing here is built. Recommended option taken everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map | **New map `data/maps/duskbarrow.map`** (120 x 120, World Forge map mode, seed 3303, not mirrored), every position in the Map table below binding for E3M3.M1 | Malrik's homeland exists nowhere yet; the outline places it here. The `forge_ep3_memories` graveyard corner (gravestones, candle) is its look in miniature |
| D2 | Who attacks | **Only the dead**: Obren's Wardens rising from the four barrows (team ENEMY, scripted, no Commander, no enemy wizard) | The mission is about Malrik and the stone, not the 2v2. One enemy keeps the temptation readable |
| D3 | How a barrow is closed | **Malrik relights its vigil candle** (the kindle rule: 3 m, 4 s, only while no Warden stands within 8 m of the candle). The barrow doors cannot be broken | "These are my dead" (L8): a bishop re-lights, he does not smash tombs. It is also the light motif of Ep1 (Vessa's braziers) turned to Malrik's candle, without spending Ep8's payoff (he never lights *his own* candle here) |
| D4 | The Shard's active | **Heart of the Hollow** (`shard_heart`), key **J** in missions (the STR / INT path key, unused in missions) or a click on artifact slot 1; cooldown 45 s; enabled at E3 ("the offer") | campaign-outline C7 / e3m1 D6. J needs no new key: in missions the path ability is off, so the same command-card slot carries the artifact's power |
| D5 | The price | **The stone's hold** meter, Malrik's own: +20 % per use, +0.5 % per own soldier lost; 50 % = Wardens rise faster; 100 % = **the stone speaks** (Malrik held 5 s, Wardens frenzy 30 s, meter back to 60 %). Uses are counted for Ep8 | The outline: "the shard offers power that fills a Hollow meter: use it or not (a flag for Ep8)". The power must be worth taking, and the price must be felt in this mission, not only later |
| D6 | Tier and Hush | Duskbarrow's keep, **the Bishop's Seat, is a Citadel at 0:00** (Malrik's capital). **Call Mother Hush** at the skirmish price (350 crystals + 200 essence, 60 s) from 0:00. Nightblood Reaver at the keep (C) | e3m2 opened both; a capital should not need upgrading. The call is now a real choice (army vs helper) |
| D7 | The boss | **The Sexton** (`sexton`): Obren's body made from the gravedigger's yard, lantern heart, spade arm, a mourning bell. 7 000 HP. Rises when the 4th candle is lit (or at **19:00** whatever the count) | Malrik's father dug these graves (`episode3-4-opening.md` L2): the stone attacks him where he is from. A fixed rise time stops a slow mission from stalling |
| D8 | Win | **The Sexton laid to rest and all four candles lit** | Both halves of the brief: hold the crypt while the dead rise, then end it |
| D9 | Torvald, Vessa, Ysolde | Not on the field. Torvald appears in the between-scene after the mission (`c_e3_doubt`) | Keeps the mission at home; his doubt lands in e3m4 |

## Story setup (briefing text, 3 short paragraphs; shown after `c_e3_price`)
1. Duskbarrow keeps its dead the old way: a candle at every barrow door, lit at dusk by the gravediggers. Two nights
   ago the candles went out, all four at once, and the dead stood up.
2. The living of the city have shut themselves inside the Great Crypt. The Bishop's Seat still stands above the Lantern
   Road. Malrik rode home through two nights to find his own dead walking toward his own people.
3. Light the vigils again and the dead will lie down. The stone in his pocket says there is a faster way. It is very
   eager to show him.
Briefing objectives: `obj_crypt`, `obj_candles`, `obj_malrik`, and the line `Only Malrik can relight a vigil candle.
Clear the barrow first.`

## Map: "Duskbarrow" (120 x 120, `data/maps/duskbarrow.map`, seed 3303, not mirrored)
A city of the dead on a long slope falling south: the **Bishop's Seat** and the living quarter at the top (north), the
**Lantern Road** running down to the **Great Crypt** in the middle, four walled barrows (graveyards with a sealed door
each) to the west, east, south-west and south-east, and the **Gravedigger's Lodge** at the bottom of the slope. Ground
`crypt` (World Forge) with the `ruins` biome scatter, mausoleum rows as impassable decor along the edges, `kit:slab`
gravestone fields inside the barrow walls (never on a lane), `forge:candle` props in the windows (emission only). Light:
violet dusk preset (low sun behind the Seat, `(0.85, 0.62, 0.75)` energy 0.9, ambient `(0.42, 0.38, 0.50)`), amber
cracks along the barrow lanes (decals, 0 lights). Playable bounds x -57..57, z -57..57 (camera 3 m inside the edge).
Clearings: no decor inside the listed radius.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Malrik) | `(0, -30)` | 5 | On the Lantern Road below the Seat |
| **Bishop's Seat** (player keep, Citadel) | `(0, -42)` | 16 | `shadow_keep`, tier 3 at 0:00 (3 500 HP, attack 20) |
| Gloom Hall (pre-built) / Hovels (pre-built) | `(-14, -40)` / `(14, -38)`, `(16, -46)` | - | |
| Night Spire (pre-built) | `(0, -24)` | 3 | Covers the top of the Lantern Road |
| Nodes `e3m3_seat_a` / `e3m3_seat_b` | `(-10, -51)` / `(9, -51)` | - | **1 500** each (13.5 m / 12.7 m from the keep) |
| Node `e3m3_ossuary_w` / `e3m3_ossuary_e` (expansions) | `(-46, -34)` / `(46, -34)` | 7 | **2 000** each; hall spots `(-40, -40)` / `(40, -40)` (the old bone quarries) |
| Node `e3m3_tithe` (rich, contested) | `(0, 26)` | 6 | **2 500**; hall spot `(7, 30)`; 26 m south of the crypt, on the road to the Lodge |
| **The Lantern Road** | `(0, -30)` -> `(0, -8)` | 6 (path) | Cobbled road, width 6 (decor path, never blocked) |
| **Great Crypt** ("the Vigil Hall") | `(0, 0)` | 12 | Objective building (below) |
| **Lantern Barrow** B1: door / candle | `(-44, 0)` / `(-39, 0)` | 8 | West; 39 m from the crypt |
| **Weeping Barrow** B2: door / candle | `(44, 0)` / `(39, 0)` | 8 | East; 39 m |
| **Pauper's Field** B3: door / candle | `(-34, 38)` / `(-30.7, 34.3)` | 8 | South-west; 46 m |
| **Bishops' Rest** B4: door / candle | `(34, 38)` / `(30.7, 34.3)` | 8 | South-east; 46 m |
| Barrow lanes | Each door -> the crypt, straight | 4 (path) | Amber crack decals along them: where the Wardens walk |
| **Gravedigger's Lodge** | `(0, 46)` | 10 | A small stone house, a bell on a post, a spade in the yard; the Sexton rises at `(0, 48)` |
| Mourners' rally (Shadow, decor) | `(0, -16)` | - | The start army stands here |
Distances (path): Seat -> crypt 42 m; Seat -> B1 / B2 candle ~58 m; Seat -> B3 / B4 candle ~86 m; crypt -> Lodge 46 m.
Generator check (E3M3.M1): a navmesh path from `PLAYER_START` to each candle, to the crypt's four sides, to the Lodge and
to every node; no gravestone within 2 m of a lane or a candle; Map Lab >= 90.

**Great Crypt** (`great_crypt`, BuildingType, systems): a domed mausoleum with a great candle visible through its door,
team PLAYER, **3 000 HP**, armor 20, radius 4, `counts_for_defeat` false (its own lose rule), not a drop-off, not a
shop, group `"scripted"`. **Vigil aura** r 10: own units inside get `idle_regen_pct` +0.5 (modifier `aura:vigil`).
Regains **0.5 % / s** while no enemy is within 12 m. Always visible through the fog. Wardens target it first (below).

**Barrow door** (`barrow_door`, a `WardenGate` variant from `mission-03.md`, 19.C6 family): a stone slab in a barrow
wall, **invulnerable**, not targetable, group `"scripted"`. Closed until its barrow opens (E2 / E8); open = amber light
in the doorway and the Warden spawn rule below; **sealed** (its candle relit) = the slab slides shut (1 s), the light dies,
no more spawns, forever.

**Vigil candle** (`MissionBrazier` with an `is_blocked()` hook, the e2m1 kindle rule): an iron stand with one tall
candle, cold until relit. **Malrik within 3 m for 4 s** relights it (progress ring; leaving resets, damage does not);
**blocked** (ring grey, message once per candle `The dead won't sleep while they stand over the candle. Clear the
barrow first.` 4 s) while any Warden, Gravewarden or the Sexton is within **8 m** of the candle. Relit: violet flame, the
door seals, every Warden within **12 m** of the door crumbles (no XP, no essence), `obj_candles` +1.

## The stone's price (Keystone Shard active + the stone's hold)
### Heart of the Hollow (`shard_heart`; the `keystone_shard` row gains its active, items owner)
| Field | Value |
|---|---|
| Key | **J** (physical) while Malrik is selected or always in Hero WASD (the command-card slot of the STR / INT path ability, empty in missions), or a click on artifact slot 1 |
| Cooldown / cost | **45 s**, no mana. Refused `"Recharging"`, `"The stone holds you"` (while held), `"Dead"` |
| Effect | An amber pulse r **14** around Malrik (0.4 s): every unit in group `"hollow"` (Wardens, Gravewardens) inside **kneels 8 s** (status `stilled`: cannot move or attack, takes **x 1.5** damage); every other enemy inside (the Sexton, any living enemy in later missions) takes **60** spell damage and `dazed` **1.0 s** (heroes, bosses, titans 0.5 s). Malrik heals **50 %** of the damage dealt and gets `spell_power` +30 for 8 s (modifier `item:artifact_1:heart`) |
| Price | **+20 %** on the stone's hold (below), and one use counted for Ep8 |
| Look | `heart_stone_pulse` at full scale on his hand, an amber ring racing out to 14 m, kneeling Wardens with amber threads from their chests to Malrik's hand (the stone pulling their strings), his eyes amber for the 8 s |

### The stone's hold (`stone_hold`, 0-100 %, Malrik's own Hollow meter)
Shown from E3 as an objectives-panel line `The stone's hold: 20 %` (amber; orange at 50 %, red at 80 %) and as a thin
amber arc around Malrik's portrait (19.U5 style).
| Source | Amount |
|---|---|
| Heart of the Hollow used | **+20 %** |
| An own soldier dies (not workers, not Hush) | **+0.5 %** ("every death feeds", the M4 rule seen from inside) |
| Time, kills | Nothing |
| Threshold | Effect |
| **50 %** (first time) | L11; for the rest of the mission every open barrow spawns **20 % faster** (interval x 0.8) |
| **100 %** "The stone speaks" | World not held: Malrik is **held 5 s** (rooted + `set_cast_lock(5)`, amber chains, still takes damage), L12; every `"hollow"` unit on the map gets `attack_damage_pct` +0.25 for 30 s (modifier `stone:frenzy`); then the meter drops to **60 %**; L13. Counted as a seizure |
Nothing lowers the meter except a seizure. A player who never uses the power ends around 5-10 % (soldier losses); one
who uses it on every cooldown reaches 100 % by ~7:00 and again every ~4 uses.

## Start state (from Malrik's track, campaign-outline D8)
Order in `_on_navigation_ready`: spawn Malrik -> `CampaignState.open(...).apply_to_start(self)` -> scripted props.
| Item | Value |
|---|---|
| Malrik | **Level 5** (Lance r2, Siphon r2, Shroud r1), **cap 7**; full HP / mana; artifact slot 1 = Keystone Shard (power from E3); slot 2 empty (no other artifact owned) |
| Items / essence | The 6 slots from the save; essence **150** + carried (50 %, cap 1 500); +1 / s |
| Crystals | **400** (easy 550, hard 300) |
| Buildings | Bishop's Seat (Citadel, `Keep.set_start_tier(3)`), Gloom Hall, 2 Hovels, Night Spire, all complete |
| Units | 6 Gloom Thralls (3 on each home node); **6 Shades, 3 Nightbolts, 1 Shadow Knight, 1 Gloom Deacon** at `(0, -16)` (1 190 crystals of army) |
| Population | 6 + 6 + 3 + 3 + 2 = **20 / 60** (keep 20 + 2 Hovels; Hovels max **4** = cap 100) |
| Hush | Not on the field; **Call Mother Hush** (keep V) available at 0:00 |
| Fog | On; the crypt, the four barrow doors and candles, the Lodge explored from 0:00 |
| Off | Tavern, trade, camps, beasts, capture points, research, STR / INT, river, titans (the Lair opens in e3m4) |
| No save / e3m2 not won | Keystone Shard equipped, 6 empty slots, essence 150 + **700**, `helper_hush_unlocked` set |

## Unlocks (what exists in this mission)
| Kind | Available | Locked (comes later) |
|---|---|---|
| Buildings | Hovel, Gloom Hall, Night Spire | Dread Paddock (e3m4), Bazaar, research |
| Units | Gloom Thrall (keep Z), **Nightblood Reaver (keep C)**, Gloom Deacon (keep B); Gloom Hall: Z Shade, X Nightbolt, C Grave Hound, V Shadow Knight, N Barrow Ghoul, M Hexweaver, `,` Hollow Oathsworn; "+" upgrades | Nightmare Knight (e3m4) |
| Keep | Citadel (no tier button left); **V Call Mother Hush** (350 + 200, 60 s), then Revive | - |
| Helper | Mother Hush (`helper_hush`, Malrik's level, stances, F4) | - |
| Spells | Shadow Lance, Soul Siphon, Umbral Shroud; cap L7 | - |
| Artifact power | **Heart of the Hollow** (J) from E3 | - |
| Items | Base shop (Seat, Gloom Halls) | - |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_crypt` | Primary, always shown | `The Great Crypt must stand` (HP bar) | Fails = defeat |
| `obj_candles` | Primary | `Relight the barrow vigils (0 / 4)` | 4 candles relit |
| `obj_sexton` | Primary (appears at E13) | `Lay the Sexton to rest` (boss bar, marks 100 / 50) | The Sexton at 0 HP |
| `obj_malrik` | Primary, always shown | `Malrik must survive` | Fails = defeat |
| `sec_refuse` | Secondary (appears at E3) | `Refuse the stone: win without its power` | Victory with 0 uses; **failed** at the first use |
| `sec_whole` | Secondary | `Keep the Great Crypt above half` | Victory with the crypt never under 50 %; **failed** the first time it drops under |
Victory needs `obj_candles` **and** `obj_sexton` (any order: the Sexton can rise early, D7).

## The dead (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
All team ENEMY, groups `"scripted"` + `"hollow"`, no Commander. **Ruin Warden** in the barrow look (`set_look(&"barrow")`:
moss-black stone, a gravestone for a shield, amber eyes; `balance-1.md` numbers: 300 HP, 16 damage) and the new
**Gravewarden** (below). Orders: attack-move to the Great Crypt, refreshed every 4 s; they fight anything they meet on the
way; at the crypt they attack it first, then the nearest PLAYER unit within 8 m.
| Wave / rule | Trigger | Units | Notes |
|---|---|---|---|
| Barrow spawn | B1 and B2 open at **1:30**, B3 and B4 at **6:00** | Each open, unsealed door: **2 Wardens every 30 s** (max **8** alive per door) | Interval **25 s** from 12:00; x 0.8 from the stone's hold 50 % |
| Gravewarden call | Each time a candle is relit | Every door still open spawns **1 Gravewarden** at once | The stone answers each seal |
| The Lodge watch | 0:00 | 4 Wardens dormant at the Lodge `(0, 46)` (stand, guard r 10, leash 16) | They wake when a PLAYER unit comes within 10 m; buried when the Sexton rises |
| The Sexton | The 4th candle relit, or **19:00** | **The Sexton** at `(0, 48)` (below) | Walks to the Great Crypt (46 m, ~29 s), crushing what blocks it |
| Grave Call | While the Sexton lives, every **25 s** | **4 Wardens** within 6 m of it | Attack-move to Malrik, refreshed every 3 s |
| Laid to rest | The Sexton at 0 HP | Every living `"hollow"` unit crumbles over 2 s (no XP) | Only if all four candles are lit; otherwise the doors still open keep spawning until sealed |

**Gravewarden** (`grave_warden`, new UnitType, gameplay; the Ruin Warden scaled 1.4 with a tombstone slab as a shield):
**900 HP**, armor **20**, Slab Slam **34** + splash r 1.5 (50 %), cooldown 2.2, range 2.2, speed 3.0, sight 12, kill XP 90,
kill essence 40, group `"hollow"`, not a titan (Heart of the Hollow kneels it).

### The Sexton (`sexton`, boss; gameplay 19.C6 family, 19.V-style model E3M3.V2)
Team ENEMY, groups `"units"` + `"boss"` + `"hollow"` (but **boss rules first**: never kneels to the Shard, takes its 60 +
dazed 0.5 s), titan tags (CC half, taunt / knockback immune), no kill XP (the mission ends).
| HP | Armor | Attack "Spade Sweep" | Speed | Radius / height | Sight |
|---|---|---|---|---|---|
| **7 000** | 20 | **70** + knockback 2 m to every PLAYER unit in a 6 m, 90-degree cone, every 3.0 s (x 2 vs buildings) | 1.6 | 2.5 / 9 m | 18 |
| Ability | Rule |
|---|---|
| **Tomb Toss** | Every 10 s: a gravestone lobbed at the biggest PLAYER clump within 25 m (Malrik's clump wins ties): **1.5 s telegraph circle r 3**, then **60** inside |
| **Grave Call** | Every 25 s: 4 Wardens rise within 6 m (table above) |
| **Mourning Toll** | Once, at **50 %**: the bell at its hip rings, r 12: PLAYER units inside `dazed` 1.0 s (heroes 0.5 s); then it **staggers 6 s** (no move, no attack) and its lantern heart opens: **x 1.25** damage taken during the stagger (the M4 Cracked Leg pattern) |
| Path | The straight road from the Lodge to the crypt's south side; it attacks the crypt when it arrives, the nearest PLAYER unit within 6 m first |
Expected normal fight: ~2:30-3:30 (7 000 HP at ~140 army DPS after armour, Spade Sweep and Grave Call cutting that in
half; Hush's Night of Knives x1.5 on a boss, Blood Tithe on the Knights).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (`c_e3_price` and the briefing played before.) Cutscene `e3m3_homecoming` (HOLD 0:20); camera on Malrik; L1-L4; `obj_crypt`, `obj_candles`, `obj_malrik`, `sec_whole` active; hint (10 s) `The barrows will open. Keep the dead away from the Great Crypt, then walk Malrik to each vigil candle.` |
| E2 | 1:30 | B1 and B2 open (amber flash in the doorways, a low groan); message `The Lantern and Weeping Barrows open.` (4 s) |
| E3 | A Warden within 15 m of Malrik (first time) | Cutscene `e3m3_offer` (PAUSE 0:10): L5-L7; Heart of the Hollow enabled (J); the stone's hold line shown; `sec_refuse` active; hint (10 s) `The stone offers its power: J. Wardens near Malrik kneel and the rest are struck. Every use tightens its hold.` |
| E4 | First candle relit | L8; the door seals; Gravewarden call |
| E5 | First Heart of the Hollow | L9-L10; `sec_refuse` failed |
| E6 | The stone's hold reaches 50 % (first time) | L11; the 20 % faster spawn |
| E7 | The stone's hold reaches 100 % | "The stone speaks": L12, Malrik held 5 s, frenzy 30 s; at the release L13 and the meter to 60 % (every time; lines only the first time) |
| E8 | 6:00 | B3 and B4 open; L14-L15 |
| E9 | Hush arrives (call; helper arrival set-piece) | Her arrival bark, then L16-L17 (first call only) |
| E10 | The Great Crypt under 50 % (first time) | L18; `sec_whole` failed |
| E11 | Second candle relit | L19 |
| E12 | Third candle relit | L20 |
| E13 | Fourth candle relit, or 19:00 | World held; cutscene `e3m3_sexton` (PAUSE 0:20): L21-L22 (at 19:00 with candles left: message `The stone has lost patience.` first); Lodge-watch Wardens buried; the Sexton spawned; `obj_sexton` active; hint (8 s) `The Sexton walks on the crypt. Step out of the gravestone circles.` |
| E14 | The Sexton at 50 % | Mourning Toll; L23; message `The Sexton staggers!` (4 s) |
| E15 | The Sexton at 0 HP **and** 4 candles relit | Every `"hollow"` unit crumbles; world held; cutscene `e3m3_rest` (PAUSE 0:30): L24-L26; `Events.mission_ended(true)` 2 s after; StoryFlow plays `c_e3_doubt` |
| E15b | The Sexton at 0 HP with candles left | Message `The Sexton falls. Relight the last vigils.` (5 s); E15 fires when the last candle is relit |
| E16 | Malrik dies | L27; `obj_malrik` failed; defeat after 3 s |
| E17 | The Great Crypt destroyed | L28; `obj_crypt` failed; defeat after 3 s |
| E18 | The Bishop's Seat destroyed | Defeat after 3 s (no line) |
Candles can be relit in any order. The intended rhythm on normal: hold the crypt at 1:30-3:00 and call Hush, relight B1
or B2 ~4:00-5:00, the other ~7:00, B3 / B4 ~10:00-14:00 (a detachment holds the crypt), the Sexton ~15:00-18:00.

## Dialogue (28 lines; speaker colours: Malrik `(0.7, 0.3, 1.0)`, Hush `(0.60, 0.50, 0.75)`, Obren `(1.0, 0.80, 0.25)`, Shade captain **new colour** `(0.62, 0.58, 0.70)`, Narrator `(0.9, 0.85, 0.7)`; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist): `narrator`, `malrik`, `hush`, `obren` (alias of `whisper`), `shade`
(shown as **Shade Captain**, the low flat `am_onyx` voice; the city's watch). Every line <= 2 lines of the box.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Duskbarrow. The city of the dead, where Malrik learned to read by tombstone light. |
| L2 | E1 | malrik | Every vigil out at once. Someone has been very rude to my dead. |
| L3 | E1 | shade | Bishop. The barrows are stirring. The living are in the Great Crypt. All of them. |
| L4 | E1 | malrik | Then the living stay in the crypt, and the dead go back to bed. |
| L5 | E3 | obren | They are mine now, Bishop. Ask me nicely, and they kneel. |
| L6 | E3 | malrik | You raised my dead, and now you sell me the shovel. |
| L7 | E3 | obren | Not sell. Lend. You will hardly notice the price. |
| L8 | E4 | malrik | Sleep. You did your share of standing. |
| L9 | E5 | obren | There. Was that so hard? Again, whenever you like. |
| L10 | E5 | malrik | Useful. Do not get comfortable in there. |
| L11 | E6 | obren | Half yours, half mine. We share so nicely, you and I. |
| L12 | E7 | obren | MINE. Hold still. Let me look out of your eyes. (4 s) |
| L13 | E7 (release) | malrik | Out. OUT. I decide. I have always decided. |
| L14 | E8 | shade | The Pauper's Field and the Bishops' Rest are open! Everything is walking! |
| L15 | E8 | malrik | Even the bishops. Of course even the bishops. |
| L16 | E9 | malrik | The dead are up, Hush. My dead. |
| L17 | E9 | hush | Then they can lie down again. I'll help them. |
| L18 | E10 | shade | The crypt doors are cracking! The families are inside! |
| L19 | E11 | narrator | Two barrows sleep. The stone does not like the quiet. |
| L20 | E12 | obren | Your father dug these graves, Bishop. Shall I show you what I built from his work? |
| L21 | E13 (`e3m3_sexton`) | obren | Forty years he dug here. Let me give him a body. |
| L22 | E13 (`e3m3_sexton`) | malrik | He had one. He wore it out honestly. |
| L23 | E14 | malrik | That bell. He rang it every dusk. Stop wearing my father's bell. |
| L24 | E15 (`e3m3_rest`) | hush | Light it, Bishop. Just this once. |
| L25 | E15 (`e3m3_rest`) | malrik | Not yet. Not while it is listening. |
| L26 | E15 (`e3m3_rest`) | narrator | The vigils burned again in Duskbarrow. In the Bishop's pocket, the stone kept count. (6 s) |
| L27 | E16 | malrik | Bury me... somewhere quiet. |
| L28 | E17 | shade | The crypt is open... the dead are among the living! |
Hush's own barks (arrival, Blink, low HP, fall, revive) are the `helper_hush_<event>` hooks. Echoes: L6 and L22 are the
gravedigger's son of `ep3_opening` (L2, L11 "he never puts the shovel down"); L13 answers `ep3_opening` L10 ("I am the one
who decides") under strain; L24-L25 keep Ep8's payoff intact (`campaign-outline.md` 4.4 E19: he lights his candle only
at the very end); L26 "kept count" is the Ep8 flag in the narrator's mouth.

## Cinematic hooks (ENGINE on the live scene unless marked; CinematicPlayer 19.C1; skippable; units frozen while they play)
| Id | When | Mode / length | Shots (camera, what we see) | Lines | End state (a skip leaves exactly this) |
|---|---|---|---|---|---|
| `c_e3_price` | Before the briefing | Stage film ~1:10 | Written by E3M2.D1 (beats in `mission-e3-02.md`) | - | Briefing |
| `e3m3_homecoming` | E1 | HOLD 0:20 | 1) CRANE down from above the Seat at violet dusk: a city of small candle-lit windows, the slope falling south; 2) four barrow doors, dark; one dead candle on its iron stand in the foreground, a thread of smoke; 3) MS Malrik riding down the Lantern Road, 3/4-left, his candle unlit in his hand | L1 | Malrik at `PLAYER_START`, the army at `(0, -16)`, mission clock at 0:00 |
| `e3m3_offer` | E3 | PAUSE 0:10 | 1) ECU the stone in Malrik's hand, amber light through his fingers; 2) MS: the nearest Wardens turn their heads toward the stone at once, like dogs hearing a whistle | L5-L7 | Heart of the Hollow enabled, the meter shown |
| `e3m3_sexton` | E13 | PAUSE 0:20 | 1) WIDE the Lodge at dusk, its bell ringing by itself; 2) gravestones tear out of the barrows' earth and fly to the yard; the old spade rises; 3) LOW: the Sexton stands up, 9 m, tombstone ribs, a lantern for a heart, the spade for a right arm, the bell at its hip; it turns toward the crypt | L21-L22 | The Sexton at `(0, 48)` facing north, walking; Lodge-watch Wardens gone; Malrik where he stood |
| `e3m3_rest` | E15 | PAUSE 0:30 | 1) The Sexton kneels in the Lodge road and comes apart into gravestones, the lantern rolling free; 2) MS: the spade standing upright in the earth; Malrik walks up to it; 3) two-shot Malrik and Hush, 3/4-left: she holds out a burning taper for his candle; he looks at it a long moment and puts the candle away (L24-L25); 4) WIDE: the four vigils burn violet at the barrow doors; the stone pulses once in his pocket; FADE_BLACK | L24-L26 | Victory 2 s later |
| `c_e3_doubt` "Torvald's Doubt" | After victory (StoryFlow) | Stage film ~1:10 | Beats for its writer (E3M3.D1): Evenmead ridge at night, Torvald's pavilion; Aldra (`aldra`, his Glass Warden) sets down a report: the old storm-sword has crossed the river twice to look at the ridge; Malrik arrives back, Hush behind him; Torvald watches the stone glow through Malrik's coat and asks what it cost; Malrik: "A little. Less than you would think." Aldra, after he leaves: "It glowed when he lied." Torvald: "I know. I saw." If `e3m3_refused`: Aldra instead: "It didn't glow at all. That frightens me more." | - | StoryFlow continues to e3m4's briefing |
Fallbacks: `e3m3_homecoming` = camera on Malrik + L1; `e3m3_offer` = L5-L7 as dialogue with a 1 s amber pulse on Malrik;
`e3m3_sexton` = the Sexton spawned with a 2 s rise tween, L21-L22 as dialogue; `e3m3_rest` = L24-L26 as dialogue, then
victory.

## Tiers and the helper
| Item | Value |
|---|---|
| Code | `MissionE303._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = true`, `helpers_enabled = true`; `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(3)` on the Seat |
| Bishop's Seat card | Z Gloom Thrall · X empty · **C Nightblood Reaver** · **V Call Mother Hush** (350 + 200, 60 s), then Revive (120 + 20 x level essence, 25 + 5 x level s) · B Gloom Deacon · Set Rally r3c1 |
| Hush | `helper_hush` at Malrik's level (L5 x 1.16: 660 HP, 36 damage, Night of Knives on), stances, F4. Her kills feed Malrik's team as usual; Wardens count for Shadow Souls (the Mage Archer rule of `t3-helpers.md` 4.1) |
| The Shard | Its power is not a tier unlock: it comes with E3 |

## Economy
| Item | Value |
|---|---|
| Start | 400 crystals, essence 150 + carried, 20 / 60 pop, 6 Thralls |
| Nodes | Home 2 x 1 500; two ossuary expansions 2 x 2 000 (out of every barrow lane: safe, but 46 m from the Seat); the rich `e3m3_tithe` 2 500 on the Sexton's road (lost once it rises) |
| Expected income (normal) | ~10 Thralls by 5:00; ~3 800 crystals mined by 20:00 |
| Kill essence | Warden **15**, Gravewarden **40** (the dead are poor), the Sexton nothing (the mission ends) |
| Essence (expected by 20:00) | 150 + carried (~800) + trickle ~1 200 + kills ~1 300 (~70 Wardens, 6 Gravewardens) - 200 (Hush) = **~3 200**: Hush plus one top item for Malrik |
| The real spend | Hush (350 + 200) at ~2:00-3:00, 2 Nightblood Reavers and a second Deacon by 8:00; the stone is free, which is the point |

## Win / lose
| Event | Result |
|---|---|
| The Sexton laid to rest **and** 4 candles relit | **Victory** (after `e3m3_rest`) |
| Malrik dies | **Defeat** (instant loss) |
| The Great Crypt destroyed | **Defeat** |
| The Bishop's Seat destroyed | **Defeat** |
| The stone speaks (100 %) | Nothing by itself (5 s held, frenzy 30 s) |
| Hush falls | Nothing; revive at the Seat |
| All Shadow soldiers dead, Malrik alive | Nothing; he can still rebuild |

## Reward carried to e3m4 (Malrik's track)
- Keystone Shard (with its power from now on) stays owned and equipped. The 6 slots at victory; essence 50 %, cap 1 500;
  **+300 first if `sec_refuse`**, **+200 first if `sec_whole`**.
- `CampaignState.MISSION_REWARDS[&"e3m3"] = {"flags": {"e3m3_refused": "sec_refuse", "e3m3_crypt_whole": "sec_whole"},
  "bonus_essence": {"sec_refuse": 300, "sec_whole": 200}, "next": &"e3m4"}`; mission-computed and written at E15:
  `e3m3_shard_uses` (int), `e3m3_seizures` (int), and the **track counter `shadow_stone_uses`** += `e3m3_shard_uses`
  (created here at 0; e3m4 and Ep8's Shadow road add to it).
- **Ep8 hook** (recommendation for the e8m1 writer, `campaign-outline.md` 4.2 Shadow road): Mother Hush, "loyal to the
  stone's power", is the boss of `e8m1_shadow`; she watched every use: her boss HP **+5 % per `shadow_stone_uses`** (cap
  +25 %), on top of the road's own +5 % per use on the final boss. With `shadow_stone_uses == 0` she hesitates once at 50 %
  (a free 6 s window and the line "You never used it. Not once.").
- Level not carried.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Warden / Gravewarden counts | x 0.6 (1 Warden per spawn) | as written | x 1.4 (3 per spawn) |
| Spawn interval / max per door | 36 s / 6 | 30 s (25 s from 12:00) / 8 | 25 s (20 s from 12:00) / 10 |
| B3 / B4 open | 7:30 | 6:00 | 5:00 |
| Great Crypt HP | 3 600 | 3 000 | 2 600 |
| The Sexton HP / forced rise | 5 000 / 21:00 | 7 000 / 19:00 | 9 000 / 17:00 |
| Start crystals | 550 | 400 | 300 |
| Heart of the Hollow / stone's hold per use | same 45 s / +20 % | same | same (the price never changes with difficulty) |
| Expected time | 17-21 min | 20-25 min | 23-29 min |
**Fight sizing** (normal; army value: Warden **110**, Gravewarden **330**, the Sexton **~2 600** (7 000 HP, armor 20,
~45 DPS + adds); every guarded fight <= 70 % of the player's force then, Malrik and Hush counted as `170 + 30 x level` and
`200 + 40 x level`).
| Fight | When | Enemy | Player then | Ratio |
|---|---|---|---|---|
| First stream at the crypt (B1 + B2, 2 x 2 Wardens / 30 s) | 2:00-3:00 | ~880 arriving over a minute, ~440 at once | 1 190 + Malrik L5 (320) | 29 % at once |
| Clearing B1's door for its candle | ~4:00 | up to 8 Wardens if neglected (880), usually 2-4 (220-440) | ~1 900 + Hush (~400) | 10-38 % |
| Three open doors + Gravewarden call | ~7:00-10:00 | ~1 320 / min spread over 3 lanes, + 2 x 330 | ~2 800 (2 Reavers, 2 Deacons) + Hush + Malrik | ~45 % per lane fight |
| B3 or B4 (far, the army split) | ~11:00-14:00 | 8 Wardens + 1 Gravewarden (1 210) | detachment ~2 000 + Hush + Malrik | 52 % |
| The Sexton + Grave Call | ~15:00-18:00 | 2 600 + 440 per 25 s | ~3 800 + Hush L6-L7 + Malrik | ~70 % (the boss is the episode's middle peak) |
- **The temptation is tuned to be real**: one Heart of the Hollow kneels a whole door's Wardens for 8 s at x 1.5 damage
  (a free clear for the candle) and heals Malrik; three uses make the B3 / B4 walk easy; the Sexton fight is ~25 % shorter
  with it on cooldown. Refusing is a fair test on normal: the Gloom Deacon's Umbral Passage (pull the army back to the
  crypt from a far barrow), Blood Tithe on the Knights and Hush's Blink on Gravewardens are the intended tools.
- **The price is real too**: a player who uses it on every cooldown reaches 100 % around 7:00, is held 5 s while the
  Wardens frenzy (usually at a candle), and spawns 20 % faster for the rest of the mission.
- Watch in the first playtest: if nobody uses the stone, cut its cooldown to 35 s; if everybody does and still wins
  easily, make 50 % also give Wardens +10 % HP.

## Target length (normal)
| Part | Time |
|---|---|
| `c_e3_price` + briefing (outside) | ~1:30 (not counted) |
| `e3m3_homecoming` + `e3m3_offer` | 0:30 |
| The barrows (`mission_time` to the 4th candle) | 13:00-16:00 |
| `e3m3_sexton` | 0:20 |
| The Sexton | 2:30-3:30 |
| `e3m3_rest` + 2 s | 0:32 |
| **Total** | **~17:00-21:00 clean, 20-25 with a lost lane or a seizure** |

## Implementation tasks (the lead adds them to `waves.md`)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| E3M3.M1 [H] | four-wizards-high (World Forge map mode) | `data/maps/duskbarrow.map` + layout: 120 x 120, seed 3303, every row of the Map table +-0.5 m, lanes and the Lantern Road as paths, barrow walls and mausoleum rows as navigation geometry, gravestone fields off the lanes | World Forge map mode | Map Lab >= 90; the generator check paths exist; no prop within 2 m of a lane or a candle |
| E3M3.S1 | systems | `missions/mission_e3_03.tscn` + `MissionE303`: load the map; start state (Seat at tier 3, 400 / 150 + carried, 20 / 60, Hovel max 4, the no-save fallback); `great_crypt` (3 000 HP, vigil aura, regen, fog-visible); 4 `barrow_door` + 4 vigil candles (4 s / 3 m, blocked at 8 m, seal + crumble 12 m); the Lodge watch; spawn rules (timings, max per door, interval changes); the Sexton's spawn point | E3M3.M1, M9.S1 | `tests/test_e3m3_s1.gd`: B1 opens at 1:30 and spawns 2 Wardens per 30 s up to 8; a candle with a Warden at 7 m stays grey and relights in 4 s once it dies; sealing B1 crumbles a Warden 10 m from the door and stops its spawns; the crypt regains 0.5 % / s with no enemy within 12 m |
| E3M3.S2 [H] | systems-high | Objectives and events E1-E18 in order; the stone's hold (sources, 50 % and 100 % effects, the 60 % reset, seizure count); Gravewarden calls; the forced rise at 19:00; the victory rule (Sexton + 4 candles, E15b); the 28 lines; win / lose; difficulty table; `MISSION_REWARDS[&"e3m3"]`, `e3m3_shard_uses`, `e3m3_seizures`, the track counter `shadow_stone_uses` | E3M3.S1, E3M3.I1, E3M3.G1 | `tests/test_e3m3_s2.gd`: five uses of the power reach 100 % and hold Malrik 5 s, the meter reads 60 % after; an own Shade's death adds 0.5 %; a scripted run with 0 uses wins on normal with `sec_refuse` done; the save holds the counters; the Sexton rises at 19:00 with 2 candles lit |
| E3M3.I1 | items | `keystone_shard` gains its active `shard_heart` (cooldown 45 s, r 14, `stilled` 8 s on `"hollow"`, 60 + dazed elsewhere, 50 % heal, +30 spell power 8 s) and a signal `artifact_power_used(item_id)` on `Inventory` for the mission's meter; refusals in order `"Dead"`, `"The stone holds you"`, `"Recharging"` | E3M1.I1 | `tests/test_e3m3_i1.gd`: 3 Wardens at 10 m kneel 8 s and take x 1.5; 3 Flame Guards at 10 m take 60 each, are dazed 1 s, and Malrik heals 90 (50 % of 180); a second use at 30 s is `"Recharging"`; the signal fires once per use |
| E3M3.G1 [H] | gameplay-high | `grave_warden` UnitType; the Ruin Warden `barrow` look hook; status **`stilled`** (no move, no attack, x 1.5 damage taken; bosses and titans immune); the **Sexton** boss (stats, Spade Sweep cone + knockback, Tomb Toss telegraph, Grave Call, Mourning Toll + 6 s stagger at x 1.25, its path to the crypt) | 19.C6 | `tests/test_e3m3_g1.gd`: Sweep hits 3 Shades in the cone and not one behind it; Toss lands 1.5 s after its circle; the Toll fires once at 50 % and dazes heroes 0.5 s; `stilled` never applies to the Sexton |
| E3M3.U1 | ui | The stone's hold line and the amber arc on Malrik's portrait; the **J** power button on the command card (artifact icon `KS`, cooldown overlay, refusal messages) and on artifact slot 1; the Great Crypt HP bar; the Sexton boss bar (marks 100 / 50); barrow markers on the minimap (amber open, violet sealed); the Shade Captain name and colour | E3M3.S2 | J by physical keycode; readable at 1600 x 900 and 3440 x 1440; nothing calls a `_private` function |
| E3M3.C1 | four-wizards-high (cine) | `e3m3_homecoming`, `e3m3_offer`, `e3m3_sexton`, `e3m3_rest` as cine timelines on the mission scene | 19.C1, 19.C2 | `cine check` 0 FAIL; every skip leaves its end state |
| E3M3.V1 [H] | tech-artist | Duskbarrow kit: Bishop's Seat dressing (Shadow keep, Citadel look with candle windows), mausoleum rows, barrow walls, barrow door (closed / open amber / sealed), vigil candle stand (cold / violet flame), Great Crypt (dome, great candle), Gravedigger's Lodge (house, bell post, spade), cobbles, violet dusk preset; 0 lights | E3M3.M1 | Art Lab pass; `PERF OK` with 4 open doors, 32 Wardens and 60 units on screen |
| E3M3.V2 [H] | tech-artist | The Sexton model (9 m: tombstone ribs, lantern heart with emission, spade arm, hip bell) with states walk, sweep, toss, call, toll, stagger (heart open), collapse; Gravewarden; the Warden `barrow` look | - | Art Lab contact sheet beside Malrik at 40 m; <= 26 meshes for the Sexton |
| E3M3.V3 | tech-artist | VFX: Heart of the Hollow pulse + amber strings + kneel, the stone's hold chains on Malrik, the seizure, candle relight + door seal, the Toll ring; <= 2 particle systems each | - | 0 lights; pooled |
| E3M3.O1 | Voice Forge agent | `data/voice/lines/e3m3.json` (L1-L28), no new speaker (`shade` exists) | E3M3.D1 | Every WAV fits its slot (L12 4 s, L26 6 s) |
| E3M3.D1 | game-designer | Read the 28 lines in game, trim over-long ones; write `c_e3_doubt` (~1:10) from the beats above | Playtest | Script written; changes back in this doc |
| Lead | lead | `CLAUDE.md` keys line: **J** = the path ability (skirmish) / the equipped artifact's power (missions) | - | Contract line updated |

## Acceptance checks
- [ ] E3M3.M1 / S1: Duskbarrow builds from seed 3303 with every table position +-0.5 m; the four barrows open on time,
  spawn to their caps and seal only by Malrik's candle; the Great Crypt is the Wardens' first target.
- [ ] E3M3.S2: a scripted normal run (call Hush at ~2:30, relight B1, B2, B3, B4, kill the Sexton) **with 0 uses** of the
  power ends `victory=true` in 20-25 game-minutes in 3 / 5 seeds and never loses the crypt in 5 / 5; the same run **with
  the power on every cooldown** wins faster and records >= 1 seizure.
- [ ] The stone's hold: +20 % per use, +0.5 % per own soldier death, 50 % speeds the spawns, 100 % holds Malrik 5 s and
  resets to 60 %; the J refusals read as listed.
- [ ] The Sexton: rises at the 4th candle or at 19:00; the Toll once at 50 %; victory only with 4 candles lit.
- [ ] The save holds `e3m3_refused`, `e3m3_crypt_whole`, `e3m3_shard_uses`, `e3m3_seizures`, `shadow_stone_uses`; e3m4's
  start reads them.
- [ ] `PERF OK` with the Sexton, 4 open doors and the full army; every cutscene skip leaves its end state.
- [ ] Lead: one human playtest on normal: did the player use the stone, how often, and did the price feel fair (logged in
  `docs/plan/usage-log.md`).

Dependencies: E3M3.M1 map, `MissionBase` (M9.S1), `MissionBrazier` with `is_blocked()` (M4 19.C5a), the Warden Gate family
and Ruin Warden (19.C6, M3), `HelperRoster` + Hush (TH.G1, TH.S1), the Nightblood Reaver (TH.G2), the Shard item (E3M1.I1),
19.C1 / 19.C2 for the cutscenes (fallbacks otherwise).

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Nightblood Reaver (first trained e3m2).
- **Why here:** an all-undead, all-melee enemy with no fire at all: the 35 % lifesteal is never halved; strong in long fights and against heavy melee.
- **Moment:** B3 / B4 open (6:00): 2 Reavers hold a lane alone; "Nightblood Reavers drink: in a long fight with no fire, they never fall.".
- **Intro card:** `Nightblood Reaver. A duelist that drinks: the longer the fight, the stronger it stands. Fear fire.`

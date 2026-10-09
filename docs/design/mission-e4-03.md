# Campaign mission e4m3: "The Frozen Ashes" (Ysolde + Maelis vs Torvald + Aldra; Episode 4)

Written 2026-10-02 (`campaign-outline.md` 3.4). Episode 4 "What Grows Back", mission 3 of 4 (id `e4m3`, outline D6).
Ysolde goes back to the **Sighing Wood**: burnt by Shadow and frozen by Ice in Episode 2, kept dead since by Torvald's
rime and Aldra's totems. She must **thaw and regrow five groves** while Torvald (Ice bot) and Aldra (enemy story unit,
her own camp) hold the wood. A **regrowth** mission: break the frost, plant, keep the growing ground alive, then hold all
five green at once. Reward: the **Heartwood Seed**, Ysolde's token and first artifact. Target **22-26 min** on normal.
Uses `mission-e2-01.md` (the same map, seed 1303, the Heartwood / Rime Totem / frost props), `mission-01.md` rules
(MissionBase, scripted groups, 70 % rule, difficulty multipliers), `tiers.md` 6, `t3-helpers.md` 3-4 (Maelis, Aldra's
kit), `caster-units.md` 5.3, `kingdom-nature.md`, `kingdom-ice.md`, `items.md` campaign rules. New scene
`missions/mission_e4_03.tscn` + `scripts/campaign/mission_e4_03.gd` (`MissionE403 extends MissionBase`, mission id
`e4m3`). Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `+z` = south. Status: **design only**.
Recommended option taken everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map | **e2m1's "The Burning Grove"** (120 x 120, the `main.gd` generator, `MAP_SEED := 1303`, the burnt-and-frozen wood variant, every e2m1 position kept), a few months later: **more snow** (north and west fully white, the ash only south-east), the Last Heartwood still alive under new rime. Changes for this mission are listed in "Map" and are the only ones | Outline: "The Sighing Wood (burnt + frozen, e2m1's map)"; one map, two missions, the e3m1 / e4m1 pattern |
| D2 | Where the player starts | **South-east**, at the Greenhold ruins (Ysolde's burnt border keep of e2m1 S3): a **new Heartwood** grown on the ruin, **at the Stronghold** (the episode's tier rule: the Citadel opened in e4m2), Grove Hall and 2 Seed Hollows pre-built | Ysolde's own land, the corner e2m1 left to burnt Nature; both Ice camps are on the far side of the wood |
| D3 | Who holds the wood | **Torvald** (Ice bot, north-west camp, real workers, defend + scripted waves) and **Aldra** (enemy story unit, `t3-helpers.md` 4.4 kit at Torvald's level, her own scripted camp in the north-east, Malrik's old camp spot). No Shadow, except Hush's last hunt if e4m2 left the hunters alive | Outline: "while Torvald and Aldra hold the wood"; Malrik is at his crypt (e3m3) |
| D4 | Maelis | **Already called at 0:00** (`helper_start_called = true`, new mission knob): she stands beside Ysolde as her called helper (pop 4 used, stance Escort, the V button reads `Revive Maelis` when she falls). The Citadel here opens the Briar Roc only | The helper was unlocked in e4m2 (`helper_maelis_unlocked`); making the player re-buy her each mission would hide her for 8 minutes of her own episode |
| D5 | The regrowth rule | New prop **`MissionGrove`** (systems, a `MissionBrazier` subclass with a growth meter): frozen -> thawed (its Rime Totems dead) -> **planted** (Ysolde channels 4 s) -> **growing** 0-100 % in 60 s -> **grown** (a `Building`-like Grove Heart, team PLAYER). Enemies pause and can **re-rime** it; a destroyed grove goes back to frozen ash | "Thaw and regrow" as one readable loop the player can lose and redo; reuses the e2m1 kindle code |
| D6 | The win | **Five groves grown at the same time**, then **hold 1:30** with at least four of them standing while the Ice makes its last push. Victory at the end of the hold | Ending on a hold gives the episode's third act a peak and Torvald's "seed of the turn" a place to happen (cutscene `e4m3_shoot`) |
| D7 | The Heartwood Seed | New campaign artifact **`heartwood_seed`** (outline C7; row for `items.md` below), given at victory: the seed-pod token Vessa kept since `c_e2_ashes` and sent back in `c_e4_turnback` wakes when the wood does | The outline's "Heartwood Seed artifact (Ysolde's token, new items.md row)" |
| D8 | Terrain | **Look now, rules later** (e2m1 D9): if `TerrainSystem` exists the patches are registered (`snow` north / west: Ice +25 % speed; `ash` south-east: Fire +10 %, nobody here); a grown grove paints **moss** r 12 (cosmetic, or `grass` if TerrainSystem exists: the snow speed bonus stops there) | TerrainSystem is not built; the mission must not wait for it |
| D9 | Emberwatch | Vessa's Fire border keep in the south-west stays **hers**: team PLAYER, scripted, invulnerable, not selectable, a **base shop** (Fire list + the exchange); its two nodes are free for the player | A small gift from the ally who is not here; the corner is otherwise dead ground |

## Story setup (briefing text, 3 short paragraphs; shown after `c_e4_turnback`)
1. The people are safe behind Vessa's border. Ysolde did not stay. She walked back east, into the wood she was born to
   keep, with a seed-pod in her hand that Vessa had kept for her all year.
2. The Sighing Wood is still ash under rime. Torvald holds its west; Aldra Stillwater, his Glass Warden, holds its east,
   and her totems keep five old glades frozen so that nothing grows there again.
3. Break the frost. Plant. Keep the young groves alive until all five are green at once. A wood that grows back cannot
   be held by anyone who wants it dead.
Briefing objectives: `obj_groves`, the rule `Ysolde must survive`, the line `Groves grow only while no enemy stands in
them. Guard them while they grow.`

## Map: "The Sighing Wood in winter" (120 x 120, `main.gd` generator, seed 1303, not mirrored)
**Binding:** e2m1's map table, generator variant (charred broadleaf and oak, frost-rimed tops) and its clearings, with
these changes (and nothing else):
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| **Heartwood** (player, tier 2 Stronghold, 2 700 HP) | `(43, 43)` on the Greenhold ruins (e2m1 S3) | **18** (was 12) | `PLAYER_START` = Ysolde at `(36, 36)`; the ruin decor stays around the keep's roots |
| Grove Hall / Seed Hollows (pre-built) | `(43, 27)` / `(56, 50)`, `(46, 58)` | 4 / 3 | 16 m / 14.8 m, 15.3 m from the keep |
| Node `e4m3_green_a` / `e4m3_green_b` | `(52, 35)` / `(35, 50)` | - | **1 500** each (12.0 m / 10.6 m from the keep) |
| Node `e4m3_charred` (expansion; e2m1 hideout S2) | `(26, 28)` | 7 | **2 000**; hall spot `(20, 22)` |
| Node `e2m1_south` | `(4, 50)` | 7 | **1 500** (e2m1's), hall spot `(-3, 51)` |
| **Emberwatch** (Vessa's, D9) | keep `(-43, 43)`, Ember Hall `(-27, 45)` | 18 | Scripted, invulnerable, shop; nodes `(-46, 34)` / `(-34, 46)` 1 500 each free to mine |
| **Torvald's camp** (Ice bot) | Rime Keep `(-43, -43)` (tier 2, 3 600 HP), Frost Hall `(-27, -45)`, Rime Spire `(-37, -29)`, Snow Lodge `(-50, -46)` | 18 / 4 / 3 / 4 | e2m1's positions; **real bot now**: 5 Rime Haulers on `(-46, -34)` / `(-34, -46)`; rally `(-30, -30)` |
| **Aldra's camp "Glasswater Watch"** (scripted, no workers) | **Glass Spire** `(43, -43)` (replaces the Dusk Keep), Frost Hall `(27, -45)`, Rime Spire `(37, -29)`, Snow Lodge `(50, -46)` | 18 / 4 / 3 / 4 | Malrik's e2m1 slots, Ice buildings. Glass Spire: 2 500 HP, armor 20, a 7 m tower of rune-glass, shoots `(range 11, 14 dmg, cooldown 1.4, chill 1.5 s)`, `counts_for_defeat` false; Aldra's rally `(30, -30)` |
| Wave spawns | Torvald: Frost Hall `(-27, -45)` spawn point (Rime Keep's if gone; corner `(-56, -56)` if both) · Aldra: her Frost Hall `(27, -45)` (Glass Spire's door if gone; corner `(56, -56)`) | - | - |
| The dead Oldroot / Lost Caches | `(0, 0)` r 3 obstacle / `(-15, -15)`, `(30, 0)` | - | Unchanged |

**The five groves** (`MissionGrove`, D5). Each sits on an e2m1 / M3 glade; totems 400 HP, armor 10, team ENEMY
(`RimeTotem`, blue frost beam into the grove).
| # | Grove | Grove centre (plant spot) | Rime Totems | Guard (scripted, 2x leash) | From the Heartwood |
|---|---|---|---|---|---|
| 1 | **Hollowfen** (M3 RH2) | `(18, 44)` | 1: `(18, 37)` | none (the teaching grove) | 25 m |
| 2 | **Stagwatch** (M3 RH3) | `(44, 14)` | 2: `(38, 9)`, `(50, 9)` | **G2** 3 Rimeshields + 2 Shardcasters (520) | 29 m |
| 3 | **Heartglade** (e2m1; the Last Heartwood) | `(0, 9)` (the Last Heartwood itself) | 3: `(-7, 9)`, `(7, 9)`, `(0, 16)` (e2m1's) | **G3** 4 Rimeshields + 2 Shardcasters + 1 Rime Seer + 1 Frost Mortar (930) + **Aldra** (first meeting) | 57 m |
| 4 | **Fernhollow** (e2m1 S1) | `(-30, -4)` | 2: `(-35, -9)`, `(-25, -9)` | **G4** 3 Rimelings + 2 Shardcasters + 1 Rimecarver (535) | 89 m |
| 5 | **Mossgate** (M3 RH1) | `(-44, -18)` | 3: `(-50, -14)`, `(-38, -14)`, `(-44, -11)` | **G5** 4 Rimeshields + 2 Hoarlight Magebows + 1 Shardguard (815) | 105 m |
Mossgate's centre is 13 m from Torvald's Rime Spire (out of its range 10 at the plant spot; the north edge of the grove's
ring is inside it). Distances (navmesh, approx.): Heartwood -> Heartglade 57 m; Aldra's Frost Hall -> Stagwatch 56 m,
-> Heartglade 59 m; Torvald's Frost Hall -> Fernhollow 47 m, -> Mossgate 31 m. Generator check (E4M3.S1): paths from
`PLAYER_START` to every grove, both camps and Emberwatch; no tree or rock within r 10 of a grove centre.

**`MissionGrove`** (systems; one per grove):
| State | Rule |
|---|---|
| Frozen | Rime decal r 8, a dead-ash stump; while any of its totems stands nothing can be planted. Team NEUTRAL, ignored by units |
| Thawed | All its totems dead: the decal cracks (2 s); a green pulse marks the plant spot |
| Planting | **Ysolde within 4 m for 4 s** with **no enemy unit and no totem within 10 m** (progress ring; leaving resets; the e2m1 kindle message `Clear the glade first: the roots won't open while the enemy stands in it`) |
| Growing | Meter 0 -> 100 % over **60 s** x `(1 + 0.25 x own soldiers within 8 m, max x2.0)`. **Paused** while any enemy unit is within 8 m. **Re-rimed** (back to Thawed, meter 0) if an enemy unit stays within 8 m for **10 s** with no own unit within 8 m. A sapling decal grows with the meter |
| Grown | A **Grove Heart** (team PLAYER, `Building`-like target: **900 HP**, armor 10, regen 1 % / s after 10 s undamaged, sight 14, a thorn bolt like a Bramble Spire: 10 damage, range 10, cooldown 1.2), **Sap Ward** aura r 8 (own units `idle_regen_pct` +1.0, e2m1's `aura:sap`), paints moss r 12 (D8). `counts_for_defeat` false |
| Destroyed | Back to **Thawed** ash (no new totems); re-plantable after 30 s |
The Heartglade's Grove Heart **is** the Last Heartwood (e2m1's prop at `(0, 9)`, 1 500 HP there; here 900 like the others,
its rime falls away when planted). Wild Bloom heals Grove Hearts (Nature support works on them, like the Heartwood in e2m1).

## Start state (Ysolde's track, campaign-outline D8)
| Item | Value |
|---|---|
| Ysolde | **Level 5 with 4 unspent points** (Thornburst r1 known), **cap 8** |
| Items / artifacts | From the save: the 6 slots; no artifact (the Seed is this mission's reward) |
| Essence / crystals | **150** + carried / **400** (easy 500, hard 300); essence +1 / s |
| Buildings | Heartwood (tier 2 Stronghold), Grove Hall, 2 Seed Hollows (all complete) |
| Units | 6 Spriglings gathering (3 / 3); 6 Thornlings, 3 Burr Slingers, 2 Bloomtenders, 2 Vinelashers, 1 Greenheart Oathkeeper, 1 Bramblehorn, 1 Bramblesage at `(36, 32)` (**1 480** crystals of army); + 4 volunteer Thornlings (veterancy 2) if `e4m2_folk_arrived >= needed + 5` |
| Maelis | **Called** at 0:00 (D4), level 5 (Wild Stampede ready), Escort, beside Ysolde |
| Population | 6 + 19 + Maelis 4 = **29 / 60** (Heartwood 20 + 2 Seed Hollows x 20; max 4 = cap 100) |
| No save | Empty slots; essence 150 + **600**; no volunteers |
| Torvald (Ice bot) | **Level 6** (Rime Bolt r2, Flash Freeze r2, Rime Aegis r1) at `(-30, -30)`; Rime Keep (Stronghold), Frost Hall, Rime Spire, Snow Lodge, 5 Rime Haulers; 4 Rimeshields + 2 Shardcasters + 1 Rime Seer at the rally |
| Aldra (enemy story unit, team ENEMY) | `aldra_story`: `t3-helpers.md` 4.4 kit at **Torvald's level** (L6: 845 HP, armor 15, 28 damage, range 9; Glasswater Ward, Shatterglass, Glass Aegis, **Wake the Sentinel**); first at the Heartglade, channelling the rime |
| Fog | On; all five grove centres and their totems explored for the player at 0:00 (the minimap shows five frozen-blue glade icons) |
| Champions, trade, camps, beasts, river, points | Off |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Seed Hollow (max 4), Grove Hall, Bramble Spire | Elder Circle (e4m4), Stables, Bazaar |
| Units | Sprigling; Grove Hall: Z Thornling, X Burr Slinger, C Bloomtender, V Bramblehorn, N Thistle Darter, M Vinelasher, `,` Greenheart Oathkeeper; keep: B Bramblesage, **C Briar Roc** (from the Citadel) | Wildwood Archer (skirmish only), Elder Treant (e4m4) |
| Keep | **Citadel** (X, 300 crystals, 90 s, from **5:45**) | - |
| Helper | Maelis already called (D4); `Revive Maelis` (V) at the skirmish price (120 + 20 x level essence, 25 + 5 x level s) | - |
| Spells | Thornburst, Wild Bloom, Call the Thicket; cap L8 | - |
| Items | Base shop (Heartwood, Grove Halls) and Emberwatch (D9); the 2 caches | - |

## Tiers and the helper
| Item | Value |
|---|---|
| Code | `MissionE403._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = true`, `helpers_enabled = true`, **`helper_start_called = true`** (new knob: `HelperRoster` spawns the team's unlocked helper at the keep door at 0:00 as if called, no price, no set-piece); `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(2)` |
| Heartwood card | Z Sprigling · X **Citadel** · C **Briar Roc** (`Requires Citadel`) · V `Revive Maelis` (greyed `Not fallen` while she lives) · B Bramblesage · Set Rally r3c1 |
| Citadel hint | Once (12 s): `Your Stronghold can become a Citadel: select the Heartwood and press X (300 crystals, 90 s). It opens the Briar Roc (C): its Seed Storm roots from the air, out of the totems' reach.` |
| Torvald's keep | Never upgrades; his scripted waves carry their tier-2 / tier-3 units (Frost Mortar, Hoarlight Magebow, Shardguard, Rime Colossus) |

### The Bramblesage here (`caster-units.md` 5.3)
**Snagroot** drags the **Rime Seer** out of G3 (its shields keep the Rimeshields alive) and the **Frost Mortar** off its
perch; it also pulls a single Rimeshield out of a growing grove's 8 m ring to stop a re-rime. **Pollen Haze** shuts the
Shardcasters and Magebows while the army works on the totems. Hint at E3.

### Aldra Stillwater (enemy story unit `aldra_story`)
`t3-helpers.md` 4.4 at Torvald's level: **Glasswater Ward** (own units -12 % from ranged and spell hits within 8 m; Bond:
Torvald's Rime Bolt / Flash Freeze victims near her get +34 frost), **Shatterglass** (11 s line, 50 + 34 frost),
**Glass Aegis** (20 s, 100 shields on the 4 lowest own units), **Wake the Sentinel** (90 s, a Rime Colossus for 30 s).
Brain: Hold home at her current anchor (the Heartglade until E6, then the Glass Spire), joins the wave that carries her.
**Flees** at 25 % HP (glass shards burst, she reappears at the Glass Spire) and returns **90 s** later with the next wave,
full HP. If the Glass Spire is destroyed (`sec_spire`) she **does not return** until the Final.

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_groves` | Primary | `Regrow the groves of the Sighing Wood (0 / 5 green at once)`; five icons below: frozen / thawed / growing % / grown | Five Grove Hearts stand at the same moment |
| `obj_hold` | Primary (after `obj_groves`) | `Hold the groves until the wood answers (1:30 · at least 4 standing)` | 90 s with >= 4 Grove Hearts standing; the countdown **pauses** (`(paused)`) with fewer, never resets |
| `obj_ysolde` | Primary, always shown | `Ysolde must survive` | Fails = defeat |
| `sec_spire` | Secondary | `Shatter Aldra's Glass Spire` | The Glass Spire at `(43, -43)` is destroyed |
| `sec_unbroken` | Secondary (appears at the first grown grove) | `Lose no grove once it is green` | Done at `obj_hold` if no Grove Heart was ever destroyed; **failed** at the first |

## Guards, waves and the bot (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Guards G2-G5 (grove table) hold their spot with a 2x leash. Waves are spawned by the mission and attack-move as listed,
refreshed every 3 s. "The target grove" = the **growing** grove with the highest meter, else the grown grove nearest the
wave's spawn, else the Grove Hall.
| Wave | Trigger | Units (spawn) | Order |
|---|---|---|---|
| R1 re-rime | 3:30 | 3 Rimeshields + 1 Rime Seer + 1 Rimecarver (Aldra's Frost Hall) | The target grove |
| Counter-waves | 45 s after each grove becomes grown (first time per grove) | nth grown: **1st** 3 Rimeshields + 2 Shardcasters · **2nd** + 1 Rime Seer · **3rd** + 1 Frost Mortar · **4th** + 1 Rime Colossus (from the camp nearer that grove) | That grove |
| Hush's last hunt (only if `e4m2_hollow_burned` is false) | 9:00 | **Hush** (L5) + 4 Shades (east edge `(58, 0)`, veiled) | Ysolde; Hush flees at 25 % and does not return |
| Aldra's frost | 12:00 (or when the Heartglade becomes grown, if later than 12:00: 30 s after it) | **Aldra** + 4 Rimeshields + 2 Shardcasters + 1 Frost Mortar (Aldra's Frost Hall) | The grown grove with the most HP; Aldra casts Wake the Sentinel on arrival |
| Torvald's march | 16:00 | **Torvald** + 4 Rimeshields + 2 Shardcasters + 1 Rime Seer + 1 Rime Colossus (Torvald's Frost Hall) | The Heartglade if it is growing or grown, else the target grove; Torvald retreats under 35 % (bot rule 8) |
| Final | `obj_groves` done | 0 s: **Torvald** + 3 Rimeshields + 2 Shardcasters + 1 Rime Colossus (NW) and **Aldra** + 3 Rimeshields + 1 Shardcaster + 1 Frost Mortar (NE, she returns even if her spire fell) · 30 s: 4 Rimelings + 2 Hoarlight Magebows (NW) | Torvald's group: the Heartglade; Aldra's: the grown grove with the least HP; at 45 s cutscene `e4m3_shoot`: **Torvald's group stops and holds** where it stands for the rest of the hold |
| Withdraw | `obj_hold` done | Every Ice unit, Torvald, Aldra | Walk to their camps; no fighting unless attacked |
Rules: `sec_spire` done = Aldra's camp sends no more counter-waves (they come from Torvald's camp instead, +20 s walk) and
Aldra skips her returns until the Final. The two wizards' respawn (Torvald 60 s at the Rime Keep: `Torvald has fallen,
the frost will bring him back`) and Aldra's flee rule as above.
**Torvald's Commander** (profile `mission_e4_03`: Ice normal knobs, `min_attack_pop` 99, `worker_target_home` 5, no
expansion, no new towers, up to 10 soldiers at `(-30, -30)`, **`defend_radius` 12 m** around its own buildings: it never
leaves the camp to save Mossgate's guard) gathers, trains and defends its camp only. Aldra's camp has no Commander.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cutscene `e4m3_arrival` (HOLD 0:15); L1-L4; `obj_groves` active; hint `Break the Rime Totems at a glade, then hold Ysolde at its centre to plant. Keep enemies out while it grows.` (12 s) |
| E2 | First grove planted | L5 |
| E3 | 0:40 | Hint (10 s) `Bramblesage: Snagroot pulls a shield-caster out of the frost. Pollen Haze silences archers while you break totems.` |
| E4 | First grove grown | L6; `sec_unbroken` active; hint `A green grove heals your soldiers and shoots thorns. The Ice will come to freeze it again.` (8 s) |
| E5 | R1 spawns (3:30) | L7 |
| E6 | A side-0 unit within 18 m of the Heartglade (first time) | Cutscene `e4m3_aldra` (PAUSE 0:10): L8-L9; G3 and Aldra fight |
| E7 | A grove re-rimed or destroyed (first time) | L10 |
| E8 | Citadel complete | L11 (and the tiers.md completion message) |
| E9 | The Heartglade becomes grown | L12-L13 |
| E10 | Aldra flees (first time) | L14 |
| E11 | Hush's last hunt spawns | L15 |
| E12 | Aldra's frost spawns | L16 |
| E13 | Glass Spire destroyed | L17; `sec_spire` done |
| E14 | Torvald's march spawns (16:00) | L18-L19 |
| E15 | `obj_groves` done | L20-L21; `obj_hold` active (1:30); the Final wave |
| E16 | Final + 45 s | Cutscene `e4m3_shoot` (HOLD 0:12): L22-L24; Torvald's group holds |
| E17 | `obj_hold` done | Withdraw; cutscene `e4m3_spring` (PAUSE 0:35): L25-L28; the Heartwood Seed goes to Ysolde's artifact slot 1 for the rest of this mission (the M2 rule); `Events.mission_ended(true)` 2 s after it; StoryFlow then plays `c_e4_frontier` |
| E18 | Ysolde dies | L29; defeat after 3 s |
| E19 | Heartwood destroyed | L30; defeat after 3 s |
| E20 | Maelis falls / is revived | Helper barks (`helper_maelis_fall` / `_revive`) |
Groves can be done in any order. The intended rhythm: Hollowfen at once (~2:30 grown), Stagwatch with the army (~5:00),
the Citadel 5:45-7:15, the Heartglade fight with Aldra (~7:30-10:00, the skill check), Fernhollow (~12:00-14:00),
Mossgate with Briar Rocs (~15:00-18:00), the five together ~18:00-20:00, hold 1:30.

## Dialogue (30 lines; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist): `narrator`, `ysolde`, `maelis`, `torvald`, `aldra`, `hush`,
`messenger` (shown as **Wren**). Colours: Ysolde `(0.55, 0.90, 0.35)`, Maelis `(0.60, 0.85, 0.50)`, Torvald `(0.55, 0.80,
1.00)`, Aldra `(0.62, 0.95, 0.88)`, Hush `(0.60, 0.50, 0.75)`, Wren `(0.80, 0.92, 0.60)`, Narrator `(0.9, 0.85, 0.7)`.
Aldra's `cast.json` entry says "unit barks only so far": these are her first story lines (same voice). Every line <= 96
characters.
| Line | Event | Speaker | Text (spoken) | Subtitle if different |
|---|---|---|---|---|
| L1 | E1 | narrator | The Sighing Wood, at the edge of winter. Burnt by Shadow, frozen by Ice, and not dead yet. | - |
| L2 | E1 | ysolde | Five glades still remember being green. Break the rime, plant, and keep them warm. | - |
| L3 | E1 | maelis | Torvald holds the west. His glass warden holds the east. They're both very tidy. | - |
| L4 | E1 | messenger | My lady, the hollow by the camp... it's frosted, but it's... it's still breathing. | My lady, the hollow by the camp is frosted, but it's still breathing. |
| L5 | E2 | ysolde | Grow. Slowly, if you must. Just grow. | - |
| L6 | E4 | narrator | Green, in the Sighing Wood. For the first time since the fire. | - |
| L7 | E5 | aldra | They're planting. Go and put the frost back. Gently. Nothing here should grow strong. | - |
| L8 | E6 (`e4m3_aldra`) | aldra | Ysolde. Torvald asked me to keep this wood quiet. I keep what I'm asked to keep. | - |
| L9 | E6 (`e4m3_aldra`) | ysolde | You froze a grave, Aldra. I've come to open it. | - |
| L10 | E7 | ysolde | They broke it. Then we plant it again. Roots don't count how often. | - |
| L11 | E8 | maelis | Tall enough for birds now. Big ones, with thorns. | - |
| L12 | E9 | ysolde | The Last Heartwood. You held on all winter, didn't you? | - |
| L13 | E9 | torvald | Aldra. Let her plant. We will see what the frost thinks of it. | - |
| L14 | E10 | aldra | Cracked. Not broken. I'll be back before your seedlings are. | - |
| L15 | E11 | hush | One more night, Ysolde. The Bishop pays for every one. | - |
| L16 | E12 | aldra | Enough green. This wood is ours by treaty, and by winter. | - |
| L17 | E13 | maelis | Her glass is sand now. She'll have to sulk somewhere warmer. | - |
| L18 | E14 | torvald | Ysolde. You were always the patient one. Why can you not wait for spring? | - |
| L19 | E14 | ysolde | Because you froze the spring, Torvald. Somebody has to go and get it. | - |
| L20 | E15 | narrator | Five glades, green at once. Deep under the ash, something old turns over. | - |
| L21 | E15 | ysolde | Hold them. All of them. Just a little longer. | - |
| L22 | E16 (`e4m3_shoot`) | torvald | Aldra. Look. A shoot, in the ash. After all of that. | - |
| L23 | E16 | aldra | It's a weed, Torvald. | - |
| L24 | E16 | torvald | We were all weeds once. Pull back. | - |
| L25 | E17 (`e4m3_spring`) | ysolde | You see, Maelis? It always comes back. | - |
| L26 | E17 | maelis | Mm. And it brought you a present. | - |
| L27 | E17 | ysolde | The wood can, now. Thank you, Vessa. (6 s) | - |
| L28 | E17 | narrator | Under the frost, very slowly, the Sighing Wood began to breathe again. | - |
| L29 | E18 | ysolde | The wood... will remember... | - |
| L30 | E19 | maelis | The new Heartwood's fallen. The wood has nothing left to grow from. | - |
Echoes: L27 closes `c_e2_ashes` ("Keep it until the wood can") and `c_e4_turnback` ("I think the wood can now. V."); L24
is the seed of Torvald's turn (Ep4's ending, Ep7's "No"), his answer to e4m1 L25; L18-L19 turn his Ep1 patience against
him (`ep1` C1 "No. For now."); L14 is Aldra's own fall bark (`t3-helpers.md` 10.4) and her e2m1 L10; L13 shows Torvald
already doubting the frost he ordered.

## Cinematic hooks
Camera axis: the Ysolde - Torvald line runs south-east -> north-west; cameras stay on its **south-west** side.
| id | Kind | When | Content | Lines | Skip end state |
|---|---|---|---|---|---|
| `e4m3_arrival` | ENGINE, **HOLD** 0:15 | E1 | 3 shots: CRANE down over the white canopy from the south-east, rime on every trunk, the five glades as blue-white circles; MS Ysolde at the new Heartwood's roots, opening her hand on the seed-pod token (closed, grey); WS the Hollowfen glade, one frosted totem, a faint green breath under the ice | L1 over shot 1 | Camera on Ysolde; `obj_groves` active; nothing spawned or moved |
| `e4m3_aldra` | ENGINE, **PAUSE** 0:10 | E6 | 2 shots: MS Aldra at the Last Heartwood, chisel-staff on the rime, three blue beams from the totems (the e2m1 `e2m1_frostwarden` framing, reversed); MS Ysolde, staff low, 3/4 | L8-L9 | G3 and Aldra active and fighting; camera back on Ysolde |
| `e4m3_shoot` | ENGINE, **HOLD** 0:12 | E16 | 2 shots: low ECU of one green shoot pushing out of black ash at the Heartglade's edge, frost melting off it; MS Torvald looking down at it, then up at Aldra, one hand raised (his Rimeshields ground their shields) | L22-L24 | Torvald's Final group set to `hold` at its current position until the Withdraw; Aldra's group unchanged |
| `e4m3_spring` | ENGINE, **PAUSE** 0:35 | E17 | 4 shots: WS the five glades from above, moss spreading from each, the rime retreating in rings; MS Ysolde and Maelis at the Last Heartwood (L25, L26); ECU Ysolde's hand: the grey seed-pod **opens**, a living green-gold seed inside, pulsing (`green_shoot` VFX); WS the Ice withdrawing through the trees, Torvald last, looking back (L27, L28) | L25-L28 | `heartwood_seed` owned and equipped in slot 1; `Events.mission_ended(true)` fired; rewards saved; StoryFlow to `c_e4_frontier` |
Fallbacks: no cine -> each hook's lines as dialogue + a 2 s pan to its subject; the token VFX missing = a plain close-up of
the hand. **Between missions**: `c_e4_frontier` "The Wall" (ENGINE stage 1:10; beats: night in the Ice camp, Torvald
alone with a lantern at the shoot; Aldra: "We could burn it again." Torvald: "No."; then Emberwatch: Ysolde and Vessa
over a map: Torvald is raising **the Wall of a Hundred Winters** on his frontier before the snow closes the passes: behind
it the Ice-Shadow alliance can feed Malrik's war all winter; break it before the first blizzard; Vessa: "I'll bring the
fire. You bring the patience." Ysolde: "I'll bring a tree.").

## The Heartwood Seed (new campaign artifact; the items row is for the items owner, campaign-outline C7)
| id | Name | Given by | Stats / effect |
|---|---|---|---|
| `heartwood_seed` | Heartwood Seed (Ysolde's token) | e4m3 victory (Ysolde's track) | `max_hp` +80, `hp_regen` +2, `spell_power` +10; **Spring Returns** (passive): once per **150 s**, when the wearer drops under **30 %** HP she heals **120 over 4 s** and **2 Saplings** (Call the Thicket rank-1 Saplings, 25 s, pop 0, 0 XP) sprout at her feet. `campaign_only`, never sold, never dropped (the Crown's drop rule does not apply) |
Look: artifact icon `HS`, green-gold border; while equipped a seed of light glows at the head of Ysolde's staff (0.2 scale
`green_shoot`, no light) and flares on Spring Returns. Ep8's Nature road equips the Master's Signet in slot 1 (outline 4.2)
and this seed in slot 2 by default.

## Win / lose
| Event | Result |
|---|---|
| `obj_hold` done | **Victory** (after `e4m3_spring`) |
| Ysolde dies | **Defeat** (instant loss) |
| Heartwood destroyed | **Defeat** |
| Every Grove Heart destroyed after `obj_groves` | Nothing by itself (the hold pauses below 4); the player can replant |
| Maelis fallen, all soldiers dead | Nothing |
| Torvald killed / his keep destroyed | Not a win: his 60 s respawn text; his camp's later waves spawn at the corner |

## Reward carried to e4m4
- **Heartwood Seed** owned; equipped in artifact slot 1 by default on the e4m4 choice screen (Ysolde has no other artifact
  yet: slot 2 stays empty).
- The 6 item slots at victory; essence 50 %, cap 1 500, **+300 first if `sec_spire`**, **+300 first if `sec_unbroken`**.
- `CampaignState.MISSION_REWARDS[&"e4m3"] = {"artifact": "heartwood_seed", "flags": {"e4m3_spire_shattered": "sec_spire",
  "e4m3_groves_unbroken": "sec_unbroken"}, "bonus_essence": {"sec_spire": 300, "sec_unbroken": 300}, "next": &"e4m4"}`.
- e4m4 hooks: `e4m3_spire_shattered` = Aldra starts e4m4 at **-15 % HP** (her glass never quite healed) and says L-variant;
  `e4m3_groves_unbroken` = 2 Grove-born Bramblehorns (veterancy 2) join the e4m4 start army.
- Level not carried.

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6, no Colossus / Shardguard / Mortar | as written | x 1.4 |
| Start crystals | 500 + 2 extra Thornlings | 400 | 300, no Bramblehorn |
| Growth time | 45 s | 60 s | 75 s |
| Re-rime time | 15 s | 10 s | 7 s |
| Hold | 1:00, >= 3 groves | 1:30, >= 4 | 2:00, >= 4 |
| Wizards / Aldra | Torvald L5, Aldra L5 | L6 | L7; Aldra returns after 60 s |
| Expected time | 18-22 min | 22-26 min | 25-30 min |
**Fight sizing** (normal; every guarded fight and wave <= 70 % of the army the player can have then; wizard worth
`170 + 30 x level`, Aldra / Maelis `200 + 40 x level`; Maelis L5 = 400 counted on the player's side).
| Fight | When | Enemy | Player army then | Ratio |
|---|---|---|---|---|
| G2 Stagwatch | ~4:00 | 520 (+ 800 HP of totems) | 1 480 + Ysolde L5 (320) + Maelis (400) | 24 % |
| R1 re-rime | 3:30 | 570 | ~1 700 + Ysolde + Maelis + a grown grove | 22 % |
| G3 Heartglade + Aldra L6 | ~7:30-10:00 | 930 + 440 = 1 370 (+ 1 200 HP of totems) | ~2 300 + Ysolde L6 + Maelis L6 (440) | 46 % (the skill check: kill the Seer and the Mortar first) |
| G4 Fernhollow | ~12:00 | 535 | ~2 600 | 18 % (but 47 m from Torvald's Frost Hall: the counter-wave comes fast) |
| Aldra's frost (+ Sentinel 330 for 30 s) | 12:00 | 1 250 (+ 330) | ~2 700 + 2 grown groves | 45-55 % |
| G5 Mossgate | ~15:00 | 815 | ~3 000 + 1-2 Briar Rocs | 23 % (+ the Rime Spire's edge) |
| Torvald's march | 16:00 | 1 420 | ~3 200 + groves | 37 % |
| Counter-wave #4 | ~17:30 | 1 160 | ~3 200 | 30 % |
| Final (0 s / +30 s) | 2 240 / 2 650 (Torvald L6 350, Aldra L6 440) | ~3 500 + Maelis L7 (480) + 5 Grove Hearts (each a spire) | 56 % / 67 %; Torvald's half (1 200) stops at 45 s |
- The meters are the pressure, not the fights: a growing grove pauses whenever one enemy stands in it, and a lone
  Rimeshield left in the ring for 10 s undoes a minute. The intended answers: leave 3-4 soldiers on each growing grove,
  Snagroot the intruder, Wild Bloom the guards; Briar Rocs patrol the far groves.
- `sec_unbroken` is for players who over-guard; on normal expect to lose and replant one grove.
- Watch in the first playtest: if the five-at-once condition drags past 22:00 because of re-rimes, raise the re-rime time
  to 12 s or drop the 4th counter-wave's Colossus.

## Done when (proposed ids; the lead adds them to `waves.md`)
- [ ] **E4M3.S1** (systems): `missions/mission_e4_03.tscn` + `MissionE403` build e2m1's map (seed 1303) in its winter
  variant with the changes in "Map" (Greenhold clearing 18, the player base, Emberwatch scripted shop, both Ice camps,
  Aldra's Glass Spire); start state via `apply_to_start` (Ysolde L5 + 4 points, cap 8; 400 / 150 + carried; 29 / 60) and
  the no-save fallback; `MissionGrove` x5 with its totems and the state table (plant 4 s with nothing within 10 m, grow
  60 s x the soldier factor, pause, re-rime 10 s, Grove Heart 900 HP + Sap Ward + thorn bolt, destroyed -> thawed,
  replant after 30 s); guards G2-G5; section "Tiers and the helper" incl. **`helper_start_called`**. `tests/test_e4m3_s1.gd`:
  a grove with no enemy grows in 60 s alone and in 30 s with 4 soldiers; a Rimeshield in the ring pauses it and re-rimes it
  after 10 s; a destroyed Grove Heart can be replanted 30 s later; Maelis stands at the keep at 0:00 and the V button reads
  Revive only when she falls.
- [ ] **E4M3.S2** (systems-high [H]): objectives and events E1-E20, the 30 lines, R1 / counter-waves / Hush's last hunt
  (flagged) / Aldra's frost / Torvald's march / Final / Withdraw, Aldra's flee-and-return and the `sec_spire` rule,
  `obj_hold` pause rule, win / lose and difficulty tables, `MISSION_REWARDS[&"e4m3"]` (artifact + flags);
  `CampaignState.MISSION_SCENES[&"e4m3"]`. Test `tests/test_e4m3_s2.gd`: a scripted run grows five groves and holds,
  `victory=true`, and the save holds `heartwood_seed`.
- [ ] **E4M3.G1** (gameplay): `aldra_story` (the `t3-helpers.md` 4.4 kit at Torvald's level on team ENEMY, Hold-home
  brain at an anchor the mission moves, flee at 25 % to an anchor, return after N s); `HelperRoster` knob
  `helper_start_called`; test: Aldra's Wake the Sentinel raises one Colossus for 30 s and she flees at 25 %.
- [ ] **E4M3.I1** (items): `heartwood_seed` ItemType (artifact, `campaign_only`) with the stats above and Spring Returns;
  test: under 30 % HP it heals 120 over 4 s, sprouts 2 Saplings, and not again for 150 s; the `items.md` campaign table
  gains the row.
- [ ] **E4M3.A1** (ai): profile `mission_e4_03` (Ice normal knobs, `min_attack_pop` 99, workers 5, no expansion, max 10
  soldiers, **`defend_radius` 12**); `AIStoryCaster` casts for Torvald (kingdom-ice 4.3) in the scripted waves; the
  Commander ignores `"scripted"` units and Aldra's camp. Test: Torvald's army does not leave its camp when Mossgate's guard
  is attacked 13 m from the Rime Spire.
- [ ] **E4M3.U1** (ui): objectives panel with the five grove icons (frozen / thawed / growing % / grown) and the hold
  countdown with `(paused)`; minimap grove icons in the same states; plant ring; Grove Heart HP bars; colours for `aldra`,
  `torvald`, `maelis`, `messenger`, `hush`; artifact icon `HS`.
- [ ] **E4M3.V1** (tech-artist): the winter variant of the burnt wood (more snow, rime on the generator's charred trees),
  `MissionGrove` states (frozen decal, crack, sapling growth 0-100 %, Grove Heart: a 3 m young oak with a green seed-heart,
  moss paint r 12), Aldra's Glass Spire (7 m rune-glass tower, beams, shatter), the opening seed-pod (grey pod -> living
  seed), `heartwood_seed` staff glow; 0 lights; `PERF OK` with the Final on the field.
- [ ] **E4M3.C1** (four-wizards-high): `e4m3_arrival`, `e4m3_aldra`, `e4m3_shoot`, `e4m3_spring` as cine timelines on the
  mission scene, `cine check` 0 FAIL; fallbacks and skip end states as listed.
- [ ] **E4M3.O1** (Voice Forge agent): the 30 lines (`data/voice/lines/e4m3.json`); Aldra's first story lines in her
  `cast.json` voice; every WAV fits its slot.
- [ ] **E4M3.D1** (game-designer): read the lines in game once; write `c_e4_frontier` (1:10) from the beats above.
- [ ] **Lead**: a scripted headless run on normal ends `victory=true` in 22-26 game-minutes in 3 / 3 runs; the G3 fight
  leaves Ysolde alive in 5 / 5 runs with the scripted army.

Dependencies: e2m1's map variant and props (E2M1.S1: `MissionHeartwood`, `RimeTotem`, the burnt-wood generator), Ysolde's
track (E4M1.S3, E4M2.S2), the helper roster with `helper_start_called` (TH + E4M3.G1), Briar Roc (TH), `MissionBase`.

## Built (2026-10-08)
`missions/mission_e4_03.tscn` + `scripts/campaign/mission_e4_03.gd` (`MissionE4_03`, its header lists the build
deviations), tests `tests/test_e4m3.gd`, `tests/test_e4m3_sim.gd` (paced) and `tests/test_e4m3_rush_sim.gd` (rush; both
on the slow list). **Balance pass (JS 2026-10-08)**: at the spec's numbers a player who rushed every grove with the start
army won in ~7:00 (the guards fell in seconds). Changes:
- Grove guards are rime-bound: x2.15 HP, x1.1 damage, +5 armour, and one unit more (Stagwatch + Rime Seer, the
  Heartglade / Fernhollow + Shardguard, Mossgate + Shardguard and a Rime Colossus; easy drops the Colossus / Shardguard).
- Rime Totems 3 000 HP (spec 400) with the Verdant regrowth (2 % / s, 10 s after the last hit).
- A grown-out grove (meter full) is **rooting**: it counts as grown only after being held 30 s by the capture rules
  (our soldiers or Ysolde alone = progress, both sides = frozen, nobody = -10 % / s, the enemy alone re-rimes it as in a
  growing grove). Hint `HINT_ROOTING` once; the objective detail shows `rooting N %`.
- Home nodes 4 000 / 4 000 / 3 500 (spec 2 500 each): with the sturdier guards a player who keeps losing armies ran dry
  at ~20:00 with a grove still frozen (a soft-lock).
- Scripted runs (normal, seeds 1-3): paced sim (the spec's push times) victory at 21:52 / 24:16 / 23:01 mission time
  (23:04 / 25:28 / 24:13 with the cutscenes); rush sim (no clock: it attacks a guarded grove with 40+ free soldiers, +8
  after a repulse) victory at 21:45 / 31:53 / 27:10 (before: ~7:00). Rushing is now no faster than the paced play.

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Briar Roc (first trained e4m2).
- **Why here:** Ice totems, spires and Rimeshield clumps over 5 far glades; Seed Storm roots from the air, out of the totems' reach.
- **Moment:** Mossgate (15-18): "Rocs fly over the ice. Root the Rimeshields from above.".
- **Intro card:** `Briar Roc. A thorn bird: walls don't stop it, and its seed storm roots the crowd below.`

# Campaign mission e4m2: "The Green Road" (Ysolde + Maelis; Episode 4)

Written 2026-10-02 (`campaign-outline.md` 3.4). Episode 4 "What Grows Back", mission 2 of 4 (id `e4m2`, outline D6). The
morning after Lark Hill: the people Ysolde saved under the golden tree walk west through **Evenmead's western woods** to
the Fire border, where Vessa's fort Cinderwatch has opened its gate. Shadow's hunters and an Ice watch lie along the road.
An **escort** mission with a base: the player keeps Larkrest camp running, opens the **Citadel**, calls **Maelis** for
the first time and trains the first **Briar Rocs**. Target **18-22 min** on normal. Uses `mission-01.md` /
`mission-e2-01.md` rules (MissionBase, scripted groups, 70 % rule, difficulty multipliers, the e2m1 survivor walker and
the first-call helper price), `tiers.md` 6, `t3-helpers.md` 3-4.5 and 7.2 (Maelis, Briar Roc), `caster-units.md` 5.3,
`kingdom-nature.md`, `items.md` campaign rules. New scene `missions/mission_e4_02.tscn` + `scripts/campaign/mission_e4_02.gd`
(`MissionE402 extends MissionBase`, mission id `e4m2`). Metres, seconds, `m:ss` since the navmesh was ready; positions
`(x, z)`, `+z` = south. Status: **design only**. Recommended option taken everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map | New World Forge map **`data/maps/green_road.map`**, **160 x 100**, `symmetry=none`, seed **42**, Old Wood biome (`map-fill.md` 3.1) in early autumn (leaves turning amber), one trodden road east -> west. Every position below is binding for the map task E4M2.M1 | An escort needs a long road; the 120 x 120 generator maps are square fights. World Forge map mode already builds `evenmead.map` |
| D2 | Where the player starts | **Larkrest**, a Nature camp at the wood's east edge (the west foot of Evenmead), the Heartwood **already a Stronghold** (Lark Hill earned it), Grove Hall and 2 Seed Hollows pre-built | campaign-outline D7: the Citadel opens in mission 2, so the Stronghold must be in hand at 0:00 (e2m1 D2 rule) |
| D3 | How villagers move | **Convoys** of `meadow_folk` (e4m1 D8) walking the road by themselves. **4 convoys**; each leaves the Lantern Green on a timer, or earlier when Ysolde **rings the Lantern** (the e4m1 bell rule with a 3 s channel). Walkers **cower** (stop) while an enemy unit is within 10 m of them and go on 2 s after it is gone | The player escorts, never herds: no orders on villagers (`commandable` false, e2m1 D5). The cower rule makes "clear the road first" the skill |
| D4 | How many | `total = 40 - (30 - e4m1_folk_saved)`, floor 30 (no save / tests: **40**). Convoy size `ceil(total / 4)`, the last takes the rest. **Needed: ceil(75 % of total)** (40 -> 30) | e4m1's result carries into this road (people lost on Lark Hill are not on it); the 75 % rule keeps the e4m1 "lose at most a quarter" feel |
| D5 | Maelis | **Callable helper** from the Citadel (`t3-helpers.md` 2-4.5, kit at Ysolde's level). At 0:00 she is a story NPC at the Lantern (3 lines), then walks ahead to scout the brook and leaves the map; the call brings her back (her arrival set-piece: a spirit stag through the roots at the Heartwood door). **First call price 250 crystals + 100 essence, 30 s** (this mission only; revive at the skirmish price) | Outline C3 / D7: Maelis becomes callable in e4m2; the e2m1 D3 / D4 pattern for Old Vey, unchanged |
| D6 | The enemy | **Shadow hunters** (Malrik's men under **Mother Hush**, no Malrik: he is at his crypt, e3m3) run by a Commander with **no wizard** (gather, train, defend); an **Ice watch** at the brook (Torvald's outpost, scripted, no workers, no Torvald) | Malrik and Torvald are busy in Ep3's missions; Hush on the hunt is the face of the enemy; no wizard bot needed |
| D7 | The wagons | No carts: the supply wagons burned in the night (Hush's sabotage, e3m2 "Another Night", and `c_e4_refuge`). The people carry bundles (speed **3.6 m/s**) | Mirror of e3m2; explains the walk |
| D8 | Cinderwatch | Vessa's border fort, **team PLAYER, scripted** (not selectable, invulnerable, no queue), a base shop (`is_shop()` true: Fire's shop list + the exchange) and the convoys' goal. **Captain Ashby** (story NPC, `ashby`) and 6 Flame Guards (team PLAYER, not commandable, hold r 6 at the gate) | A friendly face at the end of the road; no Vessa bot needed; Ashby has a voice already |
| D9 | Briar Roc | The Nature tier-3 unit (`t3-helpers.md` 7.2: 700 HP, flyer, Seed Storm roots from the air) at the **keep, slot C**, from the Citadel (`t3_enabled = true`, e2m1's opt-in). Its sight over the wood is what this map rewards | Outline e4m2 row: "Briar Roc T3" |

## Story setup (briefing text, 3 short paragraphs; shown after `c_e4_refuge`)
1. Lark Hill held. The ford did not. By morning the people under the golden tree have nothing left in the valley but
   their names, and the supply wagons burned in the night.
2. West of Evenmead the old woods run all the way to the Fire border. Vessa's fort, Cinderwatch, has opened its gate.
   Between here and there is one road, and Malrik's hunters know it as well as Ysolde does.
3. Walk them home, a lantern at a time. Somewhere in the trees, Mother Hush is counting.
Briefing objectives: `obj_convoys`, the rule `Ysolde must survive`, the line `The villagers stop when the enemy is near
them. Clear the road ahead, and they walk on.`

## Map: "The Green Road" (160 x 100, `data/maps/green_road.map`, seed 42, not mirrored)
Playable bounds x -77..77, z -47..47 (camera bounds 3 m inside). Old Wood everywhere (broadleaf and oak, autumn tint,
fern undergrowth) except the road and the listed clearings; the wood is passable for units (normal Old Wood density,
`map-fill.md` 3.1), the road is faster to read, not faster to walk. Clearings: no tree or rock inside the radius.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| **Heartwood** "Larkrest" (player, tier 2 Stronghold, 2 700 HP) | `(62, -26)` | 16 | `PLAYER_START` = Ysolde at `(60, -12)` |
| Grove Hall (pre-built) / Seed Hollows (pre-built) | `(48, -32)` / `(70, -38)`, `(54, -42)` | 4 / 3 | 15.2 m / 14.4 and 17.9 m from the keep |
| Node `e4m2_rest_a` / `e4m2_rest_b` | `(71, -20)` / `(60, -36)` | - | **1 500** each (10.8 m / 10.2 m from the keep) |
| Node `e4m2_glen` (expansion) | `(32, -22)` | 7 | **2 000**; hall spot `(38, -16)`; 30 m west of the keep, 26 m from the Hollow Oak |
| **Lantern Green** (the people wait here) | centre `(64, 4)` | 10 | 4 groups of walkers in rings of 2 m; **the Lantern** post at `(60, 2)` = road start |
| **The road** | polyline `(60, 2) (50, 4) (38, 10) (22, 6) (8, -2) (-8, -6) (-24, 0) (-40, 8) (-56, 6) (-66, 3)` | 4 (along it) | Width 5, trodden; **134 m** long. Waypoint `wp_0`..`wp_9` = the vertices |
| **Cinderwatch** (Fire border fort, D8) | keep `(-72, -10)`; gate zone centre `(-66, 3)` | 12 / gate r **8** | Walkers inside the gate zone count as arrived and despawn after 2 s (they go through the gate) |
| Ashby + 6 Flame Guards | hold spot `(-60, 12)` | - | Team PLAYER, not commandable, leash 6 m |
| **The Hollow Oak** (landmark, obstacle r 2) | `(36, 18)` | 8 | A huge split oak, 8 m south of the road's bend `(38, 10)` |
| **Frozen Brook** (decor stream, iced) | polyline `(-16, -47) (-10, -28) (-6, -6) (-2, 16) (-6, 47)` | - | Not `RiverSystem` water: a frozen stream mesh; impassable 1.5 m banks except the **crossing** |
| Brook crossing `brook_ice` | circle `(-6, -5)`, r **6** | 8 | `terrain:ice` `move_speed_pct -0.30` (modifier on every unit inside) while frozen; thawed = stepping stones, no slow |
| Rime Totems BT1 / BT2 | `(-12, -14)` / `(2, -14)` | - | 400 HP, armor 10, team ENEMY, `counts_for_defeat` false (the e2m1 `RimeTotem`); 10.8 / 12.0 m from the crossing |
| **Crowstone Clearing** (old standing stone, obstacle r 1.5) | `(-40, 16)` | 8 | 8 m south of `wp_7` `(-40, 8)` |
| **Gallow Hollow** (Shadow hunters' camp) | Dusk Keep `(6, -36)`, Gloom Hall `(-8, -40)`, Night Spire `(6, -22)`, Hovel `(18, -42)` | 16 / 4 / 3 / 3 | Nodes `(-2, -44)` / `(15, -30)` 1 500 each; rally `(-2, -22)`. Night Spire (range 10) is 20 m from the road: never covers it |
| **Rimebrook** (Ice watch, scripted) | Frost Hall `(-40, -34)`, Rime Spire `(-28, -20)`, Snow Lodge `(-50, -40)` | 10 / 3 / 3 | Group `"scripted"`, no workers; rally `(-30, -26)`; Rime Spire 20 m from the road |
| Lost Caches | `(20, 30)`, `(-24, 30)` | 3 | `items.md` loot, appear at 2:00, reopen 180 s |
| Maelis's exit | `(20, 46)` (south edge, the deep wood) | - | E2 |
| Wave spawns | Shadow: Gloom Hall spawn point (Dusk Keep's if gone; map edge `(0, -47)` if both gone) · Ice: Frost Hall spawn point (edge `(-40, -47)` if gone) | - | - |
Distances (navmesh): Heartwood -> Lantern 28 m; Lantern -> Cinderwatch gate 134 m (37 s at 3.6 m/s with no stop); Gloom
Hall -> road at `wp_5` 34 m; Gloom Hall -> Hollow Oak 62 m; Frost Hall -> crossing 40 m; Frost Hall -> Crowstone 45 m;
Heartwood -> crossing 80 m. Generator check (E4M2.M1): a navmesh path from `PLAYER_START` to every waypoint, both enemy
camps and both caches; no tree within 4 m of the road; the brook banks block everything except `brook_ice`.

**Look** (E4M2.V1): early autumn, morning sun low from the east `(1.0, 0.92, 0.80)` energy 1.1; broadleaf in green-amber
mixes, fallen leaves on the road `(0.55, 0.40, 0.22)`; the brook a white-blue ribbon of ice with frost feathers 3 m around
it (Torvald's work, the only cold thing on the map); smoke from Gallow Hollow's fires to the north. The Lantern: a 3 m
post with a green glass lantern (emission, 0 lights) that flares when rung.

## Start state (Ysolde's track, campaign-outline D8)
| Item | Value |
|---|---|
| Ysolde | **Level 4 with 3 unspent points** (Thornburst r1 known), **cap 7** (levels are never carried) |
| Items / artifacts | From the save: the 6 slots; no artifact yet |
| Essence | **150** + carried (50 %, cap 1 500, from e4m1); +1 / s |
| Crystals | **400** (easy 500, hard 300) |
| Buildings | Heartwood (tier 2 Stronghold), Grove Hall, 2 Seed Hollows (all complete) |
| Units | 6 Spriglings gathering (3 / 3); 6 Thornlings, 4 Burr Slingers, 2 Bloomtenders, 2 Vinelashers, 1 Greenheart Oathkeeper, 1 Bramblesage (full mana) at `(58, -8)` (**1 350** crystals of army) |
| Story units | **Maelis** (story NPC, invulnerable, not selectable) at the Lantern until E2; **Wren** (`wren`) at the Lantern Green, not following Ysolde this time: she rings the convoys off and stays with the people (never leaves the green) |
| Population | 6 + 18 = **24 / 60** (Heartwood 20 + 2 Seed Hollows x 20; max 4 Seed Hollows = cap 100) |
| Villagers | `total` (D4) `meadow_folk` at the Lantern Green, in 4 groups |
| No save (menu debug, tests) | Empty slots; essence 150 + **500**; `total` 40 |
| Shadow hunters | Gallow Hollow: Dusk Keep (tier 1, 2 500 HP), Gloom Hall, Night Spire, Hovel; 5 Gloom Thralls; 4 Shades + 2 Nightbolts at the rally; **Mother Hush** (`hush_story`, team ENEMY, **level 4**) dormant with ambush A3 |
| Ice watch | Rimebrook: Frost Hall, Rime Spire, Snow Lodge (`"scripted"`); 3 Rimelings + 2 Shardcasters at the crossing (A2) |
| Fog | On; the road, the Lantern Green, the Hollow Oak, the crossing, Crowstone and Cinderwatch explored for the player at 0:00 |
| Champions, trade, camps, beasts, river, points | Off |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Seed Hollow (max 4), Grove Hall, Bramble Spire | Elder Circle (e4m4), Stables, Bazaar |
| Units | Sprigling; Grove Hall: Z Thornling, X Burr Slinger, C Bloomtender, V Bramblehorn, N Thistle Darter, M Vinelasher, `,` Greenheart Oathkeeper; keep: B Bramblesage; **from the Citadel: C Briar Roc (keep)** | Wildwood Archer (Hall B, skirmish only), Elder Treant (e4m4) |
| Keep | **Citadel** (X, 300 crystals, 90 s, from **5:45**) | - |
| Helper | **Maelis** (keep, V) once the Citadel stands: 250 crystals + 100 essence, 30 s, pop 4 (D5) | Other helpers |
| Spells | Thornburst, Wild Bloom, Call the Thicket; cap L7 | - |
| Items | Base shop (Heartwood, Grove Halls) and **Cinderwatch** (Fire's base list + the exchange); the 2 caches | Artifacts (e4m3) |

## Tiers and the helper (`tiers.md` 6, `t3-helpers.md` 3)
| Item | Value |
|---|---|
| Code | `MissionE402._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = true`, `helpers_enabled = true`; `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(2)` on the Heartwood (2 700 HP, attack 16, no announcement) |
| Heartwood card | Z Sprigling · X **Citadel** (gold pulse when it can start) · C **Briar Roc** (greyed `Requires Citadel`) · V **Call Maelis** (greyed `Needs a Citadel`), then `Revive Maelis` when fallen · B Bramblesage · Set Rally r3c1 |
| Citadel hint | Once, when it can start: message 12 s `Your Stronghold can become a Citadel: select the Heartwood and press X (300 crystals, 90 s). It opens the Briar Roc (C) and lets you call Maelis (V).` |
| Call hint | Citadel complete: the tiers.md completion message, then L9 and the hint `Call Maelis: select the Heartwood and press V. She fights on her own; her card sets where (Escort / Vanguard / Hold home).` (10 s) |
| Maelis | `helper_maelis` at Ysolde's level (L4 680 HP x1.12 abilities; Wild Stampede from L5), stance Escort, F4 = centre on her. Fallen = never a defeat; revive 120 + 20 x level essence, 25 + 5 x level s at the Heartwood door. Bond: Thornburst-rooted enemies take +20 % from her and her wolves |
| Briar Roc here | 380 crystals, pop 4, 55 s, max 3 alive this mission. **Seed Storm** (r 3, 30 + root 1.0 s) is the answer to hunters in the trees; its flyer sight (13) over the canopy shows a dormant ambush only when it is within **6 m** of it (veiled units keep their 5 m rule; A1 / A3 are veiled until woken) |
| Enemy | Gallow Hollow never upgrades (`bots_upgrade = false`); scripted waves carry their own unit lists |
Timing: Citadel 5:45 -> 7:15 at the earliest; Maelis ~7:45 (30 s); first Briar Roc ~8:10, before convoy 3 (12:00).

### The Bramblesage here (`caster-units.md` 5.3)
**Snagroot** pulls a hunter out of the trees onto the road (Shades in the fern line, the Hexweaver behind A3) and
breaks the Gloom Deacon's channel in H4. **Pollen Haze** is for the brook: the Shardcasters on the far bank and the
Nightbolts of H2 / H4. Hint at E3.

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_convoys` | Primary | `Walk the people to Cinderwatch (0 / 40 · at least 30)` (numbers from D4) | The last convoy has resolved (every walker arrived or lost) and **arrived >= needed**; **failed** the moment `lost > total - needed` (40: the 11th) |
| `obj_ysolde` | Primary, always shown | `Ysolde must survive` | Fails = defeat |
| `sec_maelis` | Secondary (appears at E2) | `Raise a Citadel and call Maelis` | Maelis arrives (E9) |
| `sec_brook` | Secondary (appears at E4) | `Thaw the Frozen Brook (0 / 2)` | Both Rime Totems destroyed |
| `sec_hollow` | Secondary | `Burn the hunters' Gloom Hall` | The Gloom Hall at `(-8, -40)` is destroyed (the bot never rebuilds it) |
States through `Events.objective_changed(id, state)`. The panel line under `obj_convoys`: `Convoy 2 on the road · next at
7:30 (ring the Lantern to send it now)`.

**Convoys** (systems, the e2m1 survivor walker extended with a path):
| Rule | Value |
|---|---|
| Departure | Auto at **3:00, 7:30, 12:00, 16:30** (normal); or when Ysolde **rings the Lantern** (within 3 m of `(60, 2)` for 3 s, progress ring; leaving resets). Ringing is refused (`The road isn't clear of the last convoy yet`) until the previous convoy has resolved **and** 3:00 have passed since it left. A ring moves every later auto time earlier by the time saved |
| Walk | `wp_0` -> `wp_9` at **3.6 m/s**, single file 1.5 m apart, the group leader carries a green lantern (minimap: a moving green diamond per convoy) |
| Cower | A walker stops while any enemy unit (not a building) is within **10 m** of it; it walks on 2 s after none is. Cowering walkers crouch (model `set_cower(true)`) |
| Targets | Walkers are targetable (45 HP, armor 0); enemy waves aim at the nearest walker. Inside the gate zone they are safe (invulnerable, then gone) |
| Help | Own Bloomtenders, Wild Bloom and Sap auras heal walkers (they are PLAYER units) |

## Guards, waves and scripted groups (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units: team ENEMY, group `"scripted"`, never controlled by the Commander. Guards hold their spot with auto-aggro
and a 2x leash; **dormant** groups are veiled and inert (`_set_dormant`) until their trigger, then fight freely; waves
attack-move as listed, refreshed every 3 s.
| Group | Where | Units | Value | Trigger |
|---|---|---|---|---|
| A1 Hollow Oak | `(40, 20)`, ring r 3, dormant | 4 Shades + 2 Grave Hounds | 460 | A walker or Ysolde within **16 m** of `(40, 20)` |
| A2 Brook watch | `(-6, -16)`, ring r 4, awake, leash 2x | 3 Rimelings + 2 Shardcasters (+ the 2 totems) | 385 | - |
| A3 Crowstone | `(-38, 20)`, ring r 3, dormant | **Hush** (L4) + 3 Shades + 1 Hexweaver | 725 | A walker or Ysolde within **16 m** of `(-38, 20)`; cutscene `e4m2_hush` |

| Wave | Trigger | Units (spawn) | Order |
|---|---|---|---|
| H1 hunting party | 4:00 | 3 Shades + 2 Grave Hounds (Gloom Hall) | The nearest walker, else the Lantern Green |
| Brook relief | Every **180 s** from 5:00 while the Frost Hall stands | 3 Rimelings + 1 Shardcaster (Frost Hall) | To the crossing `(-6, -10)`, then hold there (join A2) |
| B1 Ice probe | 6:00 | 4 Rimeshields + 2 Shardcasters (Frost Hall) | Attack-move to the Grove Hall, then the Heartwood (the base needs a guard while the army walks) |
| H2 hunting party | 9:00 | 4 Shades + 2 Nightbolts + 1 Hexweaver (Gloom Hall) | The nearest walker, else Ysolde |
| H3 Hush's hunt | 13:00 | **Hush** (L5) + 4 Shades + 2 Grave Hounds + 1 Hollow Oathsworn (Gloom Hall) | The nearest walker (convoy 3), else Ysolde; Hush flees at 25 % to the Dusk Keep and returns after 90 s with the next wave |
| H4 the last hunt | The 4th convoy departs (or 16:30) | Shadow: 5 Shades + 3 Nightbolts + 1 Shadow Knight + 1 Gloom Deacon · Ice: 3 Rimeshields + 2 Shardcasters + 1 Frost Mortar | The 4th convoy (Shadow from the north-east at `wp_4`, Ice from the north-west at `wp_6`) |
| Withdraw | `obj_convoys` done | Every scripted unit, Hush | Back to their camps (no fighting unless attacked) |
Rules: `sec_hollow` done = every later **Shadow** wave loses 40 % of its units (rounded down; Hush stays) and H4 has no
Knight. Frost Hall destroyed = the brook relief stops and H4's Ice part loses 40 % and its Mortar (the e2m1 rule).
Hush cannot die for good: at 25 % HP she vanishes in smoke (`hush_smoke` VFX) and is back 90 s later (L16 once).
**The hunters' Commander** (profile `mission_e4_02`: Shadow normal knobs, `min_attack_pop` 99, `worker_target_home` 5,
no expansion, no towers beyond the Night Spire, up to 10 soldiers at `(-2, -22)`, **no wizard**: every wizard rule is
skipped when the team has none) gathers, trains and defends Gallow Hollow only. The Ice watch has no Commander.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cutscene `e4m2_lantern` (HOLD 0:15); L1-L4; `obj_convoys` active; hint `The people walk the road on their own and stop when the enemy is near. Clear the road ahead of them. Ring the Lantern to send a convoy early.` (12 s) |
| E2 | 0:20 (after L4) | L5-L6; Maelis walks west along the road and leaves at `(20, 46)` (she is untargetable while she goes); `sec_maelis` and `sec_hollow` active |
| E3 | 0:45 | Hint (10 s) `Bramblesage: Snagroot pulls a hunter out of the trees. Pollen Haze silences archers across the brook.` |
| E4 | The crossing first seen (explored) | L7; `sec_brook` active |
| E5 | A convoy departs | L8 for convoy 1; the Lantern flares; the next-convoy line updates |
| E6 | A1 wakes | L10 |
| E7 | A3 wakes | Cutscene `e4m2_hush` (PAUSE 0:08): L11-L12 |
| E8 | Citadel complete | L13; the call hint |
| E9 | Maelis arrives (helper set-piece at the Heartwood door) | Her arrival bark (`t3-helpers.md` 10.4), then L14; `sec_maelis` done |
| E10 | First convoy arrives at Cinderwatch | L15 (Ashby), L17 |
| E11 | First walker lost | L18 (once) |
| E12 | Both totems destroyed | The brook thaws (ice cracks over 2 s, stepping stones appear, slow removed); L19; `sec_brook` done |
| E13 | Gloom Hall destroyed | L20; `sec_hollow` done |
| E14 | H3 spawns (13:00) | L21-L22 |
| E15 | Hush flees the first time | L16 |
| E16 | Maelis's first Wild Stampede | L23 (once) |
| E17 | The 4th convoy departs | L24; H4 |
| E18 | H4 spawns | L25 |
| E19 | `obj_convoys` done | Withdraw; cutscene `e4m2_border` (PAUSE 0:30): L26-L29; `Events.mission_ended(true)` 2 s after it; StoryFlow then plays `c_e4_turnback` |
| E20 | Ysolde dies | L30; defeat after 3 s |
| E21 | `obj_convoys` failed | L31; defeat after 3 s |
| E22 | Heartwood destroyed | L32; defeat after 3 s |
The intended rhythm: the army goes ahead of convoy 1 to the Hollow Oak (A1) and the brook (A2), a guard of 4-6 stays at
Larkrest for B1, the Citadel at ~6:00-7:15 and Maelis before convoy 2 reaches Crowstone (A3, Hush), the Briar Rocs and
Maelis carry convoys 3-4 through H3 / H4. Gallow Hollow's Gloom Hall is a mid-mission strike (Rocs, Saplings, Maelis)
for players who want the last hunts smaller.

## Dialogue (31 lines, L1-L32 without L9; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist): `narrator`, `ysolde`, `maelis`, `messenger` (shown as **Wren**),
`hush`, `ashby` (shown as **Captain Ashby**). Colours: Ysolde `(0.55, 0.90, 0.35)`, Maelis `(0.60, 0.85, 0.50)`, Wren
`(0.80, 0.92, 0.60)`, Hush `(0.60, 0.50, 0.75)`, Captain Ashby `(0.95, 0.60, 0.35)`, Narrator `(0.9, 0.85, 0.7)`. Every
line <= 96 characters.
| Line | Event | Speaker | Text (spoken) | Subtitle if different |
|---|---|---|---|---|
| L1 | E1 | narrator | The morning after Lark Hill. The wagons burned in the night. The people will have to walk. | - |
| L2 | E1 | ysolde | One road, the Fire border at the end of it, and everyone we kept alive. We walk them there. | - |
| L3 | E1 | maelis | The western woods are old and full of ears. Some of those ears are Malrik's. | - |
| L4 | E1 | messenger | The first ones are... they're ready, my lady. Ring the lantern and... they'll go. | The first ones are ready, my lady. Ring the lantern and they'll go. |
| L5 | E2 | maelis | I'll run ahead and smell the road. Call me when your tree grows tall enough to shout. | - |
| L6 | E2 | ysolde | Don't fight them all on your own. Leave me a few. | - |
| L7 | E4 | ysolde | Torvald froze the brook. The old folk will slip, and his archers know it. | - |
| L8 | E5 (first) | ysolde | Stay on the road. If anything moves in the trees, stop, and let the thorns go first. | - |
| L10 | E6 | ysolde | Knives in the oak! Down, everyone down! Thornlings, into the ferns! | - |
| L11 | E7 (`e4m2_hush`) | hush | Little lambs on a little road. The Bishop sends his regards. | - |
| L12 | E7 (`e4m2_hush`) | ysolde | You burned their wagons. You don't get their children. | - |
| L13 | E8 | ysolde | Maelis! The Heartwood stands tall enough. Come home. | - |
| L14 | E9 | maelis | I went to see the brook. It is cold, it is guarded, and it is very rude. | - |
| L15 | E10 | ashby | Nature folk at the gate! Open up, lads. Blankets, bread, and no questions. | - |
| L16 | E15 | hush | Another night, then. There is always another night. | - |
| L17 | E10 | ysolde | They're through. Ring it again, Wren. | - |
| L18 | E11 | ysolde | No... Keep moving. We grieve at the border. Not here. | - |
| L19 | E12 | maelis | Listen. The brook's talking again. It says thank you, roughly. | - |
| L20 | E13 | maelis | Their nest is ash. Malrik will need new hunters, and new excuses. | - |
| L21 | E14 | hush | The knife never misses, Ysolde. It only waits for the right neck. | - |
| L22 | E14 | ysolde | Then it can wait forever. Maelis, stay with the people. | - |
| L23 | E16 | maelis | Make way for the old herd! | - |
| L24 | E17 | narrator | The last of them leave Larkrest. Behind them, the green road goes quiet. | - |
| L25 | E18 | maelis | Everything they have left is coming. Good. It means we're nearly there. | - |
| L26 | E19 (`e4m2_border`) | ashby | That's the lot, my lady. The border's yours whenever you want it. The queen said so. | - |
| L27 | E19 | ysolde | Thank her for me. And tell her I'm not staying. | - |
| L28 | E19 | maelis | The Sighing Wood, then? Burnt, frozen, and still ours. | - |
| L29 | E19 | ysolde | A seed doesn't wait for the war to end, Maelis. Neither do I. | - |
| L30 | E20 | ysolde | Keep... walking... | - |
| L31 | E21 | messenger | We... we lost too many on the road. My lady, we can't... we can't go on. | We lost too many on the road. My lady, we can't go on. |
| L32 | E22 | maelis | Larkrest is burning. There's nothing left to walk away from. | - |
(L9 is not used.) Maelis's own barks (arrival `The forest has opinions. Today they're about you.`, Pack, Stampede, low HP,
fall, revive) are the helper hooks of `t3-helpers.md` 10.4; L23 is the Stampede bark played once as a dialogue line.
Echoes: L16 is Hush's "another night" (e3m1 L19, e3m2's title); L29 is the seed that does not wait (`ep4_opening` L3:
"My mother buried seed in the snow") and turns the episode back east toward the Sighing Wood (e4m3); L26 pays off
`c_e4_refuge` (Vessa: "leave the gate open").

## Cinematic hooks
| id | Kind | When | Content | Lines | Skip end state |
|---|---|---|---|---|---|
| `e4m2_lantern` | ENGINE, **HOLD** 0:15 | E1 | 3 shots: CRANE down over the amber canopy from the east, smoke rising far to the north (Gallow Hollow); MS Wren on her Grove Stag lighting the green lantern at the road's head; WS the people with bundles in the Lantern Green, Maelis leaning on her staff at the edge of the road | L1 over shot 1 | Camera on Ysolde; `obj_convoys` active; all walkers in their groups; Maelis at the Lantern (she leaves at E2 as normal) |
| `e4m2_hush` | ENGINE, **PAUSE** 0:08 | E7 | 2 shots: low angle on the road at Crowstone, the standing stone's shadow stretches and **Hush rises out of it**, the mouthless mask first; MS Ysolde turning, staff up | L11-L12 | A3 awake and attacking; the convoy at Crowstone cowering; camera on Ysolde |
| Maelis's arrival | In-game set-piece (`t3-helpers.md` 10.2) | E9 | Roots part at the Heartwood door, a spirit stag runs through and becomes her; banner; no camera move | arrival bark, L14 | - (not skippable, 3.5 s, the game runs) |
| `e4m2_border` | ENGINE, **PAUSE** 0:30 | E19 | 4 shots: WS Cinderwatch's gate open, the last walkers passing under red banners, Ashby counting them in; MS Ashby and Ysolde, 3/4 (L26, L27); CU Wren handing a lantern to a Fire soldier; WS Ysolde and Maelis turning east down the empty road, autumn leaves falling (L28, L29) | L26-L29 | `Events.mission_ended(true)` fired; rewards saved; StoryFlow continues to `c_e4_turnback` |
Fallbacks: no cine / set -> `e4m2_lantern` = camera on the Lantern + L1; `e4m2_hush` = Hush spawned with a smoke puff + L11-L12
as dialogue; `e4m2_border` = L26-L29 as dialogue with a 2 s pan to the gate. **Between missions**: `c_e4_turnback` "The
Way Back" (ENGINE stage 1:10; beats for its writer: night at Cinderwatch; Ysolde writes to Vessa by lantern light;
Maelis: the Sighing Wood is still under Torvald's rime and Aldra's totems, "they froze it so it would stay dead";
Ysolde unwraps the seed-pod token Vessa kept for her (e2m1's `c_e2_ashes`: "Keep it until the wood can") — Vessa sent it
back with Ashby; a note: "I think the wood can now. V."; Ysolde closes her hand on it; road east at dawn).

## Win / lose
| Event | Result |
|---|---|
| `obj_convoys` done | **Victory** (after `e4m2_border`) |
| Ysolde dies | **Defeat** (instant loss) |
| Walkers lost > `total - needed` | **Defeat** |
| Heartwood destroyed | **Defeat** |
| Maelis fallen, Wren kneeling, all soldiers dead | Nothing |
| Every Gallow Hollow building destroyed | Later Shadow waves spawn at `(0, -47)`; no win by itself |

## Reward carried to e4m3
- No artifact (the token in `c_e4_turnback` becomes the Heartwood Seed only when the wood grows back, e4m3).
- The 6 item slots at victory; essence 50 %, cap 1 500, **+300 first if `sec_brook`**, **+200 first if `sec_hollow`**,
  **+10 per walker arrived above `needed`** (max +100).
- `CampaignState.MISSION_REWARDS[&"e4m2"] = {"flags": {"e4m2_brook_thawed": "sec_brook", "e4m2_hollow_burned":
  "sec_hollow", "e4m2_maelis_called": "sec_maelis"}, "bonus_essence": {"sec_brook": 300, "sec_hollow": 200}, "next":
  &"e4m3"}`; plus the always-set flag **`helper_maelis_unlocked`** (later Nature missions switch helpers on; the Theatre
  reveal `helper_maelis` "The Forest Has Opinions" unlocks) and `e4m2_folk_arrived` (count).
- e4m3 hooks: `e4m2_hollow_burned` = Hush is not in e4m3's waves (the hunters are broken); `e4m2_folk_arrived >= needed + 5`
  = 4 Nature volunteers (Thornlings, veterancy 2) join at e4m3's start.
- Level not carried.

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Group / wave counts | x 0.6, no Knight / Mortar / Oathsworn | as written | x 1.4 |
| Start crystals | 500 + 2 extra Thornlings | 400 | 300, no Greenheart |
| Convoy auto times | 3:00, 8:00, 13:00, 18:00 | 3:00, 7:30, 12:00, 16:30 | 3:00, 7:00, 11:00, 15:00 |
| Needed | 60 % of total (40 -> 24) | 75 % (30) | 85 % (34) |
| Cower radius | 12 m (they stop earlier: safer) | 10 m | 8 m |
| Hush | L3, flees at 35 % | L4 / L5 | L6, flees at 20 %, back in 60 s |
| Maelis first call | 200 + 50, 30 s | 250 + 100, 30 s | 300 + 150, 45 s |
| Expected time | 17-20 min | 18-22 min | 21-25 min |
**Fight sizing** (normal; army value = crystals + wizard / helper worth; every fight <= 70 % of the army the player can
have **at that place** then, the escort split counted: ~65 % of the army escorts, ~35 % guards Larkrest until B1 is done).
| Fight | When | Enemy | Player then | Ratio |
|---|---|---|---|---|
| A1 Hollow Oak | ~3:20 (convoy 1) | 460 | escort ~900 + Ysolde L4 (290) | 39 % |
| H1 | 4:00 | 380 | escort ~900 + Ysolde | 32 % |
| A2 brook (+ totems) | ~4:00-5:00 | 385 (+ 800 HP of totems) | escort ~1 000 + Ysolde | 30 % |
| B1 at Larkrest | 6:00 | 620 | guard ~500 + 1 completed Bramble Spire (100) + the Stronghold keep (16 dmg) | ~70 % with the keep (the base fight the guard must win) |
| A3 Crowstone (Hush L4) | ~5:30-8:30 (convoy 1 or 2) | 725 | escort ~1 300 + Ysolde L5 | 48 % |
| H2 | 9:00 | 645 | ~1 800 + Maelis L5 | 30 % |
| H3 Hush's hunt (Hush L5) | 13:00 | 1 030 | ~2 300 + Maelis + 1-2 Briar Rocs | 40 % |
| H4 the last hunt | ~16:30 | 1 860 | ~3 000 + Maelis + Rocs | 55-62 % |
- The intended answers: A1 = fight in the ferns **before** the convoy reaches it (Bramblesage Snagroot drags a Shade onto
  the road, Thornburst roots the Hounds); A2 = kill the Shardcasters with Pollen Haze up and Burr Slingers, Vinelashers on
  the Rimelings, soldiers on the totems; A3 = Hush dives the walkers, Greenheart Oathkeeper's taunt and Maelis's Thornsnare
  catch her; H3 / H4 = escort in two halves, Briar Rocs over the convoy (Seed Storm roots chargers before they reach it).
- The Citadel is a real choice: 300 + 250 crystals in the 5:45-7:45 window is ~2 minutes of income that does not go into
  soldiers; a player who skips Maelis can still win on normal (H3 at 46 %, H4 at ~70 % of a bigger army).

## Done when (proposed ids; the lead adds them to `waves.md`)
- [ ] **E4M2.M1** (four-wizards-high): `data/maps/green_road.map` 160 x 100, `symmetry=none`, seed 42, Old Wood in autumn,
  the road, brook and every row of the Map table at +-0.5 m; the brook banks block everything but `brook_ice`; paths from
  `PLAYER_START` to every waypoint, both camps and both caches; Map Lab >= 90.
- [ ] **E4M2.S1** (systems): `missions/mission_e4_02.tscn` + `MissionE402` load the map; start state via `apply_to_start`
  (Ysolde L4 + 3 points, cap 7; 400 / 150 + carried; 24 / 60; Heartwood tier 2) and the no-save fallback; Cinderwatch
  (scripted, invulnerable, shop + exchange, gate zone r 8) with Ashby and 6 Flame Guards; the convoy system (D3 / D4: totals
  from `e4m1_folk_saved`, auto times, the Lantern ring 3 s with its refusal, waypoint walk at 3.6 m/s, cower 10 m / 2 s,
  arrival despawn); `brook_ice` slow and thaw; Rime Totems; dormant groups A1 / A3 with their 16 m triggers; section
  "Tiers and the helper". `tests/test_e4m2_s1.gd`: a convoy with no enemy on the road arrives in 37-40 s; a Shade within
  10 m stops the walker and it walks 2 s after the Shade dies; the ring is refused while the last convoy walks; the
  crossing slow is gone once both totems die; the keep reads tier 2 at 0:00 and the Citadel button is greyed until 5:45.
- [ ] **E4M2.S2** (systems-high [H]): objectives and events E1-E22, the 31 lines, waves H1-H4 / brook relief / B1 /
  Withdraw, the -40 % rules for `sec_hollow` and the Frost Hall, Hush's flee-and-return, Maelis's story NPC at 0:00 and her
  exit, the first-call price, win / lose table, difficulty table, `MISSION_REWARDS[&"e4m2"]` + `helper_maelis_unlocked`;
  `CampaignState.MISSION_SCENES[&"e4m2"]`. Test `tests/test_e4m2_s2.gd`: a scripted escort run ends `victory=true`; losing
  11 of 40 walkers = defeat.
- [ ] **E4M2.G1** (gameplay): `meadow_folk` `set_cower(on)` hook and the waypoint walk (reuse the e2m1 survivor walker);
  `helpers_enabled` + `t3_enabled` honoured in this scene (keep card lists Briar Roc on C and Call Maelis on V; neither in
  e4m1); Briar Roc max 3 alive via the mission; test: the walker resumes 2 s after the last enemy leaves 10 m.
- [ ] **E4M2.A1** (ai): profile `mission_e4_02` (Shadow normal knobs, `min_attack_pop` 99, workers 5, no expansion, max
  10 soldiers at `(-2, -22)`), **a Commander with no wizard** (every wizard / spell / item rule skipped when the team has
  none); the Commander ignores `"scripted"` units and the Ice watch's buildings. Test: a team with no wizard runs 10:00
  headless with no error and keeps 10 soldiers at its rally.
- [ ] **E4M2.U1** (ui): objectives panel (convoy line with the next departure, `arrived · lost · on the road` + needed),
  moving green convoy diamonds on the minimap, the Lantern ring, speaker colours for `ashby`, `hush`, `maelis`, `messenger`;
  briefing (3 paragraphs + the cower line); layout from ui-designer.
- [ ] **E4M2.V1** (tech-artist): autumn Old Wood tint variant, the Lantern post (+ flare), the Hollow Oak landmark,
  Crowstone, the frozen brook mesh (ice ribbon, frost feathers, crack-and-thaw state, stepping stones), Cinderwatch
  (a Fire keep variant with an open gate and red banners), `meadow_folk` cower pose; 0 lights, `PERF OK` with H4 on the field.
- [ ] **E4M2.C1** (four-wizards-high): `e4m2_lantern`, `e4m2_hush`, `e4m2_border` as cine timelines on the mission scene,
  `cine check` 0 FAIL; the fallbacks and skip end states above.
- [ ] **E4M2.O1** (Voice Forge agent): the 31 lines (`data/voice/lines/e4m2.json`), every WAV fits its slot; no new speaker.
- [ ] **E4M2.D1** (game-designer): read the lines in game once; trim any line over 2 box lines; write `c_e4_turnback`
  (1:10) from the beats above.
- [ ] **Lead**: a scripted headless run on normal (escort 4 convoys, Citadel, call Maelis) ends `victory=true` in 18-22
  game-minutes with >= 30 of 40 arrived in 3 / 3 runs; a run with no Citadel and no Maelis still wins on normal in 3 / 5.

Dependencies: E4M1 (Ysolde's track, `meadow_folk`, `maelis_story` shares the helper code), the helper roster (TH, the
e2m1 E2M1.G1 mission opt-ins `t3_enabled` / `helpers_enabled`, `Keep.set_start_tier`), the Briar Roc unit (TH.G*),
`MissionBase`, e2m1's walker and `RimeTotem`, `hush_story` (E3M1.G1), World Forge map mode (tool 6).

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Maelis (helper, first call).
- **Why here:** dormant ambushes on a convoy road; strong against clumps and melee rushes; Thornsnare roots Hush.
- **Moment:** A3 at Crowstone Clearing: Thornsnare roots Hush and her Shades.
- **Intro card:** `Maelis. The Wildcaller of the wood: roots, wolves, and an ambush that ambushes back.`

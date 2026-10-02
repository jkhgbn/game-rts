# Campaign mission e4m1: "Hold Lark Hill" (Ysolde + Maelis, with Vessa; Episode 4)

Written 2026-10-02 (`campaign-outline.md` 3.4 and 6 "next up"). Episode 4 "What Grows Back", mission 1 of 4, the first
Nature mission of the story and the **other side of e3m1**: the same afternoon, the same map, the same armies, played
from Lark Hill. Ysolde (player) and Vessa (allied Fire bot) hold the south hill of **Evenmead** against Malrik (Shadow
bot) and Torvald (Ice bot) on the north ridge. It plays right after `ep4_opening`, on the ground that film shows. Target
**22-28 min** on normal. Uses the rules of `skirmish-1v1.md` (2v2 seat form from `ai-2v2.md`), `levels.md`, `items.md`,
`tiers.md` 6, `caster-units.md` 5.3 (Bramblesage), `t3-helpers.md` 4.5 (Maelis), `kingdom-nature.md`, `map-fill.md` 2
and 4 (river, fords, capture points) and the format of `mission-01.md` / `mission-e3-01.md`. New scene
`missions/mission_e4_01.tscn` + `scripts/campaign/mission_e4_01.gd` (`MissionE401 extends MissionBase`, mission id
`e4m1`, campaign-outline D6). Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `+z` = south (the
`forge_evenmead` set frame). Status: **design only**; nothing here is built. Recommended option taken everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | The map | **`data/maps/evenmead.map` exactly as `mission-e3-01.md` D2 / "Map" defines it** (150 x 120, `symmetry=none`, seed 34, every row of that table unchanged). Everything this mission adds (hamlets, farms, the refuge ring, wave spawns) is a **scripted prop or point placed by the mission script**, not a map row, so E34.M1 is not touched | campaign-outline 6 item 6: "the writer of `mission-e4-01.md` must use the same map numbers"; one map, two missions (e34. 7) |
| D2 | Seats and sides | Same 4 seats as e3m1, played from the south: **side 0 = Ysolde (player, Heartwood) + Vessa (ally bot, Fire Keep)**; **side 1 = Malrik (bot, Dusk Keep) + Torvald (bot, Rime Keep)**. In this spec "side 0" always means the player's side (in e3m1 it meant Malrik's) | The capture-point code reads a side index; the mission sets which side is the player's |
| D3 | What the player defends | **People and a tree, not ground.** Primary: the villagers (30 in 3 hamlets and 2 farms) reach the golden tree, the tree stands, Lark Hill holds until **nightfall** (a countdown). The ford is a **secondary** (hold it until the evening horn) and the three standards are posts the enemy takes, not objectives | Canon from e3m1 L24: "The ford fell at dusk. The golden tree still stood. Both hills called it a victory." Both missions can be won without contradicting each other |
| D4 | The golden tree | **A target here** (`MissionTree`, 3 000 HP, team PLAYER), attacked only by the Final wave and Hush's raid. Decor in e3m1 (its D8); same prop, same spot `(-16, 48.5)`, now with an HP bar | e3m1 D8 promised "Ep4 e4m1 saves it the same afternoon" |
| D5 | Tier | **Stronghold only** (`max_tier = 2`), keep starts at tier 1, Stronghold from 3:30, **Bramblesage** taught; Citadel from e4m2 (campaign-outline D7) | The e3m1 reading of D7, mirrored |
| D6 | Maelis | **Story unit** `maelis_story` (team PLAYER): autonomous, Escort stance fixed, the `t3-helpers.md` 4.5 kit at Ysolde's level, not callable, never lost (falls, returns after 45 s at the Heartwood). Becomes callable in e4m2 | Exactly e3m1's Hush rule (its D5), mirrored; `t3-helpers.md` 3 "Missions" |
| D7 | Ysolde's save track | Starts here (campaign-outline D8): **level 3, cap 6**, empty item slots, **400 essence**, **no artifact** (the Heartwood Seed comes in e4m3) | New hero, nothing from Vessa's track; essence makes up for the empty slots (e3m1 D7) |
| D8 | Villagers | New story UnitType **`meadow_folk`** (the e2m1 `wood_folk` walker with a meadow look): team PLAYER, `commandable = false`, pop 0. **Roused** only by Ysolde, Maelis or Wren within 6 m of their hamlet bell; then they walk to the tree by themselves | e2m1 D5 (PLAYER, not NEUTRAL, so the own army never attacks them); "save the villagers" needs Ysolde to go to them |
| D9 | Old Vey | **On the field once**: at Final + 45 s he arrives on the crest as Vessa's story ally (white-gold lightning, invulnerable, the M4 "kneels and returns" rule). That flash is the one e3m1's `e3m1_dusk` shot 4 shows | Pays off e3m1 D9 from the other hill; keeps e3m4's hero-boss Vey fresh (here he fights 3 minutes) |
| D10 | Mother Hush | **Enemy story unit** (team ENEMY, `hush_story` of e3m1 at Malrik's level): escorts Malrik in his waves, leads one raid on the refuge at 17:00, flees at 25 % HP and comes back 90 s later; never killed for good | Same unit as e3m1 (one model, one brain, the side flips); her raid is the night-knife of `ep3_opening` L7 seen from the victim's side |

## Story setup (briefing text, 3 short paragraphs; shown after `ep4_opening`)
1. The horns have sounded on both hills. Malrik and Torvald are coming down to the river, and between them and Lark Hill
   lie three hamlets, two farms, and the Master's golden tree.
2. Ysolde cannot win the valley today. She can keep it: bring every family up the hill to the tree, and hold the hill
   until the sun goes down. Vessa holds the east slope, and has promised to be patient. Nobody believes her.
3. Hold Lark Hill until nightfall. Let them have the water if they must. Nothing that lives on this hill is theirs.
Variant (flag `e3m1_standard_toppled` in the save, i.e. Episode 3 was played): paragraph 3 gains `You have seen this
afternoon from the other hill. This time, stand under the tree.`
Briefing objectives: `obj_folk`, `obj_tree`, `obj_nightfall`, the rule `Ysolde must survive`.

## Map: "Evenmead" (150 x 120, `data/maps/evenmead.map`, seed 34, not mirrored)
**Binding:** the e3m1 "Map" table (keeps, halls, nodes and amounts, the river polyline, the three fords, the ford zone,
the ford stones, the three standards, the two Horn Spires, the crest, the four crest spires, the golden tree, both
pavilion sets, the four rallies) is reused **row for row, unchanged**. Only the owners read differently from the south:
| e3m1 row | In e4m1 |
|---|---|
| Heartwood `(-32, 48)`, Grove Hall `(-44, 40)`, nodes `(-41, 44)` / `(-36, 56)` 1 500, expansion `(-56, 26)` 2 000 | **The player's base** (`PLAYER_START` = Ysolde at the crest `(-5, 34)`, the `crest_s` pad) |
| Fire Keep `(20, 50)`, Ember Hall `(32, 42)`, nodes `(29, 46)` / `(16, 58)`, expansion `(52, 30)` | Vessa (ally bot, seat 2) |
| Dusk Keep `(-12, -48)`, Gloom Hall `(1, -48)`, Hovel `(-14, -38)`, nodes `e3_dusk_a` / `_b`, `e3_ridge_w`, `e3_reedfield` | Malrik (enemy bot, seat 1). `e3_reedfield (-24, -14)` 2 500 stays a contested rich node the player may mine |
| Rime Keep `(28, -48)`, Rime Hall (= the Frost Hall, `kingdom-ice.md` 4) `(16, -45)`, nodes, `e3_ridge_e` | Torvald (enemy bot, seat 3) |
| Horn Spires West / East `(-40, 10)` / `(48, 10)` | **The player's** (`horn_spire`, team PLAYER, 540 HP, `counts_for_defeat` false) |
| Crest spires: Bramble `(-24, 32)`, `(-10, 30)` · Ember `(6, 31)`, `(20, 34)` | Bramble = player, Ember = Vessa |
| Standards `std_clover (-28, 20)`, `std_ysolde (1.5, 21.5)`, `std_well (24, 18)` | Owned by side 0 at 0:00; side 1 retakes them |
| Ford zone `zone_ford` centre `(4, 2)` r 7 | Side 1's capture target (sec_ford) |
| The golden tree `(-16, 48.5)` (clearing r 6) | **`MissionTree`** (D4) and the centre of the **refuge** ring r **8** |
| Rallies: Shadow `(-4, -28)`, Ice `(35, -28)`, Nature `(-18, 26)`, Fire `(12, 26)` | Unchanged |
Playable bounds, river (half width 3.0, no bridge), the three ford circles (Stone r 4.5, Reed and Birch r 3.0, `terrain:ford`
`move_speed_pct -0.35`) and the build rules are e3m1's. `Skirmish.river_enabled` stays false; the mission calls
`RiverSystem.setup(polylines, 3.0, null, crossings)` itself.

**Mission props and points** (placed by `MissionE401`, exempt from build checks; positions checked against every e3m1 row,
the river and the flank woods at |x| ~58):
| Thing | Position | Ring r | Notes (distances measured) |
|---|---|---|---|
| Hamlet **Millbrook** (3 cottages + bell) | `(-50, 16)` | 5 | South bank, west: 17 m south of the river, 11.7 m from Horn Spire West, on the west roll's edge; 6 villagers |
| Hamlet **Larkford** | `(-12, 12)` | 5 | South bank, centre: 9 m south of the river, 18.9 m from the ford zone, 13.9 m from `TRACK_S`; 6 villagers |
| Hamlet **Birchend** | `(38, 24)` | 5 | South bank, east: 15.2 m from Lark Well, 17.2 m from Horn Spire East, 15.2 m from Fire's expansion node; 6 villagers |
| Farm **Reedfield** (barn + 2 ricks + bell) | `(-34, -18)` | 6 | **North bank**, west: 17.7 m north of the river, 18 m from Reed Ford, 10.8 m from `e3_reedfield`; 6 villagers; Shadow picket F1 |
| Farm **Birchwater** | `(52, -16)` | 6 | **North bank**, east: 14.6 m north of the river, 14 m from Birch Ford, 18 m from `e3_ridge_e`; 6 villagers; Ice picket F2 |
| **Refuge** (the tree's shade) | centre `(-16, 48.5)` | **8** | Villagers inside count as saved and take **-50 %** damage ("the tree shelters them") |
| Hush's entry | west wood edge `(-56, 38)` | - | Inside the bounds; 41 m to the tree along the Heartwood's north side |
| Side 1 wave spawns | Shadow: Gloom Hall spawn point (Dusk Keep's if gone) · Ice: Rime Hall spawn point (Rime Keep's if gone) | - | As e3m1 |
| Vey's arrival | Fire Keep door `(20, 50)` -> crest `(-1.6, 35)` | - | D9 |
Walk lengths (navmesh): Larkford -> refuge 37 m; Millbrook -> refuge 46 m; Birchend -> refuge 59 m (through Vessa's base);
Reedfield -> Reed Ford -> refuge 78 m (two ford crossings' worth of slow on the one ford); Birchwater -> Birch Ford ->
refuge 92 m. A villager walks 4.0 m/s (bundles): 10-25 s home once roused, far longer if the enemy is on the road.

**Hamlet bell / farm bell** (`MissionBrazier` subclass, no channel): Ysolde, Maelis or Wren within **6 m** rouses the place
at once (a bell rings, its villagers step out of the cottages, minimap ping). Before that the villagers are hidden and
untargetable (`_set_dormant`). A farm can only be roused once its picket (F1 / F2) is dead. A place nobody roused by its
**burn time** burns (Reedfield **8:00**, Birchwater **11:00**, the south hamlets at **12:00** if still unroused: the
evening horn's host torches them): its villagers count as lost (`smoke column` prop, narrator L14 once).

## Start state
| Item | Value |
|---|---|
| Ysolde | **Level 3** (Thornburst r2, Wild Bloom r1), full HP / mana, **level cap 6**; no artifact; 6 empty slots |
| Maelis | `maelis_story` at Ysolde's level (L3: 640 HP, armor 5, 25 damage, range 9.5): Thornsnare, Call the Pack; Wild Stampede from L5 |
| Wren | `wren` (e2m1 UnitType, 260 HP, not commandable, kneels at 1 HP, never dies) 3-6 m behind Ysolde; she can rouse bells |
| Crystals / essence | 300 / **400** (essence +1 / s) |
| Buildings | Heartwood (tier 1; Stronghold from 3:30), Grove Hall (complete), **2 Seed Hollows** (complete, `(-24, 56)` and `(-40, 54)`), Bramble Spires `(-24, 32)`, `(-10, 30)`, Horn Spires W / E |
| Workers | 6 Spriglings gathering (3 on `(-41, 44)`, 3 on `(-36, 56)`) |
| Army (posted where e3m1's guards stood: the same afternoon) | **P1 ford pickets** `(6, 8)`: 4 Thornlings + 2 Burr Slingers · **P2 west horn** `(-40, 10)` ring r 3: 3 Thornlings · **P3 east horn** `(48, 10)`: 2 Burr Slingers + 1 Bramblehorn · **P4 Clover Stone** `(-28, 20)`: 4 Thornlings + 1 Bloomtender · **P5 honour guard** `(1.5, 21.5)`: 2 Greenheart Oathkeepers + 3 Wildwood Archers. Army value **1 770** crystals |
| Population | 6 + 25 = **31 / 60** (Heartwood 20 + 2 Seed Hollows x 20, the 2026-09-27 house rule; **Seed Hollows max 4** this mission = cap 100) |
| Vessa (ally bot, seat 2, Fire) | Level 4 (Fireball r2, Ember Step r1, Kindle r1) at `(-1.6, 35)`; Fire Keep **at Stronghold**, Ember Hall, 2 Hearths, 5 Cinder Hands; **2 Flame Guards** at the ford pickets `(6, 8)`; **Lark Well** `(24, 18)`: 3 Flame Guards + 2 Ember Archers + 1 Pyre Adept; her rally `(12, 26)`: 4 Flame Guards + 2 Ember Archers (14 army pop, 1 340 crystals) |
| Malrik (enemy bot, seat 1, Shadow) | Level 4 (Lance r2, Siphon r1, Shroud r1) at `(0, -36)`; Dusk Keep **at Stronghold**, Gloom Hall, Hovel, 5 Gloom Thralls, 4 Shades + 2 Nightbolts + 2 Grave Hounds at `(-4, -28)`; **Hush** at his side |
| Torvald (enemy bot, seat 3, Ice) | Level 4 (Rime Bolt r2, Flash Freeze r1, Rime Aegis r1) at `(-3.4, -37)`; Rime Keep at Stronghold, Rime Hall, 4 Rime Haulers, 4 Rimeshields + 2 Shardcasters + 1 Frost Mortar + 1 Rimecarver at `(35, -28)` |
| Fog | On; the river, the three fords, the three standards, both crests, the five bells and the refuge explored for side 0 from 0:00 |
| Champions, trade, camps, beasts, wells / shrines | Off (as e3m1); the mission adds only the ford zone and the 3 standards |

## Unlocks (what exists in this mission)
| Kind | Available | Locked (comes later) |
|---|---|---|
| Buildings | Seed Hollow (max 4), Grove Hall, Bramble Spire | Elder Circle, Stagrunner Stables, Bazaar (skirmish only); Citadel (e4m2) |
| Units | Sprigling (keep Z); Grove Hall: **Z Thornling, X Burr Slinger, C Bloomtender, V Bramblehorn, N Thistle Darter**; **from the Stronghold**: **M Vinelasher, `,` Greenheart Oathkeeper** (Grove Hall), **B Bramblesage** (keep) | Wildwood Archer (Hall B, skirmish only: the 3 at P5 are veterans of Ysolde's guard), Briar Roc (Citadel, e4m2) |
| Keep | **Stronghold** (X, 200 crystals, 60 s, from 3:30) | Citadel; Call Maelis (e4m2) |
| Spells | Thornburst (L1), Wild Bloom (L2+), Call the Thicket (L4+) | Cap L6 |
| Items | Base shop (Heartwood, Grove Halls): the 10 components, Verdant Seed, mids incl. Thornweave Vest / Bloomcaller Staff, tops, Ember Draught, Dusk Vial, Homeward Seal; no peddler | Owl Stone; artifacts (e4m3) |
| "+" upgrades | At the Grove Hall from the Stronghold (Thornling+, Burr Slinger+ ...) | - |

### The Bramblesage in this mission (`caster-units.md` 5.3, unchanged numbers)
The mission gives both spells a job: **Pollen Haze** (100 mana, r 3.5, 6 s) silences the ranged lines that cross the
ford behind the melee (W3's 3 Nightbolts, W4's Shardcasters and Nightbolts): hazed archers shoot only within 2.5 m, so the
Thornlings win the bank. **Snagroot** (75 mana) drags the **Gloom Deacon** (W3, Final) out of its Blood Tithe channel and
the **Frost Mortars** (W5) out of their siege line into the Greenheart Oathkeepers. Two hints teach it (E4, E9).

### Maelis (story unit `maelis_story`, D6)
`t3-helpers.md` 4.1 / 4.5 numbers at Ysolde's level (L3 640 HP, L6 760): The Forest Has Opinions (her wolves and own
Saplings within 12 m attack 20 % faster, +1.0 speed; **Bond**: enemies rooted by Thornburst take +20 % from her and her
wolves), Thornsnare (14 s), Call the Pack (28 s), **Wild Stampede from L5** (Ysolde reaches L5 around W4). Brain: Escort
(3-7 m from Ysolde, fights what threatens her first; R2 flee under 25 % to the Heartwood, rest 2 % / s). Not commandable
(`is_commandable()` false; clicking her = read-only inspect card, no stance buttons). **Falls**: body fades, her fall bark
(`helper_maelis_fall`, `Bury me by the roots.`), back at the Heartwood door after **45 s** at full HP, L33 once. She can
ring bells (D8). Kills give essence and XP to the player's team as usual.

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_folk` | Primary | `Bring the villagers to the golden tree (0 / 30 · at least 20)` | **20+** villagers inside the refuge at nightfall; **failed** when the **11th** villager is lost (killed or burned) |
| `obj_tree` | Primary, always shown | `The Master's tree must stand` | Fails = defeat (tree at 0 HP) |
| `obj_nightfall` | Primary | `Hold Lark Hill until nightfall (22:00)` (countdown from 0:00) | The countdown ends with Ysolde, the tree and the Heartwood alive |
| `obj_ysolde` | Primary, always shown | `Ysolde must survive` | Fails = defeat |
| `sec_ford` | Secondary | `Hold the Stone Ford until the evening horn` (side 1's progress bar 0-100 %) | 12:00 reached while side 1 has **not** captured the ford zone; **failed** the moment side 1 captures it |
| `sec_horns` | Secondary | `Keep the Lark horns sounding (2 / 2)` | Both Horn Spires alive at nightfall; **failed** when the second falls |
States through `Events.objective_changed(id, state)`: `"active"`, `"done"`, `"failed"`. Villager counter states: walking
(blue pip), saved (green), lost (grey); the panel line reads `12 saved · 3 lost · 15 still out`.

**Ford zone** (e3m1's `CapturePoint` kind `&"ford"`, side index flipped): side 1 captures it with **60 s** of uncontested
presence (fixed rate, contested = frozen, abandoned = decays 10 % / s); side 0 never needs to capture it. Once side 1 owns
it, it stays theirs (decal turns violet). **Standards** (kind `&"standard"`, r 6): side 0 owns all three at 0:00 (sight 14
each); side 1 neutralises and captures them with e3m1's rules (12 s, x1.25 on their far bank = 15 s); side 0 may retake
them (12 s). They are wave targets and vision, not objectives.

## Guards, waves and the bots (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units are team ENEMY, **not** controlled by any Commander: guards hold their spot with auto-aggro and a 2x leash;
wave units are spawned by the mission at the named spawn and given the order shown (refreshed every 4 s when it says
"then").
| Group | Where | Units | Value |
|---|---|---|---|
| F1 Reedfield picket | Farm `(-34, -18)`, ring r 4 | 3 Shades + 2 Nightbolts | 440 |
| F2 Birchwater picket | Farm `(52, -16)`, ring r 4 | 3 Rimeshields + 2 Shardcasters | 520 |

| Wave | Trigger | Units (spawn) | Order |
|---|---|---|---|
| W1 foragers | 4:30 | 4 Shades + 2 Grave Hounds (Gloom Hall) | Cross Reed Ford; attack-move to the nearest walking villager within 30 m of Millbrook or Reedfield, else Millbrook's bell, then the Grove Hall |
| W2 Torvald's probe | 7:00 | **Torvald** + 4 Rimeshields + 2 Shardcasters + 1 Rime Seer (Rime Hall) | Cross Birch Ford; attack-move to Birchend's bell, then Lark Well; Torvald retreats under 35 % HP (bot rule 8) |
| W3 Malrik's ford assault | 9:30 | **Malrik** + **Hush** + 6 Shades + 3 Nightbolts + 1 Shadow Knight + 1 Gloom Deacon (Gloom Hall) | Attack-move to the ford zone centre; once side 1 owns it, to the nearest side-0 standard |
| Horn call | From 6:00, every **150 s**, **per living Horn Spire** | 2 Thornlings + 1 Burr Slinger at that spire (team PLAYER, **commandable, pop 0 "guests"**, max 12 guests alive) | Join the player (idle at the spire); the hill's folk answering the horn |
| W4 the evening horn | **12:00** | Shadow: **Malrik L5** + 6 Shades + 4 Nightbolts + 2 Hexweavers + 1 Hollow Oathsworn (Stone Ford) · Ice: **Torvald L5** + 4 Rimeshields + 3 Shardcasters + 1 Frost Mortar (Birch Ford) | Shadow: the ford zone, then **Ysolde's Standard**, then the Clover Stone · Ice: Lark Well, then Birchend; every walking villager on the way is a target |
| W5 Ice siege | 15:30 | 2 Frost Mortars + 1 Rime Colossus + 4 Rimeshields + 1 Rimecarver (Rime Hall) | Attack-move to Lark Well, then the Fire Keep (Vessa's side; the call-for-help moment) |
| Hush's raid | 17:00 | **Hush** + 4 Shades (west wood edge `(-56, 38)`, veiled) | The nearest villager in the refuge, then the tree; Hush flees at 25 % HP to the Dusk Keep, back 90 s later with Malrik's group |
| Final | **19:00** | 0 s: **Malrik L6** + Hush + 6 Shades + 4 Nightbolts + 2 Shadow Knights + 1 Gloom Deacon (Stone Ford side) · 20 s: **Torvald L6** + 3 Rimeshields + 2 Shardcasters + 1 Rime Colossus (Birch Ford side) | Shadow: **the tree** (refreshed every 4 s), anything on the way · Ice: the nearest side-0 standard, then **holds there** (E15: Torvald stops at the foot) |
| Withdraw | `obj_nightfall` done | Every living side-1 unit, both wizards, Hush | Walk to the ford zone (no fighting unless attacked); Malrik stands on the ford stones `(12, 9)` for the cutscene |
If `sec_ford` is done at 12:00, W4's Shadow group starts **at the ford's north bank** instead of on the far side of the
zone (it must still cross): no extra numbers, only the bank fight the player prepared for.

**Enemy bots** (`ai.md` + `ai-2v2.md` side council, profile `mission_e4_01_enemy`): easy knobs, `min_attack_pop` 99
(no own attacks), `worker_target_home` 5, no expansion, no new towers, up to **10 soldiers** at their rallies,
`bots_upgrade = false`. Their wizards stay at their crest anchors `(0, -36)` / `(-3.4, -37)` except when a wave carries
them; a dead wizard respawns at its keep after the 2v2 timer and walks back to its anchor or rejoins the current wave.
**Ally bot Vessa** (`ai-2v2.md` ally layer, profile `mission_e4_01_ally`, Supportive): gathers, trains up to **14 army
pop**, defends Lark Well and the Fire Keep, answers the player's pings (attack / defend / help / retreat), never mines
the player's nodes. Scripted on top of the pings: her army **holds Lark Well** from 0:00 (her Defend anchor); at W2 she
answers Birchend if the player has not; at W5 she fights the siege and **pings `help`** at Lark Well (minimap + L19);
from the Final she moves to the **crest** `(6, 31)` and fights beside the tree's east flank. Vessa dying is never a loss
(2v2 respawn); her keep falling is never a loss (her army falls back to the Heartwood). She never charges past the river
(her rule `no_cross` this mission: the joke of the briefing).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (`ep4_opening` played before the scene, then the briefing.) Camera on Ysolde at the crest; L1-L5; `obj_folk`, `obj_tree`, `obj_nightfall` active (countdown runs); hint `Ring the hamlet bells with Ysolde (or Maelis): the villagers walk to the golden tree by themselves. Two farms wait across the river.` (12 s) |
| E2 | First bell rung | L6 (Wren); the hamlet's 6 villagers walk to the refuge |
| E3 | 3:30 | Hint (12 s) `Your Heartwood can become a Stronghold: select it and press X (200 crystals). It opens Vinelasher, Greenheart Oathkeeper (Grove Hall) · Bramblesage (Keep).` |
| E4 | First Bramblesage trained | Hint (12 s) `Bramblesage: Z Snagroot drags an enemy to the Sage. V Pollen Haze makes archers inside it fire only at point-blank range.` |
| E5 | W1 spawns (4:30) | L7-L8 |
| E6 | First farm picket dead | L9 (Maelis), first time only; hint `Ring the farm bell. The farm folk must cross the ford: keep the bank clear while they wade.` (8 s) |
| E7 | W2 spawns (7:00) | L10-L11 |
| E8 | A farm or hamlet burns (any; first time only per kind) | L14; its unroused villagers are lost |
| E9 | W3 spawns (9:30) | L12-L13; hint `Malrik wants the ford. Pollen Haze his archers, Snagroot his Deacon, and hold the south bank.` (10 s) |
| E10 | Side 1 captures the ford zone | `sec_ford` failed (if before 12:00); L15b; W3 retargets to the standards |
| E11 | 12:00 | Cutscene `e4m1_horn` (0:12); L15-L16; W4 spawns; south hamlets still unroused burn (E8); if `sec_ford` still active: done, L17 |
| E12 | A standard captured by side 1 (first) | L18 (Ysolde) |
| E13 | W5 spawns (15:30) | L19 (Vessa's help ping) |
| E14 | Hush's raid spawns (17:00) | L20-L21 |
| E15 | Final spawns (19:00) | L22-L24; 20 s later the Ice group spawns; when it reaches its first standard: cutscene `e4m1_foot` (0:10) with L25; that group then holds |
| E16 | Final + 45 s | Old Vey arrives on the crest (D9): a white-gold bolt at `(-1.6, 35)`, he stands up out of it; L26 |
| E17 | A Horn Spire destroyed | L27 (first one only); `sec_horns` failed when both are gone |
| E18 | Every 10th villager saved | Narrator bark at 10 (L28), Wren at 20 (L29), Ysolde at 30 (L30) |
| E19 | `obj_nightfall` done | Withdraw; cutscene `e4m1_nightfall` (0:30) with L31-L34; `Events.mission_ended(true)` at its end (if `obj_folk` holds: 20+ saved; else defeat, E22) |
| E20 | Ysolde dies | L35; `obj_ysolde` failed; defeat after 3 s |
| E21 | The tree falls | L36; `obj_tree` failed; defeat after 3 s |
| E22 | 11th villager lost (or fewer than 20 saved at nightfall) | L37; `obj_folk` failed; defeat after 3 s |
| E23 | Heartwood destroyed | Defeat after 3 s (no line) |
| E24 | Maelis falls / returns | Her fall bark; L38 when she is back (once per mission) |
Bells can be rung in any order. The intended rhythm: Larkford and Millbrook by Ysolde in the first 2:30 (she walks the
foot of the hill), a detachment across Reed Ford for Reedfield before 8:00 (W1 hunts it), Birchend before W2 (7:00),
Birchwater with Vessa's help or a second detachment before 11:00, then everyone back to the foot for the horn.

## Dialogue (38 lines; speaker colours: Ysolde `(0.55, 0.90, 0.35)`, Maelis `(0.60, 0.85, 0.50)`, Wren `(0.80, 0.92, 0.60)`, Vessa `(1.0, 0.45, 0.1)`, Old Vey `(0.95, 0.95, 0.55)`, Malrik `(0.7, 0.3, 1.0)`, Hush `(0.60, 0.50, 0.75)`, Torvald `(0.55, 0.80, 1.00)`, Obren `(1.0, 0.80, 0.25)`, Narrator `(0.9, 0.85, 0.7)`; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist): `narrator`, `ysolde`, `maelis`, `messenger` (shown as **Wren**),
`vessa`, `vey`, `malrik`, `hush`, `torvald`, `obren` (alias of `whisper`, shown as **Obren**). Every line <= 2 lines of
the dialogue box (<= 96 characters). Wren's stumbles are written into the spoken text (the e2o rule); the subtitle
column is the clean reading where it differs.
| Line | Event | Speaker | Text (spoken) | Subtitle if different |
|---|---|---|---|---|
| L1 | E1 | narrator | The same afternoon, from the other hill. Here nobody counts fords. They count people. | - |
| L2 | E1 | ysolde | Maelis, the horns. Every farm in the valley comes up this hill before dark. | - |
| L3 | E1 | maelis | And the ford? Malrik will want his ford. | - |
| L4 | E1 | ysolde | Let him want it. A ford is water and stones. Those farms are families. | - |
| L5 | E1 | vessa | I'll take the east slope. If Torvald crosses, he can explain himself to a fire. | - |
| L6 | E2 | messenger | Up the hill! Leave the... leave the goats! Up to the golden tree! | Up the hill, to the golden tree! Leave the goats! |
| L7 | E5 | malrik | Ysolde. You are herding sheep while I take your river. That is very you. | - |
| L8 | E5 | ysolde | Sheep come back in spring, Malrik. So do I. | - |
| L9 | E6 | maelis | Through the ford, little ones. Slow is fine. Slow is alive. | - |
| L10 | E7 | torvald | Ysolde. Go home. I have no quarrel with your farms. | - |
| L11 | E7 | ysolde | Then why is your winter standing in them, Torvald? | - |
| L12 | E9 | obren | The green one keeps a tree, Bishop. A golden tree. HIS tree. Take it. | - |
| L13 | E9 | malrik | One thing at a time. The ford first. Then we will talk about trees. | - |
| L14 | E8 | narrator | Smoke over the farms. Whoever was still there is not coming up the hill. | - |
| L15 | E11 | narrator | The evening horn. Malrik's whole host comes down to the water. | - |
| L15b | E10 | ysolde | The ford's gone. Fall back to the stones and the standards. Nobody runs. | - |
| L16 | E11 | ysolde | Let them have the water. Everyone to the foot of the hill. Nobody passes the tree. | - |
| L17 | E11 (`sec_ford` done) | vessa | The ford held till the horn! Ysolde, that was almost reckless. I'm proud of you. | - |
| L18 | E12 | ysolde | They have a standard. Let them carry it. Banners are light. Hills are not. | - |
| L19 | E13 | vessa | Ysolde! Torvald brought mortars to my well. I could use some thorns over here! | - |
| L20 | E14 | hush | The Bishop wanted a look at the tree. I came to look first. | - |
| L21 | E14 | maelis | Behind us! The wood has a knife in it! | - |
| L22 | E15 | obren | There it is. His tree. Burn it, and he feels it in the deep. | - |
| L23 | E15 | malrik | Ysolde! Step aside. I only want the tree. | - |
| L24 | E15 | ysolde | Everyone who ever wanted this tree said "only". | - |
| L25 | E15 (`e4m1_foot`) | torvald | I came for a ford, Bishop. Not for his tree. My host stops here. | - |
| L26 | E16 | vey | Lightning, Bishop. Since before you were born. Off the hill. | - |
| L27 | E17 | ysolde | A horn's down. The other one will have to sing for both. | - |
| L28 | E18 (10) | narrator | Ten families under the tree. The goats, mostly, made it too. | - |
| L29 | E18 (20) | messenger | That's... twenty, my lady. Twenty! The tree's getting... crowded. | That's twenty, my lady! The tree's getting crowded. |
| L30 | E18 (30) | ysolde | Everyone. Every last one. Now we only have to keep them. | - |
| L31 | E19 (`e4m1_nightfall`) | ysolde | The ford is his. The hill is ours, and every family on it, and the tree. | - |
| L32 | E19 | vessa | He'll call it a victory, you know. | - |
| L33 | E19 | ysolde | Let him. Something always grows back. It will not stop. | - |
| L34 | E19 | narrator | Night fell. The golden tree still stood, and everyone who made it up the hill slept under it. | - |
| L35 | E20 | ysolde | Keep them... under the tree... Maelis... | - |
| L36 | E21 | maelis | The Master's tree... It's gone dark. | - |
| L37 | E22 | ysolde | Too many. We were too slow, and the valley is empty. | - |
| L38 | E24 (return) | maelis | The forest is not done with me. Neither am I. | - |
Echoes: L33 is `ep4_opening` L15 ("It will not stop"), answering e3m1 L23 ("I will not stop"); L32 answers e3m1 L24 ("Both
hills called it a victory"); L23-L24 and L12 are the stone pulling Malrik toward the tree (e3m1 L15); L25 is Torvald's
doubt from the other side (e3m1 L16), the first spoken step of his turn (e4m4, Ep7); L26 is Vey's own Ep1 line ("Since
before you were born") and the flash e3m1 shows; L10-L11 seed e4m3 / e4m4. Voice: Voice Forge with `cast.json` as approved;
`obren` uses the whisper voice; Maelis's fall / revive barks are the helper hooks (`helper_maelis_<event>`).

## Cinematic hooks (ENGINE, on the live mission scene, CinematicPlayer 19.C1; skippable; units frozen while they play)
Camera axis: all three keep the `ep4_opening` rule (**cameras west** of the north-south Malrik - Ysolde line).
| id | When | Length | Shots (camera, what we see) | Lines | Skip end state |
|---|---|---|---|---|---|
| `e4m1_horn` | E11 (12:00) | 0:12, HOLD | 1) WIDE from the `B14R` mark `(-70, 40, 0)` -> `(-60, 42, 8)`: Malrik's host comes down to the Stone Ford, the Ice column to Birch Ford; 2) MS Ysolde on the crest, 3/4-left, staff raised; each living Horn Spire puffs its sound-wave ring | L15-L16 | W4 spawned at both fords with its orders; south hamlets that were not roused are burning (props) and counted lost; `sec_ford` resolved; camera back on Ysolde |
| `e4m1_foot` | E15, the Ice group reaches its first standard | 0:10, HOLD | 1) MS Torvald at the standard, 3/4-left, he raises one hand; his Rimeshields ground their shields; 2) long lens (fov 24) from the standard south-west up to the tree: Malrik's column passing on toward it, amber pulse in his hand (soft) | L25 | The Ice Final group (and Torvald) set to `hold` at that standard until the Withdraw; Shadow Final group unchanged |
| `e4m1_nightfall` | E19 | 0:30, then victory | 1) WIDE crane from the `B14R` mark as the light ramps from golden to dusk (`preset_golden` -> dusk tint over 6 s; same ramp as `e3m1_dusk`); 2) MS Ysolde under the golden tree, 3/4-left, villagers sitting in the refuge, Wren asleep against the trunk; 3) CU Ysolde's hand on the bark: blossoms open (`bloom_open`); 4) long lens north (the `S12` mark, fov 22): Malrik standing on the ford stones `(12, 9)`, the amber pulse, and **one white-gold lightning flicker** behind the camera on the crest (Vey, the flash `e3m1_dusk` shows from the north); 5) CU Ysolde, front: L33; FADE_BLACK; L34 over black | L31-L34 | `Events.mission_ended(true)` fired, rewards and flags saved (section "Reward"), StoryFlow continues to `c_e4_refuge` |
Fallbacks until Motion Lab / VFX Composer exist: Torvald's raised hand and the blossom open are skipped (WARN); missing
VFX ids are skipped; if the cine tool or `forge_evenmead` marks are missing, each hook = its lines as dialogue + a 2 s
camera pan to its subject. **Between missions**: `c_e4_refuge` "What the Tree Saw" (ENGINE stage 1:10, the episode's
first between-scene; beats for its writer: night under the golden tree; villagers asleep; Vessa and Ysolde share bread;
Vessa: "You'd have let him have the ford all along." Ysolde: "Fords don't bleed."; Maelis brings word that Malrik's knives
burned the supply wagons in the night (e3m2 "Another Night", the mirror); the people must walk west through the woods to
the Fire border; Vessa: "Then I'll tell Ashby to leave the gate open." Fade on the tree).

## Tiers (`tiers.md` 6)
| Item | Value |
|---|---|
| Code | `MissionE401._init`: `tiers_enabled = true`, `casters_enabled = true`; `_ready`: `tier_system.max_tier = 2`, `bots_upgrade = false` |
| Heartwood card | Z Sprigling, **X Stronghold** (gold pulse when it can start), **B Bramblesage** (greyed `Requires Stronghold`), Set Rally r3c1; no Citadel, no Call button |
| Grove Hall card | Z X C V N as listed; **M Vinelasher, `,` Greenheart Oathkeeper** greyed until the Stronghold; "+" page from the Stronghold |
| Bots | Vessa, Malrik and Torvald start at the Stronghold and never reach the Citadel; the enemy's scripted tier-2 units (Hexweaver, Hollow Oathsworn, Frost Mortar, Gloom Deacon, Rimecarver) are spawned, not trained |
Timing: Stronghold 3:30 -> 4:30 at the earliest; first Bramblesage ~5:00, Vinelashers / Oathkeepers ~5:30, before W2
(7:00) and the ford fight (9:30-12:00).

## Economy
| Item | Value |
|---|---|
| Start | 300 crystals, 400 essence, 31 / 60 pop, 6 Spriglings, 1 770 crystals of army |
| Nodes (player) | Home 2 x 1 500, west expansion `(-56, 26)` 2 000 (hall spot as the e3m1 bot's), contested rich `e3_reedfield` 2 500 on the north bank (only with an army there) |
| Expected income (normal) | ~10 Spriglings by 5:00 (Nature's 40-crystal workers); ~3 300 crystals mined by 22:00 (the home nodes run dry around 19:00) |
| Essence (expected by 22:00) | 400 start + trickle ~1 320 + kills ~1 600 (≈ 60 Shadow / Ice units, 1-2 wizard kills) = **~3 300**: one top or two mids (suggested Bloomcaller Staff -> Heart of the Grove: it heals the line in the long foot fight) |
| Horn guests | Up to 12 free Thornlings / Burr Slingers over the mission while the horns live (the reason `sec_horns` matters) |
| Vessa | Her own nodes; her army cap (14 pop) keeps her a helper, never the carry |

## Win / lose
| Event | Result |
|---|---|
| `obj_nightfall` done with 20+ villagers saved | **Victory** (after `e4m1_nightfall`, `Events.mission_ended(true)`) |
| Ysolde dies | **Defeat** (`instant_loss_on_wizard_death = true`) |
| The golden tree falls | **Defeat** |
| 11th villager lost, or fewer than 20 saved at nightfall | **Defeat** |
| Heartwood destroyed | **Defeat** |
| Vessa dies / her keep falls | Nothing (message `Vessa falls back to the Heartwood`); she respawns as a 2v2 wizard |
| Maelis falls | Nothing; back in 45 s |
| Wren kneels | Nothing; she stands after 8 s |
| An enemy keep destroyed | Allowed, not needed; message `The ridge burns, but the Bishop holds it` (the enemy wizard respawns at the other keep) |

## Reward carried to e4m2 (Ysolde's track, campaign-outline D8)
- No artifact yet (the Heartwood Seed is e4m3's). The 6 item slots as they are at victory; essence **50 %, cap 1 500**.
- `sec_ford` done: **+300 essence** at victory (before the cut). `sec_horns` done: **+200 essence**. **+10 essence per
  villager saved above 20** (max +100).
- Flags saved: `e4m1_folk_saved` (count 0-30), `e4m1_ford_held`, `e4m1_horns_held`, `e4m1_time` (seconds),
  `maelis_story_met` (always true). e4m2 reads `e4m1_folk_saved`: the convoys carry **40 - (30 - saved)** villagers with a
  floor of 30 (the people lost on Lark Hill are not on the road).
- `CampaignState.MISSION_REWARDS[&"e4m1"] = {"flags": {"e4m1_ford_held": "sec_ford", "e4m1_horns_held": "sec_horns"},
  "bonus_essence": {"sec_ford": 300, "sec_horns": 200}, "next": &"e4m2"}` + the villager count and bonus.
- Level not carried (e4m2 sets its own start).

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave / guard counts | x 0.6, no Shadow Knights, no Rime Colossus | as written | x 1.4; Final wizards L7 |
| Start | 450 crystals, +3 Thornlings at P4 | as written | 250 crystals, no Bramblehorn at P3 |
| Nightfall | 19:00 | 22:00 | 25:00 (every wave after W3 shifts +1:30, the Final +3:00) |
| Villagers needed / lost allowed | 15 / 15 | 20 / 10 | 24 / 6 |
| Burn times (Reedfield / Birchwater) | 10:00 / 13:00 | 8:00 / 11:00 | 7:00 / 9:30 |
| Tree HP | 4 000 | 3 000 | 2 400 |
| Vessa army cap | 18 pop | 14 | 10 |
| Expected time | 20-22 min | 23-25 min | 26-29 min |
Expected run on normal: Larkford + Millbrook rung by 2:30 -> detachment over Reed Ford, F1 cleared ~4:00, Reedfield folk
cross while W1 (4:30) hunts them -> Stronghold 3:30-4:30, Bramblesage ~5:00 -> Birchend before W2 (7:00) -> F2 with
Vessa's ping ~8:00-10:00 -> W3 ford fight 9:30-12:00 -> horn 12:00 (cut) -> foot fight 12:00-15:00 -> W5 at Lark Well
15:30 -> Hush 17:00 -> Final 19:00-22:00 -> nightfall cut -> **~23-25 min** (a timed mission; retries make 28).
Fight sizing (army value, crystals + wizard worth `170 + 30 x level`, helper / Hush `200 + 40 x level`; every fight <= 70 %
of what the player side can have then, ep1 4.1 rule; Vessa counted only where her scripted anchor puts her):
| Fight | Enemy | Player side then | Ratio |
|---|---|---|---|
| F1 Reedfield picket (~3:30) | 440 | a ~900 detachment + Ysolde L3 + Maelis | 37 % (of the detachment) |
| W1 foragers (4:30) | 460 | ~2 000 + Ysolde + Maelis | 23 % |
| F2 Birchwater picket (~8:30) | 520 | ~900 detachment + Vessa's ~700 sent on a ping | 33 % |
| W2 Torvald's probe (7:00) | 1 030 (Torvald L4 290) | ~2 300 + Vessa 1 340 at Lark Well | 45 % / 28 % |
| W3 ford assault (9:30) | 1 880 (1 230 of units + Malrik L4 290 + Hush L4 360) | ~2 700 + Vessa's 2 ford Flame Guards (180) | 65 % (the skill check) |
| W4 evening horn (12:00) | 2 860 (2 220 of units + Malrik L5 320 + Torvald L5 320; Hush is not in it) | ~3 200 + Vessa ~1 340 | 63 % |
| W5 Ice siege (15:30) | 1 260 | Vessa ~1 340 + a ~800 detachment | 59 % |
| Hush's raid (17:00) | 720 (Hush L5 400 + 320) | refuge guard ~600 + Maelis L5 + 2 crest spires + the tree | ~55 % |
| Final (0 s / +20 s) | 2 420 (Malrik L6 350 + Hush L6 440 + 1 630) / 3 620 total (+ Torvald L6 350 + 850) | ~3 800 + Ysolde L6 + Maelis L6 (790) + Vessa ~1 340 + Vey (from +45 s) | 41 % / 61 % |
- The ford is the skill check, as in e3m1, from the bank that is **not** wet: the defenders stand on the south bank while
  Malrik's army wades at -35 % speed; Pollen Haze on the Nightbolts, Thornburst on the ford's exit, Snagroot on the Deacon.
  Losing the ford is allowed (D3); losing the army in it is not.
- The farms are the "do I go across" choice: each is 6 villagers out of the 10 the player may lose; skipping both is a
  defeat at 11:00 on normal (12 lost). Reedfield is the cheap one (Shadow picket, W1 nearby), Birchwater the expensive
  one (Ice picket, armour 15: Vinelashers or Vessa's Pyre Adept).
- The Final is won at the tree, not at the foot: the Ice group stops at its standard (E15), so the player's whole army
  can collapse onto the refuge. Old Vey from +45 s turns it, as he turns M4.
- Watch in the first playtest: if W3 wipes the ford defenders, move it to 10:30; if the Final reaches the tree too fast,
  make its Shadow group capture a standard first (+30-40 s).

## Done when (proposed ids; the lead adds them to `waves.md`)
- [ ] **E4M1.S1** (systems): `missions/mission_e4_01.tscn` + `scripts/campaign/mission_e4_01.gd` load `evenmead.map` (no
  change to E34.M1); `RiverSystem.setup` with e3m1's polyline and 3 fords; 4 seats on 2 sides with **side 0 = player +
  Vessa**; start state exactly as the table (300 / 400 / 31 of 60, 2 Seed Hollows, Hollow max 4, posts P1-P5); the ford zone
  (side-1 capture, 60 s) and 3 standards owned by side 0 at 0:00; `MissionTree` (3 000 HP, armor 20, building regen,
  refuge ring r 8 with -50 % damage to villagers); 5 bells (rouse by Ysolde / Maelis / Wren within 6 m; farms only after
  their picket dies); `meadow_folk` walkers (4.0 m/s, walk to the refuge, counted inside r 8); burn times; pickets F1 / F2
  with a 2x leash. `tests/test_e4m1_s1.gd`: a bell rung at 0:10 brings its 6 villagers into the refuge; Reedfield burns at
  8:00 if unrung and counts 6 lost; the ford zone completes for side 1 in 60 s and never for side 0.
- [ ] **E4M1.S2** (systems-high [H]): objectives and events E1-E24 in order; waves W1, W2, W3, horn call (per living spire,
  every 150 s from 6:00, guests pop 0, max 12), W4, W5, Hush's raid, Final (Shadow on the tree refreshed every 4 s, Ice
  holds at its first standard), Withdraw; `sec_ford` / `sec_horns`; the villager counter and the 11-lost rule; instant loss
  on Ysolde's death; tree / Heartwood loss = defeat; Vessa / Maelis / Wren never end the mission; Old Vey's arrival at
  Final + 45 s (story numbers: `helper_vey` kit at L5, invulnerable, kneels 8 s at 1 HP); difficulty table.
  `tests/test_e4m1_s2.gd`: a scripted run that rings all 5 bells and holds ends `victory=true` at 22:00 + the cut; a run
  with 11 villagers lost ends in defeat.
- [ ] **E4M1.S3** (systems): victory saves **Ysolde's track** (D8): level not carried, 6 slots, essence 50 % cap 1 500
  (+300 / +200 / villager bonus first), the flags; a headless test loads e4m2's start and finds them; Vessa's and Malrik's
  tracks are untouched.
- [ ] **E4M1.G1** (gameplay): `maelis_story` (helper kit of `t3-helpers.md` 4.5 at Ysolde's level, Escort brain, not
  commandable, falls and returns in 45 s at the Heartwood; can ring bells), `meadow_folk` UnitType (45 HP, 4.0 m/s, pop 0,
  `commandable` false; look variant of `wood_folk`), `hush_story` usable on team ENEMY (flee at 25 %, back in 90 s);
  test: Maelis never stays dead and Thornsnare roots a clump of 3 within 12 m.
- [ ] **E4M1.A1** (ai): profiles `mission_e4_01_enemy` (defend only, 10 soldiers at the rally, wizards at their crest
  anchors except when a wave carries them) and `mission_e4_01_ally` (Vessa: 14 pop, Lark Well anchor, pings, `no_cross`,
  the W2 / W5 / Final scripted moves); scripted units never join a Commander.
- [ ] **E4M1.U1** (ui): objectives panel with the nightfall countdown, the villager line (`saved · lost · still out` +
  pips), side 1's ford bar under `sec_ford`, the horns 2 / 2; tree HP bar; bell pings on the minimap; DialogueBox colours
  for `maelis`, `messenger` (Wren), `vey`, `hush`, `torvald`, `obren`, `vessa`; briefing (3 paragraphs + the Ep3 variant).
- [ ] **E4M1.C1** (systems-high, after 19.C1 / 19.C2): the 3 ENGINE cutscenes as listed with their skip end states;
  StoryFlow plays `ep4_opening` -> briefing -> e4m1 -> `c_e4_refuge`; skip works and leaves the listed state.
- [ ] **E4M1.V1** (tech-artist): hamlet set (3 cottage variants, a bell post, a smoke-column burn state), farm set (barn,
  2 ricks, bell), the refuge ring decal, the golden tree's HP-damage states (leaves thin, glow dims, never "dead" before
  0 HP), `meadow_folk` look (Sprigling base, meadow smock, bundle, a goat or two as cosmetic critters); 0 lights, Art Lab pass.
- [ ] **E4M1.O1** (Voice Forge agent): the 38 lines rendered with `cast.json` voices; every WAV fits its 5 s slot.
- [ ] **E4M1.D1** (designer): read the 38 lines in game once; trim any line over 2 box lines; write `c_e4_refuge` (1:10)
  from the beats above; check that the map numbers still equal `mission-e3-01.md`'s table.
- [ ] **Lead**: a scripted headless run on normal (ring 5 bells, hold the ford to 12:00, hold the foot, defend the tree)
  ends `victory=true` in 22-28 game-minutes in 3 / 3 runs; the W3 fight leaves Ysolde alive in 5 / 5 runs with the scripted
  army; e3m1's own test still passes on the shared map.

Dependencies (must exist first): E34.M1 map (shared with e3m1), 19.C1 CinematicPlayer + 19.C2 StoryFlow (cutscenes only;
the mission plays without them), the 2v2 seat API and ally layer (`ai-2v2.md`, 20.A*), `RiverSystem` / `CapturePoint`
(step 12), `MissionBase` (M9.S1), the helper ability code (TH / 19.C12) for Maelis, Hush and Old Vey, e3m1's
`hush_story` (E3M1.G1) and e2m1's `wren` (E2M1.G1).

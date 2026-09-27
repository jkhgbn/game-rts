# Terrain types and kingdom affinities (Crown Hollow)

Task 12b.D1, written 2026-09-26, revised the same day with the user's answers. Source of truth for step 12b (tasks in
section 15). User request: ground types with gameplay effects (sand, snow, mud / marsh, deep forest, road, shallow water /
fords, ash / scorched ground) and kingdom affinities: **Ice** fast on snow, slow on sand; **Fire** strong on ash and sand;
**Nature** = riverbanks and water (fast in fords, heals by the river; slow on snow); **Shadow stays neutral** (no terrain pros
or cons). Everything here is our own. Metres, seconds, `m:ss` since the navmesh was ready, positions `(x, z)`, `+x` east,
`+z` south; **point mirror**: every patch at `(x, z)` has its twin at `(-x, -z)`. Builds on `map-fill.md` (step 12: river,
fords `terrain:ford` -35 %, biomes, `RiverSystem`, 240 x 240 masks), `kingdom-ice.md`, `kingdom-nature.md`,
`units-fire-shadow.md`, `spells.md`, `research.md` (Q3: no army-wide Nature regen), `cavalry-mounts.md` (flyers, titans,
mounts), `rush-balance.md` (targets 45-55 % per matchup, games 15-20 min), `ai.md`, `fog-of-war.md`, and the Stats contract
of `scripts/units/unit.gd` (`add_modifier`, `*_pct` keys, one recompute per change).
**Built with / after step 12** (shares the ground shader, map dressing, `skirmish.gd`, `env_props.gd`, UI and bot files).

## 0. User decisions (final, 2026-09-26)
| # | Question | Decision |
|---|---|---|
| Q1 | How does Nature heal by the river? | **Out of combat only** ("Riverside mending"): Nature units on riverbank, fords and marsh regenerate **1 % max HP / s after 4 s without damage**. Research Q3 ("no army-wide regen") stays true everywhere else |
| Q2 | Fire has two pros (ash, sand) and no con. Nerf Fire? | **No Fire con.** "Balance all the others to be stronger, with more HP if need be": Ice, Nature and Shadow get the compensation (terrain buffs for Ice / Nature, a per-kingdom HP modifier for all three), never a Fire nerf (section 11.2) |
| Q3 | Where does scorched ground come from? | **RNG**: seeded, mirrored **wildfires and lightning strikes** pop up at random spots during the match with a **10 s warning**, leave ash, and fade (section 6.2). Fire's own fire also scorches (section 6.3); two small static Cinder Scars exist from 0:00 |

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Terrain types | **9 walkable ids + water**: open ground, road, riverbank, ford (shallow water), marsh (mud), deep forest, snow, sand, ash (section 2) | Readable: 5 new looks on top of step 12's river |
| Effects | Speed for most; damage on ash; sight in forest; regen for Nature by the river. All through **one Stats modifier `terrain:<id>`** per unit | Uses the existing Stats system; the UI shows one icon |
| Base vs affinity | Each terrain has a **base effect** (the same for everyone) and some kingdoms **replace** it with their own row (section 3). **Shadow uses the base row** ("neutral" = the reference kingdom: no bonus, no penalty of its own) | One number per kingdom per terrain; Shadow's identity stays Souls / research (user) |
| Fire | Pros only (sand, ash); on every other terrain it uses the base row (Q2) | User |
| Compensation (Q2) | Ice snow **+25 %** (not +20), Nature mending + ford / riverbank speed, and a per-kingdom soldier HP modifier `kingdom:hardy` (start Shadow **+4 %**, Ice **+3 %**, Nature **+3 %**, Fire 0), tuned up in steps, never Fire down | "Make the others stronger, with more HP if need be" |
| Who is affected | Soldiers, wizards, champions (base row: champions have no kingdom), titans (except the flying dragon), summons, creatures, beasts. **Workers and caravans: only the step-12 ford slow** | Economy and trade numbers stay exactly as `economy.md` / `market-trade.md` |
| Map | Point-mirrored patches on Crown Hollow: snow at both essence wells and under the cliffs by the river mouths, sand at the home watchtowers and the heath flanks, ash in two Cinder Scars, marsh at both fords, thickets in the Old Woods; roads and the lane are road; the river banks are riverbank (section 4) | Every kingdom's good ground sits at objectives (wells, towers, fords) on **both** banks |
| Random ash (Q3) | From 4:00, every 100-140 s (seeded), a **mirrored pair** of spots gets a wildfire (r 4.5) or a lightning strike (r 2.5), announced **10 s** before; ash lasts 90 / 60 s (section 6.2) | Fair by construction (both sides get the same event at the same moment), readable (warning ring, minimap ping, message) |
| Sampling | A 240 x 240 byte grid (0.5 m cells) built once at start; units sampled at **4 Hz**, staggered, modifier changed only when the terrain changes (section 5) | O(1) lookup, < 0.05 ms / frame |
| Pathing | Units keep the **shortest navmesh path** (no terrain costs in the navmesh). The **bot** chooses routes and waiting spots with terrain weights (section 9) | Predictable orders for the player; per-kingdom costs are impossible in one navmesh |
| Fog | Static terrain and random events are public (ground and weather). Fire's own scorch is drawn for a team only where it saw it | No information leak |
| Missions | `terrain_enabled` false by default; a mission may place its own patches and events | One new system per mission |

## 2. The terrain types
| id | Name in the tooltip | Where (section 4) | Base effect (everyone; Shadow; champions; creatures) | Look (12b.V1) |
|---|---|---|---|---|
| `grass` | Open ground (or the biome name: Meadow, Heath, Glade, Crown Isle ruins) | Everything else | none | Today's ground + step-12 biome tints |
| `road` | Road | Step-10 ring road (3 m), the lane (keep hub -> keep hub, 5.2 m) **outside the Crown Isle** (r > 11), all 4 bridge decks | **+10 % speed** | Existing road / lane layers |
| `riverbank` | Riverbank | Land within **3.0 m** of deep water; not on the Crown Isle (r < 11), not on roads or bridges | none | 12.V2 wet bank band (dark earth -> sand) |
| `ford` | Ford / shallows | The 2 fords (r 3.5) and 2 Crown Steps (r 3.0) of `map-fill.md` 2.2 | **-35 % speed** (unchanged from step 12) | 12.V1 ford film |
| `mud` | Marsh | 4 marsh patches on both approaches of both fords | **-20 % speed** | Wet dark mud, puddles, reeds |
| `forest` | Deep forest | 3 thickets per Old Wood (the step-12 tree clusters and the Gloomcap nook) | **-10 % speed, -30 % sight** | Dark needle floor, dense ferns |
| `snow` | Snow | 2 snowfields per bank | **-15 % speed** | Painted snow drifts, blue shadows, sparkle |
| `sand` | Sand | 2 sand patches per bank | **-10 % speed** | Warm ochre sand with wind ripples |
| `ash` | Ash / scorched ground | 2 static Cinder Scars, random wildfires / lightning, Fire's own scorch (section 6) | none | Charred black-grey ground, faint embers |
| `water` | Deep water (impassable) | River and moat (`RiverSystem.is_water`) | not walkable | 12.V1 |

## 3. Kingdom affinities
### 3.1 The effect table (final values; a kingdom not listed on a row uses the base row)
| Terrain | Base (Shadow, champions, creatures; Fire where not listed) | Fire | Ice | Nature |
|---|---|---|---|---|
| Open ground | - | - | - | - |
| Road | +10 % speed | +10 % speed | +10 % speed | +10 % speed |
| Riverbank | - | - | - | **+10 % speed, Riverside mending** |
| Ford / shallows | -35 % speed | -35 % speed | -35 % speed | **+10 % speed, Riverside mending** |
| Marsh | -20 % speed | -20 % speed | -20 % speed | **no slow, Riverside mending** |
| Deep forest | -10 % speed, -30 % sight | same | same | same |
| Snow | -15 % speed | -15 % speed | **+25 % speed** | **-30 % speed** |
| Sand | -10 % speed | **+10 % speed** | **-25 % speed** | -10 % speed |
| Ash | - | **+10 % damage** | - | - |
Riverside mending (Q1) = `idle_regen_pct` **+1.0** (1 % max HP / s after the existing 4 s without damage).
Summary per kingdom: **Fire** pros sand, ash; no con. **Ice** pro snow (+25 %, the Q2 compensation); con sand. **Nature**
pros riverbank, fords, marsh (+ mending); con snow. **Shadow** none (compensated by HP, 11.2). Road and forest are the same for
all.

### 3.2 As Stats modifiers (source id `terrain:<id>`, at most one per unit; open ground and empty rows add nothing)
| Key | Meaning | Hook |
|---|---|---|
| `move_speed_pct` | Additive with every other `_pct` source (Wayshrine +0.12, Hamstring -0.25...) | existing |
| `attack_damage_pct` | Auto-attacks and anything that reads `attack_damage` (wizards' spells are unaffected) | existing |
| `idle_regen_pct` | Adds to the unit's idle regen (% of max HP / s after 4 s without damage) | **new Stats stat** (the same hook `research.md` 4.6 lists; whichever step lands first builds it) |
| `sight_scale` | Flat fraction added to sight: FogOfWar uses `sight x clamp(1 + sight_scale, 0.5, 1.5)` | **new**, read in `FogOfWar.sight_of` and for `"fog_sources"` Units |
The exact dictionary is `TerrainSystem.EFFECTS` (section 13). The Q2 HP compensation is a separate modifier `kingdom:hardy`
(section 11.2), not a terrain effect.

### 3.3 Who gets terrain
| Unit | Rule |
|---|---|
| Soldiers, titans, summons (Saplings, Risen) | Their `UnitType.faction` row (`&"fire"`, `&"ice"`, `&"nature"`; `&"shadow"` = base) |
| Wizards | Their kingdom's row (Torvald fast on snow, Vessa fast on sand...) |
| Champions, trackers, Magpies, creatures, beasts, the neutral wardens | Base row |
| **Workers, caravans** (`is_worker`, `is_caravan`) | **Only the ford base value** (-35 %, the step-12 rule); nothing else. Economy and trade income never depend on terrain or kingdom |
| Amphibious (group `"amphibious"`: Mirefangs) | Ford and marsh count as open ground |
| Flying (tag `&"flying"`: Cinder Dragon, Sparkwing) | No terrain at all (and no wildfire / lightning damage) |
| Riding heroes | Terrain applies; the step-13 riding cap **7.5 m/s** still holds |
| Buildings, towers | Never (they do not move; sight and damage unchanged; wildfire / lightning never damage buildings) |
`chill` (-1.5 m/s flat) and terrain percent stack as the Stats formula says: `(base + flat) x (1 + sum of pct)`, floors
unchanged (chill floor 1.0 m/s).

### 3.4 What it means in numbers (level 1, no items, before `kingdom:hardy`)
| Unit (base speed) | Road | Snow | Sand | Ford | Marsh | Riverbank | Forest |
|---|---|---|---|---|---|---|---|
| Flame Guard (5.0) | 5.5 | 4.25 | **5.5** | 3.25 | 4.0 | 5.0 | 4.5 |
| Blaze Rider (7.5) | 8.25 | 6.4 | **8.25** | 4.9 | 6.0 | 7.5 | 6.75 |
| Shade (4.8) | 5.28 | 4.08 | 4.32 | 3.12 | 3.84 | 4.8 | 4.32 |
| Rimeshield (4.2) | 4.62 | **5.25** | **3.15** | 2.73 | 3.36 | 4.2 | 3.78 |
| Rime Colossus (3.4) | 3.74 | **4.25** | **2.55** | 2.21 | 2.72 | 3.4 | 3.06 |
| Thornling (5.4) | 5.94 | **3.78** | 4.86 | **5.94** | **5.4** | **5.94** | 4.86 |
| Stagrunner (7.8) | 8.58 | 5.46 | 7.02 | **8.58** | 7.8 | 8.58 | 7.02 |
Crossing a 12 m snowfield: Rimeshield 2.3 s, Shade 2.9 s, Thornling 3.2 s. Crossing a ford (7 m): Thornling 1.2 s, Shade
2.2 s, Rimeshield 2.6 s. A Flame Guard on ash hits for 13.2 (+10 % combat value there). In the forest a unit with sight 10 sees
7 m and an archer (sight 12, range 9) sees 8.4 m: ranged units lose their reach unless a friend sees.

## 4. Where terrain lies on Crown Hollow
### 4.1 How the map is built (priority, first match wins)
1. `water` (RiverSystem deep water) 2. `ford` (ford circles, Crown Steps) 3. `road` (ring segments 3 m, lane 5.2 m outside
r 11, bridge decks) 4. `riverbank` (within 3.0 m of deep water, outside r 11) 5. `mud` 6. `forest` 7. `snow` 8. `sand`
9. static `ash` 10. `grass`. Dynamic ash (section 6) is stamped over grass, forest, sand and static ash only (never snow,
riverbank, ford, marsh, road, water).
- Patches are ellipses `{center, size: Vector2(rx, rz)}` with a **1.0 m noisy edge**; the noise is point-symmetric
  (`0.5 x (n(p) + n(-p))`), so the grid is exactly mirrored.
- Clearances: a patch edge is >= **6 m** from crystal nodes, >= **3 m** from bot build slots (H1, V1-V3, S1, S2, X1, M1, R1,
  R2, T2, T3), keeps and taverns; it may touch capture circles, camps and lairs (on purpose: they are what the terrain is
  about). 12b.C1 may move a centre by <= 2 m (mirrored) to satisfy these; it reports any move.

### 4.2 The patches (player half; the mirror `(-x, -z)` gets the name in brackets)
| id | Name | Terrain | Centre | Size (rx, rz) | Bank / objective | Straight distance from the player keep `(-43, 43)` (own / mirror) |
|---|---|---|---|---|---|---|
| `snow_well_w` | Mossmere Frost (Stonemere Frost) | snow | `(-31, -24)` | 5.5 x 5.5 | Around Mossmere Well (its capture circle mostly inside) | 68 m / ~87 m by path via Millstone Bridge |
| `snow_falls_n` | Rimefall (Rimegorge) | snow | `(-22, -54)` | 7.0 x 4.5 | Under the north cliffs by the waterfall; around the Old Wood Den (Grizzlemaw lair), west of Saltgate Bridge | 99 m / **~67 m** by path (the mirror is nearer over Millstone Bridge: contested, like the far-corner towers) |
| `sand_tower_s` | Millwatch Terrace (Saltwatch Terrace) | sand | `(-8, 41)` | 6.0 x 5.0 | The home watchtower's old river terrace | 35 m / ~115 m |
| `sand_heath_w` | Heron Dunes (Lantern Dunes) | sand | `(-55, -11)` | 5.0 x 6.0 | West flank heath around the Fallen Colossus; the Roc's Colossus Crag | 55 m / ~113 m |
| `ash_scar_w` | West Cinder Scar (East Cinder Scar) | ash | `(-31, 2)` | 4.5 x 4.5 | Where a crown shard fell long ago; the Lost Cache `(-30, 0)` lies in it; between the West Wayshrine and the Stag Glade | 43 m / ~110 m |
| `mud_reed_w` | Reed Marsh (Willow Marsh) | mud | `(-14.5, -33)` | 3.0 x 3.0 | West approach of Reed Ford (player bank), 3.6 m from the water | 81 m |
| `mud_reed_e` | Reed Marsh (Willow Marsh) | mud | `(-2.5, -35)` | 3.0 x 3.0 | East approach of Reed Ford (enemy bank); its mirror `(2.5, 35)` is on the player bank at Willow Ford | - / 46 m |
| `forest_hollow_nw` | Gloomcap Thicket (x2) | forest | `(-54, -54)` | 6.0 x 6.0 | The Gloomcap Hollow nook (camp) | 97 m |
| `forest_wolf_nw` | Greymane Thicket | forest | `(-57, -33)` | 4.5 x 4.5 | The step-12 cluster `(-57, -32)`; Direwolf lair | 77 m |
| `forest_den_nw` | Den Thicket | forest | `(-30, -56)` | 4.5 x 4.5 | The step-12 cluster `(-30, -56)`, beside Rimefall (a snowy wood at the seam) | 100 m |
Roads, riverbank and fords follow the step-10 roads and the step-12 river (already mirrored). The Crown Isle (r < 11) is
open ground ("Crown Isle ruins"): the crown fight stays neutral.

### 4.3 Fairness per kingdom (both sides see the same map)
| Kingdom | Its good ground on its own bank | On the enemy bank / contested | Its bad ground |
|---|---|---|---|
| Ice | Own well's frost (~68 m) | Rimegorge on the enemy bank is ~67 m by path (contested); the enemy's well frost | Home tower terrace and heath dunes (sand) |
| Fire | Home tower terrace (35 m), Cinder Scar (43 m), heath dunes (55 m); random ash; its own scorch anywhere | The same on the other bank | none (base slows only) |
| Nature | Riverbank along both rivers and the moat ring (nearest ~43 m, the natural node side), Willow Marsh (46 m) and Willow Ford | Reed Ford, Reed Marsh; every crossing has riverbank on both ends | 4 snowfields (incl. around its well) |
| Shadow | - | - | - |
- The grid is point-symmetric cell by cell (test in 12b.C1). Every patch has a twin at the same path distance from the other
  keep (the step-12 mirror checks cover the objectives the patches sit on).
- Area (whole map, approx.): road ~1 640 m², riverbank ~900 m², fords 130 m², marsh 110 m², forest 480 m², snow 370 m²,
  sand 350 m², static ash 130 m² (about **28 %** of the 14 400 m² map; 72 % stays open ground). Random ash adds ~130 m² on
  average while the match runs (6.2).

## 5. Sampling (systems 12b.C1)
| Rule | Value |
|---|---|
| Grid | `PackedByteArray` 240 x 240 (0.5 m cells) over x, z in [-60, 60]; cell `(i, j)` covers `x = -60 + 0.5 i`; the mirror of `(i, j)` is `(239 - i, 239 - j)`. Two arrays: `_base` (static) and `_cur` (base + live dynamic ash) |
| Build | Once at match start, after the RiverSystem mask exists: stamp each shape only over its bounding box (roads per segment, patches per ellipse, riverbank = the water mask dilated by 6 cells). **<= 100 ms** total in GDScript |
| Lookup | `id_at(pos)` = one array read (outside the grid: `grass`) |
| Unit pass | Over the cached `"units"` list (refreshed every 2 s and on `node_added`), each physics frame samples `ceil(n / 15)` units: every unit is sampled **every 0.25 s** |
| Debounce | A unit switches terrain when **two consecutive samples** agree on a new id (0.25-0.5 s after crossing an edge). First sample after spawn / teleport applies at once |
| Apply | `remove_modifier("terrain:<old>")`, `add_modifier("terrain:<new>", effects)` (skipped for empty rows). Only on change: a unit crossing terrain every few seconds costs two stat recomputes |
| Ford ownership | With a TerrainSystem present, it applies `terrain:ford` (kingdom rows); RiverSystem stops writing it (`RiverSystem.ford_modifier_enabled = false`, a flag 12.L1 adds to the step-12 contract). Without one (missions), step 12 behaves as written |
| Signals | `unit_terrain_changed(unit, terrain, old)` (UI) |

## 6. Scorched ground (ash)
### 6.1 Static
The two Cinder Scars (4.2): always ash, from 0:00.

### 6.2 Random wildfires and lightning (Q3 "RNG")
| Rule | Value |
|---|---|
| Seed | The match rng (the one the Wayshrine coin flip uses, `map-fill.md` 4.4): the same seed gives the same events. Replays and bot runs are reproducible |
| Schedule | First event at **4:00** (after the rush window of `rush-balance.md`), then every **100-140 s** (uniform, seeded): ~8 events in a 20-minute game |
| Fairness | Every event hits a **mirrored pair**: spot `p` and `-p` at the same moment, same kind, same radius. Both sides always get exactly the same ash, at the same path distance from their keep |
| Spots | 11 candidate pairs (player half below; mirrors at `-p`). An event picks, with the seed, a pair not used in the last 3 events and not live now. At the moment of the warning a spot must be grass, sand or forest in the base grid (never snow, so Ice's ground is never randomly erased) and have no building within 6 m; else the next pair |
| Kinds (seeded, 60 / 40) | **Wildfire**: r **4.5**; 6 s of flames (units of every team inside take **5 damage / s**, not buildings, not flyers), then ash **90 s**. **Lightning strike**: r **2.5**; the bolt deals **30 damage** once to every unit inside (every team, heroes included, not buildings, not flyers), then ash **60 s** |
| Warning (readability) | **10 s** before: at both spots a ground ring at the final radius (orange for wildfire, pale blue-white for lightning) with a shrinking countdown arc, a smoke column (wildfire) or a dark cloud with flickers (lightning); a minimap ping at both spots for **both teams even under fog** (weather is public); message `Smoke rises: a wildfire will break out in 10 s` / `Storm clouds gather: lightning will strike in 10 s`; thunder rumble or crackle sound. The ground tooltip over the ring reads `Wildfire in 7 s` |
| Fade | The last 10 s of the ash fade visually; then the cells go back to their base terrain |
| Live cap | At most **2** random pairs live (a third waits); Fire's own scorch does not count |
| Fog | Events and their ash are public (drawn for both teams, on the minimap as a faint ash tint while live) |
Candidate spots (player half; each checked by 12b.C1 against the rules above, moved <= 2 m if needed):
| # | Spot | Where |
|---|---|---|
| R1 | `(-20, 35)` | Glade between the home tower terrace and the lane |
| R2 | `(-36, 18)` | West glade, off the w_door road |
| R3 | `(-25, 10)` | Midfield glade near the Cinder Scar |
| R4 | `(-40, -22)` | Heath west of Mossmere Frost |
| R5 | `(-22, -34)` | Between Rookwatch and Reed Marsh |
| R6 | `(-36, -56)` | Old Wood edge south of the Lodge |
| R7 | `(-54, -54)` | Gloomcap Thicket (a forest fire) |
| R8 | `(-55, -11)` | Heron Dunes (sand) |
| R9 | `(-8, 41)` | Millwatch Terrace (sand) |
| R10 | `(-12, 28)` | By the moved Lost Cache, west of Willow Ford |
| R11 | `(-42, 4)` | West heath below Heron Ford, off the w_door road |
Every spot is >= 22 m from a keep, >= 8 m from crystal nodes, taverns, peddlers and posts, off roads, riverbank and fords.
Expected value per side: identical (mirrored). Ash from random events: ~1 pair live on average, ~130 m² map-wide.

### 6.3 Fire's own fire (a Fire-only pro)
| Rule | Value |
|---|---|
| Sources | **Fireball** impact: ash r **2.5** (the blast is 3.5). **Ember Step** scorch: r 2.5 at the spot she left. **Cinder Dragon** burning-ground patch: r 2.0 (at most one per 2 s per dragon). **Flame Rites** death zone: r 2.0 (step 14). **Pyre Adept** Flame Burst: r 2.0 (step 16). Each caller: `TerrainSystem.add_scorch(pos, radius, team)` through the group `"terrain"`, load-guarded |
| Duration / cap | **25 s**; **8** live per team (a 9th removes that team's oldest) |
| Where | Over grass, forest, sand, static ash only (never snow, riverbank, ford, marsh, road, water) |
| Fog | The local ground texture shows it only once the local team saw one of its cells while it lived; never on the enemy's minimap |
Expected: Vessa casts a Fireball every ~10 s in a fight (40 mana, 4 / s regen): 2-4 ash patches under an ongoing melee.

## 7. Visuals (tech-artists 12b.V1-12b.V7; `art-keep.md` section 0: chunky, hand-painted, readable at 40 m)
### 7.1 Ground shader layers (12b.V1, `ground.gdshader`, after 12.V2)
| Uniform | Type | Meaning |
|---|---|---|
| `terrain_enabled` | bool, false | Off = today's ground (missions unchanged) |
| `terrain_mask` | sampler2D, linear, clamp | 240 x 240 RGBA8 from `TerrainSystem.mask_texture()`: **R snow, G sand, B ash (static + random + local-seen Fire scorch), A marsh**; riverbank and fords come from the 12.V2 river uniforms, roads from `road_segs`, forest from the 12.V2 Old Wood tint + 12b.V6 undergrowth |
| `terrain_origin`, `terrain_size` | vec2 (-60, -60), float 120 | World -> mask UV |
| `scorch_fresh` | vec4[8] (x, z, r, age 0-1) | The 8 newest dynamic patches for the glowing-crack "fresh" look |
| Layer | Look |
|---|---|
| Snow | Base `(0.90, 0.93, 0.98)`, shade `(0.62, 0.72, 0.88)`, 2-3 posterised drift steps from noise, soft wind streaks, tiny sun-facing sparkles; edges broken, grass tufts poke through; frost rim `(0.80, 0.88, 0.96)` |
| Sand | Light `(0.86, 0.74, 0.50)`, dark `(0.66, 0.52, 0.32)`, wind ripples (stripes ~0.9 m along `(0.8, 0.6)`), scattered pebbles; edges fade into `grass_dry` |
| Ash | Blotches `(0.20, 0.18, 0.17)` / `(0.34, 0.31, 0.29)`, a charred rim; ember specks `(1.0, 0.45, 0.12)` emission 0.6-1.2 flickering with TIME in ~1 of 40 cells; fresh ash: glowing orange cracks fading over 6 s |
| Marsh | Wet dark mud `(0.24, 0.18, 0.11)`, puddles tinted `(0.45, 0.52, 0.55)` with lower roughness, small pock marks |
| Rules | Roads and the river draw **over** terrain. One extra texture read per ground pixel; each layer's ALU runs only where its weight > 0.001. Defaults keep the material identical when `terrain_enabled` is false |

### 7.2 Decor sets (12b.V2-12b.V5, format of `map-fill.md` 10: `art/environment/biomes/<id>/<id>_set.gd`, no class dependency)
| Id | Set | Meshes (<= 2 new kinds each, 3 shape variants through the variant mask) | Instances | Extra |
|---|---|---|---|---|
| 12b.V2 | `snow` | Snow-capped rocks, frosted grass / small icicle shrub | 500 | none (sparkle is in the shader) |
| 12b.V3 | `sand` | Dry tussock grass, half-buried pale stones / old bones | 400 | none |
| 12b.V4 | `ash` | Charred stumps and burnt logs, blackened grass | 200 | Per static scar: 1 ember-mote `GPUParticles3D` (16, emissive quads, no light) + 1 thin smoke column (8) |
| 12b.V5 | `marsh` | Puddle decals (flat quads with the water material's shallow mode), cattails (reuse the 12.V7 reed if it fits) | 300 | none |
New `place` values: `&"snow"`, `&"sand"`, `&"ash"`, `&"marsh"` (inside the patch, mask weight > 0.5) and `&"<id>_edge"` (weight
0.2-0.5). Visibility range 65 m (small) / 90 m (stumps, rocks); no shadows except stumps and rocks. **Budget change**: map-fill's
cap of 24 decor mesh kinds becomes **32** (+8), total instances stay <= 12 000.

### 7.3 Event VFX, integration and icons
- **12b.V4 also**: `art/vfx/terrain_vfx.gd` (`class_name TerrainVfx`, group `"terrain_vfx"`, `play(id, at: Vector3, radius:
  float, seconds := 0.0)`), ids: `scorch_spawn` (smoke puff + ember burst, pooled <= 8), `wildfire_warning` (orange ring +
  countdown arc + rising smoke column, 10 s), `wildfire_burn` (low flame cards over the disc, 6 s, <= 40 quads, no light),
  `storm_warning` (pale ring + countdown arc + a small dark cloud at 12 m with flicker, 10 s), `lightning_strike` (bolt mesh
  0.25 s, white flash quad, dust ring). Emission only, no `OmniLight3D` (a lightning flash may pulse the existing sun energy
  +0.3 for 0.1 s if cheap). At most 2 pairs live = 4 effects.
- **12b.V6** (after 12.V6): `MapDressingArt` reads `TerrainSystem.patches()` / the mask and scatters the 4 sets; thickets get
  the Old Wood fern density x2; grass tufts thin out on snow, sand and ash. Random ash never moves decor (the shader does it).
- **12b.V7** icons (64 x 64, `art/icons/terrain_<id>.png`): road, riverbank, ford (reuse 12.V26 "wading" if done), marsh,
  forest, snow, sand, ash, wildfire, lightning; plus two 16 x 16 corner marks (green up-arrow = good for you, red down-arrow =
  bad).

## 8. UI (ui-coder 12b.C3; styles of `ui-style.md` 8: slate tooltip, frame_metal border, max width 320, margin 8)
| Element | Content | Interaction |
|---|---|---|
| **Ground tooltip** | Cursor on ground (no unit, building, point, camp or item under it), explored cell, still for **0.5 s** -> tooltip 12 px up-right of the cursor. Line 1: terrain name, `·` patch name (`Snow · Rimefall`). Line 2: your kingdom (`Your Ice units: +25 % speed`, `trim_glow` if good, `WARN` if bad, `text_muted` `No effect on your army`). Line 3 (only if the enemy kingdom's row differs): `Enemy Nature units: -30 % speed`. Line 4 muted: `Others: -15 % speed` (the base row; omitted when empty). Fords add `Workers: -35 % speed`. Over a warning ring: `Wildfire in 7 s` / `Lightning in 7 s` as line 1 | Hides on move > 8 px, on drag-select, while targeting a spell or placing a building |
| Effect text | From `TerrainSystem.describe(terrain, kingdom) -> String`: `+25 % speed`, `+10 % damage`, `heals 1 % HP / s out of combat`, `-30 % sight`, joined by `, ` | |
| **Unit panel** | Single unit: a 20 x 20 terrain chip in the status row (the step-12 wading icon generalised to every `terrain:*` modifier), rim green (net good), red (net bad), grey (mixed / forest); tooltip `Snow (Rimefall): +25 % speed` | Hover |
| **Event warnings** | Messages of 6.2 (both teams, `show_message`), minimap ping 2 s at both spots (orange / pale blue ring, visible under fog), sounds (SFX bus): distant crackle, thunder rumble, strike crack | |
| Minimap | Static patches tinted in the ground layer: snow `(0.88, 0.92, 0.98)`, sand `(0.85, 0.75, 0.50)`, ash `(0.25, 0.22, 0.20)`, marsh `(0.35, 0.28, 0.18)`, thickets `(0.12, 0.24, 0.12)`; live random ash in the ash tint; never Fire's own scorch | |
| Skirmish setup | One line on each kingdom card: Fire `Terrain: fast on sand, fierce on ash` · Ice `Terrain: fast on snow; slow on sand` · Nature `Terrain: fast in fords and on riverbanks, heals by the river; slow on snow` · Shadow `Terrain: no kingdom bonus or penalty` | |
| Hint | Once at 1:00: `Hover the ground to see how terrain affects your army` | |
| Help text | `Terrain: roads, fords, marsh, forest, snow, sand and ash change speed, damage or sight. Hover the ground to see how. Wildfires and lightning are announced 10 s ahead.` | |
| Settings | **Terrain tooltips: On / Off** (default On), in the existing settings store (`terrain_tooltips: bool`) | |
| End screen | nothing | |
No new keys.

## 9. The bot (ai-coder 12b.A1; knobs in `AIProfile` / `data/ai/*.tres`)
The bot knows the static terrain and the public events; Fire's scorch only where it saw it (as the player). Kingdom = its own.
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `terrain_route_weight` (0 = ignore terrain in route choice) | 0 | 1.0 | 1.0 |
| `terrain_spot_search` (rally / hold / defence spots) | false | true | true |
| `terrain_engage_bias` | 0 | 0.10 | 0.15 |
| `river_retreat` (Nature only) | false | true | true |
| `dodge_events` | false (units still walk out when idle, see 13g) | true | true |
| Rule | Behaviour |
|---|---|
| **Cost weight** | `TerrainSystem.cost_weight(terrain, kingdom) = 1 / (1 + move_speed_pct) x (1 - 1.5 x attack_damage_pct)`, `x 1.2` on forest when >= 40 % of the group is ranged. Examples: base ford 1.54, Nature ford 0.91, Ice snow 0.80, Nature snow 1.43, Ice sand 1.33, road 0.91, Fire ash 0.85, Fire sand 0.91 |
| **13c Route choice** (extends map-fill rule 13b) | At an attack launch the candidate routes (the lane over the isle when the wardens are dead, each road bridge, each ford whose nest is dead) are waypoint lists; `path_cost(points, kingdom)` samples every 2 m (sum of length x weight). The bot keeps its default route unless another is **>= 10 %** cheaper after rule 13b's tower danger factor |
| **13d Spots** | When picking a rally, staging (the 10 m bridge staging of `rush-balance.md` 3.3), creep staging or point-defence spot: score the spot and 8 candidates on a ring of 6 m by 9 samples each (centre + 8 at r 3): `sum(1 - weight) - 0.05 x metres moved`; take the best. Ice waits in the frost at its well, Fire on sand or ash, Nature on the riverbank |
| **13e Engage bias** | Before rule 7 attacks and 12b point defence: the seen enemy group's centroid on a cell bad for the enemy's kingdom or good for its own -> `attack_ratio x (1 - bias)`; on a cell bad for its own kingdom -> `x (1 + bias)`. Hard: defending within 12 m of own good ground, the group holds there up to 6 s so the attacker walks in. A Fire bot counts live ash as good ground (it likes fighting on fresh wildfire ash) |
| **13f River retreat (Nature)** | Rule 2 retreat target = the nearest own-bank riverbank cell within 25 m of the straight retreat line and >= 15 m from seen enemies; wait there until the group's average HP >= 70 % or 30 s (Riverside mending), then back to the rally |
| **13g Event dodge** | On a warning, own units inside the ring + 1 m (normal / hard: also those in combat, except the wizard mid-cast) move to the nearest point 2 m outside it, then resume their order. Easy: only idle units. Players' units do nothing on their own (the warning is for the player) |
| Unchanged | Creep rules, scout loop, casting rules (Vessa does not "paint" ash on purpose), build slots, worker behaviour |
Cost: route evaluation <= 5 routes x 80 samples at a launch; spot scoring <= 81 lookups per decision; the dodge is one pass over
own units per event: nothing per frame.

## 10. Performance (200 units + step 12 + this must keep `PERF OK`)
| Part | Budget |
|---|---|
| Grid build | <= 100 ms at match start (bounding boxes only) |
| Unit pass | < **0.05 ms / frame** average: ~13 array reads per frame for 200 units; a modifier change (2 recomputes) only on a terrain change |
| Dynamic ash | Stamp / restore over the patch's bounding box (<= 20 x 20 cells for a wildfire); mask texture `update()` at most 4 times / s, only when dirty (240 x 240 RGBA8 = 230 KB) |
| Events | Scheduler checks once per second; wildfire damage at 2 Hz over the units within r 4.5 of 2 spots (reads the cached list), lightning one pass: < 0.01 ms / frame |
| Shader | One more texture read per ground pixel, layers skipped where weights are 0: rendered frame over Rimefall and a Cinder Scar <= **+5 %** vs the step-12 build (windowed 1600 x 900 check of `map-fill.md` 9) |
| Decor / VFX | +1 400 instances inside the 12 000 cap, +8 mesh kinds (32 total), 4 particle emitters (static scars), scorch VFX pooled <= 8, event VFX <= 4 live |
| Perf test | Adds the TerrainSystem with all patches, 16 live Fire scorches and 2 live random pairs; stuck count 0 |

## 11. Balance
### 11.1 What terrain does to the kingdoms (combat value only inside patches; outside nothing)
| Kingdom | Gains | Loses | Net before compensation |
|---|---|---|---|
| Fire (strongest today) | +10 % speed on sand (home tower, heath), +10 % damage on ash (scars, ~8 random wildfires / strikes, its own scorch) | nothing beyond the base slows | **+2 to +4 %** game-wide combat value |
| Ice (weakest today) | +25 % speed on snow at both wells and under the cliffs: fastest army there, can catch and escape | -25 % speed on sand | ~+1 % |
| Nature | +10 % speed on riverbanks and fords, no marsh slow, mending by the river | -30 % speed on snow | ~+1 % |
| Shadow | - | - | 0 |
Estimate: fights on a patch are ~20-30 % of a game's fights; random events move the fight ~10 % of the time (units dodge or
lure). Fire's gain is worth ~2-4 win points vs each other kingdom before compensation. Wildfire / lightning damage hits every
team alike (Fire included). Match length: roads +10 % shave ~2 s off each keep-to-keep trip, slows elsewhere add about as much:
**+0:00 +- 0:30**.

### 11.2 Compensation (Q2: make the others stronger, never nerf Fire)
| Part | Value | How |
|---|---|---|
| Ice terrain | Snow **+25 %** speed (was +20 in the draft) | `EFFECTS` |
| Nature terrain | Riverside mending, ford +10 %, riverbank +10 %, no marsh slow | `EFFECTS` |
| **Kingdom HP (`kingdom:hardy`)** | Modifier `{"max_hp_pct": X}` on every **soldier and titan** of the kingdom (not workers, caravans, wizards, champions, summons, and **not `swarm` rush units**: `rush-balance.md` 12.2 forbids HP knobs on them). Start: **Shadow +0.04, Ice +0.03, Nature +0.03, Fire 0** | `Unit.KINGDOM_HP_PCT` (gameplay, 12b.C2), applied once at spawn like the wares |
| Why these starts | Shadow gets nothing from terrain, so the most HP; Ice and Nature get some terrain value back. +4 % HP = +4 % combat value (EHP x DPS) for that kingdom's army | |
| Interplay | `kingdom:hardy` is a new, separate knob next to `rush-balance.md` section 12 (step 16 may fold it into its own ladder). It stacks with veterancy, research, wares like any source | |
### 11.3 Knobs (one at a time, 12b.D2; kept inside the `rush-balance.md` 45-55 % targets; **Fire is never nerfed**)
| Symptom (vs the `--no-terrain` control) | Knob |
|---|---|
| Fire > 55 % vs Shadow | Shadow `kingdom:hardy` +0.04 -> **+0.07** -> **+0.10** (cap +0.12) |
| Fire > 55 % vs Ice | Ice snow +25 -> **+30 %**; then Ice `kingdom:hardy` +0.03 -> **+0.06** -> +0.09; then "Frost ground": Flash Freeze leaves snow r 3 for 15 s |
| Fire > 55 % vs Nature | Nature `kingdom:hardy` +0.03 -> **+0.06**; then mending 1.0 -> **1.5 %**; then riverbank band 3 -> **4 m** |
| A buffed kingdom now > 55 % vs a non-Fire kingdom | Lower that kingdom's `kingdom:hardy` by 0.02 (not below its start) before touching anything else |
| Nature dominates crossing fights | Ford +10 -> **0 %** (and give the value back as `kingdom:hardy` +0.02) |
| Games shorter by > 1:00 | Road +10 -> **+5 %** |
| Random events decide games (a strike kills a wizard or many units often) | Lightning 30 -> **20** damage; wildfire flames 5 -> **3** / s; warning 10 -> **12 s** |
| Random events unnoticed | Ash duration 90 / 60 -> **120 / 90 s**; interval 100-140 -> **80-110 s** |
| Terrain unnoticed in the playtest | Every patch +1 m; ground tooltip delay 0.5 -> 0.3 s |
| Bot route dithering | Route hysteresis 10 -> **20 %** |
### 11.4 Re-test plan (lead 12b.L2 when the big test pass runs; harness of `map-fill.md` 12.4 + flag `--no-terrain`)
| Round | Pairs (both orders) | Runs | Pass |
|---|---|---|---|
| A | fire-ice, fire-nature, fire-shadow, ice-nature, shadow-ice, shadow-nature | 2 with terrain + 1 `--no-terrain` each = 36 | Fire's share vs each kingdom does **not rise** vs the control (the compensation holds); no pair moves by more than **10** win points; median length within 14:00-22:00 |
| B | ice-ice, nature-nature, fire-fire | 2 each | Crystals and essence within **1.1x** at 10:00 (side bias); the same seed gives the same events on both sides |
| C | logs | - | Per game: each kingdom's units spend 5-25 % of their moving time on a patch; >= 6 random events by 15:00; units killed by events <= 3 % of all deaths; >= 1 bot route or spot changed by terrain per game (normal); 0 script errors |
| Perf | perf test + terrain | 1 | `PERF OK`, stuck 0 |

## 12. Campaign
`terrain_enabled` and `terrain_events_enabled` (skirmish **true**, missions **false**). `TerrainSystem.setup(patches, ...)` and
`set_event_spots(...)` work with any map: a later Ice mission can lay a snow valley, a Fire mission a storm of wildfires.
Missions 1-4 unchanged.

## 13. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 12b.L1)
Rule for 12b agents (as step 12): never use another 12b agent's new `class_name` as a static type; reach it through the group
`"terrain"`, `has_method()`, `call()`, load-guarded.
- **TerrainSystem** (`scripts/world/terrain_system.gd`, `class_name TerrainSystem extends Node`, group `"terrain"`, `static func
  instance(tree: SceneTree) -> TerrainSystem`): `TERRAIN_IDS: Array[StringName] = [&"grass", &"road", &"riverbank", &"ford",
  &"mud", &"forest", &"snow", &"sand", &"ash", &"water"]` (index = byte value), `CELL := 0.5`, `SIZE := 240`,
  `SCORCH_TIME := 25.0`, `SCORCH_CAP := 8`, `EVENT_FIRST := 240.0`, `EVENT_INTERVAL := Vector2(100, 140)`, `EVENT_WARNING :=
  10.0`, `EVENT_KINDS := {&"wildfire": {"radius": 4.5, "burn": 6.0, "burn_dps": 5.0, "ash": 90.0, "weight": 0.6},
  &"lightning": {"radius": 2.5, "strike": 30.0, "ash": 60.0, "weight": 0.4}}`, `EVENT_LIVE_CAP := 2`,
  `setup(patches: Array[Dictionary], river: Node, roads: Array)` (patch `{id, name, terrain, center: Vector3, size: Vector2}`;
  roads = `[[a: Vector3, b: Vector3, width]]`), `set_event_spots(spots: Array[Vector3], rng: RandomNumberGenerator)` (player
  half; mirrors generated), `terrain_at(pos) -> StringName`, `id_at(pos) -> int`, `name_at(pos) -> String`,
  `current_terrain(unit) -> StringName`, `kingdom_of(unit) -> StringName` (`&"fire"`, `&"ice"`, `&"nature"` or `&"default"`),
  `effects_for(terrain, kingdom) -> Dictionary`, `describe(terrain, kingdom) -> String`, `cost_weight(terrain, kingdom) ->
  float`, `path_cost(points: PackedVector3Array, kingdom) -> float`, `area_score(center: Vector3, radius: float, kingdom) ->
  float`, `add_scorch(pos: Vector3, radius: float, team: int) -> int`, `scorch_count(team) -> int`, `next_event() -> Dictionary`
  (`{time, kind}` once warned, else `{}`), `live_events() -> Array[Dictionary]` (`{kind, spots: Array[Vector3], radius,
  state: &"warning" / &"burning" / &"ash", time_left}`), `patches() -> Array[Dictionary]`, `mask_texture() -> Texture2D`,
  `shader_params() -> Dictionary`, signals `unit_terrain_changed(unit, terrain: StringName, old: StringName)`,
  `scorch_added(id: int, pos: Vector3, radius: float)`, `scorch_expired(id: int)`, `event_warning(kind: StringName, spots:
  Array, seconds: float)`, `event_started(kind: StringName, spots: Array)`, `event_ended(kind: StringName, spots: Array)`.
  Event damage: `take_damage(amount, null)` on Units (every team, not flyers), credited to nobody. `EFFECTS`:
  `{&"road": {&"default": {"move_speed_pct": 0.10}}, &"riverbank": {&"default": {}, &"nature": {"move_speed_pct": 0.10,
  "idle_regen_pct": 1.0}}, &"ford": {&"default": {"move_speed_pct": -0.35}, &"nature": {"move_speed_pct": 0.10,
  "idle_regen_pct": 1.0}}, &"mud": {&"default": {"move_speed_pct": -0.20}, &"nature": {"idle_regen_pct": 1.0}}, &"forest":
  {&"default": {"move_speed_pct": -0.10, "sight_scale": -0.30}}, &"snow": {&"default": {"move_speed_pct": -0.15}, &"ice":
  {"move_speed_pct": 0.25}, &"nature": {"move_speed_pct": -0.30}}, &"sand": {&"default": {"move_speed_pct": -0.10}, &"fire":
  {"move_speed_pct": 0.10}, &"ice": {"move_speed_pct": -0.25}}, &"ash": {&"default": {}, &"fire": {"attack_damage_pct":
  0.10}}}`; workers / caravans get `{&"ford": {"move_speed_pct": -0.35}}` only; amphibious units treat ford and mud as grass;
  flyers get nothing.
- **Unit / Stats**: new stats `idle_regen_pct` (base `UnitType.idle_regen_pct`; `set_idle_regen_pct` sets the base; the idle
  regen tick reads the stat) and `sight_scale` (flat, default 0). Modifier ids `terrain:<id>`, one at a time, owned by
  TerrainSystem. **`Unit.KINGDOM_HP_PCT := {&"fire": 0.0, &"shadow": 0.04, &"ice": 0.03, &"nature": 0.03}`**, applied at spawn
  as modifier `kingdom:hardy` `{"max_hp_pct": X}` to soldiers and titans only (not `swarm`, workers, caravans, wizards,
  champions, summons); a skirmish flag `kingdom_hp_enabled := true` (missions false) turns it off.
- **FogOfWar**: `sight_of(unit)` and the `"fog_sources"` Unit stamp multiply by `clampf(1.0 + unit.get_stat(&"sight_scale"),
  0.5, 1.5)`.
- **RiverSystem** (step-12 contract, 12.L1 adds it): `var ford_modifier_enabled := true`; TerrainSystem sets it false.
- **Scorch callers** (gameplay): Fireball impact, Ember Step, Cinder Dragon burning ground (step 13), Flame Rites zone (step
  14), Pyre Adept Flame Burst (step 16) call `add_scorch` through the group when the node exists.
- **Skirmish**: `@export var terrain_enabled := true`, `terrain_events_enabled := true`, `kingdom_hp_enabled := true`, `const
  TERRAIN_PATCHES` (section 4.2) and `TERRAIN_EVENT_SPOTS` (6.2), player half, mirrors generated; `var terrain`; created
  (load-guarded) after the RiverSystem, before the first unit spawns; events seeded from the match rng.
- **EnvProps**: `set_terrain(mat: ShaderMaterial, params: Dictionary) -> bool` (no-op when the shader lacks the uniforms).
- **Settings**: `terrain_tooltips: bool` (default true).
- **AIProfile**: `terrain_route_weight`, `terrain_spot_search`, `terrain_engage_bias`, `river_retreat`, `dodge_events`
  (section 9).
- **Ownership**: `scripts/world/terrain_system.gd` = systems; `scripts/ai/ai_terrain.gd` = ai; `scripts/ui/terrain_tooltip.gd` =
  ui; `art/environment/biomes/{snow,sand,ash,marsh}/`, `art/vfx/terrain_*`, `art/icons/terrain_*` = tech-artist. No `Events`
  change (the TerrainSystem signals carry the events).

## 14. What changes in other specs (12b.D2 writes the lines after the build)
- `map-fill.md`: `terrain:ford` is applied by TerrainSystem with kingdom rows (Nature +10 %), RiverSystem flag; decor cap
  24 -> 32 kinds; the wading icon becomes the terrain chip; ground shader uniforms of 7.1 next to 12.V2's.
- `kingdom-ice.md` / `kingdom-nature.md` / `units-fire-shadow.md`: one "Terrain" line in the identity table (section 3.1) and
  the `kingdom:hardy` HP line (11.2).
- `research.md`: the `idle_regen_pct` stat hook is shared (built by whichever step lands first); Riverside mending is the only
  army regen outside the Treant, and only out of combat on wet ground (Q1).
- `rush-balance.md`: section 12 gains the `kingdom:hardy` knob (never on `swarm` units); 3.3 road times -~10 %; the first
  random event is after the rush window (4:00).
- `cavalry-mounts.md`: flyers ignore terrain and events; the dragon's burning ground scorches. `spells.md`: Fireball and Ember
  Step leave ash 25 s. `fog-of-war.md`: `sight_scale`; weather events public. `ai.md`: rules 13c-13g. `ui-hud.md`: ground
  tooltip, event messages, setting.

## 15. Task list (step 12b; build with / after step 12)
**Phase 0:** 12b.L1. **Phase 1:** 12b.C1, 12b.C2, 12b.V2-12b.V5, 12b.V7 (no shared files). **Phase 2 (after their step-12
twins):** 12b.V1 (after 12.V2), 12b.V6 (after 12.V6), 12b.C3 (after 12.C6 / 12.C7), 12b.A1 (after 12.A1). **Then** 12b.L2,
12b.D2 after the playtest. Phase-1 tests stub the others in `tests/test_12b_<id>.gd`.
**Shared files** (schedule, never two agents at once): `skirmish.gd`, `env_props.gd` (12.C1, 12.C8, 12.L2 glue); `river_system.gd`
(untouched thanks to the 12.L1 flag); `ground.gdshader`, `ground_material.tres` (12.V2); `map_dressing_art.gd` (12.V6);
`selection_panel.gd`, `minimap.gd`, `hud.gd`, `menus/game_settings.gd` (12.C6, 12.C7); `commander.gd`, `ai_profile.gd`,
`data/ai/*.tres`, `ai_mapfill.gd` (12.A1); `unit.gd` (steps 13, 14 and 16 also edit it); `fog_of_war.gd` (free in step 12).
| Id | Agent | Task | Files | After |
|---|---|---|---|---|
| 12b.L1 | lead | Freeze section 13 in `CLAUDE.md` ("Terrain" bullet), the RiverSystem flag in the step-12 contract, owner rows, ids in `waves.md` | `CLAUDE.md`, `docs/plan/` | - |
| 12b.C1 | systems-coder-high [H] | TerrainSystem: grid build (priorities, ellipses, symmetric noise, riverbank dilation, roads + lane + decks), lookups, 4 Hz staggered pass with debounce, kingdom rows and exemptions, ford takeover, Fire scorch (API, cap, expiry, allowed cells, local-seen mask), **random events** (seeded schedule, mirrored pairs, spot rules, warning / burn / strike / ash states, damage, live cap, signals), mask texture + shader params, `path_cost` / `cost_weight` / `area_score` / `describe`; FogOfWar `sight_scale`; Skirmish patches, event spots and flags; EnvProps `set_terrain` | `scripts/world/terrain_system.gd` (new), `skirmish.gd`, `env_props.gd`, `fog_of_war.gd` | 12.C1 (skirmish / env_props), not beside 12.C8 |
| 12b.C2 | gameplay-coder | `idle_regen_pct` and `sight_scale` Stats stats; **`KINGDOM_HP_PCT` + `kingdom:hardy`** at spawn (soldiers and titans, not `swarm`); scorch calls from Fireball impact and Ember Step (the dragon / Flame Rites / Pyre Adept hooks if those files exist, else a line in `docs/handoff/for-gameplay.md` for steps 13 / 14 / 16) | `scripts/units/unit.gd`, `scripts/spells/` (Fireball, Ember Step) | whichever unit.gd task runs |
| 12b.C3 | ui-coder | Ground tooltip (incl. event countdown), unit panel terrain chip, event messages + minimap pings + sounds, minimap tints, kingdom card lines, hint, help text, setting | `scripts/ui/terrain_tooltip.gd` (new), `selection_panel.gd`, `minimap.gd`, `hud.gd`, `menus/game_settings.gd`, the skirmish setup menu, `assets/audio/terrain_*` | 12.C6, 12.C7 |
| 12b.A1 | ai-coder | Rules 13c-13g, knobs in the four kingdoms' profiles (3 difficulties) | `scripts/ai/ai_terrain.gd` (new), `commander.gd`, `ai_profile.gd`, `data/ai/*.tres`, `ai_mapfill.gd` | 12.A1 |
| 12b.V1 | tech-artist | Ground shader terrain layers (7.1) + preview screenshot per layer | `art/environment/ground.gdshader`, `ground_material.tres` | 12.V2 |
| 12b.V2 | tech-artist | Snow set | `art/environment/biomes/snow/` | - |
| 12b.V3 | tech-artist | Sand set | `art/environment/biomes/sand/` | - |
| 12b.V4 | tech-artist | Ash set, static-scar particles, `TerrainVfx` (scorch, wildfire warning / burn, storm warning, lightning strike) | `art/environment/biomes/ash/`, `art/vfx/terrain_vfx.gd`, `art/vfx/terrain_*` | - |
| 12b.V5 | tech-artist | Marsh set | `art/environment/biomes/marsh/` | - |
| 12b.V6 | tech-artist | Dressing integration (7.3), thicket undergrowth, tuft thinning | `art/environment/map_dressing_art.gd` | 12.V6 |
| 12b.V7 | tech-artist | Terrain and event icons (7.3) | `art/icons/terrain_*` (new files only) | - |
| 12b.L2 | lead | Glue (TerrainVfx in the skirmish scene, handoffs), `--no-terrain` (turns off terrain, events and `kingdom:hardy`), perf test additions, the runs of 11.4 at the big test pass | `tests/`, `scenes/`, `docs/plan/` | all above |
| 12b.D2 | game-designer | Balance from the 12b.L2 logs and the playtest (knobs 11.3, compensation 11.2) | `docs/design/terrain.md` | 12b.L2 |

## Done when
- [ ] 12b.L1: section 13 in `CLAUDE.md`; `RiverSystem.ford_modifier_enabled` in the step-12 contract; owner rows; ids in `waves.md`.
- [ ] 12b.C1: `terrain_at` gives snow at `(-31, -24)` and `(31, 24)`, snow at `(-22, -54)`, sand at `(-8, 41)` and `(-55, -11)`,
  ash at `(-31, 2)`, mud at `(-14.5, -33)` and `(2.5, 35)`, ford at `(-8.5, -34)`, forest at `(-54, -54)`, riverbank at
  `(-13.5, -40)`, road at `(-48.5, -20)` and `(-20, 20)` (lane), grass at `(0, 0)` (isle) and `(-20, 35)`; every cell equals its
  mirror cell; the grid builds in <= 100 ms. A Rimeshield on snow moves at 5.25, a Shade at 4.08, a Thornling at 3.78; a Flame
  Guard on sand 5.5 and on ash hits 13.2, in a ford 3.25 and hits 12; a Thornling in a ford 5.94; a Rimeshield on sand 3.15; a
  worker in snow 4.6 and in a ford x0.65; a Mirefang in a ford at full speed; the dragon unaffected. The modifier appears within
  0.5 s of entering and leaves within 0.5 s of leaving; `terrain:ford` is written once (not by RiverSystem). A Fireball at
  `(-25, 10)` makes ash r 2.5 for 25 s; none on snow / riverbank / ford / marsh / road; the 9th scorch of a team removes its
  oldest; a scorch the local team never saw is not in its texture. Random events: first warning at 3:50, event at 4:00, then
  every 100-140 s; each event hits `p` and `-p` together with the same kind; the warning signal fires 10 s before; a wildfire
  deals 5 / s for 6 s to units of every team inside r 4.5 and leaves ash 90 s; a lightning strike deals 30 once inside r 2.5
  and leaves ash 60 s; buildings and flyers are never hurt; <= 2 pairs live; never on snow or next to a building; the same seed
  gives the same event list. A unit with sight 10 in the forest stamps 7 m. `terrain_enabled = false` gives step 12's map and
  ford rule; smoke test `victory=true`; `PERF OK`.
- [ ] 12b.C2: `get_stat(&"idle_regen_pct")` = UnitType value + modifiers; a Thornling at 20 / 75 HP on a riverbank regains
  0.75 HP / s after 4 s without damage and nothing while hit; `sight_scale` reads 0 by default; a new Shade has `max_hp` x1.04,
  a Rimeshield x1.03, a Flame Guard x1.00, a `swarm` unit, worker, wizard or champion x1.00; `kingdom_hp_enabled = false`
  removes it; Fireball and Ember Step call `add_scorch`; missing hooks are listed in the handoff file.
- [ ] 12b.C3: the tooltip shows the four lines of section 8 for the local kingdom and the enemy's (and the event countdown over
  a ring), hides as listed, respects the setting and fog; event messages, pings (under fog too) and sounds; the unit chip
  matches the unit's `terrain:*` modifier; minimap tints; kingdom card lines; nothing in `scripts/ui/` calls a `_private`
  function.
- [ ] 12b.A1: normal Nature bot takes a cleared ford when it is >= 10 % cheaper and retreats to the riverbank and waits until
  70 % HP or 30 s; an Ice bot's well-defence spot is inside the frost; normal / hard units walk out of a warning ring before
  the strike (a test strike on a bot group hits nobody); easy ignores terrain; `PERF OK`.
- [ ] 12b.V1-12b.V7: each follows section 7 and `art-keep.md` 0; a preview per task in `docs/art/screens/terrain_<id>.png`
  (12b.V4 also the warning / burn / strike sequence); headless instantiation without errors; decor <= 12 000 instances and
  <= 32 kinds with everything on; `terrain_enabled = false` renders the ground exactly as before.
- [ ] 12b.L2: the rounds of 11.4 pass; CI green; windowed frame check <= +5 %.
- [ ] 12b.D2: knob changes and results written in section 11.

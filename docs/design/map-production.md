# Map production: how many maps, how we make them fast, and the first batch

Owner: map / level designer + tools planner. Written 2026-10-02. Status: **design only, nothing here is built.**
Recommended option taken everywhere (JS: no questions).

User request (JS, 2026-10-02, verbatim): "more map and should be ez the make for map i will let u figure the number and
technique to get here" (earlier: "should we make a map editor if want 30 map +").

Builds on: `tools/world_forge/README.md` 2 (the `.map` text format, `forge_map.gd`, `forge_map_level.gd`),
`docs/plan/map-lab.md` (Map Lab v1 + U5), `data/maps/*.map` (Crown Hollow, Fourfold Hollow, Kinhearth Vale, Gloamspine
Divide), `map-2v2.md`, `map-2v2-audit.md`, `new-maps.md`, `map-fill.md`, `terrain.md`, `skirmish-1v1.md`,
`fog-of-war.md`, `campaign-outline.md`, `mission-00` .. `mission-04`, `mission-e2-01`, `mission-e3-01`,
`episode7-opening.md` 7 (`two_harbours`). Metres, `(x, z)`, `+x` east, `+z` south. Every name here is our own.

## 0. The answers in plain words
- **How many maps?** **40 maps for version 1.0**, plus 17 cheap **mission variants** (night, winter, the past, a smaller
  part of a map) built on top of them. Split: **13 campaign-only** maps, **12 1v1**, **8 2v2**, **4 four-player FFA**
  (also playable with 3), **3 special** (arena, survival, sandbox). The 33 campaign missions (36 to build) need only
  **14 new maps**. Every other mission reuses a map or a variant of one (section 1.2).
- **How do we make them easily?** No big visual editor. Maps stay **text files** (`.map`), built from a **template
  library** (a base, a river, a choke, the crown isle, camp patterns...). For skirmish maps a **generator** writes the
  file from `seed + archetype + biome + player count`. The **Map Lab** checks every candidate (symmetry, fair paths,
  resources, chokes). An **auto-fix loop** moves spots up to 5 m until it passes, and a **contact sheet PNG** shows the
  best 3 for a pick. The one missing piece today is the **runtime that plays any `.map`**. Today only Crown Hollow and
  mission 1 are playable, both hand-built in code. It is tool task MT2, and it comes first.
- **Map editor?** **Not now.** Agents write text, and an editor helps only a human. It would cost ~30-40 agent-hours plus
  upkeep, against ~6 for an **in-game tweak overlay** (drag a spot, save the `.map`). The overlay is built only if JS
  wants to move things himself, or if batch 1 shows that text iteration is the slow step (section 2.7).
- **Effort:** tools ~65 agent-hours, done once. Then ~5-6 agent-hours per skirmish map (generated or from templates,
  dressed, checked by bots) and ~1-1.5 h per mission variant. All 40 maps + 17 variants + 9 biome kits come to
  **~370 agent-hours** (Opus 5.5 medium). Campaign-outline 5.2 already counts ~150 of them, so **this plan adds ~220**.
  **First batch: 10 maps + the tools, ~140 agent-hours, 3-4 lead sessions at up to 6 agents.**

## 1. Inventory
### 1.1 What exists today (2026-10-02)
| Map | Mode | File / source | State |
|---|---|---|---|
| **Crown Hollow** | 1v1 skirmish (also m04, e6m4, e8m1_fire) | `scenes/skirmish.tscn` (`skirmish.gd` + `main.gd` generator, constants in code); exported to `data/maps/crown_hollow.map` (round trip 0.000 m) | **Playable**; Map Lab WARN 98 (live), World Forge PASS 100 |
| **Emberfall** | campaign m01 (also m00) | `missions/mission_01.tscn`, `main.gd` generator `MAP_SEED 1101`, positions as constants | **Playable** |
| **Fourfold Hollow** | 2v2 (golden autumn) | `data/maps/fourfold_hollow.map` + `_layout.tres` | Layout only (World Forge PASS 100, ally-keeps pass done); **no scene**: `scenes/skirmish_2v2.tscn`, `MapInfo`, step 20 not built |
| **Kinhearth Vale** | 2v2 (Nature look) | `data/maps/kinhearth_vale.map` | Layout only (WARN 97 / Map Lab 90) |
| **Gloamspine Divide** | 2v2 (Shadow look) | `data/maps/gloamspine_divide.map` | Layout only (PASS 100 / Map Lab 93) |
| Cinderstep Gorge, Thawmere Reach | 1v1 | drafts in `new-maps.md` 4.1 / 4.2 (no file yet) | Spec only |
| Three Rills, Mirewatch Caldera, Frostfang Pocket, Emberwater Cross | 1v1 / 2v2 | concepts in `new-maps.md` 2-3 (not picked) | Concept |
| Two Harbours (+ duel) | 2v2 / 1v1, Ep7 | draft in `episode7-opening.md` 7 | Draft |
| Glasswater Mere, Sighing Wood | m02 / m03 | `main.gd` generator seeds 1202 / 1303 (specs) | Spec |
| Evenmead | e3m1 / e4m1 | `mission-e3-01.md` Map table, set `forge_evenmead` (terrain, river, hills) | Spec + cinematic set |

What blocks every new map is the engine, not the layouts. Size is hard-coded to 120 m in fog (`map_half = 60.0`), the
BuildGrid, the river mask and the minimap; there is no `MapInfo` and no level that builds itself from a `MapLayout`
(`new-maps.md` NM.C1 and `map-2v2.md` 5 propose both; neither is built). The `.map` preview is flat ground: it has no
heights, forest or cliffs.

### 1.2 What the campaign needs (36 missions to build, 33 per playthrough)
Code: **B** built, **R** reuse a map as it is (with a mission overlay of marks and triggers), **V** variant of a base map
(overlay plus bounds, light, biome or dressing changes, and a few spots moved; same navmesh skeleton), **N** new map.
| Mission | Map in the outline | Code | Base map | What the variant / overlay changes |
|---|---|---|---|---|
| m00 Night of Knives | Emberfall at night, M1 corner | V | Emberfall | bounds `(-58,8)-(-8,58)`, night light, sight x0.6 |
| m01 Crown in the Ashes | Emberfall | B | Emberfall | - (adopted by `export-map`, must stay identical) |
| m02 Orb Beneath the Ice | Glasswater Mere | N | **Glasswater Mere** | - |
| m03 Signet in the Sighing Wood | Sighing Wood | N | **Sighing Wood** | - |
| m04 The Hollow Throne | Crown Hollow at war | R | Crown Hollow | pylons, Hollow overlay, river on |
| e2m1 Burning Grove | Sighing Wood burnt + frozen | V | Sighing Wood | burnt/frozen biome, Heartwood clearing, 2 enemy entries |
| e2m2 Roots and Embers | 2v2 map | R | Fourfold Hollow | 3 groves, Rime outpost, seat activation |
| e2m3 The Salt Road | trade map | N | **Salt Road** | - |
| e2m4 Sunrise Road | the deep under Emberfall | N | **Emberdeep Halls** | - |
| e2m5 The Light Below | Deep Door cavern | N | **The Deep Door** | - |
| e3m1 Take the Ford | Evenmead (north seat) | N | **Evenmead** | - |
| e3m2 Another Night | Fire-Nature camp behind Lark Hill, night | V | Evenmead | south half only, night, wagons, no base |
| e3m3 The Stone's Price | Malrik's crypt city | N | **Gravenhold** | - |
| e3m4 Storm on the Ridge | Evenmead ridge after the battle | V | Evenmead | scorched dressing, 3 hold points |
| e4m1 Hold Lark Hill | Evenmead (south seat) | R | Evenmead | player at the south seat |
| e4m2 The Green Road | Evenmead's western woods | N | **Larkwood Road** | - |
| e4m3 The Frozen Ashes | Sighing Wood burnt + frozen | V | Sighing Wood | e2m1's look, 5 regrowth groves |
| e4m4 Winter's End | Torvald's frontier, ice wall | N | **Hundred Winters** | - |
| e5m1 The First Spark | the citadel's south valley | N | **Brightvale** | - |
| e5m2 Burn a Door | raider fort, south border | V | Brightvale | bounds moved south, raider fort block |
| e5m3 Tombstones by Candlelight | a graveyard town | V | Gravenhold | the town before it became a crypt city; shadow zones |
| e5m4 Leftovers | the Master's practice field (mirrored) | N | **Orrery Green** (also a 1v1 skirmish map) | - |
| e6m1 A Hundred Winters | Glasswater Mere, decades ago | V | Glasswater Mere | no dig camp, 3 winters |
| e6m2 The Rider at the Gate | Torvald's ice gate and town | V | Hundred Winters | the gate section, town beyond |
| e6m3 The Year Nothing Grew | Evenmead, famine winter | V | Evenmead | winter biome, 4 seed-gardens |
| e6m4 The First Crack | Crown Hollow, twelve years ago | V | Crown Hollow | no bases on the far bank, amber cracks |
| e7m1 The Dragon Auction | `two_harbours` north shore | N | **Two Harbours** (also 2v2 skirmish) | - |
| e7m2 First Blood, No Further | the Tollrock arena island | V | Two Harbours | centre bounds, arena ring |
| e7m3 The Outwall | Adamarch's Outwall quarter | N | **Adamarch Outwall** | - |
| e7m4 The Year of Two Skies | `two_harbours` full strait | R | Two Harbours | side switch marks |
| e8m1_fire The Spark Waits | Hollowmere west bank | V | Crown Hollow | west bank only, 14:00 hold line |
| e8m1_shadow Put Down the Shovel | Malrik's crypt | V | Gravenhold | deep crypt, Hush boss room |
| e8m1_ice The Gate Opens | ice gate, refugee road south | V | Hundred Winters | gate open, escort route |
| e8m1_nature Take a Side | Ysolde's borders, root walls | V | Sighing Wood | spring regrowth, 3 root-walls (blocks) |
| e8m2 The Last Muster | Crown Hollow, 4 seats | V | Fourfold Hollow | war-torn biome, 4 keyholes, Hollow gates |
| e8m3 The Hollow King | the Hollow pit | N | **The Hollow Pit** | - |
**Totals: 1 B, 4 R, 17 V, 14 N.** 14 new base maps; 2 of them (Two Harbours, Orrery Green) also ship as skirmish maps.
So the campaign needs **13 campaign-only base maps** (Emberfall + 12 new) + 3 skirmish maps it borrows (Crown Hollow,
Fourfold Hollow, Two Harbours).

### 1.3 The recommended total: 40 maps (+17 mission variants)
| Category | Count | Already have (playable / layout) | Why this number |
|---|---|---|---|
| Campaign-only base maps | **13** | 1 / 0 | Exactly what the 36 missions need (1.2); the variants keep the count low |
| 1v1 skirmish | **12** | 1 / 0 | 1v1 is the main mode and the bot/balance mode. 12 maps cover 3 sizes (small rush, standard, big macro) x 4 biomes, and each campaign biome gets a skirmish twin (its kit is already paid for) |
| 2v2 skirmish | **8** | 0 / 3 | 3 laid out, 3 concepts in `new-maps.md`, Two Harbours, and 1 generated. Fewer than 1v1 because each costs ~1.5x (size, 4 seats, perf) |
| 4-player FFA (3 with one seat closed) | **4** | 0 | A new mode (`ffa.md`, not written yet). Fourfold symmetry already gives 4 equal seats, so the maps are cheap; the mode is the work. 3 players = a 4-seat map with one seat closed (its base area becomes neutral land, 2.2); a true 3-way map needs a `rot120` symmetry (later, not 1.0) |
| Special | **3** | 0 | Tollrock Arena (hero + champion duels), Hollow Pit Survival (co-op waves, reuses the e8m3 map), Proving Grounds (sandbox for players; also our calibration map for Bot / Map / Perf Labs) |
| **Total** | **40** | 2 playable, 3 laid out | JS asked for "30+". 40 fits a strong 1.0, and the generator keeps adding maps after it at ~5 agent-hours each |

### 1.4 All 40 maps
Sizes are the playable square (or `W x D`). Players: 1v1 = 2 seats, 2v2 = 4 seats, FFA = 4 (3 with one closed). Kingdom
flavour = **the look only** (new-maps.md 1: every kingdom gets its good ground at one objective per side). Status: P
playable, L layout exists, S spec / draft, C concept, G generated (archetype in brackets).

**Campaign-only (13)**
| # | Map | Size | Seats | Biome | Kingdom | Key feature | Missions | Status |
|---|---|---|---|---|---|---|---|---|
| C1 | Emberfall | 120 | 1 + scripted | ash heath, ruins | Fire | the braziers and the sealed crown | m00, m01 | P |
| C2 | Glasswater Mere | 120 | 1 + scripted | frozen lake, snowbanks | Ice | thin-ice floes, the Heartfrost dig, blizzards | m02, e6m1 | S |
| C3 | Sighing Wood | 120 | 1 + scripted | deep broadleaf forest | Nature | 3 Root Hearts in glades, Warden gates | m03, e2m1, e4m3, e8m1_nature | S |
| C4 | Salt Road | 200 x 96 | 1 + scripted | salt flats, dunes, causeways | neutral (Magpies) | one long caravan road with 3 raid choke points; Hunters' Lodge at the end | e2m3 | C |
| C5 | Emberdeep Halls | 140 x 80 | 1 + scripted | underground forge halls (new kit) | Fire / Warden stone | 3 halls linked by narrow stairs; no base until the Warden forge | e2m4 | C |
| C6 | The Deep Door | 128 | 3 (player + ally bot + 2 enemy bots, 3-way race) | cavern, white-gold door | Master | 3 tunnels converge on the door plaza; boss arena in front of the door | e2m5 | C |
| C7 | Evenmead | 150 x 120 | 4 (2v2, not mirrored) | meadow river valley, two hills | Nature / Fire vs Shadow / Ice | one stone ford + two side fords, Lark Hill, the golden tree | e3m1, e3m2, e3m4, e4m1, e6m3 | S (positions in `mission-e3-01.md`) |
| C8 | Gravenhold | 128 | 1 + scripted | crypt city, catacombs, candle streets | Shadow | 3 walled districts, crypt stairs, the shard altar | e3m3, e5m3, e8m1_shadow | C |
| C9 | Larkwood Road | 200 x 80 | 1 + scripted | western woods, willow brooks | Nature | escort corridor with 4 ambush glades and 2 bridges | e4m2 | C |
| C10 | Hundred Winters | 160 x 112 | 2 + scripted | ice wall, frozen pass, town | Ice | the great wall with 3 gates; the town beyond the main gate | e4m4, e6m2, e8m1_ice | C |
| C11 | Brightvale | 112 (variant 112 x 160) | 1 + scripted | sunny valley under the citadel | Fire / Master | 5 beacons; south extension holds the raider fort | e5m1, e5m2 | C |
| C12 | Adamarch Outwall | 112 | 1 + scripted | harbour slums, diamond pits (new city kit) | Ice / city | dense street blocks, 4 docks, the pits as a sealed zone | e7m3 | C |
| C13 | The Hollow Pit | 96 | 4 keyholes (player + 3 allied bots) | the broken throne pit (shares `forge_hollow_pit`) | all four | ring of 4 keyholes round the boss | e8m3 | C |

**1v1 skirmish (12)**
| # | Map | Size | Biome | Kingdom | Key feature | Status |
|---|---|---|---|---|---|---|
| S1 | Crown Hollow | 120 | river grassland, crown isle | neutral | the reference map: diagonal river, 8 crossings | P |
| S2 | Cinderstep Gorge | 112 | scorched canyon | Fire | rush map: home gorge bridges, enemy ~16 s away by Hound | S |
| S3 | Thawmere Reach | 136 | frozen valley, warm mere | Ice | macro map: Hearthshelf pocket, sealed Frostgate third, 6 bases | S |
| S4 | Three Rills | 124 | willow fens | Nature | two streams, a Commons in the middle (mirror_x); needs the 3-bank river change, so it is built late | C |
| S5 | Mirewatch Caldera | 128 | black fen, mist | Shadow | caldera ring round one great isle (crown + 2 wells) | C |
| S6 | Two Harbours Duel | 180 x 120 | strait, harbour cities | Ice / gold | the Ep7 shore with one keep a side; Dragon Auction | S |
| S7 | Orrery Green | 96 | trimmed lawns, practice dummies, the citadel above | Master | small, open, 3 banner points (also e5m4) | C |
| S8 | Evenmead Fields | 136 | meadow river, two hills | Nature | **twin of C7**, mirrored: hilltop sight and one ford per side | G (`river_split` + hills) |
| S9 | Glasswater Crossing | 128 | frozen lake | Ice | **twin of C2**: thin-ice lanes that open in winter phases | G (`mere`) |
| S10 | Gravenhold Crossroads | 128 | crypt streets | Shadow | **twin of C8**: walled districts, 4 gates | G (`spine`) |
| S11 | Saltpan Road | 144 | salt flats | neutral | **twin of C4**: long trade routes worth 1.3x gold, Magpie camps | G (`open` + trade ring) |
| S12 | Sighing Hollows | 120 | deep forest | Nature | **twin of C3**: forest maze with glades, -30 % sight lanes | G (`open` forest) |

**2v2 skirmish (8)**
| # | Map | Size | Biome | Kingdom | Key feature | Status |
|---|---|---|---|---|---|---|
| D1 | Fourfold Hollow | 168 | golden autumn | neutral | Crown Hollow x2: allies on one bank (also e2m2, e8m2) | L |
| D2 | Kinhearth Vale | 176 | willow meadows | Nature | allies side by side on the Hearth Green: team fights | L |
| D3 | Gloamspine Divide | 160 | black fen | Shadow | spine ridge: two lanes, three gates | L |
| D4 | Two Harbours | 180 | strait, cities | Ice / gold | partners share a shore; Tollrock; Dragon Auction (also e7m1, e7m4) | S |
| D5 | Frostfang Pocket | 176 | pack ice, frozen falls | Ice | front keep + pocket keep per team (role play) | C |
| D6 | Emberwater Cross | 168 | lava-lit lake | Fire | two rivers, four banks; needs the 4-bank river change, so it is built last | C |
| D7 | Brightvale Meadows | 160 | sunny valley | Fire | **twin of C11**: beacon points as capture objectives | G (`river_split`) |
| D8 | Hundred Winters Pass | 176 | ice wall, pass | Ice | **twin of C10**: the wall splits the lanes, gates open at 6:00 | G (`spine`) |

**4-player FFA (4)**
| # | Map | Size | Biome | Kingdom | Key feature | Status |
|---|---|---|---|---|---|---|
| F1 | Four Thrones | 176 | each corner its kingdom's home ground | all four | the signature map: crown isle centre, four homelands (the Ep8 picture) | C |
| F2 | Quartermoor | 168 | moorland, standing stones | neutral | no river; 4 wells on the diagonals, open fights | G (`open`) |
| F3 | Cindermere Isles | 168 | ash isles, chasms | Fire | chasm rifts (blocks, not water) with 8 bridges | G (`chasm`) |
| F4 | Wardenfall Ruins | 160 | Warden stone ruins | Master | ruin maze, 4 sealed caches, wardens patrol | G (`spine`) |

**Special (3)**
| # | Map | Size | Mode | Key feature | Status |
|---|---|---|---|---|---|
| X1 | Tollrock Arena | 72 | hero duel 1v1 / 2v2 (wizards + champions, no economy) | the Laurel ring; uses the `forge_tollrock` set | C |
| X2 | Hollow Pit Survival | 96 | co-op waves (1-2 players + bots) | e8m3's map, unlocked after the ending | C (variant of C13) |
| X3 | Proving Grounds | 128 | sandbox: every objective kind, spawn panel | **also the calibration map** for Map Lab / Bot Lab / Perf Lab (one of everything at known distances) | C |

## 2. The technique: text maps from templates, a generator, the Lab loop
### 2.1 Options compared
| Option | How a map is made | Cost to build | Cost per map (layout only) | Quality risk | Verdict |
|---|---|---|---|---|---|
| A. Fully hand-written `.map` (today) | a designer draws a sketch, writes every spot, the forge + Map Lab judge it (as in `new-maps.md`) | 0 | ~3-5 agent-hours + 1-2 fix rounds; spot clearances by hand | Good for hero maps; slow and error-prone at 40 | Keep for hero maps, **through templates** |
| **B. Templates + generator + Lab auto-fix (recommended)** | `gen` writes a valid mirrored `.map` from `seed + archetype + biome + players`; templates make hand maps short; the Lab ranks candidates and auto-fix nudges spots | ~65 agent-hours of tools, once | **~1-1.5 h** (generated, picked from a contact sheet) / ~2-3 h (hand map with templates) | Generated maps can feel samey, so every one gets a **hook** (a key feature row) and a designer pick | **Yes: hybrid.** Campaign, signature and twin maps from templates by hand; filler / FFA maps generated |
| C. Full visual editor (Godot EditorPlugin: spot gizmos, polyline river editing, live symmetry, Lab button) | a human drags things in the editor | ~30-40 agent-hours + upkeep with every grammar change | fast for a human, **zero help for agents** (they write text) | Two sources of truth (scene vs `.map`) unless it writes `.map` | **Not now** (2.7) |
| D. In-game tweak overlay (optional) | dev key in a skirmish: shows spots, heat map, lets you drag a spot (its twins follow) and saves the `.map` | ~6 agent-hours | minutes, for JS's own tweaks | Low (writes the same text) | **Later**, if JS wants to touch maps himself |

### 2.2 The `.map` grammar v2 (four-wizards-high; additions only, every v1 file stays valid)
| Statement | Meaning | Needed by |
|---|---|---|
| `map <id> size=WxD` | non-square maps (`size=150x120`); square stays `size=120` | Evenmead, Salt Road, Larkwood Road, Two Harbours Duel |
| `use <template> at=(x,z) yaw= mirror= key=value...` | expands a template from `data/maps/templates/<template>.mapt` into spots / river / blocks / zones / roads, in the canonical region; its ids get a prefix | every map |
| `terrain` / `hill` / `ridge` / `valley` / `pad` | the stage-set terrain statements (same code, `forge_terrain.gd`): a height field under the map, baked into the navmesh | Evenmead's hills, Hundred Winters, Gravenhold |
| `forest seed= clusters= kinds= density= clear=auto` | the `main.gd` generator moved into data: seeded tree / rock clusters, automatic clearings around every spot, road and crossing (+ listed `clear` circles) | Emberfall / Glasswater / Sighing Wood (same seeds as their specs), every skirmish map |
| `block <id> ... kind=cliff/wall/ruin/city` | `kind` tells the dressing which mesh to put on the collider | ridges, the ice wall, city blocks |
| `rules archetype= tempo= targets={keep_enemy:100..120, natural:30..36, crown:48..56, ally:60..72}` | the targets the Map Lab checks (today they live in prose in the design doc) | every map |
| `closed_seat <seat> becomes=neutral` | 3-player FFA / 2v1 missions: that seat's district becomes neutral land (its nodes stay, no keep) | FFA, e2m1 |
| **Mission overlay**: `map <mission_id> base=<map> variant=<id>` then `bounds rect(...)`, `light=night/dawn/day/storm/winter`, `biome_override zone=... biome=`, `remove <spot id>`, `move <spot id> at=`, `mark <id> at=` (named point: start, rally, spawn, brazier...), `trigger <id> <area>` (named area), `path <id> poly=[...]` (wave or escort route), `seat <team> scripted` | a mission names its places in data, not in code constants | every mission |

`MapLayout` gains `mark(id)`, `trigger(id)`, `path(id)`, `bounds`, `light`, `rules` (contract for the lead to freeze, 2.8).

### 2.3 The template library (`data/maps/templates/*.mapt`, ~30 in v1)
A template is a small `.map` fragment in its own local frame (`(0,0)` = its anchor, `+z` = toward the map centre), with
parameters (`$r`, `$amount`...) and its own clearance rules. It is checked once, alone, by a mini Lab run (all its
spots reachable on a flat bake, its clearances met). Families:
| Family | Templates (v1) | Notes |
|---|---|---|
| Bases | `base_district` (the 1v1 CH district: keep, hub, 2 home nodes, H1 / S1 / S2 / M1 / house / rush / wall slots, unchanged so bots and walls work), `base_district_cliff` (one mouth), `pocket_shelf` (Thawmere's safe node behind a ridge) | always placed by `seat_frame` |
| Resources | `natural` (node 2 500 + hall slot X1), `rich_pocket` (node 2 500 + Den / Lodge / hollow), `sealed_vein` (node 1 500 behind a T3 stag), `third_far`, `river_node` | amounts from `economy.md` |
| Rivers | `river_diagonal` (CH), `river_straight` (fourfold arms on `x = 0`), `river_s_bend`, `mere` (big moat + isle), `gorge` (straight + 2 home bridges) | obey the engine limits: one `half_width`, 2 banks, <= 4 ford / steps circles, <= 16 segments |
| Crossings | `crossing_set_cross` (2 road bridges + 2 fords + 2 lane bridges + 2 steps), `crossing_set_gorge`, `crossing_set_lean` (6) | widths from CH (6 / 7 / 8 m) |
| Chokes and walls | `spine_gate` (ridge with a 6-8 m gate), `wall_gates` (3-gate wall), `chasm_bridge` (rift of blocks + a bridge), `city_block` | named C2 exceptions travel with the template |
| Centre objectives | `crown_isle` (moat isle, Ember Crown, Ruin Wardens), `crown_open` (no moat, pillar ring), `twin_wells`, `tollrock` (arena ring + lighthouse point) | the crown is always `solo` on the centre |
| Points | `tower_over_crossing` (watchtower seeing a bridge + a ford), `well`, `shrine`, `point_cluster_river` (the audit's per-seat river tower + T2 camp, contest ratio 1.27-1.32x) | `map-fill.md` 4.1 clearances |
| Neutral camps | `camp_trio` (T1 wallow, T2 nest, T3 stag at the standard distances), `nest_in_ford`, `hollow_gate`, `lair_pair` (`kind=a|b` per seat) | `map-fill.md` 5.2 / 5.5 clearances |
| Services | `tavern_peddler`, `trade_ring` (2 posts + a ring road; near route 40-60 m, far 110-140 m), `guild_pair`, `cache_pair` | `market-trade.md` 4.3 |
| Biomes | `biome_<id>` zone presets (ash, snow, marsh, sand, forest, meadow, autumn, salt, crypt, coast, deep): ground, decor set, forest kinds, **gameplay terrain share ~28 %** | look only; gameplay patches follow `terrain.md` |

Hand-written maps become short: Cinderstep Gorge's 46 lines become ~15 `use` lines plus a few spots of its own.

### 2.4 Parametrised generation (`run_world_forge.ps1 gen <id> archetype= seed= players= size= biome= tempo= count=`)
Archetypes v1: `river_split` (CH-like), `gorge` (rush), `mere` (big centre lake, long way round), `spine` (ridges +
gates: lanes), `chasm` (rifts of blocks + bridges: "islands" without new river code), `open` (no river, forest clusters
and clearings), `corridor` (long escort road, campaign), `arena` (small ring, no economy). Players 2 (`rot180`, or
`mirror_x` for `rills`) or 4 (`fourfold`).
Tempo sets the targets: **rush** keep -> enemy keep 100-120 m, 4 expansions per seat; **standard** 116-150 m, 4-5;
**macro** 150-190 m, 6. Team maps add ally 60-72 m and enemy / ally soldier time 2.0-3.0x (JS 2026-09-27: "2 to 3 times
longer to the enemy than to the ally").
Steps (all in the canonical region; the symmetry makes the rest):
1. **Skeleton**: the archetype's template with seeded jitter (river polyline, blocks, crossings), sized to `size`.
2. **Keep**: `base_district` on the canonical region's back edge, slid until keep -> centre fits the tempo band.
3. **Expansions** by ring sampling: natural, rich and third candidates scored on a quick **2D grid path** (generator's own
   coarse A* on a 1 m grid with water and blocks as walls: no Godot bake, ~50 ms) against the tempo targets.
4. **Objectives by contest ratio** (`map-2v2-audit.md` metric): own points at 0.75-1.0x the enemy's time, raidable ones at
   1.27-1.32x, contested on the axis (1.0x); per seat >= 5 contested + raidable objectives on 1v1, >= 2.5 on team maps.
5. **Services**: tavern, peddler, trade ring, guilds, caches, lairs, from the templates with their distance bands.
6. **Roads and lanes** (ring road through the posts, lane keep -> crown), **zones** (biome + ~28 % gameplay terrain).
7. **Clearance solver**: pushes spots apart (L3 >= 3 m, camp >= 9 m and point >= 7 m from road centre lines, nothing within
   8 m of a crossing), moves <= 5 m each.
8. **Write** `data/maps/gen/<id>_s<seed>.map` with a header line `# generated: gen archetype=... seed=... (do not hand-edit;
   copy to data/maps/<id>.map to adopt)`.
9. **Pre-filter**: the fast grid score from step 3 drops bad candidates, so `count=40` seeds -> the best 8 go on to the
   forge + Map Lab (~60-150 s each; ~15 min on the laptop, 4 Godot at a time through `godot_run.ps1`).
10. **Auto-fix loop** (2.5), then the **contact sheet** (2.6) of the top 3 for the designer's pick.

### 2.5 Auto-check and auto-fix (Map Lab v2)
The Map Lab already judges a `.map` preview (N1-N3, M1-M4, F1-F2, D1, A1, T1, C1-C2, H1). v2 adds:
| New check | Rule |
|---|---|
| R1 Targets | every `rules targets=` band met (unit path lengths); FAIL > 10 % out, WARN 5-10 % |
| R2 Content per seat | the `new-maps.md` 1 table per seat (2 home nodes, natural, rich, 2 posts, tavern, peddler, 2 caches, T1 / T2 / T3 camps, 2-4 lairs, 2 towers + well + shrine, the crown); +-1 = WARN, missing kind = FAIL |
| R3 Contest | contested + raidable objectives per seat (2.4 step 4): 1v1 >= 5, team >= 2.5 (WARN under) |
| R4 Clearances | `map-fill.md` 4.1 / 5.2 / 5.5 and `terrain.md` 4.1 distances; spot inside a forest clearing radius |
| R5 Engine limits | one `half_width`, 2 banks, <= 4 ford / steps circles, <= 16 river segments, size <= 192, spots <= 140, navmesh cells <= 4x the 1v1 (FAIL) |
| R6 Mission mode (`symmetry=none` + overlay) | every `mark` / `trigger` / `path` reachable from the player start; the spec's timing lines (`Dusk Keep -> Stone Ford 51 m`, read from a `rules targets=` block in the overlay) within +-5 %; spawn marks out of the player's start sight; no forest inside a mark's clearing |
| Big maps | the 1 m Dijkstra grid for `half_size > 70` (map-lab.md 6) so a 180 m map runs in <= 3 min |
**Auto-fix** (`run_world_forge.ps1 fix <id>`, max 5 loops): reads the report's fixable rows: a spot off its target band
(moved <= 5 m along the path gradient), a clearance (pushed out), a crossing under 4 m (widened <= 2 m), a choke under 3 m on a
main route (the nearest block shortened). It rewrites the canonical `.map` lines with `# autofix: moved 3.2 m (R1 natural)`
and runs again. It **never** touches symmetry, river course or seat frames (those are FAILs for a human). It stops when
there is 0 FAIL and the score is >= 75, or after 5 loops (report "needs a designer").

### 2.6 Quick preview
- `layout.png` exists (spots by kind on the plan). New **`mapsheet <id>`** (windowed, ~20 s): one 2048 x 1024 PNG with
  the plan, the heat map, a **top-down render** of the dressed level (forest, ground, water: what a player sees), the
  travel-time table and the score. Contact sheets for `gen` put 3 candidates side by side.
- The same render, cropped, gives the **lobby preview** `data/maps/previews/<id>.png` (512 x 512) and the minimap
  background. No hand-made preview images.

### 2.7 When a visual editor becomes worth it
Build the **in-game tweak overlay** (D, ~6 h) when one of these happens: JS asks to move things himself; batch 1 shows
more than 1 in 3 maps needing 3+ manual fix rounds; or the campaign overlays (marks, triggers, paths) take more than
1.5 h each. A **full EditorPlugin** (C) only if JS wants to author whole maps himself, which nothing in his requests
suggests. Even then it must read and write `.map` (one source of truth).

### 2.8 Runtime: any `.map` plays (the missing piece)
- **`MapInfo`** (`scripts/core/map_info.gd`, lead; `map-2v2.md` 5): size / half / bounds read by fog (84 x 84 cells at
  168 m, shader `map_half`), BuildGrid, RiverSystem mask, minimap (letterboxed `W x D`, `ui-2v2.md` 7), camera bounds.
- **`LayoutLevel`** (`scripts/world/layout_level.gd`, systems; = `new-maps.md` NM.C1, merged): builds a playable level
  from a `MapLayout`. Spots become keeps / nodes / camps / points / taverns / posts / guilds / peddlers / caches; `LAIR_SPOTS`
  comes from the lairs; plus river + crossings, roads, zones -> TerrainSystem patches, blocks -> colliders (layer 1, before
  the bake), terrain height field, `forest` statement (the ported `main.gd` generator), seat spawns by `seat_frame`.
  `Skirmish` (1v1) and `Skirmish2v2` take `layout_path`; missions extend it and read `layout.mark(...)`.
  **Regression gate**: Crown Hollow rebuilt from `crown_hollow.map` = the live map (export-map R1 <= 0.1 m, R2 path table
  <= 0.01 m), and Emberfall rebuilt from `emberfall.map` (`forest seed=1101`) has the same tree hash as `mission_01.tscn`.
- **`MapCatalog`** (`data/maps/catalog.tres`): id, title, modes, seats, size, biome, hook line, preview, `ready` flag. The
  skirmish menu reads it (section 5).

### 2.9 How a campaign mission binds to its map
1. The base map (`data/maps/<base>.map`, `symmetry=none` for campaign-only maps) holds the geography: terrain, river,
   forest seed, the bases' districts, nodes.
2. The **overlay** `data/maps/missions/<mission_id>.map` (`base=<map> variant=<id>`) holds everything the script names:
   `mark` (player start, rallies, wave spawns, braziers, keyholes, boss spot), `trigger` areas (ford zone, ambush glades,
   "reached the gate"), `path` (wave routes, escort routes), `seat ... scripted`, removed or moved spots, bounds, light,
   biome override. Ids follow the spec's names (`zone_ford`, `std_clover`...).
3. The mission script reads them through `MapLayout.mark(id)` / `trigger(id)` / `path(id)`; **no position constants in
   `scripts/campaign/`** (Map Lab M2 stops checking constants there once a mission is on an overlay).
4. The mission spec's Map table is the source. The overlay task copies it to +-0.5 m (as E34.M1 already requires), the
   Map Lab R6 checks the spec's timing lines, and the spec writer for a second mission on the same map reads the overlay
   (never invents positions: `mission-e3-01.md` rule).
5. Variants share the base's navmesh skeleton, so one base fix reaches every mission on it. A variant that moves more than
   ~10 spots or changes the river is promoted to its own base map.

## 3. Pipeline per map (agent tasks, Opus 5.5 medium; all through `tools/godot_run.ps1`)
| Step | Who | Skirmish map (generated) | Skirmish map (hand, templates) | Campaign base map | Mission variant / overlay |
|---|---|---|---|---|---|
| 1. Brief: archetype, size, seats, biome, hook, targets (a row in `map-production.md` 1.4 + `rules`) | game-designer (5 briefs per task) | 0.2 h | 0.3 h | inside the mission spec | inside the mission spec |
| 2. Layout: `gen` sweep + pick, or `use` templates; forge `map`; auto-fix; Map Lab >= 75 | map-maker (four-wizards-high, owns `data/maps/`) | 1.0 h | 2.0 h | 2.5 h (terrain, forest seed, mission R6) | 1.0 h (overlay from the spec table) |
| 3. Sign-off (scorecard, heat map, contact sheet; numbers into this doc) | game-designer (batch 3-5 maps) | 0.3 h | 0.3 h | 0.3 h | - |
| 4. Dressing: biome kit params, landmarks, block meshes (crags / walls / city), edge + horizon, lobby preview | tech-artist (one per map) | 2.0 h | 2.0 h | 2.5 h | 0.5 h (light, biome override) |
| 5. Bots: read the layout, rush / scout / creep order fine (only if the gate fails) | ai-coder | 0.5 h (share) | 0.5 h | campaign bot profile is a mission task | - |
| 6. Gate: Bot Lab fairness matrix + perf (4.3), catalog row | lead (machine time on the laptop) | 0.5 h | 0.5 h | mission tests | mission tests |
| **Total** | | **~4.5 h** | **~5.5 h** | **~6 h** | **~1.5 h** |
Once per biome: a **biome kit** (tech-artist, ~8 h: ground params, decor set in the `map-fill.md` 10 format, forest kinds,
block meshes). Existing: Crown Hollow grass, golden autumn (20.V0), ash / snow / marsh / sand terrain grounds, the
`forge_evenmead` meadow. **New kits (9):** frozen lake, burnt + frozen wood (one kit, two looks), salt flats, underground
halls (Emberdeep + Deep Door), crypt city, harbour / city (Two Harbours + Outwall), ice wall + pass, Brightvale sun valley,
the Hollow pit.
**Parallelism**: maps never share files (one `.map`, one `out/<id>/`, one art folder each), so 2 map-makers + 2-3
tech-artists + 1 designer + 1 ai-coder run at once (the lead's 6-agent cap). The limit is Godot runs (4 at once through
the gate). Gen sweeps and Bot Lab matrices go on the laptop ("max it out", one Godot window at a time, headless runs OK).
**Serial**: MT1 -> MT2 before any map is playable; a biome kit before its first map's dressing; the template library
before hand maps use it (Fourfold / Kinhearth / Gloamspine adopt as-is).

**Total effort** (agent-hours, medium; low confidence, re-measure after batch 1):
| Work | Count | Hours |
|---|---|---|
| Tools MT1-MT10 (4.2) | 10 | ~65 |
| Campaign base maps (13; Emberfall adopt only) | 12 new + 1 | ~75 |
| Mission variants / overlays | 17 V + 4 R + m01 | ~33 |
| 1v1 skirmish (11 new or adopted) | 11 | ~55 |
| 2v2 skirmish (3 adopt at ~3.5 h + 5 new) | 8 | ~38 |
| FFA (maps only; the mode `ffa.md` is separate, ~12 h of code) | 4 | ~20 |
| Special | 3 | ~14 |
| Biome kits | 9 | ~72 |
| **Total** | | **~370 h** (campaign-outline 5.2 already counts ~150 of it inside its mission builds and art: **~220 h new**) |
At ~0.6 % of the weekly budget per agent-hour task, the new part is ~1.3 weekly budgets, spread over the waves.

## 4. The first batch (10 maps)
### 4.1 Which maps, in what order
Picked to (a) prove the runtime on 1v1, 2v2 and asymmetric campaign maps, (b) unblock Episode 1 first (campaign-outline
6), (c) give the skirmish menu a real choice (5 1v1 + 3 2v2 after the batch), (d) prove the generator on existing kits.
| Order | Map | Kind | Why now | Depends on |
|---|---|---|---|---|
| 0 | Crown Hollow re-built by `LayoutLevel` (not a new map) | regression | proves MT2 against the live map | MT1, MT2 |
| 1 | **Fourfold Hollow** (D1) | 2v2, adopt | step 20's map: layout done, 4-seat runtime proof; also e2m2 / e8m2 | MT1, MT2, step 20 rules |
| 2 | **Cinderstep Gorge** (S2) | 1v1, hand + templates | small rush map, ash kit exists; first map written from templates | MT3, MT4 |
| 3 | **Glasswater Mere** (C2) | campaign base | m02 is Ep1's next mission; first `forest` port with a seed | MT2 forest port, frozen-lake kit |
| 4 | **Sighing Wood** (C3) | campaign base | m03 + e2m1 + e4m3 + e8m1_nature: 4 missions on one map | forest port, burnt-wood kit (normal look first) |
| 5 | **Evenmead** (C7) | campaign base, 2v2 asymmetric, terrain heights | e3m1 / e4m1 (both films exist) + 3 variants; first `terrain` map and first R6 mission check | MT3 terrain, MT6 R6 |
| — | **Playtest 1** (JS): Gorge + Fourfold in skirmish, Glasswater as a mission preview | | | |
| 6 | **Kinhearth Vale** (D2) | 2v2, adopt | layout done; Nature look | runtime from 1 |
| 7 | **Thawmere Reach** (S3) | 1v1, hand + templates | big macro map: the other end of the size range | MT4, snow kit |
| 8 | **Gloamspine Divide** (D3) | 2v2, adopt | layout done; first map with ridge blocks: block meshes | block meshes (art) |
| 9 | **Evenmead Fields** (S8) | 1v1, **generated** | first `gen` map; reuses the Evenmead kit | MT5 |
| 10 | **Glasswater Crossing** (S9) | 1v1, **generated** | second `gen` map; reuses the frozen-lake kit | MT5 |
| — | **Playtest 2** (JS): map picker with 5 1v1 + 3 2v2 | | | MT9 |

### 4.2 Tool tasks to build first
| Id | Task | Owner | Size | Done when |
|---|---|---|---|---|
| MT1 | `MapInfo` + size-generic fog (shader `map_half`, grid), BuildGrid, river mask, minimap letterbox, camera bounds (= `map-2v2.md` 20.L1 / 20.C*) | lead (contract) + systems-coder | M (~6 h) | CH unchanged (smoke, perf, Map Lab 98); a 168 m and a 150 x 120 level load with correct fog / minimap |
| MT2 | `LayoutLevel` (2.8) incl. the `forest` port of `main.gd` `_build_map`, `Skirmish.layout_path`, `Skirmish2v2` on a layout (= NM.C1) | systems-coder [H] | L (~10 h) | regression gate (CH round trip R1 / R2, Emberfall tree hash); Fourfold loads headless, 4 seats spawn, 2 / 4 bots play 10 min with 0 script errors; live Map Lab within 2 points of the preview |
| MT3 | Grammar v2 (2.2): `size=WxD`, `use`, terrain statements, `forest`, `block kind=`, `rules`, `closed_seat`, mission overlays; `MapLayout.mark / trigger / path / bounds / rules` | four-wizards-high | M (~6 h) | every v1 `.map` builds byte-identical layouts; a test overlay on CH round-trips; README section 2 updated |
| MT4 | Template library v1 (~30 `.mapt`, 2.3), each with a mini Lab check; rewrite Cinderstep Gorge with `use` | four-wizards-high + game-designer (numbers) | M (~6 h) | all templates PASS alone; Gorge from templates = the 4.1 draft +-0.5 m |
| MT5 | `gen` verb (2.4): 8 archetypes, 2 / 4 players, tempo, biome, seed sweep with the grid pre-filter, contact sheet | four-wizards-high [H] | L (~10 h) | 3 archetypes x 2 player counts each give >= 3 candidates with 0 FAIL and score >= 75 from a 40-seed sweep in <= 20 min on the laptop |
| MT6 | Map Lab v2 (2.5): R1-R6, 1 m grid for big maps, `fix` auto-fix loop | four-wizards-high (Map Lab owner) | M (~8 h) | `tests/test_map_lab.gd` extended (synthetic cases per new check); auto-fix takes a seeded broken Gorge (3 spots off by 4 m) to PASS in <= 3 loops |
| MT7 | `mapsheet` PNG + lobby preview + minimap background render | four-wizards-high | S (~3 h) | sheets for the 4 existing layouts; previews 512 x 512 |
| MT8 | Map gate script `tools/ci/map_gate.ps1 <map>`: Bot Lab fairness matrix + rush matrix + perf + load time (4.3), one scorecard | lead (with the Bot Lab owner) | S (~4 h) | runs on CH and reproduces today's numbers; one command per map |
| MT9 | `MapCatalog` + skirmish menu map picker (preview, size, seats, hook line, Random), `GameSettings.map_id` (= NM.U1) | ui-designer (layout, 1 h) then ui-coder (~3 h) + systems (catalog, 1 h) | M | 1v1 / 2v2 lists from the catalog; the pick reaches the level; Random picks only `ready` maps |
| MT10 | Bots read the layout (scout path, rush bridge + staging, creep / capture order, `lane_opponent`, gates), no CH constants (= NM.A1) | ai-coder | M (~6 h) | Bot Lab mirror within 1.1x on Gorge and Fourfold; 4-bot 2v2 ends with a winner |
| MT11 | (optional, later) in-game tweak overlay (2.1 D) | ui-coder + four-wizards-high | S (~6 h) | only on the 2.7 triggers |
Order: MT1 -> MT2 (critical path) in parallel with MT3 -> MT4 and MT6 and MT7; then MT5, MT8, MT9, MT10. Maps 1-5 start
when MT2 + MT3 land; maps 9-10 wait for MT5.

### 4.3 Acceptance checks (every map)
| Gate | Threshold |
|---|---|
| World Forge `map` | exit 0; L1-L3 PASS; R5 engine limits PASS |
| Map Lab | **score >= 75 (JS 2026-10-02, was 90), 0 FAIL**; mirrored maps: N2 / M1-M4 / F1 PASS, D1 <= 2 % per seat, T1 seats within 3 s and 3 %; C1 crossings >= 4 m of navmesh; C2 no main-route choke < 3 m except named gates; R1 targets met; R2 content per seat; R3 contest (1v1 >= 5, team >= 2.5 per seat); team maps: A1 PASS and enemy / ally soldier time 2.0-3.0x; campaign: R6 PASS |
| Bot fairness (MT8), per map | Bot Lab, both seats swapped, **3 difficulties (easy / normal / hard) x 4 kingdom mirrors (Fire-Fire, Shadow-Shadow, Ice-Ice, Nature-Nature), 10 games per cell (120 games, laptop, sim mode)**: pooled seat win rate **45-55 %** per difficulty, no cell over 65 %; kingdom-vs-kingdom on that map 40-60 % (the global 45-55 % stays `rush-balance.md`'s job); 0 script errors, `stuck = 0`, every game ends (kill or score at 30:00). Rush maps: `rush-balance.md` 11 matrix in band, <= 15 % of rush games over before 8:00. 2v2 / FFA: 4-bot games end with a winner, each seat wins 20-30 % (FFA) or each side 45-55 % (2v2) |
| Performance | 1v1: `perf_test.gd -- map=<id>` prints `PERF OK`; 2v2 / FFA: 300 units <= 15.0 ms per frame (quiet desktop), 400-unit stress <= 22 ms; first navmesh bake <= 5 s on the desktop, runtime rebake <= 1.5 s; decor <= 12 000 instances and <= 140 draw nodes; RAM <= +60 MB vs a CH match; load to playable <= 10 s on the GTX 1660 desktop; >= 60 fps at max zoom over the busiest metre (heat map) in the windowed lead check |
| Art | Art Lab R4k PASS for the biome; units readable on the ground (contrast check, as the golden-autumn rule) |
| Playtest | JS plays it once (the end-of-wave rule); one-line verdict in `playtest-notes.md` |

### 4.4 Batch 1 effort
Tools MT1-MT10 ~62 h; maps: 3 adoptions (~3.5 h each, ~11), 2 hand skirmish (~11), 3 campaign bases (~18), 2 generated
(~9); new kits: frozen lake, burnt / normal broadleaf wood (Evenmead and ash exist) ~16 h; gates and playtest prep ~8 h.
**~135-145 agent-hours, ~55 tasks.** At 6 agents: **3-4 lead sessions** (critical path MT1 -> MT2 -> Fourfold ~1 session).

## 5. Plan-doc impacts (for the lead and the doc owners)
| Doc | Change |
|---|---|
| `docs/plan/waves.md` | New step **"MP: map production"**: MP.T1-T11 (= MT1-MT11, 4.2), MP.M1-M10 (batch 1, 4.1), two playtests; later batches MP.B2 (campaign Ep2-4 maps: Salt Road, Emberdeep, Deep Door, Gravenhold, Larkwood Road, Hundred Winters; skirmish S4 / S5 / S10-S12, D4-D5), MP.B3 (Ep5-8: Brightvale, Orrery Green, Two Harbours + Duel, Outwall, Hollow Pit; FFA after `ffa.md`; specials; D6 / D7 / D8). Fold `new-maps.md` NM.C1 -> MT2, NM.U1 -> MT9, NM.A1 -> MT10, NM.F1-F4 -> MP.M*; step 20's MapInfo -> MT1 |
| `docs/plan/map-lab.md` | Section "v2": R1-R6, 1 m grid, `fix` loop, the gen pre-filter; the section 5 rule extended: generated maps run `gen` -> `fix` -> Map Lab, and a map task ends with "Map Lab notes" + the contact sheet |
| `tools/world_forge/README.md` | Grammar v2 (2.2), verbs `gen`, `fix`, `mapsheet`; templates; limits section updated (heights and forest now in the preview) |
| Skirmish menu (`ui-2v2.md` lobby, `ui-hud.md` menus) | Map picker from `MapCatalog`: mode switch 1v1 / 2v2 / FFA, a list with preview, size, seats, biome, hook line, "Random" (ready maps only); `GameSettings.map_id`; 3 maps per mode minimum before the picker ships (after batch 1: 5 / 3 / 0) |
| `CLAUDE.md` (lead) | Contracts: `MapInfo`, `LayoutLevel` / `Skirmish.layout_path`, `MapLayout.mark / trigger / path / bounds / rules`, `MapCatalog`. Owner rows: `data/maps/templates/`, `data/maps/missions/`, `data/maps/gen/`, `data/maps/previews/` -> four-wizards-high; `scripts/world/layout_level.gd` -> systems-coder |
| `campaign-outline.md` | The Map column takes the base map ids of 1.2; mission specs reference `data/maps/missions/<id>.map` |
| Mission specs (`mission-00`, `-02`, `-03`, `-e2-01`) | "the `main.gd` generator, seed N" becomes "`<base>.map` with `forest seed=N`" (same seed, same algorithm, so no number changes) |
| `new-maps.md` | Section 6 answers taken (Gorge + Thawmere + Kinhearth + Gloamspine); concepts C / D stay as S4 / S5 / D5 / D6 |
| `map-2v2.md` 8 | e2m1's 2v1 uses `closed_seat`; e2m2 / e8m2 overlays on Fourfold Hollow |
| `docs/ideas/jss_asks.md` | The 2026-10-02 row points here (done when batch 1 ships) |

## Open points (defaults taken; JS can change them)
- 40 maps for 1.0 (the floor JS asked for is 30: cutting the 4 FFA, 3 specials and 3 generated 1v1 twins gives exactly 30).
- No full visual editor; the in-game tweak overlay only on the 2.7 triggers.
- FFA needs its own rules spec (`ffa.md`: victory, diplomacy-free, bot targeting); its maps wait for it.
- True 3-player maps (`rot120`) are after 1.0; 3 players play a 4-seat map with one seat closed.
- Three Rills (S4) and Emberwater Cross (D6) need river changes (3 / 4 banks) and are scheduled last; if those changes
  are refused, they are replaced by two more generated maps.

## 9. Faster map production and the lower bar (JS 2026-10-02)
JS: "find any way to make it faster and lower score of new map to 75". Decisions (recommended option):
1. **Map Lab acceptance score is 75 (was 90)**, still 0 FAIL and the fairness checks (symmetry, seats within 2 %, enemy 2-3x farther than ally on team maps) stay hard gates. A 75 map ships; polish passes (score 90) only for hero/campaign signature maps and only after playtest.
2. **Auto-fix loop: 3 rounds, not 5.** Stop at >= 75 with 0 FAIL; do not chase the last points.
3. **Bot fairness in two passes:** 40 games (3 difficulties x 4 mirrors, seats swapped) as the gate, the 120-game run only for maps that are close to the 45-55 % edge or that are signature/ranked maps.
4. **Contact sheet of the top 3 only**, no windowed 'sheet' for every candidate; the preview PNG is the lobby image. One windowed look per shipped map.
5. **Parallel batches:** after MT1-MT3, build 6 maps at once (the Godot gate allows 4 parallel runs; the laptop is dedicated) instead of one by one; the seed sweep runs 4 seeds in parallel.
6. **Reuse before create:** 4 campaign maps are reuse and 17 are variants (night, winter, past, partial) at ~1.5 agent-hours: do these first; filler 1v1/2v2/FFA maps come from `gen` only (about 1-1.5 agent-hours each with a contact-sheet pick).
7. **Generated maps need no hand polish pass:** accept the best of the sweep if it clears the 75 bar, add one hook row, ship.
8. **Estimate with the bar at 75:** about 3 agent-hours for a generated skirmish map (was 4.5), 4 for a hand map from templates (was 5.5), 4.5 for a campaign base map (was 6); the 40-map total drops from about 370 to about 300 agent-hours, batch 1 from about 140 to about 110.

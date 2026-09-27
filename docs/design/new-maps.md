# New skirmish maps: two 1v1 and two 2v2 (concepts, picks, draft specs, build plan)

Task NM.D1, 2026-09-27, game-designer. User request (JS): "make 4 new maps: 2 2v2 and 2 1v1", options first. **Crown Hollow**
(1v1) and **Fourfold Hollow** (2v2) stay as extra maps. Maps are World Forge `.map` specs (`tools/world_forge/README.md` 2)
judged by the Map Lab (`docs/plan/map-lab.md`) before any scene code, then dressed and adopted like step 20. Builds on
`map-fill.md`, `map-2v2.md`, `terrain.md`, `rush-balance.md` 3.3, `market-trade.md` 4.3. Metres, `(x, z)`, `+x` east, `+z`
south. Names are original. The recommendations are used until JS answers section 6.
**References.** Crown Hollow (CH): rush route over a road bridge **152 m**, lane over the isle 122 m (warded early), Map Lab
keep -> enemy keep 116 m, -> natural 47, -> crown 58. Fourfold Hollow (FH): facing enemy 142, diagonal 187, ally 142.

## 1. Rules every new map follows
- **Content per seat = CH per side**: 2 home nodes (2 000), natural (2 500), rich (2 500), 2 trading posts on a ring road,
  tavern, peddler, 2 caches, T1 / T2 / T3 camps, 2-4 beast lairs, 2 towers + 1 well + a shrine per side, the Ember Crown on a
  moat isle with its Ruin Wardens. The 1v1 base district (keep, home nodes, H1 / S1 / S2 / M1 / houses / rush / wall slots)
  is placed unchanged relative to its keep through `seat_frame` (`map-2v2.md` 2.1), so bot slots, walls and rush slots work.
  Clearances of `map-fill.md` 4.1 / 5.2 / 5.5 and `terrain.md` 4.1.
- **Engine limits (no new river code)**: one river `half_width` per map; 2 banks (`RiverSystem.bank_of`: one river line
  through a centre moat); <= 4 ford / steps circles (ground shader `fords[4]`), <= 16 river segments; fourfold maps need
  straight arms on `x = 0`. Concepts that break a limit say so under "Risks".
- **Kingdom themes are a look, not a bias.** A map's dressing leans on one kingdom's home ground (Fire ash, Ice snow, Nature
  riverbanks, Shadow marsh: the Art Lab R4k grounds). **Gameplay terrain** (`terrain.md` patches) stays near CH's share (~28 %
  of the area) and puts every kingdom's good ground at one objective on each bank. Cosmetic grounds (frost-dusted grass, cold
  cinders, fen moss) must read clearly different from gameplay snow / ash / marsh.
- **Gates**: Map Lab 0 FAIL, N2 / M1-M4 / F1 PASS, score **>= 90**, D1 per seat <= 2 %, crossings >= 4 m of navmesh (C1), no
  main-route choke < 3 m (C2) except named gates; rush matrix of `rush-balance.md` 11 (cells 20-50 %, <= 15 % of rush games
  over before 8:00); Bot Lab kingdom mirror 45-55 % per map. **Trade**: near routes 40-60 m, far routes 110-140 m (gold per
  minute within +-15 % of CH).

Sketches (top-down, north up, every image drawn): `K` keep · `o` home node · `n` natural / pocket / third · `R` rich ·
`T` watchtower · `W` well · `S` shrine · `t` tavern · `p` peddler · `P` post · `D` / `L` Den / Lodge · `w` wallow T1 ·
`N` ford nest T2 · `h` Gloomcap Hollow T2 · `g` stag T3 · `@` lair · `$` cache · `X` crown · `=` bridge · `s` steps ·
`~` water · `#` rock ridge (navmesh block).

## 2. 1v1 concepts
| # | Name | Size | Symmetry | Rush route (CH 152) | Rewards | Pick |
|---|---|---|---|---|---|---|
| A | **Cinderstep Gorge** (Fire ash) | 112 | rot180 | **~114 m** (-25 %) | aggression, harass, rushes | **Recommended** |
| B | **Thawmere Reach** (Ice snow) | 136 | rot180 | **~181 m** (+19 %) | macro, 6 bases, beasts | **Recommended** |
| C | Three Rills (Nature riverbanks) | 124 | mirror_x | ~135 m (-11 %) | map control, points | |
| D | Mirewatch Caldera (Shadow marsh) | 128 | rot180 | ~165 m (+9 %) | timing fights at one centre | |

### A. Cinderstep Gorge (recommended): "A scorched canyon where two gorge bridges put the enemy 20 s away."
```
+--------------------------------------------------------+
|    h    L              @    ~~   P       w             |
|    D        R              ~N                          |
|                   T    $   ~      T       o    K       |
|   g         p              =                    o      |
|  @        W      S    ~~~~~~~~~~                       |
|                    t~~~        ~=~    n     $      P   |
|   P       $     n   ~=~    X   ~~~ t                   |
|                       ~~~~~~~~~~     S      W       @  |
|      o                    ~=              p            |
|        K   o        T     ~    $    T               g  |
|                          ~N               R        D   |
|              w       P   ~     @              L    h   |
+--------------------------------------------------------+
```
- **Layout**: player west `(-40, 32)`, enemy east. The Hollowgorge runs north-south; each side owns a **home gorge bridge**
  33 m from its hub, the lane crosses the Crown Isle, a guarded ford sits at each far end. Natural 32 m out beside the isle;
  rich node in the far corner with the Den, Lodge and hollow. **Biomes**: Fire look (charred heath, cinder drifts,
  ember-veined walls); gameplay: 2 Cinder Scars per side (ash, at the caches), frost at the well (snow), reed marsh at the
  home ford (mud), riverbank all along.
- **Expansions** 4 per side (CH 4). **River** 6 crossings: 2 gorge bridges (5 m decks), 2 Crown Bridges, 2 fords.
  **Points**: home tower (sees its bridge and ford), far tower (sees the enemy's bridge), well, shrine.
- **Camps / beasts**: wallow, ford nest, stag, hollow per side; lairs Direwolf + Grizzlemaw per side (4; CH 8).
  **Trade**: 2 posts per side (west, south spur), routes ~45 / ~115 m.
- **Rush**: 114 m over a gorge bridge (Hound 16 s, CH 22 s); lane 103 m (warded); ford 131 m + nest. Keep -> crown ~51 m.
- **Rewards** early pressure, wizard harass, the Rusher styles; games ~12-16 min. **Risks**: the early-end budget; knobs in order: decks 5 -> 4 m, keeps 3 m back, home tower slot 2 m nearer its bridge.
  Fewer lairs = slower champions. Static ash area <= CH's 130 m².

### B. Thawmere Reach (recommended): "A frozen valley round a warm mere: a safe shelf, a sealed third, the long way round."
```
+----------------------------------------------------------+
|    h     L          @~~       P       w                  |
|                 T     =~                     o   K       |
|    D        R          ~N    T                    o      |
|    P                    ~~           n                   |
|   g     @      W    t    ~~~~~$               ##     n   |
|      n       @       ~~s~~~  ~~~=~~ S   p    $###########|
|                      ~      X     ~                      |
|###########$    p   S ~~=~~~  ~~~s~~       @       n      |
|   n     ##               $~~~~~    t    W      @     g   |
|                   n           ~~                    P    |
|      o                    T    N~          R        D    |
|       K   o                     ~=     T                 |
|                  w       P       ~~@          L     h    |
+----------------------------------------------------------+
```
- **Layout**: corner keeps `(-50, 50)` / `(50, -50)`; the river bends through **Thawmere**, a warm mere (moat r 16, water
  r 13.5-18.5) round a large Crown Isle. Behind each base the **Hearthshelf** (ridge `#`, the base is its only mouth) holds a
  safe pocket node; past the ridge the **Frostgate** third is sealed by a stag (like the Glade Vein). **Biomes**: Ice look
  (snowy heath, frosted pines, steam over the mere); gameplay: 2 snowfields per bank (well, Frostgate), a steam-vent ash scar
  (shelf cache), marsh at the far ford, riverbank round the mere, deep forest in the corner nook.
- **Expansions** home 2 + pocket + natural + third + rich = **6 per side**. **River** 8 crossings: 2 road bridges at the far
  ends, 2 fords with nests, 2 Crown Bridges, 2 Crown Steps. **Points** 2 towers, well, shrine per side.
- **Camps / beasts**: wallow, nest, stag, hollow per side; lairs Tusker, Roc, Grizzlemaw per side (6). **Trade**: 2 posts per
  side, routes ~55 / ~135 m (long, valuable, exposed).
- **Rush**: 181 m over a road bridge (Hound 26 s); isle lane 142 m (warded); ford 162 m + nest. Keep -> crown ~71 m.
- **Rewards** booming, tech, champion parties and beast hunts, late crown fights; games ~18-25 min. **Risks**: turtling (knob: pocket 2 000 -> 1 500); the pocket must never be reachable without passing the own base (4.2);
  ~30 creatures (perf gate).

### C. Three Rills: "Two streams, three strips: whoever owns the Commons owns the game."
```
+--------------------------------------------+  124 m, mirror_x; keeps at the west / east edge middles (+-48, 0). Streams
| P  @     =~   W      ~=     @  P           |  at x = +-18 make a 36 m **Commons**: crown on open ground with wardens,
|  w R   T  ~   S      ~  T   R w            |  2 wells and 2 shrines on the axis. Each stream: 2 bridges + 1 ford.
|  o K o   N~    X     ~N   o K o            |  Nature look (willow fens). 4 expansions, 4 lairs, 2 posts per side;
|  n R   T  ~   S      ~  T   R n            |  rush ~135 m over a bridge, 100 m through a nest ford.
| P  @     =~   W      ~=     @  P           |
+--------------------------------------------+
```
- Rewards map control and capture play. **Risks**: 3 "banks" (the Commons is -1: RiverSystem divider change); mirror_x pairs
  north / south objects per side (more F2 noise); heavy riverbank favours Nature.

### D. Mirewatch Caldera: "A misty caldera lake with one great isle: crown, wells and the hollow in one fight."
```
+--------------------------------------------+  128 m, rot180, corner keeps (+-46, +-46). The moat is a caldera ring
| D h   R    T  ~~~~~~   T   o K             |  (r 26, half 3) round a 23 m isle: crown, 2 wells (+0.3 / s), a hollow.
| L  @  g   =  ~ W  h ~  s   S  P            |  2 causeways + 2 steps onto the isle, 2 road bridges on the arms.
|  P  S  s  ~ h  X  W ~  =  g @  L           |  Shadow look (black fen, mist, dead trees). 4 expansions per side;
| K o   T   ~~~~~~  T    R   h D             |  rush ~165 m via a road bridge, isle lane ~140 m (warded).
+--------------------------------------------+
```
- Rewards timing and army control at one centre. **Risks**: snowball (isle = crown + both wells); a 160 m moat ring = more
  water mesh and moat sectors (perf, RiverSystem); marsh-heavy favours Nature.

## 3. 2v2 concepts
| # | Name | Size | Layout | Facing / diagonal / ally (FH 142 / 187 / 142) | Rewards | Pick |
|---|---|---|---|---|---|---|
| A | **Kinhearth Vale** (Nature riverbanks) | 176 | fourfold, allies side by side | 146 / 152 / **66** | team fights | **Recommended** |
| B | **Gloamspine Divide** (Shadow marsh) | 160 | fourfold, ridge between allies | **133** / 176 / 134 | two lanes, rotations | **Recommended** |
| C | Frostfang Pocket (Ice snow) | 176 | rot180, front + pocket per team | 130 (fronts) | holder + feeder roles | |
| D | Emberwater Cross (Fire ash) | 168 | fourfold, 2 rivers, 4 banks | 150 / 190 / 110 | turtling, bridges | |

### A. Kinhearth Vale (recommended): "Two hearths open onto one green: fight as a team or not at all."
```
+------------------------------------------------------------+
|    @         P           @   ~  @           P         @    |
|          w p        R        =       R        p w          |
|  P             n        T    ~   T        n             P  |
|            $          g      N     g          $            |
|     oK  o        W           ~          W        o  Ko     |
|                     t    ~~~~~~~~    t                     |
|  D       L    $   S     =~   X  ~=     S    $   L       D  |
|                     t    ~~~~~~~~    t                     |
|     oK  o        W           ~          W        o  Ko     |
|            $          g      N     g          $            |
|  P             n        T    ~   T        n             P  |
|          w p        R        =       R        p w          |
|    @         P           @   ~  @           P         @    |
+------------------------------------------------------------+
```
- **Layout**: allies' keeps `(-68, +-30)`, 60 m apart; both districts open onto the **Hearth Green** (ally midline: Den,
  Lodge, cache, shrine). The Broadwater (half width 3) runs north-south; one 10 m **causeway** per side onto the Crown Isle;
  a nest ford `(0, +-40)` and a road bridge `(0, +-74)` join each facing pair. The corners are the **Outer Vales**: each
  seat's rich node, 48 m from the facing enemy's across the road bridge. **Biomes**: Nature look (willow meadows, reed beds,
  wildflower banks); gameplay: riverbank along both arms and the moat, marsh at the fords (Nature, contested), snow at the
  vale lairs (Ice), sand at the home towers (Fire), ash at the green cache (Fire).
- **Expansions** 4 per seat (16). **River** 6 crossings (2 causeways, 2 fords, 2 road bridges). **Points** 4 towers (one per
  seat over its ford and bridge), 4 wells, 2 shrines on the greens.
- **Camps / beasts**: per seat a wallow and a stag (guards the ford approach); 2 ford nests; no hollow (the green is base
  land). Lairs per seat: Vale (Tusker A1 / B1, Direwolf A2 / B2) and Mouth (Roc / Grizzlemaw): 8. **Trade**: 2 posts per seat
  (vale edge, west corner) on a ring road over both road bridges.
- **Rewards**: 2v2 as one team (ally help in ~10 s), big fights at the causeways and fords, flank expansions in the vales. **Risks**: both enemies are equally far over the isle (152 m), so `lane_opponent` uses the ford pairing (A1 <-> B2); a 2v1
  dive is easy to answer, so games may run long (knob: causeways 10 -> 8 m); the natural / Glade rows are level-table, not
  framed (they would overlap the ally).

### B. Gloamspine Divide (recommended): "A spine of drowned crags splits the fen: two lanes, three gates, one crown."
```
+------------------------------------------------------------+
|               w  P      @    =   @      P   w              |
|      K   o             R     ~    R             o   K      |
|     o            p        T  ~  T       p            o     |
| @           $                N               $           @ |
|  P             n      t      ~     t      n             P  |
|       n g          W    ~=~~~~~~=~    W           gn       |
| D S  L####### h#########~    X   ~######### h####### L S D |
|       n g          W    ~=~~~~~~=~    W           gn       |
|  P             n      t      ~     t      n             P  |
| @           $                N               $           @ |
|     o            p        T  ~  T       p            o     |
|      K   o             R     ~    R             o   K      |
|               w  P      @    =   @      P   w              |
+------------------------------------------------------------+
```
- **Layout**: FH's corner bases on a tighter 160 m square (keeps `(+-62, +-62)`, the district framed with `T = (-19, 19)`).
  The **Gloamspine** (ridge on `z = 0`) splits each bank into a south lane (A1 vs B2) and a north lane (A2 vs B1). Allies
  meet through the **Guildgate** (a 6 m lane between Den and Lodge, the shrine in it), the **Hollow Gate** (8 m, a Gloomcap
  Hollow in it) or the Crown Isle (4 Crown Bridges). **Biomes**: Shadow look (black fen, drowned trees, lantern moss);
  gameplay: marsh at both ford approaches and the Hollow Gate, deep forest along the spine (-30 % sight: ambushes), snow in
  the Mouth lair gorge (Ice), ash at each well (Fire).
- **Expansions** home 2 + natural + sealed Glade Vein + rich = 5 per seat (FH rows). **River** 8 crossings (2 road bridges,
  2 nest fords, 4 Crown Bridges). **Points** 4 towers, 4 wells, 2 shrines (in the Guildgates).
- **Camps / beasts**: per seat wallow + stag; 2 nests; 2 hollows (Hollow Gates); lairs Heath + Mouth per seat (8, as FH).
  **Trade**: 2 posts per seat (west, south edge).
- **Rush**: facing keep -> keep **133 m** over the road bridge (Hound 19 s); the diagonal only over the isle (176 m).
- **Rewards**: two tight lanes where helping the ally costs a rotation through a gate; ambush and flank play on the spine. **Risks**: a lane collapses before help arrives (knob: Guildgate 6 -> 8 m); the Guildgate is a designed choke (C2
  exception); ridges need crag art with colliders at adoption.

### C. Frostfang Pocket: "Each team has a front keep on the ice and a pocket keep in the pines."
```
+----------------------------------------------+  176 m, rot180 with 4 seats. Team A: front keep (-40, 34) near the frozen
|  K(pocket B)  n   R   ~    T    o   w   P    |  river, pocket keep (-72, 70) behind it on a safe road; team B mirrored.
|   o  T  K(front B)  =~  S   t   n    $       |  The pocket's expansions are rich but far. Ice look (pack ice, frozen
|       $    n   t   ~=  K(front A)  T  o      |  falls). Rush front-front ~130 m, pocket-front ~180 m.
|  P   w   o    T    ~   R   n  K(pocket A)    |
+----------------------------------------------+
```
- Rewards team roles (the front holds, the pocket feeds and flanks). **Risks**: seats are not interchangeable (Map Lab D1
  must compare front with front: new profile option), bots need role logic, a role choice in the lobby.

### D. Emberwater Cross: "Two rivers cross in a burning lake: four banks, every seat alone."
```
+----------------------------------------------+  168 m, fourfold. Rivers on x = 0 and z = 0 meet in the moat: every
|  K  o    R   =~   R     o  K                 |  quadrant is its own bank; allies meet over 2 bridges on the z = 0
|  P  W   g    ~    g   W   P                  |  stream, enemies over 2 bridges + 1 ford on x = 0. Fire look
|  ~~=~~~~~~~~~X~~~~~~~~~~=~~                  |  (lava-lit lake, cinder banks). Rush facing ~150 m, ally 110 m.
|  P  W   g    ~    g   W   P                  |
|  K  o    R   =~   R     o  K                 |
+----------------------------------------------+
```
- Rewards turtling and bridge control. **Risks**: 4 banks (`bank_of` and the divider rewritten), ford circles over the shader
  limit, allies split by water (weak team play: the opposite of Kinhearth).

## 4. Draft `.map` specs for the recommended maps (World Forge grammar)
First placements, checked by a script for spot-to-spot gaps on every image, **not** for roads: the builder may move a spot
<= 5 m (its images follow) to pass L3 and the `map-fill.md` clearances (camp >= 9 m and point >= 7 m from road centre lines)
and lists each move in the report. `terrain=` on a zone is a proposed key (gameplay patch for TerrainSystem); if the reader
refuses it, keep `biome=` and the adopter maps the zone id prefix (`snow_`, `ash_`, `mud_`, `sand_`, `forest_`). `kind=a|b`
on a lair = per-seat kind (A1 / B1 take `a`, A2 / B2 take `b`), read by the adopter.

### 4.1 `data/maps/cinderstep_gorge.map`
```
map cinderstep_gorge  size=112  symmetry=rot180  title="Cinderstep Gorge (1v1)"  spec=docs/design/new-maps.md
seat 0  name="player (west)"  side=0  frame=identity
seat 1  name="enemy (east)"   side=1  frame=rot180
keep    keep        at=(-40,32)  footprint=6      # CH district moved by (3,-11)
start   hub         at=(-33,25)
node    node_a      at=(-43,23)  amount=2000
node    node_b      at=(-31,35)  amount=2000
node    natural     at=(-22,6)   amount=2500
slot    X1          at=(-29,12)
node    rich        at=(-30,-42) amount=2500
slot    X2          at=(-22,-46)
point   emberwatch  at=(-14,34)  sub=watchtower   # home bridge (0,26) + south ford
point   rimwatch    at=(-18,-36) sub=watchtower   # the enemy's bridge (0,-26)
point   well        at=(-34,-12) sub=well
point   shrine      at=(-20,-18) sub=shrine
camp    wallow      at=(-28,50)  tier=1
camp    nest        at=(-2,42)   tier=2           # in the south ford (image: north ford)
camp    stag        at=(-50,-28) tier=3
camp    hollow      at=(-48,-50) tier=2
guild   den         at=(-48,-38)
guild   lodge       at=(-38,-50)
tavern  tavern      at=(-16,-8)
peddler peddler     at=(-30,-22)
post    cinder_post at=(-49,2)
post    gorge_post  at=(-12,52)
lair    wolf_heath  at=(-51,-12) r=4  kind=direwolf
lair    gorge_den   at=(-8,-52)  r=5  kind=grizzlemaw
cache   cache_scar  at=(-34,2)
cache   cache_far   at=(-8,-36)
crown   crown       at=(0,0)
road  ring  poly=[(-33,25),(-46,4),(-40,-30),(0,-26),(33,-25)]  width=3
road  spur  poly=[(-8,27),(-10,46),(-12,49)]  width=3
road  lane  poly=[(-33,25),(-10.16,7.7)]  width=5
zone  ash_scar   circle((-34,2),4.5)   biome=ash    terrain=ash
zone  ash_far    circle((-8,-36),3.5)  biome=ash    terrain=ash
zone  snow_well  circle((-34,-12),5)   biome=snow   terrain=snow
zone  mud_ford   circle((-6,44),3)     biome=marsh  terrain=mud
river north  poly=[(4,-58),(2,-40),(0,-26),(0,-12.75)]  half_width=2.5
river south  poly=[(-4,58),(-2,40),(0,26),(0,12.75)]    half_width=2.5
moat  center=(0,0)  radius=12.75  half_width=1.75
crossing gorge_s  kind=bridge_road  at=(0,26)   width=5  length=8  dir=(1,0)
crossing gorge_n  kind=bridge_road  at=(0,-26)  width=5  length=8  dir=(1,0)
crossing ford_s   kind=ford  at=(-2,42)  width=7  dir=(-0.11,0.99)
crossing ford_n   kind=ford  at=(2,-42)  width=7  dir=(-0.11,0.99)
crossing crown_w  kind=bridge_lane  at=(-10.16,7.7)  width=8  length=6.5  dir=(-0.797,0.604)
crossing crown_e  kind=bridge_lane  at=(10.16,-7.7)  width=8  length=6.5  dir=(0.797,-0.604)
```
**Map Lab targets** (unit paths): keep -> enemy keep over the lane 100-108 m, over a gorge bridge 110-118; keep -> own gorge
bridge 38-44, -> the enemy's 70-78; natural 30-36; crown 48-56; score >= 90, M1-M4 / F1 PASS.

### 4.2 `data/maps/thawmere_reach.map`
```
map thawmere_reach  size=136  symmetry=rot180  title="Thawmere Reach (1v1)"  spec=docs/design/new-maps.md
seat 0  name="player (south-west)"  side=0  frame=identity
seat 1  name="enemy (north-east)"   side=1  frame=rot180
keep    keep        at=(-50,50)  footprint=6      # CH district moved by (-7,7)
start   hub         at=(-43,43)
node    node_a      at=(-53,41)  amount=2000
node    node_b      at=(-41,53)  amount=2000
node    pocket      at=(-60,20)  amount=2000      # Hearthshelf
slot    X0          at=(-52,24)
node    natural     at=(-22,28)  amount=2500
slot    X1          at=(-28,34)
node    third       at=(-52,-8)  amount=2000      # Frostgate, sealed by the stag
slot    X3          at=(-54,0)
node    rich        at=(-36,-44) amount=2500
slot    X2          at=(-28,-40)
block   ridge_n     at=(-57,9)   size=(22,3)  yaw=0
block   ridge_e     at=(-45,17)  size=(3,14)  yaw=0
point   hearthwatch at=(-4,44)   sub=watchtower   # home road bridge (13,56) + south ford
point   rimewatch   at=(-26,-50) sub=watchtower
point   well        at=(-30,-20) sub=well
point   shrine      at=(-20,6)   sub=shrine
camp    wallow      at=(-24,58)  tier=1
camp    nest        at=(-9,-40)  tier=2           # in the north ford (image: south ford)
camp    stag        at=(-60,-16) tier=3
camp    hollow      at=(-58,-58) tier=2
guild   den         at=(-58,-44)
guild   lodge       at=(-44,-58)
tavern  tavern      at=(-18,-18)
peddler peddler     at=(-30,14)
post    frostgate_post at=(-58,-34)
post    mereside_post  at=(-6,60)
lair    vent_heath  at=(-46,-24) r=4  kind=tusker
lair    icecrest    at=(-34,-6)  r=4  kind=roc
lair    mouth_den   at=(-18,-64) r=5  kind=grizzlemaw
cache   cache_shelf at=(-40,10)
cache   cache_mere  at=(-6,22)
crown   crown       at=(0,0)
road  ring  poly=[(-43,43),(-38,10),(-40,-22),(-54,-32),(-40,-52),(-13,-56),(43,-43)]  width=3
road  lane  poly=[(-43,43),(-11.3,11.3)]  width=5
zone  snow_well    circle((-30,-20),5.5)  biome=snow   terrain=snow
zone  snow_gate    circle((-54,-12),5.5)  biome=snow   terrain=snow
zone  ash_vent     circle((-40,10),4)     biome=ash    terrain=ash
zone  mud_ford     circle((-14,-40),3)    biome=marsh  terrain=mud
zone  forest_nook  circle((-56,-56),6)    biome=old_wood  terrain=forest
river north  poly=[(-16,-70),(-13,-56),(-9,-40),(-6,-28),(-3.5,-15.6)]  half_width=2.5
river south  poly=[(16,70),(13,56),(9,40),(6,28),(3.5,15.6)]            half_width=2.5
moat  center=(0,0)  radius=16  half_width=2.5
crossing bridge_n  kind=bridge_road  at=(-13,-56)  width=6  length=9  dir=(1,0)
crossing bridge_s  kind=bridge_road  at=(13,56)    width=6  length=9  dir=(-1,0)
crossing ford_n    kind=ford  at=(-9,-40)  width=7  dir=(0.24,0.97)
crossing ford_s    kind=ford  at=(9,40)    width=7  dir=(0.24,0.97)
crossing crown_w   kind=bridge_lane  at=(-11.3,11.3)  width=8  length=7.5  dir=(-0.707,0.707)
crossing crown_e   kind=bridge_lane  at=(11.3,-11.3)  width=8  length=7.5  dir=(0.707,-0.707)
crossing steps_nw  kind=steps  at=(-11.3,-11.3)  width=6  dir=(-0.707,-0.707)
crossing steps_se  kind=steps  at=(11.3,11.3)    width=6  dir=(0.707,0.707)
```
**Map Lab targets**: keep -> enemy keep over the lane 136-148 m, over a road bridge 175-188; keep -> pocket 28-36 and
**enemy keep -> pocket >= enemy keep -> own hub + 5 m** (the shelf opens only into the base); natural 32-38; third 55-64;
crown 66-76; shelf mouth >= 10 m of navmesh; score >= 90, M1-M4 / F1 PASS.

### 4.3 `data/maps/kinhearth_vale.map`
```
map kinhearth_vale  size=176  symmetry=fourfold  title="Kinhearth Vale (2v2)"  spec=docs/design/new-maps.md
seat 0  name="player (A1 west-south)"   side=0  frame=identity
seat 3  name="ally (A2 west-north)"     side=0  frame=mirror_z
seat 1  name="enemy (B1 east-north)"    side=1  frame=rot180
seat 4  name="enemy 2 (B2 east-south)"  side=1  frame=mirror_x
keep    keep        at=(-68,30)  footprint=6      # district framed; natural / Glade rows are level-table
start   hub         at=(-61,23)
node    node_a      at=(-71,21)  amount=2000
node    node_b      at=(-59,33)  amount=2000
node    natural     at=(-40,48)  amount=2500
slot    X1          at=(-46,54)
node    rich        at=(-24,72)  amount=2500      # Outer Vale; the facing rich is 48 m away over the bridge
slot    X2          at=(-32,66)
point   vale_watch  at=(-12,58)  sub=watchtower   # ford (0,40) + road bridge (0,74)
point   well        at=(-34,30)  sub=well
camp    wallow      at=(-58,72)  tier=1
camp    stag        at=(-18,40)  tier=3           # guards the ford approach
tavern  tavern      at=(-26,14)
peddler peddler     at=(-50,64)
post    vale_post   at=(-46,82)
post    corner_post at=(-82,58)
lair    vale_lair   at=(-74,78)  r=4  kind=tusker|direwolf
lair    mouth_lair  at=(-10,82)  r=5  kind=roc|grizzlemaw
cache   cache       at=(-50,42)
guild   den         at=(-82,0)                    # Hearth Green (z = 0: once per side)
guild   lodge       at=(-58,0)
cache   green_cache at=(-44,0)
point   shrine      at=(-32,0)   sub=shrine
crown   crown       at=(0,0)
camp    ford_nest   at=(0,40)    tier=2           # on x = 0: once per ford
road  ring    poly=[(-61,23),(-62,50),(-44,78),(0,74)]  width=3
road  corner  poly=[(-62,50),(-78,58)]  width=3
road  green   poly=[(-61,23),(-52,8),(-52,0)]  width=3
road  lane    poly=[(-61,23),(-12.75,0)]  width=5
zone  mud_ford    circle((-5,40),3)    biome=marsh  terrain=mud
zone  snow_vale   circle((-74,78),5)   biome=snow   terrain=snow
zone  sand_watch  circle((-12,58),5)   biome=sand   terrain=sand
zone  ash_green   circle((-44,0),4)    biome=ash    terrain=ash
river north  poly=[(0,-90),(0,-60),(0,-30),(0,-12.75)]  half_width=3
river south  poly=[(0,12.75),(0,30),(0,60),(0,90)]      half_width=3
moat  center=(0,0)  radius=12.75  half_width=1.75
crossing bridge_road_s  kind=bridge_road  at=(0,74)   width=6  length=10  dir=(1,0)
crossing bridge_road_n  kind=bridge_road  at=(0,-74)  width=6  length=10  dir=(1,0)
crossing ford_s     kind=ford  at=(0,40)   width=7  dir=(0,1)
crossing ford_n     kind=ford  at=(0,-40)  width=7  dir=(0,1)
crossing causeway_w kind=bridge_lane  at=(-12.75,0)  width=10  length=6.5  dir=(1,0)
crossing causeway_e kind=bridge_lane  at=(12.75,0)   width=10  length=6.5  dir=(1,0)
```
**Map Lab targets** (4 seats): keep -> ally keep 60-72 m (never over water); -> facing enemy via the ford 140-152, via a
causeway 146-158, via the road bridge 170-185; crown 70-82; natural 30-36; rich 55-62; D1 all seats <= 2 %; score >= 90,
M1-M4 / F1 PASS.

### 4.4 `data/maps/gloamspine_divide.map`
```
map gloamspine_divide  size=160  symmetry=fourfold  title="Gloamspine Divide (2v2)"  spec=docs/design/new-maps.md
seat 0  name="player (A1 south-west)"   side=0  frame=identity
seat 3  name="ally (A2 north-west)"     side=0  frame=mirror_z
seat 1  name="enemy (B1 north-east)"    side=1  frame=rot180
seat 4  name="enemy 2 (B2 south-east)"  side=1  frame=mirror_x
keep    keep        at=(-62,62)  footprint=6      # FH framed district with T = (-19,19)
start   hub         at=(-55,55)
node    node_a      at=(-65,53)  amount=2000
node    node_b      at=(-53,65)  amount=2000
node    natural     at=(-35,25)  amount=2500      # framed: X1 (-42,28), S3 (-38,20)
node    glade_vein  at=(-60,15.5) amount=1500     # framed: X3 (-58,24); sealed by the stag
camp    stag        at=(-56,9)   tier=3
node    rich        at=(-14,58)  amount=2500
slot    X2          at=(-22,60)
point   fenwatch    at=(-8,50)   sub=watchtower   # ford (0,36) + road bridge (0,68)
point   well        at=(-26,12)  sub=well
camp    wallow      at=(-40,72)  tier=1
tavern  tavern      at=(-18,22)
peddler peddler     at=(-30,44)
post    fen_post    at=(-74,30)
post    spine_post  at=(-30,74)
lair    heath_lair  at=(-77,42)  r=4  kind=tusker|direwolf
lair    mouth_lair  at=(-12,76)  r=5  kind=roc|grizzlemaw
cache   cache       at=(-44,40)
guild   den         at=(-76,0)                    # the Gloamspine (z = 0: once per side); door east
guild   lodge       at=(-64,0)                    # door west, across the 6 m Guildgate
point   shrine      at=(-70,0)   sub=shrine       # walk-through, inside the Guildgate
block   spine_m     at=(-52,0)   size=(16,4)  yaw=0
camp    hollow      at=(-40,0)   tier=2           # the Hollow Gate (x -44..-36)
block   spine_e     at=(-25,0)   size=(22,4)  yaw=0   # reaches the moat bank: no gap at the isle
crown   crown       at=(0,0)
camp    ford_nest   at=(0,36)    tier=2
road  ring   poly=[(-55,55),(-72,30),(-70,4),(-70,0)]  width=3
road  south  poly=[(-55,55),(-30,70),(0,68)]  width=3
road  lane   poly=[(-55,55),(-9.02,9.02)]  width=5
zone  mud_ford      circle((-5,36),3)       biome=marsh     terrain=mud
zone  mud_gate      circle((-40,4),3)       biome=marsh     terrain=mud
zone  forest_spine  rect((-60,2),(-44,8))   biome=old_wood  terrain=forest
zone  snow_mouth    circle((-12,76),5)      biome=snow      terrain=snow
zone  ash_well      circle((-26,12),4)      biome=ash       terrain=ash
river north  poly=[(0,-82),(0,-40),(0,-12.75)]  half_width=2.5
river south  poly=[(0,12.75),(0,40),(0,82)]     half_width=2.5
moat  center=(0,0)  radius=12.75  half_width=1.75
crossing bridge_road_s  kind=bridge_road  at=(0,68)   width=6  length=9  dir=(1,0)
crossing bridge_road_n  kind=bridge_road  at=(0,-68)  width=6  length=9  dir=(1,0)
crossing ford_s    kind=ford  at=(0,36)   width=7  dir=(0,1)
crossing ford_n    kind=ford  at=(0,-36)  width=7  dir=(0,1)
crossing crown_sw  kind=bridge_lane  at=(-9.02,9.02)   width=8  length=6.5  dir=(-1,1)
crossing crown_nw  kind=bridge_lane  at=(-9.02,-9.02)  width=8  length=6.5  dir=(-1,-1)
crossing crown_ne  kind=bridge_lane  at=(9.02,-9.02)   width=8  length=6.5  dir=(1,-1)
crossing crown_se  kind=bridge_lane  at=(9.02,9.02)    width=8  length=6.5  dir=(1,1)
```
**Map Lab targets** (4 seats): keep -> facing enemy via the road bridge 128-140 m, via the ford 130-142; -> diagonal enemy
170-182 (isle only); -> ally via a gate 128-140, via the isle 160-172; natural 44-50; crown 88-96; Guildgate >= 5 m of navmesh
(named C2 exception), Hollow Gate >= 7 m; **no A1 -> A2 path avoiding the gates and the isle** (spine meets the moat);
D1 <= 2 %; score >= 90, M1-M4 / F1 PASS.

## 5. Build tasks (lead places them in `waves.md`; after step 20: `MapInfo`, seat API, `MapLayout` adoption)
Per map: spec -> Map Lab sign-off -> art and scene adoption in parallel -> bots -> gates -> playtest. Gorge and Kinhearth first
(Q5). Every task keeps the smoke / perf tests, Crown Hollow and Fourfold Hollow unchanged, and follows `map-lab.md` 5.
| Id | Owner | Task | Done when |
|---|---|---|---|
| NM.F1-F4 | four-wizards-high (owns `data/maps/`), medium | `data/maps/<id>.map` from 4.x; `run_world_forge.ps1 map <id>`; spot moves <= 5 m for L3 / clearances; hand-check roads | Exit 0; LAB score >= 90; M1-M4 / F1 PASS; every 4.x target met (table in `report_map.md`); `layout.png` + `heatmap.png`; moves listed |
| NM.D2 | game-designer | Review scorecards and heat maps, fix the 4.x numbers, final distance tables | Sign-off line per map here |
| NM.C1 [H] | systems-coder | Generic layout levels `SkirmishMap` (1v1) / `Skirmish2v2Map` built from a `MapLayout` (`layout_path`): spots, river, crossings, roads, zones -> TerrainSystem patches, `LAIR_SPOTS` with per-seat kinds, blocks -> ridge colliders (layer 1, before the bake); scenes `scenes/maps/<id>.tscn`; CH / FH keep their scenes | Each scene loads headless, all seats spawn; 2 / 4 bots play 10 min with 0 script errors; live Map Lab (`scene=`) >= 90 and within 2 points of the preview; `export-map` round trip R1 <= 0.1 m; `FAIRNESS OK` per map |
| NM.A1 | ai-coder | Bots read the map from the layout: scout path, rush bridge + staging, creep / capture order, shrine play, `lane_opponent` (Kinhearth: ford pairing), gate rotations (Gloamspine); no CH constants | Bot Lab mirror within 1.1x per map; Gorge rush matrix in band, <= 15 % over before 8:00; 4-bot 2v2 ends with a winner on both maps |
| NM.V1-V4 | tech-artist, one agent per map, medium | Map edge + horizon for the size, ground / biome params, theme decor set (scorched heath / frost heath + steam / riverland / fen), crag meshes on the blocks, lobby preview 512 x 512 | Art Lab R4k PASS; decor <= 12 000 instances, <= 140 draw nodes; no collider added except ridges; CH look unchanged |
| NM.U1 | ui-designer, then ui-coder | Lobby map picker per mode: preview, size, hook line, "Random"; `GameSettings.map_id` | 3 maps per mode listed; the choice reaches the level |
| NM.L1 | lead | Per map: smoke with bots, perf (1v1 `PERF OK`; 2v2 300 units <= 15 ms), Bot Lab kingdom mirror 45-55 %, playtest build | All gates green; user playtest |

## 6. Questions for the user (recommendation first)
1. **Which four maps?** (a) **1v1 Cinderstep Gorge + Thawmere Reach, 2v2 Kinhearth Vale + Gloamspine Divide** (recommended:
   one small fast and one big slow 1v1; one "fight together" and one "two lanes" 2v2) (b) other letters from sections 2 / 3.
2. **Kingdom themes?** (a) **The look only**: each map shows one kingdom's home ground, every kingdom gets good ground on every
   map (recommended) (b) Strong home ground: each map favours its kingdom a little (c) No themes.
3. **A rush-friendly small map?** (a) **Yes**: Cinderstep Gorge, enemy ~20 s away, today's rush defences (Bell, Garrison fire),
   tuned by the bots' rush tests (recommended) (b) No: every map at least as far as Crown Hollow.
4. **Choosing a map?** (a) **Pick in the lobby, or "Random"** (recommended) (b) Always random (c) Always pick.
5. **Build order?** (a) **Gorge + Kinhearth first, playtest, then Thawmere + Gloamspine** (recommended) (b) All four at once.

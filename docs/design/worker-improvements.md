# Worker improvements: the Roadside Post, repair after pillage, and worker Auto

Task 17b.D1, written 2026-09-26. Source of truth for step 17b (tasks in section 15). User request (`docs/plan/waves.md`,
step 17b): keep gathering exactly as it is (crystal node -> keep trips) and **add** improvements that workers build on the
map, that enemies can **pillage** (disabled, not destroyed) and workers **repair**, plus an **Auto** button so a worker picks
gather / repair / build by itself. The only improvement for now is a trade improvement on the caravan roads that pays more
gold per caravan trip. Inspired by the *idea* of tile improvements in classic 4X games; every name, rule, number and look
here is our own. Metres, seconds, `m:ss`; positions `(x, z)` on Crown Hollow, point-mirrored like `market-trade.md`
(everything at `(x, z)` on the player (west-bank) side exists at `(-x, -z)` on the enemy side). Numbers build on
`market-trade.md` (step 10), `map-fill.md` (step 12), `grand-market.md` (step 17), `buildings.md`, `economy.md`.

## 0. Names (no clash)
| Thing | Name | Not to confuse with |
|---|---|---|
| The improvement | **Roadside Post** (one type for all kingdoms, team colours) | the 4 neutral **trading posts** (Heron Ford, Millstone Cross, Lantern Wharf, Saltgate), the **Bazaar** (market), the step-17 **Grand Market** |
| The spots it is built on | **roadside plots** (8 on the map, 4 per bank) | the **Wayshrines** (capture points) and the **waystones** (road decor) |
| The worker mode | **Auto** | nothing (the word is not used elsewhere in the game) |
| The enemy action | **pillage** (the post is disabled, never destroyed by damage) | "destroy" (buildings), "rob" (Magpies on caravans) |

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| What is built | A **Roadside Post**: 2 x 2 roadside booth, **75 crystals, 25 s**, 350 integrity, pop 0, needs your **completed Bazaar** | Cheap enough to be an obvious upgrade for a trading side, dear enough to be a real choice before 8:00 |
| Where | Only on **roadside plots**: 8 fixed, mirrored spots beside the ring road (2 home plots and 2 corner plots per bank, section 2). You may build on a plot only if one of **your** caravan routes uses its road | Fair (mirrored), readable (marked on the ground), easy for the bot and the tests; no "wall the enemy's road" denial |
| How many | **Max 4 per team** (sites, intact and pillaged all count) | A trading side can take its 4 own-bank plots, or trade 2 of them for the risky enemy-bank corners |
| Bonus | Every **intact** own post on a trip's road adds **`round(4 + 0.06 x V)`** gold to that trip (V = the route value). **Max 3 posts per trip.** Locked with the cargo at the trading post, paid on delivery | +21-33 % on near routes, +25-28 % on far routes (section 4); ~+25 % of trade income with a full set, about +5 % of a side's total income |
| Pillage | Enemy soldiers, wizards, champions and **Magpies** can attack it; at 0 integrity it is **pillaged** (disabled, stays on the plot). The pillager's team gets **30 gold** (Magpies carry it as loot) | The user's "disabled, not destroyed"; a small reward makes raiding a post a real option |
| Repair | A worker repairs it for **free** in **15 s** (1 / 1.5 / 2 speed with 1-3 workers, like construction). Left pillaged for **180 s** it collapses and frees the plot | Downtime + the worker's walk is the cost; the collapse stops dead posts blocking contested plots forever (user Q4) |
| Collapse gold (user, Q4) | A collapsing post drops a **ruins pile of 60 gold** (a LootSack, 90 s) that **anyone** can pick up. Demolishing it yourself drops nothing | A reason to fight over a ruin instead of forgetting it |
| Magpies camp ruins (user, Q4) | Once a post is pillaged, a Magpie band **guards** it: it attacks repair crews, re-pillages a half-repaired post and grabs the pile when the post falls. It gives up against a real escort (20 s), a tower within 20 m, heavy losses or after 240 s (section 5.4) | Smart thieves: an unescorted repair near a camp fails, so the owner must escort, build a tower, send champions or write the post off |
| Auto | Per-worker toggle, key **P**: finish an unattended own site within 40 m > staff a blocked building (step 18, crew slot only) > repair own posts > build a Roadside Post on a free plot of an active route > gather (the order of `building-levels.md` 5.4, plus new posts). At most **3** Auto workers per team away from mining at once (staff not counted) | The user's Auto button; it never walks into danger and never takes a worker carrying crystals |
| Keys | **P** = Auto (workers selected, card r2c3), build menu **B then P** = Roadside Post, right-click an own damaged / pillaged post with workers = repair | Step 18 takes I / O / L when a building or workers are selected; P is free outside cutscenes (checked in `CLAUDE.md`, all `docs/design/*.md` and `scripts/`). The build menu re-uses letters of the worker card, as C (Stop / Spire) and B (Build / Bazaar) already do |

## 2. Roadside plots (map; systems 17b.C1)
### 2.1 The 8 plots
Each plot belongs to one **ring-road segment** (`market-trade.md` 2.1). A post on it serves every caravan trip whose road
(the ring path from the team's hub to the trading post door) uses that segment, whatever the Bazaar's position.
| id | Name | Centre (2 x 2, even coordinates) | Segment | Bank | Used by (player caravans / enemy caravans) |
|---|---|---|---|---|---|
| `plot_heron_road` | Heron Road | `(-38, 18)` | `hub - w_door` | west (player) | Heron Ford (near), Saltgate (far) / - |
| `plot_millstone_road` | Millstone Road | `(-20, 48)` | `hub - s_door` | west | Millstone Cross (near), Lantern Wharf (far) / - |
| `plot_west_bend` | West Bend | `(-42, -26)` | `w_door - nw1` | west | Saltgate (far) / Heron Ford (far) |
| `plot_north_bend` | North Bend | `(-32, -42)` | `nw2 - n_door` (west of Saltgate Bridge) | west | Saltgate (far) / Heron Ford (far) |
| `plot_lantern_road` | Lantern Road | `(38, -18)` | `hub_e - e_door` | east (enemy) | - / Lantern Wharf (near), Millstone Cross (far) |
| `plot_saltgate_road` | Saltgate Road | `(20, -48)` | `hub_e - n_door` | east | - / Saltgate (near), Heron Ford (far) |
| `plot_east_bend` | East Bend | `(42, 26)` | `e_door - se1` | east | Lantern Wharf (far) / Millstone Cross (far) |
| `plot_south_bend` | South Bend | `(32, 42)` | `se2 - s_door` (east of Millstone Bridge) | east | Lantern Wharf (far) / Millstone Cross (far) |
- **Home plots** (Heron / Millstone Road for the player, Lantern / Saltgate Road for the enemy) serve only their own side:
  the other side can never build there (`"No route of yours passes here"`).
- **Bend plots** serve one far route of each side: whoever builds first owns the plot. Your own-bank bends are fairly safe;
  the other bank's bends sit next to the enemy's rich corner (the far-route gamble of `market-trade.md`).
- Per team: 6 buildable plots (2 home + 2 own bends + 2 enemy-bank bends), max 4 posts.

### 2.2 Clearances (checked by the 17b.C1 test; player side, the mirror is identical)
| Plot | Road centre line | Nearest things |
|---|---|---|
| Heron Road `(-38, 18)` | 4.4 m | ambush spot A1 6.7 m · tower slot S1 11.0 · Bazaar slot M1 11.4 (footprint gap 2 m) · Glade hall X3 13.0 · West Heath lair centre 15.8 |
| Millstone Road `(-20, 48)` | 5.7 m | A2 6.4 · hall slot H1 7.6 (footprint gap 2 m) · Bristleback Wallow 10.8 (> 8 m camp rule) · node b 14.1 · Lair slot T3 14.8 |
| West Bend `(-42, -26)` | 6.4 m | A3 7.2 · rich hall X2 `(-41, -33)` 7.1 (footprint gap 2 m) · Colossus Crag lair edge 8.6 (beasts ignore buildings and workers: accepted) · Mossmere Well 12.2 · W2 8.9 · Ford hall X5 13.0 |
| North Bend `(-32, -42)` | 6.3 m | tower slot S4 `(-37, -45)` 5.8 (footprint gap 2 m) · rich node 8.2 (>= 4 rule) · Rookwatch 8.1 (>= 8 m point rule) · Old Wood Den lair edge 8.4 (accepted) · Saltgate Bridge 21 (> 8 m crossing rule) · A4 11.7 |
- Rules for any map (campaign maps give their plots in `TradeNetwork.setup`): centre **4-7 m** from its segment's centre line
  (the footprint never touches the 3 m road paint), plots **>= 18 m** apart, **>= 8 m** from trading-post doors, guild doors,
  crossings and camp spots, footprint **>= 2 m** from every build slot footprint, never inside a capture circle.
- If a check fails in the real scene (grid, navmesh), shift the plot **up to 2 m along its segment**, keep the mirror, and
  report the new coordinates to the designer.
- The waystone row (10.V10) skips 4 m around each plot. Trees / rocks: the plot is cleared like a build slot (r 3).

### 2.3 Look, fog, minimap
- A free plot shows a **surveyor's stake** with a blank board and a ring of 3 stones (17b.V1): readable at 40 m, no collider,
  no footprint block while free (units walk over it).
- Plots are ground dressing: shown once the cell is explored, like roads. Posts on them are buildings: seen by fog like any
  building (enemy posts keep their last-seen state).
- Minimap: free plot = 3 x 3 hollow diamond `(0.85, 0.65, 0.30)` (the road colour family), once explored.

## 3. The Roadside Post (systems 17b.C1)
### 3.1 Numbers (`data/buildings/roadside_post.tres`)
| id | Name | Cost | Build time | Integrity (max_hp) | Armor | Footprint | Height | Sight | Pop | kill_xp (pillage) | Counts for defeat |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `roadside_post` | Roadside Post | **75 crystals** | **25 s** | **350** | 0 | 2 x 2 | ~4 m | **8** (intact only) | 0 | **15** | **No** |
- One type for every kingdom (`faction &"common"`: `BuildingType.buildable_for(faction)` adds it for every kingdom); team
  colour on the awning and pennant. Kingdom building traits (Ice x1.2 HP, Nature x0.9 HP and idle regen) do **not** apply;
  the **Masons' Charter** does (x1.15: 402 integrity).
- Not a drop-off, not a shop, trains nothing. Collision layer 2 (clickable), groups `"buildings"` and `"roadside_posts"`.
- Sight 8 while intact (a small fog source over the road: you see Magpies lurking at the nearby ambush spot); 0 when pillaged.
- Construction: the normal site rules (`buildings.md`: 10 % -> 100 % HP, 1 / 1.5 / 2 speed, Delete = cancel with 75 %
  refund). A site is attackable and destroyed at 0 like any site (no pillage state for sites, no reward).

### 3.2 Placement (`BuildGrid.check`, new field `BuildingType.plot_only := true`)
The ghost **snaps to the nearest roadside plot within 8 m** of the cursor. Refusals, in this order (after the existing
"Outside the map" / "Unexplored" / "Blocked by an enemy unit" checks, before crystals):
| Rule | Message |
|---|---|
| The ghost is on a plot | `Build it on a roadside plot` |
| The plot is free (no post or site of any team) | `Plot taken` |
| One of the team's ring paths (hub -> any trading post door) uses the plot's segment | `No route of yours passes here` |
| The team has a completed, living Bazaar | `Needs a Bazaar` |
| Fewer than 4 own Roadside Posts (sites, intact, pillaged) | `Only 4 Roadside Posts` |
| `Economy.can_afford(75)` | `Not enough crystals` |
- Trade off (`Skirmish.trade_enabled = false`, missions): no plots, the build menu hides the button.
- Before 4:00 you may build (the Bazaar is the gate); the bonus only exists once caravans trade (4:00).

### 3.3 States
| State | Integrity | Bonus | Sight | Targetable | Look |
|---|---|---|---|---|---|
| `site` | 10-100 % while built | No | 0 | Yes (dies at 0, no reward) | Scaffold (normal construction look) |
| `intact` | > 0 | **Yes** | 8 | Yes | Lantern lit, awning up, sign swinging (section 13) |
| `pillaged` | 0 (then rising while repaired) | No | 0 | **No** (units drop it as a target) until a repair starts | Roof caved, awning torn, lantern dark, thin smoke |
| `repairing` (a pillaged post with repair progress > 0) | = progress x max | No | 0 | Yes: a hit that brings it back to 0 stops the repair (no new reward) | Scaffold planks over the ruin, smoke fades with progress |
- A pillaged post counts for the team's limit of 4 and blocks the plot. After **180 s** without any repair progress it
  **collapses**: removed (navmesh rebake), plot free, no refund, and it drops the **ruins pile** (60 gold, section 5.4). Any
  repair progress restarts the 180 s.
- Owner's post selected: **Delete** = demolish (press twice within 2 s; no refund), frees the plot at once and drops
  **no** pile (the owner's way to deny the gold to a camping band).

## 4. The gold bonus (systems 17b.C1: TradeNetwork + Caravan)
### 4.1 Rule
- Bonus per post: **`round(4 + 0.06 x V)`** gold, V = the route value of the trip (`market-trade.md` 4.3), from the
  **trading post the caravan trades at**.
- Posts counted for a trip: the team's own **intact** Roadside Posts on plots whose segment the trip's ring path uses;
  **max 3** (the ring path from the team's hub to the door never uses more than 3 own plots on Crown Hollow anyway; the cap
  guards campaign maps). Enemy posts on your road give you nothing.
- **When**: counted at the moment the caravan finishes trading (`_finish_trade`), added to the cargo together with V and
  locked; paid with the cargo on delivery (`GoldBank.add(cargo, &"trade")`). A post pillaged after that moment does not take
  the bonus back; a post pillaged before it simply does not count. Robbery, the 50 % loot sack and Magpie weights all see
  the full cargo (bonus included).
- Cosmetic: a loaded caravan passing within 10 m of a post counted for its trip triggers `play_toll()` and the `post_toll`
  VFX (coins hop to the sign), own and visible only, max once per trip per post.
- Ledger: `TradeNetwork.record_post_bonus(team, post, amount)` at delivery, per post (panel "paid last 3 min", end screen).

### 4.2 Numbers against today's caravan income (from the M1 Bazaar; the enemy's are the mirror)
| Route | V | Plots on its road (own bank / enemy bank) | Bonus per post | Max per trip | Trip | Gold / min per caravan: today -> full posts |
|---|---|---|---|---|---|---|
| Heron Ford (near) | 15 | Heron Road | 5 | **+5 -> 20** (+33 %) | 17.9 s | 50 -> **67** |
| Millstone Cross (near) | 28 | Millstone Road | 6 | **+6 -> 34** (+21 %) | 30.0 s | 56 -> **68** |
| Saltgate (far) | 119 | Heron Road, West Bend, North Bend | 11 | **+33 -> 152** (+28 %) | 68.4 s | 104 -> **133** |
| Lantern Wharf (far) | 154 | Millstone Road / East Bend, South Bend | 13 | **+39 -> 193** (+25 %) | 80.5 s | 115 -> **144** |

| Set-up (one side) | Posts (crystals) | Trade gold / min: before -> after | Gain | Payback (gold at the 100 -> 80 exchange rate) |
|---|---|---|---|---|
| Normal bot mid game: 4 caravans on Millstone Cross | Millstone Road (75) | 224 -> 272 | **+48 (+21 %)** | ~2.0 min |
| 6 caravans near (Millstone) | Millstone Road (75) | 336 -> 408 | +72 (+21 %) | ~1.3 min |
| Late: 3 near Millstone + 3 far Saltgate | Heron Road, Millstone Road, West Bend, North Bend (300) | 481 -> 604 | **+123 (+26 %)** | ~3.0 min |
| Greedy max: 6 far Lantern Wharf | Millstone Road + the two enemy-bank bends (225) | 689 -> 863 | +174 (+25 %) | ~1.6 min, if the posts deep in the enemy half survive |
- **Worth it**: one home post pays back in about 2 minutes of normal trading and costs no pop; a post is as good as one extra
  caravan on a busy near road, and it is the only way to grow trade past the 6-caravan cap.
- **Not dominant**: capped at 4 posts and 3 per trip; the gain is ~+25 % of trade income, which is ~20-30 % of a trading
  side's income after 10:30, so **~+5 % of total income**. Every post is a pillage target worth 30 gold to the enemy, and the
  big gains sit on the far routes and the bends (exposed).

## 5. Pillage
### 5.1 Who, how, how long
| Rule | Value |
|---|---|
| Who can | Enemy soldiers, wizards, champions (their brains may target a post as a building), **Magpies** (a band target, section 8). **Not**: towers and keeps (they never target Roadside Posts: no turret camping a plot), caravans, workers, trackers, camp creatures, beasts |
| How | An intact post (or one being repaired) is an attack target like a building: explicit attack orders, attack-move and auto-aggro (buildings only when no enemy unit is within `aggro_range`, `buildings.md`). Spells and abilities damage it like a building |
| When it hits 0 | It becomes **pillaged**, not destroyed. Units drop it as a target at once (`is_targetable()` false) |
| How long (350 integrity) | 2 Magpies (18 DPS) ~19.5 s · 3 Magpies ~13 s · 1 Flame Guard-class soldier ~30-35 s · 6 soldiers ~6 s · an L3 wizard's auto-attacks ~25 s (a Fireball helps) |
| Under attack alert | Owner: `Your Roadside Post is under attack` (max once per 20 s per post) + minimap ping |

### 5.2 Reward and anti-abuse
| Rule | Value |
|---|---|
| Pillager's team (killing-blow credit, like a building kill) | **+30 gold** (`GoldBank.add(30, &"loot")`); normal victim XP / essence for kill_xp **15** (`levels.md` victim row "Roadside Post (pillaged) 15"); message `Pillaged an enemy Roadside Post: +30 gold` |
| Magpies | The 30 gold is split between the band's living Magpies within 12 m as carried loot (max 60 each, `market-trade.md` 5.1); dropped as a loot sack if they die |
| Once per 120 s per post | A post pillaged, half-repaired and knocked down again inside 120 s pays nothing the second time (no farming a repair loop) |
| Trade off | No gold reward (no GoldBank), XP / essence still paid (posts cannot exist with trade off anyway) |

### 5.3 What it looks like
- Hits: splinter sparks (the normal building hit flash), the integrity bar shows under the post while damaged (like any
  building HP bar, label `Integrity`).
- At 0: `play_pillage()` (roof beam snaps, awning tears, lantern falls and goes dark, crates burst) + `post_pillage` VFX
  (splinters + ember puff, 0.8 s), then the pillaged model with a thin looping `post_smoke` (cheap, <= 12 particles).
- Owner: message `Your Roadside Post was pillaged` (Magpies: `Magpies pillaged your Roadside Post`), minimap red ring ping
  3 s at the post, a short wood-crash + horn sound (SFX bus). Enemy side: message above, a coin sound.

### 5.4 The ruins' gold and the Magpie camp (user answer to Q4)
**The ruins pile** (systems 17b.C1):
| Rule | Value |
|---|---|
| When | A pillaged post **collapses** (180 s without repair progress). Never on demolish, never from a site |
| What | A **LootSack** (`market-trade.md` 5.4) spawned at the post centre: **60 gold**, lifetime **90 s** (not 45), look `&"ruins"` (a spilled strongbox in the rubble, 17b.V2) |
| Who picks it up | Unchanged sack rule: the first living unit within **2 m**. Any PLAYER / ENEMY unit (the owner's too) -> that team's gold (`&"loot"`); a Magpie -> its carried loot, **up to its cap of 60**; what it cannot carry stays in the pile for the next one |
| Seen by | Like sacks: drawn in cells the team sees now. The **owner** also sees the pile icon on the minimap for its whole life (it knows where its post stood) |
| Warning | Owner, 30 s before the collapse: `Your pillaged Roadside Post collapses in 30 s` + a small ping |
| Why 60 | 80 % of the post's price in crystals, a bit less than one far trip: worth a short fight, never worth letting your own post fall (you lose 75 crystals and 180 s of bonus; picking up your own pile gets back 60 gold) |

**The Magpie camp** (guild systems 17b.C3, band brain ai 17b.A1). New band state `&"guarding"`:
| Rule | Value |
|---|---|
| Who camps | (1) A band that **pillaged** a post does **not** flee: it keeps its loot and starts guarding. (2) Any other pillaged post (pillaged by a player) with no guarding band becomes a guild target kind **`&"ruin"`** from **5:00**, weight **80** (free gold draws thieves); the next 75 s tick sends a band of the normal size (2-4) if the cap of 6 alive allows. **Max 1 band per post, max 2 guarding bands on the map** |
| Where | Guard spot **7 m** from the post, away from the road, loose 3 m cluster; spot validity as today (no owner fighter within 18 m, no owner tower within 20 m, no keep within 25 m); an invalid spot -> wait at the Den door and retry (3 tries) |
| Attack repair crews | An owner's worker within **10 m** of the post (repairing or walking up) -> strike it if the escort strength within 10 m of it **<= 70 x living Magpies** (the existing strike check); max 2 kills or 15 s, then back to the guard spot (no flee) |
| Re-pillage | The post has repair progress > 0 (targetable again) and the escort check passes -> every Magpie attacks it until it is back at 0 (no new gold within 120 s, 5.2). A post that got fully repaired while they waited -> pillage it again when the check passes (a normal pillage: +30 loot if 120 s have passed) |
| Grab | The post collapses -> the nearest Magpie walks to the pile (7 m, ~1.5 s) and takes it; a second one takes the rest; then the whole band **flees** (`shroud` 2 s) to the nearer Den |
| Caravans | A loaded caravan of the owner within 12 m still takes priority (the normal caravan strike), then back to guarding |
| Give up (flee to the Den with their loot) | Escort strength within **18 m** of the post **> 70 x size for 20 s** in a row · an owner **tower completed within 20 m** (at once) · half the band dead or beaten by a stronger force (existing flee rule) · the post **demolished** · **240 s** of guarding · the post repaired to 100 % and the check fails for 20 s |
| Never | They never attack soldiers first (fight back only, existing rule), never chase more than 15 m from the guard spot except to strike a worker within 10 m of the post or to reach the pile |

**Counters for the owner** (all already in the game, plus one small extension):
| Counter | Effect |
|---|---|
| **Escort** the repair | Send soldiers with the workers: escort strength above 70 x Magpies (a band of 2 = 140, about 2 line soldiers) stops every strike; keep them there 20 s and the band gives up. A repair with 2 workers takes 10 s |
| **Tower** | An own Spire completed within 20 m of the post makes the band give up at once and keeps future guard spots invalid (120 crystals; build it with the escort) |
| **Champions** | **Escort** flag on the repairing worker (essence, 180 s), **Hunt** flag on a looter (refunded if it leaves the map); the Coin-Cutter's Raid already goes after Magpies carrying loot within 30 m (every guard carries some) |
| **Sweep** (Greywater Lodge, 100 gold) | Extension: the trackers visit the hiring team's **guarded** pillaged posts **first** (before the W spots), and fight the band there |
| **Demolish** | Delete twice: the post is gone, no pile, the band gives up (you lose the post, the thieves get nothing more) |
| **Grab it yourself** | Any own unit on the pile when the post falls takes the 60 gold |

## 6. Repair (systems 17b.C2)
| Rule | Value |
|---|---|
| Order | Right-click an own damaged or pillaged post with workers selected (cursor: hammer), or the post card's **Repair** button (sends the nearest own worker that is not carrying crystals: Auto / idle ones first), or Auto (section 7). Workers call `command_repair(post)` |
| Cost | **Free** |
| Time | A full repair (0 -> 100 %) takes **15 s** with 1 worker; 1.5 / 2.0 speed with 2 / 3 workers (the construction rule, max 3 counted). A damaged intact post repairs in proportion (175 / 350 missing = 7.5 s) |
| Pillaged post | Stays pillaged (no bonus, sight 0) until integrity reaches 100 %; then `intact` again, message `Roadside Post repaired`, `repaired` signal, VFX `post_repair` done puff |
| Interrupted | A repairer that is hit fights back (normal worker rule) and walks back after; the repair pauses. A post knocked back to 0 while repaired returns to `pillaged` (no reward within 120 s, 5.2) |
| After | The worker goes back to the node it was gathering (like after building), else stands at the post |
| Other buildings | **Not in 17b**: workers repair Roadside Posts only. `command_repair` accepts any node with `needs_repair() -> bool` so building repair can come later if the user asks |

## 7. Worker Auto (systems 17b.C2, UI 17b.U1)
### 7.1 Turning it on and off
- Worker card **r2c3 Auto P** (toggle, lit when on; r2c2 is step 18's Staff I). With several workers: if any selected
  worker is off, P turns all selected workers on; if all are on, it turns them off. Mixed selections: also r2c3, acts on the
  workers only. Why P: step 18 takes I / O / L when a building or workers are selected (`building-levels.md` section 7);
  P is free everywhere else (the cutscene pause key in `cinematics.md` only works during a cutscene).
- **Manual Move, Stop, Hold, Attack or Attack-move turns Auto off** for that worker (predictable: the player took it).
  Manual Gather, Build and Repair keep Auto on: the worker does that job first, then Auto takes over when it is idle.
- Muster Bell militia (`rush-balance.md` 3.4): Auto pauses while `militia` is on and resumes after.
- New workers: game setting **New workers start on Auto: Off (default) / On** (user Q3). Works in missions too (trade off:
  Auto repairs nothing; it finishes sites, staffs blocked buildings when step 18 is on, and gathers).
- Look: a small cog badge (12 px) on the worker's portrait in the selection panel and the multi-select grid; no world icon
  (no clutter). Worker single view line: `Auto · gathering`, `Auto · repairing a Roadside Post`, `Auto · building Ember Hall`,
  `Auto · building a Roadside Post`, `Auto · staffing Ember Hall` (while walking in), `Auto · waiting for work`.

### 7.2 The coordinator (`WorkerAuto`, one per team, think every **1.0 s**, teams staggered 0.5 s)
Each tick it lists the jobs, then gives each job the best free Auto worker. Priority (first = most important):
| # | Job | Exists when | Workers per job | Picks |
|---|---|---|---|---|
| 1 | **Finish a site** (`building-levels.md` 5.4 priority 1) | An own construction site (any building) within **40 m** of the worker with no builder for **5 s** (its builder died or was ordered away) | 1 | Nearest free Auto worker |
| 2 | **Staff a blocked building** (`building-levels.md` 5.4 priority 2; only when step 18 staffing is on) | An own production building is **blocked** (0 staff and work waiting, `StaffDirector.blocked_buildings()`), its per-building Auto pill is on, and the StaffDirector's own picks 1-2 (the finishing builder, an idle worker within 40 m) found nobody | 1 (the **crew slot only**; Auto never fills slots 2-3) | The StaffDirector's pick 3 ("the nearest worker in Auto mode doing a low-priority job") asks WorkerAuto for its nearest free Auto worker; the worker enters as staff (`building-levels.md` 4.2) |
| 3 | **Repair** | An own Roadside Post is pillaged, or intact below **60 %** integrity and not damaged in the last **8 s** | 2 (pillaged) / 1 (damaged) | Nearest free Auto worker within **90 m** (straight line) |
| 4 | **Build a Roadside Post** (user Q2: yes) | All of: trade on; own completed Bazaar; posts < 4; a free plot on **your own bank** whose segment was used by an own caravan trip in the last **120 s**; crystals >= 75 + **100** reserve; no own Auto post site already exists; none started in the last **60 s** | 1 | The plot nearest the keep first; nearest free Auto worker. The worker places the site itself (spends the 75) |
| 5 | **Gather** | A free Auto worker has no job and no gather order | - | Its last node if not depleted, else the nearest node with a free work spot (`CrystalNode.can_mine`), not sealed, within **30 m** of an own drop-off (else the nearest one) |
| Rule | Value |
|---|---|
| Free Auto worker | Auto on, alive, `can_act()`, not militia, **not carrying crystals** (a gatherer is only taken right after a delivery or while walking to its node), not already on a job |
| Away cap | At most **3** Auto workers per team on jobs 1, 3 and 4 at once (the rest keep mining). Staff (job 2) do not count: once inside they belong to the building |
| Staff | A worker that enters as staff keeps its Auto flag; inside, Auto does nothing; when it leaves (Staff Out, the building destroyed) it resumes Auto (`building-levels.md` 5.4). Staffing never takes a worker with a build order or doing a repair (`building-levels.md` 5.2) |
| Danger | A job is skipped while a visible enemy soldier, wizard, champion or Magpie is within **15 m** of its target, or the target took damage in the last 8 s; Auto gathering avoids a node raided by Magpies or where an own worker died in the last **60 s** |
| Enemy bank | Auto never builds a post on the other bank's plots and never repairs a post more than 90 m away: those stay manual |
| Guarded ruins | Auto never repairs a post with a guarding Magpie band (`guard_band() != null`), even if the Magpies stand out of sight: that repair needs an escort, so it stays manual (the `Magpies are camping...` message says so) |
| Done / failed | Job finished, target gone or danger: the worker returns to its previous node (the build-resume rule), else takes a Gather job |
| Idle list | Auto workers are never "idle": F3 (next idle worker) skips them; `Auto · waiting for work` shows when nothing is left (all nodes empty) |

### 7.3 Why this order
It is the order frozen in `building-levels.md` 5.4, plus job 4 (new posts), which that spec does not list. A nearby
unattended site comes first: it is already paid for and quick to finish. Staffing a blocked building is next, because a
blocked Hall or Forge stops training or research completely. Repair comes third: a pillaged post only loses its bonus (~12-30
gold / min). New posts are built only with a crystal reserve and only on routes that are actually used. Gathering is the
default: an Auto worker is a normal miner that also looks after sites, crews and posts.

## 8. Magpies (Thieves' Guild; systems 17b.C3, band brain ai 17b.A1)
| Rule | Value |
|---|---|
| New target kind | `&"post"`: an own **intact** Roadside Post of team T that added bonus to a delivery in the last **180 s**. From **5:00** (with the road targets) |
| Weight | **0.5 x bonus gold it paid in the last 180 s + 15** (a road with 600 gold traded weighs 630: bands still mostly hunt caravans) |
| Spot | The nearest road ambush spot within 20 m of the post (Heron Road -> A1, Millstone Road -> A2, West Bend -> A3, North Bend -> A4, mirrors); else the point 6 m from the post, away from the road. Same validity rules (18 m units, 20 m towers, 25 m keep) |
| Strike | While lurking (90 s, then home): when the escort strength within **10 m of the post** is **<= 70 x band size**, every Magpie attacks the post; stop after **25 s** or when pillaged. A loaded caravan of T within 12 m during the lurk still takes priority (the normal caravan strike) |
| After | Loot split (5.2), then the band **stays and guards** the ruin (section 5.4) instead of fleeing |
| Ruin target | `&"ruin"`: a pillaged post (any pillager) with no guarding band, weight **80**, from 5:00; sends a guarding band (5.4). Max 2 guarding bands on the map, all bands still under the cap of 6 alive |
| Counters | A tower within 20 m (spot invalid, guards give up), escorts, Sweep contracts (road spots A1-A4, and guarded posts first), champions' Escort / Hunt flags, demolish (section 5.4) |

## 9. The bot (ai 17b.A2: rule 10 of `ai.md`, new lines 10k-10o, knobs in `AIProfile` / `data/ai/*.tres`)
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `roadside_max` | 1 | 2 | 4 |
| `roadside_start` | 9:00 and 3+ caravans | 6:30 and 3+ caravans | 5:30 and 2+ caravans |
| `post_repair` | home plots only | home + own-bank bends when the route is safe (10d) | same, + 2 workers on a pillaged far post |
| `post_raid` | never on purpose | enemy posts on its **own** bank | + any known enemy post within 40 m of its idle army |
| Rule | Trigger -> action |
|---|---|
| 10k Build | Time and caravans >= `roadside_start`, posts < `roadside_max`, crystals >= 75 + 150, no other build waiting -> a Roadside Post on, in order: the home plot of its current main near route (enemy bot on Saltgate: Saltgate Road `(20, -48)`), the other home plot, then (hard, or normal when `far_route_caravans` > 0) the own-bank bends of its far route. Never the other bank's bends. Builder: the nearest worker not carrying crystals, returns to mining after |
| 10l Repair | An own post pillaged or below 60 % and no enemy unit or Magpie seen within 15 m of it in the last 20 s -> the nearest worker not carrying crystals `command_repair`s it (rules of `post_repair`). Posts never fire rule 1 (defence): the army does not run to a far bend |
| 10n Guarded ruin | An own pillaged post with Magpies seen within 15 m in the last 20 s. **Home plot** (normal, hard): no enemy army seen within 30 m in 30 s -> an escort squad of soldiers with strength >= 1.5 x the seen band (min 3 soldiers) attack-moves to the post, then 2 workers repair it under escort; the squad stays until the post is intact and the band gone, then returns. **Bend**: normal writes it off (demolish when the collapse is < 30 s away, so the band gets no pile); hard sends the escort when `own_strength >= 1.2 x seen_strength`, hires **Sweep** if gold >= 100 and none runs, and puts an **Escort 50** flag on the repairing worker (new champion bot rule B8). Easy: never repairs a guarded ruin |
| 10o Ruins gold | A visible ruins pile (any team's) within 25 m of an own soldier and no enemy army within 20 m of it -> the nearest soldier walks onto it (one per pile). Its own post's pile at collapse: the escort (if any) stands on it |
| 10m Pillage | Normal: a known intact enemy post on the bot's own bank (the player's posts on the bot-side bends), no enemy army seen within 30 m of it in 30 s, `own_strength >= seen_strength` -> a squad of 3 soldiers attack-moves there, pillages it, returns to the rally. Hard: also any known enemy post within 40 m of its army while the army is idle or regrouping. Attack waves pillage posts on their path anyway (auto-aggro) |
- Bot workers never use the Auto flag (the bot's worker rules stay the owner of its workers); `WorkerAuto` exists for the bot's
  team but has no Auto workers.
- Strength: posts count 0. Concede rule unchanged (posts do not count for defeat).
- Expected (normal): first post ~6:30-7:30 on Saltgate Road, second ~9:00-10:00; the first Magpie pillage attempt on a post
  ~9:00-11:00; repairs within ~20-40 s of a pillage at home plots; a Magpie-guarded home ruin escorted and repaired within
  ~60 s; guarded bends mostly written off (demolished before the collapse) by the normal bot.

## 10. UI (layout and sizes: ui-designer 17b.D2 in `docs/design/ui-worker-improvements.md`; code ui-coder 17b.U1 / U2)
| Element | Content | Interaction |
|---|---|---|
| Worker card | r2c3 **Auto P** (r2c2 = step 18's Staff I): `Auto  [P]\nThis worker finds its own work: finishes nearby building sites, staffs a stopped building, repairs your Roadside Posts, builds posts on your caravan roads, and gathers when idle.\nMove, Stop, Hold or Attack turns it off.` Lit / unlit / half (mixed) | P or click toggles (7.1) |
| Build menu | r3c4 **Roadside Post P**: `Roadside Post  [P]\nCost 75 crystals · 25 s · 350 integrity\nCaravans whose road passes it bring more gold (+4, plus 6 % of the route value, per trip; max 3 posts). Build on a roadside plot. Needs a Bazaar. Max 4.` + reason when disabled | B then P, then click near a plot |
| Placement ghost | Snaps to the nearest plot within 8 m; while placing, **every plot** shows a ground ring: green = you can build, grey = not (hover shows the reason). Ghost text: `Heron Road · Heron Ford +5, Saltgate +11 gold per trip` | Left-click confirms, Esc / right-click cancels |
| Roadside Post card (own) | r1c1 **Repair** (button, no key; only when damaged or pillaged; disabled `A worker is already on it` / `No free worker`), r1c4 **Demolish Delete** (press twice). Site: Cancel Delete as today | Right-click with workers = repair |
| Roadside Post panel | Name + state chip (`Intact` green / `Pillaged` red / `Repairing 40 %` amber / `Under construction`), `Integrity 350 / 350` bar, `Serves: Heron Ford (near), Saltgate (far)`, `Bonus per trip: +5 / +11 gold`, `Paid last 3 min: 84 gold · total 612`, pillaged: `Collapses in 2:14 unless repaired`. Enemy post: name, state, integrity only | |
| Worker panel | The Auto line of 7.1; cog badge on portraits | |
| Caravan panel | `Cargo 152 gold (+33 from Roadside Posts)` | |
| Bazaar panel / route buttons | Line `Roadside Posts 3 / 4 · this route +33 per trip`; route buttons' value tag includes the bonus (`152 gold / trip`) with the tooltip split `119 + 33 posts` | |
| Minimap | Free plot: 3 x 3 hollow diamond `(0.85, 0.65, 0.30)`; own post: 4 x 4 diamond in the own colour with a 1 px gold centre; pillaged: grey with a 1 px red centre; enemy post: enemy colour, last seen. A **guarded** own ruin: the pillaged icon with a pulsing 1 px orange `(1.0, 0.65, 0.2)` (Magpie colour) border. Ruins pile: 4 x 4 gold `(1.0, 0.85, 0.3)` with a slow pulse (visible cells; always for the owner). Pillage ping: red ring r 6 px, 3 s; collapse warning ping: orange ring, 2 s | Click = camera, as other icons |
| Messages (own team) | `Roadside Post built` · `Your Roadside Post is under attack` (20 s per post) · `Your Roadside Post was pillaged` / `Magpies pillaged your Roadside Post` · `Pillaged an enemy Roadside Post: +30 gold` · `Roadside Post repaired` · `Magpies are camping at your Roadside Post: escort your workers` (once per guard) · `Magpies attack your repair crew!` (20 s) · `Your pillaged Roadside Post collapses in 30 s` · `Your Roadside Post collapsed: 60 gold lies in the ruins` · `Picked up a loot sack: 60 gold` (existing sack line) · `The Magpies made off with the ruins' gold` (owner, or anyone who sees it) · `The Magpies left your Roadside Post` (give-up) · refusals of 3.2 | `show_message`; attack / pillage lines max once per 10 s, summed |
| Post panel while guarded | Chip `Guarded by Magpies (2)` in orange under the state chip; the Repair button tooltip adds `Magpies are camping here: send soldiers with your workers` | |
| Floating text | `+33` small gold at the Bazaar with the delivery text, as `+119 +33` (own, visible) | |
| Audio (SFX bus) | Pillage: wood crash + short horn (own) / coin clink (pillager); repair done: two hammer taps + chime; toll: one soft coin (own, visible, max once per 3 s) | |
| End screen | `Roadside Posts: +640 gold · pillaged 2 · you pillaged 1` | |
| Settings | `New workers start on Auto: Off / On` (default Off) | `GameSettings.worker_auto_default` |
| Help text | Adds `P: worker Auto    B, P: Roadside Post` | |
**Keys** (physical; for the lead's Keys line): workers selected **P** = Auto on / off (card r2c3); build menu **P** =
Roadside Post (the build menu replaces the worker card, as with C / B today); own post selected: **Delete** = demolish (twice)
/ cancel (site); right-click an own damaged or pillaged post with workers = repair. Step 18's I / O / L are not used here.
AZERTY prints P on the same key.

## 11. Balance
### 11.1 Fight and time checks
| Case | Result |
|---|---|
| Worker walk to a home plot / a bend (from the keep, 4.6 m/s) | ~6-7 s / ~17-19 s; a far repair costs ~50 s of one worker's mining (~60 crystals) + the downtime |
| Normal bot, 4 near caravans + 1 post | +48 gold / min; one pillage + ~40 s downtime costs it ~35 gold + ~40 crystals of mining; the pillager gets 30 gold |
| 2 Magpies vs an intact post with no escort | Pillaged in ~19.5 s, 15 gold each, then they camp 7 m away |
| 1 unescorted repair worker vs a guarding band of 2 (18 DPS vs 50 HP) | The worker dies in ~3 s; a second one sent alone dies too (2 kills max per strike, then back to guarding): the ruin cannot be repaired without an escort |
| Escort of 2-3 soldiers + 2 workers vs a band of 2 | No strike (escort > 140); repair done in 10 s; the band gives up after 20 s (or fights and flees at half losses) |
| Nobody comes | Collapse at 180 s: a Magpie takes the 60-gold pile (it carries 15 from the pillage: takes 45, the second takes 15), band flees with ~90 gold in total: kill them on the way home for sacks + 10 gold each from the Lodge |
| Owner demolishes before the collapse | No pile; the band gives up with its 30 gold |
| 2 Magpies vs a post with a Spire within 20 m | No strike (spot invalid) |
| 6 soldiers of an attack wave passing a home plot | Pillaged in ~6 s on the way (auto-aggro), +30 gold |
| Repair race | 1 Auto worker repairs a pillaged post in 15 s; two in 10 s |

### 11.2 Knobs (one at a time; 17b.D3 after the playtest)
| Symptom | Knob |
|---|---|
| Nobody builds posts (bot or playtest) | Cost 75 -> **60**; bonus 4 + 6 % -> **5 + 8 %** |
| Trade > 35 % of income before 12:00 (the `market-trade.md` 11.5 line) or games shorter than the no-post control | Bonus 6 % -> **4 %**; max per trip 3 -> **2**; team limit 4 -> **3** |
| Posts never pillaged | Pillage reward 30 -> **50**; Magpie post weight base 15 -> **40**; road bands that lurk 60 s without a caravan strike pillage an intact post within 15 m |
| Pillage too punishing / constant | Integrity 350 -> **500**; reward 30 -> **20**; Magpie post targets from 5:00 -> **8:00** |
| Auto pulls too many miners | Away cap 3 -> **2**; repair radius 90 -> **60 m** |
| Auto spends crystals the player wanted | Reserve 100 -> **200**; or job 4 off (`allow_post_builds`) |
| Dead pillaged posts block plots | Collapse 180 -> **120 s** |
| Magpie camps make posts not worth building (playtest: > 50 % of pillaged posts collapse) | Guard max time 240 -> **150 s**; give-up escort time 20 -> **10 s**; `&"ruin"` weight 80 -> **40**; max guarding bands 2 -> **1** |
| Camps irrelevant (bands never guard, piles never taken by Magpies) | `&"ruin"` weight 80 -> **150**; ruins pile 60 -> **90** gold |
| Players let their own posts collapse to farm the pile | Impossible by design (only an enemy can pillage; the owner loses 75 crystals for 60 gold); if it shows up anyway: pile 60 -> **40** |

## 12. Performance
| Part | Budget |
|---|---|
| Roadside Posts | Max 8 on the map; no per-frame work (state changes on damage / repair ticks; a 1 Hz timer only while pillaged); navmesh rebake on build, collapse and demolish only (like any building) |
| Bonus | One sum over <= 3 cached posts per trade (`TradeNetwork` caches plot -> segment and team -> ring path) |
| Toll cosmetic | Returning loaded caravans check <= 3 cached posts every 0.5 s |
| WorkerAuto | 1 Hz per team, staggered; one pass over own workers (<= ~30) and jobs (<= ~10) : **< 0.02 ms / frame** average |
| Magpies | Two more target kinds in the 75 s tick; the guarding state thinks every 0.5 s like the others (one distance check to the post and its owner's workers within 10 m); max 2 guarding bands |
| Ruins pile | A normal LootSack (checks units within 2 m every 0.25 s); at most 8 exist at once with the 6 trade sacks: fine |
| Total | **< 0.05 ms / frame** average. The perf test adds 8 posts (2 pillaged, smoke on) and 12 Auto workers to its 200 units and must still print `PERF OK`, stuck = 0 |
| Art | Smoke <= 12 particles per pillaged post, pre-built; no real lights; post model within the 17b.V1 budget (section 13) |

## 13. Art (tech-artist; global style `art-keep.md` section 0: chunky, hand-painted, readable at 40 m)
| Id | Asset | Look and silhouette | Budget / hooks |
|---|---|---|---|
| 17b.V1 | **Roadside Post** (one model, all kingdoms) + **plot marker** | Must read differently from the neutral trading post (big open waystation, sign mast), the Bazaar (balance-scale mast) and a tower. Dominant: a **leaning lantern arm** over the road from a squat **milestone** base carved with a coin, a brass lantern hanging from it; secondary: a small **shingled booth** with a team-colour awning, a strongbox and two sacks, a short team pennant. **Intact**: lantern lit `(1.0, 0.8, 0.4)`, sign swings. **Pillaged**: booth roof caved, awning torn, lantern on the ground and dark, strongbox open and empty, scorch decal. **Site / repair**: plank scaffold over the base. Plot marker: surveyor's stake with a blank board, 3 stones, a faint chalk ring (MultiMesh or a tiny scene, 8 instances) | 2 x 2 (4 x 4 m), ~4 m to the lantern arm; <= 16 meshes, <= 10 draw instances, <= 4 materials, 0 lights, 1 glow point (lantern, off when pillaged). Hooks: `set_team_color(c)`, `set_state(&"site" / &"intact" / &"pillaged")`, `set_repair_progress(r)`, `play_toll()`, `play_pillage()`, `set_selected(bool)`; paths `res://art/buildings/roadside_post/roadside_post.tscn`, `res://art/buildings/roadside_post/plot_marker.tscn` |
| 17b.V2 | **VFX** (added to `TradeVfx.play`) | `post_toll` (3 coins hop caravan -> sign, 0.5 s), `post_pillage` (splinters + ember puff, 0.8 s), `post_smoke` (thin grey looping wisp, <= 12 particles, start / stop), `post_repair` (hammer sparks + dust tick every 1 s while repaired; a done puff), `post_collapse` (dust burst 1 s), and the **ruins pile** look of the loot sack (`art/vfx/trade_loot_sack.tscn` variant `&"ruins"`: a split strongbox with spilled coins in broken planks, gold rim glow, ~1 m, slow shimmer instead of the bob) | Pre-built one-shot emitters, restarted; smoke as a per-post looping emitter owned by the post scene |
| 17b.V3 | **Icons** | Roadside Post (build menu), Auto on / off (a cog over a pick), Repair (hammer on a plank), pillaged badge, plot | Same renderer and size as the existing icon set, `art/icons/` new files only |
Contact sheet `docs/art/screens/roadside_post_states.png`: intact / pillaged / site at 40 m next to a trading post and a
Bazaar (the three must be told apart in black silhouette).

## 14. Proposed contracts (the lead freezes them in `CLAUDE.md`: 17b.L1)
Phase-1 rule as in steps 9-10: never use another step-17b agent's new `class_name` as a static type; use groups,
`has_method()`, `get()` and load guards.
- **RoadsidePost** (`scripts/buildings/roadside_post.gd`, `class_name RoadsidePost extends Building`, kind
  `&"roadside_post"`, groups `"buildings"`, `"roadside_posts"`, layer 2): `plot_id: StringName`, `state: StringName`
  (`&"site"`, `&"intact"`, `&"pillaged"`), `is_intact() -> bool`, `is_pillaged() -> bool`, `is_targetable() -> bool` (false while
  pillaged with no repair progress), `needs_repair() -> bool`, `repair_progress() -> float` (0-1), `add_repairer(worker)`,
  `remove_repairer(worker)`, `repair_spot(from: Vector3, reach: float) -> Vector3`, `collapse_time_left() -> float`,
  `served_posts() -> Array` (trading posts whose route from this team uses the plot), `bonus_for(post: Node3D) -> int`,
  `paid_recent(seconds := 180.0) -> int`, `paid_total() -> int`, `demolish()`, signals `state_changed(post, state)`,
  `pillaged(post, by_team: int, by: Node3D)`, `repaired(post)`, `collapse_warning(post)` (30 s left),
  `collapsed(post, pile: Node3D)` (pile null on demolish). `guard_band() -> Node` (the guarding ThiefBand or null, set by the
  band through `set_guard_band(band)`). `counts_for_defeat() == false`. Constants `REPAIR_TIME := 15.0`,
  `COLLAPSE_TIME := 180.0`, `COLLAPSE_WARNING := 30.0`, `PILLAGE_GOLD := 30`, `REWARD_COOLDOWN := 120.0`,
  `RUINS_GOLD := 60`, `RUINS_LIFETIME := 90.0`.
- **LootSack** (systems): `static func spawn(parent, pos, amount, lifetime := LIFETIME, look := &"sack") -> LootSack`
  (defaults keep step 10 unchanged); `look` is passed to the scene (`set_look(look)` if the model has it); Magpie pickup
  takes `min(amount, 60 - carried)` and leaves the rest (a step-10 sack is <= 60, so nothing changes there).
- **BuildingType / BuildGrid** (systems): fields `plot_only := false`, faction `&"common"` accepted by `buildable_for`;
  messages `MSG_PLOT := "Build it on a roadside plot"`, `MSG_PLOT_TAKEN := "Plot taken"`, `MSG_NO_ROUTE := "No route of yours
  passes here"`, `MSG_NEEDS_BAZAAR := "Needs a Bazaar"`, `MSG_POST_LIMIT := "Only 4 Roadside Posts"`; `snap_to_plot(world_pos,
  max_dist := 8.0) -> Vector3` (INF when none). Towers and keeps skip targets in group `"roadside_posts"`.
- **TradeNetwork** additions: `setup(..., plots: Array = [])` (entries `{id, name, pos, segment: [a, b]}`), `plots() ->
  Array[Dictionary]`, `plot_by_id(id)`, `plot_near(pos: Vector3, max_dist := 8.0) -> Dictionary`, `plot_owner(id) -> Node3D`
  (post or null), `plot_reason(team: int, id: StringName) -> String`, `plot_serves(team: int, id) -> Array` (trading posts),
  `roadside_bonus(team: int, post: Node3D) -> int` (sum of intact own posts on the ring path to that post, max 3),
  `roadside_posts(team: int) -> Array`, `record_post_bonus(team, roadside_post, amount)`, `post_bonus_total(team) -> int`,
  constants `POST_BONUS_FLAT := 4`, `POST_BONUS_PCT := 0.06`, `POST_MAX_PER_TRIP := 3`, `POST_LIMIT := 4`, signal
  `roadside_changed(team: int)`. **Skirmish** gains `ROAD_PLOTS` (section 2.1) passed to `setup`.
- **Caravan**: `cargo_bonus: int` (read only, part of `cargo`), set in `_finish_trade` from `roadside_bonus`; `play_toll`
  cosmetic; delivery calls `record_post_bonus` per counted post.
- **Worker**: `command_repair(target: Node3D)` (any node with `needs_repair()`), `is_repairing() -> bool`, `auto_mode: bool`
  (read only), `set_auto(on: bool)`, `auto_text() -> String`, signal `auto_changed(worker, on: bool)`; `command_move` /
  `command_stop` / `command_hold` / `command_attack` / `command_attack_move` call `set_auto(false)`.
- **WorkerAuto** (`scripts/economy/worker_auto.gd`, `class_name WorkerAuto extends Node`, one per team, group
  `"worker_autos"`, `static func for_team(team: int) -> WorkerAuto`): `TICK := 1.0`, `MAX_AWAY := 3`, `RESERVE := 100`,
  `allow_post_builds := true`, `jobs() -> Array[Dictionary]` (`{kind: &"site" / &"staff" / &"repair" / &"new_post" /
  &"gather", target, workers}`, in that priority order), `job_of(worker) -> Dictionary`, and the step-18 hook
  `nearest_free_auto_worker(pos: Vector3) -> Node` (the StaffDirector's pick 3, `building-levels.md` 5.2; it returns null for
  workers on jobs 1 or 3-4, carrying crystals or militia). WorkerAuto reaches `StaffDirector` through its group and
  `has_method()` only, so 17b works with step 18 absent or off.
- **ThievesGuild / ThiefBand**: target kinds `&"post"` and `&"ruin"` in `targets()` (`{kind, team, post, spot, weight}`);
  band strike on a post (`PILLAGE_MAX_TIME := 25.0`); loot split through the existing per-Magpie `loot` meta; new band state
  `&"guarding"` with `GUARD_DISTANCE := 7.0`, `GUARD_STRIKE_RADIUS := 10.0`, `GUARD_ESCORT_RADIUS := 18.0`,
  `GUARD_GIVE_UP_TIME := 20.0`, `GUARD_MAX_TIME := 240.0`, `MAX_GUARDING := 2`, `RUIN_WEIGHT := 80.0`; signal
  `guard_ended(band, reason: StringName)` (`&"collapsed"`, `&"escort"`, `&"tower"`, `&"losses"`, `&"demolished"`,
  `&"timeout"`, `&"repaired"`).
- **HuntersGuild / TrackerContract**: Sweep visits the hiring team's guarded pillaged posts first.
- **Unit** (gameplay): auto-target and attack orders skip a target with `has_method("is_targetable")` and
  `is_targetable() == false` (drops it at once when it turns false). Victim row: Roadside Post 15.
- **GameSettings** (ui): `worker_auto_default := false`; `Worker._ready` reads it through `get_node_or_null` on the settings
  holder (players' workers only).
- **Ownership**: `scripts/buildings/roadside_post.gd`, `scripts/economy/worker_auto.gd`, `data/buildings/roadside_post.tres` =
  systems; `art/buildings/roadside_post/`, `art/vfx/trade_*` additions = tech-artist. No `Events` change.

## 15. Tasks (step 17b)
**Phase 0:** 17b.L1 lead, 17b.D2 ui-designer. **Phase 1 (parallel, no shared files):** 17b.C1, 17b.C4, 17b.A1, 17b.V1,
17b.V2, 17b.V3. **Phase 1b:** 17b.C2 (after C1: worker.gd reads RoadsidePost), 17b.C3 (after C1). **Phase 2:** 17b.U1,
17b.U2 (need D2), 17b.A2, 17b.C5, then 17b.L2, then 17b.D3 after the playtest. Build with or after step 17 (shares
`skirmish.gd`, `build_grid.gd`, `trade_network.gd`, `ai_trade.gd`, `command_card.gd`).
| Id | Agent | Task | Files |
|---|---|---|---|
| 17b.L1 | lead | Freeze section 14 in `CLAUDE.md`, Keys (workers P = Auto, build menu P, repair right-click, Delete demolish), owner rows, step ids in `waves.md` | `CLAUDE.md`, `docs/plan/` |
| 17b.D2 | ui-designer | Layouts at 1600 x 900 for everything in section 10 | `docs/design/ui-worker-improvements.md` |
| 17b.C1 | systems-coder-high [H] | RoadsidePost (states, integrity, pillage instead of death, reward, cooldown, collapse, demolish, sight), `.tres`, plot data and clearing, BuildGrid plot rules / snap / messages, tower + keep skip, TradeNetwork plots / bonus / ledger, Caravan bonus lock + toll + ledger, collapse warning + **ruins pile** (LootSack `lifetime` / `look` params, capped Magpie pickup), guard-band slot on the post, messages, end-screen line | `scripts/buildings/roadside_post.gd`, `building_type.gd`, `build_grid.gd`, `building.gd` (tower targeting), `data/buildings/roadside_post.tres`, `scripts/world/trade_network.gd`, `loot_sack.gd`, `skirmish.gd`, `scripts/economy/caravan.gd` |
| 17b.C2 | systems-coder-high [H] | Worker `command_repair`, Auto flag and order rules, WorkerAuto coordinator (jobs in the 7.2 order, away cap, danger, resume), the step-18 staff hook (`nearest_free_auto_worker`, keep Auto while staffed), settings default hook | `scripts/economy/worker.gd`, `scripts/economy/worker_auto.gd`, `skirmish.gd` / `main.gd` (create one WorkerAuto per team) |
| 17b.C3 | systems-coder | ThievesGuild `&"post"` and `&"ruin"` targets, weights, spots, max 2 guarding bands | `scripts/world/thieves_guild.gd` |
| 17b.C4 | gameplay-coder | Unit target skip for `is_targetable() == false`; victim row | `scripts/units/unit.gd` (targeting only) |
| 17b.C5 | systems-coder | Plug the post model, plot markers and VFX hooks | `scripts/buildings/roadside_post.gd`, `data/buildings/roadside_post.tres`, `skirmish.gd` (markers) |
| 17b.A1 | ai-coder [H] | ThiefBand post strike (8) and loot split; the **guarding** state of 5.4 (crew strikes, re-pillage, pile grab, every give-up rule); Sweep visits guarded own posts first | `scripts/ai/thief_band.gd`, `tracker_contract.gd` |
| 17b.A2 | ai-coder | Bot rules 10k-10o, champion rule B8, knobs, strength / defence exclusions | `scripts/ai/ai_trade.gd`, `commander.gd`, `ai_profile.gd`, `ai_champions.gd`, `data/ai/*.tres` |
| 17b.U1 | ui-coder | Worker card Auto P at r2c3 (toggle, mixed state), build menu P, plot snap ghost + plot rings + hover text, post card (Repair, Demolish) and panel, right-click repair + hammer cursor, worker Auto line and cog badges, caravan / Bazaar panel lines, route button value | `scripts/ui/command_card.gd`, `selection_panel.gd`, `selection_manager.gd`, `scripts/vfx/` (plot rings) |
| 17b.U2 | ui-coder | Minimap layers and pings (guarded ruin border, ruins pile, collapse warning), guarded chip, messages (throttled), floating `+bonus`, audio, end screen, settings toggle, help text, F3 skips Auto workers | `scripts/ui/minimap.gd`, `hud.gd`, `scripts/vfx/trade_popups.gd`, `scripts/ui/menus/game_settings.gd`, `assets/audio/post_*` |
| 17b.V1 | tech-artist | Roadside Post model (3 states + repair progress) + plot marker | `art/buildings/roadside_post/` |
| 17b.V2 | tech-artist (VFX) | 5 effects of section 13 + the `&"ruins"` look of the loot sack | `art/vfx/trade_vfx.gd`, `art/vfx/trade_post_*` |
| 17b.V3 | tech-artist | Icons | `art/icons/` (new files only) |
| 17b.L2 | lead | Glue, perf test additions (8 posts, 12 Auto workers), runs of 15.1, CI, playtest copy | `tests/`, `scenes/`, `docs/plan/` |
| 17b.D3 | game-designer | Balance from the runs and the playtest (knobs 11.2) | this file |

### 15.1 Runs (lead 17b.L2)
The 10.L2 bot-vs-bot harness (normal, cap 24:00), a new `--no-posts` flag as the control, fire-shadow and nature-ice both
orders, 2 runs each with posts and 2 without (8 + 8). Pass: median length with posts >= control - 0:30; trade share of
income before 12:00 <= 35 %; each side builds >= 1 post by 10:00; >= 1 pillage per game after 10:00; every pillaged post
is repaired, demolished or collapses (none stuck); every guarding band ends with a logged reason within 240 s; <= 50 % of
pillaged posts collapse; every ruins pile is picked up or fades (logged: by whom); 0 script errors; `PERF OK`.

## Done when
- [ ] 17b.L1: section 14 in `CLAUDE.md`; Keys line has workers P = Auto, build menu P, repair right-click, Delete demolish; owner rows; ids in `waves.md`.
- [ ] 17b.D2: `ui-worker-improvements.md` gives positions / sizes / looks at 1600 x 900 for every element of section 10, consistent with `ui-style.md` and `ui-trade.md`.
- [ ] 17b.C1: 8 plots at the centres of 2.1 with the clearances of 2.2 (test prints each distance; mirror check `-p`); a free plot blocks nothing; the ghost snaps within 8 m and every refusal of 3.2 appears in order (off-plot, taken, enemy home plot -> `No route of yours passes here`, no Bazaar, 5th post, crystals); 75 crystals, 25 s, 350 integrity, pop 0, sight 8 only intact, `counts_for_defeat() == false` (a side with only posts left loses); at 0 integrity it turns pillaged (not freed), `is_targetable()` false, the killer's team gets 30 gold once per 120 s, XP victim 15; towers and keeps never target it; 180 s without repair -> collapse, plot free, a 60-gold ruins pile (90 s, look `&"ruins"`) at the post, the owner's warning at 30 s left; Delete twice demolishes and drops no pile; an owner soldier on the pile takes 60 gold for its team; a Magpie carrying 15 takes 45 and leaves 15, a second one takes the rest; step-10 sacks unchanged (45 s, same pickup); from the M1 Bazaar with all own-bank posts intact the cargo is 20 / 34 / 152 and with the two enemy-bank bends + Millstone Road 193 (+-0), a pillaged post adds nothing, an enemy post on the road adds nothing, max 3 counted; `cargo_bonus` set; `record_post_bonus` sums per post; Masons' Charter gives 402; trade off -> no plots; smoke test `victory=true`; `PERF OK`.
- [ ] 17b.C2: `command_repair` on a pillaged post: 15 s with 1 worker, 10 s with 2, 7.5 s with 3; intact again at 100 %; the worker returns to its node; hit repairers pause and resume; `set_auto(true)` then Move turns it off, Gather keeps it; with a pillaged post, an abandoned site 30 m away and a blocked Hall all at once, one free Auto worker goes to the site, the next one is handed to the StaffDirector for the Hall's crew slot (never slots 2-3), the next repairs the post (step 18 absent: site then repair); a staffed Auto worker keeps its flag and resumes Auto when ejected; an Auto worker repairs a pillaged post 60 m away, builds a post on a used own-bank plot only with >= 175 crystals and never on the other bank, gathers otherwise; never takes a carrying worker; never more than 3 away; skips a post with a visible enemy within 15 m and never repairs a post with a guarding band; militia pauses Auto; `worker_auto_default` on -> new workers start Auto; `PERF OK`.
- [ ] 17b.C3: no post target before 5:00 or for a post that paid nothing in 180 s; weight 0.5 x paid + 15; spot = the nearest ambush spot within 20 m else 6 m off the road; spot validity unchanged; a player-pillaged post with no guard becomes a `&"ruin"` target (weight 80) from 5:00 and a band is sent at the next tick; never 2 bands on one post, never more than 2 guarding bands, never above 6 Magpies alive.
- [ ] 17b.C4: a unit attacking a post that turns pillaged drops it the same frame and picks another target; auto-aggro never picks a pillaged post; everything else unchanged (existing tests pass).
- [ ] 17b.C5: model and markers replace placeholders; `set_state`, `set_repair_progress`, `play_toll`, `play_pillage` called on the right events; smoke test `victory=true`.
- [ ] 17b.A1: a headless band targets a post, lurks, strikes only when escort <= 70 x size, pillages 350 in ~20 s with 2 Magpies, splits 30 loot, then **guards** 7 m away instead of fleeing; a loaded caravan in reach during the lurk is still struck first; stops after 25 s. Guarding (headless scenes, one per row of 5.4): a lone repair worker walking to the ruin is killed; a second lone one too, then the band returns to its spot; a half-repaired post is knocked back to 0 with no new gold; a post repaired to 100 % while escorted is pillaged again once the escort leaves (+30 only after 120 s); 2 workers + escort strength 150 vs a band of 2 -> no strike, repair done, band gives up after 20 s (`guard_ended` `&"escort"`); a Spire completed within 20 m -> gives up at once (`&"tower"`); half the band killed -> flees (`&"losses"`); demolish -> `&"demolished"`, no pile; collapse -> the nearest Magpie reaches the pile within 3 s, takes it (cap 60), band flees (`&"collapsed"`); 240 s -> `&"timeout"`; never attacks a soldier first; never chases beyond 15 m except for crew and pile; a Sweep started during a guard goes to the guarded post first; `PERF OK` with 2 guarding bands.
- [ ] 17b.A2: normal bot builds Saltgate Road ~6:30-7:30 and a second post later, never an enemy-bank bend; repairs a pillaged home post within 40 s when safe; a 3-soldier squad pillages a player post on the bot's bank when safe; hard builds up to 4 and raids from its idle army; posts never trigger defence; a Magpie-guarded home ruin (normal) gets an escort of strength >= 1.5 x the band and 2 workers and is repaired, the squad returns after; a guarded bend (normal) is demolished with < 30 s left, never left to drop a pile; hard escorts a guarded bend when ahead, hires Sweep and flags Escort 50 (B8); easy never repairs a guarded ruin; a visible pile within 25 m of a bot soldier with no enemy army near is picked up; `PERF OK`.
- [ ] 17b.U1: every card, ghost, panel and badge of section 10 with its states and reasons; right-click repair; nothing in `scripts/ui/` calls a `_private` function.
- [ ] 17b.U2: minimap layers and pings (guarded ruin border, ruins pile always shown to the owner, collapse warning), the `Guarded by Magpies (n)` chip, all messages (throttled), `+bonus` text, sounds on the SFX bus, end-screen line, settings toggle saved, help text, F3 skips Auto workers.
- [ ] 17b.V1-V3: model and marker as section 13 (silhouette test vs trading post and Bazaar, budgets, 1 glow point off when pillaged), contact sheet, 5 effects play once / loop and stop, the ruins-pile look told apart from a normal loot sack at 30 m, icons; headless instantiation without errors.
- [ ] 17b.L2: runs of 15.1 pass; CI green; playtest copy moved.
- [ ] 17b.D3: balance notes and knob changes written in section 11.

## 16. What changes in other specs
`market-trade.md`: caravan cargo gains the post bonus (4.3 note), Magpie post and ruin targets and the guarding state (5.2-5.3),
loot sack `lifetime` / `look` and the capped Magpie pickup (5.4), Sweep visits guarded posts first (6.2), bot rules 10k-10o
and champion rule B8 (7), UI lines (8); `buildings.md`: build menu r3c4 P, the `plot_only` rule and messages,
`counts_for_defeat` false for posts; `ui-hud.md`: worker card r2c3 Auto P; `building-levels.md` 5.4: add job 4 (new posts)
under repair; `levels.md`: victim row Roadside Post 15; `ai.md`: rule 10k-10o; `champions.md`: bot rule B8 (Escort 50 on a
worker repairing a guarded ruin, hard); `map-fill.md` 2.3: plots in the "nothing moves" list, waystones skip plots;
`CLAUDE.md` (lead): contracts, Keys, owners.

## 17. Later (not in 17b, only if the user asks)
Other worker improvements can reuse the same pieces (`plot_only` plots, `needs_repair()`, pillage state, WorkerAuto jobs):
a crystal **mine shaft** on a node (+yield), a **farm** / **hunting camp** for step 15 (food), paved **road stretches** (+caravan
speed), and general **building repair** by workers.

## 18. Questions for the user: ANSWERED (2026-09-26)
| # | Question | User's answer | Where in this spec |
|---|---|---|---|
| Q1 | Where can posts be built? | **8 fixed roadside plots, 4 per bank** (the recommendation) | Section 2 |
| Q2 | May Auto workers spend crystals on new posts? | **Yes: own bank only, on roads your caravans use, 100-crystal reserve** (the recommendation) | 7.2 job 4 |
| Q3 | Auto for new workers? | **Off by default + a game setting** (the recommendation) | 7.1, section 10 Settings |
| Q4 | A pillaged post nobody repairs? | **Collapses after 3 minutes** (the recommendation), **and** it drops free gold anyone can pick up, and the **Magpies camp the ruin** (attack repair crews, re-pillage, grab the gold when it falls) | 3.3, **5.4** (pile, camp, counters), 8, 9 (10n-10o), 10, 11 |
No open questions left.

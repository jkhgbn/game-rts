# Markets, trade caravans, gold, the Thieves' and Hunters' guilds

Task 10.D1, written 2026-09-26, revised the same day with the user's answers. Source of truth for step 10 (tasks in
section 14). User request: a market that makes **gold**, trade caravans that walk to distant places and earn by distance,
a thieves' guild whose thieves attack caravans (and workers), and a hunters' guild. Inspired by the *idea* of long-distance
cart trade in classic RTS games and by indirect-control hero games; every name, building, unit, number and rule here is
our own. Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)` on Crown Hollow (`skirmish-1v1.md`,
`balance-1.md`, `champions.md` layout). Point mirror: everything at `(x, z)` on the player (south-west) side exists at
`(-x, -z)` on the enemy (north-east) side. Numbers build on `economy.md`, `buildings.md`, `balance-1.md`, `balance-2.md`,
`items.md`, `levels.md`, `champions.md`.

## 0. User decisions (final, 2026-09-26)
| # | Question | Decision |
|---|---|---|
| Q1 | What does trade pay? | **Gold, a new third resource.** Trade is its main source. Gold buys hunter contracts, Bazaar wares (army / building upgrades), champion hires and revives, and converts to crystals or essence at the Bazaar (section 3) |
| Q2 | Guild buildings | **A Magpie Den and a Greywater Lodge at both neutral corners** (north-west and south-east), point-mirrored |
| Q3 | Who do thieves attack? | **Caravans and workers**: caravans from 5:00; lone or lightly guarded workers at **remote** nodes (>= 30 m from their keep) from **8:00**. Home nodes are never raided |
| Q4 | Can players use the thieves? | **No.** The Magpies are purely neutral: no hiring, no toll, no bribes. The counters are soldiers, towers, champions (bounty flags) and the hunters |
| Q5 | Hunters | **Autonomous contract units** (never ordered), paid in **gold** |

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Resource | **Gold** (third resource, top bar). Start **0**. Earned by trade (main), loot sacks, the Lodge reward for Magpies. Never earned from mining or ordinary kills | The user asked for gold; keeping its sources narrow keeps it the "trade currency" |
| What gold buys | Hunter contracts, 4 one-time **Bazaar wares** (caravans, soldiers x2, buildings), the crystal part of a **champion hire** (1:1) and **revives** (2 gold per essence), and the **exchange** (100 gold -> 80 crystals or -> 40 essence) | Useful in every phase, never mandatory: a player who never trades loses only options |
| Where you trade | Your **Bazaar** (one per kingdom, near your keep) sends **caravans** along roads to one of **4 neutral trading posts**, then back | Two posts are "near" (~26-49 m, your half), two "far" (~120-145 m, ending in the enemy's half): a readable safe / risky choice |
| Pay | By **route length**, locked at the post, paid in gold on return: `round(10 + min(L, 140)² / 136)` per trip | Longer = more per minute, and the long roads are the exposed ones |
| Market own-to-own, enemy market | No. Only Bazaar <-> post | Half the UI and bot rules for little gain on a 120 m map |
| Limits | **1 Bazaar per kingdom** (within 20 m of the keep), **6 caravans** per team | No market spam, no "Bazaar in the far corner" exploit, perf budget |
| Thieves | The **Magpies**: neutral bands from the Magpie Dens. They lurk at fixed spots on the roads and beside remote nodes, rob loaded caravans, kill lone caravans and remote workers, flee home, **drop their loot when killed** | A tax on trade and on remote mining that armies, towers, champions and hunters fight |
| Thieves go where the money is | A band picks its target by weight: gold traded on a road / crystals mined at a remote node in the last 3 min | The richer side is robbed more: a soft comeback lever |
| Hunters | The **Greywater Lodges** sell two gold contracts (Outriders, Sweep) and pay **10 gold per Magpie** killed by anyone | Protection without essence or champions |
| Bounty flags | **No new flag kind.** Hunt flags already accept neutral units (Magpies); Escort flags already accept own units (caravans, workers) | No duplication with step 9 |
| Opening times | Trading posts **4:00**; Dens and Lodges **5:00** (caravan raids); worker raids **8:00** | Openings (hall at 0:00, workers to 6, natural at ~5:00) stay exactly as they are |

## 2. Map: posts, roads, guild houses (systems, 10.C1)
### 2.1 The ring road
Ten road nodes form a ring through both base hubs, the four posts and the two neutral corners. Caravans walk it as waypoints.
| Node | Position | Mirror (enemy side) | Note |
|---|---|---|---|
| `hub` | `(-36, 36)` = `PLAYER_START` | `(36, -36)` = `SHADOW_START` | Base hub (reference only; caravans leave from their Bazaar) |
| `w_door` | `(-49, 1)` | `(49, -1)` = `e_door` | Door of Heron Ford / Lantern Wharf |
| `nw1` | `(-48, -44)` | `(48, 44)` = `se1` | Corner bend |
| `nw2` | `(-44, -48)` | `(44, 48)` = `se2` | Corner bend |
| `s_door` | `(-1, 49)` | `(1, -49)` = `n_door` | Door of Millstone Cross / Saltgate |
Segments (10): `hub-w_door` 37.3, `w_door-nw1` 45.0, `nw1-nw2` 5.7, `nw2-n_door` 45.0, `hub-s_door` 37.3, and their five
mirrors (`hub'-e_door`, `e_door-se1`, `se1-se2`, `se2-s_door`, `hub'-n_door`). Ring order: hub, w_door, nw1, nw2, n_door,
hub', e_door, se1, se2, s_door, back to hub.
- **Corridor**: no tree or rock within **2.5 m** of any segment (removed after the rng draws, like the item clearings, so
  the forest elsewhere stays the same). Ground paint: trodden dirt 3 m wide with wheel ruts (10.V10); minimap 2 px line
  `(0.55, 0.45, 0.30)` in the ground layer (under the fog).
- The lane (keep to keep, width 5) is unchanged; roads only meet it at the hubs.

### 2.2 Trading posts (4, neutral, invulnerable)
| id | Name | Centre | Door | For the player side | For the enemy side |
|---|---|---|---|---|---|
| `heron_ford` | Heron Ford | `(-53, 1)` | `(-49, 1)` | near (west) | far |
| `millstone_cross` | Millstone Cross | `(-1, 53)` | `(-1, 49)` | near (south) | far |
| `lantern_wharf` | Lantern Wharf | `(53, -1)` | `(49, -1)` | far | near (east) |
| `saltgate` | Saltgate | `(1, -53)` | `(1, -49)` | far | near (north) |
- `TradePost` node: team `NEUTRAL`, **invulnerable, never a target**, ignored by every unit, clickable (layer 2, group
  `"trade_posts"`), footprint **6 x 6** blocks the build grid and the navmesh (like the taverns). Clearing r **5**.
- A post is **near** for a team when its door is < 60 m from that team's keep, else **far**.
- Opens at **4:00**: `show_message("The trading posts open their gates")` and a one-time hint
  `Build a Bazaar (B then B with a worker) to send caravans`.
- **Held**: a team holds a post when its soldiers, wizard, champions or trackers stand within **12 m** of the door and none of
  the other team's do (checked once per second). Caravans never trade at a post held by the enemy (4.3).

### 2.3 Guild houses (4: two Magpie Dens, two Greywater Lodges)
| House | North-west corner | South-east corner (mirror) | Door |
|---|---|---|---|
| Magpie Den (Thieves' Guild) | `(-55, -45)` | `(55, 45)` | 1 m outside the face toward the road: `(-51, -45)` / `(51, 45)` |
| Greywater Lodge (Hunters' Guild) | `(-45, -55)` | `(45, 55)` | `(-45, -51)` / `(45, 51)` |
- `GuildHouse` node (`kind` = `&"den"` or `&"lodge"`): neutral, invulnerable, never a target, clickable (group `"guilds"`),
  footprint 6 x 6 blocks grid and navmesh, clearing r **6**. Checks: footprint edge 4 m from the road centre line (1.5 m
  outside the corridor), centre 15.8 m from the rich node `(-40, -40)` (its clearing r 7 does not touch), inside the
  buildable area (x, z >= -58).
- One **Thieves' Guild** and one **Hunters' Guild** (the organisations, sections 5-6) run both houses. Bands leave from the
  Den **nearer their first spot**; trackers leave from the Lodge **nearer their first destination**.
- Why the corners, and why pairs: the only points equally far from both keeps lie on the `x = z` diagonal, whose middle is
  taken (crown, taverns, peddlers, rich halls, rich nodes). With one Den at one corner and one Lodge at the other, the
  point-mirrored bases would line up differently with them (one side's best road next to the thieves, the other's next to
  the hunters). A Den + Lodge at **both** corners keeps every distance mirrored, like the two taverns.

### 2.4 Ambush spots (12: 8 on the roads, 4 beside remote nodes)
| Spot | Position | Mirror | Where | Nearest Den door |
|---|---|---|---|---|
| A1 | `(-44, 15)` | A1m `(44, -15)` | road hub - w_door | 60 m (north-west Den) |
| A2 | `(-15, 44)` | A2m `(15, -44)` | road hub - s_door | 66 m (south-east Den) |
| A3 | `(-48, -22)` | A3m `(48, 22)` | road w_door - nw1 | 23 m |
| A4 | `(-22, -48)` | A4m `(22, 48)` | road nw2 - n_door | 29 m |
| W1 | `(-8, 16)` | W1m `(8, -16)` | 12.8 m from the player-side natural node `(-16, 6)`; 17.9 m from the crown (outside the wardens' reach) | 66 m |
| W2 | `(-50, -30)` | W2m `(50, 30)` | 14.1 m from the player-side rich node `(-40, -40)`, on the west road | 15 m |
Road spots per route, listed **from the post end back toward the base** (bands prefer the deepest valid spot):
| Team | Route | Spots |
|---|---|---|
| Player | Heron Ford (near) | A1 |
| Player | Millstone Cross (near) | A2 |
| Player | Saltgate (far, via Heron Ford and the north-west bend) | A4, A3, A1 |
| Player | Lantern Wharf (far, via Millstone Cross and the south-east bend) | A3m, A4m, A2 |
| Enemy | Lantern Wharf (near) | A1m |
| Enemy | Saltgate (near) | A2m |
| Enemy | Millstone Cross (far, via Lantern Wharf) | A4m, A3m, A1m |
| Enemy | Heron Ford (far, via Saltgate) | A3, A4, A2m |
Worker spots: W1 / W1m serve the two natural nodes, W2 / W2m the two rich nodes (contested: whoever mines there).
**Remote node** for a team = a crystal node more than **30 m** from that team's keep (natural 46 m, rich 83 m); home nodes
(9.5 m) are never raided.

### 2.5 Fog and minimap
- At match start `FogOfWar.reveal(team, pos, 6)` for PLAYER and ENEMY at the 4 posts and the 4 guild houses: all are
  **explored from 0:00** (landmarks). Roads are ground paint: black while unexplored, like the rest of the ground.
- Sight: Bazaar 12, caravan 8, Greywater Tracker 12 (own units, fog sources), Magpie 10. Magpies are hidden when not visible,
  like enemy units (the "a hidden attacker reveals 2 m for 1 s" rule applies). Loot sacks show only in visible cells.
| Minimap icon | Look |
|---|---|
| Trading post | 5 x 5 `(0.85, 0.65, 0.30)` with a 1 px dark border; the border takes the holder's team colour while held |
| Magpie Den / Greywater Lodge | 6 x 6 `(0.45, 0.35, 0.55)` / `(0.40, 0.62, 0.35)` |
| Road | 2 px `(0.55, 0.45, 0.30)` in the ground layer |
| Caravan | 4 x 3 px in the unit colour (own green, enemy red when visible); a 1 px gold dot on it when loaded |
| Magpie (visible) | 3 x 3 `(1.0, 0.65, 0.2)` |
| Loot sack (visible) | 3 x 3 `(1.0, 0.85, 0.3)` |
| Route (Bazaar or caravan selected) | 1 px gold `(1.0, 0.85, 0.3)` polyline Bazaar -> post |

### 2.6 Navmesh and performance
- 8 new 6 x 6 obstacles (posts, houses) exist before the first bake. Bazaars rebake like any building.
- Worst case added units: 12 caravans + 6 Magpies + 10 trackers = **28**. A normal match peaks around 110 units + champions
  (`balance-1.md`), so the 200-unit `PERF OK` budget holds.
- Budget: all trade logic **< 0.1 ms per frame on average** (TradeNetwork: one 1 Hz pass over `"units"` for post holders,
  spot danger and workers per remote node, cached; ThiefBand and TrackerContract think every 0.5 s, staggered 0.1 s;
  caravans only react to arrivals; loot sacks check units within 2 m every 0.25 s, at most 6 sacks). The perf test adds
  12 caravans, 6 Magpies and 6 trackers to its 200 units and must still print `PERF OK`.

## 3. Gold (systems, 10.C11)
### 3.1 The bank
`GoldBank` (`scripts/economy/gold_bank.gd`), one per team, like `EssenceBank`. Only exists when `trade_enabled`.
| Source | Gold |
|---|---|
| Start | **0** |
| Caravan delivery (main source) | The route value (4.3): 15-154 per trip |
| Loot sack picked up (5.4) | Its amount |
| Lodge reward | **10** per Magpie killed by the team (6.3) |
| Nothing else | Mining, ordinary kills, the camp and chests pay no gold |

### 3.2 What gold buys
| Purchase | Where | Price | Effect |
|---|---|---|---|
| **Outriders** / **Sweep** | Lodge tab (anywhere) | **120** / **100** gold | Section 6.2 |
| **Iron-shod Axles** (ware) | Bazaar tab, own completed Bazaar | **150** gold, once | Caravans `move_speed` +0.5 (loaded 4.1), `max_hp` +60 |
| **Masons' Charter** (ware) | Bazaar tab | **350** gold, once | Every own building (existing, under construction and future) **+15 % max HP** (HP gained is healed) |
| **Tempered Steel** (ware) | Bazaar tab | **350** gold, once | Soldiers `attack_damage_pct` +0.08 (modifier `ware:tempered_steel`) |
| **Quilted Gambesons** (ware) | Bazaar tab | **350** gold, once | Soldiers `armor` +10 (modifier `ware:gambesons`; x 0.91 damage taken) |
| **Champion hire** (crystal part) | Tavern window | 1 gold per crystal (200 / 250 / 300) | Pay the crystal part in gold instead; the essence part and pop are unchanged |
| **Champion revive** | Tavern window | **2 gold per essence** (L1 180, L6 480) | Instead of essence |
| **Exchange** | Bazaar tab (needs an own Bazaar) | 100 gold | -> **80 crystals** or -> **40 essence** (Shift = x5). No reverse exchange |
- "Soldiers" = non-worker, non-caravan units of the team except wizards, champions and trackers. Wares apply to living units
  at purchase and to every unit spawned later (`GoldBank.apply_wares(unit)` from `Unit._ready`).
- Refusals: `can_buy_ware(id)` -> `"No Bazaar"`, `"Already owned"`, `"Not enough gold"`; `exchange(amount, to)` ->
  `"No Bazaar"`, `"Not enough gold"`.
- Items stay essence-only; gold reaches them through the exchange (a poor rate on purpose: essence feeds the champion and
  item snowball the 9.D4 notes worry about).
- Masons' Charter is the gold sink that **lengthens games** (keeps +20 % was the only knob that did in `balance-2.md`).

### 3.3 Display
Top bar: a **5th item** after essence, 48 px gap: a 16 px gold coin `(1.0, 0.78, 0.25)` then the number, font 20
`(1.0, 0.88, 0.5)`; the bar widens to about 600 x 40 (exact layout 10.D2). Flashes red 0.4 s on a failed `spend` +
`show_message("Not enough gold")`. Hidden when `trade_enabled` is false. End screen line `Gold earned 2 140 (trade 1 890)`.

## 4. The Bazaar and caravans
### 4.1 The Bazaar (market building; systems 10.C2)
| id | Name | Cost | Build time | max_hp | Footprint | Height | Sight | kill_xp |
|---|---|---|---|---|---|---|---|---|
| `fire_market` | Ember Bazaar | 175 crystals | 40 | 1000 | 3 x 3 | 4.5 | 12 | 80 |
| `shadow_market` | Gloom Bazaar | 175 | 40 | 1000 | 3 x 3 | 4.5 | 12 | 80 |
| `ice_market` | Frost Bazaar | 175 | 40 | **1200** (x 1.2) | 3 x 3 | 4.5 | 12 | 80 |
| `nature_market` | Grove Bazaar | **155** | 40 | **900** (x 0.9) | 3 x 3 | 4.5 | 12 | 80 |
- `kind` `&"market"`, `hotkey_label` **B** (build menu slot r2c2; the Ice Wall keeps r2c1 / V), `max_count` **1**,
  `trains` = [`caravan`], queue 5 like the barracks, counts for defeat, **not** a shop or a drop-off.
- New placement rules (`BuildGrid.check`, after "Blocked by an enemy unit" and before crystals, in this order):
  `"Needs a completed Hall"` (Ember / Gloom / Frost / Grove Hall), then `"Must be within 20 m of your keep"` (centre to
  centre, own living keep). The limit message is `"Only one Bazaar"`.
- **Route**: `Market.route_post`; default = the near post with the higher value from this Bazaar. Set by right-click on a post
  (Bazaar selected) or a route button (section 8). A change applies to each caravan at its next departure (a loaded one first
  delivers).
- Bot slot **M1** (and the natural spot for players): **`(-45, 27)`** / enemy **`(45, -27)`**: 16.1 m from the keep, beside
  the west / east road, 5.1 m from home node a (>= 4 rule ok), inside the base clearing, clear of H1, V1, V2, S1, S2.

### 4.2 Caravan (`data/units/caravan.tres`, one type for all kingdoms, canvas in the team colour; gameplay 10.C6)
| Cost | Pop | Train | HP | Armor | Damage | Speed | Loaded speed | Sight | Radius | Height | kill_xp |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 75 crystals | 1 | 20 s | 220 | 10 | none (aggro 0) | 4.0 | 3.6 (modifier `cargo:load` `move_speed` -0.4) | 8 | 0.8 | 1.9 | 20 |
- Max **6 per team** (alive + queued): `can_queue` -> `"Caravan limit reached"`. Commandable like a worker; never fights,
  never flees on its own.
- The loop (systems 10.C3):
| Step | Rule |
|---|---|
| Load | 2 s at its Bazaar's spawn point (outbound caravans carry nothing of value) |
| Out | Bazaar -> first road node -> ... -> post door (`command_move` per waypoint, never attack-move) |
| Trade | 2 s at the door; cargo = **route value** V in gold, locked now |
| Back | Same waypoints reversed, then its Bazaar; loaded speed 3.6 |
| Deliver | `GoldBank.add(cargo, &"trade")`, `TradeNetwork.record_delivery`, floating `+28` in gold (own, visible only), then loops |
- Before 4:00 caravans wait at the Bazaar (`Waiting: posts open at 4:00`). Bazaar destroyed: a loaded caravan waits at the keep
  and delivers to the next Bazaar of its team.
- Orders: right-click (or G then click) a **post** = trade there from now on; right-click the **own Bazaar** = go home, deliver,
  resume the Bazaar's route. Move / Stop / Hold keep the cargo and leave it idle.

### 4.3 Route length, value and the anti-abuse rules
`L` = straight distance from the Bazaar's centre to the **first road node after the hub** on the shortest ring path from the
team's hub to the post, **plus** the ring length from that node to the post door.
**V = round(10 + min(L, 140)² / 136)** gold per trip. Trip time ~ `L / 4.0 + L / 3.6 + 4` s (real paths 5-10 % longer).
| From the M1 Bazaar (player side; the enemy's is the mirror) | Road | L | V (gold / trip) | Trip | Gold / min per caravan |
|---|---|---|---|---|---|
| Heron Ford (near) | Bazaar -> w_door | 26.3 | **15** | 17.9 s | ~50 |
| Millstone Cross (near) | Bazaar -> s_door | 49.2 | **28** | 30.0 s | ~56 |
| Saltgate (far) | -> w_door -> nw1 -> nw2 -> n_door | 122.0 | **119** | 68.4 s | ~104 |
| Lantern Wharf (far) | -> s_door -> se2 -> se1 -> e_door | 144.9 (cap 140) | **154** | 80.5 s | ~115 |
| Rule | Why |
|---|---|
| Value locked at the post from the caravan's **own** Bazaar position; paid only on delivery | No mid-trip redirect to cash a longer route |
| `L < 20` -> `"Route too short"` (never on Crown Hollow from within 20 m of a keep; guards campaign maps) | The flat part would reward tiny routes |
| L capped at **140**; one Bazaar within 20 m of the keep | No far-corner or forward-market tricks; predictable roads |
| **Held post**: the caravan stops at the last waypoint before the door (near route: 20 m before the door on its leg), waits up to **45 s**, then goes home **empty**; message `Saltgate is held by the enemy: your caravans wait` (max once per 30 s) | The defender can block a far route; caravans do not walk into death |
| A loaded caravan that dies drops a **loot sack** with **50 %** of its cargo (5.4) | Raiding caravans pays a little gold |
| Kill rewards: caravan XP 20 (kill essence 12 by the 60 % rule); kills by Magpies credit nobody | |

### 4.4 Trade vs mining
| Source | Cost | Pop | Income / min | Lasts |
|---|---|---|---|---|
| Worker on a node (`economy.md`) | 50 crystals | 1 | ~70 crystals | Until the node is empty (home ~10:30, natural ~17:30, rich ~21:00) |
| Caravan, near route | 75 crystals | 1 | ~50-56 gold (= ~40-45 crystals if exchanged) | Forever |
| Caravan, far route | 75 crystals | 1 | ~104-115 gold (= ~83-92 crystals) | Forever, if it survives the far road |
| Bazaar + 6 caravans, near | 625 crystals | 6 | ~320 gold | |
| Bazaar + 3 near + 3 far | 625 crystals | 6 | ~490 gold | |
While the home nodes last, a worker beats a near caravan per pop in raw crystals: trade is **the mid-late economy**, the
**far gamble**, and the only way to the wares. Peak mining is ~840 crystals / min (12 workers, `balance-1.md`).

## 5. The Thieves' Guild: the Magpies (service systems 10.C4, bands ai 10.A1)
Purely neutral: nobody hires, bribes or pays them.
### 5.1 The Magpie (`data/units/magpie.tres`, team `NEUTRAL`, faction `&"neutral"`, group `"magpies"`)
| HP | Armor | Damage | Range | Cooldown | DPS | Speed | Aggro | Sight | Radius | Height | kill_xp | Strength (danger) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 140 | 0 | 9 | 1.5 | 1.0 | 9 | 5.2 | **0** (the band chooses targets) | 10 | 0.4 | 1.6 | 25 | 80 |
- **No neutral leash** (`UnitType.neutral_leash = false`): unlike Ruin Wardens they roam; the band brain moves them.
- Veterans: max HP **+10 %** from 10:00 and **+20 %** from 15:00 (modifier `den:veteran`, `max_hp_pct`).
- Carried loot (gold): `thief.get_meta(&"loot", 0)`, max **60** per Magpie; the model shows a sack while > 0.
- Players' soldiers, towers and champions auto-attack Magpies (enemies of both teams). A kill gives the normal XP / essence
  (25 XP, 15 essence) plus **10 gold** from the Lodge (6.3).

### 5.2 Targets and bands
| Rule | Value |
|---|---|
| First band | Not before **5:00** (`show_message("The Magpies are on the roads")` the first time a band leaves) |
| Tick | Every **75 s** from 5:00, if at least one target exists and fewer than **6** Magpies are alive |
| Targets | **Road** of team T (from 5:00): a route with >= 1 trip of T in the last 120 s; weight = gold T traded on it in the last 180 s **+ 30**. **Remote node** of team T (from **8:00**): a node > 30 m from T's keep with **>= 2** of T's workers within 14 m; weight = **0.5 x crystals taken from it** in the last 180 s (sampled every 10 s) **+ 20**. One target drawn by weight (seeded rng) |
| Size | **2**; **3** if 6+ caravans exist on the map or after **12:00**; **+1 after 15:00** (max 4); never above the cap of 6 alive |
| Spot | Road: the first spot of that route's list (2.4) that is valid; remote node: its W spot. **Valid** = no target-team soldier, wizard, champion or tracker within **18 m**, no target-team tower within **20 m**, no target-team keep within **25 m**. None valid -> wait 20 s at the Den door and retry (3 tries, then the band goes back in) |
| Origin | The Den nearer that spot |

### 5.3 Band behaviour (`ThiefBand`, one brain per band, think every 0.5 s)
| State | Rule |
|---|---|
| Leaving | Walk from the Den door to the spot (`command_move`, never attack-move). Attacked on the way: fight back if the attackers' strength <= the band's, else flee |
| Lurking | Hold a loose 3 m cluster for up to **90 s**; road bands then move once to the next valid spot of the same route (another 90 s); then go home |
| Strike check | **Escort strength** around the victim (10 m; ai.md strength: soldiers, wizard, champions' power, trackers 150, towers covering it 150, keep covering it 250) must be **<= 70 x the band's size** |
| Striking a caravan | A **loaded** caravan of the target team within **12 m** -> every Magpie `command_attack`s it. The first within 1.8 m channels **Snatch 1.5 s** (`play_snatch`), broken by **>= 20** damage, then takes `min(cargo, 60)` via `Caravan.steal`; a second Magpie snatches if cargo is left; the others hit the caravan and anyone who attacks them. With the cargo gone the band keeps attacking the caravan until it dies, **max 15 s** (a lone caravan dies in ~13 s to 2 Magpies) |
| Striking workers | A target-team worker within **14 m** of the node (prefer one carrying crystals) -> all Magpies attack it; then the next. Stop after **2 worker kills** or **15 s**. A killed worker's carried crystals become loot (as gold) |
| Fleeing | Triggers: the strike is over, or the band is hit by a force stronger than itself, or half the band is dead. At the start every Magpie gets `shroud` **2 s** (smoke, +2 m/s, half damage); all walk to the nearer Den door |
| Home | A Magpie at a Den door **leaves the map** (`Unit.leave_map()`: no death, no XP; a Hunt flag on it is refunded 100 %); its loot is gone (fenced) |
| Sacks | Any loot sack within **15 m** while not striking: a Magpie walks over and takes it |
A dead Magpie drops its loot as a **loot sack**. A band never attacks buildings or soldiers first, never touches workers at
home nodes, and never chases more than 15 m from its spot except to strike or to reach a sack.

### 5.4 Loot sacks (`LootSack`, systems 10.C1)
| Rule | Value |
|---|---|
| Drop | A Magpie dies with loot > 0 (all of it), or a loaded caravan dies (50 % of the cargo, rounded down); nothing below 1 |
| Pickup | Automatically by the first living unit within **2 m**: any PLAYER / ENEMY unit (soldier, worker, caravan, wizard, champion, tracker) -> that team's **gold**; a Magpie -> its carried loot |
| Lifetime | **45 s**, then it fades (lost) |
| Messages | `Picked up a loot sack: 60 gold` (own team) |

### 5.5 The Den (click only)
Clicking a Den opens a read-only info panel: `Magpie Den (Thieves' Guild)`, `Thieves who rob caravans and remote workers. They
answer to no one.`, `On the roads from 5:00 · raid remote mines from 8:00`, `Magpies you can see: 3`. No buttons.

## 6. The Hunters' Guild: Greywater Lodges (service systems 10.C5, contracts ai 10.A2)
### 6.1 The Greywater Tracker (`data/units/greywater_tracker.tres`, owned by the hiring team, group `"trackers"`)
| HP | Armor | Damage | Range | Cooldown | DPS | On hit | Speed | Aggro | Sight | Radius | Height | Pop | kill_xp |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 240 | 5 | 12 | 7.0 | 1.2 | 10 | `rooted` **0.5 s** (snare arrow; halved on heroes) | 5.4 | **0** | 12 | 0.45 | 1.8 | 0 | 40 |
- **Not commandable** (`UnitType.commandable = false`): click = read-only inspect, like a champion; never in box select,
  groups, F2 or right-click orders. No levels, items, veterancy or wares. Strength 150 (danger checks only, never army).
- They only attack Magpies and units that attacked them or their charges in the last 3 s; they never start fights with
  enemy soldiers. At contract end they fade out where they stand (`leave_map()`, 1 s).

### 6.2 Contracts (the Lodge tab of the trade window, key U)
| Contract | Price | Trackers | Duration | Behaviour |
|---|---|---|---|---|
| **Outriders** | **120 gold** | 2 | 180 s | Each tracker shadows one own caravan (the loaded one farthest from home first, then the one on the longest route; never both on one), **4 m** behind it (re-picked every 2 s); shoots any Magpie within 12 m of any own caravan it can reach within 15 m, and anything that hit its caravan in the last 3 s; never more than 15 m from its caravan |
| **Sweep** | **100 gold** | 3 | 120 s | Walk the hiring team's spots in order: the W spots of its remote nodes that have workers, then the road spots of its busiest route, then the others; attack every Magpie within 15 m; chase a Magpie **carrying loot** up to 30 m; after the last spot, start over |
| Rules | | | | Open from **5:00**; one contract of each kind per team; **30 s** cooldown after it ends; trackers leave from the Lodge nearer their first destination. Refusals in order: `"The Lodge opens at 5:00"`, `"Contract already running"`, `"On cooldown"`, `"No caravans to escort"` (Outriders only), `"Not enough gold"` |

### 6.3 The Lodge reward
Every Magpie killed pays **10 gold** to the team credited with the killing blow (soldiers, towers, wizards, champions,
trackers for their hiring team). Message summed at most once per 10 s: `Greywater Lodge pays 20 gold for 2 Magpies`.

### 6.4 How it fits the step-9 bounty flags and champions (no duplication)
| Tool | Paid in | Control | Lasts | Best for |
|---|---|---|---|---|
| **Hunt** flag on a Magpie (already valid: a visible neutral unit) | Essence | Champions decide | Until it dies or leaves the map (then 100 % refund) | A champion after a band that robbed you |
| **Escort** flag on a caravan or worker (already valid: own living unit) | Essence | Champions decide | 180 s | One far caravan or a remote miner |
| **Guard** flag on the natural / rich hall (already valid) | Essence | Champions decide | 180 s | Keeping champions at a raided expansion |
| **Outriders** / **Sweep** | Gold | None (contract) | 180 / 120 s | Cheap, short protection |
| A tower at the remote node or on the near road | Crystals | None | Permanent | Bands skip spots within 20 m of your towers |
| Soldiers | Crystals + pop | Direct | | Holding a post, guarding an expansion, raiding enemy caravans |
- `ChampionBrain` (10.A3): the Coin-Cutter's **Raid** default (champions.md 8.3) also targets a visible Magpie **carrying
  loot** within 30 m; the Oathwall's **Patrol** already covers the forward halls, so it answers worker raids there. Every
  champion's R4 "join a fight" covers caravans and workers in its engage radius. Nothing else in `champions.md` changes.

## 7. The bot (ai 10.A3: `scripts/ai/ai_trade.gd`, rule 10 of `ai.md`, knobs in `AIProfile` / `data/ai/*.tres`)
The bot knows the map (posts, roads, spots, houses) and sees units only through its fog, as today.
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `trade_start` (earliest Bazaar) | 8:00 | 5:30 | 4:30 |
| `caravan_target` / `caravan_target_late` (home nodes a + b both empty) | 2 / 3 | 4 / 6 | 6 / 6 |
| `far_route_caravans` | 0 | 2 | 3 |
| `far_route_ratio` (own_strength >= ratio x max(seen_strength, 250)) | - | 1.5 | 1.2 |
| `ware_order` | Masons' Charter | Iron-shod Axles (at 3+ caravans), Masons' Charter, Tempered Steel, Quilted Gambesons | Tempered Steel, Iron-shod Axles, Quilted Gambesons, Masons' Charter |
| Outriders / Sweep | never | Outriders | both |
| Gold for champions | never | revive in gold when essence is short | + hire's crystal part in gold when gold >= price + 100 |
| `gold_exchange_above` (surplus -> crystals) | 200 | 450 | 600 |
| Champion flags | - | B5 | B5, B6, B7 |
| Rule | Trigger -> action (first that applies each tick; at most one gold purchase per tick) |
|---|---|
| 10a Bazaar | Time >= `trade_start`, a completed Hall, crystals >= 175 + 100, no build waiting -> place at **M1** `(45, -27)` (player-side bot `(-45, 27)`), shifts `(0, 4)` then `(4, 0)` after 3 refusals. Build row **7** of `ai.md` rule 4; a destroyed Bazaar is rebuilt after 60 s with crystals >= 250 |
| 10b Behind | `seen_strength > 1.5 x own_strength` for 60 s, time >= 4:00, no Bazaar -> build now (ignores `trade_start`); while behind, `caravan_target` +1 and near routes only. **The comeback path** |
| 10c Caravans | Caravans (alive + queued) < target, crystals >= 125, `pop_used + 1 <= pop_cap - 2`, Bazaar queue empty -> queue one (shares the 20 s rule with builds) |
| 10d Routes (every 30 s) | Default: the near post with the higher value (from M1: Saltgate 28 for the enemy side) unless **unsafe** (a caravan on it robbed or killed in the last 90 s, or an enemy group with strength >= 150 seen within 15 m of its road in the last 60 s) -> the other near post. Far: up to `far_route_caravans` caravans to the higher-value far post when the ratio holds and no Magpie or enemy was seen on that road in 90 s |
| 10e Remote raid | Magpies killed or robbed a bot worker at a remote node -> workers there flee to the nearest drop-off (existing worker rule) and return 6 s after the last damage; if no own tower is within 20 m of that node and crystals >= 120 + 50, place a Spire at slot **S3** (natural) `(19, -1)` / player-side `(-19, 1)` or **S4** (rich) `(37, 45)` / `(-37, -45)`, max 1 each (tower `max_count` 4 still applies) |
| 10f Hunters | A caravan robbed or killed in the last 120 s -> **Outriders** if gold >= 120 (normal / hard). Hard: Magpies seen within 15 m of one of its spots in the last 20 s and no own soldier within 25 m -> **Sweep** if gold >= 100 |
| 10g Wares | Gold >= next ware price + 50 (reserve for Outriders) and a Bazaar -> buy the next ware of `ware_order` |
| 10h Champions | A fallen champion, essence < revive price, gold >= 2 x price -> revive in gold (normal / hard). Hard: hire with gold when gold >= crystal part + 100 |
| 10i Exchange | Gold > `gold_exchange_above` after 10f-10h -> exchange the surplus in steps of 100 into crystals (into essence instead when the next item is within 100 essence) |
| 10j Defend | A caravan or worker damaged within **35 m** of an own building counts as a rule-1 intrusion (the natural and rich halls count). Farther away the army does not go: the route becomes unsafe (10d) |
| Champion B5 (normal, hard) | A loaded caravan on a far route and no such flag -> **Escort 50** on it (max 1) |
| Champion B6 (hard) | A visible Magpie carrying loot within 30 m of a bot champion -> **Hunt 75** on it |
| Champion B7 (hard) | A remote node raided in the last 60 s with an own forward hall -> **Guard 50** on that hall |
- Strength: caravans and trackers count 0 in `own_strength` / `seen_strength`; Magpies never count as the enemy army (kept in
  a `thief_sightings` list per spot for 10d / 10f). Concede rule: also requires **no caravans and no Bazaar**.
- Expected (normal): Bazaar 5:30-6:30, 4 caravans by ~8:00 (~210 gold / min), first band 6:30-7:30, Outriders after the first
  robbery, Iron-shod Axles ~9:00, Masons' Charter ~11:00, first worker raid on a remote node 8:00-10:00.

## 8. UI: what must be shown (layout, sizes, looks: ui-designer, `docs/design/ui-trade.md`, task 10.D2)
| Element | Content | Interaction |
|---|---|---|
| Top bar | Gold item (3.3) | Red flash on a failed spend |
| Build menu | **Bazaar B** at r2c2. Tooltip `Ember Bazaar  [B]\nCost 175 crystals · 40 s · 1000 HP\nSends caravans to the trading posts for gold. Within 20 m of your keep. One per kingdom.` + reason when disabled | B with the build menu open = place |
| Bazaar card | r1c1 **Caravan Z** (`Caravan  [Z]\nCost 75 crystals · Pop 1 · 20 s\nTrades with a post and brings gold back. Max 6.`), r1c2 Set Route (button, no key), r1c3 **Wares U** (opens the Bazaar tab), r2c1-r2c4 one **route button per post**: name, near / far, `28 gold / trip` (disabled + reason: `Opens at 4:00`, `Held by the enemy`) | Right-click a post = set route; right-click the ground: `Right-click a trading post to set the route` |
| Bazaar panel | Name, HP, queue; `Route: Millstone Cross (near) · 28 gold per trip · ~56 / min each`; `Caravans 4 / 6 (1 queued)`; `Gold traded, last 3 min: 620 · total 2 140` | |
| Caravan card / panel | Move M, Stop C, Hold H, **Trade G**. Single view: HP, `Cargo 119 gold` or `Empty`, `Route: Saltgate (far)`, state `To Saltgate` / `Trading` / `Returning with 119` / `Waiting: Saltgate is held` / `Idle` | G then click a post (or own Bazaar). With workers too: G then a node = gather, a post = trade, the Bazaar = go home |
| Route line | Dashed gold `(1.0, 0.85, 0.3, 0.8)` ribbon 0.25 m wide at y 0.3 along the waypoints while the Bazaar or a caravan is selected; hovering a post with the Bazaar selected previews it and shows `Saltgate · far · 119 gold / trip · ~104 / min` | |
| Loaded caravans | Model state (strongbox + gold lantern, 10.V5); `+28` gold floating text at the Bazaar on delivery (own, visible) | |
| **Trade window** (**U**; the Bazaar's Wares button; a Lodge click) | Two tabs. **Bazaar**: the 4 wares (name, effect line, price, `Owned` / reason), the exchange (`100 gold -> 80 crystals`, `100 gold -> 40 essence`, Shift = x5); without a Bazaar: `Build a Bazaar to buy wares and exchange gold`. **Greywater Lodge (Hunters' Guild)**: Outriders and Sweep rows (price, trackers, duration, time left / cooldown / reason), line `The Lodge pays 10 gold for every Magpie slain` | Buttons call the GoldBank / HuntersGuild APIs; Esc / U close |
| Tavern window (step 9) | Hire row: a second price button `200 gold · 75 essence` next to `200 crystals · 75 essence`; revive: `Revive 90 essence` and `Revive 180 gold` | `ChampionGuild.hire(id, true)` / `revive(ch, true)` |
| Post panel (click a post) | Name, `Opens at 4:00` / `Open`, `For you: near · 28 gold per trip from your Bazaar` or `Build a Bazaar to trade`, `Held by the enemy`; button `Set as route` when you own a Bazaar | |
| Den panel (click a Den) | Read-only text of 5.5 | |
| Trackers | Inspect only (name, HP, contract, time left); command card text `Hired hunters act on their own.` | |
| Messages | `The trading posts open their gates` · `The Magpies are on the roads` · `Magpies raid your miners at <node>!` (first strike on a remote node, then max once per 30 s) · `Your caravan was robbed: -119 gold` · `Your caravan was destroyed` · `Saltgate is held by the enemy: your caravans wait` · `Picked up a loot sack: 60 gold` · `Outriders hired: 2 trackers guard your caravans` · `Sweep hired: 3 trackers clear your roads and mines` · `Greywater Lodge pays 20 gold for 2 Magpies` · `Bought Masons' Charter` · `Exchanged 100 gold for 80 crystals` | `show_message`; robbery / loss lines max once per 10 s, summed |
| Minimap | Section 2.5 | |
| End screen | `Gold earned 2 140 (trade 1 890) · Caravans lost 3 · Workers lost to Magpies 2 · Magpies slain 5` | |
| Settings | Skirmish option **Trade and guilds: On / Off** (default On) | Sets `Skirmish.trade_enabled` before the scene enters the tree |
| Help text | Adds `U: trade & hunters    G: trade (caravans)    B, B: Bazaar` | |
| Audio (ui-coder) | Coin clink on own delivery (visible), a two-note whistle when a band strikes a visible own caravan or worker, a horn when a contract starts | SFX bus |
**Keys** (physical; for the lead's Keys line): **U** = trade window (Bazaar / Lodge tabs); caravans selected: **G** = trade
(then click a post or the own Bazaar); build menu: **B** = Bazaar; Bazaar selected: **Z** = caravan, right-click a post = route.
U is free today (W A S D Q E F, X C H G B M Z V R Y T, digits, F1-F3, F5-F7, F9-F11, Delete are taken).

## 9. Art list (tech-artists; global style `art-keep.md` section 0: chunky, hand-painted, 2-4 glow points at 40 m)
| Id | Asset | Silhouette (the 40 m black test) and look | Budget / hooks |
|---|---|---|---|
| 10.V1 | **Ember Bazaar** (Fire) | Dominant vertical: a tall bronze mast with a hanging **balance scale** sign; secondary: a striped awning stall (team colour) + a crate stack on one side. Fire palette (art-keep 0.2), ember lanterns | Footprint 6 x 6, ~5.5 m to the scale; hall budget; hooks as the other buildings (`set_selected`, construction, damage) + `play_delivery()` (the scale tips, coins glint) |
| 10.V2 | **Gloom Bazaar** (Shadow) | Same read, tarnished-silver scale, purple awnings, violet lanterns, a hooded "night stall" | Same |
| 10.V3 | **Frost Bazaar** (Ice) | Silver-blue scale on an ice-crystal mast, sled-runner stalls, frosted crates | Same |
| 10.V4 | **Grove Bazaar** (Nature) | A living-branch mast, leaf awnings, bark stalls, glow-fruit lanterns | Same |
| 10.V5 | **Caravan** | Two-wheeled covered wagon (canvas = team colour via `set_team_color`) pulled by a stocky shaggy short-horned draught beast; ~3.2 m long, 1.9 m tall. **Loaded**: a brass-bound strongbox on the tailboard + a gold lantern (glow `(1.0, 0.85, 0.3)` 2.5): readable at 40 m | `set_loaded(bool)`, walk cycle (beast + wheel spin), `play_death`; <= 24 meshes, <= 14 draw instances, 0 lights, <= 5 materials |
| 10.V6 | **Magpie** (thief) | Lean, **beaked half-mask** (black and white), patchwork black / white cloak with an iridescent blue-green trim, twin knives, crouched idle ("lurk") | `set_carrying(bool)` (loot sack on the back), `play_snatch()`, lurk idle; soldier budget (<= 18 meshes, <= 10 draw instances, 0 lights); 1 glow point (eye shine blue-green) |
| 10.V7 | **Greywater Tracker** | Grey-green hood, fur mantle, **longbow taller than the body**, snare-rope coil on the hip, team-colour armband (`set_team_color`) | Soldier budget; amber arrow tip glow while drawing |
| 10.V8 | **Magpie Den** | A crooked, leaning tall timber house with a **magpie weather-vane** on the roof peak (dominant), a sack-hoist crane on one side (secondary), black / white shutters, tattered stolen banners in all four kingdom colours | 6 x 6, ~7 m; tavern budget; blue-green lantern; `set_open(bool)`, `play_band_out()` (door swings, dust) |
| 10.V9 | **Greywater Lodge** | Long low log hall, a tall **stone chimney** with smoke (dominant), a raised watch platform with a pelt rack (secondary), grey-green shingles | 6 x 6, ~6 m; amber lantern; `set_open(bool)`, `play_contract()` (horn flag raised) |
| 10.V10 | **Trading post** + roads | Open-sided timber waystation with a **tall signpost mast** whose hanging sign changes per post (heron, millstone, lantern, gate), hitching rail and crates; road = dirt 3 m wide with ruts in the ground shader + waystones every ~10 m (MultiMesh) | `set_sign(i)` (0-3), `set_open(bool)`, `set_held(color_or_null)` (a small pennant); 6 x 6, ~5 m; lantern `(1.0, 0.8, 0.4)`. Ground: shader uniforms `road_segs` (vec4[16], a.xz b.xz), `road_count`, `road_width` |
| 10.V11 | **Trade VFX + loot sack** | `delivery` (gold motes up 1.5 m, 0.6 s), `post_trade` (dust + 3 coins arc), `snatch` (coin trail victim -> thief, 0.4 s), `smoke` (grey-blue puff r 3, 1.2 s, MIX), `sack_pickup` (sparkle), `snare` (rope ring on the ground, 0.5 s), `ware_bought` (gold ring pulse on the Bazaar). Loot sack: 0.5 m burlap sack with a coin spill, gold rim glow, slow bob | `TradeVfx.play(id, at, target)`; one-shot emitters pre-built and restarted; `art/vfx/trade_loot_sack.tscn` |
| 10.V12 | **Icons** (phase 2) | Gold coin (top bar), 4 Bazaars, Caravan, Trade order, 4 post signs, 4 wares, 2 exchange arrows, Outriders, Sweep, Magpie, Tracker, 2 tab crests | Same renderer and size as the existing icon set |

## 10. Campaign
- `Skirmish.trade_enabled` (exported, like `tavern_enabled`): true in the skirmish, **false by default in missions** (no gold,
  no top-bar item, no Magpies).
- **No trade in missions 1-3** (mission 3 introduces champions; one new system per mission). First use proposed: **mission 4**,
  "The Salt Road": keep one far route alive (deliver 1 500 gold) while Magpie bands grow; posts and roads placed by the mission
  with `TradeNetwork.setup(...)`.
- Gold is not carried between missions (wares, Bazaar and caravans are per mission).

## 11. Balance
### 11.1 What trade adds to a normal bot-vs-bot match (both sides trade)
| Time | Trade (each side) | Effect |
|---|---|---|
| 4:00-5:00 | Posts open; nobody trades yet | Openings unchanged |
| 5:30-6:30 | Bazaar (175 crystals) | About one soldier less at the first big fight |
| 6:00-8:00 | 4 caravans (300 crystals) | ~475 crystals invested: **armies ~5 % smaller at 7:00-9:00 on both sides** |
| 6:30-8:00 | First Magpie bands on the busiest road | Some caravans lost; Outriders appear |
| 8:00-10:30 | ~210 gold / min; Iron-shod Axles ~9:00; first raids on remote miners | Expansions need a tower or a guard: armies stay home a little more |
| 10:30+ | Home nodes empty: `caravan_target_late` 6, ~320 gold / min | Masons' Charter ~11:00 (+15 % building HP), then the soldier wares ~13:00-15:00 |
| 12:00+ | Far routes when ahead; exchange of surplus gold | The leader's far caravans end in the loser's half (loser kills them: sacks + essence) |

### 11.2 Match length and the comeback path
- **Not shorter**: trade pays back only around 10:00 (in wares or exchanged crystals), so both armies are a bit smaller early;
  remote-miner raids from 8:00 keep some soldiers home; Masons' Charter makes every building 15 % tougher from ~11:00.
- **Comeback**: (1) near roads sit in your own half and need no node, so a side that lost its expansions still earns ~320 gold
  / min (~255 crystals if exchanged); a flat income matters more to the smaller economy (840 + 255 vs 420 + 255 crystals: the
  gap shrinks from 2.0x to 1.6x). (2) Magpies weight targets by gold traded and crystals mined remotely: the richer side is
  robbed more. (3) Far routes end next to the enemy's base, so the leader's greed feeds the defender. (4) The bot builds its
  Bazaar early when behind (10b).
- **Longer**: after the home nodes run dry (~10:30) both sides still have income, and the building ware slows sieges. Expected:
  even pairs **+0:45 to +2:00** median length. Trade does **not** fix the champion snowball (9.D4 notes: ~9-11 min games);
  those knobs stay in `champions.md` 12.

### 11.3 Worker raids (Q3) must not wreck the early economy
| Guard rail | Value |
|---|---|
| Earliest | **8:00** (every kingdom's natural is up by ~5:30; the rich node is taken ~9:00) |
| Where | Only nodes > 30 m from the team's keep (natural, rich); never home nodes |
| Who | Only when >= 2 workers are at the node and the escort strength <= 70 x band size (a Spire = 150 blocks a band of 2; a Spire + 1 soldier blocks 3) |
| How much | Max **2 worker kills** per strike, then the band flees (~100 crystals + ~1 min of that node's income) |
| How often | One band per 75 s shared by every target of both teams: about one raid per team every 3-5 min when unguarded |
| Counters | A Spire at the node (120 crystals, bands skip it for good), Sweep (100 gold), a Guard flag on the forward hall, the Oathwall's patrol, soldiers |

### 11.4 Fight checks
| Fight | Result |
|---|---|
| 2 Magpies vs a lone loaded far caravan (119 gold) | Snatch 60 + 59 in ~2 s, caravan dead in ~13 s: the owner loses 119 gold + 75 crystals |
| 2 Magpies vs caravan + 1 Shade (escort 80 <= 140) | They strike: the Shade dies in ~6 s (the Magpies lose ~67 HP), then robbery. With **2 Shades** (160 > 140) they stay hidden |
| 2 Magpies vs 3 workers at the natural (50 HP each, no tower) | 2 workers dead in ~6 s (18 DPS), then flee; the third runs to the hall |
| Band of 3 vs 2 Outriders (300 > 210) | No strike: Outriders deter every band of 4 or less, but only around the 2 caravans they follow |
| Sweep (3 trackers, 720 HP, 30 DPS, roots) vs a lurking band of 3 (420 HP, 27 DPS) | The band flees; snare arrows (0.5 s root per hit, shroud lasts 2 s) let the trackers kill 1-2 of 3 (+10-20 gold) |
| L1 Coin-Cutter (300 HP, 18.9 DPS) vs 2 Magpies (17.1 DPS after armor 5) | Wins with ~35-45 % HP; a Hunt 75 on a looter is a fair job |
| Ember Spire vs a Magpie | Dies in ~14 s: bands skip spots within 20 m of your towers |
| Wares | Tempered Steel + Quilted Gambesons (700 gold) = +8 % damage and x 0.91 damage taken: ~+19 % army value, about 2 min of a 6-caravan trade; Masons' Charter keeps 2 500 -> 2 875 HP |
| Tax check (normal bot, 4 near caravans, ~210 gold / min) | Unprotected it loses about one caravan + cargo every ~2.5 min; Outriders (120 per 3 min) cover 2 of the 4. Trade nets ~160-180 gold / min |

### 11.5 Knobs (one at a time)
| Symptom | Knob |
|---|---|
| Nobody trades (bot or playtest) | V flat 10 -> **15**; caravan cost 75 -> **65** crystals |
| Gold piles up unused | Exchange 100 -> 80 crystals -> **90**; add a 5th ware |
| Trade > 35 % of income before 12:00, or games shorter than the no-trade control | Far cap 140 -> **120**; `caravan_target` normal 4 -> **3**; soldier wares 350 -> **450** |
| Worker raids hurt too much | Earliest 8:00 -> **10:00**; max kills 2 -> **1**; remote distance 30 -> **50 m** (rich nodes only) |
| Worker raids irrelevant | Earliest 8:00 -> **7:00**; strike threshold 70 -> **90** per Magpie |
| Thieves too punishing on caravans | Finish time 15 s -> **8 s** (rob, rarely kill); band size 2 -> **1** before 10:00 |
| Hunters never hired | Outriders 120 -> **90** gold; Lodge reward 10 -> **15** |
| Magpie farming (XP / essence / gold) | kill_xp 25 -> **15**; Lodge reward 10 -> **5** |

### 11.6 Re-test plan (lead 10.L2, then 10.D3)
Harness: the 9.C11 bot-vs-bot run (normal, cap 24:00) with a new `--no-trade` flag as the control.
| Round | Pairs (both orders) | Runs | Pass |
|---|---|---|---|
| A | fire-shadow, nature-ice, shadow-nature | 2 with trade + 2 `--no-trade` each = **12** | Median length with trade >= control **- 0:30**; no pair where the winner changes side in all runs because of trade |
| B | same runs | - | Gold traded 1 500-4 000 per side by 15:00 (or the end); at least 1 Magpie strike on a caravan and 1 on remote workers per game after 10:00; each side buys >= 1 ware; workers lost to Magpies <= 6 per side per game; 0 script errors |
| Perf | perf test + 12 caravans, 6 Magpies, 6 trackers | 1 | `PERF OK`, stuck = 0 |

## 12. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 10.L1)
Rule for phase-1 agents (as in step 9): never use another step-10 agent's new `class_name` as a static type; reach it with
`load()` guarded by `ResourceLoader.exists`, groups, `has_method()`, `get()`.
- **GoldBank** (`scripts/economy/gold_bank.gd`, `class_name GoldBank extends Node`, one per team, group `"gold_banks"`,
  `static func for_team(team: int) -> GoldBank`, null when trade is off): `gold: int`, `START_GOLD := 0`, `can_afford(n) -> bool`,
  `add(n: int, source: StringName = &"")`, `spend(n: int) -> bool`, `earned(source: StringName = &"") -> int` (total or per
  source: `&"trade"`, `&"loot"`, `&"reward"`), signals `changed(gold: int)`, `spend_failed`. Wares: `WARES` (ids
  `&"iron_axles"`, `&"masons_charter"`, `&"tempered_steel"`, `&"gambesons"`: price, stats, filter), `owned_wares: Array[StringName]`,
  `can_buy_ware(id) -> String`, `buy_ware(id) -> String`, `apply_wares(unit: Node)` (idempotent; `Unit._ready` calls it through
  the group), `building_hp_mult() -> float` (1.0 / 1.15). Exchange: `EXCHANGE := {&"crystals": 80, &"essence": 40}` per 100,
  `exchange(amount: int, to: StringName) -> String`, signal `ware_bought(id)`.
- **TradeNetwork** (`scripts/world/trade_network.gd`, `class_name TradeNetwork extends Node`, one per match, group
  `"trade_network"`, `static func instance(tree: SceneTree) -> TradeNetwork`): `setup(posts: Array, nodes: Dictionary,
  segments: Array, spots: Dictionary)`, `OPEN_TIME := 240.0`, `is_open() -> bool`, `time_until_open() -> float`, `posts() -> Array`,
  `road_segments() -> Array[PackedVector3Array]`, `route_points(market: Node3D, post: Node3D) -> PackedVector3Array`,
  `route_length(market, post) -> float`, `route_value(market, post) -> int`, `route_reason(market, post) -> String` (`""`,
  `"Trading posts open at 4:00"`, `"Route too short"`, `"Held by the enemy"`), `is_far(team: int, post) -> bool`,
  `ambush_spots(team: int, post) -> Array[Vector3]` (post end first), `worker_spot(node: Node3D) -> Vector3`,
  `remote_nodes(team: int) -> Array` (nodes > 30 m from the team's keep), `workers_at(team: int, node) -> Array`,
  `mined_recently(node, seconds := 180.0) -> int`, `record_delivery(team, amount, post, caravan)`, `trade_income(team: int,
  seconds := 180.0) -> int`, `trips(team: int, post, seconds := 120.0) -> int`, `caravans_lost(team) -> int`,
  `workers_lost_to_magpies(team) -> int`, `strength_near(team: int, pos: Vector3, radius: float) -> float` (1 Hz cache), signals
  `posts_opened`, `delivered(team: int, caravan: Node, amount: int, post: Node)`, `caravan_robbed(team: int, caravan: Node,
  amount: int, thief: Node)`, `workers_raided(team: int, node: Node)`, `post_held_changed(post: Node, holder_team: int)`.
- **TradePost** (`scripts/world/trade_post.gd`, `class_name TradePost extends Node3D`, group `"trade_posts"`, layer 2, NEUTRAL):
  `post_id: StringName`, `display_name`, `sign_index: int`, `door_point() -> Vector3`, `is_open()`, `holder_team() -> int` (-1),
  `is_held_by_enemy_of(team) -> bool`, `is_alive()` (true), `is_targetable()` (false), `is_invulnerable()` (true), `take_damage()`
  (no-op), `set_selected(bool)`, `footprint_rect() -> Rect2`.
- **GuildHouse** (`scripts/world/guild_house.gd`, `class_name GuildHouse extends Node3D`, group `"guilds"`, layer 2, NEUTRAL,
  invulnerable like TradePost): `kind: StringName` (`&"den"` / `&"lodge"`), `door_point()`, `is_open()`, `set_selected(bool)`.
- **LootSack** (`scripts/world/loot_sack.gd`, `class_name LootSack extends Node3D`, group `"loot_sacks"`): `amount: int` (gold),
  `static func spawn(parent: Node, pos: Vector3, amount: int) -> LootSack`, `take(by: Node3D) -> int`, `LIFETIME := 45.0`,
  `PICKUP_RADIUS := 2.0`, signal `picked(sack, team: int, amount: int)` (team NEUTRAL for a Magpie).
- **Market** (`scripts/buildings/market.gd`, `class_name Market extends TrainingBuilding`, kind `&"market"`): `route_post: Node3D`,
  `set_route(post: Node3D) -> String` (`""`, `"Not a trading post"`, `"Route too short"`), `route_value() -> int`,
  `caravans() -> Array`, `CARAVAN_LIMIT := 6`, `can_queue` adds `"Caravan limit reached"`, signal `route_changed(market, post)`,
  `static func of_team(team: int) -> Market` (completed, alive, or null; lead 2026-09-26: renamed from `for_team`, which
  clashes with `Building.for_team`; every Bazaar is in group `"markets"`).
- **BuildingType / BuildGrid / Building**: `ALL_IDS` gains the 4 market ids; fields `requires_kind: StringName` (`&"barracks"`),
  `max_keep_distance: float` (20.0; 0 = no rule); messages `MSG_NEEDS_HALL := "Needs a completed Hall"`,
  `MSG_KEEP_DISTANCE := "Must be within 20 m of your keep"`, `MSG_MARKET_LIMIT := "Only one Bazaar"`. `Building` scales its
  `max_hp` by `GoldBank.building_hp_mult()` at creation and when the Charter is bought (heals the gain).
- **Caravan** (`scripts/economy/caravan.gd`, `class_name Caravan extends Unit`, groups `"units"`, `"caravans"`, created by
  `Worker.make_unit` when `UnitType.is_caravan`): `cargo: int` (gold), `home_market: Node3D`, `route_post: Node3D`,
  `trade_state: StringName` (`&"idle"`, `&"loading"`, `&"to_post"`, `&"trading"`, `&"returning"`, `&"waiting"`),
  `command_trade(target: Node3D) -> String` (a post, or the own Bazaar; `""`, `"Not a trading post"`, `"No Bazaar"`),
  `is_loaded() -> bool`, `steal(amount: int, thief: Node3D) -> int`, `state_text() -> String`, signals `cargo_changed(caravan,
  amount: int)`, `delivered(caravan, amount: int)`, `robbed(caravan, amount: int, thief: Node3D)`. Calls `set_loaded(bool)` on its
  model if present.
- **Unit / UnitType** (gameplay): `UnitType.is_caravan := false`, `UnitType.commandable := true`, `UnitType.neutral_leash := true`;
  `Unit.is_commandable()` returns `unit_type.commandable` (Champion still false); a NEUTRAL unit with `neutral_leash = false` ignores
  the leash rules; `Unit.leave_map()` (1 s fade, no `died`, no XP / essence / loot, frees pop, new signal `left_map(unit)`);
  `Unit._ready` calls `apply_wares(self)` on the team's GoldBank if one exists (group lookup). New `.tres`: `caravan`, `magpie`,
  `greywater_tracker` (4.2 / 5.1 / 6.1). Victim table (`levels.md`): Caravan 20, Magpie 25, Greywater Tracker 40, Bazaar 80.
- **ThievesGuild** (`scripts/world/thieves_guild.gd`, `class_name ThievesGuild extends Node`, one per match, group
  `"thieves_guild"`, `static func instance(tree) -> ThievesGuild`): `OPEN_TIME := 300.0`, `WORKER_RAID_TIME := 480.0`,
  `TICK := 75.0`, `MAX_ALIVE := 6`, `is_open()`, `dens() -> Array`, `bands() -> Array`, `targets() -> Array[Dictionary]`
  (`{kind: &"road" / &"workers", team, post or node, spot, weight}`, for tests and the UI count), `magpies_alive() -> int`, signals
  `band_sent(band)`, `band_finished(band)`. No purchase API (Q4).
- **HuntersGuild** (`scripts/world/hunters_guild.gd`, `class_name HuntersGuild extends Node`, one per match, group
  `"hunters_guild"`, `static func instance(tree)`): `OPEN_TIME := 300.0`, `CONTRACTS` (`&"outriders"`: 120 gold / 2 / 180 s,
  `&"sweep"`: 100 gold / 3 / 120 s), `REWARD_PER_MAGPIE := 10` (gold), `is_open()`, `lodges() -> Array`, `contract_cost(kind) -> int`,
  `can_hire(team, kind) -> String`, `hire(team, kind) -> String`, `contract_time_left(team, kind) -> float`,
  `cooldown_left(team, kind) -> float`, signals `contract_started(team: int, kind: StringName, contract: Node)`,
  `contract_ended(team: int, kind: StringName)`, `reward_paid(team: int, amount: int)`.
- **ChampionGuild** (step 9, systems): `hire_cost(id, pay_gold := false) -> Dictionary` (`{crystals, essence, gold}`),
  `can_hire(id, pay_gold := false) -> String` (adds `"Not enough gold"` in place of `"Not enough crystals"`), `hire(id, pay_gold :=
  false) -> String`, `revive_cost(ch, pay_gold := false) -> int` (lead: int, the price in the currency paid — step-9 callers need an int),
  `can_revive(ch, pay_gold := false)`, `revive(ch, pay_gold :=
  false) -> String`. Defaults keep today's behaviour.
- **ThiefBand** (`scripts/ai/thief_band.gd`, `class_name ThiefBand extends Node`, group `"thief_bands"`): `setup(guild: Node,
  thieves: Array, target: Dictionary)` (a `ThievesGuild.targets()` entry), `thieves: Array`, `target: Dictionary`, `spot: Vector3`,
  `state: StringName` (`&"leaving"`, `&"lurking"`, `&"striking"`, `&"fleeing"`, `&"done"`), `strength() -> float`,
  `loot_total() -> int`, `worker_kills: int`, signal `finished(band)`. Per-Magpie loot: `thief.get_meta(&"loot", 0)`.
- **TrackerContract** (`scripts/ai/tracker_contract.gd`, `class_name TrackerContract extends Node`, group `"tracker_contracts"`):
  `setup(guild: Node, team: int, kind: StringName, trackers: Array, duration: float)`, `team`, `kind`, `trackers`,
  `time_left() -> float`, `end_contract()`, signal `ended(contract)`.
- **Skirmish** (`scripts/world/skirmish.gd`): `@export var trade_enabled := true` (false for missions), `trade_network`,
  `thieves_guild`, `hunters_guild`, creates the two `GoldBank`s, `market_slot(team) -> Vector3` (M1), `tower_slot(team, which:
  StringName) -> Vector3` (S3 natural / S4 rich), constants `POST_SPOTS`, `ROAD_NODES`, `ROAD_SEGMENTS`, `DEN_SPOTS`,
  `LODGE_SPOTS`, `AMBUSH_SPOTS`, `WORKER_SPOTS`; end-screen line.
- **EnvProps.ground_material** gains `roads: PackedVector4Array = PackedVector4Array()` (sets `road_segs` / `road_count` if the
  shader has them).
- **SelectionManager**: signal `neutral_building_clicked(node: Node3D)` (post or guild house), caravan order G, right-click post /
  own Bazaar for caravans and for a selected Bazaar.
- **Models / VFX paths**: `res://art/buildings/market/<kingdom>/market_<kingdom>.tscn`, `res://art/units/caravan/caravan.tscn`,
  `res://art/units/neutral/magpie/magpie.tscn`, `res://art/units/neutral/tracker/tracker.tscn`,
  `res://art/buildings/guilds/magpie_den/magpie_den.tscn`, `res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn`,
  `res://art/buildings/trade_post/trade_post.tscn`, `res://art/vfx/trade_loot_sack.tscn`, `res://art/vfx/trade_vfx.gd`
  (`class_name TradeVfx`, a Node3D in group `"trade_vfx"`; callers do `get_tree().get_first_node_in_group(&"trade_vfx")` then
  `.play(id, at, target)`). Hooks listed in section 9.
- **Ownership**: `scripts/economy/gold_bank.gd` = systems; `art/buildings/market/`, `art/buildings/guilds/`,
  `art/buildings/trade_post/`, `art/units/caravan/`, `art/units/neutral/magpie/`, `art/units/neutral/tracker/`, `art/vfx/trade_*` =
  tech-artists; `data/units/caravan|magpie|greywater_tracker.tres` = gameplay; `data/buildings/*_market.tres` = systems. No
  `Events` change is needed.

## 13. What changes in other specs
- `gdd.md` / `economy.md`: a third resource, gold (section 3); caravans (4.4). `buildings.md`: the Bazaar row, build menu B at r2c2,
  the two new placement messages, Masons' Charter. `skirmish-1v1.md`: posts, ring road corridors, 4 guild houses, clearings,
  reveal at 0:00, M1, S3 / S4, the end-screen line, `trade_enabled`, the concede rule. `fog-of-war.md`: sight 12 / 8 / 12 / 10
  for Bazaar / caravan / tracker / Magpie, the landmarks explored at 0:00. `levels.md`: victim rows Caravan 20, Magpie 25,
  Greywater Tracker 40, Bazaar 80. `ai.md`: rule 10, build row 7, strength rules, concede. `champions.md`: gold payment for hires
  and revives, bot rules B5-B7, the Coin-Cutter looter target, Hunt refund when a Magpie leaves the map. `ui-hud.md`: top-bar gold
  item, keys U / G / B, cards, help text. `items.md`: the gold -> essence exchange (items stay essence-only). `CLAUDE.md` (lead):
  section 12 contracts, Keys line, owner rows.

## 14. Task list (step 10)
**Phase 0:** 10.L1 lead, 10.D2 ui-designer. **Phase 1a (12 in parallel, no shared files):** 10.C1-10.C6, 10.C11, 10.A1, 10.A2,
10.V5, 10.V6, 10.V10. **Phase 1b (as slots free):** 10.C7, 10.C8 (need 10.D2), 10.C12, 10.V1-10.V4, 10.V7-10.V9, 10.V11.
**Phase 2:** 10.C9, 10.C10, 10.A3, 10.V12, then 10.L2, then 10.D3 after the playtest. Phase-1 tests stub the other parts in
their own test file (`tests/test_10_<id>.gd`).
| Id | Agent | Task | Files |
|---|---|---|---|
| 10.L1 | lead | Freeze section 12 in `CLAUDE.md`, Keys (U, G, B, Z), owner rows; step 10 ids in `waves.md`; step-10 agent rules (copy of `step9-agent-rules.md`) | `CLAUDE.md`, `docs/plan/` |
| 10.D2 | ui-designer | Layouts at 1600 x 900 for everything in section 8 (incl. the top bar with gold and the tavern gold buttons) | `docs/design/ui-trade.md` |
| 10.C1 | systems-coder-high [H] | TradeNetwork (road graph, route length / value, ledger, holders, spot danger, remote nodes and mining samples), TradePost, GuildHouse, LootSack, the map (posts, houses, corridors, clearings, reveal, open messages), `trade_enabled`, creation of GoldBanks and the two guild services (load-guarded), M1 / S3 / S4 slots, end-screen line, ground road param | `scripts/world/trade_network.gd`, `trade_post.gd`, `guild_house.gd`, `loot_sack.gd`, `skirmish.gd`, `env_props.gd` |
| 10.C2 | systems-coder | Market + the 4 `.tres` + placement rules and messages | `scripts/buildings/market.gd`, `build_grid.gd`, `building_type.gd`, `data/buildings/*_market.tres` |
| 10.C3 | systems-coder | Caravan loop, held-post waiting, steal, death sack, `Worker.make_unit` branch, messages | `scripts/economy/caravan.gd`, `worker.gd` |
| 10.C4 | systems-coder | ThievesGuild: targets and weights (roads from 5:00, remote nodes from 8:00), band schedule, sizes, cap, veteran HP, spawns bands (ThiefBand via load guard) | `scripts/world/thieves_guild.gd` |
| 10.C5 | systems-coder | HuntersGuild: gold contracts, reasons, cooldowns, tracker spawn (TrackerContract via load guard), Lodge gold reward | `scripts/world/hunters_guild.gd` |
| 10.C6 | gameplay-coder | UnitType fields, `is_commandable`, neutral leash exemption, `leave_map`, the `apply_wares` call in `_ready`, 3 unit `.tres` | `scripts/units/unit_type.gd`, `unit.gd`, `data/units/caravan.tres`, `magpie.tres`, `greywater_tracker.tres` |
| 10.C11 | systems-coder | GoldBank: gold, sources, wares (apply to units and buildings), exchange; Building HP multiplier | `scripts/economy/gold_bank.gd`, `scripts/buildings/building.gd` |
| 10.C12 | systems-coder | ChampionGuild gold payment for hires and revives | `scripts/world/champion_guild.gd` |
| 10.A1 | ai-coder | ThiefBand brain (5.3), caravan and worker strikes | `scripts/ai/thief_band.gd` |
| 10.A2 | ai-coder | TrackerContract brain (6.2) | `scripts/ai/tracker_contract.gd` |
| 10.C7 | ui-coder | Build menu B, Bazaar and caravan cards and panels, G trade, right-click post / Bazaar, route line, post / guild click signal, minimap layers | `scripts/ui/command_card.gd`, `selection_panel.gd`, `selection_manager.gd`, `minimap.gd`, `scripts/vfx/route_line.gd` |
| 10.C8 | ui-coder | Top-bar gold, trade window (U; Bazaar and Lodge tabs), tavern gold buttons, post and Den panels, messages, floating delivery text, audio, settings toggle, help text, tracker inspect text | `scripts/ui/top_bar.gd`, `trade_window.gd`, `tavern_window.gd`, `post_panel.gd`, `hud.gd`, `scripts/vfx/trade_popups.gd`, `scripts/ui/menus/game_settings.gd`, `assets/audio/trade_*` |
| 10.V1-10.V4 | tech-artist (one each) | Ember / Gloom / Frost / Grove Bazaar | `art/buildings/market/fire/`, `shadow/`, `ice/`, `nature/` |
| 10.V5 | tech-artist | Caravan | `art/units/caravan/` |
| 10.V6 | tech-artist | Magpie | `art/units/neutral/magpie/` |
| 10.V7 | tech-artist | Greywater Tracker | `art/units/neutral/tracker/` |
| 10.V8 | tech-artist | Magpie Den | `art/buildings/guilds/magpie_den/` |
| 10.V9 | tech-artist | Greywater Lodge | `art/buildings/guilds/greywater_lodge/` |
| 10.V10 | tech-artist | Trading post, waystones, road paint in the ground shader | `art/buildings/trade_post/`, `art/environment/` (ground shader, `ground_material.tres`, `meshes/waystone*`) |
| 10.V11 | tech-artist (VFX) | 7 effects + `trade_vfx.gd` + loot sack | `art/vfx/trade_vfx.gd`, `art/vfx/trade_*` |
| 10.C9 | systems-coder | Plug the building models (4 Bazaars, post, houses, sack), their hooks and VFX calls | `data/buildings/*_market.tres`, `scripts/world/trade_post.gd`, `guild_house.gd`, `loot_sack.gd`, `scripts/buildings/market.gd` |
| 10.C10 | gameplay-coder | Plug the unit models (`model_scene`), hooks `set_loaded` / `set_carrying` / `play_snatch` reachable | `data/units/caravan.tres`, `magpie.tres`, `greywater_tracker.tres`, `scripts/units/` (hooks only) |
| 10.A3 | ai-coder | Bot rule 10 (section 7), knobs, gold spending, S3 / S4 towers, B5-B7, Coin-Cutter looters, concede, strength | `scripts/ai/ai_trade.gd`, `commander.gd`, `ai_profile.gd`, `data/ai/*.tres`, `ai_champions.gd`, `champion_brain.gd`, `champion_sense.gd` |
| 10.V12 | tech-artist | Icons (section 9) | `art/icons/` (new files only) |
| 10.L2 | lead | Glue (TradeVfx node in both scenes, hud wiring from handoffs), `--no-trade` flag, perf test additions, runs of 11.6, CI, playtest copy | `tests/`, `scenes/`, `docs/plan/` |
| 10.D3 | game-designer | Balance check from the 10.L2 logs and the playtest; knobs of 11.5 | `docs/design/market-trade.md` |

## Done when
- [ ] 10.L1: section 12 is in `CLAUDE.md`; the Keys line has U, caravans G, build menu B, Bazaar Z; owner rows for every new folder and data file; ids in `waves.md`.
- [ ] 10.D2: `ui-trade.md` gives positions / sizes / looks at 1600 x 900 for every element of section 8, consistent with `ui-style.md` and `ui-champions.md`.
- [ ] 10.C1: posts at the 4 centres with doors as in 2.2, 6 x 6 footprints blocking grid and navmesh, clearings r 5; the 4 guild houses at 2.3 (clearing 6); no tree or rock within 2.5 m of any of the 10 segments and the rest of the forest unchanged (same rng); all 8 landmarks explored for both teams at 0:00; posts open at 4:00 with the message; test: from a Bazaar at `(-45, 27)` `route_length` / `route_value` give 26.3 / 15, 49.2 / 28, 122.0 / 119, 144.9 / 154 (+-0.2 m) and the mirrored Bazaar the mirrored values; `route_points` follow the ring; `ambush_spots` return the lists of 2.4; `remote_nodes` lists the natural and both rich nodes, never home nodes; a post with 2 enemy soldiers and no own unit within 12 m is held; `trade_income` sums the last 180 s only; a loot sack is picked up at 1.9 m and not at 2.1 m, adds **gold** to that team, fades at 45 s; `trade_enabled = false` creates nothing (no GoldBank) and the map is the step-9 map; smoke test `victory=true`; `PERF OK`.
- [ ] 10.C2: 4 `.tres` with the numbers of 4.1; Bazaar in the build menu on B; refusals in order (no Hall -> `Needs a completed Hall`, 25 m from the keep -> `Must be within 20 m of your keep`, a second one -> `Only one Bazaar`); it trains caravans on Z; `set_route` works and refuses a non-post; a 7th caravan (alive + queued) -> `Caravan limit reached`; `Market.for_team`.
- [ ] 10.C3: headless: a caravan from a Bazaar at `(-45, 27)` on Millstone Cross loops load 2 s -> post -> trade 2 s -> back at 3.6 m/s -> +28 gold, ~56 / min +-10 % over 3 min; before 4:00 it waits; the Saltgate route passes w_door, nw1, nw2 in order; a held post makes it wait at the last waypoint 45 s then come home empty; `steal(60)` from 119 leaves 59 and emits `robbed`; a loaded caravan killed drops a 50 % sack; its Bazaar destroyed -> it waits at the keep and delivers to the rebuilt one; Move / Stop keep the cargo; `Worker.make_unit` builds a Caravan for `is_caravan` types.
- [ ] 10.C4: no band before 5:00; bands every 75 s only when a target exists; road targets need a trip in 120 s, worker targets start at 8:00 and need >= 2 workers at a node > 30 m from their keep (never a home node); weights as 5.2; sizes 2 / 3 (6+ caravans or 12:00) / +1 after 15:00, never above 6 alive; spot validity (18 m units, 20 m towers, 25 m keep) with 3 retries; the band leaves from the nearer Den; `den:veteran` +10 % / +20 % HP at 10:00 / 15:00; no purchase API exists.
- [ ] 10.C5: Lodge closed before 5:00; Outriders 120 gold / 2 / 180 s and Sweep 100 gold / 3 / 120 s; reasons in order; one per kind, 30 s cooldown; trackers spawn at the Lodge nearer their destination, belong to the team, `is_commandable() == false`; a Magpie kill pays 10 gold to the killer's team (tracker kills to the hirer) with the summed message.
- [ ] 10.C6: the three `.tres` with the numbers of 4.2 / 5.1 / 6.1; a Magpie ordered 40 m away walks there and fights there (no leash pull); a tracker is refused by selection-for-orders; `leave_map()` gives no XP, no essence, no `died`, frees pop and emits `left_map`; kill_xp 20 / 25 / 40; a soldier spawned after Tempered Steel has `attack_damage_pct` +0.08 (stubbed bank in the test).
- [ ] 10.C11: GoldBank per team starts at 0; `add` / `spend` / `can_afford` / `changed` / `spend_failed`; `earned` per source; the 4 wares with prices and effects of 3.2 (Axles on caravans only; steel and gambesons on soldiers, not workers, caravans, wizards, champions or trackers; living and future units); Masons' Charter: a 2 500 HP keep becomes 2 875 and is healed by 375, a site finishes at 1.15 x; ware refusals in order; exchange 100 -> 80 crystals / 40 essence with an own Bazaar only.
- [ ] 10.C12: hire with `pay_gold = true` spends 200 gold + 75 essence (not crystals); `"Not enough gold"` in place of crystals; revive with gold costs 2 x the essence price; defaults unchanged (step-9 tests still pass).
- [ ] 10.A1: a headless scene proves each row of 5.3: spot choice and validity, lurk 90 s then the next spot then home; no strike on an escort above 70 x size; snatch 1.5 s, broken by 20 damage, max 60 each; a lone caravan dies within 15 s; a worker strike stops at 2 kills or 15 s and takes the carried crystals as loot; flee with `shroud` 2 s to the nearer Den; `leave_map` at the door; a sack within 15 m is taken; fights back against weaker, flees from stronger; never attacks a home-node worker; `PERF OK` with 3 bands.
- [ ] 10.A2: Outriders stay 4 m behind the chosen caravans, never both on one, shoot Magpies within 12 m of any own caravan, answer attackers of their caravan, never go beyond 15 m; Sweep visits W spots with workers first, then road spots, chases a looter up to 30 m; trackers ignore enemy soldiers that do not attack them; they fade at the contract end; `PERF OK`.
- [ ] 10.C7: B places a Bazaar from the build menu (r2c2); the Bazaar card shows Caravan Z, Set Route, Wares U and 4 route buttons with value and reason; the panel lines of section 8; G then a post orders caravans to trade, the own Bazaar sends them home, a node still makes workers gather; right-click a post sets the route with a Bazaar selected; the route line and its hover preview; clicking a post or a house emits `neutral_building_clicked`; minimap layers of 2.5; nothing in `scripts/ui/` calls a `_private` function.
- [ ] 10.C8: the gold item in the top bar (hidden with trade off, red flash on a failed spend); U, the Wares button and a Lodge click open the trade window on the right tab; wares, exchange (Shift x5) and contracts call their APIs and show reasons; tavern gold buttons; post and Den panels; all messages of section 8 (throttled); `+N` delivery text; settings toggle sets `trade_enabled`; help text; the three sounds on the SFX bus.
- [ ] 10.V1-10.V4: each Bazaar follows section 9 and `art-keep.md` 0 (silhouette test, palette split, 2-4 glow points, contact decal, painted shader), hooks incl. `play_delivery`; a contact sheet `docs/art/screens/bazaars_silhouette.png`; headless instantiation without errors.
- [ ] 10.V5-10.V7: models as section 9 with the art-units hooks + `set_loaded` / `set_carrying` / `play_snatch` / `set_team_color`; budgets held; the loaded caravan and a Magpie with loot are told apart from 40 m in a screenshot.
- [ ] 10.V8-10.V10: houses and post as section 9 (6 x 6, heights, hooks `set_open`, `set_sign`, `set_held`); roads painted from `road_segs` (10 segments, 3 m); waystones as one MultiMesh.
- [ ] 10.V11: 7 effects play once and stop, pre-built emitters, `TradeVfx.play` for each id; loot sack scene.
- [ ] 10.C9 / 10.C10: models replace the placeholders; hooks called on the right events; smoke test `victory=true`.
- [ ] 10.A3: normal bot places its Bazaar at M1 between 5:30 and 7:00 (earlier when behind), keeps 4 caravans (6 once its home nodes are empty) on the better near route and switches when it is unsafe; hires Outriders after a robbery; buys wares in its order; revives in gold when essence is short; exchanges surplus above 450; builds an S3 / S4 Spire after a raid on a remote node; hard sends 3 caravans far when ahead and uses Sweep; easy only buys the Charter and exchanges; B5-B7 flags; concedes only without caravans and Bazaar; `PERF OK`.
- [ ] 10.L2: the runs of 11.6 meet the pass lines; CI green; playtest copy moved.
- [ ] 10.D3: the balance notes and any knob changes are written in this file (section 11) from the 10.L2 logs and the user's playtest.

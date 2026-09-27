# Balance "good average", a rush option for every kingdom, and new units

Task 16.D1, written 2026-09-26. Source of truth for step 16 (tasks in section 14). User request (translated): *"I want a good
average: plan for all 4 kingdoms to have a zerg-rush-style attack."* Lead extension (same day): *"more units: 2-3 new units per
kingdom that fill role gaps."* So step 16 is three things:
1. **Good average**: each matchup 45-55 % in bot-vs-bot at equal difficulty, median match length 15-20 min.
2. **A rush for every kingdom**: cheap, fast, numerous units hitting at ~3:00-3:30, each with its own flavour, a clear
   economic risk and clear counters. Rushing is a real choice, never the best choice by default.
3. **New units**: two role-gap units per kingdom (plus the two new rush units), readable rosters, same balance targets.

Every name, unit, number and rule is our own. Metres, seconds, `m:ss` since the navmesh was ready, positions `(x, z)` on
Crown Hollow, player side = south-west keep `(-43, 43)`, enemy side = the point mirror `(-x, -z)`. Builds on today's
`data/units/*.tres`, `data/buildings/*.tres`, `data/ai/*.tres`, `scripts/ai/ai_profile.gd`, and on `economy.md`,
`skirmish-1v1.md`, `ai.md`, `balance-1.md`, `balance-2.md` (+ Results), `kingdom-ice.md`, `kingdom-nature.md`,
`champions.md`, `market-trade.md` (step 10), `skills-rework.md` (step 11), `map-fill.md` (step 12), `cavalry-mounts.md`
(step 13), `research.md` (step 14, incl. the user's Q3: ordinary Nature units lose idle regen). **Built after steps 10-14
are merged.** This file overrides numbers in those specs where it says `old -> new`.

## 0. Decisions of the user (answered 2026-09-26)
| # | Question | Decision |
|---|---|---|
| Q1 | A "Light" rule for rush units (half damage to buildings, +50 % vs workers)? | **No.** Rush units deal **normal damage to buildings** and have **no worker bonus**. Rushes are kept from ending games too early by other means (3.1): the **Garrison fire** rule (keeps and towers +50 % vs `swarm` units), the Muster Bell, rush-unit HP / cost / timing, the early tower, and the Rusher bot never targeting the keep during its raid |
| Q2 | The Muster Bell on every keep (key V): 30 s militia, keep fires twice as fast, 150 s cooldown | **Yes** (3.4) |
| Q3 | Bot style in the skirmish menu: `Enemy style: Balanced / Rusher / Random` | **Yes: Random by default, 25 % Rusher** |
| Scope | 2 role units per kingdom + 2 new rush units | **Keep all 10 new units** (section 5) |
Unit list (section 5): Fire and Ice get a new rush unit plus 2 role units (3 new); Shadow and Nature use an existing unit for
the rush and get 2 role units.

## 1. At a glance
| Kingdom | Rush (flavour) | Rush unit | Hits | Role units (tier, building key) |
|---|---|---|---|---|
| Fire | **Ember Swarm**: burst. Scorchlings explode when they die | `scorchling` (new, T1, Hall **V**) | ~3:05, 12-13 units | **Pyre Adept** (T2, Hall **B**): anti-swarm battle caster · **Sparkwing** (T2, Stables **V**): flying scout |
| Shadow | **Hound Pack**: speed and surprise, packs bite harder | `grave_hound` (existing, retuned) | ~3:00, ~10 units | **Hexweaver** (T2, Hall **B**): debuff caster · **Bone Ballista** (T2, Stables **V**): siege and titan-killer |
| Ice | **Winter Siege**: slow, armored, chilling; a forward Rime Spire contains the enemy natural | `rimeling` (new, T1, Hall **B**) | ~3:30, ~10 units + spire 4:12 | **Frostbow** (T2, Hall **N**): long-range anti-cavalry marksman · **Frost Mortar** (T2, Stables **V**): lobbed chilling artillery |
| Nature | **Thorn Tide**: the most bodies, reinforced from a forward proxy Grove Hall | `thornling` (existing, retuned) | ~3:00, 12-13 units | **Vinelasher** (T2, Hall **B**): reach melee that roots riders and titans · **Bore Beetle** (T2, Stables **V**): siege beast |
Every bot defends against rushes (rule 1b, section 7); the new bot **style** `&"rusher"` plays the rushes (section 6).

## 2. The baseline: what we are balancing (post steps 10-14, expected)
| Evidence | Value | Source |
|---|---|---|
| Power order today | **Fire > Nature > Shadow > Ice**: Fire wins 11 / 12 once Vessa casts; Nature 6-7 / 8 of its games; Ice 1-2 / 8 | `balance-2.md` Results |
| Match length today | 11-14 min median without champions, **9-11 min with champions** | `balance-2.md`, 9.D4 notes |
| What steps 10-14 add | Trade +0:45-2:00, map fill +2:00-4:00, cavalry +0:00-1:00, research +2:30-4:00 (all estimates, each spec's own) | `market-trade.md` 11.2, `map-fill.md` 12.2, `cavalry-mounts.md` 13.3, `research.md` 9.4 |
| Changes to the order from 13-14 | Fire: Blaze Rider behind the Stables (175, 50 s); Nature: no army-wide regen (Q3), rings later; Ice: cheapest tier 1 + Hauler Sledges, Frostbite, Stasis | same |
| So step 16 starts by measuring | Round 0 (section 11): the 16-pair matrix with everything of 10-14 on and the step-16 content off. The knob ladder of section 12 is applied from that result, one knob per re-run | |
Step 16 is designed so that its own content is **roughly neutral** for the order: Fire's new units are utility or
niche (the Scorchling has the worst PE of the Fire roster and melts under Garrison fire, the Sparkwing is a scout), Ice's three new units raise its combat value (the thing
`balance-2.md` says it lacks), Nature's two are specialists that do not bring back army sustain.

### 2.1 Combat value of the new and retuned units (level 1, no items; `kingdom-ice.md` 9 formulas)
`EHP = HP x (100 + armor) / 100`; `DPS = dmg / cooldown`; **CE** = EHP x DPS / cost² x 100 (per crystal); **PE** = EHP x DPS /
pop² / 100 (per pop). References: Flame Guard 19.3 / 15.6, Shade 18.9, Rimeshield 19.1, Thornling 17.3 / 6.2, ranged ~5,
heavies 13-14, cavalry ~13.
| Unit | EHP | DPS | Cost | Pop | CE | PE | Speed | Note |
|---|---|---|---|---|---|---|---|---|
| **Scorchling** | 55 | 8.75 | 50 | 1 | **19.3** | 4.8 | 6.0 | + Flashpoint 15 in r 2 on death; `swarm` |
| **Grave Hound** (retuned) | 70 | 11.4 (pack 14.3) | 70 | 1 | 16.3 (pack 20.4) | 8.0 (10.0) | 7.0 | `swarm`; train 14 -> 13 s |
| **Rimeling** | 71.5 | 7.0 | 55 | 1 | 16.5 | 5.0 | 5.0 | + chill on hit (target -20 % DPS, -1.5 m/s); `swarm` |
| **Thornling** (retuned) | 70 | 8.9 | 60 | 1 | 17.3 | 6.2 | 5.4 | `swarm`; no regen after research Q3 |
| **Pyre Adept** | 80 | 6.25 (+ splash 50 %) | 130 | 1 | 3.0 (~6.5 vs clumps) | 5.0 | 4.8 | + Flame Burst 30 in r 2.5 / 14 s |
| **Sparkwing** | 90 (45 vs ranged / towers) | 3.3 | 60 | 1 | 8.3 (4.2 vs ranged) | 3.0 | 7.0 fly | scout, sight 18; cheap, not a fighter (3.3 DPS) |
| **Hexweaver** | 85 | 5.7 | 125 | 1 | 3.1 | 4.8 | 4.6 | + Wither Hex: -20 % damage, healing x0.5 on the best enemy |
| **Bone Ballista** | 189 | 11.25 (19.7 vs titans, 19.7 vs buildings) | 200 | 2 | 5.3 (9.3 vs titans) | 5.3 | 3.6 | min range 4 |
| **Frostbow** | 94.5 | 9.2 (13.8 vs mounted) | 140 | 1 | 4.4 (6.6 vs mounted) | 8.7 | 4.4 | range 12; Hamstring Shot |
| **Frost Mortar** | 176 | 7.4 (~18 vs clumps) | 190 | 2 | 3.6 (~8.8 vs clumps) | 7.9 (clumps) | 3.4 | min range 5; splash chill; no air |
| **Vinelasher** | 178.5 | 10.0 (15 vs mounted) | 120 | 1 | 12.4 | **17.9** | 4.8 | reach 3.0; Snare Lash roots |
| **Bore Beetle** | 368 | 12.0 (30 vs buildings) | 180 | 2 | 13.6 | 11.0 | 4.2 | siege x2.5 |
Rush units sit at line-infantry CE (16-19) with the **worst PE** of their kingdom: strong at 3:00 when crystals bind, weak at
the pop cap, weak against area damage and (Garrison fire, 3.1) against keeps and towers. Role units sit in the ranged /
heavy bands with one special each.

## 3. The shared rush rules
### 3.1 Rush units, Garrison fire and the early-end guard (Q1 = no Light rule)
Rush units deal **full damage to buildings and workers** (no multiplier). Their only shared field is the tag:
| Field / rule | Value | Effect |
|---|---|---|
| `tags` on the 4 rush units | `+ &"swarm"` | Read by the bot (tells, counter-mix), Flame Burst priority, Snare Lash priority, the HUD rush alert, Garrison fire |
| **Garrison fire** (new rule, `BuildingType.bonus_vs_tags`) | Every **keep and tower** deals **+50 %** to `swarm` units | Keep 12 -> **18** per shot (12 DPS; **24 DPS** while the Bell rings); Ember / Night Spire 15 -> **22.5**; Rime Spire 12 -> **18** + chill; Bramble Spire 10 -> **15**. Every rush unit (55-72 EHP) dies to **4 keep shots** or **3-4 tower shots** |
| Rush-unit HP band | **55-72 EHP**, pop 1 | Low on purpose: under 4 garrison shots. An HP buff to a rush unit is never a knob (12.2) |
| Rusher bot raid | Never targets a **keep** before `rush_max_time`; Halls only when no tower covers them (6.2) | The bot's rush hits economy and production, not the win condition |
| Timing | Rushes land at 3:00-3:30, when every keep is at full HP (2 250-3 000) and the defender has 6-12 soldiers | Too early for the defender's tier-2, too late for a keep with no answer |
**Fight checks: can a rush end the game before 8:00?** (level 1, no items; a match ends only when **every** building is dead)
| Situation at ~3:05 | Result |
|---|---|
| 10 Grave Hounds (pack ~140 DPS) vs a lone keep, no army, no Bell | The keep (2 500) falls in ~20 s and kills ~3 Hounds: an **ignored** base can lose its keep. That is what the Bell and the army are for |
| Same + Muster Bell + 6 militia, no army | Hounds kill the militia first (~3 s, 3 Hounds die), then the keep kills one Hound per 2.9 s: **all Hounds dead, keep ~50 %**, 3-6 workers lost (duel D29). The rush hurt the economy, not the base |
| Same + Bell + the defender's 7 Flame Guards | Hounds wiped in ~10 s, keep untouched |
| 13 Scorchlings (114 DPS) vs a lone Ember Hall (1 300) / the Hall + an Ember Spire | ~11 s / ~15 s with 5 Scorchlings dead to the Spire (3 shots each): **Halls can fall**; a tower beside the Hall or the army near it saves it |
| The whole base (keep + Hall + house + tower ≈ 4 500-5 500 HP) vs any 10-13 pack | 35-50 s of uncontested hitting while Garrison fire kills a rush unit every 3-6 s: the pack is gone before the last building **unless** the defender's army is already dead **and** the Bell is not rung. That case is the "<= 15 % of rush games end before 8:00" budget (section 8) |

### 3.2 What a rush costs (vs the same kingdom playing Balanced, by 7:00)
| Cost | Value | Why it matters |
|---|---|---|
| Workers | **5** home workers (Balanced 6, Nature 7) until the rusher's X1 completes | ~-300 crystals (Nature -600) |
| Expansion | X1 **~1:30 later** (placed 30 s after the rush ends, ~5:00-5:45) | ~-300 crystals of natural income |
| Wizard | No creeping before 4:30 (camps, shrines, points) | ~-0.5 to -1 wizard level at 5:00, -25-50 essence |
| Tech and trade | Forge / Sanctum +1:30, Bazaar +2:00, first champion 5:30 | Stronghold and wares later |
| Army after the rush | Swarm units: PE 4.8-8 vs 15-19 for line infantry, and Garrison fire hits them +50 % all game | The pop cap arrives with a worse army |
| Total | **~-600 crystal-equivalents** (Nature ~-900) | **Break-even ≈ 7 worker kills** (Nature ~10), or a Hall (150) + a house (80) + 4 workers, or 5 kills + a forced Bell + a forced tower. A worker kill ≈ 50 cost + ~35 lost mining. Without a worker bonus a Hound needs 7 bites (4.9 s) per worker, a Scorchling 8 (6.4 s): kills come from **surprise**, not raw speed |
The second Hall (150) is **not** lost: it is the rusher's production for the rest of the game.

### 3.3 Map: rush paths on Crown Hollow (step 12)
| Route (keep to keep) | Length | Hound 7.0 | Scorchling 6.0 | Thornling 5.4 | Rimeling 5.0 | Notes |
|---|---|---|---|---|---|---|
| Lane over the Crown Isle | 122 m | 17 s | 20 s | 23 s | 24 s | **Closed early**: the 4 Ruin Wardens stand on the lane (r 4, aggro 7) until ~7:00-9:00 |
| Road bridge (Saltgate `(-12, -48.7)` or Millstone `(12, 48.7)`) | **152 m** | **22 s** | **25 s** | **28 s** | **30 s** | **The rush route.** Each bridge is 55 m from one keep and 97 m from the other; deck 6 m: a defender-friendly choke |
| Ford (Reed / Willow) | ~140 m | 20 s + nest | | | | The nest (3 Mirefangs, 570 HP, 33 DPS) costs ~2 Hounds and 5-8 s; ford -35 % speed. **Rushers never use a ford while its nest lives** |
| Nature proxy P1 -> enemy keep (4.3) | ~68 m | | | 13 s | | Over the bridge nearest the enemy |
- **Watchtowers see the bridges.** Saltgate Bridge is covered by Saltwatch (the enemy's home tower, `(6, -40)`) and by Rookwatch
  (the player's far-corner tower, `(-24, -41)`); Millstone by Millwatch `(-6, 40)` and Owlwatch `(24, 41)`. A defender who holds
  a tower on the rush's bridge sees the pack **8-20 s earlier**. The Rusher picks the bridge **not** covered by a
  defender-held tower (tie: match rng).
- **Staging**: the pack gathers 10 m before its bridge on its own bank, then crosses together.
- **Wayshrines wake at 3:00** (+12 % speed, +1.5 HP / s, 60 s): exactly when rushes land. The defender's own-bank shrine is
  near its base; bots under a rush alert do **not** send squads to shrines (rule 1b), a human defender may.
- **Camps** stand >= 9 m from roads: rush waypoints keep >= 12 m from camp spots; the defender's Bristleback Wallow (32 m from
  its keep) is where a creeping defender army usually is at 2:00-3:00 (rush timing punishes a greedy creep).
- **No building within 8 m of a crossing** (`map-fill.md` 2.4): nobody can wall or tower a bridge exit; a tower at 9-11 m
  covering the exit is legal and strong.

### 3.4 The Muster Bell (Q2): every keep, every kingdom
| Rule | Value |
|---|---|
| Button | Keep card r1c3, key **V** (physical); tooltip `Muster Bell  [V]\n30 s · cooldown 2:30\nWorkers near the keep fight as militia; the keep fires twice as fast.` |
| Available | From 0:00; cooldown **150 s**; refused `"Bell not ready"` / `"Not in this mission"` (missions: `bell_enabled` false) |
| Duration | **30 s**, or until pressed again (ends early, no cooldown refund) |
| Militia | Every own worker within **16 m** of the keep when rung, and any that walks in during it: stops gathering (keeps its load), modifier `militia` = **`armor` +30, `attack_damage` +6** (4 -> 10, 8.3 DPS), `aggro_range` 8 (it auto-fights inside the 16 m circle, never chases out of it). At the end (or leaving the circle): modifier removed, `command_gather` its node again |
| Keep | `attack_cooldown` 1.5 -> **0.75** for the duration (12 damage: 16 DPS; 18 vs `swarm` with Garrison fire: **24 DPS**, a Hound dies in 2.9 s) |
| Price | No crystals; ~30 s of mining of every militia worker (6 workers ≈ **210 crystals**) |
| Look / sound | Keep hook `play_bell()` (a bell swings on the keep, ring pulse r 16); worker hook `set_militia(on)` (helmet and a raised tool); bell sound (SFX) |
| Messages | Own `The Muster Bell rings!`; enemy (if the keep is visible) `The enemy rings its Muster Bell` |

### 3.5 Rush defence tools (what every kingdom has at ~3:00)
| Tool | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| Keep + Muster Bell (DPS vs swarm, Garrison fire) | 2 500 HP, 12 DPS / **24** rung | 2 500, 12 / 24 | 3 000, 12 / 24 | 2 250, 12 / 24 |
| Tower (cost / build; DPS vs swarm) | Ember Spire 120 / 35 s; 15 | Night Spire 120 / 35 s; 15 | Rime Spire 130 / 42 s; 12 + chill 2 s | **Bramble Spire 100 / 30 s** (fastest); 12.5 |
| Wizard answer at L2 | Fireball r1 60 in r 3.5 (kills Scorchlings; rank 2 at L3 kills Hounds and Thornlings) | Soul Siphon 40 over 5 s in r 4 + heals Malrik | Flash Freeze r 3: 20 + frozen 1.5 s | Thornburst 40 in r 3 + rooted 1.5 s |
| Line to hold the mining line | Flame Guard (CE 19.3) | Shade (18.9) | Rimeshield (19.1, armor 15 vs 7-8 damage bites) | Thornlings (17.3, 12 s train) |
| Kingdom extra | Its own Scorchlings intercept (6.0 m/s) | Hounds chase the retreating pack | **Ice Walls** (20, 8 s): close the gap between the nodes and the keep | Cheapest tower and hall; Hollows 60 |
| Champion (taverns open 2:00) | Oathwall (520 HP, armor 20, taunt) or Coin-Cutter for 225 + 75 essence; walks ~15 s from the tavern | same | same | same |
| Worker pull | Workers within 10 m of an enemy soldier run to the keep (`ai.md` rule 1); with the Bell they fight instead | | | |

## 4. The four rushes
Build orders are what the Rusher bot does (section 6) and what a human can copy. Times are for a normal bot with no
interference; "pop" = pop used / cap. Slots: **H1** (existing Hall slot), **H2** (second Hall, new), **V1** (existing
house slot), **P1** (Nature proxy), **C1** (Ice forward spire): coordinates in 6.3.

### 4.1 Fire: **Ember Swarm** (Scorchlings)
Flavour: Fire's burst in unit form. Scorchlings are cheap fire imps; when one dies it **bursts** (Flashpoint). A defender
who fights them in a melee clump takes the explosions; a defender who kills them at range (keep, towers, archers,
Fireball) wastes them.
| m:ss | Step | Pop |
|---|---|---|
| 0:00 | Ember Hall at H1 (150); 2 Cinder Hands queued (100) | 3 -> 5 / 20 |
| 0:50 | H1 done: Scorchlings non-stop (50, **12 s**) | |
| 1:05 | Second Ember Hall at **H2** (150) | |
| 1:55 | H2 done: Scorchlings from both Halls | |
| ~2:50 | Hearth at V1 (80) when pop reaches 16 | 16 / 30 |
| 2:40 | Launch from the staging point with >= 8 (usually ~12) + Vessa (normal, hard) | |
| ~3:05 | At the enemy mining line with **12-13** Scorchlings | |
| 3:05-4:30 | Raid (targets 6.2); reinforcements in groups of 3 every ~35 s | |
| 4:30 or exit | Transition (6.2) | |
Spent on the rush by 3:05: H2 150 + ~13 Scorchlings 650. Strength at contact (Lanchester, N² x EHP x DPS): ~84 k + the bursts.
**Threat to buildings**: 114 DPS kills a Hearth (500) in ~5 s, an unguarded Hall in ~11 s; bursts never hurt buildings.
**Counters**: fight under the keep / a Spire (Garrison fire: 4 keep shots or 3 Spire shots per Scorchling, and they burst
for nothing); Ember Archers, Nightbolts, Shardcasters shoot them before contact; Ice armor (7 -> 6.1 per bite, burst 15 ->
13); the Bell's militia armor. **Tells**: two Ember Halls, no Hearth by 2:30, 5+ Scorchlings seen.

### 4.2 Shadow: **Hound Pack** (Grave Hounds)
Flavour: speed and surprise. The fastest pack in the game picks the bridge you do not watch and bites harder in groups
(**Pack Hunter**). It lands first and leaves first.
| m:ss | Step | Pop |
|---|---|---|
| 0:00 | Gloom Hall at H1; 2 Gloom Thralls | 5 / 20 |
| 0:50 | Hounds non-stop (70, **13 s**) | |
| 1:05 | Second Gloom Hall at H2 | |
| 1:55 | Hounds from both Halls | |
| ~2:50 | Hovel at V1 when pop reaches 16 | |
| 2:40 | Launch with >= 8 (usually ~9) + Malrik (normal, hard) | |
| **~3:00** | Mining line with **~10** Hounds (22 s crossing) | |
| 3:00-4:30 | Raid; groups of 3 every ~40 s | |
Spent by 3:00: H2 150 + ~10 Hounds 700. Strength ~80 k (pack bonus: ~100 k).
**Threat to buildings**: ~140 DPS in a pack: a tower **site** dies in 1-3 s, a Hovel in ~4 s, an unguarded Hall in ~9 s.
The Hounds are the fastest rush but the frailest under Garrison fire (4 shots each): they must not linger near the keep.
**Counters**: area damage (Fireball rank 2, Soul Siphon, Flash Freeze, Thornburst roots: a rooted Hound loses its speed
edge); a tower between the two home nodes; Rimeshield armor (8 -> 7 per bite); hold a watchtower on each bridge. **Tells**:
two Gloom Halls, 5+ Hounds before 2:30, workers stuck at 5.

### 4.3 Nature: **Thorn Tide** (Thornlings + a proxy Grove Hall)
Flavour: the forest walks to your door. Nature plants its second Grove Hall **forward** at P1, next to the bridge nearest the
enemy (68 m from the enemy keep): the tide reinforces in 13 s instead of 28 s. The most bodies, and the biggest gamble
(two workers short, a naked 1 170 HP Hall far from home).
| m:ss | Step | Pop |
|---|---|---|
| 0:00 | Grove Hall at H1 (130); 2 Spriglings (80) | 5 / 20 |
| 0:43 | H1 done: Thornlings non-stop (60, 12 s), they walk to P1 | |
| 0:55 | A Sprigling leaves for P1 (~97 m, 21 s) | |
| ~1:16 | Proxy Grove Hall at **P1** (130); done ~1:55 (38 s) | |
| ~2:55 | Seed Hollow at V1 (60) when pop reaches 16 | |
| 2:45 | Launch from P1 with >= 8 (usually ~11) + Ysolde (normal, hard) | |
| **~3:00** | Mining line with **12-13** Thornlings | |
| 3:00-4:30 | Raid; P1 feeds groups of 3 every ~35 s | |
Spent by 3:00: proxy 130 + ~13 Thornlings 780. Strength ~90-105 k (the biggest; paid by -2 workers).
**Threat to buildings**: ~115 DPS: an unguarded Hall in ~11 s, a Seed-Hollow-sized house in ~4 s; the steady stream from P1
is what makes a base fall if the defender's army is gone, so the proxy is the key target.
**Counters**: **find the proxy** (hold Rookwatch / Owlwatch, whose sight 22 covers P1, or scout the bridge area at 2:00) and
kill it while it builds (117 HP at start, +27 HP / s); area damage (Fireball rank 2 kills a Thornling, Soul Siphon, Pyre
Adept later); Nature buildings are the weakest. **Tells**: a Grove Hall outside the Nature base, 2 workers short, 5+
Thornlings on your bank before 3:00.

### 4.4 Ice: **Winter Siege** (Rimelings + a forward Rime Spire)
Flavour: the fortress walks forward. Ice cannot win a race, so its rush is a **contain**: armored, chilling Rimelings escort
a Rime Hauler to the defender's natural, where it raises a Rime Spire (and 2 Ice Walls to shield it) at **C1**, 8 m from the
natural node. The natural is denied until the defender breaks the spire; meanwhile the Rimelings chill and chase workers
(4.6 m/s -> 3.1 chilled: they cannot run home).
| m:ss | Step | Pop |
|---|---|---|
| 0:00 | Frost Hall at H1; 2 Rime Haulers | 5 / 20 |
| 0:59 | Rimelings non-stop (55, 13 s) | |
| 1:15 | Second Frost Hall at H2; done ~2:14 (54 s) | |
| ~2:55 | Snow Lodge at V1 when pop reaches 16 | |
| 3:00 | Launch with >= 8 (usually ~10) + 1 Hauler + Torvald (normal, hard) | |
| **~3:30** | At C1: Rime Spire (130) placed; the pack guards the site; 2 Ice Walls (40) beside it | |
| ~4:12 | Spire done (42 s): the natural is covered; Rimelings raid the main mining line | |
| 5:15 or exit | Transition (6.2); the spire stays | |
Spent: H2 150 + ~10 Rimelings 550 + spire 130 + walls 40. Strength ~50 k (with chill ~63 k) **plus the spire**.
**Threat to buildings**: 70 DPS (the slowest): a defender's X1 **site** at the natural dies in seconds (the contain's real
bite), a house in ~7 s, a Hall in ~19 s. It cannot threaten a keep.
**Counters**: kill the spire **site** (90 HP at start) in its first ~20 s with the army or the wizard (Fireball, Thornburst hit
buildings); do not chase into the chill with workers; expand only after the spire falls (the bot does that: rule 1b). Ice is
slow: a defender army that walks out at 3:40 meets 10 Rimelings with no reinforcements for 30 s. **Tells**: two Frost Halls,
Rimelings + a Hauler on your bank, a spire site near your natural.

### 4.5 Expected rush matchups (vs a scouting Balanced bot; target: every cell 20-50 % success, every row 30-40 %)
| Rush \ Defender | Fire | Shadow | Ice | Nature | Why |
|---|---|---|---|---|---|
| Ember Swarm | even | even | hard | **good** | Ice armor eats bites and bursts; Thornling clumps eat bursts |
| Hound Pack | hard | even | **good** | hard | Guards + Fireball; Ice has ~6 slow units at 3:00; Thornburst roots, 12 Thornlings |
| Thorn Tide | hard | **good** | good | even | Fireball rank 2 and Guards; Shades are few and elite |
| Winter Siege | hard | even | even | **good** | Fire kills the site fastest; Nature expands earliest, so the contain hurts it most |

## 5. The new units
All ten are **skirmish units** (`UnitType.expansion = true`): Halls and Stables list them only when `Skirmish.expanded_roster`
is true (missions: false, so `mission-01.md` / `mission-02.md` are unchanged). **Tiers**: T1 = the Hall; **T2** = Hall units
with `required_keep_tier = 2` (the Stronghold, `research.md` 2.2) and Stables units (the Stables is the tier-2 building).
Without research (`--no-research`, missions) a `required_keep_tier` 2 unit needs a completed own Stables instead
(`"Requires Stables"`), and with cavalry also off, match time >= 6:00 (`"Available at 6:00"`).
**Training slots**: Halls get a 6th slot (key **N**, card r2c2, the research building's 6-slot pattern); the Stables card
gets slot **V** (r1c4) after cavalry Z, mount X, barding C.
| Building | Z | X | C | V | B | N |
|---|---|---|---|---|---|---|
| Ember Hall (skirmish) | Flame Guard | Ember Archer | Ash Hurler | **Scorchling** | **Pyre Adept** (T2) | - |
| Gloom Hall | Shade | Nightbolt | Grave Hound | Shadow Knight | **Hexweaver** (T2) | - |
| Frost Hall | Rimeshield | Shardcaster | Rime Seer | Rime Colossus | **Rimeling** | **Frostbow** (T2) |
| Grove Hall | Thornling | Burr Slinger | Bloomtender | Bramblehorn | **Vinelasher** (T2) | - |
| Stables (each) | cavalry | mount | barding | **Sparkwing / Bone Ballista / Frost Mortar / Bore Beetle** | | |
Kill XP = cost / 2 rounded to 5 (`levels.md`); victim rows for `levels.md` in the stat table.

### 5.1 Stats (`data/units/<id>.tres`)
| id | Name | Kingdom | Tier / slot | HP | Armor | Dmg | Range | CD | Speed | Aggro | Radius | Height | Cost | Pop | Train | kill_xp | Fields / tags |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `scorchling` | Scorchling | Fire | T1, Hall V | 55 | 0 | 7 | 1.4 | 0.8 | 6.0 | 8 | 0.35 | 1.1 | **50** | 1 | 12 | 25 | `swarm` (3.1); ability `flashpoint` |
| `pyre_adept` | Pyre Adept | Fire | T2, Hall B | 80 | 0 | 10 | 8.0 | 1.6 | 4.8 | 10 | 0.45 | 1.7 | 130 | 1 | 26 | 65 | `base_stats {splash_ratio: 0.5, splash_radius: 1.5}`; ability `flame_burst` |
| `sparkwing` | Sparkwing | Fire | T2, Stables V | 90 | 0 | 5 | 5.0 | 1.5 | 7.0 | 8 | 0.5 | body at 3.0 m | 60 | 1 | 18 | 30 | tags `flying`; `fly_height` 3.0, `turn_rate_deg` 240, `sight_radius` **18** |
| `hexweaver` | Hexweaver | Shadow | T2, Hall B | 85 | 0 | 8 | 8.5 | 1.4 | 4.6 | 10 | 0.45 | 1.7 | 125 | 1 | 24 | 65 | ability `wither_hex` |
| `bone_ballista` | Bone Ballista | Shadow | T2, Stables V | 180 | 5 | 36 | 13.0 | 3.2 | 3.6 | 13 | 0.8 | 1.8 | 200 | 2 | 38 | 100 | `min_attack_range` 4, `bonus_vs_tags {titan: 0.75}`, `building_damage_mult` 1.75; bolt speed 24 |
| `rimeling` | Rimeling | Ice | T1, Hall B | 65 | 10 | 7 | 1.4 | 1.0 | 5.0 | 8 | 0.4 | 1.2 | **55** | 1 | 13 | 30 | `swarm`; `on_hit_status` chill 1.0 s |
| `frostbow` | Frostbow | Ice | T2, Hall N | 90 | 5 | 22 | 12.0 | 2.4 | 4.4 | 12 | 0.45 | 1.7 | 140 | 1 | 28 | 70 | `bonus_vs_mounted` 0.5; ability `hamstring_shot` |
| `frost_mortar` | Frost Mortar | Ice | T2, Stables V | 160 | 10 | 26 | 13.0 | 3.5 | 3.4 | 13 | 0.8 | 1.9 | 190 | 2 | 42 | 95 | `min_attack_range` 5, `building_damage_mult` 1.5, cannot hit flyers; ability `frost_shell` |
| `vinelasher` | Vinelasher | Nature | T2, Hall B | 170 | 5 | 13 | **3.0** | 1.3 | 4.8 | 9 | 0.5 | 1.8 | 120 | 1 | 20 | 60 | melee kind (<= 3.0); `bonus_vs_mounted` 0.5; ability `snare_lash` |
| `bore_beetle` | Bore Beetle | Nature | T2, Stables V | 320 | 15 | 24 | 1.6 | 2.0 | 4.2 | 8 | 0.8 | 1.4 | 180 | 2 | 30 | 90 | `building_damage_mult` **2.5** |
The Ice speed line (`kingdom-ice.md` 1: "no Ice unit above 4.6") has its second exception after the Rimehorn Rider: the
Rimeling (5.0). No Nature unit gets idle regen (research Q3). Research that names unit ids does not include the new units
unless a later spec says so (e.g. Quenched Blades stays Guard / Rider / Archer).

### 5.2 Abilities (one script `UnitAbilities`, autocast or passive; checked every 0.5 s, staggered)
| Id | Unit | Rule |
|---|---|---|
| `flashpoint` | Scorchling | On death: **15** fire damage (kind `spell`) to enemy **units** within **2.0 m** (not buildings, not own units, no chain: a Scorchling killed by a burst still bursts, but bursts never hurt Scorchlings' own side) |
| `pack_hunter` | Grave Hound | Passive: `attack_damage` **+1 per other own Grave Hound within 4 m, max +2** (modifier `ability:pack`, rewritten only when the count changes) |
| `flame_burst` | Pyre Adept | Cooldown **14 s**: a point within 8 m where >= **3** enemy units stand within **2.5 m** (swarm-tagged count double for the choice): **30** fire damage (kind `spell`) to enemy units there. 0.4 s cast (the Adept keeps its attack timer) |
| `wither_hex` | Hexweaver | Cooldown **10 s**, range 9: the highest-cost enemy soldier, champion or titan in range not already `withered` -> status **`withered` 6 s**: `attack_damage_pct` **-0.20**, `healing_taken` **x0.5** (the research `blighted` key). Heroes, champions, titans: half duration (`hero_mult`); wizards immune |
| `hamstring_shot` | Frostbow | Cooldown **12 s**: the next shot on a mounted or fast (`move_speed` >= 6.0) enemy in range, else on any moving enemy, adds `chill` **3 s** (this denies a charge for 6 s, `cavalry-mounts.md` 3.2) |
| `frost_shell` | Frost Mortar | Its attack is a lobbed shell (arc, 0.9 s flight, lands where the target was): **full damage** to enemy ground units within **2.0 m** + `chill` 1.5 s on each; buildings x1.5 (main target only); never targets flyers |
| `snare_lash` | Vinelasher | Cooldown **10 s**, range 5: the nearest enemy that is mounted, a titan, or swarm-tagged (in that order, else the nearest) -> 10 damage and **`rooted` 1.5 s** (heroes, champions, titans 0.75 s). Rooted denies the charge and ends the Nightmare Knight's gallop armor |
Bone Ballista and Bore Beetle have no ability: range / siege numbers are their identity. Sparkwing has none (a scout).
`withered` does not stack with itself; with `dread` both apply (-10 % and -20 %, additive: -30 %).

### 5.3 Roles, counters, how the bot uses them
| Unit | Gap it fills | Beats | Loses to | Bot use (Balanced, via `unit_mix`, 7.3) |
|---|---|---|---|---|
| Scorchling | Fire's cheap fast unit after the Blaze Rider left the Hall | Workers, ranged in the open, melee clumps (bursts) | Towers / keep, archers, armor, chill | 0.10 as raiders; 0.25 vs ranged-heavy enemies; rush style 1.0 |
| Pyre Adept | Fire had no caster / support unit | Swarms (Thornlings, Hounds, Scorchlings, Saplings, Risen) | Cavalry, Hounds diving it, range 9 units | 0.15 once T2; 0.25 vs swarm (7.3) |
| Sparkwing | Fire lost its early scout (Rider to T2); fits Fire's flyer identity | Nothing (sight 18, moves over walls and water) | Any ranged unit or tower (x2) | Exactly **1** alive from the first Stables; takes over rule 6 scouting and watches the enemy's bridges |
| Hexweaver | Shadow had no caster | Heavies, titans, Nature healing (Bloomtenders, Wild Bloom, Treant) | Cavalry, area damage | 0.10; 0.20 vs heavy / titan (>= 30 % of seen pop) |
| Bone Ballista | Shadow had no siege and no titan answer | Titans (x1.75, dragon x3.5 with the flyer rule), buildings (x1.75) | Anything inside 4 m, cavalry, Hounds | 0.05; 0.15 vs titans; +2 in any attack group whose target is a building |
| Rimeling | Ice's rush unit, its only cheap unit | Workers, fleeing units (chill), ranged in the open | Area damage, heavies | 0.05 raiders; rush style 1.0 |
| Frostbow | Ice cannot catch raiders or cavalry | Cavalry (33 per shot, charge denied), flyers (x2), casters | Swarms, line pushes (one slow shot) | 0.08; 0.20 vs mounted >= 25 % or a seen dragon |
| Frost Mortar | Ice loses long fights to kiting and swarms | Clumps (Thornlings, Hounds, Shades), buildings (x1.5) | Flyers (cannot hit), cavalry dives, 5 m min range | 0.05; 0.15 vs swarm |
| Vinelasher | Nature had nothing that holds riders / titans; its PE was the worst | Cavalry, the Nightmare Knight, fast rushers | Ranged kiting, area damage | 0.10; 0.20 vs mounted or titans |
| Bore Beetle | Nature had the weakest siege | Buildings (30 DPS each), towers | Line infantry, anything (12 DPS vs units) | 0.04; +2 in attack groups aimed at buildings |
No near-duplicates inside a kingdom: e.g. Ice ranged = Shardcaster (9, chill, main line) / Frostbow (12, single slow shot,
anti-cavalry) / Frost Mortar (13, lobbed area, no air). A dedicated pike unit was not added: line infantry already has
+50 % vs mounted (step 13), a pike would duplicate it.

### 5.4 Art briefs (`art-units.md` style: chunky, silhouette = role, painted shaders, 1-2 glow points at 40 m; kingdom palettes of `kingdom-ice.md` 8 / `kingdom-nature.md` 7 / `art-keep.md` 0.2)
| Unit | Concept | Silhouette at 40 m | Signature detail | Glow | Hooks |
|---|---|---|---|---|---|
| Scorchling | A knee-high fire imp, huge head, stubby claws, a coal belly | Smallest Fire unit, big round head | Belly coal pulses faster as HP falls; death = pop + ember ring | belly 2.0 | unit hooks + `play_burst()` |
| Pyre Adept | A robed pyromancer with a **brazier-headed staff** held high | Tall staff with a fire bowl (vertical read) | Flames in the bowl flare on Flame Burst | bowl 2.5 | `play_cast()` |
| Sparkwing | A small fire-bird, span 1.6 m, ember tail streamer | Bird shape in the air, trailing sparks | Wings flap 0.8 s, glide when straight | tail 1.5 | flyer hooks (13.V13 pattern: `set_moving`, `set_turning`) |
| Hexweaver | A hunched witch with a **hanging cage lantern of bones**, long sleeves | Hunch + dangling cage | Violet smoke threads from the cage to hexed targets | cage 1.5 | `play_cast()` |
| Bone Ballista | A great bone-and-iron crossbow on a two-wheeled carriage, a Gloom Thrall crew | Long horizontal bow arms (2.4 m) | Rib-bone limbs, violet bolt tip | bolt tip 1.5 | `play_attack()` (arms snap) |
| Rimeling | A small squat frost goblin in fur, **two icicle shivs** | Low, wide, spiky ice back | Frost breath puffs | eyes 1.0 | unit hooks |
| Frostbow | A tall hooded marksman with a **long ice longbow** taller than itself | Very tall thin bow | Bow string glows when Hamstring is ready | bow 1.5 | `play_attack()` (draw) |
| Frost Mortar | A squat ice-bound mortar tube on a sled, 2 Hauler crew | Stubby tube tilted 45° | Frost vapour from the muzzle after each shot | muzzle 1.5 | `play_attack()` (recoil) |
| Vinelasher | A lean bark warrior with a **coiled thorn whip 3 m long** | Whip coils around the arm (circle read) | Whip lashes out, blossoms on the handle | whip tip 1.0 | `play_attack()`, `play_cast()` (lash) |
| Bore Beetle | A giant armored wood-boring beetle, **huge mandibles**, moss on the shell | Long low domed shell (2.6 m) | Mandibles chew; sawdust on building hits | eyes 1.0 | unit hooks |
Budgets: soldier budget of `art-units.md` (Ballista, Mortar, Beetle: the cavalry budget, <= 20 parts). Icons: one per unit
(`art/icons/units/<id>.png` pipeline) + 5 ability icons + the Muster Bell.

## 6. The bot's Rusher style (ai 16.A1)
### 6.1 Contract: a style is an overlay, not a difficulty
`AIProfile.style: StringName` = `&"balanced"` (default: today's bot) or `&"rusher"`. `AIProfile.apply_style(p, style, faction)`
runs **after** the kingdom preset and the difficulty `.tres` are loaded and only changes the knobs below. Difficulty keeps
its own knobs (decision interval, reaction, build delay, queue depth...): an easy Rusher rushes late and sloppily, a hard
Rusher on time. Style choice: the skirmish menu (`Enemy style`, Q3) or the harness flag; `&"random"` = Rusher with
probability **0.25** (match rng, decided at 0:00, logged).
| Knob (rusher) | Value | Balanced |
|---|---|---|
| `rush_unit` | Fire `scorchling`, Shadow `grave_hound`, Ice `rimeling`, Nature `thornling` | - |
| `rush_worker_cap` | **5** until the rusher's X1 completes | 6 (Nature 7) |
| `rush_second_hall_time` | **65 s** at H2 (Ice 75 s; Nature: the worker leaves for **P1** at 55 s) | - |
| `rush_launch_time` / `rush_launch_pop` | **160 s** (Nature 165, Ice 180) / **8** rush units at the staging point | - |
| `rush_max_time` | **270 s** (Ice 315 s): exit at the latest | - |
| `rush_retreat_hp` | **0.5** of the pack's launch HP (reinforcements add to it) | - |
| `rush_reinforce_group` | 3 (new rush units wait at staging until 3, then cross) | - |
| `rush_proxy` / `rush_forward_tower` | Nature true / Ice true (+ 2 walls) | false |
| `rush_wizard_joins` | true (easy false) | - |
| `rush_second_wave` | true: if the pack killed >= 6 workers (or >= 300 crystals of buildings) at exit, a second strike at ~5:00 (rush units + first line units, rule 7 with `attack_ratio` -0.2) | - |
| Rules suspended until exit + 30 s | rule 11 creep, 12 capture squads / shrines, 9 champion hire, 10 trade, 14 research, S1 tower (unless intruded) | - |
| After exit | `expand_time` = exit + 30 s; `creep_start` 4:30; `champion_earliest` 5:30; `forge_time` / `sanctum_time` +90 s; `trade_start` +120 s; rush-unit share 0.25 in the mix until 8:00 (raiders), then the Balanced mix | |

### 6.2 Rush rules (new rule 15 of `ai.md`, only for `style == &"rusher"`; phases BUILD -> STRIKE -> RAID -> EXIT -> TRANSITION)
| Phase | Rule |
|---|---|
| BUILD (0:00-launch) | The build orders of section 4 (rows H1, H2 / P1, V1 at pop 16); train only `rush_unit` (queue on both Halls, `queue_depth` of the difficulty); new units walk to the **staging point**. Route pick at 2:20: the road bridge not seen by a defender-held watchtower (ownership is public), tie = match rng; the scout (worker, 1:30) checks the target base once |
| STRIKE | At `rush_launch_time` with >= `rush_launch_pop` at staging (else at launch time + 20 s with what is there, never fewer than 6): `command_move` over the bridge to 14 m from the defender's mining line (the midpoint of its home nodes), then RAID. Delay 20 s (max 60 s) if seen defenders within 20 m of that point > **1.6 x** the pack's strength; Ice: go to C1 first |
| RAID targets (re-picked every tick, first that applies) | (1) workers outside keep and tower range (>= 11 m from them); (2) any worker; (3) construction sites (tower sites first); (4) houses; (5) a Hall **not** within range of a completed tower; (6) enemy soldiers **only** when attacked or when pack strength >= 1.3 x the defenders within 15 m. **Never the keep** before `rush_max_time` (it is the win condition; Garrison fire kills the pack there). Units avoid keep and tower range unless finishing a worker under 30 % HP. Ice at C1: the pack guards the site until done, then raids |
| EXIT | Pack HP < `rush_retreat_hp` of launch HP, **or** defenders within 15 m > **1.4 x** the pack, **or** `rush_max_time`: `command_move` back over the bridge to the own rally. Log worker kills, buildings killed, units lost |
| TRANSITION | The knobs of 6.1 "After exit"; if `rush_second_wave` qualifies, one more strike at ~5:00 |
| Rusher vs Rusher | A rush alert (rule 1b) during BUILD does **not** cancel the rush unless the seen enemy pack > **1.3 x** own: then the pack defends (base trade otherwise) |

### 6.3 New slots (systems clears trees and rocks r 3 at each, like `HOUSE_SLOT`; ai-coder verifies with `BuildGrid.check`, shifts `SLOT_SHIFTS`)
| Slot | Enemy side | Player side (mirror) | Check |
|---|---|---|---|
| **H2** second Hall | `(19, -53)` | `(-19, 53)` | 2 m gap to H1; 10 m from the `hub'-n_door` road; clear of S2, T3, R2 |
| **P1** Nature proxy | `(24, 54)` (near Millstone Bridge, enemy bank) | `(-24, -54)` (near Saltgate Bridge, west bank) | 13 m from the bridge (> 8 m crossing rule), 13 m from the far-corner tower, >= 2.5 m off the road corridor; ~68 m to the other keep |
| **C1** Ice forward spire (at the **defender's** natural) | `(-20, 13)` (player's natural, for an enemy-side Ice rusher) | `(20, -13)` | 8.1 m from the natural node (> 4 m node rule), 11.7 m from the Crown Bridge (> 8 m), covers the node and the X1 slot; walls at C1 +-(2, 0) |
| Staging | 10 m before the chosen road bridge on the own bank | mirror | |
| **Mine rally** (defence) | Midpoint of home nodes a and b: `(40, -40)` | `(-40, 40)` | Rule 1b holds the army here |

## 7. How every bot defends against rushes (ai 16.A2; all styles)
### 7.1 Rule 1b "Rush alert" (evaluated right after rule 1 every tick)
**Tells** (each counts once per match; the bot knows only what it saw):
| Tell | Weight |
|---|---|
| T1 A second enemy Hall seen before 2:00 | 1 |
| T2 An enemy Hall seen > 40 m from the enemy keep before 3:00 (a proxy) | **2** |
| T3 >= 5 enemy `swarm` units seen before 3:00 | 1 |
| T4 Enemy workers seen <= 5 at its mining line between 1:45 and 3:00 | 1 |
| T5 >= 4 enemy soldiers seen on the own bank or on a road bridge before 3:30 | 1 |
| T6 An enemy tower or tower site within 25 m of the own natural or X1 slot before 6:00 | **2** |
New **rule 13c "Main scout"**: at `rush_scout_time` one worker walks enemy natural -> enemy H1 -> enemy H2 slot -> enemy node a
-> home (never through the isle or a nest), so T1 / T4 can be seen. Watchtowers held by the bot (rule 12a) feed T5.
**Alert** when the tell weight >= `rush_tells_needed`. While alerted:
| # | Action |
|---|---|
| a | **Tower now**: S1 (normal), S1 + S2 when weight >= 3 (hard); the 20 s rule is waived (training pauses <= 15 s for it). Ice hard: 2 walls beside S1. Nature: its S1 is a Bramble Spire (30 s) |
| b | **Home stance**: new units and the army hold at the **mine rally**; rule 7 attacks, rule 11 creeps, rule 12 capture squads / shrines are suspended; the wizard stays within 15 m of the keep (home heal) and casts by its rules |
| c | **Muster Bell** (3.4) when >= 3 enemy units are within 12 m of own workers **and** home strength (army within 20 m + keep 150 + towers 150 each) < `bell_ratio` x the intruders' strength |
| d | **Champion**: if a tavern is open and crystals >= price + 50 and essence allows, hire `alert_champion` now (ignores `champion_earliest`) |
| e | **Counter-mix** (7.3 "vs swarm"): line unit +0.20, AoE unit +0.10 once unlocked; no heavy until the alert ends |
| f | **Contain (T6)**: attack-move the spire site / tower with the army + wizard as soon as own strength >= 1.0 x (seen strength near it + 150); do not place X1 while it stands |
| g | **Punish**: when the enemy pack leaves the own bank with < 50 % of its seen strength, X1 is placed at once (the time trigger is ignored) |
| End | No swarm unit seen on the own bank for `alert_end_quiet` s, or at `alert_end_time`: every suspended rule resumes |
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `rush_scout_time` (rule 13c) | 2:30 | **1:45** | 1:30 |
| `rush_tells_needed` | 3 | **2** | 2 |
| `alert_tower` | S1 only if crystals >= 120 at alert | **S1 now** | S1 + S2 (weight >= 3) |
| `bell_ratio` | rings only after a worker died | **1.2** | 1.4 |
| `alert_champion` | none | **first of `champion_order`** | `&"oathwall"` |
| `alert_end_quiet` / `alert_end_time` | 60 s / 6:00 | **45 s / 5:30** | 45 s / 5:30 |
Harness flag `--no-rush-defense` turns rule 1b and 13c off for the defender (the "unscouted" control).

### 7.2 Using the new units (all styles)
| Rule | Value |
|---|---|
| Mix by id | `AIProfile.unit_mix` (7.3) replaces the index arrays; shares of units not yet trainable (tier, building) are spread over the others in proportion; cavalry / titan shares stay as `cavalry-mounts.md` 9.1 |
| Min-range pullback | Each tick: a Bone Ballista or Frost Mortar with an enemy inside its `min_attack_range` and no other target in range `command_move`s 5 m toward the rally (hard: every 0.5 s) |
| Siege adds | An attack group whose target row is a building takes up to 2 Bone Ballistas / Bore Beetles / Frost Mortars along (they stay home otherwise) |
| Sparkwing | 1 alive; it runs the rule-6 loop, then parks 12 m on the own side of the bridge the enemy used last; replaced 60 s after death |
| Abilities | All autocast: no micro needed |
| Strength | Default (`cost x (0.8 + 0.2 x level)`); a Sparkwing counts 0 |

### 7.3 Default mixes (`unit_mix`: id -> `Vector3(default, vs_ranged, vs_melee)`; T1 + T2 hall / stables units, before the cavalry / titan scaling)
| Kingdom | Mix |
|---|---|
| Fire | Flame Guard (0.35, 0.30, 0.25), Ember Archer (0.25, 0.15, 0.35), Ash Hurler (0.10, 0.10, 0.15), Scorchling (0.10, 0.25, 0.05), Pyre Adept (0.20, 0.20, 0.20) |
| Shadow | Shade (0.33, 0.25, 0.22), Nightbolt (0.25, 0.12, 0.40), Grave Hound (0.12, 0.30, 0.08), Shadow Knight (0.15, 0.15, 0.15), Hexweaver (0.10, 0.10, 0.10), Bone Ballista (0.05, 0.08, 0.05) |
| Ice | Rimeshield (0.33, 0.43, 0.25), Shardcaster (0.25, 0.15, 0.33), Rime Seer (0.10, 0.10, 0.12), Rime Colossus (0.14, 0.14, 0.12), Rimeling (0.05, 0.05, 0.05), Frostbow (0.08, 0.08, 0.08), Frost Mortar (0.05, 0.05, 0.05) |
| Nature | Thornling (0.38, 0.48, 0.25), Burr Slinger (0.22, 0.08, 0.35), Bloomtender (0.12, 0.08, 0.12), Bramblehorn (0.14, 0.22, 0.14), Vinelasher (0.10, 0.10, 0.10), Bore Beetle (0.04, 0.04, 0.04) |
Extra rows, applied after the table (first match wins, like `cavalry-mounts.md` 9.1): **vs swarm** (>= 50 % of seen soldier pop
is `swarm`): Pyre Adept 0.25, Frost Mortar 0.15, line +0.10, Scorchling / Rimeling 0; **vs heavy / titan** (>= 30 % of seen
pop): Hexweaver 0.20, Bone Ballista 0.15, Vinelasher 0.20; **vs mounted** (>= 25 %): Frostbow 0.20, Vinelasher 0.20. Fire gets
its own `fire_default` profile (today it borrows `shadow_default`).

## 8. Balance targets ("good average")
| Target | Value | Pass band in the matrix (bot noise at these N, section 11) |
|---|---|---|
| Kingdom overall win rate (non-mirror, Balanced vs Balanced) | **45-55 %** | 43-57 % at N = 72 per kingdom (SE ~6 %) |
| Each unordered kingdom pair | **45-55 %** | 33-67 % at N = 12; a pair outside -> +12 runs, then 40-60 % at N = 24 |
| Median match length (Balanced, every pair) | **15:00-20:00** | Per kingdom pair 13:30-21:30; overall 15:00-20:00 |
| Games without a winner at 24:00 | <= 10 % | <= 10 % |
| Mirrors (side bias) | 50 % | Player side 40-60 % over the 24 mirror runs; crystals within 1.1x at 10:00 |
| **Rush success** vs a scouting Balanced bot (success = rusher `worth` at 7:00 >= **1.10 x** the defender's, or the rusher wins before 12:00; `worth` in 11.2) | **30-40 %** | 25-45 % per rush kingdom (N = 24), 30-40 % overall (N = 96) |
| Rusher game win rate vs Balanced | **40-50 %** (a real choice, not dominant) | 35-55 % per kingdom |
| Rush success vs an unscouted defender (`--no-rush-defense`) | **55-70 %** (ignoring a rush must hurt) | >= 50 % |
| Rush games that end before 8:00 (held by Garrison fire, the Bell, rush-unit HP / cost / timing and the early tower, 3.1; never by a building-damage cut) | <= 15 % | <= 15 % |
| Rush games' median length | >= 12:00 | >= 11:00 |
| New units in use | Each new unit >= 3 % of trained soldier pop of its kingdom in games that reach its tier; none > 25 % unless its kingdom is <= 55 % | Round A logs |
| Difficulty sanity | Rusher normal vs Balanced easy: rusher wins >= 65 %; vs Balanced hard: <= 40 % | Round F |

## 9. Numbers to change in existing data (apply mechanically; `file / field: old -> new`)
| File / field | Old -> new | Why |
|---|---|---|
| `data/units/grave_hound.tres` / `train_time` | 14 -> **13** | Hound Pack production (not 12: full building damage, 3.1) |
| same / `tags`, `abilities` | - -> `[&"swarm"]`, `[&"pack_hunter"]` | Garrison fire, Pack Hunter |
| `data/units/thornling.tres` / `tags` | `[]` (+ step 13) -> add `&"swarm"` | Garrison fire (also a mild late-game nerf to Nature's main line vs towers) |
| `data/buildings/*_keep.tres`, `*_tower.tres` (8 files) / `bonus_vs_tags` (new field) | - -> **`{&"swarm": 0.5}`** | Garrison fire (3.1) |
| `data/buildings/fire_barracks.tres` / `train_ids` (skirmish) | `[flame_guard, ember_archer, blaze_rider, ash_hurler]` (Rider hidden with cavalry on) -> + `scorchling`, `pyre_adept` (slots V, B with cavalry on) | 5 |
| `shadow_barracks.tres` / `train_ids` | + `hexweaver` (B) | 5 |
| `ice_barracks.tres` / `train_ids` | + `rimeling` (B), `frostbow` (N) | 5 |
| `nature_barracks.tres` / `train_ids` | + `vinelasher` (B) | 5 |
| `data/buildings/*_stables.tres` / `train_ids` | + `sparkwing` / `bone_ballista` / `frost_mortar` / `bore_beetle` (slot V) | 5 |
| Every keep (`scripts/buildings/keep.gd`) | + Muster Bell (3.4) | Q2 |
| `data/ai/*_{easy,normal,hard}.tres` | + rule-1b knobs (7.1), `unit_mix` (7.3), `style` `&"balanced"` | 6-7 |
| `levels.md` victim rows | + the 10 kill_xp values of 5.1 | |
Nothing else changes before Round 0 (section 11): the power knobs of section 12 are applied from the measurements, one at a
time.

## 10. UI (layout: ui-designer 16.D2 addendum `docs/design/ui-rush.md`; code ui-coder 16.C4)
| Element | Content |
|---|---|
| Keep card | **Muster Bell V** at r1c3 (tooltip 3.4); panel chip `Muster Bell 18 s` while ringing, cooldown sweep on the button |
| Hall card | 6th slot **N** (r2c2) when the Hall has 6 types (Ice); T2 units show `Requires a Stronghold` (or `Requires Stables`) disabled until met |
| Stables card | Slot **V** (r1c4) = its 4th unit |
| Worker panel | `Militia` tag + a small helmet icon on the portrait while `militia` is on |
| Selection panel | `Swarm` tag in the stat line; ability icons with cooldowns (Flame Burst, Wither Hex, Hamstring Shot, Snare Lash); `withered` status icon |
| Rush alert (own) | When >= 5 enemy `swarm` units are within 30 m of own buildings before 6:00: red message `Rush! Enemy swarm at your base` + minimap ping + a horn; max once per 60 s |
| Skirmish setup | `Enemy style: Balanced / Rusher / Random` (default Random, Q3); bot-vs-bot debug keeps both |
| Help text | Adds `V (keep): Muster Bell` |
| Audio | Bell toll (loop while ringing, fades), Scorchling burst pop (max 3 / s), hex whisper, lash crack, mortar thump, ballista twang |

## 11. The test matrix (harness 16.A3 `tests/test_16_a3.gd`; runs by the lead in the CI copy, 16.L2)
Normal bots both sides unless stated, cap **24:00** (`--fixed-fps 60 --quit-after 88000`), one process per run, up to **6 in
parallel** on a quiet machine. Every round uses **all 16 ordered kingdom pairs** (4 x 4, mirrors included) unless stated.
### 11.1 Flags
| Flag | Effect |
|---|---|
| `--pair=fire:ice` / `--pairs=all16` / `--runs=N` | Pairs (player:enemy) and repeats |
| `--style=player:rusher,enemy:balanced` | Styles per side (`balanced`, `rusher`, `random`) |
| `--difficulty=player:normal,enemy:hard` | Difficulty per side |
| `--no-trade`, `--no-champions`, `--no-mapfill`, `--no-research` | Steps 10 / 9 / 12 / 14 off (existing or planned by their steps) |
| `--no-cavalry`, `--no-titans` | Step 13 off |
| `--no-rush-defense` | Rule 1b and 13c off (both sides) |
| `--no-bell` | Muster Bell off |
| `--roster=old` | Step-16 units hidden (`expanded_roster` false), the Hound / Thornling rows of 9 reverted and Garrison fire off, in memory |
| `--no-garrison` | Garrison fire off only (to measure what it does to early ends and to Nature) |
| `--set=...` | The existing in-memory knob override (`balance-2.md` Results) |
### 11.2 What each run logs (one CSV row + the existing RUN line)
Winner, side, time; styles; kingdoms; army pop at 5 / 10 / 15 / end; crystals gathered at 5 / 10 / 15; workers at 3 / 5 / 10;
X1 / X2 / Stronghold / Citadel times; **rush**: route, launch and arrival time, pack size at arrival, worker kills by exit,
buildings killed, rush units lost, exit time and reason, defender alert time and tells, Bell times, tower completion,
champion hire time; **`worth` at 5:00 and 7:00** both sides; success flag; trained pop per unit id; 0 script errors.
`worth(t)` = bank crystals + cost of living units (workers, soldiers; champions at their hire crystals) + cost of standing
buildings and sites (keep counted **400**, keep tiers at their price) + crystals spent on finished research. Gold and essence
are logged apart.
### 11.3 Rounds
| Round | What | Runs | Pass |
|---|---|---|---|
| 0 | Baseline after 10-14, `--roster=old --no-bell`, Balanced vs Balanced | 16 x 3 = **48** | None: picks the first knobs of section 12 (report the order of kingdoms and the median length) |
| A | Everything on, Balanced vs Balanced | 16 x 6 = **96** (12 per non-mirror pair, 6 per mirror) | Section 8 rows 1-5 and "new units in use" |
| B | Rusher vs Balanced, both side orders | 16 x 3 rusher-player + 16 x 3 rusher-enemy = **96** | Rush rows of section 8 (success, rusher win, early ends, median) |
| C | Rusher vs Balanced `--no-rush-defense` | 16 x 1 = **16** | Success >= 50 % |
| D | Toggles on Balanced vs Balanced: 12 non-mirror ordered pairs x 1 run x each of `--no-trade`, `--no-champions`, `--no-mapfill`, `--no-research`, `--no-bell`, `--roster=old`, and all four feature flags at once; plus Rusher vs Balanced `--no-garrison` (16 x 1) | 12 x 7 + 16 = **100** | Each toggle: kingdom order unchanged from A (no kingdom crosses 60 % / 40 % because of a system); median length with everything on >= the all-off control + 3:00; `--no-garrison` shows more early ends than Round B (Garrison fire is doing its job) |
| E | Rusher vs Rusher | 16 x 1 = **16** | No script errors; no run < 6:00; both packs log |
| F | Difficulty sanity: Rusher normal vs Balanced easy, and vs Balanced hard, each kingdom vs each kingdom | 16 + 16 = **32** | Section 8 last row |
| Duels | Additions to `tests/test_13_duels.gd` (11.4) | 15 | Bands of 11.4 |
| Perf | Perf test + 20 Scorchlings bursting, 6 Frost Mortars firing, 10 hexes, 2 Sparkwings, 2 Bells ringing | 1 | `PERF OK`, stuck 0 |
Total ~410 runs; at 6 in parallel and ~2-4 min each, ~2-4 hours per full pass. A knob re-run (section 12) repeats only the
round that failed, plus Round A for the pairs of the touched kingdom.
### 11.4 Duels (level 1, no items, attack-move from 20 m, no kiting, 13.2b rules)
| # | Duel | Pass band |
|---|---|---|
| D18 | 10 Grave Hounds (pack) vs 8 Shades | Close: winner <= 40 % HP left |
| D19 | 12 Scorchlings vs 7 Flame Guards | Scorchlings win with <= 4 left |
| D20 | 12 Scorchlings vs 7 Rimeshields | Rimeshields win with >= 3 left |
| D21 | 12 Thornlings vs 8 Shades | Thornlings win with <= 5 left |
| D22 | 10 Rimelings vs 7 Flame Guards | Guards win with <= 3 left |
| D23 | 6 Flame Guards + 2 Pyre Adepts vs 14 Thornlings | Fire wins |
| D24 | 3 Bone Ballistas + 4 Shades vs 1 War Mammoth | Shadow wins, >= 1 Ballista alive |
| D25 | 4 Frostbows vs 2 Blaze Riders | Frostbows win, >= 2 alive |
| D26 | 2 Frost Mortars + 4 Rimeshields vs 12 Thornlings | Ice wins |
| D27 | 3 Vinelashers vs 1 Nightmare Knight | Vinelashers win, >= 1 alive |
| D28 | 2 Bore Beetles vs an undefended Ember Spire | Spire falls in < 15 s |
| D29 | Keep + Bell + 6 militia + 3 Flame Guards vs 10 Grave Hounds (pack) | Defenders win; >= 3 workers alive; keep >= 80 % |
| D30 | Keep + Bell + 6 militia, no soldiers, vs 10 Grave Hounds | All Hounds dead; keep **>= 40 %** (the base stands, the economy pays) |
| D31 | Keep alone, no Bell, vs 10 Grave Hounds | Keep falls in 15-30 s, >= 2 Hounds dead (shows why the Bell and the army matter) |
| D32 | 12 Scorchlings vs an Ember Hall with an Ember Spire 6 m away | Hall lasts >= 12 s; >= 4 Scorchlings die to the Spire (Garrison fire: 3 shots each) |

## 12. Knobs to reach "good average" (one knob per re-run; the first untried row of the symptom)
### 12.1 Kingdom power (Round A)
| Symptom | Knobs, in order |
|---|---|
| **Fire > 55 %** (expected first) | 1. Heat per stack 0.03 -> **0.025** (`research.md` 9.6) · 2. Fireball rank 3 85 -> **80** (rank 2 stays 72: it must still kill 70-HP swarms) · 3. Fire weakness x1.5 -> **x1.25** (`cavalry-mounts.md` 13.4) · 4. Flame Guard cost 90 -> **95** · 5. Pyre Adept Flame Burst 30 -> **24** |
| Fire < 45 % | Scorchling cost 50 -> **45** · Pyre Adept cost 130 -> **115** · Ember Archer HP 70 -> **75** |
| **Nature > 55 %** | 1. Growth-ring interval +30 s (`research.md` 3.4 / 9.6) · 2. Vinelasher cost 120 -> **135** · 3. Bramblehorn cost 200 -> **215** · 4. Deep Roots +0.4 -> **+0.3** |
| Nature < 45 % | Thornling HP 70 -> **75** · Thornling cost 60 -> **55** · Seed Hollow 60 -> **50** · Seasoned Bark 100 -> **75** |
| Shadow > 55 % | Wither Hex -20 % -> **-15 %** · Shade HP 110 -> **105** · Raise the Dead 3 -> **4** souls |
| Shadow < 45 % | Shade cost 80 -> **75** · Bone Ballista cost 200 -> **180** · Pack Hunter max +2 -> **+3** |
| Ice > 55 % | Carved Runes 10 -> **7 %** · Frost Mortar splash r 2.0 -> **1.6** · Frostbow damage 22 -> **20** |
| **Ice < 45 %** (expected first) | 1. Rimeshield cost 95 -> **90** · 2. Rime Spire chill 2 -> **3 s** · 3. Frostbite freeze at 100 -> **80** · 4. Frost Hall build time 54 -> **48 s** (every Ice timing earlier) |
### 12.2 Rushes (Rounds B, C)
| Symptom | Knobs, in order |
|---|---|
| A kingdom's rush success < 25 % or rusher win < 35 % | 1. Its `rush_second_hall_time` -10 s · 2. Its rush unit train time -1 s · 3. Its rush unit cost -5 · 4. Kingdom-specific: Hounds Pack max +3; Scorchling burst 15 -> 18; Thornling proxy P1 5 m closer; Rimeling armor 10 -> 12 |
| A kingdom's rush success > 45 % or rusher win > 55 % | 1. Its rush unit cost +5 · 2. Its rush unit train time +1 s (Hound 13 -> 14) · 3. `rush_worker_cap` 5 -> **4** for that kingdom · 4. Kingdom-specific: Pack max +1; burst 15 -> 12; P1 moved 10 m back toward the own keep; Ice forward spire only if no enemy army seen within 25 m of C1 |
| Every rush too weak | Muster Bell duration 30 -> **25 s** · Garrison fire +50 % -> **+35 %** |
| Every rush too strong | Muster Bell cooldown 150 -> **120 s** · Bell militia armor 30 -> **40** · Garrison fire +50 % -> **+75 %** |
| **> 15 % of rush games end before 8:00** | 1. Garrison fire +50 % -> **+75 %** (every rush unit dies to 3 keep shots) · 2. Keep attack +4 while the Bell rings · 3. Rush unit costs +5 (fewer bodies at 3:00) · 4. `rush_launch_time` +15 s (the defender's army is bigger) · 5. Every keep `max_hp` +20 %. **Never** a building-damage cut (user decision Q1) and never a rush-unit HP buff |
| Unscouted defender (Round C) survives > 50 % | `rush_launch_pop` 8 -> **10**; then rush unit train time -1 s (rushes must punish greed) |
### 12.3 Length (Round A, D)
| Symptom | Knobs, in order |
|---|---|
| Median < 15:00 | Stronghold keep x1.2 -> **x1.3** (`research.md` 9.6) · Bell cooldown 150 -> **120 s** · every keep `max_hp` +20 % (`balance-2.md` 5, already measured +2 min) |
| Median > 20:00 or > 10 % no winner | Citadel keep x1.4 -> **x1.3** · Bore Beetle cost 180 -> **160** · Bone Ballista `building_damage_mult` 1.75 -> **2.0** · rich nodes 2 500 -> 1 800 (`balance-1.md`) |
### 12.4 New units (Round A logs)
| Symptom | Knob |
|---|---|
| A new unit < 3 % of its kingdom's trained pop | First check the bot trains it (share, tier gate); then cost -10 % |
| A new unit > 25 % and its kingdom > 55 % | Cost +10 % |
| Sparkwings kill workers | Sparkwing damage 5 -> **3** |
| Ballistas / Mortars die to their own min range | Fix the pullback (7.2) before any stat |
| Vinelashers make Nature the best late army | Vinelasher HP 170 -> **150** |

## 13. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 16.L1)
Rule for phase-1 agents (as steps 9-14): never use another step-16 agent's new `class_name` as a static type; reach it with
`load()` guarded by `ResourceLoader.exists`, groups, `has_method()`, `get()`.
- **UnitType** (gameplay): `bonus_vs_tags: Dictionary = {}` (tag -> bonus, e.g. `{&"titan": 0.75}`; multiplies with the target's `damage_taken_mult`),
  `min_attack_range := 0.0` (auto-target and attack orders skip targets closer than this; an explicit attack order on one is
  refused `"Too close"`), `abilities: Array[StringName] = []`, `ability_params: Dictionary = {}` (per-ability overrides of 5.2),
  `expansion := false` (hidden unless `Skirmish.expanded_roster`). New tag `&"swarm"`. Reused: `tags`, `building_damage_mult`,
  `bonus_vs_mounted`, `required_keep_tier`, `on_hit_status`, `fly_height`, `turn_rate_deg`, `sight_radius`, `base_stats`
  (`splash_ratio`, `splash_radius`).
- **Unit** (gameplay): `bonus_vs_tags` in the damage path (no worker bonus, no building-damage change for rush units: Q1); `min_attack_range` in auto-target / `command_attack`; status
  **`withered`** (`attack_damage_pct` -0.20, `healing_taken` 0.5, `hero_mult` 0.5, `wizard_immune`); `is_swarm() -> bool`.
- **UnitAbilities** (`scripts/units/unit_abilities.gd`, `class_name UnitAbilities extends Node`, child `"UnitAbilities"` that
  `Unit._ready` creates when `unit_type.abilities` is not empty and the script exists): `setup(unit)`, `ready(id) -> bool`,
  `cooldown_left(id) -> float`, `cooldown_total(id) -> float`, signal `ability_fired(unit, id: StringName, target)`; ids
  `&"flashpoint"`, `&"pack_hunter"`, `&"flame_burst"`, `&"wither_hex"`, `&"hamstring_shot"`, `&"frost_shell"`,
  `&"snare_lash"`. Calls the model's `play_cast()` / `play_burst()` if present and **UnitVfx** (`art/vfx/unit_vfx.gd`,
  `class_name UnitVfx`, group `"unit_vfx"`, `play(id, at, target)`; callers use `get_first_node_in_group`).
- **Keep** (systems): `BELL_DURATION := 30.0`, `BELL_COOLDOWN := 150.0`, `BELL_RADIUS := 16.0`, `MILITIA_STATS := {"armor": 30,
  "attack_damage": 6}`, `can_ring_bell() -> String` (`""`, `"Bell not ready"`, `"Not in this mission"`), `ring_bell() -> String`,
  `stop_bell()`, `is_bell_ringing() -> bool`, `bell_time_left() -> float`, `bell_cooldown_left() -> float`, signals
  `bell_rung(keep)`, `bell_ended(keep)`; keep attack cooldown x0.5 while ringing; model hook `play_bell()` if present.
- **Worker** (systems): `set_militia(on: bool)`, `is_militia() -> bool` (modifier `militia`, gathering paused, aggro inside the
  bell circle); model hook `set_militia(on)` if present.
- **Garrison fire** (systems): `BuildingType.bonus_vs_tags: Dictionary = {}` (tag -> bonus), read by `building_gun.gd` for keeps
  and towers (`{&"swarm": 0.5}` on the 4 keeps and 4 towers); stacks multiplicatively with research tower bonuses.
- **TrainingBuilding / BuildingType** (systems): up to **6** training slots (keys Z X C V B N, card r1c1-r2c2); types with
  `expansion` hidden while `Skirmish.expanded_roster` is false; `required_keep_tier` 2 without a ResearchBank = `"Requires
  Stables"` (own completed Stables), without Stables either = `"Available at 6:00"`.
- **Skirmish** (systems): `@export var expanded_roster := true`, `@export var bell_enabled := true` (missions false),
  `@export var player_bot_style := &"balanced"`, `@export var enemy_bot_style := &"random"` (menu default, Q3),
  `rush_slot(team: int, id: StringName) -> Vector3` for `&"H2"`, `&"P1"`, `&"C1"`, `&"mine_rally"` (6.3; C1 is at the
  **other** team's natural), clearings r 3 at H2 / P1 / C1.
- **AIProfile** (ai): `style: StringName = &"balanced"`, `static func apply_style(p: AIProfile, style: StringName, faction:
  StringName) -> void`, the rusher knobs of 6.1, the rule-1b knobs of 7.1, `unit_mix: Dictionary` (unit id -> `Vector3(default,
  vs_ranged, vs_melee)`; when not empty it replaces the `mix_*` arrays), profile id `&"fire_default"`. Rules 1b, 13c, 15 in
  `ai.md` (game-designer adds them in 16.D3).
- **Keys** (lead's Keys line): keep selected **V** = Muster Bell; building selected **Z X C V B N** = training slots 1-6;
  Stables **V** = its 4th unit.
- **Events**: no change (the HUD rush alert reads the `"units"` group itself, 1 Hz).
- **Ownership**: `scripts/units/unit_abilities.gd`, the 10 new `data/units/*.tres` = gameplay; `scripts/ai/ai_rush.gd` = ai;
  `art/units/<kingdom>/<new unit>/`, `art/vfx/unit_vfx.gd`, `art/vfx/unit_*`, `art/icons/units/<new ids>`,
  `art/icons/abilities/<5 ids>`, `art/icons/muster_bell*` = tech-artists; `docs/design/ui-rush.md` = ui-designer.

## 14. Task list (step 16; build after steps 10-14 are merged)
**Shared files with steps 10-14** decide the phases: `unit.gd`, `unit_type.gd` (13.C1, 14.G1), `keep.gd`, `training_building.gd`,
`building_type.gd` (13.C5, 14.C2), `worker.gd` (14.C3), `skirmish.gd` (10-14), `commander.gd`, `ai_profile.gd`, `data/ai/*.tres`
(10.A3, 12.A1, 13.A1, 14.A1), `command_card.gd`, `selection_panel.gd`, `hud.gd`, `game_settings.gd` (10-14 UI). A step-16 task
that edits one of them starts only after the last step 10-14 task on that file is merged.
**Phase 0:** 16.L1, 16.D2, then **Round 0** (16.L2a) as soon as 10-14 are green. **Phase 1a (new files only):** 16.V1-16.V15.
**Phase 1b (shared files free):** 16.C1, then 16.C2 and 16.C3 in parallel, 16.C4 (needs 16.D2). **Phase 2:** 16.A1, then
16.A2, 16.A3 (harness, parallel to 16.A2), 16.C5, 16.C6. **Phase 3:** 16.L2 (Rounds A-F), playtest, 16.D3, re-runs.
| Id | Agent | Task | Files | Done when |
|---|---|---|---|---|
| 16.L1 | lead | Freeze section 13 in `CLAUDE.md` ("Rush and roster" bullet), Keys line (keep V, slots Z-N, Stables V), owner rows, step-16 ids in `waves.md`, `step16-agent-rules.md`, the Q1-Q3 answers | `CLAUDE.md`, `docs/plan/` | Contracts, keys and rules file written |
| 16.D2 | ui-designer (Fable) | `ui-rush.md`: section 10 at 1600 x 900 (bell button + chip, 6th Hall slot, Stables V, militia tag, rush alert, style option, ability icons), consistent with `ui-style.md`, `ui-cavalry.md`, `ui-research.md` | `docs/design/ui-rush.md` | Every element of section 10 has position, size, look |
| 16.L2a | lead | Round 0 (11.3) with the step 10-14 harness flags | `tests/`, `docs/plan/` | 48 runs logged; order and median sent to the game-designer |
| 16.C1 [H] | gameplay-coder-high | UnitType fields (13), Unit damage bonuses, min range, `withered`, `is_swarm`; `UnitAbilities` with the 7 ids of 5.2; UnitVfx calls (load-guarded) | `scripts/units/unit_type.gd`, `unit.gd`, `scripts/units/unit_abilities.gd` (new) | Test: a lone Grave Hound hits a worker and a keep for 8 (no Light rule); 3 Hounds together hit for 10; a dying Scorchling deals 15 to an enemy 1.5 m away, 0 at 2.5 m, 0 to buildings; Flame Burst fires only with >= 3 enemies in 2.5 m, every 14 s; a hexed Shade deals 8.8 and heals x0.5 for 6 s (3 s on a champion, 0 on a wizard); Hamstring chills a Blaze Rider 3 s and it cannot charge; a Frost Mortar never targets a flyer or a unit at 4 m, and its shell chills 3 clumped Shades; Snare Lash roots a Nightmare Knight 0.75 s and its armor drops to 0; a Ballista deals 63 to a War Mammoth before armor; `PERF OK` |
| 16.C2 | gameplay-coder | The 10 unit `.tres` (5.1), Grave Hound / Thornling rows of 9, kill_xp, `expansion` true on the 10 | `data/units/*.tres` | Numbers of 5.1 / 9 exact (test reads them) |
| 16.C3 | systems-coder | Hall 6 slots + `expansion` filter + T2 fallback gate; barracks / stables `train_ids`; **Garrison fire** (`bonus_vs_tags` on keeps / towers); Muster Bell (Keep) + militia (Worker) + keep fire x2; Skirmish flags, `rush_slot`, clearings | `scripts/buildings/training_building.gd`, `keep.gd`, `building_type.gd`, `building_gun.gd`, `scripts/economy/worker.gd`, `scripts/world/skirmish.gd`, `data/buildings/*_barracks.tres`, `*_stables.tres`, `*_keep.tres`, `*_tower.tres` | Test: a keep shot deals 18 to a Grave Hound and 12 to a Shade, an Ember Spire 22.5 to a Scorchling; with the Bell the keep deals 18 every 0.75 s to swarm units; the Frost Hall lists 6 types with Frostbow on N, disabled `Requires a Stronghold` until the Stronghold (`Requires Stables` with research off); missions list no step-16 unit; the Bell turns 6 workers within 16 m into militia (armor 30, 10 damage), not one at 18 m, the keep fires every 0.75 s, workers mine again after 30 s, `Bell not ready` for 150 s; H2 / P1 / C1 pass `BuildGrid.check` on both sides; smoke `victory=true` |
| 16.C4 | ui-coder | Section 10 (after 16.D2): keep Bell V + chip, Hall slot N, Stables V, militia tag, ability icons + cooldowns, `withered` icon, rush alert, `Enemy style` option, help text, audio | `scripts/ui/command_card.gd`, `selection_panel.gd`, `hud.gd`, `scripts/ui/menus/game_settings.gd` (+ the skirmish setup scene), `assets/audio/rush_*` | As 16.D2; nothing in `scripts/ui/` calls a `_private` function |
| 16.A1 [H] | ai-coder | Style overlay (`apply_style`, `random`), Rusher rule 15 (phases, build orders H2 / P1 / C1, route pick, targets, exit, second wave, transition), `fire_default` profile | `scripts/ai/ai_rush.gd` (new), `commander.gd`, `ai_profile.gd`, `data/ai/*.tres` | Headless normal Rusher, each kingdom vs a passive Balanced bot: H2 by 1:15 (Ice 1:25), P1 by 1:25 (Nature), 5 workers until exit; launch 2:35-3:05 (Ice 2:55-3:15) with >= 8; arrival logged; workers are the first targets; no rush unit attacks a keep before `rush_max_time`; C1 site by 3:45 (Ice); exit by 4:45 (Ice 5:15); X1 placed <= 60 s after exit; `PERF OK` |
| 16.A2 | ai-coder | Rule 1b + 13c for every style, Bell use, alert champion, contain response, punish expand; `unit_mix` by id + extra rows; min-range pullback; siege adds; Sparkwing scouting | `commander.gd`, `ai_profile.gd`, `ai_memory.gd`, `data/ai/*.tres` | Test: a scripted pack of 10 Hounds crossing at 2:50 -> alert within 5 s of the 5th Hound seen, S1 placed within 10 s (crystals allowing), army at the mine rally, Bell rung when the 1.2 ratio holds, workers mine again after; a spire site near X1 is attacked; T2 units trained per `unit_mix` once unlocked; a Ballista with a Shade at 3 m steps back; exactly 1 Sparkwing alive |
| 16.A3 | ai-coder | Matrix harness: flags of 11.1, CSV of 11.2 (`worth`, success flag), round presets (`--round=A`), summary tables (win rates per pair / kingdom, medians, rush rows); duels D18-D32 in the 13.C9 harness (D29-D32 need a keep / Hall / Spire and workers in the duel scene) | `tests/test_16_a3.gd` (new), `tests/test_13_duels.gd` (add rows, after 13.C9) | `--round=0` runs 48 games and prints the section-8 table; a 2-run smoke of each round works headless; duels print PASS / FAIL |
| 16.C5 | gameplay-coder | Plug the 10 unit models (`model_path`), hooks `play_cast`, `play_burst`, flyer model height, UnitVfx calls | `data/units/<10 ids>.tres`, `scripts/units/` (hooks only) | Models replace placeholders; hooks fire; smoke `victory=true` |
| 16.C6 | systems-coder | Plug the Bell (`play_bell`) on the 4 keeps and militia (`set_militia`) on the 4 workers | `keep.gd`, `worker.gd` (hook calls only) | Hooks fire on ring / end |
| 16.V1 | tech-artist | Scorchling (model + icon) | `art/units/fire/scorchling/`, `art/icons/units/scorchling*` | Each V task: silhouette screenshot in `docs/art/screens/`, budget held, hooks present, headless instantiation clean, `KITFIX AUDIT OK` |
| 16.V2 | tech-artist | Pyre Adept | `art/units/fire/pyre_adept/`, icon | as V1 |
| 16.V3 | tech-artist | Sparkwing (flyer rig, 13.V13 pattern) | `art/units/fire/sparkwing/`, icon | as V1 |
| 16.V4 | tech-artist | Hexweaver | `art/units/shadow/hexweaver/`, icon | as V1 |
| 16.V5 | tech-artist | Bone Ballista | `art/units/shadow/bone_ballista/`, icon | as V1 |
| 16.V6 | tech-artist | Rimeling | `art/units/ice/rimeling/`, icon | as V1 |
| 16.V7 | tech-artist | Frostbow | `art/units/ice/frostbow/`, icon | as V1 |
| 16.V8 | tech-artist | Frost Mortar | `art/units/ice/frost_mortar/`, icon | as V1 |
| 16.V9 | tech-artist | Vinelasher | `art/units/nature/vinelasher/`, icon | as V1 |
| 16.V10 | tech-artist | Bore Beetle | `art/units/nature/bore_beetle/`, icon | as V1 |
| 16.V11 | tech-artist (VFX) | Fire + Shadow: Flashpoint burst, Flame Burst, Pack Hunter glow, Wither Hex threads + `withered` mark, ballista bolt; `unit_vfx.gd` | `art/vfx/unit_vfx.gd`, `art/vfx/unit_fire_*`, `unit_shadow_*` | `UnitVfx.play(id, ...)` works for its ids; `PERF OK` with 20 bursts |
| 16.V12 | tech-artist (VFX) | Ice + Nature: Frost Shell arc + splash, Hamstring shot, Rimeling chill hit, Snare Lash vine, beetle sawdust | `art/vfx/unit_ice_*`, `unit_nature_*` | as V11 |
| 16.V13 | tech-artist | Muster Bell on the 4 keeps (`play_bell`: a bell swings, ring pulse r 16) | the 4 keep scene folders | Hook in each keep scene |
| 16.V14 | tech-artist | Militia look on the 4 workers (`set_militia`: helmet + raised tool) | the 4 worker scene folders | Hook in each worker scene |
| 16.V15 | tech-artist | Icons: Muster Bell, 5 abilities, `withered`, `Swarm` tag | `art/icons/abilities/`, `art/icons/muster_bell*` (new files only) | Icons in the pipeline |
| 16.L2 | lead | Integration (UnitVfx node in both scenes, handoffs), Rounds A-F + duels + perf, CI, playtest copy | `tests/`, `scenes/`, `docs/plan/` | Rounds logged; failures sent to 16.D3 |
| 16.D3 | game-designer | Balance from the logs and the playtest: the knob ladder of section 12, results table here, `ai.md` rules 1b / 13c / 15, the other specs' changes (15) | `docs/design/` | Section 8 passes, or the knobs applied and the re-run plan are written |
Playtest (user): a 1v1 vs a **Rusher** bot of each kingdom (does it feel beatable when scouted, painful when not?), then
vs **Random**; try each kingdom's rush yourself with the build orders of section 4.

## 15. What changes in other specs (16.D3 writes them after the build)
`ai.md`: rules 1b, 13c, 15, style overlay, `unit_mix`. `units-fire-shadow.md`: Grave Hound row, Scorchling, Pyre Adept,
Sparkwing, Hexweaver, Bone Ballista. `kingdom-ice.md` / `kingdom-nature.md`: the new units, Thornling row, the speed line.
`buildings.md`: 6 training slots, keep Muster Bell. `cavalry-mounts.md`: Stables slot V. `research.md`: T2 units' gate.
`levels.md`: 10 victim rows. `map-fill.md`: H2 / P1 / C1 clearings, the rush routes. `ui-hud.md`: help text, rush alert.
`CLAUDE.md` (lead): section 13.

## Done when (step 16)
- [ ] Every kingdom can rush with its unit and build order (section 4), and every bot answers a rush with rule 1b.
- [ ] The 10 new units are trainable at their tier and slot, with their abilities, models, icons and VFX.
- [ ] Round A: kingdom win rates 43-57 %, pairs in band, median 15:00-20:00, <= 10 % no winner.
- [ ] Rounds B-C: rush success 30-40 % overall (25-45 % per kingdom), rusher wins 35-55 %, <= 15 % of rush games end before 8:00, unscouted rushes succeed >= 50 %.
- [ ] Round D: no system toggle moves a kingdom across 60 / 40 %; duels D18-D32 in band; `PERF OK`, stuck 0; 0 script errors.

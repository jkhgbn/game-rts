# Campaign mission e8m2: "The Last Muster" (all four kingdoms, together for the first time; Episode 8)

Written 2026-10-02 (`campaign-outline.md` 3.8 and 4.2). Episode 8 "The Four Keys", mission 2 of 3 per playthrough (id
`e8m2`, spec `docs/design/mission-e8-02.md`, scene `missions/mission_e8_02.tscn`, script
`scripts/campaign/mission_e8_02.gd`, `MissionE802 extends MissionBase`). Plays after the player's road (`mission-e8-01.md`)
and the film `c_e8_muster` "Especially Malrik". **The four kingdoms fight on one side for the first time**: the player's
wizard at their own seat of **Fourfold Hollow** (`map-2v2.md`), the other three as **allied wizard bots** at the other
three seats, against the **Hollow Host** pouring out of the cracked isle and four Hollow Gates. Each wizard must walk their
key to their **keyhole** on the bank by their Crown Bridge; four lit keyholes wake the King (e8m3). Target **25-30 min** on
normal. Uses `map-2v2.md` (seats, frames, `Teams`, river), `ai-2v2.md` (ally layer, pings), `mission-04.md` (Hollow
meter, Keystone Pylons, Ruin Wardens), `mission-e8-01.md` 1.4 (Host and Stone-sworn types), `tiers.md` 6,
`caster-units.md`, `t3-helpers.md`, `tier3-extras.md` / `titans-2.md` / `cavalry-mounts.md` (Lairs and titans),
`champions.md` 11, `items.md`. Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `+z` = south.
Status: **design only**; nothing here is built. Recommended option taken everywhere (no questions).

## 0. Decisions (recommended option taken)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | Map | **Fourfold Hollow** (`data/maps/fourfold_hollow.map`, 168 x 168), the outline's "Crown Hollow layout + the 2v2 seat frames". Camps, beasts, capture points, trade, research, Magpies, Hunters off; river **on** (fords open: no nests); taverns on (player only); caches on | The only 4-seat map; its isle is Crown Hollow's isle, so the King rises where Obren fell |
| D2 | Who sits where | The player is always seat **A1** (`PLAYER`, south-west, keep `(-66, 66)`). The other three kingdoms take **A2, B1, B2** in the prologue's order (Vessa -> Malrik -> Torvald -> Ysolde, cyclic) after the player's kingdom (table 2.1) | One camera / HUD layout for every playthrough; the order keeps each wizard's neighbours varied |
| D3 | One side | `Teams.configure({PLAYER: 0, ALLY: 0, ENEMY: 0, ENEMY_2: 0})`: **all four seats are side 0** (allied: shared vision, no friendly fire, read-only ally inspect, ally pings). The Host is **team NEUTRAL** (`neutral_leash` false), hostile to all four. Colours come from `Teams.relation` (all three bots draw as **ally**, `ui-2v2.md` 2.3), never from the raw team value | `map-2v2.md` 4.1: team = seat, sides from `Teams`. The seat values `ENEMY` / `ENEMY_2` are only slot names here |
| D4 | How the allies are run | Three Commanders with profile **`mission_e8`** (section 6): gather, train to 40 pop, defend their quarter, answer the Host, and follow **scripted key pushes** driven by a **Muster bar** per ally. The player commands only their own seat (allies are never orderable: `is_commandable` by seat, the 2v2 rule); the player's levers are **help** (fight in an ally's quarter), **pings** (the 2v2 ping wheel: Help / Attack / Defend) and **answering an ally's Help ping** | The outline: "the bots theirs on a timer the player can speed up by sending help (ally call-for-help pings)" |
| D5 | Can the allies lose | Allied wizards **cannot die** (at 1 HP they kneel 10 s, untargetable, stand at 50 %: the M4 Vey rule); allied keeps have an **HP floor of 20 %**; other allied buildings can fall and are rebuilt by their bot | The story needs four keys; the player's own kingdom stays fully at risk |
| D6 | Start tier | Every seat starts at the **Citadel** (`Keep.set_start_tier(3)`), `max_tier = 3`; every tier-2 / tier-3 unit, caster and "+" upgrade open at 0:00 | The muster of four full kingdoms, not a build-up |
| D7 | Helpers | **All four helpers on the field at 0:00**, each bonded to its wizard at the wizard's level: Old Vey (Fire), **Veyra Nightquill** (Shadow, `mission-e8-01.md` D8: Hush fled), Aldra (Ice), Maelis (Nature). `helpers_enabled = true`; revive rules of `t3-helpers.md` 3 for the player's; allied helpers revive free after 45 s at their keep | Outline: "all helpers on the field (allies' helpers fight as theirs)" |
| D8 | Titans | `titans_enabled = true` for this mission (and e8m3): every seat has a **pre-built Lair** (Dragon Roost / Dread Paddock / Glacier Den / Elder Circle; slots Z titan, X the 13b unit, C the 13c option, `titans-2.md` 1). The Lair's own 8:00 floor stays (research off). Each **ally** brings **one free titan** at its march (6.3) | Outline: "Unlocks: titans"; the first time a player sees all four kingdoms' titans together |
| D9 | Keyholes | Four **keyholes** on the four banks, each **6 m off its seat's Crown lane, 24.8 m from the isle centre** (the M4 pylon rule, so the King's ring in e8m3 is even), each **under a Keystone Pylon** (1 400 HP, the M4 numbers). Break the pylon, then the seat's own wizard channels **5 s within 3 m** (the `MissionBrazier` rule) with no Host unit within 8 m | One readable rule for four keys; reuses M4's pylon and brazier code |
| D10 | Hollow meter | Returns (M4), retuned for four armies: **+0.5 % per unit death of any seat** (no time term), +3 % when an allied wizard kneels; at 100 % the **Early Rise** (5.3): the mission goes on harder and e8m3's King gains +10 % HP | The outline's "every death feeds the King" at the scale of four kingdoms |
| D11 | Level and carry | The player's wizard **level 6 with 5 unspent points**, cap 8; the track's 6 slots, key relic (slot 1, forced, `mission-e8-01.md` D3-D4), slot 2, essence, companion; allied wizards level 6 with the `AIStoryCaster` ranks | One step up from the road |
| D12 | Champions | Taverns open at 2:00 **for the player only** (bots never hire); the track's companion walks in | Hiring returns for the muster; bots stay readable |
| D13 | Pell | Pell's cart at the A1 peddler spot `(-30, 50)` for every road (`m1_peddler_freed` only changes his first line) | He is in the ending (E21's rubble sign); every road should meet him once |

## 1. Story setup (briefing, 3 short paragraphs; after `c_e8_muster`)
1. They came by four roads, and for one evening they stood on the same hill: fire, shadow, ice and green. Nobody drew a
   blade. Old Vey said it was the first miracle he had seen in thirty years.
2. Below them, Crown Hollow is splitting open. Four keyholes have pushed up out of the earth, one on each bank, and the
   Hollow's pylons stand on every one of them. The Host is climbing out of the isle by the thousand.
3. Each of you carries a key. Walk it to your keyhole. Help the others walk theirs. Every soldier who falls here falls
   into the Hollow, and something under the isle is counting.
Briefing objectives: `obj_key`, `obj_four`, `<Wizard> must survive`, `Your keep must stand`; the line `Every death feeds
the Hollow.`

## 2. Map: "Fourfold Hollow, the Last Muster" (`data/maps/fourfold_hollow.map`, 168 x 168)
`map-2v2.md` 2 unchanged (seat frames, nodes, houses, halls, roads, taverns, peddlers, river and its 10 crossings) except
the rows below. Light: dusk turning to night over the match (`preset_golden` -> storm dusk at 15:00, 19.V25 cloud layer
from 20:00); the isle's crack glows brighter with the Hollow meter (19.V4 stages 1-4 at 25 / 50 / 75 / 100 %).
### 2.1 Seats (D2)
| Player's kingdom | A1 `PLAYER` (south-west, keep `(-66, 66)`) | A2 `ALLY` (north-west, `(-66, -66)`) | B1 `ENEMY` slot (north-east, `(66, -66)`) | B2 `ENEMY_2` slot (south-east, `(66, 66)`) |
|---|---|---|---|---|
| Fire (Vessa) | Fire | Shadow (Malrik) | Ice (Torvald) | Nature (Ysolde) |
| Shadow (Malrik) | Shadow | Ice | Nature | Fire |
| Ice (Torvald) | Ice | Nature | Fire | Shadow |
| Nature (Ysolde) | Nature | Fire | Shadow | Ice |
Muster order (6.2): **A2 first, B1 second, B2 last** (A2 shares the player's bank; B1 / B2 are across the Hollowmere).

### 2.2 Mission objects
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| **Keyhole K-A1** (player) | `(-12.75, 21.25)` | 3 | 6.0 m south-east of the A1 lane centre line (x + z = 0), 24.8 m from `(0, 0)`, 8.9 m from tower slot SM `(-11, 30)`, 17 m from the A1 tavern `(-25, 9)`, 14.2 m from West Crown Steps `(-12.75, 0)` |
| Keyhole K-A2 / K-B1 / K-B2 | `(-12.75, -21.25)` / `(12.75, -21.25)` / `(12.75, 21.25)` | 3 | The seat-frame mirrors |
| Keystone Pylon on each keyhole | Same centre | - | M4 pylon: 1 400 HP, armor 20, NEUTRAL, rises at 0:00 (visible from the start, no tether until e8m3), 2 Ruin Wardens / 35 s (max 6, aggro 10, leash 18) |
| **Throne Crack** (Host spawn) | `(0, 0)` (the isle, r < 11) | - | `mission-e8-01.md` 1.4; the Host leaves the isle by the four Crown Bridges and both Crown Steps |
| **Hollow Gate G-A1** | `(-9, 80)` (A1's Mouth lair spot; camps off) | 5 | Warden Gate, 1 800 HP, armor 20; front faces `(-1, -1)` (toward A1's rich node / hub) |
| Hollow Gate G-A2 / G-B1 / G-B2 | `(-9, -80)` / `(9, -80)` / `(9, 80)` | 5 | Mirrors; fronts face their seat's hub |
| Pell's cart | `(-30, 50)` (A1 peddler spot) | 5 | `RuinPeddler` (Pell), open at 0:00 |
| Stone-sworn column spawn | The Shadow seat's outer corner: its keep + `(14, 14)` turned outward by the seat frame (A2 `(-80, -80)`, B1 `(80, -80)`, B2 `(80, 80)`; never A1's corner: if the player is Shadow, the column comes from `(-80, 80)` - their own corner) | - | 12:00 event (4.2) |
Distances (path): A1 hub -> K-A1 62 m (the lane, over nothing: K-A1 is on the player's bank); A1 hub -> K-A2 98 m (connector road
then the lane, same bank); A1 hub -> K-B2 via Millstone Bridge 118 m or via the isle (West -> East Crown Steps) 72 m;
A1 hub -> K-B1 via the isle 92 m. **The isle is the shortcut between the banks, and it is where the Host comes from.**
Keyholes are **seat-bound**: only that seat's wizard can channel it (the ring shows the seat's colour and wizard icon).

## 3. Start state (every seat; the player's from the track, D11)
| Item | Value |
|---|---|
| Player's wizard | L6, 5 unspent points (spell 1 r1), cap 8; slot 1 = the key relic (forced); slot 2 as saved; 6 slots, essence 150 + carried; companion |
| Crystals / essence / pop | **600** / as above / see below; houses max **6** per seat (keep 20 + 6 x 20 = cap 140) |
| Buildings (each seat, complete) | Keep (**Citadel**), 2 Halls (H1 + X1 spots), 2 towers (S1, S2), **3 houses** (V1-V3, cap 80), the kingdom's **Lair** (Fire Dragon Roost / Shadow Dread Paddock / Ice Glacier Den / Nature Elder Circle) on the seat's rich-hall spot X2 (A1 `(-23, 64)`, framed for the others) |
| Workers | 8 per seat (4 / 4 on the home nodes) |
| Helper (D7) | Beside its wizard, at the wizard's level, Escort |
| Player's kingdom army at `rally` (frame of `(-53, 53)`) | Table 3.1 (~3 000 crystals) |
| Allied seats | The same table for their kingdom; wizard L6 (`AIStoryCaster` ranks: spell 1 r3, spell 2 r2, spell 3 r1), helper, Lair |
| Flag bonuses (the player's road only) | 3.2 |
### 3.1 Start armies (equal value; a seat's army as player or ally)
| Kingdom | Units | Crystals | Pop |
|---|---|---|---|
| Fire | 10 Flame Guards, 6 Ember Archers, 4 Blaze Riders, 2 Pyre Adepts, 2 Cinder Arbalests, 1 Kilnwarden, 1 Ashveil Saboteur | 3 100 | 32 |
| Shadow | 8 Shades, 4 Nightbolts, 2 Shadow Knights, 3 Hexweavers, 2 Hollow Oathsworn, 1 Gloom Deacon, 2 Nightblood Reavers | 2 945 | 33 |
| Ice | 8 Rimeshields, 4 Shardcasters, 3 Frostbows, 1 Rime Seer, 2 Hoarlight Magebows, 2 Frost Mortars, 1 Rimecarver, 2 Shardguards | 2 910 | 30 |
| Nature | 12 Thornlings, 4 Burr Slingers, 6 Wildwood Archers, 3 Bloomtenders, 2 Vinelashers, 1 Greenheart Oathkeeper, 1 Bramblehorn, 1 Bramblesage, 1 Briar Roc | 2 920 | 37 |
Population at 0:00 = army + 8 workers + helper 4 (e.g. Fire 44 / 80).
### 3.2 What the road brings (the player's seat only; the flags exist only on the played road)
| Flag (from `mission-e8-01.md`) | Effect here |
|---|---|
| `e8m1_fire_waited` | Vey's **Gathering Storm** (e8m1 A.4) runs around K-A1: fills while Vessa stands within 30 m of K-A1, strikes the largest Host clump within 30 m of it (8 x 60, Wardens x 2) |
| `e8m1_fire_scouts` | Ashby's 4 Blaze Riders (veterancy 2, guests, pop 0) at the A1 rally |
| `e8m1_shadow_shovel` | The Hollow meter starts at **0 %**; otherwise it starts at **2 % x `e8_stone_uses`** (the stone's hunger) |
| `e8m1_shadow_raids` | The 12:00 Stone-sworn column loses its 2 Barrow Knights |
| `e8m1_ice_saved >= 30` | The **Kettlewick Guard**: 4 Rimeshields (veterancy 2, guests) at the A1 rally |
| `e8m1_ice_shut` | G-A1 starts at 50 % HP (900): the habit of closing gates |
| `e8m1_nature_saved` (0-3) | One hamlet militia squad (2 Wildwood Archers + 2 Thornlings, guests) per saved hamlet at the A1 rally |
| `e8m1_nature_bridge` | Maelis starts at L7 (one level above Ysolde) |
| `m1_peddler_freed` | Pell's first line is L28 (else L28b) |
No save (menu debug, tests): Vessa's row (Fire), key relic only, 6 empty slots, essence 150 + 900, no flags.

## 4. Mechanics
### 4.1 Keyholes and pylons (D9)
| Step | Rule |
|---|---|
| Pylon | Standing: the keyhole is sealed (the ring is grey); its Wardens guard it. Destroyed (any seat's damage): the keyhole opens; message `The <kingdom> keyhole is open.` |
| Channel | The seat's wizard within **3 m for 5 s** (progress ring; leaving resets; damage does not); blocked (ring red) while any Host unit is within **8 m** |
| Lit | The keyhole becomes a **Key-Ward** (team = that seat, **3 000 HP**, armor 20, `counts_for_defeat` false, regen 0.5 % / s with no Host within 12 m), a pillar of the kingdom's colour goes up (cosmetic), the relic icon on the objectives panel turns gold; a Key-Ward can be attacked (the Host tries) but a lit key **stays lit** in e8m2 even at 1 HP (HP floor 1) |
| The player's | No timer: break the A1 pylon and channel whenever ready. The pylon's death fires the **Keyhole Rush** (4.2) |

### 4.2 The Host (team NEUTRAL; normal; easy x 0.6, hard x 1.4 of every count, rounded, min 1)
| Source | When | Units | Target |
|---|---|---|---|
| **Crack tides** | Every **90 s** from 1:30 | 6 Wardens (+1 per 3:00 elapsed, max 12), + 1 Rubble Sentinel from 6:00, + 2 from 15:00 | Rotates A1 -> A2 -> B1 -> B2: that seat's keyhole (pylon or Key-Ward), then its hub; refreshed every 4 s |
| **Gate tides** | Each standing Hollow Gate, every **120 s** from 3:00 | 4 Wardens (+1 per 4:00, max 8), + 1 Sentinel from 10:00 | Its seat's rich node ("the Mouth"), then that seat's hub |
| Pylon guards | Each standing pylon, every 35 s | 2 Wardens (max 6 alive) | Guard (aggro 10, leash 18) |
| **Keyhole Rush** | The A1 pylon dies | 8 Wardens + 2 Sentinels from the Crack | K-A1, then the player's wizard |
| **March pressure** | An ally's march starts (4.3) | 6 Wardens + 1 Sentinel from the Crack | That ally's keyhole |
| **Stone-sworn column** | 12:00 | 6 Shades, 3 Nightbolts, 2 Shadow Knights, 1 Gloom Deacon, 2 Barrow Knights (Stone-sworn, team NEUTRAL) from the Shadow seat's corner (2.2) | The Shadow seat's keep (Malrik's renegades come for him), then the nearest keyhole |
| **Early Rise** extra | After 5.3 | +50 % on every later tide; + 1 Sentinel from the Crack every 60 s | As their tide |
A Hollow Gate destroyed stops its tides for good. Allies break their own gate when their Muster bar first reaches 50 % (a
scripted push, 6.3); the player may break any gate.

### 4.3 The Muster bars (one per ally; objectives panel, three thin bars with the ally's colour and wizard icon)
| Rule | Value |
|---|---|
| Fill by time | 0 -> 100 % at **16:00 (A2), 20:00 (B1), 24:00 (B2)** on normal |
| Help: Host kills | **+2 %** per Host unit killed by the **player's** units within **30 m** of that ally's keep or keyhole (max **+40 %** per ally from kills) |
| Help: answered ping | When an ally pings **Help** (6.4) and **8+ pop** of the player's units reach **30 m** of the ping point within **60 s**: **+10 %** (max 3 per ally) and that ally's thanks line |
| At 100 % | The **march**: the ally's army (all but 8 pop left home) + wizard + helper + its **free titan** (spawned at its keep: Cinder Dragon / Nightmare Knight / War Mammoth / Elder Treant, the step-13 titan of its Lair, pop 0) attack-move to its pylon; pylon dead -> the wizard walks in and channels |
| Failed march | The march army falls below **30 %** of its starting value before the pylon dies: it walks home, the bar restarts at **60 %**, the titan stays |
| Displayed | `Malrik musters: 64 % (march at ~3:10)`; marching: `Malrik marches on his keyhole`; lit: `Shadow's key is turned` |
Order is not forced: a well-helped B2 can march before A2.

### 4.4 The Hollow meter (D10)
Objectives-panel line `The Hollow stirs: 41 %` (orange 50 %, red 75 %), shown from 0:00.
| Source | Amount |
|---|---|
| A unit of any seat dies (soldiers, workers, casters, champions, the companion; not summons, not guests) | **+0.5 %** |
| An allied wizard kneels / the player's helper falls | **+3 %** / **+2 %** |
| Host deaths, time | 0 |
| Start | 0 % (or `2 % x e8_stone_uses`, 3.2) |
Messages (4 s): 25 % `The isle is breathing.`, 50 % L18, 75 % L19. At **100 %**: the **Early Rise** (5.3), once; the meter
stays at 100 % and is hidden.
Expected normal: ~90-120 deaths across four seats over 25 min = **45-60 %**; a careless player who feeds the Host 60
soldiers reaches 75-90 %.

### 4.5 Allied safety (D5)
Allied wizards kneel at 1 HP (10 s, untargetable), stand at 50 %; allied keeps cannot go below 20 % HP; allied helpers
revive free after 45 s; a bot whose Halls fall rebuilds them (its profile). None of this applies to the player's seat.

## 5. Objectives and events
### 5.1 Objectives
| id | Type | Text | Done when |
|---|---|---|---|
| `obj_key` | Primary | `Turn your key: break the pylon, then stand at your keyhole` | K-A1 lit |
| `obj_four` | Primary | `Light all four keyholes (1 / 4)` with the four kingdom icons | 4 Key-Wards |
| `obj_wizard` | Primary, always | `<Wizard> must survive` | Fails = defeat |
| `obj_keep` | Primary, always | `Your keep must stand` | Fails = defeat |
| `sec_help` | Secondary | `Muster together: help every ally (0 / 3)` | Each ally got >= 15 % of its bar from the player's help (kills + answered pings) before its key was lit |
| `sec_hollow` | Secondary | `Keep the Hollow under 75 %` | Mission won and the meter never reached 75 %; **failed** when it does |
| `sec_gate` | Secondary | `Break your Hollow Gate` | G-A1 destroyed |

### 5.2 Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (StoryFlow: `c_e8_muster`, then the briefing.) Cutscene `e8m2_seats` (HOLD 0:25): L1-L5; hint `Break the pylon on your keyhole, then stand on it with <Wizard> for 5 s. Fight in an ally's quarter to make them muster faster.` (10 s); meter and Muster bars shown |
| E2 | 1:30 | First Crack tide; L6 |
| E3 | 2:00 | Taverns open (the player's); Pell's line L28 / L28b the first time the wizard is within 10 m of his cart |
| E4 | 3:00 | First Gate tides; L7 |
| E5 | The A1 pylon dies | Keyhole Rush; L8 |
| E6 | K-A1 lit | `<W>` key line (L9, four recordings); `obj_key` done; `obj_four` 1 / 4 (+ any ally already lit) |
| E7 | An ally pings Help (6.4), first per ally | That ally's help line (L10 / L11 / L12 / L13 by kingdom) |
| E8 | An answered ping | That ally's thanks line (L14-L17 by kingdom), once per ally |
| E9 | An ally's bar reaches 100 % | March; its march line is the help line's sequel L20-L23 by kingdom, once |
| E10 | An ally's keyhole lit | Its key line (L24-L27 by kingdom); `obj_four` +1 |
| E11 | 8:00 | Lair titans trainable; hint once `Your Lair can raise a titan now.` |
| E12 | 12:00 | Stone-sworn column; L29 (Malrik, whoever plays him), L30 |
| E13 | Hollow 50 % / 75 % | L18 / L19 |
| E14 | **Hollow 100 %** | **Early Rise**: cutscene `e8m2_hand` (PAUSE 0:10): L31; end state: the King's hand stands out of the isle (a static 9 m prop, blocks nothing: the isle centre r 4 becomes an obstacle), +50 % tides, the extra Sentinels; flag `e8m2_early_rise`; `sec_hollow` already failed |
| E15 | G-A1 destroyed | L32; `sec_gate` done |
| E16 | Player's helper falls / revived | Its own bark (`t3-helpers.md` 10.4) |
| E17 | **4th keyhole lit** | World held; cutscene `e8m2_turn` (PAUSE 0:40): L33-L38; `Events.mission_ended(true)` at its end; save (section 9); StoryFlow loads `e8m3` |
| E18 | Player's wizard dies | L39 (`<W>`); defeat after 3 s |
| E19 | Player's keep destroyed | Defeat after 3 s (no line) |
| E20 | Player's keep under 30 % (once) | L40 (Vey if the player is Fire, else the A2 ally's help line is reused) |

## 6. The allied bots (`ai-2v2.md` ally layer; profile `mission_e8`, ai-coder)
### 6.1 Profile `mission_e8`
| Knob | Value |
|---|---|
| Base | The kingdom's **normal** knobs; `bots_upgrade` irrelevant (Citadel at start) |
| Economy | `worker_target_home` 10, may take its natural; no further expansion; houses to 6 |
| Army | Trains to **40 army pop** (its kingdom's normal mix incl. tier 2 / 3 and its caster), "+" upgrades as the skirmish bot |
| Defence | Defends its quarter: hub, natural, Mouth (rich node), its pylon / Key-Ward within **35 m**; never leaves its bank except on the march |
| Titans | Never trains titans; its free titan comes with the march (4.3) |
| Wizard | Casts by `AIStoryCaster` rules; stays with its army; kneels instead of dying (D5) |
| Helper | Escort its wizard |
| Champions | Never hires |
### 6.2 Its timeline
Muster (4.3) from 0:00; at **50 %** a scripted push on its own Hollow Gate (army attack-moves to the gate and back);
at **100 %** the march; after its key is lit, its army returns home and defends; it keeps helping a neighbour's keyhole if
the Host stands within 20 m of one (the 2v2 "help ally" rule).
### 6.3 The march
Attack-move to its pylon with the march group (army minus 8 pop, wizard, helper, titan); pylon dead -> the wizard walks
to the keyhole ring and channels; Host within 8 m -> the army clears the ring first. Retreat rule 4.3.
### 6.4 Pings to the player (AllyChannel, `ai-2v2.md` 5.1)
| When | Ping |
|---|---|
| Its keep, keyhole or march army is attacked by Host worth >= **1 200** (value of `mission-e8-01.md` 1.4) | **Help** at the fight's centre (max one per 90 s per ally) |
| Its march starts | One **Help** at its pylon |
| Its key is lit | No ping: a gold flash on its keyhole and its key line (E10) |
The player's pings to allies (Attack / Defend on a point): an ally whose army is home sends **half** of it there for 60 s
(the 2v2 ally layer's answer), never during its own march.

## 7. Units, tiers, economy
| Item | Value |
|---|---|
| Code | `MissionE802._init`: `tiers_enabled`, `casters_enabled`, `t3_enabled`, `helpers_enabled`, `titans_enabled = true`, `tavern_enabled = true` (player only), `river_enabled = true`, camps / beasts / points / trade / research / Magpies / Hunters false; `Teams.configure(...)` (D3); `_ready`: `max_tier = 3`, `Keep.set_start_tier(3)` on all four keeps |
| Player's unlocks | The whole kingdom: worker, both Halls' full cards (tier 1-3), the caster (B), the tier-3 unit (C), Revive <helper> (V), Lair Z / X / C (from 8:00), walls if the kingdom has them, the "+" pages; spells cap 8; items: base shop, Pell, caches |
| Crystals | Start 600; home 2 x 2 000, natural 2 500, Mouth 2 500 (Fourfold amounts); ~350 / min with 10-12 workers |
| Essence (by 26:00) | 150 + carried + trickle ~1 500 + kills ~1 800 (Host 15 / Warden, 30 / Sentinel) = **~4 000-5 000**: the first time a top item and a titan are both in reach |
| Expected player army | ~3 000 at 0:00 -> ~5 500 at 12:00 (+ a titan ~650-800) -> ~7 000 at 22:00 (cap 140) |
Champions: tavern hires as `champions.md`; the next hire costs the 2nd price (companion rule); bounties R on.

## 8. Dialogue (40 lines + the `<W>` sets; 5 s each unless listed)
Speaker ids (all in `data/voice/cast.json`): `narrator`, `vessa`, `malrik`, `torvald`, `ysolde`, `vey`, `obren`,
`master`, `pell`, `aldra`, `maelis`. Colours as `mission-e8-01.md`; Master `(0.95, 0.93, 0.85)`. **`<W>`** = a line spoken
by the player's wizard: four recordings, one plays (the column gives all four). Ally lines are spoken by that wizard
**only when they are an ally bot** (the player's own wizard never says another seat's line).
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Four kingdoms on one field, and every banner pointed the same way. It had never happened. |
| L2 | E1 | vey | Well. Look at the four of you. Thirty years I waited to see this, and it's ugly. I love it. |
| L3 | E1 | vessa | Fire takes the south-west. Or wherever I'm standing. I'm flexible. |
| L4 | E1 | torvald | Ice holds its bank. Malrik, if that stone so much as hums, I'm freezing your pocket. |
| L5 | E1 | malrik | Noted. Ysolde, try not to plant anything on my keyhole. |
| L5b | E1 | ysolde | No promises. Spring is busy. (3 s) |
| L6 | E2 | obren | Four of you. FOUR. I only needed one to come close. You brought me a feast. |
| L7 | E4 | vey | Gates on every road. He's been building while we argued. Mason to the end. |
| L8 | E5 | vey | The pylon's down! Now the Hollow knows your key is coming. Hold the ring! |
| L9 | E6 | `<W>` | Vessa: `My key's in. I waited for it, too. Who's next?` · Malrik: `The stone is in its lock. Not in my hand. Who's next?` · Torvald: `The orb is turned. Quickly. For me. Who's next?` · Ysolde: `The Signet is home. I'm still out here. Who's next?` |
| L10 | E7 Fire ally | vessa | They're all over my keyhole! I could use a hand. Or ten. |
| L11 | E7 Shadow ally | malrik | The Bishop requests assistance. Politely. Once. |
| L12 | E7 Ice ally | torvald | My line is bending. Help me hold it. I'm asking. Note that. |
| L13 | E7 Nature ally | ysolde | They're in my roots! Please. Now, not in a season. |
| L14 | E8 Fire | vessa | That's what friends are for. Apparently. Don't tell Malrik. |
| L15 | E8 Shadow | malrik | Hm. Help that arrives on time. Unsettling. Thank you. |
| L16 | E8 Ice | torvald | You came quickly. I'll try to learn how that's done. |
| L17 | E8 Nature | ysolde | You came. I always hoped someone would, when it was me. |
| L18 | E13 50 % | obren | Every one who falls is a step on my stair. Keep climbing for me. |
| L19 | E13 75 % | vey | Stop feeding it! Fight smart, or fight later. Later is worse. |
| L20 | E9 Fire | vessa | Marching now! Fire on the bridge. Somebody watch my back, I won't. |
| L21 | E9 Shadow | malrik | Shadow marches. The stone stays in my pocket. Mostly I'm telling myself. |
| L22 | E9 Ice | torvald | Ice is moving. I know. Write it down somewhere. |
| L23 | E9 Nature | ysolde | Nature marches out. Again. It's getting easier. |
| L24 | E10 Fire | vessa | Fire's key is in! Don't make me wait. I'm terrible at it. |
| L25 | E10 Shadow | malrik | Shadow's lock is turned. You may thank me in writing. |
| L26 | E10 Ice | torvald | Ice is set. That was quick, for me. |
| L27 | E10 Nature | ysolde | Nature's key is home. The roots are holding it. |
| L28 | E3, `m1_peddler_freed` | pell | Last stall before the end of the world! Again! I'm getting good at these. |
| L28b | E3, no flag | pell | Genuine relic polish! For your keys! Four keys, four customers, I can't lose. |
| L29 | E12 | malrik | Those are mine. Were mine. They followed the stone. They'll follow it into the ground. |
| L30 | E12 | vey | Renegades on the Shadow side! Whoever's nearest, lend the Bishop a blade. |
| L31 | E14 | obren | Too slow, all of you. I'm already climbing. (4 s) |
| L32 | E15 | vey | One gate less. Build something on the rubble. He'd hate that. |
| L33 | E17 | narrator | Four keyholes, four colours, one ring of light around the isle. |
| L34 | E17 | master | Now. All four of you. Turn them, and do not let go. (from below) |
| L35 | E17 | vessa | Master?! That's... that's him! Turn them! |
| L36 | E17 | malrik | Of course he waits until the last minute to speak. Family trait. |
| L37 | E17 | obren | You opened my door with your own hands. Thank you. Now I come up. |
| L38 | E17 | torvald | Then let him come. We are four. We hold. (and Ysolde, 2 s: `Together.`) |
| L39 | E18 | `<W>` | Vessa: `Not now... not when we're finally together...` · Malrik: `Of course. Just as it got interesting.` · Torvald: `Too late... again...` · Ysolde: `I came out... for this...` |
| L40 | E20 | vey | Your keep's burning! Pull back and hold it, then go again. |
Every line <= 96 characters and fits its slot at the cast speeds (`<W>` lines each). Echoes: L2 and L19 are Vey's
teacher voice; L4 and L21 keep the stone between Torvald and Malrik (Ep3-Ep7); L17 turns pro. S28; L25 and L36 are Malrik
as ever; L34 is the Master's first live line since ep1 V2 (the ending's "Now! All four! Together!" answers it).

## 9. Cinematic hooks (ENGINE on the live scene unless marked; skippable; units frozen while they play)
| id | When | Mode / length | Shots | Lines | End state (identical on skip) |
|---|---|---|---|---|---|
| `c_e8_muster` "Especially Malrik" | Before the briefing (StoryFlow, outline 3.8) | Stage film 1:20, set `forge_hollow_ridge` (the muster ridge = the `forge_hollow_pit` set's rim at dusk) | Beats for its writer (game-designer + four-wizards-high, cinematics.md format): 1) Vessa alone on the ridge, sitting on a rock, **waiting** (tapping her foot); if the player walked another road, that wizard walks up first and sits beside her; 2) Torvald and Aldra come up the north path; Ysolde and Wren, with Maelis, from the west; Vey leans on his sword; 3) Malrik arrives **last**, the stone pulsing amber in his fist; hands go to weapons; Vey: `He asked for all four of you. Especially Malrik.` Malrik: `I heard. I came. Don't make it a speech.`; 4) the four look down at Crown Hollow: four keyholes glowing on four banks; Vey: `Four keys, four keyholes. Each to your own. Together.`; title card `The Last Muster` | ~8 lines (`vey`, `malrik`, `vessa`, `torvald`, `ysolde`) | Story flow continues to the e8m2 briefing |
| `e8m2_seats` | E1 | HOLD 0:25 | 1) CRANE down over the isle crack at dusk; 2) four quick WS of the four seats, each army at its rally, its helper beside the wizard, its pylon glowing on its bank (2.5 s each); 3) MS the player's wizard, 3/4, the key relic glowing | L1-L5b | RTS camera on the player's wizard; clock at 0:00 |
| `e8m2_hand` | E14 | PAUSE 0:10 | 1) WIDE: the isle splits; 2) LOW: a hand of fused pillar-stone, 9 m, claws up out of the crack and grips the rim | L31 | The hand prop at `(0, 0)` (r 4 obstacle, navmesh rebake), tides +50 %, flag set |
| `e8m2_turn` | E17 | PAUSE 0:40 | 1) TOP-DOWN, crane up: four keyholes on a ring, four pillars of colour (red, violet, blue, green); 2) four CU inserts, each wizard's hand turning its relic (2.5 s each); 3) LOW at the crack: white-gold light far below, answering; 4) WS: the isle caves in, the Hollow Throne rising out of the dust on a body of rubble, chains of amber light snapping from the four keyholes to its limbs; FADE_BLACK | L33-L38 | Mission won; save (section 10); StoryFlow -> `e8m3` (`e8m3_king` opens it) |
Fallbacks: missing marks or VFX -> the camera on the player's wizard and the lines as dialogue; `c_e8_muster` missing ->
its 8 lines as a dialogue card over the e8m2 briefing.

## 10. Win / lose and rewards
| Event | Result |
|---|---|
| 4 keyholes lit | **Victory** (after `e8m2_turn`) |
| Player's wizard dies | **Defeat** (instant) |
| Player's keep destroyed | **Defeat** |
| An allied wizard kneels / an allied keep at 20 % | Nothing (D5); Hollow +3 % for a kneel |
| Hollow 100 % | Not a defeat: the Early Rise (E14) |
| All the player's soldiers dead, wizard and keep alive | Nothing |
Rewards: the track (6 slots, key relic, slot 2, essence 50 % cap 1 500 after bonuses, companion: the champion rule again)
for e8m3. `MISSION_REWARDS[&"e8m2"] = {"flags": {"e8m2_helped_all": "sec_help", "e8m2_hollow_low": "sec_hollow",
"e8m2_gate_broken": "sec_gate"}, "bonus_essence": {"sec_help": 300, "sec_hollow": 300, "sec_gate": 150}, "next":
&"e8m3"}`; mission-computed `e8m2_early_rise` (bool), `e8m2_hollow_peak` (int %), `e8m2_time`. e8m3 hooks: `e8m2_early_rise`
= King +10 % HP; `e8m2_helped_all` = every ally keyhole starts phase 1 at 100 % HP (else 85 %).

## 11. Difficulty and sizing
| | Easy | Normal | Hard |
|---|---|---|---|
| Host counts | x 0.6 | as written | x 1.4 |
| Muster times (A2 / B1 / B2) | 13 / 16 / 19:00 | 16 / 20 / 24:00 | 18 / 23 / 28:00 |
| Help values | kills +3 %, ping +15 % | +2 % / +10 % | +1.5 % / +8 % |
| Hollow per death | +0.35 % | +0.5 % | +0.6 % |
| Pylon HP | 1 100 | 1 400 | 1 700 |
| Start crystals | 800 | 600 | 450 |
| Expected time | 21-25 min | 25-30 min | 29-35 min |
Fight sizing (normal; every fight the player must take <= 70 % of their own army then; allies are not counted unless the
fight is in their quarter):
| Fight | When | Enemy (value) | Player then | Ratio |
|---|---|---|---|---|
| Crack tide on A1 (1st) | 1:30 | 6 Wardens = 900 | 3 000 + wizard L6 + helper | 30 % (must leave **28+ of 32-37** start soldiers) |
| A1 pylon + 6 guards | ~6:00-9:00 | 1 400 HP + 900 | ~4 200 | 21-35 % |
| Keyhole Rush + a Crack tide | ~7:00-10:00 | 2 000 + ~1 600 | ~4 600 | 43-78 % if both meet: break the pylon **between** Crack tides on A1 (the panel shows the next tide's target and time) |
| Help in A2's quarter (Gate + Crack tide) | ~10:00 | ~2 100 | ~5 000, with A2's ~3 500 | 42 % alone, ~25 % together |
| Stone-sworn column | 12:00 | ~2 400 | the Shadow seat (+ the nearest helper) | Ally fight; if the player is Shadow: ~48 % |
| Crossing to B1 / B2 by the isle | ~14:00-20:00 | Crack tide 9-12 Wardens + 1-2 Sentinels = 1 750-2 600 | ~5 500 + titan | 32-47 % |
Expected run on normal: own pylon ~7:00-9:00 -> own key ~9:00-11:00 -> help A2 (bar ~70 % at 11:00) -> A2 marches
~12:30-13:30 -> titan at 8:00+ -> cross the isle to B2 or B1 (~15:00-18:00) -> B1 ~17:00 -> B2 ~20:00-22:00 -> march and
channel ~2:00 -> `e8m2_turn` -> **~24-27 min**, 30 with retakes.
- The muster is a choice of where to fight: the player who only defends their own bank sees the last key at ~26:00 and
  the Hollow higher; the player who fights in the others' quarters ends ~21:00-24:00 with `sec_help`.
- Watch in the first playtest: if the isle shortcut makes B1 / B2 too easy, add 1 Sentinel to Crack tides aimed at B1 /
  B2; if the bots' marches fail more than once on normal, raise their march retreat threshold to 20 %.

## 12. Acceptance checks
- A scripted headless run on normal (own key, help A2 with kills, answer one ping per ally, cross the isle, wait for B2)
  ends `victory=true` in **25-30 game-minutes** in 3 / 3 runs, for each of the four player kingdoms (seat table 2.1).
- `Teams.configure` puts all four seats on side 0: no seat's unit, tower or splash ever damages another seat's; shared
  fog; the Host (NEUTRAL) attacks all four; all three bots draw as allies.
- Keyhole rules: only the seat's own wizard can channel; the ring is red with a Warden at 7.9 m and works at 8.1 m;
  a lit Key-Ward never drops below 1 HP; the A1 pylon's death spawns the Keyhole Rush exactly once.
- Muster: with no help, A2 / B1 / B2 march at 16:00 / 20:00 / 24:00 (+- 1 s); 10 Host kills by the player within 30 m of
  A2's keep add 20 %; an answered ping adds 10 % (max 3); a failed march resets to 60 %; each march brings one titan.
- Allied wizards never die (kneel 10 s, stand at 50 %); allied keeps stop at 20 % HP; the player's keep and wizard can
  be lost.
- Hollow: +0.5 % per seat death, 0 for Host; 100 % fires the Early Rise once and sets `e8m2_early_rise`.
- Every cutscene end state equals its skip; every line fits its slot; `PERF OK` with 4 x 40-pop armies, 4 titans, 4
  helpers, 4 pylons, 4 gates and ~60 Host units on the 168 m map.

## 13. Implementation tasks (proposed ids; the lead adds them to `waves.md`)
- [ ] **E8M2.S1** (systems): `missions/mission_e8_02.tscn` + `MissionE802` on Fourfold Hollow; seat table 2.1 from
  `ep8_road`; `Teams.configure` all side 0; four Citadels, Halls, towers, 3 houses, pre-built Lairs; start armies 3.1;
  helpers on the field; keyholes + pylons, Throne Crack, 4 Hollow Gates, Pell; the flag bonuses of 3.2; the no-save
  fallback. Test `tests/test_e8m2_s1.gd`: positions +- 0.5 m, clearances of 2.2, all four keeps at tier 3, no hostility
  between seats.
- [ ] **E8M2.S2** (systems-high [H]): keyhole channel / Key-Ward (seat-bound, 8 m block, HP floor 1), Host sources of
  4.2 (rotation, scaling, Keyhole Rush, march pressure, Stone-sworn column), the Muster bars (time, kills, pings, march,
  failure), the Hollow meter + Early Rise, allied safety (kneel, keep floor), objectives E1-E20, rewards; test
  `tests/test_e8m2_s2.gd` for section 12's numbers.
- [ ] **E8M2.A1** (ai-high [H]): profile `mission_e8` (6.1), the muster push, the march, retreat, return, neighbour help,
  pings to the player and answers to the player's pings (6.4); the Commander ignores `"scripted"` units; three
  Commanders for ALLY / ENEMY / ENEMY_2 slots on side 0.
- [ ] **E8M2.G1** (gameplay): allied wizard kneel rule (`Wizard.set_kneel_instead_of_death(true)`), the keep HP floor
  hook (`Building.set_hp_floor(pct)`), free titan spawn at a keep (pop 0); test.
- [ ] **E8M2.U1** (ui): the three Muster bars (ally colour, wizard icon, ETA), the four-key counter, Hollow line with
  stages, the "next Crack tide: <seat> in 0:40" line, ally Help pings answered feedback (`+10 % Malrik musters`), keyhole
  rings with seat colour / icon; `<W>` line routing in DialogueBox; briefing; layout by ui-designer (`ui-2v2.md` frame).
- [ ] **E8M2.V1** (tech-artist): keyhole ring + Key-Ward pillar in four colours; the Hollow Gate on a lair spot; the
  King's hand prop (9 m, from the e8m3 King's arm, F4 of the outline); isle crack stages; dusk-to-storm light; Art Lab.
- [ ] **E8M2.C1** (four-wizards-high, after 19.C1 / 19.C2): `e8m2_seats`, `e8m2_hand`, `e8m2_turn`; `c_e8_muster`
  stage film (script by E8M2.D1, set `forge_hollow_ridge` = the F2 pit set's rim) and StoryFlow road -> muster ->
  briefing -> e8m2 -> e8m3.
- [ ] **E8M2.VO** (Voice Forge agent): 40 lines + 8 `<W>` variants (`data/voice/lines/e8m2.json`), plus `c_e8_muster`'s.
- [ ] **E8M2.D1** (game-designer): `c_e8_muster` script (1:20, the four beats above, `episode2-opening.md` format); read
  the lines in game once.
- [ ] **Lead**: the four kingdom runs and section 12.

Dependencies: step 20 (2v2 seats, `Teams`, frames, AllyChannel, 20.A* ally layer), step 13 / 13c (Lairs, titans), TH
(helpers), 19.C6 (pylon, Warden Gate), 19.C1 / C2 (cutscenes), `mission-e8-01.md` E8M1.G1 (Host types).

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** the kingdom's T2 heavy rider: Pyrehoof Lancer / Barrow Knight / Rimehorn Rider / Thornback Charger (spec change: the unlocks list the Stables).
- **Why here:** a key-bearer escort over a 168 m map against Warden infantry lines; Lab after the 2026-10-06 pass 55-65 / 70-74 (fair, still strong).
- **Moment:** the Keyhole Rush: "Heavy riders: break the Rush before it reaches the keyhole.".
- **Intro card:** `Pyrehoof Lancer. A boar and a lance: lines break where it hits.` (Fire; the other kingdoms' lines: `unit-spotlights.md` 2.8)

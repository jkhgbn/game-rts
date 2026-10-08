# Campaign mission e7m3: "The Outwall" (Torvald + Aldra; Episode 7)

Written 2026-10-02 (`campaign-outline.md` 3.7 row 3). Episode 7 "Gold for Fire", mission 3 of 4. One night in Adamarch's
**Outwall**, the poor harbour quarter outside the white wall whose dockers, fishers and rowers keep the Diamond City
running and may never live inside it (e7o 2). Three raiders come for the dockers: Aurivane's landing boats, Adamarch's own
press-gangs, and masked raiders out of the old diamond adit who turn out to be **Malrik's**. The Diamond Archon orders
Torvald to guard her pits instead. The mission is a choice the player makes with the army's feet: **the people or the
pits** (the canon answer is the people; both win). It also gives the **War Mammoths** (the Ice titan). Target **20-25 min**
on normal. Rules and format of `mission-e7-01.md` / `mission-e7-02.md` (read them first), `mission-e2-01.md` (walking
survivors), `t3-helpers.md` 4.4 (Aldra), `cavalry-mounts.md` (War Mammoth numbers). New map, new scene
`missions/mission_e7_03.tscn` + `scripts/campaign/mission_e7_03.gd` (`MissionE7_03 extends MissionBase`, id `e7m3`).
Metres, seconds, `m:ss`; positions `(x, z)`, `+z` = south (the sea). Status: **design only**. Recommended option taken
everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | Map | **New story map `data/maps/adamarch_outwall.map`** (task **E7.M2**), 140 x 110, `symmetry=none`, authored from the table below (no generator seed for the layout; trees none, rocks only on the headland). It continues `forge_adamarch` (e7o 5.4): the white wall, the headland pits, the round harbour off-map east | The Outwall is a place the films show but the strait map has only as one node; a quarter of shanties, piers and pits needs its own ground |
| D2 | The choice | **Not a menu.** At 9:00 the Diamond Archon orders the pits held; at the Night Tide (17:00) the pits (east) and the returning fishing crews (south) are attacked **at the same moment**, 45-60 m apart. Two secondaries record what the player saved: `sec_people` (>= 30 of 40 sheltered) and `sec_pits` (3 pit heads held at dawn). Both can be won by a very strong player; the mission is won either way | The prologue's Torvald weakness ("he waits too long") becomes a clock; a scripted dialogue choice would be weaker than a choice of where the army stands. campaign-outline: "choose the people over the diamond pits" = the canon flag, not a forced outcome |
| D3 | Tier and helper | Start **at the Citadel** with **Aldra already called** (helper alive, Escort); Shardguard on the keep card; no Stronghold / Citadel button | Mission 3 of the episode: the Citadel was opened in e7m2 (campaign-outline D7 asks only that it opens in mission 2) and the night starts at once |
| D4 | Enemy bases | **None.** No enemy wizard on the field. Every enemy is a scripted raid: Aurivane landings (Fire mercenaries + Gilded Spears) from the sea, **masked raiders** (Shadow units, D5) from the adit, and Adamarch's **press-gangs** (non-violent, 6.2) from the Wall Gate | A defence-and-escort night; no base to kill keeps the choice the only question |
| D5 | Malrik's masks | Real Shadow units (Shades, Grave Hounds, Nightbolts, Barrow Ghouls, Hexweavers, a Shadow Knight) shown as **`Masked raiders`** (grey cloth, a plain grey half-mask, the team colour hidden: modifier `masked`); their leader is the **Mask Captain** (6.4). Killing him reveals the violet under the grey | Malrik's stolen Outwall coin (e7m1 L21) and his rowers for e7m4 both come from here; the reveal is the player's, and earned |
| D6 | War Mammoths | **2 War Mammoths** (`war_mammoth`, `cavalry-mounts.md` numbers: 2 000 HP, armor 30, tusks 40 / 2.4 m / 2.2 s + howdah archer, 3.4 m/s) chained at the pits' Hauling Yard; Torvald frees them (channel) and they join (team PLAYER, commandable, **pop 0** this mission). No Lair, no training | The outline's titan for e7m3; freeing the pits' beasts is the people-first act in the pits' own yard |
| D7 | Gold | `trade_enabled = true` for the GoldBank and the Bazaar (pre-built), **no caravans, no posts** (the quays burn tonight). Gold comes only from the **diamond tithe** (6.3) | Gold for Fire, turned around: the pits pay, the people do not. The player feels the price of the canon choice in wares |
| D8 | Seraphine | Arrives at **17:00** at the Low Quay with 4 Facetguards who **refuse** the Archon's order and fight for the dockers (story allies, kneel rule) | Her honour (e7o 3.1) against her own city's pride; she is the voice of the choice, not Torvald's |
| D9 | The Outwall girl | At dusk a small girl with a lantern (no line, `outwall_girl` NPC) runs ahead of the Tar Steps crew and rings that bell herself; she is the **child of `ep8_ending` E23** (campaign-outline 4.4: "a child from the Outwall") | A two-second seed for the last scene of the game |

## Story setup (briefing text, 3 short paragraphs)
1. Adamarch admits nobody who has not paid in gold and proved it in blood. Everyone else lives outside the white wall, in
   the Outwall: dockers, net-menders, rowers, the hands that make the Diamond City rich. Tonight nobody is guarding them.
2. Aurivane's boats are landing raiders on the quays. Adamarch's own press-gangs are emptying the lanes to dig the pits
   deeper. And masked men come out of the old diamond adit and take people into the dark.
3. Torvald camps against the wall with Aldra and what is left of his army. The Diamond Archon will send her orders soon.
   He already knows what she will ask. He does not yet know what he will answer.
Briefing objectives: `obj_bells`, `obj_dawn` (shown from the start as `Hold the Outwall until dawn`), the rules `Torvald
must survive` and `Do not lose 30 of the Outwall's 40 people`, and the line `Ring a Dock Bell and its lane follows you to the
shelter by your Keep.`

## Map: "The Outwall" (140 x 110, `data/maps/adamarch_outwall.map`, not mirrored)
Playable bounds x -68..68, z -53..53 (camera bounds 3 m inside). The white wall of Adamarch (impassable, 9 m, white marble on
black basalt) closes the north; the sea closes the south; the headland and its pits close the east; the west edge is the
Rope-walk and the saltworks. Clearings: no prop or rock inside the listed radius.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| **The White Wall** | Wall block from `(-70, -46)` to `(34, -46)`, 6 m thick, then bending north-east to `(40, -55)` | - | Decor + navigation obstacle; `forge_adamarch`'s `wall white` |
| **Wall Gate** (press-gangs) | `(-4, -46)`; spawn `(-4, -50)` | 5 | Opens for Facetguards only |
| `PLAYER_START` (Torvald) / Aldra | `(-46, -28)` / `(-48, -30)` | 5 | |
| **Rime Keep "the Glass Hall"** (player, **Citadel**) | `(-54, -36)` | 14 | 4 200 HP. **The shelter**: a docker within **10 m** of it walks in (counts sheltered) |
| Frost Hall (pre-built) / Snow Lodge x2 (pre-built) / Frost Bazaar (pre-built) | `(-62, -22)` / `(-42, -42)`, `(-64, -30)` / `(-44, -18)` | - | Bazaar 15 m from the keep |
| Nodes `e7m3_rope_a` / `e7m3_rope_b` | `(-64, -44)` / `(-40, -32)` | - | **1 500** each |
| Node `e7m3_saltworks` (expansion) | `(-58, 6)` | 7 | **2 000**; hall spot `(-50, 8)`; 24 m from the West Beach landing |
| **R1 Rope Row** (8 dockers + bell) | `(-30, -18)` | 6 | 26 m from the keep |
| **R2 Net Lane** (8 + bell; **Brannet**) | `(-14, -8)` | 6 | 47 m |
| **R3 Saltpan Court** (8 + bell) | `(12, -24)` | 6 | 67 m; nearest row to the adit and the pits |
| **R4 Low Quay** (8 fishers, home at dusk) | `(-28, 26)`; pier `(-28, 36)-(-28, 50)` | 6 | 65 m |
| **R5 Tar Steps** (8 fishers, home at dusk; the girl) | `(14, 26)`; pier `(14, 36)-(14, 50)` | 6 | 90 m |
| Shoreline / sea | Water south of `z = 38` (piers excepted) | - | `RiverSystem.setup` with one shore polyline as a "sea" (deep water, no ford), map-fill 11 |
| Landing points | **L1 West Beach** `(-56, 34)`, **L2 Low Quay pier head** `(-28, 36)`, **L3 Tar Steps pier head** `(14, 36)` | 5 | Aurivane boats beach here (decor boat + spawn) |
| **Pit head P1 "North Cut"** | `(46, -30)` | 6 | Diamond tithe point (6.3) |
| **Pit head P2 "Glitter Shaft"** | `(58, -10)` | 6 | 6.3 |
| **Pit head P3 "Sea Cut"** | `(48, 14)` | 6 | 6.3 |
| **Hauling Yard** (2 chained War Mammoths) | `(60, -36)`; chain post `(56, -38)` | 8 | D6 |
| **Old adit** (masks spawn) | `(66, -48)` | 5 | Also where carried dockers are taken (6.1) |
| Pit tunnel mouth (masks spawn 2) | `(68, 4)` | 4 | |
| Headland rocks | `x > 36`, scattered, seed 73 | - | Cover; the pits' terraces (`forge_adamarch` crystal-node look as decor) |
| Player rally | `(-36, -24)` | - | |
Distances (path): keep -> R1 26 m, R2 46 m, R3 66 m, R4 66 m, R5 91 m; keep -> P1 101 m, P2 116 m, P3 112 m; R5 -> P3 34 m;
R3 -> P1 35 m; R4 -> R5 42 m; P1 -> Hauling Yard 15 m. The pits are **45-60 m** from the south rows: one army cannot cover
both in the Night Tide (D2).

**Look** (E7M3.V1): dusk at 0:00 turning to full night at 17:00 and a grey-gold dawn at 22:00 (light ramp keyed to the mission
clock); the white wall glows faintly (moonlit marble), the Outwall is lanterns, tar, nets and patched sails; the pits are lit
by the diamond glints (emissive specks) and the masks' grey torches; Aurivane boats carry crimson lanterns. 0 lights: all
emission.

## Start state (Torvald's track)
| Item | Value |
|---|---|
| Torvald | **Level 5** with **4 unspent points** (Rime Bolt r1 known), cap 8; Splinter + the 6 slots from the save |
| Crystals / essence / gold | **400** / **150 + carried** / **0** |
| Buildings | Rime Keep at the **Citadel** (`Keep.set_start_tier(3)`, 4 200 HP), Frost Hall, 2 Snow Lodges, Frost Bazaar |
| Units | 6 Rime Haulers (3 / 3); **6 Rimeshields + 4 Shardcasters + 2 Rime Seers + 1 Rimecarver + 2 Shardguards** at the rally (1 880 crystals); **Aldra** (helper, L5, Escort) |
| Population | 6 + 6 + 4 + 2 + 2 + 6 + Aldra 4 = **30 / 60** (keep 20 + 2 Lodges 40; Lodges max 4) |
| Story NPCs | **Brannet Coil**, foreman of the dockers, in R2 (`brannet_story`, invulnerable, follows the R2 crew once its bell rings); the girl (dusk, D9) |
| No save | Splinter, empty slots, essence 150 + 500 |

## Unlocks
| Kind | Available | Locked |
|---|---|---|
| Buildings | Snow Lodge, Frost Hall, Rime Spire, Ice Wall (max 16) | Bazaar is pre-built (max 1); Stables, Lair, research |
| Units | Rime Hauler; Frost Hall Z X C V N M `,`; keep **C Shardguard**, **B Rimecarver**; **War Mammoths** only by freeing them (D6) | Caravans (no posts), Frostbow, Rimehorn Rider, trained titans |
| Keep | - (Citadel already) | - |
| Helper | Aldra on the field; revive at the skirmish price (120 + 20 x level essence) | - |
| Gold | Wares, the exchange | Caravans, bids |

## The people (escort rules; systems + gameplay)
### 6.1 Dockers, bells and the shelter
| Rule | Value |
|---|---|
| Dockers | `outwall_docker` (new UnitType): team PLAYER, `commandable = false`, 45 HP, armor 0, 4.2 m/s, pop 0, no attack, kill_xp 15 for the killer. **Hidden** inside their row (untargetable) until their bell rings or their row is **taken** |
| Dock Bell | One per row (a bell on a frame, 2.4 m). **Ring** = Torvald within **3 m for 3 s** (the brazier channel; leaving resets, damage does not; refused while an enemy is within 8 m: `The lane won't open its doors with raiders in the street`). R4 / R5 bells only from dusk (16:30, 6.5) |
| After the bell | The 8 dockers come out and walk to the keep (navmesh path, 4.2 m/s); within 10 m of the keep they walk in: **sheltered** (removed, counter +1). Raiders target walking dockers first (they are the prize) |
| A row **taken** | If enemies stand within 8 m of a row's bell for **20 s** with no side-0 unit within 8 m (any time before its bell rings): **Aurivane** raiders **burn** it (its unsheltered dockers are lost: dead); **masks** **seize** it (its dockers come out and are led to the adit at 4.0 m/s by the masks: kill the escorting masks within 8 m to free them: they turn and walk to the keep). A docker reaching the adit is **lost** |
| **Press-gang** (6.2) | Takes a row the third way: its dockers are **pressed** (walked to the Wall Gate and gone through it: alive, not lost, not sheltered) |
| Counters | `sheltered`, `lost`, `pressed`; 40 in total. **Lost >= 30 = defeat** (E21) |
### 6.2 Adamarch's press-gangs (non-violent)
A press-gang is 4 **Facetguards** (team PLAYER-allied, `commandable = false`, not attackable by side 0, never attack). It walks
from the Wall Gate to its target row; arriving, if **no side-0 soldier or Torvald is within 8 m of the row's bell**, it
presses the row (dockers walk to the gate with it). If one is, the gang's sergeant argues for 5 s (line on the first time:
L7) and the gang walks back through the gate. A gang never targets a row whose bell has rung. Schedule (normal): PG1 4:00
R1, PG2 8:00 R2, PG3 11:00 R3 (each only if the row still holds dockers). After **E6** (the Archon's order), any gang whose
target row is within 8 m of an Ice soldier also costs the player **-1 pit tithe minute** ("Her Radiance notes your
interference"): a deliberate sting, flavour for the pits path.
### 6.3 The diamond tithe (gold; from E6, 9:00)
A pit head is **held** while a side-0 unit stands within 6 m and no enemy does. Each held pit head pays **+40 gold / min**
(every 15 s). `sec_pits` = all 3 held at the moment of dawn. Expected: a player who stands on the pits from 9:00 to 22:00
earns ~**1 500 gold** (wares 350 each, exchange 100 -> 80 crystals / 40 essence). A player who never does earns **0** gold.
### 6.4 The masks and the Mask Captain
Masked raiders (D5) use their Shadow unit stats unchanged plus modifier `masked` (look only). The **Mask Captain**
(`mask_captain`, NT2): a Hollow Oathsworn with boss numbers: **900 HP**, armor 15, 30 damage / 1.2 s, 4.6 m/s; **Hook Chain**
(cd 12): pulls a docker or a soldier within 9 m to him; **Grey Veil** (cd 20): smoke r 4, his masks inside take -30 % from
ranged. Killed: cutscene `e7m3_unmask` (his grey half-mask cracks: violet cloth and Malrik's candle sigil underneath),
`sec_mask` done. He never retreats.
### 6.5 Dusk: the fishing crews
At **16:30** two fishing boats come in to the Low Quay and Tar Steps piers (decor boats). 8 fishers walk off each pier into
R4 / R5 (visible, **targetable**, standing at their row) and wait for their bell. The girl (D9) runs ahead of the Tar Steps
crew: if Torvald comes within **15 m** of R5's bell, the girl rings it herself at once (no channel; the R5 crew walks).
### 6.6 The War Mammoths (D6)
Chained at the Hauling Yard `(60, -36)` under a guard (G2). **Free** = Torvald within 3 m of the chain post `(56, -38)` for
**4 s** (enemy-within-8 m refusal). Both mammoths join at once (team PLAYER, commandable, pop 0, full HP); `sec_mammoths`
done; the Archon's line (L13). They are carried to e7m4 as story units (Reward).

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_bells` | Primary | `Ring the Dock Bells (0 / 5)` + counters `Sheltered 0 · Lost 0 · Pressed 0 (of 40)` | 5 bells rung (any order; R4 / R5 from 16:30); never fails on its own |
| `obj_dawn` | Primary, always shown | `Hold the Outwall until dawn (22:00)` (the clock) | 22:00 game time |
| `obj_people` | Primary rule, always shown | `Do not lose 30 of the Outwall's 40 people (lost 0)` | Fails at lost >= 30 = defeat |
| `obj_torvald` | Primary, always shown | `Torvald must survive` | Fails = defeat |
| `sec_people` | Secondary | `Shelter 30 of the Outwall's people` | >= 30 sheltered at dawn |
| `sec_pits` | Secondary (appears at E6, 9:00) | `Hold the Diamond Archon's pits at dawn (0 / 3)` | All 3 pit heads held at 22:00 |
| `sec_mammoths` | Secondary | `Free the hauling mammoths` | 6.6 |
| `sec_mask` | Secondary (appears at E12) | `Unmask the Mask Captain` | He dies |
Both `sec_people` and `sec_pits` can be done; the panel shows them side by side from 9:00 so the choice reads at a glance.

## Waves (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted, team ENEMY (masks and Aurivane) or PLAYER-allied (press-gangs), group `"scripted"`. Landing waves arrive by boat
(a 6 s beaching, then they step off). Masks spawn at the adit or the tunnel mouth. Every raiding wave's order: **the nearest
walking docker within 20 m, else the nearest row that still holds dockers, else the listed target**, refreshed every 3 s.
| Group | Where | Units | Value |
|---|---|---|---|
| G1 adit watch | Old adit `(64, -44)` | 3 masked Shades + 2 masked Nightbolts (leash 2x) | 440 |
| G2 yard guard | Hauling Yard `(58, -36)` | 4 masked Shades + 1 masked Shadow Knight + 2 masked Grave Hounds | 760 |

| Wave | Trigger | Units (spawn) | Default target |
|---|---|---|---|
| LA1 | **2:30** | 3 Flame Guards + 2 Gilded Spears (L2) | Rows, else the Frost Hall |
| PG1 | **4:00** | Press-gang (4 Facetguards) | R1 |
| MK1 | **5:30** | 4 Shades + 2 Grave Hounds, masked (adit) | R3 |
| LA2 | **7:30** | 4 Flame Guards + 3 Ember Archers + 2 Gilded Spears (L1) | Rows, else the Saltworks Haulers |
| PG2 | **8:00** | Press-gang | R2 |
| MK2 | **10:00** | 5 Shades + 2 Nightbolts + 2 Barrow Ghouls, masked (tunnel) | **P2**, then R3 |
| PG3 | **11:00** | Press-gang | R3 |
| LA3 | **12:30** | 5 Flame Guards + 3 Ember Archers + 1 Pyre Adept + 3 Gilded Spears (L3) | Rows, else the Rime Keep |
| MK3 | **14:00** | 4 Shades + 3 Grave Hounds + 2 Nightbolts, masked (adit) | **P1**, then R2 |
| **NT1 Night Tide (south)** | **17:00** | 6 Flame Guards + 4 Ember Archers + 2 Cinder Arbalests + 4 Gilded Spears (L2 and L3, half each) | The R4 / R5 fishers |
| **NT1 Night Tide (east)** | **17:00** | 6 Shades + 3 Nightbolts + 1 Shadow Knight, masked (adit + tunnel) | **P1, P2**, then R3 |
| **NT2** | **18:30** | **Mask Captain** + 4 Shades + 2 Hexweavers + 2 Grave Hounds, masked (adit) | **P1**, then the nearest row, then the keep |
| **NT3** | **20:00** | South: 6 Flame Guards + 4 Ember Archers + 2 Pyre Adepts + 1 Kilnwarden + 4 Gilded Spears (L1 and L2); east: 4 Shades + 2 Nightbolts + 2 Barrow Ghouls, masked (tunnel) | South: rows, else the keep; east: **P3** |
| Dawn | **22:00** | Every living raider walks back to its boat / adit and despawns | - |
If `sec_mask` is done before NT3, NT3's east half loses 40 % (rounded down). If the mammoths are free, NT1 east gains 1
masked Shadow Knight (the masks want their beasts back). The pits waves (MK2, MK3, NT1 east, NT2, NT3 east) attack pit
heads only to **deny the tithe**; masks never burn rows, they seize them (6.1).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cinematic `e7m3_outwall` (HOLD 0:15); L1-L4; hint `Ring a Dock Bell: hold Torvald beside it (3 s). Its lane walks to the shelter by your Keep. Raiders hunt anyone walking.` (10 s) |
| E2 | First bell rung | L5; counters appear |
| E3 | LA1 (2:30) | L6 (Aldra) |
| E4 | PG1 arrives and is turned back by a soldier (first time) | L7 (Brannet comments; the sergeant's argument is a 5 s speech bubble, no voice); if instead the row is pressed: E20 |
| E5 | MK1 (5:30) | L8; message `Masked men out of the old adit` |
| E6 | **9:00** | The Archon's order: L9-L10; `sec_pits` active; pit heads show the tithe ring (gold), +40 gold / min each when held; L11 (Torvald) |
| E7 | First tithe paid | L12 (Aldra) |
| E8 | Mammoths freed | L13-L14; `sec_mammoths` done |
| E9 | R2 bell rung | L15 (Brannet) |
| E10 | **16:30** dusk | Cinematic `e7m3_boats` (HOLD 0:08): the two fishing boats, the girl; L16; message `The fishing crews are home. The Night Tide comes at 17:00.` |
| E11 | **17:00** NT1 | Seraphine + 4 Facetguards arrive at the Low Quay `(-28, 30)` (story allies); L17-L18; `obj_dawn` countdown 5:00 |
| E12 | **18:30** NT2 | L19; `sec_mask` active |
| E13 | Mask Captain dies | Cinematic `e7m3_unmask` (PAUSE 0:12): L20-L21; `sec_mask` done |
| E14 | **20:00** NT3 | L22 (Ossavar) |
| E15 | Lost reaches 20 (first time) | L23 (Brannet), warning message `The Outwall is emptying: 10 more lost and the night is lost` |
| E16 | All 5 bells rung | L24 |
| E17 | **22:00** dawn | Raiders withdraw; cinematic `e7m3_dawn` (PAUSE 0:30): lines by outcome (L25-L29); `Events.mission_ended(true)` at its end |
| E18 | Torvald dies | L30; defeat after 3 s |
| E19 | Rime Keep destroyed | Defeat after 3 s (no line) |
| E20 | A pressed row (first time) | L7b |
| E21 | Lost >= 30 | L31; defeat after 3 s |

## Dialogue (32 lines; 5 s each unless listed)
Speakers: `torvald`, `aldra`, `seraphine`, `ossavar` (exist or added by E7M1.O1); **new for the voice cast**:
**`brannet`** (Brannet Coil, foreman of the Outwall dockers) and **`diamond_archon`** (the Diamond Archon of Adamarch).
Proposed voices (audition first, `run_voice_forge.ps1 audition only=<id>`):
| Speaker | Who | Proposed voice | Speed | Alternatives | Notes |
|---|---|---|---|---|---|
| `brannet` **new** | Brannet Coil, foreman, fifties, rope-scarred hands | `{am_echo 0.6, am_adam 0.4}` | 1.05 | `am_eric` 1.05 · `{am_fenrir 0.5, am_echo 0.5}` 1.0 | Southern cities speak American (e7o 4.3); warm, rough, quick. Not Ashby (am_eric pure) |
| `diamond_archon` **new** | The Diamond Archon, chosen for life by the Hall of Silence | `{bf_isabella 0.5, af_kore 0.5}` | 0.88 | `af_kore` 0.88 · `{af_river 0.3, bf_isabella 0.7}` 0.88 | Cold, exact, never raises her voice; distinct from Maelis (bf_isabella pure), Seraphine (river / aoede), Hush (alloy) |
Colours: Brannet **new** `(0.75, 0.62, 0.45)`, Diamond Archon **new** `(0.92, 0.94, 1.00)`; others as e7m1. Names shown:
`Brannet`, `The Diamond Archon`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | ossavar | The Outwall. Where the coin is earned, and never spent. |
| L2 | E1 | brannet | You're the ice-king? We've had kings before. They stand on the wall and watch. |
| L3 | E1 | torvald | Then I will stand down here. Ring your bells when I tell you, and bring your people to me. |
| L4 | E1 | aldra | The Glass Hall is open, my lord. It holds more than you think. Winter is roomy. |
| L5 | E2 | brannet | Rope Row's coming. Mind the old ones, they walk slow. Like you, no offence. |
| L6 | E3 | aldra | Crimson lanterns on the water. Aurivane burns what it cannot buy. |
| L7 | E4 | brannet | Facetguards, turned back by an ice-king. I'll be telling that one in the tavern for years. |
| L7b | E20 | brannet | The Archon's press took a whole lane. They'll dig till they drop, and nobody'll count them. |
| L8 | E5 | aldra | Men in grey masks, out of the old adit. They do not take coin. They take people. |
| L9 | E6 | diamond_archon | Ice-king. Adamarch did not open its harbour to you so you could herd fishermen. |
| L10 | E6 | diamond_archon | Guard my pits. The diamonds pay for your dragons. The Outwall can look after itself. |
| L11 | E6 | torvald | It has been looking after itself for a thousand years, Your Radiance. Look where it got them. |
| L12 | E7 | aldra | Diamond tithe. Every minute you stand there, my lord, the Archon pays. Every minute. |
| L13 | E8 | diamond_archon | Those beasts are the property of the Diamond Hall. You will answer for them. |
| L14 | E8 | torvald | Then I will answer for them. They will answer to nobody. |
| L15 | E9 | brannet | Net Lane, out! Follow the cold, it's the only thing tonight that isn't lying to us. |
| L16 | E10 | brannet | The boats are in. Two crews, sixteen souls, and the whole night coming for them. |
| L17 | E11 | seraphine | The Archon forbade this. The Hall of Silence can fine me. These are Adamarch's people too. |
| L18 | E11 | torvald | Pits to the east, fishers to the south. Aldra, I cannot stand in two places. |
| L19 | E12 | aldra | Their captain comes himself. Break his mask, my lord. I want to see what is under it. |
| L20 | E13 | torvald | Violet. And a candle sigil. Malrik, you are taking rowers from the gutter now. |
| L21 | E13 | aldra | His gift at the auction was their wages. Tonight he came back for the men. |
| L22 | E14 | ossavar | The last tide, Ice-king. The cities always send the biggest boats just before morning. (6 s) |
| L23 | E15 | brannet | Half the Outwall gone! Ice-king, whatever you're guarding, it isn't us! |
| L24 | E16 | brannet | Every bell's rung. I never heard all five at once. Sounds like a festival. |
| L25 | E17 (>= 30 sheltered) | brannet | Dawn, and the Outwall's still here. Nobody on the wall will ever thank you. So: thank you. |
| L26 | E17 (pits held) | diamond_archon | The pits held. Adamarch pays its debts, Ice-king. It never forgets them, either. |
| L27 | E17 (pits lost) | diamond_archon | My pits stood empty all night. Remember that I asked you, and that you chose. |
| L28 | E17 (always) | ossavar | You did not pay for that, Ice-king. Nobody paid for that. I will remember. (6 s) |
| L29 | E17 (< 30 sheltered) | torvald | I waited too long again. The lanes are quiet. Too quiet, for a morning. |
| L30 | E18 | torvald | Not here... not in front of them... |
| L31 | E21 | aldra | The lanes are empty, my lord. There is nobody left to shelter. |
Echoes: L11 and L14 are the Ep8 Ice fate ("Torvald opened his gate, and he kept it open") arriving early; L29 is his
prologue weakness spoken by himself; L20-L21 close e7m1's coin thread; L28 is Ossavar's reason in e7m4 (he joins the one
who did something nobody paid for). Every line <= 96 characters; Ossavar's <= ~70 per 5 s (L22 and L28 get **6 s**).

## Cinematic hooks (ENGINE, skippable)
| id | Kind | When | Shots | Lines | Skip end state |
|---|---|---|---|---|---|
| `e7m3_outwall` | HOLD 0:15 | E1 | 1) CRANE down the white wall's face (moonlit marble) to the Outwall's lantern-lit lanes; 2) MS Brannet at Net Lane's bell, arms crossed; 3) MS Torvald and Aldra at the Glass Hall's door, the ice doors opening | L1-L2 | Camera on Torvald; L1-L2 as dialogue |
| `e7m3_boats` | HOLD 0:08 | E10 | 1) LOW on the water: two fishing boats glide to the piers, nets full; 2) MS: a small girl with a lantern jumps onto the Tar Steps pier first and runs up toward the bell | L16 | Fishers at R4 / R5, the girl at R5's bell |
| `e7m3_unmask` | PAUSE 0:12 | E13 | 1) MS on the fallen Captain, his grey half-mask cracked; 2) ECU: violet cloth beneath, a candle sigil stitched in black; 3) CU Torvald, 3/4 | L20-L21 | `sec_mask` done; NT3 rule applied |
| `e7m3_dawn` | PAUSE 0:30, then victory | E17 | 1) WIDE crane over the Outwall at grey-gold dawn, raiders' boats pulling away; 2) outcome shot: **people** = the Glass Hall's ice doors open, the dockers walking out into the light, the girl holding Torvald's staff crystal up to the sun; **pits** = the Archon's white litter at P1, Facetguards counting diamonds; 3) MS Torvald on the Tar Steps; 4) Ossavar landing on the ridge of a shanty roof above him (L28); FADE_BLACK | L25 / L26 / L27, L28, (L29) | `Events.mission_ended(true)`; flags saved |
Fallbacks: lines as dialogue, a 2 s pan, missing VFX skipped.

**Between-mission scene `c_e7_pits` "The Year Comes Round"** (ENGINE, ~1:10, after victory; E7.D2 writes it): the Hall of
Silence; the Diamond Archon and Malrik over a table of raw diamonds. Malrik: "Empty the pits, Your Radiance. All of them.
By morning every dragon on the Coinwater is ours." The Archon: "An Archon before me did that once. The Year of Two Skies."
Malrik: "Then let us call it a tradition." Cut: Torvald on the Outwall's roofs with Aldra; Ossavar beside them; Ossavar:
"Tomorrow your friend buys the whole sky. Ask him what he means to burn." (If `sec_pits` and not `sec_people`, Ossavar
instead: "You guarded stones. Everyone guards stones." and leaves before Torvald can answer.)

## Economy
| Item | Value |
|---|---|
| Start | 400 crystals, 150 + carried essence, 0 gold, 30 / 60 pop, 6 Haulers |
| Nodes | Rope-walk 2 x 1 500, Saltworks 2 000 (24 m from the West Beach: LA2 lands beside it) |
| Gold | Only the diamond tithe: 0-120 gold / min from 9:00 (6.3). ~1 500 max by dawn |
| Essence | Trickle ~1 300 + kills ~1 600 (≈ 70 raiders) + **25 per row sheltered** (Brannet's thanks, paid when its last docker walks in) |
| What it means | The pits path buys 3-4 wares (Gambesons, Tempered Steel, Charter) or ~1 200 crystals of exchange; the people path buys none and must win with what it has. Both are tuned to win on normal (Difficulty) |

## Win / lose
| Event | Result |
|---|---|
| 22:00 dawn reached with Torvald alive and lost < 30 | **Victory** (after `e7m3_dawn`) |
| Torvald dies | **Defeat** |
| Rime Keep destroyed | **Defeat** (the shelter falls) |
| Lost >= 30 | **Defeat** |
| Aldra / Seraphine / mammoths fallen | Nothing (Aldra revives; Seraphine kneels; a dead mammoth is not carried) |
| Every pit head lost | Nothing (only `sec_pits`) |

## Reward carried to e7m4
- Splinter; 6 slots; essence 50 %, cap 1 500; **+300** first if `sec_people`, **+150** if `sec_mask`, **+100** if `sec_mammoths`.
- `sec_pits` done: **+600 gold** at the start of e7m4 (the Archon pays her debts) and **4 Facetguards** in e7m4's start army.
- `sec_people` done: **Brannet's rowers** refuse Malrik's galleys: in e7m4 Malrik's fleet has **2 galleys instead of 3**; 4
  Outwall dockers volunteer as **4 extra Rime Haulers** at e7m4's start.
- `sec_mammoths` done and at least one mammoth alive at dawn: the living mammoths start e7m4 beside Torvald (story units,
  commandable, pop 0).
- Flags: `e7m3_people` (sec_people), `e7m3_pits` (sec_pits), `e7m3_sheltered` (count), `e7m3_mammoths` (0-2 alive),
  `e7m3_mask`, `e7m3_time`. **Canon** for the Ep8 Ice road (`campaign-outline.md` 4.2, "The Gate Opens"): `e7m3_people`
  true adds 1 Rimeshield squad of Outwall volunteers there, like `e6m2`'s town.
- `MISSION_REWARDS[&"e7m3"] = {"flags": {...}, "bonus_essence": {"sec_people": 300, "sec_mask": 150, "sec_mammoths": 100}, "next": &"e7m4"}`.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave / guard counts | x 0.6, no Cinder Arbalest, no Kilnwarden, no Shadow Knight | as written | x 1.4 |
| Start | 500 crystals, +2 Rimeshields | as written | 300 crystals, 1 Shardguard |
| Bell channel | 2 s | 3 s | 4 s |
| Row taken after | 30 s | 20 s | 15 s |
| Defeat at lost | 34 | 30 | 26 |
| `sec_people` needs | 26 | 30 | 32 |
| Tithe | 50 / min per head | 40 | 30 |
| Mask Captain | 700 HP | 900 | 1 200, Hook Chain cd 9 |
| Expected time | 22 min (the clock) | 22 min + ~1 min of cutscenes | same |
The mission's length is the clock (22:00 + cutscenes = **~23:30**, in the 20-25 target); difficulty changes how hard the
night is, not how long. Expected run on normal (people path): bells R1 ~1:00, R2 ~2:30, LA1 2:30, PG1 turned back 4:00, R3
~5:00 before MK1, LA2 7:30 at the Saltworks, Archon 9:00 (ignored or half-held), MK2 / PG3 / LA3 10:00-13:00 on empty rows,
mammoths ~14:00 (optional), dusk 16:30: the army at the south piers, R4 / R5 rung by ~17:20, NT1 east takes the pits, NT2's
Captain at P1 18:30 (go east once the fishers are in), NT3 20:00 at the rows and the keep, dawn 22:00.
**Fight sizing** (normal; <= 70 % rule per fight; the Night Tide is **two fights at once** by design, D2):
| Fight | Enemy | Player side then | Ratio |
|---|---|---|---|
| LA1 (2:30) | 510 | ~2 100 + Aldra ~400 | 20 % |
| MK1 (5:30) | 460 | ~2 400 | 19 % |
| LA2 (7:30) | 900 | ~2 700 | 33 % |
| MK2 (10:00) at P2 | 720 | ~3 000 (half the army) | 48 % of a half |
| LA3 (12:30) | 1 300 | ~3 200 | 41 % |
| G2 yard guard (optional) | 760 | ~3 300 | 23 % |
| MK3 (14:00) at P1 | 730 | ~3 400 | 21 % |
| **NT1** south / east (17:00) | 1 690 / 1 080 = 2 770 | ~3 800 + Aldra + Seraphine ~600 + 4 Facetguards 560 (+ 2 mammoths ~1 300) | 34 % / 22 % each of the whole side; **55-62 %** together |
| NT2 (18:30) with the Captain | 950 + Captain ~450 = 1 400 | ~3 600 after NT1 | 39 % |
| NT3 south / east (20:00) | 1 965 / 840 = 2 805 | ~3 800 | 52 % / 22 %; 74 % together if the east half has not been cut by `sec_mask` (then 65 %) |
- The 70 % rule holds per fight; together the Night Tide is a deliberate stretch (the choice). NT3's together-ratio drops to
  65 % with `sec_mask`, which is why the Captain is worth chasing east after the fishers are safe.
- The intended people line: Rime Bulwarks across the two piers at 17:00 (the fishers run behind them), Flash Freeze on the
  landing clumps, Shardguards on the walking crews (Hold the Line stops the Grave Hounds' dives), Aldra's Glass Aegis on the
  dockers' escort. The pits line: the mammoths and the Frost Mortars on the headland; the tithe buys Gambesons + Steel.
- Watch in the first playtest: if the people path loses > 1 in 3 normal runs, cut NT1 south's Cinder Arbalests; if the pits
  path wins `sec_people` too in most runs, move the dusk boats to 17:00 (no lead time).

## Acceptance checks
1. A scripted headless run on normal (people path: 5 bells, army south at 16:30) ends `victory=true` at 22:00 + cutscenes
   with `sec_people` in 3 / 3 runs; a pits-path run (army on the pits from 9:00) ends `victory=true` with `sec_pits` and
   **< 30 sheltered** in 3 / 3 runs (the choice is real).
2. A bell refuses with an enemy within 8 m; a row with enemies and no side-0 unit for 20 s is burnt (Aurivane) or seized
   (masks); freed captives turn and walk to the keep.
3. A press-gang is turned back by one Ice soldier within 8 m of the bell and is never attackable by side 0.
4. The tithe pays 10 gold every 15 s per held pit head, and nothing while an enemy stands within 6 m.
5. Lost >= 30 = defeat within 3 s; dawn at 22:00 ends the mission (victory) whatever the secondaries.
6. The Mask Captain's death plays `e7m3_unmask`; NT3's east half is cut 40 % after it.
7. Every line <= 96 characters; every WAV fits.
8. `PERF OK` with NT1 (both halves), the 2 mammoths, 16 walking dockers and the shanty dressing.

## Implementation tasks (proposed ids)
| Id | Owner | What | Done when |
|---|---|---|---|
| **E7.M2** | four-wizards-high | `data/maps/adamarch_outwall.map` (140 x 110, `symmetry=none`): wall, gate, keep / halls / nodes, 5 rows + bells, piers, 3 landings, 3 pit heads, Hauling Yard, adit, tunnel, the sea polyline; Map Lab "story" profile | Every row of the Map table +-0.5 m; paths from the keep to every row, pit and landing |
| E7M3.S1 | systems | `missions/mission_e7_03.tscn` + `MissionE7_03`: map, sea, start state (Citadel via `set_start_tier(3)`, Aldra called at 0:00, Lodges max 4), Dock Bells (channel variant), the shelter (10 m walk-in), dockers hidden in rows, row taken / burnt / seized / pressed rules, pit heads and the tithe, the chain post, no caravans / posts, the no-save fallback | `tests/test_e7m3_s1.gd`: bell -> 8 dockers walk and shelter; a 20 s uncontested raid burns a row; tithe 10 gold / 15 s |
| E7M3.S2 | systems-high [H] | Objectives and events E1-E21; waves LA1-3, PG1-3, MK1-3, NT1-3 with the default-target rule, the `sec_mask` -40 % and mammoth +1 rules; dusk boats; the girl's instant ring; dawn withdrawal; win / lose; difficulty; rewards with the e7m4 hand-offs | `tests/test_e7m3_s2.gd`: lost 30 = defeat; dawn = victory; both secondaries reachable in scripted runs |
| E7M3.G1 | gameplay | UnitTypes `outwall_docker`, `brannet_story`, `outwall_girl` (NPC), `mask_captain` (Hook Chain, Grey Veil); the `masked` look modifier; press-gang Facetguards (`commandable` false, not attackable by side 0, never attack); War Mammoths as pop-0 mission units | Unit tests |
| E7M3.A1 | ai | Raider brain (walking dockers first, then rows, then the target), the seize-and-lead behaviour, press-gang walk / argue / leave | Raiders always prefer a walking docker within 20 m |
| E7M3.U1 | ui | Counters `Sheltered · Lost · Pressed (of 40)`, the two secondaries side by side, bell markers on the minimap (grey / ringing / rung / taken), tithe rings on the pits with a gold tick, the dawn clock; colours / names for `brannet`, `diamond_archon` | UI Lab screens |
| E7M3.C1 | systems-high | `e7m3_outwall`, `e7m3_boats`, `e7m3_unmask`, `e7m3_dawn` (two outcome takes) + skip states; StoryFlow -> `c_e7_pits` | `cine check` 0 FAIL |
| E7M3.V1 | tech-artist [H] | The Outwall kit: shanties (`forge:shanty` as game props), nets, tar barrels, piers, Dock Bells (ring anim), the white wall section and gate, pit heads with diamond glints, the Hauling Yard chains, the adit mouth, fishing boats and Aurivane landing boats (decor), night-to-dawn light ramp; 0 lights | Art Lab pass, `PERF OK` |
| E7M3.V2 | tech-artist | `outwall_docker` (3 variants), Brannet, the girl with a lantern (also the `ep8_ending` child base, campaign-outline F5), the `masked` grey look on the Shadow units, the Mask Captain, the Diamond Archon (e7o A6, portrait for the dialogue) | Contact sheet at 40 m |
| E7M3.O1 | Voice Forge agent | Audition and add `brannet`, `diamond_archon` to `cast.json`; render the 32 lines | Every WAV fits |
| E7M3.D1 | game-designer | Read the lines in game; write `c_e7_pits` (1:10, two Ossavar endings) | Script done |
| Lead | lead | Acceptance checks 1-8 | All pass |
Dependencies: e7m1's systems (trade off except the bank, story units); `MissionBase`; the walking-survivor brain of e2m1
(E2M1.S1); `RiverSystem` (one sea polyline); War Mammoth (step 13); the helper code (step TH).

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** War Mammoth (Ice titan, freed).
- **Why here:** landing lines and masked Shades on the pit headland; armor 30 grinds lines and buildings.
- **Moment:** the mammoths are freed (~14:00); the Night Tide pit front (17:00) breaks on them.
- **Intro card:** `War Mammoth. A titan of the far north: it walks through a line like snow through a fence.`

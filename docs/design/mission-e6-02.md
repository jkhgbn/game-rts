# Campaign mission e6m2: "The Rider at the Gate" (Torvald, with Aldra at the mere; Episode 6)

Written 2026-10-02 (`campaign-outline.md` 3.6, row 2). Episode 6 "The Lake and the Seed" (origins), mission 2 of 4:
**the weakness scene of the prologue (S24), played**. A rider begs at Torvald's ice gate; the player chooses to **open the
gate** (costly: the army must go out while the Hollow strikes the lake) or **keep it shut** (the town burns). The choice is
saved for Episode 8's Ice road. Target **18-22 min** on normal. Episode rules ER1-ER8 and the Warden Breaker: see
`mission-e6-01.md` section 0. Uses `skirmish-1v1.md`, `levels.md`, `items.md`, `tiers.md` 6, `kingdom-ice.md`,
`bowmen.md` (Frostbow), `new-units-12.md` (Rimeling), `t3-helpers.md` 4.4 (Aldra) and the format of `mission-01.md` /
`mission-e3-01.md`. New scene `missions/mission_e6_02.tscn` + `scripts/campaign/mission_e6_02.gd` (`MissionE602 extends
MissionBase`, mission id `e6m2`). Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `+z` = south.
Status: **design only**; recommended option taken everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | When | **Forty winters ago** (ER1): "sixty winters I have kept this gate" (the gate went up after e6m1's three winters) | Torvald's approved audition line ("A hundred winters I have kept this gate", `cast.json`) adapted to the year |
| D2 | Who burns the town | **Obren's Wardens, as bait**: they burn Hearthwick to draw the army out through the gate, then strike the Heartfrost from below the lake | Gives "he waits too long, and trusts slow ice more than quick friends" a real reason: holding is *right* for the lake and *wrong* for the town. A dilemma, not a test of goodness |
| D3 | The map | A new map **"Frostgate"** (120 x 120, `main.gd` generator, seed **1602**, not mirrored): Torvald's land north of a glacier wall, Glasswater Mere's south shore in the north-east corner, the town of Hearthwick on the road south | A wall with one gate is the whole mission; no existing map has one |
| D4 | How the player chooses | The gate is sealed until the rider arrives (5:30). Then the **Frostgate's card** has **Z `Open the gate`** and **X `Keep it shut`**, with a 1:30 window (the rider's signal fire burning down). Pressing X, or letting the fire die, chooses "shut". The gate can still be opened later, but then the town is already gone | One clear decision point, made with the game's own buttons (no dialogue menu); the prologue image (the snow burying the signal fire) is the timeout |
| D5 | Is one branch "correct"? | **Both win.** Open is harder (two fronts) and saves people (`e6m2_town_saved`, used by Ep8: 2 extra Rimeshield squads on the Ice road, outline 4.2). Shut is easier and the town burns. The prologue's memory is "shut"; the true ending's fate is "he opened his gate, and kept it open" | Outline: "open the gate (costly) or hold (the town burns)" |
| D6 | Aldra | Adult Aldra (~40, the TH look minus the grey) holds the Heartfrost as a **story unit**; she is the lake's defence while the army is away | ER2, ER5; she is the warden of the mere |
| D7 | Tier | Tier 1 (ER4) with the full tier-1 Ice roster: Rime Colossus and Frostbow open here | Fair growth from e6m1; the Stronghold stays e6m4 / e7m1 |

## Story setup (briefing text, 3 short paragraphs; shown after `c_e6_lake`)
1. Forty winters ago. For sixty years Torvald's ice gate has stood across the south road, and in sixty years it has
   never once opened. Behind it lie his keep, his lake, and the Heartfrost he promised to keep cold.
2. South of the wall lies Hearthwick: two hundred people, a mill, and a signal fire they light when they need their lord.
   Tonight the stone-men have come back up out of the ground, and they are not walking toward the lake.
3. Aldra watches the mere. Torvald watches the gate. Somewhere in the snow, a rider is coming. Decide what the gate is for.

## Map: "Frostgate" (120 x 120, `main.gd` generator, not mirrored, `MAP_SEED := 1602`)
Frozen theme (M9.V1): fir and pine, snow ground, packed-snow road (width 5) from the gate to the south edge. Clearings: no
trees / rocks inside. Playable bounds x -58..58, z -58..58.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Torvald) | `(0, -32)` | 16 (keep) | |
| **Rime Keep** (player, tier 1) | `(0, -44)` | 16 | 3 000 HP |
| Frost Hall (pre-built) / Snow Lodge (pre-built) | `(-14, -42)` / `(14, -40)` | - | Lodge +20; Snow Lodges **max 3** (cap 80) |
| Node `e6g_a` / `e6g_b` | `(-10, -52)` / `(9, -53)` | - | **1 500** each (12.8 / 12.0 m from the keep) |
| Node `e6g_west` (expansion) | `(-44, -40)` | 7 | **2 000**; hall spot `(-38, -32)` |
| **Glasswater Mere, south shore** | ice polygon `(28, -60) (60, -60) (60, -30) (40, -28) (28, -36)` | - | Old ice, walkable, no floes; no building on it |
| **The Heartfrost** | `(44, -46)` | 4 | The e6m1 object: team PLAYER, **3 000 HP**, regen **10 HP / s** while no enemy is within 8 m |
| Lake spire (pre-built Rime Spire) | `(34, -34)` | 3 | 720 HP; covers the crack's approach |
| **Amber crack `crack_mere`** | `(54, -24)` | 6 | The lake column's spawn (24 m from the Heartfrost); invisible until its first telegraph |
| **The Long Ice** (glacier wall) | line z = **-10**, x -60..-3 and 3..60, 3 m thick, 6 m high | 4 (no trees within 4 m) | Navigation geometry, invulnerable decor, blocks sight (FogOfWar occluder like a cliff) |
| **The Frostgate** (`frostgate`, new building) | `(0, -10)` | - | 6 x 3 footprint in the wall gap; see "The Frostgate" |
| Gate spires (pre-built Rime Spires) | `(-7, -15)`, `(7, -15)` | 3 | Range 11: they reach the gate apron to z -4 |
| Rider's signal fire | `(4, -5)` | 3 | A brazier prop south of the gate; lit at E4 |
| **Hearthwick Hall** | `(0, 28)` | 16 (town) | Building `town_hall` (copy of the Snow Lodge look x1.6), team PLAYER, **1 200 HP**, `counts_for_defeat` false, 24 townsfolk inside |
| Town houses (8) | ring r 12 around `(0, 28)` at 22.5 + 45 k degrees: `(11.1, 32.6)`, `(4.6, 39.1)`, `(-4.6, 39.1)`, `(-11.1, 32.6)`, `(-11.1, 23.4)`, `(-4.6, 16.9)`, `(4.6, 16.9)`, `(11.1, 23.4)` | - | `town_house` (3 x 3, 400 HP, team PLAYER, `counts_for_defeat` false); the two at z 16.9 stand 0.6 m off the road edge |
| **Warden Gate `wgate_sw` / `wgate_se`** | `(-40, 50)` / `(40, 50)` | 6 | 19.V2's Warden Gate (ruined arch, amber inner stone): team ENEMY, **1 800 HP**, armor 10, `counts_for_defeat` false, spawns the columns |
| Lost Caches | `(-30, -28)`, `(32, 26)` | 3 | `items.md` loot, appear at 2:00, reopen 180 s |
| Rally (suggested) | `(0, -24)` | - | Behind the gate |
Distances (path): keep -> gate 34 m; gate -> Hearthwick Hall 38 m; each Warden Gate -> the Hall 45 m; Hall -> inside the
wall (z < -12) 40 m; the army at the Hall -> the Heartfrost ~95 m (~23 s for Rimeshields); `crack_mere` -> Heartfrost 24 m.

### The Frostgate (`frostgate`, systems; `BuildingType` + a small script)
| Field | Value |
|---|---|
| Size / HP / armor | 6 x 3, **3 600 HP**, armor 20, team PLAYER, `counts_for_defeat` false, sight 10 |
| States | **Closed** (navigation geometry: blocks every ground path through the wall) / **Open** (no obstacle). Opening or closing takes **4 s** (the two ice leaves slide into the wall); navmesh rebake on each change (the building path). Units inside the footprint when it closes are pushed to the nearer side (the Bulwark rule) |
| Card | **Z `Open the gate`** / **X `Keep it shut`** (while closed during the choice window); afterwards **Z `Open the gate`** / **Z `Close the gate`** (one toggle button). Before 5:30 both are greyed `Sealed for winter` |
| Damage | Wardens attack it only while closed (it is in their way); Breakers deal x2. At 0 HP it **shatters**: open for good, rubble look; never a defeat |
| Look | Two 6 m leaves of blue glacier ice in a frame of grey stone, Torvald's snowflake sigil across both; open = leaves inside the wall; damage cracks as `art-keep.md` 8 |

### Townsfolk (`townsfolk`, gameplay; story unit)
The Rime Hauler model with brown wool hoods and bundles (no tool), 60 HP, speed 4.2, no attack, team PLAYER, **not
commandable**, group `"scripted"` + `"townsfolk"`, pop 0. They only walk the road. A townsperson is **saved** when it
reaches z < -12 (inside the wall); it then walks to the keep and stands by its fire (cosmetic).

## Start state
| Item | Value |
|---|---|
| Torvald | **Level 3**: Rime Bolt r1, Flash Freeze r1 + **1 unspent point**, **cap 6** (L3: 500 HP, 19 dmg, 120 mana) |
| Aldra (adult) | Story unit `aldra_story` at `(40, -40)` (below) |
| Crystals / essence | 350 / 400 (+1 / s) |
| Buildings | Rime Keep (tier 1), Frost Hall, Snow Lodge, 2 gate spires, the lake spire, the Frostgate (closed) |
| Units | 6 Rime Haulers gathering (3 + 3); **4 Rimeshields + 3 Shardcasters + 2 Frostbows + 1 Rime Seer** at `(0, -24)`; **2 Rimeshields** at the Heartfrost `(40, -40)` |
| Population | 18 / 40 |
| Inventory | 6 empty slots, no artifact |
| Fog | On; the road, Hearthwick and the gate apron explored from 0:00 (the wall still blocks sight: the town is seen through its lights only) |

## Unlocks
| Kind | Available | Locked |
|---|---|---|
| Buildings | Snow Lodge (Z), Frost Hall (X), Rime Spire (C), Ice Wall (V, max 16) | Tier 2+, stables, Bazaar |
| Units | Rime Hauler (keep Z); Frost Hall **Z Rimeshield, X Shardcaster, C Rime Seer, V Rime Colossus, B Frostbow, N Rimeling** | Tier-2 units, the Rimecarver (e7m1) |
| Keep | No tier button (`max_tier = 1`) | Stronghold (e6m4 / e7m1) |
| Spells | Rime Bolt, Flash Freeze, Rime Aegis (L4+); cap L6 | - |
| Items | Base shop (keep, Frost Hall) incl. the Ice items | Tops out of reach |

### Aldra at the mere (story unit `aldra_story`)
The TH.V3 model, look `&"prime"` (hair darker, no grey; glass hauberk, crystal staff). Kit = `t3-helpers.md` 4.4 at
**Torvald's level** (L3: 710 HP, armor 15, 22 damage, range 9): Glasswater Ward, Shatterglass, Glass Aegis, **Wake the
Sentinel from Torvald's L5** (a 30 s Rime Colossus, pop 0). Brain **"Hold the mere"**: stays within 12 m of the Heartfrost,
fights what comes within 16 m of it, never follows Torvald. Not commandable. Falls: back after **45 s** at `(38, -36)` at
full HP; line L28 once.

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_dawn` | Primary | `Hold until dawn (20:00)` (countdown) | 20:00, **or** both Warden Gates destroyed |
| `obj_heartfrost` | Primary, always shown | `The Heartfrost must not fall` (HP bar) | Fails = defeat |
| `obj_torvald` | Primary, always shown | `Torvald must survive` | Fails = defeat |
| `obj_choice` | Primary (appears at E4) | `The rider's fire: 1:30` (countdown) | Resolved at the first Z (open) or X (shut), or at 0:00 (shut). Turns into the branch line below |
| `obj_town` | Primary (branch **open**) | `Bring Hearthwick's people through the gate (0 / 24)` | Ends at victory; done if saved >= 12 (normal); shown as a counter, never a defeat |
| `sec_gates` | Secondary | `Break the Warden Gates (0 / 2)` | Both destroyed (also ends the mission) |
| `sec_lake` | Secondary | `Keep the stone-men off the Heartfrost` | Heartfrost never under 50 % HP |
In the **shut** branch `obj_town` never appears; the panel shows the line `Hearthwick burns.` (grey, struck through) for the
rest of the mission.

## Waves and the Wardens (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
All ENEMY, group `"scripted"`, no Commander. A Warden Gate "spawns" a column by its arch flaring amber for 1 s. A
destroyed Warden Gate stops all its columns. Order rule for the columns on the road: **prefer townsfolk within 8 m**, else
the order's target.
| Wave | Trigger | Units | Spawn | Order |
|---|---|---|---|---|
| W0a | 3:30 | 3 Ruin Wardens | `wgate_sw` | The west town houses (they attack houses only; the Hall is left for later) |
| W0b | 4:30 | 3 Ruin Wardens | `wgate_se` | The east town houses |
| **Branch OPEN** (from the gate's first opening while the window runs) | | | | |
| Road columns | Every **50 s** per living Warden Gate (the two offset by 25 s), from the opening | 3 Ruin Wardens | each gate | Attack-move along the road to the Frostgate (townsfolk first) |
| Lake column | Telegraph at opening + 40 s (crack glows, ground shakes, message), spawn at **opening + 60 s** | 4 Ruin Wardens + 1 Warden Breaker | `crack_mere` | Heartfrost |
| **Branch SHUT** (X, or the fire dies) | | | | |
| Siege columns | From the choice, every **60 s**, alternating gates | 3 Ruin Wardens | | Attack-move to the Frostgate |
| Lake column | Telegraph at choice + 160 s, spawn at **choice + 180 s** | 4 Ruin Wardens + 1 Warden Breaker | `crack_mere` | Heartfrost |
| **Both branches** | | | | |
| Breach | 12:00 | 2 Warden Breakers + 6 Ruin Wardens (split between the living gates) | gates | Frostgate (then the Rime Keep if it is open or shattered) |
| Lake 2 | 14:30 (telegraph 14:10) | 3 Ruin Wardens + 1 Warden Breaker | `crack_mere` | Heartfrost |
| Final | 16:00 (skipped if no Warden Gate lives) | **The Gate-Breaker** + 8 Ruin Wardens | the living gate nearer the Frostgate | Frostgate, then the Rime Keep |

**The town** (both branches). Before the choice the town is only scored: W0 burns houses. **Open**: at the opening, the
townsfolk leave the Hall in 3 groups of 8 at +0 s, +40 s and +80 s and walk the road to the gate; if the gate is closed
when they reach it they wait at `(0, -4)` until it opens. Torvald's soldiers within 6 m of a group give it +20 % speed
(they hurry). **Shut**: the Hall and every house take **10 HP / s** (burning, no attacker) and are rubble within 2:00; the
townsfolk walk south off the map at once (despawn at `(0, 58)`; not dead, not saved). An opening after the window is
allowed (a gate is a gate), but the town is already gone.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Briefing, then camera on the gate; L1-L4; hint `The Frostgate is sealed for winter. Build up: the Wardens are somewhere south.` (8 s) |
| E2 | 3:30 (W0a) | L5; smoke columns over Hearthwick; minimap pings on the houses (the town is lit but behind the wall) |
| E3 | 4:30 | L5b (Aldra: the mere is restless) |
| E4 | 5:30 | Cutscene `e6m2_rider` (0:15, HOLD): L6-L9; then `obj_choice` active (1:30); the Frostgate's Z / X unlock; prompt (non-pausing, 12 s) `The rider begs you to open the gate. Select the Frostgate: Z opens it, X keeps it shut. His fire burns for 1:30.` |
| E5a | Gate opened inside the window | Branch **open**: L10-L12; `obj_town` active; the townsfolk leave; road columns and the lake telegraph armed |
| E5b | X pressed, or the window ends | Branch **shut**: L13-L15; the signal fire is buried by snow (prologue S24: 3 s snow-drift VFX over the brazier); the rider rides south and despawns; the town burns; siege columns and the lake timer armed |
| E6 | A lake telegraph (each time) | Message `The ice is cracking at the mere!` (6 s) + minimap ping at `crack_mere`; first time L16 (open) or L17 (shut) |
| E7 | First 8 townsfolk saved (open) | L18 |
| E8 | A Warden Gate destroyed (first) | L19; `sec_gates` 1 / 2 |
| E9 | 16:00 Final spawns | L20; the Gate-Breaker's boss bar |
| E10 | Both Warden Gates destroyed, or 20:00 | Victory: cutscene `e6m2_dawn_open` (branch open) or `e6m2_dawn_shut` (branch shut, even if the gate was opened later); every Warden left crumbles |
| E11 | Torvald dies | L26; defeat after 3 s |
| E12 | Heartfrost destroyed | L27; defeat after 3 s |
| E13 | Aldra falls (first) | L28 |

## Dialogue (31 lines, ~22 heard per run; 5 s each unless listed; <= 96 characters)
New speaker **`rider`** (Bren of Hearthwick, shown `Bren`, colour `(0.80, 0.82, 0.88)`): a new `cast.json` entry
`{"voice": {"bm_fable": 0.7, "bm_daniel": 0.3}, "speed": 1.12, "notes": "Bren, a young Hearthwick rider (e6m2): breathless
British man; not a main voice."}` and a `Speakers.TABLE` row (E6M2.O1 / E6M2.U1). Others as e6m1. File
`data/voice/lines/e6m2.json`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Forty winters ago. The gate had stood for sixty years, and never once opened. |
| L2 | E1 | torvald | Sixty winters I have kept this gate. I can keep it one more. |
| L3 | E1 | aldra | Torvald. The Heartfrost hums when the stone-men are near. It is humming now. |
| L4 | E1 | torvald | Then the gate stays shut, and the lake stays quiet. |
| L5 | E2 | narrator | South of the wall, the lamps of Hearthwick went out one by one. |
| L5b | E3 | aldra | They are not coming for the lake. Why are they not coming for the lake? |
| L6 | E4 | rider | Lord Torvald! Open the gate! The stone-men are in Hearthwick! |
| L7 | E4 | rider | They're burning the houses. Two hundred people, my lord. Children. |
| L8 | E4 | aldra | It is bait. They want the gate open. They want the mere. |
| L9 | E4 | torvald | I know what they want. |
| L10 | E5a | torvald | Open the gate. All of it. |
| L11 | E5a | rider | Thank you, my lord! I'll bring them home! |
| L12 | E5a | aldra | Then I hold the mere alone. Do not be long. |
| L13 | E5b | torvald | ...No. The gate stays shut. |
| L14 | E5b | rider | You can see the smoke from up there! You can SEE it! |
| L15 | E5b | narrator | The snow buried his signal fire. Torvald watched it go out. |
| L16 | E6, open | obren | Thank you for opening the door, frost-man. |
| L17 | E6, shut | obren | Keep your gate, then. I will come up through your floor. |
| L18 | E7 | rider | They're through! Keep it open, the last ones are coming! |
| L19 | E8 | torvald | Their door is broken. Go home, stones. |
| L20 | E9 | aldra | Torvald! The big one is at your gate! |
| L21 | E10 open | torvald | Close it now. Gently. Everyone is home. |
| L22 | E10 open | rider | Hearthwick will remember this gate, my lord. |
| L23 | E10 shut | torvald | The lake is safe. The lake is always safe. |
| L24 | E10 shut | aldra | And the town? |
| L25 | E10 shut | torvald | ...Ask me in a hundred winters. |
| L26 | E11 | torvald | The ice... gives... |
| L27 | E12 | obren | Mine. (2 s) |
| L28 | E13 | aldra | Cracked. Not broken. (3 s) |
| L29 | E10 open, `c_e6_gate` | torvald | Hearthwick still sends me bread every midwinter. Burnt, usually. |
| L30 | E10 shut, `c_e6_gate` | torvald | Some nights I still see the smoke. |
(L8: Aldra speaks from the mere; the dialogue box shows her portrait as usual, she does not move.) Echoes: L2 is the
approved audition line; L13-L15 are prologue S24 ("he turns away; snow buries the rider's signal fire"); L21 is the
first half of Ep8's fate line ("Torvald opened his gate, and he kept it open"); L25 answers the truce frame (a hundred
winters later is now).

## Cinematic hooks (ENGINE; skippable; units frozen)
| Id | Kind | When | Length | Shots / actors | End state (a skip must leave exactly this) |
|---|---|---|---|---|---|
| `e6m2_rider` | ENGINE, **HOLD** | E4 | 0:15 | Teleports at `at == 0`: Torvald `(0, -16)` (no enemy is north of the wall before 7:00); the rider actor at `(0, 20)` mounted (Snowdrift Rider model, brown cloak). 1) LONG LENS down the road: a lone rider through the snow, Hearthwick burning behind; 2) LOW at the gate: he hammers the ice with a fist (3 hits, ice-thud SFX); 3) **OVER TORVALD'S SHOULDER** on the wall (the prologue S24 frame, reversed in Ep8 E17): the rider lights his signal fire at `(4, -5)` and looks up (L6-L9) | Torvald `(0, -16)`, idle; rider dismounted at `(4, -5)` by the lit fire (invulnerable story actor); `obj_choice` 1:30 running; Frostgate Z / X unlocked; L6-L9 queued once |
| `e6m2_dawn_open` | ENGINE, **HOLD**, then victory | E10 (open) | 0:30 | 1) dawn light over the wall; the Frostgate closes slowly on the empty road; 2) WIDE inside: townsfolk round the keep's fires, Aldra wrapping a child in a blanket (the Ep8 E17 image, forty years early); 3) MS Bren bows to Torvald; Torvald nods once (L21-L22) | Victory |
| `e6m2_dawn_shut` | ENGINE, **HOLD**, then victory | E10 (shut) | 0:30 | 1) dawn, grey; the buried signal fire, a hump of snow; 2) LONG LENS: thin smoke over Hearthwick's rubble; 3) MS Torvald alone on the wall, Aldra walking up behind him (L23-L25) | Victory |
| `c_e6_gate` | ENGINE stage, between-scene | After the victory screen | 0:35 | Present-day winter truce: Torvald on the same wall, older, snow on his shoulders; L29 (open) or L30 (shut); then narrator `In the west, Ysolde remembered a different winter.` (into e6m3) | - |
Camera axis: the gate line (north-south road); cameras stay east of it.

## Tiers, casters, helpers
`MissionE602._init`: `tiers_enabled = true`, `casters_enabled = false`, `helpers_enabled = false`; `_ready`:
`tier_system.max_tier = 1`, `bots_upgrade = false`. Frost Hall card Z X C V B N as listed; no "+" page; tier chip
`Tier 1 Keep`. No enemy keep, no bot.

## Economy
| Item | Value |
|---|---|
| Start | 350 crystals, 400 essence, 18 / 40, 6 Haulers |
| Nodes | Home 2 x 1 500; west 2 000 (safe: everything enemy is south of the wall or at the lake) |
| Expected (normal) | ~12 Haulers by 6:00; ~3 300 crystals mined by 20:00 |
| Essence by the end | 400 + trickle ~1 200 + kills: open ~1 300 (~70 Wardens, 5 Breakers, the Gate-Breaker if met) / shut ~900 = **~2 500-2 900** |
| Pressure | Before 5:30 the player builds without knowing the branch: a mixed army (Rimeshields for the road, Frostbows and a Rime Colossus for the gate) is right for both |

## Win / lose
| Event | Result |
|---|---|
| 20:00, or both Warden Gates destroyed | **Victory** (branch cutscene) |
| Torvald dies | **Defeat** |
| Heartfrost destroyed | **Defeat** |
| Rime Keep destroyed | **Defeat** |
| Frostgate shattered | Nothing: it stays open; message `The Frostgate has fallen. Hold the keep.` |
| Hall / houses / townsfolk lost | Counters only |
| Aldra falls | Nothing; back in 45 s |

## Reward and flags
- Nothing carried (ER3). `MISSION_REWARDS[&"e6m2"] = {"flags": {"e6m2_gate_opened": <the gate opened inside the window>,
  "e6m2_town_saved": <saved >= threshold>, "e6m2_saved_count": <int>}, "next": &"e6m3"}`. **Ep8 Ice road** reads
  `e6m2_town_saved` (outline 4.2: 2 extra Rimeshield squads).
- Story flow: victory -> `c_e6_gate` (branch line) -> e6m3 briefing.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave counts | x 0.6 | as written | x 1.4 |
| Choice window | 2:00 | 1:30 | 1:00 |
| Town saved threshold (of 24) | 8 | 12 | 16 |
| Heartfrost HP | 4 000 | 3 000 | 2 400 |
| Gate-Breaker HP | 1 800 | 2 400 | 3 200 |
| Expected time | open 16-19 / shut 20 | open 18-20 / shut 20-21 | open 19-22 / shut 21 |
Fight sizing (Warden 120, Breaker 330, Gate-Breaker 800; player side = crystals + Torvald `170 + 30 x level`):
| Fight | Enemy | Player side then | Ratio |
|---|---|---|---|
| Road column (open, from ~6:30) | 360 each, one per 25 s while both gates live | ~2 000 at the road | 18 % each; ~36 % if two stack |
| Lake column (open, ~7:30) | 810 | Aldra ~400 + 2 Rimeshields 200 + lake spire ~200 = **~800** | **~100 % on purpose**: Aldra holds ~40 s; the player must send ~6 units back at the telegraph (20 s warning) |
| Siege column (shut) | 360 / 60 s | ~2 000 + 2 gate spires behind 3 600 HP of gate | 16 % |
| Lake column (shut, ~10:00) | 810 | ~2 400 (the army is home) | 34 % |
| Warden Gate push (open, ~11:00-14:00) | gate 1 800 HP + its next column 360 | ~2 600 | 14 % + the gate |
| Breach (12:00) | 1 380 | ~2 800 | 49 % |
| Lake 2 (14:30) | 690 | ~3 000 | 23 % |
| Final (16:00) | 1 760 | ~3 200 | 55 % |
- The skill check of **open** is the split at ~7:30: escort the townsfolk (they walk 10 s through the column zone) while a
  detachment races back to the mere. The intended answers: Rimeshields + Rime Seer on the road, Frostbows (long chill) on
  the columns, Torvald back to the lake with 4 units at the telegraph (Rime Aegis there), an Ice Wall or two across the
  crack's approach built **before** the opening (the crack's spot is hinted by Aldra's L5b and the ground's faint glow).
- **Shut** is a wall defence the player already knows from e6m1; it is meant to be easier and to feel wrong.
- Watch in the first playtest: if the open branch loses the Heartfrost more than 1 run in 3 on normal, move the lake
  telegraph to opening + 30 s (spawn + 60 s stays) or raise Aldra to L4 numbers.

## Target length (normal)
| Part | Time |
|---|---|
| Mission, open branch (gates broken ~16:00-18:00) / shut branch (dawn 20:00) | ~17:00 / 20:00 |
| `e6m2_rider` + dawn cutscene | 0:45 |
| **Total** | **~18-21 min** (inside 18-22) |

## Code reuse (recommendation to the lead)
`MissionBase`; the e6m1 Heartfrost object (PLAYER target with regen) and `warden_breaker`; 19.V2's Warden Gate model as a
spawner building (the M4 pylon's spawn code: a timer, a count cap, a spawn ring); `MissionBrazier`'s prop for the signal
fire; the Rime Spire type for the three pre-built spires; the cliff / occluder path of the map generator for the Long Ice.

## Acceptance checks
- [ ] Map: seed 1602; the Long Ice blocks every path except the Frostgate (path test from `(0, -30)` to `(0, 30)` exists only while the gate is open); all table positions within 1.5 m on walkable ground; the town houses do not touch the road.
- [ ] Frostgate: sealed (greyed) before 5:30; Z opens in 4 s and rebakes; X resolves "shut"; the window timeout resolves "shut"; units in the footprint are pushed out on closing; shattering leaves it open and is not a defeat.
- [ ] Branch open: 3 groups of 8 leave at +0 / +40 / +80 s, wait at a closed gate, count as saved at z < -12; road columns every 50 s per gate (offset 25 s); lake telegraph at +40 s, spawn at +60 s.
- [ ] Branch shut: the fire is buried, the rider leaves, the town burns to rubble in 2:00, townsfolk despawn south; siege columns every 60 s; lake column at +180 s.
- [ ] Both: Breach 12:00, Lake 2 14:30, Final 16:00 (skipped with no gate alive); destroying both gates wins at once.
- [ ] Flags: `e6m2_gate_opened`, `e6m2_town_saved` (threshold per difficulty), `e6m2_saved_count` saved on victory; a save with `e6m2_town_saved = true` is readable by a stub Ep8 loader test.
- [ ] Dialogue: branch lines only on their branch; `rider` is in `Speakers.TABLE` and `cast.json`.
- [ ] Skipping `e6m2_rider` leaves Torvald at `(0, -16)`, the rider at the fire, the window running.
- [ ] Timing: scripted headless runs on normal: open branch (escort, send 4 back at the telegraph, break both gates) `victory=true` in 16-20 min with >= 12 saved in 3 / 3; shut branch survives to 20:00 in 3 / 3.

## Done when (proposed ids)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| **E6M2.M1** | four-wizards-high (World Forge) | `data/maps/frostgate.map` from the Map table (wall, gate gap, mere polygon, town ring, gates, road) | Tool 6 | Map Lab >= 90; positions +-0.5 m |
| **E6M2.S1** | systems | Scene + script; `frostgate` building (states, card, rebake, push-out, shatter); town hall / houses; Warden Gate spawner; pre-built spires; start state; `max_tier = 1` | E6M1.S1 (Heartfrost object), E6M2.M1 | Map / Frostgate checks |
| **E6M2.S2 [H]** | systems-high | The choice (window, Z / X, timeout), both branches (townsfolk groups, burning, columns, lake telegraphs), shared waves, events E1-E13, objectives, win / lose, difficulty, flags | E6M2.S1 | Branch / wave / flag / timing checks |
| **E6M2.G1** | gameplay | `townsfolk` unit (walk-only, escort speed bonus, saved trigger); `aldra_story` with the `&"prime"` look and the "Hold the mere" brain; the Gate-Breaker elite values | E6M1.G1 | A townsperson within 6 m of a Rimeshield walks 5.04 m/s; Aldra never leaves 12 m of the Heartfrost |
| **E6M2.U1** | ui | `obj_choice` countdown, the Frostgate card (Z / X then the toggle, greyed `Sealed for winter`), the non-pausing prompt, `obj_town` counter, the struck-through `Hearthwick burns.`, `rider` colour + portrait slot | 19.U3 | Readable at both test sizes |
| **E6M2.C1** | systems-high | `e6m2_rider`, `e6m2_dawn_open`, `e6m2_dawn_shut`, `c_e6_gate` (branch line) | 19.C1 | Skip tests |
| **E6M2.V1** | tech-artist | Frostgate (leaves, sigil, open / closed / cracked / shattered), the Long Ice wall kit (glacier face, 6 m, tileable), Hearthwick (hall, 8 houses, burning and rubble states, smoke), townsfolk tint, signal fire + snow-burial VFX, rider actor tint, Aldra `&"prime"` look, crack telegraph glow | M9.V1, 19.V2 | 0 lights, Art Lab pass, `PERF OK` with the town burning |
| **E6M2.O1** | Voice Forge agent | `rider` in `cast.json`; `data/voice/lines/e6m2.json` (31 lines) rendered | Lines frozen | Each WAV fits its slot |
| **E6M2.D1** | game-designer | Lines in game; first-playtest tuning of the open branch's lake split | Playtest | Written back here |
| Lead | lead | Both headless branch runs; commit | All | Acceptance "Timing" |

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Frostbow (opens here).
- **Why here:** slow Warden columns through the only gap in the Long Ice; long chill; Lab 16 / 62 / 23 (exempt bowman).
- **Moment:** the first road column after the choice: Frostbows on the gate line chill it short of the town.
- **Intro card:** `Frostbow. Every arrow chills: what walks toward it walks slower, and slower.`

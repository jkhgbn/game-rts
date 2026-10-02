# Campaign mission e5m2: "Burn a Door" (young Vessa + Sergeant Ashby; Episode 5)

Written 2026-10-02 (`campaign-outline.md` 3.5, row 2). Episode 5 "The Spark and the Candle", mission 2 of 4, a
flashback. Vessa at fifteen, given her first command, besieges **Rookhold**, the fen fort of Gannet Rook (the reiver
chief who escaped in e5m1). Her prologue weakness is the mission's rule: **charging ahead alone springs an ambush;
waiting for the army does not**. Her strength is its other rule: wood burns, and a wall is only a door she has not
burned yet. First siege of the campaign: **Ash Hurlers**, towers, gates and **Ember Archer volleys** drilled by a young
Sergeant Ashby. Target **16-20 min** on normal. Episode rules F1-F11 of `mission-e5-01.md` ("Episode 5 shared rules")
apply unchanged. Format `mission-01.md`; numbers `units-fire-shadow.md`, `levels.md`, `spells.md`, `tiers.md` 6,
`walls.md` (palisade and gate numbers), `tier3-extras.md` 4.2 (the volley rule reused). New scene
`missions/mission_e5_02.tscn` + `scripts/campaign/mission_e5_02.gd` (`MissionE502 extends MissionBase`, id `e5m2`).
Metres, seconds, `m:ss` of `mission_time()`; `(x, z)`, `+z` = south. Status: **design only**. Recommended option taken.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | Map | **"Rookhold"**, `main.gd` generator, 120 x 120, `MAP_SEED := 5102`, not mirrored: the Fire field camp in the north-west, the fen fort in the south-east, the **Reedmere** marsh (3 reed fields) on the short road between them and the **Long Dyke** (a longer dry road, no reeds) around the north and east | Two roads = a real choice between fast-and-risky and slow-and-safe |
| D2 | The ambush rule | Three hidden reiver bands in the reeds. The **first player unit** to come within **12 m** of a reed field decides it: if Vessa is inside 12 m with **fewer than 4 own soldiers within 10 m of her**, the band **springs** around her; otherwise it is **spotted** where it hides and fights normally | Her weakness as a rule (outline), with an answer the player can see and learn |
| D3 | Wood | Every Rookhold building is **wood**: palisade, gates, watchtowers, tents, the Nest take **x2 damage from fire sources** (Fireball, Ember Step scorch, Ash Hurler bolts, burning volley arrows). Ordinary arrows and swords x1 | "Give her a wall, and she will burn a door through it" (pro. L13) made literal: any palisade piece is a possible door |
| D4 | Sergeant Ashby | Story unit `ashby_sergeant` (Corwen Ashby at ~25, M0's captain-to-be), **commandable**, never dies (wounded -> back in 60 s) with the **Drill** aura that turns nearby Ember Archers' fire into volleys | Teaches support positioning; he must live (Ep1 captain) |
| D5 | Volleys | `ember_volley` = the Powder Volley rule (`tier3-extras.md` 4.2) with Ember Archer numbers, only within 10 m of Ashby | Reuse of built-to-spec code; one new knob set |
| D6 | Shop | Base shop on (field camp and Ember Hall), **150 essence, +1 / s**, no peddler | e5m1 had none; a siege refresher reopens items |
| D7 | Gannet | Boss, **flees at 25 %** (never dies: the fens keep him); victory = the Rook's Nest burned | A clear siege goal; the fight is the fort, not a chase |

## Story setup (briefing text, 3 short paragraphs)
1. *Winter, the truce. Vessa laughs at something nobody else heard. Ashby, grey now, knows exactly which day she means.*
2. Three summers after the Vale of Bells, Gannet Rook was back: a fort of black timber in the southern fens, Rookhold,
   and in it the grain of half the south border. The Master sent his youngest apprentice to fetch it back.
3. Vessa was fifteen. She had an army, a sergeant called Ashby, and one piece of advice from Vey: wait for your
   soldiers. She was sure she would remember it.

## Map: "Rookhold" (120 x 120, generator, seed 5102, not mirrored)
Overcast noon (preset `fen_noon`, tech-artist). Camera bounds x -58..58, z -58..58. The south and east edges beyond the
fort are open fen water (decor, impassable). Clearings: no trees / rocks inside.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Vessa, Ashby 2 m east) | `(-32, -32)` | - | |
| **Field camp** (`field_camp`, Fire keep copy) | `(-40, -40)` | 16 | 2 000 HP, shoots, trains Cinder Hand (Z), base shop, drop-off; no tier button |
| Ember Hall (pre-built, complete) | `(-28, -44)` | - | `fire_barracks_e5m2` (Unlocks); a shop and drop-off too |
| Node `rk_camp_a` / `rk_camp_b` | `(-50, -34)` / `(-34, -52)` | - | **1 500** each |
| Node `rk_dyke` (north road) | `(-6, -42)` | 7 | **1 500**; on the Long Dyke, raided by W1 |
| **The Causeway** (short road, width 5) | `(-26, -26)` -> `(22, 22)` | - | Path 70 m camp -> Rook Gate; crosses the three reed fields' edges |
| **The Long Dyke** (long road, width 5) | `(-26, -40)` -> `(40, -40)` -> `(50, -10)` -> `(52, 24)` | - | Path 118 m camp -> Postern; no reeds |
| **Reed field R1 "Near Reeds"** | centre `(-14, -12)`, r 9 (trigger r 12) | - | Band B1 hidden inside |
| **Reed field R2 "Heron Pools"** | centre `(2, 2)`, r 9 (trigger r 12) | - | Band B2 |
| **Reed field R3 "Gatereeds"** | centre `(12, 13)`, r 7 (trigger r 12) | - | Band B3; 18 m short of the gate |
| **Rookhold palisade** (`reiver_palisade`) | ring r **15** around `(34, 34)`, 4 m pieces | - | 600 HP each, wood (D3); collider on layer 1 |
| **Rook Gate** (`reiver_gate`) | `(23.4, 23.4)` (north-west face) | - | **2 400** HP, wood, a closed door that opens only for reiver sallies (`walls.md` 5 door rule) |
| **Postern** (`reiver_gate`, small) | `(49, 34)` (east face) | - | **1 400** HP, wood |
| Watchtowers T1 / T2 (`reiver_watchtower`) | `(20, 31)` / `(31, 20)` | 3 | 600 HP, wood, 14 dmg, range **11**, cooldown 1.5 (Ember Spire numbers) |
| **The Rook's Nest** (`rook_nest`) | `(38, 40)` | - | **2 400** HP, wood, `counts_for_defeat = true` for the enemy (the mission's goal) |
| Reiver Tents (`reiver_tent`) | `(30, 40)` / `(43, 29)` | - | 450 HP, wood |
| Grain store (decor + cutscene) | `(35, 28)` | - | Sacks and a granary hut; not targetable |
| Spawn `SP_FEN` (Gannet's escape) | `(56, 56)` | 4 | In the fen water's edge, beyond the Postern |
Distances (path): camp -> R1 24 m, R1 -> R2 22 m, R2 -> R3 15 m, R3 -> Rook Gate 15 m; camp -> Postern by the Long Dyke
118 m. Ash Hurler range 12 > watchtower range 11: from `(14, 22)` a Hurler reaches the gate and T1 but not T2's range.

## Start state
| Item | Value |
|---|---|
| Vessa | **Level 2** (Fireball r1, Ember Step r1), full HP / mana, **level cap 4**, look `&"young"` at 15 (F2) |
| Sergeant Ashby | `ashby_sergeant` at `PLAYER_START + (2, 0)` (kit below) |
| Crystals / essence | **300 / 150** (+1 essence / s) |
| Buildings | Field camp, Ember Hall (complete) |
| Units | 5 Cinder Hands gathering (3 on `rk_camp_a`, 2 on `rk_camp_b`); **4 Flame Guards + 4 Ember Archers** at `(-26, -30)`; **+2 Ember Archers** ("the miller's boys") if `e5m1_farms_saved` |
| Population | 13 / 20 (15 with the boys; Hearth max **2** = cap 40) |
| Enemy | Guards and bands below; Gannet at `(37, 37)` |
| Fog | On; the Causeway, the Long Dyke and the fort's outline (palisade, gates, towers) explored from 0:00 |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Hearth (Z, max 2), Ember Hall (X), Ember Spire (C) | Walls, stables, Bazaar |
| Units | Cinder Hand (keep Z); `fire_barracks_e5m2`: **Z Flame Guard, X Ember Archer, C Blaze Rider, V Ash Hurler** | Tier 2+ (F3) |
| Spells | Fireball (L1), Ember Step (L2), **Kindle (L4)** | Cap 4 |
| Items | Base shop: the components, mids, Ember Draught, Dusk Vial, Homeward Seal (tops sold but out of reach: ~1 300 essence max) | Peddler, artifacts |

### Sergeant Ashby (`ashby_sergeant`, team PLAYER, **commandable**; gameplay)
Young Corwen Ashby (no moustache yet, plumed sergeant's helm). Value for fight sizing **300**.
| Stat / ability | Value |
|---|---|
| HP / armor / damage / speed / sight | **450** / 10 / 16 melee (cooldown 1.1) / 5.0 / 11 |
| **Drill** (passive aura, r **10**) | Own Ember Archers within 10 m of him gain `ember_volley` (below). Ring decal r 10 under him while selected |
| **Wounded** | At 0 HP he kneels (no death event, no XP to the enemy), fades after 2 s and walks out of the field camp **60 s** later at 50 % HP; L24 the first time |
| Levels | None (story unit); not counted in the pop |
**`ember_volley`** (UnitAbilities, the `powder_volley` code with these values): hold for the volley **0.5 s** while other
loaded Ember Archers within **8 m** have targets; when **>= 4** fire in the same 0.25 s window each shot deals **+25 %**
to units and is a **burning arrow** (fire source: x2 on wood, D3); no knockback, no smoke. Bark `"Loose!"` max once per
10 s.

### Gannet Rook (`reiver_chief`, e5m2 numbers; the kit of `mission-e5-01.md`)
**1 100** HP, armor 10, 22 melee (cooldown 1.2), speed 5.2. **Hook Throw** (12 s, range 8, 6 m pull, 15). **War Horn**
(once, at 50 % HP): reivers within 12 m get `attack_cooldown_pct` -0.20 for 8 s. **Flees at 25 %**: walks out of the
Postern (or the nearest breach) to `SP_FEN`, untargetable after 2 s, despawns. Value **600**.

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_door` | Primary | `Burn a door into Rookhold` | The Rook Gate, the Postern or **any palisade piece** is destroyed |
| `obj_nest` | Primary (appears after `obj_door`) | `Burn the Rook's Nest` | The Nest is destroyed |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `sec_patience` | Secondary | `Don't let an ambush catch Vessa alone (spotted 0 / 3)` | At victory, no band has sprung (fails at the first sprung band); the counter shows spotted bands |
| `sec_towers` | Secondary | `Burn the watchtowers (0 / 2)` | T1 and T2 destroyed |

## The reed ambushes (systems; D2)
| Band | Field | Units (hidden) |
|---|---|---|
| B1 | R1 Near Reeds | 4 Reivers |
| B2 | R2 Heron Pools | 3 Reivers + 2 Reiver Slingers |
| B3 | R3 Gatereeds | 4 Reivers + 1 war-boar |
| State | Rule |
|---|---|
| Hidden | Status `hidden`: not visible to the player, not targetable, no aggro, even inside sight; a small reed-sway VFX only. The fog never reveals them |
| Decide | The first time **any** player unit (Vessa included, workers excluded) comes within **12 m** of the field centre: if Vessa is within 12 m **and** fewer than **4** own soldiers (non-worker, Ashby counts) are within **10 m** of her, the band **springs**; otherwise it is **spotted** |
| Sprung | The band teleports to navmesh points on a ring r **6** around Vessa (inside or at the edge of the reeds), gets `taunted`-style focus on Vessa for **6 s** (they attack only her), then normal aggro. Message `Ambush!` (red), minimap ping; L6-L7 the first time; `sec_patience` failed |
| Spotted | The band appears where it hid (fade-in 0.5 s), message `Ambush spotted in the reeds!` (gold), minimap ping; they attack-move to the nearest player unit; L8 the first time; counter +1 |
The Long Dyke has no reeds: a player who takes it skips the bands (they stay hidden and never act). `sec_patience` is
still done at victory (no band sprang).

## Guards, waves and the AI (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted, no Commander, no enemy economy; guards hold with a 2x leash. Units inside the palisade never leave it except
in the sally and the Final.
| Group | Where | Units |
|---|---|---|
| G1 tower feet | `(18, 28)` and `(28, 18)` | 2 Reivers each |
| G2 garrison | The Nest, `(37, 37)` | **Gannet** + 4 Reivers + 3 Reiver Slingers |
| G3 tent guards | Each tent | 1 Reiver Slinger each |

| Wave | Trigger | Units | Spawn | Order |
|---|---|---|---|---|
| W1 dyke raid | 4:30 | 3 Reivers + 1 war-boar | The Postern (it opens) | Along the Long Dyke, attack-move to the nearest Cinder Hand (`rk_dyke` first) |
| Gannet's taunt | 8:00 | Gannet walks to the gate top `(25, 25)` for 8 s (L-taunt), then back | - | Bark only (bait for an impatient player) |
| S1 sally | Rook Gate HP first below **60 %**, or the first palisade piece destroyed | 5 Reivers + 2 Reiver Slingers + 2 war-boars | The gate nearest the damage (opens 4 s) | Attack-move to the nearest Ash Hurler, else the nearest Ember Archer, else Vessa |
| Tent call | Every **90 s** from 6:00, per living tent | 2 Reivers inside the fort (max 12 extra) | That tent | Join G2 |
| Final | The Nest below **50 %** | Gannet's **War Horn**; G2 and every reiver inside attack-move to Vessa (3 s refresh); +20 s: 3 Reivers + 1 Reiver Slinger | The Postern | Attack-move to Vessa |
If `sec_towers` is done before the Final, the +20 s group is not sent and the tent calls slow to every 150 s.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (Briefing played.) Cutscene `e5m2_rookhold` (HOLD 0:15); L1-L4; hint `Rookhold is south-east. The Causeway is short but runs through the reeds. The Long Dyke goes round.` |
| E2 | Any player unit within 18 m of a reed field the first time | L5; hint `Reeds hide ambushes. Send soldiers in first, or walk Vessa in with at least 4 of them.` |
| E3 | A band springs (first) | L6-L7; `sec_patience` failed |
| E4 | A band is spotted (first) | L8 |
| E5 | W1 (4:30) | L9; hint `Shop: walk Vessa within 12 m of the camp or the Ember Hall and press T.` |
| E6 | Ashby first within 10 m of 4 Ember Archers | Hint `Sergeant Ashby drills the archers: within 10 m of him, 4 or more Ember Archers loose together. Their burning arrows hit wood twice as hard.` |
| E7 | First Ash Hurler trained | L10; hint `Ash Hurlers throw 12 m, the watchtowers shoot 11. Wood burns: Fireball, Hurlers and burning volleys deal double damage to it.` |
| E8 | Gannet's taunt (8:00) | L11 |
| E9 | A watchtower destroyed | L12 (first); `sec_towers` counter |
| E10 | S1 sally | L13 |
| E11 | `obj_door` done | Cutscene `e5m2_door` (HOLD 0:08); L14-L15; `obj_nest` active |
| E12 | Vessa reaches level 4 | L16; hint `Ctrl+E learns Kindle: E makes nearby soldiers strike and run faster.` |
| E13 | Nest below 50 % (Final) | L17 |
| E14 | Gannet below 25 % | L18; he flees |
| E15 | Nest destroyed | Cutscene `e5m2_morning` (HOLD 0:45) with L19-L23; victory at its end |
| E16 | Ashby wounded (first) | L24 |
| E17 | Vessa dies | L25; defeat after 3 s |

## Dialogue (25 lines; 5 s each unless listed; <= 96 characters)
Colours: Vessa `(1.0, 0.45, 0.1)`, Ashby `(0.95, 0.60, 0.35)`, Gannet `(0.62, 0.55, 0.40)`, Narrator `(0.9, 0.85, 0.7)`.
Voice file `data/voice/lines/e5m2.json`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Three summers on, the reivers built a fort in the fens. Vessa was sent to knock. |
| L2 | E1 | ashby | Sergeant Ashby, my lady. Vey says I'm to keep you alive. He says it's a full-time job. |
| L3 | E1 | vessa | Vey worries. I've been practising. Give me a wall and I'll burn a door through it. |
| L4 | E1 | ashby | Yes, my lady. With the army, my lady. The army's the bit that walks behind you. |
| L5 | E2 | ashby | Reeds, my lady. Lovely place to hide a knife. Let the lads go in first. |
| L6 | E3 | gannet | Little match! Three years, and you still run in alone! |
| L7 | E3 | vessa | Okay. OKAY. Bad idea. Very bad idea! |
| L8 | E4 | ashby | There! In the reeds! That's what waiting buys you, my lady. |
| L9 | E5 | gannet | Burn my tents, would you? I'll have your diggers and their shovels too. |
| L10 | E7 | ashby | Hurlers! Now we're talking. They throw farther than those towers can shoot. |
| L11 | E8 | gannet | Come on, match! Come and knock! I'm right here! Just you! |
| L12 | E9 | vessa | One tower down! Ashby, did you see? Write it down somewhere! |
| L13 | E10 | gannet | Out, boys! Knock the fire-throwers flat! |
| L14 | E11 | vessa | See? A door! I said there'd be a door! |
| L15 | E11 | ashby | There already was a door, my lady. It had a latch. |
| L16 | E12 | ashby | You're glowing, my lady. More than usual, I mean. |
| L17 | E13 | gannet | My nest! My lovely nest! The horn, boys! Blow the horn! |
| L18 | E14 | gannet | Keep the fort! Keep the fens! I'm keeping my neck! |
| L19 | E15 | narrator | Rookhold burned until morning. So, by accident, did the grain it had stolen. |
| L20 | E15 | vessa | Ashby. That was the grain. That was the grain we came here to take back. |
| L21 | E15 | ashby | It was, my lady. It's toast now. Very good toast. |
| L22 | E15 | vessa | The Master's going to say it. I know he is. "Fire that will not wait..." |
| L23 | E15 | ashby | "...burns its own house." Yes, my lady. We've all heard him say it. |
| L24 | E16 | ashby | Just a scratch! Carry on, my lady, I'll catch you up! (4 s) |
| L25 | E17 | vessa | I should have... waited... |
Echoes: L3 is pro. L13 in her own mouth; L22-L23 is pro. L14 (the Master's weakness line for her), the only time it is
spoken inside the story; L11 is the bait the ambush rule punishes; Ashby's "my lady" becomes "my queen" by Ep1 (M0
`m0_dawn`), and L2 seeds his Ep1 loyalty.

## Cinematic hooks (ENGINE, CinematicPlayer 19.C1; skippable; the mission clock stops while they play)
| Id | Kind | When | Length | Shots | End state (a skip must leave exactly this) |
|---|---|---|---|---|---|
| `e5m2_rookhold` | ENGINE, **HOLD** | E1 | 0:15 | 1) LOW over the reeds at Heron Pools, a heron lifts off; rack focus to Rookhold's black palisade and the two towers; 2) MS Vessa (15) and Ashby at the camp edge, 3/4, Ashby offering a map, Vessa already walking. L1 | Vessa at `PLAYER_START`, Ashby 2 m east, army at its spot, no orders; bands hidden |
| `e5m2_door` | ENGINE, **HOLD** | E11 | 0:08 | 1) MS on the breach (gate or the destroyed piece): burning timber falls inward; Flame Guards (actors = the 3 nearest player soldiers, moved 4 m) pour through; Vessa plants a red banner in the breach. L14 | The 3 soldiers 4 m inside the breach with their old orders cleared; a `vessa_banner` prop at the breach centre (decor, not targetable) |
| `e5m2_morning` | ENGINE, **HOLD** | E15 | 0:45 | 1) WIDE at dawn: Rookhold smoking; the granary roof collapses in flame (L19); 2) MS two-shot Vessa and Ashby by the breach, 3/4, eye: L20-L21; 3) CU on her red banner in the breach: the fire has crept up the pole and **catches the banner** (pro. S16's image); 4) STATIC CU Vessa: she looks at it and **laughs**, soot on her face (pro. S17); L22; 5) WS Ashby shaking his head, smiling: L23; FADE_BLACK | Every reiver despawned; fort ruins in their burnt state; victory |
Camera axis: Vessa - Ashby line north-south; cameras on its west side. Fallback: the banner fire is a VFX swap on the
prop (`vessa_banner` -> burning state).

## Win / lose
| Event | Result |
|---|---|
| `obj_nest` done | **Victory** after `e5m2_morning` |
| Vessa dies | **Defeat** (instant loss) |
| Field camp destroyed | **Defeat** |
| Ashby wounded | Nothing (back in 60 s) |
| A band springs | `sec_patience` failed; play goes on |
| Gannet flees | Nothing; the Nest is the goal |

## Reward (F1: flags only)
`MISSION_REWARDS[&"e5m2"] = {"flags": {"e5m2_patient": "sec_patience", "e5m2_towers_burned": "sec_towers"}, "next":
&"e5m3"}` plus `e5m2_time` and `e5m2_bands_sprung` (0-3). Ep8's Fire road ("The Spark Waits") may greet `e5m2_patient`
with one Ashby line (outline 4.2); no other effect.

## Economy
| Item | Value |
|---|---|
| Start | 300 crystals, 150 essence, 13 / 20 pop |
| Nodes | 2 x 1 500 at the camp, 1 500 on the Long Dyke (W1's target) |
| Expected (normal) | 9-10 Cinder Hands by 5:00; ~3 000 crystals mined by 17:00; army ~22-26 pop at the gate (incl. 3-4 Ash Hurlers); essence ~1 300 by 17:00 (trickle ~1 000 + kills ~300): one mid (suggested Ember Brand line) |

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / band / wave counts | x 0.6, no war-boars | as written | x 1.4; B3 +1 war-boar |
| Ambush rule | spring needs fewer than **2** soldiers near Vessa | fewer than 4 | fewer than **5** |
| Sprung focus on Vessa | 4 s | 6 s | 8 s |
| Gate / Postern / Nest HP | 1 800 / 1 000 / 1 800 | 2 400 / 1 400 / 2 400 | 3 000 / 1 800 / 3 000 |
| Gannet HP | 850 | 1 100 | 1 400 |
| Start | 400 crystals, +2 Flame Guards | as written | 250 crystals, 3 Ember Archers |
| Expected time | 13-16 min | 16-20 min | 19-24 min |
Fight sizing (normal, F10; player: soldiers + Ashby 300 + Vessa `170 + 30 x level`):
| Fight | Enemy | Player then | Ratio |
|---|---|---|---|
| B1 spotted (~2:30) | 320 | 360 + 400 + 300 + 230 = 1 290 | 25 % |
| B1 **sprung** (Vessa + < 4 soldiers) | 320 on Vessa alone (~36 DPS on 375 HP) | Vessa + Ashby | the lesson: ~10 s to escape with Ember Step |
| W1 dyke raid (4:30) | 360 | ~1 600 | 23 % |
| B2 spotted (~6:00) | 440 | ~1 800 | 24 % |
| B3 spotted (~8:30) | 440 | ~2 000 | 22 % |
| Towers + G1 | 2 x 120 + 320 = 560 | ~2 200 | 25 % |
| S1 sally | 840 | ~2 400 | 35 % |
| G2 + tent calls (inside) | 620 + 600 + up to 320 = 1 540 | ~2 800 | 55 % |
| Final (+20 s) | 1 540 + 340 = 1 880 | ~2 900 | 65 % |
- The gate is the obvious door; the intended siege is Hurlers on T1 from 12 m, burning volleys on the gate under Ashby,
  Flame Guards in front against the sally. A palisade piece away from the towers (east face, by the Long Dyke) is the
  "burn a door through a wall" answer and is meant to work: it lands the army beside the Postern and a tent.
- Gate maths (normal): 4 Ash Hurlers x 24 x 2 (wood) / 2.2 s = ~87 DPS, + a 4-archer burning volley ~33 DPS, +
  Fireball 120 per cast: ~20-25 s of steady fire, which is why S1 fires at 60 %.
- Watch in the first playtest: if B1 springs on most first runs and costs Vessa, raise E2's hint to 24 m and slow the
  sprung focus to 5 s on normal; if the Long Dyke makes the reeds pointless, add 1 Reiver Slinger to W1 (it uses the dyke).

## Target length (normal)
| Part | Time |
|---|---|
| `e5m2_rookhold` | 0:15 |
| Approach and the reeds / dyke | 0:00-9:00 |
| Towers, gate, sally (`obj_door`) | 9:00-13:00 |
| `e5m2_door` | 0:08 |
| Inside, the Nest, the Final | 13:00-18:00 |
| `e5m2_morning` | 0:45 |
| **Total** | **~16-20 min** (outline 3.5: 16-20) |

## Implementation tasks (proposed ids; the lead adds them to `waves.md`)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| **E5M2.S1** | systems | Scene + script map part: seed 5102, clearings, roads, fen edge, `field_camp` type (shop, drop-off, Cinder Hand, no tier), pre-built Hall copy `fire_barracks_e5m2` (Z X C V), nodes, palisade ring r 15 of `reiver_palisade` pieces (600 HP, layer 1), `reiver_gate` x2 with the door rule (opens only for sallies), `reiver_watchtower` x2, `rook_nest`, 2 tents, grain decor, 3 reed fields (sway decor + trigger areas); F3 knobs; start state with the `e5m1_farms_saved` archers | MissionBase, `walls.md` door code (or a closed `Building` with a scripted open) | Test `tests/test_e5m2_s1.gd`: every table position within 1.5 m; no navmesh path from the camp into the fort while all pieces stand; one palisade piece destroyed opens a path (rebake); Hurler at 12 m from T1 is outside T1's 11 m |
| **E5M2.S2 [H]** | systems-high | Objectives and events E1-E17; the ambush rule (hidden, decide on the first unit within 12 m, spring ring r 6 + 6 s focus, spot fade-in); guards G1-G3; W1, taunt, S1 (gate nearest the damage), tent calls (cap 12), Final (+20 s, 3 s refresh), `sec_towers` rule; wood x2 from fire sources (a `damage_tags` check: `fire` on Fireball, scorch, Ash Hurler, burning volley); instant loss; camp loss; difficulty; flags | E5M2.S1, E5M2.G1 | Scripted headless runs on normal: (a) army-first through the Causeway spots 3 / 3 bands and wins in 16-20 game-minutes; (b) Vessa alone into R1 springs B1 (its 4 Reivers stand on the r 6 ring around her within 1 s); (c) a palisade piece burned on the east face counts as `obj_door` |
| **E5M2.G1** | gameplay | `ashby_sergeant` (Drill aura r 10, Wounded -> 60 s return at 50 %, commandable, no pop); `ember_volley` via the `powder_volley` code (0.5 s hold, 8 m, >= 4, +25 % vs units, burning tag); Gannet's e5m2 numbers + War Horn; `hidden` status for the bands (not visible, not targetable, no aggro) | `tier3-extras` Powder Volley code | Test: 4 Ember Archers within 10 m of Ashby fire in one 0.25 s window and each deals 11.25 to a unit and x2 to a palisade; 3 archers do not volley; a hidden Reiver is not targetable by a Flame Guard at 2 m until revealed |
| **E5M2.U1** | ui | Objectives panel (`spotted n / 3` counter), `Ambush!` / `Ambush spotted` messages and pings, Ashby's Drill ring when selected, `ashby` portrait (young variant), the shop button reachable (T) | 19.U1 / 19.U3 | Readable at 1600 x 900 and 3440 x 1440 |
| **E5M2.C1** | systems-high | `e5m2_rookhold`, `e5m2_door`, `e5m2_morning` with the end states above (the breach shot finds whichever door was burned) | 19.C1, E5M2.S2 | Skips leave the end states; the door shot frames the gate, the Postern or a palisade piece correctly |
| **E5M2.V1** | tech-artist | Rookhold kit: black-timber palisade (whole / burning / breached), Rook Gate and Postern (closed / open / burning / broken), watchtower, the Nest (a timber hall with a rook-feather crest), tents, granary (burning, collapse), reed fields with sway, fen water edge, `fen_noon` and dawn presets; young Ashby look; `vessa_banner` (clean / burning) | - | 0 lights except the presets; `PERF OK` with the Final on screen |
| **E5M2.V2** | tech-artist | VFX: burning-arrow volley (one shared streak bundle per volley), wood-burn hit flare (x2 hits read different), ambush reed-burst on spring, gold shimmer on spot | - | <= 2 particle systems per effect |
| **E5M2.O1** | Voice Forge agent | Render `e5m2.json` (L1-L25) | E5.O1 (`gannet`), lines frozen | Every WAV fits its slot |
| **E5M2.D1** | game-designer | Read the 25 lines in game; check the sprung rate and the gate time in the first playtest; adjust here | Playtest | Changes written back here |

## Done when (acceptance checks)
- [ ] E5M2.S1: Rookhold builds from seed 5102 with every table row within 1.5 m; the fort is sealed until a piece or a gate burns; Hurlers out-range towers by 1 m.
- [ ] E5M2.S2: E1-E17 in order on a scripted run; every band springs or is spotted by the 12 m / 4-soldier rule, never both; S1 fires once; the Final at 50 % Nest; wood takes x2 only from fire sources; victory after `e5m2_morning`; defeat on Vessa's death or the camp's fall.
- [ ] E5M2.G1: volleys exactly at >= 4 archers within Ashby's 10 m; Ashby never dies; hidden bands are untargetable until decided.
- [ ] E5M2.U1 / C1 / V1 / V2 / O1: panel, messages, three cutscenes with their skip end states, the Rookhold kit and the lines in game.
- [ ] Lead: scripted headless run on normal (army-first) `victory=true` in 16-20 game-minutes in 3 / 3 seeds with `sec_patience` done; a Vessa-first run springs B1; smoke and perf tests pass.

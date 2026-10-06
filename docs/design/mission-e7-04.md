# Campaign mission e7m4: "The Year of Two Skies" (Torvald + Aldra, with Malrik until the turn; Episode 7 finale)

Written 2026-10-02 (`campaign-outline.md` 3.7 row 4). Episode 7 "Gold for Fire", mission 4 of 4, the episode's finale on
the **whole Coinwater**: every fleet, every dragon, both cities, four wizards. It opens as e7m1's 2v2 (Torvald + Malrik vs
Vessa + Ysolde); at the height of the battle Malrik empties Adamarch's pits and buys the whole sky (the Year of Two Skies,
again), the cities raise a truce on the Tollrock, and Malrik orders the dragons to burn it all to feed the heart-stone.
**Torvald says no.** Malrik's seat turns enemy mid-mission; Aurivane stands down; **Ossavar** lands beside Torvald; the
player holds the Tollrock against Malrik, his bought dragons and his galleys, and ends the battle the way the Master once
did: Torvald **stills the sea**. Then `ep7_ending` "No. Not for Now." Target **25-30 min** on normal. Rules and format of
`mission-e7-01.md` (map, DragonAuction, auction dragons, story units) and `mission-e7-02.md` / `-03.md` (read them first).
New scene `missions/mission_e7_04.tscn` + `scripts/campaign/mission_e7_04.gd` (`MissionE7_04 extends MissionBase`, id `e7m4`).
Metres, seconds, `m:ss`; positions `(x, z)`, `+z` = south (Aurivane). Status: **design only**. Recommended option everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | Map | `two_harbours.map` (E7.M1), the e7m1 table, **all four seats live** (Malrik seat 3, Vessa seat 0, Ysolde seat 1) plus galleys on the water (6.2) | The finale on the ground of the first mission: the player knows every door |
| D2 | The shape | **Five phases**, event-driven with time caps: P1 "The Full Strait" (2v2, take the Tollrock), P2 "Two Skies" (cutscene + 40 s truce), P3 "The Turn" (cutscene, side switch), P4 "Hold the Rock" (Malrik's assaults), P5 "Still the Sea" (3 channels at the lighthouse) | The outline: "at the turn Malrik's bot becomes the enemy; survive and hold the Tollrock with Ossavar"; a closing act the wizard performs himself |
| D3 | The side switch | `MissionBase.switch_seat_side(seat 3, side 1)`: every unit and building of Malrik's seat becomes ENEMY, its Commander loads the enemy profile, shared vision is cut, a **10 s grace** walks his field units back to his rally first. **Aurivane (seats 0 and 1) withdraws**: Commanders paused, field units walk to their city gates and leave the map, their buildings get the **truce** flag (e7m2 D8: untargetable both ways, invulnerable) | The only way to make the ally-turned-enemy readable and fair; Aurivane in a three-way brawl would bury the story beat |
| D4 | Ossavar | Joins side 0 at the turn **whatever happened before** (his line changes with `e7m1_ossavar_won` and `e7m3_people`). Story titan (e7m1 6.3 `ossavar_story` numbers), not commandable, **targets dragons first**; at 15 % HP he rests on the Master's chair 30 s and returns (never dies) | He was twice sold; he will not be sold a third time (e7o 2, e7m3 L28) |
| D5 | Malrik's dragons | After the turn **Kesh, Morrow-of-Glass and Sunwake** (a third gilt dragon, Aurivane's pride) fight for Malrik. Each can be **paid home** at the player's Bazaar for gold (6.3): the dragon leaves north and never returns | The Master's third experiment done right (he called them away; the cities paid them back; now someone pays them to leave). Gold for fire, inverted: gold for **no** fire |
| D6 | Still the Sea | Final objective: Torvald channels at the **lighthouse** (the Tollrock point `(0, 6)`) **3 times**, 15 s each (the `mission-04.md` Turn the Key rule: leaving 3 m resets the stage, damage does not); 30 s between stages. Each stage freezes a third of the strait: the galleys in it stop firing for good and Malrik's units in its water band are `chill`ed 6 s. The third ends the battle | The Ice wizard's version of the Master's "Enough." (e7o H13-H14), earned in play; it hands the stilled sea to `ep7_ending` |
| D7 | Tier, helper, carry | Start at the **Citadel**, **Aldra called** (e7m3 D3); e7m3's hand-offs apply (Facetguards / +600 gold for the pits, Outwall Haulers and 2 galleys for the people, the mammoths) | The finale with the whole kit; the night in the Outwall matters here |
| D8 | Malrik as an enemy | **Malrik L7** (Lance r3, Siphon r3, Shroud r2) with **Mother Hush** (enemy story unit, e7m2 6.3 numbers at L7, flees at 25 %, returns 90 s later once). Malrik respawns 60 s after a death (the 2v2 rule); killing him is never the win | Ep8 needs both; the win is the sea, not a body |
| D9 | The Stone's Hunger | A meter from the turn: **+1 %** for every unit death within the strait band (`|z| <= 30`). At **50 %**: Malrik's units +15 % damage for 60 s (Hollow Surge, the Obren whisper); at **100 %**: the next scheduled assault launches at once with **+25 %** units, and the meter resets to 50 %. Not a lose condition | Malrik's motive made visible: every death feeds the stone, so the player is rewarded for walls, freezes and clean fights |
| D10 | Ending film | `e7m4_still` (in-mission, 0:30) then StoryFlow plays **`ep7_ending` "No. Not for Now." (1:10)**: beats below for its writer (E7.D3) | The outline's episode ending |

## Story setup (briefing text, 3 short paragraphs)
1. Six hundred years ago, in the Year of Two Skies, Adamarch emptied its diamond pits in one night, and every dragon on the
   Coinwater changed sides by morning. Tonight the Diamond Archon signs the same order, with Malrik's hand on her pen.
2. At dawn both cities sail everything they own into the strait. Aurivane holds the Tollrock with Vessa and Ysolde. Adamarch
   attacks it with Torvald and Malrik. The truce of the Stilled Sea is a hundred and thirty years old, and it ends today.
3. Torvald knows whose knives broke the Laurel. He knows whose masks walked out of the old adit. He has waited for Malrik to
   become someone else. Today he will find out how long a patient man can wait.
Briefing objectives: `obj_rock`, the rule `Torvald must survive`, and the line `Crimson galleys shell the north shore: sink
them or stay off the shore road.`

## Map: "Two Harbours" (the e7m1 table) + this mission's layer
Everything of `mission-e7-01.md` "Map" holds (all four seats as listed there). Additions:
| Thing | Position | Notes |
|---|---|---|
| **Crimson galleys** (Aurivane, P1 only) | **CG-W** `(-62, -3)`, **CG-M** `(-38, -3)`, **CG-E** `(40, -3)` | Floating targets (6.2); anchored 6 m off the north bank (the bank is `z = -9`): Shardcasters on the bank reach them, melee cannot |
| **Silver galleys** (Malrik's, after the turn) | **SG-W** `(-50, 3)`, **SG-E** `(50, 3)`, **SG-M** `(26, 6)` (SG-M only if `e7m3_people` is false) | Anchored mid-strait, 12 m off the north bank: Frost Mortars (13), Rime Spires on the bank (11) and spells reach them |
| Strait thirds (Still the Sea) | **West** `x < -26`, **Moat** `-26 <= x <= 26` (the ring), **East** `x > 26`; water band `|z| <= 9` and the moat ring | One third per stage, west first, then east, then the moat |
| **Lighthouse** (Still the Sea channel spot) | The Tollrock point `(0, 6)` | Torvald within 3 m |
| Master's stone chair | `(-9, 0)` | Ossavar's rest spot (D4) |
| Admiralty Quay | `(22, -40)` | Side 0's far post until the turn, Malrik's (held post) after |
| Malrik's rally | `(36, -44)` | The grace walk ends here |
| Aurivane city gates (withdraw exits) | `(-40, 80)` / `(40, 80)` | Withdrawing units leave the map here |
Distances (path): Rime Keep -> Malrik's Dusk Keep 84 m along the north shore (his base is the player's next-door neighbour:
after the turn the player has an enemy base on its own shore); Gloom Hall -> North Causeway foot 64 m; Rime Keep -> lighthouse
86 m.

**6.2 Galleys** (new mission target, systems; decor ship models from e7o A7 `forge:galley`, game budget): a Building-like
floating target on the water, **900 HP**, armor 10, `counts_for_defeat` false; **melee cannot hit it** (the flyer rule's
melee half); ranged units, towers, spells and Frost Mortars can (Frost Mortar x1.5 as on buildings). **Broadside** every **30 s**:
a 2 s red ring telegraph on a shore point within 20 m of it (the side-0 unit or building nearest to it, else the shore road),
then **60** damage in r **3** (buildings x0.5). Sunk = 3 s list-and-sink, a floating debris decal. Frozen (Still the Sea) =
silent for good, still a target.

## Start state (Torvald's track + e7m3's hand-offs)
| Item | Value |
|---|---|
| Torvald | **Level 6** with **5 unspent points** (Rime Bolt r1 known), cap 8; Splinter + the 6 slots |
| Crystals / essence / gold | **450** / **150 + carried** / **0** (+**600** if `e7m3_pits`) |
| Buildings | Rime Keep at the **Citadel** (4 200 HP), Frost Hall, 2 Snow Lodges, Frost Bazaar, 1 Rime Spire `(-30, -30)` |
| Units | 6 Rime Haulers (**+4** if `e7m3_people`); 2 Caravans; **8 Rimeshields + 4 Shardcasters + 2 Rime Seers + 1 Rimecarver + 2 Frost Mortars + 2 Shardguards** at `(-36, -44)` (2 460 crystals); **Aldra** (helper, L6, Escort); **4 Facetguards** if `e7m3_pits`; the **War Mammoths** alive at e7m3's dawn (0-2, story units, commandable, pop 0) |
| Population | 6 + 2 + 19 units (pop 21) + Aldra 4 = **33 / 60** (+4 Haulers if people) |
| Malrik (ally bot until the turn, seat 3) | **Level 7**; Dusk Keep at the **Citadel**, Gloom Hall, Hovel, Night Spire; 6 Thralls; **6 Shades + 3 Nightbolts + 2 Hexweavers + 1 Shadow Knight + 1 Gloom Deacon** at his rally; **Mother Hush** at his side (story unit, ally until the turn) |
| Vessa (seat 0) / Ysolde (seat 1) | **Level 7** each; keeps at the Stronghold, halls, 6 workers each; Vessa 4 Flame Guards + 3 Ember Archers + 2 Blaze Riders, Ysolde 6 Thornlings + 3 Wildwood Archers + 1 Bramblesage |
| Story units | Dacian (`dacian_story`) at the Aurivane west gate, Seraphine at the Adamarch west gate (both step in at P2) |
| Dragons at 0:00 | **Kesh** with Aurivane (circling the Tollrock), **Morrow-of-Glass** with Malrik (circling the Admiralty), **Sunwake** on the roost (the 5:00 auction), **Ossavar** on the Master's chair (watching; untargetable until the turn) |
| No save / earlier missions skipped | Splinter, empty slots, essence 150 + 600; e7m3 flags false (no extras, 3 silver galleys); `e7m1_ossavar_won` false |

## Unlocks
| Kind | Available | Locked |
|---|---|---|
| Buildings | Snow Lodge, Frost Hall, Rime Spire, Ice Wall (16), Frost Bazaar (built) | Stables, Lair, research |
| Units | Rime Hauler; Frost Hall Z X C V N M `,`; keep C Shardguard, B Rimecarver; Caravan (max 4) | Frostbow, Rimehorn Rider, trained titans |
| Helper | Aldra (revive at the skirmish price) | - |
| Gold | Wares, exchange, **one bid** (Sunwake, 5:00), after the turn **Pay home** (6.3) | - |

### 6.3 Bids and pay-offs (the `DragonAuction` node of e7m1, two new uses)
| Use | Rule |
|---|---|
| **A-Sunwake** (P1, 5:00) | The e7m1 auction rules (45 s window, the rock's word, Aurivane's ceiling **600** normal). Won: Sunwake fights for side 0 until the Two Skies. Lost: for Aurivane until then. Either way she goes to Malrik at P2 |
| **Pay home** (P4 and P5, from the turn) | The Frost Bazaar card shows one button per dragon bonded to Malrik: **C `Pay Kesh home (400)`**, **V `Pay Morrow home (500)`**, **N `Pay Sunwake home (450)`** (normal). Click = spend the gold at once; the dragon breaks off, climbs, and flies out of the map to the north (it never returns, it is not killed); `sec_dragons` counter. Refusals `"Not enough gold"`, `"No Bazaar"`. Ossavar's line on the first (L29) |
| Gold after the turn | The Diamond Harbour route stays (near: 24 / trip); the Admiralty Quay becomes Malrik's (held post: caravans on that route wait 45 s and come home empty, so the player re-routes); the **toll** +30 / min for the Tollrock's owner |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_rock` | Primary (P1) | `Take the Tollrock` | Side 0 owns the Tollrock point (15 s) **or** 11:00 (time cap: Malrik's purchase starts P2 anyway) |
| `obj_truce` | Primary (P2) | `Guard the truce on the sand (0:40)` | 40 s pass (it always does: the beat before the turn) |
| `obj_hold` | Primary (P4, from the turn) | `Hold the Tollrock against Malrik` | Never "done" on its own; **fails** if Malrik's side owns the Tollrock point for **30 s in a row** = defeat |
| `obj_still` | Primary (P5, from **21:00**) | `Still the sea at the lighthouse (0 / 3)` | 3 channels done = victory |
| `obj_torvald` | Primary, always shown | `Torvald must survive` | Fails = defeat |
| `sec_red` | Secondary (P1) | `Sink Aurivane's crimson galleys (0 / 3)` | 3 sunk before P2 (they flee at P2) |
| `sec_dragons` | Secondary (from the turn) | `Pay Malrik's dragons home (0 / 3)` | 3 paid off |
| `sec_silver` | Secondary (from the turn) | `Sink Malrik's silver galleys (0 / 3)` (0 / 2 if `e7m3_people`) | All sunk (frozen ones can still be sunk) |
| `meter` | Panel item (from the turn) | `The stone's hunger 0 %` | D9 (not an objective) |

## Phases, waves and the bots (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
### P1 "The Full Strait" (0:00 to the Tollrock, at most 11:00)
| Group / wave | Trigger / where | Units | Order / value |
|---|---|---|---|
| G1 Tollrock garrison | `(0, 6)` ring r 4 + an Ember Spire `(0, -12)` | 4 Gilded Spears + 3 Flame Guards + 2 Ember Archers + 2 Thornlings | 1 060 + spire |
| G2 South Causeway foot | `(0, 30)` | 3 Gilded Spears + 2 Wildwood Archers | 530 |
| Crimson galleys | CG-W / CG-M / CG-E | 3 galleys (6.2) | Broadsides on the north shore |
| W1 Vessa's riders | **3:30** | **Vessa** + 4 Blaze Riders | Gold Shoal -> caravans, Haulers; Vessa retreats under 35 % |
| A-Sunwake | **5:00** | Auction (6.3) | - |
| W2 Ysolde's grove | **6:00** | **Ysolde** + 6 Thornlings + 3 Wildwood Archers + 2 Vinelashers + 1 Bramblesage | Silver Shoal -> Malrik's Dusk Keep (Malrik defends; the player may ping help) |
| W3 the sun's column | **8:30** | **Vessa** + 6 Flame Guards + 3 Ember Archers + 2 Pyre Adepts + 1 Kilnwarden | South Causeway -> Tollrock -> North Causeway -> Diamond Harbour |
**Malrik in P1** (Supportive ally, profile `mission_e7_04_ally`): defends, answers pings, **one scripted push**: at 7:30 his army
walks to the North Causeway foot `(0, -30)` and attacks the island with the player (it never spends side gold). Hush escorts him.
**Aurivane bots** (`mission_e7_04_enemy`): normal knobs, `min_attack_pop` 99, 10 soldiers at the rally, waves only.

### P2 "Two Skies" (the Tollrock taken, or 11:00)
Cutscene `e7m4_two_skies` (PAUSE 0:25). After it: every dragon is Malrik's (Kesh, Morrow, Sunwake circle the Admiralty), the
crimson galleys turn south and leave (unsunk ones despawn at the south edge), **all of Aurivane's field units walk home**
(the withdraw rule of D3 starts now for seats 0 / 1), Dacian and Seraphine walk onto the sand with a white cloth and stand at
the chair; `obj_truce` 0:40. Every side-0 and Malrik unit on the island is pushed out of the sand ring r 8 (the Laurel rule).
### P3 "The Turn" (obj_truce done)
Cutscene `e7m4_turn` (PAUSE 0:35). Effects in this order: seat 3 -> side 1 (D3); Hush and Malrik's field units walk to
`(36, -44)` for **10 s** (no attacks either way: the grace, shown as `Malrik pulls back to his harbour`); Ossavar becomes a
side-0 story titan (D4); Dacian and Seraphine become side-0 story allies (kneel rule, they hold the sand); the silver galleys
spawn and start their broadsides after **20 s**; `obj_hold`, `sec_dragons`, `sec_silver`, the meter appear. Aurivane's bots
stay paused for the rest of the mission; Vessa and Ysolde stand at their keeps.
### P4 "Hold the Rock" (the turn to 21:00)
Times are **after the turn** (`T`), normal run T ≈ 10:30. Malrik's waves spawn at his Gloom Hall `(58, -68)` (Dusk Keep if the
hall is gone; the silver galleys' decks, half size, if both are gone). Values: Malrik / Hush on top as wizards.
| Wave | Trigger | Units | Order |
|---|---|---|---|
| M1 | T + 1:30 | 6 Shades + 3 Nightbolts + 1 Shadow Knight + 1 Gloom Deacon (1 130) + **Kesh** | North Causeway -> the Tollrock point |
| M2 base raid | T + 3:00 | 6 Grave Hounds + 4 Barrow Ghouls (660) | Shore road west -> Rime Haulers, then the Frost Bazaar |
| M3 | T + 4:30 | **Malrik + Hush** + 6 Shades + 3 Hexweavers + 2 Hollow Oathsworn (1 195) + **Morrow** | North Causeway -> the Tollrock point, then Torvald |
| M4 base | T + 6:00 | 2 Shadow Knights + 4 Shades + 3 Nightbolts (1 220) + **Sunwake** | Shore road -> the Rime Keep |
| M5 | T + 7:30 | 8 Shades + 4 Nightbolts + 2 Shadow Knights + 2 Hexweavers + 1 Gloom Deacon (2 040) + every dragon still bonded | Tollrock point |
| M6 raid | T + 9:00 (if before 21:00) | 4 Grave Hounds + 3 Barrow Ghouls (460) | The caravans, then the Haulers |
Dragons still bonded to Malrik and not in a wave circle the Admiralty and join the next island wave. A dragon at 15 % HP rests
60 s on the Admiralty spire and comes back (only a pay-off removes it).
**Malrik's seat after the turn** (profile `mission_e7_04_malrik`): gathers, trains up to 12 soldiers at his rally, defends his
base (rule 1), rebuilds his Gloom Hall once, launches nothing of his own (only the waves above). Malrik follows M3 and M5 and
the Final; otherwise he stays at his rally. His keep and hall can be destroyed (not needed; D in the M-table spawn rule).

### P5 "Still the Sea" (from 21:00)
At **21:00** (or T + 10:30, whichever is **later**) `obj_still` appears; L34. Channel rules in D6. Stage order: **West, East,
Moat**. Each stage start launches its wave:
| Stage | Wave on stage start | Units | Order |
|---|---|---|---|
| 1 West | S1 | 6 Shades + 2 Barrow Ghouls + 2 Nightbolts (800) | North Causeway -> Torvald |
| 2 East | S2 base raid | 4 Grave Hounds + 2 Shadow Knights (880) | Shore road -> the Rime Keep |
| 3 Moat | **Final** | **Malrik + Hush** + 8 Shades + 4 Nightbolts + 2 Hollow Oathsworn + 1 Shadow Knight (1 680) + every dragon still bonded | Torvald, refreshed every 2 s |
A stage done = its third's water turns to glass (VFX), the galleys there freeze silent, Malrik's units in that band are
`chill`ed 6 s; 30 s later the next stage can start (the ring on the lighthouse turns from grey to gold). The third stage done
= **victory**: every enemy unit on the map is `frozen` 3 s (the sea's hush), cutscene `e7m4_still`.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (`c_e7_pits` played before, then the briefing.) Cinematic `e7m4_dawn` (HOLD 0:15); L1-L5; hint `Crimson galleys shell the shore. Shardcasters on the bank, Frost Mortars and Rime Spires reach them; melee cannot.` (10 s) |
| E2 | W1 (3:30) | L6-L7 |
| E3 | 4:30 | L8 (the auction in 0:30) |
| E4 | A-Sunwake hammer | L9 / L10 |
| E5 | W2 (6:00) | L11-L12 |
| E6 | First crimson galley sunk | L13 |
| E7 | Tollrock taken by side 0 (or 11:00) | L14; `obj_rock` done; P2 |
| E8 | P2 cutscene `e7m4_two_skies` | L15-L19 |
| E9 | `obj_truce` done | Cutscene `e7m4_turn`: L20-L24, then L25 (+L25b), L26; P3 effects |
| E10 | Turn + 0:30 | L28 (Aldra's pay-off hint) and the hint `Dragons serve whoever filled the hoard last. Select the Frost Bazaar: C / V / N pay them home.` (10 s) |
| E11 | M1 | L27 |
| E12 | First dragon paid home | L29; `sec_dragons` counter |
| E13 | M3 | L30-L31 |
| E14 | First silver galley sunk | L32 (Brannet if `e7m3_people`, else Aldra's variant) |
| E15 | Meter 50 % (first time) | L33 (Obren); Hollow Surge |
| E16 | Meter 100 % | L33b; the next wave now (+25 %) |
| E17 | 21:00 (P5) | L34; `obj_still` active; the lighthouse ring |
| E18 | Stage 1 done | L35 |
| E19 | Stage 2 done | L36 |
| E20 | Stage 3 starts | L37-L38 |
| E21 | Stage 3 done | Cutscene `e7m4_still` (PAUSE 0:30): L39-L40; `Events.mission_ended(true)` at its end; StoryFlow -> `ep7_ending` |
| E22 | Torvald dies | L41; defeat after 3 s |
| E23 | Malrik owns the Tollrock 30 s in a row (after the turn) | L42; defeat after 3 s |
| E24 | Rime Keep destroyed | Defeat after 3 s |
| E25 | Hush falls to 25 % (each time) | L43 the first time; she flees to Malrik's harbour, returns once after 90 s |

## Dialogue (47 lines, 4 of them flag variants; 5 s each unless listed)
Speakers (all exist or are added by E7M1.O1 / E7M3.O1): `torvald`, `aldra`, `malrik`, `hush`, `obren`, `vessa`, `ysolde`,
`ossavar`, `dacian`, `seraphine`, `brannet`, `diamond_archon`. **No new speaker.** Colours and names as e7m1 / e7m3.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | ossavar | The Year of Two Skies comes round again. Every ship. Every dragon. One strait. (6 s) |
| L2 | E1 | malrik | Today we finish Aurivane, Torvald. Take the rock. I will handle the sky. |
| L3 | E1 | torvald | You handled the Laurel too, Malrik. I have not forgotten whose knives they were. |
| L4 | E1 | malrik | Then remember it after we win. Victory is a wonderful eraser. |
| L5 | E1 | aldra | Crimson sails on the water. They will shell the shore road. Sink them, or stay off it. |
| L6 | E2 | vessa | Last chance to pick the right side, Torvald! I'm told I'm very forgiving! |
| L7 | E2 | torvald | You are told many things, Vessa. Most of them by people standing behind you. |
| L8 | E3 | ossavar | One small sale before the great one. Sunwake, Aurivane's pride. Who pays? |
| L9 | E4 won | torvald | Sunwake flies with us. For the morning, at least. |
| L10 | E4 lost | ossavar | Sunwake keeps her old masters. For now. |
| L11 | E5 | ysolde | Malrik! Every grave you dig, I will plant over. Every single one! |
| L12 | E5 | malrik | Then you will be a very busy gardener, Ysolde. |
| L13 | E6 | aldra | One red sail under. The sea keeps the coin, as usual. |
| L14 | E7 | seraphine | The rock is Adamarch's! The Archon is watching from the spire, Ice-king. So is everyone. |
| L15 | E8 | diamond_archon | Empty the pits. All of them. Let the sky be white and silver by noon. |
| L16 | E8 | ossavar | Every dragon on the Coinwater changes sides in one morning. I have seen this before. (6 s) |
| L17 | E8 | vessa | He bought the whole SKY? Ysolde, pull back! Everyone, back to the ships! |
| L18 | E8 | dacian | Enough. Seraphine, the cloth. We end this on the sand, the old way. |
| L19 | E8 | seraphine | A truce, Sunblade. No bets. No knives. Just us. |
| L20 | E9 | malrik | Burn them. Both fleets, the sand, the cloth. A strait of dead feeds the stone for years. |
| L21 | E9 | obren | Yes, Bishop. A whole sea of them. Feed me, and I will crown you king of the deep. |
| L22 | E9 | torvald | No. |
| L23 | E9 | malrik | You said that once before, in your hall. "For now," you said. |
| L24 | E9 | torvald | I am done waiting, Malrik. Aldra. Everyone. To the rock. |
| L25 | E9 (`e7m1_ossavar_won`) | ossavar | You paid me once, Ice-king, in clean coin. That bond still holds. I fly with you. (6 s) |
| L25a | E9 (not won) | ossavar | You never bought me, Ice-king. That is why I will fly with you. |
| L25b | E9 (`e7m3_people`) | ossavar | And you sheltered the Outwall when nobody paid. I remember debts. |
| L26 | E9 | vessa | Torvald? You're fighting HIM? ...Fine. Aurivane stands down. Don't make me regret it. |
| L27 | E11 | malrik | Kesh. Morrow. Sunwake. I filled your hoards to the brim. Earn them. |
| L28 | E10 | aldra | My lord, the Bazaar. A dragon serves whoever filled the hoard last. Pay them to fly away. |
| L29 | E12 | ossavar | Paid to go home. The one price he never tried. (5 s) |
| L30 | E13 | hush | There is always another night, Ice-king. Tonight it is yours. |
| L31 | E13 | torvald | Then I will spend it awake. |
| L32 | E14 (`e7m3_people`) | brannet | Those oars were ours! Nobody from the Outwall rows for the candle-man! |
| L32b | E14 (else) | aldra | Silver sinks the same as crimson, my lord. Slower, perhaps. Heavier pride. |
| L33 | E15 | obren | More, Bishop. The sea is generous tonight. |
| L33b | E16 | malrik | Do you hear it, Torvald? Every one of them is mine now. Every single one. |
| L34 | E17 | ossavar | He walked out once, and the sea went still. Your turn, Ice-king. Go to the light. (6 s) |
| L35 | E18 | aldra | The west water is glass. Their galleys are stuck fast. |
| L36 | E19 | seraphine | The east is frozen! Dacian, back to back! |
| L37 | E20 | malrik | Torvald! You never said no to anyone in your life. Why start with me? |
| L38 | E20 | torvald | Because I finally saw what you were buying. |
| L39 | E21 | torvald | Enough. |
| L40 | E21 | ossavar | I have heard that word once before. It sounded better from you. |
| L41 | E22 | torvald | The sea... was never mine to hold. |
| L42 | E23 | aldra | The rock is his. The stone will drink the whole strait now. |
| L43 | E25 | hush | The Bishop sends his regrets. I will deliver them in person, later. |
Echoes: L22-L24 answer ep1 C1 ("No. For now.") and pro. S24 ("he waits too long"); L39 is the Master's one public word (e7o
H14) in Torvald's mouth, and L40 says so; L29 closes the Master's third experiment (e7o 1); L20-L21 + D9 make Ep8's Hollow King
foreshadowing playable (campaign-outline 4.1: "every battle of this war has run down into the Hollow"); L25-L25b pay off e7m1
and e7m3. Every line <= 96 characters; Ossavar's longer lines get 6 s (marked).

## Cinematic hooks (ENGINE, skippable)
| id | Kind | When | Shots | Lines | Skip end state |
|---|---|---|---|---|---|
| `e7m4_dawn` | HOLD 0:15 | E1 | 1) The e7o H11 framing at dawn: CRANE up over the strait, crimson and silver galleys in battle lines; 2) MS Malrik and Torvald on the Diamond Harbour quay, Hush in Malrik's shadow; 3) long lens: Ossavar on the chair, the white cloth long gone | L1-L2 | Camera on Torvald; L1-L5 as dialogue |
| `e7m4_two_skies` | PAUSE 0:25 | E8 | 1) The Facet on the Admiralty spire throws its rainbow; diamonds pour from chests on the spire stair (the e7o P02 `diamond_pour`); 2) EWS sky: the e7o H10 "whole flock wheels in one curve", now **toward** Adamarch (Kesh, Morrow, Sunwake and a far flock); 3) MS Vessa on the South Causeway shouting (L17); 4) the sand: Dacian and Seraphine walk out from opposite gates with a white cloth between them (L18-L19) | L15-L19 | P2 state: dragons with Malrik, crimson galleys gone, Aurivane units walking home, the truce at the chair, `obj_truce` running |
| `e7m4_turn` | PAUSE 0:35 | E9 | 1) MS Malrik on the North Causeway, amber pulse up his arm, raising a hand to the circling dragons (L20); 2) ECU the stone (L21); 3) CU Torvald, 3/4, long hold, then L22; 4) OTS Torvald on Malrik (L23-L24); 5) WS: Ossavar rises from the chair, spreads his wings over Dacian and Seraphine, lands on the rim facing north (L25 / L25a / L25b); 6) MS Vessa on the south shore, lowering her staff (L26) | L20-L26 | P3 effects applied, the 10 s grace running, the galley timer at 20 s |
| `e7m4_still` | PAUSE 0:30, then victory | E21 | 1) TOP-DOWN crane up from the lighthouse: the last third of the moat turns to glass in a ring (the e7o `still_sea_ring` VFX, white-blue); 2) CU Torvald at the lighthouse, staff crystal blazing, L39; 3) WS on the glass: every soldier of every side stops, Malrik's dragons land on the ice heads bowed (the e7o H15 echo), Malrik alone standing on his frozen galley; 4) MS Ossavar on the chair (L40); FADE_WHITE | L39-L40 | `Events.mission_ended(true)`; StoryFlow -> `ep7_ending` |
Camera axes: the arena shots keep e7o's rule (cameras east of the north-south line through the chair). Fallbacks: lines as
dialogue, a 2 s pan, missing VFX skipped; the glass is a decal ramp over the water polygons.

### `ep7_ending` "No. Not for Now." (1:10, ENGINE; beats for its writer, task E7.D3)
Dawn on the stilled Coinwater, the whole strait glass. Torvald walks out across the ice to Malrik's frozen galley; Aldra a
step behind. Malrik, the stone dim in his hand: "So. No." Torvald: **"No. Not for now. Not ever."** (the title; the answer to
ep1 C1's "No. For now.") Malrik smiles thinly: "We will see who waits longer, Torvald." and steps down into the shadow of his
hull and is gone. Dacian and Seraphine sit on the rim beside the empty chair, sharing water from one flask (the ending's E21
image, younger). Ossavar lifts off the chair; over the ice, voice-over: "Gold for fire, they say. He paid in neither." He
flies north, toward the Master's empty sky (pro. S30). Last image: Torvald and Aldra on the ice, small, the sun coming up.
Title: `Episode 7 · Gold for Fire · End`. Speakers: `torvald`, `malrik`, `ossavar` (no new voice).

## Economy
| Item | Value |
|---|---|
| Start | 450 crystals (+0), 150 + carried essence, 0 gold (+600 if `e7m3_pits`), Bazaar + 2 caravans |
| Gold sources | Diamond Harbour 24 / trip all mission; Admiralty Quay 72 / trip **until the turn**; toll +30 / min; nothing else |
| Expected gold (normal) | ~**900** by the turn (~10:30; A-Sunwake 600 not bought) or ~300 if Sunwake was bought; then ~**250 / min** with 4 near caravans + toll -> ~**2 600** by 21:00 |
| Spending pressure | Pay-offs 400 + 500 + 450 = **1 350** for `sec_dragons`; wares (350 each); the exchange for crystals. The intended line: pay off **Kesh** before M1 and **Morrow** before M3 (the two island dragons), Gambesons with the rest; Sunwake (base raider) is held by the Rime Spires and Ossavar |
| Essence | carried + 150 + trickle ~1 500 + kills ~2 000 (~90 units + Malrik / Hush twice) = ~3 700 + carried: one top + one mid for Torvald by P5 |
| Malrik's side | His own nodes and the pits' diamonds (scripted: his waves do not depend on his economy) |

## Win / lose
| Event | Result |
|---|---|
| Still the Sea: stage 3 done | **Victory** (after `e7m4_still`; then `ep7_ending`) |
| Torvald dies | **Defeat** |
| Rime Keep destroyed | **Defeat** |
| Malrik's side owns the Tollrock point 30 s in a row (after the turn) | **Defeat** |
| Malrik dies | Not a win: `Malrik sinks into the shadows of his hull`; respawn 60 s |
| Hush at 25 % | She flees, returns once after 90 s |
| Ossavar / Dacian / Seraphine / Aldra / mammoths down | Ossavar rests 30 s on the chair; Dacian / Seraphine kneel 10 s; Aldra revives; a mammoth dies |
| Vessa / Ysolde killed before P2 | `... falls back to the Sun Gate`; 60 s respawn; after P2 they cannot be targeted (truce) |

## Reward (end of Episode 7; Torvald's track for Episode 8)
- New artifact **Ossavar's Ring** (`ossavar_ring`, `campaign_only`; the items row is for the items owner, campaign-outline C7):
  the gold ring from his broken horn, Aurivane's old pay, given to Torvald in `ep7_ending` ("The one price I ever gave back").
  Stats `max_hp` +120, `spell_power` +15; **Old Price** (passive, once per mission): when the wearer drops below **20 %** HP, a
  dragon-wing gust: enemies within 5 m knocked back 3 m and `dazed` 0.5 s, the wearer gets a **150** shield for 5 s. Icon `OR`,
  gold border. Ep8 equips the Stillwater Orb in slot 1 (campaign-outline 4.2) and this ring in slot 2 by default on Torvald's road.
- Splinter kept; 6 slots; essence 50 %, cap 1 500; **+300** if `sec_dragons`, **+200** if `sec_silver`, **+150** if `sec_red`.
- Flags: **`e7_turned`** (always on a win), `e7m4_dragons_paid` (0-3), `e7m4_galleys_sunk`, `e7m4_sunwake_won`,
  `e7m4_meter_peak` (the stone's hunger peak, 0-100: Ep8's Shadow road may read it as the stone's strength), `e7m4_time`,
  `episode7_complete`. Ep8's Ice road ("The Gate Opens") loads Torvald's track; `e7m3_people` adds its Outwall squad there.
- `MISSION_REWARDS[&"e7m4"] = {"flags": {...}, "bonus_essence": {"sec_dragons": 300, "sec_silver": 200, "sec_red": 150}, "items": [&"ossavar_ring"], "next": &"ep8"}`.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave / guard counts | x 0.6, no Shadow Knight in M2 / S2, no Hollow Oathsworn | as written | x 1.4 |
| Start | 600 crystals, +2 Rimeshields | as written | 350 crystals, 1 Frost Mortar |
| Wizards (Malrik, Vessa, Ysolde) | L6 | L7 | L8 (Malrik Lance r3, Siphon r3, Shroud r2 + items) |
| Rock lost after | 45 s | 30 s | 20 s |
| Channel per stage | 10 s | 15 s | 20 s |
| Pay-offs | 300 / 350 / 350 | 400 / 500 / 450 | 500 / 650 / 550 |
| Galley HP / broadside | 700 / 45 | 900 / 60 | 1 100 / 75 |
| Meter per death | 0.75 % | 1 % | 1.25 % |
| Expected time | 22-25 min | 25-28 min | 28-33 min |
Expected run on normal: W1 riders 3:30 -> galleys 3:00-8:00 (Mortars, Spires on the bank) -> A-Sunwake 5:00 (skip, save
gold) -> W2 Ysolde on Malrik 6:00 -> Malrik's push 7:30 -> W3 8:30 -> Tollrock ~9:30 -> P2 0:25 + 0:40 -> turn ~10:45 (0:35)
-> M1 12:45 (Kesh paid off ~12:00) -> M2 14:15 -> M3 15:45 (Morrow paid off ~15:00) -> M4 17:15 -> M5 18:45 -> 21:00 P5:
three stages ~21:00-23:00 -> cutscene -> **~24:00 + `ep7_ending`**, 27-28 with retakes.
**Fight sizing** (normal; <= 70 % rule; allies counted where they stand: Ossavar ~1 500, Dacian + Seraphine ~1 200, Aldra L6
~500, Malrik's army ~1 300 before the turn; enemy wizards at `170 + 30 x level` = 380, Hush ~650):
| Fight | Enemy | Player side then | Ratio |
|---|---|---|---|
| W1 riders (3:30) | 720 + Vessa 380 = 1 100 | ~2 900 | 38 % |
| G1 garrison + spire, with Malrik's push (~9:00) | 1 060 + G2 530 later | ~3 300 + Malrik 1 300 | 23-35 % |
| W3 (8:30) | 1 100 + 380 = 1 480 | ~3 400 | 44 % |
| M1 (T + 1:30) | 1 130 + Kesh 700 (or 0 if paid) | ~3 600 + Ossavar + Dacian / Seraphine + Aldra ~ 6 800 | 27 % (17 % paid) |
| M3 (T + 4:30) | 1 195 + Malrik 380 + Hush 650 + Morrow 650 = 2 875 | ~6 900 | 42 % |
| M4 base (T + 6:00) | 1 220 + Sunwake 700 | the base half: ~2 000 + Rime Spire + Aldra (Hold home) | 64 % of the half (the split) |
| M5 (T + 7:30) | 2 040 + bonded dragons (0-2 100) | ~7 000 | 29-59 % |
| Final (stage 3) | 1 680 + Malrik + Hush 1 030 + bonded dragons | ~7 000 | 39 % (69 % with all three dragons unpaid and the meter's +25 %) |
- The two skill checks: **the split** (Malrik's base is on the player's shore: M2 / M4 / S2 hit the base while M1 / M3 / M5 / S1
  hit the rock; Aldra on Hold home, Rime Spires, Ice Walls on the shore road and a Rimecarver Bulwark at the causeway are the
  answers) and **the money** (pay the island dragons home, or fight them under Ossavar).
- P5 is a protect-the-channeller fight like `mission-04.md`'s Turn the Key; the channel survives damage, so the answer is
  Rime Aegis + Glass Aegis + Shardguards around the lighthouse, and Flash Freeze on whatever reaches Torvald.
- Watch in the first playtest: if the turn feels unfair (units lost in the 10 s grace), raise the grace to 15 s; if
  `sec_dragons` is never done, lower Morrow to 450; if the Final with 3 dragons is a wall, cap the dragons in the Final at 2.

## Acceptance checks
1. A scripted headless run on normal (sink 2 galleys, take the rock, the turn, pay off Kesh and Morrow, hold, 3 stages) ends
   `victory=true` in **25-30 game-minutes** (cutscenes included, `ep7_ending` excluded) in 3 / 3 runs.
2. The side switch: after `e7m4_turn` every unit and building of seat 3 reads team ENEMY within one frame, its Commander uses
   `mission_e7_04_malrik`, side 0 loses its vision, and **no unit of either side attacks during the 10 s grace** (test).
3. Aurivane's withdraw: after P2 no seat-0 / seat-1 unit is on the field after 60 s, their buildings are untargetable and never
   attack, and their Commanders issue no order.
4. A pay-off spends the gold at once and removes the dragon from the fight for good (it leaves the map north); refused with
   `"Not enough gold"` otherwise.
5. A galley cannot be hit by melee, can by ranged / towers / spells; a frozen galley never fires again.
6. The Tollrock owned by Malrik's side for 30 s in a row after the turn = defeat; 29 s then retaken = no defeat.
7. Still the Sea: leaving 3 m resets the stage, damage does not; a stage cannot start within 30 s of the last; the third ends
   the mission with every enemy `frozen` 3 s.
8. The stone's hunger: +1 % per death in `|z| <= 30` after the turn; 50 % -> Hollow Surge 60 s; 100 % -> the next wave now at
   +25 % and the meter back to 50 %.
9. The flags `e7m1_ossavar_won`, `e7m3_people`, `e7m3_pits`, `e7m3_mammoths` change the start and lines as listed (4 test saves).
10. Every line <= 96 characters; every WAV fits; `PERF OK` with M5 + 3 dragons + Ossavar + 3 galleys + both fleets' decor.

## Implementation tasks (proposed ids)
| Id | Owner | What | Done when |
|---|---|---|---|
| E7M4.S1 | systems | `missions/mission_e7_04.tscn` + `MissionE7_04` on `two_harbours.map`: 4 seats, start state with e7m3's hand-offs and the no-save fallback, galleys (floating targets, melee-immune, broadsides, freeze), the lighthouse channel (3 stages, 30 s gate, west / east / moat bands), the stone meter, pay-off buttons on the Bazaar | `tests/test_e7m4_s1.gd`: galley rules; a stage channel resets on leaving; the meter's thresholds |
| E7M4.S2 | systems-high [H] | **`MissionBase.switch_seat_side(seat, side)`** (team of every unit / building, Commander profile swap, vision cut, the grace walk) and **`MissionBase.withdraw_seat(seat)`** (Commander pause, units to the gates and `leave_map`, buildings truce + invulnerable); phases P1-P5, events E1-E25, waves, win / lose (incl. the 30 s rock rule), difficulty, rewards with `ossavar_ring` and `episode7_complete` | `tests/test_e7m4_s2.gd`: checks 2, 3 and 6; a scripted run wins |
| E7M4.G1 | gameplay | `sunwake` (a `gilt_dragon` variant); Ossavar's ally brain flag (dragons first; rest on the chair); Hush's flee-and-return-once; the `galley` target type; `ossavar_ring` hooks if gameplay-side (knockback / daze / shield) | Unit tests |
| E7M4.A1 | ai | Profiles `mission_e7_04_ally` (P1 Malrik + the 7:30 push), `mission_e7_04_enemy` (Aurivane P1), `mission_e7_04_malrik` (after the turn: defend, 12 soldiers, rebuild the hall once, waves only); the `AuctionDragonBrain` ownership swap at P2 / the turn; Malrik follows M3 / M5 / the Final | The Commander swap leaves no stale order on a unit of seat 3 |
| E7M4.I1 | items | `ossavar_ring` ItemType (artifact, campaign_only, Old Price once per mission) | Test: below 20 % triggers once; a second drop does nothing |
| E7M4.U1 | ui | Phase banner, `obj_truce` / `obj_hold` (the 30 s rock-lost bar) / `obj_still` (stage ring with the 30 s gate), the stone meter (amber, pulses at 50 / 100 %), pay-off buttons with dragon portraits, the side-switch toast (Malrik's portrait turning red in the 2v2 strip), galley markers on the minimap | UI Lab screens |
| E7M4.C1 | systems-high | `e7m4_dawn`, `e7m4_two_skies`, `e7m4_turn` (three Ossavar takes), `e7m4_still` + skip end states; StoryFlow `c_e7_pits` -> briefing -> e7m4 -> `ep7_ending` -> Episode 8 menu | `cine check` 0 FAIL |
| E7M4.V1 | tech-artist [H] | Galleys as game units (crimson / silver, damage and sink states, frozen look), the glass-sea freeze (three water bands, decal ramp + `still_sea_ring` at game scale), Sunwake recolour, the diamond pour on the spire, Ossavar's chair-rest pose; 0 lights | Art Lab pass; `PERF OK` |
| E7M4.O1 | Voice Forge agent | Render the 47 lines (3 Ossavar variants at the turn) | Every WAV fits |
| **E7.D3** | game-designer | Write `ep7_ending` (1:10, `episode7-opening.md` script + shot-list format) from the beats above; read the e7m4 lines in game | Script done, CPS checked |
| E7.F1 | four-wizards-high | `ep7_ending` cine + set reuse (`forge_tollrock` with a frozen-sea `water` variant) | `cine check` 0 FAIL |
| Lead | lead | Acceptance checks 1-10 | All pass |
Dependencies: everything of e7m1-e7m3; the 2v2 seat API (step 20) **plus** the two new `MissionBase` calls of E7M4.S2 (this
is the first mission where a seat changes side; later missions may reuse both, e.g. Ep8's allied wizard bots); `DragonAuction`
(E7M1.S2); the truce flag (E7M2.S2); the helper code (step TH).

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Shardguard (first trained e7m2).
- **Why here:** every kind of charge and dive: 4 Blaze Riders (W1), 6 Grave Hounds (M2), M6; Hold the Line stops charges and taunts divers.
- **Moment:** M2 after the Turn: "Shardguards beside the Shardcasters: Hold the Line.".
- **Intro card:** `Shardguard. The halberd that says no: charges stop, divers turn, archers live.`

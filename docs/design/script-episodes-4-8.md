# Story script, Episodes 4-8: index

Written 2026-10-08 (second pass; the first pass wrote the per-mission files the same night). Status: **script only**.
Nothing voiced, no `.cine` written, no lines file moved to `data/voice/lines/` yet. Every per-mission file in
`docs/design/script-episodes-4-8/` holds: the in-mission films (shots and line placement), the between-scene or
episode film it owns (shot list), its open questions (section 3), and a generated lines table. The lines themselves are
in `docs/design/script-episodes-4-8/lines/<id>.json` (data/voice/lines format) and the French stub is
`data/i18n/fr/story_e4_e8.po` (not yet reviewed by a French reader). Episode 7 also has a summary of its own,
`docs/design/script-episodes-4-8/e7-summary.md`.

To go live, per film: move `lines/<id>.json` to `data/voice/lines/`, move its French into `data/i18n/fr/dialogue.po`,
add the cast entries below, render the voices, write the `.cine`.

## 1. Episodes, missions, films, line counts

Line counts are the number of entries in each lines JSON (incl. variant takes and outcome lines; a player hears only
one branch). "Q" = rows in the file's open-questions table; "open" leaves out the ones fixed or decided in the
second pass.

### Episode 4 "What Grows Back": 180 lines, 20 Q (20 open)
| Mission / film | Script file | Lines |
|---|---|---|
| `e4m1` "Hold Lark Hill" + films `e4m1_horn`, `e4m1_foot`, `e4m1_nightfall`; between-scene `c_e4_refuge` | `e4m1.md` | 39 + 13 |
| `e4m2` "The Green Road" + `e4m2_lantern`, `e4m2_hush`, `e4m2_border`; `c_e4_turnback` | `e4m2.md` | 31 + 12 |
| `e4m3` "The Frozen Ashes" + `e4m3_arrival`, `e4m3_aldra`, `e4m3_shoot`, `e4m3_spring`; `c_e4_frontier` | `e4m3.md` | 30 + 11 |
| `e4m4` "Winter's End" + `e4m4_arrival`, `e4m4_wardens`, `e4m4_thaw`, `e4m4_enough`; episode ending `ep4_ending` | `e4m4.md` | 37 + 7 |

Top 5 open: (1) `c_e4_refuge` L1 "Every family made it up the hill" is true only with all 30 saved: second take or
reword (`e4m1.md` Q1). (2) The Wall: raised new, or an old wall raised again (`e4m3.md` Q2), and who ordered it
(Q1). (3) `ep4_ending`: does the heart-stone speak (Obren line) or stay wordless (`e4m4.md` Q1; Ep5 keeps it silent,
`e5m3.md` Q1). (4) Vessa "kept" the pod since `c_e2_ashes`: does any scene show it (`e4m2.md` Q4). (5) Does Ysolde
know it was Hush who burned the wagons (`e4m1.md` Q2).

### Episode 5 "The Spark and the Candle": 141 lines, 40 Q (40 open)
| Mission / film | Script file | Lines |
|---|---|---|
| Episode opening `ep5_opening` (recap + the four childhoods); `e5m1` "The First Spark" + `e5m1_valley`, `e5m1_watch` | `e5m1.md` | 31 + 26 |
| `e5m2` "Burn a Door" + `e5m2_rookhold`, `e5m2_door`, `e5m2_morning` | `e5m2.md` | 25 |
| `e5m3` "Tombstones by Candlelight" + `e5m3_wickmoor`, `e5m3_found`; between-scene `c_e5_turn` | `e5m3.md` | 26 + 2 |
| `e5m4` "Leftovers" + `e5m4_green`, `e5m4_bell`; episode ending `ep5_ending` | `e5m4.md` | 23 + 8 |

Top 5 open: (1) Cine id clash: `episode7-opening.md` still calls its film `ep5_opening` (`e5m1.md` Q12; see Ep7).
(2) New lore in `ep5_opening`: Vessa's barn fire at six, Vey's sword-knot, Malrik's night in the crypt, the stolen bread
(`e5m1.md` Q4, Q5, Q7, Q8). (3) Who narrates the opening's blocks: the grown wizards in voice-over, the Master only
inside memories (`e5m1.md` Q3). (4) Who picks the cities: Vessa takes the gold one herself vs `episode7-opening.md` D10
"the Master gave" (`e5m4.md` Q1). (5) `ep5_ending` ends on a present-day tail into Ep6, not straight into Ep7's memory
(`e5m4.md` Q4).

### Episode 6 "The Lake and the Seed": 161 lines, 32 Q (32 open)
| Mission / film | Script file | Lines |
|---|---|---|
| Episode opening `ep6_opening`; `e6m1` "A Hundred Winters" + `e6m1_heartfrost`, `e6m1_return`; `c_e6_lake` | `e6m1.md` | 28 + 31 + 7 |
| `e6m2` "The Rider at the Gate" + `e6m2_rider`, `e6m2_dawn_open`, `e6m2_dawn_shut`; `c_e6_gate` | `e6m2.md` | 31 + 3 |
| `e6m3` "The Year Nothing Grew" + `e6m3_spring`; `c_e6_seed` | `e6m3.md` | 25 + 5 |
| `e6m4` "The First Crack" + `e6m4_crack`, `e6m4_first_crack`, `e6m4_down`; episode ending `ep6_ending` | `e6m4.md` | 27 + 4 |

Top 5 open: (1) New lore: Torvald's origin (the beacon boy on the pass) (`e6m1.md` Q2). (2) Line slots overrun their
films (`e6m1_heartfrost` 36 s in 0:30, `e6m2_rider`, `e6m4_crack` / `_first_crack`): lengthen or let lines run past
the cut (`e6m1.md` Q8, `e6m2.md` Q3, `e6m4.md` Q4). (3) `c_e6_gate` open branch decides Hearthwick still stands today
(`e6m2.md` Q6). (4) `ep6_opening` / `ep6_ending` have no `episode6-opening.md`; ER1's dates (`e6m1.md` Q11). (5) How
the Master gets from the isle to the citadel the same night (`e6m4.md` Q6).

### Episode 7 "Gold for Fire": 190 lines (+ `ep7_opening`, no lines file yet), 34 Q (32 open)
| Mission / film | Script file | Lines |
|---|---|---|
| Episode opening `ep7_opening` (script in `episode7-opening.md` 3-4, not rewritten; still headed `ep5_opening`, "Episode 5", 3:23: see `e7m1.md` Q1) | - | (34 in the script) |
| `e7m1` "The Dragon Auction" + `e7m1_arrival`, `e7m1_laurel`, `e7m1_dusk`; `c_e7_ledger` | `e7m1.md` | 41 + 10 |
| `e7m2` "First Blood, and No Further" + `e7m2_morning`, `e7m2_herald`, `e7m2_laurel_call`, `e7m2_knives`, `e7m2_mask`; `c_e7_mask` | `e7m2.md` | 33 + 9 |
| `e7m3` "The Outwall" + `e7m3_outwall`, `e7m3_boats`, `e7m3_unmask`, `e7m3_dawn`; `c_e7_pits` | `e7m3.md` | 32 + 12 |
| `e7m4` "The Year of Two Skies" + `e7m4_dawn`, `e7m4_two_skies`, `e7m4_turn`, `e7m4_still`; episode ending `ep7_ending` | `e7m4.md` | 47 + 6 |

Decided in the second pass: **the Year of Two Skies is war year 612, ~390 years ago** (`episode7-opening.md` 2).
To fix by the spec owners (flagged in `e7m3.md` Q1, `e7m4.md` Q8; specs not changed): `mission-e7-04.md` story setup
"Six hundred years ago"; `mission-e7-03.md` / `c_e7_pits` L4 "My great-grandmother did that once".

Top 5 open: (1) `ep7_opening` has no lines file, `.cine` or French, and its chronicle still says "Last year: the
Master vanishes" (outline C1 wants twelve years) (`e7m1.md` Q1). (2) The "For now" thread: who said it in `c1_offer`
(`e7m2.md` Q2, `e7m4.md` Q1). (3) The 200 stamped coins Aldra stacks were normally spent on the A2 bid (`e7m1.md` Q2).
(4) Which outcome gets which Ossavar take in `c_e7_pits` (`e7m3.md` Q2). (5) `ep7_ending`: Ossavar's gold ring
dropped at Torvald's feet is new staging (`e7m4.md` Q2).

### Episode 8 "The Four Keys": 273 lines (6 of them pointer rows, not played), 34 Q (30 open)
| Mission / film | Script file | Lines |
|---|---|---|
| Episode opening `ep8_opening`; `e8m1` "The Four Roads" (one road per playthrough): `e8m1_fire` / `_shadow` / `_ice` / `_nature` + 10 films (`e8m1_fire_stakes`, `_fire_storm`, `_shadow_home`, `_shadow_father`, `_shadow_hush`, `_shadow_stair`, `_ice_gate`, `_ice_south`, `_nature_road`, `_nature_out`) | `e8m1.md` | 14 + 26 / 26 / 22 / 21 |
| `c_e8_muster` (between-scene); `e8m2` "The Last Muster" + `e8m2_seats`, `e8m2_hand`, `e8m2_turn` | `e8m2.md` | 8 + 51 |
| `e8m3` "The Hollow King" + `e8m3_king`, `e8m3_walk`, `e8m3_chains`, the Master's lance (VFX) | `e8m3.md` | 49 |
| Closing film `ep8_ending` "Four Hands": `ep8_ending_a`, `ep8_throne_<k>` (x4), `ep8_ending_b` (canon) or `ep8_dark_<k>` (x4, on "Take the seat"), `ep8_bookend`; then `ep8_credits` (not written) | `e8m3.md` | 20 + 4 + 13 + 12 + 7 |

Pointer rows (`<W>` / bot sets, kept in the lines JSON, marked "pointer, not played" in the md; the playable lines are
the `_<k>` extras): `e8m2` L9, L39; `e8m3` L10, L11, L13, L28.

Fixed in the second pass: the bookend reuses the prologue's **L13** ("I know this tale well, child. I was that
wizard.", 5.2 s), not L12; it now overlaps the child's E24 line, timing options in `e8m3.md` Q2. `e8m2` L3 "Fire takes
the south-west" -> "Fire takes its bank" (true on all four roads; `e8m2.md` Q10). Stage directions removed from the
spoken text of `e8m1_nature` L3, `e8m2` L34 / L38, `e8m3` L19 and moved to the shot notes (the specs and
`campaign-outline.md` 4.3 "pro. L12" still need the same fix).

Top 5 open: (1) How the relics travel back (`e8m1.md` Q1). (2) Where the Master's door is: under Crown Hollow or under
Emberfall (`e8m1.md` Q3). (3) `ep8_credits` and the end panel text (`e8m3.md` Q3). (4) The bookend WAV timing: let L13
cross the cut or grow E23 by 4 s (`e8m3.md` Q2). (5) On the Shadow road, Malrik "arrives last" at the muster but is the
player's wizard who walks up first (`e8m2.md` Q7); also Vey says "Especially Malrik" twice in one episode
(`e8m1.md` Q4).

### Totals
945 lines in 51 lines files (180 / 141 / 161 / 190 / 273), 939 playable (6 pointer rows). 160 open-question rows,
154 still open. 64 in-mission films (35 HOLD, 29 PAUSE; plus the Master's lance VFX), 11 between-scenes, 8 episode opening / ending
films (`ep8_ending` split in 11 lines files; + `ep7_opening` unconverted, `ep8_credits` unwritten).

## 2. Speakers still needing a cast entry (`data/voice/cast.json`)
| Speaker | Lines | Where | Note |
|---|---|---|---|
| `rider` | 6 | `e6m2` | Bren of Hearthwick; spec E6M2.O1 gives the blend |
| `gannet` | 9 | `e5m1`, `e5m2` | spec E5.O1 auditions |
| `reeve` | 4 | `e5m3` | spec E5.O1 |
| `herald` | 5 | `e7m1`, `e7m2` | |
| `dacian` | 8 | `e7m1`, `e7m2`, `e7m4` | |
| `seraphine` | 14 | `e7m1`..`e7m4` | |
| `brannet` | 10 | `e7m3`, `e7m4` | E7M3.O1 voice proposal |
| `diamond_archon` | 8 | `c_e7_pits`, `e7m3`, `e7m4` | E7M3.O1 voice proposal |
| `ossavar` | 35 | all of Ep7 incl. `ep7_ending` (+ 21 in `ep7_opening`) | the Ep7 narrator (D11) |
| `child` | 3 | `ep8_bookend` | outline F7 auditions `am_puck` 1.15 / `af_sky` 1.2 / `bf_lily` 1.15 (not Wren's `bf_alice`) |

Also: `obren` needs a "full voice" take for `ep8_opening` (`e8m1.md` Q2).

## 3. Stand-in sets (no World Forge set yet)
| Needed set | Stand-in | Used by |
|---|---|---|
| Cinderwatch hall | `forge_ep2_feast` re-dressed | `c_e4_turnback`, `ep4_ending` |
| Emberwatch war room | the watch-keep court table of `c2_two_fronts` | `c_e4_frontier` |
| Emberfall in snow, farmyard, citadel yard / refectory / library, young Wickmoor | `forge_watch_keep`, `forge_intro_vessa`, `forge_citadel`, `forge_intro_malrik` | `ep5_opening`, `c_e5_turn` |
| Glasswater Mere | `forge_intro_torvald` frozen lake | `c_e6_lake`, `ep6_opening` |
| Frostgate (e6m2 map) | `forge_intro_torvald` ice gate + signal fire | `c_e6_gate` |
| "Under the earth" shaft | new rock-shaft dressing, perhaps in `forge_citadel` | `ep6_ending` |
| `forge_adamarch` (Diamond Harbour, war harbour, Hall of Silence), e7o galley | `two_harbours` map (itself not built) + `forge_intro_malrik` crypt kit / `forge_citadel` dome parts | `c_e7_ledger`, `c_e7_mask`, `c_e7_pits` |
| `adamarch_outwall` roofs | e7m3 map, else `forge_watch_keep` with shanty props | `c_e7_pits` |
| `forge_tollrock` + frozen-sea water | `two_harbours` map with e7m4's glass-sea decals | `c_e7_ledger`, `ep7_ending` |
| `forge_hollow_pit` | M4 Crown Hollow post-Rise pit | `ep8_opening`, `ep8_ending_a` / `_b`, `ep8_dark_<k>` |
| `forge_hollow_ridge` | a dusk ridge on the M4 Crown Hollow map | `c_e8_muster` |
| Duskbarrow | `forge_intro_malrik` crypt | `ep8_opening` |
| The dark under Crown Hollow | `forge_deep_door` (the `ep2_ending` Door cavern) | `ep8_opening` |
| Montage of the war | e4m4's broken Wall, `forge_coinwater_battle` | `ep8_opening` |
| T2 world image (the kingdom) | a matte / VFX plate; stand-in the wizard's prologue vignette set | `ep8_dark_<k>` |
| Ruined orrery dome | `forge_citadel` in a RUINED state (dressing) | `ep8_dark_<k>` T4, `ep8_bookend` |

## 4. Decisions JS must make
1. **`ep8_credits` text**: the credit roll (2:00) and the end panel text are not written (`e8m3.md` Q3); also the
   French of the title sub "The storm chooses its own." (`e8m3.md` Q4).
2. **The relic handover** in `ep8_opening`: the outline has Vessa give the Orb and the Signet back; the spec has the Orb
   arrive by letter and Ysolde already home. This pass sends both by rider (the Orb with one of Ashby's riders, the
   Signet with Wren) and keeps Torvald and Ysolde off-screen (`e8m1.md` Q1). Keep, or stage Vessa handing them over.
3. **The Master's door location**: under Crown Hollow (Ep8's story) or under Emberfall (`ep2_ending`, e2m4). The stand-in
   is `forge_deep_door` either way (`e8m1.md` Q3).
4. **Whether HOLD scenes exist**: 35 in-mission films are marked HOLD (tree running, units dormant, actors walking,
   `cinematics.md` 5), e.g. `e8m1_<k>` openers, `e8m2_seats`, `e8m3_king`. Most only crane and cut with no actor
   walking: keep HOLD (and its per-mission `hold_world` cost) or make them PAUSE.
5. **Voices for these lines**: nothing is rendered. Approve the 10 new cast entries (section 2), the `obren` full-voice
   take, and the order of renders (945 lines; 6 pointer rows are never rendered).
6. Also waiting on JS (smaller): the Year of Two Skies date fix in the two specs (picked: 612 / ~390 years); the
   `ep7_opening` rename and conversion (D2); the bookend WAV timing (`e8m3.md` Q2).

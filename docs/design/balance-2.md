# Balance pass 2: the 4 kingdoms (bot vs bot)

Task 8.D1. Written 2026-09-25 from the real data (`data/units`, `data/buildings`, `data/ai`, `scripts/ai/ai_profile.gd`,
`commander.gd`, `crystal_node.gd`) and the step 8 bot-vs-bot matrix (normal, 12-min cap). Same format as `balance-1.md`:
every change is `file / field: old -> new`. This file overrides the numbers in `kingdom-ice.md`, `kingdom-nature.md`,
`balance-1.md` and `ai.md` where they differ; those specs keep everything else.
Goal unchanged: a normal 1v1 lasts **15-20 min**, no kingdom wins every pairing.

## 0. The measurement (normal, cap 12:00; end army pop (max); crystals gathered)
| Pair | Result | Army end (max) | Crystals |
|---|---|---|---|
| fire : ice | Fire 10:45 | 28 / 0 (29 / 15) | 6 820 / 4 310 |
| shadow : nature | Nature 10:59 | 0 / 31 (11 / 32) | 4 390 / 7 560 |
| ice : nature | Nature 11:14 (rerun: no winner, 0 / 37) | - | ~4 500 / ~7 500 |
| fire : nature | no winner | 0 / 33 (10 / 37) | 4 660 / 7 890 |
| fire : shadow | Shadow 11:16 | 0 / 28 | 4 900 / 7 120 |
| shadow : ice | no winner | 25 / 0 (25 / 13) | 7 380 / 5 340 |
| nature : shadow | Nature 11:47 | 35 / 0 | 7 870 / 5 190 |
The Fire bot never casts (no Vessa bot rules yet, being added now): **Fire results are discounted**, Fire gets no change.

## 1. Diagnosis
| # | Problem | Evidence (data + matrix) |
|---|---|---|
| D1 | **Nature out-sustains everyone** | Verdant regen 1.5 % max HP / s after 4 s (Bramblehorn 3 %) on every Nature unit, + Bloomtenders (12 HP / 3 s), + Bramble Spire aura (+2 HP / s). No other kingdom's soldiers heal at all (the keep heal of `skirmish.gd` is wizards only). The Nature bot retreats at 50 % and relaunches after 30 s (`regrow_wait`), by then its army is back to ~80 %; the opponent's army is still at 40 %. Every exchange is free for Nature: opponents' max army is **10-15 pop** in 4 of 5 Nature games |
| D2 | **Nature out-mines everyone (1.6x)** | `nature_normal.tres` worker targets **7 / 10 / 13** vs 6 / 9 / 12 for the others. A node caps **miners at the node** (3), not workers on the trip (`crystal_node.gd`: ~6 workers saturate a node with a 4 s mine in an 8.5 s trip), so each extra worker is ~+70 crystals / min for the whole match. Plus 40-crystal workers, a 3-worker opening, X1 at 4:30. The rest of the 1.6x is **suppression**: D1 keeps the enemy army small, so its X1 waits for `own_strength >= 400` (camp alive) and its workers get raided by 5.4 m/s Thornlings |
| D3 | **Ice expands 2:00 late** | `ice_*.tres` `expand_time` **420** (7:00) and `expand_home_below` **700**: the 700 threshold predates balance-1 (home nodes now hold 4 000), so only the 7:00 timer fires. Everyone else expands at 5:00 (Nature 4:30) on the "half of the start" rule. Ice gathers 4.3-5.3k, the lowest of all |
| D4 | **Ice units were tuned against the pre-balance-1 Shadow** | CE (combat value per crystal, `kingdom-ice.md` 9): Shade 14.1 -> **18.9**, Shadow Knight 8.7 -> **13.2** after balance-1; Ice did not move: Rimeshield **17.3**, Rime Colossus **8.9** (the lowest CE of any heavy; the Ice mix is 20 % Colossus). Flame Guard 19.3, Thornling 20.6. Ice now loses per crystal to every kingdom and still trains 10-20 % slower |
| D5 | **Ice armies die to the last unit** | `retreat_hp` 0.3: the slowest army in the game (3.4-4.4 m/s) stays until 30 % and cannot walk out; end army **0** in all 4 Ice games |
| D6 | **Ice / Nature buildings missed balance-1** | The kingdom rule is "Ice +20 %, Nature -10 % building HP vs Fire", written when Fire's keep was 1 500. Fire / Shadow went to 2 500 / 1 300 / 500 / 750 (balance-1 2b); Ice is still 1 800 / 1 080 / 480 / 720 and Nature 1 350 / 810 / 360 / 540. Ice, the "hardest base to crack", has a keep 28 % weaker than Fire's |
| D7 | **Matches end at ~11 min** | Not the map: every game is a stomp (end armies 0 vs 25-37). The map math of balance-1 (nodes empty 10:30 / 17:30 / 21:00) only lengthens games when both armies survive fights. Fix D1-D6 and even pairs reach the natural and rich nodes; buildings of the two new kingdoms (D6) then hold as long as Fire / Shadow ones |

## 2. Changes (apply mechanically; `file / field: old -> new`)
### 2a. Nature: less free sustain, same worker count once expanded (gameplay 8.B1, ai 8.B3)
| File / field | Old -> new | Why |
|---|---|---|
| `data/units/thornling.tres`, `burr_slinger.tres`, `bloomtender.tres`, `sprigling.tres`, `sapling.tres` / `idle_regen_pct` | 1.5 -> **1.0** | D1 (the knob planned in `kingdom-nature.md` 9). Full heal from 50 %: 33 s -> 50 s |
| `data/units/bramblehorn.tres` / `idle_regen_pct` | 3.0 -> **2.0** | D1, same ratio |
| `scripts/units/nature_wizard.gd` / `VERDANT_REGEN_PCT` | unchanged 1.5 | Ysolde is the frailest wizard; her regen does not drive the army snowball |
| `data/ai/nature_normal.tres`, `nature_hard.tres` / `worker_target_expanded`, `worker_target_x2` | 10 / 13 -> **9 / 12** | D2: same as every kingdom once expanded. `worker_target_home` stays **7** (Nature keeps the fastest start) |
| `data/ai/nature_easy.tres` / `worker_target_expanded`, `worker_target_x2` | 7 / 7 -> **6 / 6** | Same rule, easy |
| `data/ai/nature_easy.tres`, `nature_normal.tres`, `nature_hard.tres` / `regrow_wait` | 30.0 -> **45.0** | D1: at 1.0 % / s the army relaunches at ~95 % after a retreat instead of ~80 % at 1.5 %, but 15 s later: fewer waves, the enemy's economy breathes |
| Thornling cost, Bloomtender heal, Bramble Spire aura, pop cap 50, X1 at 4:30, `retreat_hp` 0.5 | unchanged | Keep the identity (cheap swarm, retreats and regrows); these are the next knobs (section 5) |

### 2b. Ice: expand on time, cheaper army, retreat alive (gameplay 8.B1, ai 8.B3)
| File / field | Old -> new | Why |
|---|---|---|
| `data/ai/ice_easy.tres`, `ice_normal.tres`, `ice_hard.tres` / `expand_time` | 420.0 -> **330.0** | D3: X1 at 5:30 (still the last kingdom to expand, 30 s after Fire / Shadow) |
| same three / `expand_home_below` | 700 -> **0** (= the "home nodes < half of the start" rule, 2 000) | D3: the stale threshold |
| same three / `retreat_hp` | 0.3 -> **0.4** | D5: same as Fire / Shadow; a slow army must leave earlier to leave at all |
| `data/units/rimeshield.tres` / `cost` | 100 -> **95** | D4 (the knob planned in `kingdom-ice.md` 9): CE 17.3 -> **19.1** (Flame Guard 19.3, Shade 18.9). `kill_xp` stays 50 (95 / 2 rounded to 5) |
| `data/units/rime_colossus.tres` / `cost` | 330 -> **290** | D4, mirrors the Shadow Knight cut of balance-1: CE 8.9 -> **11.6** (Knight 13.2; the Colossus adds chill and armor 20) |
| `data/units/rime_colossus.tres` / `kill_xp` | 165 -> **145** | Kill XP = cost / 2 |
| Bot heavy gate (`heavy_crystals` default 300) | unchanged | `max(300, 290)` = 300: the Colossus still waits for 300 crystals and 8 soldier pop |
| Ice attack_ratio 1.5, min_attack_pop 8, Rime Spire at 3:30 | unchanged | Ice stays the patient kingdom |

### 2c. Building HP: apply the kingdom rule to the balance-1 values (systems 8.B2)
| File / field | Old -> new | Rule |
|---|---|---|
| `data/buildings/ice_keep.tres` / `max_hp` | 1800 -> **3000** | 2 500 x 1.2 |
| `data/buildings/ice_barracks.tres` / `max_hp` | 1080 -> **1560** | 1 300 x 1.2 |
| `data/buildings/ice_lodge.tres` / `max_hp` | 480 -> **600** | 500 x 1.2 |
| `data/buildings/ice_tower.tres` / `max_hp` | 720 -> **900** | 750 x 1.2 |
| `data/buildings/nature_keep.tres` / `max_hp` | 1350 -> **2250** | 2 500 x 0.9 |
| `data/buildings/nature_barracks.tres` / `max_hp` | 810 -> **1170** | 1 300 x 0.9 |
| `data/buildings/nature_hollow.tres` / `max_hp` | 360 -> **450** | 500 x 0.9 |
| `data/buildings/nature_tower.tres` / `max_hp` | 540 -> **675** | 750 x 0.9 |
| Ice Wall 500, every cost, build time, tower damage | unchanged | |
This helps D7 (bases of the new kingdoms survive a won fight as long as Fire / Shadow ones) and D6. It also helps
Nature defend, which is why 2a comes in the same pass.

### 2d. Code presets (ai 8.B3)
`AIProfile.for_id` loads `data/ai/<kingdom>_<difficulty>.tres` first, so 2a / 2b take effect from the .tres alone. The
fallback presets in `scripts/ai/ai_profile.gd` `nature()` / `ice()` must say the same (no `+1` on `worker_target_expanded` /
`worker_target_x2`, `regrow_wait` 45, Ice `expand_time` 330, `expand_home_below` 0, `retreat_hp` 0.4) so a missing .tres
does not bring the old numbers back.

## 3. Expected effect
| Kingdom | Before | Expected after |
|---|---|---|
| Nature | Wins 5 / 5, ~1.6x crystals, opponent armies capped at 10-15 pop | Still the strongest **early** (7 home workers, 4:30 expansion, cheap Thornlings); after 5:00 income equal to others (-1 worker = about -70 crystals / min); each attack-retreat cycle ~50 % slower and no longer free. Crystal ratio vs its opponent **<= 1.25x** at 10:00. Wins ~50-60 % |
| Ice | Weakest, 0 army at every end, 4.3-5.3k crystals | +1:30 of natural-node income (~+300 crystals by 7:00, X2 around 9:30 instead of never), +5 % (line) to +14 % (Colossus) army per crystal, retreats save ~20 % more of the group, base 1.2x Fire's. Wins ~40-50 %; strongest after 12:00 |
| Shadow | Beats Ice, loses to Nature | Unchanged data; its Nature games get closer, its Ice games get harder |
| Fire | Discounted (no casts) | Unchanged; re-measure once the Vessa bot rules land |
| Match length | ~11 min, 2 of 7 no winner at 12:00 | Even pairs **14-20 min**: both sides reach X1 by 5:30 and X2 by ~9:30, armies survive trades, new-kingdom bases need 25-35 s under 10 soldiers |

## 4. Re-test plan (lead, after 8.B1-8.B3 are in)
- Harness: the any-kingdom bot-vs-bot run of 8.A1, normal, cap **24:00** (`--fixed-fps 60 --quit-after 88000`), both sides bots.
- Log per run: winner and time; army pop at 5 / 10 / 15 / end (and max); crystals gathered at 5 / 10 / 15 / end; workers at
  5 / 10; X1 and X2 completion times; attacks launched / retreats; wizard levels at end; first top item time.

| Round | Pairs (both side orders) | Runs | Why |
|---|---|---|---|
| A | nature-shadow, nature-ice, ice-shadow | 3 each: 2 as listed + 1 sides swapped = **9** | The pairs with no discounted side; decide 2a / 2b |
| B | fire-nature, fire-ice | 2 each (1 per side) = **4** | Trend only while Fire does not cast |
| C | nature-nature, ice-ice | 1 each = **2** | Side bias of the map: must be close (crystals within 1.1x) |
| D (later) | all 6 pairs, both sides | 12 | When the Vessa bot rules are in: the full matrix |

**Pass (rounds A-C, 15 runs):** Nature wins <= 4 of its 7 non-mirror runs; Ice wins >= 2 of its 7; no run has a crystal ratio
above **1.35x** at 10:00; median match length **14:00-22:00**; at most 2 runs without a winner at 24:00; mirrors within 1.1x.

## 5. Next knobs (only if round A says so; one per re-run)
| Symptom | Knob |
|---|---|
| Nature still wins > 4 / 7 | `thornling.tres` / `cost` 55 -> **60** (CE 20.6 -> 17.3), `kill_xp` 30 unchanged |
| Nature now loses most games | `regrow_wait` 45 -> **35** |
| Ice still wins < 2 / 7 | `rime_seer.tres` / `support_amount` 60 -> **75**; or `ice_normal.tres` / `attack_ratio` 1.5 -> **1.4** |
| Ice wins > 5 / 7 | `rimeshield.tres` / `cost` 95 -> **100** (undo) |
| Even pairs still end < 14:00 | every keep `max_hp` +20 % (Fire / Shadow 3 000, Ice 3 600, Nature 2 700) |
| Games > 22:00 or many no-winner | `NODE_AMOUNTS` rich 2 500 -> 1 800 (balance-1 knob) |

## Results (8.B4, ai-coder, 2026-09-25)
Harness `tests/test_8_b3.gd` (normal bots both sides, cap 24:00, `--fixed-fps 60`), one process per run. New option
`--set=unit:<id>:<field>=<v>,building:<id>:<field>=<v>,ai:<profile>:<field>=<v>` tries a knob **in memory only** (used for
the knobs whose files the ai-coder does not own). The RUN line now names the winning side.

**Changed in the data (round 1):**
| File / field | Old -> new |
|---|---|
| `data/units/thornling.tres` / `cost` | 55 -> **60** (`kill_xp` 30 unchanged) |
| `data/ai/ice_normal.tres` / `attack_ratio` | 1.5 -> **1.4** |
| `scripts/ai/ai_profile.gd` `ice()` | normal preset +0.1 instead of +0.2 (= 1.4; easy 2.0 / hard 1.3 unchanged) |
| `tests/test_8_b3.gd` part 0 | expects `ice_normal.attack_ratio` 1.4 |
Not applied (other owners' files, tried with `--set` only): Rime Seer `support_amount` 75, every keep `max_hp` +20 %.

| Round | Knobs (cumulative) | Runs | Nature wins | Ice wins | Median length | 10:00 ratio > 1.35 | No winner | Mirrors (10:00) | Pass |
|---|---|---|---|---|---|---|---|---|---|
| 0 (lead) | balance-2 2a-2d | 15 | 7 / 8 | 1 / 8 | 13:25 | - | - | 1.2x | no |
| 1 (data) | Thornling 60, Ice `attack_ratio` 1.4 | 15 | 6 / 8 | 1 / 8 | 11:46 | 4 | 0 | Nature 1.09, Ice end 1.44x | no |
| 2 (memory) | + Rime Seer 75, keeps +20 % | 30 | 12 / 16 | 2 / 16 | 13:44 | 2 | 0 | Nature 1.05 / 1.06, Ice 1.15 / 1.15 | no |
| 3a probe | round 2 + Thornling 65 | 15 | 7 / 8 | 1 / 8 | 11:05 | 1 | 0 | Nature 1.28, Ice 1.17 | no |
| 3b probe | round 2 + Nature `worker_target_home` 6 | 15 | 6 / 8 | 1 / 8 | 13:08 | 1 | 0 | Ice 1.11 | no |

Per pair (winner count; lengths):
| Pair (both orders) | Round 1 (data as shipped) | Round 2 (+ Seer 75, keeps +20 %) |
|---|---|---|
| nature-shadow | Nature 2, Shadow 1 (15:16, 10:37 / 16:47) | Nature 6 / 6 (7:26-20:55) |
| nature-ice | Nature 3 / 3 (8:00-11:46) | Nature 6 / 6 (7:22-13:34) |
| ice-shadow | Shadow 2, Ice 1 (12:21, 13:22 / 17:35) | Shadow 4, Ice 2 (7:54-18:33) |
| fire-nature | Nature 1, Fire 1 (11:12 / 13:35) | Fire 4 / 4 (16:27-19:21) |
| fire-ice | Fire 2 / 2 (9:26, 10:19) | Fire 4 / 4 (8:10-13:36) |
| nature-nature | 15:30, 1.09x | 15:42 / 16:36, 1.05 / 1.06x |
| ice-ice | 9:45 (end 1.44x) | 13:16 / 13:51, 1.15 / 1.15x |

**Findings.** (1) Section 5 is used up for the failing symptoms and the pass line still fails. (2) Nature's edge is **not
economy**: it gathers +19 % by 5:00 (2 700 vs ~2 270), but probe 3b brought that to 2 260 and Nature still won 6 / 8; Thornling
65 changed nothing. Its win comes from the fights: 8.2 attacks per game, retreat and regrow (next knobs: `idle_regen_pct`,
Bloomtender heal, Spire aura or `regrow_wait`). (3) Ice attacks 3.2 times per game (Nature 8.2, Fire 8.0) and loses its army
defending. Seer 75 had no visible effect. It needs combat value (CE) more than bot patience. (4) Keeps +20 % is the only knob
that made games longer (+2 min median). Recommended to apply it (systems-coder). (5) Fire now casts (8.A2) and wins 11 / 12
of its games: the Fire discount no longer holds.
**Mirror gap (map check, map not changed):** the map is an exact point mirror for the economy. Navmesh paths from the keep
drop-off are the same for both sides (a / b 6.6 m, mid 39.0 m, rich 79.4 m, natural hall -> mid 5.7 m, keep -> centre 55.9 m),
and every bot slot (H1, S1, V1-V3, X1, X2) mirrors exactly. Non-mirror runs show no side bias (player side 33, enemy side 32
wins). Two asymmetries remain: (a) `skirmish.gd` `CAMP_DROP_POS` (0, 0, 3) is not mirrored. The crown camp's drops land
58.7 m from the player keep and 63.0 m from the enemy keep. (b) The scene's bot (enemy) thinks before the player-side bot
in the same frame. Both matter when two identical bots hit the crown camp together (Ice mirrors: both attack the camp at
5:33). The player side won **5 / 5 Ice mirrors** (Nature mirrors 3 / 5).

## Done when (proposed step 8 ids; the lead adds them to `waves.md`)
- [ ] 8.B1 (gameplay): the unit rows of 2a / 2b are in the data; test: a Thornling at 20 HP regains 0.7 HP / s after 4 s without damage; a Bramblehorn 7.6 HP / s; Rimeshield costs 95; Rime Colossus 290 and 145 kill XP.
- [ ] 8.B2 (systems): the 8 building HP values of 2c; test: Rime Keep 3 000, Heartwood 2 250, Frost Hall 1 560, Grove Hall 1 170.
- [ ] 8.B3 (ai): the .tres fields of 2a / 2b and the code presets of 2d; headless normal run: Ice X1 placed by 6:00 (unless an attack group is out then), Nature workers stop at 9 after X1 and 12 after X2, a Nature relaunch after a retreat comes >= 45 s after reaching the rally (or at 85 % HP).
- [ ] Lead: re-test rounds A-C of section 4 meet the pass line.

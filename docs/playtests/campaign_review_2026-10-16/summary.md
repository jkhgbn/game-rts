# Campaign review 2026-10-16 — summary (lead)

JS: "play the campaign and grade all missions, note the experience and how unique they are from each other".
Method: three reviewers (Opus 5.5 medium) "played" each mission from its design doc, its script and the CI bot playthrough
logs of tag playtest-2026-10-16 (missions 00 / 01 / 02 / 04 have no bot sim: doc + script only). One rubric for all:
Hook / Clarity / Pacing / Challenge / Story / Payoff (1-10), letter from the average, tags from one fixed list.
Details per mission: [part1.md](part1.md) (m00 .. e3m2), [part2.md](part2.md) (e3m3 .. e6m2), [part3.md](part3.md) (e6m3 .. ending).

## Grades (34 entries: 33 missions, e8m1's four roads as one, + the ending)

| Ep | Mission | Grade | Signature |
|---|---|---|---|
| 1 | m00 | **B (8.0)** | Mentor dies mid-mission; his death powers the last stand |
| 1 | m01 | C (6.2) | Three braziers break a seal, then hold the crown |
| 1 | m02 | **B (7.7)** | Fireballs crack the lake under enemy armies; reverse escape |
| 1 | m03 | C (6.8) | Champions steered only by bounty flags in a 3-way heart race |
| 1 | m04 | B (7.2) | Every death feeds the boss; you choose when the finale starts |
| 2 | e2m1 | C (6.0) | Frost clock to kindle the Heartwood, then a 12-min hold |
| 2 | e2m2 | C (6.3) | Escort the ally's planters; a 4th kingdom regrows (2v1 -> 2v2) |
| 2 | e2m3 | C (5.7) | Win by paying gold: caravans, tributes, thieves |
| 2 | e2m4 | B (7.0) | Dark halls; race the enemy to wake sleeping Wardens |
| 2 | e2m5 | C (5.8) | Seal tug-of-war sets the boss's strength |
| 3 | e3m1 | C (6.5) | Play the villain Malrik across a slowing ford |
| 3 | e3m2 | **B (7.3)** | Stealth: mission 00 from the knife's side |
| 3 | e3m3 | C (6.8) | A tempting power with a visible price |
| 3 | e3m4 | C (6.7) | An unkillable hero-boss broken three times; titan unlocked |
| 4 | e4m1 | C (6.5) | e3m1's battle from the other hill |
| 4 | e4m2 | C (5.8) | Cowering villager convoys; you clear the road |
| 4 | e4m3 | B (7.0) | Regrow five frozen groves, hold all green at once |
| 4 | e4m4 | B (7.0) | A healing full-map ice wall broken by the Elder Treant |
| 5 | e5m1 | C (6.0) | Basics refresher as a flashback |
| 5 | e5m2 | C (6.8) | The heroine's flaw as a rule: going in alone springs the ambush |
| 5 | e5m3 | **B (7.2)** | True stealth: candle toggle, shadows, knock-outs |
| 5 | e5m4 | C (6.8) | Friendly banner race against an overreaching Vessa |
| 6 | e6m1 | C (6.2) | Floes crack under the enemy (unused by the sim) |
| 6 | e6m2 | C (6.8) | Open the gate or let the town burn (saved for Ep8) |
| 6 | e6m3 | B (7.0) | Tending vs mining: the worker economy is the defence |
| 6 | e6m4 | C (6.8) | "The Hollow counts": deaths near the isle chip the seal |
| 7 | e7m1 | B (7.2) | Three timed dragon auctions won with trade gold |
| 7 | e7m2 | C (6.5) | A duel you may lose, then a truce with your rival |
| 7 | e7m3 | **B (7.3)** | People-vs-pits choice made with the army's feet |
| 7 | e7m4 | C (6.5) | Mid-mission seat switch: ally turns enemy, enemies join |
| 8 | e8m1 x4 | B (7.0) | Each road turns its wizard's weakness into the meter |
| 8 | e8m2 | C (5.5) | Four kingdoms on one side; allies march on your help |
| 8 | e8m3 | C (6.7) | Chain Surges + Hold Together: four wizards in four rings |
| 8 | ending | C (6.8) | No-timer throne choice, dark-history whisper |

Campaign average **6.7 = C+**: 12 B, 22 C, no A, no D / F. Writing and story score highest everywhere (7-8); Pacing and
Clarity score lowest. Best: m00, m02, e3m2, e7m3, e5m3. Weakest: e8m2, e2m3, e4m2, e2m5, e5m1.

## How unique are they (the three reviewers agree)
Every mission has a real signature idea on paper (the table above): the ideas are varied. What repeats is the **play
under the idea**:
1. **Base + army + scripted waves, ending on a timed hold.** ~21 of 33 missions are base-building; ~17 end on "hold X /
   survive a timer". Story floors (the next phase waits for a clock, not for the player) appear in e7m2, e7m4, e8m2,
   e8m3 and several earlier holds.
2. **One verb: "stand your hero next to a thing for N seconds"** (braziers, blocks, seals, candles, groves, bells, beacons,
   keyholes, doors, Hold Together) in most missions.
3. **A meter racing you** (dig %, frost %, wake %, Hunger, Hollow, seal): ~10 missions, five of them "deaths feed a meter".
4. **Same maps**: the Fire corner skeleton (m00-m03, e2m1), re-dressed Crown Hollow (m04, e2m2, e2m3, e6m4, e7m1, e7m2,
   e7m4, e8m3), Evenmead (e3m4, e4m1), one generator map for all four e8m1 roads and e8m2.
5. **Same enemies for whole episodes**: the Shade / Nightbolt / Grave Hound wave from m00 to e2m5, the all-melee Ruin
   Warden Host in e6m4 -> e8m3; Mother Hush flees at 25 % three times.
6. **Few genre breaks**: hero-only 1 (m00), stealth 3 (e3m2, e5m3, partly e5m4), chase 2 (m02, m03); nothing like that
   after episode 5. Near-twins: e6m1 / e6m2, e3m4 / e4m1, e4m3 / e4m4.

## Cheapest high-value fixes
1. **Bug**: ending_b's first line is hard-coded to Vessa whatever road was played (fix: the player's wizard, fate last).
2. Replace story floors by goal-based phase changes with a short minimum (e7m2, e7m4, e8m2, e8m3): biggest pacing win.
3. Cut e8m2 to ~20 min (march floors off or halved); give each allied march one beat.
4. Give 4-6 missions another final verb than "hold / channel": carry, escort, destroy, chase.
5. Break the roster sameness: 1-2 ranged Host units in ep6-8; a new Shadow unit per mission in ep1-2.
6. Readability: visible meters / tally rings for invisible rules (e6m4 deaths, e7m3 rows, e8m3 ward HP big on screen).
7. A real silhouette for the Hollow King (now a scaled Rime Colossus); credits ~1:30 instead of 20 s.

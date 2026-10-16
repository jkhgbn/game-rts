# Campaign review 2026-10-16 — part 3 (e6m3 .. ending)

Method: each mission was "played" by reading its design doc (`docs/design/mission-*.md`), its script
(`scripts/campaign/mission_*.gd`, including the "Built deviations" header) and the CI bot logs (playtest-2026-10-16, the
`-Parallel 2` rerun, and gf-2026-10-15 where the playtest run timed out). The bar is the Warcraft III campaign. A load
timeout is not counted as a design flaw. Sim lengths are mission time, with the film-inclusive time in brackets.

### mission_e6_03 — The Year Nothing Grew   Grade: B (7.0)
- Scores: Hook 8 / Clarity 7 / Pacing 7 / Challenge 4 / Story 8 / Payoff 8
- Tags: defend-hold, timed-survival, economy-twist, night-fog, boss-fight
- Signature: the worker economy *is* the defence: a Sprigling tending a garden through the frost is a Sprigling not mining, so every night forces a mining-vs-tending split.
- Experience: Opens 32 winters ago with young Ysolde (L1) and Maelis on a snowed-in Evenmead, four seed-gardens at 500 Life
  and a fixed 16:00 clock to spring. The first day is quiet building. Then nights at 3:30, 8:00 and 12:30 drain gardens
  at 3-4 Life/s unless tended, while Frostfang wolves skip buildings and go only for gardens. Night 3 is the longest and
  Old Whitepelt arrives at 13:00 as the climax. Spring comes at 16:00 with the Master's "Show me again" and the golden-tree
  film: a quiet, earned ending.
- Sim: victory 16:01 (16:51), 4/4 gardens at full 500 Life, Whitepelt killed, 8 sprouts; passive loses at 3:57. Margin is huge: the scripted run never got close to losing a garden.
- Best moment: the spring film turning the saved sapling into the golden tree, a flashback that explains a symbol.
- Weakest point: far too easy once tending is understood. Gardens end at 100 %, so nights 2-3 have no tension.
- Fix ideas: raise night-3 frost to 5/s and give Whitepelt a garden-only howl that pulls tenders off; cap regrow at 2 tenders per garden; put the 2nd and 3rd gardens out of sight of each other so a split army is needed.

### mission_e6_04 — The First Crack   Grade: C (6.83)
- Scores: Hook 7 / Clarity 6 / Pacing 6 / Challenge 7 / Story 8 / Payoff 7
- Tags: defend-hold, waves-onslaught, ally-control, siege
- Signature: "the Hollow counts": every death within 25 m of the isle chips the seal, so you are punished for fighting on your own doorstep (the origin of Torvald's "something counting").
- Experience: Twelve years ago, Ysolde (L4) and an allied Torvald hold Crown Hollow's isle while the Master kneels on the Throne
  stone; the hold bar fills 0-100 % over 16 minutes and pauses when any enemy is within 6 m of him. Ruin Wardens pour out
  of four Warden Gates, with set pieces at 50 % (First Crack), 75 % (Deep Calls) and 90 % (Last Rise) plus Breakers; Stronghold
  opens at 3:30. The middle is a long grind, with Snagroot dragging Wardens out of the circle as the best tool. The end:
  the Master names Obren, says "tell no one", "never in one hand", then the ep6 vanishing.
- Sim: victory 19:27 (20:54), hold 100 % (paused 1:17), seal min 85 %, 68 counted deaths, about 100 player losses; passive loses at 2:59. Solid margin on the seal, heavy losses.
- Best moment: the Master's last words before the vanishing, which seed the whole of episodes 7-8.
- Weakest point: no river, moat or crossings on the generator map, so the "moat rises" beats mean nothing and the Host walks straight in; an all-melee roster makes Pollen Haze dead weight.
- Fix ideas: show the "counted" deaths as a visible tally ring on the isle so players learn to fight forward; add 1-2 ranged Host units so the whole Nature kit matters; give the pause rule a loud on-screen state ("The Master is interrupted").

### mission_e7_01 — The Dragon Auction   Grade: B (7.17)
- Scores: Hook 9 / Clarity 6 / Pacing 7 / Challenge 6 / Story 8 / Payoff 7
- Tags: economy-twist, capture-points, escort, rival-wizard-race, ally-control
- Signature: three timed dragon auctions where gold from caravans and the Tollrock's "word" decide who gets an allied dragon: an RTS mission won at a bidding table.
- Experience: Narrated by Ossavar the Twice-Sold, Torvald's first track mission puts him and an allied Malrik on a re-dressed
  Crown Hollow against Vessa and Ysolde, with caravans, a Frost Bazaar and the Tollrock (+30 gold/min, wins ties within 10 %).
  Auctions at 8:00, 14:00 and 20:00 (45 s windows, +50 / +100 bids against ceilings 500 / 800 / 1100). The 12:00 Laurel duel
  is broken by gold-cloak knives and violet smoke (Mother Hush's clue), then you escort the wounded Seraphine to the
  harbour. It ends with a 2:00 harbour hold. Malrik's Outwall-stamped gift plants doubt.
- Sim: CI `-Parallel 4` FAIL, defeat 21:20 (Torvald died in the final hold) after 3/3 auctions; rerun `-Parallel 2` PASS 22:46 (23:45), 3/3 auctions, 1950 gold; passive loses at 12:37. Thin margin at the very end (the hero dies in the last hold).
- Best moment: the third auction for Ossavar himself, with the narrator being sold.
- Weakest point: the auction is a button panel and the Laurel duel is a 20 s stand-off with no blows, so the two set pieces that sell the episode play flat.
- Fix ideas: show Aurivane's bid as a rising bar with a visible ceiling hint after the first loss; give the duel 3-4 scripted exchanges before the knives; shorten the final hold to 1:30 or add a Torvald fallback point so the mission does not end on a coin flip.

### mission_e7_02 — First Blood, and No Further   Grade: C (6.5)
- Scores: Hook 7 / Clarity 6 / Pacing 6 / Challenge 6 / Story 7 / Payoff 7
- Tags: small-squad, siege, capture-points, boss-fight, puzzle-environment
- Signature: a formal duel where losing is allowed (first below 75 % loses, and losing is not defeat), followed by a truce where Vessa fights beside you.
- Experience: Torvald and Seraphine, without Malrik, break the Sun Barricade on the North Causeway (two gatehouse shells,
  a soft wall), take the Tollrock, then walk three clue channels (knives, ledger, herald). Dacian comes to the sand at the
  afternoon bell (story floor 17:00) for the duel. Mother Hush's ambush is the climax (boss numbers, flees at 25 %) while you
  keep Dacian alive. It ends on the e7m2_mask film, with the Citadel and the Aldra helper opened along the way.
- Sim: victory 17:17 (18:32), duel lost, 1/3 strongboxes, Aldra failed, about 40 losses; passive stalls at the barricade (no end at 25:00). Comfortable win, weak secondaries.
- Best moment: the turn from duel to ambush, with your rival's army joining against the knives.
- Weakest point: the 17:00 story floor makes players who found the truth early wait; the duel is auto-attacks only, so it is a stat check, not a fight.
- Fix ideas: drop the duel floor or fill the wait with the strongbox hunt (start the boxes' timer when clue 3 lands); give Dacian one telegraphed big swing to dodge; show a passive fail state ("The causeway holds — you have not broken it") instead of a silent stall.

### mission_e7_03 — The Outwall   Grade: B (7.33)
- Scores: Hook 8 / Clarity 6 / Pacing 7 / Challenge 7 / Story 8 / Payoff 8
- Tags: defend-hold, rescue, branching-choice, night-fog, economy-twist
- Signature: the people-vs-pits choice is made "with the army's feet": no menu, you either guard the shanty rows or hold the diamond pit heads for gold, and the flag branches the next film.
- Experience: A night in the poor quarter on a new code-built map with no enemy base: ring five Dock Bells and walk dockers
  to the keep. Three raider types each want something different: Aurivane burns rows, masked raiders (Malrik's) seize them,
  Adamarch press-gangs just need you standing there. The Archon's 9:00 order adds the diamond tithe; the 17:00 Night Tide
  splits the map into two fronts 45-60 m apart. The Mask Captain's unmasking (Malrik's sigil) is the climax, and dawn ends it at 22:00.
- Sim: victory 22:01 (23:06), 32 sheltered / 8 lost, bells 4/5, mask done, pits and mammoths failed, keep 2598 HP, about 22 losses; passive loses at 16:57 (30 lost). Healthy margin.
- Best moment: unmasking the Mask Captain and finding Malrik's sigil, the payoff of e7m1's Outwall-stamped gold.
- Weakest point: the three raider types read alike on screen (masks are renamed Shadow units, press-gangs are Facetguards) and the "row taken" rule is invisible until a row is gone.
- Fix ideas: a ring under each row's bell that fills while it is being taken (20 s); a grey tint on masked units; a one-line HUD note at 9:00 that says plainly "every pit held = gold, every row left = lives".

### mission_e7_04 — The Year of Two Skies   Grade: C (6.5)
- Scores: Hook 7 / Clarity 5 / Pacing 5 / Challenge 6 / Story 8 / Payoff 8
- Tags: capture-points, river-water, ally-control, defend-hold, boss-fight
- Signature: mid-mission seat switch: your ally Malrik turns enemy (switch_seat_side) while yesterday's enemies (Ossavar, Dacian, Seraphine) join you.
- Experience: A 2v2 for the Tollrock with galleys on the water and a Sunwake auction, then a 40 s truce on the sand.
  Then the Turn: Malrik flips sides and Aurivane withdraws. You hold the rock against Malrik, Hush and bought dragons, which
  you can pay to fly home at the Bazaar, while the Stone's Hunger meter feeds Obren. It closes with "Still the Sea", three
  15 s channels at the lighthouse (story floor 22:00), and the ep7 ending "No. Not for Now."
- Sim: gf-2026-10-15 PASS 23:51 (25:19), keep at 1040 HP, Hunger peak 86, about 90 losses; playtest CI timed out; rerun defeat 23:45 (keep 0 HP in P5 stage 2); passive loses at 15:55. Thin and flaky: the keep dies in the last two minutes in one run of two.
- Best moment: the Turn, the best twist in the set, done in gameplay rather than a film.
- Weakest point: five phases in 24 minutes with a story floor at the end; players hold through a long P4 and then may lose the keep during the channels.
- Fix ideas: drop the Still the Sea floor to 20:00 or let the channels start when P4's goals are met; give the keep +25 % HP or a mend at the Turn; show the Hunger meter's effect at 50 / 75 / 100 in plain words.

### mission_e8_01 — The Four Roads (fire / ice / nature / shadow)   Grade: B (7.0)
- Scores: Hook 8 / Clarity 7 / Pacing 6 / Challenge 6 / Story 8 / Payoff 7
- Tags: branching-choice, defend-hold, escort, rescue, puzzle-environment
- Signature: each road turns its wizard's prologue weakness into the mission's meter: Vessa must *wait* (Hunger rises if she crosses), Malrik must *not dig* (Stone's Gift), Torvald must *open* the gate, Ysolde must *take a side*.
- Experience: Picked on the road screen; all four start at L5 with a Stronghold and the key relic in slot 1, against the
  Hollow Host and Stone-sworn. Fire holds the west bank to 17:30 (floor), with a Storm bar that rewards patience and four
  scouts to save. Ice opens the gate and walks 40 refugees through (need 20). Nature unweaves three knots guarded by her
  own ward spires, saves each hamlet in a 120 s bar and crosses before the bridges close. Shadow lays three Barrow Doors
  to rest, fights Mother Hush and carries the stone up the Stair. Every road ends at 17-19 minutes into the Crown Hollow road.
  The variants differ strongly in mechanic but share the generator map, the south-west base, the Host roster and the length.
- Sim: fire victory 18:40 (hunger peak 54, sec_waited failed); shadow 17:01 (0 stone uses); ice 17:40 (38/40 saved); nature 18:01 (3/3 hamlets). Passives lose at 6:08 / 16:24 / 15:32, shadow stalls (no end at 25:00). Comfortable margins on all four.
- Best moment: Shadow's Stone's Gift button, a temptation that silently makes the final boss stronger.
- Weakest point: four strong ideas on one generic map: drawn walls, rivers and bridges are not obstacles, so the Ice gate and the Nature root walls are rules, not terrain.
- Fix ideas: make the Ice wall and Nature root walls real nav obstacles (even as simple block colliders); move the base per road so they do not look identical; tell the player at the end how the meter choice (stone uses, hunger peak) carries into e8m3.

### mission_e8_02 — The Last Muster   Grade: C (5.5)
- Scores: Hook 6 / Clarity 6 / Pacing 4 / Challenge 5 / Story 6 / Payoff 6
- Tags: ally-control, capture-points, defend-hold, siege
- Signature: the four kingdoms finally on one side; allies march only when their Muster bar is filled by your help kills and answered pings.
- Experience: Seat A1 on a 120 m generator stand-in for Fourfold Hollow, with three scripted allied wizards in the other corners.
  You break your own Keystone Pylon and channel your key, then help the others' bars fill; the Hollow meter rises on every
  death (Early Rise at 100 %), and a Stone-sworn column hits at 12:00. Allies march no earlier than 14:00 / 18:00 / 24:00 (story
  floors), so the back half is waiting for timers. It ends with all four keyholes lit at about 26 minutes.
- Sim: victory 26:19 (27:34), all 4 lit, sec_help failed, Hollow under 75 %; passive loses at 20:23 (wizard). Safe margin, long.
- Best moment: the first allied wizard marching out of her corner to her keyhole.
- Weakest point: the floors make the help mechanic hollow: you can do everything right and still wait until 24:00; pings are HUD lines, not a ping wheel; no titans, Lairs or taverns.
- Fix ideas: remove or halve the march floors so help actually speeds things up; cut to about 20 minutes; give each allied march one beat (a line + a small set piece) so the four kingdoms feel like characters, not timers.

### mission_e8_03 — The Hollow King   Grade: C (6.67)
- Scores: Hook 8 / Clarity 5 / Pacing 5 / Challenge 6 / Story 8 / Payoff 8
- Tags: boss-fight, defend-hold, ally-control, siege
- Signature: a three-phase final boss you can only hurt during Chain Surges while all four Key-Wards stay above 50 %, ending with all four wizards standing in their rings for the Master's lance.
- Experience: Obren climbs out for 4:30, then Four Chains: damage only lands in Surges every 110 s while all wards are up, and
  the Tear beam picks the weakest ward. Phase 2 (floor 17:00) he walks on the weakest keep at x0.3 damage, with Cracked Limb
  staggers and Feeding. Phase 3 (floor 25:30) is Hold Together, then Exposed and the lance; the Hollow Pulse needs helpers near.
  Hush returns as an ally. It ends at 28-29 minutes into the ep8 film chain.
- Sim: playtest CI and rerun timed out (load, not counted); gf-2026-10-15 PASS 28:37 (29:37), wards A2 at 1325 and B2 at 513 of 3000, sec_chains / sec_fed failed; older runs mix victories (27:06) with many defeats (16:57-33:49); passive loses at 16:57. Thin, near the edge.
- Best moment: Hold Together: all four wizards in their rings at once is the campaign's thesis as a mechanic.
- Weakest point: the King is a Rime Colossus at x2.2, rooted; the chains deal the damage and the story floors set the pace, so player play matters less than the clock; two wards down at once = defeat, with one ward at 17 % in the winning run.
- Fix ideas: give the King a unique silhouette (even a cheap one: crown, chain props, a Hollow colour); tie phase changes to damage dealt with the floor only as a minimum lock-out of 3-4 minutes; show ward HP big on screen and give one ward-mend tool (a helper or an item) to cut the flakiness.

### ending — e8 road choice / ep8_choice / ep8_credits   Grade: C (6.83)
- Scores: Hook 7 / Clarity 8 / Pacing 6 / Challenge 5 / Story 8 / Payoff 7
- Tags: branching-choice, artifact-hunt
- Signature: a no-timer "Break the throne / Take the seat" card, with per-kingdom temptation lines and a whisper shown only after 3+ dark choices earlier in the campaign.
- Experience: The road card opens episode 8 with four wizard cards and their weaknesses. After the King, ep8_ending_a: "Now! All
  four! Together!", the Master climbs out on Vey's arm and says "I gave you kingdoms. You saw gold." (which pays off ep7),
  then "Choose, all four of you." The choice card leads to ending_b (the fates of the four, the harbour cities calling it a
  draw, "four hands, not one") or a 45 s dark tail per kingdom. The child bookend ("No. That was the whole point.") closes on
  the spark and the Outwall girl. Then credits.
- Sim: no sim (test_e8_flow PASS, test_e8m3_end_race PASS; judged from the films and story screens).
- Best moment: the bookend child's question and the Master's answer, the quiet payoff of the whole campaign.
- Weakest point: ending_b's first line is hard-coded to Vessa ("Nobody sits. Not ever again.") whatever road you played, and the player's fate is not moved last; credits are 5 text lines x 4 s, against the doc's 2:00.
- Fix ideas: say the line with the player's wizard (`<W>` as the doc asks) and reorder the fates so the player's comes last; stretch the credits to about 1:30 with the four wizards' portraits and their artifact; give the dark fallback row its own neutral film instead of ep8_dark_fire.

## Summary table

| id | grade | tags | signature |
|---|---|---|---|
| mission_e6_03 | B (7.0) | defend-hold, timed-survival, economy-twist, night-fog, boss-fight | Tending vs mining: the worker economy is the defence |
| mission_e6_04 | C (6.83) | defend-hold, waves-onslaught, ally-control, siege | "The Hollow counts": deaths near the isle chip the seal |
| mission_e7_01 | B (7.17) | economy-twist, capture-points, escort, rival-wizard-race, ally-control | Three timed dragon auctions won with trade gold |
| mission_e7_02 | C (6.5) | small-squad, siege, capture-points, boss-fight, puzzle-environment | A duel you may lose, then a truce with your rival |
| mission_e7_03 | B (7.33) | defend-hold, rescue, branching-choice, night-fog, economy-twist | People-vs-pits choice made with the army's feet |
| mission_e7_04 | C (6.5) | capture-points, river-water, ally-control, defend-hold, boss-fight | Mid-mission seat switch: ally turns enemy, enemies join |
| mission_e8_01 (x4) | B (7.0) | branching-choice, defend-hold, escort, rescue, puzzle-environment | Each road turns its wizard's weakness into the meter |
| mission_e8_02 | C (5.5) | ally-control, capture-points, defend-hold, siege | Four kingdoms on one side; allies march on your help |
| mission_e8_03 | C (6.67) | boss-fight, defend-hold, ally-control, siege | Chain Surges + Hold Together: four wizards in four rings |
| ending | C (6.83) | branching-choice, artifact-hunt | No-timer throne choice with dark-history whisper |

## Too similar

- **"Deaths feed a meter"** appears five times: e6m4 (seal counts deaths), e7m4 (Stone's Hunger), e8m1 fire (Hollow Hunger), e8m2 (Hollow meter / Early Rise), e8m3 (Feeding). It is the right theme, but by episode 8 it is wallpaper; keep it for e6m4 (origin) and e8m3 (payoff) and give e7m4 / e8m2 another pressure.
- **Stand within 3 m for N seconds** is the main verb of almost every mission: e7m2 clues, e7m3 bells, e7m4 Still the Sea, e8m1 doors / knots / lever, e8m2 keyholes, e8m3 Hold Together. Vary it (carry, escort, destroy, build) in at least two of them.
- **e7m1, e7m2 and e7m4** all play on the re-dressed Crown Hollow with the Tollrock as the capture point; three Tollrock fights in four missions blur together.
- **e6m4, e8m1 and e8m3** all fight the same all-melee Ruin Warden Host out of Warden Gates; the final act's enemy never changes its shape.
- **e8m1's four roads** share the generator map, the south-west base start and the 17-19 minute length; the mechanics differ, the look does not.
- **Mother Hush flees at 25 %** in e7m2, e7m4 and e8m1 shadow; by the third time the escape is expected, not a beat.
- **e6m4, e8m2 and e8m3** are all "hold a central isle while a bar fills" with story floors setting the pace.

## Verdict on the campaign ending

1. The story pays off: the Master's "never in one hand" (e6m4) returns as "four hands, not one", and "I gave you kingdoms. You saw gold." closes the ep7 gold theme cleanly.
2. The four-wizards thesis is made a mechanic in e8m3's Hold Together, which is the best design idea of the final act, but the stand-in King model and the story floors keep the fight from feeling like a Warcraft III finale.
3. The artifacts land as keys (regalia that must never be in one hand), but the artifact hunt itself fades in episode 8: the key relic is forced into slot 1 rather than being a last prize.
4. The throne choice and the child bookend are strong and quiet; the hard-coded Vessa line in ending_b breaks it for three out of four roads and must be fixed first.
5. Overall: a satisfying, coherent ending held back by production shortcuts (generic maps, timer floors, 20 s of credits), not by its writing.

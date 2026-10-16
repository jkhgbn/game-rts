# Campaign review 2026-10-16, part 1: Episode 1, Episode 2, Episode 3 missions 1-2

Reviewer: campaign critic (read-only playthrough). I "played" each mission by reading its design doc, skimming its script,
and reading the bot playthrough logs from CI tag `playtest-2026-10-16` (`docs/ci/playtest-2026-10-16/error_lab/logs/`).
When the tag's sim failed only because of machine load, I also read the nightly logs (`docs/ci/nightly_2026-10-15|16/`).
The bar is the Warcraft III campaign. Scores are 1-10. Grade = letter from the average (A >= 8.5, B >= 7, C >= 5.5,
D >= 4, F below).

Sim sources: m00 = `test_19_c7_sim`, m03 = `test_m3_sim`, m02 = `test_m9_sim`, m04 = `test_19_c5_sim`, eXmY = `test_eXmY_sim`.
Mission 01 has no full-mission sim. The smoke test runs on its map, but it is a 64 s battle, not the mission.

---

### mission_00 — The Night of Knives   Grade: B (8.0)
- Scores: Hook 8 / Clarity 8 / Pacing 8 / Challenge 7 / Story 9 / Payoff 8
- Tags: hero-only, small-squad, timed-survival, night-fog, tutorial
- Signature: The mentor dies in the middle of the mission (`m0_fall` at 6:40), and his death becomes an 80 s Grief's Fire power spike for the last stand.
- Experience: You start wounded at 45 % HP in a dark courtyard with 8 guards and an untouchable Old Vey. There are no workers and no base. Each of the three watch braziers you light gives you light, warmth and a warning for one side, so the opening teaches "light = information" without a single text wall. At 3:00 Mother Hush arrives, and her violet ring + Ember Step dodge is the cleanest skill lesson in the set. At 5:00 the big push hits from three sides. At 6:40 Vey falls in a cutscene, and you finish the night alone with an empowered Fireball. Dawn riders arrive at 8:00. The whole thing lasts about 8-9 minutes.
- Sim: victory at 8:02 (seed 0), escort 6 / 8 alive, 0 lost in A4, Vessa 371 HP (near full), 1 / 1 Blink dodged. That is a comfortable margin for a scripted player, so a human on normal will rarely be in real danger after A4.
- Best moment / Weakest point: Vey's fall, then "Come and get me. ALL of you." with Grief's Fire / The final 1:20 after the fall is a flat "wait for the clock". With Vey gone and A5 sized for the buff, it plays as a victory lap.
- Fix ideas: (1) Make A5 come from the darkest unlit side or the side Vey guarded, so the grief segment has a direction. (2) Add one Hush Blink during A5 (she returns once) so the dodge lesson pays off under pressure. (3) Give `sec_guards` a visible reward preview ("+2 Flame Guards next mission") in the panel.

### mission_01 — The Crown in the Ashes   Grade: C (6.17)
- Scores: Hook 5 / Clarity 8 / Pacing 6 / Challenge 6 / Story 6 / Payoff 6
- Tags: base-building, artifact-hunt, tutorial, defend-hold
- Signature: The first full base game: light three braziers across the map to break a seal, then hold with the crown against Malrik's counterattack.
- Experience: A clean economy-and-army tutorial. Lighting the nearby brazier is the first fight (sized so you keep 5+ of 6). Then come freeing Pell the peddler, the Westwatch skill check (a tower plus Nightbolts, which unlocks the Blaze Riders) and the warden camp at Southgate. The seal breaks, the dormant crown wardens wake, you grab the crown, and then you survive a 2:00 counterattack wave led by Malrik. Expected 15-20 min. The Stronghold at 3:30 adds a real choice. It is well built but very familiar: "visit 3 points, then hold" is the oldest campaign shape, and Malrik never threatens you directly before the end because his bot never attacks.
- Sim: no full-mission sim. Only start / save checks (`test_m1_ep1_saves` ok). Difficulty is unverified by a playthrough.
- Best moment / Weakest point: the 2 free Blaze Riders spawning at Westwatch with "ride down the Nightbolts" / Malrik's base is a static prop for 15 minutes (`min_attack_pop` 99). The "rival" sits still, and only timed waves show he exists.
- Fix ideas: (1) Let Malrik personally walk to the 2nd brazier you are not at and "snuff" it once (relight needed), so he is a visible rival. (2) Add a sim like m03's so the 15-20 min target and the Final-wave survival are measured. (3) Shorten the hold to 1:30 on normal and make Malrik's arrival a mini-boss beat (a voiced taunt + boss bar).

### mission_02 — The Orb Beneath the Ice   Grade: B (7.67)
- Scores: Hook 9 / Clarity 7 / Pacing 8 / Challenge 7 / Story 7 / Payoff 8
- Tags: base-building, artifact-hunt, puzzle-environment, rival-wizard-race, chase-flee
- Signature: Breakable ice floes. Fireballs crack the lake under enemy waves (80 damage + chill, the lane cut for 45 s), and heavy armies crack it on their own.
- Experience: Malrik's diggers are boring toward the orb on a % clock (about 22:50 on normal). You must melt a regenerating 1 500 HP Heartfrost that only Vessa and Ash Hurlers can damage. Midgame you thaw three frozen Emberguard squads for free veterans, play with the floes, and get hit by a blizzard at 11:00 that halves both sides' sight. The burst cutscene comes next, and then the mission reverses: Aldra raises Ice Walls over three of the four shore gaps, the Sentinels wake, a permanent blizzard falls, and you must carry the orb home through the Pursuit. Sim length 13:00-13:33.
- Sim: victory in 3 / 3 recent runs (13:33 tag, 13:01 / 13:18 nightly), dig stopped at 38 % (sec_dig done), 3 / 3 blocks, army left 2-12. A steady win with real attrition on the escape.
- Best moment / Weakest point: the escape, with walls rising, Sentinels waking and the blizzard closing in / The "only Vessa and Ash Hurlers damage it" rule is invisible until you right-click with the wrong units. The rule list (dig %, melt %, cracks, weight, knitting, regen) is heavy for mission 2.
- Fix ideas: (1) Show crack pips on each floe from the start, not only after a first crack, so the player discovers the trick on purpose. (2) Put the "only fire melts it" rule in the objective line itself (`Melt the Heartfrost with Vessa / Ash Hurlers (62 %)`). (3) The sim finishes ~5-10 min under the 18-24 target: either accept a 15 min mission or let the dig speed up when the Heartfrost is ignored.

### mission_03 — The Signet in the Sighing Wood   Grade: C (6.83)
- Scores: Hook 8 / Clarity 6 / Pacing 7 / Challenge 6 / Story 7 / Payoff 7
- Tags: base-building, rival-wizard-race, artifact-hunt, chase-flee, exploration
- Signature: A three-way race for Root Hearts hidden in the fog, using hired champions you can only steer with bounty flags. If Malrik grabs the Signet, it becomes a slowed carry chase to his keep.
- Experience: The tavern opens at 0:30 and the first hire is free, so the mission is really the champion and bounty tutorial (Explore, Hunt, Guard each get a hint). The hearts sit in fog circles. Malrik's drain squads go after them, and Nature guardians (Maelis, wolves) fight everyone, so the 3-way fights reward timing. Old Mossjaw roams from 6:00 as an optional elite. When the barrier falls, a 75 s muster countdown starts the race for the tree. If Malrik wins, you chase a slowed Malrik with riders. The ending is breaking two Warden Gates while their tides attack you. In the sim the mission lasts 14:38 against the 20-25 target.
- Sim: victory at 14:38, hearts 2 player / 1 Shadow, army 24, Vessa L7. sec_stakes failed, sec_mossjaw active (never killed). That is comfortable: the race arrived (12:48) and was resolved within 14 s (gates 13:02).
- Best moment / Weakest point: the muster countdown, "Malrik marches on the Oldroot", and the dash for the tree / After winning the race, the gate-breaking epilogue (two 1 800 HP arches spawning Wardens) is a chore that dilutes the climax. Too many new systems arrive at once: tavern, three flag types, stakes, hearts, Mossjaw, gates.
- Fix ideas: (1) Cut the Warden Gates or make one gate only, with the parting cutscene right after the Signet. (2) Move the Guard-flag/stake lesson to a hint-free optional and cut `sec_stakes` raids by one (the sim failed it without noticing). (3) Mark Malrik's carry path on the minimap with a distance ring, so the chase reads at a glance.

### mission_04 — The Hollow Throne   Grade: B (7.17)
- Scores: Hook 8 / Clarity 6 / Pacing 7 / Challenge 6 / Story 8 / Payoff 8
- Tags: base-building, boss-fight, capture-points, river-water, siege
- Signature: The Hollow meter: every soldier who dies on any side (+1 %, Malrik +8 %) brings the boss closer, so the player chooses when the finale starts by taking the Master's seat.
- Experience: It opens as a normal 1v1 on Crown Hollow against an attacking Malrik bot, with a meter ticking up from time and deaths. You take the throne (or the meter fills), and the Keystone Colossus rises warded by four pylons. Malrik's army helps break the far pylons, which is a nice uneasy truce. Then the Colossus walks your lane toward your keep, crushing things. At the "darkest hour" a storm video brings Old Vey back, and the finale is three "turn the key" exposures beside him. The sim takes 12:25 of mission time (15:31 with the films) against a 22-28 target.
- Sim: victory, seat taken at 6:17, pylons by Shadow 1, Vessa L7, **army 0** at the end. About 70 Fire losses to Wardens / Colossus / Hounds. It won, but bloody, which fits a finale. The film time is a big share (~3 min of 15:31).
- Best moment / Weakest point: Old Vey returning in the storm, and the two of them turning the key / Phase 2 ("the Colossus walks your lane") is short and unreadable in the sim (1:08), and the darkest-hour trigger (boss 40 % OR keep 50 %) means the rescue can come from losing, which muddies the moment.
- Fix ideas: (1) Trigger the darkest hour only on keep HP (or a fixed lane mark), so the rescue always reads as "we were losing". (2) Put the Hollow meter's death rule on screen next to the meter ("each death +1 %") for the whole phase 0. (3) Add a short Malrik line when his army breaks a pylon for you, to sell the truce.

### mission_e2_01 — The Burning Grove   Grade: C (6.0)
- Scores: Hook 6 / Clarity 7 / Pacing 5 / Challenge 5 / Story 7 / Payoff 6
- Tags: defend-hold, waves-onslaught, rescue, base-building
- Signature: A frost clock (Rime Totems speed it up) to reach and kindle the last Heartwood, then a 12-minute hold against Shadow and Ice waves.
- Experience: Ysolde's wood is burnt and frozen, and a 6:00 frost clock pushes you north. Break the Rime Totems, clear the glade, kindle the tree, and Nature wardens join you. Then comes a long 12:00 hold of six alternating Shadow / Ice waves (Torvald, then Malrik, then both), with Grave Hound raids on the survivors you escort home. Calling Old Vey from the new Citadel is the intended swing point. The rescue thread (Wren, 12 survivors) adds side business. The mission lasts about 14 minutes, and most of it is the hold.
- Sim: tag run DEFEAT at 13:23 in the hold (Vey not called, about 60 losses to Hounds and unnamed bodies). The 2026-10-15 nightly run won at 13:52 with Vey called, frost 20 %, folk 8 home. The outcome depends on the helper call: a thin, binary margin. This one is not just machine load.
- Best moment / Weakest point: the kindle, with wardens climbing out of the roots / A 12-minute hold is the longest dead-time stretch in my set (a 2:00 wave cadence, the same "Heartwood, then Vessa" order every time), and failing to call Vey is not signposted as fatal.
- Fix ideas: (1) Cut the hold to 8:00 (H1-H5) or make H3 a choice ("defend the Heartwood or save hideout S3"). (2) If the Citadel is not started by T + 4:00, have Ashby nag it as an objective line, so the Vey dependency is readable. (3) Have one wave come from a new direction (the south road), so the hold changes shape.

### mission_e2_02 — Roots and Embers   Grade: C (6.33)
- Scores: Hook 7 / Clarity 6 / Pacing 6 / Challenge 6 / Story 7 / Payoff 6
- Tags: ally-control, escort, capture-points, base-building, defend-hold
- Signature: You escort and direct an ally (Ysolde's seed-carriers) to plant three groves. When all three stand, a fourth kingdom grows back into the map in the middle of the mission, and the 2v1 becomes a 2v2.
- Experience: Ysolde plants Grove A on her own, then waits for your pings. You guard 40 s plantings that pause while enemies stand in the ring, and you deal with W1-W5 aimed at the grove being planted, Hound raids on walking carriers, and optional capture points. Midgame is breaking Torvald's Rimehold fort, which also frees a crystal seam. When all three groves stand, the Heartwood cutscene spawns Nature's base, and the mission ends with a 2:30 "Vice" hold against both wizards. The sim lasts about 19-21 minutes.
- Sim: tag run timed out (machine load). The 2026-10-15 nightly won at 19:29, carriers lost 6 (sec_carriers failed), and lost 4 + 4 + 4 to Rimehold's garrison early. The built notes add an "Emberwatch reserve" (free soldiers when wiped), so a full wipe was a real risk.
- Best moment / Weakest point: the `e2m2_heartwood` beat, when Nature's base appears on the map / The ping-to-plant UI is a 3-button stand-in panel. The "standing groves" count can go down. Then the mission closes on a third timed hold in a row in this episode.
- Fix ideas: (1) Replace the Vice hold with a counterattack on the new Heartwood that the player must reach (a moving defend, not a timer). (2) Give each grove site a click-to-send on the minimap icon (no panel). (3) Remove the hidden reserve and instead make Rimehold's spire range visible (a red ring) before the assault.

### mission_e2_03 — The Salt Road   Grade: C (5.67)
- Scores: Hook 7 / Clarity 6 / Pacing 5 / Challenge 6 / Story 6 / Payoff 4
- Tags: economy-twist, convoy, escort, base-building
- Signature: The only mission whose goal is money: build a Bazaar, run gold caravans, and pay six tributes to a Lodge while Magpie thieves and Malrik's toll hunt your wagons.
- Experience: A trade tutorial. Build the Bazaar, send caravans to near or far posts (risk against reward), then send 300-gold tribute caravans down the road. The Magpies rob loaded wagons, Malrik's Tollgate cuts the west road at 6:00, W2 sits on a trading post, and W3 hits the Bazaar with Malrik. The sim phase log shows 17 minutes of hold / defend / escort / hold switching about 30 times, which is accurate to how it plays: a loop of shepherding caravans. It ends with a 1:30 hold while Lodge guides walk out. The promised Ember Boar mount does not exist (no mount system), so the Stables beat is just a building.
- Sim: victory at 16:59 (17:57), tributes 6 / 6 (0 lost), W1 survivors 13 / 13. sec_magpies and sec_raid failed, sec_toll done. Comfortable on the primary, so the threats to caravans are softer than the fiction suggests.
- Best moment / Weakest point: the first tribute's Lodge cutscene / The climax is "hold 1:30 and some trackers walk to you", and six identical tributes make the middle repetitive.
- Fix ideas: (1) Make the 6th tribute a single big escorted convoy down the whole road (a moving finale) instead of a timed hold. (2) Cut tributes to 4 with rising prices, and make each delivery unlock something visible (the Lodge's map reveals a section of the deep). (3) Cut the Boar mention from the hints until mounts exist.

### mission_e2_04 — Sunrise Road   Grade: B (7.0)
- Scores: Hook 8 / Clarity 7 / Pacing 7 / Challenge 6 / Story 7 / Payoff 7
- Tags: small-squad, night-fog, exploration, base-building, raid-target
- Signature: An underground descent where enemies hide outside light circles. Vessa and Vey wake the Master's sleeping Wardens to your side, while Hush's acolytes race to wake the same sleepers as enemies.
- Experience: Narrow halls, a small army and no base. You light sunstones to see, wake Sunwardens (3 s with Vey near), and fight pickets in the dark. Claiming the Warden Forge at about 1:30-6:00 turns the mission into base mode with a research objective, while waves race you for the remaining sleepers. Hall 3 brings Mother Hush's rematch with her Night of Knives. The finale is a 45 s channel at the Sunrise Gate with Vey beside you, while amber Wardens burst from the floor. The sim lasts 14:40 against a 17-23 target.
- Sim: tag run timed out (load). The 2026-10-16 nightly won at 14:40 (16:05), with Wardens 3, stones 6, 3 researches, Hush fled, gate at 100 %, G1 survivors 13 / 13. That is comfortable. The built notes say the waves' timers set the length, not the player.
- Best moment / Weakest point: the race for the sleepers (do you wake them first, or do the acolytes?) / "Research twice at the Ember Forge" is a menu chore wedged into a dungeon crawl. The forge claim lands so early (1:30 in the sim) that the "no base" fantasy lasts only a few minutes.
- Fix ideas: (1) Gate the forge claim behind Hall 2's sleepers (needs 3 Sunwardens), so the small-squad part lasts 6+ min. (2) Replace the research objective with "forge the gate key" (one research that visibly makes the key). (3) Show sleeping Wardens on the minimap as grey eyes that turn gold / amber, so the race is readable.

### mission_e2_05 — The Light Below   Grade: C (5.83)
- Scores: Hook 8 / Clarity 5 / Pacing 5 / Challenge 5 / Story 7 / Payoff 5
- Tags: boss-fight, capture-points, ally-control, base-building
- Signature: A seal tug-of-war around the Master's door. Each seal's colour when the jailer wakes changes the boss fight (amber seals make it tougher), and you must protect the Door's HP, not just your base.
- Experience: Phase 1 is a 2v2 in a huge cavern. Kindle four seals while Malrik walks around cracking them back. Torvald's covers hit at 5:00 and 9:00, waves come, and from 8:00 you can build a Roost for a Cinder Dragon. The wake cannot come before 13:00 (a hard floor added in tuning). Then the Doorwarden boss runs three phases: a burst, Malrik's healing tether (kill or drive him off), and Vessa + Vey at the Door calling Sunlances. In the sim the whole boss fight lasted 2:35.
- Sim: victory at 15:35 (17:01) against a 25-31 target. Wake 13:00, Door min 83 % (the Hold never needed), lances 3, dragon 1. The built notes (2026-10-07) said B2 wiped the army every run; after tuning, the boss is now a 2.5-minute formality. That is an unstable balance swing for an episode finale.
- Best moment / Weakest point: the faint voice of the Master behind the Door when Vessa walks up to it / The finale boss is still a grey placeholder capsule (`mission_e2_05.gd` 477: `model_scene = null`) with no boss bar UI, and its three phases blur by in about 2.5 minutes. The 13:00 wake floor means a fast player waits.
- Fix ideas: (1) Give the Doorwarden at least the M04Look treatment (a code-built statue with kneel / glow) and a boss bar. This is the cheapest big win in the set. (2) Let the wake fire when the seals are settled (all 4 owned for 60 s), not on a floor timer. (3) Raise B2 / B3 back toward 2-3 min each (more boss HP in B2 only), so the tether puzzle has time to be understood.

### mission_e3_01 — Take the Ford   Grade: C (6.5)
- Scores: Hook 7 / Clarity 7 / Pacing 5 / Challenge 6 / Story 8 / Payoff 6
- Tags: base-building, capture-points, river-water, siege, ally-control
- Signature: The point-of-view flip. You play Malrik, the villain of two episodes, against bot Vessa and Ysolde, attacking across a slowing ford with a Torvald ally bot.
- Experience: A siege-style 2v2. Build up on the north ridge, then fight for a ford zone (60 s uncontested, slowed in the water) while Vessa raids your workers with riders and Ysolde charges at 70 % of the ford. Next you take three standards at the foot of Lark Hill (horn spires keep feeding relief) and hold all three for 2:00 against both enemy wizards. The Gloom Deacon's Umbral Passage (pulling soldiers across the river) is the clever tool. The sim takes 23:52 (24:44), and almost half of it is spent before the ford is taken (11:38).
- Sim: victory at 23:52, horns 2 / 2, Vessa driven off, hero HP 85 % after W3, about 38 Heartbeats. The phase log shows standard / regroup looping (4 regroups), which matches a grinding standards phase. The first build was "not green" until a smarter scripted player was written.
- Best moment / Weakest point: Obren's heart-stone talking in Malrik's pocket at the river, and Vessa as the enemy / The ford alone is a 10-minute meat-grinder. The standards plus the hold is another "own 3 points for N minutes" ending.
- Fix ideas: (1) Have the ford also complete on a Deacon Passage plus a landing hold (an alternative to the frontal push), so the cleverness is rewarded with time. (2) Cut the hold to 1:00 and make the Final's two wizards the target (drive both off = win). (3) Give the standards a visible capture-rate number per soldier count.

### mission_e3_02 — Another Night   Grade: B (7.33)
- Scores: Hook 9 / Clarity 7 / Pacing 8 / Challenge 5 / Story 9 / Payoff 6
- Tags: stealth, night-fog, small-squad, raid-target, defend-hold
- Signature: The only stealth mission. Mother Hush's commando snuffs fires, stays out of firelight, lures alarms away from an invulnerable sentry Old Vey, and sabotages four wagons before dawn. It mirrors mission_00 from the knife's side.
- Experience: A tight night clock (Dawn in 8:12). Concealment comes from darkness (enemies see you only within 6 m, a veiled Hush within 3 m), fuses fill on spotters, and three alarms escalate up to "Vessa wakes and hunts you for 90 s". Old Vey cannot be hurt, so you have to time his walk or raise a decoy alarm far away. After the 4th wagon, the second phase switches you to Malrik, whose keep is now a Citadel, for a 2:30 hold at first light, where you call Hush as a helper for the first time. Total about 11-14 min.
- Sim: the 2026-10-16 nightly won at 10:28 (11:40), with the night finished at 7:56 against the 8:12 dawn (16 s spare), 4 / 4 wagons, 3 alarms. The tag run LOST at 8:20 with 3 / 4 wagons and dawn first. The lead bisected this to a visual-only commit (determinism), so it is not a design flaw by itself. Still, a 16 s margin for the scripted player means a normal human who raises alarms is on a knife's edge.
- Best moment / Weakest point: slipping past Old Vey's vigil veiled, Hush's "There is always another night" coming back / Phase 2 (a 2:30 base hold as Malrik) is a generic ending bolted onto a unique stealth mission. The dawn clock is very tight for anyone who isn't playing perfectly.
- Fix ideas: (1) Add +45 s to the dawn on normal (or +20 s per wagon spoiled), so stealth mistakes are recoverable. (2) Replace the phase-2 hold with the dawn cutscene plus the helper call in a shorter 1:00 "the camp counterattacks" beat, or make it a Hush escape run to the ridge. (3) Show each spotter's sight cone or radius when Hush is selected.

---

## Summary table

| id | grade | tags | signature |
|---|---|---|---|
| mission_00 | B (8.0) | hero-only, small-squad, timed-survival, night-fog, tutorial | Mentor dies mid-mission; his death powers the last stand |
| mission_01 | C (6.17) | base-building, artifact-hunt, tutorial, defend-hold | Three braziers to break a seal, then hold the crown |
| mission_02 | B (7.67) | base-building, artifact-hunt, puzzle-environment, rival-wizard-race, chase-flee | Fireballs crack the lake under enemy armies; reverse escape with walls rising |
| mission_03 | C (6.83) | base-building, rival-wizard-race, artifact-hunt, chase-flee, exploration | Champions steered only by bounty flags in a 3-way heart race; Malrik carry chase |
| mission_04 | B (7.17) | base-building, boss-fight, capture-points, river-water, siege | Every death feeds the boss; you choose when the finale starts |
| mission_e2_01 | C (6.0) | defend-hold, waves-onslaught, rescue, base-building | Frost clock to kindle the Heartwood, then a 12-min hold |
| mission_e2_02 | C (6.33) | ally-control, escort, capture-points, base-building, defend-hold | Escort the ally's planters; a 4th kingdom regrows mid-mission (2v1 -> 2v2) |
| mission_e2_03 | C (5.67) | economy-twist, convoy, escort, base-building | Win by paying gold: caravans, tributes, thieves |
| mission_e2_04 | B (7.0) | small-squad, night-fog, exploration, base-building, raid-target | Dark halls; race the enemy to wake sleeping Wardens to your side |
| mission_e2_05 | C (5.83) | boss-fight, capture-points, ally-control, base-building | Seal tug-of-war sets the boss's strength; protect the Door, not the base |
| mission_e3_01 | C (6.5) | base-building, capture-points, river-water, siege, ally-control | Play the villain Malrik against bot Vessa and Ysolde across a slowing ford |
| mission_e3_02 | B (7.33) | stealth, night-fog, small-squad, raid-target, defend-hold | The only stealth mission; mirror of mission_00 from the knife's side |

Grade spread: 0 A, 5 B, 7 C, 0 D/F. No mission in this set reaches the WC3 bar of an A. The strongest are m00, m02,
e3m2 and m04. The weakest, e2m3 and e2m5, are let down by their endings, not their hooks.

## Missions in this set that feel too similar

1. **The timed hold ending is everywhere.** m01 (hold 2:00), e2m1 (hold 12:00), e2m2 (Vice 2:30), e2m3 (guides 1:30),
   e3m1 (hold 2:00), e3m2 phase 2 (hold 2:30), plus m00 (survive until dawn). That is 7 of 12 missions closing on
   "survive a timer". Episode 2 does it three missions in a row (e2m1, e2m2, e2m3). This is the single biggest sameness
   problem.
2. **"Stand Vessa next to a thing for 3 s" is the main verb.** Braziers (m00, m01), Emberguard blocks (m02), the Master's
   seat (m04), the Heartwood kindle (e2m1), sunstones and Warden waking (e2m4), seals (e2m5), the gate channel (e2m4). It
   works, but by Episode 2 it no longer feels like a new mechanic.
3. **The two finales use the same boss gimmick.** m04 ("Turn the key: Vessa by the Colossus's heart, with Old Vey beside
   her", Exposed windows) and e2m5 ("Stand Vessa by the Door with Old Vey", Sunlances, Exposed bursts). Both are 3-phase
   bosses with Vey-adjacency as the final phase and Malrik as a third party. e2m5 should find its own final verb.
4. **The "enemy progress meter racing you" pattern repeats.** m02 (dig %), m03 (heart drains), m04 (Hollow %), e2m1
   (frost %), e2m5 (wake % + seal cracks). Each is fine alone, but five meters in nine Fire missions blur together.
5. **The map skeletons are reused.** m00, m01, m02, m03 and e2m1 all use the same Fire corner (keep at (-43, 43),
   pre-built Ember Hall at (-27, 45)) against the same Shadow camp slots (Dusk Keep (43, -43), Gloom Hall (27, -45),
   Night Spire (37, -29)). e2m1 is literally m03's seed 1303 burnt, and m00 is m01's seed 1101 at night. m04, e2m2 and
   e2m3 all play on Crown Hollow terrain. m01, m02 and m03 feel like the same base on three skins.
6. **The waves are the same.** Shades + Nightbolts + Grave Hounds (+1 Shadow Knight, later + a Gloom Deacon) make up every
   Shadow wave from m00 to e2m5, and "Grave Hound raids on the nearest worker / carrier / caravan every 150 s" appears in
   m01, e2m1, e2m2 and e2m3. The roster gives no sense of escalation across two episodes.
7. **Mother Hush's Blink-ring dodge is taught three times.** m00, then the e2m4 rematch, then the e3m2 player side. The
   e2m4 version adds Night of Knives, but the core dodge is the same. Acceptable as a recurring nemesis, but e2m4 should
   test something new.

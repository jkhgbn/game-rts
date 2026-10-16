# Campaign review 2026-10-16, part 2: e3m3 - e6m2 (12 missions)

Reviewer: a review agent, playing on paper. Sources per mission: the design doc (`docs/design/mission-*.md`), the
script's header and its "Built deviations" (`scripts/campaign/mission_*.gd`), and the bot playthrough logs of tag
playtest-2026-10-16 (`docs/ci/playtest-2026-10-16/error_lab/logs/test_<x>_sim.log` + the rush / passive / shut variants).
All 19 sims in this set PASS (no load timeouts). All in-mission cutscenes exist as baked `.tres` (`test_cine_*` PASS).
The bar is the Warcraft III campaign. Margins come from the sim's own counters (objective HP minimums, losses, hero HP).

Two things recur across the set and drag several grades down, so they are stated once here:
- **Rush floors become dead time.** To stop rushes, six missions block the win behind a clock: e5m1 (dusk 10:00), e5m2
  (the Nest "won't burn past half" before 14:00), e5m3 (the bell only rings at 10:00), e5m4 (the count only opens at
  15:00), e4m4 (the Winterheart is frost-bound until 19:00), e6m2 (dawn / the Final). In the sims this shows up as
  minutes spent waiting: e5m3 has all three secrets read at 2:38 and the Reeve down at 11:27; e4m4 has a
  `wait_heart` phase from 12:18 to 19:00. A player feels this as "I did everything and the game made me wait".
- **Flat, code-built maps.** e3m3, e3m4, e4m1, e4m2, e4m3, e4m4 and e5m3 run on flat ground built in code ("no World
  Forge map", "no hills", "no Old Wood trees"). The fantasy the docs sell (Evenmead's hills, the Green Road's ambush
  woods, the Wall between cliffs) mostly isn't on screen.

---

### e3m3 — The Stone's Price   Grade: C (6.8)
- Scores: Hook 8 / Clarity 7 / Pacing 6 / Challenge 6 / Story 9 / Payoff 5
- Tags: base-building, defend-hold, waves-onslaught, boss-fight
- Signature: a power that costs you: the Keystone Shard's Heart of the Hollow fills "the stone's hold", and at 100 % the villain you play loses control of his own body for 5 s.
- Experience: Malrik rides home to Duskbarrow at violet dusk; the city's dead walk on the Great Crypt where the living hide. You hold the crypt from a Citadel base and walk Malrik to four barrow candles one by one, clearing each barrow first. Obren's offer comes the first time a Warden gets close, and the hold meter is a real temptation on paper. The middle is a long grind: in the sim B3 is lit at 6:00 and B4 only at 13:53. The Sexton, built from your father's graveyard, rises at 14:18 and is dead by about 15:06. 16:28 with cutscenes.
- Sim: victory 15:08; crypt never under 100 %; stone used 0 times (hold 21 % from losses alone); 0 seizures. A comfortable margin.
- Best moment: "That bell. He rang it every dusk. Stop wearing my father's bell." The boss is personal.
- Weakest point: the boss. It's a placeholder body (a scaled Ruin Warden, `model_scene = null`) with 18 000 HP that melts in under a minute, so the father's-bell scene lands on a grey blob.
- Fix ideas: (1) Give the Sexton its spec kit for real (Tomb Toss telegraphs, the 50 % Mourning Toll stagger) and make the fight at least 2 minutes: gate its damage on the toll window instead of adding raw HP. (2) Make refusing the stone hurt: with 0 uses and the crypt at 100 %, the temptation is decorative. Raise the B3 / B4 pressure so the stone is the obvious answer around 8:00. (3) Use the 6:00-13:00 gap: a Gravewarden march that targets the crypt when two barrows are open.

### e3m4 — The Storm on the Ridge   Grade: C (6.7)
- Scores: Hook 7 / Clarity 7 / Pacing 6 / Challenge 6 / Story 8 / Payoff 6
- Tags: base-building, capture-points, defend-hold, boss-fight
- Signature: a hero-boss who cannot die: you "break" Old Vey's storm three times, and the titan (Nightmare Knight) unlocks mid-mission as the answer to him.
- Experience: Back on Evenmead's ridge (the e3m1 map, now flat). You and the Torvald ally bot hold three watch points while Fire raids every few minutes. Vey and Vessa lead three assaults at about 5:50, 14:04 and 20:15, and Thunderheads force you off a point for 10 s. The Dread Paddock opens at 4:00 and the Knight's charge is the intended tool. The first storm is a real fight (~45 s, Vey kills 15). Storms 2 and 3 break in 18 s and 10 s. The whisper cutscene (the stone speaks to Torvald) and `ep3_ending` carry the end. 21:46 with cutscenes.
- Sim: victory 20:26; 3 / 3 breaks, 3 Knights, watch points never lost (3 / 3). A wide margin.
- Best moment: `e3m4_whisper`, where Obren tells Torvald "nothing will ever melt": the episode's twist, delivered in-mission.
- Weakest point: the finale storm is over in 10 seconds. The episode's climax boss is weaker than his opening act.
- Fix ideas: (1) Give storm 3 more HP or a phase (Vey's last storm: +50 % HP, Thunderheads every 15 s) so it's the hardest of the three, not the easiest. (2) Let side 1 actually threaten a point at least once (the sim never lost one): a pincer with A3's columns on two fords at once. (3) Put the ridge's height back (even a raised plateau collider) so "holding the ridge" reads.

### e4m1 — Hold Lark Hill   Grade: C (6.5)
- Scores: Hook 7 / Clarity 6 / Pacing 5 / Challenge 6 / Story 8 / Payoff 7
- Tags: rescue, defend-hold, timed-survival, river-water, base-building
- Signature: the same battle as e3m1 from the other hill: ring hamlet bells to bring 30 villagers to the Master's golden tree, then hold until nightfall.
- Experience: Ysolde opens on the crest after `ep4_opening`. The rescue the doc sells (detachments across the ford before W1 / W2) is basically over at once in the sim: four of five bells ring by 0:54, the last at 8:30. The next 13 minutes are a Malrik + Torvald wave defence at the ford and the standards (W1-W5, Hush's raid, the Final). Vey flashes onto the crest 45 s into the Final. Nightfall ends it at 22:00. That's a long fixed clock with six objectives on the panel (folk, tree, nightfall, ford, horns, Ysolde). 22:53 with cutscenes.
- Sim: victory 22:01; folk 30 saved / 0 lost; tree 3 000 / 3 000 (never hit); ford held; hero 75 % after W3. A comfortable margin.
- Best moment: Vey's lightning on the crest ("Since before you were born"): the payoff of a shot the player saw from the other side in e3m1.
- Weakest point: the rescue is solved in the first minute, so a "save the people" mission plays as a 20-minute timer defence.
- Fix ideas: (1) Gate the hamlets: bells across the river only open when W1 / W2 arrive (or the villagers need an escort once roused) so the rescue spreads over 0-12:00. (2) Make the tree a real target before the Final (Hush's raid aimed at it, not at the refuge). (3) Trim the objective panel: fold `sec_horns` into the Final.

### e4m2 — The Green Road   Grade: C (5.8)
- Scores: Hook 6 / Clarity 7 / Pacing 6 / Challenge 4 / Story 7 / Payoff 5
- Tags: escort, convoy, base-building
- Signature: four timed villager convoys that cower near enemies, so you clear the road ahead instead of guarding a cart; Maelis is called for the first time.
- Experience: From Larkrest camp you push the army west ahead of each convoy (Hollow Oak, the frozen brook, Crowstone), with a base to keep running and the Citadel + Maelis around 7:00-8:00. The sim's rhythm is escort (40-50 s) then wait (3-4 min) four times, so the mission breathes in long flat stretches. The woods meant to hide the ambushes aren't built ("no Old Wood trees"), and the escort is never in danger. 18:11 with cutscenes.
- Sim: victory 17:18; arrived 40 / 40 (needed 30), lost 0; brook done, Hollow strike skipped (failed); Maelis called 7:47. No margin issue at all: no walker was ever lost.
- Best moment: Maelis' arrival plus the Hush cutscene at Crowstone ("There is always another night").
- Weakest point: zero villagers lost means the escort has no teeth; the cower rule makes walkers safer than any cart.
- Fix ideas: (1) Let ambush bands target the walkers directly (a Hush knife-squad that skips the army and goes for the convoy's tail). (2) Put trees back along the road (even a cheap scatter like the e5 generator) so ambushes come out of cover. (3) Shorten the convoy timers or let the player send them on demand with a reward for speed.

### e4m3 — The Frozen Ashes   Grade: B (7.0)
- Scores: Hook 7 / Clarity 6 / Pacing 7 / Challenge 8 / Story 7 / Payoff 7
- Tags: capture-points, base-building, defend-hold
- Signature: regrowth as the objective: thaw, plant and root five groves that the Ice keeps trying to re-rime, then hold all five green at once.
- Experience: Ysolde returns to the burnt and frozen Sighing Wood with Maelis already at her side. Every grove is a small siege (break the 3 000 HP totems), then a 60 s growth and a 30 s rooting while Torvald and Aldra counter-attack. It's a steady push-and-defend loop across the map. Aldra's Heartglade is the skill check (the sim loses dozens of units there). The five-green hold at 22:29 and Torvald's "We were all weeds once. Pull back." close it. 25:13 with cutscenes.
- Sim: victory 24:01, all five grown, none lost (`sec_unbroken` done), hero 85 %. The rush variant won 25:18 but lost a grove. Heavy unit losses in both: real but fair pressure.
- Best moment: the Heartglade fight with Aldra, then "The Last Heartwood. You held on all winter, didn't you?"
- Weakest point: the rules are layered (totem regen, planting, growth, rooting by capture rules, re-rime) and the doc's moss and snow look isn't built, so a grove's state is hard to read at a glance.
- Fix ideas: (1) One clear per-grove widget (frozen / thawed / growing % / rooting % / green) on the minimap and over the grove. (2) Paint a cheap green disc when a grove is green and a white one when it's re-rimed. (3) Give the Heartwood Seed a real ItemType so the reward isn't just a flag.

### e4m4 — Winter's End   Grade: B (7.0)
- Scores: Hook 8 / Clarity 7 / Pacing 4 / Challenge 7 / Story 9 / Payoff 7
- Tags: siege, base-building, boss-fight, raid-target
- Signature: a full-map ice wall that heals while its Winterheart beats, broken by Nature's titan (Elder Treant), ending on Torvald saying "Enough" to Aldra.
- Experience: Ysolde and Vessa (ally bot) face a wall across the whole map, where soldiers do x0.35 damage. You wake the Sleeping Elder for a free Treant, break the West and East Gates, and kill two Wallwardens that wake out of their alcoves (9:37, 11:51). Then, with everything done at 12:18, the Winterheart stays frost-bound until 19:00 (a rush floor): almost 7 minutes of holding in front of a closed objective. After that, 20 000 HP of heart, the walk to the Glass Spire, and the episode's best scene. 23:14 with cutscenes.
- Sim: victory 21:59; both wardens down, Elder woken, 2 Treants, Frost Halls skipped (failed); hero 38 % after I2. A real but survivable margin.
- Best moment: `e4m4_enough`, Aldra's chisel raised and Torvald's "Enough, Aldra." ("Why?") It's the seed of Ep7 and a true Warcraft-style turn.
- Weakest point: the 12:18-19:00 `wait_heart` phase. The player has broken the wall's guardians and is told to wait.
- Fix ideas: (1) Replace the 19:00 clock with a task: the Winterheart opens when both Frost Halls fall (`sec_halls` becomes the key) or after a channel by Ysolde under fire. (2) Give the Wallwardens their 1.6 scale and Avalanche telegraph so the two boss kills look like boss kills. (3) Use real gates (doors that open for side 1) so the waves pour out of the wall instead of stepping out beside it.

### e5m1 — The First Spark   Grade: C (6.0)
- Scores: Hook 5 / Clarity 8 / Pacing 6 / Challenge 4 / Story 7 / Payoff 6
- Tags: tutorial, base-building, timed-survival
- Signature: the basics refresher as a flashback, with twelve-year-old Vessa and Old Vey in his prime (sword only, his lightning kept secret).
- Experience: Light five signal beacons in any order while border reivers loot farms; the hints re-teach walking, gathering, building, attack-move, Fireball and levelling. Vey teaches through barks. After the 5th beacon you hold to dusk (the rush floor: never before 10:00 on normal) or drive Gannet off below 40 %. It's charming and readable, with no tension. 13:01 with cutscenes (rush variant 10:29, all five beacons lit by 2:48).
- Sim: victory 12:06 (rush 9:34); 8 losses on the paced run; `sec_farms` failed in both runs (0 farms saved).
- Best moment: the camera-only flicker of Vey's lightning she never sees, a lovely piece of continuity with Ep1.
- Weakest point: five more "stand next to a brazier" objectives; the campaign has used this verb many times by now. Also `sec_farms` fails in every sim, which suggests it can't be won.
- Fix ideas: (1) Check `sec_farms`: if a careful bot never saves a farm, slow the first farm raid or give Vessa a warning ping 20 s ahead. (2) Give each beacon a different small puzzle (one guarded by boars you lure away, one on the bridge you must hold, one that needs the Hall built) instead of the same channel. (3) Drop the dusk floor to "Gannet must appear" so a fast player still meets the boss instead of waiting.

### e5m2 — Burn a Door   Grade: C (6.8)
- Scores: Hook 8 / Clarity 7 / Pacing 6 / Challenge 7 / Story 7 / Payoff 6
- Tags: siege, base-building, raid-target
- Signature: the heroine's flaw is the rule: Vessa walking into the reeds with fewer than 4 soldiers springs an ambush; fire does double damage to the wooden fort.
- Experience: Fifteen-year-old Vessa's first command. You pick the short Causeway through three reed fields or the long Dyke, learn Ashby's drill aura (4 Ember Archers near him = burning arrows), train Ash Hurlers and burn Rookhold's gate, two watchtowers, then the Nest. The paced sim spots all three bands and never springs one. The Nest won't burn past half before 14:00 (the rush floor), so a strong player finishes the siege and waits. 15:14 with cutscenes.
- Sim: victory 14:06, 3 bands spotted / 0 sprung, both towers down, Ashby wounded twice. The rush variant (Vessa running ahead) dies at 1:41, which is the lesson working exactly as designed.
- Best moment: Ashby's "There already was a door, my lady. It had a latch." The humour lands.
- Weakest point: the "fen-wet timber" timer: the mission's own fantasy (burn it down) is blocked by a clock rather than by defenders.
- Fix ideas: (1) Replace NEST_DRY_AT with a defence: Gannet's last garrison (or a sally from the Postern) spawns when the Nest hits 50 %, and the Nest burns when it's dead. (2) Make the drill a timed volley (the spec's shared timing) so it's visible as a mechanic, not a +25 % aura. (3) Show the reed fields' 12 m trigger ring when Vessa is near with fewer than 4 soldiers.

### e5m3 — Tombstones by Candlelight   Grade: B (7.2)
- Scores: Hook 9 / Clarity 6 / Pacing 4 / Challenge 7 / Story 9 / Payoff 8
- Tags: stealth, small-squad, night-fog, puzzle-environment
- Signature: the campaign's only true stealth mission: a candle toggle (see and read, or hide and snuff lamps), shadow zones, wardens you knock out but never kill, and grave gifts that tempt a thirteen-year-old.
- Experience: Malrik at thirteen, two dogs, and Shades that burn in light. He moves between violet shadows, snuffs lamps, calls old graves and reads three tombstone secrets while lantern patrols search. It's tense, original and very in character. Then the sim reads the last secret at 2:38 and the bell can only ring at midnight (10:00): a long wait in the dark ("home" phase 3:05-11:27). The Reeve fight and `e5m3_found` ("This one, too.") close it. 12:25 with cutscenes.
- Sim: victory 11:28, 3 / 3 secrets, `sec_quiet` and `sec_hands` done, 7 losses. The rush variant is caught at 6:17 (3 alarms, 2 wakes). The stealth bites.
- Best moment: the Master behind the boy among the graves: "Reading tombstones by one candle, at midnight. And they told you everything."
- Weakest point: seven minutes of nothing between the last secret and midnight. The best mission concept in this set has the worst dead time.
- Fix ideas: (1) Fill the wait with play, not a clock: 2-3 more optional tombstones (lore, XP) and the Magpies' sack to steal back, or midnight arrives early once the 3 secrets are read and a 60 s "the town settles" timer passes. (2) Show light radii on the ground (lamp and lantern circles) so the "lit / hidden" rule reads without the HUD. (3) Name the danger: an alarm meter on screen (0 / 3).

### e5m4 — Leftovers   Grade: C (6.8)
- Scores: Hook 8 / Clarity 7 / Pacing 5 / Challenge 6 / Story 8 / Payoff 7
- Tags: rival-wizard-race, capture-points, base-building, stealth
- Signature: a friendly 1v1 against the heroine with an asymmetric rule set: Malrik is hidden in the citadel's shadow and steals banners twice as fast, against a scripted Vessa who always overreaches.
- Experience: Malrik, 18, versus Vessa, 17, on the Master's practice field, with the family watching from the terrace. Five banners, three at once plus a 30 s bell wins. Vessa takes the field fast and charges, leaving her home banner thin, and you steal it from the orchard shade (the sim's steal / hide / defend loop from 9:00). But Old Vey only starts counting at 15:00 on normal, so the first quarter-hour of banner play decides nothing. The sim wins 32 s after the count opens. The ending (Master, then `ep5_ending`) is warm. 16:17 with cutscenes.
- Sim: victory 15:32 (banners Malrik 3, Vessa 2; 5 spoils; 3 charges answered). The passive run loses at 15:34, so a player who doesn't engage loses.
- Best moment: "You taught us to use what we were given. I was given leftovers. I used them."
- Weakest point: the bell starting at 15:00 turns a race into a long warm-up; holding three banners at 8:00 feels pointless.
- Fix ideas: (1) Count from the start, but make the count longer (60-90 s) and reset on any steal, so early leads matter and a rush is still answerable. (2) Show Vessa's next scripted move as a terrace bark ("She's looking at the mill banner") so outplaying her personality is a read, not luck. (3) Keep the 6:00 yard truce, which works.

### e6m1 — A Hundred Winters   Grade: C (6.2)
- Scores: Hook 6 / Clarity 7 / Pacing 6 / Challenge 4 / Story 8 / Payoff 6
- Tags: defend-hold, timed-survival, waves-onslaught, base-building
- Signature: the M2 lake turned around: floes crack under the stone Wardens' weight and hold under Torvald's army.
- Experience: A hundred winters ago the Master leaves the Heartfrost with Torvald; a fisher girl, Aldra, refuses to go home. Three winters (blizzard, enemy slowed, your sight down) and two thaws give a clear rhythm; Aldra carves two Sentinels in thaw 1 for free Colossi; the Stair-Breaker leads the last winter. The mission ends on a fixed clock (19:00). In the sim the lake trick never happens (0 floes broken, 0 sunk) and the Heartfrost is never touched. 20:10 with cutscenes.
- Sim: victory 19:00; Heartfrost min 100 %; 2 Sentinels carved; longhouse kept. The passive run loses at 4:02, so there's a floor, but an engaged player is never threatened.
- Best moment: the Master's "You are my patience, Torvald" and the narrator's "It did not thaw for a hundred winters."
- Weakest point: the signature mechanic is optional to the point of invisible: the bot wins without a single floe breaking.
- Fix ideas: (1) Route the big waves (Breakers, the Stair-Breaker) across floes and make them too strong to stop on land, so sinking them is the intended answer. (2) Add a "Floe cracking" ping and a Rime Bolt hint the first time Wardens step on a floe. (3) Lower Heartfrost HP or send one winter-3 group from the barrow straight at it, so `obj_heartfrost` matters.

### e6m2 — The Rider at the Gate   Grade: C (6.8)
- Scores: Hook 8 / Clarity 7 / Pacing 6 / Challenge 5 / Story 8 / Payoff 7
- Tags: branching-choice, defend-hold, escort, timed-survival, base-building
- Signature: the campaign's first real moral choice inside a mission: open the ice gate to save a burning town (two fronts) or keep it shut (the town burns), saved for Episode 8.
- Experience: Torvald builds up behind a sealed gate while smoke rises over Hearthwick. At 5:30 a rider begs; you have 1:30 to choose. Open: you escort 24 townsfolk through while the Hollow strikes the mere from below. Shut: a wall defence while the town burns, with "You can SEE it!" in your ears. Breaking both Warden Gates (or the 20:00 dawn) ends it, with one dawn cutscene per branch. 17:35 (open) / 20:46 (shut) with cutscenes.
- Sim: open = victory 16:50, saved 24 / 24, both gates broken, Heartfrost min 100 %; shut = victory 20:01, Heartfrost min 100 %. Neither branch ever puts the lake at risk.
- Best moment: the shut branch's snow burying the signal fire. It's the prologue's memory, played.
- Weakest point: the "costly" branch costs nothing: open saves everyone and the Heartfrost is never scratched, so the dilemma has no teeth.
- Fix ideas: (1) In the open branch, time the lake strike to the townsfolk crossing so the player must split the army and likely loses some people or Heartfrost HP. (2) Let the shut branch pay off with an easier, faster end (dawn at 16:00) so it's a real trade, not just the slower path. (3) Show the saved count on the dawn screen with the Ep8 consequence in one line.

---

## Summary table
| id | Grade | Tags | Signature |
|---|---|---|---|
| e3m3 | C (6.8) | base-building, defend-hold, waves-onslaught, boss-fight | A tempting power with a visible price (the stone's hold) |
| e3m4 | C (6.7) | base-building, capture-points, defend-hold, boss-fight | An unkillable hero-boss you break three times; titan unlocked as the answer |
| e4m1 | C (6.5) | rescue, defend-hold, timed-survival, river-water, base-building | e3m1's battle from the other hill: bells, villagers, the golden tree, nightfall |
| e4m2 | C (5.8) | escort, convoy, base-building | Cowering villager convoys; you clear the road ahead |
| e4m3 | B (7.0) | capture-points, base-building, defend-hold | Regrow five frozen groves and hold all green at once |
| e4m4 | B (7.0) | siege, base-building, boss-fight, raid-target | A healing full-map ice wall broken by the Elder Treant; Torvald's "Enough" |
| e5m1 | C (6.0) | tutorial, base-building, timed-survival | Basics refresher as a flashback with young Vessa and prime Vey |
| e5m2 | C (6.8) | siege, base-building, raid-target | The heroine's flaw as a rule: going in alone springs the ambush |
| e5m3 | B (7.2) | stealth, small-squad, night-fog, puzzle-environment | True stealth: candle toggle, shadows, knock-outs, grave-gift greed |
| e5m4 | C (6.8) | rival-wizard-race, capture-points, base-building, stealth | Friendly asymmetric 1v1 banner race against a scripted, overreaching Vessa |
| e6m1 | C (6.2) | defend-hold, timed-survival, waves-onslaught, base-building | Floes crack under the enemy, hold under you (unused in the sim) |
| e6m2 | C (6.8) | branching-choice, defend-hold, escort, timed-survival, base-building | Open the gate or let the town burn, saved for Ep8 |

No mission in this set reaches A. Three Bs (e4m3, e4m4, e5m3), nine Cs. The writing is consistently the strongest
column (7-9 everywhere). Pacing and challenge are consistently the weakest: most margins are wide (objective HP at 100 %,
0 villagers lost) and the dead time comes from rush-floor clocks.

## Missions in this set that feel too similar
- **e6m1 and e6m2**: both are Torvald with Aldra defending the Heartfrost from the same Ruin Wardens and a named Warden
  Breaker elite, on a fixed clock (19:00 / 20:00), with the Heartfrost never under 100 % in the sims. Only e6m2's choice
  keeps it apart; without it they're the same mission.
- **e3m3, e4m3, e5m1 (and the e4m1 bells, the e4m4 Elder)**: "walk the hero to a point and channel while no enemy is
  near" (candles, groves, beacons, bells, the Sleeping Elder). It's the MissionBrazier verb from M1 / e2m1, used five
  times in this set alone. e4m3 earns it with growth and rooting; e5m1 doesn't.
- **e3m4 and e4m1**: the same Evenmead map (flat in both), a 2v2 with a story ally, holding points or standards against
  scripted assaults on a long clock, and an Old Vey lightning beat. They're mirror missions by design, but the mirror
  is the map and story, not the play.
- **e4m3 and e4m4**: back to back, both Ysolde with Maelis called from 0:00 against Torvald and a fleeing Aldra in
  snow, both "break Ice structures, then hold". e4m4's wall and titan set it apart, but the enemy roster and the
  opening are the same.
- **e4m1, e4m2 and e6m2 (open branch)**: autonomous villager walkers (meadow_folk / townsfolk) that the player can't
  order and never loses in the sims. Three missions with the same unit and the same zero stakes.
- **Base-building everywhere**: 11 of the 12 missions are "start with a base, build an army, survive scripted waves".
  Only e5m3 changes the genre (stealth, small squad). There's no hero-only, chase or exploration mission in this
  stretch, which is where a Warcraft III campaign would break the rhythm.

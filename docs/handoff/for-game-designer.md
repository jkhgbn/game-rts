
## 9.D4 input from the lead (2026-09-26, 9.C11 runs, normal bot vs normal bot, test_9_c11.gd)
The test also places, like a player: Escort 50 + Guard 50 at 7:00 / 12:00 and one Hunt 75 near a champion from 5:00.
| Pair (player:enemy) | With champions | Control, no champions (--no-champions) |
|---|---|---|
| fire:shadow | fire wins 10:08 (1st run: shadow champions died 8x, max L1) and 9:08 | fire wins 16:53 |
| shadow:fire | fire wins 14:23 | fire wins 13:54 |
| nature:ice | nature wins 10:37 | nature wins 9:31 |
Hires (normal): Coin-Cutter 3:04-4:18, Oathwall 3:14-6:36 (both sides, every run). Bounties paid mostly Guard / Escort ticks.
Question for 9.D4: do champions snowball the side that is already ahead (fire:shadow 16:53 -> ~9:30)? One run each: re-run
--pair=fire:shadow a few times (and with --no-champions) before changing knobs. Avg frame 2.9-3.8 ms.

## rush-balance.md: Frostbow removed (from 13b.D1, 2026-09-26)
User decision (13b Q3, "change the bow, but reuse what's already been made"): the step-16 **Frostbow** is dropped (never built).
Its Frost Hall slot N and anti-cavalry role go to the tier-3 **Frostrune Rifleman**; its **Hamstring Shot** moves to the
**Shardcaster**, active from the Stronghold (`ability_params.min_keep_tier` 2). The full edit list for `rush-balance.md`
(sections 0-1, 2.1, 5, 5.1-5.4, 7.3, 9, 11.4 D25, 12.1, 13-15, "10 new units" -> 9, 16.V7 cancelled) is in
`docs/design/tier3-extras.md` section **16a**. Not applied to `rush-balance.md` yet (the 13b task did not edit it).

## map-fill.md 7 / ai.md rules 11-13: what 12.A1 built (from ai-coder, 2026-09-26)
`ai.md` still needs its rules 11-13 section (map-fill.md 14); the code follows map-fill.md 7 with these readings, please
confirm or change in the spec:
- 11a ratio: `creep_ratio x camp strength` is checked against the strength of the soldiers actually sent (the rally army
  minus the 2-unit reserve and any capture squad), not the whole `own_strength`. With the real camps, `own_strength` let
  2 soldiers + wizard walk into the wallow and 3-4 into the nest, and they retreated every time; the group rule gives the
  5.4 fight checks (3-4 soldiers for a wallow, ~6 for a nest, 10-12 for the stag). The stag's 900 floor still uses
  `own_strength`. Same for 11e beasts (`beast_ratio`). Normal wallow creep then lands ~2:30-3:00 instead of ~2:00-2:30.
- 11a extras: a creep needs >= 2 soldiers at >= 60 % average HP; after a creep turns back (HP < 50 % or a rule-1 recall) no
  new creep for 30 s; a creep gives up after 120 s. The ford nest allowed = the Mirefang camp nearer to the own keep.
- 11e: "the three lairs of its own bank" read as own-bank Tusker / Roc / Direwolf (the own-bank Grizzlemaw Den is nearer
  the enemy); hard adds the Grizzlemaw nearer to its own keep (across the road bridge).
- 12a: squads walk around a living camp their straight way passes within 12 m of; the soldier the scout rule wants next
  (cheapest = Grave Hound, also the fastest) is kept out of squads from 40 s before a scout is due.
- 12b: the owner knows a point is being taken from its state (like the "The enemy is taking X!" message), who / how strong
  only from its fog. A POINT sortie is not recalled by a rule-1 intrusion at that same point.
- 12c: squads leave so as to stand in the own shrine `shrine_lead` s before it wakes (0 on easy / normal = at the waking,
  15 s on hard), from the straight-line walk time x 1.25; easy (no squad) sends the wizard.
- 13a: with a river the fog scout takes the new loop; on another bank it walks through a road bridge (or a ford whose nest
  is cleared), on the same bank around living camps; fog-grid points on water, on the isle while the wardens live, within
  13 m of a living camp or inside a living beast's lair are skipped.

## From ai-coder, 20.A3 (bot think time + attacks), 2026-09-26: please fold into ai.md rules 1 / 7 and the Difficulty table
- Rule 1: an intruder standing on the crown isle while the Ruin Wardens live (15 m of (0, 0)), or inside a living neutral camp
  (10 m of its spot) or beast lair, is not chased (a hit on a building / worker still counts). The forward hall's 28 m circle
  reaches the isle: whole defending armies died to the wardens there.
- Rule 1 "minor defence": intruders <= 35 % of the home strength, farther than 30 m from the keep -> only the nearest home
  soldiers worth 2x the intruders (2 at least) fight; the rest holds the rally and rule 7 may still launch (a raiding champion
  kept the Fire bot "defending" ~48 % of its ticks, so it never attacked).
- Rule 7 strength: power = own_strength + the own wizard when he joins this attack (HP >= 70 %), like seen_strength counts
  the enemy wizard. New knobs (normal / easy / hard): `attack_ratio_floor` 0.8 / 1.2 / 0.7 - once the army is gathered
  (pop + 80 % at the rally) the ratio falls from attack_ratio to the floor over `attack_patience` 90 / 180 / 60 s;
  `first_attack_by` 600 / 900 / 480 s - no attack yet: the floor at once; `attack_full_pop` 20 / 24 / 16 - launch anyway with
  this army pop gathered. Reason: seen_strength keeps every tower ever seen plus the enemy wizard and champions for
  memory_seconds, so attack_ratio x seen became unreachable after ~6:00 (Fire bot: 0 attacks in 30 min).

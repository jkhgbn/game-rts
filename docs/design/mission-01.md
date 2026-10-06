# Campaign mission 1: "The Crown in the Ashes" (Vessa)

Task 5.D2. Built in step 7 (proposed ids 7.S1-7.S3, 7.U1, 7.A1, 7.D1 at the end). First Fire mission; target
**15-20 min** on normal. Uses the rules of the 1v1 (`skirmish-1v1.md`), levels, spells, items and the numbers
of `balance-1.md`. New scene `missions/mission_01.tscn` + `missions/mission_01.gd` (systems);
`scenes/main.tscn` stays the smoke-test map until the lead switches the smoke test.
Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `y = 0`, `+z` = south.

## Story setup (briefing text, 3 short paragraphs)
1. The God Wizard vanished between one breath and the next. He left four apprentices, four kingdoms and not
   one word of instruction. His regalia fell across the world like sparks from a kicked fire.
2. One spark still glows: the **Ember Crown**, sealed in **Emberfall**, the Master's burnt-out observatory on
   the border between the Fire and Shadow kingdoms. Three old braziers hold the seal shut.
3. Vessa, the youngest and least patient apprentice, rides out the night she hears of it. Malrik of Shadow got
   there first and is camped at the far end of the ruins. He cannot light a brazier. She can.

## Map: "Emberfall" (120 x 120, the `main.gd` generator, **not mirrored**)
Same generator style as Crown Hollow: seeded trees and rocks, the lane from the Fire base to the Shadow base
(width 5), clearings where listed (no trees / rocks inside). Seed fixed per mission (`MAP_SEED := 1101`).
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / Fire keep | `(-36, 36)` / `(-43, 43)` | 18 | As the 1v1 |
| Ember Hall (pre-built, complete) | `(-27, 45)` | - | Fire mirror of slot H1 |
| Node `m1_fire_a` / `m1_fire_b` | `(-46, 34)` / `(-34, 46)` | - | **1 500** each |
| Node `m1_west` (expansion) | `(-48, -4)` | 7 | **2 000**, near the peddler; hall spot `(-41, -3)` |
| Node `m1_south` | `(6, 46)` | 7 | **1 500**, near Brazier 3; hall spot `(-1, 47)` |
| **Brazier 1 "Hearthward"** | `(-22, 22)` | 6 | 20 m from start: the tutorial fight |
| **Brazier 2 "Westwatch"** | `(-44, -20)` | 8 | Shadow outpost around it |
| **Brazier 3 "Southgate"** | `(22, 44)` | 8 | Neutral warden camp |
| Ruin Peddler "Pell" (caged) | `(-24, -6)` | 6 | Secondary objective 1 |
| Lost Caches | `(-8, 28)` and `(30, 20)` | 3 | `items.md` loot, appear at 2:00, reopen 180 s |
| **The Ember Crown** (sealed) | `(0, 0)` on the pedestal, pillar ring r 8 (gaps facing `(-1, 1)` and `(1, -1)`) | 12 | Sealed until the 3 braziers burn |
| Dusk Keep (Malrik's outpost) | `(43, -43)` | 18 | 2 500 HP (`balance-1.md`), shoots |
| Gloom Hall / Night Spire / Hovel | `(27, -45)` / `(37, -29)` / `(50, -46)` | - | Bot slots H1 / S1 / V1 of `ai.md` |
| Shadow nodes | `(46, -34)` / `(34, -46)` | - | 1 500 each |

**Brazier** (new prop, systems): a stone bowl 1.2 m wide, 1 m tall, cold grey `(0.35, 0.33, 0.3)`; lit = orange
flame particles + light `(1.0, 0.5, 0.15)`, energy 2, range 8. Lighting: **Vessa within 3 m for 3 s** (progress
ring on the ground; leaving the 3 m resets it, damage does not). Only Vessa can light one. A lit brazier stays lit.
Each lit brazier draws a flame line on the minimap toward the crown and adds a crack to the seal (3 = broken).

## Start state
| Item | Value |
|---|---|
| Vessa | Level 1, Fireball rank 1, full HP / mana, empty inventory (campaign start); **level cap 5** this mission |
| Crystals / essence | 300 / 150 (essence +1 / s as the 1v1) |
| Buildings | Keep (tier 1, Stronghold from 3:30: section "Tiers"), Ember Hall (complete) |
| Units | 5 Cinder Hands gathering (3 on `m1_fire_a`, 2 on `m1_fire_b`), 4 Flame Guards + 2 Ember Archers at `PLAYER_START + (4, -4)` |
| Population | 11 / 20 |
| Malrik's side | Dusk Keep, Gloom Hall, Night Spire, Hovel, 4 Gloom Thralls gathering, 4 Shades at his rally `(30, -30)`, Malrik level **3** (Lance r2, Siphon r1) at `(36, -36)` |

## Unlocks (what exists in this mission)
| Kind | Available | Locked (comes later) |
|---|---|---|
| Buildings | Hearth, Ember Hall, Ember Spire | - |
| Units | Cinder Hand, Flame Guard, Ember Archer; **Blaze Rider when Brazier 2 is lit**; **from the Stronghold** (section "Tiers"): Pyre Adept, Cinder Arbalest (Ember Hall), Kilnwarden (keep, B) | Ash Hurler (mission 2); the Citadel, Ashveil Saboteur, Old Vey |
| Keep | **Stronghold** upgrade (X, 200 crystals, 60 s, from 3:30) | Citadel |
| Spells | Fireball (L1), Ember Step (L2+), Kindle (L4+) | Nothing extra; cap L5 |
| Items | Base shop (keep, halls): 10 components, mids, Ember Draught, Dusk Vial, Homeward Seal, the exchange. Peddler stock after he is freed | Top items are sold but out of reach on purpose (~2 000 essence max) |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_braziers` | Primary | `Light the braziers of Emberfall (0 / 3)` | 3 braziers lit |
| `obj_crown` | Primary (appears after `obj_braziers`) | `Claim the Ember Crown` | Vessa takes the crown (`pickup_radius` 2.2) |
| `obj_hold` | Primary (appears after `obj_crown`) | `Survive Malrik's counterattack (2:00)` | 120 s pass, or Malrik is killed during the hold |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `sec_peddler` | Secondary | `Free the Ruin Peddler` | The 3 Shade jailers at the cage are dead; Vessa within 4 m of the cage |
| `sec_outpost` | Secondary | `Burn Malrik's Gloom Hall` | The Gloom Hall at `(27, -45)` is destroyed (the bot never rebuilds it in this mission) |
States through `Events.objective_changed(id, state)`: `"active"`, `"done"`, `"failed"`.

## Guards and scripted waves (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted guards are team `ENEMY` (or `NEUTRAL` for wardens), **not** controlled by the bot's Commander: they
hold their spot with normal auto-aggro and a 2x leash, like the 1v1 wardens.
| Group | Where | Units |
|---|---|---|
| G1 scout party | Brazier 1, `(-19, 19)` | 2 Shades + 1 Grave Hound |
| G2 jailers | Peddler cage, `(-24, -9)` | 3 Shades |
| G3 Westwatch | Brazier 2, around `(-42, -22)` | 1 Night Spire at `(-39, -25)` (750 HP, covers the brazier), 3 Shades, 2 Nightbolts |
| G4 Southgate wardens | Brazier 3, ring r 3 | 3 Ruin Wardens (neutral, `balance-1.md` numbers) |
| G5 crown wardens | Crown ring r 4 | 4 Ruin Wardens, **dormant** (no aggro, take no damage) until the seal breaks |
| Wave | Trigger | Units (spawned at the Gloom Hall spawn point; the Dusk Keep's if the hall is gone) | Order |
|---|---|---|---|
| W1 | 4:00 or Brazier 1 lit, whichever is **later** | 3 Shades + 1 Nightbolt | Attack-move to the Ember Hall |
| Raid | Every 150 s after W1 until the crown is claimed | 2 Grave Hounds | Attack-move to the nearest Fire worker |
| W2 | Brazier 2 lit | 4 Shades + 2 Nightbolts + 2 Grave Hounds | Attack-move to the Fire keep |
| W3 | 12:00, or the 3rd brazier lit, whichever is **earlier** | 5 Shades + 3 Nightbolts + 1 Shadow Knight | Attack-move to the crown `(0, 0)`, then to Vessa |
| Final | Crown claimed | Malrik (set to level 4: Lance r2, Siphon r1, Shroud r1) + 6 Shades + 4 Nightbolts at 0 s; 2 Shadow Knights + 2 Nightbolts at 45 s | Attack-move to Vessa's position, refreshed every 3 s |
If `sec_outpost` is done, every later wave loses 40 % of its units (rounded down) and W3 has no Knight.
The bot itself (`ai.md`, profile `mission_01`: the easy knobs, `min_attack_pop` 99 so it never launches its own
attacks, `worker_target_home` 4, no expansion, no towers beyond S1, keeps up to 8 soldiers at its rally) only
gathers, trains and defends its base. Malrik stays at his anchor until the final wave (defends his base).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Briefing screen (story above, the 3 primary objectives), then camera on Vessa; dialogue L1-L3; hint `Walk Vessa with W A S D. Light the brazier to the north-east.` |
| E2 | Vessa within 16 m of Brazier 1 | L4 (Malrik appears as a voice only) |
| E3 | Brazier 1 lit | L5; `obj_braziers` 1 / 3; hint `Train more soldiers at the Ember Hall (Z / X).`; W1 armed |
| E4 | G2 jailers dead + Vessa at the cage | Cage opens (box fades 1 s); L6; peddler shop works; Pell drops a **Vital Root** at his feet; `sec_peddler` done |
| E5 | Brazier 2 lit | L7-L8; Blaze Rider unlocked in the Ember Hall (slot B, after the tier-2 pair on C / V, 2026-09-30) + 2 free Blaze Riders spawn beside the brazier; W2 fires |
| E6 | Brazier 3 lit (third brazier, any order) | L9-L10; the seal shatters (flash at the crown, 1 s white ring r 12); G5 wakes up; `obj_crown` active |
| E7 | Crown claimed | L11-L12; `obj_hold` active with a 2:00 countdown; the Final wave spawns |
| E8 | Hold done (120 s, or Malrik killed during it) | L13-L14; remaining Shadow units walk back to the Dusk Keep; `Events.mission_ended(true)` after 4 s |
| E9 | Vessa dies | L15; `obj_vessa` failed; defeat after 3 s |
The braziers after the first can be lit in any order; the lines follow the count (2nd lit = E5 only for Westwatch;
if Southgate is lit 2nd, E5's unlock still happens on Westwatch).

## Dialogue (15 lines; speaker colours: Vessa `(1.0, 0.45, 0.1)`, Malrik `(0.7, 0.3, 1.0)`, Narrator `(0.9, 0.85, 0.7)`, Pell `(0.85, 0.75, 0.5)`; 5 s each)
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | Narrator | The Master is gone. His crown is not. |
| L2 | E1 | Vessa | An Ember Crown, in a place called Emberfall. I'm not saying it was left for me. I'm not NOT saying it. |
| L3 | E1 | Vessa | Three braziers, one seal. How hard can it be to light things? It's my whole personality. |
| L4 | E2 | Malrik | Little Vessa. You came a long way to lose something you never had. |
| L5 | E3 | Vessa | One lit. Malrik, you still dress like a funeral that got lost on the way. |
| L6 | E4 | Pell | Free at last! Buy something, would you? Shadow soldiers are terrible customers. They never pay, they just loom. |
| L7 | E5 | Narrator | The Westwatch fire rises. Riders who remember the old kingdom ride to meet it. |
| L8 | E5 | Malrik | Light all the candles you like. The dark just gets a better view. |
| L9 | E6 | Narrator | Three flames answer. The seal cracks, and the old wardens wake up grumpy. |
| L10 | E6 | Vessa | I'm here for the crown, not a lecture. Fine. Both. |
| L11 | E7 | Malrik | Put it down. That crown was never meant for someone who throws fire at her problems. |
| L12 | E7 | Vessa | Then it's in the right hands. I throw fire at ALL my problems. |
| L13 | E8 | Malrik | Keep it warm for me. The other three will come for it now. |
| L14 | E8 | Narrator | Far away, three apprentices feel the crown wake up, and begin to worry. |
| L15 | E9 | Vessa | Tell the others... I was winning. |

## Tiers (2026-09-30, JS: "a way to get better units, asap")
The keep can become a **Stronghold** here (`tiers.md` 6); the **Citadel** stays for later chapters. Same numbers as
the skirmish: X on the keep card, 200 crystals, 60 s, from **3:30**, needs a completed Hall (the Ember Hall is pre-built).
| Item | Value |
|---|---|
| Code | `Mission01._init`: `tiers_enabled = true`; `_ready`: `tier_system.max_tier = 2`, `bots_upgrade = false`; `casters_enabled = true` |
| Ember Hall | Z Flame Guard, X Ember Archer, **C Pyre Adept, V Cinder Arbalest** (greyed `Requires Stronghold` until then), **B Blaze Rider** after Westwatch (so no key moves when it unlocks) |
| Keep | Z Cinder Hand, **X Stronghold** (gold pulse when it can start), **B Kilnwarden** (tier 2), Set Rally r3c1; no Citadel button |
| "+" upgrades | from the Stronghold at the Ember Hall (before 2026-09-30 they were open from 0:00: no TierSystem meant "tier 3") |
| Hint | once, when the upgrade can start: message (12 s) `Your Keep can become a Stronghold: select the Keep and press X (200 crystals). It opens Pyre Adept, Cinder Arbalest (Ember Hall) · Kilnwarden (Keep).`; the tier chip under the top bar reads `Tier 1 Keep · Stronghold ready: X`. The skirmish Next hint is off in missions |
| Malrik | his keep never upgrades (the bot's rule 5 is off: `bots_upgrade = false`); scripted waves and guards unchanged |
Balance: the tier-2 pair costs 130 / 135 and 26 s each and the upgrade 200 + 60 s, so the first tier-2 units land
around 5:00-5:30, after W1 (4:00) and before G3 Westwatch (7:00-9:00, the skill check). They make Westwatch and the
Final wave a little easier; the fights keep their numbers (the 70 % rule was written for tier-1 armies and now has
headroom). Keep HP x1.2 at the Stronghold makes "Fire keep destroyed" rarer. Watch in the next playtest: if Westwatch
becomes trivial, raise G3 by one Nightbolt on normal / hard.

## Win / lose
| Event | Result |
|---|---|
| `obj_hold` done | **Victory** (`Events.mission_ended(true)`) |
| Vessa dies | **Defeat** (`gdd.md` rule, campaign flag `instant_loss_on_wizard_death = true`; the 1v1 respawn is off here) |
| Fire keep destroyed | **Defeat** |
| Malrik killed before the hold | Not a win: `Malrik has fallen back into the shadows`; he respawns at the Dusk Keep after 60 s |
| All Fire units dead, Vessa alive | Nothing; she can still finish |

## Reward carried to mission 2
- **Ember Crown** (`ember_crown`, artifact, `max_hp` +100, `max_mana` +50) added to the owned artifacts; equipped in
  artifact slot 1 by default on the mission 2 choice screen. In this mission it is worn from E7 and cannot drop.
- The 6 item slots as they are at victory; essence at **50 %, cap 1 500** (`items.md` campaign rules).
- `sec_outpost` done: **+300 essence** at victory (before the 50 % cut). `sec_peddler` done: the Vital Root it gave.
- Campaign flags saved: `m1_peddler_freed`, `m1_outpost_burned` (mission 2 may greet Pell again).
- Vessa's level is **not** carried (a new mission starts at level 1; artifacts and items are the progression).

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave / guard counts | x 0.6, no Knights | as written | x 1.4, Final wave Malrik level 5 |
| Start | 400 crystals, 6 soldiers + 2 extra Flame Guards | as written | 250 crystals, 4 Flame Guards + 2 Archers |
| Hold timer | 90 s | 120 s | 150 s |
| Expected time | 12-15 min | 15-20 min | 18-25 min |
- Fight sizing: the first fight (G1, 2 Shades + 1 Hound, ~280 crystals) against the start army (6 soldiers + Vessa,
  ~560 crystals) must end with **5+ survivors**: the old smoke layout, where the start army met a 14-unit Shadow
  block and often finished with only 4 units, is the thing this mission avoids. Every guarded fight is <= 70 % of
  the army the player can have at that time on normal.
- G3 Westwatch is the skill check (a tower plus ranged): the intended answer is Ember Step behind the spire,
  Fireball on the Nightbolts, and soldiers on the tower. Expect it around 7:00-9:00 with ~12 soldiers.
- The dormant crown wardens and the seal stop the "run Vessa to the crown" cheese of the old mission 1.
- Vessa at level 4-5 with ~1 500 essence of items (2 mids) should survive the Final wave only with her army or by
  kiting home (keep healing 1 % / s, keep shoots): the hold is a fighting retreat, not a stand-off.

## Done when (proposed step 7 ids; the lead adds them to `waves.md`)
- [ ] 7.S1 (systems): `missions/mission_01.tscn` builds Emberfall with the table above (seed 1101, clearings, nodes 1 500 / 2 000 / 1 500, pre-built hall, start state 300 / 150 / 11 of 20); braziers light after 3 s within 3 m (reset on leaving), minimap flame lines; peddler cage; dormant wardens take no damage until the seal breaks; guard groups G1-G5 at their spots with 2x leash.
- [ ] 7.S2 (systems-high): objectives and events E1-E9 in order through `Events.objective_changed` / `mission_ended`; waves W1 / Raid / W2 / W3 / Final with the triggers above and the -40 % rule after `sec_outpost`; Blaze Rider unlocked only after Westwatch; level cap 5; instant loss on Vessa's death; keep loss = defeat; difficulty multipliers.
- [ ] 7.S3 (systems): victory saves the Ember Crown in owned artifacts, the 6 slots, 50 % essence (cap 1 500, +300 first if `sec_outpost`), flags `m1_peddler_freed` / `m1_outpost_burned`; a headless test loads mission 2's start and finds them.
- [ ] 7.U1 (ui): briefing screen (3 paragraphs + primary objectives), objectives panel (primary / secondary, counters, countdown for `obj_hold`), dialogue box (speaker name in its colour, 5 s per line, queue); layout from ui-designer.
- [ ] 7.A1 (ai): profile `mission_01` (easy knobs, `min_attack_pop` 99, workers 4, no expansion, max 8 soldiers, never rebuilds the Gloom Hall); scripted units never join the Commander; Malrik stays home until the Final wave, then follows it.
- [ ] 7.D1 (designer): read the 15 lines in game once, trim any line longer than 2 lines of the dialogue box.
- [ ] Lead: a scripted headless run on normal (light 3 braziers, claim, hold) ends `victory=true` in 15-20 game-minutes; the G1 fight leaves >= 5 of the 6 start soldiers alive in 5 / 5 runs.

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Blaze Rider.
- **Why here:** unlocked at Brazier 2; Westwatch and W2 put Nightbolts behind Shades on open ground (riders beat archers and casters); Lab 68 / 72 / 81.
- **Moment:** the 2 free riders spawn at Westwatch; W2 hint "Blaze Riders: go around the Shades and ride down the Nightbolts." (+ "Not the tower." near the Night Spire).
- **Intro card:** `Blaze Rider. Fast and fierce: ride past the shields and catch the archers.`

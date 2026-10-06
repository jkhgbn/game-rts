# Campaign mission 4: "The Hollow Throne" (Vessa vs Malrik vs the Keystone Colossus)

Task 19.D2 (part 4 of 4). Built in step 19 (ids 19.C5a-19.C5c here, plus the shared 19.C6, 19.C11, 19.A1, 19.U5 and art
19.V1-V4 / V25 of `story-episode-1.md` 9). The **finale of Episode 1**; target **22-28 min** on normal, its own cutscenes
included. Source of truth for the story and every binding number: `story-episode-1.md` ("ep1") 5.4, 6 and 7.2; this spec
places them on the map and fills the gaps. Uses `skirmish-1v1.md`, `map-fill.md` (river Hollowmere, crossings), `levels.md`,
`items.md`, `champions.md` 11 (companion), `caster-units.md` (Kilnwarden), `tiers.md` 6, `cinematics.md` 11 and the
format of `mission-01.md`. New scene `missions/mission_04.tscn` + `scripts/campaign/mission_04.gd` (`Mission04 extends
MissionBase`, mission id `m04`, in `CampaignState.MISSION_ORDER` after `m03`). Metres, seconds, `m:ss` since the navmesh
was ready (`mission_time()`, held cinematic time excluded); positions `(x, z)`, `y = 0`, `+z` = south.

## Story setup (briefing text, 3 short paragraphs)
1. The parley failed. Ice and Nature walked away, and Malrik named the place himself: Crown Hollow, at dawn, where the
   Master once sat and where this war began over a crown.
2. Vessa carries all three relics now: the Ember Crown, the Stillwater Orb and the Master's Signet. They have stopped
   humming. They are pulling, toward the ruined throne on Crown Isle, and the voice inside them sounds very pleased.
3. Ysolde called the relics a lock. Somewhere under the isle, something has been counting every soldier who falls.
   Vessa means to end the war today. She is about to find out what the war has been feeding.

## Map: "Crown Hollow at war" (the skirmish map, 120 x 120, point-symmetric, `MAP_SEED` = the skirmish seed)
The 1v1 Crown Hollow with `river_enabled = true` (Hollowmere, the 8 crossings of `map-fill.md` 2.2). Off: capture points,
neutral camps (so **no ford nests**: Reed and Willow Fords are open from 0:00), epic beasts, trade, research, cavalry,
titans, wells, shrines, critters stay (cosmetic). Only the **west tavern** opens. Light: storm dusk (low sun
`(1.0, 0.72, 0.45)`, violet-grey sky; amber moat glow after the Rise; storm clouds after `m4_storm`, 19.V25).
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / Fire keep | `(-36, 36)` / `(-43, 43)` | 18 | **Stronghold** at 0:00 (section "Tiers") |
| Ember Hall / Ember Spire | `(-27, 45)` / `(-37, 29)` (S1) | - | Pre-built, complete |
| Hearths | `(-50, 46)` (V1) / `(-50, 52)` (V2) | - | Pre-built, complete (cap 40) |
| Nodes `m4_fire_a` / `m4_fire_b` | `(-46, 34)` / `(-34, 46)` | - | **1 500** each |
| Node `m4_fire_mid` (natural) | `(-16, 6)` | 7 | **2 000**; hall spot X1 `(-23, 9)` |
| Node `m4_fire_rich` | `(-40, -40)` | 7 | **2 000** (the skirmish rich node) |
| West tavern "The Lantern at the Ford" | `(-15, -15)` | - | `tavern_enabled = true`, hiring open from 0:00; the companion walks in beside Vessa |
| Pell (branch) | `(-22, -22)` | 5 | The west peddler spot; Pell if `m1_peddler_freed`, else empty |
| Lost Caches | `(-30, 0)`, `(-6, 27)`, `(30, 0)`, `(6, -27)` | 3 | `items.md` loot, appear at 2:00, reopen 180 s |
| **The Throne stone** | `(0, 0)` on Crown Isle | 12 | Replaces the crown pedestal; the `obj_isle` channel spot. Pillar ring r 8 stays until the Rise |
| **Keystone Pylon P1** | `(-12.75, 21.25)` | 3 | West bank, along the lane 24 m from the isle centre (8 m beyond the West Crown Bridge's outer end), **6.0 m** south-east of the lane centre line |
| **Keystone Pylon P2** | `(-15, -34)` | 3 | West bank beside Reed Ford: **6.5 m** from the ford centre, 4 m from the water edge, 13.7 m from the ring road |
| **Keystone Pylon P3 / P4** | `(12.75, -21.25)` / `(15, 34)` | 3 | Point mirrors of P1 / P2 (east bank) |
| Dusk Keep (Malrik) | `(43, -43)` | 18 | 1 500 HP, never upgrades |
| Gloom Hall / Night Spire / Hovels | `(27, -45)` / `(37, -29)` / `(50, -46)`, `(50, -52)` | - | Bot slots H1 / S1 / V1 / V2 (`ai.md`) |
| Shadow nodes | `(46, -34)` / `(34, -46)` 1 500 each; natural `(16, -6)` 2 000; rich `(40, 40)` 2 000 | - | Mirrors |
| Shadow rally | `(30, -30)` | - | Where the bot keeps its army |
**Pylon clearance** (ep1 5.4 rule, checked here): >= 2 m between a pylon's footprint (r 1.0) and the lane edge (half-width
2.6): P1 gap 6.0 - 2.6 - 1.0 = **2.4 m**; >= 6 m from every crossing centre: P1 12.3 m from the West Crown Bridge, P2
**6.5 m** from Reed Ford (ep1's `(-13, -34)` was 4.5 m: moved 2 m west), both > 8 m from the caches, nodes and tavern.
Test 19.C5a asserts all four against `RiverSystem.crossings` and the lane polyline.

**Keystone Pylon** (19.C6 gameplay, 19.V2 look): hidden underground until the Rise (no collision, no navmesh effect), then
a 5 m cracked obelisk with an amber core, **1 400 HP, armor 20**, team `NEUTRAL`, group `"scripted"` + `"pylons"`, not in
`"buildings"`, `counts_for_defeat` false, navigation geometry (rebake on rise and on break, the building path), always
visible through the fog after the Rise, golden tether beam to the Colossus's chest while it stands. Spawns **2 Ruin
Wardens every 35 s** within 4 m (max 6 alive per pylon); those Wardens **guard** it (aggro 10 m, leash 18 m). Credit for
the break = the team of the killing blow (signal `pylon_destroyed(pylon, by_team)`).

## Mechanic: the Hollow meter (phase 0 only; ep1 5.4.2)
`hollow` 0-100 %, shown from 0:00 as an objectives-panel line `The Hollow stirs: 37 %` (19.U5: orange at 50 %, red at 75 %).
| Source | Amount |
|---|---|
| A unit in group `"units"` dies (soldiers, workers, casters, champions, any team) | **+1 %** |
| Malrik dies | **+8 %** (his +1 does not also count) |
| Time | **+0.1 % / s** |
| Not counted | Ruin Wardens, Saplings, the isle guard when it is buried at the Rise, deaths while a cinematic holds the world |
Messages (4 s) at 25 % `The ground under Crown Hollow is warm.`, 50 % L5, 75 % L6. The moat glow brightens in 4 stages
(19.V4). **The Rise** fires at 100 % or the moment `obj_isle` completes, whichever first; then the meter is hidden.
Expected normal: ~55 % from time alone by 9:10, plus ~35-45 deaths from the isle fight, the bot's attacks and raids:
**Rise at 8:00-11:00**. Why: every soldier the player throws away brings the boss closer; a careful player chooses when.

## Mechanic: the Master's seat (`obj_isle`)
`MissionBrazier` rule on the Throne stone: **Vessa within 3 m for 3 s** (progress ring; leaving resets). The ring does not
fill (turns red) while any `ENEMY` unit stands on the isle (r < 11). The isle guard (6 Shades + 3 Nightbolts, scripted,
2x leash around `(0, 0)`) holds it until **5:00**, then joins the bot's Commander. A hint appears the first time Vessa is
within 16 m of the isle. Taking the seat is the way to **choose** the moment of the Rise (`sec_seat`).

## Start state (from the campaign save)
Order in `_on_navigation_ready`: spawn Vessa -> `CampaignState.open(...).apply_to_start(self)` -> companion -> flag branches.
| Item | Value |
|---|---|
| Vessa | **Level 4 with 3 unspent spell points** (Fireball r1 known), **cap 8**; full HP / mana (ep1 4.1) |
| Artifacts | From the save: 3 owned; default equip **Signet slot 1, Crown slot 2** (the orb owned, choosable on the choice screen) |
| Item slots / essence | The 6 slots as saved; essence **150** + carried (already 50 %, cap 1 500); +1 / s |
| Companion | The M3 companion (if chosen) beside Vessa at `PLAYER_START + (2, 2)`, roster slot 1, level 1, its items and purse |
| Crystals | **400** (easy 500, hard 300) |
| Buildings | Keep (Stronghold), Ember Hall, Ember Spire, 2 Hearths, all complete |
| Units | 6 Cinder Hands gathering (3 on `m4_fire_a`, 3 on `m4_fire_b`); **8 Flame Guards, 5 Ember Archers, 2 Blaze Riders, 3 Ash Hurlers** at `(-30, 30)` |
| Population | **26 / 40** (computed from `UnitType.pop`, never hard-coded; 26 assumes Ash Hurler pop 1) |
| Shadow | Dusk Keep, Gloom Hall, Night Spire, 2 Hovels; **6 Gloom Thralls** gathering; **8 Shades + 4 Nightbolts + 2 Shadow Knights** at the rally; **Malrik L5** (Lance r2, Siphon r2, Shroud r1) at the rally; the **isle guard** on Crown Isle |
| No save (menu debug, tests) | Crown, orb, Signet owned; Signet + Crown equipped; 6 empty slots; essence 150 + **600**; no companion; flags false |
| Flags | `m1_peddler_freed`: Pell at `(-22, -22)` (a normal `RuinPeddler`, open at 0:00; L26 the first time Vessa is within 10 m) |
No allied wizard (the 1v1 rule). `helpers_enabled = false`: Old Vey is the story unit `torren_vey` (19.C11), not the helper.

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Hearth, Ember Hall, Ember Spire (walls if built in the skirmish) | Bazaar, Forge / Sanctum (research), stables |
| Units | Cinder Hand, Flame Guard, Ember Archer, Blaze Rider, Ash Hurler; Pyre Adept, Cinder Arbalest (Hall, tier 2); **Kilnwarden** (keep B) | Citadel units, Ember Boar, titans, any Episode 2 unit |
| Keep | Already a Stronghold; no tier button (`max_tier = 2`) | Citadel (opens in e2m1, outline D7) |
| Spells | Fireball, Ember Step, Kindle; cap L8 | - |
| Champions | Tavern hires (the next hire costs the 2nd price), bounty flags R (Explore / Hunt / Guard) | - |
| Items | Base shop (keep, Ember Hall); Pell's stock if he is here; caches | Top items stay mostly out of reach |

## Tiers (`tiers.md` 6; outline D7)
`Mission04._init`: `tiers_enabled = true`, `casters_enabled = true`; `_ready`: `tier_system.max_tier = 2`,
`bots_upgrade = false`, and the Fire keep **starts at tier 2** (systems adds `TierSystem.set_start_tier(team, tier)` if it
does not exist: no upgrade timer, the HP x 1.2 applied, the "+" upgrades open). The Ember Hall copy is mission 2's (Z Flame
Guard, X Ember Archer, C Blaze Rider, V Ash Hurler, B Pyre Adept, N Cinder Arbalest); keep: Z Cinder Hand, B Kilnwarden.
Why pre-upgraded: the finale teaches the boss, not the tier ladder (taught in M1-M3), and 60 s of upgrade with nothing to
spend on is dead time. The Kilnwarden's **Slag Rain on the Colossus** (titan: 5 s, armor 25 -> 5, damage taken x 1.10) is
the intended expert tool for exposures; the phase-3 maths below does not count on it.

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_isle` | Primary (phase 0) | `Take the Master's seat on Crown Isle` | The seat channel completes, **or** the Rise happens by the meter (then it is marked done without the bonus) |
| `obj_pylons` | Primary (after the Rise) | `Break the Keystone Pylons (0 / 4)` | All 4 broken (any team) |
| `obj_colossus` | Primary (phase 2) | `Stop the Keystone Colossus` (boss bar with marks 100 / 70 / 40) | The darkest hour fires |
| `obj_key` | Primary (phase 3) | `Turn the key: Vessa by the Colossus's heart, with Old Vey beside her` | Colossus HP 0 |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `obj_keep` | Primary, always shown | `The Fire keep must stand` | Fails = defeat |
| `sec_seat` | Secondary (phase 0) | `Take the seat before the Hollow wakes on its own` | `obj_isle` by the channel before 100 %; **failed** if the meter gets there first |
| `sec_hall` | Secondary | `Burn Malrik's Gloom Hall` | The Gloom Hall at `(27, -45)` destroyed (the bot never rebuilds it here) |
The briefing shows `obj_isle`, `obj_vessa`, `obj_keep` and the line `Every fallen soldier feeds the Hollow.`; the later
primaries appear when their phase starts (ep1 5.4.3).

## Phases at a glance (normal; expected times include the cutscenes)
| Phase | From - to | Expected | What the player does |
|---|---|---|---|
| 0 "The War" | 0:00 (after `m4_war` 0:30) - the Rise | 8:00-11:00 | Normal battle vs Malrik; take the isle when ready |
| The Rise | `m4_rise` VIDEO | 0:45 | - |
| 1 "The Ward" | Rise - 4th pylon | 4:30-6:00 | Break P1 / P2 at home, cross for P3 / P4 or let Malrik's strike soften them |
| 2 "The Hollow Walks" | 4th pylon - darkest hour | 2:00-3:00 | Fighting retreat along the lane; Cracked Leg window |
| Darkest hour | L14 + `m4_storm` VIDEO | 1:50 | - |
| 3 "The Spark and the Storm" | Rescue - HP 0 | 2:00-3:00 | ~3 turns of the key beside Old Vey |
| The Fall | `m4_fall` | 0:06 | - |
| **Total** | | **~22-26 min** (a fast seat-taker can finish ~20; the cap is ~28) | |
`ep1_ending` (1:30) and the credits (1:30) play after the mission and are not counted.

## Guards, waves and the bot (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units are group `"scripted"`, never controlled by the Commander unless stated. Ruin Wardens are team `NEUTRAL`
(enemy of both: a true 3-way fight), `neutral_leash` false unless they guard a pylon, and `balance-1.md` numbers (300 HP,
16 damage).
| Group / wave | Trigger | Units | Order |
|---|---|---|---|
| Isle guard | 0:00 - 5:00 | 6 Shades + 3 Nightbolts (ENEMY) on Crown Isle | Hold the isle (2x leash); at 5:00 join the Commander (no longer scripted). Buried at the Rise if still on the isle |
| The bot | From 0:00 | Profile `mission_04` (19.A1): Shadow normal knobs, `min_attack_pop` **14** (first attack ~6:00), workers 6, no expansion past X1, max 20 soldiers at the rally, never rebuilds the Gloom Hall | Gathers, trains, attacks Vessa's base in phase 0 |
| Pylon Wardens | The Rise, every 35 s per standing pylon | 2 Ruin Wardens (max 6 alive per pylon) | Guard their pylon (aggro 10, leash 18) |
| Shadow pylon strike | Phase 1, 20 s in (with L9) | The bot's army at its rally + **4 Shades + 2 Nightbolts** (scripted) at the Gloom Hall spawn | Attack-move to P3, then P4 (scripted override of the Commander's army orders until both fall or phase 2 starts) |
| Raids | Phase 1, every **180 s** | 4 Grave Hounds | Attack-move to the nearest Fire worker |
| Ward breaks | Phase 2 start | All living pylon Wardens | Attack-move to Vessa, refreshed every 3 s |
| Shadow push | Phase 2 start | 6 Shades + 2 Shadow Knights from the north map edge `(-20, -58)` | Attack-move to the Fire keep |
| Rubble Call (phase 2) | Every 30 s | 3 Ruin Wardens within 6 m of the Colossus | Attack-move to Vessa |
| Rubble Call (phase 3) | Every 20 s | 4 Ruin Wardens within 6 m, never inside Vey's Charged Ground (r 10) | Attack-move to Vessa |
| Shadow pull-back | Phase 3 start | Every Shadow unit | Walk to the rally; the bot defends only (`min_attack_pop` 99) until the end |
If `sec_hall` is done: raids are 2 Grave Hounds and the Shadow push has 1 Knight. Malrik (bot-controlled, Commander casts
for him) follows his army in phase 0 and in the pylon strike; dead Malrik respawns at the Dusk Keep after **60 s**.

## The boss: Keystone Colossus (19.C6; ep1 6 is binding, summary here)
Team `NEUTRAL`, groups `"units"` + `"boss"`, titan tags (CC half, taunt / knockback immune), **10 000 HP**, armor 25,
Crush 60 + 50 % splash r 2 every 2.4 s (x 2 vs buildings), speed 1.4 (phase 2 only), radius 3, height 12, sight 20, no kill
XP. Spawned at the Rise at `(0, 0)` (hidden before; `set_phase(1)`).
| Phase | Rules active |
|---|---|
| 1 | **Keystone Ward** (invulnerable while a pylon stands; tethers), **Keystone Hurl** every 9 s at the biggest PLAYER or ENEMY clump within 30 m (Vessa's clump wins ties), 1.6 s telegraph r 3.5, 70 damage. Stays on the isle |
| 2 | Walks to the Fire keep: West Crown Bridge `(-9.02, 9.02)`, then the lane (61 m), crushing what blocks it (Crush targets anything within 3 m of its path; Vessa first). Hurl every 12 s, **Quake Stomp** (3+ enemies within 7 m, every 11 s, 1.2 s ring r 7, 55 + `dazed` 1.0 s / heroes 0.5 s), **Relic Pull** (every 20 s, Vessa within 22 m; Ember Step breaks it), Rubble Call 30 s, **Cracked Leg** at 70 % (8 s stagger, x 1.25 damage taken) |
| 3 | Kneels where it stands: **Stone Skin** (x 0.1 damage unless Exposed), Hurl every 10 s, **Hollow Pulse** every 7 s (40 r 5; resets Turn the Key unless Old Vey is within 8 m of Vessa), Rubble Call 20 s. **Turn the Key**: Vessa within 4 m for 3 s -> **Exposed 10 s**, then 6 s before the next turn |
Phase-3 maths (normal): 4 000 HP left; ~150 army DPS x 0.8 (armor 25) = ~1 200 per exposure + Vey's 300 bolt when Stormcall
is ready (45 s) = **3 turns**, ~19 s each plus walking and resets: 2:00-3:00.

## Old Vey (19.C11 + 19.A2; ep1 5.4.1 binding)
Arrives in `m4_storm`, 3 m from Vessa. HP 1 600, armor 25, speed 5.0, sight 14; Thunder-edged Blade 40 (3rd strike chains
to 2 for 25); Lightning Lunge 12 s (60 / 30 + `dazed` 0.5 s); Chain Lightning 8 s (45-38-32-27-23, x 2 on Wardens);
**Charged Ground** r 10 (Wardens 20 / s and cannot rise inside; own units `attack_cooldown_pct` -0.15, `aura:charged`);
**Ground the Pulse** (within 8 m of Vessa); **Stormcall** 45 s (8 bolts x 60, x 2 on Wardens; 300 on an Exposed Colossus).
Not commandable (stays 3-6 m from Vessa; lunges at her threats). At 1 HP: kneels 10 s, L23 + message `Old Vey is down! The
storm will return.`, stands at 50 %. Never causes a defeat. Speaker id **`vey`** (`cast.json`; `torren` is its alias).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Briefing (3 paragraphs + the 3 phase-0 objectives + the Hollow line) -> `m4_war` (ENGINE HOLD 0:30, L1-L4) -> RTS camera on Vessa; hint `Every death feeds the Hollow. Take the Master's seat on Crown Isle when YOU are ready.` (10 s); Hollow meter shown |
| E2 | Vessa within 10 m of Pell (first time, flag branch) | L26 |
| E3 | Hollow 25 / 50 / 75 % | Message / L5 / L6 |
| E4 | Vessa within 16 m of `(0, 0)` (first time) | Hint `Clear the isle of Shadow, then stand on the Throne stone for 3 s.` (8 s) |
| E5 | 5:00 | Isle guard joins the bot; message `Malrik's isle guard falls back to his army.` (4 s) |
| E6 | **The Rise** (seat taken or Hollow 100 %) | `obj_isle` done; `sec_seat` done or failed; world held; **V3 `m4_rise`** (VIDEO, or its fallback card). End state: isle guard removed (no Hollow, no XP); every other non-Vessa unit on the isle moved to the nearest bank point; pillar ring and Throne stone removed, isle pit set (19.V4); Vessa teleported to `(-11, 11)` (West Crown Bridge, player side); pylons risen (rebake); Colossus at `(0, 0)` phase 1; Hollow meter hidden. Then L7-L8; `obj_pylons` 0 / 4 active; hint `Break the four Keystone Pylons. The Colossus cannot be hurt while one stands.` (8 s) |
| E7 | Phase 1 + 20 s | L9; Shadow pylon strike |
| E8 | A pylon breaks | Tether snaps (0.5 s), `obj_pylons` +1; 2nd broken: L10; the first one broken by Shadow: L24 and flag `m4_malrik_pylons` true |
| E9 | 4th pylon breaks | **Phase 2**: ward shatters (the `_seal_flash`, amber `(1.0, 0.75, 0.3)`, r 12); L11; `obj_pylons` done, `obj_colossus` active, boss bar; pylon Wardens attack-move; Shadow push; raids stop |
| E10 | Colossus HP 70 % (phase 2) | Cracked Leg: message `The Colossus staggers!` (4 s); L12 |
| E11 | Fire keep under 30 % (once, any phase) | L13 |
| E12 | **The darkest hour**: phase 2 and (Colossus HP <= 40 % **or** Fire keep HP <= 50 %), first only | L14 (3 s), then world held and **V4 `m4_storm`** (VIDEO or card). End state (ep1 5.4.3): Colossus kneels where it stands, HP = `min(current, 40 %)`, `set_phase(3)`; every Ruin Warden within 25 m of Vessa destroyed (no XP, no essence); Old Vey spawned 3 m from Vessa; Vessa's mana raised to at least 50 %; storm-cloud layer on. Then L15, L25; `obj_colossus` done, `obj_key` active; Shadow pull-back; hint `Stand within 4 m of the Colossus for 3 s with Vessa. Keep Old Vey close: the Hollow Pulse can't break the key while he grounds it.` (10 s) |
| E13 | 1st / 2nd / 3rd Exposed | L16 / L17-L18 / L19 (a 4th or later exposure: no line) |
| E14 | Old Vey drops to 1 HP | Kneel 10 s; L23; message |
| E15 | Colossus HP 0 | Commander paused, world held; **`m4_fall`** (ENGINE PAUSE 0:06, L21); `Events.mission_ended(true)`; save (section "Rewards"); StoryFlow plays **V5 `ep1_ending`** then **`ep1_credits`** |
| E16 | Vessa dies | L20; `obj_vessa` failed; defeat after 3 s |
| E17 | Fire keep destroyed | `obj_keep` failed; defeat after 3 s (no line) |
| E18 | Malrik dies | Message `Malrik has fallen back into the shadows` (4 s); Hollow +8 % in phase 0; respawn at the Dusk Keep after 60 s |
Order rules: E12 can only fire in phase 2 (a keep at 50 % in phase 0 or 1 is just a keep in trouble). Phase 3 cannot start
any other way, so Old Vey is always present for the finale.

## Dialogue (25 lines, 22 from ep1 5.4 unchanged + 3 new; 5 s each unless listed)
Speaker ids and colours (`DialogueBox.SPEAKER_COLORS`, `cast.json`): `vessa` `(1.0, 0.45, 0.1)`, `malrik` `(0.7, 0.3, 1.0)`,
`narrator` `(0.9, 0.85, 0.7)`, `whisper` (shown `???`) / `obren` (shown `Obren`; same voice) `(1.0, 0.80, 0.25)`, `vey`
`(0.95, 0.95, 0.55)`, `pell` `(0.85, 0.75, 0.5)`. From E1 on the Whisper portrait is Obren's stone face (ep1 7.3).
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 `m4_war` | `narrator` | Crown Hollow. Where the Master once sat, two armies wait for the sun. |
| L2 | E1 `m4_war` | `malrik` | Three relics, little ember. Hand them over and I'll let you keep the hat. |
| L3 | E1 `m4_war` | `vessa` | Come and take them, Bishop. You owe me for Emberfall. And for Vey. |
| L4 | E1 `m4_war` | `whisper` | Yes. Come, both of you. Fight on my roof. |
| L5 | E3 50 % | `obren` | Yes. Fight. Every fallen soldier is a step on my stair. |
| L6 | E3 75 % | `vessa` | The ground is breathing. That can't be good. |
| L7 | E6 | `obren` | A hundred years in the dark. I had time to practise my entrance. |
| L8 | E6 | `vessa` | I had ten minutes to practise running. Those pillars feed it. Break them all! |
| L9 | E7 | `malrik` | A giant made of rubble, in MY war? Shades, kill the pillars. Then kill Vessa. |
| L10 | E8 2nd | `vessa` | Two down. Keep hitting the glowing parts. It's always the glowing parts. |
| L11 | E9 | `obren` | Enough. I will walk to your little fire and put it out myself. |
| L12 | E10 | `obren` | This body... cracks... No matter. Stone is patient. |
| L13 | E11 | `vessa` | Not the keep! I JUST had it redecorated! (4 s) |
| L14 | E12 | `vessa` | Everyone, back to the keep! BACK! (3 s) |
| L15 | E12 after V4 | `vey` | Stay close, girl. Whatever it throws at you, I'll ground it. |
| L16 | E13 1st | `vessa` | Crown, orb, signet. Let's see what you do together. |
| L17 | E13 2nd | `obren` | His storm? Impossible! That light should have faded a hundred years ago! |
| L18 | E13 2nd | `vessa` | Nobody stays faded around here. Ask Vey. |
| L19 | E13 3rd | `vey` | The spark was yours, Vessa. NOW the storm! |
| L20 | E16 | `vessa` | Somebody... finish my war... |
| L21 | E15 `m4_fall` | `obren` | The Hollow... remembers... (3 s) |
| L23 | E14 | `vey` | Just resting my knees. Keep turning that key! (4 s) |
| **L24** (new) | E8, first pylon broken by Shadow | `malrik` | One pillar down. You're welcome, little ember. Don't get used to it. |
| **L25** (new) | E12, after L15 | `malrik` | An old man and a thunderstorm. Shades, fall back. I'll collect whatever is left. |
| **L26** (new) | E2, `m1_peddler_freed` | `pell` | Last stall before the end of the world! Everything must go. Including me, quickly. |
L22 is not used. L25 is the in-play setup for the ending's dark beat (Malrik walking off with the heart-stone). The
companion speaks only through its `champions.md` 4.5 barks.

## Cinematic hooks (content in ep1 7.2; tech in `cinematics.md`; all through `MissionBase.play_cutscene(id)`)
| Id | Kind / mode | Trigger | Actors registered (`register_actor`) | End state applied by the mission (also on skip) | Fallback |
|---|---|---|---|---|---|
| `m4_war` | ENGINE, HOLD 0:30 | E1, after the briefing | `vessa`, `malrik` (at his rally), `companion` (optional) | HOLD released, RTS camera on Vessa, mission clock starts at 0:00 | - |
| `m4_rise` | VIDEO 0:45 | E6 | - | E6 end state | ep1 7.4 card |
| `m4_storm` | VIDEO 1:45 | E12 after L14 | - | E12 end state | ep1 7.4 card |
| `m4_fall` | ENGINE, PAUSE 0:06 | E15 | `colossus` (the dead body, `play_death` held at its first frame), `heart_stone` | Mission won and saved | - |
| `ep1_ending` | VIDEO 1:30 | After `m4_fall`, outside the mission (StoryFlow) | - | Story flow continues to `ep1_credits` | ep1 7.4 card |
| `ep1_credits` | ENGINE stage 1:30 | After `ep1_ending` | - | Story menu, Episode 1 complete, Episode 2 card shows its teaser | - |
**The ending of Episode 1 (what the mission hands to the films).** When the Colossus reaches 0 HP, `Mission04` spawns the
actor **`heart_stone`**: a fist-sized amber stone (sphere r 0.25 with the Heart-Keystone material, emission 2.5, a slow
1 Hz pulse, 0 lights; 19.V3) at the chest position projected to the ground. `m4_fall` closes on it (cracks race across
the heart, fade to white). `ep1_ending` then tells the rest on its own set (19.V22): Vessa's fire and Vey's lightning
shatter the heart, **Obren's body falls**, and in the grey dawn **Malrik picks up the still-pulsing heart-stone** (the
Keystone Shard) and melts into mist with it while the Shadow army withdraws; Torvald and Ysolde watch and turn away; Vey
tells Vessa the Master is alive below, and the three relics turn white-gold and point down. The mission sets the flag
`ep1_shard_to_malrik` (always true) so Episode 3 gives `keystone_shard` to Malrik's save track (outline D8, C7).
Order for a crash-safe ending: `mission_ended(true)` -> save rewards with `resume = &"ep1_ending"` -> V5 -> credits ->
`resume` cleared. Story mode shows no victory screen before the films; after the credits a short `Episode 1 complete`
panel (mission time, units lost, secondaries) leads to the Story menu. A replay from the Missions list ends on the normal
victory screen after `m4_fall` and skips V5 / credits (they stay in the Theatre).

## Win / lose
| Event | Result |
|---|---|
| Colossus destroyed (phase 3) | **Victory** -> `m4_fall` -> `ep1_ending` -> credits |
| Vessa dies | **Defeat** (instant; `instant_loss_on_wizard_death = true`) |
| Fire keep destroyed | **Defeat** (the darkest hour at 50 % keep HP gives one rescue first in phase 2) |
| Old Vey at 1 HP | Kneels 10 s, never dies, never a defeat |
| Malrik killed | Not a win; respawn after 60 s; +8 % Hollow in phase 0 |
| Malrik's base destroyed | Allowed, not required: the bot is beaten, scripted Shadow waves stop; the boss phases continue |
| All Fire units dead, Vessa and the keep alive | Nothing; she can still finish (Vey arrives regardless) |

## Rewards / Episode 2 carry-over
- No new artifact: the 3 relics stay owned (Episode 2 shows them white-gold). The 6 slots, essence at 50 % (cap 1 500)
  after the bonuses, the companion (`champions.md` 11 rules) saved on **Vessa's track** for Episode 2.
- `CampaignState.MISSION_REWARDS[&"m04"] = {"flags": {"m4_seat_taken": "sec_seat", "m4_hall_burned": "sec_hall"},
  "bonus_essence": {"sec_seat": 300, "sec_hall": 300}, "set_flags": {"ep1_complete": true, "ep1_vey_returned": true,
  "ep1_shard_to_malrik": true}, "next": &"e2m1"}`; `m4_malrik_pylons` is written by `Mission04` at E8 (a mission-computed
  flag). If `set_flags` does not exist in `CampaignState`, 19.C5c adds it (constant flags set on victory).
- Level not carried (the rule since mission 2).

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave / Warden counts | x 0.6 | as written | x 1.4 |
| Start crystals | 500 | 400 | 300 |
| The Rise by the meter at | Hollow **120 %** | 100 % | 100 % |
| Malrik | L4 | L5 | **L6** (+ Shroud r2) |
| Colossus HP / Hurl damage | **7 500** / 55 | 10 000 / 70 | **12 500** / 85 |
| Pylon HP | 1 100 | 1 400 | **1 700** |
| Vey's Stormcall | 45 s | 45 s | **60 s** |
| Expected time | 18-22 min | 22-28 min | 26-34 min |
- Fight sizing (every guarded fight <= 70 % of the army the player can have then, normal): isle guard (6 Shades + 3
  Nightbolts, ~900 crystals) vs the start army (~2 300 + Vessa L4 + companion); the bot's first attack at ~6:00 (~14-18 pop,
  ~1 500) vs ~30 pop; one pylon (1 400 HP, up to 6 Wardens = 1 800 HP, 96 DPS) vs ~25 soldiers at ~11:00; the Shadow push
  (6 Shades + 2 Knights) arrives while the Colossus walks: phase 2 is **meant** to exceed 70 % and feel lost (ep1 4.1).
- Phase 2 watch item: with a full army on the boss, 100 -> 40 % can fall in under 1:30. If the playtest shows that, 19.D3
  raises Rubble Call to 4 Wardens on normal before touching the boss's HP (keeps ep1 6.1 intact).
- The intended phase-1 answer: break P1 and P2 at home with the army (the Colossus's Hurl reaches 30 m: P1 at 24 m is in
  range, P2 at 37 m is not), then cross at the West Crown Bridge or Reed Ford for whichever east pylon Malrik has not
  broken. Waiting for Malrik is slower but legal.
- The seat is a real choice: taking it at ~6:00 skips 3-5 minutes of feeding, but the Rise then lands on an army still
  fighting Malrik's first attack.
- Vessa L4-L7 with ~2 000 essence of items survives phase 3 only beside Vey (Hollow Pulse 40 every 7 s plus Hurls); Ember
  Step out of Hurl circles is the skill check.

## Code reuse (recommendation to the lead)
`MissionBase` (M9.S1 / 19.C2) has objectives, `_say`, `_after`, `_spawn_group` / `_scaled` / `_mark_scripted`,
`_set_dormant`, `_order_wave` / `_refresh_waves`, `_raise_wizard`, the level cap, `_seal_flash`, `hold_world`,
`play_cutscene`. `MissionBrazier` serves the seat (with an `is_blocked()` hook for the enemy-on-isle rule) and Turn the Key
(4 m ring, 19.C6 owns it on the boss). `RuinPeddler` for Pell, `LostCache` for the caches, the `Skirmish` kingdom table for
Malrik's respawn text, `RiverSystem` for the bank / crossing queries. New in `Mission04`: the Hollow meter, the Rise
sequence, the pylon strike override, the phase driver listening to `phase_changed` / `exposed_changed` / `pylon_destroyed`.

## Done when (step 19 ids; the lead adds them to `waves.md`)
- [ ] 19.C5a (systems): `missions/mission_04.tscn` builds Crown Hollow at war (skirmish seed, river on, camps / points /
  beasts / trade / research / cavalry / titans off, west tavern only, storm-dusk preset); pre-built Fire base at tier 2
  (Stronghold, Hall, Spire, 2 Hearths); nodes 1 500 / 1 500 / 2 000 / 2 000 per side; start state (L4 + 3 points, cap 8,
  400 / 150 + carried, 26 / 40, companion, no-save fallback, Pell branch); isle guard; hidden pylons at the 4 positions
  with the clearance test (>= 2 m from the lane edge, >= 6 m from every crossing centre); the seat channel with the
  enemy-on-isle block.
- [ ] 19.C5b (systems-high): the Hollow meter (sources, exclusions, messages, the easy 120 % rule); E1-E18 in order; the
  Rise end state (bury, push off the isle, teleport, rebake, Colossus phase 1); the pylon strike override, raids, push,
  pull-back; the darkest-hour trigger (40 % boss or 50 % keep, phase 2 only) and its end state; the 25 lines with speakers;
  win / lose table; difficulty table. Every cutscene end state is identical on skip (`test_19_c9` part for m04).
- [ ] 19.C5c (systems): victory flow (save with `resume = ep1_ending`, StoryFlow -> V5 -> credits -> complete panel),
  `MISSION_REWARDS[&"m04"]` with `set_flags`, `m4_malrik_pylons`, the `heart_stone` actor; the Missions-list replay path.
- [ ] 19.C6 / 19.C11 / 19.A2 (shared): the boss, pylons, Old Vey and his brain as ep1 9; plus here: `pylon_destroyed`
  carries `by_team`, the Colossus's phase-2 path is the West Crown Bridge then the lane.
- [ ] 19.A1 (ai): profile `mission_04` (Shadow normal, `min_attack_pop` 14, workers 6, max 20 at `(30, -30)`, no Gloom
  Hall rebuild); obeys the pylon-strike override and the phase-3 pull-back; ignores `"boss"` targets unless attacked.
- [ ] 19.U5 (ui): Hollow meter line, pylon counter, boss bar with 100 / 70 / 40 marks, Turn the Key prompt and ring, Vey's
  Charged Ground ring on the minimap, all hidden during cinematics.
- [ ] 19.V1-V4, 19.V25 (tech-artist): Colossus, pylon + tether, VFX family, isle pit + moat stages, storm layer; `PERF OK`
  with the Colossus, 4 pylons, 24 Wardens and 120 units on screen.
- [ ] Lead: scripted headless runs on normal: (a) seat at ~6:00, (b) meter Rise, each ends `victory=true` in 22-28
  game-minutes (cinematics on fallback cards); the darkest hour fires once by boss HP and once (forced) by keep HP; a
  skip of every cutscene leaves the same state as a full play; the isle-guard fight leaves >= 20 of the 26 start pop alive
  in 5 / 5 runs.

## Consistency notes (for the doc owners)
| # | Where | Issue | Fix taken here |
|---|---|---|---|
| 1 | ep1 5.4 P2 `(-13, -34)` | 4.5 m from Reed Ford's centre, below the 6 m rule of the same paragraph | P2 at `(-15, -34)` (6.5 m); P4 mirrored |
| 2 | ep1 6 "the 8 pillars" vs `skirmish-1v1.md` "10 pillars" | Count mismatch | Cosmetic: the Rise removes the whole ring, whatever its count |
| 3 | ep1 5.4 start tier | Not stated | Keep starts as a Stronghold (`max_tier = 2`, D7 keeps the Citadel for e2m1) |
| 4 | ep1 5.4.3 phase 3 | Malrik's army unspecified after the rescue | Pulls back (L25), the bot defends only |
| 5 | ep1 2 speaker `torren` | `cast.json` uses `vey` (`torren` is an alias) | Lines use `vey` |
| 6 | ep1 7.2 `m4_rise` shot 1 | Shows Vessa on the stone even on the meter path | Kept: the film reads as the relics drawing her there; the end state is the same on both paths |

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Kilnwarden (unlocked m01, spotlit here).
- **Why here:** Keystone Colossus armor 25 -> 5 under Slag Rain (titan autocast); Mana Scald on Malrik; Shadow Knights.
- **Moment:** phase 2, Cracked Leg: ring on the boss + "Kilnwarden: Slag Rain the Colossus. Its stone armour melts from 25 to 5.".
- **Intro card:** `Kilnwarden. Melts armour, burns mana: it makes big things soft and casters empty.`

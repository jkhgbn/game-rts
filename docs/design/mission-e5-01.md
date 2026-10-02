# Campaign mission e5m1: "The First Spark" (young Vessa + Old Vey in his prime; Episode 5)

Written 2026-10-02 (`campaign-outline.md` 3.5, row 1). Episode 5 "The Spark and the Candle" (origins), mission 1 of 4: a
**flashback**. Twelve-year-old Vessa, apprentice in the Master's citadel, takes Torren Vey's first trial in the valley
under the citadel: light five old signal beacons and call the south watch home while border raiders loot the farms. It
plays right after `ep5_opening`. Target **12-15 min** on normal. It doubles as the campaign's **basics refresher** (walk
the wizard, light, gather, build, train, attack-move, Fireball, level up) for players who start the Origins chapter.
Rules of `mission-01.md` (format), `levels.md`, `spells.md`, `tiers.md` 6, `t3-helpers.md` 4.2 (Vey's model / ability
code), `story-episode-1.md` 5.0.1 (Vey's story kit). New scene `missions/mission_e5_01.tscn` +
`scripts/campaign/mission_e5_01.gd` (`MissionE501 extends MissionBase`, mission id `e5m1`, outline D6). Metres, seconds,
`m:ss` of `MissionBase.mission_time()`; positions `(x, z)`, `y = 0`, `+z` = south. Status: **design only**; nothing
here is built. Recommended option taken everywhere.

## Episode 5 shared rules (all four missions; e5m2-e5m4 refer to this section)
| # | Point | Decision (recommended) | Why |
|---|---|---|---|
| F1 | Carry | **Nothing is carried in or out** (outline D8: origin episodes are the past). Every start state is fixed in its spec; a victory saves **flags only** under a separate `ep5` track (`CampaignState.MISSION_REWARDS[&"e5mN"] = {"flags": {...}, "next": ...}`); items and essence at the end are discarded. Vessa's and Malrik's present-day tracks are untouched | A 12-year-old does not own the Ember Crown; replays need no save |
| F2 | Ages and looks | e5m1 Vessa **12**, e5m2 Vessa **15**, e5m3 Malrik **13**, e5m4 Vessa **17** and Malrik **18** (Ep7 C1: the cities gift is ~3 years before the vanishing, Vessa ~17). Model hooks: `set_look(&"young")` (e5m1-e5m3: scale 0.82 at 12-13, 0.9 at 15, plain apprentice robe, no crown / no knife belt, bigger hair silhouette so the read stays at RTS zoom) and `set_look(&"apprentice")` (e5m4: the real kit at full scale, plain robes, the Ep7 H19 look). Old Vey `set_look(&"prime")`: fifties, iron-grey braid, no coat frost, plain steel blade, **runes dark**. Timeline (outline D5: the vanishing is 12 years before Ep1): e5m1 and e5m3 happen the same year, **8 years before the vanishing** (20 before Ep1); e5m2 5 years before; e5m4 and the cities gift 3 years before | Same people the player knows, readable as younger; e5m4 matches the film that follows it. Malrik is found last ("Fourth of four", `ep3_opening` L4): Vessa was already the Master's at e5m3 |
| F3 | Tiers and systems | `tiers_enabled = true` with `tier_system.max_tier = 1` (no X button, `Not in this mission`), `bots_upgrade = false`. A mission without a TierSystem reads as tier 3 (`tiers.md` 1), so the knob is required. `casters_enabled`, `helpers_enabled`, `tavern_enabled`, `trade_enabled`, `river_enabled`, `camps_enabled`, `beasts_enabled`, `points_enabled` all **false**; `StrIntPath` off (missions) | Tier 1 only, small armies (outline 3.5); every system the young heroes would not have is off |
| F4 | Level caps | e5m1 **3**, e5m2 **4**, e5m3 **3**, e5m4 **5** | Low caps (outline 3.5); each mission opens exactly the spells it teaches |
| F5 | Voices | Young Vessa and Malrik use their own ids `vessa` / `malrik` and voices (the Ep7 4.3 rule: "flashback, no new voice"). Old Vey is `vey`, the Master `master`, the narrator `narrator`, Sergeant (later Captain) Ashby `ashby`, Torvald `torvald`, Ysolde `ysolde`. **Two new speakers** for the episode, added to `data/voice/cast.json` after an audition: `gannet` (Gannet Rook, reiver chief, e5m1-e5m2) and `reeve` (Reeve Aldous Pike, e5m3) | Minimum new cast; villains need one voice each |
| F6 | Vey's lightning | **Never shown to Vessa.** In Ep1 V1 she shouts "LIGHTNING? Since when do you-": she must not have seen it. Vey fights with the sword only (his `prime` kit below); the only flicker is a camera-only beat at the end of e5m1 that she does not see | Continuity with `story-episode-1.md` V1 / M0 |
| F7 | Teaching | Each mission re-teaches one slice: e5m1 basics; e5m2 siege, support aura, patience; e5m3 fog, stealth, a toggled ability; e5m4 1v1 macro and capture points. Hints are messages (12 s, once each) written for the **Classic** scheme with the Hero WASD variant in brackets; key letters go through `KeyLabels` (AZERTY prints its own letters) | Outline 3.5: "they double as a refresher for new players" |
| F8 | Story flow | StoryFlow: `ep5_opening` -> e5m1 briefing -> e5m1 -> e5m2 briefing -> e5m2 -> `c_e5_turn` (bridge, `mission-e5-03.md`) -> e5m3 -> e5m4 -> `ep5_ending` (0:40, the cities gift). Story menu card "Episode 5 · Origins" (outline C8) | One chain; the bridge hands the episode from Vessa to Malrik |
| F9 | Present-day frame | Each briefing opens with one present-day line (the winter truce of `ep4_ending`), then two lines of the past | The outline's frame (Vessa's sword-knot, Malrik's candle) without new films |
| F10 | Fight sizing | Every guarded fight <= **70 %** of the army value the player can have then (ep1 4.1 rule); army value = crystal costs + wizard worth `170 + 30 x level` + story allies at their listed value | Same rule as every mission |
| F11 | Enemy kinds (new story data, Episode 5 only) | **Duskfen Reivers**: border raiders from the fens south of Fire's land (before Fire was a kingdom). Unit types (gameplay, `data/units/`): `reiver` (copy of `magpie` numbers: 140 HP, 9 dmg, 1.5 range, speed 5.2; value **80**), `reiver_slinger` (copy of `ember_archer` numbers: 70 HP, 9 dmg, range 9; value **100**), war-boars = the existing `bristleback` set to team ENEMY (200 HP, armor 5, 11 dmg; value **120**), chief `reiver_chief` (Gannet Rook, kit below). All team ENEMY, scripted (no Commander), `is_commandable()` false for the player | Original foes for a time before the kingdom wars; reuse existing numbers and creature models |

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | Map | **"The Vale of Bells"**, the `main.gd` generator, 120 x 120, `MAP_SEED := 5101`, **not mirrored**; the north edge is the foot of the citadel's mountain (impassable cliff decor), the south-east corner is the valley mouth toward the fens | Small, readable, one direction of threat |
| D2 | Base | A small watch fort, **Valewatch**: a Fire keep copy `valewatch_keep` (2 000 HP, trains Cinder Hands only, no tier button), no pre-built Hall: the player builds the Ember Hall (refresher) | Teaches the build menu again |
| D3 | Old Vey | Story ally `torren_vey`, look `&"prime"`, **sword-only kit** (F6), autonomous Escort brain, cannot die | Teacher in his prime; the lightning stays his secret |
| D4 | Beacons | 5 `MissionBrazier` props (the M1 rule: Vessa within 3 m for 3 s), any order; the 5th starts the final | Re-uses the built brazier code; braziers are the series' signature |
| D5 | Final | After the 5th beacon: hold **1:30** until the south watch rides in, or drive Gannet off (below 40 %) for an early end | A short, readable climax for a refresher |
| D6 | Items | `items_locked = true` (no shop, no essence shown) | One less thing to teach; m01 teaches items |

## Story setup (briefing text, 3 short paragraphs)
1. *Winter, the truce. In Emberfall, Vessa turns an old sword-knot in her fingers. Vey's. She remembers the first time
   he made her wait.*
2. Twenty years before the crown, the Master's citadel rose above the clouds and the world was at peace, nearly. In
   the Vale of Bells below it, the old signal beacons had gone cold, and reivers from the southern fens had noticed.
3. Torren Vey, the Master's sword, set his youngest apprentice her first trial: light all five beacons and call the
   south watch home. Vessa was twelve. She had never waited for anything in her life.

## Map: "The Vale of Bells" (120 x 120, generator, seed 5101, not mirrored)
Afternoon light turning to dusk over the mission (lighting preset `vale_afternoon` -> `vale_dusk` from the 5th beacon,
tech-artist). Camera bounds x -56..56, z -54..58; cliffs (impassable decor, 2 bound walls baked into the navmesh like
`mission-00.md`) along z < -54 and x > 56. Clearings: no trees / rocks inside.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Vessa, Vey 2 m east) | `(-30, -34)` | - | |
| **Valewatch** (`valewatch_keep`) | `(-38, -42)` | 16 | 2 000 HP, shoots (keep numbers), trains Cinder Hand (Z) |
| Node `v_home_a` / `v_home_b` | `(-48, -36)` / `(-30, -52)` | - | **1 200** each (11.7 m / 12.8 m from the keep) |
| Node `v_mill` (optional) | `(-46, 2)` | 7 | **1 500**; a second Hall can stand here (no hall spot needed) |
| **Beacon 1 "Hearthstone"** | `(-18, -24)` | 6 | 15.6 m from the start: the tutorial beacon |
| **Beacon 2 "Millrace"** | `(-42, 14)` | 8 | Among the farms; reivers loot the mill |
| Millrace farms F1 / F2 / F3 | `(-34, 22)` / `(-50, 20)` / `(-28, 30)` | 4 each | `millrace_farm` buildings, team PLAYER, 500 HP, `counts_for_defeat = false`, no function (`sec_farms`) |
| **Beacon 3 "Old Bridge"** | `(2, 0)` | 8 | A dry stream bed (decor, walkable) from `(-10, -22)` to `(14, 24)` with a stone bridge prop at `(2, 0)` |
| **Beacon 4 "Shepherd's Knoll"** | `(36, -18)` | 8 | Neutral beasts' hill (G4) |
| **Beacon 5 "Bellmouth"** | `(26, 34)` | 8 | The valley mouth; a ruined bell-tower prop at `(30, 30)` |
| **Reiver camp** | `(44, 46)` | 14 | 2 **Reiver Tents** `(40, 48)` / `(48, 42)` (`reiver_tent`, team ENEMY, 450 HP, `counts_for_defeat = false`) |
| Spawn `SP_SE` (valley mouth) | `(52, 54)` | 5 | Wave spawns; Gannet's retreat point |
| Spawn `SP_W` (the Millrace ford) | `(-56, 30)` | 5 | The farm raiders' path in |
| Citadel terrace (cutscene actor spot) | `(0, -64)` | - | Outside the bounds, on the cliff top: the Master watches |
Distances (path): start -> B1 16 m, B1 -> B3 32 m, B1 -> B2 44 m, B3 -> B4 38 m, B3 -> B5 42 m, keep -> camp 125 m.

**Beacon** (`MissionBrazier` subclass `MissionBeacon`, systems): a 2.6 m stone pillar with an iron fire-basket. Lit by
**Vessa within 3 m for 3 s** (progress ring; leaving 3 m resets it; damage does not), only Vessa. Lit = tall flame +
light (energy 2, range 10), a `SightMarker` sight **16** for the player (permanent), a flame line on the minimap from the
beacon north to the citadel. A lit beacon stays lit (reivers cannot put it out).

## Start state
| Item | Value |
|---|---|
| Vessa | **Level 1**, Fireball r1, full HP / mana, **level cap 3**, look `&"young"` (F2); no inventory bar (`items_locked`) |
| Old Vey | `torren_vey`, look `&"prime"`, at Vessa's side (kit below) |
| Crystals | **250** (no essence shown) |
| Buildings | Valewatch (complete) |
| Units | 4 Cinder Hands gathering (2 on each home node), **3 Flame Guards** at `PLAYER_START + (3, -3)` |
| Population | 7 / 20 (keep 20; **Hearth max 1** = cap 30) |
| Enemy | Guards G1-G5 (below); nothing else on the map until W1 |
| Fog | On; the 5 beacons are explored from 0:00 (`FogOfWar.reveal(team, pos, 6)`) |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Hearth (Z, max 1), Ember Hall (X), Ember Spire (C) | Bazaar, stables, walls |
| Units | Cinder Hand (keep Z); Ember Hall copy `fire_barracks_e5m1`: **Z Flame Guard, X Ember Archer**; story gifts: 2 Ember Archers (B2), 2 Blaze Riders (B4) | Blaze Rider and Ash Hurler training (e5m2), everything tier 2+ |
| Keep | No tier button (F3) | Stronghold, Citadel |
| Spells | Fireball (L1), Ember Step (L2+) | Kindle (needs L4; cap 3) |
| Items | None (`items_locked`) | Shops (e5m2) |

### Old Vey in his prime (`torren_vey`, look `&"prime"`, team PLAYER, not commandable; gameplay + ai)
The `story-episode-1.md` 5.0.1 story kit with the lightning removed (F6) and a teacher's passive. Value for fight sizing
**700**.
| Stat / ability | Value |
|---|---|
| HP / armor / speed / sight | **1 400** / 25 / 5.0 / 13 |
| **Old Steel** (attack) | 32 melee, cooldown 1.2; every 3rd strike also hits every enemy within **2.5 m in front of him** for 50 % (a wide sweep, dust arc, **no spark**) |
| **Intercept** | Every 8 s, when an enemy that targets Vessa is within 10 m of him: a 0.3 s stride (dust, no crackle) next to it and `taunted` 3 s |
| **The Lesson** (passive) | While he is within **10 m** of Vessa, her Fireball costs **30** mana instead of 40 |
| **Your trial** | He never lights a beacon and never attacks buildings (tents included) |
| Cannot die | At 1 HP he kneels 8 s (L24), then stands at 40 % HP |
Brain (ai, the 19.A2 Escort brain): stay 3-7 m from Vessa; while she lights a beacon, stand 4 m from her between her and
the nearest enemy; Intercept as above. **Teaching bark**: when Vessa is more than **14 m** from every own soldier
(workers excluded) outside the base ring (24 m around Valewatch) for **5 s**, L14 (max once per 60 s). It seeds e5m2.

### Gannet Rook (`reiver_chief`, team ENEMY, scripted; gameplay)
Value **500**. Kit shared with e5m2 (that mission raises his HP).
| HP | Armor | Attack | Speed | Abilities |
|---|---|---|---|---|
| **700** | 10 | 20 melee, cooldown 1.2 | 5.2 | **Hook Throw** (12 s, range 8): a chain hook pulls the target 6 m toward him (`Unit.displace(to, 0.4)`) and deals 15; targets Vessa if in range, else the nearest ranged unit. **Flees at 40 % HP** (walks to `SP_SE`, untargetable after 2 s, despawns; never dies here: he is e5m2's boss) |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_beacons` | Primary | `Light the beacons of the Vale (0 / 5)` | 5 beacons lit |
| `obj_hold` | Primary (appears after `obj_beacons`) | `Hold the Vale until the south watch rides in (1:30)` | 90 s pass, or Gannet is driven off (below 40 %) during the hold |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `sec_farms` | Secondary (from E7) | `Keep the Millrace farms standing (3)` | At victory all 3 farms stand (fails at the first farm burned) |
| `sec_tents` | Secondary | `Burn the reivers' tents (0 / 2)` | Both Reiver Tents destroyed |
States through `Events.objective_changed(id, state)`: `"active"`, `"done"`, `"failed"`.

## Guards, waves and the AI (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Every enemy here is scripted (no Commander, no enemy economy). Guards hold their spot with auto-aggro and a 2x leash;
waves spawn at the named spawn point with the order shown, re-issued every 3 s.
| Group | Where | Units |
|---|---|---|
| G1 lookouts | Beacon 1, `(-15, -20)` | 2 Reivers |
| G2 mill looters | Beacon 2, ring r 4 | 3 Reivers + 1 Reiver Slinger |
| G3 bridge band | Beacon 3, `(4, 4)` | 3 Reivers + 2 Reiver Slingers |
| G4 knoll beasts | Beacon 4, ring r 4 | 2 Bristlebacks + 1 Mirefang, team **NEUTRAL** (map-fill numbers, leash 2x; they fight only inside it) |
| G5 Bellmouth watch | Beacon 5, ring r 4 | 3 Reivers + 2 Reiver Slingers |
| G6 camp | The tents | 2 Reivers per tent (hold the tents) |

| Wave | Trigger | Units | Spawn | Order |
|---|---|---|---|---|
| W1 | `max(4:00, Beacon 1 lit + 60 s)` | 3 Reivers | `SP_SE` | Attack-move to the nearest Cinder Hand |
| W2 farm torches | Beacon 2 lit | 3 Reivers + 1 war-boar | `SP_W` | Attack-move to the nearest standing farm, then to Vessa |
| Farm raids | Every **120 s** after W2, until Beacon 3 is lit | 2 Reivers | `SP_W` | Attack-move to the nearest standing farm |
| W3 | Beacon 3 lit | 4 Reivers + 2 Reiver Slingers + 1 war-boar | `SP_SE` | Attack-move to Valewatch |
| Camp call | Every **150 s** after W3, per living tent, until the 5th beacon | 2 Reivers | That tent | Attack-move to the nearest lit beacon, then Vessa |
| Final | 5th beacon lit | 0 s: **Gannet** + 5 Reivers + 2 Reiver Slingers + 2 war-boars; 40 s: 3 Reivers + 1 Reiver Slinger | `SP_SE` | Attack-move to Vessa's position, refreshed every 3 s |
If `sec_tents` is done before the 5th beacon, the Final loses **30 %** of its units (rounded down; Gannet stays) and the
camp calls stop for good (also per tent as each burns).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | (`ep5_opening` and the briefing played before.) Cutscene `e5m1_valley` (HOLD 0:15); L1-L3; hint `Right-click to walk Vessa (Hero WASD: W A S D). Light the beacon to the south-east: stand beside it.` |
| E2 | Vessa within 12 m of a beacon the first time | L4; hint `Stay within 3 m of the beacon for 3 seconds. Only Vessa can light it.` |
| E3 | First beacon lit | L5-L6; `obj_beacons` 1 / 5; hint `Select the Keep and press Z to train a Cinder Hand. Then select a Cinder Hand: B, then X, builds an Ember Hall.`; W1 armed |
| E4 | Ember Hall complete | Hint `Select the Ember Hall: Z trains a Flame Guard, X an Ember Archer. Right-click the ground to set their rally point.` |
| E5 | W1 spawns | L7 (Gannet, voice only); hint `Select your soldiers, press X (or A) and click: they attack everything on the way. F then click: Fireball.` |
| E6 | Vessa reaches level 2 | L8; hint `Level up! Ctrl+Q learns Ember Step, then Q and click to jump. Ctrl+1 puts your selection in group 1.` |
| E7 | Beacon 2 lit | L9-L10; 2 Ember Archers (team PLAYER, commandable, "Millrace volunteers") walk out of F1; `sec_farms` active; W2 |
| E8 | Beacon 3 lit | L11; W3; farm raids stop; camp calls armed |
| E9 | Vessa within 14 m of G4 the first time | L12; hint `Neutral beasts guard their ground but never chase far. Draw them off the beacon, or pass by.` |
| E10 | Beacon 4 lit | L13; 2 Blaze Riders (team PLAYER, commandable, "the south watch's scouts") ride in from the east edge `(54, -18)`; hint `Blaze Riders are fast: send them after the slingers.` |
| E11 | The teaching bark (Vey brain) | L14 (max once per 60 s) |
| E12 | A Reiver Tent destroyed | L15 (first only); `sec_tents` counter; at 2 / 2 done |
| E13 | 5th beacon lit | L16-L17; `obj_hold` active (1:30 countdown); the Final wave; lighting turns to dusk over 6 s |
| E14 | Gannet below 40 % during the hold | L18; he flees; `obj_hold` done at once |
| E15 | `obj_hold` done | Cutscene `e5m1_watch` (HOLD 0:40) with L19-L23; `Events.mission_ended(true)` at its end |
| E16 | Vey kneels the first time | L24 |
| E17 | Vessa dies | L25; `obj_vessa` failed; defeat after 3 s |
| E18 | A farm burns (first) | L26; `sec_farms` failed |
Beacons can be lit in any order; E3's hint is on the first one, the gifts stay tied to Millrace (E7) and the Knoll (E10).

## Dialogue (26 lines; 5 s each unless listed; every line <= 96 characters = 2 lines of the box)
Speaker colours: Vessa `(1.0, 0.45, 0.1)`, Vey `(0.95, 0.95, 0.55)`, Gannet `(0.62, 0.55, 0.40)` (new), Master
`(1.0, 0.92, 0.70)`, Narrator `(0.9, 0.85, 0.7)`. Voice file `data/voice/lines/e5m1.json` (the `m00.json` format).
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Long before the war, a girl with soot on her hands came down into the Vale of Bells. |
| L2 | E1 | vey | Five beacons, Vessa. Light them all and the south watch comes home. That is the trial. |
| L3 | E1 | vessa | Five? I could light fifty. Can I light the bridge too? It looks very flammable. |
| L4 | E2 | vey | Stand close and hold still. Fire comes when you stop chasing it. |
| L5 | E3 | vessa | Ha! One! Did you see? Tell me you saw that. |
| L6 | E3 | vey | I saw. Now build something to guard it. A beacon on its own is just a target. |
| L7 | E5 | gannet | Pretty lights in the vale! Keep lighting them, little match. We'll follow them home. |
| L8 | E6 | vey | You're getting stronger. Learn to step out of trouble before you learn to start it. |
| L9 | E7 | vessa | Millrace is lit! And the mill is... mostly not on fire. Mostly. |
| L10 | E7 | narrator | The miller's boys took down their bows from the wall. Nobody had asked them to. |
| L11 | E8 | vey | Halfway. Your soldiers are tired, Vessa. Let them catch up. |
| L12 | E9 | vey | Leave the boars their hill and they'll leave you yours. Take the beacon, not the fight. |
| L13 | E10 | narrator | On the far road, the south watch's scouts saw the fire and turned their horses home. |
| L14 | E11 | vey | Vessa! A spark that runs off alone goes out. Wait for your soldiers. |
| L15 | E12 | vessa | Oops. Tents are very flammable. Who knew? ...Everyone. Everyone knew. |
| L16 | E13 | gannet | All five lit? Then the whole vale can watch you lose. Boys! Fetch me that match! |
| L17 | E13 | vessa | Come on, then! I've got five fires and a really bad temper. |
| L18 | E14 | gannet | She burned my good coat! Back to the fens! Back to the fens! |
| L19 | E15 | narrator | At dusk the south watch rode home along a road of fire. |
| L20 | E15 | vey | Not bad, girl. Remember it: the spark first. Then the storm. |
| L21 | E15 | vessa | What storm? I don't have a storm. Do YOU have a storm? |
| L22 | E15 | vey | Ha. Go and wash your face. You look like a chimney. |
| L23 | E15 | master | Not yet, old friend. Let her find her own fire first. (4 s) |
| L24 | E16 | vey | Just catching my breath. Keep lighting! (3 s) |
| L25 | E17 | vessa | Vey... I didn't wait... |
| L26 | E18 | vessa | No, no, no! That was somebody's house! |
Echoes: L20 is the first time Vey says his motto (`story-episode-1.md` V1 / M1 L17 / M4 "The spark first. ...Then the
storm."); L21 sets up Ep1 V1's "LIGHTNING? Since when do you-"; L23 is the Master's only line here and pays off Ep8's "His.
Lent to me to keep you four alive" (the storm is the Master's, kept from her on his word); L14 and L25 are the prologue's
"she never waits" (S16), turned into e5m2's rule.

## Cinematic hooks (ENGINE, CinematicPlayer 19.C1; skippable; the mission clock stops while they play)
| Id | Kind | When | Length | Shots | End state (a skip must leave exactly this) |
|---|---|---|---|---|---|
| `e5m1_valley` | ENGINE, **HOLD** | E1 | 0:15 | 1) CRANE down from the citadel's cloud-line (the `forge_citadel` far card on the north sky) to the vale; 2) MS young Vessa and Vey on the path, Vey points south-east with his sheathed sword; the 5 cold beacon pillars catch the light in a row. L1 over shot 1 | Vessa at `PLAYER_START`, Vey 2 m east, Flame Guards at their spot, no orders; camera on Vessa; control returns |
| `e5m1_watch` | ENGINE, **HOLD** | E15 | 0:40 | 1) WIDE at dusk: the 5 beacons burning down the vale, 6 Blaze Riders (south watch, actors) ride up the road from `SP_SE` to Valewatch; 2) MS two-shot Vessa (soot on her face, beaming) and Vey, 3/4, eye: L20-L22; 3) Vessa runs off toward the riders; 4) CU Vey alone, slow push: one **white-gold flicker** runs down his blade and dies (the blade's runes light for 0.5 s, then dark); 5) LOW long lens up the cliff: on the citadel terrace a very tall hooded figure with a burning hem turns away (the Master, face unseen): L23; FADE_BLACK | Every reiver despawned; riders by the keep; dusk preset on; victory |
Camera axis: Vessa - Vey line east-west; cameras stay on its south side. Fallbacks until the sets exist: the citadel far
card can be a sky-dome billboard; the Master actor is the prologue's B6 stand-in. Theatre: both unlock on a win.

## Win / lose
| Event | Result |
|---|---|
| `obj_hold` done | **Victory** after `e5m1_watch` (`Events.mission_ended(true)`) |
| Vessa dies | **Defeat** (`instant_loss_on_wizard_death = true`, gdd rule) |
| Valewatch destroyed | **Defeat** |
| Vey kneels | Nothing (he stands after 8 s) |
| A farm burns | `sec_farms` failed; play goes on |
| All Fire soldiers dead, Vessa alive | Nothing; she can still light and hold |

## Reward (F1: flags only)
`MISSION_REWARDS[&"e5m1"] = {"flags": {"e5m1_farms_saved": "sec_farms", "e5m1_tents_burned": "sec_tents"}, "next":
&"e5m2"}` plus `e5m1_time` (seconds). e5m2's briefing names the reivers' chief as the one who got away; if
`e5m1_farms_saved`, the Millrace volunteers (2 Ember Archers) join e5m2's start ("the miller's boys, three years older").

## Economy
| Item | Value |
|---|---|
| Start | 250 crystals, 4 Cinder Hands, 7 / 20 pop |
| Nodes | 2 x 1 200 at home, 1 500 at the mill (optional) |
| Expected (normal) | 7-8 Cinder Hands by 4:00, Ember Hall ~2:30, ~2 200 crystals mined by 13:00; army ~12-14 pop at the final (Flame Guards + Ember Archers, 2 gift archers, 2 gift riders) |

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave / guard counts | x 0.6, no war-boars | as written | x 1.4; Final +1 war-boar |
| Start | 350 crystals, 4 Flame Guards | as written | 200 crystals, 2 Flame Guards |
| Gannet HP / Hook cooldown | 550 / 15 s | 700 / 12 s | 900 / 10 s |
| Hold timer | 60 s | 90 s | 120 s |
| Old Vey | same | same | same |
| Expected time | 10-13 min | 12-15 min | 14-18 min |
Fight sizing (normal, F10; player value: Vey 700 + soldiers + Vessa `170 + 30 x level`):
| Fight | Enemy | Player then | Ratio |
|---|---|---|---|
| G1 lookouts (~0:40) | 160 | 700 + 270 + 200 = 1 170 | 14 % |
| W1 (4:00) | 240 | ~1 400 | 17 % |
| G2 mill looters | 340 | ~1 500 | 23 % |
| W2 farm torches | 360 | ~1 700 (+ 2 gift archers 200) | 21 % |
| G3 bridge band | 440 | ~1 800 | 24 % |
| W3 (Beacon 3) | 640 | ~1 900 | 34 % |
| G4 beasts (NEUTRAL) | ~520 | ~2 000 | 26 % |
| G5 Bellmouth watch | 440 | ~2 200 (+ 2 gift riders 360) | 20 % |
| Final 0 s / +40 s | 1 340 / 1 680 | ~2 400 | 56 % / 70 % |
- The refresher must never stall: W1 waits for the first beacon + 60 s, the Ember Hall is cheap (150) and the start
  crystals pay for it plus two Cinder Hands. A player who never builds the Hall still wins on easy with Vey alone.
- The Final is the one real fight: Hook Throw pulls Vessa out of her line, so the intended answer is Ember Step back to
  Vey (or Vey's Intercept) and Fireball on the clumped reivers. Watch in the first playtest: if the hold kills Vessa
  more than 1 run in 4 on normal, drop the +40 s group to 2 Reivers.

## Target length (normal)
| Part | Time |
|---|---|
| `e5m1_valley` | 0:15 |
| Play to the 5th beacon (`mission_time`) | 10:00-12:30 |
| Hold | 1:30 (less if Gannet is driven off) |
| `e5m1_watch` | 0:40 |
| **Total** | **~12-15 min** (outline 3.5: 12-15) |

## Implementation tasks (proposed ids; the lead adds them to `waves.md`)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| **E5.S0** | systems | Episode 5 shared: `CampaignState` `ep5` flag track (F1: flags only, no item / essence save), `MISSION_ORDER` gains `e5m1`-`e5m4`, StoryFlow chain of F8 (with `c_e5_turn` and `ep5_ending` placeholders = 3 s title cards until the films exist) | 19.C2 MissionBase | Test: winning e5m1 writes only flags; Vessa's and Malrik's tracks are byte-identical before / after |
| **E5M1.S1** | systems | `missions/mission_e5_01.tscn` + `mission_e5_01.gd` map part: seed 5101, clearings, bound walls, camera bounds, `valewatch_keep` type, nodes, 5 `MissionBeacon`s (3 s / 3 m, sight 16, minimap flame lines), 3 `millrace_farm`s, 2 `reiver_tent`s, dry stream and bridge decor, `tiers_enabled` + `max_tier = 1`, `items_locked`, Hearth max 1, start state, spawn points | MissionBase, F3 | Test `tests/test_e5m1_s1.gd`: every table position within 1.5 m; a beacon lights in 3 s within 3 m and resets on leaving; Vey and Vessa start 2 m apart; the keep card has no X button |
| **E5M1.S2 [H]** | systems-high | Objectives and events E1-E18; guards G1-G6 (2x leash); waves W1 (the `max` rule), W2, farm raids, W3, camp calls, Final (+40 s, 3 s refresh), `sec_tents` -30 % rule; gifts at E7 / E10; hold and the Gannet early end; instant loss; keep loss; difficulty table; rewards and flags | E5M1.S1, E5M1.G1 | Scripted headless run on normal lights 5 beacons and ends `victory=true` in 11-15 game-minutes in 3 / 3 seeds; the G1 fight leaves all 3 start Flame Guards alive in 5 / 5 |
| **E5M1.G1** | gameplay | `torren_vey` `prime` kit (Old Steel sweep, Intercept without crackle, The Lesson, kneel 8 s -> 40 %, never attacks buildings); `reiver`, `reiver_slinger`, `reiver_chief` (Hook Throw via `Unit.displace`, flee at 40 %) UnitTypes; `bristleback` usable as ENEMY | `t3-helpers` helper code (19.C11) | Test: Fireball costs 30 within 10 m of Vey and 40 at 11 m; Hook moves Vessa 6 m in 0.4 s; Gannet at 39 % walks off and despawns; Vey never targets a tent |
| **E5M1.A1** | ai | Vey's Escort brain for e5m1 (3-7 m, guard while she lights, the teaching bark rule) | E5M1.G1 | Vey stays within 8 m of a walking Vessa; the bark fires once when she is 15 m from all soldiers for 5 s and not again within 60 s |
| **E5M1.U1** | ui | Objectives panel (beacon counter, hold countdown), the hint queue (control-scheme aware via `KeyLabels`, Classic text + Hero WASD bracket), `gannet` name / colour / portrait slot, no resource essence and no inventory bar while `items_locked` | 19.U1 / 19.U3 | Readable at 1600 x 900 and 3440 x 1440; hints never overlap the dialogue box |
| **E5M1.C1** | systems-high | `e5m1_valley` and `e5m1_watch` with the end states above | 19.C1, E5M1.S2 | Skipping each leaves its end state; the clock does not run while they play |
| **E5.V1** | tech-artist | `set_look(&"young")` for Vessa (12 and 15) and Malrik (13), `&"apprentice"` for both (Ep7 H19), Old Vey `&"prime"`; one sub-element per agent | 19.V20 (Vey model) | Art Lab pass; readable at RTS zoom beside a Flame Guard |
| **E5M1.V2** | tech-artist | Beacon pillar (cold / lit), Millrace farm + mill, Reiver Tent (burning state), reiver / slinger / Gannet looks (fen leather, reed cloaks, chain hook), stream bed + stone bridge, ruined bell-tower, `vale_afternoon` / `vale_dusk` presets, the blade-flicker VFX for `e5m1_watch` | - | 0 lights except the presets; `PERF OK` with the Final on screen |
| **E5.O1** | Voice Forge agent | Audition `gannet` (`am_echo` 0.98 · `am_fenrir` 1.0 · `{am_onyx 0.5, am_echo 0.5}` 1.0) and `reeve` (`bm_fable` 0.95 · `{bm_daniel 0.6, bm_fable 0.4}` 0.95), add the picks to `cast.json`; render `e5m1.json` (L1-L26) | Lines frozen by E5M1.D1 | Every WAV fits its slot |
| **E5M1.D1** | game-designer | Read the 26 lines in game once, trim any over 2 lines; check the Final from the first playtest | Playtest | Changes written back here |

## Done when (acceptance checks)
- [ ] E5.S0: Episode 5 saves flags only; the chain plays `ep5_opening` (or its card) -> e5m1 briefing -> e5m1.
- [ ] E5M1.S1: the Vale builds from seed 5101 with every table row within 1.5 m; 5 beacons light by Vessa only (3 s / 3 m, reset on leaving) and each gives sight 16; no tier button; no shop.
- [ ] E5M1.S2: E1-E18 in order on a scripted normal run; W1 never before 4:00 nor before Beacon 1 + 60 s; farm raids stop at Beacon 3; the Final at the 5th beacon; `obj_hold` ends at 90 s or on Gannet's flight; victory after `e5m1_watch`; defeat on Vessa's death or Valewatch's fall.
- [ ] E5M1.G1 / A1: Vey's kit as the table (no lightning VFX anywhere in the mission, checked by a VFX-id scan of the run log), kneel-and-return, the bark rule; Gannet's hook and flight.
- [ ] E5M1.U1 / C1 / V2 / E5.V1 / E5.O1: hints in both control schemes, both cutscenes skip to their end states, art and voice in game.
- [ ] Lead: scripted headless run on normal `victory=true` in 12-15 game-minutes (cutscenes included) in 3 / 3 seeds; the smoke and perf tests still pass.

# Campaign mission e2m4: "Sunrise Road" (Vessa + Old Vey vs Mother Hush and the shard's Wardens)

Task: script for `campaign-outline.md` 3.2 row 4 (the Ep2 outline, "next up" after section 6). Episode 2 "The Light
Below", mission 4 (id `e2m4`, outline D6). Plays right after `c_e2_stair` "On the Way Down" (`mission-e2-03.md`
"Cinematic hooks"). The descent: **underground, narrow halls, a small army, no base until the Warden Forge**, light
against the dark, and **research** (Ember Forge / Cinder Sanctum, `research.md`, moved here by the outline). Old Vey's
storm wakes the Master's Ruin Wardens as friends; Mother Hush, carrying a splinter of Malrik's shard, wakes them as
enemies. Target **17-23 min** on normal. Uses the rules of `mission-01.md` / `mission-e2-01.md` (MissionBase, scripted
groups, 70 % rule, difficulty multipliers), `mission-00.md` (Mother Hush's story kit), `research.md` (2, 3.1, 4.1, 12),
`t3-helpers.md` (Old Vey), `caster-units.md` (Kilnwarden), `items.md` campaign rules, `champions.md` 11, `balance-1.md`
(Ruin Warden numbers). New map `data/maps/sunrise_road.map` (World Forge map mode), scene `missions/mission_e2_04.tscn` +
script `scripts/campaign/mission_e2_04.gd` (`MissionE2_04 extends MissionBase`, mission id `e2m4`). Metres, seconds, `m:ss`
since the navmesh was ready; positions `(x, z)`, `y` = the hall floor, `+z` = south (the stair is south, the gate north).
Recommended option taken everywhere (no open questions).

## 0. Decisions (recommended option taken)
| # | Question | Decision | Why |
|---|---|---|---|
| D1 | The map | A **new hand-laid underground map** `data/maps/sunrise_road.map`, **80 x 160** (x -40..40, z -80..80), `symmetry=none`: the stair foot, three halls joined by narrow galleries, one flooded side branch, one side cave. World Forge map mode (tool 6) with a new `ground=deep_stone` biome and cave walls as navmesh obstacles | No generator map has halls and galleries; the outline asks for "a new underground biome, narrow halls". A story map need not be fair |
| D2 | Teams | Today's 3 teams: `PLAYER` (Fire), `ENEMY` (Hush's delvers and the **shard-woken Wardens**), `NEUTRAL` unused. **No enemy base, no Commander**: every enemy is scripted | Malrik is not here (he comes down in e2m5); a descent against a hunting party reads better than another base race |
| D3 | Whose are the Wardens | **Sleeping Ruin Wardens** in wall alcoves. Woken by **Old Vey's storm** (Vessa channels 3 s within 4 m **with Vey within 8 m of her**) = **Sunwardens**, team `PLAYER`, commandable, white-gold eyes. Woken by a **Splinter Acolyte** (Hush's delver, 3 s channel) = team `ENEMY`, amber eyes | The outline: "Vey's channel wakes Wardens as friends". The shard turning them is the escalation toward e2m5's Doorwarden. M4's Wardens were `NEUTRAL` (Obren's own); here the splinter's bearer commands them |
| D4 | Old Vey | **On the field from 0:00** as the player's **helper** (`helper_vey`, pre-called free by the mission: `HelperRoster.grant(PLAYER, &"helper_vey")`), Escort stance, F4. Before the forge is claimed he **cannot fall** (kneels 10 s at 1 HP, stands at 50 %); after, he falls and is revived at the Warden Forge at the Ep2 price (essence `120 + 20 x level`) | He leads the descent (`c_e2_stair`); the waking rule needs him alive; no Citadel exists down here to call him |
| D5 | The base | **No base at 0:00.** The **Warden Forge** in Hall 2 is claimed by Vessa (5 s channel, no enemy within 12 m); it then acts as the keep: drop-off, shop, trains Cinder Hands (Z) and the Kilnwarden (B), +20 pop, **tier 2** for every gate (`Keep.set_start_tier(2)` on it; no upgrade button: `max_tier = 2`). Four Cinder Hands and Captain Ashby's work crew come down the stair at the claim | The outline: "no base until the Warden forge". The forge being the Master's own makes the research building lesson a story beat ("he built forges down here") |
| D6 | Research | `research_enabled = true` with **tiers 1-2 only** (no Citadel down here: tier-3 research refuses `Needs a Citadel`); no trade, so tier-2 tech's gold part is paid in crystals (`research.md` 2.4). Primary objective: research **one technology and one magic** | Outline: "Research (Forge / Sanctum, research.md 12 moved here)". Tiers 1-2 keep the tree short enough for a 20 min mission |
| D7 | The dark | The halls are dark: player sight **x 0.7** (the M0 night rule); **in the dark** (outside every light), `ENEMY` units farther than **6 m** cannot be auto-targeted by player units (they can still be clicked when visible). **Lights**: a lit sunstone r 14, the claimed forge r 18, **Vessa herself r 8** (her spark), a Fireball impact r 6 for 3 s, the guides' lanterns r 5 | "Light against the dark" (outline) as one readable rule: light the stones and the Shades lose their cover; Vessa is the torch |
| D8 | Mother Hush | The **mini-boss** of Hall 3, `mother_hush` (M0's 19.C12 kit raised to her `t3-helpers.md` 4.3 numbers at level 5, story HP **1 400**): Blink Strike, Smoke Cloak, **Night of Knives once at 50 %**; **flees at 25 %**, never dies here (`sec_hush`) | `mission-00.md`: "a recurring threat for Episode 2"; flag `m0_hush_driven` gets its greeting here |
| D9 | Cavalry, trade, titans, champions | Off (`cavalry_enabled`, `trade_enabled`, `titans_enabled`, `tavern_enabled` false); the companion comes (champion rules); no Stables / Bazaar / Lair / Citadel | Narrow halls; one new system per mission (research) |
| D10 | Mission name and id | `e2m4`, `mission-e2-04.md`, `data/maps/sunrise_road.map`, `missions/mission_e2_04.tscn`, `scripts/campaign/mission_e2_04.gd`, `CampaignState.MISSION_SCENES[&"e2m4"]`, after `e2m3` | Outline D6 |

## Story setup (briefing text, 3 short paragraphs)
1. Under the Emberfall observatory a stair goes down, and down, past the last root and the last bat, into halls the
   Master cut before there were kingdoms. The Greywater guides call it the Sunrise Road. They do not say why.
2. The Master's old Wardens sleep in the walls. Old Vey says they will know his storm. Mother Hush went down first,
   with a splinter of Malrik's stone, and the Wardens she wakes have amber eyes.
3. Somewhere below there is a forge, and past it a gate. Vessa brought a small army, a big temper and the only light
   for a mile. Down here, that is the same thing.
Briefing objectives: `obj_forge`, `obj_research`, `obj_gate`, the rule `Vessa must survive`, and the line `The dark hides
the enemy: light the sunstones, and keep Vessa close to the fight.`

## Map: "The Sunrise Road" (`data/maps/sunrise_road.map`, 80 x 160, not mirrored)
Cave walls are navmesh obstacles; every gallery has the width listed (no tree / rock generator: the dressing is
stalagmites, fallen masonry and Warden alcoves, all outside the walkable widths). Build area: **Hall 2 only** (BuildGrid
mask), more than 6 m from its walls.
| Thing | Position | Size / r | Notes |
|---|---|---|---|
| The stair (entry) | from the south edge `(0, 80)` to the Stair Foot `(0, 70)` | 6 wide | Reinforcements arrive here |
| `PLAYER_START` | `(0, 66)` | - | Vessa, Vey, the army, the guides |
| **Hall 1 "Lantern Hall"** | centre `(0, 48)`, oval 40 x 32 (x -20..20, z 32..64) | - | Sunstones **S1** `(-12, 52)`, **S2** `(12, 42)`; sleepers **H1a** `(-17, 40)`, **H1b** `(17, 54)`, **H1c** `(0, 33)` |
| Gallery 1 | `(0, 31)` -> `(0, 21)`, 7 wide | - | Niche sleeper **G1n** `(-5, 25)` |
| **Hall 2 "The Warden Forge"** | centre `(0, 0)`, oval 52 x 40 (x -26..26, z -20..20) | - | **Warden Forge** `(0, -4)` (footprint 6 x 6, 2 800 HP); veins **V1** `(-17, 8)` 1 500, **V2** `(17, 8)` 1 500; sunstones **S3** `(-14, -12)`, **S4** `(14, -12)`; sleepers **H2a** `(-22, 10)`, **H2b** `(22, 10)`, **H2c** `(-10, 16)`, **H2d** `(10, 16)` |
| Side cave "Ash Seep" | crawl `(-26, -2)` -> `(-34, -10)`, 4 wide; cave centre `(-33, -12)` r 6 | - | Vein **V3** `(-33, -12)` 1 000; G4 guard |
| Gallery 2 | `(0, -21)` -> `(0, -35)`, 8 wide | - | The main way north |
| Flooded branch | `(8, -22)` -> `(20, -30)` -> `(16, -40)`, 4 wide, knee-deep water (modifier `terrain:deepwater` `move_speed_pct` -0.30) | - | A flank into Hall 3's east side, past the delve camp |
| **Hall 3 "The Sunrise Gate"** | centre `(0, -54)`, oval 48 x 40 (x -24..24, z -74..-36) | - | **The Sunrise Gate** in the north wall `(0, -76)`, channel spot `(0, -71)`; sunstones **S5** `(-14, -46)`, **S6** `(10, -66)`; sleepers **H3a** `(-20, -58)`, **H3b** `(-8, -67)`, **H3c** `(6, -42)`, **H3d** `(20, -68)` |
| **Delve Camp** (Hush's) | Night Spire `(18, -50)` (720 HP), Delve Tents `(22, -58)`, `(12, -60)` (500 HP each, `counts_for_defeat` false); spawn point `(20, -55)` | - | Waves spawn here; with all three gone they come down the north tunnel `(24, -79)` |
Distances (navmesh, approx.): start -> Hall 1 centre 18 m, -> the forge 70 m; forge -> V1 / V2 20 m, -> V3 38 m (crawl);
forge -> the gate 72 m by Gallery 2, 80 m by the flooded branch; delve camp -> forge 60 m. Map check (E2M4.S1): every
gallery keeps its width on the baked navmesh (no agent radius pinch below 3 m), the build mask covers Hall 2 only, a path
exists from `PLAYER_START` to every sleeper, sunstone, vein, the forge, the camp and the gate.

**Look** (E2M4.V1, new `deep_stone` biome): near-black blue-grey rock `(0.12, 0.13, 0.16)` with veins of faint white-gold
quartz that brighten near Vey (a shader parameter driven by distance to the helper, 0 lights); ambient `(0.10, 0.11, 0.15)`,
no sun; Vessa's own glow (an emission halo on her model and a ground decal r 8, warm `(1.0, 0.55, 0.2)`). Sunstones: a
1.6 m pale stone sphere on a pillar, dead grey; lit, it glows white-gold `(1.0, 0.92, 0.65)` with a soft ground decal r 14.
The Master's carvings on the hall walls: four-colour bands (red, blue, green, violet) worn almost away. The Warden Forge:
a squat anvil-altar under a stone hood, cold; claimed, its hearth burns orange and its chimney glows. The Sunrise Gate: a
round door of white stone 9 m wide, a sun carved on it, cracks of light at its rim. Delve Camp: violet tents, Shadow
banners, amber splinter-lanterns.

## Lights, the dark and the Wardens (systems; gameplay for the auto-target rule)
| Rule | Value |
|---|---|
| Sunstone | `MissionBrazier` variant: **Vessa within 3 m for 3 s** (progress ring; leaving resets, damage does not). Lit = permanent; a `SightMarker` r 14 for team `PLAYER`; a light zone r 14 |
| Light zones | Lit sunstones (r 14), the claimed forge (r 18), Vessa (r 8, moves with her), each Fireball impact (r 6, 3 s), each guide's lantern (r 5) |
| The dark | Player sight x 0.7 everywhere (`FogOfWar` sight multiplier). An `ENEMY` unit **outside every light zone** and **farther than 6 m** from a player unit cannot be picked as an **auto**-target by that unit, by towers or by autocast; a direct attack order on a visible one works. Helpers and Sunwardens follow the same rule |
| Sleeping Warden | Dormant Ruin Warden (`balance-1.md`: 300 HP, 16 damage) in a wall alcove: team `NEUTRAL`, invulnerable, ignored by every unit, always shown (a carved figure, eyes dark) |
| Wake with the storm | Vessa within **4 m** for **3 s** with **Old Vey within 8 m of Vessa** (ring white-gold; without Vey the ring stays grey and the message `The Warden sleeps. It answers only the Master's storm: bring Old Vey.` shows once, 4 s). Result: a **Sunwarden**: team `PLAYER`, commandable, pop **0**, the Ruin Warden numbers **+4 damage while within 12 m of Old Vey** (modifier `aura:storm`), white-gold eyes; max **10** alive |
| Wake with the splinter | A **Splinter Acolyte** within 3 m for 3 s (interrupted by any damage >= 20): an **amber Warden**, team `ENEMY`, same numbers, attack-moves with the acolyte's wave |
| Splinter Acolyte | `splinter_acolyte` (new story UnitType: the Hexweaver's numbers, 85 HP, Hexweaver look + an amber lantern; `kill_xp` 60): its only job is to walk to the nearest sleeping Warden of its list and wake it; Fireball bait |
| The forge claim | Vessa within **4 m** of the Warden Forge for **5 s** while **no `ENEMY` unit is within 12 m** (the e2m1 rule: the ring stays grey and `Clear the forge hall first` shows once) |

## Start state (from the campaign save, Vessa's track)
Order in `_on_navigation_ready`: spawn Vessa -> `apply_to_start` -> companion -> Old Vey (granted helper) -> the guides ->
flag branches -> scripted groups.
| Item | Value |
|---|---|
| Vessa | **Level 5 with 4 unspent spell points** (Fireball r1 known), **cap 8** |
| Artifacts / items | From the save: the 3 relics owned, 2 equipped; the 6 slots |
| Essence / crystals | Essence **150** + carried (cap 1 500); crystals **300** (easy 400, hard 200), usable once the forge is claimed |
| Buildings | **None** until the forge (D5) |
| Units | **6 Flame Guards, 4 Ember Archers, 2 Pyre Adepts, 1 Kilnwarden** at `(0, 62)` (1 350 crystals of army); the companion (if saved); **no workers** |
| Old Vey | `helper_vey` at level 5 (Stormcall ready: signature from L5), Escort, at `(2, 66)` |
| Guides | **2 Greywater Trackers** (story: `commandable` false, the `greywater_tracker` numbers, only shoot what attacks Vessa's units) walking 6 m ahead of Vessa; each hall's layout (walls, sleepers, sunstones) is **revealed as explored** when the first guide enters it (`e2m3_lodge_paid`); **+1 guide and +2 sight for the whole army** (the Lodge's deep lanterns) if `e2m3_magpies_hunted` |
| Population | 0 / 0 until the forge: the army costs no pop down here until then; at the claim the forge's +20 applies and the army's pop counts (6 + 4 + 2 + 2 = **14 / 20**, + the companion's 2, + the 4 workers = 20 / 20 → build a Hearth) |
| No save / Ep2 not reached | Crown + Signet equipped, Orb owned; empty slots; essence 150 + **600**; no companion; `e2m3_lodge_paid` **true**, other flags false; `m0_hush_driven` false |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings (after the claim, Hall 2 only) | Hearth (**max 2**), Ember Hall, Ember Spire, **Ember Forge (J)**, **Cinder Sanctum (L)** | Bazaar, Stables, Lair, walls; no keep upgrade (the forge is tier 2 and stays) |
| Units | Warden Forge: Z Cinder Hand, B Kilnwarden. Ember Hall: Z Flame Guard, X Ember Archer, C Blaze Rider, V Ash Hurler, B Pyre Adept, N Cinder Arbalest (the M2 card: cavalry off) | Saboteur (no Citadel), titans |
| Research | Ember Forge tier 1-2: Quenched Blades, Ember Mail, Great Bellows (200 crystals: gold folded), Blasting Powder (200). Cinder Sanctum tier 1-2: **Kindled Blood** (keystone: **Heat**), Flame Rites, White Heat, Ember Rebirth | Tier 3 (`Needs a Citadel`) |
| Helper | Old Vey on the field (D4); revive at the forge after the claim | Call (no Citadel) |
| Spells / items | Fireball, Ember Step, Kindle; cap L8 · base shop at the claimed forge and Ember Hall | Peddlers, caches, champions (the companion reads flags) |

## Tiers and research (`tiers.md` 6, `research.md`)
| Item | Value |
|---|---|
| Code | `MissionE2_04._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = false`, `helpers_enabled = true`, **`research_enabled = true`**, `research_max_tier = 2` (new mission knob read by `ResearchBank.can_research`: tier 3 refuses `"Needs a Citadel"`), `trade_enabled = false`, `cavalry_enabled = false`, `titans_enabled = false`, `tavern_enabled = false`, `camps_enabled = false`, `points_enabled = false`, `beasts_enabled = false`, `river_enabled = false`; `_ready`: `tier_system.max_tier = 2`, `bots_upgrade = false` |
| Warden Forge card | Z Cinder Hand · B Kilnwarden · V **Revive Old Vey** (after a fall) · Set Rally r3c1; no tier button |
| Research hint | At the first Forge or Sanctum completed (10 s): `Research makes every unit better for the whole mission. Select the Ember Forge (or the Cinder Sanctum) and pick an upgrade. Kindled Blood gives your soldiers Heat: they hit harder the longer a fight lasts.` |
| Why Heat matters here | The dark makes fights long and close (6 m auto-target); Heat (+3 % per 2.5 s, cap 3 / 5) rewards holding a lit line instead of chasing into the dark |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_forge` | Primary | `Reach the Warden Forge and light its hearth` | The forge claim completes (E9) |
| `obj_research` | Primary (appears at E9) | `Research one Technology and one Magic (0 / 2)` | One research done at the Ember Forge **and** one at the Cinder Sanctum |
| `obj_gate` | Primary (appears at E9; the gate channel works only after `obj_research`) | `Open the Sunrise Gate: Vessa and Old Vey together (0 %)` | The gate channel reaches 100 % |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `obj_hearth` | Primary (after E9) | `The Warden Forge must stand` | Fails = defeat |
| `sec_wardens` | Secondary | `Wake the Master's Wardens with the storm (0 / 8)` | 8 Sunwardens woken (dead ones still count) |
| `sec_hush` | Secondary (appears at E15) | `Drive off Mother Hush` | Hush reaches 25 % HP and flees |
| `sec_sunstones` | Secondary | `Light every sunstone (0 / 6)` | 6 sunstones lit |
States through `Events.objective_changed(id, state)`: `"active"`, `"done"`, `"failed"`.

## Guards and scripted waves (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
All enemies: team `ENEMY`, group `"scripted"`, auto-aggro, 2x leash for guards. Waves attack-move as listed, refreshed
every 3 s when the order says "then". Amber Wardens woken by a wave join that wave.
| Group | Where | Units | Value (crystals; a Warden counted 150) |
|---|---|---|---|
| G1 Lantern pickets | `(6, 44)`, Hall 1, in the dark | 4 Shades + 2 Nightbolts | 520 |
| G2 forge guard | Ring r 6 around the forge | **2 amber Wardens** (woken before you came) + 3 Shades + 1 Hexweaver | 665 |
| G3 delve camp guard | Ring r 6 around `(16, -54)` | 4 Shades + 2 Nightbolts + 1 Hexweaver + the Night Spire | 645 + spire |
| G4 Ash Seep | `(-33, -10)` | 3 Grave Hounds | 210 |
| Wave | Trigger | Units (spawn: the delve camp) | Order |
|---|---|---|---|
| W1 race | 5:30 | 1 **Splinter Acolyte** + 4 Shades + 2 Grave Hounds (585) | The acolyte walks to the nearest **sleeping** Warden of H2a-H2d / G1n, the others escort it; then attack-move to the forge (claimed or not), then Vessa |
| W2 race | 9:00 | 2 Splinter Acolytes + 4 Shades + 2 Nightbolts + 1 Shadow Knight (1 030) | As W1 (two sleepers at once); then the forge |
| W3 | 12:00 | 5 Shades + 3 Nightbolts + 1 Shadow Knight + 1 Gloom Deacon (1 110) | The forge, then Vessa |
| Hall 3 race | Every **90 s** from 10:30 while a sleeper of H3a-H3d sleeps | 1 Splinter Acolyte + 2 Shades (285) | Wake the nearest H3 sleeper, then hold at the camp |
| **Hush** | Vessa enters Hall 3 (z < -36) the first time | **Mother Hush** at `(0, -60)` | Fights Vessa (D8); flees at 25 % to the north tunnel |
| **W4 "The Splinter's Call"** | The gate channel starts | 0 s: 6 Shades + 3 Nightbolts + 1 Shadow Knight (1 040); 20 s: **4 amber Wardens** burst from the floor in a ring r 12 around the channel spot; 35 s: **Hush returns** at 60 % HP if she was not driven off (if driven: 2 Shadow Knights instead) | Attack-move to Vessa, refreshed every 3 s |
| Withdraw | `obj_gate` done | Every enemy unit | Shadow units walk to the north tunnel and despawn; amber Wardens crumble (their eyes go dark) |
Rules: if the delve camp's three buildings are destroyed, later waves come from the north tunnel `(24, -79)` 15 s later and
the Hall 3 race stops; if `sec_hush` is done before W4, W4's 35 s group is 2 Shadow Knights.

**Mother Hush** (story, `mother_hush`, D8; normal numbers)
| HP | Armor | Attack | Speed | Sight / aggro |
|---|---|---|---|---|
| **1 400** (easy 1 000, hard 1 800) | 10 | 33 melee, range 1.6, cooldown 1.0 | 5.4 | 14 / 12 |
| Ability | Rule |
|---|---|
| Blink Strike | Every 10 s: the hero (Vessa, Vey, the companion) with the lowest HP % within 14 m; violet ring r 1.5 for **0.5 s**, then **55** from behind; out of the ring = miss (the M0 lesson, again) |
| Smoke Cloak | At 70 %: `shroud` 4 s, she withdraws 10 m into the dark (the dark rule hides her), returns |
| Night of Knives | **Once at 50 %**: vanishes 1.5 s, then 6 strikes 0.25 s apart on up to 6 units within 10 m, **40** each (heroes x1.5 + `marked` 4 s) |
| Flees | At 25 %: invulnerable, walks to the north tunnel `(24, -79)`, gone; `sec_hush` done. Never dies here |
Brain: stay in the dark (prefers cells outside light zones), strike Vessa or the weakest hero; `taunted` by Vey's Lunge
for at most 3 s per 8 s.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cinematic `e2m4_descent` (HOLD 0:20); camera on Vessa; L1-L3; `obj_forge`, `obj_vessa`, `sec_wardens`, `sec_sunstones` active; hint `It's dark down here: the enemy hides beyond your light. Light the sunstones (stand Vessa beside one).` (10 s) |
| E2 | First sunstone lit | L4 |
| E3 | Vessa within 10 m of H1a / H1b / H1c (first) | L5-L6; hint `Wake a Warden: Vessa beside it for 3 s, with Old Vey close to her.` (8 s) |
| E4 | First Sunwarden woken | Cinematic `e2m4_first_warden` (PAUSE 0:10): L7 |
| E5 | G1 first seen | L8 (with `m0_hush_driven` true: L8b) |
| E6 | Gallery 1 entered (z < 31) | L9 (Ashby, from the stair: the work crew is coming) |
| E7 | Hall 2 entered | L10-L11 |
| E8 | 5:30 | W1; L12 (Malrik, through the splinter) |
| E9 | Forge claim complete | Cinematic `e2m4_forge` (PAUSE 0:15): L13-L14; the forge turns `PLAYER` (tier 2); 4 Cinder Hands + Captain Ashby (story NPC, invulnerable, stays at the forge) walk down from the stair; `obj_forge` done, `obj_research`, `obj_gate`, `obj_hearth` active; hint `Build an Ember Forge (B then J) and a Cinder Sanctum (B then L) in this hall. Research at both.` (10 s) |
| E10 | First Forge or Sanctum complete | The research hint |
| E11 | First research complete | L15 |
| E12 | An amber Warden wakes (first) | L16 (Obren, through the splinter); L17 |
| E13 | 9:00 / 12:00 | W2 / W3; L18 at W3 |
| E14 | `obj_research` done | L19; the gate's rim cracks brighten (`obj_gate` channel now possible) |
| E15 | Vessa enters Hall 3 | Cinematic `e2m4_hush` (PAUSE 0:10): L20-L21 (L21b if `m0_hush_driven`); `sec_hush` active; Hush fights |
| E16 | Hush at 50 % (Night of Knives) | L22 |
| E17 | Hush flees | L23; `sec_hush` done |
| E18 | Vessa within 4 m of the channel spot with Vey within 8 m, `obj_research` done | The gate channel starts (and resumes on later entries): **45 s** total, **pauses** (never resets) while an `ENEMY` unit stands within 10 m of the spot, while Vey is fallen or farther than 8 m, or while Vessa is farther than 4 m; first start: L24, W4 launches |
| E19 | Gate channel 50 % | L25 |
| E20 | `obj_gate` done | Withdraw; cinematic `e2m4_sunrise` (PAUSE 0:30): L26-L29; `Events.mission_ended(true)` 2 s after it; StoryFlow goes straight to the e2m5 briefing |
| E21 | 8th Sunwarden / 6th sunstone | L30 / L31; `sec_wardens` / `sec_sunstones` done |
| E22 | Vessa dies | L32; defeat after 3 s |
| E23 | The forge destroyed (after E9) | L33; defeat after 3 s |
The intended rhythm: Hall 1 (2 stones, 3 Wardens, G1) by ~4:00; the forge hall fight and the claim at ~5:00-6:30 (W1
racing for the H2 sleepers right after); Forge + Sanctum + 2 researches and a Hall at ~7:00-12:00 while W2 / W3 hit the
forge; Hall 3, Hush, the camp and the H3 race at ~12:00-17:00; the gate (45 s + pauses) at ~16:00-21:00.

## Dialogue (35 entries: L1-L33 + 2 "b" lines; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist; `obren` = alias of `whisper`, shown `Obren`). Colours: Vessa
`(1.0, 0.45, 0.1)`, Old Vey `(0.95, 0.95, 0.55)`, Captain Ashby `(0.95, 0.60, 0.35)`, Mother Hush `(0.60, 0.50, 0.75)`,
Malrik `(0.7, 0.3, 1.0)`, Obren `(1.0, 0.80, 0.25)`, Narrator `(0.9, 0.85, 0.7)`. Names shown: `Vessa`, `Old Vey`,
`Captain Ashby`, `Mother Hush`, `Malrik`, `Obren`, `Narrator`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | The Sunrise Road. The Master cut it before the kingdoms had names. No one has walked it since. |
| L2 | E1 | vessa | It's so dark. Good thing I'm the brightest person I know. |
| L3 | E1 | vey | Stay close to the light, girl. Down here the dark has teeth. |
| L4 | E2 | vey | Sunstones. He set them for the Wardens, so they'd always see him coming home. |
| L5 | E3 | vessa | There's a Warden in the wall. Asleep. Vey, the last ones I met tried to crush me. |
| L6 | E3 | vey | Those were Obren's, woken by Obren. These are the Master's. They know whose storm I carry. |
| L7 | E4 | vey | Up, old friend. Your master's walking again. Well. His sword is. |
| L8 | E5 | vessa | Shades, in the dark. Of course. They never pick a nice, sunny cave. |
| L8b | E5 (`m0_hush_driven`) | vessa | Shades in the dark. I know that smoke. She ran from me once. |
| L9 | E6 | ashby | My queen! Work crew's on the stair. Find us a hearth to build around! |
| L10 | E7 | vessa | A forge. He built forges down here? What was he making? |
| L11 | E7 | vey | Wardens. Doors. Things that hold. He was always better at holding than letting go. |
| L12 | E8 | malrik | Hush. The old man is with her. Wake the stones before he does. |
| L13 | E9 (`e2m4_forge`) | vessa | The hearth's lit. Ashby, it's yours. Make me things that hit harder. |
| L14 | E9 (`e2m4_forge`) | ashby | A Master's forge! My grandad would weep. Then he'd charge you for it. |
| L15 | E11 | ashby | First batch out of the old forge, my queen! Blades that remember the fire. |
| L16 | E12 | obren | Wake, my masons. The Bishop's hand carries my heart. Obey it. |
| L17 | E12 | vessa | That voice again. I'd hoped we buried you. |
| L18 | E13 (W3) | vey | They're throwing everything at the forge. Hold the light, and they break on it. |
| L19 | E14 | vey | Two crafts mastered. Good. The gate won't open for a fool. Or so he told me. |
| L20 | E15 (`e2m4_hush`) | hush | The little ember, in the dark. You're a long way from your braziers. |
| L21 | E15 (`e2m4_hush`) | vessa | Mother Hush. You missed me once. I'd hate for you to get out of practice. |
| L21b | E15 (`m0_hush_driven`) | vessa | Mother Hush. Last time you ran. Want to try running a second time? |
| L22 | E16 | hush | Hush now. The dark only wants to be listened to. |
| L23 | E17 | hush | There is always another night, little ember. Another night. |
| L24 | E18 | vey | Here. Hand on the sun, girl. I'll give it the storm. Hold it with me. |
| L25 | E19 | vessa | It's warm. Vey, the door is WARM. Something's on the other side. |
| L26 | E20 (`e2m4_sunrise`) | narrator | And for the first time in twelve years, the Sunrise Road saw its sunrise. |
| L27 | E20 (`e2m4_sunrise`) | vey | He's down there. I can feel him. And he's tired, girl. So very tired. (6 s) |
| L28 | E20 (`e2m4_sunrise`) | vessa | Then we go faster. Wardens, with me. We're going to fetch the Master. |
| L29 | E20 (`e2m4_sunrise`) | malrik | Go on, then. Run ahead. I'll be right behind you, with the key you lack. |
| L30 | E21 | vey | Eight of his Wardens, awake for you. He'd have liked that. |
| L31 | E21 | vessa | Every stone lit. Okay, the Master had good taste in caves. |
| L32 | E22 | vessa | Vey... the light... it's going out... |
| L33 | E23 | ashby | The forge is lost! The hearth's gone cold! |
Every line <= 2 lines of the dialogue box (<= 96 characters), 5 s (L27 6 s). Echoes: L3 / L6 set e2m5 (the Master's
storm, Obren's Wardens); L11 is the Master's flaw ("better at holding than letting go"), paid off in the ending's "The
harder I held, the more it slipped" (`campaign-outline.md` 4.3); L22 / L23 are Hush's own lines from `cast.json` /
`t3-helpers.md` 10.4; L26 is the road's name explained; L29 keeps Malrik's shard as "the key you lack" for e2m5.

## Cinematic hooks
| id | Kind | When | Content | Owner |
|---|---|---|---|---|
| `c_e2_stair` | stage film 1:30 (e2m3's hook) | Before the briefing | Vey's half-story on the stair | - |
| `e2m4_descent` | ENGINE, **HOLD** 0:20 | E1 | 3 shots: TOP-DOWN down the stair shaft into black, Vessa's glow the only colour (L1); MS Vessa stepping off the last step, her halo lighting the first carvings (L2); MS two-shot Vey and Vessa, the quartz veins brightening around Vey (L3) | four-wizards-high (cine) |
| `e2m4_first_warden` | ENGINE, **PAUSE** 0:10 | E4 | 2 shots: CU the carved face, white-gold light running into the eye sockets; MS the Warden stepping out of its alcove, bowing to Vey (L7) | four-wizards-high |
| `e2m4_forge` | ENGINE, **PAUSE** 0:15 | E9 | 2 shots: LOW, the cold anvil-altar catching fire from Vessa's hand, the chimney glowing (L13); WS the work crew coming down Gallery 1 with Ashby at the front, lanterns swinging (L14) | four-wizards-high |
| `e2m4_hush` | ENGINE, **PAUSE** 0:10 | E15 | 2 shots: WS Hall 3, the gate's light at the far wall, smoke rising off the floor; MS Hush stepping out of the smoke, the amber splinter on a cord at her mask (L20, L21) | four-wizards-high |
| `e2m4_sunrise` | ENGINE, **PAUSE** 0:30 | E20 | 4 shots: CU Vessa's and Vey's hands on the carved sun, lightning running into the stone (L26); WS the gate rolling aside, white-gold light flooding Hall 3 and every amber eye going dark; MS Vey, eyes closed, listening (L27, L28); a last ECU in the dark tunnel north: Malrik's hand around the amber shard (L29) | four-wizards-high |
Fallbacks: each = its lines as dialogue with a 2 s camera pan to the subject (Warden, forge, Hush, gate) and back; the end
states are identical on skip (the Warden standing, the forge claimed and the crew walking, Hush fighting, the Withdraw).

## Win / lose
| Event | Result |
|---|---|
| `obj_gate` done | **Victory** (after `e2m4_sunrise`) |
| Vessa dies | **Defeat** (instant) |
| Warden Forge destroyed after the claim | **Defeat** |
| Old Vey fallen | Not a loss (revive at the forge); the gate channel and the waking pause until he is back |
| Every Sunwarden dead / every soldier dead | Not a loss; Vessa can still finish |
| Hush | Never dies; fleeing is her loss |
| The delve camp destroyed | Allowed; waves come from the north tunnel |

## Reward carried to e2m5
- No new artifact; research is not carried (`research.md` 12); the 6 slots; essence 50 %, cap 1 500, **+300 first if
  `sec_wardens`**, **+150 first if `sec_hush`**, **+150 first if `sec_sunstones`**.
- Companion: the champion rule.
- `CampaignState.MISSION_REWARDS[&"e2m4"] = {"flags": {"e2m4_sunwardens": "sec_wardens", "e2m4_hush_driven": "sec_hush",
  "e2m4_road_lit": "sec_sunstones"}, "bonus_essence": {"sec_wardens": 300, "sec_hush": 150, "sec_sunstones": 150},
  "set_flags": {"e2m4_gate_open": true}, "next": &"e2m5"}`.
- Later hooks (e2m5): `e2m4_sunwardens` = **4 Sunwardens** start beside Vessa; `e2m4_hush_driven` = Mother Hush does **not**
  raid the Fire base in e2m5 (else she leads the 8:00 raid); `e2m4_road_lit` = the 4 sunstones of the Fire / Nature side
  of the Deep Door cavern start lit. Ep3 reads `e2m4_hush_driven` for one Hush line in e3m2 (optional, its writer's call).
- Level not carried.

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6, no Knight in W2 / W3, 2 amber Wardens in W4 | as written | x 1.4, 6 amber Wardens in W4 |
| Start crystals | 400 + 2 extra Flame Guards | 300 | 200, no Pyre Adepts |
| Dark | Sight x 0.85, auto-target range in the dark 8 m | x 0.7, 6 m | x 0.6, 5 m |
| Splinter wake channel | 4 s | 3 s | 2 s |
| Hush | 1 000 HP, no Night of Knives | 1 400 | 1 800, Blink every 8 s |
| Gate channel | 35 s | 45 s | 60 s |
| Expected time | 14-18 min | 17-23 min | 21-27 min |
**Fight sizing (normal, <= 70 % of the army the player can have then; Sunwardens count at 150 each).** Income after the
claim with 4-8 workers ~280-560 crystals / min, but research takes ~450-650 of it.
| Fight | When | Enemy | Player army then | Ratio |
|---|---|---|---|---|
| G1 in the dark | ~2:00 | 520 | 1 350 + Vessa L5 + Vey L5 + 1-3 Sunwardens | 30-38 % (the dark makes it feel bigger: light S2 first) |
| G2 forge guard | ~4:30-6:00 | 665 | ~1 800 with 3 Sunwardens | 37 % |
| W1 | 5:30 | 585 (+ amber Wardens it wakes) | ~1 800-2 000 | 29-37 % |
| W2 | 9:00 | 1 030 (+ up to 300 in Wardens) | ~2 400 | 43-55 % |
| W3 | 12:00 | 1 110 | ~2 700 | 41 % |
| Hush + G3 | ~13:00-16:00 | 645 + Hush (~600 value) + spire | ~3 000 | 41 % |
| W4 | gate channel | 1 040 + 600 Wardens (+ Hush 600 or 520 Knights) | ~3 200 + Vey L6 | 66-70 %: the climax; the channel pauses, so holding the light ring is the answer |
- The intended answers: light before you fight (S1 / S2 before G1, S3 / S4 before W1); wake the H2 sleepers **before**
  5:30 or kill the acolytes first (Fireball one-shots them: 85 HP); Kindled Blood first (Heat for long dark fights), Ember
  Mail for the Flame Guards; Kilnwarden Slag Rain on the Shadow Knight; Ember Step out of Hush's violet ring.
- Small army on purpose: no workers until ~6:00, a 60-pop cap, 4 000 crystals in the whole cave: research or soldiers is a
  real choice, and the Sunwardens are the free army for players who escort Vey to the walls.

## Code reuse (recommendation to the lead)
`MissionBase`; `MissionBrazier` (sunstones, the Warden wake with a "helper within 8 m" condition, the forge claim, the
gate channel with pauses: one class, four uses); `Keep.set_start_tier` on the Warden Forge (a `Keep` subclass with no
upgrade and no rally changes); M0's `mother_hush` brain with the e2m4 numbers; `HelperRoster` with a free mission grant;
the research stack with a `research_max_tier` knob; `FogOfWar`'s sight multiplier. New: the World Forge map and the
`deep_stone` biome; `LightZones` (a tiny registry of circles: stones, forge, Vessa, Fireball impacts, lanterns) read by the
auto-target rule; the `splinter_acolyte` type; the Sunwarden conversion (team swap + `aura:storm`); the guides' reveal.

## Acceptance checks
1. `data/maps/sunrise_road.map` builds (`world_forge build` 0 FAIL); galleries keep their widths on the baked navmesh;
   paths exist to every sleeper, stone, vein, the forge, the camp and the gate; the build grid accepts only Hall 2.
2. A Shade 8 m from a Flame Guard in the dark is not auto-targeted; inside a lit sunstone's r 14 (or within 8 m of Vessa)
   it is; a direct attack order on it works when visible.
3. A sleeper wakes as a `PLAYER` Sunwarden after 3 s with Vessa at 4 m and Vey at 8 m; with Vey at 12 m the ring stays
   grey; a Splinter Acolyte wakes one as `ENEMY` in 3 s and 20 damage interrupts it.
4. The forge claim refuses while a Shade is within 12 m and completes in 5 s once it dies: the forge is `PLAYER`, tier 2,
   +20 pop, drop-off and shop; 4 Cinder Hands arrive; Ember Forge / Cinder Sanctum place in Hall 2 only; tier-3 research
   refuses `Needs a Citadel`.
5. Old Vey kneels (never falls) before the claim; after it, he falls and the forge card shows `Revive Old Vey`.
6. Hush: Blink every 10 s with a 0.5 s ring, Night of Knives once at 50 %, flees invulnerable at 25 %.
7. The gate channel needs `obj_research`, Vessa within 4 m and Vey within 8 m; it pauses (never resets) with an enemy within
   10 m; 45 s of channel open it; skipping every cinematic leaves the same state.
8. Victory saves `MISSION_REWARDS[&"e2m4"]` (3 flags, bonuses, `e2m4_gate_open`); research is not saved.
9. A scripted headless run on normal (light S1 / S2, wake H1, G1, claim, Forge + Sanctum, Kindled Blood + Quenched Blades,
   wake 8, Hush, gate) ends `victory=true` in **17-23 game-minutes**; G1 leaves >= 11 of 13 start soldiers in 5 / 5 runs;
   `PERF OK` with W4, 10 Sunwardens and the light zones.

## Done when (proposed ids; the lead adds them to `waves.md`)
- [ ] E2M4.W1 (four-wizards-high, World Forge): `data/maps/sunrise_road.map` with the halls, galleries, branch, side cave,
  stair, alcoves, stone / vein / forge / camp / gate marks, the Hall 2 build mask; `deep_stone` biome; check 1.
- [ ] E2M4.S1 (systems): `missions/mission_e2_04.tscn` + `MissionE2_04` on that map; the switches of "Tiers and research";
  sunstones, `LightZones`, the forge claim and the Warden Forge building (tier 2, no upgrade, Z / B / V card), the
  sleepers and both wakes, the guides' reveal and the flag branches, start state (L5 + 4 points, cap 8; 300 / 150 +
  carried; pop off until the claim) and the no-save fallback, the `research_max_tier` knob. Test `tests/test_e2m4_s1.gd`:
  checks 3, 4 and 5.
- [ ] E2M4.S2 (systems-high): objectives and events E1-E23 in order, the 35 lines, guards, W1-W4 / the Hall 3 race /
  Withdraw, the camp-destroyed rule, the gate channel with its pause conditions, win / lose, difficulty,
  `MISSION_REWARDS[&"e2m4"]`, `MISSION_SCENES[&"e2m4"]`. Test `tests/test_e2m4_s2.gd`: checks 6-8.
- [ ] E2M4.G1 (gameplay): the dark auto-target rule (reads `LightZones`, `FogOfWar` sight x 0.7), `splinter_acolyte`, the
  Sunwarden conversion with `aura:storm`, `mother_hush` e2m4 numbers (Night of Knives from the `hush_knives` code, once at
  50 %). Test: check 2; Sunwarden +4 damage within 12 m of Vey.
- [ ] E2M4.A1 (ai): Hush's brain (prefer the dark, Blink the lowest-HP % hero, flee at 25 %), the acolyte's walk-and-wake
  brain, the guides' follow-ahead brain; Vey's Escort treats an acolyte channelling within 12 m as a threat (Lunge). Test:
  an acolyte walks to the nearest sleeping Warden and stops channelling when hit for 20.
- [ ] E2M4.U1 (ui): briefing, objectives panel (`0 / 2` research, gate `%` with `(paused)`, `0 / 8` Wardens, `0 / 6`
  stones), the grey / white-gold wake ring and its message, the Warden Forge card, the research hint, the dark: a subtle
  vignette outside light zones; speaker colours for `hush`, `obren`, `ashby`; layout from ui-designer.
- [ ] E2M4.V1 (tech-artist) **[H]**: the `deep_stone` kit (walls, stalagmites, masonry, alcoves with sleeping Warden
  figures, the four-colour carvings, quartz veins driven by Vey's distance), sunstones (dead / lit), the Warden Forge (cold
  / lit), the Sunrise Gate (closed, cracks, rolling open), the delve camp; 0 lights; `PERF OK`.
- [ ] E2M4.V2 (tech-artist): Vessa's halo (emission + decal r 8), the Sunwarden / amber Warden eye looks on the Ruin Warden
  model, the Splinter Acolyte (Hexweaver base + amber lantern), the guides' lanterns; Art Lab sheet at 40 m.
- [ ] E2M4.C1 (four-wizards-high): `e2m4_descent`, `e2m4_first_warden`, `e2m4_forge`, `e2m4_hush`, `e2m4_sunrise`;
  `cine check` 0 FAIL; fallbacks.
- [ ] E2M4.VO (Voice Forge agent): render the 35 lines (`data/voice/lines/e2m4.json`); no new speaker.
- [ ] E2M4.D1 (game-designer): read the lines in game once, trim any line over 2 box lines.
- [ ] Lead: acceptance check 9; a save with no Ep2 progress starts on the fallback.

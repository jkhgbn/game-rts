# Campaign mission e2m2: "Roots and Embers" (Vessa + Ysolde vs Malrik + Torvald)

Task: script for `campaign-outline.md` 3.2 row 2 (the Ep2 outline, "next up" after section 6). Episode 2 "The Light
Below", mission 2 (id `e2m2`, outline D6). Plays right after `c_e2_ashes` "What the Frost Kept" (Ysolde joins Fire,
`mission-e2-01.md` "Cinematic hooks"). The **first 2v2 of the story**: it starts as a 2v1 with an ally who has no
kingdom, and the war becomes a true 2v2 **inside the mission**, when Nature's Heartwood grows back. Target **22-28 min**
on normal. Uses the rules of `mission-01.md` / `mission-e2-01.md` (MissionBase, scripted groups, 70 % rule, difficulty
multipliers), `map-2v2.md` (Fourfold Hollow, seats, sides, section 8 "Story Episode 2 hooks"), `ai-2v2.md` (ally bot,
`AllyChannel` pings, enemy side), `map-fill.md` (capture points, camps), `tiers.md` 6, `t3-helpers.md` (Old Vey, Maelis),
`kingdom-nature.md`, `kingdom-ice.md`, `caster-units.md`, `items.md` campaign rules, `champions.md` 11. New scene
`missions/mission_e2_02.tscn` + script `scripts/campaign/mission_e2_02.gd` (`MissionE2_02 extends MissionBase`, mission id
`e2m2`). Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `y = 0`, `+z` = south. Recommended
option taken everywhere (no open questions).

## 0. Decisions (recommended option taken)
| # | Question | Decision | Why |
|---|---|---|---|
| D1 | Which map | **Fourfold Hollow** (`map-2v2.md` 2, `data/maps/fourfold_hollow.map`, 168 x 168, river on), the player at seat A1 (south-west) | The outline names the 2v2 map; its west bank is "Fire's line" (the Hollowmere is the front) and its A2 quadrant is free land for Nature to regrow on |
| D2 | Seat API | **Requires step 20** (`Teams`, `ALLY` / `ENEMY_2`, `activate_seat`, `AIAlly`, `AllyChannel`). Seats: `PLAYER` A1 Fire, `ALLY` A2 Nature (**scripted, no buildings** until E14), `ENEMY` B1 Shadow (Malrik bot), `ENEMY_2` B2 Ice (Torvald bot). No fallback on 3 teams | `mission-e2-01.md` D1: "e2m2 is the first one on the seat API"; `map-2v2.md` 8 lists exactly this use (`activate_seat` mid-match, a scripted seat that is not "out") |
| D3 | How Nature "joins" | **Inside the mission**: Ysolde starts with a column and no base; three **groves** planted on Fire's side regrow her kingdom; at the third, `activate_seat(ALLY, &"nature", ...)` raises her Heartwood at A2 and her bot starts playing | The outline: "Nature's army regrows around Fire's line; the war becomes 2v2". The player sees it happen and earns it |
| D4 | Who leads the seed-carriers | **Ysolde's column** (seat `ALLY`, scripted): the player sends it with an **ally ping** on a grove site (`defend` or `attack` kind, or the grove card's `Send Ysolde here` button = the same ping). The carriers are not commandable | The first 2v2 mission teaches the one 2v2 skill: pinging the ally (`ai-2v2.md` 5.1). The escort stays readable (one column, one target at a time) |
| D5 | Maelis | **Story unit `maelis_story`** bonded to Ysolde (the `t3-helpers.md` 4.5 kit at Ysolde's level, Escort stance fixed, not callable, never lost: falls, back at Ysolde's side after 45 s). **Not** in a `HelperRoster` | The 2v2 rule is one helper per team (`t3-helpers.md` 3); Old Vey is the team's roster helper (the player's call). Same pattern as `hush_story` in `mission-e3-01.md` D5 |
| D6 | Tier and Old Vey | Fire keep starts as a **Stronghold**; **Citadel** from 5:45 (X, 300, 90 s); **Call Old Vey** (V) at the **Episode 2 price: 300 crystals + 150 essence, 45 s** (e2m1's 250 + 100, 30 s was that mission only; skirmish stays 350 + 200, 60 s). Needs flag `helper_vey_unlocked` (always set by e2m1) | The Citadel was opened in e2m1 (outline D7); every mission still climbs from the Stronghold so the first minutes are spent on the army, not on a free Citadel |
| D7 | Map-fill content | **Capture points on, camps on, beasts off, critters cosmetic, taverns closed (decor), trade off, research off** | The outline: "neutral camps + capture points (map-fill)" are this mission's new systems; one new economy system per mission (trade is e2m3, research e2m4) |
| D8 | Can Ysolde or her seat be lost | Before E14: Ysolde **kneels** at 1 HP for 10 s (untargetable) and stands at 50 %; the scripted seat is never "out". After E14: normal 2v2 wizard respawn; the `ALLY` seat going **out** (`map-2v2.md` 4.4) = **defeat** (`Nature falls a second time`) | No base to respawn at before E14; after it, losing the ally's new kingdom is the story's failure |
| D9 | Wren | Story unit (the `mission-e2-01.md` `wren` type, team `ALLY` now), walks with the column, cannot die (kneel rule), no gameplay role except her lines and a 30 s minimap ping on the next unplanted grove | She rides through the Ep8 ending (outline 4.4 E18) |
| D10 | Mission name and id | `e2m2`, `mission-e2-02.md`, `missions/mission_e2_02.tscn`, `scripts/campaign/mission_e2_02.gd`, `CampaignState.MISSION_SCENES[&"e2m2"]`, in `MISSION_ORDER` after `e2m1` | Outline D6 |

## Story setup (briefing text, 3 short paragraphs)
1. Ysolde walked out of her last Heartwood with a pouch of seed, one warden and a girl who never stops running. Her
   army is ash. Her kingdom is whatever she can plant before winter notices.
2. Fire's border runs along the Hollowmere now, and Torvald has already crossed it: a frost fort on Vessa's own bank,
   squatting on the richest crystal seam she owns, and Malrik's knives in the reeds behind it.
3. Plant three groves along Fire's line and Nature grows back beside it. Then break the frost fort. Two against two,
   at last. Ysolde says it will be slow. Vessa says that is what the fire is for.
Briefing objectives: `obj_groves`, `obj_rimehold`, the rules `Vessa must survive` and `The Emberwatch must stand`, and
the line `Ping a grove site to send Ysolde's column there (the ping key, or the grove's "Send Ysolde here" button).`

## Map: "Fourfold Hollow, west bank" (`data/maps/fourfold_hollow.map`, 168 x 168, 4-way mirrored, river on)
The 2v2 map as built for step 20, dressed for winter: frost on the heath (`max(|x|, |z|) > 68`), thin snow on the north
quadrants, the Hollowmere running dark between white banks. Positions below are A1 / A2 (west bank) unless named; the
map's own tables (`map-2v2.md` 2.4-2.7) hold everything not listed. Clearings: no tree or rock inside the radius.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` / Fire keep "Emberwatch Ford" | hub `(-59, 59)` / keep `(-66, 66)` | 18 (map) | Pre-built, complete, **Stronghold** (3 000 HP) |
| Ember Hall / Ember Spire / Hearths | H1 `(-50, 68)` / S1 `(-60, 52)` / V1 `(-73, 69)`, V2 `(-73, 75)` | map | Pre-built, complete |
| Nodes `node_0_a` / `node_0_b` | `(-69, 57)` / `(-57, 69)` | - | 2 000 each (map numbers) |
| Natural `node_0_mid` | `(-39, 29)` | map | 2 500; hall spot X1 `(-46, 32)` |
| Rich "the Mouth" `node_0_rich` | `(-14, 62)` | map | 2 500; **held by Rimehold** at 0:00 |
| **Grove A "Stumpwood"** | ring centre `(-55, 38)` (the Giant's Stump stays inside as its heart) | **6** | 30 m from the keep. Planted first, by Ysolde on her own (E2) |
| **Grove B "Wayshrine Hollow"** | `(-30, -12)` | **6** | 12 m north of the Wayshrine `(-30, 0)`; ~20 m from the West Crown Steps: the contested one (Malrik) |
| **Grove C "Heartseed"** | `(-59, -59)` (the A2 hub) | **7** | 130 m from the Fire keep by the connector road; planting it is what raises the Heartwood (with A and B standing) |
| Ally seat A2 (Nature, dormant) | keep site `(-66, -66)`, nodes `(-69, -57)` / `(-57, -69)` 2 000 each | map | Empty land until E14 (`map-2v2.md` 8: 3 seats active, the 4th is land) |
| **Rimehold** (Torvald's forward outpost) | Frost Hall `(-22, 56)`; Rime Spires R1 `(-9, 56)`, R2 `(-25, 68)`, R3 `(-17, 47)` | 5 / 3 / 3 / 3 | On Fire's bank, 16 m west of Millstone Bridge `(0, 72)`; 3 Rime Haulers (scripted) mine the Mouth into the Frost Hall. **R3 is not built** if `e2m1_frosthall_shattered` |
| Capture points (map-fill) | Millwatch `(-8, 52)` (watchtower, sight 22, 6 m from R1), Mossmere Well `(-32, 17)`, Wayshrine `(-30, 0)`; their 3 twins on each other quadrant | map | The A1 / A2 ones are the ones the mission talks about |
| Camps (map-fill, `camps_enabled`) | Bristleback Wallow `(-40, 80)` T1, Gloomcap Hollow `(-50, 0)` T2, Stag Glade `(-68, 22)` T3 (seals the Glade Vein), Willow Ford Nest `(0, 40)` and Reed Ford Nest `(0, -40)` (3 Mirefangs each); the B-side twins | map | First spawns as the map's table |
| Taverns | `(-25, 9)` and twins | map | **Closed** (`tavern_enabled` false): boarded-up decor, no window |
| Lost Caches | `(-50, 22)`, `(-39, 0)` and twins | 3 | `items.md` loot, appear at 2:00, reopen 180 s |
| **Malrik** (seat `ENEMY`, B1) | keep `(66, -66)`, Gloom Hall `(50, -68)`, rally `(53, -53)` | map | The 1v1 Shadow base framed by B1's `seat_frame` (identity, origin `(23, -23)`) |
| **Torvald** (seat `ENEMY_2`, B2) | keep `(66, 66)`, Frost Hall `(50, 68)`, rally `(53, 53)` | map | Framed by B2 (`diag(1, 1, -1)`, origin `(23, 23)`) |
| Wave spawns | Shadow: Malrik's Gloom Hall (else his keep, else `(80, -80)`) · Ice: Torvald's Frost Hall (else keep, else `(80, 80)`) · Rimehold relief: Rimehold's Frost Hall | - | - |
Distances (navmesh, approx.): Fire keep -> Grove A 30 m, -> Grove B 85 m, -> Grove C 130 m (connector road), -> Rimehold
Frost Hall 46 m; Torvald's Frost Hall -> Rimehold 75 m (Millstone Bridge); Malrik's Gloom Hall -> Grove B ~100 m (Reed
Ford); Torvald's Frost Hall -> Grove C ~190 m (so Ice hits C late and from the ring road, Shadow hits B early).
Generator check (E2M2.S1): grove rings, Rimehold and the A2 keep site keep their clearings after the 2v2 forest pass; the
three Rimehold spires are >= 6 m from every crossing centre and outside the 1 m water band; paths exist from
`PLAYER_START` to each grove, to Rimehold and to both enemy keeps; every A1 object has its 3 twins (the map's own 20.C5
check still passes with the mission objects excluded).

**Look** (E2M2.V1): late-winter afternoon, low sun from the south-west `(0.95, 0.88, 0.80)` energy 1.05, ambient
`(0.55, 0.57, 0.65)`; frost-white heath, snow on the north quadrants, the meadows round the hubs brown and wet. Groves
before planting: a ring of grey burnt stumps with a dead-seed glyph on the ground (cold green `(0.30, 0.40, 0.28)`);
planted: the ring bursts into young trees, moss and flowers in 1.5 s, the only spring colours on the map
`(0.45, 0.85, 0.35)`. Rimehold: the Frost Hall and spires with icicled palisades and blue rime creeping 8 m over the Mouth.

## The groves (new prop + building, systems; `MissionGrove`)
| Rule | Value |
|---|---|
| Site | Before planting: team `NEUTRAL`, invulnerable, ignored by units, always shown through the fog (like the M2 Heartfrost); a minimap leaf icon; clicking it shows a card `Grove site: Wayshrine Hollow · 2 seed-carriers · 40 s` with the button `Send Ysolde here` (= an `AllyChannel.ping(&"defend", site, PLAYER)`) |
| Planting | **2 seed-carriers** inside the ring channel **40 s** together (progress ring). The channel **pauses** (never resets) while an enemy unit stands within **8 m** of the centre, or while fewer than 2 carriers are inside. On completion the 2 carriers are spent (they "become the grove") |
| Planted grove | Team `ALLY`, a `Building` (`counts_for_defeat` false before E14, true after): **900 HP**, armor 5, radius 4, sight 12, `idle_regen_pct` 1.0; **Sap Ward** aura r 8 (own **and allied** units `idle_regen_pct` +1.0, modifier `aura:sap`, the e2m1 numbers); **Sprouts**: every **60 s** 2 Thornlings for the `ALLY` seat at the grove (max **4 alive per grove**); **Seedbed**: every **90 s** 1 new seed-carrier (max **2 waiting** per grove). Enemy waves target it |
| Destroyed grove | Collapses to its site (burnt stumps again) after 2 s; can be replanted with 2 carriers; its Thornlings stay |
| Messages | Planting started `Ysolde is planting Stumpwood. Keep the enemy out of the grove.` · paused `The planting stops while the enemy stands in the grove` (once per grove, 4 s) · done `Stumpwood is growing again (1 / 3)` |
**Seed-carrier** (`seed_carrier`, new UnitType, gameplay; look = a Sprigling with a big wicker seed-basket and a green
lantern): team `ALLY`, `commandable = false`, **120 HP**, armor 5, speed **4.2**, no attack, pop 0, kill_xp 20. Brain:
follow Ysolde (2-5 m behind her); inside a grove ring she is channelling, the first 2 carriers step in and channel. Under
attack with Ysolde more than 12 m away: walk to the nearest planted grove or the Fire keep (whichever is closer).

## Start state (from the campaign save, Vessa's track: outline D8)
Order in `_on_navigation_ready` (the M2 order): seats (`Teams.configure`) -> spawn Vessa -> `CampaignState.open(...)
.apply_to_start(self)` -> companion -> the ally column and story units -> Rimehold -> the enemy seats' start states.
| Item | Value |
|---|---|
| Vessa | **Level 4 with 3 unspent spell points** (Fireball r1 known), **cap 8** (levels are never carried) |
| Artifacts / items | From the save: Crown, Orb, Signet owned, 2 equipped as chosen on the choice screen; the 6 item slots |
| Essence | **150** + carried (already 50 %, cap 1 500); +1 / s |
| Crystals | **400** (easy 500, hard 300) |
| Buildings | Keep (Stronghold, 3 000 HP), Ember Hall, Ember Spire, 2 Hearths (all complete) |
| Units | 6 Cinder Hands gathering (3 / 3 on the home nodes); **6 Flame Guards, 4 Ember Archers, 2 Blaze Riders, 2 Pyre Adepts, 1 Kilnwarden** at `(-55, 55)` (1 710 crystals of army); the companion beside Vessa (if saved) |
| Population | 6 + 6 + 4 + 4 + 2 + 2 = **24 / 60** (keep 20 + 2 Hearths 40; computed from `UnitType.pop`) + the companion's 2 |
| Ysolde's column (seat `ALLY`, scripted) | At Grove A `(-55, 38)`: **Ysolde level 4** (Thornburst r2, Wild Bloom r1, Call the Thicket r1), **Maelis** (`maelis_story`, L4: 680 HP), **Wren**, **6 seed-carriers** (**+4** if `e2m1_folk_saved`), **4 Thornlings + 2 Bloomtenders** (Ysolde's last wardens, veterancy 2) |
| Old Vey | Not on the field (he scouts the river crossings: L5). Callable at the Citadel (D6) |
| Malrik (seat `ENEMY`) | The 1v1 Shadow start at B1 plus a Gloom Hall and a Night Spire (framed S1), **6 Gloom Thralls** gathering, **6 Shades + 3 Nightbolts** at his rally; **Malrik level 5** (Lance r2, Siphon r2, Shroud r1) |
| Torvald (seat `ENEMY_2`) | The 1v1 Ice start at B2 plus a Frost Hall and a Rime Spire, **6 Rime Haulers**, **4 Rimeshields + 2 Shardcasters** at his rally; **Torvald level 5** (Rime Bolt r2, Flash Freeze r2, Rime Aegis r1) |
| Rimehold | Frost Hall (complete), 3 Rime Spires (2 if `e2m1_frosthall_shattered`), 3 Rime Haulers, garrison G1 (below) |
| No save / Ep2 not reached (menu debug, tests) | Crown + Signet equipped, Orb owned; empty slots; essence 150 + **600**; no companion; `e2m1_*` flags false; `helper_vey_unlocked` **true** |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Hearth, Ember Hall, Ember Spire | Bazaar (e2m3), Forge / Sanctum (e2m4), Stables, Lair, walls |
| Units | Cinder Hand; Ember Hall Z Flame Guard, X Ember Archer, C Blaze Rider, V Ash Hurler, B Pyre Adept, N Cinder Arbalest (the M2 card); keep B Kilnwarden; **from the Citadel**: C Ashveil Saboteur (keep) | Scorchbow, cavalry mounts, titans |
| Keep | **Citadel** (X, 300, 90 s, from 5:45) | - |
| Helper | **Old Vey** (keep V) once the Citadel stands: 300 + 150 essence, 45 s, pop 4 (D6) | - |
| Spells | Fireball, Ember Step, Kindle; cap L8 | - |
| Champions | The companion only (taverns closed) | Hiring, bounty flags on new hires (the companion still reads flags: R works) |
| Map fill | Capture points (watchtowers, wells, the shrine blessing), neutral camps, Lost Caches | Epic beasts, trade posts, Magpies |
| Items | Base shop (keep, Ember Hall; also the **allied** Heartwood and Grove Hall after E14, paid from Vessa's essence: `map-2v2.md` 4.2) | Peddlers (the map's peddlers are closed decor) |

## Tiers and the helper (`tiers.md` 6, `t3-helpers.md` 3)
| Item | Value |
|---|---|
| Code | `MissionE2_02._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = true`, `helpers_enabled = true`, `points_enabled = true`, `camps_enabled = true`, `beasts_enabled = false`, `tavern_enabled = false`, `trade_enabled = false`, `research_enabled = false`, `river_enabled = true`; `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(2)` on the Fire keep (and on both enemy keeps, which never upgrade) |
| Keep card | Z Cinder Hand · X Citadel · C Ashveil Saboteur (greyed `Requires Citadel`) · V Call Old Vey (greyed `Needs a Citadel`) · B Kilnwarden · Set Rally r3c1 (the e2m1 card, no key moves) |
| Messages | The e2m1 Citadel hint (12 s) at 5:45 the first time; the call hint at Citadel complete (10 s) |
| Old Vey | `helper_vey` at Vessa's level, stance Escort, F4 = centre on him; fallen = never a defeat; revive 120 + 20 x level essence |
| Maelis | `maelis_story` (D5); her **Bond** passive works with Ysolde's Thornburst; Wild Stampede from L5 (Ysolde reaches L5 around Grove B) |
| Saboteur here | Max 4. Powder Charge on the Rimehold Frost Hall + spires (x1.5 breaching): 2 charges take a spire to 0 from 720 HP minus a few hits. **Eavesdrop (mission bonus, e2m1 rule)**: a disguised Saboteur within 12 m of Malrik's Gloom Hall, Torvald's Frost Hall or Rimehold announces the next wave from that source 30 s early |

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_groves` | Primary | `Plant Ysolde's groves along Fire's line (1 / 3)` | All 3 groves stand at the same moment (the count shows **standing** groves) -> E14 |
| `obj_rimehold` | Primary | `Break Torvald's forward fort (Rimehold)` | The Rimehold Frost Hall **and** every Rime Spire of Rimehold destroyed (any order, any time) |
| `obj_vice` | Primary (appears when both above are done) | `Hold together against both kingdoms (2:30)` (countdown) | The countdown ends with the Fire keep and the Heartwood standing |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `obj_keep` | Primary, always shown | `The Emberwatch must stand` | Fails = defeat |
| `obj_ally` | Primary (appears at E14) | `Nature must not fall again` | Fails when the `ALLY` seat is out (`map-2v2.md` 4.4) = defeat |
| `sec_carriers` | Secondary | `Lose no more than 2 seed-carriers (0 lost)` | Still within the limit at victory; **failed** at the 3rd carrier death |
| `sec_points` | Secondary | `Hold 3 capture points at once (0 / 3)` | Side 0 owns 3 capture points at the same moment (any 3 of the 10) |
States through `Events.objective_changed(id, state)`: `"active"`, `"done"`, `"failed"`.

## Guards, waves and the bots (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units: team `ENEMY` (Shadow) or `ENEMY_2` (Ice), group `"scripted"`, never controlled by a Commander; guards hold
their spot with auto-aggro and a 2x leash (M1 rules). Waves attack-move as listed, refreshed every 3 s when the order says
"then". `T14` = the moment of E14.
| Group | Where | Units | Value |
|---|---|---|---|
| G1 Rimehold garrison (Ice) | Ring r 6 around `(-18, 58)` | 5 Rimeshields + 3 Shardcasters + 1 Rime Seer + 1 Frost Mortar + 1 **Rimecarver** (caster, autocast on) + the spires (720 HP, chill 2 s each) | 1 265 + spires |
| G2 Reed pickets (Shadow) | `(-14, -22)` between Reed Ford and Grove B | 3 Shades + 2 Nightbolts | 440 |
| G3 Willow scouts (Ice) | `(-12, 36)`, the west end of Willow Ford | 2 Rimeshields + 1 Shardcaster | 300 |
| Rimehold relief | Once, the first time a Rimehold building drops below 60 % | 4 Rimeshields + 2 Shardcasters (600) from Torvald's Frost Hall | Attack-move to Rimehold, then to the nearest Fire unit within 20 m of it |
| Wave | Trigger | Units | Order |
|---|---|---|---|
| W1 Ice probe | 2:30 | 3 Rimeshields + 2 Shardcasters (505), from Rimehold | Attack-move to the grove being planted, else Grove A, else the Ember Hall |
| W2 Shadow | 5:00 | 4 Shades + 2 Nightbolts + 2 Grave Hounds (660) | Attack-move to Ysolde, then the nearest planted grove |
| Raids (Shadow) | Every **150 s** from 6:00 until E14 | 2 Grave Hounds | Attack-move to the nearest **walking** seed-carrier, else the nearest Fire worker |
| W3 Ice | 7:30 | 4 Rimeshields + 2 Shardcasters + 1 Rime Seer (720) + **Torvald** | The nearest planted grove, then Vessa |
| W4 Shadow | 10:00 | 5 Shades + 3 Nightbolts + 1 Shadow Knight + 1 Gloom Deacon (1 110) + **Malrik** | Grove B (planted or being planted), else the nearest grove, then Ysolde |
| W5 Ice | 12:30 | 4 Rimeshields + 2 Shardcasters + 1 Frost Mortar + 1 Rime Colossus (1 080) | Grove C if planting or planted, else the nearest grove, then the Fire keep |
| W6 "Answer" | T14 + 0:45 | Shadow 4 Shades + 2 Nightbolts + 2 Grave Hounds (660) | The new Heartwood at `(-66, -66)` (the enemy tests the new kingdom: the ally's L6 / L1 rules and the player's `help` ping both answer) |
| **The Vice** | `obj_vice` starts | Shadow **Malrik L6** + 6 Shades + 3 Nightbolts + 1 Shadow Knight + 1 Gloom Deacon (1 190) at 0 s; Ice **Torvald L6** + 5 Rimeshields + 3 Shardcasters + 1 Frost Mortar + 1 Rime Colossus (1 285) at 0 s; Shadow 2 Shadow Knights (520) at 1:15 | Shadow: Grove B, then the Heartwood. Ice: the nearest Fire building to Millstone Bridge, then the Fire keep. Refreshed every 3 s |
| Withdraw | `obj_vice` done | Every living scripted unit and both wizards | Walk to their own keep (no fighting unless attacked); despawn there |
Rules: if `obj_rimehold` is done, every later **Ice** wave loses 40 % of its units (rounded down) and W5 / the Vice have no
Rime Colossus (the M1 rule); if `obj_rimehold` is done **before** W5's time, W5 goes to Grove C by the ring road
(Saltgate Bridge) instead of Millstone Bridge. The enemy wizards respawn **60 s** after a death at their own keep
(`Malrik has fallen back into the shadows` / `Torvald has fallen, the frost will bring him back`) and rejoin the current
wave, or walk back to their rally. Before W3 Torvald stays at his rally; before W4 Malrik stays at his.
**Enemy bots** (`ai.md` + `ai-2v2.md` side council, profiles `mission_e2_02_shadow` / `mission_e2_02_ice`): kingdom normal
knobs, `min_attack_pop` **99** (they never launch their own attacks; the scripted waves are their attacks),
`worker_target_home` 6, no expansion, no towers beyond S1, up to **12 soldiers** at their rallies, `bots_upgrade = false`;
the council never sends its own joint attack in this mission. Both Commanders ignore every `"scripted"` unit and building
(Rimehold is not Torvald's base: no rebuild, no defend rule; its relief is the scripted one above).
**Ysolde before E14** (seat `ALLY`, scripted, `AIStoryCaster` for her spells, `kingdom-nature.md` 3.3 rules): leads the
column; answers pings with the `AllyChannel` answer lines (`On my way.` / `Right behind you.`); at the target grove she
holds the ring with her units and casts; a `retreat` ping sends the column to the nearest planted grove. With no ping she
waits at the last grove she planted. Grove Thornlings join her column (max 8 in it; the rest guard their grove).
**Ysolde after E14** (seat `ALLY`, `AIAlly` Commander, profile `mission_e2_02_ally`): Nature normal knobs, personality
**Supportive** (fixed, not random), `worker_target_home` 6, no expansion before 20:00, rally `level.shared_rally(0)`,
the L1-L8 rules of `ai-2v2.md` 5.2; her wizard follows the 2v2 rules (respawn 30 + 15 s per death). The column's units
and the grove Thornlings join her Commander at E14.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cinematic `e2m2_muster` (HOLD 0:18); camera on Vessa; L1-L3; `obj_groves`, `obj_rimehold`, `obj_vessa`, `obj_keep` active; `sec_carriers`, `sec_points` active |
| E2 | 0:20 (after L3) | Ysolde starts planting Grove A on her own; L4-L5; hint `Ysolde plants, you guard. Keep the enemy out of the grove ring.` (8 s) |
| E3 | Grove A planted | Cinematic `e2m2_first_grove` (PAUSE 0:10): L6; then hint `Send Ysolde to the next grove: ping its site, or select it and press "Send Ysolde here".` (10 s); Wren's minimap ping starts (every 30 s on the nearest unplanted site) |
| E4 | First ping on a grove site answered | L7 (Ysolde's answer is the `AllyChannel` line; L7 follows it once) |
| E5 | 2:30 | W1 launches |
| E6 | First capture point captured by side 0 | L8; hint `Capture points: stand in the ring with no enemy inside. Watchtowers see far, wells pay essence, the shrine blesses your army.` (8 s) |
| E7 | 5:00 | W2 launches; L9 |
| E8 | 5:45 (Citadel can start, first time) | The Citadel hint (e2m1 text) |
| E9 | Citadel complete | L10; the call hint |
| E10 | Old Vey arrives | His arrival bark, then L11 (L11b instead if `e2m1_vey_called` is false) |
| E11 | Vessa within 20 m of Rimehold (first time) | L12-L13 |
| E12 | Grove B planting starts | L14 (Malrik, voice) |
| E13 | W3 / W4 / W5 launch | W3: L15 · W4: L16 · W5: L17 |
| E14 | All 3 groves standing (first time) | Cinematic `e2m2_heartwood` (PAUSE 0:25): L18-L20; **`activate_seat(ALLY, &"nature", ...)`**: the Heartwood (Stronghold, 2 700 HP) at `(-66, -66)`, Grove Hall at A2's H1, 2 Seed Hollows, 5 Spriglings on A2's home nodes; the column and grove units join the ally Commander; `obj_groves` done; `obj_ally` active; message `The war is two against two.` (4 s); W6 armed |
| E15 | Rimehold's last building destroyed | L21; `obj_rimehold` done; the 3 Rime Haulers (if alive) walk home; the Mouth's rime decal melts in 3 s |
| E16 | `obj_groves` and `obj_rimehold` both done | 8 s later: L22-L23; `obj_vice` active (2:30 countdown); the Vice launches |
| E17 | The Vice + 1:15 | L24 |
| E18 | Side 0 owns 3 capture points at once (first time) | L25; `sec_points` done |
| E19 | A planted grove destroyed (first time) | L26 |
| E20 | 3rd seed-carrier dies | `sec_carriers` failed; L27 |
| E21 | `obj_vice` done | Withdraw; L28; after 4 s cinematic `e2m2_two_banners` (PAUSE 0:20): L29-L30; `Events.mission_ended(true)` 2 s after it; StoryFlow then plays `c_e2_lodge` |
| E22 | Vessa dies | L31; `obj_vessa` failed; defeat after 3 s |
| E23 | Fire keep destroyed | L32; defeat after 3 s |
| E24 | `ALLY` seat out (after E14) | L33; `obj_ally` failed; defeat after 3 s |
The groves and Rimehold can be done in any order. The intended rhythm: A by ~1:30 (Ysolde alone), then a capture point or
two, B at 5:00-9:00 against W2 / W4, the Citadel and Vey, Rimehold at 9:00-13:00 (with Vey and a Saboteur or two), C at
12:00-17:00 against W5, the Heartwood at ~15:00, the Vice at ~17:00-20:00. A player who rushes Rimehold first frees the
Mouth's 2 500 crystals early and pays for it with an undefended Grove B.

## Dialogue (34 lines; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist; `messenger` = Wren). Colours: Vessa `(1.0, 0.45, 0.1)`, Ysolde
`(0.55, 0.90, 0.35)`, Maelis `(0.60, 0.85, 0.50)`, Wren `(0.80, 0.92, 0.60)`, Old Vey `(0.95, 0.95, 0.55)`, Captain Ashby
`(0.95, 0.60, 0.35)`, Malrik `(0.7, 0.3, 1.0)`, Torvald `(0.55, 0.80, 1.00)`, Narrator `(0.9, 0.85, 0.7)`. Names shown:
`Vessa`, `Ysolde`, `Maelis`, `Wren`, `Old Vey`, `Captain Ashby`, `Malrik`, `Torvald`, `Narrator`. Wren's stumbles are in the
spoken text, the subtitle is the clean reading (the e2o rule).
| Line | Event | Speaker | Text (spoken) | Subtitle if different |
|---|---|---|---|---|
| L1 | E1 | narrator | Nature had no kingdom left, only seed. Fire had a border, and a frost fort sitting on it. | - |
| L2 | E1 | ysolde | Three groves along your line, Vessa. Give me those, and I can give you a kingdom back. | - |
| L3 | E1 | vessa | Three trees? I can do three trees. Torvald brought a whole fort. That one's mine. | - |
| L4 | E2 | ysolde | This one I can do alone. Keep them off me, and do not set it on fire. | - |
| L5 | E2 | vessa | One time. I set ONE tree on fire, one time. | - |
| L6 | E3 | maelis | Stumpwood breathes again. The forest has opinions, and today they are about winter. | - |
| L7 | E4 | ysolde | Point, and I will go. I am done waiting for wars to pass my wood by. | - |
| L8 | E6 | ashby | Watchtower's ours, my queen. We can see clear across the Hollowmere. | - |
| L9 | E7 | malrik | A gardener and a matchstick. Torvald, they are planting trees at us. | - |
| L10 | E9 | vessa | The Citadel's up. Vey, the storm can come any time now. Now would be good. | - |
| L11 | E10 | vey | You called twice in two days. I'll start to think you missed me. | - |
| L11b | E10 (`e2m1_vey_called` false) | vey | First time you've called me in twelve years, girl. I came running. | - |
| L12 | E11 | torvald | This bank is mine until the thaw, child. The thaw is a long way off. | - |
| L13 | E11 | vessa | I AM the thaw, Torvald. I've been told I'm very warm. | - |
| L14 | E12 | malrik | The shrine glade. How fitting. Do pray, Ysolde. Nobody answered last time. | - |
| L15 | E13 (W3) | torvald | I gave the wood one winter. I can give it another. | - |
| L16 | E13 (W4) | ysolde | Malrik. You burned my people. You will not have their seed. | - |
| L17 | E13 (W5) | messenger | Frost, coming from the... from the road. They're going for the Heartseed! | Frost on the road! They're going for the Heartseed! |
| L18 | E14 (`e2m2_heartwood`) | ysolde | Three groves. Enough roots to stand on. Rise. (4 s) | - |
| L19 | E14 (`e2m2_heartwood`) | vessa | Huh. You grow a castle out of a seed. I have to build mine out of rocks. | - |
| L20 | E14 (`e2m2_heartwood`) | ysolde | Then we each keep the other's. Fire and Nature, one front. | - |
| L21 | E15 | vessa | Rimehold's down. Torvald, you left your fort on my bank. I put it back. | - |
| L22 | E16 | narrator | Two kingdoms on one bank, two across the water. The war has its true shape now. | - |
| L23 | E16 | torvald | Now, Bishop. Before her roots take hold. | - |
| L24 | E17 | malrik | Knights, to the shrine glade. Burn whatever grew there twice. | - |
| L25 | E18 | ysolde | Three stones in our hands. The land listens to whoever stands on it. | - |
| L26 | E19 | ysolde | They cut it. Then we plant it again. That is the whole of my strength. | - |
| L27 | E20 | messenger | The carriers... we've lost too many. The seed's running out. | We've lost too many carriers. The seed's running out. |
| L28 | E21 | torvald | Two banners on one bank. Malrik, I begin to see why you feared her. | - |
| L29 | E21 (`e2m2_two_banners`) | ysolde | You came when I called, Vessa. Next time, I come when you do. (6 s) | - |
| L30 | E21 (`e2m2_two_banners`) | vessa | Deal. And next time, I bring marshmallows. Kidding. Mostly. | - |
| L31 | E22 | vessa | Ysolde... keep... planting... | - |
| L32 | E23 | ashby | The Emberwatch is burning! Fall back, fall back! | - |
| L33 | E24 | ysolde | The roots are cut. All of them. I am sorry, Vessa. | - |
Old Vey's and Maelis's own barks (arrival, abilities, low HP, fall, revive) are the `t3-helpers.md` 10.4 hooks
(`helper_vey_<event>`, `helper_maelis_<event>`) in their cast voices. Every line <= 2 lines of the dialogue box (<= 96
characters), fits 5 s at the cast speeds (L29 6 s, L18 4 s). Echoes: L5 answers Ysolde's "do not set it on fire" and her
Ep1 distrust of fire; L13 is Vessa's humour back after e2m1's grief; L26 is Ysolde's "it grows back" (ep1 10, ep4 opening
L10); L28 seeds Torvald's doubt (Ep3 "Torvald watches the stone whisper"); L29 sets up the 2v2 alliance of Ep3-4.

## Cinematic hooks
| id | Kind | When | Content | Owner |
|---|---|---|---|---|
| `c_e2_ashes` | stage film 1:15 (e2m1's hook) | Before the briefing (StoryFlow) | Ysolde joins Fire | - |
| `e2m2_muster` | ENGINE, **HOLD** 0:18 (the game runs, input locked, skippable) | E1 | 3 shots: CRANE over the frosted west bank from the north-west, the Hollowmere dark below, Rimehold's blue rime on the far side of the Fire base (L1); MS Ysolde at the Stumpwood ring with the seed-carriers' green lanterns, Maelis leaning on her staff (L2); WS from behind Vessa looking east to Rimehold's spires (L3) | four-wizards-high (cine) |
| `e2m2_first_grove` | ENGINE, **PAUSE** 0:10 | E3 | 2 shots: LOW angle at the ring as it bursts into young trees, moss and flowers (1.5 s growth); MS Maelis touching the Giant's Stump, a green pulse through the roots (L6) | four-wizards-high |
| `e2m2_heartwood` | ENGINE, **PAUSE** 0:25 | E14 | 4 shots: TOP-DOWN over the A2 hub, three green lines race over the minimap-style ground from the groves to `(-66, -66)` (in-world: root light under the snow); LOW, the Heartwood bursts out of the snow and grows in 3 s, the Grove Hall uncurls beside it (L18); MS two-shot Vessa and Ysolde at the Heartseed ring (L19, L20); WS: Spriglings pour out, Wren on her stag waves the first green banner beside the red one | four-wizards-high |
| `e2m2_two_banners` | ENGINE, **PAUSE** 0:20 | E21 | 3 shots: WS over Millstone Bridge, the Ice and Shadow columns walking away east in snow; MS Vessa and Ysolde side by side at the Wayshrine (L29, L30); CRANE up: the red and green banners on the west bank at sunset, Old Vey (if called) sitting on the shrine step | four-wizards-high |
| `c_e2_lodge` "The Price of the Road" | stage film **1:00** (outline 3.2) | After victory | Beats for its writer: night, the Emberwatch war-room, the three relics on the map table glowing white-gold and all pointing **down** (under Emberfall); Vey: the old Warden roads go down there, but nobody living has walked them; the Greywater Lodge's hunters have, they mapped the deep for a hundred years and sell the map to nobody; Ysolde: "They sell everything to somebody"; Vey: "Gold. Six wagons of it, delivered to their door, past the Magpies and Malrik's knives"; Vessa has never had gold ("We have crystals. Lots of crystals."); Pell's cart rolls in, Pell: "Did somebody say a trade road?" Cut to the salt road at dawn | game-designer (script) + four-wizards-high |
Fallbacks: if the cine tool or a shot is missing, `e2m2_muster` = the camera on Vessa + L1-L3; `e2m2_first_grove` = L6 as
dialogue with a 2 s camera pan to Grove A; `e2m2_heartwood` = the seat activates with the growth VFX at the Heartwood and
L18-L20 as dialogue while the camera pans there (2 s) and back; `e2m2_two_banners` = L29-L30 as dialogue. Every end state
is the same on skip (the Heartwood and buildings exist, the column has joined, the Withdraw has started).

## Win / lose
| Event | Result |
|---|---|
| `obj_vice` done | **Victory** (after `e2m2_two_banners`) |
| Vessa dies | **Defeat** (instant, `instant_loss_on_wizard_death = true`; the 2v2 wizard respawn is off for the player's wizard in missions) |
| Fire keep destroyed | **Defeat** |
| `ALLY` seat out after E14 | **Defeat** |
| A grove destroyed | Not a loss: it can be replanted (but the Vice cannot start while fewer than 3 stand and `obj_groves` is done: then `obj_groves` re-opens until 3 stand again, the countdown pauses `(paused: replant)`) |
| Ysolde at 1 HP before E14 / Wren at 1 HP | Kneels, never a defeat |
| Malrik or Torvald killed | Not a win: the 60 s respawn text |
| Every building of one enemy seat destroyed | That seat crumbles (`map-2v2.md` 4.4); its later waves spawn at its map corner from scripted spawns; no win (the mission ends on the Vice) |
| All Fire soldiers dead, Vessa and the keep alive | Nothing; Vessa can still finish |

## Reward carried to e2m3
- No new artifact (the 3 relics stay).
- The 6 item slots at victory; essence 50 %, cap 1 500, **+300 first if `sec_carriers`**, **+150 first if `sec_points`**.
- Companion: the champion rule (`champions.md` 11); no new hire was possible, so the same companion (if any) is offered.
- `CampaignState.MISSION_REWARDS[&"e2m2"] = {"flags": {"e2m2_carriers_kept": "sec_carriers", "e2m2_points_held":
  "sec_points"}, "bonus_essence": {"sec_carriers": 300, "sec_points": 150}, "set_flags": {"ep2_nature_allied": true},
  "next": &"e2m3"}` (`set_flags` as `mission-04.md` added it).
- Later hooks: `e2m2_carriers_kept` = in **e2m5** Ysolde's bot starts with **+1 Bramblehorn and +2 Bloomtenders** ("the
  groves remember"); `e2m2_points_held` = in **e2m3** the Millwatch habit: Ashby's line L4 there and **+1 Ember Spire**
  pre-built on the west road; `ep2_nature_allied` = every later Ep2 mission and the Ep4 opening may reference the alliance.
- Level not carried.

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6, no Colossus or Frost Mortar in waves, no Knight in W4 | as written | x 1.4 |
| Start crystals | 500 + 2 extra Flame Guards | 400 | 300, no Pyre Adepts |
| Planting time | 30 s | 40 s | 50 s |
| Seed-carriers at start | 8 (+4) | 6 (+4) | 6 (+4), Seedbed every 120 s |
| The Vice | 2:00 | 2:30 | **3:15**, + Shadow 4 Shades + 2 Nightbolts at 2:30 |
| Wizards | Malrik L4 / Torvald L4 (the Vice: L5) | L5 (Vice L6) | L6 (Vice L7) |
| Old Vey call | 250 + 100, 45 s | 300 + 150, 45 s | 350 + 200, 60 s (the skirmish price) |
| Grove HP | 1 100 | 900 | 750 |
| Expected time | 18-22 min | 22-28 min | 26-32 min |
**Fight sizing (normal, every guarded fight and wave <= 70 % of the army the player can have then; Ysolde's column and
the ally's army are on top, not counted).** Income with 6-9 workers ~300-400 crystals / min.
| Fight | When | Enemy units | Player army then (crystals) | Ratio |
|---|---|---|---|---|
| W1 | 2:30 | 505 | 1 710 + Vessa L4 + companion | 30 % |
| G2 Reed pickets | ~5:00 | 440 | ~2 200 | 20 % |
| W2 | 5:00 | 660 | ~2 200 | 30 % |
| G1 Rimehold + spires | ~9:00-13:00 | 1 265 + 3 spires (~1 000 crystals of tower value) + relief 600 | ~2 900 + Vey | 70 % at the peak (relief arriving): the skill check |
| W4 | 10:00 | 1 110 + Malrik L5 | ~2 900 | 38 % |
| W5 | 12:30 | 1 080 (~650 if Rimehold fell) | ~3 100 | 35 % |
| The Vice | ~17:00-20:00 | 2 475 + 520 + both wizards L6 | ~3 400 + Vey L6 + the ally's ~1 500 | 63 % of the player's army alone; ~61 % with the Knights; the ally's help (pings) is what makes it comfortable |
- The intended answers: Rimehold = Kilnwarden Slag Rain on the Rimeshields, Blaze Riders on the Shardcasters, Saboteur
  charges on R1 / R3, fight it from the south-west so R2 alone covers you; W4 = Kindle on the line, Fireball the
  Nightbolts, Mana Scald on the Deacon; the Vice = send the ally to Grove B with a `help` ping while Vessa holds Millstone
  Bridge (or the reverse): the first mission where splitting with the ally is the answer.
- Capture points pay for the detours: the Millwatch watches Rimehold and Willow Ford (sight 22), Mossmere Well pays
  essence for Vey's call, the Wayshrine's blessing lands on whoever holds Grove B.
- The groves pull the army apart on purpose (B 85 m, C 130 m), but the column defends itself against raids (4-8
  Thornlings, Maelis): the escort is a readable second front, never a second mission.

## Code reuse (recommendation to the lead)
Prerequisites: `MissionBase` (M9.S1), step 20's seat API (`Teams`, `activate_seat`, `seat_frame`, `AIAlly`,
`AllyChannel`), the e2m1 pieces (`wren`, `AIStoryCaster`, `Keep.set_start_tier`, `t3_enabled`, the `HelperType`
mission-price override). Reused: `_spawn_group` / `_scaled` / `_mark_scripted` / `_tick_guards` / `_order_wave` /
`_refresh_waves`, `MissionBrazier` (the planting channel with the `is_blocked()` hook, 2-carrier variant), the e2m1 Sap
Ward aura, `hush_story`'s story-helper pattern for `maelis_story`, the map-fill services as the skirmish builds them on
Fourfold Hollow. New: `MissionGrove` (site + planted building + Sprouts / Seedbed), the `seed_carrier` UnitType and its
10-line follow brain, Ysolde's scripted column brain (pings in, answers out), the `Send Ysolde here` card button.

## Acceptance checks
1. `missions/mission_e2_02.tscn` loads headless with 4 seats (`ALLY` scripted with no building and not "out"); grove rings,
   Rimehold and the A2 keep site keep their clearings; paths exist from `PLAYER_START` to each grove, Rimehold and both
   enemy keeps; with `e2m1_frosthall_shattered` Rimehold has 2 spires.
2. Ysolde plants Grove A on her own from 0:20; a planting with 2 carriers completes in 40 s; a Shade at 7 m pauses it and
   it resumes (not resets) when the Shade dies; with 1 carrier inside it pauses.
3. A `defend` ping on Grove B's site (or the card button) is answered within 2 s and the column walks there; a `retreat`
   ping sends it to the nearest planted grove.
4. A planted grove spawns 2 Thornlings for `ALLY` every 60 s (max 4 alive) and 1 carrier every 90 s (max 2 waiting);
   destroyed, it returns to a site and can be replanted.
5. With A, B and C standing, E14 runs once: the `ALLY` seat has a Heartwood at `(-66, -66)`, a Grove Hall, 2 Seed Hollows
   and 5 Spriglings; the `AIAlly` Commander answers a `help` ping on the Fire keep within its reaction delay; skipping
   `e2m2_heartwood` leaves the same state.
6. The Vice starts only when both primaries are done; the countdown pauses while fewer than 3 groves stand; it ends in
   victory after 2:30 (normal) with the keep and the Heartwood alive.
7. Defeat on Vessa's death, the Fire keep's fall, and the `ALLY` seat going out after E14; Ysolde kneels (never dies)
   before E14.
8. Victory saves `MISSION_REWARDS[&"e2m2"]` with the flags, the +300 / +150 bonuses and `ep2_nature_allied`.
9. A scripted headless run on normal (guard A, capture the Millwatch, plant B, Citadel, Vey, Rimehold, plant C, the Vice)
   ends `victory=true` in **22-28 game-minutes**; W1 leaves >= 13 of the 15 start soldiers alive in 5 / 5 runs; a run
   with no Citadel and no Vey still wins on normal in 3 / 5; `PERF OK` during the Vice with 4 seats' armies on the field.

## Done when (proposed ids; the lead adds them to `waves.md`; after step 20)
- [ ] E2M2.S1 (systems): `missions/mission_e2_02.tscn` + `MissionE2_02` on Fourfold Hollow with 4 seats (A2 scripted, no
  buildings), the winter dressing hooks, the pre-built Fire base at tier 2, Rimehold (Frost Hall, 2-3 spires, haulers,
  G1), the 3 grove sites, map-fill on (points, camps; beasts, taverns, trade, research off), start state via
  `apply_to_start` (L4 + 3 points, cap 8; 400 / 150 + carried; 24 / 60; companion) and the no-save fallback;
  `MissionGrove` (site card + button, 2-carrier planting with the pause rule, planted building, Sprouts, Seedbed, replant);
  section "Tiers and the helper". Test `tests/test_e2m2_s1.gd`: checks 1, 2 and 4.
- [ ] E2M2.S2 (systems-high): objectives and events E1-E24 in order, the 34 lines, guards, waves W1-W6 / Raids / relief /
  the Vice / Withdraw, the -40 % Ice rule after `obj_rimehold`, the W5 reroute, wizard levels and 60 s respawns, the E14
  `activate_seat` with its start state and the column hand-over, the win / lose table (incl. the replant pause), the
  difficulty table, `MISSION_REWARDS[&"e2m2"]`, `MISSION_SCENES[&"e2m2"]`. Test `tests/test_e2m2_s2.gd`: checks 5-8.
- [ ] E2M2.G1 (gameplay): UnitType `seed_carrier` (120 HP, armor 5, speed 4.2, `commandable` false, pop 0) and its follow
  / plant brain hooks; `maelis_story` (the `t3-helpers.md` 4.5 kit at Ysolde's level, Escort fixed, 45 s return, outside
  any roster); `wren` usable on the `ALLY` team. Test: a carrier follows Ysolde 2-5 m behind; Maelis's level follows
  Ysolde's; neither is commandable.
- [ ] E2M2.A1 (ai): Ysolde's scripted column brain (ping in, `AllyChannel.answer` out, hold the ring, cast with
  `AIStoryCaster`, `retreat` rule); profiles `mission_e2_02_shadow`, `mission_e2_02_ice` (`min_attack_pop` 99, workers 6,
  max 12, council attacks off, ignore `"scripted"` units and buildings) and `mission_e2_02_ally` (Supportive fixed);
  the column hand-over to the ally Commander at E14. Test: a `defend` ping on a site is answered within 2 s; after E14 a
  Shade attacking the Fire keep draws the ally's army (L1); the enemy Commanders never order a Rimehold unit.
- [ ] E2M2.U1 (ui): briefing (3 paragraphs, 2 primaries, the ping line), objectives panel (`1 / 3` standing groves, the
  Vice countdown with `(paused: replant)`, `0 lost` carriers, `0 / 3` points), the grove card and its button, grove
  planting rings on the minimap, Wren's ping, speaker colours / names for `ysolde`, `maelis`, `messenger`, `torvald`;
  layout from ui-designer.
- [ ] E2M2.V1 (tech-artist) **[H]**: winter dressing of Fourfold Hollow (frost heath, snow north, dark river), grove site
  and the 1.5 s growth burst (young trees, moss, flowers, 0 lights), Rimehold (icicled palisade, rime decal over the
  Mouth), the Heartwood growth burst from snow; `PERF OK` during the Vice.
- [ ] E2M2.V2 (tech-artist): the `seed_carrier` (Sprigling base, wicker seed-basket, green lantern emission), Maelis's
  story look on her helper model (TH.V3) or a stand-in; Art Lab contact sheet at 40 m.
- [ ] E2M2.C1 (four-wizards-high): `e2m2_muster`, `e2m2_first_grove`, `e2m2_heartwood`, `e2m2_two_banners` as cine
  timelines on the mission scene, `cine check` 0 FAIL; the fallbacks above.
- [ ] E2M2.VO (Voice Forge agent): render the 34 lines (`data/voice/lines/e2m2.json`); every WAV fits its slot; no new
  speaker.
- [ ] E2M2.D1 (game-designer): read the 34 lines in game once and trim any line over 2 box lines; write the `c_e2_lodge`
  script from the beats above (1:00, `episode2-opening.md` format).
- [ ] Lead: acceptance check 9 (headless runs on normal and the no-Vey run); a save with no Ep2 progress starts on the
  fallback.

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Ashveil Saboteur.
- **Why here:** the Rimehold fort (Frost Hall + 3 Rime Spires) on your own bank; Powder Charge pauses training 10 s; strong against production buildings.
- **Moment:** before the Rimehold assault: "A Saboteur looks like a Rime Hauler. Walk it past the spires and charge the Frost Hall.".
- **Intro card:** `Ashveil Saboteur. Looks like their worker, works for you: blow the hall, stop the army before it's born.`

## Built (2026-10-06)
`missions/mission_e2_02.tscn` + `scripts/campaign/mission_e2_02.gd` (`MissionE2_02`), `GroveSite` / `MissionGrove`,
tests `tests/test_e2m2.gd` (checks 1-8) and `tests/test_e2m2_sim.gd` (check 9, slow list). Runs on the real seat API
(`scripts/core/teams.gd`, `MissionConfig.seat_sides`, `MissionBase.activate_seat`, `AllyChannel`). Deviations:
- Map: the 120 m Crown Hollow terrain with one base per corner (Fire SW, Nature NW, Shadow NE, Ice SE), no river;
  every spec position scaled into the quadrants (grove A `(-44, 14)`, B `(-12, -12)`, C `(-33, -33)`, Rimehold hall
  `(-8, 49)`, 8 capture points, 8 camps). Fourfold Hollow needs MissionBase on a LayoutLevel (not built).
- "Send Ysolde here": a 3-button panel (top right, until E14) and Alt+click on a site (AllyChannel's first input cut);
  the ally after E14 is a Commander that never attacks plus the mission's L1 (intruder at a Fire building) / L2 (help
  ping) answers, not the full `AIAlly`.
- `obj_groves` stays done once done; a destroyed grove pauses the Vice `(paused: replant)` until 3 stand again.
- Old Vey's L11 / L11b and the Saboteur moment hint are said at E10 / E9; no cine timelines (fallback end states).
- Scripted run (normal, 2026-10-06): victory at 20:12 mission time (21:25 with the cutscene lengths) against 22-28;
  W1 left 11 of 15 start soldiers (spec >= 13).
- 2026-10-07: the scripted player keeps out of Rimehold's spire reach before the assault (W1's losses were the spires) and
  follows the spec's rhythm (Rimehold from 9:00, Grove C from 14:00): W1 leaves 13-15 of 15, 0-1 carriers lost (3 runs);
  victory 15:00 / 15:01 (16:13 with cutscenes, old rhythm) and 17:31 (18:44, spec rhythm, Vey not called that run):
  still under 22-28 (the Vice is 2:30 and the Heartwood lands ~14:50).

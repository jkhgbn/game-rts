# Campaign mission e2m5: "The Light Below" (Vessa + Ysolde vs Malrik + Torvald, and the Doorwarden)

Task: script for `campaign-outline.md` 3.2 row 5 (the Ep2 outline, "next up" after section 6). Episode 2 "The Light
Below", mission 5 (id `e2m5`, outline D6): **the Episode 2 finale and its boss**. Plays right after `e2m4` (StoryFlow goes
straight from `e2m4_sunrise` to this briefing). A 2v2 in the Master's cavern: a race for the **four seals** of the Deep
Door, then the boss **the Doorwarden**, Obren's jailer-statue woken by Malrik's shard, which tries to break the door the
Master holds from below. **The door must hold.** Target **25-31 min** on normal, its own cutscenes included. Uses the rules
of `mission-01.md` / `mission-e2-01.md` / `mission-e2-02.md` (MissionBase, 2v2 seats, ally pings, 70 % rule, difficulty
multipliers), `mission-04.md` and `story-episode-1.md` 6 (the boss pattern: phases, telegraphs, the boss bar, Turn the
Key), `mission-e2-04.md` (sunstones, the storm rule), `cavalry-mounts.md` 2 / 5 and `titans-2.md` 6 (the Fire titan
options), `t3-helpers.md`, `items.md`, `champions.md` 11. New map `data/maps/deep_door.map`, scene
`missions/mission_e2_05.tscn` + script `scripts/campaign/mission_e2_05.gd` (`MissionE2_05 extends MissionBase`, mission id
`e2m5`). Metres, seconds, `m:ss` since the navmesh was ready (`mission_time()`, held cinematic time excluded); positions
`(x, z)`, `+z` = south. Recommended option taken everywhere (no open questions).

## 0. Decisions (recommended option taken)
| # | Question | Decision | Why |
|---|---|---|---|
| D1 | The map | A **new 2v2 cavern** `data/maps/deep_door.map`, **150 x 150**, `symmetry=mirror_z` (side 0 south, side 1 north), World Forge map mode, `deep_stone` biome (e2m4). The **Rift**, a bottomless chasm, splits it at `z = 0`; it is crossed by the **Door dais** in the centre and two **Rift Bridges** | The 2v2 needs four bases; a mirrored cavern keeps the race for the door fair; the chasm turns the dais into the one place everyone must fight over |
| D2 | Seats | **Requires step 20** (as e2m2). `PLAYER` A1 south-west Fire, `ALLY` A2 south-east Nature (Ysolde's `AIAlly`, Supportive), `ENEMY` B1 north-west Shadow (Malrik), `ENEMY_2` B2 north-east Ice (Torvald). Fire faces Shadow on the west, Nature faces Ice on the east | The war's true 2v2 shape (e2m2), each player with one lane opponent (`map-2v2.md` fairness idea) |
| D3 | "3-way race to the door" | Three forces at the door: the two alliances, and **the Warden host** of the dais (Obren's Ruin Wardens, team `NEUTRAL`, the M4 rule). The race is for the **four seals** around the Deep Door: Vessa **kindles** them with the relics, Malrik **cracks** them with the shard | The M4 3-way pattern, readable: four stones, two colours |
| D4 | What the Doorwarden wants | To **break the Deep Door** (the Master holds it shut from below; behind it is the deep where Obren's power waits). It is team `ENEMY` (the shard binds it to Malrik's seat), scripted, `"boss"` group. **The Door is the objective**: a `PLAYER`-side target with its own HP | The outline: "the door must hold". Keeps the Master alive below for Ep8 and gives the player something to protect that is not a keep |
| D5 | Old Vey | On the field from 0:00, the player's **helper** (granted free as e2m4 D4; he came down the Sunrise Road with Vessa), fallen = revive at the keep (Ep2 essence price). His storm is needed for the **Sunlance** in boss phase 3 (the e2m4 rule: Vessa at the Door with Vey within 8 m) | e2m4's lesson becomes the boss's key; pays "the spark first, then the storm" once more before Ep8 |
| D6 | Tier and the titan | Fire keep **starts as a Citadel** (the finale: no climb). `cavalry_enabled` and **`titans_enabled` true**: Ember Stables, then the **Dragon Roost** (Lair, 300, 70 s, from **8:00**) with the **Cinder Dragon** (Z, 700, pop 6, 85 s) and the **Ember Crucible** (X, the `titans-2.md` 6.3 rule: 300 crystals, 75 s, a free Flame Guard every 40 s, max 6 alive) | The outline gives the Fire titan as this mission's reward unit; `titans-2.md` makes Fire's second option the Crucible, so the Roost offers both (the Dragon is the story's reward, the Crucible is the choice) |
| D7 | Story helpers of the other wizards | **Maelis** (`maelis_story`, Ysolde's, e2m2 D5) and **Aldra Stillwater** (`aldra_story`, Torvald's: the `t3-helpers.md` 4.4 kit at Torvald's level, Escort fixed, back after 45 s when fallen). No roster helpers for the bots | `t3-helpers.md` 1: Aldra "Episode 2 at Torvald's side"; the finale shows every helper the story has so far (Hush raids if `e2m4_hush_driven` is false) |
| D8 | The wake moment | Phase 1 ends when the **Wake meter** reaches 100 % (seals drive it), **never before 9:00**, at the latest **16:00** (Malrik drives the shard into the statue) | The race must matter (kindled seals slow the wake and weaken the boss) but the finale must arrive |
| D9 | Can the player lose the door | **Yes**: Door HP 0 = defeat. One safety valve: at 50 % Door HP (first time) the Master answers (**Hold**: the Door heals 1 000) | The stake is real; the valve is the "darkest hour" of M4 in a smaller form |
| D10 | Mission name and id | `e2m5`, `mission-e2-05.md`, `data/maps/deep_door.map`, `missions/mission_e2_05.tscn`, `scripts/campaign/mission_e2_05.gd`, `CampaignState.MISSION_SCENES[&"e2m5"]`, after `e2m4`; `next` = the episode end | Outline D6 |

## Story setup (briefing text, 3 short paragraphs)
1. At the bottom of the Sunrise Road the world opens into a cavern so big it has its own weather: warm wind rising
   from a chasm, and in the middle, set in the floor, a round white door that glows like a sunrise.
2. The Master is on the other side, holding it shut. Four old seals ring the door; the relics can wake them. Malrik came
   down his own stair with Torvald, and the stone in his hand wants that door open.
3. Ysolde's army came down behind Vessa. Two kingdoms on each side of the chasm, and between them, standing over the
   door like a jailer, a statue as tall as a tower. Its eyes are closed. For now.
Briefing objectives: `obj_seals`, `obj_door`, `obj_vessa`, `obj_keep`, and the line `Kindle the seals around the Door
with Vessa. Each seal Malrik cracks brings the jailer closer to waking.`

## Map: "The Deep Door" (`data/maps/deep_door.map`, 150 x 150, mirror_z)
South half (side 0) listed; the north half is the z-mirror (`(x, -z)`) unless named. Cave walls and the Rift are navmesh
obstacles. Build areas: each base plateau (r 26 around its keep) and the natural expansions.
| Thing | Position | Size / r | Notes |
|---|---|---|---|
| **Fire base "Sunfoot"** (`PLAYER`) | keep `(-52, 56)`, hub `(-45, 49)` | plateau r 26 | Pre-built **Citadel** (3 500 HP), Ember Hall `(-36, 60)`, Ember Spire `(-44, 38)`, 2 Hearths `(-62, 62)`, `(-62, 68)`; nodes `(-56, 46)` / `(-44, 62)` 2 000 each; the stair from e2m4 arrives at `(-60, 72)` |
| Fire natural | node `(-30, 34)` 2 500, hall spot `(-36, 30)` | 7 | 30 m from the keep |
| **Nature base** (`ALLY`) | keep `(52, 56)`, hub `(45, 49)` | plateau r 26 | Heartwood (**Stronghold**, 2 700), Grove Hall `(36, 60)`, Bramble Spire `(44, 38)`, 2 Seed Hollows; nodes `(56, 46)` / `(44, 62)`; natural `(30, 34)` |
| **Shadow base** (`ENEMY`) | keep `(-52, -56)` | mirror | Dusk Keep (Stronghold), Gloom Hall `(-36, -60)`, Night Spire `(-44, -38)`, 2 Hovels |
| **Ice base** (`ENEMY_2`) | keep `(52, -56)` | mirror | Rime Keep (Stronghold), Frost Hall `(36, -60)`, Rime Spire `(44, -38)`, 2 Snow Lodges |
| **The Rift** | chasm along `z = 0`, half width 5, from `x = -75` to `-16` and `16` to `75` | - | Impassable; ranged units and spells reach across (10 m); flyers cross |
| **West / East Rift Bridge** | `(-45, 0)` / `(45, 0)` | 8 wide, 12 long | Each front's crossing (Fire - Shadow, Nature - Ice) |
| **The Door dais** | centre `(0, 0)`, r **16** | - | Joins both halves; raised 1 m, ramps at N / S / E / W |
| **The Deep Door** | `(0, 0)`, r 5 (in the floor) | - | Team `PLAYER` side target (`DeepDoor`, D4): **6 000 HP** (+500 per seal kindled at the wake, max 8 000), armor 30, regen **5 / s** while not hit for 5 s, untargetable before the wake, always visible |
| **Seals** | N `(0, -11)`, E `(11, 0)`, S `(0, 11)`, W `(-11, 0)` | channel r 3 | Grey (dormant), white-gold (kindled, side 0), amber (cracked, side 1) |
| **The Doorwarden** (asleep) | statue at `(0, -24)`, facing the Door | radius 3.5, height 16 | Decor until the wake; on the north ramp's foot (Malrik's side: he gets there first) |
| Warden alcoves | `(-14, -14)`, `(14, -14)`, `(-14, 14)`, `(14, 14)` (dais rim) | - | Respawn points of the Warden host |
| Sunstones (south) | `(-28, 20)`, `(-12, 30)`, `(12, 30)`, `(28, 20)` | r 14 when lit | e2m4's rule (Vessa 3 s); **start lit** if `e2m4_road_lit`; north twins are amber "splinter-lamps" (Malrik's, decor) |
| Side caves | "Ember Seep" `(-70, 20)` node 1 500; "Root Seep" `(70, 20)` node 1 500; north twins | 6 | Contested late nodes on each own half |
| Wave spawns | each seat's Hall (else keep, else its plateau's back wall); Shadow raiders also from the north-west tunnel `(-74, -40)` | - | - |
Distances (navmesh, approx.): Fire keep -> Door dais rim 62 m; -> West Rift Bridge 57 m; Shadow keep -> dais 62 m (fair);
Fire keep -> Shadow keep 115 m by the bridge, 125 m over the dais. Map check (E2M5.W1): z-mirror twins exact; the dais
ramps and both bridges keep 8 m of walkable width; paths from every keep to every seal; the Doorwarden's path from
`(0, -24)` to the Door rim is clear.

**Look** (E2M5.V1): the `deep_stone` cavern, lit from below: the Door's white-gold glow `(1.0, 0.93, 0.70)` is the main
light (emission + a strong ground decal r 30 and god-ray cards rising from the Door; 0 lights), the Rift breathes a faint
warm haze; the south half's sunstones white-gold, the north half's splinter-lamps amber; the dais ringed with the Master's
four-colour carvings, brighter than e2m4's. The Doorwarden: a 16 m jailer-statue of dark grey granite with amber seams, a
great stone key-ring at its belt, a hammer-fist; asleep its eyes are blank; awake they burn amber.

## Mechanics
### The seals and the Wake meter (phase 1)
| Rule | Value |
|---|---|
| Kindle (side 0) | **Vessa** (or **Ysolde**, the ally bot's wizard, on a mission order) within **3 m** for **4 s**; the seal turns white-gold. Allowed on a grey or an amber seal |
| Crack (side 1) | **Malrik** within 3 m for 4 s (only the shard-bearer); the seal turns amber. Allowed on a grey or a white-gold seal |
| Block | The channel pauses (never resets) while a unit of the other side stands within **6 m** of the seal; any damage >= 30 to the channeller resets it |
| Wake meter | `wake` 0-100 %, objectives panel line `The Doorwarden stirs: 37 %`. Rate per second: **0.10** base **+ 0.10 per amber seal - 0.05 per white-gold seal** (min 0.05). Messages at 50 % `The statue's eyes are warm.` and 80 % L14 |
| Wake | At 100 % and `mission_time() >= 9:00`, or at **16:00** whatever the meter says (E14) |
| Effect at the wake | Each **white-gold** seal: the Door gains **+500 max HP and HP**; each **amber** seal: the Doorwarden takes **x 0.85** damage (multiplicative) while that seal stays amber. Seals keep flipping during phase 2 (the channel rules stay) |
Expected on normal: Malrik cracks N at ~3:30 and W at ~6:00 unless stopped, the player kindles S and E by ~5:00, the
tug-of-war continues; **the wake lands at 12:00-15:00**.

### The Warden host (phase 1, `NEUTRAL`, the 3-way)
6 Ruin Wardens (`balance-1.md`: 300 HP, 16 damage) on the dais at r 8, leash 12 around `(0, 0)`, aggro 9: they attack
anyone on the dais. Every **40 s** one alcove (in turn) adds 2, max 6 alive. At the wake every living Warden turns
**`ENEMY`** (the Doorwarden calls them; eyes from grey to amber).

### The Doorwarden (boss, team `ENEMY`, scripted; groups `"units"`, `"boss"`, titan tags)
**15 000 HP** (easy 11 000, hard 19 000), armor **25**, speed 1.4, radius 3.5, height 16, sight 22, CC immune (titan: half
duration, taunt / knockback immune), no kill XP, x 0.85 damage taken per amber seal. Boss bar `The Doorwarden` with marks
100 / 70 / 35. Every attack has a ground telegraph (red-amber fill, the 19.V3 look).
| Phase | HP | What it does |
|---|---|---|
| B1 "The Jailer Walks" | 100-70 % | Walks from `(0, -24)` to the Door's north rim `(0, -7)` (it stays within 7 m of the Door from then on, pushing nothing). **Door Slam** every **6 s** while within 7 m of the Door: **120** to the Door (1.0 s wind-up, the fist rises; units under the fist r 3 take 60). **Stonehurl** every 10 s at the biggest side-0 clump within 25 m (1.6 s telegraph r 3.5, **70**, Vessa's clump wins ties). **Warden Call** every 30 s: 2 Ruin Wardens at the nearest alcove |
| B2 "Shard-fed" | 70-35 % | **Malrik's tether**: while Malrik is alive and within **20 m** of the Doorwarden, a violet-amber beam joins them: the boss takes **x 0.5** damage and heals **20 HP / s**. Malrik stands at `(0, -28)` with his army (bot override). Break it: kill Malrik (respawn 60 s), or drive him out of 20 m (he retreats under 35 % HP). Door Slam every **5 s**. **Quake** every 14 s when 4+ side-0 units are within 8 m: ring r 8, 1.2 s, **55** + `dazed` 1.0 s (heroes 0.5) |
| B3 "The Light Below" | 35-0 % | The Door answers. **Sunlance**: every **15 s**, if **Vessa is within 6 m of the Door with Old Vey within 8 m of her** (the e2m4 rule), a white-gold beam rises from the Door into the Doorwarden: **300** damage and **Exposed 8 s** (x 1.5 damage taken; the amber seams crack open). Without Vey: no lance (message once `The Door answers only the storm`). Door Slam every 5 s, Stonehurl every 8 s, Warden Call 3 every 20 s (never inside Vey's Stormcall area for 6 s) |
| Fall | 0 | Cinematic `e2m5_fall` |
Door maths (normal): ~6 min of Door Slams at ~22 DPS = ~7 900, minus regen and the Hold (~2 500) = **~5 400 lost** of 6 000-8 000:
a player who kindled 2+ seals and breaks the tether quickly ends with the Door at 30-60 %; one who never kindles and lets
the tether run loses the Door. **Hold** (D9): at 50 % Door HP the first time, L24 and the Door heals **1 000**.
Phase-3 maths: ~5 250 HP left; army ~180 DPS x 0.8 (armor) = ~145, x 1.5 Exposed half the time + 300 per lance = **~2:00**.

## Start state (from the campaign save, Vessa's track)
Order in `_on_navigation_ready`: seats (`Teams.configure` with 4 seats) -> spawn Vessa -> `apply_to_start` -> companion ->
Old Vey (granted) -> flag branches -> the three bot seats' start states (+ Maelis, Aldra) -> the Warden host -> seals.
| Item | Value |
|---|---|
| Vessa | **Level 5 with 4 unspent spell points** (Fireball r1 known), **cap 8** |
| Artifacts / items | The 3 relics owned, 2 equipped (choice screen); the 6 slots |
| Essence / crystals | Essence **150** + carried (cap 1 500); crystals **500** (easy 600, hard 400) |
| Buildings | Keep (**Citadel**, 3 500 HP), Ember Hall, Ember Spire, 2 Hearths |
| Units | 6 Cinder Hands gathering (3 / 3); **8 Flame Guards, 4 Ember Archers, 2 Pyre Adepts, 2 Cinder Arbalests, 1 Kilnwarden, 1 Ashveil Saboteur** at `(-40, 44)` (2 000 crystals of army); the companion (if saved); **4 Sunwardens** if `e2m4_sunwardens` (pop 0, the e2m4 numbers) |
| Old Vey | `helper_vey` level 5, Escort, beside Vessa |
| Population | 6 + 8 + 4 + 2 + 2 + 2 + 2 = **26 / 60** (+ companion 2, + Vey 4 = 32) |
| Ysolde (`ALLY`) | **Level 5** (Thornburst r2, Wild Bloom r2, Call the Thicket r1); Heartwood (Stronghold), Grove Hall, Bramble Spire, 2 Seed Hollows, 6 Spriglings; **6 Thornlings + 3 Burr Slingers + 2 Bloomtenders + 1 Bramblehorn** (**+1 Bramblehorn, +2 Bloomtenders** if `e2m2_carriers_kept`); **Maelis** L5; Wren (story, at the Heartwood) |
| Malrik (`ENEMY`) | **Level 6** (Lance r3, Siphon r2, Shroud r1), the shard; Dusk Keep (Stronghold), Gloom Hall, Night Spire, 2 Hovels, 6 Gloom Thralls; **8 Shades + 3 Nightbolts + 2 Shadow Knights + 1 Gloom Deacon** at `(-40, -44)`; crystals 400. If `e2m3_malrik_robbed`: **no Knights, crystals 100** |
| Torvald (`ENEMY_2`) | **Level 6** (Rime Bolt r3, Flash Freeze r2, Rime Aegis r1); Rime Keep (Stronghold), Frost Hall, Rime Spire, 2 Snow Lodges, 6 Rime Haulers; **6 Rimeshields + 3 Shardcasters + 1 Frost Mortar + 1 Rimecarver** at `(40, -44)`; **Aldra** L6 |
| Neutral | The Warden host (6) on the dais; seals grey; the Doorwarden asleep |
| No save / Ep2 not reached | Crown + Signet equipped, Orb owned; empty slots; essence 150 + **800**; no companion; all `e2m*` flags false |

## Unlocks (what exists in this mission)
| Kind | Available | Locked |
|---|---|---|
| Buildings | Hearth, Ember Hall, Ember Spire, **Ember Stables** (B then N), **Dragon Roost** (B then M; needs Stables, from 8:00) | Bazaar, research buildings (research is off: e2m4's lesson stays there), walls |
| Units | Keep Z Cinder Hand, C Ashveil Saboteur, B Kilnwarden; Ember Hall the cavalry card (Z Flame Guard, X Ember Archer, C Ash Hurler, B Pyre Adept, N Cinder Arbalest); Stables Z Blaze Rider; **Roost Z Cinder Dragon** (700, pop 6, 85 s), **Roost X Ember Crucible** (300, 75 s) | Scorchbow |
| Mount | Ember Boar (Stables X, 150 crystals) | Barding stays (C, level 5) |
| Helper | Old Vey on the field; `Revive Old Vey` on the keep (V) | - |
| Spells / items | Fireball, Ember Step, Kindle; cap L8 · base shop (keep, Ember Hall, the allied Heartwood / Grove Hall) | Peddlers, champions (the companion reads flags), camps, points, trade |

## Tiers and switches
`MissionE2_05._init`: `tiers_enabled = true`, `casters_enabled = true`, `t3_enabled = true`, `helpers_enabled = true`,
`cavalry_enabled = true`, **`titans_enabled = true`**, `research_enabled = false`, `trade_enabled = false`,
`tavern_enabled = false`, `camps_enabled = false`, `points_enabled = false`, `beasts_enabled = false`,
`river_enabled = false`; `_ready`: `tier_system.max_tier = 3`, `bots_upgrade = false`, `Keep.set_start_tier(3)` on the Fire
keep (no announcement), `set_start_tier(2)` on the three bot keeps. The Roost's 8:00 floor (`BuildingType.min_time` 480)
applies as in the skirmish. Message once at 8:00: `The Dragon Roost can be built: Stables first, then B then M. A Cinder
Dragon breathes fire on the jailer's Wardens and flies over the Rift.` (12 s).

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_seals` | Primary (phase 1) | `Kindle the Door's seals (1 / 4 white-gold · 1 amber)` | Marked **done** at the wake (whatever the count; the count is the reward) |
| `obj_door` | Primary, from the wake | `The Deep Door must hold` (Door HP bar) | Fails at Door HP 0 = defeat |
| `obj_doorwarden` | Primary, from the wake | `Stop the Doorwarden` (boss bar, marks 100 / 70 / 35) | Doorwarden HP 0 |
| `obj_tether` | Primary hint (B2 only) | `Break Malrik's tether: kill him or drive him off` | B2 ends |
| `obj_lance` | Primary hint (B3 only) | `Stand Vessa by the Door with Old Vey: the Door will strike` | B3 ends |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `obj_keep` | Primary, always shown | `Sunfoot must stand` | Fails = defeat |
| `sec_seals` | Secondary | `All four seals white-gold when the jailer wakes` | 4 white-gold at E14 |
| `sec_door` | Secondary (appears at E14) | `Keep the Door above half its light` | Door HP never below 50 % (the Hold does not count as failing it if it is the first dip: **failed** at the first dip below 50 %, the Hold still fires) |
| `sec_dragon` | Secondary (appears at 8:00) | `Raise a Cinder Dragon` | A Cinder Dragon trained by the player |
States through `Events.objective_changed(id, state)`. The ally `ALLY` seat going out is **not** a defeat here (Ysolde's base
is on the far side of her plateau; if it falls her army keeps the Door with Vessa: the 2v2 crumble rule is replaced by
"her units stay and follow the Door order"), but it is announced (L31).

## Guards, waves and the bots (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Scripted units: group `"scripted"`, never controlled by a Commander. `W` = the wake (E14).
| Wave / order | Trigger | Units | Order |
|---|---|---|---|
| Malrik's seal runs | 3:00, then whenever he is alive, above 60 % HP and a seal is not amber | **Malrik** + 4 Shades (320, scripted escort; renewed if dead at the next run) | Walk to the nearest non-amber seal (N, W, E, S order on ties), crack it, then the next; back to his rally under 35 % HP |
| Torvald's cover | 5:00 and 9:00 | Torvald's bot army (scripted override for 90 s) + **Torvald** + Aldra | Attack-move to the dais north ramp, hold it 90 s, then back |
| W1 Shadow raid | 4:00 | 4 Shades + 2 Grave Hounds (460) from the Gloom Hall via the West Rift Bridge | Attack-move to the Fire workers, then the Ember Hall |
| W2 Ice push | 7:00 | 5 Rimeshields + 2 Shardcasters + 1 Rime Seer (815) via the East Rift Bridge | Attack-move to the Nature base (the ally bot defends; the player may answer a `need_help` ping) |
| Hush's raid | 8:00, only if `e2m4_hush_driven` is false | **Mother Hush** (the e2m4 kit, 1 400 HP, flees at 25 %) + 3 Shades from the north-west tunnel | Attack-move to the Fire workers, then Vessa |
| W3 joint push | 11:00 | Shadow 5 Shades + 2 Nightbolts + 1 Shadow Knight (860) via the West Bridge **and** Ice 4 Rimeshields + 2 Shardcasters + 1 Frost Mortar (790) via the dais | Shadow: the Ember Hall, then the keep; Ice: the south seals (to stop kindling), then the Fire keep |
| Wake push | W + 0:20 | Shadow 6 Shades + 3 Nightbolts + 1 Shadow Knight (1 040) | The Door dais south ramp, then Vessa |
| Ice pressure | W + 1:30 and every 120 s until B3 | 4 Rimeshields + 2 Shardcasters + 1 Rime Colossus (890) | The Nature base, then the Door dais east ramp |
| Malrik's guard (B2) | B2 starts | Malrik's bot army + 4 Shades + 1 Gloom Deacon (scripted) | Stand with Malrik at `(0, -28)`; defend him |
| Torvald's withdrawal | B3 starts | Torvald, Aldra and every Ice unit | Walk home, defend only (`min_attack_pop` 99), L28-L29 |
| Withdraw | Doorwarden falls | Every Shadow unit and Malrik | Walk to the north-west tunnel `(-74, -40)` and despawn (Malrik leaves with the shard) |
If `e2m3_malrik_robbed` is true, W3's Shadow part has no Knight and the wake push has 1 Knight fewer (none). Malrik and
Torvald respawn 60 s after a death at their keep (`Malrik has fallen back into the shadows` / `Torvald has fallen, the
frost will bring him back`); Aldra and Maelis return after 45 s.
**Enemy bots** (`ai-2v2.md` side council, profiles `mission_e2_05_shadow` / `mission_e2_05_ice`): kingdom normal knobs,
`min_attack_pop` 99 (the scripted waves are their attacks), workers 7, one expansion each (their side cave) from 10:00, up
to 14 soldiers at their rallies, `bots_upgrade = false`, no Stables / Lairs; they ignore `"scripted"` and `"boss"` units.
**Ysolde** (`AIAlly`, profile `mission_e2_05_ally`, Supportive fixed): Nature normal knobs, workers 7, the east side cave
at 10:00, up to 16 army pop; L1-L8 rules; **mission orders on top**: at 2:30 she kindles the **E** seal (then guards it
while her army holds the east ramp); at the wake her army moves to the Door's **south-east** rim and holds it (the Door
order), answering pings as usual; Maelis with her. Her wizard respawns by the 2v2 rule (30 + 15 s per death).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Cinematic `e2m5_cavern` (HOLD 0:24); camera on Vessa; L1-L4; `obj_seals`, `obj_vessa`, `obj_keep`, `sec_seals` active; hint `Kindle a seal: Vessa beside it for 4 s. Malrik can crack them back. Ping Ysolde to help hold them.` (10 s) |
| E2 | First seal kindled by side 0 | L5 |
| E3 | First seal cracked by Malrik | L6-L7 |
| E4 | 2:30 | Ysolde heads for the E seal; L8 (her `AllyChannel` line) |
| E5 | 4:00 / 7:00 | W1 / W2; L9 at W2 (Ysolde's `need_help` ping if her base is hit) |
| E6 | 5:00 | Torvald's first cover; L10-L11 |
| E7 | 8:00 | Roost message; `sec_dragon` active; Hush's raid if `e2m4_hush_driven` false (L12) else L12b |
| E8 | First Cinder Dragon trained | L13; `sec_dragon` done |
| E9 | Wake meter 80 % | L14 |
| E10 | 11:00 | W3; L15 |
| E11 | A Warden-host fight on the dais, Vessa within 10 m (first) | L16 (Vey) |
| E12 | Vessa within 6 m of the Door (first time, before the wake) | L17 (the Master, very faint: `master` speaker, subtitle in italics) |
| E13 | Malrik killed (first) | L18 |
| E14 | **The wake** (100 % after 9:00, or 16:00) | Cinematic `e2m5_wake` (PAUSE 0:30): L19-L21; seal effects applied; the host turns `ENEMY`; `obj_seals` done; `obj_door`, `obj_doorwarden` active (`sec_seals` done or failed; `sec_door` active); the Doorwarden phase B1; wake push at +0:20 |
| E15 | Doorwarden at 70 % (B2) | L22-L23; `obj_tether` shown; Malrik's guard order |
| E16 | Door at 50 % (first) | **Hold**: the Door heals 1 000, white-gold flash; L24 |
| E17 | Tether broken the first time (Malrik dead or > 20 m) | L25 |
| E18 | Doorwarden at 35 % (B3) | Cinematic `e2m5_answer` (PAUSE 0:12): L26-L27; `obj_tether` hidden, `obj_lance` shown; Torvald's withdrawal: L28-L29 |
| E19 | First Sunlance | L30 |
| E20 | `ALLY` seat out (any time) | L31 (no defeat, see Objectives) |
| E21 | Doorwarden HP 0 | Every scripted Ice unit already home; the Warden host crumbles; Withdraw (Shadow); cinematic `e2m5_fall` (PAUSE 0:20): L32-L33; `Events.mission_ended(true)` 2 s after it; StoryFlow: `ep2_ending` "All Four, or None", then the Story menu (Episode 2 complete) |
| E22 | Vessa dies | L34; defeat after 3 s |
| E23 | The Door's HP 0 | Cinematic `e2m5_breach` (PAUSE 0:06: amber light pours up through the cracked Door, the Doorwarden roars) then defeat |
| E24 | Fire keep destroyed | L35; defeat after 3 s |

## Phases at a glance (normal; expected times include the cutscenes)
| Phase | From - to | Expected | What the player does |
|---|---|---|---|
| Arrival | `e2m5_cavern` | 0:24 | - |
| 1 "The Race" | 0:00 - the wake | 12:00-15:00 | Kindle S / W, hold them with pings and the army, fight the Warden host, answer W1-W3, build Stables and a Roost (8:00), a Dragon by ~11:00-13:00 |
| The wake | `e2m5_wake` | 0:30 | - |
| B1 "The Jailer Walks" | wake - 70 % | 2:00-3:00 | Burst the boss while the wake push hits the south ramp; keep seals white-gold |
| B2 "Shard-fed" | 70 - 35 % | 3:00-4:00 | Break Malrik's tether (Dragon + Blaze Riders on him), then burst |
| B3 "The Light Below" | 35 - 0 % | 2:00-3:00 | Vessa at the Door with Vey: ~4-6 Sunlances, Exposed bursts |
| Fall | `e2m5_fall` | 0:20 | - |
| **Total** | | **~25-30 min** (a fast player ~23, the cap ~32) | |

## Dialogue (38 entries: L1-L35 + 3 "b" lines; 5 s each unless listed)
Speaker ids from `data/voice/cast.json` (all exist; `master` = the Master; `obren` = alias of `whisper`). Colours: Vessa
`(1.0, 0.45, 0.1)`, Old Vey `(0.95, 0.95, 0.55)`, Ysolde `(0.55, 0.90, 0.35)`, Maelis `(0.60, 0.85, 0.50)`, Malrik
`(0.7, 0.3, 1.0)`, Torvald `(0.55, 0.80, 1.00)`, Aldra `(0.62, 0.95, 0.88)`, Mother Hush `(0.60, 0.50, 0.75)`, Obren
`(1.0, 0.80, 0.25)`, the Master `(0.95, 0.93, 0.85)`, Wren `(0.80, 0.92, 0.60)`, Narrator `(0.9, 0.85, 0.7)`. Names shown:
`Vessa`, `Old Vey`, `Ysolde`, `Maelis`, `Malrik`, `Torvald`, `Aldra`, `Mother Hush`, `Obren`, `The Master`, `Wren`,
`Narrator`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Under the roots of the world, a door. And on the other side of it, the one who made it. |
| L2 | E1 | vessa | That's it. That's the door. Vey, he's right there. Under my feet. |
| L3 | E1 | vey | Four seals. Wake them with the relics and the door stands. Let Malrik break them and it falls. |
| L4 | E1 | malrik | Good evening, Vessa. Mind the statue. It's been waiting a hundred years to stretch its legs. |
| L5 | E2 | vessa | One seal! See, Vey? I can be patient. For four seconds at a time. |
| L6 | E3 | malrik | Crack. Do you hear it, Vessa? That is the sound of a lock giving up. |
| L7 | E3 | vey | Kindle it again, girl. The relics are stronger than his pebble. If you hold them. |
| L8 | E4 | ysolde | The east seal is mine. Hold the west, Vessa. We have done this before. |
| L9 | E5 | ysolde | Torvald is on my bridge with half of winter. I could use some fire. |
| L10 | E6 | torvald | I will hold the north stair, Bishop. Do what you came to do, and quickly. |
| L11 | E6 | aldra | Rime on the ramp, Torvald. They will not climb it twice. |
| L12 | E7 | hush | Did you miss me, little ember? I missed you. Twice now. |
| L12b | E7 (`e2m4_hush_driven`) | vey | No knives at our backs tonight. Hush is still licking her wounds. Good. |
| L13 | E8 | vessa | A dragon! An actual dragon! Vey, I have a DRAGON. |
| L13b | E8 (continues) | vey | So you do. Point it at the big statue, and try not to name it. |
| L14 | E9 | obren | Wake, my jailer. The door was always mine to open. |
| L15 | E10 | malrik | Torvald, now. Both bridges. Let them choose which kingdom to lose. |
| L16 | E11 | vey | Obren's Wardens. They guarded this door before he turned. Now they guard nothing. |
| L17 | E12 | master | ...Vessa? (3 s, whispered) |
| L17b | E12 (continues) | vessa | Master?! Master, I'm here! I'm right here! |
| L18 | E13 | malrik | Dying in the dark. Twice in one war. I am starting to keep count. |
| L19 | E14 (`e2m5_wake`) | narrator | A hundred years the jailer stood over the door. Tonight Malrik's stone told it to open it. |
| L20 | E14 (`e2m5_wake`) | malrik | Open it, Mason. Let me see what the Master was so busy guarding. (6 s) |
| L21 | E14 (`e2m5_wake`) | vessa | Everyone on the door! Nobody touches it but us! |
| L22 | E15 | malrik | Feed, old stone. Take what you need from me. I have plenty. |
| L23 | E15 | vey | He's holding it up with the shard! Cut the line, girl! Get to Malrik! |
| L24 | E16 | master | Hold. (3 s) |
| L25 | E17 | ysolde | The line is cut! Now, before he crawls back! |
| L26 | E18 (`e2m5_answer`) | vey | Feel that? He's pushing back from below. The spark first, Vessa. Then the storm. |
| L27 | E18 (`e2m5_answer`) | vessa | Then let's give him something to push with. Door! Light! NOW! |
| L28 | E18 | torvald | This is not what you promised, Bishop. You said a door. Not a jailer. |
| L29 | E18 | aldra | Winter goes home, Torvald. Let the Bishop dig his own grave. |
| L30 | E19 | vessa | It answered! The Door hit it! He's helping us! |
| L31 | E20 | messenger | The Heartwood's... it's down! But we're still here! We're still with you! |
| L32 | E21 (`e2m5_fall`) | malrik | Keep your door, Vessa. I have the key, and all the time in the world. (6 s) |
| L33 | E21 (`e2m5_fall`) | ysolde | It held. Vessa. It held. |
| L34 | E22 | vessa | Master... I was... so close... |
| L35 | E24 | vey | Sunfoot's burning! Back to the stair, girl, now! |
Every line <= 2 lines of the dialogue box (<= 96 characters), 5 s at the cast speeds unless listed. Wren's L31 subtitle:
`The Heartwood's down! But we're still with you!`. Echoes: L3 sets the seal rule; L7 "If you hold them" is the Master's
flaw in Vey's mouth (e2m4 L11); L13b is Vey's dry humour paying off "Sir Crackle"; L17 is the first time the player hears
the Master in the game (the prologue voice), whispering her name; L24 "Hold." is the Master's whole philosophy in one word,
which the ending will undo ("So I will not hold it again", `campaign-outline.md` 4.3); L26 is the motto's last use before
Ep8; L28-L29 plant Torvald's turn (Ep3 "Torvald's doubt", Ep7 "No. Not for now."); L32 keeps the shard (Ep3).

## Cinematic hooks
| id | Kind | When | Content | Owner |
|---|---|---|---|---|
| `e2m5_cavern` | ENGINE, **HOLD** 0:24 | E1 | 4 shots: CRANE down from the stair mouth into the cavern, warm wind, the Door's god-rays (L1); MS Vessa at the stair foot, light on her face (L2); WS the dais: four grey seals, the Warden host standing still, the huge jailer-statue over the Door (L3); across the Rift, MS Malrik on his own stair with Torvald behind him, the amber shard glowing in his fist (L4) | four-wizards-high (cine) |
| `e2m5_wake` | ENGINE, **PAUSE** 0:30 | E14 | 4 shots: MS Malrik at the statue's foot, pressing the shard to its ankle; amber light racing up its seams (L19, L20); ECU its eyes opening, amber; LOW the statue's first step cracking the dais, the Wardens' eyes turning from grey to amber; MS Vessa raising the Crown, the seals she holds blazing white-gold (L21) | four-wizards-high |
| `e2m5_answer` | ENGINE, **PAUSE** 0:12 | E18 | 2 shots: CU the Door's surface, cracks of white-gold light pushing back the amber (L26); MS Vessa and Vey at the rim, his blade blazing, her hands raised (L27) | four-wizards-high |
| `e2m5_fall` | ENGINE, **PAUSE** 0:20 | E21 | 3 shots: WS the Doorwarden kneeling, a last Sunlance splitting it from the Door upward, the statue falling apart into the Rift in a slow cascade; MS Malrik at the north ramp, the shard dim, turning away into the dark (L32); MS Ysolde catching Vessa's arm at the Door (L33) | four-wizards-high |
| `e2m5_breach` | ENGINE, **PAUSE** 0:06 | E23 | 1 shot: the Door cracks, amber light floods up, the statue roars; cut to black (defeat) | four-wizards-high |
| `ep2_ending` "All Four, or None" | ENGINE stage film **1:30** (outline 3.2) | After victory | Beats and draft lines for its writer (`episode2-opening.md` format, set: the `deep_door` cavern as a World Forge stage `forge_deep_door`): **0:00-0:25** silence after the fall; Vessa kneels and puts both hands on the Door; it is warm. Vessa: "Master. Open it. Please." **0:25-0:55** the Door's light rises into a figure's outline that never resolves (the beard of light only, `campaign-outline.md` 4.4 E08 look); the Master, tired, kind: "My joy. You came all this way." / "I cannot open it. If I let go, what is under me comes up." / "It takes four hands to turn this lock." / Vessa: "Then tell me how!" / Master: "**All four of you, or none.**" The light sinks back. **0:55-1:15** Vey, quietly: "Especially Malrik. He always said that." Ysolde looks across the Rift: the north stair is empty; Torvald's banner is gone too, but a single blue rime-lantern has been left burning at the top of his stair (his doubt, unspoken). **1:15-1:30** both alliances climbing toward daylight; the narrator over a CRANE out of the stair mouth into spring: "The door held. The war went looking for open ground, and found the last green country: Evenmead." Title: `Episode 2 · The Light Below · The End`. Then the Ep3 card | game-designer (script) + four-wizards-high |
Fallbacks: `e2m5_cavern` = the camera on Vessa + L1-L4; `e2m5_wake` = the wake state applied + L19-L21 as dialogue with a
2 s pan to the statue; `e2m5_answer` = L26-L27 as dialogue; `e2m5_fall` = the statue crumble VFX + L32-L33; `e2m5_breach` =
the defeat screen. Every end state is identical on skip (seal effects, host turned, phase set, withdrawals ordered).

## Win / lose
| Event | Result |
|---|---|
| Doorwarden destroyed | **Victory** -> `e2m5_fall` -> `ep2_ending` -> Episode 2 complete |
| Vessa dies | **Defeat** (instant) |
| The Deep Door's HP 0 | **Defeat** (`e2m5_breach`) |
| Fire keep destroyed | **Defeat** |
| `ALLY` seat out | Not a defeat in this mission (L31); her units follow the Door order |
| Old Vey fallen | Not a loss; no Sunlance until he is revived (keep V, essence) |
| Malrik / Torvald killed | Not a win: 60 s respawn (Malrik's death in B2 breaks the tether) |
| An enemy seat's buildings all destroyed | That seat crumbles; its scripted waves spawn from its plateau's back wall; the boss phases continue |

## Reward and the Episode 2 carry-over
- No new artifact (the 3 relics stay with Vessa; Ep8's opening hands them back). The 6 slots, essence 50 %, cap 1 500,
  **+300 first if `sec_seals`**, **+300 first if `sec_door`**, **+150 first if `sec_dragon`**, the companion (champion
  rule): all saved on **Vessa's track** (outline D8) for Episode 8's Fire road (Ep3-4 do not play Vessa; Ep5 is the past).
- **Fire titan unlocked** for Vessa's track: `set_flags["fire_titans_unlocked"] = true` (any later Fire mission may set
  `titans_enabled`; Ep4's Vessa ally bot may field a Cinder Dragon; the Theatre's unit gallery shows it).
- `CampaignState.MISSION_REWARDS[&"e2m5"] = {"flags": {"e2m5_seals_kindled": "sec_seals", "e2m5_door_bright": "sec_door",
  "e2m5_dragon_raised": "sec_dragon"}, "bonus_essence": {"sec_seals": 300, "sec_door": 300, "sec_dragon": 150},
  "set_flags": {"ep2_complete": true, "ep2_door_held": true, "fire_titans_unlocked": true, "ep2_torvald_doubts": true},
  "next": &"ep2_ending"}` (StoryFlow plays `ep2_ending` then marks the episode complete; Story menu card 3 unlocks).
- Later hooks: `e2m5_door_bright` = in **e8m3** the Master's light lance from below deals **350** instead of 300
  (`campaign-outline.md` 4.2 phase 3); `e2m5_seals_kindled` = one extra line for Vessa in `ep8_opening` ("I've turned his
  seals before"); `ep2_torvald_doubts` = Ep3's "Torvald's doubt" scene and e3m4 may reference the rime-lantern.
- Level not carried.

## Difficulty
| | Easy | Normal | Hard |
|---|---|---|---|
| Guard / wave counts | x 0.6, no Colossus, no Knights in waves | as written | x 1.4 |
| Start crystals | 600 + 2 extra Flame Guards | 500 | 400 |
| Wake meter base rate | 0.08 / s (wake 13:00-17:00, cap 18:00) | 0.10 (12:00-15:00, cap 16:00) | 0.12 (10:00-13:00, cap 14:00) |
| Doorwarden HP / Door Slam | 11 000 / 90 | 15 000 / 120 | 19 000 / 150 |
| Deep Door HP / per kindled seal | 7 000 / +600 | 6 000 / +500 | 5 500 / +400 |
| Tether | x 0.6 damage, heal 10 / s | x 0.5, 20 / s | x 0.4, 30 / s |
| Sunlance | every 12 s | every 15 s | every 18 s |
| Wizards | Malrik L5, Torvald L5 | L6 | L7 |
| Expected time | 21-25 min | 25-31 min | 29-35 min |
**Fight sizing (normal, every scripted wave <= 70 % of the army the player can have then; the ally's army and the bots'
own rally armies are the 2v2 on top).** Income with 6-10 workers ~300-500 crystals / min.
| Fight | When | Enemy | Player army then (crystals) | Ratio |
|---|---|---|---|---|
| Warden host on the dais | from ~1:00 | 6 Wardens (~900) | 2 000 + Vey L5 + Vessa L5 | 45 %, and it hits Malrik's escort too (3-way) |
| Malrik's seal run | 3:00 | Malrik L6 + 320 | ~2 300 | 14 % + a wizard: a duel at a seal |
| W1 | 4:00 | 460 | ~2 400 | 19 % |
| Torvald's cover | 5:00 / 9:00 | his rally army ~1 300 + Torvald + Aldra | ~2 600 / ~3 200 | 50 % / 41 %: fight it on the dais with the ally (`attack` ping) or wait it out |
| W3 joint | 11:00 | 1 650 | ~3 500 + a Dragon soon | 47 % |
| Wake push + boss B1 | ~13:30 | 1 040 + the boss + 6 amber Wardens | ~3 800 + Dragon + Vey L6 | the boss is the test; the push is 27 % |
| B2 with Malrik's guard | ~16:00 | his rally ~1 400 + 470 + Malrik L6 + the boss | ~3 800 | ~49 % (without the boss): the tether fight |
| Ice pressure | every 120 s | 890 | the ally holds it; ~23 % of the player's army if they help |
- The intended answers: kindle S and W first (your side of the dais), let Ysolde take E, contest N only when Malrik is
  dead; keep a Kilnwarden on the dais (Slag Rain: Wardens, Rimeshields, and the boss: titan 5 s, armor 25 -> 5); in B2
  send the Dragon and Blaze Riders at Malrik (the tether breaks the moment he dies), Saboteur Powder Charge on
  his Gloom Hall to stop reinforcements; in B3 stand Vessa at the Door's south rim with Vey (Ember Step out of Stonehurls,
  the Door is 5 m wide: room to dodge).
- The Roost is a real choice: Stables 175 + Roost 300 + Dragon 700 = 1 175 crystals for one flyer before the wake (~3
  minutes of income) vs ~13 Flame Guards. The Dragon is the answer to the Warden host (breath on clumps) and to the
  tether (it flies over the Rift to Malrik); the Crucible is the slow answer (free Guards for the Door's rim).

## Code reuse (recommendation to the lead)
Prerequisites: step 20's seats, `AIAlly`, `AllyChannel` (as e2m2); the e2m4 pieces (`deep_stone`, sunstones, the storm
rule, `mother_hush` kit); the step-13 Stables / Lair / Cinder Dragon and the step-13c Ember Crucible; the M4 boss stack
(19.C6: boss bar, telegraphs, `phase_changed`, Exposed, Turn-the-Key-style condition). New: `deep_door.map` (World Forge),
`DeepDoor` (a `Building`-like side-0 target with regen and a one-time Hold heal), `MissionSeal` (a `MissionBrazier` with
two owners and flip rules), the Wake meter, `Doorwarden` (titan boss: walk to the door, Door Slam, Stonehurl, Warden Call,
the Malrik tether, Quake, Sunlance hook), `aldra_story`, the Door order for the ally bot.

## Acceptance checks
1. `data/maps/deep_door.map` builds (0 FAIL); twins exact; the Rift is impassable except the dais and the two bridges;
   paths from every keep to every seal; the scene loads with 4 seats.
2. A seal kindles in 4 s with Vessa at 3 m, pauses with an enemy at 5 m, resets on 30 damage; Malrik cracks it back in 4 s;
   the Wake meter rate matches the table (0.10 + 0.10 x amber - 0.05 x white-gold, min 0.05).
3. The wake never fires before 9:00 and always by 16:00; at the wake each white-gold seal adds 500 to the Door and each
   amber seal gives the boss x 0.85 damage taken; the Warden host turns `ENEMY`.
4. B1: Door Slam 120 every 6 s only within 7 m of the Door; B2: with Malrik alive within 20 m the boss takes x 0.5 and heals
   20 / s, Malrik's death breaks it at once; B3: a Sunlance every 15 s only with Vessa within 6 m of the Door and Vey within
   8 m of her, 300 + Exposed 8 s.
5. The Hold heals the Door 1 000 once, at the first 50 % dip; Door 0 plays `e2m5_breach` and ends in defeat.
6. The Roost cannot be placed before 8:00; it trains the Cinder Dragon (700, pop 6) and lights the Ember Crucible (one free
   Flame Guard per 40 s, max 6).
7. Ysolde kindles E at ~2:30, answers pings, holds the Door's south-east rim after the wake; her seat going out is not a
   defeat; Torvald and Aldra walk home at B3.
8. Skipping every cinematic leaves the same state (19.C9 test for e2m5); victory saves `MISSION_REWARDS[&"e2m5"]` and plays
   `ep2_ending`, then the Story menu shows Episode 2 complete.
9. Scripted headless runs on normal (kindle S / W, Stables + Roost + Dragon, break the tether by killing Malrik, lances)
   end `victory=true` in **25-31 game-minutes** with the Door at 30-60 %; a run that never kindles a seal and never kills
   Malrik in B2 loses the Door in 3 / 5 runs; `PERF OK` with the boss, 4 armies, a Dragon and 6 Wardens on screen.

## Done when (proposed ids; the lead adds them to `waves.md`; after step 20 and e2m4's E2M4.W1 / V1)
- [ ] E2M5.W1 (four-wizards-high, World Forge): `data/maps/deep_door.map` (cavern, Rift, dais with ramps, bridges, 4 base
  plateaus, side caves, alcoves, sunstones / splinter-lamps, marks); check 1.
- [ ] E2M5.S1 (systems): `missions/mission_e2_05.tscn` + `MissionE2_05` with 4 seats on that map, the switches of "Tiers
  and switches" (Fire keep at tier 3), `MissionSeal` + the Wake meter, `DeepDoor` (HP, regen, Hold, untargetable before the
  wake), the Warden host (respawn, turn at the wake), start state with every flag branch (`e2m2_carriers_kept`,
  `e2m3_malrik_robbed`, `e2m4_sunwardens`, `e2m4_hush_driven`, `e2m4_road_lit`) and the no-save fallback. Test
  `tests/test_e2m5_s1.gd`: checks 2, 3 and 5.
- [ ] E2M5.S2 (systems-high): objectives and events E1-E24 in order, the 38 lines, waves and orders of the table (seal runs,
  covers, W1-W3, Hush, wake push, Ice pressure, Malrik's guard, Torvald's withdrawal, Withdraw), the phase driver, win /
  lose, difficulty, `MISSION_REWARDS[&"e2m5"]` with `set_flags`, `MISSION_SCENES[&"e2m5"]`, StoryFlow -> `ep2_ending` ->
  episode complete. Test `tests/test_e2m5_s2.gd`: checks 7 and 8.
- [ ] E2M5.G1 (gameplay) **[H]**: `Doorwarden` (stats, titan tags, B1-B3 abilities with telegraphs, the tether link to a
  given Wizard, Exposed, the Sunlance hook called by the mission), `aldra_story`. Test: check 4.
- [ ] E2M5.A1 (ai): profiles `mission_e2_05_shadow` / `_ice` / `_ally`; the scripted overrides (seal runs with Malrik's
  escort and retreat rule, Torvald's 90 s cover, Malrik's B2 guard position, Torvald's withdrawal); Ysolde's mission orders
  (kindle E, the Door order) on top of `AIAlly`; `AIStoryCaster` for Aldra. Test: Malrik walks to the nearest non-amber
  seal and cracks it; under 35 % HP he goes home; Ysolde kindles E by 3:00 in 5 / 5 runs.
- [ ] E2M5.U1 (ui): briefing, objectives panel (seal pips white-gold / amber, the Wake meter, the Door HP bar, the boss bar
  with 100 / 70 / 35 marks, the tether and lance hints), the Door and seals on the minimap, the italic whispered subtitle
  for `master` L17, speaker colours for `master`, `aldra`, `hush`, `obren`; hidden during cinematics.
- [ ] E2M5.V1 (tech-artist) **[H]**: the Doorwarden (16 m jailer-statue: granite, amber seams, key-ring, hammer-fist; asleep
  / awake / kneeling / crumble states; Door Slam, Stonehurl, Quake telegraphs; the tether beam), the Deep Door (floor door,
  god-rays, cracks of light, the Sunlance beam, the breach state), the seals (grey / white-gold / amber), the cavern dressing;
  0 lights; `PERF OK`.
- [ ] E2M5.V2 (tech-artist): Aldra's story look on her helper model (TH.V4) or a stand-in; splinter-lamps; Art Lab sheet.
- [ ] E2M5.C1 (four-wizards-high): `e2m5_cavern`, `e2m5_wake`, `e2m5_answer`, `e2m5_fall`, `e2m5_breach`; `cine check`
  0 FAIL; fallbacks.
- [ ] E2M5.C2 (four-wizards-high): the `forge_deep_door` stage set and the `ep2_ending` timeline once E2M5.D1 delivers the
  script; 1:30 +- 2 s.
- [ ] E2M5.VO (Voice Forge agent): render the 38 lines (`data/voice/lines/e2m5.json`) and the `ep2_ending` lines; L17 and
  L24 (the Master) in the prologue's `master` voice; no new speaker.
- [ ] E2M5.D1 (game-designer): read the lines in game once, trim any line over 2 box lines; write the `ep2_ending` script
  (1:30, `episode2-opening.md` format) from the beats above.
- [ ] Lead: acceptance check 9; a save with no Ep2 progress starts on the fallback.

## Consistency notes (for the doc owners)
| # | Where | Issue | Fix (recommended) |
|---|---|---|---|
| 1 | `mission-e3-01.md` briefing paragraph 1 "Two summers ago the Master's door held" | `ep4_opening` L8 says "**Last winter** they burned my wood"; Ep2 (e2m1 burnt-and-frozen wood, e2m2 late winter) ends at the Door in early spring, and Evenmead is that summer | e3m1's line becomes "This spring the Master's door held, and the war came up out of the deep looking for open ground." |
| 2 | `campaign-outline.md` 3.2 row e2m5 "Fire titan (`titans-2.md`) as the reward unit" | `titans-2.md` 6 makes Fire's second titan option a base upgrade (the Ember Crucible); the Fire titan **unit** is the Cinder Dragon (`cavalry-mounts.md` 5) | This spec offers both at the Dragon Roost; the Cinder Dragon is the story's reward (`fire_titans_unlocked`) |
| 3 | `t3-helpers.md` 3 "Missions: `helpers_enabled := false`" | Ep2 missions switch helpers on (e2m1-e2m5) and e2m4 / e2m5 grant Vey free at 0:00 | `HelperRoster` gets a mission grant (`grant(team, id)`) and a mission price override (already proposed in e2m1's "Code reuse") |
| 4 | `map-2v2.md` 4.4 "a seat is out ... a side loses when all its seats are out" | e2m2 makes the `ALLY` seat's fall a defeat; e2m5 makes it no defeat | Missions own their win / lose tables; `Skirmish2v2`'s side rule stays the skirmish rule |

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Cinder Dragon (Fire titan).
- **Why here:** the Rift blocks ground units and flyers cross it; a titan boss fight.
- **Moment:** the first Dragon flies straight over the Rift onto Malrik's seal runners (L13).
- **Intro card:** `Cinder Dragon. Fire from the sky: it flies over the Rift and burns what walks below.`

## Built (2026-10-07)
`missions/mission_e2_05.tscn` + `scripts/campaign/mission_e2_05.gd` (`MissionE2_05`), tests `tests/test_e2m5.gd` (checks
2-8) and `tests/test_e2m5_sim.gd` (check 9, slow list; `-- --noseals` = the "never kindles, never hunts Malrik" run).
Runs on the real seat API (4 seats, `activate_seat` for Nature / Ice). Deviations:
- Map: built in code on a 150 x 150 MapInfo (no World Forge `deep_door.map`): the Rift is a rock strip along z = 0
  (16 <= |x| <= 75) with the Rift Bridges at x = +-45 (8 wide) and the dais (r 16) open; four bases at the spec's keeps;
  side caves are nodes only; M0 night lighting. No flying in the engine: the Cinder Dragon walks the bridges.
- The Dragon Roost is a mission building (the Ember Hall type renamed: 300, 70 s, 1 500 HP) raised from the mission button
  `Raise the Dragon Roost (300)` (from 8:00, needs the Ember Stables); it trains the Cinder Dragon, a code-built story
  type (1 400 HP, 16 per 2.2 s + an 11 splash within 3 m of each hit, 700 / pop 6 / 85 s, the 13.V13 model). No Crucible.
- The Doorwarden: a scripted Unit (placeholder capsule 3.5 x 16 m, armor 25, the spec's HP). Its multipliers (x 0.85 per amber seal, tether x 0.5, Exposed x 1.5)
  are applied on `damage_taken`. Telegraphs = `flash_ring`. No boss bar UI (the objectives line shows the %).
- Malrik's tether spot is (0, -24) (spec (0, -28) is 21 m from the boss at the Door's rim: out of the 20 m tether).
- Bots are Commanders that never attack; Ysolde is scripted for the E seal and the Door order (SE rim); Maelis / Aldra are
  bonded story helpers back 45 s after a fall; Hush's 8:00 raid uses M00Cast. No cine timelines; no `ep2_ending` film
  (rewards `next` = `&"ep2_ending"`, no scene).
- The Door's armor 30 is mission-side (buildings have no armor): every hit but the Doorwarden's own refunds 30.
- **Scripted runs (normal, 2026-10-07): not green.** 1 victory in 9 runs: 16:59 mission time (18:25 with the cutscene
  lengths, spec 25-31), the wake at the 16:00 cap, the boss down in 59 s, the Door at 83 %. The other runs: the Door fell
  1:30-6:30 after the wake (boss HP tried x 4 / x 2 / x 1.5: 6 / 6 defeats; the Door's armor came after them), and the
  last run (spec HP + the Door's armor) timed out at 40:00 (Door held, boss alive). The `--noseals` run loses the Door
  (spec: 3 / 5). Open: the scripted player cannot hold S / W against Malrik's runs + Torvald's covers (most runs wake at
  9:00-12:00 with 3 amber seals) and the boss's HP vs the army's real DPS needs a tuning pass.

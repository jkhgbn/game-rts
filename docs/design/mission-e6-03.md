# Campaign mission e6m3: "The Year Nothing Grew" (young Ysolde + young Maelis vs the frost wolves; Episode 6)

Written 2026-10-02 (`campaign-outline.md` 3.6, row 3). Episode 6 "The Lake and the Seed" (origins), mission 3 of 4, the
first half of Ysolde's story: a girl of the second famine winter keeps four seed-gardens alive under the snow until
spring, and the Master finds her ("show me again"). Small army, tier 1, a **regrowth rule** instead of a base fight.
Target **14-18 min** on normal. Episode rules ER1-ER8: see `mission-e6-01.md` section 0. Uses `kingdom-nature.md`,
`new-units-12.md` (Thistle Darter), `levels.md`, `items.md`, `t3-helpers.md` 4.5 (Maelis), `map-fill.md` 5.5 (Direwolf),
`episode3-4-opening.md` 3.2 (Ysolde's own telling) and the format of `mission-01.md` / `mission-e3-01.md`. New scene
`missions/mission_e6_03.tscn` + `scripts/campaign/mission_e6_03.gd` (`MissionE603 extends MissionBase`, mission id
`e6m3`). Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)`, `+z` = south (the `forge_evenmead`
frame). Status: **design only**; recommended option taken everywhere.

## Decisions taken in this spec (recommended option)
| # | Point | Decision | Why |
|---|---|---|---|
| D1 | Which "year nothing grew" | **The second one.** `ep4_opening` L2: Ysolde was *born* "the year nothing grew". Thirty-two winters ago (ER1) the frost came back when she was about fifteen; the village calls it the year nothing grew, again. Her line L2 says it | Keeps the outline's title and the built film's canon (L2-L6) together |
| D2 | The map | **Evenmead** (`data/maps/evenmead.map`, the E34.M1 table of `mission-e3-01.md`, unchanged coordinates) in deep winter: snow terrain, the river **frozen to the bottom** (no `RiverSystem.setup`: the valley is walkable ground with an ice-sheet decal along the polyline) | Ysolde was born on Lark Hill (`ep4_opening` L2); the map is already measured; e3m1 / e4m1 use the same ground three decades later |
| D3 | The golden tree | The sapling Ysolde coaxes through the frost at the end **is** the Master's golden tree `(-16, 48.5)`: he touches it, it turns gold. "The Master planted this country with his own hands" (`ep4_opening` L11) starts here | A free, strong origin for the tree both Evenmead missions fight over |
| D4 | The base | The village shelters in **the Hollow Oak**: the Heartwood slot `(-32, 48)` with the Heartwood model (story name only). A pre-built Grove Hall. No Stronghold, one Seed Hollow | Outline: "small army"; ER4 tier 1 |
| D5 | Maelis | **Young Maelis** (~25, a huntress of Evenmead) is a story ally: the first meeting of Ysolde and her future warden | She is "Ysolde's warden" (`t3-helpers.md` 1); Ep4 makes her callable; her voice exists |
| D6 | The enemy | **Frost wolves** (new story unit `frostfang`) and their old leader **Old Whitepelt** (a Moonpelt Direwolf, `map-fill.md` 5.5). Wolves dig up seed: they go for the gardens, never the buildings | Outline: "against frost wolves"; the Direwolf model already exists |
| D7 | Win shape | Survive to spring with at least 2 of 4 gardens (normal); all 4 is the secondary | The regrowth rule is the mission; a lost garden hurts but does not end it |

## Story setup (briefing text, 3 short paragraphs; shown after `c_e6_lake` / `c_e6_gate`)
1. Thirty-two winters ago. Evenmead remembers the year nothing grew: the year the frost never lifted, the year a girl was
   born on Lark Hill. Fifteen winters later, the frost has come back.
2. The village sleeps inside the Hollow Oak and eats its last seed corn. Ysolde does not. She has buried the seed in the
   snow, in four gardens across the hill, the way her mother did. The village laughs.
3. The wolves are not laughing. They have come down from the north ridge, thin and hungry, and they can smell seed under
   snow. Keep the gardens alive until spring.

## Map: "Evenmead, the second famine winter" (150 x 120, `data/maps/evenmead.map`, seed 34, not mirrored)
Only the rows below are placed (e3m1's keeps, halls, nodes, fords, standards, horns and spires are **not**). Snow terrain
(step 12b `snow` biome over the meadow), bare trees, the frozen river as an ice-sheet decal (half width 3.0 on e3m1's
polyline `(-75,6) (-44,-3) (-18,4) (4,0) (26,-7) (50,-2) (75,5)`), drifts on the flank woods. Playable bounds as e3m1.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (Ysolde) / Maelis | `(-24, 40)` / `(22, 22)` | - | Maelis starts at the Well Garden |
| **The Hollow Oak** (player keep, tier 1) | `(-32, 48)` | 16 | The Heartwood type (2 250 HP), story name `The Hollow Oak`; snow on the canopy |
| Grove Hall (pre-built) | `(-44, 40)` | - | e3m1's Nature hall slot |
| Node `e6y_a` / `e6y_b` | `(-41, 44)` / `(-36, 56)` | - | **1 500** each (the village seed stores, as crystals) |
| Node `e6y_west` (expansion) | `(-56, 26)` | 7 | **2 000**; hall spot `(-50, 20)`; 30 m from the Clover Garden |
| **Garden G1 "Mother's Garden"** | `(-14, 38)` | 4 | 19 m from the Hollow Oak's centre, 10.7 m from the sapling |
| **Garden G2 "Crest Garden"** | `(-4, 32)` | 4 | Under Lark Hill's crest `(-4, 34.8)` |
| **Garden G3 "Clover Garden"** | `(-28, 20)` | 5 | e3m1's Clover Stone |
| **Garden G4 "Well Garden"** | `(24, 18)` | 5 | e3m1's Lark Well (the old stone well stands beside it) |
| **The frost sapling** | `(-16, 48.5)` | 6 | e3m1's golden-tree spot: a hand-high sapling under a snow cap (decor, no target) |
| Larkholt cottages (decor) | 6 cottages on a ring r 7 around `(20, 50)` | 12 | e3m1's Fire keep slot: the village's empty summer houses, snowed in; no collider beyond 2 m |
| **Den `den_w` / `den_n` / `den_e`** | `(-48, -32)` / `(0, -44)` / `(52, -34)` | 6 | The north ridge (e3m1's west node, Shadow pavilion, east node): wolf spawns, invisible holes in the snow |
| Lost Caches | `(-40, 10)`, `(48, 10)` | 3 | e3m1's Horn Spire spots: travellers' frozen packs, `items.md` loot at 2:00, reopen 180 s |
Distances (path, the river frozen): `den_n` -> G2 76 m; `den_w` -> G3 57 m; `den_e` -> G4 59 m; `den_w` -> G1 87 m; Hollow
Oak -> G1 19 m, G2 31 m, G3 28 m, G4 63 m. Wolves (6.2 m/s) reach any garden in 9-14 s: the player sees them coming
(howl ping at the den 4 s before each spawn) but cannot outrun them.

## Mechanic: the seed-gardens (the regrowth rule)
A **SeedGarden** (systems, new prop): a 3 m patch of mounded snow with bean poles, a straw scarecrow and green shoots that
show through as it grows. Team PLAYER, group `"scripted"` + `"gardens"`, **Life 500**, an attack target for ENEMY units
(`team`, `is_alive`, `take_damage`, `target_radius` 2.5), not a building, no navmesh obstacle, `counts_for_defeat` false,
always visible, minimap green leaf icon.
| Rule | Value |
|---|---|
| **Frost nights** | During a night (below), every garden that is not tended loses **3 Life / s** (snow-blue frost creeps over it) |
| **Tending** | A Sprigling ordered to gather on a garden (right-click / G, the `command_gather` path: gardens answer `can_mine` true but never give crystals) walks to it and tends within 2.5 m. **1+ tender = no frost loss**; each tender (max 2) **regrows +2 Life / s**. A tending Sprigling mines nothing |
| **Ysolde's touch** | Ysolde within 6 m: **+2 Life / s** (any time) |
| **Wild Bloom** | Gardens inside it heal **x 3** (rank 1: 180 over 5 s) |
| **What grows back fights back** | A garden above **80 %** Life sprouts **1 Sapling** (the Nature summon, 25 s, team PLAYER, commandable, pop 0) when an enemy comes within 10 m; once per 30 s per garden |
| Death | Life 0: the garden is lost (black frost, the scarecrow falls); it cannot be replanted this winter |
| Spring | At spring every living garden blooms (cutscene) |
Hint (E1, 12 s): `Spriglings can tend a garden: select them and right-click it (G). A tended garden does not freeze at
night and grows back. Tending Spriglings carry no seed home.`

## Mechanic: days and nights
| Time (normal) | Phase | Effect |
|---|---|---|
| 0:00-3:30 | Day | Low white sun |
| **3:30-4:30** | Night 1 (60 s) | Night preset (M0 moonlight); frost loss; PLAYER sight x 0.7 |
| 4:30-8:00 | Day | - |
| **8:00-9:15** | Night 2 (75 s) | As night 1 |
| 9:15-12:30 | Day | - |
| **12:30-14:00** | Night 3, the longest (90 s) | As night 1, colder: frost loss **4 / s** |
| 14:00-16:00 | The thaw | Grey dawn warming to gold; every living garden regrows +1 Life / s; no wolves spawn |
| **16:00** | **Spring** | Victory cutscene |
A 10 s warning before each night: message `Night is coming. Cover the gardens.` and the sky darkens. The objectives
panel shows `Spring in 11:24` and `Night in 0:40` / `Night: 0:52 left`.

## Start state
| Item | Value |
|---|---|
| Ysolde (young) | **Level 1** (Thornburst r1), **cap 4**; full HP / mana (340 / 110); look `&"young"` (below) |
| Maelis (young) | Story unit `maelis_young` at `(22, 22)` |
| Crystals / essence | 250 / 400 (+1 / s) |
| Buildings | The Hollow Oak (tier 1), Grove Hall |
| Units | **4 Spriglings** (2 on `e6y_a`, 2 on `e6y_b`); **4 Thornlings + 2 Burr Slingers** at `(-22, 36)` |
| Population | 10 / 20; Seed Hollows **max 1** (cap 40) |
| Inventory | 6 empty slots, no artifact (ER3) |
| Fog | On; the 4 gardens and Lark Hill explored |

## Unlocks
| Kind | Available | Locked |
|---|---|---|
| Buildings | Seed Hollow (Z, max 1), Grove Hall (X), Bramble Spire (C) | Tier 2+, Bazaar, stables |
| Units | Sprigling (keep Z); Grove Hall **Z Thornling, X Burr Slinger, C Bloomtender, N Thistle Darter** | V Bramblehorn and B Wildwood Archer (e6m4), tier-2 units, the Bramblesage |
| Keep | No tier button (`max_tier = 1`) | Stronghold (e6m4) |
| Spells | Thornburst (L1), Wild Bloom (L2+), Call the Thicket (L4); cap L4 | - |
| Items | Base shop (the Hollow Oak, the Grove Hall): components, mids, the 4 Nature items (`kingdom-nature.md` 5), potions | Tops out of reach |

### Young Ysolde and young Maelis (looks and story units)
- **Ysolde `&"young"`** (tech-artist variant of the Ysolde model): ~15, a wreath of bare twigs with one blossom instead of
  the crown, a plain undyed wool cloak over the leaf gown, a hazel staff whose seed is closed (it opens only in the spring
  cutscene). Same stats as the wizard (she is the player's wizard).
- **Maelis `maelis_young`** (story unit, ER5): the Maelis model with a young look (`&"young"`: ~25, a hunter's hood, a short
  thorn bow instead of the staff, a wolf-fur collar). Team PLAYER, not commandable. HP **400**, armor 5, **16** damage,
  range 9.5 (thorn arrow), cooldown 1.25, speed 4.9, Verdant regen 1.5 %. **Thornsnare** (`t3-helpers.md` 4.5, cooldown
  14 s: ring, 0.6 s, 20 + `rooted` 1.2 s). Brain **"Keeper of the well"**: stays within 10 m of the Well Garden and fights
  what comes within 14 m of it; if that garden is lost, she escorts Ysolde (3-7 m). Falls: back after **40 s** at the
  Hollow Oak, line L24 once.

### Frost wolves (`frostfang`, gameplay; story enemy) and Old Whitepelt
| | Frostfang | Old Whitepelt |
|---|---|---|
| Model | The Moonpelt Direwolf (12.V29 variant B) at **x 0.55**, thinner, ribs showing | The Moonpelt Direwolf at x 1.0, scarred muzzle, one blind eye; boss bar `Old Whitepelt` |
| HP / armor / damage / range / cooldown / speed / aggro | 120 / 0 / 12 / 1.3 / 1.0 / **6.2** / 10 | **1 000** / 10 / 22 / 1.6 / 1.0 / 7.0 / 12; **Pounce** and **Hamstring** (`map-fill.md` 5.5) |
| XP / essence | 30 / as a 65-crystal unit | 300 / 120 |
| Behaviour | **Seed hunger**: attack-move to its target garden; within 10 m of any living garden it attacks the garden unless it was hit in the last 3 s (then it fights the attacker for 3 s). **Never attacks buildings.** No Commander | Same, target Mother's Garden; Pounces on Ysolde if she is within 10 m |
Team ENEMY, group `"scripted"`. At spring every wolf left runs north and despawns at its den.

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_spring` | Primary | `Keep the seed-gardens alive until spring (4 / 4) · Spring in 11:24` | 16:00 with >= 2 gardens alive (normal); **failed** the moment fewer than 2 live = defeat |
| `obj_ysolde` | Primary, always shown | `Ysolde must survive` | Fails = defeat |
| `sec_all` | Secondary | `Bring all four gardens to spring` | 4 alive at 16:00; failed at the first loss |
| `sec_whitepelt` | Secondary (appears at E9) | `Drive off Old Whitepelt` | Old Whitepelt killed |

## Waves (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
Each spawn: a howl at the den (ping + sound) 4 s before, then the wolves lope out of the snow.
| Wave | Time | Units | Den | Target garden |
|---|---|---|---|---|
| R1 | 2:00 | 3 Frostfangs | `den_n` | G2 Crest |
| N1a | 3:30 | 4 Frostfangs | `den_w` | G3 Clover |
| N1b | 3:45 | 3 Frostfangs | `den_e` | G4 Well |
| R2 | 6:00 | 4 Frostfangs (`den_e` -> G4) + 3 Frostfangs (`den_n` -> G2) | two dens | G4 / G2 |
| N2a | 8:00 | 5 Frostfangs | `den_n` | G2 Crest |
| N2b | 8:15 | 4 Frostfangs | `den_w` | G3 Clover |
| N2c | 8:30 | 4 Frostfangs | `den_e` | G4 Well |
| R3 | 10:45 | 5 Frostfangs | `den_w` | G1 Mother's (the west flank, past Clover) |
| N3a | 12:30 | 5 Frostfangs (`den_n` -> G2) + 4 Frostfangs (`den_e` -> G4) | two dens | G2 / G4 |
| N3b | 13:00 | **Old Whitepelt** + 4 Frostfangs | `den_n` | G1 Mother's |
If a wave's target garden is already lost, its wolves take the nearest living garden.

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Briefing, then camera on Ysolde at the Hollow Oak; L1-L5; tending hint (12 s) |
| E2 | 3:20 | Night warning; at 3:30 night 1: L6-L7 |
| E3 | R1 or N1 first seen | L8 |
| E4 | First Sapling sprouts from a garden | L9 |
| E5 | A garden lost (first) | L10; `sec_all` failed |
| E6 | 8:00 | Night 2: L11-L12 |
| E7 | Ysolde reaches L4 (first) | Hint (8 s) `Call the Thicket (E) is ready: three Saplings at a point. Save it for the long night.` |
| E8 | 12:30 | Night 3: L13 |
| E9 | 13:00 (N3b) | L14; `sec_whitepelt` active; boss bar |
| E10 | Old Whitepelt killed | L15; `sec_whitepelt` done |
| E11 | 14:00 | The thaw: L16; light warms; wolves still alive keep fighting until spring |
| E12 | 16:00 | Cutscene `e6m3_spring` (0:50, HOLD): L17-L21; victory at its end |
| E13 | Ysolde dies | L22; defeat after 3 s |
| E14 | Fewer than 2 gardens alive | L23; defeat after 3 s |
| E15 | Maelis falls (first) | L24 |

## Dialogue (25 lines; 5 s each unless listed; <= 96 characters)
Speaker colours: `ysolde` `(0.55, 0.90, 0.35)`, `maelis` `(0.60, 0.85, 0.50)`, `master` `(0.95, 0.93, 0.85)`,
`narrator` `(0.9, 0.85, 0.7)`. Ysolde's lines use her approved voice (`bf_emma`, 1.0): Kokoro cannot age a voice, so the
text carries the youth (short sentences, a girl's stubbornness), the same approach as Wren's stumbles in `cast.json`.
File `data/voice/lines/e6m3.json`.
| Line | Event | Speaker | Text |
|---|---|---|---|
| L1 | E1 | narrator | Thirty-two winters ago, the frost came back to Evenmead. Nothing grew. Again. |
| L2 | E1 | ysolde | They say I was born the year nothing grew. I won't let there be two. |
| L3 | E1 | maelis | Seed in the snow, little one? The whole village is laughing at you. |
| L4 | E1 | ysolde | My mother did it. In spring it came up green. Help me keep the wolves off. |
| L5 | E1 | maelis | Fine. I'll take the well. The wolves always come to the well. |
| L6 | E2 | narrator | When the sun went down, the frost bit through everything that was not covered. |
| L7 | E2 | ysolde | Cover the gardens! Sit on them if you have to! |
| L8 | E3 | maelis | Wolves off the north ridge. Thin ones. Hungry ones. |
| L9 | E4 | ysolde | See? It fights back. Things that grow always fight back. |
| L10 | E5 | ysolde | No. No, no. I'll plant it again. Next year. I will. |
| L11 | E6 | maelis | Colder than last night. The river froze to the bottom. |
| L12 | E6 | ysolde | Then we'll be warmer than the river. |
| L13 | E8 | narrator | On the longest night, the pack's old leader came down from the ridge. |
| L14 | E9 | maelis | Old Whitepelt. I've hunted him nine winters. He's never been this hungry. |
| L15 | E10 | maelis | Nine winters. And a girl with a seed sack beats me to him. |
| L16 | E11 | narrator | And then, one grey morning, the snow began to turn to water. |
| L17 | E12 | master | A sapling, coaxed through the frost. In this cold? |
| L18 | E12 | ysolde | It wants to grow. It only needs someone to wait with it. |
| L19 | E12 | master | Show me. (2 s) |
| L20 | E12 | master | ...Show me again. (3 s) |
| L21 | E12 | narrator | She did. For twenty years, until he was gone. |
| L22 | E13 | ysolde | I'm sorry... I couldn't keep them warm. |
| L23 | E14 | ysolde | Nothing grew. Nothing at all. |
| L24 | E15 | maelis | I'm fine! Bitten. Fine. Keep planting. |
| L25 | `c_e6_seed` | ysolde | Twelve years ago he sent for me one last time. Torvald too. Only us. (6 s) |
Echoes: L17-L20 are the prologue's S26 / S29 ("I found her coaxing a sapling through the frost", "show me again") and
`ep4_opening` L5-L6 from the other side; L21 is `ep4_opening` L6 verbatim in the narrator's mouth; L9 is Ysolde's whole
kingdom in one sentence ("it grows back"); L25 hands over to e6m4.

## Cinematic hooks (ENGINE; skippable; units frozen)
| Id | Kind | When | Length | Shots / actors | End state (a skip must leave exactly this) |
|---|---|---|---|---|---|
| `e6m3_spring` | ENGINE, **HOLD**, then victory | E12 | 0:50 | Teleports at `at == 0`: Ysolde `(-15, 47)` kneeling (gesture `kneel`), the Master actor `(0, 20)`. 1) WIDE: a warm wind; from each living garden the snow melts outward in a ring and green shoots race over the hill (`bloom_wave` VFX per garden; lost gardens stay black); 2) the Master walks up Lark Hill out of the thaw mist to `(-14, 46)`; 3) **LOW, in the snow** (the prologue S26 frame): the last patch of frost around the sapling; he kneels beside her (L17-L18); 4) CU her cupped hands round the sapling: it grows a hand-span (L19); 5) it grows again and its leaves turn **gold** (L20); 6) CRANE up and out: the whole hill green, a small gold tree at its heart (L21) | Victory; the sapling prop swapped for a 1.2 m gold sapling (cosmetic) |
| `c_e6_seed` | ENGINE stage, between-scene | After the victory screen | 0:40 | Present-day winter truce on Lark Hill: Ysolde under the grown golden tree (one branch scorched by the Evenmead battle), Maelis (TH look) beside her. Maelis: `You never told the village you were right.` Ysolde: `I didn't need to. It came up green.` Then L25 | - |
Camera axis: the Ysolde - Master line runs east-west at the sapling; cameras stay south of it (downhill, looking up).

## Tiers, casters, helpers
`MissionE603._init`: `tiers_enabled = true`, `casters_enabled = false`, `helpers_enabled = false`; `_ready`:
`tier_system.max_tier = 1`, `bots_upgrade = false`. Grove Hall card Z X C N; tier chip `Tier 1 Keep`. No enemy base.

## Economy
| Item | Value |
|---|---|
| Start | 250 crystals, 400 essence, 10 / 20, 4 Spriglings |
| Nodes | Home 2 x 1 500; west 2 000 (beside the Clover front) |
| Expected (normal) | ~10 Spriglings by 5:00; 2-4 of them tending at each night (the real cost: ~40 crystals / min of mining per tender); ~2 000 crystals mined by 16:00 |
| Essence by 16:00 | 400 + trickle ~960 + kills ~1 000 (~45 Frostfangs, Whitepelt 120) = **~2 300**: two mids or a Bloomcaller Staff early (Blossom: Wild Bloom heals gardens x 3 x 1.25) |
| Pressure | Mining vs tending (a Sprigling on a garden is a Sprigling not mining); Thornlings (cheap, fast, 5.4 m/s) vs Bloomtenders; a Bramble Spire beside the Crest Garden (+2 HP / s aura for the defenders) |

## Win / lose
| Event | Result |
|---|---|
| 16:00 with >= 2 gardens alive | **Victory** after `e6m3_spring` |
| Fewer than 2 gardens alive | **Defeat** |
| Ysolde dies | **Defeat** |
| The Hollow Oak destroyed | **Defeat** (wolves never target buildings: only possible by a stray fight) |
| Maelis falls | Nothing; back in 40 s |

## Reward and flags
- Nothing carried (ER3). `MISSION_REWARDS[&"e6m3"] = {"flags": {"e6m3_all_gardens": "sec_all", "e6m3_whitepelt":
  "sec_whitepelt"}, "next": &"e6m4"}`. (Ep8's Nature road may greet `e6m3_all_gardens`; nothing depends on it.)
- Story flow: victory -> `c_e6_seed` -> e6m4 briefing.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave counts | x 0.6 | as written | x 1.4 |
| Gardens needed at spring | 1 | 2 | 3 |
| Garden Life / frost loss (night 3) | 600 / 2 (3) | 500 / 3 (4) | 400 / 4 (5) |
| Old Whitepelt HP | 750 | 1 000 | 1 300 |
| Start | 350 crystals, +2 Thornlings | 250 | 200, 3 Thornlings |
| Expected time | 16:50 (fixed spring) | 16:50 | 16:50 |
Fight sizing (Frostfang **65**, Old Whitepelt **600**; player side = crystals + Ysolde `170 + 30 x level` + Maelis ~300;
every fight <= 70 % of what the player can have then; fronts counted separately where the waves split):
| Fight | Enemy | Player side then | Ratio |
|---|---|---|---|
| R1 (2:00) | 195 | ~860 | 23 % |
| N1 (3:30-3:45, two fronts) | 260 + 195 | ~1 100 (Maelis on the Well front) | 24 % / 18 % (41 % total) |
| R2 (6:00, two fronts) | 260 + 195 | ~1 300 | 35 % total |
| N2 (8:00-8:30, three fronts) | 325 + 260 + 260 | ~1 600 | **53 % total**: the first real split |
| R3 (10:45, flank) | 325 | ~1 800 | 18 % |
| N3a (12:30, two fronts) | 585 | ~2 000 | 29 % |
| N3b (13:00) | 600 + 260 = 860 | ~2 000 | 43 % (72 % if N3a is still alive: the Thicket, garden Saplings and Maelis carry it) |
- The mission is won by **economy timing**, not by army size: Spriglings onto the gardens 10 s before each night, back to
  the nodes after. A player who never tends loses ~180 / 225 / 360 Life per garden over the three nights and needs
  Ysolde's touch and Wild Bloom everywhere: possible for 2 gardens, not for 4.
- The Well Garden is far (63 m) on purpose: Maelis holds it alone against R2 / N1b-sized packs, not against N2c + a hunt.
- Watch in the first playtest: if 4 / 4 is common on normal, cut tending regrowth to +1.5; if the Well falls in every
  run, give Maelis 500 HP.

## Target length (normal)
| Part | Time |
|---|---|
| Mission (fixed: spring at 16:00) | 16:00 |
| `e6m3_spring` | 0:50 |
| **Total** | **~16:50** (inside 14-18; easy and hard last the same, only the fights change) |

## Code reuse (recommendation to the lead)
`MissionBase`; `evenmead.map` (E34.M1) without the e3m1 rows; the M0 night preset; the worker gather path for tending
(a `SeedGarden.can_mine()` that is true and a `take()` that returns 0 and ticks the tend instead); the Sapling summon
(`kingdom-nature.md` 3.1) for the garden sprouts; the Direwolf (`map-fill.md` 5.5) code and model for both wolves; the
Maelis helper code (Thornsnare) for her story unit.

## Acceptance checks
- [ ] Map: `evenmead.map` loads with only this table's rows; no water (the valley is walkable everywhere); the 4 gardens, 3 dens, sapling and cottages within 1.5 m of the table.
- [ ] Gardens: an untended garden loses 3 / s at night and 0 by day; a tended one loses 0 and regains 2 / s per tender (max 2); Ysolde at 5 m adds 2 / s, at 7 m 0; Wild Bloom r1 heals a garden 180; a garden at 85 % sprouts one Sapling when a wolf comes within 10 m, not again for 30 s; a tending Sprigling adds 0 crystals.
- [ ] Wolves: never attack a building; attack a garden within 10 m unless hit in the last 3 s; waves at their times / dens / targets (easy x 0.6, hard x 1.4); retarget when their garden is lost; flee at spring.
- [ ] Nights at 3:30 / 8:00 / 12:30 with their lengths and warnings; thaw regrowth from 14:00.
- [ ] Defeat the moment a third garden falls on normal (1 left); victory at 16:00 with 2.
- [ ] Maelis: not commandable, keeps within 10 m of G4 until it is lost, then escorts Ysolde; falls and returns.
- [ ] Skipping `e6m3_spring` gives victory with the gold sapling in place.
- [ ] Timing / balance: a scripted headless run on normal (2 tenders per garden at each night, army on the busiest front) reaches spring with >= 3 gardens in 3 / 3; a run with no tending keeps <= 2.

## Done when (proposed ids)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| **E6M3.S1** | systems | Scene + script on `evenmead.map` (winter: snow biome, frozen-river decal, no RiverSystem), the table's rows only, `SeedGarden` (Life, frost, tending through `command_gather`, touch, Bloom x3, sprouts), days / nights, start state, `max_tier = 1` | E34.M1, M9.S1 | Map / garden / night checks |
| **E6M3.S2 [H]** | systems-high | Waves R1-N3b with howls and retargeting, events E1-E15, objectives (garden counter, spring countdown), win / lose, difficulty, flags | E6M3.S1 | Wave / defeat / timing checks |
| **E6M3.G1** | gameplay | `frostfang` UnitType + seed-hunger brain; Old Whitepelt values on the Moonpelt Direwolf; `maelis_young` story unit (stats, Thornsnare, "Keeper of the well" brain, fall / return); Wild Bloom heals `"gardens"` x3 | TH.G1, 12.G (beasts) | A wolf hit by a Thornling fights it 3 s then returns to the garden |
| **E6M3.U1** | ui | Objectives (gardens 4 / 4 with per-garden Life pips, spring and night countdowns), night warning, Whitepelt boss bar, garden minimap icons, `maelis` colour | 19.U3 | Both test sizes |
| **E6M3.C1** | systems-high | `e6m3_spring` and `c_e6_seed` | 19.C1 | Skip test |
| **E6M3.V1** | tech-artist | Ysolde `&"young"` and Maelis `&"young"` looks; SeedGarden (snow mound, poles, scarecrow, 4 growth states, frost creep, black dead state); Frostfang scale / thin variant; winter Evenmead dressing (snow biome pass, bare trees, frozen river decal, Larkholt cottages); `bloom_wave` VFX; the gold sapling | 12b snow biome, 12.V29 | 0 lights, Art Lab, `PERF OK` with 25 wolves and 4 gardens |
| **E6M3.O1** | Voice Forge agent | `data/voice/lines/e6m3.json` (25 lines) | Lines frozen | Each WAV fits |
| **E6M3.D1** | game-designer | Lines in game; first-playtest tuning (tending rate, Maelis HP) | Playtest | Written back here |
| Lead | lead | Headless timing runs; commit | All | Acceptance "Timing" |

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Thornling.
- **Why here:** frost wolves attack gardens only and never fight units: Thornlings on a garden kill them while they chew; Lab 68 / 24 / 35 (cheap bodies).
- **Moment:** N1 (3:30): "Thornlings on the gardens: the wolves bite the seeds, your Thornlings bite the wolves.".
- **Intro card:** `Thornling. Small, cheap, stubborn: plant them where it matters and they never move.`

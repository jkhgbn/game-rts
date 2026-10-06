# Campaign mission 0: "The Night of Knives" (Vessa + Old Vey vs Mother Hush)

Task 19.D2 (part 1 of 4), written 2026-10-02 from `story-episode-1.md` 5.0 ("ep1"; its numbers are binding unless this
doc says why it moved them) and `campaign-outline.md` 6 item 1. Built in step 19 (ids at the end; 19.C7 is split in
two). Prologue mission of Episode 1; target **9-12 min** on every difficulty, its two engine cutscenes included (the
fixed 8:00 night is most of it). Uses the rules of `mission-01.md` (braziers, scripted groups, objectives, dialogue,
instant loss), `levels.md`, `spells.md`, `cinematics.md` (PAUSE / HOLD, `MissionBase.mission_time()` which excludes
cinematics) and `t3-helpers.md` (Vey and Hush reuse the helper models, VFX and ability code with story numbers). New
scene `missions/mission_00.tscn` + `scripts/campaign/mission_00.gd` (`Mission00 extends MissionBase`, mission id
`m00`). Metres, seconds, `m:ss` of `mission_time()` (since the navmesh was ready, cinematics excluded); positions
`(x, z)`, `y = 0`, `+z` = south (north = smaller z, east = larger x). Recommended option taken everywhere.

## Story setup (briefing text, 3 short paragraphs)
First start from the Story menu: **no briefing screen** (V1 `ep1_intro` is the briefing, or its fallback card,
ep1 7.4); the objectives appear in the panel. Retry and the Missions list show this briefing (3 paragraphs + the
primary objectives), as mission 1 does.
1. Twelve years after the Master vanished, Old Vey, his old sword, wrote to the apprentice he once taught to strike a
   spark: the crown sealed in the ruins of Emberfall is waking. Vessa rode out that day with four guards.
2. Malrik of Shadow read the letter too. That night his knives came over the walls of the Emberfall watch: Mother Hush,
   the knife that never misses, and every assassin he owns. The first blade only grazed Vessa. Old Vey's sword, and a
   crack of lightning no kingdom can explain, turned the second.
3. Vessa is wounded and the watch is small. Light the watch-fires so the Emberguard can find you, keep behind Vey's
   sword, and live until dawn.

## Map: "Emberfall Watch" (the mission 1 map at night, only the player's corner is played)
Same generator, seed and clearings as mission 1 (`MAP_SEED := 1101`, lane width 5, every mission 1 clearing kept) so
every tree stands where it will stand at dawn in mission 1; mission 1's props are **not** spawned except the cold
Hearthward bowl (below). One mission-only clearing is applied as a filter after generation (no other tree moves).
Play area = camera bounds **x -58..-8, z 8..58** (`camera_bounds := Rect2(-58, 8, 50, 50)`). The edges are enforced
by 2 invisible static boxes in group `"navigation_geometry"` (layer 1, no mesh), baked into the navmesh from the start:
**east wall** `x = -7`, z 6..60, 1 m thick; **north wall** `z = 7`, x -60..-6, 1 m thick. Nothing the player owns can
walk, step or be ordered past them (Ember Step uses the closest navmesh point, so it stays inside). Beyond: black fog.
| Thing | Position | Clearing r | Notes |
|---|---|---|---|
| `PLAYER_START` (generator centre) | `(-36, 36)` | 18 | Mission 1 clearing; everything of the watch sits inside it |
| **Emberfall watch-keep** | `(-43, 43)` | - | `fire_watch_keep` (below): 2 000 HP, shoots, cannot train |
| Courtyard (start) | Vessa `(-38, 40)`, Old Vey `(-37, 41)` | - | The amber crack seam: centre `(-36, 39)`, 6 m long, running south-west to north-east (decal, closed) |
| Escort: 4 Flame Guards | `(-34, 39)`, `(-34, 41)`, `(-33, 40)`, `(-33, 42)` | - | Team PLAYER, commandable |
| Escort: 4 watch archers (Ember Archers) | `(-39, 36)`, `(-41, 36)`, `(-39, 34)`, `(-41, 34)` | - | Team PLAYER, commandable |
| **Watch brazier WB1 "Bell"** (north) | `(-43, 27)` | - | Ring **r 16** around the keep, angle 270 (see "Why r 16") |
| **Watch brazier WB2 "Gate"** (north-east) | `(-32, 32)` | - | Angle 315, faces the lane |
| **Watch brazier WB3 "Crag"** (east) | `(-27, 43)` | - | Angle 0 |
| Hearthward bowl (cold, not interactive) | `(-22, 22)` | 6 | Mission 1's Brazier 1, unlit; a landmark on the lane |
| Spawn **SP_NE** (the lane) | `(-12, 12)` | - | On the lane (always clear); 37 m from the courtyard |
| Spawn **SP_E** | `(-9, 28)` | 3 | Mission 1's Lost Cache clearing (no cache tonight); 30 m |
| Spawn **SP_N** | `(-44, 10)` | **4 (M0 only)** | The one new clearing; 30 m |
| Emberguard entry **SP_SW** | `(-56, 56)` | - | Ashby and his riders at dawn |
Every spawn point is resolved with `NavigationServer3D.map_get_closest_point` at load; the build test fails if the
resolved point is more than **1.5 m** from the table value (then move the point, not the trees).
No crystal nodes, no peddler, no caches, no expansions, no Shadow buildings (Malrik's camp is off-map tonight).

**Why r 16 and not ep1's r 10**: at r 10 the three bowls sit 4-9 m from the start and the objective is done in 15 s.
At r 16 (all still inside the start clearing, so no tree check) they are 10-14 m out and 12 m apart: each one is a
short walk toward a side the knives come from, which is the lesson.

**Watch brazier** (`MissionBrazier`, unchanged rule): Vessa within **3 m for 3 s** lights it (progress ring; leaving
resets, damage does not); only Vessa; a lit brazier stays lit. On lighting it adds two things:
- **Light**: a `SightMarker` (group `"fog_sources"`, team PLAYER) of radius **23.3**, so after the night's x 0.6 it
  reads **r 14** (no contract change: the night scale is applied to it like any source).
- **Warmth**: every own unit within **6 m** regains **2 HP / s** (Vessa included; not the watch-keep). The mission
  ticks it every 0.5 s with `heal(1.0)`. Look: the flame light ring on the ground (19.V24), no real light.
- **Warning**: the side it faces (WB1 -> SP_N, WB2 -> SP_NE, WB3 -> SP_E) is **watched**: 10 s before a wave spawns
  there, a red minimap ping at the spawn point and the message `Knives from the north!` / `north-east` / `east` (3 s).
  An unwatched side gets no warning.

**Watch-keep** (`data/buildings/fire_watch_keep.tres`, a copy of `fire_keep`): display name `Emberfall Watch`,
**2 000 HP**, armor and attack as the tier-1 keep (12, shoots), `trainable_types` empty, not a drop-off, not a shop,
no tier button (no TierSystem in this mission), counts for defeat. Dressing (19.V24): bell tower, watch-fire with
emission, the `forge_watch_keep` set's language.

**Night** (19.V24 moonlight preset: the sun as a cold moon, no extra lights): `FogOfWar.sight_scale[PLAYER] = 0.6`
(the per-team array of `mission-02.md` blizzards; whichever of M9.S2 / 19.C7a lands first adds it). Enemy sight is not
scaled: the dark is theirs.

## Start state (right after V1, or the briefing on a retry)
| Item | Value |
|---|---|
| Vessa | **Level 2**, Fireball r1, Ember Step r1, 0 unspent points; **45 % HP** (169 of 375), full mana; **level cap 3** (at L3 she gets 1 point: Fireball r2 or Ember Step r2, `levels.md`) |
| Inventory | `items_locked = true`: the 6 slots and 2 artifact slots are hidden, no shop, no pickups. Nothing from the save applies |
| Crystals / essence | **0 / 0**, no income (`EssenceBank` trickle off); the resource counters are hidden in this mission |
| Buildings | The watch-keep (complete). No workers: the build menu never opens |
| Units | 4 Flame Guards + 4 watch archers (Ember Archers), veterancy 1; **Old Vey** (ally, not commandable, below) |
| Population | Counter hidden (9 of 9 if shown) |
| Enemy | Nothing on the map at 0:00 (the V1 assassins are "on the walls": A1 spawns at 0:15) |
| Camera | Centred on Vessa, Classic / RTS / Hero WASD all work as usual |
| Mission flags | `instant_loss_on_wizard_death = true`, `tiers_enabled = false`, `casters_enabled = false`, `helpers_enabled = false`, `tavern_enabled = false`, trade / river / points / camps / beasts / research / STR-INT off |

## Unlocks (what exists in this mission)
| Kind | Available | Locked (comes later) |
|---|---|---|
| Buildings | None (the keep cannot train, no workers) | Everything: the economy is taught in mission 1 |
| Units | The 8 escort soldiers only (no reinforcements until the Emberguard rides in at dawn) | All training |
| Keep / tier / caster | None (`tiers_enabled = false`, `casters_enabled = false`) | Stronghold and the Kilnwarden: mission 1 (`tiers.md` 6, `campaign-outline.md` D7) |
| Spells | Fireball (F), Ember Step (Q); a rank-up at L3 (Ctrl+F or Ctrl+Q) | Kindle (L4, mission 1) |
| Items / champions / helpers | None (`items_locked`; no tavern; `helpers_enabled = false`: Old Vey and Mother Hush are the story units below) | Items and shops mission 1; champions mission 3; Old Vey callable from Episode 2 (`campaign-outline.md` C3) |

## Allies and the mini-boss
### Old Vey (`torren_vey`, team PLAYER, not commandable): the fading storm (19.C11, brain 19.A2)
Model: the helper model `art/units/helpers/helper_vey/` with `set_look(&"m0")` (clean coat, runes flicker weak
blue-white). Clicking him = the read-only inspect card (`is_commandable()` false).
| Stat / ability | Value |
|---|---|
| HP / armor / speed / sight / aggro | 1 200 / 25 / 4.8 / 12 (x 0.6 at night = 7.2) / 10 |
| **Thunder-edged Blade** (attack) | 30 melee, range 2.0, cooldown 1.2; every 3rd strike a spark jumps to 1 more enemy within 3 m for 20 (`StormVfx` weak blue-white) |
| **Intercept** | Every 8 s, when an enemy that targets Vessa is within 10 m of him: a 0.2 s crackle blink next to it and `taunted` 3 s (the target must attack him) |
| Cannot die before the fall | At 1 HP he drops to one knee for 5 s (invulnerable, untargetable), then stands at 40 % HP |
| No XP, no level, no items | He gives no essence or XP to anyone; the mission removes him at `m0_fall` |
Brain (19.A2): stay 2-5 m from Vessa, between her and the nearest assassin; Intercept the nearest enemy targeting her;
never leaves the play area; while she stands lighting a brazier he holds 3 m in front of her, facing the nearest side.

### Mother Hush (`mother_hush`, team ENEMY, scripted): the knife that never misses (19.C12)
Model: `art/units/helpers/helper_hush/` (mask, two sickle knives, smoke cloak). Ability code reused from `hush_blink` /
`hush_smoke` with these story numbers; no veil passive, no Night of Knives in M0.
| HP | Armor | Attack | Speed | Sight / aggro |
|---|---|---|---|---|
| 900 (easy 700, hard 1 200) | 10 | 28 melee, range 1.6, cooldown 1.0 | 5.2 | 14 / 12 |
| Ability | Rule |
|---|---|
| **Blink Strike** | Every **10 s** (hard 8 s): picks the hero (Vessa or Vey) with the **lowest HP %** within 14 m (almost always Vessa); a violet ring r 1.5 appears at the target's feet for **0.5 s** (easy 0.8 s); she then appears behind the ring's centre and strikes for **50** (easy 35). **Dodge**: if the target is more than 2 m from the ring centre when it lands, she appears but the strike misses (Ember Step or a quick walk out of the ring). The lesson of the mission in one move |
| **Smoke** | Once, at 50 % HP: `shroud` 4 s and she withdraws 10 m away from Vessa, then comes back |
| **Flees** | At 25 % HP: invulnerable, walks to the nearest spawn point and despawns; never dies in M0; `sec_hush` done |
Not affected by Vey's Intercept for more than 3 s per 8 s (the taunt rule); immune to `chill` (no Ice here anyway).

## Objectives
| id | Type | Text (objectives panel) | Done when |
|---|---|---|---|
| `obj_dawn` | Primary | `Survive until dawn (8:00)` with the countdown `Dawn in 6:12` (19.U5) | The countdown ends **and** `obj_braziers` is done (then `m0_dawn`) |
| `obj_braziers` | Primary | `Light the watch braziers (0 / 3)` | 3 lit |
| `obj_vessa` | Primary, always shown | `Vessa must survive` | Fails = defeat |
| `sec_hush` | Secondary (appears at A3, 3:00) | `Drive off Mother Hush` | Hush below 25 % HP; **failed** if she is still on the field at 8:00 |
| `sec_guards` | Secondary | `Keep your escort alive (8)` (counts down) | At dawn, all 8 escort soldiers alive; **failed** at the first death |
States through `Events.objective_changed(id, state)`: `"active"`, `"done"`, `"failed"`.
**Dawn waits for the fires** (the braziers are the signal the Emberguard rides to): if the countdown ends with fewer
than 3 lit, `obj_dawn` reads `Light the last watch-fires: the Emberguard is looking for your signal`, the countdown
shows `0:00` in amber, and the **Dark hold** waves run (below) until the third is lit; then `m0_dawn` at once.

## Assassins: waves and behaviour (normal; easy x 0.6 and hard x 1.4 of every count, rounded, min 1)
All team `ENEMY`, group `"scripted"` and `"assassins"`, **no Commander, no bot** (no `ai.md` profile in this mission).
| Wave | Time | Units and spawn | Value |
|---|---|---|---|
| A1 | 0:15 | 4 Shades at SP_NE | 320 |
| A2 | 1:30 | 3 Grave Hounds at SP_E + 2 Shades at SP_N (two sides) | 370 |
| A3 | 3:00 | **Mother Hush** + 2 Shades at SP_N, 2 Shades at SP_E | ~720 (Hush ~400) |
| A4 | 5:00 | **The big push**: 3 Shades at SP_NE, 3 Shades at SP_N, 2 Nightbolts + 2 Grave Hounds at SP_E | 820 |
| Fall | 6:40 | `m0_fall`: 3 Shades teleported into the courtyard before the pause (they stay after it) | 240 |
| A5 | 7:00 | 5 Shades + 2 Nightbolts at SP_NE | 600 |
| Dark hold | Only after 8:00 while fewer than 3 braziers are lit: every 30 s | 3 Shades at the spawn of an **unlit** brazier's side (the darkest side first: N, NE, E) | 240 each |
| Dawn | 8:00 (+ the third brazier) | `m0_dawn`: every living assassin flees to SP_NE and despawns | - |
Behaviour (mission script, systems; no contract change):
- **Order**: attack-move to Vessa's position, refreshed every **3 s** (the mission 1 Final wave rule).
- **Knife focus**: every 1 s, an assassin with no `taunted` status that sees Vessa within **10 m** gets
  `command_attack(Vessa)`; otherwise the attack-move fights what it meets (escort, Vey). **Grave Hounds** always target
  Vessa when she is within 14 m (they are the knives' dogs). **Nightbolts** stop at 8 m and shoot.
- No leash, no retreat (Hush excepted) until dawn. Assassins ignore the watch-keep unless nothing else is in reach;
  the keep shoots them.
- XP and kill essence as normal kills (essence is not shown or kept; XP feeds Vessa's L3).

## Scripted events (in order)
| # | Trigger | Effect |
|---|---|---|
| E1 | 0:00 | Camera on Vessa; L1-L2; hint `Keep Vessa behind Old Vey's sword. Light the watch braziers to see the knives coming.` (10 s); `obj_dawn`, `obj_braziers`, `obj_vessa`, `sec_guards` active |
| E1b | Vey's first 3rd-strike spark (normally in A1) | L13-L14 |
| E2 | First watch brazier lit | L3; `obj_braziers` 1 / 3; hint `A lit brazier shows its side and warms whoever stands near it.` (6 s) |
| E2b | 3rd brazier lit | `obj_braziers` done; message `The watch-fires burn. The Emberguard will see them at dawn.` (5 s); if after 8:00, E10 at once |
| E3 | A2 spawns | L4 |
| E4 | A3 spawns | L5-L6; `sec_hush` active; hint `A violet ring means Hush is coming: Ember Step (Q) out of it.` (8 s) |
| E5 | Hush at 50 % HP | L7 (Smoke) |
| E6 | Hush at 25 % HP | L8; she flees; `sec_hush` done |
| E6b | Vessa reaches level 3 | Hint `Level 3: Ctrl+F ranks up Fireball, Ctrl+Q ranks up Ember Step.` (8 s) |
| E7 | A4 spawns | L9 |
| E8 | 6:00 | L10 (6 s) |
| E9 | 6:40 | Cutscene **`m0_fall`** (PAUSE, 0:35); then L11; Old Vey removed; **Grief's Fire** on Vessa: modifier `story:grief` `{"spell_power": 50, "mana_regen": 2}` for **80 s** (hands VFX, 19.V3); the crack decal goes to "sealed" |
| E10 | 8:00 with 3 braziers lit (or the 3rd brazier after 8:00) | If Hush is still on the field: L8 first and `sec_hush` failed. `sec_guards` resolves. Cutscene **`m0_dawn`** (HOLD, 0:30); `Events.mission_ended(true)` 2 s after it ends |
| E11 | Vessa dies | L12; `obj_vessa` failed; defeat after 3 s |
| E12 | Watch-keep destroyed | Message `The watch has fallen.`; defeat after 3 s |
The warnings of watched sides (Map, "Watch brazier") fire on their own, 10 s before each spawn. If two lines are due at
once they queue (dialogue box rule, 5 s each).

## Dialogue (14 lines; speaker ids from `Speakers.TABLE` / `data/voice/cast.json`; 5 s each unless listed)
Colours: Vessa `(1.0, 0.45, 0.1)`, Vey `(0.95, 0.95, 0.55)`, Mother Hush `(0.60, 0.50, 0.75)`. Speaker id **`vey`**
(`torren` is its alias in `Speakers.TABLE` and `cast.json`; both show "Vey" with the same voice).
| Line | Event | Speaker | Voice (cast.json) | Text |
|---|---|---|---|---|
| L1 | E1 | `vey` | daniel / lewis 0.85 | Stay behind my sword, girl. Knives hate a long reach. |
| L2 | E1 | `vessa` | af_heart 1.12 | I've been stabbed ONE time and I already hate it. |
| L3 | E2 | `vey` | | Good. Light pushes back the dark. Always has. |
| L4 | E3 | `vessa` | | Dogs! Why is it always dogs? |
| L5 | E4 | `hush` | af_alloy 0.92 | Hold still, little queen. It's kinder. |
| L6 | E4 | `vey` | | Over my dead body, knife-woman. |
| L7 | E5 | `hush` | | The old man bites. How charming. |
| L8 | E6 / E10 | `hush` | | Another night, little queen. There is always another night. |
| L9 | E7 | `vessa` | | How many knives does one Bishop OWN? |
| L10 | E8 | `vey` | | Two more hours, girl. Dawn always comes. It's the one thing it's good at. (6 s) |
| L11 | E9 (after `m0_fall`) | `vessa` | | You want me? Come and get me. ALL of you. |
| L12 | E11 | `vessa` | | Vey... I'm sorry... |
| L13 | E1b | `vessa` | | You're going to explain the lightning. (4 s) |
| L14 | E1b | `vey` | | Later. Duck. (3 s) |
Cinematic lines (subtitles of the two engine cutscenes, ep1 7.2; the Voice Forge renders them in the same file):
| Line | Cutscene / shot | Speaker | Voice | Text |
|---|---|---|---|---|
| C1 | `m0_fall` 2 | `vey` | | Vessa, MOVE! |
| C2 | `m0_fall` 4 | `vessa` | | VEY! |
| C3 | `m0_fall` 5 | `vessa` | | ...Malrik. |
| C4 | `m0_dawn` 1 | `narrator` | am_michael 1.0 | Dawn came to Emberfall, and so did the Emberguard. |
| C5 | `m0_dawn` 3 | `ashby` | am_eric 1.0 | My queen! You're hurt- |
| C6 | `m0_dawn` 3 | `vessa` | | I'm not the one who's hurt, Captain. |
| C7 | `m0_dawn` 4 | `vessa` | | Get the army up. We take the crown today. |
Voice file: `data/voice/lines/m00.json` (the `ep2_opening.json` format: `id`, `speaker`, `dur`, `subtitle`, `text`;
mission lines have no `shot` / `t`). Every line fits its slot at its cast speed (L10 is the long one: 6 s).

## Cinematic hooks
| Id | Kind | When | Length | Actors, marks | End state (a skip must leave exactly this) |
|---|---|---|---|---|---|
| `ep1_intro` (V1) | VIDEO, later production | New episode, before M0 | 2:00 | ep1 7.2 | Until the video exists: the fallback text card (ep1 7.4, 10 s, skippable); then the mission loads at 0:00 |
| `m0_fall` | ENGINE, **PAUSE** | E9, 6:40 | 0:35 | Teleports at `at == 0`: Vessa `(-36, 39)` (on the seam), Vey `(-34, 40)`, 3 new Shades `(-32, 37)`, `(-33, 35)`, `(-31, 39)`. Escort, other assassins and projectiles stay where they are (frozen) | Vey despawned (no death event, no XP); Vessa at `(-37.5, 40.5)` (pushed clear), standing, HP unchanged; the 3 Shades alive at their marks with orders to attack Vessa; the seam decal `sealed`; Grief's Fire applied on control return; L11 queued |
| `m0_dawn` | ENGINE, **HOLD** | E10 | 0:30 | Spawns Captain Ashby (19.V11, mounted variant) + 4 Blaze Riders (team PLAYER, no orders, not commandable during the HOLD) at SP_SW; every living assassin walks to SP_NE (actor move, then despawn) | No assassin left; Ashby and riders by the courtyard; dawn preset fully on; then victory after 2 s |
| Theatre unlocks | - | M0 won | - | - | `helper_vey` and `helper_hush` reveals (`t3-helpers.md` 10.3) unlock in the Theatre (their campaign moment is M0) |
Lighting: moonlight from 0:00; during `m0_dawn` shot 1 the 19.V24 dawn preset fades in over 6 s and stays on.

## Win / lose
| Event | Result |
|---|---|
| `obj_dawn` done (8:00 + all 3 braziers lit) | **Victory** after `m0_dawn` (`Events.mission_ended(true)`) |
| Vessa dies | **Defeat** (instant loss, no respawn) |
| Watch-keep destroyed | **Defeat** (rare: assassins do not aim at it) |
| All 8 escort soldiers dead, Vessa alive | Nothing; `sec_guards` failed; she can still see the dawn |
| Hush not driven off | Nothing; `sec_hush` failed at 8:00 |

## Reward carried to mission 1
- No items, no essence, no artifact, no level (nothing is carried: the night only sets flags).
- `CampaignState.MISSION_REWARDS[&"m00"] = {"flags": {"m0_hush_driven": "sec_hush", "m0_escort_saved": "sec_guards"},
  "next": &"m01"}`; `MISSION_ORDER = [m00, m01, m02, m03, m04]` (19.C2; m00 and m01 both unlocked by default).
- `m0_escort_saved`: mission 1 starts with **+2 Flame Guards** at `PLAYER_START + (4, -4)` ("the ones who stood with
  you", pop 13 / 20; ep1 5.1 row 3). `m0_hush_driven`: no gameplay effect in Episode 1 (Ep2 / Ep3 may greet it).
- Story flow (ep1 4.2): victory -> mission 1 briefing -> mission 1.

## Difficulty notes
| | Easy | Normal | Hard |
|---|---|---|---|
| Wave counts (A1-A5, Fall, Dark hold) | x 0.6 (A1 2 Shades, A4 6 units) | as written | x 1.4 (A1 6 Shades, A4 14 units) |
| Vessa start HP | 60 % | 45 % | 35 % |
| Mother Hush HP / Blink cooldown / telegraph / damage | 700 / 10 s / 0.8 s / 35 | 900 / 10 s / 0.5 s / 50 | 1 200 / 8 s / 0.5 s / 50 |
| Brazier warmth | 3 HP / s | 2 HP / s | 1.5 HP / s |
| Old Vey, Grief's Fire, the clock | same | same | same |
| Expected time | 9-12 min | 9-12 min | 9-12 min (+ up to 1 min if the fires are late) |
- **Fight sizing** (normal; the episode rule: every guarded fight <= 70 % of the player's force at that time). The
  player's force: escort 760 crystals + Old Vey (~600: 1 200 HP, ~30 DPS, Intercept) + Vessa = ~1 360 + Vessa.
  A1 320 (24 %), A2 370 (27 %), A3 ~720 (53 %), A4 **820 (60 %)**: A4 vs the escort + Vessa + Vey must be survivable
  with the 3 braziers lit and Ember Step used well, losing **~2-4 escort soldiers** on normal (ep1 5.0). Without the
  fires (no warning, no warmth) A4 should cost 4-6 and often Vessa.
- **A5 + the Fall Shades (840) is above the rule on purpose**: Vey is gone and the escort is down to ~4-6, but Grief's
  Fire makes each Fireball hit for 110 (cooldown 3 s; +2 mana / s on top of her regen pays for one cast every ~6 s
before her pool runs dry, so she can open with a burst). Two good Fireballs kill a clump
  of 110 HP Shades. Expected 1-2 more losses. If the playtest shows deaths here, cut A5 to 4 Shades + 2 Nightbolts.
- **Vessa's margin**: 169 HP at the start. Each Blink Strike is 50; the dodge (Ember Step or 2 m of walking in 0.5 s)
  and Vey's Intercept are the answers; brazier warmth (2 HP / s, ~100 s to full) and the L3 level-up (+25 HP healed)
  are the way back up between waves. A player who stands still in the open at 3:00 is meant to die once.
- `sec_guards` (all 8 alive) is the hard secondary: expected on easy, rare on normal, a challenge on hard. It pays off
  in mission 1 (+2 Flame Guards), so it matters but never blocks.
- The fixed 8:00 means the time does not change with difficulty; only the Dark hold can extend it, and it is the
  player's choice (light the fires).

## Target length (normal)
| Part | Time |
|---|---|
| V1 `ep1_intro` (or its fallback card) | 2:00 (0:10) |
| The night (`mission_time`) | 8:00 |
| `m0_fall` + `m0_dawn` + 2 s | 1:07 |
| **Total** | **~11:07** with V1 (~9:17 with its fallback card), inside the 9-12 min target |

## Implementation tasks (step 19; the lead adds them to `waves.md`)
| Id | Owner | What | Needs | Done when |
|---|---|---|---|---|
| 19.C2 | systems | (exists) `MissionBase` with `hold_world()`, `mission_time()`, `MISSION_ORDER` with `m00`, `MISSION_REWARDS[&"m00"]` | - | ep1 9 |
| **19.C7a** | systems | Scene `missions/mission_00.tscn` + `mission_00.gd` map part: seed 1101 with mission 1's clearings + SP_N clearing as a filter; the 2 bound walls baked; `camera_bounds`; the watch-keep type `fire_watch_keep.tres` (2 000 HP, no training, no tier button); 3 watch braziers (`MissionBrazier`) with light marker r 23.3, warmth 2 HP / s r 6, side warnings; the cold Hearthward bowl; start state (Vessa L2 45 %, cap 3, items locked, economy hidden, escort, Vey, flags off); `FogOfWar.sight_scale[PLAYER] = 0.6` (adds the array if M9.S2 has not) | 19.C2 | Test `tests/test_19_c7a.gd`: every spawn point resolves within 1.5 m of its table value; no navmesh path from `(-38, 40)` reaches x > -7 or z < 7; Vessa 169 / 375 HP, level 2, cap 3; a brazier lit by Vessa in 3 s (reset on leaving) heals a Flame Guard at 5 m by 2 HP / s and not at 7 m; a Shade at 13 m from a lit brazier is visible, at 9 m from Vessa alone it is not |
| **19.C7b [H]** | systems-high | Objectives and events E1-E12 in order; waves A1-A5, Fall, Dark hold with scaling and spawn sides; knife focus (1 s), Hound and Nightbolt rules, 3 s attack-move refresh; dawn waits for the fires; Grief's Fire modifier; win / lose; difficulty table; rewards and flags | 19.C7a, 19.C11, 19.C12 | Scripted headless run on normal (light the 3 fires by 3:00, fight at the courtyard) survives to dawn with `victory=true` at mission time 8:00 (+ cutscenes) and Vessa alive, in 5 / 5 seeds; a run that lights only 2 fires gets Dark hold waves every 30 s after 8:00 and wins 2 s after `m0_dawn` once the 3rd is lit; Vessa killed = defeat after 3 s; saved flags match `sec_hush` / `sec_guards` |
| 19.C11 [H] | gameplay-high | (exists) `torren_vey` M0 kit: Blade + 3rd-strike spark (20, 3 m), Intercept (8 s, taunt 3 s), kneel at 1 HP 5 s -> 40 %; helper model with `set_look(&"m0")` | - | ep1 9 test, M0 part |
| 19.C12 | gameplay | (exists) Mother Hush: Blink Strike (ring 0.5 s, 50, lowest-HP % hero within 14 m, **miss if the target is > 2 m from the ring**), Smoke at 50 %, flee at 25 %; difficulty values from the table above | - | ep1 9 test + the dodge: a Vessa that Ember Steps 6 m during the ring takes 0 |
| 19.A2 | ai | (exists) Old Vey's brain in M0: 2-5 m from Vessa, between her and the nearest assassin, Intercept, holds in front of her while she lights a brazier | 19.C11 | ep1 9 test |
| 19.C9 (M0 part) | systems | `m0_fall` (PAUSE) and `m0_dawn` (HOLD) as `data/cinematics/m0_fall.tres` / `m0_dawn.tres` with the marks and end states of "Cinematic hooks" | 19.C1, 19.C7b | Test: skipping each leaves the exact end state of a full play (Vey gone, Vessa at `(-37.5, 40.5)`, 3 Shades alive, Grief's Fire on; dawn: no assassin, victory 2 s later) |
| 19.U5 (M0 part) | ui | Dawn countdown in the objectives panel (`Dawn in m:ss`, amber `0:00` during the Dark hold), side-warning ping + message, hidden resource counters and inventory when `items_locked` | 19.C7a | Readable at 1600 x 900 and 3440 x 1440; hidden during cinematics |
| 19.U1 / 19.U3 | ui | (exist) overlay and portrait dialogue: `vey`, `hush`, `ashby` names, colours and portraits | - | ep1 9 |
| 19.V24 | tech-artist | (exists) Emberfall night kit: moonlight + dawn presets, watch-keep dressing, 3 watch braziers (with the warmth ring), courtyard crack (closed / opening / sealed), cold Hearthward bowl | - | `PERF OK` with A4 on screen at night |
| 19.V3 / 19.V25 (M0 parts) | tech-artist | Hush's Blink ring and smoke; Grief's Fire hands; Vey's weak blue-white blade sparks and spark jump; Intercept crackle-blink | - | 0 lights, <= 2 particle systems per effect |
| 19.V11 | tech-artist | (exists) Captain Ashby, mounted variant for `m0_dawn` | - | Art Lab pass |
| **19.VO0** | Voice Forge agent | Render `data/voice/lines/m00.json` (L1-L14, C1-C7) with the cast voices above | Lines frozen by 19.D3 | Every WAV fits its `dur` |
| 19.D3 (M0 part) | game-designer | Read the 14 + 7 lines in game, trim any over 2 lines of the box; check A4 losses and Vessa deaths from the first playtest, adjust A4 / A5 / warmth here | Playtest | Changes written back into this doc |

## Done when
- [ ] 19.C7a: Emberfall Watch builds from seed 1101 with mission 1's trees untouched outside the SP_N clearing; spawn points resolve within 1.5 m; the bound walls stop every path at x -7 / z 7; watch-keep 2 000 HP, shoots, trains nothing; 3 watch braziers at r 16 (`(-43, 27)`, `(-32, 32)`, `(-27, 43)`) light in 3 s within 3 m, reset on leaving, give r 14 light at night, 2 HP / s warmth within 6 m and the side warnings; start state as the table (Vessa L2, 169 / 375, cap 3, items locked, no economy, 8 escort, Vey).
- [ ] 19.C7b: E1-E12 fire in order on a scripted normal run; A1 0:15, A2 1:30, A3 3:00, A4 5:00, Fall 6:40, A5 7:00 with their counts and sides (easy x 0.6, hard x 1.4, min 1); knife focus within 10 m, Hounds within 14 m; dawn waits for the third fire and the Dark hold runs meanwhile; Grief's Fire +50 spell power / +2 mana regen for 80 s; victory 2 s after `m0_dawn`; defeat on Vessa's death or the keep's fall; `m0_hush_driven` / `m0_escort_saved` saved; mission 1 started after a win with `sec_guards` done has 2 extra Flame Guards.
- [ ] 19.C11 / 19.C12 / 19.A2: Vey's spark, Intercept, kneel-and-return; Hush's Blink (and its 2 m miss rule), Smoke, flee at 25 %; Vey stays within 8 m of a walking Vessa.
- [ ] 19.C9: `m0_fall` and `m0_dawn` play and skip with the same end states; the mission clock does not run during them.
- [ ] 19.U5 / 19.U3 / 19.V24 / 19.V3 / 19.V25 / 19.V11: countdown, warnings, portraits, night kit, effects and Ashby in game; `PERF OK` with A4 on screen at night.
- [ ] 19.VO0: the 21 lines rendered; each fits its slot.
- [ ] Lead: a scripted headless run on normal ends `victory=true` at mission time 8:00 with Vessa alive in 5 / 5 seeds and loses **2-4** escort soldiers in A4 on at least 3 of 5 (the fight-size check); total play time with V1's fallback card 9-12 min.

## Spotlight (`unit-spotlights.md`)
The one unit this mission shows at its best (framework hook: `mission-framework.md` 7).
- **Unit:** Flame Guard.
- **Why here:** the 4 escort Guards against Grave Hounds that always dive Vessa (hounds are weak against line infantry); braziers heal +2 HP/s; Lab 72 / 74 / 81.
- **Moment:** A2 (1:30): hint + ring on the courtyard gate "Stand the Guards between Vessa and the gate.".
- **Intro card:** `Flame Guard. Shields first, spark second: a Guard wall keeps the knives off Vessa.`

# The bot: Malrik plays the Shadow side of the 1v1 (wave 2)

Source of truth for 2.A1. Rewritten 2026-09-25 (task 2.D1): the bot is a **player**, not a wave spawner.
It has the same start as the player (`skirmish-1v1.md`), the same economy, buildings and pop rules, and it
only calls public APIs (`command_*`, `Economy`, `Keep` / `Building` queues, `BuildGrid.check` / `place`,
`Wizard.command_cast`). **It never cheats crystals** at any difficulty; hard is only faster and more precise.
One `Commander` node per bot team in `scripts/ai/commander.gd`, knobs in `data/ai/<difficulty>.tres`
(`AIProfile` resource). It thinks on a timer every `decision_interval` seconds, never in `_process`.
Metres, seconds, `m:ss` = time since the navmesh was ready. Positions `(x, z)`.

Ice and Nature bots (Steps 7-8): same rules with the differences in `kingdom-ice.md` section 7 and
`kingdom-nature.md` section 6 (profiles, build slots, unit mix, retreat, wizard cast rules, item lists).

## What the bot knows (no map hacks for the army)
- It knows the map (nodes, its slots, the crown, where the enemy keep is: the mirror of its own).
- It does **not** know where enemy units are unless it **sees** them: an enemy unit or building is *seen* when
  within **16 m of a bot unit** or **20 m of a bot building** (wave 3: replaced by the fog-of-war visibility).
- Memory: `seen: Dictionary` unit id -> `{ type, pos, time }`, refreshed each tick for seen things, entries
  dropped after `memory_seconds`. `seen_strength` = sum of `strength` of remembered enemy soldiers and towers.
- **Strength** of a unit = its `UnitType.cost` (workers 0); a wizard = 200; a tower = 120; a Ruin Warden = 100.
  Wave 3 (`levels.md`, 3.A1): a wizard = `170 + 30 x level`, a soldier = `cost x (0.8 + 0.2 x level)` (same
  values at level 1); a dead Vessa leaves `seen_strength`; `malrik_joins` also when Malrik is level 4+.
  `own_strength` = strength of the bot's living soldiers (not workers, not Malrik, not towers).

## Fixed slots (Shadow side; the Fire mirror is the same offsets from the Fire keep, for a Fire bot later)
| Slot | Building | Centre | Offset from own keep |
|---|---|---|---|
| H1 | Gloom Hall | `(27, -45)` | `(-16, -2)` |
| V1 | Hovel 1 | `(50, -46)` | `(7, -3)` |
| V2 | Hovel 2 | `(50, -52)` | `(7, -9)` |
| S1 | Night Spire 1 | `(37, -29)` | `(-6, 14)`, covers node a and the lane |
| S2 | Night Spire 2 | `(25, -37)` | `(-18, 6)`, covers the hall and node b |
| X1 | Forward Gloom Hall (expansion, drop-off for `node_shadow_mid`) | `(23, -9)` | next to the natural node |
| Rally | Army gathers here | `(30, -30)` | on the lane, 18 m from the keep |
| Anchor | Malrik idles here | `(36, -36)` = `SHADOW_START` | |
If `BuildGrid.check` refuses a slot (a unit stands there), retry every 5 s; after 3 refusals try the slot
shifted by `(0, 4)`, then `(4, 0)`.

## The rules (evaluated in this order, every tick; at most one placement and one queue per tick)
### 1. Defend
| Trigger | Action |
|---|---|
| An enemy soldier or wizard within **28 m** of any bot building, or a bot building / worker takes damage | After `reaction_delay`: every soldier at the rally, the reserve and Malrik (if HP >= 35 %) `command_attack_move` to the intruder; workers within 10 m of an enemy soldier `command_move` to the keep drop-off |
| Intruders' strength > 1.5 x the strength at home and an attack group is out | Recall the attack group (`command_move` to the rally, then it defends) |
| No enemy within 28 m of any building for 15 s | Defenders `command_move` back to the rally, workers `command_gather` their node, Malrik to his anchor |

### 2. Retreat (attack group only)
The group retreats (`command_move` to the rally, units still retaliate) when **either**: its total HP < **40 %**
of its HP at launch, or the seen enemy strength within 15 m of the group's centre > **1.5 x** the group's
remaining strength. The attack is over when the group reaches the rally; the next attack needs the rule 7 again.

### 3. Economy
| Rule | Value |
|---|---|
| Worker target | `worker_target_home` (6) until the forward hall is completed, then `worker_target_expanded` (9) |
| Queue a Gloom Thrall when | workers + queued < target and crystals >= 50 and the keep queue is empty and no build is waiting (see the 20 s rule) |
| Assignment | A new worker gathers the own node with fewer than 3 workers nearest to the keep; the natural node only once X1 is completed. A node at 0 sends its workers to the own node with the fewest workers |
| Expansion trigger | Home nodes a + b together < **700** crystals left, **or** 6:00, whichever first; **and** crystals >= 150 **and** no attack group is out **and** the camp at the crown is dead or `own_strength >= 400` |
| Expansion | Place X1; the 2 workers nearest build it; on completion the 3 newest workers (or newly trained ones) gather `node_shadow_mid` and deliver to X1. X1 destroyed: those workers go home |
| Worker under attack | Flees to the keep drop-off, `command_gather` again after 6 s without damage |

### 4. Build (one construction site at a time; a build never starves training more than 20 s)
| # | Building | Trigger |
|---|---|---|
| 1 | Gloom Hall (H1) | 0:00 (250 >= 150). One worker builds, the two others keep mining |
| 2 | Hovel 1 (V1) | `pop_used + queued >= pop_cap - 4` and crystals >= 80 |
| 3 | Night Spire 1 (S1) | Base intruded at least once (rule 1 fired) and crystals >= 120; else at 5:00 |
| 4 | Hovel 2 (V2) | Same rule as 2 (only once cap is 30) |
| 5 | Forward Gloom Hall (X1) | Rule 3 expansion trigger |
| 6 | Night Spire 2 (S2) | A second intrusion at least 2:00 after the first, or 8:00; crystals >= 120 |
| Rebuild | Any destroyed building | Its own row again; **a barracks has priority over everything** when none is alive |
The **20 s rule**: when a triggered build has waited for crystals for 20 s, the bot trains one unit, then waits
for the build again. `build_delay` (difficulty) is added between a trigger and the placement.

### 5. Train (Gloom Hall queue, or X1 too when it exists: whichever queue is shorter)
- Queue when the queue has fewer than `queue_depth` units, crystals >= cost and `pop_used + pop <= pop_cap`.
- Pick the type whose current share of soldier pop is the furthest **below** its target share. Shadow Knight
  only when crystals >= 300 and soldier pop >= 8. New units `command_move` to the rally and hold there.
| Seen in the last `memory_seconds` | Shade | Nightbolt | Grave Hound | Shadow Knight |
|---|---|---|---|---|
| Default (nothing seen, or a mix) | 40 % | 30 % | 15 % | 15 % |
| Ranged >= 50 % of seen enemy soldier pop (Ember Archer, Ash Hurler) | 30 % | 15 % | 40 % | 15 % |
| Melee >= 60 % (Flame Guard, Blaze Rider) | 25 % | 45 % | 10 % | 20 % |

### 6. Scout
- Every `scout_interval`, if no scout is out: the cheapest idle soldier at the rally (a Grave Hound if any;
  before 1:30 a worker) walks the waypoints `(16, -6)` -> `(6, 16)` -> `(-16, 6)` -> `(-27, 27)` -> rally
  (`command_move` each, never attack-move; stays >= 12 m from the crown while the camp lives). Everything it
  passes within 16 m enters `seen`. It comes home at once if HP < 50 %.
- Every 60 s the bot also marks the **enemy keep** and the enemy mirror slots as "seen buildings" only if a
  bot unit really saw them; it never counts what it has not seen.

### 7. Attack
Launch when **all** hold: no attack group out, no defence running, army pop at the rally >= `min_attack_pop`,
>= 80 % of the army within 12 m of the rally, and
`own_strength >= attack_ratio x max(seen_strength, 250)`. Launch **anyway** when `pop_used >= pop_cap - 2`
(nowhere to grow).
| Target, first that applies | Orders |
|---|---|
| The crown camp lives and `own_strength >= 350` and the crown is unclaimed | `command_attack_move((0, 0))`; when the 4 Ruin Wardens are dead Malrik takes the crown (rule 8), then the group continues to the next row's target |
| A seen enemy building within 40 m of the crown (the player's forward hall / spire) | `command_attack_move` to it |
| Otherwise | `command_attack_move((0, 0))` then, when 4+ units are within 10 m of it or 40 s passed, `command_attack_move` to the enemy keep `(-43, 43)`; once no enemy building is seen there, to the nearest seen enemy building |
- The group = every soldier at the rally except the **reserve**: the 2 soldiers with the highest HP (0 on hard
  when `pop_used >= pop_cap - 2`). Towers always stay.
- In the enemy base the group targets **units first, then buildings** (unit rule); the bot adds
  `command_attack` on the barracks for the 3 nearest units when no enemy unit is seen within 12 m.

### 8. Malrik
| Situation | Action |
|---|---|
| Idle | Stands at the anchor (auto-aggro, 2x leash). Joins every defence (rule 1) when HP >= 35 % |
| Attacks | Joins when `malrik_joins` says so (normal: from the 2nd attack, or when `own_strength >= 800`); follows the group centre 4 m behind (`command_move` to it each tick); casts by his rules (wave 2: Shadow Lance rules 1-4 of `units-fire-shadow.md`; wave 3: `spells.md` rules 1-4) |
| HP < 35 % | (wave 3: Umbral Shroud first) `command_move` to the keep; stays within 15 m of it (home healing 1 % / s) until HP >= 70 % or 60 s, then back to the anchor |
| The crown | When the camp is dead, no enemy soldier within 12 m of `(0, 0)`, the crown is unclaimed or lying dropped, and Malrik's HP >= 60 %: `command_move((0, 0))`; abort (back to the group or anchor) if an enemy soldier comes within 12 m |
| Dead | Rule 8 pauses; on respawn he waits at the anchor for 20 s before joining anything |

## Difficulty (`data/ai/easy.tres`, `normal.tres`, `hard.tres`; 2.A1 ships normal, the others load from the same fields)
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `decision_interval` | 2.0 | **1.0** | 0.5 |
| `reaction_delay` (before acting on an intrusion or a first sighting) | 4.0 | **1.5** | 0.5 |
| `build_delay` (trigger -> placement / queue) | 15 | **3** | 0 |
| `worker_target_home` / `worker_target_expanded` | 4 / 6 | **6 / 9** | 6 / 9 |
| `queue_depth` | 1 | **2** | 2 |
| `attack_ratio` | 1.8 | **1.3** | 1.1 |
| `min_attack_pop` | 8 | **6** | 5 |
| `memory_seconds` | 60 | **120** | 180 |
| `scout_interval` | 240 | **120** | 90 |
| `malrik_joins` | never | **2nd attack or strength >= 800** | every attack |
| `income_mult` | 1.0 | **1.0** | 1.0 (no cheating at any level) |

## Expected timeline (normal, player passive)
| Time | State |
|---|---|
| 0:00 | Gloom Hall site at H1 (1 builder), 2 thralls queued (100 -> 0 crystals) |
| 0:45 | Hall done; 6 workers by ~1:00; income ~420 / min |
| 1:05 | First Shade; then a unit every 15-20 s |
| 2:00 | Scout (a worker, then a hound) walks the loop |
| 3:30 | First attack: ~6 units (own_strength ~500 >= 1.3 x 250) attack-move to the crown camp |
| 4:00-4:30 | Camp dead, Malrik wears the crown; group continues to the Fire keep or retreats at 40 % HP |
| 3:40 / 6:00 | Hovel 1 (pop 16) / Hovel 2 |
| 5:00-6:00 | Expansion X1 at the natural node (home nodes < 700 or 6:00) |
| 8:00+ | Attacks whenever strength >= 1.3 x what it saw; pop up to 40 |

## Performance and structure
- One think tick < **0.3 ms** with 200 units (perf test stays `PERF OK`): iterate the `"units"` and
  `"buildings"` groups once per tick, cache the lists, no per-unit raycasts.
- Suggested pieces: `commander.gd` (timer, rules 1-8 in order), `ai_profile.gd` (the knobs),
  `ai_memory.gd` (the `seen` dictionary). A `Commander` can be given any team and keep for PvP tests.
- Debug: `Commander.debug_log: bool` prints one line per decision (`[3:31] ATTACK 6 units str 500 vs seen 0`).

## Done when
- [ ] 2.A1: from the 1v1 start (250 crystals, keep, 3 thralls, Malrik), a headless run on normal shows: Gloom Hall placed at `(27, -45)` at 0:00 and completed by 0:50; 6 workers by 1:10; first Shade by 1:15; Hovel 1 placed when pop >= 16; first attack launched between 3:00 and 4:30 with >= 6 pop, logged with strength vs seen.
- [ ] 2.A1: an enemy unit within 28 m of a Shadow building makes the rally units attack-move to it after 1.5 s; the attack group turns back under 40 % HP; a destroyed Gloom Hall is rebuilt before anything else.
- [ ] 2.A1: `seen_strength` is 0 until a bot unit comes within 16 m of a player unit; a unit type share follows the mix table (test: 20 archers placed near the scout path -> the next 4 units queued include >= 2 Grave Hounds).
- [ ] 2.A1: Malrik retreats to the keep under 35 % HP and returns at 70 %; takes the crown when the camp is dead; the bot concedes per `skirmish-1v1.md`.
- [ ] 2.A1: the three profiles change only the knobs above; `PERF OK` with the bot running; nothing in `scripts/ai/` calls a `_private` function of another script.

# Economy: crystals, workers, keep, population (wave 1)

Source of truth for tasks 1.S1 (nodes and gathering), 1.S2 (keep training, rally), 1.S3 (population), 1.U1 (top bar).
One `Economy` per team (contract in `CLAUDE.md`). Start: **250 crystals, 3 workers, cap 20** (decided).

## Crystal nodes
| id | Position (x, z; y = 0) | Crystals | Notes |
|---|---|---|---|
| `node_home_a` | `PLAYER_START + (-10, -2)` | 600 | 9.5 m from the keep |
| `node_home_b` | `PLAYER_START + (2, 10)` | 600 | 9.5 m from the keep |
| `node_mid` | `MID_CAMP + (4, 4)` | 900 | Contested; guarded by the mid camp |
| `node_ruins` | `ARTIFACT_POS + (6, -7)` | 900 | Shadow's node; unused until the wave 3 AI |

- Look: 3 crystal prisms (`PrismMesh` or tall `BoxMesh`, heights 1.6 / 1.2 / 0.9), colour `(0.45, 0.85, 1.0)`, emission 1.5, on a rock disc radius 1.2.
- Collider: cylinder radius 1.2, layer 1 (an obstacle for the navmesh, like rocks). Group `"crystal_nodes"`.
- Node scale shrinks linearly from 1.0 (full) to 0.5 (last crystal). At 0 it plays a 0.5 s shrink and is freed; workers on it look for another node within 30 m, else stop.
- Public API: `crystals_left`, `can_mine(worker) -> bool`, `take(amount) -> int` (returns what was really taken).
- Max **3 workers mining at once** per node; extras wait 1.5 m away and take the next free spot (wave 1: fine if they just stand at the edge).

## Workers gathering (Cinder Hand)
| Step | Value |
|---|---|
| Walk to node (stop at node radius + own radius + 0.3) | `move_speed` 4.6 |
| Mine | **4.0 s**, then carry **10 crystals** (or what is left) |
| Walk to the keep (drop-off point below) | 4.6 m/s |
| Drop-off | Instant on arrival: `Economy.add(carried)`, then walk back to the same node |

- Order: right-click a node, or G then click a node. A worker carrying crystals that gets a move order keeps them and delivers them on its next drop-off.
- While carrying, show a small crystal (0.25 m, same colour) above the worker's back.
- Mission start: the 3 workers are spawned with a gather order on their nearest home node (2 end up on `node_home_a`, 1 on `node_home_b`; either split is fine).
- Expected income: about 8.5 s per trip, ~70 crystals / min per worker, ~210 / min with 3.

## Keep
- Existing keep box at `PLAYER_START + (-7, 7)`, size 5 x 6 x 5. Becomes selectable (layer 2, group `"buildings"`, `team` PLAYER, `max_hp` 1500, no attack). Left-click selects it alone (it never joins a unit box selection).
- **Drop-off point**: `keep_position + (3.5, -3.5)` (the corner facing `PLAYER_START`).
- **Spawn point**: same as drop-off. New units then walk to the rally point.
- **Rally point**: default `keep_position + (6, -6)`. Right-click the ground with the keep selected sets it; right-click a crystal node sets a "gather" rally (new workers start mining it). Shown as a small flag: pole 1.2 m, triangle in the Fire colour, visible only while the keep is selected.

## Training queue (task 1.S2)
| Rule | Value |
|---|---|
| Queue length | **5** max; a 6th click shows "Queue is full" |
| Pay | Crystals **and** population are reserved when the unit is queued |
| Cancel | Click the queue slot in the selection panel: full refund of crystals and pop; cancelling slot 1 loses the progress |
| Progress | Only slot 1 trains; `train_time` from the unit table; slot 1 shows a progress bar |
| Blocked | "Not enough crystals" (button disabled) / "Population cap reached" (button disabled). Buttons re-enable live |
| Spawn | At the spawn point; if it is occupied the unit is pushed aside by avoidance (no extra logic) |

## Population (task 1.S3)
| Unit | Pop |
|---|---|
| Workers, Flame Guard, Ember Archer, Ash Hurler, Shade, Nightbolt, Grave Hound | 1 |
| Blaze Rider | 2 |
| Shadow Knight | 3 |
| Vessa, Malrik | 0 |

- `pop_cap` = 20 (one keep; more keeps or houses come with wave 2 buildings, cap never above 20 in wave 1).
- **Pop 200 (2026-09-27, JS playtest request)**: the hard cap `Economy.MAX_POP_CAP` is **200 for every kingdom**
  (was 40, Nature 50; `KINGDOM_POP_CAPS` is empty but still lets a kingdom have its own cap). Keep **+20**; every
  house (Hearth, Hovel, Snow Lodge, Seed Hollow) gives **+20** and `max_count` is **9** per team for every kingdom:
  keep + 9 houses = 200 (40 after 1 house, 100 after 4, 200 after 9). House cost / build time unchanged (Nature's
  Seed Hollow stays the cheap one: 60 crystals, 20 s). Missions: mission_01 sets no cap of its own, so it uses the
  same rule (its bot only builds V1 / V2).
- The bot (`scripts/ai/commander.gd`): house rows V1-V9 (V4-V9 behind the base, find_spot fallback); a house row
  triggers when `pop_used >= pop_cap - max(4, pop_cap / 10)` and the previous V row is finished, until the cap is
  200. The caravan rules (pop_used + 1 <= pop_cap - 2; F4 cut below 45 % soldier pop at the cap) and
  `attack_full_pop` are relative / army-size knobs and are unchanged.
- `pop_used` = living units + queued units. A unit's death frees its pop when `died` fires.
- A unit can be queued only if `pop_used + pop <= pop_cap`.

## Top bar (task 1.U1, exact layout in `ui-hud.md`)
Shows `crystals` (integer) and `pop_used / pop_cap`. Both update on `Economy.changed`. Pop turns red at cap; crystals flash red for 0.4 s on a failed `spend`.

## Done when
- [ ] 1.S1: the 4 nodes exist at the positions above with those amounts; a worker ordered on a node loops mine 4 s -> carry 10 -> drop at the keep -> back; 3 workers on one node bring about 210 crystals in the first minute of a headless run; a node at 0 disappears.
- [ ] 1.S2: keep selectable; queue of 5 with reserve-on-queue and full refund on cancel; slot 1 trains with `train_time`; new units walk to the rally; rally set by right-click, gather-rally on a node.
- [ ] 1.S3: pop 1 / 2 / 3 / 0 per the table; queueing over 20 is refused; mission 1 starts at 12 / 20; a unit death frees pop.
- [ ] Test script: start 250, queue 2 Flame Guards -> 70 crystals and 14 / 20, cancel one -> 160 and 13 / 20.

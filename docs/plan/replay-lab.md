# Replay Lab (Labs program item 3)

Record a skirmish's commands + seed, replay it deterministically (headless verify or windowed watch), save bug-repro
bundles (also from the laptop), watch bot games. Built 2026-09-26 (tools / engine agent).

## Files

| File | What |
|---|---|
| `scripts/core/replay/replay_hooks.gd` | The ONLY replay file game code touches (preload, tiny, stable): `note(kind, args, selection)`, `rebake_mode()`, `match_started(level)`, statics `session`, `auto_record`, `bake_mode`, `pending_options`. All no-ops without a session. |
| `scripts/core/replay/replay_session.gd` | The session node under the level (loaded by path): seeding, entity ids (rid), recording, playing, checkpoints, divergence report, F8 bug report, command executor, argument encoding. |
| `scripts/core/replay/replay_state.gd` | State summary + md5 hash (order independent, every per-entity number rounded to an int before summing). |
| `scripts/core/replay/bug_report.gd` | The bug-report zip. |
| `tools/replay_lab/replay_match.gd` | Runner (SceneTree script): modes `bots`, `script`, `play`, `watch`. |
| `tests/test_replay_lab.gd` | The test (child processes, see "Tests"). |

Game-code edits (small, additive, guarded):
- `scripts/world/skirmish.gd` `_start_match()`: loads `replay_hooks.gd` **by path** and calls `match_started(self)` (+ const `REPLAY_HOOKS_PATH`).
- `scripts/buildings/build_grid.gd` `request_rebake()`: asks `_REPLAY.rebake_mode()` (thread = unchanged default / sync / deferred).
- `scripts/world/main.gd` `_ready()`: `_REPLAY.level_ready()` + the first navmesh bake on the main thread only when
  `_REPLAY.bake_mode == BAKE_SYNC` (lab / tests; the game and missions are unchanged).
- `scripts/ui/selection_manager.gd`: one `_REPLAY.note(...)` line at each world-level order entry point (list below).
- `scripts/ui/wizard_control.gd`: notes the WASD walk (`hero_move`, `move_input`).

## How to use

`$GODOT` = the console exe (CLAUDE.md), or better the gate `tools/godot_run.ps1` (max 4 Godot runs at once). Always
`--fixed-fps 60` (one 1/60 s game frame per engine frame, also for `_process` gameplay) and `--quit-after`.
**Through the PowerShell gate use `++` instead of `--`** before the lab arguments (PowerShell eats `--`; Godot takes
`++` as the same separator), e.g. `& tools/godot_run.ps1 --headless --path . -s tools/replay_lab/replay_match.gd --fixed-fps 60 --quit-after 400000 ++ --mode=play --file=<path>`.

- **Recording real skirmishes is OFF by default** (lead 2026-09-26: the replay code stays inert unless a recording /
  replay runs; without a session every hook is a no-op). Turn it on with `ReplayHooks.auto_record = true` (next step:
  a settings toggle "Record replays (F8 bug reports)"). When on, every skirmish records to
  `user://replays/replay_<date>_<seed>.replay` (`%APPDATA%\Godot\app_userdata\Four Wizards RTS\replays\`), 20 kept.
- **Bug report** (while recording): **F8** in a skirmish (physical key; free in CLAUDE.md "Keys") writes
  `user://bug_reports/bug_<date>.zip` = `replay.replay` (the match so far) + `log.txt` (last 2000 lines of
  `user://logs/godot.log`) + `settings.cfg` + `screenshot.png` + `info.json` (commit, Godot, OS, GPU, CPU, match
  time, frame, seed). The HUD says where. Nothing is uploaded: the user copies the zip from the laptop by hand
  (OneDrive). A pause-menu button "Save bug report" is still to add (ui-coder, see next steps).
- **Verify a replay headless** (also one from a bug zip: unzip `replay.replay`):
  `$GODOT --headless --path . -s tools/replay_lab/replay_match.gd --fixed-fps 60 --quit-after 400000 -- --mode=play --file=<path>`
  -> `REPLAY_RESULT {"ok", "checks", "checks_ok", "end_match", "divergence": {"f", "t", "diff": [...]}}` and a
  `REPLAY diverged at frame N (m:ss): units: [..] vs [..]; pos: ...` line at the first bad checkpoint.
- **Watch a replay** (window): `$GODOT --path . -s tools/replay_lab/replay_match.gd --fixed-fps 60 -- --mode=watch --file=<path>`.
  Keys 1 / 2 / 3 / 4 = speed x1 / x2 / x4 / x8 (`Engine.max_fps` = 60 x speed; x8 only if the PC draws 480 fps),
  Space = pause, arrows / edge pan = free camera. A full-screen blocker eats mouse clicks so the viewer can't give
  orders. Watch always runs without sim mode (it needs the art).
- **Bot game from a seed**: `-- --mode=bots --seed=3 --minutes=30 --pair=fire:shadow --difficulty=normal --sim=1 --out=user://replays/b3.replay`,
  then watch it with `--mode=watch --file=...` (a bot replay's "commands" are only the seed + setup).
- **Scripted player match** (test): `-- --mode=script --seed=7 --minutes=3 --sim=1 --out=...`.
- Runner options: `--sim=1`, `--bake=thread` (record like a real game), `--hash-every=300`, `--result=PATH`,
  `--dump=F` (every unit's rid / type / position at frame F: run two records with the same seed and diff the DUMP
  lines to see which unit drifts), `--bug-report=F` (presses F8 at frame F).

## File format (`.replay`, JSON lines, `JSON.stringify(full_precision)`)

```
{"k":"header","v":1,"game":"<commit 12>|date:<day>","date":..,"mode":"player|bots|script","seed":N,"tick":60,
 "hash_every":300,"bake":"thread|sync","setup":{"player_kingdom","enemy_kingdom","tavern_enabled","trade_enabled",
 "river_enabled","points_enabled","camps_enabled","beasts_enabled","time_limit_s","bots":{"<team>":{"name","difficulty"}},
 "map_detail","control_scheme","sim"}}
{"k":"cmd","f":F,"c":"<kind>","a":[args],"sel":[rids],"b":rid,"fl":rid}      # F = physics frames done since match start
{"k":"bake","f":F}                                                         # a thread rebake landed (thread mode only)
{"k":"hash","f":F,"h":"<md5>","s":{summary}}                              # every hash_every frames
{"k":"end","f":F,"h":"<md5>","s":{summary},"reason":"game_over|time|left|stopped","winner":T}
```
Arguments: ints `{"i":n}`, StringName `{"sn":..}`, Vector3 `{"v3":[x,y,z]}`, resources `{"res":path}`, entities
`{"rid":n,"at":[x,z]}` (rid = order in which entities of the groups units / buildings / crystal_nodes / trade_posts /
game_critters / item_pickups / bounties / capture_points / taverns / guilds / markets became ready; entities present at
match start are numbered first, in group order), other nodes `{"np":"<path from the level>"}`.
Summary keys: `units`, `pos` (sum of round(x*10) + 7 round(z*10)), `hp`, `types` (per-type counts) per team 0/1/2;
`bld`, `bhp`, `cry`, `pop`, `gath`, `gold`, `ess` per team; `crit` (living critters); `t` match time.

## Frames and timing

The session node runs **first** in every physics frame (`process_physics_priority = -1000`). `frame` = physics frames
fully done since `Skirmish._start_match`. At the top of each physics frame: end check, checkpoint (state after
`frame` frames), then the commands noted after that frame, then `frame += 1`. Real input lands between frames (after
`_process`, before the next physics step), which is exactly where the replay applies it. The script mode issues its
orders from `SceneTree.physics_frame` (before any `_physics_process`) for the same reason.

## Commands (what is recorded)

Recorded at the SelectionManager world-level entry points (after the screen click is resolved), with the selection
(`selected` rids, `selected_building`, `selected_bounty`). The replay restores the selection
(`select_units` / `select_building` / `select_flag`) and gives the same call, so formations, caravan rules, hunters...
are computed by the same code.

| kind | from | replay calls |
|---|---|---|
| `select` | `selection_changed` (deduped) | restores the selection only (some gameplay reads it) |
| `formation_move` (all ground moves, `order_move`), `attack_move`, `hold`, `stop`, `gather`, `attack_building`, `build_site`, `trade_with`, `hunt_critter`, `set_market_route`, `pick_up_item`, `train`, `raise_selected_bounty`, `remove_selected_bounty` | the SelectionManager function of that name | the same function |
| `attack_unit` | `_issue_order` / `_confirm_attack_move` on an enemy / neutral unit | the same loop (caravans move, others `command_attack`) |
| `place` [BuildingType, snapped center] | `place_building_at` | `build_grid.place(type, center, PLAYER, selected_workers())` |
| `cancel_site` | `cancel_site` | `cancel_construction()` |
| `rally` [point, node] | `_set_rally` | `set_rally_node` / `set_rally_point` |
| `cast` [spell, target] | `_cast` | `hero.command_cast` |
| `learn` [spell] | `learn_spell_slot` | `hero.learn_spell` |
| `use_item` [slot, target] | `_use_item` | `hero.inventory.use_item` |
| `hero_move`, `move_input` | WizardControl (Hero WASD) | `command_move` / `set_move_input` (changes only) |
| `call` [node, method, args...] | generic, for the windows below | `node.callv(method, args)` |

**Not recorded yet** (UI outside SelectionManager, next steps 1): bounty placement (`bounty_mode.gd`), tavern
hire / revive / dismiss (`tavern_window.gd`, `champion_bar.gd`), trade window (wares, exchange, Lodge contracts:
`trade_window.gd`), shop buy / sell / swap / drop (`shop_window.gd`, `inventory_bar.gd`), keep queue cancel
(`command_card.gd` -> `cancel(slot)`), control-group recalls that only select (covered by `select`), concede /
surrender, pause-menu restart. Each needs one line: `_REPLAY.note(&"call", [node, &"method", args...], selection)`
right before the gameplay call (node must be an entity or have a deterministic path from the level).

## Determinism audit (skirmish, headless, `--fixed-fps 60`, fixed seed)

Risk: **H** = diverges a replay in normal play, **M** = sometimes / some modes, **L** = cosmetic or only across processes.

### Random numbers

| File:line | What | Risk | Fix |
|---|---|---|---|
| `scripts/units/champion.gd:117` | `class_rng.randomize()` in `_init` (class pick, `champion.gd:369`) | H | **Done (session)**: re-seeded from the match seed when the champion is ready (`_on_node_ready`, fields `class_rng` / `_rng` / `rng`). |
| `scripts/ai/champion_brain.gd:268` | `_rng.randomize()` in `_ready` (explore / guard / idle points 457, 1077, 1825) | H | **Done (session)**, same hook (no edit in scripts/ai). AI task: seed from a passed-in match seed instead. |
| `scripts/units/champion_class.gd:152` | `pick(champion, rng = null)`: a null rng -> `randomize()` | M | callers pass `class_rng` today; make the null path use a seeded rng (gameplay-coder). |
| `scripts/ai/beast_brain.gd:208` | `_rng.seed = hash(lair id) + variant` | L | deterministic; the session re-seeds it anyway (per match seed). |
| `scripts/world/game_critter.gd:147` | seeded from spawn position | L | deterministic. |
| `scripts/world/{thieves_guild:117, camp_manager:118, epic_beasts:221, critter_herds:67}` | `rng.seed = DEFAULT_SEED` constants | L | deterministic; **done (session)**: re-seeded from the match seed at match start (variety per match, like the Bot Lab). |
| `scripts/world/skirmish.gd:731, 956, 980, 1310`, `main.gd:302`, `capture_points.gd:97`, `neutral_camp.gd:468` | fixed seeds / the manager's rng | L | deterministic. `neutral_camp.gd:468` falls back to an unseeded `RandomNumberGenerator.new()` when it has no manager (M, systems-coder: seed it). |
| `scripts/vfx/champion_barks.gd:99` | `rng.randomize()` (bark chance) | L | cosmetic; the session re-seeds `rng` fields anyway. |
| `scripts/audio/game_audio.gd:136, 409` | global `randf()` (pitch, mine ticks) | L | cosmetic, but it consumes the **global** RNG: no gameplay code uses the global RNG today (checked: units, buildings, spells, items, world, economy, ai). Rule to keep: **gameplay never calls global randf / randi / shuffle / pick_random**. The session also `seed()`s the global RNG from the match seed. |
| `scripts/campaign/mission_01.gd` | fixed `MAP_SEED` | L | campaign, not in the Replay Lab scope yet. |
| Godot 4 note | `RandomNumberGenerator.new()` starts from a **random** seed | - | every new RNG in gameplay must be seeded (from the match seed). |

### Clock, frame rate, timers

| File:line | What | Risk | Fix |
|---|---|---|---|
| `scripts/ai/*` (`commander.gd:452-480`, `ai_trade.gd:399`, `ai_champions.gd:197`, `champion_brain.gd:288`, `beast_brain.gd:284`, `thief_band.gd:304`, `tracker_contract.gd:250`, `champion_sense.gd:442`, `ai_mapfill.gd:331+`) | `Time.get_ticks_usec()` | L | **measurement only** (profiling counters), never a decision: OK. AI rule to keep: no time budgets that cut work short. |
| `scripts/ai/commander.gd:680`, `world/tavern.gd:142`, `world/guild_house.gd:134/196`, `economy/caravan.gd:818` | `Engine.get_physics_frames()` (absolute engine frame) | L | only relative gaps / per-frame caches / message throttling. A cache refreshed on absolute frame parity could differ between processes whose pre-match wait differed; replace with match frames if it ever matters. |
| `scripts/items/essence_bank.gd:58` | essence +1/s trickle in **`_process`** | H (windowed) | deterministic headless with `--fixed-fps`; in a real game the delta varies -> a recorded human match diverges. Move to `_physics_process` (items-coder). |
| `scripts/units/projectile.gd:93` | projectile flight + hit in **`_process`** | H (windowed) | same: move to `_physics_process` (gameplay-coder). Hit timing decides kills. |
| `scripts/items/item_actives.gd:336`, `items/inventory.gd:140`, `items/item_pickup.gd:68`, `world/bounty.gd:125`, `world/loot_sack.gd:105`, `campaign/ember_crown.gd:98`, `campaign/artifact.gd:93` | gameplay timers / pickups in `_process` | H (windowed) | same fix, one owner each (items-coder, systems-coder). |
| `scripts/buildings/training_building.gd:224` | `_process` drops a dead gather rally **only while selected** | M | gameplay reads UI selection: **done (session)**: selection changes are recorded (`select`). Better: drop the rally regardless of selection (systems-coder). |
| `scripts/ui/selection_manager.gd` `_process` -> `_update_pickup` / `_take_pickup` | hero pickup walking done by the UI each frame | M | replay keeps the SelectionManager processing (never `--ui=off` in a replay). Move to a `Wizard.command_pickup` (the code already prefers it). |
| `scripts/units/unit.gd:1307`, `buildings/building.gd:664-666`, `world/game_critter.gd:453`, `units/support_caster.gd:151`, `items/inventory.gd:784`, `economy/caravan.gd:835` | `SceneTreeTimer`s in idle time (corpse / ruin free, fallback) | M (windowed) | idle timers count `_process` time: exact under `--fixed-fps`, frame-rate dependent in a window. Use `create_timer(t, false, true)` (process_in_physics) for gameplay timers. `commander.gd:894` already does. |
| art scripts (`res://art/`) | death / destroy animations emit `death_finished` / `destroyed_finished` from `_process` | M (windowed) | same as above; sim mode keeps their timing (Bot Lab). |

### Engine / scheduling

| Where | What | Risk | Fix |
|---|---|---|---|
| `scripts/buildings/build_grid.gd:292` `request_rebake()` | navmesh rebake **on a thread** after every placement / destruction: the new navmesh lands after a wall-clock-dependent number of frames -> paths differ | **H** | **Done**: `ReplayHooks.bake_mode` — lab / tests bake on the main thread (`BAKE_SYNC`); a replay of a thread-baked recording defers every rebake to the **recorded landing frame** (`{"k":"bake"}` lines, `BAKE_DEFERRED`). Real games keep the thread (no hitch). |
| NavigationServer map / region iterations (project defaults `navigation/world/map_use_async_iterations = true`, regions too) | the map / region rebuild after a rebake is async: lands after a wall-clock delay | H | **Done (session), deterministic runs only** (`BAKE_SYNC`): `map_set_use_async_iterations(map, false)` + `region_set_use_async_iterations(rid, false)` at match start. **Never in real games**: switching it off after a thread-baked first navmesh left the map without paths (every unit froze) in the first test run; guarded by `bake_mode == BAKE_SYNC`. |
| `scripts/world/main.gd:95` first navmesh bake on a thread | the match starts after a wall-clock-dependent number of frames; everything created in `_ready` already ticks during that wait: the bots' think `Timer` (`commander.gd:368`, idle callback), `EssenceBank._process` trickle, critters, camps | **H** | **Done for deterministic runs**: `main.gd` bakes the first navmesh on the main thread when `bake_mode == BAKE_SYNC` (the match starts inside the level's `_ready`, `pre_frames = 0`; before this fix two identical bot runs differed at the first checkpoint: bot think phase, essence +1). Real games keep the thread; the header records `pre_frames` (frames from the bake request to the match start). **Open for human recordings**: either nothing gameplay ticks before `_start_match` (Timers / trickles start there: ai-coder, items-coder) or the replay waits the same `pre_frames` before starting. |
| Static state across restarts: `champion_brain.gd:189 _slots`, `tracker_contract.gd:60 _slots`, `thief_band.gd:77 _serial`, `beast_brain.gd:115 _serial`, `commander.gd:73-76 _snapshot / _kinds`, `champion_sense.gd:57 _by_team`, `caravan.gd:71-72 _msg_*` | counters / caches that survive F9 restart / "Play again" in the same process | M | a replay always runs in a fresh process; a match played after a restart can start with different `_slots` stagger -> diverges. AI task: reset them in a `reset_statics()` called at match start (ai-coder); caravan messages are local text only. |
| Dictionary / group iteration | GDScript dictionaries and groups keep insertion order | L | deterministic in the same process order. Dictionaries keyed by `get_instance_id()` (tracker_contract 138-321, commander `_kinds`) looked like lookups only (not checked exhaustively; ai-coder to confirm none is iterated for a decision). Rule: never sort or tie-break on instance ids or auto names (`@Node@12`) — they differ between a windowed and a headless run. |
| Physics / avoidance | fixed 60 Hz step, `run_on_separate_thread` off, `physics_engine = DEFAULT`; avoidance `navigation/avoidance/thread_model/avoidance_use_multiple_threads = true` (+ high-priority threads), `navigation/pathfinding/max_threads = 4` | **H (fix = one project setting, lead)** | **Multi-threaded avoidance is not deterministic.** With everything above fixed, two bot-vs-bot runs with the same seed still drifted by ~0.001 m on the **two workers mining the same crystal node** (both teams, rids 2-5; found with `--dump=600`), first at frame 600 / 900 / 1200 in 4 runs; the drift then grows (a trip lands a frame later: `gath` 60 vs 70 at 0:20). **Experiment** (scratch copy of the project with `override.cfg` `[navigation] avoidance/thread_model/avoidance_use_multiple_threads=false`): two 1:30 bot runs = **identical** (19 / 19 checkpoints + end hash). **Fix: add to `project.godot`** `[navigation]` `avoidance/thread_model/avoidance_use_multiple_threads=false` (lead-owned file, not changed here), then run the perf test (avoidance on one thread costs CPU with many agents). |
| Threads | no `Thread` / `WorkerThreadPool` in scripts/ (checked) | - | - |
| Windowed vs headless / sim mode | a watch (art on) vs a sim recording (art off) | M | sim mode is recorded in the header and replays verify with the same mode; watch always has art, so a watch of a sim recording may drift (use `--sim=0` recordings for watching if it does). |
| Commands between frames | a real click lands after `_process` of frame k; the replay gives it at the start of physics frame k+1 | L | same point in the loop; only `_process` gameplay (above) could see a difference. |

## What is deterministic now

- Headless, `--fixed-fps 60`, main-thread bakes (`BAKE_SYNC`), same seed: **everything except avoidance** (above).
  With single-threaded avoidance (one `project.godot` line, lead) two bot-vs-bot runs are identical (tested 1:30).
- Real games (window, thread bakes) record everything the SelectionManager does + selection + WASD + the bake
  landing frames, and F8 bug zips work (checked with a plain `skirmish.tscn` start: the session records itself,
  `bake: thread`, `pre_frames: 1`, the bake landing line, checkpoints). Their replays are expected to drift until
  next steps 2 and 3 (`_process` gameplay, pre-match ticking) are done; the verify run says where.

## Tests

`$GODOT --headless --path . -s tests/test_replay_lab.gd --quit-after 6000` (~8-10 min: 3 parallel 3-minute matches,
then 2 parallel replays). Checks: scripted match replay = all checkpoints + end hash; bot-vs-bot seed 3 run twice =
equal hash streams (reports the first differing checkpoint and what differs); the bot recording replayed from its
file matches.

### Test results (2026-09-26)

- **Live project** (avoidance multi-threaded, the default): `FAIL replay_lab` — script replay 1/35 checkpoints
  (diverged at frame 600, `pos` only: the two workers on one node), bots seed 3 run twice diverged at frame 900,
  bot replay from file diverged at frame 900. Everything else in the summaries matched.
- **Scratch copy with `avoidance_use_multiple_threads=false`** (override.cfg, same scripts): `PASS replay_lab` in
  324 s — script replay **35/35 checkpoints + end hash**, bots seed 3 twice **36/36 equal**, bot replay from file
  **35/35 + end hash**.
- Earlier runs that found the other fixes: first navmesh on a thread -> two bot runs differed at the first checkpoint
  (bot think phase, essence +1); `stop()` finishing in `_process` -> end hash off by the essence trickle (now ends at
  the next physics frame start); `map_set_use_async_iterations(false)` after a threaded first bake -> no unit ever
  moved (now only in sync runs; a plain skirmish with the session was checked to move and record normally).
- Smoke test after the `main.gd` / `build_grid.gd` / `skirmish.gd` hooks: `victory=true`. Perf test not run (the PC
  was loaded with other agents' Godot runs; numbers would be noise) — the lead should run it, especially after step 0.
- Bug zip: `--bug-report=120` wrote `bug_<date>.zip` with replay.replay, log.txt, info.json (no settings.cfg in that
  user dir; no screenshot headless).

## Progress / next steps

Done: audit; hooks; session (seeding, rids, record, play, checkpoints, divergence report); bake modes (incl. the
first bake); map / region sync iterations in deterministic runs; state hash; bug zip on F8 (also while paused);
runner (bots / script / play / watch, `--dump`, `--bug-report`); test; the avoidance culprit found (step 0).
Not tried yet: the **watch** mode in a real window (written, parses, never opened: no display in this session) —
first thing to try by hand: `--mode=watch --file=<a recording>`, keys 1-4 / Space.

Next, in order:
0. **Lead: `project.godot` `[navigation] avoidance/thread_model/avoidance_use_multiple_threads=false`**, then the perf
   test and `tests/test_replay_lab.gd` (expected PASS, see "Test results"). Until then the test FAILs on the avoidance
   drift (that FAIL is the determinism signal, not a broken lab).
1. **Record the remaining UI commands** (table "Not recorded yet"): one `_REPLAY.note(&"call", ...)` per entry point in
   bounty_mode / tavern_window / champion_bar / trade_window / shop_window / inventory_bar / command_card (queue cancel)
   + concede. Add a scripted step for each to the `script` mode.
2. **Move `_process` gameplay to `_physics_process`** (essence trickle, projectiles, item actives / inventory / pickups,
   bounty, loot sack, crown, artifact) and gameplay SceneTreeTimers to `process_in_physics = true`: needed for **human
   recordings made in a window** to replay exactly. Until then a real-game replay is expected to drift after the first
   projectile hit that lands on a different frame; the verify run says where.
3. AI (ai-coder, after the bot fix): reset static counters at match start; seed champion / beast brains from a
   match seed passed in (instead of the session re-seeding after `_ready`).
4. Settings toggle "Record replays" (sets `ReplayHooks.auto_record`, saved in settings.cfg; ON on the laptop for
   playtests) + pause menu button "Save bug report" (ui-coder; calls `ReplayHooks.session.save_bug_report()`), and
   the F8 key in the keys help / CLAUDE.md "Keys" (lead).
5. Watch mode polish: timeline scrub (re-simulate from the start to a frame at max speed), camera follow of a unit,
   per-checkpoint divergence marker, the mouse wheel zoom (the blocker eats it today).
6. A `tools/replay_lab/run_replay.ps1` (verify every replay in a folder / a bug zip in one command, scorecard style
   PASS / WARN / FAIL like the other labs) and a history log.
7. Deterministic async bake for real games (bake on a thread but apply at request frame + N, waiting if needed), so
   real games and replays land rebakes on the same frame without recording them.

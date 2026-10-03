# Review: mission foundation (3d024201) and the fast-CI / test tooling

Reviewer: code review agent, 2026-10-02. Read-only review: no game code, data or test was changed and Godot was not run.
The only things executed were read-only git commands and `tools/ci/select_tests.ps1`, which only prints its selection.

Scope: `scripts/campaign/{mission_base,mission_config,mission_skeleton,mission_01,campaign_state}.gd`, the knob hooks in
`keep / tier_system / training_building / building_gun / t3_kit / helper_roster / unit / inventory / essence_bank`,
`tests/helpers/mission_harness.gd`, `tests/test_mission_framework.gd` and `docs/design/mission-framework.md`, plus the
CI tooling: `tools/ci/{ci,ci_quick,select_tests}.ps1`, `slow_tests.txt`, `tools/godot_run.ps1`,
`tools/error_lab/error_lab.ps1`, the early stops in `test_8_a1 / test_8_a2 / test_9_c11 / test_casters_bots`, the
`test_20_a3` calibration, `FaceKit.release()` and the replay-lab avoidance override.

## Verdict

**The foundation is sound, but four issues need fixing before episode 2+ missions are built on it.** Mission 1's
extraction keeps its behaviour: I compared it with `3d024201^`, and the end flow, timers, keep-lost check, economy
start and level cap all match. The CI changes are well built, and every early stop is logically safe.

The four issues:
1. `hold_world(false)` does not "restore exactly what it changed". It stops every held unit's orders: workers stop
   gathering and drop their construction sites. It also wipes `death_guard`.
2. `win()` / `lose()` can override an ending that was already decided.
3. Untagged seats fall back to "every node of the seat's team", and that fallback misbehaves after
   `switch_seat_side`.
4. `ci_quick -Changed` under-selects for a changed base class. A MissionBase-only change runs 1 test plus the core
   set, and skips all of mission 1's regression tests.

None of these is critical today, because no shipped mission calls `hold_world`, seats or win-after-lose yet. They will
bite the first episode 2-8 mission that does.

## Findings

### High

**H1. `hold_world(false)` clears every held unit's orders: workers go idle, construction is abandoned and death guards are lost**
`scripts/campaign/mission_base.gd:488-496` calls `set_dormant(u, false)` on each held unit. That function is at
`:1004-1010`.
- What is wrong: waking a unit always runs `u.command_stop()` and `u.death_guard = Callable()`.
  - `Worker.command_stop()` (`scripts/economy/worker.gd:128-131`) runs `_stop_gathering()` and `_stop_building()`.
  - `death_guard` is also used by the Rekindle item passive (`scripts/units/item_passives.gd:271`). That passive only
    re-applies it when the inventory changes.
  - `hold_world(true)` itself does not stop units, which is right: it is a ceasefire, not a freeze. The release then
    destroys the state that the hold never changed.
  - The doc (`mission-framework.md` section 2) promises "`false` restores exactly what it changed".
- Failure scenarios: a mid-mission cinematic runs `hold_world(true, [hero])` and then `hold_world(false)`. Afterwards:
  - every player worker stands idle and half-built sites are left unfinished;
  - the army's move / attack-move orders are gone;
  - wave units in mode `&"point"` are idle, so `_refresh_waves` (`:1058-1061`) switches them to `&"keep"` and sends
    them at the player's keep, skipping their scripted target;
  - a hero with Rekindle who was not in `keep_awake` silently loses the passive for the rest of the mission.
- Related problems:
  - A unit that the mission makes dormant during the hold (for example in a cutscene end state) already has
    `META_DORMANT`, but `_held` still lists it, so the release wakes it.
  - A Commander disabled during the hold (`withdraw_seat`) is set back to `enabled = true` from `_held_bots`.
- Fix:
  - Give `set_dormant` a `restore_orders := true` parameter (or add a private `_wake_held(u)`) that skips
    `command_stop`.
  - Save the previous `death_guard` in a meta on sleep and restore it on wake, instead of `Callable()`.
  - On release, skip units whose `META_DORMANT` was set by the mission after the hold. Keep the hold's own marker
    (`_held`) apart from `META_DORMANT`, for example `META_HELD`.
  - Skip bots whose `enabled` was changed during the hold.
  - Add a worker-gathering check and a Rekindle check to `test_mission_framework` core.

**H2. `win()` / `lose()` ignore a pending end, so a decided defeat can become a victory, with the campaign save**
`scripts/campaign/mission_base.gd:628-635` (`_finish`) only checks `game_over`, not `_ending`.
- What is wrong: `_on_player_hero_fell()` calls `lose(defeat_delay)`, which sets `_ending` and queues the defeat 3 s
  later. A later `win(0)` from a signal handler or timer goes straight through:
  - `_end_game(true)` runs and writes the campaign save (`:656-657`);
  - the pending defeat timer then does nothing.
  - The E-list is gated by `_ending`, but handlers wired to `destroyed`, `died` or `after` callbacks are not. Mission 1
    used to guard each of its paths by hand; the generic API lost that guard.
- Failure scenario: the hero dies (instant-loss rule, defeat in 3 s). One second later the last enemy building falls,
  and the mission's `destroyed` handler calls `win()`. Result: VICTORY, `on_mission_victory` saves and unlocks the next
  mission. The reverse also happens: `win(4)` pending, then a scripted `lose()` gives a defeat after the victory
  dialogue.
- Fix: `if game_over or _ending: return` in `_finish`. If a mission really needs to replace a pending end, add an
  explicit `force := false` parameter. Test it: lose(3), then win(0) one frame later, and expect `ended == 0` and no
  save.

**H3. Seats without tags follow the team, so after `switch_seat_side` the seat covers the player's whole side**
`scripts/campaign/mission_base.gd:837-853` (`seat_nodes`) and `:859-870` (`switch_seat_side`).
- What is wrong:
  - When no living node carries the seat's tag, `seat_nodes` returns every untagged unit and building whose `team`
    equals the seat's current team.
  - `switch_seat_side` changes the seat's team (`d["team"] = team`) but does not tag the nodes it moved.
  - The same fallback also fires when a tagged seat's tagged units have all died: the "tagged" flag is recomputed from
    living nodes on every call.
- Failure scenarios (the mission-e7-04 shape: switch, then withdraw):
  - Seat `&"allies"` (team ENEMY, untagged) switches to PLAYER, and later the mission calls
    `withdraw_seat(&"allies", exit)`. `seat_nodes` now returns every PLAYER unit and building: the hero, the workers
    and the army all walk to `exit` and `leave_map()`, and the player's buildings get the `&"all"` truce.
  - A tagged ENEMY seat whose 4 tagged units died: `withdraw_seat` withdraws the whole enemy army instead of nothing.
- The test does not catch it: `test_mission_framework._rt_seats` only uses tagged seats.
- Fix:
  - In `switch_seat_side`, `tag_seat(n, seat)` every node it moves.
  - Store `tagged: bool` in `_seats[seat]` the first time `tag_seat` is used for that seat, and never fall back to
    the team once it is set.
  - Add a test that switches an untagged seat to PLAYER and then withdraws it.

**H4. `select_tests.ps1` stops at the first direct hit, so base-class changes skip their subclasses' tests**
`tools/ci/select_tests.ps1:167`: the 2-hop referencer walk only runs when `$hits.Count -eq 0`.
- What is wrong: a file that some test names directly never maps to the tests of the scripts that extend or load it.
- Verified by running `select_tests.ps1 -Files scripts/campaign/mission_base.gd,scripts/campaign/mission_config.gd`:
  it picked `test_mission_framework` plus the 4 core tests ("5 of 274").
  - The same tool maps `mission_01.gd` to 15 tests.
  - The framework doc names mission 1's regression net as `test_m7_s1/s2/s3`, `test_m7_u1`, `test_tier_path` and
    `test_campaign_prologue`. None of them runs.
  - The smoke test does not cover Mission01 either: `scenes/main.tscn` is not the mission scene.
- Failure scenario: a MissionBase timer refactor breaks mission 1's hold or victory. `ci_quick -Changed` reports PASS
  with 5 tests.
- Fix: always walk hop 1 and union the results, at least for `.gd` files with a `class_name` or files that another
  script `extends`. For example, add `extends "res://..."` / `extends ClassName` referencers to the direct hits. Or add
  `scripts/campaign/mission_base.gd` (and similar base classes: `training_building.gd`, `caster_kit.gd`...) to a
  "fan-out" list mapped to their subclasses' tests.

### Medium

**M1. The campaign save is written in place and an unreadable file is silently treated as a new campaign**
`scripts/campaign/campaign_state.gd:121-126` (`save`) and `:97-99` (`load`).
- What is wrong:
  - `FileAccess.open(path, WRITE)` truncates the file first, then writes it.
  - `load()` returns a fresh campaign when the JSON does not parse, without a warning.
  - The commit adds more save points (`set_flags(..., save_now)`, every victory now also writes flags and counters).
- Failure scenario: Godot crashes or the PC loses power during the victory save. That is plausible: the FaceKit exit
  crash happened on ~150 runs until 09-30. The file is truncated, so the next start shows a new campaign with
  everything locked. The next victory then overwrites the broken file for good.
- Fix: write `path + ".tmp"`, close it, then `DirAccess.rename_absolute(tmp, path)`, keeping the previous file as
  `path + ".bak"`. In `load()`, fall back to `.bak` when the main file does not parse, and `push_warning` the event.

**M2. `switch_seat_side` grace overwrites an existing truce and then erases it**
`scripts/campaign/mission_base.gd:876-883`, and `set_truce` at `:764`.
- What is wrong:
  - `set_truce(nodes, true, TRUCE_ALL)` replaces whatever truce id each node had.
  - When the grace ends, every node still at `&"all"` is cleared to `&""`, so the earlier truce (for example
    `&"pact"` from e7-02) is lost.
  - `set_truce(..., on=true)` on a node that is already in another truce silently moves it, which is the same
    problem.
- Failure scenario: a seat at peace with a neutral camp through `set_truce([...], true, &"pact")` switches sides with
  a 10 s grace. After 10 s the seat and the camp fight.
- Fix: save the previous id in a meta (`truce_prev`) when the grace starts and restore it when the grace ends. Make
  `set_truce` warn when it replaces a different id, or support a set of ids.

**M3. `-Base last-green` can start from a run that did not test the full suite**
`tools/ci/ci.ps1:164-175` writes a history row unless `-NoHistory` is set, whatever the scope was.
`tools/ci/select_tests.ps1:54` takes the last PASS / WARN row that has a commit.
- What is wrong: `ci.ps1 -SkipTests -SmokeRuns 1` (the documented "quick gate") and `ci.ps1 -Tests a,b` both write
  `result = PASS` rows. The Error Lab history is skipped for subsets (`:123`), but the CI history is not.
- Failure scenario: the lead runs the quick gate on commit X (PASS) and commits Y. Then
  `ci_quick -Changed -Base last-green` diffs from X, although X never ran the test suite, and calls Y green from a
  narrow selection.
- Fix: write `scope = "full" | "subset" | "no-tests"` in the row, and have `last-green` only accept `scope == "full"`
  rows. Or write no history row when `-Tests` or `-SkipTests` is given.

**M4. `defeat_on_keep_lost` defaults to true: a mission without a keep loses at 0.5 s**
`scripts/campaign/mission_config.gd:17` and `scripts/campaign/mission_base.gd:643-649`.
- What is wrong: `_check_end` treats `keep == null` as "the keep has fallen". The config's stated rule is "defaults =
  off / untouched", but this one is on.
- Failure scenario: a hero-only or no-economy phase (e3-02 phase 1, `economy_enabled = false`) whose map has no
  player keep shows "The keep has fallen" and DEFEAT 0.5 s after the match starts, unless the author knew to turn the
  knob off.
- Fix: default it to false and set it to true in `Mission01` and the skeleton. Or only arm the check once a player
  keep has existed (`keep != null` seen at least once).

**M5. Early stops remove the long-match coverage, and the slow tests now only run at milestones**
- Files: `tests/test_8_a2.gd:335`, `test_9_c11.gd:121-126`, `test_casters_bots.gd:166-170`, `test_8_a1.gd:299`, and
  `tools/ci/slow_tests.txt`.
- What is wrong:
  - Each early stop is logically sound: every judged value only grows, I checked each `_report` / `_finish` against
    its stop condition.
  - But the long tail of each match was also the project's only check for script errors, crashes, stuck states and,
    in 9.C11, the "champion never orderable" sample every 600 frames, after minute 5-10. The Error Lab fails a test on
    any `SCRIPT ERROR` in the log, so a late-game error used to fail these tests and now goes unseen.
  - `ci_quick` also skips all 9 slow tests, so the full-length runs only happen in `ci.ps1` milestones, and only with
    `-- --full` (the CI never passes `--full`).
- Failure scenario: a script error in the Commander's late-game expansion code (min 12+) passes everyday CI and also
  the milestone CI, because `test_8_a2` now stops at the Fire bot's first cast (about min 3) and `test_9_c11` once the
  bounties are paid.
- Fix: keep one full-length bot-vs-bot run in the milestone CI. For example, `ci.ps1` could run `test_9_c11 -- --full`
  or `test_8_a1 --only=matrix` (still full). Or add `--full` to the Error Lab arguments when `ci.ps1` runs without
  `-Tests`.

**M6. No-economy mode is not 0 essence: the carried essence is added after the reset**
- Files: `scripts/campaign/mission_base.gd:182-190` and `scripts/campaign/campaign_state.gd:325-328`.
- What is wrong: `_apply_economy_start` (in `_ready`) sets the bank to 0. Then the mission's
  `_on_navigation_ready` calls `CampaignState.apply_to_start`, the skeleton pattern, which runs `bank.add(essence)`.
  The doc and the knob table say "0 essence".
- Failure scenario: e3-02 phase 1 (no economy) starts with the 100-300 essence carried from the previous mission. It
  can buy or upgrade items in a phase meant to have none, and the hidden top bar hides it from the player.
- Fix: in `apply_to_start`, hold the carried essence back while the level node has `config.economy_enabled == false`
  (store it so a later phase switch can grant it). Or have MissionBase re-zero the bank after `apply_to_start`, with a
  `grant_carried_essence()` call for the phase switch.

**M7. Track counters are added again on every victory, including replays**
`scripts/campaign/campaign_state.gd:288-292` (`mission_flag_adds`).
- What is wrong: `flags[k] = saved + add` runs on every `on_mission_victory`. Nothing records that this mission
  already contributed.
- Failure scenario: the player replays e3m3 from the mission menu, where completed missions stay unlocked, and wins
  again. `shadow_stone_uses` counts that mission's uses twice and can push a later branch over its threshold.
- Fix: store the contribution per mission (`flags["<counter>@<mission_id>"]`) and recompute the total. Or skip the
  adds when `completed.has(mission_id)` before this victory. The spec owner has to choose the rule, so record it in
  mission-framework.md.

### Low

**L1. `Unit.truce_count` never goes back to 0 after a truce**
`scripts/units/unit.gd:1358-1373`.
- What is wrong: nodes freed or killed while they carry the `truce` meta never decrement the counter, and the counter
  is static, so it survives scene changes in one process (F9 restart, mission to mission, mission to skirmish). After
  the first truce, every `is_enemy_of` call pays for `in_truce`.
- Impact: the cost is small (two `has_meta` calls), but the contract line "with no truce anywhere `is_enemy_of` skips
  the check" stops being true. A `duplicate()` of a node carrying the meta can also under-count.
- Fix: decrement in `Unit._exit_tree` / `die` when the meta is present, and reset the counter in `MissionBase._ready`
  (or `Skirmish._ready`).

**L2. The truce only covers `is_enemy_of` and the tower gun**
For example `scripts/units/caster_ability.gd:252, 745, 1027` and `champion_abilities.gd:803, 857, 1945`.
- What is wrong: ability and spell target filters that compare `team` directly ignore the truce. Units in a truce
  never auto-attack each other, but an Ice caster's AoE or a champion ability still hits the truce partner.
- Contract: the framework doc only admits this for withdrawn seats.
- Fix: document it in the Truce row, or route the AoE filters through `is_enemy_of`.

**L3. Several MissionConfig defaults change things even though "defaults = untouched"**
`scripts/campaign/mission_config.gd:13-15` and `mission_base.gd:929-933`.
- `easy_skip_types = [&"shadow_knight"]`: every mission drops scripted Shadow Knights on easy, including a boss.
- `count_mult = [0.6, 1.0, 1.4]` scales every scripted group.
- `scaled()` uses `maxi(1, ...)`, so a row count of 0 spawns 1.
- Fix: empty defaults, Mission01 sets its own, and let `scaled(0)` return 0.

**L4. `set_mission_flag` accepts any type, and a String value fails at victory**
`scripts/campaign/campaign_state.gd:207-212` and `mission_base.gd:671`.
- What is wrong: `_clean_flag` ends in `bool(v)`. Godot 4 has no String-to-bool constructor, so a String or
  StringName value is a runtime error in `_apply_reward_flags`, which runs before `save()`.
- Impact: the victory is never saved.
- Fix: type-check in `set_mission_flag` (`push_error` for anything other than bool / int / float).

**L5. MissionHarness: the "set" option is undone by "config", and an empty step list passes**
`tests/helpers/mission_harness.gd:56-60` and `:155-157`.
- With both `config` and `set`, `_ready` sees a new config and `_apply_switches` overwrites the `set` values of
  `casters_enabled`, `t3_enabled` and the other switches.
- `Steps.tick` returns true at once with no steps, so the test prints PASS with nothing checked.
- Fix: apply `set` after `_ready`, or document the order. Treat zero steps as a FAIL.

**L6. `lock_base` does not cover buildings finished later, or the keep upgrade**
`scripts/campaign/mission_base.gd:737-752`.
- A barracks completed during a locked phase can train, and the Keep tier upgrade keeps progressing.
- Fix: listen to `Events.building_completed` while a lock is on, and pause `Keep` upgrade progress when the keep is
  locked.

**L7. `select_tests.ps1` pitfalls**
- `:37`: `& git ... 2>$null` under `$ErrorActionPreference = "Stop"`. In Windows PowerShell 5.1, redirected native
  stderr becomes error records, so any git warning (CRLF warnings when `core.autocrlf=true`, which is Git for Windows'
  default, probably on the desktop) aborts `ci_quick -Changed`.
  - Fix: set `$ErrorActionPreference = "Continue"` around the call and test `$LASTEXITCODE`.
- An unknown `-Base` (a `last-green` commit from the other machine's clone) throws instead of falling back to
  `HEAD~1`.
- Untracked files are always added (`:62`). The untracked `addons/limboai/` folder currently forces the full list on
  every `-Changed` run (seen in the `-Base HEAD~3` run above).
- Generic word matches over-select. `nodes.json` gave 69 tests and `materials.json` 88, and the folder fallback
  treats `export`, `maps` and `previews` as specific names. This is safe but slow.
  - Fix: add those names to `$GenericDirs`.

**L8. The replay lab still reports multi-threaded avoidance after the in-process fix**
- `tools/replay_lab/run_replay.ps1:79, 241, 278-279` still decides `$AvoidanceMT` from `project.godot`.
  `replay_match.gd:72` now turns the threads off in the replay process. So every scorecard prints "expect pos drift"
  and the FAIL hints blame avoidance, which points the triage the wrong way.
- The override also assumes the world's navigation map is created after `_initialize`. Nothing checks this at run
  time.
- Replays recorded by real games still use multi-threaded avoidance, so they cannot replay deterministically.
- Fix: have `replay_match.gd` print the effective setting in the header and have `run_replay.ps1` read it from the
  header. Note in replay-lab.md that only lab-recorded replays are deterministic.

**L9. Smaller points**
- `force_artifacts` (`mission_base.gd:786-801`): the artifact pushed out of a forced slot is removed from the
  inventory, not moved to the freed slot.
- `godot_run.ps1:33`: the hard cap counts the user's editor and F5 game. With both open, the 4th CI run waits the full
  900 s before it starts anyway.
- CLAUDE.md's Events contract line still lists only 5 signals. `events.gd` also has `dialogue`, `cinematic_started`
  and `cinematic_finished`, which MissionBase and the harness use.
- MissionBase overrides `_process` (`:915`): a mission that defines `_process` without calling `super()` silently
  breaks `withdraw_seat`'s exit check. Mention it next to the `_physics_process` note in the doc.

## What is good

- **The mission 1 extraction is careful.** I compared it with `3d024201^:scripts/campaign/mission_01.gd`:
  - the `_ending` guards in `_hold_done` / `_on_vessa_died` are kept;
  - the timers now run on `mission_time()`, which equals `match_time()` without a hold;
  - the economy start, `tiers_enabled` after `super()`, the XP cap and the keep-lost check behave as before.
  The config is applied in `_init`, before the Skirmish builds any keep, which is the right moment for the kits.
- **The MissionConfig / `pick()` design is simple and covers the cases.** Difficulty arrays clamp, one value applies
  to all, and `[]` means untouched. Kits read the scene's own switches (`T3Kit.helpers_here`, `scene_knob`) with no
  new global state.
- **The engine hooks are small and safe:**
  - `Keep.set_start_tier` refunds a running upgrade and skips the flourish;
  - `HelperRoster` routes every price read through `call_essence()` / the stub, including the bot path;
  - `use_artifact_power` returns clear refusal strings;
  - `kill_income_enabled` gates at the single credit point.
- **The truce has a cheap fast path** (`truce_count`, metas only checked when one exists) and it covers both
  `is_enemy_of` and the tower gun.
- **CampaignState int flags are handled correctly.** JSON floats come back as ints (`_clean_flag`), and the test
  checks the round-trip. `save_items: false` and `unlock` are tested.
- **test_mission_framework is a real test.** Every part has positive checks with values in its messages, timing
  windows (the hold clock, `after(2)` at +2.0-2.2 s, the defeat delay of 170+ frames) and a separate static
  CampaignState part. It isolates its save files under `user://`.
- **The early stops are logically correct.** In all four tests, every value the verdict judges only grows, and the
  stop requires exactly the conditions under which `_report` / `_finish` can only PASS:
  - `test_casters_bots` even asks for 3 casts where the report needs 2 for Nature;
  - easy difficulty and the 9.C11 control run never stop early;
  - `--full` brings back the old horizon.
- **test_20_a3's calibration is not a weakening.** 6.5 loop medians is the old 1.5 ms on the quiet laptop, and the
  headroom is the same 1.4x. The loop is best-of-3 while think is a median, so system load makes the check stricter,
  not looser. The ms values are still printed.
- **godot_run.ps1's slot mutexes fix the leaked-semaphore bug the right way:**
  - an abandoned mutex is caught, and PowerShell unwraps the method exception for the typed catch;
  - the release happens in `finally` on the acquiring thread;
  - the exit code is passed through;
  - the hard cap now counts engine processes only.
  The CI and Error Lab kill only their own `cmd` process tree (`taskkill /T`).
- **The Error Lab's per-test timeout now scales with the cap and adds the gate's 900 s wait.** Running slow tests
  first removes the "suite ends on a 35-minute test" tail.
- **`FaceKit.release()` is a targeted fix.** It strips the lambdas out of every style dictionary that other static
  caches share, and it runs once from `root.tree_exiting`, after all children have left the tree.

# Code review: caster units and the tier path (since 40a42dad)

Reviewer: senior code review (read-only, no Godot runs), 2026-10-02.
Scope: `scripts/units/{caster_kit,caster_ability,caster_haze,rime_bulwark}.gd`, `scripts/ai/ai_casters.gd` + its hooks in
`scripts/ai/commander.gd`, the caster parts of `scripts/units/unit.gd`, `scripts/ui/{command_card,selection_manager,
selection_panel,hud,next_step_hint,tier_chip}.gd`, `scripts/buildings/{tier_system,keep,training_building}.gd`,
`data/units/{kilnwarden,rimecarver,bramblesage,gloom_deacon}.tres`, `art/vfx/caster_*_vfx.gd`, `tests/test_casters*.gd`,
`tests/test_tier_path.gd`. Each finding below was checked against the surrounding code; speculative ones were dropped.

## Verdict

Good to keep, with one fix needed before the next playtest against bots. The caster gameplay core (mana, the 0.4 s cast,
re-checks at release, channels, interrupts, death cleanup) is careful and mostly correct, and the player's caster commands
reach the Replay Lab (`caster_cast`, `caster_autocast`). No crash or null-access bug turned up. The real problems are in
the bot layer and in coordination between casters:
- the bot's "hit the enemy caster" rule writes `attack_target` directly, so the soldiers it pulls chase with no leash
  (high);
- the hard Rimecarver spends its mana on Scrying Runes whenever towers or neutral creeps hit its army (medium);
- several casters of one team autocast onto the same clump within the cast window and waste mana (medium);
- `_auto_slag_point` costs O(nearby enemies x all units) on every autocast tick (medium);
- the bot simulation test can pass without testing any casting (medium).

Severity counts: critical 0, high 1, medium 5, low 12.

---

## Findings

### HIGH

**H1. Bot soldiers pulled toward an enemy caster lose their chase leash.** `scripts/ai/ai_casters.gd:990-991`
```gdscript
elif u.attack_target != null or u.is_attack_moving() or not u.has_move_order():
    u.attack_target = best   # keeps its attack-move: back on the way once the caster falls
```
- **What is wrong:** this writes `Unit.attack_target` and leaves `Unit._auto_target` unchanged. Two cases:
  - Idle soldier: `_auto_target` is false, because `command_stop`/`command_move` clear it.
  - Attack-moving soldier with no target yet: `_auto_target` is also false.
  In `Unit._physics_process`, both chase limits need `_auto_target == true` (`unit.gd:1811`, "Attack-move: don't chase
  across the map", and `unit.gd:1816`, "Leash: don't chase an enemy we picked ourselves"). Re-targeting
  (`unit.gd:1798`) is also skipped while a Unit target is set without `_auto_target`. So the soldier treats the caster as
  an explicit player-style order and chases it until it dies.
- **Failure scenario:** the player walks a Kilnwarden within aggro + 2 m (about 11 m) of the bot's idle rally group, then
  walks it back toward their own towers. Every idle bot soldier in reach follows it across the map, one by one, into
  the player's army and towers: a free kiting exploit in every skirmish where the player has a caster. An attack-moving
  bot army on its way to the player's base also drops its attack-move to chase a fleeing caster forever. The comment
  "back on the way once the caster falls" holds only if the caster falls.
- **Fix:** do not write the field. Either:
  - add a public `Unit.set_auto_target(target: Node3D)` that sets `attack_target` and `_auto_target = true` (a contract
    addition, lead), or
  - use `command_attack(best)` only for units that should commit (the hard dive already does this), and only for
    soldiers within the leash.

  Add a test to `test_casters_ai.gd`: an enemy caster passes the idle rally group and then walks 40 m away; the
  soldiers must give up at `_chase_leash()`.

### MEDIUM

**M1. The hard Rimecarver spends its mana on runes under tower fire and while creeping.** `scripts/ai/ai_casters.gd:890-893`
(and `:708`)
- **What is wrong:** rule c "rune_blind" fires when a group member was hit in the last 0.6 s and
  `_any_enemy_near(u, enemies, 12)` is false. `enemies` is `Commander.seen_enemies()`, which holds visible enemy-team
  **units** only. Towers, keeps, other buildings and neutral creeps are not in it. Unlike the Kilnwarden and the
  Bramblesage, the Rimecarver is given `enemies` and not `_with_creeps(...)`.
- **Failure scenario:** a hard Ice bot sieges a base, or creeps a camp. Each second (the 1 s global cooldown) it casts a
  25-mana rune on its own soldier's position, which is already visible. Its 0.8/s regen cannot keep up, so it never has
  50 mana for the dive-guard Bulwark, its main job. Max 3 runes: the oldest is replaced, and the spam goes on.
  `casts_by_rule["rune_blind"]` grows, which also makes `test_casters_bots` pass (see M5).
- **Fix:** before casting, ignore damage whose attacker is visible. Track the last attacker (`take_damage(amount,
  attacker)` already receives it), or skip when an enemy building or a neutral unit stands within 12 m. Also give the
  rule its own cooldown, as `rune_ahead` has with `_rune_at`.

**M2. Several casters of one team cast the same spell at the same target within the cast window.**
`scripts/units/caster_ability.gd:68, 488, 493, 918-923` (Slag Rain); `:945-947` (Mana Scald); `:964-986` (Snagroot)
- **What is wrong:** the "never doubles" guard `_slag_inflight` belongs to each caster instance, not to the team. Between
  `_begin` and the landing there is 0.4 s of cast plus 0.6 s of flight. During that time a second Kilnwarden's autocast
  (0.5 s tick, staggered) sees no slagged unit and nothing of its own in flight, so it fires at the same clump. Slag
  does not stack (the status refreshes), so the second glob is 75 mana for 12 damage. Mana Scald works the same way:
  `scalded` is only applied at release, so two Kilnwardens in the 0.4 s window both scald the same wizard and the second
  burns little or nothing for 50 mana. Two Bramblesages can also both Snagroot one target.
- **Failure scenario:** a player with 3 Kilnwardens on autocast: one clump takes 2-3 Slag Rains within a second, about
  150 mana wasted. Bots with 2-3 casters (hard) do the same through `_kilnwarden_fight`, which reads the same state.
- **Fix:** keep a team-level "claimed" registry in `CasterKit`, next to the bulwark and rune registries:
  - `{team: [{spell, point|target_id, until}]}`;
  - write it in `_begin` and clear it at release or cancel;
  - check it in `_auto_slag_point`, `_auto_scald_target`, `_auto_snag_target` and the bot's fight rules.

**M3. Autocast target search is quadratic.** `scripts/units/caster_ability.gd:899-905` (`_auto_slag_point`), `:301-309` +
`:1034` (`tethers_on` inside `_auto_tithe_target`)
- **What is wrong:**
  - Slag Rain: for every enemy within range + radius, `_enemies_near(e.global_position, r)` scans the whole `"units"`
    group again and allocates a new typed array. Cost per tick is E_near x N_all `is_enemy_of` + distance checks, plus E
    array allocations.
  - Blood Tithe: for each wounded ally in 7 m, `target_reason` calls `tethers_on`, which calls
    `CasterKit.casters_of(...)`: another full scan of `"units"`, with an allocation.
- **Failure scenario:** a late fight with 300+ units, 30 enemies in range of a Kilnwarden, and a hard bot (0.25 s
  reaction) with 2-3 Kilnwardens. That is about 9k checks per caster per tick, or 100k+ per second from this one
  function, in the frame budget that `perf_test` guards. The tithe scan adds k x N per Deacon per tick.
- **Fix:**
  - Slag Rain: every member of a candidate's group is within range + radius of the caster, so count the group from the
    `enemies` list already built at `:899` instead of rescanning: an O(E^2) loop over the small list, with no
    allocation.
  - Blood Tithe: cache the team's Deacons once per autocast tick, or keep a `tether_count` meta on the ally that
    `_start_tithe` / `_end_tithe` update.

**M4. Static caster state is never reset: a Scrying Rune can survive a restart.** `scripts/units/caster_kit.gd:115-116,
400-412, 418, 433-436`; `scripts/ai/ai_casters.gd:92-93`
- **What is wrong:** `CasterKit.reset()` has no caller in the repo. `_runes` entries expire on `now_s()`, which is
  `Engine.get_physics_frames()` and keeps counting across scene reloads. So F9 (restart) within 20 s of a rune keeps it
  live in the new match: `revealed_for()` strips veils and disguises around the old match's rune positions. Two related
  problems:
  - After the first rune ever, `_runes` is never empty (team keys stay with `[]`), so the `_runes.is_empty()`
    early-out in `revealed_for` stops working. Every call (each veiled or disguised unit's tick) then allocates in
    `runes_of(-1)`.
  - `AICasters._last` / `_history` are static as well, so `last_cast(team)` returns the previous match's cast after a
    restart.
- **Failure scenario:** the player casts a rune on the bot's Saboteur path, presses F9, and the new match's Saboteur or
  Mother Hush is revealed near that spot for up to 20 s. This is rare, but it is a state leak across matches, which
  CLAUDE.md asks to avoid (restart = clean match).
- **Fix:**
  - Call `CasterKit.reset()` from the level's `_ready` / `Skirmish._start_match`, next to the other per-match resets
    (lead or systems-coder glue).
  - In `runes_of`, erase empty team keys.
  - Clear `AICasters._last` / `_history` when the first AICasters enters the tree (or key them by level instance).

**M5. `test_casters_bots` can pass without any casting being tested.** `tests/test_casters_bots.gd:217-238`
- **What is wrong:** a side is only judged when it reached the Stronghold at least 90 s before the limit, has a caster
  for 90 s, and logged 8 to 20 s "in fights" (a caster within 10 m of any enemy unit). Otherwise it passes silently:
  - a bot whose tiering breaks never reaches the Stronghold, so the test prints nothing and PASSes;
  - a caster that never meets an enemy needs 0 casts;
  - normal Ice is exempt from the cast count;
  - casts are summed over all rules, so M1's rune spam alone clears the bar of 3.
  The early stop (`_verdict_final`) then ends the run as soon as 3 casts of any kind exist.
- **Failure scenario:** a regression that stops Slag Rain or Pollen Haze autocasting (for example a broken
  `target_reason`) still passes for hard Ice and Shadow sides through `rune_blind` / Tithe casts. A regression that
  delays the Stronghold past `limit - 90` hides the caster checks completely.
- **Fix:**
  - FAIL (not skip) when a normal or hard side never reaches the Stronghold by a known time; `TierSystem.BOT_START`
    gives the window.
  - Judge casts per caster kind on the rules that matter: `autocast` + `fight_*` for Kilnwarden and Bramblesage,
    `dive_guard` for Rimecarver, `autocast` (Tithe) for Deacon. Exclude `rune_blind`.
  - Print which rule supplied the casts.

### LOW

**L1. Cooldown is checked before range, so smart-cast never sends a recharging caster that is out of range.**
`scripts/units/caster_ability.gd:207-217`, `scripts/units/caster_kit.gd:327-333`
- **What is wrong:** `can_cast` returns `Recharging` (global cooldown) before `Out of range`. In `pick_caster`, a caster
  that cast less than 1 s ago and is out of range is therefore not a walk-in candidate.
- **Failure scenario:** a Shift-chain of clicks with one caster says "Recharging" instead of walking toward the next
  point, which `_tick_approach` already tolerates (`:473`).
- **Fix:** check range before the global cooldown when the only blocker is the global cooldown, or let `pick_caster`
  treat `Recharging` with distance > range as a walk candidate.

**L2. The hard-bot Mana Scald wait keeps stale entries.** `scripts/units/caster_ability.gd:950-958`
- **What is wrong:** `_scald_wait[key]` is erased only when the hard rule fires.
- **Failure scenario:** a target that walks out of range and comes back days later finds its old timestamp, so the "wait
  for its cast or 1.5 s" rule is skipped. Dead targets' keys also stay (a small leak).
- **Fix:** erase entries older than about 3 s when the dictionary is read.

**L3. The Seedcloak cloud's VFX stays put while the gameplay haze follows the Bramblesage.**
`art/vfx/caster_nature_vfx.gd:349-362`; `scripts/units/caster_ability.gd:614`
- **What is wrong:** `CasterHaze.spawn(..., unit)` anchors the gameplay cloud to the fleeing Bramblesage
  (`caster_haze.gd:49-51`). `_seedcloak` starts its `_haze(p, ...)` at a fixed `Vector3`, with no `follow` on that fx
  and particles placed once.
- **Failure scenario:** a Bramblesage that flees for 3 s at 4.8 m/s hazes archers about 14 m away from the visible
  cloud.
- **Fix:** set `fx.follow = n` on the haze fx built by `_seedcloak` and move the emitter pair in `_tick` while `follow` is
  set (tech-artist).

**L4. The Bulwark aiming ghost can disagree with the wall that rises.** `scripts/ui/selection_manager.gd:1336-1345` vs
`scripts/units/caster_ability.gd:525-529`
- **What is wrong:** the ghost lies across `point - who.global_position` at click time. The wall uses the caster's
  position at release.
- **Failure scenario:** when the picked Rimecarver has to walk in first, it arrives at another angle and the wall is
  rotated compared with the ghost the player aimed.
- **Fix:** store the facing seen at click time in the target, `{"at": p, "facing": f}`; the cast path already accepts
  that form.

**L5. Replay determinism: instance-id staggers.** `scripts/units/caster_ability.gd:87`, `scripts/ai/ai_casters.gd:553`
- **What is wrong:** the autocast phase (`get_instance_id() % 5`) and the bot's fight spread (`% 3`) depend on object
  ids, which depend on everything the process created before. The pattern already exists (helper, t3, creature
  abilities). It is not new risk, but casters add bot-driven position and cast timing on top.
- **Failure scenario:** a Replay Lab playback started through a different menu path drifts in autocast timing, then in
  the state hash.
- **Fix:** derive the stagger from a per-match spawn counter, or from a hash of `unit_type.id` + spawn frame.

**L6. Mixed selections: Z / V can cast while the card shows no caster buttons.** `scripts/ui/command_card.gd:713` vs
`scripts/ui/selection_manager.gd:1143-1149, 518`
- **What is wrong:** the card shows the caster buttons only when the active subgroup holds casters. Z / V act for "the
  active subgroup's caster type, else the first caster type selected".
- **Failure scenario:** with soldiers active (Tab) in a soldiers + Kilnwarden selection, Z starts Slag Rain aiming with
  nothing on the card. This is documented as "any selection holding casters" in CLAUDE.md, so it is a UX gap, not a
  contract break.
- **Fix:** show the caster buttons whenever `caster_type() != &""`, or say in the help line that Z / V reach the casters
  from any subgroup.

**L7. The keep's rally slot depends on a command-card constant that happens to match the caster slot.**
`scripts/ui/command_card.gd:926`
- **What is wrong:** `n_train > CASTER_SLOTS[0]` uses the spell-button slot list (4, 5). It only matches
  `SelectionManager.CASTER_KEEP_SLOT` (4) by coincidence.
- **Failure scenario:** moving either constant breaks the other.
- **Fix:** use `SelectionManager.CASTER_KEEP_SLOT`.

**L8. Rime Bulwark pushes units out without checking the spot.** `scripts/units/rime_bulwark.gd:165-177`
- **What is wrong:** `_push_units_out` sets `global_position` to the nearer long side without checking water, buildings,
  another wall or the navmesh.
- **Failure scenario:** a wall cast against a keep or a river bank pushes a unit into the building footprint or the
  water.
- **Fix:** reuse `Unit._displace_end`-style checks (navmesh closest point + `river.is_water` + building radius); fall
  back to the other side, or leave the unit in place.

**L9. Dead code and dead data.**
- `Unit.STATUSES.slagged.hero_mult` (`unit.gd:99`) is never applied: every `apply_status(&"slagged", ...)` passes
  `full_duration = true` and picks `slag_big` itself (`caster_ability.gd:506-507`). It reads as if heroes got 2.5 s.
- `CasterKit.reset()` has no caller (M4).
- `best_dist` in `Unit._find_nearest_enemy` (`unit.gd:2134-2147`) is assigned but no longer read since the score
  rewrite.
- `CasterKit.gate_reason` / `MAX_PER_TEAM` are an intentional off-by-default knob (fine; keep it).

**L10. Generated maps silently drop the casters.** `scripts/units/caster_kit.gd:128`
- **What is wrong:** `enabled_here()` matches only the exact `skirmish.gd` resource path. `LayoutLevel extends Skirmish`
  (MT1-MT7 maps such as Thornwater and Quartermeet), so those maps get no caster slot. The bowman, Stables, T3 and
  new-units kits do the same.
- **Failure scenario:** none today, because no menu path loads a LayoutLevel yet. It will become one the day generated
  maps reach the skirmish menu.
- **Fix (all kits):** check `scene is Skirmish and not scene.has_method(&"objectives")`, or a `Skirmish.is_plain_skirmish()`
  method.

**L11. Weak assertions in the tests.**
- `tests/test_casters_ai.gd:280` checks a constant (`AICasters.REACTION[1] == 0.5`), so it cannot fail.
- `tests/test_casters.gd:289, 303-305, 342, 499`: the hero checks (slag 5 s, Scald on the wizard, Snagroot 4 m) sit
  inside `if enemy_hero:` / `if wiz:` and skip silently when no wizard exists. Add `_check(wiz != null, ...)`.
- `status_time_left <= 5.0` (`:304`) also passes at 0.1 s; use `_near(..., 5.0 - 1.2, 0.4)`.
- There is no test for H1 (leash), M1 (rune spam under tower fire) or M2 (double cast).

**L12. Tier card text is cached on wall-clock time.** `scripts/buildings/keep.gd:208-215`
- **What is wrong:** `tier_card_type()`, which the bot reaches through `trainable_types()`, rebuilds the tooltip through
  `TierSystem.unlock_text` -> `unlocks()` (a scan of every building's `trainable_types()`) at most once per
  `Time.get_ticks_msec()` second. Only text depends on it, so gameplay stays deterministic. The cost scales with wall
  time, not game time.
- **Failure scenario:** none today; noted so nobody later moves gameplay data into that cached block.
- **Fix:** none needed. Optionally build the text lazily only when the card asks (a `card_text()` accessor) instead of
  inside `tier_card_type()`.

---

## What is good

- **Cast pipeline correctness.**
  - `can_cast` / `target_reason` follow a clear refusal order that matches the design doc.
  - `_tick_pending` re-checks the target, the mana and the range (with a 2 m slack) at release and charges nothing on
    failure.
  - Daze, freeze and displacement cancel the cast and spend nothing.
  - The bulwark facing passes through `{at, facing}` without a new target type.
- **Death, interrupt and revive hygiene.**
  - `Unit.die()` / `_revive()` clear `_displace` and the cast lock.
  - `CasterAbility._on_died` drops pending casts, approaches and channels, and `_end_tithe` restores `attacks_blocked`.
  - Passage cancels on any new order through `order_serial`, a simple, robust way to detect a player override.
- **`Unit.displace`** samples the line against the navmesh, water, Bulwarks and buildings before moving and emits
  `displaced`, so every channel breaks in one place.
- **Armour floor math** in `_compute_stat` (`unit.gd:504-510`) is correct for positive, zero and already-negative armour,
  and tests cover 15 -> 0 and 25 -> 5.
- **Replay coverage.** The player's smart-cast and autocast toggles are noted (`caster_cast`, `caster_autocast`) and
  replayed through the same SelectionManager entry points. Bot casts are deterministic functions of state.
- **Bot integration.**
  - It goes through read-only Commander accessors.
  - A per-pass cache (`new_pass`) avoids repeated full scans.
  - The first caster comes before the Citadel.
  - The saving window is bounded (45 s on, 30 s off), so the bot never stalls.
- **Tier path UI.**
  - `TierSystem.status()` is one dictionary that the chip, the hint and the card all read.
  - `max_tier` / `bots_upgrade` are respected in `tier_card_type`, `_bot_step` and `status`.
  - The recursion between `Keep.tier_card_type` and `TierSystem.unlocks` is guarded explicitly.
- **VFX** pool their meshes and particles, reuse halos (`_hazed` refreshes instead of stacking), and hide effects in fog.
- **Tests.** `test_casters.gd` checks real numbers (damage, armour, durations, drag distances, tether rates, mana net)
  with tight tolerances, and `test_casters_ui.gd` covers AZERTY and the refusal messages.

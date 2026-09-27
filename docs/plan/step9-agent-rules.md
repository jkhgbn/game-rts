# Step 9 (Champions): rules for every agent

Project: `C:\Users\elzzo\Documents\four-wizards-rts` (Godot 4.7.2, GDScript, static types). Read `CLAUDE.md` first
(Run and test, Code style, Contracts, the **Champions** bullet), then `docs/design/champions.md` (the spec; section 13 =
frozen contracts, section 15 = task list and "Done when").

1. Edit **only** the files your task owns (champions.md section 15) plus your own `tests/test_<task-id>.gd`
   (e.g. `tests/test_9_c1.gd`, copied from `tests/_template.gd`). Need something from another owner? Write it in
   `docs/handoff/for-<agent>.md` and mention it in your final report.
2. **Never run git.** The lead commits.
3. ~15 agents work at the same time. The other parts of step 9 **may not exist yet** while you work:
   - Never use another step-9 agent's new `class_name` as a static type or a static call (`Champion`, `ChampionType`,
     `ChampionGuild`, `BountyBoard`, `Bounty`, `ChampionAbilities`, `ChampionBrain`, `ChampionSense`, `SightMarker`,
     `ChampionVfx`...) unless your task creates it. Reach them through `load("res://...")` guarded by
     `ResourceLoader.exists(path)`, groups (`get_tree().get_nodes_in_group(&"champions")`), `has_method()`, `get()`.
     Existing classes (`Unit`, `Wizard`, `Building`, `Inventory`, `EssenceBank`, `FogOfWar`...) are fine.
   - Tests may stub the missing parts inside the test file.
4. Shared paths everybody codes against:
   - Champion models: `res://art/units/champions/<id>/<id>.tscn` (ids `wayfinder`, `oathwall`, `coin_cutter`, `mender`),
     root script extends the character kit like the other unit models; hooks as in `art-units.md` plus
     `play_cast(ability_id: StringName)`, `set_variant(v: int)`, `set_team_color(c: Color)`.
   - Tavern model: `res://art/buildings/tavern/tavern_model.tscn`; bounty flag model:
     `res://art/buildings/tavern/bounty_flag.tscn` (methods `set_team_color(c)`, `set_kind(kind: int)` 0 Hunt, 1 Explore,
     2 Guard, 3 Escort).
   - Champion VFX: `res://art/vfx/champion_vfx.gd` (`class_name ChampionVfx`, a Node3D in group `"champion_vfx"`;
     callers do `get_tree().get_first_node_in_group(&"champion_vfx")` then `.play(ability_id, caster, target_or_point)`).
   - Scripts: `res://scripts/units/champion.gd`, `champion_type.gd`, `champion_abilities.gd`, `res://scripts/ai/champion_brain.gd`,
     `champion_sense.gd`, `res://scripts/world/champion_guild.gd`, `tavern.gd`, `bounty_board.gd`, `bounty.gd`, `sight_marker.gd`.
5. Godot: never kill a Godot process you did not start (the user may have the editor open; other agents run tests).
   Always pass `--fixed-fps 60 --quit-after N`. Run `--import` after adding scripts. Your final check: your test passes,
   and `tests/smoke_test.gd` still prints `victory=true` if you touched shared gameplay code (timings are noisy while
   many agents run: judge perf only by `stuck=0`).
6. Original IP only. Quality first, no time box.
7. Final report (short): files changed, public API added (exact signatures), what you stubbed or assumed about other
   tasks, test results, anything the lead must glue (scene nodes, `project.godot`, input actions).

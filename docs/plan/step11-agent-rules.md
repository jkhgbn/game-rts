# Step 11 (Champion classes): rules for every agent

Project: `C:\Users\elzzo\Documents\four-wizards-rts` (Godot 4.7.2, GDScript, static types). Read `CLAUDE.md` first
(Run and test, Code style, Contracts incl. **Champions** and **Champion classes**), then `docs/design/skills-rework.md`
(the spec; section 0 = the user's final answers: class drawn at level 2, class skills ADD to the 3 archetype abilities =
6 max, odd pairs rare; section 10 = frozen contracts; section 12 = task list and files; "Done when" at the end) and
`docs/design/champions.md` (the step-9 champions it builds on).

1. Edit **only** the files your task owns (skills-rework.md section 12) plus your own `tests/test_11_<id>.gd`. Step-9
   champion tests whose numbers change (XP table, prices, revive) are updated by the owner of the file that changes them.
   Need something from another owner? `docs/handoff/for-<agent>.md` + mention it in your report.
2. **Never run git.** The lead commits.
3. Step 10 (trade) agents work at the same time in other files. Never use a new step-10 / step-11 `class_name` of another
   agent as a static type (load-guard, groups, `has_method`, `get`); step-9 classes (`Champion`, `ChampionType`,
   `ChampionAbilities`, `ChampionGuild`, `BountyBoard`, `ChampionVfx`...) are fine. `is_instance_valid(x)` before `x is T`.
4. Godot: never kill a Godot process you did not start. Always `--fixed-fps 60 --quit-after N`; `--import` after adding
   scripts. Final check: your test passes; the champion tests (`tests/test_9_c1.gd`, `c2`, `c5`, `c10`) and the smoke
   test still pass if you touched champion or shared gameplay code (perf: judge only `stuck=0` while agents run).
5. Original IP only. Quality first, no time box. Art: painted SC2/LoL look, 0 real lights, champion budgets of
   champions.md 4.6.
6. Final report (short): files changed, public API added (exact signatures), stubs / assumptions, test results, glue.

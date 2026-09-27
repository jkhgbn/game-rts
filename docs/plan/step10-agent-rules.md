# Step 10 (Trade: gold, Bazaar, caravans, Magpies, Greywater Lodges): rules for every agent

Project: `C:\Users\elzzo\Documents\four-wizards-rts` (Godot 4.7.2, GDScript, static types). Read `CLAUDE.md` first
(Run and test, Code style, Contracts incl. the **Trade** and **Champions** bullets), then `docs/design/market-trade.md`
(the spec; section 0 = the user's final decisions, section 12 = frozen contracts, section 14 = task list and files,
"Done when" at the end).

1. Edit **only** the files your task owns (market-trade.md section 14) plus your own `tests/test_10_<id>.gd`
   (e.g. `tests/test_10_c1.gd`, copied from `tests/_template.gd`). Need something from another owner? Write it in
   `docs/handoff/for-<agent>.md` and mention it in your final report.
2. **Never run git.** The lead commits.
3. Many agents work at the same time. Other step-10 parts **may not exist yet**:
   - Never use another step-10 agent's new `class_name` as a static type or static call (`GoldBank`, `TradeNetwork`,
     `TradePost`, `GuildHouse`, `LootSack`, `Market`, `Caravan`, `ThievesGuild`, `HuntersGuild`, `ThiefBand`,
     `TrackerContract`, `TradeVfx`...) unless your task creates it. Reach them through `load("res://...")` guarded by
     `ResourceLoader.exists(path)`, groups, `has_method()`, `get()`. Existing classes (`Unit`, `Wizard`, `Building`,
     `TrainingBuilding`, `EssenceBank`, `Economy`, `FogOfWar`, `Champion`, `ChampionGuild`, `BountyBoard`...) are fine.
   - Tests may stub the missing parts inside the test file.
   - Check `is_instance_valid(x)` **before** `x is SomeClass` (the other order errors on freed objects).
4. Shared paths: see market-trade.md section 12 "Models / VFX paths" (Bazaars, caravan, magpie, tracker, den, lodge,
   trading post, loot sack, `art/vfx/trade_vfx.gd`). Models expose the hooks listed in section 9.
5. Godot: never kill a Godot process you did not start (the user may have the editor open; other agents run tests).
   Always pass `--fixed-fps 60 --quit-after N`. Run `--import` after adding scripts. Your final check: your test passes,
   and `tests/smoke_test.gd` still prints `victory=true` if you touched shared gameplay code (timings are noisy while
   many agents run: judge perf only by `stuck=0`).
6. Original IP only. Quality first, no time box. Art: painted SC2/LoL look (`art-keep.md` section 0), 0 real lights
   unless the spec says otherwise; BuildingMerge needs indexed SurfaceTool meshes (`st.index()` after `generate_normals()`).
7. Final report (short): files changed, public API added (exact signatures), what you stubbed or assumed about other
   tasks, test results, anything the lead must glue (scene nodes, `project.godot`, input actions).

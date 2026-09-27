# Visual Diff Lab history

One row per lab run (`tools/visual_diff_lab/run_visual_diff_lab.ps1`, docs/plan/visual-diff-lab.md). Mode `golden` = the references were (re)recorded; `check` = diff against them.

| When | Commit | Mode | Result | Score | Summary |
|---|---|---|---|---|---|
| 2026-09-26 23:49:09 | main@6fc1f1e56e+wip | golden | GOLDEN | - | 9 golden(s) recorded: menu_main, map_player_base, map_centre, map_west_meadow, map_overview, lineup_fire, lineup_ice, lineup_nature, lineup_shadow |
| 2026-09-26 23:50:35 | main@6fc1f1e56e+wip | check | PASS | 100 | all 9 shots unchanged |
| 2026-09-26 23:56:17 | main@6fc1f1e56e+wip | golden | GOLDEN | - | 2 golden(s) recorded: map_centre, map_overview |
| 2026-09-26 23:58:11 | main@ccb98e65df+wip | check | FAIL | 97 | menu_main FAIL 1.00%, map_centre WARN 0.28%, map_overview WARN 0.18% |
| 2026-09-27 00:01:39 | main@86810afdc0+wip | golden | GOLDEN | - | 9 golden(s) recorded: menu_main, map_player_base, map_centre, map_west_meadow, map_overview, lineup_fire, lineup_ice, lineup_nature, lineup_shadow |
| 2026-09-27 00:02:31 | main@86810afdc0+wip | check | FAIL | 96 | menu_main FAIL 1.43% |
| 2026-09-27 00:06:16 | main@86810afdc0+wip | golden | GOLDEN | - | 9 golden(s) recorded: menu_main, map_player_base, map_centre, map_west_meadow, map_overview, lineup_fire, lineup_ice, lineup_nature, lineup_shadow |
| 2026-09-27 00:07:49 | main@c48d59cfc1+wip | check | PASS | 100 | all 9 shots unchanged |

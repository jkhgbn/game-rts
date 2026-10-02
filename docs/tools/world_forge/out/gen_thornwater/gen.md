# World Forge gen: thornwater

`run_world_forge.ps1 gen thornwater archetype=river_split players=2 tempo=standard biome=meadow count=40` (size 120 m). Grid pre-filter 135.9 s.

## Pick
**thornwater_s26**: Map Lab WARN 98 after 1 fix round(s). Adopt: copy `data/maps/gen/thornwater_s26.map` to `data/maps/<name>.map`, change the `map` id, run `map <name>`.

## Map Lab finals (top 3 of the sweep)
| Candidate | Grid | Map Lab | FAIL checks | Fix rounds | Log |
|---|---|---|---|---|---|
| thornwater_s26 | -0.05 | WARN 98 | 0 | 1 | round 0: Map Lab FAIL 82 (2 FAIL checks), 4 fixable move(s); round 1: Map Lab WARN 98 (0 FAIL checks), 0 fixable move(s) |
| thornwater_s2 | -0.10 | WARN 95 | 0 | 0 | round 0: Map Lab WARN 95 (0 FAIL checks), 2 fixable move(s) |
| thornwater_s40 | -0.04 | FAIL 83 | 2 | 2 | round 0: Map Lab FAIL 87 (1 FAIL checks), 4 fixable move(s); round 1: Map Lab FAIL 82 (2 FAIL checks), 1 fixable move(s); round 2: Map Lab FAIL 83 (2 FAIL checks), 0 fixable move(s) |

## Sweep (grid pre-filter, best first; targets { "keep_enemy": (116.0, 150.0), "natural": (38.0, 58.0), "rich": (65.0, 95.0), "crown": (50.0, 72.0) })
| # | Seed | Grid score | Unreachable | keep_enemy | natural | rich | crown | contest |
|---|---|---|---|---|---|---|---|---|
| 1 | 2 | -0.10 | 0 | 124 | 51 | 84 | 62 | 9 |
| 2 | 26 | -0.05 | 0 | 124 | 49 | 85 | 62 | 8 |
| 3 | 40 | -0.04 | 0 | 120 | 46 | 80 | 60 | 9 |
| 4 | 21 | -0.04 | 0 | 125 | 52 | 83 | 62 | 8 |
| 5 | 20 | -0.04 | 0 | 122 | 47 | 83 | 61 | 8 |
| 6 | 10 | -0.04 | 0 | 121 | 45 | 83 | 60 | 9 |
| 7 | 32 | -0.04 | 0 | 119 | 47 | 81 | 60 | 9 |
| 8 | 7 | -0.03 | 0 | 124 | 45 | 85 | 62 | 8 |
| 9 | 16 | -0.02 | 0 | 125 | 46 | 89 | 62 | 9 |
| 10 | 1 | -0.02 | 0 | 124 | 47 | 87 | 62 | 8 |
| 11 | 12 | -0.02 | 0 | 122 | 45 | 83 | 61 | 8 |
| 12 | 4 | -0.02 | 0 | 122 | 49 | 85 | 61 | 8 |
| 13 | 9 | -0.01 | 0 | 121 | 46 | 81 | 60 | 8 |
| 14 | 8 | -0.00 | 0 | 119 | 47 | 83 | 59 | 9 |
| 15 | 22 | 0.01 | 0 | 120 | 47 | 81 | 60 | 8 |
| 16 | 23 | 0.01 | 0 | 120 | 47 | 83 | 60 | 8 |
| 17 | 29 | 0.01 | 0 | 121 | 51 | 82 | 60 | 8 |
| 18 | 17 | 0.02 | 0 | 122 | 44 | 85 | 61 | 8 |
| 19 | 30 | 0.03 | 0 | 120 | 46 | 84 | 60 | 8 |
| 20 | 11 | 0.03 | 0 | 121 | 50 | 82 | 61 | 7 |
| 21 | 13 | 0.03 | 0 | 121 | 48 | 87 | 60 | 8 |
| 22 | 38 | 0.03 | 0 | 119 | 46 | 79 | 60 | 8 |
| 23 | 31 | 0.04 | 0 | 119 | 46 | 78 | 59 | 8 |
| 24 | 6 | 0.05 | 0 | 123 | 45 | 86 | 61 | 7 |
| 25 | 27 | 0.05 | 0 | 121 | 49 | 84 | 60 | 7 |
| 26 | 24 | 0.05 | 0 | 119 | 49 | 85 | 60 | 8 |
| 27 | 14 | 0.05 | 0 | 122 | 49 | 86 | 61 | 7 |
| 28 | 35 | 0.05 | 0 | 118 | 49 | 83 | 59 | 8 |
| 29 | 19 | 0.05 | 0 | 124 | 53 | 85 | 62 | 7 |
| 30 | 34 | 0.06 | 0 | 121 | 42 | 79 | 60 | 8 |
| 31 | 28 | 0.08 | 0 | 119 | 43 | 79 | 59 | 8 |
| 32 | 36 | 0.08 | 0 | 118 | 43 | 85 | 59 | 9 |
| 33 | 3 | 0.11 | 0 | 125 | 48 | 89 | 62 | 6 |
| 34 | 37 | 0.12 | 0 | 120 | 45 | 78 | 60 | 6 |
| 35 | 39 | 0.14 | 0 | 119 | 41 | 83 | 60 | 8 |
| 36 | 33 | 0.15 | 0 | 120 | 43 | 85 | 60 | 7 |
| 37 | 5 | 0.15 | 0 | 119 | 41 | 84 | 59 | 8 |
| 38 | 25 | 0.17 | 0 | 119 | 46 | 89 | 60 | 7 |
| 39 | 18 | 0.20 | 0 | 119 | 41 | 84 | 59 | 7 |
| 40 | 15 | 0.31 | 0 | 119 | 40 | 83 | 60 | 6 |

![contact sheet](contact_sheet.png)

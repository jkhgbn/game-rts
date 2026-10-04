# Map gate thornwater (hard)

12 matches (0 failed). Commit: main@c8dda2d7ad. difficulty hard, style balanced, sim full, tick 60, limit 30:00, early on (12).
Targets (rush-balance.md 8): win 45-55 % [ok] (pass band [near]: pairs 33-67 %, kingdoms 43-57 %; else [OUT]), median length 15:00-20:00 [ok] (per pair 13:30-21:30 [near]), no winner at 24:00 <= 10 %, mirrors 40-60 % player side. Small N: read the counts.

## Win % matrix (row kingdom vs column kingdom, both side orders)
Cell: row win % (wins-games). Diagonal: mirror, player-side win %.

| | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| **Fire** | 0 % (0-3) [OUT] | - | - | - |
| **Shadow** | - | 33 % (1-3) [OUT] | - | - |
| **Ice** | - | - | 67 % (2-3) [OUT] | - |
| **Nature** | - | - | - | 0 % (0-3) [OUT] |

## Per kingdom (non-mirror games)
| Kingdom | Win % | W-G | Median length | Peak army pop | Peak workers | Crystals gathered | Attacks |
|---|---|---|---|---|---|---|---|
| Fire | - | 0-0 | - | - | - | - | - |
| Shadow | - | 0-0 | - | - | - | - | - |
| Ice | - | 0-0 | - | - | - | - | - |
| Nature | - | 0-0 | - | - | - | - | - |

## Match length
Overall: median **13:44** [OUT], p90 18:22, min 10:13, max 26:50 (n = 12).

| Pair (unordered) | Games | Median | p90 | Pair win % |
|---|---|---|---|---|
| Fire vs Fire | 3 | 11:45 [OUT] | 15:43 | player side 0 % |
| Shadow vs Shadow | 3 | 12:25 [OUT] | 23:57 | player side 33 % |
| Ice vs Ice | 3 | 15:02 [ok] | 17:48 | player side 67 % |
| Nature vs Nature | 3 | 16:13 [ok] | 17:08 | player side 0 % |

## How matches ended
| Reason | Matches | Share |
|---|---|---|
| concede | 9 | 75 % |
| early-score | 3 | 25 % |

No real winner (kill / concede) by 24:00: **33 %** (4 of 12) [OUT]. Early-score and time-score ends count here.

## Stalls
| Flag | Matches |
|---|---|
| player_no_workers | 2 |
| enemy_no_workers | 1 |

## Speed
Median sim speed x2.9 (game seconds per real second, one process). Sum of match real time 64:37 for 179:42 of game time; average 323 s per match.
CPU time 49:44 in total: 332 CPU s per 20 game minutes (the cost on a free core).
Batch wall clock 18:42 with 4 in parallel: **39 matches per hour**.

## Start-up (medians, real s; same machine load as the batch)
Load 2.2 s, level build 0.0 s, first navmesh bake 5.2 s, whole start-up 7.5 s, whole match 286 s (n = 12).
Navmesh cache: the first bake is only 1.8 % of a match (5.2 s): not worth a main.gd hook.

## Next steps
- 3 of 12 matches left a side with no worker for over a minute: the bots don't rebuild workers (ai-coder handoff, ai.md) - fix before tuning stats.

## Matches
| Pair | Seed | Winner | Reason | Time | Score (P-E) | Peak army (P-E) | Workers peak (P-E) | Stall flags | Real s |
|---|---|---|---|---|---|---|---|---|---|
| fire:fire | 1 | Fire | concede | 11:44 | 9928-9181 | 10-11 | 9-9 |  | 222 |
| fire:fire | 2 | Fire | concede | 11:25 | 8016-9121 | 10-12 | 9-9 |  | 253 |
| fire:fire | 3 | Fire | early-score | 16:43 | 11632-20981 | 7-12 | 9-11 |  | 362 |
| ice:ice | 1 | Ice | early-score | 15:02 | 15265-8624 | 15-9 | 12-9 |  | 320 |
| ice:ice | 2 | Ice | early-score | 18:29 | 21392-14095 | 9-9 | 9-9 |  | 421 |
| ice:ice | 3 | Ice | concede | 12:20 | 8707-11583 | 8-9 | 9-10 |  | 233 |
| nature:nature | 1 | Nature | concede | 10:12 | 6560-14816 | 8-17 | 9-9 |  | 242 |
| nature:nature | 2 | Nature | concede | 17:21 | 18332-22809 | 22-15 | 9-12 | player_no_workers | 472 |
| nature:nature | 3 | Nature | concede | 16:12 | 17947-15262 | 14-13 | 11-9 |  | 326 |
| shadow:shadow | 1 | Shadow | concede | 12:24 | 10282-14732 | 10-17 | 9-9 | player_no_workers | 248 |
| shadow:shadow | 2 | Shadow | concede | 10:54 | 12733-10408 | 11-12 | 9-9 | enemy_no_workers | 252 |
| shadow:shadow | 3 | Shadow | concede | 26:49 | 24672-33444 | 11-12 | 9-9 |  | 527 |

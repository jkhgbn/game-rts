# Map gate thornwater (normal)

16 matches (0 failed). Commit: main@393116f2d6. difficulty normal, style balanced, sim full, tick 60, limit 30:00, early on (16).
Targets (rush-balance.md 8): win 45-55 % [ok] (pass band [near]: pairs 33-67 %, kingdoms 43-57 %; else [OUT]), median length 15:00-20:00 [ok] (per pair 13:30-21:30 [near]), no winner at 24:00 <= 10 %, mirrors 40-60 % player side. Small N: read the counts.

## Win % matrix (row kingdom vs column kingdom, both side orders)
Cell: row win % (wins-games). Diagonal: mirror, player-side win %.

| | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| **Fire** | 25 % (1-4) [OUT] | - | - | - |
| **Shadow** | - | 25 % (1-4) [OUT] | - | - |
| **Ice** | - | - | 25 % (1-4) [OUT] | - |
| **Nature** | - | - | - | 50 % (2-4) [ok] |

## Per kingdom (non-mirror games)
| Kingdom | Win % | W-G | Median length | Peak army pop | Peak workers | Crystals gathered | Attacks |
|---|---|---|---|---|---|---|---|
| Fire | - | 0-0 | - | - | - | - | - |
| Shadow | - | 0-0 | - | - | - | - | - |
| Ice | - | 0-0 | - | - | - | - | - |
| Nature | - | 0-0 | - | - | - | - | - |

## Match length
Overall: median **14:03** [OUT], p90 20:27, min 10:13, max 27:18 (n = 16).

| Pair (unordered) | Games | Median | p90 | Pair win % |
|---|---|---|---|---|
| Fire vs Fire | 4 | 13:35 [near] | 18:26 | player side 25 % |
| Shadow vs Shadow | 4 | 16:00 [ok] | 24:50 | player side 25 % |
| Ice vs Ice | 4 | 12:23 [OUT] | 12:56 | player side 25 % |
| Nature vs Nature | 4 | 18:26 [ok] | 20:28 | player side 50 % |

## How matches ended
| Reason | Matches | Share |
|---|---|---|
| concede | 14 | 88 % |
| early-score | 2 | 13 % |

No real winner (kill / concede) by 24:00: **19 %** (3 of 16) [OUT]. Early-score and time-score ends count here.

## Stalls
| Flag | Matches |
|---|---|
| player_no_workers | 2 |
| enemy_no_workers | 1 |

## Speed
Median sim speed x2.6 (game seconds per real second, one process). Sum of match real time 97:38 for 250:11 of game time; average 366 s per match.
CPU time 75:23 in total: 362 CPU s per 20 game minutes (the cost on a free core).
Batch wall clock 26:54 with 4 in parallel: **36 matches per hour**.

## Start-up (medians, real s; same machine load as the batch)
Load 2.2 s, level build 0.0 s, first navmesh bake 5.0 s, whole start-up 7.3 s, whole match 327 s (n = 16).
Navmesh cache: the first bake is only 1.5 % of a match (5.0 s): not worth a main.gd hook.

## Next steps
Nothing flagged by this batch.

## Matches
| Pair | Seed | Winner | Reason | Time | Score (P-E) | Peak army (P-E) | Workers peak (P-E) | Stall flags | Real s |
|---|---|---|---|---|---|---|---|---|---|
| fire:fire | 1 | Fire | concede | 19:53 | 17729-17624 | 14-16 | 9-12 |  | 503 |
| fire:fire | 2 | Fire | concede | 14:59 | 10494-10065 | 11-11 | 9-9 |  | 348 |
| fire:fire | 3 | Fire | concede | 12:09 | 9372-9797 | 11-10 | 9-9 |  | 268 |
| fire:fire | 4 | Fire | concede | 10:38 | 5818-5862 | 11-10 | 8-9 |  | 221 |
| ice:ice | 1 | Ice | concede | 12:12 | 7276-10980 | 7-15 | 9-12 |  | 288 |
| ice:ice | 2 | Ice | concede | 12:31 | 9291-11479 | 14-8 | 9-9 |  | 298 |
| ice:ice | 3 | Ice | concede | 13:05 | 8997-14011 | 12-14 | 9-9 |  | 303 |
| ice:ice | 4 | Ice | concede | 10:12 | 6437-10903 | 12-14 | 9-9 |  | 218 |
| nature:nature | 1 | Nature | concede | 20:58 | 21655-20069 | 18-17 | 9-12 | player_no_workers | 634 |
| nature:nature | 2 | Nature | concede | 19:13 | 14271-18809 | 12-19 | 9-9 |  | 490 |
| nature:nature | 3 | Nature | early-score | 16:09 | 11021-18700 | 14-20 | 9-9 |  | 401 |
| nature:nature | 4 | Nature | concede | 17:36 | 17753-15664 | 16-18 | 11-9 |  | 373 |
| shadow:shadow | 1 | Shadow | concede | 19:04 | 16796-15210 | 14-17 | 9-9 |  | 450 |
| shadow:shadow | 2 | Shadow | early-score | 11:07 | 5888-14608 | 8-15 | 9-9 | player_no_workers | 253 |
| shadow:shadow | 3 | Shadow | concede | 12:54 | 11764-13641 | 13-13 | 9-9 |  | 307 |
| shadow:shadow | 4 | Shadow | concede | 27:17 | 24409-17250 | 11-15 | 9-9 | enemy_no_workers | 505 |

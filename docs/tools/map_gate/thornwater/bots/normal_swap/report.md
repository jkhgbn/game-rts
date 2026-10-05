# Map gate thornwater (normal, seats swapped)

40 matches (0 failed). Commit: main@f36635d463. difficulty normal, style balanced, sim full, tick 60, limit 30:00, early on (40).
Targets (rush-balance.md 8): win 45-55 % [ok] (pass band [near]: pairs 33-67 %, kingdoms 43-57 %; else [OUT]), median length 15:00-20:00 [ok] (per pair 13:30-21:30 [near]), no winner at 24:00 <= 10 %, mirrors 40-60 % player side. Small N: read the counts.

## Win % matrix (row kingdom vs column kingdom, both side orders)
Cell: row win % (wins-games). Diagonal: mirror, player-side win %.

| | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| **Fire** | 60 % (6-10) [near] | - | - | - |
| **Shadow** | - | 40 % (4-10) [near] | - | - |
| **Ice** | - | - | 50 % (5-10) [ok] | - |
| **Nature** | - | - | - | 60 % (6-10) [near] |

## Per kingdom (non-mirror games)
| Kingdom | Win % | W-G | Median length | Peak army pop | Peak workers | Crystals gathered | Attacks |
|---|---|---|---|---|---|---|---|
| Fire | - | 0-0 | - | - | - | - | - |
| Shadow | - | 0-0 | - | - | - | - | - |
| Ice | - | 0-0 | - | - | - | - | - |
| Nature | - | 0-0 | - | - | - | - | - |

## Match length
Overall: median **13:59** [OUT], p90 25:55, min 9:51, max 30:00 (n = 40).

| Pair (unordered) | Games | Median | p90 | Pair win % |
|---|---|---|---|---|
| Fire vs Fire | 10 | 12:09 [OUT] | 25:58 | player side 60 % |
| Shadow vs Shadow | 10 | 12:46 [OUT] | 18:42 | player side 40 % |
| Ice vs Ice | 10 | 15:19 [ok] | 21:15 | player side 50 % |
| Nature vs Nature | 10 | 13:55 [near] | 30:00 | player side 60 % |

## How matches ended
| Reason | Matches | Share |
|---|---|---|
| concede | 33 | 83 % |
| early-score | 5 | 13 % |
| time-score | 2 | 5 % |

No real winner (kill / concede) by 24:00: **28 %** (11 of 40) [OUT]. Early-score and time-score ends count here.

## Stalls
| Flag | Matches |
|---|---|
| player_no_workers | 7 |
| enemy_no_workers | 7 |

## Speed
Median sim speed x3.2 (game seconds per real second, one process). Sum of match real time 204:14 for 640:24 of game time; average 306 s per match.
CPU time 152:55 in total: 287 CPU s per 20 game minutes (the cost on a free core).
Batch wall clock 23:34 with 4 in parallel: **102 matches per hour**.

## Start-up (medians, real s; same machine load as the batch)
Load 2.2 s, level build 0.0 s, first navmesh bake 5.0 s, whole start-up 7.2 s, whole match 270 s (n = 40).
Navmesh cache: the first bake is only 1.8 % of a match (5.0 s): not worth a main.gd hook.

## Next steps
- 12 of 40 matches left a side with no worker for over a minute: the bots don't rebuild workers (ai-coder handoff, ai.md) - fix before tuning stats.

## Matches
| Pair | Seed | Winner | Reason | Time | Score (P-E) | Peak army (P-E) | Workers peak (P-E) | Stall flags | Real s |
|---|---|---|---|---|---|---|---|---|---|
| fire:fire | 1 | Fire | concede | 28:23 | 24217-32366 | 14-14 | 12-12 | player_no_workers, enemy_no_workers | 572 |
| fire:fire | 2 | Fire | concede | 10:36 | 8587-8326 | 11-10 | 9-9 |  | 197 |
| fire:fire | 3 | Fire | concede | 11:56 | 9422-6775 | 11-12 | 9-9 |  | 208 |
| fire:fire | 4 | Fire | concede | 9:50 | 8872-5775 | 14-10 | 9-9 |  | 176 |
| fire:fire | 5 | Fire | concede | 25:41 | 20892-18515 | 11-12 | 9-12 | enemy_no_workers | 495 |
| fire:fire | 6 | Fire | concede | 10:25 | 6815-8362 | 9-12 | 8-9 |  | 180 |
| fire:fire | 7 | Fire | early-score | 12:20 | 7564-12892 | 10-12 | 10-10 |  | 151 |
| fire:fire | 8 | Fire | concede | 11:49 | 5218-8141 | 8-11 | 9-9 |  | 172 |
| fire:fire | 9 | Fire | concede | 14:34 | 13325-8804 | 13-12 | 9-9 |  | 281 |
| fire:fire | 10 | Fire | concede | 20:00 | 21288-17789 | 15-8 | 12-9 | player_no_workers | 411 |
| ice:ice | 1 | Ice | concede | 14:39 | 12790-11769 | 13-16 | 9-9 |  | 256 |
| ice:ice | 2 | Ice | early-score | 11:31 | 6243-13377 | 9-15 | 9-9 | player_no_workers | 220 |
| ice:ice | 3 | Ice | concede | 13:47 | 10589-12683 | 10-15 | 9-9 |  | 269 |
| ice:ice | 4 | Ice | concede | 10:31 | 9750-8906 | 14-11 | 9-9 |  | 195 |
| ice:ice | 5 | Ice | concede | 16:55 | 18964-12465 | 15-16 | 9-9 |  | 343 |
| ice:ice | 6 | Ice | concede | 15:23 | 13709-12685 | 14-10 | 9-9 |  | 274 |
| ice:ice | 7 | Ice | concede | 20:30 | 17248-15543 | 17-10 | 9-9 |  | 312 |
| ice:ice | 8 | Ice | concede | 15:13 | 16504-12313 | 15-16 | 9-9 |  | 305 |
| ice:ice | 9 | Ice | concede | 16:17 | 17689-11923 | 12-14 | 9-9 |  | 341 |
| ice:ice | 10 | Ice | concede | 27:53 | 24462-21137 | 13-13 | 9-12 | enemy_no_workers | 520 |
| nature:nature | 1 | Nature | concede | 11:35 | 8035-11042 | 19-17 | 9-9 |  | 223 |
| nature:nature | 2 | Nature | concede | 13:39 | 15456-10805 | 16-17 | 9-9 |  | 317 |
| nature:nature | 3 | Nature | early-score | 11:01 | 12439-6935 | 15-12 | 10-9 |  | 257 |
| nature:nature | 4 | Nature | concede | 24:43 | 23825-23406 | 15-14 | 9-12 | enemy_no_workers | 530 |
| nature:nature | 5 | Nature | early-score | 14:10 | 14844-8718 | 19-11 | 9-9 |  | 319 |
| nature:nature | 6 | Nature | time-score | 30:00 | 26967-27602 | 17-15 | 11-9 | enemy_no_workers | 555 |
| nature:nature | 7 | Nature | time-score | 30:00 | 30956-26912 | 16-15 | 12-12 | player_no_workers, enemy_no_workers | 569 |
| nature:nature | 8 | Nature | early-score | 11:01 | 7469-13371 | 17-20 | 9-9 |  | 254 |
| nature:nature | 9 | Nature | concede | 12:40 | 11882-9728 | 15-11 | 9-9 |  | 271 |
| nature:nature | 10 | Nature | concede | 19:06 | 18287-23367 | 15-20 | 12-12 | player_no_workers | 433 |
| shadow:shadow | 1 | Shadow | concede | 10:21 | 7581-10917 | 8-17 | 9-9 |  | 169 |
| shadow:shadow | 2 | Shadow | concede | 11:56 | 11653-10745 | 9-20 | 9-9 |  | 232 |
| shadow:shadow | 3 | Shadow | concede | 21:50 | 14165-16244 | 17-15 | 9-9 |  | 429 |
| shadow:shadow | 4 | Shadow | concede | 12:46 | 7936-11829 | 12-12 | 9-9 | player_no_workers | 239 |
| shadow:shadow | 5 | Shadow | concede | 12:43 | 8182-12095 | 11-11 | 9-9 |  | 225 |
| shadow:shadow | 6 | Shadow | concede | 12:42 | 8320-10125 | 11-12 | 9-9 | player_no_workers | 227 |
| shadow:shadow | 7 | Shadow | concede | 17:04 | 19151-17045 | 13-13 | 12-9 |  | 242 |
| shadow:shadow | 8 | Shadow | concede | 18:20 | 17878-16074 | 14-17 | 12-9 |  | 376 |
| shadow:shadow | 9 | Shadow | concede | 11:20 | 13679-7154 | 12-8 | 9-9 | enemy_no_workers | 219 |
| shadow:shadow | 10 | Shadow | concede | 14:41 | 13452-13085 | 16-14 | 9-9 |  | 290 |

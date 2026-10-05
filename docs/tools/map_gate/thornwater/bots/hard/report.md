# Map gate thornwater (hard)

43 matches (0 failed). Commit: main@c8dda2d7ad, main@f36635d463. difficulty hard, style balanced, sim full, tick 60, limit 30:00, early on (43).
Targets (rush-balance.md 8): win 45-55 % [ok] (pass band [near]: pairs 33-67 %, kingdoms 43-57 %; else [OUT]), median length 15:00-20:00 [ok] (per pair 13:30-21:30 [near]), no winner at 24:00 <= 10 %, mirrors 40-60 % player side. Small N: read the counts.

## Win % matrix (row kingdom vs column kingdom, both side orders)
Cell: row win % (wins-games). Diagonal: mirror, player-side win %.

| | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| **Fire** | 25 % (3-12) [OUT] | - | - | - |
| **Shadow** | - | 36 % (4-11) [OUT] | - | - |
| **Ice** | - | - | 30 % (3-10) [OUT] | - |
| **Nature** | - | - | - | 30 % (3-10) [OUT] |

## Per kingdom (non-mirror games)
| Kingdom | Win % | W-G | Median length | Peak army pop | Peak workers | Crystals gathered | Attacks |
|---|---|---|---|---|---|---|---|
| Fire | - | 0-0 | - | - | - | - | - |
| Shadow | - | 0-0 | - | - | - | - | - |
| Ice | - | 0-0 | - | - | - | - | - |
| Nature | - | 0-0 | - | - | - | - | - |

## Match length
Overall: median **13:23** [OUT], p90 23:17, min 10:13, max 30:00 (n = 43).

| Pair (unordered) | Games | Median | p90 | Pair win % |
|---|---|---|---|---|
| Fire vs Fire | 12 | 12:20 [OUT] | 21:50 | player side 25 % |
| Shadow vs Shadow | 11 | 11:51 [OUT] | 20:02 | player side 36 % |
| Ice vs Ice | 10 | 13:47 [near] | 16:55 | player side 30 % |
| Nature vs Nature | 10 | 15:54 [ok] | 25:35 | player side 30 % |

## How matches ended
| Reason | Matches | Share |
|---|---|---|
| concede | 36 | 84 % |
| early-score | 6 | 14 % |
| time-score | 1 | 2 % |

No real winner (kill / concede) by 24:00: **23 %** (10 of 43) [OUT]. Early-score and time-score ends count here.

## Stalls
| Flag | Matches |
|---|---|
| player_no_workers | 5 |
| enemy_no_workers | 4 |

## Speed
Median sim speed x3.1 (game seconds per real second, one process). Sum of match real time 222:01 for 647:22 of game time; average 310 s per match.
CPU time 180:40 in total: 335 CPU s per 20 game minutes (the cost on a free core).
Batch wall clock 31:31 with 4 in parallel: **82 matches per hour**.

## Start-up (medians, real s; same machine load as the batch)
Load 2.2 s, level build 0.0 s, first navmesh bake 5.2 s, whole start-up 7.7 s, whole match 270 s (n = 43).
Navmesh cache: the first bake is only 1.9 % of a match (5.2 s): not worth a main.gd hook.

## Next steps
Nothing flagged by this batch.

## Matches
| Pair | Seed | Winner | Reason | Time | Score (P-E) | Peak army (P-E) | Workers peak (P-E) | Stall flags | Real s |
|---|---|---|---|---|---|---|---|---|---|
| fire:fire | 1 | Fire | concede | 11:44 | 9928-9181 | 10-11 | 9-9 |  | 222 |
| fire:fire | 2 | Fire | concede | 11:25 | 8016-9121 | 10-12 | 9-9 |  | 253 |
| fire:fire | 3 | Fire | early-score | 16:43 | 11632-20981 | 7-12 | 9-11 |  | 362 |
| fire:fire | 4 | Fire | concede | 12:40 | 12031-10966 | 13-9 | 9-9 |  | 242 |
| fire:fire | 5 | Fire | concede | 10:31 | 8338-7881 | 7-8 | 8-9 |  | 185 |
| fire:fire | 6 | Fire | concede | 10:27 | 9901-7306 | 9-10 | 8-9 |  | 190 |
| fire:fire | 6 | Fire | early-score | 14:45 | 7880-13114 | 8-12 | 9-9 |  | 270 |
| fire:fire | 7 | Fire | concede | 10:24 | 10321-7398 | 12-9 | 9-9 |  | 190 |
| fire:fire | 7 | Fire | concede | 12:48 | 9012-13037 | 10-9 | 9-9 |  | 248 |
| fire:fire | 8 | Fire | concede | 22:24 | 23485-26053 | 18-8 | 12-12 | player_no_workers | 451 |
| fire:fire | 9 | Fire | concede | 11:58 | 8799-8318 | 6-9 | 6-9 |  | 218 |
| fire:fire | 10 | Fire | concede | 26:38 | 29951-29473 | 9-17 | 12-12 | enemy_no_workers | 526 |
| ice:ice | 1 | Ice | early-score | 15:02 | 15265-8624 | 15-9 | 12-9 |  | 320 |
| ice:ice | 2 | Ice | early-score | 18:29 | 21392-14095 | 9-9 | 9-9 |  | 421 |
| ice:ice | 3 | Ice | concede | 12:20 | 8707-11583 | 8-9 | 9-10 |  | 233 |
| ice:ice | 4 | Ice | early-score | 11:41 | 7068-13149 | 6-20 | 9-9 |  | 227 |
| ice:ice | 5 | Ice | concede | 14:11 | 10775-16442 | 9-13 | 9-9 |  | 273 |
| ice:ice | 6 | Ice | concede | 16:44 | 12060-19716 | 9-11 | 9-9 |  | 332 |
| ice:ice | 7 | Ice | concede | 13:22 | 10931-11016 | 12-9 | 12-9 | enemy_no_workers | 240 |
| ice:ice | 8 | Ice | concede | 14:33 | 11482-17323 | 12-17 | 9-12 |  | 299 |
| ice:ice | 9 | Ice | concede | 10:52 | 6313-10445 | 9-14 | 8-9 |  | 204 |
| ice:ice | 10 | Ice | concede | 11:57 | 8764-8580 | 10-7 | 9-9 | player_no_workers | 218 |
| nature:nature | 1 | Nature | concede | 10:12 | 6560-14816 | 8-17 | 9-9 |  | 242 |
| nature:nature | 2 | Nature | concede | 17:21 | 18332-22809 | 22-15 | 9-12 | player_no_workers | 472 |
| nature:nature | 3 | Nature | concede | 16:12 | 17947-15262 | 14-13 | 11-9 |  | 326 |
| nature:nature | 4 | Nature | concede | 25:05 | 26214-21541 | 17-10 | 12-9 |  | 594 |
| nature:nature | 5 | Nature | concede | 13:40 | 16283-16157 | 15-15 | 9-9 |  | 328 |
| nature:nature | 6 | Nature | concede | 12:17 | 10949-13247 | 13-15 | 9-9 |  | 284 |
| nature:nature | 7 | Nature | concede | 15:34 | 15536-17784 | 10-14 | 12-9 |  | 350 |
| nature:nature | 8 | Nature | concede | 13:52 | 12555-17933 | 10-18 | 11-9 |  | 339 |
| nature:nature | 9 | Nature | concede | 23:30 | 25872-24713 | 21-19 | 9-9 | player_no_workers | 556 |
| nature:nature | 10 | Nature | time-score | 30:00 | 33920-28830 | 18-12 | 9-12 |  | 552 |
| shadow:shadow | 1 | Shadow | concede | 12:24 | 10282-14732 | 10-17 | 9-9 | player_no_workers | 248 |
| shadow:shadow | 2 | Shadow | concede | 10:54 | 12733-10408 | 11-12 | 9-9 | enemy_no_workers | 252 |
| shadow:shadow | 3 | Shadow | concede | 26:49 | 24672-33444 | 11-12 | 9-9 |  | 527 |
| shadow:shadow | 4 | Shadow | concede | 20:01 | 22735-20682 | 14-7 | 12-9 | enemy_no_workers | 425 |
| shadow:shadow | 5 | Shadow | concede | 10:40 | 10267-8700 | 6-11 | 9-9 |  | 192 |
| shadow:shadow | 6 | Shadow | concede | 10:56 | 8163-11078 | 7-18 | 9-9 |  | 212 |
| shadow:shadow | 6 | Shadow | concede | 14:53 | 15301-19207 | 10-12 | 9-12 |  | 305 |
| shadow:shadow | 7 | Shadow | concede | 11:50 | 12420-7828 | 9-9 | 12-10 |  | 221 |
| shadow:shadow | 8 | Shadow | early-score | 11:01 | 12943-7523 | 16-7 | 9-7 |  | 199 |
| shadow:shadow | 9 | Shadow | concede | 11:24 | 11128-12308 | 9-15 | 9-9 |  | 230 |
| shadow:shadow | 10 | Shadow | concede | 16:41 | 17218-15980 | 18-11 | 9-9 |  | 344 |

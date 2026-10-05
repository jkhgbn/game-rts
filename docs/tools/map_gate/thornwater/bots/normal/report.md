# Map gate thornwater (normal)

40 matches (0 failed). Commit: main@393116f2d6, main@f36635d463. difficulty normal, style balanced, sim full, tick 60, limit 30:00, early on (40).
Targets (rush-balance.md 8): win 45-55 % [ok] (pass band [near]: pairs 33-67 %, kingdoms 43-57 %; else [OUT]), median length 15:00-20:00 [ok] (per pair 13:30-21:30 [near]), no winner at 24:00 <= 10 %, mirrors 40-60 % player side. Small N: read the counts.

## Win % matrix (row kingdom vs column kingdom, both side orders)
Cell: row win % (wins-games). Diagonal: mirror, player-side win %.

| | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| **Fire** | 10 % (1-10) [OUT] | - | - | - |
| **Shadow** | - | 50 % (5-10) [ok] | - | - |
| **Ice** | - | - | 50 % (5-10) [ok] | - |
| **Nature** | - | - | - | 40 % (4-10) [near] |

## Per kingdom (non-mirror games)
| Kingdom | Win % | W-G | Median length | Peak army pop | Peak workers | Crystals gathered | Attacks |
|---|---|---|---|---|---|---|---|
| Fire | - | 0-0 | - | - | - | - | - |
| Shadow | - | 0-0 | - | - | - | - | - |
| Ice | - | 0-0 | - | - | - | - | - |
| Nature | - | 0-0 | - | - | - | - | - |

## Match length
Overall: median **14:04** [OUT], p90 26:16, min 8:45, max 30:00 (n = 40).

| Pair (unordered) | Games | Median | p90 | Pair win % |
|---|---|---|---|---|
| Fire vs Fire | 10 | 13:01 [OUT] | 26:32 | player side 10 % |
| Shadow vs Shadow | 10 | 20:02 [near] | 28:39 | player side 50 % |
| Ice vs Ice | 10 | 12:39 [OUT] | 22:17 | player side 50 % |
| Nature vs Nature | 10 | 14:16 [near] | 20:19 | player side 40 % |

## How matches ended
| Reason | Matches | Share |
|---|---|---|
| concede | 35 | 88 % |
| early-score | 3 | 8 % |
| time-score | 2 | 5 % |

No real winner (kill / concede) by 24:00: **20 %** (8 of 40) [OUT]. Early-score and time-score ends count here.

## Stalls
| Flag | Matches |
|---|---|
| player_no_workers | 5 |
| enemy_no_workers | 2 |

## Speed
Median sim speed x3.0 (game seconds per real second, one process). Sum of match real time 236:06 for 662:06 of game time; average 354 s per match.
CPU time 202:16 in total: 367 CPU s per 20 game minutes (the cost on a free core).
Batch wall clock 37:03 with 4 in parallel: **65 matches per hour**.

## Start-up (medians, real s; same machine load as the batch)
Load 2.2 s, level build 0.0 s, first navmesh bake 5.0 s, whole start-up 7.2 s, whole match 302 s (n = 40).
Navmesh cache: the first bake is only 1.7 % of a match (5.0 s): not worth a main.gd hook.

## Next steps
Nothing flagged by this batch.

## Matches
| Pair | Seed | Winner | Reason | Time | Score (P-E) | Peak army (P-E) | Workers peak (P-E) | Stall flags | Real s |
|---|---|---|---|---|---|---|---|---|---|
| fire:fire | 1 | Fire | concede | 19:53 | 17729-17624 | 14-16 | 9-12 |  | 503 |
| fire:fire | 2 | Fire | concede | 14:59 | 10494-10065 | 11-11 | 9-9 |  | 348 |
| fire:fire | 3 | Fire | concede | 12:09 | 9372-9797 | 11-10 | 9-9 |  | 268 |
| fire:fire | 4 | Fire | concede | 10:38 | 5818-5862 | 11-10 | 8-9 |  | 221 |
| fire:fire | 5 | Fire | concede | 13:07 | 10257-10978 | 14-17 | 9-11 |  | 250 |
| fire:fire | 6 | Fire | concede | 26:08 | 18089-20927 | 10-10 | 9-10 |  | 519 |
| fire:fire | 7 | Fire | time-score | 30:00 | 24957-26655 | 14-15 | 9-12 | enemy_no_workers | 592 |
| fire:fire | 8 | Fire | concede | 10:42 | 8761-8621 | 14-14 | 7-9 |  | 196 |
| fire:fire | 9 | Fire | concede | 11:54 | 7575-9910 | 11-14 | 9-9 |  | 224 |
| fire:fire | 10 | Fire | concede | 12:53 | 8532-9312 | 11-11 | 9-9 |  | 228 |
| ice:ice | 1 | Ice | concede | 12:12 | 7276-10980 | 7-15 | 9-12 |  | 288 |
| ice:ice | 2 | Ice | concede | 12:31 | 9291-11479 | 14-8 | 9-9 |  | 298 |
| ice:ice | 3 | Ice | concede | 13:05 | 8997-14011 | 12-14 | 9-9 |  | 303 |
| ice:ice | 4 | Ice | concede | 10:12 | 6437-10903 | 12-14 | 9-9 |  | 218 |
| ice:ice | 5 | Ice | concede | 12:45 | 9662-9542 | 8-13 | 11-9 |  | 244 |
| ice:ice | 6 | Ice | concede | 23:06 | 20087-17785 | 13-13 | 9-9 |  | 466 |
| ice:ice | 7 | Ice | concede | 22:10 | 20445-21380 | 11-16 | 9-9 |  | 459 |
| ice:ice | 8 | Ice | concede | 12:19 | 7495-12450 | 9-16 | 9-9 |  | 234 |
| ice:ice | 9 | Ice | early-score | 12:22 | 7560-13755 | 13-20 | 9-9 |  | 245 |
| ice:ice | 10 | Ice | concede | 17:12 | 15553-14703 | 13-16 | 9-9 |  | 344 |
| nature:nature | 1 | Nature | concede | 20:58 | 21655-20069 | 18-17 | 9-12 | player_no_workers | 634 |
| nature:nature | 2 | Nature | concede | 19:13 | 14271-18809 | 12-19 | 9-9 |  | 490 |
| nature:nature | 3 | Nature | early-score | 16:09 | 11021-18700 | 14-20 | 9-9 |  | 401 |
| nature:nature | 4 | Nature | concede | 17:36 | 17753-15664 | 16-18 | 11-9 |  | 373 |
| nature:nature | 5 | Nature | concede | 11:11 | 7640-12608 | 16-16 | 9-9 |  | 237 |
| nature:nature | 6 | Nature | concede | 12:21 | 13157-12125 | 15-18 | 11-9 |  | 286 |
| nature:nature | 7 | Nature | concede | 11:58 | 9863-11887 | 16-14 | 9-10 | player_no_workers | 273 |
| nature:nature | 8 | Nature | concede | 20:14 | 18649-17398 | 15-13 | 12-12 |  | 476 |
| nature:nature | 9 | Nature | concede | 8:44 | 12026-6202 | 22-15 | 9-9 |  | 202 |
| nature:nature | 10 | Nature | concede | 10:26 | 6134-13670 | 14-20 | 9-9 | player_no_workers | 211 |
| shadow:shadow | 1 | Shadow | concede | 19:04 | 16796-15210 | 14-17 | 9-9 |  | 450 |
| shadow:shadow | 2 | Shadow | early-score | 11:07 | 5888-14608 | 8-15 | 9-9 | player_no_workers | 253 |
| shadow:shadow | 3 | Shadow | concede | 12:54 | 11764-13641 | 13-13 | 9-9 |  | 307 |
| shadow:shadow | 4 | Shadow | concede | 27:17 | 24409-17250 | 11-15 | 9-9 | enemy_no_workers | 505 |
| shadow:shadow | 5 | Shadow | concede | 15:01 | 15111-13147 | 17-19 | 9-9 |  | 302 |
| shadow:shadow | 6 | Shadow | concede | 22:05 | 17239-18966 | 16-17 | 9-9 |  | 437 |
| shadow:shadow | 7 | Shadow | concede | 15:29 | 9122-15302 | 8-15 | 9-9 |  | 291 |
| shadow:shadow | 8 | Shadow | concede | 20:58 | 19413-17796 | 15-13 | 12-9 |  | 429 |
| shadow:shadow | 9 | Shadow | concede | 28:29 | 22476-29672 | 13-17 | 9-12 |  | 598 |
| shadow:shadow | 10 | Shadow | time-score | 30:00 | 24153-26518 | 9-9 | 12-12 | player_no_workers | 565 |

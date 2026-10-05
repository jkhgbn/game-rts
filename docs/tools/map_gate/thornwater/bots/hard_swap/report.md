# Map gate thornwater (hard, seats swapped)

40 matches (0 failed). Commit: main@f36635d463. difficulty hard, style balanced, sim full, tick 60, limit 30:00, early on (40).
Targets (rush-balance.md 8): win 45-55 % [ok] (pass band [near]: pairs 33-67 %, kingdoms 43-57 %; else [OUT]), median length 15:00-20:00 [ok] (per pair 13:30-21:30 [near]), no winner at 24:00 <= 10 %, mirrors 40-60 % player side. Small N: read the counts.

## Win % matrix (row kingdom vs column kingdom, both side orders)
Cell: row win % (wins-games). Diagonal: mirror, player-side win %.

| | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| **Fire** | 50 % (5-10) [ok] | - | - | - |
| **Shadow** | - | 50 % (5-10) [ok] | - | - |
| **Ice** | - | - | 50 % (5-10) [ok] | - |
| **Nature** | - | - | - | 30 % (3-10) [OUT] |

## Per kingdom (non-mirror games)
| Kingdom | Win % | W-G | Median length | Peak army pop | Peak workers | Crystals gathered | Attacks |
|---|---|---|---|---|---|---|---|
| Fire | - | 0-0 | - | - | - | - | - |
| Shadow | - | 0-0 | - | - | - | - | - |
| Ice | - | 0-0 | - | - | - | - | - |
| Nature | - | 0-0 | - | - | - | - | - |

## Match length
Overall: median **13:05** [OUT], p90 25:12, min 9:30, max 30:00 (n = 40).

| Pair (unordered) | Games | Median | p90 | Pair win % |
|---|---|---|---|---|
| Fire vs Fire | 10 | 12:26 [OUT] | 26:46 | player side 50 % |
| Shadow vs Shadow | 10 | 11:58 [OUT] | 17:58 | player side 50 % |
| Ice vs Ice | 10 | 13:52 [near] | 25:29 | player side 50 % |
| Nature vs Nature | 10 | 14:50 [near] | 22:27 | player side 30 % |

## How matches ended
| Reason | Matches | Share |
|---|---|---|
| concede | 35 | 88 % |
| early-score | 4 | 10 % |
| time-score | 1 | 3 % |

No real winner (kill / concede) by 24:00: **23 %** (9 of 40) [OUT]. Early-score and time-score ends count here.

## Stalls
| Flag | Matches |
|---|---|
| player_no_workers | 6 |
| enemy_no_workers | 2 |

## Speed
Median sim speed x3.2 (game seconds per real second, one process). Sum of match real time 208:16 for 629:37 of game time; average 312 s per match.
CPU time 169:18 in total: 323 CPU s per 20 game minutes (the cost on a free core).
Batch wall clock 27:42 with 4 in parallel: **87 matches per hour**.

## Start-up (medians, real s; same machine load as the batch)
Load 2.2 s, level build 0.0 s, first navmesh bake 5.1 s, whole start-up 7.4 s, whole match 249 s (n = 40).
Navmesh cache: the first bake is only 2.1 % of a match (5.1 s): not worth a main.gd hook.

## Next steps
Nothing flagged by this batch.

## Matches
| Pair | Seed | Winner | Reason | Time | Score (P-E) | Peak army (P-E) | Workers peak (P-E) | Stall flags | Real s |
|---|---|---|---|---|---|---|---|---|---|
| fire:fire | 1 | Fire | concede | 21:26 | 20548-23469 | 11-15 | 9-12 |  | 456 |
| fire:fire | 2 | Fire | concede | 10:15 | 7500-7256 | 13-11 | 8-7 |  | 177 |
| fire:fire | 3 | Fire | concede | 12:58 | 9555-9581 | 11-10 | 9-9 | player_no_workers | 228 |
| fire:fire | 4 | Fire | concede | 9:29 | 7335-7215 | 9-11 | 9-8 |  | 164 |
| fire:fire | 5 | Fire | concede | 28:57 | 34175-30476 | 13-9 | 12-9 |  | 526 |
| fire:fire | 6 | Fire | concede | 11:07 | 7272-9433 | 9-9 | 9-8 |  | 139 |
| fire:fire | 7 | Fire | early-score | 15:26 | 9501-16873 | 7-12 | 8-12 |  | 310 |
| fire:fire | 8 | Fire | concede | 26:30 | 35740-30574 | 18-12 | 12-12 |  | 585 |
| fire:fire | 9 | Fire | early-score | 11:54 | 11239-6899 | 10-7 | 12-9 |  | 232 |
| fire:fire | 10 | Fire | concede | 10:43 | 7902-6673 | 8-9 | 9-9 |  | 191 |
| ice:ice | 1 | Ice | concede | 18:34 | 18194-16358 | 14-9 | 9-12 |  | 386 |
| ice:ice | 2 | Ice | concede | 21:14 | 18278-22735 | 11-12 | 11-9 |  | 434 |
| ice:ice | 3 | Ice | concede | 11:53 | 9154-8142 | 11-6 | 9-9 | enemy_no_workers, player_no_workers | 218 |
| ice:ice | 4 | Ice | concede | 25:02 | 28047-21524 | 14-13 | 9-9 |  | 542 |
| ice:ice | 5 | Ice | concede | 11:36 | 11569-8011 | 17-8 | 9-9 |  | 174 |
| ice:ice | 6 | Ice | concede | 11:38 | 6959-9579 | 6-12 | 9-12 |  | 142 |
| ice:ice | 7 | Ice | early-score | 15:36 | 9110-18802 | 7-19 | 12-12 |  | 310 |
| ice:ice | 8 | Ice | concede | 29:18 | 26825-30458 | 8-18 | 12-12 |  | 644 |
| ice:ice | 9 | Ice | concede | 9:55 | 5719-7794 | 9-9 | 9-9 |  | 180 |
| ice:ice | 10 | Ice | concede | 12:08 | 8653-12855 | 8-13 | 9-10 |  | 231 |
| nature:nature | 1 | Nature | concede | 13:10 | 13460-13966 | 9-14 | 10-9 |  | 318 |
| nature:nature | 2 | Nature | concede | 16:54 | 16793-21037 | 16-11 | 9-11 | player_no_workers | 395 |
| nature:nature | 3 | Nature | concede | 21:36 | 24023-29208 | 14-15 | 12-12 | enemy_no_workers | 554 |
| nature:nature | 4 | Nature | concede | 15:48 | 20009-15102 | 15-15 | 9-9 |  | 366 |
| nature:nature | 5 | Nature | concede | 13:50 | 14858-15057 | 8-12 | 9-12 |  | 212 |
| nature:nature | 6 | Nature | concede | 11:57 | 16305-9464 | 15-9 | 9-9 |  | 173 |
| nature:nature | 7 | Nature | concede | 10:16 | 6706-15592 | 7-17 | 9-10 |  | 245 |
| nature:nature | 8 | Nature | concede | 19:06 | 23126-24109 | 9-20 | 12-9 |  | 468 |
| nature:nature | 9 | Nature | early-score | 11:01 | 9077-14210 | 8-18 | 9-9 |  | 252 |
| nature:nature | 10 | Nature | time-score | 30:00 | 31561-33031 | 9-10 | 12-12 | player_no_workers | 564 |
| shadow:shadow | 1 | Shadow | concede | 17:36 | 16719-20724 | 13-14 | 9-9 |  | 365 |
| shadow:shadow | 2 | Shadow | concede | 16:27 | 18529-19629 | 12-15 | 9-9 | player_no_workers | 339 |
| shadow:shadow | 3 | Shadow | concede | 21:14 | 26590-23493 | 10-10 | 12-9 |  | 422 |
| shadow:shadow | 4 | Shadow | concede | 11:33 | 7932-11883 | 11-7 | 9-8 |  | 212 |
| shadow:shadow | 5 | Shadow | concede | 10:00 | 9574-8656 | 11-5 | 9-8 |  | 188 |
| shadow:shadow | 6 | Shadow | concede | 11:53 | 7477-8283 | 7-6 | 9-9 |  | 138 |
| shadow:shadow | 7 | Shadow | concede | 17:04 | 22427-18174 | 14-15 | 12-9 |  | 372 |
| shadow:shadow | 8 | Shadow | concede | 11:03 | 8514-10184 | 6-8 | 8-12 | player_no_workers | 203 |
| shadow:shadow | 9 | Shadow | concede | 11:03 | 9234-9052 | 10-7 | 10-8 |  | 206 |
| shadow:shadow | 10 | Shadow | concede | 12:01 | 11908-9381 | 14-6 | 9-9 |  | 232 |

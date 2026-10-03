# Map gate thornwater (easy)

12 matches (0 failed). Commit: main@2d77698292. difficulty easy, style balanced, sim full, tick 60, limit 30:00, early on (12).
Targets (rush-balance.md 8): win 45-55 % [ok] (pass band [near]: pairs 33-67 %, kingdoms 43-57 %; else [OUT]), median length 15:00-20:00 [ok] (per pair 13:30-21:30 [near]), no winner at 24:00 <= 10 %, mirrors 40-60 % player side. Small N: read the counts.

## Win % matrix (row kingdom vs column kingdom, both side orders)
Cell: row win % (wins-games). Diagonal: mirror, player-side win %.

| | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| **Fire** | 100 % (3-3) [OUT] | - | - | - |
| **Shadow** | - | 67 % (2-3) [OUT] | - | - |
| **Ice** | - | - | 100 % (3-3) [OUT] | - |
| **Nature** | - | - | - | 0 % (0-3) [OUT] |

## Per kingdom (non-mirror games)
| Kingdom | Win % | W-G | Median length | Peak army pop | Peak workers | Crystals gathered | Attacks |
|---|---|---|---|---|---|---|---|
| Fire | - | 0-0 | - | - | - | - | - |
| Shadow | - | 0-0 | - | - | - | - | - |
| Ice | - | 0-0 | - | - | - | - | - |
| Nature | - | 0-0 | - | - | - | - | - |

## Match length
Overall: median **30:00** [OUT], p90 30:00, min 20:39, max 30:00 (n = 12).

| Pair (unordered) | Games | Median | p90 | Pair win % |
|---|---|---|---|---|
| Fire vs Fire | 3 | 30:00 [OUT] | 30:00 | player side 100 % |
| Shadow vs Shadow | 3 | 30:00 [OUT] | 30:00 | player side 67 % |
| Ice vs Ice | 3 | 30:00 [OUT] | 30:00 | player side 100 % |
| Nature vs Nature | 3 | 30:00 [OUT] | 30:00 | player side 0 % |

## How matches ended
| Reason | Matches | Share |
|---|---|---|
| concede | 2 | 17 % |
| time-score | 10 | 83 % |

No real winner (kill / concede) by 24:00: **92 %** (11 of 12) [OUT]. Early-score and time-score ends count here.

## Stalls
No stall flag raised.

## Speed
Median sim speed x1.6 (game seconds per real second, one process). Sum of match real time 187:13 for 347:41 of game time; average 936 s per match.
CPU time 106:42 in total: 368 CPU s per 20 game minutes (the cost on a free core).
Batch wall clock 83:33 with 4 in parallel: **9 matches per hour**.

## Start-up (medians, real s; same machine load as the batch)
Load 10.6 s, level build 0.0 s, first navmesh bake 19.9 s, whole start-up 31.6 s, whole match 1089 s (n = 12).
Navmesh cache: the first bake is only 1.8 % of a match (19.9 s): not worth a main.gd hook.

## Next steps
Nothing flagged by this batch.

## Matches
| Pair | Seed | Winner | Reason | Time | Score (P-E) | Peak army (P-E) | Workers peak (P-E) | Stall flags | Real s |
|---|---|---|---|---|---|---|---|---|---|
| fire:fire | 1 | Fire | time-score | 30:00 | 14569-14403 | 14-16 | 6-6 |  | 439 |
| fire:fire | 2 | Fire | time-score | 30:00 | 14799-13454 | 14-14 | 6-6 |  | 1293 |
| fire:fire | 3 | Fire | concede | 27:01 | 14434-12722 | 16-18 | 6-6 |  | 1013 |
| ice:ice | 1 | Ice | time-score | 30:00 | 13959-13547 | 15-15 | 6-6 |  | 462 |
| ice:ice | 2 | Ice | time-score | 30:00 | 15375-13213 | 17-14 | 6-6 |  | 1251 |
| ice:ice | 3 | Ice | time-score | 30:00 | 14489-13870 | 15-17 | 6-6 |  | 1131 |
| nature:nature | 1 | Nature | time-score | 30:00 | 13976-14802 | 17-24 | 6-6 |  | 495 |
| nature:nature | 2 | Nature | concede | 20:38 | 13250-13841 | 19-21 | 6-6 |  | 1046 |
| nature:nature | 3 | Nature | time-score | 30:00 | 13466-14722 | 13-17 | 6-6 |  | 1181 |
| shadow:shadow | 1 | Shadow | time-score | 30:00 | 14145-13845 | 15-14 | 6-6 |  | 459 |
| shadow:shadow | 2 | Shadow | time-score | 30:00 | 14070-13367 | 18-14 | 6-6 |  | 1280 |
| shadow:shadow | 3 | Shadow | time-score | 30:00 | 13198-13376 | 15-16 | 6-6 |  | 1182 |

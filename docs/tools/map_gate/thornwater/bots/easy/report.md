# Map gate thornwater (easy)

40 matches (0 failed). Commit: main@2d77698292, main@f36635d463. difficulty easy, style balanced, sim full, tick 60, limit 30:00, early on (40).
Targets (rush-balance.md 8): win 45-55 % [ok] (pass band [near]: pairs 33-67 %, kingdoms 43-57 %; else [OUT]), median length 15:00-20:00 [ok] (per pair 13:30-21:30 [near]), no winner at 24:00 <= 10 %, mirrors 40-60 % player side. Small N: read the counts.

## Win % matrix (row kingdom vs column kingdom, both side orders)
Cell: row win % (wins-games). Diagonal: mirror, player-side win %.

| | Fire | Shadow | Ice | Nature |
|---|---|---|---|---|
| **Fire** | 40 % (4-10) [near] | - | - | - |
| **Shadow** | - | 50 % (5-10) [ok] | - | - |
| **Ice** | - | - | 80 % (8-10) [OUT] | - |
| **Nature** | - | - | - | 30 % (3-10) [OUT] |

## Per kingdom (non-mirror games)
| Kingdom | Win % | W-G | Median length | Peak army pop | Peak workers | Crystals gathered | Attacks |
|---|---|---|---|---|---|---|---|
| Fire | - | 0-0 | - | - | - | - | - |
| Shadow | - | 0-0 | - | - | - | - | - |
| Ice | - | 0-0 | - | - | - | - | - |
| Nature | - | 0-0 | - | - | - | - | - |

## Match length
Overall: median **30:00** [OUT], p90 30:00, min 18:32, max 30:00 (n = 40).

| Pair (unordered) | Games | Median | p90 | Pair win % |
|---|---|---|---|---|
| Fire vs Fire | 10 | 30:00 [OUT] | 30:00 | player side 40 % |
| Shadow vs Shadow | 10 | 30:00 [OUT] | 30:00 | player side 50 % |
| Ice vs Ice | 10 | 30:00 [OUT] | 30:00 | player side 80 % |
| Nature vs Nature | 10 | 30:00 [OUT] | 30:00 | player side 30 % |

## How matches ended
| Reason | Matches | Share |
|---|---|---|
| concede | 6 | 15 % |
| time-score | 34 | 85 % |

No real winner (kill / concede) by 24:00: **90 %** (36 of 40) [OUT]. Early-score and time-score ends count here.

## Stalls
No stall flag raised.

## Speed
Median sim speed x3.3 (game seconds per real second, one process). Sum of match real time 427:48 for 1152:17 of game time; average 642 s per match.
CPU time 313:12 in total: 326 CPU s per 20 game minutes (the cost on a free core).
Batch wall clock 64:14 with 4 in parallel: **37 matches per hour**.

## Start-up (medians, real s; same machine load as the batch)
Load 2.2 s, level build 0.0 s, first navmesh bake 5.7 s, whole start-up 7.9 s, whole match 544 s (n = 40).
Navmesh cache: the first bake is only 1.0 % of a match (5.7 s): not worth a main.gd hook.

## Next steps
Nothing flagged by this batch.

## Matches
| Pair | Seed | Winner | Reason | Time | Score (P-E) | Peak army (P-E) | Workers peak (P-E) | Stall flags | Real s |
|---|---|---|---|---|---|---|---|---|---|
| fire:fire | 1 | Fire | time-score | 30:00 | 14569-14403 | 14-16 | 6-6 |  | 439 |
| fire:fire | 2 | Fire | time-score | 30:00 | 14799-13454 | 14-14 | 6-6 |  | 1293 |
| fire:fire | 3 | Fire | concede | 27:01 | 14434-12722 | 16-18 | 6-6 |  | 1013 |
| fire:fire | 4 | Fire | time-score | 30:00 | 12587-13665 | 14-14 | 6-6 |  | 435 |
| fire:fire | 5 | Fire | time-score | 30:00 | 14420-14263 | 15-14 | 6-6 |  | 529 |
| fire:fire | 6 | Fire | concede | 27:21 | 13348-12865 | 15-15 | 6-6 |  | 471 |
| fire:fire | 7 | Fire | time-score | 30:00 | 13097-13206 | 13-16 | 6-6 |  | 568 |
| fire:fire | 8 | Fire | time-score | 30:00 | 13395-13874 | 14-14 | 6-6 |  | 549 |
| fire:fire | 9 | Fire | time-score | 30:00 | 13542-14110 | 14-14 | 6-6 |  | 551 |
| fire:fire | 10 | Fire | time-score | 30:00 | 13194-13832 | 13-14 | 6-6 |  | 528 |
| ice:ice | 1 | Ice | time-score | 30:00 | 13959-13547 | 15-15 | 6-6 |  | 462 |
| ice:ice | 2 | Ice | time-score | 30:00 | 15375-13213 | 17-14 | 6-6 |  | 1251 |
| ice:ice | 3 | Ice | time-score | 30:00 | 14489-13870 | 15-17 | 6-6 |  | 1131 |
| ice:ice | 4 | Ice | time-score | 30:00 | 16064-13618 | 17-15 | 6-6 |  | 468 |
| ice:ice | 5 | Ice | time-score | 30:00 | 13671-14453 | 15-18 | 6-6 |  | 545 |
| ice:ice | 6 | Ice | concede | 18:31 | 13315-12386 | 15-17 | 6-6 |  | 337 |
| ice:ice | 7 | Ice | time-score | 30:00 | 14985-12184 | 15-19 | 6-6 |  | 527 |
| ice:ice | 8 | Ice | concede | 19:21 | 13476-11702 | 15-18 | 6-6 |  | 356 |
| ice:ice | 9 | Ice | time-score | 30:00 | 13985-13830 | 15-15 | 6-6 |  | 564 |
| ice:ice | 10 | Ice | time-score | 30:00 | 14069-13373 | 15-16 | 6-6 |  | 519 |
| nature:nature | 1 | Nature | time-score | 30:00 | 13976-14802 | 17-24 | 6-6 |  | 495 |
| nature:nature | 2 | Nature | concede | 20:38 | 13250-13841 | 19-21 | 6-6 |  | 1046 |
| nature:nature | 3 | Nature | time-score | 30:00 | 13466-14722 | 13-17 | 6-6 |  | 1181 |
| nature:nature | 4 | Nature | time-score | 30:00 | 14194-13295 | 27-24 | 6-6 |  | 540 |
| nature:nature | 5 | Nature | time-score | 30:00 | 15136-14016 | 17-19 | 6-6 |  | 622 |
| nature:nature | 6 | Nature | time-score | 30:00 | 12514-15205 | 23-20 | 6-6 |  | 567 |
| nature:nature | 7 | Nature | time-score | 30:00 | 13610-15749 | 14-21 | 6-6 |  | 603 |
| nature:nature | 8 | Nature | time-score | 30:00 | 13348-13959 | 17-16 | 6-6 |  | 578 |
| nature:nature | 9 | Nature | time-score | 30:00 | 14952-14479 | 13-18 | 6-6 |  | 595 |
| nature:nature | 10 | Nature | time-score | 30:00 | 13364-14831 | 17-19 | 6-6 |  | 513 |
| shadow:shadow | 1 | Shadow | time-score | 30:00 | 14145-13845 | 15-14 | 6-6 |  | 459 |
| shadow:shadow | 2 | Shadow | time-score | 30:00 | 14070-13367 | 18-14 | 6-6 |  | 1280 |
| shadow:shadow | 3 | Shadow | time-score | 30:00 | 13198-13376 | 15-16 | 6-6 |  | 1182 |
| shadow:shadow | 4 | Shadow | time-score | 30:00 | 14037-13140 | 16-18 | 6-6 |  | 454 |
| shadow:shadow | 5 | Shadow | time-score | 30:00 | 12621-14278 | 17-12 | 6-6 |  | 552 |
| shadow:shadow | 6 | Shadow | time-score | 30:00 | 12815-13484 | 13-21 | 6-6 |  | 546 |
| shadow:shadow | 7 | Shadow | time-score | 30:00 | 12527-12650 | 14-15 | 6-6 |  | 513 |
| shadow:shadow | 8 | Shadow | time-score | 30:00 | 12113-13418 | 14-17 | 6-6 |  | 543 |
| shadow:shadow | 9 | Shadow | time-score | 30:00 | 13501-10355 | 18-13 | 6-6 |  | 525 |
| shadow:shadow | 10 | Shadow | concede | 19:19 | 11402-11380 | 14-15 | 6-6 |  | 337 |

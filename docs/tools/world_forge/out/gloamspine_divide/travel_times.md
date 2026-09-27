# Travel times: Gloamspine Divide (2v2)

16-neighbour Dijkstra on the preview navmesh (0.5 m grid, ford cells x1.54), from each keep's navmesh point. Soldier 5.0 m/s, worker 4.6 m/s. `nav` = NavigationServer path (engine, not mirrored).

| Target (A1 view) | Kind | Where | a1 m | a2 m | b1 m | b2 m | spread | soldier s | worker s | nav min-max m |
|---|---|---|---|---|---|---|---|---|---|---|
| keep_a1 | keep | own | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 % | 0.0 | 0.0 | 0.0-0.0 |
| node_a_a1 | node | own | 4.0 | 4.0 | 4.0 | 4.0 | 0.0 % | 0.8 | 0.9 | 6.7-16.8 |
| node_b_a1 | node | own | 4.0 | 4.0 | 4.0 | 4.0 | 0.0 % | 0.8 | 0.9 | 6.7-11.1 |
| wallow_a1 | camp 1.0 | own | 16.0 | 16.0 | 16.0 | 16.0 | 0.0 % | 3.2 | 3.5 | 19.5-26.5 |
| fen_post_a1 | post | own | 16.0 | 16.0 | 16.0 | 16.0 | 0.0 % | 3.2 | 3.5 | 20.7-28.3 |
| natural_a1 | node | own | 22.0 | 22.0 | 22.0 | 22.0 | 0.0 % | 4.4 | 4.8 | 23.6-27.2 |
| lodge_a1 | guild | team midline | 23.0 | 23.0 | 23.0 | 23.0 | 0.0 % | 4.6 | 5.0 | 24.4-35.9 |
| shrine_a1 | point shrine | team midline | 23.7 | 23.7 | 23.7 | 23.7 | 0.0 % | 4.7 | 5.2 | 25.8-36.1 |
| den_a1 | guild | team midline | 25.1 | 25.1 | 25.1 | 25.1 | 0.0 % | 5.0 | 5.5 | 28.4-37.5 |
| glade_vein_a1 | node | own | 27.0 | 27.0 | 27.0 | 27.0 | 0.0 % | 5.4 | 5.9 | 28.4-38.1 |
| hollow_a1 | camp 2.0 | team midline | 29.0 | 29.0 | 29.0 | 29.0 | 0.0 % | 5.8 | 6.3 | 32.2-39.3 |
| peddler_a1 | peddler | own | 29.6 | 29.6 | 29.6 | 29.6 | 0.0 % | 5.9 | 6.4 | 33.1-37.1 |
| cache_a1 | cache | own | 30.6 | 30.6 | 30.6 | 30.6 | 0.0 % | 6.1 | 6.7 | 33.8-40.8 |
| well_a1 | point well | own | 33.6 | 33.6 | 33.6 | 33.6 | 0.0 % | 6.7 | 7.3 | 35.9-40.7 |
| fen_post_a2 | post | ally's | 35.1 | 35.1 | 35.1 | 35.1 | 0.0 % | 7.0 | 7.6 | 37.3-46.9 |
| stag_a1 | camp 3.0 | own | 35.2 | 35.2 | 35.2 | 35.2 | 0.0 % | 7.0 | 7.7 | 36.6-46.1 |
| tavern_a1 | tavern | own | 39.2 | 39.2 | 39.2 | 39.2 | 0.0 % | 7.8 | 8.5 | 40.8-44.4 |
| node_a_a2 | node | ally's | 42.0 | 42.0 | 42.0 | 42.0 | 0.0 % | 8.4 | 9.1 | 43.4-54.6 |
| heath_lair_a1 | lair | own | 44.1 | 44.1 | 44.1 | 44.1 | 0.0 % | 8.8 | 9.6 | 45.6-54.1 |
| well_a2 | point well | ally's | 47.4 | 47.4 | 47.5 | 47.5 | 0.2 % | 9.5 | 10.3 | 50.6-57.3 |
| keep_a2 | keep | ally's | 47.5 | 47.5 | 47.5 | 47.5 | 0.0 % | 9.5 | 10.3 | 60.3-62.3 |
| spine_post_a1 | post | own | 49.7 | 49.7 | 49.7 | 49.7 | 0.0 % | 9.9 | 10.8 | 52.6-59.7 |
| rich_a1 | node | own | 50.1 | 50.1 | 50.1 | 50.1 | 0.0 % | 10.0 | 10.9 | 54.1-58.3 |
| fordwatch_a1 | point watchtower | own | 50.2 | 50.2 | 50.2 | 50.2 | 0.0 % | 10.0 | 10.9 | 51.9-55.1 |
| crown_sw | crossing bridge_lane | own | 51.3 | 51.3 | 51.3 | 51.3 | 0.0 % | 10.3 | 11.2 | 52.8-57.2 |
| fenwatch_a1 | point watchtower | own | 53.0 | 53.0 | 53.0 | 53.0 | 0.0 % | 10.6 | 11.5 | 55.4-59.2 |
| natural_a2 | node | ally's | 54.5 | 54.5 | 54.4 | 54.4 | 0.3 % | 10.9 | 11.8 | 56.8-64.0 |
| node_b_a2 | node | ally's | 55.7 | 55.7 | 55.7 | 55.7 | 0.0 % | 11.1 | 12.1 | 63.0-70.2 |
| bridge_nest_a1 | camp 2.0 | own | 57.9 | 57.9 | 57.9 | 57.9 | 0.0 % | 11.6 | 12.6 | 61.7-65.7 |
| ford_s | crossing ford | river (own side) | 58.9 | 58.9 | 58.9 | 58.9 | 0.0 % | 11.8 | 12.8 | 58.9-62.1 |
| ford_nest_a1 | camp 2.0 | river (own side) | 58.9 | 58.9 | 58.9 | 58.9 | 0.0 % | 11.8 | 12.8 | 58.9-62.1 |
| tavern_a2 | tavern | ally's | 60.1 | 60.1 | 60.1 | 60.1 | 0.0 % | 12.0 | 13.1 | 63.3-70.0 |
| crown_nw | crossing bridge_lane | ally's | 62.2 | 62.2 | 62.4 | 62.4 | 0.3 % | 12.5 | 13.5 | 68.0-72.6 |
| mouth_lair_a1 | lair | own | 62.5 | 62.5 | 62.5 | 62.5 | 0.0 % | 12.5 | 13.6 | 66.2-72.0 |
| crown_a1 | crown | centre | 62.7 | 62.7 | 62.7 | 62.7 | 0.0 % | 12.5 | 13.6 | 64.3-69.2 |
| fordwatch_b2 | point watchtower | facing enemy's | 66.0 | 65.9 | 65.9 | 66.3 | 0.6 % | 13.2 | 14.3 | 65.6-68.7 |
| bridge_road_s | crossing bridge_road | river (own side) | 67.6 | 67.6 | 67.6 | 67.6 | 0.0 % | 13.5 | 14.7 | 71.1-75.3 |
| crown_se | crossing bridge_lane | facing enemy's | 69.4 | 69.4 | 69.4 | 69.4 | 0.0 % | 13.9 | 15.1 | 70.2-74.5 |
| wallow_a2 | camp 1.0 | ally's | 71.8 | 71.8 | 71.8 | 71.8 | 0.0 % | 14.4 | 15.6 | 76.8-83.9 |
| peddler_a2 | peddler | ally's | 74.7 | 74.7 | 74.5 | 74.6 | 0.2 % | 14.9 | 16.2 | 76.5-83.6 |
| crown_ne | crossing bridge_lane | diagonal enemy's | 75.4 | 75.4 | 75.4 | 75.4 | 0.0 % | 15.1 | 16.4 | 76.8-81.4 |
| fordwatch_a2 | point watchtower | ally's | 76.5 | 76.5 | 76.5 | 76.5 | 0.0 % | 15.3 | 16.6 | 79.6-86.3 |
| fenwatch_b2 | point watchtower | facing enemy's | 77.1 | 77.1 | 77.1 | 77.1 | 0.0 % | 15.4 | 16.8 | 74.7-78.1 |
| bridge_nest_b2 | camp 2.0 | facing enemy's | 78.3 | 77.8 | 77.7 | 78.3 | 0.7 % | 15.6 | 17.0 | 81.0-85.6 |
| tavern_b2 | tavern | facing enemy's | 80.6 | 80.1 | 80.1 | 80.5 | 0.6 % | 16.1 | 17.5 | 80.0-86.4 |
| mouth_lair_b2 | lair | facing enemy's | 82.2 | 82.2 | 82.2 | 82.2 | 0.0 % | 16.4 | 17.9 | 85.4-89.7 |
| rich_b2 | node | facing enemy's | 83.3 | 83.1 | 83.1 | 83.3 | 0.3 % | 16.6 | 18.1 | 86.4-90.9 |
| glade_vein_a2 | node | ally's | 83.6 | 83.6 | 83.6 | 83.6 | 0.0 % | 16.7 | 18.2 | 85.4-96.5 |
| ford_n | crossing ford | river (ally side) | 84.0 | 84.0 | 84.1 | 84.1 | 0.1 % | 16.8 | 18.3 | 86.0-92.5 |
| ford_nest_a2 | camp 2.0 | river (ally side) | 84.0 | 84.0 | 84.1 | 84.1 | 0.1 % | 16.8 | 18.3 | 86.0-92.5 |
| cache_a2 | cache | ally's | 85.7 | 85.7 | 85.7 | 85.7 | 0.0 % | 17.1 | 18.6 | 88.6-95.8 |
| well_b2 | point well | facing enemy's | 86.9 | 86.9 | 86.9 | 86.9 | 0.0 % | 17.4 | 18.9 | 87.3-91.6 |
| fenwatch_a2 | point watchtower | ally's | 89.0 | 89.0 | 89.0 | 89.0 | 0.0 % | 17.8 | 19.4 | 91.4-98.5 |
| tavern_b1 | tavern | diagonal enemy's | 90.6 | 90.6 | 90.6 | 90.6 | 0.0 % | 18.1 | 19.7 | 92.2-96.8 |
| fordwatch_b1 | point watchtower | diagonal enemy's | 90.6 | 90.7 | 91.2 | 90.7 | 0.7 % | 18.2 | 19.7 | 91.4-104.1 |
| peddler_b2 | peddler | facing enemy's | 91.4 | 91.2 | 91.2 | 91.6 | 0.4 % | 18.3 | 19.9 | 89.8-93.1 |
| stag_a2 | camp 3.0 | ally's | 91.9 | 91.9 | 91.9 | 91.9 | 0.0 % | 18.4 | 20.0 | 93.6-106.9 |
| well_b1 | point well | diagonal enemy's | 92.1 | 92.1 | 92.1 | 92.1 | 0.0 % | 18.4 | 20.0 | 93.0-97.7 |
| rich_a2 | node | ally's | 92.5 | 92.5 | 92.3 | 92.4 | 0.2 % | 18.5 | 20.1 | 95.4-102.5 |
| natural_b2 | node | facing enemy's | 95.8 | 95.4 | 95.4 | 95.8 | 0.4 % | 19.1 | 20.8 | 94.4-97.6 |
| bridge_nest_a2 | camp 2.0 | ally's | 97.4 | 97.4 | 97.4 | 97.4 | 0.0 % | 19.5 | 21.2 | 99.8-106.9 |
| spine_post_b2 | post | facing enemy's | 98.8 | 98.7 | 98.6 | 98.8 | 0.2 % | 19.7 | 21.5 | 101.2-105.5 |
| heath_lair_a2 | lair | ally's | 100.8 | 100.8 | 100.8 | 100.8 | 0.0 % | 20.2 | 21.9 | 104.5-111.7 |
| hollow_b1 | camp 2.0 | enemy midline | 102.6 | 102.6 | 102.5 | 102.5 | 0.1 % | 20.5 | 22.3 | 102.6-106.8 |
| fenwatch_b1 | point watchtower | diagonal enemy's | 103.3 | 103.3 | 103.4 | 103.4 | 0.1 % | 20.7 | 22.5 | 102.3-120.1 |
| spine_post_a2 | post | ally's | 104.1 | 104.1 | 104.1 | 104.1 | 0.0 % | 20.8 | 22.6 | 105.7-112.9 |
| cache_b2 | cache | facing enemy's | 105.9 | 105.9 | 105.9 | 105.9 | 0.0 % | 21.2 | 23.0 | 110.8-115.2 |
| natural_b1 | node | diagonal enemy's | 106.3 | 106.3 | 106.3 | 106.3 | 0.0 % | 21.3 | 23.1 | 107.2-111.9 |
| bridge_road_n | crossing bridge_road | river (ally side) | 108.7 | 108.8 | 108.8 | 108.7 | 0.1 % | 21.7 | 23.6 | 111.1-118.1 |
| wallow_b2 | camp 1.0 | facing enemy's | 109.9 | 109.7 | 109.7 | 110.1 | 0.4 % | 22.0 | 23.9 | 122.1-126.6 |
| bridge_nest_b1 | camp 2.0 | diagonal enemy's | 110.6 | 110.6 | 110.7 | 110.7 | 0.1 % | 22.1 | 24.1 | 109.5-128.2 |
| mouth_lair_a2 | lair | ally's | 111.0 | 111.0 | 110.8 | 110.9 | 0.2 % | 22.2 | 24.1 | 112.6-119.8 |
| node_b_b2 | node | facing enemy's | 112.4 | 112.0 | 112.0 | 112.4 | 0.4 % | 22.4 | 24.4 | 111.6-114.7 |
| heath_lair_b2 | lair | facing enemy's | 112.8 | 112.7 | 112.6 | 112.8 | 0.2 % | 22.5 | 24.5 | 114.8-119.2 |
| rich_b1 | node | diagonal enemy's | 112.8 | 112.8 | 112.9 | 112.9 | 0.1 % | 22.6 | 24.5 | 112.1-128.6 |
| peddler_b1 | peddler | diagonal enemy's | 115.8 | 115.8 | 115.8 | 115.8 | 0.0 % | 23.2 | 25.2 | 116.8-121.5 |
| keep_b2 | keep | facing enemy's | 118.3 | 117.9 | 117.9 | 118.3 | 0.3 % | 23.6 | 25.7 | 124.5-140.5 |
| glade_vein_b2 | node | facing enemy's | 123.2 | 123.0 | 123.0 | 123.4 | 0.3 % | 24.6 | 26.8 | 128.3-132.7 |
| mouth_lair_b1 | lair | diagonal enemy's | 123.3 | 123.4 | 123.4 | 123.3 | 0.1 % | 24.7 | 26.8 | 125.3-132.5 |
| stag_b2 | camp 3.0 | facing enemy's | 123.4 | 123.3 | 123.2 | 123.4 | 0.1 % | 24.7 | 26.8 | 126.1-130.5 |
| node_b_b1 | node | diagonal enemy's | 124.6 | 124.6 | 124.6 | 124.6 | 0.0 % | 24.9 | 27.1 | 125.7-130.3 |
| lodge_b1 | guild | enemy midline | 126.6 | 126.6 | 126.6 | 126.6 | 0.0 % | 25.3 | 27.5 | 126.3-130.5 |
| node_a_b2 | node | facing enemy's | 127.2 | 126.8 | 126.8 | 127.2 | 0.3 % | 25.4 | 27.6 | 126.9-131.2 |
| keep_b1 | keep | diagonal enemy's | 128.1 | 128.1 | 128.1 | 128.1 | 0.0 % | 25.6 | 27.8 | 130.4-148.9 |
| wallow_b1 | camp 1.0 | diagonal enemy's | 129.4 | 129.4 | 129.4 | 129.4 | 0.0 % | 25.9 | 28.1 | 130.5-135.1 |
| cache_b1 | cache | diagonal enemy's | 131.3 | 131.3 | 131.9 | 131.4 | 0.5 % | 26.3 | 28.6 | 134.1-138.7 |
| shrine_b1 | point shrine | enemy midline | 132.4 | 132.4 | 132.4 | 132.4 | 0.0 % | 26.5 | 28.8 | 131.8-136.1 |
| node_a_b1 | node | diagonal enemy's | 132.7 | 132.7 | 132.7 | 132.7 | 0.0 % | 26.5 | 28.9 | 132.5-146.0 |
| spine_post_b1 | post | diagonal enemy's | 135.4 | 135.4 | 135.6 | 135.6 | 0.1 % | 27.1 | 29.5 | 143.6-148.2 |
| fen_post_b2 | post | facing enemy's | 136.4 | 136.4 | 136.4 | 136.4 | 0.0 % | 27.3 | 29.7 | 137.2-141.5 |
| den_b1 | guild | enemy midline | 138.4 | 138.4 | 138.4 | 138.4 | 0.0 % | 27.7 | 30.1 | 137.7-142.0 |
| fen_post_b1 | post | diagonal enemy's | 141.3 | 141.3 | 141.3 | 141.3 | 0.0 % | 28.3 | 30.7 | 140.2-146.8 |
| heath_lair_b1 | lair | diagonal enemy's | 144.0 | 144.1 | 144.6 | 144.1 | 0.4 % | 28.8 | 31.4 | 149.7-154.3 |
| glade_vein_b1 | node | diagonal enemy's | 145.9 | 145.9 | 145.9 | 145.9 | 0.0 % | 29.2 | 31.7 | 147.3-152.0 |
| stag_b1 | camp 3.0 | diagonal enemy's | 150.3 | 150.4 | 150.9 | 150.5 | 0.4 % | 30.1 | 32.7 | 151.8-156.4 |

## Contest per spot (nearest seat of each side, m; contested = sides within 15 %)

| Spot | Kind | nearest side 0 | m | nearest side 1 | m | ratio 0/1 | |
|---|---|---|---|---|---|---|---|
| bridge_nest_a1 | camp | a1 | 57.9 | b2 | 78.3 | 0.74 |  |
| bridge_nest_a2 | camp | a2 | 57.9 | b1 | 77.7 | 0.74 |  |
| bridge_nest_b1 | camp | a2 | 77.8 | b1 | 57.9 | 1.34 |  |
| bridge_nest_b2 | camp | a1 | 78.3 | b2 | 57.9 | 1.35 |  |
| cache_a1 | cache | a1 | 30.6 | b2 | 105.9 | 0.29 |  |
| cache_a2 | cache | a2 | 30.6 | b1 | 105.9 | 0.29 |  |
| cache_b1 | cache | a2 | 105.9 | b1 | 30.6 | 3.46 |  |
| cache_b2 | cache | a1 | 105.9 | b2 | 30.6 | 3.46 |  |
| crown_a1 | crown | a1 | 62.7 | b1 | 62.7 | 1.00 | contested |
| den_a1 | guild | a1 | 25.1 | b1 | 138.4 | 0.18 |  |
| den_b1 | guild | a1 | 138.4 | b1 | 25.1 | 5.51 |  |
| fen_post_a1 | post | a1 | 16.0 | b2 | 136.4 | 0.12 |  |
| fen_post_a2 | post | a2 | 16.0 | b1 | 136.4 | 0.12 |  |
| fen_post_b1 | post | a2 | 136.4 | b1 | 16.0 | 8.52 |  |
| fen_post_b2 | post | a1 | 136.4 | b2 | 16.0 | 8.52 |  |
| fenwatch_a1 | point | a1 | 53.0 | b2 | 77.1 | 0.69 |  |
| fenwatch_a2 | point | a2 | 53.0 | b1 | 77.1 | 0.69 |  |
| fenwatch_b1 | point | a2 | 77.1 | b1 | 53.0 | 1.45 |  |
| fenwatch_b2 | point | a1 | 77.1 | b2 | 53.0 | 1.45 |  |
| ford_nest_a1 | camp | a1 | 58.9 | b2 | 58.9 | 1.00 | contested |
| ford_nest_a2 | camp | a2 | 58.9 | b1 | 58.9 | 1.00 | contested |
| fordwatch_a1 | point | a1 | 50.2 | b2 | 66.3 | 0.76 |  |
| fordwatch_a2 | point | a2 | 50.2 | b1 | 65.9 | 0.76 |  |
| fordwatch_b1 | point | a2 | 65.9 | b1 | 50.2 | 1.31 |  |
| fordwatch_b2 | point | a1 | 66.0 | b2 | 50.2 | 1.31 |  |
| glade_vein_a1 | node | a1 | 27.0 | b2 | 123.4 | 0.22 |  |
| glade_vein_a2 | node | a2 | 27.0 | b1 | 123.0 | 0.22 |  |
| glade_vein_b1 | node | a2 | 123.0 | b1 | 27.0 | 4.56 |  |
| glade_vein_b2 | node | a1 | 123.2 | b2 | 27.0 | 4.56 |  |
| heath_lair_a1 | lair | a1 | 44.1 | b2 | 112.8 | 0.39 |  |
| heath_lair_a2 | lair | a2 | 44.1 | b1 | 112.6 | 0.39 |  |
| heath_lair_b1 | lair | a2 | 112.7 | b1 | 44.1 | 2.56 |  |
| heath_lair_b2 | lair | a1 | 112.8 | b2 | 44.1 | 2.56 |  |
| hollow_a1 | camp | a1 | 29.0 | b1 | 102.5 | 0.28 |  |
| hollow_b1 | camp | a1 | 102.6 | b1 | 29.0 | 3.54 |  |
| lodge_a1 | guild | a1 | 23.0 | b1 | 126.6 | 0.18 |  |
| lodge_b1 | guild | a1 | 126.6 | b1 | 23.0 | 5.50 |  |
| mouth_lair_a1 | lair | a1 | 62.5 | b2 | 82.2 | 0.76 |  |
| mouth_lair_a2 | lair | a2 | 62.5 | b1 | 82.2 | 0.76 |  |
| mouth_lair_b1 | lair | a2 | 82.2 | b1 | 62.5 | 1.32 |  |
| mouth_lair_b2 | lair | a1 | 82.2 | b2 | 62.5 | 1.32 |  |
| natural_a1 | node | a1 | 22.0 | b2 | 95.8 | 0.23 |  |
| natural_a2 | node | a2 | 22.0 | b1 | 95.4 | 0.23 |  |
| natural_b1 | node | a2 | 95.4 | b1 | 22.0 | 4.34 |  |
| natural_b2 | node | a1 | 95.8 | b2 | 22.0 | 4.35 |  |
| node_a_a1 | node | a1 | 4.0 | b2 | 127.2 | 0.03 |  |
| node_a_a2 | node | a2 | 4.0 | b1 | 126.8 | 0.03 |  |
| node_a_b1 | node | a2 | 126.8 | b1 | 4.0 | 31.70 |  |
| node_a_b2 | node | a1 | 127.2 | b2 | 4.0 | 31.80 |  |
| node_b_a1 | node | a1 | 4.0 | b2 | 112.4 | 0.04 |  |
| node_b_a2 | node | a2 | 4.0 | b1 | 112.0 | 0.04 |  |
| node_b_b1 | node | a2 | 112.0 | b1 | 4.0 | 27.99 |  |
| node_b_b2 | node | a1 | 112.4 | b2 | 4.0 | 28.09 |  |
| peddler_a1 | peddler | a1 | 29.6 | b2 | 91.6 | 0.32 |  |
| peddler_a2 | peddler | a2 | 29.6 | b1 | 91.2 | 0.32 |  |
| peddler_b1 | peddler | a2 | 91.2 | b1 | 29.6 | 3.08 |  |
| peddler_b2 | peddler | a1 | 91.4 | b2 | 29.6 | 3.09 |  |
| rich_a1 | node | a1 | 50.1 | b2 | 83.3 | 0.60 |  |
| rich_a2 | node | a2 | 50.1 | b1 | 83.1 | 0.60 |  |
| rich_b1 | node | a2 | 83.1 | b1 | 50.1 | 1.66 |  |
| rich_b2 | node | a1 | 83.3 | b2 | 50.1 | 1.66 |  |
| shrine_a1 | point | a1 | 23.7 | b1 | 132.4 | 0.18 |  |
| shrine_b1 | point | a1 | 132.4 | b1 | 23.7 | 5.59 |  |
| spine_post_a1 | post | a1 | 49.7 | b2 | 98.8 | 0.50 |  |
| spine_post_a2 | post | a2 | 49.7 | b1 | 98.6 | 0.50 |  |
| spine_post_b1 | post | a2 | 98.7 | b1 | 49.7 | 1.99 |  |
| spine_post_b2 | post | a1 | 98.8 | b2 | 49.7 | 1.99 |  |
| stag_a1 | camp | a1 | 35.2 | b2 | 123.4 | 0.29 |  |
| stag_a2 | camp | a2 | 35.2 | b1 | 123.2 | 0.29 |  |
| stag_b1 | camp | a2 | 123.3 | b1 | 35.2 | 3.50 |  |
| stag_b2 | camp | a1 | 123.4 | b2 | 35.2 | 3.50 |  |
| tavern_a1 | tavern | a1 | 39.2 | b2 | 80.5 | 0.49 |  |
| tavern_a2 | tavern | a2 | 39.2 | b1 | 80.1 | 0.49 |  |
| tavern_b1 | tavern | a2 | 80.1 | b1 | 39.2 | 2.04 |  |
| tavern_b2 | tavern | a1 | 80.6 | b2 | 39.2 | 2.05 |  |
| wallow_a1 | camp | a1 | 16.0 | b2 | 110.1 | 0.15 |  |
| wallow_a2 | camp | a2 | 16.0 | b1 | 109.7 | 0.15 |  |
| wallow_b1 | camp | a2 | 109.7 | b1 | 16.0 | 6.85 |  |
| wallow_b2 | camp | a1 | 109.9 | b2 | 16.0 | 6.86 |  |
| well_a1 | point | a1 | 33.6 | b2 | 86.9 | 0.39 |  |
| well_a2 | point | a2 | 33.6 | b1 | 86.9 | 0.39 |  |
| well_b1 | point | a2 | 86.9 | b1 | 33.6 | 2.59 |  |
| well_b2 | point | a1 | 86.9 | b2 | 33.6 | 2.59 |  |

95 targets, 4 seats, 9.8 s.

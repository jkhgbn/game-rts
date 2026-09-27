# Travel times: Kinhearth Vale (2v2)

16-neighbour Dijkstra on the preview navmesh (0.5 m grid, ford cells x1.54), from each keep's navmesh point. Soldier 5.0 m/s, worker 4.6 m/s. `nav` = NavigationServer path (engine, not mirrored).

| Target (A1 view) | Kind | Where | a1 m | a2 m | b1 m | b2 m | spread | soldier s | worker s | nav min-max m |
|---|---|---|---|---|---|---|---|---|---|---|
| keep_a1 | keep | own | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 % | 0.0 | 0.0 | 0.0-0.0 |
| node_a_a1 | node | own | 4.0 | 4.0 | 4.0 | 4.0 | 0.0 % | 0.8 | 0.9 | 6.7-16.8 |
| node_b_a1 | node | own | 4.0 | 4.0 | 4.0 | 4.0 | 0.0 % | 0.8 | 0.9 | 6.7-11.1 |
| cache_a1 | cache | own | 14.8 | 14.8 | 14.8 | 14.8 | 0.0 % | 3.0 | 3.2 | 19.1-23.8 |
| corner_post_a1 | post | own | 25.1 | 25.1 | 25.1 | 25.1 | 0.0 % | 5.0 | 5.5 | 28.4-37.3 |
| lodge_a1 | guild | team midline | 26.2 | 26.2 | 26.2 | 26.2 | 0.0 % | 5.2 | 5.7 | 27.8-37.0 |
| natural_a1 | node | own | 26.6 | 26.6 | 26.6 | 26.6 | 0.0 % | 5.3 | 5.8 | 30.8-35.2 |
| den_a1 | guild | team midline | 27.1 | 27.1 | 27.1 | 27.1 | 0.0 % | 5.4 | 5.9 | 30.1-39.4 |
| well_a1 | point well | own | 29.0 | 29.0 | 29.0 | 29.0 | 0.0 % | 5.8 | 6.3 | 30.5-33.5 |
| green_cache_a1 | cache | team midline | 31.8 | 31.8 | 31.8 | 31.8 | 0.0 % | 6.4 | 6.9 | 35.1-42.1 |
| peddler_a1 | peddler | own | 32.1 | 32.1 | 32.1 | 32.1 | 0.0 % | 6.4 | 7.0 | 34.8-42.8 |
| wallow_a1 | camp 1.0 | own | 38.2 | 38.2 | 38.2 | 38.2 | 0.0 % | 7.6 | 8.3 | 39.4-48.6 |
| tavern_a1 | tavern | own | 39.6 | 39.6 | 39.6 | 39.6 | 0.0 % | 7.9 | 8.6 | 41.4-45.9 |
| shrine_a1 | point shrine | team midline | 40.3 | 40.3 | 40.3 | 40.3 | 0.0 % | 8.1 | 8.8 | 43.6-49.5 |
| vale_lair_a1 | lair | own | 43.2 | 43.2 | 43.2 | 43.2 | 0.0 % | 8.6 | 9.4 | 44.8-55.1 |
| node_a_a2 | node | ally's | 46.0 | 46.0 | 46.0 | 46.0 | 0.0 % | 9.2 | 10.0 | 47.4-58.6 |
| stag_a1 | camp 3.0 | own | 46.2 | 46.2 | 46.2 | 46.2 | 0.0 % | 9.2 | 10.0 | 47.7-51.1 |
| vale_post_a1 | post | own | 51.0 | 51.0 | 51.0 | 51.0 | 0.0 % | 10.2 | 11.1 | 52.7-61.1 |
| keep_a2 | keep | ally's | 51.5 | 51.5 | 51.5 | 51.5 | 0.0 % | 10.3 | 11.2 | 58.2-64.2 |
| tavern_a2 | tavern | ally's | 54.0 | 54.0 | 54.0 | 54.0 | 0.0 % | 10.8 | 11.7 | 57.6-63.7 |
| rich_a1 | node | own | 54.0 | 54.0 | 54.0 | 54.0 | 0.0 % | 10.8 | 11.7 | 57.7-63.5 |
| fordwatch_a1 | point watchtower | own | 54.0 | 54.0 | 54.0 | 54.0 | 0.0 % | 10.8 | 11.7 | 55.6-58.6 |
| causeway_w | crossing bridge_lane | team midline | 56.2 | 56.2 | 56.2 | 56.2 | 0.0 % | 11.2 | 12.2 | 59.3-64.4 |
| vale_watch_a1 | point watchtower | own | 56.4 | 56.4 | 56.4 | 56.4 | 0.0 % | 11.3 | 12.3 | 59.9-63.9 |
| node_b_a2 | node | ally's | 58.9 | 58.9 | 58.9 | 58.9 | 0.0 % | 11.8 | 12.8 | 62.2-75.8 |
| well_a2 | point well | ally's | 62.4 | 62.4 | 62.4 | 62.4 | 0.0 % | 12.5 | 13.6 | 65.3-73.0 |
| bridge_nest_a1 | camp 2.0 | own | 64.0 | 64.0 | 64.0 | 64.0 | 0.0 % | 12.8 | 13.9 | 68.0-72.1 |
| ford_s | crossing ford | river (own side) | 65.4 | 65.4 | 65.4 | 65.4 | 0.0 % | 13.1 | 14.2 | 65.1-68.4 |
| ford_nest_a1 | camp 2.0 | river (own side) | 65.4 | 65.4 | 65.4 | 65.4 | 0.0 % | 13.1 | 14.2 | 65.1-68.4 |
| crown_a1 | crown | centre | 68.9 | 68.9 | 68.9 | 68.9 | 0.0 % | 13.8 | 15.0 | 70.6-75.6 |
| cache_a2 | cache | ally's | 70.1 | 70.1 | 70.1 | 70.1 | 0.0 % | 14.0 | 15.2 | 70.4-79.5 |
| mouth_lair_a1 | lair | own | 71.4 | 71.4 | 71.4 | 71.4 | 0.0 % | 14.3 | 15.5 | 74.9-80.4 |
| bridge_road_s | crossing bridge_road | river (own side) | 74.9 | 74.9 | 74.9 | 74.9 | 0.0 % | 15.0 | 16.3 | 78.3-82.5 |
| fordwatch_b2 | point watchtower | facing enemy's | 77.0 | 76.9 | 76.7 | 77.0 | 0.4 % | 15.4 | 16.7 | 75.4-78.7 |
| natural_a2 | node | ally's | 78.4 | 78.4 | 78.4 | 78.4 | 0.0 % | 15.7 | 17.0 | 79.1-87.7 |
| fordwatch_a2 | point watchtower | ally's | 79.7 | 79.7 | 79.7 | 79.7 | 0.0 % | 15.9 | 17.3 | 83.1-89.2 |
| stag_a2 | camp 3.0 | ally's | 80.1 | 80.1 | 80.1 | 80.1 | 0.0 % | 16.0 | 17.4 | 82.6-89.6 |
| causeway_e | crossing bridge_lane | enemy midline | 81.5 | 81.5 | 81.5 | 81.5 | 0.0 % | 16.3 | 17.7 | 83.0-87.8 |
| stag_b2 | camp 3.0 | facing enemy's | 84.9 | 84.8 | 84.9 | 84.9 | 0.1 % | 17.0 | 18.4 | 83.0-86.1 |
| corner_post_a2 | post | ally's | 85.1 | 85.1 | 85.1 | 85.1 | 0.0 % | 17.0 | 18.5 | 85.5-96.2 |
| bridge_nest_b2 | camp 2.0 | facing enemy's | 86.3 | 85.8 | 85.7 | 86.3 | 0.7 % | 17.2 | 18.7 | 88.9-93.5 |
| mouth_lair_b2 | lair | facing enemy's | 87.8 | 87.8 | 87.8 | 87.8 | 0.0 % | 17.6 | 19.1 | 91.0-95.4 |
| vale_watch_b2 | point watchtower | facing enemy's | 88.9 | 88.9 | 88.9 | 88.9 | 0.0 % | 17.8 | 19.3 | 86.6-90.0 |
| peddler_a2 | peddler | ally's | 92.1 | 92.1 | 92.1 | 92.1 | 0.0 % | 18.4 | 20.0 | 91.9-101.2 |
| ford_nest_a2 | camp 2.0 | river (ally side) | 92.0 | 92.2 | 92.2 | 92.2 | 0.2 % | 18.4 | 20.0 | 94.4-100.3 |
| ford_n | crossing ford | river (ally side) | 92.0 | 92.2 | 92.2 | 92.2 | 0.2 % | 18.4 | 20.0 | 94.4-100.3 |
| tavern_b2 | tavern | facing enemy's | 97.7 | 97.7 | 97.7 | 97.7 | 0.1 % | 19.5 | 21.2 | 99.2-104.2 |
| wallow_a2 | camp 1.0 | ally's | 98.2 | 98.2 | 98.2 | 98.2 | 0.0 % | 19.6 | 21.3 | 100.7-108.3 |
| rich_b2 | node | facing enemy's | 98.4 | 98.3 | 98.3 | 98.4 | 0.2 % | 19.7 | 21.4 | 101.3-105.8 |
| vale_watch_a2 | point watchtower | ally's | 98.4 | 98.4 | 98.4 | 98.4 | 0.0 % | 19.7 | 21.4 | 100.8-108.1 |
| tavern_b1 | tavern | diagonal enemy's | 99.2 | 99.2 | 99.2 | 99.3 | 0.1 % | 19.8 | 21.6 | 100.4-105.1 |
| shrine_b1 | point shrine | enemy midline | 100.9 | 100.9 | 100.9 | 100.9 | 0.0 % | 20.2 | 21.9 | 102.2-115.4 |
| well_b2 | point well | facing enemy's | 102.2 | 102.1 | 102.1 | 102.2 | 0.1 % | 20.4 | 22.2 | 99.7-102.9 |
| vale_lair_a2 | lair | ally's | 103.2 | 103.2 | 103.2 | 103.2 | 0.0 % | 20.6 | 22.4 | 104.5-115.1 |
| fordwatch_b1 | point watchtower | diagonal enemy's | 103.4 | 103.8 | 103.8 | 103.5 | 0.4 % | 20.7 | 22.5 | 104.1-110.3 |
| rich_a2 | node | ally's | 106.2 | 106.2 | 106.2 | 106.2 | 0.0 % | 21.2 | 23.1 | 107.3-115.6 |
| bridge_nest_a2 | camp 2.0 | ally's | 106.9 | 106.9 | 106.9 | 106.9 | 0.0 % | 21.4 | 23.2 | 109.1-116.3 |
| natural_b2 | node | facing enemy's | 108.8 | 108.7 | 108.8 | 108.8 | 0.1 % | 21.7 | 23.6 | 105.9-109.2 |
| vale_post_a2 | post | ally's | 111.0 | 111.0 | 111.0 | 111.0 | 0.0 % | 22.2 | 24.1 | 110.3-119.6 |
| stag_b1 | camp 3.0 | diagonal enemy's | 111.3 | 111.7 | 111.7 | 111.7 | 0.4 % | 22.3 | 24.3 | 111.5-125.3 |
| green_cache_b1 | cache | enemy midline | 112.9 | 112.9 | 112.9 | 112.9 | 0.0 % | 22.6 | 24.5 | 114.1-123.5 |
| well_b1 | point well | diagonal enemy's | 116.5 | 116.5 | 116.5 | 116.6 | 0.1 % | 23.3 | 25.3 | 117.4-128.5 |
| vale_watch_b1 | point watchtower | diagonal enemy's | 116.5 | 116.7 | 116.7 | 116.7 | 0.2 % | 23.3 | 25.4 | 116.3-122.3 |
| cache_b2 | cache | facing enemy's | 117.3 | 117.2 | 117.3 | 117.3 | 0.1 % | 23.5 | 25.5 | 115.0-118.2 |
| bridge_road_n | crossing bridge_road | river (ally side) | 118.9 | 119.0 | 119.0 | 118.9 | 0.1 % | 23.8 | 25.9 | 121.0-128.2 |
| mouth_lair_a2 | lair | ally's | 119.5 | 119.5 | 119.5 | 119.5 | 0.0 % | 23.9 | 26.0 | 123.7-141.5 |
| bridge_nest_b1 | camp 2.0 | diagonal enemy's | 121.0 | 121.2 | 121.2 | 121.2 | 0.1 % | 24.2 | 26.3 | 120.3-126.4 |
| peddler_b2 | peddler | facing enemy's | 122.5 | 122.5 | 122.5 | 122.5 | 0.0 % | 24.5 | 26.6 | 127.9-132.4 |
| vale_post_b2 | post | facing enemy's | 122.7 | 122.6 | 122.5 | 122.7 | 0.1 % | 24.5 | 26.7 | 124.4-128.9 |
| node_b_b2 | node | facing enemy's | 126.5 | 126.4 | 126.4 | 126.5 | 0.1 % | 25.3 | 27.5 | 124.0-127.2 |
| lodge_b1 | guild | enemy midline | 126.9 | 126.9 | 126.9 | 126.9 | 0.0 % | 25.4 | 27.6 | 128.1-134.4 |
| mouth_lair_b1 | lair | diagonal enemy's | 131.9 | 132.0 | 132.0 | 131.9 | 0.1 % | 26.4 | 28.7 | 133.6-141.0 |
| wallow_b2 | camp 1.0 | facing enemy's | 132.4 | 132.3 | 132.3 | 132.4 | 0.1 % | 26.5 | 28.8 | 135.3-139.8 |
| keep_b2 | keep | facing enemy's | 132.4 | 132.3 | 132.3 | 132.4 | 0.1 % | 26.5 | 28.8 | 132.2-155.1 |
| natural_b1 | node | diagonal enemy's | 134.8 | 134.8 | 134.8 | 134.9 | 0.1 % | 27.0 | 29.3 | 134.7-140.3 |
| rich_b1 | node | diagonal enemy's | 135.2 | 135.3 | 135.3 | 135.3 | 0.1 % | 27.1 | 29.4 | 134.5-140.6 |
| cache_b1 | cache | diagonal enemy's | 135.8 | 135.8 | 135.8 | 135.9 | 0.1 % | 27.2 | 29.5 | 137.0-143.8 |
| node_b_b1 | node | diagonal enemy's | 137.6 | 137.6 | 137.6 | 137.7 | 0.1 % | 27.5 | 29.9 | 138.4-152.8 |
| keep_b1 | keep | diagonal enemy's | 140.2 | 140.2 | 140.2 | 140.2 | 0.0 % | 28.0 | 30.5 | 142.9-160.9 |
| node_a_b2 | node | facing enemy's | 141.3 | 141.2 | 141.2 | 141.3 | 0.1 % | 28.2 | 30.7 | 137.8-148.2 |
| node_a_b1 | node | diagonal enemy's | 144.9 | 144.9 | 144.9 | 144.9 | 0.0 % | 29.0 | 31.5 | 144.6-157.6 |
| vale_lair_b2 | lair | facing enemy's | 149.7 | 149.6 | 149.6 | 149.7 | 0.1 % | 29.9 | 32.5 | 151.6-156.0 |
| peddler_b1 | peddler | diagonal enemy's | 149.7 | 149.9 | 149.9 | 149.9 | 0.1 % | 30.0 | 32.6 | 149.6-155.7 |
| den_b1 | guild | enemy midline | 150.9 | 150.9 | 150.9 | 150.9 | 0.0 % | 30.2 | 32.8 | 152.1-156.8 |
| corner_post_b2 | post | facing enemy's | 153.1 | 153.0 | 153.1 | 153.1 | 0.1 % | 30.6 | 33.3 | 160.5-165.0 |
| vale_post_b1 | post | diagonal enemy's | 157.0 | 157.2 | 157.2 | 157.2 | 0.1 % | 31.4 | 34.2 | 156.6-162.7 |
| wallow_b1 | camp 1.0 | diagonal enemy's | 160.9 | 161.1 | 161.1 | 161.1 | 0.1 % | 32.2 | 35.0 | 160.5-166.6 |
| corner_post_b1 | post | diagonal enemy's | 171.3 | 171.3 | 171.3 | 171.4 | 0.1 % | 34.3 | 37.2 | 179.9-227.5 |
| vale_lair_b1 | lair | diagonal enemy's | 177.6 | 177.8 | 177.8 | 177.8 | 0.1 % | 35.6 | 38.6 | 177.4-183.5 |

## Contest per spot (nearest seat of each side, m; contested = sides within 15 %)

| Spot | Kind | nearest side 0 | m | nearest side 1 | m | ratio 0/1 | |
|---|---|---|---|---|---|---|---|
| bridge_nest_a1 | camp | a1 | 64.0 | b2 | 86.3 | 0.74 |  |
| bridge_nest_a2 | camp | a2 | 64.0 | b1 | 85.7 | 0.75 |  |
| bridge_nest_b1 | camp | a2 | 85.8 | b1 | 64.0 | 1.34 |  |
| bridge_nest_b2 | camp | a1 | 86.3 | b2 | 64.0 | 1.35 |  |
| cache_a1 | cache | a1 | 14.8 | b2 | 117.3 | 0.13 |  |
| cache_a2 | cache | a2 | 14.8 | b1 | 117.3 | 0.13 |  |
| cache_b1 | cache | a2 | 117.2 | b1 | 14.8 | 7.91 |  |
| cache_b2 | cache | a1 | 117.3 | b2 | 14.8 | 7.91 |  |
| corner_post_a1 | post | a1 | 25.1 | b2 | 153.1 | 0.16 |  |
| corner_post_a2 | post | a2 | 25.1 | b1 | 153.1 | 0.16 |  |
| corner_post_b1 | post | a2 | 153.0 | b1 | 25.1 | 6.09 |  |
| corner_post_b2 | post | a1 | 153.1 | b2 | 25.1 | 6.09 |  |
| crown_a1 | crown | a1 | 68.9 | b1 | 68.9 | 1.00 | contested |
| den_a1 | guild | a1 | 27.1 | b1 | 150.9 | 0.18 |  |
| den_b1 | guild | a1 | 150.9 | b1 | 27.1 | 5.56 |  |
| ford_nest_a1 | camp | a1 | 65.4 | b2 | 65.4 | 1.00 | contested |
| ford_nest_a2 | camp | a2 | 65.4 | b1 | 65.4 | 1.00 | contested |
| fordwatch_a1 | point | a1 | 54.0 | b2 | 77.0 | 0.70 |  |
| fordwatch_a2 | point | a2 | 54.0 | b1 | 76.7 | 0.70 |  |
| fordwatch_b1 | point | a2 | 76.9 | b1 | 54.0 | 1.42 |  |
| fordwatch_b2 | point | a1 | 77.0 | b2 | 54.0 | 1.43 |  |
| green_cache_a1 | cache | a1 | 31.8 | b1 | 112.9 | 0.28 |  |
| green_cache_b1 | cache | a1 | 112.9 | b1 | 31.8 | 3.55 |  |
| lodge_a1 | guild | a1 | 26.2 | b1 | 126.9 | 0.21 |  |
| lodge_b1 | guild | a1 | 126.9 | b1 | 26.2 | 4.85 |  |
| mouth_lair_a1 | lair | a1 | 71.4 | b2 | 87.8 | 0.81 |  |
| mouth_lair_a2 | lair | a2 | 71.4 | b1 | 87.8 | 0.81 |  |
| mouth_lair_b1 | lair | a2 | 87.8 | b1 | 71.4 | 1.23 |  |
| mouth_lair_b2 | lair | a1 | 87.8 | b2 | 71.4 | 1.23 |  |
| natural_a1 | node | a1 | 26.6 | b2 | 108.8 | 0.24 |  |
| natural_a2 | node | a2 | 26.6 | b1 | 108.8 | 0.24 |  |
| natural_b1 | node | a2 | 108.7 | b1 | 26.6 | 4.08 |  |
| natural_b2 | node | a1 | 108.8 | b2 | 26.6 | 4.09 |  |
| node_a_a1 | node | a1 | 4.0 | b2 | 141.3 | 0.03 |  |
| node_a_a2 | node | a2 | 4.0 | b1 | 141.2 | 0.03 |  |
| node_a_b1 | node | a2 | 141.2 | b1 | 4.0 | 35.30 |  |
| node_a_b2 | node | a1 | 141.3 | b2 | 4.0 | 35.32 |  |
| node_b_a1 | node | a1 | 4.0 | b2 | 126.5 | 0.03 |  |
| node_b_a2 | node | a2 | 4.0 | b1 | 126.4 | 0.03 |  |
| node_b_b1 | node | a2 | 126.4 | b1 | 4.0 | 31.59 |  |
| node_b_b2 | node | a1 | 126.5 | b2 | 4.0 | 31.62 |  |
| peddler_a1 | peddler | a1 | 32.1 | b2 | 122.5 | 0.26 |  |
| peddler_a2 | peddler | a2 | 32.1 | b1 | 122.5 | 0.26 |  |
| peddler_b1 | peddler | a2 | 122.5 | b1 | 32.1 | 3.82 |  |
| peddler_b2 | peddler | a1 | 122.5 | b2 | 32.1 | 3.82 |  |
| rich_a1 | node | a1 | 54.0 | b2 | 98.4 | 0.55 |  |
| rich_a2 | node | a2 | 54.0 | b1 | 98.3 | 0.55 |  |
| rich_b1 | node | a2 | 98.3 | b1 | 54.0 | 1.82 |  |
| rich_b2 | node | a1 | 98.4 | b2 | 54.0 | 1.82 |  |
| shrine_a1 | point | a1 | 40.3 | b1 | 100.9 | 0.40 |  |
| shrine_b1 | point | a1 | 100.9 | b1 | 40.3 | 2.50 |  |
| stag_a1 | camp | a1 | 46.2 | b2 | 84.9 | 0.54 |  |
| stag_a2 | camp | a2 | 46.2 | b1 | 84.9 | 0.54 |  |
| stag_b1 | camp | a2 | 84.8 | b1 | 46.2 | 1.84 |  |
| stag_b2 | camp | a1 | 84.9 | b2 | 46.2 | 1.84 |  |
| tavern_a1 | tavern | a1 | 39.6 | b2 | 97.7 | 0.41 |  |
| tavern_a2 | tavern | a2 | 39.6 | b1 | 97.7 | 0.41 |  |
| tavern_b1 | tavern | a2 | 97.7 | b1 | 39.6 | 2.47 |  |
| tavern_b2 | tavern | a1 | 97.7 | b2 | 39.6 | 2.47 |  |
| vale_lair_a1 | lair | a1 | 43.2 | b2 | 149.7 | 0.29 |  |
| vale_lair_a2 | lair | a2 | 43.2 | b1 | 149.6 | 0.29 |  |
| vale_lair_b1 | lair | a2 | 149.6 | b1 | 43.2 | 3.46 |  |
| vale_lair_b2 | lair | a1 | 149.7 | b2 | 43.2 | 3.46 |  |
| vale_post_a1 | post | a1 | 51.0 | b2 | 122.7 | 0.42 |  |
| vale_post_a2 | post | a2 | 51.0 | b1 | 122.5 | 0.42 |  |
| vale_post_b1 | post | a2 | 122.6 | b1 | 51.0 | 2.40 |  |
| vale_post_b2 | post | a1 | 122.7 | b2 | 51.0 | 2.40 |  |
| vale_watch_a1 | point | a1 | 56.4 | b2 | 88.9 | 0.64 |  |
| vale_watch_a2 | point | a2 | 56.4 | b1 | 88.9 | 0.64 |  |
| vale_watch_b1 | point | a2 | 88.9 | b1 | 56.4 | 1.57 |  |
| vale_watch_b2 | point | a1 | 88.9 | b2 | 56.4 | 1.57 |  |
| wallow_a1 | camp | a1 | 38.2 | b2 | 132.4 | 0.29 |  |
| wallow_a2 | camp | a2 | 38.2 | b1 | 132.3 | 0.29 |  |
| wallow_b1 | camp | a2 | 132.3 | b1 | 38.2 | 3.47 |  |
| wallow_b2 | camp | a1 | 132.4 | b2 | 38.2 | 3.47 |  |
| well_a1 | point | a1 | 29.0 | b2 | 102.2 | 0.28 |  |
| well_a2 | point | a2 | 29.0 | b1 | 102.1 | 0.28 |  |
| well_b1 | point | a2 | 102.1 | b1 | 29.0 | 3.52 |  |
| well_b2 | point | a1 | 102.2 | b2 | 29.0 | 3.52 |  |

89 targets, 4 seats, 12.1 s.

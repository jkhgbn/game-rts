# Travel times: Fourfold Hollow (2v2)

16-neighbour Dijkstra on the preview navmesh (0.5 m grid, ford cells x1.54), from each keep's navmesh point. Soldier 5.0 m/s, worker 4.6 m/s. `nav` = NavigationServer path (engine, not mirrored).

| Target (A1 view) | Kind | Where | a1 m | a2 m | b1 m | b2 m | spread | soldier s | worker s | nav min-max m |
|---|---|---|---|---|---|---|---|---|---|---|
| keep_a1 | keep | own | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 % | 0.0 | 0.0 | 0.0-0.0 |
| node_b_a1 | node | own | 4.0 | 4.0 | 4.0 | 4.0 | 0.0 % | 0.8 | 0.9 | 6.7-11.1 |
| node_a_a1 | node | own | 4.0 | 4.0 | 4.0 | 4.0 | 0.0 % | 0.8 | 0.9 | 6.7-16.8 |
| cache_a1 | cache | own | 11.7 | 11.7 | 11.7 | 11.7 | 0.0 % | 2.3 | 2.5 | 14.5-19.8 |
| bristleback_a1 | camp 1.0 | own | 16.0 | 16.0 | 16.0 | 16.0 | 0.0 % | 3.2 | 3.5 | 19.5-26.5 |
| heron_ford_a1 | post | own | 17.7 | 17.7 | 17.7 | 17.7 | 0.0 % | 3.5 | 3.8 | 22.1-30.1 |
| node_mid_a1 | node | own | 22.0 | 22.0 | 22.0 | 22.0 | 0.0 % | 4.4 | 4.8 | 23.5-26.7 |
| greywater_lodge_a1 | guild | team midline | 25.0 | 25.0 | 25.0 | 25.0 | 0.0 % | 5.0 | 5.4 | 26.3-36.4 |
| magpie_den_a1 | guild | team midline | 26.9 | 26.9 | 26.9 | 26.9 | 0.0 % | 5.4 | 5.8 | 29.6-39.1 |
| mid_cache_a1 | cache | team midline | 27.6 | 27.6 | 27.6 | 27.6 | 0.0 % | 5.5 | 6.0 | 30.4-38.6 |
| glade_vein_a1 | node | own | 29.0 | 29.0 | 29.0 | 29.0 | 0.0 % | 5.8 | 6.3 | 30.3-40.2 |
| mossmere_a1 | point well | own | 30.9 | 30.9 | 30.9 | 30.9 | 0.0 % | 6.2 | 6.7 | 32.9-37.5 |
| gloomcap_a1 | camp 2.0 | team midline | 33.0 | 33.0 | 33.0 | 33.0 | 0.0 % | 6.6 | 7.2 | 36.4-43.2 |
| peddler_a1 | peddler | own | 34.5 | 34.5 | 34.5 | 34.5 | 0.0 % | 6.9 | 7.5 | 38.6-42.8 |
| heron_ford_a2 | post | ally's | 37.1 | 37.1 | 37.1 | 37.1 | 0.0 % | 7.4 | 8.1 | 39.1-48.8 |
| stag_glade_a1 | camp 3.0 | own | 37.2 | 37.2 | 37.2 | 37.2 | 0.0 % | 7.4 | 8.1 | 38.6-48.2 |
| tavern_a1 | tavern | own | 39.8 | 39.8 | 39.8 | 39.8 | 0.0 % | 8.0 | 8.6 | 42.6-47.6 |
| wayshrine_a1 | point shrine | team midline | 40.3 | 40.3 | 40.3 | 40.3 | 0.0 % | 8.1 | 8.8 | 43.6-49.5 |
| millrace_a1 | node | own | 45.2 | 45.2 | 45.2 | 45.2 | 0.0 % | 9.0 | 9.8 | 47.0-50.2 |
| node_a_a2 | node | ally's | 46.0 | 46.0 | 46.0 | 46.0 | 0.0 % | 9.2 | 10.0 | 47.4-58.6 |
| heath_lair_a1 | lair | own | 47.0 | 47.0 | 47.0 | 47.0 | 0.0 % | 9.4 | 10.2 | 49.1-57.3 |
| cache_a2 | cache | ally's | 49.6 | 49.6 | 49.6 | 49.6 | 0.0 % | 9.9 | 10.8 | 50.6-59.5 |
| tavern_a2 | tavern | ally's | 49.7 | 49.7 | 49.7 | 49.7 | 0.0 % | 9.9 | 10.8 | 53.4-59.3 |
| keep_a2 | keep | ally's | 51.5 | 51.5 | 51.5 | 51.5 | 0.0 % | 10.3 | 11.2 | 58.2-64.2 |
| mossmere_a2 | point well | ally's | 51.7 | 51.7 | 51.7 | 51.7 | 0.0 % | 10.3 | 11.2 | 54.6-61.6 |
| fordwatch_a1 | point watchtower | own | 54.2 | 54.2 | 54.2 | 54.2 | 0.0 % | 10.8 | 11.8 | 55.9-59.0 |
| steps_w | crossing steps | team midline | 54.6 | 54.6 | 54.6 | 54.6 | 0.0 % | 10.9 | 11.9 | 57.6-62.8 |
| rich_a1 | node | own | 54.6 | 54.6 | 54.6 | 54.6 | 0.0 % | 10.9 | 11.9 | 58.5-62.7 |
| millstone_cross_a1 | post | own | 55.6 | 55.6 | 55.6 | 55.6 | 0.0 % | 11.1 | 12.1 | 59.0-65.3 |
| millwatch_a1 | point watchtower | own | 57.0 | 57.0 | 57.0 | 57.0 | 0.0 % | 11.4 | 12.4 | 59.1-62.9 |
| node_b_a2 | node | ally's | 58.9 | 58.9 | 58.9 | 58.9 | 0.0 % | 11.8 | 12.8 | 59.8-75.8 |
| node_mid_a2 | node | ally's | 59.2 | 59.2 | 59.2 | 59.2 | 0.0 % | 11.8 | 12.9 | 61.2-69.4 |
| bridge_nest_a1 | camp 2.0 | own | 62.6 | 62.6 | 62.6 | 62.6 | 0.0 % | 12.5 | 13.6 | 66.7-70.8 |
| ford_nest_a1 | camp 2.0 | river (own side) | 63.4 | 63.4 | 63.4 | 63.4 | 0.0 % | 12.7 | 13.8 | 63.2-66.4 |
| ford_s | crossing ford | river (own side) | 63.4 | 63.4 | 63.4 | 63.4 | 0.0 % | 12.7 | 13.8 | 63.2-66.4 |
| crown_a1 | crown | centre | 66.9 | 66.9 | 66.9 | 66.9 | 0.0 % | 13.4 | 14.5 | 68.9-74.1 |
| mouth_lair_a1 | lair | own | 69.4 | 69.4 | 69.4 | 69.4 | 0.0 % | 13.9 | 15.1 | 72.8-78.3 |
| fordwatch_b2 | point watchtower | facing enemy's | 71.8 | 71.7 | 71.7 | 71.8 | 0.1 % | 14.3 | 15.6 | 70.1-73.4 |
| bridge_road_s | crossing bridge_road | river (own side) | 72.1 | 72.1 | 72.1 | 72.1 | 0.0 % | 14.4 | 15.7 | 75.5-79.7 |
| bristleback_a2 | camp 1.0 | ally's | 75.1 | 75.1 | 75.1 | 75.1 | 0.0 % | 15.0 | 16.3 | 75.4-84.8 |
| millrace_a2 | node | ally's | 76.8 | 76.8 | 76.8 | 76.8 | 0.0 % | 15.4 | 16.7 | 79.4-86.2 |
| steps_e | crossing steps | enemy midline | 79.5 | 79.5 | 79.5 | 79.5 | 0.0 % | 15.9 | 17.3 | 81.5-86.3 |
| millwatch_b2 | point watchtower | facing enemy's | 79.5 | 79.5 | 79.5 | 79.5 | 0.0 % | 15.9 | 17.3 | 77.2-80.7 |
| millrace_b2 | node | facing enemy's | 80.8 | 80.7 | 80.7 | 80.8 | 0.1 % | 16.1 | 17.5 | 78.9-82.1 |
| bridge_nest_b2 | camp 2.0 | facing enemy's | 81.8 | 81.3 | 81.2 | 81.8 | 0.7 % | 16.3 | 17.7 | 84.4-89.0 |
| fordwatch_a2 | point watchtower | ally's | 82.1 | 82.1 | 82.1 | 82.1 | 0.0 % | 16.4 | 17.9 | 85.3-91.5 |
| peddler_a2 | peddler | ally's | 82.3 | 82.3 | 82.3 | 82.3 | 0.0 % | 16.5 | 17.9 | 84.0-92.2 |
| mouth_lair_b2 | lair | facing enemy's | 84.2 | 84.2 | 84.2 | 84.2 | 0.0 % | 16.8 | 18.3 | 87.4-91.8 |
| rich_b2 | node | facing enemy's | 87.8 | 87.5 | 87.5 | 87.8 | 0.3 % | 17.5 | 19.1 | 89.0-92.3 |
| glade_vein_a2 | node | ally's | 89.2 | 89.2 | 89.2 | 89.2 | 0.0 % | 17.8 | 19.4 | 90.9-100.2 |
| ford_n | crossing ford | river (ally side) | 90.7 | 90.8 | 90.8 | 90.8 | 0.1 % | 18.2 | 19.7 | 93.0-99.0 |
| ford_nest_a2 | camp 2.0 | river (ally side) | 90.7 | 90.8 | 90.8 | 90.8 | 0.1 % | 18.2 | 19.7 | 93.0-99.0 |
| tavern_b2 | tavern | facing enemy's | 92.7 | 92.7 | 92.7 | 92.7 | 0.0 % | 18.5 | 20.2 | 94.8-104.2 |
| tavern_b1 | tavern | diagonal enemy's | 94.0 | 94.0 | 94.0 | 94.0 | 0.0 % | 18.8 | 20.4 | 95.6-119.5 |
| millwatch_a2 | point watchtower | ally's | 94.7 | 94.7 | 94.7 | 94.7 | 0.0 % | 18.9 | 20.6 | 97.0-104.0 |
| millstone_cross_b2 | post | facing enemy's | 96.8 | 96.7 | 96.6 | 96.8 | 0.2 % | 19.3 | 21.0 | 99.3-103.6 |
| wayshrine_b1 | point shrine | enemy midline | 96.9 | 96.9 | 96.9 | 96.9 | 0.0 % | 19.4 | 21.1 | 98.7-114.2 |
| peddler_b2 | peddler | facing enemy's | 97.2 | 97.1 | 97.2 | 97.2 | 0.1 % | 19.4 | 21.1 | 94.6-97.9 |
| stag_glade_a2 | camp 3.0 | ally's | 97.2 | 97.2 | 97.2 | 97.2 | 0.0 % | 19.4 | 21.1 | 99.6-108.1 |
| fordwatch_b1 | point watchtower | diagonal enemy's | 98.8 | 99.2 | 99.2 | 99.1 | 0.4 % | 19.8 | 21.5 | 99.1-105.4 |
| rich_a2 | node | ally's | 99.3 | 99.3 | 99.3 | 99.3 | 0.0 % | 19.9 | 21.6 | 102.1-109.7 |
| mossmere_b2 | point well | facing enemy's | 103.0 | 103.0 | 103.0 | 103.0 | 0.1 % | 20.6 | 22.4 | 101.3-106.3 |
| mossmere_b1 | point well | diagonal enemy's | 104.3 | 104.3 | 104.3 | 104.3 | 0.1 % | 20.9 | 22.7 | 105.6-129.8 |
| node_mid_b2 | node | facing enemy's | 105.4 | 105.3 | 105.3 | 105.4 | 0.1 % | 21.1 | 22.9 | 102.8-106.0 |
| bridge_nest_a2 | camp 2.0 | ally's | 105.5 | 105.5 | 105.5 | 105.5 | 0.0 % | 21.1 | 22.9 | 107.7-114.9 |
| gloomcap_b1 | camp 2.0 | enemy midline | 106.9 | 106.9 | 106.9 | 106.9 | 0.0 % | 21.4 | 23.2 | 108.7-120.7 |
| heath_lair_a2 | lair | ally's | 107.0 | 107.0 | 107.0 | 107.0 | 0.0 % | 21.4 | 23.3 | 106.4-115.6 |
| millrace_b1 | node | diagonal enemy's | 107.8 | 108.2 | 108.2 | 108.1 | 0.4 % | 21.6 | 23.5 | 108.2-117.0 |
| millwatch_b1 | point watchtower | diagonal enemy's | 108.0 | 108.1 | 108.1 | 108.1 | 0.1 % | 21.6 | 23.5 | 107.5-113.6 |
| millstone_cross_a2 | post | ally's | 109.7 | 109.7 | 109.7 | 109.7 | 0.0 % | 21.9 | 23.9 | 110.3-118.7 |
| bridge_road_n | crossing bridge_road | river (ally side) | 116.0 | 116.1 | 116.1 | 116.0 | 0.1 % | 23.2 | 25.2 | 118.1-125.3 |
| mid_cache_b1 | cache | enemy midline | 116.9 | 116.9 | 116.9 | 116.9 | 0.0 % | 23.4 | 25.4 | 118.7-128.1 |
| heath_lair_b2 | lair | facing enemy's | 117.3 | 117.2 | 117.1 | 117.3 | 0.2 % | 23.4 | 25.5 | 119.3-123.6 |
| node_mid_b1 | node | diagonal enemy's | 117.3 | 117.2 | 117.2 | 117.2 | 0.1 % | 23.4 | 25.5 | 118.9-143.7 |
| mouth_lair_a2 | lair | ally's | 117.3 | 117.3 | 117.3 | 117.3 | 0.0 % | 23.5 | 25.5 | 121.4-139.5 |
| cache_b2 | cache | facing enemy's | 118.1 | 118.0 | 118.0 | 118.1 | 0.1 % | 23.6 | 25.7 | 115.3-118.6 |
| bridge_nest_b1 | camp 2.0 | diagonal enemy's | 118.3 | 118.4 | 118.4 | 118.4 | 0.1 % | 23.7 | 25.7 | 117.4-123.6 |
| bristleback_b2 | camp 1.0 | facing enemy's | 118.8 | 118.7 | 118.8 | 118.8 | 0.1 % | 23.7 | 25.8 | 131.0-135.5 |
| rich_b1 | node | diagonal enemy's | 119.5 | 119.7 | 119.7 | 119.7 | 0.1 % | 23.9 | 26.0 | 119.2-125.3 |
| cache_b1 | cache | diagonal enemy's | 122.1 | 122.1 | 122.1 | 122.1 | 0.0 % | 24.4 | 26.5 | 123.7-143.8 |
| node_b_b2 | node | facing enemy's | 122.5 | 122.4 | 122.4 | 122.5 | 0.1 % | 24.5 | 26.6 | 120.0-123.2 |
| peddler_b1 | peddler | diagonal enemy's | 124.3 | 124.7 | 124.7 | 124.7 | 0.3 % | 24.9 | 27.1 | 124.2-132.2 |
| mouth_lair_b1 | lair | diagonal enemy's | 128.1 | 128.2 | 128.2 | 128.1 | 0.1 % | 25.6 | 27.9 | 130.0-137.4 |
| keep_b2 | keep | facing enemy's | 128.4 | 128.3 | 128.3 | 128.4 | 0.1 % | 25.7 | 27.9 | 128.2-164.5 |
| greywater_lodge_b1 | guild | enemy midline | 129.9 | 129.9 | 129.9 | 129.9 | 0.0 % | 26.0 | 28.2 | 131.7-138.8 |
| stag_glade_b2 | camp 3.0 | facing enemy's | 131.9 | 131.8 | 131.7 | 131.9 | 0.1 % | 26.4 | 28.7 | 134.6-138.9 |
| node_b_b1 | node | diagonal enemy's | 134.4 | 134.3 | 134.3 | 134.3 | 0.1 % | 26.9 | 29.2 | 135.4-155.3 |
| glade_vein_b2 | node | facing enemy's | 134.5 | 134.4 | 134.5 | 134.5 | 0.1 % | 26.9 | 29.2 | 138.8-143.2 |
| keep_b1 | keep | diagonal enemy's | 136.5 | 136.4 | 136.4 | 136.4 | 0.1 % | 27.3 | 29.7 | 139.5-161.2 |
| millstone_cross_b1 | post | diagonal enemy's | 137.0 | 137.1 | 137.1 | 137.1 | 0.1 % | 27.4 | 29.8 | 136.4-142.8 |
| node_a_b2 | node | facing enemy's | 137.3 | 137.2 | 137.2 | 137.3 | 0.1 % | 27.4 | 29.8 | 136.2-141.7 |
| bristleback_b1 | camp 1.0 | diagonal enemy's | 140.6 | 140.5 | 140.5 | 140.5 | 0.1 % | 28.1 | 30.6 | 144.8-151.1 |
| node_a_b1 | node | diagonal enemy's | 140.9 | 140.9 | 140.9 | 140.9 | 0.0 % | 28.2 | 30.6 | 141.1-156.2 |
| magpie_den_b1 | guild | enemy midline | 145.9 | 145.9 | 145.9 | 145.9 | 0.0 % | 29.2 | 31.7 | 147.6-152.8 |
| heron_ford_b2 | post | facing enemy's | 148.0 | 148.0 | 148.0 | 148.0 | 0.0 % | 29.6 | 32.2 | 149.0-150.3 |
| heron_ford_b1 | post | diagonal enemy's | 149.3 | 149.3 | 149.3 | 149.3 | 0.0 % | 29.9 | 32.4 | 149.5-158.5 |
| heath_lair_b1 | lair | diagonal enemy's | 151.6 | 151.7 | 151.7 | 151.7 | 0.1 % | 30.3 | 33.0 | 151.0-157.1 |
| glade_vein_b1 | node | diagonal enemy's | 160.9 | 160.8 | 160.8 | 160.8 | 0.1 % | 32.2 | 35.0 | 160.9-167.1 |
| stag_glade_b1 | camp 3.0 | diagonal enemy's | 161.2 | 161.3 | 161.3 | 161.3 | 0.1 % | 32.3 | 35.1 | 160.7-166.9 |

## Contest per spot (nearest seat of each side, m; contested = sides within 15 %)

| Spot | Kind | nearest side 0 | m | nearest side 1 | m | ratio 0/1 | |
|---|---|---|---|---|---|---|---|
| bridge_nest_a1 | camp | a1 | 62.6 | b2 | 81.8 | 0.77 |  |
| bridge_nest_a2 | camp | a2 | 62.6 | b1 | 81.2 | 0.77 |  |
| bridge_nest_b1 | camp | a2 | 81.3 | b1 | 62.6 | 1.30 |  |
| bridge_nest_b2 | camp | a1 | 81.8 | b2 | 62.6 | 1.31 |  |
| bristleback_a1 | camp | a1 | 16.0 | b2 | 118.8 | 0.13 |  |
| bristleback_a2 | camp | a2 | 16.0 | b1 | 118.8 | 0.13 |  |
| bristleback_b1 | camp | a2 | 118.7 | b1 | 16.0 | 7.41 |  |
| bristleback_b2 | camp | a1 | 118.8 | b2 | 16.0 | 7.42 |  |
| cache_a1 | cache | a1 | 11.7 | b2 | 118.1 | 0.10 |  |
| cache_a2 | cache | a2 | 11.7 | b1 | 118.0 | 0.10 |  |
| cache_b1 | cache | a2 | 118.0 | b1 | 11.7 | 10.07 |  |
| cache_b2 | cache | a1 | 118.1 | b2 | 11.7 | 10.08 |  |
| crown_a1 | crown | a1 | 66.9 | b1 | 66.9 | 1.00 | contested |
| ford_nest_a1 | camp | a1 | 63.4 | b2 | 63.4 | 1.00 | contested |
| ford_nest_a2 | camp | a2 | 63.4 | b1 | 63.4 | 1.00 | contested |
| fordwatch_a1 | point | a1 | 54.2 | b2 | 71.8 | 0.76 |  |
| fordwatch_a2 | point | a2 | 54.2 | b1 | 71.7 | 0.76 |  |
| fordwatch_b1 | point | a2 | 71.7 | b1 | 54.2 | 1.32 |  |
| fordwatch_b2 | point | a1 | 71.8 | b2 | 54.2 | 1.32 |  |
| glade_vein_a1 | node | a1 | 29.0 | b2 | 134.5 | 0.22 |  |
| glade_vein_a2 | node | a2 | 29.0 | b1 | 134.5 | 0.22 |  |
| glade_vein_b1 | node | a2 | 134.4 | b1 | 29.0 | 4.64 |  |
| glade_vein_b2 | node | a1 | 134.5 | b2 | 29.0 | 4.64 |  |
| gloomcap_a1 | camp | a1 | 33.0 | b1 | 106.9 | 0.31 |  |
| gloomcap_b1 | camp | a1 | 106.9 | b1 | 33.0 | 3.24 |  |
| greywater_lodge_a1 | guild | a1 | 25.0 | b1 | 129.9 | 0.19 |  |
| greywater_lodge_b1 | guild | a1 | 129.9 | b1 | 25.0 | 5.20 |  |
| heath_lair_a1 | lair | a1 | 47.0 | b2 | 117.3 | 0.40 |  |
| heath_lair_a2 | lair | a2 | 47.0 | b1 | 117.1 | 0.40 |  |
| heath_lair_b1 | lair | a2 | 117.2 | b1 | 47.0 | 2.49 |  |
| heath_lair_b2 | lair | a1 | 117.3 | b2 | 47.0 | 2.49 |  |
| heron_ford_a1 | post | a1 | 17.7 | b2 | 148.0 | 0.12 |  |
| heron_ford_a2 | post | a2 | 17.7 | b1 | 148.0 | 0.12 |  |
| heron_ford_b1 | post | a2 | 148.0 | b1 | 17.7 | 8.38 |  |
| heron_ford_b2 | post | a1 | 148.0 | b2 | 17.7 | 8.38 |  |
| magpie_den_a1 | guild | a1 | 26.9 | b1 | 145.9 | 0.18 |  |
| magpie_den_b1 | guild | a1 | 145.9 | b1 | 26.9 | 5.43 |  |
| mid_cache_a1 | cache | a1 | 27.6 | b1 | 116.9 | 0.24 |  |
| mid_cache_b1 | cache | a1 | 116.9 | b1 | 27.6 | 4.24 |  |
| millrace_a1 | node | a1 | 45.2 | b2 | 80.8 | 0.56 |  |
| millrace_a2 | node | a2 | 45.2 | b1 | 80.7 | 0.56 |  |
| millrace_b1 | node | a2 | 80.7 | b1 | 45.2 | 1.78 |  |
| millrace_b2 | node | a1 | 80.8 | b2 | 45.2 | 1.79 |  |
| millstone_cross_a1 | post | a1 | 55.6 | b2 | 96.8 | 0.57 |  |
| millstone_cross_a2 | post | a2 | 55.6 | b1 | 96.6 | 0.58 |  |
| millstone_cross_b1 | post | a2 | 96.7 | b1 | 55.6 | 1.74 |  |
| millstone_cross_b2 | post | a1 | 96.8 | b2 | 55.6 | 1.74 |  |
| millwatch_a1 | point | a1 | 57.0 | b2 | 79.5 | 0.72 |  |
| millwatch_a2 | point | a2 | 57.0 | b1 | 79.5 | 0.72 |  |
| millwatch_b1 | point | a2 | 79.5 | b1 | 57.0 | 1.39 |  |
| millwatch_b2 | point | a1 | 79.5 | b2 | 57.0 | 1.39 |  |
| mossmere_a1 | point | a1 | 30.9 | b2 | 103.0 | 0.30 |  |
| mossmere_a2 | point | a2 | 30.9 | b1 | 103.0 | 0.30 |  |
| mossmere_b1 | point | a2 | 103.0 | b1 | 30.9 | 3.34 |  |
| mossmere_b2 | point | a1 | 103.0 | b2 | 30.9 | 3.33 |  |
| mouth_lair_a1 | lair | a1 | 69.4 | b2 | 84.2 | 0.82 |  |
| mouth_lair_a2 | lair | a2 | 69.4 | b1 | 84.2 | 0.82 |  |
| mouth_lair_b1 | lair | a2 | 84.2 | b1 | 69.4 | 1.21 |  |
| mouth_lair_b2 | lair | a1 | 84.2 | b2 | 69.4 | 1.21 |  |
| node_a_a1 | node | a1 | 4.0 | b2 | 137.3 | 0.03 |  |
| node_a_a2 | node | a2 | 4.0 | b1 | 137.2 | 0.03 |  |
| node_a_b1 | node | a2 | 137.2 | b1 | 4.0 | 34.30 |  |
| node_a_b2 | node | a1 | 137.3 | b2 | 4.0 | 34.32 |  |
| node_b_a1 | node | a1 | 4.0 | b2 | 122.5 | 0.03 |  |
| node_b_a2 | node | a2 | 4.0 | b1 | 122.4 | 0.03 |  |
| node_b_b1 | node | a2 | 122.4 | b1 | 4.0 | 30.59 |  |
| node_b_b2 | node | a1 | 122.5 | b2 | 4.0 | 30.62 |  |
| node_mid_a1 | node | a1 | 22.0 | b2 | 105.4 | 0.21 |  |
| node_mid_a2 | node | a2 | 22.0 | b1 | 105.3 | 0.21 |  |
| node_mid_b1 | node | a2 | 105.3 | b1 | 22.0 | 4.79 |  |
| node_mid_b2 | node | a1 | 105.4 | b2 | 22.0 | 4.79 |  |
| peddler_a1 | peddler | a1 | 34.5 | b2 | 97.2 | 0.36 |  |
| peddler_a2 | peddler | a2 | 34.5 | b1 | 97.2 | 0.36 |  |
| peddler_b1 | peddler | a2 | 97.1 | b1 | 34.5 | 2.81 |  |
| peddler_b2 | peddler | a1 | 97.2 | b2 | 34.5 | 2.82 |  |
| rich_a1 | node | a1 | 54.6 | b2 | 87.8 | 0.62 |  |
| rich_a2 | node | a2 | 54.6 | b1 | 87.5 | 0.62 |  |
| rich_b1 | node | a2 | 87.5 | b1 | 54.6 | 1.60 |  |
| rich_b2 | node | a1 | 87.8 | b2 | 54.6 | 1.61 |  |
| stag_glade_a1 | camp | a1 | 37.2 | b2 | 131.9 | 0.28 |  |
| stag_glade_a2 | camp | a2 | 37.2 | b1 | 131.7 | 0.28 |  |
| stag_glade_b1 | camp | a2 | 131.8 | b1 | 37.2 | 3.54 |  |
| stag_glade_b2 | camp | a1 | 131.9 | b2 | 37.2 | 3.54 |  |
| tavern_a1 | tavern | a1 | 39.8 | b2 | 92.7 | 0.43 |  |
| tavern_a2 | tavern | a2 | 39.8 | b1 | 92.7 | 0.43 |  |
| tavern_b1 | tavern | a2 | 92.7 | b1 | 39.8 | 2.33 |  |
| tavern_b2 | tavern | a1 | 92.7 | b2 | 39.8 | 2.33 |  |
| wayshrine_a1 | point | a1 | 40.3 | b1 | 96.9 | 0.42 |  |
| wayshrine_b1 | point | a1 | 96.9 | b1 | 40.3 | 2.41 |  |

99 targets, 4 seats, 11.1 s.

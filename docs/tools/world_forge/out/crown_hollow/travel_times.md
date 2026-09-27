# Travel times: Crown Hollow (1v1)

16-neighbour Dijkstra on the preview navmesh (0.5 m grid, ford cells x1.54), from each keep's navmesh point. Soldier 5.0 m/s, worker 4.6 m/s. `nav` = NavigationServer path (engine, not mirrored).

| Target (A1 view) | Kind | Where | a1 m | b1 m | spread | soldier s | worker s | nav min-max m |
|---|---|---|---|---|---|---|---|---|
| keep_t0 | keep | own half | 0.0 | 0.0 | 0.0 % | 0.0 | 0.0 | 0.0-0.0 |
| node_fire_a | node | own half | 2.0 | 2.0 | 0.0 % | 0.4 | 0.4 | 7.3-10.4 |
| node_fire_b | node | own half | 2.5 | 2.5 | 0.0 % | 0.5 | 0.5 | 6.0-9.9 |
| camp_wallow_s | camp | own half | 26.1 | 26.1 | 0.0 % | 5.2 | 5.7 | 30.8-33.3 |
| lair_heath_w | lair | own half | 26.2 | 26.2 | 0.0 % | 5.2 | 5.7 | 31.0-33.1 |
| tower_s | point | own half | 29.5 | 29.5 | 0.0 % | 5.9 | 6.4 | 34.8-41.6 |
| millstone_cross | post | own half | 34.4 | 34.4 | 0.0 % | 6.9 | 7.5 | 40.4-48.3 |
| heron_ford | post | own half | 34.4 | 34.4 | 0.0 % | 6.9 | 7.5 | 40.4-48.3 |
| LostCache1 | cache | own half | 34.6 | 34.6 | 0.0 % | 6.9 | 7.5 | 37.3-38.5 |
| node_fire_mid | node | own half | 37.4 | 37.4 | 0.0 % | 7.5 | 8.1 | 47.0-47.1 |
| LostCache0 | cache | own half | 39.9 | 39.9 | 0.0 % | 8.0 | 8.7 | 41.6-43.2 |
| bridge_crown_w | crossing bridge_lane | own half | 41.0 | 41.0 | 0.0 % | 8.2 | 8.9 | 45.5-45.5 |
| shrine_w | point | own half | 47.8 | 47.8 | 0.0 % | 9.6 | 10.4 | 50.0-52.0 |
| camp_stag_w | camp | own half | 48.4 | 48.4 | 0.0 % | 9.7 | 10.5 | 50.2-52.4 |
| ford_s | crossing ford | enemy half | 48.6 | 48.6 | 0.0 % | 9.7 | 10.6 | 49.0-50.9 |
| camp_nest_s | camp | enemy half | 48.6 | 48.6 | 0.0 % | 9.7 | 10.6 | 49.0-50.9 |
| bridge_road_s | crossing bridge_road | enemy half | 50.2 | 50.2 | 0.0 % | 10.0 | 10.9 | 52.3-54.8 |
| crown | crown | centre | 53.7 | 53.7 | 0.0 % | 10.7 | 11.7 | 58.0-58.0 |
| TavernFire | tavern | own half | 55.0 | 55.0 | 0.0 % | 11.0 | 11.9 | 58.5-69.2 |
| lair_crag_w | lair | own half | 57.2 | 57.2 | 0.0 % | 11.4 | 12.4 | 58.8-61.4 |
| steps_nw | crossing steps | own half | 57.6 | 57.6 | 0.0 % | 11.5 | 12.5 | 60.6-61.8 |
| steps_se | crossing steps | enemy half | 58.5 | 58.5 | 0.0 % | 11.7 | 12.7 | 61.8-63.9 |
| tower_se | point | enemy half | 60.8 | 60.8 | 0.0 % | 12.2 | 13.2 | 64.0-74.1 |
| well_w | point | own half | 61.8 | 61.8 | 0.0 % | 12.4 | 13.4 | 66.6-75.9 |
| RuinPeddlerFire | peddler | own half | 62.2 | 62.2 | 0.0 % | 12.4 | 13.5 | 66.6-69.1 |
| TavernShadow | tavern | enemy half | 62.7 | 62.7 | 0.0 % | 12.5 | 13.6 | 67.3-69.7 |
| lair_den_e | lair | enemy half | 65.4 | 65.4 | 0.0 % | 13.1 | 14.2 | 66.8-69.5 |
| bridge_crown_e | crossing bridge_lane | enemy half | 66.5 | 66.5 | 0.0 % | 13.3 | 14.4 | 70.6-70.6 |
| RuinPeddlerShadow | peddler | enemy half | 67.9 | 67.9 | 0.0 % | 13.6 | 14.8 | 66.8-68.7 |
| node_shadow_mid | node | enemy half | 71.0 | 71.0 | 0.0 % | 14.2 | 15.4 | 83.4-83.6 |
| shrine_e | point | enemy half | 72.0 | 72.0 | 0.0 % | 14.4 | 15.7 | 75.2-77.0 |
| well_e | point | enemy half | 72.0 | 72.0 | 0.0 % | 14.4 | 15.7 | 70.8-73.0 |
| lair_hollow_w | lair | own half | 73.9 | 73.9 | 0.0 % | 14.8 | 16.1 | 75.2-77.8 |
| node_fire_rich | node | own half | 76.1 | 76.1 | 0.0 % | 15.2 | 16.5 | 78.9-81.5 |
| node_shadow_rich | node | enemy half | 77.7 | 77.7 | 0.0 % | 15.5 | 16.9 | 81.4-83.1 |
| tower_nw | point | own half | 79.6 | 79.6 | 0.0 % | 15.9 | 17.3 | 81.7-85.2 |
| ford_n | crossing ford | own half | 80.9 | 80.9 | 0.0 % | 16.2 | 17.6 | 81.6-83.6 |
| camp_nest_n | camp | own half | 80.9 | 80.9 | 0.0 % | 16.2 | 17.6 | 81.6-83.6 |
| GreywaterLodgeSouthEast | guild | enemy half | 80.9 | 80.9 | 0.0 % | 16.2 | 17.6 | 82.3-87.2 |
| MagpieDenNorthWest | guild | own half | 80.9 | 80.9 | 0.0 % | 16.2 | 17.6 | 83.8-87.0 |
| LostCache2 | cache | enemy half | 81.8 | 81.8 | 0.0 % | 16.4 | 17.8 | 91.6-91.8 |
| LostCache3 | cache | enemy half | 83.7 | 83.7 | 0.0 % | 16.7 | 18.2 | 86.7-86.8 |
| camp_stag_e | camp | enemy half | 86.8 | 86.8 | 0.0 % | 17.4 | 18.9 | 85.9-87.8 |
| GreywaterLodgeNorthWest | guild | own half | 89.5 | 89.5 | 0.0 % | 17.9 | 19.5 | 94.4-94.4 |
| MagpieDenSouthEast | guild | enemy half | 89.9 | 89.9 | 0.0 % | 18.0 | 19.5 | 92.3-94.5 |
| bridge_road_n | crossing bridge_road | own half | 93.2 | 93.2 | 0.0 % | 18.6 | 20.3 | 96.7-99.3 |
| tower_n | point | enemy half | 94.0 | 94.0 | 0.0 % | 18.8 | 20.4 | 95.5-96.5 |
| camp_hollow_se | camp | enemy half | 94.7 | 94.7 | 0.0 % | 18.9 | 20.6 | 96.2-98.8 |
| camp_hollow_nw | camp | own half | 94.7 | 94.7 | 0.0 % | 18.9 | 20.6 | 96.1-98.6 |
| lair_den_w | lair | own half | 94.8 | 94.8 | 0.0 % | 19.0 | 20.6 | 97.0-99.5 |
| lair_hollow_e | lair | enemy half | 97.2 | 97.2 | 0.0 % | 19.4 | 21.1 | 98.8-101.3 |
| lair_crag_e | lair | enemy half | 98.6 | 98.6 | 0.0 % | 19.7 | 21.4 | 96.1-97.9 |
| lantern_wharf | post | enemy half | 100.9 | 100.9 | 0.0 % | 20.2 | 21.9 | 105.1-107.1 |
| saltgate | post | enemy half | 101.4 | 101.4 | 0.0 % | 20.3 | 22.0 | 99.8-103.2 |
| lair_heath_e | lair | enemy half | 108.3 | 108.3 | 0.0 % | 21.7 | 23.5 | 112.9-113.1 |
| node_shadow_a | node | enemy half | 109.6 | 109.6 | 0.0 % | 21.9 | 23.8 | 113.4-113.6 |
| node_shadow_b | node | enemy half | 110.2 | 110.2 | 0.0 % | 22.0 | 23.9 | 116.6-116.7 |
| keep_t1 | keep | enemy half | 111.8 | 111.8 | 0.0 % | 22.4 | 24.3 | 116.0-116.0 |
| camp_wallow_n | camp | enemy half | 114.8 | 114.8 | 0.0 % | 23.0 | 24.9 | 113.6-117.2 |

## Contest per spot (nearest seat of each side, m; contested = sides within 15 %)

| Spot | Kind | nearest side 0 | m | nearest side 1 | m | ratio 0/1 | |
|---|---|---|---|---|---|---|---|
| GreywaterLodgeNorthWest | guild | a1 | 89.5 | b1 | 80.9 | 1.11 | contested |
| GreywaterLodgeSouthEast | guild | a1 | 80.9 | b1 | 89.5 | 0.90 | contested |
| LostCache0 | cache | a1 | 39.9 | b1 | 81.8 | 0.49 |  |
| LostCache1 | cache | a1 | 34.6 | b1 | 83.7 | 0.41 |  |
| LostCache2 | cache | a1 | 81.8 | b1 | 39.9 | 2.05 |  |
| LostCache3 | cache | a1 | 83.7 | b1 | 34.6 | 2.42 |  |
| MagpieDenNorthWest | guild | a1 | 80.9 | b1 | 89.9 | 0.90 | contested |
| MagpieDenSouthEast | guild | a1 | 89.9 | b1 | 80.9 | 1.11 | contested |
| RuinPeddlerFire | peddler | a1 | 62.2 | b1 | 67.9 | 0.92 | contested |
| RuinPeddlerShadow | peddler | a1 | 67.9 | b1 | 62.2 | 1.09 | contested |
| TavernFire | tavern | a1 | 55.0 | b1 | 62.7 | 0.88 | contested |
| TavernShadow | tavern | a1 | 62.7 | b1 | 55.0 | 1.14 | contested |
| camp_hollow_nw | camp | a1 | 94.7 | b1 | 94.7 | 1.00 | contested |
| camp_hollow_se | camp | a1 | 94.7 | b1 | 94.7 | 1.00 | contested |
| camp_nest_n | camp | a1 | 80.9 | b1 | 48.6 | 1.66 |  |
| camp_nest_s | camp | a1 | 48.6 | b1 | 80.9 | 0.60 |  |
| camp_stag_e | camp | a1 | 86.8 | b1 | 48.4 | 1.79 |  |
| camp_stag_w | camp | a1 | 48.4 | b1 | 86.8 | 0.56 |  |
| camp_wallow_n | camp | a1 | 114.8 | b1 | 26.1 | 4.39 |  |
| camp_wallow_s | camp | a1 | 26.1 | b1 | 114.8 | 0.23 |  |
| crown | crown | a1 | 53.7 | b1 | 53.7 | 1.00 | contested |
| heron_ford | post | a1 | 34.4 | b1 | 100.9 | 0.34 |  |
| lair_crag_e | lair | a1 | 98.6 | b1 | 57.2 | 1.72 |  |
| lair_crag_w | lair | a1 | 57.2 | b1 | 98.6 | 0.58 |  |
| lair_den_e | lair | a1 | 65.4 | b1 | 94.8 | 0.69 |  |
| lair_den_w | lair | a1 | 94.8 | b1 | 65.4 | 1.45 |  |
| lair_heath_e | lair | a1 | 108.3 | b1 | 26.2 | 4.14 |  |
| lair_heath_w | lair | a1 | 26.2 | b1 | 108.3 | 0.24 |  |
| lair_hollow_e | lair | a1 | 97.2 | b1 | 73.9 | 1.32 |  |
| lair_hollow_w | lair | a1 | 73.9 | b1 | 97.2 | 0.76 |  |
| lantern_wharf | post | a1 | 100.9 | b1 | 34.4 | 2.93 |  |
| millstone_cross | post | a1 | 34.4 | b1 | 101.4 | 0.34 |  |
| node_fire_a | node | a1 | 2.0 | b1 | 109.6 | 0.02 |  |
| node_fire_b | node | a1 | 2.5 | b1 | 110.2 | 0.02 |  |
| node_fire_mid | node | a1 | 37.4 | b1 | 71.0 | 0.53 |  |
| node_fire_rich | node | a1 | 76.1 | b1 | 77.7 | 0.98 | contested |
| node_shadow_a | node | a1 | 109.6 | b1 | 2.0 | 54.78 |  |
| node_shadow_b | node | a1 | 110.2 | b1 | 2.5 | 44.06 |  |
| node_shadow_mid | node | a1 | 71.0 | b1 | 37.4 | 1.90 |  |
| node_shadow_rich | node | a1 | 77.7 | b1 | 76.1 | 1.02 | contested |
| saltgate | post | a1 | 101.4 | b1 | 34.4 | 2.94 |  |
| shrine_e | point | a1 | 72.0 | b1 | 47.8 | 1.51 |  |
| shrine_w | point | a1 | 47.8 | b1 | 72.0 | 0.66 |  |
| tower_n | point | a1 | 94.0 | b1 | 29.5 | 3.19 |  |
| tower_nw | point | a1 | 79.6 | b1 | 60.8 | 1.31 |  |
| tower_s | point | a1 | 29.5 | b1 | 94.0 | 0.31 |  |
| tower_se | point | a1 | 60.8 | b1 | 79.6 | 0.76 |  |
| well_e | point | a1 | 72.0 | b1 | 61.8 | 1.17 |  |
| well_w | point | a1 | 61.8 | b1 | 72.0 | 0.86 |  |

59 targets, 2 seats, 3.9 s.

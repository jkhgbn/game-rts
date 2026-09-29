# Art Lab calibration run

2026-09-29 00:27:30, lab v3.1, headless, 13 cases in 1 s. Bands: tools/art_lab/calibration/calibration.gd; manual: docs/plan/art-lab.md "Calibration".

| case | plant | result | quality | band | WARN / FAIL | verdict |
|---|---|---|---|---|---|---|
| shade | - | WARN | 93.6 | 91-100 | WARN B9m | OUT: new WARN B9m: 1 mesh(es) per instance |
| dusk_steed | - | PASS | 97.0 | 92-100 |  | in band |
| aqueduct | - | PASS | 99.2 | 95-100 |  | in band |
| fire_gun_vfx | - | PASS | 100.0 | 90-100 |  | in band |
| deer | - | PASS | 99.0 | 95-100 |  | in band |
| frost_dragon | - | PASS | 98.6 | 95-100 |  | in band |
| vinelasher_low | - | PASS | 86.9 | 82-91 |  | in band |
| plant_green_shade | green | WARN | 93.1 | 77-88 | WARN B9m | OUT: new WARN B9m: 1 mesh(es) per instance |
| plant_glow40_frost_dragon | glow40 | PASS | 98.8 | 89-95 |  | in band |
| plant_verts20k_shade | verts20k | WARN | 93.1 | 87-98 | WARN B9m | OUT: B4 PASS (expected FAIL): 1786 (biggest: Face 497, Merged 295, Merged 253, Merged 229); new WARN B9m: 1 mesh(es) per instance |
| plant_float_deer | float | FAIL | 87.9 | 87-94 | FAIL R9 | in band |
| plant_permat_dusk_steed | permat | FAIL | 89.5 | 86-92 | FAIL B9 | in band |
| plant_team_dusk_steed | team | PASS | 97.0 | 88-97 |  | in band |

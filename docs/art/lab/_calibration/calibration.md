# Art Lab calibration run

2026-09-30 18:39:12, lab v3.1, windowed, 13 cases in 225 s. Bands: tools/art_lab/calibration/calibration.gd; manual: docs/plan/art-lab.md "Calibration".

| case | plant | result | quality | band | WARN / FAIL | verdict |
|---|---|---|---|---|---|---|
| shade | - | WARN | 94.8 | 91-100 | WARN R5 | in band |
| dusk_steed | - | PASS | 94.9 | 92-100 |  | in band |
| aqueduct | - | PASS | 98.2 | 95-100 |  | in band |
| fire_gun_vfx | - | PASS | 100.0 | 90-100 |  | in band |
| deer | - | WARN | 81.2 | 95-100 | WARN R4 | OUT: quality 81.2 outside [95, 100]; new WARN R4: worst snow: dE 5.3 (heath dE 35.3, old_wood dE 57.4, riverbank dE 57.0, snow dE 5.3, ash d |
| frost_dragon | - | PASS | 97.2 | 95-100 |  | in band |
| vinelasher_low | - | WARN | 90.6 | 82-91 | WARN R6cb | OUT: new WARN R6cb: worst pair fire / nature (deutan): dE 11.6 on the team-colour area (normal vision 63.0; 12 |
| plant_green_shade | green | WARN | 82.2 | 77-88 | WARN R3, WARN R6, WARN R3t, WARN R5 | OUT: R3 WARN (expected FAIL): mean-colour dE 10.0, 37% of the body melts (within dE 15 of the ground); body L* 70.9 C 54 |
| plant_glow40_frost_dragon | glow40 | WARN | 94.0 | 89-95 | WARN R5, WARN R5w | in band |
| plant_verts20k_shade | verts20k | FAIL | 91.7 | 87-98 | FAIL B4 | in band |
| plant_float_deer | float | FAIL | 76.8 | 87-94 | FAIL R9, WARN R4 | OUT: quality 76.8 outside [87, 94]; new WARN R4: worst snow: dE 5.3 (heath dE 35.0, old_wood dE 57.0, riverbank dE 55.1, snow dE 5.3, ash d |
| plant_permat_dusk_steed | permat | FAIL | 89.6 | 86-92 | FAIL B9 | in band |
| plant_team_dusk_steed | team | FAIL | 91.0 | 88-97 | FAIL R6 | in band |

# Map gate: thornwater

**FAIL** (G5 FAIL, G6 SKIP)

| # | Gate | Result | Measured | Rule |
|---|---|---|---|---|
| G1 | World Forge map | PASS | WARN 98 / 100; R5 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 49 spots ok, 1.00x ok | exit 0 (PASS / WARN), L1 / L2 / N0 / R5 not FAIL |
| G2 | Map Lab | PASS | WARN 96 / 100, 0 FAIL check(s) | score >= 75 and 0 FAIL (map-production.md 9) |
| G3 | Spacing | PASS | L3 PASS (ok); R4 WARN (45 / 49 clean (0 FAIL, 4 WARN)) | >= 3 m between spots, >= 6 m between structures; R4 clearances not FAIL |
| G4 | Symmetry / fairness | PASS | N2 PASS, M1 PASS, M2 PASS, M3 PASS, M4 PASS, F1 PASS, D1 WARN, T1 PASS, C1 PASS, C2 PASS | Map Lab N2, M1-M4, F1, D1, T1, C1, C2 (A1 on team maps) not FAIL |
| G5 | Bot fairness | FAIL | 40 games (40 decided): easy 8 / 12 = 67 %; normal 5 / 16 = 31 %; hard 3 / 12 = 25 % / easy seat rate 67 %, normal seat rate 31 %, hard seat rate 25 % | seat win rate 45-55 % per difficulty, no cell > 65 % (>= 8 games), 0 script errors, every game ends |
| G6 | Performance | SKIP | not run | test_mt2_perf.gd prints PASS mt2_perf |
| G7 | Load (info) | INFO | startup 8.3 s, bake 6.1 s (Bot Lab medians, sim mode, headless) | first bake <= 5 s, load to playable <= 10 s (desktop, windowed: lead check) |

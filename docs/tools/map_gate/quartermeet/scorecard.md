# Map gate: quartermeet

**PARTIAL** (G5 SKIP)

| # | Gate | Result | Measured | Rule |
|---|---|---|---|---|
| G1 | World Forge map | PASS | WARN 98 / 100; R5 1 half widths ok, 2 arms ok, 2 circles ok, 2 segments ok, 176 x 176 m ok, 91 spots ok, 2.15x ok | exit 0 (PASS / WARN), L1 / L2 / N0 / R5 not FAIL |
| G2 | Map Lab | PASS | WARN 96 / 100, 0 FAIL check(s) | score >= 75 and 0 FAIL (map-production.md 9) |
| G3 | Spacing | PASS | L3 PASS (ok); R4 WARN (83 / 91 clean (0 FAIL, 8 WARN)) | >= 3 m between spots, >= 6 m between structures; R4 clearances not FAIL |
| G4 | Symmetry / fairness | PASS | N2 PASS, M1 PASS, M2 PASS, M3 PASS, M4 PASS, F1 PASS, D1 PASS, T1 WARN, C1 PASS, C2 WARN, A1 PASS | Map Lab N2, M1-M4, F1, D1, T1, C1, C2 (A1 on team maps) not FAIL |
| G5 | Bot fairness | SKIP | no Bot Lab games | 45-55 % seat win rate per difficulty |
| G6 | Performance | PASS | skirmish.gd: 10.07 ms/frame, 100 arrived, 0 stuck (MapInfo 120 x 120); layout_level.gd: 11.38 ms/frame, 100 arrived, 0 stuck (MapInfo 176 x 176); note: 11.38 ms/frame is over perf_test.gd's 8.0 ms main.tscn budget (the full skirmish costs more; the gate is the live reference) | frame time within live Crown Hollow's (+15 % + 0.5 ms), no stuck unit |
| G7 | Load (info) | INFO | no Bot Lab games | first bake <= 5 s, load to playable <= 10 s (desktop, windowed: lead check) |

# Map gate: thornwater

**FAIL** (G5 FAIL)

| # | Gate | Result | Measured | Rule |
|---|---|---|---|---|
| G1 | World Forge map | PASS | WARN 98 / 100; R5 1 half widths ok, 2 arms ok, 4 circles ok, 10 segments ok, 120 x 120 m ok, 49 spots ok, 1.00x ok | exit 0 (PASS / WARN), L1 / L2 / N0 / R5 not FAIL |
| G2 | Map Lab | PASS | WARN 96 / 100, 0 FAIL check(s) | score >= 75 and 0 FAIL (map-production.md 9) |
| G3 | Spacing | PASS | L3 PASS (ok); R4 WARN (45 / 49 clean (0 FAIL, 4 WARN)) | >= 3 m between spots, >= 6 m between structures; R4 clearances not FAIL |
| G4 | Symmetry / fairness | PASS | N2 PASS, M1 PASS, M2 PASS, M3 PASS, M4 PASS, F1 PASS, D1 WARN, T1 PASS, C1 PASS, C2 PASS | Map Lab N2, M1-M4, F1, D1, T1, C1, C2 (A1 on team maps) not FAIL |
| G5 | Bot fairness | FAIL | 123 games (123 decided): easy 20 / 40 = 50 %; normal 15 / 40 = 38 %; hard 13 / 43 = 30 % / normal seat rate 38 %, hard seat rate 30 %, cell easy ice 80 %, cell easy nature 30 %, cell normal fire 10 %, cell hard fire 25 %, cell hard nature 30 %, cell hard ice 30 % | seat win rate 45-55 % per difficulty, no cell > 65 % (>= 8 games), 0 script errors, every game ends |
| G6 | Performance | PASS | skirmish.gd: 8.25 ms/frame, 100 arrived, 0 stuck (MapInfo 120 x 120); layout_level.gd: 8.03 ms/frame, 100 arrived, 0 stuck (MapInfo 120 x 120); note: 8.03 ms/frame is over perf_test.gd's 8.0 ms main.tscn budget (the full skirmish costs more; the gate is the live reference) | frame time within live Crown Hollow's (+15 % + 0.5 ms), no stuck unit |
| G7 | Load (info) | INFO | startup 7.3 s, bake 5.2 s (Bot Lab medians, sim mode, headless) | first bake <= 5 s, load to playable <= 10 s (desktop, windowed: lead check) |

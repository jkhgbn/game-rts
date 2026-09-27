# Usage log

After every session the lead reads the plan limits (`get_usage`) and adds a line. After two sessions you'll know
what one task point really costs, and can fix the budget table in `waves.md`. The week resets Saturday ~1 AM.

| Date | Wave / session | Agents run | Points done | Weekly all-models % (before -> after) | Weekly Fable % | 5-hour session % peak | Notes |
|---|---|---|---|---|---|---|---|
| 2026-09-25 | 1 design day (other chat) | game-designer | 5 | ? -> 8 | 2 | ? | Week almost over; not a full-week sample |
| 2026-09-25 | 0 setup | lead only | - | 8 -> 9 | 2 | 58 | Plan v2, smoke fix, perf test, agent files |
| 2026-09-25 | 1 A+B+C (whole wave in one evening) | gameplay, ui x2, systems, designer x2 | 17 code + 5 design + 4 spec rewrite | 9 -> 11 | 2 -> 4 | 74 | ~0.1% per point, far under the 1.7% guess. The 5-hour meter is the real limit, not the weekly one |
| 2026-09-25 | 2 (1v1 vs bot) + fixes + specs (1v1, levels, items, art) | systems x3, gameplay x2, ui x3, ai, designer x5 | ~25 code + 5 specs | 11 -> 17 | 4 -> 10 | 74 then 15 -> 46 | Bot task alone took 36 min (long match tests) |
| 2026-09-25 | 3 step A (6 agents in parallel) | gameplay x3, ui, tech-artist x2 | 6 tasks | 17 -> 19 | 10 | 46 -> 57 | Every agent ≤ 11 min; step done in ~25 min incl. integration. ~11 % of the 5-hour meter per 6-agent step |

**Cost per point** = (weekly % after - weekly % before) / points done.
If it's much higher than about 1.7% per point, lower the effort or move tasks out of the wave.
| 2026-09-26 | Step 9 champions + art day | 15 + 10 art + 2 phase-2 + helpers | 9.D3, 9.C1-9.C11, 9.V1-9.V6, A2.1-A2.10 | 19 -> 32 | 2 -> 4 | 2 -> 50 | 20 agents at once ~ +16 %/h weekly; ~0.6 % weekly per agent overall |

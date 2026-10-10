"""Blitz report (docs/balance/blitz_2026-10-10.md): the Blitz targets per arm x level for runs of run_fg.py.

  python tools/balance_lab/faster_games/blitz_report.py --run bz1cr --run bz1tw [--map-of bz1tw=thornwater]

Targets: median length 8-12 min (normal, hard), each kingdom 35-65 % wins, ends before 5:00 < 10 %, first attacker
wins < ~70 %. Columns: N, median, p25-p75, < 5:00, < 8:00, > 15:00, end reasons, kingdom win %, spread, first attacker
wins, first attack (median). Times are REAL time: game time / the arm's Blitz game_speed (Engine.time_scale).
"""
import argparse
import os
import statistics as st
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(__file__))
from fg_report import KINGDOMS, clock, load, q  # noqa: E402


def speed(r):
	b = ((r.get("fg") or {}).get("blitz") or {})
	return float((b.get("tuning") or {}).get("game_speed", 1.0)) if b.get("on") else 1.0


def first_attacker(r):
	fa = [float(((r.get("stats") or {}).get(sd) or {}).get("first_attack", -1)) for sd in ("player", "enemy")]
	if max(fa) < 0:
		return None, None
	t = 0 if (fa[1] < 0 or (0 <= fa[0] <= fa[1])) else 1
	return t, fa[t]


def row(label, rs):
	n = len(rs)
	t = [float(r["end_time"]) / speed(r) for r in rs]   # REAL minutes (game time / Blitz game_speed)
	wins = defaultdict(lambda: [0, 0])
	reasons = defaultdict(int)
	fa_n = fa_w = 0
	fa_t = []
	for r in rs:
		w = r.get("winner_team", -1)
		reasons[r["end_reason"]] += 1
		for team, k in ((0, r["player"]), (1, r["enemy"])):
			wins[k][1] += 1
			wins[k][0] += (w == team)
		ft, ftime = first_attacker(r)
		if ft is not None and w in (0, 1):
			fa_n += 1
			fa_w += (w == ft)
			fa_t.append(ftime / speed(r))
	kv = [100.0 * wins[k][0] / wins[k][1] for k in KINGDOMS if wins[k][1]]
	kw = "/".join(f"{100.0 * wins[k][0] / wins[k][1]:.0f}" if wins[k][1] else "-" for k in KINGDOMS)
	rs_txt = ", ".join(f"{k} {v}" for k, v in sorted(reasons.items()))
	return (f"| {label} | {n} | **{clock(st.median(t))}** | {clock(q(t, .25))}-{clock(q(t, .75))} | "
		f"{sum(x < 300 for x in t)} ({100.0 * sum(x < 300 for x in t) / n:.0f} %) | {sum(x < 480 for x in t)} | "
		f"{sum(x > 900 for x in t)} | {kw} | {(max(kv) - min(kv)) if kv else 0:.0f} | "
		f"{(100.0 * fa_w / fa_n) if fa_n else 0:.0f} % ({fa_w}/{fa_n}) | {clock(st.median(fa_t)) if fa_t else '-'} | {rs_txt} |")


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("--run", action="append", required=True)
	a = ap.parse_args()
	print("| Arm / level / run | N | Median | p25-p75 | < 5:00 | < 8:00 | > 15:00 | Win % F/S/I/N | Spread | 1st attacker wins | 1st attack | Ends |")
	print("|---|---|---|---|---|---|---|---|---|---|---|---|")
	for run in a.run:
		rows = load([run])
		groups = defaultdict(list)
		for r in rows:
			groups[(r["_arm"], r["_level"])].append(r)
		for (arm, lv), rs in sorted(groups.items()):
			print(row(f"{arm} / {lv} / {run}", rs))
	if len(a.run) > 1:
		rows = load(a.run)
		groups = defaultdict(list)
		for r in rows:
			groups[(r["_arm"], r["_level"])].append(r)
		for (arm, lv), rs in sorted(groups.items()):
			print(row(f"**{arm} / {lv} / all maps**", rs))


if __name__ == "__main__":
	main()

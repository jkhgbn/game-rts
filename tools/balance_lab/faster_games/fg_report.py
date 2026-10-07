"""Faster-games report: reads ..\\four-wizards-lab-runs\\fg-<run>\\*.json (tools/balance_lab/faster_games/run_fg.py)
and prints Markdown tables per arm x bot level: match length, end reasons, win spread (kingdom, seat), building-kill
times, siege use. --json writes the numbers too.

  python tools/balance_lab/faster_games/fg_report.py --run fg1 [--run fg2 ...] [--json out.json]
"""
import argparse
import glob
import json
import os
import statistics as st
from collections import defaultdict

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
KINGDOMS = ["fire", "shadow", "ice", "nature"]
LEVELS = ["easy", "normal", "hard"]


def clock(s):
	if s is None:
		return "-"
	s = int(round(s))
	return f"{s // 60}:{s % 60:02d}"


def pct(a, b):
	return f"{100.0 * a / b:.0f} %" if b else "-"


def q(vals, p):
	if not vals:
		return None
	v = sorted(vals)
	k = (len(v) - 1) * p
	f = int(k)
	c = min(f + 1, len(v) - 1)
	return v[f] + (v[c] - v[f]) * (k - f)


def mwu_p(xs, ys):
	import math
	allv = sorted([(v, 0) for v in xs] + [(v, 1) for v in ys])
	ranks = {}
	i = 0
	while i < len(allv):
		j = i
		while j < len(allv) and allv[j][0] == allv[i][0]:
			j += 1
		for k in range(i, j):
			ranks.setdefault(k, (i + j + 1) / 2.0)
		i = j
	r1 = sum(ranks[k] for k, (v, g) in enumerate(allv) if g == 0)
	n1, n2 = len(xs), len(ys)
	u = r1 - n1 * (n1 + 1) / 2.0
	mu = n1 * n2 / 2.0
	sd = math.sqrt(n1 * n2 * (n1 + n2 + 1) / 12.0)
	z = (u - mu) / sd if sd else 0.0
	return math.erfc(abs(z) / math.sqrt(2))


def load(runs):
	rows = []
	for run in runs:
		d = os.path.join(os.path.dirname(REPO), "four-wizards-lab-runs", "fg-" + run)
		for path in glob.glob(os.path.join(d, "*.json")):
			base = os.path.basename(path)[:-5]
			parts = base.split("__")
			if len(parts) != 4:
				continue
			try:
				with open(path, encoding="utf-8") as f:
					r = json.loads(f.readline())
			except Exception:
				continue
			if "end_time" not in r:   # a skipped job (placeholder line, see run_fg.py resume)
				continue
			if r.get("end_reason") in ("error", "bad layout", "cap"):   # no game was played: rerun it
				print(f"skipped (no game): {path} {r.get('error', '')}")
				continue
			r["_arm"], r["_level"] = parts[0], parts[1]
			rows.append(r)
	return rows


def cell_stats(rs):
	n = len(rs)
	t = [float(r["end_time"]) for r in rs]
	reasons = defaultdict(int)
	for r in rs:
		reasons[r["end_reason"]] += 1
	wins = defaultdict(lambda: [0, 0])     # kingdom -> [wins, games]
	seat = [0, 0]                          # player-side wins, decided games
	cells = defaultdict(lambda: [0, 0])    # (kingdom, side) -> [wins, games]
	first_b, first_t, first_p, lost_loser = [], [], [], []
	none_b = 0
	siege_n, siege_dmg = [], []
	for r in rs:
		w = r.get("winner_team", -1)
		for team, side, k in [(0, "player", r["player"]), (1, "enemy", r["enemy"])]:
			wins[k][1] += 1
			cells[(k, side)][1] += 1
			if w == team:
				wins[k][0] += 1
				cells[(k, side)][0] += 1
		if w in (0, 1):
			seat[1] += 1
			if w == 0:
				seat[0] += 1
		fg = (r.get("fg") or {}).get("sides", {})
		fb = [s["first_building_lost"] for s in fg.values() if s.get("first_building_lost", -1) >= 0]
		ft = [s["first_tower_lost"] for s in fg.values() if s.get("first_tower_lost", -1) >= 0]
		fp = [s["first_production_lost"] for s in fg.values() if s.get("first_production_lost", -1) >= 0]
		if fb:
			first_b.append(min(fb))
		else:
			none_b += 1
		if ft:
			first_t.append(min(ft))
		if fp:
			first_p.append(min(fp))
		if w in (0, 1) and fg:
			loser = fg.get("enemy" if w == 0 else "player", {})
			lost_loser.append(loser.get("buildings_lost", 0))
		for s in fg.values():
			siege_n.append(sum((s.get("siege_units") or {}).values()))
			siege_dmg.append(s.get("siege_building_dmg", 0))
	kw = {k: (wins[k][0] / wins[k][1] if wins[k][1] else None) for k in KINGDOMS}
	kv = [v for v in kw.values() if v is not None]
	return {
		"n": n, "median": q(t, 0.5), "p25": q(t, 0.25), "p75": q(t, 0.75), "p90": q(t, 0.9),
		"mean": st.mean(t) if t else None,
		"reasons": dict(reasons),
		"decisive": (reasons["kill"] + reasons["concede"]) / n if n else None,
		"kingdom_win": kw, "spread": (max(kv) - min(kv)) if kv else None,
		"seat_player": seat[0] / seat[1] if seat[1] else None,
		"cells": {f"{k}/{s}": v for (k, s), v in cells.items()},
		"first_building": q(first_b, 0.5), "no_building_lost": none_b,
		"first_tower": q(first_t, 0.5), "first_production": q(first_p, 0.5),
		"loser_buildings_lost": st.mean(lost_loser) if lost_loser else None,
		"siege_units_per_side": st.mean(siege_n) if siege_n else 0, "siege_dmg_per_side": st.mean(siege_dmg) if siege_dmg else 0,
		"times": t,
	}


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("--run", action="append", required=True)
	ap.add_argument("--json", default="")
	a = ap.parse_args()
	rows = load(a.run)
	arms = sorted({r["_arm"] for r in rows}, key=lambda x: (x != "baseline", x))
	levels = [lv for lv in LEVELS if any(r["_level"] == lv for r in rows)] + ["all"]
	out = {}
	print(f"{len(rows)} matches, runs {', '.join(a.run)}\n")
	print("| Arm | Level | N | Median | p25-p75 | p90 | Kill / concede | Early-score | Time-score | Kingdom win % F/S/I/N | Spread | Player seat | 1st building lost | 1st tower | 1st production | Loser bldgs lost | Siege units / side |")
	print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
	for arm in arms:
		for lv in levels:
			rs = [r for r in rows if r["_arm"] == arm and (lv == "all" or r["_level"] == lv)]
			if not rs:
				continue
			c = cell_stats(rs)
			out[f"{arm}/{lv}"] = {k: v for k, v in c.items() if k != "times"}
			kw = "/".join(f"{100 * c['kingdom_win'][k]:.0f}" if c["kingdom_win"][k] is not None else "-" for k in KINGDOMS)
			rsn = c["reasons"]
			print(f"| {arm} | {lv} | {c['n']} | **{clock(c['median'])}** | {clock(c['p25'])}-{clock(c['p75'])} | {clock(c['p90'])} | "
				f"{pct(rsn.get('kill', 0) + rsn.get('concede', 0), c['n'])} | {pct(rsn.get('early-score', 0), c['n'])} | "
				f"{pct(rsn.get('time-score', 0), c['n'])} | {kw} | {100 * c['spread']:.0f} | {100 * c['seat_player']:.0f} % | "
				f"{clock(c['first_building'])} | {clock(c['first_tower'])} | {clock(c['first_production'])} | "
				f"{c['loser_buildings_lost']:.1f} | {c['siege_units_per_side']:.1f} |")
	# kingdom x seat cells per level (wins-games)
	print("\n## Cells (wins-games): kingdom / seat")
	for lv in levels[:-1]:
		print(f"\n### {lv}\n")
		print("| Arm | " + " | ".join(f"{k} P | {k} E" for k in KINGDOMS) + " |")
		print("|---|" + "---|" * 8)
		for arm in arms:
			c = out.get(f"{arm}/{lv}")
			if not c:
				continue
			cells = c["cells"]
			print(f"| {arm} | " + " | ".join(
				"%d-%d" % tuple(cells.get(f"{k}/{s}", [0, 0])) for k in KINGDOMS for s in ("player", "enemy")) + " |")
	# median length per kingdom (games it played)
	print("\n## Median length per kingdom (all levels)\n")
	print("| Arm | " + " | ".join(KINGDOMS) + " |")
	print("|---|---|---|---|---|")
	for arm in arms:
		cols = []
		for k in KINGDOMS:
			t = [float(r["end_time"]) for r in rows if r["_arm"] == arm and k in (r["player"], r["enemy"])]
			cols.append(clock(q(t, 0.5)))
		print(f"| {arm} | " + " | ".join(cols) + " |")
	# median change vs baseline, same level: bootstrap 90 % interval (2000 resamples, fixed seed) + Mann-Whitney p
	import random
	rng = random.Random(7)
	print("\n## Median length vs baseline (same level)\n")
	print("| Arm | Level | N arm / base | Median change | 90 % interval | Mann-Whitney p (two-sided, normal approx.) |")
	print("|---|---|---|---|---|---|")
	for lv in levels[:-1]:
		base = [float(r["end_time"]) for r in rows if r["_arm"] == "baseline" and r["_level"] == lv]
		if not base:
			continue
		for arm in arms:
			if arm == "baseline":
				continue
			xs = [float(r["end_time"]) for r in rows if r["_arm"] == arm and r["_level"] == lv]
			if not xs:
				continue
			d0 = q(xs, 0.5) - q(base, 0.5)
			ds = sorted(q([rng.choice(xs) for _ in xs], 0.5) - q([rng.choice(base) for _ in base], 0.5) for _ in range(2000))
			lo, hi = ds[100], ds[1899]
			print(f"| {arm} | {lv} | {len(xs)} / {len(base)} | {'+' if d0 >= 0 else '-'}{clock(abs(d0))} | "
				f"{'+' if lo >= 0 else '-'}{clock(abs(lo))} .. {'+' if hi >= 0 else '-'}{clock(abs(hi))} | {mwu_p(xs, base):.3f} |")
	if a.json:
		with open(a.json, "w", encoding="utf-8") as f:
			json.dump(out, f, indent=1)


if __name__ == "__main__":
	main()

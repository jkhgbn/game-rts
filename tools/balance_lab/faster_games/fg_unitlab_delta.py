"""Faster-games experiment B: Unit Lab matrix deltas (docs/balance/faster_games_2026-10-06.md).

Merges the applied final matrix (..\\four-wizards-lab-runs\\unit-lab-final_matrix_t1t2[_pop]) with the focus run of the
two lab siege units (unit-lab-fg_b_siege_cost|pop, tools/balance_lab/faster_games/fg_unit_lab_run.gd) and prints, per
entry, the mean score (unit_lab_report.gd matrix_table: mean over opponents of the pair score, win 1 / draw 0.5)
before (47 entries) and after (49 entries), plus the two new rows.

  python tools/balance_lab/faster_games/fg_unitlab_delta.py
"""
import glob
import json
import os
from collections import defaultdict

RAW = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "four-wizards-lab-runs")
NEW = ["grave_mangonel", "stoneroot_hurler"]


def lines(folder):
	out = []
	for p in glob.glob(os.path.join(RAW, folder, "*.jsonl")):
		with open(p, encoding="utf-8") as f:
			for ln in f:
				ln = ln.strip()
				if ln.startswith("{"):
					out.append(json.loads(ln))
	return out


def score_a(r):
	w = r.get("winner", "")
	return 1.0 if w == "a" else 0.0 if w == "b" else 0.5


def means(rows, exclude=()):
	cells = defaultdict(lambda: [0, 0.0])
	ents = set()
	for r in rows:
		a, b = r.get("entry_a"), r.get("entry_b")
		if not a or not b:
			continue
		ents |= {a, b}
		s = score_a(r)
		cells[(a, b)][0] += 1
		cells[(a, b)][1] += s
		if a != b:
			cells[(b, a)][0] += 1
			cells[(b, a)][1] += 1 - s
	out = {}
	for e in ents:
		vals = [cells[(e, o)][1] / cells[(e, o)][0] for o in ents if o != e and o not in exclude and cells[(e, o)][0]]
		out[e] = sum(vals) / len(vals) if vals else float("nan")
	return out


def main():
	for basis, base_dir in [("cost", "unit-lab-final_matrix_t1t2"), ("pop", "unit-lab-final_matrix_t1t2_pop")]:
		base = lines(base_dir)
		new = lines("unit-lab-fg_b_siege_" + basis)
		if not new:
			print(f"## {basis}: no focus run yet")
			continue
		before = means(base)
		after = means(base + new)
		print(f"\n## basis {basis}: {len(base)} + {len(new)} fights")
		for e in NEW:
			if e in after:
				vs = defaultdict(lambda: [0, 0.0])
				for r in new:
					if r.get("entry_a") == e:
						vs[r["entry_b"]][0] += 1
						vs[r["entry_b"]][1] += score_a(r)
					elif r.get("entry_b") == e:
						vs[r["entry_a"]][0] += 1
						vs[r["entry_a"]][1] += 1 - score_a(r)
				wins = sorted(((v[1] / v[0], o) for o, v in vs.items() if v[0]), reverse=True)
				print(f"{e}: mean {100 * after[e]:.0f}; beats (>=0.75): {[o for s, o in wins if s >= 0.75]}")
		deltas = sorted(((100 * (after[e] - before[e]), e) for e in before if e in after), key=lambda x: x[0])
		mx = max(abs(d) for d, _ in deltas)
		print(f"existing entries: max |delta| {mx:.1f} points; biggest: " +
			", ".join(f"{e} {before[e] * 100:.0f}->{after[e] * 100:.0f}" for d, e in sorted(deltas, key=lambda x: -abs(x[0]))[:6]))
		flips = [e for e in before if e in after and ((before[e] >= 0.7) != (after[e] >= 0.7) or (before[e] <= 0.3) != (after[e] <= 0.3))]
		print(f"outlier-band flips (>=70 / <=30): {flips}")


if __name__ == "__main__":
	main()

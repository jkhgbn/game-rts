# Scores per entry from Unit Lab JSONL runs: T3 vs the other combat T3s (Ashveil Saboteur = spy, left out),
# T3 vs the T1/T2 field, T1/T2 vs the T1/T2 field. Usage: score.py <run dir glob> [variant]
import csv, glob, json, os, sys
from collections import defaultdict
HERE = os.path.dirname(os.path.abspath(__file__))
RUNS = os.path.normpath(os.path.join(HERE, "..", "..", "..", "..", "..", "..", "four-wizards-lab-runs"))
units = {r["entry"]: r for r in csv.DictReader(open(os.path.join(HERE, "..", "units.csv"), encoding="utf-8"))}
SPY = "ashveil_saboteur"
def cells(pattern, variant=None):
	c = defaultdict(lambda: [0.0, 0])
	for fp in glob.glob(os.path.join(RUNS, pattern, "*.jsonl")):
		for line in open(fp, encoding="utf-8"):
			if not line.strip():
				continue
			r = json.loads(line)
			if variant and r.get("variant") != variant:
				continue
			s = 1.0 if r["winner"] == "a" else (0.0 if r["winner"] == "b" else 0.5)
			a, b = r["entry_a"], r["entry_b"]
			c[(a, b)][0] += s; c[(a, b)][1] += 1; c[(b, a)][0] += 1 - s; c[(b, a)][1] += 1
	return c
def tier(e):
	return units[e]["tier"] if e in units else "?"
def score(c, e, field):
	opp = [o for o in field if o != e and c[(e, o)][1] > 0]
	if not opp:
		return None
	return 100 * sum(c[(e, o)][0] / c[(e, o)][1] for o in opp) / len(opp)
def table(c):
	ents = sorted({k[0] for k in c})
	t3 = [e for e in ents if tier(e) == "3" and e != SPY]
	t12 = [e for e in ents if tier(e) in ("1", "2")]
	out = {}
	for e in ents:
		if e == SPY:
			continue
		if tier(e) == "3":
			out[e] = (score(c, e, t3), score(c, e, t12))
		else:
			out[e] = (score(c, e, t12), None)
	return out
if __name__ == "__main__":
	c = cells(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
	for e, (a, b) in sorted(table(c).items(), key=lambda kv: (tier(kv[0]), kv[0])):
		print("%-28s T%s  field %5s  vsT12 %5s" % (e, tier(e), "-" if a is None else "%.0f" % a, "-" if b is None else "%.0f" % b))

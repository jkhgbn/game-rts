# Compares the suggested-change variant (validate/*) with the baseline matrix for the focus entries (judged field).
import csv, glob, json, os, sys
from collections import defaultdict
RUNS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "..", "..", "four-wizards-lab-runs")
units = {r["entry"]: r for r in csv.DictReader(open(os.path.join(os.path.dirname(__file__), "..", "units.csv"), encoding="utf-8"))}
def cells(pattern):
    c = defaultdict(lambda: [0.0, 0])
    for fp in glob.glob(os.path.join(RUNS, pattern, "*.jsonl")):
        for line in open(fp, encoding="utf-8"):
            if not line.strip():
                continue
            r = json.loads(line)
            s = 1.0 if r["winner"] == "a" else (0.0 if r["winner"] == "b" else 0.5)
            a, b = r["entry_a"], r["entry_b"]
            c[(a, b)][0] += s; c[(a, b)][1] += 1; c[(b, a)][0] += 1 - s; c[(b, a)][1] += 1
    return c
focus = json.load(open(os.path.join(os.path.dirname(__file__), "focus_cost.json")))["matrix"]["focus"]
print("entry,basis,before,after")
for basis, col in (("cost", "mean_crystals"), ("pop", "mean_pop")):
    v = cells("unit-lab-sheet_2026-10-11_val_" + basis)
    for e in focus:
        t3 = units[e]["tier"] == "3"
        opp = [o for o in units if o != e and (units[o]["tier"] == "3") == t3 and v[(e, o)][1] > 0]
        after = 100 * sum(v[(e, o)][0] / v[(e, o)][1] for o in opp) / len(opp)
        print("%s,%s,%s,%.0f" % (e, "crystals" if basis == "cost" else "pop", units[e][col], after))

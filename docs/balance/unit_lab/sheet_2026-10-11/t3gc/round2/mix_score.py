# Kingdom score in mix_line_check runs: mean of its 3 arms (win 1, draw 0.5). Usage: mix_score.py <run dir> [variant]
import glob, json, os, sys
from collections import defaultdict
RUNS = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), *[".."] * 7, "four-wizards-lab-runs"))
arms = defaultdict(lambda: [0.0, 0])
for fp in glob.glob(os.path.join(RUNS, sys.argv[1], "*.jsonl")):
	for line in open(fp, encoding="utf-8"):
		if not line.strip():
			continue
		r = json.loads(line)
		if len(sys.argv) > 2 and r.get("variant") != sys.argv[2]:
			continue
		s = 1.0 if r["winner"] == "a" else (0.0 if r["winner"] == "b" else 0.5)
		arms[r["arm"]][0] += s; arms[r["arm"]][1] += 1
k = defaultdict(list)
for arm, (s, n) in arms.items():
	a, b = arm.split(".")
	k[a].append(s / n); k[b].append(1 - s / n)
print("  ".join("%s %.0f" % (x, 100 * sum(v) / len(v)) for x, v in sorted(k.items())), "| games/arm", {a: n for a, (s, n) in arms.items()})

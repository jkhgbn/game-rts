# T1/T2 field scores after a focus A/B: the cells of the full "after" matrix, with every pair that holds a focus entry
# replaced by the variant's cells. Usage: focus_merge.py <after run glob> <focus run> <variant> <entry,entry,...> [show]
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import score
base = score.cells(sys.argv[1]); var = score.cells(sys.argv[2], sys.argv[3])
focus = set(sys.argv[4].split(","))
for k in list(base):
	if k[0] in focus or k[1] in focus:
		base[k] = var[k] if var[k][1] > 0 else [0.0, 0]
before = score.table(score.cells(sys.argv[1])); after = score.table(base)
show = sys.argv[5].split(",") if len(sys.argv) > 5 else sorted(focus)
for e in show:
	print("%-22s %s -> %s" % (e, "%.0f" % before[e][0], "%.0f" % after[e][0]))

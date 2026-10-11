# Round 2 sheet runs: unit-lab-t3gc_rnd2_<basis>/merged.jsonl = the full "after" matrix (seeds 1-6) without the pairs
# that hold a changed unit + the focus run on the written values (those pairs, seeds 1-6). Changed units only differ in
# their own pairs, so this equals a full re-run. Usage: merge_runs.py
import glob, json, os
RUNS = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), *[".."] * 7, "four-wizards-lab-runs"))
FOCUS = {"sunforge_cataphract", "briar_roc", "shardguard", "glade_outrider", "flame_guard", "hollow_oathsworn", "nightbolt"}
for b in ("cost", "pop", "both"):
	rows = []
	for fp in glob.glob(os.path.join(RUNS, "unit-lab-t3gc_after_" + b, "*.jsonl")):
		rows += [l for l in open(fp, encoding="utf-8") if l.strip() and not ({json.loads(l)["entry_a"], json.loads(l)["entry_b"]} & FOCUS)]
	kept = len(rows)
	for fp in glob.glob(os.path.join(RUNS, "unit-lab-t3gc_r2focus_" + b, "*.jsonl")):
		rows += [l for l in open(fp, encoding="utf-8") if l.strip()]
	out = os.path.join(RUNS, "unit-lab-t3gc_rnd2_" + b)
	os.makedirs(out, exist_ok=True)
	open(os.path.join(out, "merged.jsonl"), "w", encoding="utf-8", newline="\n").write("".join(r if r.endswith("\n") else r + "\n" for r in rows))
	print(b, "kept", kept, "new", len(rows) - kept)

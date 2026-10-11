# Before (sheet runs, baseline) vs after (a run family): judged-field scores per basis, T3 also vs the T1/T2 field.
# Usage: compare.py <after run prefix, e.g. unit-lab-t3gc_full_n_> [variant] [--csv out.csv]
import sys, score
pre = sys.argv[1]; var = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else None
out = sys.argv[sys.argv.index("--csv") + 1] if "--csv" in sys.argv else None
B = ["cost", "pop", "both"]
before = {b: score.table(score.cells("unit-lab-sheet_2026-10-11_" + b, "baseline")) for b in B}
after = {b: score.table(score.cells(pre + b + "*", var)) for b in B}
U = score.units
rows = []
for e in sorted(after["cost"], key=lambda e: (score.tier(e), U[e]["kingdom"], e)):
    ex = U[e]["exemption"]
    f = lambda d, b, i=0: d[b].get(e, (None, None))[i]
    r = [e, U[e]["tier"], ex] + [f(before, b) for b in B] + [f(after, b) for b in B]
    if score.tier(e) == "3":
        r += [f(before, b, 1) for b in B] + [f(after, b, 1) for b in B]
    rows.append(r)
fmt = lambda x: "-" if x is None else "%.0f" % x
for r in rows:
    flag = ""
    vals = r[6:9]
    if not r[2] or r[2].startswith("swarm"):
        judged = [vals[2]] if r[2].startswith("swarm") else vals[:2]
        if any(v is not None and (v > 70 or v < 30) for v in judged) and r[1] != "3":
            flag = " <-- out"
        if r[1] == "3" and any(v is not None and (v > 60 or v < 40) for v in vals):
            flag = " <-- t3 out"
    extra = ("  vsT12 %s/%s/%s -> %s/%s/%s" % tuple(fmt(x) for x in r[9:15])) if len(r) > 9 else ""
    print("%-24s T%s %-10s %4s/%4s/%4s -> %4s/%4s/%4s%s%s" % (r[0][:24], r[1], r[2][:10], *[fmt(x) for x in r[3:9]], extra, flag))
if out:
    import csv
    with open(out, "w", newline="\n", encoding="utf-8") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(["entry", "tier", "exemption", "before_crystals", "before_pop", "before_both", "after_crystals", "after_pop",
                    "after_both", "t3_vs_t12_before_crystals", "t3_vs_t12_before_pop", "t3_vs_t12_before_both",
                    "t3_vs_t12_after_crystals", "t3_vs_t12_after_pop", "t3_vs_t12_after_both"])
        for r in rows:
            w.writerow([fmt(x) if not isinstance(x, str) else x for x in r])

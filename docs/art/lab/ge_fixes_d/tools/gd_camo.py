"""G-E fixes D: what the Nature unit pixels are made of vs the meadow behind them (L* / hue histogram, camo pixels' colour).
Run: python -I gd_camo.py <measure dir> [kingdom]"""
import sys, os
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gv_measure import to_lab, hue, hsv

d = sys.argv[1]
k = sys.argv[2] if len(sys.argv) > 2 else "nature"
p = os.path.join(d, f"{k}_units_")
a = np.asarray(Image.open(p + "a.png").convert("RGB"), dtype=np.float64) / 255.0
m = np.asarray(Image.open(p + "m.png").convert("RGB"), dtype=np.float64) / 255.0
g = np.asarray(Image.open(p + "g.png").convert("RGB"), dtype=np.float64) / 255.0
mask = (m[..., 0] > 0.8) & (m[..., 1] < 0.25) & (m[..., 2] > 0.8) & (np.abs(a - g).sum(axis=-1) > 0.1)
A, G = a[mask], g[mask]
la, lg = to_lab(A), to_lab(G)
ha, hg = hue(A), hue(G)
va, sa = hsv(A)
vg, sg = hsv(G)
print("ground mean rgb", G.mean(0).round(3), "L*", lg[:, 0].mean().round(1), "hue med", np.median(hg[sg > 0.2]).round(0))
print("unit mean rgb", A.mean(0).round(3), "L*", la[:, 0].mean().round(1))
dh = np.abs(ha - hg); dh = np.minimum(dh, 360 - dh)
camo = (dh < 30) & (sa > 0.2) & (sg > 0.2) & (np.abs(la[:, 0] - lg[:, 0]) < 12)
print("camo share", camo.mean().round(3), "camo mean rgb", A[camo].mean(0).round(3), "L*", la[camo, 0].mean().round(1))
green = (ha > 60) & (ha < 160) & (sa > 0.25)
mid = (ha > 50) & (ha < 110) & (sa > 0.2) & (la[:, 0] > 40) & (la[:, 0] < 66)
print("mid grass band (hue 50-110, L* 40-66) share", mid.mean().round(3))
print("green-ish (hue 60-160, s>0.25) share", green.mean().round(3))
for lo, hi in [(0, 30), (30, 45), (45, 60), (60, 75), (75, 101)]:
    s = (la[:, 0] >= lo) & (la[:, 0] < hi)
    print(f"L* {lo}-{hi}: {s.mean():.3f}")
for lo, hi in [(0, 30), (30, 50), (50, 70), (70, 100), (100, 160), (160, 360)]:
    s = (ha >= lo) & (ha < hi) & (sa > 0.2)
    print(f"hue {lo}-{hi}: {s.mean():.3f}")

if "--show" in sys.argv:
    out = (a * 255).astype(np.uint8).copy()
    idx = np.argwhere(mask)
    sel = idx[camo]
    out[sel[:, 0], sel[:, 1]] = [255, 0, 0]
    ys, xs = idx[:, 0], idx[:, 1]
    Image.fromarray(out).crop((xs.min() - 10, ys.min() - 10, xs.max() + 10, ys.max() + 10)).save(sys.argv[sys.argv.index("--show") + 1])

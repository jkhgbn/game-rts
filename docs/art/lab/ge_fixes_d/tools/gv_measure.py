"""G-E value pass: unit / building pixels vs the ground behind them, per kingdom (docs/art/ge_value_pass.md).
Input: a folder from gv_shots.gd --mode=measure (<k>_<what>_{a,m,g}.png). Run: python -I gv_measure.py <dir> [--json out]
Mask = magenta in _m AND the pixel changed between _a (normal) and _g (hidden), so invisible / see-through parts drop out.
Columns (HSV in sRGB 0-1):
  Vu / Su   mean value / saturation of the masked pixels (normal shot)
  Vg / Sg   mean value / saturation of the ground behind the same pixels (_g)
  dV        Vu - Vg
  Cpx       mean |V(a) - V(g)| per pixel (how much the model stands out from the ground right behind it)
  dEpx      mean CIE76 delta E per pixel (hue + value + chroma difference)
  CL        mean |L*(a) - L*(g)| per pixel / 100: the perceived lightness contrast (HSV V favours saturated colours:
            a pure orange and a pure violet both have V = 1); the value-contrast target of the pass is on CL
  Lu        mean L* / 100 of the masked pixels
  Camo      share of masked pixels whose hue is within 30 deg of the ground right behind them (both saturation > 0.2)
            and whose L* is within 12: the "green on green grass" read (lower = the model stands off the ground)
  Sbase     median saturation of the 80 % darkest masked pixels (the base materials, glows / highlights left out)
  V95       95th percentile value (the brightest parts)
"""
import json
import os
import sys

import numpy as np
from PIL import Image

KINGDOMS = ["fire", "ice", "nature", "shadow"]
WHATS = ["units", "buildings"]


def hsv(a: np.ndarray):
    mx = a.max(axis=-1)
    mn = a.min(axis=-1)
    s = np.where(mx > 1e-6, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    return mx, s


def to_lab(a: np.ndarray) -> np.ndarray:
    lin = np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = lin @ m.T
    xyz /= np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    L = 116.0 * f[..., 1] - 16.0
    A = 500.0 * (f[..., 0] - f[..., 1])
    B = 200.0 * (f[..., 1] - f[..., 2])
    return np.stack([L, A, B], axis=-1)


def hue(a: np.ndarray) -> np.ndarray:
    r, g, b = a[:, 0], a[:, 1], a[:, 2]
    mx = a.max(axis=-1)
    mn = a.min(axis=-1)
    d = np.maximum(mx - mn, 1e-6)
    h = np.where(mx == r, ((g - b) / d) % 6.0, np.where(mx == g, (b - r) / d + 2.0, (r - g) / d + 4.0))
    return h * 60.0


def measure(d: str, k: str, what: str):
    p = os.path.join(d, f"{k}_{what}_")
    if not os.path.exists(p + "a.png"):
        return None
    a = np.asarray(Image.open(p + "a.png").convert("RGB"), dtype=np.float64) / 255.0
    m = np.asarray(Image.open(p + "m.png").convert("RGB"), dtype=np.float64) / 255.0
    g = np.asarray(Image.open(p + "g.png").convert("RGB"), dtype=np.float64) / 255.0
    magenta = (m[..., 0] > 0.8) & (m[..., 1] < 0.25) & (m[..., 2] > 0.8)
    changed = np.abs(a - g).sum(axis=-1) > 0.1
    mask = magenta & changed
    n = int(mask.sum())
    if n < 200:
        return None
    va, sa = hsv(a[mask])
    vg, sg = hsv(g[mask])
    la = to_lab(a[mask])
    lg = to_lab(g[mask])
    de = np.sqrt(((la - lg) ** 2).sum(axis=-1))
    cut = np.quantile(va, 0.8)
    dh = np.abs(hue(a[mask]) - hue(g[mask]))
    dh = np.minimum(dh, 360.0 - dh)
    camo = (dh < 30.0) & (sa > 0.2) & (sg > 0.2) & (np.abs(la[:, 0] - lg[:, 0]) < 12.0)
    return {
        "px": n,
        "Vu": float(va.mean()), "Su": float(sa.mean()),
        "Vg": float(vg.mean()), "Sg": float(sg.mean()),
        "dV": float(va.mean() - vg.mean()),
        "Cpx": float(np.abs(va - vg).mean()),
        "dEpx": float(de.mean()),
        "CL": float(np.abs(la[:, 0] - lg[:, 0]).mean() / 100.0),
        "Lu": float(la[:, 0].mean() / 100.0),
        "Camo": float(camo.mean()),
        "Sbase": float(np.median(sa[va <= cut])),
        "V95": float(np.quantile(va, 0.95)),
    }


def main() -> None:
    d = sys.argv[1]
    out = {}
    cols = ["px", "Vu", "Su", "Vg", "Sg", "dV", "Cpx", "Lu", "CL", "Camo", "dEpx", "Sbase", "V95"]
    for what in WHATS:
        print(f"\n{what}")
        print("| kingdom | " + " | ".join(cols) + " | Cpx / Fire | CL / Fire |")
        print("|---" * (len(cols) + 3) + "|")
        rows = {k: measure(d, k, what) for k in KINGDOMS}
        fire = rows.get("fire")
        for k in KINGDOMS:
            r = rows[k]
            if r is None:
                continue
            rel = r["Cpx"] / fire["Cpx"] if fire else 0.0
            rel_l = r["CL"] / fire["CL"] if fire else 0.0
            vals = [str(r["px"])] + [f"{r[c]:.3f}" for c in cols[1:]]
            print(f"| {k} | " + " | ".join(vals) + f" | {rel:.2f} | {rel_l:.2f} |")
            out[f"{k}_{what}"] = r
    if "--json" in sys.argv:
        with open(sys.argv[sys.argv.index("--json") + 1], "w", encoding="utf-8") as f:
            json.dump(out, f, indent=1)


if __name__ == "__main__":
    main()

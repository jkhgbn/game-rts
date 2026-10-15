"""G-E fixes D: loud violet share of a shot region (hue 260-320 deg, saturation > 0.45, value > 0.7) = the glow read.
Run: python -I gd_violet.py <img> [x0 y0 x1 y1]"""
import sys
import numpy as np
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
if len(sys.argv) >= 6:
    im = im.crop(tuple(int(v) for v in sys.argv[2:6]))
a = np.asarray(im, dtype=np.float64) / 255.0
mx = a.max(-1); mn = a.min(-1); d = np.maximum(mx - mn, 1e-6)
r, g, b = a[..., 0], a[..., 1], a[..., 2]
h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
loud = (h > 260) & (h < 320) & (s > 0.45) & (mx > 0.7)
print(f"{sys.argv[1]}: loud violet {loud.mean() * 100:.2f} % of {a.shape[1]}x{a.shape[0]}")

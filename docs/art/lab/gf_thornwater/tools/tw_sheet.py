"""G-F review 2 item 9 (Thornwater identity) contact sheet + key PNGs.
Rows = views, columns = Crown Hollow | Thornwater before | Thornwater after.
Run: python -I docs/art/lab/gf_thornwater/tools/tw_sheet.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
COLS = [("Crown Hollow", "crown"), ("Thornwater before", "before"), ("Thornwater after", "after")]
ROWS = [("overview", "overview"), ("crown isle z35", "centre_z35"), ("river + ford z30", "river_z30"),
        ("west border z40", "edge_z40")]
KEYS = [("tw_key_overview", "overview"), ("tw_key_river_z30", "river_z30"), ("tw_key_crown_isle", "centre_z35")]
TW, TH, LAB = 640, 360, 26


def font(sz):
    for f in ("C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, sz)
    return ImageFont.load_default()


def tile(col, row):
    p = os.path.join(ROOT, col, row + ".jpg")
    im = Image.open(p).convert("RGB") if os.path.exists(p) else Image.new("RGB", (1600, 900), (40, 40, 40))
    return im.resize((TW, TH), Image.LANCZOS)


def strip(row, labels=True, prefix=""):
    out = Image.new("RGB", (TW * len(COLS), TH + LAB), (18, 18, 22))
    d = ImageDraw.Draw(out)
    f = font(18)
    for i, (name, col) in enumerate(COLS):
        out.paste(tile(col, row), (i * TW, LAB))
        d.text((i * TW + 8, 3), prefix + name, fill=(235, 235, 235), font=f)
    return out


sheet = Image.new("RGB", (TW * len(COLS), (TH + LAB) * len(ROWS)), (18, 18, 22))
for r, (label, row) in enumerate(ROWS):
    sheet.paste(strip(row, prefix=label + ": "), (0, r * (TH + LAB)))
sheet.save(os.path.join(ROOT, "tw_contact_sheet.jpg"), quality=88)
for name, row in KEYS:
    strip(row).save(os.path.join(ROOT, name + ".png"))
print("sheet + %d keys" % len(KEYS))

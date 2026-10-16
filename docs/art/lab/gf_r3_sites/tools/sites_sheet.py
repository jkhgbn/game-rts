"""G-F round-3 sites contact sheet -> docs/art/lab/gf_r3_sites/sites_contact_sheet.jpg (before | after per row)
plus 4 key PNGs (1280x720). Run: python -I docs/art/lab/gf_r3_sites/tools/sites_sheet.py
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
KINGDOMS = ["fire", "ice", "nature", "shadow"]
SHOTS = [("row z24 (0 / 30 / 70 %)", "row_%s_z24.jpg"), ("Hall 0 % z12", "hall00_%s_z12.jpg"),
         ("Hall 30 % z12", "hall30_%s_z12.jpg"), ("Hall 70 % z12", "hall70_%s_z12.jpg")]
KEYS = [
    ("sites_key_fire_row", "after/row_fire_z24.jpg"),
    ("sites_key_ice_row", "after/row_ice_z24.jpg"),
    ("sites_key_shadow_hall00", "after/hall00_shadow_z12.jpg"),
    ("sites_key_nature_hall30", "after/hall30_nature_z12.jpg"),
]


def main() -> None:
    tw, th, pad, lab = 400, 225, 6, 22
    cols = 8   # 4 shots x (before, after)
    rows = len(KINGDOMS)
    sheet = Image.new("RGB", (cols * (tw + pad) + pad, rows * (th + lab + pad) + pad), (18, 18, 20))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 14)
    except OSError:
        font = ImageFont.load_default()
    for r, k in enumerate(KINGDOMS):
        c = 0
        for label, pat in SHOTS:
            for tag in ("before", "after"):
                rel = os.path.join(tag, pat % k)
                x = pad + c * (tw + pad)
                y = pad + r * (th + lab + pad)
                draw.text((x + 2, y + 2), "%s %s %s" % (k, tag, label), fill=(235, 230, 215), font=font)
                p = os.path.join(ROOT, rel)
                if os.path.exists(p):
                    im = Image.open(p).convert("RGB")
                    im.thumbnail((tw, th), Image.LANCZOS)
                    sheet.paste(im, (x, y + lab))
                else:
                    print("missing", rel)
                c += 1
    out = os.path.join(ROOT, "sites_contact_sheet.jpg")
    sheet.save(out, quality=82)
    print("saved", out, sheet.size)
    for name, rel in KEYS:
        im = Image.open(os.path.join(ROOT, rel)).convert("RGB").resize((1280, 720), Image.LANCZOS)
        im.save(os.path.join(ROOT, name + ".png"), optimize=True)
        print("key", name)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        ROOT = sys.argv[1]
    main()

"""G-F review 2 item 11 (m02 frozen Emberguard + snow border): before / after contact sheet ->
docs/art/lab/gf_m02/gf_m02_contact_sheet.jpg and 4 key PNGs (before | after side by side).
Run: python -I docs/art/lab/gf_m02/tools/gm_sheet.py
"before" = gm_shots.gd --undress (old boxes, no cliffs) except the overview, which is the review's own shot
(docs/art/lab/gf_review2/high_missions/m02_ice_overview.jpg: the old painted canopy before this task).
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
REVIEW_OV = os.path.join(ROOT, "..", "gf_review2", "high_missions", "m02_ice_overview.jpg")
SHOTS = [
    ("West block close (Emberguard inside)", "block_west_close", None),
    ("West block z12", "block_west_z12", None),
    ("South block z24 (guarded)", "block_south_z24", None),
    ("North block z30", "block_north_z30", None),
    ("Sentinel shells z16", "sentinels_z16", None),
    ("Overview (before = review 2 shot)", "m02_overview", REVIEW_OV),
    ("North border z30", "border_north_z30", None),
    ("West border z55", "border_west_z55", None),
    ("South border z40", "border_south_z40", None),
    ("Thaw: shatter burst / teeth after", "thaw_south_burst", "AFTER:thaw_south_after"),
]
KEYS = [("gf_m02_key_block_close", "block_west_close", None), ("gf_m02_key_overview", "m02_overview", REVIEW_OV),
        ("gf_m02_key_border_north", "border_north_z30", None), ("gf_m02_key_sentinels", "sentinels_z16", None)]


def load(path, tw, th):
    return Image.open(path).convert("RGB").resize((tw, th), Image.LANCZOS)


def pair(name, before, tw, th):
    out = Image.new("RGB", (tw * 2 + 6, th), (18, 18, 20))
    if before and before.startswith("AFTER:"):
        left = os.path.join(ROOT, "after", name + ".jpg")
        right = os.path.join(ROOT, "after", before[6:] + ".jpg")
    else:
        left = before or os.path.join(ROOT, "before", name + ".jpg")
        right = os.path.join(ROOT, "after", name + ".jpg")
    out.paste(load(left, tw, th), (0, 0))
    out.paste(load(right, tw, th), (tw + 6, 0))
    return out


def main() -> None:
    try:
        font = ImageFont.truetype("arial.ttf", 16)
    except OSError:
        font = ImageFont.load_default()
    tw, th, lab, pad = 400, 225, 22, 8
    cols = 2
    rows = (len(SHOTS) + cols - 1) // cols
    cw = tw * 2 + 6
    sheet = Image.new("RGB", (cols * (cw + pad) + pad, rows * (th + lab + pad) + pad), (18, 18, 20))
    d = ImageDraw.Draw(sheet)
    for i, (label, name, before) in enumerate(SHOTS):
        x = pad + (i % cols) * (cw + pad)
        y = pad + (i // cols) * (th + lab + pad)
        sub = "" if before and before.startswith("AFTER:") else "   (before | after)"
        d.text((x, y + 2), "%d  %s%s" % (i + 1, label, sub), fill=(230, 230, 230), font=font)
        sheet.paste(pair(name, before, tw, th), (x, y + lab))
    sheet.save(os.path.join(ROOT, "gf_m02_contact_sheet.jpg"), quality=88)
    for key, name, before in KEYS:
        pair(name, before, 800, 450).save(os.path.join(ROOT, key + ".png"))
    print("sheet + %d keys" % len(KEYS))


if __name__ == "__main__":
    main()

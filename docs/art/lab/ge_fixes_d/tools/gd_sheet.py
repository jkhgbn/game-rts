"""G-E fixes D contact sheet: before | after pairs -> docs/art/lab/ge_fixes_d/gd_contact_sheet.jpg, plus 4 key PNGs
(before left, after right). Run: python -I docs/art/lab/ge_fixes_d/tools/gd_sheet.py"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TW, TH = 640, 360
# (label, before, after, crop box in the 1600 x 900 frame or None)
PAIRS = [
    ("Nature army on meadow z30", "before_ns/lineup_nature_z30.jpg", "after_ns/lineup_nature_z30.jpg", None),
    ("Nature units, measure grid z35", "before_measure/nature_units_a.png", "after_measure/nature_units_a.png", (540, 170, 1220, 552)),
    ("Riders close z7 (warden left, dartcaster right)", "before_riders/riders_z7.jpg", "after_riders/riders_z7.jpg", None),
    ("Riders z12", "before_riders/riders_z12.jpg", "after_riders/riders_z12.jpg", None),
    ("Shadow base z30 (Dusk Keep top centre)", "before_keep/base_shadow_z30.jpg", "after_keep/base_shadow_z30.jpg", None),
    ("Dusk Keep crop z30", "before_keep/base_shadow_z30.png", "after_keep/base_shadow_z30.png", (700, 0, 1240, 304)),
    ("Shadow base z40", "before_keep/base_shadow_z40.jpg", "after_keep/base_shadow_z40.jpg", None),
    ("Hovel z10 (tip shard)", "before_keep/hovel_z10.jpg", "after_keep/hovel_z10.jpg", None),
    ("Nature death leaves z14 (CombatFxG off; CombatVfx death_nature still on)", "leaves1/leaves_z14.jpg", "after_leaves/leaves_z14.jpg", None),
    ("Nature death leaves z30 (CombatFxG off; CombatVfx death_nature still on)", "leaves1/leaves_z30.jpg", "after_leaves/leaves_z30.jpg", (400, 200, 1200, 650)),
]
KEYS = [("gd_key_nature_z30", 0), ("gd_key_riders_z7", 2), ("gd_key_dusk_keep_z30", 4), ("gd_key_dusk_keep_crop", 5)]


def tile(path: str, label: str, crop, w: int = TW, h: int = TH) -> Image.Image:
    p = os.path.join(ROOT, path)
    if os.path.exists(p):
        im = Image.open(p).convert("RGB")
        if crop:
            im = im.crop(crop)
        im = im.resize((w, h))
    else:
        im = Image.new("RGB", (w, h), (40, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w, 18], fill=(0, 0, 0))
    d.text((5, 3), label, fill=(255, 230, 120))
    return im


def main() -> None:
    rows = []
    for label, b, a, crop in PAIRS:
        r = Image.new("RGB", (TW * 2, TH))
        r.paste(tile(b, "BEFORE  " + label, crop), (0, 0))
        r.paste(tile(a, "AFTER  " + label, crop), (TW, 0))
        rows.append(r)
    cols = 2
    sheet = Image.new("RGB", (TW * 2 * cols, TH * ((len(rows) + cols - 1) // cols)))
    for i, r in enumerate(rows):
        sheet.paste(r, ((i % cols) * TW * 2, (i // cols) * TH))
    sheet.save(os.path.join(ROOT, "gd_contact_sheet.jpg"), quality=85)
    for name, i in KEYS:
        label, b, a, crop = PAIRS[i]
        k = Image.new("RGB", (1280 * 2, 720))
        k.paste(tile(b, "BEFORE  " + label, crop, 1280, 720), (0, 0))
        k.paste(tile(a, "AFTER  " + label, crop, 1280, 720), (1280, 0))
        k.resize((1920, 540)).save(os.path.join(ROOT, name + ".png"))
    print("sheet + keys written")


if __name__ == "__main__":
    main()

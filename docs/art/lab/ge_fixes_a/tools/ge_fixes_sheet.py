"""G-E fixes A contact sheet: before | after pairs -> docs/art/lab/ge_fixes_a/ge_fixes_a_sheet.jpg, plus 3 key PNGs.
Run: python -I docs/art/lab/ge_fixes_a/tools/ge_fixes_sheet.py
"Before" for item 5 (maps) and the Ice base is the G-E review run (docs/art/lab/ge_review/), taken the same day.
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
REV = os.path.join(ROOT, "..", "ge_review")
# (label, before, after, crop box in 1600x900 or None)
PAIRS = [
    ("4 Fire base z30", "before_fi/base_fire_p_z30.jpg", "after_fi/base_fire_p_z30.jpg", None),
    ("4 Shadow base z30", "before_ns/base_shadow_e_z30.jpg", "after_ns/base_shadow_e_z30.jpg", None),
    ("4 Nature base z30", "before_ns/base_nature_p_z30.jpg", "after_ns/base_nature_p_z30.jpg", None),
    ("4 Fire keep, night mission m00", "before_missions/m00_night_nofog_z45.jpg", "after_missions/m00_night_nofog_z45.jpg", None),
    ("4 battle VFX check z14", "before_fi/battle_deaths_z14.jpg", "after_fi/battle_deaths_z14.jpg", None),
    ("5 Crown Hollow overview", "REV:high_maps/crown_hollow_overview.jpg", "after_maps/crown_hollow_overview.jpg", None),
    ("5 Thornwater overview", "REV:high_maps/thornwater_overview.jpg", "after_maps/thornwater_overview.jpg", None),
    ("7 Ice base z30 (halo)", "REV:high_in/base_ice_p_z30.jpg", "after_in/base_ice_p_z30.jpg", None),
    ("7 Ice keep z10", "REV:high_in/keep_ice_p_z10.jpg", "after_in/keep_ice_p_z10.jpg", None),
    ("7 Fire Hall z10", "before_fi/hall_fire_p_z10.jpg", "after_fi/hall_fire_p_z10.jpg", None),
    ("7 Fire Hall from the side", "probe_fi/orbit_hall_fire_y0.jpg", "after_fi/orbit_hall_fire_y0.jpg", None),
]
KEYS = [
    ("ge_fixes_a_key_fire_base.png", "after_fi/base_fire_p_z30.jpg"),
    ("ge_fixes_a_key_ice_base.png", "after_in/base_ice_p_z30.jpg"),
    ("ge_fixes_a_key_overview.png", "after_maps/thornwater_overview.jpg"),
]
TW, TH = 480, 270


def _open(rel):
    p = os.path.join(REV, rel[4:]) if rel.startswith("REV:") else os.path.join(ROOT, rel)
    if not os.path.exists(p):
        return None
    return Image.open(p).convert("RGB")


def main():
    rows = len(PAIRS)
    sheet = Image.new("RGB", (TW * 2 + 30, rows * (TH + 22) + 10), (18, 18, 22))
    d = ImageDraw.Draw(sheet)
    for i, (label, a, b, box) in enumerate(PAIRS):
        y = 10 + i * (TH + 22)
        d.text((10, y), "%s   (before | after)" % label, fill=(235, 235, 235))
        for j, rel in enumerate((a, b)):
            im = _open(rel)
            if im is None:
                d.text((10 + j * (TW + 10), y + 120), "missing " + rel, fill=(255, 90, 90))
                continue
            if box:
                im = im.crop(box)
            sheet.paste(im.resize((TW, TH), Image.LANCZOS), (10 + j * (TW + 10), y + 16))
    sheet.save(os.path.join(ROOT, "ge_fixes_a_sheet.jpg"), quality=88)
    for name, rel in KEYS:
        im = _open(rel)
        if im is not None:
            im.resize((1280, 720), Image.LANCZOS).save(os.path.join(ROOT, name))
    print("sheet done")


main()

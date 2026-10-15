"""G-E fixes B contact sheet: before / after pairs -> docs/art/lab/ge_fixes_b/gb_contact_sheet.jpg, plus 3 key PNGs.
Run: python -I docs/art/lab/ge_fixes_b/tools/gb_sheet.py  (shots from gb_shots.gd, tags `before` and `after`)
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
ROWS = [
    ("m00 night z45 (fog of war off)", "m00_night_nofog_z45.jpg"),
    ("m00 night hero z14", "m00_night_hero_z14.jpg"),
    ("m00 night overview", "m00_night_overview.jpg"),
    ("m02 Ice z45 (fog of war off)", "m02_ice_nofog_z45.jpg"),
    ("m02 lake + drifts z30", "m02_ice_lake_z30.jpg"),
    ("m02 overview (border forest)", "m02_ice_overview.jpg"),
    ("Crown Hollow max zoom z55", "crown_hollow_z55.jpg"),
    ("Crown Hollow overview (depth fog)", "crown_hollow_overview.jpg"),
]
KEYS = [
    ("gb_key_night", "m00_night_nofog_z45.jpg"),
    ("gb_key_ice_lake", "m02_ice_lake_z30.jpg"),
    ("gb_key_overview_fog", "crown_hollow_overview.jpg"),
]


def main() -> None:
    tw, th, pad, lab = 640, 360, 6, 22
    sheet = Image.new("RGB", (2 * (tw + pad) + pad, len(ROWS) * (th + lab + pad) + pad), (18, 18, 20))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 16)
    except OSError:
        font = ImageFont.load_default()
    for r, (label, name) in enumerate(ROWS):
        for c, tag in enumerate(("before", "after")):
            p = os.path.join(ROOT, tag, name)
            x = pad + c * (tw + pad)
            y = pad + r * (th + lab + pad)
            draw.text((x + 4, y + 2), "%s - %s" % (label, tag.upper()), fill=(235, 235, 235), font=font)
            if os.path.exists(p):
                sheet.paste(Image.open(p).convert("RGB").resize((tw, th), Image.LANCZOS), (x, y + lab))
            else:
                print("missing", p)
    sheet.save(os.path.join(ROOT, "gb_contact_sheet.jpg"), quality=88)
    for key, name in KEYS:
        a = os.path.join(ROOT, "after", name)
        b = os.path.join(ROOT, "before", name)
        if os.path.exists(a) and os.path.exists(b):
            pair = Image.new("RGB", (1280, 360))
            pair.paste(Image.open(b).convert("RGB").resize((640, 360), Image.LANCZOS), (0, 0))
            pair.paste(Image.open(a).convert("RGB").resize((640, 360), Image.LANCZOS), (640, 0))
            pair.save(os.path.join(ROOT, key + ".png"))
    print("sheet done")


if __name__ == "__main__":
    main()

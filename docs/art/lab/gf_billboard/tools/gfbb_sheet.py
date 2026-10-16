"""G-F billboard keep-scale pass: before / after contact sheet -> docs/art/lab/gf_billboard/gf_billboard_contact_sheet.jpg
and 4 key PNGs (before over after). Run: python -I docs/art/lab/gf_billboard/tools/gfbb_sheet.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SHOTS = [
    ("Fire keep damaged z18", "fire_keep_dmg_z18"),
    ("Fire base damaged z30", "fire_base_dmg_z30"),
    ("Ember Hall damaged z18 (chimney fire, blaze, smoke)", "fire_hall_dmg_z18"),
    ("Hearth damaged z12 (chimney, blaze)", "fire_house_dmg_z12"),
    ("Fire Forge z12 (kiln fire, sparks)", "fire_forge_z12"),
    ("Hall site z14 (build ring)", "fire_site_z14"),
    ("Fire base site z30", "fire_site_z30"),
    ("Gloom Hall z12 (soul flame, ground mist)", "shadow_hall_z12"),
    ("Gloom Hall damaged z18", "shadow_hall_dmg_z18"),
    ("Shadow base damaged z30", "shadow_base_dmg_z30"),
    ("Frost Hall damaged z18", "ice_hall_dmg_z18"),
    ("Fire units z12", "fire_units_z12"),
]
KEYS = [("gf_billboard_key_fire_hall_dmg_z18", "fire_hall_dmg_z18"),
        ("gf_billboard_key_fire_base_dmg_z30", "fire_base_dmg_z30"),
        ("gf_billboard_key_shadow_hall_dmg_z18", "shadow_hall_dmg_z18"),
        ("gf_billboard_key_fire_site_z14", "fire_site_z14")]


def pair(name, tw, th, vertical=False):
    if vertical:
        out = Image.new("RGB", (tw, th * 2 + 6), (18, 18, 20))
    else:
        out = Image.new("RGB", (tw * 2 + 6, th), (18, 18, 20))
    for i, tag in enumerate(["before", "after"]):
        im = Image.open(os.path.join(ROOT, tag, name + ".jpg")).convert("RGB").resize((tw, th), Image.LANCZOS)
        out.paste(im, (0, i * (th + 6)) if vertical else (i * (tw + 6), 0))
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
    for i, (label, name) in enumerate(SHOTS):
        x = pad + (i % cols) * (cw + pad)
        y = pad + (i // cols) * (th + lab + pad)
        d.text((x, y + 2), "%d  %s   (before | after)" % (i + 1, label), fill=(230, 230, 230), font=font)
        sheet.paste(pair(name, tw, th), (x, y + lab))
    sheet.save(os.path.join(ROOT, "gf_billboard_contact_sheet.jpg"), quality=88)
    for key, name in KEYS:
        pair(name, 800, 450).save(os.path.join(ROOT, key + ".png"))
    print("sheet + %d keys" % len(KEYS))


if __name__ == "__main__":
    main()

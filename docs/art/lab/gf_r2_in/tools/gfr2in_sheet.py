"""G-F round 2 Ice / Nature buildings: before / after contact sheet -> docs/art/lab/gf_r2_in/gf_r2_in_contact_sheet.jpg
and 4 key PNGs (before | after side by side). Run: python -I docs/art/lab/gf_r2_in/tools/gfr2in_sheet.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SHOTS = [
    ("Ice Hall z10 (item 6)", "hall_ice_p_z10"),
    ("Ice Hall z18 (item 6)", "hall_ice_p_z18"),
    ("Ice base z30 (items 6 + 7)", "base_ice_p_z30"),
    ("Ice in game z32", "ingame_ice_z32"),
    ("Ice keep z10 (item 7)", "keep_ice_p_z10"),
    ("Snow Lodge z12", "house_ice_p_z12"),
    ("Nature keep z10 (item 7)", "keep_nature_e_z10"),
    ("Nature base z30 (item 7)", "base_nature_e_z30"),
    ("Nature hall z10", "hall_nature_e_z10"),
    ("Nature hollow z12", "house_nature_e_z12"),
]
KEYS = [("gf_r2_in_key_ice_hall_z10", "hall_ice_p_z10"), ("gf_r2_in_key_ice_base_z30", "base_ice_p_z30"),
        ("gf_r2_in_key_nature_keep_z10", "keep_nature_e_z10"), ("gf_r2_in_key_ice_hall_z18", "hall_ice_p_z18")]


def pair(name, tw, th):
    out = Image.new("RGB", (tw * 2 + 6, th), (18, 18, 20))
    for i, tag in enumerate(["before", "after"]):
        im = Image.open(os.path.join(ROOT, tag, name + ".jpg")).convert("RGB")
        im = im.resize((tw, th), Image.LANCZOS)
        out.paste(im, (i * (tw + 6), 0))
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
    sheet.save(os.path.join(ROOT, "gf_r2_in_contact_sheet.jpg"), quality=88)
    for key, name in KEYS:
        pair(name, 800, 450).save(os.path.join(ROOT, key + ".png"))
    print("sheet + %d keys" % len(KEYS))


if __name__ == "__main__":
    main()

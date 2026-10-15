"""G-E value pass contact sheet: before | after pairs -> docs/art/lab/ge_value/gv_contact_sheet.jpg, plus up to 3 key PNGs
(before left, after right). Run: python -I docs/art/lab/ge_value/tools/gv_sheet.py
Also builds the 4-bases-side-by-side row (Fire, Ice, Nature, Shadow at z30) from the bases runs.
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TW, TH = 640, 360
# (label, before path, after path) relative to ROOT; "<tag>" = before_ / after_
PAIRS = [
    ("Fire base z30 (reference)", "{p}fs/base_fire_p_z30.jpg"),
    ("Shadow base z30", "{p}fs/base_shadow_e_z30.jpg"),
    ("Ice base z30", "{p}in/base_ice_p_z30.jpg"),
    ("Nature base z30", "{p}in/base_nature_e_z30.jpg"),
    ("Shadow base z40", "{p}fs/base_shadow_e_z40.jpg"),
    ("Ice base z40", "{p}in/base_ice_p_z40.jpg"),
    ("4-kingdom battle z30", "{p}fs/battle_z30.jpg"),
    ("4-kingdom battle z40", "{p}fs/battle_z40.jpg"),
    ("Shadow mirror lineup z30", "{p}mirror/lineup_shadow_z30.jpg"),
    ("Shadow mirror lineup z40", "{p}mirror/lineup_shadow_z40.jpg"),
    ("Nature lineup z30", "{p}in/lineup_nature_z30.jpg"),
    ("Ice lineup z30", "{p}in/lineup_ice_z30.jpg"),
]
BASES = [("Fire", "{p}fs/base_fire_p_z30.jpg"), ("Ice", "{p}in/base_ice_p_z30.jpg"),
         ("Nature", "{p}in/base_nature_e_z30.jpg"), ("Shadow", "{p}fs/base_shadow_e_z30.jpg")]
KEYS = [("gv_key_bases", None), ("gv_key_battle_z30", "{p}fs/battle_z30.jpg"),
        ("gv_key_mirror_z40", "{p}mirror/lineup_shadow_z40.jpg")]


def tile(path: str, label: str, w: int = TW, h: int = TH) -> Image.Image:
    p = os.path.join(ROOT, path)
    im = Image.open(p).convert("RGB").resize((w, h)) if os.path.exists(p) else Image.new("RGB", (w, h), (40, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w, 18], fill=(0, 0, 0))
    d.text((5, 3), label, fill=(255, 230, 120))
    return im


def bases_row(prefix: str, w: int, h: int) -> Image.Image:
    row = Image.new("RGB", (w * 4, h))
    for i, (name, pat) in enumerate(BASES):
        row.paste(tile(pat.format(p=prefix), f"{name} ({prefix.rstrip('_')})", w, h), (i * w, 0))
    return row


def main() -> None:
    rows = []
    for label, pat in PAIRS:
        r = Image.new("RGB", (TW * 2, TH))
        r.paste(tile(pat.format(p="before_"), "BEFORE  " + label), (0, 0))
        r.paste(tile(pat.format(p="after_"), "AFTER  " + label), (TW, 0))
        rows.append(r)
    cols = 2
    n = len(rows)
    sheet = Image.new("RGB", (TW * 2 * cols, TH * ((n + cols - 1) // cols) + TH))
    sheet.paste(bases_row("before_", TW, TH // 2 * 1).resize((TW * 2, TH // 2)), (0, 0))
    sheet.paste(bases_row("after_", TW, TH // 2 * 1).resize((TW * 2, TH // 2)), (0, TH // 2))
    for i, r in enumerate(rows):
        sheet.paste(r, ((i % cols) * TW * 2, TH + (i // cols) * TH))
    sheet.save(os.path.join(ROOT, "gv_contact_sheet.jpg"), quality=85)
    for name, pat in KEYS:
        if pat is None:
            k = Image.new("RGB", (1280 * 2 // 2 * 2, 360 * 2))
            k.paste(bases_row("before_", 640, 360).resize((2560, 360)), (0, 0))
            k.paste(bases_row("after_", 640, 360).resize((2560, 360)), (0, 360))
            k = k.resize((1920, 540))
        else:
            k = Image.new("RGB", (1280 * 2, 720))
            k.paste(tile(pat.format(p="before_"), "BEFORE", 1280, 720), (0, 0))
            k.paste(tile(pat.format(p="after_"), "AFTER", 1280, 720), (1280, 0))
            k = k.resize((1920, 540))
        k.save(os.path.join(ROOT, name + ".png"))
    print("sheet + keys written")


if __name__ == "__main__":
    main()

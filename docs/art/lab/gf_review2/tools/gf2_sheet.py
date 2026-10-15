"""G-F round-2 review contact sheet -> docs/art/lab/gf_review2/gf2_contact_sheet.jpg.
Also copies the key shots as PNG (1280x720) next to it. Run: python -I docs/art/lab/gf_review2/tools/gf2_sheet.py
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
# (label, relative path) in reading order; numbers in docs/art/gf_review2.md refer to these tiles.
TILES = [
    ("1 Fire base z30 (High)", "high_fs/base_fire_p_z30.jpg"),
    ("2 Ice base z30", "high_in/base_ice_p_z30.jpg"),
    ("3 Nature base z30 (enemy)", "high_in/base_nature_e_z30.jpg"),
    ("4 Shadow base z30 (mirror, player)", "high_mirror/base_shadow_p_z30.jpg"),
    ("5 Shadow mirror lineup z35", "high_mirror/lineup_shadow_z35.jpg"),
    ("6 in game, Fire start z32", "high_fs/ingame_fire_z32.jpg"),
    ("7 4-kingdom battle z30", "high_fs/battle_z30.jpg"),
    ("8 4-kingdom battle z14", "high_fs/battle_z14.jpg"),
    ("9 fog of war edge z40", "high_fs/ingame_fogedge_fire_z40.jpg"),
    ("10 Shadow Hall z10", "high_fs/hall_shadow_e_z10.jpg"),
    ("11 Ice Hall z10", "high_in/hall_ice_p_z10.jpg"),
    ("12 Nature keep z10", "high_in/keep_nature_e_z10.jpg"),
    ("13 Crown Hollow overview", "high_maps/crown_hollow_overview.jpg"),
    ("14 Thornwater overview", "high_maps/thornwater_overview.jpg"),
    ("15 Quartermeet centre z45 (autumn)", "high_maps/quartermeet_centre_z45.jpg"),
    ("16 Ashwind Reach overview (Wave Strike)", "high_maps/ashwind_reach_overview.jpg"),
    ("17 m02 Ice mission z45", "high_missions/m02_ice_nofog_z45.jpg"),
    ("18 m00 night, in game z30", "high_missions/m00_night_ingame_z30.jpg"),
    ("19 m03 Sighing Wood overview", "high_missions/m03_wood_overview.jpg"),
    ("20 main menu diorama", "menu/menu_diorama_gf2_high_1600x900_wide_ui.png"),
    ("21 champions z10", "high_close/champions_z10.jpg"),
    ("22 titans z30", "high_close/titans_z30.jpg"),
    ("23 Ultra: Nature base z30", "ultra_nf/base_nature_p_z30.jpg"),
    ("24 Ultra: Nature lineup z16", "ultra_nf/lineup_nature_z16_left.jpg"),
]
KEYS = [
    ("gf2_key_battle_hp_bars", "high_fs/battle_z30.jpg"),
    ("gf2_key_fire_start_ingame", "high_fs/ingame_fire_z32.jpg"),
    ("gf2_key_autumn_quartermeet", "high_maps/quartermeet_centre_z45.jpg"),
    ("gf2_key_shadow_mirror_base", "high_mirror/base_shadow_p_z30.jpg"),
]


def main() -> None:
    tiles = [t for t in TILES if os.path.exists(os.path.join(ROOT, t[1]))]
    missing = [t[1] for t in TILES if t not in tiles]
    if missing:
        print("missing:", missing)
    tw, th, pad, lab = 480, 270, 6, 22
    cols = 4
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (tw + pad) + pad, rows * (th + lab + pad) + pad), (18, 18, 20))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 16)
    except OSError:
        font = ImageFont.load_default()
    for i, (label, rel) in enumerate(tiles):
        im = Image.open(os.path.join(ROOT, rel)).convert("RGB")
        im.thumbnail((tw, th), Image.LANCZOS)
        x = pad + (i % cols) * (tw + pad)
        y = pad + (i // cols) * (th + lab + pad)
        draw.text((x + 2, y + 2), label, fill=(235, 230, 215), font=font)
        sheet.paste(im, (x, y + lab))
    out = os.path.join(ROOT, "gf2_contact_sheet.jpg")
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

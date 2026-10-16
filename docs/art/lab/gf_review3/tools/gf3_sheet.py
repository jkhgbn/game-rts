"""G-F round-3 review contact sheet -> docs/art/lab/gf_review3/gf3_contact_sheet.jpg.
Also copies the key shots as PNG (1280x720) next to it. Run: python -I docs/art/lab/gf_review3/tools/gf3_sheet.py
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
# (label, relative path) in reading order; numbers in docs/art/gf_review3.md refer to these tiles.
TILES = [
    ("1 Fire start in game z32", "high_fs/ingame_fire_z32.jpg"),
    ("2 Ice start in game z32 (Ice keep loudest)", "high_in/ingame_ice_z32.jpg"),
    ("3 Fire base z30 (crucible pit)", "high_fs/base_fire_p_z30.jpg"),
    ("4 Shadow base z30 (player, mirror)", "high_mirror/base_shadow_p_z30.jpg"),
    ("5 Nature base z30 (enemy)", "high_in/base_nature_e_z30.jpg"),
    ("6 Ice Hall z10", "high_in/hall_ice_p_z10.jpg"),
    ("7 Fire sites z30 (0 % / 45 %)", "high_fs/sites_fire_p_z30.jpg"),
    ("8 Shadow site 0 % z12", "high_fs/site0_shadow_e_z12.jpg"),
    ("9 Ice sites z30", "high_in/sites_ice_p_z30.jpg"),
    ("10 Fire keep 20 % HP z14", "high_fs/keep20_fire_p_z14.jpg"),
    ("11 Shadow keep 20 % HP z14", "high_fs/keep20_shadow_e_z14.jpg"),
    ("12 Ice keep 20 % HP z14", "high_in/keep20_ice_p_z14.jpg"),
    ("13 Nature keep 20 % HP z14", "high_in/keep20_nature_e_z14.jpg"),
    ("14 mixed battle z30", "high_fs/battle_z30.jpg"),
    ("15 mixed battle z14", "high_fs/battle_z14.jpg"),
    ("16 Thornwater overview", "high_maps/thornwater_overview.jpg"),
    ("17 Thornwater crown isle z30", "high_maps/thornwater_crown_z30.jpg"),
    ("18 Quartermeet overview", "high_maps/quartermeet_overview.jpg"),
    ("19 Quartermeet crown isle z30", "high_maps/quartermeet_crown_z30.jpg"),
    ("20 Ashwind Reach overview (Wave Strike)", "high_maps/ashwind_reach_overview.jpg"),
    ("21 Ashwind Reach centre z45", "high_maps/ashwind_reach_centre_z45.jpg"),
    ("22 m00 night start z30", "high_missions/m00_night_ingame_z30.jpg"),
    ("23 m00 night no fog z45", "high_missions/m00_night_nofog_z45.jpg"),
    ("24 m02 Ice start z30", "high_missions/m02_ice_ingame_z30.jpg"),
    ("25 main menu", "menu/menu_diorama_gf3_high_1920x1080_wide_ui.png"),
    ("26 skirmish setup menu", "menu/menu_diorama_gf3_high_1920x1080_skirmish_ui.png"),
    ("27 champions z10", "high_close/champions_z10.jpg"),
    ("28 titans z30", "high_close/titans_z30.jpg"),
]
KEYS = [
    ("gf3_key_battle_z30", "high_fs/battle_z30.jpg"),
    ("gf3_key_ice_start_ingame", "high_in/ingame_ice_z32.jpg"),
    ("gf3_key_fire_base_crucible", "high_fs/base_fire_p_z30.jpg"),
    ("gf3_key_fire_sites", "high_fs/sites_fire_p_z30.jpg"),
    ("gf3_key_shadow_site0", "high_fs/site0_shadow_e_z12.jpg"),
    ("gf3_key_ashwind_centre", "high_maps/ashwind_reach_centre_z45.jpg"),
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
    out = os.path.join(ROOT, "gf3_contact_sheet.jpg")
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

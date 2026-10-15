"""G-E review contact sheet: labelled thumbnails of the chosen shots -> docs/art/lab/ge_review/ge_contact_sheet.jpg.
Also copies the key shots as PNG (1280x720) next to it. Run: python -I docs/art/lab/ge_review/tools/ge_sheet.py
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
# (label, relative path) in reading order; numbers in docs/art/ge_review.md refer to these tiles.
TILES = [
    ("1 Fire base z30 (High)", "high_fs/base_fire_p_z30.jpg"),
    ("2 Ice base z30 (High)", "high_in/base_ice_p_z30.jpg"),
    ("3 Nature base z40 (High)", "high_in/base_nature_e_z40.jpg"),
    ("4 Shadow base z40 (High)", "high_fs/base_shadow_e_z40.jpg"),
    ("5 Fire lineup z35 (player front, enemy back)", "high_fs/lineup_fire_z35.jpg"),
    ("6 Nature lineup z35", "high_in/lineup_nature_z35.jpg"),
    ("7 Shadow mirror lineup z35", "high_mirror/lineup_shadow_z35.jpg"),
    ("8 4-kingdom battle z30", "high_fs/battle_z30.jpg"),
    ("9 battle + deaths z14", "high_fs/battle_deaths_z14.jpg"),
    ("10 fog of war edge, in game z40", "high_in/ingame_fogedge_ice_z40.jpg"),
    ("11 Fire Hall z10", "high_fs/hall_fire_p_z10.jpg"),
    ("12 Ice Hall z10", "high_in/hall_ice_p_z10.jpg"),
    ("13 Crown Hollow overview", "high_maps/crown_hollow_overview.jpg"),
    ("14 Thornwater centre z45", "high_maps/thornwater_centre_z45.jpg"),
    ("15 Quartermeet centre z45", "high_maps/quartermeet_centre_z45.jpg"),
    ("16 Ashwind Reach centre z45", "high_maps/ashwind_reach_centre_z45.jpg"),
    ("17 m02 Ice mission z45", "high_missions/m02_ice_nofog_z45.jpg"),
    ("18 m00 night mission z45", "high_missions/m00_night_nofog_z45.jpg"),
    ("19 m03 Sighing Wood overview", "high_missions/m03_wood_overview.jpg"),
    ("20 Low: Ice base z30", "low_is/base_ice_p_z30.jpg"),
    ("21 Low: Shadow base z30", "low_is/base_shadow_e_z30.jpg"),
    ("22 Ultra: Nature base z30", "ultra_nf/base_nature_p_z30.jpg"),
    ("23 Ultra: 4-kingdom battle z30", "ultra_nf/battle_z30.jpg"),
    ("24 Fire army z10", "high_fs/army_fire_p_z10.jpg"),
]
KEYS = [
    ("ge_key_mirror_lineup", "high_mirror/lineup_shadow_z35.jpg"),
    ("ge_key_fog_of_war", "high_in/ingame_fogedge_ice_z40.jpg"),
    ("ge_key_battle_z30", "high_fs/battle_z30.jpg"),
    ("ge_key_ice_base", "high_in/base_ice_p_z30.jpg"),
    ("ge_key_night_mission", "high_missions/m00_night_nofog_z45.jpg"),
    ("ge_key_overview_pads", "high_maps/crown_hollow_overview.jpg"),
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
    out = os.path.join(ROOT, "ge_contact_sheet.jpg")
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

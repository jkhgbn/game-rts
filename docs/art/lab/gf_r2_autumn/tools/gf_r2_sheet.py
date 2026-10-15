"""G-F r2 autumn contact sheet -> docs/art/lab/gf_r2_autumn/gf_r2_contact_sheet.jpg + 4 key PNGs (1280x720).
Before = the round-2 review shots (docs/art/lab/gf_review2/high_maps), after = after/.
Run: python -I docs/art/lab/gf_r2_autumn/tools/gf_r2_sheet.py
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
BEFORE = os.path.join(ROOT, "..", "gf_review2", "high_maps")
TILES = [
    ("BEFORE Quartermeet centre z45", os.path.join(BEFORE, "quartermeet_centre_z45.jpg")),
    ("AFTER Quartermeet centre z45", os.path.join(ROOT, "after", "quartermeet_centre_z45.jpg")),
    ("BEFORE Quartermeet overview", os.path.join(BEFORE, "quartermeet_overview.jpg")),
    ("AFTER Quartermeet overview", os.path.join(ROOT, "after", "quartermeet_overview.jpg")),
    ("BEFORE Ashwind overview", os.path.join(BEFORE, "ashwind_reach_overview.jpg")),
    ("AFTER Ashwind overview", os.path.join(ROOT, "after", "ashwind_reach_overview.jpg")),
    ("AFTER Quartermeet road z30", os.path.join(ROOT, "after", "quartermeet_z30_0.jpg")),
    ("AFTER Ashwind forest glade z30", os.path.join(ROOT, "after", "ashwind_reach_z30_1.jpg")),
    ("AFTER Ashwind pad yard z30", os.path.join(ROOT, "after", "ashwind_reach_z30_0.jpg")),
    ("AFTER Ashwind lane z30", os.path.join(ROOT, "after", "ashwind_reach_z30_2.jpg")),
]
KEYS = [
    ("gf_r2_key_quartermeet_before_after", [TILES[0][1], TILES[1][1]]),
    ("gf_r2_key_quartermeet_overview_before_after", [TILES[2][1], TILES[3][1]]),
    ("gf_r2_key_ashwind_overview_before_after", [TILES[4][1], TILES[5][1]]),
    ("gf_r2_key_ashwind_z30_forest", [TILES[7][1]]),
]
TW, TH = 640, 360


def main() -> None:
    cols = 2
    rows = (len(TILES) + cols - 1) // cols
    sheet = Image.new("RGB", (TW * cols, (TH + 22) * rows), (20, 20, 20))
    d = ImageDraw.Draw(sheet)
    for i, (label, path) in enumerate(TILES):
        x = (i % cols) * TW
        y = (i // cols) * (TH + 22)
        if os.path.exists(path):
            sheet.paste(Image.open(path).convert("RGB").resize((TW, TH)), (x, y + 22))
        d.text((x + 6, y + 5), label, fill=(240, 230, 200))
    sheet.save(os.path.join(ROOT, "gf_r2_contact_sheet.jpg"), quality=88)
    for name, paths in KEYS:
        ims = [Image.open(p).convert("RGB") for p in paths if os.path.exists(p)]
        if not ims:
            continue
        if len(ims) == 1:
            out = ims[0].resize((1280, 720))
        else:
            out = Image.new("RGB", (1280, 360))
            for j, im in enumerate(ims[:2]):
                out.paste(im.resize((640, 360)), (j * 640, 0))
        out.save(os.path.join(ROOT, name + ".png"))


if __name__ == "__main__":
    main()

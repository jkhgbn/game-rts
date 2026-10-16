"""G-F r3 leftovers contact sheet: before | after rows of the site shots + the after chimney close-up.
Run: python -I docs/art/lab/gf_r3_leftovers/tools/leftovers_sheet.py  (from the project root)
Reads before/ and after/ (leftovers_shots.gd), writes leftovers_sheet.jpg + the key PNGs next to them."""
import os
import sys
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
W, H = 960, 540
ROWS = [("hall00_edge_z8", "0 % site edge, grass vs the pad"), ("hall00_z12", "0 % site"),
        ("hall30_z12", "30 % site"), ("hall50_z12", "50 % site")]


def load(tag, name):
    p = os.path.join(ROOT, tag, name + ".jpg")
    if not os.path.exists(p):
        sys.exit("missing " + p)
    im = Image.open(p).convert("RGB")
    im.thumbnail((W, H))
    return im


def label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 8 + 7 * len(text), 22), fill=(0, 0, 0))
    d.text((5, 5), text, fill=(255, 255, 255))


sheet = Image.new("RGB", (2 * W, H * (len(ROWS) + 1)), (20, 20, 20))
for r, (name, cap) in enumerate(ROWS):
    for c, tag in enumerate(["before", "after"]):
        im = load(tag, name)
        label(im, "%s - %s" % (tag.upper(), cap))
        sheet.paste(im, (c * W, r * H))
chim = load("after", "chimney_built_z20")
label(chim, "AFTER - built Ember Hall, open chimney mouth (z20)")
sheet.paste(chim, (0, len(ROWS) * H))
full = Image.open(os.path.join(ROOT, "after", "chimney_built_z20.jpg")).convert("RGB")
crop = full.crop((700, 200, 1180, 470)).resize((W, H), Image.LANCZOS)
label(crop, "AFTER - chimney mouth crop: rounded lip, ember-red floor, coals")
sheet.paste(crop, (W, len(ROWS) * H))
sheet.save(os.path.join(ROOT, "leftovers_sheet.jpg"), quality=88)

full.save(os.path.join(ROOT, "chimney_built_after.png"))
crop.save(os.path.join(ROOT, "chimney_mouth_crop_after.png"))
Image.open(os.path.join(ROOT, "after", "hall00_edge_z8.jpg")).convert("RGB").save(os.path.join(ROOT, "site00_edge_after.png"))
Image.open(os.path.join(ROOT, "after", "hall30_z12.jpg")).convert("RGB").save(os.path.join(ROOT, "site30_after.png"))
print("sheet ok")

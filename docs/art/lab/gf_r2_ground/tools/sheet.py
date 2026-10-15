"""G-F r2 ground contact sheet + key PNGs. Run: python -I docs/art/lab/gf_r2_ground/tools/sheet.py"""
import os
from PIL import Image, ImageDraw
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
PAIRS = [
    ("Spire ring z30 (pulse peak)", "spire_z30_2.jpg", "spire_z30_2.jpg"),
    ("Spire ring z16", "spire_z16_1.jpg", "spire_z16_1.jpg"),
    ("Treant grove + mammoth frost aura z22", "titans_z22_0.jpg", "titans_z22_0.jpg"),
    ("Mammoth frost aura z14", "mammoth_z14.jpg", "mammoth_z14.jpg"),
    ("Road crown grass + butterflies z16", "road_a_z16.jpg", "road_a_z16.jpg"),
    ("Road crown grass z10", "road_a_z10.jpg", "road_a_z10.jpg"),
    ("m00 start z30 (disc = MissionBase.flash_ring, lead)", "m00_z30_1.jpg", "m00_z30_1.jpg"),
]
W, H, L = 800, 450, 24
sheet = Image.new("RGB", (2 * W, len(PAIRS) * (H + L)), (18, 18, 22))
d = ImageDraw.Draw(sheet)
for i, (label, b, a) in enumerate(PAIRS):
    y = i * (H + L)
    for j, (tag, f) in enumerate((("before", b), ("after", a))):
        im = Image.open(os.path.join(ROOT, tag, f)).convert("RGB").resize((W, H))
        sheet.paste(im, (j * W, y + L))
        d.text((j * W + 8, y + 6), "%s - %s" % (label, tag), fill=(235, 235, 235))
sheet.save(os.path.join(ROOT, "gfr2_contact_sheet.jpg"), quality=85)
KEYS = {"key_spire_before_after.png": "spire_z30_2.jpg", "key_mammoth_before_after.png": "mammoth_z14.jpg",
        "key_road_before_after.png": "road_a_z10.jpg"}
for name, f in KEYS.items():
    k = Image.new("RGB", (1280, 360))
    for j, tag in enumerate(("before", "after")):
        k.paste(Image.open(os.path.join(ROOT, tag, f)).convert("RGB").resize((640, 360)), (j * 640, 0))
    k.save(os.path.join(ROOT, name))
Image.open(os.path.join(ROOT, "before", "m00_z30_1.jpg")).convert("RGB").resize((1280, 720)).save(
    os.path.join(ROOT, "key_m00_disc.png"))

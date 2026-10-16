"""G-F Quartermeet contact sheet: columns Ashwind Reach | Quartermeet before | Quartermeet after, one row per view.
Run from the repo root: python docs/art/lab/gf_quartermeet/tools/qm_sheet.py"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
COLS = [("ashwind", "Ashwind Reach (unchanged)"), ("before", "Quartermeet before"), ("after", "Quartermeet after")]
ROWS = ["ingame_z32", "overview", "centre_z35", "field_z36", "edge_z40", "ford_z30"]
W, H, PAD, HEAD = 520, 292, 8, 30

sheet = Image.new("RGB", (PAD + len(COLS) * (W + PAD), HEAD + len(ROWS) * (H + PAD) + PAD), (24, 22, 20))
d = ImageDraw.Draw(sheet)
for c, (tag, title) in enumerate(COLS):
    d.text((PAD + c * (W + PAD) + 6, 9), title, fill=(235, 225, 200))
    for r, name in enumerate(ROWS):
        p = ROOT / tag / f"{name}.jpg"
        x, y = PAD + c * (W + PAD), HEAD + r * (H + PAD)
        if p.exists():
            sheet.paste(Image.open(p).convert("RGB").resize((W, H), Image.LANCZOS), (x, y))
        d.text((x + 6, y + H - 16), name, fill=(255, 255, 255))
sheet.save(ROOT / "qm_contact_sheet.jpg", quality=86)
for tag, name in [("after", "overview"), ("after", "field_z36"), ("after", "centre_z35"), ("before", "overview")]:
    Image.open(ROOT / tag / f"{name}.jpg").convert("RGB").resize((1200, 675), Image.LANCZOS).save(
        ROOT / f"key_{tag}_{name}.png", optimize=True)
print("sheet ok")

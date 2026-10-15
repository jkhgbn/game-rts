"""Quick review grid: python -I grid.py out.jpg cols img1 img2 ... (each tile 800x450, labelled)."""
import sys
from PIL import Image, ImageDraw
out, cols, files = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
W, H = 800, 450
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols * W, rows * (H + 22)), (20, 20, 24))
d = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    im = Image.open(f).convert("RGB").resize((W, H))
    x, y = (i % cols) * W, (i // cols) * (H + 22)
    sheet.paste(im, (x, y + 22))
    d.text((x + 6, y + 4), f.replace("\\", "/").split("/")[-2] + "/" + f.replace("\\", "/").split("/")[-1], fill=(230, 230, 230))
sheet.save(out, quality=88)

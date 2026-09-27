class_name ToolSheet
extends RefCounted
## Shared image sheets for the tools wave (docs/plan/tools-wave.md section 1; API in tools/common/README.md).
## Pure `Image` drawing: works HEADLESS (a built-in 5x7 bitmap font draws labels without any viewport or font file), is
## deterministic (same input = same bytes), and never needs a renderer. Pixels from the 3D world come from
## ToolCapture (windowed); this file lays them out: labelled contact-sheet grid, 2.39 band / safe-area overlay,
## timeline bars, text.

const BAND_COLOR := Color(1.0, 0.85, 0.2)
const SAFE_COLOR := Color(0.3, 0.85, 1.0)
const BG := Color(0.09, 0.09, 0.1)
const FG := Color(0.92, 0.92, 0.92)
const PASS_C := Color(0.4, 0.9, 0.45)
const WARN_C := Color(1.0, 0.8, 0.3)
const FAIL_C := Color(1.0, 0.35, 0.3)

# 5x7 glyphs, one int per row, bit 4 = left column. Lower case draws as upper case.
const GLYPHS := {
	"A": [0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11], "B": [0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E],
	"C": [0x0E, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0E], "D": [0x1E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1E],
	"E": [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F], "F": [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10],
	"G": [0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0F], "H": [0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
	"I": [0x0E, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E], "J": [0x07, 0x02, 0x02, 0x02, 0x02, 0x12, 0x0C],
	"K": [0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11], "L": [0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F],
	"M": [0x11, 0x1B, 0x15, 0x15, 0x11, 0x11, 0x11], "N": [0x11, 0x11, 0x19, 0x15, 0x13, 0x11, 0x11],
	"O": [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E], "P": [0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10],
	"Q": [0x0E, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0D], "R": [0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11],
	"S": [0x0F, 0x10, 0x10, 0x0E, 0x01, 0x01, 0x1E], "T": [0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04],
	"U": [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E], "V": [0x11, 0x11, 0x11, 0x11, 0x11, 0x0A, 0x04],
	"W": [0x11, 0x11, 0x11, 0x15, 0x15, 0x15, 0x0A], "X": [0x11, 0x11, 0x0A, 0x04, 0x0A, 0x11, 0x11],
	"Y": [0x11, 0x11, 0x0A, 0x04, 0x04, 0x04, 0x04], "Z": [0x1F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F],
	"0": [0x0E, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0E], "1": [0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E],
	"2": [0x0E, 0x11, 0x01, 0x02, 0x04, 0x08, 0x1F], "3": [0x1F, 0x02, 0x04, 0x02, 0x01, 0x11, 0x0E],
	"4": [0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02], "5": [0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E],
	"6": [0x06, 0x08, 0x10, 0x1E, 0x11, 0x11, 0x0E], "7": [0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08],
	"8": [0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E], "9": [0x0E, 0x11, 0x11, 0x0F, 0x01, 0x02, 0x0C],
	".": [0, 0, 0, 0, 0, 0x0C, 0x0C], ",": [0, 0, 0, 0, 0x0C, 0x04, 0x08], ":": [0, 0x0C, 0x0C, 0, 0x0C, 0x0C, 0],
	";": [0, 0x0C, 0x0C, 0, 0x0C, 0x04, 0x08], "-": [0, 0, 0, 0x1F, 0, 0, 0], "_": [0, 0, 0, 0, 0, 0, 0x1F],
	"+": [0, 0x04, 0x04, 0x1F, 0x04, 0x04, 0], "/": [0x01, 0x01, 0x02, 0x04, 0x08, 0x10, 0x10],
	"(": [0x02, 0x04, 0x08, 0x08, 0x08, 0x04, 0x02], ")": [0x08, 0x04, 0x02, 0x02, 0x02, 0x04, 0x08],
	"[": [0x0E, 0x08, 0x08, 0x08, 0x08, 0x08, 0x0E], "]": [0x0E, 0x02, 0x02, 0x02, 0x02, 0x02, 0x0E],
	">": [0x08, 0x04, 0x02, 0x01, 0x02, 0x04, 0x08], "<": [0x02, 0x04, 0x08, 0x10, 0x08, 0x04, 0x02],
	"=": [0, 0, 0x1F, 0, 0x1F, 0, 0], "!": [0x04, 0x04, 0x04, 0x04, 0x04, 0, 0x04],
	"?": [0x0E, 0x11, 0x01, 0x02, 0x04, 0, 0x04], "'": [0x04, 0x04, 0x08, 0, 0, 0, 0],
	"\"": [0x0A, 0x0A, 0, 0, 0, 0, 0], "%": [0x18, 0x19, 0x02, 0x04, 0x08, 0x13, 0x03],
	"#": [0x0A, 0x0A, 0x1F, 0x0A, 0x1F, 0x0A, 0x0A], "@": [0x0E, 0x11, 0x01, 0x0D, 0x15, 0x15, 0x0E],
	"*": [0, 0x04, 0x15, 0x0E, 0x15, 0x04, 0], "|": [0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04],
	"&": [0x0C, 0x12, 0x14, 0x08, 0x15, 0x12, 0x0D], "~": [0, 0, 0x08, 0x15, 0x02, 0, 0],
	"^": [0x04, 0x0A, 0x11, 0, 0, 0, 0],
}


static func new_image(w: int, h: int, bg: Color = BG) -> Image:
	var img := Image.create(maxi(1, w), maxi(1, h), false, Image.FORMAT_RGBA8)
	img.fill(bg)
	return img


## Draws `s` at (x, y) (top-left) with the 5x7 font, `scale` px per font pixel. Returns the drawn width in px.
static func text(img: Image, x: int, y: int, s: String, color: Color = FG, scale: int = 2) -> int:
	var cx := x
	for ch: String in s:
		var g: Variant = GLYPHS.get(ch.to_upper(), null)
		if g != null:
			var rows: Array = g
			for r: int in 7:
				var bits: int = rows[r]
				for c: int in 5:
					if bits & (0x10 >> c):
						_fill(img, cx + c * scale, y + r * scale, scale, scale, color)
		cx += 6 * scale
	return cx - x


static func text_width(s: String, scale: int = 2) -> int:
	return s.length() * 6 * scale


## Line height of the font at `scale` (glyph + 2 px gap).
static func line_h(scale: int = 2) -> int:
	return 7 * scale + 2 * scale + 2


## Cuts `s` to at most `max_px` wide (adds ".." when cut).
static func clip(s: String, max_px: int, scale: int = 2) -> String:
	var n := maxi(0, max_px / (6 * scale))
	return s if s.length() <= n else s.left(maxi(0, n - 2)) + ".."


## Filled rectangle (alpha < 1 blends over the image).
static func rect(img: Image, r: Rect2i, color: Color) -> void:
	_fill(img, r.position.x, r.position.y, r.size.x, r.size.y, color)


## Outline of a rectangle, `t` px thick.
static func frame(img: Image, r: Rect2i, color: Color, t: int = 2) -> void:
	_fill(img, r.position.x, r.position.y, r.size.x, t, color)
	_fill(img, r.position.x, r.end.y - t, r.size.x, t, color)
	_fill(img, r.position.x, r.position.y, t, r.size.y, color)
	_fill(img, r.end.x - t, r.position.y, t, r.size.y, color)


static func _fill(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var x0 := clampi(x, 0, img.get_width())
	var y0 := clampi(y, 0, img.get_height())
	var x1 := clampi(x + w, 0, img.get_width())
	var y1 := clampi(y + h, 0, img.get_height())
	if x1 <= x0 or y1 <= y0:
		return
	if color.a >= 0.999:
		img.fill_rect(Rect2i(x0, y0, x1 - x0, y1 - y0), color)
		return
	for yy: int in range(y0, y1):
		for xx: int in range(x0, x1):
			img.set_pixel(xx, yy, img.get_pixel(xx, yy).blend(color))


## Height in px of each letterbox bar for a W x H image (cinematics.md 6.1: max((H - W / A) / 2, 3 % of H)).
static func bar_px(size: Vector2i, aspect: float = 2.39) -> int:
	if aspect <= 0.0:
		return 0
	return int(round(maxf((float(size.y) - float(size.x) / aspect) * 0.5, 0.03 * float(size.y))))


## The 2.39 band as a rect of the image (what the player sees between the bars).
static func band_rect(size: Vector2i, aspect: float = 2.39) -> Rect2i:
	var b := bar_px(size, aspect)
	return Rect2i(0, b, size.x, size.y - 2 * b)


## Safe area: `safe` (0-1) of the band, centred (faces and key action belong inside it).
static func safe_rect(size: Vector2i, aspect: float = 2.39, safe: float = 0.9) -> Rect2i:
	var band := band_rect(size, aspect)
	var w := int(band.size.x * safe)
	var h := int(band.size.y * safe)
	return Rect2i(band.position.x + (band.size.x - w) / 2, band.position.y + (band.size.y - h) / 2, w, h)


## Draws the letterbox view on a still: the bars' area darkened (not black: you still see what they hide), the band edges
## in yellow and the safe area in cyan. Modifies `img` in place and returns it.
static func band_overlay(img: Image, aspect: float = 2.39, safe: float = 0.9, darken: float = 0.6) -> Image:
	var size := Vector2i(img.get_width(), img.get_height())
	var band := band_rect(size, aspect)
	var shade := Color(0, 0, 0, darken)
	rect(img, Rect2i(0, 0, size.x, band.position.y), shade)
	rect(img, Rect2i(0, band.end.y, size.x, size.y - band.end.y), shade)
	var t := maxi(1, size.y / 450)
	rect(img, Rect2i(0, band.position.y - t, size.x, t), BAND_COLOR)
	rect(img, Rect2i(0, band.end.y, size.x, t), BAND_COLOR)
	frame(img, safe_rect(size, aspect, safe), Color(SAFE_COLOR, 0.7), t)
	return img


## Resized copy that fits inside w x h (keeps the aspect).
static func fit(src: Image, w: int, h: int) -> Image:
	var img := src.duplicate() as Image
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var k := minf(float(w) / img.get_width(), float(h) / img.get_height())
	img.resize(maxi(1, int(img.get_width() * k)), maxi(1, int(img.get_height() * k)), Image.INTERPOLATE_BILINEAR)
	return img


## Labelled contact sheet. tiles = [{img: Image, label: String, color?: Color (label colour), mark?: Color (tile frame)}].
## `header` lines are drawn on top (first line bigger). Tile size = `tile_w` wide, height from the first tile's aspect.
static func grid(tiles: Array, cols: int, tile_w: int = 400, header: Array = [], title: String = "") -> Image:
	var aspect := 16.0 / 9.0
	if not tiles.is_empty() and (tiles[0] as Dictionary).get("img") is Image:
		var i0: Image = (tiles[0] as Dictionary)["img"]
		aspect = float(i0.get_width()) / maxf(1.0, float(i0.get_height()))
	var tile_h := int(tile_w / aspect)
	var lab := line_h(2) + 4
	var head := 14
	if title != "":
		head += line_h(3) + 4
	head += header.size() * line_h(2)
	head += 8
	var rows := (tiles.size() + cols - 1) / maxi(1, cols)
	var img := new_image(cols * (tile_w + 8) + 8, head + rows * (tile_h + lab + 8) + 8)
	var y := 10
	if title != "":
		text(img, 10, y, clip(title, img.get_width() - 20, 3), FG, 3)
		y += line_h(3) + 4
	for h: Variant in header:
		var hs := String(h)
		var col := FG
		if hs.begins_with("FAIL"):
			col = FAIL_C
		elif hs.begins_with("WARN"):
			col = WARN_C
		elif hs.begins_with("PASS"):
			col = PASS_C
		text(img, 10, y, clip(hs, img.get_width() - 20, 2), col, 2)
		y += line_h(2)
	for i: int in tiles.size():
		var t: Dictionary = tiles[i]
		var x := 8 + (i % cols) * (tile_w + 8)
		var ty := head + (i / cols) * (tile_h + lab + 8)
		if t.get("img") is Image:
			var f := fit(t["img"], tile_w, tile_h)
			img.blit_rect(f, Rect2i(0, 0, f.get_width(), f.get_height()), Vector2i(x + (tile_w - f.get_width()) / 2, ty))
		else:
			rect(img, Rect2i(x, ty, tile_w, tile_h), Color(0.2, 0.2, 0.22))
			text(img, x + 8, ty + tile_h / 2 - 7, "NO IMAGE", WARN_C, 2)
		if t.has("mark"):
			frame(img, Rect2i(x, ty, tile_w, tile_h), t["mark"], 3)
		text(img, x + 2, ty + tile_h + 4, clip(String(t.get("label", "")), tile_w - 4, 2), t.get("color", FG), 2)
	return img


## Saves a PNG (creates the folder). Returns the error code.
static func save_png(img: Image, path: String) -> int:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	return img.save_png(path)

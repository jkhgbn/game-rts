extends RefCounted
## World Forge picture helpers (map-production.md 2.6, tool tasks MT5 / MT7): the `gen` contact sheet (headless:
## layout plan + heat map + scores per candidate, captions in a built-in 5 x 7 pixel font) and text on images.
## No class_name on purpose (preloaded tool script).

const GLYPH_W := 5
const GLYPH_H := 7
## 5 x 7 glyphs, one string of 7 rows of 5 bits each ("1" = ink).
const FONT := {
	"0": "01110100011001110101110011000101110", "1": "00100011000010000100001000010001110",
	"2": "01110100010000100010001000100011111", "3": "11110000010000101110000010000111110",
	"4": "00010001100101010010111110001000010", "5": "11111100001111000001000011000101110",
	"6": "00110010001000011110100011000101110", "7": "11111000010001000100010000100001000",
	"8": "01110100011000101110100011000101110", "9": "01110100011000101111000010001001100",
	"A": "01110100011000111111100011000110001", "B": "11110100011000111110100011000111110",
	"C": "01110100011000010000100001000101110", "D": "11100100101000110001100011001011100",
	"E": "11111100001000011110100001000011111", "F": "11111100001000011110100001000010000",
	"G": "01110100011000010111100011000101111", "H": "10001100011000111111100011000110001",
	"I": "01110001000010000100001000010001110", "J": "00111000100001000010000101001001100",
	"K": "10001100101010011000101001001010001", "L": "10000100001000010000100001000011111",
	"M": "10001110111010110101100011000110001", "N": "10001100011100110101100111000110001",
	"O": "01110100011000110001100011000101110", "P": "11110100011000111110100001000010000",
	"Q": "01110100011000110001101011001001101", "R": "11110100011000111110101001001010001",
	"S": "01111100001000001110000010000111110", "T": "11111001000010000100001000010000100",
	"U": "10001100011000110001100011000101110", "V": "10001100011000110001100010101000100",
	"W": "10001100011000110101101011010101010", "X": "10001100010101000100010101000110001",
	"Y": "10001100010101000100001000010000100", "Z": "11111000010001000100010001000011111",
	".": "00000000000000000000000000110001100", ":": "00000011000110000000011000110000000",
	"-": "00000000000000011111000000000000000", "/": "00001000010001000100010001000010000",
	"%": "11000110010001000100010001001100011", "_": "00000000000000000000000000000011111",
	"(": "00010001000100001000010000010000010", ")": "01000001000001000010000100010001000",
	"=": "00000000001111100000111110000000000", "+": "00000001000010011111001000010000000",
	" ": "00000000000000000000000000000000000",
}


## Draws `text` (upper-cased; unknown characters = blank) at `pos` with pixel `scale`.
static func draw_text(img: Image, text: String, pos: Vector2i, color: Color, scale: int = 2) -> void:
	var x := pos.x
	for ch in text.to_upper():
		var g: String = FONT.get(ch, FONT[" "])
		for row in GLYPH_H:
			for col in GLYPH_W:
				if g[row * GLYPH_W + col] == "1":
					img.fill_rect(Rect2i(x + col * scale, pos.y + row * scale, scale, scale), color)
		x += (GLYPH_W + 1) * scale


static func text_width(text: String, scale: int = 2) -> int:
	return text.length() * (GLYPH_W + 1) * scale


## A PNG on disk as an RGBA8 image resized to `w` x `h` (a grey placeholder when it is missing).
static func load_fit(path: String, w: int, h: int) -> Image:
	var img: Image = null
	if FileAccess.file_exists(path):
		img = Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		img = Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.2, 0.2, 0.2))
		draw_text(img, "MISSING", Vector2i(8, 8), Color(1, 0.4, 0.4), 3)
		return img
	img.convert(Image.FORMAT_RGBA8)
	img.resize(w, h, Image.INTERPOLATE_BILINEAR)
	return img


## The `gen` contact sheet: one column per candidate (plan on top, heat map below, caption with the seed, the Map
## Lab score / result, the grid score and the main measures). entries: [{title, plan, heat, lab_score, lab_result,
## grid_score, lines: [String]}].
static func contact_sheet(entries: Array, title: String) -> Image:
	var cw := 512
	var cap := 150
	var head := 40
	var img := Image.create(cw * maxi(1, entries.size()) + 8 * (entries.size() + 1), head + cw * 2 + cap + 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.09, 0.1))
	draw_text(img, title, Vector2i(10, 10), Color(0.95, 0.9, 0.7), 3)
	for k in entries.size():
		var e: Dictionary = entries[k]
		var x := 8 + k * (cw + 8)
		img.blit_rect(load_fit(String(e.get("plan", "")), cw, cw), Rect2i(0, 0, cw, cw), Vector2i(x, head))
		img.blit_rect(load_fit(String(e.get("heat", "")), cw, cw), Rect2i(0, 0, cw, cw), Vector2i(x, head + cw + 4))
		var y := head + cw * 2 + 10
		var score := float(e.get("lab_score", -1.0))
		var ok := String(e.get("lab_result", "")) != "FAIL" and score >= 75.0
		draw_text(img, String(e.get("title", "")), Vector2i(x, y), Color(1, 1, 1), 2)
		draw_text(img, "LAB %s %.0f" % [String(e.get("lab_result", "-")), score], Vector2i(x, y + 22),
				Color(0.4, 1.0, 0.5) if ok else Color(1.0, 0.45, 0.4), 3)
		# score bar (75 = the acceptance bar)
		var bw := int(cw * clampf(score, 0.0, 100.0) / 100.0)
		img.fill_rect(Rect2i(x, y + 50, cw, 8), Color(0.25, 0.25, 0.25))
		img.fill_rect(Rect2i(x, y + 50, bw, 8), Color(0.4, 0.9, 0.5) if ok else Color(0.9, 0.4, 0.35))
		img.fill_rect(Rect2i(x + int(cw * 0.75), y + 46, 2, 16), Color(1, 1, 1))
		var ly := y + 66
		for l: String in e.get("lines", []):
			draw_text(img, l, Vector2i(x, ly), Color(0.8, 0.85, 0.9), 2)
			ly += 18
	return img

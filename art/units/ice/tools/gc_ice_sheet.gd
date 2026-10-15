extends SceneTree
## G-C Ice units: one contact sheet JPG from the shots (docs/art/gc_ice_units.md). Headless is fine (images only):
##   tools\godot_run.ps1 --headless --path . -s res://art/units/ice/tools/gc_ice_sheet.gd --quit-after 600
## Left column = before (the G3b shots: docs/art/lab/g3b_materials/shots/after_*), right column = after (G-C, High).
## -> docs/art/lab/gc_ice/gc_ice_contact_sheet.jpg (2 x 4 tiles, 800 x 450 each, labelled by row order in the doc).

const G3B := "res://docs/art/lab/g3b_materials/shots/"
const GC := "res://docs/art/lab/gc_ice/shots/"
const OUT := "res://docs/art/lab/gc_ice/gc_ice_contact_sheet.jpg"
const TILE := Vector2i(800, 450)
const PAIRS: Array = [
	["after_close_ice.png", "high_g3b_close_ice.png"],
	["after_portrait_ice.png", "high_g3b_portrait_ice.png"],
	["after_army_z30_crop2x.png", "high_g3b_army_z30_crop2x.png"],
	["", "high_army_snow_z10.png"],
]


func _initialize() -> void:
	var sheet := Image.create(TILE.x * 2, TILE.y * PAIRS.size(), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.1, 0.1, 0.12))
	for r: int in PAIRS.size():
		for c: int in 2:
			var name: String = PAIRS[r][c]
			if name == "":
				if r == PAIRS.size() - 1:
					name = "high_army_meadow_z10.png"
				else:
					continue
			var dir := G3B if c == 0 and PAIRS[r][0] != "" else GC
			var p := ProjectSettings.globalize_path(dir + name)
			var img := Image.load_from_file(p)
			if img == null or img.is_empty():
				print("GC ICE SHEET: missing ", p)
				continue
			img.convert(Image.FORMAT_RGB8)
			img.resize(TILE.x, TILE.y, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(img, Rect2i(Vector2i.ZERO, TILE), Vector2i(c * TILE.x, r * TILE.y))
	var out := ProjectSettings.globalize_path(OUT)
	sheet.save_jpg(out, 0.85)
	print("GC ICE SHEET ", out)
	quit(0)

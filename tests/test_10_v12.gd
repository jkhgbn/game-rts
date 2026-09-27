extends SceneTree
## Task 10.V12 (trade icons): every icon of ui-trade.md 15 / market-trade.md 9 exists at art/icons/<kind>/<id>.png,
## loads, is 128 x 128, is not blank (enough opaque pixels, real detail rather than a flat fill or a bare halo), and
## IconLibrary.icon_for finds it (plural kinds and the singular aliases).
## Run: godot --headless --path . -s tests/test_10_v12.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "10.v12"
## [kind, id, min opaque fraction]. Portraits and signs fill the square; orders / wares / glyphs are cut-outs.
const ICONS: Array = [
	[&"units", &"caravan", 0.95], [&"units", &"magpie", 0.95], [&"units", &"greywater_tracker", 0.95],
	[&"buildings", &"fire_market", 0.95], [&"buildings", &"shadow_market", 0.95], [&"buildings", &"ice_market", 0.95],
	[&"buildings", &"nature_market", 0.95], [&"buildings", &"magpie_den", 0.95], [&"buildings", &"greywater_lodge", 0.95],
	[&"posts", &"heron_ford", 0.55], [&"posts", &"millstone_cross", 0.55], [&"posts", &"lantern_wharf", 0.55],
	[&"posts", &"saltgate", 0.55],
	[&"wares", &"iron_axles", 0.3], [&"wares", &"masons_charter", 0.3], [&"wares", &"tempered_steel", 0.3],
	[&"wares", &"gambesons", 0.3],
	[&"contracts", &"outriders", 0.3], [&"contracts", &"sweep", 0.2],
	[&"orders", &"trade", 0.3], [&"orders", &"route", 0.2], [&"orders", &"wares", 0.3],
	[&"ui", &"gold_coin", 0.5], [&"ui", &"exchange_crystals", 0.2], [&"ui", &"exchange_essence", 0.2],
	[&"ui", &"crest_bazaar", 0.5], [&"ui", &"crest_lodge", 0.5],
]
## Mean |luminance step| between neighbouring pixels: a painted icon with ink outlines is far above this; a flat
## fill or the bare portrait halo (a model that failed to render) is far below.
const MIN_DETAIL := 0.012


func _initialize() -> void:
	var fails: Array[String] = []
	for e: Array in ICONS:
		var err: String = _check(e[0], e[1], float(e[2]))
		if err != "":
			fails.append("%s/%s: %s" % [e[0], e[1], err])
	for alias: Array in [[&"post", &"saltgate"], [&"ware", &"gambesons"], [&"contract", &"sweep"], [&"unit", &"magpie"]]:
		if IconLibrary.icon_for(alias[0], alias[1]) == null:
			fails.append("IconLibrary alias %s/%s not found" % alias)
	if fails.is_empty():
		print("PASS %s (%d icons)" % [TASK_ID, ICONS.size()])
	else:
		for f in fails:
			print("  ", f)
		print("FAIL %s: %d problem(s)" % [TASK_ID, fails.size()])
	quit()


func _check(kind: StringName, id: StringName, min_opaque: float) -> String:
	var path: String = "res://art/icons/%s/%s.png" % [kind, id]
	if not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		return "missing file"
	if ResourceLoader.exists(path) and not (load(path) is Texture2D):
		return "does not load as a texture"
	# Pixels from the PNG itself: the imported copy can be older than a fresh render.
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null or img.is_empty():
		return "empty image"
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	if img.get_width() != 128 or img.get_height() != 128:
		return "size %dx%d" % [img.get_width(), img.get_height()]
	var opaque: int = 0
	var detail: float = 0.0
	var samples: int = 0
	for y in 128:
		for x in 128:
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.5:
				opaque += 1
			if x < 127 and y < 127:
				var l: float = c.get_luminance() * c.a
				var r: Color = img.get_pixel(x + 1, y)
				var d: Color = img.get_pixel(x, y + 1)
				detail += absf(l - r.get_luminance() * r.a) + absf(l - d.get_luminance() * d.a)
				samples += 1
	var frac: float = float(opaque) / (128.0 * 128.0)
	detail /= float(samples)
	if frac < min_opaque:
		return "only %.0f %% opaque (want >= %.0f %%)" % [frac * 100.0, min_opaque * 100.0]
	if detail < MIN_DETAIL:
		return "blank (detail %.4f < %.4f)" % [detail, MIN_DETAIL]
	var tex: Texture2D = IconLibrary.icon_for(kind, id)
	if tex == null:
		return "IconLibrary.icon_for returned null"
	if tex.get_width() != 128:
		return "IconLibrary texture is %d wide" % tex.get_width()
	return ""

extends SceneTree
## Task 11.V7: 4 class icons + 12 class-skill icons (skills-rework.md 4.2, ui-champions.md 15.1 / 15.6).
## Run:  godot --headless --path . -s tests/test_11_v7.gd --fixed-fps 60 --quit-after 600
## Checks: the 16 PNGs exist and are imported, load as Texture2D 128 x 128, are not blank, IconLibrary.icon_for finds
## them (kinds "classes" and "abilities" / "ability"), the class glyphs keep contrast at 14 px (the bar badge), the four
## class colour codes differ, every skill wears its own class colour, and no two icons are the same picture.

const TASK_ID := "11.v7"
const CLASSES: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard"]
const SKILLS := {
	&"spear": [&"lunge", &"hobbling_javelin", &"skewer"],
	&"sword_shield": [&"riposte", &"second_wind", &"shield_throw"],
	&"two_hand": [&"cleave", &"crushing_blow", &"whirlwind"],
	&"wizard": [&"arc_bolt", &"slipstep", &"starfall"],
}

var _fails: Array[String] = []
var _images: Dictionary = {}  # id -> Image (RGBA8, 128)


func _initialize() -> void:
	var n: int = 0
	for cid in CLASSES:
		_check_file("res://art/icons/classes/%s.png" % cid, cid)
		n += 1
		for sid in SKILLS[cid]:
			_check_file("res://art/icons/abilities/%s.png" % sid, sid)
			n += 1
	print("checked %d icon files" % n)
	_check_library()
	_check_small_sizes()
	_check_colours()
	_check_distinct()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  " + f)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _fails.size()])
	quit()


func _check_file(p: String, id: StringName) -> void:
	if not FileAccess.file_exists(p):
		_fails.append("missing " + p)
		return
	if not ResourceLoader.exists(p):
		_fails.append("not imported " + p)
		return
	var t := load(p) as Texture2D
	if t == null:
		_fails.append("not a Texture2D " + p)
		return
	if t.get_width() != 128 or t.get_height() != 128:
		_fails.append("%s is %dx%d, want 128x128" % [p, t.get_width(), t.get_height()])
	var img: Image = t.get_image()
	if img == null or img.is_empty():
		_fails.append("no image data " + p)
		return
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var r: Vector2 = _lum_range(img, 4)
	if r.y - r.x < 0.3:
		_fails.append("%s looks blank (luminance %.2f-%.2f)" % [p, r.x, r.y])
	_images[id] = img


func _lum_range(img: Image, step: int) -> Vector2:
	var lo := 1.0
	var hi := 0.0
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			var l: float = img.get_pixel(x, y).get_luminance()
			lo = minf(lo, l)
			hi = maxf(hi, l)
	return Vector2(lo, hi)


func _check_library() -> void:
	var lib: Script = load("res://art/icons/icon_library.gd")
	for cid in CLASSES:
		var t: Texture2D = lib.call(&"icon_for", &"classes", cid)
		if t == null:
			_fails.append("IconLibrary.icon_for(classes, %s) is null" % cid)
		elif t.get_width() != 128:
			_fails.append("IconLibrary.icon_for(classes, %s) is %d wide" % [cid, t.get_width()])
		for sid in SKILLS[cid]:
			if lib.call(&"icon_for", &"abilities", sid) == null:
				_fails.append("IconLibrary.icon_for(abilities, %s) is null" % sid)
			if lib.call(&"icon_for", &"ability", sid) == null:
				_fails.append("IconLibrary alias 'ability' fails for %s" % sid)


## The badge draws the class icon at 14 px (mipmapped): the glyph must still carry light-on-dark contrast there,
## and the skills must keep it in their 40 px slot and at 36 / 32 px.
func _check_small_sizes() -> void:
	for cid in CLASSES:
		if not _images.has(cid):
			continue
		var s: Image = (_images[cid] as Image).duplicate()
		s.resize(14, 14, Image.INTERPOLATE_CUBIC)
		var r: Vector2 = _lum_range(s, 1)
		if r.y - r.x < 0.4:
			_fails.append("class %s: only %.2f luminance range at 14 px" % [cid, r.y - r.x])
		# A bright glyph: at least 8 of the 196 pixels clearly light (the weapon), at least 40 dark (the background).
		var light: int = 0
		var dark: int = 0
		for y in 14:
			for x in 14:
				var l: float = s.get_pixel(x, y).get_luminance()
				if l > 0.55:
					light += 1
				elif l < 0.3:
					dark += 1
		if light < 8 or dark < 40:
			_fails.append("class %s at 14 px: %d light / %d dark pixels" % [cid, light, dark])
		for sid in SKILLS[cid]:
			if not _images.has(sid):
				continue
			for size in [40, 36, 32]:
				var a: Image = (_images[sid] as Image).duplicate()
				a.resize(size, size, Image.INTERPOLATE_CUBIC)
				var ar: Vector2 = _lum_range(a, 1)
				if ar.y - ar.x < 0.45:
					_fails.append("%s: only %.2f luminance range at %d px" % [sid, ar.y - ar.x, size])


## Mean of the coloured pixels (saturation > 0.35): the class colour code, without the pale steel / grey parts.
func _mean(img: Image) -> Color:
	var s: Image = img.duplicate()
	s.resize(32, 32, Image.INTERPOLATE_BILINEAR)
	var acc := Vector3.ZERO
	var n: int = 0
	for y in 32:
		for x in 32:
			var c: Color = s.get_pixel(x, y)
			if c.s > 0.35 and c.v > 0.15:
				acc += Vector3(c.r, c.g, c.b)
				n += 1
	if n == 0:
		return Color.BLACK
	acc /= float(n)
	return Color(acc.x, acc.y, acc.z)


## Hue distance in degrees (0-180) between two colour codes.
func _dist(a: Color, b: Color) -> float:
	var d: float = absf(a.h - b.h)
	return minf(d, 1.0 - d) * 360.0


## Class colour codes: the four class icons differ in colour, and each skill is closest to its own class.
func _check_colours() -> void:
	var means: Dictionary = {}
	for cid in CLASSES:
		if _images.has(cid):
			means[cid] = _mean(_images[cid])
	if means.size() != CLASSES.size():
		return
	for i in CLASSES.size():
		for j in range(i + 1, CLASSES.size()):
			var d: float = _dist(means[CLASSES[i]], means[CLASSES[j]])
			if d < 25.0:
				_fails.append("classes %s and %s have too close hues (%.0f degrees)" % [CLASSES[i], CLASSES[j], d])
	for cid in CLASSES:
		for sid in SKILLS[cid]:
			if not _images.has(sid):
				continue
			var m: Color = _mean(_images[sid])
			var best: StringName = &""
			var best_d: float = INF
			for other in CLASSES:
				var d: float = _dist(m, means[other])
				if d < best_d:
					best_d = d
					best = other
			if best != cid:
				_fails.append("%s reads as %s's colour, not %s's" % [sid, best, cid])
	print("class mean colours: %s" % [means])


## No two of the 16 icons are the same picture (no fallback emblem left).
func _check_distinct() -> void:
	var ids: Array = _images.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Image = (_images[ids[i]] as Image).duplicate()
			var b: Image = (_images[ids[j]] as Image).duplicate()
			a.resize(32, 32, Image.INTERPOLATE_BILINEAR)
			b.resize(32, 32, Image.INTERPOLATE_BILINEAR)
			var diff: float = 0.0
			for y in 32:
				for x in 32:
					var ca: Color = a.get_pixel(x, y)
					var cb: Color = b.get_pixel(x, y)
					diff += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			diff /= 32.0 * 32.0 * 3.0
			if diff < 0.03:
				_fails.append("%s and %s look the same (mean diff %.3f)" % [ids[i], ids[j], diff])

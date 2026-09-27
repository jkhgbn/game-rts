class_name GroundParams
extends RefCounted
## Uniform values for the ground shader's 12.V2 layers (river cut, wet banks, biome tints) and a CPU mirror of the
## cut, so systems code (RiverSystem 12.C1, `shader_params()` / `EnvProps.set_river`) and art tools (12.V6 scatter)
## agree with what the ground draws. Reach it with `load()` (step-12 rule), e.g.
##     var gp: GDScript = load("res://art/environment/ground_params.gd")
##     gp.apply(ground_mat, gp.river(polylines, 2.5, moat, circles))
##     gp.apply(ground_mat, gp.skirmish_biomes())
## Keys of the dictionaries = the ground shader uniform names (map-fill.md 10, row 12.V2):
##   river_segs        PackedVector4Array (16 slots) of segments (a.x, a.z, b.x, b.z), world x/z
##   river_count       int, used slots (0 = no river)
##   river_half_width  float (2.5)
##   river_box         Vector4 (min x, min z, max x, max z): perf only, the segments' box grown by half width + 10.5 m
##                     (outside it the shader skips the segment loop); Vector4.ZERO = no box
##   moat              Vector4 (centre x, centre z, centre-line radius, half width) (0, 0, 12.75, 1.75); radius 0 = none
##   fords             PackedVector4Array (4 slots) of uncut circles (x, z, r, 0): the fords and the Crown Steps
##   ford_count        int (not a ground uniform: the 12.V1 water materials read it with the same `fords`)
##   biome_*           see skirmish_biomes()
## Missions keep the defaults of ground_material.tres (no river, no biomes) unless they set their own values.

const GROUND_SHADER := "res://art/environment/ground.gdshader"
const RIVER_SLOTS := 16
const FORD_SLOTS := 4
const RUIN_SLOTS := 8
const BIOME_DIR := "res://art/environment/biomes/"
const BOX_REACH := 10.5   ## river_box margin beyond the half width (biome_bank_reach 6 + blend / 2 + jitter)

## map-fill.md 2.1: north river N0 (2 m outside the map, under the north cliffs) .. N5 (on the moat centre line).
const RIVER_N: Array[Vector2] = [Vector2(-15, -62), Vector2(-12, -48.7), Vector2(-9, -38), Vector2(-8, -30),
	Vector2(-5, -21), Vector2(-2.5, -12.5)]
const HALF_WIDTH := 2.5
const MOAT := Vector4(0, 0, 12.75, 1.75)
## map-fill.md 2.2: Reed Ford, Willow Ford (r 3.5), North-west / South-east Crown Steps (r 3.0).
const CIRCLES: Array[Vector4] = [Vector4(-8.5, -34, 3.5, 0), Vector4(8.5, 34, 3.5, 0), Vector4(-9.02, -9.02, 3.0, 0),
	Vector4(9.02, 9.02, 3.0, 0)]
## Biome zones of map-fill.md 3.1 (Crown Hollow).
const HUBS := Vector4(-36, 36, 36, -36)
const HUB_RADIUS := 22.0
const WOODS := Vector4(-50, -50, 50, 50)
const WOOD_RADIUS := 28.0
const HEATH_EDGE := 44.0
const BANK_REACH := 6.0
const BLEND := 4.0
## Crown Isle ruins (r < 11) + 3 m around the landmarks of map-fill.md 3.2 on dry land (Fallen Colossus r 3.5,
## Giant's Stump r 2.0 (roots 3.6: 5.0), Standing Stones ring 3 + 0.5), each with its point mirror. The aqueduct
## stands on the riverbank and the barge in the water: not ruins ground.
const RUINS: Array[Vector4] = [Vector4(0, 0, 11.0, 0), Vector4(-57, -16, 6.5, 0), Vector4(57, 16, 6.5, 0),
	Vector4(-30, 20, 5.0, 0), Vector4(30, -20, 5.0, 0), Vector4(-54, 20, 6.5, 0), Vector4(54, -20, 6.5, 0)]
## biome_tints order and the biome set whose GROUND_TINT fills each slot (fallback = the shader's default).
const TINT_SETS: Array[String] = ["meadow", "heath", "old_wood", "riverbank"]
const TINT_FALLBACK: Array[Color] = [Color(0.40, 0.56, 0.20), Color(0.50, 0.46, 0.26), Color(0.18, 0.22, 0.13),
	Color(0.17, 0.32, 0.18)]


## River uniforms from centre-line polylines (world x/z, any direction), the half width, the moat ring and the
## uncut circles (fords, Crown Steps). Segments beyond 16 / circles beyond 4 are dropped with a warning.
static func river(polylines: Array, half_width: float, moat: Vector4, circles: Array) -> Dictionary:
	var segs := PackedVector4Array()
	for path: Variant in polylines:
		var pts: PackedVector2Array = PackedVector2Array(path)
		for i: int in pts.size() - 1:
			segs.append(Vector4(pts[i].x, pts[i].y, pts[i + 1].x, pts[i + 1].y))
	if segs.size() > RIVER_SLOTS:
		push_warning("GroundParams: %d river segments, the ground draws the first %d" % [segs.size(), RIVER_SLOTS])
	var count: int = mini(segs.size(), RIVER_SLOTS)
	segs.resize(RIVER_SLOTS)
	# Perf box of the used segments, grown by the half width + the farthest the look reads the river distance
	# (riverbank biome 6 m + half the blend + the border jitter).
	var box := Vector4.ZERO
	if count > 0:
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for i: int in count:
			for q: Vector2 in [Vector2(segs[i].x, segs[i].y), Vector2(segs[i].z, segs[i].w)]:
				lo = lo.min(q)
				hi = hi.max(q)
		var m: float = half_width + BOX_REACH
		box = Vector4(lo.x - m, lo.y - m, hi.x + m, hi.y + m)
	var f := PackedVector4Array()
	for c: Variant in circles:
		if f.size() < FORD_SLOTS:
			f.append(c as Vector4)
	var n_fords: int = f.size()
	if circles.size() > FORD_SLOTS:
		push_warning("GroundParams: %d uncut circles, the ground keeps the first %d" % [circles.size(), FORD_SLOTS])
	f.resize(FORD_SLOTS)
	return {
		&"river_segs": segs,
		&"river_count": count,
		&"river_half_width": half_width,
		&"river_box": box,
		&"moat": moat,
		&"fords": f,
		&"ford_count": n_fords,
	}


## Crown Hollow's river (map-fill.md 2.1 / 2.2): the north river N0-N5, its point mirror, the moat, 4 circles.
static func skirmish_river() -> Dictionary:
	return river([PackedVector2Array(RIVER_N), mirrored(PackedVector2Array(RIVER_N))], HALF_WIDTH, MOAT, CIRCLES)


## The point mirror of a polyline, in downstream order (the south river flows from S5 at the moat to S0).
static func mirrored(path: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in range(path.size() - 1, -1, -1):
		out.append(-path[i])
	return out


## Crown Hollow's biome uniforms (map-fill.md 3.1): zones, ruins circles, tints from the biome sets' GROUND_TINT.
static func skirmish_biomes(amount: float = 1.0) -> Dictionary:
	var ruins := PackedVector4Array(RUINS)
	var n_ruins: int = ruins.size()
	ruins.resize(RUIN_SLOTS)
	return {
		&"biome_amount": amount,
		&"biome_tints": biome_tints(),
		&"biome_hubs": HUBS,
		&"biome_hub_radius": HUB_RADIUS,
		&"biome_woods": WOODS,
		&"biome_wood_radius": WOOD_RADIUS,
		&"biome_heath_edge": HEATH_EDGE,
		&"biome_bank_reach": BANK_REACH,
		&"biome_blend": BLEND,
		&"biome_ruins": ruins,
		&"biome_ruin_count": n_ruins,
	}


## biome_tints (meadow, heath, old wood, riverbank) as a PackedColorArray (sRGB; the renderer linearises it, the
## uniform is `source_color`): each biome set's GROUND_TINT when its set file exists, else the shader's default.
static func biome_tints() -> PackedColorArray:
	var out := PackedColorArray()
	for i: int in TINT_SETS.size():
		var c: Color = TINT_FALLBACK[i]
		var path: String = BIOME_DIR + TINT_SETS[i] + "/" + TINT_SETS[i] + "_set.gd"
		if ResourceLoader.exists(path):
			var s: Script = load(path) as Script
			if s != null:
				var consts: Dictionary = s.get_script_constant_map()
				if consts.get("GROUND_TINT") is Color:
					c = consts["GROUND_TINT"]
		out.append(Color(c.r, c.g, c.b))
	return out


## Sets every key of `params` that the material's shader declares (unknown keys are skipped). Returns false and
## changes nothing when the shader has no `river_segs` (an older ground shader).
static func apply(mat: ShaderMaterial, params: Dictionary) -> bool:
	if mat == null or mat.shader == null:
		return false
	var names: Dictionary = uniform_names(mat.shader)
	if not names.has("river_segs"):
		return false
	for k: Variant in params:
		if names.has(String(k)):
			mat.set_shader_parameter(StringName(k), params[k])
	return true


## Uniform names of a shader (the renderer's list; the headless dummy may list none: then the source is read).
static func uniform_names(sh: Shader) -> Dictionary:
	var names := {}
	for u: Dictionary in sh.get_shader_uniform_list():
		names[String(u.get("name", ""))] = true
	if names.is_empty():
		for line: String in sh.code.split("\n"):
			var l := line.strip_edges()
			if l.begins_with("uniform "):
				var decl := l.get_slice("=", 0).get_slice(":", 0).strip_edges()
				names[decl.get_slice(" ", decl.get_slice_count(" ") - 1).get_slice("[", 0)] = true
	return names


# ---------------------------------------------------------------- CPU mirror of the ground shader (tests, scatter)

## Signed distance (m) to the deep-water edge, < 0 in the water (ground.gdshader water_sd: river segments only
## outside the moat's centre line; the ford circles are not subtracted). 1e4 when there is no river and no moat.
static func water_distance(params: Dictionary, p: Vector2) -> float:
	var sd := 1e4
	var count_river := true
	var moat: Vector4 = params.get(&"moat", Vector4.ZERO)
	if moat.z > 0.0:
		var mr: float = p.distance_to(Vector2(moat.x, moat.y))
		sd = absf(mr - moat.z) - moat.w
		count_river = mr > moat.z
	var count: int = int(params.get(&"river_count", 0))
	if count_river and count > 0:
		var segs: PackedVector4Array = params.get(&"river_segs", PackedVector4Array())
		var best := INF
		for i: int in mini(count, segs.size()):
			var s: Vector4 = segs[i]
			var cp: Vector2 = Geometry2D.get_closest_point_to_segment(p, Vector2(s.x, s.y), Vector2(s.z, s.w))
			best = minf(best, p.distance_to(cp))
		sd = minf(sd, best - float(params.get(&"river_half_width", HALF_WIDTH)))
	return sd


## True inside one of the uncut circles (fords, Crown Steps).
static func in_ford(params: Dictionary, p: Vector2) -> bool:
	for c: Vector4 in PackedVector4Array(params.get(&"fords", PackedVector4Array())):
		if c.z > 0.0 and p.distance_to(Vector2(c.x, c.y)) < c.z:
			return true
	return false


## True where the ground is cut open (deep water: not a ford, not a Crown Step). Bridges ARE cut (their decks
## cover the trench).
static func is_cut(params: Dictionary, p: Vector2) -> bool:
	return water_distance(params, p) < 0.0 and not in_ford(params, p)

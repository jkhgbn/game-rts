class_name BiomeMap
extends RefCounted
## Biome weights at a map point (task 12.V6; map-fill.md 3.1): the CPU mirror of the ground shader's analytic biome
## zones (ground.gdshader `biome_weights`, 12.V2) plus its river cut (GroundParams.water_distance / is_cut / in_ford),
## so the decor scatter (MapDressingArt) puts every biome set exactly where the ground paints that biome.
## There is no biome mask texture in the ground (one-sampler budget, 12.V2); `mask_image()` bakes one on demand for
## tools / a minimap.
##
## Zones, first match wins, borders blended over `blend` metres (the ground also jitters them by ~+-1.6 m of paint
## noise; the scatter uses the plain distances): ruins (Crown Isle r < 11 + 3 m around the dry-land landmarks) >
## riverbank (land within `bank_reach` 6 m of deep water) > Hearth Meadow (22 m round the base hubs) > Old Wood (28 m
## round (-50, -50) / (50, 50)) > heath (max(|x|, |z|) > 44) > Wildflower Glade (the rest).
##
## Build it from what the ground draws:
##     var bm := BiomeMap.from_ground(ground_shader_material)      # the level's painted ground
##     var bm := BiomeMap.skirmish()                               # Crown Hollow numbers (GroundParams), tools / tests
## A ground whose `biome_amount` is 0 (missions, the step-11 map) is all glade; its river (if any) still cuts.
## Public: `enabled`, `weights(p) -> PackedFloat32Array` (6, order BIOMES, sum 1), `weight(p, biome) -> float`,
## `biome_at(p) -> StringName`, `pick(p, roll) -> StringName` (a biome drawn by weight, roll in [0, 1)),
## `water_distance(p)` (signed, < 0 in the water), `is_cut(p)` (deep water), `in_ford(p)`, `has_water()`,
## `domain(biome) -> Array[Rect2]` (non-overlapping rects that hold every point where the biome can have weight),
## `water_domain(reach) -> Array[Rect2]`, `mask_image(size) -> Image`, `static set_path(biome)`,
## `static load_items(biome) -> Array[Dictionary]` (the set's items() in the shared step-12 format, completed with
## the ENTRIES hints; sets without items() are read from ENTRIES).
## Everything is in world x / z metres (Vector2(x, z)).

const BIOMES: Array[StringName] = [&"ruins", &"riverbank", &"meadow", &"old_wood", &"heath", &"glade"]
const RUINS := 0
const RIVERBANK := 1
const MEADOW := 2
const OLD_WOOD := 3
const HEATH := 4
const GLADE := 5
const BIOME_DIR := "res://art/environment/biomes/"
const GROUND_PARAMS := "res://art/environment/ground_params.gd"
const MAP_HALF := 60.0
const WATER_CELL := 2.0          ## Coarse water-distance grid (a lower bound for the far test).
const FAR_WATER := 1e4

var enabled := false             ## The ground paints biomes (biome_amount > 0); false = glade everywhere.
var hubs := Vector4(-36, 36, 36, -36)
var hub_radius := 22.0
var woods := Vector4(-50, -50, 50, 50)
var wood_radius := 28.0
var heath_edge := 44.0
var bank_reach := 6.0
var blend := 4.0
var ruins: Array[Vector4] = []   ## (x, z, r, 0)
# River cut (ground.gdshader water_sd): segments only outside the moat's centre line; fords stay uncut.
var _seg_a := PackedVector2Array()
var _seg_b := PackedVector2Array()
var _half_width := 2.5
var _moat := Vector4.ZERO
var _fords: Array[Vector4] = []
var _grid := PackedFloat32Array()   # coarse signed water distance at cell centres (WATER_CELL), for the far test
var _grid_n := 0


## From the ground's ShaderMaterial (the uniform values the level set: EnvProps.set_river, GroundParams.apply).
static func from_ground(mat: ShaderMaterial) -> BiomeMap:
	var params := {}
	if mat != null:
		for k: String in ["biome_amount", "biome_hubs", "biome_hub_radius", "biome_woods", "biome_wood_radius",
				"biome_heath_edge", "biome_bank_reach", "biome_blend", "biome_ruins", "biome_ruin_count",
				"river_segs", "river_count", "river_half_width", "moat", "fords"]:
			var v: Variant = mat.get_shader_parameter(StringName(k))
			if v != null:
				params[StringName(k)] = v
	var bm := BiomeMap.new()
	bm.setup(params)
	return bm


## Crown Hollow as the skirmish paints it (GroundParams.skirmish_river() + skirmish_biomes()).
static func skirmish() -> BiomeMap:
	var params := {}
	if ResourceLoader.exists(GROUND_PARAMS):
		var gp: Script = load(GROUND_PARAMS)
		params.merge(gp.call(&"skirmish_river"))
		params.merge(gp.call(&"skirmish_biomes"))
	var bm := BiomeMap.new()
	bm.setup(params)
	return bm


## Keys = the ground shader's uniform names (missing ones keep the shader defaults; no biome_amount = no biomes).
func setup(params: Dictionary) -> void:
	enabled = float(params.get(&"biome_amount", 0.0)) > 0.0
	hubs = params.get(&"biome_hubs", hubs)
	hub_radius = float(params.get(&"biome_hub_radius", hub_radius))
	woods = params.get(&"biome_woods", woods)
	wood_radius = float(params.get(&"biome_wood_radius", wood_radius))
	heath_edge = float(params.get(&"biome_heath_edge", heath_edge))
	bank_reach = float(params.get(&"biome_bank_reach", bank_reach))
	blend = maxf(float(params.get(&"biome_blend", blend)), 0.01)
	ruins.clear()
	var rc: int = int(params.get(&"biome_ruin_count", 0))
	var rlist: Array = Array(params.get(&"biome_ruins", []))
	for i: int in mini(rc, rlist.size()):
		var r: Vector4 = rlist[i]
		if r.z > 0.0:
			ruins.append(r)
	_seg_a.clear()
	_seg_b.clear()
	var count: int = int(params.get(&"river_count", 0))
	var segs: Array = Array(params.get(&"river_segs", []))
	for i: int in mini(count, segs.size()):
		var s: Vector4 = segs[i]
		_seg_a.append(Vector2(s.x, s.y))
		_seg_b.append(Vector2(s.z, s.w))
	_half_width = float(params.get(&"river_half_width", 2.5))
	_moat = params.get(&"moat", Vector4.ZERO)
	_fords.clear()
	for f: Variant in Array(params.get(&"fords", [])):
		if f is Vector4 and (f as Vector4).z > 0.0:
			_fords.append(f)
	_build_grid()


func has_water() -> bool:
	return not _seg_a.is_empty() or _moat.z > 0.0


# ---------------------------------------------------------------- water (ground.gdshader water_sd)

## Signed distance (m) to the deep-water edge, < 0 in the water; FAR_WATER without a river / moat.
func water_distance(p: Vector2) -> float:
	var sd := FAR_WATER
	var count_river := true
	if _moat.z > 0.0:
		var mr: float = p.distance_to(Vector2(_moat.x, _moat.y))
		sd = absf(mr - _moat.z) - _moat.w
		count_river = mr > _moat.z
	if count_river and not _seg_a.is_empty():
		var best := INF
		for i: int in _seg_a.size():
			best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, _seg_a[i], _seg_b[i])))
		sd = minf(sd, best - _half_width)
	return sd


## True inside a ford / Crown Steps circle (walkable, not cut).
func in_ford(p: Vector2, grow: float = 0.0) -> bool:
	for c: Vector4 in _fords:
		if p.distance_to(Vector2(c.x, c.y)) < c.z + grow:
			return true
	return false


## Deep water (the ground is cut open): water and not a ford.
func is_cut(p: Vector2) -> bool:
	return water_distance(p) < 0.0 and not in_ford(p)


## True when p is surely on land more than `reach` metres from the water (a lower bound of the signed distance from
## the coarse grid, Lipschitz 1); false = maybe closer (or in the water): compute water_distance(p).
func water_far(p: Vector2, reach: float) -> bool:
	if _grid_n == 0:
		return true
	var ix: int = clampi(int((p.x + MAP_HALF) / WATER_CELL), 0, _grid_n - 1)
	var iz: int = clampi(int((p.y + MAP_HALF) / WATER_CELL), 0, _grid_n - 1)
	# + 0.5 m: the river part is ignored inside the moat's centre line (a small step where the rivers join it).
	return _grid[iz * _grid_n + ix] - WATER_CELL * 0.7072 - 0.5 > reach


func _build_grid() -> void:
	_grid.clear()
	_grid_n = 0
	if not has_water():
		return
	_grid_n = int(ceil(MAP_HALF * 2.0 / WATER_CELL))
	_grid.resize(_grid_n * _grid_n)
	for iz: int in _grid_n:
		for ix: int in _grid_n:
			var c := Vector2(-MAP_HALF + (ix + 0.5) * WATER_CELL, -MAP_HALF + (iz + 0.5) * WATER_CELL)
			_grid[iz * _grid_n + ix] = water_distance(c)


# ---------------------------------------------------------------- biome weights (ground.gdshader biome_weights)

static func _zone_in(e: float, bl: float) -> float:
	return 1.0 - smoothstep(-bl, bl, e)


## The 6 weights at p in BIOMES order (ruins, riverbank, meadow, old_wood, heath, glade); they sum to 1.
func weights(p: Vector2) -> PackedFloat32Array:
	var w := PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 1.0])
	if not enabled:
		return w
	var bl: float = blend * 0.5
	var ruin := 0.0
	for r: Vector4 in ruins:
		var d: float = p.distance_to(Vector2(r.x, r.y))
		if d < r.z + bl:
			ruin = maxf(ruin, _zone_in(d - r.z, bl))
	var bank := 0.0
	if has_water() and not water_far(p, bank_reach + bl):
		bank = _zone_in(water_distance(p) - bank_reach, bl)
	var meadow := 0.0
	if hub_radius > 0.0:
		meadow = _zone_in(minf(p.distance_to(Vector2(hubs.x, hubs.y)), p.distance_to(Vector2(hubs.z, hubs.w)))
				- hub_radius, bl)
	var wood := 0.0
	if wood_radius > 0.0:
		wood = _zone_in(minf(p.distance_to(Vector2(woods.x, woods.y)), p.distance_to(Vector2(woods.z, woods.w)))
				- wood_radius, bl)
	var heath := 0.0
	if heath_edge > 0.0:
		heath = 1.0 - _zone_in(maxf(absf(p.x), absf(p.y)) - heath_edge, bl)
	var left: float = 1.0 - ruin
	bank *= left
	left -= bank
	meadow *= left
	left -= meadow
	wood *= left
	left -= wood
	heath *= left
	left -= heath
	w[RUINS] = ruin
	w[RIVERBANK] = bank
	w[MEADOW] = meadow
	w[OLD_WOOD] = wood
	w[HEATH] = heath
	w[GLADE] = maxf(left, 0.0)
	return w


## One biome's weight at p (`biome` = index in BIOMES or its id).
func weight(p: Vector2, biome: Variant) -> float:
	var i: int = biome if biome is int else BIOMES.find(StringName(biome))
	if i < 0:
		return 0.0
	return weights(p)[i]


## The biome with the largest weight at p.
func biome_at(p: Vector2) -> StringName:
	var w := weights(p)
	var best := GLADE
	for i: int in w.size():
		if w[i] > w[best]:
			best = i
	return BIOMES[best]


## A biome drawn by weight at p (roll in [0, 1)): blended borders mix both sets.
func pick(p: Vector2, roll: float) -> StringName:
	var w := weights(p)
	var acc := 0.0
	for i: int in w.size():
		acc += w[i]
		if roll < acc:
			return BIOMES[i]
	return BIOMES[GLADE]


# ---------------------------------------------------------------- sampling domains

## Non-overlapping rects (inside the map) that contain every point where `biome` can have weight.
func domain(biome: StringName) -> Array[Rect2]:
	var bl: float = blend * 0.5
	var out: Array[Rect2] = []
	var map := Rect2(-MAP_HALF, -MAP_HALF, MAP_HALF * 2.0, MAP_HALF * 2.0)
	if not enabled:
		if biome == &"glade":
			out.append(map)
		return out
	match biome:
		&"ruins":
			for r: Vector4 in ruins:
				out.append(Rect2(r.x - r.z - bl, r.y - r.z - bl, (r.z + bl) * 2.0, (r.z + bl) * 2.0))
		&"riverbank":
			return water_domain(bank_reach + bl)
		&"meadow":
			for c: Vector2 in [Vector2(hubs.x, hubs.y), Vector2(hubs.z, hubs.w)]:
				var rr: float = hub_radius + bl
				out.append(Rect2(c.x - rr, c.y - rr, rr * 2.0, rr * 2.0))
		&"old_wood":
			for c: Vector2 in [Vector2(woods.x, woods.y), Vector2(woods.z, woods.w)]:
				var rr: float = wood_radius + bl
				out.append(Rect2(c.x - rr, c.y - rr, rr * 2.0, rr * 2.0))
		&"heath":
			var e: float = heath_edge - bl
			out.append(Rect2(-MAP_HALF, -MAP_HALF, MAP_HALF * 2.0, MAP_HALF - e))
			out.append(Rect2(-MAP_HALF, e, MAP_HALF * 2.0, MAP_HALF - e))
			out.append(Rect2(-MAP_HALF, -e, MAP_HALF - e, e * 2.0))
			out.append(Rect2(e, -e, MAP_HALF - e, e * 2.0))
		_:
			out.append(map)
	return _clip_disjoint(out)


## Rects around the river segments and the moat grown by `reach` (water / bank / riverbank placement).
func water_domain(reach: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var g: float = _half_width + reach
	for i: int in _seg_a.size():
		var lo: Vector2 = _seg_a[i].min(_seg_b[i]) - Vector2(g, g)
		var hi: Vector2 = _seg_a[i].max(_seg_b[i]) + Vector2(g, g)
		out.append(Rect2(lo, hi - lo))
	if _moat.z > 0.0:
		var m: float = _moat.z + _moat.w + reach
		out.append(Rect2(_moat.x - m, _moat.y - m, m * 2.0, m * 2.0))
	return _clip_disjoint(out)


## Clips rects to the map and cuts the later ones by the earlier ones (so a point is sampled once).
static func _clip_disjoint(rects: Array[Rect2]) -> Array[Rect2]:
	var map := Rect2(-MAP_HALF, -MAP_HALF, MAP_HALF * 2.0, MAP_HALF * 2.0)
	var out: Array[Rect2] = []
	for r: Rect2 in rects:
		var pieces: Array[Rect2] = [r.intersection(map)]
		for o: Rect2 in out:
			var next: Array[Rect2] = []
			for piece: Rect2 in pieces:
				next.append_array(_subtract(piece, o))
			pieces = next
		for piece: Rect2 in pieces:
			if piece.size.x > 0.01 and piece.size.y > 0.01:
				out.append(piece)
	return out


## a minus b as up to 4 rects.
static func _subtract(a: Rect2, b: Rect2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if not a.intersects(b):
		out.append(a)
		return out
	var i: Rect2 = a.intersection(b)
	if i.position.y > a.position.y:
		out.append(Rect2(a.position.x, a.position.y, a.size.x, i.position.y - a.position.y))
	if i.end.y < a.end.y:
		out.append(Rect2(a.position.x, i.end.y, a.size.x, a.end.y - i.end.y))
	if i.position.x > a.position.x:
		out.append(Rect2(a.position.x, i.position.y, i.position.x - a.position.x, i.size.y))
	if i.end.x < a.end.x:
		out.append(Rect2(i.end.x, i.position.y, a.end.x - i.end.x, i.size.y))
	return out


# ---------------------------------------------------------------- mask + sets

## A size x size RGBA8 image over the map (+x right, +z down): R meadow, G heath, B Old Wood, A riverbank (the ground's
## biome_tints order); ruins / glade are what is left. For tools and a minimap; the ground itself stays analytic.
func mask_image(size: int = 240) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for iz: int in size:
		for ix: int in size:
			var p := Vector2(-MAP_HALF + (ix + 0.5) * MAP_HALF * 2.0 / size, -MAP_HALF + (iz + 0.5) * MAP_HALF * 2.0 / size)
			var w := weights(p)
			img.set_pixel(ix, iz, Color(w[MEADOW], w[HEATH], w[OLD_WOOD], w[RIVERBANK]))
	return img


static func set_path(biome: StringName) -> String:
	return BIOME_DIR + String(biome) + "/" + String(biome) + "_set.gd"


## A biome set in the shared step-12 item format (mesh, material, density, scale, vis_end, shadow, variants) plus
## every optional hint of its ENTRIES row (path, id, cluster, place, gap, yaw, yaw_jitter, y, shore, paving_ok,
## max_height, lane_clear_paving). Uses the set's items() when it has one, else reads ENTRIES (meadow, riverbank).
## Empty when the set file is missing.
static func load_items(biome: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var path: String = set_path(biome)
	if not ResourceLoader.exists(path):
		return out
	var script := load(path) as GDScript
	if script == null:
		return out
	var consts: Dictionary = script.get_script_constant_map()
	var entries: Array = consts.get("ENTRIES", [])
	var by_mesh := {}
	for e: Dictionary in entries:
		var mp: String = String(e.get("mesh", ""))
		if not by_mesh.has(mp):
			by_mesh[mp] = e   # the first row of a mesh (riverbank repeats meshes: read ENTRIES there)
	var base: Array = []
	var from_items: bool = script.has_method(&"items")
	if from_items:
		base = script.call(&"items")
	if base.is_empty():
		from_items = false
		for e: Dictionary in entries:
			var mp: String = String(e.get("mesh", ""))
			if not ResourceLoader.exists(mp):
				continue
			var mesh := load(mp) as Mesh
			if mesh == null:
				continue
			base.append({"mesh": mesh, "material": mesh.surface_get_material(0), "density": float(e["per_100m2"]),
				"scale": e["scale"], "vis_end": float(e.get("range", 90.0)), "shadow": bool(e.get("shadow", false)),
				"variants": int(e.get("variants", 3)), "_row": e})
	for it: Dictionary in base:
		var d: Dictionary = it.duplicate()
		var mesh: Mesh = d.get("mesh") as Mesh
		if mesh == null:
			continue
		var mp2: String = mesh.resource_path
		var row: Dictionary = d.get("_row", by_mesh.get(mp2, {}))
		d.erase("_row")
		d["path"] = mp2
		for k: String in ["id", "cluster", "place", "gap", "yaw", "yaw_jitter", "y", "shore", "paving_ok",
				"max_height", "lane_clear_paving"]:
			if not d.has(k) and row.has(k):
				d[k] = row[k]
		d["biome"] = biome
		out.append(d)
	return out

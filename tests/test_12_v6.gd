extends SceneTree
## Task 12.V6 (biome scatter integration, docs/design/map-fill.md 3.1 / 9 / 10): BiomeMap mirrors the ground's biome
## zones and river cut; MapDressingArt scatters the six biome sets on the real skirmish map within the budgets (<= 12 000
## instances with the river on, per-set budgets, <= 24 mesh kinds), keeps decor out of deep water / fords / bridges /
## the lane / roads / the crown dais / crystal nodes, puts water items on the surface and bank items on the bank band,
## combs the heath's tall grass with the wind, keeps the materials on the meshes (no override), sets visibility ranges,
## and Map detail Low halves the decor. CPU-side positions only (the headless renderer does not keep MultiMesh
## transforms).
## Run: $GODOT --headless --path . -s tests/test_12_v6.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "12.V6"
const TIMEOUT_FRAMES := 6000
const BIOME_MAP_PATH := "res://art/environment/biomes/biome_map.gd"
const DRESSING_PATH := "res://art/environment/map_dressing_art.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const B := "res://art/environment/biomes/"
const SET_BUDGETS := {&"riverbank": 1800, &"meadow": 1800, &"heath": 1600, &"old_wood": 900, &"glade": 1800,
		&"ruins": 300}
const MAX_TOTAL := 12000        ## map-fill.md 9 (river on)
const MAX_TOTAL_MAP_P1 := 4000  ## tests/test_map_p1.gd MAX_DECOR
const MAX_KINDS := 24
const FLAT_RUINS: Array[String] = [B + "ruins/ruins_flagstones.res", B + "ruins/ruins_ember_moss.res"]
const SHADOW_KINDS: Array[String] = [B + "meadow/meadow_hay.res", B + "old_wood/ow_moss_boulders.res",
		B + "old_wood/ow_fallen_trunk.res", B + "riverbank/rb_driftwood.res", B + "ruins/ruins_monuments.res"]
const EPS := 0.02

var main: Node
var dressing: Node
var low_dressing: Node
var _fails: PackedStringArray = PackedStringArray()
var _frame := 0
var _ready_frame := -1
var _low_frame := -1


func _initialize() -> void:
	_check_biome_map()
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	(load(DRESSING_PATH) as GDScript).set(&"map_detail_override", &"high")
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	_frame += 1
	if _ready_frame < 0:
		if main.get(&"hero") != null:
			_ready_frame = _frame
		elif _frame > TIMEOUT_FRAMES:
			_fail("the skirmish never finished loading")
			return _finish()
		return false
	if _frame == _ready_frame + 30:
		dressing = main.find_child("MapDressing", true, false)
		if dressing == null:
			_fail("MapDressing missing from the skirmish")
			return _finish()
		_check_scatter()
		# Map detail Low: a second dressing on the same map (no border), counts compared.
		(load(DRESSING_PATH) as GDScript).set(&"map_detail_override", &"low")
		low_dressing = (load(DRESSING_PATH) as GDScript).new()
		low_dressing.name = "LowDressing"
		main.add_child(low_dressing)
		_low_frame = _frame
		return false
	if _low_frame > 0 and _frame == _low_frame + 5:
		_check_low()
		(load(DRESSING_PATH) as GDScript).set(&"map_detail_override", &"")
		low_dressing.queue_free()
		_check_clear()
		return _finish()
	return false


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("  - %s" % f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	return true


func _fail(msg: String) -> void:
	_fails.append(msg)


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fail(msg)


# ---------------------------------------------------------------- BiomeMap

func _check_biome_map() -> void:
	var bm_script: GDScript = load(BIOME_MAP_PATH)
	var gp: GDScript = load(GP_PATH)
	var bm: RefCounted = bm_script.call(&"skirmish")
	_check(bool(bm.get(&"enabled")), "BiomeMap.skirmish() has biomes")
	_check(bool(bm.call(&"has_water")), "BiomeMap.skirmish() has the river")
	var expect := {Vector2(0, 0): &"ruins", Vector2(-36, 36): &"meadow", Vector2(-50, -50): &"old_wood",
		Vector2(-55, 5): &"heath", Vector2(-25, 5): &"glade", Vector2(-57, -16): &"ruins", Vector2(36, -36): &"meadow",
		Vector2(50, 50): &"old_wood"}
	for p: Vector2 in expect:
		_check(bm.call(&"biome_at", p) == expect[p], "biome at %s is %s, expected %s" % [p, bm.call(&"biome_at", p),
			expect[p]])
	var params: Dictionary = gp.call(&"skirmish_river")
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var bank_seen := 0
	for i: int in 600:
		var p := Vector2(rng.randf_range(-60, 60), rng.randf_range(-60, 60))
		var w: PackedFloat32Array = bm.call(&"weights", p)
		var sum := 0.0
		for x: float in w:
			sum += x
			_check(x >= -0.0001, "negative weight at %s" % p)
		_check(absf(sum - 1.0) < 0.001, "weights at %s sum to %.3f" % [p, sum])
		var wm: PackedFloat32Array = bm.call(&"weights", -p)
		for k: int in w.size():
			_check(absf(w[k] - wm[k]) < 0.001, "biome weights not point-mirrored at %s" % p)
		var wd: float = bm.call(&"water_distance", p)
		_check(absf(wd - float(gp.call(&"water_distance", params, p))) < 0.001, "water distance != GroundParams at %s" % p)
		_check(bool(bm.call(&"is_cut", p)) == bool(gp.call(&"is_cut", params, p)), "is_cut != GroundParams at %s" % p)
		if wd > 0.3 and wd < 3.0 and w[0] < 0.01:
			bank_seen += 1
			_check(w[1] > 0.99, "riverbank weight %.2f at %s (%.1f m from the water)" % [w[1], p, wd])
	_check(bank_seen > 5, "no riverbank sample")
	var flat: RefCounted = bm_script.call(&"from_ground", null)
	_check(not bool(flat.get(&"enabled")) and flat.call(&"biome_at", Vector2(-50, -50)) == &"glade",
		"a ground without biomes is all glade")
	var img: Image = bm.call(&"mask_image", 60)
	_check(img != null and img.get_width() == 60, "mask_image")
	for biome: StringName in [&"ruins", &"riverbank", &"meadow", &"old_wood", &"heath", &"glade"]:
		var items: Array = bm_script.call(&"load_items", biome)
		_check(not items.is_empty(), "biome set %s has no items" % biome)
		for it: Dictionary in items:
			_check(it.get("mesh") is Mesh and float(it.get("density", 0.0)) > 0.0 and float(it.get("vis_end", 0.0)) > 0.0,
				"%s item %s incomplete" % [biome, it.get("path")])


# ---------------------------------------------------------------- the scatter on the skirmish

func _check_scatter() -> void:
	var bm: RefCounted = dressing.call(&"biome_map")
	_check(bm != null and bool(bm.get(&"enabled")) and bool(bm.call(&"has_water")),
		"the dressing read the ground's biomes and river")
	var total: int = int(dressing.call(&"decor_count"))
	var counts: Dictionary = dressing.call(&"biome_counts")
	var kinds: PackedStringArray = dressing.call(&"kind_paths")
	print("decor %d, %d kinds, %.0f ms %s, per biome %s" % [total, kinds.size(), float(dressing.call(&"populate_msec")),
		str(dressing.call(&"populate_timings")), str(counts)])
	_check(total > 1500 and total <= MAX_TOTAL and total <= MAX_TOTAL_MAP_P1, "decor count %d" % total)
	for biome: StringName in SET_BUDGETS:
		var n: int = int(counts.get(biome, 0))
		_check(n > 0 and n <= int(SET_BUDGETS[biome]), "%s: %d instances (1-%d)" % [biome, n, SET_BUDGETS[biome]])
	_check(kinds.size() <= MAX_KINDS, "%d decor mesh kinds (max %d)" % [kinds.size(), MAX_KINDS])
	for k: String in kinds:
		_check(not k.get_file().begins_with("decor_"), "old glade decor %s still scattered" % k.get_file())
	_check(float(dressing.call(&"populate_msec")) < 3000.0, "populate took %.0f ms" % float(dressing.call(&"populate_msec")))
	# MultiMeshes: no material override (variant collapse / contact discs), shadows only on the big kinds, ranges.
	var biomes_node: Node = dressing.get_node_or_null(^"Biomes")
	_check(biomes_node != null, "no Biomes node")
	if biomes_node:
		for c: Node in biomes_node.get_children():
			var mmi := c as MultiMeshInstance3D
			if mmi == null:
				continue
			var path: String = mmi.multimesh.mesh.resource_path
			_check(mmi.material_override == null, "%s has a material override" % mmi.name)
			var casts: bool = mmi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_check(casts == (path in SHADOW_KINDS), "%s shadow casting %s" % [mmi.name, casts])
			if not String(mmi.name).ends_with("_all"):
				_check(mmi.visibility_range_end >= 65.0 and mmi.visibility_range_end <= 140.0,
					"%s visibility range %.0f" % [mmi.name, mmi.visibility_range_end])
	_check(dressing.find_children("*", "GeometryInstance3D", true, false).size() <= 140,
		"MapDressing draw nodes over test_map_p1's 140")
	# Where the decor is.
	var ground := _ground_material()
	var lane_a: Vector2 = ground.get_shader_parameter(&"lane_a")
	var lane_b: Vector2 = ground.get_shader_parameter(&"lane_b")
	var paving := Vector4.ZERO
	for i: int in 4:
		var s: Variant = ground.get_shader_parameter(StringName("spot_%d" % i))
		if s is Vector4 and (s as Vector4).w > 0.5:
			paving = s
	var roads: Array = []
	var rc: int = int(ground.get_shader_parameter(&"road_count"))
	var rs: Array = Array(ground.get_shader_parameter(&"road_segs"))
	for i2: int in rc:
		roads.append(rs[i2])
	var road_clear: float = float(ground.get_shader_parameter(&"road_width")) * 0.5 + 0.8
	var crossings: Array = []
	var river: Node = main.get_tree().get_first_node_in_group(&"river")
	if river and river.has_method(&"crossings"):
		crossings = river.call(&"crossings")
	_check(crossings.size() == 8, "river crossings: %d" % crossings.size())
	var nodes: Array[Vector2] = []
	for n: Node in main.get_tree().get_nodes_in_group(&"crystal_nodes"):
		nodes.append(Vector2((n as Node3D).global_position.x, (n as Node3D).global_position.z))
	# Camp sites (their decor_clear_radius) and lairs (their decor_clear circles), from the skirmish constants.
	var sites: Array[Vector3] = _site_circles()
	_check(sites.size() >= 16, "camp / lair clear circles: %d" % sites.size())
	var bad := {}
	var water_items := 0
	var bank_items := 0
	for k2: String in kinds:
		for pos: Vector3 in (dressing.call(&"instance_positions", k2) as PackedVector3Array):
			var q := Vector2(pos.x, pos.z)
			var wd: float = bm.call(&"water_distance", q)
			var in_ford: bool = bm.call(&"in_ford", q)
			var why := ""
			if absf(q.x) > 60.0 or absf(q.y) > 60.0:
				why = "off the map"
			elif pos.y < -0.2:
				water_items += 1
				if absf(pos.y + 0.35) > 0.01:
					why = "water item not on the surface"
				elif wd > -0.05 or in_ford:
					why = "water item out of deep water"
			else:
				if absf(pos.y) > 0.001:
					why = "land item not at y 0"
				elif wd < 0.1 - EPS or in_ford:
					why = "in the water / a ford"
				else:
					if wd < 2.5:
						bank_items += 1
					var lane_d: float = q.distance_to(Geometry2D.get_closest_point_to_segment(q, lane_a, lane_b))
					var on_paving: bool = paving.z > 0.0 and q.distance_to(Vector2(paving.x, paving.y)) < paving.z
					var lane_min: float = 2.6 if (on_paving and k2 in FLAT_RUINS) else 5.2
					if lane_d < lane_min - EPS and absf(q.x) < 59.5 and absf(q.y) < 59.5:
						why = "on the lane (%.1f m)" % lane_d
					for r: Vector4 in roads:
						var rd: float = q.distance_to(Geometry2D.get_closest_point_to_segment(q, Vector2(r.x, r.y),
							Vector2(r.z, r.w)))
						if rd < road_clear - EPS:
							why = "on a road (%.1f m)" % rd
			if q.length() < 3.8 - EPS:
				why = "on the crown dais"
			for c: Dictionary in crossings:
				if _in_crossing(q, c):
					why = "on crossing %s" % c.get("id")
			for nq: Vector2 in nodes:
				if q.distance_to(nq) < 2.3 - EPS:
					why = "on a crystal node"
			for sc: Vector3 in sites:
				if q.distance_to(Vector2(sc.x, sc.y)) < sc.z - EPS:
					why = "on a camp site / lair (%.1f m from %s)" % [q.distance_to(Vector2(sc.x, sc.y)), Vector2(sc.x, sc.y)]
			if why != "":
				var key := "%s: %s" % [k2.get_file(), why]
				if not bad.has(key):
					bad[key] = q
	for key2: String in bad:
		_fail("%s at %s" % [key2, bad[key2]])
	_check(water_items > 20, "only %d water items (reeds / cattails / lily pads)" % water_items)
	_check(bank_items > 100, "only %d items on the bank band" % bank_items)
	# The heath's tall grass leans with the wind (yaw -0.6435 +- 0.35: local +X toward wind_dir (0.8, 0.6)).
	var grass: Array = dressing.call(&"instance_transforms", B + "heath/heath_tall_grass.res")
	_check(grass.size() > 50, "heath tall grass: %d instances" % grass.size())
	var off := 0
	for xf: Transform3D in grass:
		var ax := Vector2(xf.basis.x.x, xf.basis.x.z).normalized()
		if ax.dot(Vector2(0.8, 0.6)) < cos(0.36):
			off += 1
	_check(off == 0, "%d heath tall grass instances not combed by the wind" % off)
	# Other kinds keep a random yaw.
	var ferns: Array = dressing.call(&"instance_transforms", B + "old_wood/ow_ferns.res")
	var spread := Vector2.ZERO
	for xf2: Transform3D in ferns:
		spread += Vector2(xf2.basis.x.x, xf2.basis.x.z).normalized()
	_check(ferns.size() > 20 and spread.length() / ferns.size() < 0.3, "Old Wood ferns should have random yaws")
	# No meadow / glade grass on the heath or in the Old Wood (each biome uses its own set).
	for k3: String in [B + "glade/glade_tall_grass.res", B + "meadow/meadow_tufts.res"]:
		var wrong := 0
		for pos2: Vector3 in (dressing.call(&"instance_positions", k3) as PackedVector3Array):
			var w: PackedFloat32Array = bm.call(&"weights", Vector2(pos2.x, pos2.z))
			if w[3] > 0.999 or w[4] > 0.999:
				wrong += 1
		_check(wrong == 0, "%d %s instances deep in the heath / Old Wood" % [wrong, k3.get_file()])


## (x, z, r) decor-free circles: every CAMP_SPOTS spot (its site scene's decor_clear_radius, 4.5 without one) and
## every LAIR_SPOTS lair (its scene's decor_clear circles turned by LairArt.yaw_for, else 0.6 x the radius).
func _site_circles() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var consts: Dictionary = (main.get_script() as Script).get_script_constant_map()
	for spot: Dictionary in consts.get("CAMP_SPOTS", []):
		var p: Vector3 = spot["pos"]
		out.append(Vector3(p.x, p.z, float(_root_meta("res://art/environment/camps/%s_site.tscn" % spot["kind"],
			"decor_clear_radius", 4.5))))
	var lair_art: Script = load("res://art/environment/lairs/lair_art.gd") as Script
	for lair: Dictionary in consts.get("LAIR_SPOTS", []):
		var c: Vector3 = lair["center"]
		var local: Variant = _root_meta(String(lair_art.call(&"scene_path_for", lair["id"], lair["kind"])), "decor_clear",
			null) if lair_art else null
		if local is PackedVector3Array:
			var yaw: float = float(lair_art.call(&"yaw_for", lair["id"]))
			for lc: Vector3 in (local as PackedVector3Array):
				var w: Vector3 = Basis(Vector3.UP, yaw) * Vector3(lc.x, 0.0, lc.y)
				out.append(Vector3(c.x + w.x, c.z + w.z, lc.z))
		else:
			out.append(Vector3(c.x, c.z, float(lair.get("radius", 4.0)) * 0.6))
	return out


func _root_meta(path: String, key: String, fallback: Variant) -> Variant:
	if not ResourceLoader.exists(path):
		return fallback
	var state: SceneState = (load(path) as PackedScene).get_state()
	for i: int in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == "metadata/" + key:
			return state.get_node_property_value(0, i)
	return fallback


func _in_crossing(q: Vector2, c: Dictionary) -> bool:
	var center: Vector3 = c.get("center", Vector3.ZERO)
	var cq := Vector2(center.x, center.z)
	if String(c.get("kind", "")).begins_with("bridge"):
		var dir: Vector3 = c.get("dir", Vector3.RIGHT)
		var u := Vector2(dir.x, dir.z).normalized()
		var d: Vector2 = q - cq
		return absf(d.dot(u)) < float(c.get("length", 8.0)) * 0.5 and absf(d.dot(Vector2(-u.y, u.x))) < float(c.get("width", 6.0)) * 0.5
	return q.distance_to(cq) < float(c.get("width", 6.0)) * 0.5


func _ground_material() -> ShaderMaterial:
	for mi: Node in main.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var sm := m.material_override as ShaderMaterial
		if m.mesh is PlaneMesh and sm and sm.shader and sm.shader.resource_path == GROUND_SHADER:
			return sm
	return null


func _check_low() -> void:
	var high: int = int(dressing.call(&"decor_count"))
	var low: int = int(low_dressing.call(&"decor_count"))
	var ratio: float = float(low) / float(maxi(high, 1))
	print("map detail low: %d of %d (%.2f)" % [low, high, ratio])
	_check(ratio > 0.4 and ratio < 0.6, "Map detail Low keeps %.2f of the decor (0.4-0.6)" % ratio)


## clear_area hides the decor under a new building.
func _check_clear() -> void:
	var all: PackedVector3Array = dressing.call(&"instance_positions")
	if all.is_empty():
		_fail("no decor to clear")
		return
	var c: Vector3 = all[all.size() / 2]
	var before := 0
	for p: Vector3 in all:
		if Vector2(p.x - c.x, p.z - c.z).length() < 3.0:
			before += 1
	dressing.call(&"clear_area", Vector3(c.x, 0.0, c.z), 3.0)
	var after: int = (dressing.call(&"instance_positions") as PackedVector3Array).size()
	_check(before > 0 and after == all.size() - before, "clear_area: %d -> %d (expected -%d)" % [all.size(), after,
		before])

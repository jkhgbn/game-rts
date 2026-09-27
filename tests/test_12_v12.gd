extends SceneTree
## Task 12.V12 (Crown Isle ruins set): the set file in both formats (items() = the shared step-12 format read by 12.V6,
## ENTRIES = map-fill.md section 10), the four meshes (indexed, one surface, shared nature_mat / the ember material,
## 3 variants each, low pieces, triangle budgets), the ember material (emission only, faint), no lights / colliders in
## the folder, and the instance budget of map-fill.md section 10 (ruins <= 300) on Crown Hollow's ruins zone.
## Run:  godot --headless --path . -s tests/test_12_v12.gd --fixed-fps 60 --quit-after 600
## Prints "PASS 12.V12" or "FAIL 12.V12: <reasons>".

const TASK_ID := "12.V12"
const SET_PATH := "res://art/environment/biomes/ruins/ruins_set.gd"
const DIR := "res://art/environment/biomes/ruins/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const EMBER_MAT := "res://art/environment/biomes/ruins/ruins_ember_mat.tres"
const GP_PATH := "res://art/environment/ground_params.gd"
const BUDGET := 300
const ITEM_KEYS := {"mesh": TYPE_OBJECT, "material": TYPE_OBJECT, "density": TYPE_FLOAT, "scale": TYPE_VECTOR2,
	"vis_end": TYPE_FLOAT, "shadow": TYPE_BOOL, "variants": TYPE_INT}
## Per mesh: [material, max triangles drawn by one variant, mesh top (m), max footprint (m), vis_end, shadow,
## max top x largest scale].
const LIMITS := {
	"ruins_flagstones": [NATURE_MAT, 300, 0.3, 1.8, 65.0, false, 0.4],
	"ruins_drums": [NATURE_MAT, 260, 0.38, 1.5, 90.0, false, 0.4],
	"ruins_ember_moss": [EMBER_MAT, 600, 0.4, 1.2, 65.0, false, 0.5],
	"ruins_monuments": [NATURE_MAT, 600, 0.86, 1.8, 90.0, true, 0.95],
}
## Landmark footprints inside the ruins circles (decor_clear_radius of the 12.V13 / 12.V14 scenes).
const LANDMARK_CLEAR := {Vector2(-57, -16): 4.2, Vector2(-30, 20): 3.8, Vector2(-54, 20): 4.3}

var _fails: Array[String] = []
var _frame := 0
var _stage: Node3D


func _initialize() -> void:
	_check_items()
	_check_entries()
	_check_ember_material()
	_check_budget()
	_check_folder()
	_stage = Node3D.new()
	root.add_child(_stage)
	_instance_all()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 10:
		return false
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _fail(msg: String) -> void:
	_fails.append(msg)
	print("  fail: " + msg)


func _set_script() -> GDScript:
	return load(SET_PATH) as GDScript


## items(): the shared format (mesh / material loaded, density, scale, vis_end, shadow, variants).
func _check_items() -> void:
	var s := _set_script()
	if s == null:
		_fail("ruins_set.gd missing")
		return
	var items: Array = s.call(&"items")
	if items.size() != LIMITS.size():
		_fail("items() returns %d kinds (%d expected)" % [items.size(), LIMITS.size()])
	var seen := {}
	for it: Variant in items:
		if not (it is Dictionary):
			_fail("item is not a Dictionary")
			continue
		var d: Dictionary = it
		for key: String in ITEM_KEYS:
			if not d.has(key) or typeof(d[key]) != ITEM_KEYS[key]:
				_fail("item without a valid '%s' (%s)" % [key, d.get(key)])
		if not (d.get("mesh") is Mesh) or not (d.get("material") is Material):
			continue
		var mesh: Mesh = d["mesh"]
		var name: String = mesh.resource_path.get_file().get_basename()
		seen[name] = true
		if not LIMITS.has(name):
			_fail("unexpected mesh %s" % mesh.resource_path)
			continue
		var lim: Array = LIMITS[name]
		var material: Material = d["material"]
		if material.resource_path != String(lim[0]):
			_fail("%s: material %s (expected %s)" % [name, material.resource_path, lim[0]])
		if mesh.surface_get_material(0) != material:
			_fail("%s: the item's material is not the mesh's surface 0 material" % name)
		var sc: Vector2 = d["scale"]
		if sc.x < 0.5 or sc.y > 2.0 or sc.x > sc.y:
			_fail("%s: bad scale %s" % [name, sc])
		if float(d["density"]) <= 0.0:
			_fail("%s: density <= 0" % name)
		if absf(float(d["vis_end"]) - float(lim[4])) > 0.01:
			_fail("%s: vis_end %s, spec %s" % [name, d["vis_end"], lim[4]])
		if bool(d["shadow"]) != bool(lim[5]):
			_fail("%s: shadow %s" % [name, d["shadow"]])
		if int(d["variants"]) != 3:
			_fail("%s: variants %d" % [name, d["variants"]])
		_check_mesh(name, mesh as ArrayMesh, lim, sc)
	for name2: String in LIMITS:
		if not seen.has(name2):
			_fail("no item for %s" % name2)


func _check_mesh(name: String, mesh: ArrayMesh, lim: Array, sc: Vector2) -> void:
	if mesh == null:
		_fail("%s: not an ArrayMesh" % name)
		return
	if mesh.get_surface_count() != 1:
		_fail("%s: %d surfaces (1 expected)" % [name, mesh.get_surface_count()])
	var arr: Array = mesh.surface_get_arrays(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		_fail("%s: not indexed" % name)
		return
	if arr[Mesh.ARRAY_COLOR] == null or arr[Mesh.ARRAY_TEX_UV] == null or arr[Mesh.ARRAY_TEX_UV2] == null:
		_fail("%s: missing COLOR / UV / UV2" % name)
		return
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	var per := [0, 0, 0]
	var own := [0, 0, 0]
	var top := [-INF, -INF, -INF]
	var hot := 0
	for t: int in range(0, idx.size(), 3):
		var m: int = int(uv2[idx[t]].x)
		var kind: int = int(uv2[idx[t]].y)
		if kind != 0 and kind != 3 and kind != 5:
			_fail("%s: kind %d (bark / stone / ivy only)" % [name, kind])
			return
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				per[k] += 1
				for j: int in 3:
					top[k] = maxf(top[k], verts[idx[t + j]].y)
			if m != 0 and m != 7 and ((m >> k) & 1) == 1:
				own[k] += 1
	for w: Vector2 in uv:
		if w.x < 0.0 or w.x > 1.0001:
			_fail("%s: UV.x %.3f out of 0..1" % [name, w.x])
			break
		if w.x > 0.9:
			hot += 1
	if String(lim[0]) == EMBER_MAT and hot == 0:
		_fail("%s: no hot (ember) vertices" % name)
	for k: int in 3:
		if own[k] == 0:
			_fail("%s: variant %d has no own shape" % [name, k])
		if per[k] > int(lim[1]):
			_fail("%s: variant %d draws %d triangles (max %d)" % [name, k, per[k], lim[1]])
		if top[k] > float(lim[2]):
			_fail("%s: variant %d is %.2f m tall (max %.2f)" % [name, k, top[k], lim[2]])
		if top[k] * sc.y > float(lim[6]):
			_fail("%s: variant %d at scale %.2f is %.2f m tall (max %.2f)" % [name, k, sc.y, top[k] * sc.y, lim[6]])
	var aabb: AABB = mesh.get_aabb()
	if aabb.size.x > float(lim[3]) or aabb.size.z > float(lim[3]):
		_fail("%s: footprint %.2f x %.2f > %.2f" % [name, aabb.size.x, aabb.size.z, lim[3]])
	print("  %-17s variants %d / %d / %d tris, tops %.2f / %.2f / %.2f m, footprint %.2f x %.2f" % [name, per[0],
		per[1], per[2], top[0], top[1], top[2], aabb.size.x, aabb.size.z])


## ENTRIES (map-fill.md 10 format) must describe the same kinds as items().
func _check_entries() -> void:
	var s := _set_script()
	if s == null:
		return
	var consts: Dictionary = s.get_script_constant_map()
	if consts.get("BIOME_ID") != &"ruins":
		_fail("BIOME_ID is not &\"ruins\"")
	if not (consts.get("GROUND_TINT") is Color):
		_fail("GROUND_TINT is not a Color")
	var entries: Array = consts.get("ENTRIES", [])
	var items: Array = s.call(&"items")
	if entries.size() != items.size():
		_fail("ENTRIES (%d) and items() (%d) differ" % [entries.size(), items.size()])
		return
	for i: int in entries.size():
		var e: Dictionary = entries[i]
		var it: Dictionary = items[i]
		for key: String in ["mesh", "per_100m2", "scale", "cluster", "shadow", "range", "place"]:
			if not e.has(key):
				_fail("entry %d without '%s'" % [i, key])
		if String(e.get("mesh", "")) != (it["mesh"] as Mesh).resource_path:
			_fail("entry %d mesh differs from items()" % i)
		if not is_equal_approx(float(e.get("per_100m2", 0.0)), float(it["density"])) \
				or not is_equal_approx(float(e.get("range", 0.0)), float(it["vis_end"])) \
				or bool(e.get("shadow", false)) != bool(it["shadow"]) or e.get("scale") != it["scale"]:
			_fail("entry %d values differ from items()" % i)
		if e.get("place") != &"land" or not bool(e.get("paving_ok", false)):
			_fail("entry %d: place / paving_ok" % i)


## Emission only: the ember shader writes EMISSION, declares no light type, and its energy stays "faint" (1.0-2.5).
func _check_ember_material() -> void:
	var m := load(EMBER_MAT) as ShaderMaterial
	if m == null or m.shader == null:
		_fail("ruins_ember_mat.tres missing or not a ShaderMaterial")
		return
	var code: String = m.shader.code
	if not code.contains("EMISSION"):
		_fail("ember shader writes no EMISSION")
	if code.contains("unshaded") or code.contains("TRANSMISSION") or code.contains("blend_add"):
		_fail("ember shader should be an opaque lit painted material")
	var energy: Variant = m.get_shader_parameter(&"ember_energy")
	var e: float = 1.5 if energy == null else float(energy)
	if e < 1.0 or e > 2.5:
		_fail("ember_energy %.2f outside the faint 1.0-2.5 band" % e)
	if m.get_shader_parameter(&"noise_tex") == null:
		_fail("ember material has no noise_tex")


## Crown Hollow's ruins zone (GroundParams.RUINS, 4 m blend outward; the isle ends at the moat) minus the lane
## corridor (5.2 m), the crown dais, the landmark footprints and the water, times the set's density.
func _check_budget() -> void:
	var s := _set_script()
	if s == null or not ResourceLoader.exists(GP_PATH):
		return
	var gp: GDScript = load(GP_PATH)
	var zones: Array = gp.RUINS
	var river: Dictionary = gp.skirmish_river()
	var dais: float = float(s.get_script_constant_map().get("ISLE_DAIS_CLEAR", 3.8))
	var step := 0.5
	var area := 0.0        # lane corridor 5.2 m everywhere
	var area_flat := 0.0   # flat kinds: lane_clear_paving on the crown's kind-1 paving (r < 9.5)
	var isle_area := 0.0
	var flat_clear: float = float(s.get_script_constant_map().get("LANE_CLEAR_FLAT", 5.2))
	var x := -60.0
	while x < 60.0:
		var z := -60.0
		while z < 60.0:
			var q := Vector2(x + step * 0.5, z + step * 0.5)
			var w := 0.0
			for zn: Vector4 in zones:
				w = maxf(w, clampf(1.0 - (q.distance_to(Vector2(zn.x, zn.y)) - zn.z) / 4.0, 0.0, 1.0))
			if w > 0.0 and absf(q.x) < 59.6 and absf(q.y) < 59.6 and q.length() > dais:
				var c: Vector2 = Geometry2D.get_closest_point_to_segment(q, Vector2(-36, 36), Vector2(36, -36))
				var lane_d: float = q.distance_to(c)
				var ok: bool = float(gp.water_distance(river, q)) >= 0.6
				for lm: Vector2 in LANDMARK_CLEAR:
					if q.distance_to(lm) < float(LANDMARK_CLEAR[lm]) or q.distance_to(-lm) < float(LANDMARK_CLEAR[lm]):
						ok = false
				if ok and lane_d >= 5.2:
					area += w * step * step
				if ok and (lane_d >= 5.2 or (q.length() < 9.5 and lane_d >= flat_clear)):
					area_flat += w * step * step
					if q.length() < 11.0:
						isle_area += step * step
			z += step
		x += step
	var per := 0.0
	var n := 0.0
	for it: Variant in s.call(&"items"):
		var d: Dictionary = it
		per += float(d["density"])
		n += float(d["density"]) * (area_flat if float(d.get("lane_clear_paving", 0.0)) > 0.0 else area) / 100.0
	print("  ruins area %.0f m2 weighted (flat kinds %.0f m2, isle %.0f m2), %.1f per 100 m2 -> %.0f instances (budget %d)"
		% [area, area_flat, isle_area, per, n, BUDGET])
	if n > BUDGET:
		_fail("%.0f instances > %d" % [n, BUDGET])
	if isle_area < 50.0:
		_fail("almost no room on the isle (%.0f m2)" % isle_area)


## No lights, no colliders, no bodies in the folder (decor only).
func _check_folder() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		_fail("folder missing")
		return
	for f: String in dir.get_files():
		if f.get_extension() in ["tscn", "tres", "gd", "gdshader"]:
			var text: String = FileAccess.get_file_as_string(DIR + f)
			for bad: String in ["OmniLight3D", "SpotLight3D", "DirectionalLight3D", "CollisionShape3D", "StaticBody3D",
					"NavigationObstacle3D"]:
				if text.contains(bad) and not (f == "ruins_preview.gd" and bad == "DirectionalLight3D"):
					_fail("%s contains a %s" % [f, bad])


## Every item in a MultiMesh of 60 instances (what the scatter does), with its material as an override too.
func _instance_all() -> void:
	var s := _set_script()
	if s == null:
		return
	var i := 0
	for it: Variant in s.call(&"items"):
		var d: Dictionary = it
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = d["mesh"]
		mm.instance_count = 60
		for k: int in 60:
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, k * 0.7), Vector3(i * 10.0 + (k % 8) * 1.4, 0.0,
				(k / 8) * 1.4)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = d["material"]
		mmi.visibility_range_end = float(d["vis_end"])
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(d["shadow"]) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stage.add_child(mmi)
		if mm.instance_count != 60 or mmi.multimesh.mesh != d["mesh"]:
			_fail("%s: MultiMesh setup failed" % (d["mesh"] as Mesh).resource_path.get_file())
		i += 1

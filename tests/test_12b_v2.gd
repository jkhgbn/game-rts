extends SceneTree
## Task 12b.V2 (Snow set, terrain.md 7.2): the set file (section-10 ENTRIES + the shared items() format, places
## &"snow" / &"snow_edge"), the two meshes (shared painted material + the blue snow contact disc, indexed, 3 variants
## each, snow / ice / rock = stone kind without moss, no wind on the frozen parts, sizes, triangle budgets, snow really
## on them), shadows only on the rocks, ranges 65 / 90 m, <= 2 mesh kinds, the instance budget (<= 500) on the four
## terrain.md 4.2 snowfields, no lights, BiomeMap.load_items(&"snow"), headless instancing.
## Run:  godot --headless --path . -s tests/test_12b_v2.gd --fixed-fps 60 --quit-after 900
## Prints "PASS 12b.V2" or "FAIL 12b.V2: <reasons>".

const TASK_ID := "12b.V2"
const SET_PATH := "res://art/environment/biomes/snow/snow_set.gd"
const DIR := "res://art/environment/biomes/snow/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const SNOW_CONTACT_MAT := "res://art/environment/biomes/snow/snow_contact_mat.tres"
const CONTACT_SHADER := "res://art/environment/nature_props/nature_contact.gdshader"
const BIOME_MAP := "res://art/environment/biomes/biome_map.gd"
const PLACES: Array[StringName] = [&"snow", &"snow_edge"]
const ITEM_KEYS := {"mesh": TYPE_OBJECT, "material": TYPE_OBJECT, "density": TYPE_FLOAT, "scale": TYPE_VECTOR2,
	"vis_end": TYPE_FLOAT, "shadow": TYPE_BOOL, "variants": TYPE_INT}
## terrain.md 4.2 snowfields (player half; mirrors at (-x, -z)): (x, z, rx, rz).
const SNOWFIELDS: Array[Vector4] = [Vector4(-31.0, -24.0, 5.5, 5.5), Vector4(-22.0, -54.0, 7.0, 4.5)]
## Per mesh: [max triangles drawn by one variant, max height (m), max footprint (m), range, shadow, kinds].
const LIMITS := {
	"snow_capped_rocks": [500, 1.0, 2.8, 90.0, true, [3]],
	"snow_frost_scrub": [900, 1.0, 1.6, 65.0, false, [0, 3, 5]],
}
const KIND_STONE := 3

var _fails: Array[String] = []
var _frame := 0
var _stage: Node3D


func _initialize() -> void:
	_check_set_and_meshes()
	_check_items()
	_check_budget()
	_check_contact_mat()
	_check_no_lights()
	_check_biome_map()
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


func _consts() -> Dictionary:
	var script := load(SET_PATH) as GDScript
	return script.get_script_constant_map() if script != null else {}


func _check_set_and_meshes() -> void:
	var script := load(SET_PATH) as GDScript
	if script == null:
		_fail("snow_set.gd missing")
		return
	var consts: Dictionary = script.get_script_constant_map()
	if consts.get("BIOME_ID") != &"snow":
		_fail("BIOME_ID is not &\"snow\"")
	var tint: Variant = consts.get("GROUND_TINT")
	if not (tint is Color) or (tint as Color).get_luminance() < 0.8 or (tint as Color).b < (tint as Color).r:
		_fail("GROUND_TINT is not the cold snow white of terrain.md 7.1")
	if int(consts.get("VARIANTS", 0)) != 3:
		_fail("VARIANTS is not 3")
	if int(consts.get("INSTANCE_BUDGET", 9999)) > 500:
		_fail("INSTANCE_BUDGET above terrain.md's 500")
	if consts.get("PLACE_IN") != &"snow" or consts.get("PLACE_EDGE") != &"snow_edge":
		_fail("PLACE_IN / PLACE_EDGE are not &\"snow\" / &\"snow_edge\"")
	if float(consts.get("EDGE_BAND", 0.0)) <= 0.0:
		_fail("EDGE_BAND missing")
	var entries: Array = consts.get("ENTRIES", [])
	var seen := {}
	var places_seen := {}
	for e: Variant in entries:
		if not (e is Dictionary):
			_fail("entry is not a Dictionary")
			continue
		var d: Dictionary = e
		for key: String in ["id", "mesh", "per_100m2", "scale", "cluster", "shadow", "range", "place", "variants"]:
			if not d.has(key):
				_fail("entry without '%s'" % key)
		var path: String = String(d.get("mesh", ""))
		var name: String = path.get_file().get_basename()
		if not LIMITS.has(name):
			_fail("unexpected mesh %s" % path)
			continue
		var lim: Array = LIMITS[name]
		var sc: Variant = d.get("scale")
		if not (sc is Vector2) or (sc as Vector2).x < 0.5 or (sc as Vector2).y > 2.0 or (sc as Vector2).x > (sc as Vector2).y:
			_fail("%s: bad scale %s" % [name, sc])
		if float(d.get("per_100m2", 0.0)) <= 0.0:
			_fail("%s: per_100m2 <= 0" % name)
		var cl: float = float(d.get("cluster", -1.0))
		if cl < 0.0 or cl > 1.0:
			_fail("%s: cluster out of 0..1" % name)
		if not PLACES.has(d.get("place")):
			_fail("%s: bad place %s" % [name, d.get("place")])
		places_seen[d.get("place")] = true
		if absf(float(d.get("range", 0.0)) - float(lim[3])) > 0.01:
			_fail("%s: range %s, spec %s" % [name, d.get("range"), lim[3]])
		if bool(d.get("shadow", false)) != bool(lim[4]):
			_fail("%s: shadow %s (only the rocks cast)" % [name, d.get("shadow")])
		if int(d.get("variants", 0)) != 3:
			_fail("%s: variants != 3" % name)
		if not seen.has(name):
			seen[name] = true
			_check_mesh(name, path, lim)
	if seen.size() > 2:
		_fail("%d mesh kinds (terrain.md 7.2: <= 2 new kinds)" % seen.size())
	for name2: String in LIMITS:
		if not seen.has(name2):
			_fail("no entry for %s" % name2)
	for p: StringName in PLACES:
		if not places_seen.has(p):
			_fail("no entry placed on %s" % p)


func _check_mesh(name: String, path: String, lim: Array) -> void:
	if not ResourceLoader.exists(path):
		_fail("%s: mesh file missing" % name)
		return
	var mesh := load(path) as ArrayMesh
	if mesh == null:
		_fail("%s: not an ArrayMesh" % name)
		return
	var m0: Material = mesh.surface_get_material(0)
	if m0 == null or m0.resource_path != NATURE_MAT:
		_fail("%s: surface 0 is not the shared nature_mat.tres" % name)
	if mesh.get_surface_count() != 2 or mesh.surface_get_material(1) == null \
			or mesh.surface_get_material(1).resource_path != SNOW_CONTACT_MAT:
		_fail("%s: surface 1 is not the snow contact disc (snow_contact_mat.tres)" % name)
	for s: int in mesh.get_surface_count():
		var sa: Array = mesh.surface_get_arrays(s)
		if sa[Mesh.ARRAY_INDEX] == null or (sa[Mesh.ARRAY_INDEX] as PackedInt32Array).is_empty():
			_fail("%s: surface %d not indexed" % [name, s])
	var arr: Array = mesh.surface_get_arrays(0)
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		return
	if arr[Mesh.ARRAY_COLOR] == null or arr[Mesh.ARRAY_TEX_UV] == null or arr[Mesh.ARRAY_TEX_UV2] == null:
		_fail("%s: missing COLOR / UV / UV2" % name)
		return
	var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	var kinds: Array = lim[5]
	var per := [0, 0, 0]
	var own := [0, 0, 0]
	var snow_tris := 0
	var dark_tris := 0
	var ice_tris := 0
	for t: int in range(0, idx.size(), 3):
		var m: int = int(uv2[idx[t]].x)
		var kind: int = int(uv2[idx[t]].y)
		if not kinds.has(kind):
			_fail("%s: kind %d (allowed %s)" % [name, kind, kinds])
			return
		for k: int in 3:
			if m == 0 or ((m >> k) & 1) == 1:
				per[k] += 1
			if m != 0 and m != 7 and ((m >> k) & 1) == 1:
				own[k] += 1
		var c: Color = (cols[idx[t]] + cols[idx[t + 1]] + cols[idx[t + 2]]) / 3.0
		if c.b > c.r + 0.25 and c.b > 0.6:
			ice_tris += 1
		elif c.r > 0.6 and c.g > 0.66 and c.b > 0.74 and c.b >= c.r:
			snow_tris += 1
		elif c.get_luminance() < 0.4:
			dark_tris += 1
		# Frozen parts (stone kind = snow, ice, rock; bark = the shrub's twigs) never sway: UV.x must be 0 there
		# (stone: no moss under the snow); foliage wind stays within 0..0.45.
		for j: int in 3:
			var ux: float = uv[idx[t + j]].x
			if (kind == KIND_STONE or kind == 0) and absf(ux) > 0.0001:
				_fail("%s: kind %d vertex with UV.x %.3f (frozen parts must not sway / carry moss)" % [name, kind, ux])
				return
			if ux < 0.0 or ux > 0.4501:
				_fail("%s: UV.x %.3f out of 0..0.45" % [name, ux])
				return
	for k: int in 3:
		if own[k] == 0:
			_fail("%s: variant %d has no own shape" % [name, k])
		if per[k] > int(lim[0]):
			_fail("%s: variant %d draws %d triangles (max %d)" % [name, k, per[k], lim[0]])
	var tris: int = idx.size() / 3
	if snow_tris < tris / 8:
		_fail("%s: only %d of %d triangles are snow-white" % [name, snow_tris, tris])
	if dark_tris < tris / 10:
		_fail("%s: only %d of %d triangles are dark (rock / twigs / roots: the 40 m read)" % [name, dark_tris, tris])
	if ice_tris == 0:
		_fail("%s: no icicles / frost" % name)
	var aabb: AABB = mesh.get_aabb()
	if aabb.end.y > float(lim[1]) or aabb.size.x > float(lim[2]) or aabb.size.z > float(lim[2]) or aabb.position.y < -0.3:
		_fail("%s: size %s .. %s out of limits" % [name, aabb.position, aabb.end])
	print("  %-18s variants %d / %d / %d tris, snow %d, ice %d, dark %d of %d, size %.2f x %.2f x %.2f" % [name, per[0],
		per[1], per[2], snow_tris, ice_tris, dark_tris, tris, aabb.size.x, aabb.end.y, aabb.size.z])


## items(): the loaded format shared by the biome sets (mesh, material, density, scale, vis_end, shadow, variants).
func _check_items() -> void:
	var script := load(SET_PATH) as GDScript
	if script == null or not script.has_method(&"items"):
		_fail("snow_set.gd has no static items()")
		return
	var items: Variant = script.call(&"items")
	if not (items is Array) or not (items as Array).is_typed() or (items as Array).get_typed_builtin() != TYPE_DICTIONARY:
		_fail("items() is not an Array[Dictionary]")
		return
	var entries: Array = _consts().get("ENTRIES", [])
	if (items as Array).size() != entries.size():
		_fail("items() has %d entries, ENTRIES %d" % [(items as Array).size(), entries.size()])
		return
	for i: int in entries.size():
		var it: Dictionary = (items as Array)[i]
		var e: Dictionary = entries[i]
		for key: String in ITEM_KEYS:
			if not it.has(key) or typeof(it[key]) != int(ITEM_KEYS[key]):
				_fail("items()[%d]: '%s' missing or wrong type" % [i, key])
		if not (it.get("mesh") is Mesh) or (it["mesh"] as Mesh).resource_path != String(e["mesh"]):
			_fail("items()[%d]: mesh is not %s" % [i, e["mesh"]])
		if not (it.get("material") is Material) or (it["material"] as Material).resource_path != NATURE_MAT:
			_fail("items()[%d]: material is not the shared nature_mat.tres" % i)
		if absf(float(it.get("density", 0.0)) - float(e["per_100m2"])) > 0.001 \
				or absf(float(it.get("vis_end", 0.0)) - float(e["range"])) > 0.001 \
				or it.get("scale") != e["scale"] or it.get("shadow") != e["shadow"] or it.get("variants") != 3 \
				or it.get("place") != e["place"] or it.get("id") != e["id"] \
				or absf(float(it.get("gap", 0.0)) - float(e.get("gap", 0.0))) > 0.001:
			_fail("items()[%d] does not match ENTRIES[%d]" % [i, i])


## Instances the rows ask for on the four snowfields (both halves): inside = more than EDGE_BAND / 2 inside the
## outline, edge = the band of EDGE_BAND centred on it (noise-free ellipses; 0.25 m grid).
func _check_budget() -> void:
	var c: Dictionary = _consts()
	var half: float = float(c.get("EDGE_BAND", 1.0)) * 0.5
	var inside := 0.0
	var edge := 0.0
	var step := 0.25
	for f: Vector4 in SNOWFIELDS:
		for sgn: float in [1.0, -1.0]:
			var ctr := Vector2(f.x, f.y) * sgn
			var x: float = ctr.x - f.z - 2.0
			while x < ctr.x + f.z + 2.0:
				var z: float = ctr.y - f.w - 2.0
				while z < ctr.y + f.w + 2.0:
					var d: float = _sdf(Vector2(x, z), Vector4(ctr.x, ctr.y, f.z, f.w))
					if d < -half:
						inside += step * step
					elif absf(d) <= half:
						edge += step * step
					z += step
				x += step
	var n := 0.0
	for e: Variant in c.get("ENTRIES", []):
		var ed: Dictionary = e
		var area: float = edge if ed.get("place") == &"snow_edge" else inside
		n += float(ed.get("per_100m2", 0.0)) * area / 100.0
	var budget: int = int(c.get("INSTANCE_BUDGET", 500))
	print("  snowfields: %.0f m2 inside, %.0f m2 edge band -> at most %.0f instances (budget %d)" % [inside, edge, n,
		budget])
	if inside < 300.0 or inside > 450.0 or edge < 100.0:
		_fail("snowfield areas look wrong (%.0f / %.0f m2)" % [inside, edge])
	if n > float(budget):
		_fail("%.0f instances > budget %d" % [n, budget])


func _sdf(p: Vector2, e: Vector4) -> float:
	var s := Vector2(e.z, e.w)
	var q: Vector2 = (p - Vector2(e.x, e.y)) / s
	var l: float = maxf(q.length(), 0.0001)
	var g: Vector2 = q / (s * l)
	return (l - 1.0) / maxf(g.length(), 0.0001)


## The snow contact disc: the shared contact shader with a cold (blue) contact colour.
func _check_contact_mat() -> void:
	var m := load(SNOW_CONTACT_MAT) as ShaderMaterial
	if m == null or m.shader == null or m.shader.resource_path != CONTACT_SHADER:
		_fail("snow_contact_mat.tres is not a nature_contact.gdshader material")
		return
	var cc: Variant = m.get_shader_parameter(&"contact_color")
	if not (cc is Color) or (cc as Color).b <= (cc as Color).r + 0.1:
		_fail("snow contact colour is not blue (%s)" % [cc])


func _check_no_lights() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		_fail("folder missing")
		return
	for f: String in dir.get_files():
		if f.get_extension() in ["tscn", "tres", "gd", "gdshader"]:
			var text: String = FileAccess.get_file_as_string(DIR + f)
			for light: String in ["OmniLight3D", "SpotLight3D", "DirectionalLight3D", "GPUParticles3D"]:
				if text.contains(light) and not (f == "snow_preview.gd" and light == "DirectionalLight3D"):
					_fail("%s contains a %s" % [f, light])


## BiomeMap.load_items(&"snow") reads the set through its standard path, keeping each row's place.
func _check_biome_map() -> void:
	if not ResourceLoader.exists(BIOME_MAP):
		return
	var bm := load(BIOME_MAP) as GDScript
	if bm == null or not bm.has_method(&"load_items"):
		return
	var list: Array = bm.call(&"load_items", &"snow")
	var entries: Array = _consts().get("ENTRIES", [])
	if list.size() != entries.size():
		_fail("BiomeMap.load_items(&\"snow\") gives %d items, ENTRIES %d" % [list.size(), entries.size()])
		return
	for i: int in list.size():
		var it: Dictionary = list[i]
		if it.get("place") != (entries[i] as Dictionary)["place"] or it.get("biome") != &"snow":
			_fail("BiomeMap.load_items(&\"snow\")[%d] lost its place / biome" % i)


## Every mesh in a MultiMesh of 60 instances (what the scatter does), a few frames in the tree: no errors.
func _instance_all() -> void:
	var i := 0
	var done := {}
	for e: Variant in _consts().get("ENTRIES", []):
		var path: String = String((e as Dictionary)["mesh"])
		if done.has(path):
			continue
		done[path] = true
		var mesh := load(path) as Mesh
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 60
		for k: int in 60:
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, k * 0.7), Vector3(i * 12.0 + (k % 8) * 1.4, 0.0,
				(k / 8) * 1.4)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = float((e as Dictionary)["range"])
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool((e as Dictionary)["shadow"]) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stage.add_child(mmi)
		if mm.instance_count != 60 or mmi.multimesh.mesh != mesh:
			_fail("%s: MultiMesh setup failed" % path.get_file())
		i += 1

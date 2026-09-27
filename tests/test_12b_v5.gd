extends SceneTree
## Task 12b.V5 (Marsh set, terrain.md 7.2): the set file (section-10 ENTRIES + the shared items() format), the two new
## meshes (puddles on the SHARED ford film water_ford_mat.tres in shallow mode + wet halo + 3-variant rim dressing;
## rush tussocks with 3 variants), the reused 12.V7 cattails / reeds, <= 2 new mesh kinds, no shadows, no lights,
## puddle spacing (films never overlap), and the instance budget (<= 300) on the 4 marsh patches of terrain.md 4.2
## with the 4.1 priorities (water, fords, roads and the 3 m riverbank band come before mud).
## Run:  godot --headless --path . -s tests/test_12b_v5.gd --fixed-fps 60 --quit-after 900
## Prints "PASS 12b.V5" or "FAIL 12b.V5: <reasons>".

const TASK_ID := "12b.V5"
const SET_PATH := "res://art/environment/biomes/marsh/marsh_set.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const DIR := "res://art/environment/biomes/marsh/"
const RB_SET := "res://art/environment/biomes/riverbank/riverbank_set.gd"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const CONTACT_MAT := "res://art/environment/nature_props/nature_contact_mat.tres"
const WATER_FORD_MAT := "res://art/environment/water/water_ford_mat.tres"
const WATER_SHADER := "res://art/environment/water/water.gdshader"
const PLACES: Array[StringName] = [&"marsh", &"marsh_edge"]
const ITEM_KEYS := {"mesh": TYPE_OBJECT, "material": TYPE_OBJECT, "density": TYPE_FLOAT, "scale": TYPE_VECTOR2,
	"vis_end": TYPE_FLOAT, "shadow": TYPE_BOOL, "variants": TYPE_INT}
## terrain.md 4.2 marsh patches (player half; mirrors generated), 4.1 riverbank band.
const PATCHES: Array[Vector4] = [Vector4(-14.5, -33.0, 3.0, 3.0), Vector4(-2.5, -35.0, 3.0, 3.0)]
const RIVERBANK := 3.0
const CELL := 0.5

var _fails: Array[String] = []
var _frame := 0
var _stage: Node3D


func _initialize() -> void:
	_check_set()
	_check_puddles()
	_check_rushes()
	_check_items()
	_check_budget()
	_check_no_lights()
	_check_shared_water()
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


func _check_set() -> void:
	var c: Dictionary = _consts()
	if c.is_empty():
		_fail("marsh_set.gd missing")
		return
	if c.get("BIOME_ID") != &"marsh":
		_fail("BIOME_ID is not &\"marsh\"")
	if not (c.get("GROUND_TINT") is Color):
		_fail("GROUND_TINT is not a Color")
	if int(c.get("VARIANTS", 0)) != 3:
		_fail("VARIANTS is not 3")
	if int(c.get("INSTANCE_BUDGET", 999)) > 300:
		_fail("INSTANCE_BUDGET above terrain.md's 300")
	var entries: Array = c.get("ENTRIES", [])
	if entries.is_empty():
		_fail("no ENTRIES")
	var new_kinds := {}
	var reused := {}
	var places_seen := {}
	for e: Variant in entries:
		if not (e is Dictionary):
			_fail("entry is not a Dictionary")
			continue
		var d: Dictionary = e
		for key: String in ["mesh", "per_100m2", "scale", "cluster", "shadow", "range", "place"]:
			if not d.has(key):
				_fail("entry without '%s'" % key)
		var path: String = String(d.get("mesh", ""))
		var name: String = path.get_file().get_basename()
		if not ResourceLoader.exists(path):
			_fail("%s: mesh file missing" % path)
		if path.begins_with(DIR):
			new_kinds[path] = true
		else:
			reused[path] = true
		var sc: Variant = d.get("scale")
		if not (sc is Vector2) or (sc as Vector2).x < 0.5 or (sc as Vector2).y > 1.5 or (sc as Vector2).x > (sc as Vector2).y:
			_fail("%s: bad scale %s" % [name, sc])
		if float(d.get("per_100m2", 0.0)) <= 0.0:
			_fail("%s: per_100m2 <= 0" % name)
		var cl: float = float(d.get("cluster", -1.0))
		if cl < 0.0 or cl > 1.0:
			_fail("%s: cluster out of 0..1" % name)
		if not PLACES.has(d.get("place")):
			_fail("%s: bad place %s (terrain.md 7.2: &\"marsh\" / &\"marsh_edge\")" % [name, d.get("place")])
		places_seen[d.get("place")] = true
		if bool(d.get("shadow", true)):
			_fail("%s: casts shadows (small decor never does)" % name)
		var rng: float = float(d.get("range", 0.0))
		if rng != 65.0 and rng != 90.0:
			_fail("%s: range %s (terrain.md 7.2: 65 or 90)" % [name, rng])
	if new_kinds.size() > 2:
		_fail("%d new mesh kinds (terrain.md 7.2: <= 2)" % new_kinds.size())
	for p: String in [String(c.get("PUDDLES", "")), String(c.get("RUSHES", ""))]:
		if not new_kinds.has(p):
			_fail("no entry for %s" % p)
	# The reused meshes are the 12.V7 riverbank ones (already counted in the decor kinds).
	var rb: Script = load(RB_SET) as Script
	var rb_meshes := {}
	if rb != null:
		for e2: Dictionary in rb.get_script_constant_map().get("ENTRIES", []):
			rb_meshes[String(e2["mesh"])] = true
	for p2: String in reused:
		if not rb_meshes.has(p2):
			_fail("%s is neither new (marsh/) nor a riverbank set mesh" % p2)
	if not reused.has(String(c.get("CATTAILS", ""))):
		_fail("the 12.V7 cattails are not reused")
	for pl: StringName in PLACES:
		if not places_seen.has(pl):
			_fail("no entry placed on %s" % pl)
	print("  entries %d, new kinds %d, reused kinds %d" % [entries.size(), new_kinds.size(), reused.size()])


func _surface(mesh: ArrayMesh, s: int, name: String) -> Array:
	var arr: Array = mesh.surface_get_arrays(s)
	var idx: Variant = arr[Mesh.ARRAY_INDEX]
	if idx == null or (idx as PackedInt32Array).is_empty():
		_fail("%s surface %d: not indexed" % [name, s])
	return arr


## Triangles drawn per variant (mask bits of UV2.x) and whether each variant has a shape of its own.
func _variants(arr: Array, name: String, max_tris: int, kinds: Array) -> void:
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var per := [0, 0, 0]
	var own := [0, 0, 0]
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
	for k: int in 3:
		if own[k] == 0:
			_fail("%s: variant %d has no own shape" % [name, k])
		if per[k] > max_tris:
			_fail("%s: variant %d draws %d triangles (max %d)" % [name, k, per[k], max_tris])
	for i: int in uv.size():
		if int(uv2[i].y) != 3 and (uv[i].x < 0.0 or uv[i].x > 0.4501):
			_fail("%s: wind weight %.3f out of 0..0.45" % [name, uv[i].x])
			break
	print("  %-14s nature tris per variant %d / %d / %d" % [name, per[0], per[1], per[2]])


func _check_puddles() -> void:
	var c: Dictionary = _consts()
	var path: String = String(c.get("PUDDLES", ""))
	var mesh := load(path) as ArrayMesh if ResourceLoader.exists(path) else null
	if mesh == null:
		_fail("marsh_puddles.res missing")
		return
	if mesh.get_surface_count() != 3:
		_fail("marsh_puddles: %d surfaces (film, halo, rim dressing expected)" % mesh.get_surface_count())
		return
	var mats: Array[String] = [WATER_FORD_MAT, CONTACT_MAT, NATURE_MAT]
	for s: int in 3:
		var m: Material = mesh.surface_get_material(s)
		if m == null or m.resource_path != mats[s]:
			_fail("marsh_puddles surface %d material is not the shared %s" % [s, mats[s].get_file()])
	# Film: flat, up-facing, the water.gdshader vertex conventions, within PUDDLE_REACH of the origin.
	var film: Array = _surface(mesh, 0, "marsh_puddles")
	var fv: PackedVector3Array = film[Mesh.ARRAY_VERTEX]
	var fn: PackedVector3Array = film[Mesh.ARRAY_NORMAL]
	var fuv: PackedVector2Array = film[Mesh.ARRAY_TEX_UV] if film[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var fc: PackedColorArray = film[Mesh.ARRAY_COLOR] if film[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	if fuv.size() != fv.size() or fc.size() != fv.size():
		_fail("marsh_puddles film: UV / COLOR missing")
		return
	var reach := 0.0
	var y0: float = fv[0].y
	for i: int in fv.size():
		reach = maxf(reach, Vector2(fv[i].x, fv[i].z).length())
		if absf(fv[i].y - y0) > 0.001 or fv[i].y < 0.03 or fv[i].y > 0.08:
			_fail("marsh_puddles film not flat at 0.03-0.08 m (y %.3f)" % fv[i].y)
			break
		if fn[i].dot(Vector3.UP) < 0.99:
			_fail("marsh_puddles film normal not up")
			break
		if fuv[i].y < -0.001 or fuv[i].y > 0.5001:
			_fail("marsh_puddles film UV.y %.3f outside 0 (rim) .. 0.5 (centre)" % fuv[i].y)
			break
		if fc[i].r <= 0.0 or fc[i].r > 1.0 or fc[i].g < 0.05 or fc[i].g > 1.0:
			_fail("marsh_puddles film COLOR %s out of range" % fc[i])
			break
	# Front faces up (the water shader culls back faces).
	var fidx: PackedInt32Array = film[Mesh.ARRAY_INDEX]
	var conv: float = _winding()
	for t: int in range(0, fidx.size(), 3):
		var a: Vector3 = fv[fidx[t]]
		var n: Vector3 = (fv[fidx[t + 1]] - a).cross(fv[fidx[t + 2]] - a)
		if n.y * conv <= 0.0:
			_fail("marsh_puddles film triangle %d faces down" % (t / 3))
			break
	var max_reach: float = float(c.get("PUDDLE_REACH", 0.0))
	if reach > max_reach + 0.001:
		_fail("puddle film reaches %.3f m > PUDDLE_REACH %.2f" % [reach, max_reach])
	for e: Dictionary in c.get("ENTRIES", []):
		if String(e["mesh"]) == path:
			var need: float = 2.0 * reach * (e["scale"] as Vector2).y
			if float(e.get("gap", 0.0)) < need:
				_fail("puddle gap %.2f < %.2f: two films could overlap (z-fight)" % [float(e.get("gap", 0.0)), need])
	print("  marsh_puddles film %d tris, reach %.3f m, y %.3f" % [fidx.size() / 3, reach, y0])
	_surface(mesh, 1, "marsh_puddles")
	var dress: Array = _surface(mesh, 2, "marsh_puddles")
	_variants(dress, "marsh_puddles", 220, [0, 3, 5])
	var aabb: AABB = mesh.get_aabb()
	if aabb.end.y > 0.7 or aabb.position.y < -0.2:
		_fail("marsh_puddles: height %s .. %s" % [aabb.position.y, aabb.end.y])


func _check_rushes() -> void:
	var path: String = String(_consts().get("RUSHES", ""))
	var mesh := load(path) as ArrayMesh if ResourceLoader.exists(path) else null
	if mesh == null:
		_fail("marsh_rushes.res missing")
		return
	if mesh.get_surface_count() != 2 or mesh.surface_get_material(0) == null \
			or mesh.surface_get_material(0).resource_path != NATURE_MAT or mesh.surface_get_material(1) == null \
			or mesh.surface_get_material(1).resource_path != CONTACT_MAT:
		_fail("marsh_rushes: surfaces are not nature_mat + nature_contact_mat")
		return
	var arr: Array = _surface(mesh, 0, "marsh_rushes")
	if arr[Mesh.ARRAY_COLOR] == null or arr[Mesh.ARRAY_TEX_UV] == null or arr[Mesh.ARRAY_TEX_UV2] == null:
		_fail("marsh_rushes: missing COLOR / UV / UV2")
		return
	_variants(arr, "marsh_rushes", 420, [3, 5])
	_surface(mesh, 1, "marsh_rushes")
	var aabb: AABB = mesh.get_aabb()
	if aabb.end.y > 1.0 or aabb.size.x > 1.5 or aabb.size.z > 1.5 or aabb.position.y < -0.2:
		_fail("marsh_rushes: size %s .. %s" % [aabb.position, aabb.end])


func _winding() -> float:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	return 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


## items(): the loaded format shared by the biome sets.
func _check_items() -> void:
	var script := load(SET_PATH) as GDScript
	if script == null or not script.has_method(&"items"):
		_fail("marsh_set.gd has no static items()")
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
		var mesh: Mesh = it.get("mesh") as Mesh
		if mesh == null or mesh.resource_path != String(e["mesh"]):
			_fail("items()[%d]: mesh is not %s" % [i, e["mesh"]])
			continue
		var want: String = WATER_FORD_MAT if mesh.resource_path.ends_with("marsh_puddles.res") else NATURE_MAT
		if not (it.get("material") is Material) or (it["material"] as Material).resource_path != want:
			_fail("items()[%d]: material is not the shared %s" % [i, want.get_file()])
		if absf(float(it.get("density", 0.0)) - float(e["per_100m2"])) > 0.001 \
				or absf(float(it.get("vis_end", 0.0)) - float(e["range"])) > 0.001 \
				or it.get("scale") != e["scale"] or it.get("shadow") != e["shadow"] or it.get("variants") != 3 \
				or it.get("place") != e["place"] or it.get("gap", 0.0) != e.get("gap", 0.0):
			_fail("items()[%d] does not match ENTRIES[%d]" % [i, i])


## The marsh cells of terrain.md 4.1 / 4.2 (0.5 m grid, ellipse + point-symmetric 1.0 m noisy edge; water, fords, the
## 3 m riverbank band first; roads ignored = an upper bound) and the one-cell edge ring, then the instances.
func _check_budget() -> void:
	var gp := load(GP_PATH) as GDScript
	if gp == null:
		_fail("ground_params.gd missing")
		return
	var river: Dictionary = gp.call(&"skirmish_river")
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.45
	noise.seed = 5
	var patches: Array[Vector4] = []
	for pt: Vector4 in PATCHES:
		patches.append(pt)
		patches.append(Vector4(-pt.x, -pt.y, pt.z, pt.w))
	var mud := {}
	for pt2: Vector4 in patches:
		var lo := Vector2i(floori((pt2.x - pt2.z - 1.5 + 60.0) / CELL), floori((pt2.y - pt2.w - 1.5 + 60.0) / CELL))
		var hi := Vector2i(ceili((pt2.x + pt2.z + 1.5 + 60.0) / CELL), ceili((pt2.y + pt2.w + 1.5 + 60.0) / CELL))
		for i: int in range(lo.x, hi.x):
			for j: int in range(lo.y, hi.y):
				var p := Vector2(-60.0 + (i + 0.5) * CELL, -60.0 + (j + 0.5) * CELL)
				var q := Vector2((p.x - pt2.x) / pt2.z, (p.y - pt2.y) / pt2.w)
				var d: float = (q.length() - 1.0) * minf(pt2.z, pt2.w)
				var nz: float = 0.25 * (noise.get_noise_2d(p.x, p.y) + noise.get_noise_2d(-p.x, -p.y))
				if d + nz >= 0.0:
					continue
				if float(gp.call(&"water_distance", river, p)) < RIVERBANK or gp.call(&"in_ford", river, p):
					continue
				mud[Vector2i(i, j)] = true
	var edge := {}
	for c: Vector2i in mud:
		for dx: int in [-1, 0, 1]:
			for dz: int in [-1, 0, 1]:
				var n := c + Vector2i(dx, dz)
				if mud.has(n) or edge.has(n):
					continue
				var p2 := Vector2(-60.0 + (n.x + 0.5) * CELL, -60.0 + (n.y + 0.5) * CELL)
				if float(gp.call(&"water_distance", river, p2)) >= 0.3 and not gp.call(&"in_ford", river, p2):
					edge[n] = true
	# Mirror check of the stand-in mask (the TerrainSystem grid is point-symmetric; so must our budget area be).
	var asym := 0
	for c2: Vector2i in mud:
		if not mud.has(Vector2i(239 - c2.x, 239 - c2.y)):
			asym += 1
	var a_mud: float = mud.size() * CELL * CELL
	var a_edge: float = edge.size() * CELL * CELL
	var n_inst := 0.0
	for e: Variant in _consts().get("ENTRIES", []):
		var d2: Dictionary = e
		n_inst += float(d2["per_100m2"]) * (a_mud if d2["place"] == &"marsh" else a_edge) / 100.0
	var budget: int = int(_consts().get("INSTANCE_BUDGET", 300))
	print("  marsh area %.1f m2 (mud cells), edge %.1f m2, %d asymmetric cells -> %.0f instances (budget %d)" % [a_mud,
		a_edge, asym, n_inst, budget])
	if a_mud < 30.0 or a_mud > 140.0:
		_fail("marsh area %.1f m2 looks wrong (terrain.md 4.4: ~110 m2 before the riverbank cut)" % a_mud)
	if n_inst > float(budget):
		_fail("%.0f marsh instances > budget %d" % [n_inst, budget])
	if asym > 0:
		_fail("%d mud cells without their mirror" % asym)


func _check_no_lights() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		_fail("folder missing")
		return
	for f: String in dir.get_files():
		if f.get_extension() in ["tscn", "tres", "gd", "res"]:
			var text: String = FileAccess.get_file_as_string(DIR + f) if f.get_extension() != "res" else ""
			for light: String in ["OmniLight3D", "SpotLight3D", "DirectionalLight3D"]:
				if text.contains(light):
					_fail("%s contains a %s" % [f, light])
	# The set never builds materials at runtime.
	var src: String = FileAccess.get_file_as_string(SET_PATH)
	for bad: String in ["Material.new", "ShaderMaterial.new", ".duplicate("]:
		if src.contains(bad):
			_fail("marsh_set.gd builds / duplicates a material (%s)" % bad)


## The puddles use the ford film as it is: water_ford_mat.tres still in shallow mode, the shader still reads the
## conventions the puddle mesh is built for.
func _check_shared_water() -> void:
	var m := load(WATER_FORD_MAT) as ShaderMaterial
	if m == null:
		_fail("water_ford_mat.tres missing")
		return
	if absf(float(m.get_shader_parameter(&"shallow")) - 1.0) > 0.001:
		_fail("water_ford_mat.tres is no longer shallow = 1")
	var code: String = (load(WATER_SHADER) as Shader).code
	for token: String in ["uniform float shallow", "COLOR.r", "COLOR.g", "UV.y", "channel_width"]:
		if not code.contains(token):
			_fail("water.gdshader changed (%s): re-check marsh_puddles (build_marsh.gd header)" % token)


## Every mesh in a MultiMesh of 40 instances, a few frames in the tree: no errors.
func _instance_all() -> void:
	var seen := {}
	var i := 0
	for e: Variant in _consts().get("ENTRIES", []):
		var path: String = String((e as Dictionary)["mesh"])
		if seen.has(path):
			continue
		seen[path] = true
		var mesh := load(path) as Mesh
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 40
		for k: int in 40:
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, k * 0.7), Vector3(i * 20.0 + (k % 8) * 2.5, 0.0,
				(k / 8) * 2.5)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float((e as Dictionary)["range"])
		_stage.add_child(mmi)
		if mm.instance_count != 40 or mmi.multimesh.mesh != mesh:
			_fail("%s: MultiMesh setup failed" % path.get_file())
		i += 1

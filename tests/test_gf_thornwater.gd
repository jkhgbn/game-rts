extends SceneTree
## G-F review 2 item 9 (docs/art/gf_thornwater.md): Thornwater's own look (art/environment/thornwater/).
## Run: $GODOT --headless --path . -s tests/test_gf_thornwater.gd --fixed-fps 60 --quit-after 30000
## Checks: the meshes (3 thicket variants, the spire) and their budgets; LevelLooks lists the look; Crown Hollow gets
## nothing (no guard, no dressing, shared materials untouched); Thornwater (the hook's moment = level ready; headless
## never creates GroundDetail, so the test calls ensure_for_level itself): guard, idempotent, level ground painted,
## shared water / nature recoloured, the rig on preset_thornwater, the dressing at High (reeds, thickets, belt trees
## outside the map, full trees only at High+, 4 spires in the moat water, nothing small on keeps / crossings), clear_area
## hides decor, Map detail Low halves it, Low tier = palette only; freed: the shared materials equal the snapshot
## again (no leak), Crown Hollow again clean; sim mode and `disabled` = nothing.
## Prints "PASS gf_thornwater" or "FAIL gf_thornwater: <reasons>".

const TASK_ID := "gf_thornwater"
const LOOK := "res://art/environment/thornwater/thornwater_look.gd"
const PALETTE := "res://art/environment/thornwater/thornwater_palette.gd"
const MESHES := "res://art/environment/thornwater/thornwater_meshes.gd"
const SIM := preload("res://scripts/core/sim_mode.gd")
const SHARED: Array[String] = [
	"res://art/environment/water/water_mat.tres",
	"res://art/environment/water/water_ford_mat.tres",
	"res://art/environment/river_mouths/mouth_water_fallback_mat.tres",
	"res://art/environment/nature_props/nature_mat.tres",
]
## Keys compared after the restore (river data such as fords / foam rocks is each level's own, written by every map).
const KEYS: Array[String] = ["deep_color", "water_color", "bank_color", "sky_color", "foam_color", "glint_color",
	"film_color", "sand_color", "shallow_tint", "bed_sand", "bed_silt", "sky_zenith", "clarity", "autumn_chance",
	"moss_color", "moss_dark"]

var _fails := PackedStringArray()
var _notes := PackedStringArray()
var _tl: GDScript
var _held: Array[Resource] = []


func _initialize() -> void:
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _run() -> void:
	_tl = load(LOOK)
	for p: String in SHARED:
		if ResourceLoader.exists(p):
			_held.append(load(p))
	_check_meshes()
	_check_palette()
	var looks := load("res://art/environment/level_looks.gd") as Script
	var listed: Array = looks.get_script_constant_map().get("LOOKS", [])
	_check(listed.has(LOOK), "LevelLooks does not list thornwater_look.gd")
	var ref := _snapshot()
	await _crown_hollow("before")
	_check(_snapshot() == ref, "Crown Hollow changed the shared materials")
	for pass_i in 2:
		await _thornwater_pass(pass_i, ref)
		_check(_snapshot() == ref, "pass %d: shared materials not restored after Thornwater left" % pass_i)
		await _crown_hollow("after pass %d" % pass_i)
	await _low_tier_pass(ref)
	_check(_snapshot() == ref, "low tier: shared materials not restored")
	(load(MESHES) as Script).call(&"clear_cache")
	_held.clear()
	for n: String in _notes:
		print("  note: ", n)
	if _fails.is_empty():
		print("PASS " + TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _check_meshes() -> void:
	var tm := load(MESHES) as Script
	var th := tm.call(&"thicket") as ArrayMesh
	var sp := tm.call(&"thorn_spire") as ArrayMesh
	_check(th != null and sp != null, "meshes not built")
	if th == null or sp == null:
		return
	_check(tm.call(&"thicket") == th, "thicket not cached")
	var per: Array = tm.call(&"variant_tris", th)
	for k: int in 3:
		_check(int(per[k]) >= 150 and int(per[k]) <= 1100, "thicket variant %d tris %d (150-1100)" % [k, per[k]])
	var sp_tris: Array = tm.call(&"variant_tris", sp)
	_check(int(sp_tris[0]) >= 500 and int(sp_tris[0]) <= 5000, "spire tris %d (500-5000)" % sp_tris[0])
	var ab := th.get_aabb()
	_check(ab.size.y > 0.6 and ab.size.y < 1.8 and ab.size.x < 3.4, "thicket size %s" % ab.size)
	var sb := sp.get_aabb()
	_check(sb.size.y > 5.5 and sb.size.y < 8.5 and sb.size.x > 2.5, "spire size %s" % sb.size)
	_check(th.surface_get_material(0) == load("res://art/environment/nature_props/nature_mat.tres"),
		"thicket not on the shared nature_mat")
	_notes.append("thicket tris per variant %s, spire %d" % [str(per), sp_tris[0]])


func _check_palette() -> void:
	var tp := load(PALETTE) as Script
	var params: Dictionary = tp.call(&"ground_params")
	var names: Dictionary = GroundParams.uniform_names(load("res://art/environment/ground.gdshader") as Shader)
	for k: Variant in params:
		_check(names.has(String(k)), "palette key %s is not a ground uniform" % k)
	var grass: Color = params[&"grass_light"]
	var road: Color = params[&"road_color"]
	_check(road.v - grass.v >= 0.04, "road (v %.2f) does not read on the grass (v %.2f)" % [road.v, grass.v])
	var water: Dictionary = tp.get_script_constant_map()["WATER"]
	var wnames: Dictionary = GroundParams.uniform_names((load(SHARED[0]) as ShaderMaterial).shader)
	for k: Variant in water:
		_check(wnames.has(String(k)), "water key %s is not a water uniform" % k)


func _crown_hollow(tag: String) -> void:
	var lvl := MapCatalog.load_default().instantiate_level(&"crown_hollow")
	_check(lvl != null, "crown_hollow did not instantiate")
	if lvl == null:
		return
	var box: Array = []
	lvl.ready.connect(func() -> void: box.append(_tl.call(&"ensure_for_level", lvl)), CONNECT_ONE_SHOT)
	root.add_child(lvl)
	await _wait_hero(lvl)
	_check(box.size() == 1 and box[0] == null, "Crown Hollow (%s) got the Thornwater guard" % tag)
	_check(lvl.get_node_or_null(^"ThornwaterLook") == null and lvl.get_node_or_null(^"ThornwaterDressing") == null,
		"Crown Hollow (%s) has Thornwater nodes" % tag)
	_check(not bool(_tl.call(&"is_swapped")), "materials swapped during Crown Hollow (%s)" % tag)
	var gm := _level_ground(lvl)
	var tw_dark: Color = (load(PALETTE) as Script).get_script_constant_map()["GRASS_DARK"]
	_check(gm != null and not (gm.get_shader_parameter(&"grass_dark") is Color and
		(gm.get_shader_parameter(&"grass_dark") as Color).is_equal_approx(tw_dark)), "Crown Hollow (%s) ground has the Thornwater palette" % tag)
	await _free(lvl)


func _thornwater_pass(i: int, ref: Dictionary) -> void:
	var lvl := MapCatalog.load_default().instantiate_level(&"thornwater")
	_check(lvl != null, "thornwater did not instantiate")
	if lvl == null:
		return
	_tl.set(&"quality_override", 2)
	lvl.ready.connect(func() -> void: _tl.call(&"ensure_for_level", lvl), CONNECT_ONE_SHOT)
	root.add_child(lvl)
	await _wait_hero(lvl)
	var guard := lvl.get_node_or_null(^"ThornwaterLook")
	_check(guard != null, "pass %d: no ThornwaterLook guard" % i)
	_check(_tl.call(&"ensure_for_level", lvl) == guard, "pass %d: ensure not idempotent" % i)
	_check(lvl.find_children("ThornwaterDressing*", "", false, false).size() == 1, "pass %d: not exactly one dressing" % i)
	# Palette on the level ground.
	var tp := load(PALETTE) as Script
	var gm := _level_ground(lvl)
	_check(gm != null and _col_eq(gm.get_shader_parameter(&"grass_dark"), tp.get_script_constant_map()["GRASS_DARK"]),
		"pass %d: level ground not Thornwater" % i)
	_check(gm != null and float(gm.get_shader_parameter(&"biome_amount")) > 0.9, "pass %d: biome zones off" % i)
	# Shared water / nature.
	var water: Dictionary = tp.get_script_constant_map()["WATER"]
	var wm := load(SHARED[0]) as ShaderMaterial
	_check(_col_eq(wm.get_shader_parameter(&"deep_color"), water[&"deep_color"]), "pass %d: water not peaty" % i)
	var nm := load(SHARED[3]) as ShaderMaterial
	_check(absf(float(nm.get_shader_parameter(&"autumn_chance")) - 0.02) < 0.001, "pass %d: nature autumn_chance" % i)
	_check(_snapshot() != ref, "pass %d: snapshot unchanged while Thornwater is up" % i)
	# Lighting.
	var rig: Node = null
	for r: Node in get_nodes_in_group(&"lighting_rigs"):
		if lvl.is_ancestor_of(r) and r.get(&"sun") is DirectionalLight3D and r.has_method(&"apply"):
			rig = r
	var pp: Variant = rig.get(&"preset") if rig else null
	_check(pp is Resource and (pp as Resource).resource_path.ends_with("preset_thornwater.tres"),
		"pass %d: rig not on preset_thornwater" % i)
	# Dressing.
	var d := lvl.get_node_or_null(^"ThornwaterDressing")
	if d:
		_check_dressing(i, lvl, d)
	_tl.set(&"quality_override", -1)
	await _free(lvl)
	_check(not bool(_tl.call(&"is_swapped")), "pass %d: still swapped after the level left" % i)


func _check_dressing(i: int, lvl: Node, d: Node) -> void:
	var counts: Dictionary = d.get(&"counts")
	var kinds: Dictionary = (d.get_script() as Script).get_script_constant_map()
	var reeds := int(counts.get(kinds["REEDS"], 0))
	var thick := int(counts.get(kinds["THICKET"], 0))
	var spires := int(counts.get(kinds["SPIRE"], 0))
	var trees := 0
	for k: String in kinds["TREES"] + kinds["FAR_TREES"]:
		trees += int(counts.get(k, 0))
	_check(reeds >= 40, "pass %d: only %d reeds" % [i, reeds])
	_check(thick >= 40, "pass %d: only %d thickets" % [i, thick])
	_check(spires == 4, "pass %d: %d spires (4)" % [i, spires])
	_check(trees >= 150, "pass %d: only %d belt trees" % [i, trees])
	var full := 0
	for k: String in kinds["TREES"]:
		full += int(counts.get(k, 0))
	_check(full >= 50 and full <= 260, "pass %d: %d full belt trees at High (50-260, the rest far stand-ins)" % [i, full])
	# Medium: the belt keeps its count with far stand-ins only.
	_tl.set(&"quality_override", 1)
	d.call(&"build")
	var med_full := 0
	var med_trees := 0
	var mc: Dictionary = d.get(&"counts")
	for k: String in kinds["TREES"]:
		med_full += int(mc.get(k, 0))
	for k: String in kinds["FAR_TREES"]:
		med_trees += int(mc.get(k, 0))
	_check(med_full == 0 and med_trees >= trees * 0.9, "pass %d: Medium belt %d full / %d far" % [i, med_full, med_trees])
	_tl.set(&"quality_override", 2)
	d.call(&"build")
	_notes.append("pass %d: belt %d trees, %d full" % [i, trees, full])
	_check(int(counts.get(kinds["LILY"], 0)) >= 5, "pass %d: no lily pads" % i)
	_check(int(counts.get(kinds["PUDDLES"], 0)) >= 2, "pass %d: no marsh puddles" % i)
	var river: Node = lvl.get(&"river")
	var hx := MapInfo.half_x()
	var hz := MapInfo.half_z()
	for xf: Transform3D in d.call(&"instance_transforms", kinds["SPIRE"]):
		_check(bool(river.call(&"is_water", xf.origin)), "pass %d: a spire stands on land at %s" % [i, xf.origin])
		_check(float(river.call(&"distance_to_crossing", xf.origin)) > 2.5, "pass %d: a spire by a crossing (%.1f m)" % [i, float(river.call(&"distance_to_crossing", xf.origin))])
	var inside_trees := 0
	for k: String in kinds["TREES"] + kinds["FAR_TREES"]:
		for xf: Transform3D in d.call(&"instance_transforms", k):
			if absf(xf.origin.x) < hx and absf(xf.origin.z) < hz:
				inside_trees += 1
	_check(inside_trees == 0, "pass %d: %d belt trees inside the map" % [i, inside_trees])
	# Small decor never on a keep or on a crossing deck / ford.
	var keeps: Array[Vector3] = []
	for b: Node in get_nodes_in_group(&"buildings"):
		if b is Keep and lvl.is_ancestor_of(b):
			keeps.append((b as Node3D).global_position)
	var bad := 0
	for k: String in [kinds["REEDS"], kinds["CATTAILS"], kinds["RUSHES"], kinds["THICKET"], kinds["GORSE"],
			kinds["PUDDLES"], kinds["BOULDER"]]:
		for xf: Transform3D in d.call(&"instance_transforms", k):
			if xf.basis.get_scale().x < 0.001:
				continue
			for kp: Vector3 in keeps:
				if Vector2(xf.origin.x - kp.x, xf.origin.z - kp.z).length() < 6.0:
					bad += 1
			if bool(river.call(&"is_bridge", xf.origin)) or bool(river.call(&"is_ford", xf.origin)):
				bad += 1
	_check(bad == 0, "pass %d: %d small decor pieces on keeps / crossings" % [i, bad])
	# A building placed later hides the decor under it.
	var any_thicket: Array = d.call(&"instance_transforms", kinds["THICKET"])
	if not any_thicket.is_empty():
		var at: Vector3 = (any_thicket[any_thicket.size() / 2] as Transform3D).origin
		_check(int(d.call(&"clear_area", at, 2.0)) >= 1, "pass %d: clear_area hid nothing" % i)
	# Map detail Low halves the scatter, keeps the spires.
	var total := 0
	for k: Variant in counts:
		total += int(counts[k])
	MapDressingArt.map_detail_override = &"low"
	var low := int(d.call(&"build"))
	MapDressingArt.map_detail_override = &""
	_check(low < total * 0.7 and low > total * 0.3, "pass %d: Map detail Low %d vs %d" % [i, low, total])
	_check(int((d.get(&"counts") as Dictionary).get(kinds["SPIRE"], 0)) == 4, "pass %d: Low lost the spires" % i)
	_notes.append("pass %d: %d pieces (%d at Map detail Low), %d draws; reeds %d, thickets %d, trees %d" % [i, total,
		low, d.get_child_count(), reeds, thick, trees])


## Low tier: the palette still applies (a colour change), no dressing; sim mode / disabled: nothing.
func _low_tier_pass(ref: Dictionary) -> void:
	var lvl := MapCatalog.load_default().instantiate_level(&"thornwater")
	if lvl == null:
		return
	_tl.set(&"quality_override", 0)
	root.add_child(lvl)
	await _wait_hero(lvl)
	SIM.enabled = true
	_check(_tl.call(&"ensure_for_level", lvl) == null, "ensure ran in Bot Lab sim mode")
	SIM.enabled = false
	_tl.set(&"disabled", true)
	_check(_tl.call(&"ensure_for_level", lvl) == null, "ensure ran while disabled")
	_tl.set(&"disabled", false)
	_check(_snapshot() == ref, "sim / disabled changed shared materials")
	_check(_tl.call(&"ensure_for_level", lvl) != null, "low tier: no guard")
	_check(lvl.get_node_or_null(^"ThornwaterDressing") == null, "low tier: dressing added")
	_check(bool(_tl.call(&"is_swapped")), "low tier: palette not applied")
	_tl.set(&"quality_override", -1)
	await _free(lvl)


func _level_ground(lvl: Node) -> ShaderMaterial:
	for n: Node in lvl.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var sm := mi.material_override as ShaderMaterial
		if mi.mesh is PlaneMesh and sm and sm.shader and sm.shader.resource_path == "res://art/environment/ground.gdshader":
			return sm
	return null


func _wait_hero(lvl: Node) -> void:
	var n := 0
	while lvl.get(&"hero") == null and n < 6000:
		await process_frame
		n += 1
	_check(lvl.get(&"hero") != null, "%s never spawned its hero" % lvl.name)
	for k in 3:
		await process_frame


func _free(lvl: Node) -> void:
	MapInfo.release(lvl)
	lvl.queue_free()
	for k in 4:
		await process_frame


func _snapshot() -> Dictionary:
	var out := {}
	for p: String in SHARED:
		if not ResourceLoader.exists(p):
			continue
		var m := load(p) as ShaderMaterial
		var d := {}
		for k: String in KEYS:
			d[k] = var_to_str(m.get_shader_parameter(StringName(k)))
		out[p] = d
	return out


func _col_eq(v: Variant, c: Variant) -> bool:
	return v is Color and c is Color and (v as Color).is_equal_approx(c as Color)

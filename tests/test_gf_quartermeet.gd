extends SceneTree
## G-F Quartermeet identity (docs/art/gf_quartermeet.md): Quartermeet's own look (art/environment/quartermeet/).
## Run: $GODOT --headless --path . -s tests/test_gf_quartermeet.gd --fixed-fps 60 --quit-after 40000
## Checks: the meshes (stook / bale / wall variants, the standing stone) and their budgets; the palette keys are real
## uniforms and the roads read on the grass; LevelLooks lists the look; Crown Hollow and Ashwind Reach (the other autumn
## map) get nothing (no guard, no dressing, Ashwind's autumn values snapshotted); Quartermeet twice (the hook's moment =
## level ready, after main.gd's AutumnSwap; headless never creates GroundDetail, so the test calls ensure_for_level):
## the guard sits under AutumnLook, idempotent, level ground painted, shared water / nature / plateau recoloured, the rig
## on preset_quartermeet, the dressing at High (fields, walls, bales, moor rim, 4 standing stones in the moat water,
## nothing on keeps / crossings / roads), clear_area hides decor, Map detail Low halves it; freed: the shared materials
## equal the snapshot again (no leak), Ashwind again equal to its first snapshot, Crown Hollow clean; Low tier = palette
## only; sim mode and `disabled` = nothing.
## Prints "PASS gf_quartermeet" or "FAIL gf_quartermeet: <reasons>".

const TASK_ID := "gf_quartermeet"
const LOOK := "res://art/environment/quartermeet/quartermeet_look.gd"
const PALETTE := "res://art/environment/quartermeet/quartermeet_palette.gd"
const MESHES := "res://art/environment/quartermeet/quartermeet_meshes.gd"
const AUTUMN := "res://art/environment/autumn/autumn_swap.gd"
const SIM := preload("res://scripts/core/sim_mode.gd")
const NATURE := "res://art/environment/nature_props/nature_mat.tres"
const PLATEAU := "res://art/environment/plateau_mat.tres"
const SHARED: Array[String] = [
	"res://art/environment/water/water_mat.tres",
	"res://art/environment/water/water_ford_mat.tres",
	"res://art/environment/river_mouths/mouth_water_fallback_mat.tres",
	NATURE,
	PLATEAU,
]
## Keys compared (water colours, nature crowns, plateau ground colours / zones).
const KEYS: Array[String] = ["deep_color", "water_color", "bank_color", "sky_color", "foam_color", "glint_color",
	"film_color", "sand_color", "shallow_tint", "bed_sand", "bed_silt", "sky_zenith", "clarity", "crown_russet",
	"crown_amber", "crown_gold", "crown_late_green", "crown_weights", "under_bracken", "under_straw", "willow_tone",
	"sun_tint", "moss_color", "moss_dark", "grass_dark", "grass_light", "grass_warm", "road_color", "dirt_color",
	"rock_color", "biome_amount", "biome_heath_edge", "biome_tints"]

var _fails := PackedStringArray()
var _notes := PackedStringArray()
var _ql: GDScript
var _held: Array[Resource] = []


func _initialize() -> void:
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _run() -> void:
	_ql = load(LOOK)
	for p: String in SHARED:
		if ResourceLoader.exists(p):
			_held.append(load(p))
	_check_meshes()
	_check_palette()
	var looks := load("res://art/environment/level_looks.gd") as Script
	var listed: Array = looks.get_script_constant_map().get("LOOKS", [])
	_check(listed.has(LOOK), "LevelLooks does not list quartermeet_look.gd")
	var ref := _snapshot()
	await _crown_hollow("before")
	_check(_snapshot() == ref, "Crown Hollow changed the shared materials")
	var ash_ref: Dictionary = await _ashwind("before", {})
	_check(_snapshot() == ref, "Ashwind left the shared materials changed")
	for pass_i in 2:
		await _quartermeet_pass(pass_i, ref, ash_ref)
		_check(_snapshot() == ref, "pass %d: shared materials not restored after Quartermeet left" % pass_i)
	await _ashwind("after", ash_ref)
	_check(_snapshot() == ref, "Ashwind (after) left the shared materials changed")
	await _crown_hollow("after")
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
	var qm := load(MESHES) as Script
	var nature := load(NATURE)
	var sizes := {
		&"stook": [Vector2(0.9, 1.5), Vector2(0.6, 1.4), 150, 1200],
		&"bale": [Vector2(0.9, 1.5), Vector2(1.0, 2.8), 60, 600],
		&"wall": [Vector2(0.45, 0.9), Vector2(2.2, 2.9), 100, 1400],
		&"standing_stone": [Vector2(4.6, 6.0), Vector2(1.4, 3.0), 150, 1600],
	}
	var parts := PackedStringArray()
	for id: StringName in sizes:
		var m := qm.call(id) as ArrayMesh
		_check(m != null, "%s not built" % id)
		if m == null:
			continue
		_check(qm.call(id) == m, "%s not cached" % id)
		_check(m.surface_get_material(0) == nature, "%s not on the shared nature_mat" % id)
		var spec: Array = sizes[id]
		var per: Array = qm.call(&"variant_tris", m)
		for k: int in 3:
			_check(int(per[k]) >= int(spec[2]) and int(per[k]) <= int(spec[3]),
				"%s variant %d tris %d (%d-%d)" % [id, k, per[k], spec[2], spec[3]])
		var ab := m.get_aabb()
		var hy: Vector2 = spec[0]
		var wx: Vector2 = spec[1]
		_check(ab.size.y >= hy.x and ab.size.y <= hy.y, "%s height %.2f (%s)" % [id, ab.size.y, hy])
		_check(maxf(ab.size.x, ab.size.z) >= wx.x and maxf(ab.size.x, ab.size.z) <= wx.y,
			"%s width %.2f (%s)" % [id, maxf(ab.size.x, ab.size.z), wx])
		parts.append("%s %s %s" % [id, str(per), str(ab.size.snapped(Vector3(0.01, 0.01, 0.01)))])
	_notes.append("meshes: " + "; ".join(parts))


func _check_palette() -> void:
	var tp := load(PALETTE) as Script
	var params: Dictionary = tp.call(&"ground_params")
	var names: Dictionary = GroundParams.uniform_names(load("res://art/environment/ground.gdshader") as Shader)
	for k: Variant in params:
		_check(names.has(String(k)), "palette key %s is not a ground uniform" % k)
	var grass: Color = params[&"grass_light"]
	var road: Color = params[&"road_color"]
	_check(grass.v - road.v >= 0.15, "road (v %.2f) does not read on the grass (v %.2f)" % [road.v, grass.v])
	_check(grass.s <= 0.55 and (params[&"grass_warm"] as Color).s <= 0.6, "straw too saturated (units must read)")
	var consts: Dictionary = tp.get_script_constant_map()
	var wnames: Dictionary = GroundParams.uniform_names((load(SHARED[0]) as ShaderMaterial).shader)
	for k: Variant in consts["WATER"]:
		_check(wnames.has(String(k)), "water key %s is not a water uniform" % k)
	var nshader := load("res://art/environment/autumn/nature_autumn.gdshader") as Shader
	var nnames: Dictionary = GroundParams.uniform_names(nshader)
	for k: Variant in consts["NATURE"]:
		_check(nnames.has(String(k)), "nature key %s is not a nature_autumn uniform" % k)


func _crown_hollow(tag: String) -> void:
	var lvl := MapCatalog.load_default().instantiate_level(&"crown_hollow")
	_check(lvl != null, "crown_hollow did not instantiate")
	if lvl == null:
		return
	var box: Array = []
	lvl.ready.connect(func() -> void: box.append(_ql.call(&"ensure_for_level", lvl)), CONNECT_ONE_SHOT)
	root.add_child(lvl)
	await _wait_level(lvl)
	_check(box.size() == 1 and box[0] == null, "Crown Hollow (%s) got the Quartermeet guard" % tag)
	_check(_ql.call(&"guard_of", lvl) == null and lvl.get_node_or_null(^"QuartermeetDressing") == null,
		"Crown Hollow (%s) has Quartermeet nodes" % tag)
	_check(not bool(_ql.call(&"is_swapped")), "materials swapped during Crown Hollow (%s)" % tag)
	await _free(lvl)


## Ashwind Reach (the other autumn map, Wave Strike): AutumnSwap only. Returns its snapshot while it is up; `ash_ref`
## not empty = must equal it (Quartermeet left nothing behind).
func _ashwind(tag: String, ash_ref: Dictionary) -> Dictionary:
	var lvl := MapCatalog.load_default().instantiate_level(&"ashwind_reach")
	_check(lvl != null, "ashwind_reach did not instantiate")
	if lvl == null:
		return {}
	var box: Array = []
	lvl.ready.connect(func() -> void: box.append(_ql.call(&"ensure_for_level", lvl)), CONNECT_ONE_SHOT)
	root.add_child(lvl)
	await _wait_level(lvl)
	_check(box.size() == 1 and box[0] == null, "Ashwind (%s) got the Quartermeet guard" % tag)
	_check(_ql.call(&"guard_of", lvl) == null and lvl.get_node_or_null(^"QuartermeetDressing") == null,
		"Ashwind (%s) has Quartermeet nodes" % tag)
	_check(not bool(_ql.call(&"is_swapped")), "Quartermeet values live during Ashwind (%s)" % tag)
	var aut := load(AUTUMN) as Script
	_check(bool(aut.call(&"is_swapped")), "Ashwind (%s): the autumn swap is not on" % tag)
	var snap := _snapshot()
	var rig := _rig(lvl)
	var pp: Variant = rig.get(&"preset") if rig else null
	_check(not (pp is Resource and (pp as Resource).resource_path.contains("quartermeet")),
		"Ashwind (%s) rig on preset_quartermeet" % tag)
	var gm := _level_ground(lvl)
	var qdark: Color = (load(PALETTE) as Script).get_script_constant_map()["GRASS_DARK"]
	_check(gm == null or not _col_eq(gm.get_shader_parameter(&"grass_dark"), qdark),
		"Ashwind (%s) ground has the Quartermeet palette" % tag)
	var ground_snap := _ground_snapshot(gm)
	snap["ground"] = ground_snap
	snap["preset"] = (pp as Resource).resource_path if pp is Resource else ""
	if not ash_ref.is_empty():
		for k: Variant in ash_ref:
			if snap.get(k) != ash_ref[k]:
				_check(false, "Ashwind (%s): %s differs from the first Ashwind run" % [tag, k])
	await _free(lvl)
	return snap


func _quartermeet_pass(i: int, ref: Dictionary, ash_ref: Dictionary) -> void:
	var lvl := MapCatalog.load_default().instantiate_level(&"quartermeet")
	_check(lvl != null, "quartermeet did not instantiate")
	if lvl == null:
		return
	_ql.set(&"quality_override", 2)
	lvl.ready.connect(func() -> void: _ql.call(&"ensure_for_level", lvl), CONNECT_ONE_SHOT)
	root.add_child(lvl)
	await _wait_level(lvl)
	var guard := _ql.call(&"guard_of", lvl) as Node
	_check(guard != null, "pass %d: no QuartermeetLook guard" % i)
	var autumn := lvl.get_node_or_null(^"AutumnLook")
	_check(autumn != null and guard != null and guard.get_parent() == autumn,
		"pass %d: the guard is not under AutumnLook (restore order)" % i)
	_check(_ql.call(&"ensure_for_level", lvl) == guard, "pass %d: ensure not idempotent" % i)
	_check(lvl.find_children("QuartermeetDressing*", "", false, false).size() == 1, "pass %d: not exactly one dressing" % i)
	# Palette on the level ground.
	var tp := load(PALETTE) as Script
	var consts: Dictionary = tp.get_script_constant_map()
	var gm := _level_ground(lvl)
	_check(gm != null and _col_eq(gm.get_shader_parameter(&"grass_dark"), consts["GRASS_DARK"]),
		"pass %d: level ground not Quartermeet" % i)
	_check(gm != null and _col_eq(gm.get_shader_parameter(&"road_color"), consts["ROAD"]), "pass %d: roads not granite" % i)
	_check(gm != null and float(gm.get_shader_parameter(&"biome_amount")) > 0.9, "pass %d: biome zones off" % i)
	_check(gm != null and float(gm.get_shader_parameter(&"biome_wood_radius")) == 0.0, "pass %d: old wood zone on" % i)
	var hubs: Variant = gm.get_shader_parameter(&"biome_hubs") if gm else null
	var kp := (lvl.get(&"keep") as Node3D).global_position if lvl.get(&"keep") is Node3D else Vector3.INF
	_check(hubs is Vector4 and Vector2((hubs as Vector4).x, (hubs as Vector4).y).distance_to(Vector2(kp.x, kp.z)) < 0.5,
		"pass %d: infield hub not on the player keep (%s vs %s)" % [i, hubs, kp])
	# Shared water / nature / plateau.
	var water: Dictionary = consts["WATER"]
	var wm := load(SHARED[0]) as ShaderMaterial
	_check(_col_eq(wm.get_shader_parameter(&"deep_color"), water[&"deep_color"]), "pass %d: water not slate-teal" % i)
	var nm := load(NATURE) as ShaderMaterial
	_check(nm.shader and nm.shader.resource_path.ends_with("nature_autumn.gdshader"),
		"pass %d: nature_mat not on the autumn shader (AutumnSwap)" % i)
	_check(_col_eq(nm.get_shader_parameter(&"crown_gold"), (consts["NATURE"] as Dictionary)[&"crown_gold"]),
		"pass %d: crowns not golden" % i)
	var pm := load(PLATEAU) as ShaderMaterial
	_check(pm and _col_eq(pm.get_shader_parameter(&"grass_dark"), consts["GRASS_DARK"]), "pass %d: plateau not painted" % i)
	_check(_snapshot() != ref, "pass %d: snapshot unchanged while Quartermeet is up" % i)
	var during := _snapshot()
	var differs := 0
	for p: String in during:
		if ash_ref.has(p) and during[p] != ash_ref[p]:
			differs += 1
	_check(differs >= 3, "pass %d: Quartermeet shares %d / 5 material values with Ashwind (not its own look)" % [i, 5 - differs])
	# Lighting.
	var rig := _rig(lvl)
	var pp: Variant = rig.get(&"preset") if rig else null
	_check(pp is Resource and (pp as Resource).resource_path.ends_with("preset_quartermeet.tres"),
		"pass %d: rig not on preset_quartermeet" % i)
	# Dressing.
	var d := lvl.get_node_or_null(^"QuartermeetDressing")
	if d:
		_check_dressing(i, lvl, d)
	_ql.set(&"quality_override", -1)
	await _free(lvl)
	_check(not bool(_ql.call(&"is_swapped")), "pass %d: still swapped after the level left" % i)
	_check(not bool((load(AUTUMN) as Script).call(&"is_swapped")), "pass %d: autumn still swapped after the level left" % i)


func _check_dressing(i: int, lvl: Node, d: Node) -> void:
	var counts: Dictionary = d.get(&"counts")
	var kinds: Dictionary = (d.get_script() as Script).get_script_constant_map()
	var stooks := int(counts.get(kinds["STOOK"], 0))
	var walls := int(counts.get(kinds["WALL"], 0))
	var bales := int(counts.get(kinds["BALE"], 0))
	var stones := int(counts.get(kinds["STONE"], 0))
	var heath := int(counts.get(kinds["HEATHER"], 0)) + int(counts.get(kinds["GORSE"], 0))
	var plots: Array = d.get(&"plots")
	_check(plots.size() >= 8, "pass %d: only %d stook fields (>= 8)" % [i, plots.size()])
	_check(stooks >= 60 and stooks <= 400, "pass %d: %d stooks (60-400)" % [i, stooks])
	_check(walls >= 30, "pass %d: only %d wall segments" % [i, walls])
	_check(bales >= 12, "pass %d: only %d bales" % [i, bales])
	_check(stones == 4, "pass %d: %d standing stones (4)" % [i, stones])
	_check(heath >= 80, "pass %d: only %d moor rim pieces" % [i, heath])
	var river: Node = lvl.get(&"river")
	for xf: Transform3D in d.call(&"instance_transforms", kinds["STONE"]):
		_check(bool(river.call(&"is_water", xf.origin)), "pass %d: a standing stone on land at %s" % [i, xf.origin])
		_check(float(river.call(&"distance_to_crossing", xf.origin)) > 2.5,
			"pass %d: a standing stone by a crossing" % i)
	# Every quadrant got fields (fourfold mirror).
	var quads := {}
	for p: Vector4 in plots:
		quads[Vector2i(signi(int(signf(p.x))), signi(int(signf(p.y))))] = true
	_check(quads.size() == 4, "pass %d: fields in %d quadrants (4)" % [i, quads.size()])
	# Nothing on a keep, a crossing, the water or a road.
	var keeps: Array[Vector3] = []
	for b: Node in get_nodes_in_group(&"buildings"):
		if b is Keep and lvl.is_ancestor_of(b):
			keeps.append((b as Node3D).global_position)
	var roads: Array[Vector4] = []
	var lay: Resource = lvl.call(&"map_layout")
	for rd: Dictionary in lay.get(&"roads"):
		var poly: PackedVector3Array = rd.get("poly", PackedVector3Array())
		for k: int in poly.size() - 1:
			roads.append(Vector4(poly[k].x, poly[k].z, poly[k + 1].x, poly[k + 1].z))
	var bad := 0
	var on_road := 0
	for k: String in [kinds["STOOK"], kinds["BALE"], kinds["WALL"], kinds["HAY"], kinds["HEATHER"], kinds["GORSE"],
			kinds["LICHEN"]]:
		for xf: Transform3D in d.call(&"instance_transforms", k):
			if xf.basis.get_scale().x < 0.001:
				continue
			for kp: Vector3 in keeps:
				if Vector2(xf.origin.x - kp.x, xf.origin.z - kp.z).length() < 8.0:
					bad += 1
			if bool(river.call(&"is_bridge", xf.origin)) or bool(river.call(&"is_ford", xf.origin)) \
					or bool(river.call(&"is_water", xf.origin)):
				bad += 1
			var p2 := Vector2(xf.origin.x, xf.origin.z)
			for s: Vector4 in roads:
				var q := Geometry2D.get_closest_point_to_segment(p2, Vector2(s.x, s.y), Vector2(s.z, s.w))
				if q.distance_to(p2) < 2.5:
					on_road += 1
	_check(bad == 0, "pass %d: %d decor pieces on keeps / crossings / water" % [i, bad])
	_check(on_road == 0, "pass %d: %d decor pieces on a road" % [i, on_road])
	# A building placed later hides the decor under it.
	var any: Array = d.call(&"instance_transforms", kinds["STOOK"])
	if not any.is_empty():
		var at: Vector3 = (any[any.size() / 2] as Transform3D).origin
		_check(int(d.call(&"clear_area", at, 3.0)) >= 1, "pass %d: clear_area hid nothing" % i)
	# Map detail Low halves the scatter, keeps the standing stones.
	var total := 0
	for k: Variant in counts:
		total += int(counts[k])
	MapDressingArt.map_detail_override = &"low"
	var low := int(d.call(&"build"))
	MapDressingArt.map_detail_override = &""
	_check(low < total * 0.7 and low > total * 0.3, "pass %d: Map detail Low %d vs %d" % [i, low, total])
	_check(int((d.get(&"counts") as Dictionary).get(kinds["STONE"], 0)) == 4, "pass %d: Low lost the stones" % i)
	var again := int(d.call(&"build"))
	_check(again == total, "pass %d: rebuild not deterministic (%d vs %d)" % [i, again, total])
	_notes.append("pass %d: %d pieces (%d at Map detail Low), %d draws; fields %d, stooks %d, walls %d, bales %d, rim %d"
		% [i, total, low, d.get_child_count(), plots.size(), stooks, walls, bales, heath])


## Low tier: the palette still applies (a colour change), no dressing; sim mode / disabled: nothing.
func _low_tier_pass(ref: Dictionary) -> void:
	var lvl := MapCatalog.load_default().instantiate_level(&"quartermeet")
	if lvl == null:
		return
	_ql.set(&"quality_override", 0)
	root.add_child(lvl)
	await _wait_level(lvl)
	var aut_snap := _snapshot()
	SIM.enabled = true
	_check(_ql.call(&"ensure_for_level", lvl) == null, "ensure ran in Bot Lab sim mode")
	SIM.enabled = false
	_ql.set(&"disabled", true)
	_check(_ql.call(&"ensure_for_level", lvl) == null, "ensure ran while disabled")
	_ql.set(&"disabled", false)
	_check(_snapshot() == aut_snap, "sim / disabled changed shared materials")
	_check(_ql.call(&"ensure_for_level", lvl) != null, "low tier: no guard")
	_check(lvl.get_node_or_null(^"QuartermeetDressing") == null, "low tier: dressing added")
	_check(bool(_ql.call(&"is_swapped")), "low tier: palette not applied")
	_ql.set(&"quality_override", -1)
	await _free(lvl)


func _rig(lvl: Node) -> Node:
	for r: Node in get_nodes_in_group(&"lighting_rigs"):
		if lvl.is_ancestor_of(r) and r.get(&"sun") is DirectionalLight3D and r.has_method(&"apply"):
			return r
	return null


func _level_ground(lvl: Node) -> ShaderMaterial:
	for n: Node in lvl.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var sm := mi.material_override as ShaderMaterial
		if mi.mesh is PlaneMesh and sm and sm.shader and sm.shader.resource_path == "res://art/environment/ground.gdshader":
			return sm
	return null


func _ground_snapshot(gm: ShaderMaterial) -> Dictionary:
	var d := {}
	if gm == null:
		return d
	for k: String in KEYS:
		d[k] = var_to_str(gm.get_shader_parameter(StringName(k)))
	return d


## Skirmish / layout levels: the hero; Wave Strike: its director and camera.
func _wait_level(lvl: Node) -> void:
	var n := 0
	while n < 6000:
		if lvl.get(&"hero") != null:
			break
		if &"director" in lvl and lvl.get(&"director") != null and lvl.get(&"camera_rig") != null:
			break
		await process_frame
		n += 1
	_check(n < 6000, "%s never started" % lvl.name)
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
		d["shader"] = m.shader.resource_path if m.shader else ""
		for k: String in KEYS:
			d[k] = var_to_str(m.get_shader_parameter(StringName(k)))
		out[p] = d
	return out


func _col_eq(v: Variant, c: Variant) -> bool:
	return v is Color and c is Color and (v as Color).is_equal_approx(c as Color)

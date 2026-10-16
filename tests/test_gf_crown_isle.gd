extends SceneTree
## G-F crown isle variants (docs/art/gf_crown_isle.md, art/environment/crown_variants/).
## Run: $GODOT --headless --path . -s tests/test_gf_crown_isle.gd --fixed-fps 60 --quit-after 40000
## Checks: the meshes (recoloured copies keep their surfaces / gold, the stump is short, the garland); Crown Hollow gets
## nothing; Thornwater / Quartermeet / Ashwind Reach (neutral) get their variant through the real hook (the altar's
## CrownPedestalArt, `allow_headless`): pillar MultiMesh copy with the repainted mesh, RuinDressing repainted, altar Stone
## untouched, paving colour on the level's own ground, props at High (stumps / garlands / edging...), nothing in the
## lanes or on the dais, idempotent; Low = swaps only (no new draw); leaving puts every swapped value back; the shared
## materials and source meshes equal the snapshot after each map then Crown Hollow; sim mode and `disabled` = nothing.
## Prints "PASS gf_crown_isle" or "FAIL gf_crown_isle: <reasons>".

const TASK_ID := "gf_crown_isle"
const LOOK := "res://art/environment/crown_variants/crown_isle_look.gd"
const MESHES := "res://art/environment/crown_variants/crown_isle_meshes.gd"
const SIM := preload("res://scripts/core/sim_mode.gd")
const SHARED_MATS: Array[String] = [
	"res://art/environment/nature_props/nature_mat.tres",
	"res://art/environment/env_painted_mat.tres",
	"res://art/environment/ground_material.tres",
	"res://art/environment/water/water_mat.tres",
	"res://art/environment/water/water_ford_mat.tres",
]
const SHARED_MESHES: Array[String] = [
	"res://art/environment/meshes/ruin_pillar.res",
	"res://art/environment/meshes/crown_ruin_dressing.res",
	"res://art/environment/bridges/lane_bridge.res",
	"res://art/environment/crown/crown_altar.res",
	"res://art/environment/biomes/ruins/ruins_drums.res",
	"res://art/environment/biomes/ruins/ruins_flagstones.res",
]
## Water / nature keys the map looks (Thornwater, Quartermeet) also restore; ground keys of the shared .tres.
## No ready layout map besides Thornwater / Quartermeet has a crown isle: the neutral pass loads Thornwater's layout
## under another id.
const NEUTRAL_ID := &"test_neutral_isle"
const KEYS: Array[String] = ["deep_color", "water_color", "moss_color", "moss_dark", "autumn_chance", "paving_color",
	"grass_dark", "grass_light", "tint", "albedo_tint"]

var _fails := PackedStringArray()
var _notes := PackedStringArray()
var _cl: GDScript
var _held: Array[Resource] = []


func _initialize() -> void:
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _run() -> void:
	_cl = load(LOOK)
	_cl.set(&"allow_headless", true)
	for p: String in SHARED_MATS + SHARED_MESHES:
		if ResourceLoader.exists(p):
			_held.append(load(p))
	_check_meshes()
	var ref := _snapshot()
	await _crown_hollow("before")
	_check(_snapshot() == ref, "Crown Hollow changed shared values")
	for map_id: StringName in [&"thornwater", &"quartermeet", NEUTRAL_ID]:
		await _map_pass(map_id, 2)
		_check(_snapshot() == ref, "%s: shared values changed" % map_id)
		await _crown_hollow("after " + map_id)
		_check(_snapshot() == ref, "%s then Crown Hollow: shared values changed" % map_id)
	await _map_pass(&"thornwater", 0)
	_check(_snapshot() == ref, "low tier: shared values changed")
	await _off_pass()
	_cl.set(&"quality_override", -1)
	_cl.set(&"allow_headless", false)
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
	var cm := load(MESHES) as Script
	var pillar := load(SHARED_MESHES[0]) as Mesh
	for v: StringName in [&"thornwater", &"quartermeet", &"neutral"]:
		var r := cm.call(&"recolored", pillar, v) as Mesh
		_check(r != null and r != pillar, "%s: pillar not copied" % v)
		if r == null:
			continue
		_check(cm.call(&"recolored", pillar, v) == r, "%s: recoloured pillar not cached" % v)
		_check(r.get_surface_count() == pillar.get_surface_count(), "%s: pillar surface count changed" % v)
		_check(r.get_aabb().size.distance_to(pillar.get_aabb().size) < 0.01, "%s: pillar shape changed" % v)
		var st := cm.call(&"stump", pillar, v) as Mesh
		_check(st != null and st.get_aabb().end.y < 1.6 and st.get_aabb().end.y > 0.7,
			"%s: stump height %s" % [v, st.get_aabb().end.y if st else -1.0])
	var bridge := load(SHARED_MESHES[2]) as Mesh
	var rb := cm.call(&"recolored", bridge, &"thornwater") as Mesh
	_check(rb != null and rb.get_surface_count() == bridge.get_surface_count(), "bridge copy surfaces")
	if rb:
		for s: int in bridge.get_surface_count():
			_check(rb.surface_get_material(s) == bridge.surface_get_material(s), "bridge surface %d material changed" % s)
			if not bool(cm.call(&"is_painted_surface", bridge, s)):
				var a: Array = bridge.surface_get_arrays(s)
				var b: Array = rb.surface_get_arrays(s)
				_check(a[Mesh.ARRAY_COLOR] == b[Mesh.ARRAY_COLOR], "bridge gold / ember surface %d repainted" % s)
	var g := cm.call(&"garland") as Mesh
	_check(g != null and g.get_aabb().size.x > 1.0 and g.get_aabb().size.x < 2.2, "garland size")


func _crown_hollow(tag: String) -> void:
	var lvl := MapCatalog.load_default().instantiate_level(&"crown_hollow")
	_check(lvl != null, "crown_hollow did not instantiate")
	if lvl == null:
		return
	root.add_child(lvl)
	await _wait_hero(lvl)
	_check(_cl.call(&"variant_for", lvl) == &"", "Crown Hollow (%s) has a variant" % tag)
	_check(_cl.call(&"ensure_for_level", lvl) == null, "Crown Hollow (%s) ensure made a node" % tag)
	_check(lvl.find_children("CrownIsleVariant*", "", true, false).is_empty(), "Crown Hollow (%s) has the variant" % tag)
	var mmi := _pillar_mmi(lvl)
	_check(mmi == null or mmi.multimesh.mesh == load(SHARED_MESHES[0]), "Crown Hollow (%s) pillar mesh swapped" % tag)
	await _free(lvl)


func _map_pass(map_id: StringName, q: int) -> void:
	_cl.set(&"quality_override", q)
	var tag := "%s q%d" % [map_id, q]
	var lvl := _make_level(map_id)
	_check(lvl != null, "%s did not instantiate" % map_id)
	if lvl == null:
		return
	root.add_child(lvl)
	await _wait_hero(lvl)
	var want: StringName = &"neutral" if map_id == NEUTRAL_ID else map_id
	_check(_cl.call(&"variant_for", lvl) == want, "%s: variant %s" % [tag, _cl.call(&"variant_for", lvl)])
	var v := lvl.get_node_or_null(^"CrownIsleVariant")
	_check(v != null, "%s: the altar hook made no CrownIsleVariant" % tag)
	if v == null:
		await _free(lvl)
		return
	_check(_cl.call(&"ensure_for_level", lvl) == v, "%s: ensure not idempotent" % tag)
	_check(lvl.find_children("CrownIsleVariant*", "", false, false).size() == 1, "%s: not exactly one variant" % tag)
	var counts: Dictionary = v.get(&"counts")
	_notes.append("%s counts %s, pillars %d, inner_r %.1f, draws %d" % [tag, str(counts), (v.get(&"pillars") as Array).size(),
		float(v.get(&"inner_r")), int(v.call(&"draw_count"))])
	_check(int(counts.get("crossings", 0)) >= 2, "%s: the crown crossings were not repainted" % tag)
	# Pedestal: rubble repainted, the altar stone / runes untouched.
	var ped := _pedestal(lvl)
	_check(ped != null, "%s: no pedestal" % tag)
	if ped:
		var rd := ped.get_node(^"RuinDressing") as MeshInstance3D
		_check(rd.mesh != load(SHARED_MESHES[1]), "%s: RuinDressing not repainted" % tag)
		_check((ped.get_node(^"Stone") as MeshInstance3D).mesh == load(SHARED_MESHES[3]), "%s: altar stone changed" % tag)
	# Paving on the level's own ground.
	var pav: Color = (v.get_script().get_script_constant_map()["PAVING"] as Dictionary)[want]
	var gm := _level_ground(lvl)
	_check(gm != null and gm.get_shader_parameter(&"paving_color") is Color and
		(gm.get_shader_parameter(&"paving_color") as Color).is_equal_approx(pav), "%s: paving colour" % tag)
	var old_pav: Variant = null
	# Pillars.
	var mmi := _pillar_mmi(lvl)
	var isle_pillars: Array = v.get(&"pillars")
	if mmi and not isle_pillars.is_empty():
		var all_isle := mmi.multimesh.instance_count <= isle_pillars.size()
		if all_isle or q >= 1:
			_check(mmi.multimesh.mesh != load(SHARED_MESHES[0]) or not all_isle, "%s: pillar mesh not repainted" % tag)
	else:
		_notes.append("%s: no isle pillars" % tag)
	# Draws: Low adds none.
	if q == 0:
		_check(int(v.call(&"draw_count")) == 0, "%s: Low added %d draws" % [tag, v.call(&"draw_count")])
		_check(not counts.has("isle:stump") and not counts.has("isle:garland"), "%s: Low has props" % tag)
	else:
		_check(int(v.call(&"draw_count")) <= 9, "%s: %d draws (max 9)" % [tag, v.call(&"draw_count")])
		_check_props(tag, map_id, v, isle_pillars)
	# Every prop clear of the dais and the lanes, on the isle's land.
	for kind: Variant in counts:
		if String(kind) in ["paving", "crossings", "rubble", "pillars", "isle:stump", "isle:garland", "isle:pillar",
				"res://art/environment/biomes/riverbank/rb_lily_pads.res"]:
			continue
		for xf: Transform3D in v.call(&"instance_transforms", String(kind)):
			var p := Vector2(xf.origin.x, xf.origin.z)
			_check(not bool(v.call(&"blocked", p, -0.05)), "%s: %s at %s in a lane / on the dais / off the isle" % [tag, kind, p])
	# Leaving puts the level's nodes back.
	var rd_node: MeshInstance3D = ped.get_node(^"RuinDressing") if ped else null
	v.get_parent().remove_child(v)
	if rd_node:
		_check(rd_node.mesh == load(SHARED_MESHES[1]), "%s: RuinDressing not restored on exit" % tag)
	if gm:
		old_pav = gm.get_shader_parameter(&"paving_color")
		_check(not (old_pav is Color and (old_pav as Color).is_equal_approx(pav)), "%s: paving not restored on exit" % tag)
	if mmi:
		_check(mmi.multimesh.mesh == load(SHARED_MESHES[0]), "%s: pillar multimesh not restored on exit" % tag)
	v.free()
	await _free(lvl)


func _make_level(map_id: StringName) -> Node:
	if map_id != NEUTRAL_ID:
		return MapCatalog.load_default().instantiate_level(map_id)
	var lvl := MapCatalog.load_default().instantiate_level(&"thornwater")
	var lay := (load(String(lvl.get(&"layout_path"))) as Resource).duplicate()
	lay.set(&"id", NEUTRAL_ID)
	lvl.set(&"layout", lay)
	return lvl


func _check_props(tag: String, map_id: StringName, v: Node, isle_pillars: Array) -> void:
	var counts: Dictionary = v.get(&"counts")
	var n_p := isle_pillars.size()
	match map_id:
		&"thornwater":
			_check(n_p == 0 or int(counts.get("isle:stump", 0)) >= 1, "%s: no stumps" % tag)
			_check(int(counts.get("res://art/environment/biomes/marsh/marsh_rushes.res", 0)) >= 10, "%s: rushes" % tag)
			_check(int(counts.get("res://art/environment/biomes/marsh/marsh_puddles.res", 0)) >= 3, "%s: puddles" % tag)
			_check(not counts.has("isle:garland"), "%s: garlands on Thornwater" % tag)
		&"quartermeet":
			_check(not counts.has("isle:stump"), "%s: stumps on Quartermeet" % tag)
			_check(n_p == 0 or int(counts.get("isle:garland", 0)) == n_p, "%s: garlands %d / pillars %d" % [tag,
				int(counts.get("isle:garland", 0)), n_p])
			_check(int(counts.get("quartermeet:wall", 0)) >= 10, "%s: drystone edging %d" % [tag, int(counts.get("quartermeet:wall", 0))])
			for xf: Transform3D in v.call(&"instance_transforms", "quartermeet:wall"):
				var p := Vector2(xf.origin.x, xf.origin.z)
				var c: Vector2 = v.get(&"center")
				_check(absf(p.distance_to(c) - (float(v.get(&"inner_r")) - 0.7)) < 0.1, "%s: edging off the rim" % tag)
		_:
			_check(int(counts.get("res://art/environment/biomes/ruins/ruins_flagstones.res", 0)) >= 3, "%s: flagstones" % tag)
			_check(not counts.has("isle:garland"), "%s: garlands on a neutral map" % tag)


func _off_pass() -> void:
	_cl.set(&"quality_override", 2)
	_cl.set(&"disabled", true)
	var lvl := MapCatalog.load_default().instantiate_level(&"thornwater")
	root.add_child(lvl)
	await _wait_hero(lvl)
	_check(lvl.get_node_or_null(^"CrownIsleVariant") == null, "disabled: variant made")
	await _free(lvl)
	_cl.set(&"disabled", false)
	SIM.enabled = true
	lvl = MapCatalog.load_default().instantiate_level(&"thornwater")
	root.add_child(lvl)
	await _wait_hero(lvl)
	_check(lvl.get_node_or_null(^"CrownIsleVariant") == null, "sim mode: variant made")
	SIM.enabled = false
	await _free(lvl)


func _pedestal(lvl: Node) -> Node:
	for n: Node in lvl.find_children("*", "Node3D", true, false):
		if n is CrownPedestalArt:
			return n
	return null


func _pillar_mmi(lvl: Node) -> MultiMeshInstance3D:
	var env: Variant = lvl.get(&"env_props")
	if env is Node:
		return (env as Node).get_node_or_null(^"RuinPillar") as MultiMeshInstance3D
	return null


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
	for k in 4:
		await process_frame


func _free(lvl: Node) -> void:
	MapInfo.release(lvl)
	lvl.queue_free()
	for k in 4:
		await process_frame


func _snapshot() -> Dictionary:
	var out := {}
	for p: String in SHARED_MATS:
		if not ResourceLoader.exists(p):
			continue
		var m := load(p) as ShaderMaterial
		if m == null:
			continue
		var d := {}
		for k: String in KEYS:
			d[k] = var_to_str(m.get_shader_parameter(StringName(k)))
		out[p] = d
	for p: String in SHARED_MESHES:
		var mesh := load(p) as Mesh
		var d := {}
		for s: int in mesh.get_surface_count():
			var a: Array = mesh.surface_get_arrays(s)
			d[s] = [hash(a[Mesh.ARRAY_COLOR]), hash(a[Mesh.ARRAY_VERTEX]), mesh.surface_get_material(s)]
		out[p] = d
	return out

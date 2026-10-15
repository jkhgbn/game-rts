extends SceneTree
## G2a ground / grass test (docs/art/g2a_ground.md). Headless:
##   & tools\godot_run.ps1 --headless --path . -s tests/test_g2a_ground.gd --fixed-fps 60 --quit-after 3000
## Checks: the G2a scripts / shaders compile; ground.gdshader has bake_mode + relief with defaults that keep today's
## look (0 / 0); grass_blades.gdshader's uniforms; GrassClump builds 7 blades (35 verts, 21 tris); GroundDetail.ensure
## is a no-op headless (no bake, no node, so tests / perf / bots never pay for it); the tier tables keep Low empty and
## grow with the tier; MapDressingArt hooks GroundDetail. Prints "G2A_GROUND PASS" or "G2A_GROUND FAIL: ...".

const DETAIL := "res://art/environment/grass/ground_detail.gd"
const CLUMP := "res://art/environment/grass/grass_clump.gd"
const BLADES := "res://art/environment/grass/grass_blades.gdshader"
const GROUND := "res://art/environment/ground.gdshader"
const DRESSING := "res://art/environment/map_dressing_art.gd"

var fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)
		print("  FAIL ", what)


func _uniforms(path: String) -> Dictionary:
	var out := {}
	var sh := load(path) as Shader
	if sh == null:
		return out
	for u: Dictionary in sh.get_shader_uniform_list():
		out[String(u.get("name", ""))] = u
	return out


func _run() -> void:
	var detail := load(DETAIL) as Script
	_check(detail != null and detail.can_instantiate(), "ground_detail.gd compiles")
	var clump := load(CLUMP) as Script
	_check(clump != null and clump.can_instantiate(), "grass_clump.gd compiles")
	var gu := _uniforms(GROUND)
	_check(gu.has("bake_mode") and gu.has("relief"), "ground.gdshader has bake_mode + relief")
	var gsrc := FileAccess.get_file_as_string(GROUND)
	_check(gsrc.contains("uniform int bake_mode = 0;"), "bake_mode defaults to 0")
	_check(gsrc.contains("uniform float relief = 0.0;"), "relief defaults to 0 (flat light)")
	var bu := _uniforms(BLADES)
	for n: String in ["ground_col", "ground_mask", "pushers", "clears", "cam_fade", "map_half", "blade_height"]:
		_check(bu.has(n), "grass_blades.gdshader has uniform %s" % n)
	if clump:
		var mesh: ArrayMesh = clump.call(&"build")
		_check(mesh != null and mesh.get_surface_count() == 1, "GrassClump.build() makes one surface")
		if mesh:
			var arr: Array = mesh.surface_get_arrays(0)
			var nv: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var ni: int = (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size()
			_check(nv == 35 and ni == 63, "clump = 35 verts / 21 tris (got %d / %d)" % [nv, ni / 3])
	if detail:
		var rings: Array = detail.get_script_constant_map().get("RINGS", [])
		_check(rings.size() == 4, "RINGS has 4 tiers")
		if rings.size() == 4:
			_check(float(rings[0][1]) == 0.0, "Low has no grass field")
			var prev := -1.0
			for q in range(1, 4):
				var a: Array = rings[q]
				var count := PI * float(a[1]) * float(a[1]) / (float(a[0]) * float(a[0]))
				_check(count > prev, "tier %d has more clumps than tier %d" % [q, q - 1])
				prev = count
		var relief: Array = detail.get_script_constant_map().get("RELIEF", [])
		_check(relief.size() == 4 and float(relief[0]) == 0.0 and float(relief[1]) == 0.0, "no relief at Low / Medium")
		# Headless: ensure() builds nothing.
		var level := Node3D.new()
		root.add_child(level)
		await process_frame
		var gd: Variant = detail.call(&"ensure", level)
		_check(gd == null and level.get_child_count() == 0, "GroundDetail.ensure is a no-op headless")
		level.queue_free()
		await _fog_filter(detail)
	var dsrc := FileAccess.get_file_as_string(DRESSING)
	_check(dsrc.contains("ground_detail.gd") and (dsrc.contains("\"ensure\"") or dsrc.contains("&\"ensure\"")),
		"MapDressingArt hooks GroundDetail.ensure")
	if fails.is_empty():
		print("G2A_GROUND PASS")
	else:
		print("G2A_GROUND FAIL: %d (%s)" % [fails.size(), "; ".join(fails)])
	quit(0 if fails.is_empty() else 1)


## Fog filter (lead review G2a): a building the player never saw (FogOfWar keeps it visible = false) must not clear
## grass; once seen it may keep its clear after the fog hides it again (its ghost shows it anyway).
func _fog_filter(detail: Script) -> void:
	var gd := detail.new() as Node3D
	root.add_child(gd)
	var hidden := Node3D.new()
	hidden.add_to_group(&"buildings")
	hidden.visible = false
	hidden.position = Vector3(5.0, 0.0, 0.0)
	root.add_child(hidden)
	var shown := Node3D.new()
	shown.add_to_group(&"buildings")
	shown.position = Vector3(-5.0, 0.0, 0.0)
	root.add_child(shown)
	await process_frame
	gd.call(&"refresh_clears", Vector3.ZERO, 30.0)
	var list: Array = gd.call(&"clear_list")
	_check(list.size() == 1 and is_equal_approx((list[0] as Vector4).x, -5.0),
		"fog: only the visible building clears grass (got %s)" % str(list))
	hidden.visible = true
	gd.call(&"refresh_clears", Vector3.ZERO, 30.0)
	_check((gd.call(&"clear_list") as Array).size() == 2, "fog: a building in sight clears grass")
	hidden.visible = false
	gd.call(&"refresh_clears", Vector3.ZERO, 30.0)
	_check((gd.call(&"clear_list") as Array).size() == 2, "fog: a building seen once keeps its clear")
	var far := Node3D.new()
	far.add_to_group(&"buildings")
	far.position = Vector3(200.0, 0.0, 0.0)
	root.add_child(far)
	gd.call(&"refresh_clears", Vector3.ZERO, 30.0)
	_check((gd.call(&"clear_list") as Array).size() == 2, "clears: a building out of reach is skipped")
	for n: Node in [gd, hidden, shown, far]:
		n.queue_free()
	await process_frame
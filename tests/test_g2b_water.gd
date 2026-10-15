extends SceneTree
## Task G2b (water, docs/art/g2b_water.md). Headless: no renderer, so it checks the data side:
## - water.gdshader keeps every uniform RiverSystem / the materials set (12.V1 / 12.V2 names) and has the tier uniform
## - WaterQuality.apply / pin put `quality` on both shared water materials and the waterline overlay material
## - register_overlay gives a crossing body the wet-stone overlay from Medium up, removes it on Low, follows the tier
## - WaterMeshes.channel_surface still builds a water strip with the shared material and starts the watcher node
## - the crossing / lane bridge scenes register their bodies (group "water_overlays")
## - the bridge overlay shader keeps its instance uniform
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_g2b_water.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "g2b_water"
const WATER_SHADER := "res://art/environment/water/water.gdshader"
const WATERLINE_SHADER := "res://art/environment/bridges/waterline.gdshader"
const WQ := "res://art/environment/water/water_quality.gd"
const WM := "res://art/environment/water/water_meshes.gd"
const MATS: Array[String] = [
	"res://art/environment/water/water_mat.tres",
	"res://art/environment/water/water_ford_mat.tres",
	"res://art/environment/autumn/water_autumn_mat.tres",
	"res://art/environment/bridges/waterline_mat.tres",
]
## Uniforms other code writes (river_system.gd _apply_water_material_data, the .tres files, ground params).
const KEPT_UNIFORMS: Array[String] = ["noise_tex", "flow_speed", "foam_amount", "shallow", "channel_width",
		"detail", "foam_rocks", "foam_rock_count", "fords", "ford_count", "sun_dir", "deep_color", "water_color",
		"bank_color", "sky_color", "foam_color", "glint_color", "film_color", "stone_color", "sand_color"]

var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _run() -> void:
	var code := FileAccess.get_file_as_string(WATER_SHADER)
	for u in KEPT_UNIFORMS:
		_check(RegEx.create_from_string("uniform\\s+[A-Za-z0-9_]+\\s+" + u + "\\b").search(code) != null,
				"water.gdshader lost uniform " + u)
	_check(code.contains("uniform int quality = 0"),
			"water.gdshader `quality` must default to 0 (water WaterQuality never reaches stays at the Low cost)")
	# Marsh puddles share water_ford_mat.tres and get the tier through the river's build: every marsh map needs one.
	for f in DirAccess.get_files_at("res://data/maps/"):
		if not f.ends_with("_layout.tres"):
			continue
		var lt := FileAccess.get_file_as_string("res://data/maps/" + f)
		if lt.contains("\"marsh\""):
			_check(lt.contains("river = Array[Dictionary]([{"),
					f + " has the marsh biome but no river: its puddles never get the water tier (see docs/art/g2b_water.md)")
	_check(not code.contains("hint_screen_texture") and not code.contains("hint_depth_texture"),
			"water.gdshader must stay opaque (no screen / depth reads)")
	var wl := FileAccess.get_file_as_string(WATERLINE_SHADER)
	_check(wl.contains("instance uniform float water_y"), "waterline.gdshader lost its instance uniform water_y")
	_check(wl.contains("blend_mul"), "waterline.gdshader is not a multiply overlay")

	var wq: Script = load(WQ)
	_check(wq != null, "water_quality.gd does not load")
	if wq == null:
		_finish()
		return
	for q in [0, 1, 2, 3]:
		wq.call(&"pin", q)
		_check(int(wq.call(&"applied")) == q, "applied() != %d" % q)
		for path in MATS:
			var m := load(path) as ShaderMaterial
			_check(m != null, path + " does not load")
			# The headless dummy renderer has no uniform list, so the value may not be stored there: check it when it is.
			var v: Variant = m.get_shader_parameter(&"quality") if m else null
			_check(v == null or int(v) == q, "%s quality != %d" % [path, q])
	_check(int(wq.call(&"pin", 9)) == 3 and int(wq.call(&"pin", -2)) == 0, "pin() does not clamp to 0..3")

	# Overlay on a stand-in crossing body.
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	root.add_child(mi)
	wq.call(&"pin", 2)
	wq.call(&"register_overlay", mi, -0.35)
	_check(mi.is_in_group(&"water_overlays"), "register_overlay did not add the group")
	_check(mi.material_overlay != null and (mi.material_overlay as Resource).resource_path == MATS[3],
			"no waterline overlay at High")
	_check(is_equal_approx(float(mi.get_instance_shader_parameter(&"water_y")), -0.35), "water_y not set")
	wq.call(&"pin", 0)
	_check(mi.material_overlay == null, "the overlay stays on at Low (Low must cost what it did)")
	wq.call(&"pin", 1)
	_check(mi.material_overlay != null, "no overlay back at Medium")
	mi.queue_free()

	# WaterMeshes still builds a channel with the shared material, and starts the watcher.
	var wm: Script = load(WM)
	var path := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(20, 4)])
	var mesh: Variant = wm.call(&"channel_surface", path, 2.5)
	_check(mesh is ArrayMesh and (mesh as ArrayMesh).get_surface_count() == 1, "channel_surface built nothing")
	if mesh is ArrayMesh:
		var mat := (mesh as ArrayMesh).surface_get_material(0)
		_check(mat != null and mat.resource_path == MATS[0], "channel_surface lost the shared water material")
	await process_frame
	await process_frame
	_check(root.get_node_or_null(^"WaterQuality") != null, "WaterMeshes did not start the WaterQuality watcher")

	# The crossing scenes register their bodies.
	for scene_path: String in ["res://art/environment/bridges/road_bridge.tscn",
			"res://art/environment/bridges/ford_stones.tscn", "res://art/environment/bridges/crown_steps.tscn",
			"res://art/environment/bridges/lane_bridge.tscn"]:
		var n := (load(scene_path) as PackedScene).instantiate()
		root.add_child(n)
		var body := (n.get_node_or_null(^"Body") if n.has_node(^"Body") else n.get_node_or_null(^"Mesh")) as GeometryInstance3D
		_check(body != null and body.is_in_group(&"water_overlays") and body.material_overlay != null,
				scene_path + " has no waterline overlay at Medium")
		n.queue_free()
	wq.call(&"unpin")
	_finish()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)

extends SceneTree
## Task 12.V17 screenshots of the watchtower (windowed only, headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/buildings/capture/watchtower/watchtower_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 6000 -- [mode=stage|map] [only=<shot>,<shot>]
## mode=stage (default): a clean stage with the game's lighting rig, ground shader and camera (pitch 55, fov 50):
##   watchtower_neutral_z20, _capturing_z20 (fire at 55 %), _neutralising_z20 (shadow-owned, fire at 70 %),
##   _owned_fire_z20, _owned_shadow_z20, _owned_ice_z20, _owned_nature_z20, _captured_pulse_z20, _close_z14,
##   _lineup_z46 (all states side by side), _lineup_z55, _silhouette_z40 (art-keep.md 0.1 black test).
## mode=map: the real skirmish map (bot off, fog off, HUD hidden), the four towers of map-fill.md 4.1 at their spots:
##   watchtower_map_millwatch_z30 (player, fire), _map_rookwatch_z30 (neutral), _map_owlwatch_z30 (capturing),
##   _map_saltwatch_z30 (enemy, shadow), _map_z55.
## Saves docs/art/screens/watchtower_<shot>.png.

const SCENE := "res://art/buildings/capture/watchtower/watchtower.tscn"
const RIG := "res://art/environment/lighting/lighting_rig.gd"
const CAMERA := "res://scripts/ui/rts_camera.gd"
const GROUND := "res://art/environment/ground_material.tres"
const OUT := "res://docs/art/screens/watchtower_%s.png"

const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.45, 0.75, 1.0)
const NATURE := Color(0.45, 0.8, 0.35)

## [label, owner (Color or null), capture colour (or null), capture ratio]
const STATES: Array = [
	["neutral", null, null, 0.0],
	["capturing", null, FIRE, 0.55],
	["neutralising", SHADOW, FIRE, 0.7],
	["owned_fire", FIRE, null, 0.0],
	["owned_shadow", SHADOW, null, 0.0],
	["owned_ice", ICE, null, 0.0],
	["owned_nature", NATURE, null, 0.0],
]
const SPACING := 11.0
const STAGE_Z := 40.0   # away from the ground shader's centre plaza

## map-fill.md 4.1: [id, name, position, owner, capture colour, ratio]
const SPOTS: Array = [
	["millwatch", Vector3(-6, 0, 40), FIRE, null, 0.0],
	["rookwatch", Vector3(-24, 0, -41), null, null, 0.0],
	["owlwatch", Vector3(24, 0, 41), null, SHADOW, 0.4],
	["saltwatch", Vector3(6, 0, -40), SHADOW, null, 0.0],
]

var _only: PackedStringArray = PackedStringArray()
var _mode: String = "stage"
var _towers: Array[Node3D] = []
var _rig: Node3D
var _world: Node3D


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5).split(",")
		elif arg.begins_with("mode="):
			_mode = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	if _mode == "map":
		_run_map()
	else:
		_run_stage()


func _want(shot: String) -> bool:
	return _only.is_empty() or _only.has(shot)


func _shot(shot: String, zoom: float, focus: Vector3, frames: int = 40) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.rotation.y = 0.0
	_rig.call(&"focus_on", focus)
	for i: int in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path: String = OUT % shot
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s fps=%d draws=%d" % [path, Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])


func _apply_state(t: Node3D, st: Array) -> void:
	t.call(&"set_owner_color", st[1])
	t.call(&"set_capture", st[2], float(st[3]))


# ------------------------------------------------------------------------------------------------ stage

func _run_stage() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	current_scene = _world
	var lr: Node = (load(RIG) as GDScript).new()
	_world.add_child(lr)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(240, 240)
	ground.mesh = pm
	var gm := (load(GROUND) as ShaderMaterial).duplicate() as ShaderMaterial
	gm.set_shader_parameter(&"lane_a", Vector2(900, 900))
	gm.set_shader_parameter(&"lane_b", Vector2(901, 901))
	for i: int in 4:
		gm.set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)   # no keep dirt / plaza spots on the stage
	ground.material_override = gm
	_world.add_child(ground)
	_rig = (load(CAMERA) as GDScript).new()
	_world.add_child(_rig)
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"bounds", Rect2(-200, -200, 400, 400))
	var scene := load(SCENE) as PackedScene
	var x0: float = -SPACING * float(STATES.size() - 1) * 0.5
	for i: int in STATES.size():
		var t: Node3D = scene.instantiate() as Node3D
		t.position = Vector3(x0 + SPACING * float(i), 0, STAGE_Z)
		_apply_state(t, STATES[i])
		_world.add_child(t)
		_towers.append(t)
	for i2: int in 30:
		await process_frame
	# Single states, the others hidden.
	for i3: int in STATES.size():
		var shot := "%s_z20" % STATES[i3][0]
		if not _want(shot):
			continue
		_solo(i3)
		await _shot(shot, 20.0, _towers[i3].position + Vector3(0, 0, -2.5))
	if _want("close_z14"):
		_solo(3)
		await _shot("close_z14", 14.0, _towers[3].position + Vector3(0, 0, -1.8))
	if _want("captured_pulse_z20"):
		_solo(4)
		var t4: Node3D = _towers[4]
		t4.call(&"set_owner_color", null)
		t4.call(&"set_capture", SHADOW, 1.0)
		for i4: int in 90:
			await process_frame
		t4.call(&"set_owner_color", SHADOW)
		t4.call(&"set_capture", null, 0.0)
		t4.call(&"play_captured")
		await _shot("captured_pulse_z20", 20.0, t4.position + Vector3(0, 0, -2.5), 22)
	for t5: Node3D in _towers:
		t5.visible = true
	if _want("lineup_z46"):
		await _shot("lineup_z46", 46.0, Vector3(0, 0, STAGE_Z))
	if _want("lineup_z55"):
		await _shot("lineup_z55", 55.0, Vector3(0, 0, STAGE_Z))
	if _only.has("gpu"):
		await _gpu_cost()
	if _want("silhouette_z40"):
		await _silhouette()
	print("SHOTS DONE")
	quit()


func _solo(k: int) -> void:
	for i: int in _towers.size():
		_towers[i].visible = i == k


## Black silhouettes on white at zoom 40 (art-keep.md 0.1): neutral, owned, and a tower turned 90 / 180 degrees.
func _silhouette() -> void:
	root.remove_child(_world)
	var w := Node3D.new()
	root.add_child(w)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	we.environment = e
	w.add_child(we)
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var cfg: Array = [[null, 0.0], [FIRE, 0.0], [FIRE, PI * 0.5], [SHADOW, PI]]
	for i: int in cfg.size():
		var h := Node3D.new()
		h.position = Vector3(-15.0 + 10.0 * float(i), 0, 300)
		h.rotation.y = float(cfg[i][1])
		w.add_child(h)
		var t: Node3D = (load(SCENE) as PackedScene).instantiate()
		t.set(&"face_camera", false)
		t.call(&"set_owner_color", cfg[i][0])
		h.add_child(t)
	for i2: int in 5:
		await process_frame
	for g: Node in w.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi.name in ["Flames", "ContactDecal", "CaptureRing"]:
			gi.visible = false
		elif gi.name.contains("Banner"):
			pass   # the banner keeps its torn shape (discard), just black
		else:
			gi.material_override = black
	for g2: Node in w.find_children("Banner", "MeshInstance3D", true, false):
		var bm := StandardMaterial3D.new()
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.albedo_color = Color.BLACK
		bm.cull_mode = BaseMaterial3D.CULL_DISABLED
		(g2 as MeshInstance3D).material_override = bm
	var cam := Camera3D.new()
	cam.fov = 50.0
	cam.far = 500.0
	w.add_child(cam)
	var p: float = deg_to_rad(55.0)
	var focus := Vector3(0.0, 3.0, 300.0)
	cam.position = focus + Vector3(0.0, sin(p) * 40.0, cos(p) * 40.0)
	cam.rotation = Vector3(-p, 0.0, 0.0)
	cam.current = true
	for i3: int in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path: String = OUT % "silhouette_z40"
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s" % path)


# ------------------------------------------------------------------------------------------------ map

func _run_map() -> void:
	var main: Node = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	_clear_spots(main)
	# The capture points (12.C8) may already show this model: use theirs, else place our own.
	var scene := load(SCENE) as PackedScene
	for s: Array in SPOTS:
		var t: Node3D = scene.instantiate() as Node3D
		t.position = s[1]
		t.call(&"set_owner_color", s[2])
		t.call(&"set_capture", s[3], float(s[4]))
		main.add_child(t)
		_towers.append(t)
	_rig = main.get(&"camera_rig")
	_rig.set(&"edge_pan_enabled", false)
	for i: int in 40:
		await process_frame
	for s2: Array in SPOTS:
		var shot := "map_%s_z30" % s2[0]
		if _want(shot):
			await _shot(shot, 30.0, (s2[1] as Vector3) + Vector3(0, 0, 2.0))
	if _want("map_z55"):
		await _shot("map_z55", 55.0, Vector3(-12, 0, 32))
	print("SHOTS DONE")
	quit()


## Preview only: hide the drawn trees / rocks within 5.5 m of a tower spot (12.C1 keeps the point clearings free).
func _clear_spots(main: Node) -> void:
	var env: Node = main.get(&"env_props")
	var hidden := 0
	var roots: Array[Node] = []
	if env:
		roots.append(env)
	var dress: Node = main.find_child("MapDressing*", true, false)
	if dress:
		roots.append(dress)
	for r: Node in roots:
		for c: Node in r.find_children("*", "MultiMeshInstance3D", true, false):
			var mmi := c as MultiMeshInstance3D
			if mmi.multimesh == null:
				continue
			for i: int in mmi.multimesh.instance_count:
				var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
				var q := Vector2(xf.origin.x, xf.origin.z)
				for s: Array in SPOTS:
					var sp: Vector3 = s[1]
					if q.distance_to(Vector2(sp.x, sp.z)) < 5.5:
						mmi.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001),
							Vector3(xf.origin.x, -30.0, xf.origin.z)))
						hidden += 1
						break
	print("hidden props: %d" % hidden)

## GPU frame time with the seven towers shown / hidden (same view, zoom 30 and 46), `only=gpu`.
func _gpu_cost() -> void:
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	for view: Array in [[30.0, Vector3(0, 0, STAGE_Z)], [46.0, Vector3(0, 0, STAGE_Z)]]:
		_rig.set(&"_target_zoom", view[0])
		_rig.set(&"_zoom", view[0])
		_rig.call(&"focus_on", view[1])
		var totals := {"on": 0.0, "off": 0.0}
		for pass_i: int in 6:
			for mode: String in ["on", "off"]:
				for t: Node3D in _towers:
					t.visible = mode == "on"
				for i: int in 20:
					await process_frame
				var sum := 0.0
				for i2: int in 60:
					await process_frame
					sum += RenderingServer.viewport_get_measured_render_time_gpu(vp)
				totals[mode] = float(totals[mode]) + sum / 60.0 / 6.0
		print("gpu zoom %d: 7 towers %.3f ms, none %.3f ms -> %.3f ms per tower" % [int(view[0]), totals["on"], totals["off"],
			(float(totals["on"]) - float(totals["off"])) / 7.0])
	for t2: Node3D in _towers:
		t2.visible = true

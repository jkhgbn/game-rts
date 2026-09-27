extends SceneTree
## Task 12.V16 screenshots: the cosmetic critters on the real Crown Hollow skirmish map (scenes/skirmish.tscn, bot off,
## fog off, HUD hidden) with the 12.V2 river ground, the 12.V1 water and the 12.V3 / 12.V4 crossings (the way
## ground_river_preview.gd builds them), a stand-in RiverSystem (group "river", shader_params()) and the real
## CritterSystem driven by the RTS camera; then a close-up "studio" sheet of every kind and pose.
## Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/critters/tools/critter_preview.gd
##       --resolution 1600x900 --quit-after 30000 -- [only=<shot>,<shot>]
## Saves docs/art/screens/12_v16_<shot>.png.

const CS_PATH := "res://art/environment/critters/critter_system.gd"
const GP_PATH := "res://art/environment/ground_params.gd"
const WM_PATH := "res://art/environment/water/water_meshes.gd"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const LANE_BRIDGE := "res://art/environment/bridges/lane_bridge.tscn"
const ROAD_BRIDGE := "res://art/environment/bridges/road_bridge.tscn"
const FORD := "res://art/environment/bridges/ford_stones.tscn"
const STEPS := "res://art/environment/bridges/crown_steps.tscn"
const ROAD_DIR := Vector3(45, 0, -1)
const FLOW := Vector3(1, 0, 8)
const DIR := "res://art/environment/critters/"
const OUT := "res://docs/art/screens/12_v16_%s.png"
const STUDIO := Vector3(150, 0, 0)


class StandInRiver extends Node:
	var params: Dictionary = {}

	func shader_params() -> Dictionary:
		return params


var main: Node
var cs: Node3D
var rig: Node3D
var _only := PackedStringArray()
var _params := {}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5).split(",")
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


func _want(shot: String) -> bool:
	return _only.is_empty() or _only.has(shot)


func _run() -> void:
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
	for i in 30:
		await process_frame
	var gp := load(GP_PATH) as GDScript
	_params = gp.call(&"skirmish_river")
	_set_ground()
	_hide_props()
	var water := Node3D.new()
	water.name = "PreviewWater"
	main.add_child(water)
	_build_water(water)
	_place_models()
	var river := StandInRiver.new()
	river.params = _params
	river.add_to_group(&"river")
	main.add_child(river)
	(load(CS_PATH) as GDScript).set(&"map_detail_override", &"high")
	cs = (load(CS_PATH) as GDScript).new()
	cs.name = "CritterSystem"
	main.add_child(cs)
	cs.call(&"setup", main)
	rig = main.get(&"camera_rig")
	rig.set(&"edge_pan_enabled", false)
	for i in 20:
		await process_frame
	print("critters: %d (%s)" % [cs.call(&"critter_count"), ", ".join(PackedStringArray(
			["bird", "butterfly", "firefly", "dragonfly", "frog", "splash"].map(
			func(k: String) -> String: return "%s %d" % [k, cs.call(&"critter_count", StringName(k))])))])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))

	# Game views (the real system, driven by the camera).
	if _want("meadow_z25"):
		await _shot("meadow_z25", 25.0, Vector3(-25, 0, 37), 2.0)
	if _want("meadow_z12"):
		await _shot("meadow_z12", 12.0, Vector3(-24, 0, 40), 1.0)
	if _want("takeoff_z25"):
		_view(25.0, Vector3(-24, 0, 38))
		await _secs(1.0)
		var squad := _squad(["flame_guard", "flame_guard", "ember_archer"], Vector3(-30, 0, 44))
		for u: Node in squad:
			u.call(&"command_move", Vector3(-22, 0, 41))
		await _secs(2.2)
		await _save("takeoff_z25")
		await _secs(2.5)
		var flying: Array = cs.call(&"critters_info", &"bird").filter(
				func(e: Dictionary) -> bool: return e["state"] != &"ground")
		var mean := Vector3.ZERO
		for e: Dictionary in flying:
			mean += e["pos"]
			print("  bird %s %s shown=%s" % [e["state"], e["pos"], e["shown"]])
		if not flying.is_empty():
			mean /= float(flying.size())
			_view(25.0, Vector3(mean.x, 0, mean.z - mean.y * 0.7))
		await _secs(0.1)
		await _save("circling_z25")
		_view(40.0, Vector3(mean.x, 0, mean.z - mean.y * 0.7))
		await _secs(0.4)
		await _save("circling_z40")
		for u: Node in squad:
			u.queue_free()
	var frogs: Array = cs.call(&"critters_info", &"frog")
	if not frogs.is_empty() and _want("river_z18"):
		var fp: Vector3 = frogs[0]["pos"]
		await _shot("river_z18", 18.0, fp + Vector3(0, 0, 2), 2.0)
	if not frogs.is_empty() and _want("frog_jump_z8"):
		var fp: Vector3 = frogs[1]["pos"] if frogs.size() > 1 else frogs[0]["pos"]
		_view(8.0, fp)
		await _secs(1.5)
		var land := _landward(fp)
		var u2 := _squad(["flame_guard"], fp + land * 6.0)
		u2[0].call(&"command_move", fp + land * 2.5)
		var t := 0.0
		while t < 5.0:
			await _secs(0.05)
			t += 0.05
			var st: StringName = cs.call(&"critters_info", &"frog").filter(
					func(e: Dictionary) -> bool: return (e["pos"] as Vector3).distance_to(fp) < 0.1)[0]["state"]
			if st == &"jump":
				break
		await _secs(0.33)
		await _save("frog_jump_z8")
		await _secs(0.5)
		await _save("frog_splash_z8")
		u2[0].queue_free()
	if _want("oldwood_z30"):
		await _shot("oldwood_z30", 30.0, Vector3(-42, 0, -44), 2.0)
	if _want("isle_z30"):
		await _shot("isle_z30", 30.0, Vector3(-4, 0, -8), 2.0)
	if _want("game_z40"):
		await _shot("game_z40", 40.0, Vector3(-16, 0, -30), 2.0)
	if _want("glade_z40"):
		await _shot("glade_z40", 40.0, Vector3(-24, 0, 24), 2.0)
	if _want("studio"):
		await _studio()
	print("SHOTS DONE")
	quit()


func _view(zoom: float, focus: Vector3) -> void:
	rig.set(&"_target_zoom", zoom)
	rig.set(&"_zoom", zoom)
	rig.rotation.y = 0.0
	rig.call(&"focus_on", focus)


func _shot(nm: String, zoom: float, focus: Vector3, settle: float) -> void:
	_view(zoom, focus)
	await _secs(settle)
	await _save(nm)


func _save(nm: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT % nm))
	print("saved %s animated=%d draws=%d" % [nm, cs.call(&"animated_count"),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])


func _secs(s: float) -> void:
	var t := 0.0
	while t < s:
		await process_frame
		t += 1.0 / 60.0 if Engine.max_fps == 0 else 1.0 / float(Engine.max_fps)


## The unit direction from a bank point that leads away from the water.
func _landward(p: Vector3) -> Vector3:
	var gp := load(GP_PATH) as GDScript
	var best := Vector3.RIGHT
	var best_d := -INF
	for k in 16:
		var d := Vector3(cos(TAU * k / 16.0), 0, sin(TAU * k / 16.0))
		var q := p + d * 5.0
		var wd := float(gp.call(&"water_distance", _params, Vector2(q.x, q.z)))
		if wd > best_d:
			best_d = wd
			best = d
	return best


func _squad(ids: Array, at: Vector3) -> Array:
	var out := []
	for i in ids.size():
		var u: Node3D = main.call(&"make_unit", ids[i])
		if u == null:
			continue
		u.set(&"team", 0)
		main.add_child(u)
		u.global_position = at + Vector3((i % 3) * 1.4, 0.0, (i / 3) * 1.6)
		out.append(u)
	return out


# ---------------------------------------------------------------- studio close-ups

func _mmi(kind: String, count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = load(DIR + "meshes/critter_%s.res" % kind)
	mm.instance_count = count
	mm.custom_aabb = AABB(Vector3(-500, -10, -500), Vector3(1000, 50, 1000))
	var parked := Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3(0, -200, 0))
	for i in count:
		mm.set_instance_transform(i, parked)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = load(DIR + "materials/critter_%s_mat.tres" % kind)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.custom_aabb = mm.custom_aabb
	main.add_child(mi)
	return mm


func _put(mm: MultiMesh, i: int, at: Vector3, yaw: float, s: float, c: Color) -> void:
	mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), STUDIO + at))
	mm.set_instance_custom_data(i, c)


## Close-ups of every kind and pose on a small ground patch + a water pool beside the map, 6 views in a sheet.
func _studio() -> void:
	cs.call(&"set_enabled", false)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(36, 36)
	ground.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.26, 0.36, 0.16)
	ground.material_override = sm
	main.add_child(ground)
	ground.global_position = STUDIO
	var pool := MeshInstance3D.new()
	var wpm := PlaneMesh.new()
	wpm.size = Vector2(8, 8)
	pool.mesh = wpm
	pool.material_override = load("res://art/environment/water/water_mat.tres")
	main.add_child(pool)
	pool.global_position = STUDIO + Vector3(10, -0.35 + 0.001, 0)
	# Lift the ground away from the pool (the pool is below ground level): a hole = move the grass patch aside.
	ground.global_position = STUDIO + Vector3(-12, 0, 0)
	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.far = 200.0
	main.add_child(cam)
	cam.make_current()
	var clock := func() -> float: return float(cs.get(&"_clock"))
	var birds := _mmi("bird", 18)
	var bfly := _mmi("butterfly", 4)
	var dfly := _mmi("dragonfly", 2)
	var frog := _mmi("frog", 3)
	var ffly := _mmi("firefly", 6)
	var spl := _mmi("splash", 2)
	var frames: Array[Image] = []
	# 1. Birds on the ground (crow, finch, bluewing), 2. the same three in flight (flapping flare).
	var t := float(clock.call())
	_put(birds, 0, Vector3(-13.0, 0, 0.0), 0.6, 1.25, Color(t, 0, 0, 0))
	_put(birds, 6, Vector3(-12.3, 0, 0.35), -0.9, 0.95, Color(t - 1.2, 0, 0, 0))
	_put(birds, 12, Vector3(-11.6, 0, -0.1), 2.2, 1.05, Color(t - 0.6, 0, 0, 0))
	await _studio_cam(cam, Vector3(-12.3, 0.1, 0.1), 2.6, 25.0, 20.0)
	frames.append(await _grab_after(0.9))
	for b: Array in [[1, Vector3(-13.0, 0, 3.0), 0.0], [7, Vector3(-12.0, 0, 3.2), 0.0], [13, Vector3(-11.0, 0, 2.8), 0.0]]:
		_put(birds, b[0], b[1], b[2], 1.1, Color(0, 0, 0, 0))
	await _studio_cam(cam, Vector3(-12.0, 0.9, 3.0), 3.4, 18.0, 30.0)
	for k in 3:
		var tt := float(clock.call())
		# LAND mode at the flare (e ~ 0.85 of a 1.6 s glide from 40 m up: ~0.9 m above the anchor), wings beating.
		_put(birds, [1, 7, 13][k], [Vector3(-13.0, 0, 3.0), Vector3(-12.0, 0, 3.2), Vector3(-11.0, 0, 2.8)][k],
				0.0, [1.25, 0.95, 1.05][k], Color(tt - 1.36 - 0.03 * k, 140.0, 0.0001, 0.0))
	frames.append(await _grab_after(0.0))
	for k in 3:
		birds.set_instance_transform([1, 7, 13][k], Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3(0, -200, 0)))
	# 3. Butterflies (4 palettes), low loops.
	for k in 4:
		_put(bfly, k, Vector3(-13.5 + k * 1.0, 0, 6.0 + (k % 2) * 0.4), 0.0, 1.0,
				Color(0.13 + 0.21 * k, float(k), 0.06, 0.7))
	await _studio_cam(cam, Vector3(-12.0, 0.7, 6.2), 3.6, 24.0, 10.0)
	frames.append(await _grab_after(0.6))
	# 4. Dragonflies (2 palettes) over the pool, fireflies behind.
	_put(dfly, 0, Vector3(9.0, -0.35, 0.0), 1.6, 1.0, Color(0.2, 0.0, 0.02, 0.02))
	_put(dfly, 1, Vector3(10.2, -0.35, 0.6), 1.2, 1.0, Color(0.7, 1.0, 0.02, 0.02))
	for k in 6:
		_put(ffly, k, Vector3(8.5 + k * 0.6, -0.6, 2.2 + (k % 2) * 0.5), 0.0, 1.0, Color(0.1 + 0.15 * k, 0, 0.35, 0))
	await _studio_cam(cam, Vector3(9.8, 0.25, 0.8), 3.2, 22.0, 15.0)
	frames.append(await _grab_after(0.5))
	# 5. Frogs: sitting on the edge, mid-leap, emerging.
	var tf := float(clock.call())
	_put(frog, 0, Vector3(5.6, 0.0, -0.8), 1.3, 1.1, Color(tf, 0, 0, 0))
	_put(frog, 1, Vector3(5.5, 0.0, 0.4), 1.57, 1.1, Color(tf - 0.12 - 0.2, 1.0, 1.4, 0.0))
	_put(frog, 2, Vector3(5.6, 0.0, 1.6), 1.57, 1.1, Color(tf - 0.72, 2.0, 1.2, 0.0))
	await _studio_cam(cam, Vector3(6.3, 0.0, 0.4), 2.8, 20.0, -35.0)
	frames.append(await _grab_after(0.0))
	# 6. Fish leap + a plain splash.
	var ts := float(clock.call())
	_put(spl, 0, Vector3(10.0, -0.35, -1.2), 1.57, 1.0, Color(ts - 0.42, 1.0, 0, 0))
	_put(spl, 1, Vector3(11.4, -0.35, 0.6), 0.0, 1.0, Color(ts - 0.25, 0.0, 0, 0))
	await _studio_cam(cam, Vector3(10.6, 0.0, -0.3), 3.6, 24.0, 10.0)
	frames.append(await _grab_after(0.0))
	_sheet(frames, "detail")
	(main.get(&"camera_rig").get(&"camera") as Camera3D).make_current()
	cs.call(&"set_enabled", true)


func _studio_cam(cam: Camera3D, target: Vector3, dist: float, pitch_deg: float, yaw_deg: float) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var off := Vector3(0, sin(pitch), cos(pitch)).rotated(Vector3.UP, yaw) * dist
	cam.global_position = STUDIO + target + off
	cam.look_at(STUDIO + target, Vector3.UP)
	await process_frame


func _grab_after(s: float) -> Image:
	if s > 0.0:
		await _secs(s)
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _sheet(frames: Array[Image], nm: String) -> void:
	var w := 640
	var h := 360
	var cols := 3
	var rows := (frames.size() + cols - 1) / cols
	var out := Image.create(w * cols, h * rows, false, frames[0].get_format())
	for i in frames.size():
		var im := frames[i]
		im.resize(w, h)
		out.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	out.save_png(ProjectSettings.globalize_path(OUT % nm))
	print("saved sheet %s" % nm)


# ---------------------------------------------------------------- map setup (as ground_river_preview.gd)

func _set_ground() -> void:
	var gp := load(GP_PATH) as GDScript
	for node: Node in main.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var sm := mi.material_override as ShaderMaterial
		if sm == null or sm.shader == null or sm.shader.resource_path != GROUND_SHADER or not (mi.mesh is PlaneMesh):
			continue
		if (mi.mesh as PlaneMesh).size.x > 121.0:
			continue
		gp.call(&"apply", sm, _params)
		gp.call(&"apply", sm, gp.call(&"skirmish_biomes"))


func _hide_props() -> void:
	var gp := load(GP_PATH) as GDScript
	var bridges: Array[Vector2] = [Vector2(-12, -48.7), Vector2(12, 48.7), Vector2(-9.02, 9.02), Vector2(9.02, -9.02)]
	for node: Node in main.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := node as MultiMeshInstance3D
		if mmi.multimesh == null or mmi.get_parent() == cs:
			continue
		var gx: Transform3D = mmi.global_transform
		for i: int in mmi.multimesh.instance_count:
			var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
			var wp: Vector3 = gx * xf.origin
			var q := Vector2(wp.x, wp.z)
			var hide: bool = float(gp.call(&"water_distance", _params, q)) < 1.2 or bool(gp.call(&"in_ford", _params, q))
			for b: Vector2 in bridges:
				if q.distance_to(b) < 6.0:
					hide = true
			if hide:
				mmi.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001),
						Vector3(xf.origin.x, -30.0, xf.origin.z)))


func _build_water(parent: Node3D) -> void:
	if not ResourceLoader.exists(WM_PATH):
		return
	var wm := load(WM_PATH) as GDScript
	var gp := load(GP_PATH) as GDScript
	var moat: Vector4 = gp.MOAT
	var half: float = gp.HALF_WIDTH
	var circles: Array[Vector4] = gp.CIRCLES
	var river_n := PackedVector2Array(gp.RIVER_N)
	var river_s: PackedVector2Array = gp.call(&"mirrored", river_n)
	var moat_path: PackedVector2Array = wm.call(&"arc_path", Vector2.ZERO, moat.z, 180.0, 540.0, 0.6)
	var moat_w: PackedVector2Array = wm.call(&"arc_path", Vector2.ZERO, moat.z, 258.69, 78.69, 0.6)
	var moat_e: PackedVector2Array = wm.call(&"arc_path", Vector2.ZERO, moat.z, 258.69, 438.69, 0.6)
	var fords := PackedVector4Array(circles)
	for mp: String in [wm.WATER_MAT, wm.FORD_MAT]:
		var m := load(mp) as ShaderMaterial
		if m:
			m.set_shader_parameter(&"fords", fords)
			m.set_shader_parameter(&"ford_count", fords.size())
	var dist_river := func(p: Vector2) -> float:
		return minf(float(wm.call(&"distance_to_path", river_n, p)), float(wm.call(&"distance_to_path", river_s, p)))
	var in_moat := func(p: Vector2) -> float: return 0.0 if p.length() < moat.z + moat.w + 0.3 else 1.0
	var near_river := func(p: Vector2) -> float: return 0.0 if float(dist_river.call(p)) < half + 0.35 else 1.0
	var skip_river := func(p: Vector2) -> bool: return p.length() < moat.z + moat.w - 0.05
	var skip_moat := func(p: Vector2) -> bool: return p.length() > moat.z and float(dist_river.call(p)) < half - 0.05
	var s_len := 0.0
	for i: int in river_n.size() - 1:
		s_len += river_n[i].distance_to(river_n[i + 1])
	var radial := PackedVector2Array([moat_w[0], moat_w[moat_w.size() - 1]])
	var wy: float = wm.WATER_Y
	_add(parent, wm.call(&"channel_surface", river_n, half, wy - 0.004, 0.0, 1.0, in_moat))
	_add(parent, wm.call(&"channel_surface", river_s, half, wy - 0.004, s_len + 40.0, 1.0, in_moat))
	_add(parent, wm.call(&"channel_surface", moat_w, moat.w, wy, s_len, 0.6, near_river, true, radial))
	_add(parent, wm.call(&"channel_surface", moat_e, moat.w, wy, s_len, 0.6, near_river, false, radial))
	_add(parent, wm.call(&"ford_film", river_n, half, Vector2(circles[0].x, circles[0].y), circles[0].z))
	_add(parent, wm.call(&"ford_film", river_s, half, Vector2(circles[1].x, circles[1].y), circles[1].z))
	_add(parent, wm.call(&"ford_film", moat_w, moat.w, Vector2(circles[2].x, circles[2].y), circles[2].z, wm.FILM_Y, s_len))
	_add(parent, wm.call(&"ford_film", moat_e, moat.w, Vector2(circles[3].x, circles[3].y), circles[3].z, wm.FILM_Y, s_len))
	_add(parent, wm.call(&"channel_walls", river_n, half, skip_river, wm.WALL_BOTTOM_Y, 0.8, 1))
	_add(parent, wm.call(&"channel_walls", river_s, half, skip_river, wm.WALL_BOTTOM_Y, 0.8, 3))
	_add(parent, wm.call(&"channel_walls", moat_path, moat.w, skip_moat, wm.WALL_BOTTOM_Y, 0.8, 2))
	_add(parent, wm.call(&"ford_end_walls", river_n, half, Vector2(circles[0].x, circles[0].y), circles[0].z))
	_add(parent, wm.call(&"ford_end_walls", river_s, half, Vector2(circles[1].x, circles[1].y), circles[1].z))
	for i: int in [2, 3]:
		_add(parent, wm.call(&"ford_end_walls", moat_path, moat.w, Vector2(circles[i].x, circles[i].y), circles[i].z))


func _add(parent: Node3D, mesh: Mesh) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _place_models() -> void:
	var list: Array = [
		[ROAD_BRIDGE, Vector3(-12, 0, -48.7), ROAD_DIR], [ROAD_BRIDGE, Vector3(12, 0, 48.7), ROAD_DIR],
		[FORD, Vector3(-8.5, 0, -34), FLOW], [FORD, Vector3(8.5, 0, 34), FLOW],
		[STEPS, Vector3(-9.02, 0, -9.02), Vector3.ZERO], [STEPS, Vector3(9.02, 0, 9.02), Vector3.ZERO],
	]
	for e: Array in list:
		if not ResourceLoader.exists(e[0]):
			continue
		var m: Node3D = (load(e[0]) as PackedScene).instantiate() as Node3D
		main.add_child(m)
		if m.has_method(&"place_crossing"):
			m.call(&"place_crossing", e[1], e[2])
		else:
			m.position = e[1]
	if ResourceLoader.exists(LANE_BRIDGE):
		for c: Vector3 in [Vector3(-9.02, 0, 9.02), Vector3(9.02, 0, -9.02)]:
			var lb: Node3D = (load(LANE_BRIDGE) as PackedScene).instantiate() as Node3D
			main.add_child(lb)
			if lb.has_method(&"place_on_moat"):
				lb.call(&"place_on_moat", c)
			else:
				lb.position = c

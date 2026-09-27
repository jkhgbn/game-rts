extends Node3D
## Task A.5 (polish the Shadow army + Ruin Warden): screenshot rig.
## Windowed run:  Godot_v4.7.2-stable_win64.exe --path . res://art/preview/polish_shadow_army.tscn -- --shots=after
## Saves docs/art/screens/polish_shadow_<tag>_*.png (tag = the --shots value) and quits. Without --shots it is a
## free preview: 1-5 zoom close / 15 / 25 / 40 (group 20) / 55 (army of 100), A attack, D death, M walk toggle,
## C carry, N mine, H hit, L level-up, R revive.

const SCENES: Array[String] = [
	"res://art/units/shadow/gloom_thrall.tscn",
	"res://art/units/shadow/shade.tscn",
	"res://art/units/shadow/nightbolt.tscn",
	"res://art/units/shadow/grave_hound.tscn",
	"res://art/units/shadow/shadow_knight.tscn",
	"res://art/units/neutral/ruin_warden.tscn",
]
## Base move speeds (stride rate 1 = this speed), as gameplay sets stride_speed from the UnitType.
const SPEEDS: Array[float] = [4.6, 4.8, 5.0, 7.0, 4.0, 4.0]
const SHADOW_COLOR := Color(0.42, 0.22, 0.60)
const LINE := Vector3(22, 0, 22)
const GROUP20 := Vector3(60, 0, 0)
const GROUP100 := Vector3(-80, 0, 0)
const STRIP := Vector3(0, 0, 70)
const PORTRAIT := Vector3(0, 0, 110)
const SIL := Vector3(0, 0, -90)
const DT := 1.0 / 60.0

var _cam: Camera3D
var _env: Environment
var _row: Array = []
var _group20: Array = []
var _group100: Array = []
var _strip: Array = []
var _portraits: Array = []
var _walking: bool = false
var _tag: String = ""


func _ready() -> void:
	var we := WorldEnvironment.new()
	_env = (load("res://art/environment/world_env.tres") as Environment).duplicate()
	we.environment = _env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	ground.material_override = load("res://art/environment/ground_material.tres")
	add_child(ground)
	# Lineup: one of each, 2.6 m apart, facing the camera (+Z).
	for i: int in SCENES.size():
		_row.append(_spawn(i, LINE + Vector3((i - 2.5) * 2.6, 0, 0), 0.0))
	# Portrait stands, 9 m apart so neighbours stay out of frame.
	for i: int in SCENES.size():
		_portraits.append(_spawn(i, PORTRAIT + Vector3((i - 2.5) * 9.0, 0, 0), 0.0))
	# Mixed group of 20 facing a diagonal enemy.
	var mix: Array[int] = [0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 1, 2, 3, 0]
	for k: int in mix.size():
		var gx := (k % 5) * 1.7 - 3.4 + (0.4 if (k / 5) % 2 == 1 else 0.0)
		var gz := (k / 5) * 1.8 - 2.7
		_group20.append(_spawn(mix[k], GROUP20 + Vector3(gx, 0, gz), atan2(0.6, 1.0)))
	# A 100-unit army: blocks by role (hounds in front, shades, nightbolts, knights, thralls behind) + 4 wardens.
	var rows: Array = [[3, 14], [1, 24], [2, 24], [4, 10], [0, 12], [5, 4]]
	var zrow := 0.0
	for r: Array in rows:
		var kind: int = r[0]
		var n: int = r[1]
		var per: int = 12
		var sp: float = 2.2 if kind == 4 or kind == 5 else 1.5
		for k: int in n:
			var col := k % per
			var line := k / per
			var x := (col - (mini(n, per) - 1) * 0.5) * sp + (0.5 if line % 2 == 1 else 0.0)
			var jitter := Vector3(sin(k * 12.9898) * 0.25, 0, cos(k * 78.233) * 0.25)
			_group100.append(_spawn(kind, GROUP100 + Vector3(x, 0, zrow - line * sp) + jitter, 0.0))
		zrow -= (ceili(float(n) / per)) * sp + 0.6
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 600.0
	add_child(_cam)
	_game_cam(25.0, LINE)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shots"):
			_tag = a.get_slice("=", 1) if "=" in a else "after"
			_take_shots()


func _spawn(kind: int, p: Vector3, yaw: float) -> Node3D:
	var holder := Node3D.new() # stands in for Unit._visual (facing lives here)
	holder.position = p
	holder.rotation.y = yaw
	add_child(holder)
	var m := (load(SCENES[kind]) as PackedScene).instantiate() as Node3D
	holder.add_child(m)
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", SHADOW_COLOR)
	if "stride_speed" in m:
		m.set(&"stride_speed", SPEEDS[kind])
	m.set_meta(&"speed", SPEEDS[kind])
	m.set_meta(&"kind", kind)
	return m


## Game camera: pitch 55, fov 50, looking at `focus` from `z` metres.
func _game_cam(z: float, focus: Vector3) -> void:
	_orbit(focus, z, 55.0, 0.0)


func _orbit(focus: Vector3, dist: float, pitch_deg: float, yaw_deg: float) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var off := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	_cam.position = focus + off
	_cam.look_at(focus, Vector3.UP)


func _all(list: Array, method: StringName, args: Array = []) -> void:
	for m in list:
		if is_instance_valid(m) and m.has_method(method):
			m.callv(method, args)


func _set_walk(list: Array, on: bool, mul: float = 1.0) -> void:
	for m in list:
		if is_instance_valid(m) and m.has_method(&"set_moving"):
			m.set_moving(float(m.get_meta(&"speed")) * mul if on else 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1: _orbit(LINE + Vector3(0, 1, 0), 9.0, 30.0, 20.0)
		KEY_2: _game_cam(15.0, LINE + Vector3(0, 0, 1))
		KEY_3: _game_cam(25.0, LINE)
		KEY_4: _game_cam(40.0, GROUP20)
		KEY_5: _game_cam(55.0, GROUP100 + Vector3(0, 0, -10))
		KEY_A: _all(_row, &"play_attack"); _all(_group20, &"play_attack")
		KEY_D: _all(_row, &"play_death")
		KEY_H: _all(_row, &"play_hit")
		KEY_L: _all(_row, &"play_level_up")
		KEY_C: _all(_row, &"set_carrying", [true])
		KEY_N: _all(_row, &"play_mine")
		KEY_R: _all(_row, &"revive")
		KEY_M:
			_walking = not _walking
			_set_walk(_row, _walking)
			_set_walk(_group20, _walking)


# ---------------------------------------------------------------- shots

## `--only=a,b` limits the shots to these sections: portraits, lineup, groups, strips, close, worker, silhouette.
func _want(section: String) -> bool:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			return section in a.get_slice("=", 1).split(",")
	return true


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.0)
	if _want("portraits"):
		await _portrait_sheet("portraits", 26.0, 25.0, 1.0)
		await _portrait_sheet("portraits_back", 22.0, 205.0, 1.0)
		await _portrait_sheet("portraits_game", 55.0, 0.0, 1.35)
	if _want("lineup"):
		await _lineup_shots()
	if _want("groups"):
		await _group_shots()
	if _want("strips"):
		await _strip_shot("attack", [0.0, 0.05, 0.10, 0.14, 0.25, 0.45])
		await _strip_shot("walk", [0.0, 0.08, 0.16, 0.24, 0.32, 0.40])
		await _strip_shot("death", [0.1, 0.3, 0.45, 0.6, 0.75, 0.92])
		await _strip_shot("hit", [0.0, 0.03, 0.06, 0.12])
	if _want("close"):
		await _strip_shot("attack", [0.0, 0.05, 0.08, 0.11, 0.14, 0.25, 0.45, 0.7], [4], 4, 3.4, "knight_swing")
		await _strip_shot("walk", [0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35], [3], 4, 2.3, "hound_trot")
		await _strip_shot("run", [0.0, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28], [3], 4, 2.3, "hound_bound")
		await _strip_shot("attack", [0.0, 0.03, 0.06, 0.09, 0.12, 0.2, 0.3, 0.4], [3, 1], 8, 2.3, "hound_shade_attack")
		await _strip_shot("attack", [0.0, 0.04, 0.08, 0.12, 0.16, 0.25, 0.35, 0.5], [2, 5, 0], 8, 2.4, "ranged_warden_worker_attack")
		await _strip_shot("death", [0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.9, 0.97], [1, 5], 8, 2.4, "shade_warden_death")
	if _want("worker"):
		await _worker_shot()
	if _want("silhouette"):
		await _silhouette_shot()
	print("A5 SHOTS DONE ", _tag)
	get_tree().quit()


func _lineup_shots() -> void:
	_orbit(LINE + Vector3(0, 0.9, 0), 11.0, 22.0, 18.0)
	await _wait(0.4)
	await _save("close")
	_game_cam(15.0, LINE + Vector3(0, 0, 1.2))
	await _wait(0.5)
	await _save("z15")
	_game_cam(25.0, LINE + Vector3(0, 0, 0.6))
	await _wait(0.5)
	await _save("z25")
	_game_cam(40.0, LINE)
	await _wait(0.5)
	await _save("z40")


func _group_shots() -> void:
	# Group of 20 walking at 40 m, then fighting at 20 m.
	_set_walk(_group20, true)
	_game_cam(40.0, GROUP20)
	await _wait(1.0)
	await _save("group20_z40")
	_game_cam(20.0, GROUP20 + Vector3(0, 0, 1))
	_set_walk(_group20, false)
	await _wait(0.3)
	_all(_group20, &"play_attack")
	await _wait(0.12)
	await _save("group20_z20_attack")
	# 4. 100 units at 55 m and 40 m (walking) + perf print.
	_set_walk(_group100, true)
	_game_cam(55.0, GROUP100 + Vector3(0, 0, -9))
	await _wait(1.2)
	await _save("group100_z55")
	_game_cam(40.0, GROUP100 + Vector3(0, 0, -6))
	await _wait(0.8)
	await _save("group100_z40")
	var t0 := Time.get_ticks_usec()
	var frames := Engine.get_process_frames()
	await _wait(2.0)
	print("group100 fps ", Engine.get_frames_per_second(), " avg frame ms ",
		(Time.get_ticks_usec() - t0) / 1000.0 / maxf(1.0, Engine.get_process_frames() - frames),
		" process ms ", Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, " draw calls ",
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " objects ",
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_set_walk(_group100, false)


## 3 x 2 sheet of close-ups: each unit alone, camera at `pitch` / `yaw`, distance from its height.
func _portrait_sheet(nm: String, pitch: float, yaw: float, dist_mul: float) -> void:
	var sheet := Image.create(1600, 900, false, Image.FORMAT_RGBA8)
	var heights: Array[float] = [1.5, 1.6, 1.8, 1.1, 2.9, 1.9]
	for i: int in _portraits.size():
		var m: Node3D = _portraits[i]
		var h: float = heights[i]
		_orbit(m.global_position + Vector3(0, h * 0.5, 0), (h * 1.5 + 1.4) * dist_mul, pitch, yaw)
		await _wait(0.15)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		var cw := 852
		var ch := 720
		var crop := img.get_region(Rect2i((img.get_width() - cw) / 2, (img.get_height() - ch) / 2, cw, ch))
		crop.resize(533, 450, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(crop, Rect2i(0, 0, 533, 450), Vector2i((i % 3) * 533, (i / 3) * 450))
	var path := "res://docs/art/screens/polish_shadow_%s_%s.png" % [_tag, nm]
	sheet.save_png(path)
	print("saved ", path)


## Contact sheet: one row per unit type hung in the air (rows stacked in y), one column per time, profile view
## (faces +Z = image left) through an orthographic camera on the +X side. Frames are stepped by hand.
func _strip_shot(what: String, times: Array, kinds: Array = [0, 1, 2, 3, 4, 5], wrap: int = 6,
		spacing: float = 4.6, nm: String = "") -> void:
	_clear_strip()
	await get_tree().process_frame
	var cols: int = times.size()
	var subs: int = ceili(float(cols) / wrap)
	# Rows from the bottom up (the first kind / first frames are the top rows).
	var tall: Array[float] = [2.1, 1.75, 1.95, 1.15, 3.3, 1.95]
	var rows: Array = []   # [kind, sub] from the top
	for kind: int in kinds:
		for s: int in subs:
			rows.append([kind, s])
	var row_y: Dictionary = {}
	var y := 0.0
	for i: int in range(rows.size() - 1, -1, -1):
		row_y[str(rows[i])] = y
		y += tall[rows[i][0]] + 0.75
	var mid := (y - 0.75) * 0.5
	var size := maxf(y + 0.3, (wrap * spacing) * 9.0 / 16.0 + 0.3)
	for kind: int in kinds:
		for c: int in cols:
			var key := str([kind, c / wrap])
			var col := c % wrap
			var p := STRIP + Vector3(0, row_y[key], ((wrap - 1) * 0.5 - col) * spacing)
			var m := _spawn(kind, p, 0.0)
			_strip.append(m)
	await get_tree().process_frame
	for idx: int in _strip.size():
		var m = _strip[idx]
		m.set_process(false)
		var t: float = times[idx % cols]
		var pre: int = 0
		match what:
			"attack": m.play_attack()
			"death": m.play_death()
			"hit": m.play_hit()
			"walk", "run":
				m.set_moving(float(m.get_meta(&"speed")) * (1.45 if what == "run" else 1.0))
				pre = 12
		m.set_process(false)
		for s: int in int(round(t / DT)) + pre:
			m._t += DT
			m._animate(DT)
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = size
	_orbit(STRIP + Vector3(0, mid, 0), 40.0, 6.0, 90.0)
	await _wait(0.2)
	await _save("strip_" + (nm if nm != "" else what))
	_cam.projection = Camera3D.PROJECTION_PERSPECTIVE


func _clear_strip() -> void:
	for m in _strip:
		if is_instance_valid(m):
			(m as Node3D).get_parent().queue_free()
	_strip.clear()


func _worker_shot() -> void:
	_clear_strip()
	await get_tree().process_frame
	var th := _spawn(0, STRIP + Vector3(-2.2, 0, 0), 0.3)
	th.call(&"set_carrying", true)
	var th2 := _spawn(0, STRIP + Vector3(0.3, 0, 0), 0.0)
	th2.call(&"play_mine")
	var th3 := _spawn(0, STRIP + Vector3(2.8, 0, 0), -0.5)
	th3.call(&"set_carrying", true)
	th3.call(&"set_moving", 4.6)
	_strip.append_array([th, th2, th3])
	_orbit(STRIP + Vector3(0.3, 0.8, 0), 7.5, 30.0, 20.0)
	await _wait(2.8)
	await _save("thrall_states")


func _silhouette_shot() -> void:
	var white := StandardMaterial3D.new()
	white.albedo_color = Color.BLACK
	white.emission_enabled = true
	white.emission = Color.WHITE
	white.emission_energy_multiplier = 8.0
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(240, 240)
	plane.mesh = pm
	plane.material_override = white
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plane.position = SIL + Vector3(0, 0.01, 0)
	add_child(plane)
	_env.glow_enabled = false
	var sil: Array = []
	for i: int in SCENES.size():
		sil.append(_spawn(i, SIL + Vector3((i - 2.5) * 2.8, 0, 0), 0.0))
		sil.append(_spawn(i, SIL + Vector3((i - 2.5) * 2.8, 0, 3.4), PI * 0.5))
	await get_tree().process_frame
	await get_tree().process_frame
	for m in sil:
		for n: Node in (m as Node).find_children("*", "", true, false):
			if n is GPUParticles3D or n.name == &"Shadow":
				(n as Node3D).visible = false
			elif n is GeometryInstance3D:
				(n as GeometryInstance3D).material_override = black
				(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_game_cam(17.0, SIL + Vector3(0, 0, 1.8))
	await _wait(0.3)
	await _save("silhouette")
	_game_cam(40.0, SIL + Vector3(0, 0, 1.8))
	await _wait(0.3)
	await _save("silhouette_z40")
	_env.glow_enabled = true


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _save(nm: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "res://docs/art/screens/polish_shadow_%s_%s.png" % [_tag, nm]
	img.save_png(path)
	print("saved ", path)

extends Node3D
## Task A2.7 screenshot rig (Ruin Warden, Ruin Peddler, Lost Cache). Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/environment/neutral/neutral_preview.tscn -- --shots=after
## Saves docs/art/screens/neutral_<tag>_*.png and quits (`--only=warden,peddler,cache,context,silhouette`).
## Without --shots: free preview, keys 1-5 cameras, A attack, D death, H hit, M walk, R revive, O open / close caches.

const WARDEN := "res://art/units/neutral/ruin_warden.tscn"
const PEDDLER := "res://art/environment/ruin_peddler.tscn"
const CACHE := "res://art/environment/lost_cache.tscn"
const DT := 1.0 / 60.0
const W_AREA := Vector3(0, 0, 0)
const P_AREA := Vector3(40, 0, 0)
const C_AREA := Vector3(80, 0, 0)
const CTX := Vector3(0, 0, 60)
const STRIP := Vector3(-60, 0, 0)
const SIL := Vector3(0, 0, -60)

var _cam: Camera3D
var _env: Environment
var _tag := "after"
var _wardens: Array = []
var _strip: Array = []
var _caches: Array = []
var _walking := false
var _peddler_art: Node3D


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
	# Warden area: a lineup of 3 (front, 3/4, side) + a camp of 4 behind.
	for i: int in 3:
		_wardens.append(_warden(W_AREA + Vector3((i - 1) * 3.2, 0, 0), [0.0, 0.7, PI * 0.5][i]))
	_ref_units(W_AREA + Vector3(-4.6, 0, 1.2))
	for i: int in 4:
		var a := i * TAU / 4.0 + 0.4
		_wardens.append(_warden(W_AREA + Vector3(cos(a) * 3.0, 0, -9 + sin(a) * 3.0), -a + PI * 0.5))
	# Peddler area: front view and back view (the (-22,-22) peddler shows its back to the camera) + scale refs.
	_peddler_art = _scene(PEDDLER, P_AREA, 0.0)
	_scene(PEDDLER, P_AREA + Vector3(9, 0, 0), PI)
	_ref_units(P_AREA + Vector3(-2.6, 0, 2.0))
	# Cache area: closed / opened art, and two real LostCache nodes (ring, open sequence).
	_caches.append(_scene(CACHE, C_AREA + Vector3(-1.6, 0, 0), 0.0))
	var c2: Node3D = _scene(CACHE, C_AREA + Vector3(1.6, 0, 0), 0.0)
	c2.call(&"set_opened", true)
	_caches.append(c2)
	# Context: a crown-hollow corner with a camp, the peddler, a cache and a few props.
	_scene(PEDDLER, CTX + Vector3(-6, 0, -2), 0.25)
	var lc_script: Script = load("res://scripts/world/lost_cache.gd")
	for k: int in 2:
		var lc: Node3D = lc_script.new()
		lc.set(&"first_delay", 0.05)
		lc.position = CTX + Vector3(5.5 + k * 30.0, 0, 3)
		add_child(lc)
		_caches.append(lc)
	for i: int in 3:
		_wardens.append(_warden(CTX + Vector3(3 + i * 1.8, 0, -4 - (i % 2) * 1.2), 0.3 - i * 0.3))
	for p: Array in [["ruin_pillar", Vector3(1, 0, -7)], ["ruin_pillar", Vector3(8, 0, -6)], ["tree_broadleaf", Vector3(-11, 0, -6)],
			["tree_pine", Vector3(12, 0, -3)], ["rock_boulder", Vector3(-9, 0, 4)], ["tree_birch", Vector3(-2, 0, -9)]]:
		_scene("res://art/environment/%s.tscn" % p[0], CTX + p[1], 0.7)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 600.0
	add_child(_cam)
	_game_cam(25.0, W_AREA)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shots"):
			_tag = a.get_slice("=", 1) if "=" in a else "after"
			_take_shots.call_deferred()


func _warden(p: Vector3, yaw: float) -> Node3D:
	var holder := Node3D.new()
	holder.position = p
	holder.rotation.y = yaw
	add_child(holder)
	var m := (load(WARDEN) as PackedScene).instantiate() as Node3D
	holder.add_child(m)
	return m


func _scene(path: String, p: Vector3, yaw: float) -> Node3D:
	var n := (load(path) as PackedScene).instantiate() as Node3D
	n.position = p
	n.rotation.y = yaw
	add_child(n)
	return n


func _ref_units(p: Vector3) -> void:
	# Scale references: Vessa, a Flame Guard, a Shade.
	var list: Array = [["res://art/units/wizards/vessa.tscn", Vector3(0, 0, 0)], ["res://art/units/fire/flame_guard.tscn", Vector3(-1.2, 0, 0.6)],
		["res://art/units/shadow/shade.tscn", Vector3(-2.2, 0, -0.4)], ["res://art/units/shadow/shadow_knight.tscn", Vector3(-3.6, 0, 0.3)]]
	for u: Array in list:
		if ResourceLoader.exists(u[0]):
			var h := Node3D.new()
			h.position = p + u[1]
			h.rotation.y = 0.6
			add_child(h)
			h.add_child((load(u[0]) as PackedScene).instantiate())


func _game_cam(z: float, focus: Vector3) -> void:
	_orbit(focus, z, 55.0, 0.0)


func _orbit(focus: Vector3, dist: float, pitch_deg: float, yaw_deg: float) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	_cam.position = focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	_cam.look_at(focus, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1: _orbit(W_AREA + Vector3(0, 1, 0), 8.0, 20.0, 20.0)
		KEY_2: _game_cam(15.0, W_AREA)
		KEY_3: _game_cam(25.0, P_AREA + Vector3(0.4, 0, 0))
		KEY_4: _game_cam(40.0, CTX)
		KEY_5: _game_cam(25.0, C_AREA)
		KEY_A: for w in _wardens: w.play_attack()
		KEY_D: for w in _wardens: w.play_death()
		KEY_H: for w in _wardens: w.play_hit()
		KEY_R: for w in _wardens: w.revive()
		KEY_M:
			_walking = not _walking
			for w in _wardens: w.set_moving(4.0 if _walking else 0.0)
		KEY_O:
			for c in _caches:
				if c.has_method(&"set_open"):
					c.call(&"set_open", not bool(c.call(&"is_open")))


# ---------------------------------------------------------------- shots

func _want(section: String) -> bool:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			return section in a.get_slice("=", 1).split(",")
	return true


func _take_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.2)
	if _want("warden"):
		_orbit(W_AREA + Vector3(0, 1.0, 0), 8.5, 18.0, 16.0)
		await _wait(0.3)
		await _save("warden_close")
		_orbit(W_AREA + Vector3(-3.2, 1.0, 0), 4.2, 12.0, 28.0)
		await _wait(0.3)
		await _save("warden_portrait")
		_orbit(W_AREA + Vector3(-3.2, 1.0, 0), 4.2, 14.0, 200.0)
		await _wait(0.3)
		await _save("warden_back")
		_game_cam(15.0, W_AREA + Vector3(0, 0, -3))
		await _wait(0.3)
		await _save("warden_z15")
		_game_cam(40.0, W_AREA + Vector3(0, 0, -4))
		await _wait(0.3)
		await _save("warden_z40")
		for w in _wardens.slice(3, 7):
			w.play_attack()
		_game_cam(18.0, W_AREA + Vector3(0, 0, -9))
		await _wait(0.16)
		await _save("warden_camp_slam")
		await _strip_shot("attack", [0.0, 0.04, 0.07, 0.10, 0.12, 0.18, 0.3, 0.5], "attack")
		await _strip_shot("walk", [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7], "walk")
		await _strip_shot("death", [0.05, 0.15, 0.25, 0.35, 0.5, 0.65, 0.8, 0.95], "death")
		await _strip_shot("hit", [0.0, 0.04, 0.08, 0.12], "hit")
	if _want("peddler"):
		_orbit(P_AREA + Vector3(0.3, 1.1, 0), 7.5, 22.0, 18.0)
		await _wait(0.3)
		await _save("peddler_close")
		_orbit(P_AREA + Vector3(-1.1, 1.2, 0.7), 3.4, 10.0, 12.0)
		await _wait(0.3)
		await _save("peddler_merchant")
		var art: Node = _peddler_art
		art.set(&"_wave_t", 0.0)
		await _wait(0.45)
		await _save("peddler_merchant_wave")
		_game_cam(15.0, P_AREA + Vector3(0.3, 0, 0.3))
		await _wait(0.3)
		await _save("peddler_z15")
		_game_cam(25.0, P_AREA + Vector3(4.5, 0, 0))
		await _wait(0.3)
		await _save("peddler_z25_front_back")
		_game_cam(40.0, P_AREA + Vector3(4.5, 0, 0))
		await _wait(0.3)
		await _save("peddler_z40")
	if _want("cache"):
		_orbit(C_AREA + Vector3(0, 0.4, 0), 5.2, 24.0, 14.0)
		await _wait(0.3)
		await _save("cache_close")
		_game_cam(15.0, C_AREA)
		await _wait(0.3)
		await _save("cache_z15")
		# the reappear pop (set_open(false)) mid-way
		_caches[0].call(&"set_open", false)
		await _wait(0.12)
		_orbit(C_AREA + Vector3(0, 0.4, 0), 5.2, 24.0, 14.0)
		await _save("cache_appear")
		await _cache_strip()
	if _want("context"):
		_game_cam(40.0, CTX + Vector3(0, 0, -1))
		await _wait(0.5)
		await _save("context_z40")
		_game_cam(25.0, CTX + Vector3(0, 0, -1))
		await _wait(0.3)
		await _save("context_z25")
		var lc: Node3D = _caches[2]
		lc.call(&"_play_open")
		await _wait(0.28)
		_game_cam(14.0, lc.global_position)
		await _save("context_cache_opening")
	if _want("silhouette"):
		await _silhouette()
	print("A2.7 SHOTS DONE ", _tag)
	get_tree().quit()


## Side-view contact sheet of the warden (profile: faces +Z = image left), frames stepped by hand.
func _strip_shot(what: String, times: Array, nm: String) -> void:
	for m in _strip:
		if is_instance_valid(m):
			(m as Node3D).get_parent().queue_free()
	_strip.clear()
	await get_tree().process_frame
	var spacing := 2.7
	var per := 4
	var rows := ceili(float(times.size()) / per)
	for c: int in times.size():
		var row := c / per
		var col := c % per
		var m := _warden(STRIP + Vector3(0, (rows - 1 - row) * 2.8, ((per - 1) * 0.5 - col) * spacing), 0.0)
		_strip.append(m)
	await get_tree().process_frame
	for idx: int in _strip.size():
		var m = _strip[idx]
		m.set_process(false)
		var t: float = times[idx]
		var pre := 0
		match what:
			"attack": m.play_attack()
			"death": m.play_death()
			"hit": m.play_hit()
			"walk":
				m.set_moving(4.0)
				pre = 12
		for s: int in int(round(t / DT)) + pre:
			m._t += DT
			m._animate(DT)
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = maxf(per * spacing * 9.0 / 16.0, rows * 2.8) + 0.3
	_orbit(STRIP + Vector3(0, (rows - 1) * 1.4 + 1.1, 0), 40.0, 4.0, 90.0)
	await _wait(0.25)
	await _save("warden_strip_" + nm)
	_cam.projection = Camera3D.PROJECTION_PERSPECTIVE


## Lost Cache opening, stepped by hand (lid / chest / treasure; particles run in real time).
func _cache_strip() -> void:
	var times: Array = [0.0, 0.06, 0.12, 0.18, 0.26, 0.40]
	var list: Array = []
	for i: int in times.size():
		var c := _scene(CACHE, STRIP + Vector3(0, 0, 40 + (i - 2.5) * 2.2), 0.0)
		list.append(c)
	await get_tree().process_frame
	for i: int in list.size():
		var c = list[i]
		c.set_process(false)
		c.call(&"set_open", true)
		for s: int in int(round(float(times[i]) / DT)):
			c._process(DT)
	_orbit(STRIP + Vector3(0, 0.5, 40), 16.0, 28.0, 90.0)
	await _wait(0.25)
	await _save("cache_strip_open")
	for c in list:
		c.queue_free()


func _silhouette() -> void:
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
	pm.size = Vector2(80, 80)
	plane.mesh = pm
	plane.material_override = white
	plane.position = SIL + Vector3(0, 0.01, 0)
	add_child(plane)
	_env.glow_enabled = false
	var nodes: Array = []
	nodes.append(_warden(SIL + Vector3(-4, 0, 0), 0.0))
	nodes.append(_warden(SIL + Vector3(-2, 0, 0), PI * 0.5))
	nodes.append(_scene(PEDDLER, SIL + Vector3(1.5, 0, 0), 0.0))
	nodes.append(_scene(CACHE, SIL + Vector3(5.5, 0, 0.5), 0.0))
	await get_tree().process_frame
	await get_tree().process_frame
	for m in nodes:
		for n: Node in (m as Node).find_children("*", "", true, false):
			if n is GPUParticles3D or n.name == &"Shadow" or n.name == &"ContactShadow":
				(n as Node3D).visible = false
			elif n is GeometryInstance3D:
				(n as GeometryInstance3D).material_override = black
				(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_game_cam(22.0, SIL + Vector3(0.5, 0, 0))
	await _wait(0.3)
	await _save("silhouette")
	_env.glow_enabled = true


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _save(nm: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "res://docs/art/screens/neutral_%s_%s.png" % [_tag, nm]
	img.save_png(path)
	print("saved ", path)

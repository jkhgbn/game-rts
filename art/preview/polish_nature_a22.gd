extends Node3D
## Nature army polish pass 2 preview (task A2.2): Thornling, Burr Slinger, Bramblehorn from the RTS camera
## (pitch 55, fov 50) on the painted ground, next to a Shadow Knight and a Rime Colossus for scale; a mixed group of
## 20 and of 100, a black silhouette test. Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/preview/polish_nature_a22.tscn -- --shots --tag=after
## saves docs/art/screens/polish_nature2_<tag>_*.png and quits. `-- --check` (headless ok): budgets + every hook.
## By hand: 1 attack, 2 hit, 3 death, 4 level-up + vet 4, 7 walk toggle, 8 fidget, 9 revive, G group 20,
## H group 100, wheel zoom.

const SCENES: Array[String] = [
	"res://art/units/nature/thornling.tscn",
	"res://art/units/nature/burr_slinger.tscn",
	"res://art/units/nature/bramblehorn.tscn",
	"res://art/units/shadow/shadow_knight.tscn",
	"res://art/units/ice/rime_colossus.tscn",
]
const NAMES: Array[String] = ["thornling", "slinger", "bramblehorn", "ref_knight", "ref_colossus"]
const SPEEDS: Array[float] = [5.4, 5.0, 4.6, 4.2, 3.4]
const XS: Array[float] = [-4.4, -2.2, 0.6, 4.0, 7.0]
const NATURE_COLOR := Color(0.35, 0.70, 0.25)
const G20_CENTER := Vector3(0, 0, -40)
const G100_CENTER := Vector3(0, 0, -90)
# Bot mix (kingdom-nature.md 6, default): thornling 45 %, slinger 25 %, bramblehorn 15 % (bloomtenders left out).
const MIX20: Array[int] = [0, 0, 1, 0, 2, 0, 1, 0, 2, 1, 0, 0, 1, 2, 0, 1, 0, 0, 1, 2]
const MAIN: int = 3   # the first 3 of the row are the units of this task

var zoom: float = 15.0
var focus: Vector3 = Vector3(0, 0.9, 0)
var tag: String = "after"
var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array[Node3D] = []
var _g20: Array[Node3D] = []
var _g100: Array[Node3D] = []
var _walking: bool = false


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	_env = WorldEnvironment.new()
	_env.environment = (load("res://art/environment/world_env.tres") as Environment).duplicate()
	add_child(_env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	_ground.mesh = pm
	var spots: Array[Vector4] = [Vector4(0, -40, 9, 0), Vector4(16, 6, 4, 1)]
	var gm: Material = EnvProps.ground_material(Vector3(-60, 0, -8), Vector3(60, 0, -60), spots)
	if gm == null:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.30, 0.34, 0.22)
		gm = sm
	_ground.material_override = gm
	add_child(_ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 600.0
	add_child(_cam)
	for i: int in SCENES.size():
		_row.append(_spawn(i, Vector3(XS[i], 0, 0), 0.0))
	_apply()
	var args := OS.get_cmdline_user_args()
	if "--shots" in args:
		_shots()
	elif "--check" in args:
		_check()


## Budget report (draw instances after the merge, particle systems, vertices, lights) + every hook, death_finished.
func _check() -> void:
	await _wait(0.2)
	var main: Array[Node3D] = _row.slice(0, MAIN)
	for u: Node3D in main:
		var acc: Array[int] = [0, 0, 0, 0]
		_count(u, acc)
		print("CHECK %s: draw instances %d (+%d particle systems), vertices %d, lights %d" % [u.name, acc[0], acc[2],
			acc[1], acc[3]])
		if "--verbose" in OS.get_cmdline_user_args():
			for mi: Node in u.find_children("*", "MeshInstance3D", true, false):
				var mesh := (mi as MeshInstance3D).mesh
				var v: int = 0
				for s: int in mesh.get_surface_count():
					v += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				print("    %s: %d verts, %d surfaces" % [u.get_path_to(mi), v, mesh.get_surface_count()])
	_all(main, &"play_attack")
	await _wait(1.1)
	_all(main, &"play_hit")
	_all(main, &"set_veterancy", [4])
	_all(main, &"play_level_up")
	_all(main, &"set_status", [&"haste", true])
	_all(main, &"set_team_color", [Color(0.85, 0.30, 0.12)])
	_walk(main, true)
	await _wait(0.8)
	_walk(main, false)
	_all(main, &"play_fidget")
	await _wait(0.5)
	var done: Array[int] = [0]
	for u: Node3D in main:
		u.connect(&"death_finished", func() -> void: done[0] += 1)
	_all(main, &"play_death")
	await _wait(1.3)
	_all(main, &"revive")
	await _wait(0.3)
	var visible_roots: int = 0
	for u: Node3D in main:
		if (u.get_node(^"Root") as Node3D).visible:
			visible_roots += 1
	print("CHECK death_finished %d / %d, visible after revive %d" % [done[0], main.size(), visible_roots])
	get_tree().quit()


func _count(n: Node, acc: Array[int]) -> void:
	for c: Node in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			acc[0] += 1
			var mesh := (c as MeshInstance3D).mesh
			for s: int in mesh.get_surface_count():
				acc[1] += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		elif c is MultiMeshInstance3D:
			acc[0] += 1
		elif c is GPUParticles3D:
			acc[2] += 1
		elif c is Light3D:
			acc[3] += 1
		_count(c, acc)


func _spawn(kind: int, at: Vector3, yaw: float) -> Node3D:
	var holder := Node3D.new()   # stands in for Unit._visual (facing lives here)
	holder.position = at
	holder.rotation.y = yaw
	add_child(holder)
	var m := (load(SCENES[kind]) as PackedScene).instantiate() as Node3D
	m.set_meta(&"speed", SPEEDS[kind])
	holder.add_child(m)
	if kind < MAIN and m.has_method(&"set_team_color"):
		m.call(&"set_team_color", NATURE_COLOR)
	return m


func _make_group(center: Vector3, n: int, spacing: float, yaw: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var cols: int = int(ceil(sqrt(float(n))))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11 + n
	for k: int in n:
		var kind: int = MIX20[k % MIX20.size()] if n <= MIX20.size() else MIX20[rng.randi() % MIX20.size()]
		var gx: float = (float(k % cols) - float(cols - 1) * 0.5) * spacing + rng.randf_range(-0.25, 0.25)
		var gz: float = (float(k / cols) - float(cols - 1) * 0.5) * spacing + rng.randf_range(-0.25, 0.25)
		if kind == 2:
			gx *= 1.08
		out.append(_spawn(kind, center + Vector3(gx, 0, gz), yaw + rng.randf_range(-0.15, 0.15)))
	return out


func _apply() -> void:
	var p: float = deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _main() -> Array[Node3D]:
	return _row.slice(0, MAIN)


func _all(list: Array[Node3D], method: StringName, args: Array = []) -> void:
	for u: Node3D in list:
		if is_instance_valid(u) and u.has_method(method):
			u.callv(method, args)


func _walk(list: Array[Node3D], on: bool) -> void:
	for u: Node3D in list:
		if is_instance_valid(u) and u.has_method(&"set_moving"):
			u.call(&"set_moving", float(u.get_meta(&"speed")) if on else 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 3.0, 4.0, 60.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 3.0, 4.0, 60.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_1: _all(_row, &"play_attack")
			KEY_2: _all(_row, &"play_hit")
			KEY_3: _all(_row, &"play_death")
			KEY_4:
				_all(_row, &"play_level_up")
				_all(_row, &"set_veterancy", [4])
			KEY_7:
				_walking = not _walking
				_walk(_row, _walking)
			KEY_8: _all(_row, &"play_fidget")
			KEY_9: _all(_row, &"revive")
			KEY_G:
				if _g20.is_empty():
					_g20 = _make_group(G20_CENTER, 20, 1.9, 0.5)
				_view(22.0, G20_CENTER)
			KEY_H:
				if _g100.is_empty():
					_g100 = _make_group(G100_CENTER, 100, 1.8, 0.5)
				_view(50.0, G100_CENTER)


func _save(nm: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/polish_nature2_%s_%s.png" % [tag, nm]
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


## Centre crop enlarged k times with nearest filtering (what the pixels at that zoom really show).
func _save_crop(nm: String, k: int) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var w: int = img.get_width() / k
	var h: int = img.get_height() / k
	var crop := img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))
	crop.resize(w * k, h * k, Image.INTERPOLATE_NEAREST)
	crop.save_png(ProjectSettings.globalize_path("res://docs/art/screens/polish_nature2_%s_%s.png" % [tag, nm]))


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _view(z: float, f: Vector3) -> void:
	zoom = z
	focus = f
	_apply()


func _side(f: Vector3, dist: float) -> void:
	_cam.position = f + Vector3(dist, 0.3, 0.0)
	_cam.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)


func _front(f: Vector3, dist: float, back: bool = false) -> void:
	# 3/4 view slightly from above (closer to the in-game portrait than the RTS camera).
	var dir := Vector3(0.45, 0.45, 1.0 if not back else -1.0).normalized()
	_cam.position = f + dir * dist
	_cam.look_at(f, Vector3.UP)


func _face_all(yaw: float) -> void:
	for u: Node3D in _row:
		u.get_parent().rotation.y = yaw


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.2)
	var mid := Vector3(1.3, 0.9, 0)
	# 1. Row idle at the RTS zooms.
	_view(15.0, mid)
	await _wait(0.3)
	await _save("row_z15")
	_view(28.0, mid)
	await _wait(0.2)
	await _save("row_z28")
	_view(40.0, mid)
	await _wait(0.2)
	await _save("row_z40")
	await _save_crop("row_z40_crop3x", 3)
	# 2. Close-ups (3/4 front, then 3/4 back) per unit.
	for i: int in MAIN:
		var h: float = 0.8 if i != 2 else 1.2
		var d: float = 3.0 if i != 2 else 5.2
		_front(_row[i].global_position + Vector3(0, h, 0), d)
		await _wait(0.25)
		await _save("close_%s" % NAMES[i])
		_front(_row[i].global_position + Vector3(0, h, 0), d, true)
		await _wait(0.2)
		await _save("back_%s" % NAMES[i])
	# 3. Side view of the row (weapon / horn silhouettes).
	_face_all(PI * 0.5)
	_view(14.0, mid)
	await _wait(0.3)
	await _save("side_z14")
	if "--quick" in OS.get_cmdline_user_args():
		_cam.position = _row[2].global_position + Vector3(0, 1.5, 6.5)
		_cam.look_at(_row[2].global_position + Vector3(0, 1.1, 0), Vector3.UP)
		await _wait(0.1)
		await _save("side_close")
		_face_all(0.0)
		for i: int in MAIN:
			var hp: Vector3 = _row[i].global_position + (Vector3(0, 1.25, 1.2) if i == 2 else Vector3(0, 1.15, 0.3))
			_cam.position = hp + Vector3(0.0, 0.35, 2.4 if i == 2 else 1.3)
			_cam.look_at(hp, Vector3.UP)
			await _wait(0.1)
			await _save("face_%s" % NAMES[i])
		_view(40.0, mid)
		await _wait(0.3)
		await _save_crop("row_z40_crop3x", 3)
		get_tree().quit()
		return
	# 3b. Side attack: wind-up and strike.
	_all(_main(), &"play_attack")
	await _wait(0.07)
	await _save("attack_side_windup")
	await _wait(0.06)
	await _save("attack_side_strike")
	await _wait(0.2)
	await _save("attack_side_follow")
	await _wait(1.0)
	# 3c. Side walk mid-stride.
	_walk(_main(), true)
	await _wait(0.8)
	await _save("walk_side")
	_walk(_main(), false)
	await _wait(0.5)
	_face_all(0.0)
	# 4. Walk mid-stride from the game camera.
	_walk(_main(), true)
	_view(15.0, mid)
	await _wait(0.9)
	await _save("walk_z15")
	_walk(_main(), false)
	await _wait(0.6)
	# 5. Fidgets.
	_view(10.0, Vector3(-1.5, 0.9, 0))
	_all(_main(), &"play_fidget")
	await _wait(0.6)
	await _save("fidget_z10")
	await _wait(1.6)
	# 6. Attack from the game camera + hit.
	_view(12.0, Vector3(-1.5, 0.9, 0))
	_all(_main(), &"play_attack")
	await _wait(0.13)
	await _save("attack_z12")
	await _wait(1.2)
	_all(_main(), &"play_hit")
	await _wait(0.05)
	await _save("hit_z12")
	await _wait(0.8)
	# 7. Veterancy 4 + level-up flash.
	_all(_main(), &"set_veterancy", [4])
	_all(_main(), &"play_level_up")
	await _wait(0.1)
	await _save("vet4_levelup_z12")
	await _wait(0.6)
	_all(_main(), &"set_veterancy", [1])
	# 8. Death at 0.3 / 0.6 / 0.9 s.
	_all(_main(), &"play_death")
	await _wait(0.3)
	await _save("death_a_z12")
	await _wait(0.3)
	await _save("death_b_z12")
	await _wait(0.3)
	await _save("death_c_z12")
	await _wait(0.6)
	_all(_main(), &"revive")
	await _wait(0.3)
	# 8b. Mirror-match team colour (a violet Nature enemy): only the *_cloth / *_cape parts change.
	_all(_main(), &"set_team_color", [Color(0.42, 0.22, 0.60)])
	_view(12.0, Vector3(-1.5, 0.9, 0))
	await _wait(0.2)
	await _save("team_recolor_z12")
	# 9. Group of 20 (zoom 22 and 40), walking.
	_g20 = _make_group(G20_CENTER, 20, 1.9, 0.5)
	await _wait(0.5)
	_view(22.0, G20_CENTER)
	await _wait(0.4)
	await _save("group20_z22")
	_walk(_g20, true)
	_view(40.0, G20_CENTER)
	await _wait(0.8)
	await _save("group20_z40")
	await _save_crop("group20_z40_crop3x", 3)
	_all(_g20, &"play_attack")
	_view(22.0, G20_CENTER)
	await _wait(0.12)
	await _save("group20_attack_z22")
	_walk(_g20, false)
	# 10. Group of 100 (zoom 50), walking: fps + process time.
	_g100 = _make_group(G100_CENTER, 100, 1.8, 0.5)
	await _wait(0.5)
	_view(50.0, G100_CENTER)
	_walk(_g100, true)
	await _wait(1.5)
	await _save("group100_z50")
	await _measure("walk100 z50")
	_view(30.0, G100_CENTER + Vector3(0, 0, 4))
	await _wait(1.0)
	await _save("group100_z30")
	await _measure("walk100 z30")
	_walk(_g100, false)
	# 11. Silhouette test (black on white) of the row at 40 m and 20 m.
	_silhouette()
	_view(40.0, mid)
	await _wait(0.4)
	await _save("silhouette_z40")
	await _save_crop("silhouette_z40_crop3x", 3)
	_view(20.0, mid)
	await _wait(0.2)
	await _save("silhouette_z20")
	get_tree().quit()


func _measure(label: String) -> void:
	var frames: int = 0
	var t0: int = Time.get_ticks_usec()
	var proc: float = 0.0
	while frames < 90:
		await get_tree().process_frame
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		frames += 1
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0 / float(frames)
	print("MEASURE %s: frame %.2f ms (%.0f fps), process %.2f ms, draw calls %d, objects %d" % [label, ms,
		1000.0 / ms, proc / float(frames), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])


func _silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	_ground.material_override = white
	_env.environment.glow_enabled = false
	_env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	for u: Node3D in _row:
		_paint(u, black)


func _paint(n: Node, mat: Material) -> void:
	for c: Node in n.get_children():
		if c is GPUParticles3D:
			(c as GPUParticles3D).visible = false
		elif c is GeometryInstance3D:
			if c.name == "Shadow":
				(c as GeometryInstance3D).visible = false
			else:
				(c as GeometryInstance3D).material_override = mat
				(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_paint(c, mat)

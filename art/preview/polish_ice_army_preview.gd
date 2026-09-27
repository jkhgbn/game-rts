extends Node3D
## Ice army polish preview (task A.6): the 5 Ice units from the RTS camera (pitch 55, fov 50) on the real painted
## ground, a 20-unit and a 100-unit group, a black silhouette test. Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/preview/polish_ice_army_preview.tscn -- --shots --tag=after
## saves docs/art/screens/polish_ice_<tag>_*.png and quits. `-- --perf` only prints the 100-unit timings.
## By hand: 1 attack, 2 hit, 3 death, 4 level-up + vet 4, 5 carry, 6 mine, 7 walk toggle, 8 seer support cast,
## 9 revive, G group 20, H group 100, wheel zoom.

const SCENES: Array[String] = [
	"res://art/units/ice/rime_hauler.tscn",
	"res://art/units/ice/rimeshield.tscn",
	"res://art/units/ice/shardcaster.tscn",
	"res://art/units/ice/rime_seer.tscn",
	"res://art/units/ice/rime_colossus.tscn",
]
const NAMES: Array[String] = ["hauler", "rimeshield", "shardcaster", "seer", "colossus"]
const SPEEDS: Array[float] = [4.6, 4.2, 4.4, 4.2, 3.4]
const RADII: Array[float] = [0.4, 0.5, 0.45, 0.45, 0.8]
const ICE_COLOR := Color(0.45, 0.75, 0.95)
const G20_CENTER := Vector3(0, 0, -40)
const G100_CENTER := Vector3(0, 0, -90)
# Bot mix (kingdom-ice.md 7): shield 40 %, caster 30 %, seer 10 %, colossus 20 % (+ a few haulers in the 20).
const MIX20: Array[int] = [1, 1, 2, 1, 4, 2, 1, 3, 2, 1, 4, 2, 1, 2, 3, 1, 0, 2, 1, 0]

var zoom: float = 15.0
var focus: Vector3 = Vector3(0, 0.9, 0)
var tag: String = "after"
var _cam: Camera3D
var _sun: DirectionalLight3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _row: Array[Node3D] = []
var _g20: Array[Node3D] = []
var _g100: Array[Node3D] = []
var _walking: bool = false
var _carry: bool = false


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	_env = WorldEnvironment.new()
	_env.environment = (load("res://art/environment/world_env.tres") as Environment).duplicate()
	add_child(_env)
	_sun = DirectionalLight3D.new()
	_sun.light_color = Color(1.00, 0.93, 0.82)
	_sun.light_energy = 1.3
	_sun.rotation_degrees = Vector3(-50, 35, 0)
	_sun.shadow_enabled = true
	_sun.shadow_normal_bias = 2.0
	_sun.directional_shadow_max_distance = 120.0
	add_child(_sun)
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
		var u := _spawn(i, Vector3((float(i) - 2.0) * 2.7, 0, 0), 0.0)
		if u:
			_row.append(u)
	_apply()
	var args := OS.get_cmdline_user_args()
	if "--shots" in args:
		_shots()
	elif "--perf" in args:
		_perf_only()
	elif "--check" in args:
		_check()


## Headless: budget report (draw instances after the merge, particles, vertices) + every hook, death_finished.
func _check() -> void:
	for u: Node3D in _row:
		var acc: Array[int] = [0, 0, 0]
		_count(u, acc)
		print("CHECK %s: draw instances %d (+%d particle systems), vertices %d" % [u.name, acc[0], acc[2], acc[1]])
	await _wait(0.3)
	_all(_row, &"play_attack")
	await _wait(1.1)
	_row[3].call(&"play_cast", &"support")
	_all(_row, &"play_hit")
	_all(_row, &"set_veterancy", [4])
	_all(_row, &"play_level_up")
	_all(_row, &"set_carrying", [true])
	_row[0].call(&"play_mine")
	_all(_row, &"set_status", [&"haste", true])
	_walk(_row, true)
	await _wait(0.8)
	_walk(_row, false)
	_all(_row, &"play_fidget")
	await _wait(0.5)
	var done: Array[int] = [0]
	for u: Node3D in _row:
		u.connect(&"death_finished", func() -> void: done[0] += 1)
	_all(_row, &"play_death")
	await _wait(1.3)
	_all(_row, &"revive")
	await _wait(0.3)
	var visible_roots: int = 0
	for u: Node3D in _row:
		if (u.get_node(^"Root") as Node3D).visible:
			visible_roots += 1
	print("CHECK death_finished %d / %d, visible after revive %d" % [done[0], _row.size(), visible_roots])
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
		_count(c, acc)


func _spawn(kind: int, at: Vector3, yaw: float) -> Node3D:
	var holder := Node3D.new()   # stands in for Unit._visual (facing lives here)
	holder.position = at
	holder.rotation.y = yaw
	add_child(holder)
	var m := (load(SCENES[kind]) as PackedScene).instantiate() as Node3D
	m.set_meta(&"speed", SPEEDS[kind])
	m.set_meta(&"kind", kind)
	holder.add_child(m)
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", ICE_COLOR)
	return m


func _make_group(center: Vector3, n: int, spacing: float, yaw: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var cols: int = int(ceil(sqrt(float(n))))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + n
	for k: int in n:
		var kind: int = MIX20[k % MIX20.size()] if n <= MIX20.size() else MIX20[rng.randi() % MIX20.size()]
		var gx: float = (float(k % cols) - float(cols - 1) * 0.5) * spacing + rng.randf_range(-0.25, 0.25)
		var gz: float = (float(k / cols) - float(cols - 1) * 0.5) * spacing + rng.randf_range(-0.25, 0.25)
		if kind == 4:
			gx *= 1.05
		out.append(_spawn(kind, center + Vector3(gx, 0, gz), yaw + rng.randf_range(-0.15, 0.15)))
	return out


func _apply() -> void:
	var p: float = deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


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
			KEY_5:
				_carry = not _carry
				_all(_row, &"set_carrying", [_carry])
			KEY_6: _all(_row, &"play_mine")
			KEY_7:
				_walking = not _walking
				_walk(_row, _walking)
			KEY_8: _all(_row, &"play_cast", [&"support"])
			KEY_9: _all(_row, &"revive")
			KEY_G:
				if _g20.is_empty():
					_g20 = _make_group(G20_CENTER, 20, 1.7, 0.5)
				focus = G20_CENTER
				zoom = 22.0
				_apply()
			KEY_H:
				if _g100.is_empty():
					_g100 = _make_group(G100_CENTER, 100, 1.6, 0.5)
				focus = G100_CENTER
				zoom = 50.0
				_apply()


func _save(nm: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/polish_ice_%s_%s.png" % [tag, nm]
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
	crop.save_png(ProjectSettings.globalize_path("res://docs/art/screens/polish_ice_%s_%s.png" % [tag, nm]))


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _view(z: float, f: Vector3) -> void:
	zoom = z
	focus = f
	_apply()


func _side(f: Vector3, dist: float) -> void:
	_cam.position = f + Vector3(dist, 0.3, 0.0)
	_cam.rotation = Vector3(0.0, deg_to_rad(90.0), 0.0)


func _front(f: Vector3, dist: float) -> void:
	# 3/4 front view slightly from above (closer to the in-game portrait than the RTS camera).
	var dir := Vector3(0.45, 0.35, 1.0).normalized()
	_cam.position = f + dir * dist
	_cam.look_at(f, Vector3.UP)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.2)
	# 1. Row idle at the three RTS zooms (the worker carries so the load shows).
	_row[0].call(&"set_carrying", true)
	await _wait(0.4)
	_view(15.0, Vector3(0, 0.9, 0))
	await _wait(0.3)
	await _save("row_z15")
	_view(28.0, Vector3(0, 0.9, 0))
	await _wait(0.2)
	await _save("row_z28")
	_view(40.0, Vector3(0, 0.9, 0))
	await _wait(0.2)
	await _save("row_z40")
	await _save_crop("row_z40_crop3x", 3)
	# 2. Close-ups (3/4 front) per unit.
	for i: int in _row.size():
		var h: float = 1.0 if i != 4 else 1.4
		_front(_row[i].global_position + Vector3(0, h, 0), 3.4 if i != 4 else 5.0)
		await _wait(0.25)
		await _save("close_%s" % NAMES[i])
	# 2b. Back 3/4 views (hauler ice block + lantern, caster quiver, colossus glacier crystals).
	for i: int in [0, 2, 4]:
		_row[i].get_parent().rotation.y = PI * 0.8
		var hb: float = 1.0 if i != 4 else 1.5
		_front(_row[i].global_position + Vector3(0, hb, 0), 3.2 if i != 4 else 5.0)
		await _wait(0.25)
		await _save("back_%s" % NAMES[i])
		_row[i].get_parent().rotation.y = 0.0
	# 2c. Veterancy 4 (gold trims) + the level-up flash, and the hauler mining.
	_all(_row, &"set_veterancy", [4])
	_all(_row, &"play_level_up")
	_row[0].call(&"play_mine")
	_view(9.0, Vector3(0, 1.0, 0))
	await _wait(0.12)
	await _save("vet4_levelup_z9")
	await _wait(0.4)
	await _save("vet4_mine_z9")
	_all(_row, &"set_veterancy", [1])
	await _wait(1.0)
	# 3. Side view of the row (silhouettes of the weapons).
	for u: Node3D in _row:
		u.get_parent().rotation.y = PI * 0.5
	_view(13.0, Vector3(0, 0.9, 0))
	await _wait(0.3)
	await _save("side_z13")
	for u: Node3D in _row:
		u.get_parent().rotation.y = 0.0
	# 4. Frost breath close-up (all units breathe at once for the shot).
	_front(_row[1].global_position + Vector3(0, 1.4, 0), 2.6)
	_all(_row, &"puff_breath")
	await _wait(0.45)
	await _save("breath_close")
	# 5. Walk mid-stride.
	_walk(_row, true)
	_view(15.0, Vector3(0, 0.9, 0))
	await _wait(0.9)
	await _save("walk_z15")
	_walk(_row, false)
	await _wait(0.6)
	# 5b. Idle fidgets (each unit has its own), mid-way.
	_view(10.0, Vector3(0, 1.0, 0))
	_all(_row, &"play_fidget")
	await _wait(0.62)
	await _save("fidget_z10")
	await _wait(1.2)
	_view(15.0, Vector3(0, 0.9, 0))
	# 6. Attack at the strike / release, front and side.
	_all(_row, &"play_attack")
	await _wait(0.12)
	await _save("attack_z15")
	await _wait(1.2)
	for u: Node3D in _row:
		u.get_parent().rotation.y = PI * 0.5
	_view(13.0, Vector3(0, 0.9, 0))
	await _wait(0.2)
	_all(_row, &"play_attack")
	await _wait(0.07)
	await _save("attack_side_windup")
	await _wait(0.08)
	await _save("attack_side_strike")
	await _wait(1.2)
	for u: Node3D in _row:
		u.get_parent().rotation.y = 0.0
	# 7. Seer support cast + hit flash.
	_view(15.0, Vector3(0, 0.9, 0))
	_row[3].call(&"play_cast", &"support")
	_all(_row, &"play_hit")
	await _wait(0.2)
	await _save("hit_support_z15")
	await _wait(0.8)
	# 8. Death: mid (frosting over) and late (shatter).
	_all(_row, &"play_death")
	await _wait(0.45)
	await _save("death_a_z15")
	await _wait(0.25)
	await _save("death_b_z15")
	await _wait(0.8)
	_all(_row, &"revive")
	await _wait(0.3)
	# 9. Group of 20 (zoom 22 and 40), walking.
	_g20 = _make_group(G20_CENTER, 20, 1.7, 0.5)
	await _wait(0.5)
	_view(22.0, G20_CENTER)
	await _wait(0.4)
	await _save("group20_z22")
	_walk(_g20, true)
	_view(40.0, G20_CENTER)
	await _wait(0.8)
	await _save("group20_z40")
	await _save_crop("group20_z40_crop3x", 3)
	_walk(_g20, false)
	# 10. Group of 100 (zoom 50), walking: fps + process time.
	_g100 = _make_group(G100_CENTER, 100, 1.6, 0.5)
	await _wait(0.5)
	_view(50.0, G100_CENTER)
	_walk(_g100, true)
	await _wait(1.5)
	await _save("group100_z50")
	await _save_crop("group100_z50_crop2x", 2)
	_all(_g100, &"play_attack")
	await _wait(0.12)
	await _save("group100_attack_z50")
	await _measure("walk100 z50")
	_view(30.0, G100_CENTER + Vector3(0, 0, 4))
	await _wait(1.0)
	await _save("group100_z30")
	await _measure("walk100 z30")
	_walk(_g100, false)
	# 11. Silhouette test (black on white) of the row at 40 m.
	_silhouette()
	_view(40.0, Vector3(0, 0.9, 0))
	await _wait(0.4)
	await _save("silhouette_z40")
	await _save_crop("silhouette_z40_crop3x", 3)
	_view(20.0, Vector3(0, 0.9, 0))
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
		1000.0 / ms, proc / float(frames),Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])


func _perf_only() -> void:
	await _wait(0.5)
	_g100 = _make_group(G100_CENTER, 100, 1.6, 0.5)
	_view(50.0, G100_CENTER)
	await _wait(1.0)
	await _measure("idle100 z50")
	_walk(_g100, true)
	await _wait(0.5)
	await _measure("walk100 z50")
	_view(25.0, G100_CENTER)
	await _wait(1.0)
	await _measure("walk100 z25")
	get_tree().quit()


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

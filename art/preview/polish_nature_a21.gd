extends Node3D
## Nature army polish pass 1 preview (task A2.1): Sprigling, Sapling, Bloomtender from the RTS camera (pitch 55,
## fov 50) on the real painted ground, close-ups, every action, a 20 / 100-unit group and the black silhouette test.
## Windowed:
##   Godot_v4.7.2-stable_win64.exe --path . res://art/preview/polish_nature_a21.tscn -- --shots --tag=after
## saves docs/art/screens/polish_nature_a21_<tag>_*.png and quits. `-- --compare` stacks the before / after pairs
## into polish_nature_a21_compare_*.png. `-- --check` (headless ok) prints the budgets and runs every hook.
## By hand: 1 attack, 2 hit, 3 death, 4 level-up + vet 4, 5 carry, 6 mine, 7 walk toggle, 8 support cast,
## 9 revive, 0 sprout, F fidget, G group 20, H group 100, wheel zoom.

const SCENES: Array[String] = [
	"res://art/units/nature/sprigling.tscn",
	"res://art/units/nature/sapling.tscn",
	"res://art/units/nature/bloomtender.tscn",
]
const NAMES: Array[String] = ["sprigling", "sapling", "bloomtender"]
const SPEEDS: Array[float] = [4.6, 4.8, 4.8]
const NATURE_COLOR := Color(0.35, 0.70, 0.25)
const MIRROR_COLOR := Color(0.85, 0.30, 0.12)
const G20_CENTER := Vector3(0, 0, -40)
const G100_CENTER := Vector3(0, 0, -90)
const MIX20: Array[int] = [0, 1, 2, 1, 0, 1, 2, 0, 1, 1, 0, 2, 1, 0, 1, 2, 0, 1, 1, 0]
const COMPARE: Array[String] = ["row_z15", "row_z40_crop3x", "close_sprigling", "close_sapling", "close_bloomtender",
	"back_sprigling", "back_bloomtender", "side_z13", "walk_z15", "attack_z15", "attack_side_strike", "hit_support_z15",
	"vet4_mine_z9", "death_a_z15", "death_b_z15", "sprout_z9", "group20_z40_crop3x", "silhouette_z40_crop3x"]

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
	var args := OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--tag="):
			tag = a.substr(6)
	if "--compare" in args:
		_compare()
		get_tree().quit()
		return
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
		var u := _spawn(i, Vector3((float(i) - 1.0) * 2.4, 0, 0), 0.0)
		if u:
			_row.append(u)
	_apply()
	if "--shots" in args:
		_shots()
	elif "--perf" in args:
		_perf_only()
	elif "--check" in args:
		_check()


## Budget report (draw instances after the merge, particles, vertices, authored parts) + every hook, death_finished.
func _check() -> void:
	for u: Node3D in _row:
		var acc: Array[int] = [0, 0, 0]
		_count(u, acc)
		print("CHECK %s: draw instances %d (+%d particle systems), vertices %d" % [u.name, acc[0], acc[2], acc[1]])
	await _wait(0.3)
	_all(_row, &"play_attack")
	await _wait(1.1)
	_row[2].call(&"play_cast", &"support")
	_all(_row, &"play_hit")
	_all(_row, &"set_veterancy", [4])
	_all(_row, &"play_level_up")
	_all(_row, &"set_carrying", [true])
	_row[0].call(&"play_mine")
	_all(_row, &"set_status", [&"haste", true])
	_all(_row, &"set_status", [&"shroud", true])
	_walk(_row, true)
	await _wait(0.8)
	_walk(_row, false)
	_all(_row, &"play_fidget")
	await _wait(0.5)
	_all(_row, &"set_team_color", [MIRROR_COLOR])
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
			KEY_0: _all(_row, &"play_sprout")
			KEY_F: _all(_row, &"play_fidget")
			KEY_G:
				if _g20.is_empty():
					_g20 = _make_group(G20_CENTER, 20, 1.6, 0.5)
				focus = G20_CENTER
				zoom = 22.0
				_apply()
			KEY_H:
				if _g100.is_empty():
					_g100 = _make_group(G100_CENTER, 100, 1.5, 0.5)
				focus = G100_CENTER
				zoom = 50.0
				_apply()


func _path(nm: String) -> String:
	return ProjectSettings.globalize_path("res://docs/art/screens/polish_nature_a21_%s_%s.png" % [tag, nm])


func _save(nm: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(_path(nm))
	print("saved ", nm, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


## Centre crop enlarged k times with nearest filtering (what the pixels at that zoom really show).
func _save_crop(nm: String, k: int) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var w: int = img.get_width() / k
	var h: int = img.get_height() / k
	var crop := img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))
	crop.resize(w * k, h * k, Image.INTERPOLATE_NEAREST)
	crop.save_png(_path(nm))


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _view(z: float, f: Vector3) -> void:
	zoom = z
	focus = f
	_apply()


func _front(f: Vector3, dist: float) -> void:
	# 3/4 front view slightly from above (closer to the in-game portrait than the RTS camera).
	var dir := Vector3(0.45, 0.35, 1.0).normalized()
	_cam.position = f + dir * dist
	_cam.look_at(f, Vector3.UP)


func _face_all(yaw: float) -> void:
	for u: Node3D in _row:
		u.get_parent().rotation.y = yaw


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.2)
	# 1. Row idle at the three RTS zooms (the worker carries so the load shows).
	_row[0].call(&"set_carrying", true)
	await _wait(0.4)
	_view(12.0, Vector3(0, 0.8, 0))
	await _wait(0.3)
	await _save("row_z15")
	_view(28.0, Vector3(0, 0.8, 0))
	await _wait(0.2)
	await _save("row_z28")
	_view(40.0, Vector3(0, 0.8, 0))
	await _wait(0.2)
	await _save("row_z40")
	await _save_crop("row_z40_crop3x", 3)
	# 2. Close-ups (3/4 front) and backs.
	for i: int in _row.size():
		var h: float = 0.75 if i < 2 else 1.0
		_front(_row[i].global_position + Vector3(0, h, 0), 2.7 if i < 2 else 3.3)
		await _wait(0.25)
		await _save("close_%s" % NAMES[i])
	for i: int in _row.size():
		_row[i].get_parent().rotation.y = PI * 0.8
		var hb: float = 0.75 if i < 2 else 1.0
		_front(_row[i].global_position + Vector3(0, hb, 0), 2.7 if i < 2 else 3.3)
		await _wait(0.25)
		await _save("back_%s" % NAMES[i])
		_row[i].get_parent().rotation.y = 0.0
	if "--quick" in OS.get_cmdline_user_args():
		get_tree().quit()
		return
	# 2b. Veterancy 4 + the level-up flash, the worker mining.
	_all(_row, &"set_veterancy", [4])
	_all(_row, &"play_level_up")
	_row[0].call(&"play_mine")
	_view(8.0, Vector3(0, 0.9, 0))
	await _wait(0.12)
	await _save("vet4_levelup_z9")
	await _wait(0.4)
	await _save("vet4_mine_z9")
	_all(_row, &"set_veterancy", [1])
	await _wait(1.0)
	# 3. Side view of the row (silhouettes of the tools).
	_face_all(PI * 0.5)
	_view(10.0, Vector3(0, 0.8, 0))
	await _wait(0.3)
	await _save("side_z13")
	_face_all(0.0)
	# 4. Walk mid-stride.
	_walk(_row, true)
	_view(12.0, Vector3(0, 0.8, 0))
	await _wait(0.9)
	await _save("walk_z15")
	_face_all(PI * 0.5)
	_view(10.0, Vector3(0, 0.8, 0))
	await _wait(0.2)
	await _save("walk_side")
	_face_all(0.0)
	_walk(_row, false)
	await _wait(0.6)
	# 4b. Idle fidgets (if the units have them).
	_view(9.0, Vector3(0, 0.9, 0))
	_all(_row, &"play_fidget")
	await _wait(0.6)
	await _save("fidget_z10")
	await _wait(1.6)
	# 5. Attack at the strike / release, front and side.
	_view(12.0, Vector3(0, 0.8, 0))
	_all(_row, &"play_attack")
	await _wait(0.12)
	await _save("attack_z15")
	await _wait(1.2)
	_face_all(PI * 0.5)
	_view(10.0, Vector3(0, 0.8, 0))
	await _wait(0.2)
	_all(_row, &"play_attack")
	await _wait(0.06)
	await _save("attack_side_windup")
	await _wait(0.07)
	await _save("attack_side_strike")
	await _wait(1.2)
	_face_all(0.0)
	# 6. Support cast + hit flash.
	_view(12.0, Vector3(0, 0.8, 0))
	_row[2].call(&"play_cast", &"support")
	_all(_row, &"play_hit")
	await _wait(0.2)
	await _save("hit_support_z15")
	await _wait(0.9)
	_front(_row[2].global_position + Vector3(0, 1.1, 0), 3.4)
	_row[2].call(&"play_cast", &"support")
	await _wait(0.2)
	await _save("support_close")
	await _wait(0.9)
	# 7. Death: mid and late.
	_view(12.0, Vector3(0, 0.8, 0))
	_all(_row, &"play_death")
	await _wait(0.4)
	await _save("death_a_z15")
	await _wait(0.3)
	await _save("death_b_z15")
	await _wait(0.8)
	_all(_row, &"revive")
	await _wait(0.4)
	# 8. Sapling sprout (grow in).
	_view(8.0, Vector3(0, 0.7, 0))
	_row[1].call(&"play_sprout")
	await _wait(0.2)
	await _save("sprout_z9")
	await _wait(0.8)
	# 9. Team colour of a mirror match (the cloth swaps to the other colour).
	_all(_row, &"set_team_color", [MIRROR_COLOR])
	_view(10.0, Vector3(0, 0.8, 0))
	await _wait(0.2)
	await _save("mirror_team_z12")
	_all(_row, &"set_team_color", [NATURE_COLOR])
	# 10. Group of 20 (zoom 22 and 40), walking.
	_g20 = _make_group(G20_CENTER, 20, 1.6, 0.5)
	await _wait(0.8)
	_view(22.0, G20_CENTER)
	await _wait(0.4)
	await _save("group20_z22")
	_walk(_g20, true)
	_view(40.0, G20_CENTER)
	await _wait(0.8)
	await _save("group20_z40")
	await _save_crop("group20_z40_crop3x", 3)
	_walk(_g20, false)
	# 11. Group of 100 (zoom 50), walking: fps + process time.
	_g100 = _make_group(G100_CENTER, 100, 1.5, 0.5)
	await _wait(0.8)
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
	# 12. Silhouette test (black on white) of the row at 40 m and 20 m.
	_silhouette()
	_view(40.0, Vector3(0, 0.8, 0))
	await _wait(0.4)
	await _save("silhouette_z40")
	await _save_crop("silhouette_z40_crop3x", 3)
	_view(18.0, Vector3(0, 0.8, 0))
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
	_g100 = _make_group(G100_CENTER, 100, 1.5, 0.5)
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


## Stacks before (top) / after (bottom) of each pair, both at half size, into polish_nature_a21_compare_*.png.
func _compare() -> void:
	for nm: String in COMPARE:
		var pa := ProjectSettings.globalize_path("res://docs/art/screens/polish_nature_a21_before_%s.png" % nm)
		var pb := ProjectSettings.globalize_path("res://docs/art/screens/polish_nature_a21_after_%s.png" % nm)
		if not FileAccess.file_exists(pa) or not FileAccess.file_exists(pb):
			continue
		var a := Image.load_from_file(pa)
		var b := Image.load_from_file(pb)
		var w: int = a.get_width() / 2
		var h: int = a.get_height() / 2
		a.convert(Image.FORMAT_RGB8)
		b.convert(Image.FORMAT_RGB8)
		a.resize(w, h, Image.INTERPOLATE_BILINEAR)
		b.resize(w, h, Image.INTERPOLATE_BILINEAR)
		var out := Image.create(w, h * 2 + 6, false, Image.FORMAT_RGB8)
		out.fill(Color(1, 1, 1))
		out.blit_rect(a, Rect2i(0, 0, w, h), Vector2i(0, 0))
		out.blit_rect(b, Rect2i(0, 0, w, h), Vector2i(0, h + 6))
		out.save_png(ProjectSettings.globalize_path("res://docs/art/screens/polish_nature_a21_compare_%s.png" % nm))
		print("compare ", nm)

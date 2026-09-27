extends Node3D
## Fire army polish preview (task A.4). Game camera (pitch 55, fov 50) on the painted ground.
## Windowed, frame-exact (the animation sheets freeze each copy at its own frame):
##   Godot_v4.7.2-stable_win64.exe --path . res://art/preview/polish_fire_army.tscn --fixed-fps 60 -- --shots --tag=after
## Saves docs/art/screens/polish_fire_<tag>_*.png and quits. Extra user args: --only=row,turn,anim,group,sil,perf.
## By hand (no --shots): 1 attack, 2 hit, 3 death, 4 level-up + vet 4, 5 carry, 6 mine, 7 walk, wheel zoom, R reset.

const IDS: Array[String] = ["cinder_hand", "flame_guard", "ember_archer", "blaze_rider", "ash_hurler"]
const SPEEDS: Array[float] = [4.6, 5.0, 5.2, 7.5, 4.0]
const FIRE := Color(0.85, 0.30, 0.12)
const CENTER := Vector3(15, 0, 15)   # grass, away from the lane and the paving of ground_material

var zoom: float = 12.0
var focus: Vector3 = CENTER + Vector3(0, 0.8, 0)
var tag: String = "after"
var only: PackedStringArray = PackedStringArray()
var _cam: Camera3D
var _env: WorldEnvironment
var _ground: MeshInstance3D
var _sun: DirectionalLight3D
var _live: Array[Node3D] = []   # holders (Unit._visual stand-ins)


func _ready() -> void:
	_env = WorldEnvironment.new()
	_env.environment = load("res://art/environment/world_env.tres")
	add_child(_env)
	_sun = DirectionalLight3D.new()
	_sun.light_color = Color(1.00, 0.93, 0.82)
	_sun.light_energy = 1.3
	_sun.rotation_degrees = Vector3(-50, 35, 0)
	_sun.shadow_enabled = true
	_sun.shadow_normal_bias = 2.0
	add_child(_sun)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 260)
	_ground.mesh = pm
	_ground.material_override = load("res://art/environment/ground_material.tres")
	add_child(_ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()
	else:
		_row(0.0, Vector3.ZERO)


func _want(s: String) -> bool:
	return only.is_empty() or only.has(s)


# ---------------------------------------------------------------- spawning

func _spawn(i: int, at: Vector3, yaw: float) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = yaw
	add_child(holder)
	var m := (load("res://art/units/fire/%s.tscn" % IDS[i]) as PackedScene).instantiate() as Node3D
	holder.add_child(m)
	m.call(&"set_team_color", FIRE)
	m.set_meta(&"kind", i)
	_live.append(holder)
	return m


func _clear() -> void:
	for h: Node3D in _live:
		h.queue_free()
	_live.clear()


func _row(yaw: float, off: Vector3, spacing: float = 2.6) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for i: int in IDS.size():
		out.append(_spawn(i, CENTER + off + Vector3((i - 2) * spacing, 0, 0), yaw))
	return out


func _model(h: Node3D) -> Node3D:
	return h.get_child(0) as Node3D


func _apply() -> void:
	var p: float = deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 2.0, 5.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 2.0, 5.0, 55.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		var ms: Array[Node3D] = []
		for h: Node3D in _live:
			ms.append(_model(h))
		match k.physical_keycode:
			KEY_1: for m: Node3D in ms: m.call(&"play_attack")
			KEY_2: for m: Node3D in ms: m.call(&"play_hit")
			KEY_3: for m: Node3D in ms: m.call(&"play_death")
			KEY_4:
				for m: Node3D in ms:
					m.call(&"play_level_up")
					m.call(&"set_veterancy", 4)
			KEY_5: for m: Node3D in ms: m.call(&"set_carrying", not m.get(&"_carrying"))
			KEY_6: for m: Node3D in ms: m.call(&"play_mine")
			KEY_7: for m: Node3D in ms: m.call(&"set_moving", 0.0 if m.get(&"_speed") > 0.0 else SPEEDS[m.get_meta(&"kind")])
			KEY_R:
				_clear()
				_row(0.0, Vector3.ZERO)


# ---------------------------------------------------------------- capture helpers

func _save(name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/polish_fire_%s_%s.png" % [tag, name]
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, "  fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" objects=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame


func _look(f: Vector3, z: float) -> void:
	focus = f
	zoom = z
	_apply()


## Budget report per type: draw instances (visible geometry incl. particles), keep_separate, vertices.
func _report() -> void:
	print("---- budget (", tag, ")")
	for i: int in IDS.size():
		var m: Node3D = _spawn(i, CENTER + Vector3(0, 0, -40), 0.0)
		await get_tree().process_frame
		var c: Array[int] = [0, 0, 0]
		_count(m, c)
		print("%-13s draw instances %2d  keep_separate %d  vertices %d" % [IDS[i], c[0], c[1], c[2]])
	_clear()


func _count(n: Node, c: Array[int]) -> void:
	for ch: Node in n.get_children():
		if ch is GeometryInstance3D:
			if ch.has_meta(&"keep_separate") or ch is GPUParticles3D or ch is MultiMeshInstance3D:
				c[1] += 1
			c[0] += 1
			if ch is MeshInstance3D and (ch as MeshInstance3D).mesh:
				c[2] += _verts((ch as MeshInstance3D).mesh)
			elif ch is MultiMeshInstance3D:
				var mm := (ch as MultiMeshInstance3D).multimesh
				c[2] += _verts(mm.mesh) * mm.instance_count
		_count(ch, c)


func _verts(m: Mesh) -> int:
	var v: int = 0
	for s: int in m.get_surface_count():
		v += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return v


# ---------------------------------------------------------------- the shot list

func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _frames(30)
	await _report()
	if _want("close"):
		await _shot_close()
	if _want("row"):
		await _shot_rows()
	if _want("turn"):
		await _shot_turn()
	if _want("anim"):
		await _shot_anim()
	if _want("group"):
		await _shot_groups()
	if _want("sil"):
		await _shot_silhouette()
	get_tree().quit()


## 0) Close-ups (zoom 5, game pitch): each unit front / three-quarter / back (worker carrying).
func _shot_close() -> void:
	var yaws: Array[float] = [0.0, -55.0, 160.0]
	var rows: Array = []
	for k: int in yaws.size():
		var r: Array[Node3D] = _row(deg_to_rad(yaws[k]), Vector3(0, 0, k * 8.0), 8.0)
		r[0].call(&"set_carrying", true)
		rows.append(r)
	await _frames(30)
	var names: Array[String] = ["front", "3q", "back"]
	for k: int in yaws.size():
		for i: int in IDS.size():
			var h: Node3D = (rows[k][i] as Node3D).get_parent()
			_look(h.position + Vector3(0, 0.95 if i != 3 else 1.1, 0), 4.6 if i != 3 else 5.6)
			await _frames(2)
			_save("close_%s_%s" % [IDS[i], names[k]])
	_clear()
	await _frames(2)


## 1) The five, facing the camera, zoom 12 (idle, worker carrying, guard veteran 4).
func _shot_rows() -> void:
	var r: Array[Node3D] = _row(0.0, Vector3.ZERO)
	r[0].call(&"set_carrying", true)
	_look(CENTER + Vector3(0, 0.8, 0), 12.0)
	await _frames(40)
	_save("row_z12")
	r[1].call(&"set_veterancy", 4)
	for m: Node3D in r:
		m.call(&"set_moving", SPEEDS[m.get_meta(&"kind")])
	await _frames(50)
	_save("row_walk_z12")
	_clear()
	await _frames(2)
	# Mirror match check: another kingdom colour recolours cloth / pennon only (kit set_team_color); veterancy 4.
	var r2: Array[Node3D] = _row(0.0, Vector3.ZERO)
	for m: Node3D in r2:
		m.call(&"set_team_color", Color(0.42, 0.22, 0.60))
		m.call(&"set_veterancy", 4)
	await _frames(20)
	_save("row_team_vet4_z12")
	_clear()
	await _frames(2)


## 2) Turnaround at zoom 16: rows facing camera / 3-quarter left / away / profile right.
func _shot_turn() -> void:
	var yaws: Array[float] = [0.0, -50.0, 180.0, 90.0]
	for k: int in yaws.size():
		var rr: Array[Node3D] = _row(deg_to_rad(yaws[k]), Vector3(0, 0, -4.5 + k * 3.0), 2.8)
		rr[0].call(&"set_carrying", true)
	_look(CENTER + Vector3(0, 0.6, 0), 17.0)
	await _frames(40)
	_save("turn_z17")
	_clear()
	await _frames(2)


## 3) Animation sheets (side view, face left so the weapon arm is toward the camera). Each copy freezes at its
## own frame: rows = units, columns = time.
func _shot_anim() -> void:
	# attack: anticipation / strike / release+impact / follow-through / recovery
	await _sheet("attack", [3, 6, 9, 15, 27], func(m: Node3D) -> void: m.call(&"play_attack"), 0)
	# walk: one stride in 4 phases after 1 s of walking
	await _sheet("walk", [60, 68, 76, 84], func(m: Node3D) -> void: m.call(&"set_moving", SPEEDS[m.get_meta(&"kind")]), 0)
	# death
	await _sheet("death", [8, 18, 30, 42, 54], func(m: Node3D) -> void: m.call(&"play_death"), 0)
	# hit flinch; worker mine swing (row 0 only is meaningful: cocked / strike + sparks / recovery)
	await _sheet("hit", [2, 4, 7, 10], func(m: Node3D) -> void: m.call(&"play_hit"), 0)
	await _sheet("mine", [18, 27, 31, 45], func(m: Node3D) -> void: m.call(&"play_mine"), 0)


func _sheet(name: String, frames: Array, start: Callable, _unused: int) -> void:
	var cols: int = frames.size()
	var grid: Array = []   # [row][col] model
	for i: int in IDS.size():
		var line: Array[Node3D] = []
		for c: int in cols:
			var at := CENTER + Vector3((c - (cols - 1) * 0.5) * 3.0, 0, -6.0 + i * 3.0)
			line.append(_spawn(i, at, deg_to_rad(-90.0)))
		grid.append(line)
	_look(CENTER + Vector3(0, 0.6, 0), 24.0)
	await _frames(20)
	for line: Array in grid:
		for m: Node3D in line:
			start.call(m)
	var f: int = 0
	for c: int in cols:
		while f < int(frames[c]):
			await get_tree().process_frame
			f += 1
		for line: Array in grid:
			(line[c] as Node3D).process_mode = Node.PROCESS_MODE_DISABLED
	await _frames(3)
	_save("anim_%s" % name)
	for i: int in IDS.size():
		_look(CENTER + Vector3(0, 0.7, -6.0 + i * 3.0), 7.5 if i != 3 else 8.5)
		await _frames(3)
		_save("anim_%s_%s" % [name, IDS[i]])
	_clear()
	await _frames(2)


## 4) A mixed group of 20 (6 guards, 5 archers, 3 riders, 3 hurlers, 3 workers) advancing up-screen, zoom 25 / 45,
## then 100 at 45 (fps and process time printed).
func _shot_groups() -> void:
	var mix: Array[int] = [1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4, 0, 0, 0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var ms: Array[Node3D] = []
	for k: int in mix.size():
		var kind: int = mix[k]
		var row: int = [2, 0, 1, 0, 2][kind]   # riders + workers in front, guards next, archers / hurlers behind
		var at := CENTER + Vector3(rng.randf_range(-4.5, 4.5), 0, -2.5 + row * 2.4 + rng.randf_range(-0.9, 0.9))
		var m := _spawn(kind, at, deg_to_rad(180.0 + rng.randf_range(-25.0, 25.0)))
		ms.append(m)
		if k % 2 == 0:
			m.call(&"set_moving", SPEEDS[kind])
	_look(CENTER, 25.0)
	await _frames(60)
	_save("group20_z25")
	# attack moment, facing the camera
	for h: Node3D in _live:
		h.rotation.y = deg_to_rad(rng.randf_range(-20.0, 20.0))
	for m: Node3D in ms:
		m.call(&"set_moving", 0.0)
	await _frames(20)
	for m: Node3D in ms:
		m.call(&"play_attack")
	await _frames(8)
	_save("group20_attack_z25")
	await _frames(40)
	_look(CENTER, 45.0)
	await _frames(60)
	_save("group20_z45")
	_clear()
	await _frames(2)
	# 100: 5 x 20 block
	for k: int in 100:
		var kind2: int = [1, 1, 2, 2, 3, 4, 0][k % 7]
		var at2 := CENTER + Vector3(-12.0 + (k % 20) * 1.25, 0, -4.0 + (k / 20) * 1.9)
		var m2 := _spawn(kind2, at2, deg_to_rad(180.0))
		if k % 2 == 0:
			m2.call(&"set_moving", SPEEDS[kind2])
		if k % 20 == 19:
			await get_tree().process_frame
	_look(CENTER, 45.0)
	await _frames(90)
	var t0: float = 0.0
	for i: int in 60:
		await get_tree().process_frame
		t0 += Performance.get_monitor(Performance.TIME_PROCESS)
	print("100 units: avg process ms ", t0 / 60.0 * 1000.0)
	_save("group100_z45")
	_look(CENTER, 28.0)
	await _frames(40)
	_save("group100_z28")
	_clear()
	await _frames(2)


## 5) Silhouette test: unlit black on white at zoom 40 and 20 (art-units.md 1.2).
func _shot_silhouette() -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	_ground.material_override = white
	_sun.visible = false
	var env0: Environment = _env.environment
	_env.environment = Environment.new()
	var yaws: Array[float] = [0.0, -60.0, 180.0]
	for k: int in yaws.size():
		_row(deg_to_rad(yaws[k]), Vector3(0, 0, -3.0 + k * 3.0), 2.8)
	await _frames(5)
	for h: Node3D in _live:
		_blacken(h, black)
	_look(CENTER + Vector3(0, 0.6, 0), 40.0)
	await _frames(20)
	_save("silhouette_z40")
	_look(CENTER + Vector3(0, 0.6, 0), 18.0)
	await _frames(5)
	_save("silhouette_z18")
	_clear()
	_env.environment = env0
	_sun.visible = true
	_ground.material_override = load("res://art/environment/ground_material.tres")
	await _frames(2)


func _blacken(n: Node, mat: Material) -> void:
	for c: Node in n.get_children():
		if c is GPUParticles3D or c.name == "Shadow":
			(c as Node3D).visible = false
		elif c is GeometryInstance3D:
			(c as GeometryInstance3D).material_override = mat
		_blacken(c, mat)

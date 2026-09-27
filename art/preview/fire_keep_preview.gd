extends Node3D
## Preview of the Fire Keep from the RTS camera (pitch 55, fov 50 like rts_camera.gd).
## Windowed runs:
##   `-- --shots`   saves docs/art/screens/fire_keep_z15.png and _z40.png, then quits.
##   `-- --states`  saves docs/art/screens/fire_state_*.png (zoom 30) + the contact sheet
##                  fire_keep_states.png, then quits.
##   `-- --polish --tag=before|after`  task A.7: the keep turned like in the 1v1 (rotation -90, gate
##                  toward +x), on the map's ground material with a few Fire units for scale:
##                  docs/art/screens/polish_firekeep_<tag>_{z15,z30,z50,gate_z15,gate_z30,states}.png
##   `-- --compare` stitches polish_firekeep_before_X | _after_X into polish_firekeep_compare_X.png.
##   `-- --stats`   (headless ok) geometry instances, surfaces (draw calls), vertices, lights, particles.
## Keys when viewing by hand: 1 construction replay (6 s), 2 training pulse, 3 HP 40 %, 4 HP 20 %,
## 5 full HP, 6 destroy, 7 toggle selected, 8 cycle team colour, 0 new keep, 9 turn the keep 90.
## Mouse wheel = zoom.

const KEEP_SCENE: PackedScene = preload("res://art/buildings/fire_keep.tscn")
const TEAM_COLORS: Array[Color] = [Color(0.85, 0.30, 0.12), Color(0.20, 0.45, 0.95), Color(0.30, 0.80, 0.30)]
const OUT := "res://docs/art/screens/"
const GROUND_MAT := "res://art/environment/ground_material.tres"
const UNITS: Array[String] = ["res://art/units/fire/cinder_hand.tscn", "res://art/units/fire/flame_guard.tscn"]
const SHEET_NAMES: Array[String] = ["construction50", "idle", "hp40", "hp20", "destroyed_1s2", "destroyed_3s"]

@export var zoom: float = 30.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(0, 0, 0)

@onready var _cam: Camera3D = $Camera3D
@onready var _keep: Node3D = $FireKeep

var _build_p: float = 1.0
var _selected: bool = false
var _team: int = 0
var _tag: String = "after"


func _ready() -> void:
	_apply()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--tag="):
			_tag = a.substr(6)
	if "--compare" in args:
		_compare()
		get_tree().quit()
		return
	if "--polish" in args or "--stats" in args:
		_setup_game_look()
	if "--shots" in args:
		_shots()
	elif "--states" in args:
		_states("fire_state_", "fire_keep_states")
	elif "--polish" in args:
		_polish()
	elif "--stats" in args:
		_stats()


func _process(delta: float) -> void:
	if _build_p < 1.0:
		_build_p = minf(_build_p + delta / 6.0, 1.0)
		_keep.call(&"set_construction_progress", _build_p)


func _apply() -> void:
	var p: float = deg_to_rad(pitch_degrees)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 3.0, 10.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 3.0, 10.0, 55.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_1:
				_build_p = 0.0
				_keep.call(&"set_construction_progress", 0.0)
			KEY_2:
				_keep.call(&"play_training_pulse")
			KEY_3:
				_keep.call(&"set_health_ratio", 0.4)
			KEY_4:
				_keep.call(&"set_health_ratio", 0.2)
			KEY_5:
				_keep.call(&"set_health_ratio", 1.0)
			KEY_6:
				_keep.call(&"play_destroyed")
			KEY_7:
				_selected = not _selected
				_keep.call(&"set_selected", _selected)
			KEY_8:
				_team = (_team + 1) % TEAM_COLORS.size()
				_keep.call(&"set_team_color", TEAM_COLORS[_team])
			KEY_9:
				_keep.rotation.y += PI * 0.5
			KEY_0:
				_new_keep()


func _new_keep() -> void:
	var xf: Transform3D = _keep.transform
	_keep.queue_free()
	_keep = KEEP_SCENE.instantiate() as Node3D
	_keep.transform = xf
	add_child(_keep)
	_build_p = 1.0


func _save(name: String) -> Image:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = OUT + "%s.png" % name
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	return img


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	# zoom 15: keep in the upper third -> focus in front of it (toward the camera).
	for shot: Array in [[15.0, Vector3(0, 0, 2.0), "z15"], [40.0, Vector3(0, 4.0, 0), "z40"]]:
		zoom = shot[0]
		focus = shot[1]
		_apply()
		await _wait(1.5)
		_save("fire_keep_%s%s" % [shot[2], "" if _tag == "after" else _tag])
	get_tree().quit()


## Contact sheet (zoom 30): construction 50 %, idle, 40 % HP, 20 % HP, destroyed at 1.2 s and 3 s.
func _states(prefix: String, sheet_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	zoom = 30.0
	focus = Vector3(0, 5.0, 0)
	_apply()
	var sheet: Array[Image] = []
	# Construction 50 %.
	_keep.call(&"set_construction_progress", 0.0)
	await _wait(0.6)
	_keep.call(&"set_construction_progress", 0.5)
	await _wait(1.0)
	sheet.append(_save(prefix + SHEET_NAMES[0]))
	# Idle (just completed -> flash), then settle.
	_keep.call(&"set_construction_progress", 1.0)
	await _wait(2.0)
	sheet.append(_save(prefix + SHEET_NAMES[1]))
	# Selected + training pulse.
	_keep.call(&"set_selected", true)
	_keep.call(&"play_training_pulse")
	await _wait(0.15)
	_save(prefix + "selected_training")
	_keep.call(&"set_selected", false)
	await _wait(0.5)
	# Damage.
	_keep.call(&"set_health_ratio", 0.4)
	await _wait(2.5)
	sheet.append(_save(prefix + SHEET_NAMES[2]))
	_keep.call(&"set_health_ratio", 0.2)
	await _wait(2.0)
	sheet.append(_save(prefix + SHEET_NAMES[3]))
	print("draw_calls at 20%: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	# Destroyed at 1.2 s and 3 s.
	var finished: Array[bool] = [false]
	_keep.connect(&"destroyed_finished", func() -> void: finished[0] = true)
	_keep.call(&"play_destroyed")
	await _wait(1.2)
	sheet.append(_save(prefix + SHEET_NAMES[4]))
	await _wait(1.9)
	sheet.append(_save(prefix + SHEET_NAMES[5]))
	print("destroyed_finished emitted: ", finished[0])
	# Healing check on a fresh keep: 20 % -> 100 % must revert everything.
	_new_keep()
	await get_tree().process_frame
	_keep.call(&"set_health_ratio", 0.2)
	await _wait(0.3)
	_keep.call(&"set_health_ratio", 1.0)
	await _wait(4.0)
	_save(prefix + "healed")
	# Contact sheet 3 x 2 at 640 x 360.
	var out := Image.create(1920, 720, false, Image.FORMAT_RGBA8)
	for i: int in sheet.size():
		var img: Image = sheet[i]
		img.convert(Image.FORMAT_RGBA8)
		img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(img, Rect2i(0, 0, 640, 360), Vector2i((i % 3) * 640, (i / 3) * 360))
	out.save_png(ProjectSettings.globalize_path(OUT + sheet_name + ".png"))
	print("saved ", sheet_name, ".png")


# ---------------------------------------------------------------- task A.7 (polish)

## The map's look: its ground material and sun, the keep turned like the player's 1v1 keep
## (gate toward +x), and a few Fire units beside the gate for scale.
func _setup_game_look() -> void:
	var ground := get_node_or_null(^"Ground") as MeshInstance3D
	if ground and ResourceLoader.exists(GROUND_MAT):
		ground.material_override = load(GROUND_MAT) as Material
		(ground.mesh as PlaneMesh).size = Vector2(240, 240)
	var sun := get_node_or_null(^"Sun") as DirectionalLight3D
	if sun:
		sun.transform = Transform3D.IDENTITY
		sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
		sun.directional_shadow_max_distance = 90.0
	_keep.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3.ZERO)
	var spots: Array = [[0, Vector3(6.2, 0, -1.2), 100.0], [0, Vector3(7.0, 0, 1.4), 70.0],
		[1, Vector3(6.4, 0, 3.4), 95.0], [0, Vector3(-5.8, 0, 4.6), 200.0]]
	for s: Array in spots:
		var path: String = UNITS[int(s[0])]
		if not ResourceLoader.exists(path):
			continue
		var holder := Node3D.new()
		holder.position = s[1]
		holder.rotation.y = deg_to_rad(float(s[2]))
		add_child(holder)
		var m: Node3D = (load(path) as PackedScene).instantiate() as Node3D
		holder.add_child(m)
		if m.has_method(&"set_team_color"):
			m.call(&"set_team_color", TEAM_COLORS[0])


func _polish() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var base := "polish_firekeep_%s_" % _tag
	await _wait(1.0)
	# In-game orientation, the camera centred on the keep like a player would.
	for z: float in [15.0, 30.0, 50.0]:
		zoom = z
		focus = Vector3(0.0, 0.0, 0.0)
		_apply()
		await _wait(1.2)
		_save(base + "z%d" % int(z))
	# Zoom 30 framed like a player looking at the whole keep (focus a little behind it).
	zoom = 30.0
	focus = Vector3(0.0, 0.0, -5.5)
	_apply()
	await _wait(1.0)
	_save(base + "z30_full")
	# The gate side (the keep turned toward the camera).
	_keep.rotation.y = PI
	for z: float in [15.0, 30.0]:
		zoom = z
		focus = Vector3(0.0, 0.0, 1.0) if z < 20.0 else Vector3.ZERO
		_apply()
		await _wait(1.2)
		_save(base + "gate_z%d" % int(z))
	_keep.rotation.y = -PI * 0.5
	await _states(base + "state_", base + "states")
	await _silhouette(base + "sil_z50")
	get_tree().quit()


## The black-on-white silhouette test of art-keep.md 0.1, at zoom 50 in the 1v1 orientation.
func _silhouette(name: String) -> void:
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	for n: Node in _keep.find_children("*", "GeometryInstance3D", true, false):
		if n is GPUParticles3D or n.name == "ContactDecal":
			(n as Node3D).visible = false
		else:
			(n as GeometryInstance3D).material_override = black
	for c: Node in get_children():
		if c is Node3D and c != _keep and c.get_child_count() > 0 and c.get_child(0) is Node3D and not c is Camera3D:
			(c as Node3D).visible = false
	var ground := get_node_or_null(^"Ground") as MeshInstance3D
	if ground:
		ground.visible = true
		ground.material_override = white
	var we := get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	if we:
		var env := we.environment.duplicate() as Environment
		env.glow_enabled = false
		we.environment = env
	zoom = 50.0
	focus = Vector3(0, 0, -3.0)
	_apply()
	await _wait(0.8)
	_save(name)


func _compare() -> void:
	for s: String in ["z15", "z30", "z50", "gate_z15", "gate_z30", "states"]:
		var a := Image.load_from_file(ProjectSettings.globalize_path(OUT + "polish_firekeep_before_%s.png" % s))
		var b := Image.load_from_file(ProjectSettings.globalize_path(OUT + "polish_firekeep_after_%s.png" % s))
		if a == null or b == null or a.is_empty() or b.is_empty():
			print("compare: missing ", s)
			continue
		a.convert(Image.FORMAT_RGBA8)
		b.convert(Image.FORMAT_RGBA8)
		var vertical: bool = s == "states"
		if not vertical:
			a.resize(a.get_width() / 2, a.get_height() / 2, Image.INTERPOLATE_BILINEAR)
			b.resize(b.get_width() / 2, b.get_height() / 2, Image.INTERPOLATE_BILINEAR)
		var gap := 8
		var w: int = a.get_width() if vertical else a.get_width() + b.get_width() + gap
		var h: int = a.get_height() + b.get_height() + gap if vertical else maxi(a.get_height(), b.get_height())
		var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
		out.fill(Color.WHITE)
		out.blit_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i.ZERO)
		out.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()),
			Vector2i(0, a.get_height() + gap) if vertical else Vector2i(a.get_width() + gap, 0))
		out.save_png(ProjectSettings.globalize_path(OUT + "polish_firekeep_compare_%s.png" % s))
		print("compare: wrote ", s)


## Geometry / draw-call / light / particle counts of one keep (its own nodes only).
func _stats() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var inst := 0
	var surfaces := 0
	var verts := 0
	var lights := 0
	var particles := 0
	var systems := 0
	for n: Node in _keep.find_children("*", "", true, false):
		if n is OmniLight3D or n is SpotLight3D:
			lights += 1
		var gp := n as GPUParticles3D
		if gp:
			if gp.emitting:
				systems += 1
				particles += gp.amount
			continue
		var gi := n as GeometryInstance3D
		if gi == null or not gi.is_visible_in_tree():
			continue
		var mesh: Mesh = null
		var count := 1
		if gi is MeshInstance3D:
			mesh = (gi as MeshInstance3D).mesh
		elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh:
			mesh = (gi as MultiMeshInstance3D).multimesh.mesh
			count = (gi as MultiMeshInstance3D).multimesh.instance_count
		if mesh == null:
			continue
		inst += 1
		surfaces += mesh.get_surface_count()
		for si: int in mesh.get_surface_count():
			var arr: Array = mesh.surface_get_arrays(si)
			if arr.size() > 0 and arr[Mesh.ARRAY_VERTEX] != null:
				verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() * count
	print("STATS instances=%d surfaces(draw calls)=%d particle_systems=%d particles=%d lights=%d vertices=%d" % [
		inst, surfaces + systems, systems, particles, lights, verts])
	# CPU cost of the keep's one _process (idle, then at 20 % HP), averaged over 2000 calls.
	for hp: float in [1.0, 0.2]:
		_keep.call(&"set_health_ratio", hp)
		var t0: int = Time.get_ticks_usec()
		for i: int in 2000:
			_keep.call(&"_process", 0.016)
		print("STATS cpu_ms_per_frame(hp=%.1f)=%.4f" % [hp, (Time.get_ticks_usec() - t0) / 1000.0 / 2000.0])
	get_tree().quit()

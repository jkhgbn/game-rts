extends SceneTree
## Task A.17 (visual bugs): white squares on unit particles + level-up whiteout.
## Scan (headless ok):  $GODOT --headless --path . -s tests/test_a17.gd --fixed-fps 60 --quit-after 600
##   Every GPUParticles3D of every unit scene: a billboard quad drawn with no mask texture (a hard square), a draw
##   pass without a material (Godot's default white), or a scale curve on a billboard material without
##   billboard_keep_scale (Godot 4.7 then ignores the particle scale). Prints PASS a17 / FAIL a17.
## Shots (windowed):   Godot_v4.7.2-stable_win64.exe --path . -s tests/test_a17.gd --fixed-fps 60 --quit-after 3000 -- --shots --tag=after
##   docs/art/screens/fix_a17_<tag>_<army>.png: 2 x 2 sheet (rest, release +0.06 s, release +0.2 s, level-up peak)
##   and fix_a17_<tag>_closeup.png (Shardcaster + Burr Slinger up close: rest / release / level-up).

const TASK_ID := "a17"
const ARMIES: Dictionary = {
	"fire": ["fire/cinder_hand", "fire/flame_guard", "fire/ember_archer", "fire/blaze_rider", "fire/ash_hurler"],
	"shadow": ["shadow/gloom_thrall", "shadow/shade", "shadow/nightbolt", "shadow/grave_hound", "shadow/shadow_knight",
		"neutral/ruin_warden"],
	"ice": ["ice/rime_hauler", "ice/rimeshield", "ice/shardcaster", "ice/rime_seer", "ice/rime_colossus"],
	"nature": ["nature/sprigling", "nature/thornling", "nature/sapling", "nature/burr_slinger", "nature/bloomtender",
		"nature/bramblehorn"],
	"wizards": ["wizards/vessa", "wizards/malrik", "wizards/torvald", "wizards/ysolde"],
}
const SPACING := 2.1

var _world: Node3D
var _cam: Camera3D
var _rows: Dictionary = {}
var _row_z: Dictionary = {}
var _close: Array = []
var _tag: String = "after"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--tag="):
			_tag = a.substr(6)
	_world = Node3D.new()
	root.add_child(_world)
	var we := WorldEnvironment.new()
	we.environment = load("res://art/environment/world_env.tres")
	_world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	_world.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	ground.material_override = load("res://art/environment/ground_material.tres")
	_world.add_child(ground)
	var z := 0.0
	for army: String in ARMIES:
		var list: Array = []
		var ids: Array = ARMIES[army]
		for i: int in ids.size():
			var m: Node3D = (load("res://art/units/%s.tscn" % ids[i]) as PackedScene).instantiate()
			m.position = Vector3((i - (ids.size() - 1) * 0.5) * SPACING, 0, z)
			_world.add_child(m)
			list.append(m)
		_rows[army] = list
		_row_z[army] = z
		z -= 40.0
	# close-up pair
	for i: int in 2:
		var p: String = ["res://art/units/ice/shardcaster.tscn", "res://art/units/nature/burr_slinger.tscn"][i]
		var m: Node3D = (load(p) as PackedScene).instantiate()
		m.position = Vector3(-1.1 + 2.2 * i, 0, z)
		_world.add_child(m)
		_close.append(m)
	_row_z["closeup"] = z
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	_world.add_child(_cam)
	_game_cam(12.0, Vector3.ZERO)
	if "--shots" in args:
		_shots.call_deferred()
	else:
		_scan.call_deferred()


func _game_cam(zoom: float, focus: Vector3) -> void:
	var pitch := deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, 0.9 + sin(pitch) * zoom, cos(pitch) * zoom)
	_cam.rotation = Vector3(-pitch, 0.0, 0.0)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


# ---------------------------------------------------------------- scan

func _scan() -> void:
	await process_frame
	await process_frame
	var bad := 0
	var warn := 0
	var total := 0
	var all: Array = []
	for army: String in _rows:
		all.append_array(_rows[army])
	for m: Node in all:
		for n: Node in m.find_children("*", "GPUParticles3D", true, false):
			var p := n as GPUParticles3D
			total += 1
			var why := _problems(p)
			if why.contains("SQUARE") or why.contains("no material"):
				bad += 1
				print("  SQUARE %s/%s: %s" % [m.name, m.get_path_to(p), why])
			elif why != "":
				warn += 1
				print("  warn %s/%s: %s" % [m.name, m.get_path_to(p), why])
	print("particle emitters checked: %d, hard squares: %d, keep_scale warnings (masked, not squares): %d" % [total, bad, warn])
	print("PASS %s" % TASK_ID if bad == 0 else "FAIL %s: %d emitters draw hard squares" % [TASK_ID, bad])
	quit()


func _problems(p: GPUParticles3D) -> String:
	var out: PackedStringArray = []
	var pm := p.process_material as ParticleProcessMaterial
	var scaled: bool = pm != null and (pm.scale_curve != null or pm.scale_min != pm.scale_max)
	for i: int in p.draw_passes:
		var mesh: Mesh = p.get_draw_pass_mesh(i)
		if mesh == null:
			continue
		var mats: Array[Material] = []
		if p.material_override:
			mats.append(p.material_override)
		else:
			for s: int in mesh.get_surface_count():
				mats.append(mesh.surface_get_material(s))
		for mat: Material in mats:
			if mat == null:
				out.append("pass %d has no material (default white)" % (i + 1))
				continue
			var bm := mat as BaseMaterial3D
			if bm == null:
				continue
			var flat := mesh is QuadMesh or mesh is PlaneMesh
			if flat and bm.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED and bm.albedo_texture == null \
					and bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				out.append("SQUARE: billboard quad with no mask texture (%s)" % ("additive" if bm.blend_mode == BaseMaterial3D.BLEND_MODE_ADD else "alpha"))
			if flat and bm.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES and scaled and not bm.billboard_keep_scale:
				out.append("scale curve ignored (billboard_keep_scale off)")
	return ", ".join(out)


# ---------------------------------------------------------------- shots

func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _wait(1.0)
	for army: String in _rows:
		var row: Array = _rows[army]
		_game_cam(6.5 if row.size() <= 4 else 8.0, Vector3(0, 0.4, _row_z[army]))
		await _wait(0.8)
		await _sequence(row, "fix_a17_%s_%s" % [_tag, army])
	# close-up: RTS pitch, 3.2 m
	_game_cam(3.2, Vector3(0, 0.7, _row_z["closeup"]))
	await _wait(3.6)   # past one breath cycle
	await _sequence(_close, "fix_a17_%s_closeup" % _tag)
	print("A17 SHOTS DONE ", _tag)
	quit()


func _sequence(row: Array, nm: String) -> void:
	var imgs: Array[Image] = [_grab()]
	for m in row:
		m.play_attack()
	await _wait(0.18)
	imgs.append(_grab())
	await _wait(0.14)
	imgs.append(_grab())
	await _wait(0.8)
	for m in row:
		m.play_level_up()
	await _wait(0.06)
	imgs.append(_grab())
	_sheet(imgs, nm)


func _grab() -> Image:
	return root.get_texture().get_image()


func _sheet(imgs: Array[Image], nm: String) -> void:
	var w: int = imgs[0].get_width()
	var h: int = imgs[0].get_height()
	var out := Image.create(w * 2, h * 2, false, imgs[0].get_format())
	for i: int in imgs.size():
		out.blit_rect(imgs[i], Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
	out.save_png("res://docs/art/screens/%s.png" % nm)

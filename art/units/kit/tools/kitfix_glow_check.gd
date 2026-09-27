extends Node3D
## Task A.16 (kit shader bug): instance-uniform slot audit + glow / flash screenshot rig for every unit scene.
## Headless ok:  $GODOT --headless --path . res://art/units/kit/tools/kitfix_glow_check.tscn --fixed-fps 60 --quit-after 1200 -- --audit
##   For every GeometryInstance3D of every unit it lists the instance uniforms of all its materials with their
##   instance-uniform slot. Two different names on one slot = COLLISION (the renderer writes both into the same
##   vec4 of the instance's buffer, the last write wins). Also checks every unit shader against the kit slot map
##   (CharacterModel.INSTANCE_SLOTS) and that the kit finds every flash / glow instance. Prints KITFIX AUDIT OK.
## Windowed:     Godot_v4.7.2-stable_win64.exe --path . res://art/units/kit/tools/kitfix_glow_check.tscn --fixed-fps 60 -- --shots --tag=after
##   Saves docs/art/screens/kitfix_glow_<tag>_<army>.png (2 x 2: rest, rest 0.7 s later, hit flash, level-up flash).

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

var _cam: Camera3D
var _rows: Dictionary = {}   # army -> Array of models (untyped: hooks live on the model scripts)
var _row_z: Dictionary = {}
var _tag: String = "after"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_setup_world()
	var z := 0.0
	for army: String in ARMIES:
		var list: Array = []
		var ids: Array = ARMIES[army]
		for i: int in ids.size():
			var p := "res://art/units/%s.tscn" % ids[i]
			if not ResourceLoader.exists(p):
				continue
			var m: Node3D = (load(p) as PackedScene).instantiate()
			m.position = Vector3((i - (ids.size() - 1) * 0.5) * SPACING, 0, z)
			add_child(m)
			list.append(m)
		_rows[army] = list
		_row_z[army] = z
		z -= 40.0
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_game_cam(12.0, Vector3.ZERO)
	for a: String in args:
		if a.begins_with("--tag="):
			_tag = a.substr(6)
	if "--audit" in args:
		_audit()
	elif "--shots" in args:
		_shots(_tag)


func _setup_world() -> void:
	var we := WorldEnvironment.new()
	we.environment = load("res://art/environment/world_env.tres")
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	ground.material_override = load("res://art/environment/ground_material.tres")
	add_child(ground)


func _game_cam(zoom: float, focus: Vector3) -> void:
	var pitch := deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, 0.9 + sin(pitch) * zoom, cos(pitch) * zoom)
	_cam.rotation = Vector3(-pitch, 0.0, 0.0)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


# ---------------------------------------------------------------- screenshots

func _shots(tag: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	await _probe()
	await _wait(1.0)
	for army: String in _rows:
		var row: Array = _rows[army]
		if row.is_empty():
			continue
		_game_cam(6.5 if row.size() <= 4 else 8.0, Vector3(0, 0.4, _row_z[army]))
		await _wait(0.6)
		var imgs: Array[Image] = [_grab()]
		imgs[0].save_png("res://docs/art/screens/kitfix_glow_%s_%s.png" % [tag, army])
		await _wait(0.7)
		imgs.append(_grab())
		for m in row:
			m.play_hit()
		await _wait(0.03)
		imgs.append(_grab())
		await _wait(0.6)
		for m in row:
			m.play_level_up()
		await _wait(0.05)
		imgs.append(_grab())
		await _wait(0.6)
		_sheet(imgs, "kitfix_glow_%s_%s_sheet" % [tag, army])
	print("KITFIX SHOTS DONE ", tag)
	get_tree().quit()


## GPU truth test (windowed only): two-surface meshes (painted quad + glow quad, like a merged pivot) in their own
## SubViewport, glow_boost = 2. The glow quad must render exactly like a glow-only reference mesh, whatever the
## surface order and whatever the kit writes later (ao_bottom, ao_height, hit_flash). Prints PROBE ... OK / DARK.
func _probe() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(512, 128)
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.0
	cam.position = Vector3(0, 0, 5)
	sv.add_child(cam)
	var glow := ShaderMaterial.new()
	glow.shader = CharacterModel.GLOW_SHADER
	glow.set_shader_parameter(&"glow_color", Color(0.2, 0.2, 0.2))
	glow.set_shader_parameter(&"energy", 1.0)
	glow.set_shader_parameter(&"pulse_speed", 0.0)
	glow.set_shader_parameter(&"phase", PI * 0.5)
	var painted: Material = CharacterModel.palette(&"unit_gold_trim")
	# name, surface materials (left quad, right quad = glow), probe centre x
	var specs: Array = [["painted+glow", [painted, glow], -3.0], ["glow+painted", [glow, painted], -1.0],
		["painted+glow, ao_bottom written later", [painted, glow], 1.0], ["glow only (reference)", [null, glow], 3.0]]
	var nodes: Array[MeshInstance3D] = []
	for s: Array in specs:
		var mats: Array = s[1]
		var am := ArrayMesh.new()
		for q: int in 2:
			var m: Material = mats[q]
			if m == null:
				continue
			# The glow quad is always on the right (+0.5), whatever its surface index.
			var x: float = s[2] + (0.5 if m == glow else -0.5)
			var pm := PlaneMesh.new()
			pm.size = Vector2(0.8, 0.8)
			pm.orientation = PlaneMesh.FACE_Z
			var arr := pm.get_mesh_arrays()
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for k: int in v.size():
				v[k] += Vector3(x, 0, 0)
			arr[Mesh.ARRAY_VERTEX] = v
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			am.surface_set_material(am.get_surface_count() - 1, m)
		var mi := MeshInstance3D.new()
		mi.mesh = am
		sv.add_child(mi)
		mi.set_instance_shader_parameter(&"ao_height", 1.6)
		mi.set_instance_shader_parameter(&"glow_boost", 2.0)
		nodes.append(mi)
	for k: int in 4:
		await RenderingServer.frame_post_draw
	# What the kit / unit scripts do later: flash, height, and (tscn-authored / _build_shadow) ao_bottom.
	for mi: MeshInstance3D in nodes:
		mi.set_instance_shader_parameter(&"hit_flash", 0.0)
		mi.set_instance_shader_parameter(&"ao_height", 1.7)
	nodes[2].set_instance_shader_parameter(&"ao_bottom", 0.0)
	for k: int in 4:
		await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	var ref := img.get_pixel(int((3.5 + 4.0) / 8.0 * 512.0), 64)
	for i: int in specs.size():
		var c := img.get_pixel(int((specs[i][2] + 0.5 + 4.0) / 8.0 * 512.0), 64)
		var same: bool = absf(c.r - ref.r) < 0.01 and absf(c.g - ref.g) < 0.01
		print("PROBE %-40s glow pixel %.3f (reference %.3f) %s" % [specs[i][0], c.r, ref.r, "OK" if same else "DARK / WRONG"])
	img.save_png("res://docs/art/screens/kitfix_glow_probe_%s.png" % _tag)
	sv.queue_free()


func _grab() -> Image:
	return get_viewport().get_texture().get_image()


func _sheet(imgs: Array[Image], nm: String) -> void:
	var w: int = imgs[0].get_width()
	var h: int = imgs[0].get_height()
	var out := Image.create(w * 2, h * 2, false, imgs[0].get_format())
	for i: int in imgs.size():
		out.blit_rect(imgs[i], Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
	out.resize(w, h)   # 2 x 2 sheet at the window size (each cell half size)
	out.save_png("res://docs/art/screens/%s.png" % nm)


# ---------------------------------------------------------------- audit

func _audit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var ok := true
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	# 1. Every unit shader declares the kit instance uniforms on their map slots.
	var checked: Dictionary = {}
	for army: String in _rows:
		for m in _rows[army]:
			for gi: GeometryInstance3D in _geometry(m):
				for mat: Material in m._materials_of(gi):
					if not mat is ShaderMaterial or (mat as ShaderMaterial).shader == null:
						continue
					var sh := (mat as ShaderMaterial).shader
					if checked.has(sh.resource_path):
						continue
					checked[sh.resource_path] = true
					for u: Array in _instance_uniforms(sh):
						if slots.has(u[0]) and u[1] != slots[u[0]]:
							push_error("%s: %s on slot %d, map says %d" % [sh.resource_path, u[0], u[1], slots[u[0]]])
							ok = false
	print("shaders checked: ", checked.keys())
	# 2. Per geometry instance: names sharing a slot, flash / glow coverage by the kit.
	var collisions := 0
	var mixed := 0
	for army: String in _rows:
		for m in _rows[army]:
			for gi: GeometryInstance3D in _geometry(m):
				var by_slot: Dictionary = {}
				var names: Array[String] = []
				var order: Array[String] = []
				for mat: Material in m._materials_of(gi):
					if not mat is ShaderMaterial or (mat as ShaderMaterial).shader == null:
						continue
					var sh := (mat as ShaderMaterial).shader
					order.append(sh.resource_path.get_file().get_basename())
					for u: Array in _instance_uniforms(sh):
						var nm: String = u[0]
						if names.has(nm):
							continue
						names.append(nm)
						if by_slot.has(u[1]):
							by_slot[u[1]].append(nm)
						else:
							by_slot[u[1]] = [nm]
				var where := "%s/%s" % [m.name, m.get_path_to(gi)]
				for s: int in by_slot:
					if (by_slot[s] as Array).size() > 1:
						collisions += 1
						print("  COLLISION %s slot %d: %s  (surfaces %s)" % [where, s, by_slot[s], order])
				if names.has("glow_boost") and names.has("hit_flash"):
					mixed += 1
				if names.has("hit_flash") and not m._flash_all_targets.has(gi) and not _own_flash(m, gi):
					print("  not flashed by the kit: ", where, " ", order)
				if names.has("glow_boost") and not m._glow_nodes.has(gi) and not gi.has_meta(&"own_glow"):
					print("  glow not driven by the kit: ", where, " ", order)
	print("geometry instances mixing painted + glow surfaces: ", mixed, ", slot collisions: ", collisions)
	ok = ok and collisions == 0
	print("KITFIX AUDIT OK" if ok else "KITFIX AUDIT FAILED")
	get_tree().quit()


## Nodes a unit script flashes itself (Fire's ash ball, Ice's separate crystal parts before A.16).
func _own_flash(m: Node, gi: GeometryInstance3D) -> bool:
	return "_ice_nodes" in m and (m.get("_ice_nodes") as Array).has(gi) or ("_ball" in m and m.get("_ball") == gi)


func _geometry(m: Node) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		if n != m.get("_shadow"):
			out.append(n)
	return out


## [[name, slot], ...] of a shader, includes resolved. Slots: instance_index(N) or the implicit declaration order.
static func _instance_uniforms(sh: Shader) -> Array:
	var out: Array = []
	var code := _expand(sh.code, 0)
	var re := RegEx.create_from_string("instance\\s+uniform\\s+\\w+\\s+(\\w+)\\s*(:[^=;]*)?[=;]")
	var idx_re := RegEx.create_from_string("instance_index\\s*\\(\\s*(\\d+)\\s*\\)")
	var implicit := 0
	for line: String in code.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("//"):
			continue
		var r := re.search(l)
		if r == null:
			continue
		var hint := r.get_string(2)
		var ir := idx_re.search(hint)
		if ir:
			out.append([r.get_string(1), int(ir.get_string(1))])
		else:
			out.append([r.get_string(1), implicit])
			implicit += 1
	return out


static func _expand(code: String, depth: int) -> String:
	if depth > 4:
		return code
	var re := RegEx.create_from_string("#include\\s+\"([^\"]+)\"")
	var out := code
	for r: RegExMatch in re.search_all(code):
		var inc := load(r.get_string(1)) as ShaderInclude
		if inc:
			out = out.replace(r.get_string(0), _expand(inc.code, depth + 1))
	return out

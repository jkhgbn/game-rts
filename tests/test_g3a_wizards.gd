extends SceneTree
## G3a (graphics pass): the 4 wizard heroes (Vessa, Malrik, Torvald, Ysolde) keep their contract (scenes, pivots,
## hooks, staff / orb nodes, expressions) and gain the hero layer: a rune band ("Runes", wizard_runes.gdshader, kit
## glow_boost + cast flare) and a close-camera kingdom aura ("HeroAura", looping; not built on Low, so absent in a
## headless run; phase B forces High through WizardModel.aura_quality_override: it emits with the camera near, stops
## when the camera is far (the model freezes), stops on death and comes back on revive).
## Headless:  tools\godot_run.ps1 --headless --path . -s tests/test_g3a_wizards.gd --fixed-fps 60 --quit-after 3000
## Shots (windowed, not CI): ... -s tests/test_g3a_wizards.gd --fixed-fps 60 --quit-after 6000 -- --shots --gfx=high
##   -> docs/art/lab/g3a_wizards/skirmish_z10.png / skirmish_z40.png (+ z10 close-ups per wizard): the 4 models lined up
##   next to the player's wizard in a 1v1 skirmish.

const TASK_ID := "g3a_wizards"
const SCENES := {
	&"vessa": "res://art/units/wizards/vessa.tscn",
	&"malrik": "res://art/units/wizards/malrik.tscn",
	&"torvald": "res://art/units/wizards/torvald.tscn",
	&"ysolde": "res://art/units/wizards/ysolde.tscn",
}
const CASTS := {
	&"vessa": [&"fireball", &"ember_step", &"kindle"],
	&"malrik": [&"shadow_lance", &"soul_siphon", &"umbral_shroud"],
	&"torvald": [&"rime_bolt", &"flash_freeze", &"rime_aegis"],
	&"ysolde": [&"thornburst", &"wild_bloom", &"call_the_thicket"],
}
const PIVOTS := ["Root", "Root/Hips", "Root/Chest", "Root/Chest/Head", "Root/Chest/ArmL", "Root/Chest/ArmR", "Fx"]
const OUT := "res://docs/art/lab/g3a_wizards"

var _fails: PackedStringArray = []
var _models: Array[Node3D] = []
var _frame := 0
var _shots := false
var _level: Node
var _step := 0
var _wait := 0
var _close_cam: Camera3D
var _holder: Node3D
var _cam: Camera3D


func _initialize() -> void:
	_shots = "--shots" in OS.get_cmdline_user_args()
	if _shots:
		_level = load("res://scenes/skirmish.tscn").instantiate()
		root.add_child(_level)
		current_scene = _level
		return
	WizardModel.aura_quality_override = -1   # phase A: the real tier (Low in a headless run: no aura node)
	_spawn(Vector3(0, 6, 12))


func _process(_d: float) -> bool:
	_frame += 1
	if _shots:
		return _shots_step()
	if _frame == 3:
		_check_static()
	elif _frame == 4:
		for m: Node3D in _models:
			m.call(&"set_team_color", Color(0.2, 0.5, 0.9))
			m.call(&"set_moving", 3.0)
	elif _frame == 40:
		for m: Node3D in _models:
			m.call(&"set_moving", 0.0)
			m.call(&"play_attack")
	elif _frame >= 80 and _frame < 260 and _frame % 60 == 20:
		var i := (_frame - 80) / 60
		for m: Node3D in _models:
			m.call(&"play_cast", CASTS[m.get_meta(&"wid")][i])
	elif _frame == 95:
		_check_flare()
	elif _frame == 270:
		for m: Node3D in _models:
			if m.has_method(&"set_expression"):
				m.call(&"set_expression", &"fierce")
			m.call(&"play_level_up")
	elif _frame == 330:
		for m: Node3D in _models:
			m.call(&"play_death")
	elif _frame == 460:
		for m: Node3D in _models:
			m.call(&"revive")
	# ---- phase B: the aura on a forced High tier (WizardModel.aura_quality_override), a camera near / far, death.
	elif _frame == 500:
		_holder.queue_free()
		_models.clear()
		WizardModel.aura_quality_override = GameSettings.GFX_HIGH
		_spawn(Vector3(0, 3, 7))
	elif _frame == 504:
		_check_aura_built()
	elif _frame == 545:
		_expect_aura(true, "camera 7 m away")
		_cam.position = Vector3(0, 70, 90)   # ~110 m: far tier (the kit freezes the model) and out of AURA_RANGE
	elif _frame == 600:
		_expect_aura(false, "camera 110 m away (frozen)")
		_cam.position = Vector3(0, 3, 7)
	elif _frame == 650:
		_expect_aura(true, "camera back at 7 m")
		for m: Node3D in _models:
			m.call(&"play_death")
	elif _frame == 700:
		_expect_aura(false, "dead")
		for m: Node3D in _models:
			m.call(&"revive")
	elif _frame == 760:
		_expect_aura(true, "revived")
		WizardModel.aura_quality_override = -1
		if _fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
		return true
	return false


## Two instances of each wizard in a row at the origin, a current camera at `cam_at` looking at them.
func _spawn(cam_at: Vector3) -> void:
	_holder = Node3D.new()
	root.add_child(_holder)
	_cam = Camera3D.new()
	_holder.add_child(_cam)
	_cam.position = cam_at
	_cam.current = true
	var x := -5.6
	for id: StringName in SCENES:
		for k: int in 2:   # the second instance runs the cached-type path
			var m := (load(SCENES[id]) as PackedScene).instantiate() as Node3D
			m.name = "%s_%d" % [id, k]
			m.set_meta(&"wid", id)
			m.position = Vector3(x, 0, 0)
			x += 1.6
			_holder.add_child(m)
			_models.append(m)


func _check_aura_built() -> void:
	for m: Node3D in _models:
		var a := m.find_child("HeroAura", true, false) as GPUParticles3D
		if a == null:
			_fails.append("%s has no HeroAura on High" % m.name)
			continue
		if a.one_shot:
			_fails.append("%s HeroAura is one-shot" % m.name)
		if a.amount > 16:
			_fails.append("%s HeroAura has %d particles (> 16)" % [m.name, a.amount])
	for i: int in range(0, _models.size(), 2):
		var a0 := _models[i].find_child("HeroAura", true, false) as GPUParticles3D
		var a1 := _models[i + 1].find_child("HeroAura", true, false) as GPUParticles3D
		if a0 and a1 and a0.process_material != a1.process_material:
			_fails.append("%s aura material built per instance" % _models[i].name)


func _expect_aura(on: bool, why: String) -> void:
	for m: Node3D in _models:
		var a := m.find_child("HeroAura", true, false) as GPUParticles3D
		if a and a.emitting != on:
			_fails.append("%s aura emitting=%s (want %s: %s)" % [m.name, a.emitting, on, why])


func _check_static() -> void:
	for m: Node3D in _models:
		for p: String in PIVOTS:
			if m.get_node_or_null(p) == null:
				_fails.append("%s lost pivot %s" % [m.name, p])
		for h: String in ["set_team_color", "set_moving", "play_attack", "play_cast", "play_hit", "play_death",
				"play_level_up", "revive", "set_expression", "get_expression"]:
			if not m.has_method(h):
				_fails.append("%s lost hook %s" % [m.name, h])
		if m.find_child("Staff", true, false) == null and m.find_child("Orb", true, false) == null:
			_fails.append("%s has no Staff / Orb node" % m.name)
		var r := m.find_child("Runes", true, false) as MeshInstance3D
		if r == null or r.mesh == null:
			_fails.append("%s has no Runes mesh" % m.name)
		else:
			var mat := r.mesh.surface_get_material(0) as ShaderMaterial
			if mat == null or not String(mat.shader.resource_path).ends_with("wizard_runes.gdshader"):
				_fails.append("%s Runes not on wizard_runes.gdshader" % m.name)
			if r.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				_fails.append("%s Runes cast shadows" % m.name)
		if m.find_child("HeroAura", true, false) != null:
			_fails.append("%s built a HeroAura on Low graphics (headless run)" % m.name)
	# shared per type: the two instances of a wizard draw the same rune mesh
	for i: int in range(0, _models.size(), 2):
		var r0 := _models[i].find_child("Runes", true, false) as MeshInstance3D
		var r1 := _models[i + 1].find_child("Runes", true, false) as MeshInstance3D
		if r0 and r1 and r0.mesh != r1.mesh:
			_fails.append("%s rune mesh built per instance" % _models[i].name)


func _check_flare() -> void:
	for m: Node3D in _models:
		var r := m.find_child("Runes", true, false) as GeometryInstance3D
		if r and float(r.get_instance_shader_parameter(&"flare")) <= 0.05:
			_fails.append("%s runes do not flare on a cast" % m.name)


# ---------------------------------------------------------------- windowed shots in a skirmish

func _shots_step() -> bool:
	var hero: Node3D = _level.get(&"hero") if _level else null
	if hero == null:
		if _frame > 5000:
			print("FAIL %s: skirmish never spawned the hero" % TASK_ID)
			return true
		return false
	_wait += 1
	if paused:   # the STR / INT path chooser pauses the match at the start: models and the camera must run
		paused = false
	match _step:
		0:
			var base := hero.global_position + Vector3(3.0, 0, 3.0)
			var i := 0
			for id: StringName in SCENES:
				var m := (load(SCENES[id]) as PackedScene).instantiate() as Node3D
				m.name = "G3aShot_" + String(id)
				_level.add_child(m)
				m.global_position = base + Vector3(1.7 * float(i) - 2.55, 0, 0)
				m.rotation.y = 0.0
				_models.append(m)
				i += 1
			_look(base, 10.0)
			_hide_ui(root)
			_step = 1
			_wait = 0
		1:
			if _wait == 60:
				var cam := root.get_viewport().get_camera_3d()
				var rig: Node = _level.get(&"camera_rig")
				print("g3a shots: camera ", cam.global_position if cam else Vector3.INF, " hero ", hero.global_position,
					" rig zoom ", rig.get(&"_zoom") if rig else -1.0, " rig cam is current ", rig.get(&"camera") == cam if rig else false)
				for m: Node3D in _models:
					print("g3a shots: ", m.name, " at ", m.global_position, " visible ", m.is_visible_in_tree())
			if _wait >= 150:
				_shot("skirmish_z10")
				_look(_models[0].global_position + Vector3(2.55, 0, 0), 40.0)
				_step = 2
				_wait = 0
		2:
			if _wait >= 90:
				_shot("skirmish_z40")
				_step = 3
				_wait = 0
		_:
			var k := _step - 3
			if k >= _models.size():
				print("PASS %s shots" % TASK_ID)
				return true
			if _wait == 1:
				# cinematic-style close-up (the rig stops at zoom 10): an own camera 4.6 m away, slightly to the side
				if _close_cam == null:
					_close_cam = Camera3D.new()
					_close_cam.fov = 40.0
					_level.add_child(_close_cam)
				var tgt := _models[k].global_position + Vector3(0, 1.35, 0)
				var eye := tgt + Vector3(1.3, 1.5, 4.2)
				_close_cam.global_transform = Transform3D(Basis.looking_at(tgt - eye), eye)
				_close_cam.current = true
			if _wait == 100 and k % 2 == 1:
				_models[k].call(&"play_cast", CASTS[SCENES.keys()[k]][1])   # Malrik / Ysolde: mid-cast (runes flare)
			if _wait >= 120:
				_shot("close_" + String(SCENES.keys()[k]))
				_step += 1
				_wait = 0
	return false


func _hide_ui(n: Node) -> void:
	for c: Node in n.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
		else:
			_hide_ui(c)


func _look(at: Vector3, zoom: float) -> void:
	var rig: Node = _level.get(&"camera_rig")
	if rig == null:
		return
	rig.call(&"fly_to", at, (rig as Node3D).rotation.y, zoom, 0.0)


func _shot(name_: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var img := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT, name_]
	img.save_png(path)
	print("shot ", ProjectSettings.globalize_path(path))

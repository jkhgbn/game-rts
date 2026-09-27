extends Node3D
## Preview of the combat effects (tasks 5.V4 / A.12): melee hits per kingdom, deaths per kingdom, hero deaths,
## arrows / bolts, building hits, level-up, item pickup, then a 100 v 100 stress brawl (zoom 40).
## RTS camera: pitch 55, fov 50.
## User args (after `--`):
##   --shots            save docs/art/screens/<prefix>_*.png and quit
##   --prefix=NAME      screenshot prefix (default polish_combat)
##   --stress-only      skip the showcase, only run the stress brawl
##   --novfx            no CombatVfx at all (stress baseline)
## Stress prints: avg frame ms (vsync off), GPU ms, CPU ms of the renderer, emitters, bursts skipped by LOD.

const STRESS_WARMUP := 1.5
const STRESS_SECONDS := 5.0

@export var zoom: float = 16.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3.ZERO

var vfx: Node3D
var _shots := false
var _prefix := "polish_combat"
var _stress_only := false
var _no_vfx := false
var _stage: Array[Node] = []
var _gpu_sum := 0.0
var _cpu_sum := 0.0
var _samples := 0
var _sampling := false

@onready var _cam: Camera3D = $Camera3D


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_shots = "--shots" in args
	_stress_only = "--stress-only" in args
	_no_vfx = "--novfx" in args
	for a in args:
		if a.begins_with("--prefix="):
			_prefix = a.substr(9)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_apply()
	if not _no_vfx:
		vfx = CombatVfx.new()
		vfx.name = "CombatVfx"
		add_child(vfx)
	_run()


func _process(_delta: float) -> void:
	if _sampling:
		var rid := get_viewport().get_viewport_rid()
		_gpu_sum += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		_cpu_sum += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		_samples += 1


func _unit(id: String, team: int, pos: Vector3) -> Unit:
	var u := Worker.make_unit(UnitType.find(id))
	u.team = team
	add_child(u)
	u.global_position = pos
	_stage.append(u)
	return u


func _wizard(path: String, team: int, pos: Vector3) -> Unit:
	var script := load(path) as GDScript
	if script == null:
		return null
	var w := script.new() as Unit
	w.team = team
	add_child(w)
	w.global_position = pos
	_stage.append(w)
	return w


func _tank(units: Array) -> void:
	for u: Unit in units:
		u.max_hp = 4000.0
		u.hp = 4000.0


func _clear() -> void:
	for n in _stage:
		if is_instance_valid(n):
			n.queue_free()
	_stage.clear()


func _run() -> void:
	await _wait(0.5)
	if not _stress_only:
		await _showcase()
	await _stress()
	if _shots:
		get_tree().quit()


func _showcase() -> void:
	# 1. Melee: Flame Guards vs Shades, then Rimeshields vs Thornlings, toe to toe.
	for pair in [["flame_guard", "shade", "melee_fs"], ["rimeshield", "thornling", "melee_in"]]:
		var a: Array[Unit] = []
		var b: Array[Unit] = []
		for i in 3:
			a.append(_unit(pair[0], Unit.Team.PLAYER, Vector3(-0.8, 0, -1.5 + i * 1.5)))
			b.append(_unit(pair[1], Unit.Team.ENEMY, Vector3(0.8, 0, -1.5 + i * 1.5)))
		_tank(a)
		_tank(b)
		for i in 3:
			a[i].command_attack(b[i])
			b[i].command_attack(a[i])
		await _wait(1.3)
		await _shot(pair[2])
		await _wait(0.37)
		await _shot(pair[2] + "_2")
		# Forced blows on both sides at once, so the shot catches the flash + sparks.
		for i in 3:
			a[i].attack_landed.emit(b[i], 10.0)
			b[i].attack_landed.emit(a[i], 10.0)
		await _wait(0.04)
		await _shot(pair[2] + "_hit")
		await _wait(0.1)
		await _shot(pair[2] + "_hit_2")
		_clear()
		await _wait(0.5)
	# 2. Deaths, one per kingdom in a row: Fire, Shadow, Ice, Nature (left to right).
	var ids := ["flame_guard", "shade", "rimeshield", "thornling"]
	var victims: Array[Unit] = []
	for i in 4:
		victims.append(_unit(ids[i], Unit.Team.PLAYER, Vector3(-4.5 + i * 3.0, 0, 0)))
	for u in victims:
		u.command_hold()
	await _wait(0.6)
	for u in victims:
		u.take_damage(99999.0, null)
	await _wait(0.1)
	await _shot("death_a")
	await _wait(0.3)
	await _shot("death_b")
	await _wait(0.5)
	await _shot("death_c")
	await _wait(1.0)
	_clear()
	# 3. Hero deaths: the four wizards.
	var paths := ["res://scripts/units/wizard.gd", "res://scripts/units/shadow_wizard.gd",
			"res://scripts/units/ice_wizard.gd", "res://scripts/units/nature_wizard.gd"]
	var heroes: Array[Unit] = []
	for i in 4:
		var w := _wizard(paths[i], Unit.Team.PLAYER if i % 2 == 0 else Unit.Team.ENEMY, Vector3(-4.5 + i * 3.0, 0, 0))
		if w:
			heroes.append(w)
	await _wait(0.8)
	for w in heroes:
		w.command_hold()
		w.take_damage(99999.0, null)
	await _wait(0.12)
	await _shot("hero_death")
	await _wait(0.35)
	await _shot("hero_death_2")
	await _wait(1.2)
	_clear()
	await _wait(0.4)
	# 4. Arrows / bolts: Ember Archers vs Nightbolts, then Shardcasters vs Burr Slingers, at 8 m.
	for pair in [["ember_archer", "nightbolt", "bolts_fs"], ["shardcaster", "burr_slinger", "bolts_in"]]:
		var arch: Array[Unit] = []
		var bolt: Array[Unit] = []
		for i in 3:
			arch.append(_unit(pair[0], Unit.Team.PLAYER, Vector3(-4.0, 0, -2.0 + i * 2.0)))
			bolt.append(_unit(pair[1], Unit.Team.ENEMY, Vector3(4.0, 0, -2.0 + i * 2.0)))
		_tank(arch)
		_tank(bolt)
		for i in 3:
			arch[i].command_attack(bolt[i])
			bolt[i].command_attack(arch[i])
		var n := 0
		for t in [1.6, 0.1, 0.12, 0.2]:
			await _wait(t)
			await _shot("%s_%d" % [pair[2], n])
			n += 1
		_clear()
		await _wait(0.5)
	# 5. Building hits: a stand-in wall (group "buildings", signal damaged) hit from two sides.
	var wall := _stand_in_building(Vector3(0, 0, -1.0))
	var hitter_f := _unit("flame_guard", Unit.Team.PLAYER, Vector3(-3.5, 0, 1.5))
	var hitter_s := _unit("grave_hound", Unit.Team.ENEMY, Vector3(3.5, 0, 1.5))
	for u: Unit in [hitter_f, hitter_s]:
		u.command_hold()
		u.attack_damage = 0.0
	await _wait(0.6)
	for i in 4:
		wall.emit_signal(&"damaged", 20.0, hitter_f)
		await _wait(0.08)
		wall.emit_signal(&"damaged", 20.0, hitter_s)
		await _wait(0.08)
	await _shot("building_hit")
	await _wait(0.25)
	await _shot("building_hit_2")
	await _wait(0.8)
	_clear()
	# 6. Level-up + item pickup.
	var vet := _unit("flame_guard", Unit.Team.PLAYER, Vector3(-2.0, 0, 0))
	var vet2 := _unit("shadow_knight", Unit.Team.ENEMY, Vector3(2.5, 0, 0))
	for u: Unit in [vet, vet2]:
		u.command_hold()
	await _wait(0.5)
	vet.add_xp(130)   # Unit.VETERANCY_XP[1] = 120
	vet2.add_xp(130)
	print("levels: ", vet.level, " ", vet2.level)
	await _wait(0.12)
	await _shot("levelup")
	await _wait(0.3)
	await _shot("levelup_2")
	await _wait(0.8)
	var items := ItemType.all_items()
	if not items.is_empty():
		var p := ItemPickup.spawn(items[0], Vector3(0, 0, 2.5), 1, self)
		_stage.append(p)
		await _wait(0.4)
		p.picked_up.emit(p, null, p.type)   # the preview has no wizard: fire the signal the game fires
		p.queue_free()
		await _wait(0.15)
		await _shot("pickup")
	await _wait(0.8)
	_clear()
	await _wait(0.5)


## 100 v 100, mixed melee and ranged of the four kingdoms, zoom 40.
func _stress() -> void:
	zoom = 40.0
	_apply()
	# Same Fire vs Shadow mix as the 5.V4 measure (8.7 ms), so the numbers compare; --mix=all adds Ice / Nature.
	var ids_a := ["flame_guard", "ember_archer", "cinder_hand", "blaze_rider"]
	var ids_b := ["shade", "nightbolt", "gloom_thrall", "shadow_knight"]
	if "--mix=all" in OS.get_cmdline_user_args():
		ids_a = ["flame_guard", "ember_archer", "rimeshield", "shardcaster"]
		ids_b = ["shade", "nightbolt", "thornling", "burr_slinger"]
	var left: Array[Unit] = []
	var right: Array[Unit] = []
	for i in 100:
		var row := i / 10
		var col := i % 10
		var ranged: bool = row % 4 == 1 or (row % 4 == 3 and ids_a[3] == "shardcaster")
		var gap := 4.0 if ranged else 0.75
		var z := -13.5 + col * 3.0
		var x := -18.0 + row * 4.0
		left.append(_unit(ids_a[row % 4], Unit.Team.PLAYER, Vector3(x - gap, 0, z)))
		right.append(_unit(ids_b[row % 4], Unit.Team.ENEMY, Vector3(x + gap, 0, z)))
	for i in 100:
		left[i].command_attack(right[i])
		right[i].command_attack(left[i])
	await _wait(STRESS_WARMUP)
	if "--deaths" in OS.get_cmdline_user_args():
		_kill_some(left + right)   # 6 deaths every 0.5 s while measuring (not awaited)
	var t0 := Time.get_ticks_usec()
	var f0 := Engine.get_process_frames()
	_sampling = true
	await _wait(STRESS_SECONDS * 0.5)
	await _shot("stress_z40")
	await _wait(STRESS_SECONDS * 0.5)
	_sampling = false
	var frames := Engine.get_process_frames() - f0
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / maxf(1.0, float(frames))
	var emitters := 0
	var visible_emitters := 0
	var extra := ""
	if vfx:
		for c in vfx.get_children():
			if c is GPUParticles3D:
				emitters += 1
				if (c as GPUParticles3D).visible:
					visible_emitters += 1
		if vfx.has_method(&"stats"):
			extra = str(vfx.call(&"stats"))
	var alive := 0
	for u in left + right:
		if is_instance_valid(u) and u.is_alive():
			alive += 1
	print("STRESS 200 units (%s): avg frame %.2f ms over %d frames, render gpu %.2f ms cpu %.2f ms, alive %d, emitters %d (visible now %d) %s" % [
			"no vfx" if _no_vfx else "vfx", ms, frames, _gpu_sum / maxf(1.0, _samples),
			_cpu_sum / maxf(1.0, _samples), alive, emitters, visible_emitters, extra])


func _kill_some(units: Array[Unit]) -> void:
	for step in int(STRESS_SECONDS / 0.5):
		await _wait(0.5)
		var n := 0
		for u in units:
			if n >= 6:
				break
			if is_instance_valid(u) and u.is_alive() and randf() < 0.1:
				u.take_damage(99999.0, null)
				n += 1


## A wall with the Building contract CombatVfx uses: group "buildings" + damaged(amount, attacker).
func _stand_in_building(pos: Vector3) -> Node3D:
	var b := StaticBody3D.new()
	b.add_user_signal("damaged", [{"name": "amount", "type": TYPE_FLOAT}, {"name": "attacker", "type": TYPE_OBJECT}])
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(4.0, 3.0, 3.0)
	m.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.26, 0.24)
	m.material_override = mat
	m.position.y = 1.5
	b.add_child(m)
	add_child(b)
	b.add_to_group(&"buildings")
	b.global_position = pos
	_stage.append(b)
	if vfx:
		vfx.call(&"watch" if vfx.has_method(&"watch") else &"_hook", b)
	return b


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(tag: String) -> void:
	if not _shots:
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/%s_%s.png" % [_prefix, tag]
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


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

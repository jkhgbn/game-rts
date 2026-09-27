extends Node3D
## Preview of the Nature effects (task 8.V5). Ysolde does not exist yet, so a stand-in wizard's SpellCaster emits
## her spell ids (spell_cast + spell_effect, exactly what SpellCaster will emit): Thornburst on 4 Shades (rooted by
## IceVfx), Wild Bloom on hurt guards (regen motes + `+` ticks), Call the Thicket + 3 stand-in Saplings (lifetime 4 s:
## sprout then wither), a Bloomtender-style heal support_cast (with IceVfx: pollen + `+` only; without: vine beam),
## a Bramble Spire stand-in pulsing its aura, then 120 regenerating units for the cost check. RTS camera (pitch 55,
## fov 50). Run windowed with `-- --shots` to save docs/art/screens/vfx_nature_*.png and quit; it prints fps /
## draw calls per shot and the live pooled effects at the end (leak check, expect 0).

@export var zoom: float = 18.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(-1.0, 0, 1.0)

var ysolde: Wizard
var seer: Unit
var guards: Array[Unit] = []
var foes: Array[Unit] = []
var crowd: Array[Unit] = []
var vfx: NatureVfx
var ice: IceVfx
var _shots := false

@onready var _cam: Camera3D = $Camera3D


func _ready() -> void:
	_shots = "--shots" in OS.get_cmdline_user_args()
	_apply()
	ice = IceVfx.new()
	ice.name = "IceVfx"
	add_child(ice)
	vfx = NatureVfx.new()
	vfx.name = "NatureVfx"
	add_child(vfx)
	ysolde = _spawn(IceWizard.new(), Unit.Team.PLAYER, Vector3(-6.5, 0.0, 4.5)) as Wizard
	(ysolde as IceWizard).ai_auto_cast = false
	for p: Vector3 in [Vector3(-3.6, 0, 2.2), Vector3(-2.0, 0, 3.4), Vector3(-4.2, 0, 4.0), Vector3(-2.6, 0, 1.2),
			Vector3(-1.2, 0, 2.0)]:
		var g := _spawn(Worker.make_unit(UnitType.find("rimeshield")), Unit.Team.PLAYER, p)
		guards.append(g)
	seer = _spawn(Worker.make_unit(UnitType.find("rime_seer")), Unit.Team.PLAYER, Vector3(-6.0, 0, 1.0))
	var seer_sc := seer.get_node_or_null(^"SupportCaster")
	if seer_sc:
		seer_sc.set_physics_process(false)   # no Ice shield autocasts in the shots: the preview emits heals itself
	for p: Vector3 in [Vector3(2.2, 0, -3.2), Vector3(3.6, 0, -2.2), Vector3(1.6, 0, -1.8), Vector3(3.0, 0, -0.9)]:
		foes.append(_spawn(Worker.make_unit(UnitType.find("shade")), Unit.Team.ENEMY, p))
	var spire_type := (BuildingType.find("ice_tower") as BuildingType).duplicate() as BuildingType
	spire_type.id = &"nature_tower"
	spire_type.faction = &"nature"
	spire_type.aura_radius = 8.0
	spire_type.aura_stats = {}
	var spire := Tower.new()
	spire.building_type = spire_type
	spire.team = Unit.Team.PLAYER
	add_child(spire)
	spire.global_position = Vector3(-16.0, 0.0, -9.0)
	if "--bursts" in OS.get_cmdline_user_args():
		_run_bursts()
	else:
		_run()


## Debug sheet: every pooled burst look side by side on bare ground (docs/art/screens/vfx_nature_bursts.png).
func _run_bursts() -> void:
	focus = Vector3(0.0, 0, 16.0)
	zoom = 16.0
	_apply()
	await _wait(0.5)
	var i := 0
	for look: StringName in NatureVfx.LOOKS:
		var p := Vector3(-8.0 + float(i % 5) * 4.0, 0.0, 13.0 + float(i / 5) * 5.0)
		vfx.call(&"_burst", look, p + Vector3.UP * 0.3, 1.0)
		i += 1
	await _wait(0.35)
	await _shot("vfx_nature_bursts")
	await _wait(0.5)
	await _shot("vfx_nature_bursts_late")
	if _shots:
		get_tree().quit()


func _spawn(u: Unit, team: int, pos: Vector3) -> Unit:
	u.team = team
	add_child(u)
	u.global_position = pos
	u.attack_damage = 0.0
	u.aggro_range = 0.0
	u.command_hold()
	return u


## What Ysolde's SpellCaster will emit for a cast.
func _cast(id: StringName, pos: Vector3) -> void:
	var sc: Node = ysolde.get_node(^"SpellCaster")
	sc.emit_signal(&"spell_cast", id)
	sc.emit_signal(&"spell_effect", id, pos)


func _hurt(u: Unit, ratio: float) -> void:
	u.set_idle_regen_pct(1.5)
	u.hp = u.max_hp * ratio


func _run() -> void:
	for g in guards:
		_hurt(g, 0.45)
	_hurt(ysolde, 0.6)
	await _wait(1.0)
	await _shot("vfx_nature_regen")
	# Thornburst on the Shades (the spell roots them: IceVfx draws the roots).
	_cast(&"thornburst", Vector3(2.6, 0, -2.0))
	for f in foes:
		f.apply_status(&"rooted", 1.5)
	await _wait(0.07)
	await _shot("vfx_nature_thornburst_erupt")
	await _wait(0.2)
	await _shot("vfx_nature_thornburst")
	await _wait(0.55)
	await _shot("vfx_nature_thornburst_crumble")
	await _wait(1.0)
	# Wild Bloom on the hurt guards.
	_cast(&"wild_bloom", Vector3(-2.8, 0, 2.6))
	var blooms: Array = vfx.get(&"_blooms")
	print("wild bloom ticks: ", blooms.size(), " heal(s) running, ",
			(blooms[0]["units"] as Array).size() if not blooms.is_empty() else 0, " units get a `+` per tick")
	await _wait(0.25)
	await _shot("vfx_nature_wild_bloom")
	await _wait(1.3)
	await _shot("vfx_nature_wild_bloom_ticks")
	# Call the Thicket: the spell emits, then spawns 3 Saplings on a ring r 1.2.
	var at := Vector3(5.5, 0, 3.0)
	_cast(&"call_the_thicket", at)
	var saps: Array[Unit] = []
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.4
		var s := Worker.make_unit(UnitType.find("cinder_hand"))
		s.set_lifetime(4.0)
		saps.append(_spawn(s, Unit.Team.PLAYER, at + Vector3(cos(a), 0.0, sin(a)) * 1.2))
	await _wait(0.15)
	await _shot("vfx_nature_thicket")
	await _wait(0.6)
	await _shot("vfx_nature_thicket_grown")
	# Bloomtender-style heal autocast (with IceVfx in the scene: pollen + `+` only, IceVfx draws the beam).
	var sc: Node = seer.get_node_or_null(^"SupportCaster")
	if sc and sc.has_signal(&"support_cast"):
		sc.emit_signal(&"support_cast", seer, guards[3], &"heal")
	await _wait(0.06)
	await _shot("vfx_nature_heal_with_ice")
	# Without IceVfx: NatureVfx's own vine beam.
	ice.queue_free()
	await _wait(1.1)
	if sc and sc.has_signal(&"support_cast"):
		sc.emit_signal(&"support_cast", seer, guards[3], &"heal")
	await _wait(0.07)
	await _shot("vfx_nature_heal_beam")
	# Saplings wither (lifetime 4 s from their spawn).
	focus = Vector3(5.0, 0, 3.0)
	zoom = 12.0
	_apply()
	await _wait(2.4)
	await _shot("vfx_nature_wither")
	# Close-up of Thornburst + regen from the lowest zoom.
	focus = Vector3(1.0, 0, -0.5)
	zoom = 11.0
	_apply()
	for g in guards:
		_hurt(g, 0.5)
	_cast(&"thornburst", Vector3(2.6, 0, -2.0))
	await _wait(0.25)
	await _shot("vfx_nature_thornburst_close")
	# Bramble Spire aura pulse.
	focus = Vector3(-16.0, 0, -8.0)
	zoom = 30.0
	_apply()
	await _wait(4.2)
	for i in 30:
		await get_tree().process_frame
		if _any_ring_scale() > 4.0:
			break
	await _shot("vfx_nature_spire_aura")
	# Cost check: 120 more units regenerating + 2 Wild Blooms + 2 Thornbursts.
	for i in 120:
		var u := _spawn(Worker.make_unit(UnitType.find("rimeshield" if i % 2 == 0 else "cinder_hand")),
				Unit.Team.PLAYER, Vector3(-18.0 + float(i % 12) * 2.2, 0.0, -6.0 - float(i / 12) * 2.2))
		crowd.append(u)
	await _wait(0.2)
	for u in crowd:
		_hurt(u, 0.4)
	focus = Vector3(-6.0, 0, -14.0)
	zoom = 40.0
	_apply()
	await _wait(0.6)
	_cast(&"wild_bloom", Vector3(-10.0, 0, -12.0))
	_cast(&"thornburst", Vector3(0.0, 0, -18.0))
	await _wait(0.3)
	await _shot("vfx_nature_mass_z40")
	zoom = 55.0
	_apply()
	await _wait(0.3)
	await _shot("vfx_nature_mass_z55")
	# CPU cost of NatureVfx (_process + polls) with ~130 regenerating units: average over 120 frames, on and off.
	zoom = 28.0
	_apply()
	await _wait(0.5)
	await _shot("vfx_nature_mass_regen_z28")
	# Timed directly (TIME_PROCESS is too noisy with other Godot runs on the machine): the poll alone, then
	# NatureVfx._process called by hand for 120 frames (it includes a poll every 0.25 s).
	var t_a := Time.get_ticks_usec()
	vfx.call(&"_poll")
	var poll_us := Time.get_ticks_usec() - t_a
	vfx.set_process(false)
	var worst := 0
	var sum := 0
	for i in 120:
		await get_tree().process_frame
		var t0 := Time.get_ticks_usec()
		vfx.call(&"_process", get_process_delta_time())
		var dt := Time.get_ticks_usec() - t0
		sum += dt
		worst = maxi(worst, dt)
	vfx.set_process(true)
	print("NatureVfx cost with ", (vfx.get_node(^"RegenMotes") as MultiMeshInstance3D).multimesh.visible_instance_count / 2,
			" regenerating units in view: _process avg ", sum / 120, " us, worst ", worst, " us (poll ", poll_us, " us)")
	# Leak check: everything fades out.
	for u in crowd + guards:
		u.hp = u.max_hp
	vfx.spire_pulse = false
	await _wait(7.0)
	var live := 0
	for c in vfx.get_children():
		if (c is MeshInstance3D or c.name.begins_with("Thornburst")) and (c as Node3D).visible:
			live += 1
	print("nature fx live: ", live, " (expect 0) regen motes shown: ",
			(vfx.get_node(^"RegenMotes") as MultiMeshInstance3D).multimesh.visible_instance_count, " (expect 0)")
	if _shots:
		get_tree().quit()


func _any_ring_scale() -> float:
	var best := 0.0
	for c in vfx.get_children():
		var m := c as MeshInstance3D
		if m and m.visible and m.mesh is PlaneMesh and m.material_override is ShaderMaterial \
				and (m.material_override as ShaderMaterial).shader.resource_path.ends_with("vfx_ground.gdshader"):
			best = maxf(best, m.scale.x)
	return best


func _avg_process_ms(frames: int) -> float:
	var total := 0.0
	for i in frames:
		await get_tree().process_frame
		total += Performance.get_monitor(Performance.TIME_PROCESS)
	return total / float(frames) * 1000.0


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(tag: String) -> void:
	if not _shots:
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/%s.png" % tag
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

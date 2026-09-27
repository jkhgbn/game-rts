extends Node3D
## Preview of the Ice effects (task 7.V5): Torvald casts Rime Bolt / Flash Freeze / Rime Aegis, a Rime Seer
## shields a guard, a Shade is rooted, then 80 chilled / frozen units for the cost check. RTS camera
## (pitch 55, fov 50). Run windowed with `-- --shots` to save docs/art/screens/vfx_ice_*.png and quit; it
## prints fps / draw calls per shot and how many auras are still live at the end (leak check, expect 0).

@export var zoom: float = 18.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(-1.5, 0, 1.0)

var torvald: Wizard
var seer: Unit
var guards: Array[Unit] = []
var foes: Array[Unit] = []
var crowd: Array[Unit] = []
var vfx: IceVfx
var _shots := false

@onready var _cam: Camera3D = $Camera3D


func _ready() -> void:
	_shots = "--shots" in OS.get_cmdline_user_args()
	_apply()
	vfx = IceVfx.new()
	vfx.name = "IceVfx"
	add_child(vfx)
	torvald = _spawn(IceWizard.new(), Unit.Team.PLAYER, Vector3(-5.0, 0.0, 3.0))
	(torvald as IceWizard).ai_auto_cast = false
	for p: Vector3 in [Vector3(-7.0, 0, 5.0), Vector3(-5.2, 0, 5.8), Vector3(-3.4, 0, 5.0)]:
		guards.append(_spawn(Worker.make_unit(UnitType.find("rimeshield")), Unit.Team.PLAYER, p))
	seer = _spawn(Worker.make_unit(UnitType.find("rime_seer")), Unit.Team.PLAYER, Vector3(-7.5, 0, 2.0))
	for p: Vector3 in [Vector3(0.6, 0, -2.6), Vector3(1.9, 0, -1.3), Vector3(-0.3, 0, -1.0), Vector3(1.2, 0, -0.2)]:
		foes.append(_spawn(Worker.make_unit(UnitType.find("shade")), Unit.Team.ENEMY, p))
	foes.append(_spawn(Worker.make_unit(UnitType.find("flame_guard")), Unit.Team.ENEMY, Vector3(3.5, 0, 2.5)))
	torvald.add_xp(1200)
	torvald.spell_points = 6
	for c: StringName in torvald.spell_ids():
		if torvald.spell_rank(c) == 0:
			var r := torvald.learn_spell(c)
			if r != "":
				print("learn ", c, ": ", r)
	_run()


func _spawn(u: Unit, team: int, pos: Vector3) -> Unit:
	u.team = team
	add_child(u)
	u.global_position = pos
	u.attack_damage = 0.0
	u.aggro_range = 0.0
	u.command_hold()
	return u


func _cast(id: StringName, target: Variant) -> void:
	torvald.mana = 300.0
	var r: String = torvald.command_cast(id, target)
	if r != "":
		print("cast ", id, " refused: ", r)


func _run() -> void:
	await _wait(1.0)
	_cast(&"rime_bolt", foes[2])
	await _wait(0.18)
	await _shot("vfx_ice_rime_bolt")
	await _wait(0.12)
	await _shot("vfx_ice_bolt_hit")
	await _wait(0.6)
	await _shot("vfx_ice_chill")
	_cast(&"flash_freeze", Vector3(0.9, 0.0, -1.4))
	await _wait(0.12)
	await _shot("vfx_ice_flash_freeze")
	await _wait(0.6)
	await _shot("vfx_ice_frozen")
	foes[4].apply_status(&"rooted", 6.0)
	await _wait(0.5)
	_cast(&"rime_aegis", null)
	await _wait(0.12)
	await _shot("vfx_ice_aegis_cast")
	await _wait(0.5)
	# Rime Seer autocast: shield a guard through its SupportCaster signal (the timer would take 12 s).
	var sc: Node = seer.get_node_or_null(^"SupportCaster")
	if sc and sc.has_signal(&"support_cast"):
		guards[0].add_shield(60.0, 6.0)
		sc.emit_signal(&"support_cast", seer, guards[0], &"shield")
		sc.emit_signal(&"support_cast", seer, torvald, &"heal")   # Nature look check (0.06 s dedupe: next line)
	await _wait(0.08)
	if sc and sc.has_signal(&"support_cast"):
		sc.emit_signal(&"support_cast", seer, torvald, &"heal")
	await _wait(0.04)
	await _shot("vfx_ice_support_beam")
	await _wait(0.4)
	await _shot("vfx_ice_aegis_domes")
	focus = Vector3(3.0, 0, -1.0)
	zoom = 11.0
	_apply()
	await _wait(0.1)
	await _shot("vfx_ice_rooted_close")
	# Cost check: 80 more units, half chilled, a quarter frozen.
	for i in 80:
		var u := _spawn(Worker.make_unit(UnitType.find("shade" if i % 2 == 0 else "flame_guard")), Unit.Team.ENEMY,
				Vector3(-14.0 + float(i % 10) * 2.2, 0.0, -10.0 - float(i / 10) * 2.2))
		crowd.append(u)
	await _wait(0.2)
	for i in crowd.size():
		crowd[i].apply_status(&"chill" if i % 4 != 0 else &"frozen", 4.0)
	focus = Vector3(-4.0, 0, -12.0)
	zoom = 40.0
	_apply()
	await _wait(0.8)
	await _shot("vfx_ice_mass_z40")
	zoom = 55.0
	_apply()
	await _wait(0.2)
	await _shot("vfx_ice_mass_z55")
	await _wait(9.0)
	var live := 0
	for c in vfx.get_children():
		if c.name.begins_with("Aura_") and (c as Node3D).visible:
			live += 1
	var overlays := 0
	for u: Variant in crowd + foes:
		if not is_instance_valid(u):
			continue
		for g in (u as Node).find_children("*", "MeshInstance3D", true, false):
			if (g as MeshInstance3D).material_overlay != null:
				overlays += 1
	print("ice auras live: ", live, " (expect 0 once shields end: guards/torvald domes may remain) overlays left: ",
			overlays, " (expect 0)")
	if _shots:
		get_tree().quit()


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

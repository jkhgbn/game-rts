extends Node3D
## Preview of the spell effects (task 3.U2): Vessa and Malrik cast their 6 spells on dummies, seen from
## the RTS camera (pitch 55, fov 50). Run windowed with `-- --shots` to save docs/art/screens/vfx_*.png
## and quit; it also prints how many effect nodes are left at the end (leak check).

@export var zoom: float = 20.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(0, 0, 1.5)

var vessa: Wizard
var malrik: Wizard
var guards: Array[Unit] = []
var foes: Array[Unit] = []
var vfx: SpellVfx
var _shots := false

@onready var _cam: Camera3D = $Camera3D


func _ready() -> void:
	_shots = "--shots" in OS.get_cmdline_user_args()
	_apply()
	vfx = SpellVfx.new()
	vfx.name = "SpellVfx"
	add_child(vfx)
	vessa = _spawn(Wizard.new(), Unit.Team.PLAYER, Vector3(-5.0, 0.0, 3.0))
	malrik = _spawn(ShadowWizard.new(), Unit.Team.ENEMY, Vector3(3.0, 0.0, -2.0))
	for p: Vector3 in [Vector3(-7.0, 0, 5.5), Vector3(-5.0, 0, 6.2), Vector3(-3.2, 0, 5.2), Vector3(-6.5, 0, 1.2)]:
		guards.append(_spawn(Worker.make_unit(UnitType.find("flame_guard")), Unit.Team.PLAYER, p))
	for p: Vector3 in [Vector3(0.5, 0, -3.0), Vector3(1.8, 0, -1.2), Vector3(-0.5, 0, -1.0)]:
		foes.append(_spawn(Worker.make_unit(UnitType.find("shade")), Unit.Team.ENEMY, p))
	for w: Wizard in [vessa, malrik]:
		w.add_xp(1200)   # level 5: enough to learn every spell
		w.spell_points = 6
		for c: StringName in w.spell_ids():
			if w.spell_rank(c) == 0:
				var r := w.learn_spell(c)
				if r != "":
					print("learn ", c, ": ", r)
	malrik.mana = 0.0
	_run()


func _spawn(u: Unit, team: int, pos: Vector3) -> Unit:
	u.team = team
	add_child(u)
	u.global_position = pos
	u.attack_damage = 0.0
	u.aggro_range = 0.0
	u.command_hold()
	return u


func _process(_delta: float) -> void:
	if malrik and not _casting:
		malrik.mana = 0.0   # keep his own AI from casting in the preview


var _casting := false


func _cast(w: Wizard, id: StringName, target: Variant) -> void:
	_casting = true
	w.mana = 200.0
	var r: String = w.command_cast(id, target)
	if r != "":
		print("cast ", id, " refused: ", r)
	w.mana = 0.0 if w == malrik else 200.0
	_casting = false


func _run() -> void:
	await _wait(1.0)
	_cast(vessa, &"fireball", Vector3(0.8, 0.0, -1.8))
	await _wait(0.22)
	await _shot("vfx_fireball_travel")
	await _wait(0.35)
	await _shot("vfx_fireball_impact")
	await _wait(1.2)
	_cast(vessa, &"ember_step", Vector3(-2.0, 0.0, 1.0))
	await _wait(0.08)
	await _shot("vfx_ember_step")
	await _wait(1.0)
	await _shot("vfx_ember_scorch")
	await _wait(0.5)
	_cast(vessa, &"kindle", null)
	await _wait(0.2)
	await _shot("vfx_kindle")
	await _wait(1.0)
	await _shot("vfx_haste")
	_cast(malrik, &"shadow_lance", guards[2])
	await _wait(0.2)
	await _shot("vfx_shadow_lance")
	await _wait(1.0)
	_cast(malrik, &"soul_siphon", Vector3(-5.0, 0.0, 5.5))
	await _wait(1.05)
	await _shot("vfx_soul_siphon")
	await _wait(0.3)
	_cast(malrik, &"umbral_shroud", null)
	await _wait(0.7)
	await _shot("vfx_umbral_shroud")
	zoom = 40.0
	_apply()
	await _wait(0.1)
	await _shot("vfx_overview_z40")
	zoom = 20.0
	_apply()
	await _wait(9.0)
	var shown := 0   # SpellVfx pools its effects (task A.13): idle pieces stay as hidden children
	for c in vfx.get_children():
		if c is Node3D and (c as Node3D).visible:
			shown += 1
	print("vfx pieces still visible: ", shown, " (expect 0)")
	print("shroud still on: ", malrik.has_status(&"shroud"), " body transparency ok: ", _body_opaque(malrik))
	var auras := 0
	for u: Node in [vessa, malrik] + guards:
		for c in u.get_children():
			if c.has_meta(&"spell_vfx"):
				auras += 1
	print("auras left: ", auras, " (expect 0)")
	if _shots:
		get_tree().quit()


func _body_opaque(u: Node3D) -> bool:
	for c in u.get_children():
		if c.get_class() == "Node3D":
			for g in c.get_children():
				if g is GeometryInstance3D and (g as GeometryInstance3D).transparency > 0.01:
					return false
	return true


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

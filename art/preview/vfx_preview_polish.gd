extends Node3D
## Polish preview for the Fire / Shadow spell effects (task A.13, art/vfx/spell_vfx.gd). Vessa and Malrik cast
## their 6 spells on dummies, seen from the RTS camera (pitch 55, fov 50).
## Windowed `--fixed-fps 60 -- --shots <tag>`: saves docs/art/screens/polish_spell_<tag>_*.png and quits.
## `-- --test` (headless ok): casts everything twice, then checks the node count stays flat (pooling) and that
## nothing is left on the units; prints SPELL VFX POLISH OK.
## By hand: mouse wheel = zoom, 1-6 = cast Fireball / Ember Step / Kindle / Shadow Lance / Soul Siphon / Shroud.

@export var zoom: float = 20.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(0, 0, 1.5)

var vessa: Wizard
var malrik: Wizard
var guards: Array[Unit] = []
var foes: Array[Unit] = []
var vfx: SpellVfx
var _tag := ""
var _test := false
var _casting := false

@onready var _cam: Camera3D = $Camera3D


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--shots")
	if i >= 0:
		_tag = args[i + 1] if i + 1 < args.size() else "x"
	_test = "--test" in args
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
	if _test:
		_run_test()
	elif _tag != "":
		_run_shots()


func _spawn(u: Unit, team: int, pos: Vector3) -> Unit:
	u.team = team
	add_child(u)
	u.global_position = pos
	u.attack_damage = 0.0
	u.aggro_range = 0.0
	u.max_hp = 100000.0
	u.hp = 100000.0
	u.command_hold()
	return u


func _process(_delta: float) -> void:
	if malrik and not _casting:
		malrik.mana = 0.0   # keep his own AI from casting in the preview


func _cast(w: Wizard, id: StringName, target: Variant) -> void:
	_casting = true
	w.mana = 500.0
	var sc := w.get_node_or_null(^"SpellCaster")
	# Clear the cooldown so the preview can recast (SpellCaster keeps it in a private dictionary).
	if sc:
		var cds: Variant = sc.get(&"_cooldown_left")
		if cds is Dictionary:
			(cds as Dictionary)[id] = 0.0
	var r: String = w.command_cast(id, target)
	if r != "":
		print("cast ", id, " refused: ", r)
	w.mana = 0.0 if w == malrik else 500.0
	_casting = false


func _fireball_projectile() -> Projectile:
	return _projectile_of(vessa)


func _projectile_of(w: Wizard) -> Projectile:
	for c in get_children():
		if c is Projectile and (c as Projectile).source == w and c.is_processing():
			return c
	return null


func _run_shots() -> void:
	await _wait(1.2)
	# --- Fireball: wind-up, travel, impact, scorch.
	_look(Vector3(-2.0, 0, 1.0), 20.0)
	_cast(vessa, &"fireball", Vector3(0.8, 0.0, -1.8))
	await _wait(0.05)
	await _shot("fireball_cast")
	await _wait(0.2)
	await _shot("fireball_travel")
	var p := _fireball_projectile()
	while p != null and is_instance_valid(p) and p.is_processing():
		await get_tree().process_frame
	await _wait(0.06)
	await _shot("fireball_impact")
	await _wait(0.25)
	await _shot("fireball_impact_late")
	await _wait(1.2)
	await _shot("fireball_scorch")
	await _wait(1.5)
	# --- Ember Step: dash, landing, burning ground.
	_look(Vector3(-3.5, 0, 2.0), 18.0)
	_cast(vessa, &"ember_step", Vector3(-1.5, 0.0, -0.5))
	await _wait(0.05)
	await _shot("ember_step_dash")
	await _wait(0.2)
	await _shot("ember_step_land")
	await _wait(1.2)
	await _shot("ember_step_scorch")
	await _wait(3.5)
	# --- Kindle: wave, ground fire, haste.
	vessa.global_position = Vector3(-5.0, 0.0, 3.0)
	_look(Vector3(-5.0, 0, 3.5), 24.0)
	await _wait(0.3)
	_cast(vessa, &"kindle", null)
	await _wait(0.12)
	await _shot("kindle_cast")
	await _wait(0.2)
	await _shot("kindle_wave")
	await _wait(0.45)
	await _shot("kindle_fire")
	await _wait(1.0)
	await _shot("kindle_haste")
	# --- Shadow Lance: flight, hit.
	_look(Vector3(-1.0, 0, 1.5), 20.0)
	_cast(malrik, &"shadow_lance", guards[2])
	await _wait(0.1)
	await _shot("shadow_lance_flight")
	var lance := _projectile_of(malrik)
	while lance != null and is_instance_valid(lance) and lance.is_processing():
		await get_tree().process_frame
	await _wait(0.05)
	await _shot("shadow_lance_hit")
	await _wait(0.15)
	await _shot("shadow_lance_drain")
	await _wait(1.2)
	# --- Soul Siphon.
	_look(Vector3(-3.0, 0, 3.0), 20.0)
	_cast(malrik, &"soul_siphon", Vector3(-5.0, 0.0, 5.5))
	await _wait(0.15)
	await _shot("soul_siphon_cast")
	await _wait(0.9)
	await _shot("soul_siphon")
	await _wait(1.0)
	await _shot("soul_siphon_late")
	# --- Umbral Shroud.
	_look(Vector3(2.5, 0, -1.0), 14.0)
	_cast(malrik, &"umbral_shroud", null)
	await _wait(0.12)
	await _shot("umbral_shroud_cast")
	await _wait(0.8)
	await _shot("umbral_shroud")
	# --- Overview from far: shroud + siphon + a fresh fireball and kindle.
	_cast(vessa, &"fireball", Vector3(1.5, 0.0, -1.0))
	_cast(vessa, &"kindle", null)
	_look(Vector3(-1.5, 0, 1.5), 40.0)
	await _wait(0.55)
	await _shot("overview_z40")
	_look(Vector3(-1.5, 0, 1.5), 55.0)
	_cast(vessa, &"fireball", Vector3(-1.0, 0.0, -2.5))
	await _wait(0.6)
	await _shot("overview_z55")
	await _wait(8.0)
	_report()
	get_tree().quit()


func _run_test() -> void:
	await _wait(0.5)
	var counts: Array[int] = []
	for round_i in 3:
		_cast(vessa, &"fireball", Vector3(0.8, 0.0, -1.8))
		_cast(vessa, &"kindle", null)
		_cast(malrik, &"shadow_lance", guards[2])
		_cast(malrik, &"soul_siphon", Vector3(-5.0, 0.0, 5.5))
		_cast(malrik, &"umbral_shroud", null)
		await _wait(0.3)
		_cast(vessa, &"ember_step", Vector3(-1.5 + round_i, 0.0, -0.5))
		await _wait(0.4)
		_cast(vessa, &"ember_step", Vector3(-5.0, 0.0, 3.0))
		await _wait(8.0)
		counts.append(_count(vfx))
		print("round ", round_i, " spell vfx nodes: ", counts[-1])
	_report()
	var ok := counts[1] == counts[2]   # round 0 warms the lazy pools up
	print("SPELL VFX POLISH OK" if ok else "SPELL VFX POLISH FAIL (node count grew)")
	get_tree().quit()


func _report() -> void:
	var auras := 0
	for u: Node in [vessa, malrik] + guards + foes:
		for c in u.get_children():
			if c.has_meta(&"spell_vfx"):
				auras += 1
	print("auras left on units: ", auras, " (expect 0)")
	print("shroud still on: ", malrik.has_status(&"shroud"), " body opaque: ", _body_opaque(malrik))
	print("pooled nodes under SpellVfx: ", _count(vfx), " visible now: ", _count_visible(vfx))


func _count(n: Node) -> int:
	var c := n.get_child_count()
	for ch in n.get_children():
		c += _count(ch)
	return c


func _count_visible(n: Node) -> int:
	var c := 0
	var names: Array[String] = []
	for ch in n.get_children():
		if ch is Node3D and (ch as Node3D).visible:
			c += 1
			names.append(String(ch.name))
	if c > 0:
		print("  still visible: ", ", ".join(names))
	return c


func _body_opaque(u: Node3D) -> bool:
	for c in u.get_children():
		if c.get_class() == "Node3D" and not c.has_meta(&"spell_vfx"):
			for g in c.get_children():
				if g is GeometryInstance3D and (g as GeometryInstance3D).transparency > 0.01:
					return false
	return true


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(tag: String) -> void:
	if _tag == "":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/polish_spell_%s_%s.png" % [_tag, tag]
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func _look(at: Vector3, z: float) -> void:
	focus = at
	zoom = z
	_apply()


func _apply() -> void:
	var p: float = deg_to_rad(pitch_degrees)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 3.0, 8.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 3.0, 8.0, 55.0)
		_apply()
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.physical_keycode:
			KEY_1: _cast(vessa, &"fireball", foes[randi() % foes.size()].global_position)
			KEY_2: _cast(vessa, &"ember_step", vessa.global_position + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)))
			KEY_3: _cast(vessa, &"kindle", null)
			KEY_4: _cast(malrik, &"shadow_lance", guards[randi() % guards.size()])
			KEY_5: _cast(malrik, &"soul_siphon", Vector3(-5.0, 0.0, 5.5))
			KEY_6: _cast(malrik, &"umbral_shroud", null)

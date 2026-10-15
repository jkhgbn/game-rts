extends SceneTree
## G-F art review 2 item 1: lighter HP bars (scripts/units/unit.gd _build_hp_bar / _update_hp_bar, scripts/units/fx/).
## Checks: thinner bars, width by unit size (small < soldier < heavy; heroes / champions >= 1 m), a light edge instead of
## the black frame, fade to ~35 % FADE_HOLD s after the last hit (heroes stronger), full again on a new hit, on hover and
## on selection, the team colour rule (ramp only on own units), shared materials (no per-unit material).
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_gf_hp_bars.gd --fixed-fps 60 --quit-after 1500

const TASK_ID := "gf_hp_bars"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const TIMEOUT_FRAMES := 1400

var world: Node3D
var failures: Array[String] = []
var frame := 0
var _step := 0
var _hit_ms := 0

var _small: Unit
var _soldier: Unit
var _soldier2: Unit
var _heavy: Unit
var _foe: Unit
var _wiz: Wizard
var _ch: Champion


func _initialize() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(ground)
	var nav := NavigationMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	nav.create_from_mesh(plane)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	world.add_child(region)


func _process(_delta: float) -> bool:
	frame += 1
	if frame > TIMEOUT_FRAMES:
		failures.append("timed out at step %d" % _step)
		return _finish()
	match _step:
		0:
			if frame == 3:
				_setup()
				_step = 1
		1:
			if frame == 6:
				_check_static()
				_hit()
				_step = 2
		2:
			# Real time: UnitFx.now() is wall-clock based (headless frames run faster than real time).
			OS.delay_msec(10)
			if Time.get_ticks_msec() - _hit_ms > int((UnitFx.FADE_HOLD + UnitFx.FADE_TIME) * 1000.0) + 300:
				_check_faded()
				return _finish()
	return false


func _finish() -> bool:
	if failures.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(failures)])
	return true


func _setup() -> void:
	_small = _spawn(&"cinder_hand", P, Vector3(-4.0, 0.0, 0.0))
	_soldier = _spawn(&"flame_guard", P, Vector3(0.0, 0.0, 0.0))
	_soldier2 = _spawn(&"flame_guard", P, Vector3(2.0, 0.0, 0.0))
	_heavy = _spawn(&"ironhide_tusker", P, Vector3(8.0, 0.0, 0.0))
	_foe = _spawn(&"flame_guard", E, Vector3(70.0, 0.0, 70.0))   # far: no fight
	_wiz = Wizard.new()
	_wiz.team = P
	world.add_child(_wiz)
	_wiz.global_position = Vector3(-8.0, 0.0, 6.0)
	_wiz.command_stop()
	_ch = ChampionType.find(&"oathwall").create_champion(0)
	_ch.team = P
	world.add_child(_ch)
	_ch.global_position = Vector3(0.0, 0.0, 12.0)
	_ch.command_stop()
	var brain := _ch.get_node_or_null(^"Brain")
	if brain:
		brain.process_mode = Node.PROCESS_MODE_DISABLED


func _check_static() -> void:
	# Thinner, sized by the unit.
	var ws := _bar_size(_small)
	var wf := _bar_size(_soldier)
	var wh := _bar_size(_heavy)
	_check(wf.y <= 0.16 * 0.65 + 0.001, "soldier bar ~40 %% thinner (%.3f m)" % wf.y)
	_check(ws.x < wf.x + 0.001 and ws.x <= 0.85, "small unit bar short (%.2f m vs soldier %.2f)" % [ws.x, wf.x])
	_check(wf.x < 1.0, "soldier bar narrower than the old 1 m minimum (%.2f)" % wf.x)
	_check(wh.x > wf.x + 0.3 and wh.x >= 1.4, "heavy bar wider (%.2f m, radius %.2f)" % [wh.x, _heavy.radius])
	_check(is_equal_approx(wh.x, _heavy.hp_bar_width()), "hp_bar_width() = the quad width")
	_check(_bar_size(_wiz).x >= 1.0 and _bar_size(_wiz).y > wf.y, "wizard bar stronger (%s)" % str(_bar_size(_wiz)))
	_check(_bar_size(_ch).x >= 1.0, "champion bar >= 1 m (%.2f)" % _bar_size(_ch).x)
	var bs: Variant = _bar_of(_heavy).get_instance_shader_parameter(&"bar_size")
	_check(bs is Vector2 and is_equal_approx((bs as Vector2).x, wh.x), "bar_size instance param follows the width")
	# Light edge, not the black frame; fading on units only (buildings keep fade_min 1).
	var sm := _mat(_soldier)
	var fsz: Vector2 = sm.get_shader_parameter(&"frame_size")
	var fcol: Color = sm.get_shader_parameter(&"frame_color")
	_check(fsz.x <= 0.015, "soldier edge thin (%.3f m)" % fsz.x)
	_check(fcol.a < 0.75, "soldier edge light (alpha %.2f)" % fcol.a)
	_near(float(sm.get_shader_parameter(&"fade_min")), Unit.HP_BAR_FADE_MIN, "soldier bar fades to 35 %")
	_check(_soldier.hp_bar_frame_color().is_equal_approx(Color.BLACK), "soldier frame colour stays black (style)")
	var bmat := UnitFx.bar_material(Color.RED, false, {"color": Color.BLACK, "frame": 0.05}, 0)
	_near(float(bmat.get_shader_parameter(&"fade_min")), 1.0, "building-style bar never fades")
	_check(float(_mat(_ch).get_shader_parameter(&"fade_min")) > Unit.HP_BAR_FADE_MIN, "champion fades less")
	_check(float(_mat(_wiz).get_shader_parameter(&"fade_min")) > Unit.HP_BAR_FADE_MIN, "wizard fades less")
	_check(_ch.has_gold_hp_frame(), "champion keeps the gold frame")
	# Team colour rule (decisions.md 2026-10-15): ramp only on own units, team colour on others.
	_near(float(sm.get_shader_parameter(&"ramp_k")), 1.0, "own bar ramps green -> red")
	var fm := _mat(_foe)
	_near(float(fm.get_shader_parameter(&"ramp_k")), 0.0, "enemy bar has no ramp")
	var fc: Color = fm.get_shader_parameter(&"fill_color")
	_check(fc.is_equal_approx(Unit.team_hp_color(E)), "enemy bar keeps the team colour")
	# Shared materials, no per-unit material.
	_check(_mat(_soldier) == _mat(_soldier2) and _mat(_soldier) == _mat(_small), "own soldiers share one bar material")
	_check(_bar_of(_soldier).mesh == _bar_of(_soldier2).mesh, "same-size bars share one quad")


func _hit() -> void:
	_foe.take_damage(30.0, null)
	_soldier.take_damage(30.0, null)
	_ch.take_damage(_ch.max_hp * 0.3, null)
	_wiz.take_damage(30.0, null)
	_hit_ms = Time.get_ticks_msec()
	_check(_bar_of(_foe).visible, "hit bar visible")
	_near(_foe.hp_bar_opacity(), 1.0, "full opacity right after a hit")


func _check_faded() -> void:
	var now := UnitFx.now()
	var fx_now := float(_mat(_foe).get_shader_parameter(&"fx_now"))
	_check(fx_now > now - 0.5 and fx_now >= _t0(_foe) + UnitFx.FADE_HOLD, "clock kept fx_now ticking through the fade (%.2f, t0 %.2f)" % [fx_now, _t0(_foe)])
	_near(_foe.hp_bar_opacity(), Unit.HP_BAR_FADE_MIN, "enemy bar faded to 35 % after the hit")
	_near(_soldier.hp_bar_opacity(), Unit.HP_BAR_FADE_MIN, "own bar faded to 35 %")
	_near(_ch.hp_bar_opacity(), Unit.HP_BAR_FADE_MIN_HERO, "champion bar faded less")
	_near(_wiz.hp_bar_opacity(), Unit.HP_BAR_FADE_MIN_HERO, "wizard bar faded less")
	_check(_bar_of(_foe).visible, "faded bar still drawn (damaged)")
	# Selection: full; deselected: faded again.
	_foe.set_selected(true)
	_near(_foe.hp_bar_opacity(), 1.0, "selected = full")
	_near(float(_bar_of(_foe).get_instance_shader_parameter(&"focus")), 1.0, "focus instance param on selection")
	_foe.set_selected(false)
	_near(_foe.hp_bar_opacity(), Unit.HP_BAR_FADE_MIN, "deselected = faded again")
	_near(float(_bar_of(_foe).get_instance_shader_parameter(&"focus")), 0.0, "focus param off")
	# Hover: full.
	_foe.set_hp_bar_hover(true)
	_near(_foe.hp_bar_opacity(), 1.0, "hovered = full")
	_foe.set_hp_bar_hover(false)
	_near(_foe.hp_bar_opacity(), Unit.HP_BAR_FADE_MIN, "unhovered = faded")
	# A new hit: full again.
	var t0 := _t0(_foe)
	_foe.take_damage(10.0, null)
	_check(_t0(_foe) > t0, "new hit restarts the fade clock")
	_near(_foe.hp_bar_opacity(), 1.0, "new hit = full again")
	# The curve.
	_near(UnitFx.bar_fade(10.0, 11.0, false, 0.35), 1.0, "fade holds 1 s after the hit")
	_near(UnitFx.bar_fade(10.0, 13.0, false, 0.35), 0.35, "faded 3 s after the hit")
	_near(UnitFx.bar_fade(10.0, 13.0, true, 0.35), 1.0, "focus keeps it full")
	_near(UnitFx.bar_fade(10.0, 13.0, false, 1.0), 1.0, "fade_min 1 never fades")


func _spawn(id: StringName, team: int, pos: Vector3) -> Unit:
	var t := load("res://data/units/%s.tres" % id) as UnitType
	var u := t.create_unit()
	u.team = team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _bar_of(u: Unit) -> MeshInstance3D:
	return u.get_node_or_null(^"HPBar") as MeshInstance3D


func _bar_size(u: Unit) -> Vector2:
	var b := _bar_of(u)
	if b == null:
		failures.append("no HPBar on %s" % u.name)
		return Vector2.ZERO
	return (b.mesh as QuadMesh).size


func _mat(u: Unit) -> ShaderMaterial:
	return _bar_of(u).material_override as ShaderMaterial


func _t0(u: Unit) -> float:
	return float(_bar_of(u).get_instance_shader_parameter(&"trail_t0"))


func _check(cond: bool, what: String) -> void:
	if not cond:
		failures.append(what)


func _near(a: float, b: float, what: String) -> void:
	if absf(a - b) > 0.02:
		failures.append("%s (%.3f vs %.3f)" % [what, a, b])

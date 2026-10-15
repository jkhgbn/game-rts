extends SceneTree
## Graphics week G-D: selection ring + HP bar (scripts/units/fx/). Checks shared materials, instance uniforms, the
## recent-damage trail param on a hit, Low = plain ring, High = dashes on own units, champion gold frame, ticks.
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_gd_rings.gd --fixed-fps 60 --quit-after 1200
## Shots (windowed):  tools\godot_run.ps1 --path . -s tests/test_gd_rings.gd --quit-after 3000 '--' --gfx=high --shots=after
##   -> docs/art/lab/gd_rings/<tag>_<gfx>_z30.png / _z10.png
## Fps (windowed):    ... '--' --gfx=high --fps   (200-unit clash, prints "FPS avg=..")

const TASK_ID := "gd_rings"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const GOLD := Color(1.0, 0.82, 0.3)
const OUT_DIR := "res://docs/art/lab/gd_rings/"

var world: Node3D
var camera: Camera3D
var failures: Array[String] = []
var frame := 0
var mode := "test"
var tag := "after"
var gfx := "low"
var units: Array[Unit] = []
var _fps_samples: Array[float] = []


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shots"):
			mode = "shots"
			if a.contains("="):
				tag = a.get_slice("=", 1)
		elif a == "--fps":
			mode = "fps"
		elif a.begins_with("--gfx="):
			gfx = a.get_slice("=", 1)
	_build_world()


func _build_world() -> void:
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
	if mode == "test":
		return
	var gm := MeshInstance3D.new()
	gm.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.33, 0.4, 0.22)
	gmat.roughness = 0.95
	gm.material_override = gmat
	world.add_child(gm)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.shadow_enabled = true
	world.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.55, 0.65)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.58, 0.62)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.add_child(env)
	camera = Camera3D.new()
	camera.fov = 45.0
	world.add_child(camera)
	camera.current = true


func _process(_delta: float) -> bool:
	frame += 1
	match mode:
		"shots":
			return _shots_step()
		"fps":
			return _fps_step()
	return _test_step()


# ---------------------------------------------------------------- headless checks

func _test_step() -> bool:
	if frame == 3:
		_setup_test()
	elif frame == 8:
		_check_after_hit()
	elif frame == 10:
		if failures.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(failures)])
		return true
	return false


var _a: Unit
var _b: Unit
var _foe: Unit
var _big: Unit
var _ch: Champion


func _setup_test() -> void:
	_a = _spawn(&"flame_guard", P, Vector3(0.0, 0.0, 0.0))
	_b = _spawn(&"flame_guard", P, Vector3(3.0, 0.0, 0.0))
	_foe = _spawn(&"shade", E, Vector3(6.0, 0.0, 0.0))
	_big = _spawn(&"flame_guard", P, Vector3(-6.0, 0.0, 0.0), 500.0)
	_ch = ChampionType.find(&"oathwall").create_champion(0)
	_ch.team = P
	world.add_child(_ch)
	_ch.global_position = Vector3(0.0, 0.0, 8.0)
	_ch.command_stop()
	var brain := _ch.get_node_or_null(^"Brain")
	if brain:
		brain.process_mode = Node.PROCESS_MODE_DISABLED
	# Shared materials: same team / style = the same material object.
	var ra := _ring_of(_a)
	var rb := _ring_of(_b)
	_check(ra != null and rb != null, "rings exist")
	if ra == null or rb == null:
		return
	_check(ra.material_override == rb.material_override, "ring material shared between two soldiers")
	_check(ra.material_override is ShaderMaterial, "ring uses a ShaderMaterial")
	_check(ra.mesh is PlaneMesh and ra.mesh == rb.mesh, "ring is one shared ground quad")
	_check(_ring_of(_foe).material_override != ra.material_override, "enemy ring has its own (red) material")
	_check(_bar_of(_a).material_override == _bar_of(_b).material_override, "HP bar material shared")
	_check(_bar_of(_a).material_override != _bar_of(_ch).material_override, "champion bar material differs")
	_near(float(_iparam(ra, &"ring_radius")), _a.radius, "ring_radius instance param = radius")
	var bs: Variant = _iparam(_bar_of(_a), &"bar_size")
	_check(bs is Vector2 and is_equal_approx((bs as Vector2).x, (_bar_of(_a).mesh as QuadMesh).size.x), "bar_size param")
	var shared := {}
	for u: Unit in [_a, _b, _foe, _big, _ch]:
		shared[_ring_of(u).material_override] = true
		shared[_bar_of(u).material_override] = true
	_check(shared.size() <= 6, "5 units use %d materials (max 6)" % shared.size())
	# Low (headless) = plain ring; High = dashes on own units only.
	var low := ra.material_override as ShaderMaterial
	_check(int(low.get_shader_parameter(&"gfx_tier")) == 0, "Low ring gfx_tier 0")
	_near(float(low.get_shader_parameter(&"dash_count")), 0.0, "Low ring has no dashes")
	var high_own := UnitFx.ring_material(Unit.team_color(P), true, 3)
	var high_foe := UnitFx.ring_material(Unit.team_color(E), false, 2)
	_near(float(high_own.get_shader_parameter(&"dash_count")), 4.0, "High own ring: 4 dashes")
	_near(float(high_foe.get_shader_parameter(&"dash_count")), 0.0, "High enemy ring: no dashes")
	_check(high_own == UnitFx.ring_material(Unit.team_color(P), true, 2), "High / Ultra share one ring material")
	# Champion gold frame.
	_check(_ch.hp_bar_frame_color().is_equal_approx(GOLD), "champion frame colour gold")
	var cm := _bar_of(_ch).material_override as ShaderMaterial
	var fc: Variant = cm.get_shader_parameter(&"frame_color")
	_check(fc is Color and (fc as Color).is_equal_approx(GOLD), "champion bar shader frame_color gold")
	_check(_a.hp_bar_frame_color().is_equal_approx(Color.BLACK), "soldier frame black")
	# Ticks: big units only.
	_check(float(_iparam(_bar_of(_big), &"tick_step")) > 0.0, "500 HP unit gets 100 HP ticks")
	_near(float(_iparam(_bar_of(_a), &"tick_step")), 0.0, "flame guard gets no ticks")
	var bar_mat := _bar_of(_a).material_override as ShaderMaterial
	_check(bar_mat.shader != null and bar_mat.shader.code.contains("depth_test_disabled"), "HP bar drawn on top")
	# A max_hp gain without heal lowers the fill but starts no damage trail.
	var t0_before: Variant = _iparam(_bar_of(_big), &"trail_t0")
	_big.add_modifier(&"test:gd_rings", {"max_hp": 200.0}, false)
	_check(_iparam(_bar_of(_big), &"trail_t0") == t0_before, "max_hp gain without heal starts no trail")
	_check(float(_iparam(_bar_of(_big), &"fill")) < 0.99, "max_hp gain lowered the fill (%s)" % str(_iparam(_bar_of(_big), &"fill")))
	_near(_big.max_hp, 700.0, "500 HP unit + 200 = 700 max HP")
	# Visibility rules unchanged.
	_check(not _bar_of(_a).visible, "full-HP soldier bar hidden")
	_a.set_selected(true)
	_check(_ring_of(_a).visible and _bar_of(_a).visible, "selected: ring + bar shown")
	_a.set_selected(false)
	if Unit.team_ring_shown_at(_a.fx_tier()):   # G-E: deselected = back to the faint always-on team ring (style 1)
		var tm := _ring_of(_a).material_override as ShaderMaterial
		_check(_ring_of(_a).visible and int(tm.get_shader_parameter(&"ring_style")) == 1, "deselected: team ring style")
	else:
		_check(not _ring_of(_a).visible, "deselected: ring hidden")
	# A hit: the trail starts at the old fill.
	_near(float(_iparam(_bar_of(_b), &"fill")), 1.0, "fill 1 at full HP")
	_b.take_damage(40.0, null)


func _check_after_hit() -> void:
	var bar := _bar_of(_b)
	var f := _b.hp / _b.max_hp
	_near(float(_iparam(bar, &"fill")), f, "fill param follows HP")
	_near(float(_iparam(bar, &"trail_from")), 1.0, "trail_from = fill before the hit")
	var t0 := float(_iparam(bar, &"trail_t0"))
	_check(t0 >= 0.0 and absf(UnitFx.now() - t0) < 2.0, "trail_t0 set on the hit (%.2f)" % t0)
	_check(bar.visible, "damaged bar visible")
	var clock := root.get_node_or_null(^"UnitFxClock")
	_check(clock != null, "UnitFx clock node runs during the trail")
	var fx_now := float((bar.material_override as ShaderMaterial).get_shader_parameter(&"fx_now"))
	_check(fx_now >= t0 - 0.01, "shared material fx_now ticks (%.2f vs t0 %.2f)" % [fx_now, t0])
	# trail_value: hold, then drain to the fill.
	_near(UnitFx.trail_value(1.0, 0.5, 10.0, 10.1), 1.0, "trail holds")
	_near(UnitFx.trail_value(1.0, 0.5, 10.0, 12.0), 0.5, "trail drained")
	# A second hit chains from the visible trail, not from the new fill.
	_b.take_damage(10.0, null)
	_near(float(_iparam(bar, &"trail_from")), 1.0, "chained hit keeps the undrained trail")


func _spawn(id: StringName, team: int, pos: Vector3, hp_override := 0.0) -> Unit:
	var t := load("res://data/units/%s.tres" % id) as UnitType
	var u := t.create_unit()
	if hp_override > 0.0:
		u.max_hp = hp_override
	u.team = team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	units.append(u)
	return u


func _ring_of(u: Unit) -> MeshInstance3D:
	return u.get_node_or_null(^"SelectionRing") as MeshInstance3D


func _bar_of(u: Unit) -> MeshInstance3D:
	return u.get_node_or_null(^"HPBar") as MeshInstance3D


func _iparam(gi: GeometryInstance3D, pname: StringName) -> Variant:
	var v: Variant = gi.get_instance_shader_parameter(pname)
	if v == null:
		v = gi.get("instance_shader_parameters/" + String(pname))
	return v


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func _near(a: float, b: float, what: String) -> void:
	if absf(a - b) > 0.01:
		failures.append("%s (%.3f vs %.3f)" % [what, a, b])


# ---------------------------------------------------------------- windowed shots

func _shots_step() -> bool:
	if frame == 3:
		_setup_scene()
	elif frame == 60:
		_hit_some()
	elif frame == 66:
		_aim(30.0)
	elif frame == 70:
		_save("z30")
	elif frame == 75:
		_hit_some()
	elif frame == 78:
		_aim(10.0)
	elif frame == 82:
		_save("z10")
	elif frame == 84:
		print("SHOTS %s done" % tag)
		return true
	return false


func _setup_scene() -> void:
	for i in 12:   # a selected group of own soldiers
		var u := _spawn(&"flame_guard", P, Vector3(-3.0 + (i % 4) * 1.6, 0.0, -1.0 + (i / 4) * 1.6))
		u.set_selected(true)
	for i in 6:    # damaged enemies, one selected
		var e := _spawn(&"shade", E, Vector3(-3.0 + i * 1.5, 0.0, -5.0))
		e.take_damage(e.max_hp * (0.15 + 0.13 * i), null)
		if i == 2:
			e.set_selected(true)
	var big := _spawn(&"rime_colossus", P, Vector3(5.0, 0.0, 1.0))
	big.take_damage(170.0, null)
	big.set_selected(true)
	var ch := ChampionType.find(&"oathwall").create_champion(0)
	ch.team = P
	world.add_child(ch)
	ch.global_position = Vector3(5.0, 0.0, -3.5)
	ch.command_stop()
	var brain := ch.get_node_or_null(^"Brain")
	if brain:
		brain.process_mode = Node.PROCESS_MODE_DISABLED
	ch.take_damage(ch.max_hp * 0.3, null)
	for u: Unit in units:
		u.attack_damage = 0.0
		u.aggro_range = 0.0
	_aim(30.0)


func _hit_some() -> void:
	for i in range(0, units.size(), 3):
		var u := units[i]
		if u.is_alive() and u.hp > u.max_hp * 0.4:
			u.take_damage(u.max_hp * 0.12, null)


func _aim(dist: float) -> void:
	var focus := Vector3(1.0, 0.5, -1.5)
	var dir := Vector3(0.0, sin(deg_to_rad(55.0)), cos(deg_to_rad(55.0)))
	camera.global_position = focus + dir * dist
	camera.look_at(focus, Vector3.UP)


func _save(zoom: String) -> void:
	var img := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(OUT_DIR + "%s_%s_%s.png" % [tag, gfx, zoom])
	img.save_png(path)
	print("SHOT ", path)


# ---------------------------------------------------------------- windowed fps (200-unit clash)

func _fps_step() -> bool:
	if frame == 3:
		for i in 100:
			var a := _spawn(&"flame_guard", P, Vector3(-8.0 + (i % 10) * 1.6, 0.0, -2.0 - (i / 10) * 1.6))
			a.set_selected(true)
			var b := _spawn(&"shade", E, Vector3(-8.0 + (i % 10) * 1.6, 0.0, 6.0 + (i / 10) * 1.6))
			b.set_selected(i % 10 == 0)
		for u: Unit in units:
			u.command_attack_move(Vector3(u.global_position.x, 0.0, 2.0))
		camera.global_position = Vector3(0.0, 26.0, 22.0)
		camera.look_at(Vector3(0.0, 0.0, 2.0), Vector3.UP)
	elif frame > 120 and frame <= 720:
		_fps_samples.append(Engine.get_frames_per_second())
	elif frame > 720:
		var s := 0.0
		for v: float in _fps_samples:
			s += v
		var alive := 0
		for u: Unit in units:
			if is_instance_valid(u) and u.is_alive():
				alive += 1
		print("FPS avg=%.1f min=%.1f tag=%s gfx=%s alive=%d" % [s / maxf(1.0, _fps_samples.size()), _fps_samples.min(), tag, gfx, alive])
		return true
	return false

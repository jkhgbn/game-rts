extends SceneTree
## G-E team read (docs/art/ge_review.md item 2): mirror matches give the second side of a kingdom its alternate
## palette (Unit.KINGDOM_ALT_COLORS, Unit.team_display_color / kingdom_color_for), 2v2 seats sharing a kingdom too;
## every living unit carries a faint always-on team ring (its "SelectionRing" quad, idle style) in its relation colour (one shared material per colour /
## tier, style 1, instance alpha), hidden while selected or dead, and hidden by the fog with its unit.
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_ge_team_read.gd --fixed-fps 60 --quit-after 2400 [-- --gfx=high]
## (headless = Low: the team ring is off below Medium, Unit.TEAM_RING_MIN_TIER; '--gfx=high' runs the ring checks)

const TASK_ID := "ge_team_read"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const A := 3   # Unit.Team.ALLY
const E2 := 4  # Unit.Team.ENEMY_2

var world: Node3D
var fog: Node
var failures: Array[String] = []
var frame := 0
var _near_foe: Unit
var _far_foe: Unit
var _own: Unit
var _ring_on := false


func _initialize() -> void:
	_build_world(&"fire", &"fire")


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		_test_palettes()
		_test_rings()
		_setup_fog()
	if frame == 40:
		_check_fog()
		_finish()
		return true
	return false


# A bare level whose script names the kingdoms the way Skirmish does (player_kingdom / enemy_kingdom, seat_kingdom).
func _build_world(pk: StringName, ek: StringName) -> void:
	var s := GDScript.new()
	s.source_code = "extends Node3D\nvar player_kingdom := &\"%s\"\nvar enemy_kingdom := &\"%s\"\nvar seats := {}\n" % [pk, ek] \
			+ "func seat_kingdom(t: int) -> Variant:\n\treturn seats.get(t, null)\n"
	s.reload()
	world = Node3D.new()
	world.set_script(s)
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


func _test_palettes() -> void:
	var fire: Color = Unit.KINGDOM_COLORS[&"fire"]
	var fire_alt: Color = Unit.KINGDOM_ALT_COLORS[&"fire"]
	_check(not fire.is_equal_approx(fire_alt), "fire alt differs from fire")
	for k: StringName in Unit.KINGDOM_COLORS:
		_check(Unit.KINGDOM_ALT_COLORS.has(k), "alt palette for %s" % k)
	# Mirror Fire vs Fire.
	var a := _spawn(&"flame_guard", P, Vector3(0, 0, 0))
	var b := _spawn(&"flame_guard", E, Vector3(3, 0, 0))
	_check(a.team_kingdom_color().is_equal_approx(fire), "mirror: the player keeps the Fire colour")
	_check(b.team_kingdom_color().is_equal_approx(fire_alt), "mirror: the enemy wears the Fire alt colour (%s)" % b.team_kingdom_color())
	_check(Unit.team_display_color(P).is_equal_approx(fire), "team_display_color(P) = fire")
	_check(Unit.team_display_color(E).is_equal_approx(fire_alt), "team_display_color(E) = fire alt")
	_check(Unit.team_display_color(2).is_equal_approx(Unit.team_color(2)), "neutral display colour = team_color")
	# Not a mirror: Fire vs Shadow, both main.
	world.set(&"enemy_kingdom", &"shadow")
	_check(Unit.team_display_color(E).is_equal_approx(Unit.KINGDOM_COLORS[&"shadow"]), "Fire vs Shadow: enemy = shadow main")
	_check(not Unit.uses_alt_palette(E, &"shadow"), "Fire vs Shadow: no alt palette")
	# A Fire-faction unit on the Shadow team facing a Fire player: alt (the player plays Fire).
	_check(Unit.kingdom_color_for(E, &"fire").is_equal_approx(fire_alt), "a fire-faction unit facing a fire player = alt")
	_check(Unit.kingdom_color_for(E, &"ice").is_equal_approx(Unit.KINGDOM_COLORS[&"ice"]), "ice on the enemy = ice main")
	# 2v2: P fire + A fire vs E shadow + E2 shadow.
	world.set(&"seats", {P: &"fire", A: &"fire", E: &"shadow", E2: &"shadow"})
	_check(Unit.team_display_color(A).is_equal_approx(fire_alt), "2v2: the ally sharing the player's kingdom = alt")
	_check(Unit.team_display_color(E).is_equal_approx(Unit.KINGDOM_COLORS[&"shadow"]), "2v2: enemy = shadow main")
	_check(Unit.team_display_color(E2).is_equal_approx(Unit.KINGDOM_ALT_COLORS[&"shadow"]), "2v2: second shadow seat = alt")
	world.set(&"seats", {})
	world.set(&"enemy_kingdom", &"fire")
	a.queue_free()
	b.queue_free()


func _test_rings() -> void:
	var a := _spawn(&"flame_guard", P, Vector3(-4, 0, -4))
	var b := _spawn(&"flame_guard", P, Vector3(-6, 0, -4))
	var c := _spawn(&"shade", P, Vector3(-8, 0, -4))
	var foe := _spawn(&"flame_guard", E, Vector3(-4, 0, -8))
	var ra := _team_ring(a)
	var rb := _team_ring(b)
	var rc := _team_ring(c)
	var rf := _team_ring(foe)
	_check(ra != null and rb != null and rc != null and rf != null, "every unit has its ring")
	if ra == null or rf == null or rc == null:
		return
	_check(ra.get_parent() == a, "the ring is a child of its unit (hides with it)")
	_ring_on = Unit.team_ring_shown_at(a.fx_tier())
	print("ge_team_read: tier %d, team ring %s" % [a.fx_tier(), "on" if _ring_on else "off (Low)"])
	if not _ring_on:
		_check(not ra.visible and not rf.visible, "Low: no idle team ring")
		a.set_selected(true)
		_check(ra.visible, "Low: the selection ring still shows")
		a.set_selected(false)
		_check(not ra.visible, "Low: deselected = hidden")
		var lm := UnitFx.team_ring_material(Unit.team_color(P), 0)
		_check(int(lm.get_shader_parameter(&"ring_style")) == 1 and lm == UnitFx.team_ring_material(Unit.team_color(P), 1),
				"team ring material style 1, cached")
		return
	_check(ra.visible and rf.visible, "idle team rings show")
	_check(ra.material_override == rb.material_override and ra.material_override == rc.material_override,
			"one shared team ring material for every own unit")
	_check(rf.material_override != ra.material_override, "the enemy team ring has its own (red) material")
	_check(ra.mesh == rb.mesh, "team rings share the ground quad")
	var mat := ra.material_override as ShaderMaterial
	_check(mat != null and int(mat.get_shader_parameter(&"ring_style")) == 1, "team ring material style 1 (idle team)")
	_check(UnitFx.ring_material(Unit.team_color(P), true, 0) != mat, "team ring style differs from the selection ring material")
	var col: Variant = mat.get_shader_parameter(&"ring_color")
	_check(col is Color and (col as Color).is_equal_approx(Unit.team_color(P)), "own team ring = the player's relation colour")
	var fcol: Variant = (rf.material_override as ShaderMaterial).get_shader_parameter(&"ring_color")
	_check(fcol is Color and (fcol as Color).is_equal_approx(Unit.team_color(E)), "enemy team ring = red relation colour")
	_check(UnitFx.team_ring_material(Unit.team_color(P), a.fx_tier()) == mat, "team_ring_material is cached")
	_check(UnitFx.team_ring_material(Unit.team_color(P), 3) == UnitFx.team_ring_material(Unit.team_color(P), 2),
			"High / Ultra share one team ring material")
	var alpha: Variant = ra.get_instance_shader_parameter(&"ring_alpha")
	_check(alpha != null and is_equal_approx(float(alpha), Unit.TEAM_RING_ALPHA), "ring_alpha instance uniform = TEAM_RING_ALPHA (%s)" % str(alpha))
	var before := UnitFx.material_count()
	for i in 20:
		_spawn(&"flame_guard", P, Vector3(-20.0 + float(i), 0, 20))
	_check(UnitFx.material_count() == before, "20 more units add no material (%d -> %d)" % [before, UnitFx.material_count()])
	a.set_selected(true)
	var sm := ra.material_override as ShaderMaterial
	_check(ra.visible and int(sm.get_shader_parameter(&"ring_style")) == 0, "selected: the selection look replaces the team ring")
	_check(is_equal_approx(float(ra.get_instance_shader_parameter(&"ring_alpha")), 1.0), "selected: ring_alpha 1")
	a.set_selected(false)
	_check(ra.visible and ra.material_override == mat, "deselected: the team ring is back")
	_check(a.get_node_or_null(^"TeamRing") == null, "no extra node for the team ring")
	b.die()
	_check(not rb.visible, "dead: no team ring")
	# A team switch recolours it.
	c.team = E
	_check(rc.material_override == rf.material_override, "team switch recolours the team ring")


func _setup_fog() -> void:
	fog = FogOfWar.new()
	world.add_child(fog)
	_own = _spawn(&"flame_guard", P, Vector3(-40, 0, -40))
	_near_foe = _spawn(&"flame_guard", E, Vector3(-38, 0, -40))
	_far_foe = _spawn(&"flame_guard", E, Vector3(45, 0, 45))
	_near_foe.command_hold()
	_far_foe.command_hold()


func _check_fog() -> void:
	var near_r := _team_ring(_near_foe)
	var far_r := _team_ring(_far_foe)
	_check(near_r != null and near_r.is_visible_in_tree() == _ring_on, "an enemy in sight shows its team ring (tier >= Medium)")
	_check(_near_foe.visible, "the enemy in sight is shown by the fog")
	_check(not _far_foe.visible, "the fog hides the far enemy")
	_check(far_r != null and not far_r.is_visible_in_tree(), "an enemy in the fog hides its team ring")
	_check(_team_ring(_own).is_visible_in_tree() == _ring_on, "own team ring visible (tier >= Medium)")


func _spawn(id: StringName, team: int, pos: Vector3) -> Unit:
	var t := load("res://data/units/%s.tres" % id) as UnitType
	var u := t.create_unit()
	u.team = team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _team_ring(u: Unit) -> MeshInstance3D:
	return u.get_node_or_null(^"SelectionRing") as MeshInstance3D


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func _finish() -> void:
	if failures.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(failures)])

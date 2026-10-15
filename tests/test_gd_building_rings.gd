extends SceneTree
## G-D buildings: ring + HP bar through UnitFx (shared materials, instance uniforms), never copied into fog ghosts,
## bar visibility rules unchanged, construction progress still on the bar.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gd_building_rings.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "gd_building_rings"

var main: Node
var _wait := 0
var _frame := 0
var _site: Building
var _bar: Building
var _errors: Array[String] = []


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_frame += 1
	if _frame == 1:
		_setup()
	elif _frame == 5:
		_check()
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)


func _setup() -> void:
	var keep := _player_keep()
	var grid: BuildGrid = main.get(&"build_grid")
	var bt := BuildingType.find(&"fire_barracks")
	_bar = grid.spawn_complete(bt, keep.global_position + Vector3(18, 0, 0), Unit.Team.PLAYER)
	_site = grid.spawn_site(bt, keep.global_position + Vector3(-18, 0, 0), Unit.Team.PLAYER)


func _player_keep() -> Building:
	for n in get_nodes_in_group(&"buildings"):
		if n is Keep and int((n as Building).team) == Unit.Team.PLAYER:
			return n
	return null


func _check() -> void:
	var keep := _player_keep()
	var kr: MeshInstance3D = keep.get(&"_ring")
	var kb: MeshInstance3D = keep.get(&"_hp_bar")
	var br: MeshInstance3D = _bar.get(&"_ring")
	var bb: MeshInstance3D = _bar.get(&"_hp_bar")
	# Shared materials: the UnitFx shaders, one material for two buildings of a team.
	var rm := kr.material_override as ShaderMaterial
	var bm := kb.material_override as ShaderMaterial
	_expect(rm != null and rm.shader == UnitFx.ring_shader(), "ring is not the UnitFx ring shader")
	_expect(bm != null and bm.shader == UnitFx.bar_shader(), "bar is not the UnitFx bar shader")
	_expect(br.material_override == rm, "two player buildings do not share the ring material")
	_expect(bb.material_override == bm, "two player buildings do not share the bar material")
	var s := keep.building_type.size_m()
	var rr := float(kr.get_instance_shader_parameter(&"ring_radius"))
	_expect(absf(rr + 0.26 - (s.length() * 0.5 + 0.3)) < 0.01, "ring band not at the footprint diagonal (%.2f)" % rr)
	_expect(is_equal_approx(float(kb.get_instance_shader_parameter(&"tick_step")), 250.0 / keep.max_hp),
			"keep bar ticks are not 250 HP")
	# Fog ghosts never get the ring / bar.
	keep.set_selected(true)
	_expect(kr.visible and kb.visible, "selected keep: ring / bar hidden")
	var visual: Node = keep.get(&"_visual")
	_expect(not visual.is_ancestor_of(kr) and not visual.is_ancestor_of(kb), "ring / bar under _visual (ghost source)")
	var ghost := keep.make_ghost(StandardMaterial3D.new())
	for c in ghost.get_children():
		var mi := c as MeshInstance3D
		if mi and (mi.mesh == kr.mesh or mi.mesh == kb.mesh):
			_expect(false, "ring / bar copied into the fog ghost")
	ghost.free()
	keep.set_selected(false)
	_expect(not kr.visible and not kb.visible, "deselected full keep: ring / bar still shown")
	# Damage shows the bar and starts the trail; the shared material is untouched.
	var fill_before := float((bm.get_shader_parameter(&"fill_color") as Color).r)
	_bar.take_damage(_bar.max_hp * 0.4)
	_expect(bb.visible, "damaged barracks: bar hidden")
	_expect(absf(float(bb.get_instance_shader_parameter(&"fill")) - 0.6) < 0.01, "damaged fill not 0.6")
	_expect(absf(float(bb.get_instance_shader_parameter(&"trail_from")) - 1.0) < 0.01, "no recent-damage trail")
	_expect(bm.get_shader_parameter(&"fill") == null, "a per-building value was written on the shared material")
	_expect(float(bm.get_shader_parameter(&"fill_color").r) == fill_before, "shared fill colour changed")
	# Construction site: bar shown, fill = the site's HP (grows with the progress).
	var sb: MeshInstance3D = _site.get(&"_hp_bar")
	_expect(not _site.is_constructed() and sb.visible, "site bar hidden")
	var site_mat := sb.material_override as ShaderMaterial
	_expect(site_mat != bm and float(site_mat.get_shader_parameter(&"ramp_k")) == 0.0, "site bar uses the damage ramp")
	_site.load_snapshot({"progress": 0.5}, {})
	_site.heal(_site.max_hp * 0.3)
	_expect(absf(float(sb.get_instance_shader_parameter(&"fill")) - _site.hp / _site.max_hp) < 0.01,
			"site bar does not show its HP / progress")
	_expect(is_equal_approx(_site.construction_progress(), 0.5), "construction_progress changed")
	_site.load_snapshot({"progress": 1.0}, {})
	_expect(_site.is_constructed() and sb.material_override == bm, "finished site did not take the building bar")
	# Destroyed: bar and ring hidden.
	_bar.set_selected(true)
	_bar.take_damage(_bar.max_hp * 2.0)
	_expect(not bb.visible and not br.visible, "destroyed barracks still shows its ring / bar")
	# Enemy buildings: another shared ring material (red), not the player's.
	for n in get_nodes_in_group(&"buildings"):
		var e := n as Building
		if e and int(e.team) == Unit.Team.ENEMY:
			_expect((e.get(&"_ring") as MeshInstance3D).material_override != rm, "enemy ring shares the player's material")
			break

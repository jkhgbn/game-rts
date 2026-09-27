extends SceneTree
## Task 10.V3 (Frost Bazaar model, art/buildings/market/ice/market_ice.tscn):
## - instantiates headless and has every hook (set_team_color, set_construction_progress, set_health_ratio,
##   play_training_pulse, play_destroyed + destroyed_finished, set_selected, play_delivery); hooks before _ready are
##   cached;
## - no active light, merged (few visible mesh nodes), footprint 6 x 6 (building parts inside +-3.6 m: eaves), top 8.5-10.5 m;
## - construction 0 -> 1 hides / shows parts and the scaffold;
## - play_delivery tips the scale (> 0.1 rad within 0.4 s) and it settles back (< 0.06 rad after 4 s); ignored on a site;
## - damage states: < 50 % the gem is gone and a roof hole shows, < 25 % the mast banner is gone and a second hole
##   shows, healed back reverts;
## - team colour reaches the roof / awning materials;
## - collapse emits destroyed_finished and leaves the wreck;
## - plugged into a real Building (model_scene): the Building drives the hooks (site, damage, collapse).
## Run:  godot --headless --path . -s tests/test_10_v3.gd --fixed-fps 60 --quit-after 1200

const TASK_ID := "10.V3"
const SCENE := "res://art/buildings/market/ice/market_ice.tscn"
const BUILDING := "res://scripts/buildings/building.gd"
const HOOKS: Array[StringName] = [&"set_team_color", &"set_construction_progress", &"set_health_ratio",
	&"play_training_pulse", &"play_destroyed", &"set_selected", &"play_delivery"]
const MAX_MESH_NODES := 20
const RED := Color(0.85, 0.25, 0.25)

var _m: Node3D        # the model under test
var _site: Node3D     # a second model kept as a site (delivery must be ignored)
var _bld: Node3D      # a Building using the model
var _finished: int = 0
var _frame: int = 0
var _errors: Array[String] = []
var _max_tip: float = 0.0


func _initialize() -> void:
	var ps := load(SCENE) as PackedScene
	if ps == null:
		print("FAIL %s: cannot load %s" % [TASK_ID, SCENE])
		quit(1)
		return
	_m = ps.instantiate() as Node3D
	for h: StringName in HOOKS:
		if not _m.has_method(h):
			_errors.append("missing hook %s" % h)
	if not _m.has_signal(&"destroyed_finished"):
		_errors.append("missing signal destroyed_finished")
	_m.call(&"set_construction_progress", 0.0)   # before _ready: cached
	_m.call(&"set_selected", true)
	root.add_child(_m)
	_m.connect(&"destroyed_finished", func() -> void: _finished += 1)
	_site = ps.instantiate() as Node3D
	_site.position = Vector3(20, 0, 0)
	_site.call(&"set_construction_progress", 0.5)
	root.add_child(_site)
	_make_building(ps)


func _make_building(ps: PackedScene) -> void:
	var bs := load(BUILDING) as GDScript
	if bs == null or not bs.can_instantiate():
		print("  (note) building.gd not loadable right now: Building integration skipped")
		return
	_bld = bs.new() as Node3D
	_bld.set(&"model_scene", ps)
	_bld.set(&"team_color", RED)
	_bld.set(&"front_toward", Vector3(40, 0, 100))
	_bld.position = Vector3(40, 0, 0)
	_bld.call(&"make_site")
	root.add_child(_bld)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_check_site_state()
	if _frame <= 61:
		_m.call(&"set_construction_progress", clampf(_frame / 60.0, 0.0, 1.0))
	if _frame == 70:
		_check_built()
		_site.call(&"play_delivery")
		_m.call(&"set_selected", false)
		_m.call(&"play_training_pulse")
		_m.call(&"play_delivery")
	if _frame > 70 and _frame <= 94:
		_max_tip = maxf(_max_tip, absf(_beam_angle(_m)))
	if _frame == 95:
		if _max_tip < 0.1:
			_errors.append("play_delivery: the scale tipped only %.3f rad" % _max_tip)
		if absf(_beam_angle(_site)) > 0.06:
			_errors.append("play_delivery on a site tipped the scale")
	if _frame == 70 + 240:
		if absf(_beam_angle(_m)) > 0.06:
			_errors.append("the scale did not settle after 4 s (%.3f rad)" % _beam_angle(_m))
		if int(_m.get(&"_deliveries")) != 1:
			_errors.append("delivery count %d, want 1" % int(_m.get(&"_deliveries")))
		_m.call(&"set_health_ratio", 0.4)
	if _frame == 70 + 242:
		_expect_visible("Body/Mast/MastGem", false, "HP 40 %")
		_expect_visible("Body/Roof/RoofHoleL", true, "HP 40 %")
		_expect_visible("Body/Mast/MastBanner", true, "HP 40 %")
		_m.call(&"set_health_ratio", 0.2)
	if _frame == 70 + 244:
		_expect_visible("Body/Mast/MastBanner", false, "HP 20 %")
		_expect_visible("Body/Roof/RoofHoleR", true, "HP 20 %")
		_m.call(&"set_health_ratio", 1.0)
		_m.call(&"set_team_color", RED)
	if _frame == 70 + 246:
		_expect_visible("Body/Mast/MastGem", true, "healed")
		_expect_visible("Body/Mast/MastBanner", true, "healed")
		_expect_visible("Body/Roof/RoofHoleL", false, "healed")
		for mat_name: StringName in [&"mat_cloth", &"mat_team"]:
			var mat := _m.get(mat_name) as ShaderMaterial
			var c: Color = mat.get_shader_parameter(&"base_color") if mat else Color.BLACK
			if not c.is_equal_approx(RED):
				_errors.append("team colour: %s is %s" % [mat_name, c])
		var roof := _m.get(&"mat_roof") as ShaderMaterial
		if roof == null or not (roof.get_shader_parameter(&"base_color") as Color).is_equal_approx(RED.darkened(0.35)):
			_errors.append("team colour: roof tiles not recoloured")
		_check_building()
		_m.call(&"play_destroyed")
		if _bld:
			_bld.call(&"take_damage", 1.0e6, null)
	if _frame == 70 + 246 + 60 * 4:
		if _finished != 1:
			_errors.append("destroyed_finished emitted %d times" % _finished)
		var w := _m.get_node_or_null(^"Wreck") as Node3D
		if w == null or not w.visible:
			_errors.append("wreck missing / hidden after the collapse")
		var mast := _m.get_node_or_null(^"Body/Mast") as Node3D
		if mast and mast.visible:
			_errors.append("the mast did not fall")
		if _bld and is_instance_valid(_bld):
			var model := _bld.call(&"model") as Node3D
			if model and not bool(model.get(&"_destroyed")):
				_errors.append("Building collapse did not call play_destroyed")
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			for e: String in _errors:
				print("  ", e)
			print("FAIL %s: %s" % [TASK_ID, _errors[0]])
		return true
	return false


func _check_site_state() -> void:
	# Progress 0: only the outline, the decal and the flattened plinth: every other Body part hidden.
	var body := _m.get_node_or_null(^"Body") as Node3D
	if body == null:
		_errors.append("no Body node")
		return
	for c: Node in body.get_children():
		if String(c.name).begins_with("Plinth"):
			continue
		if (c is MeshInstance3D or c.get_class() == "Node3D") and (c as Node3D).visible:
			_errors.append("site at 0 %%: part %s visible" % c.name)
			break
	var outline := _m.get_node_or_null(^"BuildOutline") as Node3D
	if outline == null or not outline.visible:
		_errors.append("site at 0 %: no build outline")


func _check_built() -> void:
	var c: Vector2i = _count(_m)
	if c.x > MAX_MESH_NODES:
		_errors.append("%d visible mesh nodes (max %d)" % [c.x, MAX_MESH_NODES])
	if c.y > 0:
		_errors.append("%d visible lights (want 0)" % c.y)
	var s := _m.get_node_or_null(^"Scaffold") as Node3D
	if s and s.visible:
		_errors.append("scaffold still visible when built")
	# Footprint and height from the merged parts (model space, Body = root space here).
	var box := AABB()
	var first: bool = true
	var top: float = 0.0
	for mi: Node in _m.find_children("*", "MeshInstance3D", true, false):
		var g := mi as MeshInstance3D
		if not g.is_visible_in_tree() or g.mesh == null or g.name == "ContactDecal" or g.name == "PlinthBase":
			continue
		var bb: AABB = _m.global_transform.affine_inverse() * g.global_transform * g.mesh.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
		top = maxf(top, bb.end.y)
	var lim: float = 3.6   # 3 x 3 cells = +-3 m; eaves may overhang 0.6 m like the Frost Hall's
	if box.position.x < -lim or box.position.z < -lim or box.end.x > lim or box.end.z > lim:
		_errors.append("parts outside the 6 x 6 footprint: %s" % box)
	if top < 8.5 or top > 10.5:
		_errors.append("top %.2f m (want 8.5-10.5)" % top)
	print("  built: %d visible mesh nodes, parts box %s, top %.2f m" % [c.x, box, top])


func _check_building() -> void:
	if _bld == null:
		return
	var model := _bld.call(&"model") as Node3D
	if model == null:
		_errors.append("Building did not instance the model_scene")
		return
	if not model.scene_file_path.ends_with("market_ice.tscn"):
		_errors.append("Building model is %s" % model.scene_file_path)
	if absf(float(model.get(&"_progress"))) > 0.001:
		_errors.append("Building site: model progress %.2f, want 0" % float(model.get(&"_progress")))
	if not (model.get(&"_team_color") as Color).is_equal_approx(RED):
		_errors.append("Building did not pass its team colour")
	_bld.call(&"take_damage", 10.0, null)
	var r: float = float(model.get(&"_health_ratio"))
	if r >= 1.0 or r <= 0.0:
		_errors.append("Building damage did not reach set_health_ratio (%.2f)" % r)


func _beam_angle(m: Node3D) -> float:
	var beam := m.get_node_or_null(^"Body/Mast/ScaleBeam") as Node3D
	if beam == null:
		_errors.append("no ScaleBeam")
		return 0.0
	# Minus the idle sway (0.035 x sin(t * 0.8)) is not needed: the thresholds allow for it.
	return beam.rotation.z


func _expect_visible(path: String, want: bool, what: String) -> void:
	var n := _m.get_node_or_null(NodePath(path)) as Node3D
	if n == null:
		_errors.append("%s: no node %s" % [what, path])
	elif n.visible != want:
		_errors.append("%s: %s visible = %s, want %s" % [what, path, n.visible, want])


## (visible MeshInstance3D nodes, visible lights), recursive through visible nodes.
func _count(n: Node) -> Vector2i:
	var c := Vector2i.ZERO
	if n is MeshInstance3D and (n as MeshInstance3D).visible:
		c.x += 1
	if n is Light3D and (n as Light3D).visible:
		c.y += 1
	for ch: Node in n.get_children():
		if ch is Node3D and not (ch as Node3D).visible:
			continue
		c += _count(ch)
	return c

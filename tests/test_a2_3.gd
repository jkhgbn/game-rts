extends SceneTree
## Task A2.3 (Ember Crown centrepiece + crystal nodes art). Headless:
##   godot --headless --path . -s tests/test_a2_3.gd --fixed-fps 60 --quit-after 4000
## 1. The pedestal scene alone: node contract (Runes with the tint uniforms), manual looks.
## 2. The crystal node scene alone: fill hook, per-instance `fill` on the crystal mesh.
## 3. The real skirmish: the altar binds itself to the EmberCrown (sealed -> awake -> empty when worn) and
##    every crystal node's model follows its crystals.
## Prints "PASS a2.3" or "FAIL a2.3: <reason>".

const TASK_ID := "a2.3"
const PEDESTAL := "res://art/environment/crown_pedestal.tscn"
const CRYSTAL := "res://art/environment/crystal_node.tscn"
const CROWN_MESH := "res://art/environment/crown/ember_crown_mesh.res"
const SEALED := 0
const STIRRING := 1
const AWAKE := 2
const EMPTY := 3

var main: Node
var _step := 0
var _t := 0
var _wait := 0
var _ped: Node3D
var _crystal: Node3D
var _art: Node        # the altar inside the skirmish crown
var _crown: Node3D
var _done := false


func _initialize() -> void:
	var err := _static_checks()
	if err != "":
		_fail(err)


func _fail(msg: String) -> void:
	print("FAIL %s: %s" % [TASK_ID, msg])
	_done = true
	quit(1)


## Scene contracts that need no game.
func _static_checks() -> String:
	if not ResourceLoader.exists(PEDESTAL) or not ResourceLoader.exists(CRYSTAL):
		return "scenes missing"
	var mesh := load(CROWN_MESH) as Mesh
	if mesh == null or mesh.get_surface_count() != 2:
		return "crown mesh missing or not 2 surfaces"
	_ped = (load(PEDESTAL) as PackedScene).instantiate() as Node3D
	root.add_child(_ped)
	for n: String in ["Stone", "Runes", "RuinDressing", "SealRings", "SealChains", "Beacon", "GroundGlow", "Embers",
			"SealBurst"]:
		if _ped.get_node_or_null(NodePath(n)) == null:
			return "pedestal has no %s" % n
	var runes := _ped.get_node("Runes") as MeshInstance3D
	var rm := runes.get_active_material(0) as ShaderMaterial
	if rm == null:
		return "Runes surface 0 is not a ShaderMaterial"
	for p: String in ["glow_color", "core_color", "energy"]:
		if rm.get_shader_parameter(p) == null:
			return "Runes material has no %s" % p
	for m: String in ["set_sealed", "set_stirring", "set_crown_present", "bind_crown", "get_look"]:
		if not _ped.has_method(m):
			return "pedestal art has no %s()" % m
	_crystal = (load(CRYSTAL) as PackedScene).instantiate() as Node3D
	root.add_child(_crystal)
	if not _crystal.has_method(&"set_fill_ratio") or not _crystal.has_method(&"get_fill_ratio"):
		return "crystal art has no fill hook"
	_crystal.call(&"set_fill_ratio", 0.3)
	if absf(float(_crystal.call(&"get_fill_ratio")) - 0.3) > 0.001:
		return "crystal fill ratio not kept"
	var cm := _crystal.get_node_or_null(^"Crystals") as GeometryInstance3D
	if cm == null:
		return "crystal node has no Crystals mesh"
	var fill: Variant = cm.get_instance_shader_parameter(&"fill")   # null with the headless dummy renderer
	if fill != null and absf(float(fill) - 0.3) > 0.001:
		return "crystal mesh fill parameter is %s" % fill
	return ""


func _process(_delta: float) -> bool:
	if _done:
		return true
	_t += 1
	match _step:
		0:   # manual looks on the standalone pedestal
			_ped.call(&"set_sealed", true)
			_step = 1
		1:
			if int(_ped.call(&"get_look")) != SEALED:
				_fail("manual sealed look is %d" % int(_ped.call(&"get_look")))
				return true
			_ped.call(&"set_stirring", true)
			_step = 2
		2:
			if int(_ped.call(&"get_look")) != STIRRING:
				_fail("manual stirring look is %d" % int(_ped.call(&"get_look")))
				return true
			_ped.call(&"set_sealed", false)
			_ped.call(&"set_stirring", false)
			_step = 3
		3:
			if int(_ped.call(&"get_look")) != AWAKE:
				_fail("manual awake look is %d" % int(_ped.call(&"get_look")))
				return true
			_ped.call(&"set_crown_present", false)
			_step = 4
		4:
			if int(_ped.call(&"get_look")) != EMPTY:
				_fail("manual empty look is %d" % int(_ped.call(&"get_look")))
				return true
			_ped.queue_free()
			_crystal.queue_free()
			main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
			var bot: Node = main.get_node_or_null(^"ShadowBot")
			if bot:
				bot.set(&"enabled", false)
			root.add_child(main)
			current_scene = main
			_step = 5
		5:   # wait for the map
			if main.get(&"hero") == null:
				_wait += 1
				if _wait > 5000:
					_fail("navigation never finished baking")
					return true
				return false
			_crown = main.get(&"crown")
			if _crown == null:
				_fail("skirmish has no crown")
				return true
			for c: Node in _crown.find_children("*", "Node3D", true, false):
				if c.has_method(&"get_look"):
					_art = c
			if _art == null:
				_fail("crown has no pedestal art")
				return true
			_step = 6
			_t = 0
		6:
			if _t < 3:
				return false
			if int(_art.call(&"get_look")) != SEALED:
				_fail("skirmish crown should look sealed at start, look %d" % int(_art.call(&"get_look")))
				return true
			if not _check_crystals():
				return true
			_crown.set(&"seal_time", 0.0)
			_step = 7
			_t = 0
		7:
			if _t < 3:
				return false
			if int(_art.call(&"get_look")) != AWAKE:
				_fail("unsealed crown should look awake, look %d" % int(_art.call(&"get_look")))
				return true
			var hero: Node3D = main.get(&"hero")
			hero.global_position = _crown.global_position + Vector3(2.6, 0.0, 2.6)
			hero.call(&"command_move", _crown.global_position + Vector3(0.8, 0.0, 0.8))
			_step = 8
			_t = 0
		8:
			if bool(_crown.call(&"is_available")):
				if _t > 600:
					_fail("the hero never took the crown")
					return true
				return false
			if _t < 3:
				return false
			if int(_art.call(&"get_look")) != EMPTY:
				_fail("worn crown should leave the altar empty, look %d" % int(_art.call(&"get_look")))
				return true
			print("PASS %s" % TASK_ID)
			_done = true
			return true
	return false


## Every crystal node's model starts full and follows take().
func _check_crystals() -> bool:
	var nodes: Array = get_nodes_in_group(&"crystal_nodes")
	if nodes.is_empty():
		_fail("no crystal nodes")
		return false
	for n: Node in nodes:
		if absf(float(n.call(&"model_fill_ratio")) - 1.0) > 0.001:
			_fail("%s model fill %s at start" % [n.name, n.call(&"model_fill_ratio")])
			return false
	var cn: Node = nodes[0]
	var max_c: int = int(cn.get(&"max_crystals"))
	cn.call(&"take", max_c / 2)
	var want: float = float(cn.get(&"crystals_left")) / float(max_c)
	if absf(float(cn.call(&"model_fill_ratio")) - want) > 0.001:
		_fail("model fill %s after take, want %s" % [cn.call(&"model_fill_ratio"), want])
		return false
	return true

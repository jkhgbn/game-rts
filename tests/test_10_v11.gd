extends SceneTree
## Task 10.V11: trade effects (art/vfx/trade_vfx.gd) + the loot sack look (art/vfx/trade_loot_sack.tscn).
## Run:  $GODOT --headless --path . -s tests/test_10_v11.gd --fixed-fps 60 --quit-after 600
## Stand-in units (a tiny Node3D script built here: team, body_height, radius, is_alive) replace Unit / Caravan.
## Checks:
##  - the node joins group "trade_vfx"; each of the 7 ids starts an effect with a target AND without one (null);
##    `at` may be a Node3D; an unknown id or no position does nothing;
##  - no node, material or mesh is created after _ready (everything pooled), even with 40 snatches at once;
##  - `snare` ends (0.2 s fade) when its unit is freed, and when the unit reports it is no longer `rooted`;
##  - at 1.0 s the <= 0.9 s effects are over while smoke (1.2 s) and ware_bought (1.3 s) still run; at 1.6 s nothing
##    runs; at 3 s nothing is left (no burst alive, every pooled piece hidden, every pool full again);
##  - loot sack: hooks exist; standalone it fades by itself at the end of `lifetime`; `play_pickup` hides it in
##    0.25 s; under an owner with `time_left()` / `is_available()` / `amount` it follows the owner; spawned by the
##    real LootSack (if scripts/world/loot_sack.gd exists) the art is loaded and finds its owner.
## Prints PASS 10_v11 / FAIL 10_v11: <reason>.

const TASK_ID := "10_v11"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nfunc is_alive() -> bool:\n\treturn alive\n"
const ROOT_STUB_SRC := "extends Node3D\nvar team: int = 1\nvar body_height: float = 1.6\nvar radius: float = 0.4\nvar rooted: bool = true\nfunc is_alive() -> bool:\n\treturn true\nfunc has_status(s: StringName) -> bool:\n\treturn rooted and s == &\"rooted\"\n"
const OWNER_SRC := "extends Node3D\nvar amount: int = 150\nvar left: float = 30.0\nvar available: bool = true\nfunc time_left() -> float:\n\treturn left\nfunc is_available() -> bool:\n\treturn available\n"
const IDS: Array[StringName] = [&"delivery", &"post_trade", &"snatch", &"smoke", &"sack_pickup", &"snare",
		&"ware_bought"]
const SHORT: Array[StringName] = [&"delivery", &"post_trade", &"snatch", &"sack_pickup", &"snare"]
const LONG: Array[StringName] = [&"smoke", &"ware_bought"]
const SACK_PATH := "res://art/vfx/trade_loot_sack.tscn"
const SACK_HOOKS: Array[StringName] = [&"set_amount", &"set_time_left", &"play_drop", &"play_pickup", &"fade_out",
		&"is_faded", &"bobs_itself"]

var world: Node3D
var vfx: Node3D
var vfx2: Node3D
var stub: GDScript
var root_stub: GDScript
var owner_stub: GDScript
var caravan: Node3D
var thief: Node3D
var t2: Node3D
var rooted_unit: Node3D
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var children2_before := 0
var mats_before: Dictionary = {}
var sack_a: Node3D       # standalone, lifetime 2 s
var sack_b: Node3D       # picked up
var sack_c: Node3D       # under a fake owner
var fake_owner: Node3D
var real_sack: Node3D


func _initialize() -> void:
	world = Node3D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	stub = _script(STUB_SRC)
	root_stub = _script(ROOT_STUB_SRC)
	owner_stub = _script(OWNER_SRC)


func _script(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s


func _process(_delta: float) -> bool:
	frame += 1
	match frame:
		2:
			_setup()
		3:
			_play_all()
			_sacks()
		4:
			# Snare on a unit whose root is over (a hero's halved root): ends at the 0.25 s check (+0.2 s fade),
			# before its natural end at 0.5 s (frame 33).
			rooted_unit.set(&"rooted", false)
		12:
			t2.queue_free()
		32:
			if int(vfx2.call(&"active_count")) != 0:
				_fail("snare still running after its unit was freed / unrooted: %s" % [vfx2.call(&"active_ids")])
			sack_b.call(&"play_pickup")
		63:
			var ids: Array = vfx.call(&"active_ids")
			for id in SHORT:
				if ids.has(id):
					_fail("%s still running at 1.0 s" % id)
			for id in LONG:
				if not ids.has(id):
					_fail("%s already over at 1.0 s" % id)
			if not (sack_a as Node3D).visible or bool(sack_a.call(&"is_faded")):
				_fail("standalone sack gone at 1.0 s (lifetime 2 s)")
			if not bool(sack_b.call(&"is_faded")) or (sack_b as Node3D).visible:
				_fail("picked-up sack still shown 0.55 s after play_pickup")
			if bool(sack_c.call(&"is_faded")):
				_fail("owned sack faded while its owner is available")
			fake_owner.set(&"available", false)
		86:
			if not bool(sack_c.call(&"is_faded")):
				_fail("owned sack did not fade when its owner stopped being available")
		100:
			if int(vfx.call(&"active_count")) != 0:
				_fail("effects still running at 1.6 s: %s" % [vfx.call(&"active_ids")])
			# Pool exhaustion: 40 snatches in one frame must not create anything nor error.
			for i in 40:
				vfx.call(&"play", &"snatch", Vector3(float(i), 0.0, 5.0), thief)
			if vfx.get_child_count() != children_before or _materials(vfx) != mats_before:
				_fail("nodes / materials created when the pools ran out")
		150:
			if not bool(sack_a.call(&"is_faded")) or (sack_a as Node3D).visible:
				_fail("standalone sack still shown 0.5 s after its lifetime")
		290:
			_final_checks()
			print("PASS %s" % TASK_ID if fails.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
			return true
	return false


func _setup() -> void:
	vfx = (load("res://art/vfx/trade_vfx.gd") as GDScript).new()
	vfx.name = "TradeVfx"
	world.add_child(vfx)
	vfx2 = (load("res://art/vfx/trade_vfx.gd") as GDScript).new()
	vfx2.name = "TradeVfx2"
	world.add_child(vfx2)
	if get_first_node_in_group(&"trade_vfx") == null:
		_fail("no node in group trade_vfx")
	caravan = _unit(stub, 0, Vector3(3.0, 0.0, 1.0))
	thief = _unit(stub, 2, Vector3(4.5, 0.0, 2.0))
	t2 = _unit(stub, 1, Vector3(20.0, 0.0, 20.0))
	rooted_unit = _unit(root_stub, 1, Vector3(-10.0, 0.0, 4.0))
	children_before = vfx.get_child_count()
	children2_before = vfx2.get_child_count()
	mats_before = _materials(vfx)


func _unit(script: GDScript, team: int, pos: Vector3) -> Node3D:
	var u := Node3D.new()
	u.set_script(script)
	u.set(&"team", team)
	world.add_child(u)
	u.global_position = pos
	return u


func _play_all() -> void:
	var n0: int = vfx.call(&"active_count")
	vfx.call(&"play", &"not_a_trade_effect", Vector3.ZERO, caravan)
	vfx.call(&"play", &"delivery", null, null)
	if int(vfx.call(&"active_count")) != n0:
		_fail("unknown id / no position started an effect")
	for id in IDS:
		var before: int = vfx.call(&"active_count")
		vfx.call(&"play", id, Vector3(2.0, 0.0, 0.0), thief if id == &"snatch" or id == &"sack_pickup" else caravan)
		if int(vfx.call(&"active_count")) <= before:
			_fail("%s with a target started nothing" % id)
		before = vfx.call(&"active_count")
		vfx.call(&"play", id, Vector3(-6.0, 0.0, 3.0), null)
		if int(vfx.call(&"active_count")) <= before:
			_fail("%s without a target started nothing" % id)
	var b2: int = vfx.call(&"active_count")
	vfx.call(&"play", &"ware_bought", caravan, caravan)   # `at` given as a node
	if int(vfx.call(&"active_count")) <= b2:
		_fail("ware_bought with a Node3D `at` started nothing")
	if vfx.get_child_count() != children_before:
		_fail("nodes created at runtime (%d -> %d)" % [children_before, vfx.get_child_count()])
	if _materials(vfx) != mats_before:
		_fail("materials / meshes created at runtime")
	if int(vfx.call(&"live_count")) == 0:
		_fail("nothing visible after playing 7 effects")
	# Death / unroot set on the second node.
	vfx2.call(&"play", &"snare", t2.global_position, t2)
	vfx2.call(&"play", &"snare", rooted_unit.global_position, rooted_unit)
	if int(vfx2.call(&"active_count")) != 2:
		_fail("snare set: %d effects (expected 2)" % vfx2.call(&"active_count"))


func _sacks() -> void:
	if not ResourceLoader.exists(SACK_PATH):
		_fail("missing %s" % SACK_PATH)
		return
	var scene := load(SACK_PATH) as PackedScene
	sack_a = scene.instantiate() as Node3D
	sack_a.set(&"lifetime", 2.0)
	world.add_child(sack_a)
	sack_a.position = Vector3(10.0, 0.0, 0.0)
	for h in SACK_HOOKS:
		if not sack_a.has_method(h):
			_fail("loot sack has no %s()" % h)
	if not bool(sack_a.call(&"bobs_itself")):
		_fail("bobs_itself() should be true")
	for path: String in ["Sack/Body", "Sack/MouthCoins", "Spill", "Glow", "ContactShadow", "Glints", "Dust", "Burst"]:
		if sack_a.get_node_or_null(path) == null:
			_fail("loot sack has no %s node" % path)
	sack_b = scene.instantiate() as Node3D
	world.add_child(sack_b)
	sack_b.position = Vector3(12.0, 0.0, 0.0)
	fake_owner = Node3D.new()
	fake_owner.set_script(owner_stub)
	world.add_child(fake_owner)
	var visual := Node3D.new()
	fake_owner.add_child(visual)
	sack_c = scene.instantiate() as Node3D
	visual.add_child(sack_c)
	var sack_node := sack_c.get_node("Sack") as Node3D
	if sack_node.scale.x < 1.15:
		_fail("owned sack did not read the owner's amount (scale %.2f, expected 1.2 for 150 gold)" % sack_node.scale.x)
	# The real LootSack (task 10.C1), if it exists: it must load and host the art.
	if ResourceLoader.exists("res://scripts/world/loot_sack.gd"):
		var ls := load("res://scripts/world/loot_sack.gd") as Script
		real_sack = ls.call(&"spawn", world, Vector3(-20.0, 0.0, -20.0), 40)
		if real_sack == null:
			_fail("LootSack.spawn returned null")
		elif real_sack.get_node_or_null("Visual/Art") == null:
			_fail("LootSack did not load the art (no Visual/Art)")


func _final_checks() -> void:
	for v: Node3D in [vfx, vfx2]:
		if int(v.call(&"live_count")) != 0:
			_fail("%s: pieces or bursts still alive at 4.8 s (%d)" % [v.name, v.call(&"live_count")])
		if int(v.call(&"active_count")) != 0:
			_fail("%s: effects still running at 4.8 s" % v.name)
		for c in v.get_children():
			if c is GPUParticles3D and (c as GPUParticles3D).visible:
				_fail("burst %s still shown at 4.8 s" % c.name)
				break
			if c is MeshInstance3D and (c as MeshInstance3D).visible:
				_fail("piece %s still visible at 4.8 s" % c.name)
				break
		var free: Dictionary = v.get(&"_free")
		var sizes: Dictionary = v.get(&"POOL_SIZES")
		for pool: StringName in sizes:
			if (free[pool] as Array).size() != int(sizes[pool]):
				_fail("%s: pool %s has %d free of %d (leak)" % [v.name, pool, (free[pool] as Array).size(), sizes[pool]])
	if vfx.get_child_count() != children_before or vfx2.get_child_count() != children2_before:
		_fail("nodes created during the run")
	if _materials(vfx) != mats_before:
		_fail("materials created during the run")


## Instance ids of every material, mesh and process material the pools use.
func _materials(v: Node) -> Dictionary:
	var out: Dictionary = {}
	for c in v.get_children():
		if c is MeshInstance3D:
			out[(c as MeshInstance3D).material_override.get_instance_id()] = true
			out[(c as MeshInstance3D).mesh.get_instance_id()] = true
		elif c is GPUParticles3D:
			var p := c as GPUParticles3D
			out[p.process_material.get_instance_id()] = true
			out[p.draw_pass_1.get_instance_id()] = true
			out[(p.draw_pass_1 as PrimitiveMesh).material.get_instance_id()] = true
	return out


func _fail(why: String) -> void:
	fails.append(why)
	print("  fail: ", why)

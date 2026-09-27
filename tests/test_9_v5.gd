extends SceneTree
## Task 9.V5: champion ability effects (art/vfx/champion_vfx.gd).
## Run:  $GODOT --headless --path . -s tests/test_9_v5.gd --fixed-fps 60 --quit-after 900
## Stand-in units (a tiny Node3D script built here: team, body_height, radius, is_alive) replace Champion / Unit.
## Checks:
##  - the node joins group "champion_vfx"; every one of the 12 ids starts an effect on a unit target AND on a Vector3;
##    an unknown id does nothing; a null caster works;
##  - no node, material or mesh is created after _ready (everything pooled);
##  - Oath of Iron puts taunt badges on the 3 enemies within 6 m only (not the ally, the far enemy, the wizard);
##  - effects on a unit end (0.25 s fade) when that unit is freed, and Bulwark / Trailblaze end when the caster dies
##    (is_alive() false while still in the tree; polled 4 times per second);
##  - at 4 s the <= 3 s effects are over while the 5-6 s ones still run; at 7 s nothing runs; at 9 s nothing is left
##    (no emitter emitting, every pooled piece hidden).
## Prints PASS 9_v5 / FAIL 9_v5: <reason>.

const TASK_ID := "9_v5"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nfunc is_alive() -> bool:\n\treturn alive\n"
const IDS: Array[StringName] = [&"flare_arrow", &"snare_line", &"trailblaze", &"oath_of_iron", &"shield_bash",
		&"bulwark_stand", &"cutpurse", &"smoke_pouch", &"marked_for_coin", &"mending_draught", &"soothing_circle",
		&"lifeline"]
const SHORT: Array[StringName] = [&"snare_line", &"shield_bash", &"cutpurse", &"mending_draught", &"smoke_pouch",
		&"oath_of_iron", &"taunt_mark"]
const LONG: Array[StringName] = [&"flare_arrow", &"trailblaze", &"bulwark_stand", &"marked_for_coin",
		&"soothing_circle", &"lifeline"]

var world: Node3D
var vfx: Node3D
var vfx2: Node3D
var stub: GDScript
var caster: Node3D
var target: Node3D
var t2: Node3D
var c2: Node3D
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var mats_before: Dictionary = {}


func _initialize() -> void:
	world = Node3D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	stub = GDScript.new()
	stub.source_code = STUB_SRC
	stub.reload()


func _process(_delta: float) -> bool:
	frame += 1
	match frame:
		2:
			_setup()
		3:
			_play_all()
		30:
			# 0.45 s in: kill the second target (freed) and the second caster (dead, still in the tree).
			if vfx2.call(&"active_count") != 7:
				_fail("death set: %d effects running before the deaths (expected 7): %s" % [vfx2.call(&"active_count"),
						vfx2.call(&"active_ids")])
			t2.queue_free()
			c2.set(&"alive", false)
		64:
			# Freed: noticed the next frame; dead but still in the tree: at the next 4 Hz check. Then 0.25 s fade.
			if vfx2.call(&"active_count") != 0:
				_fail("effects still running 0.55 s after their unit died: %s" % [vfx2.call(&"active_ids")])
		243:
			var ids: Array = vfx.call(&"active_ids")
			for id in SHORT:
				if ids.has(id):
					_fail("%s still running at 4 s" % id)
			for id in LONG:
				if not ids.has(id):
					_fail("%s already over at 4 s" % id)
		423:
			if vfx.call(&"active_count") != 0:
				_fail("effects still running at 7 s: %s" % [vfx.call(&"active_ids")])
		543:
			_final_checks()
			print("PASS %s" % TASK_ID if fails.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
			return true
	return false


func _setup() -> void:
	vfx = (load("res://art/vfx/champion_vfx.gd") as GDScript).new()
	vfx.name = "ChampionVfx"
	world.add_child(vfx)
	vfx2 = (load("res://art/vfx/champion_vfx.gd") as GDScript).new()
	vfx2.name = "ChampionVfx2"
	world.add_child(vfx2)
	if get_first_node_in_group(&"champion_vfx") == null:
		_fail("no node in group champion_vfx")
	caster = _unit(0, Vector3.ZERO)
	target = _unit(1, Vector3(4.0, 0.0, 2.0))
	_unit(1, Vector3(2.0, 0.0, -2.0))      # enemy within 6 m
	_unit(1, Vector3(-3.0, 0.0, 1.0))      # enemy within 6 m
	_unit(1, Vector3(15.0, 0.0, 0.0))      # enemy too far
	_unit(0, Vector3(1.0, 0.0, 1.0))       # ally
	var wiz := _unit(1, Vector3(1.0, 0.0, -1.0))
	wiz.add_to_group(&"heroes")            # a wizard: taunt never shows on it
	t2 = _unit(1, Vector3(40.0, 0.0, 40.0))
	c2 = _unit(0, Vector3(-40.0, 0.0, -40.0))
	children_before = vfx.get_child_count()
	mats_before = _materials(vfx)


func _unit(team: int, pos: Vector3) -> Node3D:
	var u := Node3D.new()
	u.set_script(stub)
	u.set(&"team", team)
	world.add_child(u)
	u.global_position = pos
	u.add_to_group(&"units")
	return u


func _play_all() -> void:
	# Oath alone first: 3 badges expected.
	vfx.call(&"play", &"oath_of_iron", caster, caster)
	var marks := (vfx.call(&"active_ids") as Array).count(&"taunt_mark")
	if marks != 3:
		_fail("Oath of Iron made %d taunt badges (expected 3)" % marks)
	var n0: int = vfx.call(&"active_count")
	vfx.call(&"play", &"not_an_ability", caster, target)
	if vfx.call(&"active_count") != n0:
		_fail("unknown id started an effect")
	for id in IDS:
		var before: int = vfx.call(&"active_count")
		vfx.call(&"play", id, caster, target)
		if vfx.call(&"active_count") <= before:
			_fail("%s on a unit started nothing" % id)
		before = vfx.call(&"active_count")
		vfx.call(&"play", id, caster, Vector3(6.0, 0.0, -3.0))
		if vfx.call(&"active_count") <= before:
			_fail("%s on a point started nothing" % id)
	vfx.call(&"play", &"flare_arrow", null, Vector3(-8.0, 0.0, 5.0))
	vfx.call(&"play", &"soothing_circle", null, Vector3(-8.0, 0.0, 5.0))
	if vfx.get_child_count() != children_before:
		_fail("nodes created at runtime (%d -> %d)" % [children_before, vfx.get_child_count()])
	if _materials(vfx) != mats_before:
		_fail("materials / meshes created at runtime")
	if int(vfx.call(&"live_count")) == 0:
		_fail("nothing visible after playing 12 effects")
	# Death set on the second node: 5 effects on t2, 2 bound to c2.
	for id: StringName in [&"snare_line", &"shield_bash", &"marked_for_coin", &"mending_draught", &"lifeline"]:
		vfx2.call(&"play", id, c2, t2)
	vfx2.call(&"play", &"bulwark_stand", c2, c2)
	vfx2.call(&"play", &"trailblaze", c2, c2)


func _final_checks() -> void:
	if int(vfx.call(&"live_count")) != 0 or int(vfx2.call(&"live_count")) != 0:
		_fail("pieces or emitters still alive at 9 s (%d, %d)" % [vfx.call(&"live_count"), vfx2.call(&"live_count")])
	for v: Node3D in [vfx, vfx2]:
		for c in v.get_children():
			if c is GPUParticles3D and ((c as GPUParticles3D).emitting and (c as GPUParticles3D).visible):
				_fail("emitter %s still emitting at 9 s" % c.name)
				break
			if c is MeshInstance3D and (c as MeshInstance3D).visible:
				_fail("piece %s still visible at 9 s" % c.name)
				break
	if vfx.get_child_count() != children_before or _materials(vfx) != mats_before:
		_fail("nodes / materials created during the run")


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

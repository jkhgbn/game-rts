extends SceneTree
## Task 13b.V8: the Mage Archer's effects (art/vfx/champion_mage_archer_vfx.gd through ChampionVfx.play).
## Run:  $GODOT --headless --path . -s tests/test_13b_v8.gd --fixed-fps 60 --quit-after 900
## Stand-in units (tiny Node3D scripts built here: team, body_height, radius, is_alive, get_model, statuses) replace
## Champion / Unit; one caster carries the real Mage Archer model (get_beam_origin / get_quiver_origin). Checks:
##  - each of the 6 ids starts an effect on a unit target AND on a Vector3 (and with no caster); unknown ids are still
##    ignored; the 12 step-9 ids and the 13 class ids still play;
##  - no node, material or mesh is created after _ready (everything pooled); something is visible after the casts;
##  - Sable Shaft: the charge follows the model's bow (get_beam_origin) and nothing flies before the loose (0.55 s);
##    after it the shaft and its beam show; a shaft whose caster dies while drawing is dropped, one loosed plays out;
##  - Grave Mark ends with the `marked` status (no soul wisp: its unit lives); a unit killed while marked sends ONE
##    `grave_reap` wisp back; a unit killed before the mark lands sends none;
##  - Eclipse Volley leaves 3 sets of stuck arrows after its waves and plays out when its caster dies;
##  - unique_call / unique_revive show their columns;
##  - fog: a hidden caster's shaft and a volley on a spot the local team does not see show nothing;
##  - at 3.2 s only the Grave Marks run; at 7.2 s nothing runs; at 8.5 s nothing is left (no emitter emitting, every
##    pooled piece hidden).
## Prints PASS 13b_v8 / FAIL 13b_v8: <reason>.

const TASK_ID := "13b_v8"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nvar model: Node3D = null\nfunc is_alive() -> bool:\n\treturn alive\nfunc get_model() -> Node3D:\n\treturn model\n"
const STATUS_SRC := "extends Node3D\nvar team: int = 1\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nvar statuses: Dictionary = {}\nfunc is_alive() -> bool:\n\treturn alive\nfunc has_status(id: StringName) -> bool:\n\treturn statuses.has(id)\nfunc status_time_left(id: StringName) -> float:\n\treturn float(statuses.get(id, 0.0))\n"
const FOG_SRC := "extends Node\nvar enabled: bool = true\nvar local_team: int = 1\nfunc is_visible(_team: int, pos: Vector3) -> bool:\n\treturn pos.x < 100.0\n"
const IDS: Array[StringName] = [&"arcane_arrow", &"sable_shaft", &"grave_mark", &"eclipse_volley", &"unique_call",
		&"unique_revive"]
const OLD: Array[StringName] = [&"flare_arrow", &"snare_line", &"trailblaze", &"oath_of_iron", &"shield_bash",
		&"bulwark_stand", &"cutpurse", &"smoke_pouch", &"marked_for_coin", &"mending_draught", &"soothing_circle",
		&"lifeline", &"lunge", &"hobbling_javelin", &"skewer", &"riposte", &"second_wind", &"shield_throw", &"cleave",
		&"crushing_blow", &"whirlwind", &"arc_bolt", &"slipstep", &"starfall", &"class_chosen"]

var world: Node3D
var vfx: Node3D      # every id, timings
var vfx2: Node3D     # Sable Shaft deaths
var vfx3: Node3D     # Grave Mark status / reap
var vfx4: Node3D     # fog
var vfx5: Node3D     # the step-9 / class ids still play
var stub: GDScript
var status_stub: GDScript
var caster: Node3D
var target: Node3D
var cm: Node3D       # caster with the real Mage Archer model
var cm_model: Node3D
var c2: Node3D
var c2b: Node3D
var c3: Node3D
var t_status: Node3D
var t_killed: Node3D
var t_early: Node3D
var c4: Node3D
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var mats_before: Dictionary = {}


func _initialize() -> void:
	world = Node3D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	stub = _script(STUB_SRC)
	status_stub = _script(STATUS_SRC)


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
		9:
			t_early.set(&"alive", false)            # 0.1 s: killed before the mark lands (0.4 s)
		21:
			_check_bow()                             # 0.3 s
			c2.set(&"alive", false)                  # dies while drawing
		30:
			# 0.45 s: nothing of the shafts flies before the loose.
			if _visible(vfx, "MaBolt") != 0:
				_fail("a Sable Shaft bolt shows before the loose (%d)" % _visible(vfx, "MaBolt"))
		45:
			# 0.7 s: both shafts (unit and point) fly: heads + beams.
			if _visible(vfx, "MaBolt") < 3:
				_fail("Sable Shaft head / beam not showing after the loose (%d)" % _visible(vfx, "MaBolt"))
		51:
			c2b.set(&"alive", false)                 # 0.8 s: dies after loosing
		57:
			var n := _count(vfx2.call(&"active_ids"), &"sable_shaft")
			if n != 1:
				_fail("vfx2 runs %d shafts at 0.9 s (expected 1: dropped while drawing, kept once loosed)" % n)
		63:
			# 1.0 s
			if _visible(vfx, "MaColumn") < 2:
				_fail("unique_call columns not showing at 1.0 s (%d)" % _visible(vfx, "MaColumn"))
			t_status.set(&"statuses", {})            # the mark is cleansed
			t_killed.set(&"alive", false)            # killed while marked
			if _visible(vfx4, "") != 0:
				_fail("fogged effects show (%d pieces)" % _visible(vfx4, ""))
		87:
			# 1.4 s
			var reaps := _count(vfx3.call(&"active_ids"), &"grave_reap")
			if reaps != 1:
				_fail("%d grave_reap wisps at 1.4 s (expected 1)" % reaps)
		99:
			# 1.6 s: the three waves have landed.
			if _visible(vfx, "MaStuck") < 3:
				_fail("Eclipse Volley stuck arrows not showing after the waves (%d)" % _visible(vfx, "MaStuck"))
			var ids3: Array = vfx3.call(&"active_ids")
			if _count(ids3, &"grave_mark") != 0:
				_fail("Grave Marks still running 0.6 s after their status went / unit died (%s)" % [ids3])
		195:
			# 3.2 s
			for v: Node3D in [vfx, vfx2]:
				for id: StringName in v.call(&"active_ids"):
					if id != &"grave_mark":
						_fail("%s still running at 3.2 s on %s" % [id, v.name])
			if _count(vfx.call(&"active_ids"), &"grave_mark") < 2:
				_fail("Grave Mark (no status system: fixed 6 s) already over at 3.2 s")
		435:
			# 7.2 s
			for v: Node3D in [vfx, vfx2, vfx3, vfx4, vfx5]:
				if v.call(&"active_count") != 0:
					_fail("effects still running at 7.2 s on %s: %s" % [v.name, v.call(&"active_ids")])
		513:
			_final_checks()
			print("PASS %s" % TASK_ID if fails.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
			return true
	return false


func _setup() -> void:
	var fog := Node.new()
	fog.set_script(_script(FOG_SRC))
	fog.add_to_group(&"fog")
	world.add_child(fog)
	vfx = _new_vfx("ChampionVfx")
	vfx2 = _new_vfx("ChampionVfx2")
	vfx3 = _new_vfx("ChampionVfx3")
	vfx4 = _new_vfx("ChampionVfx4")
	vfx5 = _new_vfx("ChampionVfx5")
	caster = _unit(0, Vector3.ZERO)
	caster.set(&"body_height", 2.0)
	target = _unit(1, Vector3(5.0, 0.0, 2.0))
	_unit(1, Vector3(8.0, 0.0, 3.2))      # behind the target on the shaft line
	_unit(1, Vector3(3.0, 0.0, 4.0))      # off the line
	_unit(0, Vector3(1.0, 0.0, -1.0))     # ally
	# The real model on a caster at (-20, 0, 0).
	cm = _unit(0, Vector3(-20.0, 0.0, 0.0))
	cm.set(&"body_height", 2.0)
	var ps := load("res://art/units/champions/mage_archer/mage_archer.tscn") as PackedScene
	if ps == null:
		_fail("the Mage Archer model does not load")
	else:
		cm_model = ps.instantiate()
		cm.add_child(cm_model)
		cm.set(&"model", cm_model)
	_unit(1, Vector3(-14.0, 0.0, 0.0))
	# Deaths (vfx2).
	c2 = _unit(0, Vector3(-40.0, 0.0, -40.0))
	c2b = _unit(0, Vector3(-40.0, 0.0, -30.0))
	# Grave Mark (vfx3).
	c3 = _unit(0, Vector3(40.0, 0.0, 40.0))
	t_status = _status_unit(Vector3(46.0, 0.0, 40.0))
	t_killed = _status_unit(Vector3(40.0, 0.0, 47.0))
	t_early = _status_unit(Vector3(34.0, 0.0, 40.0))
	# Fog (vfx4): a hidden team-0 caster the local team (1) does not see, a volley on a spot it does not see.
	c4 = _unit(0, Vector3(200.0, 0.0, 0.0))
	c4.visible = false
	children_before = vfx.get_child_count()
	mats_before = _materials(vfx)


func _new_vfx(n: String) -> Node3D:
	var script := load("res://art/vfx/champion_vfx.gd") as GDScript
	if script == null or not script.can_instantiate():
		print("FAIL %s: art/vfx/champion_vfx.gd does not load" % TASK_ID)
		quit(1)
		return Node3D.new()
	var v: Node3D = script.new()
	v.name = n
	world.add_child(v)
	return v


func _unit(team: int, pos: Vector3) -> Node3D:
	var u := Node3D.new()
	u.set_script(stub)
	u.set(&"team", team)
	world.add_child(u)
	u.global_position = pos
	u.add_to_group(&"units")
	return u


func _status_unit(pos: Vector3) -> Node3D:
	var u := Node3D.new()
	u.set_script(status_stub)
	u.set(&"statuses", {&"marked": 6.0})
	world.add_child(u)
	u.global_position = pos
	u.add_to_group(&"units")
	return u


func _play_all() -> void:
	var n0: int = vfx.call(&"active_count")
	vfx.call(&"play", &"not_an_ability", caster, target)
	if vfx.call(&"active_count") != n0:
		_fail("unknown id started an effect")
	for id in IDS:
		var before: int = vfx.call(&"active_count")
		var on_unit: Variant = caster if id == &"unique_call" or id == &"unique_revive" else target
		vfx.call(&"play", id, caster, on_unit)
		if vfx.call(&"active_count") <= before:
			_fail("%s on a unit started nothing" % id)
		before = vfx.call(&"active_count")
		vfx.call(&"play", id, caster, Vector3(6.0, 0.0, -3.0))
		if vfx.call(&"active_count") <= before:
			_fail("%s on a point started nothing" % id)
		before = vfx5.call(&"active_count")
		vfx5.call(&"play", id, null, Vector3(-60.0, 0.0, 30.0))
		if vfx5.call(&"active_count") <= before:
			_fail("%s without a caster started nothing" % id)
	for id in OLD:
		var before: int = vfx5.call(&"active_count")
		vfx5.call(&"play", id, caster, target)
		if vfx5.call(&"active_count") <= before:
			_fail("older id %s no longer plays" % id)
	if cm_model:
		cm_model.call(&"play_cast", &"sable_shaft")
	vfx.call(&"play", &"sable_shaft", cm, cm.global_position + Vector3(8.0, 0.0, 0.0))
	vfx2.call(&"play", &"sable_shaft", c2, c2.global_position + Vector3(8.0, 0.0, 0.0))
	vfx2.call(&"play", &"sable_shaft", c2b, c2b.global_position + Vector3(8.0, 0.0, 0.0))
	vfx2.call(&"play", &"eclipse_volley", c2b, c2b.global_position + Vector3(9.0, 0.0, 0.0))
	vfx3.call(&"play", &"grave_mark", c3, t_status)
	vfx3.call(&"play", &"grave_mark", c3, t_killed)
	vfx3.call(&"play", &"grave_mark", c3, t_early)
	vfx4.call(&"play", &"sable_shaft", c4, Vector3(210.0, 0.0, 0.0))
	vfx4.call(&"play", &"eclipse_volley", c4, Vector3(205.0, 0.0, 4.0))
	if vfx.get_child_count() != children_before:
		_fail("nodes created at runtime (%d -> %d)" % [children_before, vfx.get_child_count()])
	if _materials(vfx) != mats_before:
		_fail("materials / meshes created at runtime")
	if int(vfx.call(&"live_count")) == 0:
		_fail("nothing visible after playing the Mage Archer effects")


## 0.3 s: the Sable Shaft charge of the model caster sits on the model's arrow head.
func _check_bow() -> void:
	if cm_model == null:
		return
	var bow: Vector3 = cm_model.call(&"get_beam_origin")
	var found := false
	for fx: Object in vfx.get(&"_fx"):
		if fx.get(&"id") == &"sable_shaft" and fx.get(&"caster") == cm:
			found = true
			var at: Vector3 = (fx.get(&"data") as Dictionary).get("arrow_pos", Vector3.INF)
			if at.distance_to(bow) > 0.05:
				_fail("the shaft charge is not on the bow (%s vs %s)" % [at, bow])
	if not found:
		_fail("the model caster's Sable Shaft is not running at 0.3 s")
	if bow.distance_to(cm.global_position + Vector3.UP * 1.5) > 1.5:
		_fail("get_beam_origin is far from the bow (%s)" % bow)


func _count(ids: Array, id: StringName) -> int:
	var n := 0
	for x in ids:
		if x == id:
			n += 1
	return n


## Visible pooled meshes of `v` whose name starts with `prefix` ("" = all).
func _visible(v: Node, prefix: String) -> int:
	var n := 0
	for c in v.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).visible and String(c.name).begins_with(prefix):
			n += 1
	return n


func _final_checks() -> void:
	for v: Node3D in [vfx, vfx2, vfx3, vfx4, vfx5]:
		if int(v.call(&"live_count")) != 0:
			_fail("%s: pieces or emitters still alive at 8.5 s (%d)" % [v.name, v.call(&"live_count")])
		for c in v.get_children():
			if c is GPUParticles3D and ((c as GPUParticles3D).emitting and (c as GPUParticles3D).visible):
				_fail("emitter %s still emitting at 8.5 s" % c.name)
				break
			if c is MeshInstance3D and (c as MeshInstance3D).visible:
				_fail("piece %s still visible at 8.5 s" % c.name)
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

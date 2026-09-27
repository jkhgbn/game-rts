extends SceneTree
## Task 11.V6: champion class-skill effects + the class_chosen ring (art/vfx/champion_vfx.gd).
## Run:  $GODOT --headless --path . -s tests/test_11_v6.gd --fixed-fps 60 --quit-after 900
## Stand-in units (tiny Node3D scripts built here: team, body_height, radius, is_alive, class_id, abilities) replace
## Champion / Unit. Checks:
##  - every one of the 13 new ids starts an effect on a unit target AND on a Vector3 (self skills: on the caster);
##    class_chosen plays for the 4 classes (class_id() and a StringName argument) and with no class; unknown ids are
##    still ignored; the 12 step-9 ids still play;
##  - no node, material or mesh is created after _ready (everything pooled); something is visible after the casts;
##  - Riposte / Whirlwind listen to the caster's abilities.skill_hit while they run (a counter spark shows) and
##    disconnect at their end; Riposte falls back to damage_taken on a caster without abilities;
##  - the Hobbling Javelin's hobble waits for the landing before checking `smoulder` (still running in flight) and
##    ends soon after landing on a unit that never got the status;
##  - the Crushing Blow badge ends when its unit is freed; Whirlwind / Riposte end when the caster dies;
##  - at 1.3 s the short effects are over; at 3.5 s only Riposte, Second Wind and Crushing Blow run
##    (the hobble ends 3 s after landing); at 7 s nothing runs; at 8.5 s nothing is left (no emitter emitting, every pooled piece hidden).
## Prints PASS 11_v6 / FAIL 11_v6: <reason>.

const TASK_ID := "11_v6"
const STUB_SRC := "extends Node3D\nsignal damage_taken(amount: float, attacker: Node3D)\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nvar attack_range: float = 1.5\nvar cls: StringName = &\"\"\nvar abilities: Node = null\nfunc is_alive() -> bool:\n\treturn alive\nfunc class_id() -> StringName:\n\treturn cls\n"
const STATUS_SRC := "extends Node3D\nvar team: int = 1\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar statuses: Dictionary = {}\nfunc is_alive() -> bool:\n\treturn true\nfunc has_status(id: StringName) -> bool:\n\treturn statuses.has(id)\nfunc status_time_left(id: StringName) -> float:\n\treturn float(statuses.get(id, 0.0))\n"
const ABILITIES_SRC := "extends Node\nsignal skill_hit(id: StringName, target: Node3D, amount: float)\n"
const IDS: Array[StringName] = [&"lunge", &"hobbling_javelin", &"skewer", &"riposte", &"second_wind",
		&"shield_throw", &"cleave", &"crushing_blow", &"whirlwind", &"arc_bolt", &"slipstep", &"starfall",
		&"class_chosen"]
const SELF_IDS: Array[StringName] = [&"riposte", &"second_wind", &"whirlwind", &"class_chosen"]
const STEP9: Array[StringName] = [&"flare_arrow", &"snare_line", &"trailblaze", &"oath_of_iron", &"shield_bash",
		&"bulwark_stand", &"cutpurse", &"smoke_pouch", &"marked_for_coin", &"mending_draught", &"soothing_circle",
		&"lifeline"]
const SHORT: Array[StringName] = [&"lunge", &"skewer", &"cleave", &"arc_bolt", &"slipstep", &"class_chosen",
		&"shield_throw"]
const LONG: Array[StringName] = [&"riposte", &"second_wind", &"crushing_blow"]
const MID: Array[StringName] = [&"whirlwind", &"starfall", &"hobbling_javelin"]

var world: Node3D
var vfx: Node3D
var vfx2: Node3D
var vfx3: Node3D
var stub: GDScript
var status_stub: GDScript
var caster: Node3D
var target: Node3D
var abil: Node
var c2: Node3D
var t2: Node3D
var c3: Node3D
var hobbled: Node3D
var far_hob: Node3D
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var mats_before: Dictionary = {}
var live_before_hit := 0


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
			_play_side()
		30:
			# Riposte hook: the step-3 bursts are over after 0.45 s; a counter spark must show now.
			live_before_hit = int(vfx2.call(&"live_count"))
			abil.emit_signal(&"skill_hit", &"riposte", t2, 10.0)
			abil.emit_signal(&"skill_hit", &"whirlwind", t2, 12.0)
			if int(vfx2.call(&"live_count")) < live_before_hit + 2:
				_fail("skill_hit did not burst counter / whirl sparks (%d -> %d)" % [live_before_hit,
						vfx2.call(&"live_count")])
			# Fallback: a caster without abilities hears damage_taken from a melee attacker.
			var before := int(vfx3.call(&"live_count"))
			c3.emit_signal(&"damage_taken", 10.0, hobbled)
			if int(vfx3.call(&"live_count")) <= before:
				_fail("Riposte did not answer damage_taken from a melee attacker")
		50:
			# 0.78 s: the javelin (12 m, 0.48 s flight) landed 0.3 s ago: its grace is not over, the hobble runs.
			if not (vfx3.call(&"active_ids") as Array).has(&"hobbling_javelin"):
				_fail("the javelin's hobble ended before its landing grace (status checked in flight)")
		100:
			if (vfx3.call(&"active_ids") as Array).has(&"hobbling_javelin"):
				_fail("the hobble still runs 1.1 s after landing on a unit without smoulder")
		70:
			# Deaths: the crushed unit is freed, the whirlwind / riposte caster dies (still in the tree).
			t2.queue_free()
			c2.set(&"alive", false)
		110:
			var left: Array = vfx2.call(&"active_ids")
			for id: StringName in [&"crushing_blow", &"whirlwind", &"riposte"]:
				if left.has(id):
					_fail("%s still running 0.65 s after its unit died" % id)
		81:
			var ids: Array = vfx.call(&"active_ids")
			for id in SHORT:
				if ids.has(id):
					_fail("%s still running at 1.3 s" % id)
			for id in LONG + MID:
				if not ids.has(id):
					_fail("%s already over at 1.3 s" % id)
		213:
			var ids: Array = vfx.call(&"active_ids")
			for id in MID:
				if ids.has(id):
					_fail("%s still running at 3.5 s" % id)
			for id in LONG:
				if not ids.has(id):
					_fail("%s already over at 3.5 s" % id)
		423:
			for v: Node3D in [vfx, vfx2, vfx3]:
				if v.call(&"active_count") != 0:
					_fail("effects still running at 7 s: %s" % [v.call(&"active_ids")])
			if abil.get_signal_connection_list(&"skill_hit").size() != 0:
				_fail("skill_hit still connected after the effects ended")
			if c3.get_signal_connection_list(&"damage_taken").size() != 0:
				_fail("damage_taken still connected after Riposte ended")
		513:
			_final_checks()
			print("PASS %s" % TASK_ID if fails.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
			return true
	return false


func _setup() -> void:
	vfx = _new_vfx("ChampionVfx")
	vfx2 = _new_vfx("ChampionVfx2")
	vfx3 = _new_vfx("ChampionVfx3")
	caster = _unit(0, Vector3.ZERO)
	caster.set(&"cls", &"spear")
	target = _unit(1, Vector3(4.0, 0.0, 2.0))
	_unit(1, Vector3(5.5, 0.0, 3.0))       # next to the target: shield bounce, cleave splash
	_unit(1, Vector3(2.0, 0.0, 1.0))       # in the skewer line toward the target
	_unit(0, Vector3(1.0, 0.0, -1.0))      # ally: never a bounce / splash
	# Hook / death set on vfx2: a caster with an abilities node, a target that will be freed.
	c2 = _unit(0, Vector3(-40.0, 0.0, -40.0))
	abil = Node.new()
	abil.set_script(_script(ABILITIES_SRC))
	abil.name = "ChampionAbilities"
	c2.add_child(abil)
	c2.set(&"abilities", abil)
	t2 = _unit(1, Vector3(-38.0, 0.0, -40.0))
	# Status / fallback set on vfx3.
	c3 = _unit(0, Vector3(40.0, 0.0, 40.0))
	hobbled = Node3D.new()
	hobbled.set_script(status_stub)
	world.add_child(hobbled)
	hobbled.global_position = Vector3(42.0, 0.0, 40.0)   # 2 m from c3: a melee attacker for Riposte
	hobbled.add_to_group(&"units")
	far_hob = Node3D.new()
	far_hob.set_script(status_stub)
	world.add_child(far_hob)
	far_hob.global_position = Vector3(52.0, 0.0, 40.0)   # 12 m: a 0.48 s javelin flight
	far_hob.add_to_group(&"units")
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


func _play_all() -> void:
	var n0: int = vfx.call(&"active_count")
	vfx.call(&"play", &"not_an_ability", caster, target)
	if vfx.call(&"active_count") != n0:
		_fail("unknown id started an effect")
	for id in IDS:
		var before: int = vfx.call(&"active_count")
		vfx.call(&"play", id, caster, caster if SELF_IDS.has(id) else target)
		if vfx.call(&"active_count") <= before:
			_fail("%s on a unit started nothing" % id)
		before = vfx.call(&"active_count")
		vfx.call(&"play", id, caster, Vector3(6.0, 0.0, -3.0))
		if vfx.call(&"active_count") <= before:
			_fail("%s on a point started nothing" % id)
	for cls: StringName in [&"sword_shield", &"two_hand", &"wizard", &""]:
		var before: int = vfx.call(&"active_count")
		vfx.call(&"play", &"class_chosen", caster, cls)
		if vfx.call(&"active_count") <= before:
			_fail("class_chosen for '%s' started nothing" % cls)
	vfx.call(&"play", &"starfall", null, Vector3(-8.0, 0.0, 5.0))
	vfx.call(&"play", &"arc_bolt", null, target)
	vfx.call(&"play", &"shield_throw", null, target)
	if vfx.get_child_count() != children_before:
		_fail("nodes created at runtime (%d -> %d)" % [children_before, vfx.get_child_count()])
	if _materials(vfx) != mats_before:
		_fail("materials / meshes created at runtime")
	if int(vfx.call(&"live_count")) == 0:
		_fail("nothing visible after playing the class effects")


func _play_side() -> void:
	# The step-9 effects still play on a separate node (its own test covers them fully).
	for id in STEP9:
		var before: int = vfx3.call(&"active_count")
		vfx3.call(&"play", id, c3, hobbled)
		if vfx3.call(&"active_count") <= before:
			_fail("step-9 %s no longer plays" % id)
	vfx3.call(&"play", &"hobbling_javelin", c3, far_hob)   # it never gets smoulder
	vfx3.call(&"play", &"riposte", c3, c3)                  # no abilities: damage_taken fallback
	vfx2.call(&"play", &"crushing_blow", c2, t2)
	vfx2.call(&"play", &"whirlwind", c2, c2)
	vfx2.call(&"play", &"riposte", c2, c2)


func _final_checks() -> void:
	for v: Node3D in [vfx, vfx2, vfx3]:
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

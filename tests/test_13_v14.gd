extends SceneTree
## Task 13.V14 Dragon VFX (+ the Frost Dragon ids of 13c.V2): art/vfx/titan_vfx.gd (class TitanVfx, group "titan_vfx").
## Run:  $GODOT --headless --path . -s tests/test_13_v14.gd --fixed-fps 60 --quit-after 1200
## Stand-in units (a tiny Node3D script: team, is_alive, get_model) carry the real dragon models
## (art/units/titans/cinder_dragon, frost_dragon) the way Unit does (unit > visual holder > model). Checks:
##  - group "titan_vfx"; play() true for the 8 ids, false for others; handles() agrees;
##  - auto attach: a model entering the tree after TitanVfx (node_added) and one already there (scan) are attached,
##    the frost one gets the frost look;
##  - breath: play_attack -> breath_released (0.35 s) -> ONE dragon_breath; an explicit play(&"dragon_breath") made
##    at play_attack time waits for the jaw and gives its aim (fan direction); one made just after re-aims, no second
##    breath; a unit without a dragon model breathes at once; the Frost Dragon's is a frost_breath with a 6.5 m reach;
##  - burning_ground lives 3 s (+ fade), hoarfrost 4 s; a patch in the fog (stub FogOfWar) is hidden, one in sight shown;
##    a breath of a hidden dragon is hidden;
##  - trail: emits while the dragon flies near the camera, stops when the camera is > 45 m away, never while hovering;
##  - crash: an explicit dragon_crash at death time waits for crashed(at) and plays once at the impact; frost_crash;
##  - no node, material or mesh is created after _ready, even with 40 patches at once (pools);
##  - after the dragons are freed and 6 s pass: nothing running, nothing alive, every pool full again.
## Prints PASS 13_v14 / FAIL 13_v14: <reason>.

const TASK_ID := "13_v14"
const SCRIPT_PATH := "res://art/vfx/titan_vfx.gd"
const CINDER := "res://art/units/titans/cinder_dragon/cinder_dragon.tscn"
const FROST := "res://art/units/titans/frost_dragon/frost_dragon.tscn"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar alive: bool = true\nvar model: Node3D\nfunc is_alive() -> bool:\n\treturn alive\nfunc get_model() -> Node3D:\n\treturn model\n"
const FOG_SRC := "extends Node\nvar enabled: bool = true\nvar local_team: int = 0\nfunc _ready() -> void:\n\tadd_to_group(&\"fog\")\nfunc is_visible(_team: int, pos: Vector3) -> bool:\n\treturn pos.x < 100.0\n"
const IDS: Array[StringName] = [&"dragon_breath", &"burning_ground", &"dragon_crash", &"dragon_trail",
		&"frost_breath", &"hoarfrost", &"frost_crash", &"frost_trail"]

var world: Node3D
var vfx: Node3D
var cam: Camera3D
var stub: GDScript
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var mats_before: Dictionary = {}
var cinder_unit: Node3D
var cinder: Node3D
var frost_unit: Node3D
var frost: Node3D
var capsule: Node3D          # a unit without a dragon model
var hidden_unit: Node3D      # a hidden (fogged) unit without a model
var aim1 := Vector3(-3.0, 0.0, 3.0)
var aim2 := Vector3(3.0, 0.0, 3.0)
var patch_seen: Variant = null
var patch_fog: Variant = null
var moving := false


func _initialize() -> void:
	world = Node3D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	stub = _script(STUB_SRC)


func _script(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s


func _process(_delta: float) -> bool:
	frame += 1
	if moving and is_instance_valid(cinder_unit):
		cinder_unit.position.x += 5.5 / 60.0
		cinder.call(&"set_moving", 5.5)
	match frame:
		2:
			_setup()
			if not fails.is_empty():
				return _end()
		4:
			if not vfx.call(&"is_attached", cinder):
				_fail("cinder model (added after TitanVfx) not auto-attached")
			if not vfx.call(&"is_attached", frost):
				_fail("frost model (already in the tree) not attached by the scan")
			_check_ids()
		5:
			# Cinder: animation + an explicit call at the same time (it must wait for the jaw, then use its aim).
			cinder.call(&"play_attack")
			vfx.call(&"play", &"dragon_breath", aim1, cinder_unit)
			frost.call(&"play_attack")
		12:
			if _count(&"dragon_breath") != 0:
				_fail("dragon_breath started before breath_released")
		35:
			if _count(&"dragon_breath") != 1:
				_fail("expected 1 dragon_breath after breath_released, got %d" % _count(&"dragon_breath"))
			else:
				var fx: Variant = vfx.call(&"last_fx", &"dragon_breath")
				var want := (aim1 - cinder_unit.global_position)
				want.y = 0.0
				if (fx.dir as Vector3).angle_to(want.normalized()) > 0.05:
					_fail("breath did not take the explicit aim (dir %s)" % fx.dir)
				if absf(fx.reach - 6.0) > 0.01:
					_fail("cinder breath reach %.2f (want 6)" % fx.reach)
			if _count(&"frost_breath") != 1:
				_fail("expected 1 frost_breath, got %d" % _count(&"frost_breath"))
			else:
				var ffx: Variant = vfx.call(&"last_fx", &"frost_breath")
				if absf(ffx.reach - 6.5) > 0.01:
					_fail("frost breath reach %.2f (want 6.5)" % ffx.reach)
			# Just after the release: merges (re-aims), no second breath.
			vfx.call(&"play", &"dragon_breath", aim2, cinder_unit)
		37:
			if _count(&"dragon_breath") != 1:
				_fail("explicit breath right after the release made a second breath")
			else:
				var fx2: Variant = vfx.call(&"last_fx", &"dragon_breath")
				var want2 := aim2 - cinder_unit.global_position
				want2.y = 0.0
				if (fx2.dir as Vector3).angle_to(want2.normalized()) > 0.05:
					_fail("late explicit breath did not re-aim")
				var jet: GeometryInstance3D = fx2.nodes.get(&"jet")
				if jet == null or not jet.visible:
					_fail("breath jet not visible")
		40:
			vfx.call(&"play", &"dragon_breath", capsule.global_position + Vector3(0, 0, 4), capsule)
			vfx.call(&"play", &"dragon_breath", hidden_unit.global_position + Vector3(0, 0, 4), hidden_unit)
		42:
			if _count(&"dragon_breath") != 3:
				_fail("model-less units should breathe at once (dragon_breath count %d)" % _count(&"dragon_breath"))
			var fxh: Variant = vfx.call(&"last_fx", &"dragon_breath")
			if fxh and fxh.unit == hidden_unit:
				for role: StringName in fxh.nodes:
					if (fxh.nodes[role] as GeometryInstance3D).visible:
						_fail("breath of a hidden unit shows its %s" % role)
			else:
				_fail("last breath is not the hidden unit's")
		60:
			vfx.call(&"play", &"burning_ground", Vector3(5, 0, 8), cinder_unit)
			patch_seen = vfx.call(&"last_fx", &"burning_ground")
			vfx.call(&"play", &"hoarfrost", Vector3(10, 0, 8), frost_unit)
			var enemy := _unit(1, Vector3(150, 0, 0), false)
			vfx.call(&"play", &"burning_ground", Vector3(150, 0, 8), enemy)
			patch_fog = vfx.call(&"last_fx", &"burning_ground")
		90:
			var ms: GeometryInstance3D = patch_seen.nodes.get(&"mark") if patch_seen else null
			var mf: GeometryInstance3D = patch_fog.nodes.get(&"mark") if patch_fog else null
			if ms == null or not ms.visible:
				_fail("burning ground in sight not visible")
			if mf == null or mf.visible:
				_fail("burning ground in the fog is visible")
			if not _has_stream_emitting(patch_seen):
				_fail("burning ground has no low flames emitting")
		100:
			var ch := vfx.get_child_count()
			for i in 40:
				vfx.call(&"play", &"burning_ground", Vector3(float(i), 0.0, -20.0), null)
				vfx.call(&"play", &"hoarfrost", Vector3(float(i), 0.0, -30.0), null)
			if vfx.get_child_count() != ch or _materials(vfx) != mats_before:
				_fail("nodes / materials created when the pools ran out")
		120:
			moving = true
			cam.global_position = cinder_unit.global_position + Vector3(0.0, 18.0, 14.0)
		200:
			if not vfx.call(&"trail_emitting", cinder):
				_fail("ember trail not emitting while the dragon flies near the camera")
			if vfx.call(&"trail_emitting", frost):
				_fail("frost trail emitting while the dragon hovers")
			cam.global_position = cinder_unit.global_position + Vector3(0.0, 70.0, 60.0)
		230:
			if vfx.call(&"trail_emitting", cinder):
				_fail("ember trail still emitting with the camera > 45 m away")
			cam.global_position = cinder_unit.global_position + Vector3(0.0, 18.0, 14.0)
		234:
			if not _running(patch_seen):
				_fail("burning ground ended before 3 s")
		260:
			moving = false
			cinder.call(&"set_moving", 0.0)
		294:
			if _running(patch_seen):
				_fail("burning ground still running at 3.9 s")
		300:
			cinder.call(&"play_death")
			cinder_unit.set(&"alive", false)
			vfx.call(&"play", &"dragon_crash", cinder_unit.global_position, cinder_unit)
			frost.call(&"play_death")
			frost_unit.set(&"alive", false)
		330:
			if _count(&"dragon_crash") != 0:
				_fail("dragon_crash played before the model hit the ground")
		380:
			if _count(&"dragon_crash") != 1:
				_fail("expected 1 dragon_crash after crashed(at), got %d" % _count(&"dragon_crash"))
			if _count(&"frost_crash") != 1:
				_fail("expected 1 frost_crash, got %d" % _count(&"frost_crash"))
			if vfx.call(&"trail_emitting", cinder):
				_fail("trail still emitting after the crash")
		430:
			cinder_unit.queue_free()
			frost_unit.queue_free()
			capsule.queue_free()
			hidden_unit.queue_free()
		800:
			_final_checks()
			return _end()
	if frame > 2 and frame % 50 == 0 and vfx and vfx.get_child_count() != children_before:
		_fail("child count changed (%d -> %d) at frame %d" % [children_before, vfx.get_child_count(), frame])
		children_before = vfx.get_child_count()
	return false


func _end() -> bool:
	print("PASS %s" % TASK_ID if fails.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
	return true


func _setup() -> void:
	var fog := Node.new()
	fog.set_script(_script(FOG_SRC))
	world.add_child(fog)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.global_position = Vector3(0.0, 18.0, 14.0)
	cam.current = true
	for p: String in [SCRIPT_PATH, CINDER, FROST]:
		if not ResourceLoader.exists(p):
			_fail("missing %s" % p)
			return
	# The frost dragon is in the tree BEFORE TitanVfx (the deferred scan must find it).
	frost_unit = _unit(0, Vector3(20.0, 0.0, 0.0))
	frost = _dragon(frost_unit, FROST)
	vfx = (load(SCRIPT_PATH) as GDScript).new()
	vfx.name = "TitanVfx"
	world.add_child(vfx)
	if get_first_node_in_group(&"titan_vfx") != vfx:
		_fail("not in group titan_vfx")
	cinder_unit = _unit(0, Vector3(0.0, 0.0, 0.0))
	cinder = _dragon(cinder_unit, CINDER)
	capsule = _unit(0, Vector3(40.0, 0.0, 0.0))
	hidden_unit = _unit(1, Vector3(60.0, 0.0, 0.0), false)
	children_before = vfx.get_child_count()
	mats_before = _materials(vfx)


func _unit(team: int, pos: Vector3, vis: bool = true) -> Node3D:
	var u := Node3D.new()
	u.set_script(stub)
	u.set(&"team", team)
	world.add_child(u)
	u.global_position = pos
	u.visible = vis
	return u


func _dragon(u: Node3D, path: String) -> Node3D:
	var holder := Node3D.new()   # like Unit._visual
	u.add_child(holder)
	var m := (load(path) as PackedScene).instantiate() as Node3D
	holder.add_child(m)
	u.set(&"model", m)
	return m


func _check_ids() -> void:
	for id in IDS:
		if not vfx.call(&"handles", id):
			_fail("handles(%s) false" % id)
	if vfx.call(&"play", &"not_a_titan_effect", Vector3.ZERO, null):
		_fail("play() returned true for an unknown id")
	if vfx.call(&"handles", &"gore_charge"):
		_fail("handles(gore_charge) true")
	# Trail ids return true (the dragons already have trails through attach).
	if not vfx.call(&"play", &"dragon_trail", Vector3.ZERO, cinder_unit):
		_fail("play(dragon_trail) returned false")
	if not vfx.call(&"play", &"frost_trail", null, frost):
		_fail("play(frost_trail) returned false")


func _count(id: StringName) -> int:
	var n := 0
	for a: StringName in vfx.call(&"active_ids"):
		if a == id:
			n += 1
	return n


func _running(fx: Variant) -> bool:
	if fx == null:
		return false
	var ids: Array = vfx.get(&"_fx")
	return ids.has(fx)


func _has_stream_emitting(fx: Variant) -> bool:
	if fx == null:
		return false
	for s: Dictionary in fx.streams:
		if int(s["state"]) == 1 and s["p"] and (s["p"] as GPUParticles3D).emitting:
			return true
	return false


func _materials(n: Node) -> Dictionary:
	var out := {}
	for c in n.get_children():
		if c is GeometryInstance3D and (c as GeometryInstance3D).material_override:
			out[(c as GeometryInstance3D).material_override.get_instance_id()] = true
		if c is GPUParticles3D:
			var gp := c as GPUParticles3D
			out[gp.process_material.get_instance_id()] = true
			if gp.draw_pass_1:
				out[gp.draw_pass_1.get_instance_id()] = true
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			out[(c as MeshInstance3D).mesh.get_instance_id()] = true
	return out


func _final_checks() -> void:
	if vfx.call(&"active_count") != 0:
		_fail("%d effects still running at the end: %s" % [vfx.call(&"active_count"), vfx.call(&"active_ids")])
	if vfx.call(&"live_count") != 0:
		_fail("live_count %d at the end (expected 0)" % vfx.call(&"live_count"))
	var free: Dictionary = vfx.get(&"_free")
	var all: Dictionary = vfx.get(&"_all")
	for pool: StringName in all:
		if (free[pool] as Array).size() != (all[pool] as Array).size():
			_fail("pool %s not full at the end" % pool)
	var sf: Dictionary = vfx.get(&"_stream_free")
	var sa: Dictionary = vfx.get(&"_stream_all")
	for look: StringName in sa:
		if (sf[look] as Array).size() != (sa[look] as Array).size():
			_fail("stream pool %s not full at the end" % look)
	if (vfx.get(&"_att") as Dictionary).size() != 0:
		_fail("freed dragons still attached")
	if vfx.get_child_count() != children_before or _materials(vfx) != mats_before:
		_fail("nodes / materials changed during the run")


func _fail(msg: String) -> void:
	if not fails.has(msg):
		fails.append(msg)

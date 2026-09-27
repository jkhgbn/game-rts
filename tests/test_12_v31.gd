extends SceneTree
## Task 12.V31: epic-beast effects (art/vfx/mapfill_beast_vfx.gd, class MapFillBeastVfx).
## Run:  $GODOT --headless --path . -s tests/test_12_v31.gd --fixed-fps 60 --quit-after 900
## Stand-in units (a tiny Node3D script built here: team, body_height, radius, is_alive) replace Unit; a stub FogOfWar
## (group "fog": the local team 0 sees x < 100) checks the fog rules. Checks:
##  - group "mapfill_beast_vfx"; play() returns true for the 9 beast ids (with a target, without one, `at` as a node)
##    and false for any other id; handles() agrees; an effect starts for each;
##  - no node, material or mesh is created after _ready (everything pooled), even with 40 mauls at once;
##  - dashes / leaps: the impact waits for the beast (a 10 m Gore Charge at 12 m/s has not landed at 0.7 s, has at
##    1.1 s, where the beast stopped); a charge stopped early (hits its victim at 5 m) lands there, before its
##    estimated time; a Pounce lands; a Roc freed mid-dive lands at once without errors;
##  - variant B (meta beast_variant = 1) uses the dark Duskwing feather swirl for updraft;
##  - fog: a maul on a hidden victim shows nothing; beast_spawn in the fog still shows its birds, not its leaves;
##  - the real call sites are wired to "mapfill_vfx" -> play(id, at, target) (grep of the 2 scripts), and if
##    MapFillVfx (12.V25) exists and mentions this script, it forwards a beast id to a MapFillBeastVfx child;
##  - at 6 s nothing is left (no burst / trail alive, every pooled piece hidden, every pool full again).
## Prints PASS 12_v31 / FAIL 12_v31: <reason>.

const TASK_ID := "12_v31"
const SCRIPT_PATH := "res://art/vfx/mapfill_beast_vfx.gd"
const MAPFILL_PATH := "res://art/vfx/mapfill_vfx.gd"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.8\nvar radius: float = 0.45\nvar alive: bool = true\nfunc is_alive() -> bool:\n\treturn alive\n"
const FOG_SRC := "extends Node\nvar enabled: bool = true\nvar local_team: int = 0\nfunc _ready() -> void:\n\tadd_to_group(&\"fog\")\nfunc is_visible(_team: int, pos: Vector3) -> bool:\n\treturn pos.x < 100.0\n"
const IDS: Array[StringName] = [&"gore_charge", &"gale_swoop", &"shrieking_dive", &"updraft", &"pounce",
		&"hamstring", &"maul", &"rending_roar", &"beast_spawn"]

var world: Node3D
var vfx: Node3D
var stub: GDScript
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var mats_before: Dictionary = {}
var tusker_a: Node3D      # charges 10 m along +X at 12 m/s
var tusker_b: Node3D      # charges toward 12 m but stops at 5 m (hit its victim)
var wolf: Node3D          # pounces 8 m along +Z at 16 m/s
var roc_a: Node3D         # freed mid-dive
var roc_b: Node3D         # variant B (Duskwing) for updraft
var bear: Node3D
var victim: Node3D
var hidden_victim: Node3D
var t0 := 0


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
	var dt := 1.0 / 60.0
	if t0 > 0 and frame > t0:
		var tt := float(frame - t0) / 60.0
		if tt <= 10.0 / 12.0 + dt * 0.5:
			tusker_a.position.x = minf(10.0, tusker_a.position.x + 12.0 * dt)
		if tt <= 0.42 and is_instance_valid(tusker_b):
			tusker_b.position.x = minf(5.0, tusker_b.position.x + 12.0 * dt)
		if tt <= 0.5:
			wolf.position.z = minf(38.0, wolf.position.z + 16.0 * dt)
		if is_instance_valid(roc_a):
			roc_a.position.x += 16.0 * dt   # still diving when it is freed at 0.3 s
	match frame:
		2:
			_setup()
		3:
			t0 = frame
			_play_all()
		21:    # 0.3 s: the Roc dies mid-dive (0.56 s dive)
			if _landed(roc_a):
				_fail("gale_swoop landed before the Roc arrived")
			roc_a.queue_free()
		24:
			if not _landed_id(&"gale_swoop"):
				_fail("gale_swoop did not land when its Roc was freed")
		27:    # 0.4 s
			if _landed(tusker_a):
				_fail("10 m gore_charge landed at 0.4 s")
		45:    # 0.7 s
			if _landed(tusker_a):
				_fail("10 m gore_charge landed at 0.7 s (the beast is still running)")
			if not _landed(tusker_b):
				_fail("gore_charge stopped at 5 m did not land at 0.7 s")
			elif absf(_land_pos(tusker_b).x - 5.0) > 0.4:
				_fail("early-stop charge landed at x %.2f (expected 5)" % _land_pos(tusker_b).x)
			_check_variant()
		69:    # 1.1 s
			if not _landed(tusker_a):
				_fail("10 m gore_charge not landed at 1.1 s")
			elif absf(_land_pos(tusker_a).x - 10.0) > 0.4:
				_fail("gore_charge landed at x %.2f (expected 10)" % _land_pos(tusker_a).x)
			if not _landed(wolf):
				_fail("pounce not landed at 1.1 s")
			_check_fog()
		93:    # 1.5 s: pool exhaustion
			var ch := vfx.get_child_count()
			for i in 40:
				vfx.call(&"play", &"maul", Vector3(float(i), 0.0, 5.0), victim)
			if vfx.get_child_count() != ch or _materials(vfx) != mats_before:
				_fail("nodes / materials created when the pools ran out")
			_check_mapfill()
		363:   # 6.0 s
			_final_checks()
			print("PASS %s" % TASK_ID if fails.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
			return true
	return false


func _setup() -> void:
	var fog := Node.new()
	fog.set_script(_script(FOG_SRC))
	world.add_child(fog)
	if not ResourceLoader.exists(SCRIPT_PATH):
		_fail("missing %s" % SCRIPT_PATH)
		return
	vfx = (load(SCRIPT_PATH) as GDScript).new()
	vfx.name = "BeastVfx"
	world.add_child(vfx)
	if get_first_node_in_group(&"mapfill_beast_vfx") != vfx:
		_fail("not in group mapfill_beast_vfx")
	if vfx.is_in_group(&"mapfill_vfx"):
		_fail("must not join group mapfill_vfx (MapFillVfx owns it)")
	tusker_a = _unit(2, Vector3(0.0, 0.0, 0.0), 2.0, 1.0)
	tusker_b = _unit(2, Vector3(0.0, 0.0, 10.0), 2.3, 1.0)
	tusker_b.set_meta(&"beast_variant", 1)
	wolf = _unit(2, Vector3(20.0, 0.0, 30.0), 1.8, 0.8)
	roc_a = _unit(2, Vector3(40.0, 0.0, 0.0), 3.2, 0.9)
	roc_b = _unit(2, Vector3(40.0, 0.0, 20.0), 3.2, 0.9)
	roc_b.set_meta(&"beast_variant", 1)
	bear = _unit(2, Vector3(60.0, 0.0, 0.0), 2.6, 1.1)
	victim = _unit(0, Vector3(62.0, 0.0, 0.0), 1.8, 0.45)
	hidden_victim = _unit(0, Vector3(70.0, 0.0, 0.0), 1.8, 0.45)
	hidden_victim.visible = false
	children_before = vfx.get_child_count()
	mats_before = _materials(vfx)


func _unit(team: int, pos: Vector3, h: float, r: float) -> Node3D:
	var u := Node3D.new()
	u.set_script(stub)
	u.set(&"team", team)
	u.set(&"body_height", h)
	u.set(&"radius", r)
	world.add_child(u)
	u.global_position = pos
	return u


func _play(id: StringName, at: Variant, target: Variant) -> void:
	var before: int = vfx.call(&"active_count")
	var ok: bool = vfx.call(&"play", id, at, target)
	if not ok:
		_fail("play(%s) returned false" % id)
	if int(vfx.call(&"active_count")) <= before:
		_fail("%s (target %s) started nothing" % [id, target])


func _play_all() -> void:
	if vfx == null:
		return
	# Unknown ids: false, nothing starts.
	var n0: int = vfx.call(&"active_count")
	for bad: StringName in [&"spore_burst", &"capture_done", &"not_an_effect"]:
		if bool(vfx.call(&"play", bad, Vector3.ZERO, victim)):
			_fail("play(%s) returned true" % bad)
		if bool(vfx.call(&"handles", bad)):
			_fail("handles(%s) is true" % bad)
	if int(vfx.call(&"active_count")) != n0:
		_fail("an unknown id started an effect")
	for id in IDS:
		if not bool(vfx.call(&"handles", id)):
			_fail("handles(%s) is false" % id)
	# The real call shapes (creature_abilities.gd / epic_beasts.gd).
	_play(&"gore_charge", Vector3(10.0, 0.0, 0.0), tusker_a)
	_play(&"gore_charge", Vector3(12.0, 0.0, 10.0), tusker_b)
	_play(&"pounce", Vector3(20.0, 0.0, 38.0), wolf)
	_play(&"gale_swoop", Vector3(49.0, 0.0, 0.0), roc_a)
	_play(&"shrieking_dive", Vector3(46.0, 0.0, 20.0), roc_b)
	_play(&"updraft", roc_b.global_position, roc_b)
	_play(&"maul", victim.global_position, victim)
	_play(&"hamstring", victim.global_position, victim)
	_play(&"rending_roar", bear.global_position, bear)
	_play(&"beast_spawn", Vector3(80.0, 0.0, 40.0), bear)
	# No target (null), and `at` given as a node.
	for id in IDS:
		_play(id, Vector3(-20.0, 0.0, -20.0 - float(IDS.find(id)) * 8.0), null)
	_play(&"rending_roar", bear, null)
	if vfx.get_child_count() != children_before:
		_fail("nodes created at runtime (%d -> %d)" % [children_before, vfx.get_child_count()])
	if _materials(vfx) != mats_before:
		_fail("materials / meshes created at runtime")
	if int(vfx.call(&"live_count")) == 0:
		_fail("nothing visible after playing the 9 effects")


func _fx_of(target: Node3D, id: StringName = &"") -> Object:
	for fx: Object in vfx.get(&"_fx"):
		if fx.get(&"target") == target and (id == &"" or fx.get(&"id") == id):
			return fx
	return null


func _landed(target: Node3D) -> bool:
	var fx := _fx_of(target)
	return fx == null or bool(fx.get(&"landed"))


## True when every running effect `id` with a (possibly freed) target has landed.
func _landed_id(id: StringName) -> bool:
	for fx: Object in vfx.get(&"_fx"):
		if fx.get(&"id") == id and bool(fx.get(&"has_target")) and not bool(fx.get(&"landed")):
			return false
	return true


func _land_pos(target: Node3D) -> Vector3:
	var fx := _fx_of(target)
	return fx.get(&"land_pos") if fx else Vector3.INF


func _check_variant() -> void:
	var fx := _fx_of(roc_b, &"updraft")
	if fx == null:
		_fail("updraft on the Duskwing ended before 0.7 s")
		return
	var used := false
	for tr: Dictionary in fx.get(&"trails"):
		if tr["look"] == &"feather_swirl_b" and int(tr["state"]) == 1:
			used = true
	if not used:
		_fail("variant B updraft does not use the dark feather swirl")


func _check_fog() -> void:
	# A maul on a hidden victim: nothing of it shows.
	var before: int = vfx.call(&"active_count")
	vfx.call(&"play", &"maul", hidden_victim.global_position, hidden_victim)
	if int(vfx.call(&"active_count")) <= before:
		_fail("maul on a hidden victim not started")
	else:
		var fx := _fx_of(hidden_victim, &"maul")
		for d: Object in fx.get(&"pieces"):
			if (d.get(&"n") as Node3D).visible:
				_fail("maul piece visible on a hidden victim")
				break
	# beast_spawn in the fog (x 300): the birds show, the leaves do not.
	var bursts: Dictionary = vfx.get(&"_bursts")
	var nxt: Dictionary = vfx.get(&"_burst_next")
	var flock_i: int = nxt[&"flock"]
	var leaves_i: int = nxt[&"lair_leaves"]
	vfx.call(&"play", &"beast_spawn", Vector3(300.0, 0.0, 0.0), null)
	var flock: GPUParticles3D = (bursts[&"flock"] as Array)[flock_i]
	var leaves: GPUParticles3D = (bursts[&"lair_leaves"] as Array)[leaves_i]
	if not flock.visible or flock.global_position.x < 290.0:
		_fail("beast_spawn birds hidden by the fog")
	if int(nxt[&"lair_leaves"]) != leaves_i or (leaves.visible and leaves.global_position.x > 290.0):
		_fail("beast_spawn leaves shown in the fog")


## The real callers send (id, Vector3, target) to the first node of group "mapfill_vfx"; MapFillVfx (12.V25) forwards
## beast ids here once it is wired.
func _check_mapfill() -> void:
	for path: String in ["res://scripts/units/creature_abilities.gd", "res://scripts/world/epic_beasts.gd"]:
		var src := FileAccess.get_file_as_string(path)
		if src.find("\"mapfill_vfx\"") < 0 or src.find("&\"play\", id, at, target") < 0:
			_fail("%s no longer calls mapfill_vfx.play(id, at, target)" % path)
	if not ResourceLoader.exists(MAPFILL_PATH):
		print("  note: %s not there yet: forwarding not checked" % MAPFILL_PATH)
		return
	if FileAccess.get_file_as_string(MAPFILL_PATH).find("mapfill_beast_vfx") < 0:
		print("  note: MapFillVfx does not load mapfill_beast_vfx.gd yet: forwarding not checked")
		return
	var mf := (load(MAPFILL_PATH) as GDScript).new() as Node
	world.add_child(mf)
	var ok: Variant = mf.call(&"play", &"maul", victim.global_position, victim)
	var child: Node = null
	for c in mf.get_children():
		if c.get_script() != null and (c.get_script() as Script).resource_path == SCRIPT_PATH:
			child = c
	if child == null:
		_fail("MapFillVfx did not create a MapFillBeastVfx child")
	elif int(child.call(&"active_count")) < 1:
		_fail("MapFillVfx did not forward maul (play returned %s)" % [ok])
	mf.queue_free()


func _final_checks() -> void:
	if vfx == null:
		return
	if int(vfx.call(&"active_count")) != 0:
		_fail("effects still running at 6 s: %s" % [vfx.call(&"active_ids")])
	if int(vfx.call(&"live_count")) != 0:
		_fail("pieces / bursts / trails still alive at 6 s (%d)" % vfx.call(&"live_count"))
	for c in vfx.get_children():
		if c is GPUParticles3D and (c as GPUParticles3D).visible:
			_fail("emitter %s still shown at 6 s" % c.name)
			break
		if c is MeshInstance3D and (c as MeshInstance3D).visible:
			_fail("piece %s still visible at 6 s" % c.name)
			break
	var free: Dictionary = vfx.get(&"_free")
	var sizes: Dictionary = vfx.get(&"POOL_SIZES")
	for pool: StringName in sizes:
		if (free[pool] as Array).size() != int(sizes[pool]):
			_fail("pool %s has %d free of %d (leak)" % [pool, (free[pool] as Array).size(), sizes[pool]])
	var tfree: Dictionary = vfx.get(&"_trail_free")
	var trails: Dictionary = vfx.get(&"TRAILS")
	for look: StringName in trails:
		if (tfree[look] as Array).size() != int((trails[look] as Array)[3]):
			_fail("trail pool %s not full again (leak)" % look)
	if vfx.get_child_count() != children_before:
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

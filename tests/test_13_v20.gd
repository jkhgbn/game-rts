extends SceneTree
## Task 13.V20 Cavalry VFX: art/vfx/cavalry_vfx.gd (class CavalryVfx, group "cavalry_vfx").
## Run:  $GODOT --headless --path . -s tests/test_13_v20.gd --fixed-fps 60 --quit-after 1200
## Stand-in units (a tiny Node3D script: team, kingdom, is_alive, is_titan) and a stand-in MountRider child
## (is_riding). Checks:
##  - group "cavalry_vfx"; play() true for the 7 ids, false for others; handles() agrees;
##  - charge: streak + shock ring + flash show, kingdom-tinted sparks burst (shadow pool for a Shadow unit), a titan's
##    ring is bigger; the same charge twice in a frame = one; a charge of a hidden unit and one in the fog are hidden;
##  - lifesteal: 3 wisps (4 for a titan) that fly from the victim into the drainer; one per drainer per 0.25 s; at most
##    12 at once;
##  - mount: the body puff is out AT ONCE (t = 0, where the rider's hop starts inside the mount) and opaque from its
##    first frame; dismount: the body puff waits for the hop-off (~0.2 s); thrown: the skid dust waits for the landing;
##  - speed_lines: emit for a fast rider near the camera only (not slow, not > 45 m away), one tracker per unit, stop
##    when the MountRider stops riding, on speed_lines_off and when the unit is freed;
##  - no node, material or mesh is created after _ready, even with 60 charges + 60 drains + 30 puffs (pools);
##  - after the units are freed and ~4 s pass: nothing running, nothing alive, every pool full again.
## Prints PASS 13_v20 / FAIL 13_v20: <reason>.

const TASK_ID := "13_v20"
const SCRIPT_PATH := "res://art/vfx/cavalry_vfx.gd"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar kingdom: StringName = &\"neutral\"\nvar alive: bool = true\nvar titan: bool = false\nfunc is_alive() -> bool:\n\treturn alive\nfunc is_titan() -> bool:\n\treturn titan\n"
const RIDER_SRC := "extends Node\nvar riding: bool = true\nfunc is_riding() -> bool:\n\treturn riding\n"
const FOG_SRC := "extends Node\nvar enabled: bool = true\nvar local_team: int = 0\nfunc _ready() -> void:\n\tadd_to_group(&\"fog\")\nfunc is_visible(_team: int, pos: Vector3) -> bool:\n\treturn pos.x < 100.0\n"
const IDS: Array[StringName] = [&"charge", &"lifesteal", &"mount", &"dismount", &"thrown", &"speed_lines",
		&"speed_lines_off"]

var world: Node3D
var vfx: Node3D
var cam: Camera3D
var stub: GDScript
var rider_stub: GDScript
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var mats_before: Dictionary = {}
var units: Array[Node3D] = []
var charger: Node3D
var victim: Node3D
var knight: Node3D
var knight_victim: Node3D
var hidden_unit: Node3D
var fx_charge: Variant = null
var fx_knight: Variant = null
var fx_hidden: Variant = null
var fx_fog: Variant = null
var fx_seen: Variant = null
var fx_drain: Variant = null
var drain_d0 := 0.0
var fx_dismount: Variant = null
var fx_thrown: Variant = null
var fast: Node3D
var slow: Node3D
var far: Node3D
var fast_mr: Node


func _initialize() -> void:
	world = Node3D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	stub = _script(STUB_SRC)
	rider_stub = _script(RIDER_SRC)


func _script(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s


func _process(_delta: float) -> bool:
	frame += 1
	var dt := 1.0 / 60.0
	if is_instance_valid(fast):
		fast.position.x += 7.0 * dt
	if is_instance_valid(slow):
		slow.position.x += 2.0 * dt
	if is_instance_valid(far):
		far.position.x += 7.0 * dt
	match frame:
		2:
			_setup()
			if not fails.is_empty():
				return _end()
		4:
			_check_ids()
			vfx.call(&"play", &"charge", victim, charger)
			vfx.call(&"play", &"charge", victim, charger)   # same event twice: merged
			fx_charge = vfx.call(&"last_fx", &"charge")
			vfx.call(&"play", &"charge", knight_victim, knight)
			fx_knight = vfx.call(&"last_fx", &"charge")
			vfx.call(&"play", &"charge", Vector3(22.0, 0.0, 1.0), hidden_unit)
			fx_hidden = vfx.call(&"last_fx", &"charge")
			vfx.call(&"play", &"charge", Vector3(150.0, 0.0, 0.0), null)
			fx_fog = vfx.call(&"last_fx", &"charge")
			vfx.call(&"play", &"charge", Vector3(30.0, 0.0, 0.0), null)
			fx_seen = vfx.call(&"last_fx", &"charge")
			if _count(&"charge") != 5:
				_fail("expected 5 charges (one merged), got %d" % _count(&"charge"))
			if fx_charge == null or fx_charge.kingdom != &"shadow":
				_fail("charge kingdom is not shadow")
			if fx_charge and fx_charge.big:
				_fail("a cavalry charge is marked big")
			if fx_knight == null or not fx_knight.big:
				_fail("the titan's charge is not big")
		6:
			var st: GeometryInstance3D = fx_charge.nodes.get(&"streak") if fx_charge else null
			if st == null or not st.visible:
				_fail("charge streak not visible at once")
			var sh: GeometryInstance3D = fx_charge.nodes.get(&"shock") if fx_charge else null
			if sh and sh.visible:
				_fail("charge ring visible before the strike frame (0.10 s)")
		13:
			if not _burst_live(&"charge_sparks/shadow"):
				_fail("no shadow sparks burst on the charge")
			for role: StringName in [&"streak", &"core", &"shock", &"flash"]:
				var n: GeometryInstance3D = fx_charge.nodes.get(role) if fx_charge else null
				if n == null or not n.visible:
					_fail("charge %s not visible" % role)
			var s1: GeometryInstance3D = fx_charge.nodes.get(&"shock") if fx_charge else null
			var s2: GeometryInstance3D = fx_knight.nodes.get(&"shock") if fx_knight else null
			if s1 and s2 and s2.transform.basis.x.length() <= s1.transform.basis.x.length() + 0.05:
				_fail("titan shock ring not bigger (%.2f vs %.2f)" % [s2.transform.basis.x.length(),
						s1.transform.basis.x.length()])
			for f: Variant in [fx_hidden, fx_fog]:
				if f:
					for role: StringName in f.nodes:
						if (f.nodes[role] as GeometryInstance3D).visible:
							_fail("charge %s visible under fog / on a hidden unit" % role)
			var sn: GeometryInstance3D = fx_seen.nodes.get(&"shock") if fx_seen else null
			if sn == null or not sn.visible:
				_fail("point charge in sight not visible")
		10:
			vfx.call(&"play", &"lifesteal", victim, charger)
			fx_drain = vfx.call(&"last_fx", &"lifesteal")
			vfx.call(&"play", &"lifesteal", victim, charger)   # 0 s later: merged
			vfx.call(&"play", &"lifesteal", knight_victim, knight)
			if _count(&"lifesteal") != 2:
				_fail("expected 2 lifesteals (one per drainer), got %d" % _count(&"lifesteal"))
			if fx_drain == null or fx_drain.wisps.size() != 3:
				_fail("cavalry lifesteal should have 3 wisps")
			var fk: Variant = vfx.call(&"last_fx", &"lifesteal")
			if fk == null or fk.wisps.size() != 4:
				_fail("titan lifesteal should have 4 wisps")
			drain_d0 = (fx_drain.from - fx_drain.to).length() if fx_drain else 0.0
		14:
			# 0.2 s after its first try (still inside the gap): ignored.
			vfx.call(&"play", &"lifesteal", victim, charger)
			if _count(&"lifesteal") != 2:
				_fail("lifesteal inside the 0.25 s gap was not merged")
		28:
			var n0: GeometryInstance3D = fx_drain.nodes.get(&"w0") if fx_drain else null
			if n0 == null or not n0.visible:
				_fail("lifesteal wisp 0 not visible in flight")
			elif drain_d0 > 0.0 and (n0.global_position - fx_drain.to).length() > drain_d0 * 0.8:
				_fail("wisp 0 is not flying into the drainer")
		40:
			for i in 20:
				var d := _unit(0, Vector3(-30.0 + float(i) * 1.5, 0.0, 10.0), &"shadow")
				vfx.call(&"play", &"lifesteal", d.global_position + Vector3(0, 0, 1.5), d)
			if _count(&"lifesteal") > 12:
				_fail("more than 12 lifesteals at once (%d)" % _count(&"lifesteal"))
		60:
			var r1 := _unit(0, Vector3(40.0, 0.0, 0.0), &"fire")
			var before := _live_of(&"mount_puff")
			vfx.call(&"play", &"mount", r1, r1)
			var pp: Variant = _newest_live(&"mount_puff", before)
			if pp == null:
				_fail("mount puff not out at t = 0 (it must hide the hop start inside the mount)")
			elif (pp as GPUParticles3D).global_position.distance_to(Vector3(40.0, 0.95, 0.0)) > 0.3:
				_fail("mount puff not on the mount body (%s)" % (pp as GPUParticles3D).global_position)
			else:
				var pm: ParticleProcessMaterial = (pp as GPUParticles3D).process_material
				var g: Gradient = (pm.color_ramp as GradientTexture1D).gradient
				if g.sample(0.0).a < 0.8:
					_fail("mount puff not opaque from its first frame (alpha %.2f)" % g.sample(0.0).a)
			if not _burst_live(&"hop_puff"):
				_fail("no hop puff on the flank at mount")
			var r2 := _unit(0, Vector3(46.0, 0.0, 0.0), &"ice")
			vfx.call(&"play", &"dismount", r2, r2)
			fx_dismount = vfx.call(&"last_fx", &"dismount")
			var r3 := _unit(0, Vector3(52.0, 0.0, 0.0), &"nature")
			vfx.call(&"play", &"thrown", r3, r3)
			fx_thrown = vfx.call(&"last_fx", &"thrown")
		66:
			if not _burst_live(&"mount_glints/fire"):
				_fail("no fire glints on a Fire mount")
			if _burst_done(fx_dismount, &"mount_puff"):
				_fail("dismount body puff went off before the hop-off (0.1 s)")
			if _burst_done(fx_thrown, &"thrown_dust"):
				_fail("thrown skid dust went off before the landing (0.1 s)")
			if not _burst_done(fx_thrown, &"hop_puff"):
				_fail("thrown jolt puff missing at the start")
		80:
			if not _burst_done(fx_dismount, &"mount_puff"):
				_fail("dismount body puff missing at 0.33 s")
			if not _burst_done(fx_thrown, &"thrown_dust"):
				_fail("thrown skid dust missing at 0.33 s")
		90:
			fast = _unit(0, Vector3(-10.0, 0.0, -2.0), &"fire")
			fast_mr = Node.new()
			fast_mr.set_script(rider_stub)
			fast_mr.name = "MountRider"
			fast.add_child(fast_mr)
			slow = _unit(0, Vector3(-10.0, 0.0, 2.0), &"ice")
			far = _unit(0, Vector3(200.0, 0.0, 0.0), &"nature")
			for u: Node3D in [fast, slow, far]:
				vfx.call(&"play", &"speed_lines", null, u)
			vfx.call(&"play", &"speed_lines", null, fast)
			if int(vfx.call(&"rider_count")) != 3:
				_fail("expected 3 rider trackers, got %d" % int(vfx.call(&"rider_count")))
		130:
			if not vfx.call(&"lines_emitting", fast):
				_fail("speed lines not emitting for a fast rider near the camera")
			if vfx.call(&"lines_emitting", slow):
				_fail("speed lines emitting for a 2 m/s rider")
			if vfx.call(&"lines_emitting", far):
				_fail("speed lines emitting for a rider > 45 m from the camera")
			fast_mr.set(&"riding", false)
		160:
			if vfx.call(&"lines_emitting", fast):
				_fail("speed lines still emitting after the MountRider stopped riding")
			if int(vfx.call(&"rider_count")) != 2:
				_fail("tracker of the dismounted rider not removed (%d)" % int(vfx.call(&"rider_count")))
			vfx.call(&"play", &"speed_lines_off", null, slow)
			if int(vfx.call(&"rider_count")) != 1:
				_fail("speed_lines_off did not remove the tracker")
			far.queue_free()
		190:
			if int(vfx.call(&"rider_count")) != 0:
				_fail("tracker of a freed unit not removed")
		200:
			var ch := vfx.get_child_count()
			for i in 60:
				var a := _unit(i % 2, Vector3(float(i), 0.0, -40.0), &"fire")
				vfx.call(&"play", &"charge", a.global_position + Vector3(0, 0, 1.5), a)
				vfx.call(&"play", &"lifesteal", a.global_position + Vector3(0, 0, 1.5), a)
				if i < 30:
					vfx.call(&"play", &"mount" if i % 3 == 0 else (&"dismount" if i % 3 == 1 else &"thrown"), a, a)
			if vfx.get_child_count() != ch or _materials(vfx) != mats_before:
				_fail("nodes / materials created when the pools ran out")
		220:
			for u in units:
				if is_instance_valid(u):
					u.queue_free()
			for u: Node3D in [fast, slow]:
				if is_instance_valid(u):
					u.queue_free()
		480:
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
	if not ResourceLoader.exists(SCRIPT_PATH):
		_fail("missing %s" % SCRIPT_PATH)
		return
	var fog := Node.new()
	fog.set_script(_script(FOG_SRC))
	world.add_child(fog)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.global_position = Vector3(0.0, 18.0, 14.0)
	cam.current = true
	vfx = (load(SCRIPT_PATH) as GDScript).new()
	vfx.name = "CavalryVfx"
	world.add_child(vfx)
	if get_first_node_in_group(&"cavalry_vfx") != vfx:
		_fail("not in group cavalry_vfx")
	charger = _unit(0, Vector3(0.0, 0.0, 0.0), &"shadow")
	victim = _unit(1, Vector3(0.0, 0.0, 1.8), &"fire")
	knight = _unit(0, Vector3(10.0, 0.0, 0.0), &"shadow")
	knight.set(&"titan", true)
	knight_victim = _unit(1, Vector3(10.0, 0.0, 2.0), &"fire")
	hidden_unit = _unit(1, Vector3(20.0, 0.0, 0.0), &"fire", false)
	children_before = vfx.get_child_count()
	mats_before = _materials(vfx)


func _unit(team: int, pos: Vector3, kingdom: StringName, vis: bool = true) -> Node3D:
	var u := Node3D.new()
	u.set_script(stub)
	u.set(&"team", team)
	u.set(&"kingdom", kingdom)
	world.add_child(u)
	u.global_position = pos
	u.visible = vis
	units.append(u)
	return u


func _check_ids() -> void:
	for id in IDS:
		if not vfx.call(&"handles", id):
			_fail("handles(%s) false" % id)
	if vfx.call(&"play", &"not_a_cavalry_effect", Vector3.ZERO, null):
		_fail("play() returned true for an unknown id")
	if vfx.call(&"handles", &"dragon_breath"):
		_fail("handles(dragon_breath) true")


func _count(id: StringName) -> int:
	var n := 0
	for a: StringName in vfx.call(&"active_ids"):
		if a == id:
			n += 1
	return n


func _burst_live(key: StringName) -> bool:
	var pool: Array = (vfx.get(&"_bursts") as Dictionary).get(key, [])
	for b: Dictionary in vfx.get(&"_live_bursts"):
		if pool.has(b["p"]) and (b["p"] as GPUParticles3D).visible:
			return true
	return false


func _live_of(key: StringName) -> Array:
	var pool: Array = (vfx.get(&"_bursts") as Dictionary).get(key, [])
	var out: Array = []
	for b: Dictionary in vfx.get(&"_live_bursts"):
		if pool.has(b["p"]):
			out.append(b["p"])
	return out


## The burst of `key` that went live since `before` was taken (or null).
func _newest_live(key: StringName, before: Array) -> Variant:
	for p: Variant in _live_of(key):
		if not before.has(p):
			return p
	var lb: Array = vfx.get(&"_live_bursts")
	if not lb.is_empty():
		var p2: Variant = (lb[lb.size() - 1] as Dictionary)["p"]
		var pool: Array = (vfx.get(&"_bursts") as Dictionary).get(key, [])
		if pool.has(p2):
			return p2   # a pool reused a live emitter (restart)
	return null


func _burst_done(fx: Variant, look: StringName) -> bool:
	if fx == null:
		return false
	for b: Dictionary in fx.bursts:
		if b["look"] == look:
			return bool(b["done"])
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
	if int(vfx.call(&"rider_count")) != 0:
		_fail("rider trackers left at the end")
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
	if vfx.get_child_count() != children_before or _materials(vfx) != mats_before:
		_fail("nodes / materials changed during the run")


func _fail(msg: String) -> void:
	if not fails.has(msg):
		fails.append(msg)

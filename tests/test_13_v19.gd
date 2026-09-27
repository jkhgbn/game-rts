extends SceneTree
## Task 13.V19 Titan VFX (non-dragon): art/vfx/titan_ground_vfx.gd (class TitanGroundVfx), the family node TitanVfx
## (art/vfx/titan_vfx.gd) creates and forwards to.
## Run:  $GODOT --headless --path . -s tests/test_13_v19.gd --fixed-fps 60 --quit-after 1600
## Stand-in units (a tiny Node3D script: team, is_alive, get_model) carry the real titan models (War Mammoth with its
## howdah, Elder Treant, Nightmare Knight) the way Unit does (unit > visual holder > model). Checks:
##  - TitanVfx has the "TitanGroundVfx" child; handles() / play() true for the 8 new ids (and the 8 dragon ids), false
##    for others and for charge_impact (the Knight's impact is CavalryVfx's); the Knight model is NOT hooked;
##  - auto attach: a mammoth entering after TitanVfx (node_added) and a treant already there (scan);
##  - frost_aura: one per mammoth, radius 5, follows it, hidden with it, rime mist emitting near the camera, released
##    and gone ~1 s after death;
##  - trample: play_trample -> trample_stomped (0.2 s) -> ONE trample (an explicit call at the same time merges);
##    a unit without the model tramples at once;
##  - howdah_bolt: play_howdah_shot + explicit call -> one bolt at the release (not before) aimed at the target, it
##    lands; play_howdah_shot alone still shoots a bolt;
##  - root_morph: set_rooted(true) -> a root bed with dust streams within 0.2 s; rooted -> grove pulses every 4 s
##    (>= 2 seen); play_volley + explicit thorn_volley -> one volley of 6 thorns at the release, aimed at the target;
##    uprooting releases the bed and it ends;
##  - sapling_sprout lives ~2.4 s; one owned by a fogged enemy at a fogged point is hidden;
##  - knight_knockback: the skid follows the knocked unit (stretches to its slide), a point slides 3 m by itself;
##  - no node, material or mesh is created after _ready, even with 40 calls of every id at once (pools);
##  - after everything is freed and 6 s pass: nothing running, nothing alive, every pool full again, nothing attached.
## Prints PASS 13_v19 / FAIL 13_v19: <reason>.

const TASK_ID := "13_v19"
const SCRIPT_PATH := "res://art/vfx/titan_vfx.gd"
const MAMMOTH := "res://art/units/titans/war_mammoth/war_mammoth.tscn"
const TREANT := "res://art/units/titans/elder_treant/elder_treant.tscn"
const KNIGHT := "res://art/units/titans/nightmare_knight/nightmare_knight.tscn"
const STUB_SRC := "extends Node3D\nvar team: int = 0\nvar alive: bool = true\nvar model: Node3D\nfunc is_alive() -> bool:\n\treturn alive\nfunc get_model() -> Node3D:\n\treturn model\n"
const FOG_SRC := "extends Node\nvar enabled: bool = true\nvar local_team: int = 0\nfunc _ready() -> void:\n\tadd_to_group(&\"fog\")\nfunc is_visible(_team: int, pos: Vector3) -> bool:\n\treturn pos.x < 100.0\n"
const NEW_IDS: Array[StringName] = [&"frost_aura", &"trample", &"howdah_bolt", &"root_morph", &"grove_pulse",
		&"thorn_volley", &"sapling_sprout", &"knight_knockback"]
const OLD_IDS: Array[StringName] = [&"dragon_breath", &"burning_ground", &"dragon_crash", &"dragon_trail",
		&"frost_breath", &"hoarfrost", &"frost_crash", &"frost_trail"]

var world: Node3D
var vfx: Node3D
var fam: Node3D
var cam: Camera3D
var stub: GDScript
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var fam_children_before := 0
var mats_before: Dictionary = {}
var mammoth_unit: Node3D
var mammoth: Node3D
var treant_unit: Node3D
var treant: Node3D
var knight_unit: Node3D
var knight: Node3D
var plain: Node3D          # a unit without a titan model
var target: Node3D         # the howdah / volley target
var victim: Node3D         # the knocked unit
var enemy_far: Node3D      # a fogged enemy (x 150)
var pulses: Dictionary = {}
var trample_before := 0
var bolts_before := 0
var sprout_fx: Variant = null
var sprout_fog: Variant = null
var knock_fx: Variant = null
var knock_pt_fx: Variant = null
var bed_fx: Variant = null


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
	if fam and frame > 150 and frame < 700:
		for fx: Variant in fam.get(&"_fx"):
			if fx.id == &"grove_pulse":
				pulses[fx] = true
	if frame >= 220 and frame <= 241 and is_instance_valid(victim):
		victim.position.x += 3.0 / 21.0
	match frame:
		2:
			_setup()
			if not fails.is_empty():
				return _end()
		4:
			_check_ids()
			if not fam.call(&"is_attached", mammoth):
				_fail("mammoth (added after TitanVfx) not auto-attached")
			if not fam.call(&"is_attached", treant):
				_fail("treant (already in the tree) not attached by the scan")
			if fam.call(&"is_attached", knight) or vfx.call(&"is_attached", knight):
				_fail("the Knight model is hooked (its charge impact belongs to CavalryVfx)")
		8:
			var aura: Variant = fam.call(&"aura_of", mammoth)
			if aura == null:
				_fail("no frost_aura for the mammoth")
			else:
				var ring: GeometryInstance3D = aura.nodes.get(&"ring")
				if ring == null or not ring.visible:
					_fail("aura ring not visible")
				elif absf(ring.transform.basis.x.length() - 5.0) > 0.01:
					_fail("aura radius %.2f (want 5)" % ring.transform.basis.x.length())
			if _count(&"frost_aura") != 1:
				_fail("expected 1 frost_aura, got %d" % _count(&"frost_aura"))
			vfx.call(&"play", &"frost_aura", null, mammoth_unit)
		10:
			if _count(&"frost_aura") != 1:
				_fail("an explicit frost_aura made a second aura")
			var aura2: Variant = fam.call(&"aura_of", mammoth)
			if aura2 == null or aura2.data.get("p") == null or not (aura2.data["p"] as GPUParticles3D).emitting:
				_fail("aura rime mist not emitting near the camera")
			trample_before = _count(&"trample")
			mammoth.call(&"play_trample")
			vfx.call(&"play", &"trample", mammoth_unit.global_position + Vector3(0, 0, 1.5), mammoth_unit)
		18:
			if _count(&"trample") != trample_before:
				_fail("trample started before trample_stomped")
		30:
			if _count(&"trample") != trample_before + 1:
				_fail("expected 1 trample after the stomp, got %d" % (_count(&"trample") - trample_before))
			else:
				var tfx: Variant = vfx.call(&"active_ids")
				var t0: Variant = fam.call(&"last_fx", &"trample")
				var m: GeometryInstance3D = t0.nodes.get(&"mark")
				if m == null or not m.visible:
					_fail("trample mark not visible")
			vfx.call(&"play", &"trample", plain.global_position, plain)
		31:
			if _count(&"trample") != trample_before + 2:
				_fail("a model-less unit should trample at once")
		40:
			mammoth_unit.position.x += 3.0
		42:
			var aura3: Variant = fam.call(&"aura_of", mammoth)
			if aura3:
				var r3: GeometryInstance3D = aura3.nodes.get(&"ring")
				if r3 == null or absf(r3.global_position.x - mammoth.global_position.x) > 0.05:
					_fail("aura does not follow the mammoth")
			mammoth_unit.visible = false
		60:
			var aura4: Variant = fam.call(&"aura_of", mammoth)
			if aura4:
				var r4: GeometryInstance3D = aura4.nodes.get(&"ring")
				if r4 and r4.visible:
					_fail("aura of a hidden mammoth is visible")
			mammoth_unit.visible = true
			bolts_before = _count(&"howdah_bolt")
			mammoth.call(&"play_howdah_shot", target)
			vfx.call(&"play", &"howdah_bolt", target, mammoth_unit)
		64:
			if _count(&"howdah_bolt") != bolts_before:
				_fail("howdah bolt left before the archer released")
		74:
			if _count(&"howdah_bolt") != bolts_before + 1:
				_fail("expected 1 howdah_bolt after the release, got %d" % (_count(&"howdah_bolt") - bolts_before))
			else:
				var b: Variant = fam.call(&"last_fx", &"howdah_bolt")
				if b.shots.is_empty() or b.shots[0]["aim"] != target:
					_fail("the bolt did not take the explicit target")
		100:
			var b2: Variant = fam.call(&"last_fx", &"howdah_bolt")
			if b2 == null or not b2.data.has("hit_t"):
				_fail("howdah bolt did not land")
			bolts_before = _count(&"howdah_bolt")
			mammoth.call(&"play_howdah_shot", null)
		130:
			if _count(&"howdah_bolt") <= bolts_before:
				_fail("play_howdah_shot alone shot no bolt")
		150:
			treant.call(&"set_rooted", true)
		165:
			bed_fx = fam.call(&"last_fx", &"root_morph")
			if bed_fx == null:
				_fail("no root_morph within 0.25 s of set_rooted")
			elif bed_fx.streams.is_empty():
				_fail("root_morph has no dust streams")
		200:
			sprout_fx = null
			vfx.call(&"play", &"sapling_sprout", Vector3(30, 0, 5), treant_unit)
			sprout_fx = fam.call(&"last_fx", &"sapling_sprout")
			vfx.call(&"play", &"sapling_sprout", Vector3(150, 0, 5), enemy_far)
			sprout_fog = fam.call(&"last_fx", &"sapling_sprout")
		220:
			vfx.call(&"play", &"knight_knockback", victim, knight_unit)
			knock_fx = fam.call(&"last_fx", &"knight_knockback")
			vfx.call(&"play", &"knight_knockback", Vector3(50, 0, 0), knight_unit)
			knock_pt_fx = fam.call(&"last_fx", &"knight_knockback")
			knight.call(&"play_charge")
		230:
			var ms: GeometryInstance3D = sprout_fx.nodes.get(&"mound") if sprout_fx else null
			var mf: GeometryInstance3D = sprout_fog.nodes.get(&"mound") if sprout_fog else null
			if ms == null or not ms.visible:
				_fail("sapling sprout in sight not visible")
			if mf == null or mf.visible:
				_fail("sapling sprout in the fog is visible")
		260:
			for pair: Array in [[knock_fx, 1.2, "unit"], [knock_pt_fx, 1.3, "point"]]:
				var k: Variant = pair[0]
				var sk: GeometryInstance3D = k.nodes.get(&"skid") if k else null
				if sk == null or not sk.visible:
					_fail("knockback skid (%s) not visible" % pair[2])
				elif sk.transform.basis.x.length() < float(pair[1]):
					_fail("knockback skid (%s) did not stretch (half length %.2f)" % [pair[2], sk.transform.basis.x.length()])
			if (vfx.call(&"active_ids") as Array).has(&"charge_impact"):
				_fail("a charge_impact was drawn by TitanVfx")
		350:
			if sprout_fx and _running(sprout_fx):
				_fail("sapling sprout still running at 2.5 s")
			if _count(&"grove_pulse") < 1 and pulses.is_empty():
				_fail("no grove pulse when the treant rooted")
			if not bool(treant.call(&"is_rooted")):
				_fail("treant not rooted at 3.3 s (model)")
		400:
			treant.call(&"play_volley")
			vfx.call(&"play", &"thorn_volley", target, treant_unit)
		405:
			if _count(&"thorn_volley") != 0:
				_fail("thorn volley left before volley_released")
		420:
			if _count(&"thorn_volley") != 1:
				_fail("expected 1 thorn_volley after the release, got %d" % _count(&"thorn_volley"))
			else:
				var v: Variant = fam.call(&"last_fx", &"thorn_volley")
				if v.shots.size() != 6:
					_fail("thorn volley has %d thorns (want 6)" % v.shots.size())
				elif v.shots[0]["aim"] != target:
					_fail("the volley did not take the explicit target")
		460:
			vfx.call(&"play", &"root_morph", null, treant_unit)
			vfx.call(&"play", &"grove_pulse", null, treant_unit)
		462:
			if _count(&"root_morph") != 1:
				_fail("explicit root_morph for a watched treant made a second bed (%d)" % _count(&"root_morph"))
		640:
			if pulses.size() < 2:
				_fail("expected >= 2 grove pulses while rooted (4 s cadence), saw %d" % pulses.size())
			treant.call(&"set_rooted", false)
		700:
			var ch := vfx.get_child_count()
			var fch := fam.get_child_count()
			for i in 40:
				var p := Vector3(float(i) - 20.0, 0.0, -30.0)
				for id: StringName in NEW_IDS:
					vfx.call(&"play", id, p, plain)
			if vfx.get_child_count() != ch or fam.get_child_count() != fch or _materials() != mats_before:
				_fail("nodes / materials created when the pools ran out")
		720:
			mammoth_unit.set(&"alive", false)
		830:
			if fam.call(&"aura_of", mammoth) != null:
				_fail("aura not released after the mammoth died")
		990:
			if bed_fx and _running(bed_fx):
				_fail("root bed still running 1.8 s after the uproot finished")
		1000:
			for n: Node3D in [mammoth_unit, treant_unit, knight_unit, plain, target, victim, enemy_far]:
				if is_instance_valid(n):
					n.queue_free()
		1400:
			_final_checks()
			return _end()
	if frame > 2 and frame % 50 == 0 and vfx and (vfx.get_child_count() != children_before
			or fam.get_child_count() != fam_children_before):
		_fail("child count changed at frame %d" % frame)
		children_before = vfx.get_child_count()
		fam_children_before = fam.get_child_count()
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
	for p: String in [SCRIPT_PATH, MAMMOTH, TREANT, KNIGHT, "res://art/vfx/titan_ground_vfx.gd"]:
		if not ResourceLoader.exists(p):
			_fail("missing %s" % p)
			return
	# The treant is in the tree BEFORE TitanVfx (the deferred scan must find it).
	treant_unit = _unit(0, Vector3(20.0, 0.0, 0.0))
	treant = _titan(treant_unit, TREANT)
	vfx = (load(SCRIPT_PATH) as GDScript).new()
	vfx.name = "TitanVfx"
	world.add_child(vfx)
	fam = vfx.get_node_or_null(^"TitanGroundVfx") as Node3D
	if fam == null:
		_fail("TitanVfx has no TitanGroundVfx child")
		return
	mammoth_unit = _unit(0, Vector3(0.0, 0.0, 0.0))
	mammoth = _titan(mammoth_unit, MAMMOTH)
	knight_unit = _unit(0, Vector3(37.0, 0.0, 0.0))
	knight_unit.rotation.y = PI * 0.5
	knight = _titan(knight_unit, KNIGHT)
	plain = _unit(0, Vector3(-10.0, 0.0, 0.0))
	target = _unit(1, Vector3(0.0, 0.0, 8.0))
	victim = _unit(1, Vector3(40.0, 0.0, 0.0))
	enemy_far = _unit(1, Vector3(150.0, 0.0, 0.0))
	children_before = vfx.get_child_count()
	fam_children_before = fam.get_child_count()
	mats_before = _materials()


func _unit(team: int, pos: Vector3, vis: bool = true) -> Node3D:
	var u := Node3D.new()
	u.set_script(stub)
	u.set(&"team", team)
	world.add_child(u)
	u.global_position = pos
	u.visible = vis
	return u


func _titan(u: Node3D, path: String) -> Node3D:
	var holder := Node3D.new()   # like Unit._visual
	u.add_child(holder)
	var m := (load(path) as PackedScene).instantiate() as Node3D
	holder.add_child(m)
	u.set(&"model", m)
	return m


func _check_ids() -> void:
	for id in NEW_IDS:
		if not vfx.call(&"handles", id):
			_fail("TitanVfx.handles(%s) false" % id)
		if not fam.call(&"handles", id):
			_fail("family handles(%s) false" % id)
	for id in OLD_IDS:
		if not vfx.call(&"handles", id):
			_fail("TitanVfx.handles(%s) false (dragon id lost)" % id)
		if fam.call(&"handles", id):
			_fail("family claims the dragon id %s" % id)
	if vfx.call(&"play", &"not_a_titan_effect", Vector3.ZERO, null):
		_fail("play() returned true for an unknown id")
	if vfx.call(&"handles", &"charge_impact") or fam.call(&"handles", &"charge_impact"):
		_fail("charge_impact is handled (it belongs to CavalryVfx)")


func _count(id: StringName) -> int:
	var n := 0
	for a: StringName in vfx.call(&"active_ids"):
		if a == id:
			n += 1
	return n


func _running(fx: Variant) -> bool:
	if fx == null:
		return false
	return (fam.get(&"_fx") as Array).has(fx)


func _materials() -> Dictionary:
	var out := {}
	for parent: Node in [vfx, fam]:
		for c in parent.get_children():
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
	var free: Dictionary = fam.get(&"_free")
	var all: Dictionary = fam.get(&"_all")
	for pool: StringName in all:
		if (free[pool] as Array).size() != (all[pool] as Array).size():
			_fail("pool %s not full at the end" % pool)
	var sf: Dictionary = fam.get(&"_stream_free")
	var sa: Dictionary = fam.get(&"_stream_all")
	for look: StringName in sa:
		if (sf[look] as Array).size() != (sa[look] as Array).size():
			_fail("stream pool %s not full at the end" % look)
	if (fam.get(&"_att") as Dictionary).size() != 0:
		_fail("freed titans still attached")
	if vfx.get_child_count() != children_before or fam.get_child_count() != fam_children_before \
			or _materials() != mats_before:
		_fail("nodes / materials changed during the run")


func _fail(msg: String) -> void:
	if not fails.has(msg):
		fails.append(msg)

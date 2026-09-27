extends SceneTree
## Task 13c.V9: Frost Wyrm VFX + lair (docs/design/titans-2.md 7 / 11 row 13c.V9).
##   art/vfx/mapfill_wyrm_vfx.gd (MapFillWyrmVfx), the forwarding hook in art/vfx/mapfill_vfx.gd, the Icebound Barge
##   (art/environment/lairs/icebound_barge.tscn + icebound_barge.gd) and LairArt's mapping.
## Run:  $GODOT --headless --path . -s tests/test_13c_v9.gd --fixed-fps 60 --quit-after 6000
## Checks:
##  - group "mapfill_wyrm_vfx" (not "mapfill_vfx"); handles() / play() true for the 5 ids, false for others (nothing
##    starts); every id plays without a target and with `at` as a Node3D; no node / material created at runtime;
##  - timings: the dive telegraph shows at once and lands at 1.0 s (no Wyrm), the ice burst shows after it; the lash
##    strikes at 0.35 s; the blizzard wall reaches r 8 and runs 8 s (+ fade), stops early (<= 1.1 s) when its Wyrm dies;
##    the warning runs 30 s + 3.5 s;
##  - fog (stub FogOfWar): a dive in the fog shows nothing, the warning shows anyway, a breath follows its Wyrm's
##    `visible`;
##  - the real Frost Wyrm model (13c.V8) under a stub unit: attached by itself; breath_released -> ONE wyrm_breath
##    (an explicit call before the jaw opens merges); dive_landed lands the explicit dive; tail_struck strikes the
##    explicit lash once; blizzard_released merges with the explicit call; TitanVfx (present) no longer holds the Wyrm;
##    its death crash reaches TitanVfx as frost_crash; the rime wake emits while it flies near the camera;
##  - MapFillVfx forwards the 5 ids to its child "WyrmVfx" (wyrm_vfx()), still forwards beast ids to BeastVfx, and none
##    of the wyrm ids is in its own EFFECTS;
##  - the Icebound Barge: loads, root is a LairArt (icebound_barge.gd) in group "lairs", lair_kind &"frost_wyrm", no
##    light / collider, saved materials, crust mesh indexed and <= 4 000 triangles; empty at start (Active hidden);
##    occupied before _ready = frozen at once; set_occupied(true) freezes in 2.5 s, (false) thaws in 6 s and hides;
##    "Active" snaps onto a barge landmark (group "landmarks", lm_barge) near the lair centre, the root stays put;
##    LairArt.scene_path_for(wyrm_barge_s / _n / kind frost_wyrm) -> icebound_barge.tscn; barge.tscn untouched;
##  - at the end every effect is over, pools full, live_count 0.
## Prints PASS 13c.v9 / FAIL 13c.v9: <reasons>.

const TASK_ID := "13c.v9"
const VFX_PATH := "res://art/vfx/mapfill_wyrm_vfx.gd"
const MAPFILL_PATH := "res://art/vfx/mapfill_vfx.gd"
const TITAN_PATH := "res://art/vfx/titan_vfx.gd"
const WYRM_SCENE := "res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn"
const LAIR_SCENE := "res://art/environment/lairs/icebound_barge.tscn"
const LAIR_ART := "res://art/environment/lairs/lair_art.gd"
const BARGE_SCENE := "res://art/environment/landmarks/barge.tscn"
const IDS: Array[StringName] = [&"wyrm_breath", &"wyrm_dive", &"wyrm_tail", &"wyrm_blizzard", &"wyrm_warning"]
const UNIT_SRC := "extends Node3D\nvar team: int = 2\nvar alive: bool = true\nfunc is_alive() -> bool:\n\treturn alive\nfunc get_model() -> Node3D:\n\treturn get_node_or_null(\"Model\") as Node3D\n"
const FOG_SRC := "extends Node\nvar enabled := true\nvar local_team := 0\nfunc _ready() -> void:\n\tadd_to_group(&\"fog\")\nfunc is_visible(_team: int, p: Vector3) -> bool:\n\treturn p.x < 150.0\n"
const DT := 1.0 / 60.0

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _vfx: Node3D
var _unit_s: GDScript
var _children := 0
var _mats: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  check failed: ", what)


func _frames(n: int) -> void:
	for _i: int in n:
		await process_frame


func _secs(s: float) -> void:
	await _frames(int(round(s / DT)))


func _run() -> void:
	_world = Node3D.new()
	_world.name = "World"
	root.add_child(_world)
	current_scene = _world
	var cam := Camera3D.new()
	cam.position = Vector3(0, 30, 20)
	_world.add_child(cam)
	cam.look_at(Vector3.ZERO)
	cam.current = true
	_unit_s = GDScript.new()
	_unit_s.source_code = UNIT_SRC
	_unit_s.reload()
	var fog_s := GDScript.new()
	fog_s.source_code = FOG_SRC
	fog_s.reload()
	var fog := Node.new()
	fog.set_script(fog_s)
	_world.add_child(fog)
	_check(ResourceLoader.exists(VFX_PATH), "mapfill_wyrm_vfx.gd exists")
	if not ResourceLoader.exists(VFX_PATH):
		_finish()
		return
	_vfx = (load(VFX_PATH) as GDScript).new()
	_vfx.name = "WyrmVfx"
	_world.add_child(_vfx)
	await _frames(3)
	_children = _vfx.get_child_count()
	_mats = _materials(_vfx)
	await _api()
	# Let the dives / blizzards of the API pass end (their crown / storm pools are sized for two Wyrms).
	for i in 20:
		var busy := false
		for id: StringName in (_vfx.call(&"active_ids") as Array):
			busy = busy or id != &"wyrm_warning"
		if not busy:
			break
		await _secs(1.0)
	await _timings()
	await _fog_checks()
	await _with_model()
	await _forwarding()
	await _lair()
	await _end_checks()
	_finish()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


# ---------------------------------------------------------------- API

func _api() -> void:
	_check(_vfx.is_in_group(&"mapfill_wyrm_vfx"), "in group mapfill_wyrm_vfx")
	_check(not _vfx.is_in_group(&"mapfill_vfx"), "not in group mapfill_vfx")
	for id in IDS:
		_check(bool(_vfx.call(&"handles", id)), "handles %s" % id)
	for bad: StringName in [&"maul", &"frost_breath", &"capture_done", &"nope"]:
		_check(not bool(_vfx.call(&"handles", bad)), "does not handle %s" % bad)
		_check(not bool(_vfx.call(&"play", bad, Vector3.ZERO, null)), "play(%s) is false" % bad)
	_check(int(_vfx.call(&"active_count")) == 0 and int(_vfx.call(&"live_count")) == 0, "unknown ids start nothing")
	# Every id without a target, then with `at` as a node.
	var spot := Node3D.new()
	_world.add_child(spot)
	spot.position = Vector3(40, 0, 40)
	var x := 0.0
	for id in IDS:
		var before: int = _vfx.call(&"active_count")
		_check(bool(_vfx.call(&"play", id, Vector3(x, 0.0, -40.0), null)), "play(%s) true" % id)
		_check(int(_vfx.call(&"active_count")) == before + 1, "%s without a target started an effect" % id)
		x += 30.0
	for id in IDS:
		if id == &"wyrm_warning":
			continue
		var b2: int = _vfx.call(&"active_count")
		_vfx.call(&"play", id, spot, null)
		_check(int(_vfx.call(&"active_count")) == b2 + 1, "%s with at = Node3D started an effect" % id)
	await _frames(20)
	_check(int(_vfx.call(&"live_count")) > 0, "something visible after playing every id")
	_check(_vfx.get_child_count() == _children, "no node created at runtime")
	_check(_materials(_vfx) == _mats, "no material / mesh created at runtime")
	# A second warning at the same spot is ignored.
	var w0: int = _vfx.call(&"active_count")
	_vfx.call(&"play", &"wyrm_warning", Vector3(120.0, 0.0, -40.0), null)
	_check(int(_vfx.call(&"active_count")) == w0, "the same warning twice plays once")
	spot.queue_free()


# ---------------------------------------------------------------- timings (no Wyrm)

func _timings() -> void:
	var p := Vector3(-60.0, 0.0, 60.0)
	_vfx.call(&"play", &"wyrm_dive", p, null)
	var dive: Object = _vfx.call(&"last_fx", &"wyrm_dive")
	_vfx.call(&"play", &"wyrm_tail", p + Vector3(20, 0, 0), null)
	var lash: Object = _vfx.call(&"last_fx", &"wyrm_tail")
	await _frames(2)
	var tele: GeometryInstance3D = dive.get(&"nodes").get(&"tele")
	_check(tele != null and tele.visible, "dive telegraph visible at once")
	_check(float(dive.get(&"land_t")) < 0.0, "dive not landed at 0.03 s")
	await _secs(0.34)
	_check(float(lash.get(&"land_t")) >= 0.0 and absf(float(lash.get(&"land_t")) - 0.35) < 0.06,
			"lash strikes at 0.35 s (%.2f)" % float(lash.get(&"land_t")))
	await _secs(0.36)
	_check(float(dive.get(&"land_t")) < 0.0, "dive not landed at 0.75 s")
	await _secs(0.33)
	var lt := float(dive.get(&"land_t"))
	_check(lt >= 0.95 and lt <= 1.06, "dive lands at 1.0 s (%.2f)" % lt)
	await _frames(6)
	var crown: GeometryInstance3D = dive.get(&"nodes").get(&"crown")
	var crater: GeometryInstance3D = dive.get(&"nodes").get(&"crater")
	_check(crown != null and crown.visible, "ice crown shows after the landing")
	_check(crater != null and crater.visible, "ice crater shows after the landing")
	# Blizzard: r 8 wall, 8 s.
	var c := Vector3(-60.0, 0.0, 100.0)
	_vfx.call(&"play", &"wyrm_blizzard", c, null)
	var bz: Object = _vfx.call(&"last_fx", &"wyrm_blizzard")
	await _secs(2.0)
	var wall: GeometryInstance3D = bz.get(&"nodes").get(&"wall")
	_check(wall != null and wall.visible and absf(wall.transform.basis.x.length() - 8.0) < 0.05,
			"blizzard wall r 8 at 2 s (%.2f)" % (wall.transform.basis.x.length() if wall else -1.0))
	await _secs(5.8)
	_check((_vfx.call(&"active_ids") as Array).has(&"wyrm_blizzard"), "blizzard still running at 7.8 s")
	await _secs(1.6)
	_check(not (_vfx.call(&"active_ids") as Array).has(&"wyrm_blizzard"), "blizzard over at 9.4 s")


# ---------------------------------------------------------------- fog

func _fog_checks() -> void:
	_vfx.call(&"play", &"wyrm_dive", Vector3(200.0, 0.0, 0.0), null)
	var dive: Object = _vfx.call(&"last_fx", &"wyrm_dive")
	_vfx.call(&"play", &"wyrm_warning", Vector3(220.0, 0.0, 30.0), null)
	var warn: Object = _vfx.call(&"last_fx", &"wyrm_warning")
	await _secs(1.3)
	var shown := false
	for n: GeometryInstance3D in (dive.get(&"nodes") as Dictionary).values():
		shown = shown or n.visible
	_check(not shown, "a dive in the fog shows nothing")
	var wshown := false
	for n: GeometryInstance3D in (warn.get(&"nodes") as Dictionary).values():
		wshown = wshown or n.visible
	_check(wshown, "the warning shows through the fog")
	# The warning runs 30 s + 3.5 s: check with its clock.
	_check(absf(float(warn.get(&"dur")) - 33.5) < 0.01, "warning lasts 30 + 3.5 s")


# ---------------------------------------------------------------- the real Wyrm

func _wyrm_unit(pos: Vector3) -> Node3D:
	var u := Node3D.new()
	u.set_script(_unit_s)
	u.name = "WyrmUnit"
	var m := (load(WYRM_SCENE) as PackedScene).instantiate() as Node3D
	m.name = "Model"
	u.add_child(m)
	_world.add_child(u)
	u.global_position = pos
	return u


func _count_id(id: StringName) -> int:
	var n := 0
	for a: StringName in (_vfx.call(&"active_ids") as Array):
		if a == id:
			n += 1
	return n


func _with_model() -> void:
	if not ResourceLoader.exists(WYRM_SCENE):
		print("  note: the Frost Wyrm model is missing: model checks skipped")
		return
	var titan: Node3D = null
	if ResourceLoader.exists(TITAN_PATH):
		titan = (load(TITAN_PATH) as GDScript).new()
		titan.name = "TitanVfx"
		_world.add_child(titan)
	await _frames(2)
	var u := _wyrm_unit(Vector3(0.0, 0.0, 5.0))
	var m := u.get_node("Model") as Node3D
	await _frames(4)
	_check(bool(_vfx.call(&"is_attached", m)), "the Wyrm model is attached by itself")
	if titan:
		_check(not bool(titan.call(&"is_attached", m)), "TitanVfx no longer holds the Wyrm (take-over)")
	# Breath: explicit call before the jaw + the model's breath_released = ONE breath.
	var b0 := _count_id(&"wyrm_breath")
	_vfx.call(&"play", &"wyrm_breath", Vector3(0.0, 0.0, 10.0), u)
	m.call(&"play_attack")
	await _secs(0.25)
	_check(_count_id(&"wyrm_breath") == b0, "the explicit breath waits for breath_released")
	await _secs(0.2)
	_check(_count_id(&"wyrm_breath") == b0 + 1, "breath_released plays ONE wyrm_breath (%d)" % (_count_id(&"wyrm_breath") - b0))
	if titan:
		_check(not (titan.call(&"active_ids") as Array).has(&"frost_breath"), "TitanVfx drew no frost_breath")
	# Auto breath without a call.
	await _secs(1.2)
	var b1 := _count_id(&"wyrm_breath")
	m.call(&"play_attack")
	await _secs(0.45)
	_check(_count_id(&"wyrm_breath") == b1 + 1, "breath_released alone plays wyrm_breath")
	await _secs(1.0)
	# Dive: explicit telegraph, landed by dive_landed.
	var spot := u.global_position + Vector3(0.0, 0.0, 3.0)
	_vfx.call(&"play", &"wyrm_dive", spot, u)
	var dive: Object = _vfx.call(&"last_fx", &"wyrm_dive")
	m.call(&"play_cast", &"glacial_dive")
	await _secs(0.9)
	_check(float(dive.get(&"land_t")) < 0.0, "the dive waits for dive_landed")
	await _secs(0.3)
	_check(float(dive.get(&"land_t")) >= 0.95, "dive_landed lands the explicit dive (%.2f)" % float(dive.get(&"land_t")))
	_check(_vfx.call(&"last_fx", &"wyrm_dive") == dive, "dive_landed did not start a second dive")
	_check((dive.get(&"point") as Vector3).is_equal_approx(spot), "the burst stays on the gameplay point")
	m.call(&"set_grounded", true)
	await _secs(1.0)
	# Tail Lash: explicit + tail_struck = one strike.
	var l0 := _count_id(&"wyrm_tail")
	_vfx.call(&"play", &"wyrm_tail", u.global_position, u)
	var lash: Object = _vfx.call(&"last_fx", &"wyrm_tail")
	m.call(&"play_cast", &"tail_lash")
	await _secs(0.5)
	_check(_count_id(&"wyrm_tail") == l0 + 1, "tail_struck merged with the explicit lash (%d)" % (_count_id(&"wyrm_tail") - l0))
	_check(float(lash.get(&"land_t")) >= 0.3 and float(lash.get(&"land_t")) <= 0.45,
			"the lash strikes on tail_struck (%.2f)" % float(lash.get(&"land_t")))
	_vfx.call(&"play", &"wyrm_tail", u.global_position, u)
	_check(_count_id(&"wyrm_tail") == l0 + 1, "a late second call for the same lash is ignored")
	await _secs(1.2)
	# Blizzard: explicit + blizzard_released = one, following the Wyrm; stops when it dies.
	m.call(&"set_variant", 1)
	var z0 := _count_id(&"wyrm_blizzard")
	_vfx.call(&"play", &"wyrm_blizzard", u.global_position, u)
	m.call(&"play_cast", &"blizzard")
	await _secs(0.5)
	_check(_count_id(&"wyrm_blizzard") == z0, "the explicit blizzard waits for blizzard_released")
	await _secs(0.4)
	_check(_count_id(&"wyrm_blizzard") == z0 + 1, "blizzard_released plays ONE blizzard")
	var bz: Object = _vfx.call(&"last_fx", &"wyrm_blizzard")
	_check(int(bz.get(&"variant")) == 1, "the blizzard reads variant B")
	u.global_position += Vector3(3.0, 0.0, 0.0)
	await _frames(3)
	var wall: GeometryInstance3D = bz.get(&"nodes").get(&"wall") if bz else null
	_check(wall != null and absf(wall.global_position.x - u.global_position.x) < 0.01, "the storm follows the Wyrm")
	u.set(&"alive", false)
	await _secs(1.2)
	_check(not (_vfx.call(&"active_ids") as Array).has(&"wyrm_blizzard"), "the blizzard ends <= 1.2 s after the death")
	u.set(&"alive", true)
	# Wake: flying, moving, near the camera.
	m.call(&"set_grounded", false)
	await _secs(1.0)
	for i in 30:
		u.global_position += Vector3(0.0, 0.0, 0.1)
		await process_frame
	_check(bool(_vfx.call(&"wake_emitting", m)), "the rime wake emits while it flies")
	# Death crash -> TitanVfx frost_crash.
	if titan:
		m.call(&"play_death")
		var got := false
		for i in 150:
			await process_frame
			if (titan.call(&"active_ids") as Array).has(&"frost_crash"):
				got = true
				break
		_check(got, "the death crash reaches TitanVfx as frost_crash")
	await _secs(1.0)
	u.queue_free()
	await _frames(3)
	_check(not bool(_vfx.call(&"is_attached", m)) if is_instance_valid(m) else true, "the freed Wyrm is detached")
	if titan:
		titan.queue_free()


# ---------------------------------------------------------------- MapFillVfx hook

func _forwarding() -> void:
	var mf := (load(MAPFILL_PATH) as GDScript).new() as Node3D
	mf.set(&"auto_hooks", false)
	mf.set(&"auto_wade", false)
	_world.add_child(mf)
	await _frames(2)
	var effects: Array = mf.get(&"EFFECTS")
	for id in IDS:
		_check(not effects.has(id), "%s not in MapFillVfx.EFFECTS" % id)
	var child := mf.get_node_or_null(^"WyrmVfx")
	_check(child != null and child.is_in_group(&"mapfill_wyrm_vfx"), "MapFillVfx has a child WyrmVfx")
	_check(mf.call(&"wyrm_vfx") == child, "MapFillVfx.wyrm_vfx() returns it")
	if child:
		for id in IDS:
			var before: int = child.call(&"active_count")
			mf.call(&"play", id, Vector3(-150.0, 0.0, 0.0), null)
			_check(int(child.call(&"active_count")) == before + 1, "MapFillVfx forwards %s" % id)
	var beast: Node = mf.get_node_or_null(^"BeastVfx")
	if beast and beast.has_method(&"active_count"):
		var b0: int = beast.call(&"active_count")
		mf.call(&"play", &"maul", Vector3(-150.0, 0.0, 20.0), null)
		_check(int(beast.call(&"active_count")) == b0 + 1, "beast ids still reach BeastVfx")
	mf.queue_free()


# ---------------------------------------------------------------- the lair

func _lair() -> void:
	_check(ResourceLoader.exists(LAIR_SCENE), "icebound_barge.tscn exists")
	if not ResourceLoader.exists(LAIR_SCENE):
		return
	var ps := load(LAIR_SCENE) as PackedScene
	var lair := ps.instantiate() as Node3D
	_check(lair is LairArt, "root is a LairArt")
	_check((lair.get_script() as Script).resource_path.ends_with("icebound_barge.gd"), "root script icebound_barge.gd")
	_check(StringName(str(lair.get_meta(&"lair_kind", &""))) == &"frost_wyrm", "lair_kind frost_wyrm")
	_check(lair.find_children("*", "Light3D", true, false).is_empty(), "no light")
	_check(lair.find_children("*", "CollisionObject3D", true, false).is_empty(), "no collider")
	var crust := lair.get_node_or_null(^"Active/Crust") as MeshInstance3D
	_check(crust != null, "Active/Crust exists")
	if crust:
		var mesh := crust.mesh as ArrayMesh
		_check(mesh.get_surface_count() == 1, "crust: one surface")
		var arr: Array = mesh.surface_get_arrays(0)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		_check(not idx.is_empty(), "crust indexed")
		_check(idx.size() / 3 <= 4000, "crust <= 4 000 triangles (%d)" % (idx.size() / 3))
		print("  icebound crust: %d triangles, %d vertices" % [idx.size() / 3, (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()])
	for path: NodePath in [^"Active/Crust", ^"Active/Sheet", ^"Active/Rime"]:
		var gi := lair.get_node_or_null(path) as GeometryInstance3D
		_check(gi != null and gi.material_override != null and gi.material_override.resource_path != "",
				"%s uses a saved material" % path)
		if gi:
			_check(gi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s casts no shadow" % path)
	# A barge landmark near the lair centre (the south one: point mirror, yaw PI).
	var lm := Node3D.new()
	lm.name = "BargeLandmark"
	lm.add_to_group(&"landmarks")
	lm.set_meta(&"landmark_id", &"lm_barge")
	lm.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(106.2, 0.0, 24.5))
	_world.add_child(lm)
	lair.position = Vector3(104.5, 0.0, 20.5)
	_world.add_child(lair)
	await _frames(3)
	var active := lair.get_node(^"Active") as Node3D
	_check(not active.visible and float(lair.call(&"freeze_level")) == 0.0, "empty at start (Active hidden)")
	_check(bool(lair.call(&"is_snapped")) and active.global_transform.is_equal_approx(lm.global_transform),
			"Active snapped onto the barge landmark")
	_check(lair.global_position.is_equal_approx(Vector3(104.5, 0.0, 20.5)), "the lair root stays at the lair centre")
	lair.call(&"set_occupied", true)
	await _secs(1.2)
	var mid := float(lair.call(&"freeze_level"))
	_check(active.visible and mid > 0.2 and mid < 0.9, "freezing over (%.2f at 1.2 s)" % mid)
	await _secs(1.45)
	_check(is_equal_approx(float(lair.call(&"freeze_level")), 1.0), "frozen by 2.65 s")
	var sheet := lair.get_node(^"Active/Sheet") as GeometryInstance3D
	_check(is_equal_approx(float(sheet.get_instance_shader_parameter(&"freeze")), 1.0), "freeze uniform pushed")
	var vap := lair.get_node_or_null(^"Active/Vapour") as GPUParticles3D
	_check(vap != null and vap.emitting, "vapour rises while occupied")
	lair.call(&"set_occupied", false)
	await _secs(3.0)
	_check(float(lair.call(&"freeze_level")) > 0.3 and active.visible, "thawing, not hidden at once")
	await _secs(3.2)
	_check(float(lair.call(&"freeze_level")) == 0.0 and not active.visible, "thawed and hidden by 6.2 s")
	# Occupied before _ready: frozen at once.
	var early := ps.instantiate() as Node3D
	early.call(&"set_occupied", true)
	_world.add_child(early)
	await _frames(1)
	_check(float(early.call(&"freeze_level")) == 1.0 and (early.get_node(^"Active") as Node3D).visible,
			"occupied before _ready = frozen at once")
	early.queue_free()
	lair.queue_free()
	lm.queue_free()
	# LairArt mapping.
	var la := load(LAIR_ART) as GDScript
	for id: StringName in [&"wyrm_barge_s", &"wyrm_barge_n"]:
		_check(String(la.call(&"scene_path_for", id, &"")).ends_with("icebound_barge.tscn"), "scene_path_for(%s)" % id)
	_check(String(la.call(&"scene_path_for", &"some_lair", &"frost_wyrm")).ends_with("icebound_barge.tscn"),
			"scene_path_for falls back on kind frost_wyrm")
	_check(FileAccess.get_file_as_string(BARGE_SCENE).find("icebound") < 0, "barge.tscn untouched")


# ---------------------------------------------------------------- end

func _end_checks() -> void:
	# Let the long ones (the warnings) run out.
	for i in 40:
		if int(_vfx.call(&"active_count")) == 0 and int(_vfx.call(&"live_count")) == 0:
			break
		await _secs(1.0)
	_check(int(_vfx.call(&"active_count")) == 0, "every effect is over (%s)" % [_vfx.call(&"active_ids")])
	_check(int(_vfx.call(&"live_count")) == 0, "nothing left on screen (%d)" % int(_vfx.call(&"live_count")))
	var free: Dictionary = _vfx.get(&"_free")
	var sizes: Dictionary = _vfx.get(&"MESH_POOLS")
	for pool: StringName in sizes:
		_check((free[pool] as Array).size() == int(sizes[pool]), "pool %s full again" % pool)
	_check(_vfx.get_child_count() == _children, "no node created during the run")
	_check(_materials(_vfx) == _mats, "no material created during the run")


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
	return out

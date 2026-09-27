extends SceneTree
## Task 12.V25: map-fill effects (art/vfx/mapfill_vfx.gd, class MapFillVfx, group "mapfill_vfx").
## Run:  $GODOT --headless --path . -s tests/test_12_v25.gd --fixed-fps 60 --quit-after 4000
## Stand-ins built here (tiny GDScripts): units (team, body_height, radius, velocity, is_alive, has_modifier), a river
## (group "river": a straight channel along x = 0, half width 2.5, one ford circle r 3.5 at the origin, deep water
## elsewhere in the channel), CapturePoints / CampManager / NeutralCamp signal stubs, and a beast-effects stub script
## written to user:// (stands for 12.V31's art/vfx/mapfill_beast_vfx.gd).
## Checks:
##  - the node joins group "mapfill_vfx"; every id of EFFECTS plays with a target AND without one; `at` may be a
##    Node3D; no position = nothing; the ids called by finished code (capture_point.gd `_play_vfx`, creature_abilities
##    spore_burst / antler_sweep) are all in EFFECTS, the beast ability ids and beast_spawn are not;
##  - unknown ids: forwarded to the beast script (setup(host) called, child "BeastVfx"), own ids never forwarded; with
##    no beast file an unknown id is a silent no-op;
##  - no node, material or mesh is created after _ready (40 capture_done at once included); same id + spot twice in
##    one frame plays once;
##  - hooks: blessing_started -> runes over the blessed team's units that carry the modifier only; blessing_ended ->
##    they fade; a unit given the rune by play(&"blessing") loses it when freed; camp_cleared / respawned signals play
##    camp_cleared / camp_respawn;
##  - wading: a unit in the ford over the channel and an amphibious unit in deep water ripple; a unit in the ford
##    circle but on the bank, a hidden unit and a far unit do not; <= 6 waders; <= 16 rings at every frame;
##  - timing: at 1.73 s the <= 1.6 s effects are over, the 1.8 / 2.7 s ones still run; at the end nothing is left
##    (no burst, no piece, no ring, no rune), every pool is full again.
##  - phase 2, the real skirmish (map fill on) + a MapFillVfx child added like the lead's glue: the hero put in Reed Ford
##    wades (real RiverSystem), CapturePoint.wake() / play_pulse() reach it, it hooked CapturePoints and CampManager.
## Prints PASS 12_v25 / FAIL 12_v25: <reason>.

const TASK_ID := "12_v25"
const VFX_PATH := "res://art/vfx/mapfill_vfx.gd"
const BEAST_STUB_PATH := "user://test_12_v25_beast.gd"
const BEAST_STUB_SRC := "extends Node\nvar calls: Array = []\nvar host: Object\nfunc setup(h: Object) -> void:\n\thost = h\nfunc play(id: StringName, at: Variant, target: Variant = null) -> void:\n\tcalls.append(id)\n"
const UNIT_SRC := "extends Node3D\nvar team: int = 0\nvar body_height: float = 1.6\nvar radius: float = 0.45\nvar alive: bool = true\nvar velocity: Vector3 = Vector3.ZERO\nvar mods: Dictionary = {}\nfunc is_alive() -> bool:\n\treturn alive\nfunc has_modifier(id: StringName) -> bool:\n\treturn mods.has(id)\n"
const POINT_SRC := "extends Node3D\nvar team: int = 2\nvar owner_team: int = 0\nvar capture_radius: float = 7.0\nvar kind: StringName = &\"watchtower\"\n"
const RIVER_SRC := "extends Node3D\nfunc crossings() -> Array:\n\treturn [{\"id\": &\"ford_t\", \"kind\": &\"ford\", \"center\": Vector3.ZERO, \"width\": 7.0, \"radius\": 3.5}, {\"id\": &\"bridge_t\", \"kind\": &\"bridge_road\", \"center\": Vector3(0, 0, 20), \"width\": 6.0}]\nfunc polylines() -> Array:\n\treturn [PackedVector2Array([Vector2(0, -40), Vector2(0, 40)])]\nfunc half_width() -> float:\n\treturn 2.5\nfunc moat() -> Vector4:\n\treturn Vector4.ZERO\nfunc is_water(pos: Vector3) -> bool:\n\treturn absf(pos.x) < 2.5 and absf(pos.z) > 3.5 and absf(pos.z) < 40.0\n"
const CPS_SRC := "extends Node\nsignal blessing_started(team: int, seconds: float)\nsignal blessing_ended(team: int)\nfunc blessing_time_left(team: int) -> float:\n\treturn 0.0\n"
const CM_SRC := "extends Node\nsignal camp_cleared(camp: Node3D, team: int, reward: Dictionary)\n"
const CAMP_SRC := "extends Node3D\nsignal respawned(camp: Node3D)\n"
const PHASE2_FRAMES := 2400
const SHORT: Array[StringName] = [&"capture_done", &"well_pulse", &"camp_respawn", &"antler_sweep"]
const LONG: Array[StringName] = [&"shrine_awaken", &"spore_burst", &"camp_cleared"]
const BEAST_IDS: Array[StringName] = [&"gore_charge", &"bristle_hide", &"gale_swoop", &"shrieking_dive", &"updraft",
		&"pounce", &"hamstring", &"maul", &"rending_roar", &"enrage", &"beast_spawn"]

var world: Node3D
var vfx: Node3D        # with the beast stub
var vfx_nb: Node3D     # no beast file
var unit_s: GDScript
var frame := 0
var fails: PackedStringArray = []
var children_before := 0
var mats_before: Dictionary = {}
var point: Node3D
var cps: Node
var cm: Node
var camp: Node3D
var wader_a: Node3D
var bank_u: Node3D
var hidden_u: Node3D
var far_u: Node3D
var amph: Node3D
var crowd: Array[Node3D] = []
var bl_a: Node3D
var bl_b: Node3D
var bl_c: Node3D
var bl_d: Node3D
var explicit_u: Node3D
var max_rings := 0
var done := false


func _initialize() -> void:
	world = Node3D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	var f := FileAccess.open(BEAST_STUB_PATH, FileAccess.WRITE)
	f.store_string(BEAST_STUB_SRC)
	f.close()
	unit_s = _script(UNIT_SRC)


func _script(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s


func _node(src: String, group: StringName, is_3d: bool = true) -> Node:
	var n: Node = Node3D.new() if is_3d else Node.new()
	n.set_script(_script(src))
	if group != &"":
		n.add_to_group(group)
	world.add_child(n)
	return n


func _process(_delta: float) -> bool:
	frame += 1
	if frame >= 10 and frame < 540 and vfx != null:
		var rc := int(vfx.call(&"ripple_count"))
		max_rings = maxi(max_rings, rc)
		if rc > 16:
			_fail("%d ripple rings alive (max 16)" % rc)
	match frame:
		2:
			_setup()
		3:
			_play_all()
			_check_callers()
		5:
			cps.emit_signal(&"blessing_started", 0, 60.0)
			var before: int = vfx.call(&"active_count")
			cm.emit_signal(&"camp_cleared", camp, 1, {})
			cm.emit_signal(&"camp_cleared", camp, 1, {})   # same frame, same spot: plays once
			camp.emit_signal(&"respawned", camp)
			var ids: Array = vfx.call(&"active_ids")
			if not ids.has(&"camp_cleared") or not ids.has(&"camp_respawn"):
				_fail("camp hooks did not play camp_cleared / camp_respawn: %s" % [ids])
			if int(vfx.call(&"active_count")) != before + 2:
				_fail("camp hooks: %d new effects (expected 2, dedupe)" % (int(vfx.call(&"active_count")) - before))
		22:
			var w: Array = vfx.call(&"waders")
			if not w.has(wader_a):
				_fail("unit in the ford over the channel is not wading")
			if not w.has(amph):
				_fail("amphibious unit in deep water is not wading")
			for u: Node3D in [bank_u, hidden_u, far_u]:
				if w.has(u):
					_fail("%s should not wade" % u.name)
			if int(vfx.call(&"ripple_count")) == 0:
				_fail("no ripples for the waders")
			_spawn_crowd()
		40:
			var runes: Array = vfx.call(&"rune_units")
			for u: Node3D in [bl_a, bl_b, explicit_u]:
				if not runes.has(u):
					_fail("%s has no blessing rune" % u.name)
			for u: Node3D in [bl_c, bl_d]:
				if runes.has(u):
					_fail("%s should have no rune (no modifier / team not blessed)" % u.name)
		50:
			var w: Array = vfx.call(&"waders")
			if w.size() > 6:
				_fail("%d waders (max 6)" % w.size())
		60:
			cps.emit_signal(&"blessing_ended", 0)
		100:
			if int(vfx.call(&"rune_count")) != 1:
				_fail("after blessing_ended %d runes (expected only the explicit one)" % vfx.call(&"rune_count"))
			explicit_u.queue_free()
		107:
			# 1.73 s after the plays of frame 3.
			var ids: Array = vfx.call(&"active_ids")
			for id in SHORT:
				if ids.has(id):
					_fail("%s still running at 1.73 s" % id)
			for id in LONG:
				if not ids.has(id):
					_fail("%s already over at 1.73 s" % id)
		112:
			for i in 40:
				vfx.call(&"play", &"capture_done", Vector3(float(i) * 3.0, 0.0, 50.0), point)
			if vfx.get_child_count() != children_before or _materials(vfx) != mats_before:
				_fail("nodes / materials created when the pools ran out")
		140:
			if int(vfx.call(&"rune_count")) != 0:
				_fail("rune of a freed unit still shown")
			for u in crowd:
				u.position = Vector3(30.0, 0.0, 30.0)
			wader_a.position = Vector3(30.0, 0.0, -30.0)
			amph.position = Vector3(30.0, 0.0, 0.0)
		540:
			_final_checks()
			_phase2()
	if frame > 540 + PHASE2_FRAMES and not done:
		_fail("phase 2 timed out")
		done = true
	if done:
		print("PASS %s" % TASK_ID if fails.is_empty() else "FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
		return true
	return false


## Phase 2: the real skirmish (map fill on) with a MapFillVfx added the way the lead glues it (a child of the level):
## the real RiverSystem finds a unit wading in Reed Ford, the real CapturePoint calls play shrine_awaken / well_pulse,
## the hooks connect to the real CapturePoints / CampManager.
func _phase2() -> void:
	# The phase-1 stand-ins sit in the real service groups: take them out before the real services look for them.
	for n in world.find_children("*", "", true, false):
		for g in n.get_groups():
			n.remove_from_group(g)
	world.queue_free()
	await _frames(3)
	var main: Node = load("res://scenes/skirmish.tscn").instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main
	# skirmish.tscn now ships its own MapFillVfx (lead glue); use it instead of adding a second one
	var mv: Node3D = main.get_node_or_null("MapFillVfx") as Node3D
	if mv == null:
		mv = (load(VFX_PATH) as GDScript).new()
		mv.name = "MapFillVfx"
		main.add_child(mv)
	var map_ok := false
	for i in 1500:
		await process_frame
		var pts := get_first_node_in_group(&"capture_points_service")
		if get_first_node_in_group(&"river") != null and pts != null and pts.has_method(&"points") \
				and not (pts.call(&"points") as Array).is_empty() and get_first_node_in_group(&"heroes") != null:
			map_ok = true
			break
	if not map_ok:
		_fail("phase 2: skirmish never had a river, capture points and a hero")
		done = true
		return
	await _frames(30)
	var river := get_first_node_in_group(&"river")
	var ford: Dictionary = river.call(&"crossing", &"ford_n")
	var hero := get_first_node_in_group(&"heroes") as Node3D
	var center: Vector3 = ford.get("center", Vector3(-8.5, 0.0, -34.0))
	# The RTS camera (the Camera3D's parent) drifts to a corner headless (edge pan with the mouse at 0, 0): stop that and
	# look at the ford (waders are only searched within 70 m of the camera's ground point).
	var cam := root.get_camera_3d()
	var rig: Node = cam.get_parent() if cam else null
	if rig and rig.has_method(&"focus_on"):
		rig.set(&"edge_pan_enabled", false)
		rig.call(&"focus_on", center)
	hero.global_position = Vector3(center.x, hero.global_position.y, center.z)
	if hero.has_method(&"command_stop"):
		hero.call(&"command_stop")
	await _frames(40)
	var w: Array = mv.call(&"waders")
	if not w.has(hero):
		var hp := hero.global_position
		var grid: PackedByteArray = mv.get(&"_wade_grid")
		var gi := int((hp.z + 64.0) * 2.0) * 256 + int((hp.x + 64.0) * 2.0)
		_fail("phase 2: the hero in Reed Ford is not wading (hero at %s, visible %s, camera ground %s, grid %s, fords %s)"
				% [hp, hero.is_visible_in_tree(), mv.call(&"_camera_pos"), grid[gi] if gi < grid.size() else -1,
				mv.get(&"_fords")])
	if int(mv.call(&"ripple_count")) == 0:
		_fail("phase 2: no ripples in Reed Ford")
	var pts := get_first_node_in_group(&"capture_points_service")
	var shrines: Array = pts.call(&"points", &"shrine")
	var wells: Array = pts.call(&"points", &"well")
	if shrines.is_empty() or wells.is_empty():
		_fail("phase 2: no shrine / well")
	else:
		shrines[0].call(&"wake")
		wells[0].call(&"play_pulse")
		var ids: Array = mv.call(&"active_ids")
		if not ids.has(&"shrine_awaken") or not ids.has(&"well_pulse"):
			_fail("phase 2: CapturePoint wake / play_pulse did not reach MapFillVfx (%s)" % [ids])
	# Blessing through the real service: every soldier / wizard of team 0 with the modifier gets a rune.
	if pts.has_signal(&"blessing_started"):
		var hooked: Dictionary = mv.get(&"_hooked")
		if not hooked.has(pts.get_instance_id()):
			_fail("phase 2: not hooked to CapturePoints")
		var cm := get_first_node_in_group(&"camp_manager")
		if cm != null and not hooked.has(cm.get_instance_id()):
			_fail("phase 2: not hooked to CampManager")
	done = true


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _setup() -> void:
	# Services first: the effects node hooks them on its first frame.
	_node(RIVER_SRC, &"river")
	cps = _node(CPS_SRC, &"capture_points_service", false)
	cm = _node(CM_SRC, &"camp_manager", false)
	camp = _node(CAMP_SRC, &"neutral_camps") as Node3D
	camp.position = Vector3(-20.0, 0.0, 20.0)
	point = _node(POINT_SRC, &"") as Node3D
	point.position = Vector3(-20.0, 0.0, -20.0)
	var gs := load(VFX_PATH) as GDScript
	if gs == null:
		_fail("cannot load %s" % VFX_PATH)
		return
	vfx = gs.new()
	vfx.name = "MapFillVfx"
	vfx.set(&"beast_vfx_path", BEAST_STUB_PATH)
	world.add_child(vfx)
	vfx_nb = gs.new()
	vfx_nb.name = "MapFillVfxNoBeast"
	vfx_nb.set(&"beast_vfx_path", "res://art/vfx/__no_such_beast_vfx.gd")
	vfx_nb.set(&"auto_hooks", false)
	vfx_nb.set(&"auto_wade", false)
	world.add_child(vfx_nb)
	if get_first_node_in_group(&"mapfill_vfx") == null:
		_fail("no node in group mapfill_vfx")
	if vfx.call(&"beast_vfx") == null or vfx.get_node_or_null("BeastVfx") == null:
		_fail("beast stub not loaded as child BeastVfx")
	elif vfx.call(&"beast_vfx").get(&"host") != vfx:
		_fail("beast stub setup(host) not called")
	if vfx_nb.call(&"beast_vfx") != null:
		_fail("a beast object without a beast file")
	wader_a = _unit("WaderA", 0, Vector3(0.5, 0.0, 1.0))
	wader_a.set(&"velocity", Vector3(1.5, 0.0, 0.0))
	bank_u = _unit("BankUnit", 0, Vector3(3.2, 0.0, 0.0))
	hidden_u = _unit("HiddenUnit", 1, Vector3(-1.0, 0.0, -1.0))
	hidden_u.visible = false
	far_u = _unit("FarUnit", 0, Vector3(12.0, 0.0, 12.0))
	amph = _unit("Mirefang", 2, Vector3(0.0, 0.0, 10.0))
	amph.add_to_group(&"amphibious")
	bl_a = _unit("BlessedA", 0, Vector3(20.0, 0.0, 20.0), true)
	bl_b = _unit("BlessedB", 0, Vector3(22.0, 0.0, 20.0), true)
	bl_c = _unit("TeamNoMod", 0, Vector3(24.0, 0.0, 20.0), false)
	bl_d = _unit("EnemyMod", 1, Vector3(26.0, 0.0, 20.0), true)
	explicit_u = _unit("Explicit", 1, Vector3(28.0, 0.0, 20.0), false)
	explicit_u.set_script(null)   # a plain Node3D: no has_modifier, kept for 60 s by play(&"blessing")
	explicit_u.add_to_group(&"units")
	children_before = vfx.get_child_count()
	mats_before = _materials(vfx)


func _unit(uname: String, team: int, pos: Vector3, blessed: bool = false) -> Node3D:
	var u := Node3D.new()
	u.set_script(unit_s)
	u.name = uname
	u.set(&"team", team)
	if blessed:
		u.set(&"mods", {&"blessing:wayshrine": {}})
	u.add_to_group(&"units")
	world.add_child(u)
	u.position = pos
	return u


func _spawn_crowd() -> void:
	for i in 12:
		var u := _unit("Crowd%d" % i, i % 2, Vector3(-1.5 + float(i % 4), 0.0, -2.0 + float(i / 4) * 1.5))
		u.set(&"velocity", Vector3(0.0, 0.0, 2.0))
		crowd.append(u)


func _play_all() -> void:
	var effects: Array = vfx.get(&"EFFECTS")
	# Unknown id, no beast file: nothing, no error. No position: nothing.
	vfx_nb.call(&"play", &"not_a_mapfill_effect", Vector3.ZERO, null)
	vfx_nb.call(&"play", &"gore_charge", Vector3.ZERO, null)
	vfx_nb.call(&"play", &"capture_done", null, null)
	if int(vfx_nb.call(&"active_count")) != 0 or int(vfx_nb.call(&"live_count")) != 0:
		_fail("unknown id / no position started something")
	var spots := 0
	for id: StringName in effects:
		spots += 1
		var tgt: Node3D = point
		match id:
			&"blessing":
				tgt = explicit_u
			&"wade":
				tgt = far_u
			&"antler_sweep", &"spore_burst", &"camp_respawn", &"camp_cleared":
				tgt = camp if id.begins_with("camp") else bl_c
		var p := Vector3(-30.0 + float(spots) * 6.0, 0.0, -10.0)
		var before := _counts(vfx_nb)
		vfx_nb.call(&"play", id, p, tgt)
		if _counts(vfx_nb) <= before:
			_fail("%s with a target started nothing" % id)
		before = _counts(vfx_nb)
		vfx_nb.call(&"play", id, p + Vector3(0.0, 0.0, 8.0), null)
		if _counts(vfx_nb) <= before and id != &"blessing":
			_fail("%s without a target started nothing" % id)
		if id == &"blessing" and int(vfx_nb.call(&"live_count")) == 0:
			_fail("blessing without a unit showed nothing")
	# The same effects on the node with hooks (for the timing checks) + `at` as a Node3D.
	for id: StringName in effects:
		if id != &"wade" and id != &"blessing":
			vfx.call(&"play", id, Vector3(float(effects.find(id)) * 7.0 - 30.0, 0.0, -25.0),
					camp if id.begins_with("camp") else point)
	vfx.call(&"play", &"blessing", explicit_u, explicit_u)
	var before_dup: int = vfx.call(&"active_count")
	vfx.call(&"play", &"well_pulse", point, point)
	vfx.call(&"play", &"well_pulse", point, point)
	if int(vfx.call(&"active_count")) != before_dup + 1:
		_fail("same id + spot twice in one frame did not play exactly once")
	# Forwarding.
	vfx.call(&"play", &"gore_charge", Vector3(1, 0, 1), wader_a)
	vfx.call(&"play", &"beast_spawn", Vector3(5, 0, 5), null)
	var calls: Array = vfx.call(&"beast_vfx").get(&"calls")
	if calls != [&"gore_charge", &"beast_spawn"]:
		_fail("beast stub calls %s (expected [gore_charge, beast_spawn]: own ids must not be forwarded)" % [calls])
	if vfx.get_child_count() != children_before or _materials(vfx) != mats_before:
		_fail("nodes / materials created at runtime")
	if int(vfx.call(&"live_count")) == 0:
		_fail("nothing visible after playing every effect")


func _counts(v: Node) -> int:
	return int(v.call(&"active_count")) + int(v.call(&"ripple_count")) + int(v.call(&"rune_count")) \
			+ int(v.call(&"live_count"))


## The ids the finished code sends must be ours; beast ids must not be (they are forwarded to 12.V31).
func _check_callers() -> void:
	var effects: Array = vfx.get(&"EFFECTS")
	var cp := FileAccess.get_file_as_string("res://scripts/world/capture_point.gd")
	if cp != "":
		var re := RegEx.create_from_string("_play_vfx\\(&\"(\\w+)\"\\)")
		var found := 0
		for m in re.search_all(cp):
			found += 1
			if not effects.has(StringName(m.get_string(1))):
				_fail("capture_point.gd plays '%s', not in EFFECTS" % m.get_string(1))
		if found < 3:
			_fail("capture_point.gd: expected 3 _play_vfx ids, found %d" % found)
	for id: StringName in [&"spore_burst", &"antler_sweep"]:
		if not effects.has(id):
			_fail("%s missing from EFFECTS" % id)
	for id in BEAST_IDS:
		if effects.has(id):
			_fail("beast id %s must be forwarded, not played here" % id)


func _final_checks() -> void:
	if max_rings < 8:
		_fail("ripple pool barely used (max %d rings alive with 7+ waders)" % max_rings)
	for v: Node3D in [vfx, vfx_nb]:
		if int(v.call(&"live_count")) != 0:
			_fail("%s: pieces / bursts / rings / runes still alive at the end (%d)" % [v.name, v.call(&"live_count")])
		if int(v.call(&"active_count")) != 0:
			_fail("%s: effects still running at the end: %s" % [v.name, v.call(&"active_ids")])
		for c in v.get_children():
			if c is GPUParticles3D and (c as GPUParticles3D).visible:
				_fail("%s: burst %s still shown" % [v.name, c.name])
				break
			if c is MeshInstance3D and (c as MeshInstance3D).visible:
				_fail("%s: piece %s still visible" % [v.name, c.name])
				break
		var free: Dictionary = v.get(&"_free")
		var sizes: Dictionary = v.get(&"POOL_SIZES")
		for pool: StringName in sizes:
			if (free[pool] as Array).size() != int(sizes[pool]):
				_fail("%s: pool %s has %d free of %d (leak)" % [v.name, pool, (free[pool] as Array).size(), sizes[pool]])
	if vfx.get_child_count() != children_before:
		_fail("nodes created during the run")
	if _materials(vfx) != mats_before:
		_fail("materials created during the run")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BEAST_STUB_PATH))


## Instance ids of every material, mesh, multimesh and process material the pools use.
func _materials(v: Node) -> Dictionary:
	var out: Dictionary = {}
	for c in v.get_children():
		if c is MeshInstance3D:
			out[(c as MeshInstance3D).material_override.get_instance_id()] = true
			out[(c as MeshInstance3D).mesh.get_instance_id()] = true
		elif c is MultiMeshInstance3D:
			var mm := (c as MultiMeshInstance3D).multimesh
			out[mm.get_instance_id()] = true
			out[mm.mesh.get_instance_id()] = true
			out[mm.mesh.surface_get_material(0).get_instance_id() if mm.mesh.get_surface_count() > 0 else 0] = true
		elif c is GPUParticles3D:
			var p := c as GPUParticles3D
			out[p.process_material.get_instance_id()] = true
			out[p.draw_pass_1.get_instance_id()] = true
			out[(p.draw_pass_1 as PrimitiveMesh).material.get_instance_id()] = true
	return out


func _fail(why: String) -> void:
	fails.append(why)
	print("  fail: ", why)

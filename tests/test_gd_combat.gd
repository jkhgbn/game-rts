extends SceneTree
## G-D combat feedback (docs/art/gd_combat_feedback.md): CombatVfx + its CombatFxG layer, headless.
## - Low tier: the layer builds nothing (no MultiMesh, no node), CombatVfx keeps its pre-G look.
## - High tier (CombatFxG.test_tier): melee hits on each material write pieces; the per-frame event cap holds under a
##   200-hit burst; no node is added per hit / death / building event once warm; a death writes a ground mark; a building
##   cracks at 66 % and 33 %, burns, and its destruction writes a collapse (rubble); a site cancel writes none.
## - Fog: an enemy hit where the local player does not see is skipped; an enemy ground mark hides when the fog covers it.
## - Systems with nothing alive draw nothing (visible_instance_count back to 0).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gd_combat.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "gd_combat"

var _fails: Array[String] = []
var _stage: Node3D
var _added := 0
var _counting := false
var _g_node: Node = null


class FogStub extends Node:
	var enabled := true
	var local_team := 0
	var see := true

	func is_visible(_team: int, _pos: Vector3) -> bool:
		return see


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_materials()
	# --- Low: nothing built.
	CombatFxG.test_tier = 0
	_stage = Node3D.new()
	root.add_child(_stage)
	var low := CombatVfx.new()
	_stage.add_child(low)
	await process_frame
	var lg := low.get_node_or_null(^"CombatFxG") as CombatFxG
	_check(lg != null, "CombatVfx has no CombatFxG child")
	if lg:
		_check(not lg.active() and lg.get_child_count() == 0, "Low tier: CombatFxG built pieces (%d children)" % lg.get_child_count())
	low.queue_free()
	await process_frame
	# --- The real path (no test_tier): _ready reads GameSettings.effective_graphics_quality() (Low headless), a Settings
	# change reaches it through the "lighting_rigs" group (GameSettings.apply_graphics).
	CombatFxG.test_tier = -1
	var real := CombatVfx.new()
	_stage.add_child(real)
	await process_frame
	var rg := real.get_node(^"CombatFxG") as CombatFxG
	_check(GameSettings.effective_graphics_quality() == GameSettings.GFX_LOW, "headless effective tier is not Low")
	_check(not rg.active() and rg.get_child_count() == 0, "real path: CombatFxG active / built at the headless Low tier")
	_check(rg.is_in_group(&"lighting_rigs"), "CombatFxG not in group lighting_rigs")
	call_group(&"lighting_rigs", &"set_quality", GameSettings.GFX_HIGH)
	_check(rg.active() and rg.get_child_count() == CombatFxG.CAPS.size(), "set_quality(2) did not build the layer")
	_check(real.g_layer() == rg, "CombatVfx.g_layer() is not the layer after set_quality(2)")
	call_group(&"lighting_rigs", &"set_quality", GameSettings.GFX_LOW)
	var hidden := true
	for c in rg.get_children():
		hidden = hidden and not (c as Node3D).visible
	_check(not rg.active() and hidden and real.g_layer() == null, "set_quality(0) did not turn the layer off / hide it")
	real.queue_free()
	await process_frame
	# --- High.
	CombatFxG.test_tier = 2
	var vfx := CombatVfx.new()
	_stage.add_child(vfx)
	await process_frame
	var g := vfx.get_node(^"CombatFxG") as CombatFxG
	_g_node = g
	_check(g.active(), "High tier: CombatFxG not active")
	var mmis := 0
	for c in g.get_children():
		if c is MultiMeshInstance3D:
			mmis += 1
	_check(mmis == CombatFxG.CAPS.size(), "expected %d MultiMeshes, got %d" % [CombatFxG.CAPS.size(), mmis])
	var a := _unit("flame_guard", 0, Vector3(-0.8, 0, 0))
	var targets: Array[Unit] = []
	for id: String in ["rimeshield", "ember_archer", "shade", "thornling", "rimeling", "ruin_warden"]:
		targets.append(_unit(id, 1, Vector3(0.8, 0, 0)))
	await process_frame
	await process_frame
	vfx.watch(a)
	# One hit per material, one per frame.
	for t in targets:
		var before := g.written(CombatFxG.Sys.SPARK) + g.written(CombatFxG.Sys.PUFF) + g.written(CombatFxG.Sys.CHIP)
		a.attack_landed.emit(t, 10.0)
		var after := g.written(CombatFxG.Sys.SPARK) + g.written(CombatFxG.Sys.PUFF) + g.written(CombatFxG.Sys.CHIP)
		_check(after > before, "a hit on %s wrote no pieces" % t.unit_type.id)
		await process_frame
	# Per-frame cap under a 200-hit burst.
	await process_frame
	var ev0 := int(g.stats()["events"])
	for i in 200:
		a.attack_landed.emit(targets[i % targets.size()], 10.0)
	var ev := int(g.stats()["events"]) - ev0
	_check(ev <= CombatFxG.EVENTS_PER_FRAME[2], "200 hits in a frame took %d events (cap %d)" % [ev, CombatFxG.EVENTS_PER_FRAME[2]])
	_check(ev > 0, "no hit event taken in the burst frame")
	# No node per event once warm.
	node_added.connect(_on_node_added)
	_counting = true
	for f in 30:
		for t in targets:
			a.attack_landed.emit(t, 10.0)
		await process_frame
	# Deaths (CombatVfx listens to Events.unit_died).
	var d0 := int(g.stats()["deaths"])
	var m0 := g.written(CombatFxG.Sys.MARK)
	var victims: Array[Unit] = []
	for k in 4:
		victims.append(_unit(["flame_guard", "shade", "rimeshield", "thornling"][k], 0, Vector3(4.0 + k * 2.0, 0, 3.0)))
	_counting = false
	await process_frame
	await process_frame
	_counting = true
	for v in victims:
		v.take_damage(999999.0, null)
	await process_frame
	_check(int(g.stats()["deaths"]) - d0 == 4, "4 deaths gave %d G deaths" % (int(g.stats()["deaths"]) - d0))
	_check(g.written(CombatFxG.Sys.MARK) - m0 == 4, "4 deaths wrote %d ground marks" % (g.written(CombatFxG.Sys.MARK) - m0))
	# Building stages + collapse.
	_counting = false
	var b := _building(&"fire_barracks", 1, Vector3(20, 0, 0))
	var site := _building(&"fire_barracks", 1, Vector3(40, 0, 0))
	await process_frame
	await process_frame
	vfx.watch(b)
	vfx.watch(site)
	_counting = true
	var r0 := g.written(CombatFxG.Sys.RUBBLE)
	b.take_damage(b.max_hp * 0.4, a)
	_check(int(g.stats()["cracks"]) == 1, "66 %% crack missing (cracks %d)" % int(g.stats()["cracks"]))
	b.take_damage(b.max_hp * 0.3, a)
	_check(int(g.stats()["cracks"]) == 2, "33 %% crack missing (cracks %d)" % int(g.stats()["cracks"]))
	_check(int(g.stats()["burning"]) == 1, "the damaged building is not burning")
	for f in 20:
		await process_frame
	b.take_damage(b.max_hp * 2.0, a)
	_check(int(g.stats()["collapses"]) == 1, "destroyed building wrote no collapse")
	_check(g.written(CombatFxG.Sys.RUBBLE) - r0 > 20, "collapse wrote too little rubble")
	_check(int(g.stats()["burning"]) == 0, "a destroyed building stays in the burning list")
	# Off-screen collapse: no dust / debris burst, but the rubble pile + stain are still laid.
	var b2 := _building(&"fire_barracks", 1, Vector3(60, 0, 0))
	var cam := Camera3D.new()
	_stage.add_child(cam)
	cam.global_position = Vector3(-200, 30, -200)
	cam.look_at(Vector3(-200, 0, -230))
	cam.make_current()
	await process_frame
	await process_frame
	vfx.watch(b2)
	var c0 := int(g.stats()["collapses"])
	var rb0 := g.written(CombatFxG.Sys.RUBBLE)
	var pf0 := g.written(CombatFxG.Sys.PUFF)
	var mk0 := g.written(CombatFxG.Sys.MARK)
	b2.take_damage(b2.max_hp * 2.0, a)
	_check(int(g.stats()["collapses"]) == c0 + 1, "off-screen collapse not counted")
	_check(g.written(CombatFxG.Sys.RUBBLE) > rb0 and g.written(CombatFxG.Sys.MARK) > mk0,
			"off-screen collapse laid no rubble pile / stain")
	_check(g.written(CombatFxG.Sys.PUFF) == pf0, "off-screen collapse spawned the dust burst")
	cam.queue_free()
	await process_frame
	if site.has_method(&"cancel_construction"):
		var cs0 := int(g.stats()["collapses"])
		site.make_site()
		site.cancel_construction()
		await process_frame
		_check(int(g.stats()["collapses"]) == cs0, "a cancelled site played a collapse")
	await process_frame
	_counting = false
	_check(_added == 0, "%d nodes added under CombatFxG for hits / deaths / buildings (per-event nodes)" % _added)
	# Fog: an enemy (team 1) hit / mark where the local player does not see.
	var fog := FogStub.new()
	fog.add_to_group(&"fog")
	root.add_child(fog)
	await process_frame
	var enemy := _unit("shade", 1, Vector3(-30, 0, 0))
	var mine := _unit("flame_guard", 0, Vector3(-30.8, 0, 0))
	await process_frame
	await process_frame
	vfx.watch(enemy)
	fog.see = true
	var shown0 := int(g.stats()["marks_shown"])
	g.unit_death(enemy, 1, false, 1)   # an enemy death in sight: its mark shows
	await process_frame
	_check(int(g.stats()["marks_shown"]) == shown0 + 1, "enemy mark in sight not shown")
	fog.see = false
	for f in 20:
		await process_frame
	_check(int(g.stats()["marks_shown"]) <= shown0, "enemy mark still shown under fog (%d > %d)" % [int(g.stats()["marks_shown"]), shown0])
	var sk0 := int(g.stats()["skipped"])
	var ev1 := int(g.stats()["events"])
	enemy.attack_landed.emit(mine, 10.0)
	_check(int(g.stats()["events"]) == ev1, "an enemy hit in the fog was drawn")
	_check(int(g.stats()["skipped"]) > sk0, "an enemy hit in the fog was not counted as skipped")
	fog.queue_free()
	# Sparks end: their MultiMesh draws nothing again.
	for f in 330:   # collapse embers live up to ~4.1 s
		await process_frame
	var sp := (g.get_child(CombatFxG.Sys.SPARK) as MultiMeshInstance3D).multimesh
	_check(sp.visible_instance_count == 0, "spark MultiMesh still drawing %d after every spark ended" % sp.visible_instance_count)
	print("gd_combat: stats %s" % g.stats())
	CombatFxG.test_tier = -1
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	_stage.queue_free()
	quit()


func _check_materials() -> void:
	var cases := {"rimeshield": CombatFxG.Mat.STEEL, "flame_guard": CombatFxG.Mat.STEEL, "shade": CombatFxG.Mat.BONE,
			"thornling": CombatFxG.Mat.WOOD, "rimeling": CombatFxG.Mat.ICE, "ruin_warden": CombatFxG.Mat.STONE,
			"ember_archer": CombatFxG.Mat.FLESH, "grave_hound": CombatFxG.Mat.BONE, "shardguard": CombatFxG.Mat.ICE,
			"ironhide_tusker": CombatFxG.Mat.FLESH, "greymane_direwolf": CombatFxG.Mat.FLESH,
			"elder_grizzlemaw": CombatFxG.Mat.FLESH, "old_scarback": CombatFxG.Mat.FLESH, "hollow_stag": CombatFxG.Mat.FLESH,
			"hollow_oathsworn": CombatFxG.Mat.BONE, "barrow_knight": CombatFxG.Mat.STEEL}
	for id: String in ["hoarlight_magebow", "nightbolt", "shardcaster"]:
		_check(not CombatFxG.is_physical_id(id), "%s counted as a physical shooter" % id)
	for id: String in ["frostbow", "ember_archer", "fire_tower", "burr_slinger"]:
		_check(CombatFxG.is_physical_id(id), "%s not counted as a physical shooter" % id)
	for id: String in cases:
		var t := UnitType.find(StringName(id))
		var armor := float(t.armor) if t else 0.0
		var m := CombatFxG.material_of_id(id, armor)
		_check(m == int(cases[id]), "material of %s = %s, expected %s" % [id, CombatFxG.MAT_NAMES[m], CombatFxG.MAT_NAMES[int(cases[id])]])


func _unit(id: String, team: int, pos: Vector3) -> Unit:
	var u := Worker.make_unit(UnitType.find(StringName(id)))
	u.team = team as Unit.Team
	_stage.add_child(u)
	u.global_position = pos
	u.max_hp = 100000.0 if u.max_hp > 0.0 else 100000.0
	u.hp = u.max_hp
	u.aggro_range = 0.0
	u.attack_damage = 0.0
	return u


func _building(id: StringName, team: int, pos: Vector3) -> Building:
	var b := BuildGrid.create_building(BuildingType.find(id))
	b.team = team as Unit.Team
	_stage.add_child(b)
	b.global_position = pos
	return b


func _on_node_added(n: Node) -> void:
	if _counting and _g_node and is_instance_valid(_g_node) and _g_node.is_ancestor_of(n):
		_added += 1


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)

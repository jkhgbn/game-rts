extends SceneTree
## G-B spell VFX layer (art/vfx/spells_g/spell_fx_g.gd, docs/art/gb_spell_vfx.md).
## 1. Low (every headless run): no SpellFxG is ever built; the hubs keep their own lights (Low = the look before G-B).
## 2. The hubs call only recipe ids SpellFxG knows, and every recipe is called by a hub (source scan).
## 3. High (SpellFxG.test_tier): one layer per level, pools sized by tier, every recipe plays without growing the node
##    count (round 2 = round 1), everything is back in its pool after the longest piece, the hubs' light flashes are
##    routed to it, a tier change rebuilds it and Low drops it again.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gb_vfx.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "gb_vfx"
const HUBS := ["res://art/vfx/spell_vfx.gd", "res://art/vfx/ice_vfx.gd", "res://art/vfx/nature_vfx.gd",
		"res://art/vfx/caster_fire_vfx.gd", "res://art/vfx/caster_ice_vfx.gd", "res://art/vfx/caster_nature_vfx.gd",
		"res://art/vfx/caster_shadow_vfx.gd"]

var _fails: Array[String] = []
var _level: Node3D
var _done := false


func _initialize() -> void:
	_level = Node3D.new()
	_level.name = "GbLevel"
	root.add_child(_level)
	current_scene = _level
	var cam := Camera3D.new()
	_level.add_child(cam)
	cam.transform = Transform3D.IDENTITY.looking_at(Vector3(0, -16, -11)).translated(Vector3(0, 16, 11))
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


func _run() -> void:
	# ---- 1. Low
	SpellFxG.test_tier = -1
	var spell := _hub(SpellVfx)
	var ice := _hub(IceVfx)
	var nature := _hub(NatureVfx)
	var unit_vfx := _hub(UnitVfx)
	await _frames(3)
	_check(SpellFxG.tier() == SpellFxG.TIER_LOW, "headless run is not Low (tier %d)" % SpellFxG.tier())
	_check(SpellFxG.live(spell) == null, "SpellFxG built at Low")
	spell.call(&"_light_flash", Vector3.ZERO, Color.ORANGE, 2.0, 5.0, 0.3)
	unit_vfx.call(&"play", &"slag_rain", Vector3(2, 0, 0), Vector3(-3, 1, 0))
	unit_vfx.call(&"play", &"snagroot", Vector3(-3, 1, 0), Vector3(2, 0, 0))
	ice.call(&"_light_flash", Vector3.ZERO, Color.CYAN, 0.7, 5.0, 0.3)
	await _frames(5)
	_check(root.get_tree().get_nodes_in_group(SpellFxG.GROUP).is_empty(), "a spell_fx_g node exists at Low")
	var lit := 0
	for l in (spell.get(&"_lights") as Array):
		if (l as OmniLight3D).visible:
			lit += 1
	_check(lit >= 1, "Low: SpellVfx's own light flash did not show")

	# ---- 2. ids
	var called := {}
	var re := RegEx.new()
	re.compile("(?:g\\.play|_gplay)\\(&\"([a-z_]+)\"")
	var re_if := RegEx.new()
	re_if.compile("_gplay\\(&\"([a-z_]+)\" if [^\\n]* else &\"([a-z_]+)\"")
	for path: String in HUBS:
		var src := FileAccess.get_file_as_string(path)
		_check(src != "", "cannot read %s" % path)
		for m in re.search_all(src):
			called[StringName(m.get_string(1))] = path
		for m in re_if.search_all(src):
			called[StringName(m.get_string(2))] = path
		if "SpellVfx" in path or "spell_vfx" in path:
			called[&"fireball_cast"] = path      # built as id + "_cast"
			called[&"shadow_lance_cast"] = path
			for id: StringName in [&"fireball_fly", &"lance_fly"]:
				called[id] = path
		if "nature_vfx.gd" == path.get_file():
			for id: StringName in [&"thornburst", &"wild_bloom", &"call_the_thicket"]:
				called[id] = path   # g.play(id, ...) with the spell id
	called[&"slag_land"] = "spell_fx_g (scheduled by slag_rain)"
	for id: StringName in called:
		_check(SpellFxG.RECIPES.has(id), "%s calls unknown recipe %s" % [called[id], id])
	for id: StringName in SpellFxG.RECIPES:
		_check(called.has(id), "recipe %s is never called by a hub" % id)

	# ---- 3. High
	SpellFxG.test_tier = SpellFxG.TIER_HIGH
	var g := SpellFxG.live(spell)
	_check(g != null, "no SpellFxG at High")
	if g == null:
		_finish()
		return
	_check(SpellFxG.live(ice) == g and SpellFxG.live(unit_vfx) == g, "two SpellFxG for one level")
	var sizes := g.pool_sizes()
	_check(int(sizes[&"billow"]) == int(SpellFxG.CAPS[&"billow"][2]) and int(sizes[&"light"]) == int(SpellFxG.CAPS[&"light"][2])
			and int(sizes[&"distort"]) == int(SpellFxG.CAPS[&"distort"][2]), "High pool sizes %s" % sizes)
	var proj := Node3D.new()
	_level.add_child(proj)
	var counts: Array[int] = []
	for round_i in 2:
		for id: StringName in SpellFxG.RECIPES:
			var opts := {"r": 3.0, "dir": Vector3.FORWARD, "from": Vector3(-4, 2, 0), "axis": Vector3.RIGHT}
			if id.ends_with("_fly"):
				opts["node"] = proj
			g.play(id, Vector3(float(round_i), 0, 0), opts)
		await _frames(2)
		_check(g.live_count() > 0, "nothing on screen after playing every recipe")
		proj.visible = false   # the projectile 'lands': followers end
		await _secs(4.5)
		proj.visible = true
		counts.append(_count(g))
		_check(g.live_count() == 0, "round %d: %d pieces still live after 4.5 s" % [round_i, g.live_count()])
	_check(counts[0] == counts[1], "node count grew between rounds: %s" % [counts])
	# light routing
	var before := g.live_count()
	spell.call(&"_light_flash", Vector3.ZERO, Color.ORANGE, 2.0, 5.0, 0.3)
	nature.call(&"_light_flash", Vector3.ZERO, Color.GREEN, 1.4, 5.0, 0.3)
	await _frames(2)
	_check(g.live_count() >= before + 2, "hub light flashes not routed to SpellFxG")
	# fog: an enemy (or unknown-team) effect in fog the local team does not see draws nothing
	await _check_fog(g)
	# a second live() while the first layer's add_child is deferred keeps that one (no duplicate)
	var pending := SpellFxG.new()
	pending.tier_built = SpellFxG.TIER_HIGH
	var live_one: SpellFxG = SpellFxG._inst
	SpellFxG._inst = pending
	SpellFxG._pending_ms = Time.get_ticks_msec()
	_check(SpellFxG.live(spell) == null and SpellFxG._inst == pending, "a pending (deferred) layer was dropped")
	_check(root.get_tree().get_nodes_in_group(SpellFxG.GROUP).size() == 1, "a second layer was built next to a pending one")
	SpellFxG._inst = live_one
	pending.free()
	# tier change rebuilds, Low drops
	SpellFxG.test_tier = SpellFxG.TIER_ULTRA
	var g2 := SpellFxG.live(spell)
	_check(g2 != null and g2 != g and g2.tier_built == SpellFxG.TIER_ULTRA, "no Ultra rebuild")
	await _frames(2)
	_check(not is_instance_valid(g) or g.is_queued_for_deletion() or not g.is_inside_tree(), "old High layer kept")
	if g2:
		_check(int(g2.pool_sizes()[&"distort"]) == int(SpellFxG.CAPS[&"distort"][3]), "Ultra pool sizes")
	SpellFxG.test_tier = SpellFxG.TIER_LOW
	_check(SpellFxG.live(spell) == null, "SpellFxG still live at Low")
	await _frames(2)
	_check(root.get_tree().get_nodes_in_group(SpellFxG.GROUP).is_empty(), "SpellFxG kept after switching to Low")
	SpellFxG.test_tier = -1
	_finish()


## Fake fog: the local team (PLAYER) sees x < 50 only.
func _check_fog(g: SpellFxG) -> void:
	var src := GDScript.new()
	src.source_code = "extends Node\nvar enabled := true\nvar local_team := 0\nfunc is_visible(_team: int, p: Vector3) -> bool:\n\treturn p.x < 50.0\n"
	src.reload()
	var fog: Node = src.new()
	fog.add_to_group(&"fog")
	_level.add_child(fog)
	fog.set(&"local_team", int(Unit.Team.PLAYER))
	await _frames(2)
	var enemy := int(Unit.Team.ENEMY)
	var mine := int(Unit.Team.PLAYER)
	var hidden := Vector3(60, 0, 0)   # in the fog, inside the 70 m particle / 90 m light range
	var n0 := g.live_count()
	g.play(&"fireball_impact", hidden, {"r": 3.5, "team": enemy})
	g.play(&"soul_siphon", hidden, {"r": 4.0})
	g.light(hidden, Color.ORANGE, 3.5, 5.0, 0.4)
	await _frames(2)
	_check(g.live_count() == n0, "an enemy / unknown-team effect in fog drew %d pieces" % (g.live_count() - n0))
	g.play(&"fireball_impact", hidden, {"r": 3.5, "team": mine})
	await _frames(2)
	_check(g.live_count() > n0, "the local team's own effect in fog was hidden")
	var shot := Node3D.new()
	_level.add_child(shot)
	shot.set_process(true)
	shot.global_position = Vector3(10, 1, 0)
	g.play(&"fireball_fly", shot.global_position, {"node": shot, "team": enemy})
	await _frames(2)
	var shown := _visible_followers(g, shot.global_position)
	shot.global_position = Vector3(55, 1, -20)   # in the fog, away from the own impact above
	await _secs(0.4)
	var after := _visible_followers(g, shot.global_position)
	_check(shown > 0 and after == 0, "an enemy fireball flying into fog still shows (%d -> %d)" % [shown, after])
	shot.queue_free()
	fog.queue_free()
	await _secs(2.5)


func _visible_followers(g: SpellFxG, at: Vector3) -> int:
	var c := 0
	for n in g.get_children():
		if (n is MeshInstance3D or n is OmniLight3D or n is GPUParticles3D) and (n as Node3D).visible \
				and (n as Node3D).global_position.distance_to(at) < 3.0:
			c += 1
	return c


func _finish() -> void:
	SpellFxG.test_tier = -1
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  - ", f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	_done = true


func _hub(script: GDScript) -> Node3D:
	var n: Node3D = script.new()
	_level.add_child(n)
	return n


func _count(n: Node) -> int:
	var c := n.get_child_count()
	for ch in n.get_children():
		c += _count(ch)
	return c


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _secs(s: float) -> void:
	await create_timer(s).timeout

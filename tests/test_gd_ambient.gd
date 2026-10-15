extends SceneTree
## G-D ambient life (docs/art/gd_ambient.md, art/environment/ambient/ambient_life.gd).
## Static: the tier plan (Low = nothing, Medium < High <= Ultra, hard cap), mood detection and ratios, the flock path
## mirror. Then a skirmish (bot off) with AmbientLife forced to High headless (allow_headless + quality_override set
## before the level enters the tree, so main.gd's hook + the HUD's settings broadcast build it the real way):
##   - the level's node is built (children); ensure() returns null headless by default and at Low; is idempotent;
##   - the emitters and 3 flocks are built, candidates exist (meadow, water, trees);
##   - fog: with the focus over never-explored ground every emission point is explored (no particles in black fog);
##     near the base there are points;
##   - birds: enemy soldiers spawned in fog (fresh, before the fog pass, and hidden after it) never scare a flock;
##     an own army in view does; no dark spot / not every enemy hidden = FAIL;
##   - mood: the night preset turns birds off and fireflies on; set_quality(0) frees every child.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gd_ambient.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "gd_ambient"
const LOAD_TIMEOUT_FRAMES := 5000
const AMBIENT := "res://art/environment/ambient/ambient_life.gd"
const NIGHT := "res://art/environment/lighting/emberfall_night.gd"

var main: Node = null
var fog: Node = null
var _frame := 0
var _started := false
var _done := false
var _fails: Array[String] = []
var _notes: Array[String] = []


func _initialize() -> void:
	_static_checks()
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	# The real level path: main.gd's hook calls AmbientLife.ensure in _ready, the HUD's settings broadcast follows.
	var al := load(AMBIENT) as GDScript
	al.set(&"quality_override", 2)
	al.set(&"allow_headless", true)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	_frame += 1
	if not _started:
		if main.get(&"hero") != null and main.get(&"fog") != null and bool(main.get(&"match_started")):
			_started = true
			_run.call_deferred()
		elif _frame > LOAD_TIMEOUT_FRAMES:
			_fails.append("the skirmish never finished loading")
			_finish()
	return _done


func _static_checks() -> void:
	var al := load(AMBIENT) as GDScript
	var day := {"night": false, "snow": false, "autumn": false, "marsh": false}
	var low: Dictionary = al.call(&"plan", 0, day)
	for k: StringName in low:
		if int(low[k]) != 0:
			_fails.append("Low plan is not empty: %s" % str(low))
			break
	var med: Dictionary = al.call(&"plan", 1, day)
	var high: Dictionary = al.call(&"plan", 2, day)
	var ultra: Dictionary = al.call(&"plan", 3, day)
	var sm := 0
	var sh := 0
	var su := 0
	for k: StringName in high:
		sm += int(med[k])
		sh += int(high[k])
		su += int(ultra[k])
		if int(ultra[k]) < int(high[k]) or int(high[k]) < int(med[k]):
			_fails.append("tier plan not monotonic for %s: %d / %d / %d" % [k, med[k], high[k], ultra[k]])
	if not (sm < sh):
		_fails.append("Medium (%d) is not lighter than High (%d)" % [sm, sh])
	var caps: Dictionary = al.get_script_constant_map()["CAPS"]
	var total := 0
	for k: StringName in caps:
		total += int((caps[k] as Array)[3])
	if total > int(al.get_script_constant_map()["MAX_PARTICLES"]):
		_fails.append("Ultra caps add to %d > MAX_PARTICLES" % total)
	# Moods.
	var night: Dictionary = al.call(&"mood_from", 0.55, Color(0.55, 0.66, 1.0), &"warm", "")
	var sunny: Dictionary = al.call(&"mood_from", 1.35, Color(1.0, 0.89, 0.74), &"warm", "grass")
	var ice: Dictionary = al.call(&"mood_from", 1.2, Color(0.9, 0.95, 1.0), &"ice", "")
	var aut: Dictionary = al.call(&"mood_from", 1.3, Color(1.0, 0.85, 0.7), &"warm", "autumn",
		"res://art/environment/autumn/preset_autumn.tres")
	var hint: Dictionary = al.call(&"mood_from", 1.3, Color(1.0, 0.85, 0.7), &"warm", "autumn")
	var moods_ok := bool(night["night"]) and not bool(sunny["night"]) and bool(ice["snow"]) and bool(aut["autumn"])
	moods_ok = moods_ok and not bool(hint["autumn"]) and bool(hint["autumn_hint"])
	if not moods_ok:
		_fails.append("mood_from wrong: night %s sunny %s ice %s autumn %s" % [night, sunny, ice, aut])
	var rn: Dictionary = al.call(&"mood_ratios", night)
	var rs: Dictionary = al.call(&"mood_ratios", ice)
	var rd: Dictionary = al.call(&"mood_ratios", sunny)
	if float(rn[&"birds"]) != 0.0 or float(rn[&"motes"]) < 1.0 or float(rn[&"mist"]) <= 0.0:
		_fails.append("night ratios wrong: %s" % str(rn))
	if float(rs[&"snow"]) != 1.0 or float(rs[&"wings"]) != 0.0 or float(rd[&"snow"]) != 0.0:
		_fails.append("snow ratios wrong: snow %s day %s" % [str(rs), str(rd)])
	# Flock path mirror: start / end / middle.
	var a := Vector3(0, 12, 0)
	var b := Vector2(10, 0)
	var c0: Vector2 = al.call(&"flock_centre", a, b, 5.0, 4.0, 4.0)
	var c1: Vector2 = al.call(&"flock_centre", a, b, 5.0, 4.0, 20.0)
	var cm: Vector2 = al.call(&"flock_centre", a, b, 5.0, 4.0, 7.0)
	if c0 != Vector2.ZERO or c1 != b or absf(cm.x - 5.0) > 0.01:
		_fails.append("flock_centre wrong: %s %s %s" % [c0, c1, cm])


func _run() -> void:
	var al_script := load(AMBIENT) as GDScript
	fog = main.get(&"fog") as Node
	# The node main.gd's hook made (the level path, HUD and settings broadcast included).
	var al: Node = null
	for n in get_nodes_in_group(&"ambient_life"):
		if main.is_ancestor_of(n):
			al = n
	if al == null:
		_fails.append("the level built no AmbientLife through main.gd's hook (forced High)")
		_finish()
		return
	if al_script.call(&"ensure", main) != al:
		_fails.append("ensure() is not idempotent")
	# Headless default / Low: nothing (a bare level node without one).
	var bare := Node3D.new()
	root.add_child(bare)
	al_script.set(&"allow_headless", false)
	if al_script.call(&"ensure", bare) != null:
		_fails.append("ensure() built a node headless without allow_headless")
	al_script.set(&"allow_headless", true)
	al_script.set(&"quality_override", 0)
	if al_script.call(&"ensure", bare) != null:
		_fails.append("ensure() built a node at Low")
	al_script.set(&"quality_override", 2)
	bare.queue_free()
	var w := 0
	while int(al.get(&"quality")) < 2 and w < 1200:
		await process_frame
		w += 1
	if int(al.get(&"quality")) != 2 or al.get_child_count() == 0:
		_fails.append("AmbientLife never built in the real level (quality %d, %d children)" % [
			int(al.get(&"quality")), al.get_child_count()])
		_finish()
		return
	_notes.append("build %.1f ms, trees %d, meadow %d, bank %d, water %d, road %d, heath %d" % [
		float(al.call(&"build_msec")), int(al.call(&"tree_count")), int(al.call(&"candidate_count", "meadow")),
		int(al.call(&"candidate_count", "bank")), int(al.call(&"candidate_count", "water")),
		int(al.call(&"candidate_count", "road")), int(al.call(&"candidate_count", "heath"))])
	var ids: Array = al.call(&"emitter_ids")
	for id: StringName in [&"wings", &"motes", &"leaves", &"dust", &"mist", &"ripples", &"snow"]:
		if not ids.has(id):
			_fails.append("emitter %s missing at High" % id)
	if int(al.call(&"flock_count")) != 3:
		_fails.append("flocks at High: %d (want 3)" % int(al.call(&"flock_count")))
	if int(al.call(&"candidate_count", "meadow")) < 50 or int(al.call(&"candidate_count", "water")) < 10 \
			or int(al.call(&"tree_count")) < 20:
		_fails.append("too few candidates on Crown Hollow: %s" % _notes[-1])
	for c in (al as Node).get_children():
		if c is CollisionObject3D or c.is_in_group(&"units"):
			_fails.append("AmbientLife has a gameplay node: %s" % c.name)
	var mood: Dictionary = al.call(&"mood")
	if bool(mood.get("night", true)) or bool(mood.get("snow", true)):
		_fails.append("Crown Hollow day mood wrong: %s" % str(mood))

	# --- fog: points only on explored ground.
	var local := int(fog.get(&"local_team"))
	var dark := _pick_unexplored(local)
	var keep := _keep_pos(0)
	if dark == Vector3.INF:
		_fails.append("no never-explored spot found: the fog checks cannot run")
	else:
		al.set(&"focus_override", dark)
		await process_frame
		al.call(&"refresh_points")
		var bad := 0
		var n := 0
		for id: StringName in al.call(&"emitter_ids"):
			for p: Vector3 in al.call(&"emitter_points", id):
				n += 1
				if not bool(fog.call(&"is_explored", local, p)):
					bad += 1
		if bad > 0:
			_fails.append("%d of %d emission points in never-explored fog round %s" % [bad, n, str(dark)])
		_notes.append("dark focus %s: %d points (all explored)" % [str(dark), n])
	al.set(&"focus_override", keep + Vector3(-keep.x, 0.0, -keep.z).normalized() * 10.0)
	await process_frame
	al.call(&"refresh_points")
	var near := 0
	for id: StringName in al.call(&"emitter_ids"):
		near += (al.call(&"emitter_points", id) as PackedVector3Array).size()
	if near < 40:
		_fails.append("only %d emission points near the base" % near)

	# --- birds: hidden enemies never scare a flock, a seen army does.
	if dark != Vector3.INF:
		var enemies: Array[Node] = []
		al.set(&"focus_override", dark)   # else the flock plan would bring a far flock back to the view first
		await process_frame
		for i in 10:
			var u := _spawn_unit("flame_guard", 1, dark + Vector3(float(i % 5) * 1.5, 0.0, float(i / 5) * 1.5))
			if u:
				enemies.append(u)
		# Fresh spawns: still visible until the next fog pass; the VfxFog check must keep the flock calm.
		al.call(&"put_flock", 0, Vector2(dark.x, dark.z))
		var b0 := int((al.call(&"flock_state", 0) as Dictionary)["scatters"])
		al.call(&"tick_logic")
		if int((al.call(&"flock_state", 0) as Dictionary)["scatters"]) != b0:
			_fails.append("a flock scattered over enemy units spawned in fog before the fog pass hid them")
		var fresh := 0
		for u in enemies:
			if (u as Node3D).is_visible_in_tree():
				fresh += 1
		_notes.append("%d / %d fresh enemy spawns still visible_in_tree at the scan (VfxFog kept the flock calm)" % [
			fresh, enemies.size()])
		for i in 20:   # fog passes hide them
			await process_frame
		var hidden := 0
		for u in enemies:
			if not (u as Node3D).is_visible_in_tree():
				hidden += 1
		al.set(&"focus_override", dark)   # else the flock plan would bring a far flock back to the view first
		await process_frame
		al.call(&"put_flock", 0, Vector2(dark.x, dark.z))
		var before := int((al.call(&"flock_state", 0) as Dictionary)["scatters"])
		al.call(&"tick_logic")
		var after := int((al.call(&"flock_state", 0) as Dictionary)["scatters"])
		if hidden != enemies.size():
			_fails.append("only %d / %d enemies in never-explored fog were hidden: the scatter check is not valid" % [
				hidden, enemies.size()])
		elif after != before:
			_fails.append("a flock scattered over %d enemy units hidden by the fog (information leak)" % hidden)
		_notes.append("%d / %d enemies hidden in the fog; flock 0 scatters %d -> %d" % [hidden, enemies.size(),
			before, after])
		for u in enemies:
			u.queue_free()
	var own := keep + Vector3(-keep.x, 0.0, -keep.z).normalized() * 12.0
	for i in 9:
		_spawn_unit("flame_guard", 0, own + Vector3(float(i % 3) * 1.4, 0.0, float(i / 3) * 1.4))
	al.set(&"focus_override", own)
	for i in 3:
		await process_frame
	al.call(&"put_flock", 1, Vector2(own.x, own.z))
	var b2 := int((al.call(&"flock_state", 1) as Dictionary)["scatters"])
	al.call(&"tick_logic")
	var st: Dictionary = al.call(&"flock_state", 1)
	if int(st["scatters"]) <= b2 or not bool(st.get("in_transit", false)):
		_fails.append("a flock over 9 own units in view did not scatter (%s)" % str(st))

	# --- night: birds off, fireflies on.
	var nn := load(NIGHT) as Script
	nn.call(&"apply_to", main, nn.call(&"night"))
	for i in 150:   # > MOOD_TIME
		await process_frame
	mood = al.call(&"mood")
	if not bool(mood.get("night", false)):
		_fails.append("night preset not seen as night: %s" % str(mood))
	var birds: Node3D = (al as Node).get_node_or_null(^"Birds") as Node3D
	if birds and birds.visible:
		_fails.append("birds still shown at night")
	var motes: Dictionary = al.call(&"emitter_info", &"motes")
	if float(motes.get("ratio", 0.0)) < 0.99:
		_fails.append("fireflies not at full ratio at night: %s" % str(motes))

	# --- Low frees everything (the override off, as the settings broadcast would send it).
	al_script.set(&"quality_override", -1)
	al.call(&"set_quality", 0)
	await process_frame
	await process_frame
	if (al as Node).get_child_count() > 0:
		_fails.append("set_quality(0) left %d children" % (al as Node).get_child_count())
	al_script.set(&"quality_override", -1)
	al_script.set(&"allow_headless", false)
	_finish()


func _spawn_unit(type_id: String, team: int, pos: Vector3) -> Node:
	var u: Node = main.call(&"make_unit", type_id)
	if u == null:
		_notes.append("unit type %s missing" % type_id)
		return null
	u.set(&"team", team)
	main.add_child(u)
	u.call(&"set_down", pos)
	u.call(&"command_stop")
	return u


func _pick_unexplored(team: int) -> Vector3:
	var best := Vector3.INF
	for z in range(-48, 49, 6):
		for x in range(-48, 49, 6):
			var p := Vector3(x, 0, z)
			var ok := true
			for d: Vector3 in [Vector3(8, 0, 0), Vector3(-8, 0, 0), Vector3(0, 0, 8), Vector3(0, 0, -8), Vector3.ZERO]:
				if bool(fog.call(&"is_explored", team, p + d)):
					ok = false
					break
			if ok:
				return p
	return best


func _keep_pos(team: int) -> Vector3:
	for b in get_nodes_in_group(&"buildings"):
		var sc := b.get_script() as Script
		if int(b.get(&"team")) == team and sc != null and sc.resource_path.contains("keep"):
			return (b as Node3D).global_position
	return Vector3.ZERO


func _finish() -> void:
	for n in _notes:
		print("  note: %s" % n)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  fail: %s" % f)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _fails.size()])
	_done = true

extends SceneTree
## MT10 (docs/design/map-production.md 4.2, NM.A1), fast part: the bots read the layout. Thornwater (a generated 1v1
## LayoutLevel, sim mode) with a Commander on each side, checked right after their first tick:
## - LayoutLevel.bot_reads_layout() is true; the build rows X1 / X2 / M1 / S3 / S4 go to the layout's slot spots of the
##   team's image (natural_hall, rich_hall, market, tower_natural, tower_rich) - no Crown Hollow constant moved;
## - the scout loop is the layout's: own side of the crown isle (outside the warden ring), the enemy's natural and rich
##   halls, the approach to the enemy keep; every point on the map and on dry land; the two seats' loops mirror;
## - the rally stands 18.4 m from the keep toward the natural hall, the anchor is the wizard start, the crown is the
##   layout's crown spot; the explore points name the enemy's real slots (bot_point of the enemy team).
## Then Crown Hollow rebuilt as a LayoutLevel: bot_reads_layout() is false and the bot keeps Crown Hollow's points
## (rally, scout loop, X2 = skirmish.gd's constants), so test_mt2_layout_level / the replay lab stay identical.
## The full match on Thornwater is tests/test_mt10_layout_bots.gd (slow).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_mt10_bot_slots.gd --fixed-fps 60 --quit-after 9000
## Prints "PASS mt10_bot_slots" or "FAIL mt10_bot_slots: <reasons>".

const TASK_ID := "mt10_bot_slots"
const SCENE := "res://scenes/layout_level.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const SIM := preload("res://scripts/core/sim_mode.gd")
const MAPS: Array[String] = ["res://data/maps/thornwater_layout.tres", "res://data/maps/crown_hollow_level_layout.tres"]
const SLOT_OF := {&"X1": "natural_hall", &"X2": "rich_hall", &"M1": "market", &"S3": "tower_natural", &"S4": "tower_rich"}

var main: Node
var lay: MapLayout
var bots: Array = [null, null]
var map_i := -1
var fails: Array[String] = []
var notes: Array[String] = []
var _wait := 0


func _initialize() -> void:
	if ResourceLoader.exists("res://scripts/core/replay/replay_hooks.gd"):
		load("res://scripts/core/replay/replay_hooks.gd").auto_record = false
	SIM.enabled = true
	_next_map()


func _next_map() -> void:
	if main != null and is_instance_valid(main):
		main.queue_free()
		main = null
	map_i += 1
	if map_i >= MAPS.size():
		_done()
		return
	lay = LayoutLevel.load_layout(MAPS[map_i])
	if lay == null:
		fails.append("no layout %s" % MAPS[map_i])
		_next_map()
		return
	main = (load(SCENE) as PackedScene).instantiate()
	main.set(&"layout", lay)
	bots = [null, null]
	for c: Node in main.get_children():
		if c.get_script() == COMMANDER:
			bots[int(c.get(&"team"))] = c
	for team: int in [0, 1]:
		if bots[team] == null:
			var b: Node = COMMANDER.new()
			b.name = "TestBot%d" % team
			b.set(&"team", team)
			main.add_child(b)
			bots[team] = b
	root.add_child(main)
	current_scene = main
	_wait = 0


func _process(_delta: float) -> bool:
	if main == null:
		return map_i >= MAPS.size()
	_wait += 1
	if _wait > 9000:
		fails.append("%s: the bots never set up" % lay.id)
		_next_map()
		return false
	if not bool(main.get(&"match_started")):
		return false
	for b: Node in bots:
		if b.get(&"_ready_done") != true:
			return false
	if String(lay.id) == "thornwater":
		_check_layout_map()
	else:
		_check_crown_hollow()
	_next_map()
	return main == null and map_i >= MAPS.size()


func _slot(team: int, sub: String) -> Vector3:
	var img := String((main.get(&"seat_of_team") as Dictionary)[team].get("frame_name", "identity"))
	for s: Dictionary in lay.spots_of("slot"):
		if String(s.get("sub", "")) == sub and String(s.get("image", "identity")) == img:
			return s["pos"]
	return Vector3.INF


func _check_layout_map() -> void:
	if not bool(main.call(&"bot_reads_layout")):
		fails.append("thornwater: bot_reads_layout() is false")
	var crown: Vector3 = lay.spots_of("crown")[0]["pos"]
	var river: Node = main.get(&"river")
	var loops := []
	for team: int in [0, 1]:
		var b: Node = bots[team]
		var enemy := 1 - team
		# build rows on the layout's slots
		for row: StringName in SLOT_OF:
			var want := _slot(team, SLOT_OF[row])
			var got: Vector3 = b.call(&"planned_spot", row)
			if want == Vector3.INF:
				fails.append("thornwater team %d: the layout has no %s slot" % [team, SLOT_OF[row]])
			elif got.distance_to(want) > 0.05:
				fails.append("thornwater team %d: row %s at %s, layout slot %s" % [team, row, got, want])
		# crown, rally, anchor
		if (b.get(&"_crown_spot") as Vector3).distance_to(crown) > 0.05:
			fails.append("team %d crown spot %s, layout crown %s" % [team, b.get(&"_crown_spot"), crown])
		var keep: Vector3 = main.call(&"base_center", team)
		var nat: Vector3 = main.call(&"natural_hall_spot", team)
		var rally: Vector3 = b.get(&"_rally")
		var dir := Vector3(nat.x - keep.x, 0, nat.z - keep.z).normalized()
		var rv := Vector3(rally.x - keep.x, 0, rally.z - keep.z)
		if absf(rv.length() - LayoutLevel.RALLY_DIST) > 0.6 or rv.normalized().dot(dir) < 0.98:
			fails.append("team %d rally %s is not %.1f m from the keep toward the natural hall" % [team, rally, LayoutLevel.RALLY_DIST])
		var anchor: Vector3 = b.get(&"_anchor")
		if anchor.distance_to(main.call(&"start_position", team)) > 0.05:
			fails.append("team %d anchor %s is not the wizard start" % [team, anchor])
		# scout loop
		var loop: Array = b.call(&"scout_loop")
		loops.append(loop)
		if loop.size() < 3:
			fails.append("team %d scout loop has %d points" % [team, loop.size()])
			continue
		var p0: Vector3 = loop[0]
		var d0 := Vector2(p0.x - crown.x, p0.z - crown.z).length()
		if d0 < AIMapFill.ISLE_RADIUS or d0 > LayoutLevel.SCOUT_ISLE_GAP + 1.0:
			fails.append("team %d scout start %s is %.1f m from the crown" % [team, p0, d0])
		var e_nat: Vector3 = main.call(&"natural_hall_spot", enemy)
		var e_rich: Vector3 = main.call(&"rich_hall_spot", enemy)
		if not _has_point(loop, e_nat) or not _has_point(loop, e_rich):
			fails.append("team %d scout loop misses the enemy natural / rich hall: %s" % [team, str(loop)])
		for p: Vector3 in loop:
			if not MapInfo.contains(p, 2.0):
				fails.append("team %d scout point %s off the map" % [team, p])
			if river != null and river.has_method(&"is_water") and bool(river.call(&"is_water", p)):
				fails.append("team %d scout point %s in the water" % [team, p])
		# explore points: the enemy's own slots (its seat frame), not a point mirror of ours
		var ex: Array = b.call(&"_explore_points")
		if not _has_point(ex, e_nat):
			fails.append("team %d explore points miss the enemy natural hall" % team)
	# the seats' loops mirror (rot180 map)
	if loops.size() == 2 and (loops[0] as Array).size() == (loops[1] as Array).size():
		for i in (loops[0] as Array).size():
			var a: Vector3 = loops[0][i]
			var c: Vector3 = loops[1][i]
			if Vector3(-a.x, 0, -a.z).distance_to(Vector3(c.x, 0, c.z)) > 0.1:
				fails.append("scout loops do not mirror at point %d: %s vs %s" % [i, a, c])
	notes.append("thornwater: team 0 scout loop %s, rally %s" % [str(loops[0] if loops.size() > 0 else []), bots[0].get(&"_rally")])


func _check_crown_hollow() -> void:
	if bool(main.call(&"bot_reads_layout")):
		fails.append("crown hollow: bot_reads_layout() is true (the bot must keep Crown Hollow's points)")
	for team: int in [0, 1]:
		var b: Node = bots[team]
		var sgn := 1.0 if team == 1 else -1.0
		var want_rally := COMMANDER.RALLY * sgn
		if (b.get(&"_rally") as Vector3).distance_to(want_rally) > 0.05:
			fails.append("crown hollow team %d rally %s, want %s" % [team, b.get(&"_rally"), want_rally])
		var loop: Array = b.call(&"scout_loop")
		var ch: Array[Vector3] = AIMapFill.SCOUT_PATH_RIVER if b.get(&"mapfill_ai") != null and b.get(&"mapfill_ai").call(&"has_river") else COMMANDER.SCOUT_PATH
		if loop.size() != ch.size():
			fails.append("crown hollow team %d scout loop has %d points, want %d" % [team, loop.size(), ch.size()])
		else:
			for i in ch.size():
				if (loop[i] as Vector3).distance_to(ch[i] * sgn) > 0.05:
					fails.append("crown hollow team %d scout point %d %s, want %s" % [team, i, loop[i], ch[i] * sgn])
					break
		var x2: Vector3 = b.call(&"planned_spot", &"X2")
		var want_x2 := Skirmish.RICH_HALL_SPOT * -sgn
		if x2.distance_to(want_x2) > 0.05:
			fails.append("crown hollow team %d X2 %s, want %s" % [team, x2, want_x2])
		if (b.get(&"_crown_spot") as Vector3).length() > 0.01:
			fails.append("crown hollow team %d crown spot %s" % [team, b.get(&"_crown_spot")])


static func _has_point(list: Array, p: Vector3) -> bool:
	for q: Vector3 in list:
		if Vector2(q.x - p.x, q.z - p.z).length() < 0.1:
			return true
	return false


func _done() -> void:
	for n in notes:
		print("  " + n)
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(fails)])
	quit(0 if fails.is_empty() else 1)

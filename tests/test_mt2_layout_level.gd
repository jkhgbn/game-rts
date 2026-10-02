extends SceneTree
## MT2 regression gate (docs/design/map-production.md 2.8 / 4.2): Crown Hollow rebuilt by LayoutLevel from
## data/maps/crown_hollow_level.map (= crown_hollow.map + the forest / road / prop / slot lines) equals the live
## scenes/skirmish.tscn: every Map Lab spot within 0.1 m (R1), every layer-1 collider (trees, rocks, pillars, landmarks,
## buildings) at the same place with the same shape (the "tree hash"), the spot-pair NavigationServer path table
## within 0.05 m (R2), the bot slots identical (bot_point = Commander's own mirror), MapInfo 120 x 120.
## Bots off, sim mode. Prints "PASS mt2_layout_level" or "FAIL mt2_layout_level: <reasons>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_mt2_layout_level.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "mt2_layout_level"
const FMap := preload("res://tools/world_forge/forge_map.gd")
const MapLab := preload("res://tools/map_lab/map_lab.gd")
const SIM := preload("res://scripts/core/sim_mode.gd")
const MAP := "res://data/maps/crown_hollow_level.map"

var frame := 0
var phase := 0
var level: Node
var ref := {}
var fails: Array[String] = []
var notes: Array[String] = []
var wait := 0


func _initialize() -> void:
	SIM.enabled = true
	_load("res://scenes/skirmish.tscn", null)


func _load(scene: String, lay: Resource) -> void:
	level = (load(scene) as PackedScene).instantiate()
	if lay != null:
		level.set(&"layout", lay)
	MapLab._disable_bots(level)
	root.add_child(level)
	wait = 0


var _pending: Resource = null
var _pending_wait := 0


func _process(_delta: float) -> bool:
	frame += 1
	if level == null:
		# the previous level is freed a few frames before the next one loads (its services leave their groups)
		if _pending != null:
			_pending_wait += 1
			if _pending_wait > 5:
				_load("res://scenes/layout_level.tscn", _pending)
				_pending = null
		return false
	MapLab._disable_bots(level)
	if level.get(&"match_started") != true:
		wait += 1
		if wait > 6000:
			fails.append("phase %d: the level never started" % phase)
			return _done()
		return false
	wait += 1
	if wait < 12:
		return false
	var snap := _snapshot(level)
	if phase == 0:
		ref = snap
		level.queue_free()
		level = null
		phase = 1
		var fm := FMap.new()
		if not fm.compile(MAP):
			fails.append("compile %s: %s" % [MAP, " / ".join(fm.spec.error_lines())])
			return _done()
		var t0 := Time.get_ticks_usec()
		_pending = fm.layout
		notes.append("layout compiled (%d spots, %d templates, forest seed %d) in %.0f ms" % [fm.layout.spots.size(),
			fm.layout.templates_used.size(), int(fm.layout.forest.get("seed", -1)), float(Time.get_ticks_usec() - t0) / 1000.0])
		return false
	_compare(ref, snap)
	return _done()


func _snapshot(lv: Node) -> Dictionary:
	var spots: Array = FMap.collect_spots(lv)
	var nav: NavigationRegion3D = lv.get(&"nav_region")
	var cols: Array[String] = []
	for body: Node in nav.find_children("*", "CollisionObject3D", true, false):
		var co := body as CollisionObject3D
		if co.collision_layer & 1 == 0:
			continue
		for cs: Node in co.get_children():
			var c := cs as CollisionShape3D
			if c == null or c.shape == null:
				continue
			var p := c.global_position
			var sh := c.shape
			var desc := sh.get_class()
			if sh is CylinderShape3D:
				desc += " r%.3f h%.2f" % [(sh as CylinderShape3D).radius, (sh as CylinderShape3D).height]
			elif sh is BoxShape3D:
				var s := (sh as BoxShape3D).size
				desc += " %.3f,%.3f,%.3f" % [s.x, s.y, s.z]
			cols.append("%.2f,%.2f,%.2f %s" % [p.x, p.y, p.z, desc])
	cols.sort()
	var table := FMap.path_table(FMap._nav_map_of(lv), spots)
	var bot := {}
	if lv.has_method(&"bot_point"):
		for p: Vector3 in [Vector3(27, 0, -45), Vector3(50, 0, -46), Vector3(16, 0, -6), Vector3(33, 0, 33)]:
			for team: int in [0, 1]:
				bot["%d %s" % [team, p]] = lv.call(&"bot_point", team, p)
	var nodes := {}
	for team: int in [0, 1]:
		for role: String in ["a", "b", "mid", "rich"]:
			var n: Variant = lv.call(&"node_of", team, role)
			nodes["%d%s" % [team, role]] = String((n as Node).name) if n != null else "-"
	return {"spots": spots, "cols": cols, "table": table, "bot": bot, "nodes": nodes,
		"hall": [lv.call(&"natural_hall_spot", 0), lv.call(&"natural_hall_spot", 1), lv.call(&"rich_hall_spot", 1),
			lv.call(&"market_slot", 1), lv.call(&"tower_slot", 0, &"S3"), lv.call(&"tower_slot", 1, &"S4")],
		"size": Vector2(MapInfo.size_x, MapInfo.size_z), "trees": cols.filter(func(s: String) -> bool: return s.contains("Cylinder")).size()}


func _compare(a: Dictionary, b: Dictionary) -> void:
	# R1 spots
	var sa: Array = a["spots"]
	var sb: Array = b["spots"]
	if sa.size() != sb.size():
		fails.append("spot count %d live vs %d layout" % [sa.size(), sb.size()])
	var worst := 0.0
	for s: Dictionary in sa:
		var best := INF
		for t: Dictionary in sb:
			if t["kind"] == s["kind"]:
				best = minf(best, (t["pos"] as Vector3).distance_to(s["pos"]))
		worst = maxf(worst, best)
		if best > 0.1:
			fails.append("spot %s %s: nearest layout twin %.2f m" % [s["kind"], s["id"], best])
	notes.append("R1 spots: %d live, %d layout, worst %.3f m" % [sa.size(), sb.size(), worst])
	# colliders (the tree hash)
	var ca: Array = a["cols"]
	var cb: Array = b["cols"]
	var hash_a := "\n".join(ca).md5_text().substr(0, 12)
	var hash_b := "\n".join(cb).md5_text().substr(0, 12)
	if hash_a != hash_b:
		var only_a: Array[String] = []
		var only_b: Array[String] = []
		for c: String in ca:
			if not cb.has(c):
				only_a.append(c)
		for c: String in cb:
			if not ca.has(c):
				only_b.append(c)
		fails.append("colliders differ: %d live vs %d layout; only live (%d): %s; only layout (%d): %s" % [ca.size(), cb.size(),
			only_a.size(), ", ".join(only_a.slice(0, 6)), only_b.size(), ", ".join(only_b.slice(0, 6))])
	notes.append("colliders: %d live (hash %s), %d layout (hash %s); cylinders %d / %d" % [ca.size(), hash_a, cb.size(), hash_b, a["trees"], b["trees"]])
	# R2 path table
	var ta: Dictionary = a["table"]
	var tb: Dictionary = b["table"]
	var missing := 0
	var wd := 0.0
	var wk := ""
	for k: String in ta:
		if not tb.has(k):
			missing += 1
			continue
		var x: Variant = ta[k]
		var y: Variant = tb[k]
		var d := 0.0 if str(x) == str(y) else (INF if str(x) == "INF" or str(y) == "INF" else absf(float(x) - float(y)))
		if d > wd:
			wd = d
			wk = k
	if missing > 0:
		fails.append("path table: %d pairs missing in the layout level" % missing)
	if wd > 0.05:
		fails.append("path table: worst diff %.3f m (%s)" % [wd, wk])
	notes.append("R2 path table: %d pairs, %d missing, worst %.3f m (%s)" % [ta.size(), missing, wd, wk])
	# bot slots: Commander's own mirror (p for the enemy, -p for the player) on Crown Hollow
	for k: String in b["bot"]:
		var team := int(k.split(" ")[0])
		var p: Vector3 = str_to_var("Vector3" + k.substr(k.find(" ") + 1))
		var want := p if team == 1 else -p
		if (b["bot"][k] as Vector3).distance_to(want) > 0.001:
			fails.append("bot_point %s = %s, want %s" % [k, b["bot"][k], want])
	if a["nodes"] != b["nodes"]:
		fails.append("node roles: live %s vs layout %s" % [a["nodes"], b["nodes"]])
	for i in (a["hall"] as Array).size():
		if (a["hall"][i] as Vector3).distance_to(b["hall"][i]) > 0.01:
			fails.append("slot %d: live %s vs layout %s" % [i, a["hall"][i], b["hall"][i]])
	if b["size"] != Vector2(120, 120):
		fails.append("MapInfo %s, want 120 x 120" % b["size"])


func _done() -> bool:
	for n in notes:
		print("  " + n)
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(fails)])
	quit(0 if fails.is_empty() else 1)
	return true

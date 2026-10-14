extends SceneTree
## WS3.M1 (docs/design/wave-strike.md 15.1 / 15.7): Ashwind Reach's layout has, per seat, a `muster_pad` and a
## `muster_spawn` slot; the spawn box (24 x 18 m: 12 m ahead of the gate, 6 m behind it, centred on the lane) is >= 2 m
## clear of the Bastion and of every tower slot and holds no wizard start; the pad clearing (20 x 26 m around the pad
## centre) holds no block (forest / rock / cliff). Pure layout check (no level).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws3_m1.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "ws3_m1"
const LAYOUT := "res://data/maps/ashwind_reach_layout.tres"
const CELL := 2.0                 ## BuildGrid.CELL
const BOX_AHEAD := 12.0           ## spawn box front edge ahead of the gate
const BOX_BEHIND := 6.0
const BOX_HALF_WIDTH := 12.0      ## across the lane
const PAD_HALF := Vector2(10.0, 13.0)   ## clearing x / z half sizes (18 x 24 m of cells + 1 m rim)
const MIN_CLEAR := 2.0

var _fails: Array[String] = []


func _initialize() -> void:
	var layout: Resource = load(LAYOUT)
	if layout == null:
		print("FAIL %s: no layout at %s" % [TASK_ID, LAYOUT])
		quit(1)
		return
	var tower_half := _footprint_half("res://data/buildings/fire_tower.tres", 1)
	for team in [0, 1]:
		_check_seat(layout, team, tower_half)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  " + f)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _fails.size()])
	quit(0 if _fails.is_empty() else 1)


func _check_seat(layout: Resource, team: int, tower_half: float) -> void:
	var keep: Dictionary = layout.keep_of(team)
	if keep.is_empty():
		_fails.append("seat %d: no keep" % team)
		return
	var keep_pos: Vector3 = keep["pos"]
	var keep_half: float = float((keep.get("props", {}) as Dictionary).get("footprint", 6.0)) * 0.5
	var gate := _nearest(layout, "slot", "gate", keep_pos)
	var spawn := _nearest(layout, "slot", "muster_spawn", keep_pos)
	var pad := _nearest(layout, "slot", "muster_pad", keep_pos)
	if gate.is_empty() or spawn.is_empty() or pad.is_empty():
		_fails.append("seat %d: missing slot (gate %s, muster_spawn %s, muster_pad %s)" % [team, not gate.is_empty(),
			not spawn.is_empty(), not pad.is_empty()])
		return
	var g: Vector3 = gate["pos"]
	var fwd := 1.0 if g.x < 0.0 else -1.0   # the lane runs along x, toward the map centre
	var box := Rect2(Vector2(minf(g.x + fwd * BOX_AHEAD, g.x - fwd * BOX_BEHIND), -BOX_HALF_WIDTH),
		Vector2(BOX_AHEAD + BOX_BEHIND, BOX_HALF_WIDTH * 2.0))
	var sp: Vector3 = spawn["pos"]
	if Vector2(sp.x, sp.z).distance_to(box.get_center()) > 0.01:
		_fails.append("seat %d: muster_spawn %s is not the spawn box centre %s" % [team, sp, box.get_center()])
	# seat 1 = rot180 image of seat 0
	if team == 1:
		for kind_sub in ["muster_spawn", "muster_pad"]:
			var a := _nearest(layout, "slot", kind_sub, layout.keep_of(0)["pos"])
			var b := _nearest(layout, "slot", kind_sub, keep_pos)
			if not a.is_empty() and not b.is_empty() and ((a["pos"] as Vector3) + (b["pos"] as Vector3)).length() > 0.01:
				_fails.append("%s: seat 1 %s is not the rot180 image of seat 0 %s" % [kind_sub, b["pos"], a["pos"]])
	# Bastion
	var kc := _rect_gap(box, Rect2(Vector2(keep_pos.x, keep_pos.z) - Vector2.ONE * keep_half, Vector2.ONE * keep_half * 2.0))
	print("seat %d: spawn box %s, Bastion gap %.1f m" % [team, box, kc])
	if kc < MIN_CLEAR:
		_fails.append("seat %d: spawn box %.1f m from the Bastion (< %.1f)" % [team, kc, MIN_CLEAR])
	# tower slots (every ring, both seats)
	for s: Dictionary in layout.spots_of("slot"):
		if not String(s.get("sub", "")).begins_with("tower_ring"):
			continue
		var p: Vector3 = s["pos"]
		var gap := _rect_gap(box, Rect2(Vector2(p.x, p.z) - Vector2.ONE * tower_half, Vector2.ONE * tower_half * 2.0))
		if gap < MIN_CLEAR:
			_fails.append("seat %d: tower slot %s %s is %.1f m from the spawn box" % [team, s["id"], p, gap])
		elif String(s["sub"]) == "tower_ring1" and absf(p.x - g.x) < 20.0:
			print("seat %d: %s at %s, gap %.1f m" % [team, s["id"], p, gap])
	# wizard starts
	for s: Dictionary in layout.spots_of("start"):
		var p: Vector3 = s["pos"]
		if box.has_point(Vector2(p.x, p.z)):
			_fails.append("seat %d: start %s %s inside the spawn box" % [team, s["id"], p])
	# pad clearing: no block overlaps it
	var pp: Vector3 = pad["pos"]
	var clearing := Rect2(Vector2(pp.x, pp.z) - PAD_HALF, PAD_HALF * 2.0)
	for b: Dictionary in layout.blocks:
		var c: Vector3 = b["center"]
		var h: Vector3 = b["half"]
		var br := Rect2(Vector2(c.x - h.x, c.z - h.z), Vector2(h.x, h.z) * 2.0)
		if br.intersects(clearing):
			_fails.append("seat %d: block %s overlaps the pad clearing %s" % [team, b["id"], clearing])
	if clearing.intersects(box):
		_fails.append("seat %d: pad clearing overlaps the spawn box" % team)
	print("seat %d: pad %s, clearing %s" % [team, pp, clearing])


func _nearest(layout: Resource, kind: String, sub: String, to: Vector3) -> Dictionary:
	var best := {}
	var best_d := INF
	for s: Dictionary in layout.spots_of(kind):
		if String(s.get("sub", "")) != sub:
			continue
		var d: float = (s["pos"] as Vector3).distance_to(to)
		if d < best_d:
			best_d = d
			best = s
	return best


## Distance between two axis-aligned rectangles (0 when they touch or overlap).
func _rect_gap(a: Rect2, b: Rect2) -> float:
	var dx := maxf(0.0, maxf(a.position.x - b.end.x, b.position.x - a.end.x))
	var dy := maxf(0.0, maxf(a.position.y - b.end.y, b.position.y - a.end.y))
	return Vector2(dx, dy).length()


func _footprint_half(path: String, fallback_cells: int) -> float:
	var t: Resource = load(path)
	var cells := fallback_cells
	if t != null and "footprint" in t:
		cells = maxi((t.footprint as Vector2i).x, (t.footprint as Vector2i).y)
	return float(cells) * CELL * 0.5

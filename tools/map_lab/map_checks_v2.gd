extends RefCounted
## Map Lab v2 (docs/design/map-production.md 2.5, tool task MT6): the layout-aware checks R1-R6, run after the v1
## checks when the level carries a MapLayout (World Forge preview `layout`, LayoutLevel `map_layout()`).
## - R1 Targets: every `rules` band (keep_enemy, natural, rich, third, crown, ally: path metres; enemy_ally: ratio of
##   the nearest enemy keep path to the ally keep path) per seat; FAIL > 10 % outside, WARN 5-10 %.
## - R2 Content per seat (new-maps.md 1 = Crown Hollow per side): home nodes, natural, rich, 2 posts, tavern, peddler,
##   2 caches, T1 / T2 / T3 camps, 2-4 lairs, 2 towers + well + shrine, the crown; +-1 = WARN, a missing kind = FAIL.
## - R3 Contest: objectives per seat whose own / nearest-enemy path ratio is contested (0.9-1.1) or raidable (1.1-1.45):
##   1v1 >= 5, team maps >= 3 (WARN under).
## - R4 Clearances (map-fill.md 4.1 / 5.2): points >= 7 m and camps >= 9 m from road centre lines, no spot within 8 m of
##   a crossing centre (ford nests excepted), spots >= 3 m apart.
## - R5 Engine limits: one river half width, <= 2 arms (2 banks), <= 4 ford / steps circles, <= 16 river segments, size
##   <= 192 m, <= 140 spots, navmesh raster <= 4x Crown Hollow's.
## - R6 Mission mode (layouts with marks / triggers / paths): each reachable from the player's keep; `spawn*` marks out
##   of the start's sight (> 20 m).
## Fixable findings carry `fix` data {id, move: Vector3 (canonical frame), why} that `run_world_forge.ps1 fix` applies.
## No class_name on purpose (preloaded tool script).

const BAND_WARN := 0.05
const BAND_FAIL := 0.10
const MAX_MOVE := 5.0
const POINT_ROAD := 7.0
const CAMP_ROAD := 9.0
const CROSSING_CLEAR := 8.0
const CONTEST := [0.9, 1.1]
const RAID_MAX := 1.45
const CONTEST_MIN_1V1 := 5
const CONTEST_MIN_TEAM := 3
const LIMIT_SIZE := 192.0
const LIMIT_SPOTS := 140
const LIMIT_CIRCLES := 4
const LIMIT_SEGMENTS := 16
const CH_CELLS := 240 * 240        ## Crown Hollow's navmesh raster (120 m / 0.5 m)^2
## R2 expected per seat: kind key -> [min, max].
const CONTENT := {"home node": [2, 2], "natural": [1, 1], "rich": [1, 1], "post": [2, 2], "tavern": [1, 1], "peddler": [1, 1],
	"cache": [2, 2], "camp T1": [1, 2], "camp T2": [1, 3], "camp T3": [1, 1], "lair": [2, 4], "watchtower": [2, 2],
	"well": [1, 1], "shrine": [1, 1], "crown": [1, 1]}

var c                      ## the v1 Checks (untyped: its fields are read dynamically) (spots, path_len, seat_keep, nav_map, report, profile, level)
var lay: MapLayout
var fixes: Array = []      ## [{id, move, why}] (canonical frame)
var seat_frames := {}      ## team -> Transform3D
var team_seats: Array = [] ## seats of the profile that have a keep


func _init(checks: RefCounted, layout: MapLayout) -> void:
	c = checks
	lay = layout


func run() -> void:
	for s: Dictionary in lay.seats:
		seat_frames[int(s["team"])] = s.get("frame", Transform3D.IDENTITY)
	for s: Dictionary in c.call(&"_seat_list"):
		if not lay.closed_seats.has(int(s["team"])):
			team_seats.append(s)
	if String(lay.rules.get("archetype", "")) == "template":
		# a template checked alone (`run_world_forge.ps1 template <name>`): clearances and engine limits only
		_r4_clearances()
		_r5_limits()
		return
	_r1_targets()
	if lay.rules.is_empty():
		# no `rules` line: not declared a playable skirmish map, so no content / contest bar (R1 says so too)
		c.report.add_info("R2", "dist", "Content per seat", "no `rules` line: content per seat not judged")
		c.report.add_info("R3", "dist", "Contest per seat", "no `rules` line: contest not judged")
	else:
		_r2_content()
		_r3_contest()
	_r4_clearances()
	_r5_limits()
	_r6_mission()
	c.report.notes.append("Map Lab v2 (map-production.md 2.5): layout %s, %d seats, rules %s, %d fixable findings." % [
		lay.id, team_seats.size(), "tempo " + String(lay.rules.get("tempo", "-")) if not lay.rules.is_empty() else "none", fixes.size()])


# ---------------------------------------------------------------- helpers

func _frame_name(team: int) -> String:
	for s: Dictionary in lay.seats:
		if int(s["team"]) == team:
			return String(s.get("frame_name", "identity"))
	return "identity"


func _spot_idx(id: String) -> int:
	return int(c.call(&"_spot_index", id))


func _path(i: int, j: int) -> float:
	return float(c.call(&"path_len", i, j))


## The layout spot a seat owns for each canonical spot (image identity / solo): {canonical id: layout spot}.
func _seat_spots(team: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var xf: Transform3D = seat_frames.get(team, Transform3D.IDENTITY)
	for s: Dictionary in lay.spots:
		if String(s.get("image", "identity")) != "identity":
			continue
		var want: Vector3 = xf * (s["pos"] as Vector3)
		for t: Dictionary in lay.spots:
			if t["kind"] == s["kind"] and (t["pos"] as Vector3).distance_to(want) < 0.1:
				out.append(t)
				break
	return out


static func role_of(n: Dictionary) -> String:
	var props: Dictionary = n.get("props", {})
	if props.has("role"):
		return String(props["role"])
	var base := String(n.get("twin_of", n["id"]))
	for role: String in ["rich", "mid", "third", "a", "b"]:
		if base.ends_with("_" + role):
			return role
	return ""


static func camp_tier(s: Dictionary) -> int:
	var props: Dictionary = s.get("props", {})
	if props.has("tier"):
		return int(props["tier"])
	var key := (String(s.get("sub", "")) + " " + String(s.get("twin_of", s["id"]))).to_lower()
	if key.contains("stag"):
		return 3
	if key.contains("nest") or key.contains("mirefang") or key.contains("hollow") or key.contains("gloomcap"):
		return 2
	return 1


func _keep_idx(team: int) -> int:
	return int((c.get(&"seat_keep") as Dictionary).get(team, -1))


func _nearest_enemy(team: int, side: int) -> float:
	var ki := _keep_idx(team)
	var best := INF
	for o: Dictionary in team_seats:
		if int(o["side"]) != side:
			best = minf(best, _path(ki, _keep_idx(int(o["team"]))))
	return best


func _ally(team: int, side: int) -> float:
	var ki := _keep_idx(team)
	var best := INF
	for o: Dictionary in team_seats:
		if int(o["side"]) == side and int(o["team"]) != team:
			best = minf(best, _path(ki, _keep_idx(int(o["team"]))))
	return best


## How far `v` is outside band (a, b), as a share of the nearer edge (0 inside).
static func band_miss(v: float, band: Vector2) -> float:
	if v < band.x:
		return (band.x - v) / maxf(band.x, 0.01)
	if v > band.y:
		return (v - band.y) / maxf(band.y, 0.01)
	return 0.0


# ---------------------------------------------------------------- R1 targets

func _r1_targets() -> void:
	var targets: Dictionary = lay.rules.get("targets", {})
	if targets.is_empty():
		c.report.add_info("R1", "dist", "Targets (rules)", "no `rules` targets in the .map (add `rules tempo=... keep_enemy=a..b natural=a..b`)")
		return
	var issues: Array = []
	var rows := "| Seat | Target | Band | Measured | Miss |\n|---|---|---|---|---|\n"
	var total := 0
	for s: Dictionary in team_seats:
		var team := int(s["team"])
		var side := int(s["side"])
		var ki := _keep_idx(team)
		if ki < 0:
			continue
		var mine := _seat_spots(team)
		for key: String in targets:
			var band: Vector2 = targets[key]
			var v := INF
			var spot_id := ""
			match key:
				"keep_enemy":
					v = _nearest_enemy(team, side)
				"ally":
					v = _ally(team, side)
				"enemy_ally":
					var al := _ally(team, side)
					v = _nearest_enemy(team, side) / al if al > 0.0 and not is_inf(al) else INF
				"crown":
					var ci := _spot_idx("crown")
					v = _path(ki, ci) if ci >= 0 else INF
				"natural", "rich", "third":
					var role := "mid" if key == "natural" else key
					for t in mine:
						if t["kind"] == "node" and role_of(t) == role:
							var si := _spot_idx(String(t["id"]))
							if si >= 0:
								v = _path(ki, si)
								spot_id = String(t["id"])
							break
				_:
					continue
			total += 1
			if is_inf(v):
				issues.append({"sev": "FAIL", "where": "%s %s" % [s["name"], key], "what": "%s not measurable (no spot / no path)" % key,
					"fix": "add the %s spot or open a path to it" % key})
				rows += "| %s | %s | %.0f-%.0f | - | - |\n" % [s["name"], key, band.x, band.y]
				continue
			var miss := band_miss(v, band)
			rows += "| %s | %s | %.2f-%.2f | %.2f | %s |\n" % [s["name"], key, band.x, band.y, v, "-" if miss <= 0.0 else "%.1f %%" % (100.0 * miss)]
			if miss <= BAND_WARN:
				continue
			var sev := "FAIL" if miss > BAND_FAIL else "WARN"
			var fixable := spot_id != "" and _frame_name(team) == "identity"
			var item := {"sev": sev, "where": "%s %s" % [s["name"], key], "what": "%s %.1f outside %.0f-%.0f (%.0f %%)" % [key, v, band.x, band.y, 100.0 * miss],
				"fix": "move %s toward / away from the keep (auto-fix)" % spot_id if spot_id != "" else "a designer moves the keeps or the river (R1 %s is not auto-fixed)" % key}
			issues.append(item)
			if fixable:
				_fix_toward_keep(spot_id, ki, v, band, key)
	c.report.add_check("R1", "dist", "Targets met (rules bands, per seat)", "every `rules` band per seat: FAIL > %.0f %% outside, WARN %.0f-%.0f %%" % [
		100.0 * BAND_FAIL, 100.0 * BAND_WARN, 100.0 * BAND_FAIL], maxi(1, total), issues, "", "", 2.0)
	c.report.add_table("R1 targets per seat (navmesh path m; enemy_ally = ratio)", rows)


func _fix_toward_keep(spot_id: String, ki: int, v: float, band: Vector2, key: String) -> void:
	var s := lay.spot(spot_id)
	if s.is_empty():
		return
	var kp: Vector3 = c.spots[ki]["pos"]
	var p: Vector3 = s["pos"]
	var want := band.y * 0.97 if v > band.y else band.x * 1.03
	var delta := v - want   # > 0: too far, move toward the keep
	var dir := (kp - p)
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var step := clampf(delta * 0.9, -MAX_MOVE, MAX_MOVE)
	fixes.append({"id": String(s.get("twin_of", spot_id)) if String(s.get("image", "identity")) == "identity" else spot_id,
		"move": dir.normalized() * step, "why": "R1 %s %.1f -> %.0f-%.0f" % [key, v, band.x, band.y]})


# ---------------------------------------------------------------- R2 content

func _r2_content() -> void:
	if team_seats.is_empty():
		c.report.add_info("R2", "dist", "Content per seat", "no seats")
		return
	var issues: Array = []
	var head := "| Seat | " + " | ".join(CONTENT.keys()) + " |\n|---|" + "---|".repeat(CONTENT.size()) + "\n"
	var rows := head
	for s: Dictionary in team_seats:
		var team := int(s["team"])
		var counts := {}
		for k: String in CONTENT:
			counts[k] = 0
		for t in _seat_spots(team):
			var key := ""
			match String(t["kind"]):
				"node":
					var r := role_of(t)
					key = "home node" if r in ["a", "b"] else ("natural" if r == "mid" else ("rich" if r == "rich" else ""))
				"camp":
					key = "camp T%d" % camp_tier(t)
				"point":
					key = MapForest.point_kind(t)
				_:
					key = String(t["kind"])
			if counts.has(key):
				counts[key] = int(counts[key]) + 1
		var cells: Array[String] = []
		for k: String in CONTENT:
			var n := int(counts[k])
			var lo := int(CONTENT[k][0])
			var hi := int(CONTENT[k][1])
			cells.append(str(n))
			if n == 0 and lo > 0:
				issues.append({"sev": "FAIL", "where": "%s %s" % [s["name"], k], "what": "no %s for this seat" % k,
					"fix": "add one (template: %s)" % _template_for(k)})
			elif n < lo or n > hi:
				issues.append({"sev": "WARN", "where": "%s %s" % [s["name"], k], "what": "%d %s, want %d-%d" % [n, k, lo, hi],
					"fix": "Crown Hollow per side: new-maps.md 1"})
		rows += "| %s | %s |\n" % [s["name"], " | ".join(cells)]
	c.report.add_check("R2", "dist", "Content per seat (Crown Hollow per side)", "new-maps.md 1 per seat: +-1 = WARN, a missing kind = FAIL",
		team_seats.size() * CONTENT.size(), issues, "", "", 1.5)
	c.report.add_table("R2 content per seat", rows)


static func _template_for(k: String) -> String:
	return {"home node": "base_district", "natural": "natural", "rich": "rich_pocket", "post": "trade_post", "tavern": "tavern_peddler",
		"peddler": "tavern_peddler", "cache": "cache_pair", "camp T1": "camp_trio", "camp T2": "camp_trio / nest_in_ford",
		"camp T3": "camp_trio / sealed_vein", "lair": "lair_pair", "watchtower": "tower_over_crossing", "well": "well",
		"shrine": "shrine", "crown": "crown_isle"}.get(k, "-")


# ---------------------------------------------------------------- R3 contest

func _r3_contest() -> void:
	if team_seats.size() < 2:
		c.report.add_info("R3", "dist", "Contest per seat", "fewer than 2 seats")
		return
	var team_map := false
	var sides := {}
	for s: Dictionary in team_seats:
		sides[int(s["side"])] = int(sides.get(int(s["side"]), 0)) + 1
	for k: int in sides:
		team_map = team_map or int(sides[k]) >= 2
	var need := CONTEST_MIN_TEAM if team_map else CONTEST_MIN_1V1
	var issues: Array = []
	var rows := "| Seat | Contested (0.9-1.1) | Raidable (1.1-%.2f) | Own (< 0.9) | Objectives |\n|---|---|---|---|---|\n" % RAID_MAX
	for s: Dictionary in team_seats:
		var team := int(s["team"])
		var ki := _keep_idx(team)
		var nc := 0
		var nr := 0
		var no := 0
		var n := 0
		for j in c.spots.size():
			var kind := String(c.spots[j]["kind"])
			if not kind in ["point", "camp", "crown", "expansion", "post", "tavern"]:
				continue
			var own := _path(ki, j)
			var enemy := INF
			for o: Dictionary in team_seats:
				if int(o["side"]) != int(s["side"]):
					enemy = minf(enemy, _path(_keep_idx(int(o["team"])), j))
			if is_inf(own) or is_inf(enemy) or enemy <= 0.0:
				continue
			n += 1
			var r := own / enemy
			if r >= CONTEST[0] and r <= CONTEST[1]:
				nc += 1
			elif r > CONTEST[1] and r <= RAID_MAX:
				nr += 1
			elif r < CONTEST[0]:
				no += 1
		rows += "| %s | %d | %d | %d | %d |\n" % [s["name"], nc, nr, no, n]
		if nc + nr < need:
			issues.append({"sev": "WARN", "where": s["name"], "what": "%d contested + raidable objectives, want >= %d" % [nc + nr, need],
				"fix": "move a point or camp toward the middle (map-2v2-audit.md contest ratio)"})
	c.report.add_check("R3", "dist", "Contested + raidable objectives per seat", "own / nearest enemy path 0.9-1.1 (contested) or 1.1-%.2f (raidable): >= %d per seat" % [
		RAID_MAX, need], team_seats.size(), issues, "", "", 1.0)
	c.report.add_table("R3 contest per seat", rows)


# ---------------------------------------------------------------- R4 clearances

func _r4_clearances() -> void:
	var issues: Array = []
	var total := 0
	var road_segs: Array = []
	for r: Dictionary in lay.roads:
		var poly: PackedVector3Array = r["poly"]
		for i in poly.size() - 1:
			road_segs.append([Vector2(poly[i].x, poly[i].z), Vector2(poly[i + 1].x, poly[i + 1].z)])
	for s: Dictionary in lay.spots:
		var kind := String(s["kind"])
		if kind in ["slot", "start"]:
			continue
		total += 1
		var p: Vector3 = s["pos"]
		var q := Vector2(p.x, p.z)
		var need_road := POINT_ROAD if kind == "point" else (CAMP_ROAD if kind == "camp" else 0.0)
		if need_road > 0.0:
			for seg: Array in road_segs:
				var cp := Geometry2D.get_closest_point_to_segment(q, seg[0], seg[1])
				var d := q.distance_to(cp)
				if d < need_road:
					issues.append({"sev": "WARN", "where": s["id"], "what": "%s %.1f m from a road centre line (want >= %.0f)" % [kind, d, need_road],
						"fix": "push it off the road (auto-fix)"})
					_fix_push(s, Vector3(q.x - cp.x, 0, q.y - cp.y), need_road - d + 0.5, "R4 %s %.1f m from road" % [kind, d])
					break
		var nest := kind == "camp" and camp_tier(s) == 2 and (String(s.get("sub", "")) + String(s.get("twin_of", ""))).to_lower().contains("nest") \
				or String(s.get("sub", "")) == "mirefang"
		if not nest:
			for cr: Dictionary in lay.crossings:
				var cc: Vector3 = cr["center"]
				var d2 := Vector2(cc.x - p.x, cc.z - p.z).length()
				if d2 < CROSSING_CLEAR:
					issues.append({"sev": "WARN", "where": s["id"], "what": "%s %.1f m from crossing %s (want >= %.0f)" % [kind, d2, cr["id"], CROSSING_CLEAR],
						"fix": "move it off the crossing approach (auto-fix)"})
					_fix_push(s, p - cc, CROSSING_CLEAR - d2 + 0.5, "R4 %.1f m from crossing %s" % [d2, cr["id"]])
					break
	c.report.add_check("R4", "choke", "Clearances (roads, crossings)", "points >= %.0f m and camps >= %.0f m from road centre lines; no spot within %.0f m of a crossing (ford nests excepted)" % [
		POINT_ROAD, CAMP_ROAD, CROSSING_CLEAR], maxi(1, total), issues, "", "", 1.0)


func _fix_push(s: Dictionary, away: Vector3, dist: float, why: String) -> void:
	if String(s.get("image", "identity")) != "identity":
		return   # the canonical twin carries the fix
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3(1, 0, 0)
	fixes.append({"id": String(s.get("twin_of", s["id"])), "move": away.normalized() * minf(dist, MAX_MOVE), "why": why})


# ---------------------------------------------------------------- R5 engine limits

func _r5_limits() -> void:
	var issues: Array = []
	var hws := {}
	var segs := 0
	for arm: Dictionary in lay.river:
		hws[snappedf(float(arm.get("half_width", 2.5)), 0.01)] = true
		segs += maxi(0, (arm["poly"] as PackedVector3Array).size() - 1)
	var circles := 0
	for cr: Dictionary in lay.crossings:
		if String(cr["kind"]) in ["ford", "steps"]:
			circles += 1
	var nspots := 0   # Map Lab spots: slots and starts are not live objects
	for s: Dictionary in lay.spots:
		if not String(s["kind"]) in ["slot", "start"]:
			nspots += 1
	var checks := [
		["one river half width", hws.size() <= 1, "%d half widths" % hws.size()],
		["<= 2 river arms (2 banks)", lay.river.size() <= 2, "%d arms" % lay.river.size()],
		["<= %d ford / steps circles" % LIMIT_CIRCLES, circles <= LIMIT_CIRCLES, "%d circles" % circles],
		["<= %d river segments" % LIMIT_SEGMENTS, segs <= LIMIT_SEGMENTS, "%d segments" % segs],
		["size <= %.0f m" % LIMIT_SIZE, maxf(lay.size_x, lay.size_z) <= LIMIT_SIZE, "%.0f x %.0f m" % [lay.size_x, lay.size_z]],
		["<= %d spots" % LIMIT_SPOTS, nspots <= LIMIT_SPOTS, "%d spots" % nspots],
		["navmesh raster <= 4x Crown Hollow", lay.size_x * lay.size_z * 4.0 <= 4.0 * CH_CELLS, "%.1fx" % (lay.size_x * lay.size_z * 4.0 / CH_CELLS)],
	]
	var vals: Array[String] = []
	for row: Array in checks:
		vals.append("%s %s" % [row[2], "ok" if row[1] else "OVER"])
		if not row[1]:
			issues.append({"sev": "FAIL", "where": "engine", "what": "%s: %s" % [row[0], row[2]], "fix": "the map breaks an engine limit (map-production.md 2.5 R5): a designer changes it"})
	c.report.add_check("R5", "nav", "Engine limits", "one half width, <= 2 arms, <= 4 circles, <= 16 segments, <= 192 m, <= 140 spots, raster <= 4x CH",
		checks.size(), issues, "", "", 1.5, ", ".join(vals))


# ---------------------------------------------------------------- R6 mission mode

func _r6_mission() -> void:
	if lay.marks.is_empty() and lay.triggers.is_empty() and lay.paths.is_empty():
		c.report.add_info("R6", "nav", "Mission marks / triggers / paths", "no mission overlay data")
		return
	var issues: Array = []
	var nav_map: RID = c.get(&"nav_map")
	var ki := _keep_idx(int(team_seats[0]["team"])) if not team_seats.is_empty() else -1
	var from: Vector3 = c.spots[ki]["snap"] if ki >= 0 else Vector3.ZERO
	var pts := {}
	for id: String in lay.marks:
		pts["mark " + id] = lay.marks[id]
	for id: String in lay.triggers:
		var a: Dictionary = lay.triggers[id]
		pts["trigger " + id] = a["center"] if a.has("center") else ((a["min"] as Vector3) + (a["max"] as Vector3)) * 0.5
	for id: String in lay.paths:
		var poly: PackedVector3Array = lay.paths[id]
		for k in poly.size():
			pts["path %s[%d]" % [id, k]] = poly[k]
	for key: String in pts:
		var p: Vector3 = pts[key]
		var to := NavigationServer3D.map_get_closest_point(nav_map, p + Vector3(0, 0.5, 0))
		var path := NavigationServer3D.map_get_path(nav_map, from, to, true)
		if path.is_empty() or path[path.size() - 1].distance_to(to) > 1.0 or Vector2(to.x - p.x, to.z - p.z).length() > 3.0:
			issues.append({"sev": "FAIL", "where": key, "what": "not reachable from the player's keep (%s)" % str(p), "fix": "move it onto walkable ground"})
		if key.begins_with("mark spawn") and ki >= 0 and Vector2(p.x - from.x, p.z - from.z).length() < 20.0:
			issues.append({"sev": "WARN", "where": key, "what": "spawn mark within 20 m of the player's start", "fix": "spawns stay out of the start's sight"})
	c.report.add_check("R6", "nav", "Mission marks / triggers / paths reachable", "every mark, trigger centre and path point reachable from the player's keep; spawns > 20 m from it",
		maxi(1, pts.size()), issues, "", "", 1.5)

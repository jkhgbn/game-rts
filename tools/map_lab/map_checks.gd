extends RefCounted
## Map Lab (docs/plan/map-lab.md): every measurement on a loaded, baked map. Reads the spots from the live scene
## (groups + the map script's constants), asks the NavigationServer for the shortest path between every pair of spots,
## compares each pair with its mirror twins, checks the map script's spot constants and the navmesh itself for
## symmetry, measures crossings and corridor widths on the rasterised navmesh (map_grid.gd) and paints the heat map.
## It never edits the map: findings name the constant / spot and the fix for the owner.
## No class_name on purpose (preloaded tool script).

const Grid := preload("res://tools/map_lab/map_grid.gd")
const Report := preload("res://tools/map_lab/map_report.gd")

## Rules (all numbers in one place).
const ASYM_WARN := 0.02          ## path pair vs its mirror twin: > 2 % longer = WARN...
const ASYM_FAIL := 0.05          ## ...> 5 % = FAIL...
const ASYM_MIN_M := 0.75         ## ...but only when the difference is also > this many metres (short-path noise).
const ASYM_FAIL_MIN_M := 2.0
const TWIN_TOL := 1.0            ## a spot's mirror twin lies within this of the mirrored position
const CONST_TOL := 0.05          ## spot constants mirror exactly (m)
const REACH_TOL := 1.0           ## a path that ends farther than this from its target did not reach it
const SNAP_WARN := 6.0           ## a spot farther than this from the navmesh (inside a big building / cliff)
const NAV_MIRROR_WARN := 0.003   ## share of walkable cells without a mirror image
const NAV_MIRROR_FAIL := 0.02
const ISLAND_WARN_M2 := 2.0      ## ground-level navmesh islands at least this big (m²)
const GROUND_Y := 0.3            ## |mean height - main navmesh height| below this = ground level (raised islands sit on rocks / roofs)
const CROSSING_TWIN_TOL := 0.5   ## mirrored crossings' navmesh widths differ by at most this (m)
const CROSSING_NARROW := 2.0     ## navmesh width below this = a narrow crossing (WARN)
const CHOKE_WIDTH := 3.0         ## route samples narrower than this (navmesh m) are listed as chokes
const ROUTE_TWIN_TOL := 1.0      ## a route's narrowest point vs its mirror twin's (m)
const HOME_NODE_RADIUS := 16.0   ## crystal nodes this close to a keep are home nodes, the others expansions
const ALLY_FAR_RATIO := 1.25     ## A1: the ally keep farther than this x the nearest enemy keep = allies can't help (WARN)
const TARGET_TOL := 0.10         ## A1: a profile `targets` distance (map spec) missed by more than 10 % = WARN
const TRAVEL_SPREAD_S := 3.0     ## T1: seats' travel times to the same destination differ by more than this (s)...
const TRAVEL_SPREAD_REL := 0.03  ## ...and by more than 3 % = WARN
const FORD_SLOW := -0.35         ## RiverSystem.FORD_SLOW (move_speed_pct inside a ford / steps circle)
const SAMPLE_M := 0.5            ## path sampling step for ford / river tests (m)
## T1 unit classes: [label, unit id in data/units, fallback speed m/s]. Speeds are read from the UnitType.
const TRAVEL_UNITS: Array = [["worker", "cinder_hand", 4.6], ["soldier", "flame_guard", 5.0],
	["cavalry", "blaze_rider", 7.5], ["caravan", "caravan", 4.0]]
## Spots that are buildings: a navmesh pocket inside their footprint is by design.
const BUILDING_KINDS: Array[String] = ["keep", "tavern", "post", "guild", "peddler"]
const DIST_KINDS: Array[String] =["expansion", "point", "camp", "lair", "tavern", "post", "peddler", "cache", "crown"]
const KIND_COLORS := {"keep": Color(1, 1, 1), "home_node": Color(0.3, 0.9, 1.0), "expansion": Color(0.0, 0.8, 0.9),
	"point": Color(0.6, 0.2, 0.9), "camp": Color(0.9, 0.5, 0.1), "lair": Color(0.55, 0.25, 0.1),
	"tavern": Color(0.1, 0.7, 0.2), "post": Color(0.9, 0.8, 0.1), "guild": Color(0.5, 0.5, 0.2),
	"peddler": Color(0.2, 0.4, 0.2), "cache": Color(0.8, 0.8, 0.5), "crown": Color(1.0, 0.1, 0.6)}
## Keys that are positions, names or directions (compared separately or not at all) when two mirrored constant
## entries are compared.
const SKIP_PROPS: Array[String] = ["id", "name", "pos", "center", "door", "patrol", "spots", "dir", "sign"]

var report: Report
var profile: Dictionary
var level: Node
var grid: Grid
var nav_map: RID
var heat_on := true
var out_dir := ""
var spots: Array[Dictionary] = []   ## {id, kind, pos, snap, snap_d, reach, team}
var lens := PackedFloat32Array()    ## n x n NavigationServer path lengths (INF = no path)
var geo_lens := PackedFloat32Array() ## n x n octile grid shortest paths (mirror-exact)
var seat_keep := {}                 ## team -> spot index of its keep
var t_paths := 0.0


func _init(p_report: Report, p_profile: Dictionary, p_level: Node) -> void:
	report = p_report
	profile = p_profile
	level = p_level


func symmetries() -> Array:
	return profile.get("symmetries", [])


## Runs everything (the level's navmesh must be baked).
func run() -> void:
	var t0 := Time.get_ticks_usec()
	var regions := level.find_children("*", "NavigationRegion3D", true, false)
	if regions.is_empty():
		report.add_check("N1", "nav", "Navmesh baked", "the level has a NavigationRegion3D with polygons", 1,
			[{"sev": "FAIL", "where": "level", "what": "no NavigationRegion3D", "fix": "bake the navmesh before the lab runs"}])
		return
	nav_map = (regions[0] as NavigationRegion3D).get_navigation_map()
	grid = Grid.new()
	grid.build(regions, float(profile.get("half_size", 60.0)))
	var t_grid := Time.get_ticks_usec()
	_check_navmesh()
	_collect_spots()
	_snap_spots()
	_check_reach()
	_check_islands()
	_check_spot_mirror()
	_check_constants()
	_check_nav_mirror()
	var t_mid := Time.get_ticks_usec()
	_all_paths()
	_geo_paths()
	_check_pair_fairness(geo_lens, true)
	_check_pair_fairness(lens, false)
	_distance_tables()
	_check_allies()
	_travel_times()
	_check_crossings()
	_check_routes()
	if heat_on:
		_write_heat()
	report.notes.append("Navmesh raster %.2f s (%d polygons, %d cells of %.2f m), spot / mirror checks %.2f s, %d paths %.2f s." % [
		float(t_grid - t0) / 1e6, grid.polygon_count, grid.n * grid.n, Grid.CELL, float(t_mid - t_grid) / 1e6,
		spots.size() * (spots.size() - 1) / 2, t_paths])


# ---------------------------------------------------------------- spots

func _collect_spots() -> void:
	var tree := level.get_tree()
	var keeps: Array[Vector3] = []
	for b: Node in tree.get_nodes_in_group(&"buildings"):
		if b is Keep and level.is_ancestor_of(b):
			var k := b as Keep
			_add_spot("keep_t%d" % k.team, "keep", k.global_position, k.team)
			keeps.append(k.global_position)
	for nd: Node in tree.get_nodes_in_group(&"crystal_nodes"):
		var p := (nd as Node3D).global_position
		var home := false
		for kp in keeps:
			if Vector2(kp.x - p.x, kp.z - p.z).length() < HOME_NODE_RADIUS:
				home = true
		_add_spot(String(nd.name), "home_node" if home else "expansion", p)
	var groups := {&"capture_points": "point", &"neutral_camps": "camp", &"taverns": "tavern", &"trade_posts": "post",
		&"guilds": "guild", &"peddlers": "peddler", &"lost_caches": "cache"}
	for g: StringName in groups:
		for nd: Node in tree.get_nodes_in_group(g):
			if nd is Node3D and level.is_ancestor_of(nd):
				_add_spot(_id_of(nd), groups[g], (nd as Node3D).global_position)
	# Lairs: the map script's LAIR_SPOTS (EpicBeasts keeps no lair nodes before a beast spawns).
	var consts := _script_constants()
	if consts.has("LAIR_SPOTS"):
		for d: Dictionary in consts["LAIR_SPOTS"]:
			_add_spot(String(d.get("id", "lair")), "lair", d.get("center", d.get("pos", Vector3.ZERO)))
	var river := _river()
	if river:
		for c: Dictionary in river.call(&"crossings"):
			_add_spot(String(c.get("id", "crossing")), "crossing_" + String(c.get("kind", "")), c["center"])
	var crown: Variant = level.get(&"crown")
	if crown is Node3D and is_instance_valid(crown):
		_add_spot("crown", "crown", (crown as Node3D).global_position)
	elif level.get(&"ARTIFACT_POS") is Vector3:
		_add_spot("crown", "crown", level.get(&"ARTIFACT_POS"))
	report.counts_scanned["spots"] = spots.size()


func _add_spot(id: String, kind: String, pos: Vector3, team: int = -1) -> void:
	var uid := id
	var k := 2
	while _spot_index(uid) >= 0:
		uid = "%s_%d" % [id, k]
		k += 1
	spots.append({"id": uid, "kind": kind, "pos": Vector3(pos.x, 0.0, pos.z), "team": team})
	if kind == "keep":
		seat_keep[team] = spots.size() - 1


func _spot_index(id: String) -> int:
	for i in spots.size():
		if spots[i]["id"] == id:
			return i
	return -1


static func _id_of(nd: Node) -> String:
	for prop: StringName in [&"camp_id", &"point_id", &"post_id", &"id"]:
		var v: Variant = nd.get(prop)
		if (v is StringName or v is String) and String(v) != "":
			return String(v)
	var nm := String(nd.name)
	return nm if not nm.begins_with("@") else nd.get_class().to_lower()


func _river() -> Node:
	for r: Node in level.get_tree().get_nodes_in_group(&"river"):
		if level.is_ancestor_of(r) and r.has_method(&"crossings"):
			return r
	return null


func _snap_spots() -> void:
	# Onto the main (ground) navmesh: the plain closest point of a keep / post centre is often its roof island.
	for s: Dictionary in spots:
		var p: Vector3 = s["pos"]
		var c := grid.nearest_main(p.x, p.z, 25.0)
		var q := NavigationServer3D.map_get_closest_point(nav_map, c if c != Vector3.INF else p + Vector3(0, 0.5, 0))
		s["snap"] = q
		s["snap_d"] = Vector2(q.x - p.x, q.z - p.z).length()
	# Twins take the mirror image of their orbit's first spot's point (re-snapped within 2 m), so a building whose
	# footprint is square does not get its path start on a different face than its twin.
	var done := {}
	for i in spots.size():
		if done.has(i):
			continue
		done[i] = true
		for sym: Dictionary in symmetries():
			var t := twin_of(i, sym["xf"])
			if t < 0 or done.has(t):
				continue
			done[t] = true
			var want: Vector3 = (sym["xf"] as Transform3D) * (spots[i]["snap"] as Vector3)
			var c := grid.nearest_main(want.x, want.z, 2.0)
			if c == Vector3.INF:
				continue   # M4 reports it
			var q := NavigationServer3D.map_get_closest_point(nav_map, c)
			var p: Vector3 = spots[t]["pos"]
			spots[t]["snap"] = q
			spots[t]["snap_d"] = Vector2(q.x - p.x, q.z - p.z).length()
	# Own twins (the crown): its point and the point's mirror images; paths use the nearest ("alts").
	for i in spots.size():
		var alts: Array[Vector3] = [spots[i]["snap"]]
		for sym: Dictionary in symmetries():
			if twin_of(i, sym["xf"]) == i:
				var want: Vector3 = (sym["xf"] as Transform3D) * (spots[i]["snap"] as Vector3)
				var c := grid.nearest_main(want.x, want.z, 2.0)
				if c != Vector3.INF:
					alts.append(NavigationServer3D.map_get_closest_point(nav_map, c))
		spots[i]["alts"] = alts


## The spot index of `i`'s mirror twin under `xf` (same kind, within TWIN_TOL), -1 when none.
func twin_of(i: int, xf: Transform3D) -> int:
	var want: Vector3 = xf * (spots[i]["pos"] as Vector3)
	var best := -1
	var best_d := TWIN_TOL
	for j in spots.size():
		if spots[j]["kind"] != spots[i]["kind"]:
			continue
		var d := (spots[j]["pos"] as Vector3).distance_to(want)
		if d <= best_d:
			best_d = d
			best = j
	return best


# ---------------------------------------------------------------- navmesh

func _check_navmesh() -> void:
	var main_area := grid.comp_area[grid.main_comp] if grid.main_comp >= 0 else 0.0
	var map_area := 4.0 * grid.half * grid.half
	var issues: Array = []
	if grid.polygon_count == 0:
		issues.append({"sev": "FAIL", "where": "navmesh", "what": "0 polygons", "fix": "the bake did not run"})
	report.add_check("N1", "nav", "Navmesh baked", "polygons > 0; main walkable area shown", 1, issues, "", "", 1.0,
		"%d polygons, main area %.0f m² (%.0f %% of the %.0f m map), ground y %.2f" % [grid.polygon_count, main_area,
		100.0 * main_area / map_area, 2.0 * grid.half, grid.comp_y[grid.main_comp] if grid.main_comp >= 0 else 0.0])


func _check_reach() -> void:
	var issues: Array = []
	var ref := int(seat_keep.values()[0]) if not seat_keep.is_empty() else -1
	if seat_keep.size() < (profile.get("seats", []) as Array).size():
		issues.append({"sev": "FAIL", "where": "keeps", "what": "%d keeps for %d seats" % [seat_keep.size(),
			(profile.get("seats", []) as Array).size()], "fix": "the map must place one keep per seat"})
	for i in spots.size():
		var s := spots[i]
		s["reach"] = true
		var comp: int = grid.comp_at((s["snap"] as Vector3).x, (s["snap"] as Vector3).z)
		if ref >= 0 and i != ref:
			var path := NavigationServer3D.map_get_path(nav_map, spots[ref]["snap"], s["snap"], true)
			if path.is_empty() or path[path.size() - 1].distance_to(s["snap"]) > REACH_TOL:
				s["reach"] = false
		if not s["reach"] or (comp >= 0 and comp != grid.main_comp):
			s["reach"] = false
			issues.append({"sev": "FAIL", "where": s["id"], "what": "%s at %s is not reachable from %s (navmesh component %d)" % [
				s["kind"], _v(s["pos"]), spots[ref]["id"] if ref >= 0 else "-", comp],
				"fix": "open a gap (>= 2 m) in the colliders around it, or move the spot"})
		elif float(s["snap_d"]) > SNAP_WARN:
			issues.append({"sev": "WARN", "where": s["id"], "what": "%s is %.1f m from the nearest navmesh" % [s["kind"], s["snap_d"]],
				"fix": "the spot sits deep inside a collider: check its clearing"})
	report.add_check("N2", "nav", "Every spot reachable", "a path from the first keep ends within %.1f m of each spot; spot <= %.0f m from the navmesh" % [
		REACH_TOL, SNAP_WARN], spots.size(), issues, "open the blocked spot or move it", "", 2.0)


func _check_islands() -> void:
	var issues: Array = []
	var raised := 0
	var raised_area := 0.0
	for c in grid.comp_area.size():
		if c == grid.main_comp or grid.comp_area[c] <= 0.0:
			continue
		var y: float = grid.comp_y[c]
		var a: float = grid.comp_area[c]
		if absf(y - grid.comp_y[grid.main_comp]) > GROUND_Y:
			raised += 1
			raised_area += a
			continue
		var inside := ""
		for s: Dictionary in spots:
			if BUILDING_KINDS.has(String(s["kind"])) and Vector2((s["pos"] as Vector3).x, (s["pos"] as Vector3).z).distance_to(grid.comp_center[c]) < 6.0:
				inside = String(s["id"])
		if inside != "":
			issues.append({"sev": "INFO", "where": "island %d at %s" % [c, _v2(grid.comp_center[c])],
				"what": "%.1f m² inside the footprint of %s (unreachable by design)" % [a, inside], "fix": ""})
			continue
		var sev := "WARN" if a >= ISLAND_WARN_M2 else "INFO"
		issues.append({"sev": sev, "where": "island %d at %s" % [c, _v2(grid.comp_center[c])],
			"what": "%.1f m² of ground-level navmesh cut off from the main area (y %.2f)" % [a, y],
			"fix": "a pocket closed by colliders: widen its gap or fill it (trees / rocks)"})
	issues.append({"sev": "INFO", "where": "raised islands", "what": "%d islands on top of colliders (%.0f m², more than %.1f m above / below the ground navmesh): harmless" % [
		raised, raised_area, GROUND_Y], "fix": ""})
	report.add_check("N3", "nav", "No navmesh islands", "ground-level components other than the main one < %.0f m²" % ISLAND_WARN_M2,
		maxi(1, grid.comp_area.size() - 1 - raised), issues, "close or open the pocket")


# ---------------------------------------------------------------- mirror

func _check_spot_mirror() -> void:
	var issues: Array = []
	for sym: Dictionary in symmetries():
		for i in spots.size():
			if twin_of(i, sym["xf"]) < 0:
				issues.append({"sev": "FAIL", "where": spots[i]["id"], "what": "%s at %s has no twin at %s (%s)" % [
					spots[i]["kind"], _v(spots[i]["pos"]), _v((sym["xf"] as Transform3D) * (spots[i]["pos"] as Vector3)),
					sym["name"]], "fix": "place its mirror (or move it onto the mirror position)"})
	report.add_check("M1", "mirror", "Every live spot has its mirror twins", "same kind within %.1f m of each symmetry image" % TWIN_TOL,
		spots.size(), issues, "place the missing twin", "", 2.0)
	# The navmesh points the paths start / end at must mirror too, or F1 compares different doors of a building.
	var snap_issues: Array = []
	var rows := "| Spot | Kind | Position | On navmesh at | Twin | Twin's point, mirrored back | Gap |\n|---|---|---|---|---|---|---|\n"
	if not symmetries().is_empty():
		var xf: Transform3D = symmetries()[0]["xf"]
		for i in spots.size():
			var t := twin_of(i, xf)
			if t < 0:
				continue
			var back := xf.affine_inverse() * (spots[t]["snap"] as Vector3)
			var gap := Vector2(back.x - (spots[i]["snap"] as Vector3).x, back.z - (spots[i]["snap"] as Vector3).z).length()
			rows += "| %s | %s | %s | %s | %s | %s | %.1f |\n" % [spots[i]["id"], spots[i]["kind"], _v(spots[i]["pos"]),
				_v(spots[i]["snap"]), spots[t]["id"], _v(back), gap]
			if gap > 1.0:
				snap_issues.append({"sev": "WARN", "where": spots[i]["id"], "what": "navmesh point %s vs twin's mirrored %s (%.1f m apart)" % [
					_v(spots[i]["snap"]), _v(back), gap], "fix": "the obstacle around the spot is not mirrored (door / footprint), or the lab's snap rule needs a hint"})
	report.add_check("M4", "mirror", "Spots meet the navmesh at mirrored points", "each spot's navmesh point vs its twin's, mirrored back: <= 1 m",
		spots.size(), snap_issues, "", "", 1.0)
	report.add_table("Spot navmesh points (%s)" % (symmetries()[0]["name"] if not symmetries().is_empty() else "-"), rows)


## Every constant of the map script (and its base scripts) that holds positions.
func _script_constants() -> Dictionary:
	var out := {}
	var s: Script = level.get_script()
	while s != null:
		var m := s.get_script_constant_map()
		for k: String in m:
			if not out.has(k):
				out[k] = m[k]
		s = s.get_base_script()
	return out


## Position entries of one constant: [{label, pos, props, extra (Array[Vector3]), dir}]. [] = not positional.
func _entries_of(value: Variant) -> Array:
	var out: Array = []
	if value is Array:
		var i := 0
		for e: Variant in value:
			var ent := _entry(e, "[%d]" % i)
			if not ent.is_empty():
				out.append(ent)
			i += 1
	elif value is Dictionary:
		for k: Variant in value:
			var ent := _entry(value[k], String(k))
			if not ent.is_empty():
				out.append(ent)
	return out


func _entry(e: Variant, label: String) -> Dictionary:
	if e is Vector3:
		return {"label": label, "pos": e, "props": {}}
	if e is Vector2:
		return {"label": label, "pos": Vector3(e.x, 0.0, e.y), "props": {}}
	if e is Array and not (e as Array).is_empty() and (e as Array)[0] is Vector3:
		var props := {}
		for k in range(1, (e as Array).size()):
			props["v%d" % k] = (e as Array)[k]
		return {"label": label, "pos": (e as Array)[0], "props": props}
	if e is Dictionary:
		var d: Dictionary = e
		var pos: Variant = d.get("pos", d.get("center", null))
		var extra: Array = []
		for key: String in ["patrol", "spots"]:
			if d.get(key) is Array:
				for q: Variant in d[key]:
					if q is Vector3:
						extra.append(q)
		if pos == null and not extra.is_empty():
			var c := Vector3.ZERO
			for q: Vector3 in extra:
				c += q
			pos = c / float(extra.size())
		if not pos is Vector3:
			return {}
		var props := {}
		for key: Variant in d:
			if not SKIP_PROPS.has(String(key)):
				props[String(key)] = d[key]
		var ent := {"label": String(d.get("id", label)), "pos": pos, "props": props, "extra": extra}
		if d.get("door") is Vector3:
			ent["door"] = d["door"]
		if d.get("dir") is Vector3:
			ent["dir"] = d["dir"]
		return ent
	return {}


func _check_constants() -> void:
	var consts := _script_constants()
	var issues: Array = []
	var total := 0
	var singles := {}
	var rows := "| Constant | Entries | Result |\n|---|---|---|\n"
	for cname: String in consts:
		var v: Variant = consts[cname]
		if v is Vector3:
			singles[cname] = v
			continue
		var entries := _entries_of(v)
		if entries.is_empty():
			continue
		total += 1
		var result := _mirror_constant(cname, entries, issues)
		rows += "| %s | %d | %s |\n" % [cname, entries.size(), result]
	for cname: String in singles:
		total += 1
		var p: Vector3 = singles[cname]
		var result := "one side only (mirrored in code, INFO)"
		var all_self := true
		for sym: Dictionary in symmetries():
			if ((sym["xf"] as Transform3D) * p).distance_to(p) > CONST_TOL:
				all_self = false
		if all_self:
			result = "on every symmetry axis"
		else:
			for other: String in singles:
				if other != cname and ((symmetries()[0]["xf"] as Transform3D) * p).distance_to(singles[other]) <= CONST_TOL:
					result = "mirror of %s" % other
		if result.begins_with("one side"):
			issues.append({"sev": "INFO", "where": cname, "what": "single position %s, no mirrored constant" % _v(p),
				"fix": "fine when the code mirrors it (offsets, player-side slots)"})
		rows += "| %s | 1 | %s |\n" % [cname, result]
	report.add_check("M2", "mirror", "Spot constants mirror", "every position constant of %s: all entries have a twin under each symmetry (+-%.2f m) with the same kind / sizes / timings, or the list is one-sided (mirrored in code)" % [
		(level.get_script() as Script).resource_path.get_file(), CONST_TOL], total, issues,
		"fix the constant so the twin matches", "", 1.5)
	report.add_table("Spot constants (%d)" % total, rows)


## Checks one list constant; returns the table cell.
func _mirror_constant(cname: String, entries: Array, issues: Array) -> String:
	var matched_any := false
	var unmatched: Array[String] = []
	var prop_bad: Array[String] = []
	for sym: Dictionary in symmetries():
		var xf: Transform3D = sym["xf"]
		for e: Dictionary in entries:
			var want: Vector3 = xf * (e["pos"] as Vector3)
			var twin: Dictionary = {}
			for f: Dictionary in entries:
				if (f["pos"] as Vector3).distance_to(want) <= CONST_TOL and _same_kind(e, f):
					twin = f
					break
			if twin.is_empty():
				unmatched.append("%s %s" % [e["label"], _v(e["pos"])])
				continue
			matched_any = true
			var diff := _prop_diff(e, twin, xf)
			if diff != "":
				prop_bad.append("%s vs %s: %s" % [e["label"], twin["label"], diff])
	if not matched_any:
		issues.append({"sev": "INFO", "where": cname, "what": "%d entries on one side only (mirrored in code)" % entries.size(),
			"fix": ""})
		return "one side only (mirrored in code)"
	for u in unmatched:
		issues.append({"sev": "FAIL", "where": cname, "what": "%s has no mirror entry" % u,
			"fix": "add / fix its twin at the mirrored position"})
	for pb in _dedupe(prop_bad):
		issues.append({"sev": "FAIL", "where": cname, "what": "mirror twins differ: %s" % pb,
			"fix": "give both twins the same values (mirrored patrol / door / dir)"})
	if unmatched.is_empty() and prop_bad.is_empty():
		return "mirrored"
	return "**%d unmatched, %d differ**" % [unmatched.size(), _dedupe(prop_bad).size()]


static func _same_kind(a: Dictionary, b: Dictionary) -> bool:
	var ka: Variant = (a["props"] as Dictionary).get("kind")
	var kb: Variant = (b["props"] as Dictionary).get("kind")
	return ka == null or kb == null or String(ka) == String(kb)


## "" when two mirrored entries agree (props, mirrored door / patrol / spots, dir as a line).
static func _prop_diff(a: Dictionary, b: Dictionary, xf: Transform3D) -> String:
	var out: Array[String] = []
	var pa: Dictionary = a["props"]
	var pb: Dictionary = b["props"]
	for k: String in pa:
		if not pb.has(k):
			continue
		var va: Variant = pa[k]
		var vb: Variant = pb[k]
		if (va is float or va is int) and (vb is float or vb is int):
			if absf(float(va) - float(vb)) > 1e-4:
				out.append("%s %s / %s" % [k, str(va), str(vb)])
		elif typeof(va) == typeof(vb) and not (va is Array or va is Dictionary) and va != vb:
			out.append("%s %s / %s" % [k, str(va), str(vb)])
	if a.has("door") and b.has("door") and (xf * (a["door"] as Vector3)).distance_to(b["door"]) > CONST_TOL:
		out.append("door %s / %s" % [_v(a["door"]), _v(b["door"])])
	if a.has("dir") and b.has("dir"):
		var da := (xf.basis * (a["dir"] as Vector3)).normalized()
		var db := (b["dir"] as Vector3).normalized()
		if absf(da.dot(db)) < 0.999:
			out.append("dir %s / %s" % [_v(a["dir"]), _v(b["dir"])])
	var ea: Array = a.get("extra", [])
	var eb: Array = b.get("extra", [])
	if ea.size() != eb.size():
		out.append("%d / %d patrol-spots points" % [ea.size(), eb.size()])
	else:
		for q: Vector3 in ea:
			var found := false
			for r: Vector3 in eb:
				if (xf * q).distance_to(r) <= CONST_TOL:
					found = true
					break
			if not found:
				out.append("point %s has no mirror %s" % [_v(q), _v(xf * q)])
				break
	return ", ".join(out)


func _check_nav_mirror() -> void:
	var issues: Array = []
	var worst := 0.0
	var vals: Array[String] = []
	for sym: Dictionary in symmetries():
		var r: Dictionary = grid.mirror_mismatch(sym["xf"])
		var share := float(r["mismatch"]) / maxf(1.0, float(r["walkable"]))
		worst = maxf(worst, share)
		vals.append("%.2f %% (%d cells)" % [100.0 * share, r["mismatch"]])
		var sev := "FAIL" if share > NAV_MIRROR_FAIL else ("WARN" if share > NAV_MIRROR_WARN else "")
		var tiles: Array = r["tiles"]
		for k in mini(tiles.size(), 6 if sev != "" else 3):
			var t: Array = tiles[k]
			if int(t[1]) < 8:
				break
			issues.append({"sev": sev if sev != "" and k < 3 else "INFO", "where": "4 m tile at %s" % _v2(t[0]),
				"what": "%d cells (%.1f m²) walkable on one side only (%s)" % [t[1], float(t[1]) * Grid.CELL * Grid.CELL, sym["name"]],
				"fix": "a collider (tree, rock, landmark, building) without its mirror near %s or %s" % [_v2(t[0]),
					_v2(_mir2(t[0], sym["xf"]))]})
	report.add_check("M3", "mirror", "Navmesh mirrors itself", "cells walkable on one side only (1-cell edge noise ignored): WARN > %.1f %%, FAIL > %.0f %%" % [
		100.0 * NAV_MIRROR_WARN, 100.0 * NAV_MIRROR_FAIL], 1, issues, "mirror the collider", "", 1.5, ", ".join(vals))


# ---------------------------------------------------------------- paths

func _all_paths() -> void:
	var t0 := Time.get_ticks_usec()
	var n := spots.size()
	lens.resize(n * n)
	lens.fill(INF)
	for i in n:
		lens[i * n + i] = 0.0
		for j in range(i + 1, n):
			if not spots[i]["reach"] or not spots[j]["reach"]:
				continue
			var path := PackedVector3Array()
			var d := INF
			for a: Vector3 in spots[i].get("alts", [spots[i]["snap"]]):
				for b: Vector3 in spots[j].get("alts", [spots[j]["snap"]]):
					var p := NavigationServer3D.map_get_path(nav_map, a, b, true)
					if p.is_empty() or p[p.size() - 1].distance_to(b) > REACH_TOL:
						continue
					var pl := _path_len(p)
					if pl < d:
						d = pl
						path = p
			if is_inf(d):
				continue
			lens[i * n + j] = d
			lens[j * n + i] = d
			if heat_on:
				grid.add_heat(path)
	t_paths = float(Time.get_ticks_usec() - t0) / 1e6


func _geo_paths() -> void:
	var t0 := Time.get_ticks_usec()
	grid.build_coarse()
	var n := spots.size()
	geo_lens.resize(n * n)
	geo_lens.fill(INF)
	# A spot that is its own twin (the crown, on every axis) meets the navmesh on one side of its obstacle: it
	# counts as all the mirror images of that point (distance to the nearest), so no side is favoured.
	var cells: Array[PackedInt32Array] = []
	for i in n:
		var s := spots[i]
		var own := PackedInt32Array([grid.coarse_near((s["snap"] as Vector3).x, (s["snap"] as Vector3).z)])
		for sym: Dictionary in symmetries():
			if twin_of(i, sym["xf"]) == i:
				var m: Vector3 = (sym["xf"] as Transform3D) * (s["snap"] as Vector3)
				own.append(grid.coarse_near(m.x, m.z))
		cells.append(own)
	for i in n:
		if cells[i][0] < 0:
			continue
		var dist := grid.dijkstra(cells[i])
		for j in n:
			var best := INF
			for c in cells[j]:
				if c >= 0:
					best = minf(best, dist[c])
			geo_lens[i * n + j] = best
	report.notes.append("Octile grid shortest paths (0.5 m, %d sources) %.2f s." % [n, float(Time.get_ticks_usec() - t0) / 1e6])


func path_len(i: int, j: int) -> float:
	return lens[i * spots.size() + j]


static func _path_len(path: PackedVector3Array) -> float:
	var d := 0.0
	for k in range(path.size() - 1):
		d += path[k].distance_to(path[k + 1])
	return d


## F1 (geo = true): the octile shortest paths on the mirrored navmesh grid = is the MAP fair (FAIL / WARN).
## F2 (geo = false): the NavigationServer paths units really walk = engine path noise on top (INFO 2-5 %, WARN above).
func _check_pair_fairness(arr: PackedFloat32Array, geo: bool) -> void:
	var n := spots.size()
	var issues: Array = []
	var checked := 0
	var flagged: Array = []   # [rel, i, j, ti, tj, a, b, sym]
	var seen := {}
	for sym: Dictionary in symmetries():
		var twins := PackedInt32Array()
		for i in n:
			twins.append(twin_of(i, sym["xf"]))
		for i in n:
			for j in range(i + 1, n):
				var ti := twins[i]
				var tj := twins[j]
				if ti < 0 or tj < 0:
					continue
				var key := "%d,%d|%d,%d" % [mini(i, j), maxi(i, j), mini(ti, tj), maxi(ti, tj)]
				var key2 := "%d,%d|%d,%d" % [mini(ti, tj), maxi(ti, tj), mini(i, j), maxi(i, j)]
				if seen.has(key) or seen.has(key2):
					continue
				seen[key] = true
				var a := arr[i * n + j]
				var b := arr[ti * n + tj]
				if is_inf(a) or is_inf(b):
					continue
				checked += 1
				var rel := absf(a - b) / maxf(0.01, maxf(a, b))
				if rel > ASYM_WARN and absf(a - b) > ASYM_MIN_M:
					flagged.append([rel, i, j, ti, tj, a, b, sym["name"]])
	flagged.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) > float(y[0]))
	var rows := "| # | Pair | Length | Mirror pair | Length | Diff |\n|---|---|---|---|---|---|\n"
	var k := 0
	for f: Array in flagged:
		var rel: float = f[0]
		var a: float = f[5]
		var b: float = f[6]
		var big := rel > ASYM_FAIL and absf(a - b) > ASYM_FAIL_MIN_M
		var sev := ("FAIL" if big else "WARN") if geo else ("WARN" if big else "INFO")
		var longer := "%s-%s" % [spots[f[1]]["id"], spots[f[2]]["id"]] if a > b else "%s-%s" % [spots[f[3]]["id"], spots[f[4]]["id"]]
		issues.append({"sev": sev, "where": "%s-%s vs %s-%s" % [spots[f[1]]["id"], spots[f[2]]["id"], spots[f[3]]["id"],
			spots[f[4]]["id"]], "what": "%.1f m vs %.1f m (%.1f %%)" % [a, b, 100.0 * rel],
			"fix": ("%s is longer: look for an unmirrored collider on that route (heat map, M3 tiles)" if geo else "units walk %s the long way: the engine's polygon path, not the map (see F1)") % longer})
		if k < 20:
			rows += "| %d | %s - %s | %.1f | %s - %s | %.1f | %+.1f %% |\n" % [k + 1, spots[f[1]]["id"], spots[f[2]]["id"], a,
				spots[f[3]]["id"], spots[f[4]]["id"], b, 100.0 * (a - b) / maxf(a, b)]
		k += 1
	var cid := "F1" if geo else "F2"
	var cname := "Map geometry: path pairs match their mirror twins" if geo else "Unit paths (NavigationServer): pairs match their twins"
	var rule := ("octile shortest path on the 0.5 m navmesh grid, every spot pair vs its mirrored pair: WARN > %.0f %% (and > %.2f m), FAIL > %.0f %% (and > %.0f m)" if geo else "NavigationServer3D.map_get_path length, every spot pair vs its mirrored pair: INFO > %.0f %% (and > %.2f m), WARN > %.0f %% (and > %.0f m); the polygon A* is not mirrored, so this is how much the engine's path choice (not the map) favours a side") % [
		100.0 * ASYM_WARN, ASYM_MIN_M, 100.0 * ASYM_FAIL, ASYM_FAIL_MIN_M]
	report.add_check(cid, "fair", cname, rule, checked, issues,
		"find the unmirrored obstacle on the longer route" if geo else "engine path noise: a finer bake (smaller cell / edge_max_length) or path post-processing evens it", "", 3.0 if geo else 1.0,
		"%d / %d pairs within %.0f %% (%d FAIL, %d WARN, %d info)" % [checked - flagged.size(), checked, 100.0 * ASYM_WARN,
		report._count_sev(issues, "FAIL"), report._count_sev(issues, "WARN"), report._count_sev(issues, "INFO")])
	if not flagged.is_empty():
		report.add_table("%s: most asymmetric pairs (top %d of %d)" % [cid + (" map geometry" if geo else " unit paths"), mini(20, flagged.size()), flagged.size()], rows)


# ---------------------------------------------------------------- distances

func _seat_list() -> Array:
	var out: Array = []
	for s: Dictionary in profile.get("seats", []):
		if seat_keep.has(int(s["team"])):
			out.append(s)
	return out


func _distance_tables() -> void:
	var seats := _seat_list()
	if seats.size() < 2:
		report.add_info("D1", "dist", "Keep distances per seat", "fewer than 2 keeps found")
		return
	var head := "| From keep | " + " | ".join(DIST_KINDS.map(func(k: String) -> String: return "nearest " + k)) + " | enemy keep |\n"
	head += "|---|" + "---|".repeat(DIST_KINDS.size() + 1) + "\n"
	var rows := head
	var issues: Array = []
	var per_kind := {}   # kind -> [dist per seat]
	for s: Dictionary in seats:
		var ki: int = seat_keep[int(s["team"])]
		var cells: Array[String] = []
		for kind in DIST_KINDS:
			var best := INF
			var best_id := ""
			for j in spots.size():
				if spots[j]["kind"] == kind and path_len(ki, j) < best:
					best = path_len(ki, j)
					best_id = spots[j]["id"]
			cells.append("-" if is_inf(best) else "%.1f (%s)" % [best, best_id])
			if not per_kind.has(kind):
				per_kind[kind] = []
			per_kind[kind].append(best)
		var enemy := INF
		for o: Dictionary in seats:
			if int(o["side"]) != int(s["side"]):
				enemy = minf(enemy, path_len(ki, seat_keep[int(o["team"])]))
		cells.append("-" if is_inf(enemy) else "%.1f" % enemy)
		if not per_kind.has("enemy keep"):
			per_kind["enemy keep"] = []
		per_kind["enemy keep"].append(enemy)
		rows += "| %s | %s |\n" % [s["name"], " | ".join(cells)]
	var total := 0
	for kind: String in per_kind:
		var arr: Array = per_kind[kind]
		var lo := INF
		var hi := 0.0
		for v: float in arr:
			if is_inf(v):
				continue
			lo = minf(lo, v)
			hi = maxf(hi, v)
		if is_inf(lo):
			continue
		total += 1
		var rel := (hi - lo) / maxf(0.01, hi)
		if rel > ASYM_WARN and hi - lo > ASYM_MIN_M:
			issues.append({"sev": "WARN", "where": "nearest " + kind, "what": "%.1f m vs %.1f m between seats (%.1f %%)" % [lo, hi, 100.0 * rel],
				"fix": "move the far seat's spot closer (or check its route for a blocker)"})
	report.add_check("D1", "dist", "Keep to nearest camp / point / expansion... equal per seat", "per kind, the seats' nearest path lengths differ <= %.0f %%" % [
		100.0 * ASYM_WARN], total, issues, "", "", 1.5)
	report.add_table("Keep to nearest spot by kind (navmesh path, m)", rows)
	# Every spot from each seat's keep (the canonical seat's view; the twin column is the mirrored pair).
	var sym0: Transform3D = symmetries()[0]["xf"] if not symmetries().is_empty() else Transform3D.IDENTITY
	var s0: int = seat_keep[int(seats[0]["team"])]
	var t0 := twin_of(s0, sym0)
	if t0 >= 0:
		var r2 := "| Spot | Kind | From %s | Twin | From %s | Diff |\n|---|---|---|---|---|---|\n" % [spots[s0]["id"], spots[t0]["id"]]
		var order: Array = range(spots.size())
		order.sort_custom(func(a: int, b: int) -> bool: return path_len(s0, a) < path_len(s0, b))
		for j: int in order:
			var tj := twin_of(j, sym0)
			if j == s0 or tj < 0:
				continue
			var a := path_len(s0, j)
			var b := path_len(t0, tj)
			var diff := "-" if is_inf(a) or is_inf(b) else "%+.1f %%" % (100.0 * (a - b) / maxf(0.01, maxf(a, b)))
			r2 += "| %s | %s | %.1f | %s | %.1f | %s |\n" % [spots[j]["id"], spots[j]["kind"], a, spots[tj]["id"], b, diff]
		report.add_table("Every spot from the keeps (%s)" % symmetries()[0]["name"], r2)


# ---------------------------------------------------------------- allies (2v2) and travel times

## Seconds to walk `length` m at `speed` m/s when `ford_m` of it lies in fords / steps (FORD_SLOW there).
static func travel_seconds(length: float, ford_m: float, speed: float) -> float:
	if is_inf(length) or speed <= 0.0:
		return INF
	var f := clampf(ford_m, 0.0, length)
	return (length - f) / speed + f / (speed * (1.0 + FORD_SLOW))


static func mmss(sec: float) -> String:
	if is_inf(sec):
		return "-"
	var s := int(round(sec))
	return "%d:%02d" % [s / 60, s % 60]


## Seats grouped by side: side -> [team, ...] (profile order).
static func sides_of(seats: Array) -> Dictionary:
	var out := {}
	for s: Dictionary in seats:
		var side := int(s["side"])
		if not out.has(side):
			out[side] = []
		(out[side] as Array).append(int(s["team"]))
	return out


## Speeds of the T1 unit classes: [[label, speed]], from data/units/<id>.tres (fallback when missing).
static func travel_speeds() -> Array:
	var out: Array = []
	for u: Array in TRAVEL_UNITS:
		var path := "res://data/units/%s.tres" % u[1]
		var v: float = u[2]
		if ResourceLoader.exists(path):
			var r: Resource = load(path)
			if r and &"move_speed" in r:
				v = float(r.get(&"move_speed"))
		out.append([u[0], v])
	return out


## The shortest NavigationServer path between spots i and j (over their alternative points). Empty = none.
func _best_path(i: int, j: int) -> PackedVector3Array:
	var best := PackedVector3Array()
	var d := INF
	for a: Vector3 in spots[i].get("alts", [spots[i]["snap"]]):
		for b: Vector3 in spots[j].get("alts", [spots[j]["snap"]]):
			var p := NavigationServer3D.map_get_path(nav_map, a, b, true)
			if p.is_empty() or p[p.size() - 1].distance_to(b) > REACH_TOL:
				continue
			var pl := _path_len(p)
			if pl < d:
				d = pl
				best = p
	return best


## {len, ford, bridge, water}: metres of the path inside ford / steps circles, on bridge decks, and whether it
## crosses the river at all (a ford, steps or a bridge).
func _path_terrain(path: PackedVector3Array) -> Dictionary:
	var river := _river()
	var out := {"len": _path_len(path), "ford": 0.0, "bridge": 0.0, "water": false}
	if river == null or path.size() < 2:
		return out
	# A World Forge river (forge_river.gd) may have no ford / bridge queries: fall back to is_water, else lengths only.
	var has_ford := river.has_method(&"is_ford")
	var has_bridge := river.has_method(&"is_bridge")
	var has_water := river.has_method(&"is_water")
	if not has_ford and not has_bridge and not has_water:
		return out
	for k in range(path.size() - 1):
		var a := path[k]
		var b := path[k + 1]
		var seg := a.distance_to(b)
		var steps := maxi(1, int(ceil(seg / SAMPLE_M)))
		for s in steps:
			var p := a.lerp(b, (float(s) + 0.5) / float(steps))
			if has_ford and river.call(&"is_ford", p):
				out["ford"] = float(out["ford"]) + seg / steps
				out["water"] = true
			elif has_bridge and river.call(&"is_bridge", p):
				out["bridge"] = float(out["bridge"]) + seg / steps
				out["water"] = true
			elif not has_ford and has_water and river.call(&"is_water", p):
				out["water"] = true
	return out


## A1 (maps with allies, e.g. the 2v2): per seat, the path to its ally keep vs its enemy keeps. Rules: the ally
## distance is equal on every side (<= 2 %), the ally is not much farther than the nearest enemy
## (<= ALLY_FAR_RATIO x), the ally road crosses no river when the profile says `ally_dry`, and the profile's
## `targets` (ally_keep / enemy_keep_near / enemy_keep_far, from the map spec) are met within 10 %.
func _check_allies() -> void:
	var seats := _seat_list()
	var sides := sides_of(seats)
	var has_allies := false
	for side: int in sides:
		if (sides[side] as Array).size() >= 2:
			has_allies = true
	if not has_allies:
		report.add_info("A1", "dist", "Ally keeps (team maps)", "no side has 2 seats (1v1): nothing to check")
		return
	var targets: Dictionary = profile.get("targets", {})
	var ally_dry := bool(profile.get("ally_dry", false))
	var issues: Array = []
	var rows := "| Seat | Side | Ally keep | Ally path (m) | Crosses river | Nearest enemy (m) | Farthest enemy (m) | Ally / nearest enemy |\n|---|---|---|---|---|---|---|---|\n"
	var ally_d: Array = []
	var total := 0
	for s: Dictionary in seats:
		var team := int(s["team"])
		var ki: int = seat_keep[team]
		var ally := INF
		var ally_team := -1
		var near := INF
		var far := 0.0
		for o: Dictionary in seats:
			var ot := int(o["team"])
			if ot == team:
				continue
			var d := path_len(ki, seat_keep[ot])
			if int(o["side"]) == int(s["side"]):
				if d < ally:
					ally = d
					ally_team = ot
			else:
				near = minf(near, d)
				if not is_inf(d):
					far = maxf(far, d)
		if ally_team < 0:
			continue
		total += 1
		var where := String(s["name"])
		var wet := false
		if is_inf(ally):
			issues.append({"sev": "FAIL", "where": where, "what": "no path to the ally keep", "fix": "open a road between the allies"})
		else:
			ally_d.append(ally)
			var terr := _path_terrain(_best_path(ki, seat_keep[ally_team]))
			wet = bool(terr["water"])
			if wet and ally_dry:
				issues.append({"sev": "WARN", "where": where, "what": "the ally road crosses the river (%.1f m ford, %.1f m bridge)" % [
					terr["ford"], terr["bridge"]], "fix": "the spec keeps allies on one bank: check the connector road / river course"})
			if not is_inf(near) and ally > near * ALLY_FAR_RATIO:
				issues.append({"sev": "WARN", "where": where, "what": "ally keep %.1f m vs nearest enemy %.1f m (x%.2f)" % [ally, near, ally / near],
					"fix": "allies too far apart to defend each other: shorten the ally road"})
		for key: String in targets:
			var want := float(targets[key])
			var got: float = {"ally_keep": ally, "enemy_keep_near": near, "enemy_keep_far": far}.get(key, INF)
			if want > 0.0 and not is_inf(got) and absf(got - want) / want > TARGET_TOL:
				issues.append({"sev": "WARN", "where": where, "what": "%s %.1f m vs spec ~%.0f m (%+.0f %%)" % [key, got, want, 100.0 * (got - want) / want],
					"fix": "the map drifted from its spec (%s): move the keep / road or update the spec" % profile.get("spec", "-")})
		rows += "| %s | %d | %s | %s | %s | %s | %s | %s |\n" % [where, int(s["side"]), spots[seat_keep[ally_team]]["id"],
			"-" if is_inf(ally) else "%.1f" % ally, "yes" if wet else "no", "-" if is_inf(near) else "%.1f" % near,
			"-" if far <= 0.0 else "%.1f" % far, "-" if is_inf(ally) or is_inf(near) else "%.2f" % (ally / near)]
	if ally_d.size() >= 2:
		var lo: float = ally_d.min()
		var hi: float = ally_d.max()
		var rel := (hi - lo) / maxf(0.01, hi)
		if rel > ASYM_WARN and hi - lo > ASYM_MIN_M:
			issues.append({"sev": "WARN", "where": "ally roads", "what": "%.1f m vs %.1f m between sides (%.1f %%)" % [lo, hi, 100.0 * rel],
				"fix": "one side's allies are farther apart: an unmirrored blocker on the ally road"})
	report.add_check("A1", "dist", "Ally keeps: equal, close, on their bank", "ally path equal per side (<= %.0f %%), <= %.2f x the nearest enemy keep%s%s" % [
		100.0 * ASYM_WARN, ALLY_FAR_RATIO, ", never across the river" if ally_dry else "",
		", spec targets +-%.0f %%" % (100.0 * TARGET_TOL) if not targets.is_empty() else ""], total, issues,
		"", "", 1.5)
	report.add_table("Ally keeps per seat (navmesh path, m)", rows)


## T1: travel times per seat and unit class (path length / UnitType.move_speed, ford / steps metres at FORD_SLOW):
## keep -> ally keep(s), every enemy keep, nearest expansion, point, camp, crown. Seats' times to the same
## destination differ by <= TRAVEL_SPREAD_S (and 3 %) for every class (WARN). Terrain speed costs are not in yet.
func _travel_times() -> void:
	var seats := _seat_list()
	if seats.size() < 2:
		report.add_info("T1", "dist", "Travel times per seat", "fewer than 2 keeps found")
		return
	var speeds := travel_speeds()
	var head := "| Seat | Destination | Path (m) | Ford (m) |"
	for u: Array in speeds:
		head += " %s (%.1f m/s) |" % [u[0], u[1]]
	var rows := head + "\n|---|---|---|---|" + "---|".repeat(speeds.size()) + "\n"
	var by_dest := {}   # dest label -> [[seat name, [sec per class]]]
	for s: Dictionary in seats:
		var team := int(s["team"])
		var ki: int = seat_keep[team]
		var dests: Array = []   # [label, spot index]
		var enemies: Array = []
		for o: Dictionary in seats:
			var ot := int(o["team"])
			if ot == team:
				continue
			if int(o["side"]) == int(s["side"]):
				dests.append(["ally keep", seat_keep[ot]])
			else:
				enemies.append([path_len(ki, seat_keep[ot]), seat_keep[ot]])
		enemies.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
		for e in enemies.size():
			dests.append(["enemy keep (nearest)" if e == 0 and enemies.size() > 1 else ("enemy keep" if enemies.size() == 1 else "enemy keep #%d" % (e + 1)), enemies[e][1]])
		for kind: String in ["expansion", "point", "camp", "crown"]:
			var best := INF
			var bj := -1
			for j in spots.size():
				if spots[j]["kind"] == kind and path_len(ki, j) < best:
					best = path_len(ki, j)
					bj = j
			if bj >= 0:
				dests.append(["nearest " + kind if kind != "crown" else "crown", bj])
		for d: Array in dests:
			var path := _best_path(ki, int(d[1]))
			if path.is_empty():
				rows += "| %s | %s (%s) | - | - |%s\n" % [s["name"], d[0], spots[d[1]]["id"], " - |".repeat(speeds.size())]
				continue
			var terr := _path_terrain(path)
			var secs: Array = []
			var cells := ""
			for u: Array in speeds:
				var t := travel_seconds(float(terr["len"]), float(terr["ford"]), float(u[1]))
				secs.append(t)
				cells += " %s |" % mmss(t)
			rows += "| %s | %s (%s) | %.1f | %.1f |%s\n" % [s["name"], d[0], spots[d[1]]["id"], terr["len"], terr["ford"], cells]
			if not by_dest.has(d[0]):
				by_dest[d[0]] = []
			(by_dest[d[0]] as Array).append([String(s["name"]), secs])
	var issues: Array = []
	var total := 0
	for label: String in by_dest:
		var list: Array = by_dest[label]
		if list.size() < 2:
			continue
		total += 1
		for c in speeds.size():
			var lo := INF
			var hi := 0.0
			for it: Array in list:
				var t: float = it[1][c]
				lo = minf(lo, t)
				hi = maxf(hi, t)
			if hi - lo > TRAVEL_SPREAD_S and (hi - lo) / maxf(0.01, hi) > TRAVEL_SPREAD_REL:
				issues.append({"sev": "WARN", "where": "%s (%s)" % [label, speeds[c][0]], "what": "%s vs %s between seats" % [mmss(lo), mmss(hi)],
					"fix": "one seat's route is longer or crosses more ford: see the travel-time table"})
				break
	report.add_check("T1", "dist", "Travel times per seat (worker / soldier / cavalry / caravan)",
		"path length / UnitType.move_speed with fords and steps at %+.0f %%; seats' times per destination within %.0f s (and %.0f %%)" % [
		100.0 * FORD_SLOW, TRAVEL_SPREAD_S, 100.0 * TRAVEL_SPREAD_REL], total, issues, "", "", 1.0)
	report.add_table("Travel times per seat (m:ss from the keep; terrain speed costs not included)", rows)


# ---------------------------------------------------------------- chokes

func _check_crossings() -> void:
	var river := _river()
	if river == null:
		report.add_info("C1", "choke", "Crossing widths", "no river on this map")
		return
	var issues: Array = []
	var rows := "| Crossing | Kind | Spec width | Navmesh width | ~Real gap | Twin | Twin width |\n|---|---|---|---|---|---|---|\n"
	var widths := {}
	var list: Array = river.call(&"crossings")
	for c: Dictionary in list:
		var center: Vector3 = c["center"]
		var dir: Vector3 = c.get("dir", Vector3.RIGHT)
		var d2 := Vector2(dir.x, dir.z).normalized()
		# Fords: `dir` is the water flow, units cross across it, so the width lies along the flow. Bridges / steps:
		# `dir` is the way across, the width lies perpendicular to it.
		var across := d2 if String(c.get("kind", "")) == "ford" else Vector2(-d2.y, d2.x)
		var w: Dictionary = grid.width_at(Vector2(center.x, center.z), across, 12.0)
		widths[String(c["id"])] = float(w["width"])
	for c: Dictionary in list:
		var id := String(c["id"])
		var w: float = widths[id]
		var twin_id := "-"
		var tw := -1.0
		var si := _spot_index(id)
		if si >= 0 and not symmetries().is_empty():
			var ti := twin_of(si, symmetries()[0]["xf"])
			if ti >= 0:
				twin_id = spots[ti]["id"]
				tw = float(widths.get(twin_id, -1.0))
		if tw >= 0.0 and absf(tw - w) > CROSSING_TWIN_TOL:
			issues.append({"sev": "WARN", "where": id, "what": "navmesh width %.1f m vs twin %s %.1f m" % [w, twin_id, tw],
				"fix": "a collider narrows one side of the crossing (willow, rock, bridge post)"})
		if w < CROSSING_NARROW:
			issues.append({"sev": "WARN", "where": id, "what": "only %.1f m of navmesh across (units pass single file)" % w,
				"fix": "widen the crossing or clear its approach"})
		rows += "| %s | %s | %.1f | %.1f | %.1f | %s | %s |\n" % [id, c.get("kind", ""), float(c.get("width", 0.0)), w, w + 1.0,
			twin_id, "-" if tw < 0.0 else "%.1f" % tw]
	report.add_check("C1", "choke", "Crossing widths", "navmesh width across each crossing >= %.1f m and equal to its twin (+-%.1f m)" % [
		CROSSING_NARROW, CROSSING_TWIN_TOL], list.size(), issues, "", "", 1.0)
	report.add_table("Crossings (navmesh width = where unit centres can go; real gap ~ +1.0 m agent diameter)", rows)


## Main routes per seat: keep -> crown, keep -> each enemy keep, keep -> nearest expansion. Narrowest navmesh
## corridor along each (sampled every metre, 4 m from both ends skipped), compared with its mirror twin.
func _check_routes() -> void:
	var seats := _seat_list()
	var routes: Array = []   # [label, i, j]
	var crown := -1
	for j in spots.size():
		if spots[j]["kind"] == "crown":
			crown = j
	for s: Dictionary in seats:
		var ki: int = seat_keep[int(s["team"])]
		if crown >= 0:
			routes.append(["%s -> crown" % spots[ki]["id"], ki, crown])
		for o: Dictionary in seats:
			if int(o["side"]) != int(s["side"]) and int(o["team"]) > int(s["team"]):
				routes.append(["%s -> %s" % [spots[ki]["id"], spots[seat_keep[int(o["team"])]]["id"]], ki, seat_keep[int(o["team"])]])
		var best := -1
		for j in spots.size():
			if spots[j]["kind"] == "expansion" and (best < 0 or path_len(ki, j) < path_len(ki, best)):
				best = j
		if best >= 0:
			routes.append(["%s -> %s" % [spots[ki]["id"], spots[best]["id"]], ki, best])
	var issues: Array = []
	var rows := "| Route | Length | Narrowest (navmesh m) | At | Chokes < %.0f m |\n|---|---|---|---|---|\n" % CHOKE_WIDTH
	var mins := {}
	for r: Array in routes:
		var path := NavigationServer3D.map_get_path(nav_map, spots[r[1]]["snap"], spots[r[2]]["snap"], true)
		var res := _route_width(path)
		mins["%d>%d" % [r[1], r[2]]] = res
		var chokes: Array[String] = []
		for c: Array in res["chokes"]:
			chokes.append("%s %.1f" % [_v2(c[0]), c[1]])
		rows += "| %s | %.1f | %.1f | %s | %s |\n" % [r[0], _path_len(path), res["min"], _v2(res["at"]),
			", ".join(chokes) if not chokes.is_empty() else "-"]
	for r: Array in routes:
		for sym: Dictionary in symmetries():
			var ti := twin_of(r[1], sym["xf"])
			var tj := twin_of(r[2], sym["xf"])
			var key := "%d>%d" % [ti, tj]
			if not mins.has(key):
				key = "%d>%d" % [tj, ti]
			if not mins.has(key):
				continue
			var a: float = mins["%d>%d" % [r[1], r[2]]]["min"]
			var b: float = mins[key]["min"]
			if a + ROUTE_TWIN_TOL < b:
				issues.append({"sev": "WARN", "where": r[0], "what": "narrowest %.1f m at %s vs its twin's %.1f m" % [a,
					_v2(mins["%d>%d" % [r[1], r[2]]]["at"]), b],
					"fix": "a collider narrows this route only on one side"})
	report.add_check("C2", "choke", "Main routes: narrowest corridor matches the twin", "keep -> crown / enemy keep / nearest expansion: the narrowest navmesh width along the path differs from the mirrored route's by <= %.1f m" % [
		ROUTE_TWIN_TOL], routes.size(), issues, "", "", 1.0)
	report.add_table("Main routes: narrowest corridors (navmesh width; real gap ~ +1.0 m)", rows)


## {min, at, chokes: [[Vector2, width]]} along a path.
func _route_width(path: PackedVector3Array) -> Dictionary:
	var total := _path_len(path)
	var out := {"min": INF, "at": Vector2.ZERO, "chokes": []}
	var dist := 0.0
	var next := 4.0
	for k in range(path.size() - 1):
		var a := path[k]
		var b := path[k + 1]
		var seg := a.distance_to(b)
		if seg < 0.001:
			continue
		var d2 := Vector2(b.x - a.x, b.z - a.z).normalized()
		while next <= dist + seg and next <= total - 4.0:
			var q := a.lerp(b, (next - dist) / seg)
			var w: Dictionary = grid.width_at(Vector2(q.x, q.z), Vector2(-d2.y, d2.x), 20.0)
			var wv: float = w["width"]
			if wv < out["min"]:
				out["min"] = wv
				out["at"] = Vector2(q.x, q.z)
			if wv < CHOKE_WIDTH:
				var merged := false
				for c: Array in out["chokes"]:
					if (c[0] as Vector2).distance_to(Vector2(q.x, q.z)) < 5.0:
						merged = true
						if wv < float(c[1]):
							c[0] = Vector2(q.x, q.z)
							c[1] = wv
				if not merged:
					out["chokes"].append([Vector2(q.x, q.z), wv])
			next += 1.0
		dist += seg
	if is_inf(float(out["min"])):
		out["min"] = 0.0
	return out


# ---------------------------------------------------------------- heat map

func _write_heat() -> void:
	var marks: Array = []
	for s: Dictionary in spots:
		var kind: String = s["kind"]
		marks.append({"pos": s["pos"], "color": KIND_COLORS.get(kind, Color(0.2, 0.9, 0.9) if kind.begins_with("crossing") else Color.WHITE)})
	var img: Image = grid.heat_image(marks)
	var path := out_dir.path_join("heatmap.png")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var err := img.save_png(path)
	var hot: Array = grid.hot_spots(10)
	var rows := "| # | Where (x, z) | Shortest paths through this metre | Share |\n|---|---|---|---|\n"
	var npaths := spots.size() * (spots.size() - 1) / 2
	var k := 1
	for h: Array in hot:
		rows += "| %d | %s | %d | %.0f %% |\n" % [k, _v2(h[0]), int(h[1]), 100.0 * float(h[1]) / maxf(1.0, float(npaths))]
		k += 1
	report.add_info("H1", "info", "Heat map (sum of all shortest paths)", "heatmap.png %s (%d x %d px, 4 px per metre; grey navmesh, blue islands, yellow -> red path use, dots = spots)" % [
		"written" if err == OK else "NOT written (error %d)" % err, grid.n, grid.n])
	report.add_table("Hottest metres (every spot-pair shortest path, %d paths)" % npaths, rows)


# ---------------------------------------------------------------- helpers

static func _v(p: Vector3) -> String:
	return "(%.1f, %.1f)" % [p.x, p.z]


static func _v2(p: Vector2) -> String:
	return "(%.1f, %.1f)" % [p.x, p.y]


static func _mir2(p: Vector2, xf: Transform3D) -> Vector2:
	var q := xf * Vector3(p.x, 0.0, p.y)
	return Vector2(q.x, q.z)


static func _dedupe(arr: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for s in arr:
		if not out.has(s):
			out.append(s)
	return out

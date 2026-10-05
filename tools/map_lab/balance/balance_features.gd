extends RefCounted
## Balance model, part 1: the per-seat layout features of a loaded LayoutLevel whose navmesh is baked
## (docs/tools/map_gate/balance_model.md). No bot games: about 1-5 s after the bake.
## For each of the two playing seats (team 0 = the layout's side-0 seat, team 1 = side 1, as the map gate's G5 counts
## them) it measures what the bots actually use: NavigationServer path lengths (what units walk, triangulation included)
## and the Map Lab grid's geometric shortest paths (mirror-exact), from the keep's front door to every resource node,
## the halls, the third, the crown, the enemy, the neutral objectives, the Commander's build slots and marks; the
## navmesh widths along the main route (chokes, base pocket); then the SIGNED asymmetry of each feature:
##   rel features  a = (v0 - v1) / mean(v0, v1)     (distances, widths)
##   share features a = v0 - v1                    (fractions 0-1)
## and the ADVANTAGE of seat 0 = a * dir (dir -1 when smaller is better for the seat), so adv > 0 = seat 0 favoured.
## No class_name on purpose (preloaded tool script).

const MapGrid := preload("res://tools/map_lab/map_grid.gd")
const COMMANDER := preload("res://scripts/ai/commander.gd")

## Feature table. kind rel / share; dir: -1 smaller is better for the seat, +1 larger is better; tol: the asymmetry
## that costs the feature's full weight in the internal score (rel: fraction, share: difference); weight: score points
## lost at tol (x up to 1.5 beyond it). group: what the map maker changes to fix it.
const FEATURES: Array[Dictionary] = [
	{"id": "eco_home_nav", "group": "economy", "label": "keep door -> home nodes a / b (navmesh walk)", "kind": "rel", "dir": -1, "tol": 0.08, "weight": 6.0},
	{"id": "eco_trip_nav", "group": "economy", "label": "home nodes a / b -> keep rim, the mining trip (navmesh)", "kind": "rel", "dir": -1, "tol": 0.08, "weight": 10.0},
	{"id": "eco_home_grid", "group": "economy", "label": "keep -> home nodes a / b (geometric)", "kind": "rel", "dir": -1, "tol": 0.05, "weight": 8.0},
	{"id": "eco_mid_nav", "group": "economy", "label": "natural hall -> natural node (navmesh)", "kind": "rel", "dir": -1, "tol": 0.10, "weight": 5.0},
	{"id": "eco_rich_nav", "group": "economy", "label": "rich hall -> rich node (navmesh)", "kind": "rel", "dir": -1, "tol": 0.10, "weight": 4.0},
	{"id": "exp_nat_nav", "group": "expansion", "label": "keep -> natural hall (navmesh)", "kind": "rel", "dir": -1, "tol": 0.06, "weight": 6.0},
	{"id": "exp_nat_grid", "group": "expansion", "label": "keep -> natural hall (geometric)", "kind": "rel", "dir": -1, "tol": 0.05, "weight": 4.0},
	{"id": "exp_rich_nav", "group": "expansion", "label": "keep -> rich hall (navmesh)", "kind": "rel", "dir": -1, "tol": 0.06, "weight": 4.0},
	{"id": "exp_third_grid", "group": "expansion", "label": "keep -> third node (geometric)", "kind": "rel", "dir": -1, "tol": 0.06, "weight": 3.0},
	{"id": "atk_keep_nav", "group": "attack", "label": "keep -> enemy keep (navmesh)", "kind": "rel", "dir": -1, "tol": 0.05, "weight": 5.0},
	{"id": "atk_rally_nav", "group": "attack", "label": "rally -> enemy natural / rich / keep (navmesh)", "kind": "rel", "dir": -1, "tol": 0.06, "weight": 5.0},
	{"id": "def_exposure_grid", "group": "defence", "label": "enemy keep -> own natural / rich hall (geometric, farther = safer)", "kind": "rel", "dir": 1, "tol": 0.06, "weight": 5.0},
	{"id": "crown_nav", "group": "contest", "label": "keep -> crown (navmesh)", "kind": "rel", "dir": -1, "tol": 0.05, "weight": 3.0},
	{"id": "contest_share", "group": "contest", "label": "share of neutral objectives nearer this seat (geometric)", "kind": "share", "dir": 1, "tol": 0.15, "weight": 6.0},
	{"id": "camps_grid", "group": "contest", "label": "keep -> nearest 3 creep camps (geometric)", "kind": "rel", "dir": -1, "tol": 0.10, "weight": 3.0},
	{"id": "vision_grid", "group": "contest", "label": "keep -> nearest watchtower / vision point (geometric)", "kind": "rel", "dir": -1, "tol": 0.12, "weight": 2.0},
	{"id": "pocket_width", "group": "defence", "label": "narrowest navmesh width leaving the base (first 30 m, narrower = safer)", "kind": "rel", "dir": -1, "tol": 0.20, "weight": 3.0, "dead": 0.75, "floor": 8.0},
	{"id": "choke_home", "group": "defence", "label": "chokes (< 8 m) on the main route in the seat's own half", "kind": "share", "dir": 1, "tol": 0.34, "weight": 3.0},
	{"id": "slots_grid", "group": "bot slots", "label": "keep -> Commander build slots (geometric)", "kind": "rel", "dir": -1, "tol": 0.06, "weight": 4.0},
	{"id": "marks_grid", "group": "bot slots", "label": "keep -> bot rally / anchor / hub marks (geometric)", "kind": "rel", "dir": -1, "tol": 0.08, "weight": 3.0},
	{"id": "nav_detour", "group": "navmesh", "label": "navmesh / geometric path ratio over the economy targets", "kind": "rel", "dir": -1, "tol": 0.04, "weight": 4.0, "dead": 0.03, "floor": 1.0},
]
const DEAD_M := 0.5            ## rel features: differences under this (m) count as 0
const FLOOR_M := 15.0          ## rel features: the mean under the difference is at least this (m)
const CHOKE_W := 8.0           ## navmesh width (m) under which a route sample counts as a choke
const POCKET_LEN := 30.0       ## base pocket: the first metres of the route out of the base
const NEUTRAL_KINDS := ["camp", "point", "lair", "cache", "tavern", "peddler", "post", "guild"]


## Returns {ok, error, map, seats: [{feature id -> value}, {...}], asym: {id -> a}, adv: {id -> seat-0 advantage},
## abs: {absolute sanity numbers}, notes: [String], seconds}.
static func extract(level: Node) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	var lay: MapLayout = level.get(&"layout")
	var out := {"ok": false, "error": "", "map": String(lay.id) if lay else "", "seats": [], "asym": {}, "adv": {}, "abs": {}, "notes": []}
	if lay == null:
		out["error"] = "no layout"
		return out
	var half := maxf(lay.size_x, lay.size_z) * 0.5
	if half <= 0.0:
		half = lay.size * 0.5
	var grid := MapGrid.new()
	grid.build(level.find_children("*", "NavigationRegion3D", true, false), half)
	grid.build_coarse()
	var nav: RID = (level as Node3D).get_world_3d().navigation_map
	var ctx := {"level": level, "lay": lay, "grid": grid, "nav": nav, "dist": {}}
	var seats: Array = []
	for t: int in [0, 1]:
		seats.append(_seat_features(ctx, t))
	# contest share: every neutral objective (identity image + its twins) nearer to one seat (grid, 3 % tie band)
	var near := [0, 0]
	var total := 0
	for kind: String in NEUTRAL_KINDS:
		for s: Dictionary in lay.spots_of(kind):
			var p: Vector3 = s["pos"]
			var d0 := _grid_to(ctx, 0, p)
			var d1 := _grid_to(ctx, 1, p)
			if d0 == INF and d1 == INF:
				continue
			total += 1
			if d0 < d1 * 0.97:
				near[0] += 1
			elif d1 < d0 * 0.97:
				near[1] += 1
	for t: int in [0, 1]:
		(seats[t] as Dictionary)["contest_share"] = float(near[t]) / maxf(1.0, total)
	# chokes on the main route: navmesh path keep 0 -> keep 1, widths across it every 2 m
	var route := _route_chokes(ctx)
	for t: int in [0, 1]:
		(seats[t] as Dictionary)["choke_home"] = float(route["home"][t]) / maxf(1.0, float(route["count"]))
		(seats[t] as Dictionary)["pocket_width"] = route["pocket"][t]
	out["seats"] = seats
	var aa := asym_of(seats, out["notes"])
	out["asym"] = aa["asym"]
	out["adv"] = aa["adv"]
	# absolute sanity numbers
	var ab := {}
	ab["size"] = maxf(lay.size_x, lay.size_z)
	ab["keep_keep"] = (float(seats[0]["raw_keep_keep"]) + float(seats[1]["raw_keep_keep"])) * 0.5
	ab["natural"] = (float(seats[0]["exp_nat_grid"]) + float(seats[1]["exp_nat_grid"])) * 0.5
	ab["home_nodes"] = (float(seats[0]["eco_home_grid"]) + float(seats[1]["eco_home_grid"])) * 0.5
	ab["route_min_width"] = route["min_width"]
	ab["route_chokes"] = route["count"]
	ab["camps"] = lay.spots_of("camp").size()
	ab["neutral_objectives"] = total
	ab["slot_sym_err"] = _slot_sym_err(ctx)
	ab["unreachable"] = int(seats[0]["raw_unreachable"]) + int(seats[1]["raw_unreachable"])
	out["abs"] = ab
	out["ok"] = true
	out["seconds"] = float(Time.get_ticks_msec() - t0) / 1000.0
	return out


## Signed asymmetry and seat-0 advantage of every feature from the two seats' raw values (also used by the fitter
## on stored datasets, so the dead bands / floors can change without re-extracting).
static func asym_of(seats: Array, notes: Array = []) -> Dictionary:
	var asym := {}
	var adv := {}
	for f: Dictionary in FEATURES:
		var id: String = f["id"]
		var r0: Variant = (seats[0] as Dictionary).get(id)
		var r1: Variant = (seats[1] as Dictionary).get(id)
		var v0: float = float(r0) if (r0 is float or r0 is int) else NAN   # JSON writes NaN / INF as null
		var v1: float = float(r1) if (r1 is float or r1 is int) else NAN
		var a := 0.0
		if not is_finite(v0) or not is_finite(v1):
			a = 0.0
			if not (is_nan(v0) and is_nan(v1)):
				notes.append("%s: missing or unreachable on a seat (%s / %s), counted as 0" % [id, str(v0), str(v1)])
		elif f["kind"] == "share":
			a = v0 - v1
		else:
			# dead band (navmesh carving / grid quantisation noise, ~0.3 m on a mirrored map) and a floor under the
			# mean (a 1 m difference on an 8 m trip is not a 12 % map flaw)
			var dead := float(f.get("dead", DEAD_M))
			var m := maxf((absf(v0) + absf(v1)) * 0.5, float(f.get("floor", FLOOR_M)))
			var dv := absf(v0 - v1) - dead
			a = 0.0 if dv <= 0.0 else signf(v0 - v1) * dv / m
		asym[id] = a
		adv[id] = a * float(f["dir"])
	return {"asym": asym, "adv": adv}


static func _seat_features(ctx: Dictionary, t: int) -> Dictionary:
	var lv: Node = ctx["level"]
	var e := 1 - t
	var f := {}
	ctx["unreach"] = 0
	var door: Vector3 = lv.start_position(t)
	var edoor: Vector3 = lv.start_position(e)
	var na: Vector3 = lv.call(&"_node_spot_pos", t, "a")
	var nb: Vector3 = lv.call(&"_node_spot_pos", t, "b")
	var nmid: Vector3 = lv.call(&"_node_spot_pos", t, "mid")
	var nrich: Vector3 = lv.call(&"_node_spot_pos", t, "rich")
	var nthird: Vector3 = lv.call(&"_node_spot_pos", t, "third")
	var nat: Vector3 = lv.natural_hall_spot(t)
	var rich: Vector3 = lv.rich_hall_spot(t)
	var enat: Vector3 = lv.natural_hall_spot(e)
	var erich: Vector3 = lv.rich_hall_spot(e)
	var home_nav: Array[float] = [_nav_len(ctx, door, na), _nav_len(ctx, door, nb)]
	var home_grid: Array[float] = [_grid_to(ctx, t, na), _grid_to(ctx, t, nb)]
	f["eco_home_nav"] = _mean_ok(home_nav)
	f["eco_home_grid"] = _mean_ok(home_grid)
	f["eco_mid_nav"] = _nav_len(ctx, nat, nmid)
	f["eco_rich_nav"] = _nav_len(ctx, rich, nrich)
	f["exp_nat_nav"] = _nav_len(ctx, door, nat)
	f["exp_nat_grid"] = _grid_to(ctx, t, nat)
	f["exp_rich_nav"] = _nav_len(ctx, door, rich)
	f["exp_third_grid"] = _grid_to(ctx, t, nthird)
	f["atk_keep_nav"] = _nav_len(ctx, door, edoor)
	f["raw_keep_keep"] = _grid_to(ctx, t, edoor)
	var rally: Vector3 = lv.bot_mark(t, &"rally")
	if rally == Vector3.INF:
		rally = door
	f["atk_rally_nav"] = _mean_ok([_nav_len(ctx, rally, enat), _nav_len(ctx, rally, erich), _nav_len(ctx, rally, edoor)])
	f["def_exposure_grid"] = _mean_ok([_grid_to(ctx, e, nat), _grid_to(ctx, e, rich)])
	f["crown_nav"] = _nav_len(ctx, door, lv.bot_mark(t, &"crown"))
	var camps: Array[float] = []
	for s: Dictionary in (ctx["lay"] as MapLayout).spots_of("camp"):
		camps.append(_grid_to(ctx, t, s["pos"]))
	camps.sort()
	f["camps_grid"] = _mean_ok(camps.slice(0, 3)) if not camps.is_empty() else 0.0
	var vis := INF
	for s: Dictionary in (ctx["lay"] as MapLayout).spots_of("point"):
		var sub := String(s.get("sub", ""))
		if sub == "watchtower" or sub == "" or sub == "tower":
			vis = minf(vis, _grid_to(ctx, t, s["pos"]))
	f["vision_grid"] = vis if vis < INF else 0.0
	var slots: Array[float] = []
	for row: Dictionary in COMMANDER.ROWS:
		var p: Vector3 = row["pos"]
		if p != Vector3.INF:
			slots.append(_grid_to(ctx, t, lv.bot_point(t, p)))
	slots.append(_grid_to(ctx, t, lv.market_slot(t)))
	slots.append(_grid_to(ctx, t, lv.tower_slot(t, &"natural")))
	slots.append(_grid_to(ctx, t, lv.tower_slot(t, &"rich")))
	f["slots_grid"] = _mean_ok(slots)
	var marks: Array[float] = []
	for key: StringName in [&"rally", &"anchor", &"hub"]:
		var m: Vector3 = lv.bot_mark(t, key)
		if m != Vector3.INF:
			marks.append(_grid_to(ctx, t, m))
	f["marks_grid"] = _mean_ok(marks) if not marks.is_empty() else 0.0
	# navmesh detour: what units walk vs the geometric shortest path, over the economy targets
	var ratios: Array[float] = []
	for p: Vector3 in [na, nb, nat, rich, nmid]:
		var g := _grid_to(ctx, t, p)
		var n := _nav_len(ctx, door, p)
		if g != INF and n != INF and g > 5.0:
			ratios.append(n / g)
	f["nav_detour"] = _mean_ok(ratios) if not ratios.is_empty() else 1.0
	# the mining trip itself: node -> the keep's rim (where workers drop off), navmesh walk
	f["eco_trip_nav"] = _mean_ok([_trip(ctx, t, na), _trip(ctx, t, nb)])
	f["raw_unreachable"] = int(ctx["unreach"])
	return f


## The mining trip: from the node's approach point (1.5 m out of the node, toward the keep) to the keep's rim facing
## the node (half the footprint + 0.75 m from its centre), navmesh walk. Both ends are mirror-invariant.
static func _trip(ctx: Dictionary, t: int, node: Vector3) -> float:
	if node == Vector3.INF:
		return NAN
	var lv: Node = ctx["level"]
	var kc: Vector3 = lv.base_center(t)
	var d := Vector3(node.x - kc.x, 0.0, node.z - kc.z)
	if d.length() < 1.0:
		return NAN
	var u := d.normalized()
	var keep: Dictionary = (ctx["lay"] as MapLayout).keep_of(int((lv.get(&"seat_of_team") as Dictionary).get(t, {}).get("team", t)))
	var fp := float((keep.get("props", {}) as Dictionary).get("footprint", 6.0))
	return _nav_len(ctx, node - u * 1.5, kc + u * (fp * 0.5 + 0.75))


static func _mean_ok(v: Array) -> float:
	var s := 0.0
	var n := 0
	for x: float in v:
		if is_finite(x):
			s += x
			n += 1
	return s / n if n > 0 else NAN


## NavigationServer path length between two points (xz), INF when no path reaches within 1.5 m of the end.
static func _nav_len(ctx: Dictionary, a: Vector3, b: Vector3) -> float:
	if a == Vector3.INF or b == Vector3.INF:
		return NAN   # the target does not exist on this map (no third, no rally...)
	var nav: RID = ctx["nav"]
	var pa := NavigationServer3D.map_get_closest_point(nav, a)
	var pb := NavigationServer3D.map_get_closest_point(nav, b)
	var path := NavigationServer3D.map_get_path(nav, pa, pb, true)
	if path.is_empty():
		ctx["unreach"] = int(ctx.get("unreach", 0)) + 1
		return INF
	var l := 0.0
	for i in range(1, path.size()):
		l += Vector2(path[i].x - path[i - 1].x, path[i].z - path[i - 1].z).length()
	var last := path[path.size() - 1]
	if Vector2(last.x - pb.x, last.z - pb.z).length() > 1.5:
		ctx["unreach"] = int(ctx.get("unreach", 0)) + 1
		return INF
	return l


## Geometric shortest path (Map Lab coarse grid, octile Dijkstra) from seat t's keep door to p (INF = unreachable).
static func _grid_to(ctx: Dictionary, t: int, p: Vector3) -> float:
	if p == Vector3.INF:
		return NAN   # the target does not exist on this map
	var dist := _dist_of(ctx, t)
	var grid: RefCounted = ctx["grid"]
	var best := INF
	var q: Vector3 = grid.nearest_main(p.x, p.z, 12.0)
	if q == Vector3.INF:
		ctx["unreach"] = int(ctx.get("unreach", 0)) + 1
		return INF
	var rad := Vector2(q.x - p.x, q.z - p.z).length() + 1.0
	var step: float = 2.0 * MapGrid.CELL
	var k := int(ceil(rad / step)) + 1
	for dj in range(-k, k + 1):
		for di in range(-k, k + 1):
			var x := p.x + di * step
			var z := p.z + dj * step
			if Vector2(x - p.x, z - p.z).length() > rad:
				continue
			var ci: int = grid.coarse_index(x, z)
			if ci >= 0 and grid.coarse[ci] == 1 and dist[ci] < best:
				best = dist[ci]
	if best == INF:
		ctx["unreach"] = int(ctx.get("unreach", 0)) + 1
	return best


static func _dist_of(ctx: Dictionary, t: int) -> PackedFloat32Array:
	var cache: Dictionary = ctx["dist"]
	if cache.has(t):
		return cache[t]
	var grid: RefCounted = ctx["grid"]
	var door: Vector3 = (ctx["level"] as Node).start_position(t)
	# sources: every walkable coarse cell within 1 m of the door's nearest navmesh point (a mirror-invariant set; a
	# single nearest cell breaks ties differently on the two seats)
	var srcs := PackedInt32Array()
	var q: Vector3 = grid.nearest_main(door.x, door.z, 12.0)
	if q != Vector3.INF:
		var rad := Vector2(q.x - door.x, q.z - door.z).length() + 1.0
		var step: float = 2.0 * MapGrid.CELL
		var k := int(ceil(rad / step)) + 1
		for dj in range(-k, k + 1):
			for di in range(-k, k + 1):
				var x := door.x + di * step
				var z := door.z + dj * step
				var ci: int = grid.coarse_index(x, z)
				if ci >= 0 and grid.coarse[ci] == 1 and Vector2(x - door.x, z - door.z).length() <= rad and not srcs.has(ci):
					srcs.append(ci)
	var d: PackedFloat32Array = grid.dijkstra(srcs)
	cache[t] = d
	return d


## Chokes along the navmesh route keep 0 -> keep 1: widths across the path every 2 m. Returns {count, home: [n0, n1]
## (chokes in each seat's half), pocket: [w0, w1] (narrowest width in each seat's first POCKET_LEN m), min_width}.
static func _route_chokes(ctx: Dictionary) -> Dictionary:
	var lv: Node = ctx["level"]
	var nav: RID = ctx["nav"]
	var grid: RefCounted = ctx["grid"]
	var a: Vector3 = lv.start_position(0)
	var b: Vector3 = lv.start_position(1)
	var path := NavigationServer3D.map_get_path(nav, NavigationServer3D.map_get_closest_point(nav, a),
			NavigationServer3D.map_get_closest_point(nav, b), true)
	var out := {"count": 0, "home": [0, 0], "pocket": [INF, INF], "min_width": INF}
	if path.size() < 2:
		return out
	var total := 0.0
	for i in range(1, path.size()):
		total += Vector2(path[i].x - path[i - 1].x, path[i].z - path[i - 1].z).length()
	var s := 0.0
	var in_choke := false
	for i in range(1, path.size()):
		var p0 := Vector2(path[i - 1].x, path[i - 1].z)
		var p1 := Vector2(path[i].x, path[i].z)
		var seg := p0.distance_to(p1)
		if seg < 0.01:
			continue
		var dir := (p1 - p0) / seg
		var across := Vector2(-dir.y, dir.x)
		var u := 0.0
		while u < seg:
			var p := p0 + dir * u
			var at := s + u
			u += 2.0
			if at < 6.0 or at > total - 6.0:
				continue
			var w: float = float(grid.width_at(p, across, 20.0)["width"])
			out["min_width"] = minf(float(out["min_width"]), w)
			if at <= POCKET_LEN:
				out["pocket"][0] = minf(float(out["pocket"][0]), w)
			if at >= total - POCKET_LEN:
				out["pocket"][1] = minf(float(out["pocket"][1]), w)
			var narrow := w < CHOKE_W
			if narrow and not in_choke:
				out["count"] = int(out["count"]) + 1
				out["home"][0 if at < total * 0.5 else 1] += 1
			in_choke = narrow
		s += seg
	return out


## Mean distance (m) between seat 1's Commander slots / marks and seat 0's seen through the layout's symmetry
## (seat frames): 0 on an exactly symmetric map.
static func _slot_sym_err(ctx: Dictionary) -> float:
	var lv: Node = ctx["level"]
	var f0: Transform3D = lv.call(&"_seat_frame", 0)
	var f1: Transform3D = lv.call(&"_seat_frame", 1)
	var m := f1 * f0.affine_inverse()
	var pts: Array = []
	for row: Dictionary in COMMANDER.ROWS:
		var p: Vector3 = row["pos"]
		if p != Vector3.INF:
			pts.append([lv.bot_point(0, p), lv.bot_point(1, p)])
	for key: StringName in [&"rally", &"anchor", &"hub", &"natural", &"rich"]:
		pts.append([lv.bot_mark(0, key), lv.bot_mark(1, key)])
	var s := 0.0
	var n := 0
	for pr: Array in pts:
		var p0: Vector3 = pr[0]
		var p1: Vector3 = pr[1]
		if p0 == Vector3.INF or p1 == Vector3.INF:
			continue
		var img := m * p0
		s += Vector2(img.x - p1.x, img.z - p1.z).length()
		n += 1
	return s / n if n > 0 else 0.0

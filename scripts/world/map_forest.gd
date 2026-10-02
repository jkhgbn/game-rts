class_name MapForest
extends RefCounted
## The tree / rock / pillar generator of main.gd and skirmish.gd moved into data (map-production.md 2.2 `forest`, tool
## task MT2): `plan(layout, river)` turns a MapLayout's `forest` / `grove` / `willows` statements into placements, with
## the same random draws as Crown Hollow's `_build_map` (seed 7 forest, seed 13 Old Wood, seed 17 willows), so
## `crown_hollow_level.map` rebuilds the live forest tree for tree. Pure data: LayoutLevel adds colliders + art from
## the result, the World Forge preview adds colliders only.
##
## Draw order (identical to skirmish.gd): forest rng: per cluster a centre in +-spread, a count in `trees`, per tree a
## point within cluster_r; points outside the canonical region, in a `pre` clearing or the lane are dropped BEFORE
## the size draw; then the size; then the post checks (spot clearings, road corridors, river / crossing corridors,
## point / camp / prop clearings + the obstacle radius). Rocks: points folded into the canonical region, the same two
## tiers. Groves (own rng), willows (own rng), then the pillar ring heights (forest rng). Every kept placement is
## copied to each symmetry image (rot180: p then -p).

const TREE_R := 0.45          ## Tree collider radius x size (main.gd _add_tree).
const ROCK_R := 0.8           ## Rock footprint reach x size (1.6 x 1.3 box).
const LANE_HALF := 5.0        ## main.gd _in_path_lane.
const RIVER_CORRIDOR := 1.2   ## skirmish.gd: no collider this close to deep water...
const CROSSING_CORRIDOR := 2.0   ## ...or to a crossing.
const START_CLEAR := 18.0     ## skirmish.gd: the start clearing.
const START_OFFSET := 9.9     ## The wizard start: 9.9 m from the keep toward the map centre (Crown Hollow: KEEP_OFFSET).
const GROVE_BORDER := 2.5     ## Groves and willows stay this far inside the map edge.
const GROVE_GAP := 1.4
const WILLOW_TREE_GAP := 1.5
## Post-tier clearing radius per spot kind (Crown Hollow's item / trade / map-fill clearings). `clear=` on a spot wins.
const CLEAR := {"node": 7.0, "crown": 12.0, "peddler": 5.0, "cache": 3.0, "tavern": 6.0, "post": 5.0, "guild": 6.0,
	"camp": 3.5, "slot": 4.0, "keep": 0.0, "lair": 0.0, "start": 0.0}
const POINT_CLEAR := {"watchtower": 4.0, "well": 3.5, "shrine": 3.0}
## Kinds whose clearing also keeps the obstacle's own radius out (skirmish.gd _in_map_fill_corridor).
const EXTRA_KINDS: Array[String] = ["point", "camp"]
## pre=auto (maps without an explicit list): start 18, crown 12, every crystal node 7, slots 4.
const PRE_AUTO := {"crown": 12.0, "node": 7.0}

const HALF_TURN := Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3.ZERO)
const MIRROR_X := Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)), Vector3.ZERO)
const MIRROR_Z := Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3.ZERO)


## The symmetry images, identity first (rot180: [I, half turn]; fourfold: [I, mirror z, half turn, mirror x]).
static func images(symmetry: String) -> Array[Transform3D]:
	match symmetry:
		"rot180":
			return [Transform3D.IDENTITY, HALF_TURN]
		"mirror_x":
			return [Transform3D.IDENTITY, MIRROR_X]
		"mirror_z":
			return [Transform3D.IDENTITY, MIRROR_Z]
		"fourfold":
			return [Transform3D.IDENTITY, MIRROR_Z, HALF_TURN, MIRROR_X]
	return [Transform3D.IDENTITY]


static func frame_of(frame_name: String) -> Transform3D:
	match frame_name:
		"rot180":
			return HALF_TURN
		"mirror_x":
			return MIRROR_X
		"mirror_z":
			return MIRROR_Z
	return Transform3D.IDENTITY


## True when p lies in the canonical region the draws keep ("xz": x + z < 0, Crown Hollow; "x": x < 0; "z": z > 0;
## "quad": x < 0 and z > 0; "all").
static func in_canon(p: Vector3, half: String) -> bool:
	match half:
		"xz":
			return p.x + p.z < 0.0
		"x":
			return p.x < 0.0
		"z":
			return p.z > 0.0
		"quad":
			return p.x < 0.0 and p.z > 0.0
	return true


## The wizard start of a keep spot: the layout's `start` spot of the same image, else 9.9 m toward the map centre.
static func start_of(layout: MapLayout, keep_spot: Dictionary) -> Vector3:
	for s in layout.spots_of("start"):
		if String(s.get("image", "identity")) == String(keep_spot.get("image", "identity")) or int(s.get("team", -2)) == int(keep_spot.get("team", -1)):
			return s["pos"]
	var k: Vector3 = keep_spot["pos"]
	var d := Vector2(-k.x, -k.z)
	if d.length() < 0.01:
		return k
	d = d.normalized() * START_OFFSET
	return Vector3(k.x + d.x, 0.0, k.z + d.y)


## Placements: {trees: [{pos, s, kind ("tree" / "willow"), yaw}], rocks: [{pos, s, rot}], pillars: [{pos, h}],
## hash: String}. `river`: a set-up RiverSystem (distance_to_water / distance_to_crossing) or null.
static func plan(layout: MapLayout, river: Object) -> Dictionary:
	var out := {"trees": [], "rocks": [], "pillars": [], "hash": ""}
	var f := layout.forest
	if f.is_empty() or not f.has("seed"):
		return out
	var imgs := images(layout.symmetry)
	var half := String(f.get("half", "all"))
	var hx := layout.size_x * 0.5
	var hz := layout.size_z * 0.5
	# clearings
	var pre: Array = []      # [Vector3, r] checked before the size draw
	var post: Array = []     # [Vector3, r] plain
	var post_x: Array = []   # [Vector3, r] + the obstacle radius (points, camps, props)
	for c: Array in f.get("pre", []):
		for xf in imgs:
			pre.append([xf * (c[0] as Vector3), float(c[1])])
	var starts: Array[Vector3] = []
	for k in layout.spots_of("keep"):
		if layout.closed_seats.has(int(k["team"])):
			continue
		starts.append(start_of(layout, k))
	if bool(f.get("pre_auto", false)):
		for st in starts:
			pre.append([st, START_CLEAR])
		for s in layout.spots:
			var r := float(PRE_AUTO.get(String(s["kind"]), 0.0))
			if String(s["kind"]) == "slot" and String(s.get("sub", "")) in ["house", "natural_hall", "rich_hall"]:
				r = 4.0
			if r > 0.0:
				pre.append([s["pos"], r])
	if String(f.get("clear", "auto")) != "none":
		for s in layout.spots:
			var kind := String(s["kind"])
			var props: Dictionary = s.get("props", {})
			var r := float(CLEAR.get(kind, 0.0))
			if kind == "point":
				r = float(POINT_CLEAR.get(point_kind(s), 3.0))
			if props.has("clear"):
				r = float(props["clear"])
			if r <= 0.0:
				continue
			if EXTRA_KINDS.has(kind):
				post_x.append([s["pos"], r])
			else:
				post.append([s["pos"], r])
		for p in layout.props:
			if float(p.get("clear", 0.0)) > 0.0:
				post_x.append([p["pos"], float(p["clear"])])
	var lane: Array = []   # [a, b] Vector2 segments
	var lp: PackedVector3Array = f.get("lane", PackedVector3Array())
	if lp.size() >= 2:
		for i in lp.size() - 1:
			lane.append([Vector2(lp[i].x, lp[i].z), Vector2(lp[i + 1].x, lp[i + 1].z)])
	elif starts.size() >= 2 and bool(f.get("pre_auto", false)):
		lane.append([Vector2(starts[0].x, starts[0].z), Vector2(starts[starts.size() - 1].x, starts[starts.size() - 1].z)])
	var roads: Array = []   # [a, b, half width]
	for r in layout.roads:
		var poly: PackedVector3Array = r["poly"]
		for i in poly.size() - 1:
			roads.append([Vector2(poly[i].x, poly[i].z), Vector2(poly[i + 1].x, poly[i + 1].z), float(r.get("width", 5.0)) * 0.5])
	var blocks: Array = layout.blocks
	var ctx := {"pre": pre, "post": post, "post_x": post_x, "lane": lane, "roads": roads, "river": river, "blocks": blocks}
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f["seed"])
	var tree_spots: Array[Vector3] = []
	var trees: Array = out["trees"]
	var rocks: Array = out["rocks"]
	# trees
	var spread := float(f.get("spread", 50.0))
	var cr := float(f.get("cluster_r", 6.0))
	var tcount: Vector2 = f.get("trees", Vector2(5, 9))
	var tsize: Vector2 = f.get("tree_size", Vector2(0.8, 1.3))
	for cluster in int(f.get("clusters", 9)):
		var center := Vector3(rng.randf_range(-spread, spread), 0.0, rng.randf_range(-spread, spread))
		for i in rng.randi_range(int(tcount.x), int(tcount.y)):
			var p := center + Vector3(rng.randf_range(-cr, cr), 0.0, rng.randf_range(-cr, cr))
			if not in_canon(p, half) or _in(p, pre) or _in_lane(p, lane):
				continue
			var s := rng.randf_range(tsize.x, tsize.y)
			if _post_blocked(p, TREE_R * s, ctx):
				continue
			if absf(p.x) > hx or absf(p.z) > hz:
				continue
			for xf in imgs:
				var q := xf * p
				trees.append({"pos": q, "s": s, "kind": "tree", "yaw": INF, "stage": "forest"})
				tree_spots.append(q)
	# rocks
	var rs := float(f.get("rock_spread", 54.0))
	var rsize: Vector2 = f.get("rock_size", Vector2(0.8, 2.2))
	for i in int(f.get("rocks", 11)):
		var p := Vector3(rng.randf_range(-rs, rs), 0.0, rng.randf_range(-rs, rs))
		if not in_canon(p, half):
			for xf in imgs:
				if in_canon(xf * p, half):
					p = xf * p
					break
		if _in(p, pre) or _in_lane(p, lane):
			continue
		var s := rng.randf_range(rsize.x, rsize.y)
		var rot := rng.randf() * TAU
		if _post_blocked(p, ROCK_R * s, ctx):
			continue
		if absf(p.x) > hx - 1.0 or absf(p.z) > hz - 1.0:
			continue
		for xf in imgs:
			rocks.append({"pos": xf * p, "s": s, "rot": _image_yaw(rot, xf)})
	# groves (Old Wood, own rng)
	if not layout.groves.is_empty():
		var grng := RandomNumberGenerator.new()
		grng.seed = int(f.get("grove_seed", 13))
		for g in layout.groves:
			var gc: Vector3 = g["center"]
			for i in int(g["trees"]):
				var a := grng.randf() * TAU
				var r := sqrt(grng.randf()) * float(g["r"])
				var s := grng.randf_range(0.8, 1.3)
				var p := gc + Vector3(cos(a) * r, 0.0, sin(a) * r)
				if absf(p.x) > hx - GROVE_BORDER or absf(p.z) > hz - GROVE_BORDER or _blocked(p, TREE_R * s, ctx):
					continue
				if _near_any(p, tree_spots, GROVE_GAP):
					continue
				for xf in imgs:
					var q := xf * p
					trees.append({"pos": q, "s": s, "kind": "tree", "yaw": INF, "stage": "grove"})
					tree_spots.append(q)
	# willows (own rng)
	if f.has("willows") and not layout.river.is_empty():
		_willows(layout, f["willows"], ctx, imgs, half, tree_spots, trees)
	# the pillar ring (forest rng, after the rocks)
	var pv: Variant = f.get("pillars", null)
	if pv is Vector3:
		_pillars(layout, pv, f, rng, imgs, out["pillars"])
	var h := ""
	for t: Dictionary in trees:
		h += "t%.3f,%.3f,%.3f;" % [t["pos"].x, t["pos"].z, t["s"]]
	for r: Dictionary in rocks:
		h += "r%.3f,%.3f,%.3f;" % [r["pos"].x, r["pos"].z, r["s"]]
	for pl: Dictionary in out["pillars"]:
		h += "p%.3f,%.3f,%.3f;" % [pl["pos"].x, pl["pos"].z, pl["h"]]
	out["hash"] = h.md5_text().substr(0, 12)
	return out


## Capture point kind of a `point` spot: its `sub`, else from the id (tower / well / shrine).
static func point_kind(s: Dictionary) -> String:
	var sub := String(s.get("sub", ""))
	if sub != "":
		return sub
	var id := String(s.get("twin_of", s["id"]))
	if id.begins_with("well") or id.contains("_well"):
		return "well"
	if id.begins_with("shrine") or id.contains("_shrine"):
		return "shrine"
	return "watchtower"


static func _image_yaw(rot: float, xf: Transform3D) -> float:
	if xf == HALF_TURN:
		return rot + PI
	if xf == MIRROR_X or xf == MIRROR_Z:
		return -rot
	return rot


static func _in(p: Vector3, circles: Array) -> bool:
	for c: Array in circles:
		if p.distance_to(c[0]) < float(c[1]):
			return true
	return false


static func _in_lane(p: Vector3, lane: Array) -> bool:
	var q := Vector2(p.x, p.z)
	for seg: Array in lane:
		if q.distance_to(Geometry2D.get_closest_point_to_segment(q, seg[0], seg[1])) < LANE_HALF:
			return true
	return false


## The post checks (after the size draw): spot clearings, road corridors, map-fill corridors (points / camps / props
## + `extra`, deep water + 1.2, crossings + 2.0), blocks.
static func _post_blocked(p: Vector3, extra: float, ctx: Dictionary) -> bool:
	if _in(p, ctx["post"]):
		return true
	var q := Vector2(p.x, p.z)
	for seg: Array in ctx["roads"]:
		if q.distance_to(Geometry2D.get_closest_point_to_segment(q, seg[0], seg[1])) < float(seg[2]) + extra:
			return true
	for c: Array in ctx["post_x"]:
		if Vector2(p.x - c[0].x, p.z - c[0].z).length() < float(c[1]) + extra:
			return true
	var river: Object = ctx["river"]
	if river != null:
		if float(river.call(&"distance_to_crossing", p)) < CROSSING_CORRIDOR + extra:
			return true
		if float(river.call(&"distance_to_water", p, RIVER_CORRIDOR + extra)) < RIVER_CORRIDOR + extra:
			return true
	for b: Dictionary in ctx["blocks"]:
		var local := Basis(Vector3.UP, deg_to_rad(float(b.get("yaw", 0.0)))).inverse() * (p - (b["center"] as Vector3))
		var hb: Vector3 = b["half"]
		if absf(local.x) < hb.x + extra and absf(local.z) < hb.z + extra:
			return true
	return false


## Groves / willows: every check at once (skirmish.gd `blocked`).
static func _blocked(p: Vector3, extra: float, ctx: Dictionary) -> bool:
	return _in(p, ctx["pre"]) or _in_lane(p, ctx["lane"]) or _post_blocked(p, extra, ctx)


static func _near_any(p: Vector3, spots: Array[Vector3], radius: float) -> bool:
	for q in spots:
		if Vector2(p.x - q.x, p.z - q.z).length() < radius:
			return true
	return false


## skirmish.gd _add_willows on the layout's river arm `w.arm` and its moat.
static func _willows(layout: MapLayout, w: Dictionary, ctx: Dictionary, imgs: Array[Transform3D], half: String,
		tree_spots: Array[Vector3], trees: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(w.get("seed", 17))
	var arm: Dictionary = layout.river[clampi(int(w.get("arm", 0)), 0, layout.river.size() - 1)]
	var line := PackedVector2Array()
	for p: Vector3 in (arm["poly"] as PackedVector3Array):
		line.append(Vector2(p.x, p.z))
	var hw := float(arm.get("half_width", 2.5))
	var total := 0.0
	for i in line.size() - 1:
		total += line[i].distance_to(line[i + 1])
	var moat := layout.moat
	var arc: Vector2 = w.get("arc", Vector2(140, 310))
	var gap_r: Vector2 = w.get("gap", Vector2(1.5, 4.0))
	var size_r: Vector2 = w.get("size", Vector2(0.95, 1.2))
	var hx := layout.size_x * 0.5
	var hz := layout.size_z * 0.5
	var river: Object = ctx["river"]
	var willows: Array[Vector3] = []
	for draw in int(w.get("draws", 40)):
		var s := rng.randf_range(size_r.x, size_r.y)
		var gap := rng.randf_range(gap_r.x, gap_r.y)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var t := rng.randf()
		var p := Vector3.ZERO
		var water := Vector2.ZERO
		if draw < int(w.get("river_draws", 30)) or moat.is_empty():
			var along := t * total
			for i in line.size() - 1:
				var l := line[i].distance_to(line[i + 1])
				if along <= l or i == line.size() - 2:
					var c := line[i].lerp(line[i + 1], clampf(along / l, 0.0, 1.0))
					var d := (line[i + 1] - line[i]).normalized()
					var q := c + Vector2(-d.y, d.x) * side * (hw + gap)
					p = Vector3(q.x, 0.0, q.y)
					water = c
					break
				along -= l
		else:
			var mc: Vector3 = moat["center"]
			var a := deg_to_rad(lerpf(arc.x, arc.y, t))
			var q := Vector2(mc.x, mc.z) + Vector2.from_angle(a) * (float(moat["radius"]) + float(moat["half_width"]) + gap)
			p = Vector3(q.x, 0.0, q.y)
			water = Vector2(mc.x, mc.z) + Vector2.from_angle(a) * float(moat["radius"])
		if not in_canon(p, half) or absf(p.x) > hx - GROVE_BORDER or absf(p.z) > hz - GROVE_BORDER:
			continue
		if _blocked(p, TREE_R * s, ctx) or _near_any(p, willows, float(w.get("spacing", 4.0))) or _near_any(p, tree_spots, WILLOW_TREE_GAP):
			continue
		if river != null and float(river.call(&"distance_to_crossing", p)) < float(w.get("crossing_gap", 3.5)) + TREE_R * s:
			continue
		var dir := Vector2(water.x - p.x, water.y - p.z)
		for xf in imgs:
			var q := xf * p
			var d3 := xf.basis * Vector3(dir.x, 0.0, dir.y)
			var yaw := atan2(-dir.y, dir.x)
			if xf != Transform3D.IDENTITY:
				yaw = (atan2(-dir.y, dir.x) + PI) if xf == HALF_TURN else atan2(-d3.z, d3.x)
			trees.append({"pos": q, "s": s, "kind": "willow", "yaw": yaw, "stage": "willow"})
			willows.append(q)
			tree_spots.append(q)


## The ruined pillar ring: rot180 = skirmish.gd (pillar i and i + count / 2 share a height, `pillar_gap` skipped);
## other symmetries: one height per orbit of `count` evenly spaced pillars.
static func _pillars(layout: MapLayout, pv: Vector3, f: Dictionary, rng: RandomNumberGenerator, imgs: Array[Transform3D],
		out: Array) -> void:
	var center := Vector3(pv.x, 0.0, pv.y)
	var ring := pv.z
	var n := maxi(2, int(f.get("pillar_count", 10)))
	var gap := int(f.get("pillar_gap", -1))
	var hr: Vector2 = f.get("pillar_h", Vector2(2.0, 4.5))
	if layout.symmetry == "rot180" or imgs.size() == 1:
		var halfn := n / 2 if layout.symmetry == "rot180" else n
		for i in halfn:
			var h := rng.randf_range(hr.x, hr.y)
			if i == gap:
				continue
			for k in ([i, i + halfn] if layout.symmetry == "rot180" else [i]):
				var a := float(k) * TAU / float(n)
				out.append({"pos": center + Vector3(cos(a) * ring, 0.0, sin(a) * ring), "h": h})
		return
	var done: Array[int] = []
	var orbit := 0
	for i in n:
		if done.has(i):
			continue
		var a := (float(i) + 0.5) * TAU / float(n)
		var p := center + Vector3(cos(a) * ring, 0.0, sin(a) * ring)
		var h := rng.randf_range(hr.x, hr.y)
		var members: Array[Vector3] = []
		for xf in imgs:
			var q := xf * p
			var dup := false
			for m in members:
				dup = dup or m.distance_to(q) < 0.05
			if not dup:
				members.append(q)
		for k in n:
			var ak := (float(k) + 0.5) * TAU / float(n)
			var pk := center + Vector3(cos(ak) * ring, 0.0, sin(ak) * ring)
			for m in members:
				if m.distance_to(pk) < 0.05:
					done.append(k)
		if orbit != gap:
			for m in members:
				out.append({"pos": m, "h": h})
		orbit += 1

extends RefCounted
## World Forge, map mode: `data/maps/<id>.map` (canonical quadrant + symmetry) -> `data/maps/<id>_layout.tres`
## (MapLayout) + a navmesh-baked preview level + the Map Lab run on it + layout.png; and `export-map`: the live spots of
## an existing map scene -> a `.map` spec (round trip). Grammar: tools/world_forge/README.md.
## No class_name on purpose (preloaded tool script).

const Spec := preload("res://tools/world_forge/forge_spec.gd")
const Report := preload("res://tools/world_forge/forge_report.gd")
const Img := preload("res://tools/world_forge/forge_set_checks.gd")
const MapLab := preload("res://tools/map_lab/map_lab.gd")
const Profiles := preload("res://tools/map_lab/map_profiles.gd")
const _SIM := preload("res://scripts/core/sim_mode.gd")
const MAPS_DIR := "res://data/maps"
const OUT_DIR := "res://docs/tools/world_forge/out"
const LEVEL_SCRIPT := "res://tools/world_forge/forge_map_level.gd"
const LIVE_SCENE := "res://scenes/layout_level.tscn"

const Grammar := preload("res://tools/world_forge/forge_map_grammar.gd")

const SPOT_KINDS: Array[String] = ["keep", "node", "point", "camp", "tavern", "post", "guild", "peddler", "cache", "lair", "crown", "start", "slot"]
const OTHER: Array[String] = ["map", "seat", "river", "moat", "crossing", "road", "zone", "block", "navmesh",
	# grammar v2 (map-production.md 2.2)
	"forest", "grove", "willows", "prop", "rules", "closed_seat", "bounds", "mark", "trigger", "path", "terrain", "hill",
	"ridge", "valley", "pad"]
const SYMS: Array[String] = ["none", "mirror_x", "mirror_z", "rot180", "fourfold"]
const FRAMES: Array[String] = ["identity", "mirror_x", "mirror_z", "rot180"]
const CROSS_KINDS: Array[String] = ["bridge_road", "bridge_lane", "ford", "steps"]
const BLOCK_KINDS: Array[String] = ["rock", "cliff", "wall", "ruin", "city", "forest", "ice"]
const SPOT_KEYS: Array[String] = ["at", "sub", "team", "twin", "footprint", "amount", "r", "tier", "name", "clear", "role",
	"first", "respawn", "kind", "radius", "door", "sign", "yaw", "count"]
const DEDUPE := 0.05
## Map Lab acceptance score (JS 2026-10-02, map-production.md 9: was 90).
const LAB_MIN := 75.0

var spec := Spec.new()
var report := Report.new()
var layout: MapLayout
var map_id := ""
var level: Node3D
var holder: Node3D
var opts := {}
var t0 := 0
var export_ref: Array = []
var lab_score := -1.0        ## the last Map Lab run (map verb): score, result, FAIL checks, fixable moves
var lab_result := ""
var lab_fails := 0
var lab_fixes: Array = []
var l2_fixes: Array = []     ## L2 out-of-bounds spots moved inward (fix verb)
var _ready_frame := -1   ## round trip: the exported live spots [{id, kind, pos}]


static func frame_xf(nm: String) -> Transform3D:
	match nm:
		"mirror_x":
			return Profiles.MIRROR_X
		"mirror_z":
			return Profiles.MIRROR_Z
		"rot180":
			return Profiles.HALF_TURN
	return Transform3D.IDENTITY


static func images_of(sym: String) -> Array[String]:
	match sym:
		"mirror_x":
			return ["identity", "mirror_x"]
		"mirror_z":
			return ["identity", "mirror_z"]
		"rot180":
			return ["identity", "rot180"]
		"fourfold":
			return ["identity", "mirror_z", "rot180", "mirror_x"]
	return ["identity"]


static func suffix_of(sym: String, image: String) -> String:
	if sym == "fourfold":
		return {"identity": "_a1", "mirror_z": "_a2", "rot180": "_b1", "mirror_x": "_b2"}[image]
	return "" if image == "identity" else "_twin"


# ---------------------------------------------------------------- compile

func compile(path: String) -> bool:
	layout = MapLayout.new()
	layout.source = path
	var gram := Grammar.new(spec)
	var sts := gram.expand(path)
	if sts.is_empty() and not spec.ok():
		return false
	layout.source_hash = gram.hash_text()
	layout.templates_used.assign(gram.templates_used)
	var canon: Array = []   # spot statements
	var seat_frames := {}   # frame name -> seat dict
	for st: Dictionary in sts:
		var kw: String = st["kw"]
		if SPOT_KINDS.has(kw):
			canon.append(st)
			continue
		if not OTHER.has(kw):
			spec.err(st.get("via", st["line"]), kw, "unknown statement \"%s\"" % kw, SPOT_KINDS + OTHER + ["use", "remove", "move"])
			continue
		match kw:
			"map":
				spec.check_keys(st, ["size", "symmetry", "title", "spec", "biome", "base", "variant", "light"])
				if st["args"].is_empty():
					spec.err(st["line"], "map", "map wants an id: map <id> size=168 symmetry=fourfold")
					continue
				layout.id = StringName(st["args"][0])
				var sz := _size_of(st)
				layout.size_x = sz.x
				layout.size_z = sz.y
				layout.size = maxf(sz.x, sz.y)
				layout.symmetry = String(st["kv"].get("symmetry", "none"))
				if not SYMS.has(layout.symmetry):
					spec.err(st["line"], layout.symmetry, "unknown symmetry", SYMS)
					layout.symmetry = "none"
				layout.title = String(st["kv"].get("title", String(layout.id)))
				layout.biome = String(st["kv"].get("biome", ""))
				layout.light = String(st["kv"].get("light", ""))
				layout.base = String(st["kv"].get("base", ""))
				layout.variant = String(st["kv"].get("variant", ""))
				opts["spec_doc"] = String(st["kv"].get("spec", "-"))
			"seat":
				spec.check_keys(st, ["name", "side", "frame"])
				if st["args"].is_empty() or not String(st["args"][0]).is_valid_int():
					spec.err(st["line"], "seat", "seat wants a team number: seat 0 name=\"player\" side=0 frame=identity")
					continue
				var fr := String(st["kv"].get("frame", "identity"))
				if not FRAMES.has(fr):
					spec.err(st["line"], fr, "unknown frame", FRAMES)
					continue
				var seat := {"team": int(st["args"][0]), "name": String(st["kv"].get("name", "seat %s" % st["args"][0])),
					"side": int(spec.num(st, "side", 0)), "frame": frame_xf(fr), "frame_name": fr}
				layout.seats.append(seat)
				seat_frames[fr] = seat
				if (st["args"] as Array).has("scripted"):
					layout.scripted_seats.append(int(st["args"][0]))
			"closed_seat":
				spec.check_keys(st, ["becomes"])
				if st["args"].is_empty() or not String(st["args"][0]).is_valid_int():
					spec.err(st["line"], "closed_seat", "closed_seat wants a team number: closed_seat 4 becomes=neutral")
					continue
				layout.closed_seats.append(int(st["args"][0]))
			"forest", "willows":
				_c_forest(st)
			"grove":
				spec.check_keys(st, ["at", "r", "trees"])
				var gat: Variant = spec.vec(st, "at")
				if gat == null:
					spec.err(st["line"], "grove", "grove wants at=(x,z) r=4 trees=7")
					continue
				layout.groves.append({"id": st["args"][0] if not st["args"].is_empty() else "grove%d" % layout.groves.size(),
					"center": gat, "r": spec.num(st, "r", 4.0), "trees": int(spec.num(st, "trees", 6.0))})
			"rules":
				_c_rules(st)
			"bounds":
				var ba: Variant = Spec.parse_area(st["args"][0] if not st["args"].is_empty() else "")
				if ba == null or String(ba["kind"]) != "rect":
					spec.err(st["line"], "bounds", "bounds wants rect((x0,z0),(x1,z1))")
					continue
				layout.bounds = Rect2(ba["min"].x, ba["min"].z, ba["max"].x - ba["min"].x, ba["max"].z - ba["min"].z)
			"mark":
				spec.check_keys(st, ["at"])
				var mat: Variant = spec.vec(st, "at")
				if mat == null or st["args"].is_empty():
					spec.err(st["line"], "mark", "mark wants: mark <id> at=(x,z)")
					continue
				layout.marks[String(st["args"][0])] = mat
			"trigger":
				var ta: Variant = Spec.parse_area(st["args"][1] if st["args"].size() > 1 else "")
				if ta == null:
					spec.err(st["line"], "trigger", "trigger wants: trigger <id> circle((x,z),r) | ring(...) | rect(...)")
					continue
				layout.triggers[String(st["args"][0])] = ta
			"path":
				spec.check_keys(st, ["poly"])
				var pp: Variant = Spec.parse_poly(st["kv"].get("poly", ""))
				if pp == null or st["args"].is_empty():
					spec.err(st["line"], "path", "path wants: path <id> poly=[(x,z),...]")
					continue
				layout.paths[String(st["args"][0])] = pp
			"terrain", "hill", "ridge", "valley", "pad":
				var op := {"op": kw, "id": st["args"][0] if not st["args"].is_empty() else kw}
				for k: String in st["kv"]:
					var v: Variant = Spec.parse_vec(st["kv"][k])
					if v == null:
						v = Spec.parse_poly(st["kv"][k])
					op[k] = v if v != null else (st["kv"][k].to_float() if String(st["kv"][k]).is_valid_float() else st["kv"][k])
				layout.terrain.append(op)
			"river":
				spec.check_keys(st, ["poly", "half_width"])
				var poly: Variant = Spec.parse_poly(st["kv"].get("poly", ""))
				if poly == null:
					spec.err(st["line"], st["kv"].get("poly", "poly"), "river wants poly=[(x,z),...]")
					continue
				layout.river.append({"id": st["args"][0] if not st["args"].is_empty() else "river", "poly": poly,
					"half_width": spec.num(st, "half_width", 2.5)})
			"moat":
				spec.check_keys(st, ["center", "radius", "half_width"])
				layout.moat = {"center": spec.vec(st, "center", Vector3.ZERO), "radius": spec.num(st, "radius", 12.0),
					"half_width": spec.num(st, "half_width", 1.75)}
			"crossing":
				spec.check_keys(st, ["kind", "at", "width", "length", "dir", "name"])
				var ck := String(st["kv"].get("kind", "ford"))
				if not CROSS_KINDS.has(ck):
					spec.err(st["line"], ck, "unknown crossing kind", CROSS_KINDS)
				var at: Variant = spec.vec(st, "at")
				if at == null or st["args"].is_empty():
					spec.err(st["line"], "crossing", "crossing wants: crossing <id> kind=ford at=(x,z) width=7")
					continue
				var c := {"id": st["args"][0], "name": String(st["kv"].get("name", st["args"][0])), "kind": ck, "center": at,
					"width": spec.num(st, "width", 6.0), "length": spec.num(st, "length", spec.num(st, "width", 6.0)),
					"dir": spec.vec(st, "dir", Vector3.FORWARD)}
				if ck == "ford" or ck == "steps":
					c["radius"] = float(c["width"]) * 0.5
				layout.crossings.append(c)
			"navmesh":
				spec.check_keys(st, ["origin"])
				var np: String = st["args"][0] if not st["args"].is_empty() else ""
				if not ResourceLoader.exists(np):
					spec.err(st["line"], np, "navmesh wants an existing res:// NavigationMesh (export-map writes one)")
					continue
				layout.navmeshes.append({"path": np, "xf": Transform3D(Basis(), spec.vec(st, "origin", Vector3.ZERO))})
			"road", "zone", "block", "prop":
				_c_mirrored(st)
	# spots, mirrored
	var imgs := images_of(layout.symmetry)
	for st: Dictionary in canon:
		var kind: String = st["kw"]
		spec.check_keys(st, SPOT_KEYS)
		if st["args"].is_empty():
			spec.err(st["line"], kind, "%s wants an id: %s <id> at=(x,z)" % [kind, kind])
			continue
		var sid: String = st["args"][0]
		var solo: bool = st["args"].has("solo")
		var at: Variant = spec.vec(st, "at")
		if at == null:
			spec.err(st["line"], sid, "%s %s wants at=(x,z)" % [kind, sid])
			continue
		var props := {}
		for k: String in st["kv"]:
			if not k in ["at", "sub", "team", "twin"]:
				props[k] = st["kv"][k].to_float() if String(st["kv"][k]).is_valid_float() else st["kv"][k]
		var placed: Array[Vector3] = []
		for fr in (["identity"] if solo else imgs):
			var p: Vector3 = frame_xf(fr) * (at as Vector3)
			p.y = 0.0
			var dup := false
			for q in placed:
				if q.distance_to(p) < DEDUPE:
					dup = true
			if dup:
				continue
			placed.append(p)
			var this_id := sid
			if fr != "identity":
				this_id = String(st["kv"]["twin"]) if st["kv"].has("twin") and layout.symmetry != "fourfold" else sid + suffix_of(layout.symmetry, fr)
			elif layout.symmetry == "fourfold" and not solo and imgs.size() > 1:
				# a spot on an axis keeps one name per distinct image
				this_id = sid + suffix_of(layout.symmetry, fr)
			var team := -1
			if st["kv"].has("team"):
				team = int(st["kv"]["team"])
			if kind == "keep" or kind == "start":
				if solo:
					team = int(st["kv"].get("team", "0"))
				elif seat_frames.has(fr):
					team = int(seat_frames[fr]["team"])
				elif fr == "identity" and not st["kv"].has("team"):
					team = 0
			var props_i := props
			if st["kv"].has("door"):   # a door is a point: it follows the image
				var dv: Variant = Spec.parse_vec(st["kv"]["door"])
				if dv != null:
					props_i = props.duplicate()
					props_i["door"] = frame_xf(fr) * (dv as Vector3)
			layout.spots.append({"id": this_id, "kind": kind, "sub": String(st["kv"].get("sub", "")), "pos": p, "team": team,
				"twin_of": sid, "props": props_i, "line": st["line"], "image": fr})
	if String(layout.id) == "":
		spec.err(1, "map", "the spec needs `map <id> size=<m> symmetry=<none|mirror_x|mirror_z|rot180|fourfold>`")
	for t in layout.closed_seats:
		var found := false
		for s in layout.seats:
			found = found or int(s["team"]) == t
		if not found:
			spec.err(1, "closed_seat", "closed_seat %d: no `seat %d` line" % [t, t])
	return spec.ok()


## `size=120` (square) or `size=150x120` (W x D) -> Vector2(width, depth).
func _size_of(st: Dictionary) -> Vector2:
	var s := String(st["kv"].get("size", "120")).to_lower()
	if s.contains("x"):
		var p := s.split("x")
		if p.size() == 2 and p[0].is_valid_float() and p[1].is_valid_float():
			return Vector2(p[0].to_float(), p[1].to_float())
		spec.err(st["line"], s, "size= wants metres: size=120 or size=150x120")
		return Vector2(120, 120)
	if not s.is_valid_float():
		spec.err(st["line"], s, "size= wants metres: size=120 or size=150x120")
		return Vector2(120, 120)
	return Vector2(s.to_float(), s.to_float())


## `forest` (the main.gd / skirmish.gd generator as data) and `willows` (river-bank trees): layout.forest.
func _c_forest(st: Dictionary) -> void:
	if st["kw"] == "willows":
		spec.check_keys(st, ["seed", "draws", "river_draws", "arc", "spacing", "gap", "crossing_gap", "arm", "size"])
		layout.forest["willows"] = {"seed": int(spec.num(st, "seed", 17.0)), "draws": int(spec.num(st, "draws", 40.0)),
			"river_draws": int(spec.num(st, "river_draws", 30.0)), "arc": spec.rng(st, "arc", Vector2(140, 310)),
			"spacing": spec.num(st, "spacing", 4.0), "gap": spec.rng(st, "gap", Vector2(1.5, 4.0)),
			"crossing_gap": spec.num(st, "crossing_gap", 3.5), "arm": int(spec.num(st, "arm", 0.0)),
			"size": spec.rng(st, "size", Vector2(0.95, 1.2))}
		return
	spec.check_keys(st, ["seed", "clusters", "trees", "spread", "cluster_r", "tree_size", "rocks", "rock_spread", "rock_size",
		"half", "pre", "lane", "clear", "pillars", "pillar_count", "pillar_gap", "pillar_h", "grove_seed", "kinds", "density"])
	var half_default: String = {"rot180": "xz", "mirror_x": "x", "mirror_z": "z", "fourfold": "quad"}.get(layout.symmetry, "all")
	var f := layout.forest
	var hx := layout.size_x * 0.5
	var density := spec.num(st, "density", 1.0)
	var area_k := layout.size_x * layout.size_z / 14400.0 * density
	f["seed"] = int(spec.num(st, "seed", 7.0))
	f["clusters"] = int(spec.num(st, "clusters", roundf(9.0 * area_k)))
	f["trees"] = spec.rng(st, "trees", Vector2(5, 9))
	f["spread"] = spec.num(st, "spread", minf(layout.size_x, layout.size_z) * 0.5 - 10.0)
	f["cluster_r"] = spec.num(st, "cluster_r", 6.0)
	f["tree_size"] = spec.rng(st, "tree_size", Vector2(0.8, 1.3))
	f["rocks"] = int(spec.num(st, "rocks", roundf(11.0 * area_k)))
	f["rock_spread"] = spec.num(st, "rock_spread", minf(layout.size_x, layout.size_z) * 0.5 - 6.0)
	f["rock_size"] = spec.rng(st, "rock_size", Vector2(0.8, 2.2))
	f["half"] = String(st["kv"].get("half", half_default))
	f["clear"] = String(st["kv"].get("clear", "auto"))
	f["kinds"] = String(st["kv"].get("kinds", ""))
	f["grove_seed"] = int(spec.num(st, "grove_seed", 13.0))
	var pre: Array = []
	if st["kv"].has("pre"):
		if String(st["kv"]["pre"]) == "auto":
			f["pre_auto"] = true
		else:
			var pp: Variant = Spec.parse_poly(st["kv"]["pre"])
			if pp == null:
				spec.err(st["line"], st["kv"]["pre"], "pre= wants [(x,z,r),...] (clearings checked before the tree size draw) or auto")
			else:
				for v: Vector3 in pp:
					pre.append([Vector3(v.x, 0.0, v.y), v.z])
	else:
		f["pre_auto"] = true
	f["pre"] = pre
	var lane: Variant = Spec.parse_poly(st["kv"].get("lane", "[]")) if st["kv"].has("lane") else PackedVector3Array()
	if lane == null:
		spec.err(st["line"], st["kv"]["lane"], "lane= wants [(x,z),(x,z)]")
		lane = PackedVector3Array()
	f["lane"] = lane
	f["pillars"] = null
	if st["kv"].has("pillars"):
		var pv: Variant = Spec.parse_vec(st["kv"]["pillars"])
		if pv == null:
			spec.err(st["line"], st["kv"]["pillars"], "pillars= wants (x,z,ring radius)")
		else:
			f["pillars"] = pv
	f["pillar_count"] = int(spec.num(st, "pillar_count", 10.0))
	f["pillar_gap"] = int(spec.num(st, "pillar_gap", -1.0))
	f["pillar_h"] = spec.rng(st, "pillar_h", Vector2(2.0, 4.5))
	if hx <= 0.0:
		return


## `rules archetype= tempo= <target>=a..b ... contest=5`: the Map Lab R1 / R3 targets.
func _c_rules(st: Dictionary) -> void:
	var targets := {}
	for k: String in st["kv"]:
		if k in ["archetype", "tempo", "contest", "players", "biome", "seed"]:
			continue
		var r: Variant = Spec.parse_range(String(st["kv"][k]))
		if r == null:
			spec.err(st["line"], String(st["kv"][k]), "rules %s= wants a band a..b (metres, or a ratio for enemy_ally)" % k)
			continue
		targets[k] = r
	layout.rules = {"archetype": String(st["kv"].get("archetype", "")), "tempo": String(st["kv"].get("tempo", "")),
		"targets": targets, "contest": spec.num(st, "contest", -1.0), "players": int(spec.num(st, "players", 0.0)),
		"seed": int(spec.num(st, "seed", -1.0))}


func _c_mirrored(st: Dictionary) -> void:
	var kw: String = st["kw"]
	var sid: String = st["args"][0] if not st["args"].is_empty() else kw
	var solo: bool = st["args"].has("solo")
	var imgs := ["identity"] if solo else images_of(layout.symmetry)
	match kw:
		"road":
			spec.check_keys(st, ["poly", "width"])
			var poly: Variant = Spec.parse_poly(st["kv"].get("poly", ""))
			if poly == null:
				spec.err(st["line"], st["kv"].get("poly", "poly"), "road wants poly=[(x,z),...]")
				return
			for fr in imgs:
				var xf := frame_xf(fr)
				var pp := PackedVector3Array()
				for p in poly:
					pp.append(xf * p)
				layout.roads.append({"id": sid + ("" if fr == "identity" else suffix_of(layout.symmetry, fr)), "poly": pp, "width": spec.num(st, "width", 5.0)})
		"zone":
			spec.check_keys(st, ["biome"])
			var a: Variant = Spec.parse_area(st["args"][1] if st["args"].size() > 1 else "")
			if a == null:
				spec.err(st["line"], sid, "zone wants: zone <id> circle((x,z),r) | ring(...) | rect(...) biome=<name>")
				return
			for fr in imgs:
				var z: Dictionary = (a as Dictionary).duplicate()
				var xf := frame_xf(fr)
				if z.has("center"):
					z["center"] = xf * (z["center"] as Vector3)
				else:
					var p1: Vector3 = xf * (z["min"] as Vector3)
					var p2: Vector3 = xf * (z["max"] as Vector3)
					z["min"] = Vector3(minf(p1.x, p2.x), 0, minf(p1.z, p2.z))
					z["max"] = Vector3(maxf(p1.x, p2.x), 0, maxf(p1.z, p2.z))
				z["id"] = sid + ("" if fr == "identity" else suffix_of(layout.symmetry, fr))
				z["biome"] = String(st["kv"].get("biome", ""))
				layout.zones.append(z)
		"block":
			spec.check_keys(st, ["at", "size", "yaw", "kind", "height"])
			var at: Variant = spec.vec(st, "at")
			var sz: Variant = spec.vec(st, "size", Vector3(2, 0, 2))
			if at == null:
				spec.err(st["line"], sid, "block wants at=(x,z) size=(w,d) yaw=deg")
				return
			var bk := String(st["kv"].get("kind", "rock"))
			if not BLOCK_KINDS.has(bk):
				spec.err(st["line"], bk, "unknown block kind", BLOCK_KINDS)
			var placed: Array[Vector3] = []
			for fr in imgs:
				var xf := frame_xf(fr)
				var yaw := spec.num(st, "yaw", 0.0)
				# a mirror flips the yaw's sign; a half turn keeps it (a box is symmetric under 180 deg)
				if fr == "mirror_x" or fr == "mirror_z":
					yaw = -yaw
				var c: Vector3 = xf * (at as Vector3)
				var dup := false
				for q in placed:
					dup = dup or q.distance_to(c) < DEDUPE
				if dup:
					continue   # a block on a mirror axis appears once
				placed.append(c)
				var b := {"id": sid + ("" if fr == "identity" else suffix_of(layout.symmetry, fr)), "center": c,
					"half": Vector3(absf(sz.x) * 0.5, 1.5, absf(sz.z) * 0.5), "yaw": yaw}
				if bk != "rock" or st["kv"].has("height"):
					b["kind"] = bk
					b["height"] = spec.num(st, "height", 3.0)
				layout.blocks.append(b)
		"prop":
			spec.check_keys(st, ["scene", "at", "yaw", "clear", "colliders"])
			var pat: Variant = spec.vec(st, "at")
			if pat == null:
				spec.err(st["line"], sid, "prop wants: prop <id> scene=res://...tscn at=(x,z) yaw=deg clear=4 colliders=[(x,z,r),...]")
				return
			var cols: Array = []
			if st["kv"].has("colliders"):
				var cp: Variant = Spec.parse_poly(st["kv"]["colliders"])
				if cp == null:
					spec.err(st["line"], st["kv"]["colliders"], "colliders= wants [(local x,local z,radius),...]")
				else:
					for v: Vector3 in cp:
						cols.append(Vector3(v.x, v.y, v.z))   # (x, z, r) as written
			var yaw0 := spec.num(st, "yaw", 0.0)
			for fr in imgs:
				var xf := frame_xf(fr)
				var yaw := yaw0
				match fr:
					"rot180":
						yaw = yaw0 + 180.0
					"mirror_x":
						yaw = -yaw0
					"mirror_z":
						yaw = 180.0 - yaw0
				layout.props.append({"id": sid + ("" if fr == "identity" else suffix_of(layout.symmetry, fr)),
					"scene": String(st["kv"].get("scene", "")), "pos": xf * (pat as Vector3), "yaw": deg_to_rad(yaw),
					"clear": spec.num(st, "clear", 0.0), "colliders": cols, "image": fr})


# ---------------------------------------------------------------- fix (map-production.md 2.5)

## Applies Map Lab v2 fixable moves to a `.map`: one `move <id> at=(x,z)  # autofix: ...` line per spot (replacing an
## earlier autofix line of the same spot; moves of one round add up, <= 5 m). Returns the changed lines. Never touches
## seats, the river or the symmetry: only spot positions (the canonical twin; the symmetry moves the others).
static func apply_fixes(path: String, lay: MapLayout, fixes: Array, round_no: int) -> Array[String]:
	var moves := {}
	var whys := {}
	for f: Dictionary in fixes:
		var fid := String(f["id"])
		moves[fid] = (moves.get(fid, Vector3.ZERO) as Vector3) + (f["move"] as Vector3)
		if not whys.has(fid):
			whys[fid] = []
		(whys[fid] as Array).append(String(f.get("why", "")))
	var lines := FileAccess.get_file_as_string(path).split("\n")
	var out: Array[String] = []
	var changed: Array[String] = []
	var pos := {}
	for fid: String in moves:
		var s := {}
		for sp: Dictionary in lay.spots:
			if String(sp.get("image", "identity")) == "identity" and (String(sp["id"]) == fid or String(sp.get("twin_of", "")) == fid):
				s = sp
				break
		if s.is_empty():
			continue
		var mv: Vector3 = moves[fid]
		if mv.length() > 5.0:
			mv = mv.normalized() * 5.0
		var np: Vector3 = (s["pos"] as Vector3) + mv
		var hx := lay.size_x * 0.5 - 3.0
		var hz := lay.size_z * 0.5 - 3.0
		np = Vector3(clampf(np.x, -hx, hx), 0.0, clampf(np.z, -hz, hz))
		pos[String(s.get("twin_of", fid))] = [np, mv.length(), ", ".join(whys[fid])]
	for l in lines:
		var t := l.strip_edges()
		var drop := false
		for fid: String in pos:
			if t.begins_with("move %s " % fid):
				drop = true
		if not drop:
			out.append(l)
	while not out.is_empty() and out[out.size() - 1].strip_edges() == "":
		out.pop_back()
	if not pos.is_empty() and not "\n".join(out).contains("# autofix"):
		out.append("")
		out.append("# autofix (run_world_forge.ps1 fix): moves of the Map Lab v2 fixable findings; delete a line to undo it")
	for fid: String in pos:
		var e: Array = pos[fid]
		var p: Vector3 = e[0]
		var line := "move %s  at=(%.1f,%.1f)  # autofix round %d: moved %.1f m (%s)" % [fid, p.x, p.z, round_no, float(e[1]), e[2]]
		out.append(line)
		changed.append(line)
	var f2 := FileAccess.open(path, FileAccess.WRITE)
	f2.store_string("\n".join(out) + "\n")
	f2.close()
	return changed


# ---------------------------------------------------------------- map verb

func start_map(id: String, p_opts: Dictionary, p_holder: Node3D) -> String:
	opts = p_opts.duplicate()
	holder = p_holder
	map_id = id
	t0 = Time.get_ticks_usec()
	var path := String(opts.get("spec", "%s/%s.map" % [MAPS_DIR, id]))
	if not compile(path):
		var s := ""
		for l in spec.error_lines():
			s += "ERROR " + l + "\n"
		return s + "WORLD FORGE map %s: BAD INPUT (%d errors)" % [id, spec.errors.size()]
	for l in spec.warning_lines():
		print("WARN  " + l)
	report.setup("map", id)
	_layout_checks()
	# save the layout
	for s in layout.spots:
		s.erase("line")
	var lpath := "%s/%s_layout.tres" % [path.get_base_dir(), id]   # next to its .map (data/maps, data/maps/gen, an out folder)
	var e := ResourceSaver.save(layout, lpath)
	if e != OK:
		return "WORLD FORGE map %s: could not save %s (error %d)" % [id, lpath, e]
	layout.take_over_path(lpath)
	report.files.append(lpath)
	# preview level: a generated subclass with LAIR_SPOTS, and its scene
	var od := "%s/%s" % [OUT_DIR, id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(od))
	var src := "extends \"%s\"\n## Generated by World Forge for the Map Lab (lairs are read from this constant). Do not edit.\n\nconst LAIR_SPOTS: Array[Dictionary] = [\n" % LEVEL_SCRIPT
	for s in layout.spots_of("lair"):
		src += "\t{\"id\": \"%s\", \"center\": Vector3(%.3f, 0.0, %.3f)},\n" % [s["id"], s["pos"].x, s["pos"].z]
	src += "]\n"
	var gd_path := od + "/preview_level.gd"
	var f := FileAccess.open(gd_path, FileAccess.WRITE)
	f.store_string(src)
	f.close()
	var scr := GDScript.new()
	scr.source_code = src
	scr.reload()
	scr.take_over_path(gd_path)
	level = Node3D.new()
	level.name = "ForgeMapPreview"
	level.set_script(scr)
	level.set(&"layout", layout)
	var ps := PackedScene.new()
	ps.pack(level)
	ResourceSaver.save(ps, od + "/preview.tscn")
	report.files.append(od + "/preview.tscn")
	# profile for the Map Lab CLI (map_lab.gd profile_json=)
	var prof := {"name": id, "title": layout.title, "scene": od + "/preview.tscn", "half_size": layout.size * 0.5,
		"symmetries": _sym_names(), "seats": [], "spec": opts.get("spec_doc", "-")}
	for s in layout.seats:
		prof["seats"].append({"team": s["team"], "name": s["name"], "side": s["side"]})
	var pf := FileAccess.open(od + "/map_profile.json", FileAccess.WRITE)
	pf.store_string(JSON.stringify(prof, "\t"))
	pf.close()
	report.files.append(od + "/map_profile.json")
	if String(opts.get("live", "0")) == "1":
		# live=1 (MT2): the Map Lab judges the playable LayoutLevel itself (sim mode, bots off), not the preview
		level.free()
		_SIM.enabled = true
		level = (load(LIVE_SCENE) as PackedScene).instantiate()
		level.set(&"layout", layout)
		MapLab._disable_bots(level)
		report.notes.append("live=1: the Map Lab ran on %s with this layout (sim mode, bots off)." % LIVE_SCENE)
	holder.add_child(level)
	return ""


func _sym_names() -> Array:
	match layout.symmetry:
		"mirror_x":
			return ["mirror_x"]
		"mirror_z":
			return ["mirror_z"]
		"rot180":
			return ["half_turn"]
		"fourfold":
			return ["mirror_x", "mirror_z", "half_turn"]
	return []


func profile_dict() -> Dictionary:
	var syms: Array = []
	for n: String in _sym_names():
		syms.append({"name": n, "xf": {"mirror_x": Profiles.MIRROR_X, "mirror_z": Profiles.MIRROR_Z, "half_turn": Profiles.HALF_TURN}[n]})
	var seats: Array = []
	for s in layout.seats:
		seats.append({"team": s["team"], "name": s["name"], "side": s["side"]})
	return {"name": map_id, "title": layout.title, "scene": "%s/%s/preview.tscn" % [OUT_DIR, map_id], "half_size": layout.size * 0.5,
		"symmetries": syms, "seats": seats, "spec": opts.get("spec_doc", "-"), "settings": {}}


func _layout_checks() -> void:
	var hx := layout.size_x * 0.5
	var hz := layout.size_z * 0.5
	# L1 keeps per seat
	var keeps := layout.spots_of("keep")
	var teams := {}
	for k in keeps:
		teams[int(k["team"])] = true
	var missing: Array[String] = []
	for s in layout.seats:
		if not teams.has(int(s["team"])):
			missing.append("seat %d (%s)" % [s["team"], s["frame_name"]])
	report.fcheck("L1", "One keep per seat", "FAIL" if not missing.is_empty() or keeps.size() != layout.seats.size() else "PASS",
		"%d keeps, %d seats%s" % [keeps.size(), layout.seats.size(), "" if missing.is_empty() else "; no keep: " + ", ".join(missing)],
		"each seat's frame maps the canonical keep onto that seat", "add `seat <team> frame=<mirror>` for every image of the symmetry", 2.0)
	# L2 in bounds
	var out: Array[String] = []
	l2_fixes.clear()
	for s in layout.spots:
		var p: Vector3 = s["pos"]
		if absf(p.x) > hx - 2.0 or absf(p.z) > hz - 2.0:
			out.append("%s %s" % [s["id"], _v(p)])
			if String(s.get("image", "identity")) == "identity":   # fixable: 0.5 m inside the 2 m margin
				var inside := Vector3(clampf(p.x, -hx + 2.5, hx - 2.5), 0.0, clampf(p.z, -hz + 2.5, hz - 2.5))
				l2_fixes.append({"id": String(s.get("twin_of", s["id"])), "move": inside - p, "why": "L2 outside the map"})
	report.fcheck("L2", "Spots inside the map", "FAIL" if not out.is_empty() else "PASS", "ok" if out.is_empty() else ", ".join(out),
		"|x| <= W/2 - 2, |z| <= D/2 - 2 (%.0f x %.0f m)" % [layout.size_x, layout.size_z], "move the spot inward (map line %s)" % [layout.source.get_file()])
	# L3 spacing
	var close: Array[String] = []
	for i in layout.spots.size():
		for j in range(i + 1, layout.spots.size()):
			var a: Dictionary = layout.spots[i]
			var b: Dictionary = layout.spots[j]
			var d := (a["pos"] as Vector3).distance_to(b["pos"])
			if d < 3.0 and not (a["kind"] in ["slot", "start"] or b["kind"] in ["slot", "start"]):
				close.append("%s-%s %.1f m" % [a["id"], b["id"], d])
	report.fcheck("L3", "Spot spacing", "WARN" if not close.is_empty() else "PASS", "ok" if close.is_empty() else ", ".join(close),
		">= 3 m between spots (slots / starts excepted)", "a canonical spot too close to its own mirror axis doubles up: move it off the axis or onto it")
	# L4 counts
	var counts := {}
	for s in layout.spots:
		counts[s["kind"]] = int(counts.get(s["kind"], 0)) + 1
	var parts: Array[String] = []
	for k in SPOT_KINDS:
		if counts.has(k):
			parts.append("%s %d" % [k, counts[k]])
	report.fcheck("L4", "Spot counts", "INFO", ", ".join(parts) + "; crossings %d, roads %d, zones %d, blocks %d" % [layout.crossings.size(),
		layout.roads.size(), layout.zones.size(), layout.blocks.size()], "compare with the design doc's count table", "")


func tick_map(frame: int) -> Dictionary:
	if level == null:
		return {"code": 2, "line": "no level"}
	MapLab._disable_bots(level)
	if level.get(&"match_started") != true:
		if frame > 7000:
			report.fcheck("N0", "Navmesh bake", "FAIL", "not ready after %d frames" % frame, "the preview bakes", "")
			return _end_map()
		return {}
	if _ready_frame < 0:
		_ready_frame = frame
	if frame < _ready_frame + 10:
		return {}
	var nav := level.get(&"nav_region") as NavigationRegion3D
	var polys := nav.navigation_mesh.get_polygon_count() if nav and nav.navigation_mesh else 0
	var bake_s: Variant = level.get(&"bake_seconds")
	report.fcheck("N0", "Navmesh bakes", "PASS" if polys > 0 else "FAIL", "%d polygons%s" % [polys, " in %.1f s" % float(bake_s) if bake_s != null else ""],
		"the preview navmesh is ready: baked (flat ground, river / moat / keeps / blocks / forest as obstacles) or loaded from `navmesh` lines", "check the river / block lines", 1.5)
	var fp: Variant = level.get(&"forest_plan")
	if fp is Dictionary and (fp as Dictionary).has("hash"):
		report.notes.append("Forest (MapForest): %d trees, %d rocks, %d pillars, hash %s." % [(fp["trees"] as Array).size(),
			(fp["rocks"] as Array).size(), (fp["pillars"] as Array).size(), fp["hash"]])
	var od := "%s/%s" % [OUT_DIR, map_id]
	var lab_opts := {"out": od + "/map_lab", "run": "world_forge_" + map_id, "log": "0", "scene": od + "/preview.tscn"}
	var lab = MapLab.run_on(level, profile_dict(), lab_opts, t0, frame)
	lab_score = lab.quality()
	lab_result = lab.result()
	lab_fixes = lab.fixes.duplicate()
	lab_fixes.append_array(l2_fixes)
	lab_fails = lab.count("FAIL")
	var score: float = lab_score
	var res: String = lab_result
	var st := "PASS" if res != "FAIL" and score >= LAB_MIN else "FAIL"
	report.fcheck("LAB", "Map Lab", st, "%s, score %.0f / 100" % [res, score], "Map Lab 0 FAIL and score >= %.0f (map-production.md 9)" % LAB_MIN,
		"open map_lab/scorecard.md: its Improve next names the spot; `run_world_forge.ps1 fix %s` moves fixable spots" % map_id, 3.0)
	for c: Dictionary in lab.checks:
		if String(c["id"]).begins_with("R") and c["status"] in ["PASS", "WARN", "FAIL"]:
			report.fcheck("LAB." + String(c["id"]), String(c["name"]), String(c["status"]), String(c.get("value", "")), "Map Lab v2 " + String(c["id"]), "", 0.5)
		if String(c["id"]).begins_with("M") or String(c["id"]) == "F1":
			report.fcheck("LAB." + String(c["id"]), String(c["name"]), String(c["status"]) if c["status"] in ["PASS", "WARN", "FAIL"] else "INFO",
				String(c.get("value", "")) if String(c.get("value", "")) != "" else "%d items" % int(c.get("count", 0)), "Map Lab " + String(c["id"]), "", 0.5)
	report.files.append(od + "/map_lab/scorecard.md")
	report.files.append(od + "/map_lab/heatmap.png")
	# round trip (export-map wrote the live spots)
	var ref_path := "%s/%s/export_spots.json" % [OUT_DIR, map_id]
	if FileAccess.file_exists(ref_path):
		_round_trip(ref_path)
	return _end_map()


func _round_trip(ref_path: String) -> void:
	var ref: Variant = JSON.parse_string(FileAccess.get_file_as_string(ref_path))
	if not ref is Array:
		return
	var worst := 0.0
	var worst_id := ""
	var missing: Array[String] = []
	for r: Dictionary in ref:
		var p := Vector3(r["pos"][0], 0, r["pos"][1])
		var best := INF
		for s in layout.spots:
			if s["kind"] == r["kind"]:
				best = minf(best, (s["pos"] as Vector3).distance_to(p))
		if best > 0.1:
			missing.append("%s %s (%.2f m)" % [r["kind"], r["id"], best])
		if best > worst:
			worst = best
			worst_id = r["id"]
	var n_ref := (ref as Array).size()
	var st := "PASS" if missing.is_empty() and n_ref == layout.spots.size() else "FAIL"
	report.fcheck("R1", "Round trip: every live spot rebuilt within 0.1 m", st, "%d live spots, %d rebuilt; worst %.3f m (%s)%s" % [n_ref,
		layout.spots.size(), worst, worst_id, "" if missing.is_empty() else "; off: " + ", ".join(missing)],
		"export-map -> map: same count, each spot within 0.1 m (same kind)", "a live spot without an exact twin must be written `solo`", 2.0)
	_compare_paths()


func _end_map() -> Dictionary:
	var od := "%s/%s" % [OUT_DIR, map_id]
	var img := layout_image(layout)
	img.save_png(od + "/layout.png")
	report.files.append(od + "/layout.png")
	report.hash_value = layout.source_hash + "/" + _layout_hash()
	var code := report.done()
	return {"code": code, "line": "WORLD FORGE map %s: %s quality %.0f" % [map_id, report.result(), report.quality()]}


func _layout_hash() -> String:
	var s := ""
	for sp in layout.spots:
		s += "%s %s %s %d\n" % [sp["id"], sp["kind"], _v(sp["pos"]), sp["team"]]
	return s.md5_text().substr(0, 12)


static func _v(p: Vector3) -> String:
	return "(%.2f, %.2f)" % [p.x, p.z]


const KIND_COLORS := {"keep": Color(1, 1, 1), "node": Color(0.0, 0.85, 0.95), "point": Color(0.6, 0.2, 0.9), "camp": Color(0.9, 0.5, 0.1),
	"lair": Color(0.55, 0.25, 0.1), "tavern": Color(0.1, 0.7, 0.2), "post": Color(0.9, 0.8, 0.1), "guild": Color(0.5, 0.5, 0.2),
	"peddler": Color(0.2, 0.4, 0.2), "cache": Color(0.8, 0.8, 0.5), "crown": Color(1.0, 0.1, 0.6), "start": Color(0.7, 0.7, 0.7), "slot": Color(0.5, 0.5, 0.5)}


## Top-down layout: ground, zones, roads, blocks, water, crossings, spots (colour by kind), keeps with seat rings.
static func layout_image(lay: MapLayout) -> Image:
	var ppm := 6.0
	var n := int(lay.size * ppm)
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.33, 0.40, 0.26))
	var half := lay.size * 0.5
	var px := func(p: Vector3) -> Vector2:
		return Vector2((p.x + half) * ppm, (p.z + half) * ppm)
	for z: Dictionary in lay.zones:
		var col := Color(0.2, 0.28, 0.2, 0.5) if z.get("biome", "") == "old_wood" else Color(0.5, 0.45, 0.3, 0.35)
		if z.has("center"):
			Img._disc(img, px.call(z["center"]), float(z["r1"]) * ppm, col)
		else:
			Img._rect(img, px.call(z["min"]), px.call(z["max"]), col)
	for r: Dictionary in lay.roads:
		var poly: PackedVector3Array = r["poly"]
		for i in range(poly.size() - 1):
			Img._line(img, px.call(poly[i]), px.call(poly[i + 1]), Color(0.55, 0.45, 0.3), int(float(r["width"]) * ppm * 0.6))
	for b: Dictionary in lay.blocks:
		var c: Vector3 = b["center"]
		var h: Vector3 = b["half"]
		Img._rect(img, px.call(c - Vector3(h.x, 0, h.z)), px.call(c + Vector3(h.x, 0, h.z)), Color(0.25, 0.22, 0.2))
	for arm: Dictionary in lay.river:
		var poly2: PackedVector3Array = arm["poly"]
		for i in range(poly2.size() - 1):
			Img._line(img, px.call(poly2[i]), px.call(poly2[i + 1]), Color(0.15, 0.35, 0.55), int(float(arm["half_width"]) * 2.0 * ppm))
	if not lay.moat.is_empty():
		var c2: Vector3 = lay.moat["center"]
		var rr: float = lay.moat["radius"]
		for k in 180:
			var a := TAU * k / 180.0
			Img._disc(img, px.call(c2 + Vector3(cos(a) * rr, 0, sin(a) * rr)), float(lay.moat["half_width"]) * ppm, Color(0.15, 0.35, 0.55))
	for cr: Dictionary in lay.crossings:
		var w: float = float(cr.get("width", 6.0)) * 0.5 * ppm
		Img._disc(img, px.call(cr["center"]), w, Color(0.75, 0.62, 0.42) if String(cr["kind"]).begins_with("bridge") else Color(0.45, 0.65, 0.75))
	for s: Dictionary in lay.spots:
		var col2: Color = KIND_COLORS.get(s["kind"], Color.WHITE)
		var r2 := 9.0 if s["kind"] == "keep" else (7.0 if s["kind"] == "crown" else 5.0)
		Img._disc(img, px.call(s["pos"]), r2 + 1.5, Color(0, 0, 0))
		Img._disc(img, px.call(s["pos"]), r2, col2)
	# 12 m grid ticks on the axes
	Img._line(img, Vector2(n * 0.5, 0), Vector2(n * 0.5, n), Color(1, 1, 1, 0.15), 1)
	Img._line(img, Vector2(0, n * 0.5), Vector2(n, n * 0.5), Color(1, 1, 1, 0.15), 1)
	return img


# ---------------------------------------------------------------- export-map

var _exp_scene := ""


func start_export(id: String, p_opts: Dictionary, p_holder: Node3D) -> String:
	opts = p_opts.duplicate()
	holder = p_holder
	t0 = Time.get_ticks_usec()
	var prof := Profiles.get_profile("1v1" if id == "crown_hollow" else id)
	_exp_scene = String(opts.get("scene", prof.get("scene", id)))
	map_id = String(opts.get("as", "crown_hollow" if id == "crown_hollow" else _exp_scene.get_file().get_basename()))
	if not ResourceLoader.exists(_exp_scene):
		return "WORLD FORGE export-map: scene %s not found (ids: crown_hollow, or scene=res://...tscn as=<id>)" % _exp_scene
	report.setup("export-map", map_id)
	_SIM.enabled = true
	level = (load(_exp_scene) as PackedScene).instantiate()
	for k: String in prof.get("settings", {}):
		if k in level:
			level.set(k, prof["settings"][k])
	MapLab._disable_bots(level)
	holder.add_child(level)
	opts["profile"] = prof
	return ""


func tick_export(frame: int) -> Dictionary:
	MapLab._disable_bots(level)
	var started: Variant = level.get(&"match_started")
	if not (started == true or level.get(&"hero") != null):
		if frame > 7000:
			return {"code": 1, "line": "WORLD FORGE export-map %s: the level never finished loading" % map_id}
		return {}
	if frame < 10:
		return {}
	var live := collect_spots(level)
	var prof: Dictionary = opts["profile"]
	var half: float = float(prof.get("half_size", 60.0))
	var sym := "rot180"
	var syms: Array = prof.get("symmetries", [])
	if syms.size() >= 3:
		sym = "fourfold"
	# pair every spot with its half-turn twin (same kind within 0.1 m); canonical = the x < 0 (or x = 0, z > 0) one
	var used := {}
	var lines: Array[String] = []
	var n_pair := 0
	var n_self := 0
	var n_solo := 0
	var xf := Profiles.HALF_TURN
	for i in live.size():
		if used.has(i):
			continue
		var a: Dictionary = live[i]
		var pa: Vector3 = a["pos"]
		if (xf * pa).distance_to(pa) < DEDUPE:
			used[i] = true
			lines.append(_spot_line(a, ""))
			n_self += 1
			continue
		var twin := -1
		for j in live.size():
			if j != i and not used.has(j) and live[j]["kind"] == a["kind"] and (live[j]["pos"] as Vector3).distance_to(xf * pa) < 0.1:
				twin = j
				break
		if twin < 0:
			used[i] = true
			lines.append(_spot_line(a, "", true))
			n_solo += 1
			continue
		used[i] = true
		used[twin] = true
		var b: Dictionary = live[twin]
		var canon_a := pa.x < -0.001 or (absf(pa.x) <= 0.001 and pa.z > 0.0)
		lines.append(_spot_line(a if canon_a else b, String((b if canon_a else a)["id"])))
		n_pair += 1
	# crossings (global)
	var cross_lines: Array[String] = []
	for r: Node in level.get_tree().get_nodes_in_group(&"river"):
		if level.is_ancestor_of(r) and r.has_method(&"crossings"):
			for c: Dictionary in r.call(&"crossings"):
				var cc: Vector3 = c["center"]
				var d: Vector3 = c.get("dir", Vector3.FORWARD)
				cross_lines.append("crossing %s kind=%s at=(%.3f,%.3f) width=%.2f length=%.2f dir=(%.3f,%.3f)" % [c["id"], c["kind"], cc.x, cc.z,
					float(c.get("width", 6.0)), float(c.get("length", 6.0)), d.x, d.z])
	var river_lines: Array[String] = []
	if level.has_method(&"river_polylines"):
		var hw: Variant = (level.get_script() as Script).get_script_constant_map().get("RIVER_HALF_WIDTH")
		for poly: Variant in level.call(&"river_polylines"):
			var pts: Array[String] = []
			for p: Vector2 in poly:
				pts.append("(%.2f,%.2f)" % [p.x, p.y])
			river_lines.append("river arm poly=[%s] half_width=%.2f" % [",".join(pts), float(hw) if hw != null else 2.5])
	var moat: Variant = (level.get_script() as Script).get_script_constant_map().get("MOAT")
	if moat is Vector4:
		river_lines.append("moat center=(%.2f,%.2f) radius=%.2f half_width=%.2f" % [moat.x, moat.y, moat.z, moat.w])
	var nav_lines := _export_navmeshes()
	var txt := "# %s: exported by World Forge from %s (live spots after the level loaded). Rebuild: run_world_forge.ps1 map %s\n" % [prof.get("title", map_id), _exp_scene, map_id]
	txt += "map %s  size=%.0f  symmetry=%s  title=\"%s\"  spec=%s\n" % [map_id, half * 2.0, sym, prof.get("title", map_id), prof.get("spec", "-")]
	var fr_names := {0: "identity", 1: "rot180"}
	for s: Dictionary in prof.get("seats", []):
		txt += "seat %d  name=\"%s\"  side=%d  frame=%s\n" % [s["team"], s["name"], s["side"], fr_names.get(int(s["side"]), "identity")]
	txt += "\n# the live navmesh (paths in the preview = live paths; delete these lines to bake a flat preview instead)\n" + "\n".join(nav_lines) + "\n"
	txt += "\n# spots: canonical half (x < 0); `twin=` names the live id of its half-turn image; `solo` = no exact twin\n"
	lines.sort()
	txt += "\n".join(lines) + "\n\n# river (global, not mirrored)\n" + "\n".join(river_lines) + ("\n" if not river_lines.is_empty() else "") + "\n".join(cross_lines) + "\n"
	var mpath := "%s/%s.map" % [MAPS_DIR, map_id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAPS_DIR))
	var f := FileAccess.open(mpath, FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	report.files.append(mpath)
	var od := "%s/%s" % [OUT_DIR, map_id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(od))
	var ref: Array = []
	for s: Dictionary in live:
		ref.append({"id": s["id"], "kind": s["kind"], "pos": [snappedf(s["pos"].x, 0.0001), snappedf(s["pos"].z, 0.0001)]})
	var jf := FileAccess.open(od + "/export_spots.json", FileAccess.WRITE)
	jf.store_string(JSON.stringify(ref, "\t"))
	jf.close()
	report.files.append(od + "/export_spots.json")
	var pt := path_table(_nav_map_of(level), live)
	var pf := FileAccess.open(od + "/export_paths.json", FileAccess.WRITE)
	pf.store_string(JSON.stringify(pt, "\t", true))
	pf.close()
	report.files.append(od + "/export_paths.json")
	report.fcheck("E3", "Live path table", "PASS" if pt.size() > 0 else "FAIL", "%d spot pairs, %d navmesh region(s) saved" % [pt.size(), nav_lines.size()],
		"NavigationServer3D.map_get_path (optimized, the Map Lab's call) between every pair of live spots", "the level has no navmesh yet")
	report.fcheck("E1", "Live spots exported", "PASS" if live.size() > 0 else "FAIL", "%d spots: %d twin pairs, %d on the centre, %d solo; %d crossings, %d river arms" % [
		live.size(), n_pair, n_self, n_solo, cross_lines.size(), river_lines.size()], "every Map Lab spot kind of the live scene is in the .map",
		"a solo spot has no exact half-turn twin in the live map (tell the map owner)" if n_solo > 0 else "", 1.0)
	if n_solo > 0:
		report.fcheck("E2", "Live map symmetric", "WARN", "%d spots without an exact twin (written solo)" % n_solo, "every live spot has its half-turn twin within 0.1 m", "see the solo lines in the .map")
	report.hash_value = txt.md5_text().substr(0, 12)
	var code := report.done()
	return {"code": code, "line": "WORLD FORGE export-map %s: %s (%d spots) -> %s" % [map_id, report.result(), live.size(), mpath]}


func _spot_line(s: Dictionary, twin: String, solo := false) -> String:
	var p: Vector3 = s["pos"]
	var l := "%-7s %s  at=(%.4f,%.4f)" % [s["kind"], s["id"], p.x, p.z]
	if s["kind"] == "keep":
		l += "  team=%d" % s["team"]
	if twin != "":
		l += "  twin=%s" % twin
	if solo:
		l += "  solo"
	return l


## The spots the Map Lab reads, from a live level: [{id, kind, pos, team}].
static func collect_spots(lv: Node) -> Array:
	var out: Array = []
	var tree := lv.get_tree()
	for b: Node in tree.get_nodes_in_group(&"buildings"):
		if b is Keep and lv.is_ancestor_of(b):
			out.append({"id": "keep_t%d" % (b as Keep).team, "kind": "keep", "pos": _flat((b as Node3D).global_position), "team": (b as Keep).team})
	for nd: Node in tree.get_nodes_in_group(&"crystal_nodes"):
		if lv.is_ancestor_of(nd):
			out.append({"id": String(nd.name), "kind": "node", "pos": _flat((nd as Node3D).global_position), "team": -1})
	var groups := {&"capture_points": "point", &"neutral_camps": "camp", &"taverns": "tavern", &"trade_posts": "post",
		&"guilds": "guild", &"peddlers": "peddler", &"lost_caches": "cache"}
	for g: StringName in groups:
		for nd: Node in tree.get_nodes_in_group(g):
			if nd is Node3D and lv.is_ancestor_of(nd):
				out.append({"id": _id_of(nd), "kind": groups[g], "pos": _flat((nd as Node3D).global_position), "team": -1})
	var s: Script = lv.get_script()
	if lv.has_method(&"lair_spots"):   # LayoutLevel (MT2): the layout's lairs, not Crown Hollow's constant
		for d: Dictionary in lv.call(&"lair_spots"):
			out.append({"id": String(d.get("id", "lair")), "kind": "lair", "pos": _flat(d.get("center", d.get("pos", Vector3.ZERO))), "team": -1})
		s = null
	while s != null:
		var m := s.get_script_constant_map()
		if m.has("LAIR_SPOTS"):
			for d: Dictionary in m["LAIR_SPOTS"]:
				out.append({"id": String(d.get("id", "lair")), "kind": "lair", "pos": _flat(d.get("center", d.get("pos", Vector3.ZERO))), "team": -1})
			break
		s = s.get_base_script()
	var crown: Variant = lv.get(&"crown")
	if crown is Node3D and is_instance_valid(crown):
		out.append({"id": "crown", "kind": "crown", "pos": _flat((crown as Node3D).global_position), "team": -1})
	elif lv.get(&"ARTIFACT_POS") is Vector3:
		out.append({"id": "crown", "kind": "crown", "pos": _flat(lv.get(&"ARTIFACT_POS")), "team": -1})
	# unique ids (the .map needs them)
	var seen := {}
	for e: Dictionary in out:
		var base := String(e["id"]).validate_node_name().replace(" ", "_")
		var uid := base
		var k := 2
		while seen.has(uid):
			uid = "%s_%d" % [base, k]
			k += 1
		seen[uid] = true
		e["id"] = uid
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["kind"]) + String(a["id"]) < String(b["kind"]) + String(b["id"]))
	return out


static func _flat(p: Vector3) -> Vector3:
	return Vector3(p.x, 0.0, p.z)


static func _id_of(nd: Node) -> String:
	for prop: StringName in [&"camp_id", &"point_id", &"post_id", &"id"]:
		var v: Variant = nd.get(prop)
		if (v is StringName or v is String) and String(v) != "":
			return String(v)
	var nm := String(nd.name)
	return nm if not nm.begins_with("@") else nd.get_class().to_lower()


# ---------------------------------------------------------------- path table (round trip R2)

static func _nav_map_of(lv: Node) -> RID:
	var regs := lv.find_children("*", "NavigationRegion3D", true, false)
	return (regs[0] as NavigationRegion3D).get_navigation_map() if not regs.is_empty() else RID()


## {"<id a>|<id b>": length} for every pair of spots (ids sorted), NavigationServer3D paths between the spots' closest
## navmesh points (the Map Lab's path call). "INF" when there is no path.
static func path_table(nav_map: RID, spots: Array) -> Dictionary:
	var out := {}
	if not nav_map.is_valid():
		return out
	var pts := {}
	for s: Dictionary in spots:
		var p: Vector3 = s["pos"]
		pts[String(s["id"])] = NavigationServer3D.map_get_closest_point(nav_map, Vector3(p.x, 0.5, p.z))
	var ids: Array = pts.keys()
	ids.sort()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var path := NavigationServer3D.map_get_path(nav_map, pts[ids[i]], pts[ids[j]], true)
			var d := 0.0
			for k in range(path.size() - 1):
				d += path[k].distance_to(path[k + 1])
			out["%s|%s" % [ids[i], ids[j]]] = snappedf(d, 0.001) if not path.is_empty() else "INF"
	return out


## Saves the live level's baked navmesh(es) next to the .map; returns the `navmesh` spec lines.
func _export_navmeshes() -> Array[String]:
	var lines_out: Array[String] = []
	var k := 0
	for r: Node in level.find_children("*", "NavigationRegion3D", true, false):
		var reg := r as NavigationRegion3D
		if reg.navigation_mesh == null or reg.navigation_mesh.get_polygon_count() == 0:
			continue
		var path := "%s/%s_navmesh%s.res" % [MAPS_DIR, map_id, "" if k == 0 else "_%d" % k]
		ResourceSaver.save(reg.navigation_mesh.duplicate(), path, ResourceSaver.FLAG_COMPRESS)
		report.files.append(path)
		var o := reg.global_transform.origin
		if not reg.global_transform.basis.is_equal_approx(Basis()):
			report.fcheck("E4", "Navmesh region rotated", "WARN", path, "regions are placed by origin only", "the preview ignores the rotation")
		lines_out.append("navmesh %s  origin=(%.3f,%.3f,%.3f)" % [path, o.x, o.y, o.z])
		k += 1
	var links := level.find_children("*", "NavigationLink3D", true, false).size()
	if links > 0:
		report.fcheck("E5", "Navigation links", "WARN", "%d links not exported" % links, "the preview has no links", "paths using links will differ")
	return lines_out


## R2: the preview's path table vs the live one written by export-map (same navmesh -> identical within 1 cm).
func _compare_paths() -> void:
	var ref_path := "%s/%s/export_paths.json" % [OUT_DIR, map_id]
	if not FileAccess.file_exists(ref_path):
		return
	var ref: Variant = JSON.parse_string(FileAccess.get_file_as_string(ref_path))
	if not ref is Dictionary:
		return
	var mine := path_table(_nav_map_of(level), layout.spots.filter(func(s: Dictionary) -> bool: return s["kind"] in SPOT_KINDS and not s["kind"] in ["start", "slot"]))
	var worst := 0.0
	var worst_key := ""
	var missing := 0
	var over: Array[String] = []
	for key: String in ref:
		if not mine.has(key):
			missing += 1
			continue
		var a: Variant = ref[key]
		var b: Variant = mine[key]
		var d := 0.0 if str(a) == "INF" and str(b) == "INF" else (INF if str(a) == "INF" or str(b) == "INF" else absf(float(a) - float(b)))
		if d > worst:
			worst = d
			worst_key = key
		if d > 0.01 and over.size() < 5:
			over.append("%s %s vs %s" % [key, str(a), str(b)])
	var st := "PASS" if missing == 0 and worst <= 0.01 else ("WARN" if missing == 0 and worst <= 1.0 else "FAIL")
	report.fcheck("R2", "Round trip: path table identical", st, "%d pairs, %d missing, worst diff %.3f m (%s)%s" % [(ref as Dictionary).size(), missing,
		worst, worst_key, "" if over.is_empty() else "; " + ", ".join(over)],
		"every spot pair's NavigationServer path length on the rebuilt preview = the live map's (<= 0.01 m); the preview uses the exported live navmesh (`navmesh` lines)",
		"missing pairs = a spot id changed; big diffs = the navmesh lines were removed (flat preview)", 2.0)
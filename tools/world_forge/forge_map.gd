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

const SPOT_KINDS: Array[String] = ["keep", "node", "point", "camp", "tavern", "post", "guild", "peddler", "cache", "lair", "crown", "start", "slot"]
const OTHER: Array[String] = ["map", "seat", "river", "moat", "crossing", "road", "zone", "block"]
const SYMS: Array[String] = ["none", "mirror_x", "mirror_z", "rot180", "fourfold"]
const FRAMES: Array[String] = ["identity", "mirror_x", "mirror_z", "rot180"]
const CROSS_KINDS: Array[String] = ["bridge_road", "bridge_lane", "ford", "steps"]
const DEDUPE := 0.05
const LAB_MIN := 90.0

var spec := Spec.new()
var report := Report.new()
var layout: MapLayout
var map_id := ""
var level: Node3D
var holder: Node3D
var opts := {}
var t0 := 0
var export_ref: Array = []
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
	var sts := spec.read_file(path)
	layout = MapLayout.new()
	layout.source = path
	if not spec.ok():
		return false
	layout.source_hash = FileAccess.get_file_as_string(path).md5_text().substr(0, 12)
	var canon: Array = []   # spot statements
	var seat_frames := {}   # frame name -> seat dict
	for st: Dictionary in sts:
		var kw: String = st["kw"]
		if SPOT_KINDS.has(kw):
			canon.append(st)
			continue
		if not OTHER.has(kw):
			spec.err(st["line"], kw, "unknown statement \"%s\"" % kw, SPOT_KINDS + OTHER)
			continue
		match kw:
			"map":
				spec.check_keys(st, ["size", "symmetry", "title", "spec"])
				if st["args"].is_empty():
					spec.err(st["line"], "map", "map wants an id: map <id> size=168 symmetry=fourfold")
					continue
				layout.id = StringName(st["args"][0])
				layout.size = spec.num(st, "size", 120.0)
				layout.symmetry = String(st["kv"].get("symmetry", "none"))
				if not SYMS.has(layout.symmetry):
					spec.err(st["line"], layout.symmetry, "unknown symmetry", SYMS)
					layout.symmetry = "none"
				layout.title = String(st["kv"].get("title", String(layout.id)))
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
			"road", "zone", "block":
				_c_mirrored(st)
	# spots, mirrored
	var imgs := images_of(layout.symmetry)
	for fr in imgs:
		if fr != "identity" and not seat_frames.has(fr) and not layout.seats.is_empty() and layout.symmetry != "fourfold":
			pass
	for st: Dictionary in canon:
		var kind: String = st["kw"]
		spec.check_keys(st, ["at", "sub", "team", "twin", "footprint", "amount", "r", "tier", "name"])
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
			layout.spots.append({"id": this_id, "kind": kind, "sub": String(st["kv"].get("sub", "")), "pos": p, "team": team,
				"twin_of": sid, "props": props, "line": st["line"]})
	if String(layout.id) == "":
		spec.err(1, "map", "the spec needs `map <id> size=<m> symmetry=<none|mirror_x|mirror_z|rot180|fourfold>`")
	return spec.ok()


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
			spec.check_keys(st, ["at", "size", "yaw"])
			var at: Variant = spec.vec(st, "at")
			var sz: Variant = spec.vec(st, "size", Vector3(2, 0, 2))
			if at == null:
				spec.err(st["line"], sid, "block wants at=(x,z) size=(w,d) yaw=deg")
				return
			for fr in imgs:
				var xf := frame_xf(fr)
				var yaw := spec.num(st, "yaw", 0.0)
				# a mirror flips the yaw's sign; a half turn keeps it (a box is symmetric under 180 deg)
				if fr == "mirror_x" or fr == "mirror_z":
					yaw = -yaw
				layout.blocks.append({"id": sid + ("" if fr == "identity" else suffix_of(layout.symmetry, fr)), "center": xf * (at as Vector3),
					"half": Vector3(absf(sz.x) * 0.5, 1.5, absf(sz.z) * 0.5), "yaw": yaw})


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
	report.title = "World Forge map: %s" % layout.title
	report.id = id
	report.kind = "map"
	_layout_checks()
	# save the layout
	for s in layout.spots:
		s.erase("line")
	var lpath := "%s/%s_layout.tres" % [MAPS_DIR, id]
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
	var half := layout.size * 0.5
	# L1 keeps per seat
	var keeps := layout.spots_of("keep")
	var teams := {}
	for k in keeps:
		teams[int(k["team"])] = true
	var missing: Array[String] = []
	for s in layout.seats:
		if not teams.has(int(s["team"])):
			missing.append("seat %d (%s)" % [s["team"], s["frame_name"]])
	report.add("L1", "One keep per seat", "FAIL" if not missing.is_empty() or keeps.size() != layout.seats.size() else "PASS",
		"%d keeps, %d seats%s" % [keeps.size(), layout.seats.size(), "" if missing.is_empty() else "; no keep: " + ", ".join(missing)],
		"each seat's frame maps the canonical keep onto that seat", "add `seat <team> frame=<mirror>` for every image of the symmetry", 2.0)
	# L2 in bounds
	var out: Array[String] = []
	for s in layout.spots:
		var p: Vector3 = s["pos"]
		if absf(p.x) > half - 2.0 or absf(p.z) > half - 2.0:
			out.append("%s %s" % [s["id"], _v(p)])
	report.add("L2", "Spots inside the map", "FAIL" if not out.is_empty() else "PASS", "ok" if out.is_empty() else ", ".join(out),
		"|x|, |z| <= size/2 - 2", "move the spot inward (map line %s)" % [layout.source.get_file()])
	# L3 spacing
	var close: Array[String] = []
	for i in layout.spots.size():
		for j in range(i + 1, layout.spots.size()):
			var a: Dictionary = layout.spots[i]
			var b: Dictionary = layout.spots[j]
			var d := (a["pos"] as Vector3).distance_to(b["pos"])
			if d < 3.0 and not (a["kind"] in ["slot", "start"] or b["kind"] in ["slot", "start"]):
				close.append("%s-%s %.1f m" % [a["id"], b["id"], d])
	report.add("L3", "Spot spacing", "WARN" if not close.is_empty() else "PASS", "ok" if close.is_empty() else ", ".join(close),
		">= 3 m between spots (slots / starts excepted)", "a canonical spot too close to its own mirror axis doubles up: move it off the axis or onto it")
	# L4 counts
	var counts := {}
	for s in layout.spots:
		counts[s["kind"]] = int(counts.get(s["kind"], 0)) + 1
	var parts: Array[String] = []
	for k in SPOT_KINDS:
		if counts.has(k):
			parts.append("%s %d" % [k, counts[k]])
	report.add("L4", "Spot counts", "INFO", ", ".join(parts) + "; crossings %d, roads %d, zones %d, blocks %d" % [layout.crossings.size(),
		layout.roads.size(), layout.zones.size(), layout.blocks.size()], "compare with the design doc's count table", "")


func tick_map(frame: int) -> Dictionary:
	if level == null:
		return {"code": 2, "line": "no level"}
	if level.get(&"match_started") != true:
		if frame > 3000:
			report.add("N0", "Navmesh bake", "FAIL", "not ready after %d frames" % frame, "the preview bakes", "")
			return _end_map()
		return {}
	if _ready_frame < 0:
		_ready_frame = frame
	if frame < _ready_frame + 10:
		return {}
	var nav := level.get(&"nav_region") as NavigationRegion3D
	var polys := nav.navigation_mesh.get_polygon_count() if nav and nav.navigation_mesh else 0
	report.add("N0", "Navmesh bakes", "PASS" if polys > 0 else "FAIL", "%d polygons in %.1f s" % [polys, float(level.get(&"bake_seconds"))],
		"the preview's navmesh bakes (flat ground, river / moat / keeps / blocks as obstacles)", "check the river / block lines", 1.5)
	var od := "%s/%s" % [OUT_DIR, map_id]
	var lab_opts := {"out": od + "/map_lab", "run": "world_forge_" + map_id, "log": "0", "scene": od + "/preview.tscn"}
	var lab = MapLab.run_on(level, profile_dict(), lab_opts, t0, frame)
	var score: float = lab.quality()
	var res: String = lab.result()
	var st := "PASS" if res != "FAIL" and score >= LAB_MIN else ("WARN" if res != "FAIL" and score >= 75.0 else "FAIL")
	report.add("LAB", "Map Lab", st, "%s, score %.0f / 100" % [res, score], "Map Lab PASS / WARN and score >= %.0f" % LAB_MIN,
		"open map_lab/scorecard.md: its Improve next names the spot", 3.0)
	for c: Dictionary in lab.checks:
		if String(c["id"]).begins_with("M") or String(c["id"]) == "F1":
			report.add("LAB." + String(c["id"]), String(c["name"]), String(c["status"]) if c["status"] in ["PASS", "WARN", "FAIL"] else "INFO",
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
	report.add("R1", "Round trip: every live spot rebuilt within 0.1 m", st, "%d live spots, %d rebuilt; worst %.3f m (%s)%s" % [n_ref,
		layout.spots.size(), worst, worst_id, "" if missing.is_empty() else "; off: " + ", ".join(missing)],
		"export-map -> map: same count, each spot within 0.1 m (same kind)", "a live spot without an exact twin must be written `solo`", 2.0)
	report.add("R2", "Round trip: Map Lab path table", "INFO", "not comparable yet",
		"identical path table needs the live terrain (cliffs, forest, river banks) in the preview; the preview is flat ground + water + keeps",
		"next: export blocks (forest clusters / cliffs) from the live navmesh so paths match")


func _end_map() -> Dictionary:
	var od := "%s/%s" % [OUT_DIR, map_id]
	var img := layout_image(layout)
	img.save_png(od + "/layout.png")
	report.files.append(od + "/layout.png")
	report.hash = layout.source_hash + "/" + _layout_hash()
	report.seconds = float(Time.get_ticks_usec() - t0) / 1e6
	report.write(od)
	report.append_history()
	report.print_summary(od)
	return {"code": report.exit_code(), "line": "WORLD FORGE map %s: %s score %.0f" % [map_id, report.result(), report.score()]}


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
	report.title = "World Forge export: %s" % map_id
	report.id = map_id
	report.kind = "export"
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
	var txt := "# %s: exported by World Forge from %s (live spots after the level loaded). Rebuild: run_world_forge.ps1 map %s\n" % [prof.get("title", map_id), _exp_scene, map_id]
	txt += "map %s  size=%.0f  symmetry=%s  title=\"%s\"  spec=%s\n" % [map_id, half * 2.0, sym, prof.get("title", map_id), prof.get("spec", "-")]
	var fr_names := {0: "identity", 1: "rot180"}
	for s: Dictionary in prof.get("seats", []):
		txt += "seat %d  name=\"%s\"  side=%d  frame=%s\n" % [s["team"], s["name"], s["side"], fr_names.get(int(s["side"]), "identity")]
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
	report.add("E1", "Live spots exported", "PASS" if live.size() > 0 else "FAIL", "%d spots: %d twin pairs, %d on the centre, %d solo; %d crossings, %d river arms" % [
		live.size(), n_pair, n_self, n_solo, cross_lines.size(), river_lines.size()], "every Map Lab spot kind of the live scene is in the .map",
		"a solo spot has no exact half-turn twin in the live map (tell the map owner)" if n_solo > 0 else "", 1.0)
	if n_solo > 0:
		report.add("E2", "Live map symmetric", "WARN", "%d spots without an exact twin (written solo)" % n_solo, "every live spot has its half-turn twin within 0.1 m", "see the solo lines in the .map")
	report.hash = txt.md5_text().substr(0, 12)
	report.seconds = float(Time.get_ticks_usec() - t0) / 1e6
	report.write(od + "/export")
	report.append_history()
	report.print_summary(od + "/export")
	return {"code": report.exit_code(), "line": "WORLD FORGE export-map %s: %s (%d spots) -> %s" % [map_id, report.result(), live.size(), mpath]}


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

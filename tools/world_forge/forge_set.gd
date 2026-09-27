extends RefCounted
## World Forge, set mode: `<set>.set` text -> stage-set scene (set contract, prologue-movie-plan.md 2.3) + marks.json +
## lighting preset + baked meshes + plan.png + scorecard. Grammar: tools/world_forge/README.md.
## No class_name on purpose (preloaded tool script).

const Spec := preload("res://tools/world_forge/forge_spec.gd")
const Kits := preload("res://tools/world_forge/forge_kits.gd")
const FMesh := preload("res://tools/world_forge/forge_mesh.gd")
const Report := preload("res://tools/world_forge/forge_report.gd")
const SET_SCRIPT := "res://art/cinematics/stage_sets/forge_common/forge_stage_set.gd"
const SETS_DIR := "res://art/cinematics/stage_sets"
const OUT_DIR := "res://docs/tools/world_forge/out"

const Terrain := preload("res://tools/world_forge/forge_terrain.gd")
const KEYWORDS: Array[String] = ["set", "budget", "zone", "place", "row", "scatter", "wall", "path", "actor", "mark",
	"terrain", "hill", "ridge", "valley", "pad", "sky", "water"]
const KEYS := {
	"set": ["size", "ground", "light", "seed", "title"],
	"budget": ["draws", "lights", "tris"],
	"zone": [],
	"place": ["at", "yaw", "scale", "tag", "lights", "radius", "y", "pad"],
	"row": ["poly", "from", "to", "spacing", "count", "yaw", "scale", "lights", "radius", "seed", "jitter"],
	"scatter": ["area", "count", "gap", "seed", "avoid", "scale", "radius", "tilt"],
	"wall": ["poly", "height", "thick", "gate", "gate_width", "color"],
	"path": ["poly", "width", "kit"],
	"actor": ["at", "yaw", "scale", "lights", "pad"],
	"mark": ["from", "to", "look", "look_to", "fov", "fov_to", "subject", "lens", "dur", "ground"],
	"terrain": ["step", "smooth", "noise", "extend", "rock", "snow", "seed"],
	"hill": ["at", "r", "h", "flat"],
	"ridge": ["poly", "width", "h", "jag"],
	"valley": ["poly", "width", "depth", "flat"],
	"pad": ["at", "r", "y", "edge"],
	"sky": ["mountains", "dist", "height", "color", "haze", "top", "horizon", "seed"],
	"water": ["level", "area", "color", "alpha"],
}
const MOODS: Array[String] = ["warm", "ice", "nightfall", "dusk", "storm", "crypt", "dawn"]
const BAND := 0.744      ## 2.39:1 band inside a 16:9 frame (fraction of the half height)
const BAND_SAFE := 0.62  ## subject point inside this = PASS; up to BAND = WARN
const ASPECT := 16.0 / 9.0

var spec := Spec.new()
var plan := {}
var report := Report.new()
## Filled by build(): world AABBs of places / actors, wall boxes, scatter points.
var obstacles: Array = []   ## [{name, aabb: AABB}] or [{name, xf, center, half}] for walls
var scatter_pts: Array = [] ## [{kit, pos, r}]
var layout_lines: Array[String] = []  ## deterministic layout dump (hash source)
var terrain := Terrain.new()          ## height field (terrain.on false = flat ground at y 0)


# ---------------------------------------------------------------- compile

## Parses a .set file into `plan`. Returns false on errors (spec.error_lines()).
func compile(path: String) -> bool:
	var sts := spec.read_file(path)
	plan = {"id": "", "size": Vector2(40, 30), "ground": Kits.GROUNDS["dirt"], "light": "warm", "seed": 1, "title": "",
		"budget": {"draws": 150.0, "lights": 0.0, "tris": 400000.0}, "zones": {}, "places": [], "rows": [], "scatters": [],
		"walls": [], "paths": [], "actors": [], "marks": [], "path": path, "sky": {}, "waters": []}
	terrain = Terrain.new()
	if not spec.ok():
		return false
	var saw_set := false
	for st: Dictionary in sts:
		var kw: String = st["kw"]
		if not KEYWORDS.has(kw):
			spec.err(st["line"], kw, "unknown statement \"%s\"" % kw, KEYWORDS)
			continue
		spec.check_keys(st, KEYS[kw])
		match kw:
			"set":
				saw_set = true
				_c_set(st)
			"budget":
				for k: String in st["kv"]:
					plan["budget"][k] = spec.num(st, k, 0.0)
			"zone":
				if st["args"].size() < 2:
					spec.err(st["line"], kw, "zone wants: zone <name> ring((x,z),r0..r1) | circle((x,z),r) | rect((x0,z0),(x1,z1))")
					continue
				var a: Variant = Spec.parse_area(st["args"][1])
				if a == null:
					spec.err(st["line"], st["args"][1], "bad area", Spec.AREA_KINDS)
					continue
				plan["zones"][st["args"][0]] = a
			"place":
				_c_place(st)
			"row":
				_c_row(st)
			"scatter":
				_c_scatter(st)
			"wall":
				_c_wall(st)
			"path":
				_c_path(st)
			"actor":
				_c_actor(st)
			"mark":
				_c_mark(st)
			"terrain":
				_c_terrain(st)
			"hill", "ridge", "valley", "pad":
				_c_terrain_op(st)
			"sky":
				_c_sky(st)
			"water":
				_c_water(st)
	if not saw_set:
		spec.err(1, "set", "the spec needs a first line `set <id> size=WxD ground=<name> light=<mood>`")
	_seat_on_terrain()
	# subjects resolve against actors / place tags
	var tags := _tags()
	for m: Dictionary in plan["marks"]:
		if m["subject"] != "" and not tags.has(m["subject"]):
			spec.err(m["line"], m["subject"], "unknown subject \"%s\"" % m["subject"], tags)
	return spec.ok()


func _tags() -> Array:
	var tags: Array = []
	for a: Dictionary in plan["actors"]:
		tags.append(a["tag"])
	for p: Dictionary in plan["places"]:
		if p["tag"] != "":
			tags.append(p["tag"])
	return tags


func _c_set(st: Dictionary) -> void:
	if st["args"].is_empty():
		spec.err(st["line"], "set", "set wants an id: set forge_<name> ...")
		return
	var id: String = st["args"][0]
	if not id.begins_with("forge_") or not id.is_valid_identifier():
		spec.err(st["line"], id, "set ids are snake_case and start with \"forge_\" (World Forge owns art/cinematics/stage_sets/forge_*)")
	plan["id"] = id
	var expect := "%s/%s/%s.set" % [SETS_DIR, id, id]
	if String(plan["path"]).replace("\\", "/") != expect and not String(plan["path"]).begins_with("user://"):
		spec.warn(st["line"], id, "spec file should be %s" % expect)
	if st["kv"].has("size"):
		var p: PackedStringArray = String(st["kv"]["size"]).split("x")
		if p.size() != 2 or not p[0].is_valid_float() or not p[1].is_valid_float():
			spec.err(st["line"], st["kv"]["size"], "size= wants WxD in metres, e.g. size=40x30")
		else:
			plan["size"] = Vector2(p[0].to_float(), p[1].to_float())
	if st["kv"].has("ground"):
		var c: Variant = Spec.parse_color(st["kv"]["ground"], Kits.GROUNDS)
		if c == null:
			spec.err(st["line"], st["kv"]["ground"], "unknown ground", Kits.GROUNDS.keys())
		else:
			plan["ground"] = c
	if st["kv"].has("light"):
		var l: String = st["kv"]["light"]
		if not MOODS.has(l) and not (l.begins_with("res://") and ResourceLoader.exists(l)):
			spec.err(st["line"], l, "unknown light mood", MOODS)
		plan["light"] = l
	plan["seed"] = int(spec.num(st, "seed", 1))
	plan["title"] = st["kv"].get("title", "")


func _kit(st: Dictionary, idx: int) -> Dictionary:
	if st["args"].size() <= idx:
		spec.err(st["line"], st["kw"], "%s wants a kit: kit:<name> or res://path.tscn" % st["kw"], [])
		return {}
	var tok: String = st["args"][idx]
	var k := Kits.resolve(tok)
	if not k["ok"]:
		if tok.begins_with("res://"):
			spec.err(st["line"], tok, "scene not found")
		else:
			spec.err(st["line"], tok, "unknown kit \"%s\"" % tok.trim_prefix("kit:"), Kits.names())
		return {}
	return k


func _yaw(st: Dictionary, def: float) -> float:
	if not st["kv"].has("yaw"):
		return def
	var y: String = st["kv"]["yaw"]
	if y in ["random", "along", "across"]:
		return INF
	return spec.num(st, "yaw", def)


func _c_place(st: Dictionary) -> void:
	var k := _kit(st, 0)
	var at: Variant = spec.vec(st, "at")
	if at == null:
		spec.err(st["line"], "at", "place wants at=(x,z)")
		return
	if k.is_empty():
		return
	if st["kv"].has("y"):
		at.y = spec.num(st, "y", 0.0)
	var lights: String = st["kv"].get("lights", "off")
	if not lights in ["on", "off"]:
		spec.err(st["line"], lights, "lights= is on or off", ["on", "off"])
	_pad_of(st, at, float(at.y) if st["kv"].has("y") else NAN)
	plan["places"].append({"kit": k, "at": at, "yaw": _yaw(st, 0.0), "scale": spec.num(st, "scale", 1.0),
		"tag": st["kv"].get("tag", ""), "lights_off": lights == "off", "radius": spec.num(st, "radius", -1.0), "line": st["line"],
		"y_set": st["kv"].has("y")})


## `place` / `actor` ... pad=R: a flat pad under it (terrain on).
func _pad_of(st: Dictionary, at: Vector3, y: float) -> void:
	if not st["kv"].has("pad"):
		return
	var r := spec.num(st, "pad", 6.0)
	if r <= 0.0:
		spec.err(st["line"], st["kv"]["pad"], "pad= wants a radius in metres > 0")
		return
	terrain.on = true
	terrain.pads.append({"at": at, "r": r, "edge": r * 0.6, "y": y})


func _c_row(st: Dictionary) -> void:
	var k := _kit(st, 0)
	var poly: Variant = null
	if st["kv"].has("poly"):
		poly = Spec.parse_poly(st["kv"]["poly"])
		if poly == null:
			spec.err(st["line"], st["kv"]["poly"], "poly= wants [(x,z),(x,z),...]")
			return
	else:
		var a: Variant = spec.vec(st, "from")
		var b: Variant = spec.vec(st, "to")
		if a == null or b == null:
			spec.err(st["line"], "row", "row wants poly=[...] or from=(x,z) to=(x,z)")
			return
		poly = PackedVector3Array([a, b])
	if k.is_empty():
		return
	var yaw_mode: String = st["kv"].get("yaw", "along")
	var r := RandomNumberGenerator.new()
	r.seed = int(spec.num(st, "seed", plan["seed"]))
	var jitter := spec.num(st, "jitter", 0.0)
	var pts := _resample(poly, spec.num(st, "spacing", 3.0), int(spec.num(st, "count", 0)))
	for i in pts.size():
		var p: Vector3 = pts[i][0]
		var d: Vector3 = pts[i][1]
		var yaw := 0.0
		match yaw_mode:
			"along":
				yaw = rad_to_deg(atan2(d.x, d.z))
			"across":
				yaw = rad_to_deg(atan2(d.x, d.z)) + 90.0
			"random":
				yaw = r.randf() * 360.0
			_:
				yaw = yaw_mode.to_float()
		if jitter > 0.0:
			p += Vector3(r.randf_range(-jitter, jitter), 0, r.randf_range(-jitter, jitter))
		plan["places"].append({"kit": k, "at": p, "yaw": yaw, "scale": spec.num(st, "scale", 1.0), "tag": "",
			"lights_off": st["kv"].get("lights", "off") == "off", "radius": spec.num(st, "radius", -1.0), "line": st["line"], "row": true})


## Points along a polyline every `spacing` m (or `count` points evenly), with the direction there.
static func _resample(poly: PackedVector3Array, spacing: float, count: int) -> Array:
	var total := 0.0
	for i in range(poly.size() - 1):
		total += poly[i].distance_to(poly[i + 1])
	var n := count if count > 0 else maxi(1, int(floor(total / maxf(0.1, spacing))) + 1)
	var out: Array = []
	for j in n:
		var want := total * (float(j) / maxf(1.0, float(n - 1))) if n > 1 else total * 0.5
		var acc := 0.0
		for i in range(poly.size() - 1):
			var seg := poly[i].distance_to(poly[i + 1])
			if acc + seg >= want - 0.0001 or i == poly.size() - 2:
				var t := clampf((want - acc) / maxf(0.0001, seg), 0.0, 1.0)
				out.append([poly[i].lerp(poly[i + 1], t), (poly[i + 1] - poly[i]).normalized()])
				break
			acc += seg
	return out


func _c_scatter(st: Dictionary) -> void:
	var k := _kit(st, 0)
	if not st["kv"].has("area"):
		spec.err(st["line"], "area", "scatter wants area=ring((x,z),r0..r1) | circle((x,z),r) | rect((x0,z0),(x1,z1)) or a zone name")
		return
	var area: Variant = Spec.parse_area(st["kv"]["area"])
	if area == null:
		if plan["zones"].has(st["kv"]["area"]):
			area = plan["zones"][st["kv"]["area"]]
		else:
			spec.err(st["line"], st["kv"]["area"], "bad area (or unknown zone)", Spec.AREA_KINDS + plan["zones"].keys())
			return
	var avoid: Array = []
	if st["kv"].has("avoid"):
		for a: String in String(st["kv"]["avoid"]).split(","):
			if a in ["cams", "marks", "paths", "walls", "places"] or plan["zones"].has(a):
				avoid.append(a)
			else:
				spec.err(st["line"], a, "unknown avoid \"%s\"" % a, ["cams", "paths", "walls", "places"] + plan["zones"].keys())
	if k.is_empty():
		return
	plan["scatters"].append({"kit": k, "area": area, "count": int(spec.num(st, "count", 10)), "gap": spec.num(st, "gap", 2.0),
		"seed": int(spec.num(st, "seed", plan["seed"])), "avoid": avoid, "scale": spec.rng(st, "scale", Vector2(0.85, 1.15)),
		"radius": spec.num(st, "radius", -1.0), "tilt": spec.num(st, "tilt", 0.0), "line": st["line"]})


func _c_wall(st: Dictionary) -> void:
	var poly: Variant = Spec.parse_poly(st["kv"].get("poly", ""))
	if poly == null or (poly as PackedVector3Array).size() < 2:
		spec.err(st["line"], st["kv"].get("poly", "poly"), "wall wants poly=[(x,z),(x,z),...] (2+ points)")
		return
	var gates: Array = []
	if st["kv"].has("gate"):
		for g in Spec._split_top(String(st["kv"]["gate"]).trim_prefix("[").trim_suffix("]")):
			var v: Variant = Spec.parse_vec(g)
			if v == null:
				spec.err(st["line"], g, "gate= wants (x,z) or [(x,z),(x,z)]")
			else:
				gates.append({"at": v, "width": spec.num(st, "gate_width", 4.0)})
	var col: Variant = Spec.parse_color(st["kv"].get("color", "stone"), Kits.GROUNDS)
	if col == null:
		spec.err(st["line"], st["kv"]["color"], "bad color", Kits.GROUNDS.keys())
		col = Kits.GROUNDS["stone"]
	plan["walls"].append({"name": st["args"][0] if not st["args"].is_empty() else "wall", "poly": poly,
		"height": spec.num(st, "height", 4.0), "thick": spec.num(st, "thick", 1.2), "gates": gates, "color": col, "line": st["line"]})


func _c_path(st: Dictionary) -> void:
	var poly: Variant = Spec.parse_poly(st["kv"].get("poly", ""))
	if poly == null or (poly as PackedVector3Array).size() < 2:
		spec.err(st["line"], st["kv"].get("poly", "poly"), "path wants poly=[(x,z),(x,z),...] (2+ points)")
		return
	var kit: String = st["kv"].get("kit", "road")
	if not Kits.PATH_KITS.has(kit):
		spec.err(st["line"], kit, "unknown path kit", Kits.PATH_KITS.keys())
		return
	plan["paths"].append({"name": st["args"][0] if not st["args"].is_empty() else "path", "poly": poly,
		"width": spec.num(st, "width", 3.0), "kit": kit, "line": st["line"]})


func _c_actor(st: Dictionary) -> void:
	if st["args"].size() < 2:
		spec.err(st["line"], "actor", "actor wants: actor <tag> kit:<name>|res://... at=(x,z) yaw=deg")
		return
	var k := _kit(st, 1)
	var at: Variant = spec.vec(st, "at", Vector3.ZERO)
	if k.is_empty():
		return
	_pad_of(st, at, NAN)
	plan["actors"].append({"tag": String(st["args"][0]).to_lower(), "kit": k, "at": at, "yaw": _yaw(st, 0.0),
		"scale": spec.num(st, "scale", 1.0), "lights_off": st["kv"].get("lights", "off") == "off", "line": st["line"]})


func _c_mark(st: Dictionary) -> void:
	if st["args"].is_empty():
		spec.err(st["line"], "mark", "mark wants a shot id: mark P01 from=(x,y,z) look=(x,y,z)")
		return
	var shot: String = st["args"][0]
	if not shot.is_valid_identifier():
		spec.err(st["line"], shot, "shot ids are identifiers (P01, watch_a)")
	var f: Variant = spec.vec(st, "from")
	var l: Variant = spec.vec(st, "look")
	if f == null or l == null:
		if st["kv"].has("lens") or st["args"].size() > 1:
			spec.err(st["line"], shot, "Lens (tool 3) is not installed yet: give explicit from=(x,y,z) look=(x,y,z)")
		else:
			spec.err(st["line"], shot, "mark wants from=(x,y,z) look=(x,y,z)")
		return
	if st["kv"].has("lens"):
		spec.warn(st["line"], st["kv"]["lens"], "lens words are kept as a note; the camera uses from= / look=")
	var fov := spec.num(st, "fov", 40.0)
	var gmode: String = st["kv"].get("ground", "abs")
	if not gmode in ["rel", "abs"]:
		spec.err(st["line"], gmode, "ground= is rel (y above the terrain) or abs (default)", ["rel", "abs"])
	plan["marks"].append({"ground_rel": gmode == "rel","shot": shot, "from": f, "to": spec.vec(st, "to", f), "look_from": l, "look_to": spec.vec(st, "look_to", l),
		"fov_from": fov, "fov_to": spec.num(st, "fov_to", fov), "subject": String(st["kv"].get("subject", "")).to_lower(),
		"lens": st["kv"].get("lens", ""), "dur": spec.num(st, "dur", 4.0), "line": st["line"]})


# ---------------------------------------------------------------- terrain / sky / water (README "Terrain")

func _c_terrain(st: Dictionary) -> void:
	terrain.on = true
	terrain.step = maxf(0.5, spec.num(st, "step", 2.0))
	terrain.smooth = clampi(int(spec.num(st, "smooth", 2)), 0, 8)
	terrain.noise = maxf(0.0, spec.num(st, "noise", 0.25))
	terrain.extend = clampf(spec.num(st, "extend", 0.0), 0.0, 400.0)
	terrain.tseed = int(spec.num(st, "seed", plan["seed"]))
	if st["kv"].has("rock"):
		var c: Variant = Spec.parse_color(st["kv"]["rock"], Kits.GROUNDS)
		if c == null:
			spec.err(st["line"], st["kv"]["rock"], "bad rock colour", Kits.GROUNDS.keys())
		else:
			terrain.rock = c
	if st["kv"].has("snow") and st["kv"]["snow"] != "off":
		terrain.snow = spec.num(st, "snow", INF)


func _c_terrain_op(st: Dictionary) -> void:
	var kw: String = st["kw"]
	terrain.on = true
	var nm: String = st["args"][0] if not st["args"].is_empty() else kw
	match kw:
		"hill":
			var at: Variant = spec.vec(st, "at")
			if at == null:
				spec.err(st["line"], "hill", "hill wants at=(x,z) r=<radius> h=<height>")
				return
			terrain.ops.append({"kind": "hill", "name": nm, "at": at, "r": maxf(0.5, spec.num(st, "r", 12.0)), "h": spec.num(st, "h", 6.0),
				"flat": clampf(spec.num(st, "flat", 0.0), 0.0, 0.9)})
		"ridge", "valley":
			var poly: Variant = Spec.parse_poly(st["kv"].get("poly", ""))
			if poly == null or (poly as PackedVector3Array).is_empty():
				spec.err(st["line"], st["kv"].get("poly", kw), "%s wants poly=[(x,z),(x,z),...]" % kw)
				return
			if kw == "ridge":
				terrain.ops.append({"kind": "ridge", "name": nm, "poly": poly, "width": maxf(1.0, spec.num(st, "width", 10.0)),
					"h": spec.num(st, "h", 8.0), "jag": clampf(spec.num(st, "jag", 0.3), 0.0, 1.0)})
			else:
				terrain.ops.append({"kind": "valley", "name": nm, "poly": poly, "width": maxf(1.0, spec.num(st, "width", 12.0)),
					"depth": spec.num(st, "depth", 3.0), "flat": clampf(spec.num(st, "flat", 0.4), 0.0, 0.9)})
		"pad":
			var at: Variant = spec.vec(st, "at")
			if at == null:
				spec.err(st["line"], "pad", "pad wants at=(x,z) r=<radius>")
				return
			var r := maxf(0.5, spec.num(st, "r", 6.0))
			terrain.pads.append({"at": at, "r": r, "edge": maxf(0.1, spec.num(st, "edge", r * 0.6)),
				"y": spec.num(st, "y", 0.0) if st["kv"].has("y") else NAN})


func _c_sky(st: Dictionary) -> void:
	var sky := {"mountains": clampi(int(spec.num(st, "mountains", 2)), 0, 4), "dist": clampf(spec.num(st, "dist", 190.0), 40.0, 240.0),
		"height": spec.num(st, "height", 38.0), "color": Color("#3a4150"), "haze": null, "top": null, "horizon": null,
		"seed": int(spec.num(st, "seed", plan["seed"])), "line": st["line"]}
	for k: String in ["color", "haze", "top", "horizon"]:
		if st["kv"].has(k):
			var c: Variant = Spec.parse_color(st["kv"][k], Kits.GROUNDS)
			if c == null:
				spec.err(st["line"], st["kv"][k], "%s= wants #rrggbb" % k)
			else:
				sky[k] = c
	if spec.num(st, "dist", 190.0) > 240.0:
		spec.warn(st["line"], st["kv"]["dist"], "dist clamped to 240 m (the cinematic camera's far plane is 250 m)")
	plan["sky"] = sky


func _c_water(st: Dictionary) -> void:
	var area: Variant = null
	if st["kv"].has("area"):
		area = Spec.parse_area(st["kv"]["area"])
		if area == null:
			if plan["zones"].has(st["kv"]["area"]):
				area = plan["zones"][st["kv"]["area"]]
			else:
				spec.err(st["line"], st["kv"]["area"], "bad area (or unknown zone)", Spec.AREA_KINDS + plan["zones"].keys())
				return
	var col: Variant = Spec.parse_color(st["kv"].get("color", "#1d4252"), Kits.GROUNDS)
	if col == null:
		spec.err(st["line"], st["kv"]["color"], "color= wants #rrggbb")
		col = Color("#1d4252")
	plan["waters"].append({"name": st["args"][0] if not st["args"].is_empty() else "water", "level": spec.num(st, "level", -0.5),
		"area": area, "color": col, "alpha": clampf(spec.num(st, "alpha", 0.85), 0.05, 1.0), "line": st["line"]})


## Bakes the height field and puts places / rows / actors on it; `ground=rel` marks get the terrain height added.
func _seat_on_terrain() -> void:
	terrain.bake(plan["size"])
	if not terrain.on:
		return
	for p: Dictionary in plan["places"]:
		if not bool(p.get("y_set", false)):
			var at: Vector3 = p["at"]
			at.y = terrain.height_at(at.x, at.z)
			p["at"] = at
	for a: Dictionary in plan["actors"]:
		var at: Vector3 = a["at"]
		at.y = terrain.height_at(at.x, at.z)
		a["at"] = at
	for m: Dictionary in plan["marks"]:
		if bool(m.get("ground_rel", false)):
			for k: String in ["from", "to", "look_from", "look_to"]:
				var v: Vector3 = m[k]
				v.y += terrain.height_at(v.x, v.z)
				m[k] = v


## True when (x, z) is under one of the set's water planes.
func under_water(p: Vector3) -> bool:
	for w: Dictionary in plan["waters"]:
		if w["area"] != null and not Spec.area_has(w["area"], p):
			continue
		if terrain.height_at(p.x, p.z) < float(w["level"]) + 0.05:
			return true
	return false


# ---------------------------------------------------------------- build

func set_dir() -> String:
	return "%s/%s" % [SETS_DIR, plan["id"]]


func out_dir() -> String:
	return "%s/%s" % [OUT_DIR, plan["id"]]


## Builds the set under `holder` (must be in the tree so model scripts run). Returns the set root.
func build(holder: Node) -> Node3D:
	obstacles.clear()
	scatter_pts.clear()
	layout_lines.clear()
	var root := Node3D.new()
	root.name = String(plan["id"])
	root.set_script(load(SET_SCRIPT))
	root.set(&"set_id", StringName(plan["id"]))
	holder.add_child(root)
	var sz: Vector2 = plan["size"]
	# ground
	if not terrain.baked:
		terrain.bake(sz)
	var gnd := terrain.ground_callable()
	if terrain.on:
		_mesh_child(root, root, "Ground", terrain.mesh(plan["ground"]))
		var body := StaticBody3D.new()
		body.name = "TerrainBody"
		body.collision_layer = 1
		body.collision_mask = 0
		root.add_child(body)
		body.owner = root
		var cs := CollisionShape3D.new()
		cs.name = "Shape"
		cs.shape = (root.get_node(^"Ground") as MeshInstance3D).mesh.create_trimesh_shape()
		body.add_child(cs)
		cs.owner = root
		layout_lines.append(terrain.layout_line())
	else:
		var gst := FMesh.ground(sz, plan["ground"], int(plan["seed"]))
		var gmesh := gst.commit()
		gmesh.surface_set_material(0, FMesh.vc_material(false, 0.97))
		_mesh_child(root, root, "Ground", gmesh)
	# distant mountains + water planes
	var sky: Dictionary = plan["sky"]
	if not sky.is_empty() and int(sky["mountains"]) > 0:
		var sk := sky.duplicate()
		if sk["haze"] == null:
			sk["haze"] = _haze_color()
		_mesh_child(root, root, "Mountains", Terrain.mountains(sk)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		layout_lines.append("sky mountains %d dist %.1f h %.1f seed %d" % [sk["mountains"], sk["dist"], sk["height"], sk["seed"]])
	for w: Dictionary in plan["waters"]:
		var full := Rect2(-sz.x * 0.5 - terrain.extend, -sz.y * 0.5 - terrain.extend, sz.x + 2.0 * terrain.extend, sz.y + 2.0 * terrain.extend)
		var wm := _mesh_child(root, root, "Water_%s" % w["name"], Terrain.water(w, full))
		wm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		layout_lines.append("water %s level %.2f" % [w["name"], w["level"]])
	# paths (one mesh: ember ribbons get an emissive surface)
	if not plan["paths"].is_empty():
		var pst := SurfaceTool.new()
		pst.begin(Mesh.PRIMITIVE_TRIANGLES)
		var est := SurfaceTool.new()
		est.begin(Mesh.PRIMITIVE_TRIANGLES)
		var ne := 0
		var np := 0
		for p: Dictionary in plan["paths"]:
			var col: Color = Kits.PATH_KITS[p["kit"]]
			if p["kit"] == "ember":
				FMesh.ribbon(est, p["poly"], p["width"], col, 0.035 + (0.06 if terrain.on else 0.0), int(plan["seed"]), gnd)
				ne += 1
			else:
				FMesh.ribbon(pst, p["poly"], p["width"], col, (0.02 if p["kit"] != "river" else 0.03) + (0.06 if terrain.on else 0.0), int(plan["seed"]), gnd)
				np += 1
			layout_lines.append("path %s %s %.3f" % [p["name"], str(p["poly"]), p["width"]])
		var pm := ArrayMesh.new()
		if np > 0:
			pm = pst.commit(pm)
			pm.surface_set_material(pm.get_surface_count() - 1, FMesh.vc_material(false, 0.9))
		if ne > 0:
			pm = est.commit(pm)
			pm.surface_set_material(pm.get_surface_count() - 1, FMesh.vc_material(true))
		_mesh_child(root, root, "Paths", pm)
	# walls + procedural props share one baked mesh (stone surface + glow surface)
	var wst := SurfaceTool.new()
	wst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glow := SurfaceTool.new()
	glow.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_stone := 0
	var n_glow := 0
	for w: Dictionary in plan["walls"]:
		var boxes := FMesh.wall(wst, w["poly"], w["height"], w["thick"], w["color"], w["gates"], int(plan["seed"]), gnd)
		n_stone += 1
		for b: Dictionary in boxes:
			obstacles.append({"name": "wall %s" % w["name"], "xf": b["xf"], "center": b["center"], "half": b["half"]})
		layout_lines.append("wall %s %s h%.2f t%.2f gates %d" % [w["name"], str(w["poly"]), w["height"], w["thick"], w["gates"].size()])
	# places
	var placed := Node3D.new()
	placed.name = "Placed"
	root.add_child(placed)
	placed.owner = root
	var bake := FMesh.new()
	var lights_off: Array[NodePath] = []
	var counts := {}
	for p: Dictionary in plan["places"]:
		var k: Dictionary = p["kit"]
		var yaw: float = p["yaw"] if not is_inf(p["yaw"]) else 0.0
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)).scaled(Vector3.ONE * float(p["scale"])), p["at"])
		layout_lines.append("place %s %s yaw %.2f s %.3f" % [k["name"], _v3(p["at"]), yaw, p["scale"]])
		if k["procedural"]:
			FMesh.prop(k["name"], wst, glow, xf, int(plan["seed"]))
			n_stone += 1
			n_glow += 0 if k["name"] == "crate" else 1
			obstacles.append({"name": k["name"], "aabb": AABB(xf.origin + Vector3(-0.45, 0, -0.45), Vector3(0.9, {"brazier": 1.4, "stake": 2.1, "crate": 0.9}.get(k["name"], 1.5), 0.9)), "tag": p["tag"]})
			continue
		var inst: Node3D = (load(k["path"]) as PackedScene).instantiate()
		if bool(p.get("row", false)) and FMesh.is_bakeable(inst) and p["tag"] == "":
			bake.add_node(inst, xf)
			var ab := _aabb_of(inst, xf)
			obstacles.append({"name": k["name"], "aabb": ab, "tag": ""})
			inst.free()
			continue
		counts[k["name"]] = int(counts.get(k["name"], 0)) + 1
		inst.name = p["tag"] if p["tag"] != "" else "%s_%d" % [k["name"], counts[k["name"]]]
		inst.transform = xf
		placed.add_child(inst)
		inst.owner = root
		if p["lights_off"]:
			lights_off.append(root.get_path_to(inst))
		var ab2 := _aabb_of(inst, Transform3D.IDENTITY)
		if float(p["radius"]) > 0.0:
			var r: float = p["radius"]
			ab2 = AABB(inst.global_position - Vector3(r, 0, r), Vector3(2 * r, maxf(ab2.size.y, 2.0), 2 * r))
		obstacles.append({"name": String(inst.name), "aabb": ab2, "tag": p["tag"]})
	# actors (puppets)
	var puppets := Node3D.new()
	puppets.name = "Puppets"
	root.add_child(puppets)
	puppets.owner = root
	for a: Dictionary in plan["actors"]:
		var inst: Node3D = (load(a["kit"]["path"]) as PackedScene).instantiate()
		inst.name = a["tag"]
		var yaw: float = a["yaw"] if not is_inf(a["yaw"]) else 0.0
		inst.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)).scaled(Vector3.ONE * float(a["scale"])), a["at"])
		puppets.add_child(inst)
		inst.owner = root
		if a["lights_off"]:
			lights_off.append(root.get_path_to(inst))
		layout_lines.append("actor %s %s yaw %.2f" % [a["tag"], _v3(a["at"]), yaw])
	root.set(&"lights_off", lights_off)
	# scatter (after everything it must avoid)
	for s: Dictionary in plan["scatters"]:
		_scatter(s, bake, wst, glow)
		if s["kit"]["procedural"]:
			n_stone += 1
			n_glow += 0 if s["kit"]["name"] == "crate" else 1
	var smesh := bake.commit()
	if smesh:
		_mesh_child(root, root, "Scatter", smesh)
	if n_stone > 0:
		var wm := wst.commit()
		wm.surface_set_material(0, FMesh.vc_material(false, 0.95))
		if n_glow > 0:
			glow.commit(wm)
			wm.surface_set_material(1, FMesh.vc_material(true))
		_mesh_child(root, root, "Masonry", wm)
	# marks
	var shots := Node3D.new()
	shots.name = "Shots"
	root.add_child(shots)
	shots.owner = root
	for m: Dictionary in plan["marks"]:
		for suffix: String in ["from", "to", "look_from", "look_to"]:
			var mk := Marker3D.new()
			mk.name = "%s_%s" % [m["shot"], suffix]
			mk.position = m[suffix]
			if suffix == "from":
				mk.set_meta(&"fov", m["fov_from"])
			elif suffix == "to":
				mk.set_meta(&"fov", m["fov_to"])
			shots.add_child(mk)
			mk.owner = root
		layout_lines.append("mark %s %s>%s look %s>%s fov %.1f>%.1f" % [m["shot"], _v3(m["from"]), _v3(m["to"]), _v3(m["look_from"]),
			_v3(m["look_to"]), m["fov_from"], m["fov_to"]])
	root.set(&"lighting", _lighting())
	root.call(&"refresh")
	return root


func _mesh_child(root: Node3D, parent: Node3D, nm: String, mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)
	mi.owner = root
	return mi


static func _v3(v: Vector3) -> String:
	return "(%.3f,%.3f,%.3f)" % [v.x, v.y, v.z]


## World AABB of the meshes under `n` (placed with `xf` when n is not in the tree).
static func _aabb_of(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	for c: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi.mesh == null:
			continue
		var local := Transform3D.IDENTITY
		var q: Node = mi
		while q != n and q != null:
			if q is Node3D:
				local = (q as Node3D).transform * local
			q = q.get_parent()
		var box := (xf * (n as Node3D).transform * local) * mi.mesh.get_aabb() if n.is_inside_tree() else (xf * local) * mi.mesh.get_aabb()
		if first:
			out = box
			first = false
		else:
			out = out.merge(box)
	if first:
		var o := (n as Node3D).global_position if n.is_inside_tree() else xf.origin
		out = AABB(o - Vector3(1, 0, 1), Vector3(2, 2, 2))
	return out


func _scatter(s: Dictionary, bake: FMesh, wst: SurfaceTool, glow: SurfaceTool) -> void:
	var k: Dictionary = s["kit"]
	var inst: Node3D = null
	var rad: float = s["radius"]
	if not k["procedural"]:
		inst = (load(k["path"]) as PackedScene).instantiate()
		if rad < 0.0:
			var ab := _aabb_of(inst, Transform3D.IDENTITY)
			rad = clampf(maxf(ab.size.x, ab.size.z) * 0.35, 0.3, 4.0)
	if rad < 0.0:
		rad = 0.5
	var r := RandomNumberGenerator.new()
	r.seed = int(s["seed"])
	var sz: Vector2 = plan["size"]
	var got := 0
	var tries := 0
	var mine: Array[Vector3] = []
	while got < int(s["count"]) and tries < int(s["count"]) * 60:
		tries += 1
		var p := Spec.area_sample(s["area"], r)
		var yaw := r.randf() * TAU
		var sc := r.randf_range(s["scale"].x, s["scale"].y)
		var tilt := r.randf_range(-1.0, 1.0) * deg_to_rad(float(s["tilt"]))
		if absf(p.x) > sz.x * 0.5 + terrain.extend - 0.5 or absf(p.z) > sz.y * 0.5 + terrain.extend - 0.5:
			continue
		if not _free_at(p, rad, float(s["gap"]), s["avoid"], mine):
			continue
		if terrain.on:
			if not plan["waters"].is_empty() and under_water(p):
				continue
			p.y = terrain.height_at(p.x, p.z) - 0.05
		mine.append(p)
		scatter_pts.append({"kit": k["name"], "pos": p, "r": rad})
		got += 1
		var xf := Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tilt), p).scaled_local(Vector3.ONE * sc)
		layout_lines.append("scatter %s %s yaw %.4f s %.4f" % [k["name"], _v3(p), yaw, sc])
		if k["procedural"]:
			FMesh.prop(k["name"], wst, glow, xf, int(s["seed"]))
		else:
			bake.add_node(inst, xf)
	if inst:
		inst.free()
	s["placed"] = got


func _free_at(p: Vector3, rad: float, gap: float, avoid: Array, mine: Array[Vector3]) -> bool:
	for q in mine:
		if Vector2(p.x - q.x, p.z - q.z).length() < gap:
			return false
	for q: Dictionary in scatter_pts:
		if Vector2(p.x - q["pos"].x, p.z - q["pos"].z).length() < rad + float(q["r"]):
			return false
	for o: Dictionary in obstacles:
		if o.has("aabb"):
			var ab: AABB = (o["aabb"] as AABB).grow(rad + 0.3)
			if p.x > ab.position.x and p.x < ab.end.x and p.z > ab.position.z and p.z < ab.end.z:
				return false
		else:
			var lp: Vector3 = (o["xf"] as Transform3D).affine_inverse() * p - (o["center"] as Vector3)
			var h: Vector3 = o["half"]
			if absf(lp.x) < h.x + rad + 0.3 and absf(lp.z) < h.z + rad + 0.3:
				return false
	for a: Dictionary in plan["actors"]:
		if Vector2(p.x - a["at"].x, p.z - a["at"].z).length() < rad + 1.2:
			return false
	for pa: Dictionary in plan["paths"]:
		if _dist_poly(p, pa["poly"]) < float(pa["width"]) * 0.5 + rad * 0.6:
			return false
	for av: String in avoid:
		if plan["zones"].has(av) and Spec.area_has(plan["zones"][av], p):
			return false
		if av == "cams" or av == "marks":
			for m: Dictionary in plan["marks"]:
				if _dist_seg(p, m["from"], m["look_from"]) < rad + 1.2 or _dist_seg(p, m["to"], m["look_to"]) < rad + 1.2:
					return false
	return true


static func _dist_seg(p: Vector3, a: Vector3, b: Vector3) -> float:
	var q := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), Vector2(a.x, a.z), Vector2(b.x, b.z))
	return q.distance_to(Vector2(p.x, p.z))


static func _dist_poly(p: Vector3, poly: PackedVector3Array) -> float:
	var best := INF
	for i in range(poly.size() - 1):
		best = minf(best, _dist_seg(p, poly[i], poly[i + 1]))
	return best


# ---------------------------------------------------------------- lighting

func _lighting() -> LightingPreset:
	var lp := _base_lighting()
	var sky: Dictionary = plan["sky"]
	if lp == null or sky.is_empty() or (sky["top"] == null and sky["horizon"] == null):
		return lp
	# `sky top= / horizon=`: a copy of the preset with the procedural sky retinted (shared presets stay untouched)
	var env := lp.environment
	if env == null or env.sky == null or not env.sky.sky_material is ProceduralSkyMaterial:
		spec.warn(int(sky["line"]), "sky", "top= / horizon= need a procedural sky (this light preset has none): ignored")
		return lp
	var out := lp.duplicate() as LightingPreset
	var env2 := env.duplicate() as Environment
	var sky2 := env.sky.duplicate() as Sky
	var mat := env.sky.sky_material.duplicate() as ProceduralSkyMaterial
	if sky["top"] != null:
		mat.sky_top_color = sky["top"]
	if sky["horizon"] != null:
		mat.sky_horizon_color = sky["horizon"]
		mat.ground_horizon_color = (sky["horizon"] as Color).darkened(0.5)
		env2.fog_light_color = (sky["horizon"] as Color).darkened(0.3)
	sky2.sky_material = mat
	env2.sky = sky2
	out.environment = env2
	return out


## The horizon colour of the set's sky (mountain haze default).
func _haze_color() -> Color:
	var sky: Dictionary = plan["sky"]
	if not sky.is_empty() and sky["horizon"] != null:
		return sky["horizon"]
	var lp := _base_lighting()
	if lp and lp.environment and lp.environment.sky and lp.environment.sky.sky_material is ProceduralSkyMaterial:
		return (lp.environment.sky.sky_material as ProceduralSkyMaterial).sky_horizon_color
	return Color(0.62, 0.64, 0.70)


func _base_lighting() -> LightingPreset:
	var l: String = plan["light"]
	if l.begins_with("res://"):
		return load(l) as LightingPreset
	if l == "warm" or l == "ice":
		return LightingRig.load_preset(StringName(l))
	return mood_preset(l)


## Generated moods (night / dusk / storm / crypt / dawn): an Environment with a procedural sky + sun and fill.
static func mood_preset(mood: String) -> LightingPreset:
	var t := {
		"nightfall": {"top": Color(0.05, 0.07, 0.16), "hor": Color(0.55, 0.30, 0.22), "gnd": Color(0.05, 0.04, 0.05),
			"sun": Color(1.0, 0.52, 0.28), "se": 0.55, "rot": Vector3(-9, 55, 0), "fill": Color(0.35, 0.45, 0.9), "fe": 0.42,
			"amb": 0.55, "fog": Color(0.22, 0.18, 0.24), "fd": 0.006, "exp": 1.05, "vig": 0.45},
		"dusk": {"top": Color(0.16, 0.18, 0.36), "hor": Color(0.95, 0.55, 0.32), "gnd": Color(0.1, 0.08, 0.07),
			"sun": Color(1.0, 0.62, 0.38), "se": 0.95, "rot": Vector3(-14, 50, 0), "fill": Color(0.45, 0.5, 0.9), "fe": 0.3,
			"amb": 0.6, "fog": Color(0.5, 0.38, 0.35), "fd": 0.004, "exp": 1.0, "vig": 0.38},
		"storm": {"top": Color(0.12, 0.13, 0.17), "hor": Color(0.32, 0.34, 0.38), "gnd": Color(0.08, 0.08, 0.09),
			"sun": Color(0.75, 0.8, 0.95), "se": 0.5, "rot": Vector3(-40, 20, 0), "fill": Color(0.5, 0.55, 0.7), "fe": 0.35,
			"amb": 0.7, "fog": Color(0.3, 0.32, 0.36), "fd": 0.012, "exp": 1.0, "vig": 0.45},
		"crypt": {"top": Color(0.04, 0.04, 0.06), "hor": Color(0.12, 0.10, 0.14), "gnd": Color(0.03, 0.03, 0.04),
			"sun": Color(0.55, 0.6, 0.85), "se": 0.35, "rot": Vector3(-60, 30, 0), "fill": Color(0.5, 0.35, 0.7), "fe": 0.3,
			"amb": 0.5, "fog": Color(0.1, 0.09, 0.13), "fd": 0.015, "exp": 1.1, "vig": 0.55},
		"dawn": {"top": Color(0.3, 0.42, 0.66), "hor": Color(0.98, 0.78, 0.58), "gnd": Color(0.15, 0.13, 0.1),
			"sun": Color(1.0, 0.8, 0.6), "se": 1.0, "rot": Vector3(-16, -60, 0), "fill": Color(0.5, 0.6, 0.95), "fe": 0.25,
			"amb": 0.7, "fog": Color(0.75, 0.68, 0.62), "fd": 0.003, "exp": 1.0, "vig": 0.3},
	}
	var d: Dictionary = t.get(mood, t["dusk"])
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = d["top"]
	sky_mat.sky_horizon_color = d["hor"]
	sky_mat.ground_horizon_color = (d["hor"] as Color).darkened(0.5)
	sky_mat.ground_bottom_color = d["gnd"]
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = d["amb"]
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = d["exp"]
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = d["fog"]
	env.fog_density = d["fd"]
	env.fog_sky_affect = 0.3
	var p := LightingPreset.new()
	p.environment = env
	p.sun_color = d["sun"]
	p.sun_energy = d["se"]
	p.sun_rotation_degrees = d["rot"]
	p.fill_color = d["fill"]
	p.fill_energy = d["fe"]
	p.vignette_strength = d["vig"]
	p.vignette_color = Color(0.04, 0.03, 0.06)
	p.haze_strength = 0.0
	return p


# ---------------------------------------------------------------- save

## Saves meshes, lighting, scene and marks.json into the set folder. Returns the scene path.
func save(root: Node3D) -> String:
	var dir := set_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir + "/meshes"))
	var names: Array[String] = ["Ground", "Paths", "Scatter", "Masonry", "Mountains"]
	for w: Dictionary in plan["waters"]:
		names.append("Water_%s" % w["name"])
	var cs := root.get_node_or_null(^"TerrainBody/Shape") as CollisionShape3D
	if cs and cs.shape:
		var sp := "%s/meshes/terrain_shape.res" % dir
		ResourceSaver.save(cs.shape, sp, ResourceSaver.FLAG_COMPRESS)
		cs.shape.take_over_path(sp)
		report.files.append(sp)
	for nm: String in names:
		var mi := root.get_node_or_null(nm) as MeshInstance3D
		if mi and mi.mesh:
			var mp := "%s/meshes/%s.res" % [dir, nm.to_lower()]
			ResourceSaver.save(mi.mesh, mp, ResourceSaver.FLAG_COMPRESS)
			mi.mesh.take_over_path(mp)
			report.files.append(mp)
	var lp: LightingPreset = root.get(&"lighting")
	if lp and lp.resource_path == "":
		var lpath := "%s/%s_lighting.tres" % [dir, plan["id"]]
		ResourceSaver.save(lp, lpath)
		lp.take_over_path(lpath)
		report.files.append(lpath)
	var ps := PackedScene.new()
	var e := ps.pack(root)
	var spath := "%s/%s.tscn" % [dir, plan["id"]]
	if e == OK:
		e = ResourceSaver.save(ps, spath)
	if e != OK:
		report.fcheck("S2", "Scene saved", "FAIL", "error %d" % e, "the set scene packs and saves", "report this to the World Forge owner")
	report.files.push_front(spath)
	var marks := {}
	for m: Dictionary in plan["marks"]:
		marks[m["shot"]] = {"from": _arr(m["from"]), "to": _arr(m["to"]), "look_from": _arr(m["look_from"]),
			"look_to": _arr(m["look_to"]), "fov_from": m["fov_from"], "fov_to": m["fov_to"], "subject": m["subject"],
			"dur": m["dur"], "lens": m["lens"]}
	var f := FileAccess.open(dir + "/marks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(marks, "\t", false))
	f.close()
	report.files.append(dir + "/marks.json")
	return spath


static func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]


func layout_hash() -> String:
	return "\n".join(layout_lines).md5_text().substr(0, 12)

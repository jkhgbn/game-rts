extends RefCounted
## World Forge map grammar v2 (docs/design/map-production.md 2.2, tool task MT3): turns a `.map` file into the flat
## statement list `forge_map.gd` compiles. It resolves
## - `map <id> base=<map> variant=<v>`: the base map's statements first (recursively), then this file's; the `map`
##   line merges (this file's keys win; `base` / `variant` are kept for the layout);
## - `use <template> [<prefix>] at=(x,z) yaw=<deg> | face=center mirror=x key=value...`: the template
##   `data/maps/templates/<template>.mapt` (a `.map` fragment in its own frame: (0,0) = the anchor, +z toward the map
##   centre; `param <name>=<default>` lines; `$name` placeholders) is substituted, turned and moved onto `at`, and its
##   ids get `<prefix>_` (default: the template name);
## - overlay edits on the canonical statements: `remove <spot id>`, `move <spot id> at=(x,z)`.
## Statements from other files keep {file, line} and carry `via` (the line of this file that pulled them in), so
## errors name both. No class_name on purpose (preloaded tool script).

const Spec := preload("res://tools/world_forge/forge_spec.gd")

const TEMPLATES_DIR := "res://data/maps/templates"
const MAPS_DIR := "res://data/maps"
const MAX_DEPTH := 6
## Keys whose value is a ground point (moved with the template), a direction (turned only) or a polyline.
const POINT_KEYS: Array[String] = ["at", "center", "from", "to", "door"]
const DIR_KEYS: Array[String] = ["dir"]
const POLY_KEYS: Array[String] = ["poly", "lane"]
## Statements whose first argument is an id that a template prefix renames.
const ID_STATEMENTS: Array[String] = ["keep", "node", "point", "camp", "tavern", "post", "guild", "peddler", "cache",
	"lair", "crown", "start", "slot", "river", "crossing", "road", "zone", "block", "grove", "prop", "mark", "trigger",
	"path", "hill", "ridge", "valley", "pad"]

var spec: Spec                 ## the main file's spec (errors land here)
var sources: Array[String] = []   ## every file read (main, bases, templates), for the layout hash
var texts: Array[String] = []
var templates_used: Array[String] = []
var _use_count := {}


func _init(p_spec: Spec) -> void:
	spec = p_spec


## The statement list of `path` with bases, templates and overlay edits resolved ([] + errors on bad input).
func expand(path: String) -> Array:
	var sts := spec.read_file(path)
	if not spec.ok():
		return []
	sources.append(path)
	texts.append(FileAccess.get_file_as_string(path))
	return _resolve(sts, path, 0, -1)


func _resolve(sts: Array, path: String, depth: int, via: int) -> Array:
	var out: Array = []
	var head: Dictionary = {}
	for st: Dictionary in sts:
		if via >= 0:
			st["via"] = via
			st["file"] = path
		if st["kw"] == "map" and head.is_empty():
			head = st
	# base map first
	if not head.is_empty() and (head["kv"] as Dictionary).has("base"):
		var bname := String(head["kv"]["base"])
		var bpath := bname if bname.contains("://") else "%s/%s.map" % [MAPS_DIR, bname]
		if depth >= MAX_DEPTH:
			_err(head, bname, "base maps nest too deep (max %d)" % MAX_DEPTH)
		elif not FileAccess.file_exists(bpath):
			_err(head, bname, "base map %s not found" % bpath)
		else:
			var sub := Spec.new()
			var bsts := sub.read_file(bpath)
			_take_errors(sub)
			sources.append(bpath)
			texts.append(FileAccess.get_file_as_string(bpath))
			var resolved := _resolve(bsts, bpath, depth + 1, int(head["line"]) if via < 0 else via)
			# the base's map line merges into ours (ours wins)
			for b: Dictionary in resolved:
				if b["kw"] == "map":
					var kv: Dictionary = (b["kv"] as Dictionary).duplicate()
					for k: String in head["kv"]:
						kv[k] = head["kv"][k]
					kv["base"] = bname
					head["kv"] = kv
					continue
				out.append(b)
	var edits: Array = []
	var own: Array = []
	for st: Dictionary in sts:
		match String(st["kw"]):
			"use":
				own.append_array(_use(st, depth, path))
			"remove", "move", "set":
				edits.append(st)
			_:
				own.append(st)
	# the map line goes first
	var final: Array = []
	if not head.is_empty():
		final.append(head)
	final.append_array(out)
	for st: Dictionary in own:
		if st != head:
			final.append(st)
	for e: Dictionary in edits:
		_apply_edit(final, e)
	return final


func _apply_edit(sts: Array, e: Dictionary) -> void:
	if (e["args"] as Array).is_empty():
		_err(e, String(e["kw"]), "%s wants a spot id: %s <id>%s" % [e["kw"], e["kw"], " at=(x,z)" if e["kw"] == "move" else ""])
		return
	var sid := String(e["args"][0])
	for i in sts.size():
		var st: Dictionary = sts[i]
		if not ID_STATEMENTS.has(String(st["kw"])) or (st["args"] as Array).is_empty() or String(st["args"][0]) != sid:
			continue
		if e["kw"] == "remove":
			sts.remove_at(i)
		elif e["kw"] == "set":
			var kv2: Dictionary = (st["kv"] as Dictionary).duplicate()
			for k: String in e["kv"]:
				kv2[k] = e["kv"][k]
			st["kv"] = kv2
		else:
			if not (e["kv"] as Dictionary).has("at"):
				_err(e, sid, "move wants at=(x,z)")
				return
			var kv: Dictionary = (st["kv"] as Dictionary).duplicate()
			kv["at"] = e["kv"]["at"]
			st["kv"] = kv
		return
	_err(e, sid, "%s: no statement with id \"%s\" (ids are the canonical ones, before mirroring)" % [e["kw"], sid])


# ---------------------------------------------------------------- templates

func _use(st: Dictionary, depth: int, from_path: String) -> Array:
	var args: Array = st["args"]
	if args.is_empty():
		_err(st, "use", "use wants a template: use <template> [<prefix>] at=(x,z)")
		return []
	var tname := String(args[0])
	var tpath := "%s/%s.mapt" % [TEMPLATES_DIR, tname]
	if not FileAccess.file_exists(tpath):
		_err(st, tname, "unknown template \"%s\" (%s)" % [tname, tpath], list_templates())
		return []
	if depth >= MAX_DEPTH:
		_err(st, tname, "templates nest too deep (max %d)" % MAX_DEPTH)
		return []
	var n := int(_use_count.get(tname, 0))
	_use_count[tname] = n + 1
	var prefix := String(args[1]) if args.size() > 1 and args[1] != "solo" else (tname if n == 0 else "%s%d" % [tname, n + 1])
	var at: Variant = Spec.parse_vec(String(st["kv"].get("at", "(0,0)")))
	if at == null:
		_err(st, String(st["kv"].get("at", "")), "use: at= wants (x,z)")
		return []
	var anchor: Vector3 = at
	# yaw: explicit, else the local +z faces the map centre (face=center, the default), face=none = 0
	var yaw := 0.0
	if (st["kv"] as Dictionary).has("yaw"):
		yaw = deg_to_rad(String(st["kv"]["yaw"]).to_float())
	elif String(st["kv"].get("face", "center")) == "center" and Vector2(anchor.x, anchor.z).length() > 0.01:
		yaw = atan2(-anchor.x, -anchor.z)
	var mirror := String(st["kv"].get("mirror", "none")) == "x"
	var text := FileAccess.get_file_as_string(tpath)
	sources.append(tpath)
	# params: defaults from `param name=value`, overridden by the use line's other keys
	var params := {}
	var pre := Spec.new()
	for p: Dictionary in pre.read_text(text, tpath):
		if p["kw"] == "param":
			for k: String in p["kv"]:
				params[k] = String(p["kv"][k])
	for k: String in st["kv"]:
		if not k in ["at", "yaw", "face", "mirror"]:
			if not params.has(k):
				_err(st, k, "template %s has no param \"%s\"" % [tname, k], params.keys())
				continue
			params[k] = String(st["kv"][k])
	var keys: Array = params.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	for k: String in keys:
		text = text.replace("${%s}" % k, String(params[k])).replace("$" + k, String(params[k]))
	texts.append(text)
	var sub := Spec.new()
	var tsts := sub.read_text(text, tpath)
	_take_errors(sub)
	var basis := Basis(Vector3.UP, yaw)
	var flip := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)) if mirror else Basis()
	var xf := Transform3D(basis * flip, Vector3(anchor.x, 0.0, anchor.z))
	var out: Array = []
	var resolved := _resolve(tsts, tpath, depth + 1, int(st.get("via", st["line"])))
	for t: Dictionary in resolved:
		if t["kw"] in ["template", "param", "map"]:
			continue
		var moved := xform_statement(t, xf, rad_to_deg(yaw), mirror, prefix)
		# review M3: the template group (the outermost `use` wins) and whether this member is its anchor (local (0,0)),
		# so the fix verb moves a whole expansion (node + hall / tower slots) when its anchor spot moves
		var local: Variant = Spec.parse_vec(String((t["kv"] as Dictionary).get("at", "")))
		moved["use_group"] = "%s@%d" % [prefix, int(st.get("via", st["line"]))]
		moved["use_anchor"] = local != null and Vector2((local as Vector3).x, (local as Vector3).z).length() < 0.01
		out.append(moved)
	templates_used.append("%s %s at (%.1f, %.1f) yaw %.0f%s" % [tname, prefix, anchor.x, anchor.z, rad_to_deg(yaw), " mirror x" if mirror else ""])
	return out


## Every template id in data/maps/templates (for "did you mean" and the help).
static func list_templates() -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(TEMPLATES_DIR)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".mapt"):
			out.append(f.get_basename())
	out.sort()
	return out


## One statement moved by `xf` (rotation about y, optional mirror, translation): points, directions, polylines,
## areas, block / prop yaw; ids (and `twin=`) get `<prefix>_`.
static func xform_statement(t: Dictionary, xf: Transform3D, yaw_deg: float, mirror: bool, prefix: String) -> Dictionary:
	var st := t.duplicate(true)
	var kv: Dictionary = st["kv"]
	for k: String in kv.keys():
		var v := String(kv[k])
		if POINT_KEYS.has(k):
			var p: Variant = Spec.parse_vec(v)
			if p != null:
				kv[k] = _fmt(xf * (p as Vector3))
		elif DIR_KEYS.has(k):
			var d: Variant = Spec.parse_vec(v)
			if d != null:
				kv[k] = _fmt(xf.basis * (d as Vector3))
		elif POLY_KEYS.has(k):
			var poly: Variant = Spec.parse_poly(v)
			if poly != null:
				var pts: Array[String] = []
				for q: Vector3 in poly:
					pts.append(_fmt(xf * q))
				kv[k] = "[%s]" % ",".join(pts)
		elif k == "yaw" and st["kw"] in ["block", "prop"]:
			var y := v.to_float()
			kv[k] = "%.3f" % ((-y if mirror else y) + yaw_deg)
		elif k == "twin" and prefix != "":
			kv[k] = "%s_%s" % [prefix, v]
	var args: Array = st["args"]
	if ID_STATEMENTS.has(String(st["kw"])) and not args.is_empty() and prefix != "":
		args[0] = "%s_%s" % [prefix, args[0]]
	# zone / trigger areas: the second argument
	if st["kw"] in ["zone", "trigger"] and args.size() > 1:
		var a: Variant = Spec.parse_area(String(args[1]))
		if a != null:
			args[1] = area_text(xform_area(a, xf))
	return st


static func xform_area(a: Dictionary, xf: Transform3D) -> Dictionary:
	var out := a.duplicate()
	if out.has("center"):
		out["center"] = xf * (out["center"] as Vector3)
	else:
		var lo: Vector3 = out["min"]
		var hi: Vector3 = out["max"]
		var pts: Array[Vector3] = [xf * lo, xf * hi, xf * Vector3(lo.x, 0, hi.z), xf * Vector3(hi.x, 0, lo.z)]
		var mn := Vector3(INF, 0, INF)
		var mx := Vector3(-INF, 0, -INF)
		for p in pts:
			mn = Vector3(minf(mn.x, p.x), 0, minf(mn.z, p.z))
			mx = Vector3(maxf(mx.x, p.x), 0, maxf(mx.z, p.z))
		out["min"] = mn
		out["max"] = mx
	return out


static func area_text(a: Dictionary) -> String:
	match String(a["kind"]):
		"circle":
			return "circle(%s,%.3f)" % [_fmt(a["center"]), float(a["r1"])]
		"ring":
			return "ring(%s,%.3f..%.3f)" % [_fmt(a["center"]), float(a["r0"]), float(a["r1"])]
	return "rect(%s,%s)" % [_fmt(a["min"]), _fmt(a["max"])]


static func _fmt(p: Vector3) -> String:
	return "(%.3f,%.3f)" % [snappedf(p.x, 0.001), snappedf(p.z, 0.001)]


# ---------------------------------------------------------------- errors

func _err(st: Dictionary, token: String, msg: String, choices: Array = []) -> void:
	var m := msg
	if st.has("file"):
		m = "%s:%d: %s" % [String(st["file"]).get_file(), int(st["line"]), msg]
	spec.err(int(st.get("via", st["line"])), token, m, choices)


func _take_errors(sub: Spec) -> void:
	for e: Dictionary in sub.errors:
		spec.ts.errors.append(e)
	for w: Dictionary in sub.warnings:
		spec.ts.warnings.append(w)


## md5 of every file text the layout came from (12 hex chars).
func hash_text() -> String:
	return "\n".join(texts).md5_text().substr(0, 12)

class_name LensDoc
extends RefCounted
## Reads a `.lens` spec (tools/lens/specs/<id>.lens) with the shared ToolSpec reader and validates it. Grammar table:
## tools/lens/README.md. Errors name file, line, token and the nearest valid value.

const SPECS_DIR := "res://tools/lens/specs/"
const KEYWORDS := ["lens", "use", "subject", "cast", "shot", "icons", "portrait"]
const SHOT_CHILDREN := ["frame", "subject", "cast", "light", "bg", "out"]
const LIGHTS := ["studio", "warm", "ice", "dusk", "night", "set"]
const RIMS := ["warm", "cool", "off"]
const FACTIONS := ["fire", "ice", "nature", "shadow", "neutral"]

var spec: ToolSpec
var id := ""
var header := {"res": [Vector2i(1600, 900)], "band": 2.39, "fov": 40.0, "light": "studio", "rim": "warm", "bg": {"kind": "flat", "value": "#1b1a1f"}}
var subjects: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var icons: Array[Dictionary] = []
var portraits: Array[Dictionary] = []
var set_override := ""


static func source_of(id_or_path: String) -> String:
	if id_or_path.begins_with("res://") or id_or_path.ends_with(".lens"):
		return id_or_path if id_or_path.begins_with("res://") else "res://" + id_or_path.replace("\\", "/")
	return SPECS_DIR + id_or_path + ".lens"


## `set_override` (marks verb): every shot is staged on that set, its puppets are valid subjects.
static func load_file(path: String, set_override: String = "") -> LensDoc:
	var d := LensDoc.new()
	d.set_override = set_override
	d.id = path.get_file().get_basename()
	if not FileAccess.file_exists(path):
		d.spec = ToolSpec.parse_text("", path)
		var ids: Array = []
		for f: String in DirAccess.get_files_at(SPECS_DIR):
			if f.ends_with(".lens"):
				ids.append(f.get_basename())
		var n := ToolSpec.nearest(d.id, ids)
		d.spec.errors.append({"file": path, "line": 0, "token": d.id, "message": "no spec file \"%s\"" % path,
			"hint": ("did you mean \"%s\"? " % n if n != "" else "") + "specs: " + ", ".join(PackedStringArray(ids)), "text": ""})
		return d
	d.spec = ToolSpec.parse_file(path)
	d._read()
	return d


static func from_text(text: String, name: String = "<text>") -> LensDoc:
	var d := LensDoc.new()
	d.id = name.get_file().get_basename()
	d.spec = ToolSpec.parse_text(text, name)
	d._read()
	return d


func ok() -> bool:
	return spec.ok()


func subject_tags(shot: Dictionary = {}) -> Array:
	var out: Array = []
	for s: Dictionary in subjects:
		out.append(s["tag"])
	for s2: Dictionary in shot.get("subjects", []):
		if not s2["tag"] in out:
			out.append(s2["tag"])
	return out


func shot(shot_id: String) -> Dictionary:
	for s: Dictionary in shots:
		if s["id"] == shot_id:
			return s
	return {}


func _read() -> void:
	for l: ToolSpecLine in spec.lines:
		match l.keyword:
			"lens":
				spec.check_keys(l, ["res", "band", "fov", "light", "rim", "bg"])
				_header(l)
			"use":
				spec.check_keys(l, ["cine"])
				_use(l)
			"subject", "cast":
				var s := _subject(l)
				if not s.is_empty():
					subjects.append(s)
			"shot":
				_shot(l)
			"icons":
				_icons(l)
			"portrait":
				_portrait(l)
			_:
				spec.error(l, l.keyword, "unknown keyword \"%s\"" % l.keyword, KEYWORDS)
	# words are checked once every subject is known
	for s: Dictionary in shots:
		var known := subject_tags(s)
		if s.has("set") and String(s["set"]) != "":
			for t: String in _set_puppets(String(s["set"])):
				if not t in known:
					known.append(t)
		var w := LensSolver.parse_words(String(s["words"]), known)
		for e: Dictionary in w["errors"]:
			spec.error(s["_line"], String(e["token"]), "%s (%s)" % [e["message"], e["hint"]])
		s["parsed"] = w


func _header(l: ToolSpecLine) -> void:
	if l.arg(0) != "" and l.arg(0) != id and not spec.path.begins_with("<"):
		spec.warn(l, l.arg(0), "the header id \"%s\" differs from the file name \"%s\": outputs use the file name" % [l.arg(0), id],
			"rename the file or the header")
	_common(l, header)


func _common(l: ToolSpecLine, into: Dictionary) -> void:
	if l.has("res"):
		var sizes: Array = []
		for part: String in l.get_str("res").split(",", false):
			var v := _size(l, part)
			if v != Vector2i.ZERO:
				sizes.append(v)
		if not sizes.is_empty():
			into["res"] = sizes
	for k: String in ["band", "fov"]:
		if l.has(k):
			if not l.get_str(k).is_valid_float():
				spec.error(l, l.get_str(k), "%s= wants a number" % k)
			else:
				into[k] = l.get_float(k)
	if l.has("light"):
		if spec.expect_one_of(l, l.get_str("light"), LIGHTS, "light preset"):
			into["light"] = l.get_str("light")
	if l.has("rim"):
		if spec.expect_one_of(l, l.get_str("rim"), RIMS, "rim"):
			into["rim"] = l.get_str("rim")
	if l.has("bg"):
		into["bg"] = _bg_value(l, l.get_str("bg"))


func _size(l: ToolSpecLine, s: String) -> Vector2i:
	var p := s.to_lower().split("x")
	if p.size() != 2 or not p[0].is_valid_int() or not p[1].is_valid_int():
		spec.error(l, s, "resolution wants WxH (e.g. 1600x900)")
		return Vector2i.ZERO
	return Vector2i(p[0].to_int(), p[1].to_int())


func _bg_value(l: ToolSpecLine, v: String) -> Dictionary:
	if v.begins_with("#"):
		if ToolSpec.color_of(v) == null:
			spec.error(l, v, "bad colour (use #rgb or #rrggbb)")
		return {"kind": "flat", "value": v}
	var kv := v.split(":", false, 1)
	if kv.size() == 2 and kv[0] in ["flat", "ground", "set"]:
		if kv[0] == "set":
			_check_set(l, kv[1])
		return {"kind": kv[0], "value": kv[1]}
	if v in ["kingdom", "none", "flat"]:
		return {"kind": v, "value": ""}
	spec.error(l, v, "unknown background \"%s\"" % v, ["#1b1a1f", "ground:#3a3328", "set:<set_id>", "kingdom", "none"])
	return {"kind": "flat", "value": "#1b1a1f"}


static func set_scene_path(set_id: String) -> String:
	return "res://art/cinematics/stage_sets/%s/%s.tscn" % [set_id, set_id]


func _check_set(l: ToolSpecLine, set_id: String) -> void:
	if not ResourceLoader.exists(set_scene_path(set_id)):
		var sets: Array = []
		for d: String in DirAccess.get_directories_at("res://art/cinematics/stage_sets"):
			if ResourceLoader.exists(set_scene_path(d)):
				sets.append(d)
		spec.error(l, set_id, "no stage set \"%s\" (%s)" % [set_id, set_scene_path(set_id)], sets)


## Puppet tags of a set scene, read from the .tscn text (no instancing): nodes under "Puppets".
static func _set_puppets(set_id: String) -> Array:
	var out: Array = []
	var p := set_scene_path(set_id)
	if not FileAccess.file_exists(p):
		return out
	for line: String in FileAccess.get_file_as_string(p).split("\n"):
		if line.begins_with("[node name=\"") and "parent=\"Puppets\"" in line:
			out.append(line.get_slice("\"", 1).to_lower())
	return out


func _use(l: ToolSpecLine) -> void:
	var path := l.get_str("cine", l.arg(0))
	if path == "" or not FileAccess.file_exists(path):
		spec.error(l, path, "use wants cine=res://path/to.cine (an existing file); its `cast` lines become subjects")
		return
	var cs := ToolSpec.parse_file(path)
	for cl: ToolSpecLine in cs.all_lines:
		if cl.keyword == "cast" and cl.arg(1).begins_with("res://"):
			var s := {"tag": cl.arg(0).to_lower(), "res": cl.arg(1), "at": _vec(cl, "at", Vector3.ZERO), "yaw": cl.get_float("yaw", 0.0),
				"scale": cl.get_float("scale", 1.0), "pose": "", "pose_arg": "", "pose_t": 0.0, "line": l.line, "_line": l}
			subjects.append(s)


func _vec(l: ToolSpecLine, k: String, d: Vector3) -> Vector3:
	if not l.has(k):
		return d
	var v: Variant = ToolSpec.vec_of(l.get_str(k))
	if v is Vector3:
		return v
	if v is Vector2:
		return Vector3((v as Vector2).x, 0, (v as Vector2).y)
	spec.error(l, l.get_str(k), "%s= wants (x,y,z) or (x,z)" % k)
	return d


func _subject(l: ToolSpecLine) -> Dictionary:
	spec.check_keys(l, ["at", "yaw", "pose", "scale"])
	var tag := l.arg(0).to_lower()
	var res := l.arg(1)
	if tag == "" or not tag.is_valid_identifier():
		spec.error(l, tag, "subject wants: subject <tag> <res://scene.tscn> at=(x,y,z) yaw=<deg>")
		return {}
	if not res.begins_with("res://") or not ResourceLoader.exists(res):
		spec.error(l, res, "model scene not found \"%s\"" % res, _near_files(res))
		return {}
	var s := {"tag": tag, "res": res, "at": _vec(l, "at", Vector3.ZERO), "yaw": l.get_float("yaw", 0.0),
		"scale": l.get_float("scale", 1.0), "pose": "", "pose_arg": "", "pose_t": 0.0, "line": l.line, "_line": l}
	if l.has("pose"):
		# pose=<hook>[:<arg>]@<seconds>   e.g. pose=play_cast:fireball@0.35
		var pv := l.get_str("pose")
		var at := pv.get_slice("@", 1) if "@" in pv else "0"
		var hk := pv.get_slice("@", 0)
		s["pose"] = hk.get_slice(":", 0)
		s["pose_arg"] = hk.get_slice(":", 1) if ":" in hk else ""
		s["pose_t"] = at.to_float()
		if not String(s["pose"]).begins_with("play_") and not String(s["pose"]).begins_with("set_"):
			spec.error(l, pv, "pose wants <hook>[:<arg>]@<seconds> with a model hook (play_cast, play_attack, play_hit...)",
				["play_cast:fireball@0.35", "play_attack@0.2"])
	return s


## Candidate files near a wrong res:// path (same folder, else same file name anywhere under art/).
static func _near_files(res: String) -> Array:
	var dir := res.get_base_dir()
	var out: Array = []
	if DirAccess.dir_exists_absolute(dir):
		for f: String in DirAccess.get_files_at(dir):
			if f.ends_with(".tscn"):
				out.append(dir + "/" + f)
	return out


func _shot(l: ToolSpecLine) -> void:
	spec.check_keys(l, ["res", "band", "fov", "light", "rim", "bg"])
	var sid := l.arg(0)
	if sid == "" or not sid.is_valid_identifier():
		spec.error(l, sid, "shot wants an identifier id: shot <id> \"<framing words>\"")
		return
	var s := {"id": sid, "words": l.arg(1), "res": header["res"], "band": header["band"], "fov": header["fov"],
		"light": header["light"], "rim": header["rim"], "bg": header["bg"], "subjects": [], "set": "", "line": l.line, "_line": l}
	_common(l, s)
	for c: ToolSpecLine in l.children:
		match c.keyword:
			"frame":
				spec.check_keys(c, ["angle", "height", "comp", "lead", "dutch", "push", "truck", "crane", "arc", "fov"])
				var parts: PackedStringArray = [" ".join(c.args)]
				for k: String in c.kv_order:
					var v := c.get_str(k)
					match k:
						"angle", "height", "comp":
							parts.append(v if not v.is_valid_float() else "%s=%s" % [k, v])
						"lead":
							parts.append("lead-" + v)
						_:
							parts.append("%s=%s" % [k, v])
				s["words"] = ", ".join(parts)
			"subject", "cast":
				var sub := _subject(c)
				if not sub.is_empty():
					(s["subjects"] as Array).append(sub)
			"light":
				spec.check_keys(c, ["preset", "rim"])
				if c.has("preset") and spec.expect_one_of(c, c.get_str("preset"), LIGHTS, "light preset"):
					s["light"] = c.get_str("preset")
				if c.has("rim") and spec.expect_one_of(c, c.get_str("rim"), RIMS, "rim"):
					s["rim"] = c.get_str("rim")
			"bg":
				spec.check_keys(c, ["flat", "ground", "set"])
				if c.has("set"):
					s["bg"] = {"kind": "set", "value": c.get_str("set")}
					_check_set(c, c.get_str("set"))
				elif c.has("ground"):
					s["bg"] = {"kind": "ground", "value": c.get_str("ground")}
				elif c.has("flat"):
					s["bg"] = {"kind": "flat", "value": c.get_str("flat")}
				elif c.arg(0) != "":
					s["bg"] = _bg_value(c, c.arg(0))
			"out":
				spec.check_keys(c, ["band"])
				var sizes: Array = []
				for a: String in c.args:
					var v2 := _size(c, a)
					if v2 != Vector2i.ZERO:
						sizes.append(v2)
				if not sizes.is_empty():
					s["res"] = sizes
				if c.has("band"):
					s["band"] = c.get_float("band", 2.39)
			_:
				spec.error(c, c.keyword, "unknown shot line \"%s\"" % c.keyword, SHOT_CHILDREN)
	if (s["bg"] as Dictionary).get("kind", "") == "set":
		s["set"] = s["bg"]["value"]
	if set_override != "":
		s["set"] = set_override
		s["bg"] = {"kind": "set", "value": set_override}
	if String(s["words"]).strip_edges() == "":
		spec.error(l, sid, "shot %s has no framing: write shot %s \"mcu on <tag>\" or a `frame` line" % [sid, sid])
	for other: Dictionary in shots:
		if other["id"] == sid:
			spec.error(l, sid, "duplicate shot id \"%s\"" % sid)
	shots.append(s)


func _icons(l: ToolSpecLine) -> void:
	spec.check_keys(l, ["size", "yaw", "pitch", "fill", "fov", "bg", "light", "kind"])
	var g := {"group": l.arg(0, "icons"), "size": l.get_int("size", 256), "yaw": l.get_float("yaw", 30.0),
		"pitch": l.get_float("pitch", 20.0), "fill": l.get_float("fill", 0.65), "fov": l.get_float("fov", 30.0),
		"bg": l.get_str("bg", "kingdom"), "light": l.get_str("light", "studio"), "kind": l.get_str("kind", "units"),
		"items": [], "line": l.line}
	spec.expect_one_of(l, String(g["bg"]), ["kingdom", "flat", "none"], "icon background")
	spec.expect_one_of(l, String(g["light"]), LIGHTS, "light preset")
	for c: ToolSpecLine in l.children:
		if c.keyword != "icon":
			spec.error(c, c.keyword, "icons blocks hold `icon <id> <res://scene.tscn> faction=<kingdom>` lines", ["icon"])
			continue
		spec.check_keys(c, ["faction", "kind", "yaw", "pitch", "fill", "hide"])
		var res := c.arg(1)
		if not res.begins_with("res://") or not ResourceLoader.exists(res):
			spec.error(c, res, "model scene not found \"%s\"" % res, _near_files(res))
			continue
		var fac := c.get_str("faction", "neutral")
		spec.expect_one_of(c, fac, FACTIONS, "faction")
		(g["items"] as Array).append({"id": c.arg(0), "res": res, "faction": fac, "kind": c.get_str("kind", g["kind"]),
			"yaw": c.get_float("yaw", g["yaw"]), "pitch": c.get_float("pitch", g["pitch"]), "fill": c.get_float("fill", g["fill"]),
			"hide": c.get_str("hide", ""), "line": c.line})
	icons.append(g)


func _portrait(l: ToolSpecLine) -> void:
	spec.check_keys(l, ["frame", "angle", "size", "faction", "light", "height"])
	var res := l.arg(1)
	if not res.begins_with("res://") or not ResourceLoader.exists(res):
		spec.error(l, res, "model scene not found \"%s\"" % res, _near_files(res))
		return
	var fr := l.get_str("frame", "cu")
	spec.expect_one_of(l, fr, ["ecu", "cu", "mcu"], "portrait frame")
	var ang := l.get_str("angle", "3/4-right")
	spec.expect_one_of(l, ang, LensSolver.ANGLES.keys(), "angle")
	var fac := l.get_str("faction", "neutral")
	spec.expect_one_of(l, fac, FACTIONS, "faction")
	portraits.append({"speaker": l.arg(0), "res": res, "frame": fr, "angle": ang, "size": l.get_int("size", 512),
		"faction": fac, "light": l.get_str("light", "studio"), "height": l.get_str("height", "eye"), "line": l.line})

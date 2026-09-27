class_name CineDoc
extends RefCounted
## A parsed `.cine` file (grammar: tools/cine/README.md). Reads with the shared ToolSpec reader; every problem keeps its
## line so the report can say `file:line: ... -> did you mean ...`. No engine objects here: CineStage builds the nodes,
## CineBake resolves names to positions.

const TOP_KEYWORDS := ["cine", "use", "cast", "prop", "env", "mark", "marks", "shot"]
const CAM_MODES := ["static", "dolly", "crane", "orbit", "rail", "follow", "frame", "lens"]
const SHOT_KEYS := ["cam", "from", "to", "look", "fov", "pivot", "r", "h", "deg", "actor", "offset", "rail", "in", "ease",
	"trans", "roll", "shake", "faces", "push", "marks", "set", "dof", "branch", "lens_spec"]
const ACTION_KINDS := ["line", "move", "teleport", "face", "anim", "clip", "vfx", "sfx", "music", "shake", "fade", "title",
	"show", "hide", "call", "set_shot"]
const ACTION_KEYS := {
	"line": ["dur", "voice"], "move": ["to", "speed"], "teleport": ["to", "yaw"], "face": ["yaw", "to", "time"],
	"anim": ["arg"], "clip": [], "vfx": ["at", "to", "scene", "life"], "sfx": ["vol"], "music": ["vol"],
	"shake": [], "fade": ["color", "alpha", "time"], "title": ["sub", "time"], "show": [], "hide": ["fade"],
	"call": ["args", "on_skip"], "set_shot": [],
}
const HEADER_KEYS := ["title", "letterbox", "skip_lock", "seed", "length", "mode", "skippable"]
const ENV_PRESETS := ["night", "dusk", "day", "none"]

var path: String = ""
var spec: ToolSpec
var id: String = ""
var title: String = ""
var letterbox: float = 2.39
var skip_lock: float = 0.0
var rng_seed: int = 1
var skippable: bool = true
var length_range: Vector2 = Vector2(0.0, 120.0)   # total duration rule (cinematics.md: 2:00 max)
var set_id: String = ""
var set_line: ToolSpecLine
var lines_path: String = ""
var lines_line: ToolSpecLine
var music: String = ""
var music_line: ToolSpecLine
var env: Dictionary = {"preset": "night", "moon_yaw": 35.0, "moon_pitch": -38.0, "energy": 0.6, "color": Color(0.62, 0.7, 1.0)}
var cast: Dictionary = {}          # tag -> {tag, scene, pos, yaw, hidden, speaker, line: ToolSpecLine}
var cast_order: Array[String] = []
var props: Array[Dictionary] = []  # {name, scene, pos, yaw, scale, line}
var marks: Dictionary = {}         # "P1_from" -> Vector3 (inline marks)
var mark_fov: Dictionary = {}      # "P1_from" -> fov
var mark_lines: Dictionary = {}    # marker -> ToolSpecLine
var shots: Array[Dictionary] = []  # {id, dur, line: ToolSpecLine, cam, kv..., words, actions: [...], lines: [...]}


static func load_file(file_path: String) -> CineDoc:
	var d := CineDoc.new()
	d.path = file_path
	d.spec = ToolSpec.parse_file(file_path)
	d._read()
	return d


static func from_text(text: String, source: String = "<text>") -> CineDoc:
	var d := CineDoc.new()
	d.path = source
	d.spec = ToolSpec.parse_text(text, source)
	d._read()
	return d


## Source path of a cine id: data/cinematics/src/<id>.cine (a path ending in .cine is taken as is).
static func source_of(cine_id: String) -> String:
	if cine_id.ends_with(".cine"):
		return cine_id if cine_id.begins_with("res://") else "res://" + cine_id
	return "res://data/cinematics/src/%s.cine" % cine_id


func total_duration() -> float:
	var t := 0.0
	for s: Dictionary in shots:
		t += float(s["dur"])
	return t


func line_count() -> int:
	var n := 0
	for l: ToolSpecLine in spec.all_lines:
		n = maxi(n, l.line)
	return n


# ---------------------------------------------------------------- reading

func _read() -> void:
	var header_seen := false
	for l: ToolSpecLine in spec.lines:
		match l.keyword:
			"cine":
				header_seen = true
				_read_header(l)
			"use":
				_read_use(l)
			"cast":
				_read_cast(l)
			"prop":
				_read_prop(l)
			"env":
				_read_env(l)
			"mark":
				_read_mark(l)
			"marks":
				_read_marks(l)
			"shot":
				_read_shot(l)
			_:
				spec.error(l, l.keyword, "unknown keyword \"%s\"" % l.keyword, TOP_KEYWORDS)
		if l.keyword != "shot":
			for c: ToolSpecLine in l.children:
				spec.error(c, c.keyword, "unexpected indented line under \"%s\" (only shots have a block)" % l.keyword)
	if not header_seen and spec.errors.is_empty():
		spec.error(null, "cine", "missing header line: cine <id> title=\"...\"")
	if shots.is_empty() and spec.errors.is_empty():
		spec.error(null, "shot", "no shots: add `shot <id> <seconds> cam=...` lines")


func _num(l: ToolSpecLine, tok: String, what: String, default: float) -> float:
	if tok.is_valid_float():
		return tok.to_float()
	spec.error(l, tok, "%s must be a number, got \"%s\"" % [what, tok])
	return default


func _vec(l: ToolSpecLine, tok: String, what: String) -> Variant:
	var v: Variant = ToolSpec.vec_of(tok)
	if v is Vector3:
		return v
	spec.error(l, tok, "%s must be a position (x, y, z), got \"%s\"" % [what, tok])
	return null


func _read_header(l: ToolSpecLine) -> void:
	spec.check_keys(l, HEADER_KEYS)
	id = l.arg(0, "")
	if id == "":
		spec.error(l, "cine", "the header needs an id: cine <id> title=\"...\"")
	title = l.get_str("title", id)
	if l.has("letterbox"):
		letterbox = _num(l, l.get_str("letterbox"), "letterbox", 2.39)
	if l.has("skip_lock"):
		skip_lock = _num(l, l.get_str("skip_lock"), "skip_lock", 0.0)
	if l.has("seed"):
		rng_seed = int(_num(l, l.get_str("seed"), "seed", 1.0))
	skippable = l.get_bool("skippable", true)
	if l.has("length"):
		var r: Variant = ToolSpec.range_of(l.get_str("length"))
		if r == null:
			spec.error(l, l.get_str("length"), "length must be a range in seconds like 45..60")
		else:
			length_range = r
	if l.has("mode"):
		spec.expect_one_of(l, l.get_str("mode"), ["stage"], "mode (only stage for now)")


func _read_use(l: ToolSpecLine) -> void:
	spec.check_keys(l, [])
	var what := l.arg(0, "")
	match what:
		"set":
			set_id = l.arg(1, "")
			set_line = l
			if set_id == "":
				spec.error(l, "set", "use set <set_id> (a tool 6 set in art/cinematics/stage_sets/<set_id>/)")
		"lines":
			lines_path = l.arg(1, "")
			lines_line = l
		"music":
			music = l.arg(1, "")
			music_line = l
		_:
			spec.error(l, what, "unknown use \"%s\"" % what, ["set", "lines", "music"])


func _read_cast(l: ToolSpecLine) -> void:
	spec.check_keys(l, ["at", "yaw", "hidden", "speaker"])
	var tag := l.arg(0, "")
	if tag == "" or l.arg(1, "") == "":
		spec.error(l, "cast", "cast <tag> <res://model.tscn | capsule> at=(x, y, z) yaw=<deg>")
		return
	if cast.has(tag):
		spec.error(l, tag, "actor \"%s\" cast twice" % tag)
		return
	var pos: Variant = _vec(l, l.get_str("at", "(0,0,0)"), "at")
	cast[tag] = {"tag": tag, "scene": l.arg(1), "pos": pos if pos != null else Vector3.ZERO,
		"yaw": _num(l, l.get_str("yaw", "0"), "yaw", 0.0), "hidden": l.get_bool("hidden", false),
		"speaker": l.get_str("speaker", tag), "line": l}
	cast_order.append(tag)


func _read_prop(l: ToolSpecLine) -> void:
	spec.check_keys(l, ["at", "yaw", "scale"])
	if l.arg(1, "") == "":
		spec.error(l, "prop", "prop <name> <res://scene.tscn> at=(x, y, z) yaw=<deg> scale=<k>")
		return
	var pos: Variant = _vec(l, l.get_str("at", "(0,0,0)"), "at")
	props.append({"name": l.arg(0), "scene": l.arg(1), "pos": pos if pos != null else Vector3.ZERO,
		"yaw": _num(l, l.get_str("yaw", "0"), "yaw", 0.0), "scale": _num(l, l.get_str("scale", "1"), "scale", 1.0), "line": l})


func _read_env(l: ToolSpecLine) -> void:
	spec.check_keys(l, ["moon_yaw", "moon_pitch", "energy", "color"])
	var p := l.arg(0, "night")
	if spec.expect_one_of(l, p, ENV_PRESETS, "env preset"):
		env["preset"] = p
	for k: String in ["moon_yaw", "moon_pitch", "energy"]:
		if l.has(k):
			env[k] = _num(l, l.get_str(k), k, float(env[k]))
	if l.has("color"):
		var c: Variant = ToolSpec.color_of(l.get_str("color"))
		if c == null:
			spec.error(l, l.get_str("color"), "color must be #rrggbb")
		else:
			env["color"] = c


## mark <name> (x, y, z) [fov=38]  -> marker @name
func _read_mark(l: ToolSpecLine) -> void:
	spec.check_keys(l, ["fov"])
	var n := l.arg(0, "").trim_prefix("@")
	var v: Variant = _vec(l, l.arg(1, ""), "mark position")
	if n == "" or v == null:
		return
	marks[n] = v
	mark_lines[n] = l
	if l.has("fov"):
		mark_fov[n] = _num(l, l.get_str("fov"), "fov", 40.0)


## marks <shot> from=(..) to=(..) look=(..)>(..) fov=a>b  -> markers @<shot>_from / _to / _look_from / _look_to
func _read_marks(l: ToolSpecLine) -> void:
	spec.check_keys(l, ["from", "to", "look", "fov", "pivot"])
	var s := l.arg(0, "")
	if s == "":
		spec.error(l, "marks", "marks <shot_id> from=(x,y,z) to=(x,y,z) look=(x,y,z)>(x,y,z) fov=40>36")
		return
	var fov := ToolSpec.fromto(l.get_str("fov", "40"))
	for k: String in ["from", "to", "pivot"]:
		if l.has(k):
			var v: Variant = _vec(l, l.get_str(k), k)
			if v != null:
				marks["%s_%s" % [s, k]] = v
				mark_lines["%s_%s" % [s, k]] = l
	if l.has("look"):
		var lk := ToolSpec.fromto(l.get_str("look"))
		var a: Variant = _vec(l, lk[0], "look")
		var b: Variant = _vec(l, lk[1], "look")
		if a != null and b != null:
			marks[s + "_look_from"] = a
			marks[s + "_look_to"] = b
			mark_lines[s + "_look_from"] = l
			mark_lines[s + "_look_to"] = l
	if marks.has(s + "_from"):
		mark_fov[s + "_from"] = _num(l, fov[0], "fov", 40.0)
		mark_fov[s + "_to"] = _num(l, fov[1], "fov", 40.0)
		if not marks.has(s + "_to"):
			marks[s + "_to"] = marks[s + "_from"]
			mark_lines[s + "_to"] = l


func _read_shot(l: ToolSpecLine) -> void:
	spec.check_keys(l, SHOT_KEYS)
	var sid := l.arg(0, "")
	if sid == "" or l.arg(1, "") == "":
		spec.error(l, "shot", "shot <id> <seconds> cam=<mode> ...")
		return
	for s: Dictionary in shots:
		if s["id"] == sid:
			spec.error(l, sid, "shot id \"%s\" used twice" % sid)
	var dur := _num(l, l.arg(1), "shot duration", 1.0)
	if dur <= 0.0:
		spec.error(l, l.arg(1), "shot duration must be > 0 s")
		dur = 0.1
	var cam := l.get_str("cam", "")
	if cam == "":
		cam = "marks" if not l.has("pivot") else "orbit"
	elif not cam in CAM_MODES:
		spec.error(l, cam, "unknown camera mode \"%s\"" % cam, CAM_MODES)
		cam = "static"
	var shot := {"id": sid, "dur": dur, "line": l, "cam": cam, "kv": l.kv, "words": l.arg(2, ""), "actions": [], "lines": []}
	for bad: String in l.bad_numbers(["r", "h", "roll", "shake", "push", "dof"]):
		spec.error(l, l.get_str(bad), "%s must be a number" % bad)
	if (cam == "frame" or cam == "lens") and shot["words"] == "":
		spec.error(l, cam, "cam=%s needs framing words: cam=%s \"mcu on vessa, 3/4 left, low\"" % [cam, cam])
	for c: ToolSpecLine in l.children:
		_read_at(shot, c)
	shots.append(shot)


func _read_at(shot: Dictionary, c: ToolSpecLine) -> void:
	if c.keyword != "at":
		spec.error(c, c.keyword, "shot lines start with `at <seconds> <kind> ...`", ["at"])
		return
	var t := _num(c, c.arg(0, ""), "time after `at`", 0.0)
	var kind := c.arg(1, "")
	if not kind in ACTION_KINDS:
		spec.error(c, kind, "unknown action \"%s\"" % kind, ACTION_KINDS)
		return
	spec.check_keys(c, ACTION_KEYS[kind])
	var a := {"at": t, "kind": kind, "line": c, "args": c.args.slice(2), "kv": c.kv}
	if kind == "line":
		var sp := c.arg(2, "")
		var tx := c.arg(3, "")
		if sp == "" or tx == "":
			spec.error(c, "line", "at <t> line <speaker> \"text\" [dur=<s>]")
			return
		shot["lines"].append({"at": t, "speaker": sp, "text": tx, "dur": c.get_float("dur", 0.0), "voice": c.get_str("voice", ""), "line": c})
		return
	shot["actions"].append(a)

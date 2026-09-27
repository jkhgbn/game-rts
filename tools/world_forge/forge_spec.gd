extends RefCounted
## World Forge spec adapter over the shared reader `tools/common/tool_spec.gd` (ToolSpec: one grammar and one error
## style for every tool). Statements come out as {kw, args, kv, ops, line, src: ToolSpecLine}; budget tokens
## `draws<=150` (not key=value for ToolSpec) are split here into kv + ops. Errors / warnings live in `ts` (ToolSpec):
## `file:line: message -> did you mean "x"?`. The value helpers below add World Forge's own shapes: (x,z) = ground
## point, polylines, areas (ring / circle / rect).
## No class_name on purpose (preloaded tool script).

var ts: ToolSpec = ToolSpec.parse_text("", "<none>")
var file := ""
var _by_line := {}   ## line number -> ToolSpecLine
var errors: Array[Dictionary]:
	get:
		return ts.errors
var warnings: Array[Dictionary]:
	get:
		return ts.warnings


## Reads a spec file into statements [{kw, args, kv, ops, line, src}].
func read_file(path: String) -> Array:
	file = path
	if not FileAccess.file_exists(path):
		ts = ToolSpec.parse_text("", path)
		ts.error(null, path, "spec file not found")
		return []
	ts = ToolSpec.parse_file(path)
	return _statements()


func read_text(text: String, source := "<text>") -> Array:
	file = source
	ts = ToolSpec.parse_text(text, source)
	return _statements()


func _statements() -> Array:
	var out: Array = []
	for l: ToolSpecLine in ts.all_lines:
		_by_line[l.line] = l
		var st := {"kw": l.keyword.to_lower(), "args": [], "kv": {}, "ops": {}, "line": l.line, "src": l}
		for k: String in l.kv:
			st["kv"][k.to_lower()] = l.kv[k]
			st["ops"][k.to_lower()] = "="
		for a: String in l.args:
			var m := _budget_split(a)
			if m.is_empty():
				st["args"].append(a)
			else:
				st["kv"][m[0]] = m[2]
				st["ops"][m[0]] = m[1]
		out.append(st)
	return out


## "draws<=150" -> ["draws", "<=", "150"]; [] otherwise.
static func _budget_split(t: String) -> Array:
	for op: String in ["<=", ">="]:
		var i := t.find(op)
		if i > 0 and t.substr(0, i).is_valid_identifier():
			return [t.substr(0, i).to_lower(), op, t.substr(i + 2)]
	return []


# ---------------------------------------------------------------- errors (ToolSpec)

func err(line: int, token: String, msg: String, choices: Array = []) -> void:
	var m := msg
	if not choices.is_empty() and ToolSpec.nearest(token.trim_prefix("kit:").trim_prefix("forge:"), choices) == "" and choices.size() <= 12:
		m += " (valid: %s)" % ", ".join(choices.map(func(c: Variant) -> String: return String(c)))
	var e := ts.error(_by_line.get(line, null), token, m, [])
	var best := ToolSpec.nearest(token.trim_prefix("kit:").trim_prefix("forge:"), choices) if not choices.is_empty() else ""
	if best != "":
		e["hint"] = "did you mean \"%s\"?" % best
	if e["file"] == "" or e["file"] == "<text>":
		e["file"] = file


func warn(line: int, token: String, msg: String) -> void:
	var e := ts.warn(_by_line.get(line, null), token, msg)
	if e["file"] == "" or e["file"] == "<text>":
		e["file"] = file


func ok() -> bool:
	return ts.ok()


## `file:line: message -> did you mean "x"?` (ToolSpec.format_error).
func error_lines() -> Array[String]:
	return ts.error_lines()


func warning_lines() -> Array[String]:
	var out: Array[String] = []
	for e: Dictionary in ts.warnings:
		out.append(ToolSpec.format_error(e))
	return out


static func did_you_mean(token: String, choices: Array) -> String:
	return ToolSpec.nearest(token.to_lower().trim_prefix("kit:").trim_prefix("forge:"), choices)


## Unknown keys of a statement -> errors (with "did you mean").
func check_keys(st: Dictionary, allowed: Array) -> void:
	for k: String in st["kv"]:
		if not allowed.has(k):
			err(st["line"], k, "unknown key \"%s\" for \"%s\"" % [k, st["kw"]], allowed)
# ---------------------------------------------------------------- values

## "1.5" -> 1.5; errors on junk. Returns `def` on error.
func num(st: Dictionary, key: String, def: float) -> float:
	if not st["kv"].has(key):
		return def
	var s: String = st["kv"][key]
	if not s.is_valid_float():
		err(st["line"], s, "%s= wants a number" % key)
		return def
	return s.to_float()


## "(x,z)" -> Vector3(x, 0, z); "(x,y,z)" -> Vector3. `ok` false on junk.
static func parse_vec(s: String) -> Variant:
	var t := s.strip_edges()
	if not (t.begins_with("(") and t.ends_with(")")):
		return null
	var parts := t.substr(1, t.length() - 2).split(",")
	for p in parts:
		if not p.strip_edges().is_valid_float():
			return null
	if parts.size() == 2:
		return Vector3(parts[0].to_float(), 0.0, parts[1].to_float())
	if parts.size() == 3:
		return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
	return null


func vec(st: Dictionary, key: String, def: Variant = null) -> Variant:
	if not st["kv"].has(key):
		return def
	var v: Variant = parse_vec(st["kv"][key])
	if v == null:
		err(st["line"], st["kv"][key], "%s= wants (x,z) or (x,y,z)" % key)
		return def
	return v


## "a..b" -> Vector2(a, b); a single number -> Vector2(n, n).
static func parse_range(s: String) -> Variant:
	var t := s.strip_edges()
	if t.is_valid_float():
		return Vector2(t.to_float(), t.to_float())
	var p := t.split("..")
	if p.size() == 2 and p[0].is_valid_float() and p[1].is_valid_float():
		return Vector2(p[0].to_float(), p[1].to_float())
	return null


func rng(st: Dictionary, key: String, def: Vector2) -> Vector2:
	if not st["kv"].has(key):
		return def
	var v: Variant = parse_range(st["kv"][key])
	if v == null:
		err(st["line"], st["kv"][key], "%s= wants a number or a range a..b" % key)
		return def
	return v


## "[(x,z),(x,z),...]" -> PackedVector3Array.
static func parse_poly(s: String) -> Variant:
	var t := s.strip_edges()
	if not (t.begins_with("[") and t.ends_with("]")):
		return null
	var out := PackedVector3Array()
	for part in _split_top(t.substr(1, t.length() - 2)):
		var v: Variant = parse_vec(part)
		if v == null:
			return null
		out.append(v)
	return out


## Splits "a,(b,c),d" on top-level commas.
static func _split_top(s: String) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	var depth := 0
	for ch in s:
		if ch == "(" or ch == "[":
			depth += 1
		elif ch == ")" or ch == "]":
			depth -= 1
		if ch == "," and depth == 0:
			out.append(cur.strip_edges())
			cur = ""
		else:
			cur += ch
	if cur.strip_edges() != "":
		out.append(cur.strip_edges())
	return out


const AREA_KINDS: Array[String] = ["ring", "circle", "rect"]


## "ring((0,0),14..20)" -> {kind, center: Vector3, r0, r1}; "circle((x,z),r)" -> {kind, center, r0: 0, r1: r};
## "rect((x0,z0),(x1,z1))" -> {kind, min: Vector3, max: Vector3}. null on junk.
static func parse_area(s: String) -> Variant:
	var t := s.strip_edges()
	var i := t.find("(")
	if i <= 0 or not t.ends_with(")"):
		return null
	var kind := t.substr(0, i).to_lower()
	var args := _split_top(t.substr(i + 1, t.length() - i - 2))
	match kind:
		"ring", "circle":
			if args.size() != 2:
				return null
			var c: Variant = parse_vec(args[0])
			var r: Variant = parse_range(args[1])
			if c == null or r == null:
				return null
			if kind == "circle":
				return {"kind": "circle", "center": c, "r0": 0.0, "r1": (r as Vector2).y}
			return {"kind": "ring", "center": c, "r0": (r as Vector2).x, "r1": (r as Vector2).y}
		"rect":
			if args.size() != 2:
				return null
			var a: Variant = parse_vec(args[0])
			var b: Variant = parse_vec(args[1])
			if a == null or b == null:
				return null
			return {"kind": "rect", "min": Vector3(minf(a.x, b.x), 0, minf(a.z, b.z)), "max": Vector3(maxf(a.x, b.x), 0, maxf(a.z, b.z))}
	return null


static func area_has(area: Dictionary, p: Vector3) -> bool:
	match String(area["kind"]):
		"rect":
			return p.x >= area["min"].x and p.x <= area["max"].x and p.z >= area["min"].z and p.z <= area["max"].z
		_:
			var d := Vector2(p.x - area["center"].x, p.z - area["center"].z).length()
			return d >= float(area["r0"]) and d <= float(area["r1"])


## A deterministic point inside an area (rng = seeded RandomNumberGenerator).
static func area_sample(area: Dictionary, r: RandomNumberGenerator) -> Vector3:
	match String(area["kind"]):
		"rect":
			return Vector3(r.randf_range(area["min"].x, area["max"].x), 0.0, r.randf_range(area["min"].z, area["max"].z))
		_:
			var r0: float = area["r0"]
			var r1: float = area["r1"]
			var rad := sqrt(r.randf_range(r0 * r0, r1 * r1))
			var a := r.randf() * TAU
			return area["center"] + Vector3(cos(a) * rad, 0.0, sin(a) * rad)


## "#rrggbb" or a named colour ("ash") from `named` -> Color; null on junk.
static func parse_color(s: String, named: Dictionary) -> Variant:
	if named.has(s):
		return named[s]
	if s.begins_with("#") and Color.html_is_valid(s):
		return Color.html(s)
	return null

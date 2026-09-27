extends RefCounted
## World Forge spec reader (tools-wave.md section 0 / 1 token rules): one statement per line,
## `keyword arg arg key=value ...`, `#` comments, `"quoted strings"`, groups in () and [] keep their spaces,
## `key<=value` / `key>=value` for budgets, `a..b` ranges, `(x,z)` / `(x,y,z)` vectors, `[(x,z),...]` polylines,
## `ring((x,z),r0..r1)` / `circle((x,z),r)` / `rect((x0,z0),(x1,z1))` areas. Line numbers are kept for errors.
## Errors teach: file, line, token and the nearest valid value ("did you mean").
## No class_name on purpose (preloaded tool script). Swap to tools/common/tool_spec.gd once it is frozen.

var file := ""
var errors: Array[Dictionary] = []    ## {line, token, msg}
var warnings: Array[Dictionary] = []


## Reads a spec file into statements [{kw, args: Array[String], kv: {key: String}, ops: {key: "<=" | ">=" | "="}, line}].
func read_file(path: String) -> Array:
	file = path
	if not FileAccess.file_exists(path):
		err(0, path, "spec file not found")
		return []
	return read_text(FileAccess.get_file_as_string(path))


func read_text(text: String) -> Array:
	var out: Array = []
	var n := 0
	for raw: String in text.split("\n"):
		n += 1
		var line := _strip_comment(raw).strip_edges()
		if line == "":
			continue
		var toks := tokenize(line)
		if toks.is_empty():
			continue
		var st := {"kw": toks[0].to_lower(), "args": [], "kv": {}, "ops": {}, "line": n}
		for k in range(1, toks.size()):
			var t: String = toks[k]
			var m := _kv_split(t)
			if m.is_empty():
				st["args"].append(_unquote(t))
			else:
				st["kv"][m[0]] = _unquote(m[2])
				st["ops"][m[0]] = m[1]
		out.append(st)
	return out


## Splits one line on whitespace outside quotes / brackets.
static func tokenize(line: String) -> Array[String]:
	var toks: Array[String] = []
	var cur := ""
	var depth := 0
	var quoted := false
	for ch in line:
		if ch == "\"":
			quoted = not quoted
			cur += ch
		elif quoted:
			cur += ch
		elif ch == "(" or ch == "[":
			depth += 1
			cur += ch
		elif ch == ")" or ch == "]":
			depth -= 1
			cur += ch
		elif (ch == " " or ch == "\t") and depth <= 0:
			if cur != "":
				toks.append(cur)
			cur = ""
		else:
			cur += ch
	if cur != "":
		toks.append(cur)
	return toks


static func _strip_comment(s: String) -> String:
	var quoted := false
	for i in s.length():
		var ch := s[i]
		if ch == "\"":
			quoted = not quoted
		elif ch == "#" and not quoted:
			# `#hex` colours are values, not comments: a comment starts the line or follows a space.
			if i == 0 or s[i - 1] == " " or s[i - 1] == "\t":
				if i + 1 < s.length() and _is_hex_color(s.substr(i).split(" ")[0]):
					continue
				return s.substr(0, i)
	return s


static func _is_hex_color(t: String) -> bool:
	return (t.length() == 7 or t.length() == 9) and t.substr(1).is_valid_hex_number()


## [key, op, value] or [] when the token is not key=value.
static func _kv_split(t: String) -> Array:
	if t.begins_with("(") or t.begins_with("[") or t.begins_with("\""):
		return []
	for op: String in ["<=", ">=", "="]:
		var i := t.find(op)
		if i > 0:
			var key := t.substr(0, i)
			if key.is_valid_identifier():
				return [key.to_lower(), op, t.substr(i + op.length())]
			return []
	return []


static func _unquote(t: String) -> String:
	if t.length() >= 2 and t.begins_with("\"") and t.ends_with("\""):
		return t.substr(1, t.length() - 2)
	return t


# ---------------------------------------------------------------- errors

func err(line: int, token: String, msg: String, choices: Array = []) -> void:
	var m := msg
	var best := did_you_mean(token, choices)
	if best != "":
		m += " -> did you mean \"%s\"?" % best
	elif not choices.is_empty() and choices.size() <= 12:
		m += " (valid: %s)" % ", ".join(choices.map(func(c: Variant) -> String: return String(c)))
	errors.append({"line": line, "token": token, "msg": m})


func warn(line: int, token: String, msg: String) -> void:
	warnings.append({"line": line, "token": token, "msg": msg})


func ok() -> bool:
	return errors.is_empty()


## "file:line: unknown key "cuont" -> did you mean "count"?" lines.
func error_lines() -> Array[String]:
	var out: Array[String] = []
	for e: Dictionary in errors:
		out.append("%s:%d: %s (token \"%s\")" % [file.get_file(), e["line"], e["msg"], e["token"]])
	return out


func warning_lines() -> Array[String]:
	var out: Array[String] = []
	for e: Dictionary in warnings:
		out.append("%s:%d: %s (token \"%s\")" % [file.get_file(), e["line"], e["msg"], e["token"]])
	return out


static func did_you_mean(token: String, choices: Array) -> String:
	var t := token.to_lower().trim_prefix("kit:").trim_prefix("forge:")
	var best := ""
	var best_d := maxi(2, t.length() / 3) + 1
	for c: Variant in choices:
		var d := edit_distance(t, String(c).to_lower())
		if d < best_d:
			best_d = d
			best = String(c)
	return best


## Levenshtein distance with adjacent transpositions (so "pnie" -> "pine" is 1).
static func edit_distance(a: String, b: String) -> int:
	var n := a.length()
	var m := b.length()
	var d: Array[PackedInt32Array] = []
	for i in n + 1:
		var row := PackedInt32Array()
		row.resize(m + 1)
		row[0] = i
		d.append(row)
	for j in m + 1:
		d[0][j] = j
	for i in range(1, n + 1):
		for j in range(1, m + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			var v := mini(mini(d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + cost)
			if i > 1 and j > 1 and a[i - 1] == b[j - 2] and a[i - 2] == b[j - 1]:
				v = mini(v, d[i - 2][j - 2] + 1)
			d[i][j] = v
	return d[n][m]


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

class_name ToolSpec
extends RefCounted
## The shared line-based spec reader of the tools wave (docs/plan/tools-wave.md section 1; API in tools/common/README.md).
## One format for every tool:  `keyword arg arg key=value key="quoted value"   # comment`
## - Blocks by indentation: a line indented deeper than the line above is its child (`ToolSpecLine.children`).
## - `# ` (hash + space, or a hash at the start of a line) starts a comment; `#ff8800` (no space) is a colour token.
## - Tokens split on spaces outside "quotes", (parentheses) and [brackets]: `at=(-8, 0, -10)` is one token.
## - Token kinds (`kind_of`): marker `@name`, res `res://...`, color `#hex`, fromto `a>b`, range `a..b`, vector `(x,y[,z])`,
##   list `[...]`, number, string (was quoted), word.
## - Every line keeps its number; `error()` / `check_keys()` / `expect_one_of()` write errors that name the file, the
##   line, the token and the nearest valid value ("did you mean").

var path: String = ""                    # the file read ("" for text)
var lines: Array[ToolSpecLine] = []      # top-level lines (children hang below them)
var all_lines: Array[ToolSpecLine] = []  # every line in file order (flat)
var errors: Array[Dictionary] = []       # {file, line, token, message, hint, text}
var warnings: Array[Dictionary] = []     # same shape


## Reads a spec file (res:// or absolute). A missing file gives a spec with one error.
static func parse_file(file_path: String) -> ToolSpec:
	var s := ToolSpec.new()
	s.path = file_path
	if not FileAccess.file_exists(file_path):
		s.errors.append(_err_dict(file_path, 0, file_path, "file not found", "", ""))
		return s
	s._parse(FileAccess.get_file_as_string(file_path))
	return s


static func parse_text(text: String, source: String = "<text>") -> ToolSpec:
	var s := ToolSpec.new()
	s.path = source
	s._parse(text)
	return s


func ok() -> bool:
	return errors.is_empty()


## Top-level lines whose keyword is `keyword` (or all when "").
func find(keyword: String = "") -> Array[ToolSpecLine]:
	var out: Array[ToolSpecLine] = []
	for l: ToolSpecLine in lines:
		if keyword == "" or l.keyword == keyword:
			out.append(l)
	return out


func first(keyword: String) -> ToolSpecLine:
	for l: ToolSpecLine in lines:
		if l.keyword == keyword:
			return l
	return null


## Records an error. `candidates` (optional) adds "did you mean" with the nearest one.
func error(line: ToolSpecLine, token: String, message: String, candidates: Array = []) -> Dictionary:
	var hint := ""
	if not candidates.is_empty():
		var n := ToolSpec.nearest(token, candidates)
		if n != "":
			hint = "did you mean \"%s\"?" % n
	var d := _err_dict(path, line.line if line != null else 0, token, message, hint, line.text if line != null else "")
	errors.append(d)
	return d


func warn(line: ToolSpecLine, token: String, message: String, hint: String = "") -> Dictionary:
	var d := _err_dict(path, line.line if line != null else 0, token, message, hint, line.text if line != null else "")
	warnings.append(d)
	return d


## Errors for every key of `line` not in `allowed` (with "did you mean"). Returns true when all keys are known.
func check_keys(line: ToolSpecLine, allowed: Array) -> bool:
	var good := true
	for k: String in line.kv:
		if not k in allowed:
			error(line, k, "unknown key \"%s\" for \"%s\"" % [k, line.keyword], allowed)
			good = false
	return good


## Error when `value` is not one of `allowed` (with "did you mean"). Returns true when it is.
func expect_one_of(line: ToolSpecLine, value: String, allowed: Array, what: String) -> bool:
	if value in allowed:
		return true
	error(line, value, "unknown %s \"%s\"" % [what, value], allowed)
	return false


## Every error as one teaching line: `file:line: message (token "x") -> did you mean "y"?`
func error_lines() -> Array[String]:
	var out: Array[String] = []
	for e: Dictionary in errors:
		out.append(ToolSpec.format_error(e))
	return out


static func format_error(e: Dictionary) -> String:
	var s := "%s:%d: %s" % [String(e["file"]).replace("res://", ""), int(e["line"]), e["message"]]
	if String(e["hint"]) != "":
		s += " -> " + String(e["hint"])
	return s


static func _err_dict(file: String, line: int, token: String, message: String, hint: String, text: String) -> Dictionary:
	return {"file": file, "line": line, "token": token, "message": message, "hint": hint, "text": text}


# ---------------------------------------------------------------- reader

func _parse(text: String) -> void:
	var stack: Array[ToolSpecLine] = []
	var n := 0
	for raw: String in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
		n += 1
		var body := _strip_comment(raw)
		if body.strip_edges() == "":
			continue
		var indent := 0
		for ch: String in body:
			if ch == " ":
				indent += 1
			elif ch == "\t":
				indent += 4
			else:
				break
		var toks := ToolSpec.tokenize(body.strip_edges())
		if toks.is_empty():
			continue
		var l := ToolSpecLine.new()
		l.line = n
		l.indent = indent
		l.text = raw.strip_edges()
		l.keyword = String(toks[0]["text"])
		for i: int in range(1, toks.size()):
			var t: Dictionary = toks[i]
			var tx: String = t["text"]
			var eq := _kv_split(tx)
			if eq > 0 and not bool(t["quoted"]):
				var k := tx.substr(0, eq)
				var v := tx.substr(eq + 1)
				if v.length() >= 2 and v.begins_with("\"") and v.ends_with("\""):
					v = v.substr(1, v.length() - 2)
				if l.kv.has(k):
					error(l, k, "key \"%s\" given twice" % k)
				l.kv[k] = v
				l.kv_order.append(k)
			else:
				l.args.append(tx)
				l.quoted.append(bool(t["quoted"]))
		while not stack.is_empty() and stack[-1].indent >= indent:
			stack.pop_back()
		if stack.is_empty():
			lines.append(l)
		else:
			l.parent = stack[-1]
			stack[-1].children.append(l)
		stack.append(l)
		all_lines.append(l)


## Index of the `=` of a key=value token (-1 when the token is not one: the key must be a plain identifier).
static func _kv_split(tx: String) -> int:
	var eq := tx.find("=")
	if eq <= 0:
		return -1
	var k := tx.substr(0, eq)
	for ch: String in k:
		if not (ch == "_" or ch == "-" or ch == "." or (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9")):
			return -1
	return eq


## Removes a `# comment` (hash at line start, or hash followed by a space / end, outside quotes).
static func _strip_comment(raw: String) -> String:
	var q := false
	for i: int in raw.length():
		var ch := raw[i]
		if ch == "\"":
			q = not q
		elif ch == "#" and not q:
			var prev_ok := i == 0 or raw[i - 1] == " " or raw[i - 1] == "\t"
			var next := raw[i + 1] if i + 1 < raw.length() else " "
			if raw.substr(0, i).strip_edges() == "" or (prev_ok and (next == " " or next == "\t" or next == "#")):
				return raw.substr(0, i)
	return raw


## Splits one line into tokens [{text, quoted}]; spaces inside quotes / () / [] do not split.
static func tokenize(s: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cur := ""
	var depth := 0
	var q := false
	var was_quoted := false
	for i: int in s.length():
		var ch := s[i]
		if ch == "\"":
			q = not q
			if cur == "" or (not q and cur.begins_with("\"")):
				was_quoted = true
			cur += ch
			continue
		if not q:
			if ch == "(" or ch == "[":
				depth += 1
			elif ch == ")" or ch == "]":
				depth = maxi(0, depth - 1)
			elif (ch == " " or ch == "\t") and depth == 0:
				if cur != "":
					out.append(_tok(cur, was_quoted))
				cur = ""
				was_quoted = false
				continue
		cur += ch
	if cur != "":
		out.append(_tok(cur, was_quoted))
	return out


static func _tok(t: String, was_quoted: bool) -> Dictionary:
	var quoted := was_quoted and t.begins_with("\"") and t.ends_with("\"") and t.length() >= 2
	return {"text": t.substr(1, t.length() - 2) if quoted else t, "quoted": quoted}


# ---------------------------------------------------------------- token helpers (static, usable on any string)

## marker | res | color | fromto | range | vector | list | number | word  (a quoted arg is "string": see ToolSpecLine.quoted)
static func kind_of(tok: String) -> String:
	if tok.begins_with("@"):
		return "marker"
	if tok.begins_with("res://") or tok.begins_with("user://"):
		return "res"
	if tok.begins_with("#") and is_hex_color(tok):
		return "color"
	if tok.begins_with("(") and tok.ends_with(")") and "," in tok:
		return "vector"
	if tok.begins_with("["):
		return "list"
	if ".." in tok:
		return "range"
	if ">" in tok:
		return "fromto"
	if tok.is_valid_float():
		return "number"
	return "word"


static func is_hex_color(tok: String) -> bool:
	var h := tok.trim_prefix("#")
	return h.length() in [3, 4, 6, 8] and h.is_valid_hex_number(false)


## `a>b` -> ["a", "b"]; `a` -> ["a", "a"] (a constant). Works on markers, numbers, words.
static func fromto(tok: String) -> PackedStringArray:
	var i := tok.find(">")
	if i < 0:
		return PackedStringArray([tok, tok])
	return PackedStringArray([tok.substr(0, i), tok.substr(i + 1)])


## `14..20` -> Vector2(14, 20); a single number -> Vector2(n, n); bad -> null.
static func range_of(tok: String) -> Variant:
	var i := tok.find("..")
	var a := tok if i < 0 else tok.substr(0, i)
	var b := tok if i < 0 else tok.substr(i + 2)
	if not a.is_valid_float() or not b.is_valid_float():
		return null
	return Vector2(a.to_float(), b.to_float())


## `(1,2,3)` -> Vector3, `(1,2)` -> Vector2; anything else -> null.
static func vec_of(tok: String) -> Variant:
	var t := tok.strip_edges()
	if not (t.begins_with("(") and t.ends_with(")")):
		return null
	var parts := t.substr(1, t.length() - 2).split(",")
	var f: Array[float] = []
	for p: String in parts:
		if not p.strip_edges().is_valid_float():
			return null
		f.append(p.strip_edges().to_float())
	if f.size() == 3:
		return Vector3(f[0], f[1], f[2])
	if f.size() == 2:
		return Vector2(f[0], f[1])
	return null


static func color_of(tok: String) -> Variant:
	if not is_hex_color(tok):
		return null
	return Color.html(tok)


## `[a,b,(1,2)]` -> ["a", "b", "(1,2)"] (top-level commas only); `a,b` -> ["a", "b"].
static func list_of(tok: String) -> PackedStringArray:
	var t := tok.strip_edges()
	if t.begins_with("[") and t.ends_with("]"):
		t = t.substr(1, t.length() - 2)
	var out := PackedStringArray()
	var cur := ""
	var depth := 0
	for ch: String in t:
		if ch == "(" or ch == "[":
			depth += 1
		elif ch == ")" or ch == "]":
			depth -= 1
		if ch == "," and depth == 0:
			if cur.strip_edges() != "":
				out.append(cur.strip_edges())
			cur = ""
		else:
			cur += ch
	if cur.strip_edges() != "":
		out.append(cur.strip_edges())
	return out


## Nearest candidate by edit distance ("" when nothing is reasonably close: distance > max(2, len / 2)).
static func nearest(word: String, candidates: Array) -> String:
	var best := ""
	var bd := 1 << 20
	var w := word.to_lower()
	for c: Variant in candidates:
		var cs := String(c)
		var d := levenshtein(w, cs.to_lower())
		if cs.to_lower().begins_with(w) or w.begins_with(cs.to_lower()):
			d = mini(d, 1)
		if d < bd:
			bd = d
			best = cs
	if best == "" or bd > maxi(2, word.length() / 2):
		return ""
	return best


static func levenshtein(a: String, b: String) -> int:
	if a == b:
		return 0
	var prev := PackedInt32Array()
	prev.resize(b.length() + 1)
	for j: int in b.length() + 1:
		prev[j] = j
	for i: int in a.length():
		var cur := PackedInt32Array()
		cur.resize(b.length() + 1)
		cur[0] = i + 1
		for j: int in b.length():
			var cost := 0 if a[i] == b[j] else 1
			cur[j + 1] = mini(mini(cur[j] + 1, prev[j + 1] + 1), prev[j] + cost)
		prev = cur
	return prev[b.length()]

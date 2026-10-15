extends SceneTree
## Shader lint (graphics week 2026-10-15, CLAUDE.md "Recurring bugs"): reads the text of every .gdshader /
## .gdshaderinc under res://art/ and res://scripts/ (no rendering) and flags two bug classes that kept coming back:
##   A  a graphics-tier uniform (TIER_NAMES) whose default is above 0: a material no code ever sets runs the
##      expensive High path at Low. Genuine non-tier uses carry `// lint: tier-default-ok` on the uniform line.
##   B  dFdx / dFdy / fwidth (or a function that calls one, found through the file and its #includes) inside an
##      `if (...)` / `switch (...)` whose condition reads a per-fragment value (anything that is not a uniform, a const,
##      a #define, a uniform built-in like TIME, a `flat` varying (constant over a pixel quad, which never spans two
##      triangles; lead 2026-10-15), or a local / parameter only ever fed from those): undefined
##      derivatives, speckles at seams. `// lint: deriv-ok` on the call line silences one hit.
## Heuristic notes (B): locals and function parameters are tracked (a parameter is per-fragment when any call site in
## the shader + its includes passes a per-fragment value; a local when any assignment is per-fragment or happens inside
## a per-fragment branch). Loops, early returns / discard and implicit texture() derivatives are not checked.
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_shader_lint.gd --quit-after 600
## Options after `--` (PowerShell: `'--'`): --verbose (prints the include map), --only=<substring of a path> (filter the printout)

const TASK_ID := "shader_lint"
const ROOTS: Array[String] = ["res://art", "res://scripts"]
const TIER_NAMES: Array[String] = ["quality", "gfx_detail", "gb_detail", "kit_detail", "detail_tier", "gfx_tier", "tier"]
const OK_TIER := "lint: tier-default-ok"
const OK_DERIV := "lint: deriv-ok"
const DERIV_BUILTINS: Array[String] = ["dFdx", "dFdy", "fwidth", "dFdxCoarse", "dFdyCoarse", "fwidthCoarse",
	"dFdxFine", "dFdyFine", "fwidthFine"]
## Built-ins that are the same for every pixel of a draw call.
const UNIFORM_BUILTINS: Array[String] = ["TIME", "PI", "TAU", "E", "VIEWPORT_SIZE", "CAMERA_POSITION_WORLD",
	"CAMERA_DIRECTION_WORLD", "CAMERA_VISIBLE_LAYERS", "VIEW_MATRIX", "INV_VIEW_MATRIX", "PROJECTION_MATRIX",
	"INV_PROJECTION_MATRIX", "MODEL_MATRIX", "MODEL_NORMAL_MATRIX", "NODE_POSITION_WORLD", "NODE_POSITION_VIEW",
	"OUTPUT_IS_SRGB", "EYE_OFFSET", "VIEW_INDEX", "VIEW_MONO_LEFT", "VIEW_RIGHT", "INSTANCE_ID", "TEXTURE_PIXEL_SIZE",
	"SCREEN_PIXEL_SIZE", "CANVAS_MATRIX", "SCREEN_MATRIX", "EXPOSURE", "AT_LIGHT_PASS"]
const TYPES: Array[String] = ["void", "bool", "bvec2", "bvec3", "bvec4", "int", "ivec2", "ivec3", "ivec4", "uint",
	"uvec2", "uvec3", "uvec4", "float", "vec2", "vec3", "vec4", "mat2", "mat3", "mat4", "sampler2D", "isampler2D",
	"usampler2D", "sampler2DArray", "isampler2DArray", "usampler2DArray", "sampler3D", "isampler3D", "usampler3D",
	"samplerCube", "samplerCubeArray", "samplerExternalOES"]
const QUALIFIERS: Array[String] = ["const", "in", "out", "inout", "lowp", "mediump", "highp", "flat", "smooth"]
const KEYWORDS: Array[String] = ["if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue",
	"return", "discard", "true", "false", "struct", "uniform", "varying", "const"]
const ASSIGN_OPS: Array[String] = ["=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "<<=", ">>="]


class FuncDef:
	var name: String
	var params: Array[String] = []
	var quals: Array[String] = []
	var b0: int = 0       ## first body token
	var b1: int = 0       ## index of the closing brace
	var env: Dictionary = {}   ## local / param name -> true (uniform) / false (per-fragment)
	var calls: Array[String] = []
	var deriv: bool = false
	var impure: bool = false


# --- per-run state
var _files: Dictionary = {}      ## path -> {toks, lines, defines} (tokenized once)
var _markers: Dictionary = {}    ## "path:line" -> comment text
var _hits: Dictionary = {}       ## "path:line [rule]" -> message
var _verbose := false
var _only := ""

# --- per-unit state (one shader + its includes)
var _tt: Array[String] = []
var _tp: Array[String] = []      ## path of each token
var _tl: Array[int] = []         ## line of each token
var _defines: Dictionary = {}
var _uniforms: Dictionary = {}
var _consts: Dictionary = {}
var _varyings: Dictionary = {}
var _flat_varyings: Dictionary = {}   ## `varying flat ...`: uniform within a pixel quad (rule B treats them as uniform)
var _structs: Dictionary = {}
var _funcs: Array[FuncDef] = []
var _by_name: Dictionary = {}    ## name -> Array of FuncDef
var _f: FuncDef = null
var _p := 0
var _end := 0
var _collect := false
var _changed := false


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	for a: String in OS.get_cmdline_user_args():
		if a == "--verbose":
			_verbose = true
		elif a.begins_with("--only="):
			_only = a.substr(7)
	var self_ok := _self_test()
	var paths: Array[String] = []
	for r: String in ROOTS:
		_list(r, paths)
	paths.sort()
	var included: Dictionary = {}
	for p: String in paths:
		var f: Dictionary = _file(p)
		for t: String in f.toks:
			if t.begins_with("#inc:"):
				included[t.substr(5)] = true
	for p: String in paths:
		_rule_a(p)
	if _verbose:
		print("included: ", included.keys())
	var units := 0
	for p: String in paths:
		if p.ends_with(".gdshader") or not included.has(p):
			_analyze_unit(p)
			units += 1
	var keys: Array = _hits.keys()
	keys.sort()
	var na := 0
	var nb := 0
	for k: String in keys:
		if _only != "" and not k.contains(_only):
			continue
		print("%s  %s" % [k, _hits[k]])
		if k.ends_with("[A]"):
			na += 1
		else:
			nb += 1
	print("shader_lint: %d files, %d units, rule A %d hit(s), rule B %d hit(s), %d ms" % [
		paths.size(), units, na, nb, Time.get_ticks_msec() - t0])
	if not self_ok:
		print("FAIL %s: the lint's own self-test failed (see above)" % TASK_ID)
	elif na + nb > 0:
		print("FAIL %s: %d hit(s)" % [TASK_ID, na + nb])
	else:
		print("PASS %s" % TASK_ID)
	quit(0 if self_ok and na + nb == 0 else 1)


# ---------------------------------------------------------------------------------------------------- self-test

const _SELF_BAD := """shader_type spatial;
uniform float gb_detail : hint_range(0.0, 3.0) = 2.0;
varying vec3 v_wp;
float bump(vec3 p) { return length(fwidth(p)); }
float bump2(vec3 p, float q) { float r = 0.0; if (q > 1.0) { r = length(fwidth(p)); } return r; }
void fragment() {
	float d = length(v_wp);
	float k = 0.0;
	if (d < 2.0) { k = 1.0; }
	if (d < 10.0) {
		ALBEDO = vec3(bump(v_wp));
	}
	ALBEDO += vec3(bump2(v_wp, d));
	if (k > 0.5) ALBEDO += vec3(dFdx(d));
}
"""
const _SELF_GOOD := """shader_type spatial;
uniform int quality = 0;
uniform float tier = 2.0; // lint: tier-default-ok
const float K = 1.0;
#define HI (quality > 1)
varying vec3 v_wp;
varying flat float v_kind;
float bump(vec3 p, float q) { float r = 0.0; if (q > 1.0) { r = length(fwidth(p)); } return r; }
void fragment() {
	float px = length(fwidth(v_wp));
	if (v_kind > 0.5) { px += length(fwidth(v_wp)); }
	float qf = float(quality) * K;
	for (int i = 0; i < 3; i++) { if (i == 1 && qf > 0.0) { px += fwidth(v_wp.x); } }
	if (HI) { ALBEDO = vec3(bump(v_wp, qf)); } else if (TIME > 2.0) { ALBEDO = vec3(dFdy(px)); }
	float d = length(v_wp);
	if (d < 5.0) { ALBEDO = vec3(px); }
	if (d < 3.0) { ALBEDO = vec3(fwidth(d)); } // lint: deriv-ok
}
"""


func _self_test() -> bool:
	var bad := "res://__lint_self_bad.gdshader"
	var good := "res://__lint_self_good.gdshader"
	_files[bad] = _tokenize(bad, _SELF_BAD)
	_files[good] = _tokenize(good, _SELF_GOOD)
	_rule_a_text(bad, _SELF_BAD)
	_rule_a_text(good, _SELF_GOOD)
	_analyze_unit(bad)
	_analyze_unit(good)
	var want := {"res://__lint_self_bad.gdshader:2 [A]": true, "res://__lint_self_bad.gdshader:5 [B]": true,
		"res://__lint_self_bad.gdshader:11 [B]": true, "res://__lint_self_bad.gdshader:14 [B]": true}
	var ok := true
	for k: String in _hits.keys():
		if not want.has(k):
			print("self-test: unexpected hit %s  %s" % [k, _hits[k]])
			ok = false
	for k: String in want.keys():
		if not _hits.has(k):
			print("self-test: missed %s" % k)
			ok = false
	_hits.clear()
	return ok


# ---------------------------------------------------------------------------------------------------- files

func _list(dir_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if not n.begins_with("."):
			var full := dir_path.path_join(n)
			if d.current_is_dir():
				_list(full, out)
			elif n.ends_with(".gdshader") or n.ends_with(".gdshaderinc"):
				out.append(full)
		n = d.get_next()
	d.list_dir_end()


func _file(path: String) -> Dictionary:
	if not _files.has(path):
		if FileAccess.file_exists(path):
			_files[path] = _tokenize(path, FileAccess.get_file_as_string(path))
		else:
			_files[path] = {}
	return _files[path]


# ---------------------------------------------------------------------------------------------------- rule A

func _rule_a(path: String) -> void:
	_rule_a_text(path, FileAccess.get_file_as_string(path))


func _rule_a_text(path: String, text: String) -> void:
	var re := RegEx.new()
	re.compile("^\\s*(?:(?:global|instance)\\s+)?uniform\\s+(?:(?:lowp|mediump|highp)\\s+)?(?:int|uint|float)\\s+(\\w+)\\b[^=;]*=\\s*([-+]?[0-9]*\\.?[0-9]+(?:[eE][-+]?[0-9]+)?)")
	var lines := text.split("\n")
	for i in lines.size():
		var m := re.search(lines[i])
		if m == null or not TIER_NAMES.has(m.get_string(1)):
			continue
		if m.get_string(2).to_float() > 0.0 and not lines[i].contains(OK_TIER):
			_hits["%s:%d [A]" % [path, i + 1]] = "tier uniform `%s` defaults to %s (> 0): an unset material runs the High path at Low" % [
				m.get_string(1), m.get_string(2)]


# ---------------------------------------------------------------------------------------------------- tokenizer

func _note_marker(path: String, line: int, text: String) -> void:
	if text.contains("lint:"):
		var k := "%s:%d" % [path, line]
		_markers[k] = String(_markers.get(k, "")) + text


static func _is_id0(c: int) -> bool:
	return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95


static func _is_id(c: int) -> bool:
	return _is_id0(c) or (c >= 48 and c <= 57)


static func _is_ident(t: String) -> bool:
	return t != "" and _is_id0(t.unicode_at(0))


func _tokenize(path: String, text: String) -> Dictionary:
	var toks: Array[String] = []
	var lines: Array[int] = []
	var defines: Array[String] = []
	var n := text.length()
	var i := 0
	var line := 1
	var line_start := true
	var two := ["==", "!=", "<=", ">=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "++", "--", "&&", "||", "<<", ">>"]
	while i < n:
		var c := text.unicode_at(i)
		if c == 10:
			line += 1
			line_start = true
			i += 1
			continue
		if c == 32 or c == 9 or c == 13:
			i += 1
			continue
		if c == 47 and i + 1 < n and text.unicode_at(i + 1) == 47:   # //
			var e := text.find("\n", i)
			if e < 0:
				e = n
			_note_marker(path, line, text.substr(i, e - i))
			i = e
			continue
		if c == 47 and i + 1 < n and text.unicode_at(i + 1) == 42:   # /*
			var e2 := text.find("*/", i + 2)
			if e2 < 0:
				e2 = n - 2
			var body := text.substr(i, e2 + 2 - i)
			_note_marker(path, line, body)
			line += body.count("\n")
			i = e2 + 2
			continue
		if c == 35 and line_start:   # preprocessor line
			var e3 := text.find("\n", i)
			while e3 > 0 and text.substr(i, e3 - i).strip_edges(false, true).ends_with("\\"):
				e3 = text.find("\n", e3 + 1)
			if e3 < 0:
				e3 = n
			var d := text.substr(i, e3 - i)
			var cpos := d.find("//", d.rfind("\"") + 1)   # not the // of "res://"
			if cpos >= 0:
				_note_marker(path, line, d.substr(cpos))
				d = d.substr(0, cpos)
			var ds := d.strip_edges()
			if ds.begins_with("#include"):
				var q0 := ds.find("\"")
				var q1 := ds.find("\"", q0 + 1)
				if q0 >= 0 and q1 > q0:
					var inc := ds.substr(q0 + 1, q1 - q0 - 1)
					if not inc.begins_with("res://"):
						inc = path.get_base_dir().path_join(inc).simplify_path()
					toks.append("#inc:" + inc)
					lines.append(line)
			elif ds.begins_with("#define"):
				var rest := ds.substr(7).strip_edges()
				var k := 0
				while k < rest.length() and _is_id(rest.unicode_at(k)):
					k += 1
				if k > 0:
					defines.append(rest.substr(0, k))
			line += d.count("\n")
			i = e3
			continue
		line_start = false
		if _is_id0(c):
			var s := i
			while i < n and _is_id(text.unicode_at(i)):
				i += 1
			toks.append(text.substr(s, i - s))
			lines.append(line)
			continue
		if (c >= 48 and c <= 57) or (c == 46 and i + 1 < n and text.unicode_at(i + 1) >= 48 and text.unicode_at(i + 1) <= 57):
			var s2 := i
			while i < n:
				var ch := text.unicode_at(i)
				if (ch >= 48 and ch <= 57) or ch == 46 or ch == 120 or (ch >= 97 and ch <= 102) or (ch >= 65 and ch <= 70) or ch == 117:
					i += 1
				elif (ch == 43 or ch == 45) and (text.unicode_at(i - 1) == 101 or text.unicode_at(i - 1) == 69):
					i += 1
				else:
					break
			toks.append(text.substr(s2, i - s2))
			lines.append(line)
			continue
		if c == 34:   # string (hints / includes only)
			var e4 := text.find("\"", i + 1)
			i = (e4 + 1) if e4 > 0 else n
			continue
		var t2 := text.substr(i, 2)
		if i + 2 < n and (t2 == "<<" or t2 == ">>") and text.unicode_at(i + 2) == 61:
			toks.append(text.substr(i, 3))
			lines.append(line)
			i += 3
			continue
		if two.has(t2):
			toks.append(t2)
			lines.append(line)
			i += 2
			continue
		toks.append(text.substr(i, 1))
		lines.append(line)
		i += 1
	return {"toks": toks, "lines": lines, "defines": defines}


# ---------------------------------------------------------------------------------------------------- unit

func _append_file(path: String, seen: Dictionary) -> void:
	if seen.has(path):
		return
	seen[path] = true
	var f: Dictionary = _file(path)
	if f.is_empty():
		return
	for d: String in f.defines:
		_defines[d] = true
	var toks: Array[String] = f.toks
	var lines: Array[int] = f.lines
	for k in toks.size():
		var t: String = toks[k]
		if t.begins_with("#inc:"):
			_append_file(t.substr(5), seen)
		else:
			_tt.append(t)
			_tp.append(path)
			_tl.append(lines[k])


func _analyze_unit(path: String) -> void:
	_tt = []
	_tp = []
	_tl = []
	_defines = {}
	_uniforms = {}
	_consts = {}
	_varyings = {}
	_flat_varyings = {}
	_structs = {}
	_funcs = []
	_by_name = {}
	_append_file(path, {})
	_scan_globals()
	_scan_functions()
	for _it in 16:
		_changed = false
		_run_all(false)
		if not _changed:
			break
	_run_all(true)


func _run_all(collect: bool) -> void:
	_collect = collect
	for f: FuncDef in _funcs:
		if f.name == "vertex":
			continue
		_f = f
		_p = f.b0
		_end = f.b1
		while _p < _end:
			var before := _p
			_parse_stmt("")
			if _p <= before:
				_p = before + 1


## Index of the token closing the bracket at `open`.
func _match(open: int) -> int:
	var o := _tt[open]
	var cl := ")" if o == "(" else ("]" if o == "[" else "}")
	var depth := 0
	for k in range(open, _tt.size()):
		var t := _tt[k]
		if t == o:
			depth += 1
		elif t == cl:
			depth -= 1
			if depth == 0:
				return k
	return _tt.size() - 1


## Index of `what` at bracket depth 0 starting at `from` (stops at `limit`).
func _find0(from: int, limit: int, what: String) -> int:
	var depth := 0
	for k in range(from, limit):
		var t := _tt[k]
		if depth == 0 and t == what:
			return k
		if t == "(" or t == "[" or t == "{":
			depth += 1
		elif t == ")" or t == "]" or t == "}":
			depth -= 1
			if depth < 0:
				return k
	return limit


func _is_type(t: String) -> bool:
	return TYPES.has(t) or _structs.has(t)


func _scan_globals() -> void:
	var n := _tt.size()
	var i := 0
	while i < n:
		var t := _tt[i]
		if t == "shader_type" or t == "render_mode" or t == "group_uniforms":
			i = _find0(i, n, ";") + 1
		elif t == "uniform" or t == "const" or t == "varying":
			var j := i + 1
			var is_flat := false
			while j < n and (QUALIFIERS.has(_tt[j]) or _tt[j] == "flat" or _tt[j] == "smooth"):
				is_flat = is_flat or _tt[j] == "flat"
				j += 1
			if j + 1 < n:
				var name := _tt[j + 1]
				if t == "uniform":
					_uniforms[name] = true
				elif t == "const":
					_consts[name] = true
				elif is_flat:
					# Lead 2026-10-15: a 2x2 pixel quad always belongs to one triangle, so a flat varying is
					# uniform within the quad: derivatives under a branch on it are defined.
					_flat_varyings[name] = true
				else:
					_varyings[name] = true
			i = _find0(i, n, ";") + 1
		elif t == "struct" and i + 1 < n:
			_structs[_tt[i + 1]] = true
			var ob := _find0(i, n, "{")
			i = _find0(_match(ob) + 1, n, ";") + 1
		elif _is_ident(t) and i + 2 < n and _is_ident(_tt[i + 1]) and _tt[i + 2] == "(" and not KEYWORDS.has(_tt[i + 1]):
			var close := _match(i + 2)
			if close + 1 < n and _tt[close + 1] == "{":
				var f := FuncDef.new()
				f.name = _tt[i + 1]
				var a := i + 3
				while a < close:
					var e := _find0(a, close, ",")
					var nm := ""
					var q := "in"
					for k in range(a, e):
						if _tt[k] == "[":
							break
						if _tt[k] == "out" or _tt[k] == "inout":
							q = _tt[k]
						if _is_ident(_tt[k]):
							nm = _tt[k]
					if nm != "" and nm != "void":
						f.params.append(nm)
						f.quals.append(q)
						f.env[nm] = true
					a = e + 1
				f.b0 = close + 2
				f.b1 = _match(close + 1)
				_funcs.append(f)
				if not _by_name.has(f.name):
					_by_name[f.name] = []
				(_by_name[f.name] as Array).append(f)
				i = f.b1 + 1
			else:
				i = close + 1
		elif t == "{":
			i = _match(i) + 1
		else:
			i += 1


## Per function: calls, direct derivative use, reads of per-fragment globals; then closure over the call graph.
func _scan_functions() -> void:
	for f: FuncDef in _funcs:
		for k in range(f.b0, f.b1):
			var t := _tt[k]
			if not _is_ident(t) or _tt[k - 1] == ".":
				continue
			if _tt[k + 1] == "(":
				if DERIV_BUILTINS.has(t):
					f.deriv = true
				elif _by_name.has(t) and not f.calls.has(t):
					f.calls.append(t)
			elif _varyings.has(t) or _is_frag_builtin(t):
				f.impure = true
	var grew := true
	while grew:
		grew = false
		for f: FuncDef in _funcs:
			for c: String in f.calls:
				for g: FuncDef in _by_name[c]:
					if g.deriv and not f.deriv:
						f.deriv = true
						grew = true
					if g.impure and not f.impure:
						f.impure = true
						grew = true


func _is_frag_builtin(t: String) -> bool:
	return t == t.to_upper() and _is_id0(t.unicode_at(0)) and t.to_upper() != t.to_lower() \
		and not UNIFORM_BUILTINS.has(t) and not _consts.has(t) and not _defines.has(t) and not _uniforms.has(t)


## "" when the tokens [a, b) only read uniform values, else the first per-fragment identifier.
func _eval(a: int, b: int) -> String:
	for k in range(a, b):
		var t := _tt[k]
		if not _is_ident(t) or (k > 0 and _tt[k - 1] == "."):
			continue
		if k + 1 < _tt.size() and _tt[k + 1] == "(":
			if _by_name.has(t):
				for g: FuncDef in _by_name[t]:
					if g.impure:
						return t + "()"
			continue
		if KEYWORDS.has(t) or QUALIFIERS.has(t) or _is_type(t):
			continue
		if _f.env.has(t):
			if not bool(_f.env[t]):
				return t
			continue
		if _uniforms.has(t) or _consts.has(t) or _defines.has(t) or UNIFORM_BUILTINS.has(t) or _flat_varyings.has(t):
			continue
		return t
	return ""


func _set_env(name: String, uni: bool) -> void:
	if not _f.env.has(name):
		_f.env[name] = uni
		if not _collect:
			_changed = true
	elif not uni and bool(_f.env[name]):
		_f.env[name] = false
		_changed = true


func _short(k: int) -> String:
	return "%s:%d" % [_tp[k].get_file(), _tl[k]]


# ---------------------------------------------------------------------------------------------------- statements

func _parse_stmt(ctx: String) -> void:
	if _p >= _end:
		return
	var t := _tt[_p]
	if t == "{":
		var close := _match(_p)
		_p += 1
		while _p < close:
			var before := _p
			_parse_stmt(ctx)
			if _p <= before:
				_p = before + 1
		_p = close + 1
		return
	if t == ";":
		_p += 1
		return
	if (t == "if" or t == "switch" or t == "while") and _p + 1 < _end and _tt[_p + 1] == "(":
		var o := _p + 1
		var c := _match(o)
		_effects(o + 1, c, ctx)
		var inner := ctx
		if t != "while" and inner == "":
			var bad := _eval(o + 1, c)
			if bad != "":
				inner = "%s at %s reads `%s`" % [t, _short(_p), bad]
		_p = c + 1
		_parse_stmt(inner)
		if t == "if" and _p < _end and _tt[_p] == "else":
			_p += 1
			_parse_stmt(inner)
		return
	if t == "for" and _p + 1 < _end and _tt[_p + 1] == "(":
		var o2 := _p + 1
		var c2 := _match(o2)
		var s1 := _find0(o2 + 1, c2, ";")
		var s2 := _find0(s1 + 1, c2, ";")
		_effects(o2 + 1, s1, ctx)
		var cond_bad := _eval(s1 + 1, s2)
		_effects(s2 + 1, c2, ctx if cond_bad == "" else "loop bound reads `%s`" % cond_bad, true)
		_p = c2 + 1
		_parse_stmt(ctx)
		return
	if t == "do":
		_p += 1
		_parse_stmt(ctx)
		_p = _find0(_p, _end, ";") + 1
		return
	if t == "case" or t == "default":
		_p = _find0(_p, _end, ":") + 1
		return
	if t == "else":
		_p += 1
		return
	var e := _find0(_p, _end, ";")
	_effects(_p, e, ctx)
	_p = e + 1


## Derivative hits, call-site parameter flow and local taint for the statement tokens [a, b).
func _effects(a: int, b: int, ctx: String, no_hits := false) -> void:
	# calls
	for k in range(a, b):
		var t := _tt[k]
		if not _is_ident(t) or k + 1 >= b or _tt[k + 1] != "(" or (k > 0 and _tt[k - 1] == "."):
			continue
		var user := _by_name.has(t)
		var is_deriv := DERIV_BUILTINS.has(t)
		if user:
			for g: FuncDef in _by_name[t]:
				is_deriv = is_deriv or g.deriv
		if is_deriv and ctx != "" and _collect and not no_hits:
			var mk := "%s:%d" % [_tp[k], _tl[k]]
			if not String(_markers.get(mk, "")).contains(OK_DERIV):
				var what := "%s()" % t if DERIV_BUILTINS.has(t) else "%s() (calls a derivative)" % t
				_hits[mk + " [B]"] = "%s in a per-fragment branch: %s" % [what, ctx]
		if not user:
			continue
		var close := _match(k + 1)
		var args: Array[Vector2i] = []
		var s := k + 2
		while s < close:
			var e := _find0(s, close, ",")
			args.append(Vector2i(s, e))
			s = e + 1
		var any_bad := ctx != ""
		for g: FuncDef in _by_name[t]:
			if g.params.size() != args.size():
				continue
			for ai in args.size():
				var bad := _eval(args[ai].x, args[ai].y)
				if bad != "":
					any_bad = true
					if bool(g.env.get(g.params[ai], true)):
						g.env[g.params[ai]] = false
						_changed = true
			for ai in args.size():
				if g.quals[ai] != "in" and (any_bad or g.impure) and _is_ident(_tt[args[ai].x]):
					_set_env(_tt[args[ai].x], false)
	# declaration
	var j := a
	while j < b and QUALIFIERS.has(_tt[j]):
		j += 1
	if j + 1 < b and _is_type(_tt[j]) and (_is_ident(_tt[j + 1]) or _tt[j + 1] == "["):
		j += 1
		if _tt[j] == "[":
			j = _match(j) + 1
		while j < b:
			var e2 := _find0(j, b, ",")
			var nm := _tt[j]
			var eq := _find0(j, e2, "=")
			var uni := ctx == "" and (eq >= e2 or _eval(eq + 1, e2) == "")
			if _is_ident(nm):
				_set_env(nm, uni)
			j = e2 + 1
		return
	# assignment / increment
	var depth := 0
	for k2 in range(a, b):
		var t2 := _tt[k2]
		if t2 == "(" or t2 == "[":
			depth += 1
		elif t2 == ")" or t2 == "]":
			depth -= 1
		elif depth == 0 and ASSIGN_OPS.has(t2):
			var base := _first_ident(a, k2)
			if base != "" and (ctx != "" or _eval(k2 + 1, b) != ""):
				_set_env(base, false)
			return
		elif depth == 0 and (t2 == "++" or t2 == "--") and ctx != "":
			var base2 := _first_ident(a, b)
			if base2 != "":
				_set_env(base2, false)
			return


func _first_ident(a: int, b: int) -> String:
	for k in range(a, b):
		var t := _tt[k]
		if _is_ident(t) and not KEYWORDS.has(t) and not QUALIFIERS.has(t):
			return t
	return ""

extends SceneTree
## G-E fix 5 (docs/art/ge_review.md item 5, docs/art/ge_fixes_a.md): an additive material drawn WITH depth fog adds the
## fog colour over its whole quad (transparent corners included), so every additive glow / particle quad shows as a pale
## square at range. Shaders are checked by tests/test_shader_lint.gd rule C; this test reads the text of every .gd under
## res://art/ and res://scripts/ (no rendering) and flags a function that sets `<mat>.blend_mode` to BLEND_MODE_ADD (or to
## a variable, in a file that uses BLEND_MODE_ADD: the `_quad(blend)` helpers) without touching `<mat>.disable_fog`
## (or FLAG_DISABLE_FOG) in the same function. CanvasItemMaterial (2D) is ignored. It also reads every .tres / .tscn
## under res://art/ and res://scripts/: a StandardMaterial3D section with `blend_mode = 1` (add) needs `disable_fog = true`.
## `# lint: fog-ok` on the blend_mode line exempts one .gd hit (a material that must fog, e.g. a big translucent sheet).
## art/ hits FAIL, except art/cinematics/ (films: close cameras, own environments; four-wizards-high owns the forge_*
## stage sets) and PENDING; scripts/ hits are listed as known (other owners, handoff in docs/handoff/).
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_ge_additive_fog.gd --quit-after 600

const TASK_ID := "ge_additive_fog"
const ROOTS: Array[String] = ["res://art", "res://scripts"]
const OK_MARK := "lint: fog-ok"
## Files another agent is still editing when this test landed (2026-10-15). They are reported, not failed; remove a
## line once its owner has added disable_fog (the handoff in docs/handoff/for-tech-artist.md names them).
const PENDING: Array[String] = []
## Reported, never failed.
const REPORT_ONLY: Array[String] = ["res://art/cinematics/"]

var _re_assign := RegEx.new()
var _re_func := RegEx.new()


func _initialize() -> void:
	_re_assign.compile("([A-Za-z_][A-Za-z0-9_]*(?:\\.[A-Za-z_][A-Za-z0-9_]*)*)\\.blend_mode\\s*=\\s*(.+)$")
	_re_func.compile("^\\s*(?:static\\s+)?func\\s")
	var ok := _self_test()
	var paths: Array[String] = []
	for r: String in ROOTS:
		_list(r, paths)
	paths.sort()
	var art_hits: Array[String] = []
	var known: Array[String] = []
	for p: String in paths:
		var text := FileAccess.get_file_as_string(p)
		var hits := _scan(p, text) if p.ends_with(".gd") else _scan_res(p, text)
		for h: String in hits:
			if p.begins_with("res://art/") and not PENDING.has(p) and not _report_only(p):
				art_hits.append(h)
			else:
				known.append(h)
	var verbose := OS.get_cmdline_user_args().has("--verbose")
	for h: String in known:
		if verbose or not h.begins_with("res://art/cinematics/"):
			print("known (other owner / pending): ", h)
	for h: String in art_hits:
		print("HIT ", h)
	print("ge_additive_fog: %d .gd / .tres / .tscn files, %d art/ hit(s), %d known" % [paths.size(), art_hits.size(), known.size()])
	if not ok:
		print("FAIL %s: self-test failed" % TASK_ID)
	elif art_hits.size() > 0:
		print("FAIL %s: %d additive material(s) under art/ without disable_fog" % [TASK_ID, art_hits.size()])
	else:
		print("PASS %s" % TASK_ID)
	quit(0 if ok and art_hits.is_empty() else 1)


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
			elif n.ends_with(".gd") or n.ends_with(".tres") or n.ends_with(".tscn"):
				out.append(full)
		n = d.get_next()
	d.list_dir_end()


func _report_only(p: String) -> bool:
	for pre: String in REPORT_ONLY:
		if p.begins_with(pre):
			return true
	return false


## .tres / .tscn: "path:line  [section]" per StandardMaterial3D / ORMMaterial3D section with blend_mode = 1 (add)
## and no disable_fog = true.
func _scan_res(path: String, text: String) -> Array[String]:
	var out: Array[String] = []
	if not text.contains("blend_mode = 1"):
		return out
	var lines := text.replace("\r\n", "\n").split("\n")
	var mat_file := lines.size() > 0 and (lines[0].contains("type=\"StandardMaterial3D\"") or lines[0].contains("type=\"ORMMaterial3D\""))
	var head := -1
	var is_mat := false
	var add_line := -1
	var fog := false
	for i in lines.size() + 1:
		var l := lines[i] if i < lines.size() else "["
		if l.begins_with("["):
			if is_mat and add_line >= 0 and not fog:
				out.append("%s:%d  %s" % [path, add_line + 1, lines[head]])
			head = i
			is_mat = l.contains("type=\"StandardMaterial3D\"") or l.contains("type=\"ORMMaterial3D\"") or (l == "[resource]" and mat_file)
			add_line = -1
			fog = false
		elif l == "blend_mode = 1":
			add_line = i
		elif l == "disable_fog = true":
			fog = true
	return out


## "path:line  text" per additive material without disable_fog.
func _scan(path: String, text: String) -> Array[String]:
	var out: Array[String] = []
	if not text.contains("BLEND_MODE_ADD"):
		return out
	var lines := text.split("\n")
	# function ranges
	var starts: Array[int] = [0]
	for i in lines.size():
		if _re_func.search(lines[i]) != null:
			starts.append(i)
	starts.append(lines.size())
	for s in range(starts.size() - 1):
		var a := starts[s]
		var b := starts[s + 1]
		var body := "\n".join(lines.slice(a, b))
		if body.contains("CanvasItemMaterial.new()") and not body.contains("StandardMaterial3D"):
			continue
		for i in range(a, b):
			var line := lines[i]
			var code := line.split("#")[0] if not line.contains("\"#") else line
			var m := _re_assign.search(code)
			if m == null:
				continue
			var recv := m.get_string(1)
			var rhs := m.get_string(2).strip_edges()
			if rhs.contains("CanvasItemMaterial"):
				continue
			var is_add := rhs.contains("BLEND_MODE_ADD")
			var maybe := not rhs.contains("BLEND_MODE_")   # a variable / parameter in a file that uses ADD
			if not (is_add or maybe):
				continue
			if line.contains(OK_MARK):
				continue
			if body.contains(recv + ".disable_fog") or (body.contains(recv + ".set_flag(") and body.contains("FLAG_DISABLE_FOG")):
				continue
			out.append("%s:%d  %s" % [path, i + 1, line.strip_edges()])
	return out


const _SELF := """func a() -> void:
	var m := StandardMaterial3D.new()
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
func b(blend: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.blend_mode = blend
	m.disable_fog = blend == BaseMaterial3D.BLEND_MODE_ADD
	return m
func c(blend: int) -> void:
	var q := StandardMaterial3D.new()
	q.blend_mode = blend
func d() -> void:
	var m := StandardMaterial3D.new()
	m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	var k := StandardMaterial3D.new()
	k.blend_mode = BaseMaterial3D.BLEND_MODE_ADD  # lint: fog-ok
	var c2 := CanvasItemMaterial.new()
	c2.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
"""
const _SELF_RES := """[gd_scene format=3]

[sub_resource type="StandardMaterial3D" id="a"]
blend_mode = 1
shading_mode = 0

[sub_resource type="StandardMaterial3D" id="b"]
blend_mode = 1
disable_fog = true

[sub_resource type="CanvasItemMaterial" id="c"]
blend_mode = 1
"""


func _self_test() -> bool:
	var res_hits := _scan_res("res://__self.tscn", _SELF_RES)
	if res_hits.size() != 1 or not res_hits[0].begins_with("res://__self.tscn:4 "):
		print("self-test (res): ", res_hits)
		return false
	var hits := _scan("res://__self.gd", _SELF)
	var want: Array[String] = ["res://__self.gd:3", "res://__self.gd:11"]
	var got: Array[String] = []
	for h: String in hits:
		got.append(h.split("  ")[0])
	if got != want:
		print("self-test: want ", want, " got ", got)
		return false
	return true

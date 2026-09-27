extends SceneTree
## Task 12.V2 (ground: river cut + banks + biome tint). Headless checks:
## - ground.gdshader declares the 12.V2 uniforms with the spec names / types (river_segs vec4[16], river_count,
##   river_half_width, moat vec4, fords vec4[4], biome_amount, biome_tints vec3[4] ...), defaults = no river and no
##   biomes, the MAP.P1 / 10.V10 uniforms and defaults are intact, still ONE sampler (no biome mask texture: the
##   zones are analytic), no screen / depth reads, one discard (the cut);
## - ground_material.tres, menu_ground_mat.tres and plateau_mat.tres leave the river and biomes off;
## - ground_params.gd: the map-fill.md 2.1 / 2.2 / 3.1 values (10 segments, 4 circles, moat, point mirror), the CPU
##   mirror of the cut (deep water cut, fords / Crown Steps / isle / land not, bridges cut under their decks, the
##   river's round end never bites into the isle), a mirror-symmetric cut over the whole map with a sane area,
##   apply() on a copy of the ground material (and refusal on another shader);
## - the live skirmish ground: river either off (before 12.C1) or exactly the spec values.
## Run: $GODOT --headless --path . -s tests/test_12_v2.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "12.v2"
const SHADER := "res://art/environment/ground.gdshader"
const GP := "res://art/environment/ground_params.gd"
const MATS: Array[String] = ["res://art/environment/ground_material.tres",
	"res://art/environment/menu_diorama/menu_ground_mat.tres", "res://art/environment/plateau_mat.tres"]
const DECLS: Array[String] = [
	"uniform vec4 river_segs[16];",
	"uniform int river_count = 0;",
	"uniform float river_half_width = 2.5;",
	"uniform vec4 moat = vec4(0.0);",
	"uniform vec4 fords[4];",
	"uniform vec4 river_box = vec4(0.0);",
	"uniform float bank_width = 2.5;",
	"uniform float biome_amount = 0.0;",
	"uniform vec3 biome_tints[4] : source_color;",
	"uniform vec4 biome_ruins[8];",
	"uniform int biome_ruin_count = 0;",
	"uniform bool skip_sun_shadow = true;",
	# unchanged from MAP.P1 / 10.V10
	"uniform int road_count = 0;",
	"uniform vec4 road_segs[16];",
	"uniform vec2 sun_dir = vec2(0.64, 0.77);",
	"uniform float patch_contrast = 0.58;",
	"uniform float edge_lip = 1.0;",
	"uniform float cliff_ao = 0.38;",
	"uniform float outer_cool = 1.0;",
]
const TIMEOUT_FRAMES := 5000

var main: Node
var _fails: PackedStringArray = PackedStringArray()
var _frame := 0
var _gp: GDScript


func _initialize() -> void:
	_gp = load(GP) as GDScript
	_check_shader()
	_check_materials()
	if _gp == null:
		_fail("ground_params.gd does not load")
	else:
		_check_params()
		_check_cut()
		_check_apply()
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	_frame += 1
	if main.get(&"hero") == null:
		if _frame > TIMEOUT_FRAMES:
			_fail("the skirmish never finished loading")
			return _finish()
		return false
	_check_live()
	return _finish()


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("  - %s" % f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	return true


func _fail(msg: String) -> void:
	_fails.append(msg)


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fail(msg)


# ---------------------------------------------------------------- shader

func _check_shader() -> void:
	var sh := load(SHADER) as Shader
	if sh == null:
		_fail("ground.gdshader does not load")
		return
	var code: String = sh.code
	var flat := "\n".join(Array(code.split("\n")).map(func(l: String) -> String: return l.strip_edges()))
	for d: String in DECLS:
		_check(flat.contains("\n" + d), "ground.gdshader: missing declaration '%s'" % d)
	var samplers := 0
	for line: String in code.split("\n"):
		if line.strip_edges().begins_with("uniform ") and line.contains("sampler2D"):
			samplers += 1
	_check(samplers == 1, "ground.gdshader has %d samplers (must stay 1: the paint noise)" % samplers)
	_check(not code.contains("biome_mask"), "no biome mask texture (analytic zones)")
	_check(code.count("{") == code.count("}"), "unbalanced braces")
	_check(not code.contains("SCREEN_TEXTURE") and not code.contains("hint_screen_texture")
			and not code.contains("hint_depth_texture"), "no screen / depth reads")
	_check(code.count("discard;") == 1 and flat.contains("if (cut) {\ndiscard;"), "exactly one discard, on `cut`")
	# The whole river layer hides behind river_on, the biome layer behind biome_amount (defaults skip them).
	_check(flat.contains("bool river_on = river_count > 0 || moat.z > 0.0;"), "river layer gated by river_on")
	_check(flat.contains("if (biome_amount > 0.0) {"), "biome layer gated by biome_amount")
	# Perf: the plane stays out of the sun's (orthographic) shadow pass, else the discard makes every cascade run the
	# fragment shader over the whole plane.
	_check(flat.contains("if (skip_sun_shadow && PROJECTION_MATRIX[3][3] > 0.5) {"), "sun shadow-pass skip missing")
	# Godot has no defaults for uniform arrays (a compile error that greys the whole ground): none may have one.
	for line: String in code.split("\n"):
		var l := line.get_slice("//", 0).strip_edges()
		if l.begins_with("uniform ") and l.get_slice("=", 0).contains("["):
			_check(not l.contains("="), "uniform array with a default value: %s" % l)


func _check_materials() -> void:
	for path: String in MATS:
		var m := load(path) as ShaderMaterial
		if m == null:
			_fail("%s does not load" % path)
			continue
		_check(m.shader != null and m.shader.resource_path == SHADER, "%s must use ground.gdshader" % path)
		for k: StringName in [&"river_count", &"biome_amount", &"biome_ruin_count"]:
			var v: Variant = m.get_shader_parameter(k)
			_check(v == null or float(v) == 0.0, "%s sets %s = %s (default must stay off)" % [path, k, str(v)])
		var mo: Variant = m.get_shader_parameter(&"moat")
		_check(mo == null or (mo as Vector4).z == 0.0, "%s sets a moat" % path)


# ---------------------------------------------------------------- ground_params.gd

func _check_params() -> void:
	var rp: Dictionary = _gp.skirmish_river()
	var segs: PackedVector4Array = rp[&"river_segs"]
	_check(segs.size() == 16, "river_segs must have 16 slots (got %d)" % segs.size())
	_check(int(rp[&"river_count"]) == 10, "10 river segments (N0-N5 + mirror), got %d" % int(rp[&"river_count"]))
	_check(is_equal_approx(float(rp[&"river_half_width"]), 2.5), "half width 2.5")
	# Perf box: every segment end inside it with the full reach (half width + 10.5 m) to spare.
	var box: Vector4 = rp[&"river_box"]
	_check(box.is_equal_approx(Vector4(-28, -75, 28, 75)), "river_box %s (want (-28, -75, 28, 75))" % str(box))
	_check((rp[&"moat"] as Vector4).is_equal_approx(Vector4(0, 0, 12.75, 1.75)), "moat (0, 0, 12.75, 1.75)")
	var fords: PackedVector4Array = rp[&"fords"]
	_check(fords.size() == 4 and int(rp[&"ford_count"]) == 4, "4 ford / steps circles")
	var want_f: Array[Vector4] = [Vector4(-8.5, -34, 3.5, 0), Vector4(8.5, 34, 3.5, 0), Vector4(-9.02, -9.02, 3.0, 0),
		Vector4(9.02, 9.02, 3.0, 0)]
	for f: Vector4 in want_f:
		_check(fords.has(f), "circle %s missing" % str(f))
	# Spec points N0..N5 in order, and the south river is the point mirror.
	var n_pts: Array[Vector2] = [Vector2(-15, -62), Vector2(-12, -48.7), Vector2(-9, -38), Vector2(-8, -30),
		Vector2(-5, -21), Vector2(-2.5, -12.5)]
	for i: int in 5:
		_check(Vector4(n_pts[i].x, n_pts[i].y, n_pts[i + 1].x, n_pts[i + 1].y).is_equal_approx(segs[i]),
				"segment %d is not N%d-N%d" % [i, i, i + 1])
	for i: int in 10:
		var s: Vector4 = segs[i]
		var found := false
		for j: int in 10:
			var t: Vector4 = segs[j]
			if (Vector2(t.x, t.y).is_equal_approx(-Vector2(s.z, s.w)) and Vector2(t.z, t.w).is_equal_approx(-Vector2(s.x, s.y))):
				found = true
		_check(found, "segment %d has no point mirror" % i)
	var bp: Dictionary = _gp.skirmish_biomes()
	_check(float(bp[&"biome_amount"]) == 1.0, "skirmish biomes on")
	_check(bp[&"biome_tints"] is PackedColorArray and (bp[&"biome_tints"] as PackedColorArray).size() == 4,
			"biome_tints: 4 colours (PackedColorArray, linearised by the renderer)")
	var ruins: PackedVector4Array = bp[&"biome_ruins"]
	var n_ruins: int = int(bp[&"biome_ruin_count"])
	_check(ruins.size() == 8 and n_ruins >= 1 and n_ruins <= 8, "biome_ruins 8 slots, 1-8 used")
	for i: int in n_ruins:
		var r: Vector4 = ruins[i]
		var mirrored := false
		for j: int in n_ruins:
			if Vector2(ruins[j].x, ruins[j].y).is_equal_approx(-Vector2(r.x, r.y)) and is_equal_approx(ruins[j].z, r.z):
				mirrored = true
		_check(mirrored, "ruins circle %s has no point mirror" % str(r))
	_check((bp[&"biome_hubs"] as Vector4).is_equal_approx(Vector4(-36, 36, 36, -36)), "meadow hubs")
	_check((bp[&"biome_woods"] as Vector4).is_equal_approx(Vector4(-50, -50, 50, 50)), "old wood centres")
	_check(is_equal_approx(float(bp[&"biome_heath_edge"]), 44.0), "heath edge 44")
	# The meadow set's GROUND_TINT reaches the tints (when the set exists).
	if ResourceLoader.exists("res://art/environment/biomes/meadow/meadow_set.gd"):
		var mt: Color = (bp[&"biome_tints"] as PackedColorArray)[0]
		_check(mt.is_equal_approx(Color(0.40, 0.56, 0.20)), "meadow tint from meadow_set.gd GROUND_TINT (%s)" % str(mt))


func _cut(p: Vector2) -> bool:
	return bool(_gp.is_cut(_gp.skirmish_river(), p))


func _check_cut() -> void:
	var rp: Dictionary = _gp.skirmish_river()
	var cut_pts: Array[Vector2] = [Vector2(-6.5, -25.5), Vector2(-12.75, 0), Vector2(0, -12.75), Vector2(-12, -48.7),
		Vector2(-9.02, 9.02), Vector2(-10.5, -41.0)]
	var land_pts: Array[Vector2] = [Vector2(-8.5, -34), Vector2(-9.02, -9.02), Vector2(0, 0), Vector2(-30, -24),
		Vector2(-36, 36), Vector2(-15, -15), Vector2(-11.5, -11.5), Vector2(0, -10.0), Vector2(-8.5, -31.0)]
	for p: Vector2 in cut_pts:
		_check(_cut(p) and _cut(-p), "ground must be cut at %s and %s" % [p, -p])
	for p: Vector2 in land_pts:
		_check(not _cut(p) and not _cut(-p), "ground must NOT be cut at %s / %s" % [p, -p])
	# The river's round end at N5 must not bite into the isle: 10.6 m out toward the north mouth is land, although
	# it lies within 2.5 m of N5 (a plain capsule distance would cut it).
	var mouth := Vector2(cos(deg_to_rad(258.69)), sin(deg_to_rad(258.69)))
	var q: Vector2 = mouth * 10.6
	_check(q.distance_to(Vector2(-2.5, -12.5)) < 2.5, "test point setup")
	_check(not _cut(q) and not _cut(-q), "the river mouth bites into the Crown Isle at %s" % q)
	_check(_cut(mouth * 13.0) and _cut(mouth * 16.0), "the river mouth must open into the moat")
	# Bank distance: 1 m from the river edge.
	var wd: float = float(_gp.water_distance(rp, Vector2(-6.5 - 3.5 * 0.95, -25.5 + 3.5 * 0.3)))
	_check(wd > 0.5 and wd < 1.5, "water distance ~1 m off the bank, got %.2f" % wd)
	# Whole map: mirror symmetric, sane water area (rivers ~2 x 52 m x 5 m + moat ~280 m2 - fords).
	var area := 0
	var asym := 0
	for zi: int in range(-62, 63):
		for xi: int in range(-62, 63):
			var p := Vector2(xi + 0.25, zi + 0.25)
			var c: bool = _cut(p)
			if c:
				area += 1
			if c != _cut(-p):
				asym += 1
	_check(asym == 0, "cut not point-symmetric at %d cells" % asym)
	_check(area > 550 and area < 950, "water area %d m2 (expected ~650-700)" % area)
	print("12.V2 cut: %d m2 of deep water in the 124 m square" % area)


func _check_apply() -> void:
	var base := load(MATS[0]) as ShaderMaterial
	if base == null:
		return
	var m := base.duplicate() as ShaderMaterial
	_check(bool(_gp.apply(m, _gp.skirmish_river())), "apply(river) refused on the ground material")
	_check(bool(_gp.apply(m, _gp.skirmish_biomes())), "apply(biomes) refused on the ground material")
	_check(int(m.get_shader_parameter(&"river_count")) == 10, "river_count did not stick")
	_check((m.get_shader_parameter(&"moat") as Vector4).z == 12.75, "moat did not stick")
	_check(float(m.get_shader_parameter(&"biome_amount")) == 1.0, "biome_amount did not stick")
	_check((m.get_shader_parameter(&"river_segs") as PackedVector4Array).size() == 16, "river_segs did not stick")
	_check(m.get_shader_parameter(&"ford_count") == null, "apply must skip keys the shader lacks (ford_count)")
	# The shared saved material is untouched.
	_check(base.get_shader_parameter(&"river_count") == null, "apply changed the saved ground_material.tres")
	var other := load("res://art/environment/water/riverbed_mat.tres") as ShaderMaterial
	if other:
		var o2 := other.duplicate() as ShaderMaterial
		_check(not bool(_gp.apply(o2, _gp.skirmish_river())), "apply must refuse a shader without river_segs")


# ---------------------------------------------------------------- live skirmish

func _check_live() -> void:
	var found := false
	for mi: Node in main.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var sm := m.material_override as ShaderMaterial
		if not (m.mesh is PlaneMesh) or sm == null or sm.shader == null or sm.shader.resource_path != SHADER:
			continue
		if (m.mesh as PlaneMesh).size.x > 121.0:
			continue
		found = true
		var rc: Variant = sm.get_shader_parameter(&"river_count")
		if rc == null or int(rc) == 0:
			print("12.V2 live: skirmish ground has no river yet (12.C1 sets it)")
			continue
		# 12.C1 has plugged the river: it must match the spec values the art was made for.
		var want: Dictionary = _gp.skirmish_river()
		_check(int(rc) == int(want[&"river_count"]), "live river_count %d != %d" % [int(rc), int(want[&"river_count"])])
		_check((sm.get_shader_parameter(&"moat") as Vector4).is_equal_approx(want[&"moat"]), "live moat differs")
		for p: Vector2 in [Vector2(-6.5, -25.5), Vector2(-8.5, -34), Vector2(0, 0)]:
			var live := {&"river_segs": sm.get_shader_parameter(&"river_segs"), &"river_count": int(rc),
				&"river_half_width": sm.get_shader_parameter(&"river_half_width"), &"moat": sm.get_shader_parameter(&"moat"),
				&"fords": sm.get_shader_parameter(&"fords")}
			_check(bool(_gp.is_cut(live, p)) == _cut(p), "live ground cut differs from the spec at %s" % p)
		print("12.V2 live: skirmish ground river_count %d" % int(rc))
	_check(found, "no skirmish ground plane with ground.gdshader")

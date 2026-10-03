extends SceneTree
## Map tools code review fixes (docs/reviews/review-map-tools.md, 2026-10-02): fast checks, no navmesh bake, no level
## in the tree.
## - H1: the painted ground gets the map's halves (MapInfo) for a 176 m, a 112 m and a 168 x 150 m map (map_half_xz,
##   map_half, a skirt reaching >= 200 m past the edge).
## - H2: forge_spacing finds Thornwater's old faults (rich_pocket + guild_pair stacked dens / lodges, a shrine on the
##   peddler) as FAILs; every adopted map in data/maps passes; the gen grid score punishes them.
## - H3: on Quartermeet (not Crown Hollow) bot_point(t, p + v) - bot_point(t, p) == bot_vector(t, v) for both teams;
##   Commander's slot shifts are 4 m and its Ice wall spots stay 2 m from the S1 tower; Crown Hollow: v / -v.
## - H4: rich_hall_spot == the layout's rich_hall slot, and Commander's X2 row resolves to it (Quartermeet, Thornwater).
## - M2: a missing layout path loads as null. M3: auto-fix moves a template's slots with its anchor node and keeps a
##   hand-written move. M5: the fourfold forest lanes are A1 -> B1 and A1 -> A2. L7: the raster limit can fail.
##   L8: the gen seed does not depend on the map id. R1 (grid pre-filter): Quartermeet and Thornwater in their bands.
## Prints "PASS map_review" or "FAIL map_review: <reasons>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_map_review.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "map_review"
const FMap := preload("res://tools/world_forge/forge_map.gd")
const Gen := preload("res://tools/world_forge/forge_gen.gd")
const Spacing := preload("res://tools/world_forge/forge_spacing.gd")
const ChecksV2 := preload("res://tools/map_lab/map_checks_v2.gd")
const COMMANDER := preload("res://scripts/ai/commander.gd")
const MAIN_PATH := "res://scripts/world/main.gd"
const ADOPTED: Array[String] = ["crown_hollow", "crown_hollow_level", "fourfold_hollow", "gloamspine_divide", "kinhearth_vale",
	"quartermeet", "thornwater"]

var fails: Array[String] = []
var notes: Array[String] = []


func _initialize() -> void:
	_h1_ground()
	_h2_spacing()
	_h3_h4_bot_slots()
	_m2_bad_layout()
	_m3_fix_group()
	_m5_lanes()
	_l7_l8()
	_r1_grid()
	MapInfo.reset()
	for n in notes:
		print("  " + n)
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(fails)])
	quit(0 if fails.is_empty() else 1)


func _layout(id: String) -> MapLayout:
	var p := "res://data/maps/%s_layout.tres" % id
	return load(p) as MapLayout if ResourceLoader.exists(p) else null


# ---------------------------------------------------------------- H1

func _h1_ground() -> void:
	var main_script := load(MAIN_PATH) as Script
	for sz: Vector2 in [Vector2(176, 176), Vector2(112, 112), Vector2(168, 150), Vector2(120, 120)]:
		MapInfo.setup(sz.x, sz.y)
		var mat := EnvProps.ground_material(Vector3(-40, 0, 40), Vector3(40, 0, -40), [] as Array[Vector4])
		if mat == null:
			fails.append("H1: no ground material")
			return
		main_script.call(&"apply_map_size", mat)
		var hxz: Variant = mat.get_shader_parameter(&"map_half_xz")
		var mh: Variant = mat.get_shader_parameter(&"map_half")
		var ex: Variant = mat.get_shader_parameter(&"expand_to")
		if not hxz is Vector2 or not (hxz as Vector2).is_equal_approx(sz * 0.5):
			fails.append("H1 %s: map_half_xz %s, want %s" % [sz, hxz, sz * 0.5])
		if not is_equal_approx(float(mh), maxf(sz.x, sz.y) * 0.5):
			fails.append("H1 %s: map_half %s" % [sz, mh])
		if float(ex) < maxf(sz.x, sz.y) * 0.5 + 199.0:
			fails.append("H1 %s: expand_to %s (skirt < 200 m)" % [sz, ex])
	var names := {}
	for u: Dictionary in (load("res://art/environment/ground.gdshader") as Shader).get_shader_uniform_list():
		names[String(u["name"])] = true
	if not names.has("map_half_xz"):
		fails.append("H1: ground.gdshader has no map_half_xz uniform")
	notes.append("H1: ground map_half_xz / map_half / expand_to set for 176, 112, 168 x 150 and 120 m")
	MapInfo.reset()


# ---------------------------------------------------------------- H2

func _h2_spacing() -> void:
	for id in ADOPTED:
		var fm := FMap.new()
		if not fm.compile("res://data/maps/%s.map" % id):
			fails.append("H2: %s does not compile" % id)
			continue
		var f := Spacing.findings(fm.layout)
		if not f.is_empty():
			fails.append("H2: %s spacing %s" % [id, ", ".join(Spacing.lines(f))])
	# the faults Thornwater shipped with: rich_pocket + guild_pair on one side, a shrine 2.3 m from the peddler
	var text := "map sp_bad  size=120  symmetry=rot180\nseat 0 side=0 frame=identity\nseat 1 side=1 frame=rot180\n" + \
		"keep home at=(-43,43)\nuse rich_pocket rich at=(-38.6,-41.7) yaw=-4.4\nuse guild_pair guilds at=(-48.1,-51.0) yaw=43.3\n" + \
		"use tavern_peddler inn at=(-13.8,-14.3) yaw=227.5\npoint shrine sub=shrine at=(-22.3,-5.4)\n"
	var bad := _compile_text(text, "sp_bad")
	if bad != null:
		var f := Spacing.findings(bad.layout)
		var dup := f.filter(func(x: Dictionary) -> bool: return x["rule"] == "duplicate").size()
		var shrine := f.filter(func(x: Dictionary) -> bool: return "%s %s" % [x["a"], x["b"]] in ["shrine inn_peddler", "inn_peddler shrine"]).size()
		if dup < 2 or shrine < 1:
			fails.append("H2: spacing missed the stacked guild houses (%d duplicates) or the shrine on the peddler (%d): %s" % [dup, shrine,
				", ".join(Spacing.lines(f))])
		var hint_ok := false
		for x: Dictionary in f:
			hint_ok = hint_ok or String(x["hint"]).contains("guild_pair")
		if not hint_ok:
			fails.append("H2: no hint names guild_pair")
		# World Forge L3 is a FAIL now
		bad.report.setup("map", "sp_bad")
		bad.call(&"_layout_checks")
		var l3 := ""
		for c: Dictionary in bad.report.checks:
			if String(c.get("id", "")) == "L3":
				l3 = String(c.get("status", ""))
		if l3 != "FAIL":
			fails.append("H2: World Forge L3 is %s, want FAIL" % l3)
		var g := Gen.new("sp_bad", "river_split", 2, "standard", "meadow")
		var sc := g.score_layout(bad.layout)
		if int(sc.get("close", 0)) < 1 or float(sc["score"]) < 200.0:
			fails.append("H2: gen score ignores spacing (close %s, score %s)" % [sc.get("close"), sc.get("score")])
		notes.append("H2: adopted maps clean; stacked layout -> %d spacing FAILs, L3 %s, gen close %d" % [f.size(), l3, int(sc.get("close", 0))])
	MapInfo.reset()


func _compile_text(text: String, name: String) -> FMap:
	var path := "user://%s.map" % name
	var fh := FileAccess.open(path, FileAccess.WRITE)
	fh.store_string(text)
	fh.close()
	var fm := FMap.new()
	if not fm.compile(path):
		fails.append("%s did not compile: %s" % [name, " / ".join(fm.spec.error_lines())])
		return null
	return fm


# ---------------------------------------------------------------- H3 / H4

func _level_for(lay: MapLayout) -> LayoutLevel:
	MapInfo.setup(lay.size_x, lay.size_z, lay.id)
	var lv := LayoutLevel.new()
	lv.layout = lay
	lv.call(&"_assign_seats")
	return lv


func _h3_h4_bot_slots() -> void:
	# Commander with no level: the plain skirmish mirror
	var cmd0: Node = COMMANDER.new()
	cmd0.set(&"team", 0)
	if (cmd0.call(&"_side_vec", Vector3(4, 0, 0)) as Vector3) != Vector3(-4, 0, 0):
		fails.append("H3: _side_vec without a level is not the mirror")
	cmd0.free()
	for id: String in ["crown_hollow_level", "quartermeet", "thornwater"]:
		var lay := _layout(id)
		if lay == null:
			fails.append("H3: no %s layout" % id)
			continue
		var lv := _level_for(lay)
		var worst := 0.0
		for team: int in [0, 1]:
			for p: Vector3 in [Vector3(16, 0, -6), Vector3(33, 0, 33), Vector3(27, 0, -45)]:   # Commander base points (Shadow side)
				for v: Vector3 in [Vector3(4, 0, 0), Vector3(0, 0, 4), Vector3(-2, 0, 0), Vector3(2, 0, 0), Vector3(3, 0, -5)]:
					var a := lv.bot_point(team, p)
					var b := lv.bot_point(team, p + v)
					var vec := lv.bot_vector(team, v)
					if MapInfo.contains(a, 3.5) and MapInfo.contains(b, 3.5):   # bot_point clamps 3 m inside the edge
						worst = maxf(worst, (b - a).distance_to(vec))
					if not is_equal_approx(vec.length(), v.length()):
						fails.append("H3 %s: |bot_vector| %.2f for |v| %.2f" % [id, vec.length(), v.length()])
					if id == "crown_hollow_level" and vec.distance_to(v if team == 1 else -v) > 0.001:
						fails.append("H3 crown hollow: bot_vector(%d, %s) = %s" % [team, v, vec])
			# H4: the rich hall slot of the team's image, and Commander's X2 row
			var slot := lv.call(&"_slot", team, "rich_hall") as Vector3
			var rh := lv.rich_hall_spot(team)
			if slot != Vector3.INF and rh.distance_to(slot) > 0.01:
				fails.append("H4 %s team %d: rich_hall_spot %s vs slot %s" % [id, team, rh, slot])
			var cmd: Node = COMMANDER.new()
			cmd.set(&"team", team)
			cmd.set(&"_level", lv)
			var x2 := {}
			for row: Dictionary in COMMANDER.ROWS:
				if row["id"] == &"X2":
					x2 = row
			var got := cmd.call(&"_row_base", x2) as Vector3
			if got.distance_to(rh) > 0.01:
				fails.append("H4 %s team %d: X2 at %s, rich hall %s" % [id, team, got, rh])
			for shift: Vector3 in COMMANDER.SLOT_SHIFTS:
				var sv := cmd.call(&"_side_vec", shift) as Vector3
				if not is_equal_approx(sv.length(), shift.length()):
					fails.append("H3 %s: slot shift %s -> %s" % [id, shift, sv])
			for w: Vector3 in COMMANDER.WALL_OFFSETS:
				var wv := cmd.call(&"_side_vec", w) as Vector3
				if wv.length() > 2.01:
					fails.append("H3 %s: wall offset %s -> %s (%.1f m from S1)" % [id, w, wv, wv.length()])
			cmd.free()
		if worst > 0.01:
			fails.append("H3 %s: bot_point(p + v) - bot_point(p) differs from bot_vector by %.2f m" % [id, worst])
		notes.append("H3 / H4 %s: linearity worst %.4f m, X2 = rich_hall slot (%s / %s)" % [id, worst, lv.rich_hall_spot(0), lv.rich_hall_spot(1)])
		lv.free()
	MapInfo.reset()


# ---------------------------------------------------------------- M2 / M3 / M5

func _m2_bad_layout() -> void:
	if LayoutLevel.load_layout("res://data/maps/thornwatr_layout.tres") != null or LayoutLevel.load_layout("") != null:
		fails.append("M2: a missing layout path did not load as null")


func _m3_fix_group() -> void:
	var text := "map fixg  size=120  symmetry=rot180\nseat 0 side=0 frame=identity\nseat 1 side=1 frame=rot180\n" + \
		"keep home at=(-43,43)\nuse natural nat at=(-20,20) yaw=0\npoint tower at=(-30,-10)\nmove tower  at=(-31,-10)\n"
	var fm := _compile_text(text, "fixg")
	if fm == null:
		return
	var before := {}
	for s: Dictionary in fm.layout.spots:
		if String(s.get("image", "identity")) == "identity":
			before[String(s["id"])] = s["pos"]
	var path := "user://fixg.map"
	FMap.apply_fixes(path, fm.layout, [{"id": "nat_node", "move": Vector3(3, 0, 0), "why": "test"}], 1)
	var out := FileAccess.get_file_as_string(path)
	var fm2 := FMap.new()
	if not fm2.compile(path):
		fails.append("M3: the fixed map does not compile: %s" % " / ".join(fm2.spec.error_lines()))
		return
	for id: String in ["nat_node", "nat_hall", "nat_tower"]:
		var s := fm2.layout.spot(id)
		if s.is_empty() or (s["pos"] as Vector3).distance_to((before[id] as Vector3) + Vector3(3, 0, 0)) > 0.11:
			fails.append("M3: %s did not move with its template anchor (%s -> %s)" % [id, before.get(id), s.get("pos")])
	if not out.contains("move tower  at=(-31,-10)"):
		fails.append("M3: the hand-written move line was dropped")
	notes.append("M3: nat_node fix moved nat_hall / nat_tower too; hand-written move kept")


func _m5_lanes() -> void:
	var lay := _layout("quartermeet")
	if lay == null:
		return
	var pairs: Array = MapForest.lane_pairs(lay)
	var starts := {}
	for k: Dictionary in lay.spots_of("keep"):
		starts[String(k.get("image", "identity"))] = MapForest.start_of(lay, k)
	var want := [[starts["identity"], starts["rot180"]], [starts["identity"], starts["mirror_z"]]]
	if pairs.size() != 2 or (pairs[0][1] as Vector3).distance_to(want[0][1]) > 0.01 or (pairs[1][1] as Vector3).distance_to(want[1][1]) > 0.01:
		fails.append("M5: fourfold lanes %s, want A1 -> B1 and A1 -> A2" % str(pairs))
	var two := _layout("thornwater")
	if two != null and MapForest.lane_pairs(two).size() != 1:
		fails.append("M5: a 1v1 map has %d lanes" % MapForest.lane_pairs(two).size())


# ---------------------------------------------------------------- L7 / L8 / R1

func _l7_l8() -> void:
	var lay := MapLayout.new()
	lay.size_x = 176.0
	lay.size_z = 176.0
	var r176 := ChecksV2.raster_ratio(lay)
	lay.size_x = 192.0
	lay.size_z = 192.0
	var r192 := ChecksV2.raster_ratio(lay)
	if r176 > ChecksV2.LIMIT_RASTER or r192 <= ChecksV2.LIMIT_RASTER:
		fails.append("L7: raster ratio 176 m %.2f, 192 m %.2f vs limit %.1f (must pass / fail)" % [r176, r192, ChecksV2.LIMIT_RASTER])
	var a := Gen.new("aaa", "river_split", 2, "standard", "meadow").map_text(7).replace("aaa", "X").replace("Aaa", "X")
	var b := Gen.new("bbb", "river_split", 2, "standard", "meadow").map_text(7).replace("bbb", "X").replace("Bbb", "X")
	if a != b:
		fails.append("L8: the same seed gives another map under another id")
	if Gen.rng_seed(7, "river_split", 2, "standard") == Gen.rng_seed(8, "river_split", 2, "standard"):
		fails.append("L8: rng_seed ignores the seed")


func _r1_grid() -> void:
	for id: String in ["quartermeet", "thornwater"]:
		var lay := _layout(id)
		if lay == null:
			continue
		var g := Gen.new(id, String(lay.rules.get("archetype", "river_split")), int(lay.rules.get("players", 2)),
			String(lay.rules.get("tempo", "standard")), lay.biome)
		var sc := g.score_layout(lay)
		var miss: Dictionary = sc.get("miss", {})
		for k: String in miss:
			if is_inf(float(miss[k])) or float(miss[k]) > ChecksV2.BAND_FAIL:
				fails.append("R1 %s: %s %.0f %% outside its band (grid)" % [id, k, 100.0 * float(miss[k])])
		if int(sc.get("close", 0)) > 0:
			fails.append("R1 %s: %d spacing FAILs" % [id, int(sc["close"])])
		notes.append("R1 grid %s: %s" % [id, JSON.stringify(sc.get("measures", {}))])

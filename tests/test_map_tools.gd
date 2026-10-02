extends SceneTree
## Map tools MT1 / MT3 / MT4 / MT5 / MT6 / MT7 (docs/design/map-production.md 2, 4.2): fast checks, no navmesh bake.
## - MT1 MapInfo: setup / bounds / clamp; a FogOfWar sized from it (168 x 150 m -> 84 x 75 cells; 120 m -> 60 x 60).
## - MT3 grammar v2: every v1 .map in data/maps compiles to the same spots as before (ids, kinds, positions vs its saved
##   _layout.tres); `size=WxD`, `rules`, `closed_seat`, `forest`, `prop`, `block kind=`, `mark` / `trigger` / `path`,
##   overlays (`base=`, `move`, `remove`, `set`) and their MapLayout accessors; bad input teaches (template did-you-mean).
## - MT4 templates: every data/maps/templates/*.mapt expands; base_district at Crown Hollow's keep gives Crown Hollow's
##   home nodes and start (the bot slots stay valid).
## - MT2 data: crown_hollow_level.map compiles, MapForest plans the same forest twice (determinism).
## - MT5 gen: a 1v1 and a 2v2 candidate compile, are mirrored, and the grid pre-filter puts them in their bands.
## - MT6: apply_fixes writes `move` autofix lines that the next compile applies (<= 5 m).
## - MT7: the contact sheet composes (headless) and the 5 x 7 font has every glyph.
## Prints "PASS map_tools" or "FAIL map_tools: <reasons>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_map_tools.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "map_tools"
const FMap := preload("res://tools/world_forge/forge_map.gd")
const Grammar := preload("res://tools/world_forge/forge_map_grammar.gd")
const Gen := preload("res://tools/world_forge/forge_gen.gd")
const Sheet := preload("res://tools/world_forge/forge_sheet.gd")

var fails: Array[String] = []
var notes: Array[String] = []


func _initialize() -> void:
	_mt1()
	_mt3_v1_maps()
	_mt3_grammar()
	_mt4_templates()
	_mt2_forest()
	_mt5_gen()
	_mt6_fix()
	_mt7_sheet()
	MapInfo.reset()
	for n in notes:
		print("  " + n)
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(fails)])
	quit(0 if fails.is_empty() else 1)


func _write(path: String, text: String) -> String:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return path


func _compile_text(text: String, name: String) -> FMap:
	var fm := FMap.new()
	if not fm.compile(_write("user://%s.map" % name, text)):
		fails.append("%s did not compile: %s" % [name, " / ".join(fm.spec.error_lines())])
	return fm


# ---------------------------------------------------------------- MT1

func _mt1() -> void:
	MapInfo.setup(168, 150)
	if not is_equal_approx(MapInfo.half_x(), 84.0) or not is_equal_approx(MapInfo.half_z(), 75.0) or MapInfo.size_max() != 168.0:
		fails.append("MapInfo halves %s %s" % [MapInfo.half_x(), MapInfo.half_z()])
	if MapInfo.contains(Vector3(80, 0, 76)) or not MapInfo.contains(Vector3(83, 0, -74)):
		fails.append("MapInfo.contains")
	if MapInfo.clamp_point(Vector3(100, 0, -100), 2.0) != Vector3(82, 0, -73):
		fails.append("MapInfo.clamp_point %s" % MapInfo.clamp_point(Vector3(100, 0, -100), 2.0))
	var fog := FogOfWar.new()
	root.add_child(fog)
	if fog.grid_w != 84 or fog.grid_d != 75 + 1:   # 150 / 2 = 75 cells, rounded up to an even count (76)
		fails.append("fog grid %d x %d for 168 x 150 m (want 84 x 76)" % [fog.grid_w, fog.grid_d])
	if fog.grid_image(0).get_width() != fog.grid_w:
		fails.append("fog grid_image width %d" % fog.grid_image(0).get_width())
	fog.reveal(0, Vector3(80, 0, 70), 4.0)
	if not fog.is_explored(0, Vector3(80, 0, 70)) or fog.is_explored(0, Vector3(-80, 0, -70)):
		fails.append("fog reveal on a 168 x 150 map")
	fog.free()
	MapInfo.reset()
	var fog2 := FogOfWar.new()
	root.add_child(fog2)
	if fog2.grid_w != FogOfWar.SIZE or fog2.grid_d != FogOfWar.SIZE:
		fails.append("fog grid %d x %d on the 120 m default" % [fog2.grid_w, fog2.grid_d])
	fog2.free()
	notes.append("MT1: MapInfo + fog 168 x 150 -> 84 x 76 cells, 120 -> 60 x 60")


# ---------------------------------------------------------------- MT3

func _mt3_v1_maps() -> void:
	var n := 0
	for id: String in ["crown_hollow", "fourfold_hollow", "kinhearth_vale", "gloamspine_divide"]:
		var old := load("res://data/maps/%s_layout.tres" % id) as MapLayout
		var fm := FMap.new()
		if not fm.compile("res://data/maps/%s.map" % id):
			fails.append("v1 map %s: %s" % [id, " / ".join(fm.spec.error_lines())])
			continue
		if old == null:
			continue
		var a := {}
		for s: Dictionary in old.spots:
			a[String(s["id"])] = [String(s["kind"]), s["pos"]]
		var diff := 0
		for s: Dictionary in fm.layout.spots:
			var e: Variant = a.get(String(s["id"]))
			if e == null or e[0] != String(s["kind"]) or (e[1] as Vector3).distance_to(s["pos"]) > 0.001:
				diff += 1
		if diff > 0 or old.spots.size() != fm.layout.spots.size():
			fails.append("v1 map %s: %d spots differ (%d vs %d)" % [id, diff, old.spots.size(), fm.layout.spots.size()])
		if old.crossings.size() != fm.layout.crossings.size() or old.river.size() != fm.layout.river.size():
			fails.append("v1 map %s: river / crossings differ" % id)
		if not is_equal_approx(fm.layout.size_x, old.size) or not is_equal_approx(fm.layout.size_z, old.size):
			fails.append("v1 map %s: size %s x %s vs %s" % [id, fm.layout.size_x, fm.layout.size_z, old.size])
		n += 1
	notes.append("MT3: %d v1 maps compile to the same spots / river / size" % n)


func _mt3_grammar() -> void:
	var text := """map g2  size=150x120  symmetry=rot180  biome=snow  title="Grammar v2"
seat 0  name="a"  side=0  frame=identity
seat 1  name="b"  side=1  frame=rot180
seat 3  name="c"  side=0  frame=identity
closed_seat 3  becomes=neutral
rules archetype=open  tempo=rush  keep_enemy=100..120  natural=30..36  contest=5
keep  k   at=(-50,30)
node  n_mid  at=(-30,10)  role=mid  clear=6
point tw  sub=watchtower  at=(-20,-30)
block wall1  at=(-10,20)  size=(8,2)  yaw=30  kind=wall
prop  stone  scene=res://nope.tscn  at=(-40,-40)  yaw=10  clear=3  colliders=[(1,0,0.5)]
forest seed=11  pre=auto  pillars=(0,0,9)
grove g  at=(-55,-40)  r=4  trees=5
mark  start_a  at=(-44,24)
trigger zone_ford  circle((0,10),6)
path  wave1  poly=[(60,-30),(20,-10),(-40,20)]
bounds rect((-70,-55),(70,55))
"""
	var fm := _compile_text(text, "g2")
	var lay := fm.layout
	if lay == null or not fm.spec.ok():
		return
	if lay.size_x != 150.0 or lay.size_z != 120.0 or lay.size != 150.0:
		fails.append("size=150x120 -> %s x %s (size %s)" % [lay.size_x, lay.size_z, lay.size])
	if lay.closed_seats != [3]:
		fails.append("closed_seat -> %s" % [lay.closed_seats])
	if lay.target("keep_enemy") != Vector2(100, 120) or String(lay.rules.get("tempo")) != "rush" or float(lay.rules.get("contest")) != 5.0:
		fails.append("rules -> %s" % lay.rules)
	if lay.biome != "snow" or int(lay.forest.get("seed", -1)) != 11 or not bool(lay.forest.get("pre_auto", false)) or lay.groves.size() != 1:
		fails.append("map biome / forest / grove: %s %s %s" % [lay.biome, lay.forest, lay.groves])
	if lay.blocks.size() != 2 or String(lay.blocks[0].get("kind", "")) != "wall":
		fails.append("block kind=wall: %s" % [lay.blocks])
	if lay.props.size() != 2 or not is_equal_approx(rad_to_deg(float(lay.props[1]["yaw"])), 190.0) or (lay.props[1]["pos"] as Vector3).distance_to(Vector3(40, 0, 40)) > 0.01:
		fails.append("prop mirrored: %s" % [lay.props])
	if lay.mark("start_a") != Vector3(-44, 0, 24) or lay.trigger("zone_ford").is_empty() or lay.path("wave1").size() != 3:
		fails.append("mark / trigger / path accessors")
	if lay.play_bounds() != Rect2(-70, -55, 140, 110):
		fails.append("bounds %s" % lay.play_bounds())
	if lay.open_seats().size() != 2:
		fails.append("open_seats %d" % lay.open_seats().size())
	# overlay: base= + move + remove + set
	var over := """map g2_night  base=user://g2.map  variant=night  light=night
move n_mid  at=(-28,12)
remove tw
set k  footprint=8
"""
	var fo := _compile_text(over, "g2_night")
	if fo.layout != null and fo.spec.ok():
		var l2 := fo.layout
		if String(l2.id) != "g2_night" or l2.base != "user://g2.map" or l2.variant != "night" or l2.light != "night":
			fails.append("overlay map line: id %s base %s variant %s light %s" % [l2.id, l2.base, l2.variant, l2.light])
		if (l2.spot("n_mid")["pos"] as Vector3) != Vector3(-28, 0, 12) or not l2.spot("tw").is_empty():
			fails.append("overlay move / remove")
		if float((l2.spot("k")["props"] as Dictionary).get("footprint", 0)) != 8.0:
			fails.append("overlay set")
		if l2.size_x != 150.0 or l2.symmetry != "rot180":
			fails.append("overlay keeps the base map line (size %s, symmetry %s)" % [l2.size_x, l2.symmetry])
	# teaching errors
	var bad := FMap.new()
	bad.compile(_write("user://g2_bad.map", "map bad size=120 symmetry=rot180\nuse base_distrct  at=(-40,40)\nforest sede=3\n"))
	var all := "\n".join(bad.spec.error_lines())
	for want: String in ["did you mean \"base_district\"", "did you mean \"seed\""]:
		if not all.contains(want):
			fails.append("bad v2 input lacks '%s' (got %s)" % [want, all.replace("\n", " / ")])
	notes.append("MT3: grammar v2 statements, overlay base / move / remove / set, errors teach")


# ---------------------------------------------------------------- MT4

func _mt4_templates() -> void:
	var names := Grammar.list_templates()
	if names.size() < 30:
		fails.append("only %d templates (want ~30)" % names.size())
	for t in names:
		var fm := FMap.new()
		var ok := fm.compile(_write("user://tpl_%s.map" % t, "map tpl_%s  size=184  symmetry=none\nseat 0 side=0 frame=identity\nuse %s t  at=(0,0)  yaw=0\n" % [t, t]))
		if not ok:
			fails.append("template %s: %s" % [t, " / ".join(fm.spec.error_lines())])
	# base_district on Crown Hollow's keep = Crown Hollow's home nodes and wizard start
	var fm2 := _compile_text("map bd  size=120  symmetry=rot180\nseat 0 side=0 frame=identity\nseat 1 side=1 frame=rot180\nuse base_district home  at=(-43,43)\n", "bd")
	if fm2.layout != null:
		var want := {"home_a": Vector3(-46, 0, 34), "home_b": Vector3(-34, 0, 46), "home_start": Vector3(-36, 0, 36), "home_keep": Vector3(-43, 0, 43)}
		for sid: String in want:
			var s := fm2.layout.spot(sid)
			if s.is_empty() or (s["pos"] as Vector3).distance_to(want[sid]) > 0.05:
				fails.append("base_district %s at %s, want %s" % [sid, s.get("pos", "-"), want[sid]])
		if fm2.layout.spot("home_keep_twin").is_empty() or int(fm2.layout.spot("home_keep_twin")["team"]) != 1:
			fails.append("base_district twin keep (seat 1)")
		if fm2.layout.templates_used.size() != 1:
			fails.append("templates_used %s" % [fm2.layout.templates_used])
	notes.append("MT4: %d templates expand; base_district = Crown Hollow's district" % names.size())


# ---------------------------------------------------------------- MT2 data

func _mt2_forest() -> void:
	var fm := FMap.new()
	if not fm.compile("res://data/maps/crown_hollow_level.map"):
		fails.append("crown_hollow_level.map: %s" % " / ".join(fm.spec.error_lines()))
		return
	var lay := fm.layout
	MapInfo.setup(lay.size_x, lay.size_z)
	var river := RiverSystem.new()
	river.build_visuals = false
	river.setup(LayoutLevel.river_lines(lay), LayoutLevel.river_half_width(lay), LayoutLevel.moat_of(lay), LayoutLevel.crossings_of(lay))
	var a := MapForest.plan(lay, river)
	var b := MapForest.plan(lay, river)
	river.free()
	if a["hash"] != b["hash"] or (a["trees"] as Array).is_empty():
		fails.append("MapForest not deterministic / empty (%s vs %s)" % [a["hash"], b["hash"]])
	notes.append("MT2: Crown Hollow forest plan %d trees, %d rocks, %d pillars, hash %s" % [(a["trees"] as Array).size(),
		(a["rocks"] as Array).size(), (a["pillars"] as Array).size(), a["hash"]])


# ---------------------------------------------------------------- MT5

func _mt5_gen() -> void:
	for p: int in [2, 4]:
		var g := Gen.new("t%d" % p, "river_split", p, "standard", "meadow")
		var path := _write("user://gen_t%d.map" % p, g.map_text(3))
		var fm := FMap.new()
		if not fm.compile(path):
			fails.append("gen %dp: %s" % [p, " / ".join(fm.spec.error_lines())])
			continue
		var lay := fm.layout
		if lay.symmetry != ("fourfold" if p == 4 else "rot180") or lay.spots_of("keep").size() != p:
			fails.append("gen %dp: symmetry %s, %d keeps" % [p, lay.symmetry, lay.spots_of("keep").size()])
		var t0 := Time.get_ticks_usec()
		var sc := g.score_layout(lay)
		var ms := float(Time.get_ticks_usec() - t0) / 1000.0
		if int(sc.get("unreachable", 1)) != 0:
			fails.append("gen %dp: %d spots unreachable on the grid" % [p, int(sc.get("unreachable", 1))])
		var miss: Dictionary = sc.get("miss", {})
		for k: String in miss:
			if float(miss[k]) > 0.1:
				fails.append("gen %dp: %s %.0f %% outside its band (%s)" % [p, k, 100.0 * float(miss[k]), str(sc["measures"])])
		notes.append("MT5: gen %dp seed 3 grid score %.2f in %.0f ms: %s" % [p, float(sc["score"]), ms, str(sc["measures"])])
	MapInfo.reset()


# ---------------------------------------------------------------- MT6

func _mt6_fix() -> void:
	var path := _write("user://fixme.map", "map fixme  size=120  symmetry=rot180\nseat 0 side=0 frame=identity\nseat 1 side=1 frame=rot180\nkeep k at=(-40,40)\nnode far  at=(-10,10)  role=mid\n")
	var fm := FMap.new()
	fm.compile(path)
	var changed := FMap.apply_fixes(path, fm.layout, [{"id": "far", "move": Vector3(-3, 0, 4), "why": "R1 natural test"},
		{"id": "far", "move": Vector3(-6, 0, 8), "why": "R4 test"}], 1)
	var fm2 := FMap.new()
	if not fm2.compile(path):
		fails.append("fixed map no longer compiles: %s" % " / ".join(fm2.spec.error_lines()))
		return
	var p: Vector3 = fm2.layout.spot("far")["pos"]
	if changed.size() != 1 or p.distance_to(Vector3(-13, 0, 14)) > 0.11:   # (-9, 12) summed, clamped to 5 m
		fails.append("apply_fixes: %s -> far at %s" % [changed, p])
	if (fm2.layout.spot("far_twin")["pos"] as Vector3).distance_to(-p) > 0.01:
		fails.append("apply_fixes: the twin did not follow")
	notes.append("MT6: autofix line %s" % (changed[0] if not changed.is_empty() else "-"))


# ---------------------------------------------------------------- MT7

func _mt7_sheet() -> void:
	for k: String in Sheet.FONT:
		if (Sheet.FONT[k] as String).length() != Sheet.GLYPH_W * Sheet.GLYPH_H:
			fails.append("font glyph '%s' has %d bits" % [k, (Sheet.FONT[k] as String).length()])
	var img := Sheet.contact_sheet([{"title": "A", "lab_score": 88.0, "lab_result": "WARN", "lines": ["GRID 0.1"]},
		{"title": "B", "lab_score": 60.0, "lab_result": "FAIL"}], "TEST SHEET")
	if img.get_width() != 2 * 512 + 3 * 8 or img.get_height() < 1000:
		fails.append("contact sheet %d x %d" % [img.get_width(), img.get_height()])
	notes.append("MT7: contact sheet %d x %d, %d glyphs" % [img.get_width(), img.get_height(), Sheet.FONT.size()])

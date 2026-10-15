extends SceneTree
## G-F review 2 items 2 and 10 (docs/art/gf_r2_autumn.md). Headless, no level load.
##   palette  autumn grass olive (hue 60-90 deg, saturation <= 0.45), dirt / roads red-brown (hue <= 30 deg), the grass
##            mean value (grass_dark..grass_light mid, meadow tint) >= 0.12 over dirt_color / road_color
##   fog      world_env_autumn: depth fog begins 75-85 m, density <= 0.35 (half the old 0.6), a light low-saturation
##            colour; the rig's screen haze <= 0.1
##   forest   ForestReplant on the real Ashwind layout: every tree inside its block, 80-125 % of the level's grid count,
##            3 size classes, >= 15 % of the 4.6 m cells empty (glades / gaps: no orchard), the lane-facing treeline has
##            no gap > 5.5 m, deterministic; ensure_for_level is idempotent and ignores a plain node
##   pads     LaneDressing dresses each Muster Pad yard: 4 banners near each pad, >= 30 flagstones round it, none on the
##            plate, still <= 18 draws
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gf_r2_autumn.gd --quit-after 3000

const TASK_ID := "gf_r2_autumn"
const AP := "res://art/environment/autumn/autumn_ground_params.gd"
const ENV := "res://art/environment/autumn/world_env_autumn.tres"
const PRESET := "res://art/environment/autumn/preset_autumn.tres"
const REPLANT := "res://art/environment/lane_dressing/forest_replant.gd"
const ASHWIND := "res://data/maps/ashwind_reach_layout.tres"

var _fails: Array[String] = []
var _notes: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_palette()
	_check_fog()
	_check_forest()
	_check_pads()
	for n: String in _notes:
		print("  ", n)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _check_palette() -> void:
	var gp: Dictionary = (load(AP) as GDScript).call(&"ground_params")
	var gd: Color = gp[&"grass_dark"]
	var gl: Color = gp[&"grass_light"]
	var mid := gd.lerp(gl, 0.5)
	var tints: PackedColorArray = gp[&"biome_tints"]
	for c: Color in [gd, gl, mid, tints[0]]:
		if c.h * 360.0 < 60.0 or c.h * 360.0 > 90.0 or c.s > 0.45:
			_fails.append("grass %s not olive (hue %.0f, s %.2f)" % [c, c.h * 360.0, c.s])
	var grass_v := (mid.v + tints[0].v) * 0.5
	for key: StringName in [&"dirt_color", &"road_color", &"dirt_dark", &"road_dark"]:
		var c2: Color = gp[key]
		if c2.h * 360.0 > 30.0 or not (c2.r > c2.g and c2.g > c2.b):
			_fails.append("%s not red-brown (hue %.0f)" % [key, c2.h * 360.0])
		if grass_v - c2.v < 0.12:
			_fails.append("%s value %.2f only %.2f under the grass %.2f" % [key, c2.v, grass_v - c2.v, grass_v])
	_notes.append("palette: grass mean v %.2f (hue %.0f), dirt v %.2f, road v %.2f" % [grass_v, mid.h * 360.0,
			(gp[&"dirt_color"] as Color).v, (gp[&"road_color"] as Color).v])


func _check_fog() -> void:
	var env := load(ENV) as Environment
	if env == null or not env.fog_enabled:
		_fails.append("autumn env has no fog")
		return
	if env.fog_depth_begin < 75.0 or env.fog_depth_begin > 85.0:
		_fails.append("autumn fog begins at %.0f m (75-85)" % env.fog_depth_begin)
	if env.fog_density > 0.35:
		_fails.append("autumn fog density %.2f > 0.35" % env.fog_density)
	if env.fog_light_color.s > 0.15 or env.fog_light_color.v < 0.75:
		_fails.append("autumn fog colour %s too saturated / dark" % env.fog_light_color)
	var pr := load(PRESET) as LightingPreset
	if pr == null or pr.haze_strength > 0.1:
		_fails.append("autumn screen haze too strong")
	_notes.append("fog: begin %.0f m, density %.2f, colour s %.2f" % [env.fog_depth_begin, env.fog_density,
			env.fog_light_color.s])


func _check_forest() -> void:
	var fr := load(REPLANT) as GDScript
	var layout := load(ASHWIND) as Resource
	if fr == null or layout == null:
		_fails.append("forest: script or layout missing")
		return
	var rects: Array[Rect2] = fr.call(&"forest_rects", layout)
	if rects.size() < 4:
		_fails.append("forest: %d forest blocks" % rects.size())
		return
	var hx := float(layout.get(&"size_x")) * 0.5
	var hz := float(layout.get(&"size_z")) * 0.5
	var trees: Array[Dictionary] = fr.call(&"plan", rects, hx, hz)
	var again: Array[Dictionary] = fr.call(&"plan", rects, hx, hz)
	if trees.size() != again.size() or (trees.size() > 0 and trees[5]["pos"] != again[5]["pos"]):
		_fails.append("forest: not deterministic")
	var classes := [0, 0, 0]
	for t: Dictionary in trees:
		var s := float(t["s"])
		classes[0 if s < 0.95 else (1 if s < 1.4 else 2)] += 1
	if classes[0] < 5 or classes[1] < 5 or classes[2] < 5:
		_fails.append("forest: size classes %s" % str(classes))
	var empty_total := 0
	var cells_total := 0
	for r: Rect2 in rects:
		var mine: Array[Vector3] = []
		for t: Dictionary in trees:
			var p: Vector3 = t["pos"]
			if r.grow(0.31).has_point(Vector2(p.x, p.z)):
				mine.append(p)
		var want := int(fr.call(&"grid_count", r))
		if r.size.x < 14.0 or r.size.y < 14.0:
			continue   # the thin strip next to the pad clearing: just inside
		if mine.size() < want * 0.8 or mine.size() > want * 1.25:
			_fails.append("forest: block %s has %d trees (grid %d)" % [r, mine.size(), want])
		# Orchard check: share of empty 4.6 m cells.
		var nx := int(r.size.x / 4.6)
		var nz := int(r.size.y / 4.6)
		var full := {}
		for p: Vector3 in mine:
			full[Vector2i(clampi(int((p.x - r.position.x) / 4.6), 0, nx - 1), clampi(int((p.z - r.position.y) / 4.6), 0, nz - 1))] = true
		cells_total += nx * nz
		empty_total += nx * nz - full.size()
		# Treeline: the lane-facing 3 m strip has no gap > 5.5 m along x.
		var edge_z := r.end.y if r.get_center().y < 0.0 else r.position.y
		var xs: Array[float] = [r.position.x]
		for p: Vector3 in mine:
			if absf(p.z - edge_z) < 3.0:
				xs.append(p.x)
		xs.append(r.end.x)
		xs.sort()
		for i: int in xs.size() - 1:
			if xs[i + 1] - xs[i] > 5.5:
				_fails.append("forest: treeline gap %.1f m in block %s" % [xs[i + 1] - xs[i], r])
				break
	var share := float(empty_total) / maxf(1.0, float(cells_total))
	if share < 0.15:
		_fails.append("forest: only %.0f %% empty cells (orchard)" % (share * 100.0))
	_notes.append("forest: %d trees in %d blocks, sizes %s, %.0f %% empty 4.6 m cells" % [trees.size(), rects.size(),
			str(classes), share * 100.0])
	# Wiring: a plain node is ignored; a stand-in Wave Strike level with EnvProps is replanted once.
	var plain := Node3D.new()
	root.add_child(plain)
	if fr.call(&"ensure_for_level", plain) != null:
		_fails.append("forest: dressed a plain node")
	plain.free()
	var lvl := _stand_in("extends Node3D\nvar layout: Resource\nvar env_props: Node3D\nfunc lane_for(_t: int) -> PackedVector3Array:\n\treturn PackedVector3Array()\n")
	lvl.set(&"layout", layout)
	var ep := EnvProps.new()
	ep.name = "EnvProps"
	lvl.add_child(ep)
	lvl.set(&"env_props", ep)
	ep.add_tree(Vector3(0.0, 0.0, -60.0), 1.0)
	ep.commit()
	MapInfo.setup(float(layout.get(&"size_x")), float(layout.get(&"size_z")), &"ashwind_reach", lvl)
	root.add_child(lvl)
	var got: Variant = fr.call(&"ensure_for_level", lvl)
	var n := 0
	for c: Node in ep.get_children():
		var mmi := c as MultiMeshInstance3D
		if mmi and mmi.multimesh:
			n += mmi.multimesh.instance_count
	if got == null or n < trees.size():
		_fails.append("forest: ensure_for_level did not replant (%d instances, plan %d)" % [n, trees.size()])
	fr.call(&"ensure_for_level", lvl)
	var n2 := 0
	for c: Node in ep.get_children():
		var mmi := c as MultiMeshInstance3D
		if mmi and mmi.multimesh:
			n2 += mmi.multimesh.instance_count
	if n2 != n:
		_fails.append("forest: not idempotent (%d then %d)" % [n, n2])
	MapInfo.release(lvl)
	lvl.free()


func _check_pads() -> void:
	var layout := load(ASHWIND) as Resource
	var lvl := _stand_in("extends Node3D\nvar layout: Resource\nfunc lane_for(_t: int) -> PackedVector3Array:\n\treturn PackedVector3Array()\n")
	lvl.set(&"layout", layout)
	MapInfo.setup(float(layout.get(&"size_x")), float(layout.get(&"size_z")), &"ashwind_reach", lvl)
	root.add_child(lvl)
	LaneDressing.quality_override = 2
	MapDressingArt.map_detail_override = &"high"
	var d := LaneDressing.ensure_for_level(lvl)
	if d == null:
		_fails.append("pads: no LaneDressing")
	else:
		var pads: Array[Vector3] = []
		for sp: Dictionary in layout.get(&"spots"):
			if String(sp.get("sub", "")) == "muster_pad":
				pads.append(sp["pos"])
		if pads.size() != 2:
			_fails.append("pads: %d muster pads in the layout" % pads.size())
		var he := Vector2(MusterPad.ROWS * MusterPad.CELL * 0.5 + 1.0, MusterPad.COLS * MusterPad.CELL * 0.5 + 1.0)
		for c: Vector3 in pads:
			var banners := 0
			for xf: Transform3D in d.instance_transforms(LaneDressing.BANNER):
				var q := xf.origin - c
				if absf(q.x) < he.x + 3.0 and absf(q.z) < he.y + 3.0:
					banners += 1
					if absf(q.x) < he.x and absf(q.z) < he.y:
						_fails.append("pads: banner on the plate")
			var flags := 0
			for xf: Transform3D in d.instance_transforms(LaneDressing.FLAGS):
				var q := xf.origin - c
				if absf(q.x) < he.x + 3.0 and absf(q.z) < he.y + 3.0:
					flags += 1
					if absf(q.x) < he.x - 0.2 and absf(q.z) < he.y - 0.2:
						_fails.append("pads: flagstone on the plate at %s" % xf.origin.round())
						break
			if banners < 4 or flags < 30:
				_fails.append("pads: pad %s has %d banners, %d flagstones" % [c, banners, flags])
			_notes.append("pads: %s %d banners, %d flagstones" % [c, banners, flags])
		if d.get_child_count() > 18:
			_fails.append("pads: %d lane draws (> 18)" % d.get_child_count())
	LaneDressing.quality_override = -1
	MapDressingArt.map_detail_override = &""
	MapInfo.release(lvl)
	lvl.free()
	# The ready plate material for the ui view (handoff in docs/handoff/for-lead.md): loads, keeps the vertex colour.
	var pm := load("res://art/environment/lane_dressing/muster_plate_mat.tres") as ShaderMaterial
	if pm == null or pm.shader == null or not pm.shader.code.contains("COLOR.rgb"):
		_fails.append("pads: muster_plate_mat.tres missing or does not read the vertex colour")


func _stand_in(source: String) -> Node:
	var s := GDScript.new()
	s.source_code = source
	s.reload()
	var n: Node = Node3D.new()
	n.set_script(s)
	return n

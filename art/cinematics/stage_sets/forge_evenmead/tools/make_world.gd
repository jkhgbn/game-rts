extends SceneTree
## forge_evenmead world (E34.W2 art pass, set-only tech-art tool, not game code). Reads the terrain of
## forge_evenmead.set through World Forge's own compiler (same heights, same grid) and writes parts/*.tscn:
##   em_ground     the painted meadow skin on the terrain grid (1 draw)
##   em_grass_*    MultiMesh grass tufts (near / mid / far / tall seed grass), dense where the cameras are (4 draws)
##   em_flowers    MultiMesh wildflower drifts: daisy, buttercup, poppy, cornflower, cow parsley, clover (1 draw)
##   em_trees_*    MultiMesh oaks (3), birches, hawthorn / blossom shrubs (2), far woods (7 draws)
##   em_river      the water ribbon (1 draw) + em_riverbed: ford stones, bank pebbles, lily pads, reeds (2 draws)
##   em_camps      tents, pavilions, standards, fire pits (matte + cloth, 2 draws)
##   em_mist / em_glow / em_rays / em_birds: river mist, far haze banks, camp smoke, pollen, glints, god rays, swallows (4 draws)
##   em_far        the far mountain ring: snowy north, snow-dusted east / west, blue southern downs (1 draw)
##   master_tree, standard_shadow, standard_nature, heart_stone, bloom_patch  (props / tagged places)
## Every world mesh sits at the origin (VERTEX = world position); the set loads them as puppets at (0,0,0).
## Deterministic: hashed jitter, fixed seeds.
## Run WINDOWED (no --headless: the dummy renderer drops MultiMesh instance data and the grass / trees would save empty):
##   tools\godot_run.ps1 --path . -s res://art/cinematics/stage_sets/forge_evenmead/tools/make_world.gd --quit-after 60000
##      '--' ['only=ground,grass,flowers,trees,river,camps,air,far,props']  (quote the comma list in PowerShell)
## Order: make_light -> make_world -> bake_armies -> world_forge build -> lens marks -> merge_lens -> build -> sheet.

const FSet := preload("res://tools/world_forge/forge_set.gd")
const EM := preload("res://art/cinematics/stage_sets/forge_evenmead/tools/em_mesh.gd")
const L := preload("res://art/cinematics/stage_sets/forge_evenmead/tools/em_layout.gd")
const SPEC := "res://art/cinematics/stage_sets/forge_evenmead/forge_evenmead.set"
const DIR := "res://art/cinematics/stage_sets/forge_evenmead/parts"
const MATS := DIR + "/materials"
const SET_HALF := Vector2(75, 60)

var T  ## World Forge terrain (forge_terrain.gd)
var mats := {}
var only: PackedStringArray = PackedStringArray()
var hedges: Array = []   ## hedge points from the far fields (x, z)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
	_run.call_deferred()


func _want(k: String) -> bool:
	return only.is_empty() or only.has(k)


func _run() -> void:
	var fs := FSet.new()
	fs.compile(SPEC)
	T = fs.terrain
	print("WORLD terrain %dx%d step %.2f x0 %.1f z0 %.1f" % [T.nx, T.nz, T.step, T.x0, T.z0])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR + "/mm"))
	_materials()
	var t0 := Time.get_ticks_msec()
	if _want("ground"):
		_ground()
	if _want("grass"):
		_grass()
	if _want("flowers"):
		_flowers()
	if _want("trees"):
		_trees()
	if _want("river"):
		_river()
	if _want("camps"):
		_camps()
	if _want("air"):
		_air()
	if _want("far"):
		_far()
	if _want("props"):
		_props()
	print("WORLD done in %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit()


# ================================================================== plumbing

func _materials() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MATS))
	var sh := func(name: String, prio := 0, params := {}) -> ShaderMaterial:
		var m := ShaderMaterial.new()
		m.shader = load("%s/%s.gdshader" % [MATS, name])
		m.render_priority = prio
		for k: String in params:
			m.set_shader_parameter(k, params[k])
		return m
	var defs := {
		"veg": sh.call("em_veg"),
		"veg_gold": sh.call("em_veg", 0, {"glow": 0.45, "dry_amount": 0.0, "translucency": 0.8, "tree_tint": 0.0}),
		"ground": sh.call("em_ground"),
		"water": sh.call("em_water", 1),
		"cloth": sh.call("em_cloth"),
		"mist": sh.call("em_mist", 1),
		"halo": sh.call("em_halo", 2),
		"rays": sh.call("em_rays", 0, {"strength": 0.4}),
		"birds": sh.call("em_birds"),
		"stone": sh.call("em_stone"),
		"far": sh.call("em_far"),
	}
	var matte := StandardMaterial3D.new()
	matte.vertex_color_use_as_albedo = true
	matte.vertex_color_is_srgb = true
	matte.roughness = 0.86
	matte.rim_enabled = true
	matte.rim = 0.18
	matte.rim_tint = 0.6
	matte.cull_mode = BaseMaterial3D.CULL_DISABLED
	defs["matte"] = matte
	for k: String in defs:
		var p := "%s/em_%s.tres" % [MATS, k]
		ResourceSaver.save(defs[k], p)
		mats[k] = load(p)


## Saves a mesh-only part: surfaces = [[EM builder, material key], ...] -> parts/<name>.res + <name>.tscn.
func _save_mesh(name: String, surfaces: Array, shadow := false, cull_margin := 0.0) -> void:
	var mesh := ArrayMesh.new()
	var tris := 0
	for s: Array in surfaces:
		tris += (s[0] as EM).commit(mesh, mats[s[1]])
	if mesh.get_surface_count() == 0:
		print("PART %s empty" % name)
		return
	var mp := "%s/%s.res" % [DIR, name]
	ResourceSaver.save(mesh, mp, ResourceSaver.FLAG_COMPRESS)
	mesh.take_over_path(mp)
	var root := Node3D.new()
	root.name = name
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.extra_cull_margin = cull_margin
	root.add_child(mi)
	mi.owner = root
	_pack(root, name)
	print("PART %s surfaces=%d tris=%d aabb=%s" % [name, mesh.get_surface_count(), tris, mesh.get_aabb()])


## Saves a MultiMesh part: one mesh (builder + material), instance transforms + custom data (Color).
func _save_mm(name: String, mb: EM, mat_key: String, xfs: Array, customs: Array, shadow := false) -> void:
	var mesh := ArrayMesh.new()
	var tris := mb.commit(mesh, mats[mat_key])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_custom_data(i, customs[i])
	var mp := "%s/mm/%s.res" % [DIR, name]
	ResourceSaver.save(mm, mp, ResourceSaver.FLAG_COMPRESS)
	mm.take_over_path(mp)
	var root := Node3D.new()
	root.name = name
	var mi := MultiMeshInstance3D.new()
	mi.name = "Instances"
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	root.add_child(mi)
	mi.owner = root
	_pack(root, name)
	print("MM %s instances=%d mesh_tris=%d total_tris=%d" % [name, xfs.size(), tris, tris * xfs.size()])


func _pack(root: Node3D, name: String) -> void:
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, "%s/%s.tscn" % [DIR, name])
	root.free()


## Height on the terrain mesh itself (same grid and diagonals as forge_terrain.mesh()).
func gh(x: float, z: float) -> float:
	var fx := clampf((x - T.x0) / T.step, 0.0, T.nx - 1.001)
	var fz := clampf((z - T.z0) / T.step, 0.0, T.nz - 1.001)
	var i := int(fx)
	var j := int(fz)
	var tx := fx - i
	var tz := fz - j
	var a: float = T.h[j * T.nx + i]
	var b: float = T.h[j * T.nx + i + 1]
	var d: float = T.h[(j + 1) * T.nx + i]
	var e: float = T.h[(j + 1) * T.nx + i + 1]
	if tx >= tz:
		return a + (b - a) * tx + (e - b) * tz
	return a + (d - a) * tz + (e - d) * tx


func gn(x: float, z: float) -> Vector3:
	var e := 0.75
	return Vector3(gh(x - e, z) - gh(x + e, z), 2.0 * e, gh(x, z - e) - gh(x, z + e)).normalized()


static func h01(a: float, b: float, s: int) -> float:
	return EM.h01(a, b, s)


## Smooth value noise (cell metres), 0..1.
static func vn(x: float, z: float, cell: float, s: int) -> float:
	var fx := x / cell
	var fz := z / cell
	var i := floorf(fx)
	var j := floorf(fz)
	var tx := fx - i
	var tz := fz - j
	tx = tx * tx * (3.0 - 2.0 * tx)
	tz = tz * tz * (3.0 - 2.0 * tz)
	var a := h01(i, j, s)
	var b := h01(i + 1.0, j, s)
	var c := h01(i, j + 1.0, s)
	var d := h01(i + 1.0, j + 1.0, s)
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)


static func fbm(x: float, z: float, cell: float, s: int) -> float:
	return vn(x, z, cell, s) * 0.55 + vn(x, z, cell * 0.47, s + 1) * 0.28 + vn(x, z, cell * 0.21, s + 2) * 0.17


func river_d(x: float, z: float) -> float:
	return L.dist_poly(Vector2(x, z), L.RIVER)


func track_d(x: float, z: float) -> float:
	var p := Vector2(x, z)
	return minf(L.dist_poly(p, L.TRACK_N), L.dist_poly(p, L.TRACK_S))


## Distance to the nearest camera focus, scaled by its radius (0 = at a focus centre, 1 = on its rim).
func focus_k(x: float, z: float) -> float:
	var best := INF
	for f: Vector3 in L.FOCUS:
		best = minf(best, Vector2(x - f.x, z - f.y).length() / f.z)
	return best


func in_set(x: float, z: float, margin := 0.0) -> bool:
	return absf(x) <= SET_HALF.x + margin and absf(z) <= SET_HALF.y + margin


## Far-field weight (0 inside the set's meadow, 1 in the farmland / forest beyond it).
func far_w(x: float, z: float) -> float:
	var ox := absf(x) - SET_HALF.x
	var oz := absf(z) - SET_HALF.y
	return smoothstep(2.0, 22.0, maxf(ox, oz) + 6.0 * (vn(x, z, 23.0, 71) - 0.5))


func forest_w(x: float, z: float) -> float:
	## the northern uplands' forest (beyond the ridge) and the flank woods of the set
	var n := smoothstep(-82.0, -98.0, z + 8.0 * (vn(x, z, 19.0, 72) - 0.5))
	var wx := absf(x) + 6.0 * (vn(x, z, 14.0, 73) - 0.5)
	var flank := smoothstep(58.0, 66.0, wx) * (1.0 - smoothstep(88.0, 98.0, wx)) * (1.0 - smoothstep(58.0, 66.0, absf(z)))
	return clampf(maxf(n, flank), 0.0, 1.0)


## Field cell of the farmland beyond the set: {id, kind, u, v, border}.
func field_at(x: float, z: float) -> Dictionary:
	var a := 0.38
	var u := x * cos(a) + z * sin(a)
	var v := -x * sin(a) + z * cos(a)
	var cu := floorf(u / 34.0)
	var cv := floorf(v / 21.0)
	var fu := u / 34.0 - cu
	var fv := v / 21.0 - cv
	var border := minf(minf(fu, 1.0 - fu) * 34.0, minf(fv, 1.0 - fv) * 21.0)
	var hk := h01(cu, cv, 81)
	var kind := "pasture"
	if hk < 0.22:
		kind = "hay"
	elif hk < 0.36:
		kind = "plough"
	elif hk < 0.45:
		kind = "flax"
	elif hk < 0.52:
		kind = "rape"
	elif hk < 0.68:
		kind = "wild"
	return {"kind": kind, "border": border, "angle": a, "h": hk}


# ================================================================== paint (ground colour field)

const LUSH := Color(0.25, 0.41, 0.11)
const GOLDEN := Color(0.60, 0.57, 0.22)
const BANK := Color(0.17, 0.33, 0.10)
const MUD := Color(0.33, 0.28, 0.18)
const BED := Color(0.42, 0.38, 0.29)
const DIRT := Color(0.52, 0.42, 0.28)
const FOREST_FLOOR := Color(0.17, 0.22, 0.09)


## {col, fl (flower amount), pal (flower palette), grass, furrow, dry}
func paint(x: float, z: float) -> Dictionary:
	var y := gh(x, z)
	var nrm := gn(x, z)
	var slope := 1.0 - nrm.y
	var dry := clampf(fbm(x, z, 42.0, 61) * 1.5 - 0.42 + (y - 2.0) * 0.045, 0.0, 1.0)
	var col := LUSH.lerp(GOLDEN, dry * 0.85)
	col = col * (0.92 + 0.16 * vn(x, z, 7.0, 62))
	# sun-facing slopes read warmer, shaded slopes cooler (painted light on top of the real one)
	var facing := nrm.dot(L.SUN)
	col = col.lerp(col * Color(1.08, 1.02, 0.86), clampf(facing * 2.0, 0.0, 1.0) * 0.4)
	var grass := 1.0
	var fl := smoothstep(0.52, 0.86, fbm(x, z, 11.0, 63))
	var pal := 0.0
	var furrow := 0.0
	# zones
	var lark := 1.0 - smoothstep(22.0, 36.0, Vector2(x - (-6.0), z - 42.0).length())
	var north := smoothstep(-18.0, -30.0, z)
	var pn := vn(x, z, 6.0, 64)
	if lark > 0.0:
		fl = clampf(fl * 1.1 + lark * 0.28 * vn(x, z, 5.0, 65), 0.0, 1.0)
		# (few cornflower drifts: massed blue read as grey-blue puddles in the hill's shadows from the crane)
		pal = [0.0, 0.5, 0.25, 1.0, 0.5, 0.75][int(pn * 5.99)] if lark > 0.5 else [0.0, 0.25, 0.5][int(pn * 2.99)]
	elif north > 0.5:
		fl *= 0.55
		pal = [0.0, 0.5, 0.5, 1.0][int(pn * 3.99)]
	else:
		pal = [0.0, 0.25, 0.25, 0.5][int(pn * 3.99)]
	# river: bed, mud line, lush banks
	var dw := y - L.WL
	if dw < 1.8:
		col = col.lerp(BANK, smoothstep(1.8, 0.4, dw) * 0.75)
		fl *= smoothstep(0.3, 1.2, dw)
		pal = 0.25
	if dw < 0.28:
		col = col.lerp(MUD, smoothstep(0.28, 0.02, dw))
		grass = smoothstep(0.0, 0.28, dw)
	if dw < 0.0:
		var deep := clampf(-dw / 1.3, 0.0, 1.0)
		col = BED.lerp(Color(0.24, 0.24, 0.18), deep) * (0.95 + 0.1 * vn(x, z, 9.0, 66))
		grass = 0.0
		fl = 0.0
	# worn tracks to the ford
	var td := track_d(x, z)
	var wear := 1.0 - smoothstep(0.7, 2.3, td + 0.8 * (vn(x, z, 3.0, 67) - 0.5))
	if wear > 0.0 and dw > 0.1:
		col = col.lerp(DIRT * (0.9 + 0.2 * vn(x, z, 1.7, 68)), wear * 0.85)
		grass = minf(grass, 1.0 - wear * 0.85)
		fl *= 1.0 - wear
	# the Master's tree: a ring of fallen gold leaves
	var dt := Vector2(x - L.MASTER_TREE.x, z - L.MASTER_TREE.y).length()
	if dt < 10.0:
		col = col.lerp(Color(0.80, 0.60, 0.18), (1.0 - dt / 10.0) * 0.5 * (0.6 + 0.4 * vn(x, z, 1.1, 69)))
	# slopes turn earthy
	col = col.lerp(Color(0.40, 0.36, 0.24), smoothstep(0.2, 0.45, slope) * 0.6)
	# far: farmland patchwork, the northern forest floor
	var fw := far_w(x, z)
	if fw > 0.0:
		var f := field_at(x, z)
		var fc := col
		var ff := 0.0
		var fp := 0.0
		var fg := 1.0
		var fu := 0.0
		match String(f["kind"]):
			"hay":
				fc = Color(0.80, 0.66, 0.30) * (0.92 + 0.12 * vn(x, z, 5.0, 74))
				fu = f["angle"] / TAU + 0.001
				fg = 0.35
			"plough":
				fc = Color(0.44, 0.31, 0.20)
				fu = f["angle"] / TAU + 0.26
				fg = 0.0
			"flax":
				fc = Color(0.36, 0.44, 0.22)
				ff = 0.95
				fp = 0.75
			"rape":
				fc = Color(0.74, 0.70, 0.16)
				ff = 0.6
				fp = 0.25
			"wild":
				fc = LUSH.lerp(GOLDEN, 0.4)
				ff = 0.75
				fp = [0.0, 0.5, 0.25][int(float(f["h"]) * 100.0) % 3]
			_:
				fc = LUSH.lerp(GOLDEN, 0.25 * vn(x, z, 30.0, 75)) * (0.95 + 0.1 * float(f["h"]))
		# hedge margins stay green
		var edge := smoothstep(2.5, 0.5, float(f["border"]))
		fc = fc.lerp(BANK, edge * 0.7)
		col = col.lerp(fc, fw)
		fl = lerpf(fl, ff * (1.0 - edge), fw)
		if fw > 0.5:
			pal = fp
			furrow = fu * (1.0 - edge)
		grass = lerpf(grass, fg, fw)
		if dw < 0.5:
			col = col.lerp(BANK, 0.5)
	var fo := forest_w(x, z)
	if fo > 0.0:
		col = col.lerp(FOREST_FLOOR * (0.85 + 0.3 * vn(x, z, 4.0, 76)), fo * 0.9)
		fl *= 1.0 - fo
	return {"col": col, "fl": fl, "pal": pal, "grass": grass, "furrow": furrow, "dry": dry, "y": y}


# ================================================================== ground skin

func _ground() -> void:
	var mb := EM.new()
	var nx: int = T.nx
	var nz: int = T.nz
	for j in nz:
		for i in nx:
			var x: float = T.x0 + i * T.step
			var z: float = T.z0 + j * T.step
			var y: float = T.h[j * nx + i]
			var p := paint(x, z)
			var c: Color = p["col"]
			c.a = 1.0
			mb.vert(Vector3(x, y, z), T.normal_at(x, z), c, Vector2(p["fl"], p["pal"]), Vector2(p["grass"], p["furrow"]))
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			var b := a + 1
			var d := a + nx
			var e := d + 1
			# forge_terrain winding (a, b, e) / (a, e, d) as stored: emit the same stored order
			mb.idx.append_array([a, b, e, a, e, d])
	_save_mesh("em_ground", [[mb, "ground"]], false)


# ================================================================== grass

## One tuft: `blades` blades round the origin (radius r), heights hmin..hmax (m).
func _tuft(mb: EM, blades: int, r: float, hmin: float, hmax: float, bw: float, seed: int, seedheads := 0.0, off := Vector3.ZERO) -> void:
	for b in blades:
		var fa := h01(float(b), 1.0, seed)
		var fr := sqrt(h01(float(b), 2.0, seed))
		var ang := TAU * (b * 0.618034 + fa * 0.3)
		var root := off + Vector3(cos(ang), 0, sin(ang)) * r * fr
		var hh := lerpf(hmin, hmax, pow(h01(float(b), 3.0, seed), 0.8)) * (1.0 - 0.35 * fr)
		var lean := Vector3(cos(ang), 0, sin(ang)) * (0.18 + 0.35 * fr) + Vector3(h01(float(b), 4.0, seed) - 0.5, 0, h01(float(b), 5.0, seed) - 0.5) * 0.5
		var face := TAU * h01(float(b), 6.0, seed)
		var wa := Vector3(cos(face), 0, sin(face)) * bw * (0.7 + 0.6 * h01(float(b), 7.0, seed)) * 0.5
		var nn := Vector3(-sin(face), 0.0, cos(face))
		var mid := root + Vector3(0, hh * 0.5, 0) + lean * hh * 0.18
		var tip := root + Vector3(0, hh * 0.92, 0) + lean * hh * 0.55
		var ir := h01(float(b), 8.0, seed)
		var dry := h01(float(b), 9.0, seed) < 0.18
		var c_root := Color(0.09, 0.17, 0.05)
		var c_mid := Color(0.26, 0.42, 0.12).lerp(Color(0.34, 0.46, 0.14), ir)
		var c_tip := Color(0.55, 0.63, 0.22).lerp(Color(0.66, 0.66, 0.28), ir)
		if dry:
			c_mid = Color(0.52, 0.48, 0.24)
			c_tip = Color(0.84, 0.72, 0.42)
		var i0 := mb.vert(root - wa, nn, c_root, Vector2(0, 0), Vector2(ir, 0.0))
		mb.vert(root + wa, nn, c_root, Vector2(0, 0), Vector2(ir, 0.0))
		mb.vert(mid - wa * 0.62, nn, c_mid, Vector2(0.3, 0), Vector2(ir, 0.5))
		mb.vert(mid + wa * 0.62, nn, c_mid, Vector2(0.3, 0), Vector2(ir, 0.5))
		mb.vert(tip, nn, c_tip, Vector2(1.0, 0), Vector2(ir, 1.0))
		mb.tri(i0, i0 + 1, i0 + 3)
		mb.tri(i0, i0 + 3, i0 + 2)
		mb.tri(i0 + 2, i0 + 3, i0 + 4)
		if seedheads > 0.0 and h01(float(b), 10.0, seed) < seedheads:
			# an oat-like seed head hanging from the tip: a slim golden diamond
			var hd := (tip - mid).normalized()
			var s0 := tip
			var s1 := tip + hd * 0.13 + Vector3(0, -0.02, 0)
			var sw := wa.normalized() * 0.018
			var cs := Color(0.86, 0.74, 0.44)
			var k := mb.vert(s0, nn, cs, Vector2(1, 1), Vector2(ir, 1.0))
			mb.vert(s0.lerp(s1, 0.5) + sw, nn, cs, Vector2(1, 1), Vector2(ir, 1.0))
			mb.vert(s1, nn, cs.lightened(0.1), Vector2(1, 1), Vector2(ir, 1.0))
			mb.vert(s0.lerp(s1, 0.5) - sw, nn, cs, Vector2(1, 1), Vector2(ir, 1.0))
			mb.tri(k, k + 1, k + 2)
			mb.tri(k, k + 2, k + 3)


func _grass() -> void:
	var near := EM.new()
	_tuft(near, 30, 0.26, 0.32, 0.86, 0.034, 3)
	var mid := EM.new()
	_tuft(mid, 16, 0.3, 0.34, 0.8, 0.045, 5)
	var far := EM.new()
	_tuft(far, 8, 0.36, 0.36, 0.78, 0.07, 7)
	var tall := EM.new()
	_tuft(tall, 22, 0.3, 0.6, 1.25, 0.03, 9, 0.45)
	var sets := {"near": [[], []], "mid": [[], []], "far": [[], []], "tall": [[], []]}
	var step := 0.5
	var rng_i := 0
	var x := -SET_HALF.x - 14.0
	while x <= SET_HALF.x + 14.0:
		var z := -SET_HALF.y - 12.0
		while z <= SET_HALF.y + 12.0:
			rng_i += 1
			var jx := x + (h01(x, z, 101) - 0.5) * step
			var jz := z + (h01(z, x, 102) - 0.5) * step
			z += step
			var fk := focus_k(jx, jz)
			# target spacing: 0.55 m inside a focus, ~2.6 m on the open meadow
			var sp := lerpf(0.55, 2.6, smoothstep(0.45, 1.6, fk))
			var p_keep := pow(step / sp, 2.0)
			if h01(jx, jz, 103) > p_keep:
				continue
			var p := paint(jx, jz)
			if float(p["grass"]) < 0.35 or float(p["y"]) < L.WL + 0.12:
				continue
			if far_w(jx, jz) > 0.6 or forest_w(jx, jz) > 0.7:
				continue
			var hero_clear := false
			for k: String in L.HEROES:
				if (L.HEROES[k] as Vector2).distance_to(Vector2(jx, jz)) < 0.55 or Vector2(-6.3, 32.4).distance_to(Vector2(jx, jz)) < 1.0:
					hero_clear = true
			if hero_clear:
				continue
			var y := gh(jx, jz) - 0.04
			var yaw := TAU * h01(jx, jz, 104)
			var dry: float = p["dry"]
			var s := 0.85 + 0.35 * h01(jx, jz, 105)
			var dw := float(p["y"]) - L.WL
			var kind := "near" if fk < 0.75 else ("mid" if fk < 1.35 else "far")
			if dw < 1.6 or (fk > 0.9 and h01(jx, jz, 106) < 0.12):
				kind = "tall"
				s *= 0.9 + 0.3 * h01(jx, jz, 107)
			var nrm := gn(jx, jz)
			var b := Basis(Vector3.UP, yaw)
			var tilt := Vector3.UP.cross(nrm)
			if tilt.length() > 0.001:
				b = Basis(tilt.normalized(), Vector3.UP.angle_to(nrm) * 0.6) * b
			sets[kind][0].append(Transform3D(b.scaled(Vector3(s, s * (0.9 + 0.25 * h01(jx, jz, 108)), s)), Vector3(jx, y, jz)))
			sets[kind][1].append(Color(h01(jx, jz, 109), dry, (h01(jx, jz, 110) - 0.5) * 2.0, 0.0))
		x += step
	_save_mm("em_grass_near", near, "veg", sets["near"][0], sets["near"][1])
	_save_mm("em_grass_mid", mid, "veg", sets["mid"][0], sets["mid"][1])
	_save_mm("em_grass_far", far, "veg", sets["far"][0], sets["far"][1])
	_save_mm("em_grass_tall", tall, "veg", sets["tall"][0], sets["tall"][1])


# ================================================================== flowers

## A flower head: centre c, facing n (unit), radius r, petals, cup (0 flat .. 1 cup), eye colour / size.
func _head(mb: EM, c: Vector3, n: Vector3, r: float, petals: int, pc: Color, ec: Color, eye: float, cup: float, w: float, ir: float, mask: float, ragged := 0.0) -> void:
	var t1 := n.cross(Vector3.RIGHT if absf(n.x) < 0.9 else Vector3.FORWARD).normalized()
	var t2 := n.cross(t1).normalized()
	var pa := Color(pc.r, pc.g, pc.b, mask)
	var ea := Color(ec.r, ec.g, ec.b, mask)
	for k in petals:
		var a0 := TAU * (k - 0.42) / petals
		var a1 := TAU * (k + 0.42) / petals
		var am := TAU * float(k) / petals
		var rr := r * (1.0 - ragged * h01(float(k), ir * 10.0, 7))
		var tip := c + (t1 * cos(am) + t2 * sin(am)) * rr + n * rr * cup
		var e0 := c + (t1 * cos(a0) + t2 * sin(a0)) * rr * 0.66 + n * rr * cup * 0.4
		var e1 := c + (t1 * cos(a1) + t2 * sin(a1)) * rr * 0.66 + n * rr * cup * 0.4
		var i0 := mb.vert(c, n, pa, Vector2(w, 1), Vector2(ir, 1.0))
		mb.vert(e0, n, pa, Vector2(w, 1), Vector2(ir, 1.0))
		mb.vert(tip, n, pa.lightened(0.06), Vector2(w, 1), Vector2(ir, 1.0))
		mb.vert(e1, n, pa, Vector2(w, 1), Vector2(ir, 1.0))
		mb.tri(i0, i0 + 1, i0 + 2)
		mb.tri(i0, i0 + 2, i0 + 3)
	if eye > 0.0:
		var ring: Array[int] = []
		for k in 5:
			var a := TAU * k / 5.0
			ring.append(mb.vert(c + (t1 * cos(a) + t2 * sin(a)) * eye + n * 0.003, n, ea, Vector2(w, 1), Vector2(ir, 1.0)))
		var top := mb.vert(c + n * eye * 0.6, n, ea.lightened(0.15), Vector2(w, 1), Vector2(ir, 1.0))
		for k in 5:
			mb.tri(ring[k], ring[(k + 1) % 5], top)


## A thin stem from root to top (2 triangles), wind 0 -> w.
func _stem(mb: EM, root: Vector3, top: Vector3, wdt: float, col: Color, w: float, ir: float, mask: float) -> void:
	var d := (top - root)
	var side := d.cross(Vector3.FORWARD).normalized() * wdt
	if side.length() < 0.0001:
		side = Vector3.RIGHT * wdt
	var nn := d.cross(side).normalized()
	var ca := Color(col.r, col.g, col.b, mask)
	var i0 := mb.vert(root - side, nn, ca.darkened(0.3), Vector2(0, 0), Vector2(ir, 0.0))
	mb.vert(root + side, nn, ca.darkened(0.3), Vector2(0, 0), Vector2(ir, 0.0))
	mb.vert(top, nn, ca, Vector2(w, 0), Vector2(ir, 0.8))
	mb.tri(i0, i0 + 1, i0 + 2)


func _flower_drift(mb: EM, kind: int, seed: int) -> void:
	var mask := float(1 << kind) / 255.0
	var sunh := Vector3(L.SUN.x, 0, L.SUN.z).normalized()
	var counts := [9, 10, 6, 7, 3, 8]
	var n: int = counts[kind]
	for f in n:
		var fa := TAU * h01(float(f), 1.0, seed + kind * 13)
		var fr := 0.62 * sqrt(h01(float(f), 2.0, seed + kind * 13))
		var root := Vector3(cos(fa) * fr, 0, sin(fa) * fr)
		var ir := h01(float(f), 3.0, seed + kind * 13)
		var face := (Vector3.UP + sunh * 0.55 + Vector3(ir - 0.5, 0, h01(float(f), 4.0, seed) - 0.5) * 0.5).normalized()
		var stem_c := Color(0.22, 0.38, 0.12)
		match kind:
			0:  # daisy: white rays, gold eye
				var h := lerpf(0.22, 0.48, ir)
				var top := root + Vector3(0, h, 0) + sunh * h * 0.1
				_stem(mb, root, top, 0.006, stem_c, 0.8, ir, mask)
				_head(mb, top, face, 0.042, 11, Color(0.99, 0.98, 0.93), Color(1.0, 0.78, 0.12), 0.013, 0.08, 0.8, ir, mask)
			1:  # buttercup: glossy gold cups
				var h := lerpf(0.3, 0.62, ir)
				var top := root + Vector3(0, h, 0)
				_stem(mb, root, top, 0.005, stem_c, 0.9, ir, mask)
				_head(mb, top, face, 0.03, 5, Color(1.0, 0.84, 0.1), Color(0.95, 0.62, 0.05), 0.008, 0.6, 0.9, ir, mask)
			2:  # poppy: four big scarlet petals, black eye
				var h := lerpf(0.45, 0.78, ir)
				var top := root + Vector3(0, h, 0) + sunh * 0.05
				_stem(mb, root, top, 0.006, Color(0.3, 0.42, 0.16), 0.95, ir, mask)
				_head(mb, top, face, 0.06, 4, Color(0.92, 0.14, 0.06), Color(0.1, 0.06, 0.08), 0.014, 0.45, 0.95, ir, mask)
			3:  # cornflower: ragged blue star
				var h := lerpf(0.4, 0.72, ir)
				var top := root + Vector3(0, h, 0)
				_stem(mb, root, top, 0.005, Color(0.3, 0.44, 0.24), 0.95, ir, mask)
				_head(mb, top, face, 0.038, 9, Color(0.26, 0.42, 0.96), Color(0.3, 0.2, 0.55), 0.009, 0.25, 0.95, ir, mask, 0.45)
			4:  # cow parsley: tall stem, a dome of white umbels (glows against the low sun)
				var h := lerpf(0.95, 1.3, ir)
				var top := root + Vector3(0, h, 0) + sunh * 0.06
				_stem(mb, root, top, 0.009, Color(0.3, 0.44, 0.18), 1.0, ir, mask)
				for u in 7:
					var ua := TAU * (u + ir) / 7.0
					var ud := Vector3(cos(ua), 0.5, sin(ua)).normalized()
					var uc := top + ud * (0.09 + 0.03 * h01(float(u), ir, 9)) + Vector3(0, 0.03, 0)
					_stem(mb, top, uc, 0.003, Color(0.4, 0.5, 0.25), 1.0, ir, mask)
					_head(mb, uc, Vector3.UP, 0.03, 6, Color(0.95, 0.94, 0.86), Color(0.9, 0.9, 0.8), 0.0, -0.15, 1.0, ir, mask)
			5:  # red clover: low pink balls on trefoil leaves
				var h := lerpf(0.1, 0.22, ir)
				var top := root + Vector3(0, h, 0)
				_stem(mb, root, top, 0.005, stem_c, 0.5, ir, mask)
				var cfn := func(d: Vector3) -> Color:
					var cc := Color(0.86, 0.42, 0.62).lerp(Color(0.98, 0.72, 0.84), clampf(d.y, 0.0, 1.0))
					return Color(cc.r, cc.g, cc.b, mask)
				mb.blob(top + Vector3(0, 0.02, 0), Vector3(0.022, 0.026, 0.022), 3, 5, cfn, Vector2(0.5, 1), ir, f, 0.1, 0.3)
				for lf in 3:
					var la := TAU * lf / 3.0 + ir
					var lc := root + Vector3(cos(la) * 0.03, h * 0.35, sin(la) * 0.03)
					_head(mb, lc, Vector3.UP, 0.028, 3, Color(0.2, 0.38, 0.14), Color(0.3, 0.46, 0.2), 0.0, 0.1, 0.3, ir, mask)


func _flowers() -> void:
	var mb := EM.new()
	for k in 6:
		_flower_drift(mb, k, 31)
	var xfs: Array = []
	var cus: Array = []
	var step := 0.9
	var x := -SET_HALF.x - 10.0
	while x <= SET_HALF.x + 10.0:
		var z := -SET_HALF.y - 10.0
		while z <= SET_HALF.y + 10.0:
			var jx := x + (h01(x, z, 201) - 0.5) * step
			var jz := z + (h01(z, x, 202) - 0.5) * step
			z += step
			var fk := focus_k(jx, jz)
			var p := paint(jx, jz)
			var fl: float = p["fl"]
			var keep := fl * lerpf(0.85, 0.07, smoothstep(0.5, 1.8, fk))
			if h01(jx, jz, 203) > keep:
				continue
			var dw := float(p["y"]) - L.WL
			if dw < 0.15 or float(p["grass"]) < 0.4 or far_w(jx, jz) > 0.5:
				continue
			var hero_clear := false
			for hk: String in L.HEROES:
				if (L.HEROES[hk] as Vector2).distance_to(Vector2(jx, jz)) < 0.7:
					hero_clear = true
			if hero_clear:
				continue
			var pal: float = p["pal"]
			var kind := int(round(pal * 4.0))   # 0 daisy, 1 buttercup, 2 poppy, 3 cornflower, 4 clover
			kind = [0, 1, 2, 3, 5][clampi(kind, 0, 4)]
			var r := h01(jx, jz, 204)
			if dw < 2.2 and r < 0.35:
				kind = 4   # cow parsley along the banks
			elif r < 0.12:
				kind = 0
			var yaw := TAU * h01(jx, jz, 205)
			var s := 0.8 + 0.45 * h01(jx, jz, 206)
			xfs.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), Vector3(jx, gh(jx, jz) - 0.03, jz)))
			cus.append(Color(h01(jx, jz, 207), 0.0, 0.0, (float(kind) + 0.5) / 8.0))
		x += step
	_save_mm("em_flowers", mb, "veg", xfs, cus)



# ================================================================== trees

## Crown colour from the outward direction d: sunlit side warm, shade side cool, underside dark.
func _crown_fn(sun_c: Color, shade_c: Color, under_c: Color, mask := 1.0) -> Callable:
	return func(d: Vector3) -> Color:
		var lit := clampf(d.dot(L.SUN) * 0.62 + 0.42 + d.y * 0.22, 0.0, 1.0)
		var c := shade_c.lerp(sun_c, lit)
		c = c.lerp(under_c, smoothstep(-0.15, -0.75, d.y))
		return Color(c.r, c.g, c.b, mask)


## A bent limb from p0 to p1 (prism segments), radius r0 -> r1, bark (kind 3), wind w0 -> w1.
func _limb(mb: EM, p0: Vector3, p1: Vector3, r0: float, r1: float, col: Color, sides: int, segs: int, seed: int, w0 := 0.0, w1 := 0.12, mask := 1.0) -> void:
	var d := p1 - p0
	var side := d.cross(Vector3.RIGHT if absf(d.normalized().x) < 0.9 else Vector3.FORWARD).normalized()
	var sunh := Vector3(L.SUN.x, 0, L.SUN.z).normalized()
	var prev := p0
	for s in segs:
		var t0 := float(s) / segs
		var t1 := float(s + 1) / segs
		var bend := side * sin(t1 * PI) * d.length() * 0.06 * (h01(float(seed), 1.0, 5) - 0.5) * 2.0
		var q := p0 + d * t1 + bend
		var ra := lerpf(r0, r1, t0)
		var rb := lerpf(r0, r1, t1)
		var ax := (q - prev).normalized()
		var bx := ax.cross(Vector3.FORWARD if absf(ax.z) < 0.9 else Vector3.RIGHT).normalized()
		var bz := bx.cross(ax).normalized()
		for i in sides:
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			var o0 := bx * sin(a0) + bz * cos(a0)
			var o1 := bx * sin(a1) + bz * cos(a1)
			var om := (o0 + o1).normalized()
			var k := 0.78 + 0.22 * clampf(om.dot(sunh) * 0.5 + 0.5, 0.0, 1.0)
			var tone := Color(col.r * k, col.g * k, col.b * k, mask)
			var wa := lerpf(w0, w1, t0)
			var wb := lerpf(w0, w1, t1)
			var i0 := mb.vert(prev + o0 * ra, o0, tone, Vector2(wa, 3), Vector2(0, t0 * 0.5))
			mb.vert(prev + o1 * ra, o1, tone, Vector2(wa, 3), Vector2(0, t0 * 0.5))
			mb.vert(q + o1 * rb, o1, tone, Vector2(wb, 3), Vector2(0, t1 * 0.5 + 0.2))
			mb.vert(q + o0 * rb, o0, tone, Vector2(wb, 3), Vector2(0, t1 * 0.5 + 0.2))
			var fn := (mb.v[i0 + 1] - mb.v[i0]).cross(mb.v[i0 + 3] - mb.v[i0])
			if fn.dot(om) >= 0.0:
				mb.tri(i0, i0 + 1, i0 + 2)
				mb.tri(i0, i0 + 2, i0 + 3)
			else:
				mb.tri(i0, i0 + 2, i0 + 1)
				mb.tri(i0, i0 + 3, i0 + 2)
		prev = q


## A leafy crown lobe: a soft core blob (crown-level shading, no facets) wrapped in `cards` leaf clusters, small
## jagged star cards standing out of the surface, so the silhouette reads as foliage instead of a smooth lump
## (the old crowns read as cauliflower / lettuce). `under` = cards on the underside too (a close hero tree seen from
## below: a dense shell of small flat cards hides the core). cfn(d) colours from the outward direction; `crown` = the whole
## crown's centre (normals lean to it: one soft light across the tree). u = (wind weight, kind 2).
func _lobe(mb: EM, c: Vector3, r: Vector3, cfn: Callable, u: Vector2, u2x: float, seed: int, crown: Vector3, cards: int,
		card_size: float, rings := 4, segs := 7, core_k := 0.86, lump := 0.14, under := false) -> void:
	var core_fn := func(d: Vector3) -> Color:
		var cc: Color = cfn.call(d)
		return Color(cc.r * 0.86, cc.g * 0.88, cc.b * 0.88, cc.a)
	mb.blob(c, r * core_k, rings, segs, core_fn, u, u2x, seed, lump, 0.0, 0.5, crown, 0.7)
	for k in cards:
		# fibonacci directions; no cards under the lobe (seen from below they floated like flakes)
		var fy := 1.0 - 2.0 * (k + 0.5) / cards
		if not under and (fy < -0.3 or (fy < 0.0 and h01(float(k), float(seed), 961) < 0.4)):
			continue
		var fr := sqrt(maxf(0.0, 1.0 - fy * fy))
		var fa := TAU * k * 0.618034 + h01(float(k), float(seed), 962) * 0.9
		var d := Vector3(cos(fa) * fr, fy, sin(fa) * fr)
		var p := c + Vector3(d.x * r.x, d.y * r.y, d.z * r.z) * (0.98 + 0.1 * h01(float(k), float(seed), 963))
		var nrm := (p - crown).normalized().lerp(d, 0.4).normalized()
		var t1 := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
		var t2 := d.cross(t1).normalized()
		var rot := TAU * h01(float(k), float(seed), 964)
		var a1 := t1 * cos(rot) + t2 * sin(rot)
		var a2 := d.cross(a1).normalized()
		# the card lies nearly on the surface, tipped a little outward (a scalloped leafy edge, not spikes)
		a2 = a2.lerp(d, 0.18).normalized()
		var s := card_size * (0.75 + 0.5 * h01(float(k), float(seed), 965))
		var col: Color = cfn.call(d)
		var jit := 0.94 + 0.12 * h01(float(k), float(seed), 966)
		col = Color(col.r * jit, col.g * jit, col.b * jit, col.a)
		var yy := clampf(0.5 + 0.5 * d.y, 0.0, 1.0) * 0.8 + 0.2
		var ctr := mb.vert(p, nrm, col, u, Vector2(u2x, yy))
		var rim: Array[int] = []
		var pts := 5
		for m in pts:
			var aa := TAU * m / pts + 0.3 * h01(float(m), float(k + seed), 967)
			var rr := s * (1.0 if m % 2 == 0 else 0.62) * (0.85 + 0.3 * h01(float(m), float(k), 968))
			var q := p + (a1 * cos(aa) + a2 * sin(aa)) * rr + d * s * 0.12
			var cr := Color(col.r * 1.06, col.g * 1.06, col.b * 1.04, col.a)
			rim.append(mb.vert(q, nrm, cr, Vector2(u.x + 0.1, u.y), Vector2(u2x, yy)))
		for m in pts:
			mb.tri(ctr, rim[m], rim[(m + 1) % pts])


func _oak(mb: EM, seed: int, tall: float, sun_c: Color, shade_c: Color, blobs := 14, spread := 5.0, mask := 1.0) -> void:
	var bark := Color(0.29, 0.23, 0.17)
	var base_h := 3.0 * tall
	var top := Vector3((h01(float(seed), 2.0, 9) - 0.5) * 0.6, base_h, (h01(float(seed), 3.0, 9) - 0.5) * 0.6)
	_limb(mb, Vector3(0, -0.3, 0), top, 0.5 * tall, 0.34 * tall, bark, 8, 3, seed, 0.0, 0.05, mask)
	for k in 4:
		var a := TAU * (k + h01(float(k), float(seed), 11)) / 4.0
		_limb(mb, Vector3(cos(a) * 0.9, -0.25, sin(a) * 0.9) * tall, Vector3(cos(a) * 0.15, 0.9, sin(a) * 0.15) * tall, 0.16 * tall, 0.3 * tall, bark.darkened(0.1), 5, 1, seed + k, 0.0, 0.0, mask)
	var cfn := _crown_fn(sun_c, shade_c, shade_c.darkened(0.45), mask)
	var crown_c := top + Vector3(0, 3.4 * tall, 0)
	for k in blobs:
		var f := (k + 0.5) / blobs
		var a := TAU * k * 0.618034 + h01(float(k), float(seed), 12) * 0.8
		var rr := spread * tall * sqrt(f) * (0.75 + 0.35 * h01(float(k), float(seed), 13))
		var hy := (1.0 - f) * 2.6 * tall + (h01(float(k), float(seed), 14) - 0.5) * 1.2 * tall
		var c := crown_c + Vector3(cos(a) * rr, hy - 0.6 * tall, sin(a) * rr)
		var rad := (1.5 + 0.85 * h01(float(k), float(seed), 15)) * tall
		if f > 0.45:
			_limb(mb, top, c.lerp(top, 0.25), 0.2 * tall, 0.08 * tall, bark, 5, 2, seed + 40 + k, 0.05, 0.3, mask)
		_lobe(mb, c, Vector3(rad, rad * 0.8, rad), cfn, Vector2(0.35 + 0.35 * f, 2), h01(float(k), float(seed), 16), seed * 31 + k,
			crown_c + Vector3(0, 0.6 * tall, 0), 22, 0.52 * tall)


func _birch(mb: EM, seed: int, tall: float, mask := 1.0) -> void:
	var h := 8.5 * tall
	var lean := Vector3((h01(float(seed), 1.0, 21) - 0.5) * 0.8, 0, (h01(float(seed), 2.0, 21) - 0.5) * 0.8)
	var prev := Vector3(0, -0.2, 0)
	for s in 6:
		var t := float(s + 1) / 6.0
		var q := Vector3(0, h * t, 0) + lean * t * t
		var dark := h01(float(s), float(seed), 22) < 0.35
		var col := Color(0.18, 0.16, 0.15) if dark else Color(0.88, 0.86, 0.80)
		_limb(mb, prev, q, 0.16 * tall * (1.0 - (t - 0.16) * 0.6) + 0.03, 0.16 * tall * (1.0 - t * 0.6) + 0.03, col, 6, 1, seed + s, 0.02 * s, 0.02 * (s + 1), mask)
		prev = q
	var cfn := _crown_fn(Color(0.70, 0.74, 0.28), Color(0.22, 0.34, 0.14), Color(0.12, 0.2, 0.08), mask)
	for k in 10:
		var f := (k + 0.5) / 10.0
		var a := TAU * k * 0.618034
		var y := h * (0.45 + 0.55 * (1.0 - f)) + (h01(float(k), float(seed), 23) - 0.5)
		var rr := (0.6 + 1.6 * f) * tall
		var c := Vector3(cos(a) * rr, y, sin(a) * rr) + lean * (y / h) * (y / h)
		var rad := (0.9 + 0.5 * h01(float(k), float(seed), 24)) * tall
		_lobe(mb, c, Vector3(rad, rad * 1.15, rad), cfn, Vector2(0.4 + 0.4 * (y / h), 2), h01(float(k), float(seed), 25), seed * 17 + k,
			Vector3(0, h * 0.72, 0), 12, 0.42 * tall)


func _shrub(mb: EM, seed: int, blossom: bool, mask := 1.0) -> void:
	var sun_c := Color(0.46, 0.56, 0.18)
	var shade_c := Color(0.12, 0.24, 0.1)
	var base_fn := _crown_fn(sun_c, shade_c, shade_c.darkened(0.4), mask)
	for k in 6:
		var a := TAU * k / 6.0 + h01(float(k), float(seed), 31)
		var rr := 0.55 + 0.4 * h01(float(k), float(seed), 32)
		var c := Vector3(cos(a) * rr, 0.75 + 0.5 * h01(float(k), float(seed), 33), sin(a) * rr)
		var rad := 0.65 + 0.3 * h01(float(k), float(seed), 34)
		var fn := base_fn
		if blossom:
			fn = func(d: Vector3) -> Color:
				var cc: Color = base_fn.call(d)
				if h01(d.x * 13.0, d.z * 17.0 + d.y * 5.0, 35) < 0.1 and d.y > 0.2:
					var bl := Color(0.99, 0.95, 0.94) if h01(d.x * 7.0, d.y * 3.0, 36) < 0.7 else Color(0.98, 0.74, 0.82)
					var kk := 0.75 + 0.25 * clampf(d.dot(L.SUN) + 0.5, 0.0, 1.0)
					cc = Color(bl.r * kk, bl.g * kk, bl.b * kk, mask)
				return cc
		_lobe(mb, c, Vector3(rad, rad * 0.8, rad), fn, Vector2(0.35, 2), h01(float(k), float(seed), 37), seed * 7 + k,
			Vector3(0, 0.95, 0), 10, 0.3)
	_limb(mb, Vector3(0, -0.1, 0), Vector3(0, 0.8, 0), 0.07, 0.05, Color(0.3, 0.24, 0.18), 5, 1, seed, 0.0, 0.05, mask)


func _trees() -> void:
	var oaks := [EM.new(), EM.new(), EM.new()]
	# three oak shapes, three greens (a deep summer oak, a warm olive one, a cool blue-green one)
	_oak(oaks[0], 3, 1.0, Color(0.46, 0.57, 0.18), Color(0.09, 0.2, 0.1), 16, 5.0)
	_oak(oaks[1], 7, 0.92, Color(0.58, 0.60, 0.22), Color(0.14, 0.24, 0.1), 13, 4.2)
	_oak(oaks[2], 11, 1.08, Color(0.38, 0.54, 0.22), Color(0.07, 0.18, 0.12), 18, 5.6)
	var birch := EM.new()
	_birch(birch, 5, 1.0, 1.0 / 255.0)
	_birch(birch, 9, 0.85, 2.0 / 255.0)
	var shrubs := [EM.new(), EM.new()]
	_shrub(shrubs[0], 3, false)
	_shrub(shrubs[1], 8, true)
	var farc := EM.new()
	# three far-wood shapes in one mesh (variant masks): a broad round broadleaf, a tall narrow poplar-like crown, a dark
	# spruce; leafy lobes (not smooth balls) so a whole hillside of them reads as a wood, not a wall of lettuce
	var ffn := _crown_fn(Color(0.40, 0.50, 0.2), Color(0.08, 0.18, 0.12), Color(0.05, 0.11, 0.08), 1.0 / 255.0)
	_lobe(farc, Vector3(0, 3.2, 0), Vector3(2.6, 2.2, 2.6), ffn, Vector2(0.2, 2), 0.3, 5, Vector3(0, 3.4, 0), 12, 0.95, 3, 7)
	_lobe(farc, Vector3(1.5, 2.5, 1.0), Vector3(1.8, 1.5, 1.8), ffn, Vector2(0.2, 2), 0.6, 6, Vector3(0, 3.4, 0), 8, 0.8, 3, 6)
	_lobe(farc, Vector3(-1.2, 4.3, -0.6), Vector3(1.6, 1.4, 1.6), ffn, Vector2(0.25, 2), 0.8, 7, Vector3(0, 3.4, 0), 8, 0.75, 3, 6)
	_limb(farc, Vector3(0, -0.2, 0), Vector3(0, 1.6, 0), 0.25, 0.2, Color(0.25, 0.2, 0.15), 5, 1, 1, 0.0, 0.05, 1.0 / 255.0)
	var ffn2 := _crown_fn(Color(0.52, 0.56, 0.24), Color(0.12, 0.22, 0.12), Color(0.07, 0.13, 0.08), 2.0 / 255.0)
	_lobe(farc, Vector3(0, 4.0, 0), Vector3(1.6, 2.4, 1.6), ffn2, Vector2(0.25, 2), 0.2, 7, Vector3(0, 5.2, 0), 10, 0.7, 3, 6)
	_lobe(farc, Vector3(0.2, 6.6, -0.2), Vector3(1.2, 2.0, 1.2), ffn2, Vector2(0.35, 2), 0.7, 8, Vector3(0, 5.2, 0), 8, 0.6, 3, 6)
	_limb(farc, Vector3(0, -0.2, 0), Vector3(0, 2.4, 0), 0.22, 0.16, Color(0.25, 0.2, 0.15), 5, 1, 2, 0.0, 0.05, 2.0 / 255.0)
	# the spruce: five jagged tiers, darker and bluer than the broadleaves, a sharp tip
	for k in 5:
		var tk := float(k) / 4.0
		var tier := Color(0.06 + 0.04 * tk, 0.15 + 0.05 * tk, 0.13 + 0.02 * tk, 4.0 / 255.0)
		farc.prism(Transform3D.IDENTITY, Vector3(0, 1.1 + k * 1.75, 0), 2.1 - k * 0.38, 0.12, 2.6 - k * 0.3, 9,
			tier, false, Vector2(0.2 + 0.15 * k, 2), null, k * 0.37)
	farc.prism(Transform3D.IDENTITY, Vector3(0, 8.4, 0), 0.35, 0.0, 1.6, 5, Color(0.12, 0.22, 0.15, 4.0 / 255.0), false, Vector2(0.9, 2))
	_limb(farc, Vector3(0, -0.2, 0), Vector3(0, 1.2, 0), 0.18, 0.15, Color(0.25, 0.2, 0.15), 5, 1, 3, 0.0, 0.05, 4.0 / 255.0)
	var lists := {"oak0": [[], []], "oak1": [[], []], "oak2": [[], []], "birch": [[], []], "shrub0": [[], []], "shrub1": [[], []], "far": [[], []]}
	var add := func(kind: String, x: float, z: float, s: float, variant: int, sink := 0.25) -> void:
		if kind == "oak" or kind == "shrub":
			kind = kind + str(variant)
		var y := gh(x, z) - sink
		var yaw := TAU * h01(x, z, 301)
		lists[kind][0].append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s * (0.92 + 0.16 * h01(x, z, 302)), s)), Vector3(x, y, z)))
		lists[kind][1].append(Color(h01(x, z, 303), 0.15 * h01(x, z, 304), (h01(x, z, 305) - 0.5) * 1.6, (float(variant) + 0.5) / 8.0))
	var clear := func(x: float, z: float, r: float) -> bool:
		if river_d(x, z) < 8.5 or gh(x, z) < L.WL + 0.4:
			return false
		if track_d(x, z) < 3.0:
			return false
		for k: String in L.HEROES:
			if (L.HEROES[k] as Vector2).distance_to(Vector2(x, z)) < 7.0 + r:
				return false
		for army: String in L.ARMIES:
			for blk: Array in L.ARMIES[army]:
				if (blk[1] as Vector2).distance_to(Vector2(x, z)) < 9.0 + r:
					return false
		return true
	# flank woods (oak and birch, birches on the sunny edges)
	var gx := -120.0
	while gx <= 120.0:
		var gz := -80.0
		while gz <= 80.0:
			var x := gx + (h01(gx, gz, 311) - 0.5) * 3.6
			var z := gz + (h01(gz, gx, 312) - 0.5) * 3.6
			gz += 4.6
			var fo := forest_w(x, z)
			if absf(x) < 50.0 or fo < 0.35 or h01(x, z, 313) > fo * 1.1:
				continue
			if not clear.call(x, z, 3.0):
				continue
			if absf(x) < 70.0 and h01(x, z, 314) < 0.45:
				add.call("birch", x, z, 0.85 + 0.35 * h01(x, z, 315), int(h01(x, z, 316) * 2.0))
			elif absf(x) > 100.0:
				add.call("far", x, z, 1.1 + 0.7 * h01(x, z, 317), int(h01(x, z, 318) * 3.0), 0.3)
			else:
				add.call("oak", x, z, 0.8 + 0.4 * h01(x, z, 318), int(h01(x, z, 319) * 3.0))
			if h01(x, z, 320) < 0.35 and clear.call(x + 2.2, z + 1.4, 1.0):
				add.call("shrub", x + 2.2, z + 1.4, 0.8 + 0.5 * h01(x, z, 321), 1 if h01(x, z, 322) < 0.2 else 0)
		gx += 4.6
	# the northern uplands forest (far crowns, oaks on the near edge)
	gx = -170.0
	while gx <= 170.0:
		var gz := -165.0
		while gz <= -78.0:
			var x := gx + (h01(gx, gz, 331) - 0.5) * 5.0
			var z := gz + (h01(gz, gx, 332) - 0.5) * 5.0
			gz += 5.2
			var fo := forest_w(x, z)
			if fo < 0.3 or h01(x, z, 333) > fo:
				continue
			if z > -96.0 and h01(x, z, 334) < 0.5:
				add.call("oak", x, z, 0.9 + 0.35 * h01(x, z, 335), int(h01(x, z, 336) * 3.0))
			else:
				add.call("far", x, z, 0.9 + 0.9 * h01(x, z, 337), 2 if h01(x, z, 338) < 0.4 else int(h01(x, z, 339) * 2.0), 0.3)
		gx += 5.2
	# hedgerows and hedgerow oaks in the far farmland
	gx = -165.0
	while gx <= 165.0:
		var gz := -150.0
		while gz <= 150.0:
			var x := gx + (h01(gx, gz, 341) - 0.5) * 1.4
			var z := gz + (h01(gz, gx, 342) - 0.5) * 1.4
			gz += 2.6
			if far_w(x, z) < 0.7 or forest_w(x, z) > 0.2:
				continue
			var f := field_at(x, z)
			if float(f["border"]) > 1.3 or river_d(x, z) < 7.0:
				continue
			var r := h01(x, z, 343)
			if r < 0.05:
				add.call("oak", x, z, 0.75 + 0.35 * h01(x, z, 344), int(h01(x, z, 345) * 3.0))
			elif r < 0.62:
				add.call("shrub", x, z, 0.9 + 0.5 * h01(x, z, 346), 1 if h01(x, z, 347) < 0.22 else 0)
		gx += 2.6
	# lone meadow trees (hand-placed, readable shapes)
	var lone := [[-38.0, 13.0, "oak", 1.15], [33.0, 17.5, "oak", 1.05], [-47.0, 30.0, "oak", 1.2], [51.0, -12.0, "oak", 1.0],
		[-44.0, -24.0, "birch", 1.0], [-41.5, -22.0, "birch", 0.85], [46.0, 30.0, "birch", 0.95], [-26.0, 44.0, "oak", 0.9],
		[28.0, 44.0, "oak", 0.95], [-30.0, -50.0, "oak", 0.85], [36.0, -52.0, "birch", 0.9], [-52.0, 6.0, "oak", 1.1]]
	for t: Array in lone:
		add.call(t[2], t[0], t[1], t[3], int(h01(t[0], t[1], 351) * (3.0 if t[2] == "oak" else 2.0)))
	# hawthorn / elder bushes along the banks and the hill feet
	for k in 90:
		var x := -70.0 + 140.0 * h01(float(k), 1.0, 361)
		var z := -55.0 + 110.0 * h01(float(k), 2.0, 361)
		var dw := gh(x, z) - L.WL
		var near_bank := dw > 0.6 and dw < 2.6
		if not near_bank and h01(float(k), 3.0, 361) > 0.3:
			continue
		if focus_k(x, z) < 0.95 or track_d(x, z) < 2.5 or dw < 0.6:
			continue
		var bad := false
		for army: String in L.ARMIES:
			for blk: Array in L.ARMIES[army]:
				if (blk[1] as Vector2).distance_to(Vector2(x, z)) < 10.0:
					bad = true
		if bad:
			continue
		add.call("shrub", x, z, 0.9 + 0.6 * h01(float(k), 4.0, 361), 1 if h01(float(k), 5.0, 361) < 0.3 else 0, 0.15)
	for k in 3:
		_save_mm("em_trees_oak%d" % k, oaks[k], "veg", lists["oak%d" % k][0], lists["oak%d" % k][1], true)
	_save_mm("em_trees_birch", birch, "veg", lists["birch"][0], lists["birch"][1], true)
	for k in 2:
		_save_mm("em_trees_shrub%d" % k, shrubs[k], "veg", lists["shrub%d" % k][0], lists["shrub%d" % k][1], true)
	_save_mm("em_trees_far", farc, "veg", lists["far"][0], lists["far"][1], false)


# ================================================================== river, ford, banks

func _resample(poly: Array, step: float) -> Array:
	var out: Array = []
	for i in range(poly.size() - 1):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[i + 1]
		var n := int(ceil(a.distance_to(b) / step))
		for k in n:
			out.append(a.lerp(b, float(k) / n))
	out.append(poly[poly.size() - 1])
	return out


func _tangent(pts: Array, i: int) -> Vector2:
	return ((pts[mini(i + 1, pts.size() - 1)] as Vector2) - (pts[maxi(i - 1, 0)] as Vector2)).normalized()


## The water line on one bank: walk from the river centre p along n until the ground rises above y.
func _bank(p: Vector2, n: Vector2, y: float) -> Vector2:
	var q := p
	for m in 30:
		q = p + n * (0.5 * m)
		if gh(q.x, q.y) > y:
			break
	return q


func _river() -> void:
	var water := EM.new()
	var pts := _resample(L.RIVER, 2.0)
	var across := 10
	var hw := 10.5
	var s := 0.0
	var rows: Array = []
	for i in pts.size():
		var p: Vector2 = pts[i]
		var t := _tangent(pts, i)
		var nrm := Vector2(-t.y, t.x)
		if i > 0:
			s += p.distance_to(pts[i - 1])
		var row: Array = []
		for k in across + 1:
			var u := float(k) / across * 2.0 - 1.0
			var q := p + nrm * u * hw
			var fd := absf(q.x - L.FORD.x)
			var foam := clampf(1.0 - fd / 3.2, 0.0, 1.0) * (1.0 - absf(u) * 0.3)
			var speed := 0.4 + 0.6 * foam
			row.append(water.vert(Vector3(q.x, L.WL, q.y), Vector3.UP, Color(speed, 0, 0, foam), Vector2(s, u), Vector2.ZERO))
		rows.append(row)
	for i in rows.size() - 1:
		for k in across:
			var a: int = rows[i][k]
			var b: int = rows[i][k + 1]
			var c: int = rows[i + 1][k]
			var d: int = rows[i + 1][k + 1]
			var pa := water.v[a]
			var pb := water.v[b]
			var pc := water.v[c]
			# tri(a, b, c) = counter-clockwise seen from +y when (b - a) x (c - a) points up
			if (pb - pa).cross(pc - pa).y > 0.0:
				water.tri(a, b, c)
				water.tri(b, d, c)
			else:
				water.tri(a, c, b)
				water.tri(b, c, d)
	_save_mesh("em_river", [[water, "water"]], false)
	# ---- the ford: a sunken causeway of flat slabs + stepping stones, bank pebbles, driftwood
	var st := EM.new()
	var slab := func(c: Vector3, rx: float, rz: float, seed: int, col: Color) -> void:
		var sides := 7
		var top: Array = []
		var bot: Array = []
		for k in sides:
			var a := TAU * (k + 0.3 * h01(float(k), float(seed), 401)) / sides
			var rr := 0.8 + 0.3 * h01(float(k), float(seed), 402)
			var o := Vector3(cos(a) * rx * rr, 0, sin(a) * rz * rr)
			top.append(c + o * 0.84 + Vector3(0, 0.03 * (h01(float(k), float(seed), 403) - 0.5), 0))
			bot.append(c + o + Vector3(0, -0.55, 0))
		for k in sides:
			var k1 := (k + 1) % sides
			st.fquad(bot[k1], bot[k], top[k], top[k1], col * (0.8 + 0.15 * h01(float(k), float(seed), 404)))
			st.ftri(c + Vector3(0, 0.03, 0), top[k], top[k1], col.lightened(0.06))
	var cz := -8.0
	var ci := 0
	while cz <= 8.0:
		ci += 1
		var z := cz
		cz += 0.95
		var x0 := L.FORD.x + 0.25 * sin(z * 0.7)
		for lane in 3:
			var x := x0 - 1.1 + lane * 1.1 + (h01(float(ci), float(lane), 405) - 0.5) * 0.3
			if gh(x, z) > L.WL + 0.2:
				continue
			var top := L.WL - 0.06 + (0.15 if h01(float(ci), float(lane), 406) < 0.2 else 0.0)
			var sc := Color(0.56, 0.53, 0.47).lerp(Color(0.40, 0.39, 0.36), h01(float(ci), float(lane), 407))
			slab.call(Vector3(x, top, z), 0.52, 0.45, ci * 7 + lane, sc)
		var sx := x0 + 2.3
		if gh(sx, z) < L.WL + 0.1 and ci % 2 == 0:
			slab.call(Vector3(sx, L.WL + 0.2, z), 0.38, 0.34, ci * 13, Color(0.52, 0.5, 0.45))
	# bank pebbles and boulders along the water line
	for i in pts.size():
		var p: Vector2 = pts[i]
		if absf(p.x) > 95.0:
			continue
		var t := _tangent(pts, i)
		for side: float in [-1.0, 1.0]:
			var nrm := Vector2(-t.y, t.x) * side
			for k in 3:
				if h01(p.x, float(k) + side, 411) > 0.55:
					continue
				var q := _bank(p, nrm, L.WL - 0.05)
				q += nrm * (h01(p.x, float(k), 412) - 0.35) * 1.4 + t * (h01(p.y, float(k), 413) - 0.5) * 1.8
				var big := h01(p.x, float(k) + 5.0, 414) < 0.12
				var r := (0.3 + 0.45 * h01(p.x, float(k), 415)) * (2.2 if big else 1.0)
				var sfn := func(d: Vector3) -> Color:
					var cc := Color(0.55, 0.52, 0.46).lerp(Color(0.38, 0.37, 0.34), h01(d.x * 5.0, d.z * 5.0, 416))
					if d.y > 0.55 and big:
						cc = cc.lerp(Color(0.34, 0.44, 0.16), 0.55)
					var kk := 0.8 + 0.3 * clampf(d.dot(L.SUN) + 0.4, 0.0, 1.0)
					return Color(cc.r * kk, cc.g * kk, cc.b * kk)
				st.blob(Vector3(q.x, gh(q.x, q.y) - r * 0.3, q.y), Vector3(r, r * 0.55, r * 0.85), 3, 6, sfn, Vector2.ZERO, 0.0, int(p.x * 7.0) + k, 0.22, 0.7)
	for dl: Array in [[-22.0, 6.2, 0.4], [31.0, -3.2, -0.3], [-58.0, 8.4, 0.9]]:
		var x: float = dl[0]
		var z: float = dl[1]
		var q := _bank(Vector2(x, z), Vector2(0, 1) if z > 0 else Vector2(0, -1), L.WL + 0.1)
		var d := Vector3(cos(dl[2]), 0, sin(dl[2])) * 2.4
		var y := gh(q.x, q.y) + 0.1
		_limb(st, Vector3(q.x, y, q.y) - d, Vector3(q.x, y + 0.05, q.y) + d, 0.2, 0.14, Color(0.50, 0.44, 0.36), 6, 2, int(x))
	_save_mesh("em_riverbed", [[st, "matte"]], true)
	# ---- reeds, cattails, lily pads (vegetation)
	var rd := EM.new()
	for i in pts.size():
		var p: Vector2 = pts[i]
		if absf(p.x) > 110.0:
			continue
		var t := _tangent(pts, i)
		for side: float in [-1.0, 1.0]:
			var nrm := Vector2(-t.y, t.x) * side
			var q := _bank(p, nrm, L.WL - 0.15)
			if absf(q.x - L.FORD.x) < 7.0:
				continue
			var fk := focus_k(q.x, q.y)
			if h01(p.x, side, 421) > lerpf(0.95, 0.4, smoothstep(0.6, 1.6, fk)):
				continue
			var cc := q + t * (h01(p.x, side, 422) - 0.5) * 1.6
			var y := gh(cc.x, cc.y)
			var nb := 12 + int(10.0 * h01(p.x, side, 423))
			for b in nb:
				var a := TAU * h01(float(b), p.x, 424)
				var rr := 0.75 * sqrt(h01(float(b), p.y, 425))
				var root := Vector3(cc.x + cos(a) * rr, maxf(y, L.WL - 0.35) - 0.05, cc.y + sin(a) * rr)
				var hh := 1.0 + 0.9 * h01(float(b), p.x, 426)
				var lean := Vector3(cos(a), 0, sin(a)) * 0.12
				var tip := root + Vector3(0, hh, 0) + lean * hh
				var face := a + 1.3
				var wa := Vector3(cos(face), 0, sin(face)) * 0.025
				var nn := Vector3(-sin(face), 0, cos(face))
				var ir := h01(float(b), p.y, 427)
				var c0 := Color(0.16, 0.24, 0.1)
				var c1 := Color(0.44, 0.52, 0.2).lerp(Color(0.62, 0.58, 0.28), ir)
				var i0 := rd.vert(root - wa, nn, c0, Vector2(0, 0), Vector2(ir, 0.1))
				rd.vert(root + wa, nn, c0, Vector2(0, 0), Vector2(ir, 0.1))
				rd.vert(tip, nn, c1, Vector2(0.8, 0), Vector2(ir, 1.0))
				rd.tri(i0, i0 + 1, i0 + 2)
				if b % 5 == 0:
					var ch := root + Vector3(0, hh * 0.8, 0) + lean * hh * 0.8
					rd.prism(Transform3D.IDENTITY, ch, 0.028, 0.026, 0.2, 5, Color(0.36, 0.22, 0.12), true, Vector2(0.7, 3))
	for k in 300:
		var i := clampi(int(h01(float(k), 1.0, 431) * pts.size()), 0, pts.size() - 1)
		var p: Vector2 = pts[i]
		if absf(p.x - L.FORD.x) < 14.0 or absf(p.x) > 100.0:
			continue
		var t := _tangent(pts, i)
		var nrm := Vector2(-t.y, t.x)
		var q := p + nrm * (h01(float(k), 2.0, 431) - 0.5) * 14.0
		var g := gh(q.x, q.y)
		if g > L.WL - 0.25 or g < L.WL - 1.1:
			continue
		var r := 0.22 + 0.2 * h01(float(k), 3.0, 431)
		var y := L.WL + 0.012
		var col := Color(0.18, 0.34, 0.12).lerp(Color(0.32, 0.44, 0.16), h01(float(k), 4.0, 431))
		var ctr := rd.vert(Vector3(q.x, y, q.y), Vector3.UP, col.lightened(0.1), Vector2(0, 2), Vector2(0, 1))
		var notch := TAU * h01(float(k), 5.0, 431)
		var prev := -1
		for m in 9:
			var a := notch + 0.35 + (TAU - 0.7) * m / 8.0
			var vi := rd.vert(Vector3(q.x + cos(a) * r, y, q.y + sin(a) * r), Vector3.UP, col, Vector2(0, 2), Vector2(0, 0.8))
			if prev >= 0:
				rd.tri(ctr, prev, vi)
			prev = vi
		if h01(float(k), 6.0, 431) < 0.16:
			_head(rd, Vector3(q.x + r * 0.3, y + 0.05, q.y), Vector3.UP, 0.07, 8, Color(0.98, 0.94, 0.92), Color(1.0, 0.8, 0.2), 0.02, 0.5, 0.0, 0.5, 1.0)
	_save_mesh("em_reeds", [[rd, "veg"]], false)



# ================================================================== camps, standards

const KCOL := {
	"shadow": [Color(0.14, 0.09, 0.19), Color(0.30, 0.18, 0.40), Color(0.68, 0.52, 0.92)],
	"ice": [Color(0.46, 0.64, 0.84), Color(0.86, 0.91, 0.97), Color(0.96, 0.98, 1.0)],
	"nature": [Color(0.17, 0.40, 0.15), Color(0.62, 0.52, 0.24), Color(0.96, 0.80, 0.32)],
	"fire": [Color(0.70, 0.15, 0.07), Color(0.93, 0.80, 0.55), Color(1.0, 0.74, 0.22)],
}


## A hanging banner: top-left corner o, across unit a (width w), down (height h), facing n. A smooth nu x nv grid
## (waves bend it); the emblem, trim border and swallowtail are drawn per pixel by em_cloth (UV2.y = kingdom code).
func _banner(cl: EM, o: Vector3, a: Vector3, w: float, h: float, n: Vector3, k: String, phase: float, nu := 6, nv := 12) -> void:
	var field: Color = KCOL[k][0]
	var code := (float(L.KINGDOMS.find(k)) + 0.5) / 4.0
	var base := cl.v.size()
	for j in nv + 1:
		for i in nu + 1:
			var u := float(i) / nu
			var vv := float(j) / nv
			cl.vert(o + a * w * u + Vector3.DOWN * h * vv, n, field, Vector2(vv, u), Vector2(phase, code))
	for j in nv:
		for i in nu:
			var a0 := base + j * (nu + 1) + i
			cl.tri(a0, a0 + 1, a0 + nu + 2)
			cl.tri(a0, a0 + nu + 2, a0 + nu + 1)


## A pennant streaming from a pole at p (triangle strip, fixed edge on the pole), length len, height hh.
func _pennant(cl: EM, p: Vector3, len: float, hh: float, col: Color, trim: Color, phase: float) -> void:
	var dir := Vector3(-0.86, 0, -0.5).normalized()
	var n := dir.cross(Vector3.UP).normalized()
	var segs := 6
	for s in segs:
		var t0 := float(s) / segs
		var t1 := float(s + 1) / segs
		var a0 := p + dir * len * t0
		var a1 := p + dir * len * t1
		var h0 := hh * (1.0 - t0 * 0.85)
		var h1 := hh * (1.0 - t1 * 0.85)
		var c := trim if s == 0 else col
		var i0 := cl.vert(a0 + Vector3.UP * h0 * 0.5, n, c, Vector2(t0, 0), Vector2(phase, 0))
		cl.vert(a1 + Vector3.UP * h1 * 0.5, n, c, Vector2(t1, 0), Vector2(phase, 0))
		cl.vert(a1 - Vector3.UP * h1 * 0.5, n, c, Vector2(t1, 1), Vector2(phase, 0))
		cl.vert(a0 - Vector3.UP * h0 * 0.5, n, c, Vector2(t0, 1), Vector2(phase, 0))
		cl.tri(i0, i0 + 1, i0 + 2)
		cl.tri(i0, i0 + 2, i0 + 3)


## A standard: pole + crossbar + hanging banner + finial (+ 2 streamers when big). base = ground point.
func _standard(mt: EM, cl: EM, base: Vector3, k: String, height: float, big: bool, yaw: float) -> void:
	var gold := Color(0.86, 0.66, 0.26)
	var wood := Color(0.30, 0.22, 0.15)
	var I := Transform3D.IDENTITY
	mt.prism(I, base + Vector3(0, -0.3, 0), 0.06 if big else 0.045, 0.045 if big else 0.035, height + 0.3, 6, wood)
	var fwd := Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw)))
	var across := Vector3.UP.cross(fwd).normalized()
	var bw := 1.7 if big else 1.0
	var bh := 3.4 if big else 2.0
	var top := base + Vector3(0, height, 0)
	mt.box(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), top + Vector3(0, -0.12, 0)), Vector3.ZERO, Vector3(bw * 0.58, 0.04, 0.04), gold)
	mt.prism(I, top, 0.05, 0.0, 0.35 if big else 0.22, 6, gold)
	for sx: float in [-1.0, 1.0]:
		mt.prism(I, top + across * sx * bw * 0.58 + Vector3(0, -0.12, 0), 0.04, 0.0, 0.1, 5, gold)
	_banner(cl, top + Vector3(0, -0.17, 0) - across * bw * 0.5 + fwd * 0.03, across, bw, bh, fwd, k, h01(base.x, base.z, 501), 7 if not big else 9, 14 if not big else 18)
	if big:
		for sx: float in [-1.0, 1.0]:
			_pennant(cl, top + across * sx * bw * 0.55 + Vector3(0, -0.3, 0), 1.4, 0.16, KCOL[k][2], KCOL[k][2], h01(sx, base.z, 502))


## A round pavilion (vertical-striped walls, cone roof, scalloped valance, finial and pennant). c = ground centre.
func _pavilion(mt: EM, cl: EM, c: Vector3, r: float, wall: float, roof: float, k: String, yaw: float) -> void:
	var ca: Color = KCOL[k][0]
	var cb: Color = KCOL[k][1]
	var trim: Color = KCOL[k][2]
	var sides := 14
	var y0 := c.y - 0.35
	var apex := c + Vector3(0, wall + roof, 0)
	var door := int(fposmod(yaw / 360.0 * sides, float(sides)))
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var d0 := Vector3(sin(a0), 0, cos(a0))
		var d1 := Vector3(sin(a1), 0, cos(a1))
		var col := ca if i % 2 == 0 else cb
		if i == door:
			col = col.darkened(0.55)
		var b0 := Vector3(c.x, y0, c.z) + d0 * r
		var b1 := Vector3(c.x, y0, c.z) + d1 * r
		var t0 := c + d0 * r + Vector3(0, wall, 0)
		var t1 := c + d1 * r + Vector3(0, wall, 0)
		mt.fquad(b1, b0, t0, t1, col)
		var e0 := c + d0 * r * 1.08 + Vector3(0, wall - 0.05, 0)
		var e1 := c + d1 * r * 1.08 + Vector3(0, wall - 0.05, 0)
		mt.ftri(e1, e0, apex, (cb if i % 2 == 0 else ca).lightened(0.05))
		# scalloped valance
		var m := (e0 + e1) * 0.5 + Vector3(0, -0.32, 0)
		mt.ftri(e1, e0, m, trim)
	mt.prism(Transform3D.IDENTITY, apex - Vector3(0, 0.1, 0), 0.05, 0.03, 1.2, 5, Color(0.3, 0.22, 0.15))
	mt.blob(apex + Vector3(0, 1.2, 0), Vector3(0.09, 0.09, 0.09), 3, 5, func(_d: Vector3) -> Color: return Color(0.86, 0.66, 0.26), Vector2.ZERO, 0.0, 3, 0.0, 0.8)
	_pennant(cl, apex + Vector3(0, 1.0, 0), 1.6, 0.34, trim, trim, h01(c.x, c.z, 511))


## An A-frame tent along `yaw`: length ln, half width hw, ridge height h.
func _ridge_tent(mt: EM, c: Vector3, yaw: float, ln: float, hw: float, h: float, k: String) -> void:
	var ca: Color = KCOL[k][0]
	var cb: Color = KCOL[k][1]
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var p := func(x: float, y: float, z: float) -> Vector3: return c + b * Vector3(x, y, z)
	var y0 := -0.3
	mt.fquad(p.call(-hw, y0, -ln), p.call(-hw, y0, ln), p.call(0, h, ln), p.call(0, h, -ln), ca)
	mt.fquad(p.call(hw, y0, ln), p.call(hw, y0, -ln), p.call(0, h, -ln), p.call(0, h, ln), ca.darkened(0.12))
	mt.ftri(p.call(-hw, y0, ln), p.call(hw, y0, ln), p.call(0, h, ln), cb)
	mt.ftri(p.call(hw, y0, -ln), p.call(-hw, y0, -ln), p.call(0, h, -ln), cb.darkened(0.1))
	# the open door flap (dark triangle) on the front end
	mt.ftri(p.call(-hw * 0.4, 0.0, ln + 0.02), p.call(hw * 0.4, 0.0, ln + 0.02), p.call(0, h * 0.8, ln + 0.02), Color(0.06, 0.05, 0.05))
	mt.prism(Transform3D.IDENTITY, p.call(0, 0, ln + 0.1), 0.03, 0.03, h + 0.35, 4, Color(0.3, 0.22, 0.15))


func _fire_pit(mt: EM, c: Vector3) -> void:
	for k in 9:
		var a := TAU * k / 9.0
		mt.blob(c + Vector3(cos(a) * 0.7, 0.02, sin(a) * 0.7), Vector3(0.2, 0.14, 0.17), 3, 5, func(d: Vector3) -> Color: return Color(0.45, 0.43, 0.4) * (0.75 + 0.3 * clampf(d.y, 0.0, 1.0)), Vector2.ZERO, 0.0, k, 0.2, 0.7)
	for k in 4:
		var a := TAU * k / 4.0 + 0.4
		var d := Vector3(cos(a), 0.0, sin(a))
		_limb(mt, c + d * 0.55 + Vector3(0, 0.05, 0), c + Vector3(0, 0.45, 0) - d * 0.05, 0.06, 0.04, Color(0.22, 0.14, 0.09), 5, 1, k)
	mt.blob(c + Vector3(0, 0.08, 0), Vector3(0.4, 0.06, 0.4), 2, 7, func(_d: Vector3) -> Color: return Color(0.9, 0.35, 0.08), Vector2.ZERO, 0.0, 9, 0.1, 0.8)


func _crates(mt: EM, c: Vector3, seed: int) -> void:
	for k in 4:
		var o := Vector3((h01(float(k), 1.0, seed) - 0.5) * 2.4, 0, (h01(float(k), 2.0, seed) - 0.5) * 1.6)
		var y := gh(c.x + o.x, c.z + o.z)
		var s := 0.32 + 0.12 * h01(float(k), 3.0, seed)
		if k % 2 == 0:
			mt.box(Transform3D(Basis(Vector3.UP, h01(float(k), 4.0, seed) * 1.5), Vector3(c.x + o.x, y + s - 0.04, c.z + o.z)), Vector3.ZERO, Vector3(s, s, s), Color(0.52, 0.38, 0.22))
		else:
			mt.prism(Transform3D.IDENTITY, Vector3(c.x + o.x, y - 0.03, c.z + o.z), s * 0.8, s * 0.8, s * 2.2, 8, Color(0.45, 0.30, 0.18), true)
	# a weapon rack with spears
	var rb := c + Vector3(1.6, 0, -0.8)
	var ry := gh(rb.x, rb.z)
	for sx: float in [-0.7, 0.7]:
		mt.prism(Transform3D.IDENTITY, Vector3(rb.x + sx, ry - 0.1, rb.z), 0.04, 0.04, 1.3, 4, Color(0.3, 0.22, 0.15))
	mt.box(Transform3D(Basis(), Vector3(rb.x, ry + 1.05, rb.z)), Vector3.ZERO, Vector3(0.8, 0.03, 0.03), Color(0.3, 0.22, 0.15))
	for s in 5:
		var x := rb.x - 0.55 + s * 0.27
		_limb(mt, Vector3(x, ry - 0.05, rb.z + 0.25), Vector3(x + 0.05, ry + 2.1, rb.z - 0.05), 0.018, 0.015, Color(0.36, 0.27, 0.18), 4, 1, s)
		mt.prism(Transform3D.IDENTITY, Vector3(x + 0.05, ry + 2.08, rb.z - 0.05), 0.03, 0.0, 0.22, 4, Color(0.7, 0.72, 0.76))


func _camps() -> void:
	var mt := EM.new()
	var cl := EM.new()
	var fires: Array = []
	# host standards (the two great standards are their own parts: standard_shadow / standard_nature)
	for s: Vector3 in L.STANDARDS:
		var k: String = L.KINGDOMS[int(s.z)]
		var yaw := 0.0 if s.z < 1.5 else 180.0
		_standard(mt, cl, Vector3(s.x, gh(s.x, s.y), s.y), k, 5.6 + 0.6 * h01(s.x, s.y, 521), false, yaw)
	# north camp: Shadow command pavilion behind Malrik, Ice pavilion, rows of tents along the ridge
	var tents := [
		["pav", "shadow", -1.0, -47.5, 3.4, 2.4, 3.2, 180.0], ["pav", "shadow", -13.5, -50.5, 2.5, 2.0, 2.4, 170.0],
		["pav", "ice", 17.0, -48.5, 2.8, 2.1, 2.8, 190.0], ["pav", "shadow", -27.0, -46.5, 2.3, 1.9, 2.2, 175.0],
		["pav", "ice", 32.5, -47.0, 2.3, 1.9, 2.3, 185.0],
		# south camp. The two Fire pavilions are placed for the Ep4 Lark Hill close shots (S07 / S11 / S10) and Ep3's long
		# lens N12 / N02: the big one stands down the back of the crest in the gap between Vessa and Ysolde in S11 (it was
		# right behind Vessa's red hat and staff orb), hides behind Ysolde's shoulders in S07 / S10 and stays clear of the
		# red Fire standard in N12; the small one hides behind Vessa's robe in S07 (a red-and-white sliver merged with her
		# red cloak) and frames S11's left.
		["pav", "nature", -17.5, 53.0, 3.1, 2.2, 3.0, 0.0], ["pav", "fire", 8.6, 56.6, 2.4, 2.0, 2.6, 10.0],
		["pav", "nature", -31.0, 50.5, 2.3, 1.9, 2.2, 5.0], ["pav", "fire", 21.0, 50.5, 2.2, 1.9, 2.3, 350.0],
	]
	var pav_spots: Array = []
	for t: Array in tents:
		var x: float = t[2]
		var z: float = t[3]
		var r: float = t[4]
		var y := minf(gh(x, z), minf(gh(x + r, z), minf(gh(x - r, z), minf(gh(x, z + r), gh(x, z - r)))))
		_pavilion(mt, cl, Vector3(x, y, z), r, t[5], t[6], t[1], t[7])
		if z > 0.0:   # the south camp only (the north rows stay as they were)
			pav_spots.append(Vector3(x, z, r))
	var rows := [["shadow", -46.0, -20.0, -52.5, 175.0], ["shadow", -44.0, -18.0, -57.0, 180.0], ["ice", 8.0, 46.0, -53.5, 185.0],
		["ice", 10.0, 44.0, -58.0, 180.0], ["shadow", -9.0, 6.0, -56.0, 178.0],
		["nature", -46.0, -24.0, 57.5, 0.0], ["nature", -12.0, -2.0, 58.5, 355.0], ["fire", 2.0, 38.0, 57.0, 5.0]]
	# (the short Fire row at z 54, x 30..44, is gone: from Lark Hill it was a red strip under Vessa's red robe in S07 and
	# behind the small pavilion in S11)
	for rw: Array in rows:
		var x: float = rw[1]
		var ci := 0
		while x <= float(rw[2]):
			ci += 1
			var z: float = float(rw[3]) + (h01(x, float(ci), 531) - 0.5) * 1.6
			var y := gh(x, z)
			var free := true
			for ps: Vector3 in pav_spots:
				if Vector2(x - ps.x, z - ps.y).length() < ps.z + 2.4:
					free = false
			if not free:
				x += 4.4 + 1.4 * h01(x, z, 534)
				continue
			_ridge_tent(mt, Vector3(x, y, z), float(rw[4]) + (h01(x, z, 532) - 0.5) * 14.0, 1.6, 1.25, 1.9, rw[0])
			if h01(x, z, 533) < 0.3:
				_standard(mt, cl, Vector3(x + 1.8, gh(x + 1.8, z + 1.8), z + 1.8), rw[0], 3.4, false, float(rw[4]))
			x += 4.4 + 1.4 * h01(x, z, 534)
	for f: Vector2 in [Vector2(-22.0, -50.0), Vector2(6.0, -52.5), Vector2(27.0, -51.5), Vector2(-34.0, 54.0), Vector2(-4.0, 55.5), Vector2(26.0, 53.5)]:
		var c := Vector3(f.x, gh(f.x, f.y), f.y)
		_fire_pit(mt, c)
		fires.append(c)
		_crates(mt, c + Vector3(2.6, 0, 1.2), int(f.x * 3.0))
	_save_mesh("em_camps", [[mt, "matte"], [cl, "cloth"]], true)
	# the two great standards (tagged places: N05 / S06 subjects)
	for g: Array in [["standard_shadow", "shadow", 0.0], ["standard_nature", "nature", 180.0]]:
		var m2 := EM.new()
		var c2 := EM.new()
		_standard(m2, c2, Vector3.ZERO, g[1], 7.6, true, g[2])
		_save_mesh(g[0], [[m2, "matte"], [c2, "cloth"]], true)
	var f := FileAccess.open(DIR + "/fires.txt", FileAccess.WRITE)
	for c: Vector3 in fires:
		f.store_line("%.2f %.2f %.2f" % [c.x, c.y, c.z])
	f.close()


# ================================================================== air: mist, haze, smoke, pollen, glints, rays, birds

func _card(mb: EM, c: Vector3, s: float, col: Color, mode: float) -> void:
	var corners := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	var ids: Array[int] = []
	for k in 4:
		ids.append(mb.vert(c, Vector3.UP, col, corners[k], Vector2(s, mode)))
	mb.idx.append_array([ids[0], ids[2], ids[1], ids[0], ids[3], ids[2]])


func _air() -> void:
	var mist := EM.new()
	var halo := EM.new()
	var rays := EM.new()
	var birds := EM.new()
	var pts := _resample(L.RIVER, 5.0)
	# morning mist lying on the river (thinner at the ford, where the armies will cross)
	for i in pts.size():
		var p: Vector2 = pts[i]
		if absf(p.x) > 150.0:
			continue
		for k in 2:
			var o := Vector2((h01(p.x, float(k), 601) - 0.5) * 6.0, (h01(p.y, float(k), 602) - 0.5) * 5.0)
			var q := p + o
			var ford := smoothstep(10.0, 34.0, absf(q.x - L.FORD.x))
			var s := 3.0 + 3.0 * h01(p.x, float(k), 603)
			var a := (0.025 + 0.04 * h01(p.x, float(k), 604)) * ford
			_card(mist, Vector3(q.x, L.WL + 0.35 + 0.6 * h01(q.x, q.y, 605), q.y), s, Color(1.0, 0.96, 0.9, a), 0.15)
	# low haze pools in the valley flats and at the wood feet (depth layers for the wides)
	for k in 70:
		var x := -150.0 + 300.0 * h01(float(k), 1.0, 611)
		var z := -40.0 + 80.0 * h01(float(k), 2.0, 611)
		if absf(x) < 110.0 and absf(z) < 70.0:
			continue
		var y := gh(x, z)
		_card(mist, Vector3(x, y + 2.0 + 3.0 * h01(float(k), 3.0, 611), z), 12.0 + 12.0 * h01(float(k), 4.0, 611), Color(0.98, 0.9, 0.82, 0.07), 0.08)
	# haze banks at the far forest feet and between the far ridges (aerial perspective layers)
	for k in 46:
		var a := TAU * (k + 0.5 * h01(float(k), 1.0, 621)) / 46.0
		var d := 118.0 + 30.0 * h01(float(k), 2.0, 621)
		var x := sin(a) * d * 1.15
		var z := cos(a) * d
		_card(mist, Vector3(x, gh(x, z) + 3.0 + 5.0 * h01(float(k), 3.0, 621), z), 22.0 + 16.0 * h01(float(k), 4.0, 621), Color(0.9, 0.88, 0.94, 0.06), 0.06)
	# camp smoke: thin columns leaning downwind
	var fires: Array = []
	if FileAccess.file_exists(DIR + "/fires.txt"):
		for ln in FileAccess.get_file_as_string(DIR + "/fires.txt").split("\n", false):
			var pp := ln.split(" ")
			fires.append(Vector3(float(pp[0]), float(pp[1]), float(pp[2])))
	var wd := Vector3(-0.86, 0, -0.5).normalized()
	for c: Vector3 in fires:
		for k in 11:
			var t := float(k) / 10.0
			var p := c + Vector3(0, 0.9 + t * 13.0, 0) + wd * t * t * 7.0
			_card(mist, p, 0.5 + t * 2.6, Color(0.82, 0.78, 0.76, 0.34 * (1.0 - t * 0.85)), 0.35)
		_card(halo, c + Vector3(0, 0.45, 0), 1.3, Color(1.0, 0.55, 0.2, 0.9), 0.0)
		_card(halo, c + Vector3(0, 0.3, 0), 0.5, Color(1.0, 0.8, 0.4, 1.0), 0.0)
	# pollen and seed fluff drifting in the low sun round both crests, the tree and the N05 / S06 foregrounds
	for f: Vector3 in L.FOCUS:
		var n := int(34.0 * f.z / 14.0)
		for k in n:
			var a := TAU * h01(float(k), f.x, 631)
			var r := f.z * 1.1 * sqrt(h01(float(k), f.y, 632))
			var x := f.x + cos(a) * r
			var z := f.y + sin(a) * r
			var y := gh(x, z) + 0.4 + 2.8 * pow(h01(float(k), 3.0, 633), 1.6)
			var warm := h01(float(k), 4.0, 634)
			_card(halo, Vector3(x, y, z), 0.02 + 0.02 * h01(float(k), 5.0, 635), Color(1.0, 0.8 + 0.1 * warm, 0.45 + 0.25 * warm, 0.45), 0.0)
	# the Master's tree: slow golden glints in its crown and falling leaves
	for k in 70:
		var a := TAU * h01(float(k), 1.0, 641)
		var r := 7.5 * sqrt(h01(float(k), 2.0, 641))
		var x := L.MASTER_TREE.x + cos(a) * r
		var z := L.MASTER_TREE.y + sin(a) * r
		var y := gh(L.MASTER_TREE.x, L.MASTER_TREE.y) + 1.0 + 11.0 * h01(float(k), 3.0, 641)
		_card(halo, Vector3(x, y, z), 0.06 + 0.06 * h01(float(k), 4.0, 641), Color(1.0, 0.8, 0.35, 0.8), 1.0 if k % 3 == 0 else 0.0)
	# god rays: long warm sheets from the low sun through the east wood and over the valley (seen looking east)
	var ldir := -L.SUN
	var w1 := ldir.cross(Vector3.UP).normalized()
	for k in 11:
		var sx := 80.0 + 40.0 * h01(float(k), 1.0, 651)
		var sz := -60.0 + 110.0 * h01(float(k), 2.0, 651)
		var s := Vector3(sx, 18.0 + 22.0 * h01(float(k), 3.0, 651), sz)
		var len := 70.0 + 50.0 * h01(float(k), 4.0, 651)
		var e := s + ldir * len
		var wa := 2.5 + 4.5 * h01(float(k), 5.0, 651)
		var col := Color(1.0, 0.82, 0.55, 0.16 + 0.14 * h01(float(k), 6.0, 651))
		var i0 := rays.vert(s - w1 * wa, Vector3.UP, col, Vector2(0, 0))
		rays.vert(s + w1 * wa, Vector3.UP, col, Vector2(1, 0))
		rays.vert(e + w1 * wa * 1.9, Vector3.UP, col, Vector2(1, 1))
		rays.vert(e - w1 * wa * 1.9, Vector3.UP, col, Vector2(0, 1))
		rays.tri(i0, i0 + 1, i0 + 2)
		rays.tri(i0, i0 + 2, i0 + 3)
	# swallows wheeling over the valley, a far flock over the northern forest
	var flocks := [[Vector3(-8, 16, 4), 10, 9.0], [Vector3(22, 22, -10), 8, 12.0], [Vector3(-40, 26, 14), 7, 14.0], [Vector3(10, 38, -110), 12, 18.0]]
	for fl: Array in flocks:
		var c: Vector3 = fl[0]
		for b in int(fl[1]):
			var rad := float(fl[2]) * (0.5 + 0.7 * h01(float(b), c.x, 671))
			var ctr := c + Vector3((h01(float(b), 1.0, 672) - 0.5) * 6.0, (h01(float(b), 2.0, 672) - 0.5) * 5.0, (h01(float(b), 3.0, 672) - 0.5) * 6.0)
			var spd := (0.35 + 0.35 * h01(float(b), 4.0, 672)) * (1.0 if b % 3 != 0 else -1.0)
			var ph := TAU * h01(float(b), 5.0, 672)
			var fp := h01(float(b), 6.0, 672)
			var sc := 0.55
			var shape := [[Vector3(0, 0, 0.18), Vector3(-0.35, 0.02, -0.05), Vector3(0, 0, -0.05)], [Vector3(0, 0, 0.18), Vector3(0, 0, -0.05), Vector3(0.35, 0.02, -0.05)],
				[Vector3(0, 0, -0.05), Vector3(-0.08, 0, -0.28), Vector3(0.08, 0, -0.28)]]
			for tr: Array in shape:
				var ids: Array[int] = []
				for vv: Vector3 in tr:
					var lo := vv * sc
					ids.append(birds.vert(ctr, Vector3.UP, Color(lo.x + 0.5, lo.y + 0.5, lo.z + 0.5), Vector2(ph, spd), Vector2(rad, fp)))
				birds.idx.append_array([ids[0], ids[1], ids[2]])
	_save_mesh("em_mist", [[mist, "mist"]], false, 40.0)
	_save_mesh("em_glow", [[halo, "halo"]], false, 12.0)
	_save_mesh("em_rays", [[rays, "rays"]], false, 10.0)
	_save_mesh("em_birds", [[birds, "birds"]], false, 30.0)


# ================================================================== far land: the snowy northern range, blue southern hills

## The far ring: one closed band of mountains all round the valley (replaces World Forge's sky ring and the old flat
## far strips). Angle-indexed grid (inner -> outer rows) of flat low-poly faces, the whole light painted into the
## vertex colours for an unshaded, fog-free material (em_far.gdshader): forested blue-green feet, cool blue-violet rock
## with a lilac sunlit side, snow caps on the high crests (warm white in the sun, lavender in shade) and aerial
## perspective that lifts the far rows toward the haze.
## `peak_fn(ang)` gives the crest height by direction (ang = atan2(z, x)); the north is the high snowy range.
func _ring(mb: EM, rx: float, rz: float, depth: float, peak_fn: Callable, snow_line: float, seed: int, forest_top: float,
		haze: Color, haze_k: float, base_y := -8.0) -> void:
	var na := 400
	var rows := 9
	var P: Array = []
	for j in rows + 1:
		var t := float(j) / rows
		for i in na:
			var ang := TAU * i / na
			var dirv := Vector2(cos(ang), sin(ang))
			var pk: float = peak_fn.call(ang)
			var arc := ang * 180.0 / PI
			# ridged noise along the ring: sharp crests, broad cols
			var n1 := 1.0 - absf(fbm(arc * 2.1, float(seed), 23.0, seed) * 2.0 - 1.0)
			var n2 := 1.0 - absf(fbm(arc * 2.1 + 17.0, float(seed) + 3.0, 8.0, seed + 5) * 2.0 - 1.0)
			var ridge := pow(n1, 1.7) * 0.72 + pow(n2, 2.2) * 0.28
			var hmax := pk * (0.28 + 0.9 * ridge)
			# profile across the band: rises from the inner edge to a crest at 60 %, then falls a little
			var prof := sin(clampf(t / 0.62, 0.0, 1.0) * PI * 0.5) * (1.0 - smoothstep(0.62, 1.0, t) * 0.3)
			# gullies and spurs running down the faces (rock ribs between snow chutes)
			var gully := (fbm(arc * 6.0, t * 9.0, 3.0, seed + 9) - 0.5) * pk * 0.16 * t
			gully += (1.0 - absf(vn(arc * 14.0, t * 3.0, 4.0, seed + 19) * 2.0 - 1.0)) * pk * 0.12 * t
			var y := base_y + hmax * prof + gully
			var rr := 1.0 + (t - 0.5) * depth / ((rx + rz) * 0.5) + (h01(float(i), float(j), seed + 7) - 0.5) * 0.004
			P.append(Vector3(dirv.x * rx * rr, y, dirv.y * rz * rr))
	# low-poly facets, each face lit by its own normal (clean painted planes, like the prologue's peaks)
	var paint_face := func(p: Vector3, nrm: Vector3, t: float, ang: float) -> Color:
		var pk: float = peak_fn.call(ang)
		var lit := clampf(nrm.dot(L.SUN) * 2.2 + 0.38, 0.0, 1.0)
		var sky := clampf(nrm.y, 0.0, 1.0)
		# rock: dark cool slate in shade (a little sky on the upward facets), warm ochre-rose where the low sun strikes;
		# the sun-side paint pass (2026-09-28): darker rock + more snow, so the range keeps a clear snow line and real
		# contrast when the camera looks toward the sun (N05 read lilac-pale: all shaded rock, no snow on steep peaks)
		var amb := 0.72 + 0.28 * sky
		var rock := Color(0.21 * amb, 0.18 * amb, 0.25 * amb).lerp(Color(0.74, 0.52, 0.38), lit)
		var forest := Color(0.10, 0.18, 0.22).lerp(Color(0.30, 0.38, 0.30), lit)
		var fy := p.y - base_y
		var jit := 6.0 * (fbm(p.x, p.z, 9.0, seed + 13) - 0.5)
		var col := forest.lerp(rock, smoothstep(pk * forest_top * 0.7, pk * forest_top * 1.25, fy + jit))
		# snow above a clear line on the high crests (a fraction of the local crest height); only the steepest faces stay
		# bare rock (ribs between the snowfields)
		var hk := fy / maxf(pk, 1.0) + 0.12 * (fbm(p.x, p.z, 6.0, seed + 11) - 0.5)
		var cap := smoothstep(snow_line + 0.18, snow_line + 0.26, hk) * smoothstep(0.1, 0.22, sky)
		var snowy := smoothstep(snow_line - 0.04, snow_line + 0.03, hk) * maxf(smoothstep(0.28, 0.46, sky), cap) * smoothstep(20.0, 32.0, pk)
		col = col.lerp(Color(0.58, 0.60, 0.80).lerp(Color(1.0, 0.93, 0.80), lit), snowy)
		# aerial perspective: the low rows and the far side of the band melt into the haze, crests stay crisp
		var air := haze_k * (0.55 + 0.45 * t) * (1.0 - 0.45 * smoothstep(0.0, pk, fy))
		col = col.lerp(haze, clampf(air, 0.0, 0.9))
		# alpha carries the snow mask to em_far.gdshader (rim light on snow when the view looks toward the sun)
		col.a = snowy
		return col
	for j in rows:
		for i in na:
			var i1 := (i + 1) % na
			var pa: Vector3 = P[j * na + i]
			var pb: Vector3 = P[j * na + i1]
			var pd: Vector3 = P[(j + 1) * na + i]
			var pe: Vector3 = P[(j + 1) * na + i1]
			var t := (j + 0.5) / rows
			var ang := TAU * (i + 0.5) / na
			# angle runs x -> +z, rows go outward: (e - a) x (d - a) points up
			for tri: Array in [[pa, pe, pd], [pa, pb, pe]]:
				var q0: Vector3 = tri[0]
				var q1: Vector3 = tri[1]
				var q2: Vector3 = tri[2]
				var fn := (q1 - q0).cross(q2 - q0).normalized()
				mb.ftri(q0, q1, q2, paint_face.call((q0 + q1 + q2) / 3.0, fn, t, ang))


func _far() -> void:
	var mb := EM.new()
	var haze := Color(0.80, 0.80, 0.88)
	# ang = atan2(z, x): north (z < 0) is ang ~ -PI/2 (= 3PI/2)
	var north := func(ang: float) -> float:
		return clampf(-sin(ang), 0.0, 1.0)
	# forested foothills (no snow), a little nearer
	var foot := func(ang: float) -> float:
		return 15.0 + 6.0 * north.call(ang)
	_ring(mb, 182.0, 168.0, 18.0, foot, 9.0, 903, 1.4, haze.lerp(Color(0.5, 0.6, 0.62), 0.35), 0.38, -6.0)
	# the main range: the high snowy north, lower snow-dusted east and west, soft blue downs to the south
	var main := func(ang: float) -> float:
		var nn: float = north.call(ang)
		var ss := clampf(sin(ang), 0.0, 1.0)
		return 24.0 + 36.0 * pow(nn, 1.5) - 6.0 * ss
	_ring(mb, 196.0, 186.0, 24.0, main, 0.6, 901, 0.45, haze, 0.2, -8.0)
	_save_mesh("em_far", [[mb, "far"]], false)


# ================================================================== props

func _props() -> void:
	# the Master's golden tree: an ancient broad oak in gold leaf (tagged place master_tree)
	var gt := EM.new()
	var bark := Color(0.36, 0.28, 0.2)
	var top := Vector3(0.3, 4.2, -0.2)
	_limb(gt, Vector3(0, -0.4, 0), top, 1.0, 0.7, bark, 10, 4, 71, 0.0, 0.03)
	for k in 6:
		var a := TAU * (k + 0.2) / 6.0
		_limb(gt, Vector3(cos(a) * 1.9, -0.35, sin(a) * 1.9), Vector3(cos(a) * 0.3, 1.6, sin(a) * 0.3), 0.3, 0.55, bark.darkened(0.12), 6, 2, 71 + k, 0.0, 0.0)
	# gold leaves glow even in shade (a lit-from-within crown; the old brown underside read as dead leaves)
	var gfn := _crown_fn(Color(1.0, 0.82, 0.30), Color(0.76, 0.50, 0.13), Color(0.80, 0.50, 0.13))
	for k in 7:
		var a := TAU * (k + 0.4) / 7.0
		var bend := top + Vector3(cos(a) * 4.6, 2.2 + 1.4 * h01(float(k), 1.0, 72), sin(a) * 4.6)
		_limb(gt, top, bend, 0.42, 0.18, bark, 7, 3, 80 + k, 0.03, 0.2)
		_limb(gt, bend, bend + Vector3(cos(a + 0.5) * 2.4, 1.6, sin(a + 0.5) * 2.4), 0.18, 0.07, bark, 5, 2, 90 + k, 0.2, 0.35)
	# ONE broad, flat umbrella canopy (the Master's tree pass, 2026-09-28): a continuous leafy shell with a flat, lumpy
	# underside, shallow leafy bumps on top and a drooping scalloped rim. Every vertex is then re-lit from the SHELL's
	# own normal (an ellipsoid), not its lobe's: the old per-lobe light read as clustered balls from N12's long lens,
	# and the old underside (lobes with sky between them) read as blotchy flakes from S06 below.
	var cc := top + Vector3(0, 5.6, 0)
	var sh_r := 8.9
	var sh_h := 2.9
	var c0 := gt.v.size()
	gt.blob(cc, Vector3(sh_r, sh_h, sh_r), 10, 30, gfn, Vector2(0.25, 2), 0.5, 699, 0.07, 0.0, 0.62, cc, 1.0)
	# the underside: hanging leaf masses pressed into the shell, core only (no cards, so nothing floats as flakes)
	for k in 30:
		var f := (k + 0.5) / 30.0
		var a := TAU * k * 0.618034 + 0.4
		var rr := 7.6 * sqrt(f)
		var rad := 1.25 + 0.55 * h01(float(k), 11.0, 73)
		var c := cc + Vector3(cos(a) * rr, -sh_h * 0.62 + rad * 0.12 - 0.12 * h01(float(k), 12.0, 73), sin(a) * rr)
		if rr < 6.2:
			# interior: small leaf cards hugging the lower face (leafy texture; the shell behind them, never sky)
			_lobe(gt, c, Vector3(rad, rad * 0.42, rad), gfn, Vector2(0.3, 2), h01(float(k), 13.0, 73), 900 + k, cc, 22, 0.34, 4, 9, 1.0, 0.16, true)
		else:
			gt.blob(c, Vector3(rad, rad * 0.42, rad), 4, 9, gfn, Vector2(0.3, 2), h01(float(k), 13.0, 73), 900 + k, 0.16, 0.0)
	# a few broad low domes on the top break the umbrella into an old oak's billowing crown (not a flat pancake)
	for k in 7:
		var a := TAU * (k + 0.3 * h01(float(k), 14.0, 73)) / 7.0 + 0.5
		var rr := 4.4 + 1.2 * h01(float(k), 15.0, 73)
		var ys := sh_h * sqrt(maxf(0.0, 1.0 - pow(rr / sh_r, 2.0)))
		var rad := 3.0 + 0.8 * h01(float(k), 16.0, 73)
		gt.blob(cc + Vector3(cos(a) * rr, ys - rad * 0.12, sin(a) * rr), Vector3(rad, rad * 0.36, rad), 5, 14, gfn, Vector2(0.3, 2), 0.5, 960 + k, 0.08, 0.0, 0.3)
	gt.blob(cc + Vector3(0.4, sh_h - 0.5, -0.3), Vector3(3.6, 1.5, 3.6), 5, 14, gfn, Vector2(0.3, 2), 0.5, 959, 0.08, 0.0, 0.3)
	# the top: shallow leafy bumps sitting IN the shell (a third of each shows), leaf cards on their upper half
	for k in 58:
		var f := (k + 0.5) / 58.0
		var a := TAU * k * 0.618034
		var rr := (sh_r - 0.9) * sqrt(f) * (0.92 + 0.12 * h01(float(k), 2.0, 73))
		var ys := sh_h * sqrt(maxf(0.0, 1.0 - pow(rr / sh_r, 2.0)))
		var rad := 1.35 + 0.6 * h01(float(k), 4.0, 73)
		var c := cc + Vector3(cos(a) * rr, ys - rad * 0.3 + (h01(float(k), 3.0, 73) - 0.5) * 0.35, sin(a) * rr)
		_lobe(gt, c, Vector3(rad, rad * 0.5, rad), gfn, Vector2(0.3 + 0.3 * f, 2), h01(float(k), 5.0, 73), 700 + k, cc, 34, 0.4, 4, 8, 0.92, 0.12, false)
	# the rim: a drooping scalloped fringe hung on the shell's edge (continuous, cards on the outer / upper side only)
	for k in 26:
		var a := TAU * (k + 0.4 * h01(float(k), 6.0, 73)) / 26.0
		var rr := sh_r - 0.5 + 0.5 * h01(float(k), 7.0, 73)
		var rad := 1.0 + 0.75 * h01(float(k), 9.0, 73)
		var c := cc + Vector3(cos(a) * rr, -0.45 - 1.0 * h01(float(k), 8.0, 73), sin(a) * rr)
		_lobe(gt, c, Vector3(rad, rad * 0.8, rad), gfn, Vector2(0.55, 2), h01(float(k), 10.0, 73), 800 + k, cc, 26, 0.36, 4, 8, 0.92, 0.12, false)
	# re-light the whole canopy as one mass: shell normal (a rounder ellipsoid than the mesh, so the rim still turns to
	# the side), colour mostly from it with a little of the part's own tone for leafy texture, and a lifted AO floor
	# on the underside (warm lit-from-within gold, not a dark hole)
	var vv := gt.v
	var nn := gt.n
	var cl := gt.c
	var u2 := gt.uv2
	for i in range(c0, vv.size()):
		var q := vv[i] - cc
		var ne := Vector3(q.x / (sh_r * sh_r), q.y / (3.6 * 3.6), q.z / (sh_r * sh_r)).normalized()
		var col: Color = (gfn.call(ne) as Color).lerp(cl[i], 0.3)
		col.a = cl[i].a
		cl[i] = col
		nn[i] = ne.lerp(nn[i], 0.25).normalized()
		u2[i] = Vector2(u2[i].x, 0.6 + 0.4 * clampf(0.5 + 0.5 * ne.y, 0.0, 1.0))
	gt.n = nn
	gt.c = cl
	gt.uv2 = u2
	# fallen gold leaves on the grass round the trunk
	for k in 220:
		var a := TAU * h01(float(k), 1.0, 74)
		var r := 1.6 + 8.0 * sqrt(h01(float(k), 2.0, 74))
		var x := cos(a) * r
		var z := sin(a) * r
		var y := gh(L.MASTER_TREE.x + x, L.MASTER_TREE.y + z) - gh(L.MASTER_TREE.x, L.MASTER_TREE.y) + 0.03
		var lc := Color(1.0, 0.78, 0.28).lerp(Color(0.84, 0.5, 0.12), h01(float(k), 3.0, 74))
		var o := Vector3(x, y, z)
		var ang := TAU * h01(float(k), 4.0, 74)
		var d := Vector3(cos(ang), 0, sin(ang)) * 0.07
		var s2 := Vector3(-d.z, 0, d.x) * 0.6
		gt.ftri(o - d, o + s2, o + d, lc, Vector2(0, 2), Vector2(0, 0.7))
		gt.ftri(o - d, o + d, o - s2, lc.darkened(0.1), Vector2(0, 2), Vector2(0, 0.7))
	_save_mesh("master_tree", [[gt, "veg_gold"]], true)
	# the heart-stone: fist-sized cracked amber (E34.V1 set stand-in) + its halo
	var hs := EM.new()
	hs.blob(Vector3(0, 0, 0), Vector3(0.055, 0.062, 0.05), 4, 6, func(d: Vector3) -> Color: return Color(0.62, 0.30, 0.06).lerp(Color(0.95, 0.62, 0.2), clampf(d.y * 0.5 + 0.5, 0.0, 1.0)), Vector2.ZERO, 0.0, 17, 0.28, 0.85)
	var hh := EM.new()
	_card(hh, Vector3.ZERO, 0.3, Color(1.0, 0.58, 0.16, 1.0), 0.0)
	_card(hh, Vector3(0, 0.01, 0), 0.07, Color(1.0, 0.85, 0.5, 1.0), 1.0)
	_save_mesh("heart_stone", [[hs, "stone"], [hh, "halo"]], false, 1.0)
	# the bloom patch by Ysolde's hand: flowers leaning toward her (she stands 1.6 m to the south-east)
	var bp := EM.new()
	var toward := Vector3(-1.3, 0, -1.6).normalized()
	var pal := [[Color(0.99, 0.98, 0.93), Color(1.0, 0.78, 0.12), 11, 0.045, 0.08], [Color(0.4, 0.5, 0.98), Color(0.3, 0.2, 0.55), 9, 0.04, 0.3],
		[Color(0.98, 0.6, 0.76), Color(1.0, 0.85, 0.4), 6, 0.05, 0.4], [Color(1.0, 0.86, 0.14), Color(0.95, 0.6, 0.05), 5, 0.035, 0.6]]
	for k in 64:
		var a := TAU * h01(float(k), 1.0, 81)
		var r := 0.48 * sqrt(h01(float(k), 2.0, 81))
		var root := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var h := 0.28 + 0.3 * h01(float(k), 3.0, 81)
		var top2 := root + Vector3(0, h, 0) + toward * h * 0.35
		var ir := h01(float(k), 4.0, 81)
		_stem(bp, root, top2, 0.006, Color(0.24, 0.42, 0.14), 0.7, ir, 1.0)
		var pp: Array = pal[k % pal.size()]
		_head(bp, top2, (Vector3.UP + toward * 0.9).normalized(), pp[3], pp[2], pp[0], pp[1], 0.012, pp[4], 0.7, ir, 1.0, 0.2 if k % 4 == 1 else 0.0)
	_tuft(bp, 60, 0.6, 0.14, 0.42, 0.03, 13)
	for k in 8:
		var a := TAU * k / 8.0
		_head(bp, Vector3(cos(a) * 0.25, 0.05, sin(a) * 0.25), Vector3.UP, 0.09, 5, Color(0.2, 0.4, 0.14), Color(0.3, 0.46, 0.2), 0.0, 0.2, 0.2, 0.3, 1.0)
	_save_mesh("bloom_patch", [[bp, "veg"]], false)
	# a zero-draw subject pin: an invisible 2 cm box, so World Forge's M1 aims at the prop itself (a tagged place's box
	# centre) instead of a character's head height
	var pin := Node3D.new()
	pin.name = "subject_pin"
	var pm := MeshInstance3D.new()
	pm.name = "Pin"
	var bx := BoxMesh.new()
	bx.size = Vector3(0.02, 0.02, 0.02)
	pm.mesh = bx
	pm.visible = false
	pin.add_child(pm)
	pm.owner = pin
	_pack(pin, "subject_pin")

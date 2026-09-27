extends SceneTree
## Task 12.V11 previews. Windowed only (headless has no renderer):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/biomes/glade/glade_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 6000
## A glade patch (r 24 m + 4 m blend) scattered from glade_set.gd items() with the rules the set file documents
## (density, cluster, scale, gap), the lane and a road through it (decor kept off them like MapDressingArt does),
## units of the four kingdoms standing in it (some right inside tall-grass patches), the lighting rig and the game
## camera (pitch 55). Saves docs/art/screens/:
##   12_v11_game_z40.png (+ biome_glade.png)  the 40 m game-camera patch
##   12_v11_game_z40_bare.png                 the same view without the glade decor (readability comparison)
##   12_v11_game_z55.png / 12_v11_game_z25.png / 12_v11_close_z12.png
##   12_v11_contact_sheet.png                 every mesh, its 3 variants side by side, close
##   12_v11_lineup_z40.png                    the same lineup at the 40 m game zoom
## and prints render stats per shot + a wind check.

const SET_PATH := "res://art/environment/biomes/glade/glade_set.gd"
const GLADE_R := 24.0
const BLEND := 4.0
const PATCH_SIZE := 8.0      ## instances per patch (the `cluster` part)
const PATCH_SPREAD := 1.2    ## gaussian sigma of a patch, metres
const LANE_A := Vector2(-70.0, 26.0)
const LANE_B := Vector2(70.0, -26.0)
const ROAD := Vector4(-30.0, -40.0, 18.0, 40.0)
## Units on show: [scene, position (x, z), yaw].
const UNITS := [
	["res://art/units/nature/sprigling.tscn", Vector2(-3.0, 7.0), 0.4],
	["res://art/units/nature/thornling.tscn", Vector2(-1.6, 8.2), 0.2],
	["res://art/units/nature/bramblehorn.tscn", Vector2(-4.4, 9.4), 0.6],
	["res://art/units/fire/flame_guard.tscn", Vector2(4.0, 3.0), 3.4],
	["res://art/units/fire/ember_archer.tscn", Vector2(5.6, 4.1), 3.2],
	["res://art/units/shadow/shadow_knight.tscn", Vector2(9.0, 10.0), 2.4],
	["res://art/units/shadow/shade.tscn", Vector2(10.4, 11.0), 2.6],
	["res://art/units/ice/rimeshield.tscn", Vector2(-9.0, -3.0), 1.0],
	["res://art/units/ice/rime_hauler.tscn", Vector2(-10.2, -1.8), 1.2],
]

var _rig: Node3D
var _rng := RandomNumberGenerator.new()
var _items: Array = []
var _decor: Node3D
var _grass_spots: Array[Vector2] = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	_items = (load(SET_PATH) as GDScript).call(&"items")
	_rng.seed = 12011
	_run_stage()


# ---------------------------------------------------------------- scatter (the set file's rules)

## Glade weight at (x, z): 1 inside the core radius, fading to 0 over the blend ring; 0 where decor is blocked.
func _weight(x: float, z: float, margin: float) -> float:
	var q := Vector2(x, z)
	var w: float = clampf(1.0 - (q.length() - GLADE_R) / BLEND, 0.0, 1.0)
	if w <= 0.0 or _blocked(q, margin):
		return 0.0
	return w


func _blocked(q: Vector2, margin: float) -> bool:
	var c: Vector2 = Geometry2D.get_closest_point_to_segment(q, LANE_A, LANE_B)
	if q.distance_to(c) < 5.2 + margin:
		return true
	var c2: Vector2 = Geometry2D.get_closest_point_to_segment(q, Vector2(ROAD.x, ROAD.y), Vector2(ROAD.z, ROAD.w))
	return q.distance_to(c2) < 2.3 + margin


func _scatter(parent: Node3D) -> void:
	var r: float = GLADE_R + BLEND
	var rect := Rect2(Vector2(-r, -r), Vector2(r, r) * 2.0)
	var total := 0
	for e: Dictionary in _items:
		var mesh: Mesh = e["mesh"]
		var sc: Vector2 = e["scale"]
		var gap: float = float(e.get("gap", 0.0))
		var big: bool = gap > 0.0
		var margin: float = gap * 0.5 if big else 0.25
		var n_full: float = float(e["density"]) * rect.get_area() / 100.0
		var cluster: float = e.get("cluster", 0.5)
		var xfs: Array[Transform3D] = []
		for i: int in int(round(n_full * (1.0 - cluster))):
			var p := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
			if _rng.randf() < _weight(p.x, p.y, margin) and _gap_ok(xfs, p, gap):
				xfs.append(_xf(p, sc))
		var patches: int = int(round(n_full * cluster / PATCH_SIZE))
		for k: int in patches:
			var pc := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
			if _rng.randf() >= _weight(pc.x, pc.y, margin):
				continue
			for j: int in int(PATCH_SIZE):
				var p2: Vector2 = pc + Vector2(_rng.randfn(0.0, PATCH_SPREAD), _rng.randfn(0.0, PATCH_SPREAD)) \
					* (2.0 if big else 1.0)
				if _rng.randf() < _weight(p2.x, p2.y, margin) and _gap_ok(xfs, p2, gap):
					xfs.append(_xf(p2, sc))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xfs.size()
		for i: int in xfs.size():
			mm.set_instance_transform(i, xfs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = String(e.get("name", "decor")).to_pascal_case()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(e["shadow"]) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(e["vis_end"])
		mmi.visibility_range_end_margin = 10.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		parent.add_child(mmi)
		if String(e.get("name", "")) == "glade_tall_grass":
			for xf: Transform3D in xfs:
				_grass_spots.append(Vector2(xf.origin.x, xf.origin.z))
		print("scatter %-22s %4d instances (%.1f / 100 m2 at full weight)" % [mmi.name, xfs.size(),
			float(e["density"])])
		total += xfs.size()
	print("scatter total %d instances on %.0f m2 of glade disc" % [total, PI * GLADE_R * GLADE_R])


func _gap_ok(xfs: Array[Transform3D], p: Vector2, gap: float) -> bool:
	if gap <= 0.0:
		return true
	for xf: Transform3D in xfs:
		if Vector2(xf.origin.x, xf.origin.z).distance_to(p) < gap:
			return false
	return true


func _xf(p: Vector2, sc: Vector2) -> Transform3D:
	var s: float = _rng.randf_range(sc.x, sc.y)
	return Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(p.x, 0.0, p.y))


# ---------------------------------------------------------------- shots

func _shoot(shot: String, zoom: float, focus: Vector3, frames: int = 40, also: String = "") -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.call(&"focus_on", focus)
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var gpu := 0.0
	for i in frames:
		await process_frame
		if i >= frames - 20:
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp) / 20.0
	await RenderingServer.frame_post_draw
	var draws: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	print("shot %-16s draws=%d prims=%d gpu_ms=%.2f" % [shot, draws, prims, gpu])
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/12_v11_%s.png" % shot))
	if also != "":
		img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/%s.png" % also))


func _wind_check(focus: Vector3, zoom: float) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.call(&"focus_on", focus)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var a: Image = root.get_texture().get_image()
	for i in 45:
		await process_frame
	await RenderingServer.frame_post_draw
	var b: Image = root.get_texture().get_image()
	var changed := 0
	for y in range(0, a.get_height(), 4):
		for x in range(0, a.get_width(), 4):
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.06:
				changed += 1
	print("wind check: %d of %d sampled pixels changed in 0.75 s" % [changed, (a.get_width() / 4) * (a.get_height() / 4)])


# ---------------------------------------------------------------- stage

func _run_stage() -> void:
	var stage := Node3D.new()
	stage.name = "Stage"
	root.add_child(stage)
	current_scene = stage
	stage.add_child((load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new())
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 160)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	ground.mesh = plane
	var gm := (load("res://art/environment/ground_material.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	gm.set_shader_parameter(&"lane_a", LANE_A)
	gm.set_shader_parameter(&"lane_b", LANE_B)
	for i in 4:
		gm.set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	var segs := PackedVector4Array()
	segs.resize(16)
	segs[0] = ROAD
	gm.set_shader_parameter(&"road_segs", segs)
	gm.set_shader_parameter(&"road_count", 1)
	ground.material_override = gm
	stage.add_child(ground)
	_decor = Node3D.new()
	_decor.name = "Glade"
	stage.add_child(_decor)
	_scatter(_decor)
	_place_units(stage)
	_build_lineup(stage)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_rig.set(&"min_zoom", 4.0)   # closer than the game allows, for the contact sheet only
	stage.add_child(_rig)
	for i in 5:
		await process_frame
	await _shoot("game_z40", 40.0, Vector3(0, 0, 3), 40, "biome_glade")
	_decor.visible = false
	await _shoot("game_z40_bare", 40.0, Vector3(0, 0, 3))
	_decor.visible = true
	await _shoot("game_z55", 55.0, Vector3(0, 0, 3))
	await _shoot("game_z25", 25.0, Vector3(0, 0, 6))
	await _shoot("close_z12", 12.0, Vector3(-3, 0, 9))
	await _shoot("contact_sheet", 10.5, Vector3(0.3, 0, -44.0))
	await _shoot("lineup_z40", 40.0, Vector3(0, 0, -40.0))
	await _wind_check(Vector3(0, 0, -44.0), 9.0)
	print("SHOTS DONE")
	quit()


## Units of the four kingdoms, plus one sprigling dropped right onto a tall-grass patch (worst case).
func _place_units(stage: Node3D) -> void:
	var list: Array = UNITS.duplicate()
	if not _grass_spots.is_empty():
		var best: Vector2 = _grass_spots[0]
		for p: Vector2 in _grass_spots:   # the grass instance nearest (2, 12): inside the 40 m view
			if p.distance_to(Vector2(2, 12)) < best.distance_to(Vector2(2, 12)):
				best = p
		list.append(["res://art/units/nature/sprigling.tscn", best, 2.0])
		list.append(["res://art/units/fire/cinder_hand.tscn", best + Vector2(0.9, 0.5), 2.4])
	for u: Array in list:
		var path: String = u[0]
		if not ResourceLoader.exists(path):
			print("unit missing: ", path)
			continue
		var n := (load(path) as PackedScene).instantiate() as Node3D
		if n == null:
			continue
		stage.add_child(n)
		var p: Vector2 = u[1]
		n.position = Vector3(p.x, 0.0, p.y)
		n.rotation.y = float(u[2])


## nature_painted.gdshader's hash1 (sine-free, so the CPU gets the variant the GPU draws).
static func _hash1(p: Vector2) -> float:
	var p3 := Vector3(fposmod(p.x * 0.1031, 1.0), fposmod(p.y * 0.1031, 1.0), fposmod(p.x * 0.1031, 1.0))
	var d: float = p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3(33.33, 33.33, 33.33))
	p3 += Vector3(d, d, d)
	return fposmod((p3.x + p3.y) * p3.z, 1.0)


static func variant_at(pos: Vector3) -> int:
	return mini(int(floor(_hash1(Vector2(pos.z, pos.x) + Vector2(3.1, 7.7)) * 3.0)), 2)


func _find_variant(pos: Vector3, variant: int) -> Vector3:
	for i in 400:
		var p: Vector3 = pos + Vector3(fmod(i * 0.173, 0.6) - 0.3, 0.0, fmod(i * 0.311, 0.6) - 0.3)
		if variant_at(p) == variant:
			return p
	return pos


## Every mesh with its 3 variants side by side at z -44: [name, x centre, spacing].
func _build_lineup(stage: Node3D) -> void:
	var rows: Array = [["glade_tall_grass", -4.7, 1.35], ["glade_flowers", -0.9, 1.2], ["glade_butterfly_bush", 3.8, 2.3]]
	for r: Array in rows:
		var mesh := load("res://art/environment/biomes/glade/%s.res" % r[0]) as Mesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = 3
		for i in 3:
			var x: float = float(r[1]) + (i - 1) * float(r[2])
			var pos: Vector3 = _find_variant(Vector3(x, 0.0, -44.0), i)
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, 0.4 + i * 1.7), pos))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stage.add_child(mmi)

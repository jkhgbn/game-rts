extends SceneTree
## Task 13c.V9 screenshots: the Frost Wyrm effects (MapFillWyrmVfx) and the Icebound Barge lair, on a staged north
## river (the barge landmark at its real map spot, riverbed + water materials, the lighting rig, the RTS camera rig),
## with the real Frost Wyrm model (13c.V8) under a stub unit and Flame Guards for scale. Windowed only:
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/vfx/mapfill_wyrm_vfx_preview.gd --resolution 1600x900
##       --quit-after 20000
## Saves docs/art/screens/13c_v9_<shot>.png + a contact sheet 13c_v9_sheet.png. `only=<shot>,<shot>` limits the shots.

const RIVER_N: Array[Vector2] = [Vector2(-15, -62), Vector2(-12, -48.7), Vector2(-9, -38), Vector2(-8, -30), Vector2(-5, -21),
	Vector2(-2.5, -12.5)]
const HALF_W := 2.5
const BARGE := Vector3(-6.2, 0.0, -24.5)
const LAIR_C := Vector3(-4.5, 0.0, -20.5)
const WYRM_SCENE := "res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn"
const GUARD_SCENE := "res://art/units/fire/flame_guard.tscn"
const STUB_SRC := "extends Node3D\nvar team: int = 2\nvar body_height: float = 5.0\nvar alive: bool = true\nfunc is_alive() -> bool:\n\treturn alive\nfunc get_model() -> Node3D:\n\treturn get_node_or_null(\"Model\") as Node3D\n"
const CELL := Vector2i(640, 360)

var _only := ""
var _stage: Node3D
var _rig: Node3D
var _vfx: Node3D
var _lair: Node3D
var _stub: GDScript
var _conv := 1.0
var _label: Label
var _temp: Array[Node] = []
var _shots: Array[Image] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			_only = arg.substr(5)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	_conv = 1.0 if (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]]).dot(n[idx[0]]) >= 0.0 else -1.0
	_stub = GDScript.new()
	_stub.source_code = STUB_SRC
	_stub.reload()
	_run()


func _wanted(shot: String) -> bool:
	return _only == "" or _only.split(",").has(shot)


func _run() -> void:
	_stage = Node3D.new()
	_stage.name = "Stage"
	root.add_child(_stage)
	current_scene = _stage
	_stage.add_child((load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new())
	var gm: ShaderMaterial = (load("res://art/environment/ground_material.tres") as ShaderMaterial).duplicate()
	gm.set_shader_parameter(&"lane_a", Vector2(500, 500))
	gm.set_shader_parameter(&"lane_b", Vector2(501, 501))
	for i in 4:
		gm.set_shader_parameter(StringName("spot_%d" % i), Vector4.ZERO)
	var bed: Material = load("res://art/environment/water/riverbed_mat.tres")
	_stage.add_child(_river_ground(Rect2(-42.0, -66.0, 58.0, 60.0), 0.3, gm, bed))
	var barge := (load("res://art/environment/landmarks/barge.tscn") as PackedScene).instantiate() as Node3D
	barge.position = BARGE
	_stage.add_child(barge)
	var foam := PackedVector4Array()
	for f: Vector3 in (barge.get_meta(&"foam_rocks", PackedVector3Array()) as PackedVector3Array):
		var wp: Vector3 = barge.transform * Vector3(f.x, 0.0, f.y)
		foam.append(Vector4(wp.x, wp.z, f.z, 0.0))
	var wm: ShaderMaterial = (load("res://art/environment/water/water_mat.tres") as ShaderMaterial).duplicate()
	var fa: Array[Vector4] = []
	for f4: Vector4 in foam:
		fa.append(f4)
	while fa.size() < 16:
		fa.append(Vector4.ZERO)
	wm.set_shader_parameter(&"foam_rocks", fa)
	wm.set_shader_parameter(&"foam_rock_count", foam.size())
	_stage.add_child(_water_strip(wm))
	# The lair at the lair centre, as EpicBeasts places it; it snaps onto the barge by itself.
	_lair = (load("res://art/environment/lairs/icebound_barge.tscn") as PackedScene).instantiate() as Node3D
	_lair.position = LAIR_C
	_stage.add_child(_lair)
	_vfx = (load("res://art/vfx/mapfill_wyrm_vfx.gd") as GDScript).new()
	_stage.add_child(_vfx)
	_rig = (load("res://scripts/ui/rts_camera.gd") as GDScript).new()
	_rig.set(&"edge_pan_enabled", false)
	_stage.add_child(_rig)
	var layer := CanvasLayer.new()
	_stage.add_child(layer)
	_label = Label.new()
	_label.position = Vector2(24, 836)
	_label.add_theme_font_size_override(&"font_size", 30)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 10)
	layer.add_child(_label)
	for i in 5:
		await process_frame
	print("lair snapped: ", _lair.call(&"is_snapped"))
	await _lair_shots()
	await _fx_shots()
	_save_sheet()
	print("SHOTS DONE")
	quit()


# ---------------------------------------------------------------- lair

func _lair_shots() -> void:
	_guards([Vector3(-10.2, 0, -23.6), Vector3(-10.6, 0, -25.4), Vector3(-2.4, 0, -26.2)])
	if _wanted("barge_plain"):
		_label.text = "Drowned Barge, lair empty (unchanged landmark)"
		await _shoot("barge_plain", 16.0, BARGE + Vector3(0, 0, 1.5), 0.0)
	_lair.call(&"set_occupied", true)
	await _wait(0.9)
	if _wanted("barge_freezing"):
		_label.text = "Icebound Barge: set_occupied(true), freezing (0.9 s)"
		await _shoot("barge_freezing", 16.0, BARGE + Vector3(0, 0, 1.5), 0.0, 1)
	await _wait(2.2)
	if _wanted("barge_z16"):
		_label.text = "Icebound Barge (occupied)"
		await _shoot("barge_z16", 16.0, BARGE + Vector3(0, 0, 1.5), 0.0)
	if _wanted("barge_close"):
		_label.text = "Icebound Barge close: mast sheath, icicles, snow, hull frost"
		await _shoot("barge_close", 8.0, BARGE + Vector3(0, 0.6, 0.6), 0.0)
	if _wanted("barge_back"):
		_label.text = "Icebound Barge from the north (the mirrored lair as the player sees it)"
		await _shoot("barge_back", 14.0, BARGE + Vector3(0, 0, -1.0), PI)
	if _wanted("barge_z40"):
		_label.text = "Icebound Barge at the game camera, zoom 40"
		await _shoot("barge_z40", 40.0, BARGE + Vector3(0, 0, 5.0), 0.0)
	_lair.call(&"set_occupied", false)
	await _wait(2.5)
	if _wanted("barge_thaw"):
		_label.text = "set_occupied(false): thawing (2.5 s of 6)"
		await _shoot("barge_thaw", 16.0, BARGE + Vector3(0, 0, 1.5), 0.0, 1)
	await _wait(4.0)
	_clear()


# ---------------------------------------------------------------- effects

func _fx_shots() -> void:
	_lair.call(&"set_occupied", true)
	var land := Vector3(-18.0, 0.0, -30.0)
	# Rime Breath (A), airborne, aimed at a squad.
	if _wanted("breath"):
		var gs := _guards([land + Vector3(-1.0, 0, 5.2), land + Vector3(1.0, 0, 5.6), land + Vector3(0.0, 0, 6.6),
				land + Vector3(-2.0, 0, 6.2)])
		var w := _wyrm(land, 0, land + Vector3(0, 0, 8))
		await _wait(0.8)
		_vfx.call(&"play", &"wyrm_breath", land + Vector3(0, 0, 5.8), w)
		(w.get_node("Model")).call(&"play_attack")
		await _wait(0.35 + 0.33)
		_label.text = "wyrm_breath: rime jet + 60 deg rime fan to 7 m"
		await _shoot("breath", 22.0, land + Vector3(0, 0, 3.5), 0.0, 1)
		await _wait(1.0)
		_label.text = "wyrm_breath: the rime fan and cold mist after the jaw closes"
		await _shoot("breath_after", 22.0, land + Vector3(0, 0, 3.5), 0.0, 1)
		await _wait(2.0)
		_clear()
	# Glacial Dive: the telegraph, then the ice burst.
	if _wanted("dive_tele") or _wanted("dive_burst"):
		var spot := land + Vector3(0, 0, 2.0)
		_guards([spot + Vector3(-1.2, 0, 0.6), spot + Vector3(1.0, 0, -0.8), spot + Vector3(0.2, 0, 1.6),
				spot + Vector3(2.6, 0, 1.2)])
		var w := _wyrm(spot + Vector3(0, 0, -2.6), 0, spot + Vector3(0, 0, 6))
		await _wait(0.8)
		_vfx.call(&"play", &"wyrm_dive", spot, w)
		(w.get_node("Model")).call(&"play_cast", &"glacial_dive")
		await _wait(0.6)
		_label.text = "wyrm_dive: telegraph ring r 3 closing (0.6 s of 1.0)"
		await _shoot("dive_tele", 18.0, spot + Vector3(0, 0, 0.5), 0.0, 1)
		await _wait(0.55)
		_label.text = "wyrm_dive: ice burst (crown of spikes, crater, shock ring, snow wall)"
		await _shoot("dive_burst", 18.0, spot + Vector3(0, 0, 0.5), 0.0, 1)
		await _wait(0.9)
		_label.text = "wyrm_dive: the ice crown shatters (1.2 s after landing)"
		await _shoot("dive_shatter", 18.0, spot + Vector3(0, 0, 0.5), 0.0, 1)
		await _wait(3.5)
		_clear()
	# Tail Lash (grounded coil).
	if _wanted("tail"):
		var c := land + Vector3(-1, 0, 1)
		_guards([c + Vector3(3.0, 0, 1.2), c + Vector3(-2.4, 0, 2.6), c + Vector3(1.0, 0, -3.2)])
		var w := _wyrm(c, 0, c + Vector3(0, 0, 6))
		(w.get_node("Model")).call(&"set_grounded", true)
		await _wait(1.3)
		_vfx.call(&"play", &"wyrm_tail", c, w)
		(w.get_node("Model")).call(&"play_cast", &"tail_lash")
		await _wait(0.35 + 0.12)
		_label.text = "wyrm_tail: the lash arc sweeping round the coil (r 3.5)"
		await _shoot("tail", 16.0, c, 0.0, 1)
		await _wait(0.25)
		_label.text = "wyrm_tail: arc + snow spray just after the strike"
		await _shoot("tail_after", 16.0, c, 0.0, 1)
		await _wait(1.5)
		_clear()
	# Blizzard (Old Hoarfang).
	if _wanted("blizzard"):
		var c := land + Vector3(0, 0, 1)
		_guards([c + Vector3(4.0, 0, 2.0), c + Vector3(-5.0, 0, -1.0), c + Vector3(1.0, 0, 6.0), c + Vector3(6.5, 0, -3.0),
				c + Vector3(-9.5, 0, 2.0)])
		var w := _wyrm(c, 1, c + Vector3(0, 0, 6))
		await _wait(0.8)
		_vfx.call(&"play", &"wyrm_blizzard", c, w)
		(w.get_node("Model")).call(&"play_cast", &"blizzard")
		await _wait(0.75 + 0.3)
		_label.text = "wyrm_blizzard: release burst + ring racing to r 8 (Old Hoarfang)"
		await _shoot("blizzard_release", 30.0, c + Vector3(0, 0, 2), 0.0, 1)
		await _wait(2.0)
		_label.text = "wyrm_blizzard: 8 s snow wall r 8 following the Wyrm"
		await _shoot("blizzard", 30.0, c + Vector3(0, 0, 2), 0.0, 1)
		_label.text = "wyrm_blizzard at zoom 45"
		await _shoot("blizzard_z45", 45.0, c + Vector3(0, 0, 4), 0.0, 1)
		await _wait(7.0)
		_clear()
	# The 30 s pre-spawn warning over the river (time sped up x6).
	if _wanted("warning"):
		_lair.call(&"set_occupied", false)
		await _wait(6.5)
		_vfx.call(&"play", &"wyrm_warning", LAIR_C, null)
		Engine.time_scale = 6.0
		await _wait(4.0 * 6.0)
		Engine.time_scale = 1.0
		_label.text = "wyrm_warning: cold mist over the river, 24 s into the 30 s warning"
		await _shoot("warning", 26.0, BARGE + Vector3(1, 0, 3), 0.0, 1)
		await _wait(6.2)
		_lair.call(&"set_occupied", true)
		_label.text = "wyrm_warning: the frost pulse at 30 s, the barge freezes as the Wyrm spawns"
		await _shoot("warning_pulse", 26.0, BARGE + Vector3(1, 0, 3), 0.0, 1)
		await _wait(4.0)
	await _stress()


## Two Wyrms doing everything at once (cost check).
func _stress() -> void:
	if not _wanted("stress"):
		return
	var a := Vector3(-22.0, 0.0, -40.0)
	var b := Vector3(-14.0, 0.0, -46.0)
	var w1 := _wyrm(a, 1, a + Vector3(0, 0, 5))
	var w2 := _wyrm(b, 0, b + Vector3(0, 0, 5))
	_guards([a + Vector3(2, 0, 3), b + Vector3(-2, 0, 3), a + Vector3(4, 0, -2)])
	await _wait(0.8)
	_vfx.call(&"play", &"wyrm_blizzard", a, w1)
	(w1.get_node("Model")).call(&"play_cast", &"blizzard")
	_vfx.call(&"play", &"wyrm_dive", b + Vector3(0, 0, 3), w2)
	(w2.get_node("Model")).call(&"play_cast", &"glacial_dive")
	_vfx.call(&"play", &"wyrm_warning", LAIR_C, null)
	await _wait(1.2)
	_vfx.call(&"play", &"wyrm_breath", b + Vector3(0, 0, 5), w2)
	(w2.get_node("Model")).call(&"play_attack")
	var t0 := Time.get_ticks_usec()
	_vfx.call(&"_process", 1.0 / 60.0)
	print("MapFillWyrmVfx _process (busy): %d us" % (Time.get_ticks_usec() - t0))
	await _wait(0.5)
	_label.text = "stress: two Wyrms, blizzard + dive + breath + warning at once (zoom 38)"
	await _shoot("stress", 38.0, (a + b) * 0.5, 0.0, 1)
	print("stress: running=", _vfx.call(&"active_count"), " live=", _vfx.call(&"live_count"), " fps=",
			Engine.get_frames_per_second())
	await _wait(9.0)
	print("after 9 s: running=", _vfx.call(&"active_ids"))
	_clear()


# ---------------------------------------------------------------- helpers

func _wyrm(pos: Vector3, variant: int, face: Vector3) -> Node3D:
	var u := Node3D.new()
	u.set_script(_stub)
	u.name = "WyrmUnit"
	u.set_meta(&"beast_variant", variant)
	var m := (load(WYRM_SCENE) as PackedScene).instantiate() as Node3D
	m.name = "Model"
	m.call(&"set_variant", variant)
	u.add_child(m)
	_stage.add_child(u)
	u.global_position = pos
	u.look_at(Vector3(face.x, pos.y, face.z), Vector3.UP, true)
	_temp.append(u)
	return u


func _guards(points: Array) -> Array:
	var out: Array = []
	if not ResourceLoader.exists(GUARD_SCENE):
		return out
	var ps := load(GUARD_SCENE) as PackedScene
	for p: Vector3 in points:
		var g := ps.instantiate() as Node3D
		_stage.add_child(g)
		g.position = p
		g.rotation.y = p.x * 0.7
		_temp.append(g)
		out.append(g)
	return out


func _clear() -> void:
	for n in _temp:
		if is_instance_valid(n):
			n.queue_free()
	_temp.clear()


func _wait(sec: float) -> void:
	await create_timer(sec).timeout   # game time (the warning shot speeds it up with Engine.time_scale)


func _shoot(shot: String, zoom: float, focus: Vector3, yaw: float, frames: int = 30) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.rotation.y = yaw
	_rig.call(&"focus_on", focus)
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/13c_v9_%s.png" % shot))
	var small := img.duplicate() as Image
	small.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
	small.convert(Image.FORMAT_RGBA8)
	_shots.append(small)
	print("shot %-18s draws=%d prims=%d fps=%d" % [shot, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), Engine.get_frames_per_second()])


func _save_sheet() -> void:
	if _shots.is_empty():
		return
	var cols := 4
	var rows := (_shots.size() + cols - 1) / cols
	var sheet := Image.create_empty(CELL.x * cols, CELL.y * rows, false, Image.FORMAT_RGBA8)
	for i in _shots.size():
		sheet.blit_rect(_shots[i], Rect2i(Vector2i.ZERO, CELL), Vector2i((i % cols) * CELL.x, (i / cols) * CELL.y))
	sheet.save_png(ProjectSettings.globalize_path("res://docs/art/screens/13c_v9_sheet.png"))


# ---------------------------------------------------------------- staged river (landmarks_b_preview.gd's)

func _river_dist(p: Vector2) -> float:
	var best := INF
	for i in RIVER_N.size() - 1:
		var a: Vector2 = RIVER_N[i]
		var b: Vector2 = RIVER_N[i + 1]
		var ab: Vector2 = b - a
		var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


func _height(x: float, z: float) -> float:
	var d: float = _river_dist(Vector2(x, z))
	return -1.0 + smoothstep(HALF_W - 0.35, HALF_W + 0.05, d)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	if (1.0 if fn.y >= 0.0 else -1.0) != _conv:
		var t: Vector3 = b
		b = c
		c = t
		var tn: Vector3 = nb
		nb = nc
		nc = tn
	st.set_normal(na)
	st.add_vertex(a)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_normal(nc)
	st.add_vertex(c)


func _river_ground(r: Rect2, cell: float, land: Material, bed: Material) -> MeshInstance3D:
	var nx: int = int(r.size.x / cell)
	var nz: int = int(r.size.y / cell)
	var hs: Array[PackedFloat32Array] = []
	for j in nz + 1:
		var row := PackedFloat32Array()
		for i in nx + 1:
			row.append(_height(r.position.x + i * cell, r.position.y + j * cell))
		hs.append(row)
	var st_land := SurfaceTool.new()
	var st_bed := SurfaceTool.new()
	st_land.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_bed.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in nz:
		for i in nx:
			var p: Array[Vector3] = []
			var nn: Array[Vector3] = []
			for q: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var y: float = hs[q.y][q.x]
				p.append(Vector3(r.position.x + q.x * cell, y, r.position.y + q.y * cell))
				var hl: float = hs[q.y][maxi(q.x - 1, 0)]
				var hr: float = hs[q.y][mini(q.x + 1, nx)]
				var hd: float = hs[maxi(q.y - 1, 0)][q.x]
				var hu: float = hs[mini(q.y + 1, nz)][q.x]
				nn.append(Vector3(hl - hr, 2.0 * cell, hd - hu).normalized())
			var low: bool = false
			for pp: Vector3 in p:
				if pp.y < -0.02:
					low = true
			var st: SurfaceTool = st_bed if low else st_land
			_tri(st, p[0], p[1], p[2], nn[0], nn[1], nn[2])
			_tri(st, p[0], p[2], p[3], nn[0], nn[2], nn[3])
	var mesh := ArrayMesh.new()
	st_land.commit(mesh)
	mesh.surface_set_material(0, land)
	st_bed.commit(mesh)
	mesh.surface_set_material(1, bed)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	return mi


func _water_strip(m: Material) -> MeshInstance3D:
	var pts: Array[Vector2] = []
	for i in RIVER_N.size() - 1:
		var a: Vector2 = RIVER_N[i]
		var b: Vector2 = RIVER_N[i + 1]
		var steps: int = maxi(1, int(a.distance_to(b) / 0.5))
		for k in steps:
			pts.append(a.lerp(b, float(k) / steps))
	pts.append(RIVER_N[RIVER_N.size() - 1])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var along := 0.0
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var prev_u := 0.0
	for i in pts.size():
		var t: Vector2 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var nrm := Vector2(t.y, -t.x)
		var l := Vector3(pts[i].x + nrm.x * HALF_W, -0.35, pts[i].y + nrm.y * HALF_W)
		var rr := Vector3(pts[i].x - nrm.x * HALF_W, -0.35, pts[i].y - nrm.y * HALF_W)
		if i > 0:
			along += pts[i].distance_to(pts[i - 1])
			for tri: Array in [[prev_l, prev_r, rr, Vector2(prev_u, 0), Vector2(prev_u, 1), Vector2(along, 1)],
					[prev_l, rr, l, Vector2(prev_u, 0), Vector2(along, 1), Vector2(along, 0)]]:
				var a3: Vector3 = tri[0]
				var b3: Vector3 = tri[1]
				var c3: Vector3 = tri[2]
				var ua: Vector2 = tri[3]
				var ub: Vector2 = tri[4]
				var uc: Vector2 = tri[5]
				if (1.0 if (b3 - a3).cross(c3 - a3).y >= 0.0 else -1.0) != _conv:
					var tv: Vector3 = b3
					b3 = c3
					c3 = tv
					var tu: Vector2 = ub
					ub = uc
					uc = tu
				for pair: Array in [[a3, ua], [b3, ub], [c3, uc]]:
					st.set_normal(Vector3.UP)
					st.set_uv(pair[1])
					st.add_vertex(pair[0])
		prev_l = l
		prev_r = rr
		prev_u = along
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

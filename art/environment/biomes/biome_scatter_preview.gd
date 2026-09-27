extends SceneTree
## Task 12.V6 previews and GPU check on the REAL skirmish (bot off, fog off, HUD hidden). Windowed only:
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/biomes/biome_scatter_preview.gd
##       --resolution 1600x900 --fixed-fps 60 --quit-after 30000 -- [legacy=1] [low=1] [shots=0] [frames=N]
## Default: the biome scatter (MapDressingArt 12.V6), screenshots of every biome at zoom 40 and 55 saved as
## docs/art/screens/12_v6_<biome>_z40.png / _z55.png, then the GPU check (default zoom 30 over the Crown Isle and the Old
## Wood, max zoom 55 over the north / south river), printed as `perf <shot> gpu_ms=...`.
## legacy=1: the old decor (MapDressingArt.biomes_enabled = false), same map: the "before" numbers (no screenshots).
## low=1: Map detail Low (prints the counts, screenshots saved as 12_v6_low_*). shots=0: GPU check only.
## breakdown=1: GPU cost of each decor kind (hidden one at a time) + a one-variant-mesh experiment; split=1: only the
## experiment (it showed the decor cost is fragment work, not the 3-variant vertex submission).

const SHOTS: Array = [
	# [name, zoom, focus]
	["ruins", 40.0, Vector3(0.0, 0.0, 1.0)],
	["riverbank", 40.0, Vector3(-7.0, 0.0, -33.0)],
	["meadow", 40.0, Vector3(-30.0, 0.0, 44.0)],
	["old_wood", 40.0, Vector3(-44.0, 0.0, -44.0)],
	["heath", 40.0, Vector3(-51.0, 0.0, 6.0)],
	["glade", 40.0, Vector3(-18.0, 0.0, 26.0)],
	["ruins", 55.0, Vector3(0.0, 0.0, 1.0)],
	["riverbank", 55.0, Vector3(-9.0, 0.0, -38.0)],
	["meadow", 55.0, Vector3(-32.0, 0.0, 40.0)],
	["old_wood", 55.0, Vector3(-42.0, 0.0, -42.0)],
	["heath", 55.0, Vector3(-48.0, 0.0, 10.0)],
	["glade", 55.0, Vector3(-20.0, 0.0, 22.0)],
]
const PERF: Array = [
	["isle_z30", 30.0, Vector3(0.0, 0.0, 0.0)],
	["old_wood_z30", 30.0, Vector3(-45.0, 0.0, -45.0)],
	["river_n_z55", 55.0, Vector3(-8.0, 0.0, -34.0)],
	["river_s_z55", 55.0, Vector3(8.0, 0.0, 34.0)],
	["centre_z55", 55.0, Vector3(0.0, 0.0, 0.0)],
]

var _main: Node
var _rig: Node3D
var _legacy := false
var _low := false
var _shots := true
var _breakdown := false
var _split_only := false
var _measure := 90


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "legacy=1":
			_legacy = true
		elif arg == "low=1":
			_low = true
		elif arg == "shots=0":
			_shots = false
		elif arg == "breakdown=1":
			_breakdown = true
		elif arg == "split=1":
			_breakdown = true
			_split_only = true
		elif arg.begins_with("frames="):
			_measure = int(arg.substr(7))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	var mda: GDScript = load("res://art/environment/map_dressing_art.gd")
	mda.set(&"map_detail_override", &"low" if _low else &"high")
	node_added.connect(_on_node_added)
	_run()


func _on_node_added(n: Node) -> void:
	var s: Script = n.get_script() as Script
	if s and s.resource_path == "res://art/environment/map_dressing_art.gd":
		n.set(&"biomes_enabled", not _legacy)


func _run() -> void:
	_main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = _main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(_main)
	current_scene = _main
	var wait := 0
	while _main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	for i in 40:
		await process_frame
	var fog: Node = _main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in _main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	var hud: Node = _main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	_rig = _main.get(&"camera_rig")
	_rig.set(&"edge_pan_enabled", false)
	var d: Node = _main.find_child("MapDressing", true, false)
	print("mode=%s detail=%s decor=%d kinds=%d draw_nodes=%d populate_ms=%.0f" % ["legacy" if _legacy else "biomes",
		"low" if _low else "high", int(d.call(&"decor_count")), (d.call(&"kind_paths") as PackedStringArray).size(),
		d.find_children("*", "GeometryInstance3D", true, false).size(), float(d.call(&"populate_msec"))])
	print("biomes: ", d.call(&"biome_counts"), " timings: ", d.call(&"populate_timings"))
	var per_kind: Array[String] = []
	for k: String in (d.call(&"kind_paths") as PackedStringArray):
		per_kind.append("%s %d" % [k.get_file().get_basename(), (d.call(&"instance_positions", k) as PackedVector3Array).size()])
	per_kind.sort()
	print("kinds: ", ", ".join(per_kind))
	if _breakdown:
		await _run_breakdown(d)
		print("SHOTS DONE")
		quit()
		return
	if _shots and not _legacy:
		for s: Array in SHOTS:
			var nm: String = ("12_v6_low_%s_z%d" if _low else "12_v6_%s_z%d") % [s[0], int(s[1])]
			await _shoot(nm, s[1], s[2], true)
	for p: Array in PERF:
		await _shoot(p[0], p[1], p[2], false)
	print("SHOTS DONE")
	quit()


## GPU cost of each decor kind: hide its MultiMeshes, measure, show them again (isle at zoom 30, centre at 55).
func _run_breakdown(d: Node) -> void:
	var by_kind := {}
	for n: Node in d.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if mmi.get_parent().name != "Biomes" and mmi.get_parent().name != "Decor":
			continue
		var k: String = mmi.multimesh.mesh.resource_path.get_file().get_basename()
		if not by_kind.has(k):
			by_kind[k] = []
		(by_kind[k] as Array).append(mmi)
	for p: Array in [PERF[0], PERF[4]]:
		await _shoot("all_" + String(p[0]), p[1], p[2], false)
		for k: String in ([] if _split_only else by_kind.keys()):
			for m: MultiMeshInstance3D in by_kind[k]:
				m.visible = false
			await _shoot("no_%s_%s" % [k, p[0]], p[1], p[2], false)
			for m: MultiMeshInstance3D in by_kind[k]:
				m.visible = true
		var dec: Node3D = d.get_node_or_null(^"Biomes") as Node3D
		if dec == null:
			dec = d.get_node_or_null(^"Decor") as Node3D
		dec.visible = false
		await _shoot("no_decor_" + String(p[0]), p[1], p[2], false)
		dec.visible = true
	# Experiment: every biome MultiMesh drawing ONE variant's triangles (what a per-variant split would cost).
	var cache := {}
	for k2: String in by_kind:
		for m2: MultiMeshInstance3D in by_kind[k2]:
			var src: Mesh = m2.multimesh.mesh
			if not cache.has(src):
				cache[src] = _one_variant(src as ArrayMesh)
			m2.multimesh.mesh = cache[src]
	for p2: Array in [PERF[0], PERF[4]]:
		await _shoot("onevariant_" + String(p2[0]), p2[1], p2[2], false)


func _one_variant(src: ArrayMesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s: int in src.get_surface_count():
		var arr: Array = src.surface_get_arrays(s)
		var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2] if arr[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		if uv2.is_empty() or idx.is_empty():
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			out.surface_set_material(out.get_surface_count() - 1, src.surface_get_material(s))
			continue
		var keep := PackedInt32Array()
		for t: int in range(0, idx.size(), 3):
			var ok := true
			for c: int in 3:
				var m: float = uv2[idx[t + c]].x
				if m > 0.5 and (int(m) & 1) == 0:
					ok = false
			if ok:
				keep.append(idx[t])
				keep.append(idx[t + 1])
				keep.append(idx[t + 2])
		for i: int in uv2.size():
			if uv2[i].x > 0.5:
				uv2[i].x = 0.0
		arr[Mesh.ARRAY_TEX_UV2] = uv2
		arr[Mesh.ARRAY_INDEX] = keep
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		out.surface_set_material(out.get_surface_count() - 1, src.surface_get_material(s))
	return out


func _shoot(shot: String, zoom: float, focus: Vector3, save: bool) -> void:
	_rig.set(&"_target_zoom", zoom)
	_rig.set(&"_zoom", zoom)
	_rig.call(&"focus_on", focus)
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var gpu := 0.0
	var cpu := 0.0
	var frames: int = 30 if save else 40
	var n: int = 5 if save else _measure
	for i in frames + n:
		await process_frame
		if i >= frames:
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp) / float(n)
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp) / float(n)
	await RenderingServer.frame_post_draw
	var draws: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	print("%s %-26s draws=%d prims=%d gpu_ms=%.2f cpu_ms=%.2f" % ["shot" if save else "perf", shot, draws, prims,
		gpu, cpu])
	if save:
		var img: Image = root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("res://docs/art/screens/%s.png" % shot))

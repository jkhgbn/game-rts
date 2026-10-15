extends SceneTree
## Task G2b: water shots and fps in a real level (windowed only, headless has no renderer).
##   tools\godot_run.ps1 --path . -s res://art/environment/water/water_shots.gd --resolution 1920x1080 --quit-after 9000
##       -- map=thornwater tag=after gfx-list=high,ultra [fps] [shots] [out=docs/art/lab/g2b_water]
## map = a MapCatalog id (crown_hollow = skirmish.tscn with the Crown Isle moat, thornwater = LayoutLevel + river).
## Shots: the river mid-span, the first ford, the first bridge and (Crown Hollow) the moat, each at zoom 10 / 30 / 50,
## fog of war and HUD off, saved as <out>/<tag>_<map>_<spot>_z<zoom>.png at the first tier of gfx-list.
## fps: per tier of gfx-list (GameSettings.apply_graphics, the same call as the settings menu), vsync off, the camera
## over the river at zoom 30 and 50, 4 s of frames each: prints "WATER_FPS map=.. gfx=.. zoom=.. fps=.. ms=..".

const ZOOMS: Array[float] = [10.0, 30.0, 50.0]
const GFX_IDS: Array[String] = ["low", "medium", "high", "ultra"]

var _map := "thornwater"
var _tag := "after"
var _out := "res://docs/art/lab/g2b_water"
var _gfx_list: Array[String] = ["high"]
var _do_fps := false
var _do_shots := false
var _water_tier := -1   ## water-tier=N: the water's tier for the shots (0 = the 12.V1 look), else the gfx tier
var _level: Node


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var k := a.get_slice("=", 0).trim_prefix("--")
		var v := a.get_slice("=", 1) if a.contains("=") else ""
		match k:
			"map":
				_map = v
			"tag":
				_tag = v
			"out":
				_out = "res://" + v.trim_prefix("res://")
			"gfx-list":
				_gfx_list.clear()
				for g in v.split(","):
					_gfx_list.append(g.strip_edges())
			"water-tier":
				_water_tier = v.to_int()
			"fps":
				_do_fps = true
			"shots":
				_do_shots = true
	print("WATER_SHOTS args=", OS.get_cmdline_user_args())
	if not _do_fps and not _do_shots:
		_do_shots = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var cat_script: Script = load("res://scripts/world/map_catalog.gd")
	var cat: Object = cat_script.call(&"load_default")
	_level = cat.call(&"instantiate_level", StringName(_map)) as Node
	if _level == null:
		print("WATER_SHOTS ERROR: unknown map ", _map)
		quit(1)
		return
	_level.set(&"player_kingdom", &"fire")
	_level.set(&"enemy_kingdom", &"shadow")
	if &"time_limit_s" in _level:
		_level.set(&"time_limit_s", 0.0)
	root.add_child(_level)
	current_scene = _level
	var waited := 0
	while not bool(_level.get(&"match_started")):
		await process_frame
		waited += 1
		if waited > 6000:
			print("WATER_SHOTS ERROR: the match never started")
			quit(1)
			return
	for i in 30:
		await process_frame
	var cam: Variant = _level.get(&"camera_rig")
	if cam is Node:
		(cam as Node).set(&"edge_pan_enabled", false)
	var fog: Variant = _level.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", false)
	# HUD and every other overlay (the STR / INT pick card...): the shots are about the 3D water.
	# (Not the lighting rig's vignette / haze layer: it is part of the look.)
	var rigs := get_nodes_in_group(&"lighting_rigs")
	for n in _level.find_children("*", "CanvasLayer", true, false):
		var in_rig := false
		for r in rigs:
			if r == n or (r as Node).is_ancestor_of(n):
				in_rig = true
		if not in_rig:
			(n as CanvasLayer).visible = false
	var river: Node = null
	for n in get_nodes_in_group(&"river"):
		river = n
	if river == null:
		print("WATER_SHOTS ERROR: no river on ", _map)
		quit(1)
		return
	var spots := _spots(river)
	print("WATER_SHOTS map=%s spots=%s viewport=%s" % [_map, str(spots.keys()), str(root.get_visible_rect().size)])
	var ss: Script = load("res://scripts/ui/menus/game_settings.gd")
	if _do_shots:
		ss.call(&"apply_graphics", self, maxi(0, GFX_IDS.find(_gfx_list[0])))
		_apply_water_tier(_water_tier if _water_tier >= 0 else maxi(0, GFX_IDS.find(_gfx_list[0])))
		for spot: String in spots:
			for z in ZOOMS:
				await _place(spots[spot], z)
				var img := root.get_texture().get_image()
				var path := "%s/%s_%s_%s_z%d.png" % [_out, _tag, _map, spot, int(z)]
				img.save_png(ProjectSettings.globalize_path(path))
				print("WATER_SHOT ", path)
	if _do_fps:
		var vp: RID = root.get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(vp, true)
		for g in _gfx_list:
			var q := maxi(0, GFX_IDS.find(g))
			ss.call(&"apply_graphics", self, q)
			_apply_water_tier(q)
			for z: float in [10.0, 30.0, 50.0]:
				await _place(spots["river"], z)
				var on: Array[float] = await _measure(4000000)
				var meshes := _water_meshes(river)
				for m in meshes:
					m.visible = false
				var off: Array[float] = await _measure(3000000)
				for m in meshes:
					m.visible = true
				print("WATER_FPS map=%s gfx=%s zoom=%d fps=%.1f ms=%.2f gpu_ms=%.2f water_gpu_ms=%.2f (no water: fps %.1f)" % [
						_map, g, int(z), on[0], on[1], on[2], on[2] - off[2], off[0]])
	quit(0)


## The water's own tier hook (art/environment/water/water_quality.gd), when it exists (the "before" tree has none).
func _apply_water_tier(q: int) -> void:
	const WQ := "res://art/environment/water/water_quality.gd"
	if ResourceLoader.exists(WQ):
		(load(WQ) as Script).call(&"pin", q)


## The water surfaces of the river (RiverWater*, MoatWater*, Film*), for the with / without cost.
func _water_meshes(river: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var vis := river.get_node_or_null(^"Visuals")
	if vis == null:
		return out
	for c in vis.get_children():
		var n := String(c.name)
		if c is MeshInstance3D and (n.contains("Water") or n.begins_with("Film")):
			out.append(c as Node3D)
	return out


func _measure(frames_wanted_us: int) -> Array[float]:
	var vp: RID = root.get_viewport_rid()
	for i in 30:
		await process_frame
	var t0 := Time.get_ticks_usec()
	var frames := 0
	var gpu := 0.0
	while Time.get_ticks_usec() - t0 < frames_wanted_us:
		await process_frame
		frames += 1
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	var secs := float(Time.get_ticks_usec() - t0) / 1000000.0
	return [frames / secs, secs * 1000.0 / frames, gpu / maxf(1.0, frames)]


func _place(at: Vector3, zoom: float) -> void:
	var cam: Variant = _level.get(&"camera_rig")
	if not (cam is Node3D):
		return
	# Public RTSCamera API: fly_to with 0 s = at once (yaw 0, the default pitch); its _process applies the zoom.
	(cam as Node).call(&"fly_to", at, 0.0, zoom, 0.0)
	for i in 45:
		await process_frame
	await RenderingServer.frame_post_draw


## Points to look at: river mid-span (longest polyline's middle, away from crossings), first ford circle, first
## bridge, the moat (opposite the river mouth).
func _spots(river: Node) -> Dictionary:
	var out := {}
	var crossings: Array = river.call(&"crossings")
	var lines: Array = river.call(&"polylines")
	var best_line := PackedVector2Array()
	for l: PackedVector2Array in lines:
		if l.size() > best_line.size():
			best_line = l
	if best_line.size() >= 2:
		# The polyline point farthest from every crossing, among the middle half of the line.
		var best_d := -1.0
		var best_p := best_line[best_line.size() / 2]
		for i in range(best_line.size() / 4, best_line.size() * 3 / 4 + 1):
			var p: Vector2 = best_line[i]
			var d := INF
			for c: Dictionary in crossings:
				var cc: Vector3 = c["center"]
				d = minf(d, p.distance_to(Vector2(cc.x, cc.z)))
			if d > best_d and absf(p.x) < MapInfo.half_x() - 12.0 and absf(p.y) < MapInfo.half_z() - 12.0:
				best_d = d
				best_p = p
		out["river"] = Vector3(best_p.x, 0.0, best_p.y)
	for c: Dictionary in crossings:
		var kind := String(c.get("kind", ""))
		if kind == "ford" and not out.has("ford"):
			out["ford"] = c["center"]
		elif kind.begins_with("bridge") and not out.has("bridge"):
			out["bridge"] = c["center"]
	var moat: Vector4 = river.call(&"moat")
	if moat.z > 0.0:
		out["moat"] = Vector3(moat.x - moat.z, 0.0, moat.y)
	if not out.has("river"):
		out["river"] = Vector3.ZERO
	return out

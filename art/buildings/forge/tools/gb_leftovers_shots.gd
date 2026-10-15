extends SceneTree
## Task G-B leftovers (docs/art/gb_leftovers.md): windowed shots + fps on the real skirmish map. Around the team-1 keep:
## the four Forges (Fire / Nature / Shadow new, Ice for reference; one Nature Forge at 20 % HP, a Fire Forge site at
## 50 %), the Ember Stables, a Gloom Hall and two Hovels (dead ground vs the G2a grass). Bot off, fog off, HUD hidden.
##   tag=before : the forges keep ForgeBuilding's placeholder (model_path cleared in memory), the Ember Stables the
##                old stables_painted (FireBuildingLook.legacy), the dead ground does not clear the grass.
##   tag=after  : the shipped look.
## Then a completion sequence: a Grove Hall, a Frost Hall and a Gloom Hall site complete in front of the camera
## (settle_f04 / f12 / f30 shots), and the fps over the forges at zoom 30.
## Windowed only:
##   tools\godot_run.ps1 --path . -s res://art/buildings/forge/tools/gb_leftovers_shots.gd --resolution 1920x1080
##       --quit-after 60000 -- --gfx=high tag=after [perf=0] [only=forges_z30,...]

const OUT_DIR := "res://docs/art/lab/gb_leftovers"
const SHOTS: Array = [
	["forges_z30", 30.0, "forges"],
	["fire_forge_z10", 10.0, "fire"],
	["nature_forge_z10", 10.0, "nature"],
	["shadow_forge_z10", 10.0, "shadow"],
	["ice_forge_z10", 10.0, "ice"],
	["damaged_z14", 14.0, "damaged"],
	["stables_z10", 10.0, "stables"],
	["grass_z12", 12.0, "grass"],
]

var main: Node
var _tag := "after"
var _perf := true
var _only := ""
var _cam: Node3D
var _focus := {}
var _results := {}
var _kp := Vector3.ZERO
var _toward := Vector3.FORWARD
var _side := Vector3.RIGHT


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var k := arg.get_slice("=", 0)
		var v := arg.substr(k.length() + 1)
		match k:
			"tag": _tag = v
			"perf": _perf = v != "0"
			"only": _only = v
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	if _tag == "before":
		for id: String in ["fire_forge", "nature_forge", "shadow_forge"]:
			BuildingType.find(id).model_path = ""
		(load("res://art/buildings/fire/fire_building_look.gd") as Script).set(&"legacy", true)
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	main.set(&"enemy_kingdom", &"shadow")
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	_run()


func _run() -> void:
	var wait := 0
	while main.get(&"hero") == null and wait < 3000:
		await process_frame
		wait += 1
	var fog: Node = main.get(&"fog")
	if fog:
		fog.call(&"set_enabled", false)
	for n: Node in main.get_children():
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
	_cam = main.get(&"camera_rig")
	_cam.set(&"edge_pan_enabled", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var q: int = GameSettings.effective_graphics_quality()
	print("GBL tag=%s tier=%d" % [_tag, q])
	GameSettings.apply_graphics(self, q)
	await _stage()
	for s: Array in SHOTS:
		if _only != "" and not _only.split(",").has(s[0]):
			continue
		await _shot(s[0], s[1], _focus[s[2]], q)
	if _only == "" or _only.contains("settle"):
		await _settle_sequence(q)
	if _perf:
		await _measure(q)
	for qq: Variant in _results.keys():
		var r: Array = _results[qq]
		print("GBL PERF q=%s tag=%s avg_fps=%.1f low1_fps=%.1f gpu_ms_med=%.2f draws=%d" % [str(qq), _tag, r[0], r[1], r[2], r[3]])
	print("GBL DONE")
	quit()


func _shot(nm: String, zoom: float, at: Vector3, q: int) -> void:
	paused = false
	_cam.call(&"fly_to", at, 0.0, zoom, 0.0)
	for i in 50:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var path := "%s/%s_q%d_%s.png" % [OUT_DIR, _tag, q, nm]
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved %s" % path)


func _put(grid: Node, id: String, off: Vector3, site: bool = false) -> Building:
	var ty := BuildingType.find(id)
	var want: Vector3 = _kp + _side * off.x + _toward * off.z
	var spot: Vector3 = grid.call(&"find_spot", ty, want, 1, 6)
	if spot == Vector3.INF or not spot.is_finite():
		spot = want
	return (grid.call(&"spawn_site", ty, spot, 1) if site else grid.call(&"spawn_complete", ty, spot, 1)) as Building


func _stage() -> void:
	var grid: Node = main.get(&"build_grid")
	var keep: Node3D = null
	for b: Node in get_nodes_in_group(&"buildings"):
		if b is Keep and int(b.get(&"team")) == 1:
			keep = b as Node3D
	_kp = keep.global_position
	_toward = (Vector3.ZERO - _kp)
	_toward.y = 0.0
	_toward = _toward.normalized()
	_side = Vector3.UP.cross(_toward).normalized()
	var f_fire := _put(grid, "fire_forge", Vector3(-10, 0, 10))
	var f_nat := _put(grid, "nature_forge", Vector3(-3, 0, 12))
	var f_sh := _put(grid, "shadow_forge", Vector3(4, 0, 12))
	var f_ice := _put(grid, "ice_forge", Vector3(11, 0, 10))
	var f_site := _put(grid, "fire_forge", Vector3(-6, 0, 20), true)
	var f_dmg := _put(grid, "nature_forge", Vector3(1, 0, 21))
	var f_dmg2 := _put(grid, "shadow_forge", Vector3(8, 0, 20))
	var stables := _put(grid, "fire_stables", Vector3(-18, 0, -2))
	var hall := _put(grid, "shadow_barracks", Vector3(16, 0, -2))
	var hov := _put(grid, "shadow_hovel", Vector3(20, 0, 5))
	_put(grid, "shadow_hovel", Vector3(13, 0, 6))
	for i in 3:
		await process_frame
	f_dmg.take_damage(f_dmg.max_hp * 0.8, null)
	f_dmg2.take_damage(f_dmg2.max_hp * 0.6, null)
	var sm: Node = f_site.model()
	if sm and sm.has_method(&"set_construction_progress"):
		sm.call(&"set_construction_progress", 0.5)
	if _tag == "before":
		for b: Node in get_nodes_in_group(&"buildings"):
			var m: Node = (b as Building).model() if b is Building else null
			if m and m.has_meta(&"_grass_clear_radius"):
				m.remove_meta(&"_grass_clear_radius")
	_focus["forges"] = (f_fire.global_position + f_nat.global_position + f_sh.global_position + f_ice.global_position) / 4.0
	_focus["fire"] = f_fire.global_position
	_focus["nature"] = f_nat.global_position
	_focus["shadow"] = f_sh.global_position
	_focus["ice"] = f_ice.global_position
	_focus["damaged"] = (f_site.global_position + f_dmg.global_position + f_dmg2.global_position) / 3.0
	_focus["stables"] = stables.global_position
	_focus["grass"] = (hall.global_position + hov.global_position) * 0.5
	for i in 240:
		await process_frame


## Three halls finish construction in front of the camera: shots 4 / 12 / 30 frames after completion.
func _settle_sequence(q: int) -> void:
	var grid: Node = main.get(&"build_grid")
	var sites: Array[Building] = []
	var c := Vector3.ZERO
	for e: Array in [["nature_barracks", Vector3(-8, 0, 32)], ["ice_barracks", Vector3(0, 0, 33)], ["shadow_barracks", Vector3(8, 0, 32)]]:
		var b := _put(grid, e[0], e[1], true)
		sites.append(b)
		c += b.global_position / 3.0
	for i in 5:
		await process_frame
	for b: Building in sites:
		b.load_snapshot({"progress": 0.8}, {})
		b.hp = b.max_hp
	_cam.call(&"fly_to", c, 0.0, 22.0, 0.0)
	for i in 60:
		await process_frame
	for b: Building in sites:
		b.load_snapshot({"progress": 1.0}, {})
		b.heal(b.max_hp)
	var t := 0
	for f: int in [4, 12, 30]:
		for i in f - t:
			await process_frame
		t = f
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path := "%s/%s_q%d_settle_f%02d.png" % [OUT_DIR, _tag, q, f]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved %s" % path)


func _measure(q: Variant) -> void:
	paused = false
	_cam.call(&"fly_to", _focus["forges"], 0.0, 30.0, 0.0)
	for i in 90:
		await process_frame
	var times: Array[float] = []
	var gpu: Array[float] = []
	var vp_rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var last := Time.get_ticks_usec()
	for i in 600:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now - last))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp_rid))
		last = now
	gpu.sort()
	var total := 0.0
	for x: float in times:
		total += x
	times.sort()
	var p99: float = times[maxi(int(times.size() * 0.99) - 1, 0)]
	_results[q] = [1e6 * times.size() / total, 1e6 / p99, gpu[gpu.size() / 2],
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))]

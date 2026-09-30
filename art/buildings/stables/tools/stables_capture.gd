extends SceneTree
## In-game capture of the four Stables (read-only tool, same method as docs/art/ingame_grade/ingame_capture.gd):
## a real windowed skirmish at 1600 x 900, the real RTS camera + HUD, fog off, both bases built (every kingdom
## building incl. the Stables), then per side: the Stables at RTS zoom 30 (+ 18 close, 48 far), a construction site
## at 50 %, 40 % / 20 % HP and the collapse (1.2 s / 2.8 s).
## Run (through the gate): tools\godot_run.ps1 --path . -s res://art/buildings/stables/tools/stables_capture.gd
##   --quit-after 400000 -- --kp=fire --ke=shadow --tag=after
## Shots: docs/art/lab/stables_ingame/<tag>/<kingdom>_<shot>.png

const SKIRMISH := "res://scenes/skirmish.tscn"
const OUT_ROOT := "res://docs/art/lab/stables_ingame"

var args := {}
var main: Node = null
var kp := "fire"
var ke := "shadow"
var tag := "after"
var out := ""


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var wd := create_timer(400.0, true, false, true)
	wd.timeout.connect(func() -> void:
		print("CAP ERROR watchdog")
		quit(3))
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	kp = String(args.get("kp", "fire"))
	ke = String(args.get("ke", "shadow"))
	tag = String(args.get("tag", "after"))
	out = "%s/%s" % [OUT_ROOT, tag]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	for i in 4:
		await process_frame
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", StringName(kp))
	main.set(&"enemy_kingdom", StringName(ke))
	main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	var waited := 0
	while not bool(main.get(&"match_started")):
		await process_frame
		waited += 1
		if waited > 20000:
			print("CAP ERROR never started")
			quit(2)
			return
	for i in 30:
		await process_frame
	for team in [0, 1]:
		var wz: Node = main.call(&"wizard_of", team)
		var pn: Node = wz.get_node_or_null(^"StrIntPath") if wz else null
		if pn and not bool(pn.call(&"is_locked")):
			pn.call(&"choose", pn.call(&"default_pick"))
	paused = false
	for i in 10:
		await process_frame
	var cam: Node = main.get(&"camera_rig")
	cam.set(&"edge_pan_enabled", false)
	Input.warp_mouse(Vector2(1598, 898))
	var fog: Variant = main.get(&"fog")
	if fog is Node:
		(fog as Node).set(&"enabled", false)
	var ts: Node = get_first_node_in_group(&"tier_systems")
	if ts:
		ts.call(&"set_tier", 0, 3)
		ts.call(&"set_tier", 1, 3)
	for team in [0, 1]:
		_build_base(team, kp if team == 0 else ke)
	for i in 150:
		await process_frame
	for team in [0, 1]:
		var k: String = kp if team == 0 else ke
		var st: Node3D = _stables_of(team)
		if st == null:
			print("CAP no stables for ", k)
			continue
		var at: Vector3 = st.global_position
		print("CAP stables ", k, " at ", at, " model=", st.call(&"model") != null)
		await _shot("%s_z30" % k, at, 30.0)
		await _shot("%s_z18" % k, at, 18.0)
		await _shot("%s_z48" % k, at, 48.0)
		# A construction site at 50 % next to it (spawned complete, then turned back into a site).
		var bt: Resource = st.get(&"building_type")
		var grid: Object = main.get(&"build_grid")
		var spot: Vector3 = grid.call(&"find_spot", bt, at + Vector3(0, 0, 9) * (1 if team == 0 else -1), team, 12)
		print("CAP site spot ", spot)
		if spot != Vector3.INF:
			var site: Node3D = grid.call(&"spawn_complete", bt, spot, team)
			await process_frame
			var m: Node = site.call(&"model")
			if m and m.has_method(&"set_construction_progress"):
				m.call(&"set_construction_progress", 0.5)
			for i in 20:
				await process_frame
			await _shot("%s_site50" % k, (at + spot) * 0.5, 30.0)
			if m:
				m.call(&"set_construction_progress", 0.15)
			for i in 10:
				await process_frame
			await _shot("%s_site15" % k, (at + spot) * 0.5, 22.0)
			site.queue_free()
		var mh: float = float(st.get(&"max_hp"))
		st.call(&"take_damage", mh * 0.6)
		await _wait(1.5)
		await _shot("%s_hp40" % k, at, 22.0)
		st.call(&"take_damage", mh * 0.2)
		await _wait(1.5)
		await _shot("%s_hp20" % k, at, 22.0)
		st.call(&"take_damage", mh)
		await _wait(1.2)
		await _shot("%s_dead12" % k, at, 22.0)
		await _wait(1.05)
		await _shot("%s_dead24" % k, at, 22.0)
	print("CAP done")
	quit(0)


func _stables_of(team: int) -> Node3D:
	for b: Node in get_nodes_in_group(&"buildings"):
		var bt: Variant = b.get(&"building_type")
		if bt is Resource and StringName((bt as Resource).get(&"kind")) == &"stables" and int(b.get(&"team")) == team:
			return b as Node3D
	return null


func _wait(sec: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < int(sec * 1000.0):
		await process_frame


func _shot(id: String, at: Vector3, zoom: float) -> void:
	var cam: Node3D = main.get(&"camera_rig")
	cam.rotation = Vector3.ZERO
	cam.call(&"focus_on", at + Vector3(0, 0, zoom * 0.14))
	cam.set(&"_zoom", zoom)
	cam.set(&"_target_zoom", zoom)
	cam.call(&"_apply_zoom")
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var p := ProjectSettings.globalize_path("%s/%s.png" % [out, id])
	img.save_png(p)
	print("CAP shot ", p)


func _build_base(team: int, kingdom: String) -> void:
	var grid: Object = main.get(&"build_grid")
	var near: Vector3 = main.call(&"base_center", team)
	var ids: Array[String] = []
	for f: String in DirAccess.get_files_at("res://data/buildings/"):
		var fn := f.trim_suffix(".remap")
		if fn.ends_with(".tres") and fn.begins_with(kingdom + "_") and not fn.contains("keep"):
			ids.append(fn.get_basename())
	ids.sort()
	var dir: Vector3 = Vector3(1, 0, -1) if team == 0 else Vector3(-1, 0, 1)
	var i := 0
	for id in ids:
		var bt: Resource = load("res://data/buildings/%s.tres" % id)
		var target: Vector3 = near + dir * (8.0 + 3.0 * (i % 3)) + Vector3(dir.z, 0, -dir.x) * (-10.0 + 7.0 * float(i))
		var spot: Vector3 = grid.call(&"find_spot", bt, target, team, 14)
		if spot == Vector3.INF:
			print("CAP no spot for ", id)
			i += 1
			continue
		var b: Node = grid.call(&"spawn_complete", bt, spot, team)
		print("CAP built ", id, " at ", spot, " ok=", b != null)
		i += 1

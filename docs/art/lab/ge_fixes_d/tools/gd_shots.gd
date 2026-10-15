extends SceneTree
## G-E fixes D shots (docs/art/ge_fixes_d.md): a copy of docs/art/lab/ge_value/tools/gv_shots.gd plus `--mode=riders`
## (the Thornback warden / Bramble dartcaster riders close, team 0 and 1, z7 and z12). Original header:
## G-E value pass shots (docs/art/ge_value_pass.md), a copy of docs/art/lab/ge_review/tools/ge_shots.gd plus a
## `measure` mode. WINDOWED only; pass the tier.
##   tools\godot_run.ps1 --path . -s docs/art/lab/ge_value/tools/gv_shots.gd --resolution 1600x900 --quit-after 400000 '--' --gfx=high --mode=bases --pk=fire --ek=shadow --tag=before_fs [--battle] [--quick]
##   ... '--' --gfx=high --mode=measure --tag=before_measure --out=<abs dir>   (PNG triples per kingdom: normal / mask / ground)
## Then: python -I docs/art/lab/ge_value/tools/gv_measure.py <dir>
## JPGs (1600x900) in docs/art/lab/ge_value/<tag>/ (the folder has a .gdignore); --out overrides the folder.

var OUT := "res://docs/art/lab/ge_fixes_d"
const SKIRMISH := "res://scenes/skirmish.tscn"
const WS_SCENE := "res://scenes/wave_strike.tscn"
const HOUSES := {"fire": "fire_hearth", "ice": "ice_lodge", "nature": "nature_hollow", "shadow": "shadow_hovel"}
const BAD := ["Outside the map", "Not on walkable ground", "Blocked", "Too close to a crystal node", "Can't build on water",
		"Too close to a crossing", "Too close to a monster camp", "Can't build that"]

var args := {}
var tag := "x"
var main: Node
var _ov_cam: Camera3D


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	tag = String(args.get("tag", "x"))
	if args.has("out"):
		OUT = String(args["out"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [OUT, tag]))
	for i in 3:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1600, 900))
		for f in 4:
			await process_frame
	var mode := String(args.get("mode", "bases"))
	if mode == "bases":
		await _run_bases()
	elif mode == "map":
		await _run_map(StringName(String(args.get("map", "crown_hollow"))))
	elif mode == "scout":
		await _run_scout()
	elif mode == "measure":
		await _run_measure()
	elif mode == "riders":
		await _run_riders()
	elif mode == "battle":
		await _run_battle_only()
	elif mode == "keep":
		await _run_keep()
	elif mode == "leaves":
		await _run_leaves()
	elif mode == "matmap":
		await _run_matmap()
	elif mode == "mission":
		await _run_mission(String(args.get("mission", "")), String(args.get("name", "mission")))
	print("GE SHOTS DONE ", tag)
	quit(0)


# ---------------------------------------------------------------- helpers

func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _shot(name: String) -> void:
	Input.warp_mouse(Vector2(800, 450))
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var p := ProjectSettings.globalize_path("%s/%s/%s.jpg" % [OUT, tag, name])
	img.save_jpg(p, 0.92)
	print("shot ", name, " fps=", Engine.get_frames_per_second())


func _cam(at: Vector3, zoom: float) -> void:
	if _ov_cam:
		_ov_cam.queue_free()
		_ov_cam = null
	var cam: Variant = main.get(&"camera_rig")
	if not (cam is Node3D):
		return
	var c := cam as Node3D
	c.set(&"edge_pan_enabled", false)
	c.rotation = Vector3.ZERO
	c.call(&"focus_on", at)
	c.set(&"_zoom", zoom)
	c.set(&"_target_zoom", zoom)
	c.call(&"_apply_zoom")
	var cam3 := c.get(&"camera") as Camera3D
	if cam3:
		cam3.make_current()


## A free camera high over the map (overviews beyond the RTS zoom range).
func _overview(center: Vector3, dist: float, pitch_deg: float) -> void:
	if _ov_cam == null:
		_ov_cam = Camera3D.new()
		_ov_cam.fov = 50.0
		_ov_cam.far = 3000.0
		main.add_child(_ov_cam)
	var p := deg_to_rad(pitch_deg)
	_ov_cam.global_position = center + Vector3(0.0, sin(p) * dist, cos(p) * dist)
	_ov_cam.rotation = Vector3(-p, 0.0, 0.0)
	_ov_cam.make_current()


func _close_picker() -> void:
	var hero: Variant = main.get(&"hero")
	if hero is Node:
		var sp := StrIntPath.of(hero as Node)
		if sp and not sp.is_locked():
			sp.choose(sp.default_pick())
	for n in root.find_children("*", "", true, false):
		if n is StrIntPanel:
			n.set(&"visible", false)


func _hud(on: bool) -> void:
	var hud: Variant = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = on


func _fog(on: bool) -> void:
	var fog: Variant = main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", on)


func _wait_level(max_s: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if float(Time.get_ticks_msec() - t0) / 1000.0 > max_s:
			return false
	return true


func _kingdom_types(kingdom: String) -> Array[String]:
	var names: Array[String] = []
	for f: String in DirAccess.get_files_at("res://data/units/"):
		var fn := f.trim_suffix(".remap")
		if fn.ends_with(".tres"):
			names.append(fn.get_basename())
	names.sort()
	var workers: Array[String] = []
	var rest: Array[String] = []
	for id: String in names:
		var t: Resource = load("res://data/units/%s.tres" % id)
		if t == null or String(t.get(&"faction")) != kingdom:
			continue
		if bool(t.get(&"is_caravan")) or float(t.get(&"lifetime")) > 0.0:
			continue
		if bool(t.get(&"is_worker")):
			workers.append(id)
		else:
			rest.append(id)
	return workers + rest


func _unit(id: String, team: int, pos: Vector3, face: float) -> Unit:
	var u := Worker.make_unit(UnitType.find(id))
	if u == null:
		return null
	u.team = team as Unit.Team
	main.add_child(u)
	if u.has_method(&"set_down"):
		u.set_down(pos)
	else:
		u.global_position = pos
	u.command_stop()
	u.rotation.y = face
	return u


func _place_building(id: String, team: int, want: Vector3) -> Building:
	var t := BuildingType.find(id)
	if t == null:
		print("no building ", id)
		return null
	var bg: BuildGrid = main.get(&"build_grid")
	for r in [0.0, 2.0, 4.0, 6.0, 8.0, 10.0]:
		var steps := 1 if r == 0.0 else 12
		for k in steps:
			var a := TAU * float(k) / float(steps)
			var p := want + Vector3(cos(a) * r, 0.0, sin(a) * r)
			var c := bg.snap(p, t.footprint) if bg else p
			var why := bg.check(t, c, team) if bg else ""
			if why in BAD:
				continue
			var b := BuildGrid.create_building(t)
			b.team = team as Unit.Team
			main.add_child(b)
			b.global_position = c
			return b
	print("no spot for ", id, " near ", want)
	return null


# ---------------------------------------------------------------- bases

func _run_bases() -> void:
	var pk := String(args.get("pk", "fire"))
	var ek := String(args.get("ek", "shadow"))
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", StringName(pk))
	main.set(&"enemy_kingdom", StringName(ek))
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		print("GE ERROR: skirmish never started")
		return
	await _wait(1.0)
	_close_picker()
	for team in [0, 1]:
		var eco := Economy.for_team(team)
		if eco:
			eco.add(100000)
	var quick := args.has("quick")
	var kingdoms := {0: pk, 1: ek}
	var info := {}
	for team: int in [0, 1]:
		info[team] = _build_base(team, String(kingdoms[team]))
	await _wait(4.0)
	# In-game view: fog on, HUD on, the player's base.
	var k0: Vector3 = info[0]["keep"]
	var d0: Vector3 = info[0]["dir"]
	_hud(true)
	_cam(k0 + d0 * 6.0, 32.0)
	await _wait(0.6)
	await _shot("ingame_%s_z32" % pk)
	if not quick:
		_cam(k0 + d0 * 26.0, 40.0)
		await _wait(0.6)
		await _shot("ingame_fogedge_%s_z40" % pk)
	_hud(false)
	_fog(false)
	await _wait(0.5)
	for team: int in [0, 1]:
		var kname := "%s_%s" % [kingdoms[team], "p" if team == 0 else "e"]
		var k: Vector3 = info[team]["keep"]
		var d: Vector3 = info[team]["dir"]
		_cam(k + d * 7.0, 30.0)
		await _wait(0.6)
		await _shot("base_%s_z30" % kname)
		_cam(k + d * 7.0, 40.0)
		await _wait(0.5)
		await _shot("base_%s_z40" % kname)
		if quick:
			continue
		_cam(k, 10.0)
		await _wait(0.5)
		await _shot("keep_%s_z10" % kname)
		if info[team]["hall"] != null:
			_cam((info[team]["hall"] as Node3D).global_position, 10.0)
			await _wait(0.5)
			await _shot("hall_%s_z10" % kname)
		_cam(info[team]["army"], 10.0)
		await _wait(0.5)
		await _shot("army_%s_z10" % kname)
		_cam(info[team]["army"], 20.0)
		await _wait(0.5)
		await _shot("army_%s_z20" % kname)
	await _lineups(kingdoms)
	if args.has("battle"):
		await _battle()


## Keep + Hall + 3 houses + 2 towers + Stables + Forge + an army of every unit type.
func _build_base(team: int, kingdom: String) -> Dictionary:
	var keep_pos: Vector3 = main.call(&"base_center", team)
	var kp: Variant = main.call(&"keep_of", team)
	if kp is Node3D:
		keep_pos = (kp as Node3D).global_position
	var d := Vector3(-keep_pos.x, 0.0, -keep_pos.z).normalized()
	var p := Vector3(-d.z, 0.0, d.x)
	var at := func(f: float, s: float) -> Vector3: return keep_pos + d * f + p * s
	var hall := _place_building("%s_barracks" % kingdom, team, at.call(6.0, 12.0))
	for o: Vector2 in [Vector2(-6.0, 11.0), Vector2(-10.0, 4.0), Vector2(-10.0, -4.0)]:
		_place_building(String(HOUSES[kingdom]), team, at.call(o.x, o.y))
	_place_building("%s_tower" % kingdom, team, at.call(15.0, -6.0))
	_place_building("%s_tower" % kingdom, team, at.call(13.0, 14.0))
	_place_building("%s_stables" % kingdom, team, at.call(4.0, -12.0))
	_place_building("%s_forge" % kingdom, team, at.call(-5.0, -12.0))
	var army_c: Vector3 = at.call(22.0, 0.0)
	var types := _kingdom_types(kingdom)
	var face := atan2(d.x, d.z)
	var i := 0
	for id: String in types:
		var col := i % 5
		var row := i / 5
		_unit(id, team, army_c + p * (float(col) - 2.0) * 2.4 - d * float(row) * 2.6, face)
		i += 1
	return {"keep": keep_pos, "dir": d, "hall": hall, "army": army_c}


## Every unit type of each kingdom in two rows (player in front, enemy behind), zoom 35 and 18.
func _lineups(kingdoms: Dictionary) -> void:
	var center := Vector3(-30.0, 0.0, 30.0)
	var hidden: Array = []
	for u in get_nodes_in_group(&"units"):
		if u is Node3D and (u as Node3D).visible and (u as Node3D).global_position.distance_to(center) < 30.0:
			(u as Node3D).visible = false
			hidden.append(u)
	for team: int in [0, 1]:
		var kingdom := String(kingdoms[team])
		var types := _kingdom_types(kingdom)
		var made: Array[Unit] = []
		var n := types.size()
		for r: int in [0, 1]:
			for i in n:
				var x := (float(i) - float(n - 1) * 0.5) * 2.4
				var u := _unit(types[i], r, center + Vector3(x, 0.0, -4.0 * float(r)), 0.0)
				if u:
					if u.has_method(&"command_hold"):
						u.call(&"command_hold")
					made.append(u)
		for z: float in [30.0, 40.0]:
			_cam(center + Vector3(0, 0, -2.0), z)
			await _wait(1.2)
			await _shot("lineup_%s_z%d" % [kingdom, int(z)])
		for u in made:
			if is_instance_valid(u):
				u.queue_free()
		await _wait(0.3)
	for h: Node in hidden:
		if is_instance_valid(h):
			(h as Node3D).visible = true


## Mixed 4-kingdom battle: Fire + Nature (player) against Ice + Shadow (enemy).
func _battle() -> void:
	var c := Vector3(-30.0, 0.0, 30.0)
	var left: Array[Unit] = []
	var right: Array[Unit] = []
	var sides := [[0, ["fire", "nature"]], [1, ["ice", "shadow"]]]
	for sd: Array in sides:
		var team: int = sd[0]
		var i := 0
		for k: String in sd[1]:
			var types := _kingdom_types(k)
			for id: String in types.slice(1, 9):
				var col := i % 8
				var row := i / 8
				var z := 7.0 + float(row) * 2.4
				var pos := c + Vector3((float(col) - 3.5) * 2.2, 0.0, z if team == 0 else -z)
				var u := _unit(id, team, pos, 0.0 if team == 1 else PI)
				if u:
					u.max_hp = 20000.0
					u.hp = 20000.0
					(left if team == 0 else right).append(u)
				i += 1
	for u in left + right:
		if u.has_method(&"command_attack_move"):
			u.call(&"command_attack_move", c)
		else:
			u.command_move(c)
	_cam(c, 30.0)
	await _wait(5.0)
	await _shot("battle_z30")
	_cam(c, 40.0)
	await _wait(1.5)
	await _shot("battle_z40")
	if args.has("quick"):
		return
	_cam(c, 14.0)
	await _wait(1.0)
	await _shot("battle_z14")
	# a few deaths for the death / hit look
	var kills := 0
	for u in left + right:
		if kills % 3 == 0 and is_instance_valid(u) and u.is_alive():
			u.take_damage(999999.0, null)
		kills += 1
	await _wait(0.4)
	await _shot("battle_deaths_z14")
	_cam(c, 30.0)
	await _wait(0.3)
	await _shot("battle_deaths_z30")


# ---------------------------------------------------------------- measure

## Per kingdom on the meadow (Crown Hollow, warm preset, fog / HUD off, zoom 35): every unit type in two rows (team 0 =
## main palette), then a building row (Hall, house, tower, Stables, Forge). Three PNGs each: `<k>_<what>_a` (normal),
## `_m` (every unit / building mesh unshaded magenta = the mask), `_g` (the units / buildings hidden = the ground).
func _run_measure() -> void:
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		print("GE ERROR: skirmish never started")
		return
	await _wait(1.0)
	_close_picker()
	var eco := Economy.for_team(0)
	if eco:
		eco.add(100000)
	_hud(false)
	_fog(false)
	var center := Vector3(12.0, 0.0, -33.0)   # open meadow south-east of the centre (scout shots)
	for u in get_nodes_in_group(&"units"):
		if u is Node3D and (u as Node3D).global_position.distance_to(center) < 40.0:
			(u as Node3D).visible = false
	var mask_mat := StandardMaterial3D.new()
	mask_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mask_mat.albedo_color = Color(1.0, 0.0, 1.0)
	mask_mat.disable_fog = true
	var kingdoms: Array = String(args.get("kingdoms", "fire,ice,nature,shadow")).split(",")
	for k: String in kingdoms:
		var types := _kingdom_types(k)
		var made: Array[Node3D] = []
		var all: Array[String] = types + types
		var rows := int(ceil(float(all.size()) / 6.0))
		for i in all.size():
			var col := i % 6
			var row := i / 6
			var pos := center + Vector3((float(col) - 2.5) * 2.4, 0.0, (float(row) - float(rows - 1) * 0.5) * 2.8)
			var u := _unit(all[i], 0, pos, 0.0)
			if u:
				if u.has_method(&"command_hold"):
					u.call(&"command_hold")
				made.append(u)
		await _measure_triple("%s_units" % k, made, center, 35.0, mask_mat)
		for u in made:
			if is_instance_valid(u):
				u.queue_free()
		await _wait(0.4)
		var blds: Array[Node3D] = []
		var bids := ["%s_barracks" % k, String(HOUSES[k]), "%s_tower" % k, "%s_stables" % k, "%s_forge" % k]
		var offs := [Vector3(-7, 0, -6), Vector3(4, 0, -7), Vector3(11, 0, -3), Vector3(-6, 0, 6), Vector3(6, 0, 6)]
		for j in bids.size():
			var b := _place_building(bids[j], 0, center + (offs[j] as Vector3))
			if b:
				blds.append(b)
		await _wait(3.0)
		await _measure_triple("%s_buildings" % k, blds, center, 35.0, mask_mat)
		for b in blds:
			if is_instance_valid(b):
				b.queue_free()
		await _wait(0.6)


## Which materials make a kingdom's unit pixels: the measure grid, then per material (surface-level) an unshaded magenta
## override; prints visible pixel count + mean colour (normal shot) per material, largest first.
func _run_matmap() -> void:
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		print("GE ERROR: skirmish never started")
		return
	await _wait(1.0)
	_close_picker()
	_hud(false)
	_fog(false)
	var center := Vector3(12.0, 0.0, -33.0)
	for u in get_nodes_in_group(&"units"):
		if u is Node3D and (u as Node3D).global_position.distance_to(center) < 40.0:
			(u as Node3D).visible = false
	var mask_mat := StandardMaterial3D.new()
	mask_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mask_mat.albedo_color = Color(1.0, 0.0, 1.0)
	mask_mat.disable_fog = true
	var k := String(args.get("kingdoms", "nature"))
	var types := _kingdom_types(k)
	var all: Array[String] = types + types
	var rows := int(ceil(float(all.size()) / 6.0))
	var made: Array[Node3D] = []
	for i in all.size():
		var pos := center + Vector3((float(i % 6) - 2.5) * 2.4, 0.0, (float(i / 6) - float(rows - 1) * 0.5) * 2.8)
		var u := _unit(all[i], 0, pos, 0.0)
		if u:
			if u.has_method(&"command_hold"):
				u.call(&"command_hold")
			made.append(u)
	_cam(center, 35.0)
	await _wait(1.5)
	# pause the motion so every shot sees the same pose
	for n in made:
		n.process_mode = Node.PROCESS_MODE_DISABLED
	await _wait(0.3)
	var base := await _grab()
	# material -> [[MeshInstance3D, surface]...]
	var uses := {}
	for n in made:
		for g in n.find_children("*", "MeshInstance3D", true, false):
			var mi := g as MeshInstance3D
			if not mi.is_visible_in_tree() or mi.mesh == null:
				continue
			for si in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(si)
				if mat == null:
					continue
				if not uses.has(mat):
					uses[mat] = []
				(uses[mat] as Array).append([mi, si])
	var res: Array = []
	for mat: Material in uses.keys():
		for e: Array in uses[mat]:
			(e[0] as MeshInstance3D).set_surface_override_material(e[1], mask_mat)
		var img := await _grab()
		for e: Array in uses[mat]:
			(e[0] as MeshInstance3D).set_surface_override_material(e[1], null)
		var cnt := 0
		var sum := Vector3.ZERO
		for y in range(150, 700, 2):
			for x in range(450, 1300, 2):
				var c := img.get_pixel(x, y)
				if c.r > 0.8 and c.g < 0.25 and c.b > 0.8:
					var b := base.get_pixel(x, y)
					sum += Vector3(b.r, b.g, b.b)
					cnt += 1
		if cnt > 0:
			var nm := mat.resource_name if mat.resource_name != "" else mat.resource_path.get_file()
			if nm == "" and mat is ShaderMaterial and (mat as ShaderMaterial).shader:
				nm = "shader:" + (mat as ShaderMaterial).shader.resource_path.get_file()
			if mat is ShaderMaterial and (mat as ShaderMaterial).get_shader_parameter(&"base_color") != null:
				nm += " base=" + str((mat as ShaderMaterial).get_shader_parameter(&"base_color"))
			elif mat is BaseMaterial3D:
				nm += " albedo=" + str((mat as BaseMaterial3D).albedo_color)
			res.append([cnt, nm, sum / float(cnt)])
	res.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	var total := 0
	for r: Array in res:
		total += int(r[0])
	for r: Array in res:
		var c: Vector3 = r[2]
		print("MAT %6d %5.1f%%  rgb(%.2f %.2f %.2f)  %s" % [int(r[0]), 100.0 * float(r[0]) / float(maxi(total, 1)), c.x, c.y, c.z, r[1]])


func _grab() -> Image:
	for i in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	return img


## Only the 4-kingdom battle (+ the deaths shots at z14 / z30: the Nature death leaves).
func _run_battle_only() -> void:
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"nature")
	main.set(&"enemy_kingdom", &"shadow")
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		print("GE ERROR: skirmish never started")
		return
	await _wait(1.0)
	_close_picker()
	_hud(false)
	_fog(false)
	await _battle()


## A Shadow base (keep + Hall + 3 hovels + towers + Stables + Forge, no army) at z12 (the keep), z30 and z40 (the base),
## plus a hovel close-up (z10).
func _run_keep() -> void:
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		print("GE ERROR: skirmish never started")
		return
	await _wait(1.0)
	_close_picker()
	var eco := Economy.for_team(1)
	if eco:
		eco.add(100000)
	var info := _build_base(1, "shadow")
	await _wait(4.0)
	_hud(false)
	_fog(false)
	var k: Vector3 = info["keep"]
	var d: Vector3 = info["dir"]
	_cam(k, 12.0)
	await _wait(0.8)
	await _shot("keep_shadow_z12")
	_cam(k + d * 7.0, 30.0)
	await _wait(0.6)
	await _shot("base_shadow_z30")
	await _shot_png("base_shadow_z30")
	_cam(k + d * 7.0, 40.0)
	await _wait(0.6)
	await _shot("base_shadow_z40")
	for b in get_nodes_in_group(&"buildings"):
		if b is Building and (b as Building).building_type and String((b as Building).building_type.id) == "shadow_hovel":
			_cam((b as Node3D).global_position, 10.0)
			await _wait(0.6)
			await _shot("hovel_z10")
			break


## The Nature war models' own death leaves (NatureWarModel.add_death_bloom) alone: thornlings, burr slingers and
## bramblehorns on the meadow, every CombatFxG node hidden, all killed at once; shots at z30 / z14, 0.3 s after.
func _run_leaves() -> void:
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		print("GE ERROR: skirmish never started")
		return
	await _wait(1.0)
	_close_picker()
	_hud(false)
	_fog(false)
	var center := Vector3(12.0, 0.0, -33.0)
	for u in get_nodes_in_group(&"units"):
		if u is Node3D and (u as Node3D).global_position.distance_to(center) < 40.0:
			(u as Node3D).visible = false
	for n in root.find_children("*", "", true, false):
		var sc: Variant = n.get_script()
		if sc is Script and String((sc as Script).resource_path).find("combat_fx_g") >= 0:
			n.process_mode = Node.PROCESS_MODE_DISABLED
			if n is Node3D:
				(n as Node3D).visible = false
	for z: float in [30.0, 14.0]:
		var made: Array[Unit] = []
		var ids := ["thornling", "burr_slinger", "bramblehorn"]
		for i in 9:
			var u := _unit(ids[i % 3], 0, center + Vector3((float(i % 3) - 1.0) * 2.6, 0.0, (float(i / 3) - 1.0) * 2.6), 0.0)
			if u:
				u.command_stop()
				made.append(u)
		_cam(center, z)
		await _wait(1.2)
		for u in made:
			u.take_damage(999999.0, null)
		await _wait(0.3)
		await _shot("leaves_z%d" % int(z))
		await _wait(3.0)


## The two Nature riders close (player and enemy colours), front three-quarter and side.
func _run_riders() -> void:
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", &"nature")
	main.set(&"enemy_kingdom", &"shadow")
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		print("GE ERROR: skirmish never started")
		return
	await _wait(1.0)
	_close_picker()
	_hud(false)
	_fog(false)
	var center := Vector3(12.0, 0.0, -33.0)
	for u in get_nodes_in_group(&"units"):
		if u is Node3D and (u as Node3D).global_position.distance_to(center) < 40.0:
			(u as Node3D).visible = false
	var ids := ["thornback_charger", "bramble_harrier"]
	for i in ids.size():
		for team in [0, 1]:
			var u := _unit(ids[i], team, center + Vector3(float(i) * 3.2 - 1.6, 0.0, float(team) * -3.0), 0.6 if team == 0 else -0.6)
			if u and u.has_method(&"command_hold"):
				u.call(&"command_hold")
	for z: float in [7.0, 12.0]:
		_cam(center + Vector3(0, 0, -1.5), z)
		await _wait(1.5)
		await _shot("riders_z%d" % int(z))
		await _shot_png("riders_z%d" % int(z))


func _run_scout() -> void:
	main = (load(SKIRMISH) as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	if not await _wait_level(300.0):
		return
	await _wait(1.0)
	_close_picker()
	_hud(false)
	_fog(false)
	for ps: String in String(args.get("pts", "0,0")).split(";"):
		var xz := ps.split(",")
		_cam(Vector3(float(xz[0]), 0.0, float(xz[1])), 35.0)
		await _wait(0.8)
		await _shot("scout_%s_%s" % [xz[0], xz[1]])


func _measure_triple(name: String, nodes: Array[Node3D], at: Vector3, zoom: float, mask_mat: Material) -> void:
	_cam(at, zoom)
	await _wait(1.5)
	await _shot_png(name + "_a")
	var geos: Array[GeometryInstance3D] = []
	var hid: Array[Node3D] = []
	for n in nodes:
		for g in n.find_children("*", "", true, false):
			if g is GPUParticles3D or g is CPUParticles3D or g is Light3D:
				if (g as Node3D).visible:
					(g as Node3D).visible = false
					hid.append(g)
			elif g is GeometryInstance3D:
				var gi := g as GeometryInstance3D
				if String(gi.name) in ["SelectionRing", "HPBar", "Chevrons"] or _see_through(gi):
					continue
				gi.set_meta(&"_gv_ov", gi.material_override)
				gi.material_override = mask_mat
				geos.append(gi)
	await _shot_png(name + "_m")
	for gi in geos:
		if is_instance_valid(gi):
			gi.material_override = gi.get_meta(&"_gv_ov") as Material
			gi.remove_meta(&"_gv_ov")
	for h in hid:
		if is_instance_valid(h):
			h.visible = true
	for n in nodes:
		n.visible = false
	await _shot_png(name + "_g")
	for n in nodes:
		if is_instance_valid(n):
			n.visible = true


## Glows, rings, blob shadows, decals: not body material (left out of the mask).
func _see_through(gi: GeometryInstance3D) -> bool:
	var mats: Array[Material] = []
	if gi.material_override:
		mats.append(gi.material_override)
	elif gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
		var mi := gi as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i)
			if m:
				mats.append(m)
	elif gi is MultiMeshInstance3D:
		return false
	if mats.is_empty():
		return gi is MeshInstance3D
	for m in mats:
		if m is BaseMaterial3D:
			var b := m as BaseMaterial3D
			if b.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED or b.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
				if b.blend_mode == BaseMaterial3D.BLEND_MODE_MIX and b.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
					return false
		elif m is ShaderMaterial and (m as ShaderMaterial).shader:
			var code := (m as ShaderMaterial).shader.code
			if code.find("blend_add") < 0 and code.find("unshaded") < 0 and code.find("ALPHA") < 0:
				return false
			if code.find("ALPHA_SCISSOR") >= 0 or code.find("#include") >= 0:
				return false
	return true


func _shot_png(name: String) -> void:
	Input.warp_mouse(Vector2(800, 450))
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(ProjectSettings.globalize_path("%s/%s/%s.png" % [OUT, tag, name]))
	print("png ", name)


# ---------------------------------------------------------------- maps

func _run_map(map_id: StringName) -> void:
	var cat := MapCatalog.load_default()
	var e := cat.entry(map_id)
	var ws := String(e.get("mode", "")) == "wave_strike"
	if ws:
		main = (load(WS_SCENE) as PackedScene).instantiate()
		if &"autopilot_player" in main:
			main.set(&"autopilot_player", true)
	else:
		main = cat.instantiate_level(map_id)
		main.set(&"player_kingdom", &"fire")
		main.set(&"enemy_kingdom", &"shadow")
	root.add_child(main)
	current_scene = main
	if ws:
		await _wait(40.0)
	elif not await _wait_level(300.0):
		print("GE ERROR: map never started ", map_id)
		return
	await _wait(2.0)
	_close_picker()
	_hud(true)
	var kp: Variant = main.call(&"keep_of", 0) if main.has_method(&"keep_of") else null
	if kp is Node3D:
		_cam((kp as Node3D).global_position + Vector3(0, 0, -6), 32.0)
		await _wait(0.5)
		await _shot("%s_ingame_z32" % map_id)
	_hud(false)
	_fog(false)
	await _wait(0.5)
	var sx := MapInfo.size_x
	var sz := MapInfo.size_z
	_overview(Vector3.ZERO, maxf(sx, sz) * 1.05, 62.0)
	await _wait(0.8)
	await _shot("%s_overview" % map_id)
	_cam(Vector3.ZERO, 45.0)
	await _wait(0.6)
	await _shot("%s_centre_z45" % map_id)
	if kp is Node3D:
		_cam((kp as Node3D).global_position * 0.5, 40.0)
		await _wait(0.6)
		await _shot("%s_mid_z40" % map_id)


# ---------------------------------------------------------------- missions

func _run_mission(path: String, name: String) -> void:
	main = (load(path) as PackedScene).instantiate()
	main.set(&"show_briefing", false)
	main.set(&"save_campaign_on_victory", false)
	main.set(&"cinematics_enabled", false)
	root.add_child(main)
	current_scene = main
	var t := 0
	while not (main.get(&"hero") != null and bool(main.get(&"match_started"))):
		await process_frame
		t += 1
		if t > 20000:
			print("GE ERROR: mission never started ", path)
			return
	await _wait(3.0)
	var hero := main.get(&"hero") as Node3D
	_hud(true)
	_cam(hero.global_position, 30.0)
	await _wait(0.6)
	await _shot("%s_ingame_z30" % name)
	_hud(false)
	_cam(hero.global_position, 14.0)
	await _wait(0.6)
	await _shot("%s_hero_z14" % name)
	_fog(false)
	_cam(hero.global_position + Vector3(0, 0, -12), 45.0)
	await _wait(0.6)
	await _shot("%s_nofog_z45" % name)
	_overview(Vector3.ZERO, maxf(MapInfo.size_x, MapInfo.size_z) * 1.0, 62.0)
	await _wait(0.8)
	await _shot("%s_overview" % name)

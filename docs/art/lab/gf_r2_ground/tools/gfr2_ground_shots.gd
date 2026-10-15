extends SceneTree
## G-F round-2 ground fixes (docs/art/gf_r2_ground.md, review items 5 / 14 / 15). WINDOWED only; pass the tier.
##   tools\godot_run.ps1 --path . -s docs/art/lab/gf_r2_ground/tools/gfr2_ground_shots.gd --resolution 1600x900 --quit-after 200000 '--' --gfx=high --mode=rings --tag=before
##   ... --mode=road --tag=before      (dirt road / lane close-ups, butterflies)
##   ... --mode=m00 --tag=before       (m00 start: logs every disc-like mesh added during the first 12 s)
## JPGs / PNGs in docs/art/lab/gf_r2_ground/<tag>/ (the folder has a .gdignore).

const OUT := "res://docs/art/lab/gf_r2_ground"
const SKIRMISH := "res://scenes/skirmish.tscn"
const BAD := ["Outside the map", "Not on walkable ground", "Blocked", "Too close to a crystal node", "Can't build on water",
		"Too close to a crossing", "Too close to a monster camp", "Can't build that"]

var args := {}
var tag := "x"
var main: Node
var _t0 := 0


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	tag = String(args.get("tag", "x"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [OUT, tag]))
	for i in 3:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1600, 900))
		for f in 4:
			await process_frame
	var mode := String(args.get("mode", "rings"))
	if mode == "rings":
		await _run_rings()
	elif mode == "road":
		await _run_road()
	elif mode == "m00":
		await _run_m00()
	print("GFR2 SHOTS DONE ", tag)
	quit(0)


func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _shot(name: String, png: bool = false) -> void:
	Input.warp_mouse(Vector2(800, 450))
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var p := ProjectSettings.globalize_path("%s/%s/%s.%s" % [OUT, tag, name, "png" if png else "jpg"])
	if png:
		img.save_png(p)
	else:
		img.save_jpg(p, 0.92)
	print("shot ", name)


func _cam(at: Vector3, zoom: float) -> void:
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


func _hud(on: bool) -> void:
	var hud: Variant = main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = on


func _fog(on: bool) -> void:
	var fog: Variant = main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", on)


func _close_picker() -> void:
	var hero: Variant = main.get(&"hero")
	if hero is Node:
		var sp := StrIntPath.of(hero as Node)
		if sp and not sp.is_locked():
			sp.choose(sp.default_pick())
	for n in root.find_children("*", "", true, false):
		if n is StrIntPanel:
			n.set(&"visible", false)


func _skirmish(pk: StringName, ek: StringName) -> bool:
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", pk)
	main.set(&"enemy_kingdom", ek)
	if &"time_limit_s" in main:
		main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 300000:
			return false
	await _wait(1.0)
	_close_picker()
	_hud(false)
	_fog(false)
	return true


func _unit(id: String, team: int, pos: Vector3) -> Unit:
	var u := Worker.make_unit(UnitType.find(id))
	if u == null:
		return null
	u.team = team as Unit.Team
	main.add_child(u)
	u.set_down(pos)
	u.command_stop()
	return u


func _place_building(id: String, team: int, want: Vector3) -> Building:
	var t := BuildingType.find(id)
	var bg: BuildGrid = main.get(&"build_grid")
	for r in [0.0, 2.0, 4.0, 6.0]:
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
	return null


# ---------------------------------------------------------------- item 5: ground rings

func _run_rings() -> void:
	if not await _skirmish(&"nature", &"ice"):
		print("GFR2 ERROR: skirmish never started")
		return
	var c := Vector3(-30.0, 0.0, 30.0)
	var spire := _place_building("nature_tower", 0, c)
	var sp := spire.global_position if spire else c
	# A few Nature units around the spire (a Bloomtender heals a hurt friend).
	var ids := ["bloomtender", "thornling", "wildwood_archer", "bramblehorn", "burr_slinger", "bloomtender"]
	for i in ids.size():
		var u := _unit(ids[i], 0, sp + Vector3(-4.0 + float(i) * 1.6, 0.0, 4.5))
		if u and i == 1:
			u.take_damage(u.max_hp * 0.5, null)
	# Titans (bare models, as the review's close-ups): a rooted Elder Treant and a War Mammoth.
	var t0 := sp + Vector3(0.0, 0.0, 22.0)
	var models := {}
	for pair: Array in [["elder_treant", Vector3(-6.0, 0, 0)], ["war_mammoth", Vector3(7.0, 0, 0)]]:
		var ps: PackedScene = load("res://art/units/titans/%s/%s.tscn" % [pair[0], pair[0]])
		if ps == null:
			continue
		var m := ps.instantiate() as Node3D
		main.add_child(m)
		m.global_position = t0 + (pair[1] as Vector3)
		if m.has_method(&"set_team_color"):
			m.call(&"set_team_color", Color(0.35, 0.7, 0.25))
		models[pair[0]] = m
	if models.has("elder_treant") and (models["elder_treant"] as Node).has_method(&"set_rooted"):
		(models["elder_treant"] as Node).call(&"set_rooted", true, true)
	await _wait(2.0)
	# A burst of frames on the spire (the pulse: catch it growing), then the titans.
	_cam(sp + Vector3(0, 0, 3.0), 30.0)
	await _wait(0.5)
	for i in 8:
		await _shot("spire_z30_%d" % i)
		await _wait(0.9)
	_cam(sp + Vector3(0, 0, 2.0), 16.0)
	for i in 8:
		await _shot("spire_z16_%d" % i)
		await _wait(0.9)
	_cam(t0, 22.0)
	await _wait(0.5)
	for i in 8:
		await _shot("titans_z22_%d" % i)
		await _wait(0.9)
	_cam(t0 + Vector3(7.0, 0, 0), 14.0)
	await _wait(0.5)
	await _shot("mammoth_z14")


# ---------------------------------------------------------------- item 14: road grass + butterflies

func _run_road() -> void:
	if not await _skirmish(&"fire", &"shadow"):
		print("GFR2 ERROR: skirmish never started")
		return
	await _wait(6.0)   # butterflies spread around the camera
	var spots := [["road_a", Vector3(-19.8, 0, 28.0)], ["road_b", Vector3(-38.0, 0, 30.0)],
			["road_c", Vector3(-10.0, 0, 10.0)]]
	for s: Array in spots:
		var at: Vector3 = s[1]
		_cam(at, 16.0)
		await _wait(3.0)
		await _shot("%s_z16" % s[0])
		_cam(at, 10.0)
		await _wait(1.0)
		await _shot("%s_z10" % s[0])


# ---------------------------------------------------------------- item 15: m00 grey disc

func _run_m00() -> void:
	main = (load("res://missions/mission_00.tscn") as PackedScene).instantiate()
	main.set(&"show_briefing", false)
	main.set(&"save_campaign_on_victory", false)
	main.set(&"cinematics_enabled", false)
	node_added.connect(_on_added)
	_t0 = Time.get_ticks_msec()
	root.add_child(main)
	current_scene = main
	var t := 0
	while not (main.get(&"hero") != null and bool(main.get(&"match_started"))):
		await process_frame
		t += 1
		if t > 20000:
			print("GFR2 ERROR: m00 never started")
			return
	var hero := main.get(&"hero") as Node3D
	_cam(hero.global_position, 30.0)
	for i in 6:
		await _shot("m00_z30_%d" % i)
		await _wait(0.5)
	_hud(false)
	_cam(hero.global_position, 14.0)
	await _wait(0.5)
	await _shot("m00_z14")


func _on_added(n: Node) -> void:
	if not (n is MeshInstance3D):
		return
	_check_disc.call_deferred(n)


func _check_disc(n: Node) -> void:
	if not is_instance_valid(n) or not n.is_inside_tree():
		return
	var mi := n as MeshInstance3D
	var m := mi.mesh
	var wide := false
	if m is CylinderMesh:
		wide = (m as CylinderMesh).top_radius >= 1.5
	elif m is PlaneMesh:
		wide = (m as PlaneMesh).size.x * absf(mi.global_transform.basis.get_scale().x) >= 3.0
	elif m is QuadMesh:
		wide = (m as QuadMesh).size.x >= 3.0
	if wide:
		print("GFR2 DISC t=%.2f %s mesh=%s parent=%s mat=%s" % [float(Time.get_ticks_msec() - _t0) / 1000.0,
				mi.get_path(), m.get_class(), mi.get_parent().name, mi.material_override])

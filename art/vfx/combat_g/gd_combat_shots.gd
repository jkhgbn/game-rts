extends Node3D
## G-D combat feedback lab (docs/art/gd_combat_feedback.md). WINDOWED only (pass the tier: headless / -s runs are Low).
## Shots: per-material melee hits, arrows, kingdom deaths, building damage stages + collapse, at zoom 10 and 30;
## frames become strips in docs/art/lab/gd_combat/<tag>/strip_<family>.jpg + one contact sheet <tag>/sheet.jpg.
##   tools\godot_run.ps1 --path . res://art/vfx/combat_g/gd_combat_shots.tscn --fixed-fps 60 --quit-after 40000 '--' --gfx=high --shots after
##   ... '--' --gfx=high --shots before --off          (same stage without the G-D layer)
## Clash (fps, 100 v 100 of the four kingdoms, zoom 35, vsync off, no --fixed-fps):
##   tools\godot_run.ps1 --path . res://art/vfx/combat_g/gd_combat_shots.tscn --quit-after 8000 '--' --gfx=ultra --clash ultra_after
## prints "GD CLASH <tag> avg=.. low1=.. min=.." and writes docs/art/lab/gd_combat/clash_<tag>.json (+ a frame).

const OUT := "res://docs/art/lab/gd_combat"
const PITCH := 55.0
const THUMB := Vector2i(480, 270)
const ARENA_STEP := 45.0

var _tag := ""
var _clash := ""
var _cam: Camera3D
var _strips: Dictionary = {}     # family -> Array of Array[Image] (rows)
var _arena := 0
var _units: Array[Node] = []
var _frame_us: Array[int] = []
var _measuring := false
var _last_us := 0
var _keys: Array[String] = []    # full-size key frames saved as PNG (max 4)
var _crop := Rect2(0, 0, 1, 1)   # part of the frame kept in the strips (normalised): close-ups crop round the action
var _only := ""                  # -- --only <family prefix>: one block (look-dev)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--shots")
	if i >= 0:
		_tag = args[i + 1] if i + 1 < args.size() else "x"
	i = args.find("--clash")
	if i >= 0:
		_clash = args[i + 1] if i + 1 < args.size() else "x"
	CombatFxG.force_off = "--off" in args
	i = args.find("--only")
	if i >= 0 and i + 1 < args.size():
		_only = args[i + 1]
	_build_stage()
	GameSettings.apply_graphics(get_tree())
	if _clash != "":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		_run_clash.call_deferred()
	elif _tag != "":
		_run_shots.call_deferred()
	else:
		print("gd_combat_shots: pass -- --shots <tag> or -- --clash <tag>")


func _process(_delta: float) -> void:
	if _measuring:
		var now := Time.get_ticks_usec()
		if _last_us > 0:
			_frame_us.append(now - _last_us)
		_last_us = now


# ---------------------------------------------------------------- stage

func _build_stage() -> void:
	var rig := LightingRig.new()
	rig.preset_id = &"warm"
	add_child(rig)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3200.0, 200.0)
	ground.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://art/shaders/painted.gdshader") as Shader
	mat.set_shader_parameter(&"base_color", Color(0.32, 0.36, 0.2, 1))
	mat.set_shader_parameter(&"noise_tex", load("res://art/shaders/paint_noise.tres"))
	mat.set_shader_parameter(&"noise_scale_a", 0.15)
	mat.set_shader_parameter(&"noise_scale_b", 0.04)
	mat.set_shader_parameter(&"rim_strength", 0.0)
	ground.material_override = mat
	ground.position = Vector3(200.0, 0.0, 0.0)
	add_child(ground)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3(200.0, -0.5, 0.0)
	floor_body.add_child(shape)
	add_child(floor_body)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	add_child(_cam)
	_cam.make_current()
	var v := CombatVfx.new()
	v.name = "CombatVfx"
	add_child(v)


func _look(at: Vector3, zoom: float) -> void:
	var p := deg_to_rad(PITCH)
	_cam.position = at + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _next_arena() -> Vector3:
	var c := Vector3(-700.0 + ARENA_STEP * float(_arena), 0.0, 0.0)
	_arena += 1
	return c


func _clear_units() -> void:
	for u in _units:
		if is_instance_valid(u):
			u.queue_free()
	_units.clear()


func _unit(id: String, team: int, pos: Vector3, hp := 100000.0) -> Unit:
	var u := Worker.make_unit(UnitType.find(id))
	u.team = team as Unit.Team
	add_child(u)
	u.global_position = pos
	u.max_hp = hp
	u.hp = hp
	_units.append(u)
	return u


func _building(id: StringName, team: int, pos: Vector3) -> Building:
	var t := BuildingType.find(id)
	if t == null:
		print("no building type ", id)
		return null
	var b := BuildGrid.create_building(t)
	b.team = team as Unit.Team
	add_child(b)
	b.global_position = pos
	_units.append(b)
	return b


# ---------------------------------------------------------------- shots

func _run_shots() -> void:
	await _wait(1.0)
	var crop10 := Rect2(0.3, 0.12, 0.4, 0.4)    # zoom 10: the 6 m round the fight
	var crop30 := Rect2(0.25, 0.1, 0.5, 0.5)
	if _on("hits"):
		_crop = crop10
		await _hits(10.0, "hits_z10")
		_crop = crop30
		await _hits(30.0, "hits_z30")
	if _on("arrows"):
		_crop = Rect2(0.25, 0.1, 0.5, 0.5)
		await _arrows(10.0, "arrows_z10")
	if _on("deaths"):
		_crop = Rect2(0.25, 0.1, 0.5, 0.5)
		await _deaths(10.0, "deaths_z10")
		_crop = crop30
		await _deaths(30.0, "deaths_z30")
	if _on("buildings"):
		_crop = Rect2(0.15, 0.0, 0.7, 0.7)
		await _buildings(30.0, "buildings_z30")
		_crop = Rect2(0.0, 0.0, 1.0, 1.0)
		await _buildings(14.0, "buildings_z14")
	for fam: String in _strips:
		_strip(fam)
	_sheet()
	print("GD SHOTS DONE ", _tag)
	get_tree().quit()


## One row per target material: two Flame Guards strike two targets; frames on the blow, +0.08, +0.2, +0.45 s.
func _hits(zoom: float, fam: String) -> void:
	var rows: Array = [["rimeshield", "steel"], ["ember_archer", "flesh"], ["shade", "bone"], ["thornling", "wood"],
			["rimeling", "ice"], ["ruin_warden", "stone"]]
	for row: Array in rows:
		var c := _next_arena()
		var a: Array[Unit] = []
		var b: Array[Unit] = []
		for i in 3:
			a.append(_unit("flame_guard", Unit.Team.PLAYER, c + Vector3(-0.8, 0, -1.4 + i * 1.4)))
			b.append(_unit(row[0], Unit.Team.ENEMY, c + Vector3(0.8, 0, -1.4 + i * 1.4)))
		for i in 3:
			a[i].command_attack(b[i])
			b[i].command_attack(a[i])
		_look(c, zoom)
		await _wait(1.2)
		for i in 3:
			a[i].attack_landed.emit(b[i], 10.0)
		var imgs: Array[Image] = []
		await _wait(0.03)
		imgs.append(await _grab())
		await _wait(0.08)
		imgs.append(await _grab())
		await _wait(0.15)
		imgs.append(await _grab())
		await _wait(0.3)
		imgs.append(await _grab())
		_add(fam, imgs, "%s %s" % [fam, row[1]])
		_clear_units()
		await _wait(0.3)


func _arrows(zoom: float, fam: String) -> void:
	for pair: Array in [["ember_archer", "rimeshield"], ["nightbolt", "thornling"], ["frostbow", "shade"]]:
		var c := _next_arena()
		var arch: Array[Unit] = []
		var tgt: Array[Unit] = []
		for i in 3:
			arch.append(_unit(pair[0], Unit.Team.PLAYER, c + Vector3(-6.0, 0, -2.0 + i * 2.0)))
			tgt.append(_unit(pair[1], Unit.Team.ENEMY, c + Vector3(1.5, 0, -2.0 + i * 2.0)))
		for i in 3:
			arch[i].command_attack(tgt[i])
			tgt[i].command_hold()
			tgt[i].attack_damage = 0.0
		_look(c + Vector3(1.0, 0, 0), zoom)
		var imgs: Array[Image] = []
		await _wait(1.6)
		for t: float in [0.0, 0.12, 0.25, 0.4]:
			await _wait(t)
			imgs.append(await _grab())
		_add(fam, imgs, "%s %s" % [fam, pair[0]])
		_clear_units()
		await _wait(0.3)


## One row per kingdom (3 units die at once) + a hero row: +0.12, +0.5, +1.0, +4.0 s.
func _deaths(zoom: float, fam: String) -> void:
	var rows: Array = [["flame_guard", "fire"], ["shade", "shadow"], ["rimeshield", "ice"], ["thornling", "nature"],
			["greymane_direwolf", "neutral"]]
	for row: Array in rows:
		var c := _next_arena()
		var v: Array[Unit] = []
		for i in 3:
			var u := _unit(row[0], Unit.Team.PLAYER if i != 1 else Unit.Team.ENEMY, c + Vector3(-2.2 + i * 2.2, 0, 0), 100.0)
			u.command_hold()
			u.attack_damage = 0.0
			u.aggro_range = 0.0
			v.append(u)
		_look(c, zoom)
		await _wait(0.8)
		for u in v:
			u.take_damage(99999.0, null)
		var imgs: Array[Image] = []
		for t: float in [0.12, 0.38, 0.5, 3.0]:
			await _wait(t)
			imgs.append(await _grab())
		if fam == "deaths_z10" and row[1] == "ice":
			_key(imgs[1], "key_death_ice_z10")
		_add(fam, imgs, "%s %s" % [fam, row[1]])
		_clear_units()
		await _wait(0.3)


## Per building: hit to 60 % (crack), 30 % (crack, fire), then destroyed: frames +0.3 s after 60 %, 2 s at 30 %,
## collapse +0.4 / +1.6 / +4 s, rubble +12 s.
func _buildings(zoom: float, fam: String) -> void:
	for id: StringName in [&"fire_barracks", &"shadow_tower", &"nature_barracks", &"ice_tower"]:
		var c := _next_arena()
		var b := _building(id, Unit.Team.ENEMY, c)
		if b == null:
			continue
		var hitter := _unit("flame_guard", Unit.Team.PLAYER, c + Vector3(-4.0, 0, 3.0))
		hitter.command_hold()
		hitter.attack_damage = 0.0
		_look(c, zoom)
		await _wait(1.0)
		var imgs: Array[Image] = []
		b.take_damage(b.max_hp * 0.42, hitter)
		await _wait(0.3)
		imgs.append(await _grab())
		b.take_damage(b.max_hp * 0.3, hitter)
		await _wait(2.0)
		imgs.append(await _grab())
		b.take_damage(b.max_hp, hitter)
		await _wait(0.4)
		imgs.append(await _grab())
		if zoom > 20.0 and id == &"fire_barracks":
			_key(imgs[2], "key_collapse_z30")
		await _wait(1.2)
		imgs.append(await _grab())
		await _wait(2.4)
		imgs.append(await _grab())
		await _wait(8.0)
		imgs.append(await _grab())
		_add(fam, imgs, "%s %s" % [fam, id])
		_clear_units()
		await _wait(0.3)


func _on(block: String) -> bool:
	return _only == "" or _only == block


func _add(fam: String, imgs: Array[Image], label: String) -> void:
	if not _strips.has(fam):
		_strips[fam] = []
	(_strips[fam] as Array).append(imgs)
	print("frames ", label, " fps=", Engine.get_frames_per_second())


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	if _crop.size != Vector2.ONE:
		var s := Vector2(img.get_size())
		img = img.get_region(Rect2i(Vector2i(_crop.position * s), Vector2i(_crop.size * s)))
	return img


func _key(full: Image, name: String) -> void:
	if _keys.size() >= 4 or _tag == "":
		return
	_keys.append(name)
	var dir := ProjectSettings.globalize_path("%s/%s" % [OUT, _tag])
	DirAccess.make_dir_recursive_absolute(dir)
	var img := full.duplicate() as Image
	img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	img.save_png("%s/%s.png" % [dir, name])


## A strip: rows of thumbnails (one row per vignette), saved as JPG.
func _strip(fam: String) -> void:
	var rows: Array = _strips[fam]
	var cols := 0
	for r: Array in rows:
		cols = maxi(cols, r.size())
	var out := Image.create(cols * (THUMB.x + 6) + 6, rows.size() * (THUMB.y + 6) + 6, false, Image.FORMAT_RGB8)
	out.fill(Color(0.07, 0.07, 0.08))
	for ri in rows.size():
		var r: Array = rows[ri]
		for ci in r.size():
			var t := (r[ci] as Image).duplicate() as Image
			t.resize(THUMB.x, THUMB.y, Image.INTERPOLATE_LANCZOS)
			out.blit_rect(t, Rect2i(Vector2i.ZERO, THUMB), Vector2i(6 + ci * (THUMB.x + 6), 6 + ri * (THUMB.y + 6)))
	var dir := ProjectSettings.globalize_path("%s/%s" % [OUT, _tag])
	DirAccess.make_dir_recursive_absolute(dir)
	out.save_jpg("%s/strip_%s.jpg" % [dir, fam], 0.85)
	print("saved strip ", fam)


## One contact sheet of every strip (half-size thumbnails), the file that goes to git.
func _sheet() -> void:
	var tw := THUMB.x / 2
	var th := THUMB.y / 2
	var cols := 6
	var nrows := 0
	for fam: String in _strips:
		nrows += (_strips[fam] as Array).size()
	var out := Image.create(cols * (tw + 4) + 4, nrows * (th + 4) + 4, false, Image.FORMAT_RGB8)
	out.fill(Color(0.07, 0.07, 0.08))
	var y := 4
	for fam: String in _strips:
		for r: Array in _strips[fam]:
			for ci in mini(r.size(), cols):
				var t := (r[ci] as Image).duplicate() as Image
				t.resize(tw, th, Image.INTERPOLATE_LANCZOS)
				out.blit_rect(t, Rect2i(0, 0, tw, th), Vector2i(4 + ci * (tw + 4), y))
			y += th + 4
	var dir := ProjectSettings.globalize_path("%s/%s" % [OUT, _tag])
	out.save_jpg("%s/sheet.jpg" % dir, 0.8)
	print("saved sheet ", dir, "/sheet.jpg")


# ---------------------------------------------------------------- clash (fps)

func _run_clash() -> void:
	var c := _next_arena()
	var ids_a := ["flame_guard", "rimeshield", "ember_archer", "shardcaster", "cinder_hand"]
	var ids_b := ["shade", "thornling", "nightbolt", "wildwood_archer", "gloom_thrall"]
	var left: Array[Unit] = []
	var right: Array[Unit] = []
	for i in 100:
		var row := i / 10
		var col := i % 10
		var kind := row % 5
		var ranged := kind == 2 or kind == 3
		var gap := 4.5 if ranged else 0.75
		var z := -13.5 + col * 3.0
		var x := -18.0 + row * 4.0
		var la := _unit(ids_a[kind], Unit.Team.PLAYER, c + Vector3(x, 0, z - gap), 0.0)
		var rb := _unit(ids_b[kind], Unit.Team.ENEMY, c + Vector3(x, 0, z + gap), 0.0)
		for u: Unit in [la, rb]:
			var t := UnitType.find(u.unit_type.id) if u.unit_type else null
			var hp := (t.max_hp if t else 200.0) * 4.0
			u.max_hp = hp
			u.hp = hp
		left.append(la)
		right.append(rb)
	for i in 100:
		left[i].command_attack(right[i])
		right[i].command_attack(left[i])
	_look(c + Vector3(0, 0, 0), 35.0)
	await _wait(2.5)
	_frame_us.clear()
	_last_us = 0
	_measuring = true
	var shot_done := false
	var t0 := Time.get_ticks_msec()
	var kills := 0
	while Time.get_ticks_msec() - t0 < 7000:
		await get_tree().process_frame
		# A steady stream of deaths (6 per second) so the measure covers death effects too.
		if kills < int(float(Time.get_ticks_msec() - t0) / 1000.0 * 6.0):
			var pool := left if kills % 2 == 0 else right
			for u in pool:
				if is_instance_valid(u) and u.is_alive():
					u.take_damage(999999.0, null)
					break
			kills += 1
		if not shot_done and Time.get_ticks_msec() - t0 > 3000:
			shot_done = true
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
			img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
			img.save_jpg(ProjectSettings.globalize_path("%s/clash_%s.jpg" % [OUT, _clash]), 0.85)
	_measuring = false
	var times: Array[int] = _frame_us.duplicate()
	times.sort()
	var total := 0
	for t in times:
		total += t
	var n := maxi(times.size(), 1)
	var avg := 1000000.0 * float(n) / maxf(float(total), 1.0)
	var worst := times[-1] if not times.is_empty() else 1
	var p99: int = times[clampi(int(float(n) * 0.99), 0, n - 1)] if not times.is_empty() else 1
	var vfx := get_node_or_null(^"CombatVfx")
	var g_stats: Dictionary = {}
	if vfx and vfx.get(&"_g") != null:
		g_stats = (vfx.get(&"_g") as CombatFxG).stats()
	var res := {"tag": _clash, "tier": GameSettings.GFX_NAMES[GameSettings.effective_graphics_quality()],
			"g_layer": not CombatFxG.force_off, "frames": times.size(), "avg_fps": snappedf(avg, 0.1),
			"low1_fps": snappedf(1000000.0 / float(p99), 0.1), "min_fps": snappedf(1000000.0 / float(worst), 0.1),
			"kills": kills, "window": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y],
			"combat_vfx": vfx.call(&"stats") if vfx else {}, "combat_fx_g": g_stats}
	var f := FileAccess.open(ProjectSettings.globalize_path("%s/clash_%s.json" % [OUT, _clash]), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(res, "  "))
		f.close()
	print("GD CLASH %s avg=%.1f low1=%.1f min=%.1f frames=%d tier=%s g=%s %s" % [_clash, avg, res["low1_fps"],
			res["min_fps"], times.size(), res["tier"], res["g_layer"], g_stats])
	get_tree().quit()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

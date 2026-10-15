extends Node3D
## G-B spell VFX lab (docs/art/gb_spell_vfx.md). WINDOWED only (pass the tier: headless / -s runs are Low).
## Every wizard F / Q / E and every caster spell is cast on a group of dummies; frames at cast / impact / linger
## become one contact sheet per family: docs/art/lab/gb_vfx/<tag>/sheet_<family>.jpg.
##   tools\godot_run.ps1 --path . res://art/vfx/spells_g/gb_vfx_shots.tscn --fixed-fps 60 --quit-after 30000 '--' --gfx=high --shots after
## Storm (fps while 20 spells land on a 30-unit clump in 2.5 s; no --fixed-fps, vsync off):
##   tools\godot_run.ps1 --path . res://art/vfx/spells_g/gb_vfx_shots.tscn --quit-after 6000 '--' --gfx=ultra --storm ultra
## Writes docs/art/lab/gb_vfx/storm_<tag>.json (+ a frame) and prints "GB STORM <tag> avg=.. low1=.. min=..".

const OUT := "res://docs/art/lab/gb_vfx"
const PITCH := 55.0
const THUMB := Vector2i(400, 225)
const ARENA_STEP := 60.0

var _tag := ""
var _storm := ""
var _zoom := 0.0          # -- --zoom N: closer camera for look-dev (0 = the RTS distance of each vignette)
var _only := ""           # -- --only fire|shadow|ice|nature|casters: one block
var _cam: Camera3D
var _sheets: Dictionary = {}     # family -> Array of [label, Array[Image]]
var _arena := 0
var _units: Array[Node] = []
var _frame_us: Array[int] = []
var _measuring := false
var _last_us := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--shots")
	if i >= 0:
		_tag = args[i + 1] if i + 1 < args.size() else "x"
	i = args.find("--zoom")
	if i >= 0 and i + 1 < args.size():
		_zoom = float(args[i + 1])
	i = args.find("--only")
	if i >= 0 and i + 1 < args.size():
		_only = args[i + 1]
	i = args.find("--storm")
	if i >= 0:
		_storm = args[i + 1] if i + 1 < args.size() else "x"
	CasterKit.force_enabled = true
	SpellFxG.force_off = "--no-g" in args   # before shots: same tier and lighting, no G-B layer
	_build_stage()
	GameSettings.apply_graphics(get_tree())
	if "--compose" in args:
		_compose.call_deferred()
	elif "--probe" in args:
		_run_probe.call_deferred()
	elif _storm != "":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		_run_storm.call_deferred()
	elif _tag != "":
		_run_shots.call_deferred()
	else:
		print("gb_vfx_shots: pass -- --shots <tag> or -- --storm <tag>")


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
	pm.size = Vector2(1400.0, 160.0)
	ground.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://art/shaders/painted.gdshader") as Shader
	mat.set_shader_parameter(&"base_color", Color(0.32, 0.36, 0.2, 1))
	mat.set_shader_parameter(&"noise_tex", load("res://art/shaders/paint_noise.tres"))
	mat.set_shader_parameter(&"noise_scale_a", 0.15)
	mat.set_shader_parameter(&"noise_scale_b", 0.04)
	mat.set_shader_parameter(&"rim_strength", 0.0)
	ground.material_override = mat
	ground.position = Vector3(-200.0, 0.0, 0.0)
	add_child(ground)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1400.0, 1.0, 160.0)
	shape.shape = box
	shape.position = Vector3(-200.0, -0.5, 0.0)
	floor_body.add_child(shape)
	add_child(floor_body)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 400.0
	add_child(_cam)
	_cam.make_current()
	for hub: Array in [[SpellVfx, "SpellVfx"], [IceVfx, "IceVfx"], [NatureVfx, "NatureVfx"], [CombatVfx, "CombatVfx"],
			[UnitVfx, "UnitVfx"]]:
		var n: Node = (hub[0] as GDScript).new()
		n.name = hub[1]
		add_child(n)


func _look(at: Vector3, zoom: float) -> void:
	if _zoom > 0.0 and _storm == "":
		zoom = _zoom
		at += Vector3(1.5, 0.0, -1.2)   # closer on the target clump
	var p := deg_to_rad(PITCH)
	_cam.position = at + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _next_arena() -> Vector3:
	var c := Vector3(-560.0 + ARENA_STEP * float(_arena), 0.0, 0.0)
	_arena += 1
	return c


func _clear_units() -> void:
	for u in _units:
		if is_instance_valid(u):
			u.queue_free()
	_units.clear()


func _unit(id: String, team: int, pos: Vector3) -> Unit:
	var t := UnitType.find(id)
	var u: Unit = t.create_unit() if t else Unit.new()
	u.team = team as Unit.Team
	add_child(u)
	u.global_position = pos
	_tame(u)
	_units.append(u)
	return u


func _tame(u: Unit) -> void:
	u.aggro_range = 0.0
	u.attack_damage = 0.0
	u.max_hp = 100000.0
	u.hp = 100000.0
	u.command_hold()


func _wizard(w: Wizard, pos: Vector3) -> Wizard:
	w.team = Unit.Team.PLAYER
	add_child(w)
	w.global_position = pos
	_tame(w)
	if &"ai_auto_cast" in w:
		w.set(&"ai_auto_cast", false)
	w.add_xp(1200)
	w.spell_points = 6
	for c: StringName in w.spell_ids():
		if w.spell_rank(c) == 0:
			var r := w.learn_spell(c)
			if r != "":
				print("learn ", c, ": ", r)
	_units.append(w)
	return w


func _caster(id: String, team: int, pos: Vector3) -> Unit:
	var u := _unit(id, team, pos)
	var ab := CasterKit.ability_of(u)
	if ab:
		for s in ab.spell_ids():
			ab.set_autocast(s, false)
	return u


## A clump of 6 enemy dummies around `c`.
func _foes(c: Vector3, n: int = 6, id: String = "shade") -> Array[Unit]:
	var out: Array[Unit] = []
	for k in n:
		var a := TAU * float(k) / float(n) + 0.3
		var r := 0.0 if k == 0 else 1.5 + 0.3 * float(k % 2)
		out.append(_unit(id, Unit.Team.ENEMY, c + Vector3(cos(a) * r, 0.0, sin(a) * r)))
	return out


func _allies(c: Vector3, n: int = 4, id: String = "flame_guard") -> Array[Unit]:
	var out: Array[Unit] = []
	for k in n:
		var a := TAU * float(k) / float(n)
		out.append(_unit(id, Unit.Team.PLAYER, c + Vector3(cos(a) * 1.4, 0.0, sin(a) * 1.4)))
	return out


# ---------------------------------------------------------------- casting

func _wcast(w: Wizard, id: StringName, target: Variant) -> void:
	w.mana = 900.0
	var sc := w.get_node_or_null(^"SpellCaster")
	if sc:
		var cds: Variant = sc.get(&"_cooldown_left")
		if cds is Dictionary:
			(cds as Dictionary)[id] = 0.0
	var r: String = w.command_cast(id, target)
	if r != "":
		print("cast ", id, " refused: ", r)


func _ccast(u: Unit, id: StringName, target: Variant) -> void:
	var ab := CasterKit.ability_of(u)
	if ab == null:
		print("no caster ability on ", u.name)
		return
	ab.mana = 200.0
	ab.set(&"_gcd", 0.0)
	var cd: Variant = ab.get(&"_cd")
	if cd is Dictionary:
		(cd as Dictionary).clear()
	var r := ab.cast(id, target)
	if r != "":
		print("caster cast ", id, " refused: ", r)


func _uvfx(id: StringName, at: Variant, target: Variant = null) -> void:
	var v := get_tree().get_first_node_in_group(&"unit_vfx")
	if v:
		v.call(&"play", id, at, target)


func _projectile_of(w: Node) -> Node3D:
	for c in get_children():
		if c is Projectile and (c as Projectile).source == w and c.is_processing():
			return c
	return null


# ---------------------------------------------------------------- shots

func _run_shots() -> void:
	await _wait(1.0)
	if _only in ["", "fire"]:
		await _fire()
	if _only in ["", "shadow"]:
		await _shadow()
	if _only in ["", "ice"]:
		await _ice()
	if _only in ["", "nature"]:
		await _nature()
	if _only in ["", "casters"]:
		await _caster_fire()
		await _caster_ice()
		await _caster_nature()
		await _caster_shadow()
	for fam: String in _sheets:
		await _sheet(fam)
	print("GB SHOTS DONE ", _tag)
	get_tree().quit()


func _fire() -> void:
	var c := _next_arena()
	var w := _wizard(Wizard.new(), c + Vector3(-5.0, 0, 3.0))
	var foes := _foes(c + Vector3(1.5, 0, -1.5))
	_allies(c + Vector3(-5.0, 0, 5.5), 3)
	_look(c + Vector3(-1.5, 0, 1.0), 19.0)
	await _wait(0.6)
	_wcast(w, &"fireball", foes[0].global_position)
	await _three_p("wizard_fire", "Fireball (F)", w, 0.3, 0.9)
	await _wait(2.5)
	_wcast(w, &"ember_step", c + Vector3(-1.0, 0, 0.5))
	await _three("wizard_fire", "Ember Step (Q)", 0.05, 0.25, 1.2)
	await _wait(3.5)
	w.global_position = c + Vector3(-1.0, 0, 0.0)
	await _wait(0.2)
	_wcast(w, &"kindle", null)
	await _three("wizard_fire", "Kindle (E)", 0.12, 0.35, 1.0)
	await _wait(1.5)
	_clear_units()


func _shadow() -> void:
	var c := _next_arena()
	var w := _wizard(ShadowWizard.new(), c + Vector3(-5.0, 0, 3.0))
	var foes := _foes(c + Vector3(1.5, 0, -1.5))
	_look(c + Vector3(-1.5, 0, 1.0), 19.0)
	await _wait(0.6)
	_wcast(w, &"shadow_lance", foes[0])
	await _three_p("wizard_shadow", "Shadow Lance (F)", w, 0.05, 0.6)
	await _wait(1.5)
	_wcast(w, &"soul_siphon", foes[0].global_position)
	await _three("wizard_shadow", "Soul Siphon (Q)", 0.15, 0.9, 1.2)
	await _wait(3.0)
	_wcast(w, &"umbral_shroud", null)
	await _three("wizard_shadow", "Umbral Shroud (E)", 0.1, 0.5, 1.2)
	await _wait(1.0)
	_clear_units()


func _ice() -> void:
	var c := _next_arena()
	var w := _wizard(IceWizard.new(), c + Vector3(-5.0, 0, 3.0))
	var foes := _foes(c + Vector3(1.5, 0, -1.5))
	_allies(c + Vector3(-5.0, 0, 5.5), 3, "rimeshield")
	_look(c + Vector3(-1.5, 0, 1.0), 19.0)
	await _wait(0.6)
	_wcast(w, &"rime_bolt", foes[0])
	await _three_p("wizard_ice", "Rime Bolt (F)", w, 0.05, 0.7)
	await _wait(1.5)
	_wcast(w, &"flash_freeze", foes[0].global_position)
	await _three("wizard_ice", "Flash Freeze (Q)", 0.1, 0.4, 1.2)
	await _wait(2.5)
	_wcast(w, &"rime_aegis", null)
	await _three("wizard_ice", "Rime Aegis (E)", 0.12, 0.5, 1.0)
	await _wait(1.0)
	_clear_units()


func _nature() -> void:
	var c := _next_arena()
	var w := _wizard(NatureWizard.new(), c + Vector3(-5.0, 0, 3.0))
	var foes := _foes(c + Vector3(1.5, 0, -1.5))
	var allies := _allies(c + Vector3(-4.0, 0, 5.0), 4, "rimeshield")
	for a in allies:
		a.hp = a.max_hp * 0.5
	_look(c + Vector3(-1.5, 0, 1.0), 19.0)
	await _wait(0.6)
	_wcast(w, &"thornburst", foes[0].global_position)
	await _three("wizard_nature", "Thornburst (F)", 0.07, 0.25, 0.8)
	await _wait(2.0)
	_wcast(w, &"wild_bloom", allies[0].global_position + Vector3(0, 0, -1.0))
	await _three("wizard_nature", "Wild Bloom (Q)", 0.2, 0.6, 1.5)
	await _wait(2.0)
	_wcast(w, &"call_the_thicket", c + Vector3(-1.0, 0, -0.5))
	await _three("wizard_nature", "Call the Thicket (E)", 0.15, 0.6, 1.5)
	await _wait(1.0)
	_clear_units()


func _caster_fire() -> void:
	var c := _next_arena()
	var kw := _caster("kilnwarden", Unit.Team.PLAYER, c + Vector3(-5.0, 0, 3.0))
	var foes := _foes(c + Vector3(1.5, 0, -1.5))
	var enemy_caster := _caster("rimecarver", Unit.Team.ENEMY, c + Vector3(-1.5, 0, -2.5))
	_look(c + Vector3(-1.5, 0, 1.0), 19.0)
	await _wait(1.0)
	_ccast(kw, &"slag_rain", foes[0].global_position)
	await _three("caster_fire", "Slag Rain (Kilnwarden Z)", 0.6, 0.45, 1.4)
	await _wait(1.5)
	var ab := CasterKit.ability_of(enemy_caster)
	if ab:
		ab.mana = 200.0
	_ccast(kw, &"mana_scald", enemy_caster)
	await _three("caster_fire", "Mana Scald (V)", 0.5, 0.12, 0.5)
	await _wait(1.0)
	_uvfx(&"stoke", foes[2], kw)
	await _three("caster_fire", "Stoke (passive)", 0.2, 0.3, 0.3)
	await _wait(1.0)
	_clear_units()


func _caster_ice() -> void:
	var c := _next_arena()
	var rc := _caster("rimecarver", Unit.Team.PLAYER, c + Vector3(-5.0, 0, 3.0))
	_foes(c + Vector3(2.5, 0, -2.5), 4)
	_look(c + Vector3(-1.5, 0, 1.0), 19.0)
	await _wait(1.0)
	var wall_at := c + Vector3(-1.0, 0, -0.5)
	_ccast(rc, &"rime_bulwark", wall_at)
	await _three("caster_ice", "Rime Bulwark (Rimecarver Z)", 0.55, 0.35, 1.2)
	await _wait(0.5)
	_uvfx(&"rime_bulwark_shatter", wall_at)
	await _three("caster_ice", "Bulwark shatter", 0.04, 0.2, 0.6)
	await _wait(1.0)
	_ccast(rc, &"scrying_rune", c + Vector3(1.5, 0, -1.0))
	await _three("caster_ice", "Scrying Rune (V)", 0.6, 0.6, 1.0)
	await _wait(1.0)
	_clear_units()


func _caster_nature() -> void:
	var c := _next_arena()
	var bs := _caster("bramblesage", Unit.Team.PLAYER, c + Vector3(-5.0, 0, 3.0))
	var foes := _foes(c + Vector3(1.5, 0, -1.5), 5, "flame_guard")
	_look(c + Vector3(-1.5, 0, 1.0), 19.0)
	await _wait(1.0)
	_ccast(bs, &"snagroot", foes[1])
	await _three("caster_nature", "Snagroot (Bramblesage Z)", 0.55, 0.3, 0.8)
	await _wait(1.5)
	_ccast(bs, &"pollen_haze", foes[0].global_position)
	await _three("caster_nature", "Pollen Haze (V)", 0.6, 0.8, 1.5)
	await _wait(1.0)
	_uvfx(&"seedcloak", bs)
	await _three("caster_nature", "Seedcloak (passive)", 0.1, 0.4, 1.0)
	await _wait(1.0)
	_clear_units()


func _caster_shadow() -> void:
	var c := _next_arena()
	var dc := _caster("gloom_deacon", Unit.Team.PLAYER, c + Vector3(-5.0, 0, 3.0))
	var allies := _allies(c + Vector3(-2.0, 0, 1.0), 3, "flame_guard")
	_foes(c + Vector3(1.0, 0, -1.5), 4)
	allies[0].hp = allies[0].max_hp * 0.4
	var far := _allies(c + Vector3(6.0, 0, -6.0), 4, "flame_guard")
	_look(c + Vector3(-1.0, 0, 0.0), 21.0)
	await _wait(1.0)
	_ccast(dc, &"blood_tithe", allies[0])
	await _three("caster_shadow", "Blood Tithe (Gloom Deacon Z)", 0.6, 0.5, 0.8)
	CasterKit.ability_of(dc).stop_channel()
	await _wait(1.0)
	_ccast(dc, &"umbral_passage", far[0].global_position)
	await _three("caster_shadow", "Umbral Passage (V)", 0.6, 1.0, 1.4)
	await _wait(1.0)
	_uvfx(&"vigil", allies[2], dc)
	await _three("caster_shadow", "Vigil (passive)", 0.1, 0.25, 0.35)
	await _wait(1.0)
	_clear_units()


## Three frames: `a` s after the cast, then `b` and `c` s later.
func _three(family: String, label: String, a: float, b: float, c: float) -> void:
	var imgs: Array[Image] = []
	await _wait(a)
	imgs.append(await _grab())
	await _wait(b)
	imgs.append(await _grab())
	await _wait(c)
	imgs.append(await _grab())
	_add(family, label, imgs)


## Projectile spells: in flight (0.15 s), just after the hit, then `linger` s later.
func _three_p(family: String, label: String, w: Node, after_hit: float, linger: float) -> void:
	var imgs: Array[Image] = []
	await _wait(0.15)
	imgs.append(await _grab())
	var p := _projectile_of(w)
	var guard := 0
	while p != null and is_instance_valid(p) and p.is_processing() and guard < 240:
		await get_tree().process_frame
		guard += 1
	await _wait(after_hit)
	imgs.append(await _grab())
	await _wait(linger)
	imgs.append(await _grab())
	_add(family, label, imgs)


func _add(family: String, label: String, imgs: Array[Image]) -> void:
	if not _sheets.has(family):
		_sheets[family] = []
	(_sheets[family] as Array).append([label, imgs])
	print("frames ", family, " / ", label, " fps=", Engine.get_frames_per_second())


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(THUMB.x, THUMB.y, Image.INTERPOLATE_LANCZOS)
	return img


## One contact sheet: a row per spell (label, cast / impact / linger thumbnails), shot from the viewport.
func _sheet(family: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var box := VBoxContainer.new()
	box.position = Vector2(16, 10)
	box.add_theme_constant_override(&"separation", 6)
	layer.add_child(box)
	var title := Label.new()
	title.text = "G-B spell VFX  -  %s  -  %s  -  tier %s" % [family, _tag,
			GameSettings.GFX_NAMES[GameSettings.effective_graphics_quality()]]
	title.add_theme_font_size_override(&"font_size", 22)
	box.add_child(title)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 8)
	box.add_child(head)
	for t: String in ["", "cast / flight", "impact", "linger"]:
		var l := Label.new()
		l.text = t
		l.custom_minimum_size = Vector2(220 if t == "" else THUMB.x, 0)
		head.add_child(l)
	for row: Array in _sheets[family]:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override(&"separation", 8)
		box.add_child(hb)
		var l := Label.new()
		l.text = row[0]
		l.custom_minimum_size = Vector2(220, THUMB.y)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override(&"font_size", 18)
		hb.add_child(l)
		for img: Image in row[1]:
			var tr := TextureRect.new()
			tr.texture = ImageTexture.create_from_image(img)
			tr.custom_minimum_size = Vector2(THUMB)
			hb.add_child(tr)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	var dir := "%s/%s" % [OUT, _tag]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := "%s/sheet_%s.jpg" % [dir, family]
	shot.save_jpg(ProjectSettings.globalize_path(path), 0.88)
	print("saved ", path)
	layer.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------- storm (fps)

func _run_storm() -> void:
	var c := _next_arena()
	var foes := _foes(c + Vector3(0.0, 0, -2.0), 30)
	var spread := 0
	for f in foes:   # a looser 30-unit clump
		f.global_position = c + Vector3(-4.0 + float(spread % 6) * 1.6, 0.0, -5.0 + float(spread / 6) * 1.6)
		spread += 1
	var fire := _wizard(Wizard.new(), c + Vector3(-7.0, 0, 4.0))
	var shadow := _wizard(ShadowWizard.new(), c + Vector3(-3.0, 0, 5.0))
	var ice := _wizard(IceWizard.new(), c + Vector3(1.0, 0, 5.0))
	var nature := _wizard(NatureWizard.new(), c + Vector3(5.0, 0, 4.0))
	var kw := _caster("kilnwarden", Unit.Team.PLAYER, c + Vector3(-8.0, 0, 1.0))
	var rc := _caster("rimecarver", Unit.Team.PLAYER, c + Vector3(8.0, 0, 1.0))
	var bs := _caster("bramblesage", Unit.Team.PLAYER, c + Vector3(-6.0, 0, 6.5))
	var dc := _caster("gloom_deacon", Unit.Team.PLAYER, c + Vector3(6.0, 0, 6.5))
	_look(c + Vector3(0.0, 0, 0.0), 26.0)
	await _wait(1.5)
	var pick := func(k: int) -> Vector3: return foes[(k * 7) % foes.size()].global_position
	var casts: Array[Callable] = [
		func() -> void: _wcast(fire, &"fireball", pick.call(0)),
		func() -> void: _wcast(ice, &"flash_freeze", pick.call(1)),
		func() -> void: _wcast(nature, &"thornburst", pick.call(2)),
		func() -> void: _wcast(shadow, &"soul_siphon", pick.call(3)),
		func() -> void: _ccast(kw, &"slag_rain", pick.call(4)),
		func() -> void: _wcast(fire, &"kindle", null),
		func() -> void: _wcast(shadow, &"shadow_lance", foes[5]),
		func() -> void: _wcast(ice, &"rime_bolt", foes[9]),
		func() -> void: _wcast(nature, &"wild_bloom", c + Vector3(-1.0, 0, 4.0)),
		func() -> void: _ccast(bs, &"snagroot", foes[11]),
		func() -> void: _wcast(fire, &"fireball", pick.call(6)),
		func() -> void: _ccast(rc, &"rime_bulwark", c + Vector3(6.0, 0, -1.0)),
		func() -> void: _wcast(ice, &"rime_aegis", null),
		func() -> void: _wcast(shadow, &"umbral_shroud", null),
		func() -> void: _ccast(bs, &"pollen_haze", pick.call(8)),
		func() -> void: _wcast(nature, &"call_the_thicket", c + Vector3(3.0, 0, 2.0)),
		func() -> void: _wcast(fire, &"fireball", pick.call(9)),
		func() -> void: _ccast(dc, &"blood_tithe", fire),
		func() -> void: _wcast(ice, &"flash_freeze", pick.call(10)),
		func() -> void: _wcast(nature, &"thornburst", pick.call(12)),
	]
	# Round 1 warms the pipelines / pools up (a match has seen these spells before); round 2 is measured.
	for k in casts.size():
		(casts[k] as Callable).call()
		await _wait(0.125)
	await _wait(4.5)
	_frame_us.clear()
	_last_us = 0
	_measuring = true
	var shot_done := false
	for k in casts.size():
		(casts[k] as Callable).call()
		await _wait(0.125)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 3500:
		await get_tree().process_frame
		if not shot_done and Time.get_ticks_msec() - t0 > 100:
			shot_done = true
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
			img.resize(960, 540, Image.INTERPOLATE_LANCZOS)
			img.save_jpg(ProjectSettings.globalize_path("%s/storm_%s.jpg" % [OUT, _storm]), 0.88)
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
	var res := {"tag": _storm, "tier": GameSettings.GFX_NAMES[GameSettings.effective_graphics_quality()],
			"frames": times.size(), "avg_fps": snappedf(avg, 0.1), "low1_fps": snappedf(1000000.0 / float(p99), 0.1),
			"min_fps": snappedf(1000000.0 / float(worst), 0.1),
			"window": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y],
			"spell_fx_g": get_tree().get_nodes_in_group(&"spell_fx_g").size()}
	var f := FileAccess.open(ProjectSettings.globalize_path("%s/storm_%s.json" % [OUT, _storm]), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(res, "  "))
		f.close()
	print("GB STORM %s avg=%.1f low1=%.1f min=%.1f frames=%d tier=%s" % [_storm, avg, res["low1_fps"], res["min_fps"],
			times.size(), res["tier"]])
	get_tree().quit()


## Look-dev: every G billow palette and ground mark side by side, held (docs/art/lab/gb_vfx/probe.jpg).
func _run_probe() -> void:
	await _wait(0.5)
	var g := SpellFxG.live(self)
	if g == null:
		print("probe: no SpellFxG (tier Low?)")
		get_tree().quit()
		return
	var c := Vector3(0, 0, 0)
	_look(c, 16.0)
	var pi := OS.get_cmdline_user_args().find("--probe")
	var pid: String = OS.get_cmdline_user_args()[pi + 1] if pi + 1 < OS.get_cmdline_user_args().size() else ""
	if pid != "" and not pid.begins_with("--"):
		_look(c, 12.0)
		g.play(StringName(pid), c, {"r": 3.5})
		for k in 4:
			await _wait(0.12)
			await RenderingServer.frame_post_draw
			var im := get_viewport().get_texture().get_image()
			im.resize(800, 450, Image.INTERPOLATE_LANCZOS)
			im.save_jpg(ProjectSettings.globalize_path("%s/probe_%s_%d.jpg" % [OUT, pid, k]), 0.85)
		get_tree().quit()
		return
	var i := 0
	for pal: StringName in SpellFxG.PALETTES:
		g.call(&"_billow", c + Vector3(-9.0 + 3.0 * float(i % 7), 1.0, -2.0 + 4.0 * float(i / 7)), pal, 2.2, 2.4, 6.0)
		i += 1
	g.call(&"_billow", c + Vector3(9.0, 1.0, 2.0), &"shadow", 3.0, 1.0, 6.0, Vector3.ZERO, 0.0, 0.8, true)
	for k in 4:
		g.call(&"_mark", c + Vector3(-6.0 + 4.0 * float(k), 0.0, 4.0), k, 1.6, 6.0, 1.0, 1.0)
	for t: float in [0.15, 1.5, 3.0]:
		await _wait(t if t < 1.0 else 1.4)
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_jpg(ProjectSettings.globalize_path("%s/probe_%d.jpg" % [OUT, int(t * 10.0)]), 0.85)
	get_tree().quit()


## One before | after contact sheet of every family: docs/art/lab/gb_vfx/gb_vfx_before_after.jpg (the two sheets of a
## family side by side at half size, families stacked).
func _compose() -> void:
	var fams: Array[String] = ["wizard_fire", "wizard_shadow", "wizard_ice", "wizard_nature", "caster_fire", "caster_ice",
			"caster_nature", "caster_shadow"]
	var w := 800
	var h := 390
	var out := Image.create(w * 2 + 8, (h + 8) * fams.size(), false, Image.FORMAT_RGB8)
	out.fill(Color(0.06, 0.06, 0.07))
	var y := 0
	for fam in fams:
		var x := 0
		for tag: String in _compose_tags():
			var path := ProjectSettings.globalize_path("%s/%s/sheet_%s.jpg" % [OUT, tag, fam])
			var img := Image.load_from_file(path)
			if img:
				img.convert(Image.FORMAT_RGB8)
				var crop := img.get_region(Rect2i(0, 0, 1600, 780))
				crop.resize(w, h, Image.INTERPOLATE_LANCZOS)
				out.blit_rect(crop, Rect2i(0, 0, w, h), Vector2i(x, y))
			x += w + 8
		y += h + 8
	var name := "gb_vfx_before_after%s.jpg" % _compose_tags()[1].trim_prefix("after")
	out.save_jpg(ProjectSettings.globalize_path("%s/%s" % [OUT, name]), 0.85)
	print("GB COMPOSE saved ", OUT, "/", name)
	get_tree().quit()


## -- --compose [before_tag after_tag] (default before after).
func _compose_tags() -> Array[String]:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--compose")
	if i >= 0 and i + 2 < args.size() and not args[i + 1].begins_with("--"):
		return [args[i + 1], args[i + 2]]
	return ["before", "after"]


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

extends SceneTree
## G-F review 3, top-6 item 1 (docs/art/gf_review3.md, docs/art/gf_r3_ice_keep.md): the Ice keep was the loudest object
## on any map (a white crystal spire with glowing crack veins at full HP) and its damage smoke never read as a column.
## Checks on art/buildings/ice_keep.tscn (built, tier 3), for the main / alt (mirror) Ice palettes and every test team:
##   A  crystal: the team crystal's base colour has value (max channel) <= CRYSTAL_CAP and still reads its team hue.
##   B  glow x0.5: glow boost, crystal inner glow, idle rim and the crown light at or under half the old values.
##   C  veins: no crack veins (painted crack_strength 0, crystal fracture damage 0) at 50 % HP and above; on below 50 %.
##   D  smoke at 20 % HP: Smoke1 / Smoke2 emit, alpha-blended, drawn size > 1 m, value <= 0.72, a column >= 6 m tall;
##      off at full HP; no more particles than before (30 each).
## Modes:
##   test:  $GODOT --headless --path . -s tests/test_gf_r3_ice_keep.gd --fixed-fps 60 --quit-after 3000
##   shots: $GODOT --path . -s tests/test_gf_r3_ice_keep.gd --resolution 1600x900 --quit-after 4000 '--' --gfx=high shots=1 tag=after out=<dir>
##   sheet: $GODOT --headless --path . -s tests/test_gf_r3_ice_keep.gd --quit-after 600 '--' sheet=1 out=<dir>
##          (before_* + after_* shots of <dir> -> docs/art/lab/gf_r3_ice_keep/contact_sheet.jpg + the 4 key PNGs)
## Prints "PASS gf_r3_ice_keep (...)" or "FAIL gf_r3_ice_keep: <list>".

const TASK_ID := "gf_r3_ice_keep"
const ICE := "res://art/buildings/ice_keep.tscn"
const FIRE := "res://art/buildings/fire_keep.tscn"
const CRYSTAL_CAP := 0.6
const GLOW_BOOST_MAX := 0.15     # was 0.3
const ICE_GLOW_MAX := 0.5        # was 1.0
const RIM_IDLE_MAX := 0.1        # was 0.2
const CROWN_LIGHT_MAX := 1.0     # was 1.95 at tier 3 (1.5 x 1.3 x shimmer)
const SMOKE_CAP := 0.72
const SMOKE_AMOUNT_MAX := 30
const MAIN := Color(0.45, 0.75, 0.95)      # ice_keep.tres colour = IceKeep.DEFAULT_TEAM
const MAIN_UNIT := Color(0.45, 0.75, 1.0)  # Unit.KINGDOM_COLORS ice
const ALT := Color(0.5, 0.36, 0.86)        # Unit.KINGDOM_ALT_COLORS ice (mirror match)
const TEAMS: Array[Color] = [MAIN, MAIN_UNIT, ALT, Color(0.85, 0.2, 0.2), Color(0.2, 0.45, 0.95),
		Color(0.3, 0.8, 0.3), Color(0.95, 0.85, 0.2), Color(0.7, 0.3, 1.0), Color(0.95, 0.95, 0.95), Color(0.1, 0.1, 0.1)]
const OUT_DIR := "res://docs/art/lab/gf_r3_ice_keep"
const KEY_SHOTS: Array[String] = ["row", "ice_full", "ice_20", "mirror"]

var _fails: PackedStringArray = PackedStringArray()
var _notes: PackedStringArray = PackedStringArray()
var _world: Node3D
var _tag := "after"
var _out := "user://gf_r3_ice_keep"


func _initialize() -> void:
	var shots := false
	var sheet := false
	for arg: String in OS.get_cmdline_user_args():
		var k := arg.get_slice("=", 0)
		var v := arg.substr(k.length() + 1)
		match k:
			"shots": shots = v != "0"
			"sheet": sheet = v != "0"
			"tag": _tag = v
			"out": _out = v
	_world = Node3D.new()
	root.add_child(_world)
	if sheet:
		_make_sheet()
	elif shots:
		_run_shots()
	else:
		_run()


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _keep(path: String, pos: Vector3) -> Node3D:
	var k := (load(path) as PackedScene).instantiate() as Node3D
	k.position = pos
	_world.add_child(k)
	return k


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)


func _maxc(c: Color) -> float:
	return maxf(c.r, maxf(c.g, c.b))


func _hue_gap(a: float, b: float) -> float:
	var d: float = absf(a - b)
	return minf(d, 1.0 - d)


func _run() -> void:
	var k := _keep(ICE, Vector3.ZERO)
	await _frames(2)
	k.call(&"set_tier", 3)
	k.call(&"set_health_ratio", 1.0)
	await _frames(2)
	var crystal := k.get(&"_crystal_mat") as ShaderMaterial
	var glow := k.get(&"_glow_mat") as ShaderMaterial
	var painted: Array = k.get(&"_painted_mats")
	_check(crystal != null and glow != null and painted.size() >= 3, "keep materials not found")
	if not _fails.is_empty():
		_finish()
		return
	# A: crystal value and team hue, every palette.
	var hues := {}
	for c: Color in TEAMS:
		k.call(&"set_team_color", c)
		var b: Color = crystal.get_shader_parameter(&"base_color")
		var tag := c.to_html(false)
		_check(_maxc(b) <= CRYSTAL_CAP + 0.001, "crystal value %.3f > %.2f (team %s)" % [_maxc(b), CRYSTAL_CAP, tag])
		_check(_maxc(b) >= 0.35, "crystal value %.3f too dark (team %s)" % [_maxc(b), tag])
		if c.s > 0.3:
			_check(_hue_gap(b.h, c.h) < 0.06, "crystal hue drifts from the team (team %s, %.3f vs %.3f)" % [tag, b.h, c.h])
			_check(b.s >= 0.25, "crystal saturation %.2f lost the team colour (team %s)" % [b.s, tag])
		hues[tag] = b
		_notes.append("team %s -> crystal %s (v %.2f s %.2f)" % [tag, b.to_html(false), _maxc(b), b.s])
	var bm: Color = hues[MAIN.to_html(false)]
	var ba: Color = hues[ALT.to_html(false)]
	_check(_hue_gap(bm.h, ba.h) > 0.1, "mirror palette: main / alt crystals too close in hue (%.3f / %.3f)" % [bm.h, ba.h])
	k.call(&"set_team_color", MAIN)
	# B: glow x0.5.
	var boost: float = glow.get_shader_parameter(&"boost_mult")
	_check(boost <= GLOW_BOOST_MAX + 0.001, "glow boost %.3f > %.2f" % [boost, GLOW_BOOST_MAX])
	var ig: Variant = crystal.get_shader_parameter(&"ip_ice_glow")
	_check(ig != null and float(ig) <= ICE_GLOW_MAX + 0.001, "crystal ip_ice_glow %s > %.2f" % [str(ig), ICE_GLOW_MAX])
	for m: ShaderMaterial in painted:
		var rs: float = m.get_shader_parameter(&"rim_strength")
		_check(rs <= RIM_IDLE_MAX + 0.001, "%s idle rim %.2f > %.2f" % [m.resource_name, rs, RIM_IDLE_MAX])
	await _frames(3)
	var cl := k.get_node(^"CrownLight") as OmniLight3D
	_check(cl.light_energy <= CROWN_LIGHT_MAX, "crown light %.2f > %.2f" % [cl.light_energy, CROWN_LIGHT_MAX])
	# C: veins only below 50 % HP.
	for hp: float in [1.0, 0.8, 0.5]:
		k.call(&"set_health_ratio", hp)
		for m: ShaderMaterial in painted:
			var cs: float = m.get_shader_parameter(&"crack_strength")
			_check(cs <= 0.0001, "%s veins at %d %% HP (crack_strength %.2f)" % [m.resource_name, int(hp * 100.0), cs])
		var dmg: float = crystal.get_shader_parameter(&"damage")
		_check(dmg <= 0.0001, "crystal fracture lines at %d %% HP (damage %.2f)" % [int(hp * 100.0), dmg])
	k.call(&"set_health_ratio", 0.45)
	var any_vein := false
	for m: ShaderMaterial in painted:
		any_vein = any_vein or float(m.get_shader_parameter(&"crack_strength")) > 0.0
	_check(any_vein, "no crack veins at 45 % HP")
	_check(float(crystal.get_shader_parameter(&"damage")) > 0.0, "no crystal fracture at 45 % HP")
	# D: damage smoke at 20 % HP.
	for hp: float in [1.0, 0.2]:
		k.call(&"set_health_ratio", hp)
		await _frames(2)
		for nm: String in ["Smoke1", "Smoke2"]:
			var p := k.get_node(NodePath(nm)) as GPUParticles3D
			if hp >= 1.0:
				_check(not p.emitting, "%s emits at full HP" % nm)
				continue
			_check(p.emitting and p.is_visible_in_tree() and p.amount_ratio > 0.0, "%s does not draw at 20 %% HP" % nm)
			_check(p.amount <= SMOKE_AMOUNT_MAX, "%s amount %d > %d (Low cost)" % [nm, p.amount, SMOKE_AMOUNT_MAX])
			_smoke_check(p, nm)
	_finish()


func _smoke_check(p: GPUParticles3D, nm: String) -> void:
	var mesh: Mesh = p.draw_pass_1
	var mat := MoteCap.draw_material(p) as BaseMaterial3D
	_check(mat != null and mat.blend_mode == BaseMaterial3D.BLEND_MODE_MIX, "%s is not alpha-blended" % nm)
	var q: float = 1.0
	if mesh is QuadMesh:
		q = maxf((mesh as QuadMesh).size.x, (mesh as QuadMesh).size.y)
	elif mesh:
		q = maxf(mesh.get_aabb().size.x, mesh.get_aabb().size.y)
	var pm := p.process_material as ParticleProcessMaterial
	var keep_scale: bool = mat != null and mat.billboard_keep_scale
	var peak_curve: float = 1.0
	if pm.scale_curve is CurveTexture and (pm.scale_curve as CurveTexture).curve:
		var cv: Curve = (pm.scale_curve as CurveTexture).curve
		peak_curve = 0.0
		for i: int in 11:
			peak_curve = maxf(peak_curve, cv.sample(float(i) / 10.0))
	var drawn: float = q * (pm.scale_max * peak_curve if keep_scale else 1.0)
	_check(drawn > 1.0, "%s drawn size %.2f m <= 1 m" % [nm, drawn])
	var vmax := 0.0
	var amax := 0.0
	var g: Gradient = (pm.color_ramp as GradientTexture1D).gradient if pm.color_ramp is GradientTexture1D else null
	if g:
		for i: int in g.get_point_count():
			var c: Color = g.get_color(i) * pm.color
			vmax = maxf(vmax, _maxc(c))
			amax = maxf(amax, c.a)
	_check(g != null, "%s has no colour ramp" % nm)
	_check(vmax <= SMOKE_CAP + 0.001, "%s value %.2f > %.2f" % [nm, vmax, SMOKE_CAP])
	_check(vmax >= 0.4, "%s value %.2f: too dark to read as grey smoke" % [nm, vmax])
	_check(amax >= 0.35, "%s peak alpha %.2f too faint" % [nm, amax])
	var rise: float = p.lifetime * pm.initial_velocity_min
	_check(rise >= 6.0, "%s column %.1f m < 6 m" % [nm, rise])
	_notes.append("%s: drawn %.2f m, value %.2f, alpha %.2f, column %.1f m, %d particles, life %.1f s" % [nm, drawn, vmax,
			amax, rise, p.amount, p.lifetime])


func _finish() -> void:
	for n: String in _notes:
		print("  ", n)
	if _fails.is_empty():
		print("PASS %s (crystal <= %.2f, glow x0.5, veins < 50 %% HP, smoke column, tier %d)" % [TASK_ID, CRYSTAL_CAP,
				GameSettings.effective_graphics_quality()])
	else:
		for f: String in _fails:
			print("  ", f)
		print("FAIL %s: %d (first: %s)" % [TASK_ID, _fails.size(), _fails[0]])
	quit(0)


# --- shots (windowed, --gfx=high): Fire keep / Ice keep / Ice alt side by side, Ice close at 100 % and 20 % HP --------

func _run_shots() -> void:
	var env := WorldEnvironment.new()
	env.environment = (load("res://art/environment/world_env.tres") as Environment).duplicate() as Environment
	_world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.shadow_enabled = true
	_world.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.30, 0.36, 0.20)
	gm.roughness = 1.0
	ground.material_override = gm
	_world.add_child(ground)
	var fire := _keep(FIRE, Vector3(16.0, 0, 0))
	var ice := _keep(ICE, Vector3(0, 0, 0))
	var alt := _keep(ICE, Vector3(-16.0, 0, 0))
	var cam := Camera3D.new()
	cam.fov = 40.0
	_world.add_child(cam)
	cam.current = true
	await _frames(5)
	fire.call(&"set_team_color", Color(0.85, 0.30, 0.12))
	ice.call(&"set_team_color", MAIN)
	alt.call(&"set_team_color", ALT)
	for k: Node3D in [fire, ice, alt]:
		k.call(&"set_tier", 1)
		k.call(&"set_health_ratio", 1.0)
	await _frames(90)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	var pitch := deg_to_rad(52.0)
	var f := Vector3(0, 5.0, 0)
	cam.look_at_from_position(f + Vector3(0, sin(pitch) * 58.0, -cos(pitch) * 58.0), f, Vector3.UP)
	await _shot("row", [Vector2(0.62, 0.86), Vector2(0.4, 0.6), Vector2(0.14, 0.38)])
	var fi := Vector3(0, 7.0, 0)
	cam.look_at_from_position(fi + Vector3(0, sin(pitch) * 26.0, -cos(pitch) * 26.0), fi, Vector3.UP)
	await _shot("ice_full", [Vector2(0.3, 0.7)])
	ice.call(&"set_health_ratio", 0.2)
	alt.call(&"set_health_ratio", 0.2)
	await create_timer(5.5).timeout   # real time: the smoke column needs a full 5 s particle life (frames run fast)
	var fs := Vector3(0, 9.0, 0)
	cam.look_at_from_position(fs + Vector3(0, sin(pitch) * 34.0, -cos(pitch) * 34.0), fs, Vector3.UP)
	await _shot("ice_20", [Vector2(0.3, 0.7)])
	var fm := Vector3(-8.0, 6.0, 0)
	cam.look_at_from_position(fm + Vector3(0, sin(pitch) * 42.0, -cos(pitch) * 42.0), fm, Vector3.UP)
	await _shot("mirror", [Vector2(0.55, 0.95), Vector2(0.05, 0.45)])
	quit(0)


## Saves the frame and prints the 98th-percentile value (max channel) of each column band (x0..x1 of the width).
func _shot(nm: String, bands: Array) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := "%s/%s_%s.png" % [_out, _tag, nm]
	img.save_png(ProjectSettings.globalize_path(path))
	var parts: PackedStringArray = PackedStringArray()
	for b: Vector2 in bands:
		parts.append("%.2f-%.2f: p98 %.3f" % [b.x, b.y, _p98(img, b)])
	print("saved %s  [%s]" % [path, ", ".join(parts)])


func _p98(img: Image, band: Vector2) -> float:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var vals: PackedFloat32Array = PackedFloat32Array()
	for y: int in range(int(h * 0.08), int(h * 0.92), 3):
		for x: int in range(int(w * band.x), int(w * band.y), 3):
			var c: Color = img.get_pixel(x, y)
			vals.append(maxf(c.r, maxf(c.g, c.b)))
	vals.sort()
	return vals[int(vals.size() * 0.98)] if vals.size() > 0 else 0.0


# --- sheet: before / after pairs -> contact_sheet.jpg + the 4 key PNGs ---------------------------------------------

func _make_sheet() -> void:
	var dir: String = ProjectSettings.globalize_path(_out)
	var out_dir: String = ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var cell := Vector2i(800, 450)
	var sheet := Image.create(cell.x * 2, cell.y * KEY_SHOTS.size(), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.08, 0.08, 0.1))
	var row := 0
	for nm: String in KEY_SHOTS:
		for col: int in 2:
			var tag: String = "before" if col == 0 else "after"
			var img := Image.load_from_file("%s/%s_%s.png" % [dir, tag, nm])
			if img == null or img.is_empty():
				print("missing %s_%s" % [tag, nm])
				continue
			img.convert(Image.FORMAT_RGB8)
			# 4 key PNGs: the before / after row, the after Ice close-ups at 100 % and 20 % HP.
			if (tag == "after" and nm != "mirror") or (tag == "before" and nm == "row"):
				img.save_png("%s/%s_%s.png" % [out_dir, tag, nm])
			img.resize(cell.x, cell.y, Image.INTERPOLATE_BILINEAR)
			sheet.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i(col * cell.x, row * cell.y))
		row += 1
	sheet.save_jpg("%s/contact_sheet.jpg" % out_dir, 0.85)
	print("saved %s/contact_sheet.jpg (left before, right after; rows %s)" % [OUT_DIR, ", ".join(KEY_SHOTS)])
	quit(0)

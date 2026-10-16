extends SceneTree
## G-F round 3 item 6 + regressions (docs/art/gf_review3.md, docs/art/gf_r3_fire_keep.md):
##   * the Ember Crucible's pit floor (the slag crust in the bowl, the chimney crown's floor) is a dark ember red under
##     the glow cap, never black; the chimney crown is round; the floor light pool is alpha-blended (no additive pool);
##   * the Fire keep's orb cage is slimmer (CROWN_SLIM 0.65) and the Ember Heart's emission is x0.6;
##   * the Fire, Dusk and Nature keeps' damage smoke (Smoke1/2) at 20 % HP draws soft grey columns: puffs >= 3 m,
##     lifetime >= 4.5 s, rising >= 6 m, alpha-blended, colour value <= 0.72 (MoteCap) and >= 0.3 (not near-black).
## Modes:
##   test:  $GODOT --headless --path . -s tests/test_gf_r3_fire_keep.gd --fixed-fps 60 --quit-after 2400
##   shots: $GODOT --path . -s tests/test_gf_r3_fire_keep.gd --resolution 1600x900 --fixed-fps 60 --quit-after 5000 '--' --gfx=high shots=1 tag=after
##          (legacy_smoke=1: the old damage smoke, for before shots)
## Prints "PASS gf_r3_fire_keep (...)" or "FAIL gf_r3_fire_keep: <list>".

const TASK_ID := "gf_r3_fire_keep"
const FIRE_KEEP := "res://art/buildings/fire_keep.tscn"
const DUSK_KEEP := "res://art/buildings/dusk_keep.tscn"
const NATURE_KEEP := "res://art/buildings/nature_keep.tscn"
const CRUCIBLE := "res://art/buildings/fire/ember_crucible/ember_crucible.tscn"
const EC_DIR := "res://art/buildings/fire/ember_crucible/"
const OUT_DIR := "res://docs/art/lab/gf_r3_fire_keep"
const SMOKE_MIN_SIZE := 3.0
const SMOKE_MIN_LIFE := 4.5
const SMOKE_MIN_RISE := 6.0
const VALUE_CAP := 0.72
const VALUE_MIN := 0.3

var _world: Node3D
var _errors: PackedStringArray = PackedStringArray()
var _notes: PackedStringArray = PackedStringArray()
var _shots := false
var _tag := "after"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var k := arg.get_slice("=", 0)
		var v := arg.substr(k.length() + 1)
		match k:
			"shots": _shots = v != "0"
			"tag": _tag = v
			"legacy_smoke": KeepDamageSmoke.enabled = v == "0"   # 1 = the old smoke (before shots)
	_world = Node3D.new()
	root.add_child(_world)
	if _shots:
		_run_shots()
	else:
		_run()


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)


func _add(path: String, pos: Vector3) -> Node3D:
	var m := (load(path) as PackedScene).instantiate() as Node3D
	m.position = pos
	_world.add_child(m)
	return m


func _maxc(c: Color) -> float:
	return maxf(c.r, maxf(c.g, c.b))


func _run() -> void:
	await _frames(2)   # the world enters the tree after _initialize
	await _check_crucible()
	await _check_fire_keep()
	await _check_smoke()
	for n: String in _notes:
		print("  ", n)
	if _errors.is_empty():
		print("PASS %s (crucible pit, cage %.2f, heart x0.6, smoke on 3 keeps, tier %d)" % [TASK_ID,
				FireKeepModel.CROWN_SLIM, GameSettings.effective_graphics_quality()])
	else:
		for e: String in _errors:
			print("  ", e)
		print("FAIL %s: %s" % [TASK_ID, _errors[0]])
	quit(0)


# ---------------------------------------------------------------- crucible

func _check_crucible() -> void:
	var pit := load(EC_DIR + "materials/ec_pit.tres") as ShaderMaterial
	_check(pit != null, "ec_pit.tres missing")
	if pit == null:
		return
	_check(pit.shader.resource_path.ends_with("crucible_glow.gdshader"), "ec_pit not on crucible_glow")
	var gc: Color = pit.get_shader_parameter(&"glow_color")
	var energy: float = float(pit.get_shader_parameter(&"energy"))
	# crucible_glow: ALBEDO = glow_cap(gc * 0.4 + gc * energy * pulse (0.5..1)), gc a source_color (linear in the
	# shader); the shown value is that linear albedo back in sRGB. The knee of the cap is 0.6 x 1.5 (linear).
	var lin: Color = gc.srgb_to_linear()
	var peak: float = Color(lin * (0.4 + energy)).linear_to_srgb().r
	var low: float = Color(lin * (0.4 + energy * 0.5)).linear_to_srgb().r
	_check(_maxc(lin) * (0.4 + energy) <= 0.9, "pit floor over the glow cap knee (linear)")
	_notes.append("crucible pit glow_color %s energy %.2f -> value %.2f .. %.2f" % [gc, energy, low, peak])
	_check(gc.r >= 0.18 and gc.r > gc.g * 2.0 and gc.g > gc.b, "pit floor not dark ember red: %s" % gc)
	_check(low >= 0.2, "pit floor too dark (black): %.2f" % low)
	_check(peak <= 0.45, "pit floor glows too bright: %.2f" % peak)
	var cr := (load(CRUCIBLE) as PackedScene).instantiate() as Node3D
	_world.add_child(cr)
	await _frames(2)
	cr.call(&"set_crucible", false, true)
	var crust := cr.get_node(^"CruciblePivot/Crust") as MeshInstance3D
	var pilot := cr.get_node(^"PilotGlow") as MeshInstance3D
	_check(crust.visible, "cold crucible: crust hidden")
	_check(_has_mat(crust, pit), "cold crucible: crust has no ember-red pit floor")
	_check(pilot.visible and _has_mat(pilot, pit), "chimney crown: no ember-red pit floor (always on)")
	var pool := cr.get_node(^"LightPool") as MeshInstance3D
	var pool_code: String = ((pool.material_override as ShaderMaterial).shader as Shader).code
	_check(not pool_code.contains("blend_add"), "crucible light pool still additive")
	cr.queue_free()


func _has_mat(mi: MeshInstance3D, mat: Material) -> bool:
	for s: int in mi.mesh.get_surface_count():
		var m: Material = mi.get_surface_override_material(s)
		if m == null:
			m = mi.mesh.surface_get_material(s)
		if m == mat:
			return true
	return false


# ---------------------------------------------------------------- fire keep cage / heart

func _check_fire_keep() -> void:
	_check(absf(FireKeepModel.CROWN_SLIM - 0.65) < 0.001, "CROWN_SLIM %.2f != 0.65" % FireKeepModel.CROWN_SLIM)
	var k := _add(FIRE_KEEP, Vector3(0, 0, -40))
	await _frames(3)
	var ring := k.get_node(^"Body/Ring") as Node3D
	var heart := k.get_node(^"Body/EmberHeart") as Node3D
	_check(absf(ring.scale.x - 0.65) < 0.02, "ring (cage) scale %.2f != 0.65" % ring.scale.x)
	_check(absf(heart.scale.x - 0.65) < 0.02, "heart scale %.2f != 0.65" % heart.scale.x)
	var hm := k.get(&"heart_material") as ShaderMaterial
	var he: float = float(hm.get_shader_parameter(&"heart_energy")) if hm else -1.0
	_notes.append("fire keep heart_energy %.2f (was 3.6)" % he)
	_check(absf(he - 3.6 * 0.6) < 0.01, "heart energy %.2f != 2.16 (x0.6)" % he)
	k.queue_free()


# ---------------------------------------------------------------- damage smoke

func _check_smoke() -> void:
	var i := 0
	for path: String in [FIRE_KEEP, DUSK_KEEP, NATURE_KEEP]:
		var k := _add(path, Vector3(i * 30.0, 0, 0))
		i += 1
		await _frames(2)
		k.call(&"set_tier", 3)
		k.call(&"set_health_ratio", 0.2)
		await _frames(3)
		var found := 0
		for nm: String in ["Smoke1", "Smoke2"]:
			var p: GPUParticles3D = null
			for c: Node in k.find_children(nm, "GPUParticles3D", true, false):
				p = c as GPUParticles3D
			var tag := "%s %s" % [path.get_file().get_basename(), nm]
			if p == null:
				_errors.append("%s missing" % tag)
				continue
			found += 1
			_check(p.emitting and p.is_visible_in_tree() and p.amount_ratio > 0.0, "%s not emitting at 20 %% HP" % tag)
			var size := _drawn_size(p)
			var pm := p.process_material as ParticleProcessMaterial
			var rise: float = pm.initial_velocity_min * p.lifetime if pm else 0.0
			var vals := _ramp_values(pm)
			var mat := MoteCap.draw_material(p) as BaseMaterial3D
			_notes.append("%s size %.2f m, life %.1f s, rise %.1f m, value %.2f..%.2f, peak alpha %.2f" % [tag, size,
					p.lifetime, rise, vals.x, vals.y, vals.z])
			_check(size >= SMOKE_MIN_SIZE, "%s drawn size %.2f < %.1f m" % [tag, size, SMOKE_MIN_SIZE])
			_check(p.lifetime >= SMOKE_MIN_LIFE, "%s lifetime %.1f < %.1f" % [tag, p.lifetime, SMOKE_MIN_LIFE])
			_check(rise >= SMOKE_MIN_RISE, "%s rises %.1f < %.1f m" % [tag, rise, SMOKE_MIN_RISE])
			_check(vals.y <= VALUE_CAP + 0.001, "%s colour value %.2f > %.2f" % [tag, vals.y, VALUE_CAP])
			_check(vals.x >= VALUE_MIN, "%s colour value %.2f < %.2f (near-black)" % [tag, vals.x, VALUE_MIN])
			_check(vals.z >= 0.3 and vals.z <= 0.75, "%s peak alpha %.2f outside 0.3..0.75" % [tag, vals.z])
			_check(mat != null and mat.blend_mode == BaseMaterial3D.BLEND_MODE_MIX
					and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED, "%s not alpha-blended" % tag)
			_check(mat != null and mat.billboard_keep_scale, "%s billboard drops the particle scale" % tag)
			_check(_maxc(mat.albedo_color) <= 1.0 if mat else false, "%s HDR albedo" % tag)
		_check(found == 2, "%s: %d smoke emitters" % [path, found])
		k.queue_free()
		await _frames(1)


## The largest world size a smoke puff draws at: quad size x process scale_max x the curve's peak (keep scale on).
func _drawn_size(p: GPUParticles3D) -> float:
	var q := 1.0
	var mesh: Mesh = p.draw_pass_1
	if mesh is QuadMesh:
		q = maxf((mesh as QuadMesh).size.x, (mesh as QuadMesh).size.y)
	elif mesh:
		q = maxf(mesh.get_aabb().size.x, mesh.get_aabb().size.y)
	var pm := p.process_material as ParticleProcessMaterial
	var sc: float = pm.scale_max if pm else 1.0
	var peak := 1.0
	if pm and pm.scale_curve is CurveTexture and (pm.scale_curve as CurveTexture).curve:
		var cv: Curve = (pm.scale_curve as CurveTexture).curve
		peak = 0.0
		for j: int in 21:
			peak = maxf(peak, cv.sample(float(j) / 20.0))
	return q * sc * peak


## (min value over the opaque stops, max value, peak alpha) of the process colour x ramp.
func _ramp_values(pm: ParticleProcessMaterial) -> Vector3:
	if pm == null:
		return Vector3.ZERO
	var g: Gradient = null
	if pm.color_ramp is GradientTexture1D:
		g = (pm.color_ramp as GradientTexture1D).gradient
	if g == null:
		return Vector3(_maxc(pm.color), _maxc(pm.color), pm.color.a)
	var lo := 9.0
	var hi := 0.0
	var amax := 0.0
	for j: int in g.get_point_count():
		var c: Color = pm.color * g.get_color(j)
		hi = maxf(hi, _maxc(c))
		amax = maxf(amax, c.a)
		if c.a >= 0.2:
			lo = minf(lo, _maxc(c))
	return Vector3(lo if lo < 9.0 else 0.0, hi, amax)


# ---------------------------------------------------------------- shots (windowed, --gfx=high)

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
	var pm := PlaneMesh.new()
	pm.size = Vector2(220, 220)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.30, 0.34, 0.22)
	gm.roughness = 1.0
	ground.material_override = gm
	_world.add_child(ground)
	var fire := _add(FIRE_KEEP, Vector3(-30, 0, 0))
	var dusk := _add(DUSK_KEEP, Vector3(0, 0, 0))
	var nature := _add(NATURE_KEEP, Vector3(30, 0, 0))
	var fire_full := _add(FIRE_KEEP, Vector3(-30, 0, 40))
	var cr_lit := _add(CRUCIBLE, Vector3(10, 0, 40))
	var cr_cold := _add(CRUCIBLE, Vector3(16, 0, 40))
	var cam := Camera3D.new()
	cam.fov = 40.0
	_world.add_child(cam)
	cam.current = true
	await _frames(5)
	for k: Node3D in [fire, dusk, nature]:
		k.call(&"set_tier", 3)
		k.call(&"set_health_ratio", 0.2)
	fire_full.call(&"set_tier", 1)
	cr_lit.call(&"set_crucible", true, true)
	cr_cold.call(&"set_crucible", false, true)
	await _frames(60)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var q: int = GameSettings.effective_graphics_quality()
	var names: Array[String] = ["fire", "dusk", "nature"]
	var keeps: Array[Node3D] = [fire, dusk, nature]
	for i: int in keeps.size():
		await _rts(cam, keeps[i].position, 30.0, 330)
		_save("%s_q%d_keep20_%s_z30" % [_tag, q, names[i]])
	await _rts(cam, fire.position + Vector3(0, 0, 3), 45.0, 330)
	_save("%s_q%d_keep20_fire_z45" % [_tag, q])
	await _rts(cam, fire_full.position, 30.0, 120)
	_save("%s_q%d_fire_keep_full_z30" % [_tag, q])
	await _rts(cam, (cr_lit.position + cr_cold.position) * 0.5, 12.0, 120)
	_save("%s_q%d_crucible_z12" % [_tag, q])
	quit(0)


## The game's RTS view: pitch 55 deg from +Z, `zoom` m from the ground pivot. `settle` frames before the shot:
## Godot only simulates particles it draws (a camera or shadow pass sees them), so a transparent emitter out of view
## stays at its birth point (alpha 0 at birth = invisible) until the camera looks at it; 330 frames at --fixed-fps 60
## = 5.5 s, one smoke lifetime.
func _rts(cam: Camera3D, at: Vector3, zoom: float, settle: int = 3) -> void:
	var pitch := deg_to_rad(55.0)
	cam.look_at_from_position(at + Vector3(0, sin(pitch) * zoom, cos(pitch) * zoom), at, Vector3.UP)
	await _frames(settle)
	await RenderingServer.frame_post_draw


func _save(nm: String) -> void:
	var path := "%s/%s.png" % [OUT_DIR, nm]
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("saved %s" % path)

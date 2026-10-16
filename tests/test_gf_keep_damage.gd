extends SceneTree
## G-F keep damage pass (docs/art/gf_keep_damage.md): under 25 % HP the Dusk Keep's damage Rift bloomed into a
## white-lilac ball (24 additive quads on an albedo x3 HDR material: each one already past the glow threshold, the
## stack summed to white). Every keep's damage effects must stay under a cap at 20 % HP, for every team colour.
## Damage effects = the particle emitters that emit on a keep at 20 % HP and not on the same keep at full HP
## (tier 3, built). For each one the peak colour a particle can draw is computed from its draw material
## (albedo x albedo texture x process colour x colour ramp, + emission x energy):
##   * alpha-blended (MIX): max channel <= CAP_MIX (0.72 = MoteCap.VALUE_CAP): a stack never sums past its own colour.
##   * additive (ADD): per-particle peak (rgb x alpha) x STACK (the particles that overlap at a plume's core) <= CAP_ADD
##     (1.0, under every world environment's glow threshold 1.1-1.3). A speck emitter (drawn size <= SPECK_SIZE m:
##     sparse embers / sparks that never pile into a plume) counts as a stack of 1.
##   * no HDR albedo (> 1.0) on any damage-effect material.
## Modes:
##   test:  $GODOT --headless --path . -s tests/test_gf_keep_damage.gd --fixed-fps 60 --quit-after 3000 [-- --gfx=high]
##   shots: $GODOT --path . -s tests/test_gf_keep_damage.gd --resolution 1600x900 --quit-after 3000 '--' --gfx=high shots=1 tag=after
## Prints "PASS gf_keep_damage (...)" or "FAIL gf_keep_damage: <list>".

const TASK_ID := "gf_keep_damage"
const KEEPS: Array[String] = ["res://art/buildings/fire_keep.tscn", "res://art/buildings/ice_keep.tscn",
		"res://art/buildings/nature_keep.tscn", "res://art/buildings/dusk_keep.tscn"]
const CAP_MIX := 0.72
const CAP_ADD := 1.0
const STACK := 6.0
const SPECK_SIZE := 0.25
const TEAMS: Array[Color] = [Color(0.85, 0.2, 0.2), Color(0.2, 0.45, 0.95), Color(0.3, 0.8, 0.3),
		Color(0.95, 0.85, 0.2), Color(0.7, 0.3, 1.0), Color(0.95, 0.95, 0.95), Color(0.1, 0.1, 0.1)]
const OUT_DIR := "res://docs/art/lab/gf_keep_damage"

var _fails: PackedStringArray = PackedStringArray()
var _lines: PackedStringArray = PackedStringArray()
var _world: Node3D
var _shots := false
var _tag := "after"
var _checked := 0
var _near := 24.0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var k := arg.get_slice("=", 0)
		var v := arg.substr(k.length() + 1)
		match k:
			"shots": _shots = v != "0"
			"tag": _tag = v
			"near": _near = float(v)
	_world = Node3D.new()
	root.add_child(_world)
	if _shots:
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


func _run() -> void:
	var i := 0
	for path: String in KEEPS:
		for team: Color in TEAMS:
			var full := _keep(path, Vector3(i * 30.0, 0, 0))
			var hurt := _keep(path, Vector3(i * 30.0, 0, 30.0))
			i += 1
			await _frames(2)
			for k: Node3D in [full, hurt]:
				if k.has_method(&"set_team_color"):
					k.call(&"set_team_color", team)
				k.call(&"set_tier", 3)
				k.call(&"set_health_ratio", 1.0 if k == full else 0.2)
			await _frames(4)
			var on_full := {}
			for e: Node in _emitters(full, []):
				if _emitting(e):
					on_full[str(full.get_path_to(e))] = true
			var tag: String = "%s team %s" % [path.get_file().get_basename(), team.to_html(false)]
			for e: Node in _emitters(hurt, []):
				var rel := str(hurt.get_path_to(e))
				if _emitting(e) and not on_full.has(rel):
					_check(e, "%s %s" % [tag, rel])
			full.queue_free()
			hurt.queue_free()
			await _frames(1)
	for l: String in _lines:
		print("  ", l)
	if _checked == 0:
		_fails.append("no damage emitter found")
	if _fails.is_empty():
		print("PASS %s (%d damage emitters x team colours, mix <= %.2f, add x%d <= %.2f, tier %d)" % [TASK_ID, _checked,
				CAP_MIX, int(STACK), CAP_ADD, GameSettings.effective_graphics_quality()])
	else:
		for f: String in _fails:
			print("  ", f)
		print("FAIL %s: %d over the cap (first: %s)" % [TASK_ID, _fails.size(), _fails[0]])
	quit(0)


func _emitters(n: Node, out: Array) -> Array:
	for c: Node in n.get_children():
		if c is GPUParticles3D or c is CPUParticles3D:
			out.append(c)
		_emitters(c, out)
	return out


func _emitting(e: Node) -> bool:
	var v: bool = (e as Node3D).is_visible_in_tree()
	if e is GPUParticles3D:
		return v and (e as GPUParticles3D).emitting and (e as GPUParticles3D).amount_ratio > 0.0
	return v and (e as CPUParticles3D).emitting


func _materials(e: Node) -> Array[Material]:
	var out: Array[Material] = []
	var gi := e as GeometryInstance3D
	if gi.material_override:
		out.append(gi.material_override)
		return out
	var mesh: Mesh = (e as GPUParticles3D).draw_pass_1 if e is GPUParticles3D else (e as CPUParticles3D).mesh
	if mesh == null:
		return out
	if mesh is PrimitiveMesh and (mesh as PrimitiveMesh).material:
		out.append((mesh as PrimitiveMesh).material)
	for s: int in mesh.get_surface_count():
		if mesh.surface_get_material(s):
			out.append(mesh.surface_get_material(s))
	return out


## The colours a texture can multiply by (a gradient texture's stops; anything else = white).
func _tex_cols(t: Texture2D) -> Array[Color]:
	var out: Array[Color] = []
	var g: Gradient = null
	if t is GradientTexture2D:
		g = (t as GradientTexture2D).gradient
	elif t is GradientTexture1D:
		g = (t as GradientTexture1D).gradient
	if g:
		for k: int in g.get_point_count():
			out.append(g.get_color(k))
	if out.is_empty():
		out.append(Color.WHITE)
	return out


func _ramp_cols(e: Node) -> Array[Color]:
	var out: Array[Color] = []
	var base := Color.WHITE
	var ramp: Texture2D = null
	if e is GPUParticles3D:
		var pm := (e as GPUParticles3D).process_material as ParticleProcessMaterial
		if pm:
			base = pm.color
			ramp = pm.color_ramp
	else:
		var cp := e as CPUParticles3D
		base = cp.color
		if cp.color_ramp:
			for k: int in cp.color_ramp.get_point_count():
				out.append(base * cp.color_ramp.get_color(k))
			return out
	for c: Color in _tex_cols(ramp) if ramp else ([Color.WHITE] as Array[Color]):
		out.append(base * c)
	return out


## The largest world size a particle draws at: quad size x process scale_max (curves peak at 1).
func _drawn_size(e: Node) -> float:
	var q := 1.0
	var mesh: Mesh = (e as GPUParticles3D).draw_pass_1 if e is GPUParticles3D else (e as CPUParticles3D).mesh
	if mesh is QuadMesh:
		q = maxf((mesh as QuadMesh).size.x, (mesh as QuadMesh).size.y)
	elif mesh:
		var a: AABB = mesh.get_aabb()
		q = maxf(a.size.x, a.size.y)
	var sc := 1.0
	if e is GPUParticles3D:
		var pm := (e as GPUParticles3D).process_material as ParticleProcessMaterial
		if pm:
			sc = pm.scale_max
	else:
		sc = (e as CPUParticles3D).scale_amount_max
	return q * sc


func _maxc(c: Color) -> float:
	return maxf(c.r, maxf(c.g, c.b))


func _check(e: Node, tag: String) -> void:
	var mats := _materials(e)
	if mats.is_empty():
		_fails.append("%s: no draw material" % tag)
		return
	var ramp := _ramp_cols(e)
	var stack: float = STACK if _drawn_size(e) > SPECK_SIZE else 1.0
	var seen := {}
	for m: Material in mats:
		if seen.has(m):
			continue
		seen[m] = true
		_checked += 1
		var bm := m as BaseMaterial3D
		if bm == null:
			_fails.append("%s: unmeasured material %s" % [tag, m])
			continue
		var add: bool = bm.blend_mode == BaseMaterial3D.BLEND_MODE_ADD
		var tex := _tex_cols(bm.albedo_texture)
		var peak := 0.0
		for rc: Color in ramp:
			for tc: Color in tex:
				var c := Color(bm.albedo_color.r * tc.r * rc.r, bm.albedo_color.g * tc.g * rc.g,
						bm.albedo_color.b * tc.b * rc.b)
				var w: float = rc.a * tc.a * bm.albedo_color.a if add else 1.0
				if not bm.vertex_color_use_as_albedo:
					c = Color(bm.albedo_color.r * tc.r, bm.albedo_color.g * tc.g, bm.albedo_color.b * tc.b)
				peak = maxf(peak, _maxc(c) * w)
		if bm.emission_enabled:
			peak += _maxc(bm.emission) * bm.emission_energy_multiplier
		var hdr: bool = _maxc(bm.albedo_color) > 1.0
		var value: float = peak * stack if add else peak
		var cap: float = CAP_ADD if add else CAP_MIX
		var line := "%s [%s%s] peak %.2f -> %.2f / %.2f" % [tag, "add" if add else "mix", " speck" if stack < STACK else "",
				peak, value, cap]
		if not _lines.has(line):
			_lines.append(line)
		if value > cap + 0.001 or hdr:
			_fails.append(line + (" (HDR albedo)" if hdr else ""))


# --- shots: the 4 keeps at 20 % HP, windowed (--gfx=high), the game's world environment

func _run_shots() -> void:
	var env := WorldEnvironment.new()
	var e := (load("res://art/environment/world_env.tres") as Environment).duplicate() as Environment
	env.environment = e
	_world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.shadow_enabled = true
	_world.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.30, 0.34, 0.22)
	gm.roughness = 1.0
	ground.material_override = gm
	_world.add_child(ground)
	var keeps: Array[Node3D] = []
	for i: int in KEEPS.size():
		keeps.append(_keep(KEEPS[i], Vector3(21.0 - 14.0 * i, 0, 0)))
	var cam := Camera3D.new()
	cam.fov = 40.0
	_world.add_child(cam)
	cam.current = true
	await _frames(5)
	for i: int in keeps.size():
		keeps[i].call(&"set_team_color", TEAMS[i % 3] if i < 3 else TEAMS[4])
		keeps[i].call(&"set_tier", 3)
		keeps[i].call(&"set_health_ratio", 0.2)
	await _frames(120)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var q: int = GameSettings.effective_graphics_quality()
	# Row: all four keeps (RTS pitch).
	var focus := Vector3(0, 7.0, 0)
	var pitch := deg_to_rad(50.0)
	cam.look_at_from_position(focus + Vector3(0, sin(pitch) * 62.0, -cos(pitch) * 62.0), focus, Vector3.UP)
	await _frames(3)
	await RenderingServer.frame_post_draw
	_save("%s_q%d_row" % [_tag, q])
	# Close-ups of each keep (the damage effects sit at 7-14 m).
	var names: Array[String] = ["fire", "ice", "nature", "dusk"]
	for i: int in keeps.size():
		var f := keeps[i].position + Vector3(0, 9.0, 0)
		cam.look_at_from_position(f + Vector3(0, sin(pitch) * _near, -cos(pitch) * _near), f, Vector3.UP)
		await _frames(3)
		await RenderingServer.frame_post_draw
		_save("%s_q%d_%s" % [_tag, q, names[i]])
	# The Dusk Keep in every team colour (the rift is fixed violet; the lights follow the team).
	var dusk := keeps[3]
	var f2 := dusk.position + Vector3(0, 10.0, 0)
	cam.look_at_from_position(f2 + Vector3(0, sin(pitch) * 20.0, -cos(pitch) * 20.0), f2, Vector3.UP)
	for t: int in [0, 1, 3, 5]:
		dusk.call(&"set_team_color", TEAMS[t])
		await _frames(4)
		await RenderingServer.frame_post_draw
		_save("%s_q%d_dusk_team%d" % [_tag, q, t])
	quit(0)


func _save(nm: String) -> void:
	var path := "%s/%s.png" % [OUT_DIR, nm]
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("saved %s" % path)

extends SceneTree
## G-F VFX caps (docs/art/gf_vfx_caps.md, review 3 top-6 item 2): the mixed melee showed a white HDR steam blob (the
## Medium+ steam billow + steam_puff at Color(1.5, 1.7, 1.9), drawn at full size since the billboard keep-scale pass).
## Root cause = HDR colours on spell / caster / combat particles. Every particle emitter the VFX makers build (art/vfx,
## scripts/vfx, the Medium+ SpellFxG layer at Ultra) must stay under the keep-damage caps (tests/test_gf_keep_damage.gd):
##   * alpha-blended (MIX): peak max channel <= CAP_MIX (0.72 = MoteCap.VALUE_CAP);
##   * additive (ADD): per-particle peak (rgb x alpha) x STACK (6) <= CAP_ADD (1.0); a speck emitter (drawn size
##     <= SPECK_SIZE m) counts as a stack of 1;
##   * no HDR albedo (> 1.0) on a particle draw material.
## The SpellFxG billows (big noise spheres) follow the same MIX cap when their palette is pale (min / max channel
## >= PALE_RATIO: steam, frost, gold read as a white ball once they pass the glow threshold); saturated fire / void
## palettes keep their hot core (they bloom in their own hue, by design).
## Modes:
##   test:  $GODOT --headless --path . -s tests/test_gf_vfx_caps.gd --fixed-fps 60 --quit-after 3000
##   shots: $GODOT --path . -s tests/test_gf_vfx_caps.gd --resolution 1920x1080 --quit-after 400000 '--' --gfx=high shots=1 tag=after
## Prints "PASS gf_vfx_caps (...)" or "FAIL gf_vfx_caps: <list>".

const TASK_ID := "gf_vfx_caps"
const ROOTS: Array[String] = ["res://art/vfx", "res://scripts/vfx"]
const SKIP_PARTS: Array[String] = ["_preview", "_shots", "/tools/", "unit_vfx.gd", "trade_loot_sack", "spell_fx_g.gd"]
const CAP_MIX := 0.72
const CAP_ADD := 1.0
const STACK := 6.0
const SPECK_SIZE := 0.25
const PALE_RATIO := 0.45
const OUT_DIR := "res://docs/art/lab/gf_vfx_caps"

var _fails: PackedStringArray = PackedStringArray()
var _lines: PackedStringArray = PackedStringArray()
var _notes: PackedStringArray = PackedStringArray()
var _world: Node3D
var _checked := 0
var _emitters_seen := 0
var _args := {}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var s := arg.trim_prefix("--")
		var k := s.get_slice("=", 0)
		_args[k] = s.substr(k.length() + 1)
	if String(_args.get("shots", "0")) != "0":
		_run_shots.call_deferred()
		return
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	_world.add_child(cam)
	cam.current = true
	_run.call_deferred()


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _scripts(dir: String, out: Array[String]) -> Array[String]:
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d: String in DirAccess.get_directories_at(dir):
		_scripts(dir + "/" + d, out)
	return out


func _skip(path: String) -> bool:
	for p: String in SKIP_PARTS:
		if path.contains(p):
			return true
	return false


func _run() -> void:
	var makers: Array[Node] = []
	var paths: Array[String] = []
	for r: String in ROOTS:
		_scripts(r, paths)
	for path: String in paths:
		if _skip(path):
			continue
		var scr := load(path) as GDScript
		if scr == null or not scr.can_instantiate():
			continue
		var base := scr.get_instance_base_type()
		if not ClassDB.is_parent_class(base, &"Node3D"):
			continue
		var n := scr.new() as Node
		n.name = path.get_file().get_basename()
		_world.add_child(n)
		makers.append(n)
	# UnitVfx loads its caster / unit families as children (same nodes, but built the game's way).
	var uv := (load("res://art/vfx/unit_vfx.gd") as GDScript).new() as Node
	uv.name = "unit_vfx"
	_world.add_child(uv)
	makers.append(uv)
	await _frames(3)
	# The Medium+ layer at its biggest tier (headless runs are Low and never build it).
	SpellFxG.test_tier = SpellFxG.TIER_ULTRA
	var g := SpellFxG.live(_world.get_child(0))
	if g == null:
		_fails.append("no SpellFxG at Ultra")
	await _frames(3)
	for m: Node in makers + ([g] as Array[Node] if g else []):
		for e: Node in _emitters(m, []):
			_emitters_seen += 1
			_check(e, "%s %s" % [m.name, _clean(str(m.get_path_to(e)))])
		# pooled makers (CombatVfx) hand their looks to an emitter only when it fires: check each look's pair
		for pm_owner: Node in [m] + m.find_children("*", "", true, false):
			if not pm_owner.has_method(&"look_parts"):
				continue
			var parts: Dictionary = pm_owner.call(&"look_parts")
			for look: StringName in parts:
				var tmp := GPUParticles3D.new()
				tmp.draw_pass_1 = parts[look][0]
				tmp.process_material = parts[look][1]
				_emitters_seen += 1
				_check(tmp, "%s look %s" % [pm_owner.name, look])
				tmp.free()
	if g:
		_check_palettes()
	SpellFxG.test_tier = -1
	if _args.has("verbose"):
		for l: String in _lines:
			print("  ", l)
	for l: String in _notes:
		print("  note: ", l)
	if _checked == 0:
		_fails.append("no VFX particle material found")
	if _fails.is_empty():
		print("PASS %s (%d emitters, %d materials, mix <= %.2f, add x%d <= %.2f, billow palettes)" % [TASK_ID,
				_emitters_seen, _checked, CAP_MIX, int(STACK), CAP_ADD])
	else:
		for f: String in _fails:
			print("  OVER ", f)
		print("FAIL %s: %d over the cap (first: %s)" % [TASK_ID, _fails.size(), _fails[0]])
	quit(0)


## Pool copies share one look: "steam_burst_174" / "@GPUParticles3D@101" -> one line per look.
func _clean(path: String) -> String:
	var re := RegEx.new()
	re.compile("@[A-Za-z0-9]+@[0-9]+")
	var out := re.sub(path, "#", true)
	re.compile("_[0-9]+$")
	var parts := out.split("/")
	for i: int in parts.size():
		parts[i] = re.sub(parts[i], "")
	return "/".join(parts)


func _emitters(n: Node, out: Array) -> Array:
	for c: Node in n.get_children():
		if c is GPUParticles3D or c is CPUParticles3D:
			out.append(c)
		_emitters(c, out)
	return out


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
	var gr: Gradient = null
	if t is GradientTexture2D:
		gr = (t as GradientTexture2D).gradient
	elif t is GradientTexture1D:
		gr = (t as GradientTexture1D).gradient
	if gr:
		for k: int in gr.get_point_count():
			out.append(gr.get_color(k))
	if out.is_empty():
		out.append(Color.WHITE)
	return out


func _ramp_cols(e: Node) -> Array[Color]:
	var out: Array[Color] = []
	var base := Color.WHITE
	var ramp: Texture2D = null
	var inits: Array[Color] = [Color.WHITE]
	if e is GPUParticles3D:
		var pm := (e as GPUParticles3D).process_material as ParticleProcessMaterial
		if pm:
			base = pm.color
			ramp = pm.color_ramp
			# color_initial_ramp picks one colour per particle: the brightest stop is the peak it can reach
			if pm.color_initial_ramp:
				inits = _tex_cols(pm.color_initial_ramp)
	else:
		var cp := e as CPUParticles3D
		base = cp.color
		if cp.color_initial_ramp:
			inits.clear()
			for k: int in cp.color_initial_ramp.get_point_count():
				inits.append(cp.color_initial_ramp.get_color(k))
		if cp.color_ramp:
			for k: int in cp.color_ramp.get_point_count():
				for ic: Color in inits:
					out.append(base * cp.color_ramp.get_color(k) * ic)
			return out
	for c: Color in _tex_cols(ramp) if ramp else ([Color.WHITE] as Array[Color]):
		for ic: Color in inits:
			out.append(base * c * ic)
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


func _minc(c: Color) -> float:
	return minf(c.r, minf(c.g, c.b))


func _check(e: Node, tag: String) -> void:
	var mats := _materials(e)
	if mats.is_empty():
		_notes.append("%s: no draw material" % tag)
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
			_check_shader(m as ShaderMaterial, ramp, stack, tag, e as GeometryInstance3D)
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
					w = tc.a * bm.albedo_color.a if add else 1.0
				peak = maxf(peak, _maxc(c) * w)
		if bm.emission_enabled:
			peak += _maxc(bm.emission) * bm.emission_energy_multiplier
		var hdr: bool = _maxc(bm.albedo_color) > 1.0
		_judge(tag, add, stack, peak, hdr)


## A particle ShaderMaterial: blend from the shader's render_mode; peak = ramp x the colour uniforms x the energy-like
## float uniforms (the VFX particle shaders multiply COLOR by a tint and an energy).
func _check_shader(sm: ShaderMaterial, ramp: Array[Color], stack: float, tag: String, e: GeometryInstance3D) -> void:
	if sm == null or sm.shader == null:
		_notes.append("%s: unmeasured material" % tag)
		return
	var code := sm.shader.code
	var add := code.contains("blend_add")
	if not add and code.contains("instance uniform float additive"):
		# vfx_particle.gdshader (premultiplied): the emitter's `additive` instance uniform picks glow or mix
		var av: Variant = e.get_instance_shader_parameter(&"additive")
		add = av == null or float(av) >= 0.5
	var tint := -1.0
	var energy := 1.0
	for u: Dictionary in sm.shader.get_shader_uniform_list():
		var nm := String(u["name"])
		var v: Variant = sm.get_shader_parameter(nm)
		if v is Color and not nm.contains("smoke") and not nm.contains("fill"):
			tint = maxf(tint, _maxc(v as Color) * ((v as Color).a if add else 1.0))
		elif (v is float) and (nm.contains("energy") or nm.contains("glow") or nm.contains("intensity") or nm == "boost"):
			energy *= maxf(float(v), 0.0)
	var peak := 0.0
	for rc: Color in ramp:
		peak = maxf(peak, _maxc(rc) * (rc.a if add else 1.0))
	peak *= (tint if tint >= 0.0 else 1.0) * energy
	_judge(tag + " (shader %s)" % sm.shader.resource_path.get_file(), add, stack, peak, false)


func _judge(tag: String, add: bool, stack: float, peak: float, hdr: bool) -> void:
	var value: float = peak * stack if add else peak
	var cap: float = CAP_ADD if add else CAP_MIX
	var line := "%s [%s%s] peak %.2f -> %.2f / %.2f" % [tag, "add" if add else "mix", " speck" if stack < STACK else "",
			peak, value, cap]
	if not _lines.has(line):
		_lines.append(line)
	if (value > cap + 0.001 or hdr) and not _fails.has(line + (" (HDR albedo)" if hdr else "")):
		_fails.append(line + (" (HDR albedo)" if hdr else ""))


## SpellFxG billows: a pale palette (steam, frost, gold) must stay under the MIX cap (it reads as a white ball once it
## passes the glow threshold); saturated palettes (fire, molten, void) bloom in their own hue.
func _check_palettes() -> void:
	for id: StringName in SpellFxG.PALETTES:
		var cols: Array = SpellFxG.PALETTES[id]
		for i: int in cols.size():
			var c: Color = cols[i]
			var mx := _maxc(c)
			if mx <= 0.0:
				continue
			var pale := _minc(c) / mx >= PALE_RATIO
			var line := "SpellFxG billow %s[%d] %s max %.2f%s" % [id, i, c, mx, " pale" if pale else ""]
			_lines.append(line)
			if pale and mx > CAP_MIX + 0.001:
				_fails.append(line + " > %.2f" % CAP_MIX)
		_checked += 1


# --- shots: the gf_review3 mixed 4-kingdom melee (skirmish, Fire + Nature vs Ice + Shadow), windowed, --gfx=high

var _main: Node
var _tag := "after"


func _run_shots() -> void:
	_tag = String(_args.get("tag", "after"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for i: int in 3:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		await _frames(4)
	_main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	_main.set(&"player_kingdom", &"fire")
	_main.set(&"enemy_kingdom", &"shadow")
	if &"time_limit_s" in _main:
		_main.set(&"time_limit_s", 0.0)
	root.add_child(_main)
	current_scene = _main
	var t0 := Time.get_ticks_msec()
	while not bool(_main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 300000:
			print("GF SHOTS ERROR: no match")
			quit(1)
			return
	await _wait(1.0)
	var hero: Variant = _main.get(&"hero")
	if hero is Node:
		var sp := StrIntPath.of(hero as Node)
		if sp and not sp.is_locked():
			sp.choose(sp.default_pick())
	for n: Node in root.find_children("*", "", true, false):
		if n is StrIntPanel:
			n.set(&"visible", false)
	var hud: Variant = _main.get(&"hud")
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	var fog: Variant = _main.get(&"fog")
	if fog is Node and &"enabled" in fog:
		(fog as Node).set(&"enabled", false)
	var c := Vector3(-30.0, 0.0, 30.0)
	var units: Array[Unit] = []
	for sd: Array in [[0, ["fire", "nature"]], [1, ["ice", "shadow"]]]:
		var team: int = sd[0]
		var i := 0
		for k: String in sd[1]:
			for id: String in _kingdom_types(k).slice(1, 9):
				var z := 7.0 + float(i / 8) * 2.4
				var pos := c + Vector3((float(i % 8) - 3.5) * 2.2, 0.0, z if team == 0 else -z)
				var u := Worker.make_unit(UnitType.find(id))
				if u:
					u.team = team as Unit.Team
					_main.add_child(u)
					u.set_down(pos)
					u.command_stop()
					u.rotation.y = 0.0 if team == 1 else PI
					u.max_hp = 20000.0
					u.hp = 20000.0
					units.append(u)
				i += 1
	for u: Unit in units:
		if u.has_method(&"command_attack_move"):
			u.call(&"command_attack_move", c)
		else:
			u.command_move(c)
	_cam(c, 30.0)
	await _wait(5.0)
	await _shot("%s_battle_z30" % _tag)
	var n := int(_args.get("extra", "3"))
	for k: int in n:
		await _wait(0.7)
		await _shot("%s_battle_z30_%d" % [_tag, k + 1])
	_cam(c, 14.0)
	await _wait(1.0)
	await _shot("%s_battle_z14" % _tag)
	for k: int in n:
		await _wait(0.7)
		await _shot("%s_battle_z14_%d" % [_tag, k + 1])
	if _args.has("vessa") and hero is Unit:
		# The review's "yellow-white sphere on a Fire unit" = Vessa in the melee: burst of frames while she fights.
		var h := hero as Unit
		h.set_down(c + Vector3(-3.0, 0.0, 4.0))
		var foe: Unit = null
		for u: Unit in units:
			if u.team == Unit.Team.ENEMY and (foe == null or u.global_position.distance_to(h.global_position)
					< foe.global_position.distance_to(h.global_position)):
				foe = u
		if foe:
			h.command_attack(foe)
		_cam(h.global_position, 14.0)
		for k: int in 16:
			await _wait(0.12)
			await _shot("%s_vessa_%02d" % [_tag, k])
	print("GF SHOTS DONE ", _tag)
	quit(0)


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
		(workers if bool(t.get(&"is_worker")) else rest).append(id)
	return workers + rest


func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func _cam(at: Vector3, zoom: float) -> void:
	var cam: Variant = _main.get(&"camera_rig")
	if not (cam is Node3D):
		return
	var rig := cam as Node3D
	rig.set(&"edge_pan_enabled", false)
	rig.rotation = Vector3.ZERO
	rig.call(&"focus_on", at)
	rig.set(&"_zoom", zoom)
	rig.set(&"_target_zoom", zoom)
	rig.call(&"_apply_zoom")
	var cam3 := rig.get(&"camera") as Camera3D
	if cam3:
		cam3.make_current()


func _shot(nm: String) -> void:
	Input.warp_mouse(Vector2(960, 540))
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var p := ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, nm])
	img.save_png(p)
	print("shot ", nm)
	if _args.has("probe"):
		_probe()


## Look-dev aid (probe=1): every emitting particle system over the cap, with its screen position.
func _probe() -> void:
	var cam := root.get_viewport().get_camera_3d()
	for e: Node in root.find_children("*", "GeometryInstance3D", true, false):
		if not (e is GPUParticles3D or e is CPUParticles3D):
			continue
		if not (e as Node3D).is_visible_in_tree():
			continue
		var on: bool = (e as GPUParticles3D).emitting if e is GPUParticles3D else (e as CPUParticles3D).emitting
		if not on:
			continue
		var wp := (e as Node3D).global_position
		if cam.is_position_behind(wp):
			continue
		var sp := cam.unproject_position(wp)
		if sp.x < 0 or sp.y < 0 or sp.x > 1920 or sp.y > 1080:
			continue
		var n0 := _fails.size()
		_check(e, str(e.get_path()).trim_prefix("/root/"))
		for k: int in range(n0, _fails.size()):
			print("  probe (%d, %d) %s" % [int(sp.x), int(sp.y), _fails[k]])
	for m: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if not mi.is_visible_in_tree() or not (mi.material_override is ShaderMaterial):
			continue
		var sh := (mi.material_override as ShaderMaterial).shader
		if sh == null or not sh.resource_path.contains("billow"):
			continue
		var sp2 := cam.unproject_position(mi.global_position)
		print("  probe billow (%d, %d) %s c_hot %s" % [int(sp2.x), int(sp2.y), mi.name, mi.get_instance_shader_parameter(&"c_hot")])

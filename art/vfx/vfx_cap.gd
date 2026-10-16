class_name VfxCap
extends RefCounted
## G-F VFX caps (docs/art/gf_vfx_caps.md, review 3 item 2): every spell / caster / combat particle emitter a VFX maker
## builds goes through `VfxCap.fit(p)` once, at build time (no per-frame cost, same draw calls at every tier).
## It scales the emitter's colour ramp down (hue kept) until it is under the keep-damage caps:
##   * alpha-blended (MIX): peak max channel <= MIX (0.72 = MoteCap.VALUE_CAP);
##   * additive (ADD): per-particle peak (rgb x alpha) x STACK (6) <= ADD (1.0); a speck (drawn size <= SPECK m)
##     counts as a stack of 1 (a lone glint may reach white, never HDR);
##   * a particle draw material never has an HDR albedo (> 1.0).
## tests/test_gf_vfx_caps.gd measures the same thing on every maker's emitters (its own copy of the maths).

const MIX := 0.72
const ADD := 1.0
const STACK := 6.0
const SPECK := 0.25


## Fits one emitter (GPUParticles3D or CPUParticles3D) under the caps. Idempotent: a fitted shared process
## material is left alone by the next emitter that uses it.
static func fit(e: GeometryInstance3D) -> void:
	if e == null:
		return
	for m: Material in _materials(e):
		var bm := m as BaseMaterial3D
		if bm and _maxc(bm.albedo_color) > 1.0:
			var k := 1.0 / _maxc(bm.albedo_color)
			bm.albedo_color = Color(bm.albedo_color.r * k, bm.albedo_color.g * k, bm.albedo_color.b * k, bm.albedo_color.a)
	var r := measure(e)
	if r.is_empty():
		return
	var value: float = r["value"]
	var cap: float = r["cap"]
	if value <= cap + 0.0005:
		return
	var k2 := cap / value
	for m: Material in _materials(e):
		# a lit shard with its own glow: the emission part scales with the colour part (peak = colour + emission)
		var bm := m as BaseMaterial3D
		if bm and bm.emission_enabled:
			bm.emission_energy_multiplier *= k2
	if bool(r["ramp_used"]):
		_scale_ramp(e, k2)
	else:
		# the material ignores the particle colour: scale its own albedo
		for m: Material in _materials(e):
			var bm := m as BaseMaterial3D
			if bm:
				bm.albedo_color = Color(bm.albedo_color.r * k2, bm.albedo_color.g * k2, bm.albedo_color.b * k2,
						bm.albedo_color.a)


## Fits a look whose pooled emitters only get their process material / draw mesh when they fire (CombatVfx):
## a throwaway emitter carries the pair through `fit`.
static func fit_parts(pm: ParticleProcessMaterial, mesh: Mesh) -> void:
	var p := GPUParticles3D.new()
	p.process_material = pm
	p.draw_pass_1 = mesh
	fit(p)
	p.free()


## {value, cap, add, speck, ramp_used} for an emitter ({} when it has no draw material).
static func measure(e: GeometryInstance3D) -> Dictionary:
	var mats := _materials(e)
	if mats.is_empty():
		return {}
	var ramp := _ramp_cols(e)
	var stack: float = STACK if _drawn_size(e) > SPECK else 1.0
	var worst := 0.0
	var worst_cap := MIX
	var add_any := false
	var ramp_used := true
	for m: Material in mats:
		var add := false
		var peak := 0.0
		var bm := m as BaseMaterial3D
		if bm:
			add = BaseMaterial3D.BLEND_MODE_ADD == bm.blend_mode   # (constant first: not an assignment for the fog lint)
			var tex := _tex_cols(bm.albedo_texture)
			ramp_used = bm.vertex_color_use_as_albedo
			for rc: Color in ramp if ramp_used else ([Color.WHITE] as Array[Color]):
				for tc: Color in tex:
					var c := Color(bm.albedo_color.r * tc.r * rc.r, bm.albedo_color.g * tc.g * rc.g,
							bm.albedo_color.b * tc.b * rc.b)
					var w: float = rc.a * tc.a * bm.albedo_color.a if add else 1.0
					peak = maxf(peak, _maxc(c) * w)
			if bm.emission_enabled:
				peak += _maxc(bm.emission) * bm.emission_energy_multiplier
		else:
			var sm := m as ShaderMaterial
			if sm == null or sm.shader == null:
				continue
			add = shader_is_additive(sm, e)
			var tint := -1.0
			var energy := 1.0
			for u: Dictionary in sm.shader.get_shader_uniform_list():
				var nm := String(u["name"])
				var v: Variant = sm.get_shader_parameter(nm)
				if v is Color and not nm.contains("smoke") and not nm.contains("fill"):
					tint = maxf(tint, _maxc(v as Color) * ((v as Color).a if add else 1.0))
				elif (v is float) and (nm.contains("energy") or nm.contains("glow") or nm.contains("intensity") \
						or nm == "boost"):
					energy *= maxf(float(v), 0.0)
			for rc: Color in ramp:
				peak = maxf(peak, _maxc(rc) * (rc.a if add else 1.0))
			peak *= (tint if tint >= 0.0 else 1.0) * energy
		var value: float = peak * stack if add else peak
		var cap: float = ADD if add else MIX
		if value / cap > worst / worst_cap:
			worst = value
			worst_cap = cap
			add_any = add
	return {"value": worst, "cap": worst_cap, "add": add_any, "speck": stack < STACK, "ramp_used": ramp_used}


## A particle shader blends additively when its render_mode says blend_add, or (vfx_particle.gdshader, premultiplied)
## when the emitter's `additive` instance uniform is >= 0.5.
static func shader_is_additive(sm: ShaderMaterial, e: GeometryInstance3D) -> bool:
	var code := sm.shader.code
	if code.contains("blend_add"):
		return true
	if code.contains("instance uniform float additive"):
		var v: Variant = e.get_instance_shader_parameter(&"additive")
		return v == null or float(v) >= 0.5
	return false


static func _materials(e: GeometryInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	if e.material_override:
		out.append(e.material_override)
		return out
	var mesh: Mesh = (e as GPUParticles3D).draw_pass_1 if e is GPUParticles3D else (e as CPUParticles3D).mesh
	if mesh == null:
		return out
	if mesh is PrimitiveMesh and (mesh as PrimitiveMesh).material:
		out.append((mesh as PrimitiveMesh).material)
	for s: int in mesh.get_surface_count():
		var sm := mesh.surface_get_material(s)
		if sm and not out.has(sm):
			out.append(sm)
	return out


static func _tex_cols(t: Texture2D) -> Array[Color]:
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


static func _ramp_cols(e: GeometryInstance3D) -> Array[Color]:
	var out: Array[Color] = []
	var base := Color.WHITE
	var ramp: Array[Color] = [Color.WHITE]
	var inits: Array[Color] = [Color.WHITE]
	if e is GPUParticles3D:
		var pm := (e as GPUParticles3D).process_material as ParticleProcessMaterial
		if pm:
			base = pm.color
			if pm.color_ramp:
				ramp = _tex_cols(pm.color_ramp)
			if pm.color_initial_ramp:
				inits = _tex_cols(pm.color_initial_ramp)
	else:
		var cp := e as CPUParticles3D
		base = cp.color
		if cp.color_ramp:
			ramp.clear()
			for k: int in cp.color_ramp.get_point_count():
				ramp.append(cp.color_ramp.get_color(k))
		if cp.color_initial_ramp:
			inits.clear()
			for k: int in cp.color_initial_ramp.get_point_count():
				inits.append(cp.color_initial_ramp.get_color(k))
	for c: Color in ramp:
		for ic: Color in inits:
			out.append(base * c * ic)
	return out


static func _drawn_size(e: GeometryInstance3D) -> float:
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


## Scales the colour the particles carry (rgb only, alpha and hue kept). A shared ramp texture is copied first so a
## look that was already under the cap elsewhere keeps its colours.
static func _scale_ramp(e: GeometryInstance3D, k: float) -> void:
	if e is GPUParticles3D:
		var pm := (e as GPUParticles3D).process_material as ParticleProcessMaterial
		if pm == null:
			return
		var tex := pm.color_ramp as GradientTexture1D
		if tex and tex.gradient:
			var nt := tex.duplicate() as GradientTexture1D
			nt.gradient = _scaled_gradient(tex.gradient, k)
			pm.color_ramp = nt
		else:
			pm.color = _scaled(pm.color, k)
	else:
		var cp := e as CPUParticles3D
		if cp.color_ramp:
			cp.color_ramp = _scaled_gradient(cp.color_ramp, k)
		else:
			cp.color = _scaled(cp.color, k)


static func _scaled_gradient(g: Gradient, k: float) -> Gradient:
	var ng := g.duplicate() as Gradient
	for i: int in ng.get_point_count():
		ng.set_color(i, _scaled(ng.get_color(i), k))
	return ng


static func _scaled(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, c.a)


static func _maxc(c: Color) -> float:
	return maxf(c.r, maxf(c.g, c.b))

extends SceneTree
## Generates art/buildings/dusk_keep.tscn (Umbral Spire, art-keep.md section 4, polished in task A.8).
## Run WINDOWED (headless drops MultiMesh buffers):
##   Godot --path . -s art/buildings/dusk_keep_build.gd --quit-after 30
## A.8: the stacked drums became one twisted, tapering obsidian needle with dark collars; fins are
## curved thorn blades rising from corner buttresses; a thorn crown cradles the Dusk Eye (with three
## orbiting shards); a secondary watch-needle on one face breaks the symmetry (silhouette rule 0.1);
## glowing lancet windows, cap teeth, a gate arch hood and shard rubble add the small detail level.

const OUT := "res://art/buildings/dusk_keep.tscn"
const KeepScript := preload("res://art/buildings/dusk_keep.gd")
const APOTHEM := 0.866
const VISUAL_SCALE := 1.12
const GROUND_SIZE := 11.0

var keep: Node3D
var model: Node3D
var noise_tex: Texture2D


func _initialize() -> void:
	keep = Node3D.new()
	keep.name = "DuskKeep"
	keep.set_script(KeepScript)
	model = _add(Node3D.new(), keep, "Model")
	noise_tex = load("res://art/shaders/paint_noise.tres")
	var shader: Shader = load("res://art/shaders/painted.gdshader")
	# 3.V2b: a touch more presence (visual only, the 6 x 6 collider is Building's).
	model.scale = Vector3.ONE * VISUAL_SCALE
	# G-E fixes D: wall / obsidian crack glow 0.45 / 0.7 -> 0.3 / 0.45 (violet as accents, not glowing panels)
	var S := _painted(shader, "Stone", Color(0.22, 0.205, 0.255), 0.0, 0.3)
	var O := _painted(shader, "Obsidian", Color(0.11, 0.1, 0.14), 0.35, 0.45)
	var D := _painted(shader, "DarkStone", Color(0.13, 0.12, 0.15), 0.0, 0.0)
	var M := _painted(shader, "Silver", Color(0.37, 0.36, 0.42), 0.55, 0.0)
	var G := ShaderMaterial.new()
	G.resource_name = "Glow"
	G.shader = load("res://art/buildings/dusk_keep_glow.gdshader")
	G.set_shader_parameter("glow_color", Color(0.70, 0.30, 1.00))
	var T := ShaderMaterial.new()
	T.resource_name = "Banner"
	T.shader = load("res://art/buildings/dusk_keep_banner.gdshader")
	var black := StandardMaterial3D.new()
	black.resource_name = "GateVoid"
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color(0.02, 0.01, 0.03)

	# --- Big masses: plinth (one mesh, two steps), battered body, cap --------------------------
	var plinth := _merge([
		[_prism(3.3, 3.3, 0.7, 0.0, 0.0), Transform3D()],
		[_prism(2.9, 2.9, 0.5, 0.0, 0.0), Transform3D(Basis(), Vector3(0, 0.7, 0))]])
	_mesh("Plinth", plinth, Vector3.ZERO, D, 0.0, 1.2)
	_mesh("Body", _prism(2.55, 2.3, 5.0, 0.0, 0.0), Vector3(0, 1.2, 0), S, 1.2, 5.0)
	_mesh("BodyCap", _prism(2.95, 2.75, 0.45, 0.0, 0.0), Vector3(0, 6.15, 0), M, 6.15, 0.45)
	# Corner buttresses (wedges, vertical edge on the body) flowing up into the thorn blades.
	var wedge := PrismMesh.new()
	wedge.left_to_right = 0.0
	wedge.size = Vector3(1.05, 4.75, 0.5)
	var but_xf: Array[Transform3D] = []
	for i: int in 6:
		var r: Vector3 = _dir(30.0 + 60.0 * i)
		var b := Basis(r, Vector3.UP, r.cross(Vector3.UP))
		but_xf.append(Transform3D(b, r * (2.33 + 0.525) + Vector3(0, 0.7 + 4.75 * 0.5, 0)))
	_multi("Buttresses", wedge, but_xf, D, 0.7, 4.75)
	# Cap teeth: six leaning pyramids on the face centres of the cap.
	var tooth := _prism(0.42, 0.0, 1.0, 0.0, 0.0, 4)
	var tooth_xf: Array[Transform3D] = []
	for i: int in 6:
		var r: Vector3 = _dir(60.0 * i)
		var b := Basis(r.cross(Vector3.UP).normalized(), deg_to_rad(-14.0)) * Basis(Vector3.UP, PI / 4.0)
		tooth_xf.append(Transform3D(b, r * 2.35 + Vector3(0, 6.5, 0)))
	var teeth := _multi("CapTeeth", tooth, tooth_xf, O, 6.5, 1.0)
	teeth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# --- The twisted needle: segments share their end rings so the taper is continuous ----------
	_mesh("Prism1", _prism(2.0, 1.72, 2.5, 0.0, 16.0), Vector3(0, 6.2, 0), O, 6.2, 9.8)
	_mesh("Prism2", _prism(1.72, 1.3, 2.5, 16.0, 34.0), Vector3(0, 8.7, 0), O, 6.2, 9.8)
	_mesh("Prism3", _prism(1.3, 0.86, 2.5, 34.0, 52.0), Vector3(0, 11.2, 0), O, 6.2, 9.8)
	_mesh("Tip", _prism(0.86, 0.0, 1.6, 52.0, 70.0), Vector3(0, 13.7, 0), O, 6.2, 9.8)
	# Dark silver collars at the joints (one draw call).
	var bands := _merge([
		[_prism(1.9, 1.9, 0.26, 16.0, 16.0), Transform3D(Basis(), Vector3(0, 8.57, 0))],
		[_prism(1.46, 1.46, 0.26, 34.0, 34.0), Transform3D(Basis(), Vector3(0, 11.07, 0))],
		[_prism(1.02, 1.02, 0.24, 52.0, 52.0), Transform3D(Basis(), Vector3(0, 13.58, 0))]])
	var sb := _mesh("SpireBands", bands, Vector3.ZERO, M, 6.0, 9.0)
	sb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Lancet windows: six glowing slits on the lower needle ("something is watching").
	var win := BoxMesh.new()
	win.size = Vector3(0.16, 1.25, 0.06)
	var win_xf: Array[Transform3D] = []
	for i: int in 6:
		var r: Vector3 = _dir(60.0 * i + 8.0)
		var tilt := Basis(r.cross(Vector3.UP).normalized(), deg_to_rad(-6.5))
		win_xf.append(Transform3D(tilt * Basis(Vector3.UP, atan2(-r.x, -r.z)), r * 1.62 + Vector3(0, 7.35, 0)))
	var wins := _multi("Windows", win, win_xf, G, 0, 1)
	wins.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wins.set_instance_shader_parameter("energy", 1.0)   # G-E fixes D: accents (was 2.2; under the glow cap knee)
	wins.set_instance_shader_parameter("pulse_speed", 1.1)
	# Thorn crown around the tip: three curved blades cradling the floating eye.
	var thorn := _blade(0.26, 0.5, 2.3, 0.45)
	var thorn_xf: Array[Transform3D] = []
	for i: int in 3:
		var r: Vector3 = _dir(20.0 + 120.0 * i)
		var b := Basis(Vector3.UP.cross(r), Vector3.UP, r) * Basis(Vector3.RIGHT, deg_to_rad(24.0))
		thorn_xf.append(Transform3D(b, r * 0.72 + Vector3(0, 13.35, 0)))
	var th := _multi("Thorns", thorn, thorn_xf, O, 12.0, 4.0)
	th.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# --- Thorn blades (fins) on the corners + their glowing crystal tips -------------------------
	var fin_mm := _multi("Fins", _blade(0.46, 1.05, KeepScript.FIN_LEN, KeepScript.FIN_CURVE), [], O, 5.4, 4.6)
	var fm: MultiMesh = fin_mm.multimesh
	fm.instance_count = 6
	var tip_mm := _multi("FinTips", _octahedron(0.24, 0.42), [], G, 0, 1)
	tip_mm.multimesh.instance_count = 6
	for i: int in 6:
		fm.set_instance_transform(i, KeepScript.fin_xf(i, KeepScript.FIN_TILT))
		tip_mm.multimesh.set_instance_transform(i, KeepScript.fin_tip_xf(i, KeepScript.FIN_TILT))
	tip_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tip_mm.set_instance_shader_parameter("energy", 1.2)   # G-E fixes D (was 3.0)
	tip_mm.set_instance_shader_parameter("pulse_speed", 2.0)

	# --- Watch-needle: the asymmetric secondary element on face 180 (opposite the gate: always side-on) --
	var wn := _dir(KeepScript.NEEDLE_FACE)
	var wpos: Vector3 = wn * 2.42
	var watch := _merge([
		[_prism(0.72, 0.52, 9.4, 0.0, 28.0), Transform3D()],
		[_prism(0.52, 0.0, 1.9, 28.0, 44.0), Transform3D(Basis(), Vector3(0, 9.4, 0))]])
	_mesh("WatchNeedle", watch, wpos, O, 0.0, 11.3)
	var collar := _merge([
		[_prism(0.86, 0.86, 0.3, 0.0, 0.0), Transform3D(Basis(), Vector3(0, 6.35, 0))],
		[_prism(0.68, 0.68, 0.28, 28.0, 28.0), Transform3D(Basis(), Vector3(0, 9.25, 0))]])
	var wc := _mesh("WatchCollars", collar, Vector3.ZERO, M, 6.0, 4.0)
	wc.owner = null
	wc.reparent(model.get_node("WatchNeedle"), false)
	wc.owner = keep
	wc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# --- Floating Dusk Eye: shard + core + three orbiting splinters -----------------------------
	var shard: Node3D = _add(Node3D.new(), model, "Shard")
	shard.position = Vector3(0, KeepScript.SHARD_Y, 0)
	var oct := MeshInstance3D.new()
	oct.mesh = _octahedron(0.55, 1.05)
	oct.material_override = O
	_add(oct, shard, "ShardMesh")
	oct.set_instance_shader_parameter("ao_bottom", 15.5)
	oct.set_instance_shader_parameter("ao_height", 2.0)
	var core := MeshInstance3D.new()
	core.mesh = _sphere(0.38)
	core.material_override = G
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(core, shard, "ShardCore")
	core.set_instance_shader_parameter("energy", 3.2)   # G-E fixes D (was 4.0)
	core.set_instance_shader_parameter("pulse_speed", 3.1)
	var orbit: Node3D = _add(Node3D.new(), shard, "EyeOrbit")
	var spl_xf: Array[Transform3D] = []
	for i: int in 3:
		var a: float = TAU * float(i) / 3.0
		spl_xf.append(Transform3D(Basis(Vector3(cos(a), 0, sin(a)), 0.5), Vector3(cos(a) * 1.25, 0.35 * sin(a * 2.0), sin(a) * 1.25)))
	var spl := _multi("EyeShards", _octahedron(0.16, 0.36), spl_xf, O, 15.0, 3.0, orbit)
	spl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Rune ring
	var torus := TorusMesh.new()
	torus.inner_radius = 3.03   # G-E fixes D: a thinner band (was 2.95 / 3.25)
	torus.outer_radius = 3.19
	torus.rings = 48
	torus.ring_segments = 6
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.material_override = G
	ring.position = Vector3(0, 6.95, 0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(ring, model, "RuneRing")
	ring.set_instance_shader_parameter("energy", 1.0)   # G-E fixes D (was 3.0; DuskKeep.RING_ENERGY)
	ring.set_instance_shader_parameter("pulse_speed", 1.3)
	ring.set_instance_shader_parameter("rune_bands", 12)

	# --- Gate (-Z face): void arch, glowing slits, silver frame + pointed hood ------------------
	var arch := BoxMesh.new()
	arch.size = Vector3(1.6, 3.2, 0.3)
	var peak := PrismMesh.new()
	peak.size = Vector3(1.6, 0.9, 0.3)
	var void_mesh := _merge([[arch, Transform3D(Basis(), Vector3(0, 2.8, 0))], [peak, Transform3D(Basis(), Vector3(0, 4.85, 0))]])
	var gv := _mesh("GateArch", void_mesh, Vector3(0, 0, -2.13), black)
	gv.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var slit := BoxMesh.new()
	slit.size = Vector3(0.09, 2.6, 0.06)
	var slits := _multi("GateSlits", slit, [Transform3D(Basis(), Vector3(-0.55, 2.6, -2.31)), Transform3D(Basis(), Vector3(0.55, 2.6, -2.31)),
		Transform3D(Basis(Vector3.FORWARD, PI / 4.0) * Basis.from_scale(Vector3(3.6, 0.14, 1.0)), Vector3(0, 4.95, -2.33))], G, 0, 1)
	slits.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	slits.set_instance_shader_parameter("energy", 1.2)   # G-E fixes D (was 2.5)
	slits.set_instance_shader_parameter("pulse_speed", 1.0)
	# Frame pillars + two slanted ribs meeting in a point above the arch (one mesh, silver).
	var pillar := BoxMesh.new()
	pillar.size = Vector3(0.28, 3.7, 0.45)
	var rib := BoxMesh.new()
	rib.size = Vector3(0.26, 1.55, 0.42)
	var ang: float = atan2(1.0, 1.05)
	var frame := _merge([
		[pillar, Transform3D(Basis(), Vector3(-1.0, 3.05, 0))], [pillar, Transform3D(Basis(), Vector3(1.0, 3.05, 0))],
		[rib, Transform3D(Basis(Vector3.BACK, -ang), Vector3(-0.5, 5.35, 0))],
		[rib, Transform3D(Basis(Vector3.BACK, ang), Vector3(0.5, 5.35, 0))]])
	_mesh("GateFrame", frame, Vector3(0, 0, -2.3), M, 1.2, 4.9)
	# Banners on faces 60, 120, 300 deg from -Z
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.85, 3.1)
	plane.orientation = PlaneMesh.FACE_Z
	plane.subdivide_width = 3
	plane.subdivide_depth = 12
	var bi: int = 0
	for deg: float in [60.0, 120.0, 300.0]:
		var n: Vector3 = _dir(deg)
		var mi := MeshInstance3D.new()
		mi.mesh = plane
		mi.material_override = T
		# Body is battered (apothem 2.21 at the bottom, 1.99 at the top): the cloth leans with the wall.
		var n2: Vector3 = (n + Vector3.UP * 0.044).normalized()
		var up2: Vector3 = (Vector3.UP - n * 0.044).normalized()
		mi.transform = Transform3D(Basis.looking_at(-n2, up2), n * (2.08 + 0.12) + Vector3(0, 4.25, 0))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bi += 1
		_add(mi, model, "Banner%d" % bi)
		mi.set_instance_shader_parameter("phase", float(bi) * 2.1)
	# Soul lanterns: stems beside the gate and on face 240; the second orb crowns the watch-needle.
	var stem_xf: Array[Transform3D] = [Transform3D(Basis(), Vector3(1.55, 1.8, -2.35)), Transform3D(Basis(), _dir(240.0) * 2.4 + Vector3(0, 1.8, 0))]
	var stem := CylinderMesh.new()
	stem.top_radius = 0.1
	stem.bottom_radius = 0.18
	stem.height = 1.2
	stem.radial_segments = 6
	stem.rings = 1
	var stems := _multi("LanternStems", stem, stem_xf, M, 1.2, 1.2)
	stems.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var orb_mesh := _sphere(0.26)
	for i: int in 3:
		var o := MeshInstance3D.new()
		o.mesh = orb_mesh
		o.material_override = G
		o.position = KeepScript.orb_pos(i)
		o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(o, model, "LanternOrb%d" % (i + 1))
		o.set_instance_shader_parameter("energy", 1.6)   # G-E fixes D (was 3.0)
		o.set_instance_shader_parameter("pulse_speed", 2.0)
		o.set_instance_shader_parameter("phase", float(i) * 1.7)
	# Rubble: "broken teeth" (4-sided obsidian-dark shards) around the base.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var rub_xf: Array[Transform3D] = []
	for i: int in 14:
		var a: float = TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / 14.0 + 0.3
		var rad: float = rng.randf_range(3.35, 4.1)
		var sc: float = rng.randf_range(0.7, 1.35)
		var out := Vector3(cos(a), 0, sin(a))
		var bb := Basis(out.cross(Vector3.UP).normalized(), deg_to_rad(-rng.randf_range(12.0, 38.0))) * Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(sc, sc * rng.randf_range(0.8, 1.4), sc))
		rub_xf.append(Transform3D(bb, out * rad + Vector3(0, -0.15, 0)))
	var rub := _multi("Rubble", _prism(0.32, 0.0, 1.1, 0.0, 0.0, 4), rub_xf, D, -0.3, 1.0)
	rub.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Rubble2: the broken blades' shards (blades 1 and 4 point +x / -x), shown under 50 % HP.
	var rub2_xf: Array[Transform3D] = []
	for side: float in [1.0, -1.0]:
		for j: int in 3:
			var bb2 := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(50.0, 80.0)))
			rub2_xf.append(Transform3D(bb2, Vector3(side * rng.randf_range(3.3, 4.2), 0.2, rng.randf_range(-1.4, 1.4))))
	var r2 := _multi("Rubble2", _blade(0.35, 0.8, 1.6, 0.2), rub2_xf, O, -0.4, 1.0)
	r2.visible = false
	# Contact decal (not under Model: stays flat during construction): void stain, radial cracks, runes.
	var decal := MeshInstance3D.new()
	var dplane := PlaneMesh.new()
	dplane.size = Vector2(GROUND_SIZE, GROUND_SIZE)
	decal.mesh = dplane
	decal.position = Vector3(0, 0.03, 0)
	decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dmat := ShaderMaterial.new()
	dmat.resource_name = "VoidGround"
	dmat.shader = load("res://art/buildings/dusk_keep_ground.gdshader")
	dmat.set_shader_parameter("size", GROUND_SIZE)
	decal.material_override = dmat
	_add(decal, keep, "ContactDecal")
	# Construction outline: flat glowing square ring 6.4 x 6.4, 0.2 thick (8.2), hidden when built.
	var outline := MeshInstance3D.new()
	outline.mesh = _square_ring(3.2, 0.2)
	outline.material_override = G
	outline.position = Vector3(0, 0.05, 0)
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outline.visible = false
	_add(outline, keep, "Outline")
	outline.set_instance_shader_parameter("energy", 2.0)
	outline.set_instance_shader_parameter("pulse_speed", TAU)
	# lights
	var sl := OmniLight3D.new()
	sl.position = Vector3(0, 7.0, 0)
	sl.light_color = Color(0.60, 0.30, 1.00)
	sl.light_energy = 2.0
	sl.omni_range = 14.0
	sl.light_specular = 0.2
	sl.shadow_enabled = false
	_add(sl, keep, "SpireLight")
	var gl := OmniLight3D.new()
	gl.position = Vector3(0, 2.5, -3.4)
	gl.light_color = Color(0.70, 0.30, 1.00)
	gl.light_energy = 1.2
	gl.omni_range = 6.0
	gl.light_specular = 0.2
	gl.shadow_enabled = false
	_add(gl, keep, "GateLight")
	# particles (7.2)
	var soft := _radial([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)], [0.0, 0.35, 1.0])
	var add_mat := _particle_mat(soft, BaseMaterial3D.BLEND_MODE_ADD, "ParticleAdd")
	var mix_mat := _particle_mat(soft, BaseMaterial3D.BLEND_MODE_MIX, "ParticleMix")
	var motes := _particles("VoidMotes", keep, 50, 5.0, add_mat, 0.16)
	motes.position = Vector3(0, 1.0, 0)
	var mp := motes.process_material as ParticleProcessMaterial
	mp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mp.emission_ring_axis = Vector3.UP
	mp.emission_ring_radius = 3.1
	mp.emission_ring_inner_radius = 2.2
	mp.emission_ring_height = 0.2
	mp.direction = Vector3.UP
	mp.spread = 10.0
	mp.initial_velocity_min = 0.45
	mp.initial_velocity_max = 0.9
	mp.scale_curve = _curve(1.0, 0.55)
	mp.color_ramp = _grad([Color(0.70, 0.30, 1.00, 1), Color(0.30, 0.10, 0.50, 0.8), Color(0.30, 0.10, 0.50, 0)], [0.0, 0.7, 1.0])
	motes.visibility_aabb = AABB(Vector3(-5, -1, -5), Vector3(10, 8, 10))
	var mist := _particles("GroundMist", keep, 14, 6.0, mix_mat, 2.6)
	mist.position = Vector3(0, 0.35, 0)
	mist.sorting_offset = 1.0
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var gp := mist.process_material as ParticleProcessMaterial
	gp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	gp.emission_ring_axis = Vector3.UP
	gp.emission_ring_radius = 3.4
	gp.emission_ring_inner_radius = 1.8
	gp.emission_ring_height = 0.1
	gp.radial_velocity_min = 0.2
	gp.radial_velocity_max = 0.25
	gp.initial_velocity_min = 0.0
	gp.initial_velocity_max = 0.0
	gp.scale_curve = _curve(0.5, 1.0)
	gp.color_ramp = _grad([Color(0.22, 0.10, 0.34, 0), Color(0.22, 0.10, 0.34, 0.5), Color(0.22, 0.10, 0.34, 0)], [0.0, 0.3, 1.0])
	mist.visibility_aabb = AABB(Vector3(-7, -1, -7), Vector3(14, 4, 14))
	var sparks := _particles("ShardSparks", shard, 20, 1.4, add_mat, 0.12)
	var sp := sparks.process_material as ParticleProcessMaterial
	sp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.5
	sp.radial_velocity_min = 0.3
	sp.radial_velocity_max = 0.5
	sp.gravity = Vector3(0, -0.9, 0)
	sp.scale_curve = _curve(1.0, 0.4)
	sp.color_ramp = _grad([Color(0.90, 0.60, 1.00, 1), Color(0.90, 0.60, 1.00, 0)], [0.0, 1.0])
	sparks.visibility_aabb = AABB(Vector3(-2, -3, -2), Vector3(4, 5, 4))

	# --- 3.V2 state particles (7.3). Positions are in keep space (x VISUAL_SCALE). ---
	var k := VISUAL_SCALE
	# Second mist emitter: switched on by the collapse ("mist doubles and stays").
	var mist2 := mist.duplicate() as GPUParticles3D
	mist2.emitting = false
	mist2.preprocess = 0.0
	_add(mist2, keep, "GroundMist2")
	for s: Array in [["Smoke1", Vector3(-1.6, 6.5, 1.2)], ["Smoke2", Vector3(1.4, 10.5, -0.8)]]:
		var sm := _particles(s[0], keep, 30, 3.5, mix_mat, 2.6)
		sm.position = s[1] * k
		sm.emitting = false
		sm.preprocess = 0.0
		sm.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 14, 8))
		var smp := sm.process_material as ParticleProcessMaterial
		smp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		smp.emission_sphere_radius = 0.4
		smp.direction = Vector3.UP
		smp.spread = 12.0
		smp.initial_velocity_min = 1.0
		smp.initial_velocity_max = 1.6
		smp.gravity = Vector3(0.25, 0, 0)
		smp.scale_curve = _curve(0.27, 1.0)
		smp.color_ramp = _grad([Color(0.10, 0.07, 0.13, 0.0), Color(0.10, 0.07, 0.13, 0.7), Color(0.14, 0.11, 0.18, 0.0)], [0.0, 0.1, 1.0])
	for s: Array in [["Rift1", Vector3(-1.2, 7.0, 1.4)], ["Rift2", Vector3(0.6, 12.0, -0.8)]]:
		var rf := _particles(s[0], keep, 24, 1.0, add_mat, 0.9)
		rf.position = s[1] * k
		rf.emitting = false
		rf.preprocess = 0.0
		rf.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
		var rfp := rf.process_material as ParticleProcessMaterial
		rfp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		rfp.emission_sphere_radius = 0.35
		rfp.direction = Vector3.UP
		rfp.spread = 15.0
		rfp.initial_velocity_min = 1.2
		rfp.initial_velocity_max = 2.0
		rfp.scale_curve = _curve(1.0, 0.33)
		rfp.color_ramp = _grad([Color(0.45, 0.25, 0.55, 1.0), Color(0.33, 0.13, 0.5, 1.0), Color(0.12, 0.04, 0.2, 0.6), Color(0.1, 0.03, 0.17, 0.0)], [0.0, 0.3, 0.75, 1.0])
	# TrainBurst: one-shot, 72 particles; the training pulse uses 1/3 of them (amount_ratio),
	# the shard burst all of them. The script moves it and sets its direction per use.
	var tb := _particles("TrainBurst", keep, 72, 0.8, add_mat, 0.15)
	tb.one_shot = true
	tb.explosiveness = 1.0
	tb.emitting = false
	tb.preprocess = 0.0
	tb.position = Vector3(0, 2.0, -2.8) * k
	tb.visibility_aabb = AABB(Vector3(-5, -5, -5), Vector3(10, 10, 10))
	var tbp := tb.process_material as ParticleProcessMaterial
	tbp.direction = Vector3(0, 0, -1)
	tbp.spread = 60.0
	tbp.initial_velocity_min = 2.0
	tbp.initial_velocity_max = 4.0
	tbp.gravity = Vector3(0, -1.5, 0)
	tbp.scale_curve = _curve(1.0, 0.33)
	tbp.color_ramp = _grad([Color(1, 1, 1, 1), Color(1, 1, 1, 0)], [0.0, 1.0])
	tbp.color = Color(0.70, 0.30, 1.00)
	# BuildRing: team-colour sparks along the construction outline.
	var br := _particles("BuildRing", keep, 40, 1.2, add_mat, 0.12)
	br.emitting = false
	br.preprocess = 0.0
	br.position = Vector3(0, 0.1, 0)
	br.visibility_aabb = AABB(Vector3(-5, -1, -5), Vector3(10, 4, 10))
	var brp := br.process_material as ParticleProcessMaterial
	brp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	brp.emission_ring_axis = Vector3.UP
	brp.emission_ring_radius = 3.6
	brp.emission_ring_inner_radius = 3.3
	brp.emission_ring_height = 0.05
	brp.direction = Vector3.UP
	brp.spread = 10.0
	brp.initial_velocity_min = 0.8
	brp.initial_velocity_max = 1.4
	brp.scale_curve = _curve(1.0, 0.33)
	brp.color_ramp = _grad([Color(1, 1, 1, 1), Color(1, 1, 1, 0)], [0.0, 1.0])
	brp.color = Color(0.70, 0.30, 1.00)
	# CollapseDust: one-shot, 60 big dust puffs, stone colour x 0.8.
	var cd := _particles("CollapseDust", keep, 60, 2.5, mix_mat, 3.0)
	cd.one_shot = true
	cd.explosiveness = 0.9
	cd.emitting = false
	cd.preprocess = 0.0
	cd.position = Vector3(0, 6.4, 0) * k
	cd.visibility_aabb = AABB(Vector3(-8, -8, -8), Vector3(16, 16, 16))
	var cdp := cd.process_material as ParticleProcessMaterial
	cdp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	cdp.emission_sphere_radius = 1.5
	cdp.direction = Vector3.UP
	cdp.spread = 90.0
	cdp.initial_velocity_min = 1.0
	cdp.initial_velocity_max = 3.0
	cdp.damping_min = 1.5
	cdp.damping_max = 2.5
	cdp.scale_curve = _curve(0.33, 1.0)
	cdp.color_ramp = _grad([Color(0.18, 0.15, 0.22, 0.6), Color(0.16, 0.14, 0.2, 0.0)], [0.0, 1.0])
	# Debris: the falling needle breaks into 10 tumbling obsidian splinters (mesh particles).
	var db := GPUParticles3D.new()
	db.amount = 10
	db.lifetime = 1.8
	db.one_shot = true
	db.explosiveness = 0.85
	db.emitting = false
	db.fixed_fps = 30
	db.interpolate = true
	db.local_coords = true
	db.position = Vector3(0, 8.0, 0) * k
	db.draw_pass_1 = _prism(0.3, 0.0, 1.2, 0.0, 0.0, 4)
	db.material_override = O
	db.visibility_aabb = AABB(Vector3(-9, -10, -9), Vector3(18, 16, 18))
	var dbp := ParticleProcessMaterial.new()
	dbp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	dbp.emission_sphere_radius = 1.4
	dbp.direction = Vector3.UP
	dbp.spread = 80.0
	dbp.initial_velocity_min = 2.5
	dbp.initial_velocity_max = 5.5
	dbp.gravity = Vector3(0, -12.0, 0)
	dbp.particle_flag_rotate_y = true
	dbp.angle_min = 0.0
	dbp.angle_max = 360.0
	dbp.angular_velocity_min = -300.0
	dbp.angular_velocity_max = 300.0
	dbp.scale_min = 0.8
	dbp.scale_max = 1.6
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(0.75, 1))
	sc.add_point(Vector2(1, 0))
	var sct := CurveTexture.new()
	sct.curve = sc
	dbp.scale_curve = sct
	db.process_material = dbp
	_add(db, keep, "Debris")
	db.set_instance_shader_parameter("ao_bottom", 0.0)
	db.set_instance_shader_parameter("ao_height", 8.0)

	var ps := PackedScene.new()
	var err := ps.pack(keep)
	if err == OK:
		err = ResourceSaver.save(ps, OUT)
	print("dusk_keep_build: saved ", OUT, " err=", err, " fins=", fm.instance_count)
	keep.free()
	quit(0)


# --- helpers ---------------------------------------------------------------------------------

## Horizontal unit vector at `deg` degrees from -Z toward +X (the art-keep.md face convention).
func _dir(deg: float) -> Vector3:
	var th: float = deg_to_rad(deg)
	return Vector3(sin(th), 0.0, -cos(th))


func _add(n: Node, parent: Node, nm: String) -> Node:
	n.name = nm
	parent.add_child(n)
	if n != keep:
		n.owner = keep
	return n


func _painted(shader: Shader, nm: String, c: Color, spec: float, crack: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.resource_name = nm
	m.shader = shader
	m.set_shader_parameter("base_color", c)
	m.set_shader_parameter("noise_tex", noise_tex)
	m.set_shader_parameter("spec_strength", spec)
	m.set_shader_parameter("crack_strength", crack)
	m.set_shader_parameter("crack_color", Color(0.70, 0.30, 1.00))
	m.set_shader_parameter("crack_speed", 0.7)
	m.set_shader_parameter("crack_scale", 1.8) # fewer, bigger veins: keeps the 40 m read to a few glow points
	return m


func _mesh(nm: String, mesh: Mesh, pos: Vector3, mat: Material, ao_b: float = -1000.0, ao_h: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	_add(mi, model, nm)
	if ao_b > -999.0:
		mi.set_instance_shader_parameter("ao_bottom", ao_b)
		mi.set_instance_shader_parameter("ao_height", ao_h)
	return mi


func _multi(nm: String, mesh: Mesh, xfs: Array, mat: Material, ao_b: float, ao_h: float, parent: Node = null) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i: int in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	_add(mmi, parent if parent else model, nm)
	mmi.set_instance_shader_parameter("ao_bottom", ao_b)
	mmi.set_instance_shader_parameter("ao_height", ao_h)
	return mmi


## Bakes several [mesh, transform] pairs (one surface each) into one ArrayMesh = one draw call.
func _merge(parts: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p: Array in parts:
		st.append_from(p[0] as Mesh, 0, p[1] as Transform3D)
	return st.commit()


## Faceted prism from y 0 to h, `sides` sides (a flat face toward -Z), corner radius r0 at the
## bottom and r1 at the top, twisted from tw0 to tw1 degrees. r1 = 0 makes a pointed cone. Flat-shaded.
func _prism(r0: float, r1: float, h: float, tw0: float, tw1: float, sides: int = 6) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step: float = 360.0 / float(sides)
	var bot: Array[Vector3] = []
	var top: Array[Vector3] = []
	for i: int in sides:
		var a0: float = deg_to_rad(step * 0.5 + step * i + tw0 - 90.0)
		var a1: float = deg_to_rad(step * 0.5 + step * i + tw1 - 90.0)
		bot.append(Vector3(cos(a0) * r0, 0.0, sin(a0) * r0))
		top.append(Vector3(cos(a1) * r1, h, sin(a1) * r1))
	var c_top := Vector3(0, h, 0)
	for i: int in sides:
		var j: int = (i + 1) % sides
		var u0: float = float(i) / float(sides)
		var u1: float = float(i + 1) / float(sides)
		st.set_uv(Vector2(u0, 1)); st.add_vertex(bot[i])
		st.set_uv(Vector2(u1, 1)); st.add_vertex(bot[j])
		st.set_uv(Vector2(u1, 0)); st.add_vertex(top[j])
		if r1 > 0.0:
			st.set_uv(Vector2(u0, 1)); st.add_vertex(bot[i])
			st.set_uv(Vector2(u1, 0)); st.add_vertex(top[j])
			st.set_uv(Vector2(u0, 0)); st.add_vertex(top[i])
			st.set_uv(Vector2(u0, 0)); st.add_vertex(top[i])
			st.set_uv(Vector2(u1, 0)); st.add_vertex(top[j])
			st.set_uv(Vector2(0.5, 0)); st.add_vertex(c_top)
		st.set_uv(Vector2(u0, 1)); st.add_vertex(bot[i])
		st.set_uv(Vector2(0.5, 1)); st.add_vertex(Vector3.ZERO)
		st.set_uv(Vector2(u1, 1)); st.add_vertex(bot[j])
	st.generate_normals()
	return st.commit()


## Curved thorn blade from y 0 to h: a rhombus cross-section (w_tan across, w_rad deep along +Z)
## that tapers to a point and bends `curve` metres toward +Z at the top. Flat-shaded.
func _blade(w_tan: float, w_rad: float, h: float, curve: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	var n: int = 4
	for k: int in n + 1:
		var t: float = float(k) / float(n)
		var s: float = pow(1.0 - t, 0.85)
		var c := Vector3(0, t * h, curve * t * t)
		rings.append([c + Vector3(0, 0, w_rad * 0.5 * s), c + Vector3(w_tan * 0.5 * s, 0, 0),
			c + Vector3(0, 0, -w_rad * 0.5 * s), c + Vector3(-w_tan * 0.5 * s, 0, 0)])
	for k: int in n:
		var lo: Array = rings[k]
		var hi: Array = rings[k + 1]
		for i: int in 4:
			var j: int = (i + 1) % 4
			st.add_vertex(lo[i]); st.add_vertex(lo[j]); st.add_vertex(hi[j])
			if k < n - 1:
				st.add_vertex(lo[i]); st.add_vertex(hi[j]); st.add_vertex(hi[i])
	for i: int in 4:
		var j: int = (i + 1) % 4
		st.add_vertex(rings[0][i]); st.add_vertex(Vector3.ZERO); st.add_vertex(rings[0][j])
	st.generate_normals()
	return st.commit()


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


func _octahedron(r: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var eq: Array[Vector3] = [Vector3(r, 0, 0), Vector3(0, 0, r), Vector3(-r, 0, 0), Vector3(0, 0, -r)]
	var top := Vector3(0, h, 0)
	var bot := Vector3(0, -h, 0)
	for i: int in 4:
		var a: Vector3 = eq[i]
		var b: Vector3 = eq[(i + 1) % 4]
		st.add_vertex(top); st.add_vertex(b); st.add_vertex(a)
		st.add_vertex(bot); st.add_vertex(a); st.add_vertex(b)
	st.generate_normals()
	return st.commit()


## Flat square ring (outer half-size h, thickness w) in the XZ plane, facing up.
func _square_ring(h: float, w: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var o: Array[Vector3] = [Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h)]
	var i_: Array[Vector3] = []
	for v: Vector3 in o:
		i_.append(v - v.normalized() * w * sqrt(2.0))
	for s: int in 4:
		var a: Vector3 = o[s]
		var b: Vector3 = o[(s + 1) % 4]
		var c: Vector3 = i_[(s + 1) % 4]
		var d: Vector3 = i_[s]
		st.set_uv(Vector2(0, 0)); st.add_vertex(a)
		st.set_uv(Vector2(1, 0)); st.add_vertex(b)
		st.set_uv(Vector2(1, 1)); st.add_vertex(c)
		st.set_uv(Vector2(0, 0)); st.add_vertex(a)
		st.set_uv(Vector2(1, 1)); st.add_vertex(c)
		st.set_uv(Vector2(0, 1)); st.add_vertex(d)
	return st.commit()


func _grad(cols: Array, offs: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(cols)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _radial(cols: Array, offs: Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(cols)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


func _curve(a: float, b: float) -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0, a))
	c.add_point(Vector2(1, b))
	var t := CurveTexture.new()
	t.curve = c
	return t


func _particle_mat(tex: Texture2D, blend: int, nm: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = nm
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = blend
	m.disable_fog = blend == BaseMaterial3D.BLEND_MODE_ADD  # G-E 5: an additive quad must not fog
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	if blend == BaseMaterial3D.BLEND_MODE_ADD:
		m.albedo_color = Color(3.0, 3.0, 3.0, 1.0) # HDR so motes reach the bloom threshold
	return m


func _particles(nm: String, parent: Node, amount: int, life: float, mat: Material, size: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.fixed_fps = 30
	p.interpolate = true
	p.local_coords = true
	p.preprocess = life
	var pm := ParticleProcessMaterial.new()
	pm.gravity = Vector3.ZERO
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = mat
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(p, parent, nm)
	return p

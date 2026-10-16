extends SceneTree
## Generates art/buildings/ice_keep.tscn (Rime Keep, kingdom-ice.md 8.1 + art-keep.md section 0 / 6-8).
## Run WINDOWED (headless drops MultiMesh buffers):
##   Godot --path . -s art/buildings/ice_keep_build.gd --quit-after 30

const OUT := "res://art/buildings/ice_keep.tscn"
const KeepScript := preload("res://art/buildings/ice_keep.gd")
const GROUND_SIZE := 12.5
const TEAM := Color(0.45, 0.75, 0.95)
const GLOW := Color(0.75, 0.92, 1.00)

var keep: Node3D
var model: Node3D
var noise_tex: Texture2D


func _initialize() -> void:
	keep = Node3D.new()
	keep.name = "IceKeep"
	keep.set_script(KeepScript)
	model = _add(Node3D.new(), keep, "Model")
	noise_tex = load("res://art/shaders/paint_noise.tres")
	var shader: Shader = load("res://art/shaders/painted.gdshader")

	# In-game grade pass (2026-09-30): the keep was the brightest thing on screen. Snow ~17 % darker (blue-grey) and the
	# silver folded into it (B8 11 -> 8), crystals 15 % darker (ice_keep.gd) with dim cyan cracks, glow parts under the
	# bloom, GateVoid = DarkStone kept dark by its ao band, one alpha-blended particle material, a hard 1 m frost rim.
	var S := _painted(shader, "Stone", Color(0.40, 0.49, 0.63), 0.0, 0.45)
	var D := _painted(shader, "DarkStone", Color(0.30, 0.38, 0.48), 0.0, 0.0)
	var C := _painted(shader, "Crystal", Color(0.38, 0.64, 0.81), 0.5, 0.12)
	C.set_shader_parameter("crack_scale", 1.2)
	C.set_shader_parameter("crack_color", Color(0.35, 0.82, 1.00))
	var W := _painted(shader, "Snow", Color(0.70, 0.77, 0.86), 0.25, 0.0)
	var M := W
	var G := ShaderMaterial.new()
	G.resource_name = "Glow"
	G.shader = load("res://art/buildings/ice_keep_glow.gdshader")
	G.set_shader_parameter("glow_color", GLOW)
	G.set_shader_parameter("boost_mult", KeepScript.GLOW_BOOST)
	var T := ShaderMaterial.new()
	T.resource_name = "Banner"
	T.shader = load("res://art/shaders/banner.gdshader")
	T.set_shader_parameter("cloth_color", TEAM)
	T.set_shader_parameter("stripe_color", Color(0.15, 0.35, 0.60))
	T.set_shader_parameter("glyph_color", GLOW)
	T.set_shader_parameter("glyph_shape", 1)
	T.set_shader_parameter("amplitude", 0.08)
	T.set_shader_parameter("speed", 1.4)

	# A.8: battered (sloped) terraces merged into one mass, four corner watchtowers with crystal
	# spires, arrow-slit windows glowing with cold light, a bigger asymmetric crown cluster and ice
	# spikes erupting from the frozen ground around the plinth.
	var sq: float = sqrt(2.0) # 4-sided prism: corner radius = half-size x sqrt 2
	_mesh("PlinthLower", _prism(3.25 * sq, 3.1 * sq, 0.8, 0.0, 0.0, 4), Vector3.ZERO, D, 0.0, 0.8)
	var terr: Array = []
	var caps: Array = []
	for t: Array in KeepScript.TERRACES:
		var hb: float = t[0]
		var ht: float = t[1]
		var y0: float = t[2]
		var y1: float = t[3]
		terr.append([_prism(hb * sq, ht * sq, y1 - y0, 0.0, 0.0, 4), Transform3D(Basis(), Vector3(0, y0, 0))])
		caps.append([_prism((ht + 0.14) * sq, (ht + 0.02) * sq, 0.26, 0.0, 0.0, 4), Transform3D(Basis(), Vector3(0, y1 - 0.04, 0))])
	_mesh("Terraces", _merge(terr), Vector3.ZERO, S, 0.8, 4.4)
	var snow_mi := _mesh("SnowCaps", _merge(caps), Vector3.ZERO, W, 2.0, 3.4)
	snow_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Icicles under each snow lip (the gatehouse and the towers interrupt some).
	var ice_xf: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for ti: int in 3:
		var t: Array = KeepScript.TERRACES[ti]
		var w: float = (t[1] as float) + 0.14
		var top: float = (t[3] as float) - 0.04
		for side: int in 4:
			var out := Vector3(sin(side * PI / 2.0), 0, -cos(side * PI / 2.0))
			var along := Vector3(out.z, 0, -out.x)
			for f: float in [-0.7, -0.42, -0.15, 0.12, 0.4, 0.68]:
				var off: float = (f + rng.randf_range(-0.05, 0.05)) * w
				if ti == 0 and side == 0 and absf(off) < 1.5:
					continue # the gatehouse sits here
				if ti == 0 and absf(off) > w - 0.9:
					continue # corner towers
				var sy: float = rng.randf_range(0.6, 1.4)
				var p: Vector3 = out * (w + 0.02) + along * off + Vector3(0, top - 0.4 * sy, 0)
				ice_xf.append(Transform3D(Basis.from_scale(Vector3(1.0, sy, 1.0)), p))
	var icicle := CylinderMesh.new()
	icicle.top_radius = 0.15
	icicle.bottom_radius = 0.0
	icicle.height = 0.8
	icicle.radial_segments = 5
	icicle.rings = 1
	var ic := _multi("Icicles", icicle, ice_xf, W, 0.0, 5.0)
	ic.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Corner watchtowers (battered hex) with crystal spire caps, 1.3 x wider than the tower.
	var towers: Array = []
	var tcaps: Array = []
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var p := Vector3(sx * 2.6, 0.0, sz * 2.6)
			towers.append([_prism(0.74, 0.62, 4.3, 0.0, 0.0), Transform3D(Basis(), p + Vector3(0, 0.8, 0))])
			towers.append([_prism(0.8, 0.8, 0.22, 0.0, 0.0), Transform3D(Basis(), p + Vector3(0, 5.05, 0))])
			tcaps.append([_crystal(0.8, 0.3, 1.9, 0.0), Transform3D(Basis(Vector3.UP, 0.4 * sx * sz), p + Vector3(0, 5.25, 0))])
	_mesh("Towers", _merge(towers), Vector3.ZERO, S, 0.8, 4.5)
	_mesh("TowerCaps", _merge(tcaps), Vector3.ZERO, C, 4.0, 4.0)
	# Crystal spikes on the terrace 2 / 3 corners, leaning out, and on the banner pole tops.
	var spike_xf: Array[Transform3D] = []
	for c: Array in [[2.02, 3.75, 0.95], [1.48, 5.05, 0.8]]:
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var dir := Vector3(sx, 0, sz).normalized()
				var k: Vector3 = dir.cross(Vector3.UP).normalized()
				var b := Basis(k, deg_to_rad(-28.0)).scaled(Vector3.ONE * c[2])
				spike_xf.append(Transform3D(b, Vector3(sx * c[0], c[1] - 0.2, sz * c[0])))
	for sx: float in [-1.0, 1.0]:
		spike_xf.append(Transform3D(Basis.from_scale(Vector3.ONE * 0.55), Vector3(sx * KeepScript.POLE_X, 5.25, -3.02)))
	_multi("Spikes", _crystal(0.32, 0.8, 0.9, 0.0), spike_xf, C, 2.0, 3.5)
	# Arrow-slit windows (cold light) on terrace 1 and 2 walls.
	var win_xf: Array[Transform3D] = []
	for ti: int in 2:
		var t: Array = KeepScript.TERRACES[ti]
		var y0: float = t[2]
		var y1: float = t[3]
		var hm: float = ((t[0] as float) + (t[1] as float)) * 0.5
		var slope: float = atan(((t[0] as float) - (t[1] as float)) / (y1 - y0))
		for side: int in 4:
			var out := Vector3(sin(side * PI / 2.0), 0, -cos(side * PI / 2.0))
			var along := Vector3(out.z, 0, -out.x)
			var offs: Array = [-1.3, 0.0, 1.3] if ti == 0 else [-0.75, 0.75]
			for o: float in offs:
				if ti == 0 and side == 0 and absf(o) < 1.5:
					continue
				var b := Basis(along, -slope) * Basis(Vector3.UP, atan2(out.x, out.z))
				win_xf.append(Transform3D(b, out * (hm + 0.03) + along * o + Vector3(0, (y0 + y1) * 0.5, 0)))
	var slit := BoxMesh.new()
	slit.size = Vector3(0.2, 0.78, 0.06)
	var wins := _multi("Windows", slit, win_xf, G, 0, 1)
	wins.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wins.set_instance_shader_parameter("energy", 2.6)
	wins.set_instance_shader_parameter("pulse_speed", 0.9)
	# Gate on -Z: dark-stone gatehouse, silver frame, dark void, glowing slit + keystone.
	_mesh("Gatehouse", _arch(1.3, 2.4, 0.9), Vector3(0, 0.8, -2.8), D, 0.8, 3.7)
	_mesh("GateFrame", _arch(1.05, 2.0, 0.14), Vector3(0, 0.8, -3.27), M, 0.8, 3.1)
	var gv := _mesh("GateVoid", _arch(0.8, 1.85, 0.1), Vector3(0, 0.8, -3.33), D, 6.0, 1.0)   # below ao_bottom: dark
	gv.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var unit_box := BoxMesh.new()
	var key_b := Basis(Vector3.FORWARD, PI / 4.0).scaled(Vector3(0.42, 0.42, 0.14))
	var gg := _multi("GateGlow", unit_box, [
		Transform3D(Basis.from_scale(Vector3(0.16, 1.5, 0.06)), Vector3(0, 1.65, -3.40)),
		Transform3D(key_b, Vector3(0, 3.85, -3.37))], G, 0, 1)
	gg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gg.set_instance_shader_parameter("energy", 2.5)
	gg.set_instance_shader_parameter("pulse_speed", 1.0)
	# Banner poles + banners on both gate sides (between the gatehouse and the front towers).
	var pole := CylinderMesh.new()
	pole.top_radius = 0.09
	pole.bottom_radius = 0.11
	pole.height = 4.5
	pole.radial_segments = 6
	pole.rings = 1
	var px: float = KeepScript.POLE_X
	var poles := _multi("BannerPoles", pole, [Transform3D(Basis(), Vector3(-px, 3.05, -3.02)), Transform3D(Basis(), Vector3(px, 3.05, -3.02))], M, 0.8, 4.5)
	poles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.72, 2.2)
	plane.orientation = PlaneMesh.FACE_Z
	plane.subdivide_width = 3
	plane.subdivide_depth = 10
	var bi: int = 0
	for sx: float in [-1.0, 1.0]:
		var mi := MeshInstance3D.new()
		mi.mesh = plane
		mi.material_override = T
		mi.transform = Transform3D(Basis.looking_at(Vector3(0, 0, 1), Vector3.UP), Vector3(sx * px, 3.95, -3.14))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bi += 1
		_add(mi, model, "Banner%d" % bi)
		mi.set_instance_shader_parameter("phase", float(bi) * 2.3)
	# Crown: main crystal (body + floating tip with the glowing core in the gap), two tilted side
	# crystals and a ring of smaller shards bursting out of the top terrace (asymmetric cluster).
	var cb: float = KeepScript.CROWN_BASE
	_mesh("CrystalMain", _crystal(1.05, KeepScript.TIP_Y - 1.1 - cb, 0.4, 0.0), Vector3(0, cb, 0), C, cb, 10.0)
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 0.4
	core_mesh.bottom_radius = 0.4
	core_mesh.height = 2.1
	core_mesh.radial_segments = 6
	core_mesh.rings = 1
	var core := _mesh("Core", core_mesh, Vector3(0, KeepScript.TIP_Y - 0.55, 0), G)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core.set_instance_shader_parameter("energy", 3.6)
	core.set_instance_shader_parameter("pulse_speed", 3.1)
	var tip: Node3D = _add(Node3D.new(), model, "Tip")
	tip.position = Vector3(0, KeepScript.TIP_Y, 0)
	var tip_mi := MeshInstance3D.new()
	tip_mi.mesh = _crystal(1.05, 0.9, 2.9, 0.45)
	tip_mi.material_override = C
	_add(tip_mi, tip, "TipMesh")
	tip_mi.set_instance_shader_parameter("ao_bottom", cb)
	tip_mi.set_instance_shader_parameter("ao_height", 10.0)
	for side: Array in [["CrystalL", Vector3(-0.55, cb - 0.2, 0.3), Vector3(-1, 0, 0.25), 0.7, 4.6, 1.9],
			["CrystalR", Vector3(0.55, cb - 0.2, -0.25), Vector3(0.9, 0, 0.45), 0.6, 3.6, 1.6]]:
		var dir: Vector3 = (side[2] as Vector3).normalized()
		var k: Vector3 = dir.cross(Vector3.UP).normalized()
		var mi := _mesh(side[0], _crystal(side[3], side[4], side[5], 0.0), side[1], C, cb, 10.0)
		mi.basis = Basis(k, deg_to_rad(-21.0))
	var shard_xf: Array[Transform3D] = []
	for s: Array in [[200.0, 0.95, 1.0, 38.0], [255.0, 1.05, 0.75, 46.0], [330.0, 0.9, 0.9, 34.0], [20.0, 1.0, 0.65, 50.0], [115.0, 1.0, 0.8, 42.0]]:
		var a: float = deg_to_rad(s[0])
		var out := Vector3(cos(a), 0, sin(a))
		var k2: Vector3 = out.cross(Vector3.UP).normalized()
		var b := Basis(k2, deg_to_rad(-(s[3] as float))) * Basis(Vector3.UP, a) * Basis.from_scale(Vector3.ONE * (s[2] as float))
		shard_xf.append(Transform3D(b, out * (s[1] as float) + Vector3(0, cb - 0.1, 0)))
	_multi("CrownShards", _crystal(0.42, 1.5, 0.9, 0.0), shard_xf, C, cb, 4.0)
	# Shard halo: 6 small crystals orbiting the core gap.
	var halo: Node3D = _add(Node3D.new(), model, "Halo")
	halo.position = Vector3(0, KeepScript.HALO_Y, 0)
	var hm := MultiMesh.new()
	hm.transform_format = MultiMesh.TRANSFORM_3D
	hm.mesh = _crystal(0.34, 0.7, 0.55, 0.55)
	hm.instance_count = 6
	for i: int in 6:
		hm.set_instance_transform(i, KeepScript.halo_xf(i))
	var hmi := MultiMeshInstance3D.new()
	hmi.multimesh = hm
	hmi.material_override = G
	hmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(hmi, halo, "HaloShards")
	hmi.set_instance_shader_parameter("energy", 2.5)
	hmi.set_instance_shader_parameter("pulse_speed", 2.0)
	# Ground: ice spikes erupting from the frozen ground in small clusters (glacier contact).
	var gs_xf: Array[Transform3D] = []
	for cl: int in 7:
		var a0: float = TAU * (float(cl) + 0.35) / 7.0 + rng.randf_range(-0.15, 0.15)
		for j: int in rng.randi_range(2, 3):
			var a: float = a0 + rng.randf_range(-0.22, 0.22)
			var rad: float = rng.randf_range(3.6, 4.5)
			var out := Vector3(cos(a), 0, sin(a))
			var k3: Vector3 = out.cross(Vector3.UP).normalized()
			var sc: float = rng.randf_range(0.8, 1.35) * (1.0 if j == 0 else 0.65)
			var b := Basis(k3, deg_to_rad(-rng.randf_range(18.0, 48.0))) * Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3.ONE * sc)
			gs_xf.append(Transform3D(b, out * rad + Vector3(0, -0.25, 0)))
	var gs := _multi("GroundSpikes", _crystal(0.3, 1.1, 0.7, 0.0), gs_xf, C, -0.6, 2.4)
	gs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Rubble (dark ice-stone chunks) + Rubble2 (the broken side crystal, shown under 50 % HP).
	var rub_xf: Array[Transform3D] = []
	for i: int in 7:
		var a: float = TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / 7.0 + 0.6
		var rad: float = rng.randf_range(3.4, 3.9)
		var sc: float = rng.randf_range(0.8, 1.3)
		var bb := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(10.0, 20.0))) * Basis.from_scale(Vector3(0.55, 0.45, 0.5) * sc)
		rub_xf.append(Transform3D(bb, Vector3(cos(a) * rad, 0.08, sin(a) * rad)))
	var rb := _multi("Rubble", unit_box, rub_xf, D, -0.2, 0.8)
	rb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rub2_xf: Array[Transform3D] = []
	for j: int in 6:
		var bb2 := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(35.0, 75.0)))
		rub2_xf.append(Transform3D(bb2, Vector3(rng.randf_range(3.3, 4.3), 0.1, rng.randf_range(-1.6, 1.8))))
	var r2 := _multi("Rubble2", _crystal(0.35, 0.5, 0.45, 0.0), rub2_xf, C, -0.3, 1.2)
	r2.visible = false
	# Contact: frost patch decal (not under Model, stays flat during construction).
	var decal := MeshInstance3D.new()
	var dplane := PlaneMesh.new()
	dplane.size = Vector2(GROUND_SIZE, GROUND_SIZE)
	decal.mesh = dplane
	decal.position = Vector3(0, 0.03, 0)
	decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dmat := ShaderMaterial.new()
	dmat.resource_name = "FrostGround"
	dmat.shader = load("res://art/buildings/ice_keep_ground.gdshader")
	dmat.set_shader_parameter("size", GROUND_SIZE)
	dmat.set_shader_parameter("frost_color", Color(0.66, 0.74, 0.84))
	dmat.set_shader_parameter("frost_alpha", 0.88)
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
	# Lights (2, shadows off).
	var cl := OmniLight3D.new()
	cl.position = Vector3(0, 8.0, 0)
	cl.light_color = Color(0.70, 0.88, 1.00)
	cl.light_energy = 1.5
	cl.omni_range = 10.0
	cl.light_specular = 0.2
	cl.shadow_enabled = false
	_add(cl, keep, "CrownLight")
	var gl := OmniLight3D.new()
	gl.position = Vector3(0, 2.0, -4.0)
	gl.light_color = GLOW
	gl.light_energy = 1.0
	gl.omni_range = 5.0
	gl.light_specular = 0.2
	gl.shadow_enabled = false
	_add(gl, keep, "GateLight")
	# Idle particles: falling snow motes (40) + frost mist at the plinth (24) = 64.
	# G-F round 2 item 7: IceKeep._cap_motes() (ice_keep.gd) re-sets SnowMotes / FrostSwirl at run time (lower, smaller,
	# dimmer, MoteCap quad and tier), so a rebuilt .tscn keeps the capped look.
	var soft := _radial([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)], [0.0, 0.35, 1.0])
	var mix_mat := _particle_mat(soft, BaseMaterial3D.BLEND_MODE_MIX, "ParticleMix")
	var add_mat := mix_mat   # one alpha-blended material (the additive one at albedo x3 glittered white)
	var snow := _particles("SnowMotes", keep, 30, 9.0, add_mat, 0.14)
	snow.position = Vector3(0, 12.0, 0)
	var snp := snow.process_material as ParticleProcessMaterial
	snp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	snp.emission_box_extents = Vector3(3.6, 0.3, 3.6)
	snp.direction = Vector3.DOWN
	snp.spread = 10.0
	snp.initial_velocity_min = 1.0
	snp.initial_velocity_max = 1.4
	snp.gravity = Vector3(0.12, 0, 0)
	snp.scale_min = 0.7
	snp.scale_max = 1.3
	snp.color_ramp = _grad([Color(0.72, 0.8, 0.9, 0), Color(0.72, 0.8, 0.9, 0.8), Color(0.72, 0.8, 0.9, 0.8), Color(0.72, 0.8, 0.9, 0)], [0.0, 0.1, 0.85, 1.0])
	snow.visibility_aabb = AABB(Vector3(-5, -13, -5), Vector3(10, 14, 10))
	var mist := _particles("FrostMist", keep, 24, 6.0, mix_mat, 1.2)
	mist.position = Vector3(0, 0.3, 0)
	mist.sorting_offset = 1.0
	var gp := mist.process_material as ParticleProcessMaterial
	gp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	gp.emission_ring_axis = Vector3.UP
	gp.emission_ring_radius = 3.9
	gp.emission_ring_inner_radius = 3.3
	gp.emission_ring_height = 0.1
	gp.radial_velocity_min = 0.08
	gp.radial_velocity_max = 0.08
	gp.initial_velocity_min = 0.0
	gp.initial_velocity_max = 0.0
	gp.scale_curve = _curve(0.5, 1.0)
	gp.color_ramp = _grad([Color(0.6, 0.7, 0.82, 0), Color(0.6, 0.7, 0.82, 0.13), Color(0.6, 0.7, 0.82, 0)], [0.0, 0.3, 1.0])
	mist.visibility_aabb = AABB(Vector3(-7, -1, -7), Vector3(14, 4, 14))
	# Frost swirl: glittering motes rising in a slow spiral around the crown (the script turns the node).
	var swirl := _particles("FrostSwirl", keep, 30, 7.0, add_mat, 0.16)
	swirl.position = Vector3(0, 5.4, 0)
	var swp := swirl.process_material as ParticleProcessMaterial
	swp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	swp.emission_ring_axis = Vector3.UP
	swp.emission_ring_radius = 2.5
	swp.emission_ring_inner_radius = 1.6
	swp.emission_ring_height = 0.3
	swp.direction = Vector3.UP
	swp.spread = 8.0
	swp.initial_velocity_min = 0.7
	swp.initial_velocity_max = 1.1
	swp.scale_curve = _curve(0.6, 1.0)
	swp.color_ramp = _grad([Color(0.3, 0.78, 1.0, 0), Color(0.3, 0.78, 1.0, 0.9), Color(0.22, 0.6, 0.95, 0.7), Color(0.22, 0.6, 0.95, 0)], [0.0, 0.15, 0.7, 1.0])
	swirl.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 10, 8))
	var mist2 := mist.duplicate() as GPUParticles3D
	mist2.emitting = false
	mist2.preprocess = 0.0
	_add(mist2, keep, "FrostMist2")
	# State particles (art-keep.md 7.3, Ice colours).
	# G-F r3: IceKeep._style_smoke() (ice_keep.gd) re-sets Smoke1 / Smoke2 at run time (soft grey column, sized quad,
	# 5 s life) and crystal_color() / set_health_ratio() set the crystal tint and the veins, so a rebuilt .tscn keeps them.
	for s: Array in [["Smoke1", Vector3(-1.6, 3.8, 1.5)], ["Smoke2", Vector3(1.1, 5.2, -1.0)]]:
		var sm := _particles(s[0], keep, 30, 3.5, mix_mat, 2.6)
		sm.position = s[1]
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
		smp.color_ramp = _grad([Color(0.20, 0.23, 0.29, 0.0), Color(0.20, 0.23, 0.29, 0.65), Color(0.32, 0.36, 0.42, 0.0)], [0.0, 0.1, 1.0])
	for s: Array in [["FrostFlare1", Vector3(-1.5, 3.8, -1.4)], ["FrostFlare2", Vector3(0.9, 5.3, 1.1)]]:
		var rf := _particles(s[0], keep, 24, 1.0, add_mat, 0.9)
		rf.position = s[1]
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
		rfp.color_ramp = _grad([Color(0.14, 0.26, 0.42, 1.0), Color(0.06, 0.18, 0.40, 0.9), Color(0.03, 0.08, 0.24, 0.5), Color(0.02, 0.05, 0.16, 0.0)], [0.0, 0.3, 0.75, 1.0])
	var tb := _particles("TrainBurst", keep, 72, 0.8, add_mat, 0.15)
	tb.one_shot = true
	tb.explosiveness = 1.0
	tb.emitting = false
	tb.preprocess = 0.0
	tb.position = Vector3(0, 2.0, -3.5)
	tb.visibility_aabb = AABB(Vector3(-5, -5, -5), Vector3(10, 10, 10))
	var tbp := tb.process_material as ParticleProcessMaterial
	tbp.direction = Vector3(0, 0, -1)
	tbp.spread = 60.0
	tbp.initial_velocity_min = 2.0
	tbp.initial_velocity_max = 4.0
	tbp.gravity = Vector3(0, -1.5, 0)
	tbp.scale_curve = _curve(1.0, 0.33)
	tbp.color_ramp = _grad([Color(1, 1, 1, 1), Color(1, 1, 1, 0)], [0.0, 1.0])
	tbp.color = GLOW
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
	brp.color = GLOW
	var cd := _particles("CollapseDust", keep, 60, 2.5, mix_mat, 3.0)
	cd.one_shot = true
	cd.explosiveness = 0.9
	cd.emitting = false
	cd.preprocess = 0.0
	cd.position = Vector3(0, 5.0, 0)
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
	cdp.color_ramp = _grad([Color(0.72, 0.78, 0.86, 0.6), Color(0.60, 0.66, 0.74, 0.0)], [0.0, 1.0])
	# Shatter: the crown breaks into 12 crystal shards (mesh particles, crystal material).
	var sh := GPUParticles3D.new()
	sh.amount = 12
	sh.lifetime = 1.7
	sh.one_shot = true
	sh.explosiveness = 1.0
	sh.emitting = false
	sh.fixed_fps = 30
	sh.interpolate = true
	sh.local_coords = true
	sh.position = Vector3(0, 7.5, 0)
	sh.draw_pass_1 = _crystal(0.32, 0.7, 0.55, 0.4)
	sh.material_override = C
	sh.visibility_aabb = AABB(Vector3(-9, -8, -9), Vector3(18, 16, 18))
	var shp := ParticleProcessMaterial.new()
	shp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	shp.emission_sphere_radius = 1.2
	shp.direction = Vector3.UP
	shp.spread = 75.0
	shp.initial_velocity_min = 3.0
	shp.initial_velocity_max = 6.0
	shp.gravity = Vector3(0, -12.0, 0)
	shp.particle_flag_rotate_y = true
	shp.angle_min = 0.0
	shp.angle_max = 360.0
	shp.angular_velocity_min = -360.0
	shp.angular_velocity_max = 360.0
	shp.scale_min = 0.9
	shp.scale_max = 1.7
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(0.75, 1))
	sc.add_point(Vector2(1, 0))
	var sct := CurveTexture.new()
	sct.curve = sc
	shp.scale_curve = sct
	sh.process_material = shp
	_add(sh, keep, "Shatter")
	sh.set_instance_shader_parameter("ao_bottom", 0.0)
	sh.set_instance_shader_parameter("ao_height", 8.0)

	var ps := PackedScene.new()
	var err := ps.pack(keep)
	if err == OK:
		err = ResourceSaver.save(ps, OUT)
	print("ice_keep_build: saved ", OUT, " err=", err, " icicles=", (model.get_node("Icicles") as MultiMeshInstance3D).multimesh.instance_count)
	keep.free()
	quit(0)


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
	m.set_shader_parameter("crack_color", Color(0.80, 0.95, 1.00))
	m.set_shader_parameter("crack_speed", 0.9)
	m.set_shader_parameter("crack_scale", 1.8)
	m.set_shader_parameter("rim_color", Color(0.70, 0.86, 1.00))
	m.set_shader_parameter("rim_strength", 0.35)
	return m


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
		st.add_vertex(bot[i]); st.add_vertex(bot[j]); st.add_vertex(top[j])
		if r1 > 0.0:
			st.add_vertex(bot[i]); st.add_vertex(top[j]); st.add_vertex(top[i])
			st.add_vertex(top[i]); st.add_vertex(top[j]); st.add_vertex(c_top)
		st.add_vertex(bot[i]); st.add_vertex(Vector3.ZERO); st.add_vertex(bot[j])
	st.generate_normals()
	return st.commit()


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


func _multi(nm: String, mesh: Mesh, xfs: Array, mat: Material, ao_b: float, ao_h: float) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i: int in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	_add(mmi, model, nm)
	mmi.set_instance_shader_parameter("ao_bottom", ao_b)
	mmi.set_instance_shader_parameter("ao_height", ao_h)
	return mmi


## Faceted hexagonal crystal: prism of radius r from y 0 to body, a point `top` above it and,
## if `bot` > 0, a point `bot` below y 0 (else a flat base). Flat-shaded.
func _crystal(r: float, body: float, top: float, bot: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector3] = []
	for i: int in 6:
		var a: float = TAU * float(i) / 6.0 + PI / 6.0
		ring.append(Vector3(cos(a) * r, 0, sin(a) * r))
	var up := Vector3(0, body, 0)
	var apex := Vector3(0, body + top, 0)
	var low := Vector3(0, -bot, 0)
	for i: int in 6:
		var a0: Vector3 = ring[i]
		var a1: Vector3 = ring[(i + 1) % 6]
		var b0: Vector3 = a0 + up
		var b1: Vector3 = a1 + up
		var u0: float = float(i) / 6.0
		var u1: float = float(i + 1) / 6.0
		# side quad (clockwise seen from outside = Godot front face)
		st.set_uv(Vector2(u0, 1)); st.add_vertex(a0)
		st.set_uv(Vector2(u1, 1)); st.add_vertex(a1)
		st.set_uv(Vector2(u1, 0)); st.add_vertex(b1)
		st.set_uv(Vector2(u0, 1)); st.add_vertex(a0)
		st.set_uv(Vector2(u1, 0)); st.add_vertex(b1)
		st.set_uv(Vector2(u0, 0)); st.add_vertex(b0)
		# top point
		st.set_uv(Vector2(u0, 0)); st.add_vertex(b0)
		st.set_uv(Vector2(u1, 0)); st.add_vertex(b1)
		st.set_uv(Vector2(0.5, 0)); st.add_vertex(apex)
		# bottom point / flat base
		st.set_uv(Vector2(u0, 1)); st.add_vertex(a0)
		st.set_uv(Vector2(0.5, 1)); st.add_vertex(low)
		st.set_uv(Vector2(u1, 1)); st.add_vertex(a1)
	st.generate_normals()
	return st.commit()


## "Tombstone" arch: rectangle half-width hw, straight height h, topped by a half disc of radius hw,
## extruded `depth` along z (centred). Bottom at y 0.
func _arch(hw: float, h: float, depth: float) -> ArrayMesh:
	var outline: Array[Vector2] = [Vector2(hw, 0)]
	var segs: int = 10
	for i: int in segs + 1:
		var a: float = PI * float(i) / float(segs)
		outline.append(Vector2(cos(a) * hw, h + sin(a) * hw))
	outline.append(Vector2(-hw, 0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var zf: float = -depth * 0.5
	var zb: float = depth * 0.5
	var centre := Vector2(0, h * 0.6)
	var n: int = outline.size()
	for i: int in n:
		var p0: Vector2 = outline[i]
		var p1: Vector2 = outline[(i + 1) % n]
		# front face (-z) and back face (+z) as a fan from an inner point
		st.add_vertex(Vector3(centre.x, centre.y, zf)); st.add_vertex(Vector3(p0.x, p0.y, zf)); st.add_vertex(Vector3(p1.x, p1.y, zf))
		st.add_vertex(Vector3(centre.x, centre.y, zb)); st.add_vertex(Vector3(p1.x, p1.y, zb)); st.add_vertex(Vector3(p0.x, p0.y, zb))
		# side
		st.add_vertex(Vector3(p0.x, p0.y, zf)); st.add_vertex(Vector3(p0.x, p0.y, zb)); st.add_vertex(Vector3(p1.x, p1.y, zb))
		st.add_vertex(Vector3(p0.x, p0.y, zf)); st.add_vertex(Vector3(p1.x, p1.y, zb)); st.add_vertex(Vector3(p1.x, p1.y, zf))
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
	m.billboard_keep_scale = true   # G-F billboard pass: the particle scale applies (docs/art/gf_billboard.md)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = blend
	m.disable_fog = blend == BaseMaterial3D.BLEND_MODE_ADD  # G-E 5: an additive quad must not fog
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	if blend == BaseMaterial3D.BLEND_MODE_ADD:
		m.albedo_color = Color(3.0, 3.0, 3.0, 1.0) # HDR so sparks reach the bloom threshold
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

extends SceneTree
## Builds the Shadow army + Ruin Warden scenes (task 4.V3, polished in A.5; docs/design/art-units.md section 5) and
## their particle materials. Run it with the WINDOWED Godot (a real renderer, so instance uniforms serialize):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://art/units/shadow/_build_shadow.gd --quit-after 600
## Every unit is authored in its idle pose with pivots at rest rotation 0 (+Z = face / weapon side).
## A.5 look: dark, hooded, faceless silhouettes (black face voids + violet eye bars), team cloth on the big masses
## (cowls, mantles, torsos, tassets), bone and silver only as small high accents, violet shadow pools under the feet.

const PAINTED := "res://art/units/kit/unit_painted.gdshader"
const SHADOW_MAT_DIR := "res://art/units/shadow/materials/"
const NEUTRAL_MAT_DIR := "res://art/units/neutral/materials/"
const SHADOW_KINGDOM := Color(0.42, 0.22, 0.6)
## Violet-tinted ground blob of the Shadow units (instance uniform of the shared blob material).
const SHADOW_BLOB := Color(0.10, 0.03, 0.16, 0.55)
const WARDEN_BLOB := Color(0.06, 0.05, 0.03, 0.50)
const DEATH_VIOLET := Color(0.75, 0.40, 1.0, 1.0)

var SCRIPT_SHADOW: String = "res://art/units/shadow/shadow_model.gd"

var mats: Dictionary = {}
var sroot: Node3D
var piv: Dictionary = {}
var piv_pos: Dictionary = {}
var body_h: float = 1.6
var mesh_count: int = 0


func _init() -> void:
	_make_materials()
	# Optional filter (after `--`): only=nightbolt,hound rebuilds just those scenes
	# (ids: thrall, shade, nightbolt, hound, knight, warden).
	var only: PackedStringArray = []
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
	if only.is_empty() or only.has("thrall"):
		_build_thrall()
	if only.is_empty() or only.has("shade"):
		_build_shade()
	if only.is_empty() or only.has("nightbolt"):
		_build_nightbolt()
	if only.is_empty() or only.has("hound"):
		_build_hound()
	if only.is_empty() or only.has("knight"):
		_build_knight()
	if only.is_empty() or only.has("warden"):
		_build_warden()
	print("SHADOW BUILD DONE")
	quit()


# ---------------------------------------------------------------- materials

## Additive glowing mote (soft round dot: radial gradient texture, not a square quad).
func _particle_mat(nm: String, dir: String) -> void:
	var p := dir + nm + ".tres"
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.disable_fog = true  # G-E 5: an additive quad must not fog
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true   # G-F billboard pass: the particle scale applies (docs/art/gf_billboard.md)
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(1.6, 1.6, 1.6, 1)
	m.albedo_texture = _radial_tex(0.35)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	ResourceSaver.save(m, p)
	mats[nm] = load(p)


## Radial white-to-transparent dot; `core` = the solid part of the radius (0-1).
func _radial_tex(core: float) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(core, Color(1, 1, 1, 0.85))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	return gt


## Opaque shaded chunk material for the warden's rubble particles (StandardMaterial3D is allowed for particles).
func _rubble_mat() -> void:
	var p := NEUTRAL_MAT_DIR + "warden_rubble.tres"
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.30, 0.33, 0.27)
	m.roughness = 1.0
	m.vertex_color_use_as_albedo = true
	ResourceSaver.save(m, p)
	mats["warden_rubble"] = load(p)


## Soft violet smoke puff (mix blend, not additive) for the dissolve deaths and the knight's ground slam.
func _smoke_mat() -> void:
	var p := SHADOW_MAT_DIR + "shadow_smoke.tres"
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true   # G-F billboard pass: the particle scale applies (docs/art/gf_billboard.md)
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _radial_tex(0.1)
	ResourceSaver.save(m, p)
	mats["shadow_smoke"] = load(p)


## Palette materials come from the shared kit (art/units/kit/materials/); only particle materials
## (StandardMaterial3D, allowed for particles) live in the Shadow / neutral folders.
func _make_materials() -> void:
	for nm: String in ["shadow_cloth", "shadow_cloth_dark", "shadow_skin", "shadow_silver", "shadow_leather",
			"shadow_iron", "shadow_obsidian", "shadow_bone", "shadow_sec_worker", "shadow_sec_bolt", "shadow_glow",
			"shadow_glow_hero", "shadow_glow_mid", "shadow_cape", "shadow_cape_plain", "warden_stone",
			"warden_stone_dark", "warden_moss", "warden_glow", "unit_gold_trim", "crystal_glow", "unit_shadow_blob"]:
		var m := _kit_mat(nm)
		if m == null:
			push_error("missing kit material " + nm)
		mats[nm] = m
	_particle_mat("shadow_particle", SHADOW_MAT_DIR)
	_particle_mat("warden_particle", NEUTRAL_MAT_DIR)
	_rubble_mat()
	_smoke_mat()


func _kit_mat(nm: String) -> Material:
	for p: String in ["res://art/units/kit/materials/%s.tres" % nm, "res://art/units/materials/%s.tres" % nm]:
		if ResourceLoader.exists(p):
			return load(p)
	return null


# ---------------------------------------------------------------- meshes

func box(x: float, y: float, z: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(x, y, z)
	return m


func sph(r: float, radial: int = 12, rings: int = 6) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = radial
	m.rings = rings
	return m


func cyl(top: float, bottom: float, h: float, seg: int = 10) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	m.cap_top = top > 0.0
	return m


func cone(bottom: float, h: float, seg: int = 6) -> CylinderMesh:
	return cyl(0.0, bottom, h, seg)


func cap(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = max(h, r * 2.0 + 0.01)
	m.radial_segments = 8
	m.rings = 2
	return m


func torus(inner: float, outer: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 14
	m.ring_segments = 5
	return m


func prism(x: float, y: float, z: float) -> PrismMesh:
	var m := PrismMesh.new()
	m.size = Vector3(x, y, z)
	return m


func octa(r: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector3] = [Vector3(r, 0, 0), Vector3(0, 0, r), Vector3(-r, 0, 0), Vector3(0, 0, -r)]
	for tip: Vector3 in [Vector3(0, h, 0), Vector3(0, -h, 0)]:
		for i: int in 4:
			var a: Vector3 = ring[i]
			var b: Vector3 = ring[(i + 1) % 4]
			if tip.y > 0.0:
				st.add_vertex(a); st.add_vertex(tip); st.add_vertex(b)
			else:
				st.add_vertex(a); st.add_vertex(b); st.add_vertex(tip)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------- scene helpers

func begin(nm: String, h: float) -> void:
	body_h = h
	mesh_count = 0
	sroot = Node3D.new()
	sroot.name = nm
	piv.clear()
	piv_pos.clear()
	var r := Node3D.new()
	r.name = "Root"
	sroot.add_child(r)
	r.owner = sroot
	piv["Root"] = r
	piv_pos["Root"] = Vector3.ZERO


func pivot(nm: String, parent: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	var p: Node3D = piv[parent]
	p.add_child(n)
	n.owner = sroot
	n.position = pos - piv_pos[parent]
	piv[nm] = n
	piv_pos[nm] = pos
	return n


func biped_pivots(hip_y: float, leg_x: float, shoulder: Vector3, head_y: float, head_z: float = 0.0) -> void:
	pivot("Hips", "Root", Vector3(0, hip_y, 0))
	pivot("LegL", "Hips", Vector3(-leg_x, hip_y, 0))
	pivot("LegR", "Hips", Vector3(leg_x, hip_y, 0))
	pivot("Chest", "Root", Vector3(0, hip_y, 0))
	pivot("Head", "Chest", Vector3(0, head_y, head_z))
	pivot("ArmL", "Chest", Vector3(-shoulder.x, shoulder.y, shoulder.z))
	pivot("ArmR", "Chest", Vector3(shoulder.x, shoulder.y, shoulder.z))


func _setup_geom(mi: GeometryInstance3D, mat: Material, shadow: bool) -> void:
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null and (mat as ShaderMaterial).shader.resource_path == PAINTED:
		mi.set_instance_shader_parameter(&"ao_bottom", 0.0)
		mi.set_instance_shader_parameter(&"ao_height", body_h)


## A part at a unit-space position (the pivot's rest position is subtracted).
func part(pv: String, mesh: Mesh, pos: Vector3, mat: String, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, nm: String = "", keep: bool = false, shadow: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if nm != "":
		mi.name = nm
	var p: Node3D = piv[pv]
	p.add_child(mi, true)
	mi.owner = sroot
	var b := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z))) * Basis.from_scale(scl)
	mi.transform = Transform3D(b, pos - piv_pos[pv])
	var m: Material = mats.get(mat, null)
	if m == null:
		m = _kit_mat(mat)
	_setup_geom(mi, m, shadow)
	if keep:
		mi.set_meta(&"keep_separate", true)
	mesh_count += 1
	return mi


## A part whose local +Y runs from a to b (limbs, poles, blades). `face` = where its local +Z should point.
func seg(pv: String, mesh: Mesh, a: Vector3, b: Vector3, mat: String, face: Vector3 = Vector3.BACK, nm: String = "", keep: bool = false, shadow: bool = false, center_t: float = 0.5, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var y := (b - a).normalized()
	var f := face - y * face.dot(y)
	if f.length() < 0.01:
		f = Vector3.RIGHT - y * Vector3.RIGHT.dot(y)
	var z := f.normalized()
	var x := y.cross(z).normalized()
	var mi := part(pv, mesh, a.lerp(b, center_t), mat, Vector3.ZERO, Vector3.ONE, nm, keep, shadow)
	mi.basis = Basis(x, y, z) * Basis.from_scale(scl)
	return mi


## A limb capsule from a to b (radius r).
func limb(pv: String, a: Vector3, b: Vector3, r: float, mat: String, shadow: bool = false) -> MeshInstance3D:
	return seg(pv, cap(r, a.distance_to(b) + r * 2.0), a, b, mat, Vector3.BACK, "", false, shadow)


## An arm from the shoulder toward `hand`, with a fist at the hand (a gauntlet box when `gauntlet`).
func arm(pv: String, hand: Vector3, r: float, fist_r: float, mat: String, fist_mat: String, shadow: bool = false, gauntlet: bool = false) -> void:
	var s: Vector3 = piv_pos[pv]
	var d := hand - s
	var len := d.length() - fist_r * 0.6
	var e := s + d.normalized() * len
	seg(pv, cap(r, len + r), s, e, mat, Vector3.BACK, "", false, shadow)
	if gauntlet:
		seg(pv, box(fist_r * 1.7, fist_r * 1.9, fist_r * 1.7), e, e + d.normalized() * 0.1, fist_mat, Vector3.BACK, "", false, shadow, 1.0)
	else:
		part(pv, sph(fist_r, 10, 5), hand, fist_mat, Vector3.ZERO, Vector3.ONE, "", false, shadow)


func leg(pv: String, r: float, h: float, foot_scale: float, mat: String, foot_mat: String) -> void:
	var t: Vector3 = piv_pos[pv]
	part(pv, cap(r, h), Vector3(t.x, t.y - h * 0.5, 0), mat)
	var fs := foot_scale
	part(pv, box(0.24 * fs, 0.12 * fs, 0.32 * fs), Vector3(t.x, 0.06 * fs, 0.05 * fs), foot_mat)


func blob(scale_r: float, tint: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Shadow"
	sroot.add_child(mi)
	mi.owner = sroot
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1)
	mi.mesh = pm
	mi.position = Vector3(0, 0.02, 0)
	mi.scale = Vector3(scale_r, 1, scale_r)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = mats.get("unit_shadow_blob")
	mi.set_instance_shader_parameter(&"blob_color", tint)
	mi.set_meta(&"keep_separate", true)
	mesh_count += 1


func fx_node() -> Node3D:
	var fx := Node3D.new()
	fx.name = "Fx"
	sroot.add_child(fx)
	fx.owner = sroot
	piv["Fx"] = fx
	piv_pos["Fx"] = Vector3.ZERO
	return fx


## A pre-built particle emitter (one_shot unless looping), restarted by the model with restart().
## `death` = the kit restarts it when the glows die (meta death_fx).
func emitter(pv: String, nm: String, pos: Vector3, amount: int, life: float, col: Color, size: float, vel: float, spread: float, gravity: float, box_ext: Vector3, looping: bool, mat_name: String, death: bool = false, grow: bool = false) -> GPUParticles3D:
	var e := GPUParticles3D.new()
	e.name = nm
	var p: Node3D = piv[pv]
	p.add_child(e)
	e.owner = sroot
	e.position = pos - piv_pos[pv]
	e.amount = amount
	e.lifetime = life
	e.one_shot = not looping
	e.emitting = looping
	e.explosiveness = 0.0 if looping else 0.85
	e.randomness = 0.3
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	e.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 4, 4))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box_ext
	pm.direction = Vector3(0, 1, 0)
	pm.spread = spread
	pm.initial_velocity_min = vel * 0.6
	pm.initial_velocity_max = vel
	pm.gravity = Vector3(0, gravity, 0)
	pm.damping_min = 0.5
	pm.damping_max = 1.5
	pm.color = col
	var curve := Curve.new()
	if grow:
		curve.add_point(Vector2(0, 0.5))
		curve.add_point(Vector2(0.4, 1.0))
		curve.add_point(Vector2(1, 0.8))
	else:
		curve.add_point(Vector2(0, 1))
		curve.add_point(Vector2(1, 0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	e.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = mats[mat_name]
	e.draw_pass_1 = q
	if death:
		e.set_meta(&"death_fx", true)
	return e


## Tumbling stone chunks (mesh particles, gravity) for the warden's crumble; restarted by the model at 0.3 s.
func rubble_emitter(pv: String, nm: String, pos: Vector3) -> GPUParticles3D:
	var e := GPUParticles3D.new()
	e.name = nm
	var p: Node3D = piv[pv]
	p.add_child(e)
	e.owner = sroot
	e.position = pos - piv_pos[pv]
	e.amount = 9
	e.lifetime = 0.9
	e.one_shot = true
	e.emitting = false
	e.explosiveness = 0.9
	e.randomness = 0.4
	e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	e.visibility_aabb = AABB(Vector3(-2.5, -1, -2.5), Vector3(5, 4, 5))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.35, 0.35, 0.25)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 2.6
	pm.gravity = Vector3(0, -9.0, 0)
	pm.angular_velocity_min = -360.0
	pm.angular_velocity_max = 360.0
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	pm.color = Color(1, 1, 1)
	pm.collision_mode = ParticleProcessMaterial.COLLISION_DISABLED
	e.process_material = pm
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, 0.13, 0.15)
	bm.material = mats["warden_rubble"]
	e.draw_pass_1 = bm
	return e


func finish(path: String, script_path: String, exports: Dictionary) -> void:
	if ResourceLoader.exists(script_path):
		sroot.set_script(load(script_path))
		for k: String in exports:
			if k in sroot:
				sroot.set(k, exports[k])
			else:
				push_warning("%s: no export %s" % [path, k])
	var ps := PackedScene.new()
	var err := ps.pack(sroot)
	if err != OK:
		push_error("pack failed %s" % path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	ResourceSaver.save(ps, path)
	var count := 0
	for n: Node in sroot.find_children("*", "GeometryInstance3D", true, false):
		count += 1
	print("%s: %d meshes (budget rows), %d geometry nodes incl. particles" % [path, mesh_count, count])
	sroot.free()


func gold_trim(pv: String, pos: Vector3, scl: float = 1.0, rot: Vector3 = Vector3.ZERO) -> void:
	var t := part(pv, torus(0.20 * scl, 0.24 * scl), pos, "unit_gold_trim", rot, Vector3.ONE, "GoldTrim", true)
	t.visible = false


## The violet dissolve motes (16, rising in a column through the body; restarted by the kit at 0.4 s) and a
## soft smoke puff (restarted by the model when the body starts to fade).
func death_fx(h: float, r: float) -> void:
	emitter("Fx", "DeathMotes", Vector3(0, h * 0.45, 0), 16, 1.1, DEATH_VIOLET, 0.13 + h * 0.03, 1.3, 20.0, 0.6,
		Vector3(r * 0.55, h * 0.35, r * 0.55), false, "shadow_particle", true)
	emitter("Fx", "DeathSmoke", Vector3(0, h * 0.3, 0), 6, 0.9, Color(0.16, 0.06, 0.26, 0.55), 0.55 + h * 0.15, 0.7,
		35.0, 0.3, Vector3(r * 0.5, h * 0.2, r * 0.5), false, "shadow_smoke", false, true)


# ---------------------------------------------------------------- 5.1 Gloom Thrall (worker, 1.4 m) - budget 22

func _build_thrall() -> void:
	begin("GloomThrall", 1.4)
	biped_pivots(0.43, 0.14, Vector3(0.30, 0.92, 0.06), 0.92, 0.08)
	fx_node()
	leg("LegL", 0.09, 0.32, 0.9, "shadow_leather", "shadow_leather")
	leg("LegR", 0.09, 0.32, 0.9, "shadow_leather", "shadow_leather")
	# Hunched drudge robe (secondary grey-violet), dark torn hem, a team-colour shawl over the hump.
	part("Chest", cyl(0.19, 0.36, 0.62, 10), Vector3(0, 0.66, 0.04), "shadow_sec_worker", Vector3(12, 0, 0), Vector3(1.0, 1.0, 0.92), "", false, true)
	part("Chest", cyl(0.355, 0.39, 0.10, 7), Vector3(0, 0.37, -0.02), "shadow_cloth_dark", Vector3(12, 0, 0))
	part("Chest", cyl(0.16, 0.38, 0.44, 10), Vector3(0, 0.88, 0.02), "shadow_cloth", Vector3(18, 0, 0), Vector3(1.0, 1.0, 0.95), "", false, true)
	# Deep cowl (team) with a black face void and the violet eye bar; the hood tip droops down the back.
	part("Head", sph(0.24), Vector3(0, 1.09, 0.10), "shadow_cloth", Vector3(-10, 0, 0), Vector3(1.0, 1.02, 1.12), "", false, true)
	part("Head", sph(0.16, 10, 5), Vector3(0, 1.055, 0.27), "shadow_iron", Vector3.ZERO, Vector3(1.0, 1.0, 0.75))
	seg("Head", cone(0.15, 0.40), Vector3(0, 1.24, 0.02), Vector3(0, 1.14, -0.36), "shadow_cloth", Vector3.UP, "", false, true)
	part("Head", box(0.21, 0.06, 0.05), Vector3(0, 1.075, 0.395), "shadow_glow")
	arm("ArmL", Vector3(-0.28, 0.62, 0.24), 0.08, 0.10, "shadow_sec_worker", "shadow_skin")
	arm("ArmR", Vector3(0.36, 0.74, 0.22), 0.08, 0.10, "shadow_sec_worker", "shadow_skin", true)
	# Tall lantern pole over the shoulder: the lantern's violet light is the worker's role cue from 40 m.
	var hand := Vector3(0.36, 0.74, 0.22)
	var tip := Vector3(0.60, 2.02, 0.36)
	seg("ArmR", cyl(0.035, 0.04, hand.distance_to(tip) + 0.28, 6), hand - (tip - hand).normalized() * 0.28, tip, "shadow_iron", Vector3.BACK, "", false, true)
	var lan := pivot("Lantern", "ArmR", tip)
	lan.set_meta(&"keep_separate", true)
	part("Lantern", cone(0.16, 0.15, 6), tip + Vector3(0, -0.08, 0), "shadow_silver", Vector3.ZERO, Vector3.ONE, "", true)
	part("Lantern", sph(0.12, 10, 5), tip + Vector3(0, -0.25, 0), "shadow_glow_mid", Vector3.ZERO, Vector3(1.0, 1.15, 1.0), "LanternOrb", true)
	# Crystal cage (carry): 3 floating crystals behind the back.
	# Raised so the floating crystals peek over the hood from the game camera.
	var cc := Vector3(0, 1.30, -0.38)
	var cr := pivot("Crystals", "Chest", cc)
	cr.set_meta(&"keep_separate", true)
	cr.set_meta(&"carry", true)   # the kit shows it while set_carrying(true)
	cr.visible = false
	var co: Array[Vector3] = [Vector3(-0.17, 0.0, 0.0), Vector3(0.17, 0.05, 0.02), Vector3(0.0, 0.19, -0.06)]
	for k: int in 3:
		part("Crystals", octa(0.10, 0.16), cc + co[k], "crystal_glow", Vector3(0, 30.0 * k, 0), Vector3.ONE, "Crystal%d" % k, true)
	death_fx(1.4, 0.4)
	emitter("ArmR", "MineSparks", tip + Vector3(0, -0.26, 0.1), 6, 0.5, Color(0.55, 0.85, 1.0), 0.12, 1.5, 60.0, -3.0, Vector3(0.05, 0.05, 0.05), false, "shadow_particle")
	blob(0.4 * 2.6, SHADOW_BLOB)
	finish("res://art/units/shadow/gloom_thrall.tscn", SCRIPT_SHADOW, {"stride_speed": 4.6, "kingdom_color": SHADOW_KINGDOM, "unit_kind": &"thrall", "attack_style": &"worker_pick", "attack_windup": 0.0, "death_style": &"sink", "stride_time": 0.55, "body_height": 1.4, "is_quadruped": false, "glow_gain": 1.25})


# ---------------------------------------------------------------- 5.2 Shade (melee, 1.6 m) - budget 26

func _build_shade() -> void:
	begin("Shade", 1.6)
	biped_pivots(0.60, 0.17, Vector3(0.36, 1.20, 0), 1.26)
	fx_node()
	leg("LegL", 0.10, 0.42, 1.0, "shadow_leather", "shadow_leather")
	leg("LegR", 0.10, 0.42, 1.0, "shadow_leather", "shadow_leather")
	part("Hips", cyl(0.21, 0.28, 0.28, 6), Vector3(0, 0.66, 0), "shadow_cloth_dark", Vector3(0, 30, 0))
	# Lithe team-coloured torso bound in dark bandages, silver shoulder spikes.
	part("Chest", cyl(0.30, 0.19, 0.56, 10), Vector3(0, 0.98, 0), "shadow_cloth", Vector3.ZERO, Vector3(1.0, 1.0, 0.8), "", false, true)
	part("Chest", torus(0.20, 0.26), Vector3(0, 0.84, 0), "shadow_cloth_dark", Vector3(10, 0, 0), Vector3(1.0, 1.0, 0.85))
	part("Chest", torus(0.25, 0.31), Vector3(0, 1.08, 0), "shadow_cloth_dark", Vector3(-12, 0, 6), Vector3(1.0, 1.0, 0.85))
	part("Chest", cone(0.10, 0.42), Vector3(0.40, 1.38, -0.02), "shadow_silver", Vector3(0, 0, -42), Vector3.ONE, "", false, true)
	part("Chest", cone(0.10, 0.42), Vector3(-0.40, 1.38, -0.02), "shadow_silver", Vector3(0, 0, 42), Vector3.ONE, "", false, true)
	var cape_m := PlaneMesh.new()
	cape_m.size = Vector2(0.5, 0.85)
	cape_m.orientation = PlaneMesh.FACE_Z
	cape_m.subdivide_depth = 6
	part("Chest", cape_m, Vector3(-0.18, 0.88, -0.25), "shadow_cape_plain", Vector3(10, 0, 0), Vector3.ONE, "Cape", true)
	# Faceless assassin: team scarf, a pointed dark hood swept back, a black face void, violet eye slit.
	part("Head", cyl(0.22, 0.25, 0.16, 10), Vector3(0, 1.31, 0.01), "shadow_cloth", Vector3.ZERO, Vector3.ONE, "", false, true)
	part("Head", cyl(0.02, 0.27, 0.50, 10), Vector3(0, 1.55, -0.05), "shadow_cloth_dark", Vector3(-18, 0, 0), Vector3(1.0, 1.0, 1.08), "", false, true)
	part("Head", sph(0.19, 10, 5), Vector3(0, 1.41, 0.08), "shadow_leather", Vector3.ZERO, Vector3(1.0, 1.05, 0.95))
	part("Head", box(0.20, 0.055, 0.05), Vector3(0, 1.435, 0.265), "shadow_glow")
	gold_trim("Head", Vector3(0, 1.34, 0.01), 1.1)
	# Arms held low and out; blades in reverse grip, swept down, back and outward, tips near the ground.
	var hl := Vector3(-0.47, 0.80, 0.10)
	var hr := Vector3(0.47, 0.80, 0.10)
	arm("ArmL", hl, 0.085, 0.11, "shadow_cloth_dark", "shadow_silver")
	arm("ArmR", hr, 0.085, 0.11, "shadow_cloth_dark", "shadow_silver", true)
	for side: int in [-1, 1]:
		var pv := "ArmR" if side > 0 else "ArmL"
		var h := hr if side > 0 else hl
		var d1 := Vector3(0.22 * side, -0.72, -0.66).normalized()
		var d2 := Vector3(0.10 * side, -0.97, -0.20).normalized()
		var a := h + d1 * 0.07
		var b := a + d1 * 0.42
		var c := b + d2 * 0.40
		var out := Vector3(side, 0, 0)
		seg(pv, box(0.16, 0.44, 0.045), a, b, "shadow_silver", out, "", false, side > 0)
		seg(pv, prism(0.16, 0.42, 0.045), b, c, "shadow_silver", out, "", false, side > 0)
		if side > 0:
			# Glowing edge on the right blade only (1-2 glow rule), on the blade's back (the side that trails).
			seg(pv, box(0.045, 0.40, 0.055), a + Vector3(0, 0.0, 0.0) + (b - a).cross(out).normalized() * -0.07, b + (b - a).cross(out).normalized() * -0.07, "shadow_glow", out)
	death_fx(1.6, 0.45)
	blob(0.45 * 2.6, SHADOW_BLOB)
	finish("res://art/units/shadow/shade.tscn", SCRIPT_SHADOW, {"stride_speed": 4.8, "kingdom_color": SHADOW_KINGDOM, "unit_kind": &"shade", "attack_style": &"dual_slash", "attack_windup": 0.0, "death_style": &"sink", "stride_time": 0.50, "body_height": 1.6, "is_quadruped": false, "glow_gain": 2.2})


# ---------------------------------------------------------------- 5.3 Nightbolt (ranged, 1.6 m) - budget 26

func _build_nightbolt() -> void:
	begin("Nightbolt", 1.6)
	biped_pivots(0.55, 0.15, Vector3(0.34, 1.14, 0), 1.28)
	fx_node()
	leg("LegL", 0.10, 0.42, 1.0, "shadow_leather", "shadow_leather")
	leg("LegR", 0.10, 0.42, 1.0, "shadow_leather", "shadow_leather")
	# Long secondary-violet coat, a team-colour shoulder mantle, the bolt quiver on the back.
	# Secondary-violet doublet over a long dark coat skirt, a team-colour shoulder mantle, the quiver on the back.
	part("Chest", cyl(0.24, 0.29, 0.50, 10), Vector3(0, 0.98, 0), "shadow_sec_bolt", Vector3.ZERO, Vector3(0.9, 1, 0.88), "", false, true)
	part("Chest", cyl(0.28, 0.36, 0.50, 10), Vector3(0, 0.58, -0.01), "shadow_cloth_dark", Vector3.ZERO, Vector3(0.92, 1, 0.9), "", false, true)
	part("Chest", cyl(0.17, 0.37, 0.28, 10), Vector3(0, 1.16, -0.01), "shadow_cloth", Vector3.ZERO, Vector3(1.0, 1.0, 0.9), "", false, true)
	part("Chest", box(0.18, 0.46, 0.12), Vector3(-0.17, 1.02, -0.30), "shadow_leather", Vector3(0, 0, 14), Vector3.ONE, "", false, true)
	part("Chest", box(0.13, 0.12, 0.08), Vector3(-0.23, 1.28, -0.30), "shadow_glow", Vector3(0, 0, 14))
	# Face hidden: a dark wrapped head, the eyes glow under a wide peaked hat.
	part("Head", sph(0.205, 10, 5), Vector3(0, 1.41, 0), "shadow_cloth_dark")
	# Lab pass: the hat is the unit's biggest mass from the game camera, so it carries the team colour (brim) and the
	# lighter secondary violet (crown) instead of near-black (tops light, bottoms dark), and its band glows: the
	# Nightbolt's one high glow point over a crowd (the eye slit hides under the brim from 55 deg).
	part("Head", cyl(0.47, 0.49, 0.05, 14), Vector3(0, 1.585, -0.01), "shadow_cloth", Vector3(-7, 0, 0), Vector3.ONE, "", false, true)
	part("Head", cyl(0.10, 0.22, 0.34, 10), Vector3(0, 1.77, -0.04), "shadow_sec_bolt", Vector3(-14, 0, 0), Vector3.ONE, "", false, true)
	part("Head", torus(0.20, 0.25), Vector3(0, 1.645, -0.02), "shadow_glow", Vector3(-10, 0, 0))
	part("Head", box(0.20, 0.055, 0.05), Vector3(0, 1.43, 0.205), "shadow_glow")
	gold_trim("Head", Vector3(0, 1.645, -0.02), 1.15, Vector3(-10, 0, 0))
	# Dusk-caster held level at the hip, sticking forward; ArmL supports the front.
	var hr := Vector3(0.24, 0.98, 0.26)
	var hl := Vector3(0.02, 1.00, 0.52)
	arm("ArmR", hr, 0.085, 0.11, "shadow_sec_bolt", "shadow_silver", true)
	arm("ArmL", hl, 0.085, 0.11, "shadow_sec_bolt", "shadow_silver")
	# Lab pass: stock 0.95 -> 0.82 m and the prod / bolt pulled back 4-6 cm, so the muzzle stays inside the 0.45 m
	# selection footprint (it stuck out 0.87 m in front).
	var c := Vector3(0.15, 1.04, 0.36)
	part("ArmR", box(0.12, 0.13, 0.82), c, "shadow_iron", Vector3.ZERO, Vector3.ONE, "", false, true)
	# Swept prod: two arms bent back toward the shooter, silver barbs at the tips.
	for s: int in [-1, 1]:
		var root := c + Vector3(0.05 * s, 0.03, 0.34)
		var end := c + Vector3(0.56 * s, 0.03, 0.22)
		seg("ArmR", box(0.08, root.distance_to(end) + 0.04, 0.10), root, end, "shadow_silver", Vector3.UP, "", false, true)
		seg("ArmR", cone(0.065, 0.24), end - (end - root).normalized() * 0.04, end + Vector3(0.05 * s, 0, -0.20), "shadow_silver", Vector3.UP)
	part("ArmR", cyl(0.03, 0.03, 0.62, 6), c + Vector3(0, 0.09, 0.06), "shadow_glow_mid", Vector3(90, 0, 0), Vector3.ONE, "Bolt", true)
	emitter("ArmR", "FirePuff", c + Vector3(0, 0.08, 0.46), 8, 0.35, Color(0.75, 0.35, 1.0), 0.20, 1.4, 50.0, 0.0, Vector3(0.05, 0.05, 0.05), false, "shadow_particle")
	death_fx(1.6, 0.45)
	blob(0.45 * 2.6, SHADOW_BLOB)
	finish("res://art/units/shadow/nightbolt.tscn", SCRIPT_SHADOW, {"stride_speed": 5.0, "kingdom_color": SHADOW_KINGDOM, "unit_kind": &"nightbolt", "attack_style": &"caster_fire", "attack_windup": 0.12, "death_style": &"sink", "stride_time": 0.55, "body_height": 1.6, "is_quadruped": false, "glow_gain": 1.3})


# ---------------------------------------------------------------- 5.4 Grave Hound (quadruped, 1.0 m) - budget 22

func _build_hound() -> void:
	begin("GraveHound", 1.0)
	pivot("Mount", "Root", Vector3(0, 0, 0))
	pivot("Body", "Mount", Vector3(0, 0.58, 0))
	pivot("Head", "Mount", Vector3(0, 0.70, 0.50))
	for l: Array in [["LegFL", -0.17, 0.30], ["LegFR", 0.17, 0.30], ["LegBL", -0.15, -0.42], ["LegBR", 0.15, -0.42]]:
		pivot(l[0], "Mount", Vector3(l[1], 0.54, l[2]))
	pivot("Tail", "Mount", Vector3(0, 0.62, -0.64))
	fx_node()
	# Deep shadow-flesh chest and a lean rump (near-black), joined by a bone spine over open ribs + the heart.
	# (capsules along z: scale x = width, z = depth after the 90 deg turn) deep narrow chest, lean tucked rump.
	part("Body", cap(0.25, 0.72), Vector3(0, 0.62, 0.26), "shadow_leather", Vector3(98, 0, 0), Vector3(0.82, 1.0, 1.12), "", false, true)
	part("Body", cap(0.17, 0.46), Vector3(0, 0.60, -0.45), "shadow_leather", Vector3(80, 0, 0), Vector3(0.9, 1.0, 1.05), "", false, true)
	seg("Body", cyl(0.045, 0.06, 1.0, 6), Vector3(0, 0.79, 0.34), Vector3(0, 0.71, -0.62), "shadow_bone", Vector3.UP)
	# Lab pass: the two girth bands are team cloth (a harness), not bone: the team colour reads on the flanks at 40 m
	# and the busy black / bone stripes calm down (P4 detail density).
	for z: float in [-0.08, -0.22]:
		part("Body", torus(0.17, 0.225), Vector3(0, 0.60, z), "shadow_cloth", Vector3(90, 0, 0), Vector3(0.95, 1.0, 1.1))
	part("Body", sph(0.12, 10, 5), Vector3(0, 0.60, -0.16), "shadow_glow_mid", Vector3.ZERO, Vector3.ONE, "Heart")
	# Spine spikes, raked back, biggest over the shoulders (the "spiky back" of the role rule).
	var spikes: Array = [[0.30, 0.40], [0.05, 0.34], [-0.24, 0.30]]
	for sp: Array in spikes:
		var z: float = sp[0]
		var h: float = sp[1]
		seg("Body", cone(0.075, h), Vector3(0, 0.80 - z * 0.08, z), Vector3(0, 0.80 - z * 0.08 + h * 0.8, z - h * 0.6), "shadow_bone", Vector3.UP, "", false, true, 0.5)
	# Team-colour spiked collar where the neck meets the chest.
	part("Body", torus(0.16, 0.23), Vector3(0, 0.70, 0.46), "shadow_cloth", Vector3(62, 0, 0), Vector3.ONE, "", false, true)
	# Head: a long tapered skull (6-sided, flattened) narrowing to the snout, swept-back bone horns, eye bar, jaw.
	seg("Head", cyl(0.075, 0.16, 0.48, 6), Vector3(0, 0.80, 0.50), Vector3(0, 0.72, 0.98), "shadow_bone", Vector3.UP, "", false, true, 0.5, Vector3(1.0, 1.0, 0.78))
	for s: int in [-1, 1]:
		seg("Head", cone(0.065, 0.30), Vector3(0.09 * s, 0.84, 0.58), Vector3(0.20 * s, 0.99, 0.35), "shadow_bone", Vector3.UP)
	part("Head", box(0.18, 0.05, 0.08), Vector3(0, 0.875, 0.68), "shadow_glow", Vector3(10, 0, 0))
	var jaw := pivot("Jaw", "Head", Vector3(0, 0.66, 0.56))
	jaw.set_meta(&"keep_separate", true)
	part("Jaw", box(0.18, 0.07, 0.36), Vector3(0, 0.645, 0.76), "shadow_bone", Vector3(-4, 0, 0), Vector3.ONE, "", true)
	gold_trim("Head", Vector3(0, 0.78, 0.60), 0.85, Vector3(62, 0, 0))
	# Legs: thin shadow-flesh limbs (dark, like the body), front ones straight, back ones raked under the body (tensed
	# to pounce). Lab pass: the bone stays on top (skull, horns, spine, spikes, ribs) so the hound is light on top and
	# dark at the ground, and the busy bone-vs-black leg stripes no longer flicker at 25-40 m.
	for l: String in ["LegFL", "LegFR", "LegBL", "LegBR"]:
		var t: Vector3 = piv_pos[l]
		var front := t.z > 0.0
		var paw := Vector3(t.x * 1.1, 0.04, t.z + (0.08 if front else 0.14))
		limb(l, t, paw, 0.055 if front else 0.065, "shadow_leather")
	seg("Tail", cone(0.05, 0.36, 6), Vector3(0, 0.62, -0.64), Vector3(0, 0.80, -0.95), "shadow_bone", Vector3.BACK, "", true)
	piv["Tail"].set_meta(&"keep_separate", true)
	death_fx(0.9, 0.5)
	blob(0.4 * 2.6 * 1.2, SHADOW_BLOB)
	finish("res://art/units/shadow/grave_hound.tscn", SCRIPT_SHADOW, {"stride_speed": 7.0, "idle_period": 2.0, "flinch_push": true, "walk_bounce": 0.05, "kingdom_color": SHADOW_KINGDOM, "unit_kind": &"hound", "attack_style": &"bite", "attack_windup": 0.0, "death_style": &"sink", "stride_time": 0.40, "body_height": 1.0, "is_quadruped": true, "glow_gain": 1.8})


# ---------------------------------------------------------------- 5.5 Shadow Knight (elite, 2.4 m) - budget 30

func _build_knight() -> void:
	begin("ShadowKnight", 2.4)
	biped_pivots(0.82, 0.26, Vector3(0.66, 1.80, 0), 1.86)
	fx_node()
	leg("LegL", 0.16, 0.64, 1.5, "shadow_obsidian", "shadow_silver")
	leg("LegR", 0.16, 0.64, 1.5, "shadow_obsidian", "shadow_silver")
	# Team-colour plate skirt (tassets) and torso; black obsidian breastplate with the violet rune line.
	part("Hips", cyl(0.40, 0.52, 0.44, 8), Vector3(0, 0.92, 0), "shadow_cloth", Vector3(0, 22.5, 0), Vector3.ONE, "", false, true)
	part("Chest", cyl(0.51, 0.36, 0.82, 10), Vector3(0, 1.45, 0), "shadow_cloth", Vector3.ZERO, Vector3(0.9, 1, 0.85), "", false, true)
	part("Chest", box(0.78, 0.58, 0.22), Vector3(0, 1.52, 0.28), "shadow_obsidian", Vector3(-4, 0, 0), Vector3.ONE, "", false, true)
	part("Chest", prism(0.78, 0.26, 0.22), Vector3(0, 1.935, 0.27), "shadow_obsidian", Vector3(-4, 0, 0))
	part("Chest", box(0.07, 0.52, 0.03), Vector3(0, 1.52, 0.40), "shadow_glow_mid", Vector3(-4, 0, 0))
	# Team-colour slab pauldrons (the kingdom colour must read from the top camera), silver spikes raked outward.
	for s: int in [-1, 1]:
		part("Chest", box(0.46, 0.20, 0.52), Vector3(0.64 * s, 1.90, 0), "shadow_cloth", Vector3(0, 0, -24 * s), Vector3.ONE, "", false, true)
		part("Chest", cone(0.10, 0.52), Vector3(0.76 * s, 2.18, -0.02), "shadow_silver", Vector3(0, 0, -38 * s), Vector3.ONE, "", false, true)
	var cape_m := PlaneMesh.new()
	cape_m.size = Vector2(1.05, 1.85)
	cape_m.orientation = PlaneMesh.FACE_Z
	cape_m.subdivide_depth = 6
	part("Chest", cape_m, Vector3(0, 1.10, -0.47), "shadow_cape", Vector3(6, 0, 0), Vector3.ONE, "Cape", true)
	# Great helm, horns that curl up, a glowing visor slit.
	# Tapered 8-sided great helm: a small top cap, so the obsidian spec never paints a big flat grey square.
	part("Head", cyl(0.15, 0.34, 0.62, 8), Vector3(0, 2.15, 0), "shadow_obsidian", Vector3(0, 22.5, 0), Vector3.ONE, "", false, true)
	for s: int in [-1, 1]:
		var base := Vector3(0.18 * s, 2.34, 0)
		var d1 := Vector3(0.766 * s, 0.643, 0)
		var tip1 := base + d1 * 0.56
		seg("Head", cone(0.11, 0.60), base, tip1, "shadow_silver", Vector3.BACK, "", false, true, 0.5)
		var d2 := Vector3(0.26 * s, 0.97, 0)
		seg("Head", cone(0.07, 0.34), tip1 - d1 * 0.06, tip1 - d1 * 0.06 + d2 * 0.34, "shadow_silver")
	part("Head", box(0.22, 0.085, 0.08), Vector3(0, 2.14, 0.26), "shadow_glow_mid")
	gold_trim("Head", Vector3(0, 1.98, 0), 1.55)
	# Great sword resting on the right shoulder (tilted 35 deg back); left hand joins the grip.
	var hr := Vector3(0.42, 1.40, 0.40)
	var hl := Vector3(0.20, 1.26, 0.44)
	arm("ArmR", hr, 0.135, 0.15, "shadow_obsidian", "shadow_obsidian", true, true)
	arm("ArmL", hl, 0.135, 0.15, "shadow_obsidian", "shadow_obsidian", false, true)
	var d := Vector3(0.08, 0.81, -0.58).normalized()
	var face := Vector3(0, 0.58, 0.81)
	seg("ArmR", cyl(0.05, 0.05, 0.50, 6), hr - d * 0.28, hr + d * 0.22, "shadow_obsidian", face)
	seg("ArmR", box(0.66, 0.09, 0.15), hr + d * 0.22, hr + d * 0.31, "shadow_silver", face, "", false, true)
	seg("ArmR", prism(0.28, 1.78, 0.06), hr + d * 0.31, hr + d * 2.09, "shadow_silver", face, "", false, true)
	seg("ArmR", box(0.075, 1.30, 0.03), hr + d * 0.40 + face * 0.035, hr + d * 1.70 + face * 0.035, "shadow_glow_hero", face, "Fuller")
	emitter("ArmR", "Sparks", hr + d * 1.6, 14, 0.5, Color(0.8, 0.4, 1.0), 0.15, 3.8, 70.0, -6.0, Vector3(0.1, 0.3, 0.1), false, "shadow_particle")
	emitter("ArmR", "Slam", hr + d * 1.9, 8, 0.7, Color(0.20, 0.08, 0.32, 0.6), 0.9, 2.2, 85.0, 0.5, Vector3(0.15, 0.1, 0.15), false, "shadow_smoke", false, true)
	death_fx(2.4, 0.7)
	blob(0.7 * 2.6, SHADOW_BLOB)
	finish("res://art/units/shadow/shadow_knight.tscn", SCRIPT_SHADOW, {"stride_speed": 4.0, "kingdom_color": SHADOW_KINGDOM, "unit_kind": &"knight", "attack_style": &"great_swing", "attack_windup": 0.0, "death_style": &"sink", "stride_time": 0.64, "body_height": 2.4, "is_quadruped": false, "glow_gain": 1.1})


# ---------------------------------------------------------------- 5.6 Ruin Warden (neutral, 1.8 m) - budget 22

func _build_warden() -> void:
	begin("RuinWarden", 1.8)
	biped_pivots(0.62, 0.24, Vector3(0.66, 1.40, 0), 1.56, 0.05)
	fx_node()
	for s: int in [-1, 1]:
		var pv := "LegR" if s > 0 else "LegL"
		part(pv, box(0.28, 0.52, 0.32), Vector3(0.24 * s, 0.36, 0), "warden_stone_dark", Vector3(0, 0, 3 * s))
		part(pv, box(0.36, 0.17, 0.46), Vector3(0.25 * s, 0.085, 0.06), "warden_stone_dark", Vector3(0, 6 * s, 0))
	# Hip block (dark) under a cracked, glowing torso slab with a moss cap.
	part("Chest", box(0.70, 0.22, 0.48), Vector3(0, 0.70, 0), "warden_stone_dark", Vector3(0, 4, 0), Vector3.ONE, "", false, true)
	part("Chest", box(0.82, 0.70, 0.56), Vector3(0, 1.07, 0), "warden_stone", Vector3(8, 0, 0), Vector3.ONE, "", false, true)
	part("Chest", box(0.88, 0.13, 0.64), Vector3(0, 1.46, 0.03), "warden_moss", Vector3(8, 0, 2), Vector3.ONE, "", false, true)
	part("Chest", box(0.40, 0.40, 0.40), Vector3(0.58, 1.44, 0), "warden_stone_dark", Vector3(0, 12, -12), Vector3.ONE, "", false, true)
	part("Chest", box(0.38, 0.38, 0.38), Vector3(-0.58, 1.40, 0), "warden_stone_dark", Vector3(10, -8, 14), Vector3.ONE, "", false, true)
	part("Chest", box(0.30, 0.10, 0.30), Vector3(0.60, 1.66, 0.0), "warden_moss", Vector3(0, 12, -12))
	# The broken column it still carries on its back (the asymmetric "ruin" secondary element).
	part("Chest", cyl(0.17, 0.19, 0.95, 8), Vector3(-0.22, 1.42, -0.34), "warden_stone", Vector3(-12, 0, 24), Vector3.ONE, "", false, true)
	part("Head", box(0.42, 0.34, 0.40), Vector3(0, 1.75, 0.06), "warden_stone", Vector3(0, 4, 0), Vector3.ONE, "", false, true)
	part("Head", box(0.28, 0.08, 0.06), Vector3(0, 1.77, 0.27), "warden_glow")
	part("Chest", sph(0.10, 10, 5), Vector3(0, 1.54, 0.05), "warden_glow", Vector3.ZERO, Vector3(2.4, 0.5, 2.2), "GapLight", true)
	for s: int in [-1, 1]:
		var pv := "ArmR" if s > 0 else "ArmL"
		part(pv, box(0.24, 0.56, 0.24), Vector3(0.68 * s, 1.14, 0.02), "warden_stone", Vector3(0, 0, 4 * s), Vector3.ONE, "", false, s > 0)
		part(pv, box(0.30, 0.28, 0.30), Vector3(0.70 * s, 0.80, 0.06), "warden_stone_dark", Vector3(8, 20 * s, 6 * s))
	# Ruin mace: a broken capital, head down, held forward.
	var h := Vector3(0.70, 0.80, 0.06)
	var d := Vector3(0.0, -0.866, 0.5)
	seg("ArmR", cyl(0.055, 0.055, 0.80, 6), h - d * 0.12, h + d * 0.62, "warden_stone_dark")
	part("ArmR", box(0.36, 0.34, 0.36), h + d * 0.74, "warden_stone_dark", Vector3(-30, 20, 0), Vector3.ONE, "", false, true)
	part("ArmR", box(0.40, 0.07, 0.40), h + d * 0.74 + Vector3(0, 0.18, -0.05), "warden_moss", Vector3(-30, 20, 0))
	emitter("Fx", "Motes", Vector3(0, 1.0, 0), 6, 2.0, Color(1.0, 0.85, 0.3), 0.08, 0.3, 15.0, 0.0, Vector3(0.35, 0.3, 0.25), true, "warden_particle")
	emitter("Fx", "DeathDust", Vector3(0, 0.5, 0), 10, 1.0, Color(0.50, 0.52, 0.42, 0.7), 0.6, 1.2, 75.0, -0.5, Vector3(0.45, 0.35, 0.3), false, "shadow_smoke", true, true)
	emitter("ArmR", "Slam", h + d * 0.9, 6, 0.6, Color(0.55, 0.55, 0.45, 0.55), 0.6, 1.6, 80.0, 0.0, Vector3(0.12, 0.05, 0.12), false, "shadow_smoke", false, true)
	rubble_emitter("Fx", "Rubble", Vector3(0, 1.1, 0))
	blob(0.5 * 2.6, WARDEN_BLOB)
	# A2.7 rebuilt the warden (art/units/neutral/warden_model.gd): this old build must not overwrite it.
	#finish("res://art/units/neutral/ruin_warden.tscn", SCRIPT_SHADOW, {"stride_speed": 4.0, "idle_period": 4.0, "swing_scale": 1.15, "leg_swing_deg": 18.0, "walk_bounce": 0.03, "flinch_push": true, "kingdom_color": Color(0.45, 0.50, 0.40), "unit_kind": &"warden", "attack_style": &"melee_swing", "attack_windup": 0.0, "death_style": &"crumble", "stride_time": 0.80, "body_height": 1.8, "is_quadruped": false, "glow_gain": 1.15})

extends WizardModel
## Vessa, the Ember Queen (art-units.md 3.1; polish pass A.1). Read from the RTS camera by three verticals and a
## colour split: a tall crimson witch-crown hat bent back (so the face shows at pitch 55) ringed by glowing crown
## flames, a staff whose "caged sun" floats in four bronze claws above the hat line, and a curved flame-glyph cape
## that wraps the shoulders. Orange mantle with flame-tongue pauldrons and a standing crimson collar over a
## crimson gown licked by painted flame tongues, smouldering at the hem.
## Casts (6.5): fireball (charge in the off hand, lunge-point with the staff), ember_step (crouch and spring),
## kindle (both arms up, crown blazes). Extras: cape billows with the walk, level-up pirouette, head snap on hit,
## gasp-and-reach death, and (close camera only) idle fidgets: she plays with a flame in her palm, taps the staff.
## Face (smile pass): ember eyes with dark pupils and lashes, brows, blush, button nose and a smile, painted as decals
## on the face sphere; `set_expression(&"neutral" | &"smile" | &"fierce")` for cinematics (see EXPRESSIONS).
## Death style fall. Only palette materials (kit/materials); per-unit looks through instance uniforms / node scale.

const FIRE_GLOW := Color(1.0, 0.55, 0.15)
const HAT_O := Vector3(0.0, 1.99, -0.05)      # hat frame origin (brim centre, model space)
const HAT_TILT := -15.0                        # deg about X: the hat leans back so the eye bar clears the brim
const SHOULDER_L := Vector3(-0.42, 1.40, 0.0)
const SHOULDER_R := Vector3(0.42, 1.40, 0.0)
const HAND_L := Vector3(-0.54, 0.99, 0.08)
const HAND_R := Vector3(0.52, 0.99, 0.22)
const STAFF_X := 0.52
const STAFF_Z := 0.22
const ORB_Y := 2.60
const FIDGET_FLAME := &"_idle_flame"
const FIDGET_STAFF := &"_idle_staff"
## Face (smile pass): features are painted-style decals projected onto the low-poly face sphere (they follow its
## facets, 2-6 mm above it). Face 2D coords: metres of arc from the face centre, +x = model +X, +y = up.
const FACE_C := Vector3(0.0, 1.78, 0.02)
const FACE_R := 0.25
const FACE_SEG := 12
const FACE_RINGS := 6
## Expressions: neutral = soft closed smile, ember eyes open (gameplay default: warm, never goofy mid-battle);
## smile = open laugh, happy-closed glowing eye arcs, raised brows, bigger blush (cinematics, "laughed like sunrise");
## fierce = brows down, narrowed eyes, a set smirk. Casts / attacks show fierce and a level-up shows smile while the
## requested expression is neutral (close camera only; the requested one comes back after).
const EXPRESSIONS: Array[StringName] = [&"neutral", &"smile", &"fierce"]

static var _cape_cache: ArrayMesh
static var _face_cache: Dictionary = {}       # expression -> ArrayMesh (features + hat gem)
static var _face_tris: PackedVector3Array     # the face sphere's triangles (centred), for the decal projection
static var _glow_cache: Dictionary = {}       # name -> ArrayMesh (glow-only parts)
static var _ember_draw: Dictionary = {}       # size -> QuadMesh (soft round additive ember)
static var _ember_proc: Dictionary = {}       # key -> ParticleProcessMaterial

var _flames: MultiMeshInstance3D
var _palm: MeshInstance3D
var _cape: MeshInstance3D
var _flame_scale: float = 1.0       # crown flame target, set by poses each frame
var _flame_written: float = -1.0
var _flame_boost_written: float = -1.0
var _palm_target: float = 0.0       # palm flame size 0-1, set by poses each frame
var _palm_written: float = -1.0
var _cape_kick: float = 0.0         # extra cape lift (deg), set by poses each frame
var _cape_written: float = 999.0
var _fidget_next: float = 8.0
var _fidget_alt: bool = false
var _face: MeshInstance3D
var _expr: StringName = &"neutral"  # requested by set_expression
var _face_shown: StringName = &""


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := palette(&"fire_cloth")
	var dark := palette(&"fire_cloth_dark")
	var bronze := palette(&"fire_bronze")
	var skin := palette(&"fire_skin")
	var hair := palette(&"fire_hair")
	var gold_cloth := palette(&"fire_sec_archer")

	# ---- Hips: crimson bell gown, painted flame tongues licking up from a dark hem, smouldering ember line.
	add_part(hips, cyl(0.30, 0.52, 0.85, 16), dark, Vector3(0, 0.43, 0))
	add_part(hips, torus(0.47, 0.56, 16), palette(&"fire_leather"), Vector3(0, 0.055, 0))
	_glow_part(hips, "HemGlow", [[torus(0.495, 0.535, 16), Transform3D(Basis.IDENTITY, Vector3(0, 0.115, 0)), palette(&"fire_glow")]])
	add_part(hips, torus(0.27, 0.34, 12), bronze, Vector3(0, 0.86, 0))
	add_part(hips, box(Vector3(0.16, 0.14, 0.06)), bronze, Vector3(0, 0.86, 0.33))
	var slope := atan2(0.22, 0.85)
	for i: int in 10:
		var a := TAU * float(i) / 10.0 + 0.31
		var tall := i % 2 == 0
		var h := 0.46 if tall else 0.32
		var yc := 0.12 + h * 0.5
		var r := 0.52 - 0.22 * (yc / 0.85) + 0.022
		var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -slope)
		add_part(hips, prism(Vector3(0.22 if tall else 0.18, h, 0.04)), cloth if tall else gold_cloth,
			Vector3(sin(a) * r, yc, cos(a) * r), b.get_euler() / DEG)

	# ---- Chest: torso, orange mantle + bronze rim, flame pauldrons, standing collar, brooch, curved cape.
	add_part(chest, cyl(0.34, 0.28, 0.55, 10), dark, Vector3(0, 1.12, 0))
	add_part(chest, cyl(0.28, 0.54, 0.30, 14), cloth, Vector3(0, 1.42, 0))
	add_part(chest, torus(0.50, 0.58, 16), bronze, Vector3(0, 1.28, 0))
	# Crimson V neckline lying on the mantle front (darkens the area under the face), bronze brooch at its tip.
	var nb := Basis(Vector3.RIGHT, -41.0 * DEG) * Basis(Vector3.BACK, PI)
	add_part(chest, prism(Vector3(0.30, 0.30, 0.03)), dark, Vector3(0, 1.45, 0.40), nb.get_euler() / DEG)
	add_part(chest, sphere(0.11, 8, 4), bronze, Vector3(0, 1.34, 0.49), Vector3.ZERO, Vector3(1.0, 1.0, 0.55))
	add_part(chest, torus(0.18, 0.25, 10), bronze, Vector3(0, 1.57, -0.01))
	for sx: float in [-1.0, 1.0]:
		add_part(chest, sphere(0.14, 8, 4), bronze, Vector3(0.44 * sx, 1.44, 0), Vector3.ZERO, Vector3(1.0, 0.75, 1.0))
		var tongues := [[28.0, 0.30, -0.05, cloth], [56.0, 0.34, 0.03, gold_cloth], [84.0, 0.26, -0.02, cloth]]
		for tg: Array in tongues:
			var ang: float = tg[0] * DEG * sx
			var dir := Vector3(sin(ang), cos(ang), tg[2])
			_segment(chest, cyl(0.0, 0.085, tg[1], 6), tg[3], Vector3(0.46 * sx, 1.46, 0), dir.normalized(), tg[1])
	for k: int in 5:
		var a := (-72.0 + 36.0 * float(k)) * DEG
		var dir := Vector3(sin(a), 0.0, -cos(a))
		var h := 0.46 if k == 2 else (0.40 if k % 2 == 1 else 0.32)
		var b := Basis(Vector3.UP, atan2(dir.x, dir.z)) * Basis(Vector3.RIGHT, 24.0 * DEG)
		var base := Vector3(0, 1.55, -0.01) + dir * 0.22
		add_part(chest, prism(Vector3(0.20, h, 0.05)), dark, base + b * Vector3(0, h * 0.5, 0), b.get_euler() / DEG)
	_cape = add_part(chest, _cape_mesh(), null, Vector3(0, 1.58, -0.02), Vector3(3, 0, 0),
		Vector3.ONE, true, "Cape")

	# ---- Head: face, dark hair framing it, glowing eye bar, bent crown-hat.
	add_part(head, sphere(FACE_R, FACE_SEG, FACE_RINGS), skin, FACE_C)
	add_part(head, sphere(0.024, 8, 4), skin, Vector3(0, 1.762, 0.262), Vector3.ZERO, Vector3(0.9, 0.75, 0.8))   # button nose
	add_part(head, sphere(0.27), hair, Vector3(0, 1.85, -0.06), Vector3.ZERO, Vector3(1.04, 0.86, 1.0))
	add_part(head, sphere(0.24, 8, 4), hair, Vector3(0, 1.64, -0.15), Vector3.ZERO, Vector3(1.1, 1.3, 0.8))
	for sx: float in [-1.0, 1.0]:
		add_part(head, cyl(0.07, 0.08, 0.38, 6), hair, Vector3(0.20 * sx, 1.66, 0.09), Vector3(0, 0, -8.0 * sx))
	_hat_part(head, cyl(0.40, 0.47, 0.06, 12), dark, Vector3(0, 0.0, 0))
	_hat_part(head, cyl(0.265, 0.28, 0.13, 10), bronze, Vector3(0, 0.09, 0))
	_hat_part(head, cyl(0.16, 0.27, 0.42, 10), dark, Vector3(0, 0.27, 0))
	var b1 := Basis.from_euler(Vector3(-6.0 * DEG, 0, 16.0 * DEG))   # the tip curls back and to her off side
	var p1 := Vector3(0, 0.47, 0)
	_hat_part(head, cyl(0.085, 0.165, 0.34, 8), dark, p1 + b1 * Vector3(0, 0.17, 0), b1)
	var b2 := Basis.from_euler(Vector3(-12.0 * DEG, 0, 44.0 * DEG))
	var p2 := p1 + b1 * Vector3(0, 0.33, 0)
	_hat_part(head, cyl(0.0, 0.09, 0.28, 8), dark, p2 + b2 * Vector3(0, 0.13, 0), b2)
	# Face (eyes, brows, cheeks, mouth) + the hat gem: ONE keep_separate node whose cached mesh is swapped per
	# expression (set_expression), so the three faces cost one draw instance (the old HeadGlow eye bar's).
	_face = add_part(head, _face_mesh(_face_target()), null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "Face")
	_face_shown = _face_target()
	# Crown flames: one MultiMesh, 6 tongues (tall / short) around the band, leaning out.
	_flames = MultiMeshInstance3D.new()
	_flames.name = "CrownFlames"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cyl(0.0, 0.10, 0.34, 6)
	mm.instance_count = 6
	for i: int in 6:
		var a := TAU * (float(i) + 0.5) / 6.0     # a gap at the front for the gem
		var out := Vector3(sin(a), 0, cos(a))
		var hs := 1.0 if i % 2 == 0 else 0.72
		var b := Basis(Vector3.UP.cross(out).normalized(), 20.0 * DEG).scaled(Vector3(1.0, hs, 1.0))
		mm.set_instance_transform(i, Transform3D(b, out * 0.29 + Vector3(0, 0.10, 0) + b * Vector3(0, 0.17, 0)))
	_flames.multimesh = mm
	_flames.material_override = palette(&"fire_flame")
	_flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flames.set_meta(&"own_glow", true)
	_flames.transform = Transform3D(Basis(Vector3.RIGHT, HAT_TILT * DEG), HAT_O - model_origin(head))
	head.add_child(_flames)

	# ---- Arms: orange sleeves with crimson bell cuffs; ArmR holds the staff, ArmL carries the (hidden) palm flame.
	_arm(arm_l, SHOULDER_L, HAND_L, cloth, dark, skin)
	_arm(arm_r, SHOULDER_R, HAND_R, cloth, dark, skin)
	_palm = add_part(arm_l, sphere(0.11), palette(&"fire_glow_hero"), HAND_L + Vector3(0, 0.15, 0.07),
		Vector3.ZERO, Vector3(1.0, 1.4, 1.0), true, "PalmFlame")
	_palm.set_meta(&"own_glow", true)
	_palm.visible = false

	# ---- Staff: wood shaft with bronze foot, grips and head collar; four bronze claws cage the floating sun.
	var sp := Vector3(STAFF_X, 0, STAFF_Z)
	add_part(arm_r, cyl(0.05, 0.06, 2.36, 8), palette(&"fire_wood"), sp + Vector3(0, 1.24, 0))
	add_part(arm_r, cyl(0.075, 0.05, 0.12, 8), bronze, sp + Vector3(0, 0.10, 0))
	add_part(arm_r, torus(0.045, 0.09, 8), bronze, sp + Vector3(0, 1.13, 0))
	add_part(arm_r, torus(0.045, 0.09, 8), bronze, sp + Vector3(0, 0.85, 0))
	add_part(arm_r, cyl(0.12, 0.06, 0.18, 8), bronze, sp + Vector3(0, 2.40, 0))
	for k: int in 4:
		var a := (45.0 + 90.0 * float(k)) * DEG
		var o := Vector3(sin(a), 0, cos(a))
		var p0 := sp + Vector3(0, 2.45, 0) + o * 0.09
		var pm := sp + Vector3(0, ORB_Y - 0.03, 0) + o * 0.26
		var pt := sp + Vector3(0, ORB_Y + 0.10, 0) + o * 0.21
		_segment(arm_r, cyl(0.03, 0.045, (pm - p0).length() + 0.04, 5), bronze, p0, (pm - p0).normalized(), (pm - p0).length() + 0.04)
		_segment(arm_r, cyl(0.0, 0.04, (pt - pm).length() + 0.03, 5), bronze, pm, (pt - pm).normalized(), (pt - pm).length() + 0.03)
	var orb := add_part(arm_r, sphere(0.21, 12, 6), palette(&"fire_glow_hero"), sp + Vector3(0, ORB_Y, 0),
		Vector3.ZERO, Vector3.ONE, true, "Orb")
	orb.set_meta(&"own_glow", true)
	_orb = orb
	_bob = orb
	_bob_rest = orb.position
	_light = OmniLight3D.new()
	_light.name = "OrbLight"
	_light.light_color = Color(1.0, 0.55, 0.20)
	_light.light_energy = light_energy
	_light.omni_range = 4.5
	_light.shadow_enabled = false
	_light.position = orb.position
	arm_r.add_child(_light)
	var motes := _embers(8, 1.6, 0.22, 0.45, 0.10, false)
	motes.name = "EmberMotes"
	motes.position = orb.position
	arm_r.add_child(motes)
	var burst := _embers(14, 1.0, 0.45, 1.8, 0.16, true)
	burst.name = "DeathEmbers"
	burst.set_meta(&"death_fx", true)
	burst.position = Vector3(0, 0.9, 0.3)
	$Fx.add_child(burst)
	ensure_shadow_blob(0.55)


## Glow parts get their own instance: the kit shaders both use instance-uniform slot 0 (painted ao_bottom,
## glow glow_boost), so a glow surface merged with painted ones reads glow_boost = 0 and shows dull. Parts:
## [[mesh, model-space Transform3D, material], ...] -> one surface each, cached per name. The kit drives glow_boost.
func _glow_part(pivot: Node3D, part_name: String, parts: Array) -> MeshInstance3D:
	var am: ArrayMesh = _glow_cache.get(part_name)
	if am == null:
		am = ArrayMesh.new()
		for pt: Array in parts:
			var st := SurfaceTool.new()
			st.append_from(pt[0], 0, pt[1])
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
			am.surface_set_material(am.get_surface_count() - 1, pt[2])
		_glow_cache[part_name] = am
	return add_part(pivot, am, null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, part_name)


# ================================================================ face / expressions

## Cinematic / UI hook: &"neutral" (default), &"smile", &"fierce". Unknown ids fall back to neutral. Safe before
## _ready and any number of times (swaps a cached mesh: no allocation after the first instance of the type).
func set_expression(id: StringName) -> void:
	_expr = id if EXPRESSIONS.has(id) else &"neutral"
	_update_face()


func get_expression() -> StringName:
	return _expr


## The face to show now: the requested one, except that a neutral face turns fierce on casts / attacks and smiles on
## a level-up (close camera only, alive).
func _face_target() -> StringName:
	if _expr != &"neutral" or _dead or _tier != 0:
		return _expr
	if _level_t < 1.6 or (_action == &"cast" and _cast_id == FIDGET_FLAME):
		return &"smile"
	if (_action == &"cast" and _cast_id != FIDGET_FLAME and _cast_id != FIDGET_STAFF) or _action == &"attack":
		return &"fierce"
	return _expr


func _update_face() -> void:
	if _face == null:
		return
	var id := _face_target()
	if id != _face_shown:
		_face_shown = id
		_face.mesh = _face_mesh(id)


## Painted face decals + the hat gem for one expression, cached per type. Surfaces (one per palette material):
## fire_glow ember eyes, unit_eye_dark lashes / pupils, fire_hair brows, fire_leather mouth, fire_sec_hurler blush /
## tongue, unit_gold_trim eye highlights, fire_glow_hero hat gem.
static func _face_mesh(id: StringName) -> ArrayMesh:
	var cached: ArrayMesh = _face_cache.get(id)
	if cached:
		return cached
	if _face_tris.is_empty():
		_face_tris = sphere(FACE_R, FACE_SEG, FACE_RINGS).get_faces()
	var sf: Dictionary = {}
	var eye := Vector2(0.083, 0.024)
	for sx: float in [1.0, -1.0]:
		match id:
			&"smile":
				# Happy-closed eyes: glowing arcs with a dark lash line on top, brows up and arched, cheeks raised.
				var e := eye + Vector2(0, -0.004)
				_f_strip(sf, &"fire_glow", _fm(_bez(e + Vector2(-0.033, -0.004), e + Vector2(0.0, 0.036), e + Vector2(0.035, 0.0)), sx), Vector3(0.005, 0.0105, 0.0042), 0.0025)
				_f_strip(sf, &"unit_eye_dark", _fm(_bez(e + Vector2(-0.030, 0.006), e + Vector2(0.002, 0.044), e + Vector2(0.046, 0.012)), sx), Vector3(0.0018, 0.004, 0.0014), 0.004)
				_f_strip(sf, &"fire_hair", _fm(_bez(Vector2(0.040, 0.078), Vector2(0.084, 0.106), Vector2(0.128, 0.080)), sx), Vector3(0.006, 0.0075, 0.0025), 0.003)
				_f_fill(sf, &"fire_sec_hurler", _fm(_ellipse(Vector2(0.116, -0.030), Vector2(0.034, 0.017), 10.0, 14), sx), 0.002)
			&"fierce":
				_eye_open(sf, eye, 0.036, 0.016, 0.012, 0.012, 0.013, sx)
				_f_strip(sf, &"fire_hair", _fm(_bez(Vector2(0.034, 0.046), Vector2(0.078, 0.058), Vector2(0.130, 0.080)), sx), Vector3(0.0085, 0.008, 0.003), 0.003)
			_:
				_eye_open(sf, eye, 0.036, 0.024, 0.014, 0.005, 0.017, sx)
				_f_strip(sf, &"fire_hair", _fm(_bez(Vector2(0.042, 0.066), Vector2(0.085, 0.090), Vector2(0.128, 0.068)), sx), Vector3(0.0065, 0.0075, 0.0025), 0.003)
				_f_fill(sf, &"fire_sec_hurler", _fm(_ellipse(Vector2(0.118, -0.036), Vector2(0.030, 0.014), 8.0, 14), sx), 0.002)
	match id:
		&"smile":
			# Open laugh: a D-shaped mouth, lips turned up at the corners, a rosy tongue.
			var top := _bez(Vector2(-0.054, -0.066), Vector2(0.0, -0.078), Vector2(0.054, -0.066))
			var bot := _bez(Vector2(0.054, -0.066), Vector2(0.0, -0.152), Vector2(-0.054, -0.066))
			var d := PackedVector2Array(top)
			d.append_array(bot.slice(1, bot.size() - 1))
			_f_fill(sf, &"fire_leather", d, 0.0025)
			_f_fill(sf, &"fire_sec_hurler", _ellipse(Vector2(0.0, -0.097), Vector2(0.024, 0.009), 0.0, 14), 0.004)
			for sx: float in [1.0, -1.0]:
				_f_strip(sf, &"fire_leather", _fm(PackedVector2Array([Vector2(0.050, -0.068), Vector2(0.060, -0.063), Vector2(0.065, -0.055)]), sx), Vector3(0.0028, 0.0022, 0.0012), 0.003)
		&"fierce":
			# A set smirk, one corner up.
			_f_strip(sf, &"fire_leather", _bez(Vector2(-0.040, -0.086), Vector2(0.004, -0.094), Vector2(0.046, -0.073)), Vector3(0.0025, 0.005, 0.003), 0.003)
			_f_strip(sf, &"fire_leather", PackedVector2Array([Vector2(0.044, -0.075), Vector2(0.050, -0.066)]), Vector3(0.0025, 0.002, 0.0012), 0.003)
		_:
			# Soft closed smile, corners up.
			_f_strip(sf, &"fire_leather", _bez(Vector2(-0.046, -0.080), Vector2(0.0, -0.103), Vector2(0.046, -0.080)), Vector3(0.0026, 0.0072, 0.0026), 0.003)
			for sx: float in [1.0, -1.0]:
				_f_strip(sf, &"fire_leather", _fm(PackedVector2Array([Vector2(0.044, -0.081), Vector2(0.052, -0.074)]), sx), Vector3(0.0026, 0.002, 0.0012), 0.003)
	var am := ArrayMesh.new()
	for mat: StringName in [&"fire_glow", &"unit_eye_dark", &"unit_gold_trim", &"fire_hair", &"fire_leather", &"fire_sec_hurler"]:
		if not sf.has(mat):
			continue
		var s: Array = sf[mat]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s[0]
		arrays[Mesh.ARRAY_NORMAL] = s[1]
		arrays[Mesh.ARRAY_INDEX] = s[2]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, palette(mat))
	# The hat gem (was in HeadGlow): hat frame, tilted back.
	var hat_xf := Transform3D(Basis(Vector3.RIGHT, HAT_TILT * DEG), HAT_O)
	var st := SurfaceTool.new()
	st.append_from(sphere(0.085), 0, hat_xf * Transform3D(Basis.IDENTITY, Vector3(0, 0.09, 0.285)))
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	am.surface_set_material(am.get_surface_count() - 1, palette(&"fire_glow_hero"))
	_face_cache[id] = am
	return am


## An open ember eye at `c` (mirrored by sx): glowing almond (half width hw, top / bottom heights, outer corner lifted
## by `tilt`), dark pupil with a gold highlight, a dark upper lash line ending in a small flick.
static func _eye_open(sf: Dictionary, c: Vector2, hw: float, top: float, bot: float, tilt: float, pupil_h: float, sx: float) -> void:
	var up := PackedVector2Array()
	var lo := PackedVector2Array()
	for i: int in 9:
		var t := float(i) / 8.0
		var x := c.x - hw + 2.0 * hw * t
		var ty := c.y + tilt * (t - 0.5)
		up.append(Vector2(x, ty + top * sin(PI * t)))
		lo.append(Vector2(x, ty - bot * sin(PI * t)))
	var poly := PackedVector2Array(up)
	lo.reverse()
	poly.append_array(lo.slice(1, lo.size() - 1))
	_f_fill(sf, &"fire_glow", _fm(poly, sx), 0.0025)
	var pc := c + Vector2(0.002, 0.001)
	_f_fill(sf, &"unit_eye_dark", _fm(_ellipse(pc, Vector2(0.0115, pupil_h), 0.0, 12), sx), 0.0038)
	_f_fill(sf, &"unit_gold_trim", _fm(_ellipse(pc + Vector2(0.005, 0.006), Vector2(0.0045, 0.0045), 0.0, 8), sx), 0.0052)
	var lash := PackedVector2Array(up)
	lash.append(up[8] + Vector2(0.011, 0.010))
	_f_strip(sf, &"unit_eye_dark", _fm(lash, sx), Vector3(0.0024, 0.0066, 0.002), 0.0045)


## Quadratic Bezier p0 -> p2 (control p1), 12 segments.
static func _bez(p0: Vector2, p1: Vector2, p2: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in 13:
		var t := float(i) / 12.0
		out.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return out


static func _ellipse(c: Vector2, r: Vector2, rot_deg: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var b := Transform2D(rot_deg * DEG, Vector2.ZERO)
	for i: int in n:
		var a := TAU * float(i) / float(n)
		out.append(c + b * Vector2(cos(a) * r.x, sin(a) * r.y))
	return out


## Mirror face points to her other side (sx = -1).
static func _fm(pts: PackedVector2Array, sx: float) -> PackedVector2Array:
	if sx > 0.0:
		return pts
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(Vector2(-p.x, p.y))
	return out


## Face 2D point -> model space on the face sphere's facets, `lift` m out; normal = the sphere direction.
static func _face_point(p: Vector2, lift: float) -> Array:
	var az := p.x / FACE_R
	var el := p.y / FACE_R
	var d := Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
	var dist := FACE_R
	for i: int in range(0, _face_tris.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3.ZERO, d, _face_tris[i], _face_tris[i + 1], _face_tris[i + 2])
		if hit != null:
			dist = (hit as Vector3).length()
			break
	return [FACE_C + d * (dist + lift), d]


static func _fv(sf: Dictionary, mat: StringName, p: Vector2, lift: float) -> int:
	if not sf.has(mat):
		sf[mat] = [PackedVector3Array(), PackedVector3Array(), PackedInt32Array()]
	var s: Array = sf[mat]
	var pn := _face_point(p, lift)
	var v: PackedVector3Array = s[0]
	var nm: PackedVector3Array = s[1]
	v.append(pn[0])
	nm.append(pn[1])
	s[0] = v
	s[1] = nm
	return v.size() - 1


## Both windings (the decal is seen from outside only; the inner copy is culled), shared vertices.
static func _ftri(sf: Dictionary, mat: StringName, a: int, b: int, c: int) -> void:
	var idx: PackedInt32Array = sf[mat][2]
	idx.append_array(PackedInt32Array([a, b, c, a, c, b]))
	sf[mat][2] = idx


static func _resample(pts: PackedVector2Array, step: float, closed: bool) -> PackedVector2Array:
	var out := PackedVector2Array([pts[0]])
	var n := pts.size()
	for i: int in range(1, n + (1 if closed else 0)):
		var a := pts[i - 1]
		var b := pts[i % n]
		var k := maxi(1, ceili(a.distance_to(b) / step))
		for j: int in range(1, k + 1):
			out.append(a.lerp(b, float(j) / float(k)))
	if closed:
		out.remove_at(out.size() - 1)
	return out


## A tapered band along a polyline; w = half widths at start / middle / end.
static func _f_strip(sf: Dictionary, mat: StringName, pts: PackedVector2Array, w: Vector3, lift: float) -> void:
	var p := _resample(pts, 0.008, false)
	var n := p.size()
	var acc := PackedFloat32Array([0.0])
	for i: int in range(1, n):
		acc.append(acc[i - 1] + p[i - 1].distance_to(p[i]))
	var total := maxf(acc[n - 1], 0.0001)
	var pa := -1
	var pb := -1
	for i: int in n:
		var t := acc[i] / total
		var hw := lerpf(w.x, w.y, t * 2.0) if t < 0.5 else lerpf(w.y, w.z, t * 2.0 - 1.0)
		var dir := (p[mini(i + 1, n - 1)] - p[maxi(i - 1, 0)]).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		var ia := _fv(sf, mat, p[i] + nrm * hw, lift)
		var ib := _fv(sf, mat, p[i] - nrm * hw, lift)
		if pa >= 0:
			_ftri(sf, mat, pa, pb, ib)
			_ftri(sf, mat, pa, ib, ia)
		pa = ia
		pb = ib


## A filled star-shaped polygon: centroid fan with 1-2 rings (small triangles so the decal follows the facets).
static func _f_fill(sf: Dictionary, mat: StringName, poly: PackedVector2Array, lift: float) -> void:
	var b := _resample(poly, 0.010, true)
	var c := Vector2.ZERO
	for q: Vector2 in poly:
		c += q
	c /= float(poly.size())
	var n := b.size()
	var rings := 1 if float(n) * 0.010 < 0.06 else 2      # tiny shapes (pupils, highlights) need no inner ring
	var ci := _fv(sf, mat, c, lift)
	var prev: Array[int] = []
	for r: int in range(1, rings + 1):
		var ring: Array[int] = []
		for k: int in n:
			ring.append(_fv(sf, mat, c.lerp(b[k], float(r) / float(rings)), lift))
		for k: int in n:
			var k2 := (k + 1) % n
			if r == 1:
				_ftri(sf, mat, ci, ring[k], ring[k2])
			else:
				_ftri(sf, mat, prev[k], ring[k], ring[k2])
				_ftri(sf, mat, prev[k], ring[k2], prev[k2])
		prev = ring


## A part whose transform is given in the hat frame (brim centre, tilted back).
func _hat_part(head: Node3D, mesh: Mesh, mat: Material, local: Vector3, lb: Basis = Basis.IDENTITY) -> void:
	var hb := Basis(Vector3.RIGHT, HAT_TILT * DEG)
	add_part(head, mesh, mat, HAT_O + hb * local, (hb * lb).get_euler() / DEG)


## A cylinder / cone (mesh axis +Y) standing on `base` and pointing along `dir`, total length `len`.
func _segment(pivot: Node3D, mesh: Mesh, mat: Material, base: Vector3, dir: Vector3, len: float) -> void:
	var b := Basis(Quaternion(Vector3.UP, dir))
	add_part(pivot, mesh, mat, base + dir * (len * 0.5), b.get_euler() / DEG)


## Sleeve capsule + crimson bell cuff at the wrist + fist.
func _arm(pivot: Node3D, shoulder: Vector3, hand: Vector3, sleeve: Material, cuff: Material, skin: Material) -> void:
	var d := hand - shoulder
	var e := Basis(Quaternion(Vector3.DOWN, d.normalized())).get_euler() / DEG
	add_part(pivot, capsule(0.10, d.length() + 0.10), sleeve, shoulder + d * 0.5, e)
	# Cuff: narrow end toward the elbow, wide bell over the hand.
	add_part(pivot, cyl(0.10, 0.165, 0.22, 10), cuff, shoulder + d * 0.80, e)
	add_part(pivot, sphere(0.11, 8, 4), skin, hand + d.normalized() * 0.03)


## Curved painted cape (crimson, double-sided): a cone section wrapping the back (+-56 deg), draping over the mantle,
## its hem cut into three flame tongues, an orange band above the hem and a glowing flame glyph between the
## shoulder blades. Three surfaces carry their own palette materials (no material_override), so the kit's
## flash / glow / team recolour find them like any merged part. Cached once per type.
static func _cape_mesh() -> ArrayMesh:
	if _cape_cache:
		return _cape_cache
	var cols := 12
	var rows := 10
	var h := 1.30
	var arc := 56.0 * DEG
	var body := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), {}]
	var band := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array(), {}]
	var grid: Array[Vector3] = []
	var gn: Array[Vector3] = []
	for j: int in rows + 1:
		var v := float(j) / float(rows)
		var r := 0.33 + 0.25 * smoothstep(0.0, 0.24, v) + 0.05 * v
		for i: int in cols + 1:
			var u := float(i) / float(cols)
			var a := lerpf(-arc, arc, u)
			var tongue := 1.0 - 0.13 * absf(sin(3.0 * PI * u)) * smoothstep(0.5, 1.0, v)
			grid.append(Vector3(sin(a) * r, -h * v * tongue, -cos(a) * r))
			gn.append(Vector3(sin(a), 0.3 - 0.25 * v, -cos(a)).normalized())
	for j: int in rows:
		var target: Array = band if j == 8 else body
		for i: int in cols:
			var q := j * (cols + 1) + i
			_cape_quad(target, grid, gn, [q, q + 1, q + cols + 2, q + cols + 1])
	# Flame glyph (3 tongues), lifted 1.5 cm off the cloth; (s = arc length in m from the spine, v = height fraction).
	var glyph := [PackedVector3Array(), PackedVector3Array(), PackedInt32Array()]
	var poly: Array[Vector2] = [Vector2(0, 0.22), Vector2(0.07, 0.36), Vector2(0.15, 0.30), Vector2(0.16, 0.46),
		Vector2(0.10, 0.58), Vector2(0, 0.62), Vector2(-0.10, 0.58), Vector2(-0.16, 0.46), Vector2(-0.15, 0.30),
		Vector2(-0.07, 0.36)]
	var centre := _cape_point(Vector2(0, 0.47), h, 0.015)
	var cn := Vector3(0, 0.1, -1).normalized()
	for k: int in poly.size():
		var p0 := _cape_point(poly[k], h, 0.015)
		var p1 := _cape_point(poly[(k + 1) % poly.size()], h, 0.015)
		_cape_tri(glyph, centre, p0, p1, cn)
	_cape_cache = ArrayMesh.new()
	for sf: Array in [[body, &"fire_cloth_dark"], [band, &"fire_cloth"], [glyph, &"fire_sec_archer"]]:
		var d: Array = sf[0]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = d[0]
		arrays[Mesh.ARRAY_NORMAL] = d[1]
		arrays[Mesh.ARRAY_INDEX] = d[2]
		_cape_cache.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_cape_cache.surface_set_material(_cape_cache.get_surface_count() - 1, palette(sf[1]))
	return _cape_cache


## Point on the cape cone at arc offset s (m) and height fraction v, lifted `lift` m outward.
static func _cape_point(sv: Vector2, h: float, lift: float) -> Vector3:
	var v := sv.y
	var r := 0.33 + 0.25 * smoothstep(0.0, 0.24, v) + 0.05 * v + lift
	var a := sv.x / r
	return Vector3(sin(a) * r, -h * v, -cos(a) * r)


## Double-sided quad (outer face clockwise seen from outside = Godot front face, plus the inner face). Grid vertices
## are shared per surface through d[3] (grid index -> outer vertex index; the inner copy follows it).
static func _cape_quad(d: Array, grid: Array[Vector3], gn: Array[Vector3], q: Array) -> void:
	var ids := PackedInt32Array()
	for k: int in 4:
		var g: int = q[k]
		if not d[3].has(g):
			d[3][g] = (d[0] as PackedVector3Array).size()
			d[0].append(grid[g])
			d[1].append(gn[g])
			d[0].append(grid[g])
			d[1].append(-gn[g])
		ids.append(d[3][g])
	d[2].append_array(PackedInt32Array([ids[0], ids[3], ids[1], ids[1], ids[3], ids[2]]))
	d[2].append_array(PackedInt32Array([ids[0] + 1, ids[1] + 1, ids[3] + 1, ids[1] + 1, ids[2] + 1, ids[3] + 1]))

static func _cape_tri(d: Array, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	var base: int = (d[0] as PackedVector3Array).size()
	for p: Vector3 in [a, b, c]:
		d[0].append(p)
		d[1].append(n)
	for p: Vector3 in [a, b, c]:
		d[0].append(p)
		d[1].append(-n)
	d[2].append_array(PackedInt32Array([base, base + 2, base + 1, base + 3, base + 4, base + 5]))

## Soft round additive embers (yellow -> orange -> red, fading), shared process / draw resources.
static func _embers(amount: int, lifetime: float, radius: float, speed: float, size: float, one_shot: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = one_shot
	p.emitting = not one_shot
	p.explosiveness = 0.9 if one_shot else 0.0
	p.randomness = 0.4
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-1.5, -1.5, -1.5), Vector3(3, 4, 3))
	var key := "%s_%s_%s" % [radius, speed, one_shot]
	var pm: ParticleProcessMaterial = _ember_proc.get(key)
	if pm == null:
		pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = radius
		pm.direction = Vector3.UP
		pm.spread = 180.0 if one_shot else 30.0
		pm.initial_velocity_min = speed * 0.5
		pm.initial_velocity_max = speed
		pm.gravity = Vector3(0, 0.6, 0) if not one_shot else Vector3(0, -1.2, 0)
		pm.damping_min = 0.5
		pm.damping_max = 1.5
		var sc := Curve.new()
		sc.add_point(Vector2(0, 0.6))
		sc.add_point(Vector2(0.2, 1.0))
		sc.add_point(Vector2(1, 0.2))
		var ct := CurveTexture.new()
		ct.curve = sc
		pm.scale_curve = ct
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.9, 0.5, 1.0))
		g.set_color(1, Color(0.8, 0.15, 0.05, 0.0))
		g.add_point(0.45, Color(1.0, 0.5, 0.12, 0.9))
		var gt := GradientTexture1D.new()
		gt.gradient = g
		pm.color_ramp = gt
		_ember_proc[key] = pm
	p.process_material = pm
	var q: QuadMesh = _ember_draw.get(size)
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(size, size)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.vertex_color_use_as_albedo = true
		sm.albedo_color = Color(2.2, 2.0, 1.8, 1.0)
		var rg := Gradient.new()
		rg.set_color(0, Color(1, 1, 1, 1))
		rg.set_color(1, Color(1, 1, 1, 0))
		rg.add_point(0.35, Color(1, 1, 1, 0.8))
		var tex := GradientTexture2D.new()
		tex.gradient = rg
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 32
		tex.height = 32
		sm.albedo_texture = tex
		q.material = sm
		_ember_draw[size] = q
	p.draw_pass_1 = q
	return p


# ================================================================ casts (6.5) + idle fidgets

func _pose_cast(spell: StringName, t: float) -> float:
	match spell:
		&"ember_step":
			# Crouch (staff slams, cape flares up), spring up, settle.
			var c := _k3(t, 0.0, 0.12, 0.16, 0.32, 1.0, 1.0)
			var s := _k3(t, 0.16, 0.26, 0.30, 0.55, 1.0, 1.0)
			pos(P_ROOT, Vector3(0, -0.14 * c + 0.07 * s, 0))
			rot(P_CHEST, Vector3((18.0 * c - 6.0 * s) * DEG, 0, 0))
			rot(P_HEAD, Vector3((-14.0 * c) * DEG, 0, 0))
			rot(P_ARM_R, Vector3(28.0 * DEG * c, 0, 0))
			pos(P_ARM_R, Vector3(0, 0, 0.12 * c))
			rot(P_ARM_L, Vector3(40.0 * DEG * c, 0, -35.0 * DEG * c))
			var k := maxf(c, s)
			_flame_scale = 1.0 + 0.5 * k
			_cape_kick = 30.0 * c + 10.0 * s
			_cast_boost = 1.0 + 2.0 * k
			_cast_light = 1.0 + 1.0 * k
			return 0.55
		&"kindle":
			# Both arms up, staff overhead, chin up on tiptoe; the crown blazes for 0.6 s; both hands ignite.
			var k := _k3(t, 0.0, 0.28, 0.62, 0.95, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-18.0 * DEG * k, 0, 12.0 * DEG * k))
			pos(P_ARM_R, Vector3(0, 0.45 * k, 0.05 * k))
			rot(P_ARM_L, Vector3(-30.0 * DEG * k, 0, -125.0 * DEG * k))
			rot(P_HEAD, Vector3(-18.0 * DEG * k, 0, 0))
			rot(P_CHEST, Vector3(-9.0 * DEG * k, 0, 0))
			pos(P_ROOT, Vector3(0, 0.06 * k, 0))
			var f := 1.0 if t < 0.62 else k
			_flame_scale = 1.0 + 0.7 * f
			_palm_target = f
			_cape_kick = 12.0 * k
			_cast_boost = 1.0 + 2.0 * f
			_cast_light = 1.0 + 1.2 * f
			return 0.95
		FIDGET_FLAME:
			return _fidget_flame(t)
		FIDGET_STAFF:
			return _fidget_staff(t)
		_:  # fireball (and unknown ids): charge in the off hand, then lunge and point the sun at the target.
			var w := _k3(t, 0.0, 0.20, 0.30, 0.31, 1.0, 0.0)          # wind-up, gone by 0.30
			var th := _k3(t, 0.18, 0.30, 0.42, 0.80, 1.0, 1.0)        # thrust, hold, recover
			rot(P_ARM_R, Vector3((-28.0 * w + 38.0 * th) * DEG, 0, 0))
			pos(P_ARM_R, Vector3(0, 0.10 * w + 0.12 * th, 0.30 * th))
			rot(P_ARM_L, Vector3((-75.0 * w + 30.0 * th) * DEG, 0, (22.0 * w) * DEG))
			rot(P_CHEST, Vector3((-8.0 * w + 12.0 * th) * DEG, (-14.0 * w + 10.0 * th) * DEG, 0))
			rot(P_HEAD, Vector3((6.0 * w - 8.0 * th) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, -0.03 * th, 0.12 * th))
			var k := maxf(w, th)
			_palm_target = w * 1.3
			_flame_scale = 1.0 + 0.5 * k
			_cape_kick = 14.0 * th
			_cast_boost = 1.0 + 2.0 * k
			_cast_light = 1.0 + 1.5 * k   # 1.2 -> 3.0
			return 0.8


## Idle: she opens her off hand, a flame grows and dances in her palm, she looks at it and closes her fist.
func _fidget_flame(t: float) -> float:
	if _speed >= 0.3:
		return 0.0
	var k := _k3(t, 0.0, 0.40, 1.85, 2.30, 1.0, 1.0)
	rot(P_ARM_L, Vector3(-58.0 * DEG * k, 0, 18.0 * DEG * k))
	rot(P_HEAD, Vector3(12.0 * DEG * k, -22.0 * DEG * k, 0))
	rot(P_CHEST, Vector3(0, -8.0 * DEG * k, 0))
	var f := _k3(t, 0.30, 0.75, 1.75, 1.90, 0.8, 1.0)
	_palm_target = f * (1.15 + 0.2 * sin(t * 17.0))
	return 2.3


## Idle: lifts the staff, taps it down (orb flares), chin up.
func _fidget_staff(t: float) -> float:
	if _speed >= 0.3:
		return 0.0
	var lift := _k3(t, 0.0, 0.45, 0.55, 0.62, 1.0, 1.0)
	var tap := _k3(t, 0.55, 0.62, 0.70, 1.1, 1.0, 1.0)
	var proud := _k3(t, 0.6, 0.9, 1.3, 1.7, 1.0, 1.0)
	pos(P_ARM_R, Vector3(0, 0.12 * lift, 0))
	pos(P_ROOT, Vector3(0, -0.02 * tap, 0))
	rot(P_HEAD, Vector3(-10.0 * DEG * proud, 0, 0))
	rot(P_CHEST, Vector3(-4.0 * DEG * proud, 0, 0))
	_cast_boost = 1.0 + 1.2 * tap
	_cast_light = 1.0 + 0.6 * tap
	return 1.7


# ================================================================ per frame extras

func _wizard_process(_dt: float) -> void:
	if _flames == null:
		return
	_update_face()
	var full := _walk_w > 0.0 or _action != &"" or _dead or _hit_t < HIT_LEN or _level_t < LEVEL_LEN
	if full and not _dead:
		_body_extras()
	elif _dead:
		_death_extras()
	# Idle fidgets: close camera only (tier 0), every 7-12 s.
	if _action == &"" and not _dead and _speed < 0.3 and _tier == 0 and _hit_t >= HIT_LEN and _level_t >= LEVEL_LEN:
		if _t >= _fidget_next:
			_fidget_alt = not _fidget_alt
			_fidget_next = _t + 7.0 + fmod(_phase_off * 7.3 + _t, 5.0)
			play_cast(FIDGET_FLAME if _fidget_alt else FIDGET_STAFF)
	elif _action != &"" or _speed >= 0.3:
		_fidget_next = maxf(_fidget_next, _t + 4.0)
	# Crown flames: flicker 1.0 + 0.1 x noise (two sines), flare on casts; die out on death.
	var s := _flame_scale + 0.1 * sin(_t * 8.0 + _phase_off) * sin(_t * 5.3)
	if _dead:
		s = maxf(0.01, 1.0 - _death_t * 2.0)
	if absf(s - _flame_written) > 0.005:
		_flame_written = s
		var wd := 1.0 + 0.25 * (s - 1.0)          # flares grow taller along the hat axis, barely wider
		_flames.scale = Vector3(wd, s, wd)
	var fb := glow_level() * (1.0 + 0.6 * clampf(_flame_scale - 1.0, 0.0, 1.0))
	if absf(fb - _flame_boost_written) > 0.01:
		_flame_boost_written = fb
		_flames.set_instance_shader_parameter(&"glow_boost", fb)
	# Palm flame (shown only while a pose asks for it).
	var pt := 0.0 if _dead else clampf(_palm_target, 0.0, 1.4)
	if absf(pt - _palm_written) > 0.01:
		_palm_written = pt
		_palm.visible = pt > 0.02
		if _palm.visible:
			_palm.scale = Vector3(pt, pt * 1.4, pt)
			_palm.set_instance_shader_parameter(&"glow_boost", glow_level() * (0.8 + 0.8 * pt))
	# Cape: billows back with the walk, kicked by casts.
	var ck := 3.0 + (7.0 + 3.0 * absf(sin(TAU * _walk_p))) * _walk_w + _cape_kick
	if _dead:
		ck = 3.0 - 20.0 * clampf(_death_t / 0.5, 0.0, 1.0)
	ck += 1.5 * sin(_t * 2.1 + _phase_off) + 1.0 * sin(_t * 3.7)   # slow flutter (one node write per frame)
	if absf(ck - _cape_written) > 0.05:
		_cape_written = ck
		_cape.rotation.x = ck * DEG
	_flame_scale = 1.0
	_palm_target = 0.0
	_cape_kick = 0.0


## Offsets added on top of the kit's walk / attack / hit / level-up poses (only on frames the kit applies them).
func _body_extras() -> void:
	# Walk: a proud glide, the gown swings, the staff swings forward like a walking stick.
	if _walk_w > 0.0:
		var sw := sin(TAU * _walk_p) * _walk_w
		rot(P_HIPS, Vector3(0, 6.0 * DEG * sw, 2.0 * DEG * sw))
		rot(P_CHEST, Vector3(4.0 * DEG * _walk_w, -3.0 * DEG * sw, 0))
		rot(P_HEAD, Vector3(-4.0 * DEG * _walk_w, 2.0 * DEG * sw, 0))
		rot(P_ARM_R, Vector3(-6.0 * DEG * _walk_w, 0, 0))
	# Auto-attack (wizard_bolt, release 0.12): the kit lifts the arm; add a flick that points the orb forward.
	if _action == &"attack":
		var a := _k3(_action_t, 0.0, attack_windup, attack_windup + 0.04, 0.45, 1.0, 1.0)
		# Pushed for the 40 m read (Art Lab A3): a longer lunge-flick, the off hand flung back, the cape kicks.
		rot(P_ARM_R, Vector3(62.0 * DEG * a, 0, 0))
		pos(P_ARM_R, Vector3(0, 0.08 * a, 0.26 * a))
		rot(P_CHEST, Vector3(9.0 * DEG * a, 11.0 * DEG * a, 0))
		rot(P_ARM_L, Vector3(26.0 * DEG * a, 0, -30.0 * DEG * a))
		_cape_kick = maxf(_cape_kick, 12.0 * a)
		_flame_scale = maxf(_flame_scale, 1.0 + 0.2 * a)
	# Hit: the head snaps back with the chest flinch.
	if _hit_t < HIT_LEN:
		var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
		rot(P_HEAD, Vector3(-14.0 * DEG * k, 0, 6.0 * DEG * k))
		rot(P_ARM_L, Vector3(-20.0 * DEG * k, 0, -15.0 * DEG * k))
	# Level-up: a pirouette with the free arm flung out; the crown blazes.
	if _level_t < LEVEL_LEN:
		var u := clampf(_level_t / LEVEL_LEN, 0.0, 1.0)
		rot(P_ROOT, Vector3(0, TAU * smoothstep(0.0, 1.0, u), 0))
		rot(P_ARM_L, Vector3(0, 0, -70.0 * DEG * sin(PI * u)))
		_flame_scale = maxf(_flame_scale, 1.0 + 0.8 * sin(PI * u))
		_cape_kick = 25.0 * sin(PI * u)


## Death (fall): a gasp (head back, off hand reaching out) before the kit's forward fall and sink.
func _death_extras() -> void:
	var t := _death_t
	var g := _k3(t, 0.0, 0.22, 0.30, 0.55, 1.0, 1.0)
	rot(P_HEAD, Vector3(-24.0 * DEG * g, 0, 0))
	rot(P_ARM_L, Vector3(-65.0 * DEG * g, 0, -20.0 * DEG * g))
	rot(P_CHEST, Vector3(-10.0 * DEG * g, 0, 0))


func _on_revive() -> void:
	super._on_revive()
	_flame_written = -1.0
	_flame_boost_written = -1.0
	_palm_written = -1.0
	_cape_written = 999.0
	_face_shown = &""
	_update_face()
	_palm_target = 0.0
	_cape_kick = 0.0
	if _palm:
		_palm.visible = false

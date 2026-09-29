extends FireModel
## Scorchling, Fire T1 swarm imp (rush-balance.md 5.4, new-units-12.md 6; tiers wave, medium effort). Height 1.1.
## A knee-high fire imp with a huge head: charred red-brown hide, long bat ears swept out sideways and two pale horn
## nubs (the silhouette hook: a wide "T" head on a tiny body), a wide painted grin (FaceKit face), a team scarf with a torn tail and a
## team loincloth, long skinny arms ending in pale claws, a whip tail with a team spade tip.
## Glow points (2): the coal belly (pulses, faster as HP falls: reads the parent Unit's hp every 0.5 s, else each
## play_hit speeds it up) and a flame tuft on the crown (flickers).
## Attack `imp_pounce` (0.5 s, strike 0.14): crouch, leap forward raking with both claws, land.
## Death (Flashpoint): swells, pops at 0.15 s (ember ring + burst, white-hot flash), shrinks, FireModel's burn.
## `play_burst()` = the same pop without dying (gameplay may call it). play_cast(&"flashpoint") = the pop too.
## Draws: merged pivots + Belly + Tuft (keep_separate, own_glow) + blob + hidden vet trim; 0 lights.

const ATTACK_LEN := 0.5
const STRIKE := 0.14
const POP_AT := 0.15
const BELLY := Vector3(0.0, 0.44, 0.135)
const TUFT := Vector3(0.0, 1.0, -0.04)
const HAND := Vector3(0.29, 0.25, 0.13)
const EMBER_COL := Color(1.0, 0.5, 0.12)

static var K_ARM := PackedFloat32Array([0.0, 0.0, 0, 0.10, 45.0, 1, 0.15, -115.0, 2, 0.28, -70.0, 0, 0.50, 0.0, 0])
static var K_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.10, -0.06, 1, 0.16, 0.38, 2, 0.30, 0.30, 0, 0.50, 0.0, 0])
static var K_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.10, -0.09, 1, 0.15, 0.20, 2, 0.26, 0.02, 2, 0.34, -0.04, 0, 0.50, 0.0, 0])
static var K_ROOT_X := PackedFloat32Array([0.0, 0.0, 0, 0.10, -10.0, 1, 0.15, 24.0, 2, 0.30, 10.0, 0, 0.50, 0.0, 0])
static var K_LEG := PackedFloat32Array([0.0, 0.0, 0, 0.10, -30.0, 1, 0.15, 35.0, 2, 0.30, -10.0, 0, 0.50, 0.0, 0])
static var K_HEAD := PackedFloat32Array([0.0, 0.0, 0, 0.10, 10.0, 1, 0.15, -16.0, 2, 0.50, 0.0, 0])

var _belly: GeometryInstance3D
var _tuft: GeometryInstance3D
var _ring: GPUParticles3D
var _pop_fx: GPUParticles3D
var _unit: Node = null
var _hurt: float = 0.0          # 0 = full HP .. 1 = nearly dead (pulse rate)
var _hp_timer: float = 0.0
var _pulse_p: float = 0.0
var _belly_v: float = -1.0
var _tuft_v: float = -1.0
var _popped: bool = false
var _burst_t: float = -1.0      # play_burst() pop without dying


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var hide := palette(&"fire_fur")
	var burnt := palette(&"fire_leather")
	var cloth := palette(&"fire_cloth")
	var cdark := palette(&"fire_cloth_dark")
	var horn := palette(&"fire_sec_worker")
	var skull := palette(&"fire_sec_hurler")
	# ---- Legs: short crooked legs, charred shins, splayed clawed feet.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, _tube("sc_leg_%s" % sx, PackedVector3Array([Vector3(0.09 * sx, 0.36, 0.0),
			Vector3(0.13 * sx, 0.22, 0.07), Vector3(0.12 * sx, 0.07, -0.03)]), PackedFloat32Array([0.06, 0.045, 0.04]), 6),
			burnt, Vector3.ZERO)
		add_part(leg, cyl(0.045, 0.05, 0.1, 6), burnt, Vector3(0.12 * sx, 0.1, -0.01), Vector3(-15, 0, 0))
		add_part(leg, sphere(0.055, 6, 3), burnt, Vector3(0.12 * sx, 0.035, 0.05), Vector3.ZERO, Vector3(1.1, 0.6, 1.7))
		for k: int in 2:
			var tx: float = 0.12 * sx + (float(k) - 0.5) * 0.05
			add_part(leg, cyl(0.0, 0.018, 0.07, 4), horn, Vector3(tx, 0.03, 0.14), Vector3(80, 0, 0))
	# ---- Hips: team loincloth (front flap longer), a charred belt, the whip tail with a team spade.
	add_part(hips, cyl(0.15, 0.19, 0.14, 8), cloth, Vector3(0, 0.33, 0.0))
	add_part(hips, box(Vector3(0.13, 0.16, 0.03)), cloth, Vector3(0.02, 0.23, 0.17), Vector3(-12, 0, 4))
	add_part(hips, torus(0.15, 0.185, 8), burnt, Vector3(0, 0.39, 0.0), Vector3.ZERO, Vector3(1.0, 1.6, 1.0))
	add_part(hips, _tube("sc_tail", PackedVector3Array([Vector3(0, 0.32, -0.14), Vector3(0.02, 0.24, -0.3),
		Vector3(0.10, 0.34, -0.45), Vector3(0.14, 0.54, -0.5)]), PackedFloat32Array([0.04, 0.03, 0.024, 0.018]), 5, false),
		hide, Vector3.ZERO)
	add_part(hips, prism(Vector3(0.14, 0.14, 0.03)), cdark, Vector3(0.145, 0.62, -0.505), Vector3(0, -20, 0))
	# ---- Chest: pot belly with the coal set in a charred crust ring, hunched shoulders, team scarf + torn tail.
	add_part(chest, sphere(0.2, 10, 5), hide, Vector3(0, 0.47, 0.0), Vector3.ZERO, Vector3(1.05, 1.0, 0.95))
	add_part(chest, sphere(0.14, 8, 4), hide, Vector3(0, 0.61, -0.03), Vector3.ZERO, Vector3(1.35, 0.8, 1.0))
	add_part(chest, torus(0.085, 0.13, 10), burnt, BELLY + Vector3(0, 0, 0.02), Vector3(80, 0, 0), Vector3(1.0, 1.0, 1.2))
	for k: int in 3:
		var a: float = -0.9 + 0.9 * k
		add_part(chest, box(Vector3(0.02, 0.07, 0.02)), burnt, BELLY + Vector3(sin(a) * 0.15, cos(a) * 0.15 - 0.02, -0.01),
			Vector3(0, 0, -rad_to_deg(a)))
	_belly = add_part(chest, sphere(0.1, 8, 4), palette(&"fire_glow"), BELLY, Vector3.ZERO, Vector3(1.0, 1.1, 0.6),
		true, "Belly")
	_belly.set_meta(&"own_glow", true)
	add_part(chest, torus(0.09, 0.17, 10), cloth, Vector3(0, 0.67, 0.0), Vector3(-8, 0, 0), Vector3(1.0, 1.5, 1.0))
	add_part(chest, box(Vector3(0.09, 0.26, 0.025)), cloth, Vector3(-0.12, 0.58, -0.14), Vector3(28, 20, 30))
	add_part(chest, box(Vector3(0.07, 0.12, 0.025)), cdark, Vector3(-0.2, 0.44, -0.2), Vector3(40, 20, 45))
	# ---- Head: huge round head, big bat ears out sideways, pale horn nubs, wide dark grin, pale yellow eyes.
	add_part(head, sphere(0.24, 10, 6), skull, Vector3(0, 0.84, 0.03), Vector3.ZERO, Vector3(1.1, 0.95, 1.0))
	add_part(head, box(Vector3(0.3, 0.05, 0.08)), hide, Vector3(0, 0.92, 0.2), Vector3(-15, 0, 0))
	# Face (faces pass 2026-09-28, beast rule: eyes + expression, no hair): big pale-yellow imp eyes with slit-dark
	# pupils and a wide grin that snarls on the pounce (FaceKit; replaces the mesh eyes, pupils and the grin bar).
	_face = UnitFaces.attach_lean(self, head, "scorchling", {"center": Vector3(0, 0.84, 0.03), "radius": 0.24,
		"head_mesh": sphere(0.24, 10, 6), "head_scale": Vector3(1.1, 0.95, 1.0), "preset": &"plain", "detail": &"low",
		"skin": Color(0.6, 0.35, 0.25), "hair": Color(0.16, 0.05, 0.03), "eyes": Color(0.98, 0.62, 0.10), "ears": &"none",
		"palette": {"sclera": Color(1.0, 0.92, 0.55), "blush": Color(0.75, 0.25, 0.12), "lip": Color(0.40, 0.12, 0.08),
			"lip_line": Color(0.12, 0.03, 0.02), "mouth_in": Color(0.18, 0.03, 0.02)},
		"eye": {"c": Vector2(0.085, 0.030), "hw": 0.050, "top": 0.040, "bot": 0.024, "ir": 0.026},
		"mouth": {"c": Vector2(0.0, -0.088), "hw": 0.10, "lip": 0.005},
		"x": {&"neutral": {"blush": 0.0, "mouth": {"curve": 1.8, "w": 1.0}}, &"smile": {"blush": 0.0},
			&"worried": {"blush": 0.0}, &"shout": {"blush": 0.0}}}, false)
	for s: float in [-1.0, 1.0]:
		# bat ears: a long cone out sideways with a dark inner fold
		add_part(head, cyl(0.0, 0.085, 0.38, 6), skull, Vector3(0.36 * s, 0.93, -0.01), Vector3(0, 0, -72 * s),
			Vector3(1.0, 1.0, 0.45))
		add_part(head, cyl(0.0, 0.05, 0.26, 4), cdark, Vector3(0.34 * s, 0.925, 0.02), Vector3(0, 0, -72 * s),
			Vector3(1.0, 1.0, 0.3))
		add_part(head, cyl(0.0, 0.045, 0.16, 5), horn, Vector3(0.1 * s, 1.04, 0.06), Vector3(-25, 0, -18 * s))
	add_part(head, cyl(0.0, 0.03, 0.06, 4), horn, Vector3(0.05, 0.735, 0.26), Vector3(170, 0, 0))
	add_part(head, cyl(0.0, 0.03, 0.06, 4), horn, Vector3(-0.07, 0.735, 0.255), Vector3(170, 0, 0))
	_tuft = add_part(head, _tuft_mesh(), palette(&"fire_flame"), TUFT, Vector3.ZERO, Vector3.ONE, true, "Tuft")
	_tuft.set_meta(&"own_glow", true)
	var trim := add_part(head, torus(0.12, 0.16, 10), palette(&"unit_gold_trim"), Vector3(0, 1.0, 0.03),
		Vector3.ZERO, Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
	# ---- Arms: long skinny arms hanging to the knees, charred forearms, three pale claws each.
	for arm: Node3D in [arm_l, arm_r]:
		var sx: float = -1.0 if arm == arm_l else 1.0
		add_part(arm, _tube("sc_arm_%s" % sx, PackedVector3Array([Vector3(0.19 * sx, 0.62, 0.0),
			Vector3(0.29 * sx, 0.45, 0.03), HAND * Vector3(sx, 1, 1) + Vector3(0, 0.03, 0)]),
			PackedFloat32Array([0.05, 0.04, 0.035]), 6), hide, Vector3.ZERO)
		add_part(arm, cyl(0.045, 0.052, 0.1, 6), cloth, Vector3(0.29 * sx, 0.33, 0.08), Vector3(-25, 0, 0))
		add_part(arm, sphere(0.05, 6, 3), hide, HAND * Vector3(sx, 1, 1))
		add_part(arm, _claws_mesh(sx), horn, Vector3.ZERO)
	# ---- Fx: the Flashpoint pop (ember ring + burst, restarted by this script) and FireModel's burn.
	var fx: Node3D = $Fx
	_ring = make_motes(EMBER_COL, 18, 0.55, 0.35, 3.2, 0.16, true, true)
	_ring.name = "PopRing"
	_ring.position = Vector3(0, 0.25, 0)
	fx.add_child(_ring)
	_pop_fx = make_motes(Color(1.0, 0.7, 0.25), 14, 0.5, 0.2, 2.6, 0.2, false, true)
	_pop_fx.name = "PopBurst"
	_pop_fx.position = Vector3(0, 0.55, 0)
	fx.add_child(_pop_fx)
	var be := make_motes(EMBER_COL, 10, 0.9, 0.2, 1.4, 0.1, false, true)
	be.name = "BurnEmbers"
	be.position = Vector3(0, 0.4, 0)
	be.set_meta(&"burn_fx", true)
	fx.add_child(be)
	ensure_shadow_blob(0.32)


# ================================================================ meshes (cached, model space)

## Tapered tube through `pts` (radii per point), one cached mesh.
static func _tube(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 6,
		caps: bool = true) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	for i: int in pts.size() - 1:
		var a := pts[i]
		var d := pts[i + 1] - a
		var extra: float = 0.02 if radii[i + 1] > 0.0 else 0.0
		var len_total := d.length() + extra
		var c := cyl(radii[i + 1], radii[i], len_total, seg, caps and (i == 0 or i == pts.size() - 2))
		st.append_from(c, 0, Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d.normalized() * len_total * 0.5))
	st.index()
	return _cached(key, st.commit())


## Three hooked claws from the hand, reaching forward and down.
static func _claws_mesh(side: float) -> Mesh:
	var key := "sc_claws_%s" % side
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	var h := HAND * Vector3(side, 1, 1)
	for k: int in 3:
		var dx: float = (float(k) - 1.0) * 0.035
		var b := h + Vector3(dx, -0.02, 0.03)
		var m := _tube("sc_claw_%s_%d" % [side, k], PackedVector3Array([b, b + Vector3(dx * 0.5, -0.06, 0.06),
			b + Vector3(dx, -0.13, 0.07)]), PackedFloat32Array([0.018, 0.013, 0.0]), 4)
		st.append_from(m, 0, Transform3D.IDENTITY)
	st.index()
	return _cached(key, st.commit())


## Flame tuft on the crown: a tall central tongue leaning back and three shorter ones (origin at the scalp).
static func _tuft_mesh() -> Mesh:
	const KEY := "sc_tuft"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	st.append_from(cyl(0.0, 0.08, 0.26, 6), 0, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-18.0)), Vector3(0, 0.12, -0.02)))
	var hs: Array[float] = [0.16, 0.13, 0.15]
	for k: int in 3:
		var a: float = TAU * k / 3.0 + 0.6
		var b := Basis(Vector3(-sin(a), 0, cos(a)), deg_to_rad(-22.0))
		st.append_from(cyl(0.0, 0.05, hs[k], 5), 0, Transform3D(b, Vector3(cos(a) * 0.05, hs[k] * 0.45, sin(a) * 0.05)))
	st.index()
	return _cached(KEY, st.commit())


# ================================================================ hooks

func _after_ready() -> void:
	super()
	# The owning Unit (for the HP-driven pulse): the model sits a few nodes under it. Found once.
	var n: Node = get_parent()
	for i: int in 3:
		if n == null:
			break
		if n.get(&"max_hp") != null and n.get(&"hp") != null:
			_unit = n
			break
		n = n.get_parent()
	_write_glows(1.0, 1.0)


func play_hit() -> void:
	super()
	if _unit == null:
		_hurt = minf(_hurt + 0.12, 1.0)


## The Flashpoint pop without dying (ember ring + burst + white-hot flash for 0.35 s).
func play_burst() -> void:
	if _dead:
		return
	_burst_t = 0.0
	_fire_pop()


func play_cast(spell_id: StringName) -> void:
	if spell_id == &"flashpoint":
		play_burst()
		return
	super(spell_id)


func _fire_pop() -> void:
	if _tier >= 2:
		return
	if _ring:
		_ring.restart()
	if _pop_fx:
		_pop_fx.restart()


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"imp_pounce":
		return super(prev, t)
	var a: float = _kf(t, K_ARM) * DEG
	rot(P_ARM_R, Vector3(a, 0, -12.0 * DEG * clampf(-a, 0.0, 1.0)))
	rot(P_ARM_L, Vector3(a * 0.9, 0, 12.0 * DEG * clampf(-a, 0.0, 1.0)))
	pos(P_ROOT, Vector3(0, _kf(t, K_ROOT_Y), _kf(t, K_ROOT_Z)))
	rot(P_ROOT, Vector3(_kf(t, K_ROOT_X) * DEG, 0, 0))
	if _tier == 0:
		var l: float = _kf(t, K_LEG) * DEG
		rot(P_LEG_L, Vector3(l, 0, 0))
		rot(P_LEG_R, Vector3(l * 0.7, 0, 0))
		rot(P_HEAD, Vector3(_kf(t, K_HEAD) * DEG, 0, 0))
	if prev < STRIKE and t >= STRIKE:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## Flashpoint cast (only when gameplay asks): a crouch and a hop around the pop.
func _pose_cast(_spell: StringName, t: float) -> float:
	pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.1, 0.18, 0.4, -0.08, 0.12), 0))
	rot(P_ARM_L, Vector3(0, 0, _k3(t, 0.0, 0.1, 0.18, 0.4, 10.0, -70.0) * DEG))
	rot(P_ARM_R, Vector3(0, 0, _k3(t, 0.0, 0.1, 0.18, 0.4, -10.0, 70.0) * DEG))
	return 0.4


## Scurry: quick bouncy steps, body rocking side to side, arms swinging wide, the head bobbing.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	if _tier > 0:
		return
	var s: float = sin(TAU * _walk_p)
	rot(P_ROOT, Vector3(8.0 * DEG * w, 0, 6.0 * DEG * s * w))
	rot(P_HIPS, Vector3(0, 10.0 * DEG * s * w, 0))
	rot(P_ARM_L, Vector3(-26.0 * DEG * s * w, 0, 10.0 * DEG * w))
	rot(P_ARM_R, Vector3(26.0 * DEG * s * w, 0, -10.0 * DEG * w))
	rot(P_HEAD, Vector3(-6.0 * DEG * absf(s) * w, 0, -4.0 * DEG * s * w))


func _pose_death(dt: float) -> void:
	super(dt)
	var t: float = _death_t
	# Swell, pop at POP_AT (white-hot), then shrink fast into FireModel's burn.
	var swell: float = smoothstep(0.0, POP_AT, t) * (1.0 - smoothstep(POP_AT, POP_AT + 0.05, t))
	var shrink: float = smoothstep(POP_AT, POP_AT + 0.25, t)
	_root_scale *= (1.0 + 0.3 * swell) * lerpf(1.0, 0.6, shrink)
	if not _popped and t >= POP_AT:
		_popped = true
		_fire_pop()
	if t < POP_AT + 0.2:
		_write_burn(0.6 * swell + 0.35 * (1.0 - smoothstep(POP_AT, POP_AT + 0.2, t)) * float(t >= POP_AT))


func _extra_process(dt: float) -> void:
	super(dt)
	if _belly == null:
		return
	if _dead:
		var k: float = 1.0 - smoothstep(POP_AT, POP_AT + 0.2, _death_t)
		_write_glows(3.0 * k, 2.0 * k)
		return
	# HP read (cheap, twice a second).
	_hp_timer -= dt
	if _hp_timer <= 0.0:
		_hp_timer = 0.5
		if _unit and is_instance_valid(_unit):
			var mx: float = float(_unit.get(&"max_hp"))
			if mx > 0.0:
				_hurt = clampf(1.0 - float(_unit.get(&"hp")) / mx, 0.0, 1.0)
	var bt: float = 0.0
	if _burst_t >= 0.0:
		_burst_t += dt
		bt = 1.0 - smoothstep(0.1, 0.35, _burst_t)
		_set_flash(0.5 * bt)
		if _burst_t > 0.35:
			_burst_t = -1.0
			_set_flash(0.0)
	var rate: float = lerpf(2.2, 9.0, _hurt * _hurt)
	_pulse_p = fmod(_pulse_p + dt * rate, TAU)
	var pulse: float = 0.5 + 0.5 * sin(_pulse_p)
	var belly: float = 1.0 + 0.9 * pulse + 1.5 * bt
	var f: float = 1.0 + 0.5 * bt
	if _tier == 0:
		var fl: float = 0.1 * sin(_t * 14.0) + 0.06 * sin(_t * 8.1 + 1.3)
		_tuft.scale = Vector3(f - fl * 0.5, f + fl, f - fl * 0.5)
	if _action == &"attack":
		belly += 0.6 * _k3(_action_t, 0.0, 0.1, STRIKE + 0.04, ATTACK_LEN, 0.5, 1.0)
	_write_glows(belly, 1.0 + bt)


func _on_revive() -> void:
	super()
	_popped = false
	_burst_t = -1.0
	_hurt = 0.0
	if _tuft:
		_tuft.scale = Vector3.ONE
	_write_glows(1.0, 1.0)


func _write_glows(belly: float, tuft: float) -> void:
	var g: float = glow_level()
	var b: float = snappedf(belly * 1.6 * g, 0.1)
	if b != _belly_v and _belly:
		_belly_v = b
		_belly.set_instance_shader_parameter(&"glow_boost", b)
	var tv: float = snappedf(tuft * 1.3 * g, 0.05)
	if tv != _tuft_v and _tuft:
		_tuft_v = tv
		_tuft.set_instance_shader_parameter(&"glow_boost", tv)

extends NatureWarModel
## Burr Slinger (kingdom-nature.md 7.2; 8.V4, polish A2.2), Nature ranged, 1.5 m, radius 0.4.
## A crouched sharpshooter under a big curling team-leaf hood, holding a LONG seed-pod launcher sideways across the
## body (the silhouette: a narrow figure + a 1.55 m horizontal bar with a bulb at the back and a flared mouth), a
## spiky burr loaded in the mouth, a sack of spare burrs on the back (spikes over the shoulder), a leaf mantle.
## Glow points: the pod's mouth ring and the 3 charge seeds on the pod's back (nature_glow; own glow: they fill up
## one by one during the aim, flare on release, dim while the burr regrows).
## Motion: sneaking crouched jog with the pod level; `pod_shot` (own timeline, 0.6 s): kneels, lifts and aims
## (0-0.12), release at `attack_windup` 0.12 (burr hidden, puff at the mouth, hard recoil), a pump of the pod while a new
## burr grows in the mouth (0.35-0.5 s); fidget: sights along the pod; hit leaves; Nature death.

const POD_DIR := Vector3(-0.90, 0.10, 0.42)   # model space: held sideways, mouth front-left
const GRIP := Vector3(0.30, 0.74, 0.24)        # right fist on the pod
const POD_LEN := 1.55
const POD_BACK := 0.40                          # grip distance from the pod's back end
const SHOT_LEN := 0.6
const BURR_SCALE := 1.0
# pod_shot tracks: [t, value, ease] (NatureWarModel._kf). Both arms share the rotation so both hands stay on the pod.
static var S_ARM := PackedFloat32Array([0.0, 0.0, 0, 0.12, -22.0, 1, 0.16, -40.0, 1, 0.30, -14.0, 0, 0.40, -2.0, 0, 0.48, -12.0, 0, 0.60, 0.0, 0])
static var S_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0, 0.12, 16.0, 1, 0.18, 8.0, 0, 0.60, 0.0, 0])
static var S_CHEST_X := PackedFloat32Array([0.0, 0.0, 0, 0.12, 6.0, 1, 0.16, -12.0, 1, 0.34, 2.0, 0, 0.60, 0.0, 0])
static var S_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.12, 8.0, 1, 0.16, -10.0, 1, 0.34, 0.0, 0, 0.60, 0.0, 0])
static var S_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0, 0.12, -0.08, 1, 0.30, -0.06, 0, 0.60, 0.0, 0])
static var S_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.12, 0.03, 1, 0.16, -0.15, 1, 0.34, -0.06, 0, 0.60, 0.0, 0])
static var S_LEG_L := PackedFloat32Array([0.0, 0.0, 0, 0.12, -30.0, 1, 0.40, -26.0, 0, 0.60, 0.0, 0])
static var S_LEG_R := PackedFloat32Array([0.0, 0.0, 0, 0.12, 22.0, 1, 0.40, 18.0, 0, 0.60, 0.0, 0])

static var _combo_cache: Dictionary = {}

var _tip: GeometryInstance3D
var _seeds: GeometryInstance3D
var _burr: Node3D
var _puff: GPUParticles3D
var _flare: float = 0.0
var _tip_written: float = -1.0
var _seed_written: float = -1.0
var _burr_t: float = 99.0
var _burr_s: float = 1.0


## One mesh from several (mesh, transform) pairs, cached by key (one draw instance, one material).
static func _combine(key: String, parts: Array) -> Mesh:
	if _combo_cache.has(key):
		return _combo_cache[key]
	var st := SurfaceTool.new()
	for p: Array in parts:
		st.append_from(p[0] as Mesh, 0, p[1] as Transform3D)
	var m := _indexed(st)
	_combo_cache[key] = m
	return m


## Spiky burr: a ball r 0.11 with 8 thorns (one mesh).
static func burr_mesh() -> Mesh:
	var parts: Array = [[sphere(0.11, 6, 3), Transform3D.IDENTITY]]
	var dirs: Array[Vector3] = [Vector3.UP, Vector3.DOWN, Vector3(1, 0.2, 0.9), Vector3(-1, 0.2, -0.9),
		Vector3(1, -0.4, -0.8), Vector3(-1, -0.4, 0.8), Vector3(0.2, 0.9, -1), Vector3(-0.2, -0.9, 1)]
	var spike := cyl(0.0, 0.05, 0.18, 4, false)   # base inside the ball: no cap (face budget)
	for d: Vector3 in dirs:
		var n := d.normalized()
		parts.append([spike, Transform3D(Basis(Quaternion(Vector3.UP, n)), n * 0.17)])
	return _combine("burr", parts)


## Low-poly limb: 6-segment cylinder from a to b, optional sphere at b.
func _rod(pivot: Node3D, a: Vector3, b: Vector3, r: float, mat: Material, end_r: float = 0.0,
		end_mat: Material = null) -> void:
	var d := b - a
	add_part(pivot, cyl(r, r, d.length(), 6), mat, a + d * 0.5, Basis(Quaternion(Vector3.UP, d.normalized())).get_euler() / DEG)
	if end_r > 0.0:
		add_part(pivot, sphere(end_r, 8, 4), end_mat if end_mat else mat, b)


func _build_parts() -> void:
	var hips: Node3D = $Root/Hips
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := nature(&"nature_cloth")
	var dark := nature(&"nature_cloth_dark")
	var sec := nature(&"nature_sec_slinger_c")   # ochre straw (Art Lab R3: the old yellow-green melted into the meadow)
	var skin := nature(&"nature_skin")
	var bark := nature(&"nature_bark")
	var bdark := nature(&"nature_bark_dark")
	var burr := nature(&"nature_burr_b")
	var glow := nature(&"nature_glow")
	# ---- Legs: crouched (thigh forward to the knee, shin back down), the left foot a little forward; bark boots.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		var fz: float = 0.06 if sx < 0.0 else -0.04
		_rod(leg, Vector3(0.14 * sx, 0.50, -0.02), Vector3(0.17 * sx, 0.32, 0.14 + fz), 0.09, dark, 0.09)
		_rod(leg, Vector3(0.17 * sx, 0.32, 0.14 + fz), Vector3(0.17 * sx, 0.10, 0.03 + fz), 0.085, dark)
		add_part(leg, box(Vector3(0.20, 0.13, 0.32)), bdark, Vector3(0.17 * sx, 0.065, 0.09 + fz))
	# ---- Hips: short tunic (the unit's ochre straw), bark belt, a burr pouch on the hip.
	add_part(hips, cyl(0.22, 0.31, 0.30, 8), sec, Vector3(0, 0.53, 0))
	add_part(hips, cyl(0.25, 0.25, 0.07, 8, false), bark, Vector3(0, 0.67, 0))
	add_part(hips, sphere(0.10, 6, 3), bdark, Vector3(0.24, 0.58, -0.10), Vector3.ZERO, Vector3(0.9, 1.1, 0.9))
	# ---- Chest: team torso leaning forward, a mantle of team leaves over the shoulders, the burr sack on the back
	# with spare burrs sticking out over the shoulder.
	add_part(chest, cyl(0.27, 0.21, 0.46, 8), cloth, Vector3(0, 0.88, 0.04), Vector3(14, 0, 0))
	# The shoulder mantle is team-DARK (Art Lab R3): a dark collar between the bright team hood leaf and the torso.
	add_part(chest, leaf_ring_mesh(7, 0.16, Vector3(0.26, 0.06, 0.34), -38.0, 8.0), dark, Vector3(0, 1.10, 0.0))
	add_part(chest, sphere(0.20, 8, 4), bark, Vector3(-0.06, 0.90, -0.28), Vector3(0, 0, 12), Vector3(1.0, 1.25, 0.8))
	add_part(chest, _sack_burrs_mesh(), burr, Vector3.ZERO)
	# ---- Head: face, dark bark hood (Art Lab R3: a green hood melted into the meadow), team leaf flaps framing the
	# face, a big team leaf curling over the hood with its tip trailing back and up, a dark eye bar (bare-faced
	# ranged: no glow on the face).
	var hc := Vector3(0, 1.24, 0.10)
	add_part(head, sphere(0.21, 10, 5), skin, hc)
	# Face (FaceKit): amber eyes, a cocky grin, a chestnut fringe out of the hood (was a dark eye bar).
	_face = FaceKit.attach(self, head, "burr_slinger", {
		"center": hc, "radius": 0.21, "head_mesh": sphere(0.21, 10, 5), "preset": &"plain", "skin": NatureFaces.SKIN,
		"hair": NatureFaces.CHESTNUT, "eyes": NatureFaces.EYE_AMBER, "detail": &"low",
		"x": NatureFaces.lean_x(1.05, {&"neutral": {"mouth": {"kind": "smirk"}}}), "palette": NatureFaces.pal(NatureFaces.CHESTNUT),
		"eye": {"c": Vector2(0.066, 0.030)}, "mouth": {"c": Vector2(0.0, -0.082)},
		"hair_fn": func(acc: Dictionary) -> void:
			NatureFaces.fringe(acc, hc, 0.21, 3, NatureFaces.AMBER, NatureFaces.AMBER_TIP, 0.55, 0.75, 0.16),
	})
	add_part(head, sphere(0.25, 10, 5), bdark, Vector3(0, 1.29, 0.0), Vector3.ZERO, Vector3(1.06, 1.04, 1.0))
	for sx: float in [-1.0, 1.0]:   # leaf hood flaps framing the face
		add_leaf(head, Vector3(0.19 * sx, 1.21, 0.14), Vector3(0.16, 0.05, 0.34), cloth, Vector3(78, 12.0 * sx, -18.0 * sx))
	add_part(head, cyl(0.0, 0.045, 0.10, 5), skin, Vector3(0, 1.21, 0.33), Vector3(90, 0, 0))
	add_leaf(head, Vector3(0, 1.47, -0.02), Vector3(0.40, 0.08, 0.66), cloth, Vector3(-16, 180, 0))
	add_leaf(head, Vector3(0, 1.43, 0.14), Vector3(0.30, 0.07, 0.30), cloth, Vector3(-8, 0, 0))
	# ---- Arms (ochre sleeves): both hands on the pod.
	var d := POD_DIR.normalized()
	var grip_l := GRIP + d * 0.62
	_rod(arm_l, Vector3(-0.30, 0.98, 0.02), grip_l, 0.085, sec, 0.10, skin)
	_rod(arm_r, Vector3(0.30, 0.98, 0.02), GRIP, 0.085, sec, 0.10, skin)
	# ---- The pod launcher: bark back cap, a bulbous seed chamber (ochre) with two team leaf fins, a bark
	# barrel with dark bands, a flared mouth.
	var e := Basis(Quaternion(Vector3.UP, d)).get_euler() / DEG
	var back := GRIP - d * POD_BACK
	add_part(arm_r, sphere(0.15, 8, 4), bark, back + d * 0.02)
	add_part(arm_r, sphere(0.20, 10, 5), sec, back + d * 0.30, e, Vector3(1.0, 1.9, 1.0))
	add_part(arm_r, cyl(0.105, 0.14, POD_LEN - 0.55, 8), bark, back + d * (0.50 + (POD_LEN - 0.55) * 0.5), e)
	for f: float in [0.62, 1.10]:
		add_part(arm_r, cyl(0.135 - 0.02 * f, 0.135 - 0.02 * f, 0.07, 8, false), bdark, back + d * f, e)
	add_part(arm_r, _fins_mesh(), cloth, Vector3.ZERO)
	var mouth := back + d * POD_LEN
	add_part(arm_r, cyl(0.21, 0.12, 0.24, 8), bark, mouth - d * 0.07, e)
	# Own glows: the mouth ring and the 3 charge seeds on the chamber's back.
	_tip = add_part(arm_r, torus(0.13, 0.20, 10), glow, mouth + d * 0.05, e, Vector3.ONE, true, "Tip")
	if _tip:
		_tip.set_meta(&"own_glow", true)
	_seeds = add_part(arm_r, _seeds_mesh(), glow, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, true, "Seeds")
	if _seeds:
		_seeds.set_meta(&"own_glow", true)
	# Loaded burr sitting in the mouth (hidden on release, regrows)
	_burr = add_part(arm_r, burr_mesh(), burr, mouth + d * 0.13, Vector3.ZERO, Vector3.ONE * BURR_SCALE, true, "Burr")
	# Launch puff at the mouth (pre-built one-shot)
	_puff = make_motes(Color(0.75, 0.90, 0.40), 8, 0.45, 0.08, 1.4, 0.11, false, true)
	_puff.name = "Puff"
	_puff.position = mouth + d * 0.18 - model_origin(arm_r)
	arm_r.add_child(_puff)
	add_hit_burst(Vector3(0, 0.95, 0.0), Color(0.60, 0.70, 0.25), 7)
	add_death_bloom(Vector3(0, 0.8, 0.0), 0.35, 8, 12)
	ensure_shadow_blob(0.4)


## Cheaper spare burr for the sack (5 spikes; the sack burrs are half hidden).
static func _spare_burr_mesh() -> Mesh:
	var parts: Array = [[sphere(0.11, 5, 3), Transform3D.IDENTITY]]
	var spike := cyl(0.0, 0.05, 0.18, 4, false)   # base inside the ball: no cap (face budget)
	for d: Vector3 in [Vector3.UP, Vector3(1, 0.3, 0.6), Vector3(-1, 0.3, 0.5), Vector3(0.2, 0.5, -1), Vector3(0.1, 0.4, 1)]:
		var n := d.normalized()
		parts.append([spike, Transform3D(Basis(Quaternion(Vector3.UP, n)), n * 0.17)])
	return _combine("burr_spare", parts)


## 3 spare burrs poking out of the sack over the left shoulder (one mesh, model space).
static func _sack_burrs_mesh() -> Mesh:
	var b := _spare_burr_mesh()
	# 3 -> 2 burrs (face rework 2026-09-28: pays for the face), the pair a little bigger
	return _combine("slinger_sack_burrs_f1", [[b, Transform3D(Basis().scaled(Vector3.ONE * 0.8), Vector3(-0.14, 1.16, -0.30))],
		[b, Transform3D(Basis(Vector3.UP, 0.6).scaled(Vector3.ONE * 0.74), Vector3(0.05, 1.14, -0.33))]])


## Two team leaf fins on the seed chamber (top and bottom, lying along the pod, tips toward the back).
static func _fins_mesh() -> Mesh:
	var d := POD_DIR.normalized()
	var back := GRIP - d * POD_BACK
	var side := d.cross(Vector3.UP).normalized()
	var up := side.cross(d).normalized()
	var xs: Array[Transform3D] = []
	for s: float in [1.0, -1.0]:
		var base := back + d * 0.46 + up * 0.14 * s
		var tip_dir := (-d + up * 0.55 * s).normalized()
		var bz := tip_dir
		var bx := side
		var by := bz.cross(bx).normalized()
		bx = by.cross(bz).normalized()
		var size := Vector3(0.10, 0.04, 0.44)
		xs.append(Transform3D(Basis(bx, by, bz).scaled_local(size), base + bz * size.z * 0.5))
	return cluster_mesh("slinger_fins_a22", leaf_mesh(), xs)


## The 3 charge seeds in a row on the chamber's back (one glow mesh, own glow).
static func _seeds_mesh() -> Mesh:
	const KEY := "slinger_seeds_a22"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var d := POD_DIR.normalized()
	var back := GRIP - d * POD_BACK
	var up := d.cross(Vector3.UP).normalized().cross(d).normalized()
	var st := SurfaceTool.new()
	for k: int in 3:
		st.append_from(sphere(0.055, 6, 3), 0, Transform3D(Basis(), back + d * (0.18 + 0.14 * float(k)) + up * 0.19))
	return _cached(KEY, _indexed(st))


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"pod_shot":
		return super._pose_attack(prev, t)
	var w: float = attack_windup if attack_windup > 0.0 else 0.12
	var ts: float = t * 0.12 / w   # the tracks are keyed for a 0.12 s release
	var a := _kf(ts, S_ARM) * DEG
	rot(P_ARM_R, Vector3(a, 0, 0))
	rot(P_ARM_L, Vector3(a, 0, 0))
	rot(P_CHEST, Vector3(_kf(ts, S_CHEST_X) * DEG, _kf(ts, S_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, _kf(ts, S_ROOT_Y), _kf(ts, S_ROOT_Z)))
	if _tier == 0:
		rot(P_HEAD, Vector3(_kf(ts, S_HEAD_X) * DEG, 0, 0))
		rot(P_LEG_L, Vector3(_kf(ts, S_LEG_L) * DEG, 0, 0))
		rot(P_LEG_R, Vector3(_kf(ts, S_LEG_R) * DEG, 0, 0))
	if prev < w and t >= w:
		_on_action_event(&"release")
	return t < SHOT_LEN


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		_flare = 1.0
		_burr_t = 0.0
		if _burr:
			_burr.visible = false
		if _puff and _tier < 2:
			_puff.restart()


## Sneaking jog: crouched lower, the pod held level (the kit swings ArmL -18 / ArmR +8: ArmL is brought to +8 too so
## the left hand stays on the pod), a slight shoulder roll.
func _pose_walk(w: float, rate: float) -> void:
	super(w, rate)
	var s: float = sin(TAU * _walk_p)
	rot(P_ARM_L, Vector3(26.0 * DEG * s * w, 0, 0))
	rot(P_ROOT, Vector3(7.0 * DEG * w, 0, 0))
	pos(P_ROOT, Vector3(0, -0.04 * w, 0))
	if _tier == 0:
		rot(P_CHEST, Vector3(0, -5.0 * DEG * s * w, 0))
		rot(P_HEAD, Vector3(0, 5.0 * DEG * s * w, 0))


## Death: the pod flies up out of the hands, then the kit's fall.
func _pose_death(dt: float) -> void:
	super(dt)
	var t: float = _death_t
	var k := _k3(t, 0.0, 0.12, 0.3, 0.6, 1.0, 0.7)
	rot(P_ARM_R, Vector3(-55.0 * DEG * k, 0, 0))
	rot(P_ARM_L, Vector3(-75.0 * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, 0, -0.12 * k))


## Fidget: raises the pod to the eye and sights along it, sweeping slowly, then lowers it.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.35, 1.5, 1.9, 1.0, 1.0)
	var sweep: float = sin(clampf((t - 0.35) / 1.15, 0.0, 1.0) * TAU) * 12.0
	rot(P_ARM_R, Vector3(-30.0 * DEG * k, 0, 0))
	rot(P_ARM_L, Vector3(-30.0 * DEG * k, 0, 0))
	rot(P_CHEST, Vector3(0, (22.0 + sweep) * DEG * k, 0))
	rot(P_HEAD, Vector3(8.0 * DEG * k, -14.0 * DEG * k, 0))
	return 1.9


func _war_process(dt: float) -> void:
	var charge: float = 0.0
	if _action == &"attack" and _action_t < attack_windup:
		charge = clampf(_action_t / maxf(attack_windup, 0.01), 0.0, 1.0)
	_flare = maxf(0.0, _flare - dt / 0.3)
	var g := glow_level()
	if _tip:
		var b: float = g * (1.0 + 1.5 * charge + 2.5 * _flare)
		if b != _tip_written:
			_tip_written = b
			_tip.set_instance_shader_parameter(&"glow_boost", b)
	# Seeds: full while loaded, dark right after the shot, fill back as the burr regrows; brighten on the aim.
	if _seeds:
		var ld: float = 1.0
		if _burr_t < 99.0:
			ld = clampf((_burr_t - 0.1) / 0.4, 0.15, 1.0)
		var sb: float = snappedf(g * ld * (1.0 + 1.2 * charge + 1.5 * _flare), 0.02)
		if sb != _seed_written:
			_seed_written = sb
			_seeds.set_instance_shader_parameter(&"glow_boost", sb)
	# Reload: the burr regrows in the mouth 0.35-0.5 s after the shot.
	if _burr and _burr_t < 99.0:
		_burr_t += dt
		var s: float = clampf((_burr_t - 0.35) / 0.15, 0.0, 1.0)
		if s > 0.0 and not _dead:
			_burr.visible = true
			if s != _burr_s:
				_burr_s = s
				_burr.scale = Vector3.ONE * BURR_SCALE * maxf(s, 0.05)
		if s >= 1.0:
			_burr_t = 99.0


func _war_revive() -> void:
	_flare = 0.0
	_tip_written = -1.0
	_seed_written = -1.0
	_burr_t = 99.0
	_burr_s = 1.0
	if _burr:
		_burr.visible = true
		_burr.scale = Vector3.ONE * BURR_SCALE

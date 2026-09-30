extends IceModel
## Frost Mortar, Ice T2 siege (new-units-12.md 6, rush-balance.md 5.4; tiers wave, medium). Height 1.4, radius 0.8.
## An ice-bound mortar on a sled with its 2 Hauler crew:
##  - Mount pivot = the sled: iron-shod runners curling up at the front, a plank deck, a big faceted ICE BLOCK
##    encasing the base of a squat steel MORTAR TUBE raised 55 deg forward (silver bands, frost crystals growing on
##    it), a rack of 3 frost shells at the back left, a push bar at the back, and the kneeling LOADER (team coat, fur
##    hood) at the front left holding the next shell (static, merged with the sled).
##  - Chest / Head / Arms / Legs = the GUNNER standing behind on the right, both hands on the push bar.
## Glow point: the muzzle (own glow): a cold charge that brightens on the wind-up and flashes at the shot.
## Attack `mortar_fire` (1.0 s, release 0.15): the gunner yanks the lanyard, the tube thumps (the whole sled kicks
## back and noses up), a burst of motes + a thick frost vapour cloud at the muzzle that drifts for a second.
## play_cast(&"frost_shell") = the same shot, bigger flash and vapour. Death: tips over, freezes, shatters.

const ATTACK_LEN := 1.0
const G := Vector3(0.30, 0.0, -0.78)            # gunner offset (model space)
const TUBE_BASE := Vector3(0.0, 0.52, 0.16)
const TUBE_DIR := Vector3(0.0, 0.819, 0.574)     # 55 deg elevation, forward
const BAR_Y := 0.74
const BAR_Z := -0.50

var _muzzle: GeometryInstance3D
var _vapour: GPUParticles3D
var _burst: GPUParticles3D
var _flare: float = 0.0
var _charge: float = 0.0
var _big: float = 1.0
var _muzzle_written: float = -1.0
var _face_loader: FaceRig                 # the kneeling loader's face (on the sled pivot); _face = the gunner's


func _build_parts() -> void:
	var mount: Node3D = $Root/Mount
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var cloth := ice(&"ice_cloth")
	var cdark := ice(&"ice_cloth_dark")
	var skin := ice(&"ice_skin")
	var leather := ice(&"ice_leather")
	var fur := ice(&"ice_fur")
	var pale := ice(&"ice_fur_pale")
	var wood := ice(&"ice_wood")
	var metal := ice(&"ice_metal")
	var steel := ice(&"ice_steel")
	var frost := ice(&"ice_frost_crystal")
	var deep := ice(&"ice_frost_deep")
	var glow := ice(&"ice_glow_unit")
	# ================= the sled (Mount pivot)
	for s: float in [-1.0, 1.0]:
		var x: float = 0.40 * s
		add_part(mount, _path("fm_runner", PackedVector3Array([Vector3(0, 0.06, -0.80), Vector3(0, 0.04, 0.42),
			Vector3(0, 0.10, 0.66), Vector3(0, 0.25, 0.80), Vector3(0, 0.38, 0.76)]),
			PackedFloat32Array([0.045, 0.045, 0.042, 0.038, 0.03]), 6), steel, Vector3(x, 0, 0))
		for z: float in [-0.55, -0.05, 0.40]:
			add_part(mount, box(Vector3(0.07, 0.16, 0.07)), wood, Vector3(x, 0.13, z))
	add_part(mount, box(Vector3(0.92, 0.08, 1.30)), wood, Vector3(0, 0.23, -0.08))
	for z: float in [-0.60, -0.20, 0.20]:
		add_part(mount, box(Vector3(0.96, 0.03, 0.05)), steel, Vector3(0, 0.275, z))
	# ice block around the mortar base (+ a deeper blue chunk frozen to it)
	add_part(mount, box(Vector3(0.62, 0.30, 0.62)), frost, Vector3(0, 0.41, 0.16), Vector3(0, 14, 0))
	add_part(mount, box(Vector3(0.30, 0.22, 0.28)), deep, Vector3(0.26, 0.36, 0.38), Vector3(8, -20, 6))
	add_crystal(mount, Vector3(-0.28, 0.46, 0.34), Vector3(-0.6, 1.0, 0.4), 0.06, 0.30, frost, 0.5)
	# palette depth: a dark stone plinth under the block, snow caked on the block top and on the runner curls
	add_part(mount, box(Vector3(0.70, 0.07, 0.70)), ice(&"ice_stone_dark"), Vector3(0, 0.29, 0.16), Vector3(0, 14, 0))
	add_part(mount, sphere(0.30, 10, 5), ice(&"ice_hair"), Vector3(-0.08, 0.56, 0.14), Vector3(0, 14, 0), Vector3(1.0, 0.22, 0.9))
	for s: float in [-1.0, 1.0]:
		add_part(mount, sphere(0.07, 7, 4), ice(&"ice_hair"), Vector3(0.40 * s, 0.30, 0.80), Vector3.ZERO, Vector3(1.0, 0.6, 1.2))
	add_crystal(mount, Vector3(0.30, 0.50, -0.02), Vector3(0.7, 1.0, -0.2), 0.05, 0.24, frost, 0.5)
	# the mortar tube: squat steel barrel raised forward, silver bands, trunnions, frost crystals on it
	var d := TUBE_DIR.normalized()
	var e := Basis(Quaternion(Vector3.UP, d)).get_euler() * (180.0 / PI)
	add_part(mount, sphere(0.25, 10, 5), steel, TUBE_BASE + Vector3(0, 0.02, -0.04), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	add_part(mount, cyl(0.23, 0.27, 0.74, 12), steel, TUBE_BASE + d * 0.35, e)
	add_part(mount, cyl(0.29, 0.23, 0.10, 12, false), steel, TUBE_BASE + d * 0.74, e)
	add_part(mount, cyl(0.28, 0.28, 0.07, 12), metal, TUBE_BASE + d * 0.20, e)
	add_part(mount, cyl(0.265, 0.265, 0.06, 12), metal, TUBE_BASE + d * 0.48, e)
	add_part(mount, torus(0.22, 0.31, 12), metal, TUBE_BASE + d * 0.79, e)
	add_part(mount, cyl(0.06, 0.06, 0.62, 8), metal, TUBE_BASE + Vector3(0, 0.02, 0.0), Vector3(0, 0, 90))
	add_crystal(mount, TUBE_BASE + d * 0.40 + Vector3(-0.2, 0.0, 0.0), Vector3(-1.0, 0.5, 0.2), 0.045, 0.22, frost, 0.5)
	add_crystal(mount, TUBE_BASE + d * 0.28 + Vector3(0.18, 0.06, 0.0), Vector3(1.0, 0.8, -0.1), 0.04, 0.18, frost, 0.5)
	# back rack with 3 frost shells (back left) and the push bar at the back
	add_part(mount, box(Vector3(0.36, 0.08, 0.34)), wood, Vector3(-0.24, 0.31, -0.52))
	for p: Vector3 in [Vector3(-0.32, 0.43, -0.45), Vector3(-0.16, 0.43, -0.56), Vector3(-0.28, 0.43, -0.62)]:
		add_part(mount, sphere(0.085, 8, 4), frost, p, Vector3.ZERO, Vector3(1.0, 1.25, 1.0))
		add_part(mount, cyl(0.03, 0.05, 0.05, 6), metal, p + Vector3(0, 0.11, 0))
	for s: float in [-1.0, 1.0]:
		add_part(mount, cyl(0.03, 0.03, 0.52, 6), wood, Vector3(0.30 + 0.24 * s, 0.48, BAR_Z - 0.02), Vector3(-12, 0, 0))
	add_part(mount, cyl(0.035, 0.035, 0.62, 6), wood, Vector3(0.30, BAR_Y, BAR_Z - 0.07), Vector3(0, 0, 90))
	# the kneeling loader at the front left (static, part of the sled), holding the next shell
	var lo := Vector3(-0.60, 0.0, 0.34)
	add_part(mount, cyl(0.20, 0.30, 0.42, 9), cloth, lo + Vector3(0, 0.44, 0), Vector3(-10, 0, 0))
	add_part(mount, cyl(0.30, 0.32, 0.09, 9), fur, lo + Vector3(0, 0.25, -0.03), Vector3(-10, 0, 0))
	add_part(mount, cyl(0.16, 0.25, 0.12, 9), pale, lo + Vector3(0, 0.66, 0.02))
	add_part(mount, capsule(0.09, 0.36), fur, lo + Vector3(-0.1, 0.16, 0.14), Vector3(80, 0, 0))
	add_part(mount, capsule(0.09, 0.32), fur, lo + Vector3(0.1, 0.12, -0.08), Vector3(0, 0, 0))
	add_part(mount, box(Vector3(0.16, 0.09, 0.26)), leather, lo + Vector3(0.1, 0.045, 0.0))
	add_part(mount, sphere(0.16, 9, 5), skin, lo + Vector3(0, 0.80, 0.06))
	add_part(mount, sphere(0.2, 9, 5), cloth, lo + Vector3(0, 0.84, -0.02), Vector3.ZERO, Vector3(1.0, 1.05, 1.0))
	add_part(mount, cyl(0.0, 0.12, 0.24, 6), cloth, lo + Vector3(0, 0.95, -0.2), Vector3(-60, 0, 0))
	add_part(mount, torus(0.11, 0.19, 10), pale, lo + Vector3(0, 0.81, 0.13), Vector3(80, 0, 0))
	# the loader's face (faces pass 2026-09-28): its own FaceRig on the sled pivot (replaces the eye bar: the eye_dark
	# surface of the sled merge goes, the face node comes: same draw count). A young loader, straw fringe.
	var lh := Color(0.88, 0.80, 0.56)
	_face_loader = UnitFaces.attach_lean(self, mount, "frost_mortar_loader", {"center": lo + Vector3(0, 0.80, 0.06), "radius": 0.16,
		"head_mesh": sphere(0.16, 9, 5), "preset": &"bright", "detail": &"low", "skin": ICE_SKIN, "hair": lh,
		"hair_tip": Color(0.98, 0.94, 0.78), "eyes": Color(0.40, 0.60, 0.80), "ears": &"none",
		"palette": {"brow": lh.darkened(0.4)}, "eye": {"c": Vector2(0.056, 0.016)},
		"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, lo + Vector3(0, 0.80, 0.06), 0.16, lh,
			Color(0.98, 0.94, 0.78), -1.0)}, false)
	for s: float in [-1.0, 1.0]:
		add_limb(mount, lo + Vector3(0.22 * s, 0.62, 0.0), lo + Vector3(0.10 + 0.08 * s, 0.50, 0.26), 0.07, cloth, 0.08, leather)
	add_part(mount, sphere(0.10, 8, 4), frost, lo + Vector3(0.10, 0.56, 0.30), Vector3.ZERO, Vector3(1.0, 1.25, 1.0))
	# ================= the gunner (kit rig): hauler build, both hands on the push bar
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, capsule(0.11, 0.40), fur, G + Vector3(0.14 * sx, 0.30, 0))
		add_part(leg, box(Vector3(0.23, 0.13, 0.32)), leather, G + Vector3(0.14 * sx, 0.065, 0.05))
		add_part(leg, cyl(0.12, 0.115, 0.06, 8), pale, G + Vector3(0.14 * sx, 0.16, 0.0))
	add_part(chest, cyl(0.25, 0.37, 0.54, 10), cloth, G + Vector3(0, 0.80, 0))
	add_part(chest, cyl(0.37, 0.40, 0.12, 10), fur, G + Vector3(0, 0.56, 0))
	add_part(chest, cyl(0.28, 0.30, 0.07, 10), leather, G + Vector3(0, 0.84, 0))
	add_part(chest, cyl(0.19, 0.32, 0.14, 10), pale, G + Vector3(0, 1.06, 0))
	add_part(chest, box(Vector3(0.14, 0.40, 0.04)), cdark, G + Vector3(0, 0.80, 0.26), Vector3(-12, 0, 0))
	add_part(chest, cyl(0.08, 0.07, 0.26, 6), leather, G + Vector3(-0.30, 0.78, 0.02), Vector3(0, 0, 10))
	add_part(head, sphere(0.19, 10, 5), skin, G + Vector3(0, 1.20, 0.06))
	add_part(head, sphere(0.245, 10, 6), cloth, G + Vector3(0, 1.25, -0.05), Vector3.ZERO, Vector3(1.0, 1.05, 1.0))
	add_part(head, cyl(0.0, 0.15, 0.30, 6), cloth, G + Vector3(0, 1.38, -0.24), Vector3(-62, 0, 0))
	add_part(head, torus(0.14, 0.23, 12), pale, G + Vector3(0, 1.21, 0.14), Vector3(90, 0, 0))
	# the gunner's face (faces pass 2026-09-28): a grizzled hauler, grey moustache, grey-blue eyes (replaces the eye bar)
	_face = UnitFaces.attach_lean(self, head, "frost_mortar_gunner", {"center": G + Vector3(0, 1.20, 0.06), "radius": 0.19,
		"head_mesh": sphere(0.19, 10, 5), "preset": &"elder", "detail": &"low", "skin": ICE_SKIN,
		"hair": Color(0.62, 0.64, 0.68), "hair_tip": Color(0.86, 0.88, 0.92), "eyes": Color(0.40, 0.52, 0.66), "ears": &"none",
		"beard": &"moustache", "palette": {"brow": Color(0.40, 0.42, 0.46)}, "eye": {"c": Vector2(0.066, 0.02)}}, false)
	var trim := add_part(head, torus(0.19, 0.24, 12), palette(&"unit_gold_trim"), G + Vector3(0, 1.38, -0.05),
		Vector3(-10, 0, 0), Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	for arm: Node3D in [arm_l, arm_r]:
		var sx: float = -1.0 if arm == arm_l else 1.0
		var hand := Vector3(G.x + 0.22 * sx, BAR_Y, BAR_Z - 0.07)
		add_limb(arm, G + Vector3(0.34 * sx, 1.02, 0), hand, 0.095, cloth, 0.105, leather)
	# ================= glow + fx
	var tip := TUBE_BASE + d * 0.76
	_muzzle = add_part(mount, cyl(0.2, 0.2, 0.03, 12), glow, tip, e, Vector3.ONE, true, "Muzzle")
	_muzzle.set_meta(&"own_glow", true)
	# Half-size, shorter vapour (in-game grade 2026-09-30: the muzzle cloud read as a white puff the size of a unit).
	_vapour = _puffs(0.4, 6, 1.0, 0.85, 0.12, Vector3(0, 1, 0.3), 25.0, 0.4, 0.8, Vector3(0, 0.25, 0), 0.45)
	_vapour.name = "Vapour"
	_vapour.position = tip + d * 0.05 - model_origin(mount)
	mount.add_child(_vapour)
	_burst = make_motes(ICE_GLOW, 10, 0.4, 0.12, 3.5, 0.10, false, true)
	_burst.name = "MuzzleBurst"
	_burst.position = tip + d * 0.08 - model_origin(mount)
	mount.add_child(_burst)
	add_breath(G + Vector3(0, 1.18, 0.30), 0.20)
	add_hit_chips(Vector3(0, 0.6, 0.1), 7)
	add_shatter(Vector3(0, 0.55, 0), 16, 0.55, 0.12)
	ensure_shadow_blob(0.85, BLOB_TINT)


static func _path(key: String, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	for i: int in pts.size() - 1:
		var a := pts[i]
		var dd := pts[i + 1] - a
		var len_total := dd.length() + 0.02
		st.append_from(cyl(radii[i + 1], radii[i], len_total, seg, false), 0,
			Transform3D(Basis(Quaternion(Vector3.UP, dd.normalized())), a + dd.normalized() * len_total * 0.5))
	st.index()
	return _cached(key, st.commit())


# ================================================================ motion

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"mortar_fire":
		return super._pose_attack(prev, t)
	_pose_shot(t)
	if prev < attack_windup and t >= attack_windup:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## The shot timeline (attack and cast): lanyard yank, thump, the sled kicks back + noses up, the crew flinches.
func _pose_shot(t: float) -> void:
	var r := attack_windup
	_charge = clampf(t / maxf(r, 0.01), 0.0, 1.0) if t < r else 0.0
	var kick := _k3(t, r, r + 0.05, r + 0.12, 0.8, 1.0, 0.8)
	pos(P_MOUNT, Vector3(0, 0.05 * kick, -0.28 * kick))
	rot(P_MOUNT, Vector3(-11.0 * DEG * kick, 0, 0))
	rot(P_ARM_R, Vector3(_k3(t, 0.0, r, r + 0.1, 0.7, 45.0, 30.0) * DEG, 0, 18.0 * DEG * _k3(t, 0.0, r, r + 0.1, 0.7, 1.0, 1.0)))
	rot(P_ARM_L, Vector3(-70.0 * DEG * _k3(t, r, r + 0.08, r + 0.25, 0.8, 1.0, 0.7), 0, 0))
	rot(P_CHEST, Vector3(_k3(t, 0.0, r, r + 0.1, 0.8, -14.0, -20.0) * DEG, _k3(t, 0.0, r, r + 0.1, 0.8, 16.0, 10.0) * DEG, 0))
	rot(P_HEAD, Vector3(_k3(t, r, r + 0.06, r + 0.2, 0.7, 18.0, 10.0) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, 0, -0.10 * kick))


func _pose_cast(_spell: StringName, t: float) -> float:
	_pose_shot(t)
	if t >= attack_windup and _big < 1.5:
		_big = 1.8
		_fire(1.8)
	return ATTACK_LEN


func _fire(amount: float) -> void:
	_flare = amount
	_charge = 0.0
	if _tier < 2:
		if _vapour:
			_vapour.restart()
		if _burst:
			_burst.restart()


func _on_action_event(ev: StringName) -> void:
	if ev == &"release":
		_fire(1.0)
	elif ev == &"cast_start":
		_big = 1.0
	elif ev == &"attack_end" or ev == &"cast_end" or ev == &"death_glow_off":
		_charge = 0.0


func _ice_process(dt: float) -> void:
	if _face_loader:
		_face_loader.auto(self)
	if _walk_w > 0.0 and not _dead:
		# the gunner pushes: lean in, hands stay on the bar (cancel the kit's arm swing)
		var s: float = sin(TAU * _walk_p)
		rot(P_CHEST, Vector3(14.0 * DEG * _walk_w, 0, 0))
		rot(P_ARM_L, Vector3(18.0 * DEG * s * _walk_w, 0, 0))
		rot(P_ARM_R, Vector3(-8.0 * DEG * s * _walk_w, 0, 0))
	if _action != &"attack" and _action != &"cast":
		_charge = 0.0
	_flare = maxf(0.0, _flare - dt / 0.5)
	if _muzzle:
		var b: float = glow_level() * (1.3 + 2.0 * _charge + 2.6 * _flare)
		if absf(b - _muzzle_written) > 0.04:
			_muzzle_written = b
			_muzzle.set_instance_shader_parameter(&"glow_boost", b)


func _ice_revive() -> void:
	if _face_loader:
		_face_loader.reset()
	_flare = 0.0
	_charge = 0.0
	_muzzle_written = -1.0


## Fidget: the gunner leans round the tube to sight the target, shading his eyes.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.4, 1.1, 1.5, 1.0, 1.0)
	rot(P_CHEST, Vector3(-6.0 * DEG * k, -18.0 * DEG * k, 0))
	rot(P_ARM_L, Vector3(-120.0 * DEG * k, 0, -20.0 * DEG * k))
	rot(P_HEAD, Vector3(-10.0 * DEG * k, -10.0 * DEG * k, 0))
	return 1.5

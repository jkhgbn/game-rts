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


## G-C leftovers (2026-10-15, docs/art/gc_leftovers.md): the sled, the loader and the gunner are built from smooth
## tubes, lathes, faceted ice and bevelled plates (ChampionShapes, one mesh per pivot and material, cached per process)
## instead of boxes / capsules / tori: curled runners, a faceted ice block, a lathed mortar with breech, banded barrel and
## flared bored muzzle, egg shells, a hunched hooded loader and gunner with fur hems. Under the soldier budget (was 5039).
func _build_parts() -> void:
	var mount: Node3D = $Root/Mount
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var d := TUBE_DIR.normalized()
	var e := Basis(Quaternion(Vector3.UP, d)).get_euler() * (180.0 / PI)
	var lo := Vector3(-0.60, 0.0, 0.34)
	# ================= the sled + the kneeling loader (Mount pivot)
	IceUnitShapes.put(self, mount, "fm_gc_sled", _gc_sled)
	# the loader's face (faces pass 2026-09-28): its own FaceRig on the sled pivot. A young loader, straw fringe.
	var lh := Color(0.88, 0.80, 0.56)
	_face_loader = UnitFaces.attach_lean(self, mount, "frost_mortar_loader", {"center": lo + Vector3(0, 0.80, 0.06), "radius": 0.16,
		"head_mesh": sphere(0.16, 9, 5), "preset": &"bright", "detail": &"low", "skin": ICE_SKIN, "hair": lh,
		"hair_tip": Color(0.98, 0.94, 0.78), "eyes": Color(0.40, 0.60, 0.80), "ears": &"none",
		"palette": {"brow": lh.darkened(0.4)}, "eye": {"c": Vector2(0.056, 0.016)},
		"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, lo + Vector3(0, 0.80, 0.06), 0.16, lh,
			Color(0.98, 0.94, 0.78), -1.0)}, false)
	# ================= the gunner (kit rig): hauler build, both hands on the push bar
	IceUnitShapes.put(self, leg_l, "fm_gc_leg_l", func(acc: Dictionary) -> void: _gc_leg(acc, -1.0))
	IceUnitShapes.put(self, leg_r, "fm_gc_leg_r", func(acc: Dictionary) -> void: _gc_leg(acc, 1.0))
	IceUnitShapes.put(self, chest, "fm_gc_chest", _gc_chest)
	IceUnitShapes.put(self, head, "fm_gc_head", _gc_head)
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
	IceUnitShapes.put(self, arm_l, "fm_gc_arm_l", func(acc: Dictionary) -> void: _gc_arm(acc, -1.0))
	IceUnitShapes.put(self, arm_r, "fm_gc_arm_r", func(acc: Dictionary) -> void: _gc_arm(acc, 1.0))
	var glow := ice(&"ice_glow_unit")
	# ================= glow + fx
	var tip := TUBE_BASE + d * 0.76
	_muzzle = add_part(mount, cyl(0.2, 0.2, 0.03, 10), glow, tip, e, Vector3.ONE, true, "Muzzle")
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


# ================================================================ G-C shape builders (model space, IceUnitShapes)

func _gc_sled(acc: Dictionary) -> void:
	var steel := IceUnitShapes.st(acc, ice(&"ice_steel"))
	var wood := IceUnitShapes.st(acc, ice(&"ice_wood"))
	var metal := IceUnitShapes.st(acc, ice(&"ice_metal"))
	var frost := IceUnitShapes.st(acc, ice(&"ice_frost_crystal"))
	var deep := IceUnitShapes.st(acc, ice(&"ice_frost_deep"))
	var stone := IceUnitShapes.st(acc, ice(&"ice_stone_dark"))
	var snow := IceUnitShapes.st(acc, ice(&"ice_hair"))
	var d := TUBE_DIR.normalized()
	var txf := IceUnitShapes.on(d, TUBE_BASE)
	for s: float in [-1.0, 1.0]:
		var x: float = 0.40 * s
		# iron-shod runner: flat along the ground, a swan-neck curl at the front
		ChampionShapes.tube(steel, PackedVector3Array([Vector3(x, 0.05, -0.84), Vector3(x, 0.035, -0.40), Vector3(x, 0.035, 0.40),
			Vector3(x, 0.08, 0.63), Vector3(x, 0.24, 0.80), Vector3(x, 0.41, 0.74)]),
			PackedFloat32Array([0.035, 0.042, 0.042, 0.04, 0.034, 0.026]), 6, true)
		# raked struts from the runner up to the deck
		for z: float in [-0.50, 0.36]:
			ChampionShapes.tube(wood, PackedVector3Array([Vector3(x, 0.05, z - 0.03), Vector3(x * 0.96, 0.21, z + 0.02)]),
				PackedFloat32Array([0.036, 0.030]), 5, false)
	# plank deck (bevelled, a tapered nose), two iron straps
	ChampionShapes.plate(wood, PackedVector2Array([Vector2(-0.46, 0.72), Vector2(0.46, 0.72), Vector2(0.47, -0.38),
		Vector2(0.30, -0.60), Vector2(-0.30, -0.60), Vector2(-0.47, -0.38)]), 0.08, 0.022,
		Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.23, 0)))
	for z: float in [-0.45, 0.30]:
		ChampionShapes.append(steel, soft_box(Vector3(0.96, 0.03, 0.06)), Transform3D(Basis.IDENTITY, Vector3(0, 0.275, z)))
	# dark stone plinth, the faceted ice block on it, a deeper blue chunk frozen to it, a snow cap on the block
	ChampionShapes.append(stone, soft_box(Vector3(0.68, 0.07, 0.68)), IceUnitShapes.xf(Vector3(0, 0.29, 0.16), Vector3(0, 14, 0)))
	ChampionShapes.lathe(frost, PackedVector2Array([Vector2(0.33, 0.0), Vector2(0.38, 0.11), Vector2(0.33, 0.24),
		Vector2(0.20, 0.31)]), 6, IceUnitShapes.xf(Vector3(0, 0.30, 0.16), Vector3(0, 14, 0)), 1.05, 0.95, true, 0.0, TAU, true)
	ChampionShapes.lathe(deep, PackedVector2Array([Vector2(0.13, 0.0), Vector2(0.15, 0.09), Vector2(0.06, 0.20)]), 5,
		IceUnitShapes.xf(Vector3(0.27, 0.31, 0.38), Vector3(8, -20, 6)), 1.0, 0.9, false, 0.0, TAU, true)
	ChampionShapes.lathe(snow, PackedVector2Array([Vector2(0.27, 0.0), Vector2(0.22, 0.035), Vector2(0.0, 0.05)]), 8,
		IceUnitShapes.xf(Vector3(-0.06, 0.585, 0.12), Vector3(0, 14, 0)), 1.0, 0.85, false)
	IceUnitShapes.crystal(frost, Vector3(-0.28, 0.46, 0.34), Vector3(-0.6, 1.0, 0.4), 0.06, 0.30)
	IceUnitShapes.crystal(frost, Vector3(0.30, 0.50, -0.02), Vector3(0.7, 1.0, -0.2), 0.05, 0.24)
	# the mortar: rounded breech, swelling barrel, flared muzzle lip, a dark bore (profile turns back inside)
	ChampionShapes.lathe(steel, PackedVector2Array([Vector2(0.0, -0.25), Vector2(0.16, -0.21), Vector2(0.25, -0.08),
		Vector2(0.275, 0.06), Vector2(0.255, 0.42), Vector2(0.235, 0.66), Vector2(0.30, 0.74), Vector2(0.305, 0.80),
		Vector2(0.215, 0.80), Vector2(0.20, 0.62), Vector2(0.0, 0.60)]), 9, txf, 1.0, 1.0, false)
	ChampionShapes.band(metal, 0.262, 0.07, 0.022, 10, IceUnitShapes.on(d, TUBE_BASE + d * 0.22))
	ChampionShapes.tube(metal, PackedVector3Array([TUBE_BASE + Vector3(-0.32, 0.02, 0), TUBE_BASE + Vector3(0.32, 0.02, 0)]),
		PackedFloat32Array([0.06, 0.06]), 6, true)
	IceUnitShapes.crystal(frost, TUBE_BASE + d * 0.40 + Vector3(-0.22, 0.0, 0.0), Vector3(-1.0, 0.5, 0.2), 0.045, 0.22)
	# back rack with 3 frost shells
	ChampionShapes.append(wood, soft_box(Vector3(0.36, 0.08, 0.34)), Transform3D(Basis.IDENTITY, Vector3(-0.24, 0.31, -0.52)))
	for p: Vector3 in [Vector3(-0.32, 0.43, -0.45), Vector3(-0.16, 0.43, -0.56), Vector3(-0.28, 0.43, -0.62)]:
		IceUnitShapes.egg(frost, Transform3D(Basis.IDENTITY, p), 0.085, 0.24, 6)
	# push bar: two raked posts and the bar (the gunner's mitts sit on it)
	for s: float in [-1.0, 1.0]:
		ChampionShapes.tube(wood, PackedVector3Array([Vector3(0.30 + 0.24 * s, 0.25, BAR_Z + 0.04),
			Vector3(0.30 + 0.24 * s, BAR_Y, BAR_Z - 0.07)]), PackedFloat32Array([0.032, 0.03]), 5, false)
	ChampionShapes.tube(wood, PackedVector3Array([Vector3(-0.02, BAR_Y, BAR_Z - 0.07), Vector3(0.62, BAR_Y, BAR_Z - 0.07)]),
		PackedFloat32Array([0.036, 0.036]), 6, true)
	_gc_loader(acc)


## The kneeling loader at the front left (static, part of the sled), holding the next shell.
func _gc_loader(acc: Dictionary) -> void:
	var lo := Vector3(-0.60, 0.0, 0.34)
	var cloth := IceUnitShapes.st(acc, ice(&"ice_cloth"))
	var fur := IceUnitShapes.st(acc, ice(&"ice_fur"))
	var pale := IceUnitShapes.st(acc, ice(&"ice_fur_pale"))
	var leather := IceUnitShapes.st(acc, ice(&"ice_leather"))
	var skin := IceUnitShapes.st(acc, ice(&"ice_skin"))
	var frost := IceUnitShapes.st(acc, ice(&"ice_frost_crystal"))
	var hunch := IceUnitShapes.xf(lo, Vector3(-10, 0, 0))
	# hunched coat with a fur hem and a pale fur collar
	ChampionShapes.lathe(cloth, PackedVector2Array([Vector2(0.31, 0.22), Vector2(0.28, 0.40), Vector2(0.22, 0.57),
		Vector2(0.15, 0.68)]), 9, hunch, 1.0, 0.92, false)
	ChampionShapes.append(fur, fur_ring(0.30, 0.34, 0.10, 5, 0.04), hunch * Transform3D(Basis.IDENTITY, Vector3(0, 0.17, 0)))
	ChampionShapes.append(pale, fur_ring(0.15, 0.24, 0.10, 5, 0.03), Transform3D(Basis.IDENTITY, lo + Vector3(0, 0.60, 0.02)))
	# the raised knee and its boot (the other knee is down under the coat)
	ChampionShapes.tube(fur, PackedVector3Array([lo + Vector3(0.10, 0.28, 0.04), lo + Vector3(0.12, 0.34, 0.25),
		lo + Vector3(0.12, 0.09, 0.27)]), PackedFloat32Array([0.10, 0.085, 0.07]), 6, false)
	ChampionShapes.append(leather, boot(0.085, 0.11), IceUnitShapes.xf(lo + Vector3(0.12, 0.0, 0.31), Vector3.ZERO, Vector3(1.0, 1.0, 1.4)))
	# head in a pointed hood, open at the front, pale fur trim round the face
	ChampionShapes.append(skin, sphere(0.16, 9, 5), Transform3D(Basis.IDENTITY, lo + Vector3(0, 0.80, 0.06)))
	ChampionShapes.tube(cloth, PackedVector3Array([lo + Vector3(0, 0.80, 0.10), lo + Vector3(0, 0.84, -0.04),
		lo + Vector3(0, 0.90, -0.18), lo + Vector3(0, 0.99, -0.34)]), PackedFloat32Array([0.19, 0.21, 0.15, 0.0]), 8, false)
	ChampionShapes.append(pale, fur_ring(0.17, 0.20, 0.05, 5, 0.02),
		Transform3D(Basis(Vector3.RIGHT, PI * 0.5), lo + Vector3(0, 0.80, 0.09)))
	# arms forward, mitts round the next shell
	for s: float in [-1.0, 1.0]:
		var hand := lo + Vector3(0.10 + 0.08 * s, 0.50, 0.26)
		ChampionShapes.tube(cloth, PackedVector3Array([lo + Vector3(0.20 * s, 0.62, 0.0), lo + Vector3(0.20 * s, 0.46, 0.13), hand]),
			PackedFloat32Array([0.075, 0.066, 0.056]), 6, false)
		IceUnitShapes.egg(leather, IceUnitShapes.on(Vector3(0, -0.3, 1), hand), 0.07, 0.15, 6)
	IceUnitShapes.egg(frost, Transform3D(Basis.IDENTITY, lo + Vector3(0.10, 0.50, 0.30)), 0.10, 0.27, 6)


func _gc_leg(acc: Dictionary, sx: float) -> void:
	var x := G.x + 0.14 * sx
	ChampionShapes.tube(IceUnitShapes.st(acc, ice(&"ice_fur")), PackedVector3Array([Vector3(x, 0.52, G.z), Vector3(x, 0.31, G.z + 0.04),
		Vector3(x, 0.12, G.z)]), PackedFloat32Array([0.115, 0.10, 0.085]), 7, false)
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur_pale")), fur_ring(0.09, 0.125, 0.07, 3, 0.03),
		Transform3D(Basis.IDENTITY, Vector3(x, 0.12, G.z)))
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_leather")), boot(0.115, 0.15),
		IceUnitShapes.xf(Vector3(x, 0.0, G.z + 0.05), Vector3.ZERO, Vector3(1.0, 1.0, 1.4)))


func _gc_chest(acc: Dictionary) -> void:
	var cloth := IceUnitShapes.st(acc, ice(&"ice_cloth"))
	ChampionShapes.lathe(cloth, PackedVector2Array([Vector2(0.38, 0.50), Vector2(0.345, 0.62), Vector2(0.30, 0.82),
		Vector2(0.275, 0.97), Vector2(0.21, 1.08)]), 10, Transform3D(Basis.IDENTITY, G), 1.0, 0.9, false)
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur")), fur_ring(0.36, 0.41, 0.12, 5, 0.045),
		Transform3D(Basis.IDENTITY, G + Vector3(0, 0.47, 0)))
	ChampionShapes.band(IceUnitShapes.st(acc, ice(&"ice_leather")), 0.285, 0.07, 0.02, 10, Transform3D(Basis.IDENTITY, G + Vector3(0, 0.84, 0)),
		1.0, 0.9)
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur_pale")), fur_ring(0.18, 0.32, 0.13, 5, 0.035),
		Transform3D(Basis.IDENTITY, G + Vector3(0, 0.98, 0)))
	# dark tabard strip with a pointed hem down the front
	ChampionShapes.plate(IceUnitShapes.st(acc, ice(&"ice_cloth_dark")), PackedVector2Array([Vector2(-0.075, 0.16), Vector2(0.075, 0.16),
		Vector2(0.08, -0.15), Vector2(0.0, -0.23), Vector2(-0.08, -0.15)]), 0.03, 0.01,
		IceUnitShapes.xf(G + Vector3(0, 0.76, 0.285), Vector3(-12, 0, 0)))


func _gc_head(acc: Dictionary) -> void:
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_skin")), sphere(0.19, 10, 5), Transform3D(Basis.IDENTITY, G + Vector3(0, 1.20, 0.06)))
	ChampionShapes.tube(IceUnitShapes.st(acc, ice(&"ice_cloth")), PackedVector3Array([G + Vector3(0, 1.22, 0.12), G + Vector3(0, 1.27, -0.04),
		G + Vector3(0, 1.34, -0.21), G + Vector3(0, 1.45, -0.42)]), PackedFloat32Array([0.23, 0.25, 0.18, 0.0]), 8, false)
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur_pale")), fur_ring(0.20, 0.245, 0.06, 5, 0.025),
		Transform3D(Basis(Vector3.RIGHT, PI * 0.5), G + Vector3(0, 1.21, 0.11)))


func _gc_arm(acc: Dictionary, sx: float) -> void:
	var sh := G + Vector3(0.34 * sx, 1.02, 0)
	var hand := Vector3(G.x + 0.22 * sx, BAR_Y, BAR_Z - 0.07)
	var elbow := (sh + hand) * 0.5 + Vector3(0.08 * sx, -0.06, -0.05)
	ChampionShapes.tube(IceUnitShapes.st(acc, ice(&"ice_cloth")), PackedVector3Array([sh, elbow, hand]),
		PackedFloat32Array([0.095, 0.085, 0.07]), 6, false)
	var fd := (hand - elbow).normalized()
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur_pale")), fur_ring(0.07, 0.095, 0.06, 3, 0.025),
		IceUnitShapes.on(-fd, hand - fd * 0.03))
	IceUnitShapes.egg(IceUnitShapes.st(acc, ice(&"ice_leather")), IceUnitShapes.on(fd, hand + fd * 0.02), 0.095, 0.19, 6)


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

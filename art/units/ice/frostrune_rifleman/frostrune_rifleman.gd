class_name FrostruneRiflemanModel
extends "res://art/units/ice/shardcaster.gd"
## Frostrune Rifleman (tier3-extras.md 5 / 12, task 13b.V2): the Shardcaster's hooded caster turned sniper, built ON the
## Shardcaster (user Q3: "reuse what's already been made"). The scene inherits shardcaster.tscn (same 7 pivots) and
## this script extends shardcaster.gd: `super._build_parts()` builds the whole Shardcaster body (legs, team coat, belt,
## crystal left pauldron, quiver of 3 ice shards = rune slugs, face, team hood + pointed tip, vet trim, frost breath,
## shatter death, cool blob); then only the rod hands are replaced and two parts are restyled:
##   - the crystal rod, its arms and orbit shards are removed (ArmL / ArmR emptied before the merge);
##   - the pale fur collar becomes a big shaggy PALE FUR MANTLE with an ice-silver right pauldron (the stock side);
##   - an ice-silver visor band pushed up on the brow over its own painted face (the glow moves to the rifle).
## New: two bent arms holding a VERY LONG RUNE-ETCHED RIFLE level in front (2.0 m, longer than the 1.9 m body): dark
## wood stock and forestock with silver bands, a long ice-silver barrel with 3 glowing rune collars, a crystal muzzle
## crown, a dark steel scope with a crystal objective and a glowing lens, and a FOLDED ICE MONOPOD under the forestock.
## Glow points (spec): the 3 barrel runes + the scope lens (one own-glow mesh, flared by the aim and the shot).
## Read at 40 m: the Shardcaster's dark narrow body + pointed hood, a wide pale mantle, a long silver line forward
## (the Shardcaster's bright line is sideways); braced it is LOW (kneeling) with a leg of ice under the rifle.
##
## Hooks (plus every kit / Ice hook):
##   set_braced(on: bool)        1.0 s kneel on the right knee: the rifle comes to the shoulder, the monopod swings down
##                               and grows to the ground. Off = stands in 0.35 s. Moving always stands the model up.
##   set_status(&"braced", on)   the same (the Unit's display-only `braced` status); returns true (the model shows it).
##   is_braced() -> bool         the last set_braced value.  brace_amount() -> float  0 standing .. 1 fully braced.
##   play_aim(seconds: float)    Rime Lock aim: rifle to the eye, head down to the scope, the scope + runes charge up
##                               and pulse over `seconds`, a flare held until the shot; <= 0 cancels the aim.
##   is_aiming() -> bool
##   attack_style &"rifle_shot"  (attack_windup 0.10 = the crack): the rifle snaps to the shoulder (0.08 s), fires at
##                               0.10 (recoil: muzzle kicks 11 deg, the arms kick back, the chest rocks, frost motes at
##                               the muzzle, the runes + lens flare), lowers from 0.45 to 0.75 s unless braced / aiming.
##   play_cast(any id)           a short shouldered aim with a scope flare (e.g. &"rime_lock").
##   get_muzzle_position() -> Vector3, get_scope_position() -> Vector3 (world; the aim line / tracer origins),
##   get_beam_origin() -> Vector3 (= the muzzle, the Champion / ability convention).
##   authored_mesh_count() -> int (budget test).
## Idle fidget: brings the rifle up and checks the scope (a glint). Death: the Shardcaster's freeze-over + shatter.
## Budget (soldier, tier3-extras.md 12): 26 authored meshes (blob included), 14 draw instances (6 merged pivots,
## VetTrim, Rifle, Monopod, blob, 4 one-shot particle systems), 0 lights, Ice palette materials only.

const HOLD := &"rifle_hold"            # private kit action id: keeps the full pose path while braced / aiming
const BRACE_TIME := 1.0                # s, the kneel (spec)
const UNBRACE_TIME := 0.35             # s, standing up
const KNEEL_DROP := 0.36               # m the body drops when kneeling
const RIFLE_YAW := -12.0               # deg: the rifle's yaw in the body at rest (muzzle a little inward)
const CHEST_YAW := 12.0                # deg the body blades while shouldered (rifle straight forward)
const AIM_ARM := -40.0                 # deg both arms rise to bring the stock to the shoulder
const HEAD_AIM := 13.0                 # deg the head dips to the scope
const KICK_DEG := 11.0                 # deg muzzle climb at the shot
const FOLD_DEG := 90.0                 # deg: the monopod folded along the forestock
const MONO_LEN := 0.70                 # m, the deployed ice leg (hinge to foot tip)
const MONO_FOLDED := 0.58              # length factor while folded (the ice leg grows as it swings down)
const REST_GLOW := 1.0

# model space (feet origin, +Z face), rest pose
const SH_R := Vector3(0.31, 1.19, 0.0)
const EL_R := Vector3(0.37, 1.00, -0.06)
const GRIP_R := Vector3(0.17, 0.99, 0.17)      # right fist on the rifle's grip = the Rifle node origin
const SH_L := Vector3(-0.30, 1.19, 0.03)
const EL_L := Vector3(-0.20, 0.98, 0.21)
const HAND_S := 0.34                           # m along the barrel from the grip: the left hand on the forestock
# rifle space (origin = grip, +Z = barrel, +Y = up)
const MUZZLE := Vector3(0.0, 0.03, 1.55)
const SCOPE_LENS := Vector3(0.0, 0.115, 0.445)
const HINGE := Vector3(0.0, -0.065, 0.74)

static var _rf_cache: Dictionary = {}
static var _authored_static: int = 0

var _rifle: MeshInstance3D
var _mono: Node3D
var _rifle_b0: Basis = Basis.IDENTITY
var _braced: bool = false
var _brace_t: float = 0.0
var _kneel_w: float = 0.0
var _aim_left: float = 0.0
var _aim_total: float = 0.0
var _aim_w: float = 0.0
var _aim_charge: float = 0.0
var _att_sh: float = 0.0          # shoulder request of this frame's attack / cast pose
var _fid_sh: float = 0.0          # ... of the fidget
var _kick: float = 0.0            # recoil of this frame (0-1)
var _fast_frame: bool = false
var _glow_w: float = -1.0
var _rifle_rho: float = 999.0
var _mono_rot: float = 999.0
var _mono_len: float = -1.0
# IK constants (chest space)
var _g0: Vector3
var _h0: Vector3
var _dir0: Vector3


# ================================================================ hooks

func set_braced(on: bool) -> void:
	_braced = on
	set_process(true)


func is_braced() -> bool:
	return _braced


## 0 standing .. 1 kneeling with the rifle on the monopod.
func brace_amount() -> float:
	return clampf(_brace_t / BRACE_TIME, 0.0, 1.0)


func play_aim(seconds: float) -> void:
	if _dead:
		return
	if seconds <= 0.0:
		_aim_left = 0.0
		return
	_aim_left = seconds
	_aim_total = seconds
	_aim_charge = 0.0
	set_process(true)


func is_aiming() -> bool:
	return _aim_left > 0.0


func set_status(id: StringName, on: bool) -> bool:
	if id == &"braced":
		set_braced(on)
		return true
	return super.set_status(id, on)


func get_muzzle_position() -> Vector3:
	if _rifle and _rifle.is_inside_tree():
		return _rifle.global_transform * MUZZLE
	return global_position + Vector3(0, 1.0, 1.4)


func get_scope_position() -> Vector3:
	if _rifle and _rifle.is_inside_tree():
		return _rifle.global_transform * SCOPE_LENS
	return global_position + Vector3(0, 1.1, 0.6)


func get_beam_origin() -> Vector3:
	return get_muzzle_position()


func authored_mesh_count() -> int:
	return _authored_static


# ================================================================ build

## Face (faces pass 2026-09-28): a weathered marksman, steel-grey fringe and stubble-grey moustache, cold grey eyes
## (no iris glow: the rifle holds the glow).
func _face_key() -> String:
	return "frostrune_rifleman"


func _face_spec() -> Dictionary:
	var hair := Color(0.52, 0.55, 0.60)
	var tip := Color(0.72, 0.76, 0.82)
	return {"center": Vector3(0, 1.40, 0.03), "radius": 0.16, "head_mesh": sphere(0.16), "preset": &"stern",
		"detail": &"low", "skin": ICE_SKIN, "hair": hair, "hair_tip": tip, "eyes": Color(0.46, 0.54, 0.62), "ears": &"none",
		"beard": &"moustache", "palette": {"brow": Color(0.30, 0.32, 0.36)}, "eye": {"c": Vector2(0.056, 0.006)},
		"mouth": {"c": Vector2(0.0, -0.068), "hw": 0.032},
		"hair_fn": func(acc: Dictionary) -> void: UnitFaces.hood_fringe(acc, Vector3(0, 1.40, 0.03), 0.16, hair, tip, 1.0)}


func _build_parts() -> void:
	var first: bool = not _merged.has(_type_key + "|Root/Chest")
	super._build_parts()   # the whole Shardcaster (see the header)
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	# 1. The rod, its hands and the orbit shards go (everything the Shardcaster hung on the arms).
	for arm: Node3D in [arm_l, arm_r]:
		for c: Node in arm.get_children():
			arm.remove_child(c)
			c.free()
	_tip = null
	_spin = null
	_burst = null
	# 2. Restyle (first build only: later instances get the cached merge).
	for c: Node in chest.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_override == ice(&"ice_fur_pale"):
			var mi := c as MeshInstance3D
			mi.mesh = _mantle_mesh()
			mi.material_override = null
			mi.position = -model_origin(chest)
			mi.rotation = Vector3.ZERO
	# The Shardcaster's glowing eye slit is gone (faces pass 2026-09-28: a painted face): the ice-silver visor band now
	# sits pushed up on the brow, over the hood edge, above the rifleman's own face (_face_spec below).
	add_part(head, _visor_mesh(), ice(&"ice_metal"), Vector3.ZERO)
	# 3. Arms (one merged mesh each: sleeve, forearm, glove) and the rifle (own glow, keeps its pitch level).
	add_part(arm_r, _arm_mesh(true), null, Vector3.ZERO)
	add_part(arm_l, _arm_mesh(false), null, Vector3.ZERO)
	_rifle = add_part(arm_r, _rifle_mesh(), null, GRIP_R, Vector3(0, RIFLE_YAW, 0), Vector3.ONE, true, "Rifle")
	_rifle.set_meta(&"own_glow", true)
	_rifle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_rifle_b0 = _rifle.basis
	_mono = Node3D.new()
	_mono.name = "Monopod"
	_mono.set_meta(&"keep_separate", true)
	_mono.position = HINGE
	_rifle.add_child(_mono)
	var leg := MeshInstance3D.new()
	leg.name = "IceLeg"
	leg.mesh = _monopod_mesh()
	leg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mono.add_child(leg)
	_mono.rotation = Vector3(FOLD_DEG * DEG, 0, 0)
	_mono.scale = Vector3(1.0, MONO_FOLDED, 1.0)
	# The Shardcaster's release burst, moved to the muzzle (reuses its _burst / _flare / release event).
	_burst = make_motes(ICE_GLOW, 10, 0.32, 0.05, 3.2, 0.08, false, true)
	_burst.name = "MuzzleBurst"
	_burst.position = MUZZLE + Vector3(0, 0, 0.06)
	_rifle.add_child(_burst)
	if first:
		_authored_static = _count_meshes(self)


static func _count_meshes(n: Node) -> int:
	var k := 0
	for c: Node in n.get_children():
		if c is MeshInstance3D or c is MultiMeshInstance3D:
			k += 1
		k += _count_meshes(c)
	return k


func _ice_ready() -> void:
	var co := model_origin($Root/Chest)
	_dir0 = _rifle_b0 * Vector3(0, 0, 1)
	_g0 = GRIP_R - co
	_h0 = _g0 + _dir0 * HAND_S
	_glow_w = -1.0
	_write_rifle(0.0, 0.0, MONO_FOLDED)


# ================================================================ meshes (static, built once per game)

static func _xf(p: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * DEG) * Basis.from_scale(scl), p)


## Transform that turns a primitive's +Y axis along d, centred at c.
static func _along(c: Vector3, d: Vector3) -> Transform3D:
	return Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), c)


static func _limb_items(items: Array, a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var d := b - a
	items.append([capsule(r, d.length() + r * 1.4), _along(a + d * 0.5, d), [mat]])


## G-C leftovers (2026-10-15, docs/art/gc_leftovers.md): the arms, the mantle and the rifle are built from smooth tubes,
## lathes, fur rings and bevelled side-profile plates (ChampionShapes / IceUnitShapes) instead of capsules and boxes; the
## model drops from 3317 to ~2300 vertices (soldier budget 2500) while the stock, grip and forestock get real outlines.
## Items for _merge_items from {Material: SurfaceTool} (one committed mesh per material).
static func _acc_items(acc: Dictionary) -> Array:
	var items: Array = []
	for m: Material in acc:
		items.append([ChampionShapes.commit(acc[m]), Transform3D.IDENTITY, [m]])
	return items


static func _arm_mesh(right: bool) -> Mesh:
	var key := "arm_r_v2" if right else "arm_l_v2"
	if _rf_cache.has(key):
		return _rf_cache[key]
	var s := SH_R if right else SH_L
	var e := EL_R if right else EL_L
	var h := GRIP_R if right else GRIP_R + Basis(Vector3.UP, RIFLE_YAW * DEG) * Vector3(0, 0, HAND_S)
	var acc: Dictionary = {}
	# sleeve with the elbow bend, forearm narrowing to the wrist
	IceUnitShapes.limb(IceUnitShapes.st(acc, ice(&"ice_cloth_dark")), s, e, h, 0.086, 0.08, 0.068, 7)
	var fd := (h - e).normalized()
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur_pale")), fur_ring(0.078, 0.104, 0.085, 4, 0.03),
		IceUnitShapes.on(-fd, e.lerp(h, 0.66)))
	IceUnitShapes.egg(IceUnitShapes.st(acc, ice(&"ice_leather")), IceUnitShapes.on(fd, h - fd * 0.02), 0.088, 0.19, 7)
	var m := _merge_items(_acc_items(acc))
	_rf_cache[key] = m
	return m


## The Shardcaster's pale collar, made a big shaggy fur mantle (a jagged fur ring) + an ice-silver right pauldron (a
## flattened dome over a rolled lame) and a silver diamond clasp (model space).
static func _mantle_mesh() -> Mesh:
	if _rf_cache.has("mantle_v2"):
		return _rf_cache["mantle_v2"]
	var acc: Dictionary = {}
	ChampionShapes.append(IceUnitShapes.st(acc, ice(&"ice_fur_pale")), fur_ring(0.15, 0.38, 0.17, 9, 0.05, 1.0, 0.95),
		Transform3D(Basis.IDENTITY, Vector3(0, 1.125, -0.03)))
	var metal := IceUnitShapes.st(acc, ice(&"ice_metal"))
	var sh := IceUnitShapes.xf(Vector3(0.33, 1.25, 0.0), Vector3(0, 0, -18))
	ChampionShapes.lathe(metal, PackedVector2Array([Vector2(0.145, -0.03), Vector2(0.135, 0.03), Vector2(0.09, 0.075),
		Vector2(0.0, 0.09)]), 8, sh * Transform3D(Basis.from_scale(Vector3(1.0, 0.9, 1.12)), Vector3.ZERO), 1.0, 1.0, false)
	ChampionShapes.lame(metal, 0.16, 0.145, -0.10, -0.03, PI * 0.5 - 1.5, PI * 0.5 + 1.5, 5, 0.015, sh, 1.0, 1.12)
	ChampionShapes.plate(metal, PackedVector2Array([Vector2(0.0, 0.055), Vector2(0.05, 0.0), Vector2(0.0, -0.055),
		Vector2(-0.05, 0.0)]), 0.03, 0.012, IceUnitShapes.xf(Vector3(0, 1.21, 0.25), Vector3(-15, 0, 0)))
	var m := _merge_items(_acc_items(acc))
	_rf_cache["mantle_v2"] = m
	return m


## The visor band pushed up on the brow: a rolled silver lame round the front of the hood (model space).
static func _visor_mesh() -> Mesh:
	return IceUnitShapes.mesh("fr_gc_visor", func(st: SurfaceTool) -> void:
		ChampionShapes.lame(st, 0.172, 0.165, -0.028, 0.028, -1.0, 1.0, 6, 0.016,
			IceUnitShapes.xf(Vector3(0, 1.475, 0.035), Vector3(-18, 0, 0)), 1.0, 1.0))


## Side-profile plate in rifle space: outline (z, y), thickness along X, bevelled both sides.
static func _side(st: SurfaceTool, outline: PackedVector2Array, thick: float, bevel: float) -> void:
	ChampionShapes.plate(st, outline, thick, bevel, Transform3D(Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0)),
		Vector3.ZERO), true)


## The rune rifle in rifle space: grip at the origin, barrel along +Z (2.0 m butt to muzzle crown).
static func _rifle_mesh() -> Mesh:
	if _rf_cache.has("rifle_v2"):
		return _rf_cache["rifle_v2"]
	var acc: Dictionary = {}
	var wood := IceUnitShapes.st(acc, ice(&"ice_wood"))
	var metal := IceUnitShapes.st(acc, ice(&"ice_metal"))
	var steel := IceUnitShapes.st(acc, ice(&"ice_steel"))
	var crystal := IceUnitShapes.st(acc, ice(&"ice_frost_crystal"))
	var glow := IceUnitShapes.st(acc, ice(&"ice_glow_unit"))
	var leather := IceUnitShapes.st(acc, ice(&"ice_leather"))
	var zf := Basis(Vector3.RIGHT, PI * 0.5)   # a lathe's +Y along +Z
	# stock in one outline: dropping butt with a toe, a raised comb, the slim wrist, the pistol grip
	_side(wood, PackedVector2Array([Vector2(-0.45, 0.045), Vector2(-0.21, 0.065), Vector2(-0.07, 0.042), Vector2(0.03, 0.04),
		Vector2(0.03, -0.04), Vector2(0.05, -0.06), Vector2(0.025, -0.165), Vector2(-0.035, -0.155), Vector2(-0.07, -0.065),
		Vector2(-0.26, -0.11), Vector2(-0.45, -0.155)]), 0.075, 0.016)
	ChampionShapes.append(metal, soft_box(Vector3(0.085, 0.21, 0.025)), IceUnitShapes.xf(Vector3(0, -0.055, -0.457), Vector3(-3, 0, 0)))
	ChampionShapes.append(leather, soft_box(Vector3(0.082, 0.035, 0.15)), IceUnitShapes.xf(Vector3(0, 0.07, -0.21), Vector3(-4, 0, 0)))
	# receiver with two silver bands, the forestock (tapered nose) with its silver cap, the monopod clamp
	ChampionShapes.append(steel, soft_box(Vector3(0.085, 0.11, 0.30)), Transform3D(Basis.IDENTITY, Vector3(0, 0.02, 0.17)))
	for z: float in [0.03, 0.31]:
		ChampionShapes.append(metal, soft_box(Vector3(0.10, 0.125, 0.035)), Transform3D(Basis.IDENTITY, Vector3(0, 0.02, z)))
	_side(wood, PackedVector2Array([Vector2(0.32, 0.032), Vector2(0.745, 0.03), Vector2(0.775, 0.008), Vector2(0.765, -0.045),
		Vector2(0.42, -0.058), Vector2(0.32, -0.052)]), 0.078, 0.014)
	ChampionShapes.band(metal, 0.036, 0.04, 0.014, 6, Transform3D(zf, Vector3(0, -0.005, 0.765)), 1.15, 1.25)
	ChampionShapes.append(steel, soft_box(Vector3(0.05, 0.035, 0.06)), Transform3D(Basis.IDENTITY, Vector3(0, -0.055, 0.74)))
	# the long ice-silver barrel, 3 glowing rune collars, the crystal muzzle crown (a flared cup and three prongs)
	ChampionShapes.tube(metal, PackedVector3Array([Vector3(0, 0.03, 0.30), Vector3(0, 0.03, 1.46)]), PackedFloat32Array([0.034, 0.03]),
		7, false)
	for z: float in [0.90, 1.11, 1.32]:
		ChampionShapes.band(glow, 0.031, 0.055, 0.015, 6, Transform3D(zf, Vector3(0, 0.03, z)))
	ChampionShapes.lathe(crystal, PackedVector2Array([Vector2(0.036, 0.0), Vector2(0.058, 0.12)]), 6,
		Transform3D(zf, Vector3(0, 0.03, 1.41)), 1.0, 1.0, false, 0.0, TAU, true)
	for k: int in 3:
		var a: float = TAU * float(k) / 3.0 + 0.5
		var d := Vector3(cos(a) * 0.45, sin(a) * 0.45, 1.0).normalized()
		var b := Vector3(0, 0.03, 1.52) + Vector3(cos(a), sin(a), 0) * 0.045
		ChampionShapes.tube(crystal, PackedVector3Array([b, b + d * 0.13]), PackedFloat32Array([0.022, 0.0]), 4, true)
	# scope: two mounts, the dark tube with an ocular bell, the crystal objective, the glowing lens
	for z: float in [0.07, 0.28]:
		ChampionShapes.append(steel, soft_box(Vector3(0.03, 0.06, 0.035)), Transform3D(Basis.IDENTITY, Vector3(0, 0.085, z)))
	ChampionShapes.lathe(steel, PackedVector2Array([Vector2(0.03, -0.07), Vector2(0.045, -0.035), Vector2(0.035, -0.0),
		Vector2(0.033, 0.36)]), 7, Transform3D(zf, Vector3(0, 0.115, -0.0)), 1.0, 1.0, true)
	ChampionShapes.lathe(crystal, PackedVector2Array([Vector2(0.036, 0.0), Vector2(0.062, 0.08)]), 6,
		Transform3D(zf, Vector3(0, 0.115, 0.355)), 1.0, 1.0, false, 0.0, TAU, true)
	ChampionShapes.lathe(glow, PackedVector2Array([Vector2(0.052, 0.0), Vector2(0.052, 0.018)]), 6,
		Transform3D(zf, Vector3(0, 0.115, 0.43)), 1.0, 1.0, true)
	var m := _merge_items(_acc_items(acc))
	_rf_cache["rifle_v2"] = m
	return m


## The folded ice monopod: a silver knuckle at the hinge, a hexagonal ice leg hanging along -Y, a crystal foot spike.
static func _monopod_mesh() -> Mesh:
	if _rf_cache.has("mono"):
		return _rf_cache["mono"]
	var metal := ice(&"ice_metal")
	var crystal := ice(&"ice_frost_crystal")
	var items: Array = []
	items.append([cyl(0.032, 0.032, 0.07, 6), _xf(Vector3.ZERO, Vector3(0, 0, 90)), [metal]])
	items.append([cyl(0.036, 0.036, 0.05, 6), _xf(Vector3(0, -0.06, 0)), [metal]])
	items.append([cyl(0.026, 0.034, MONO_LEN - 0.17, 6), _xf(Vector3(0, -0.06 - (MONO_LEN - 0.17) * 0.5, 0)), [crystal]])
	items.append([cyl(0.0, 0.05, 0.12, 6), _xf(Vector3(0, -MONO_LEN + 0.06, 0), Vector3(180, 0, 0)), [crystal]])
	var m := _merge_items(items)
	_rf_cache["mono"] = m
	return m


# ================================================================ animation

func _idle_fast() -> void:
	super._idle_fast()
	_fast_frame = true


## rifle_shot (others: the kit). Rifle to the shoulder by 0.08, the crack at attack_windup (0.10), recoil, lowered by
## 0.75 unless braced / aiming (the shoulder weight is the max of all requests).
func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"rifle_shot":
		return super._pose_attack(prev, t)
	var rel: float = attack_windup if attack_windup > 0.0 else 0.10
	var length := 0.75
	_att_sh = maxf(_att_sh, _k3(t, 0.0, minf(0.08, rel * 0.8), 0.45, length, 1.0, 1.0))
	var k := _k3(t, rel, rel + 0.025, rel + 0.05, rel + 0.42, 1.0, 0.75)
	_kick = maxf(_kick, k)
	rot(P_CHEST, Vector3(-5.0 * DEG * k, 3.0 * DEG * k, 0))
	rot(P_HEAD, Vector3(-6.0 * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, 0, -0.035 * k * (1.0 - _kneel_w)))
	if prev < rel and t >= rel:
		_on_action_event(&"release")
	return t < length


## Any cast (e.g. rime_lock): a short shouldered aim with a scope flare.
func _pose_cast(_spell: StringName, t: float) -> float:
	_att_sh = maxf(_att_sh, _k3(t, 0.0, 0.1, 0.45, 0.6, 1.0, 1.0))
	_flare = maxf(_flare, 0.5 * _k3(t, 0.05, 0.2, 0.3, 0.6, 1.0, 1.0))
	return 0.6


## Fidget: brings the rifle up and looks through the scope; the lens glints.
func _pose_fidget(t: float) -> float:
	var k := _k3(t, 0.0, 0.35, 1.1, 1.6, 1.0, 1.0)
	_fid_sh = maxf(_fid_sh, k)
	_flare = maxf(_flare, 0.35 * _k3(t, 0.5, 0.7, 0.8, 1.1, 1.0, 1.0))
	return 1.6


func _ice_process(dt: float) -> void:
	var fast := _fast_frame
	_fast_frame = false
	# ---- state
	var want: bool = _braced and _speed < 0.3 and not _dead
	if not _dead:
		if want:
			_brace_t = minf(BRACE_TIME, _brace_t + dt)
		else:
			_brace_t = maxf(0.0, _brace_t - dt * BRACE_TIME / UNBRACE_TIME)
	if _aim_left > 0.0:
		_aim_left = maxf(0.0, _aim_left - dt)
		_aim_charge = 1.0 - _aim_left / maxf(_aim_total, 0.01)
		if _dead or _speed >= 0.3:
			_aim_left = 0.0
	var aiming: bool = _aim_left > 0.0
	_aim_w = move_toward(_aim_w, 1.0 if aiming else 0.0, dt / (0.2 if aiming else 0.35))
	if _aim_w <= 0.0:
		_aim_charge = 0.0
	_flare = maxf(0.0, _flare - dt / 0.3)
	var b := _brace_t / BRACE_TIME
	_kneel_w = smoothstep(0.0, 0.55, b)
	var sh_b := smoothstep(0.3, 0.8, b)
	var mono := smoothstep(0.55, 1.0, b)
	var grow := smoothstep(0.7, 1.0, b)
	var sh := maxf(maxf(sh_b, _aim_w), maxf(_att_sh, _fid_sh))
	var kick := _kick
	var fid := _fid_sh
	_att_sh = 0.0
	_fid_sh = 0.0
	_kick = 0.0
	# ---- pose (full-path frames only: the kit's fast idle ignores offsets and the arms are at rest)
	if fast:
		_write_rifle(0.0, 0.0, MONO_FOLDED)
	elif not _dead:
		var kn := _kneel_w
		var lean: float = 4.0 * kn + 5.0 * sh
		var yaw: float = CHEST_YAW * sh
		rot(P_CHEST, Vector3(lean * DEG, yaw * DEG, 0))
		rot(P_HEAD, Vector3((HEAD_AIM * maxf(_aim_w, maxf(sh_b * 0.6, fid)) - lean * 0.6) * DEG, -yaw * DEG, 0))
		pos(P_ROOT, Vector3(0, -KNEEL_DROP * kn, 0.04 * kn))
		rot(P_LEG_L, Vector3(-58.0 * DEG * kn, 0, -5.0 * DEG * kn))
		rot(P_LEG_R, Vector3(66.0 * DEG * kn, 0, 6.0 * DEG * kn))
		rot(P_ARM_R, Vector3((AIM_ARM * sh - lean) * DEG, 0, 0))
		# on the monopod the rifle kicks less (40 % climb, half the push back)
		pos(P_ARM_R, Vector3(0, 0, -0.07 * kick * lerpf(1.0, 0.5, mono)))
		if _walk_w > 0.0:
			rot(P_ARM_R, Vector3(-4.0 * DEG * _walk_w, 0, 0))   # carry a little higher while walking
		var counter: float = lerpf(0.75, 1.0, sh)
		var a_r: float = _off_rot[P_ARM_R].x
		var kick_a: float = KICK_DEG * DEG * kick * lerpf(1.0, 0.4, mono)
		var rho: float = -(a_r + _off_rot[P_CHEST].x) * counter - kick_a
		_solve_left_hand(a_r, rho)
		_write_rifle(rho, mono, lerpf(MONO_FOLDED, 1.0, grow), kick_a)
	# ---- glow: runes + scope lens
	if _rifle:
		var pulse: float = 0.0
		if _aim_w > 0.0 and _tier == 0:
			pulse = 0.4 * sin(_t * 17.0) * _aim_charge
		var g: float = glow_level() * (REST_GLOW + (2.2 * _aim_charge + pulse) * _aim_w + 2.6 * _flare)
		if absf(g - _glow_w) > 0.005 or (g == 0.0 and _glow_w != 0.0):
			_glow_w = g
			_rifle.set_instance_shader_parameter(&"glow_boost", g)
	# ---- keep the full pose path while braced / aiming
	var hold: bool = not _dead and (_brace_t > 0.0 or _aim_w > 0.0 or aiming)
	if hold and _action == &"":
		_action = HOLD
		_action_t = 0.0
	elif not hold and _action == HOLD:
		_action = &""
		_force_write = true


## The rifle's pitch in its arm (rho, rad; keeps it level against the arm / chest rotation), the monopod deploy
## (0 folded along the forestock .. 1 straight down) and its length factor; kick_a (rad, the muzzle climb) keeps the
## deployed leg vertical and stretches it so the foot stays planted while the hinge rises.
func _write_rifle(rho: float, deploy: float, length: float, kick_a: float = 0.0) -> void:
	if _rifle and absf(rho - _rifle_rho) > 0.0001:
		_rifle_rho = rho
		_rifle.basis = Basis(Vector3.RIGHT, rho) * _rifle_b0
	if _mono:
		length += deploy * HINGE.z * sin(kick_a) / MONO_LEN
		var r: float = FOLD_DEG * DEG * (1.0 - deploy) + kick_a * deploy
		if absf(r - _mono_rot) > 0.0001:
			_mono_rot = r
			_mono.rotation = Vector3(r, 0, 0)
		if absf(length - _mono_len) > 0.0001:
			_mono_len = length
			_mono.scale = Vector3(1.0, length, 1.0)


## Keeps the left glove on the forestock: ArmL gets the X rotation (about its shoulder) that puts the hand on the
## rifle's line (y-z plane of the chest; the hand may slide a little along the forestock), and ArmR's position offset.
func _solve_left_hand(a_r: float, rho: float) -> void:
	var p: Vector3 = _off_pos[P_ARM_R]
	var pr: Vector3 = _rest_pos[P_ARM_R]
	var pl: Vector3 = _rest_pos[P_ARM_L]
	var rx := Basis(Vector3.RIGHT, a_r)
	var g := pr + p + rx * (_g0 - pr)
	var d := Basis(Vector3.RIGHT, a_r + rho) * _dir0
	var c := pl + p
	var h := _h0 - pl
	var r2: float = h.y * h.y + h.z * h.z
	# |g + s d - c|^2 = r^2 in (y, z)
	var oy: float = g.y - c.y
	var oz: float = g.z - c.z
	var qa: float = d.y * d.y + d.z * d.z
	var qb: float = 2.0 * (oy * d.y + oz * d.z)
	var qc: float = oy * oy + oz * oz - r2
	var disc: float = qb * qb - 4.0 * qa * qc
	var s: float
	if disc >= 0.0 and qa > 0.0001:
		var sq := sqrt(disc)
		var s1: float = (-qb + sq) / (2.0 * qa)
		var s2: float = (-qb - sq) / (2.0 * qa)
		s = s1 if absf(s1 - HAND_S) < absf(s2 - HAND_S) else s2
	else:
		s = -qb / (2.0 * maxf(qa, 0.0001))
	s = clampf(s, HAND_S - 0.22, HAND_S + 0.30)
	var qy: float = oy + s * d.y
	var qz: float = oz + s * d.z
	var beta: float = wrapf(atan2(qz, qy) - atan2(h.z, h.y), -PI, PI)
	_off_rot[P_ARM_L] = Vector3(beta, 0, 0)
	_off_pos[P_ARM_L] = p


func _ice_revive() -> void:
	super._ice_revive()
	_braced = false
	_brace_t = 0.0
	_kneel_w = 0.0
	_aim_left = 0.0
	_aim_w = 0.0
	_aim_charge = 0.0
	_att_sh = 0.0
	_fid_sh = 0.0
	_kick = 0.0
	_glow_w = -1.0
	_rifle_rho = 999.0
	_mono_rot = 999.0
	_mono_len = -1.0
	_write_rifle(0.0, 0.0, MONO_FOLDED)

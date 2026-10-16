class_name HollowKingArt
extends RefCounted
## The Hollow King's own look (campaign review 2026-10-16, e8m3; mission-e8-03.md 4.1 "Look"): Obren's last body, a
## king of the buried throne-hall's stone, dressed OVER the Rime Colossus model the mission spawns him on (x 2.2).
## `HollowKingArt.dress(unit)` hides every Colossus draw (ice body, core, cracks, frost fx) and builds, on the same
## animated pivots (walk / slam / hit / death still play):
##   * a BROKEN CROWN of pale stone on a sunken head (7 points, three of them snapped stumps) - the top-down read;
##   * a broken ROSE WINDOW for a face over a gap of amber light (5 of 8 spokes left);
##   * an OPEN CHEST CAGE of rib pillars round a black hollow, the HOLLOW THRONE inside it with the heart-stone's
##     amber twin glowing behind it and an amber rim round the hollow (the strongest light on the body);
##   * vault shoulders, pillar limbs, plinth feet, a RAGGED MANTLE (torn hem, double-sided) and a torn skirt;
##   * FOUR HANGING CHAINS of light from wrist / ankle shackles, dragging on the ground, one per Key-Ward:
##     A1 right arm, A2 left arm, B1 left leg, B2 right leg (mission-e8-03.md 2), coloured per seat kingdom with
##     `set_chain_color(unit, limb, colour)`; `set_chain_broken(unit, limb, on)` swaps a chain for a snapped stub.
## Hollow palette (warden stone / amber, the Wardens' own family), never ice-blue.
## Cost: one merged mesh per pivot (a surface per material) + one node per chain; collision, HP and gameplay untouched
## (only GeometryInstance3D visibility on the model). Graphics tiers: Low = the static parts only (no extra effects);
## Medium+ add one amber ember emitter rising out of the hollow (VfxCap-fitted, paused off-screen by the kit).
## A real model later: set `model_scene` (or drop a scene at REAL_MODEL_PATH): dress() then hides the Colossus and
## instances it under the model's Root instead of the code-built parts.
## Model scene for the Art Lab / shots / a UnitType later: hollow_king.tscn (the Colossus scene + hollow_king_model.gd).

const DRESSED := &"_hollow_king"            # meta on the model (leading _: never saved)
const REAL_MODEL_PATH := "res://art/units/titans/hollow_king/hollow_king_real.tscn"
const LIMBS: Array[StringName] = [&"arm_r", &"arm_l", &"leg_l", &"leg_r"]
const LIMB_PIVOT := {&"arm_r": "Root/Chest/ArmR", &"arm_l": "Root/Chest/ArmL", &"leg_l": "Root/Hips/LegL",
	&"leg_r": "Root/Hips/LegR"}
## Placeholder chain colours (the four kingdoms) until the mission paints each with its seat's kingdom.
const DEFAULT_CHAIN_COLORS := {&"arm_r": Color(1.0, 0.35, 0.15), &"arm_l": Color(0.62, 0.30, 0.95),
	&"leg_l": Color(0.45, 0.75, 1.0), &"leg_r": Color(0.40, 0.90, 0.35)}
const AMBER := Color(1.0, 0.62, 0.22)
const PAINTED := "res://art/units/kit/unit_painted.gdshader"
const GLOW := "res://art/units/kit/unit_glow.gdshader"
const NOISE := "res://art/shaders/paint_noise.tres"
## Pivots that get a merged mesh, and the ones whose mesh casts a shadow (the kit's rule: chest / head / right arm).
const PIVOTS: Array[String] = ["Root/Hips", "Root/Hips/LegL", "Root/Hips/LegR", "Root/Chest", "Root/Chest/Head",
	"Root/Chest/ArmL", "Root/Chest/ArmR"]
const SHADOW_PIVOTS: Array[String] = ["Root/Chest", "Root/Chest/Head", "Root/Chest/ArmR", "Root/Chest/ArmL"]
const CHAIN_ENERGY := 1.9
const CHAIN_BROKEN_ENERGY := 0.5

## A real model for the King (null = the code-built parts). Also read from REAL_MODEL_PATH when that file exists.
static var model_scene: PackedScene
## Test / shot hook: >= 0 forces the graphics tier dress() reads (else GameSettings.effective_graphics_quality()).
static var quality_override: int = -1

static var _mats: Dictionary = {}           # key -> shared Material
static var _meshes: Dictionary = {}         # pivot path / chain key -> merged Mesh


# ================================================================ public API

## Dresses `unit` (a Unit built on the Rime Colossus model, or the model itself) as the Hollow King. Safe to call
## before the unit / model is ready (it waits for ready) and more than once (the second call does nothing).
## `chain_colors` (optional): limb (&"arm_r" / &"arm_l" / &"leg_l" / &"leg_r") -> colour.
static func dress(unit: Node3D, chain_colors: Dictionary = {}) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	if unit is CharacterModel:
		dress_model(unit, chain_colors)
		return
	var m := _model_of(unit)
	if m == null:
		if not unit.is_node_ready():
			unit.ready.connect(func() -> void: dress(unit, chain_colors), CONNECT_ONE_SHOT)
		return
	dress_model(m, chain_colors)


## Same on the model node directly (hollow_king_model.gd calls it from its own ready).
static func dress_model(m: Node3D, chain_colors: Dictionary = {}) -> void:
	if m == null or not is_instance_valid(m) or m.has_meta(DRESSED):
		return
	if m.get_node_or_null(^"Root/Chest") == null:
		return
	if m.get_node_or_null(^"Root/Chest/Merged") == null and not m.is_node_ready():
		m.ready.connect(func() -> void: dress_model(m, chain_colors), CONNECT_ONE_SHOT)
		return
	m.set_meta(DRESSED, true)
	_hide_colossus(m)
	var real := model_scene
	if real == null and ResourceLoader.exists(REAL_MODEL_PATH):
		real = load(REAL_MODEL_PATH) as PackedScene
	if real != null:
		var r := real.instantiate() as Node3D
		if r:
			r.name = "HollowKingModel"
			(m.get_node(^"Root") as Node3D).add_child(r)
		return
	var bh: float = float(m.get(&"body_height")) if &"body_height" in m else 2.6
	var detail: float = CharacterModel.detail_tier()
	for path: String in PIVOTS:
		var piv := m.get_node_or_null(path) as Node3D
		if piv == null:
			continue
		var mesh := _pivot_mesh(m, path)
		if mesh == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = "HollowKing"
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if SHADOW_PIVOTS.has(path) \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.set_instance_shader_parameter(&"ao_height", bh)
		mi.set_instance_shader_parameter(&"kit_detail", detail)
		piv.add_child(mi)
	for limb: StringName in LIMBS:
		var piv := m.get_node_or_null(String(LIMB_PIVOT[limb])) as Node3D
		if piv == null:
			continue
		var c := MeshInstance3D.new()
		c.name = "HKChain_" + String(limb)
		c.mesh = _chain_mesh(m, limb, false)
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piv.add_child(c)
		set_chain_color(m, limb, chain_colors.get(limb, DEFAULT_CHAIN_COLORS[limb]))
	if _quality() >= 1:
		_add_embers(m)
	if m.has_method(&"refresh_emitter_cache"):
		m.call(&"refresh_emitter_cache")


## True once dress() ran on this unit / model.
static func is_dressed(unit: Node3D) -> bool:
	var m := unit if unit is CharacterModel else _model_of(unit)
	return m != null and m.has_meta(DRESSED)


## Paints one chain (limb = &"arm_r" / &"arm_l" / &"leg_l" / &"leg_r"), e.g. with its Key-Ward seat's kingdom colour.
static func set_chain_color(unit: Node3D, limb: StringName, c: Color) -> void:
	var n := chain_node(unit, limb)
	if n == null:
		return
	var col := Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0))
	n.set_meta(&"_color", col)
	n.material_override = _chain_mat(limb, col, bool(n.get_meta(&"_broken", false)))


## A broken chain (its Key-Ward at 0 HP): a short dim stub hangs from the shackle; false = rebound.
static func set_chain_broken(unit: Node3D, limb: StringName, broken: bool) -> void:
	var n := chain_node(unit, limb)
	if n == null:
		return
	var m := unit if unit is CharacterModel else _model_of(unit)
	n.mesh = _chain_mesh(m, limb, broken)
	n.set_meta(&"_broken", broken)
	n.material_override = _chain_mat(limb, n.get_meta(&"_color", DEFAULT_CHAIN_COLORS[limb]) as Color, broken)


## The chain node of a limb (null when the unit is not dressed).
static func chain_node(unit: Node3D, limb: StringName) -> MeshInstance3D:
	if unit == null or not LIMB_PIVOT.has(limb):
		return null
	var m := unit if unit is CharacterModel else _model_of(unit)
	if m == null:
		return null
	return m.get_node_or_null(String(LIMB_PIVOT[limb]) + "/HKChain_" + String(limb)) as MeshInstance3D


# ================================================================ internals

static func _model_of(unit: Node3D) -> Node3D:
	if unit == null or not is_instance_valid(unit):
		return null
	if unit.has_method(&"get_model"):
		return unit.call(&"get_model") as Node3D
	return null


static func _quality() -> int:
	return quality_override if quality_override >= 0 else GameSettings.effective_graphics_quality()


## Hides every Colossus draw on the model except the ground blob; the slam ring stays (re-tinted amber).
static func _hide_colossus(m: Node3D) -> void:
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if gi.name == &"Shadow" and gi.get_parent() == m:
			continue
		if gi.name == &"SlamRing" and gi is MeshInstance3D:
			gi.material_override = _ring_mat((gi as MeshInstance3D).mesh)
			continue
		gi.visible = false


static func _ring_mat(mesh: Mesh) -> Material:
	if _mats.has(&"ring"):
		return _mats[&"ring"]
	var src: BaseMaterial3D = null
	if mesh is PrimitiveMesh:
		src = (mesh as PrimitiveMesh).material as BaseMaterial3D
	var r: StandardMaterial3D = (src.duplicate() as StandardMaterial3D) if src is StandardMaterial3D else StandardMaterial3D.new()
	r.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	r.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	r.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	r.disable_fog = true
	r.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	r.albedo_color = Color(1.0, 0.70, 0.32, 1.0)   # no HDR albedo (VfxCap)
	_mats[&"ring"] = r
	return r


static func _painted(key: StringName, base: Color, crack: float = 0.0, spec: float = 0.0, kind: int = 7) -> Material:
	if _mats.has(key):
		return _mats[key]
	var sm := ShaderMaterial.new()
	sm.resource_name = "hk_" + String(key)
	sm.shader = load(PAINTED)
	sm.set_shader_parameter(&"base_color", base)
	sm.set_shader_parameter(&"noise_tex", load(NOISE))
	sm.set_shader_parameter(&"spec_strength", spec)
	sm.set_shader_parameter(&"rim_strength", 0.25)
	sm.set_shader_parameter(&"rim_color", Color(0.75, 0.55, 0.35))
	sm.set_shader_parameter(&"crack_strength", crack)
	sm.set_shader_parameter(&"crack_color", AMBER)
	sm.set_shader_parameter(&"surface_kind", kind)
	_mats[key] = sm
	return sm


## A chain's glow, shared per (limb phase, colour, broken) so two Kings with the same colours build no new material.
static func _chain_mat(limb: StringName, col: Color, broken: bool) -> ShaderMaterial:
	var key := StringName("chain_%s_%s_%s" % [limb, col.to_html(false), broken])
	if _mats.has(key):
		return _mats[key]
	var sm := ShaderMaterial.new()
	sm.resource_name = "hk_chain"
	sm.shader = load(GLOW)
	sm.set_shader_parameter(&"glow_color", col)
	sm.set_shader_parameter(&"energy", CHAIN_BROKEN_ENERGY if broken else CHAIN_ENERGY)
	sm.set_shader_parameter(&"pulse_speed", 2.4)
	sm.set_shader_parameter(&"phase", float(LIMBS.find(limb)) * 1.3)
	_mats[key] = sm
	return sm


static func _glow_mat(c: Color, energy: float, pulse: float) -> ShaderMaterial:
	var key := StringName("glow%s_%s_%s" % [c.to_html(), energy, pulse])
	if _mats.has(key):
		return _mats[key]
	var sm := ShaderMaterial.new()
	sm.resource_name = "hk_glow"
	sm.shader = load(GLOW)
	sm.set_shader_parameter(&"glow_color", c)
	sm.set_shader_parameter(&"energy", energy)
	sm.set_shader_parameter(&"pulse_speed", pulse)
	_mats[key] = sm
	return sm


## Material by part key (shared across Kings; chains: _chain_mat, shared per colour).
static func _mat(key: StringName) -> Material:
	match key:
		&"stone":
			return _painted(key, Color(0.36, 0.34, 0.30), 0.45)
		&"dark":
			return _painted(key, Color(0.19, 0.18, 0.17), 0.30)
		&"pale":
			return _painted(key, Color(0.62, 0.57, 0.48), 0.35)
		&"metal":
			return _painted(key, Color(0.30, 0.25, 0.19), 0.0, 0.3, 2)
		&"gold":
			return _painted(key, Color(0.78, 0.60, 0.30), 0.0, 0.4, 2)
		&"void":
			return _painted(key, Color(0.05, 0.04, 0.04), 0.0)
		&"mantle":
			return _painted(key, Color(0.27, 0.11, 0.10), 0.0, 0.0, 0)
		&"glow":
			return _glow_mat(AMBER, 2.2, 1.2)
	return _painted(&"stone", Color(0.36, 0.34, 0.30), 0.45)


## Model-space rest origin of a pivot (pivots are unrotated at rest, like CharacterModel.model_origin).
static func _origin(m: Node3D, path: String) -> Vector3:
	var p := Vector3.ZERO
	var c: Node = m.get_node_or_null(path)
	while c and c != m:
		p += (c as Node3D).position
		c = c.get_parent()
	return p


static func _pivot_mesh(m: Node3D, path: String) -> Mesh:
	var key := "piv|" + path
	if _meshes.has(key):
		return _meshes[key]
	var items: Array = []
	match path:
		"Root/Hips":
			_hips(items)
		"Root/Hips/LegL":
			_leg(items, -1.0)
		"Root/Hips/LegR":
			_leg(items, 1.0)
		"Root/Chest":
			_chest(items)
		"Root/Chest/Head":
			_head(items)
		"Root/Chest/ArmL":
			_arm(items, -1.0)
		"Root/Chest/ArmR":
			_arm(items, 1.0)
	var mesh := _merge(items, _origin(m, path))
	_meshes[key] = mesh
	return mesh


# ---------------------------------------------------------------- parts (model space, Colossus rest pose, feet at 0)

static func _xf(pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	var b := Basis.from_euler(rot_deg * (PI / 180.0)).scaled_local(scl) if scl != Vector3.ONE \
			else Basis.from_euler(rot_deg * (PI / 180.0))
	return Transform3D(b, pos)


## A mesh built along +Y from 0 placed from a to b.
static func _seg(a: Vector3, b: Vector3) -> Transform3D:
	var d := (b - a).normalized()
	return Transform3D(Basis(Quaternion(Vector3.UP, d)), a)


## A cylinder (centred on its height) from a to b.
static func _cyl_between(items: Array, a: Vector3, b: Vector3, r0: float, r1: float, seg: int, mat: StringName) -> void:
	var d := b - a
	var xf := Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), a + d * 0.5)
	items.append([CharacterModel.cyl(r1, r0, d.length(), seg), xf, mat])


static func _hips(items: Array) -> void:
	items.append([IceModel.soft_box(Vector3(0.92, 0.38, 0.58), 0.5), _xf(Vector3(0, 0.98, 0)), &"dark"])
	# torn skirt of the mantle cloth round the hips (strips hang to the knee blocks; the pillar legs show below)
	items.append([_ragged(0.48, 0.62, 0.44, 360.0, 14, 7), _xf(Vector3(0, 1.14, 0)), &"mantle"])


static func _leg(items: Array, sx: float) -> void:
	# a splayed pillar leg on a plinth foot (a dark block on a pale slab), a pale capital for the knee
	items.append([IceModel.taper(0.78, 0.27, 0.23, 8), _seg(Vector3(0.48 * sx, 0.24, 0.04), Vector3(0.36 * sx, 1.0, 0)), &"dark"])
	items.append([IceModel.soft_box(Vector3(0.50, 0.14, 0.50), 0.5), _xf(Vector3(0.43 * sx, 0.62, 0.02)), &"pale"])
	items.append([IceModel.soft_box(Vector3(0.54, 0.22, 0.70), 0.5), _xf(Vector3(0.49 * sx, 0.19, 0.10)), &"dark"])
	items.append([IceModel.soft_box(Vector3(0.66, 0.10, 0.82), 0.4), _xf(Vector3(0.49 * sx, 0.05, 0.10)), &"pale"])
	# ankle shackle
	items.append([CharacterModel.torus(0.25, 0.38, 10), _xf(Vector3(0.47 * sx, 0.40, 0.03), Vector3.ZERO, Vector3(1, 1.7, 1)), &"metal"])


static func _arm(items: Array, sx: float) -> void:
	# vault shoulder: a pale block crowned with two broken pillar stubs leaning out (jagged from the side and above)
	items.append([IceModel.soft_box(Vector3(0.62, 0.36, 0.64), 0.5), _xf(Vector3(0.86 * sx, 2.22, 0.0)), &"pale"])
	for st: Array in [[Vector3(0.80, 2.36, -0.14), 0.46, 0.0], [Vector3(1.00, 2.34, 0.12), 0.24, 0.05]]:
		var at: Vector3 = st[0]
		var h: float = st[1]
		var tilt := Basis(Vector3.BACK, deg_to_rad(-20.0 * sx))
		items.append([CharacterModel.cyl(float(st[2]), 0.08, h, 4), Transform3D(tilt,
			Vector3(at.x * sx, at.y, at.z) + tilt * Vector3(0, h * 0.5, 0)), &"pale"])
	# long arms reaching forward, huge fists
	items.append([IceModel.taper(0.68, 0.22, 0.19, 8), _seg(Vector3(0.88 * sx, 2.05, 0.05), Vector3(1.02 * sx, 1.42, 0.22)), &"stone"])
	items.append([IceModel.soft_box(Vector3(0.32, 0.24, 0.32), 0.5), _xf(Vector3(1.02 * sx, 1.40, 0.22)), &"pale"])
	items.append([IceModel.taper(0.50, 0.20, 0.24, 8), _seg(Vector3(1.02 * sx, 1.38, 0.22), Vector3(1.08 * sx, 0.96, 0.42)), &"stone"])
	items.append([IceModel.soft_box(Vector3(0.50, 0.52, 0.52), 0.55), _xf(Vector3(1.10 * sx, 0.74, 0.48), Vector3(-12, 0, 0)), &"stone"])
	# wrist shackle (along the forearm)
	items.append([CharacterModel.torus(0.24, 0.36, 10), _xf(Vector3(1.07 * sx, 1.00, 0.40), Vector3(-25, 0, 0), Vector3(1, 1.7, 1)), &"metal"])


static func _chest(items: Array) -> void:
	# back mass (the throne-hall wall) + broad collar lintel + narrow waist beam: the cage frame, wide at the top
	items.append([IceModel.soft_box(Vector3(1.04, 1.08, 0.44), 0.5), _xf(Vector3(0, 1.72, -0.34), Vector3(8, 0, 0)), &"dark"])
	items.append([IceModel.soft_box(Vector3(1.34, 0.22, 0.66), 0.5), _xf(Vector3(0, 2.18, 0.0)), &"stone"])
	items.append([IceModel.soft_box(Vector3(0.80, 0.20, 0.60), 0.5), _xf(Vector3(0, 1.26, 0.04)), &"stone"])
	# rib pillars round an open front (the throne shows between them)
	for p: Vector3 in [Vector3(0.44, 0, 0.18), Vector3(0.28, 0, 0.30), Vector3(0.48, 0, -0.10)]:
		for s: float in [-1.0, 1.0]:
			_cyl_between(items, Vector3(p.x * s * 0.9, 1.34, p.z), Vector3(p.x * s, 2.10, p.z + 0.02), 0.075, 0.06, 6, &"pale")
	# the hollow: a black void in the cage, the heart-stone's twin glowing behind the throne, an amber rim
	items.append([CharacterModel.sphere(0.44, 8, 4), _xf(Vector3(0, 1.72, -0.10), Vector3.ZERO, Vector3(1.0, 1.05, 0.55)), &"void"])
	items.append([CharacterModel.sphere(0.22, 8, 4), _xf(Vector3(0, 1.86, -0.04)), &"glow"])
	items.append([CharacterModel.torus(0.36, 0.43, 14), _xf(Vector3(0, 1.72, 0.26), Vector3(90, 0, 0), Vector3(1.0, 1.0, 1.2)), &"glow"])
	# the Hollow Throne: seat, back, arms, two finials (gold-worn stone)
	items.append([IceModel.soft_box(Vector3(0.36, 0.08, 0.26), 0.4), _xf(Vector3(0, 1.48, 0.14)), &"gold"])
	items.append([IceModel.soft_box(Vector3(0.32, 0.42, 0.07), 0.4), _xf(Vector3(0, 1.72, 0.04)), &"gold"])
	for s: float in [-1.0, 1.0]:
		items.append([CharacterModel.box(Vector3(0.06, 0.10, 0.24)), _xf(Vector3(0.18 * s, 1.56, 0.14)), &"gold"])
		items.append([CharacterModel.cyl(0.0, 0.04, 0.18, 4), _xf(Vector3(0.14 * s, 2.02, 0.04)), &"gold"])
	# ragged mantle off the shoulders (torn hem to the knees) + a torn collar
	items.append([_ragged(0.62, 0.98, 1.70, 230.0, 12, 11), _xf(Vector3(0, 2.26, -0.06)), &"mantle"])
	items.append([IceModel.fur_ring(0.58, 0.76, 0.26, 9, 0.08), _xf(Vector3(0, 2.10, -0.04)), &"mantle"])


static func _head(items: Array) -> void:
	items.append([IceModel.soft_box(Vector3(0.52, 0.48, 0.44), 0.5), _xf(Vector3(0, 2.46, 0.30)), &"dark"])
	items.append([IceModel.soft_box(Vector3(0.58, 0.10, 0.18), 0.5), _xf(Vector3(0, 2.68, 0.44), Vector3(-8, 0, 0)), &"dark"])
	# broken rose window: amber light behind a pale ring, 5 of 8 spokes left
	var face := Vector3(0, 2.46, 0.53)
	items.append([CharacterModel.cyl(0.21, 0.21, 0.04, 12), _xf(face, Vector3(90, 0, 0)), &"glow"])
	items.append([CharacterModel.torus(0.18, 0.26, 12), _xf(face + Vector3(0, 0, 0.02), Vector3(90, 0, 0)), &"pale"])
	items.append([CharacterModel.sphere(0.05, 6, 3), _xf(face + Vector3(0, 0, 0.03)), &"pale"])
	for k: int in [0, 1, 3, 4, 6]:
		var a := TAU * float(k) / 8.0
		var dir := Vector3(sin(a), cos(a), 0)
		items.append([CharacterModel.box(Vector3(0.035, 0.17, 0.03)), _xf(face + dir * 0.095 + Vector3(0, 0, 0.03),
			Vector3(0, 0, -rad_to_deg(a))), &"pale"])
	# broken crown: a pale band and 7 points round it, three snapped to stumps
	var crown := Vector3(0, 2.74, 0.28)
	items.append([CharacterModel.torus(0.24, 0.34, 12), _xf(crown, Vector3.ZERO, Vector3(1, 1.4, 1)), &"pale"])
	var hs: Array[float] = [0.54, 0.18, 0.62, 0.24, 0.56, 0.13, 0.46]
	for i: int in hs.size():
		var a := TAU * float(i) / float(hs.size())
		var out := Vector3(sin(a), 0, cos(a))
		var tilt := Basis(Vector3.UP.cross(out).normalized(), deg_to_rad(14.0))
		var h: float = hs[i]
		var stump: bool = h < 0.25
		var mesh := CharacterModel.cyl(0.05 if stump else 0.0, 0.08, h, 4)
		var pos := crown + out * 0.29 + tilt * Vector3(0, 0.04 + h * 0.5, 0)
		items.append([mesh, Transform3D(tilt * Basis(Vector3.UP, a + PI * 0.25), pos), &"pale"])


# ---------------------------------------------------------------- chains

## The chain links of one limb (pivot-local), cached per limb and state.
static func _chain_mesh(m: Node3D, limb: StringName, broken: bool) -> Mesh:
	var key := "chain|%s|%s" % [limb, broken]
	if _meshes.has(key):
		return _meshes[key]
	var sx: float = -1.0 if limb == &"arm_l" or limb == &"leg_l" else 1.0
	var pts: PackedVector3Array
	# arms: down from the wrist, then out along the front diagonal; legs: back from the ankle along the rear diagonal
	# (the four chains make an X on the ground round him: one toward each keyhole side)
	if limb == &"arm_r" or limb == &"arm_l":
		pts = PackedVector3Array([Vector3(1.20 * sx, 0.92, 0.42), Vector3(1.30 * sx, 0.40, 0.60),
			Vector3(1.42 * sx, 0.09, 0.78), Vector3(2.55 * sx, 0.09, 1.85)])
	else:
		pts = PackedVector3Array([Vector3(0.52 * sx, 0.36, -0.22), Vector3(0.62 * sx, 0.12, -0.50),
			Vector3(0.78 * sx, 0.09, -0.74), Vector3(1.95 * sx, 0.09, -1.95)])
	if broken:
		pts = PackedVector3Array([pts[0], pts[0].lerp(pts[1], 0.7)])
	var items: Array = []
	var link := CharacterModel.torus(0.065, 0.145, 6)
	var step := 0.22
	var n := 0
	for i: int in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var d := (b - a).normalized()
		var length := a.distance_to(b)
		var t := 0.0
		while t < length:
			var z := d
			var x := Vector3.UP.cross(z)
			if x.length() < 0.01:
				x = Vector3.RIGHT
			x = x.normalized()
			var y := z.cross(x)
			var basis := Basis(x, y, z)
			if n % 2 == 1:
				basis = Basis(z, PI * 0.5) * basis
			basis = basis.scaled_local(Vector3(1.0, 1.0, 1.5))
			items.append([link, Transform3D(basis, a + d * t), &"chain"])
			t += step
			n += 1
	var path := String(LIMB_PIVOT[limb])
	var mesh := _merge(items, _origin(m, path))
	_meshes[key] = mesh
	return mesh


# ---------------------------------------------------------------- effects (Medium+)

static func _add_embers(m: Node3D) -> void:
	var chest := m.get_node_or_null(^"Root/Chest") as Node3D
	if chest == null:
		return
	var p := CharacterModel.make_motes(AMBER, 10, 2.4, 0.28, 0.45, 0.09)
	p.name = "HKEmbers"
	p.position = Vector3(0, 1.80, 0.10) - _origin(m, "Root/Chest")
	p.visibility_aabb = AABB(Vector3(-1.0, -0.6, -1.0), Vector3(2.0, 3.0, 2.0))
	VfxCap.fit(p)
	chest.add_child(p)


# ---------------------------------------------------------------- mesh building

## Torn mantle: an arc of `wrap_deg` round the back (-Z; 360 = a full skirt), radius r_top at y 0 flaring to r_bot,
## every column hanging to its own length (a torn hem), both sides (one copy wound each way).
static func _ragged(r_top: float, r_bot: float, h: float, wrap_deg: float, cols: int, seed_k: int) -> Mesh:
	var key := "rag%s_%s_%s_%s_%d_%d" % [r_top, r_bot, h, wrap_deg, cols, seed_k]
	if _meshes.has(key):
		return _meshes[key]
	var rows := 3
	var v := PackedVector3Array()
	var nn := PackedVector3Array()
	var uv := PackedVector2Array()
	var ix := PackedInt32Array()
	var lens := PackedFloat32Array()
	for c: int in cols + 1:
		var hsh: float = float(absi(hash(c * 7919 + seed_k * 131)) % 1000) / 1000.0
		lens.append(1.0 if c % 2 == 0 else 0.62 + 0.25 * hsh)
	var full: bool = wrap_deg >= 359.0
	for side: int in 2:
		var base := v.size()
		for c: int in cols + 1:
			var u := float(c) / float(cols)
			var a := (u - 0.5) * deg_to_rad(wrap_deg)
			var lc: float = lens[0] if full and c == cols else lens[c]
			for r: int in rows + 1:
				var t := float(r) / float(rows)
				var rad: float = lerpf(r_top, r_bot, t * lc)
				v.append(Vector3(sin(a) * rad, -t * h * lc, -cos(a) * rad))
				var out := Vector3(sin(a), 0.3, -cos(a)).normalized()
				nn.append(out if side == 0 else -out)
				uv.append(Vector2(u, t))
		for c: int in cols:
			for r: int in rows:
				var i0 := base + c * (rows + 1) + r
				var i1 := base + (c + 1) * (rows + 1) + r
				_tri(ix, v, nn, i0, i1, i1 + 1)
				_tri(ix, v, nn, i0, i1 + 1, i0 + 1)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nn
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = ix
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_meshes[key] = am
	return am


## Appends a triangle wound front-out along the vertices' normals (Godot: clockwise = front).
static func _tri(ix: PackedInt32Array, v: PackedVector3Array, n: PackedVector3Array, a: int, b: int, c: int) -> void:
	var fn := (v[b] - v[a]).cross(v[c] - v[a])
	if fn.dot(n[a] + n[b] + n[c]) > 0.0:
		ix.append_array(PackedInt32Array([a, c, b]))
	else:
		ix.append_array(PackedInt32Array([a, b, c]))


## Merges [mesh, model-space Transform3D, material key] items into one ArrayMesh, one surface per material, in
## pivot space (minus `origin`).
static func _merge(items: Array, origin: Vector3) -> ArrayMesh:
	var order: Array[StringName] = []
	var vs: Dictionary = {}
	var ns: Dictionary = {}
	var us: Dictionary = {}
	var is_: Dictionary = {}
	for it: Array in items:
		var mesh: Mesh = it[0]
		var xf: Transform3D = it[1]
		xf.origin -= origin
		var key: StringName = it[2]
		if not vs.has(key):
			order.append(key)
			vs[key] = PackedVector3Array()
			ns[key] = PackedVector3Array()
			us[key] = PackedVector2Array()
			is_[key] = PackedInt32Array()
		var av: PackedVector3Array = vs[key]
		var an: PackedVector3Array = ns[key]
		var au: PackedVector2Array = us[key]
		var ai: PackedInt32Array = is_[key]
		var nb := xf.basis.inverse().transposed()
		var flip: bool = xf.basis.determinant() < 0.0
		for s: int in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			var u: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var b0 := av.size()
			for i: int in v.size():
				av.append(xf * v[i])
				an.append((nb * n[i]).normalized() if i < n.size() else Vector3.UP)
				au.append(u[i] if i < u.size() else Vector2.ZERO)
			if ix.is_empty():
				for i: int in v.size():
					ai.append(b0 + i)
			else:
				for k: int in range(0, ix.size(), 3):
					if flip:
						ai.append_array(PackedInt32Array([b0 + ix[k], b0 + ix[k + 2], b0 + ix[k + 1]]))
					else:
						ai.append_array(PackedInt32Array([b0 + ix[k], b0 + ix[k + 1], b0 + ix[k + 2]]))
		vs[key] = av
		ns[key] = an
		us[key] = au
		is_[key] = ai
	var am := ArrayMesh.new()
	for key: StringName in order:
		var arr: Array = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = vs[key]
		arr[Mesh.ARRAY_NORMAL] = ns[key]
		arr[Mesh.ARRAY_TEX_UV] = us[key]
		arr[Mesh.ARRAY_INDEX] = is_[key]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		if key != &"chain":
			am.surface_set_material(am.get_surface_count() - 1, _mat(key))
	return am

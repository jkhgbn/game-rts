class_name MossbackModel
extends MountModel
## Mossback (tier3-extras.md 7 / 12, task 13b.V4): Nature's tier-3 "strong, slow" unit. A giant old tortoise, 4.25 m from
## the beak to the tail, the moss-grown carapace 1.76 m high, a SMALL GROVE ON ITS SHELL = the read at 40 m: a mossy
## mound ringed by standing stones (a tall front stone with a glowing tree rune = the ONE glow point, a little dolmen
## at the back, a vine ring), three young trees of different heights rooted into the moss (dark and brown bark, round
## deep blue-green crowns with an amber seed pod each, lit only by the Canopy; the old tree has a bleached dead limb
## reaching out front-left), the grove's top ~3.0 m. Palette (Art Lab R3): the main mass is WARM - umber seams, two
## rows of raised bronze-brown stone scutes (costals), a thick serrated rim - with a cool, dusky blue-green moss cap
## and fringe, so it never melts into the yellow-green meadow; light tops, dark limbs. Moss locks off the rim; a pale
## plastron; team-cloth drapes on both flanks (nature_cloth, dark hem, a pale leaf emblem, tassels). Beaked, wrinkled
## head on a long neck (dark wet eyes with a pale glint, heavy brows, a lichen patch), a hinged lower beak; four
## elephantine splayed legs with scales and blunt horn claws.
## Apart from the Elder Treant (a tall walking tree with a face) and the Grove Stag (a slim deer with wide antlers):
## a LOW, WIDE dome carrying trees, four stubby legs, no antlers, no face in the bark.
##
## Hooks (all safe before _ready; callers use has_method):
##   kit / MountModel: set_team_color(c) (the drapes) · set_moving(speed) (slow heavy 4-beat stomp, never a gallop;
##   footfall dips, waddle, the trees sway and shiver) · play_attack() (attack_style &"shell_bite": the head shoots
##   out on its neck, the beak snaps shut at BITE_HIT 0.18 s = event "release", a tearing head shake, back into the
##   shell; length BITE_LEN 0.95 s; melee: attack_windup 0) · play_hit() (flash, the head flinches into the shell, the
##   trees shiver) · play_death() + signal death_finished (SINK_DEATH_LEN 1.6 s, before Unit's 2.0 s fallback: the
##   head and legs pull into the shell, the shell drops, the crowns wilt, glows die at 0.38 s, then the whole tortoise sinks into the ground)
##   · revive() · set_status(id, on) -> bool · play_cast / play_level_up / set_veterancy (kit) · play_fidget().
##   set_canopy(on: bool, instant := false): the Canopy aura (tier3-extras.md 7.2). On: the three crowns spread wide
##   (x1.6 across, x0.78 tall, trees lean out 12 deg) and lean outward, the leaves glow softly (lime), the seed pods light up amber, the rune
##   flares, glowing leaves drift down (one particle system, world space, only while on and within 45 m). Opens in
##   ~0.7 s with a small overshoot, folds back in ~0.9 s; signal canopy_changed(on) when it has settled.
##   is_canopy() -> bool · canopy_blend() -> float (0 folded .. 1 spread) · get_bite_point() -> Vector3 (world beak
##   tip, bite VFX) · get_canopy_points() -> PackedVector3Array (world crown centres, canopy_block VFX).
##   signal footfall(leg: int) (0-3 = FL FR BL BR, within 30 m; a stomp sound hook).
## Budget (tier3-extras.md 12 heavy: <= 30 meshes, <= 16 instances, <= 1 looping particle system, 0 lights):
##   authored meshes 13 (body, head, jaw, 4 legs, 3 trunks, 3 crowns sculpts) + blob = 14; draw instances 14
##   (Body, Head, Jaw, 4 legs, 3 trees, 3 crowns, blob) + 1 particle system = 15. Vertices ~5 800 (Art Lab heavy soft
##   6 000: low segment counts, one lathe per scute, lobes only on the main crown clump). Shadow casters 3 (body +
##   crowns A / B). Glow points at 40 m: 1 (the rune). Materials: 7 own (this folder: 5 painted, the leaf shader, the
##   seed pods on the leaf shader) + the Nature palette + kit (unit_eye_dark, blob).

signal footfall(leg: int)
## The Canopy spread / fold has settled (true = spread).
signal canopy_changed(on: bool)

const OWN := "res://art/units/nature/mossback/materials/"
const NAT := "res://art/units/nature/materials/"
const KIT := "res://art/units/kit/materials/"
const BLOB_TINT := Color(0.04, 0.05, 0.02, 0.55)

## Carapace: a lathe around +Y at (0, RIM_Y, SH_CZ) scaled (SH_X, 1, SH_Z); profile = normalised radius per height
## above the rim. The moss cap is a thicker lathe on the top (CAP_*), the grove stands on it.
const RIM_Y := 0.80
const SH_X := 1.28
const SH_Z := 1.50
const SH_CZ := 0.05
const DOME_H: Array[float] = [-0.09, 0.00, 0.21, 0.46, 0.67, 0.81, 0.88]
const DOME_R: Array[float] = [0.96, 1.02, 0.98, 0.88, 0.70, 0.45, 0.00]
const CAP_H: Array[float] = [0.58, 0.69, 0.83, 0.90, 0.96]
const CAP_R: Array[float] = [0.78, 0.715, 0.47, 0.25, 0.00]
## Normalised radius of the standing-stone ring on the cap.
const RING_RN := 0.58
## Standing stones: [theta deg (0 = front, toward +x), height, width, outward lean deg, twist deg]. 0 = the rune stone.
const STONES: Array = [[0.0, 0.70, 0.30, 0.0, 0.0], [58.0, 0.40, 0.24, 8.0, 20.0], [118.0, 0.34, 0.22, -6.0, -15.0],
	[242.0, 0.42, 0.24, 5.0, 10.0], [302.0, 0.33, 0.22, -9.0, 30.0]]
## Dolmen posts at the back (theta), height.
const DOLMEN: Array[float] = [166.0, 194.0]
const DOLMEN_H := 0.40
## Team drapes: the ellipse (x radius, height) they hang on, centred on the rim at the shell's middle.
const DR_X := 1.40
const DR_Y := 0.97
## The head's geometry is authored 8 cm back from its first draft (keeps the model ~4.3 m long).
const HO := Vector3(0.0, 0.0, -0.08)

## Trees (pivots Root/Mount/TreeA|B|C, each with a Crown child at the crown base; the geometry follows the nodes).
const TREE_PATHS: Array[String] = ["Root/Mount/TreeA", "Root/Mount/TreeB", "Root/Mount/TreeC"]
const TREE_BARK: Array[String] = ["nature_bark_dark", "nature_bark", "nature_bark_dark"]
const TREE_BEND: Array[Vector3] = [Vector3(0.05, 0.0, 0.03), Vector3(-0.05, 0.0, -0.04), Vector3(0.03, 0.0, 0.03)]
const TRUNK_R: Array = [[0.13, 0.11, 0.085, 0.065], [0.11, 0.09, 0.075, 0.055], [0.10, 0.08, 0.065, 0.05]]
## Leaf clumps per crown: [offset from the crown base, radii].
const CLUMPS: Array = [
	[[Vector3(0.0, 0.16, 0.0), Vector3(0.42, 0.33, 0.42)], [Vector3(-0.27, 0.07, 0.12), Vector3(0.30, 0.25, 0.30)],
		[Vector3(0.24, 0.05, -0.14), Vector3(0.30, 0.24, 0.30)], [Vector3(0.04, 0.34, -0.06), Vector3(0.27, 0.22, 0.27)],
		[Vector3(0.12, 0.02, 0.27), Vector3(0.25, 0.20, 0.25)]],
	[[Vector3(0.0, 0.12, 0.0), Vector3(0.36, 0.25, 0.36)], [Vector3(0.25, 0.04, 0.14), Vector3(0.26, 0.20, 0.26)],
		[Vector3(-0.19, 0.06, 0.18), Vector3(0.24, 0.19, 0.24)], [Vector3(0.05, 0.25, -0.09), Vector3(0.22, 0.17, 0.22)]],
	[[Vector3(0.0, 0.10, 0.0), Vector3(0.28, 0.23, 0.28)], [Vector3(0.16, 0.18, -0.10), Vector3(0.20, 0.17, 0.20)],
		[Vector3(-0.15, 0.04, 0.10), Vector3(0.20, 0.16, 0.20)]],
]
## Seed lanterns (amber pods hanging under the crowns, lit only by the Canopy): offsets from the crown base.
const LANTERNS: Array = [[Vector3(0.34, -0.12, 0.24)], [Vector3(-0.26, -0.08, 0.30)], [Vector3(0.22, -0.07, 0.16)]]
## Crowns that cast sun shadows (the two big ones; the body casts too): 3 casters in all.
const CROWN_SHADOW: Array[bool] = [true, true, false]

## Canopy: crown scale at full spread, the trees' outward lean, the crown glow_boost folded / spread (the leaf shader
## maps it to its glow), spring times.
const CROWN_SPREAD := Vector3(1.6, 0.78, 1.6)
const CANOPY_LEAN_DEG := 12.0
const CROWN_GLOW_OFF := 0.55
const CROWN_GLOW_ON := 2.2
const CANOPY_OPEN := 0.7
const CANOPY_CLOSE := 0.9
## Tree sway spring (rad): stiffness (omega^2) and damping (2 zeta omega).
const SW_K := 56.0
const SW_D := 3.0
## shell_bite timeline (s).
const BITE_LEN := 0.95
const BITE_HIT := 0.18
## Death: pull in (s), total length (s), sink depth (m).
const RETRACT_LEN := 0.45
const SINK_DEATH_LEN := 1.6
const SINK_DEPTH := 2.7
## Beak tip in the Head pivot's frame (rest), for get_bite_point().
const BEAK_TIP := Vector3(0.0, 0.02, 1.07)

# Keyframe tracks [t, value, ease, ...] (MountModel._mkf). shell_bite: the head draws back and up (0.08), shoots out
# and down on its neck with the beak open, snaps shut at 0.18, a tearing shake, then slides back into the shell.
static var BT_HEAD_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.10, 1, 0.18, 0.62, 2, 0.30, 0.56, 0, 0.45, 0.50, 0, 0.95, 0.0, 0])
static var BT_HEAD_Y := PackedFloat32Array([0.0, 0.0, 0, 0.08, 0.05, 1, 0.18, -0.13, 2, 0.45, -0.08, 0, 0.95, 0.0, 0])
static var BT_HEAD_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -14.0, 1, 0.18, 12.0, 2, 0.30, 6.0, 0, 0.45, 4.0, 0, 0.95, 0.0, 0])
static var BT_JAW := PackedFloat32Array([0.0, 0.0, 0, 0.06, 10.0, 1, 0.14, 38.0, 1, 0.18, 0.0, 2, 0.30, 5.0, 0, 0.40, 0.0, 0, 0.95, 0.0, 0])
static var BT_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0, 0.08, -0.06, 1, 0.20, 0.16, 2, 0.45, 0.10, 0, 0.95, 0.0, 0])
static var BT_BODY_X := PackedFloat32Array([0.0, 0.0, 0, 0.08, -2.5, 1, 0.20, 3.5, 2, 0.45, 1.5, 0, 0.95, 0.0, 0])
static var BT_LEG_F := PackedFloat32Array([0.0, 0.0, 0, 0.08, -4.0, 1, 0.20, -10.0, 2, 0.50, -3.0, 0, 0.95, 0.0, 0])

static var _fx_cache: Dictionary = {}

var _jaw: Node3D
var _face: FaceRig   # beast eyes (FaceKit, face rework 2026-09-28)
var _jaw_mi: MeshInstance3D
var _trees: Array[Node3D] = [null, null, null]
var _crowns: Array[Node3D] = [null, null, null]
var _tree_mi: Array[MeshInstance3D] = [null, null, null]
var _crown_mi: Array[MeshInstance3D] = [null, null, null]
var _tree_rest: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _crown_rest: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _tree_out: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _sway: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _sway_v: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _tree_last: Array[Vector3] = [Vector3(INF, 0, 0), Vector3(INF, 0, 0), Vector3(INF, 0, 0)]
var _crown_last_s: Vector3 = Vector3(INF, 0, 0)
var _crown_last_dy: float = INF
var _crown_glow_written: float = -1.0
var _leaves: GPUParticles3D
var _jaw_pose: float = 0.0
var _jaw_last: float = INF
var _canopy_on: bool = false
var _canopy_w: float = 0.0
var _canopy_v: float = 0.0
var _canopy_settled: bool = true
var _canopy_instant: bool = false
var _wilt: float = 0.0


# ================================================================ authoring

func _build_mount() -> void:
	var body: Node3D = $Root/Mount
	var head: Node3D = $Root/Mount/Head
	add_sculpt(body, _body_sculpt)
	add_sculpt(head, _head_sculpt)
	# Eyes (FaceKit beast face, face rework 2026-09-28, were two dark wet spheres with a glint): old, heavy-lidded
	# amber-brown eyes on the skull sides under the scale brows; they narrow on the bite, droop as it sinks. The beak
	# hides the kit's mouth.
	var sc := Vector3(0, 1.26, 2.10) + HO
	var hide := Color(0.37, 0.32, 0.25)
	_face = FaceKit.attach(self, head, "mossback", NatureFaces.style({
		"center": sc, "radius": 0.30, "head_mesh": sphere(1.0, 10, 4), "head_scale": Vector3(0.34, 0.29, 0.40), "head_at": sc,
		"preset": &"elder", "skin": hide, "eyes": Color(0.62, 0.42, 0.14), "detail": &"low",
		"x": NatureFaces.lean_x(1.15, {&"neutral": {"open": 0.8, "low": 0.3}}),
		"palette": NatureFaces.beast_palette(hide, Color(0.62, 0.42, 0.14)),
		"eye": {"c": Vector2(0.345, 0.05), "hw": 0.055, "top": 0.040, "bot": 0.028, "ir": 0.028, "tilt": 0.0},
		"brow": {"none": true}, "mouth": NatureFaces.beast_mouth(Vector2(0, -0.40)), "extra": func(_a: Dictionary, _i: StringName) -> void: pass,
	}, Vector3.ZERO, 0.005))
	_jaw = get_node_or_null(^"Root/Mount/Head/Jaw") as Node3D
	if _jaw:
		_jaw.set_meta(&"keep_separate", true)
		add_sculpt(_jaw, _jaw_sculpt)
		_jaw_mi = _merge_own(_jaw)
	var legs: Array[Node3D] = [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]
	for leg: Node3D in legs:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _leg_sculpt(s, p))
	for i: int in 3:
		var tr := get_node_or_null(TREE_PATHS[i]) as Node3D
		_trees[i] = tr
		if tr == null:
			continue
		tr.set_meta(&"keep_separate", true)
		var cr := tr.get_node_or_null(^"Crown") as Node3D
		_crowns[i] = cr
		var b := model_origin(tr)
		var c: Vector3 = model_origin(cr) if cr else b + Vector3(0, 0.5, 0)
		var ti := i
		add_sculpt(tr, func(s: Dictionary) -> void: _tree_sculpt(s, ti, b, c))
		_tree_mi[i] = _merge_own(tr)
		if cr:
			cr.set_meta(&"keep_separate", true)
			add_sculpt(cr, func(s: Dictionary) -> void: _crown_sculpt(s, ti, c))
			_crown_mi[i] = _merge_own(cr)
			if _crown_mi[i]:
				_crown_mi[i].set_meta(&"own_glow", true)   # driven by the Canopy, not by the kit
	ensure_shadow_blob(1.3, BLOB_TINT)
	_shadow.scale = Vector3(3.3, 1.0, 4.6)
	_shadow.position = Vector3(0, 0.02, 0.10)


static func m(name: String) -> Material:
	var dir: String = OWN if name.begins_with("mossback") else (KIT if name.begins_with("unit_") else NAT)
	return material_at(dir + name + ".tres")


## Merges the static parts under an own (non-kit) pivot into one "Merged" node, cached per type like the kit.
func _merge_own(p: Node3D) -> MeshInstance3D:
	var key := _type_key + "|" + _pivot_name(p)
	var parts: Array[MeshInstance3D] = []
	var xforms: Array[Transform3D] = []
	_collect_static(p, Transform3D.IDENTITY, parts, xforms, true)
	var entry: Dictionary
	if _merged.has(key):
		entry = _merged[key]
	else:
		entry = _build_merged(parts, xforms)
		_merged[key] = entry
	for mi: MeshInstance3D in parts:
		mi.get_parent().remove_child(mi)
		mi.queue_free()
	if entry.is_empty():
		return null
	var out := MeshInstance3D.new()
	out.name = "Merged"
	out.mesh = entry["mesh"]
	out.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var params: Dictionary = entry["params"]
	for nm: StringName in params:
		out.set_instance_shader_parameter(nm, params[nm])
	p.add_child(out)
	return out


# ================================================================ geometry helpers (model space)

static func _lerp_table(xs: Array[float], ys: Array[float], x: float) -> float:
	if x <= xs[0]:
		return ys[0]
	for i: int in range(1, xs.size()):
		if x < xs[i]:
			return lerpf(ys[i - 1], ys[i], (x - xs[i - 1]) / (xs[i] - xs[i - 1]))
	return ys[ys.size() - 1]


## Normalised dome radius at height h above the rim.
static func _dome_r(h: float) -> float:
	return _lerp_table(DOME_H, DOME_R, h)


static func _dome_p(th: float, h: float) -> Vector3:
	var r := _dome_r(h)
	return Vector3(SH_X * r * sin(th), RIM_Y + h, SH_CZ + SH_Z * r * cos(th))


## [point, outward normal] on the carapace at azimuth theta (deg from +z toward +x) and height h above the rim.
static func _dome_pt(theta_deg: float, h: float) -> Array:
	var th := deg_to_rad(theta_deg)
	var p := _dome_p(th, h)
	var d_th := _dome_p(th + 0.01, h) - _dome_p(th - 0.01, h)
	var d_h := _dome_p(th, h + 0.01) - _dome_p(th, h - 0.01)
	var n := d_th.cross(d_h).normalized()
	if n.dot(p - Vector3(0, RIM_Y, SH_CZ)) < 0.0:
		n = -n
	return [p, n]


## Height above the rim of the moss cap (or of the bare dome outside it) at normalised radius rn.
static func _cap_h(rn: float) -> float:
	if rn >= CAP_R[0]:
		for i: int in range(1, DOME_R.size()):
			if rn >= DOME_R[i] and DOME_R[i] < DOME_R[i - 1]:
				return lerpf(DOME_H[i - 1], DOME_H[i], (DOME_R[i - 1] - rn) / (DOME_R[i - 1] - DOME_R[i]))
		return 0.0
	for i: int in range(1, CAP_R.size()):
		if rn >= CAP_R[i]:
			return lerpf(CAP_H[i - 1], CAP_H[i], (CAP_R[i - 1] - rn) / (CAP_R[i - 1] - CAP_R[i]))
	return CAP_H[CAP_H.size() - 1]


## The cap surface point above (x, z).
static func _cap_pt(x: float, z: float) -> Vector3:
	var rn := sqrt(pow(x / SH_X, 2.0) + pow((z - SH_CZ) / SH_Z, 2.0))
	return Vector3(x, RIM_Y + _cap_h(rn), z)


static func _ring_pt(theta_deg: float, rn: float) -> Vector3:
	var th := deg_to_rad(theta_deg)
	return _cap_pt(SH_X * rn * sin(th), SH_CZ + SH_Z * rn * cos(th))


static func _ell(s: Dictionary, mat: Material, c: Vector3, r: Vector3, seg: int = 12, rings: int = 6) -> void:
	sculpt_put(s, sphere(1.0, seg, rings), mat, c, Vector3.ZERO, r)


## A tapered cone along `dir` whose base centre is at `at` (length l, base radius r).
static func _cone(s: Dictionary, mat: Material, at: Vector3, dir: Vector3, r: float, l: float, seg: int = 6) -> void:
	var d := dir.normalized()
	sculpt_add(s, cyl(0.0, r, l, seg), Transform3D(Basis(Quaternion(Vector3.UP, d)), at + d * l * 0.5), mat)


# ================================================================ body (carapace, grove ground, stones, drapes)

func _body_sculpt(s: Dictionary) -> void:
	var shell := m("mossback_shell")
	var sdark := m("mossback_shell_dark")
	var moss := m("mossback_moss")
	var skin := m("mossback_skin")
	var scl := m("mossback_scale")
	var plast := m("nature_burr_b")
	var stone := m("nature_stone")
	var glow := m("nature_glow")
	var cloth := m("nature_cloth")
	var cdark := m("nature_cloth_dark")
	var vine := m("nature_leaf_dark")
	var pale := m("nature_skin")
	var cap_m := m("nature_hair")
	var shx := Transform3D(Basis.from_scale(Vector3(SH_X, 1.0, SH_Z)), Vector3(0, RIM_Y, SH_CZ))
	# ---- carapace: dark seams (the base dome), a thick rim band with serrated marginals, two rows of raised scutes
	var prof := PackedVector2Array()
	for i: int in DOME_H.size():
		prof.append(Vector2(DOME_R[i], DOME_H[i]))
	sculpt_add(s, lathe_mesh("mossback_dome_v3", prof, 12), shx, sdark)
	sculpt_add(s, lathe_mesh("mossback_rim_v2", PackedVector2Array([Vector2(1.0, -0.12), Vector2(1.055, -0.06),
		Vector2(1.07, 0.04), Vector2(1.025, 0.12)]), 14, false), shx, shell)
	sculpt_fringe(s, shell, fringe_mesh("mossback_marginal_v2", SH_X * 1.05, SH_Z * 1.05, SH_X * 1.075, SH_Z * 1.075,
		0.05, 0.0, 360.0, 13, 0.04, 0.05, 0.15), Vector3(0, RIM_Y - 0.06, SH_CZ))
	# one lathe per scute (a raised, bevelled hex plate with a low boss), 6 sides, radius 1 (scaled per scute)
	var scute := lathe_mesh("mossback_scute_v3", PackedVector2Array([Vector2(1.0, -0.03), Vector2(0.78, 0.075),
		Vector2(0.45, 0.11)]), 6)
	for ring: Array in [[0.20, 9, 20.0, 0.31], [0.48, 7, 0.0, 0.29]]:
		var hh: float = ring[0]
		var cnt: int = ring[1]
		var off: float = ring[2]
		var rr: float = ring[3]
		for k: int in cnt:
			var th: float = off + 360.0 * float(k) / float(cnt)
			var e := _dome_pt(th, hh)
			var p: Vector3 = e[0]
			var nn: Vector3 = e[1]
			var f := frame(p, nn, Vector3.UP).basis
			var b := Basis(f.x * 1.35, f.y, f.z) * Basis(Vector3.UP, PI / 6.0) * Basis.from_scale(Vector3(rr, 1.0, rr))
			sculpt_add(s, scute, Transform3D(b, p), shell)
	# plastron (pale belly plate) and the dark openings for the head and the tail, a skin collar round the neck
	_ell(s, plast, Vector3(0, 0.67, SH_CZ), Vector3(1.12, 0.16, 1.38), 10, 3)
	_ell(s, scl, Vector3(0, 1.02, 1.49), Vector3(0.42, 0.34, 0.14), 8, 3)
	sculpt_add(s, torus(0.22, 0.33, 8), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.02, 1.55)), skin)
	_ell(s, scl, Vector3(0, 0.92, -1.37), Vector3(0.30, 0.22, 0.12), 8, 3)
	# stubby tail with a scale
	var tp := PackedVector3Array([Vector3(0, 0.90, -1.33), Vector3(0, 0.80, -1.55), Vector3(0, 0.66, -1.69),
		Vector3(0, 0.56, -1.76)])
	sculpt_add(s, tube_mesh("mossback_tail_v2", tp, PackedFloat32Array([0.16, 0.13, 0.08, 0.0]), 6), Transform3D.IDENTITY, skin)
	_ell(s, scl, tp[0].lerp(tp[2], 0.35) + Vector3(0, 0.09, 0), Vector3(0.09, 0.04, 0.12), 6, 3)
	# ---- the grove ground: a moss cap over the top with a ragged fringe hanging over the upper scutes, moss mounds,
	# moss locks hanging off the rim
	var cprof := PackedVector2Array()
	for i: int in CAP_H.size():
		cprof.append(Vector2(CAP_R[i], CAP_H[i]))
	sculpt_add(s, lathe_mesh("mossback_cap_v3", cprof, 12), shx, moss)
	sculpt_fringe(s, moss, fringe_mesh("mossback_mossfringe_v2", SH_X * 0.78, SH_Z * 0.78, SH_X * 0.96, SH_Z * 0.96,
		0.14, 0.0, 360.0, 13, 0.08, 0.035, 0.7), Vector3(0, RIM_Y + 0.59, SH_CZ))
	for c: Array in [[-0.52, 0.30, 0.20], [0.05, -0.30, 0.18], [0.62, -0.05, 0.15]]:
		var cp := _cap_pt(c[0], c[1])
		var cr: float = c[2]
		_ell(s, moss, cp + Vector3(0, 0.01, 0), Vector3(cr, cr * 0.35, cr * 1.1), 7, 2)
	for th: float in [70.0, 250.0, 180.0]:
		var e := _dome_pt(th, 0.03)
		var nn: Vector3 = e[1]
		sculpt_lock(s, vine, (e[0] as Vector3) + nn * 0.07, (nn * 0.25 + Vector3.DOWN).normalized(), nn, 0.26,
			0.30 + 0.05 * sin(th), 0.06)
	for th: float in [-16.0, 16.0]:
		var e := _dome_pt(th, 0.30)
		var nn: Vector3 = e[1]
		sculpt_lock(s, moss, (e[0] as Vector3) + nn * 0.08, (nn * 0.3 + Vector3.DOWN).normalized(), nn, 0.18, 0.24, 0.05)
	# undergrowth: two dark leaf tufts, a mushroom (warm cap)
	for tu: Vector2 in [Vector2(-0.05, 0.42), Vector2(0.58, -0.22)]:
		var tb := _cap_pt(tu.x, tu.y) - Vector3(0, 0.02, 0)
		for k: int in 2:
			var a := TAU * (float(k) / 2.0 + 0.19 * tu.x)
			_cone(s, vine, tb, Vector3(0.45 * cos(a), 1.0, 0.45 * sin(a)), 0.05, 0.22 + 0.04 * float(k), 3)
	for mu: Array in [[-0.44, -0.58, 1.25]]:
		var mb := _cap_pt(mu[0], mu[1])
		var ms: float = mu[2]
		sculpt_put(s, cyl(0.02 * ms, 0.026 * ms, 0.10 * ms, 4), pale, mb + Vector3(0, 0.04 * ms, 0))
		_ell(s, cap_m, mb + Vector3(0, 0.10 * ms, 0), Vector3(0.065, 0.035, 0.065) * ms, 6, 3)
	# ---- the standing-stone ring: a vine ring on the moss, five stones (the front one tall with a glowing tree rune,
	# moss on some tops), a little dolmen at the back
	var ry: float = RIM_Y + _cap_h(RING_RN) + 0.02
	sculpt_add(s, torus(0.72, 0.76, 12), Transform3D(Basis.from_scale(Vector3(SH_X * RING_RN / 0.74, 1.0,
		SH_Z * RING_RN / 0.74)), Vector3(0, ry, SH_CZ)), vine)
	for st: Array in STONES:
		var th: float = st[0]
		var h: float = st[1]
		var w: float = st[2]
		var o := Vector3(sin(deg_to_rad(th)), 0.0, cos(deg_to_rad(th)))
		var base := _ring_pt(th, RING_RN) - Vector3(0, 0.05, 0)
		var bb := _stone_basis(o, st[3], th + float(st[4]))
		var up := bb.y.normalized()
		sculpt_add(s, cyl(w * 0.40, w * 0.5, h, 5), Transform3D(bb * Basis.from_scale(Vector3(1.0, 1.0, 0.55)),
			base + up * (h * 0.5)), stone)
		if th == 0.0 or th == 242.0:
			_ell(s, moss, base + up * (h + 0.005), Vector3(w * 0.42, 0.045, w * 0.26), 6, 3)
		if th == 0.0:
			# the tree rune on the outer face: a trunk line and two pairs of rising branches
			var fz := bb.z.normalized()
			var face := base + fz * (w * 0.5 * 0.55 * 0.9 + 0.012)
			sculpt_add(s, box(Vector3(0.04, 0.32, 0.025)), Transform3D(bb, face + up * 0.44), glow)
			for k: int in 2:
				for sx: float in [-1.0, 1.0]:
					var rb := bb * Basis(Vector3.BACK, -sx * 0.75)
					sculpt_add(s, box(Vector3(0.035, 0.13, 0.025)), Transform3D(rb, face + up * (0.44 + 0.08 * float(k))
						+ bb.x.normalized() * sx * 0.045), glow)
	var tops: Array[Vector3] = []
	for th: float in DOLMEN:
		var o := Vector3(sin(deg_to_rad(th)), 0.0, cos(deg_to_rad(th)))
		var base := _ring_pt(th, RING_RN) - Vector3(0, 0.05, 0)
		var bb := _stone_basis(o, -4.0, th)
		sculpt_add(s, cyl(0.09, 0.11, DOLMEN_H, 5), Transform3D(bb * Basis.from_scale(Vector3(1.0, 1.0, 0.7)),
			base + bb.y * (DOLMEN_H * 0.5)), stone)
		tops.append(base + bb.y * DOLMEN_H)
	var lc := (tops[0] + tops[1]) * 0.5 + Vector3(0, 0.05, 0)
	sculpt_put(s, box(Vector3(0.62, 0.12, 0.22)), stone, lc, Vector3(0, 0, 3.0))
	sculpt_lock(s, moss, lc + Vector3(-0.22, -0.05, -0.10), Vector3(0, -1, -0.1), Vector3(0, 0, -1), 0.10, 0.20, 0.03)
	# ---- team drapes on both flanks (hung from the stone ring over the scutes to the rim): cloth, a dark hem,
	# a dark diamond with a pale leaf, two tassels
	var ct := Transform3D(Basis.IDENTITY, Vector3(0, RIM_Y, SH_CZ))
	for sx: float in [-1.0, 1.0]:
		var a0: float = 34.0
		var a1: float = 82.0
		var lo: float = a0 if sx > 0.0 else -a1
		var hi: float = a1 if sx > 0.0 else -a0
		sculpt_add(s, shell_mesh("mossback_drape2_%s" % sx, DR_X, DR_Y, lo, hi, -0.40, 0.40, 0.03, 6, 2), ct, cloth)
		var h0: float = 78.0 * sx
		var h1: float = 84.0 * sx
		sculpt_add(s, shell_mesh("mossback_hem2_%s" % sx, DR_X + 0.012, DR_Y + 0.012, minf(h0, h1), maxf(h0, h1), -0.41, 0.41, 0.04, 1, 2),
			ct, cdark)
		var ea := deg_to_rad(56.0)
		var nn := Vector3(sin(ea) / DR_X * sx, cos(ea) / DR_Y, 0.0).normalized()
		var pp := Vector3(DR_X * sin(ea) * sx, RIM_Y + DR_Y * cos(ea), SH_CZ) + nn * 0.02
		var tup := (Vector3.UP - nn * Vector3.UP.dot(nn)).normalized()
		var eb := frame(pp, tup, nn).basis
		sculpt_add(s, box(Vector3(0.34, 0.34, 0.03)), Transform3D(eb * Basis(Vector3.BACK, PI * 0.25), pp), cdark)
		sculpt_add(s, sphere(1.0, 4, 2), Transform3D(eb.scaled_local(Vector3(0.075, 0.16, 0.02)), pp + nn * 0.02
			+ eb.y * 0.02), pale)
		sculpt_add(s, box(Vector3(0.018, 0.30, 0.02)), Transform3D(eb, pp + nn * 0.03 - eb.y * 0.03), cdark)
		for l: float in [-0.25, 0.25]:
			var ta := deg_to_rad(84.0)
			var tb := Vector3((DR_X + 0.01) * sin(ta) * sx, RIM_Y + (DR_Y + 0.01) * cos(ta), SH_CZ + l)
			sculpt_lock(s, cdark, tb, Vector3(0.04 * sx, -1.0, 0.0).normalized(), Vector3(sx, 0, 0), 0.08, 0.22, 0.03)


## Basis of a standing stone: faces outward `o`, leans outward by lean_deg, turned by yaw_deg.
static func _stone_basis(o: Vector3, lean_deg: float, yaw_deg: float) -> Basis:
	var b := Basis(Vector3.UP, deg_to_rad(yaw_deg))
	if absf(lean_deg) > 0.01:
		b = Basis(Vector3.UP.cross(o).normalized(), deg_to_rad(lean_deg)) * b
	return b


# ================================================================ head + jaw

func _head_sculpt(s: Dictionary) -> void:
	var skin := m("mossback_skin")
	var scl := m("mossback_scale")
	var beak := m("nature_thorn")
	var dark := m("unit_eye_dark")
	var moss := m("mossback_moss")
	# long wrinkled neck (its back half hides inside the shell; the bite slides it out); a thick fold of skin
	sculpt_add(s, tube_mesh("mossback_neck_v4", PackedVector3Array([Vector3(0, 0.98, 0.86), Vector3(0, 1.02, 1.27),
		Vector3(0, 1.10, 1.46), Vector3(0, 1.10, 1.62), Vector3(0, 1.18, 1.84)]),
		PackedFloat32Array([0.30, 0.29, 0.32, 0.27, 0.25]), 8, true), Transform3D.IDENTITY, skin)
	# skull, cheeks, snout, mouth interior (seen when the jaw opens)
	_ell(s, skin, Vector3(0, 1.26, 2.10) + HO, Vector3(0.34, 0.29, 0.40), 10, 4)
	for sx: float in [-1.0, 1.0]:
		_ell(s, skin, Vector3(0.20 * sx, 1.15, 2.20) + HO, Vector3(0.16, 0.15, 0.21), 6, 3)
	_ell(s, skin, Vector3(0, 1.17, 2.32) + HO, Vector3(0.24, 0.15, 0.21), 6, 3)
	_ell(s, dark, Vector3(0, 1.09, 2.26) + HO, Vector3(0.19, 0.06, 0.19), 6, 3)
	# hooked horn beak + nostrils
	var bd := Vector3(0, -0.45, 1.0).normalized()
	sculpt_add(s, cyl(0.0, 0.17, 0.28, 6), Transform3D(Basis(Quaternion(Vector3.UP, bd)) * Basis.from_scale(Vector3(1.0, 1.0,
		0.75)), Vector3(0, 1.13, 2.44) + HO), beak)
	_ell(s, beak, Vector3(0, 1.21, 2.40) + HO, Vector3(0.12, 0.06, 0.12), 6, 3)
	# heavy scale brows (the eyes: the FaceKit rig above), a head scale, a lichen patch
	for sx: float in [-1.0, 1.0]:
		sculpt_put(s, sphere(1.0, 6, 3), scl, Vector3(0.22 * sx, 1.42, 2.20) + HO, Vector3(-12.0, 25.0 * sx, 14.0 * sx),
			Vector3(0.17, 0.07, 0.15))
	_ell(s, scl, Vector3(0, 1.53, 2.06) + HO, Vector3(0.18, 0.055, 0.19), 6, 3)
	_ell(s, moss, Vector3(0.03, 1.54, 1.90) + HO, Vector3(0.15, 0.06, 0.12), 6, 3)


func _jaw_sculpt(s: Dictionary) -> void:
	var skin := m("mossback_skin")
	var scl := m("mossback_scale")
	var beak := m("nature_thorn")
	_ell(s, skin, Vector3(0, 1.04, 2.24) + HO, Vector3(0.22, 0.10, 0.24), 8, 4)
	_ell(s, scl, Vector3(0, 1.00, 2.12) + HO, Vector3(0.19, 0.07, 0.17), 6, 3)
	var bd := Vector3(0, 0.30, 1.0).normalized()
	sculpt_add(s, cyl(0.0, 0.13, 0.17, 6), Transform3D(Basis(Quaternion(Vector3.UP, bd)) * Basis.from_scale(Vector3(1.0, 1.0,
		0.6)), Vector3(0, 1.03, 2.42) + HO), beak)


# ================================================================ legs

## A splayed elephantine leg rooted at the pivot p: upper limb, elbow knob, a thick scaled forearm, a round foot pad
## with 4 blunt horn claws; overlapping scales on the front (fore) / back (hind) face, a heel spur on the hind legs.
func _leg_sculpt(s: Dictionary, p: Vector3) -> void:
	var skin := m("mossback_skin")
	var scl := m("mossback_scale")
	var claw := m("nature_thorn")
	var sx: float = signf(p.x)
	var front: bool = p.z > 0.0
	var fz: float = 1.0 if front else -1.0
	var e := p + Vector3(0.22 * sx, -0.32, 0.05 * fz)
	var a := Vector3(e.x + 0.02 * sx, 0.28, e.z + 0.05 * fz)
	var key := "%s_%s" % [sx, front]
	sculpt_add(s, tube_mesh("mossback_upleg2_" + key, PackedVector3Array([p + Vector3(0, 0.08, 0), p.lerp(e, 0.5), e]),
		PackedFloat32Array([0.28, 0.30, 0.31]), 6, true), Transform3D.IDENTITY, skin)
	sculpt_add(s, tube_mesh("mossback_foreleg2_" + key, PackedVector3Array([e, e.lerp(a, 0.5), a - Vector3(0, 0.08, 0)]),
		PackedFloat32Array([0.31, 0.29, 0.29]), 6, true), Transform3D.IDENTITY, skin)
	_ell(s, skin, e, Vector3(0.32, 0.30, 0.32), 6, 2)
	var fc := Vector3(a.x, 0.165, a.z + 0.04 * fz)
	_ell(s, scl, fc, Vector3(0.36, 0.14, 0.38), 8, 3)
	for c: int in 3:
		var ang := deg_to_rad(-36.0 + 36.0 * float(c))
		var dir := Vector3(sin(ang), -0.45, cos(ang)).normalized()
		_cone(s, claw, fc + Vector3(sin(ang) * 0.29, 0.02, cos(ang) * 0.31), dir, 0.062, 0.15, 3)
	var axis := (a - e).normalized()
	var faces: Array[Vector3] = [Vector3(0.35 * sx, 0.0, fz).normalized(), Vector3(sx, 0.0, 0.3 * fz).normalized()]
	for t: float in [0.25, 0.62]:
		for fi: int in 1:
			var d: Vector3 = faces[fi]
			var q := e.lerp(a, t) + d * 0.265
			var fb := frame(q, axis, d).basis
			sculpt_add(s, sphere(1.0, 6, 2), Transform3D(fb.scaled_local(Vector3(0.15, 0.14, 0.05)), q), scl)
	if not front:
		_cone(s, claw, fc + Vector3(0, 0.08, -0.28), Vector3(0, 0.2, -1.0), 0.05, 0.12, 3)


# ================================================================ trees

func _tree_sculpt(s: Dictionary, i: int, b: Vector3, c: Vector3) -> void:
	var bark := m(TREE_BARK[i])
	var bend: Vector3 = TREE_BEND[i]
	var rr: Array = TRUNK_R[i]
	var pts := PackedVector3Array([b - Vector3(0, 0.06, 0), b.lerp(c, 0.35) + bend, b.lerp(c, 0.70) - bend * 0.5,
		c + Vector3(0, 0.10, 0)])
	sculpt_add(s, tube_mesh("mossback_trunk2_%d" % i, pts, PackedFloat32Array([rr[0], rr[1], rr[2], rr[3]]), 6, true),
		Transform3D.IDENTITY, bark)
	# roots gripping the moss
	for k: int in 2:
		var ang := TAU * (float(k) / 2.0 + 0.13 * float(i))
		var d := Vector3(cos(ang), 0.0, sin(ang))
		var tip := _cap_pt(b.x + d.x * 0.38, b.z + d.z * 0.38) - Vector3(0, 0.03, 0)
		var mid := _cap_pt(b.x + d.x * 0.20, b.z + d.z * 0.20) + Vector3(0, 0.02, 0)
		sculpt_add(s, tube_mesh("mossback_root2_%d_%d" % [i, k], PackedVector3Array([b + Vector3(0, 0.10, 0) + d * 0.04,
			mid, tip]), PackedFloat32Array([0.065, 0.045, 0.0]), 4, true), Transform3D.IDENTITY, bark)
	# branches up into the crown
	for k: int in 2:
		var ang := TAU * (float(k) / 2.0 + 0.21 * float(i))
		var d := Vector3(cos(ang) * 0.24, 0.12, sin(ang) * 0.24)
		sculpt_add(s, tube_mesh("mossback_branch2_%d_%d" % [i, k], PackedVector3Array([c - Vector3(0, 0.14, 0) + d * 0.1,
			c + d]), PackedFloat32Array([0.045, 0.02]), 4, true), Transform3D.IDENTITY, bark)
	if i == 0:
		# the old tree's bleached dead limb reaching out front-left past the leaves (the asymmetric hook of the
		# silhouette), a fork and a moss beard hanging off it
		var dead := m("nature_stone")
		var r0 := b.lerp(c, 0.55)
		var p1 := r0 + Vector3(-0.36, 0.26, 0.36)
		var p2 := r0 + Vector3(-0.66, 0.52, 0.62)
		var p3 := r0 + Vector3(-0.84, 0.70, 0.74)
		sculpt_add(s, tube_mesh("mossback_deadlimb_v1", PackedVector3Array([r0, p1, p2, p3]),
			PackedFloat32Array([0.07, 0.055, 0.035, 0.0]), 5, true), Transform3D.IDENTITY, dead)
		sculpt_add(s, tube_mesh("mossback_deadtwig_v1", PackedVector3Array([p2 - (p2 - p1) * 0.3,
			p2 + Vector3(0.10, 0.26, 0.12)]), PackedFloat32Array([0.03, 0.0]), 4, true), Transform3D.IDENTITY, dead)
		sculpt_lock(s, m("mossback_moss"), p1.lerp(p2, 0.5), Vector3.DOWN, Vector3(-1, 0, 1).normalized(), 0.10, 0.26, 0.03)


func _crown_sculpt(s: Dictionary, i: int, c: Vector3) -> void:
	var leaf := m("mossback_leaf")
	var pod := m("mossback_lantern")
	var n: int = 0
	for cl: Array in CLUMPS[i]:
		var off: Vector3 = cl[0]
		var r: Vector3 = (cl[1] as Vector3) * Vector3(1.12, 1.0, 1.12)
		off *= Vector3(1.12, 1.0, 1.12)
		sculpt_put(s, sphere(1.0, 8, 4), leaf, c + off, Vector3.ZERO, r)
		# lobes breaking the outline: 3 on the main clump (the other clumps are the crown's own lobes)
		var lobes: int = 3 if n == 0 else 0
		for k: int in lobes:
			var ang := TAU * float(k) / float(lobes) + 0.7 * float(i) + off.x * 3.0
			var u := Vector3(cos(ang) * 0.8, 0.40 + 0.15 * float(k % 2), sin(ang) * 0.8).normalized()
			sculpt_put(s, sphere(1.0, 6, 3), leaf, c + off + u * r * 0.82, Vector3.ZERO, r * 0.45)
		n += 1
	# one amber seed pod per crown: painted, it only lights up with the Canopy (same leaf shader, glow_boost)
	for ln: Vector3 in LANTERNS[i]:
		sculpt_put(s, sphere(1.0, 6, 3), pod, c + ln, Vector3.ZERO, Vector3(0.075, 0.095, 0.075))


# ================================================================ canopy leaf fall

## Glowing leaves drifting down from the crowns while the Canopy is on (additive, world space). Resources shared.
static func _make_leaves() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "CanopyLeaves"
	p.amount = 14
	p.lifetime = 2.6
	p.local_coords = false
	p.fixed_fps = 30
	p.interpolate = true
	p.emitting = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-3.5, -3.5, -3.5), Vector3(7.0, 7.0, 7.0))
	var pm: ParticleProcessMaterial = _fx_cache.get("leaf_pm")
	if pm == null:
		pm = ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(1.05, 0.25, 1.15)
		pm.direction = Vector3.DOWN
		pm.spread = 70.0
		pm.initial_velocity_min = 0.10
		pm.initial_velocity_max = 0.30
		pm.gravity = Vector3(0, -0.30, 0)
		pm.damping_min = 0.2
		pm.damping_max = 0.4
		pm.angle_min = -180.0
		pm.angle_max = 180.0
		pm.angular_velocity_min = -120.0
		pm.angular_velocity_max = 120.0
		pm.scale_min = 0.7
		pm.scale_max = 1.2
		var ramp := GradientTexture1D.new()
		var g := Gradient.new()
		g.set_color(0, Color(0.75, 1.0, 0.42, 0.0))
		g.set_color(1, Color(0.60, 0.95, 0.35, 0.0))
		g.add_point(0.15, Color(0.80, 1.0, 0.45, 0.95))
		g.add_point(0.70, Color(0.70, 1.0, 0.40, 0.70))
		ramp.gradient = g
		pm.color_ramp = ramp
		_fx_cache["leaf_pm"] = pm
	p.process_material = pm
	var q: QuadMesh = _fx_cache.get("leaf_quad")
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(0.20, 0.12)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.billboard_keep_scale = true
		sm.vertex_color_use_as_albedo = true
		sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		var gt := GradientTexture2D.new()
		var tg := Gradient.new()
		tg.set_color(0, Color(1, 1, 1, 1))
		tg.set_color(1, Color(1, 1, 1, 0))
		tg.add_point(0.45, Color(1, 1, 1, 0.55))
		gt.gradient = tg
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 32
		gt.height = 32
		sm.albedo_texture = gt
		q.material = sm
		_fx_cache["leaf_quad"] = q
	p.draw_pass_1 = q
	return p


# ================================================================ lifecycle

func _mount_ready() -> void:
	for i: int in 3:
		if _trees[i]:
			_tree_rest[i] = _trees[i].position
			var mo := model_origin(_trees[i])
			var o := Vector2(mo.x, mo.z - SH_CZ)
			_tree_out[i] = o.normalized() if o.length() > 0.01 else Vector2(0, 1)
		if _crowns[i]:
			_crown_rest[i] = _crowns[i].position
	var extra: Array[MeshInstance3D] = [_jaw_mi]
	extra.append_array(_tree_mi)
	extra.append_array(_crown_mi)
	for mi: MeshInstance3D in extra:
		if mi and not _flash_hit_targets.has(mi):
			_flash_hit_targets.append(mi)
	# the two big crowns cast sun shadows (the body does already): 3 casters; trunks, head and legs do not
	for i: int in 3:
		if _crown_mi[i]:
			_crown_mi[i].cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if CROWN_SHADOW[i] \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if _tree_mi[i]:
			_tree_mi[i].cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# added after the kit's scan: the Canopy (not the distance tier alone) decides when it emits
	if _leaves == null:
		_leaves = _make_leaves()
		$Fx.add_child(_leaves)
		_leaves.position = Vector3(0, 2.35, -0.10)
	if _canopy_instant:
		_canopy_w = 1.0 if _canopy_on else 0.0
		_canopy_v = 0.0
		_canopy_settled = true
		_canopy_instant = false
	_crown_glow_written = -1.0
	_force_trees()


# ================================================================ hooks

## The Canopy aura's look (tier3-extras.md 7.2): on = the crowns spread and glow softly, leaves drift down.
## instant = no transition (spawn with the aura already on). Safe before _ready.
func set_canopy(on: bool, instant: bool = false) -> void:
	if on == _canopy_on and not instant:
		return
	_canopy_on = on
	_canopy_settled = false
	if not _setup_done:
		_canopy_instant = instant
		return
	if on and not _dead:
		_flare = maxf(_flare, 1.0)
		_impulse_trees(Vector2(0.35, 0.6))
	if instant or _tier == 2:
		_canopy_w = 1.0 if on else 0.0
		_canopy_v = 0.0
		_canopy_settled = true
		_crowns_tick()
	set_process(true)


func is_canopy() -> bool:
	return _canopy_on


## 0 = folded .. 1 = fully spread (the spring overshoots a little while opening; clamped here).
func canopy_blend() -> float:
	return clampf(_canopy_w, 0.0, 1.0)


## World position of the beak tip (bite VFX origin), with the current head pose.
func get_bite_point() -> Vector3:
	var h: Node3D = _piv[P_MOUNT_HEAD] if _piv.size() > P_MOUNT_HEAD else null
	if h == null or not h.is_inside_tree():
		return global_position + Vector3(0, 1.0, 2.3) if is_inside_tree() else Vector3(0, 1.0, 2.3)
	return h.global_transform * BEAK_TIP


## World centres of the three crowns (canopy VFX).
func get_canopy_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for c: Node3D in _crowns:
		if c and c.is_inside_tree():
			out.append(c.global_transform * Vector3(0, 0.18, 0))
	return out


func play_hit() -> void:
	var was: float = _hit_t
	super()
	if not _dead and _hit_t < was:
		_impulse_trees(Vector2(-0.9, 0.35))


# ================================================================ motion (on top of MountModel)

func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"shell_bite":
		return super(prev, t)
	pos(P_MOUNT_HEAD, Vector3(0, _mkf(t, BT_HEAD_Y), _mkf(t, BT_HEAD_Z)))
	var shake: float = 0.0
	if t > BITE_HIT and t < 0.5:
		shake = 12.0 * sin(TAU * 5.5 * (t - BITE_HIT)) * (1.0 - smoothstep(0.3, 0.5, t))
	rot(P_MOUNT_HEAD, Vector3(_mkf(t, BT_HEAD_X) * DEG, shake * DEG, -shake * 0.4 * DEG))
	_jaw_pose += _mkf(t, BT_JAW)
	pos(P_ROOT, Vector3(0, 0, _mkf(t, BT_ROOT_Z)))
	rot(P_MOUNT, Vector3(_mkf(t, BT_BODY_X) * DEG, 0, 0))
	var f := _mkf(t, BT_LEG_F) * DEG * (1.0 - 0.6 * _walk_w)
	rot(P_LEG_FL, Vector3(f, 0, 0))
	rot(P_LEG_FR, Vector3(f, 0, 0))
	if prev < BITE_HIT and t >= BITE_HIT:
		_flare = maxf(_flare, 0.6)
		_impulse_trees(Vector2(0.8, 0.0))
		_on_action_event(&"release")
	return t < BITE_LEN


## Idle fidget: the neck stretches out, the old head looks slowly left and right and chews, then a slow shake of the
## shell rustles the grove.
func _pose_fidget(t: float) -> float:
	var out := _k3(t, 0.0, 0.7, 2.2, 3.0, 1.0, 1.0)
	pos(P_MOUNT_HEAD, Vector3(0, 0.06 * out, 0.34 * out))
	var look: float = sin(clampf((t - 0.8) / 1.4, 0.0, 1.0) * TAU) * 26.0 * out
	rot(P_MOUNT_HEAD, Vector3(-14.0 * out * DEG, look * DEG, 0))
	if t > 0.9 and t < 1.9:
		_jaw_pose += 9.0 * maxf(sin((t - 0.9) * TAU * 3.0), 0.0)
	var sh := _k3(t, 2.3, 2.4, 2.75, 2.95, 1.0, 1.0)
	rot(P_MOUNT, Vector3(0, 0, 1.6 * DEG * sin(t * TAU * 6.0) * sh))
	if _fidget_prev < 2.4 and t >= 2.4:
		_impulse_trees(Vector2(0.2, 0.9))
	if _fidget_prev < 1.0 and t >= 1.0:
		_flare = maxf(_flare, 0.4)
		_on_mount_event(&"fidget_snort")
	return 3.0


func _on_footfall(leg: int, _gallop: bool) -> void:
	_impulse_trees(Vector2(0.22, -0.40 if leg % 2 == 0 else 0.40))
	footfall.emit(leg)


func _mount_process(dt: float) -> void:
	_canopy_tick(dt)
	if _face:
		_face.auto(self)
	_wilt = smoothstep(0.1, 0.6, _death_t) if _dead else 0.0
	if not _fast and not _dead:
		if _walk_w > 0.0:
			_walk_extras()
		if _hit_t < HIT_LEN:
			var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
			pos(P_MOUNT_HEAD, Vector3(0, -0.02 * k, -0.22 * k))
	_jaw_tick()
	_trees_tick(dt)
	_crowns_tick()
	if _leaves:
		var want: bool = _canopy_on and _canopy_w > 0.4 and _tier < 2 and not _dead
		if _leaves.emitting != want:
			_leaves.emitting = want


## The heavy stomp on top of the MountModel walk: a dip at each footfall, the legs swing out as they lift (the
## tortoise's rowing gait), a waddle yaw / roll of the shell, the head swaying.
func _walk_extras() -> void:
	var w := _walk_w
	var p := _gait_p
	var dip: float = 0.0
	for k: int in 4:
		var phw: float = fposmod(p - WALK_T[k], 1.0)
		dip += exp(-phw * 16.0)
		var cyc := _leg_cycle(phw, WALK_DUTY)
		var sx: float = -1.0 if (k == 0 or k == 2) else 1.0
		rot(LEGS[k], Vector3(0, 0, sx * 9.0 * DEG * cyc.y * w))
	pos(P_ROOT, Vector3(0, -0.04 * minf(dip, 1.2) * w, 0))
	rot(P_MOUNT, Vector3(0, 1.4 * DEG * sin(TAU * p + 0.5) * w, 1.2 * DEG * sin(TAU * p) * w))
	rot(P_MOUNT_HEAD, Vector3(0, 3.0 * DEG * sin(TAU * p + 1.4) * w, 0))


func _canopy_tick(dt: float) -> void:
	if _canopy_settled or dt <= 0.0:
		return
	var target: float = 1.0 if _canopy_on else 0.0
	var om: float = TAU / (CANOPY_OPEN * 1.45 if _canopy_on else CANOPY_CLOSE * 1.3)
	var zeta: float = 0.55 if _canopy_on else 0.95
	var n: int = maxi(1, ceili(dt / 0.02))
	var h: float = dt / float(n)
	for i: int in n:
		_canopy_v += (om * om * (target - _canopy_w) - 2.0 * zeta * om * _canopy_v) * h
		_canopy_w += _canopy_v * h
	if absf(target - _canopy_w) < 0.003 and absf(_canopy_v) < 0.02:
		_canopy_w = target
		_canopy_v = 0.0
		_canopy_settled = true
		canopy_changed.emit(_canopy_on)


func _jaw_tick() -> void:
	var a: float = 0.0
	if not _dead:
		var ph: float = (_t + _phase_off) * TAU / idle_period
		a = _jaw_pose + (1.2 + 1.2 * sin(ph * 1.3)) if _tier == 0 else _jaw_pose
	_jaw_pose = 0.0
	if _jaw and (a != _jaw_last or _force_write):
		_jaw_last = a
		_jaw.rotation = Vector3(a * DEG, 0, 0)


func _impulse_trees(v: Vector2) -> void:
	for i: int in 3:
		var k: float = 0.8 + 0.2 * float(i)
		_sway_v[i] += Vector2(v.x * k, v.y * k * (1.0 if i != 1 else -0.7))


## Tree sway: a damped spring per tree (breeze, the gait's counter-sway, footfall / hit / bite impulses), plus the
## outward lean of the Canopy and the death wilt.
func _trees_tick(dt: float) -> void:
	var ph: float = _t + _phase_off
	var n: int = maxi(1, ceili(dt / 0.02))
	var h: float = dt / float(n)
	var lean: float = (CANOPY_LEAN_DEG * clampf(_canopy_w, -0.2, 1.3) + 16.0 * _wilt) * DEG
	for i: int in 3:
		var tr := _trees[i]
		if tr == null:
			continue
		var tgt := Vector2(1.1 * sin(0.9 * ph + float(i) * 1.7), 0.9 * sin(0.7 * ph + float(i) * 2.3)) * DEG
		if _walk_w > 0.0 and not _dead:
			var p := _gait_p
			tgt += Vector2(1.6 * sin(2.0 * TAU * p - 0.9), -3.0 * sin(TAU * p - 1.1)) * DEG * _walk_w
		if dt > 0.0:
			for k: int in n:
				var acc: Vector2 = (tgt - _sway[i]) * SW_K - _sway_v[i] * SW_D
				_sway_v[i] += acc * h
				_sway[i] += _sway_v[i] * h
		var o: Vector2 = _tree_out[i]
		var r := Vector3(_sway[i].x + lean * o.y, 0.0, _sway[i].y - lean * o.x)
		if r != _tree_last[i] or _force_write:
			_tree_last[i] = r
			tr.rotation = r


## Crown spread (scale about the crown base) and glow from the Canopy blend; the death wilt shrinks and drops them.
func _crowns_tick() -> void:
	var w := _canopy_w * (1.0 - _wilt)
	var sc := Vector3(1.0 + (CROWN_SPREAD.x - 1.0) * w, 1.0 + (CROWN_SPREAD.y - 1.0) * w, 1.0 + (CROWN_SPREAD.z - 1.0) * w)
	sc *= 1.0 - 0.28 * _wilt
	sc.y *= 1.0 - 0.15 * _wilt
	var dy: float = 0.05 * w - 0.12 * _wilt
	if sc != _crown_last_s or dy != _crown_last_dy or _force_write:
		_crown_last_s = sc
		_crown_last_dy = dy
		for i: int in 3:
			var c := _crowns[i]
			if c:
				c.scale = sc
				c.position = _crown_rest[i] + Vector3(0, dy, 0)
	var g: float = 0.0
	if not _glows_off:
		g = lerpf(CROWN_GLOW_OFF, CROWN_GLOW_ON, clampf(w, 0.0, 1.15)) * (1.0 + 0.35 * _flare)
	if absf(g - _crown_glow_written) > 0.01 or (g == 0.0 and _crown_glow_written != 0.0):
		_crown_glow_written = g
		for mi: MeshInstance3D in _crown_mi:
			if mi:
				mi.set_instance_shader_parameter(&"glow_boost", g)


func _force_trees() -> void:
	for i: int in 3:
		_tree_last[i] = Vector3(INF, 0, 0)
	_crown_last_s = Vector3(INF, 0, 0)
	_jaw_last = INF
	_trees_tick(0.0)
	_crowns_tick()
	_jaw_tick()


## Death (SINK_DEATH_LEN 1.6 s): a shudder, the head and neck slide back into the shell and the legs tuck in
## (0-0.45 s), the shell drops onto its plastron (death_down), the crowns wilt, the glows die at 0.38 s, then the whole
## tortoise sinks into the ground (0.55-1.6 s, slowing its fall at first) and the blob fades; death_finished at the end.
func _pose_death(dt: float) -> void:
	var prev := _death_t
	_death_t += dt
	var t := _death_t
	var k: float = _ease_out(clampf(t / RETRACT_LEN, 0.0, 1.0))
	pos(P_MOUNT_HEAD, Vector3(0, -0.05 * k, -0.62 * k))
	rot(P_MOUNT_HEAD, Vector3(10.0 * DEG * k, 0, 0))
	for i: int in 4:
		var sx: float = -1.0 if (i == 0 or i == 2) else 1.0
		var front: bool = i < 2
		pos(LEGS[i], Vector3(-0.16 * sx * k, 0.40 * k, 0.0))
		rot(LEGS[i], Vector3((20.0 if front else -20.0) * DEG * k, 0, -sx * 26.0 * DEG * k))
	var shudder: float = 2.5 * sin(t * 38.0) * (1.0 - smoothstep(0.0, 0.5, t))
	rot(P_MOUNT, Vector3(0, 0, shudder * DEG))
	var s: float = clampf((t - 0.55) / (SINK_DEATH_LEN - 0.55), 0.0, 1.0)
	s = s * s * (3.0 - 2.0 * s) * 0.35 + s * s * 0.65
	pos(P_ROOT, Vector3(0, -0.33 * k - SINK_DEPTH * s, 0))
	rot(P_ROOT, Vector3(3.0 * DEG * s, 0, 1.5 * DEG * s))
	_root_scale *= 1.0 - 0.12 * s
	if t >= 0.38:
		_glows_dead()
	if prev < RETRACT_LEN and t >= RETRACT_LEN:
		_on_mount_event(&"death_down")
	if _shadow:
		# the blob shader ignores GeometryInstance3D.transparency: fade its tint instead
		var fade: float = clampf((t - 0.6) / 0.6, 0.0, 1.0)
		_shadow.transparency = fade
		_shadow.set_instance_shader_parameter(&"blob_color", Color(BLOB_TINT, BLOB_TINT.a * (1.0 - fade)))
	if t >= SINK_DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


func _mount_revive() -> void:
	_wilt = 0.0
	if _face:
		_face.reset()
	if _shadow:
		_shadow.set_instance_shader_parameter(&"blob_color", BLOB_TINT)
	_jaw_pose = 0.0
	_canopy_w = 1.0 if _canopy_on else 0.0
	_canopy_v = 0.0
	_canopy_settled = true
	for i: int in 3:
		_sway[i] = Vector2.ZERO
		_sway_v[i] = Vector2.ZERO
	_crown_glow_written = -1.0
	_force_trees()

extends Node3D
## Dusk Keep ("Umbral Spire") visual model: idle animation + the state hooks of art-keep.md 8.2-8.8.
## The geometry is built by art/buildings/dusk_keep_build.gd (run it WINDOWED to regenerate dusk_keep.tscn:
## headless drops MultiMesh buffers). Every hook is safe to call before _ready (cached, applied in _ready).

signal destroyed_finished

const PVC := preload("res://art/buildings/painted_vc.gd")
const DEFAULT_TEAM := Color(0.42, 0.22, 0.60)
const GLOW_DEFAULT := Color(0.70, 0.30, 1.00)
const IDLE_RIM := Color(0.55, 0.5, 0.7) # 3.V2b rim so the dark needle reads at 40 m (G-F r2: slate lilac, was 0.62 0.42 1.0)
const IDLE_RIM_STRENGTH := 0.45
## G-F round 2 (docs/art/gf_r2_buildings_fs.md, gf_review2 item 3): the keep's two lights tinted the whole body violet
## (the default team kept a full-saturation spire light, other teams a lightened one, so the player's keep was the
## loudest object in a mirror). Both lights now take the team glow graded to LIGHT_SAT for every team, and the spire
## light is dimmer: the sides differ by hue, not by saturation. The glow parts (seams, slits, eye) keep the full glow.
const LIGHT_SAT := 0.4
const SPIRE_ENERGY := 1.3
const GATE_ENERGY := 1.0
const CRACK_ENERGY := 0.7   ## emission of the merged body's violet veins (painted_vc crack_energy; 1 = before)
const RING_SPEED := deg_to_rad(-8.0)
const SHARD_SPIN := deg_to_rad(-20.0)
## Rune ring emission (G-E fixes D: 3.0 -> 1.0, under the glow cap's knee; the violet glows are accents, not panels); halved under 50 % HP.
const RING_ENERGY := 1.0
const MOTE_SPIN := 0.12 * TAU
const HEIGHT := 17.5 # model-space height used by the construction rise (8.2)
const VIS := 1.12 # Model's visual scale (dusk_keep_build.gd VISUAL_SCALE)
const SHARD_Y := 16.6
const FIN_TILT := deg_to_rad(18.0)
const FIN_LEN := 4.6
const FIN_CURVE := 0.35
const FIN_BASE := Vector2(2.35, 5.9) # radius, height of each thorn blade's root
const EYE_ORBIT_SPEED := deg_to_rad(55.0) # the splinters counter-orbit the eye
const NEEDLE_FACE := 180.0 # the watch-needle's face (degrees from -Z)
const FLOATING: Array[StringName] = [&"RuneRing", &"Shard", &"LanternOrb1", &"LanternOrb2", &"LanternOrb3"]
const TOPPLE: Array[StringName] = [&"Prism2", &"Prism3", &"Tip", &"SpireBands", &"Thorns"]
const NO_CRUSH: Array[StringName] = [&"Plinth", &"Rubble", &"Rubble2", &"WatchNeedle"]
## G-B: tier looks (DuskKeepTiers), shown by set_tier, never part of the construction rise.
const TIER_NODES: Array[StringName] = [&"Tier2", &"Tier3", &"UpgradeRig"]
const TIERS := preload("res://art/buildings/dusk_keep_tiers.gd")
const RING2_SPEED := deg_to_rad(14.0)
const HALO_SPEED := deg_to_rad(-26.0)
const TIER_UP_TIME := 1.4
## Bottom / top (model space) of parts whose AABB is unreliable (MultiMeshes are empty headless).
const SPANS := {
	&"Fins": Vector2(5.8, 10.2), &"FinTips": Vector2(9.8, 10.6), &"Rubble": Vector2(0.0, 1.0),
	&"GateSlits": Vector2(1.3, 5.2), &"LanternStems": Vector2(1.2, 2.4), &"Buttresses": Vector2(0.7, 5.45),
	&"CapTeeth": Vector2(6.4, 7.5), &"Windows": Vector2(6.7, 8.0), &"Thorns": Vector2(13.3, 15.6),
}

var _team_color: Color = DEFAULT_TEAM
var _health_ratio: float = 1.0
var _progress: float = 1.0
var _selected: bool = false
var _destroyed: bool = false
var _t: float = 0.0
var _pulse_t: float = 10.0
var _ring_mult: float = 1.0
var _shard_bob: float = 0.3
var _shard_spin: float = SHARD_SPIN
var _agitated: bool = false
var _rumble: bool = false
var _sel: float = 0.0
var _fin_tilt: float = FIN_TILT
var _fins_broken: bool = false
var _floating_shown: bool = true
var _needle_lean: float = 0.0
var _painted_mats: Array[ShaderMaterial] = []
var _glow_mat: ShaderMaterial
var _banner_mat: ShaderMaterial
var _ground_mat: ShaderMaterial
var _sel_tween: Tween
var _float_tween: Tween
var _outline_tween: Tween
var _ready_done: bool = false
var _parts: Array[Node3D] = [] # rising parts (construction) in model space
var _spans: Array[Vector2] = []
var _orig: Dictionary = {} # Node3D -> Transform3D
var _tier: int = 1
var _upgrading: bool = false
var _tier_t: float = 10.0 # time since play_tier_up
var _tn: Dictionary = {} # DuskKeepTiers.build() nodes (empty before _ready)
var _dress: ShadowDress

@onready var _model: Node3D = $Model
@onready var _ring: GeometryInstance3D = $Model/RuneRing
@onready var _shard: Node3D = $Model/Shard
@onready var _shard_core: GeometryInstance3D = $Model/Shard/ShardCore
@onready var _eye_orbit: Node3D = $Model/Shard/EyeOrbit
@onready var _needle: Node3D = $Model/WatchNeedle
@onready var _debris: GPUParticles3D = $Debris
@onready var _orbs: Array[Node3D] = [$Model/LanternOrb1, $Model/LanternOrb2, $Model/LanternOrb3]
@onready var _slits: GeometryInstance3D = $Model/GateSlits
@onready var _fins: MultiMeshInstance3D = $Model/Fins
@onready var _tips: MultiMeshInstance3D = $Model/FinTips
@onready var _rubble: Node3D = $Model/Rubble
@onready var _rubble2: Node3D = $Model/Rubble2
@onready var _banners: Array[Node3D] = [$Model/Banner1, $Model/Banner2, $Model/Banner3]
@onready var _stems: Node3D = $Model/LanternStems
@onready var _spire_light: OmniLight3D = $SpireLight
@onready var _gate_light: OmniLight3D = $GateLight
@onready var _motes: GPUParticles3D = $VoidMotes
@onready var _mist: GPUParticles3D = $GroundMist
@onready var _mist2: GPUParticles3D = $GroundMist2
@onready var _sparks: GPUParticles3D = $Model/Shard/ShardSparks
@onready var _smoke: Array[GPUParticles3D] = [$Smoke1, $Smoke2]
@onready var _rifts: Array[GPUParticles3D] = [$Rift1, $Rift2]
@onready var _burst: GPUParticles3D = $TrainBurst
@onready var _build_ring: GPUParticles3D = $BuildRing
@onready var _dust: GPUParticles3D = $CollapseDust
@onready var _outline: GeometryInstance3D = $Outline
@onready var _decal: GeometryInstance3D = $ContactDecal


## Horizontal unit vector `deg` degrees from -Z toward +X (art-keep.md face convention).
static func dir(deg: float) -> Vector3:
	var th: float = deg_to_rad(deg)
	return Vector3(sin(th), 0.0, -cos(th))


## Thorn blade i (0-5, on the hex corners 30 + 60 i) with its outward tilt; shared with the build script.
static func fin_xf(i: int, tilt: float) -> Transform3D:
	var r: Vector3 = dir(30.0 + 60.0 * i)
	var b := Basis(Vector3.UP.cross(r), Vector3.UP, r) * Basis(Vector3.RIGHT, tilt)
	return Transform3D(b, r * FIN_BASE.x + Vector3(0.0, FIN_BASE.y, 0.0))


## The glowing crystal floating just above blade i's point.
static func fin_tip_xf(i: int, tilt: float) -> Transform3D:
	var f: Transform3D = fin_xf(i, tilt)
	return Transform3D(Basis(), f * Vector3(0.0, FIN_LEN + 0.38, FIN_CURVE + 0.05))


## Rest position of soul-lantern orb i: beside the gate, atop the watch-needle, on face 240.
static func orb_pos(i: int) -> Vector3:
	match i:
		0: return Vector3(1.55, 2.7, -2.35)
		1: return dir(NEEDLE_FACE) * 2.42 + Vector3(0.0, 11.95, 0.0)
		_: return dir(240.0) * 2.4 + Vector3(0.0, 2.7, 0.0)


func _ready() -> void:
	_make_unique_materials()
	_merge_painted()
	# Per-keep copies of what the states edit (the .tscn resources are shared by every instance).
	_fins.multimesh = _fins.multimesh.duplicate() as MultiMesh
	_tips.multimesh = _tips.multimesh.duplicate() as MultiMesh
	_burst.process_material = _burst.process_material.duplicate() as ParticleProcessMaterial
	_build_ring.process_material = _build_ring.process_material.duplicate() as ParticleProcessMaterial
	for c: Node in _model.get_children():
		var n := c as Node3D
		if n == null:
			continue
		_orig[n] = n.transform
		if n.name in FLOATING or n == _rubble2 or n.name in TIER_NODES:
			continue
		_parts.append(n)
		_spans.append(_span_of(n))
	# G-B: tier-scaled dressing (dead ground, mist, wisps, embers; nothing at Low). World metres (root space).
	_dress = ShadowDress.attach(self, {"radius": 8.6, "inner": 3.5, "top": 18.0, "mist": 4.4, "seed": 3.3,
		"wisp_r": 3.0, "wisp_y": Vector2(1.6, 9.0), "glow": _glow_color(),
		"embers": [Vector3(1.4, 5.2, 1.2), Vector3(-1.1, 9.4, 0.6), Vector3(0.6, 2.6, -2.4)]})
	_ready_done = true
	_update_fins()
	set_team_color(_team_color)
	set_construction_progress(_progress)
	set_health_ratio(_health_ratio)
	_set_sel(1.0 if _selected else 0.0)
	_apply_tier()


func _span_of(n: Node3D) -> Vector2:
	if SPANS.has(n.name):
		return SPANS[n.name]
	var gi := n as GeometryInstance3D
	if gi == null:
		return Vector2(n.position.y, n.position.y)
	var box: AABB = n.transform * (gi as VisualInstance3D).get_aabb()
	return Vector2(box.position.y, box.end.y)


## Materials in the .tscn are shared by every instance: duplicate them once so selecting or
## damaging one keep never changes another.
func _make_unique_materials() -> void:
	var dups: Dictionary = {}
	for node: Node in find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		var mat := gi.material_override
		if mat == null or not (mat is ShaderMaterial):
			continue
		if not dups.has(mat):
			var d: ShaderMaterial = (mat as ShaderMaterial).duplicate()
			dups[mat] = d
			var path: String = d.shader.resource_path
			if path.ends_with("glow.gdshader"):
				_glow_mat = d
			elif path.ends_with("banner.gdshader"):
				_banner_mat = d
			elif path.ends_with("ground.gdshader"):
				_ground_mat = d
			else:
				_painted_mats.append(d)
		gi.material_override = dups[mat]


## B8 (art-keep.md 9: <= 8 materials): the four painted stones (DarkStone, Stone, Silver, Obsidian: same crack
## colour / speed / scale) and the gate void become ONE vertex-coloured material (PaintedVC, painted_vc shader: the
## same shading). The body is the first per-keep painted copy, so the damage / rim loops still reach it.
func _merge_painted() -> void:
	if _painted_mats.is_empty():
		return
	var holes: Array = []
	for node: Node in find_children("*", "GeometryInstance3D", true, false):
		var m: Material = (node as GeometryInstance3D).material_override
		var sm := m as StandardMaterial3D
		if sm == null or holes.has(sm):
			continue
		if sm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and sm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
			holes.append(sm)
	_add_carving()
	_add_tiers()
	var body: ShaderMaterial = _painted_mats[0]
	PVC.convert(self, body, [], holes)
	body.set_shader_parameter(&"crack_energy", CRACK_ENERGY)   # G-F round 2: the needle veins are seams, not panels
	# B2 (keep: <= 32 draws): now that they share one material, fold four static painted parts into their neighbour
	# (same material, same place): the cap into the body, the buttresses into the body, the arch into the gate
	# frame, the collars into the watch-needle (they tilt with it). One mesh each, baked once for every keep.
	for pair: Array in [["Body", "BodyCap"], ["Body", "Buttresses"], ["GateFrame", "GateArch"],
			["WatchNeedle", "WatchNeedle/WatchCollars"]]:
		_fold(pair[0], pair[1], body)


static var _fold_cache: Dictionary = {}
const BMG := preload("res://art/buildings/fire_hall_merge.gd")


## 2026-09-30 detail pass (Art Lab C2 / C3: the keep used a fifth of its vertex budget): two carved string courses round
## the battered body (a proud block on each face, a paler and a deeper stone), silver rune studs between them, and
## a ring of fallen masonry on the upper plinth step. One part (it rises with the body), drawn by the merged material.
func _add_carving() -> void:
	var stone: ShaderMaterial = null
	var silver: ShaderMaterial = null
	for m: ShaderMaterial in _painted_mats:
		if m.resource_name == "Stone":
			stone = m
		elif m.resource_name == "Silver":
			silver = m
	if stone == null or silver == null:
		return
	var pale: ShaderMaterial = stone.duplicate() as ShaderMaterial
	pale.set_shader_parameter(&"base_color", Color(0.3, 0.27, 0.38))
	var deep: ShaderMaterial = stone.duplicate() as ShaderMaterial
	deep.set_shader_parameter(&"base_color", Color(0.17, 0.14, 0.23))
	var vio: ShaderMaterial = stone.duplicate() as ShaderMaterial   # a violet-veined stone for the studs' settings
	vio.set_shader_parameter(&"base_color", Color(0.36, 0.26, 0.5))
	var box := BoxMesh.new()
	var stud := CylinderMesh.new()
	stud.top_radius = 0.07
	stud.bottom_radius = 0.1
	stud.height = 0.1
	stud.radial_segments = 6
	stud.rings = 0
	var it: Array = []
	for course: int in 3:
		var y: float = 1.2 + [1.4, 3.3, 4.75][course]
		var r: float = lerpf(2.55, 2.3, (y - 1.2) / 5.0)
		var ap: float = r * 0.866
		for i: int in 6:
			var a: float = deg_to_rad(-30.0 + 60.0 * i)
			var n := Vector3(cos(a), 0.0, sin(a))
			var b := Basis(Vector3.UP, -a + PI * 0.5)
			it.append(BMG.item_xf(box, Transform3D(b.scaled_local(Vector3(r * 0.92, 0.26, 0.14)), n * (ap + 0.04) + Vector3(0, y, 0)),
				pale if (i + course) % 2 == 0 else deep))
			if course == 2:
				continue
			for k: int in 3:
				var t: float = -0.3 + 0.3 * float(k)
				it.append(BMG.item_xf(stud, Transform3D(b * Basis(Vector3.RIGHT, PI * 0.5), n * (ap + 0.12) +
					b * Vector3(t * r, 0, 0) + Vector3(0, y + 0.95, 0)), silver if k != 1 else vio))
	var shard := CylinderMesh.new()
	shard.top_radius = 0.0
	shard.bottom_radius = 0.16
	shard.height = 0.7
	shard.radial_segments = 5
	shard.rings = 0
	for i: int in 18:
		var a2: float = deg_to_rad(10.0 + 20.0 * float(i))
		var n2 := Vector3(cos(a2), 0.0, sin(a2))
		var sz := Vector3(0.34 + 0.08 * float(i % 3), 0.16 + 0.04 * float(i % 2), 0.26)
		it.append(BMG.item_xf(box, Transform3D(Basis(Vector3.UP, -a2 + 0.3 * float(i % 3)).scaled_local(sz),
			n2 * 2.4 + Vector3(0, 1.2 + sz.y * 0.5, 0)), [deep, pale, vio][i % 3]))
		if i % 3 == 1:   # obsidian splinters stuck in the rubble
			var lb := Basis(Vector3.UP.cross(n2).normalized(), deg_to_rad(-25.0 - 5.0 * float(i % 2)))
			it.append(BMG.item_xf(shard, Transform3D(lb, n2 * 2.5 + Vector3(0, 1.45, 0)), deep))
	var mi := MeshInstance3D.new()
	mi.name = "Carving"
	mi.mesh = BMG.mesh_for("dusk_keep/carving", it)
	var mats: Array[Material] = BMG.materials_of(it)
	for i: int in mats.size():
		mi.set_surface_override_material(i, mats[i])
	_model.add_child(mi)


## G-B: the Stronghold / Citadel looks and the upgrade rig (DuskKeepTiers), built hidden before the painted merge so
## their stone folds into the body material like the carving.
func _add_tiers() -> void:
	var m := {}
	for pm: ShaderMaterial in _painted_mats:
		match pm.resource_name:
			"DarkStone": m["dark"] = pm
			"Stone": m["stone"] = pm
			"Silver": m["silver"] = pm
			"Obsidian": m["obsidian"] = pm
	if m.size() < 4 or _glow_mat == null or _banner_mat == null:
		return
	_tn = TIERS.build(_model, m, _glow_mat, _banner_mat)


## Appends part `from_path`'s painted geometry (every instance of a MultiMesh) to the painted surface of
## `into_path` (both under Model, both already drawn by `body` only) and removes `from_path`.
func _fold(into_path: String, from_path: String, body: ShaderMaterial) -> void:
	var into := _model.get_node_or_null(into_path) as MeshInstance3D
	var from := _model.get_node_or_null(from_path) as GeometryInstance3D
	if into == null or from == null or into.mesh == null or into.get_surface_override_material(0) != body:
		return
	var src_mesh: Mesh = null
	var xfs: Array[Transform3D] = []
	var rel: Transform3D = into.global_transform.affine_inverse() * from.global_transform
	if from is MeshInstance3D:
		src_mesh = (from as MeshInstance3D).mesh
		var mi_ok: bool = src_mesh != null and (from as MeshInstance3D).get_surface_override_material(0) == body
		if not mi_ok or src_mesh.get_surface_count() != 1:
			return
		xfs.append(rel)
	elif from is MultiMeshInstance3D:
		var mm := (from as MultiMeshInstance3D).multimesh
		if mm == null or mm.mesh == null or from.material_override != body or mm.mesh.get_surface_count() != 1:
			return
		src_mesh = mm.mesh
		for i: int in mm.instance_count:
			xfs.append(rel * mm.get_instance_transform(i))
	if src_mesh == null:
		return
	var key := "%s+%s|%d|%d" % [into_path, from_path, into.mesh.get_instance_id(), src_mesh.get_instance_id()]
	if not _fold_cache.has(key):
		var am := ArrayMesh.new()
		for s: int in into.mesh.get_surface_count():
			if s == 0:
				var st := SurfaceTool.new()
				st.create_from(into.mesh, 0)
				for xf: Transform3D in xfs:
					st.append_from(src_mesh, 0, xf)
				st.commit(am)
			else:
				am.add_surface_from_arrays(into.mesh.surface_get_primitive_type(s), into.mesh.surface_get_arrays(s))
		_fold_cache[key] = am
	var mats: Array[Material] = []
	for s: int in into.mesh.get_surface_count():
		mats.append(into.get_surface_override_material(s))
	into.mesh = _fold_cache[key]
	for s: int in mats.size():
		into.set_surface_override_material(s, mats[s])
	from.get_parent().remove_child(from)
	from.queue_free()


func _process(delta: float) -> void:
	_t += delta
	var fast: float = 1.0
	if _pulse_t < 0.6:
		_pulse_t += delta
		fast = 3.0
		var k: float = _pulse_t / 0.6
		var b: float = 1.0 + 2.0 * (1.0 - k) * (1.0 - k) if _pulse_t > 0.1 else 1.0 + 20.0 * _pulse_t
		_slits.set_instance_shader_parameter(&"boost", b)
		if _pulse_t >= 0.6:
			_slits.set_instance_shader_parameter(&"boost", 1.0)
	if _destroyed:
		if _rumble:
			_model.position = Vector3(sin(_t * TAU * 15.0) * 0.08, 0.0, cos(_t * TAU * 13.0) * 0.08)
		return
	_ring.rotation.y += RING_SPEED * _ring_mult * fast * delta
	_shard.position.y = SHARD_Y + _shard_bob * sin(_t * 1.57)
	_shard.rotation.y += _shard_spin * delta
	_eye_orbit.rotation.y += (EYE_ORBIT_SPEED - _shard_spin) * fast * delta
	for i: int in 3:
		_orbs[i].position.y = orb_pos(i).y + 0.1 * sin(_t * 2.5 + float(i))
	_motes.rotation.y += MOTE_SPIN * delta
	var breath: float = 0.85 + 0.15 * sin(_t * 2.1)
	if _agitated:
		breath = 0.75 + 0.25 * sin(_t * TAU * 4.0)
	var p: float = _progress
	_spire_light.light_energy = SPIRE_ENERGY * breath * p
	_gate_light.light_energy = GATE_ENERGY * (0.85 + 0.15 * sin(_t * 2.1)) * p * (2.0 if _pulse_t < 0.3 else 1.0)
	_process_tiers(delta)


## G-B tier looks: the second rune ring and the halo turn, the upgrade beams breathe, the tier-up flash fades.
func _process_tiers(delta: float) -> void:
	if _tn.is_empty():
		return
	if _tier >= 2:
		(_tn["ring2"] as Node3D).rotation.y += RING2_SPEED * _ring_mult * delta
	if _tier >= 3:
		(_tn["halo"] as Node3D).rotation.y += HALO_SPEED * delta
	if _upgrading:
		_ring.rotation.y += RING_SPEED * 3.0 * delta   # the rune ring races while the keep grows
		var beams: Array[MeshInstance3D] = _tn["beams"]
		for i: int in beams.size():
			var k: float = fmod(_t * 0.45 + float(i) / 6.0, 1.0)
			beams[i].scale = Vector3(1.0, 1.0 + 9.0 * k, 1.0)
			beams[i].position.y = 0.7 + 4.5 * k
			beams[i].transparency = k * k
	if _tier_t < TIER_UP_TIME:
		_tier_t += delta
		var f: float = 1.0 - clampf(_tier_t / TIER_UP_TIME, 0.0, 1.0)
		_glow_mat.set_shader_parameter(&"boost_mult", lerpf(1.0, 1.4, _sel) * (1.0 + 2.5 * f * f))
		_spire_light.light_energy += 6.0 * f * f
		# The new tier's parts grow up out of the plinth in 0.6 s with a small overshoot.
		var pop: float = minf(_tier_t / 0.6, 1.0)
		var newest: Node3D = _tn["t3"] if _tier >= 3 else _tn["t2"]
		newest.scale = Vector3(1.0, maxf(0.01, ease(pop, 0.4) * (1.0 + 0.12 * sin(pop * PI))), 1.0)
		if _tier_t >= TIER_UP_TIME:
			newest.scale = Vector3.ONE
			_apply_rim()


# --- Hooks (art-keep.md 8.8) ---------------------------------------------------------------

func set_team_color(c: Color) -> void:
	_team_color = c
	if not _ready_done:
		return
	var glow: Color = _glow_color()
	var is_default: bool = c.is_equal_approx(DEFAULT_TEAM)
	var cloth: Color = Color(0.25, 0.12, 0.38) if is_default else c.darkened(0.4)
	_glow_mat.set_shader_parameter(&"glow_color", glow)
	_banner_mat.set_shader_parameter(&"cloth_color", cloth)
	_banner_mat.set_shader_parameter(&"glyph_color", glow)
	_ground_mat.set_shader_parameter(&"glow_color", glow)
	(_burst.process_material as ParticleProcessMaterial).color = glow
	(_build_ring.process_material as ParticleProcessMaterial).color = glow
	_spire_light.light_color = light_tint(glow)
	_gate_light.light_color = light_tint(glow)
	if _dress:
		_dress.set_glow(glow)
	_apply_rim()


func set_health_ratio(r: float) -> void:
	_health_ratio = clampf(r, 0.0, 1.0)
	if not _ready_done or _destroyed:
		return
	var below50: bool = _health_ratio < 0.5
	var below25: bool = _health_ratio < 0.25
	var dmg: float = 1.0 if below25 else (0.6 if below50 else (1.0 - _health_ratio) * 0.5)
	for m: ShaderMaterial in _painted_mats:
		m.set_shader_parameter(&"damage", dmg)
	_ground_mat.set_shader_parameter(&"damage", dmg)
	var built: bool = _progress >= 1.0
	for s: GPUParticles3D in _smoke:
		s.emitting = below50 and built
	for s: GPUParticles3D in _rifts:
		s.emitting = below25 and built
	_fins_broken = below50
	_update_fins()
	_rubble2.visible = below50 and _progress > 0.0
	_ring_mult = 3.0 / 8.0 if below50 else 1.0
	_ring.set_instance_shader_parameter(&"energy", RING_ENERGY * 0.5 if below50 else RING_ENERGY)
	_shard_bob = 0.6 if below25 else 0.3
	_shard_spin = deg_to_rad(-60.0) if below25 else SHARD_SPIN
	_agitated = below25
	# Under 25 % the watch-needle cracks at its root and leans 7 deg away from the keep.
	_needle_lean = deg_to_rad(7.0) if below25 and built else 0.0
	if built:
		_needle.transform = _needle_xf(_needle_lean)
	if built:
		_banners[0].visible = not below25
	if _dress:
		_dress.sync(_progress, _health_ratio, false)


func set_construction_progress(p: float) -> void:
	var was: float = _progress
	_progress = clampf(p, 0.0, 1.0)
	if not _ready_done or _destroyed:
		return
	var done: bool = _progress >= 1.0
	var h: float = _progress * HEIGHT
	for i: int in _parts.size():
		var n: Node3D = _parts[i]
		var sp: Vector2 = _spans[i]
		if done:
			n.visible = true
			n.transform = _orig[n]
			continue
		n.visible = h >= sp.x and _progress > 0.0
		var s: float = clampf((h - sp.x) / maxf(sp.y - sp.x, 0.01), 0.05, 1.0)
		_squash(n, s, sp.x)
	# Floating parts pop in at 95 % with a 0.5 s scale-in.
	var show_float: bool = _progress >= 0.95
	if show_float != _floating_shown:
		_floating_shown = show_float
		if _float_tween:
			_float_tween.kill()
		for nm: StringName in FLOATING:
			var f: Node3D = _model.get_node(NodePath(nm))
			f.visible = show_float
			f.scale = Vector3.ONE * (0.01 if show_float else 1.0)
		if show_float:
			_float_tween = create_tween().set_parallel(true)
			for nm: StringName in FLOATING:
				_float_tween.tween_property(_model.get_node(NodePath(nm)), "scale", Vector3.ONE, 0.5) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ground_mat.set_shader_parameter(&"build", _progress)
	_motes.emitting = done
	_mist.emitting = done
	_sparks.emitting = done
	_build_ring.emitting = not done
	if _outline_tween:
		_outline_tween.kill()
	if not done:
		_outline.visible = true
		_outline.set_instance_shader_parameter(&"energy", 2.0)
	elif was < 1.0:
		# Finished: outline fades out, flash from the top, damage looks come back.
		_outline_tween = create_tween()
		_outline_tween.tween_method(func(e: float) -> void:
			_outline.set_instance_shader_parameter(&"energy", e), 2.0, 0.0, 0.5)
		_outline_tween.tween_callback(_outline.hide)
		_fire_burst(Vector3(0, 16.5 * VIS, 0), Vector3.UP, 180.0, 2.0, 5.0, 40.0 / 72.0)
	else:
		_outline.visible = false
	_apply_rim()
	_apply_tier()
	if _dress:
		_dress.sync(_progress, _health_ratio, false)
	if done and was < 1.0:
		set_health_ratio(_health_ratio)


func play_training_pulse() -> void:
	if _destroyed:
		return
	_pulse_t = 0.0
	_fire_burst(Vector3(0, 2.0, -2.8) * VIS, Vector3(0, 0, -1), 60.0, 2.0, 4.0, 1.0 / 3.0)


## Keep tier 1 Keep / 2 Stronghold / 3 Citadel (Keep._show_tier): the tier parts show at once (loads, campaign
## start tiers); play_tier_up adds the flourish after a finished upgrade. Safe before _ready.
func set_tier(t: int) -> void:
	_tier = clampi(t, 1, 3)
	_apply_tier()


## While the keep upgrades: soul-fire beams rise round the plinth, the rune ring races, the build ring glows.
func set_upgrading(on: bool) -> void:
	_upgrading = on
	_apply_tier()


## The upgrade finished: the new tier's parts grow out of the plinth, a burst from the eye, the glows flare.
func play_tier_up() -> void:
	if _destroyed or not _ready_done or _tn.is_empty():
		return
	_tier_t = 0.0
	_fire_burst(Vector3(0, SHARD_Y * VIS, 0), Vector3.UP, 180.0, 3.0, 6.5, 1.0)


func _apply_tier() -> void:
	if not _ready_done or _tn.is_empty():
		return
	var built: bool = _progress >= 1.0 and not _destroyed
	(_tn["t2"] as Node3D).visible = built and _tier >= 2
	(_tn["t3"] as Node3D).visible = built and _tier >= 3
	(_tn["rig"] as Node3D).visible = built and _upgrading
	if built:
		_build_ring.emitting = _upgrading


func set_selected(on: bool) -> void:
	_selected = on
	if not _ready_done:
		return
	if _sel_tween:
		_sel_tween.kill()
	_sel_tween = create_tween()
	_sel_tween.tween_method(_set_sel, _sel, 1.0 if on else 0.0, 0.15 if on else 0.25)


## The 3.0 s collapse of art-keep.md 8.5 (Dusk column). Ends with a smoking wreck and
## `destroyed_finished`. Tweens belong to this node, so freeing it mid-sequence is safe.
func play_destroyed() -> void:
	if _destroyed or not _ready_done:
		return
	_destroyed = true
	_pulse_t = 10.0
	_motes.emitting = false
	_sparks.emitting = false
	_build_ring.emitting = false
	for s: GPUParticles3D in _smoke:
		s.emitting = true
	_outline.visible = false
	if _float_tween:
		_float_tween.kill()
	for nm: StringName in FLOATING:
		(_model.get_node(NodePath(nm)) as Node3D).scale = Vector3.ONE
	# The top of the spire falls as one piece around a pivot at the prism 1 / prism 2 joint.
	var pivot := Node3D.new()
	pivot.name = "ToppleTop"
	pivot.position = Vector3(0, 8.7, 0)
	_model.add_child(pivot)
	for nm: StringName in TOPPLE:
		var n: Node3D = _model.get_node(NodePath(nm))
		n.visible = true
		n.transform = _orig[n]
		n.reparent(pivot, true)
	_shard_core.set_instance_shader_parameter(&"boost", 4.0)
	_spire_light.light_energy = 6.0
	var tw := create_tween().set_parallel(true)
	# 0.0-0.15 flash, 0.0-0.6 shard rises 2 m and spins 180 deg/s.
	tw.tween_property(_spire_light, "light_energy", SPIRE_ENERGY, 0.15).set_delay(0.0)
	tw.tween_property(_shard, "position:y", _shard.position.y + 2.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_shard, "rotation:y", _shard.rotation.y + PI * 0.6, 0.6)
	# 0.6 shard bursts, rune ring off.
	tw.tween_callback(func() -> void:
		_shard.visible = false
		_ring.visible = false
		_fire_burst(_model.transform * _shard.position, Vector3.UP, 180.0, 3.0, 6.0, 1.0)).set_delay(0.6)
	# G-B: the tier parts shatter with the eye (dust from the plinth fangs).
	if not _tn.is_empty():
		(_tn["rig"] as Node3D).visible = false
		tw.tween_callback(func() -> void:
			(_tn["t2"] as Node3D).visible = false
			(_tn["t3"] as Node3D).visible = false).set_delay(0.6)
	if _dress:
		_dress.sync(1.0, 0.0, true)
	# 0.6-1.4 the top tilts 30 deg toward +Z and drops 8 m.
	tw.tween_property(pivot, "rotation:x", deg_to_rad(30.0), 0.8).set_delay(0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(pivot, "position:y", 8.7 - 8.0, 0.8).set_delay(0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		_fire_dust(6.4)
		_debris.restart()).set_delay(0.9)
	# 0.8-1.9 the watch-needle snaps at its root and falls away from the keep.
	tw.tween_callback(func() -> void: _orbs[1].visible = false).set_delay(0.8)
	tw.tween_method(func(a: float) -> void: _needle.transform = _needle_xf(a), _needle_lean, deg_to_rad(62.0), 1.1) \
		.set_delay(0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		_needle.hide()
		_fire_dust(0.4)).set_delay(1.9)
	tw.tween_callback(pivot.hide).set_delay(1.4)
	# 1.0-2.2 body and fins sink to 30 % with a rumble, fins splay to 45 deg.
	tw.tween_callback(func() -> void: _rumble = true).set_delay(1.0)
	tw.tween_method(_crush, 0.0, 1.0, 1.2).set_delay(1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		for b: Node3D in _banners:
			b.visible = false
		_stems.visible = false
		for o: Node3D in _orbs:
			o.visible = false
		_fire_dust(1.2)).set_delay(1.6)
	tw.tween_callback(func() -> void:
		_rumble = false
		_model.position = Vector3.ZERO
		_mist2.emitting = true
		_rubble2.visible = true).set_delay(2.2)
	# 2.2-3.0 lights fade to 30 %, the ground turns purple-black, debris grows.
	tw.tween_property(_spire_light, "light_energy", SPIRE_ENERGY * 0.3, 0.8).set_delay(2.2)
	tw.tween_property(_gate_light, "light_energy", GATE_ENERGY * 0.3, 0.8).set_delay(2.2)
	tw.tween_method(func(v: float) -> void: _ground_mat.set_shader_parameter(&"scorch", v), 0.0, 1.0, 0.8).set_delay(2.2)
	tw.tween_property(_rubble, "scale", Vector3(1.1, 1.6, 1.1), 0.8).set_delay(2.2)
	for m: ShaderMaterial in _painted_mats:
		m.set_shader_parameter(&"damage", 1.0)
	tw.tween_callback(func() -> void: destroyed_finished.emit()).set_delay(3.0)


# --- Internals -------------------------------------------------------------------------------

## Scales a Model child along y about the model-space height `pivot_y` (from its original transform).
func _squash(n: Node3D, sy: float, pivot_y: float) -> void:
	n.transform = Transform3D(Basis.from_scale(Vector3(1.0, sy, 1.0)), Vector3(0.0, pivot_y * (1.0 - sy), 0.0)) * _orig[n]


## Watch-needle transform leaning `a` radians outward about its root.
func _needle_xf(a: float) -> Transform3D:
	var o: Transform3D = _orig[_needle]
	var axis: Vector3 = Vector3.UP.cross(dir(NEEDLE_FACE))
	return Transform3D(Basis(axis, a) * o.basis, o.origin)


func _crush(k: float) -> void:
	var sy: float = lerpf(1.0, 0.3, k)
	for n: Node3D in _parts:
		if n.name in NO_CRUSH or n.name in TOPPLE:
			continue
		_squash(n, sy, 1.2)
	_fin_tilt = lerpf(FIN_TILT, deg_to_rad(45.0), k)
	_update_fins()


## Fin and fin-tip transforms (same formula as dusk_keep_build.gd), with the current tilt and
## the two fins lost under 50 % HP collapsed to nothing.
func _update_fins() -> void:
	var fm: MultiMesh = _fins.multimesh
	var tm: MultiMesh = _tips.multimesh
	if fm.instance_count < 6 or tm.instance_count < 6:
		return
	for i: int in 6:
		var gone: bool = _fins_broken and (i == 1 or i == 4)
		var f: Transform3D = fin_xf(i, _fin_tilt)
		var t: Transform3D = fin_tip_xf(i, _fin_tilt)
		if gone:
			f.basis = Basis.from_scale(Vector3.ZERO)
			t.basis = Basis.from_scale(Vector3.ZERO)
		fm.set_instance_transform(i, f)
		tm.set_instance_transform(i, t)


func _fire_burst(pos: Vector3, dir: Vector3, spread: float, v_min: float, v_max: float, ratio: float) -> void:
	var pm := _burst.process_material as ParticleProcessMaterial
	pm.direction = dir
	pm.spread = spread
	pm.initial_velocity_min = v_min
	pm.initial_velocity_max = v_max
	_burst.position = pos
	_burst.amount_ratio = ratio
	_burst.restart()


func _fire_dust(model_y: float) -> void:
	_dust.position = Vector3(0.0, model_y * VIS, 0.0)
	_dust.restart()


## G-F round 2: a team glow graded for the keep's lights (hue kept, saturation <= LIGHT_SAT).
static func light_tint(glow: Color) -> Color:
	return Color.from_hsv(glow.h, minf(glow.s, LIGHT_SAT), glow.v)


func _glow_color() -> Color:
	return GLOW_DEFAULT if _team_color.is_equal_approx(DEFAULT_TEAM) else _team_color.lightened(0.35)


func _set_sel(v: float) -> void:
	_sel = v
	_apply_rim()


func _apply_rim() -> void:
	if not _ready_done:
		return
	var team_rim: Color = _team_color.lightened(0.2)
	var rim: Color = IDLE_RIM.lerp(team_rim, _sel)
	var strength: float = lerpf(IDLE_RIM_STRENGTH, 0.9, _sel)
	if _progress > 0.0 and _progress < 1.0:
		rim = _glow_color() # parts glow in the team colour while they rise
		strength = maxf(strength, 1.0)
	for m: ShaderMaterial in _painted_mats:
		m.set_shader_parameter(&"rim_color", rim)
		m.set_shader_parameter(&"rim_strength", strength)
	_banner_mat.set_shader_parameter(&"rim_color", rim)
	_banner_mat.set_shader_parameter(&"rim_strength", lerpf(0.0, 0.9, _sel))
	_glow_mat.set_shader_parameter(&"boost_mult", lerpf(1.0, 1.4, _sel))

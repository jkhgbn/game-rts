class_name DragonRoostModel
extends FireHallModel
## Visual model of the Fire kingdom's Lair, the Dragon Roost (task 13.V25, docs/design/cavalry-mounts.md 2.1 + 10, style
## art-keep.md 0). Read from the RTS camera: a spire of columnar basalt (a cluster of leaning hexagonal columns, glowing
## lava seams in the joints, bronze straps) rising to ~7 m, crowned by a huge nest of charred beams (the dominant: a woven
## basket of crossed beams flaring to ~5.4 m wide with jagged beam spikes, ember tips, team lashings and an ember bed that
## burns in the middle), two team banners hanging under the nest. Asymmetric secondary: a long stone perch ledge
## (a "diving board" with bronze talons and glowing claw scratches) jutting from the spire over the gate at ~5.2 m.
## At the foot: a basalt gatehouse with a glowing arched door (local -Z), a lava runnel feeding a bubbling lava pool
## (back +X corner) and a lava fall over the -X plinth edge (one per camera), a paved forge terrace at the front +X
## corner where the Ember Crucible annex (13c.V7) stands once lit (a stack of nest beams and a lava vent there before).
## Same hooks and state machine as FireHallModel (fire_hall.gd, art-keep.md 8.8): set_team_color,
## set_construction_progress, set_health_ratio (< 50 %: smoke, part of the nest's spikes snapped, lava leaking down the
## spire, rubble; < 25 %: fire in the nest and on the perch strut, the player-side banner lost, burnt nest patch),
## play_training_pulse (the door flashes), play_destroyed (-> destroyed_finished after 3 s: the nest tilts and falls, the
## spire sinks to broken stumps, charred beams everywhere), set_selected. All hooks are safe before _ready.
## Lair hooks:
##   play_raise()  a Cinder Dragon is raised (2.6 s): the lava seams, pool and nest flare (x4), a fire column erupts from
##       the nest, a ring of fire runs round the spire foot, the nest shakes. Restarts if retriggered; ignored on a site,
##       a wreck or before _ready. is_raising() -> bool, get_lava_flare() -> float (0 idle .. ~3 at the peak).
##   set_crucible(on: bool, instant: bool = false)  the Ember Crucible annex (EmberCrucibleAnnex, a separate child scene,
##       never merged into the Roost's meshes): the first `on` installs it on the forge terrace (ROOST_ANCHOR) and lights
##       it; `off` cools it (the annex stays, cold). Hidden on a construction site and on the wreck; play_destroyed puts
##       it out at once (its set_crucible(false, true)) and hides it with the collapse. has_crucible(),
##       is_crucible_lit(), get_crucible() -> Node3D (null until installed).
##   play_forge()  forwarded to the annex (pour + sparks) while it is lit; signal crucible_poured(at) relays its
##       forge_poured(at) (world point of the sprue).
## Footprint 3 x 3 cells (6 x 6 m), gate local -Z (Building turns it toward the map centre). The player's camera sees the
## local +X side, the enemy's the local -X side: the ledge and the nest spikes stick out along local Z (broadside to both
## cameras); the spire stands back (+Z) and to the left (-X) so the annex on the front +X corner stays visible from the
## -X camera too (no spire mass above 1.2 m inside the annex bounds). Below 2.5 m everything stays within 3.3 m of the
## centre; above it the nest spikes and the perch overhang the footprint by at most ~0.8 m. Top ~9.9 m.
## No collision (Building's). No real light: the base class drives a virtual OmniLight3D that never enters the tree; its
## flicker drives an additive fake light pool on the plinth. Parts are merged per tier (BuildingMerge).

signal crucible_poured(at: Vector3)

const CRUCIBLE_PATH := "res://art/buildings/fire/ember_crucible/ember_crucible.tscn"
## Annex origin on the Roost (the crucible's ROOST_ANCHOR, on the lower plinth tier top).
const CRUCIBLE_ANCHOR := Vector3(1.85, 0.5, -1.85)
## Annex bounds (x0, z0, x1, z1) around the anchor (its FOOTPRINT_HALF 1.30 / 1.37, z -1.33..+1.37).
const ANNEX_RECT := Rect2(0.55, -3.18, 2.6, 2.7)
const LOWER_TOP := 0.5
const SPIRE := Vector3(-0.4, 0.0, 1.0)      ## spire axis (x, z)
const NEST_Y := 7.05                         ## nest group origin (bottom of the bowl)
const GATE := Vector3(-1.45, 0.0, -0.6)       ## gatehouse centre (x, z)
const PERCH_X := -1.8
const PERCH_Y := 5.7
const PERCH_TIP_Z := -3.25
const POOL := Vector3(2.05, 0.8, 2.15)
const RAISE_TIME := 2.6
const RAISE_PEAK := 3.0
const CHAR_COLOR := Color(0.13, 0.085, 0.07)
const LAVA_COLOR := Color(1.0, 0.42, 0.1)

var mat_char: ShaderMaterial   ## charred beams (ember cracks)
var mat_lava: ShaderMaterial   ## lava seams, runnels, pool
var _nest: Node3D
var _nest_xf: Transform3D
var _perch: Node3D
var _terrace: MeshInstance3D
var _pool: MeshInstance3D
var _pool_mat: StandardMaterial3D
var _raise_burst: GPUParticles3D
var _raise_ring: GPUParticles3D
var _raise_t: float = -1.0
var _raise_fired: bool = false
var _flare: float = 0.0
var _crucible: Node3D
var _crucible_installed: bool = false
var _crucible_lit: bool = false
var _crucible_instant: bool = true


# --- Palette / materials ---

func _setup_palette() -> void:
	stone_color = Color(0.28, 0.24, 0.23)   # basalt, a touch cooler than the keep stone
	crack_strength = 0.45                     # faint lava veins through the basalt (the seams carry the read)
	light_energy = 1.0   # the virtual light's energy is read back as a 0..1+ flicker for the fake pool


func _make_materials() -> void:
	super()
	mat_char = _painted_mat(CHAR_COLOR, 0.1, 0.6)
	mat_char.set_shader_parameter(&"crack_scale", 0.7)
	mat_char.set_shader_parameter(&"crack_speed", 1.8)
	mat_lava = _glow_mat(0.6, 1.3, 0)   # 2026-09-30 R5: seams and ember tips glow under the bloom (the nest core and the gate stay the points)
	mat_lava.set_shader_parameter(&"glow_color", LAVA_COLOR)


func _process(delta: float) -> void:
	super(delta)
	if _pool and _ready_done and _light:
		var c: Color = _pool_mat.albedo_color
		c.a = clampf(0.26 * _light.light_energy / maxf(light_energy, 0.01) * (1.0 + 0.5 * _flare), 0.0, 0.9)
		_pool_mat.albedo_color = c


func _notification(what: int) -> void:
	# The virtual light never enters the tree: free it with the model.
	if what == NOTIFICATION_PREDELETE and _light != null and is_instance_valid(_light) and not _light.is_inside_tree():
		_light.free()


func _ready() -> void:
	super()
	if _crucible_installed and not _destroyed:
		_ensure_crucible()
		if _crucible != null:
			_crucible.call(&"set_crucible", _crucible_lit, true)
	_update_crucible()


# --- Hooks (lair) ---

## A Cinder Dragon is raised: the lava flare (2.6 s). Restarts if retriggered; ignored on a site / wreck / before _ready.
func play_raise() -> void:
	if _destroyed or not _ready_done or _progress < 1.0:
		return
	_raise_t = 0.0
	_raise_fired = false


func is_raising() -> bool:
	return _raise_t >= 0.0


## Current lava flare (0 idle .. RAISE_PEAK at the top of play_raise). For tests and tools.
func get_lava_flare() -> float:
	return _flare


## The Ember Crucible annex: `on` installs (first time) and lights it, `off` lets it cool. `instant` skips the ramps.
func set_crucible(on: bool, instant: bool = false) -> void:
	if _destroyed:
		# The Crucible goes out with the Roost (titans-2.md 6.3): a dead Roost never relights.
		_crucible_lit = false
		return
	if on:
		_crucible_installed = true
	_crucible_lit = on
	if not _ready_done or not _crucible_installed:
		return
	_ensure_crucible()
	if _crucible == null:
		return
	# A hidden annex (site / wreck) or a restore changes at once.
	var hidden: bool = _progress < 1.0 or _destroyed
	_crucible.call(&"set_crucible", on, instant or hidden)
	_update_crucible()


## One Flame Guard forged: forwarded to the annex while it is lit and shown.
func play_forge() -> void:
	if _crucible != null and _crucible_lit and _crucible.visible and not _destroyed:
		_crucible.call(&"play_forge")


func has_crucible() -> bool:
	return _crucible_installed


func is_crucible_lit() -> bool:
	return _crucible_lit


func get_crucible() -> Node3D:
	return _crucible


func set_construction_progress(p: float) -> void:
	super(p)
	if _pool:
		_pool.visible = _progress >= 1.0 and not _destroyed
	if _progress < 1.0:
		_end_raise()
	_update_crucible()


func play_destroyed() -> void:
	var was: bool = _destroyed
	super()
	if was:
		return
	_end_raise()
	if _pool:
		_pool.visible = false
	if _crucible != null:
		_crucible.call(&"set_crucible", false, true)
	_crucible_lit = false


# --- Crucible annex ---

func _ensure_crucible() -> void:
	if _crucible != null or not ResourceLoader.exists(CRUCIBLE_PATH):
		return
	var scene := load(CRUCIBLE_PATH) as PackedScene
	if scene == null:
		return
	_crucible = scene.instantiate() as Node3D
	_crucible.name = "CrucibleAnnex"
	_crucible.position = CRUCIBLE_ANCHOR
	_crucible.set_meta(&"keep_separate", true)
	_crucible.visible = false
	add_child(_crucible)   # root child: never a construction part, never merged
	if _crucible.has_signal(&"forge_poured"):
		_crucible.connect(&"forge_poured", func(at: Vector3) -> void: crucible_poured.emit(at))
	_hide_on_collapse.append(_crucible)


func _update_crucible() -> void:
	if not _ready_done:
		return
	# On a wreck the annex keeps its state until the collapse hides it (_hide_on_collapse, 1.6 s).
	if _crucible != null and not _destroyed:
		_crucible.visible = _crucible_installed and _progress >= 1.0
	if _terrace:
		_terrace.visible = not _crucible_installed


# --- Idle motion: the raise flare ---

func _idle_motion(delta: float) -> void:
	if _raise_t < 0.0:
		return
	_raise_t += delta
	var k: float = _raise_t
	if k < 0.35:
		_flare = RAISE_PEAK * smoothstep(0.0, 0.35, k)
	else:
		_flare = RAISE_PEAK * exp(-1.7 * (k - 0.35))
	if not _raise_fired and k >= 0.25:
		_raise_fired = true
		_fire(_raise_burst)
		_fire(_raise_ring)
	# The nest shudders while the dragon climbs out of it.
	if _nest and _nest.visible:
		var s: float = 0.05 * _bump01(k, 0.15, 0.35, 1.1)
		_nest.transform = Transform3D(_nest_xf.basis, _nest_xf.origin + Vector3(sin(k * 71.0) * s, 0.0, cos(k * 63.0) * s))
	if k >= RAISE_TIME:
		_end_raise()
		return
	_apply_flare()


func _end_raise() -> void:
	_raise_t = -1.0
	_flare = 0.0
	if _nest and not _destroyed:
		_nest.transform = _nest_xf
	if _ready_done and not _destroyed:
		_apply_flare()


func _apply_flare() -> void:
	var sel: float = _sel_boost()
	mat_lava.set_shader_parameter(&"boost", sel * (1.0 + _flare))
	mat_glow.set_shader_parameter(&"boost", sel * (1.0 + 0.6 * _flare))


func _apply_rim_and_glow() -> void:
	super()
	if _ready_done and _raise_t >= 0.0:
		_apply_flare()


static func _bump01(t: float, a: float, b: float, c: float) -> float:
	if t <= a or t >= c:
		return 0.0
	if t < b:
		return smoothstep(a, b, t)
	return 1.0 - smoothstep(b, c, t)


# --- Structure ---

func _build_structure() -> void:
	_top_y = 9.9
	_light = OmniLight3D.new()
	_light.name = "VirtualLight"
	_light.light_energy = light_energy
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 132501
	var plinth := _build_plinth(box1, rng)
	_build_terrace(box1, plinth, rng)
	_build_spire(box1, rng)
	_build_gatehouse(box1)
	_build_lava(box1, rng)
	_build_perch(box1)
	_build_nest(box1, rng)
	_build_pool()
	# Construction scaffolding round the spire, the wreck (spire stubs, beams, the fallen nest and perch).
	_build_scaffold(SPIRE.x, SPIRE.z, 4.1, 4.1, 5.2)
	_build_wreck(SPIRE.x, SPIRE.z, 3.8, 3.8, 0.8 + (6.8 - 0.8) * 0.3, Vector3(SPIRE.x, 1.7, SPIRE.z),
		Vector3(1.9, 1.9, 1.9), 2525)
	_build_wreck_extra(box1)
	_scorch_decal(Vector3(POOL.x - 0.2, 0.84, POOL.z - 0.2), 2.6, Color(0.14, 0.05, 0.02, 0.6)).name = "PoolScorchDecal"
	_scorch_decal(Vector3(GATE.x, 0.035, -3.6), 2.8).name = "GateScorchDecal"
	# Collapse: the nest tilts toward the gate and falls; the perch and banners go at 1.6 s.
	_falling = _nest
	_fall_axis = Vector3.RIGHT
	_fall_deg = 34.0
	_hide_on_collapse.append(_perch)
	# State anchors: smoke from a spire gap and the nest; fire in the nest and on the perch strut.
	_smoke_points = [Vector3(0.9, 5.4, 0.1), Vector3(SPIRE.x + 0.4, 8.4, SPIRE.z + 0.7)]
	_blaze_points = [Vector3(SPIRE.x - 0.7, 8.1, SPIRE.z - 0.5), Vector3(PERCH_X, 4.5, -1.5)]
	_rubble2_points = [Vector3(-2.5, 0.9, -2.5), Vector3(-2.9, 0.5, -2.0), Vector3(-2.0, 0.9, -2.95),
		Vector3(-2.75, 0.9, 2.55)]
	_gate_pos = Vector3(GATE.x, 1.6, -1.8)


## Two dark tiers: the full lower tier (top 0.5) and an upper tier (top 0.8) that leaves the front +X corner low (the
## forge terrace where the annex stands), raised corner blocks, a door path, a kerb round the terrace.
func _build_plinth(box1: BoxMesh, rng: RandomNumberGenerator) -> MeshInstance3D:
	var it: Array = []
	it.append(BMG.item(box1, Vector3(0, 0.25, 0), mat_dark, Vector3.ZERO, Vector3(6.4, 0.5, 6.4)))
	# Upper tier: back strip (z -0.3 .. 2.9) and front-left block (x -2.9 .. 0.3).
	it.append(BMG.item(box1, Vector3(0, 0.65, 1.3), mat_dark, Vector3.ZERO, Vector3(5.8, 0.3, 3.2)))
	it.append(BMG.item(box1, Vector3(-1.3, 0.65, -1.6), mat_dark, Vector3.ZERO, Vector3(3.2, 0.3, 2.6)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(BMG.item(box1, Vector3(c.x * 2.72, 0.95, c.y * 2.72), mat_dark, Vector3.ZERO, Vector3(0.75, 0.4, 0.75)))
	# Door path: worn stone flags from the gate to the front edge.
	for i: int in 3:
		var p := Vector3(GATE.x + rng.randf_range(-0.12, 0.12), 0.83, -1.95 - 0.42 * i)
		it.append(BMG.item(box1, p, mat_stone, Vector3(0, rng.randf_range(-10, 10), 0), Vector3(1.1, 0.07, 0.36)))
	# Terrace: a stone kerb on its two open edges (front and +X), stepping down from the upper tier.
	it.append(BMG.item(box1, Vector3(1.75, 0.56, -3.07), mat_stone, Vector3.ZERO, Vector3(2.9, 0.12, 0.2)))
	it.append(BMG.item(box1, Vector3(3.07, 0.56, -1.75), mat_stone, Vector3.ZERO, Vector3(0.2, 0.12, 2.9)))
	return _merged("PlinthBase", "plinth", it)


## Before the Crucible: a stack of spare nest beams and a glowing lava vent on the terrace (child of the plinth, so the
## annex can replace it; hidden once installed).
func _build_terrace(box1: BoxMesh, plinth: MeshInstance3D, rng: RandomNumberGenerator) -> void:
	var it: Array = []
	var base := Vector3(1.55, LOWER_TOP, -1.75)
	for i: int in 4:
		var y: float = 0.16 + 0.27 * (i / 2)
		var z: float = -0.3 + 0.55 * (i % 2)
		var yaw: float = (8.0 if i < 2 else 78.0) + rng.randf_range(-6.0, 6.0)
		var p: Vector3 = base + (Vector3(0, y, z) if i < 2 else Vector3(z * 0.9, y, 0.05))
		it.append(BMG.item(box1, p, mat_char, Vector3(0, yaw, rng.randf_range(-3.0, 3.0)), Vector3(0.32, 0.3, 2.0)))
	it.append(BMG.item(box1, base + Vector3(0.05, 0.72, 0.0), mat_metal, Vector3(0, 40, 0), Vector3(0.36, 0.12, 0.8)))
	# A basalt boulder and the vent (a glowing crack with a dark lip).
	it.append(BMG.item(_cyl(0.32, 0.45, 0.7, 6), Vector3(2.55, LOWER_TOP + 0.35, -2.6), mat_stone, Vector3(4, 20, -6)))
	it.append(BMG.item(box1, Vector3(1.2, LOWER_TOP + 0.02, -2.55), mat_dark, Vector3(0, -24, 0), Vector3(1.4, 0.06, 0.5)))
	it.append(BMG.item(box1, Vector3(1.2, LOWER_TOP + 0.05, -2.55), mat_lava, Vector3(0, -24, 0), Vector3(1.15, 0.03, 0.18)))
	_terrace = _merged("TerraceProps", "terrace", it, plinth)


## The columnar basalt spire: a tapering hex core in two drums, six leaning satellite columns (none on the annex side),
## zig-zag lava seams in the joints, a glowing ring at the drum joint, bronze straps and the nest seat collar.
func _build_spire(box1: BoxMesh, rng: RandomNumberGenerator) -> void:
	var it: Array = []
	var s := Vector3(SPIRE.x, 0.0, SPIRE.z)
	it.append(BMG.item(_cyl(1.6, 1.75, 4.0, 6), s + Vector3(0, 2.8, 0), mat_stone))
	it.append(BMG.item(_cyl(1.28, 1.45, 2.0, 6), s + Vector3(0, 5.8, 0), mat_stone, Vector3(0, 18, 0)))
	it.append(BMG.item(_cyl(1.52, 1.52, 0.08, 6), s + Vector3(0, 4.83, 0), mat_lava, Vector3(0, 9, 0)))
	# Seat collar under the nest (dark, flared).
	it.append(BMG.item(_cyl(1.62, 1.3, 0.55, 6), s + Vector3(0, 6.95, 0), mat_dark, Vector3(0, 18, 0)))
	# Bronze straps.
	it.append(BMG.item(_cyl(1.69, 1.69, 0.22, 6), s + Vector3(0, 3.35, 0), mat_metal))
	it.append(BMG.item(_cyl(1.4, 1.4, 0.2, 6), s + Vector3(0, 6.15, 0), mat_metal, Vector3(0, 18, 0)))
	# Satellite columns: angle (deg, from +X toward +Z), height, radius. The annex side (-52 deg) stays clear.
	var sats: Array[Vector3] = [Vector3(15, 5.4, 0.7), Vector3(62, 3.3, 0.6), Vector3(105, 6.2, 0.75),
		Vector3(150, 4.1, 0.62), Vector3(195, 5.1, 0.7), Vector3(240, 2.7, 0.55)]
	# 2026-09-30 C3 / R4k: the satellite columns in three basalt shades (one merged material: shades are free),
	# paler ones so the Roost's base parts from dark ash.
	var basalt: Array = [mat_stone, _painted_mat(stone_color.lightened(0.12), 0.05, crack_strength),
		_painted_mat(stone_color.lightened(0.22), 0.05, crack_strength * 0.6)]
	var si: int = 0
	for sat: Vector3 in sats:
		var a: float = deg_to_rad(sat.x)
		var d := Vector3(cos(a), 0.0, sin(a))
		var lean := Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(-4.0))
		var h: float = sat.y
		var base: Vector3 = s + d * 1.45 + Vector3(0, 0.8, 0)
		it.append(BMG.item_xf(_cyl(sat.z * 0.92, sat.z, h, 6),
			Transform3D(lean * Basis(Vector3.UP, rng.randf_range(0.0, 1.0)), base + lean * Vector3(0, h * 0.5, 0)), basalt[si % 3]))
		si += 1
		# A darker broken top on each column (reads as a column joint from above).
		it.append(BMG.item_xf(_cyl(sat.z * 0.7, sat.z * 0.9, 0.22, 6),
			Transform3D(lean, base + lean * Vector3(0, h + 0.09, 0)), mat_dark))
	# Lava seams on the core faces between the satellites (zig-zag strips, 3 segments each), lying on the hex faces.
	for fa: float in [-30.0, 40.0, 84.0, 128.0, 172.0, 218.0]:
		var pts: Array[Vector3] = []
		var hs: Array[float] = [1.0, 2.2, 3.4, 4.6]
		var face: Vector3
		for i: int in hs.size():
			var r: float = lerpf(1.75, 1.6, (hs[i] - 0.8) / 4.0)
			var on: Array = _hex_point(fa + (5.0 if i % 2 == 0 else -5.0), 0.0, r)
			pts.append(s + (on[0] as Vector3) + Vector3(0, hs[i], 0))
			face = on[1]
		for i: int in pts.size() - 1:
			it.append(BMG.item_xf(box1, _strip(pts[i], pts[i + 1], Vector3(-face.z, 0, face.x), 0.16, 0.08), mat_lava))
	for fa: float in [60.0, 150.0, 250.0]:
		var p0: Array = _hex_point(fa, 18.0, 1.45)
		var p1: Array = _hex_point(fa + 6.0, 18.0, 1.3)
		var f: Vector3 = p0[1]
		it.append(BMG.item_xf(box1, _strip(s + (p0[0] as Vector3) + Vector3(0, 5.0, 0),
			s + (p1[0] as Vector3) + Vector3(0, 6.6, 0), Vector3(-f.z, 0, f.x), 0.14, 0.08), mat_lava))
	_merged("Spire", "spire", it)


## Point on the surface of a 6-sided CylinderMesh (corner radius `r`, turned `rot_deg` about y) in direction `a_deg`
## (from +X toward +Z), 3 cm proud, and the outward normal of that face: [point, normal]. Godot puts the cylinder's
## corners at x = sin(u), z = cos(u), so the flat faces sit at a = 60 k - rot_deg.
func _hex_point(a_deg: float, rot_deg: float, r: float) -> Array:
	var f: float = roundf((a_deg + rot_deg) / 60.0) * 60.0 - rot_deg
	var dlt: float = deg_to_rad(a_deg - f)
	var n := Vector3(cos(deg_to_rad(f)), 0.0, sin(deg_to_rad(f)))
	var d := Vector3(cos(deg_to_rad(a_deg)), 0.0, sin(deg_to_rad(a_deg)))
	var dist: float = r * 0.866 / cos(dlt) + 0.03 / cos(dlt)
	return [d * dist, n]


## Basalt gatehouse in front of the spire (-Z): an arched door with a glowing interior (the training flash), a bronze
## keystone and lintel, a sloped dark roof, a team crest over the arch.
func _build_gatehouse(box1: BoxMesh) -> void:
	var it: Array = []
	var g := Vector3(GATE.x, 0.0, GATE.z)
	it.append(BMG.item(box1, g + Vector3(0, 2.25, 0.05), mat_stone, Vector3.ZERO, Vector3(2.3, 2.9, 1.3)))
	it.append(BMG.item(box1, g + Vector3(0, 1.0, 0.05), mat_dark, Vector3.ZERO, Vector3(2.5, 0.4, 1.5)))
	for sx: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, g + Vector3(sx * 1.08, 2.2, -0.62), mat_dark, Vector3.ZERO, Vector3(0.42, 2.9, 0.42)))
	it.append(BMG.item(_prism(Vector3(2.7, 0.75, 1.6), 0.5), g + Vector3(0, 4.07, 0.05), mat_dark))
	# 2026-09-30 R6: team tiles on both roof slopes (the Roost's team colour only hung in two banners before).
	var ra: float = atan2(0.75, 1.35)
	for sx: float in [-1.0, 1.0]:
		var rb := Basis(Vector3.BACK, -sx * ra)
		it.append(BMG.item_xf(box1, Transform3D(rb.scaled_local(Vector3(1.5, 0.1, 1.75)),
			g + Vector3(sx * 0.66, 4.1, 0.05) + rb * Vector3(0, 0.05, 0)), mat_team))
	it.append(BMG.item(box1, g + Vector3(0, 3.72, 0.05), mat_metal, Vector3.ZERO, Vector3(2.6, 0.14, 1.5)))
	# Door: dark frame, round arch, glowing interior, keystone.
	var fz: float = g.z - 0.62
	it.append(BMG.item(box1, g + Vector3(0, 1.85, -0.62), mat_dark, Vector3.ZERO, Vector3(1.55, 2.1, 0.3)))
	it.append(BMG.item(_cyl(0.78, 0.78, 0.3, 14), Vector3(g.x, 2.85, fz), mat_dark, Vector3(90, 0, 0)))
	it.append(BMG.item(box1, Vector3(g.x, 1.78, fz - 0.14), mat_gate, Vector3.ZERO, Vector3(1.0, 1.9, 0.08)))
	it.append(BMG.item(_cyl(0.5, 0.5, 0.08, 14), Vector3(g.x, 2.72, fz - 0.14), mat_gate, Vector3(90, 0, 0)))
	it.append(BMG.item(box1, Vector3(g.x, 3.5, fz - 0.08), mat_metal, Vector3.ZERO, Vector3(0.4, 0.5, 0.42)))
	for sx: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, Vector3(g.x + sx * 0.82, 2.85, fz - 0.06), mat_metal, Vector3.ZERO, Vector3(0.32, 0.22, 0.4)))
	it.append(BMG.item(box1, Vector3(g.x, 0.86, fz - 0.28), mat_metal, Vector3.ZERO, Vector3(1.4, 0.1, 0.3)))
	# Team crest on the roof front: a round team shield on a bronze rim with a flame-shaped glow boss.
	# (In front of the roof's gable triangle, whose face is at z = g.z - 0.75.)
	it.append(BMG.item(_cyl(0.52, 0.52, 0.12, 12), Vector3(g.x, 4.0, g.z - 0.84), mat_metal, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.4, 0.4, 0.16, 12), Vector3(g.x, 4.0, g.z - 0.87), mat_team, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.0, 0.16, 0.36, 4), Vector3(g.x, 4.02, g.z - 0.98), mat_glow, Vector3(0, 45, 0)))
	_merged("Gatehouse", "gatehouse", it)


## Lava: a runnel from the spire foot to the bubbling pool in the back +X corner (player side), another from the spire to
## a lava fall over the -X plinth edge (enemy side); dark kerbs, basalt stones at the pool.
func _build_lava(box1: BoxMesh, rng: RandomNumberGenerator) -> void:
	var it: Array = []
	var runs: Array = [[Vector3(0.95, 0.82, 1.25), Vector3(1.55, 0.82, 1.75)],
		[Vector3(-2.05, 0.82, 0.55), Vector3(-2.95, 0.82, 0.25)]]
	for run: Array in runs:
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var along: Vector3 = (b - a).normalized()
		var t := Vector3(-along.z, 0.0, along.x)
		it.append(BMG.item_xf(box1, _strip(a - along * 0.2, b + along * 0.1, t, 0.3, 0.05), mat_lava))
		for side: float in [-1.0, 1.0]:
			it.append(BMG.item_xf(box1, _strip(a + t * side * 0.24 - along * 0.2, b + t * side * 0.24, t, 0.16, 0.14),
				mat_dark))
	# Lava fall over the -X edge: down the upper tier, across the lower tier, down to a small ground puddle.
	it.append(BMG.item(box1, Vector3(-2.92, 0.66, 0.25), mat_lava, Vector3.ZERO, Vector3(0.06, 0.3, 0.34)))
	it.append(BMG.item(box1, Vector3(-3.05, 0.52, 0.25), mat_lava, Vector3.ZERO, Vector3(0.3, 0.04, 0.34)))
	it.append(BMG.item(box1, Vector3(-3.22, 0.27, 0.25), mat_lava, Vector3.ZERO, Vector3(0.05, 0.5, 0.3)))
	it.append(BMG.item(box1, Vector3(-3.25, 0.03, 0.25), mat_lava, Vector3.ZERO, Vector3(0.1, 0.04, 0.5)))
	# Pool: a dark basin, the lava surface, a bronze lip and stones.
	it.append(BMG.item(_cyl(0.98, 1.08, 0.24, 8), POOL + Vector3(0, 0.1, 0), mat_dark))
	it.append(BMG.item(_cyl(0.8, 0.8, 0.05, 8), POOL + Vector3(0, 0.2, 0), mat_lava))
	for i: int in 3:
		var a: float = TAU * (0.15 + 0.3 * i) + rng.randf_range(-0.2, 0.2)
		var p: Vector3 = POOL + Vector3(cos(a) * 1.0, 0.25, sin(a) * 1.0)
		it.append(BMG.item(_cyl(0.18, 0.3, 0.45, 6), p, mat_stone, Vector3(rng.randf_range(-10, 10), rng.randf() * 60.0, 8)))
	_merged("Lava", "lava", it)
	var em := _pm(Vector3.UP, 25.0, 0.6, 1.4, Vector3(0, 0.4, 0), 0.14, 0.05, _fire_ramp)
	em.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	em.emission_box_extents = Vector3(0.6, 0.05, 0.6)
	_idle_fx.append(_particles("LavaEmbers", _body, POOL + Vector3(0, 0.3, 0), 10, 1.6, em, _add_quad, false))


## The perch ledge (one construction part): a stone slab jutting from the spire over the gate toward -Z, a corbel, a
## charred strut with a bronze bracket, bronze talons hooked over the tip, glowing claw scratches on top.
func _build_perch(box1: BoxMesh) -> void:
	_perch = Node3D.new()
	_perch.name = "Perch"
	_body.add_child(_perch)
	var it: Array = []
	var x: float = PERCH_X
	var root := Vector3(x, PERCH_Y - 0.05, 0.9)
	var tip := Vector3(x, PERCH_Y + 0.12, PERCH_TIP_Z)
	it.append(BMG.item_xf(box1, _strip(root, tip, Vector3.RIGHT, 1.35, 0.5), mat_stone))
	it.append(BMG.item_xf(box1, _strip(root + Vector3(0, 0.27, 0), tip + Vector3(0, 0.27, 0.05), Vector3.RIGHT, 1.1, 0.06),
		mat_dark))
	it.append(BMG.item(box1, Vector3(x + 0.25, PERCH_Y - 0.5, 0.35), mat_stone, Vector3(-12, 0, 0), Vector3(1.6, 0.95, 1.1)))
	# Strut (charred beam) from the spire above the gatehouse to under the ledge, bronze bracket at the top.
	var s0 := Vector3(x, 4.2, -0.55)
	var s1 := Vector3(x, PERCH_Y - 0.25, -2.35)
	it.append(BMG.item_xf(box1, _strip(s0, s1, Vector3.RIGHT, 0.34, 0.34), mat_char))
	it.append(BMG.item(box1, s1 + Vector3(0, 0.02, 0.05), mat_metal, Vector3.ZERO, Vector3(0.5, 0.3, 0.55)))
	# Tip: a bronze cap and three talons hooked forward and down.
	it.append(BMG.item(box1, tip + Vector3(0, 0.05, -0.05), mat_metal, Vector3.ZERO, Vector3(1.5, 0.42, 0.34)))
	for sx: float in [-0.5, 0.0, 0.5]:
		it.append(BMG.item(_cyl(0.0, 0.13, 0.62, 4), tip + Vector3(sx, -0.22, -0.3), mat_metal, Vector3(-150, 45, 0)))
	# Claw scratches (glowing) along the top.
	for sx: float in [-0.28, 0.0, 0.28]:
		var a := Vector3(x + sx, PERCH_Y + 0.33, -1.0)
		var b := Vector3(x + sx + 0.08, PERCH_Y + 0.37, -2.5)
		it.append(BMG.item_xf(box1, _strip(a, b, Vector3.RIGHT, 0.07, 0.03), mat_lava))
	_merged("PerchParts", "perch", it, _perch)


## The nest crown (one construction part that topples on collapse): a charred bowl, an ember bed with glowing lumps,
## two woven rings of crossed charred beams flaring outward, jagged beam spikes with ember tips and bronze bands, team
## lashings, two team banners hanging under the rim (+X and -X). The front / +X spikes snap below 50 % HP.
func _build_nest(box1: BoxMesh, rng: RandomNumberGenerator) -> void:
	_nest = Node3D.new()
	_nest.name = "Nest"
	_nest.position = Vector3(SPIRE.x, NEST_Y, SPIRE.z)
	_body.add_child(_nest)
	var it: Array = []
	it.append(BMG.item(_cyl(2.0, 1.3, 0.85, 10), Vector3(0, 0.42, 0), mat_char))
	it.append(BMG.item(_cyl(1.2, 1.2, 0.3, 10), Vector3(0, -0.05, 0), mat_dark))
	# Woven rings: beams along the tangent, tilted up / down alternately (they cross), leaning outward.
	for ring: int in 2:
		var n: int = 14 if ring == 0 else 16
		var r: float = 1.95 if ring == 0 else 2.3
		var y: float = 0.7 if ring == 0 else 1.2
		var ln: float = 2.1 if ring == 0 else 2.2
		for k: int in n:
			var a: float = TAU * (k + 0.5 * ring) / n
			var rd := Vector3(cos(a), 0.0, sin(a))
			var tg := Vector3(-rd.z, 0.0, rd.x)
			var phi: float = deg_to_rad(20.0 if (k + ring) % 2 == 0 else -20.0)
			var dir: Vector3 = (tg * cos(phi) + Vector3.UP * sin(phi)).normalized()
			var c: Vector3 = rd * r + Vector3(0, y + rng.randf_range(-0.06, 0.06), 0)
			var th: float = rng.randf_range(0.26, 0.34)
			it.append(BMG.item_xf(box1, _strip(c - dir * ln * 0.5, c + dir * ln * 0.5, rd, th, th), mat_char))
			if k % 2 == 1:   # team lashings (every other beam of both rings since 2026-09-30, R6)
				it.append(BMG.item_xf(box1, _strip(c - dir * 0.2, c + dir * 0.2, rd, th + 0.1, th + 0.1), mat_team))
	# Ember bed: a dark charred floor with a glowing core (the glow point), dark rocks and bright lumps.
	it.append(BMG.item(_cyl(1.72, 1.72, 0.1, 10), Vector3(0, 0.86, 0), mat_char))
	it.append(BMG.item(_cyl(0.78, 0.9, 0.1, 10), Vector3(0.1, 0.9, -0.1), mat_glow))
	for i: int in 4:
		var a: float = TAU * i / 4.0 + 0.4
		it.append(BMG.item(_cyl(0.22, 0.34, 0.3, 6), Vector3(cos(a) * 0.95, 0.98, sin(a) * 0.95), mat_dark,
			Vector3(rng.randf_range(-15, 15), rng.randf() * 60.0, rng.randf_range(-15, 15))))
	for i: int in 3:
		var a: float = TAU * i / 3.0 + 1.2
		it.append(BMG.item(_cyl(0.18, 0.28, 0.2, 6), Vector3(cos(a) * 0.5, 1.0, sin(a) * 0.5), mat_glow))
	var bowl := _merged("NestBowl", "nest_bowl", it, _nest)
	# Spikes: charred beams from inside the bowl up and out past the rim; ember tips, bronze bands. Two groups: the
	# front / +X ones (lost below 50 % HP) and the rest.
	var keep: Array = []
	var lost: Array = []
	var stubs: Array = []
	# 12 spikes every 30 deg (angle, tip height, tip radius); the back (+Z) ones are kept inside z 3.75.
	var spikes: Array[Vector3] = []
	for k: int in 12:
		var ang: float = -90.0 + 30.0 * k + (7.0 if k % 2 == 1 else -4.0)
		var hgt: float = [2.85, 2.2, 2.55][k % 3]
		var rad: float = 3.1 if k % 2 == 0 else 2.85
		var sa: float = sin(deg_to_rad(ang))
		if sa > 0.05:
			rad = minf(rad, (3.75 - SPIRE.z) / sa)
		spikes.append(Vector3(ang, hgt, rad))
	for i: int in spikes.size():
		var sp: Vector3 = spikes[i]
		var a: float = deg_to_rad(sp.x)
		var rd := Vector3(cos(a), 0.0, sin(a))
		var p0: Vector3 = rd * 1.0 + Vector3(0, 0.55, 0)
		var p1: Vector3 = rd * sp.z + Vector3(0, sp.y, 0)
		var th: float = 0.3 if i % 2 == 0 else 0.26
		var dst: Array = lost if sp.x > -60.0 and sp.x < 20.0 else keep
		dst.append(BMG.item_xf(box1, _strip(p0, p1, Vector3(-rd.z, 0, rd.x), th, th), mat_char))
		var band: Vector3 = p0.lerp(p1, 0.72)
		dst.append(BMG.item_xf(box1, _strip(band - (p1 - p0).normalized() * 0.12, band + (p1 - p0).normalized() * 0.12,
			Vector3(-rd.z, 0, rd.x), th + 0.1, th + 0.1), mat_metal))
		if i % 3 == 0:   # ember tips: lava-hot, under the bloom since 2026-09-30 (R5: the nest core stays the point)
			dst.append(BMG.item(box1, p1, mat_lava, Vector3(0, sp.x, 25), Vector3.ONE * 0.26))
		if dst == lost:
			# The snapped stub shown instead (< 50 %): a short, splintered beam end.
			var m: Vector3 = p0.lerp(p1, 0.45)
			stubs.append(BMG.item_xf(box1, _strip(p0, m, Vector3(-rd.z, 0, rd.x), th, th), mat_char))
			stubs.append(BMG.item(_cyl(0.0, th * 0.6, 0.3, 4), m + (p1 - p0).normalized() * 0.12, mat_glow,
				Vector3(0, 0, 0)))
	_merged("NestSpikes", "nest_spikes", keep, _nest)
	var lost_mi := _merged("NestSpikesFront", "nest_spikes_front", lost, _nest)
	_hide_below_50.append(lost_mi)
	var stub_mi := _merged("NestStubs", "nest_stubs", stubs, _nest, false)
	stub_mi.visible = false
	_show_below_50.append(stub_mi)
	# Burnt patch in the bowl (< 25 %): a black crater in the ember bed.
	var burn: Array = []
	burn.append(BMG.item(_cyl(0.75, 0.9, 0.08, 8), Vector3(0.6, 0.95, -0.5), _hole_mat()))
	var burn_mi := _merged("NestBurn", "nest_burn", burn, bowl, false)
	burn_mi.visible = false
	_show_below_25.append(burn_mi)
	# Banners under the rim, facing each camera.
	var bp := _banner("BannerPlayer", Vector2(1.0, 2.4), Vector3(2.15, -0.9, -0.3), 90.0, _nest)
	var be := _banner("BannerEnemy", Vector2(1.0, 2.4), Vector3(-2.25, -0.9, 0.3), -90.0, _nest)
	_hide_below_25.append(bp)
	_hide_on_collapse.append_array([bp, be])
	# Idle: flames and smoke from the ember bed.
	var fire := _pm(Vector3.UP, 14.0, 1.2, 2.0, Vector3.ZERO, 0.55, 0.12, _fire_ramp)
	fire.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	fire.emission_box_extents = Vector3(0.75, 0.05, 0.75)
	_idle_fx.append(_particles("NestFire", _nest, Vector3(0.1, 1.0, -0.1), 16, 0.75, fire, _add_quad, false))
	var sm := _pm(Vector3.UP, 10.0, 0.8, 1.2, Vector3(0.25, 0.0, 0.0), 0.8, 2.4,
		_ramp(Color(smoke_color, 0.4), Color(smoke_color, 0.0), false))
	_idle_fx.append(_particles("NestSmoke", _nest, Vector3(0, 1.9, 0), 10, 3.5, sm, _mix_quad, false))
	# Raise: a fire column out of the nest and a ring of fire round the spire foot (one-shots).
	var rb := _pm(Vector3.UP, 16.0, 7.0, 11.0, Vector3(0, -5.0, 0), 1.1, 0.25, _fire_ramp)
	rb.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	rb.emission_sphere_radius = 0.8
	_raise_burst = _particles("RaiseBurst", _nest, Vector3(0, 1.0, 0), 40, 1.2, rb, _add_quad, true)
	_raise_burst.explosiveness = 0.75
	var rr := _pm(Vector3.UP, 20.0, 2.0, 4.0, Vector3(0, -1.0, 0), 0.6, 0.12, _fire_ramp)
	rr.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	rr.emission_ring_axis = Vector3.UP
	rr.emission_ring_radius = 2.35
	rr.emission_ring_inner_radius = 2.1
	rr.emission_ring_height = 0.05
	_raise_ring = _particles("RaiseRing", _body, Vector3(SPIRE.x, 0.9, SPIRE.z), 32, 0.9, rr, _add_quad, true)
	_raise_ring.explosiveness = 0.85
	_nest_xf = _nest.transform


## Additive warm pool on the plinth: the "light" of the door and the lava, flickering with the virtual light.
func _build_pool() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	_pool_mat = StandardMaterial3D.new()
	_pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_pool_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_pool_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_pool_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_pool_mat.albedo_texture = tex
	_pool_mat.albedo_color = Color(1.0, 0.5, 0.18, 0.26)
	var pm := PlaneMesh.new()
	pm.size = Vector2(6.2, 6.2)
	_pool = MeshInstance3D.new()
	_pool.name = "LightPool"
	_pool.mesh = pm
	_pool.material_override = _pool_mat
	_pool.position = Vector3(0.2, 0.86, 0.2)
	_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pool)


## Extra wreck pieces (shown with the base wreck at 1.6 s): the fallen nest (a tilted bowl half and scattered charred
## beams), the perch slab broken on the ground in front, glowing embers.
func _build_wreck_extra(box1: BoxMesh) -> void:
	var it: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 25250
	it.append(BMG.item(_cyl(1.8, 1.2, 0.7, 10), Vector3(-0.9, 1.1, -1.9), mat_char, Vector3(28, 20, -14),
		Vector3(1.0, 1.0, 0.55)))
	for i: int in 9:
		var p := Vector3(rng.randf_range(-2.8, 2.6), rng.randf_range(0.9, 1.4), rng.randf_range(-2.9, 2.6))
		it.append(BMG.item(box1, p, mat_char, Vector3(rng.randf_range(-25, 25), rng.randf() * 180.0, rng.randf_range(-20, 20)),
			Vector3(0.3, 0.3, rng.randf_range(1.8, 2.8))))
	it.append(BMG.item(box1, Vector3(PERCH_X + 0.3, 1.1, -2.4), mat_stone, Vector3(-18, 12, 9), Vector3(1.3, 0.45, 2.4)))
	it.append(BMG.item(box1, Vector3(PERCH_X + 0.5, 1.2, -3.4), mat_metal, Vector3(-30, 12, 9), Vector3(1.4, 0.36, 0.3)))
	for i: int in 4:
		var p := Vector3(rng.randf_range(-1.8, 1.4), 1.05, rng.randf_range(-2.2, 1.8))
		it.append(BMG.item(box1, p, mat_glow, Vector3(0, rng.randf() * 90.0, 20), Vector3.ONE * 0.34))
	_merged("WreckExtra", "wreck_extra", it, _wreck)


# --- Small helpers ---

## Transform of a box running from `a` to `b` (local Z along it), `w` wide along `across` (made perpendicular), `t` thick.
func _strip(a: Vector3, b: Vector3, across: Vector3, w: float, t: float) -> Transform3D:
	var z: Vector3 = b - a
	var len: float = z.length()
	z = z / maxf(len, 0.0001)
	var x: Vector3 = (across - z * across.dot(z))
	if x.length() < 0.001:
		x = Vector3.UP if absf(z.y) < 0.9 else Vector3.RIGHT
		x = x - z * x.dot(z)
	x = x.normalized()
	var y: Vector3 = z.cross(x).normalized()
	return Transform3D(Basis(x, y, z).scaled_local(Vector3(w, t, len)), (a + b) * 0.5)

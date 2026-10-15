class_name GloomForgeModel
extends ShadowHallModel
## Visual model of Malrik's Forge, the Gloom Forge (task G-B leftovers, docs/art/gb_leftovers.md; unit-upgrades.md:
## kind &"forge", 3 x 3 cells = 6 x 6 m, data height 4). It replaces the ForgeBuilding placeholder through
## BuildingType.model_path (data/buildings/shadow_forge.tres), in the Gloom Hall's language, and inherits its G-B
## dressing (ShadowDress: dead ground, mist, wisps, embers, a soft light at Ultra; nothing at Low) and its stepped
## team / dark-team slate courses.
## Read from the RTS camera:
## - Dominant vertical (back left, ~7 m): the soul furnace, a tapering obsidian stack banded in iron-silver, gripped
##   by three obsidian claws, crowned by a cage of iron spikes holding a floating soul flame (a violet orb that bobs).
## - The smithy (back right): a crypt-forge of dark stone under a steep slate roof in the team colour with an iron
##   spike crest, a pointed forge arch glowing violet on its front (it flares when a research completes), corner
##   pinnacles, a lancet slit.
## - The yard in front (asymmetric): an obsidian anvil on a skull-marked block (left), an ichor quench basin glowing
##   violet and a rack of silver blades (right), a chain gallows with a hook, a team banner on a spiked post.
## Hooks (FireHallModel contract, art-keep.md 8.8): set_team_color, set_construction_progress, set_health_ratio,
## play_training_pulse, play_destroyed (-> destroyed_finished after 3 s), set_selected. No active light.

const SX := 0.7       ## smithy axis x
const SZ := 0.95      ## smithy centre z
const SWX := 1.75     ## smithy half-width
const SWZ := 1.5      ## smithy half-depth
const S_WALL := 2.7
const FURNACE := Vector3(-1.95, PLINTH_TOP, 1.6)
const ORB_Y := 6.2    ## furnace-local height of the soul flame


## Gloom Forge parts (Body space, gate -Z). Heights: plinth 0.8, smithy walls 3.5, roof ridge ~6.1, furnace cage ~7.3.
## Tiers: PlinthBase, Walls (smithy, forge arch), Roof, Furnace (falls on the collapse; its cage and flame are lost
## under 50 %), Yard (anvil, basin, blade rack, gallows).
func _build_structure() -> void:
	_top_y = 7.4
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var pt: float = PLINTH_TOP
	var rng := RandomNumberGenerator.new()
	rng.seed = 7402
	var slab_a: ShaderMaterial = _painted_mat(stone_color.lightened(0.14), 0.0, 0.0)
	var slab_b: ShaderMaterial = _painted_mat(dark_color.lightened(0.1), 0.1, 0.0)
	var obsidian: ShaderMaterial = _painted_mat(Color(0.06, 0.05, 0.09), 0.55, 0.0)
	# --- Plinth: two dark tiers, corner blocks, steps, cracked grave-slab rim, scattered bones by the furnace.
	var it: Array = []
	it.append(BMG.item(box1, Vector3(0, 0.25, 0), mat_dark, Vector3.ZERO, Vector3(6.3, 0.5, 6.3)))
	it.append(BMG.item(box1, Vector3(0, 0.65, 0), mat_dark, Vector3.ZERO, Vector3(5.75, 0.3, 5.75)))
	for c: Vector2 in [Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		it.append(BMG.item(box1, Vector3(c.x * 2.7, 0.95, c.y * 2.7), mat_dark, Vector3.ZERO, Vector3(0.7, 0.4, 0.7)))
		it.append(BMG.item(_cyl(0.0, 0.16, 0.7, 4), Vector3(c.x * 2.7, 1.5, c.y * 2.7), mat_metal, Vector3(0, 45, 0)))
	it.append(BMG.item(box1, Vector3(0.0, 0.14, -3.4), mat_dark, Vector3.ZERO, Vector3(2.4, 0.28, 0.5)))
	for i: int in 3:
		var p := Vector3(rng.randf_range(-0.35, 0.35), 0.04, -3.95 - 0.68 * i)
		it.append(BMG.item(box1, p, mat_dark, Vector3(0, rng.randf_range(-20, 20), 0),
			Vector3(rng.randf_range(0.75, 0.95), 0.1, rng.randf_range(0.5, 0.6))))
	for k: int in 16:
		var side: int = k / 4
		var t: float = -2.2 + 1.47 * float(k % 4)
		var fp: Vector3 = [Vector3(t, 0, -2.6), Vector3(2.6, 0, t), Vector3(-t, 0, 2.6), Vector3(-2.6, 0, -t)][side]
		if fp.distance_to(Vector3(0, 0, -2.6)) < 1.1:
			continue
		it.append(BMG.item(box1, fp + Vector3(0, 0.815, 0), slab_a if k % 3 != 1 else slab_b,
			Vector3(rng.randf_range(-2, 2), rng.randf_range(-7, 7), rng.randf_range(-2, 2)),
			Vector3(1.3, 0.07, 0.5) if side % 2 == 0 else Vector3(0.5, 0.07, 1.3)))
	for i: int in 4:
		var p := Vector3(-0.6 + rng.randf_range(-0.4, 0.4), pt + 0.06, 2.45 + rng.randf_range(-0.2, 0.2))
		it.append(BMG.item(_cyl(0.05, 0.06, rng.randf_range(0.5, 0.8), 5), p, slab_a, Vector3(90, rng.randf() * 180.0, 0)))
	_merged("PlinthBase", "plinth", it)
	# --- Walls: crypt smithy, base course, corner piers with pinnacles, the pointed forge arch, a lancet slit.
	it = []
	it.append(BMG.item(box1, Vector3(SX, pt + 0.22, SZ), mat_dark, Vector3.ZERO, Vector3(SWX * 2.0 + 0.3, 0.44, SWZ * 2.0 + 0.3)))
	it.append(BMG.item(box1, Vector3(SX, pt + S_WALL * 0.5, SZ), mat_stone, Vector3.ZERO, Vector3(SWX * 2.0, S_WALL, SWZ * 2.0)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var cp := Vector3(SX + c.x * SWX, 0, SZ + c.y * SWZ)
		it.append(BMG.item(box1, cp + Vector3(0, pt + S_WALL * 0.5 + 0.1, 0), mat_dark, Vector3.ZERO,
			Vector3(0.5, S_WALL + 0.2, 0.5)))
		it.append(BMG.item(_cyl(0.0, 0.26, 0.9, 4), cp + Vector3(0, pt + S_WALL + 0.65, 0), mat_dark, Vector3(0, 45, 0)))
		for q: int in 4:
			it.append(BMG.item(box1, cp + Vector3(0, pt + 0.5 + 0.62 * q, 0), slab_a if q % 2 == 0 else mat_stone,
				Vector3(0, rng.randf_range(-3, 3), 0), Vector3(0.62 if q % 2 == 0 else 0.54, 0.22, 0.54 if q % 2 == 0 else 0.62)))
	var fz: float = SZ - SWZ
	it.append(BMG.item(box1, Vector3(SX, pt + 1.05, fz - 0.22), mat_dark, Vector3.ZERO, Vector3(2.0, 2.1, 0.55)))
	it.append(BMG.item(_prism(Vector3(2.0, 1.25, 0.55), 0.5), Vector3(SX, pt + 2.72, fz - 0.22), mat_dark))
	it.append(BMG.item(box1, Vector3(SX, pt + 0.95, fz - 0.52), mat_gate, Vector3.ZERO, Vector3(1.25, 1.7, 0.08)))
	it.append(BMG.item(_prism(Vector3(1.25, 0.75, 0.08), 0.5), Vector3(SX, pt + 2.17, fz - 0.52), mat_gate))
	var arch_a: float = atan2(1.25, 1.0)
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.BACK, -s * arch_a).scaled_local(Vector3(1.6, 0.22, 0.65)),
			Vector3(SX + s * 0.52, pt + 2.75, fz - 0.24)), mat_metal))
	it.append(BMG.item(_cyl(0.0, 0.16, 0.8, 4), Vector3(SX, pt + 3.7, fz - 0.24), mat_metal, Vector3(0, 45, 0)))
	# Glowing coal bed at the sill (violet soul-coals).
	it.append(BMG.item(box1, Vector3(SX, pt + 0.2, fz - 0.68), mat_dark, Vector3.ZERO, Vector3(1.5, 0.3, 0.42)))
	it.append(BMG.item(box1, Vector3(SX, pt + 0.37, fz - 0.68), mat_glow, Vector3.ZERO, Vector3(1.1, 0.05, 0.28)))
	# Lancet slit on the right wall.
	var lp := Vector3(SX + SWX + 0.02, pt + 1.6, SZ + 0.2)
	it.append(BMG.item(box1, lp, mat_dark, Vector3.ZERO, Vector3(0.2, 1.5, 0.6)))
	it.append(BMG.item(box1, lp + Vector3(0.06, 0, 0), mat_gate, Vector3.ZERO, Vector3(0.1, 1.15, 0.3)))
	it.append(BMG.item(_cyl(0.0, 0.42, 0.45, 4), lp + Vector3(0, 0.95, 0), mat_dark, Vector3.ZERO, Vector3(0.4, 1.0, 1.0)))
	_merged("Walls", "walls", it)
	# --- Roof: steep slate gable (alternating team / dark-team courses), spike crest, eave spikes.
	it = []
	mat_team_dark = _painted_mat(kingdom_color.darkened(1.0 - TEAM_DARK), 0.1, 0.0)
	var eave: float = pt + S_WALL
	var rise: float = 2.55
	var half: float = SWX + 0.32
	var first: int = it.size()
	_gable_roof(it, SX, SZ, half, eave, rise, SWZ * 2.0 + 0.5, SWZ * 2.0 - 0.1, 5, mat_stone, mat_team, mat_metal, 0.0, 9.0)
	var tile_n: int = 0
	for i: int in range(first, it.size()):
		if it[i][2] == mat_team:
			if tile_n % 2 == 1:
				it[i][2] = mat_team_dark
			tile_n += 1
	for i: int in 5:
		it.append(BMG.item(_cyl(0.0, 0.16, 0.6, 4), Vector3(SX, eave + rise + 0.5, SZ - 1.4 + 0.7 * i), mat_metal,
			Vector3(0, 45, 0)))
	for sx: float in [-1.0, 1.0]:
		for k: int in 4:
			var ep := Vector3(SX + sx * (half + 0.05), eave - 0.05, SZ - 1.35 + 0.9 * k)
			var eb: Basis = Basis(Quaternion(Vector3.UP, Vector3(sx, -0.35, 0).normalized()))
			it.append(BMG.item_xf(_cyl(0.0, 0.07, 0.45, 4), Transform3D(eb, ep + eb * Vector3(0, 0.2, 0)), mat_metal))
	it.append(BMG.item(_cyl(0.48, 0.48, 0.14, 10), Vector3(SX, eave + 1.0, fz - 0.27), mat_dark, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.34, 0.34, 0.08, 10), Vector3(SX, eave + 1.0, fz - 0.35), mat_gate, Vector3(90, 0, 0)))
	var roof := _merged("Roof", "roof", it)
	_hide_on_collapse.append(roof)
	var hole_l: Vector3 = _gable_point(SX, half, eave, rise, -1.0, 0.5, 0.32, SZ + 0.5)
	var hole_r: Vector3 = _gable_point(SX, half, eave, rise, 1.0, 0.4, 0.32, SZ - 0.3)
	_show_below_50.append(_roof_hole("RoofHoleL", roof, hole_l, -1.0, half, rise, false))
	_show_below_25.append(_roof_hole("RoofHoleR", roof, hole_r, 1.0, half, rise, true))
	# --- Soul furnace (dominant vertical; falls on the collapse): obsidian stack, iron-silver bands, claws, cage.
	var furnace := Node3D.new()
	furnace.name = "Furnace"
	furnace.position = FURNACE
	_body.add_child(furnace)
	it = []
	it.append(BMG.item(box1, Vector3(0, 0.5, 0), mat_dark, Vector3(0, 8, 0), Vector3(1.45, 1.0, 1.45)))
	it.append(BMG.item(_cyl(0.42, 0.82, 4.4, 4), Vector3(0, 3.2, 0), obsidian, Vector3(0, 53, 0)))
	for y: float in [1.5, 2.9, 4.3]:
		var r: float = lerpf(0.84, 0.44, (y - 1.0) / 4.4) + 0.06
		it.append(BMG.item(_cyl(r, r, 0.18, 4), Vector3(0, y, 0), mat_metal, Vector3(0, 53, 0)))
	# Glowing fire mouth at the foot, facing the yard.
	it.append(BMG.item(box1, Vector3(0.12, 0.5, -0.74), mat_dark, Vector3(0, -20, 0), Vector3(0.75, 0.7, 0.12)))
	it.append(BMG.item(box1, Vector3(0.12, 0.47, -0.79), mat_glow, Vector3(0, -20, 0), Vector3(0.5, 0.46, 0.06)))
	# Three obsidian claws gripping the stack.
	for i: int in 3:
		var a: float = TAU * float(i) / 3.0 + 0.4
		var d := Vector3(cos(a), 0, sin(a))
		var b: Basis = Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(-22.0))
		it.append(BMG.item_xf(_cyl(0.0, 0.22, 1.9, 4), Transform3D(b, d * 0.9 + Vector3(0, 1.75, 0)), obsidian))
	_merged("FurnaceStack", "furnace_stack", it, furnace)
	it = []
	it.append(BMG.item(_cyl(0.6, 0.48, 0.3, 4), Vector3(0, 5.5, 0), mat_dark, Vector3(0, 53, 0)))
	for i: int in 6:
		var a: float = TAU * float(i) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		var b: Basis = Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(-12.0))
		it.append(BMG.item_xf(_cyl(0.0, 0.07, 1.3, 4), Transform3D(b, d * 0.5 + Vector3(0, 6.2, 0)), mat_metal))
	var cage := _merged("FurnaceCage", "furnace_cage", it, furnace)
	_hide_below_50.append(cage)
	_orb_y = ORB_Y
	var orb := _part("SoulOrb", _sphere(0.26), Vector3(0, ORB_Y, 0), mat_glow, Vector3.ZERO, furnace)
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_orb = orb
	_hide_below_50.append(orb)
	var fb := _banner("FurnaceBanner", Vector2(0.8, 1.7), Vector3(0.0, 2.9, -0.74), -20.0, furnace)
	_hide_below_25.append(fb)
	_hide_on_collapse.append(fb)
	_falling = furnace
	_fall_axis = Vector3(1, 0, 0.3).normalized()
	_fall_deg = -30.0
	# --- Yard: the obsidian anvil (left), the ichor basin and the blade rack (right), the chain gallows.
	var yard := Node3D.new()
	yard.name = "Yard"
	_body.add_child(yard)
	it = []
	var an := Vector3(-1.55, pt, -1.75)
	it.append(BMG.item(box1, an + Vector3(0, 0.3, 0), mat_stone, Vector3(0, 15, 0), Vector3(0.62, 0.6, 0.5)))
	it.append(BMG.item(box1, an + Vector3(0, 0.33, -0.26), mat_gate, Vector3(0, 15, 0), Vector3(0.2, 0.16, 0.03)))   # a skull rune
	it.append(BMG.item(box1, an + Vector3(0, 0.71, 0), obsidian, Vector3(0, 15, 0), Vector3(0.8, 0.22, 0.36)))
	it.append(BMG.item(_cyl(0.0, 0.13, 0.5, 4), an + Vector3(-0.6, 0.72, 0.16), obsidian, Vector3(0, 15, 90)))
	it.append(BMG.item(box1, an + Vector3(0.05, 0.86, 0), mat_metal, Vector3(0, 40, 0), Vector3(0.5, 0.05, 0.08)))
	var ba := Vector3(1.55, pt, -2.0)
	it.append(BMG.item(_cyl(0.62, 0.48, 0.55, 6), ba + Vector3(0, 0.27, 0), mat_dark))
	it.append(BMG.item(_cyl(0.68, 0.68, 0.08, 6), ba + Vector3(0, 0.56, 0), mat_metal))
	it.append(BMG.item(_cyl(0.52, 0.52, 0.03, 6), ba + Vector3(0, 0.5, 0), mat_gate))
	# Blade rack.
	it.append(BMG.item(box1, Vector3(2.55, pt + 1.1, -0.8), mat_dark, Vector3.ZERO, Vector3(0.18, 0.18, 1.6)))
	for z: float in [-1.5, -0.1]:
		it.append(BMG.item(box1, Vector3(2.55, pt + 0.6, z), mat_dark, Vector3.ZERO, Vector3(0.18, 1.2, 0.18)))
	for i: int in 3:
		it.append(BMG.item(_prism(Vector3(0.22, 1.5, 0.05), 0.5), Vector3(2.66, pt + 0.95, -1.2 + 0.4 * i), mat_metal,
			Vector3(180, 90, 6.0 - 6.0 * i)))
	# Chain gallows: two posts and a beam with a hanging chain and hook (front left of the furnace).
	var gp := Vector3(-2.65, pt, 0.0)
	it.append(BMG.item(box1, gp + Vector3(0, 1.3, 0), mat_dark, Vector3.ZERO, Vector3(0.18, 2.6, 0.18)))
	it.append(BMG.item(box1, gp + Vector3(0.45, 2.55, 0), mat_dark, Vector3.ZERO, Vector3(1.1, 0.16, 0.16)))
	for k: int in 5:
		it.append(BMG.item(box1, gp + Vector3(0.85, 2.35 - 0.2 * k, 0), mat_metal, Vector3(0, 90.0 * float(k % 2), 0),
			Vector3(0.05, 0.2, 0.12)))
	it.append(BMG.item(_cyl(0.0, 0.08, 0.3, 4), gp + Vector3(0.85, 1.25, 0), mat_metal, Vector3(180, 0, 0)))
	# Banner post with a spike.
	it.append(BMG.item(_cyl(0.06, 0.08, 2.8, 4), Vector3(-0.95, pt + 1.4, -2.85), mat_dark))
	it.append(BMG.item(box1, Vector3(-0.95, pt + 2.68, -2.85), mat_metal, Vector3.ZERO, Vector3(0.8, 0.08, 0.08)))
	it.append(BMG.item(_cyl(0.0, 0.1, 0.45, 4), Vector3(-0.95, pt + 3.0, -2.85), mat_metal, Vector3(0, 45, 0)))
	_merged("YardParts", "yard", it, yard, false)
	_hide_on_collapse.append(yard)
	var bn := _banner("Banner", Vector2(0.7, 1.55), Vector3(-0.95, pt + 1.85, -2.9), 0.0)
	_hide_below_25.append(bn)
	_hide_on_collapse.append(bn)
	_light = _omni(Vector3(SX, 1.3, -1.4), 6.0)
	# Idle particles: soul flame round the orb, violet sparks off the anvil, vapour off the basin, motes round the forge.
	var flame := _pm(Vector3.UP, 14.0, 0.7, 1.2, Vector3.ZERO, 0.4, 0.08, _fire_ramp)
	flame.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	flame.emission_sphere_radius = 0.22
	_idle_fx.append(_particles("SoulFlame", furnace, Vector3(0, ORB_Y, 0), 12, 0.8, flame, _add_quad, false))
	var sp := _pm(Vector3(0.3, 1.0, -0.4), 40.0, 1.0, 2.0, Vector3(0, -3.5, 0), 0.08, 0.03,
		_ramp(Color(0.72, 0.48, 0.95), Color(0.35, 0.12, 0.55), false))   # under the bloom (no violet puff at High)
	_idle_fx.append(_particles("AnvilSparks", yard, an + Vector3(0.05, 0.9, 0), 8, 0.8, sp, _add_quad, false))
	# A dark ichor fume (a pale one read as a white puff at the forge's foot).
	var vap := _pm(Vector3.UP, 15.0, 0.12, 0.3, Vector3(0.05, 0.04, 0), 0.25, 0.6,
		_ramp(Color(0.2, 0.09, 0.3, 0.35), Color(0.12, 0.05, 0.18), false))
	vap.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	vap.emission_sphere_radius = 0.35
	_idle_fx.append(_particles("IchorVapour", yard, ba + Vector3(0, 0.6, 0), 6, 2.4, vap, _mix_quad, false))
	var motes := _pm(Vector3.UP, 30.0, 0.3, 0.7, Vector3.ZERO, 0.11, 0.04,
		_ramp(Color(0.55, 0.32, 0.78), Color(0.25, 0.08, 0.42), false))
	motes.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	motes.emission_ring_axis = Vector3.UP
	motes.emission_ring_radius = 2.9
	motes.emission_ring_inner_radius = 2.0
	motes.emission_ring_height = 0.1
	motes.orbit_velocity_min = 0.08
	motes.orbit_velocity_max = 0.12
	_idle_fx.append(_particles("VoidMotes", _body, Vector3(0, 1.0, 0), 10, 4.0, motes, _add_quad, false))
	# Construction scaffolding, the collapse wreck (the furnace stump), an ash stain under the basin.
	_build_scaffold(SX - 0.5, SZ - 0.3, 5.4, 4.6, 3.8)
	_build_wreck(SX, SZ, SWX * 2.0, SWZ * 2.0, pt + S_WALL * 0.3, FURNACE + Vector3(0, 0.95, 0), Vector3(1.6, 1.9, 1.6), 7474)
	_scorch_decal(Vector3(1.4, 0.035, -1.9), 3.0, Color(0.12, 0.04, 0.18, 0.5))
	_smoke_points = [hole_l + Vector3(0, 0.3, 0), FURNACE + Vector3(0, 4.3, 0)]
	_blaze_points = [hole_r + Vector3(0, 0.2, 0), Vector3(SX, pt + 1.0, fz - 0.6)]
	_rubble2_points = [FURNACE + Vector3(0.7, 0.05, -0.7), FURNACE + Vector3(-0.4, 0.05, -1.0), FURNACE + Vector3(0.9, 0.05, 0.5)]
	_gate_pos = Vector3(SX, pt + 0.9, fz - 0.75)

class_name EmberForgeModel
extends FireHallModel
## Visual model of Vessa's Forge, the Ember Forge (task G-B leftovers, docs/art/gb_leftovers.md; unit-upgrades.md:
## kind &"forge", 3 x 3 cells = 6 x 6 m, data height 4). It replaces the ForgeBuilding placeholder through
## BuildingType.model_path (data/buildings/fire_forge.tres), in the Ember Hall's language on the G-B Fire paint layer
## (fire_painted_vc: ashlar stone, clay tiles on the team slopes, timber, bronze with patina, soot, ember bounce).
## Read from the RTS camera:
## - Dominant vertical (back right, ~7 m): a round smelting kiln of banded basalt, a tapering stack with bronze hoops
##   and a flared crown whose rim glows, a glowing fire hole at its foot, a bellows of timber and leather feeding it.
## - The smithy (back left): a squat ashlar house under a clay-tiled team gable with crossed bronze bargeboards, a wide
##   forge arch glowing on its front (it flares when a research completes: play_training_pulse), warm side slits.
## - The yard in front (asymmetric): a bronze anvil on a timber stump under a lean-to roofed in team clay tiles (left), a
##   lava quench trough and a stack of bronze ingots (right), a hammer rack, a team banner on a post.
## Hooks (FireHallModel contract, art-keep.md 8.8): set_team_color, set_construction_progress, set_health_ratio,
## play_training_pulse, play_destroyed (-> destroyed_finished after 3 s), set_selected. No active light (emissive and
## the B8 light pool only). Heat haze over the kiln crown and the trough at High / Ultra (FireBuildingLook).

const HX := -0.75     ## smithy axis x
const HZ := 0.95      ## smithy centre z
const WX := 1.9       ## smithy half-width
const WZ := 1.45      ## smithy half-depth
const WALL_H := 2.55
const KILN := Vector3(1.85, PLINTH_TOP, 1.55)
const STACK_TOP := 6.2   ## kiln-local height of the crown rim


func _gb_fire() -> bool:
	return true


func _idle_motion(_delta: float) -> void:
	pass


## Ember Forge parts (Body space, gate -Z). Heights: plinth 0.8, smithy walls 3.35, roof ridge ~5.1, kiln crown ~7.1.
## Tiers: PlinthBase, Walls (smithy, forge arch, bellows), Roof, Kiln (falls on the collapse; its crown is lost under
## 50 %), Yard (lean-to, anvil, trough, ingots, rack).
func _build_structure() -> void:
	_top_y = 7.3
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var pt: float = PLINTH_TOP
	mat_wood = _painted_mat(Color(0.36, 0.22, 0.12), 0.0, 0.0)
	var lava: ShaderMaterial = _glow_mat(1.4, 0.7, 0)   # under the bloom: the forge mouth and kiln fire stay the bright points
	var flag_a: ShaderMaterial = _painted_mat(stone_color.lightened(0.12), 0.0, 0.0)
	var flag_b: ShaderMaterial = _painted_mat(stone_color.darkened(0.12), 0.0, 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7301
	# --- Plinth: two basalt tiers, corner blocks, the gate steps, a rim of worn flagstones, a path out of the yard.
	var it: Array = []
	it.append(BMG.item(box1, Vector3(0, 0.25, 0), mat_dark, Vector3.ZERO, Vector3(6.3, 0.5, 6.3)))
	it.append(BMG.item(box1, Vector3(0, 0.65, 0), mat_dark, Vector3.ZERO, Vector3(5.75, 0.3, 5.75)))
	for c: Vector2 in [Vector2(-1, 1), Vector2(1, -1)]:
		it.append(BMG.item(box1, Vector3(c.x * 2.7, 0.92, c.y * 2.7), mat_dark, Vector3(0, 8 * c.x, 0), Vector3(0.7, 0.36, 0.7)))
	it.append(BMG.item(box1, Vector3(-0.2, 0.14, -3.4), mat_dark, Vector3.ZERO, Vector3(2.6, 0.28, 0.5)))
	for i: int in 3:
		var p := Vector3(-0.2 + rng.randf_range(-0.4, 0.4), 0.04, -3.95 - 0.68 * i)
		it.append(BMG.item(box1, p, mat_dark, Vector3(0, rng.randf_range(-22, 22), 0),
			Vector3(rng.randf_range(0.75, 1.0), 0.1, rng.randf_range(0.5, 0.62))))
	for k: int in 16:
		var side: int = k / 4
		var t: float = -2.2 + 1.47 * float(k % 4)
		var fp: Vector3 = [Vector3(t, 0, -2.6), Vector3(2.6, 0, t), Vector3(-t, 0, 2.6), Vector3(-2.6, 0, -t)][side]
		if fp.distance_to(Vector3(-0.2, 0, -2.6)) < 1.1:
			continue
		it.append(BMG.item(box1, fp + Vector3(0, 0.815, 0), flag_a if k % 3 != 1 else flag_b,
			Vector3(rng.randf_range(-1.5, 1.5), rng.randf_range(-6, 6), rng.randf_range(-1.5, 1.5)),
			Vector3(1.3, 0.07, 0.5) if side % 2 == 0 else Vector3(0.5, 0.07, 1.3)))
	# Yard paving in front of the smithy (worn flags, two shades): the yard reads as a work floor, not a black slab.
	for i: int in 4:
		for j: int in 3:
			var fp2 := Vector3(-2.1 + 1.15 * i + rng.randf_range(-0.08, 0.08), 0.815, -2.05 + 0.9 * j + rng.randf_range(-0.06, 0.06))
			if fp2.z > -0.4 and fp2.x < 1.2:
				continue   # under the smithy
			it.append(BMG.item(box1, fp2, flag_a if (i + j) % 3 != 0 else flag_b, Vector3(rng.randf_range(-1.5, 1.5),
				rng.randf_range(-5, 5), rng.randf_range(-1.5, 1.5)), Vector3(1.05, 0.06, 0.8)))
	# Slag heap at the kiln foot (dark lumps with a few glowing ones).
	for i: int in 7:
		var p := Vector3(2.75 + rng.randf_range(-0.3, 0.2), pt + rng.randf_range(0.0, 0.15), 0.1 + rng.randf_range(-0.5, 0.4))
		it.append(BMG.item(box1, p, mat_dark if i % 3 != 0 else lava, Vector3(rng.randf_range(-30, 30), rng.randf() * 90.0,
			rng.randf_range(-30, 30)), Vector3.ONE * rng.randf_range(0.2, 0.34)))
	_merged("PlinthBase", "plinth", it, null, false)
	# --- Walls: ashlar smithy, dark base course, quoined corner piers, the forge arch, side slits, the bellows.
	it = []
	it.append(BMG.item(box1, Vector3(HX, pt + 0.2, HZ), mat_dark, Vector3.ZERO, Vector3(WX * 2.0 + 0.3, 0.4, WZ * 2.0 + 0.3)))
	it.append(BMG.item(box1, Vector3(HX, pt + WALL_H * 0.5, HZ), mat_stone, Vector3.ZERO, Vector3(WX * 2.0, WALL_H, WZ * 2.0)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var cp := Vector3(HX + c.x * WX, 0, HZ + c.y * WZ)
		it.append(BMG.item(box1, cp + Vector3(0, pt + WALL_H * 0.5 + 0.05, 0), mat_dark, Vector3.ZERO,
			Vector3(0.5, WALL_H + 0.1, 0.5)))
		for q: int in 4:
			var long_x: bool = q % 2 == 0
			it.append(BMG.item(box1, cp + Vector3(0, pt + 0.45 + 0.6 * q, 0), flag_a if long_x else mat_stone,
				Vector3(0, rng.randf_range(-3, 3), 0), Vector3(0.66 if long_x else 0.56, 0.24, 0.56 if long_x else 0.66)))
	# The forge arch on the front (-Z): a deep dark frame, a round arch, the glowing mouth, bronze keystone + imposts.
	var fz: float = HZ - WZ
	it.append(BMG.item(box1, Vector3(HX, pt + 0.95, fz - 0.2), mat_dark, Vector3.ZERO, Vector3(2.3, 1.9, 0.5)))
	it.append(BMG.item(_cyl(1.15, 1.15, 0.5, 14), Vector3(HX, pt + 1.9, fz - 0.2), mat_dark, Vector3(90, 0, 0)))
	it.append(BMG.item(box1, Vector3(HX, pt + 0.85, fz - 0.47), mat_gate, Vector3.ZERO, Vector3(1.5, 1.5, 0.08)))
	it.append(BMG.item(_cyl(0.75, 0.75, 0.08, 12), Vector3(HX, pt + 1.6, fz - 0.47), mat_gate, Vector3(90, 0, 0)))
	it.append(BMG.item(box1, Vector3(HX, pt + 3.0, fz - 0.28), mat_metal, Vector3.ZERO, Vector3(0.45, 0.5, 0.6)))
	for sx: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, Vector3(HX + sx * 1.18, pt + 1.9, fz - 0.28), mat_metal, Vector3.ZERO, Vector3(0.36, 0.26, 0.62)))
	# Coal bed glowing at the mouth's sill.
	it.append(BMG.item(box1, Vector3(HX, pt + 0.2, fz - 0.62), mat_dark, Vector3.ZERO, Vector3(1.7, 0.3, 0.45)))
	it.append(BMG.item(box1, Vector3(HX, pt + 0.37, fz - 0.62), mat_glow, Vector3.ZERO, Vector3(1.3, 0.06, 0.3)))
	# Warm side slits (left, back).
	for w: Array in [[Vector3(HX - WX - 0.02, pt + 1.5, HZ - 0.2), true], [Vector3(HX + 0.6, pt + 1.5, HZ + WZ + 0.02), false]]:
		var p: Vector3 = w[0]
		var side_w: bool = w[1]
		it.append(BMG.item(box1, p, mat_dark, Vector3.ZERO, Vector3(0.2, 1.1, 0.75) if side_w else Vector3(0.75, 1.1, 0.2)))
		it.append(BMG.item(box1, p + (Vector3(-0.06, 0, 0) if side_w else Vector3(0, 0, 0.06)), mat_gate, Vector3.ZERO,
			Vector3(0.1, 0.8, 0.4) if side_w else Vector3(0.4, 0.8, 0.1)))
	# The bellows between the smithy and the kiln: timber boards, a leather bag (dark), a bronze nozzle into the kiln.
	var bw := Vector3(1.55, pt, -0.15)
	it.append(BMG.item(box1, bw + Vector3(0, 0.35, 0), mat_wood, Vector3(0, 20, 0), Vector3(0.55, 0.7, 0.55)))
	it.append(BMG.item(_prism(Vector3(1.2, 0.5, 0.7), 0.0), bw + Vector3(0, 0.95, 0), mat_dark, Vector3(0, 20, 0)))
	it.append(BMG.item(box1, bw + Vector3(0, 0.72, 0), mat_wood, Vector3(0, 20, 0), Vector3(1.3, 0.08, 0.75)))
	it.append(BMG.item(box1, bw + Vector3(0.05, 1.22, 0.02), mat_wood, Vector3(0, 20, 14), Vector3(1.3, 0.08, 0.75)))
	it.append(BMG.item(_cyl(0.06, 0.1, 0.9, 6), bw + Vector3(0.3, 0.85, 0.9), mat_metal, Vector3(70, 20, 0)))
	_merged("Walls", "walls", it)
	# --- Roof: clay-tiled team gable (ridge along z), crossed bronze bargeboards, a chimney pot over the forge arch.
	it = []
	var eave: float = pt + WALL_H
	_gable_roof(it, HX, HZ, WX + 0.3, eave, 1.6, WZ * 2.0 + 0.55, WZ * 2.0 - 0.1, 3, mat_stone, mat_team, mat_metal, 0.6)
	it.append(BMG.item(box1, Vector3(HX - 0.4, eave + 1.35, HZ - 0.5), mat_stone, Vector3.ZERO, Vector3(0.6, 1.6, 0.6)))
	it.append(BMG.item(box1, Vector3(HX - 0.4, eave + 2.2, HZ - 0.5), mat_metal, Vector3.ZERO, Vector3(0.75, 0.16, 0.75)))
	it.append(BMG.item(_cyl(0.18, 0.24, 0.5, 8), Vector3(HX - 0.4, eave + 2.5, HZ - 0.5), mat_dark))
	it.append(BMG.item(_cyl(0.42, 0.42, 0.12, 10), Vector3(HX, eave + 0.85, fz - 0.33), mat_team, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.52, 0.52, 0.08, 10), Vector3(HX, eave + 0.85, fz - 0.29), mat_metal, Vector3(90, 0, 0)))
	var roof := _merged("Roof", "roof", it)
	_hide_on_collapse.append(roof)
	var hole_l: Vector3 = _gable_point(HX, WX + 0.3, eave, 1.6, -1.0, 0.5, 0.3, HZ + 0.4)
	var hole_r: Vector3 = _gable_point(HX, WX + 0.3, eave, 1.6, 1.0, 0.45, 0.3, HZ + 0.6)
	_show_below_50.append(_roof_hole("RoofHoleL", roof, hole_l, -1.0, WX + 0.3, 1.6, false))
	_show_below_25.append(_roof_hole("RoofHoleR", roof, hole_r, 1.0, WX + 0.3, 1.6, true))
	# --- Kiln (dominant vertical; falls on the collapse): banded basalt drum, glowing fire hole, tapering stack.
	var kiln := Node3D.new()
	kiln.name = "Kiln"
	kiln.position = KILN
	_body.add_child(kiln)
	it = []
	it.append(BMG.item(_cyl(1.05, 1.22, 2.2, 10), Vector3(0, 1.1, 0), mat_stone))
	for y: float in [0.25, 1.15, 2.1]:
		it.append(BMG.item(_cyl(1.12 - y * 0.05 + 0.05, 1.12 - y * 0.05 + 0.05, 0.16, 10), Vector3(0, y, 0),
			mat_metal if y > 0.5 else mat_dark))
	# Proud blocks round the drum (ashlar courses read from above).
	for k: int in 10:
		var a: float = TAU * float(k) / 10.0 + (0.3 if k % 2 == 0 else 0.0)
		var d := Vector3(cos(a), 0, sin(a))
		it.append(BMG.item(box1, d * 1.1 + Vector3(0, 0.7 + 0.8 * float(k % 2), 0), flag_a if k % 3 == 0 else flag_b,
			Vector3(0, -rad_to_deg(a), 0), Vector3(0.14, 0.32, 0.55)))
	# The fire hole facing the yard (-Z, turned toward the anvil).
	var fh := Vector3(-0.55, 0.55, -0.92)
	it.append(BMG.item(box1, fh, mat_dark, Vector3(0, 30, 0), Vector3(0.95, 0.85, 0.4)))
	it.append(BMG.item(box1, fh + Vector3(-0.08, -0.03, -0.14), mat_glow, Vector3(0, 30, 0), Vector3(0.62, 0.52, 0.08)))
	it.append(BMG.item(box1, fh + Vector3(0, 0.48, 0), mat_metal, Vector3(0, 30, 0), Vector3(1.05, 0.12, 0.5)))
	# Stack: two tapering sections, bronze hoops, a flared crown with a glowing rim.
	it.append(BMG.item(_cyl(0.98, 1.05, 0.3, 10), Vector3(0, 2.35, 0), mat_dark))
	it.append(BMG.item(_cyl(0.62, 0.82, 2.0, 8), Vector3(0, 3.5, 0), mat_stone))
	it.append(BMG.item(_cyl(0.5, 0.6, 1.6, 8), Vector3(0, 5.25, 0), mat_stone))
	for y: float in [3.0, 4.45, 5.6]:
		var r: float = 0.84 - (y - 3.0) * 0.12
		it.append(BMG.item(_cyl(r, r, 0.14, 8), Vector3(0, y, 0), mat_metal))
	_merged("KilnStack", "kiln_stack", it, kiln)
	it = []
	it.append(BMG.item(_cyl(0.85, 0.52, 0.55, 8), Vector3(0, STACK_TOP - 0.15, 0), mat_dark))
	it.append(BMG.item(_cyl(0.7, 0.7, 0.08, 8), Vector3(0, STACK_TOP + 0.14, 0), lava))
	for i: int in 4:
		var a: float = TAU * float(i) / 4.0 + PI / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		var b: Basis = Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(28.0))
		it.append(BMG.item_xf(_cyl(0.0, 0.13, 0.75, 4), Transform3D(b, d * 0.88 + Vector3(0, STACK_TOP + 0.2, 0)
			+ b * Vector3(0, 0.35, 0)), mat_metal))
	var crown := _merged("KilnCrown", "kiln_crown", it, kiln)
	_hide_below_50.append(crown)
	var kb := _banner("KilnBanner", Vector2(0.75, 1.5), Vector3(0, 3.6, -0.78), 0.0, kiln)
	_hide_below_25.append(kb)
	_hide_on_collapse.append(kb)
	_falling = kiln
	_fall_axis = Vector3(1, 0, 0.4).normalized()
	_fall_deg = 32.0
	# --- Yard: lean-to over the anvil (left front), lava trough + ingots (right front), hammer rack, banner post.
	var yard := Node3D.new()
	yard.name = "Yard"
	_body.add_child(yard)
	it = []
	var an := Vector3(-1.75, pt, -1.75)
	it.append(BMG.item(_cyl(0.36, 0.42, 0.55, 8), an + Vector3(0, 0.27, 0), mat_wood))
	it.append(BMG.item(_cyl(0.36, 0.36, 0.03, 8), an + Vector3(0, 0.56, 0), flag_b))
	it.append(BMG.item(box1, an + Vector3(0, 0.66, 0), mat_metal, Vector3(0, 22, 0), Vector3(0.62, 0.18, 0.3)))
	it.append(BMG.item(_cyl(0.0, 0.11, 0.42, 6), an + Vector3(-0.47, 0.68, -0.19), mat_metal, Vector3(0, 22, 90)))
	it.append(BMG.item(box1, an + Vector3(0.05, 0.83, 0.02), mat_glow, Vector3(0, 40, 0), Vector3(0.42, 0.05, 0.07)))   # a hot blade
	# Lean-to: four timber posts, a sloping team awning, a cross beam.
	for c: Vector2 in [Vector2(-0.95, -0.85), Vector2(0.85, -0.85), Vector2(-0.95, 0.75), Vector2(0.85, 0.75)]:
		var h: float = 2.1 if c.y < 0.0 else 2.55
		it.append(BMG.item(box1, an + Vector3(c.x, h * 0.5, c.y), mat_wood, Vector3.ZERO, Vector3(0.14, h, 0.14)))
	# Lean-to roof: two courses of clay tiles in the team colour (slope 24 deg: the Fire layer's tile rows) on a timber deck.
	it.append(BMG.item(box1, an + Vector3(-0.05, 2.33, -0.05), mat_wood, Vector3(-24, 0, 0), Vector3(2.1, 0.06, 2.05)))
	for k: int in 2:
		it.append(BMG.item(box1, an + Vector3(-0.05, 2.18 + 0.4 * k, -0.62 + 0.9 * k), mat_team, Vector3(-17, 0, 0),
			Vector3(2.3, 0.12, 1.1)))
	it.append(BMG.item(box1, an + Vector3(-0.05, 2.12, -0.88), mat_wood, Vector3.ZERO, Vector3(2.1, 0.12, 0.12)))
	# Hammer rack against the lean-to's back posts.
	it.append(BMG.item(box1, an + Vector3(-0.05, 1.35, 0.78), mat_wood, Vector3.ZERO, Vector3(1.75, 0.1, 0.1)))
	for i: int in 3:
		var hp: Vector3 = an + Vector3(-0.6 + 0.55 * i, 0.95, 0.72)
		it.append(BMG.item(box1, hp, mat_wood, Vector3(0, 0, 4.0 * (i - 1)), Vector3(0.06, 0.85, 0.06)))
		it.append(BMG.item(box1, hp + Vector3(0, -0.45, 0), mat_metal, Vector3.ZERO, Vector3(0.26, 0.14, 0.14)))
	# Lava quench trough (basalt, a lava face) and the ingot stack.
	var tr := Vector3(1.05, pt, -2.05)
	it.append(BMG.item(box1, tr + Vector3(0, 0.25, 0), mat_dark, Vector3(0, -10, 0), Vector3(1.4, 0.5, 0.66)))
	it.append(BMG.item(box1, tr + Vector3(0, 0.47, 0), lava, Vector3(0, -10, 0), Vector3(1.18, 0.04, 0.46)))
	for i: int in 3:
		for j: int in 2 - i % 2:
			it.append(BMG.item(_prism(Vector3(0.42, 0.13, 0.2), 0.5), Vector3(2.45 + 0.24 * j - 0.12 * float(i % 2), pt + 0.07
				+ 0.13 * i, -1.2), mat_metal, Vector3(0, 90.0 * float(i % 2), 0)))
	# Banner post by the gate.
	it.append(BMG.item(_cyl(0.06, 0.08, 2.7, 6), Vector3(0.95, pt + 1.35, -2.85), mat_wood))
	it.append(BMG.item(box1, Vector3(0.95, pt + 2.62, -2.85), mat_metal, Vector3.ZERO, Vector3(0.8, 0.08, 0.08)))
	it.append(BMG.item(_cyl(0.0, 0.1, 0.3, 4), Vector3(0.95, pt + 2.85, -2.85), mat_metal))
	_merged("YardParts", "yard", it, yard, false)
	_hide_on_collapse.append(yard)
	var bn := _banner("Banner", Vector2(0.7, 1.5), Vector3(0.95, pt + 1.82, -2.9), 0.0)
	_hide_below_25.append(bn)
	_hide_on_collapse.append(bn)
	# Light (the B8 hall budget keeps it as a detached proxy: a warm pool on the ground at the forge arch).
	_light = _omni(Vector3(HX, 1.3, -1.4), 5.5)
	# Idle particles: kiln crown flames + smoke, sparks off the anvil, smithy pot smoke, embers off the trough.
	var up_fire := _pm(Vector3.UP, 12.0, 1.0, 1.6, Vector3.ZERO, 0.5, 0.12, _fire_ramp)
	up_fire.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	up_fire.emission_sphere_radius = 0.35
	_idle_fx.append(_particles("KilnFire", kiln, Vector3(0, STACK_TOP + 0.25, 0), 16, 0.7, up_fire, _add_quad, false))
	var sm := _pm(Vector3.UP, 10.0, 0.8, 1.1, Vector3(0.25, 0.0, 0.0), 0.55, 1.8,
		_ramp(Color(smoke_color, 0.45), Color(smoke_color, 0.0), false))
	_idle_fx.append(_particles("KilnSmoke", kiln, Vector3(0, STACK_TOP + 0.8, 0), 10, 3.4, sm, _mix_quad, false))
	var sp := _pm(Vector3(0.3, 1.0, -0.4), 40.0, 1.2, 2.4, Vector3(0, -4.0, 0), 0.1, 0.04, _fire_ramp)
	_idle_fx.append(_particles("AnvilSparks", yard, an + Vector3(0.05, 0.86, 0.02), 10, 0.8, sp, _add_quad, false))
	var ps := _pm(Vector3.UP, 8.0, 0.5, 0.8, Vector3(0.2, 0.0, 0.0), 0.28, 0.85,
		_ramp(Color(smoke_color, 0.35), Color(smoke_color, 0.0), false))
	_idle_fx.append(_particles("PotSmoke", _body, Vector3(HX - 0.4, eave + 2.8, HZ - 0.5), 6, 2.2, ps, _mix_quad, false))
	var em := _pm(Vector3.UP, 20.0, 0.4, 0.9, Vector3.ZERO, 0.08, 0.03, _fire_ramp)
	em.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	em.emission_box_extents = Vector3(0.5, 0.02, 0.18)
	_idle_fx.append(_particles("TroughEmbers", yard, tr + Vector3(0, 0.5, 0), 6, 1.2, em, _add_quad, false))
	# G-B: heat shimmer over the kiln crown and the lava trough (High / Ultra).
	_gb_haze(kiln, Vector3(0, STACK_TOP + 1.0, 0), Vector2(1.6, 2.8))
	_gb_haze(yard, tr + Vector3(0, 0.95, 0), Vector2(1.3, 1.0), 0.6)
	# Construction scaffolding, the collapse wreck (the kiln drum stump), a soot stain by the kiln.
	_build_scaffold(HX + 0.6, HZ - 0.3, 5.4, 4.6, 3.6)
	_build_wreck(HX, HZ, WX * 2.0, WZ * 2.0, pt + WALL_H * 0.3, KILN + Vector3(0, 0.9, 0), Vector3(1.7, 1.8, 1.7), 7373)
	_scorch_decal(Vector3(1.4, 0.035, -1.6), 3.2)
	_smoke_points = [hole_l + Vector3(0, 0.3, 0), KILN + Vector3(0, 4.0, 0)]
	_blaze_points = [hole_r + Vector3(0, 0.2, 0), Vector3(HX, pt + 1.0, fz - 0.6)]
	_rubble2_points = [KILN + Vector3(0.7, 0.05, -0.6), KILN + Vector3(-0.3, 0.05, -1.1), KILN + Vector3(0.9, 0.05, 0.6)]
	_gate_pos = Vector3(HX, pt + 0.9, fz - 0.7)

class_name GloomBazaarModel
extends ShadowHallModel
## Visual model of Malrik's market, the Gloom Bazaar (task 10.V2, docs/design/market-trade.md sections 4.1 and 9):
## a night market on a dark crypt dais, footprint 6 x 6 m (3 x 3 cells), gate (caravans roll out) = local -Z.
## Read from the RTS camera:
##   dominant vertical, back-left: the Scale Mast. A stone counting pillar with glowing slits, a dark timber mast with
##   tarnished-silver bands, a gallows arm reaching over the plaza with a big hanging balance scale (a gold heap in one
##   pan, iron weights in the other) and, on top, a spinning gold coin with a glowing violet diamond (~9.2 m);
##   secondary (asymmetric), front-right: the hooded Night Stall. A tall tent whose hood tip droops forward like a
##   cowl with a lure lantern hanging from it, a glowing violet mouth framed in silver where the hooded merchant's eyes
##   shine, two bone tusks arching over it and a small table of bone curios;
##   plus the long stall at the back (striped team-colour awning with a scalloped valance, silk bolts, a skull, glowing
##   jars, coin stacks), crates and bone urns on the left, a coin chest at the mast foot, a string of violet lanterns
##   across the plaza, two team banners (mast + gate pole), a hanging lantern at the stall corner.
## Same hooks and state machine as the Gloom Hall (FireHallModel / ShadowHallModel, art-keep.md 8.2-8.8):
##   set_team_color(c), set_construction_progress(p), set_health_ratio(r) (< 50 %: smoke, torn awning, the coin emblem
##   is lost; < 25 %: violet fire, the mast banner burns), play_training_pulse() (a caravan leaves: the lanterns, jars
##   and the tent mouth flash, sparks at the gate), play_destroyed() (the mast topples outward, emits
##   destroyed_finished after 3.0 s, the wreck stays), set_selected(on);
##   plus play_delivery() (market-trade.md 9: the scale tips and swings back, gold glints burst from the gold pan, the
##   coin flares and spins fast). All hooks are safe before _ready.
## No real light: the inherited light code drives a detached OmniLight3D proxy (never added to the tree) whose energy
## (breath, training pulse x2, collapse flash) is shown by two additive light pools and the lantern halo.
## Merged meshes (BuildingMerge): 16 visible mesh nodes (the Gloom Hall budget), materials per instance.

const BONE_COLOR := Color(0.74, 0.69, 0.60)
const GOLD_COLOR := Color(0.95, 0.72, 0.26)
const PAVE_COLOR := Color(0.29, 0.26, 0.35)
const MAST_POS := Vector3(-2.05, 0.8, 2.05)   ## mast group origin (its foot on the dais), back-left
const ARM_Y := 6.2          ## mast-local height of the gallows arm
const ARM_LEN := 2.4
const HOOK_DROP := 0.66     ## arm tip -> beam fulcrum
const BEAM_HALF := 1.25     ## fulcrum -> pan hook
const PAN_DROP := 1.15      ## pan hook -> dish
const COIN_Y := 7.8         ## mast-local coin centre
const TENT_POS := Vector3(1.6, 0.8, -1.55)    ## night stall axis (front-right)
const TENT_FACE := Vector3(-0.45, 0.0, -0.1)  ## the tent mouth looks at this plaza point
const STALL_Z := 1.75       ## long stall counter centre (back)
const AWN_X0 := -0.75
const AWN_X1 := 2.75
const AWN_BACK := Vector2(2.9, 3.82)    ## awning back edge (z, y)
const AWN_FRONT := Vector2(0.8, 3.0)    ## awning front edge (z, y)
const LANTERN_POS := Vector3(-0.86, 2.98, 0.74)
const GATE := Vector3(-1.35, 0.0, -3.1)

var mat_cloth: ShaderMaterial   ## team colour, darkened (awning stripes, tent body)
var mat_bone: ShaderMaterial
var mat_pave: ShaderMaterial    ## paving and crates: the stone a step lighter, without the glowing cracks
var mat_gold: ShaderMaterial
var _g_coin: ShaderMaterial     ## the coin's diamond (flares on delivery)

var _mast: Node3D
var _coin: Node3D
var _beam: Node3D
var _pan_l: Node3D
var _pan_r: Node3D
var _lantern: Node3D
var _halo: MeshInstance3D
var _pools: Array[MeshInstance3D] = []
var _glints: GPUParticles3D

var _tip_t: float = -1.0        ## seconds since the last delivery (-1 = idle)
var _coin_flash: float = 0.0
var _spin_boost: float = 0.0


func _notification(what: int) -> void:
	# The light proxy never enters the tree: free it with the model.
	if what == NOTIFICATION_PREDELETE and _light != null and is_instance_valid(_light) and not _light.is_inside_tree():
		_light.free()


func _process(delta: float) -> void:
	super(delta)
	if _ready_done:
		_update_fake_light()


# --- Hooks (the rest is inherited) ---

## A caravan delivered gold: the scale tips toward the gold pan and swings back (damped, ~3 s), gold glints burst from
## that pan, the coin emblem flares and spins fast. Retriggering restarts it. No-op while under construction or dead.
func play_delivery() -> void:
	if _destroyed or _progress < 1.0:
		return
	_tip_t = 0.0
	_coin_flash = 1.0
	_spin_boost = 1.0
	if _ready_done:
		_fire(_glints)


## True while the scale still swings from the last delivery.
func is_delivery_playing() -> bool:
	return _tip_t >= 0.0


func set_team_color(c: Color) -> void:
	super(c)
	if _ready_done:
		mat_cloth.set_shader_parameter(&"base_color", _cloth_of(c))


func set_construction_progress(p: float) -> void:
	super(p)
	if _ready_done and not _destroyed:
		_update_fake_light()


# --- Kingdom-specific overrides ---

func _make_materials() -> void:
	super()
	mat_cloth = _painted_mat(_cloth_of(kingdom_color), 0.05, 0.0)
	mat_bone = _painted_mat(BONE_COLOR, 0.15, 0.0)
	mat_pave = _painted_mat(PAVE_COLOR, 0.0, 0.0)
	mat_gold = _painted_mat(GOLD_COLOR, 0.5, 0.0)
	_g_coin = _glow_mat(3.2, 1.7, 0)
	# The hall's portcullis material lights the lanterns here: solid (no rune bands), a little brighter.
	mat_gate.set_shader_parameter(&"rune_bands", 0)
	mat_gate.set_shader_parameter(&"energy", 2.5)
	mat_gate.set_shader_parameter(&"pulse_speed", 1.4)


func _idle_motion(delta: float) -> void:
	# Coin emblem: slow spin + bob; spins fast after a delivery.
	_spin_boost = maxf(_spin_boost - delta * 0.45, 0.0)
	_coin.rotation.y = wrapf(_coin.rotation.y + deg_to_rad(35.0 + 560.0 * _spin_boost * _spin_boost) * delta, -PI, PI)
	_coin.position.y = COIN_Y + 0.07 * sin(_t * 1.7)
	# Balance: a faint idle sway, the damped tip after a delivery; the pans stay level.
	var tilt: float = 0.025 * sin(_t * 0.8) + 0.01 * sin(_t * 2.3)
	if _tip_t >= 0.0:
		_tip_t += delta
		tilt += 0.3 * sin(_tip_t * 5.2) * exp(-1.4 * _tip_t)
		if _tip_t > 4.0:
			_tip_t = -1.0
	_beam.rotation.z = tilt
	_pan_l.rotation.z = -tilt
	_pan_r.rotation.z = -tilt
	# Lantern sways on its hook.
	_lantern.basis = Basis(Vector3.RIGHT, 0.08 * sin(_t * 1.5)) * Basis(Vector3.FORWARD, 0.05 * sin(_t * 1.1 + 0.7))
	if _coin_flash > 0.0:
		_coin_flash = maxf(_coin_flash - delta / 1.2, 0.0)
		_g_coin.set_shader_parameter(&"boost", _sel_boost() * (1.0 + 3.0 * _coin_flash * _coin_flash))


## Fake light: the proxy's energy (breath x progress, x2 on a training pulse, the collapse flash) drives the additive
## pools and the halo. The pools go out with the lanterns at 1.6 s of the collapse.
func _update_fake_light() -> void:
	var k: float = _light.light_energy / maxf(light_energy, 0.01)
	var built: bool = _progress >= 1.0
	var gone: bool = _destroyed and _destroy_t >= 1.6
	for p: MeshInstance3D in _pools:
		p.visible = built and not gone
		p.transparency = 1.0 - clampf(0.25 + 0.5 * k, 0.0, 1.0)
	_halo.visible = built
	_halo.transparency = 1.0 - clampf(0.3 + 0.45 * k, 0.0, 1.0)


# --- Structure (Body space, gate -Z; heights: dais 0.8, counter 1.9, awning 3.0-3.8, tent hood 5.2, scale 5.3-6.4,
# arm 7.0, coin ~8.6 +- 0.7) ---

func _build_structure() -> void:
	_top_y = 9.3
	# Proxy light for the inherited flicker / pulse / collapse code: never added to the tree (0 real lights).
	_light = OmniLight3D.new()
	_light.name = "LightProxy"
	_light.light_energy = light_energy
	var box1: BoxMesh = _boxm(Vector3.ONE)
	_build_plinth(box1)
	_build_stall(box1)
	_build_awning(box1)
	_build_tent(box1)
	_build_mast(box1)
	var bl := _banner("BannerL", Vector2(0.8, 1.9), Vector3(-2.26, 3.8, -2.72), 0.0)
	_hide_on_collapse.append(bl)
	_build_pools()
	_build_fx()
	_build_scaffold(0.3, 0.2, 5.5, 5.3, 3.3)
	_build_wreck(0.5, 0.2, 4.6, 4.8, PLINTH_TOP + 0.35, MAST_POS + Vector3(0, 0.75, 0), Vector3(1.28, 1.5, 1.28), 10027)
	_smoke_points = [Vector3(1.2, 3.8, 1.9), Vector3(TENT_POS.x, 3.6, TENT_POS.z)]
	_blaze_points = [Vector3(TENT_POS.x + 0.2, 2.6, TENT_POS.z - 0.3), Vector3(-2.3, 2.4, -0.1)]
	_rubble2_points = [Vector3(2.85, 0.9, 2.9), Vector3(2.2, 0.9, 3.2), Vector3(3.2, 0.5, 2.0), Vector3(-2.9, 0.9, -1.6)]
	_gate_pos = GATE + Vector3(0, 1.5, 0)


func _build_plinth(box1: BoxMesh) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 10021
	var it: Array = []
	it.append(BMG.item(box1, Vector3(0, 0.25, 0), mat_dark, Vector3.ZERO, Vector3(6.4, 0.5, 6.4)))
	it.append(BMG.item(box1, Vector3(0, 0.65, 0), mat_dark, Vector3.ZERO, Vector3(5.8, 0.3, 5.8)))
	# Worn paving: a 4 x 4 grid of stone slabs, the dark dais showing in the joints.
	for gx: int in 4:
		for gz: int in 4:
			var p := Vector3(-2.1 + 1.4 * gx + rng.randf_range(-0.05, 0.05), 0.81 + rng.randf_range(0.0, 0.03),
				-2.1 + 1.4 * gz + rng.randf_range(-0.05, 0.05))
			it.append(BMG.item(box1, p, mat_pave, Vector3(0, rng.randf_range(-4.0, 4.0), 0),
				Vector3(rng.randf_range(1.22, 1.32), 0.05, rng.randf_range(1.22, 1.32))))
	# Corner blocks (the gate banner stands on the front-left one), the gate step, a flagstone road out of the gate.
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, 1)]:
		it.append(BMG.item(box1, Vector3(c.x * 2.72, 0.95, c.y * 2.72), mat_dark, Vector3.ZERO, Vector3(0.75, 0.4, 0.75)))
	it.append(BMG.item(box1, Vector3(GATE.x, 0.14, -3.45), mat_dark, Vector3.ZERO, Vector3(2.4, 0.28, 0.55)))
	for i: int in 3:
		var p := Vector3(GATE.x + rng.randf_range(-0.3, 0.3), 0.04, -4.0 - 0.7 * i)
		it.append(BMG.item(box1, p, mat_dark, Vector3(0, rng.randf_range(-20, 20), 0),
			Vector3(rng.randf_range(0.8, 1.0), 0.1, rng.randf_range(0.55, 0.65))))
	_merged("PlinthBase", "plinth", it)


## The long stall (counter, posts, goods), the crates / urns / coin chest, the bone rack and the gate banner pole.
func _build_stall(box1: BoxMesh) -> void:
	var it: Array = []
	var cx: float = (AWN_X0 + AWN_X1) * 0.5
	var fz: float = STALL_Z - 0.35   # counter front face
	# Counter: dark body, stone top with a silver lip, team cloth over the front with a scalloped hem and a gold coin.
	it.append(BMG.item(box1, Vector3(cx, 1.28, STALL_Z), mat_dark, Vector3.ZERO, Vector3(3.2, 0.96, 0.7)))
	it.append(BMG.item(box1, Vector3(cx, 1.82, STALL_Z - 0.04), mat_pave, Vector3.ZERO, Vector3(3.42, 0.12, 0.86)))
	it.append(BMG.item(box1, Vector3(cx, 1.82, STALL_Z - 0.48), mat_metal, Vector3.ZERO, Vector3(3.46, 0.1, 0.08)))
	it.append(BMG.item(box1, Vector3(cx, 1.48, fz - 0.03), mat_team, Vector3.ZERO, Vector3(3.0, 0.56, 0.05)))
	for i: int in 5:
		it.append(BMG.item(_prism(Vector3(0.6, 0.26, 0.05), 0.5), Vector3(cx - 1.2 + 0.6 * i, 1.07, fz - 0.03), mat_team,
			Vector3(0, 0, 180)))
	it.append(BMG.item(_cyl(0.28, 0.28, 0.06, 14), Vector3(cx, 1.5, fz - 0.08), mat_gold, Vector3(90, 0, 0)))
	it.append(BMG.item(box1, Vector3(cx, 1.5, fz - 0.12), mat_gate, Vector3(0, 0, 45), Vector3(0.2, 0.2, 0.03)))
	# Awning posts (dark), silver spikes on the back ones poking through the canvas.
	for x: float in [AWN_X0 + 0.1, AWN_X1 - 0.1]:
		for z: float in [AWN_FRONT.x + 0.2, AWN_BACK.x - 0.2]:
			var top: float = _awning_y(z) - 0.05
			it.append(BMG.item(box1, Vector3(x, (PLINTH_TOP + top) * 0.5, z), mat_dark, Vector3.ZERO,
				Vector3(0.18, top - PLINTH_TOP, 0.18)))
		it.append(BMG.item(_cyl(0.0, 0.14, 0.6, 4), Vector3(x, _awning_y(AWN_BACK.x - 0.2) + 0.32, AWN_BACK.x - 0.2),
			mat_metal, Vector3(0, 45, 0)))
	# Goods on the counter (top 1.88): silk bolts, a skull, three glowing jars, gold coin stacks.
	var top_y: float = 1.88
	for b: Array in [[Vector3(2.0, top_y + 0.15, STALL_Z), mat_team], [Vector3(2.32, top_y + 0.15, STALL_Z), mat_team],
			[Vector3(2.16, top_y + 0.43, STALL_Z), mat_metal]]:
		it.append(BMG.item(_cyl(0.15, 0.15, 0.64, 8), b[0], b[1], Vector3(90, 0, 0)))
	var sk := Vector3(0.0, top_y + 0.16, STALL_Z - 0.05)
	it.append(BMG.item(_sphere(0.17), sk, mat_bone))
	it.append(BMG.item(box1, sk + Vector3(0, -0.11, -0.07), mat_bone, Vector3.ZERO, Vector3(0.2, 0.1, 0.16)))
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, sk + Vector3(s * 0.065, 0.01, -0.155), mat_dark, Vector3.ZERO, Vector3(0.07, 0.07, 0.04)))
	for j: Array in [[0.42, 0.26], [0.64, 0.2], [0.86, 0.3]]:
		var jx: float = j[0]
		var jh: float = j[1]
		it.append(BMG.item(_cyl(0.085, 0.1, jh, 8), Vector3(jx, top_y + jh * 0.5, STALL_Z + 0.05), mat_gate))
		it.append(BMG.item(_cyl(0.05, 0.05, 0.07, 6), Vector3(jx, top_y + jh + 0.035, STALL_Z + 0.05), mat_dark))
	for c: Vector3 in [Vector3(1.28, 0.2, 0.0), Vector3(1.5, 0.12, 0.08), Vector3(1.38, 0.28, 0.18)]:
		it.append(BMG.item(_cyl(0.12, 0.12, c.y, 10), Vector3(c.x, top_y + c.y * 0.5, STALL_Z - 0.05 + c.z), mat_gold))
	# Bone rack between the mast and the counter: a post, a bar, hanging bones and an antler.
	var rk := Vector3(-1.05, PLINTH_TOP, 2.3)
	it.append(BMG.item(box1, rk + Vector3(0, 1.0, 0), mat_dark, Vector3.ZERO, Vector3(0.14, 2.0, 0.14)))
	it.append(BMG.item(box1, rk + Vector3(0, 1.9, 0), mat_dark, Vector3.ZERO, Vector3(0.1, 0.1, 0.9)))
	for i: int in 3:
		var bz: float = -0.3 + 0.3 * i
		it.append(BMG.item(box1, rk + Vector3(0, 1.8, bz), mat_metal, Vector3.ZERO, Vector3(0.03, 0.14, 0.03)))
		it.append(BMG.item(_cyl(0.05, 0.06, 0.44, 6), rk + Vector3(0, 1.5, bz), mat_bone, Vector3(8.0 * (i - 1), 0, 0)))
		it.append(BMG.item(_sphere(0.08), rk + Vector3(0, 1.27, bz), mat_bone))
	var ant := rk + Vector3(0, 2.0, 0)
	it.append(_taper(ant, ant + Vector3(0, 0.45, -0.3), 0.06, 0.03, mat_bone))
	it.append(_taper(ant, ant + Vector3(0, 0.45, 0.3), 0.06, 0.03, mat_bone))
	it.append(_taper(ant + Vector3(0, 0.25, -0.17), ant + Vector3(0, 0.5, -0.05), 0.04, 0.02, mat_bone))
	# Crates (dark, silver bands) and bone urns on the left side.
	_crate(it, box1, Vector3(-2.32, PLINTH_TOP + 0.42, -0.45), 0.84, 6.0)
	_crate(it, box1, Vector3(-2.36, PLINTH_TOP + 0.42, 0.45), 0.84, -8.0)
	_crate(it, box1, Vector3(-2.3, PLINTH_TOP + 0.84 + 0.32, 0.02), 0.64, 22.0)
	for u: Vector3 in [Vector3(-2.45, 1.0, -1.45), Vector3(-1.9, 0.85, -1.85)]:
		var s: float = u.y
		var b := Vector3(u.x, PLINTH_TOP, u.z)
		it.append(BMG.item(_cyl(0.2 * s, 0.3 * s, 0.5 * s, 8), b + Vector3(0, 0.25 * s, 0), mat_bone))
		it.append(BMG.item(_cyl(0.11 * s, 0.2 * s, 0.24 * s, 8), b + Vector3(0, 0.62 * s, 0), mat_bone))
		it.append(BMG.item(_cyl(0.16 * s, 0.16 * s, 0.07 * s, 8), b + Vector3(0, 0.77 * s, 0), mat_dark))
	# Coin chest at the mast foot: dark box, silver bands, open lid, a gold heap.
	var cb := Basis(Vector3.UP, deg_to_rad(28.0))
	var cc := Vector3(-1.45, PLINTH_TOP + 0.22, 0.95)
	it.append(BMG.item_xf(box1, Transform3D(cb.scaled_local(Vector3(0.8, 0.44, 0.55)), cc), mat_dark))
	for x: float in [-0.28, 0.28]:
		it.append(BMG.item_xf(box1, Transform3D(cb.scaled_local(Vector3(0.08, 0.47, 0.58)), cc + cb * Vector3(x, 0, 0)),
			mat_metal))
	var lb: Basis = cb * Basis(Vector3.RIGHT, deg_to_rad(-18.0))
	it.append(BMG.item_xf(box1, Transform3D(lb.scaled_local(Vector3(0.8, 0.52, 0.07)),
		cc + cb * Vector3(0, 0.46, 0.3)), mat_dark))
	it.append(BMG.item(_sphere(0.3), cc + Vector3(0, 0.22, 0), mat_gold, Vector3(0, 28, 0), Vector3(1.2, 0.5, 0.8)))
	for c: Vector3 in [Vector3(0.35, 0.04, -0.35), Vector3(-0.2, 0.03, -0.42)]:
		it.append(BMG.item(_cyl(0.12, 0.12, 0.04, 10), Vector3(cc.x + c.x, PLINTH_TOP + 0.08, cc.z + c.z), mat_gold,
			Vector3(12, 0, 8)))
	# Gate banner pole on the front-left corner block: dark pole, silver bar and finial.
	var gp := Vector3(-2.72, 1.15, -2.72)
	it.append(BMG.item(box1, gp + Vector3(0, 1.85, 0), mat_dark, Vector3.ZERO, Vector3(0.17, 3.7, 0.17)))
	it.append(BMG.item(box1, gp + Vector3(0.42, 3.62, 0), mat_metal, Vector3.ZERO, Vector3(0.96, 0.1, 0.1)))
	it.append(BMG.item(_cyl(0.0, 0.13, 0.5, 4), gp + Vector3(0, 3.95, 0), mat_metal, Vector3(0, 45, 0)))
	_merged("StallFrame", "stall", it)


func _crate(it: Array, box1: BoxMesh, c: Vector3, s: float, yaw: float) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3.ONE * s), c), mat_pave))
	for y: float in [-0.3, 0.3]:
		it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(s + 0.05, 0.1, s + 0.05)), c + Vector3(0, y * s, 0)),
			mat_dark))
	it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(0.1, s + 0.04, s + 0.05)), c), mat_dark))
	it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(0.14, 0.14, s + 0.07)), c + Vector3(0, 0.3 * s, 0)),
		mat_metal))


func _awning_y(z: float) -> float:
	return lerpf(AWN_FRONT.y, AWN_BACK.y, (z - AWN_FRONT.x) / (AWN_BACK.x - AWN_FRONT.x))


## The awning group: the whole canvas (hidden below 50 % HP), the torn one (shown below 50 %) and the corner lantern.
func _build_awning(box1: BoxMesh) -> void:
	var group := Node3D.new()
	group.name = "Awning"
	_body.add_child(group)
	var whole := _merged("AwningWhole", "awning", _awning_items(box1, false), group)
	var torn := _merged("AwningTorn", "awning_torn", _awning_items(box1, true), group)
	torn.visible = false
	_hide_below_50.append(whole)
	_show_below_50.append(torn)
	_hide_on_collapse.append(group)
	# Hanging lantern at the front-left corner (sways), with a soft halo so it reads from far away.
	_lantern = Node3D.new()
	_lantern.name = "LanternPivot"
	_lantern.position = LANTERN_POS
	group.add_child(_lantern)
	var li: Array = []
	li.append(BMG.item(box1, Vector3(0, -0.1, 0), mat_metal, Vector3.ZERO, Vector3(0.05, 0.22, 0.05)))
	li.append(BMG.item(_cyl(0.03, 0.25, 0.2, 4), Vector3(0, -0.3, 0), mat_metal, Vector3(0, 45, 0)))
	li.append(BMG.item(box1, Vector3(0, -0.62, 0), mat_glow, Vector3.ZERO, Vector3(0.3, 0.42, 0.3)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		li.append(BMG.item(box1, Vector3(c.x * 0.16, -0.62, c.y * 0.16), mat_metal, Vector3.ZERO, Vector3(0.05, 0.46, 0.05)))
	li.append(BMG.item(box1, Vector3(0, -0.86, 0), mat_metal, Vector3.ZERO, Vector3(0.36, 0.06, 0.36)))
	li.append(BMG.item(_cyl(0.1, 0.0, 0.16, 4), Vector3(0, -0.97, 0), mat_metal, Vector3(0, 45, 0)))
	_merged("LanternMesh", "lantern", li, _lantern, false)
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	var q := QuadMesh.new()
	q.size = Vector2(1.35, 1.35)
	_halo.mesh = q
	_halo.material_override = _soft_mat(Color(glow_color, 0.5), true)
	_halo.position = Vector3(0, -0.62, 0)
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lantern.add_child(_halo)


func _awning_items(box1: BoxMesh, torn: bool) -> Array:
	var it: Array = []
	var run := Vector2(AWN_BACK.x - AWN_FRONT.x, AWN_BACK.y - AWN_FRONT.y)
	var slope_len: float = run.length()
	var a: float = atan2(run.y, run.x)
	var b := Basis(Vector3.RIGHT, -a)       # local +Z runs up the slope toward the back
	var up_dir: Vector3 = b * Vector3.BACK
	var n: Vector3 = b * Vector3.UP
	var count: int = 7
	var w: float = (AWN_X1 - AWN_X0) / count
	# Canvas: 7 billowing stripes (shallow ridges), team colour / its shadow.
	for i: int in count:
		var x: float = AWN_X0 + w * (i + 0.5)
		var mat: Material = mat_team if i % 2 == 0 else mat_cloth
		var back := Vector3(x, AWN_BACK.y, AWN_BACK.x + 0.1) + n * 0.06
		var sb: Basis = b
		var length: float = slope_len + 0.2
		if torn:
			if i == 1 or i == 4:
				continue
			if i == 2:
				length *= 0.48
			if i == 5:
				sb = Basis(Vector3.RIGHT, -(a + deg_to_rad(20.0)))
		var dirv: Vector3 = sb * Vector3.BACK
		it.append(BMG.item_xf(_prism(Vector3(w + 0.02, 0.12, length), 0.5),
			Transform3D(sb, back - dirv * (length * 0.5)), mat))
	# Scalloped valance along the front edge (colours swapped against the stripes).
	for i: int in count:
		if torn and i in [1, 2, 4, 5]:
			continue
		var x: float = AWN_X0 + w * (i + 0.5)
		it.append(BMG.item(_prism(Vector3(w, 0.34, 0.05), 0.5), Vector3(x, AWN_FRONT.y - 0.19, AWN_FRONT.x - 0.04),
			mat_cloth if i % 2 == 0 else mat_team, Vector3(0, 0, 180)))
	# Beams (dark) front and back, silver rails along both slope edges.
	it.append(BMG.item(box1, Vector3((AWN_X0 + AWN_X1) * 0.5, AWN_FRONT.y + 0.01, AWN_FRONT.x), mat_dark, Vector3.ZERO,
		Vector3(AWN_X1 - AWN_X0 + 0.3, 0.15, 0.15)))
	it.append(BMG.item(box1, Vector3((AWN_X0 + AWN_X1) * 0.5, AWN_BACK.y + 0.01, AWN_BACK.x), mat_dark, Vector3.ZERO,
		Vector3(AWN_X1 - AWN_X0 + 0.3, 0.15, 0.15)))
	var mid := Vector3(0, (AWN_FRONT.y + AWN_BACK.y) * 0.5, (AWN_FRONT.x + AWN_BACK.x) * 0.5)
	for x: float in [AWN_X0 - 0.04, AWN_X1 + 0.04]:
		it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(0.1, 0.14, slope_len + 0.3)),
			mid + Vector3(x, 0, 0) + n * 0.1), mat_metal))
	# Silk curtains on the right side, hanging from the rail (one tied back); the torn canvas keeps a ragged one.
	var cz: Array[float] = [2.35, 1.45]
	for k: int in 2:
		if torn and k == 1:
			continue
		var z: float = cz[k]
		var h: float = 1.45 if k == 0 else 1.1
		if torn:
			h = 0.8
		var y: float = _awning_y(z) - h * 0.5 - 0.02
		it.append(BMG.item(box1, Vector3(AWN_X1 + 0.07, y, z), mat_team if k == 0 else mat_cloth,
			Vector3(0, 4.0 - 8.0 * k, 3.0), Vector3(0.05, h, 0.78)))
	it.append(BMG.item(box1, Vector3(AWN_X1 + 0.1, _awning_y(1.45) - 0.75, 1.45), mat_metal, Vector3.ZERO,
		Vector3(0.08, 0.1, 0.5)))
	if torn:
		# Loose strips hanging through the holes and from the front beam.
		for s: Array in [[AWN_X0 + w * 1.5, 1.8, 0.9], [AWN_X0 + w * 4.5, 1.3, 0.75], [AWN_X0 + w * 2.5, 0.85, 0.6]]:
			var sx: float = s[0]
			var sz: float = s[1]
			var sh: float = s[2]
			it.append(BMG.item(box1, Vector3(sx, _awning_y(sz) - sh * 0.5, sz), mat_team, Vector3(0, 10, 6),
				Vector3(w * 0.8, sh, 0.04)))
	return it


## The hooded night stall, built in its own frame (mouth = local -Z, toward TENT_FACE) and merged in Body space.
func _build_tent(box1: BoxMesh) -> void:
	var face: Vector3 = TENT_FACE - Vector3(TENT_POS.x, 0, TENT_POS.z)
	face = face.normalized()
	var tf := Transform3D(Basis(Vector3.UP, atan2(-face.x, -face.z)), TENT_POS)
	var it: Array = []
	var r0: float = 1.36
	var r1: float = 0.92
	var y0: float = 0.5
	var h0: float = 1.85
	var oct := Basis(Vector3.UP, PI / 8.0)
	# Dais ring, team hem, dark-team cloth robe with a silver belt.
	it.append(_ti(tf, _cyl(1.44, 1.5, 0.16, 8), Transform3D(oct, Vector3(0, 0.08, 0)), mat_dark))
	it.append(_ti(tf, _cyl(r0, 1.42, 0.34, 8), Transform3D(oct, Vector3(0, 0.33, 0)), mat_team))
	it.append(_ti(tf, _cyl(r1, r0, h0, 8), Transform3D(oct, Vector3(0, y0 + h0 * 0.5, 0)), mat_cloth))
	var belt_y: float = y0 + h0 * 0.62
	var belt_r: float = r0 - 0.62 * (r0 - r1) + 0.04
	it.append(_ti(tf, _cyl(belt_r, belt_r + 0.03, 0.12, 8), Transform3D(oct, Vector3(0, belt_y, 0)), mat_metal))
	# The hood: a team-colour cowl collar, then three segments curling forward and down (a floppy hood).
	var p1 := Vector3(0, y0 + h0, 0)
	it.append(_ti(tf, _cyl(r1 + 0.1, r1 + 0.14, 0.3, 8), Transform3D(oct, p1 + Vector3(0, -0.02, 0)), mat_team))
	it.append(_ti(tf, _cyl(r1 + 0.02, r1 + 0.12, 0.08, 8), Transform3D(oct, p1 + Vector3(0, 0.16, 0)), mat_metal))
	var b1 := Basis(Vector3.RIGHT, deg_to_rad(-22.0))
	it.append(_ti(tf, _cyl(0.6, r1, 1.2, 8), Transform3D(b1 * oct, p1 + b1 * Vector3(0, 0.6, 0)), mat_cloth))
	var p2: Vector3 = p1 + b1 * Vector3(0, 1.2, 0)
	it.append(_ti(tf, _sphere(0.6), Transform3D(Basis.IDENTITY, p2), mat_cloth))
	var b2 := Basis(Vector3.RIGHT, deg_to_rad(-66.0))
	it.append(_ti(tf, _cyl(0.36, 0.6, 1.1, 8), Transform3D(b2 * oct, p2 + b2 * Vector3(0, 0.55, 0)), mat_cloth))
	var p3: Vector3 = p2 + b2 * Vector3(0, 1.1, 0)
	it.append(_ti(tf, _sphere(0.36), Transform3D(Basis.IDENTITY, p3), mat_cloth))
	var b3 := Basis(Vector3.RIGHT, deg_to_rad(-118.0))
	it.append(_ti(tf, _cyl(0.0, 0.36, 0.85, 8), Transform3D(b3 * oct, p3 + b3 * Vector3(0, 0.42, 0)), mat_cloth))
	var p4: Vector3 = p3 + b3 * Vector3(0, 0.85, 0)
	it.append(_ti(tf, _cyl(0.38, 0.38, 0.1, 8), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-92.0)) * oct, p3), mat_metal))
	# Lure lantern hanging from the hood tip.
	it.append(_ti(tf, _sphere(0.08), Transform3D(Basis.IDENTITY, p4), mat_metal))
	it.append(_ti(tf, _cyl(0.03, 0.03, 0.34, 4), Transform3D(Basis.IDENTITY, p4 + Vector3(0, -0.2, 0)), mat_metal))
	it.append(_ti(tf, _cyl(0.03, 0.2, 0.14, 4), Transform3D(Basis(Vector3.UP, PI / 4.0), p4 + Vector3(0, -0.42, 0)),
		mat_metal))
	it.append(_ti(tf, box1, Transform3D(Basis.from_scale(Vector3(0.26, 0.32, 0.26)), p4 + Vector3(0, -0.65, 0)), mat_gate))
	it.append(_ti(tf, _cyl(0.1, 0.0, 0.14, 4), Transform3D(Basis(Vector3.UP, PI / 4.0), p4 + Vector3(0, -0.88, 0)),
		mat_metal))
	var slope_a: float = atan2(r0 - r1, h0)
	# Mouth (-Z): glowing pointed arch with a silver frame, team flaps tied back.
	var my: float = 1.12
	var mr: float = r0 - (my - y0) / h0 * (r0 - r1)
	var mf := Transform3D(Basis(Vector3.RIGHT, slope_a), Vector3(0, my, -mr - 0.01))
	it.append(_ti(tf, box1, mf * Transform3D(Basis.from_scale(Vector3(0.95, 1.24, 0.06)), Vector3.ZERO), mat_gate))
	it.append(_ti(tf, _prism(Vector3(0.95, 0.46, 0.06), 0.5), mf * Transform3D(Basis.IDENTITY, Vector3(0, 0.85, 0)),
		mat_gate))
	var arch_a: float = atan2(0.46, 0.475)
	for s: float in [-1.0, 1.0]:
		it.append(_ti(tf, box1, mf * Transform3D(Basis.from_scale(Vector3(0.1, 1.28, 0.1)), Vector3(s * 0.52, 0, -0.03)),
			mat_metal))
		it.append(_ti(tf, box1, mf * Transform3D(Basis(Vector3.BACK, -s * arch_a).scaled_local(Vector3(0.74, 0.1, 0.1)),
			Vector3(s * 0.26, 0.84, -0.03)), mat_metal))
		it.append(_ti(tf, box1, mf * Transform3D(Basis(Vector3.UP, deg_to_rad(s * 24.0)).scaled_local(
			Vector3(0.34, 1.42, 0.07)), Vector3(s * 0.72, 0.05, -0.02)), mat_team))
		it.append(_ti(tf, box1, mf * Transform3D(Basis.from_scale(Vector3(0.4, 0.1, 0.1)), Vector3(s * 0.7, 0.05, -0.08)),
			mat_metal))
	# The hooded merchant in the mouth: dark robe, cowl, dark face, glowing eyes.
	it.append(_ti(tf, _cyl(0.15, 0.36, 1.0, 6), Transform3D(Basis.IDENTITY, Vector3(0, 0.66, -1.47)), mat_dark))
	it.append(_ti(tf, _sphere(0.24), Transform3D(Basis.IDENTITY, Vector3(0, 1.3, -1.5)), mat_cloth))
	it.append(_ti(tf, _cyl(0.0, 0.2, 0.44, 6), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(30.0)),
		Vector3(0, 1.6, -1.42)), mat_cloth))
	it.append(_ti(tf, _cyl(0.16, 0.16, 0.05, 10), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.28, -1.72)),
		mat_dark))
	for s: float in [-1.0, 1.0]:
		it.append(_ti(tf, box1, Transform3D(Basis.from_scale(Vector3(0.1, 0.05, 0.03)), Vector3(s * 0.075, 1.31, -1.75)),
			mat_gate))
	# Curio table in front of the mouth: team cloth, a skull, a glowing orb on a silver stand, bone dice.
	it.append(_ti(tf, box1, Transform3D(Basis.from_scale(Vector3(1.1, 0.5, 0.42)), Vector3(0, 0.41, -1.9)), mat_dark))
	it.append(_ti(tf, box1, Transform3D(Basis.from_scale(Vector3(1.16, 0.05, 0.48)), Vector3(0, 0.685, -1.9)), mat_team))
	it.append(_ti(tf, box1, Transform3D(Basis.from_scale(Vector3(1.16, 0.3, 0.04)), Vector3(0, 0.55, -2.15)), mat_team))
	it.append(_ti(tf, _sphere(0.13), Transform3D(Basis.IDENTITY, Vector3(-0.3, 0.83, -1.92)), mat_bone))
	it.append(_ti(tf, _cyl(0.05, 0.09, 0.1, 6), Transform3D(Basis.IDENTITY, Vector3(0.3, 0.76, -1.92)), mat_metal))
	it.append(_ti(tf, _sphere(0.1), Transform3D(Basis.IDENTITY, Vector3(0.3, 0.89, -1.92)), mat_gate))
	it.append(_ti(tf, box1, Transform3D(Basis(Vector3.UP, 0.5).scaled_local(Vector3.ONE * 0.1), Vector3(0.02, 0.76, -1.98)),
		mat_bone))
	it.append(_ti(tf, box1, Transform3D(Basis(Vector3.UP, 1.1).scaled_local(Vector3.ONE * 0.1), Vector3(0.12, 0.76, -1.86)),
		mat_bone))
	# Two bone tusks arching over the mouth, silver cuffs at their roots.
	for s: float in [-1.0, 1.0]:
		var pts: Array[Vector3] = []
		for k: int in 5:
			var ph: float = deg_to_rad(80.0 * k / 4.0)
			pts.append(Vector3(s * (1.02 - 0.72 * (1.0 - cos(ph))), 0.16 + 2.05 * sin(ph), -1.25 - 0.45 * sin(ph)))
		for k: int in 4:
			var ra: float = lerpf(0.18, 0.04, k / 4.0)
			var rb2: float = lerpf(0.18, 0.04, (k + 1) / 4.0)
			var seg: Array = _taper(pts[k], pts[k + 1], ra, rb2, mat_bone)
			it.append(BMG.item_xf(seg[0], tf * (seg[1] as Transform3D), seg[2]))
		it.append(_ti(tf, _cyl(0.22, 0.22, 0.12, 8), Transform3D(Basis.IDENTITY, pts[0] + Vector3(0, 0.25, 0)), mat_metal))
	_merged("NightStall", "tent", it)


## Item in the tent frame: `mesh` at `xf` (tent space) -> Body space.
func _ti(tf: Transform3D, mesh: Mesh, xf: Transform3D, mat: Material) -> Array:
	return BMG.item_xf(mesh, tf * xf, mat)


## The Scale Mast: stack (pillar, mast, arm, stirrup, lantern string), banner, coin emblem, the balance (beam + pans).
func _build_mast(box1: BoxMesh) -> void:
	_mast = Node3D.new()
	_mast.name = "Mast"
	_mast.position = MAST_POS
	_body.add_child(_mast)
	var arm := Vector3(1, 0, -1).normalized()   # toward the plaza
	var arm_yaw: float = atan2(arm.x, arm.z)
	var ab := Basis(Vector3.UP, arm_yaw)
	var it: Array = []
	# Counting pillar: dark course, stone block with two glowing slits, dark cap and a chamfered collar.
	it.append(BMG.item(box1, Vector3(0, 0.15, 0), mat_dark, Vector3.ZERO, Vector3(1.45, 0.3, 1.45)))
	it.append(BMG.item(box1, Vector3(0, 1.0, 0), mat_stone, Vector3.ZERO, Vector3(1.28, 1.5, 1.28)))
	it.append(BMG.item(box1, Vector3(0, 1.84, 0), mat_dark, Vector3.ZERO, Vector3(1.5, 0.2, 1.5)))
	it.append(BMG.item(_cyl(0.42, 0.95, 0.42, 4), Vector3(0, 2.15, 0), mat_dark, Vector3(0, 45, 0)))
	it.append(BMG.item(box1, Vector3(0, 1.05, -0.645), mat_gate, Vector3.ZERO, Vector3(0.14, 0.78, 0.05)))
	it.append(BMG.item(box1, Vector3(0.645, 1.05, 0), mat_gate, Vector3.ZERO, Vector3(0.05, 0.78, 0.14)))
	# Mast: dark timber, silver bands, a dark collar where the arm joins, a spiked crown.
	it.append(BMG.item(_cyl(0.22, 0.34, 4.6, 6), Vector3(0, 4.6, 0), mat_dark))
	for y: float in [3.2, 4.9]:
		it.append(BMG.item(_cyl(0.36, 0.36, 0.2, 6), Vector3(0, y, 0), mat_metal))
	it.append(BMG.item(box1, Vector3(0, ARM_Y, 0), mat_dark, Vector3(0, 45, 0), Vector3(0.6, 0.5, 0.6)))
	it.append(BMG.item(_cyl(0.33, 0.33, 0.14, 6), Vector3(0, ARM_Y + 0.35, 0), mat_metal))
	it.append(BMG.item(_cyl(0.46, 0.28, 0.3, 4), Vector3(0, 7.0, 0), mat_dark, Vector3(0, 45, 0)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var d := Vector3(c.x, 0.0, c.y).normalized()
		var lb := Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(24.0))
		it.append(BMG.item_xf(_cyl(0.0, 0.12, 0.7, 4), Transform3D(lb, d * 0.36 + Vector3(0, 7.1, 0) + lb * Vector3(0, 0.35, 0)),
			mat_metal))
	# Gallows arm toward the plaza: dark beam, silver end cap and spike, a brace.
	it.append(BMG.item_xf(box1, Transform3D(ab.scaled_local(Vector3(0.24, 0.3, ARM_LEN + 0.3)),
		arm * (ARM_LEN * 0.5 + 0.1) + Vector3(0, ARM_Y, 0)), mat_dark))
	var tip: Vector3 = arm * ARM_LEN + Vector3(0, ARM_Y, 0)
	it.append(BMG.item_xf(box1, Transform3D(ab.scaled_local(Vector3(0.34, 0.38, 0.14)), tip + arm * 0.22), mat_metal))
	it.append(BMG.item(_cyl(0.0, 0.1, 0.45, 4), tip + arm * 0.22 + Vector3(0, 0.4, 0), mat_metal, Vector3(0, 45, 0)))
	it.append(_taper(arm * 0.22 + Vector3(0, ARM_Y - 1.25, 0), arm * 1.35 + Vector3(0, ARM_Y - 0.12, 0), 0.07, 0.07,
		mat_dark))
	# Hook and stirrup (static): the beam turns inside the ring.
	var fulcrum: Vector3 = tip + Vector3(0, -HOOK_DROP, 0)
	var beam_dir := Vector3(-arm.z, 0, arm.x)
	it.append(_taper(tip + Vector3(0, -0.12, 0), fulcrum + Vector3(0, 0.36, 0), 0.045, 0.045, mat_metal))
	it.append(BMG.item_xf(_ring(0.3, 0.37), Transform3D(Basis(Quaternion(Vector3.UP, beam_dir)), fulcrum), mat_metal))
	# String of violet lanterns from the mast to the night stall, sagging over the plaza.
	var a_w: Vector3 = MAST_POS + arm * 0.3 + Vector3(0, 3.3, 0)
	var to_mast: Vector3 = Vector3(MAST_POS.x - TENT_POS.x, 0, MAST_POS.z - TENT_POS.z).normalized()
	var b_w: Vector3 = TENT_POS + Vector3(0, 2.35, 0) + to_mast * 0.99
	var prev: Vector3 = a_w
	for k: int in range(1, 11):
		var p: Vector3 = _garland(a_w, b_w, k / 10.0)
		it.append(_taper(prev - MAST_POS, p - MAST_POS, 0.03, 0.03, mat_dark, 4))
		prev = p
	for t: float in [0.2, 0.36, 0.52, 0.68, 0.84]:
		var p: Vector3 = _garland(a_w, b_w, t) - MAST_POS
		it.append(BMG.item(_cyl(0.02, 0.15, 0.1, 4), p + Vector3(0, -0.07, 0), mat_dark, Vector3(0, 45, 0)))
		it.append(BMG.item(box1, p + Vector3(0, -0.24, 0), mat_gate, Vector3(0, 45, 0), Vector3(0.2, 0.26, 0.2)))
	# Silver bar for the mast banner (outer face of the mast).
	it.append(BMG.item_xf(box1, Transform3D(ab.scaled_local(Vector3(0.95, 0.09, 0.09)), -arm * 0.3 + Vector3(0, 5.07, 0)),
		mat_metal))
	_merged("MastStack", "mast", it, _mast)
	var mb := _banner("MastBanner", Vector2(0.8, 1.75), -arm * 0.34 + Vector3(0, 4.15, 0), rad_to_deg(arm_yaw), _mast)
	# Coin emblem on top (spins, bobs): gold disc, silver rim, a glowing violet diamond on each face.
	_coin = Node3D.new()
	_coin.name = "CoinPivot"
	_coin.position = Vector3(0, COIN_Y, 0)
	_mast.add_child(_coin)
	it = []
	it.append(BMG.item(_cyl(0.66, 0.66, 0.15, 16), Vector3.ZERO, mat_gold, Vector3(90, 0, 0)))
	it.append(BMG.item(_ring(0.6, 0.77), Vector3.ZERO, mat_metal, Vector3(90, 0, 0)))
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, Vector3(0, 0, s * 0.085), _g_coin, Vector3(0, 0, 45), Vector3(0.4, 0.4, 0.03)))
	_merged("CoinMesh", "coin", it, _coin, false)
	# The balance: a fixed pivot turned along the beam, the beam (tilts on z), two pans that stay level.
	var sp := Node3D.new()
	sp.name = "ScalePivot"
	sp.position = fulcrum
	sp.basis = Basis(Vector3.UP, atan2(-beam_dir.z, beam_dir.x))
	_mast.add_child(sp)
	_beam = Node3D.new()
	_beam.name = "ScaleBeam"
	sp.add_child(_beam)
	it = []
	it.append(BMG.item(box1, Vector3.ZERO, mat_metal, Vector3.ZERO, Vector3(0.34, 0.2, 0.2)))
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item(_cyl(0.06, 0.11, BEAM_HALF, 6), Vector3(s * BEAM_HALF * 0.5, 0, 0), mat_metal,
			Vector3(0, 0, -90.0 * s)))
		it.append(BMG.item(_sphere(0.12), Vector3(s * BEAM_HALF, 0, 0), mat_metal))
		it.append(BMG.item(_cyl(0.0, 0.08, 0.3, 4), Vector3(s * (BEAM_HALF + 0.2), 0, 0), mat_metal, Vector3(0, 0, -90.0 * s)))
	it.append(BMG.item(_cyl(0.0, 0.2, 0.28, 4), Vector3(0, -0.24, 0), mat_dark, Vector3(180, 45, 0)))
	it.append(BMG.item(_cyl(0.0, 0.06, 0.34, 4), Vector3(0, 0.26, 0), mat_metal, Vector3(0, 45, 0)))
	_merged("BeamMesh", "beam", it, _beam, false)
	_pan_l = _build_pan("PanL", -1.0)
	_pan_r = _build_pan("PanR", 1.0)
	_falling = _mast
	_fall_axis = Vector3.BACK
	_fall_deg = 30.0
	_hide_below_50.append(_coin)
	_hide_below_25.append(mb)
	_hide_on_collapse.append(mb)


func _garland(a: Vector3, b: Vector3, t: float) -> Vector3:
	return a.lerp(b, t) - Vector3(0, 0.75 * 4.0 * t * (1.0 - t), 0)


## One pan hanging from the beam end `side` (-1 = the gold pan, +1 = the weights): hook, three chains, a dish.
func _build_pan(nm: String, side: float) -> Node3D:
	var pv := Node3D.new()
	pv.name = nm
	pv.position = Vector3(side * BEAM_HALF, 0, 0)
	_beam.add_child(pv)
	var it: Array = []
	it.append(BMG.item(_sphere(0.08), Vector3(0, -0.08, 0), mat_metal))
	for k: int in 3:
		var ang: float = TAU * k / 3.0 + PI / 6.0
		it.append(_taper(Vector3(0, -0.12, 0), Vector3(cos(ang) * 0.47, -PAN_DROP + 0.1, sin(ang) * 0.47), 0.025, 0.025,
			mat_metal))
	it.append(BMG.item(_cyl(0.56, 0.3, 0.18, 12), Vector3(0, -PAN_DROP, 0), mat_metal))
	it.append(BMG.item(_cyl(0.6, 0.6, 0.06, 12), Vector3(0, -PAN_DROP + 0.09, 0), mat_metal))
	if side < 0.0:
		it.append(BMG.item(_sphere(0.42), Vector3(0, -PAN_DROP + 0.1, 0), mat_gold, Vector3.ZERO, Vector3(1.0, 0.42, 1.0)))
		for c: Vector3 in [Vector3(0.15, 0.2, 0.05), Vector3(-0.12, 0.2, -0.1), Vector3(0.0, 0.26, 0.14)]:
			it.append(BMG.item(_cyl(0.13, 0.13, 0.04, 10), Vector3(c.x, -PAN_DROP + c.y, c.z), mat_gold, Vector3(20, c.x * 300, 12)))
	else:
		it.append(BMG.item(_cyl(0.2, 0.24, 0.24, 8), Vector3(0, -PAN_DROP + 0.2, 0), mat_dark))
		it.append(BMG.item(_cyl(0.13, 0.16, 0.18, 8), Vector3(0, -PAN_DROP + 0.41, 0), mat_dark))
		it.append(BMG.item(_sphere(0.07), Vector3(0, -PAN_DROP + 0.53, 0), mat_metal))
	_merged(nm + "Mesh", "pan_%s" % ("l" if side < 0.0 else "r"), it, pv, false)
	return pv


## Two additive light pools on the dais (under the corner lantern and before the tent mouth): the fake light.
func _build_pools() -> void:
	var face: Vector3 = (TENT_FACE - Vector3(TENT_POS.x, 0, TENT_POS.z)).normalized()
	var spots: Array = [
		[Vector3(LANTERN_POS.x + 0.25, PLINTH_TOP + 0.07, LANTERN_POS.z - 0.15), 3.6, 0.42],
		[Vector3(TENT_POS.x, PLINTH_TOP + 0.075, TENT_POS.z) + face * 2.0, 2.8, 0.45],
	]
	for i: int in spots.size():
		var s: Array = spots[i]
		var pm := PlaneMesh.new()
		pm.size = Vector2.ONE * float(s[1])
		var mi := MeshInstance3D.new()
		mi.name = "LightPool" if i == 0 else "MouthPool"
		mi.mesh = pm
		mi.material_override = _soft_mat(Color(0.62, 0.3, 1.0, float(s[2])), false)
		mi.position = s[0]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_pools.append(mi)


## Idle: ground mist ring (like the hall), violet fireflies over the plaza. One-shot: gold glints from the gold pan.
func _build_fx() -> void:
	var mist := _pm(Vector3(1, 0, 0), 180.0, 0.1, 0.25, Vector3.ZERO, 1.2, 2.4,
		_ramp(Color(0.25, 0.12, 0.38, 0.28), Color(0.25, 0.12, 0.38), false))
	mist.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mist.emission_ring_axis = Vector3.UP
	mist.emission_ring_radius = 3.4
	mist.emission_ring_inner_radius = 2.6
	mist.emission_ring_height = 0.05
	_idle_fx.append(_particles("GroundMist", self, Vector3(0, 0.35, 0), 8, 6.0, mist, _mix_quad, false))
	var ff := _pm(Vector3.UP, 40.0, 0.12, 0.3, Vector3.ZERO, 0.06, 0.02,
		_ramp(Color(0.8, 0.5, 1.0, 0.8), Color(0.4, 0.12, 0.7), false))
	ff.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ff.emission_box_extents = Vector3(1.8, 0.7, 1.6)
	_idle_fx.append(_particles("Fireflies", _body, Vector3(0.1, 2.4, 0.1), 9, 4.0, ff, _add_quad, false))
	var gl := _pm(Vector3.UP, 55.0, 1.4, 2.8, Vector3(0, -4.0, 0), 0.11, 0.03,
		_ramp(Color(1.0, 0.82, 0.35), Color(1.0, 0.6, 0.12), false))
	gl.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	gl.emission_sphere_radius = 0.3
	_glints = _particles("DeliveryGlints", _pan_l, Vector3(0, -PAN_DROP + 0.3, 0), 16, 1.0, gl, _add_quad, true)


# --- Helpers ---

## A tapered rod from `a` (radius ra) to `b` (radius rb) as a merge item.
func _taper(a: Vector3, b: Vector3, ra: float, rb: float, mat: Material, segs: int = 6) -> Array:
	var e: Vector3 = b - a
	var l: float = e.length()
	var bs := Basis(Quaternion(Vector3.UP, e / l))
	return BMG.item_xf(_cyl(rb, ra, l, segs), Transform3D(bs, (a + b) * 0.5), mat)


func _ring(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 16
	t.ring_segments = 6
	return t


## Soft radial quad material (unshaded, no depth write): additive for halos / light pools.
func _soft_mat(c: Color, billboard: bool) -> StandardMaterial3D:
	var g := Gradient.new()
	g.set_color(0, c)
	g.set_color(1, Color(c, 0.0))
	g.add_point(0.45, Color(c, c.a * 0.45))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = tex
	return m

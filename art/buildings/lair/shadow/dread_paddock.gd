class_name DreadPaddockModel
extends ShadowHallModel
## Visual model of Malrik's Lair, the Dread Paddock (task 13.V26, docs/design/cavalry-mounts.md 2.1 + 10, style
## art-keep.md 0): the tier-3 building that raises Nightmare Knights, calls the Mage Archer (tier3-extras.md) and
## later the Barrow Giant. Footprint 3 x 3 cells = 6 x 6 m (collision is Building's), gate (the Knights ride out) =
## local -Z. Read from the RTS camera:
##   dominant vertical, front: the spiked gatehouse. Two tapering black-stone towers flank a glowing violet ward-veil
##   under a pointed silver arch with an iron portcullis; machicolation caps bristling with silver spikes, iron
##   thorns on the tower faces, a crest of spikes on the curtain parapet around a horned nightmare-horse skull with
##   glowing eye sockets; the left tower carries a tall team-slate spire, the right a short one (asymmetric pair;
##   finials ~11.65 / 9.75 m), a team banner on the left tower, a violet torch on each tower flanking the gate;
##   secondary (asymmetric), back: the stalls. A long low stone stable (x -2.9..1.6) under a team-slate gable roof,
##   three stall openings facing the yard with iron-strapped half-doors, two nightmare-horse heads looking out (dark
##   coats, silver chanfrons, violet eyes, team-colour smoke manes), a pair of eyes glowing in the dark middle stall,
##   smoke curling from two iron roof cowls, a team banner on each gable end;
##   plus the black iron fence (spear-tipped posts and pickets on a stone kerb) closing the yard on both flanks, a
##   tall violet torch stand in the back-right corner, a stone trough, a bone pile and a hitching post; and the clear
##   **call circle** in the yard (CALL_POINT, r 1.35 kept free of props): a black stone disc with a silver ring, a
##   slowly turning violet rune ring and six standing stones. The Mage Archer rises out of it (mage_archer play_call).
## In the game the gate faces the map centre along world X, so the players' cameras look at the local +X (own) or -X
## (enemy) flank: both flanks are only a 2 m fence, so the yard and the circle read from both cameras; the gatehouse
## and the stalls stand at the ends (-Z / +Z) and show in profile. Everything stays within 3.3 m of the centre in x / z
## (the torch flames and the gate step reach 3.3-3.7 m on the gate side, like every hall's step).
## Same hooks and state machine as the Gloom Hall (FireHallModel / ShadowHallModel, art-keep.md 8.2-8.8):
##   set_team_color(c), set_construction_progress(p) (the parts rise, scaffolding round the gatehouse),
##   set_health_ratio(r) (< 50 %: smoke, a caved stall roof, the tall spire loses its crown; < 25 %: violet fire, a
##   burning roof hole, the tower banner is lost), play_training_pulse() (the veil flashes, sparks at the gate),
##   play_destroyed() (the tall spire topples outward, emits destroyed_finished after 3.0 s, the wreck stays),
##   set_selected(on); plus (all safe before _ready, no-ops while building or destroyed):
##   play_raise()  a titan is raised (3.0 s): the portcullis hauls up (open at RAISE_OPEN, signal raise_opened), the
##       veil, torches and stall eyes flare, the nightmares toss their heads, violet smoke billows out of the gate with
##       a spark burst; the portcullis slams down at RAISE_CLOSE with a small bounce. Retriggering restarts it.
##   play_call()  the Mage Archer is called (CALL_TIME 2.0 s = her play_call): the rune ring flares and spins fast, a
##       column of violet motes rises from the ring, the circle's light pool brightens.
##   is_raising() -> bool, is_calling() -> bool, get_call_point() -> Vector3 (world centre of the circle, on the 0.8 m
##   dais: where to stand her model for play_call).
## No real light: the inherited light code drives a detached OmniLight3D proxy (never added to the tree) whose energy
## (breath, training pulse, collapse flash) drives three torch halos and an additive light pool by the back torch; a
## circle pool lights the dais only during a call.
## Merged meshes (BuildingMerge): 24 visible mesh nodes idle (15 geometry tiers + 3 banners + 3 halos + 1 pool + the
## contact / scorch decals), 13 particle systems (8 inherited state systems + stall smoke x2, ground mist, raise smoke,
## call column), materials per instance (as every Shadow building).

signal raise_opened(at: Vector3)

const YARD := 0.8             ## dais / yard floor height (= PLINTH_TOP)
const GATE_X := -0.55             ## gate axis x
const GATE_Z := -2.3              ## gatehouse centre z
const TOWER_DX := 1.65        ## tower centres at GATE_X -/+ TOWER_DX
const TOWER_R0 := 0.92        ## tower (4-sided) radius at the foot (half-width 0.65)
const TOWER_R1 := 0.78        ## at the top (half-width 0.55)
const TOWER_TOP := 6.3
const CAP_TOP := 6.75
const GATE_TOP := 4.6         ## curtain wall top over the gate
const VEIL_W := 1.9
const VEIL_RECT := 3.5        ## veil rectangle top (the pointed top reaches 4.15)
const PORT_Z := GATE_Z - 0.72     ## portcullis plane
const PORT_TOP := 3.2
const PORT_LIFT := 1.35
const STALL_X0 := -2.9
const STALL_X1 := 1.6
const STALL_Z0 := 1.5         ## stall front wall (the openings face -Z, the yard)
const STALL_Z1 := 2.9
const STALL_CX := -0.65
const STALL_CZ := 2.2
const STALL_HALF := 0.95      ## roof half-width (ridge along X)
const STALL_EAVE := 2.85
const STALL_RISE := 1.05
const STALL_DOORS := [-2.1, -0.55, 1.0]    ## stall opening centres (x)
const VENTS := [Vector3(-1.85, 4.45, 2.2), Vector3(0.6, 4.45, 2.2)]
const TORCH_FLAMES := [Vector3(GATE_X - 1.3, 3.3, GATE_Z - 0.88), Vector3(GATE_X + 1.3, 3.3, GATE_Z - 0.88), Vector3(2.25, 4.3, 2.25)]
const TORCH_BACK := Vector3(2.25, 0.8, 2.25)
const CALL_POINT := Vector3(-0.55, 0.8, -0.05)  ## circle centre (Body space, on the dais), on the gate axis
const CALL_STONES := [0.0, 50.0, 130.0, 180.0, 230.0, 310.0]  ## standing stone angles (deg, from +X toward +Z)
const CALL_CLEAR := 1.35      ## radius kept free of props around CALL_POINT
const RAISE_TIME := 3.0
const RAISE_OPEN := 0.7
const RAISE_CLOSE := 2.3
const RAISE_SMOKE_AT := 0.25
const CALL_TIME := 2.0
const HORSE_COLOR := Color(0.16, 0.12, 0.20)
const BONE_COLOR := Color(0.74, 0.69, 0.60)
const PAVE_COLOR := Color(0.29, 0.26, 0.35)

var mat_pave: ShaderMaterial
var mat_bone: ShaderMaterial
var mat_horse: ShaderMaterial
var mat_iron: ShaderMaterial    ## black iron (fence, portcullis, sconces)
var mat_pave2: ShaderMaterial   ## the darker paving flags
var mat_tower: ShaderMaterial   ## the gate towers' paler stone
var mat_kerb: ShaderMaterial    ## fence kerbs and the stalls' base course (between paving and dark stone)
var mat_stall: ShaderMaterial   ## the stalls' walls: a paler stone than the gatehouse
var mat_team_dk: ShaderMaterial ## every other stall-roof tile course: the team colour x 0.75
var _g_torch: ShaderMaterial    ## torch flames (fast flicker)
var _g_circle: ShaderMaterial   ## call circle runes

var _portcullis: Node3D
var _rune: MeshInstance3D
var _heads: Array[MeshInstance3D] = []
var _head_rest: Array[Vector3] = []
var _halos: Array[MeshInstance3D] = []
var _pools: Array[MeshInstance3D] = []
var _circle_pool: MeshInstance3D
var _raise_smoke: GPUParticles3D
var _call_col: GPUParticles3D

var _raise_t: float = -1.0
var _call_t: float = -1.0
var _raise_pending: bool = false
var _call_pending: bool = false
var _raise_env: float = 0.0
var _call_env: float = 0.0


func _ready() -> void:
	super()
	if _raise_pending:
		_raise_pending = false
		play_raise()
	if _call_pending:
		_call_pending = false
		play_call()


func _notification(what: int) -> void:
	# The light proxy never enters the tree: free it with the model.
	if what == NOTIFICATION_PREDELETE and _light != null and is_instance_valid(_light) and not _light.is_inside_tree():
		_light.free()


func _process(delta: float) -> void:
	super(delta)
	if _ready_done:
		_update_fake_light()


# --- Hooks (the rest is inherited) ---

## A titan is raised (3.0 s): portcullis up, flare, smoke out of the gate, portcullis down. Restarts if retriggered.
func play_raise() -> void:
	if not _ready_done:
		_raise_pending = true
		return
	if _destroyed or _progress < 1.0:
		return
	_raise_t = 0.0


## The Mage Archer is called (2.0 s): the rune ring flares and spins, motes rise from the circle.
func play_call() -> void:
	if not _ready_done:
		_call_pending = true
		return
	if _destroyed or _progress < 1.0:
		return
	_call_t = 0.0
	_fire(_call_col)


func is_raising() -> bool:
	return _raise_t >= 0.0 or _raise_pending


func is_calling() -> bool:
	return _call_t >= 0.0 or _call_pending


## World centre of the call circle on the dais (the Mage Archer's model stands here for play_call).
func get_call_point() -> Vector3:
	if is_inside_tree():
		return global_transform * CALL_POINT
	return transform * CALL_POINT


func set_construction_progress(p: float) -> void:
	super(p)
	if _ready_done and not _destroyed:
		if _progress < 1.0:
			_raise_t = -1.0
			_call_t = -1.0
			_portcullis.position.y = 0.0
		_update_fake_light()


func play_destroyed() -> void:
	var was: bool = _destroyed
	super()
	if was or not _ready_done:
		return
	_raise_t = -1.0
	_call_t = -1.0
	_portcullis.position.y = 0.0
	_g_circle.set_shader_parameter(&"boost", 0.3)


# --- Kingdom-specific overrides ---

func _make_materials() -> void:
	super()
	mat_pave = _painted_mat(PAVE_COLOR, 0.0, 0.0)
	mat_bone = _painted_mat(BONE_COLOR, 0.15, 0.0)
	mat_horse = _painted_mat(HORSE_COLOR, 0.25, 0.0)
	# 2026-09-30: black iron in its own blue-black with a little shine (the hall draws every painted part with ONE merged
	# material now, so shades cost nothing: C3 palette depth), a second paving shade, a paler tower stone.
	mat_iron = _painted_mat(Color(0.12, 0.12, 0.17), 0.3, 0.0)
	mat_pave2 = _painted_mat(PAVE_COLOR.darkened(0.18), 0.0, 0.0)
	mat_tower = _painted_mat(stone_color.lightened(0.12), 0.0, crack_strength)
	mat_kerb = _painted_mat(PAVE_COLOR.lerp(dark_color, 0.5), 0.0, 0.0)
	mat_stall = _painted_mat(stone_color.lightened(0.22), 0.0, crack_strength)
	mat_team_dk = _painted_mat(kingdom_color.darkened(0.25), 0.1, 0.0)
	_g_torch = _glow_mat(3.2, 9.0, 0)
	_g_circle = _glow_mat(0.7, 1.3, 0)   # 2026-09-30 R5: the call circle glows under the bloom until it calls


func _idle_motion(delta: float) -> void:
	# Raise timeline.
	_raise_env = 0.0
	if _raise_t >= 0.0:
		var t0: float = _raise_t
		_raise_t += delta
		var t: float = _raise_t
		var lift: float = 0.0
		if t < RAISE_OPEN:
			lift = 1.0 - pow(1.0 - t / RAISE_OPEN, 2.0)
		elif t < RAISE_CLOSE:
			lift = 1.0
		elif t < RAISE_CLOSE + 0.4:
			lift = 1.0 - pow((t - RAISE_CLOSE) / 0.4, 2.0)
		elif t < RAISE_CLOSE + 0.62:
			lift = 0.07 * sin((t - RAISE_CLOSE - 0.4) / 0.22 * PI)
		_portcullis.position.y = PORT_LIFT * lift
		_raise_env = _bump(t, 0.0, 0.3, RAISE_TIME - 0.3)
		if t0 < RAISE_SMOKE_AT and t >= RAISE_SMOKE_AT:
			_fire(_raise_smoke)
			_fire(_train_burst)
		if t0 < RAISE_OPEN and t >= RAISE_OPEN:
			raise_opened.emit(_world(Vector3(GATE_X, YARD, GATE_Z - 0.9)))
		if t >= RAISE_TIME:
			_raise_t = -1.0
			_portcullis.position.y = 0.0
			_raise_env = 0.0
	# Call timeline.
	_call_env = 0.0
	if _call_t >= 0.0:
		_call_t += delta
		var c: float = _call_t
		_call_env = clampf(c / 0.25, 0.0, 1.0) if c < 1.5 else clampf(1.0 - (c - 1.5) / 0.5, 0.0, 1.0)
		if c >= CALL_TIME:
			_call_t = -1.0
			_call_env = 0.0
	var sel: float = _sel_boost()
	if _pulse_left <= 0.0:
		mat_gate.set_shader_parameter(&"boost", sel * (1.0 + 2.2 * _raise_env))
	_g_torch.set_shader_parameter(&"boost", sel * (1.0 + 1.2 * _raise_env))
	mat_glow.set_shader_parameter(&"boost", sel * (1.0 + 1.5 * _raise_env))
	_g_circle.set_shader_parameter(&"boost", sel * (1.0 + 2.6 * _call_env))
	# The rune ring turns slowly, fast while calling.
	_rune.rotation.y = wrapf(_rune.rotation.y + delta * (0.22 + 3.2 * _call_env), -PI, PI)
	# The nightmares look around and nod; they toss their heads up when a titan is raised.
	for i: int in _heads.size():
		var ph: float = 1.7 * i
		_heads[i].rotation = Vector3(0.0, _head_rest[i].y + 0.28 * sin(_t * 0.37 + ph),
			0.07 * sin(_t * 0.9 + ph) - 0.45 * _raise_env)


func _bump(t: float, a: float, b: float, c: float) -> float:
	if t <= a or t >= c:
		return 0.0
	if t < b:
		return smoothstep(a, b, t)
	return 1.0 - smoothstep(b, c, t)


func _world(p: Vector3) -> Vector3:
	return global_transform * p if is_inside_tree() else transform * p


## Fake light: the proxy's energy (breath x progress, x2 on a training pulse, the collapse flash) plus the raise flare
## drives the torch halos (each flickers on its own) and the pools; the circle pool follows the call.
func _update_fake_light() -> void:
	var k: float = _light.light_energy / maxf(light_energy, 0.01)
	var built: bool = _progress >= 1.0
	var gone: bool = _destroyed and _destroy_t >= 1.6
	var fire_k: float = k + 0.9 * _raise_env
	for i: int in _halos.size():
		var h: MeshInstance3D = _halos[i]
		h.visible = built and not gone
		var fl: float = 0.88 + 0.12 * sin(_t * (9.0 + 2.3 * i) + 1.9 * i) * sin(_t * (5.1 + i) + i)
		h.transparency = 1.0 - clampf((0.28 + 0.45 * fire_k) * fl, 0.0, 1.0)
	for p: MeshInstance3D in _pools:
		p.visible = built and not gone
		p.transparency = 1.0 - clampf(0.2 + 0.45 * fire_k, 0.0, 1.0)
	_circle_pool.visible = built and not _destroyed and _call_env > 0.0
	_circle_pool.transparency = 1.0 - clampf(0.85 * _call_env, 0.0, 1.0)


# --- Structure (Body space, gate -Z; heights: dais 0.8, fence 2.6 (finials 3.1), stall eaves 2.85 / ridge 3.9
# (cowls 4.6), curtain 4.6 (skull horns 6.0), towers 6.3 / caps 6.75, right spire 9.75, left spire finial 11.65) ---

func _build_structure() -> void:
	_top_y = 11.7
	# Proxy light for the inherited flicker / pulse / collapse code: never added to the tree (0 real lights).
	_light = OmniLight3D.new()
	_light.name = "LightProxy"
	_light.light_energy = light_energy
	var box1: BoxMesh = _boxm(Vector3.ONE)
	_build_plinth(box1)
	_build_fence(box1)
	_build_gatehouse(box1)
	var hole: Array = _build_stalls(box1)
	_build_circle(box1)
	_build_props(box1)
	_build_torches(box1)
	_build_heads(box1)
	var tb := _banner("TowerBanner", Vector2(0.8, 1.7), Vector3(GATE_X - TOWER_DX, 4.05, GATE_Z - 0.68), 0.0)
	var se := _banner("StallBannerE", Vector2(0.75, 1.35), Vector3(STALL_X1 + 0.05, 1.95, STALL_CZ), 90.0)
	var sw := _banner("StallBannerW", Vector2(0.75, 1.35), Vector3(STALL_X0 - 0.05, 1.95, STALL_CZ), -90.0)
	_hide_below_25.append(tb)
	for b: Node3D in [tb, se, sw]:
		_hide_on_collapse.append(b)
	_build_glows()
	_build_fx()
	_build_scaffold(GATE_X, GATE_Z, 4.9, 1.9, 4.6)
	_build_wreck(GATE_X, GATE_Z, 4.4, 1.4, PLINTH_TOP + (GATE_TOP - PLINTH_TOP) * 0.3, Vector3(GATE_X - TOWER_DX, 1.95, GATE_Z),
		Vector3(1.2, 2.3, 1.2), 26026)
	_scorch_decal(Vector3(-2.9, 0.035, 0.4), 3.2, Color(0.12, 0.04, 0.18, 0.5))
	var hole_l: Vector3 = hole[0]
	var hole_r: Vector3 = hole[1]
	_smoke_points = [hole_l + Vector3(0, 0.3, 0), Vector3(GATE_X - TOWER_DX, 7.0, GATE_Z)]
	_blaze_points = [hole_r + Vector3(0, 0.2, 0), Vector3(GATE_X + TOWER_DX, 6.95, GATE_Z)]
	_rubble2_points = [Vector3(-1.35, 0.95, -3.05), Vector3(-2.95, 0.5, -1.3), Vector3(1.9, 0.95, 0.9),
		Vector3(2.95, 0.5, 0.3)]
	_gate_pos = Vector3(GATE_X, 1.6, GATE_Z - 0.8)


## Dark dais (two tiers), worn paving (none under the circle disc), the gate step and a flagstone road out.
func _build_plinth(box1: BoxMesh) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 26001
	var it: Array = []
	it.append(BMG.item(box1, Vector3(0, 0.25, 0), mat_dark, Vector3.ZERO, Vector3(6.4, 0.5, 6.4)))
	it.append(BMG.item(box1, Vector3(0, 0.65, 0), mat_dark, Vector3.ZERO, Vector3(5.8, 0.3, 5.8)))
	for gx: int in 4:
		for gz: int in 4:
			var c := Vector3(-2.1 + 1.4 * gx, 0.0, -2.1 + 1.4 * gz)
			if Vector2(c.x - CALL_POINT.x, c.z - CALL_POINT.z).length() < 1.45:
				continue
			var p := Vector3(c.x + rng.randf_range(-0.05, 0.05), 0.81 + rng.randf_range(0.0, 0.03),
				c.z + rng.randf_range(-0.05, 0.05))
			it.append(BMG.item(box1, p, mat_pave if (gx + gz) % 3 != 0 else mat_pave2, Vector3(0, rng.randf_range(-4.0, 4.0), 0),
				Vector3(rng.randf_range(1.22, 1.32), 0.05, rng.randf_range(1.22, 1.32))))
	it.append(BMG.item(box1, Vector3(GATE_X, 0.14, -3.45), mat_dark, Vector3.ZERO, Vector3(2.8, 0.28, 0.55)))
	it.append(BMG.item(box1, Vector3(GATE_X, 0.5, -3.28), mat_dark, Vector3.ZERO, Vector3(2.4, 0.3, 0.3)))
	for i: int in 3:
		var p := Vector3(GATE_X + rng.randf_range(-0.3, 0.3), 0.04, -4.0 - 0.7 * i)
		it.append(BMG.item(box1, p, mat_dark, Vector3(0, rng.randf_range(-20, 20), 0),
			Vector3(rng.randf_range(0.85, 1.05), 0.1, rng.randf_range(0.55, 0.65))))
	# The call circle: a black stone disc, a silver ring and six standing stones outside CALL_CLEAR.
	var cp := CALL_POINT
	it.append(BMG.item(_cyl(1.36, 1.4, 0.08, 24), cp + Vector3(0, 0.04, 0), mat_dark))
	it.append(BMG.item(_ring(1.2, 1.34), cp + Vector3(0, 0.085, 0), mat_metal, Vector3.ZERO, Vector3(1.0, 0.3, 1.0)))
	for deg: float in CALL_STONES:
		var a: float = deg_to_rad(deg)
		var p := cp + Vector3(cos(a), 0.0, sin(a)) * 1.52
		it.append(BMG.item(box1, p + Vector3(0, 0.06, 0), mat_dark, Vector3(0, -deg, 0), Vector3(0.3, 0.12, 0.3)))
		it.append(BMG.item(_cyl(0.06, 0.19, 0.8, 4), p + Vector3(0, 0.52, 0), mat_stone, Vector3(0, 45.0 - deg, 0)))
	_merged("PlinthBase", "plinth", it)


## Black iron fence on a stone kerb: the left flank (tower to stalls), the right flank (front-right corner to the
## torch stand) with its short front run to the right tower, and the back run from the torch stand to the stalls.
func _build_fence(box1: BoxMesh) -> void:
	var it: Array = []
	var tower_back: float = GATE_Z + 0.78
	_fence_run(it, box1, Vector2(-2.85, tower_back), Vector2(-2.85, STALL_Z0), true, false)
	var rt_x: float = GATE_X + TOWER_DX + 0.72
	_fence_run(it, box1, Vector2(rt_x, GATE_Z), Vector2(2.85, GATE_Z), false, false)
	_fence_run(it, box1, Vector2(2.85, GATE_Z), Vector2(2.85, 2.85), false, true)
	_fence_run(it, box1, Vector2(2.85, 2.85), Vector2(STALL_X1, 2.85), false, false)
	# Corner post (front right): thicker, a silver collar and a big spear finial.
	var cp := Vector3(2.85, 0.0, GATE_Z)
	it.append(BMG.item(box1, cp + Vector3(0, YARD + 1.0, 0), mat_iron, Vector3.ZERO, Vector3(0.34, 2.0, 0.34)))
	it.append(BMG.item(box1, cp + Vector3(0, YARD + 2.02, 0), mat_metal, Vector3.ZERO, Vector3(0.42, 0.1, 0.42)))
	it.append(BMG.item(_cyl(0.0, 0.24, 0.62, 4), cp + Vector3(0, YARD + 2.38, 0), mat_metal, Vector3(0, 45, 0)))
	_merged("Fence", "fence", it)


## One fence run from `a` to `b` (x, z): kerb, two rails, posts every <= 0.95 m (skipped at the ends when the run meets
## a wall or a torch), two spear-tipped pickets between posts.
func _fence_run(it: Array, box1: BoxMesh, a: Vector2, b: Vector2, post_a: bool, post_b: bool) -> void:
	var d: Vector2 = b - a
	var l: float = d.length()
	var yaw: float = atan2(d.x, d.y)
	var yaw_deg: float = rad_to_deg(yaw)
	var bs := Basis(Vector3.UP, yaw)
	var mid := Vector3((a.x + b.x) * 0.5, 0.0, (a.y + b.y) * 0.5)
	it.append(BMG.item_xf(box1, Transform3D(bs.scaled_local(Vector3(0.38, 0.18, l + 0.38)), mid + Vector3(0, YARD + 0.09, 0)),
		mat_kerb))
	for ry: float in [YARD + 0.58, YARD + 1.45]:
		it.append(BMG.item_xf(box1, Transform3D(bs.scaled_local(Vector3(0.07, 0.1, l)), mid + Vector3(0, ry, 0)), mat_iron))
	var n: int = maxi(1, ceili(l / 0.95))
	for i: int in n + 1:
		if (i == 0 and not post_a) or (i == n and not post_b):
			continue
		var p2: Vector2 = a + d * (float(i) / n)
		var p := Vector3(p2.x, 0.0, p2.y)
		it.append(BMG.item(box1, p + Vector3(0, YARD + 0.98, 0), mat_iron, Vector3(0, yaw_deg, 0), Vector3(0.2, 1.6, 0.2)))
		it.append(BMG.item(box1, p + Vector3(0, YARD + 1.8, 0), mat_metal, Vector3(0, yaw_deg, 0), Vector3(0.28, 0.08, 0.28)))
		it.append(BMG.item(_cyl(0.0, 0.16, 0.44, 4), p + Vector3(0, YARD + 2.06, 0), mat_metal, Vector3(0, yaw_deg + 45.0, 0)))
	for i: int in n:
		for f: float in [1.0 / 3.0, 2.0 / 3.0]:
			var p2: Vector2 = a + d * ((float(i) + f) / n)
			var p := Vector3(p2.x, 0.0, p2.y)
			it.append(BMG.item(box1, p + Vector3(0, YARD + 0.85, 0), mat_iron, Vector3(0, yaw_deg, 0), Vector3(0.07, 1.34, 0.07)))
			it.append(BMG.item(_cyl(0.0, 0.085, 0.28, 4), p + Vector3(0, YARD + 1.66, 0), mat_iron, Vector3(0, yaw_deg + 45.0, 0)))


## Half-width of a tower face at height y.
func _tower_hw(y: float) -> float:
	return 0.7071 * lerpf(TOWER_R0, TOWER_R1, clampf((y - YARD) / (TOWER_TOP - YARD), 0.0, 1.0))


## The gatehouse group: towers + curtain + veil + skull + crest (GateStack), the portcullis (own pivot), and the two
## spires (SpireL is the falling element, its crown is lost below 50 %).
func _build_gatehouse(box1: BoxMesh) -> void:
	var grp := Node3D.new()
	grp.name = "Gatehouse"
	_body.add_child(grp)
	var it: Array = []
	# Curtain block between the towers, dark base course, parapet cap.
	it.append(BMG.item(box1, Vector3(GATE_X, (YARD + GATE_TOP) * 0.5, GATE_Z), mat_stone, Vector3.ZERO,
		Vector3(2.1, GATE_TOP - YARD, 0.9)))
	it.append(BMG.item(box1, Vector3(GATE_X, YARD + 0.22, GATE_Z), mat_dark, Vector3.ZERO, Vector3(2.2, 0.44, 1.0)))
	it.append(BMG.item(box1, Vector3(GATE_X, GATE_TOP + 0.12, GATE_Z), mat_dark, Vector3.ZERO, Vector3(2.3, 0.24, 1.08)))
	# Ward-veil (the glowing gate, on both faces of the passage: the yard sees it too): rectangle + pointed top, dark
	# jambs, silver arch trims; a dark threshold.
	var arch_a: float = atan2(0.65, VEIL_W * 0.5)
	var arch_l: float = sqrt(0.65 * 0.65 + VEIL_W * VEIL_W * 0.25) + 0.3
	for fz: float in [-1.0, 1.0]:
		var vz: float = GATE_Z + fz * 0.47
		it.append(BMG.item(box1, Vector3(GATE_X, (YARD + VEIL_RECT) * 0.5, vz), mat_gate, Vector3.ZERO,
			Vector3(VEIL_W, VEIL_RECT - YARD, 0.06)))
		it.append(BMG.item(_prism(Vector3(VEIL_W, 0.65, 0.06), 0.5), Vector3(GATE_X, VEIL_RECT + 0.325, vz), mat_gate))
		for s: float in [-1.0, 1.0]:
			it.append(BMG.item(box1, Vector3(GATE_X + s * (VEIL_W * 0.5 + 0.13), (YARD + VEIL_RECT + 0.1) * 0.5,
				GATE_Z + fz * 0.5), mat_dark, Vector3.ZERO, Vector3(0.26, VEIL_RECT + 0.1 - YARD, 0.3)))
			it.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.BACK, -s * arch_a).scaled_local(Vector3(arch_l, 0.18, 0.24)),
				Vector3(GATE_X + s * VEIL_W * 0.25, VEIL_RECT + 0.36, GATE_Z + fz * 0.52)), mat_metal))
	it.append(BMG.item(box1, Vector3(GATE_X, YARD + 0.03, GATE_Z - 0.1), mat_dark, Vector3.ZERO, Vector3(2.0, 0.08, 1.2)))
	# Towers.
	for s: float in [-1.0, 1.0]:
		var c := Vector3(GATE_X + s * TOWER_DX, 0.0, GATE_Z)
		it.append(BMG.item(box1, c + Vector3(0, YARD + 0.3, 0), mat_dark, Vector3.ZERO, Vector3(1.55, 0.6, 1.55)))
		it.append(BMG.item(_cyl(TOWER_R1, TOWER_R0, TOWER_TOP - YARD, 4), c + Vector3(0, (YARD + TOWER_TOP) * 0.5, 0),
			mat_tower, Vector3(0, 45, 0)))
		var rb: float = _tower_hw(3.3) / 0.7071 + 0.07
		it.append(BMG.item(_cyl(rb, rb, 0.18, 4), c + Vector3(0, 3.3, 0), mat_metal, Vector3(0, 45, 0)))
		# Corbels flaring into the machicolation cap.
		it.append(BMG.item(_cyl(1.13, TOWER_R1, 0.42, 4), c + Vector3(0, TOWER_TOP - 0.19, 0), mat_dark, Vector3(0, 45, 0)))
		it.append(BMG.item(box1, c + Vector3(0, (TOWER_TOP + CAP_TOP) * 0.5, 0), mat_dark, Vector3.ZERO,
			Vector3(1.6, CAP_TOP - TOWER_TOP, 1.6)))
		# Cap spikes: four corners leaning out, one mid-edge on the front and on the outer side.
		for cc: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var base := c + Vector3(cc.x * 0.72, CAP_TOP - 0.05, cc.y * 0.72)
			_spike(it, base, Vector3(cc.x, 1.7, cc.y), 0.16, 1.05, mat_metal)
		_spike(it, c + Vector3(0, CAP_TOP - 0.05, -0.74), Vector3(0, 1.0, -0.9), 0.13, 0.75, mat_metal)
		_spike(it, c + Vector3(s * 0.74, CAP_TOP - 0.05, 0), Vector3(s, 1.0, 0), 0.13, 0.75, mat_metal)
		# Iron thorns on the outer face (two), the back face (one) and the right tower's front (one).
		for y: float in [2.4, 3.95, 5.5]:
			_spike(it, c + Vector3(s * (_tower_hw(y) - 0.06), y, 0), Vector3(s, 0.35, 0), 0.12, 0.72, mat_iron)
		_spike(it, c + Vector3(0, 3.2, _tower_hw(3.2) - 0.06), Vector3(0, 0.35, 1), 0.12, 0.7, mat_iron)
		if s > 0.0:
			_spike(it, c + Vector3(0, 4.1, -(_tower_hw(4.1) - 0.06)), Vector3(0, 0.35, -1), 0.12, 0.72, mat_iron)
		# A glowing arrow slit on the outer face (between the thorns).
		it.append(BMG.item(box1, c + Vector3(s * (_tower_hw(4.75) + 0.01), 4.75, 0), mat_dark, Vector3.ZERO, Vector3(0.08, 1.0, 0.34)))
		it.append(BMG.item(box1, c + Vector3(s * (_tower_hw(4.75) + 0.04), 4.75, 0), mat_gate, Vector3.ZERO, Vector3(0.06, 0.78, 0.14)))
	# Banner bar on the left tower front.
	it.append(BMG.item(box1, Vector3(GATE_X - TOWER_DX, 4.95, GATE_Z - 0.64), mat_metal, Vector3.ZERO, Vector3(1.0, 0.1, 0.1)))
	# Crest of spikes on the parapet (the centre one tallest, behind the skull), leaning alternately.
	var pz: float = GATE_Z + 0.05
	for k: int in 4:
		var ox: float = [-0.85, -0.45, 0.45, 0.85][k]
		var h: float = [0.8, 1.05, 1.05, 0.8][k]
		_spike(it, Vector3(GATE_X + ox, GATE_TOP + 0.2, pz), Vector3(ox * 0.35, 1.0, 0.05), 0.16, h, mat_metal)
	_spike(it, Vector3(GATE_X, GATE_TOP + 0.2, GATE_Z + 0.25), Vector3(0, 1.0, 0.04), 0.22, 1.7, mat_metal)
	# The horned nightmare-horse skull over the veil (nose down), glowing eye sockets.
	var sk := Vector3(GATE_X, 5.05, GATE_Z - 0.5)
	it.append(BMG.item(box1, sk, mat_bone, Vector3.ZERO, Vector3(0.5, 0.46, 0.36)))
	it.append(BMG.item(box1, sk + Vector3(0, 0.26, 0.05), mat_bone, Vector3(-12, 0, 0), Vector3(0.36, 0.14, 0.3)))
	it.append(_taper(sk + Vector3(0, -0.12, -0.06), sk + Vector3(0, -0.8, -0.12), 0.21, 0.13, mat_bone, 4))
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, sk + Vector3(s * 0.13, -0.02, -0.18), mat_glow, Vector3.ZERO, Vector3(0.13, 0.1, 0.03)))
		it.append(BMG.item(box1, sk + Vector3(s * 0.06, -0.8, -0.21), mat_dark, Vector3.ZERO, Vector3(0.06, 0.07, 0.03)))
		var h0: Vector3 = sk + Vector3(s * 0.22, 0.18, 0.0)
		var h1: Vector3 = sk + Vector3(s * 0.46, 0.5, -0.04)
		var h2: Vector3 = sk + Vector3(s * 0.5, 0.98, -0.1)
		it.append(_taper(h0, h1, 0.1, 0.075, mat_bone, 5))
		it.append(_taper(h1, h2, 0.075, 0.0, mat_bone, 5))
	_merged("GateStack", "gate_stack", it, grp)
	# Portcullis (own pivot: lifts PORT_LIFT on play_raise): five bars with spiked feet, three cross bars, a top rail.
	_portcullis = Node3D.new()
	_portcullis.name = "PortcullisPivot"
	grp.add_child(_portcullis)
	it = []
	var bar_y0: float = YARD + 0.28
	for ox: float in [-0.76, -0.38, 0.0, 0.38, 0.76]:
		it.append(BMG.item(box1, Vector3(GATE_X + ox, (bar_y0 + PORT_TOP) * 0.5, PORT_Z), mat_iron, Vector3.ZERO,
			Vector3(0.13, PORT_TOP - bar_y0, 0.13)))
		it.append(BMG.item(_cyl(0.075, 0.0, 0.28, 4), Vector3(GATE_X + ox, YARD + 0.14, PORT_Z), mat_iron, Vector3(0, 45, 0)))
	for y: float in [1.5, 2.2, 2.9]:
		it.append(BMG.item(box1, Vector3(GATE_X, y, PORT_Z), mat_iron, Vector3.ZERO, Vector3(1.72, 0.11, 0.11)))
	it.append(BMG.item(box1, Vector3(GATE_X, PORT_TOP, PORT_Z), mat_iron, Vector3.ZERO, Vector3(1.9, 0.18, 0.18)))
	_merged("Portcullis", "portcullis", it, _portcullis)
	# Spires: the tall left one (falls on collapse, its crown is lost below 50 %) and the short right one.
	var spire := Node3D.new()
	spire.name = "SpireL"
	spire.position = Vector3(GATE_X - TOWER_DX, CAP_TOP, GATE_Z)
	_body.add_child(spire)
	it = []
	var sl_r: float = 1.0
	var sl_h: float = 4.1
	it.append(BMG.item(_cyl(1.16, 1.16, 0.12, 4), Vector3(0, 0.06, 0), mat_metal, Vector3(0, 45, 0)))
	it.append(BMG.item(_cyl(0.0, sl_r, sl_h, 4), Vector3(0, sl_h * 0.5, 0), mat_team, Vector3(0, 45, 0)))
	var band_r: float = sl_r * (1.0 - 2.0 / sl_h) + 0.05
	it.append(BMG.item(_cyl(band_r, band_r + 0.02, 0.12, 4), Vector3(0, 2.0, 0), mat_metal, Vector3(0, 45, 0)))
	for dv: Vector3 in [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)]:
		var hw: float = 0.7071 * sl_r * (1.0 - 1.1 / sl_h)
		_spike(it, dv * (hw - 0.05) + Vector3(0, 1.1, 0), dv + Vector3(0, 0.8, 0), 0.11, 0.7, mat_metal)
	for dv: Vector3 in [Vector3(0, 0, -1), Vector3(-1, 0, 0)]:
		var hw: float = 0.7071 * sl_r * (1.0 - 2.5 / sl_h)
		_spike(it, dv * (hw - 0.04) + Vector3(0, 2.5, 0), dv + Vector3(0, 1.0, 0), 0.08, 0.5, mat_metal)
	_merged("SpireLRoof", "spire_l", it, spire)
	it = []
	it.append(BMG.item(_cyl(0.2, 0.2, 0.14, 4), Vector3(0, 3.62, 0), mat_metal, Vector3(0, 45, 0)))
	it.append(_taper(Vector3(0, 3.55, 0), Vector3(0, 4.9, 0), 0.14, 0.0, mat_metal, 4))
	# 2026-09-30 P5: a soul-gem caught in the finial, the Lair's one high glow (read over the crowd at 40 m).
	it.append(BMG.item(_cyl(0.0, 0.13, 0.26, 4), Vector3(0, 4.3, 0), mat_glow, Vector3(0, 45, 0)))
	it.append(BMG.item(_cyl(0.13, 0.0, 0.18, 4), Vector3(0, 4.08, 0), mat_glow, Vector3(0, 45, 0)))
	for dv: Vector3 in [Vector3(1, 0, 1), Vector3(-1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, -1)]:
		_spike(it, Vector3(0, 3.62, 0) + dv * 0.1, dv + Vector3(0, 1.4, 0), 0.07, 0.5, mat_metal)
	var crown := _merged("SpireLCrown", "spire_l_crown", it, spire, false)
	_falling = spire
	_fall_axis = Vector3.BACK
	_fall_deg = 35.0
	_hide_below_50.append(crown)
	it = []
	var rc := Vector3(GATE_X + TOWER_DX, CAP_TOP, GATE_Z)
	var sr_r: float = 0.98
	var sr_h: float = 2.5
	it.append(BMG.item(_cyl(1.12, 1.12, 0.12, 4), rc + Vector3(0, 0.06, 0), mat_metal, Vector3(0, 45, 0)))
	it.append(BMG.item(_cyl(0.0, sr_r, sr_h, 4), rc + Vector3(0, sr_h * 0.5, 0), mat_team, Vector3(0, 45, 0)))
	it.append(_taper(rc + Vector3(0, 2.15, 0), rc + Vector3(0, 3.0, 0), 0.12, 0.0, mat_metal, 4))
	for dv: Vector3 in [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1)]:
		var hw2: float = 0.7071 * sr_r * (1.0 - 0.8 / sr_h)
		_spike(it, rc + dv * (hw2 - 0.05) + Vector3(0, 0.8, 0), dv + Vector3(0, 0.8, 0), 0.1, 0.6, mat_metal)
	_merged("SpireR", "spire_r", it)


## The stalls (back row, openings toward the yard -Z): walls, three openings with shut half-doors, glowing eyes in
## the dark middle stall, banner bars on both gable ends; the gable roof (ridge along X: built
## in a frame turned 90 deg, own tier for the damage holes) with ridge spikes and two smoking cowls. Returns the hole
## points (Body space).
func _build_stalls(box1: BoxMesh) -> Array:
	var it: Array = []
	var wl: float = STALL_X1 - STALL_X0
	var wd: float = STALL_Z1 - STALL_Z0
	it.append(BMG.item(box1, Vector3(STALL_CX, YARD + 0.2, STALL_CZ), mat_kerb, Vector3.ZERO, Vector3(wl + 0.2, 0.4, wd + 0.2)))
	it.append(BMG.item(box1, Vector3(STALL_CX, (YARD + STALL_EAVE) * 0.5, STALL_CZ), mat_stall, Vector3.ZERO,
		Vector3(wl, STALL_EAVE - YARD, wd)))
	for c: Vector2 in [Vector2(STALL_X0, STALL_Z0), Vector2(STALL_X1, STALL_Z0), Vector2(STALL_X0, STALL_Z1),
			Vector2(STALL_X1, STALL_Z1)]:
		it.append(BMG.item(box1, Vector3(c.x, (YARD + STALL_EAVE) * 0.5, c.y), mat_dark, Vector3.ZERO,
			Vector3(0.32, STALL_EAVE - YARD, 0.32)))
	var fz: float = STALL_Z0
	for i: int in STALL_DOORS.size():
		var x: float = STALL_DOORS[i]
		it.append(BMG.item(box1, Vector3(x, YARD + 0.875, fz - 0.02), _hole_mat(), Vector3.ZERO, Vector3(1.0, 1.75, 0.04)))
		for s: float in [-1.0, 1.0]:
			it.append(BMG.item(box1, Vector3(x + s * 0.58, YARD + 0.93, fz - 0.06), mat_dark, Vector3.ZERO, Vector3(0.18, 1.86, 0.18)))
		it.append(BMG.item(box1, Vector3(x, YARD + 1.86, fz - 0.08), mat_dark, Vector3.ZERO, Vector3(1.4, 0.22, 0.24)))
		# Half-door (1.0 m, shut: an open one would swing into the circle), two silver straps and a ring pull.
		var door := Vector3(x, YARD + 0.52, fz - 0.1)
		it.append(BMG.item(box1, door, mat_dark, Vector3.ZERO, Vector3(0.98, 1.0, 0.1)))
		for y: float in [-0.27, 0.27]:
			it.append(BMG.item(box1, door + Vector3(0.04, y, -0.065), mat_metal, Vector3.ZERO, Vector3(0.86, 0.09, 0.03)))
		it.append(BMG.item(_ring(0.05, 0.09), door + Vector3(-0.36, 0.05, -0.08), mat_metal, Vector3(90, 0, 0)))
	# Eyes in the dark of the middle stall.
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, Vector3(STALL_DOORS[1] + s * 0.12, YARD + 1.45, fz - 0.05), mat_glow, Vector3(0, 0, 8.0 * s),
			Vector3(0.12, 0.06, 0.03)))
	# Barred stall windows on the back wall (the view of a Lair whose gate faces away from the camera): violet glow.
	for x: float in STALL_DOORS:
		var bz: float = STALL_Z1
		it.append(BMG.item(box1, Vector3(x, 2.2, bz + 0.03), mat_dark, Vector3.ZERO, Vector3(0.66, 0.46, 0.06)))
		it.append(BMG.item(box1, Vector3(x, 2.2, bz + 0.05), mat_gate, Vector3.ZERO, Vector3(0.48, 0.28, 0.04)))
		for ox: float in [-0.12, 0.0, 0.12]:
			it.append(BMG.item(box1, Vector3(x + ox, 2.2, bz + 0.08), mat_dark, Vector3.ZERO, Vector3(0.045, 0.32, 0.03)))
	# Banner bars on both gable ends (the banners face the two cameras).
	for bx: float in [STALL_X1 + 0.04, STALL_X0 - 0.04]:
		it.append(BMG.item(box1, Vector3(bx, 2.68, STALL_CZ), mat_metal, Vector3.ZERO, Vector3(0.09, 0.09, 0.95)))
	_merged("Stalls", "stalls", it)
	# Roof tier, built in its own frame: local +Z = Body +X (the ridge), local +X = Body -Z (the yard slope).
	var rg := Node3D.new()
	rg.name = "StallRoofFrame"
	rg.position = Vector3(STALL_CX, 0.0, STALL_CZ)
	rg.basis = Basis(Vector3.UP, PI * 0.5)
	_body.add_child(rg)
	it = []
	var depth: float = wl + 0.3
	_gable_roof(it, 0.0, 0.0, STALL_HALF, STALL_EAVE, STALL_RISE, depth, wl - 0.1, 3, mat_stone, mat_team, mat_metal, 0.3, 9.0)
	# 2026-09-30 C3: every other tile course a deeper team shade (painted shades are free in the merged material).
	var tn: int = 0
	for e: Array in it:
		if e[2] == mat_team:
			if tn % 2 == 1:
				e[2] = mat_team_dk
			tn += 1
	var ridge: float = STALL_EAVE + STALL_RISE
	for lz: float in [-2.05, -0.6, 1.95]:
		it.append(BMG.item(_cyl(0.0, 0.15, 0.55, 4), Vector3(0, ridge + 0.4, lz), mat_metal, Vector3(0, 45, 0)))
	for v: Vector3 in VENTS:
		var lz: float = v.x - STALL_CX
		it.append(BMG.item(box1, Vector3(0, ridge + 0.22, lz), mat_dark, Vector3.ZERO, Vector3(0.46, 0.5, 0.46)))
		for s: float in [-1.0, 1.0]:
			it.append(BMG.item(box1, Vector3(s * 0.2, ridge + 0.55, lz), mat_iron, Vector3.ZERO, Vector3(0.06, 0.18, 0.5)))
		it.append(BMG.item(_cyl(0.0, 0.46, 0.42, 4), Vector3(0, ridge + 0.85, lz), mat_dark, Vector3(0, 45, 0)))
	var roof := _merged("StallRoof", "stall_roof", it, rg)
	_hide_on_collapse.append(rg)
	# Damage: a caved-in patch on the yard slope (< 50 %), a burning hole on the back slope (< 25 %).
	var hole_l: Vector3 = _gable_point(0.0, STALL_HALF, STALL_EAVE, STALL_RISE, 1.0, 0.42, 0.3, -1.25)
	var hole_r: Vector3 = _gable_point(0.0, STALL_HALF, STALL_EAVE, STALL_RISE, -1.0, 0.42, 0.3, 1.2)
	_show_below_50.append(_roof_hole("RoofHoleL", roof, hole_l, 1.0, STALL_HALF, STALL_RISE, false))
	_show_below_25.append(_roof_hole("RoofHoleR", roof, hole_r, -1.0, STALL_HALF, STALL_RISE, true))
	return [rg.transform * hole_l, rg.transform * hole_r]


## The call circle's rune ring (a Plinth* group: it stays flat on the dais when the building collapses; it turns and
## flares on play_call). The black disc, the silver ring and the six standing stones are merged into PlinthBase.
func _build_circle(box1: BoxMesh) -> void:
	var grp := Node3D.new()
	grp.name = "PlinthCallCircle"
	grp.position = CALL_POINT
	_body.add_child(grp)
	var it: Array = []
	for k: int in 16:
		var a: float = TAU * k / 16.0
		var p := Vector3(cos(a), 0.0, sin(a)) * 1.02
		it.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.UP, -a - PI * 0.5).scaled_local(Vector3(0.3, 0.025, 0.09)),
			p + Vector3(0, 0.095, 0)), _g_circle))
	for k: int in 8:
		var a: float = TAU * k / 8.0 + PI / 8.0
		var p := Vector3(cos(a), 0.0, sin(a)) * 0.62
		it.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.UP, PI * 0.5 - a).scaled_local(Vector3(0.06, 0.025, 0.24)),
			p + Vector3(0, 0.095, 0)), _g_circle))
	it.append(BMG.item(box1, Vector3(0, 0.095, 0), _g_circle, Vector3(0, 45, 0), Vector3(0.3, 0.025, 0.3)))
	_rune = _merged("RuneRing", "runes", it, grp, false)


## Yard props: the back-right torch stand, a stone trough on the right fence, a bone pile behind the right tower and a
## hitching post behind the left one. All outside the circle's clear radius.
func _build_props(box1: BoxMesh) -> void:
	var grp := Node3D.new()
	grp.name = "YardProps"
	_body.add_child(grp)
	var it: Array = []
	var t := TORCH_BACK
	for k: int in 3:
		var a: float = TAU * k / 3.0 + 0.5
		var foot := t + Vector3(cos(a) * 0.42, 0.03, sin(a) * 0.42)
		it.append(_taper(foot, t + Vector3(0, 0.75, 0), 0.06, 0.05, mat_iron, 4))
	it.append(BMG.item(_cyl(0.07, 0.09, 3.0, 6), t + Vector3(0, 1.5, 0), mat_iron))
	it.append(BMG.item(_cyl(0.13, 0.13, 0.1, 6), t + Vector3(0, 2.2, 0), mat_metal))
	it.append(BMG.item(_cyl(0.28, 0.12, 0.32, 6), t + Vector3(0, 3.16, 0), mat_iron))
	it.append(BMG.item(_cyl(0.3, 0.3, 0.07, 6), t + Vector3(0, 3.33, 0), mat_metal))
	for k: int in 4:
		var a: float = TAU * k / 4.0 + PI / 4.0
		var d := Vector3(cos(a), 0.0, sin(a))
		_spike(it, t + d * 0.26 + Vector3(0, 3.3, 0), d * 0.45 + Vector3(0, 1.0, 0), 0.05, 0.42, mat_iron)
	# Stone trough on the right fence.
	var tr := Vector3(2.33, YARD, 0.55)
	it.append(BMG.item(box1, tr + Vector3(0, 0.25, 0), mat_stone, Vector3.ZERO, Vector3(0.62, 0.5, 1.3)))
	it.append(BMG.item(box1, tr + Vector3(0, 0.49, 0), mat_dark, Vector3.ZERO, Vector3(0.46, 0.04, 1.14)))
	it.append(BMG.item(box1, tr + Vector3(0, 0.02, 0), mat_dark, Vector3.ZERO, Vector3(0.7, 0.06, 1.38)))
	# Bone pile (behind the right tower) with a small horse skull.
	var bp := Vector3(2.0, YARD, -1.0)
	for b: Array in [[Vector3(0.0, 0.07, 0.0), 20.0], [Vector3(0.1, 0.07, 0.12), -35.0], [Vector3(-0.08, 0.17, 0.05), 70.0],
			[Vector3(0.14, 0.17, -0.06), 5.0]]:
		var bpos: Vector3 = bp + (b[0] as Vector3)
		var yaw: float = b[1]
		it.append(BMG.item(_cyl(0.055, 0.055, 0.72, 6), bpos, mat_bone, Vector3(90, yaw, 0)))
		var ax := Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0, 0.36)
		for sgn: float in [-1.0, 1.0]:
			it.append(BMG.item(_sphere(0.085), bpos + ax * sgn, mat_bone))
	it.append(BMG.item(box1, bp + Vector3(-0.35, 0.14, 0.3), mat_bone, Vector3(0, 40, 0), Vector3(0.24, 0.24, 0.3)))
	it.append(_taper(bp + Vector3(-0.35, 0.12, 0.3), bp + Vector3(-0.62, 0.08, 0.52), 0.1, 0.07, mat_bone, 4))
	# Hitching post behind the left tower: iron post, spike cap, a ring and a hanging chain.
	var hp := Vector3(-2.3, YARD, -1.1)
	it.append(BMG.item(box1, hp + Vector3(0, 0.7, 0), mat_iron, Vector3.ZERO, Vector3(0.18, 1.4, 0.18)))
	it.append(BMG.item(_cyl(0.0, 0.13, 0.36, 4), hp + Vector3(0, 1.58, 0), mat_metal, Vector3(0, 45, 0)))
	it.append(BMG.item(_ring(0.1, 0.16), hp + Vector3(-0.14, 1.15, 0), mat_metal, Vector3(0, 0, 90)))
	for k: int in 3:
		it.append(BMG.item(box1, hp + Vector3(-0.16, 0.98 - 0.15 * k, 0.02 * k), mat_metal, Vector3(0, 0, 18.0 * (k % 2) - 9.0),
			Vector3(0.05, 0.13, 0.05)))
	_merged("PropsMesh", "props", it, grp)
	_hide_on_collapse.append(grp)


## The three violet torches in one mesh (hidden on the collapse): the iron sconces on the two tower fronts flanking
## the gate and every flame (own flicker material; the back torch's stand is a yard prop).
func _build_torches(box1: BoxMesh) -> void:
	var it: Array = []
	for i: int in 2:
		var f: Vector3 = TORCH_FLAMES[i]
		var face_z: float = GATE_Z - _tower_hw(2.75) + 0.02
		it.append(BMG.item(box1, Vector3(f.x, 2.72, (face_z + f.z) * 0.5), mat_iron, Vector3.ZERO,
			Vector3(0.1, 0.1, absf(f.z - face_z))))
		it.append(BMG.item(box1, Vector3(f.x, 2.72, face_z - 0.03), mat_iron, Vector3.ZERO, Vector3(0.24, 0.34, 0.06)))
		it.append(BMG.item(_cyl(0.2, 0.1, 0.26, 6), Vector3(f.x, 2.9, f.z), mat_iron))
		it.append(BMG.item(_cyl(0.22, 0.22, 0.06, 6), Vector3(f.x, 3.03, f.z), mat_metal))
		for k: int in 3:
			var a: float = TAU * k / 3.0 + PI / 2.0
			var d := Vector3(cos(a), 0.0, sin(a))
			_spike(it, Vector3(f.x, 3.02, f.z) + d * 0.18, d * 0.4 + Vector3(0, 1.0, 0), 0.04, 0.3, mat_iron)
	for i: int in TORCH_FLAMES.size():
		var f: Vector3 = TORCH_FLAMES[i]
		var big: float = 1.25 if i == 2 else 1.0
		it.append(BMG.item(_cyl(0.0, 0.17 * big, 0.6 * big, 6), f, _g_torch))
		it.append(BMG.item(_cyl(0.0, 0.1 * big, 0.36 * big, 6), f + Vector3(0.05, 0.12 * big, 0.02), _g_torch, Vector3(0, 30, 8)))
	var flames := _merged("Torches", "torches", it, null, false)
	_hide_on_collapse.append(flames)


## Two nightmare heads over the first and third half-doors (own meshes: they nod and look around).
func _build_heads(box1: BoxMesh) -> void:
	var grp := Node3D.new()
	grp.name = "Nightmares"
	_body.add_child(grp)
	var it: Array = []
	# Head space: pivot at the neck over the door, looking -X.
	it.append(BMG.item(box1, Vector3(-0.08, 0.26, 0), mat_horse, Vector3(0, 0, 22), Vector3(0.3, 0.62, 0.32)))
	it.append(_taper(Vector3(-0.12, 0.62, 0), Vector3(-0.68, 0.42, 0), 0.21, 0.13, mat_horse, 4))
	it.append(BMG.item(box1, Vector3(-0.68, 0.4, 0), mat_horse, Vector3.ZERO, Vector3(0.2, 0.21, 0.22)))
	var sl: float = atan2(0.2, 0.56)
	var mid := Vector3(-0.4, 0.52, 0) + Vector3(-sin(sl), cos(sl), 0) * 0.14
	it.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.BACK, sl).scaled_local(Vector3(0.5, 0.05, 0.19)), mid), mat_metal))
	it.append(BMG.item(box1, Vector3(-0.56, 0.44, 0), mat_metal, Vector3.ZERO, Vector3(0.05, 0.25, 0.25)))
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item(box1, Vector3(-0.3, 0.58, s * 0.16), mat_glow, Vector3.ZERO, Vector3(0.1, 0.06, 0.04)))
		it.append(_taper(Vector3(-0.04, 0.72, s * 0.08), Vector3(0.02, 0.98, s * 0.13), 0.06, 0.0, mat_horse, 4))
	for k: int in 3:
		var a := Vector3(0.06, 0.2 + 0.2 * k, 0)
		it.append(_taper(a, a + Vector3(0.3, 0.2, 0), 0.1, 0.0, mat_team, 4))
	for i: int in 2:
		var x: float = STALL_DOORS[0] if i == 0 else STALL_DOORS[2]
		var mi := _merged("Head%d" % i, "head", it, grp, false)
		var rest := Vector3(0, deg_to_rad(-90.0 + (-14.0 if i == 0 else 12.0)), 0)
		mi.position = Vector3(x, YARD + 1.08, STALL_Z0 - 0.04)
		mi.rotation = rest
		mi.set_instance_shader_parameter(&"ao_bottom", YARD + 0.9)
		mi.set_instance_shader_parameter(&"ao_height", 2.0)
		_heads.append(mi)
		_head_rest.append(rest)
	_hide_on_collapse.append(grp)


## Torch halos (billboards, one shared material), the fake light pool of the back torch on the dais and the circle
## pool (shown only while calling); the two pools share one material (their strength is the node transparency).
func _build_glows() -> void:
	var halo_mat := _soft_mat(Color(glow_color, 0.55), true)
	for i: int in TORCH_FLAMES.size():
		var q := QuadMesh.new()
		q.size = Vector2.ONE * (1.7 if i == 2 else 1.45)
		var h := MeshInstance3D.new()
		h.name = "Halo%d" % i
		h.mesh = q
		h.material_override = halo_mat
		h.position = (TORCH_FLAMES[i] as Vector3) + Vector3(0, 0.08, 0)
		h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(h)
		_halos.append(h)
	var pool_mat := _soft_mat(Color(0.62, 0.3, 1.0, 0.6), false)
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * 2.3
	var mi := MeshInstance3D.new()
	mi.name = "LightPoolBack"
	mi.mesh = pm
	mi.material_override = pool_mat
	mi.position = Vector3(2.15, YARD + 0.07, 1.8)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_pools.append(mi)
	var cp := PlaneMesh.new()
	cp.size = Vector2.ONE * 3.4
	_circle_pool = MeshInstance3D.new()
	_circle_pool.name = "CirclePool"
	_circle_pool.mesh = cp
	_circle_pool.material_override = pool_mat
	_circle_pool.position = CALL_POINT + Vector3(0, 0.12, 0)
	_circle_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_circle_pool.visible = false
	add_child(_circle_pool)


## Idle: smoke from the two stall cowls, the ground mist ring. One-shots: raise smoke out of the gate, the call column.
func _build_fx() -> void:
	for i: int in VENTS.size():
		var sm := _pm(Vector3.UP, 14.0, 0.45, 0.8, Vector3(0.18, 0.06, 0.0), 0.45, 1.6,
			_ramp(Color(0.30, 0.22, 0.40, 0.55), Color(0.16, 0.11, 0.22), false))
		sm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		sm.emission_sphere_radius = 0.15
		_idle_fx.append(_particles("StallSmoke%d" % (i + 1), _body, VENTS[i], 9, 3.2, sm, _mix_quad, false))
	var mist := _pm(Vector3(1, 0, 0), 180.0, 0.1, 0.25, Vector3.ZERO, 1.2, 2.4,
		_ramp(Color(0.25, 0.12, 0.38, 0.28), Color(0.25, 0.12, 0.38), false))
	mist.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mist.emission_ring_axis = Vector3.UP
	mist.emission_ring_radius = 3.4
	mist.emission_ring_inner_radius = 2.6
	mist.emission_ring_height = 0.05
	_idle_fx.append(_particles("GroundMist", self, Vector3(0, 0.35, 0), 8, 6.0, mist, _mix_quad, false))
	var rs := _pm(Vector3(0, 0.25, -1), 35.0, 1.4, 2.8, Vector3(0, 0.3, 0), 0.7, 2.4,
		_ramp(Color(0.28, 0.17, 0.38, 0.75), Color(0.14, 0.09, 0.2), false))
	rs.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rs.emission_box_extents = Vector3(0.8, 0.9, 0.1)
	rs.damping_min = 0.8
	rs.damping_max = 1.2
	_raise_smoke = _particles("RaiseSmoke", _body, Vector3(GATE_X, 1.8, GATE_Z - 0.85), 18, 1.8, rs, _mix_quad, true)
	var cc := _pm(Vector3.UP, 6.0, 1.6, 3.2, Vector3(0, 0.6, 0), 0.16, 0.05,
		_ramp(Color(0.85, 0.55, 1.0), Color(0.45, 0.15, 0.8), false))
	cc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	cc.emission_ring_axis = Vector3.UP
	cc.emission_ring_radius = 1.05
	cc.emission_ring_inner_radius = 0.9
	cc.emission_ring_height = 0.05
	_call_col = _particles("CallColumn", _body, CALL_POINT + Vector3(0, 0.12, 0), 36, 1.6, cc, _add_quad, true)
	_call_col.explosiveness = 0.35


# --- Helpers ---

## An iron / silver spike from `base` along `dir` (normalised here), `len` long, base radius `r`.
func _spike(it: Array, base: Vector3, dir: Vector3, r: float, len: float, mat: Material) -> void:
	it.append(_taper(base, base + dir.normalized() * len, r, 0.0, mat, 4))


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
	t.rings = 24
	t.ring_segments = 6
	return t


## Soft radial quad material (unshaded, additive, no depth write): halos and light pools.
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
	m.disable_fog = true  # G-E 5: an additive quad must not fog
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = tex
	return m


## B8 merge: the deeper tile courses follow the team colour (x 0.75).
func _vc_team() -> Array:
	return [mat_team, [mat_team_dk, 0.75]]

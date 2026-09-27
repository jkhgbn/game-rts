class_name EmberSpireModel
extends SmallBuildingModel
## Fire tower "Ember Spire" (buildings.md: 1 x 1 cell = 2 x 2 m, height 5, orb blinks on each shot). Task 5.V2.
## Read from the RTS camera: a tapering eight-sided stone shaft with lava cracks, a flared team-coloured cup,
## four bronze claws holding a glowing ember orb, and an obsidian shard leaning on the shaft (the asymmetric
## secondary). One small OmniLight (no shadows) at the orb. A.9: stepped plinth, four dark buttress fins at the
## foot, two bronze bands, three slits; scaffolding while built, a broken stump with embers after the collapse.
## Extra hook for towers: play_shot() (the Tower script calls it each time it fires): the orb blinks 0.1 s.
## NightSpireModel (shadow_tower.gd) extends this and only changes the palette and the parts.

const SHOT_HOLD := 0.1
const SHOT_FADE := 0.18

var _orb: MeshInstance3D
var _orb_mat: ShaderMaterial
var _orb_light: OmniLight3D
var _orb_y: float = 4.5
var _light_energy: float = 1.3
var _crown: MultiMeshInstance3D
var _shot_left: float = 0.0
var _flicker_amp: float = 0.08
var _orb_energy: float = 3.2


func _setup() -> void:
	kingdom_color = Color(0.85, 0.30, 0.12)
	glow_color = Color(1.0, 0.55, 0.15)
	stone_color = Color(0.30, 0.26, 0.24)
	dark_color = Color(0.12, 0.10, 0.10)
	trim_color = Color(0.62, 0.40, 0.16)
	smoke_color = Color(0.16, 0.14, 0.13)
	stain_color = Color(0.22, 0.07, 0.02, 0.35)
	footprint = 2.0
	crack_strength = 0.9
	plinth_top = 0.4
	wreck_top = 1.25
	smoke_points = [Vector3(0.3, 2.6, 0.3)]
	blaze_points = [Vector3(-0.25, 3.3, -0.2)]


## A.9: merged tiers (Plinth, Shaft with fins / bands / slits / shard, Cup), claws stay a MultiMesh (_crown).
func _build_parts() -> void:
	var box1: Mesh = _box(Vector3.ONE)
	var oct := Basis(Vector3.UP, PI / 8.0)
	var slit_mat: ShaderMaterial = _glow_mat(glow_color, 2.2, 1.5, false)
	var ember_mat: ShaderMaterial = _glow_mat(glow_color, 2.4, 2.0, false)
	var it: Array = []
	it.append(_it(box1, Vector3(0, 0.2, 0), _m_dark, Vector3.ZERO, Vector3(2.3, 0.4, 2.3)))
	it.append(_itx(_cyl(1.0, 1.08, 0.24, 8), Transform3D(oct, Vector3(0, 0.52, 0)), _m_dark))
	_no_collapse.append(_merged("Plinth", "plinth", it))
	# Shaft tier: tapering octagonal stone shaft, two bronze bands, four dark buttress fins at the foot, three
	# glowing slits, the obsidian shard leaning on the front-left (asymmetric secondary).
	it = []
	it.append(_itx(_cyl(0.55, 0.85, 3.0, 8), Transform3D(oct, Vector3(0, 1.9, 0)), _m_stone))
	it.append(_itx(_cyl(0.78, 0.8, 0.22, 8), Transform3D(oct, Vector3(0, 1.55, 0)), _m_trim))
	it.append(_itx(_cyl(0.64, 0.66, 0.2, 8), Transform3D(oct, Vector3(0, 3.1, 0)), _m_trim))
	for i: int in 4:
		var a: float = PI * 0.25 + PI * 0.5 * i
		var d := Vector3(sin(a), 0.0, cos(a))
		it.append(_itx(_prism(Vector3(0.75, 1.3, 0.3), 0.0), Transform3D(Basis(Vector3.UP, a - PI * 0.5),
			d * 1.02 + Vector3(0, 1.05, 0)), _m_dark))
	for s: Array in [[Vector3(0, 2.55, -0.64), 0.0], [Vector3(0.64, 2.55, 0), 90.0], [Vector3(-0.64, 2.55, 0), 90.0]]:
		it.append(_it(box1, s[0], slit_mat, Vector3(0, s[1], 0), Vector3(0.14, 0.6, 0.08)))
	var sb: Basis = _lean(Vector3(-1, 0, -0.4), 22.0)
	it.append(_itx(_cyl(0.0, 0.3, 1.9, 5), Transform3D(sb, Vector3(-0.72, 0.4, -0.3) + sb * Vector3(0, 0.95, 0)), _m_dark))
	_merged("Shaft", "shaft", it)
	# Cup tier: the flared team cup and its bronze rim.
	it = []
	it.append(_itx(_cyl(1.0, 0.6, 0.55, 8), Transform3D(oct, Vector3(0, 3.67, 0)), _m_team))
	it.append(_itx(_cyl(1.06, 1.06, 0.16, 8), Transform3D(oct, Vector3(0, 4.0, 0)), _m_trim))
	var cup := _merged("Cup", "cup", it)
	_build_scaffold(2.3, 4.3, [2.0, 3.7] as Array[float])
	_build_wreck(0.72, 1.3, ember_mat, 2021, 4)
	# Four claws leaning out 14 deg around the orb (one draw call).
	var cx: Array[Transform3D] = []
	for i: int in 4:
		var a: float = PI * 0.25 + PI * 0.5 * i
		var dir := Vector3(sin(a), 0.0, cos(a))
		var b: Basis = _lean(dir, 14.0)
		cx.append(Transform3D(b, dir * 0.72 + Vector3(0, 4.05, 0) + b * Vector3(0, 0.55, 0)))
	_crown = _multi("Claws", _cyl(0.0, 0.15, 1.1, 4), _m_trim, cx)
	_build_orb(0.34, 3.2)
	_hide_on_collapse.append_array([cup, _crown])
	var em := _pm(Vector3.UP, 30.0, 0.5, 1.1, Vector3(0, 0.2, 0), 0.08, 0.04,
		_ramp(Color(1.0, 0.7, 0.25), Color(1.0, 0.4, 0.1), false))
	em.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	em.emission_sphere_radius = 0.35
	_idle_particles("OrbEmbers", Vector3(0, _orb_y, 0), 10, 1.4, em, true)


## The orb (team glow) and its light, shared by both towers.
func _build_orb(radius: float, energy: float) -> void:
	_orb_energy = energy
	_orb_mat = _glow_mat(glow_color, energy, 3.0, true)
	_orb = _part("Orb", _sphere(radius), _orb_mat, Vector3(0, _orb_y, 0))
	_floaters.append(_orb)
	_orb_light = _light("OrbLight", Vector3(0, _orb_y, 0), glow_color, _light_energy, 5.5)


# --- Tower hook ---

## The tower fired: the orb blinks (boost x3.5, +30 % size, light x3) for 0.1 s, then fades in 0.18 s.
func play_shot() -> void:
	if _destroyed or _progress < 1.0:
		return
	_shot_left = SHOT_HOLD + SHOT_FADE


# --- Overrides ---

func _idle(delta: float) -> void:
	_orb.position.y = _orb_y + 0.08 * sin(_t * 2.2)
	var k: float = 0.0
	if _shot_left > 0.0:
		_shot_left = maxf(_shot_left - delta, 0.0)
		k = 1.0 if _shot_left > SHOT_FADE else _shot_left / SHOT_FADE
		_orb_mat.set_shader_parameter(&"boost", _sel_boost() * (1.0 + 2.5 * k))
		if _shot_left <= 0.0:
			_orb_mat.set_shader_parameter(&"boost", _sel_boost())
	if _float_appear >= 1.0:
		_orb.scale = Vector3.ONE * (1.0 + 0.3 * k)
	var n: float = sin(_t * 7.3) * 0.5 + sin(_t * 12.1) * 0.5
	_orb_light.light_energy = _light_energy * (1.0 - _flicker_amp + _flicker_amp * n) * (1.0 + 2.0 * k) \
		* (1.0 if _progress >= 1.0 else 0.0)
	_crown_idle(delta)


func _crown_idle(_delta: float) -> void:
	pass


func _on_progress(building: bool) -> void:
	_orb_light.visible = not building


func _on_health(smoke_on: bool, fire_on: bool) -> void:
	# Below 50 % one claw breaks off; below 25 % the orb dims and its light gutters.
	_crown.multimesh.visible_instance_count = _crown.multimesh.instance_count - 1 if smoke_on else -1
	_orb_mat.set_shader_parameter(&"energy", _orb_energy * 0.55 if fire_on else _orb_energy)
	_flicker_amp = 0.35 if fire_on else 0.08


func _on_team_color(g: Color) -> void:
	_orb_light.light_color = g


func _on_destroy_start() -> void:
	_shot_left = 0.0


func _on_destroy(t: float) -> void:
	_orb_light.light_energy = 5.0 if t < 0.2 else maxf(_orb_light.light_energy - 0.1, 0.0)
	if t >= 0.2:
		_orb_light.visible = t < 0.8

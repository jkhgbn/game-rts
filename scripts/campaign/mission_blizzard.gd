class_name MissionBlizzard
extends Node3D
## Torvald's storm (docs/design/mission-02.md "Mechanic: blizzard"): while `blowing`, every team's sight radii are
## x `sight_mult` (FogOfWar.sight_scale, floor 5 m) and the look is on: snow particles in a 40 x 20 x 40 box that
## follows the camera and a white-blue world fog (the level's WorldEnvironment, restored when it stops).
## Placeholder art (M9.V1): CPUParticles3D quads, no new lights.

const SNOW_AMOUNT := 400
const BOX := Vector3(40.0, 20.0, 40.0)
const FOG_COLOR := Color(0.82, 0.88, 0.96)
## Depth fog from FOG_BEGIN to FOG_END metres from the camera. The game camera sits ~30-40 m from the ground it looks
## at: the begin is past the near ground so units / walls stay readable and the storm eats the far side of the screen
## (2026-10-04 screenshot pass: 8 / 70 / 0.85 was a white-out where nothing could be read).
const FOG_DENSITY := 0.6
const FOG_BEGIN := 30.0
const FOG_END := 100.0

var blowing := false        ## Read only.
var sight_mult := 0.5
var follow: Node3D          ## What the snow box follows (the camera rig); null = stays where it is.

var _snow: CPUParticles3D
var _env: Environment
var _env_saved := {}


func _ready() -> void:
	_snow = CPUParticles3D.new()
	_snow.name = "Snow"
	_snow.amount = SNOW_AMOUNT
	_snow.lifetime = 3.0
	_snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snow.emission_box_extents = BOX * 0.5
	_snow.direction = Vector3(0.6, -1.0, 0.2)
	_snow.spread = 12.0
	_snow.gravity = Vector3(0.0, -2.0, 0.0)
	_snow.initial_velocity_min = 5.0
	_snow.initial_velocity_max = 8.0
	_snow.scale_amount_min = 0.6
	_snow.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.2, 0.2)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.95, 0.97, 1.0, 0.75)
	m.albedo_texture = _flake_texture()   # a soft round flake, not a square
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m
	_snow.mesh = q
	_snow.emitting = false
	_snow.visible = false
	add_child(_snow)


func set_blowing(on: bool) -> void:
	if on == blowing:
		return
	blowing = on
	var fog := FogOfWar.find()
	if fog:
		var s := sight_mult if on else 1.0
		for t in fog.sight_scale.size():
			fog.sight_scale[t] = s
	_snow.emitting = on
	_snow.visible = on
	_set_world_fog(on)


func _process(_delta: float) -> void:
	if blowing and follow != null and is_instance_valid(follow):
		global_position = follow.global_position + Vector3(0.0, BOX.y * 0.5, 0.0)


func _set_world_fog(on: bool) -> void:
	if _env == null:
		_env = _find_env()
	if _env == null:
		return
	if on:
		_env_saved = {}
		for k: String in ["fog_enabled", "fog_mode", "fog_light_color", "fog_density", "fog_depth_begin",
				"fog_depth_end", "fog_depth_curve"]:
			_env_saved[k] = _env.get(k)
		_env.fog_enabled = true
		_env.fog_mode = Environment.FOG_MODE_DEPTH
		_env.fog_light_color = FOG_COLOR
		_env.fog_density = FOG_DENSITY
		_env.fog_depth_begin = FOG_BEGIN
		_env.fog_depth_end = FOG_END
		_env.fog_depth_curve = 1.0
	else:
		for k: String in _env_saved:
			_env.set(k, _env_saved[k])


func _find_env() -> Environment:
	var root := get_tree().current_scene if is_inside_tree() else null
	if root == null:
		return null
	for n in root.find_children("*", "WorldEnvironment", true, false):
		var we := n as WorldEnvironment
		if we and we.environment:
			we.environment = we.environment.duplicate()   # the preset's Environment is a shared resource
			return we.environment
	return null


static func _flake_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	g.add_point(0.45, Color(1.0, 1.0, 1.0, 0.8))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 32
	t.height = 32
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

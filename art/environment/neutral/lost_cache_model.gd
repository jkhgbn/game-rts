class_name LostCacheModel
extends Node3D
## Lost Cache look (docs/design/items.md; polished in task A2.7): an old timber reliquary bound in bronze, domed lid,
## a glowing amber seal gem on its lock, sitting on a cracked mossy plinth among ruin stones (a leaning broken tablet,
## a fallen column drum, spilled coins). Root = chest centre on the ground; the lid hinges on its -z edge.
## Closed: the seal gem pulses, gold glints rise from the lid seam, and every few seconds the lid rattles as if
## something inside wants out (a puff of gold). `set_open(true)` (LostCache, when a wizard / champion walks in):
## the lid shakes, then bursts open (-112 deg, overshoot), the seal breaks (gem out), a heap of glowing treasure
## and a shaft of golden light appear and coins fly out - all within 0.35 s (LostCache shrinks the art from 0.6 s).
## `set_open(false)` (LostCache, when it reappears): the chest pops up out of the ground in a puff of dust, closed.
## `set_opened(b)` snaps to either state with no animation (previews, loading a saved state).
## Fading / hiding the chest stays in LostCache. No real light; all motion in _process (no Tween).

const SITE_GROUND := preload("res://art/environment/neutral/site_ground.gd")
const OPEN_ANGLE := -112.0
const OPEN_LEN := 0.40
const APPEAR_LEN := 0.55
const RATTLE_LEN := 0.45

var _open: bool = false
var _anim: StringName = &""
var _anim_t: float = 0.0
var _rattle_in: float = 4.0
var _t: float = 0.0
var _burst_fired: bool = false

var _chest: Node3D
var _lid: Node3D
var _gem: Node3D
var _inner: Node3D
var _shaft: GeometryInstance3D
var _sparkles: GPUParticles3D
var _coins: GPUParticles3D
var _glints: GPUParticles3D
var _puff: GPUParticles3D


func _ready() -> void:
	_chest = get_node("Chest") as Node3D
	_lid = get_node("Chest/LidPivot") as Node3D
	_gem = get_node("Chest/LockGem") as Node3D
	_inner = get_node("Chest/InnerGlow") as Node3D
	_shaft = get_node("Chest/Shaft") as GeometryInstance3D
	_sparkles = get_node("Chest/Sparkles") as GPUParticles3D
	_coins = get_node("Chest/Coins") as GPUParticles3D
	_glints = get_node("Chest/Glints") as GPUParticles3D
	_puff = get_node("Puff") as GPUParticles3D
	_t = randf() * 10.0
	_rattle_in = 3.0 + randf() * 4.0
	# MAP.P2: a ring of scuffed earth with a baked contact shadow around the plinth (shared mesh + material).
	if get_node_or_null(^"SiteGround") == null:
		move_child(SITE_GROUND.add(self, "SiteGround", Vector2.ZERO, 1.25, 1.5, Vector3.ZERO, 0.0, 6), 0)
	_snap(_open)


## Animated: true = burst open (the moment of looting), false = pop back up closed (the cache reappears).
func set_open(b: bool) -> void:
	_open = b
	if not is_node_ready():
		return
	_anim = &"open" if b else &"appear"
	_anim_t = 0.0
	_burst_fired = false
	if b:
		_sparkles.emitting = false
	else:
		_snap(false)
		_chest.position.y = -0.45
		_chest.scale = Vector3.ONE * 0.6
		_puff.restart()
		_glints.restart()


## Instant: shows the open (looted, treasure glowing) or closed chest with no animation.
func set_opened(b: bool) -> void:
	_open = b
	_anim = &""
	if is_node_ready():
		_snap(b)


func is_open() -> bool:
	return _open


func _snap(b: bool) -> void:
	_lid.rotation = Vector3(deg_to_rad(OPEN_ANGLE) if b else 0.0, 0, 0)
	_chest.position = Vector3.ZERO
	_chest.rotation = Vector3.ZERO
	_chest.scale = Vector3.ONE
	_gem.visible = not b
	_inner.visible = b
	_shaft.visible = b
	_shaft.scale = Vector3.ONE
	_shaft.transparency = 0.25
	_sparkles.emitting = not b


func _process(delta: float) -> void:
	_t += delta
	match _anim:
		&"open":
			_anim_t += delta
			_pose_open(_anim_t)
			if _anim_t >= OPEN_LEN:
				_anim = &""
		&"appear":
			_anim_t += delta
			var u := clampf(_anim_t / APPEAR_LEN, 0.0, 1.0)
			var k := _ease_out_back(u, 2.2)
			_chest.position.y = lerpf(-0.45, 0.0, k)
			_chest.scale = Vector3.ONE * lerpf(0.6, 1.0, k)
			_chest.rotation.z = deg_to_rad(7.0) * sin(u * PI * 2.0) * (1.0 - u)
			if u >= 1.0:
				_anim = &""
				_chest.position.y = 0.0
				_chest.scale = Vector3.ONE
				_chest.rotation = Vector3.ZERO
		&"rattle":
			_anim_t += delta
			var u := clampf(_anim_t / RATTLE_LEN, 0.0, 1.0)
			var shake := sin(_anim_t * 55.0) * (1.0 - u)
			_lid.rotation.x = deg_to_rad(-9.0) * maxf(shake, 0.0)
			_chest.position.y = 0.035 * absf(sin(_anim_t * 27.0)) * (1.0 - u)
			_chest.rotation.z = deg_to_rad(2.5) * shake
			if u >= 1.0:
				_anim = &""
				_lid.rotation.x = 0.0
				_chest.position.y = 0.0
				_chest.rotation.z = 0.0
		_:
			if _open:
				# The treasure light breathes.
				var p := 0.5 + 0.5 * sin(_t * 2.4)
				_shaft.transparency = 0.18 + 0.22 * p
				_shaft.scale = Vector3(1.0 + 0.06 * p, 1.0, 1.0 + 0.06 * p)
			elif is_visible_in_tree():
				_rattle_in -= delta
				if _rattle_in <= 0.0:
					_rattle_in = 4.5 + randf() * 5.0
					_anim = &"rattle"
					_anim_t = 0.0
					_glints.restart()


## 0-0.10 the lid strains and shakes · 0.10 the seal breaks: burst of coins, treasure and light · 0.10-0.35 the lid
## flies back with an overshoot, the chest hops.
func _pose_open(t: float) -> void:
	if t < 0.10:
		var s := sin(t * 70.0)
		_lid.rotation.x = deg_to_rad(-7.0) * maxf(s, 0.0)
		_chest.rotation.z = deg_to_rad(3.0) * s
		return
	if not _burst_fired:
		_burst_fired = true
		_gem.visible = false
		_inner.visible = true
		_shaft.visible = true
		_coins.restart()
		_glints.restart()
	var u := clampf((t - 0.10) / 0.25, 0.0, 1.0)
	_lid.rotation.x = deg_to_rad(OPEN_ANGLE) * _ease_out_back(u, 1.8)
	_chest.rotation.z = 0.0
	_chest.position.y = 0.07 * sin(clampf(u * 1.6, 0.0, 1.0) * PI)
	_shaft.scale = Vector3(1.0, maxf(0.05, _ease_out_back(u, 1.2)), 1.0)
	_shaft.transparency = lerpf(0.0, 0.25, u)


static func _ease_out_back(x: float, s: float) -> float:
	var y := x - 1.0
	return 1.0 + (s + 1.0) * y * y * y + s * y * y

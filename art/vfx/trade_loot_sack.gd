class_name TradeLootSackModel
extends Node3D
## Loot sack look (task 10.V11, docs/design/market-trade.md 5.4 / 9): a 0.5 m burlap sack tied with rope, leaning,
## a stitched gold coin patch on its belly, coins peeking out of its mouth and a spill of coins on the ground, a gold
## rim light on the burlap, a warm gold glow pool under it with glints turning on its rim, and sparkles.
## Root = sack centre on the ground. Built by art/vfx/trade_loot_sack_build.gd (res://art/vfx/trade_loot_sack.tscn).
## Motion (all in _process, no Tween, no real light):
##  - drop: falls in from 0.8 m, squashes, a puff of road dust and a gold sparkle (auto on _ready);
##  - idle: the sack bobs slowly (0.04 m, only the sack: the spill stays on the ground) and sways; glints twinkle;
##  - warning: in its last WARN_TIME seconds the glow and the coins blink, faster and faster;
##  - end: fades out (transparency) at the end of its lifetime, or at once when picked up.
## Works alone (its own clock, `lifetime` 45 s) or under a LootSack (scripts/world/loot_sack.gd): it then reads the
## owner's `time_left()` / `is_available()` / `amount` (duck typed: the nearest ancestor with `time_left`) and needs
## no calls at all. Hooks for other code: `set_amount`, `set_time_left`, `play_drop`, `play_pickup`, `fade_out`,
## `is_faded`, `bobs_itself`.

const WARN_TIME := 8.0          ## Blinking before it vanishes.
const END_FADE := 0.6           ## Fade at the end of its lifetime.
const DROP_LEN := 0.45
const DROP_HEIGHT := 0.8
const PICKUP_LEN := 0.25
const BOB_AMP := 0.04
const BOB_SPEED := 1.9
const SWAY_DEG := 5.0

## Seconds before it fades when no LootSack owns it.
@export var lifetime := 45.0
## Standalone: fade by itself at the end of `lifetime` (off = only when fade_out / play_pickup is called).
@export var auto_expire := true

var _t := 0.0
var _left := 45.0
var _anim := &""
var _anim_t := 0.0
var _fade_len := 0.0            # > 0 while fading out
var _fade_t := 0.0
var _faded := false
var _alpha := 1.0
var _size := 1.0
var _owner: Node = null
var _dust_fired := false

var _sack: Node3D
var _parts: Array[GeometryInstance3D] = []
var _glow: GeometryInstance3D
var _gold: Array[GeometryInstance3D] = []
var _glints: GPUParticles3D
var _dust: GPUParticles3D
var _burst: GPUParticles3D


func _ready() -> void:
	_sack = get_node("Sack") as Node3D
	_glow = get_node("Glow") as GeometryInstance3D
	_glints = get_node("Glints") as GPUParticles3D
	_dust = get_node("Dust") as GPUParticles3D
	_burst = get_node("Burst") as GPUParticles3D
	for path: String in ["ContactShadow", "Spill", "Sack/Body", "Sack/MouthCoins"]:
		var g := get_node_or_null(path) as GeometryInstance3D
		if g:
			_parts.append(g)
	for path: String in ["Spill", "Sack/MouthCoins"]:
		var g := get_node_or_null(path) as GeometryInstance3D
		if g:
			_gold.append(g)
	_t = randf() * 10.0
	_left = lifetime
	_owner = _find_owner()
	if _owner:
		var a: Variant = _owner.get(&"amount")
		if a != null:
			set_amount(int(a))
	play_drop()


func _process(delta: float) -> void:
	if _faded:
		return
	_t += delta
	# Clock: the owner's, else our own.
	if is_instance_valid(_owner) and _owner.is_inside_tree():
		_left = float(_owner.call(&"time_left"))
		if _fade_len <= 0.0 and _owner.has_method(&"is_available") and not bool(_owner.call(&"is_available")):
			fade_out(0.25)   # picked up or expired: the LootSack shrinks it too
	else:
		_owner = null
		_left -= delta
		if auto_expire and _fade_len <= 0.0 and _left <= END_FADE:
			fade_out(maxf(_left, 0.05))
	_animate(delta)
	# Warning blink (glow + coins) in the last seconds: 1.5 Hz -> 6 Hz.
	var blink := 0.0
	if _left < WARN_TIME and _fade_len <= 0.0:
		var k := 1.0 - clampf(_left / WARN_TIME, 0.0, 1.0)
		var hz := lerpf(1.5, 6.0, k * k)
		blink = pow(0.5 + 0.5 * sin(_t * TAU * hz), 3.0) * (0.5 + 0.5 * k)
	_glow.set_instance_shader_parameter(&"blink", blink)
	for g in _gold:
		g.set_instance_shader_parameter(&"glint_boost", blink)
	# Fade out.
	if _fade_len > 0.0:
		_fade_t += delta
		_set_alpha(1.0 - clampf(_fade_t / _fade_len, 0.0, 1.0))
		if _fade_t >= _fade_len:
			_faded = true
			visible = false
			_glints.emitting = false


# ---------------------------------------------------------------- hooks

## Bigger sack for more gold: 0.85 x (1 gold) to 1.2 x (120+ gold).
func set_amount(gold: int) -> void:
	_size = lerpf(0.85, 1.2, clampf(float(gold) / 120.0, 0.0, 1.0))
	if is_node_ready():
		_sack.scale = Vector3.ONE * _size


## Standalone clock: seconds before it fades (ignored while a LootSack owns it).
func set_time_left(seconds: float) -> void:
	_left = maxf(seconds, 0.0)


## Falls in from 0.8 m with a squash, dust and a gold sparkle (auto on _ready).
func play_drop() -> void:
	if not is_node_ready():
		return
	_anim = &"drop"
	_anim_t = 0.0
	_dust_fired = false
	_burst.restart()


## Picked up: the sack hops and shrinks away in 0.25 s (the gold sparkle is TradeVfx `sack_pickup`).
func play_pickup() -> void:
	if not is_node_ready() or _faded:
		return
	_anim = &"pickup"
	_anim_t = 0.0
	fade_out(PICKUP_LEN)


## Fades everything out over `duration` s, then hides (never frees itself: the owner does).
func fade_out(duration: float = 0.5) -> void:
	if _faded or (_fade_len > 0.0 and _fade_len - _fade_t <= duration):
		return
	_fade_len = maxf(duration, 0.01)
	_fade_t = 0.0
	_glints.emitting = false


## True once it has fully faded (hidden).
func is_faded() -> bool:
	return _faded


## The model bobs its own sack (the coin spill stays on the ground): the owner should not bob the whole model.
func bobs_itself() -> bool:
	return true


# ---------------------------------------------------------------- internals

func _animate(delta: float) -> void:
	var bob := BOB_AMP * (0.5 + 0.5 * sin(_t * BOB_SPEED))
	var sway := deg_to_rad(SWAY_DEG) * sin(_t * BOB_SPEED * 0.5 + 0.7)
	match _anim:
		&"drop":
			_anim_t += delta
			var u := clampf(_anim_t / DROP_LEN, 0.0, 1.0)
			var fall := 0.55                                   # share of the time spent falling
			var y := 0.0
			var sq := 1.0
			if u < fall:
				var f := u / fall
				y = DROP_HEIGHT * (1.0 - f * f)
			else:
				var b := (u - fall) / (1.0 - fall)
				if not _dust_fired:
					_dust_fired = true
					_dust.restart()
				y = 0.09 * sin(b * PI) * (1.0 - b)
				sq = 1.0 - 0.28 * sin(minf(b * 2.2, 1.0) * PI) * (1.0 - b)
			_sack.position = Vector3(0.0, y, 0.0)
			_sack.scale = Vector3(_size * (2.0 - sq), _size * sq, _size * (2.0 - sq))
			_sack.rotation = Vector3(0.0, 0.0, sway * u)
			_glow.set_instance_shader_parameter(&"fade", u)
			if u >= 1.0:
				_anim = &""
		&"pickup":
			_anim_t += delta
			var u := clampf(_anim_t / PICKUP_LEN, 0.0, 1.0)
			_sack.position = Vector3(0.0, 0.5 * sin(u * PI * 0.5), 0.0)
			_sack.scale = Vector3.ONE * _size * lerpf(1.1, 0.3, u)
			_sack.rotation.y += delta * 12.0
		_:
			_sack.position = Vector3(0.0, bob, 0.0)
			_sack.rotation = Vector3(sway * 0.4, _sack.rotation.y + delta * 0.15, sway)
			_sack.scale = Vector3.ONE * _size


func _set_alpha(a: float) -> void:
	if absf(a - _alpha) < 0.004 and a > 0.0:
		return
	_alpha = a
	for g in _parts:
		g.transparency = 1.0 - a
	_glow.set_instance_shader_parameter(&"fade", a)


## The nearest ancestor (3 levels) that has `time_left()`: the LootSack that owns this look.
func _find_owner() -> Node:
	var n := get_parent()
	for i in 3:
		if n == null:
			return null
		if n.has_method(&"time_left"):
			return n
		n = n.get_parent()
	return null

class_name WayshrineModel
extends Node3D
## The Wayshrine capture point's model (task 12.V18, docs/design/map-fill.md 4.2 / 4.4 / 10). Draw-only: no collider,
## no light, no gameplay (CapturePoint owns the rules and calls the hooks below). Scene: wayshrine.tscn, generated with
## its meshes by build_wayshrine.gd; this script only animates it.
## Look: a round dais of worn flagstones with a rune circle inlaid in a dark channel; in the middle a waist-high carved
## standing stone (1.42 m, two uneven horns cradling a notch, the Wayfarer's mark carved on both faces), three mossy
## marker stones around the dais (one upright, one leaning, one toppled); above the notch a slate rune stone floats at
## y 1.6 (FLOAT_Y), slowly spinning and bobbing, with three chips orbiting it. Root origin = the point's centre on the
## ground; front = +Z (the default camera side). Footprint: none (units walk through), dais r 1.86, markers to r 2.6,
## contact shadow r 2.8 (the clearing is r 3).
## States (all blended smoothly, nothing pops):
##   asleep, neutral  dark: carved runes are dark grooves, no column, the rune stone turns slowly and glimmers pale blue.
##   awake            gold: runes, rune stone, rune circle and a halo glow gold (energy 2.8-3.4), a beam of light flares
##                    up out of the rune stone (to 12 m) over a low glow on the dais, golden motes spiral up, the rune
##                    stone spins faster.
##   owned (asleep)   the capturer's colour at a calmer energy (~1.5, rune stone ~2.4), rune circle and halo faint;
##                    no column. Awake always shows gold (the owner colour comes back when it sleeps again).
##   capturing        set_capture(color, ratio): the rune circle fills clockwise (from -Z, seen from above) in the
##                    capturer's colour with a bright head, the carved runes burn in that colour from the dais up to
##                    the rune stone (0.2 + ratio x 1.8 m), the rune stone spins up.
##   blessing         play_blessing(color): a ring of light races out to the 6 m capture radius, the column flashes
##                    in that colour (even on a sleeping shrine), runes flare, the rune stone whirls (1.8 s).
## Hooks (all safe before _ready; the values are kept and shown when the model enters the tree, without a fade):
##   set_state(state: StringName)   &"asleep" / &"awake" (any other value is ignored)
##   set_owner_color(c: Variant)    a Color = owned (shown while asleep), null = neutral
##   set_capture(color: Variant, ratio: float)   progress 0-1 of the team capturing it; null colour or ratio 0 = none
##   play_blessing(color: Variant = null)        the blessing burst in `color` (null = gold); safe to retrigger
##   set_selected(on: bool)          warm selection rim on the stones
## Budget: 9 small meshes, ~1 700 triangles. Stone parts 1 draw call each (dais + standing stone + markers merged, rune
## stone, shards); effects (rune circle, halo, column, motes, blessing burst) are hidden while they have nothing to show,
## so a sleeping neutral shrine costs 4 draw calls incl. the contact decal. 0 lights, 0 particle nodes, 0 colliders,
## shared .tres materials (never duplicated), per-shrine state in instance uniforms.

## In-game grade 2026-09-30 (row 40, the 40 m read x1.1): the stones (Stone node) and the floating rune stone (Float
## node) are drawn 10 % larger (their node scale in wayshrine.tscn); the float height follows (1.6 -> 1.76 m).
## Effects (rune circle, blessing ring, column) keep their sizes: the ring stays on the 6 m capture radius.
const FLOAT_Y := 1.76
const STATE_ASLEEP := &"asleep"
const STATE_AWAKE := &"awake"
const GOLD := Color(1.0, 0.72, 0.28)
const DORMANT := Color(0.46, 0.54, 0.70)
const WAKE_TIME := 1.4          ## s: the column rises from the dais
const BLESSING_TIME := 1.8      ## s: play_blessing
## Rune energies [standing stone, rune stone] per look.
## Dormant: the carved runes on the stones stay dark grooves; the floating rune stone GLIMMERS pale blue (in-game grade
## 2026-09-30: a sleeping shrine had no glow point at all and read as a grey disc; 0.16 -> 3.0, one soft point).
const E_DORMANT := Vector2(0.1, 3.0)
const E_OWNED := Vector2(1.5, 2.4)
const E_AWAKE := Vector2(2.8, 3.4)

var _state: StringName = STATE_ASLEEP
var _owner_on: bool = false
var _owner_color: Color = GOLD
var _cap_on: bool = false
var _cap_color: Color = Color.WHITE
var _cap_ratio: float = 0.0
var _selected: bool = false
var _bless_t: float = -1.0
var _bless_color: Color = GOLD

# Smoothed look (0-1 blends).
var _awake_k: float = 0.0
var _owner_k: float = 0.0
var _grow: float = 1.0
var _cap_k: float = 0.0
var _cap_shown: float = 0.0
var _sel_k: float = 0.0
var _spin: float = 0.0
var _t: float = 0.0
var _ready_done: bool = false

var _stone: GeometryInstance3D
var _float: Node3D
var _rune: GeometryInstance3D
var _orbit: Node3D
var _shards: GeometryInstance3D
var _halo: GeometryInstance3D
var _ring: GeometryInstance3D
var _column: GeometryInstance3D
var _motes: GeometryInstance3D
var _burst: GeometryInstance3D


func _ready() -> void:
	_stone = get_node_or_null(^"Stone") as GeometryInstance3D
	_float = get_node_or_null(^"Float") as Node3D
	_rune = get_node_or_null(^"Float/RuneStone") as GeometryInstance3D
	_orbit = get_node_or_null(^"Float/Orbit") as Node3D
	_shards = get_node_or_null(^"Float/Orbit/Shards") as GeometryInstance3D
	_halo = get_node_or_null(^"Float/Halo") as GeometryInstance3D
	_ring = get_node_or_null(^"Ring") as GeometryInstance3D
	_column = get_node_or_null(^"Column") as GeometryInstance3D
	_motes = get_node_or_null(^"Motes") as GeometryInstance3D
	_burst = get_node_or_null(^"Burst") as GeometryInstance3D
	_ready_done = true
	_t = randf() * 20.0
	_spin = randf() * TAU
	_snap()
	_apply(0.0)


func _process(delta: float) -> void:
	_t += delta
	_apply(delta)


# --- Hooks ---

## &"awake" (gold glow, light column) or &"asleep" (dark, or the owner's colour). Other values are ignored.
func set_state(state: StringName) -> void:
	if state != STATE_AWAKE and state != STATE_ASLEEP:
		return
	if state == STATE_AWAKE and _state != STATE_AWAKE and _awake_k < 0.05:
		_grow = 0.0   # the column rises from the dais again
	_state = state


func get_state() -> StringName:
	return _state


func is_awake() -> bool:
	return _state == STATE_AWAKE


## `c` = the owning team's colour (shown while the shrine sleeps), or null (neutral).
func set_owner_color(c: Variant) -> void:
	if c is Color:
		_owner_on = true
		_owner_color = c
	else:
		_owner_on = false


## The owner colour, or null when neutral.
func get_owner_color() -> Variant:
	return _owner_color if _owner_on else null


## Capture progress of the team taking the shrine: `color` its colour, `ratio` 0-1. null or ratio <= 0 = nobody.
func set_capture(color: Variant, ratio: float) -> void:
	_cap_ratio = clampf(ratio, 0.0, 1.0)
	if color is Color and _cap_ratio > 0.0:
		if not _cap_on:
			_cap_shown = minf(_cap_shown, _cap_ratio) if _cap_k > 0.05 else _cap_ratio
		_cap_on = true
		_cap_color = color
	else:
		_cap_on = false


func get_capture_ratio() -> float:
	return _cap_ratio if _cap_on else 0.0


## The blessing burst (the capturer got the Wayfarer's Blessing): `color` = its colour, null = gold. 1.8 s, retriggers.
func play_blessing(color: Variant = null) -> void:
	_bless_color = color if color is Color else GOLD
	_bless_t = 0.0


func is_blessing_playing() -> bool:
	return _bless_t >= 0.0


func set_selected(on: bool) -> void:
	_selected = on


# --- Look ---

## Jumps every blend to the current hooks (spawn: no fade).
func _snap() -> void:
	_awake_k = 1.0 if _state == STATE_AWAKE else 0.0
	_grow = 1.0
	_owner_k = 1.0 if _owner_on else 0.0
	_cap_k = 1.0 if _cap_on else 0.0
	_cap_shown = _cap_ratio
	_sel_k = 1.0 if _selected else 0.0


func _apply(delta: float) -> void:
	if not _ready_done:
		return
	var awake_t: float = 1.0 if _state == STATE_AWAKE else 0.0
	_awake_k = move_toward(_awake_k, awake_t, delta / (0.9 if awake_t > _awake_k else 1.3))
	if awake_t > 0.0:
		_grow = move_toward(_grow, 1.0, delta / WAKE_TIME)
	_owner_k = move_toward(_owner_k, 1.0 if _owner_on else 0.0, delta / 0.7)
	_cap_k = move_toward(_cap_k, 1.0 if _cap_on else 0.0, delta / (0.2 if _cap_on else 0.45))
	if _cap_on:
		_cap_shown = lerpf(_cap_shown, _cap_ratio, clampf(delta * 8.0, 0.0, 1.0)) if delta > 0.0 else _cap_ratio
	_sel_k = move_toward(_sel_k, 1.0 if _selected else 0.0, delta / 0.2)
	# Blessing envelope: a fast attack, then a long fall.
	var flash: float = 0.0
	var b: float = 0.0
	if _bless_t >= 0.0:
		_bless_t += delta
		b = _bless_t / BLESSING_TIME
		if b >= 1.0:
			_bless_t = -1.0
			b = 0.0
		else:
			flash = smoothstep(0.0, 0.06, b) * pow(1.0 - b, 2.0)

	# State colour and energies: dormant -> owned (asleep only) -> awake gold; the blessing tints everything briefly.
	var col: Color = DORMANT.lerp(_owner_color, _owner_k)
	var e: Vector2 = E_DORMANT.lerp(E_OWNED, _owner_k)
	col = col.lerp(GOLD, _awake_k)
	e = e.lerp(E_AWAKE, _awake_k)
	var tint: float = clampf(flash * 2.5, 0.0, 1.0)
	col = col.lerp(_bless_color, tint)
	var cap: float = _cap_shown * _cap_k
	var cap_ratio: float = cap if _cap_k > 0.01 else 0.0

	# Motion: slow drift asleep, livelier awake, spinning up while captured, a whirl on the blessing.
	var speed: float = lerpf(0.22, 0.6, _awake_k) + 1.5 * cap + 6.0 * flash
	_spin = fmod(_spin + speed * delta, TAU * 64.0)
	if _float:
		var bob: float = sin(_t * 1.15) * lerpf(0.03, 0.06, _awake_k)
		_float.position = Vector3(0.0, FLOAT_Y + bob, 0.0)
	if _rune:
		(_rune as Node3D).rotation = Vector3(sin(_t * 0.7) * 0.06, _spin, sin(_t * 0.53 + 1.0) * 0.05)
	if _orbit:
		_orbit.rotation = Vector3(0.32, -_spin * 1.7, 0.18)

	for gi: GeometryInstance3D in [_stone, _rune, _shards]:
		if gi == null:
			continue
		var energy: float = e.y if gi != _stone else e.x
		if gi == _shards:
			energy = e.y * lerpf(1.0, 0.8, _awake_k)   # the orbiting chips glimmer with the rune stone while asleep
		gi.set_instance_shader_parameter(&"rune_color", col)
		gi.set_instance_shader_parameter(&"rune_energy", energy)
		gi.set_instance_shader_parameter(&"cap_color", _cap_color)
		gi.set_instance_shader_parameter(&"cap_ratio", cap_ratio)
		gi.set_instance_shader_parameter(&"flare", flash)
		gi.set_instance_shader_parameter(&"select_k", _sel_k)

	# Rune circle + pool.
	var ring_e: float = 0.6 * _owner_k * (1.0 - _awake_k) + 1.0 * _awake_k + 1.2 * flash
	_fx(_ring, col, ring_e, ring_e > 0.005 or cap_ratio > 0.0)
	if _ring:
		_ring.set_instance_shader_parameter(&"cap_color", _cap_color)
		_ring.set_instance_shader_parameter(&"cap_ratio", cap_ratio)
	# Halo around the rune stone (leans toward the capturer's colour while captured).
	var halo_e: float = 0.35 * _owner_k * (1.0 - _awake_k) + 1.25 * _awake_k + 1.5 * flash + 0.6 * cap
	_fx(_halo, col.lerp(_cap_color, cap * 0.6), halo_e, halo_e > 0.005)
	# Light column + motes: awake, or flashing in the blessing colour.
	var col_color: Color = GOLD.lerp(_bless_color, tint)
	var col_e: float = 1.35 * _awake_k + 1.8 * flash
	_fx(_column, col_color, col_e, col_e > 0.005)
	if _column:
		var g: float = _grow
		if _bless_t >= 0.0:
			g = maxf(g, smoothstep(0.0, 0.18, b))
		_column.set_instance_shader_parameter(&"grow", g)
	_fx(_motes, col_color, 1.0 * _awake_k * _grow + 1.4 * flash, _awake_k > 0.005 or flash > 0.005)
	# Blessing burst.
	_fx(_burst, _bless_color, 1.0, _bless_t >= 0.0)
	if _burst:
		_burst.set_instance_shader_parameter(&"burst", b)


func _fx(gi: GeometryInstance3D, c: Color, energy: float, show: bool) -> void:
	if gi == null:
		return
	gi.visible = show
	if show:
		gi.set_instance_shader_parameter(&"fx_color", c)
		gi.set_instance_shader_parameter(&"fx_energy", energy)

class_name UnitFx
extends RefCounted
## Shared look of the in-world selection ring and HP bar (graphics week G-D). Materials are cached statically: one
## per colour / style / tier, never one per unit (400+ lane units in Wave Strike). Per-unit values are instance
## uniforms (slots documented in selection_ring.gdshader / hp_bar.gdshader). Buildings may reuse it (see
## docs/handoff/for-systems-coder.md): ring_material / ring_mesh, bar_material / bar_mesh, start_trail.

const RING_SHADER := "res://scripts/units/fx/selection_ring.gdshader"
const BAR_SHADER := "res://scripts/units/fx/hp_bar.gdshader"
const RING_PAD := 0.45        # the ring quad reaches radius + RING_PAD (band radius + 0.20 .. + 0.32, dashes to + 0.41)
const RING_DASHES := 4.0      # own selection, High+
const SOLDIER_FRAME := 0.022  # m, the thin black frame of a soldier's bar
const TRAIL_HOLD := 0.3       # s the recent-damage trail holds before draining
const TRAIL_DRAIN := 0.5      # s to drain to the fill
const TICK_HP := 100.0        # HP per segment tick
const TICK_MIN_MAX_HP := 400.0
const CLOCK_WRAP := 1024.0    # s; keeps the clock small enough for shader floats

static var _ring_shader: Shader
static var _bar_shader: Shader
static var _ring_mats: Dictionary = {}   # key String -> ShaderMaterial
static var _bar_mats: Dictionary = {}    # key String -> ShaderMaterial
static var _ring_meshes: Dictionary = {}   # snapped half size (cm) -> PlaneMesh
static var _bar_meshes: Dictionary = {}    # Vector2i (mm) -> QuadMesh
static var _clock: Node = null
static var _trail_until_ms := 0


static func ring_shader() -> Shader:
	if _ring_shader == null:
		_ring_shader = load(RING_SHADER) as Shader
	return _ring_shader


static func bar_shader() -> Shader:
	if _bar_shader == null:
		_bar_shader = load(BAR_SHADER) as Shader
	return _bar_shader


## The shared ring material of a colour. `own` = the player's own units (slow dashes at High+). tier = graphics tier.
static func ring_material(color: Color, own: bool, tier: int) -> ShaderMaterial:
	var t := 2 if tier >= 2 else 0
	var dashes := own and t >= 2
	var key := "%s|%d|%d" % [color.to_html(), t, int(dashes)]
	var mat: ShaderMaterial = _ring_mats.get(key)
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = ring_shader()
		mat.set_shader_parameter(&"ring_color", color)
		mat.set_shader_parameter(&"gfx_tier", t)
		mat.set_shader_parameter(&"dash_count", RING_DASHES if dashes else 0.0)
		_ring_mats[key] = mat
	return mat


## The shared ground quad of a ring around a unit of `radius` (instance uniform `ring_radius` = radius).
static func ring_mesh(radius: float) -> PlaneMesh:
	var half_cm := int(ceil((radius + RING_PAD) * 100.0))
	var mesh: PlaneMesh = _ring_meshes.get(half_cm)
	if mesh == null:
		mesh = PlaneMesh.new()
		var s := half_cm * 0.02
		mesh.size = Vector2(s, s)
		_ring_meshes[half_cm] = mesh
	return mesh


## The shared HP bar material. `style` = Unit._hp_bar_frame_style() ({"color", "height", "frame", "inner"}; frame 0 =
## the thin black soldier frame). `ramp` = green -> yellow -> red by fill (the player's own units).
static func bar_material(fill_color: Color, ramp: bool, style: Dictionary, tier: int) -> ShaderMaterial:
	var t := 2 if tier >= 2 else 0
	var frame_m := float(style.get("frame", 0.0))
	var inner_m := float(style.get("inner", 0.0))
	var frame_color: Color = style.get("color", Color.BLACK)
	if frame_m <= 0.0:
		frame_m = SOLDIER_FRAME
		inner_m = 0.0
	var key := "%s|%d|%d|%s|%.3f|%.3f" % [fill_color.to_html(), int(ramp), t, frame_color.to_html(), frame_m, inner_m]
	var mat: ShaderMaterial = _bar_mats.get(key)
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = bar_shader()
		mat.set_shader_parameter(&"fill_color", fill_color)
		mat.set_shader_parameter(&"ramp_k", 1.0 if ramp else 0.0)
		mat.set_shader_parameter(&"gfx_tier", t)
		mat.set_shader_parameter(&"frame_color", frame_color)
		mat.set_shader_parameter(&"frame_size", Vector2(frame_m, frame_m))
		mat.set_shader_parameter(&"inner_size", Vector2(inner_m, inner_m))
		mat.set_shader_parameter(&"trail_hold", TRAIL_HOLD)
		mat.set_shader_parameter(&"trail_drain", TRAIL_DRAIN)
		mat.set_shader_parameter(&"fx_now", now())
		_bar_mats[key] = mat
	return mat


## The shared billboard quad of a bar size (m).
static func bar_mesh(size: Vector2) -> QuadMesh:
	var key := Vector2i(roundi(size.x * 1000.0), roundi(size.y * 1000.0))
	var mesh: QuadMesh = _bar_meshes.get(key)
	if mesh == null:
		mesh = QuadMesh.new()
		mesh.size = size
		_bar_meshes[key] = mesh
	return mesh


## Segment tick step of a bar (fraction of the bar per 100 HP; 0 = none).
static func tick_step(max_hp: float, total: float) -> float:
	if max_hp < TICK_MIN_MAX_HP or total <= 0.0:
		return 0.0
	return TICK_HP / total


## The effects clock (s, real time, wraps at CLOCK_WRAP). trail_t0 and the materials' fx_now use it.
static func now() -> float:
	return fmod(float(Time.get_ticks_msec()) * 0.001, CLOCK_WRAP)


## The trail level the shader shows at `at` (same curve as hp_bar.gdshader).
static func trail_value(from: float, fill: float, t0: float, at: float) -> float:
	var age := at - t0
	if age < -1.0:
		return fill
	var k := clampf((maxf(age, 0.0) - TRAIL_HOLD) / TRAIL_DRAIN, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	return lerpf(maxf(from, fill), fill, k)


## A trail started: keeps the shared bar materials' fx_now ticking until every trail has drained (one tiny node at
## the root, a handful of set_shader_parameter calls per frame, nothing per unit).
static func start_trail(from: Node) -> void:
	_trail_until_ms = Time.get_ticks_msec() + int((TRAIL_HOLD + TRAIL_DRAIN) * 1000.0) + 100
	if _clock != null and is_instance_valid(_clock):
		if not _clock.is_processing():   # asleep: fx_now is stale, push once; a running clock pushes every frame
			_push_now()
			_clock.set_process(true)
		return
	_push_now()
	if from == null or not from.is_inside_tree():
		return
	_clock = Clock.new()
	_clock.name = "UnitFxClock"
	from.get_tree().root.add_child.call_deferred(_clock)


## Number of shared materials built so far (tests / perf notes).
static func material_count() -> int:
	return _ring_mats.size() + _bar_mats.size()


static func _push_now() -> void:
	var t := now()
	for m: ShaderMaterial in _bar_mats.values():
		m.set_shader_parameter(&"fx_now", t)


## Pushes the clock to the shared bar materials while a trail runs, then sleeps.
class Clock extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(_delta: float) -> void:
		UnitFx._push_now()
		if Time.get_ticks_msec() > UnitFx._trail_until_ms:
			set_process(false)

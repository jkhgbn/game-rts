class_name EssenceWellModel
extends Node3D
## The Essence well capture point's model (task 12.V19, docs/design/map-fill.md 4.2 / 4.3 / 10). Draw-only: no collider,
## no light, no gameplay (CapturePoint owns the rules and calls the hooks below). Scene: essence_well.tscn, generated with
## its meshes and materials by build_essence_well.gd; this script only drives its state.
## Look: an old round well of mossy stone blocks on a low footing, a ring of cracked flagstones around it; the coping is
## broken at the back-right (two stones fell to the ground, violet essence crystals grow out of the gap). A broken timber
## winch: the left post still stands (~3 m, propped by a log) with half of the little shingle roof hanging from its top;
## the right post snapped at 1.4 m (its top lies on the apron), so the rope drum sags diagonally into the broken coping;
## a frayed rope hangs over the shaft, the bucket lies tipped on the apron in a small violet spill. The shaft brims with
## glowing violet essence (a swirling pool 0.3 m under the coping), violet mist wisps rise 2-3 m from it (two soft cards
## at every zoom + a few particles near the camera only). Carved runes run round the coping top: dim violet when neutral,
## the owner's colour when owned, with a soft light pool on the ground in the same colour.
## Root origin = the point's centre on the ground; front = +Z (the default camera side). Footprint 3 x 3 (the stone body
## r 1.56 and the winch posts stay inside it +0.3 m); flat apron / rubble / fallen pieces out to r ~3 (clearing r 3.5).
## States (blended smoothly, nothing pops; a well that enters the tree shows its hooks at once, without a fade):
##   neutral     runes dim violet (energy ~0.45, under the bloom threshold), a faint violet ground glow.
##   owned       set_owner_color(c): runes glow in the owner's colour (energy ~2.3, a slow shimmer runs round the ring),
##               ground glow in that colour; a short flare when the owner changes.
##   capturing   set_capture(color, ratio): the rune ring and an arc of the ground glow fill clockwise (from -Z, seen from
##               above, like the Wayshrine) in the capturer's colour, with a bright leading edge.
##   pulse       play_pulse() (each income tick): a violet ring races out from the rim to ~4.6 m, the pool, crystals, mist
##               and runes flare (1.1 s); safe to retrigger.
## Hooks (all safe before _ready; the values are kept and shown when the model enters the tree):
##   set_owner_color(c: Variant)                 a Color = owned, null = neutral
##   set_capture(color: Variant, ratio: float)   progress 0-1 of the team capturing it; null colour or ratio <= 0 = none
##   play_pulse()                                the income pulse
##   set_selected(on: bool)                      warm selection rim on the stones and timber
## Budget: 4 draw nodes (Body: stone + timber + runes in one surface and the contact shadow; Essence: pool + crystals +
## spill; Fx: mist cards + ground glow + pulse ring; Mist: 12 particles, drawn only within 40 m of the camera), 0 lights,
## shared .tres materials, per-well state in instance uniforms, no processing while idle.

const NEUTRAL_RUNE := Color(0.52, 0.36, 0.80)
const E_NEUTRAL := 0.45
const E_OWNED := 2.3
const PULSE_TIME := 1.1          ## s: play_pulse
const OWNER_FLASH_TIME := 0.9    ## s: the flare when the owner changes
## Kingdom colour (Unit.KINGDOM_COLORS / art-keep.md 0.2 "team") -> its glow colour (art-keep.md 0.2 "glow"); any other
## colour is brightened (hue kept) so runes always glow.
const KINGDOM_GLOWS: Array = [
	[Color(0.85, 0.30, 0.12), Color(1.00, 0.55, 0.15)],   # fire
	[Color(0.42, 0.22, 0.60), Color(0.70, 0.30, 1.00)],   # shadow
	[Color(0.45, 0.75, 0.97), Color(0.75, 0.92, 1.00)],   # ice
	[Color(0.40, 0.75, 0.30), Color(0.75, 1.00, 0.40)],   # nature
]

var _owner_on: bool = false
var _owner_glow: Color = NEUTRAL_RUNE
var _cap_on: bool = false
var _cap_color: Color = Color.WHITE
var _cap_ratio: float = 0.0
var _selected: bool = false
var _pulse_t: float = -1.0
var _flash_t: float = -1.0

# Shown look (blended toward the hooks).
var _col: Color = NEUTRAL_RUNE
var _energy: float = E_NEUTRAL
var _cap_k: float = 0.0
var _cap_shown: float = 0.0
var _sel_k: float = 0.0
var _ready_done: bool = false

var _body: GeometryInstance3D
var _essence: GeometryInstance3D
var _fx: GeometryInstance3D
var _fx_ground: GeometryInstance3D
var _mist: GPUParticles3D
## The Fx mesh split in two (in-game grade 2026-09-30): the standing mist cards stay on Fx, the flat ground glow and
## pulse ring go to their own flat node "FxGround" (a ground decal, 0.01 m thick: it is not part of the well's
## silhouette / body read). Same material and instance uniforms; built once from essence_well_fx.res and cached.
static var _split: Dictionary = {}


func _ready() -> void:
	_body = get_node_or_null(^"Body") as GeometryInstance3D
	_essence = get_node_or_null(^"Essence") as GeometryInstance3D
	_fx = get_node_or_null(^"Fx") as GeometryInstance3D
	_split_body()
	_split_fx()
	_mist = get_node_or_null(^"Mist") as GPUParticles3D
	_ready_done = true
	_snap()
	_apply(0.0)


func _process(delta: float) -> void:
	_apply(delta)


## Surface arrays keeping only the vertices `index` uses (re-indexed), so the part's AABB is its own.
static func _compact(arr: Array, index: PackedInt32Array) -> Array:
	var remap := {}
	var order := PackedInt32Array()
	var nix := PackedInt32Array()
	for i: int in index:
		if not remap.has(i):
			remap[i] = order.size()
			order.append(i)
		nix.append(int(remap[i]))
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	for k: int in Mesh.ARRAY_MAX:
		var src: Variant = arr[k]
		if src == null or k == Mesh.ARRAY_INDEX:
			continue
		var per := 1
		if k == Mesh.ARRAY_TANGENT:
			per = 4
		var dst: Variant = src.duplicate()
		dst.resize(order.size() * per)
		for j: int in order.size():
			for c: int in per:
				dst[j * per + c] = src[order[j] * per + c]
		out[k] = dst
	out[Mesh.ARRAY_INDEX] = nix
	return out


## The Body mesh's surface 1 (the shared contact-shadow disc, r 2.95) goes to its own flat node "Contact" (a ground
## decal like every other building's ContactDecal; in-game grade 2026-09-30: it made the well's body read as a 6 m
## grass-coloured square). Cached per source mesh.
func _split_body() -> void:
	var mi := _body as MeshInstance3D
	if mi == null or mi.mesh == null or mi.mesh.get_surface_count() < 2:
		return
	var src: Mesh = mi.mesh
	var key := "body_%d" % src.get_instance_id()
	if not _split.has(key):
		var body := ArrayMesh.new()
		body.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(0))
		body.surface_set_material(0, src.surface_get_material(0))
		var disc := ArrayMesh.new()
		disc.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(1))
		disc.surface_set_material(0, src.surface_get_material(1))
		_split[key] = [body, disc]
	var pair: Array = _split[key]
	mi.mesh = pair[0]
	var c := MeshInstance3D.new()
	c.name = "Contact"
	c.mesh = pair[1]
	c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	c.transform = mi.transform
	add_child(c)


func _split_fx() -> void:
	var mi := _fx as MeshInstance3D
	if mi == null or mi.mesh == null:
		return
	var src: Mesh = mi.mesh
	if not _split.has(src.get_instance_id()):
		# UV2.x = the part mode of build_essence_well.gd: 0 mist cards, 1 ground glow, 2 pulse ring.
		var arr := src.surface_get_arrays(0)
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var uv2: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV2]
		var cards := PackedInt32Array()
		var ground := PackedInt32Array()
		for t: int in range(0, ix.size(), 3):
			var flat: bool = uv2[ix[t]].x > 0.5
			(ground if flat else cards).append_array(PackedInt32Array([ix[t], ix[t + 1], ix[t + 2]]))
		var out: Array[ArrayMesh] = []
		for part: PackedInt32Array in [cards, ground]:
			var m := ArrayMesh.new()
			m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _compact(arr, part))
			m.surface_set_material(0, src.surface_get_material(0))
			out.append(m)
		_split[src.get_instance_id()] = out
	var pair: Array = _split[src.get_instance_id()]
	mi.mesh = pair[0]
	var g := MeshInstance3D.new()
	g.name = "FxGround"
	g.mesh = pair[1]
	g.material_override = mi.material_override
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.transform = mi.transform
	add_child(g)
	_fx_ground = g


# --- Hooks ---

## `c` = the owning team's colour, or null (neutral: dim violet runes).
func set_owner_color(c: Variant) -> void:
	var was_on: bool = _owner_on
	var old: Color = _owner_glow
	if c is Color:
		_owner_on = true
		_owner_glow = glow_of(c)
	else:
		_owner_on = false
	# A new owner (not the first colour a fresh well gets before it shows): a short flare.
	if _ready_done and _owner_on and (not was_on or not old.is_equal_approx(_owner_glow)):
		_flash_t = 0.0
	_wake()


## The owner's colour as the runes show it (its glow colour), or null when neutral.
func get_owner_color() -> Variant:
	return _owner_glow if _owner_on else null


## Capture progress of the team taking the well: `color` its colour, `ratio` 0-1. null or ratio <= 0 = nobody.
func set_capture(color: Variant, ratio: float) -> void:
	_cap_ratio = clampf(ratio, 0.0, 1.0)
	if color is Color and _cap_ratio > 0.0:
		if not _cap_on:
			_cap_shown = minf(_cap_shown, _cap_ratio) if _cap_k > 0.05 else _cap_ratio
		_cap_on = true
		_cap_color = glow_of(color)
	else:
		_cap_on = false
	_wake()


func get_capture_ratio() -> float:
	return _cap_ratio if _cap_on else 0.0


## The income pulse (every income tick): a violet ring from the rim, the essence flares. 1.1 s, safe to retrigger.
func play_pulse() -> void:
	_pulse_t = 0.0
	_wake()


func is_pulse_playing() -> bool:
	return _pulse_t >= 0.0


func set_selected(on: bool) -> void:
	_selected = on
	_wake()


## The glow colour shown for a team colour `c`: the kingdom glow for the four kingdom colours, else `c` brightened.
static func glow_of(c: Color) -> Color:
	for pair: Array in KINGDOM_GLOWS:
		var k: Color = pair[0]
		if absf(k.r - c.r) + absf(k.g - c.g) + absf(k.b - c.b) < 0.3:
			return pair[1]
	var h: float = c.h
	var s: float = clampf(c.s, 0.0, 0.85)
	return Color.from_hsv(h, s, 1.0)


# --- Look ---

func _wake() -> void:
	if _ready_done:
		set_process(true)


## Jumps every blend to the current hooks (spawn: no fade).
func _snap() -> void:
	_col = _owner_glow if _owner_on else NEUTRAL_RUNE
	_energy = E_OWNED if _owner_on else E_NEUTRAL
	_cap_k = 1.0 if _cap_on else 0.0
	_cap_shown = _cap_ratio
	_sel_k = 1.0 if _selected else 0.0


func _apply(delta: float) -> void:
	if not _ready_done:
		return
	var busy: bool = false
	var target_col: Color = _owner_glow if _owner_on else NEUTRAL_RUNE
	var target_e: float = E_OWNED if _owner_on else E_NEUTRAL
	if delta > 0.0:
		var k: float = clampf(delta * 3.5, 0.0, 1.0)
		_col = _col.lerp(target_col, k)
		_energy = lerpf(_energy, target_e, k)
		if _col.is_equal_approx(target_col) or absf(_col.r - target_col.r) + absf(_col.g - target_col.g) \
				+ absf(_col.b - target_col.b) < 0.004:
			_col = target_col
		else:
			busy = true
		if absf(_energy - target_e) < 0.01:
			_energy = target_e
		else:
			busy = true
	_cap_k = move_toward(_cap_k, 1.0 if _cap_on else 0.0, delta / (0.2 if _cap_on else 0.45))
	if _cap_on:
		_cap_shown = lerpf(_cap_shown, _cap_ratio, clampf(delta * 8.0, 0.0, 1.0)) if delta > 0.0 else _cap_ratio
		if absf(_cap_shown - _cap_ratio) > 0.002:
			busy = true
	if _cap_k != (1.0 if _cap_on else 0.0):
		busy = true
	_sel_k = move_toward(_sel_k, 1.0 if _selected else 0.0, delta / 0.2)
	if _sel_k != (1.0 if _selected else 0.0):
		busy = true

	# Pulse and owner flash envelopes: a fast attack, then a long fall.
	var p: float = -1.0
	var flare: float = 0.0
	if _pulse_t >= 0.0:
		_pulse_t += delta
		p = _pulse_t / PULSE_TIME
		if p >= 1.0:
			_pulse_t = -1.0
			p = -1.0
		else:
			flare = maxf(flare, smoothstep(0.0, 0.08, p) * pow(1.0 - p, 2.0))
			busy = true
	if _flash_t >= 0.0:
		_flash_t += delta
		var f: float = _flash_t / OWNER_FLASH_TIME
		if f >= 1.0:
			_flash_t = -1.0
		else:
			flare = maxf(flare, smoothstep(0.0, 0.1, f) * pow(1.0 - f, 2.0) * 0.8)
			busy = true

	var cap: float = _cap_shown * _cap_k if _cap_k > 0.01 else 0.0
	var cap_col: Color = _cap_color
	if _body:
		_body.set_instance_shader_parameter(&"rune_color", _col)
		_body.set_instance_shader_parameter(&"rune_energy", _energy)
		_body.set_instance_shader_parameter(&"cap_color", cap_col)
		_body.set_instance_shader_parameter(&"cap_ratio", cap)
		_body.set_instance_shader_parameter(&"flare", flare)
		_body.set_instance_shader_parameter(&"select_k", _sel_k)
	if _essence:
		_essence.set_instance_shader_parameter(&"flare", flare)
	for fx: GeometryInstance3D in [_fx, _fx_ground]:
		if fx:
			fx.set_instance_shader_parameter(&"rune_color", _col)
			fx.set_instance_shader_parameter(&"rune_energy", _energy)
			fx.set_instance_shader_parameter(&"cap_color", cap_col)
			fx.set_instance_shader_parameter(&"cap_ratio", cap)
			fx.set_instance_shader_parameter(&"pulse", p)
			fx.set_instance_shader_parameter(&"flare", flare)
	if _mist:
		_mist.speed_scale = 1.0 + flare * 1.5
	if not busy:
		set_process(false)

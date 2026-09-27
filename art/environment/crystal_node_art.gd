class_name CrystalNodeArt
extends Node3D
## Crystal node look (docs/design/economy.md): 3 glowing prisms (1.7 / 1.25 / 0.95 m) on a rock disc of
## radius 1.2, small shards around them, 3 motes orbiting, star glints (Sparkles) and a soft cyan light pool on
## the ground (GroundGlow, additive, no real light). Root = node centre on the ground.
## Hook: CrystalNode calls `set_fill_ratio(crystals_left / max_crystals)` whenever crystals change.
## The prisms shrink toward their base (they do not sink into the disc); the smallest prism is gone below
## 35 %, the middle one below 12 %, the shards below 55 %; glints and the light pool fade with the fill.
## The disc keeps its size, so the caller should NOT also scale the model.

const HIDE_BELOW: Array[float] = [0.0, 0.12, 0.35]
const SHARDS_BELOW := 0.55
const MOTE_SPIN := 0.6

var _ratio: float = 1.0
var _prisms: Array[Node3D] = []
var _motes: Node3D
var _shards: Node3D
var _sparkles: GPUParticles3D
var _pool: Node3D


func _ready() -> void:
	for n: String in ["Prism0", "Prism1", "Prism2"]:
		_prisms.append(get_node(n) as Node3D)
	_motes = get_node("Motes") as Node3D
	_shards = get_node_or_null(^"Shards") as Node3D
	_sparkles = get_node_or_null(^"Sparkles") as GPUParticles3D
	_pool = get_node_or_null(^"GroundGlow") as Node3D
	_apply()


## r = crystals left / crystals at start (0-1).
func set_fill_ratio(r: float) -> void:
	_ratio = clampf(r, 0.0, 1.0)
	if is_node_ready():
		_apply()


func get_fill_ratio() -> float:
	return _ratio


func _apply() -> void:
	var h: float = lerpf(0.35, 1.0, _ratio)
	var w: float = lerpf(0.7, 1.0, _ratio)
	for i: int in _prisms.size():
		var p: Node3D = _prisms[i]
		p.scale = Vector3(w, h, w)
		p.visible = _ratio > HIDE_BELOW[i]
	_motes.visible = _ratio > 0.0
	_motes.scale = Vector3(w, h, w)
	if _shards:
		_shards.visible = _ratio > SHARDS_BELOW
	if _sparkles:
		_sparkles.visible = _ratio > 0.0
		_sparkles.emitting = _ratio > 0.0
		_sparkles.amount_ratio = lerpf(0.3, 1.0, _ratio)
		_sparkles.scale = Vector3(1.0, h, 1.0)
	if _pool:
		_pool.visible = _ratio > 0.0
		var s: float = lerpf(0.55, 1.0, _ratio)
		_pool.scale = Vector3(s, 1.0, s)


func _process(delta: float) -> void:
	_motes.rotate_y(delta * MOTE_SPIN)

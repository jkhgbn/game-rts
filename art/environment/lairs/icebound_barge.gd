extends LairArt
## The Icebound Barge (task 13c.V9, docs/design/titans-2.md 7.2 + 11): the Frost Wyrm's lair. A draw-only OVERLAY on
## top of the Drowned Barge landmark (art/environment/landmarks/barge.tscn, untouched): an ice sheet r 5 on the river
## round the wreck (broken into floes at its edge), hoarfrost on the banks, icicles on the broken mast, the fallen
## spar, the yard, the gunwales, the cabin eaves and the bow post, an ice sheath up the mast, snow on the roof, crates,
## barrels and deck, ice plates jammed against the hull, a frost glaze on the upper hull, and cold vapour rising.
## Built by build_icebound_barge.gd. No collider, no light, no click.
##
## Placement: EpicBeasts puts the scene at the lair centre (like every LairArt; lair ids `wyrm_barge_s` /
## `wyrm_barge_n`, LairArt.scene_path_for maps them here, kind &"frost_wyrm"). The ROOT stays there; its child
## "Active" (everything drawn) snaps onto the barge landmark by itself: the nearest node of group "landmarks" with
## `landmark_id` &"lm_barge" within 12 m of the root (checked on _ready and a frame later), else the barge's known map
## spots (skirmish.gd LANDMARK_SPOTS and their point mirror), else it stays at the root (previews: put the root on the
## barge). `snap_to(barge_xf)` forces it.
## `set_occupied(true)` (a Wyrm nests here): the barge freezes over in FREEZE_IN s (the ice grows out of the wreck,
## the icicles grow down, the vapour starts); `set_occupied(false)` (the Wyrm died): it thaws in THAW s, then Active is
## hidden. The state set before _ready shows at once. Everything is driven by ONE instance uniform `freeze` (0-1) on
## the three meshes; nothing is created at runtime.

const FREEZE_IN := 2.5
const THAW := 6.0
const SNAP_RANGE := 12.0
## The Drowned Barge on Crown Hollow (skirmish.gd LANDMARK_SPOTS: north river, yaw 0; its point mirror, yaw PI).
const BARGE_SPOTS: Array[Transform3D] = [
	Transform3D(Basis.IDENTITY, Vector3(-6.2, 0.0, -24.5)),
	Transform3D(Basis(Vector3.UP, PI), Vector3(6.2, 0.0, 24.5)),
]

var _freeze := 0.0
var _target := 0.0
var _instant := true
var _snapped := false
var _parts: Array[GeometryInstance3D] = []
var _vapour: GPUParticles3D
var _active: Node3D


func _ready() -> void:
	_collect()
	_instant = true
	super._ready()
	_instant = false
	_snap()
	_snap_late.call_deferred()


## 0 = the plain Drowned Barge .. 1 = fully frozen (animated between the two).
func freeze_level() -> float:
	return _freeze


## True once "Active" sits on a barge landmark (or a forced transform).
func is_snapped() -> bool:
	return _snapped


## Puts the overlay on a barge whose global transform is `barge_xf`.
func snap_to(barge_xf: Transform3D) -> void:
	if _active == null:
		_collect()
	if _active and is_inside_tree():
		_active.global_transform = barge_xf
		_snapped = true


## Decor-free circles in world space (x, z, radius): the ice and the banks round it.
func decor_clear_circles() -> PackedVector3Array:
	var out := PackedVector3Array()
	var c := _active.global_position if _active and is_inside_tree() else (global_position if is_inside_tree()
			else position)
	out.append(Vector3(c.x, c.z, 5.5))
	return out


func _collect() -> void:
	_active = get_node_or_null(^"Active") as Node3D
	_parts.clear()
	if _active == null:
		return
	for n: Node in _active.get_children():
		if n is GeometryInstance3D and not (n is GPUParticles3D):
			_parts.append(n as GeometryInstance3D)
	_vapour = _active.get_node_or_null(^"Vapour") as GPUParticles3D


## LairArt calls this on _ready and on set_occupied: freeze / thaw instead of a hard swap.
func _apply() -> void:
	_target = 1.0 if is_occupied() else 0.0
	if _instant or not is_inside_tree():
		_freeze = _target
	_push()
	set_process(not is_equal_approx(_freeze, _target))


func _process(delta: float) -> void:
	var span := FREEZE_IN if _target > _freeze else THAW
	_freeze = move_toward(_freeze, _target, delta / span)
	_push()
	if is_equal_approx(_freeze, _target):
		_freeze = _target
		set_process(false)


func _push() -> void:
	if _active == null:
		return
	_active.visible = _freeze > 0.001
	for p in _parts:
		p.set_instance_shader_parameter(&"freeze", _freeze)
	if _vapour:
		var on := _target > 0.5 and _freeze > 0.35
		if _vapour.emitting != on:
			_vapour.emitting = on


func _snap_late() -> void:
	if not _snapped:
		_snap()


func _snap() -> void:
	if _active == null or not is_inside_tree():
		return
	var here := global_position
	var best: Node3D = null
	var best_d := SNAP_RANGE
	for n: Node in get_tree().get_nodes_in_group(&"landmarks"):
		if not (n is Node3D) or StringName(str(n.get_meta(&"landmark_id", &""))) != &"lm_barge":
			continue
		var d := Vector2((n as Node3D).global_position.x - here.x, (n as Node3D).global_position.z - here.z).length()
		if d < best_d:
			best_d = d
			best = n as Node3D
	if best:
		snap_to(best.global_transform)
		return
	for xf: Transform3D in BARGE_SPOTS:
		if Vector2(xf.origin.x - here.x, xf.origin.z - here.z).length() < SNAP_RANGE:
			_active.global_transform = xf
			return   # a known spot, but no landmark there (yet): keep looking a frame later

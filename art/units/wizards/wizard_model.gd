class_name WizardModel
extends CharacterModel
## Shared wizard layer (art-units.md 3, 6.2 wizards, 6.4 wizard_bolt, 6.5, 6.8): the staff orb / shard glow
## (instance uniform glow_boost, own_glow), its OmniLight3D and the orb bob. Vessa / Malrik add the parts and casts.
## Wizards never receive set_veterancy; set_carrying / play_mine stay inherited no-ops (no carry parts).

## Base energy of the staff light (Vessa 1.2, Malrik 1.0).
@export var light_energy: float = 1.2

var _orb: GeometryInstance3D        # glowing core driven here (meta own_glow)
var _bob: Node3D                    # the node that bobs (orb / shard)
var _bob_rest: Vector3
var _light: OmniLight3D
var _cast_boost: float = 1.0        # set by _pose_cast each frame of a cast
var _cast_light: float = 1.0
var _orb_written: float = -1.0
var _light_written: float = -1.0
var _bob_extra: Vector3 = Vector3.ZERO  # extra offset of the bob node this frame (subclass casts / death)


## Static parts of a kit pivot are pre-merged per pivot (Art Lab B1, art-units 8: <= 26 authored meshes per wizard;
## the heroes' polish detail was 56-69 separate parts). Same arguments and return as CharacterModel.add_part: static
## parts return null (as the kit already does once the type is cached); keep_separate / named parts and parts of
## non-pivot nodes pass straight to the kit. The batch becomes ONE part per pivot right before the kit merges it, so
## the merged mesh, its materials and every hook stay the same.
var _part_batch: Dictionary = {}    # pivot Node3D -> [[mesh, pivot-local Transform3D, [material per surface]], ...]


func add_part(pivot: Node3D, mesh: Mesh, mat: Material, model_pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, keep_separate: bool = false, part_name: String = "") -> MeshInstance3D:
	if keep_separate or part_name != "" or mesh == null or pivot == null or not _piv.has(pivot):
		return super.add_part(pivot, mesh, mat, model_pos, rot_deg, scl, keep_separate, part_name)
	if _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return null
	var xf := Transform3D(Basis.from_euler(rot_deg * DEG) * Basis.from_scale(scl), model_pos - model_origin(pivot))
	var mats: Array = []
	for s: int in mesh.get_surface_count():
		mats.append(mat)
	if not _part_batch.has(pivot):
		_part_batch[pivot] = []
	(_part_batch[pivot] as Array).append([mesh, xf, mats])
	return null


func _merge_pivot(i: int) -> void:
	var p: Node3D = _piv[i]
	var items: Array = _part_batch.get(p, [])
	if not items.is_empty():
		_part_batch.erase(p)
		var am := _merge_items(items)
		if am:
			super.add_part(p, am, null, model_origin(p), Vector3.ZERO, Vector3.ONE, false, "PartBatch")
	super._merge_pivot(i)


## Arm capsule + fist from the shoulder (model space) to the hand (model space).
func add_arm(pivot: Node3D, shoulder: Vector3, hand: Vector3, r: float, fist_r: float, sleeve: Material, skin: Material) -> void:
	var d := hand - shoulder
	var e := Basis(Quaternion(Vector3.DOWN, d.normalized())).get_euler() * (180.0 / PI)
	add_part(pivot, capsule(r, d.length() + r), sleeve, shoulder + d * 0.5, e)
	add_part(pivot, sphere(fist_r), skin, hand)


func _extra_process(dt: float) -> void:
	var b: float = 1.0
	var lm: float = 1.0
	if _action == &"attack" and _action_t < attack_windup + 0.08:
		b = 1.6
		lm = 1.4
	elif _action == &"cast":
		b = _cast_boost
		lm = _cast_light
	if _level_t < LEVEL_LEN:
		b = maxf(b, 3.0)
		lm = maxf(lm, 2.0)
	_cast_boost = 1.0
	_cast_light = 1.0
	var g := glow_level() * b
	if _dead:
		g = _death_glow()
		lm = g / 3.0
	if _orb and g != _orb_written:
		_orb_written = g
		_orb.set_instance_shader_parameter(&"glow_boost", g)
	var le := light_energy * lm
	if _light and le != _light_written:
		_light_written = le
		_light.light_energy = le
	if _bob:
		var y := 0.04 * sin((_t + _phase_off) * PI)   # +-0.04 m over 2 s
		_bob.position = _bob_rest + Vector3(0, y, 0) + _bob_extra
	_bob_extra = Vector3.ZERO
	_wizard_process(dt)


## Orb boost while dying (default: flash 5 for 0.15 s then out).
func _death_glow() -> float:
	return 5.0 if _death_t < 0.15 else maxf(0.0, 5.0 * (1.0 - (_death_t - 0.15) / 0.1))


## Subclass per-frame extras (flames, shard spin).
func _wizard_process(_dt: float) -> void:
	pass


func _on_revive() -> void:
	_orb_written = -1.0
	_light_written = -1.0
	if _bob:
		_bob.visible = true
		_bob.position = _bob_rest

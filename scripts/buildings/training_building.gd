class_name TrainingBuilding
extends Building
## A building that trains units (keep, barracks): queue of 5, crystals and pop reserved on queue,
## full refund on cancel, only slot 1 trains, new units walk to the rally point (or start gathering
## for a gather rally). Numbers: docs/design/economy.md and buildings.md.
## Units come out at the footprint corner facing `front_toward` (the map centre) + 1 m.

signal queue_changed
signal unit_trained(unit: Unit)   ## A queued unit came out (after it entered the scene).

const MAX_QUEUE := 5
const SPAWN_OUT := 1.0     ## Spawn point: corner + this much outward (per axis).
const RALLY_OUT := 4.0     ## Default rally: corner + this much outward.

const REASON_QUEUE_FULL := "Queue is full"
const REASON_NO_CRYSTALS := "Not enough crystals"
const REASON_POP_CAP := "Population cap reached"
const REASON_DESTROYED := "The building is destroyed"
const REASON_UNDER_CONSTRUCTION := "Under construction"
const REASON_UNKNOWN := "Can't train that here"

var queue: Array[UnitType] = []   ## Read only. Slot 1 (index 0) is the one training.

var _train_time := 0.0            # seconds trained on queue[0]
var _rally_point := Vector3.INF   # INF = default spot, see rally_point()
var _rally_node: CrystalNode = null
var _flag: Node3D


func _ready() -> void:
	super()
	_build_flag()


# ---------------------------------------------------------------- public

## The unit types this building trains, in card order.
func trainable_types() -> Array[UnitType]:
	var types: Array[UnitType] = []
	if building_type:
		for t in building_type.trains:
			if t:
				types.append(t)
		# docs/design/bowmen.md: each skirmish Hall adds its kingdom's bowman as slot 5 (key B).
		# Switch: BowmanKit.BOWMEN_ENABLED (gameplay-coder, bowmen task).
		if building_type.kind == &"barracks" and types.size() < 5:
			var bow := BowmanKit.hall_bowman(building_type)
			if bow and not types.has(bow):
				types.append(bow)
	return types


## Progress of slot 1 (0-1). 0 when the queue is empty.
func train_progress() -> float:
	if queue.is_empty() or queue[0].train_time <= 0.0:
		return 0.0
	return clampf(_train_time / queue[0].train_time, 0.0, 1.0)


## "" if `type` can be queued now, else the reason to show the player.
func can_queue(type: UnitType) -> String:
	if _dead:
		return REASON_DESTROYED
	if not is_constructed():
		return REASON_UNDER_CONSTRUCTION
	if type == null or not _trains(type):
		return REASON_UNKNOWN
	if queue.size() >= MAX_QUEUE:
		return REASON_QUEUE_FULL
	var eco := _get_economy()
	if eco == null or not eco.can_afford(type.cost):
		return REASON_NO_CRYSTALS
	if not eco.has_pop_for(type.pop):
		return REASON_POP_CAP
	return ""


## Queues `type`: its crystals and pop are reserved now. Returns "" or the reason it was refused.
func queue_unit(type: UnitType) -> String:
	var reason := can_queue(type)
	if reason == REASON_NO_CRYSTALS and _get_economy():
		_get_economy().spend(type.cost)   # fails on purpose so spend_failed fires (top bar flash)
	if reason != "":
		return reason
	var eco := _get_economy()
	eco.spend(type.cost)
	eco.reserve_pop(type.pop)
	queue.append(type)
	queue_changed.emit()
	return ""


## Cancels queue slot `slot` (0 = slot 1, the one training): full refund of crystals and pop.
## Cancelling slot 1 loses its progress.
func cancel(slot: int) -> void:
	if slot < 0 or slot >= queue.size():
		return
	var type: UnitType = queue[slot]
	queue.remove_at(slot)
	if slot == 0:
		_train_time = 0.0
	var eco := _get_economy()
	if eco:
		eco.add(type.cost)
		eco.release_pop(type.pop)
	queue_changed.emit()


func set_rally_point(pos: Vector3) -> void:
	_rally_point = Vector3(pos.x, 0.0, pos.z)
	_rally_node = null
	_update_flag()


## Gather rally: new workers start mining `node`; other units walk to it.
func set_rally_node(node: CrystalNode) -> void:
	if node == null or not is_instance_valid(node):
		return
	_rally_node = node
	_rally_point = Vector3(node.global_position.x, 0.0, node.global_position.z)
	_update_flag()


func rally_is_node() -> bool:
	return _rally_node != null and is_instance_valid(_rally_node) and not _rally_node.is_depleted()


## Where new units walk (default: the spawn corner + 4 m outward). For a gather rally: the node's spot.
func rally_point() -> Vector3:
	if _rally_point == Vector3.INF:
		return global_position + _corner_offset(_rally_distance())
	return _rally_point


## Where trained units appear.
func spawn_point() -> Vector3:
	return global_position + _corner_offset(_spawn_distance())


## Keeps and barracks take crystals once they are finished (skirmish-1v1.md).
func is_drop_off() -> bool:
	return is_alive() and is_constructed()


## Completed keeps and barracks are base shops (docs/design/items.md; range ShopStock.SHOP_RADIUS).
func is_shop() -> bool:
	return is_alive() and is_constructed()


## Item ids sold here (the base stock); every shop also combines mid / top recipes.
func shop_stock() -> Array[StringName]:
	return ShopStock.base()


## Where workers deliver crystals: the spawn corner (the keep overrides it).
func drop_off_point() -> Vector3:
	return spawn_point()


# ---------------------------------------------------------------- training

func _physics_process(delta: float) -> void:
	super(delta)
	if _dead or queue.is_empty() or not is_constructed():
		return
	_train_time += delta
	if _train_time >= queue[0].train_time:
		var type: UnitType = queue.pop_front()
		_train_time = 0.0
		_spawn(type)
		queue_changed.emit()


func _spawn(type: UnitType) -> void:
	var eco := _get_economy()
	if eco:
		eco.release_pop(type.pop)   # the living unit counts its own pop from now on
	var unit := Worker.make_unit(type)
	unit.team = team
	var parent := get_tree().current_scene if get_tree().current_scene else get_parent()
	parent.add_child(unit)
	unit.global_position = spawn_point()
	unit.command_stop()
	if rally_is_node() and unit.has_method("command_gather"):
		unit.call("command_gather", _rally_node)
	else:
		unit.command_move(rally_point())
	_call_model(&"play_training_pulse")
	unit_trained.emit(unit)


func _trains(type: UnitType) -> bool:
	for t in trainable_types():
		if t.id == type.id:
			return true
	return false


## Per-axis distance from the centre to the spawn point (footprint half-size + 1 m).
func _spawn_distance() -> float:
	return _half_size() + SPAWN_OUT


func _rally_distance() -> float:
	return _half_size() + RALLY_OUT


func _half_size() -> float:
	return building_type.size_m().x * 0.5 if building_type else 1.0


## (d, 0, d) pointing to the corner facing front_toward.
func _corner_offset(d: float) -> Vector3:
	var sx := signf(front_toward.x - global_position.x)
	var sz := signf(front_toward.z - global_position.z)
	return Vector3((sx if sx != 0.0 else 1.0) * d, 0.0, (sz if sz != 0.0 else -1.0) * d)


func _on_destroyed() -> void:
	while not queue.is_empty():
		cancel(queue.size() - 1)


func _on_selected_changed() -> void:
	_update_flag()


# ---------------------------------------------------------------- rally flag

func _process(_delta: float) -> void:
	# A gather rally on a node that ran out falls back to that spot; keep the flag in place.
	if selected and _rally_node != null and not rally_is_node():
		_rally_node = null
		_update_flag()


func _update_flag() -> void:
	if _flag == null:
		return
	_flag.visible = selected
	if not selected:
		return
	var pos := rally_point()
	if rally_is_node():
		pos = _rally_node.global_position + Vector3.UP * 1.7   # on top of the crystals
	_flag.global_position = pos


## Rally flag: a 1.2 m pole with a triangle in the kingdom colour. Visible only while selected.
func _build_flag() -> void:
	_flag = Node3D.new()
	_flag.top_level = true
	_flag.visible = false
	add_child(_flag)
	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.035
	cyl.bottom_radius = 0.045
	cyl.height = 1.2
	pole.mesh = cyl
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.35, 0.25, 0.15)
	pole.material_override = pole_mat
	pole.position.y = 0.6
	pole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flag.add_child(pole)
	var cloth := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.36, 0.5, 0.03)
	cloth.mesh = prism
	var cloth_mat := StandardMaterial3D.new()
	cloth_mat.albedo_color = team_color
	cloth_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloth_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloth.material_override = cloth_mat
	cloth.rotation.z = -PI / 2.0   # the tip points away from the pole
	cloth.position = Vector3(0.25, 1.02, 0.0)
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flag.add_child(cloth)

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
const REASON_LOCKED := "Not now"     ## MissionBase.lock_base (docs/design/mission-framework.md).
const META_LOCKED := &"mission_locked"

var queue: Array[UnitType] = []   ## Read only. Slot 1 (index 0) is the one training.

var _train_time := 0.0            # seconds trained on queue[0]
var _rally_point := Vector3.INF   # INF = default spot, see rally_point()
var _rally_node: CrystalNode = null
var _flag: Node3D
var _load_refunds: Array[Dictionary] = []   # load: queue stubs nobody could rebuild (refunded in the late phase)


func _ready() -> void:
	super()
	_build_flag()
	unit_trained.connect(_on_unit_trained_plus)


## docs/design/tiers.md 5: every unit that comes out (bowman twins too) gets the team's "+" if researched.
func _on_unit_trained_plus(unit: Unit) -> void:
	UnitUpgrades.apply_to(unit)


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
		# docs/design/new-units-12.md: 3 new units per kingdom as slots 6-8 (keys N M ,). Switch NewUnits12.ENABLED.
		if building_type.kind == &"barracks":
			for t in NewUnits12.hall_units(building_type):
				if not types.has(t):
					types.append(t)
		# docs/design/tiers.md 3: the keep's Stronghold / Citadel button, a stub type right after the worker
		# (slot 2, key X; Keep.can_queue / queue_unit start or cancel the upgrade). Switch TierSystem.ENABLED.
		if has_method(&"tier_card_type"):
			var up: Variant = call(&"tier_card_type")
			if up is UnitType:
				types.append(up)
		# t3-helpers.md (T3 agent): the keep's T3 unit, then Call / Revive helper. Switch T3Kit.ENABLED.
		for t3 in T3Kit.keep_types(self):
			if not types.has(t3):
				types.append(t3)
		# caster-units.md 3.3: the kingdom's caster (tier 2), keep slot 5 = key B. Switch CasterKit.ENABLED.
		for c in CasterKit.keep_types(self):
			if not types.has(c):
				types.append(c)
	return types


## Progress of slot 1 (0-1). 0 when the queue is empty.
func train_progress() -> float:
	if queue.is_empty() or queue[0].train_time <= 0.0:
		return 0.0
	return clampf(_train_time / queue[0].train_time, 0.0, 1.0)


## "" if `type` can be queued now, else the reason to show the player.
## True while a mission locked this building (MissionBase.lock_base): no new orders, the queue waits.
func is_locked() -> bool:
	return has_meta(META_LOCKED) and bool(get_meta(META_LOCKED))


func can_queue(type: UnitType) -> String:
	if _dead:
		return REASON_DESTROYED
	if not is_constructed():
		return REASON_UNDER_CONSTRUCTION
	if type == null or not _trains(type):
		return REASON_UNKNOWN
	if is_locked():
		return REASON_LOCKED
	var tier_gate := TierSystem.gate_reason(type.requires_tier, int(team))   # tiers.md: Stronghold / Citadel
	if tier_gate != "":
		return tier_gate
	var gate := NewUnits12.gate_reason(type, int(team))   # new-units-12.md 3: stop-gap gate, off (OWN_T2_GATE)
	if gate != "":
		return gate
	var t3_gate := T3Kit.gate_reason(type, int(team))   # t3-helpers.md 3: "Already called", essence, Saboteur cap
	if t3_gate != "":
		return t3_gate
	var caster_gate := CasterKit.gate_reason(type, int(team))   # caster-units.md 13 Q5: optional cap (off)
	if caster_gate != "":
		return caster_gate
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
	T3Kit.on_queued(type, int(team))   # t3-helpers.md: a helper call / revive pays its essence
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
	T3Kit.on_cancelled(type, int(team))   # t3-helpers.md: essence back
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
	if T3Kit.is_paused(self):   # t3-helpers.md 7.2: a Saboteur's Powder Charge stops training 10 s
		return
	if is_locked():   # MissionBase.lock_base: the queue waits
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
	if T3Kit.on_trained(self, type):   # t3-helpers.md 3: the helper walks out (HelperRoster)
		_call_model(&"play_training_pulse")
		return
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


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

func save_snapshot(ids: Dictionary) -> Dictionary:
	var d := super(ids)
	var q: Array = []
	for t in queue:
		if ForgeKit.is_stub(t):
			q.append({"forge": String(ForgeKit.stub_line(t)), "level": int(t.get_meta(&"forge_level", 1))})
		elif UnitType.find(String(t.id)) == null:
			# A code-built stub (helper Call / Revive, a Stables rank...): rebuilt by its owner on load, else refunded
			# (review R4-3), so the row keeps what was paid.
			q.append({"stub": String(t.id), "cost": t.cost, "essence": _stub_essence(t)})
		else:
			q.append({"id": String(t.id)})
	d["queue"] = q
	d["train_time"] = _train_time
	d["rally"] = _rally_point
	if _rally_node != null and is_instance_valid(_rally_node):
		d["rally_node"] = String(_rally_node.node_id)
	return d


## Restores the queue without paying (the saved crystals already paid it) and reserves its pop again.
func load_snapshot(d: Dictionary, nodes: Dictionary) -> void:
	super(d, nodes)
	var eco := _get_economy()
	for t in queue:
		if eco:
			eco.release_pop(t.pop)
	queue.clear()
	_load_refunds.clear()
	for e: Variant in d.get("queue", []):
		var row := e as Dictionary
		var t: UnitType = null
		if row.has("forge"):
			t = ForgeKit.stub(StringName(str(row["forge"])), int(row.get("level", 1)))
		elif row.has("stub"):
			t = _stub_from_save(StringName(str(row["stub"])))
			if t == null:
				_load_refunds.append(row)   # paid back in load_snapshot_late, once the saved purses are restored
				continue
		else:
			t = UnitType.find(String(row.get("id", "")))
		if t == null:
			continue
		queue.append(t)
		if eco:
			eco.reserve_pop(t.pop)
	_train_time = float(d.get("train_time", 0.0))
	var rally: Variant = d.get("rally", Vector3.INF)
	_rally_point = rally if rally is Vector3 else Vector3.INF
	_rally_node = null
	queue_changed.emit()


func load_snapshot_late(d: Dictionary, nodes: Dictionary) -> void:
	super(d, nodes)
	for row: Dictionary in _load_refunds:
		var eco := _get_economy()
		if eco and int(row.get("cost", 0)) > 0:
			eco.add(int(row["cost"]))
		var bank := EssenceBank.for_team(int(team))
		if bank and int(row.get("essence", 0)) > 0:
			bank.add(int(row["essence"]))
	_load_refunds.clear()
	var node_id := StringName(str(d.get("rally_node", "")))
	if node_id != &"":
		for n in get_tree().get_nodes_in_group(&"crystal_nodes"):
			if n is CrystalNode and (n as CrystalNode).node_id == node_id:
				_rally_node = n
	_update_flag()


## Team switch (review R4-5): the queue's reserved pop moves with the building's pop bonus.
func refresh_economy() -> void:
	var old := _get_economy()
	var held := 0
	for t in queue:
		held += t.pop
	if old and held > 0:
		old.release_pop(held)
	super()
	var eco := _get_economy()
	if eco and held > 0:
		eco.reserve_pop(held)


## A code-built queue stub by id, from the system that owns it (review R4-3): an owner's `stub_for_save(id)` when it has
## one (HelperRoster, Stables16), else the helper roster's own Call / Revive stubs. Null = nobody rebuilds it.
func _stub_from_save(id: StringName) -> UnitType:
	var owners: Array[Node] = []
	var helper_stub := id == HelperRoster.CALL_ID or id == HelperRoster.REVIVE_ID
	# Only for a helper row: its roster may not exist yet in load phase 1 (created on first use), and it is the node the
	# roster's saved_state row adopts afterwards, so here (only here) it is created.
	var roster := HelperRoster.for_team(int(team)) if helper_stub else null
	if roster:
		owners.append(roster)
	var ranks := Stables16.for_team(int(team), false)
	if ranks:
		owners.append(ranks)
	for o in owners:
		if o.has_method(&"stub_for_save"):
			var t: Variant = o.call(&"stub_for_save", id)
			if t is UnitType:
				return t as UnitType
	if roster and id == HelperRoster.CALL_ID and roster.has_method(&"call_type"):
		return roster.call(&"call_type") as UnitType
	if roster and id == HelperRoster.REVIVE_ID and roster.has_method(&"revive_type"):
		return roster.call(&"revive_type") as UnitType
	return null


## The essence a queued stub paid (helper Call / Revive), 0 otherwise: the refund when it cannot be rebuilt.
func _stub_essence(t: UnitType) -> int:
	if t.has_meta(&"essence"):
		return int(t.get_meta(&"essence"))
	if t.id != HelperRoster.CALL_ID and t.id != HelperRoster.REVIVE_ID:
		return 0
	var roster := _helper_roster()
	if roster == null:
		return 0
	return roster.call_essence() if t.id == HelperRoster.CALL_ID else roster.revive_cost()


## The team's existing HelperRoster (group lookup: never creates one), or null.
func _helper_roster() -> HelperRoster:
	if not is_inside_tree():
		return null
	for n in get_tree().get_nodes_in_group(&"helper_rosters"):
		var r := n as HelperRoster
		if r and r.team == int(team) and not r.is_queued_for_deletion():
			return r
	return null

class_name StablesBuilding
extends TrainingBuilding
## The Stables (docs/design/stables.md; kind &"stables", one per team, needs a completed Hall). Trains the kingdom's 4
## mounted units (Stables16.ROSTER, keys Z X C V; the tier gate is the units' requires_tier) and sells the two rank-3
## upgrades as stub buttons B / N (Stables16.rank_stub: queue_unit starts the research instead of training).
## Not a crystal drop-off, not a shop. Placeholder look: a long low stable + roof + paddock posts until
## art/buildings/stables/<kingdom>/ lands (BuildingType.model_path).


func _ready() -> void:
	super()
	unit_trained.connect(Stables16.apply_rank)


func trainable_types() -> Array[UnitType]:
	var types: Array[UnitType] = []
	if building_type == null or not Stables16.ENABLED:
		return types
	# A mission may reorder the Z X C V card (`stables_card` on the scene: unit ids, e.g. e2m3 puts the Emberdart
	# Harrier on V, unit-spotlights.md); ids outside the kingdom's roster are skipped.
	var order: Variant = MissionBase.scene_knob(&"stables_card", null)
	var roster := Stables16.roster_types(building_type.faction)
	if order is Array and not (order as Array).is_empty():
		var by_id := {}
		for t in roster:
			by_id[t.id] = t
		roster.clear()
		for id: Variant in order:
			if by_id.has(StringName(id)):
				roster.append(by_id[StringName(id)])
	types.append_array(roster)
	types.append_array(Stables16.rank_stubs(building_type.faction))
	return types


func can_queue(type: UnitType) -> String:
	if Stables16.is_rank_stub(type):
		if _dead:
			return REASON_DESTROYED
		if not is_constructed():
			return REASON_UNDER_CONSTRUCTION
		var bank := Stables16.for_team(int(team), false)
		var tmp_bank := bank
		if tmp_bank == null:
			tmp_bank = Stables16.new()
			tmp_bank.team = int(team)
		var r := tmp_bank.can_rank(StringName(type.get_meta(&"rank_of")), self)
		if bank == null:
			tmp_bank.free()
		return r
	return super(type)


func queue_unit(type: UnitType) -> String:
	if Stables16.is_rank_stub(type):
		var reason := can_queue(type)
		if reason != "" and reason != REASON_NO_CRYSTALS:
			return reason
		var bank := Stables16.for_team(int(team))
		if bank == null:
			return REASON_UNKNOWN
		var r := bank.rank_up(StringName(type.get_meta(&"rank_of")), self)
		if r == "":
			queue_changed.emit()
		return r
	return super(type)


## 0-1 progress of the rank research running here (-1 = none): UI / tests.
func rank_progress() -> float:
	var bank := Stables16.for_team(int(team), false)
	if bank == null or building_type == null:
		return -1.0
	for id in Stables16.rank_ids(building_type.faction):
		if bank.is_working(id):
			return bank.progress(id)
	return -1.0


func is_drop_off() -> bool:
	return false


func is_shop() -> bool:
	return false


func _build_shape() -> void:
	var body := _body_size()
	var stable := BoxMesh.new()
	stable.size = Vector3(body.x, body.y * 0.55, body.z * 0.55)
	var hall := _add_mesh(stable, building_type.body_color, body.y * 0.275)
	hall.position.z -= body.z * 0.2
	var roof := PrismMesh.new()
	roof.size = Vector3(body.x * 1.05, body.y * 0.4, body.z * 0.62)
	var r := _add_mesh(roof, team_color, body.y * 0.55 + body.y * 0.2)
	r.position.z -= body.z * 0.2
	var loft := BoxMesh.new()
	loft.size = Vector3(body.x * 0.25, body.y * 0.35, body.z * 0.25)
	var l := _add_mesh(loft, building_type.body_color.darkened(0.2), body.y * 0.9)
	l.position = Vector3(body.x * 0.3, l.position.y, -body.z * 0.2)
	for i in 5:   # paddock posts along the front
		var post := BoxMesh.new()
		post.size = Vector3(0.15, 0.9, 0.15)
		var p := _add_mesh(post, Color(0.4, 0.28, 0.16), 0.45)
		p.position = Vector3(-body.x * 0.45 + body.x * 0.225 * i, p.position.y, body.z * 0.42)
	var rail := BoxMesh.new()
	rail.size = Vector3(body.x * 0.92, 0.08, 0.08)
	var rl := _add_mesh(rail, Color(0.45, 0.32, 0.18), 0.7)
	rl.position.z = body.z * 0.42

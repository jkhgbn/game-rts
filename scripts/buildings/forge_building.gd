class_name ForgeBuilding
extends TrainingBuilding
## The Forge (docs/design/unit-upgrades.md; kind &"forge", one per team, tier 1). Its card shows the next level of each
## research line (ForgeKit.CARD, keys Z X C; the V B N unit lines moved to UnitResearch, UR.S2); the research is its
## queue: a stub UnitType queued like a unit (pay on queue, full refund on cancel or when the Forge falls), and when it
## "comes out" ForgeKit.complete raises the level.
## One level of a line in the queue at a time. Not a drop-off, not a shop, no rally flag.
## Placeholder look (anvil yard, chimney) until art/buildings/forge/<kingdom>/ lands (BuildingType.model_path).

signal research_completed(line: StringName, level: int)


func trainable_types() -> Array[UnitType]:
	var types: Array[UnitType] = []
	if building_type == null or not ForgeKit.ENABLED:
		return types
	for line in ForgeKit.card_lines(building_type.faction):
		var lv := ForgeKit.level_of(int(team), line)
		types.append(ForgeKit.stub(line, mini(lv + 1, ForgeKit.max_level(line))))
	return types


func can_queue(type: UnitType) -> String:
	if ForgeKit.is_stub(type):
		if _dead:
			return REASON_DESTROYED
		if not is_constructed():
			return REASON_UNDER_CONSTRUCTION
		var line := ForgeKit.stub_line(type)
		if ForgeKit.level_of(int(team), line) >= ForgeKit.max_level(line):
			return ForgeKit.REASON_MAX
		for q in queue:
			if ForgeKit.stub_line(q) == line:
				return ForgeKit.REASON_WORKING
	return super(type)


## The line being researched now (&"" = none) and its 0-1 progress: UI / tests.
func researching() -> StringName:
	return ForgeKit.stub_line(queue[0]) if not queue.is_empty() else &""


func _spawn(type: UnitType) -> void:
	if not ForgeKit.is_stub(type):
		super(type)
		return
	var line := ForgeKit.stub_line(type)
	var bank := ForgeKit.for_team(int(team))
	if bank:
		bank.complete(line)
	_call_model(&"play_training_pulse")
	research_completed.emit(line, ForgeKit.level_of(int(team), line))


func is_drop_off() -> bool:
	return false


func is_shop() -> bool:
	return false


## No rally flag: nothing walks out of the Forge.
func _on_selected_changed() -> void:
	pass


func _build_shape() -> void:
	var body := _body_size()
	var hall := BoxMesh.new()
	hall.size = Vector3(body.x * 0.8, body.y * 0.6, body.z * 0.7)
	var h := _add_mesh(hall, building_type.body_color, body.y * 0.3)
	h.position.z -= body.z * 0.1
	var roof := PrismMesh.new()
	roof.size = Vector3(body.x * 0.86, body.y * 0.3, body.z * 0.76)
	var r := _add_mesh(roof, team_color, body.y * 0.75)
	r.position.z -= body.z * 0.1
	var chimney := BoxMesh.new()
	chimney.size = Vector3(body.x * 0.16, body.y * 0.7, body.z * 0.16)
	var c := _add_mesh(chimney, building_type.body_color.darkened(0.35), body.y * 0.85)
	c.position.x = body.x * 0.25
	c.position.z -= body.z * 0.2
	var glow := BoxMesh.new()   # the forge mouth, kingdom colour
	glow.size = Vector3(body.x * 0.3, body.y * 0.2, 0.06)
	var g := _add_mesh(glow, building_type.color.lightened(0.3), body.y * 0.18)
	g.position.z = body.z * 0.26
	var anvil := BoxMesh.new()
	anvil.size = Vector3(0.7, 0.45, 0.35)
	var a := _add_mesh(anvil, Color(0.25, 0.25, 0.28), 0.25)
	a.position = Vector3(-body.x * 0.25, a.position.y, body.z * 0.4)

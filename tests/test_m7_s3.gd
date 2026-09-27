extends SceneTree
## Task M7.S3: campaign save + mission flow (docs/design/mission-01.md "Reward carried to mission 2").
## A fake mission 1 victory (stub level: hero with a real Inventory, an EssenceBank, objective states)
## saves the Ember Crown, the 6 slots, 50 % essence (+300 for sec_outpost, cap 1 500) and the flags;
## a fresh CampaignState.open() then applies them to a "mission 2" start stub.
## Backs up and restores user://campaign.json.
## Run:  godot --headless --path . -s tests/test_m7_s3.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "m7.s3"
const SAVE := "user://campaign.json"

const LEVEL_SRC := "extends Node3D\nvar hero: Node3D\nvar objective_states := {}\n"
const HERO_SRC := "extends Node3D\nvar team: int = 0\nvar inventory: Node\nvar mods := {}\n" \
		+ "func add_modifier(id: StringName, s: Dictionary) -> void:\n\tmods[id] = s\n" \
		+ "func remove_modifier(id: StringName) -> void:\n\tmods.erase(id)\n" \
		+ "func is_alive() -> bool:\n\treturn true\n"

var _errors: Array[String] = []
var _backup: Variant = null
var _frame := 0


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:
		return false
	_backup_save()
	_run()
	_restore_save()
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


func _run() -> void:
	var CS: Script = load("res://scripts/campaign/campaign_state.gd")
	# --- fresh campaign
	var cs: Object = CS.call(&"open")
	cs.call(&"reset")
	if cs.call(&"unlocked_missions") != [&"m01"]:
		_errors.append("fresh unlocked %s" % str(cs.call(&"unlocked_missions")))
	if CS.call(&"mission_scene", &"m01") != "res://missions/mission_01.tscn":
		_errors.append("mission_scene(m01) wrong")
	# --- mission 1 victory stub
	var level := _make_level("Mission1Stub")
	var hero: Node3D = level.get(&"hero")
	var inv: Node = _inventory(hero)
	_add(inv, &"blazing_edge", 1)
	_add(inv, &"ember_draught", 2)
	_add(inv, &"vital_root", 1)
	_add(inv, &"ember_crown", 1)   # worn from E7 as the artifact item
	var bank: Node = _bank(level)
	bank.set(&"trickle_enabled", false)
	bank.set(&"essence", 1100)
	level.set(&"objective_states", {"sec_peddler": "done", "sec_outpost": "done", "obj_hold": "done"})
	if cs.call(&"on_mission_victory", &"m01", level) != OK:
		_errors.append("victory save failed")
	level.free()
	if not FileAccess.file_exists(SAVE):
		_errors.append("no user://campaign.json")
		return
	# --- a fresh load, applied to a mission 2 start stub
	var loaded: Object = CS.call(&"open")
	var unlocked: Array = loaded.call(&"unlocked_missions")
	if not unlocked.has(&"m01") or not unlocked.has(&"m02"):
		_errors.append("unlocked %s" % str(unlocked))
	if not loaded.call(&"is_completed", &"m01"):
		_errors.append("m01 not completed")
	if not loaded.call(&"flag", "m1_peddler_freed") or not loaded.call(&"flag", "m1_outpost_burned"):
		_errors.append("flags %s" % str(loaded.get(&"flags")))
	if int(loaded.call(&"carried_essence")) != 700:   # (1100 + 300) * 50 %
		_errors.append("carried essence %d, want 700" % int(loaded.call(&"carried_essence")))
	if not (loaded.call(&"owned_artifacts") as Array).has("ember_crown"):
		_errors.append("crown not owned")
	if str((loaded.call(&"equipped_artifacts") as Array)[0]) != "ember_crown":
		_errors.append("crown not in artifact slot 1")
	var m2 := _make_level("Mission2Stub")
	var hero2: Node3D = m2.get(&"hero")
	var bank2: Node = _bank(m2)
	bank2.set(&"trickle_enabled", false)
	var start_essence := int(bank2.get(&"essence"))
	if not loaded.call(&"apply_to_start", m2):
		_errors.append("apply_to_start returned false")
	var inv2: Node = _inventory(hero2)
	var ids: Array = []
	for e: Variant in inv2.get(&"slots"):
		ids.append(String((e["type"] as Resource).get(&"id")) + "x%d" % int(e["count"]) if e is Dictionary else "-")
	if ids != ["blazing_edgex1", "ember_draughtx2", "vital_rootx1", "-", "-", "-"]:
		_errors.append("mission 2 slots %s" % str(ids))
	var arts: Array = inv2.get(&"artifacts")
	if not (arts[0] is Dictionary) or String((arts[0]["type"] as Resource).get(&"id")) != "ember_crown":
		_errors.append("mission 2 artifact slot 1 %s" % str(arts))
	var mods: Dictionary = hero2.get(&"mods")
	if not mods.has(&"item:artifact_1") or float((mods[&"item:artifact_1"] as Dictionary).get(&"max_hp", 0.0)) != 100.0:
		_errors.append("crown modifier not applied %s" % str(mods))
	if int(bank2.get(&"essence")) != start_essence + 700:
		_errors.append("mission 2 essence %d, want %d" % [int(bank2.get(&"essence")), start_essence + 700])
	if not (m2.get_meta(&"campaign_flags", {}) as Dictionary).get("m1_outpost_burned", false):
		_errors.append("flags not on the mission 2 node")
	m2.free()
	# --- the cap: 5000 essence -> 1500; no outpost -> flag false
	var level3 := _make_level("CapStub")
	var bank3: Node = _bank(level3)
	bank3.set(&"trickle_enabled", false)
	bank3.set(&"essence", 5000)
	level3.set(&"objective_states", {"sec_peddler": "done"})
	loaded.call(&"on_mission_victory", &"m01", level3)
	level3.free()
	var capped: Object = CS.call(&"open")
	if int(capped.call(&"carried_essence")) != 1500 or capped.call(&"flag", "m1_outpost_burned"):
		_errors.append("cap / flag replay wrong: %d" % int(capped.call(&"carried_essence")))
	if (capped.call(&"owned_artifacts") as Array).count("ember_crown") != 1:
		_errors.append("crown duplicated in owned")


func _make_level(level_name: String) -> Node3D:
	var ls := GDScript.new()
	ls.source_code = LEVEL_SRC
	ls.reload()
	var hs := GDScript.new()
	hs.source_code = HERO_SRC
	hs.reload()
	var level: Node3D = ls.new()
	level.name = level_name
	var hero: Node3D = hs.new()
	hero.name = "Hero"
	level.add_child(hero)
	level.set(&"hero", hero)
	root.add_child(level)
	current_scene = level
	hero.add_to_group("heroes")
	return level


func _inventory(hero: Node) -> Node:
	var inv: Node = hero.get_node_or_null(^"Inventory")
	if inv == null:
		var s: Script = load("res://scripts/items/inventory.gd")
		inv = s.call(&"ensure_for", hero)
	return inv


func _add(inv: Node, id: StringName, count: int) -> void:
	var t: Resource = load("res://data/items/%s.tres" % id)
	if t == null or not inv.call(&"add_item", t, count):
		_errors.append("could not add %s" % id)


func _bank(level: Node) -> Node:
	for n in get_nodes_in_group("essence_banks"):
		if level.is_ancestor_of(n) and int(n.get(&"team")) == 0:
			return n
	var s: Script = load("res://scripts/items/essence_bank.gd")
	var b: Node = s.new()
	b.set(&"team", 0)
	b.name = "EssenceBank0"
	b.add_to_group("essence_banks")
	level.add_child(b)
	return b


func _backup_save() -> void:
	if FileAccess.file_exists(SAVE):
		_backup = FileAccess.get_file_as_bytes(SAVE)


func _restore_save() -> void:
	if _backup is PackedByteArray:
		var f := FileAccess.open(SAVE, FileAccess.WRITE)
		f.store_buffer(_backup)
		f.close()
	elif FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

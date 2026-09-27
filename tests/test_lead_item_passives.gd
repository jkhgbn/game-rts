extends SceneTree
## Lead integration check: an item with a passive attaches it through ItemPassives, selling detaches it.
## Run: godot --headless --path . -s tests/test_lead_item_passives.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "lead_item_passives"

var main: Node
var frame := 0
var _wait := 0


func _initialize() -> void:
	main = load("res://scenes/skirmish.tscn").instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: map never ready" % TASK_ID)
			return true
		return false
	frame += 1
	if frame < 10:
		return false
	var hero: Node = main.hero
	var inv: Node = hero.get("inventory")
	if inv == null:
		print("FAIL %s: hero has no inventory" % TASK_ID)
		return true
	# Find any item that has a passive.
	var item_type_script: Script = load("res://scripts/items/item_type.gd")
	var chosen: Resource = null
	for f in DirAccess.get_files_at("res://data/items"):
		if not f.ends_with(".tres"):
			continue
		var t: Resource = load("res://data/items/" + f)
		if t and str(t.get(&"passive_id")) != "" and not bool(t.get(&"is_artifact")):
			chosen = t
			break
	if chosen == null:
		print("FAIL %s: no item with a passive in data/items" % TASK_ID)
		return true
	var passives: Script = load("res://scripts/units/item_passives.gd")
	if not inv.call(&"add_item", chosen):
		print("FAIL %s: add_item refused %s" % [TASK_ID, chosen.get(&"id")])
		return true
	var active: Variant = passives.call(&"active_ids", hero)
	var got := str(active)
	if got == "[]" or got == "":
		print("FAIL %s: passive of %s not attached (active_ids=%s)" % [TASK_ID, chosen.get(&"id"), got])
		return true
	inv.call(&"remove_item", 0)
	var after := str(passives.call(&"active_ids", hero))
	if after != "[]" and after != "":
		print("FAIL %s: passive still attached after removal (%s)" % [TASK_ID, after])
		return true
	print("PASS %s (%s -> %s)" % [TASK_ID, chosen.get(&"id"), got])
	return true

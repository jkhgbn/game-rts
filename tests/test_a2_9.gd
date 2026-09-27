extends SceneTree
## Task A2.9: champion portraits + 12 ability icons.
## Run:  godot --headless --path . -s tests/test_a2_9.gd --fixed-fps 60 --quit-after 600
## Checks: the 16 PNGs exist and are imported, load as Texture2D 128 x 128, are not blank, and the champion UI
## (ChampionBar.Face used by the bar + tavern rows, SelectionPanel.AbilitySlot) shows them instead of the initials.

const TASK_ID := "a2.9"
const CHAMPIONS: Array[StringName] = [&"wayfinder", &"oathwall", &"coin_cutter", &"mender"]
const ABILITIES: Array[StringName] = [&"flare_arrow", &"snare_line", &"trailblaze", &"oath_of_iron", &"shield_bash",
	&"bulwark_stand", &"cutpurse", &"smoke_pouch", &"marked_for_coin", &"mending_draught", &"soothing_circle", &"lifeline"]

var _fails: Array[String] = []
var _frame := 0
var _nodes: Array[Node] = []


func _initialize() -> void:
	var paths: Array[String] = []
	for id in CHAMPIONS:
		paths.append("res://art/icons/units/%s.png" % id)
	for id in ABILITIES:
		paths.append("res://art/icons/abilities/%s.png" % id)
	for p in paths:
		_check_file(p)
	print("checked %d icon files" % paths.size())
	_check_library()


func _check_file(p: String) -> void:
	if not FileAccess.file_exists(p):
		_fails.append("missing " + p)
		return
	if not ResourceLoader.exists(p):
		_fails.append("not imported " + p)
		return
	var t := load(p) as Texture2D
	if t == null:
		_fails.append("not a Texture2D " + p)
		return
	if t.get_width() != 128 or t.get_height() != 128:
		_fails.append("%s is %dx%d, want 128x128" % [p, t.get_width(), t.get_height()])
	var img: Image = t.get_image()
	if img == null or img.is_empty():
		_fails.append("no image data " + p)
		return
	if img.is_compressed():
		img.decompress()
	# Not blank: luminance must vary (a painted emblem / rendered bust, not a flat fill).
	var lo := 1.0
	var hi := 0.0
	for y in range(0, 128, 4):
		for x in range(0, 128, 4):
			var l: float = img.get_pixel(x, y).get_luminance()
			lo = minf(lo, l)
			hi = maxf(hi, l)
	if hi - lo < 0.3:
		_fails.append("%s looks blank (luminance %.2f-%.2f)" % [p, lo, hi])


func _check_library() -> void:
	var lib: Script = load("res://art/icons/icon_library.gd")
	for id in CHAMPIONS:
		if lib.call(&"icon_for", &"units", id) == null:
			_fails.append("IconLibrary.icon_for(units, %s) is null" % id)
	for id in ABILITIES:
		if lib.call(&"icon_for", &"abilities", id) == null:
			_fails.append("IconLibrary.icon_for(abilities, %s) is null" % id)
		if lib.call(&"icon_for", &"ability", id) == null:
			_fails.append("IconLibrary alias 'ability' fails for %s" % id)


func _check_ui() -> void:
	var bar: Script = load("res://scripts/ui/champion_bar.gd")
	var panel: Script = load("res://scripts/ui/selection_panel.gd")
	if bar == null or panel == null:
		_fails.append("champion UI scripts missing")
		return
	for id in CHAMPIONS:
		if bar.call(&"icon_of", id) == null:
			_fails.append("ChampionBar.icon_of(%s) is null" % id)
	for id in ABILITIES:
		if panel.call(&"ability_icon", id) == null:
			_fails.append("SelectionPanel.ability_icon(%s) is null" % id)
	# The real widgets: the portrait face (bar slot + tavern row tile) and the inspect ability slot.
	var face_cls: Variant = bar.get(&"Face")
	var slot_cls: Variant = panel.get(&"AbilitySlot")
	if face_cls == null or slot_cls == null:
		_fails.append("ChampionBar.Face / SelectionPanel.AbilitySlot not found")
		return
	for id in CHAMPIONS:
		var f: Control = face_cls.new()
		f.size = Vector2(56, 56)
		f.set_meta(&"test_id", id)
		root.add_child(f)
		_nodes.append(f)
	for id in ABILITIES:
		var s: Control = slot_cls.new()
		s.set_meta(&"test_id", id)
		root.add_child(s)
		_nodes.append(s)


func _fill_ui() -> void:
	for n in _nodes:
		var id: StringName = n.get_meta(&"test_id")
		if n.has_method(&"set_face"):
			n.call(&"set_face", id, "Test Name", false)
		else:
			n.call(&"show_ability", id, true, 0.0, 10.0, 4)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_check_ui()   # root is in the tree now: the widgets get _ready
	if _frame == 2:
		_fill_ui()
	if _frame < 4:
		return false
	for n in _nodes:
		if n.has_method(&"is_placeholder"):
			if bool(n.call(&"is_placeholder")):
				_fails.append("Face %s still shows initials '%s'" % [n.get(&"champion_id"), n.call(&"letters")])
		else:
			var icon: TextureRect = n.get(&"icon")
			var abbrev: Label = n.get(&"abbrev")
			if icon == null or icon.texture == null or (abbrev != null and abbrev.text != ""):
				_fails.append("AbilitySlot %s has no icon" % n.get(&"ability_id"))
	print("UI widgets checked: %d" % _nodes.size())
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  " + f)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _fails.size()])
	quit()
	return true

extends SceneTree
## Test for 1.U1 (top bar): placement (top centre, 320 x 40, 8 px from the top), crystals and
## "12 / 20" at start, updates on Economy.changed, pop red at the cap, failed spend flashes the
## crystal number red for 0.4 s and shows "Not enough crystals".
## Run:  godot --headless --path . -s tests/test_1_u1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "1.u1"
const TIMEOUT_FRAMES := 300
const WARN := Color(0.95, 0.35, 0.3)

var main: Node
var bar: Node
var eco: Node
var frame := 0
var _wait := 0
var _error := ""
var _done := false
var _saved_cap := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:   # the map is ready when the hero has spawned
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	_step()
	if _error != "":
		print("FAIL %s: %s" % [TASK_ID, _error])
		return true
	if _done:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _step() -> void:
	match frame:
		20:
			bar = main.hud.top_bar
			if bar == null:
				_error = "GameHUD has no top_bar"
				return
			for e in root.get_tree().get_nodes_in_group("economies"):
				if int(e.team) == 0:
					eco = e
			if eco == null:
				_error = "no player Economy in group 'economies' (systems-coder's 1.S1)"
				return
			if bar.economy != eco:
				_error = "top bar did not find the player's economy"
				return
			# Layout: centred, 8 px from the top, 320 x 40 (+100 wide with essence, 4.U1a).
			var rect: Rect2 = bar.get_global_rect()
			var screen: Vector2 = root.get_visible_rect().size
			var w := 320.0 + (100.0 if bar.get("essence_bank") != null else 0.0)
			var expected := Vector2(screen.x * 0.5 - w * 0.5, 8.0)
			if rect.position.distance_to(expected) > 1.5 or rect.size.distance_to(Vector2(w, 40)) > 1.5:
				_error = "top bar at %s, expected %s size %d x 40" % [rect, expected, int(w)]
				return
			# Start values.
			if bar.crystals_label.text != str(eco.crystals):
				_error = "crystals show '%s', economy has %d" % [bar.crystals_label.text, eco.crystals]
				return
			if bar.pop_label.text != "12 / 20":
				_error = "pop shows '%s' at start, expected '12 / 20'" % bar.pop_label.text
				return
			if _color(bar.pop_label).is_equal_approx(WARN):
				_error = "pop is red below the cap"
				return
			# Economy.changed updates the numbers.
			eco.add(35)
			if bar.crystals_label.text != str(eco.crystals):
				_error = "crystals did not update on changed ('%s' vs %d)" % [bar.crystals_label.text, eco.crystals]
				return
			# At the cap: red.
			_saved_cap = eco.pop_cap
			eco.pop_cap = eco.pop_used
			eco.changed.emit()
			if not _color(bar.pop_label).is_equal_approx(WARN):
				_error = "pop not red at the cap (%s)" % bar.pop_label.text
				return
			eco.pop_cap = _saved_cap
			eco.changed.emit()
			if _color(bar.pop_label).is_equal_approx(WARN):
				_error = "pop stayed red after leaving the cap"
				return
			# Failed spend: red flash + message.
			if eco.spend(999999):
				_error = "spend(999999) succeeded?"
				return
			if not bar.is_flashing() or not _color(bar.crystals_label).is_equal_approx(WARN):
				_error = "failed spend did not flash the crystals red"
				return
			if not _hud_shows("Not enough crystals"):
				_error = "failed spend did not show 'Not enough crystals'"
				return
		36:
			# 16 frames (0.27 s) later: still red.
			if not bar.is_flashing():
				_error = "flash ended before 0.4 s"
		50:
			# 30 frames (0.5 s): back to the normal colour.
			if bar.is_flashing() or _color(bar.crystals_label).is_equal_approx(WARN):
				_error = "flash still on after 0.5 s"
				return
			_done = true


func _color(label: Label) -> Color:
	return label.get_theme_color("font_color")


func _hud_shows(text: String) -> bool:
	for node in main.hud.find_children("*", "Label", true, false):
		if (node as Label).text.contains(text):
			return true
	return false

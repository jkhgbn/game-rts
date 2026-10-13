class_name MissionHud
extends CanvasLayer
## Campaign UI (task M7.U1): objectives panel (top-left), dialogue box (bottom-centre) and the briefing screen.
## Create it from the mission scene script, once the GameHUD exists:
##     MissionHud.attach(self, mission_node, hud)
## `mission_node` answers `briefing() -> Dictionary` and/or `objectives() -> Array` (both optional, checked with
## has_method; formats in briefing_screen.gd / objectives_panel.gd). The briefing pauses the tree; `begun` fires
## when the player presses Begin (at once when there is no briefing). Dialogue lines emitted while the briefing is
## up wait in the queue (the box is paused with the game).

signal begun

var objectives_panel: ObjectivesPanel
var dialogue_box: DialogueBox
var briefing: BriefingScreen   ## null once closed (or if the mission has no briefing()).
var mission: Node
var _hud: Node


## Adds a MissionHud to `level`. `hud` (the GameHUD) gets its skirmish objective hidden when the mission has
## objectives(). Shows the briefing when the mission has briefing() and `show_briefing` (false: a mission rebuilt by a
## save load gets its objectives / dialogue / spotlight without the briefing; `begun` still fires, deferred).
static func attach(level: Node, mission_node: Node = null, hud: Node = null, show_briefing := true) -> MissionHud:
	var m := MissionHud.new()
	m.mission = mission_node if mission_node != null else level
	m._hud = hud if hud != null else level.get(&"hud") as Node
	m._show_briefing = show_briefing
	level.add_child(m)
	return m


var _show_briefing := true


func _init() -> void:
	name = "MissionHud"
	layer = 2   # over the GameHUD (layer 1), under the briefing (80) and the pause menu (90)


func _ready() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIStyle.hud_theme()
	add_child(root)
	dialogue_box = DialogueBox.new()
	root.add_child(dialogue_box)
	if ResourceLoader.exists("res://scripts/ui/voice_player.gd"):   # Voice Forge: speaks lines that have a WAV, else silent
		dialogue_box.add_child((load("res://scripts/ui/voice_player.gd") as Script).new())
	if mission and mission.has_method(&"objectives"):
		objectives_panel = ObjectivesPanel.new()
		root.add_child(objectives_panel)
		objectives_panel.setup(mission)
		_hide_skirmish_objective()
	if _show_briefing and mission and mission.has_method(&"briefing"):
		var data: Variant = mission.call(&"briefing")
		if data is Dictionary and not (data as Dictionary).is_empty():
			briefing = BriefingScreen.new()
			add_child(briefing)
			briefing.begun.connect(_on_briefing_begun)
			briefing.open(data, mission)
			return
	_on_briefing_begun.call_deferred()


func is_briefing_open() -> bool:
	return briefing != null and is_instance_valid(briefing)


func _on_briefing_begun() -> void:
	briefing = null
	begun.emit()
	if not _pending_spotlight.is_empty():
		var data := _pending_spotlight
		_pending_spotlight = {}
		show_spotlight(data)


var spotlight_card: SpotlightCard   ## The spotlight card on screen (null when none).
var _pending_spotlight: Dictionary = {}


## The mission's unit spotlight card ({id, card, key_hint, short}) under the objectives panel; waits for the briefing.
func show_spotlight(data: Dictionary) -> void:
	if is_briefing_open() or not is_node_ready():
		_pending_spotlight = data
		return
	if spotlight_card and is_instance_valid(spotlight_card):
		spotlight_card.queue_free()
	spotlight_card = SpotlightCard.new()
	spotlight_card.setup(data)
	var parent: Node = get_node_or_null(^"Root")
	if parent == null:
		parent = self
	parent.add_child(spotlight_card)
	_place_spotlight()


## Under the objectives panel, and under the keep's tier chip when the chip sits in that column (a map-fill mission:
## the strip takes the chip's top-bar spot); re-placed every frame while the card shows (both can change height).
func _place_spotlight() -> void:
	if spotlight_card == null or not is_instance_valid(spotlight_card):
		return
	var y := 36.0
	if objectives_panel and is_instance_valid(objectives_panel):
		y = objectives_panel.position.y + objectives_panel.size.y + 10.0
	var chip: Variant = _hud.get(&"tier_chip") if _hud != null and is_instance_valid(_hud) and &"tier_chip" in _hud else null
	if chip is Control and is_instance_valid(chip) and (chip as Control).is_visible_in_tree() \
			and StringName(str((chip as Control).get(&"placement"))) == &"left_column":
		y = maxf(y, (chip as Control).get_global_rect().end.y + 8.0)
	var x := 8.0
	# The champion slots (F5-F7) sit in the same left column below: a card reaching them moves to their right.
	var bar: Variant = _hud.get(&"champion_bar") if _hud != null and is_instance_valid(_hud) and &"champion_bar" in _hud else null
	if bar is Control and is_instance_valid(bar) and (bar as Control).is_visible_in_tree():
		var br := (bar as Control).get_global_rect()
		var card := Rect2(Vector2(x, y), spotlight_card.size)
		if br.has_area() and card.intersects(br):
			x = br.end.x + 8.0
	spotlight_card.position = Vector2(x, y)


func _process(_delta: float) -> void:
	_place_spotlight()


func _hide_skirmish_objective() -> void:
	if _hud == null or not is_instance_valid(_hud):
		return
	if _hud.has_method(&"set_objective_visible"):
		_hud.call(&"set_objective_visible", false)
	elif _hud.has_method(&"set_objective"):
		_hud.call(&"set_objective", "")
	# The skirmish "Next: ..." hint moves to (16, 16) once the skirmish objective hides, i.e. under this objectives
	# panel (a faint second text behind its first rows, 2026-10-06 spotlight check): missions give their own hints.
	var nh: Variant = _hud.get(&"next_step_hint")
	if nh is CanvasItem and is_instance_valid(nh):
		(nh as CanvasItem).visible = false
		(nh as Node).process_mode = Node.PROCESS_MODE_DISABLED

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
## objectives(). Shows the briefing when the mission has briefing().
static func attach(level: Node, mission_node: Node = null, hud: Node = null) -> MissionHud:
	var m := MissionHud.new()
	m.mission = mission_node if mission_node != null else level
	m._hud = hud if hud != null else level.get(&"hud") as Node
	level.add_child(m)
	return m


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
	if mission and mission.has_method(&"briefing"):
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
	var y := 16.0
	if objectives_panel and is_instance_valid(objectives_panel):
		y = objectives_panel.position.y + objectives_panel.size.y + 10.0
	spotlight_card.position = Vector2(16.0, y)


func _hide_skirmish_objective() -> void:
	if _hud == null or not is_instance_valid(_hud):
		return
	if _hud.has_method(&"set_objective_visible"):
		_hud.call(&"set_objective_visible", false)
	elif _hud.has_method(&"set_objective"):
		_hud.call(&"set_objective", "")

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


func _hide_skirmish_objective() -> void:
	if _hud == null or not is_instance_valid(_hud):
		return
	if _hud.has_method(&"set_objective_visible"):
		_hud.call(&"set_objective_visible", false)
	elif _hud.has_method(&"set_objective"):
		_hud.call(&"set_objective", "")

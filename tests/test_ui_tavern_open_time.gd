extends SceneTree
## The tavern's opening time on the HUD comes from the taverns, not a 2:00 constant (fix 2026-10-04): mission 3's
## Crooked Lantern opens at 0:30, so during its first 30 s the champion bar's empty slots and the tavern window say
## "0:30"; ChampionBar.opens_at_text reads the earliest tavern open_time (OPENS_AT 2:00 without a tavern).
## Run: godot --headless --path . -s tests/test_ui_tavern_open_time.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "ui_tavern_open_time"
const SCENE := "res://missions/mission_03.tscn"

var h := MissionHarness.new()
var main: Node
var _wait := 0


func _initialize() -> void:
	h.task_id = TASK_ID
	main = h.open(self, SCENE, {"difficulty": 1, "set": {"campaign_save_path": "user://test_ui_tavern_none.json"}})
	h.steps.add("static text", _static, 10)
	h.steps.add("bake settles", func() -> bool:
		_wait += 1
		return _wait > 30, 3000)
	h.steps.add("mission 3 HUD says 0:30", _mission_hud, 10)


func _static() -> bool:
	var lone := Node.new()   # outside the tree: the fallback
	h.check(ChampionBar.opens_at_text(lone) == "2:00", "a node outside the tree gives 2:00")
	lone.free()
	return true


func _mission_hud() -> bool:
	var taverns := get_nodes_in_group(&"taverns")
	h.check(not taverns.is_empty(), "mission 3 has a tavern")
	h.check(ChampionBar.opens_at_text(main) == "0:30", "opens_at_text says %s, not 0:30" % ChampionBar.opens_at_text(main))
	var hud: Node = main.get(&"hud")
	var bar: ChampionBar = hud.get(&"champion_bar") if hud else null
	var win: TavernWindow = hud.get(&"tavern_window") if hud else null
	h.check(bar != null and win != null, "mission 3 HUD has the champion bar and the tavern window")
	if bar == null or win == null:
		return true
	var open_now := false
	for t: Node in taverns:
		open_now = open_now or bool(t.call(&"is_open"))
	h.check(not open_now, "the tavern is still closed at the start")
	bar.slots[0].show_empty(false)
	var lbl := String(bar.slots[0].tavern_label.text)
	h.check(lbl == "Tavern opens at 0:30", "champion slot says '%s'" % lbl)
	h.check(String(bar.slots[0].tooltip_text).contains("Tavern opens at 0:30"), "slot tooltip: %s" % bar.slots[0].tooltip_text)
	win.refresh()
	h.check(String(win.footer.text).contains("Tavern opens at 0:30"), "window footer: %s" % win.footer.text)
	h.check(String(win.closed_label.text) == "The tavern opens at 0:30", "window closed line: %s" % win.closed_label.text)
	return true


func _process(_d: float) -> bool:
	return h.tick()

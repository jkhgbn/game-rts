extends SceneTree
## Windowed look check of the SpotlightCard (mission-framework.md 7): opens a mission with its MissionHud, closes the
## briefing, shows the card (full and short) and saves screenshots per resolution and language.
## Run (windowed): tools/godot_run.ps1 --path . -s tests/shot_spotlight.gd --quit-after 20000 '--' res=1600x900 lang=fr
##   out=<abs folder> mission=res://missions/mission_e2_02.tscn id=ashveil_saboteur
## Prints SHOT <path> per image and the card's rect / label line count.

var out_dir := "user://shots"
var res := Vector2i(1600, 900)
var lang := "en"
var mission_path := "res://missions/mission_e2_02.tscn"
var unit_id := &"ashveil_saboteur"
var main: Node
var _frame := 0
var _phase := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() != 2:
			continue
		match kv[0]:
			"res":
				var p := kv[1].split("x")
				res = Vector2i(int(p[0]), int(p[1]))
			"lang":
				lang = kv[1]
			"out":
				out_dir = kv[1]
			"mission":
				mission_path = kv[1]
			"id":
				unit_id = StringName(kv[1])
	if lang != "en":
		Loc.set_language(lang)
	DisplayServer.window_set_size(res)
	root.size = res
	DirAccess.make_dir_recursive_absolute(out_dir)
	var scene := load(mission_path) as PackedScene
	main = scene.instantiate()
	main.set(&"save_campaign_on_victory", false)
	main.set(&"cinematics_enabled", false)
	main.set(&"campaign_save_path", "user://shot_spotlight_none.json")
	root.add_child(main)
	current_scene = main


func _process(_d: float) -> bool:
	_frame += 1
	var mh: Node = main.get(&"mission_hud") if main else null
	match _phase:
		0:
			if mh != null and mh.get(&"briefing") != null:
				_shot("briefing")
				(mh.get(&"briefing") as Node).call(&"begin")
				_phase = 1
				_frame = 0
			elif _frame > 3000:
				print("SHOT FAIL: no MissionHud")
				return true
		1:
			if _frame == 30:
				var cfg: MissionConfig = main.get(&"config")
				var card := String(cfg.spotlight.get("card", "")) if cfg else ""
				mh.call(&"show_spotlight", {"id": unit_id, "card": card, "key_hint": String(cfg.spotlight.get("key_hint", "")), "short": false})
			if _frame == 60:
				_report(mh)
				_shot("card_full")
				mh.call(&"show_spotlight", {"id": unit_id, "card": "Ashveil Saboteur: you have seen it before.", "short": true})
			if _frame == 90:
				_report(mh)
				_shot("card_short")
				return true
	return false


func _report(mh: Node) -> void:
	var c := mh.get(&"spotlight_card") as Control
	if c == null:
		print("SHOT card: none")
		return
	var lbl := c.get(&"card_label") as Label
	print("SHOT card rect %s (viewport %s), label lines %d, text '%s'" % [c.get_global_rect(), res,
			lbl.get_line_count() if lbl else -1, lbl.text if lbl else ""])
	var op := mh.get(&"objectives_panel") as Control
	if op:
		print("SHOT objectives rect %s" % op.get_global_rect())


func _shot(tag: String) -> void:
	var img := root.get_texture().get_image()
	var path := "%s/spotlight_%dx%d_%s_%s.png" % [out_dir, res.x, res.y, lang, tag]
	img.save_png(path)
	print("SHOT %s" % path)

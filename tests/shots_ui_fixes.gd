extends SceneTree
## Windowed screenshot pass for the 2026-10-04 HUD fixes (not a CI test): mission 2 on its snow with the gold hint
## line up, Vessa selected with an artifact equipped and a spell point to spend (artifact slot vs "+1 point" chip),
## and the keys panel (mission keys only). PNGs to user://shots_ui_fixes/<tag>_*.png.
## Run (windowed):  godot --path . -s tests/shots_ui_fixes.gd --fixed-fps 60 --quit-after 6000 -- tag=after

const SCENE := "res://missions/mission_02.tscn"
const OUT := "user://shots_ui_fixes"

var h := MissionHarness.new()
var main: Node
var _wait := 0
var _tag := "shot"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("tag="):
			_tag = a.substr(4)
	h.task_id = "shots_ui_fixes"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	main = h.open(self, SCENE, {"difficulty": 1, "set": {"campaign_save_path": "user://shots_ui_none.json"}})
	h.steps.add("settle", func() -> bool: return _frames(60), 200)
	h.steps.add("set up", func() -> bool:
		var hero: Node = main.get(&"hero")
		main.camera_rig.focus_on((hero as Node3D).global_position + Vector3(6, 0, 6))
		var inv: Node = hero.get(&"inventory")
		var art := ItemType.find(&"stillwater_orb")
		if inv != null and art != null:
			inv.call(&"add_item", art)
		hero.set(&"spell_points", 1)
		if hero.has_signal(&"spell_points_changed"):
			hero.emit_signal(&"spell_points_changed", 1)
		main.selection.select_units([hero])
		main.hud.show_message("Gather crystals and grow your army: the dig starts at 2:00", 10.0)
		return true, 5)
	h.steps.add("wait", func() -> bool: return _frames(30), 100)
	h.steps.add("shot", func() -> bool:
		var img := get_root().get_texture().get_image()
		var path := "%s/%s_m2_hud.png" % [OUT, _tag]
		img.save_png(path)
		print("shot ", ProjectSettings.globalize_path(path))
		return true, 5)


func _frames(n: int) -> bool:
	_wait += 1
	if _wait >= n:
		_wait = 0
		return true
	return false


func _process(_d: float) -> bool:
	return h.tick()

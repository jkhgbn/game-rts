extends "res://art/icons/render_icons.gd"
## Unit icons only, with render_icons.gd's pipeline (128 x 128, 3/4 view over the kingdom background):
##   art/icons/units/<id>.png for every data/units/<id>.tres whose model exists (UnitType.model_scene, else
##   art/units/<group>/<id>.tscn or art/units/<group>/<id>/<id>.tscn), and a contact sheet of EVERY unit icon on disk
##   (docs/art/icons/unit_icons_sheet.png: 128 / 56 / 32 px per icon).
## Default: renders only the Unit Guide units (data/ui/unit_guide.json) that have no icon yet. Must run WINDOWED (needs the renderer):
##   tools\godot_run.ps1 --path . --script art/icons/render_unit_icons.gd --fixed-fps 60 --quit-after 9000
## then `--headless --path . --import` so Godot imports the new PNGs.
## User args (after `--`; from PowerShell write it quoted, `'--'`, or PowerShell drops it): `all` (re-render every unit that has a model; wizards / champions / trade units keep their
## own renderers), `ids=a,b` (only those), `frame=<id>:<cy>,<r>,<yaw>,<w>,<pitch>[,<dx>,<dz>]` (try a framing without
## editing UNIT_FRAMING), `sheet=res://...` (where the sheet goes).

const UNIT_SHEET := "res://docs/art/icons/unit_icons_sheet.png"
## The default run renders the Unit Guide's units (the player-facing roster) that have no icon yet.
const GUIDE_JSON := "res://data/ui/unit_guide.json"
## Per-unit framing lives in render_icons.gd UNIT_FRAMING (shared with a full render_icons.gd run).

var _render_all: bool = false


func _initialize() -> void:
	_only_kinds.assign(["units"])
	_sheet_override = UNIT_SHEET
	for a in OS.get_cmdline_user_args():
		if a == "all":
			_render_all = true
		elif a.begins_with("ids="):
			_only_ids.assign(a.trim_prefix("ids=").split(",", false))
		elif a.begins_with("sheet="):
			_sheet_override = a.trim_prefix("sheet=")
		elif a.begins_with("frame="):
			var kv: PackedStringArray = a.trim_prefix("frame=").split(":")
			var nums: Array = []
			for s in kv[1].split(","):
				nums.append(float(s))
			_frame_override[StringName(kv[0])] = nums
	_run.call_deferred()


func _unit_framing(id: StringName) -> Array:
	if _frame_override.has(id):
		return _frame_override[id]
	return super(id)


func _run() -> void:
	await process_frame
	var done: int = 0
	var guide: Dictionary = {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GUIDE_JSON))
	if parsed is Dictionary and (parsed as Dictionary).get("units") is Dictionary:
		guide = (parsed as Dictionary)["units"]
	for id in _ids("res://data/units"):
		if TRADE_IDS.has(id) or WIZARDS.has(id) or CHAMPIONS.has(id):
			continue
		if not _only_ids.is_empty():
			if not _only_ids.has(String(id)):
				continue
		elif not _render_all:
			if not guide.has(String(id)):
				continue  # creatures / beasts / dev units: only with `all` or `ids=`
			if FileAccess.file_exists(ProjectSettings.globalize_path("%sunits/%s.png" % [OUT, id])):
				continue
		var res: Resource = load("res://data/units/%s.tres" % id)
		if res == null:
			continue
		var scene: PackedScene = res.get("model_scene") as PackedScene
		if scene == null:
			var p: String = _unit_scene(id)
			if p != "":
				scene = load(p) as PackedScene
		if scene == null:
			continue  # no model: the UI keeps its initials tile
		var f: StringName = StringName(str(res.get("faction")))
		await _render_model(&"units", id, f, scene, true)
		print("UNIT ICON ", id)
		done += 1
	# The sheet shows every unit icon on disk (rendered here or by the other renderers), sorted by id.
	_entries.clear()
	var names: Array[String] = []
	for fn in DirAccess.get_files_at(ProjectSettings.globalize_path(OUT + "units")):
		if fn.ends_with(".png"):
			names.append(fn)
	names.sort()
	for fn in names:
		var img: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + "units/" + fn))
		if img == null:
			continue
		img.convert(Image.FORMAT_RGBA8)
		if img.get_width() != SIZE:
			img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
		_entries.append([&"units", StringName(fn.get_basename()), img])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_sheet_override.get_base_dir()))
	await _contact_sheet()
	print("UNIT ICONS DONE: %d rendered, %d on the sheet" % [done, _entries.size()])
	quit()

extends SceneTree
## Merges the Lens close-shot cameras (tools/lens/specs/ep34_opening.lens, solved on this set's puppets by
## `tools\lens\run_lens.ps1 marks ep34_opening set=forge_evenmead`) into forge_evenmead.set as explicit `mark` lines,
## between the "# ---- Lens close shots" and "# ---- end Lens" markers (the words stay as the mark's lens= note).
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_evenmead/tools/merge_lens.gd --quit-after 300

const SET := "res://art/cinematics/stage_sets/forge_evenmead/forge_evenmead.set"
const MARKS := "res://docs/tools/lens/out/ep34_opening/marks.json"
const BEGIN := "# ---- Lens close shots (merged by tools/merge_lens.gd from docs/tools/lens/out/ep34_opening/marks.json; do not hand-edit)"
const END := "# ---- end Lens"
const DUR := {"N02": 6.0, "N07": 6.5, "N10": 6.0, "N11": 6.0, "N13": 5.5, "S02": 6.0, "S07": 6.0, "S10": 6.0, "S11": 6.0, "S13": 5.0}
const ORDER := ["N02", "N07", "N10", "N11", "N13", "S02", "S07", "S10", "S11", "S13"]


func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MARKS))
	var lines: Array[String] = [BEGIN]
	for shot: String in ORDER:
		if not data.has(shot):
			push_error("merge_lens: no %s in %s" % [shot, MARKS])
			continue
		var m: Dictionary = data[shot]
		var subj: String = {"stone": "stone_pt", "bloom": "bloom_pt"}.get(String(m["subject"]), String(m["subject"]))
		lines.append("mark %-4s from=%s  to=%s  look=%s  look_to=%s  fov=%s  fov_to=%s  subject=%s  dur=%s  lens=\"%s\"" % [shot,
			_v(m["from"]), _v(m["to"]), _v(m["look_from"]), _v(m["look_to"]), _n(m["fov_from"]), _n(m["fov_to"]), subj,
			_n(DUR.get(shot, 6.0)), m["lens"]])
	lines.append(END)
	var src := FileAccess.get_file_as_string(SET)
	var out := PackedStringArray()
	var skipping := false
	var done := false
	for ln in src.split("\n"):
		if ln.begins_with("# ---- Lens close shots"):
			skipping = true
			out.append_array(PackedStringArray(lines))
			done = true
			continue
		if skipping:
			if ln.begins_with(END):
				skipping = false
			continue
		out.append(ln)
	if not done:
		if out.size() > 0 and out[out.size() - 1] == "":
			out.remove_at(out.size() - 1)
		out.append_array(PackedStringArray(lines))
		out.append("")
	var f := FileAccess.open(SET, FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	print("merge_lens: %d marks merged" % (lines.size() - 2))
	quit()


static func _n(v: Variant) -> String:
	return ("%.3f" % float(v)).rstrip("0").rstrip(".")


static func _v(a: Array) -> String:
	return "(%s,%s,%s)" % [_n(a[0]), _n(a[1]), _n(a[2])]

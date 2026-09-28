extends SceneTree
## Asset trial: Rhubarb Lip Sync output -> cutscene puppets. Reads the TSV mouth cues made by
##   C:\Tools\rhubarb\rhubarb.exe -q -f tsv -d <line.txt> -o docs/art/asset_trials/rhubarb/<n>.tsv <voice.wav>
## and drives Vessa's only face hook (`set_expression`, 3 whole-face meshes) at 30 fps, as a cutscene would.
## Malrik has a void face (no mouth): the cues are turned into an eye-glow pulse curve instead.
## Headless:  tools\godot_run.ps1 --headless --path . -s tests/asset_trials/trial_rhubarb.gd --quit-after 3000

const DIR := "res://docs/art/asset_trials/rhubarb/"
const FPS := 30.0
## Rhubarb basic shapes: A closed (M B P), B slightly open (most consonants), C open (EH AE), D wide open (AA),
## E rounded (AO ER), F puckered (UW OW W), G F / V, H L, X idle. The best Vessa can do with 3 faces:
const VESSA_MAP := {"A": &"neutral", "B": &"neutral", "X": &"neutral", "G": &"neutral", "H": &"neutral",
		"C": &"smile", "D": &"smile", "E": &"smile", "F": &"fierce"}
## How open each shape is (0-1), for a mouthless face (Malrik's eyes).
const OPEN := {"X": 0.0, "A": 0.0, "B": 0.25, "G": 0.3, "H": 0.45, "F": 0.4, "C": 0.7, "E": 0.7, "D": 1.0}


func _initialize() -> void:
	var ok := true
	for n: String in ["vessa_tired", "malrik_little"]:
		var cues := _read(DIR + n + ".tsv")
		if cues.is_empty():
			print("FAIL rhubarb: no cues in %s.tsv" % n)
			ok = false
			continue
		var dur: float = cues[-1][0]
		var hist := {}
		for c: Array in cues:
			hist[c[1]] = hist.get(c[1], 0) + 1
		print("%s: %d cues over %.2f s (%.1f changes / s), shapes %s" % [n, cues.size(), dur, cues.size() / dur, str(hist)])
		if n.begins_with("vessa"):
			_drive_vessa(cues, dur)
		else:
			_drive_malrik(cues, dur)
	print("PASS rhubarb trial" if ok else "FAIL rhubarb trial")
	quit()


func _read(path: String) -> Array:
	var out: Array = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var parts := f.get_line().strip_edges().split("\t")
		if parts.size() == 2:
			out.append([parts[0].to_float(), parts[1]])
	return out


func _shape_at(cues: Array, t: float) -> String:
	var s: String = "X"
	for c: Array in cues:
		if c[0] <= t:
			s = c[1]
		else:
			break
	return s


func _drive_vessa(cues: Array, dur: float) -> void:
	var v: Node3D = (load("res://art/units/wizards/vessa.tscn") as PackedScene).instantiate()
	root.add_child(v)
	if not v.has_method(&"set_expression"):
		print("vessa: no set_expression hook")
		return
	var swaps := 0
	var prev := &""
	var strip := ""
	var us := 0
	var frames := int(dur * FPS)
	for i in frames:
		var e: StringName = VESSA_MAP.get(_shape_at(cues, i / FPS), &"neutral")
		var s := Time.get_ticks_usec()
		v.call(&"set_expression", e)
		us += Time.get_ticks_usec() - s
		if e != prev:
			swaps += 1
			prev = e
		strip += String(e).substr(0, 1)
	print("vessa: %d frames, %d face swaps (%.1f / s), set_expression %.4f ms avg" % [frames, swaps, swaps / dur, us / 1000.0 / frames])
	print("vessa frame strip (n=neutral closed smile, s=smile = open laugh + happy-CLOSED eyes, f=fierce smirk):")
	print("  " + strip)
	v.queue_free()


func _drive_malrik(cues: Array, dur: float) -> void:
	var frames := int(dur * FPS)
	var curve := ""
	var marks := " .:-=+*#"
	for i in frames:
		var o: float = OPEN.get(_shape_at(cues, i / FPS), 0.0)
		curve += marks[int(round(o * (marks.length() - 1)))]
	print("malrik (void face): eye-glow pulse from mouth openness, 30 fps:")
	print("  |" + curve + "|")

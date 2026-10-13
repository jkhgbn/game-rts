extends SceneTree
## Music Forge entry (docs/design/music.md 5). Renders the scores in tools/music_forge/scores/ to 16-bit mono
## 22 050 Hz WAV files and writes the listening sheet excerpts.
## Run (headless, through the gate):
##   & tools\godot_run.ps1 --headless --path . -s tools/music_forge/music_forge.gd --quit-after 200000 -- track=all
## Args (after --): track=<id>|<id,id>|all   excerpts (writes the 20 s listening excerpts)   force (ignore the hash)
## A track is re-rendered only when its score hash (score text + forge version) changed or its WAV is missing.
## Outputs: assets/audio/music/<id>.wav (scores with "out": "listen" go to the listening folder only),
## tools/music_forge/renders/<id>.json (check numbers + hash), docs/audio/listening_2026-10-13/<nn>_<id>.wav.
## Phase 1b: `backend=sampler` renders B versions with the recorded VSCO 2 CE instruments (sampler.gd; path from env
## FW_MUSIC_SAMPLES or `samples=<dir>`), stereo 44.1 kHz, to <samples dir>/../forge_renders_b/<id>_b.wav (outside the
## repo; the game tracks in assets/audio/music are not touched) and renders/<id>_b.json; `excerpts` then also writes
## <nn>b_<id>.wav. No sample folder = the sampler pass is skipped with a message (synth A versions still render).

const Core := preload("res://tools/music_forge/forge_core.gd")
const Dsp := preload("res://tools/music_forge/dsp.gd")
const Sampler := preload("res://tools/music_forge/sampler.gd")

const SCORES := "res://tools/music_forge/scores/"
const MUSIC_DIR := "res://assets/audio/music/"
const RENDERS := "res://tools/music_forge/renders/"
const LISTEN_DIR := "res://docs/audio/listening_2026-10-13/"
const EXCERPT_S := 20.0
const LISTEN_ORDER := ["theme_main", "fire", "fire_drive", "sting_victory", "choir_test"]


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var which := str(args.get("track", "all"))
	var ids: Array[String] = []
	if which == "all":
		for f in DirAccess.get_files_at(SCORES):
			if f.ends_with(".json"):
				ids.append(f.get_basename())
	else:
		for s in which.split(","):
			ids.append(s)
	var t0 := Time.get_ticks_msec()
	var ok := true
	_samples_root = Sampler.sample_root(str(args.get("samples", "")))
	if str(args.get("backend", "synth")) == "sampler":
		var smp := Sampler.new()
		if not smp.setup(_samples_root):
			print("music_forge: no sample library at %s: sampler pass skipped (synth versions only)" % _samples_root)
		else:
			for id in ids:
				if id != "kit_demo" or which != "all":
					ok = _render_one_b(id, smp, args.has("force")) and ok
			print("music_forge: sampler loaded %d files in %.1f s, %d sampled notes, %d synth fallbacks" % [
				smp.stats["files"], smp.stats["load_ms"] / 1000.0, smp.stats["notes"], smp.stats["fallback"]])
	else:
		for id in ids:
			ok = _render_one(id, args.has("force")) and ok
	if args.has("excerpts"):
		_excerpts()
	print("music_forge: done in %.1f s%s" % [(Time.get_ticks_msec() - t0) / 1000.0, "" if ok else " (with errors)"])
	quit.call_deferred(0 if ok else 1)


var _samples_root := ""


## Full B render (sampler, stereo 44.1 kHz): next to the sample library, outside the repo.
static func b_path(id: String, samples_root: String) -> String:
	return samples_root.get_base_dir() + "/forge_renders_b/" + id + "_b.wav"


func _render_one_b(id: String, smp: Sampler, force: bool) -> bool:
	var score := Core.load_score(SCORES + id + ".json")
	if score.is_empty():
		push_error("music_forge: cannot read score %s" % id)
		return false
	var path := b_path(id, _samples_root)
	var meta_path := RENDERS + id + "_b.json"
	var want := str(score["_hash_b"]) + "|" + Sampler.SAMPLER_VERSION
	if not force and FileAccess.file_exists(path) and FileAccess.file_exists(meta_path):
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if old is Dictionary and str((old as Dictionary).get("hash", "")) == want:
			print("music_forge: %s_b unchanged, skipped" % id)
			return true
	print("music_forge: rendering %s_b (sampler, stereo 44.1 kHz)" % id)
	var core := Core.new()
	var res := core.render_b(score, smp)
	var l: PackedFloat32Array = res["left"]
	var r: PackedFloat32Array = res["right"]
	var st: Dictionary = res["stats"]
	if not Dsp.write_wav2(path, l, r, Core.RATE_B):
		push_error("music_forge: cannot write %s" % path)
		return false
	st["file"] = path
	st["bytes"] = 44 + l.size() * 4
	var f := FileAccess.open(meta_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(st, "\t"))
	f.close()
	var seam_txt := "seam %.4f slope %.4f" % [st["seam_step"], st["seam_slope"]] if st.has("seam_step") else "end %.1f dB" % st["end_db"]
	print("  %s_b  %.2f s  %d samples x2  peak %.2f dB  rms %.2f dB  %.2f LUFS  %s  pad %.1f %%  %.1f s (reverb %d ms)"
		% [id, st["length_s"], st["samples"], st["peak_db"], st["rms_db"], st["lufs"], seam_txt,
		float(st["pad_share"]) * 100.0, st["render_s"], st["reverb_ms"]])
	return true


static func out_path(score: Dictionary) -> String:
	if str(score.get("out", "")) == "listen":
		return LISTEN_DIR + str(score["id"]) + ".wav"
	if str(score.get("out", "")) == "scratch":   # kit demos: not a game track
		return RENDERS + str(score["id"]) + ".wav"
	return MUSIC_DIR + str(score["id"]) + ".wav"


func _render_one(id: String, force: bool) -> bool:
	var score := Core.load_score(SCORES + id + ".json")
	if score.is_empty():
		push_error("music_forge: cannot read score %s" % id)
		return false
	var path := out_path(score)
	var meta_path := RENDERS + id + ".json"
	if not force and FileAccess.file_exists(path) and FileAccess.file_exists(meta_path):
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if old is Dictionary and str((old as Dictionary).get("hash", "")) == str(score["_hash"]):
			print("music_forge: %s unchanged (hash %s), skipped" % [id, str(score["_hash"]).substr(0, 8)])
			return true
	if not Core.length_exact(score):
		push_warning("music_forge: %s length is not a whole number of samples" % id)
	print("music_forge: rendering %s (%d bars, %s bpm)" % [id, int(score.get("bars", 0)), str(score.get("bpm"))])
	var core := Core.new()
	var res := core.render(score)
	for w in core.warnings:
		print("    WARN " + w)
	var buf: PackedFloat32Array = res["samples"]
	var st: Dictionary = res["stats"]
	if not Dsp.write_wav(ProjectSettings.globalize_path(path), buf):
		push_error("music_forge: cannot write %s" % path)
		return false
	st["file"] = path
	st["bytes"] = 44 + buf.size() * 2
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RENDERS))
	var f := FileAccess.open(meta_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(st, "\t"))
	f.close()
	var seam_txt := ""
	if st.has("seam_step"):
		seam_txt = "seam %.4f slope %.4f" % [st["seam_step"], st["seam_slope"]]
	else:
		seam_txt = "end %.1f dB" % st["end_db"]
	print("  %s  %.2f s  %d samples  peak %.2f dB  rms %.2f dB  %.2f LUFS  %s  pad %.1f %%  hf %.2f %%  %.1f s (reverb %d ms)"
		% [id, st["length_s"], st["samples"], st["peak_db"], st["rms_db"], st["lufs"], seam_txt,
		float(st["pad_share"]) * 100.0, float(st["hf_share"]) * 100.0, st["render_s"], st["reverb_ms"]])
	return true


func _excerpts() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LISTEN_DIR))
	var nn := 1
	var rows: PackedStringArray = []
	var checks: PackedStringArray = []
	for id in LISTEN_ORDER:
		var score := Core.load_score(SCORES + id + ".json")
		if score.is_empty():
			continue
		var w := Dsp.read_wav(out_path(score))
		if w.is_empty():
			push_error("music_forge: no render for %s" % id)
			continue
		var src: PackedFloat32Array = w["samples"]
		var n := src.size()
		var m := Core.meter_of(score)
		var start := int(round(float(score.get("excerpt_bar", 0)) * m.x * Core.spu(score) * Dsp.RATE))
		var length := mini(int(float(score.get("excerpt_s", EXCERPT_S)) * Dsp.RATE), n)
		if not bool(score.get("loop", true)):
			start = 0
			length = n
		var ex := PackedFloat32Array()
		ex.resize(length)
		for i in length:
			ex[i] = src[(start + i) % n]
		var fade := int(0.5 * Dsp.RATE)
		if bool(score.get("loop", true)):
			for i in fade:
				var g := float(i) / fade
				ex[i] *= g
				ex[length - 1 - i] *= g
		var name := "%02d_%s.wav" % [nn, id]
		Dsp.write_wav(ProjectSettings.globalize_path(LISTEN_DIR + name), ex)
		print("  excerpt %s  %.1f s from %.1f s" % [name, float(length) / Dsp.RATE, float(start) / Dsp.RATE])
		var full := "%d:%02d" % [int(n / Dsp.RATE) / 60, int(n / Dsp.RATE) % 60]
		var span := ("complete, %s" % full) if not bool(score.get("loop", true)) else 			("%.0f s from %d:%02d (%s) of %s" % [float(length) / Dsp.RATE, int(start / Dsp.RATE) / 60, int(start / Dsp.RATE) % 60,
			score.get("excerpt_note", "bar %s" % score.get("excerpt_bar", 0)), full])
		rows.append("| %d | `%s` | %s | %s | %s | %s | %s | %s | |" % [nn, name, score.get("title", id), score.get("mood", ""),
			score.get("instruments", ""), "%s %s, %s bpm %d/%d" % [score.get("key", ""), score.get("mode", ""), score.get("bpm", ""), m.x, m.y],
			span, score.get("listen_for", "")])
		var st: Variant = JSON.parse_string(FileAccess.get_file_as_string(RENDERS + id + ".json"))
		if st is Dictionary:
			var d: Dictionary = st
			var seam := "%.4f / %.4f" % [d["seam_step"], d["seam_slope"]] if d.has("seam_step") else "no loop (ends < -60 dBFS)"
			checks.append("| %s | %.2f s | %d | %.2f dBFS | %.2f dB | %.2f LUFS | %s | %.1f %% | %.0f s | %.1f MB |" % [id, d["length_s"],
				d["samples"], d["peak_db"], d["rms_db"], d["lufs"], seam, float(d["pad_share"]) * 100.0, d["render_s"],
				float(d.get("bytes", 0)) / 1048576.0])
		nn += 1
	var brows: PackedStringArray = []
	var bchecks: PackedStringArray = []
	nn = 1
	for id in LISTEN_ORDER:
		var score := Core.load_score(SCORES + id + ".json")
		var bp := b_path(id, _samples_root)
		if score.is_empty() or not FileAccess.file_exists(bp):
			nn += 1
			continue
		var w := Dsp.read_wav(bp)
		var sl: PackedFloat32Array = w.get("samples", PackedFloat32Array())
		var sr: PackedFloat32Array = w.get("right", PackedFloat32Array())
		var rate := int(w.get("rate", 44100))
		var n := sl.size()
		if n == 0 or sr.size() != n:
			nn += 1
			continue
		var m := Core.meter_of(score)
		var loop := bool(score.get("loop", true))
		var start := 0 if not loop else int(round(float(score.get("excerpt_bar", 0)) * m.x * Core.spu(score) * rate))
		var length := n if not loop else mini(int(float(score.get("excerpt_s", EXCERPT_S)) * rate), n)
		var el := PackedFloat32Array()
		el.resize(length)
		var er := PackedFloat32Array()
		er.resize(length)
		for i in length:
			el[i] = sl[(start + i) % n]
			er[i] = sr[(start + i) % n]
		if loop:
			var fade := int(0.5 * rate)
			for i in fade:
				var g := float(i) / fade
				el[i] *= g
				er[i] *= g
				el[length - 1 - i] *= g
				er[length - 1 - i] *= g
		var name := "%02db_%s.wav" % [nn, id]
		Dsp.write_wav2(ProjectSettings.globalize_path(LISTEN_DIR + name), el, er, rate)
		print("  excerpt %s  %.1f s stereo %d Hz" % [name, float(length) / rate, rate])
		brows.append("| %d | `%02d_%s.wav` | `%s` | %s |" % [nn, nn, id, name, COMPARE.get(id, "")])
		var st: Variant = JSON.parse_string(FileAccess.get_file_as_string(RENDERS + id + "_b.json"))
		if st is Dictionary:
			var d: Dictionary = st
			var seam := "%.4f / %.4f" % [d["seam_step"], d["seam_slope"]] if d.has("seam_step") else "no loop (ends < -60 dBFS)"
			var sm: Dictionary = d.get("sampler", {})
			bchecks.append("| %s_b | %.2f s | %d x 2 | %.2f dBFS | %.2f dB | %.2f LUFS | %s | %.0f s | %.1f MB | %d / %d |" % [id,
				d["length_s"], d["samples"], d["peak_db"], d["rms_db"], d["lufs"], seam, d["render_s"],
				float(d.get("bytes", 0)) / 1048576.0, int(sm.get("notes", 0)), int(sm.get("fallback", 0))])
		nn += 1
	_write_index(rows, checks, brows, bchecks)


const COMPARE := {
	"theme_main": "Brass bridge and tutti: real horns / trumpets / strings vs synth sections. Does B finally sound like an orchestra? Is the harp too present?",
	"fire": "Oboe (B) vs synth shawm (A) as the Fire lead; harp-plucked lute (B) vs Karplus-Strong lute (A); real cello spiccato gallop.",
	"fire_drive": "Orchestral bass drum + snare (B) vs synth frame drums / taiko (A). Claps and shaker stay synth in both.",
	"sting_victory": "Real trumpets + timpani hits: more triumphant? (tubular bell stays synth, celesta = glockenspiel in B)",
	"choir_test": "No choir samples: B plays the choir line on horns, then the strings half on real strings. Compare the strings halves.",
}


func _write_index(rows: PackedStringArray, checks: PackedStringArray, brows: PackedStringArray = [],
		bchecks: PackedStringArray = []) -> void:
	var t := PackedStringArray([
		"# Music Forge phase 1: listening sheet (2026-10-13)", "",
		"Generated by `tools/music_forge/music_forge.gd -- excerpts` from the scores (`tools/music_forge/scores/*.json`) and the",
		"render reports (`tools/music_forge/renders/*.json`). All music is generated by code, no samples, own melodies only.",
		"Style target (JS): an orchestral film-score sound (string / brass / flute sections of several detuned, time-offset",
		"players, harp, timpani and drums, room reverb, quiet build-ups to tutti). Every track quotes the **Call** motif.",
		"Files: 16-bit mono 22 050 Hz WAV; excerpts have 0.5 s fades. Copy for double-click listening (with the full tracks):",
		"`C:\\Users\\elzzo\\Desktop\\FourWizards-musique-ecoute\\` (full tracks in the `complet` sub-folder).", "",
		"| # | File | Track | Mood | Instruments | Key, tempo | Excerpt | What to listen for | JS verdict |",
		"|---|---|---|---|---|---|---|---|---|"])
	t.append_array(rows)
	t.append_array(PackedStringArray(["", "## Audio check numbers (whole rendered files, `tests/test_music_forge.gd`)", "",
		"| Track | Length | Samples | Peak | RMS | Loudness | Loop seam step / slope (max 0.02) | Pad share (max 20 %) | Render time | Size |",
		"|---|---|---|---|---|---|---|---|---|---|"]))
	t.append_array(checks)
	t.append_array(PackedStringArray(["",
		"Loudness = BS.1770 integrated (K-weighted, gated); targets -12 +-1.5 LUFS (drives -16 +-2). Peak = sample peak after a",
		"look-ahead limiter at -1.2 dBFS. Pad share = energy of the parts flagged `pad` / dry mix energy.",
		"Deterministic: same score = same bytes (the test renders sting_victory twice and compares with the file).", ""]))
	if not brows.is_empty():
		t.append_array(PackedStringArray(["## A vs B: synth (A) vs recorded instruments (B)", "",
			"B = the SAME scores played by the sampler backend (`tools/music_forge/sampler.gd`) with the CC0 library VSCO 2",
			"Community Edition (Versilian Studios; kept outside the repo, path from env `FW_MUSIC_SAMPLES`). B files are",
			"**stereo 44.1 kHz** (orchestra seating pan, stereo Freeverb) to show the real potential; A files are the game format",
			"(mono 22 050 Hz). Same notes, same humanised timing, B part levels matched to A's balance. JS picks A or B per track.",
			"Instruments with no sample in the subset stay synth in B: claps, shaker, frame-drum tek, tubular bell, pad; the",
			"choir line is played by horns; celesta = glockenspiel; lute = harp, damped.", "",
			"| # | A (synth) | B (samples) | What to compare | JS pick (A / B) |", "|---|---|---|---|---|"]))
		for r in brows:
			t.append(r + " |")
		t.append_array(PackedStringArray(["", "B check numbers (whole files):", "",
			"| Track | Length | Samples | Peak | RMS | Loudness | Loop seam step / slope | Render time | Size | Sampled / synth notes |",
			"|---|---|---|---|---|---|---|---|---|---|"]))
		t.append_array(bchecks)
		t.append("")
	var f := FileAccess.open(LISTEN_DIR + "index.md", FileAccess.WRITE)
	f.store_string("\n".join(t))
	f.close()
	print("  wrote %sindex.md" % LISTEN_DIR)

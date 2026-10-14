extends SceneTree
## Music Forge entry (docs/design/music.md 5). Renders the scores in tools/music_forge/scores/ and writes the listening
## sheet excerpts.
## Run (headless, through the gate):
##   & tools\godot_run.ps1 --headless --path . -s tools/music_forge/music_forge.gd --quit-after 2000000 -- track=all
## Args (after --): track=<id>|<id,id>|all   backend=game|sampler|synth   excerpts   force (ignore the hash)
## backend=game (default, phase 2, JS 2026-10-14 "B for every track"): the sampler backend (sampler.gd, CC0 VSCO 2 CE
##   samples from env FW_MUSIC_SAMPLES or `samples=<dir>`, kept OUTSIDE the repo; neither set = error) renders stereo at 44.1 kHz with the
##   stereo room, then low-passes and decimates to the game format: 16-bit STEREO 22 050 Hz WAV in
##   assets/audio/music/<id>.wav (drives <id>_drive.wav); report renders/<id>.json. No sample library = error, the
##   game files are never overwritten by the synth. `track=all` = GAME_TRACKS. Scores may not hold a choir part
##   (no singing, JS 2026-10-14).
## backend=sampler: the phase 1b listening renders (stereo 44.1 kHz) to <samples dir>/../forge_renders_b/<id>_b.wav.
## backend=synth: the phase 1 synth kit (mono 22 050 Hz) to scratch WAVs OUTSIDE the repo (scratch_dir(): env
##   FW_MUSIC_SCRATCH, else %TEMP%/fw_music_forge); its reports stay in tools/music_forge/renders/<id>_a.json.
## No WAV is ever written inside the repo except the shipped game files and the listening excerpts.
## A track is re-rendered only when its score hash (score text + forge / sampler version + format) changed or its WAV is
## missing. `excerpts` writes the phase 2 listening excerpts (stereo 22 050 Hz) and the "Phase 2" section of index.md.

const Core := preload("res://tools/music_forge/forge_core.gd")
const Dsp := preload("res://tools/music_forge/dsp.gd")
const Sampler := preload("res://tools/music_forge/sampler.gd")

const SCORES := "res://tools/music_forge/scores/"
const MUSIC_DIR := "res://assets/audio/music/"
const RENDERS := "res://tools/music_forge/renders/"
const LISTEN_DIR := "res://docs/audio/listening_2026-10-13/"
const EXCERPT_S := 20.0
const GAME_FORMAT := "g22050s"
## Every shipped track (music.md 2): 13 tracks + 7 drives.
const GAME_TRACKS := ["theme_main", "campaign_map", "fire", "fire_drive", "ice", "ice_drive", "nature", "nature_drive",
	"shadow", "shadow_drive", "field", "field_drive", "wave_strike", "wave_strike_drive", "boss", "boss_drive", "tavern",
	"chant", "sting_victory", "sting_defeat"]
## Phase 2 listening excerpts (numbered after the phase 1 sheet's 01-05).
const PHASE2_LISTEN := ["ice", "ice_drive", "nature", "nature_drive", "shadow", "shadow_drive", "field", "field_drive",
	"wave_strike", "wave_strike_drive", "boss", "boss_drive", "chant", "campaign_map", "tavern", "sting_defeat"]
const PHASE2_FIRST := 6
const PHASE2_MARK := "## Phase 2"

var _samples_root := ""


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var backend := str(args.get("backend", "game"))
	var which := str(args.get("track", "all" if not args.has("excerpts") else ""))
	var ids: Array[String] = []
	if which == "all" and backend == "game":
		for id in GAME_TRACKS:
			ids.append(id)
	elif which == "all":
		for f in DirAccess.get_files_at(SCORES):
			if f.ends_with(".json"):
				ids.append(f.get_basename())
	elif which != "":
		for s in which.split(","):
			ids.append(s)
	var t0 := Time.get_ticks_msec()
	var ok := true
	_samples_root = Sampler.sample_root(str(args.get("samples", "")))
	if backend == "synth":
		for id in ids:
			ok = _render_one(id, args.has("force")) and ok
	elif not ids.is_empty():
		var smp := Sampler.new()
		if _samples_root == "":
			push_error("music_forge: FW_MUSIC_SAMPLES is not set (path of the VSCO 2 CE sample library): nothing rendered")
			ok = false
		elif not smp.setup(_samples_root):
			push_error("music_forge: no sample library at %s (FW_MUSIC_SAMPLES): nothing rendered" % _samples_root)
			ok = false
		else:
			for id in ids:
				if backend == "sampler":
					ok = _render_one_b(id, smp, args.has("force")) and ok
				else:
					ok = _render_game(id, smp, args.has("force")) and ok
			print("music_forge: sampler loaded %d files in %.1f s, %d sampled notes, %d synth notes" % [
				smp.stats["files"], smp.stats["load_ms"] / 1000.0, smp.stats["notes"], smp.stats["fallback"]])
	if args.has("excerpts"):
		ok = _excerpts_phase2() and ok
	print("music_forge: done in %.1f s%s" % [(Time.get_ticks_msec() - t0) / 1000.0, "" if ok else " (with errors)"])
	quit.call_deferred(0 if ok else 1)


## The shipped file of a track.
static func game_path(id: String) -> String:
	return MUSIC_DIR + id + ".wav"


## Hash a game file's report must carry to be up to date with its score.
static func game_hash(score: Dictionary) -> String:
	return str(score["_hash_b"]) + "|" + Sampler.SAMPLER_VERSION + "|" + GAME_FORMAT


func _render_game(id: String, smp: Sampler, force: bool) -> bool:
	var score := Core.load_score(SCORES + id + ".json")
	if score.is_empty():
		push_error("music_forge: cannot read score %s" % id)
		return false
	if str(score.get("out", "")) != "":
		push_error("music_forge: %s is not a game track (out = %s)" % [id, score.get("out")])
		return false
	var path := ProjectSettings.globalize_path(game_path(id))
	var meta_path := RENDERS + id + ".json"
	var want := game_hash(score)
	if not force and FileAccess.file_exists(path) and FileAccess.file_exists(meta_path):
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if old is Dictionary and str((old as Dictionary).get("hash", "")) == want:
			print("music_forge: %s unchanged, skipped" % id)
			return true
	if not Core.length_exact(score, Core.RATE_GAME):
		push_warning("music_forge: %s length is not a whole number of samples" % id)
	print("music_forge: rendering %s (sampler, stereo 22 050 Hz, %d bars, %s bpm)" % [id, int(score.get("bars", 0)),
		str(score.get("bpm"))])
	var core := Core.new()
	var res := core.render_b(score, smp, true, Core.RATE_GAME)
	if res.has("error"):
		return false   # refused (choir part): nothing is written
	for w in core.warnings:
		print("    WARN " + w)
	var l: PackedFloat32Array = res["left"]
	var r: PackedFloat32Array = res["right"]
	var st: Dictionary = res["stats"]
	if not Dsp.write_wav2(path, l, r, Core.RATE_GAME):
		push_error("music_forge: cannot write %s" % path)
		return false
	st["id"] = id
	st["hash"] = want
	st["file"] = game_path(id)
	st["bytes"] = 44 + l.size() * 4
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RENDERS))
	var f := FileAccess.open(meta_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(st, "\t"))
	f.close()
	var seam_txt := "seam %.4f slope %.4f" % [st["seam_step"], st["seam_slope"]] if st.has("seam_step") else "end %.1f dB" % st["end_db"]
	var sm: Dictionary = st["sampler"]
	print("  %s  %.2f s  %d samples x2  peak %.2f dB  rms %.2f dB  %.2f LUFS  %s  pad %.1f %%  %d sampled / %d synth notes  %.1f s"
		% [id, st["length_s"], st["samples"], st["peak_db"], st["rms_db"], st["lufs"], seam_txt,
		float(st["pad_share"]) * 100.0, int(sm["notes"]), int(sm["fallback"]), st["render_s"]])
	return true


## Phase 1b listening render (sampler, stereo 44.1 kHz): next to the sample library, outside the repo.
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
	print("  %s_b  %.2f s  peak %.2f dB  %.2f LUFS  %.1f s" % [id, st["length_s"], st["peak_db"], st["lufs"], st["render_s"]])
	return true


## Scratch folder for dev renders, outside the repo: env FW_MUSIC_SCRATCH, else %TEMP%/fw_music_forge.
static func scratch_dir() -> String:
	var d := OS.get_environment("FW_MUSIC_SCRATCH")
	if d == "":
		var tmp := OS.get_environment("TEMP")
		d = (tmp if tmp != "" else OS.get_user_data_dir()) + "/fw_music_forge"
	return d.replace("\\", "/") + "/"


## Synth (A) render target (absolute path): always the scratch folder, never inside the repo.
static func out_path(score: Dictionary) -> String:
	return scratch_dir() + str(score["id"]) + ("_a" if str(score.get("out", "")) == "" else "") + ".wav"


func _render_one(id: String, force: bool) -> bool:
	var score := Core.load_score(SCORES + id + ".json")
	if score.is_empty():
		push_error("music_forge: cannot read score %s" % id)
		return false
	var path := out_path(score)
	var meta_path := RENDERS + id + ("_a" if str(score.get("out", "")) == "" else "") + ".json"
	if not force and FileAccess.file_exists(path) and FileAccess.file_exists(meta_path):
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if old is Dictionary and str((old as Dictionary).get("hash", "")) == str(score["_hash"]):
			print("music_forge: %s unchanged (hash %s), skipped" % [id, str(score["_hash"]).substr(0, 8)])
			return true
	print("music_forge: rendering %s (synth, mono 22 050 Hz)" % id)
	var core := Core.new()
	var res := core.render(score)
	for w in core.warnings:
		print("    WARN " + w)
	var buf: PackedFloat32Array = res["samples"]
	var st: Dictionary = res["stats"]
	if not Dsp.write_wav(path, buf):
		push_error("music_forge: cannot write %s" % path)
		return false
	st["file"] = path
	st["bytes"] = 44 + buf.size() * 2
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RENDERS))
	var f := FileAccess.open(meta_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(st, "\t"))
	f.close()
	print("  %s  %.2f s  peak %.2f dB  %.2f LUFS  %.1f s" % [id, st["length_s"], st["peak_db"], st["lufs"], st["render_s"]])
	return true


# ---------------------------------------------------------------- phase 2 listening sheet

## Writes <nn>_<id>.wav (20 s from excerpt_bar, 0.5 s fades; stings complete) for PHASE2_LISTEN from the game files and
## rewrites the "Phase 2" section of index.md (everything before it, the phase 1 sheet, is kept as it is).
func _excerpts_phase2() -> bool:
	var ok := true
	var rows: PackedStringArray = []
	for k in PHASE2_LISTEN.size():
		var id: String = PHASE2_LISTEN[k]
		var nn := PHASE2_FIRST + k
		var score := Core.load_score(SCORES + id + ".json")
		var w := Dsp.read_wav(game_path(id))
		if score.is_empty() or w.is_empty() or int(w.get("channels", 0)) != 2:
			push_error("music_forge: no stereo game render for %s" % id)
			ok = false
			continue
		var sl: PackedFloat32Array = w["samples"]
		var sr: PackedFloat32Array = w["right"]
		var rate := int(w["rate"])
		var n := sl.size()
		var m := Core.meter_of(score)
		var loop := bool(score.get("loop", true))
		var start := 0 if not loop else int(round(float(score.get("excerpt_bar", 0)) * m.x * Core.spu(score) * rate))
		var length := n if not loop else mini(int(EXCERPT_S * rate), n)
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
		var name := "%02d_%s.wav" % [nn, id]
		Dsp.write_wav2(ProjectSettings.globalize_path(LISTEN_DIR + name), el, er, rate)
		print("  excerpt %s  %.1f s from %.1f s" % [name, float(length) / rate, float(start) / rate])
		var full := "%d:%02d" % [int(n / rate) / 60, int(n / rate) % 60]
		var span := ("complete, %s" % full) if not loop else ("%.0f s from %d:%02d (%s) of %s" % [float(length) / rate,
			int(start / rate) / 60, int(start / rate) % 60, score.get("excerpt_note", "bar %s" % score.get("excerpt_bar", 0)), full])
		var key := "unpitched" if str(score.get("mode", "")) == "unpitched" else "%s %s" % [score.get("key", ""), score.get("mode", "")]
		rows.append("| %d | `%s` | %s | %s | %s | %s, %s bpm %d/%d | %s | %s | |" % [nn, name, score.get("title", id),
			score.get("mood", ""), score.get("instruments", ""), key, score.get("bpm", ""), m.x, m.y, span,
			score.get("listen_for", "")])
	var checks: PackedStringArray = []
	var total := 0.0
	for id in GAME_TRACKS:
		var st: Variant = JSON.parse_string(FileAccess.get_file_as_string(RENDERS + id + ".json"))
		if not (st is Dictionary):
			continue
		var d: Dictionary = st
		var seam := "%.4f / %.4f" % [d["seam_step"], d["seam_slope"]] if d.has("seam_step") else "no loop (ends < -60 dBFS)"
		var sm: Dictionary = d.get("sampler", {})
		total += float(d.get("bytes", 0))
		checks.append("| %s | %.2f s | %d x 2 | %.2f dBFS | %.2f dB | %.2f LUFS | %s | %.1f %% | %.0f s | %.1f MB | %d / %d |" % [id,
			d["length_s"], d["samples"], d["peak_db"], d["rms_db"], d["lufs"], seam, float(d["pad_share"]) * 100.0,
			d["render_s"], float(d.get("bytes", 0)) / 1048576.0, int(sm.get("notes", 0)), int(sm.get("fallback", 0))])
	var t := PackedStringArray([PHASE2_MARK + " (2026-10-14): every track, recorded instruments (B), game format", "",
		"JS picked **B for every track** and **no singing anywhere** (melody only). Every game track is now rendered by the",
		"sampler backend (CC0 VSCO 2 Community Edition, outside the repo) in the game format: **16-bit stereo 22 050 Hz WAV**",
		"(orchestra seating pan + stereo room kept), in `assets/audio/music/`. The four phase 1 tracks (theme_main, fire,",
		"fire_drive, sting_victory) were re-rendered in this format (theme_main's choir swell is now a horn / viola swell).",
		"`chant` and `boss` have no choir: their lead is instrumental (see each row). Excerpts: 20 s with 0.5 s fades,",
		"stings complete. Full tracks in the Desktop copy's `complet` folder.",
		"Still synth (no sample in the library): tubular / tolling bells, log mallet, frame-drum tek, claps, shaker, the",
		"low drone pads (support only, <= 20 %). Celesta / glass bell = glockenspiel samples; lute = damped harp; fiddle =",
		"violin section; pizzicato = cello pizzicato samples; hand drum / heartbeat / foot stomp = muted bass drum.", "",
		"| # | File | Track | Mood | Instruments | Key, tempo | Excerpt | What to listen for | JS verdict |",
		"|---|---|---|---|---|---|---|---|---|"])
	t.append_array(rows)
	t.append_array(PackedStringArray(["", "Game files check numbers (`tests/test_music_check.gd`, whole files):", "",
		"| Track | Length | Samples | Peak | RMS | Loudness | Loop seam step / slope | Pad share | Render time | Size | Sampled / synth notes |",
		"|---|---|---|---|---|---|---|---|---|---|---|"]))
	t.append_array(checks)
	t.append_array(PackedStringArray(["", "Total: %.1f MB of WAV (QOA on import for the export)." % (total / 1048576.0), ""]))
	var old := FileAccess.get_file_as_string(LISTEN_DIR + "index.md")
	var cut := old.find("\n" + PHASE2_MARK)
	if cut >= 0:
		old = old.substr(0, cut)
	old = old.rstrip("\n") + "\n"
	var f := FileAccess.open(LISTEN_DIR + "index.md", FileAccess.WRITE)
	f.store_string(old + "\n" + "\n".join(t))
	f.close()
	print("  wrote %sindex.md (%d phase 2 rows)" % [LISTEN_DIR, rows.size()])
	return ok

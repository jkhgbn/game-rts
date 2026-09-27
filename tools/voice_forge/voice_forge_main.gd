extends SceneTree
## Voice Forge, Godot side (tools/voice_forge/README.md). Rendering happens in Python (Kokoro, voice_forge.py);
## this script judges the result and writes the scorecard: docs/tools/voice_forge/out/<id>/report.md + report.json +
## a history row. Run through tools/voice_forge/run_voice_forge.ps1 (check / build / demo call it last).

const VERBS := [
	{"verb": "help", "args": "", "text": "grammar, files, example"},
	{"verb": "check", "args": "[id]", "text": "lines missing audio, overruns of cine slot / subtitle time, clipping, format"},
	{"verb": "build", "args": "[id]", "text": "(the .ps1 extracts + renders + imports first) the same checks, verb build"},
	{"verb": "demo", "args": "[id]", "text": "(the .ps1 rebuilds everything first) the same checks, verb demo"},
]
const KEYS := [
	{"key": "strict", "default": "0", "text": "1 = slot overruns FAIL instead of WARN"},
	{"key": "force", "default": "0", "text": "(ps1 build) 1 = re-render every line"},
	{"key": "only", "default": "", "text": "(ps1 build / audition) render only this speaker (audition keeps the other rows)"},
	{"key": "fit", "default": "1", "text": "(ps1 build) 1 = speed new / changed lines up (<= x1.25) to fit their slot, all = also re-fit existing overruns, 0 = off"},
]
const EXAMPLE := """Files:
  data/voice/cast.json          speaker -> {voice, speed, notes, audition[]}; voice = kokoro id or {id: weight} blend
  data/voice/lines_index.json   every spoken line found (extract), with its sources and slots
  data/voice/lines/*.json       extra line files ({cine_id, lines: [{id, shot, at, dur, speaker, text}]})
  data/voice/manifest.json      id -> {speaker, text, text_hash, path, duration, peak, voice, speed, sources}
  assets/audio/voice/<speaker>/<first_words>_<hash8>.wav   mono 24 kHz PCM16, trimmed, peak -1 dBFS
Sources scanned: const *DIALOGUE* arrays + literal dialogue emits in scripts/campaign/ and missions/ (slot = the
DialogueBox LINE_SECONDS), `at <t> line <speaker> "<text>"` in data/cinematics/src/*.cine (slot = to the next line
or the shot end; *_bugs.cine skipped), data/story/*.lines.json, docs/design/episode3-4-opening.md section 3 tables.
Example:
  .\\tools\\voice_forge\\run_voice_forge.ps1 build            # extract + render new/changed lines + import + report
  .\\tools\\voice_forge\\run_voice_forge.ps1 check            # extract + report (no rendering)
  .\\tools\\voice_forge\\run_voice_forge.ps1 audition only=hush  # candidates -> docs/tools/voice_forge/auditions/
Direction tags in a line: [scared] [hesitant] [stutter] [whisper] [sad] [tired] [slow] [calm] [fast] [excited] [angry]
[shout], inline [pause] (speed / pauses / stutter / ending of the spoken text; the tag stays in the keyed text).
Add a voiced line: write the line in its source (mission DIALOGUE, .cine `line`, story doc), run build. Unchanged lines
are never re-rendered (key = hash of speaker + text); a changed voice / speed in cast.json re-renders that speaker."""

const INDEX := "res://data/voice/lines_index.json"
const MANIFEST := "res://data/voice/manifest.json"
const CAST := "res://data/voice/cast.json"
const SR := 24000
const LEAD_MAX := 0.12
const TAIL_MAX := 0.2


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var cli := ToolCli.parse("voice_forge", VERBS, KEYS)
	if cli.bad != "":
		print(cli.bad)
		quit(ToolCli.BAD_INPUT)
		return
	ToolCli.watchdog(self, 120.0, "voice_forge")
	if cli.verb == "help":
		print(cli.help_text("every spoken line of the game -> one Kokoro voice WAV (text in, report out)", EXAMPLE))
		quit(ToolCli.OK)
		return
	var id := cli.id if cli.id != "" else "all"
	var rep := ToolReport.start("voice_forge", cli.verb, id)
	_run_checks(rep, id, cli.opt_bool("strict"))
	quit(rep.finish())


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _run_checks(rep: ToolReport, id: String, strict: bool) -> void:
	rep.add_group("data", "Data (cast, index, manifest)", 1.0)
	rep.add_group("cover", "Coverage (every spoken line has audio)", 2.0)
	rep.add_group("fit", "Fit (voice length vs cine slot / subtitle time)", 1.0)
	rep.add_group("audio", "Audio (format, clipping, trim, size)", 1.0)
	rep.add_group("hook", "Game hookup", 0.5)
	var cast: Variant = _read_json(CAST)
	var index: Variant = _read_json(INDEX)
	var man: Variant = _read_json(MANIFEST)
	var speakers: Dictionary = (cast as Dictionary).get("speakers", {}) if cast is Dictionary else {}
	rep.check("D1", "data", "cast.json", "PASS" if not speakers.is_empty() else "FAIL", "%d speakers" % speakers.size(),
		"parses, has speakers", "fix the JSON in data/voice/cast.json")
	if not index is Dictionary:
		rep.check("D2", "data", "lines_index.json", "FAIL", "missing", "extract ran", "run run_voice_forge.ps1 check (it extracts first)")
		return
	var lines: Array = (index as Dictionary).get("lines", [])
	rep.check("D2", "data", "lines found", "PASS" if lines.size() > 0 else "FAIL", "%d unique lines" % lines.size(),
		"> 0", "sources: see notes")
	for n: Variant in (index as Dictionary).get("notes", []):
		rep.notes.append("source: " + str(n))
	var entries: Dictionary = {}
	if man is Dictionary and (man as Dictionary).get("lines") is Dictionary:
		entries = man["lines"]
	var bad_entries: Array[String] = []
	for key: String in entries:
		var e: Dictionary = entries[key]
		var spk := str(e.get("speaker", ""))
		var h := (spk + "\n" + str(e.get("text", ""))).sha256_text().substr(0, 16)
		var path := str(e.get("path", ""))
		if h != str(e.get("text_hash", "")) or not path.begins_with("res://assets/audio/voice/%s/" % spk) \
				or float(e.get("duration", 0.0)) <= 0.0 or not key.begins_with(spk + "/"):
			bad_entries.append(key)
	rep.check("D3", "data", "manifest entries", "PASS" if man is Dictionary and bad_entries.is_empty() else "FAIL",
		"%d entries, %d bad %s" % [entries.size(), bad_entries.size(), ", ".join(PackedStringArray(bad_entries.slice(0, 4)))],
		"text_hash = sha256(speaker\\ntext)[:16], path under assets/audio/voice/<speaker>/, duration > 0",
		"re-run build (force=1 if a file was edited by hand)")
	# Known speakers: the cast and the subtitle table.
	var sp_script: Script = load("res://scripts/ui/cinematic/speakers.gd") if ResourceLoader.exists("res://scripts/ui/cinematic/speakers.gd") else null
	var table: Dictionary = sp_script.get_script_constant_map().get("TABLE", {}) if sp_script else {}
	var uncast: Array[String] = []
	var unknown: Array[String] = []
	for l: Dictionary in lines:
		for s: Dictionary in l.get("sources", []):
			var sid := str(s.get("speaker_id", l["speaker"]))
			if not speakers.has(sid) and not sid in uncast:
				uncast.append(sid)
			if not table.is_empty() and not table.has(StringName(sid)) and not sid in unknown and sid != "shade":
				unknown.append(sid)
	rep.check("D4", "data", "speakers cast", "PASS" if uncast.is_empty() else "WARN",
		"all cast" if uncast.is_empty() else "no cast entry: " + ", ".join(PackedStringArray(uncast)),
		"every speaker has a voice in cast.json", "add them to data/voice/cast.json (else the default voice speaks)")
	if not unknown.is_empty():
		rep.check("D5", "data", "speakers vs Speakers.TABLE", "INFO", ", ".join(PackedStringArray(unknown)),
			"subtitle names known", "ask ui-coder to add them to scripts/ui/cinematic/speakers.gd")
	# Coverage.
	var missing: Array[String] = []
	var unimported: Array[String] = []
	var mission_total := 0
	var mission_ok := 0
	var total_s := 0.0
	var listed := {}
	for l: Dictionary in lines:
		var key: String = l["id"]
		listed[key] = true
		var e: Dictionary = entries.get(key, {})
		var is_mission := false
		for s: Dictionary in l.get("sources", []):
			if str(s.get("kind", "")) == "mission":
				is_mission = true
		mission_total += 1 if is_mission else 0
		var path := str(e.get("path", ""))
		if e.is_empty() or not FileAccess.file_exists(path):
			missing.append(key)
			continue
		if not ResourceLoader.exists(path) or not load(path) is AudioStream:
			unimported.append(key)
			continue
		mission_ok += 1 if is_mission else 0
		total_s += float(e.get("duration", 0.0))
	rep.add("C1", "cover", "lines with audio", "PASS" if missing.is_empty() else "FAIL",
		"%d / %d%s" % [lines.size() - missing.size(), lines.size(), ("; missing " + ", ".join(PackedStringArray(missing.slice(0, 5)))) if not missing.is_empty() else ""],
		"every spoken line has a WAV", "run_voice_forge.ps1 build", ToolReport.grade(lines.size() - missing.size(), 0, lines.size()))
	rep.check("C2", "cover", "mission lines voiced", "PASS" if mission_ok == mission_total and mission_total > 0 else "FAIL",
		"%d / %d" % [mission_ok, mission_total], "all mission dialogue voiced", "run_voice_forge.ps1 build")
	rep.check("C3", "cover", "imported", "PASS" if unimported.is_empty() else "FAIL",
		"%d not importable%s" % [unimported.size(), (": " + ", ".join(PackedStringArray(unimported.slice(0, 4)))) if not unimported.is_empty() else ""],
		"load(path) is AudioStream", "run Godot --headless --import (build does it)")
	var orphans: Array[String] = []
	for key: String in entries:
		if not listed.has(key):
			orphans.append(key)
	rep.check("C4", "cover", "orphan WAVs", "PASS" if orphans.is_empty() else "WARN", "%d" % orphans.size(),
		"no manifest line without a source", "lines removed from their source: delete the WAVs, rebuild")
	# Fit.
	var over: Array[String] = []
	var over_bad := 0
	var fitted := 0
	for l: Dictionary in lines:
		var e: Dictionary = entries.get(l["id"], {})
		if e.is_empty():
			continue
		var d := float(e.get("duration", 0.0))
		for s: Dictionary in l.get("sources", []):
			if s.get("slot") == null or float(s["slot"]) <= 0.0:
				continue
			var slot := float(s["slot"])
			fitted += 1
			if d > slot + 0.05:
				over.append("%s %s: %.2f s > %s %.2f s" % [l["id"], s.get("ref", ""), d, s.get("slot_kind", "slot"), slot])
				if d > slot * 1.15:
					over_bad += 1
	var fit_status := "PASS"
	if not over.is_empty():
		fit_status = "FAIL" if strict else "WARN"
	rep.add("F1", "fit", "voice fits its slot", fit_status, "%d / %d over (%d by > 15 %%)" % [over.size(), fitted, over_bad],
		"voice length <= cine slot / subtitle time", "run_voice_forge.ps1 build fit=all (speeds the overrunning lines up, <= x1.25), lengthen the slot, or shorten the line",
		ToolReport.grade(float(over.size()), float(maxi(fitted, 1)), 0.0), "the lines listed in the notes")
	for o: String in over:
		rep.notes.append("over slot: " + o)
	# Audio: parse the source WAVs (the imported copy is QOA-compressed).
	var fmt_bad: Array[String] = []
	var clipped: Array[String] = []
	var untrimmed: Array[String] = []
	var peak_lo := 1.0
	var peak_hi := 0.0
	var bytes_total := 0
	for key: String in entries:
		var path := str((entries[key] as Dictionary).get("path", ""))
		if not FileAccess.file_exists(path):
			continue
		var w := _wav_info(path)
		bytes_total += int(w.get("bytes", 0))
		if not w.get("ok", false) or int(w["channels"]) != 1 or int(w["rate"]) != SR or int(w["bits"]) != 16:
			fmt_bad.append(key)
			continue
		if int(w["clip"]) > 0:
			clipped.append("%s (%d samples)" % [key, w["clip"]])
		peak_lo = minf(peak_lo, float(w["peak"]))
		peak_hi = maxf(peak_hi, float(w["peak"]))
		if float(w["lead"]) > LEAD_MAX or float(w["tail"]) > TAIL_MAX:
			untrimmed.append("%s (%.2f / %.2f s)" % [key, w["lead"], w["tail"]])
	rep.check("A1", "audio", "format", "PASS" if fmt_bad.is_empty() else "FAIL",
		"%d bad %s" % [fmt_bad.size(), ", ".join(PackedStringArray(fmt_bad.slice(0, 4)))], "mono, 24 kHz, PCM 16-bit",
		"re-render with build force=1")
	rep.check("A2", "audio", "clipping", "PASS" if clipped.is_empty() else "FAIL",
		"none" if clipped.is_empty() else ", ".join(PackedStringArray(clipped.slice(0, 4))), "no sample at full scale",
		"re-render (finish_audio normalises to -1 dBFS)")
	var peak_ok := peak_hi <= 0.95 and peak_lo >= 0.8
	rep.check("A3", "audio", "peak level", "PASS" if peak_ok or entries.is_empty() else "WARN",
		"%.1f..%.1f dBFS" % [linear_to_db(maxf(peak_lo, 1e-6)), linear_to_db(maxf(peak_hi, 1e-6))], "-2..-0.5 dBFS (target -1)",
		"re-render")
	rep.check("A4", "audio", "trimmed", "PASS" if untrimmed.is_empty() else "WARN",
		"%d untrimmed %s" % [untrimmed.size(), ", ".join(PackedStringArray(untrimmed.slice(0, 3)))],
		"lead <= %.2f s, tail <= %.2f s of silence" % [LEAD_MAX, TAIL_MAX], "re-render")
	var mb := bytes_total / 1048576.0
	rep.add("A5", "audio", "size", "PASS" if mb <= 40.0 else "WARN", "%.1f MB source WAV, %.1f min of speech" % [mb, total_s / 60.0],
		"<= 40 MB", "the import is QOA-compressed (~5x smaller in the build)", ToolReport.grade(mb, 60.0, 10.0))
	# Hookup.
	var hud := FileAccess.get_file_as_string("res://scripts/ui/mission/mission_hud.gd") if FileAccess.file_exists("res://scripts/ui/mission/mission_hud.gd") else ""
	var has_player := ResourceLoader.exists("res://scripts/ui/voice_player.gd")
	rep.check("H1", "hook", "VoicePlayer in the mission HUD", "PASS" if has_player and hud.contains("voice_player.gd") else "INFO",
		("script present, " if has_player else "script missing, ") + ("added by MissionHud" if hud.contains("voice_player.gd") else "not added"),
		"DialogueBox child plays the manifest WAV on line_started", "see docs/handoff/for-ui-coder.md")
	var gen: Variant = _read_json("res://docs/tools/voice_forge/out/%s/generate.json" % id)
	if gen is Dictionary:
		rep.notes.append("this build: %s rendered, %s unchanged" % [gen.get("rendered"), gen.get("unchanged")])
		var lr: Variant = (gen as Dictionary).get("last_render", {})
		if lr is Dictionary and not (lr as Dictionary).is_empty():
			rep.notes.append("last render: %s lines, %s s of audio in %s s (x%s real time) on %s, at %s" % [
				lr.get("rendered"), lr.get("audio_s"), lr.get("gen_s"), lr.get("rtf"), lr.get("providers"), lr.get("at")])
	var n_fit := 0
	var n_dir := 0
	for key: String in entries:
		n_fit += 1 if (entries[key] as Dictionary).has("fit") else 0
		n_dir += 1 if (entries[key] as Dictionary).has("direction") else 0
	rep.notes.append("total: %d lines, %.2f min of speech, %d speed-fitted, %d with direction tags" % [entries.size(), total_s / 60.0, n_fit, n_dir])
	if FileAccess.file_exists(MANIFEST):
		rep.hash_value = ToolCli.file_hash(MANIFEST)
		rep.hash_note = "manifest.json (line keys are content hashes)"
	rep.extras.append({"title": "Hold lines as long as their voice", "text": "DialogueBox shows every line 5 s; VoicePlayer.line_duration() lets it wait for the voice (handoff for ui-coder).", "source": "voice_forge"})
	rep.extras.append({"title": "Voice the cinematics", "text": "The cinematic runtime can play manifest WAVs for `line` cues (handoff for systems-coder-high).", "source": "voice_forge"})
	rep.extras.append({"title": "Tune overruns", "text": "Lines over their slot: raise that speaker's speed a little, or give the shot more time.", "source": "voice_forge"})


## Reads a PCM WAV: format, peak, clipped samples, leading / trailing silence (below -40 dB of the peak).
static func _wav_info(path: String) -> Dictionary:
	var b := FileAccess.get_file_as_bytes(path)
	var out := {"ok": false, "bytes": b.size()}
	if b.size() < 44 or b.slice(0, 4).get_string_from_ascii() != "RIFF" or b.slice(8, 12).get_string_from_ascii() != "WAVE":
		return out
	var pos := 12
	var data_at := -1
	var data_len := 0
	while pos + 8 <= b.size():
		var cid := b.slice(pos, pos + 4).get_string_from_ascii()
		var clen := b.decode_u32(pos + 4)
		if cid == "fmt ":
			out["format"] = b.decode_u16(pos + 8)
			out["channels"] = b.decode_u16(pos + 10)
			out["rate"] = b.decode_u32(pos + 12)
			out["bits"] = b.decode_u16(pos + 22)
		elif cid == "data":
			data_at = pos + 8
			data_len = mini(clen, b.size() - data_at)
			break
		pos += 8 + clen + (clen & 1)
	if data_at < 0 or not out.has("bits") or int(out["bits"]) != 16 or int(out["format"]) != 1:
		out["ok"] = data_at >= 0 and out.has("bits")
		out.merge({"channels": out.get("channels", 0), "rate": out.get("rate", 0), "bits": out.get("bits", 0)})
		return out
	var n := data_len / 2
	var peak := 0
	var clip := 0
	var first := -1
	var last := -1
	var absvals := PackedInt32Array()
	absvals.resize(n)
	for i: int in n:
		var v := absi(b.decode_s16(data_at + i * 2))
		absvals[i] = v
		if v > peak:
			peak = v
		if v >= 32767:
			clip += 1
	var thr := maxi(int(peak * 0.01), 1)
	for i: int in n:
		if absvals[i] > thr:
			first = i
			break
	for i: int in range(n - 1, -1, -1):
		if absvals[i] > thr:
			last = i
			break
	var rate := float(out["rate"]) if int(out["rate"]) > 0 else float(SR)
	out["ok"] = true
	out["peak"] = peak / 32767.0
	out["clip"] = clip
	out["lead"] = (first if first >= 0 else n) / rate
	out["tail"] = ((n - 1 - last) if last >= 0 else n) / rate
	out["duration"] = n / rate
	return out

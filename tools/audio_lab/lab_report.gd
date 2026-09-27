extends RefCounted
## Audio Lab (docs/plan/audio-lab.md): turns measures + code facts into checks (PASS / WARN / FAIL / INFO), a score,
## "Improve next", and writes scorecard.md, scorecard.json, listening_sheet.md, preview_cues.json and the
## improvement log line.

const Rules := preload("res://tools/audio_lab/lab_rules.gd")
const LOG_PATH := "res://docs/audio/lab/improvement-log.md"

static var _checks: Array = []
static var _short := ""   ## Set before _add: a per-item detail shown in "Improve next" (e.g. "-8 dB").


static func _add(group: String, item: String, status: String, value: String, rule: String, fix: String = "",
		key: String = "") -> void:
	_checks.append({"group": group, "item": item, "status": status, "value": value, "rule": rule, "fix": fix,
		"key": key if key != "" else rule, "short": _short})
	_short = ""


static func f1(x: Variant) -> String:
	if x == null:
		return "-"
	var v := float(x)
	if is_inf(v):
		return "-inf" if v < 0 else "inf"
	return "%.1f" % v


# ------------------------------------------------------------------ helpers

static func category_of(id: String, path: String, kind: String) -> String:
	if kind != "" and kind != "auto":
		return kind
	if Rules.CATEGORY_BY_ID.has(id):
		return Rules.CATEGORY_BY_ID[id]
	for pr: Array in Rules.CATEGORY_PREFIXES:
		if id.begins_with(pr[0]):
			return pr[1]
	if path.find("/music/") >= 0:
		return "music"
	if path.find("/ambience/") >= 0 or path.find("/amb/") >= 0:
		return "ambience"
	return "unit"


## dB lost at `d` metres by a 3D player (Godot 4 formulas; clamped by max_db 3 dB).
static func att_db(model: Variant, unit_size: float, d: float) -> float:
	var m := str(model)
	var us := maxf(unit_size, 0.01)
	var g := 0.0
	if m.find("SQUARE") >= 0 or m == "1":
		g = 20.0 * log(1.0 / pow(d / us, 2.0)) / log(10.0)
	elif m.find("LOG") >= 0 or m == "2":
		g = -20.0 * log(d / us + 0.00001)
	elif m.find("DISABLED") >= 0 or m == "3":
		g = 0.0
	else:
		g = 20.0 * log(1.0 / (d / us)) / log(10.0)
	return minf(g, 3.0)


static func model_name(v: Variant) -> String:
	if v is int or v is float:
		return ["ATTENUATION_INVERSE_DISTANCE", "ATTENUATION_INVERSE_SQUARE_DISTANCE", "ATTENUATION_LOGARITHMIC",
			"ATTENUATION_DISABLED"][clampi(int(v), 0, 3)]
	return str(v) if v != null else "ATTENUATION_INVERSE_DISTANCE"


# ------------------------------------------------------------------ evaluation

## ctx keys: name, mode, target, kind, cues {id: row}, players [], fight {}, events [], missing_scored, set_bytes.
## A cue row: {id, path, category, meta (code registry entry or {}), m (measures), info, error, generated, rate,
## frequent, level, takes}.
static func evaluate(ctx: Dictionary) -> Dictionary:
	_checks = []
	var cues: Dictionary = ctx["cues"]
	var bed := _battle_bed(ctx.get("bed_cues", cues))
	for id: String in cues:
		_cue_checks(cues[id], bed)
	_family_checks(cues)
	var mem := 0
	for id: String in cues:
		mem += int((cues[id] as Dictionary).get("memory", 0))
	if not cues.is_empty():
		_add("memory", "set", "PASS" if mem <= Rules.SET_MEMORY_WARN else "WARN", "%.1f MB in memory" % (mem / 1.0e6),
			"set <= %d MB" % (Rules.SET_MEMORY_WARN / 1000000), "Stream music as Ogg; compress long SFX (QOA).")
	_player_checks(ctx)
	_voice_checks(ctx)
	_event_checks(ctx)
	# ---- score
	var groups := {}
	for c: Dictionary in _checks:
		var g: String = c["group"]
		if not groups.has(g):
			groups[g] = {"PASS": 0, "WARN": 0, "FAIL": 0, "INFO": 0}
		groups[g][c["status"]] += 1
	var wsum := 0.0
	var ssum := 0.0
	var gscores := {}
	for g: String in groups:
		var d: Dictionary = groups[g]
		var n := int(d["PASS"]) + int(d["WARN"]) + int(d["FAIL"])
		if n == 0:
			continue
		if g == "missing" and not bool(ctx.get("missing_scored", true)):
			continue
		var s := (float(d["PASS"]) + 0.5 * float(d["WARN"])) / n
		gscores[g] = s
		var w := float(Rules.WEIGHTS.get(g, 5.0))
		wsum += w
		ssum += w * s
	var counts := {"PASS": 0, "WARN": 0, "FAIL": 0, "INFO": 0}
	for c: Dictionary in _checks:
		if c["group"] == "missing" and not bool(ctx.get("missing_scored", true)) and c["status"] != "PASS":
			continue
		counts[c["status"]] += 1
	var penalty := minf(Rules.FAIL_PENALTY * float(counts["FAIL"]), Rules.MAX_PENALTY)
	var score := maxi(int(round(100.0 * ssum / wsum - penalty)), 0) if wsum > 0.0 else 0
	return {"checks": _checks.duplicate(true), "groups": groups, "group_scores": gscores, "score": score,
		"counts": counts, "improve": _improve_next(ctx), "bed": bed}


static func _cue_checks(r: Dictionary, bed: Dictionary) -> void:
	var id: String = r["id"]
	var cat: String = r["category"]
	if r.get("error", "") != "":
		_add("memory", id, "WARN", r["error"], "stream decodes", "Re-import the file or check its format.")
		return
	var m: Dictionary = r["m"]
	var info: Dictionary = r["info"]
	var loud: Dictionary = Rules.LOUDNESS[cat]
	var looped := cat in ["music", "ambience"]
	# ---- loudness
	var lo := float(loud["lo"])
	var hi := float(loud["hi"])
	if bool(r.get("frequent", false)) and cat in ["ui", "unit"]:
		lo += Rules.FREQUENT_SHIFT
		hi += Rules.FREQUENT_SHIFT
	var lv := float(r["level"])
	var st := "PASS"
	var fix := ""
	if lv < lo or lv > hi:
		var off := (lo - lv) if lv < lo else (lv - hi)
		st = "WARN" if off <= Rules.LOUDNESS_TOL else "FAIL"
		var tgt := (lo + Rules.LOUDNESS_AIM) if lv < lo else (hi - Rules.LOUDNESS_AIM)
		fix = "%s the in-game level into the range (volume_db in %s, or re-render the file)" % ["Raise" if lv < lo
			else "Lower", str(r["meta"].get("script", "the player")).get_file()]
		_short = "%+.0f dB" % (tgt - lv)
	_add("loudness", id, st, "%s LUFS in game (file %s, vol %s dB, 3D %s dB)" % [f1(lv), f1(r["file_level"]),
		f1(r["meta"].get("volume_db", 0.0)), f1(r["att"])],
		"%s%s: %.0f..%.0f %s" % [cat, " (frequent)" if r.get("frequent", false) else "", lo, hi,
		"integrated" if loud["metric"] == "integrated" else "cue"], fix, "loud_" + ("lo" if lv < lo else "hi"))
	# ---- peaks
	var tp := float(m["true_peak_dbtp"])
	var clipped := int(m["clipped"])
	st = "PASS"
	if clipped > 0 or tp > Rules.TP_FAIL:
		st = "FAIL"
	elif tp > Rules.TP_WARN:
		st = "WARN"
	var fmt := str(info.get("imported_format", ""))
	var sp: Variant = r.get("src_peak_dbfs", null)
	var over := (float(m["peak_dbfs"]) - float(sp)) if sp != null else 0.0
	var tp_fix := "Normalise the file to -1 dBTP (peak), lower the level before export if it clips."
	if st != "PASS":
		if sp != null and over >= Rules.IMPORT_OVERSHOOT_DB:
			tp_fix = ("The %s import adds %+.1f dB (source peak %s dBFS): set Compress > Mode to PCM or IMA-ADPCM in "
				+ "the Import dock (.import compress/mode), or leave that much headroom in the file.") % [fmt, over, f1(sp)]
		elif sp != null:
			tp_fix = "The source file itself peaks at %s dBFS (the import adds %+.1f dB): normalise the file to -1 dBTP." % [
				f1(sp), over]
		elif fmt == "QOA":
			tp_fix += " Imported as QOA, which can overshoot up to ~7 dB on harmonic tones: PCM / IMA-ADPCM import avoids it."
	_add("peaks", id, st, "true peak %s dBTP, %d clipped runs%s" % [f1(tp), clipped, (", source %s dBFS (%s import %+.1f dB)"
		% [f1(sp), fmt, over]) if sp != null else ""], "true peak <= %.0f dBTP, no clipping" % Rules.TP_WARN, tp_fix, "tp")
	if sp != null and over >= Rules.IMPORT_OVERSHOOT_DB and st == "PASS":
		_add("peaks", id, "WARN", "%s import raises the peak %+.1f dB (source %s dBFS, decoded %s dBFS)" % [fmt, over, f1(sp),
			f1(m["peak_dbfs"])], "import changes the peak by < %.0f dB" % Rules.IMPORT_OVERSHOOT_DB,
			"Import as PCM or IMA-ADPCM (Import dock, Compress > Mode): the lossy QOA import is distorting this cue.",
			"import_over")
	if absf(float(m["dc"])) > Rules.DC_WARN:
		_add("peaks", id, "WARN", "DC %.3f" % float(m["dc"]), "|DC| <= %.2f" % Rules.DC_WARN,
			"High-pass at 20 Hz / remove DC offset.", "dc")
	# ---- duration / silence
	var dur := float(m["duration_s"])
	var lead := float(m["lead_ms"])
	var lead_warn := float(Rules.LEAD_WARN_MS.get(cat, 15.0))
	var lead_fail := 2000.0 if looped else Rules.LEAD_FAIL_MS
	st = "PASS" if lead <= lead_warn else ("WARN" if lead <= lead_fail else "FAIL")
	_add("duration", id, st, "lead silence %.0f ms" % lead, "lead <= %.0f ms" % lead_warn,
		"Trim the start (import option edit/trim, or cut the file) so it fires on the frame.", "lead")
	if not looped:
		var trail := float(m["trail_ms"])
		st = "PASS" if trail <= Rules.TRAIL_WARN_MS else ("WARN" if trail <= Rules.TRAIL_FAIL_MS else "FAIL")
		_add("duration", id, st, "trailing silence %.0f ms" % trail, "trail <= %.0f ms" % Rules.TRAIL_WARN_MS,
			"Cut the silent end: GameAudio keeps a voice busy for the whole stream length.", "trail")
		var mx := float(Rules.MAX_DURATION_S.get(cat, 99.0))
		st = "PASS"
		if dur > mx:
			st = "WARN"
		if dur < Rules.MIN_DURATION_S:
			st = "WARN"
		_add("duration", id, st, "%.2f s" % dur, "%s: %.2f..%.1f s" % [cat, Rules.MIN_DURATION_S, mx],
			"Shorten the tail or split into a cue + a separate layer.", "dur")
		var abrupt := float(m["end_db"]) > Rules.END_DB_WARN and float(m["last_abs"]) > Rules.END_SAMPLE
		if abrupt:
			_add("duration", id, "WARN", "ends at %s dB RMS (last sample %.3f)" % [f1(m["end_db"]), float(m["last_abs"])],
				"fade to silence (last 10 ms < %.0f dB)" % Rules.END_DB_WARN, "Add a 5-20 ms fade-out at the end (click).",
				"abrupt")
		if bool(r.get("frequent", false)) and float(m["decay_ms"]) > Rules.FREQUENT_DECAY_MS:
			_add("duration", id, "WARN", "tail %.0f ms" % float(m["decay_ms"]), "frequent cue tail <= %.0f ms"
				% Rules.FREQUENT_DECAY_MS, "Shorten the decay: long tails of frequent cues smear a fight.", "decay")
	else:
		var min_loop := float(Rules.MIN_LOOP_S.get(cat, 20.0))
		_add("duration", id, "PASS" if dur >= min_loop else "WARN", "%.1f s loop" % dur, "%s loop >= %.0f s"
			% [cat, min_loop], "Longer track / more tracks: a short loop repeats dozens of times in a match.", "loop_len")
		var seam := float(m["seam_jump"])
		_add("duration", id, "PASS" if seam <= Rules.SEAM_WARN else "WARN", "loop seam jump %.3f" % seam,
			"|last - first sample| <= %.2f" % Rules.SEAM_WARN,
			"Cut the loop on a zero crossing / crossfade the loop point (click every loop).", "seam")
	if float(m["first_abs"]) > Rules.START_SAMPLE:
		_add("duration", id, "WARN", "first sample %.2f" % float(m["first_abs"]), "starts near 0 (<= %.1f)"
			% Rules.START_SAMPLE, "Add a 1-2 ms fade-in (pop at start).", "pop")
	# ---- spectral
	var b: Dictionary = m["bands"]
	var shares := "low %.0f%% / mid %.0f%% / pres %.0f%% / air %.0f%%" % [100.0 * float(b["low"]),
		100.0 * float(b["mid"]), 100.0 * float(b["presence"]), 100.0 * float(b["air"])]
	if not looped:
		st = "PASS"
		var why := ""
		var bkey := "balance"
		if float(b["low"]) >= Rules.ALL_BASS:
			st = "WARN"
			bkey = "bass"
			why = "Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix."
		elif float(b["air"]) >= Rules.ALL_HISS_AIR:
			st = "WARN"
			bkey = "hiss"
			why = "Tame > 6 kHz (low-pass / de-ess): all-hiss cues are harsh and tiring."
		elif cat == "ui" and float(b["presence"]) + float(b["air"]) < Rules.UI_THIN:
			st = "WARN"
			bkey = "thin"
			why = "Add 2-5 kHz content so the UI cue reads on small speakers."
		_add("spectral", id, st, shares, "not all-bass (< %.0f%% low), not all-hiss (< %.0f%% air)"
			% [100.0 * Rules.ALL_BASS, 100.0 * Rules.ALL_HISS_AIR], why, bkey)
	if cat == "alert" and not bed.is_empty():
		var best := -INF
		var best_band := ""
		for band: String in b:
			var share := float(b[band])
			if share < Rules.MASK_MIN_SHARE:
				continue
			var mine := lv + 10.0 * log(share) / log(10.0)
			var margin := mine - float(bed[band])
			if margin > best:
				best = margin
				best_band = band
		st = "PASS" if best >= Rules.MASK_PASS else ("WARN" if best >= Rules.MASK_FAIL else "FAIL")
		_add("spectral", id, st, "beats the battle bed by %s dB (%s band)" % [f1(best), best_band if best_band != ""
			else "-"], "alert >= +%.0f dB over %d combat voices in one band" % [Rules.MASK_PASS, Rules.BED_VOICES],
			"Give it energy where the fight is thin (2-5 kHz presence), or +%.0f dB; a distinct pitch contour helps."
			% maxf(Rules.MASK_PASS - best, 1.0), "mask")
	# ---- memory / format
	var rate := int(info.get("src_rate", 0))
	if rate > 0 and rate < Rules.RATE_FAIL:
		_add("memory", id, "FAIL", "%d Hz" % rate, ">= %d Hz" % Rules.RATE_FAIL, "Re-render at 44.1 / 48 kHz.", "rate")
	var mode: String = r["meta"].get("mode", "")
	var stereo := int(info.get("src_channels", 1)) == 2 and not bool(m.get("dual_mono", false))
	if mode == "3d" and stereo:
		_add("memory", id, "WARN", "stereo file on a 3D player", "3D cues are mono",
			"Export mono: half the memory, and 3D panning places it correctly.", "stereo3d")
	var bytes := int(info.get("disk_bytes", 0))
	var lim_w := Rules.MUSIC_FILE_WARN if looped else Rules.SFX_FILE_WARN
	st = "PASS" if bytes <= lim_w else ("WARN" if looped or bytes <= Rules.SFX_FILE_FAIL else "FAIL")
	_add("memory", id, st, "%.0f KB on disk, %s %s Hz %s" % [bytes / 1024.0, info.get("imported_format", "?"),
		str(info.get("imported_rate", rate)), "stereo" if stereo else "mono"], "file <= %.0f KB" % (lim_w / 1024.0),
		"Use Ogg Vorbis for music / long loops; trim or compress (QOA) long SFX.", "size")
	if r.get("orphan", false):
		_add("memory", id, "WARN", "no code plays it", "every file in the set is used",
			"Wire it up (see Missing cues) or delete it.", "orphan")
	# ---- variation (frequent cues only; a take is judged with its parent cue)
	if not looped and not r.has("take_of"):
		var takes := int(r.get("takes", 1))
		var pitch := float(r["meta"].get("pitch", 0.0))
		var vr := bool(r["meta"].get("vol_rand", false))
		var rand_txt := "%d take(s), pitch +-%.0f%%%s" % [takes, pitch * 100.0, ", volume random" if vr else ""]
		if not bool(r.get("frequent", false)):
			_add("variation", id, "PASS", rand_txt + ", ~%.0f/min" % float(r.get("rate", 0.0)),
				"occasional cue (< %.0f/min): one take is fine" % Rules.FREQUENT_PER_MIN)
		elif cat == "ui":
			_add("variation", id, "PASS", rand_txt + ", ~%.0f/min" % float(r.get("rate", 0.0)),
				"UI cues stay identical on purpose (consistency)")
		else:
			var has_rand := pitch >= Rules.PITCH_MIN or vr
			if takes >= Rules.TAKES_GOOD or (takes >= 2 and has_rand):
				st = "PASS"
			elif has_rand or takes >= 2:
				st = "WARN"
			else:
				st = "FAIL"
			_add("variation", id, st, rand_txt + ", ~%.0f/min" % float(r.get("rate", 0.0)),
				"frequent cue: >= %d takes, or 2 takes + pitch / volume randomisation" % Rules.TAKES_GOOD,
				"Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer)%s." % [
				"" if has_rand else " and randomise pitch +-5 % in the play function"],
				"var_" + st)


## Band levels of the battle bed: unit cues at their in-game level, BED_VOICES at once (energy average + sum).
static func _battle_bed(cues: Dictionary) -> Dictionary:
	var acc := {"low": 0.0, "mid": 0.0, "presence": 0.0, "air": 0.0}
	var n := 0
	for id: String in cues:
		var r: Dictionary = cues[id]
		if r.get("category", "") != "unit" or r.get("error", "") != "" or not r.has("m"):
			continue
		var b: Dictionary = r["m"]["bands"]
		var p := pow(10.0, float(r["level"]) / 10.0)
		for band: String in acc:
			acc[band] = float(acc[band]) + p * float(b[band])
		n += 1
	if n == 0:
		return {}
	var out := {}
	for band: String in acc:
		var avg := float(acc[band]) / n
		out[band] = (10.0 * log(avg) / log(10.0) if avg > 0.0 else -120.0) + 10.0 * log(float(Rules.BED_VOICES)) / log(10.0)
	return out


static func _family_checks(cues: Dictionary) -> void:
	for fam in Rules.FAMILIES:
		var ids: Array = []
		for id: String in cues:
			if id.begins_with(fam) and (cues[id] as Dictionary).get("error", "") == "":
				ids.append(id)
		if ids.size() < 2:
			continue
		var lo := INF
		var hi := -INF
		for id: String in ids:
			lo = minf(lo, float(cues[id]["level"]))
			hi = maxf(hi, float(cues[id]["level"]))
		_add("loudness", fam + "*", "PASS" if hi - lo <= Rules.FAMILY_TOL else "WARN",
			"spread %.1f dB (%s)" % [hi - lo, ", ".join(ids)], "same-role cues within %.0f dB" % Rules.FAMILY_TOL,
			"Match the family levels (VOLUMES in the playing script) so no faction sounds louder.", "family")
	# Takes of one cue (<id>, <id>_1, <id>_2) are picked at random: one louder take pops out of the mix.
	var takes_of := {}
	for id: String in cues:
		var c: Dictionary = cues[id]
		if c.has("take_of") and c.get("error", "") == "" and c.has("level"):
			var p: String = c["take_of"]
			if not takes_of.has(p):
				takes_of[p] = []
				if cues.has(p) and (cues[p] as Dictionary).get("error", "") == "" and (cues[p] as Dictionary).has("level"):
					(takes_of[p] as Array).append(p)
			(takes_of[p] as Array).append(id)
	for p: String in takes_of:
		var ids: Array = takes_of[p]
		if ids.size() < 2:
			continue
		var lo := INF
		var hi := -INF
		for id: String in ids:
			lo = minf(lo, float(cues[id]["level"]))
			hi = maxf(hi, float(cues[id]["level"]))
		_add("loudness", p + " takes", "PASS" if hi - lo <= Rules.TAKE_TOL else "WARN",
			"spread %.1f dB (%s)" % [hi - lo, ", ".join(ids)], "takes of one cue within %.1f dB" % Rules.TAKE_TOL,
			"Re-level the takes (or re-render them) so a random pick never jumps out of the mix.", "take_spread")


static func _player_checks(ctx: Dictionary) -> void:
	var allowed: Array = ctx["allowed_buses"]
	for p: Dictionary in ctx["players"]:
		var pr: Dictionary = p["props"]
		var bus := str(pr.get("bus", "Master"))
		var where: String = p["where"]
		var st := "PASS"
		var fix := ""
		if bus == "Master":
			st = "FAIL"
			fix = "Set `bus = &\"SFX\"` (or \"Music\"): on Master the SFX / Music sliders don't reach it."
		elif bus.begins_with("?") or not allowed.has(bus):
			st = "FAIL" if not bus.begins_with("?") else "WARN"
			fix = "Use one of the buses GameSettings creates (%s); an unknown bus falls back to Master." % ", ".join(allowed)
		_add("bus", where, st, "%s on bus %s" % [p["class"], bus], "bus in %s" % ", ".join(allowed), fix, "bus")
		var stream := str(pr.get("stream", ""))
		if stream.find("music") >= 0 and bus != "Music" and allowed.has("Music"):
			_add("bus", where, "WARN", "music stream on %s" % bus, "music on the Music bus", "Route music to Music.",
				"music_bus")
		if not str(p["class"]).ends_with("3D"):
			continue
		var us := float(pr.get("unit_size", 10.0)) if (pr.get("unit_size", 10.0) is float) else 10.0
		var md := float(pr.get("max_distance", 0.0)) if (pr.get("max_distance", 0.0) is float) else 0.0
		var model := model_name(pr.get("attenuation_model", 0))
		var g_ref := att_db(model, us, Rules.REF_DISTANCE)
		var g_far := att_db(model, us, Rules.CAMERA_RANGE.y)
		var g_cut := att_db(model, us, md) if md > 0.0 else -INF
		var probs: Array[String] = []
		var fixes: Array[String] = []
		st = "PASS"
		if model.find("DISABLED") >= 0:
			st = "WARN"
			probs.append("no attenuation")
			fixes.append("use ATTENUATION_INVERSE_DISTANCE")
		if us < Rules.MIN_UNIT_SIZE:
			st = "WARN"
			probs.append("unit_size %.0f < %.0f (camera is 10-55 m away)" % [us, Rules.MIN_UNIT_SIZE])
			fixes.append("raise unit_size to 12-20")
		if md <= 0.0:
			st = "WARN"
			probs.append("max_distance 0 = heard map-wide")
			fixes.append("set max_distance 60-90")
		elif md < Rules.MAX_DISTANCE_RANGE.x or md > Rules.MAX_DISTANCE_RANGE.y:
			st = "WARN"
			probs.append("max_distance %.0f outside %.0f-%.0f" % [md, Rules.MAX_DISTANCE_RANGE.x, Rules.MAX_DISTANCE_RANGE.y])
			fixes.append("max_distance 60-90")
		if g_cut > Rules.CUTOFF_GAIN_MAX:
			st = "WARN"
			probs.append("still %s dB at the %.0f m cut-off (audible pop-out)" % [f1(g_cut), md])
			fixes.append("lower unit_size or raise max_distance")
		if g_ref < Rules.REF_GAIN_MIN:
			st = "WARN"
			probs.append("%s dB at %.0f m (default zoom)" % [f1(g_ref), Rules.REF_DISTANCE])
			fixes.append("raise unit_size")
		if str(pr.get("doppler_tracking", "")).find("PHYSICS") >= 0 or str(pr.get("doppler_tracking", "")).find("IDLE") >= 0:
			st = "WARN"
			probs.append("doppler on (camera pans fast = pitch warble)")
			fixes.append("DOPPLER_TRACKING_DISABLED")
		_add("3d", where, st, "unit_size %.0f, max_distance %.0f, %s; %s dB @%.0f m, %s dB @%.0f m, %s dB @cut"
			% [us, md, model.replace("ATTENUATION_", "").to_lower(), f1(g_ref), Rules.REF_DISTANCE, f1(g_far),
			Rules.CAMERA_RANGE.y, f1(g_cut)], "; ".join(probs) if not probs.is_empty() else
			"gain >= %.0f dB at %.0f m, <= %.0f dB at the cut-off" % [Rules.REF_GAIN_MIN, Rules.REF_DISTANCE,
			Rules.CUTOFF_GAIN_MAX], ", ".join(fixes), "3d")


static func _voice_checks(ctx: Dictionary) -> void:
	var pools := {}
	var n3 := 0
	for p: Dictionary in ctx["players"]:
		if str(p["class"]).ends_with("3D"):
			n3 += 1
		pools[str(p.get("script", "")).get_file()] = int(pools.get(str(p.get("script", "")).get_file(), 0)) + 1
	var pool_note := str(ctx.get("pool_note", ""))
	var total := int(ctx.get("pool_total", ctx["players"].size()))
	var p3 := int(ctx.get("pool_3d", n3))
	if total > 0:
		_add("voices", "players", "PASS" if total <= Rules.PLAYERS_WARN else "WARN", "%d players (%d 3D) %s" % [total,
			p3, pool_note], "<= %d players, 3D pool <= %d" % [Rules.PLAYERS_WARN, Rules.POOL_3D_MAX],
			"Pool players (one pool per system) instead of one per source.", "pool")
		if p3 > Rules.POOL_3D_MAX:
			_add("voices", "3D pool", "WARN", "%d 3D players" % p3, "3D voices <= %d" % Rules.POOL_3D_MAX,
				"Shrink the pool; steal the oldest voice for priority cues.", "pool3d")
	var cues: Dictionary = ctx["cues"]
	for id: String in cues:
		var r: Dictionary = cues[id]
		if not bool(r.get("frequent", false)) or r["meta"].is_empty():
			continue
		var rl: Variant = r["meta"].get("rate_limit_s")
		var ok := rl != null and float(rl) >= Rules.MIN_RATE_LIMIT_S
		_add("voices", id, "PASS" if ok else "FAIL", "rate limit %s s" % (f1(rl) if rl != null else "none"),
			"frequent cue has a per-cue cooldown >= %.2f s" % Rules.MIN_RATE_LIMIT_S,
			"Add a cooldown (GameAudio.COOLDOWNS) so 50 units don't stack the same sound.", "ratelimit")
	var fight: Dictionary = ctx.get("fight", {})
	if not fight.is_empty():
		var sat := float(fight.get("saturation", 0.0))
		var played := int(fight.get("played", 0))
		var dropped := int(fight.get("dropped", 0))
		var drop_share := float(dropped) / maxf(float(played + dropped), 1.0)
		_add("voices", "fight: size", "PASS" if played >= 40 else "WARN", "%d cue plays in %.0f s" % [played,
			float(fight.get("seconds", 0.0))], ">= 40 plays (else expected rates are used)",
			"Fight not representative: check the units reach each other in view of the camera (fight_s=60).", "fight_size")
		_add("voices", "fight: pool saturation", "PASS" if sat <= Rules.SATURATION_WARN else "WARN",
			"all %d 3D voices busy %.0f%% of the fight (peak %d)" % [int(fight.get("voices", 0)), sat * 100.0,
			int(fight.get("peak", 0))], "<= %.0f%% of frames" % (Rules.SATURATION_WARN * 100.0),
			"Shorter streams (trim tails) or longer cooldowns for the most played cues.", "saturation")
		_add("voices", "fight: dropped", "PASS" if drop_share <= Rules.DROP_WARN else "WARN",
			"%d dropped / %d played" % [dropped, played], "dropped <= %.0f%%" % (Rules.DROP_WARN * 100.0),
			"Raise MAX_VOICES a little or mark key cues PRIORITY.", "dropped")


static func _event_checks(ctx: Dictionary) -> void:
	for e: Dictionary in ctx.get("events", []):
		var st := "PASS"
		var val := "covered: " + str(e["via"])
		var fix := ""
		match e["status"]:
			"covered":
				st = "PASS"
			"partial":
				st = "WARN" if e["core"] else "INFO"
				val = "partly: " + str(e["via"])
				fix = "Hook the event's signal (%s) to a cue." % ", ".join(e["signals_found"])
			"missing":
				st = "FAIL" if e["core"] else "INFO"
				val = "no sound (signal %s exists)" % ", ".join(e["signals_found"]) if not (e["signals_found"] as Array).is_empty() else "no sound"
				fix = "Add a cue and hook it (ui-coder, GameAudio or the system's popups script)."
			"design_gap":
				st = "WARN" if e["core"] else "INFO"
				val = "not in the game yet (no event to hook)"
				fix = "Needs a design (game-designer / ui-designer) + a cue."
			"absent":
				st = "INFO"
				val = "event not in the game yet"
		_add("missing", "%s (%s)" % [e["label"], "core" if e["core"] else "nice"], st, val, "every key event has a sound",
			fix, "ev_" + str(e["status"]) + ("_core" if e["core"] else ""))


# ------------------------------------------------------------------ improve next

static func _improve_next(ctx: Dictionary) -> Array:
	var buckets := {}   # key -> {status, group, fix, items[]}
	for c: Dictionary in _checks:
		if not (c["status"] in ["FAIL", "WARN"]) or str(c["fix"]) == "":
			continue
		if c["group"] == "missing" and not bool(ctx.get("missing_scored", true)):
			continue
		var k := "%s|%s|%s" % [c["group"], c["key"], c["status"]]
		if not buckets.has(k):
			buckets[k] = {"status": c["status"], "group": c["group"], "fix": c["fix"], "items": [], "rule": c["rule"]}
		var sh := str(c.get("short", ""))
		(buckets[k]["items"] as Array).append(str(c["item"]) + (" " + sh if sh != "" else ""))
	var list: Array = buckets.values()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := (100.0 if a["status"] == "FAIL" else 10.0) * float(Rules.WEIGHTS.get(a["group"], 5.0)) * sqrt(float((a["items"] as Array).size()))
		var pb := (100.0 if b["status"] == "FAIL" else 10.0) * float(Rules.WEIGHTS.get(b["group"], 5.0)) * sqrt(float((b["items"] as Array).size()))
		return pa > pb)
	var out := []
	for b: Dictionary in list:
		var items: Array = b["items"]
		var shown := ", ".join(items.slice(0, 6)) + (" (+%d more)" % (items.size() - 6) if items.size() > 6 else "")
		out.append("**%s %s** - %s  _(%s; %s)_" % [b["status"], Rules.GROUP_TITLES.get(b["group"], b["group"]), b["fix"],
			shown, b["rule"]])
		if out.size() >= 8:
			break
	# Always at least 3: then the real-replacement needs of the categories in the set.
	var cats := {}
	var generated := 0
	for id: String in ctx["cues"]:
		cats[ctx["cues"][id]["category"]] = true
		if str(ctx["cues"][id].get("generated", "")) != "":
			generated += 1
	if generated > 0:
		out.append("**Replace placeholders** - %d of %d files are generated tones (see \"What a real replacement needs\"); start with the most played cues (combat hits, shots, deaths) and the alerts." % [generated, ctx["cues"].size()])
	for cat: String in cats:
		if out.size() >= 3:
			break
		out.append("**Polish %s** - %s" % [cat, Rules.REPLACEMENT_SPEC[cat]])
	if out.size() < 3:
		out.append("**Listen in context** - run the preview (tools/audio_lab/audio_lab_preview.tscn) and fill the listening sheet; numbers can't judge taste.")
	if out.size() < 3:
		out.append("**Measure a real fight** - rerun with `scene=res://scenes/skirmish.tscn fight=1` to replace the expected play rates with measured ones.")
	return out


# ------------------------------------------------------------------ writing

static func write(ctx: Dictionary, res: Dictionary, out_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	_write_json(ctx, res, out_dir.path_join("scorecard.json"))
	_write_md(ctx, res, out_dir.path_join("scorecard.md"))
	_write_sheet(ctx, out_dir.path_join("listening_sheet.md"))
	_write_preview(ctx, out_dir.path_join("preview_cues.json"))
	if bool(ctx.get("log", true)):
		_append_log(ctx, res, out_dir)


static func _jsonable(v: Variant) -> Variant:
	if v is float:
		return null if is_inf(v) or is_nan(v) else snappedf(v, 0.001)
	if v is Dictionary:
		var d := {}
		for k in v:
			d[str(k)] = _jsonable(v[k])
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(_jsonable(x))
		return a
	if v is StringName:
		return str(v)
	return v


static func _write_json(ctx: Dictionary, res: Dictionary, path: String) -> void:
	var cues := {}
	for id: String in ctx["cues"]:
		var r: Dictionary = ctx["cues"][id]
		cues[id] = {"path": r["path"], "category": r["category"], "level": r.get("level"), "file_level":
			r.get("file_level"), "att_3d": r.get("att"), "frequent": r.get("frequent", false), "rate_per_min":
			r.get("rate", 0.0), "takes": r.get("takes", 1), "generated": r.get("generated", ""), "measures":
			r.get("m", {}), "file": r.get("info", {}), "code": r.get("meta", {}), "error": r.get("error", "")}
	var doc := {"name": ctx["name"], "date": Time.get_datetime_string_from_system(), "command": ctx["command"],
		"mode": ctx["mode"], "target": ctx["target"], "kind": ctx["kind"], "score": res["score"], "counts":
		res["counts"], "group_scores": res["group_scores"], "improve_next": res["improve"], "checks": res["checks"],
		"cues": cues, "players": ctx["players"], "events": ctx.get("events", []), "fight": ctx.get("fight", {}),
		"battle_bed_band_db": res["bed"], "rules": {"loudness": Rules.LOUDNESS, "ref_distance": Rules.REF_DISTANCE}}
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(_jsonable(doc), "\t"))
	f.close()


static func _md_escape(s: Variant) -> String:
	return str(s).replace("|", "\\|").replace("\n", " ")


static func _write_md(ctx: Dictionary, res: Dictionary, path: String) -> void:
	var L: PackedStringArray = []
	var c: Dictionary = res["counts"]
	L.append("# Audio Lab scorecard: %s" % ctx["name"])
	L.append("")
	L.append("- Date: %s" % Time.get_datetime_string_from_system(false, true))
	L.append("- Command: `%s`" % ctx["command"])
	L.append("- %s: `%s`, kind `%s`, %d cues, %d players judged" % [ctx["mode"], ctx["target"], ctx["kind"],
		ctx["cues"].size(), ctx["players"].size()])
	if not bool(ctx.get("missing_scored", true)):
		L.append("- Missing cues are listed for context but not scored (set is not the whole game; use scene= or set=res://assets/audio).")
	L.append("")
	L.append("## Score: %d / 100" % res["score"])
	L.append("")
	L.append("PASS %d | WARN %d | FAIL %d | INFO %d" % [c["PASS"], c["WARN"], c["FAIL"], c["INFO"]])
	L.append("")
	L.append("| Group | Weight | PASS | WARN | FAIL | INFO | Group score |")
	L.append("|---|---|---|---|---|---|---|")
	for g in Rules.GROUPS:
		if not res["groups"].has(g):
			continue
		var d: Dictionary = res["groups"][g]
		L.append("| %s | %d | %d | %d | %d | %d | %s |" % [Rules.GROUP_TITLES[g], int(Rules.WEIGHTS[g]), d["PASS"],
			d["WARN"], d["FAIL"], d["INFO"], ("%.0f %%" % (100.0 * float(res["group_scores"][g]))) if
			res["group_scores"].has(g) else "not scored"])
	L.append("")
	L.append("## Improve next")
	L.append("")
	var i := 1
	for s: String in res["improve"]:
		L.append("%d. %s" % [i, s])
		i += 1
	L.append("")
	L.append("## Checks")
	for g in Rules.GROUPS:
		var rows: Array = res["checks"].filter(func(x: Dictionary) -> bool: return x["group"] == g)
		if rows.is_empty():
			continue
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var o := {"FAIL": 0, "WARN": 1, "PASS": 2, "INFO": 3}
			return int(o[a["status"]]) < int(o[b["status"]]))
		L.append("")
		L.append("### %s" % Rules.GROUP_TITLES[g])
		L.append("")
		L.append("| Status | Item | Measured | Rule | Fix hint |")
		L.append("|---|---|---|---|---|")
		for r: Dictionary in rows:
			L.append("| %s | %s | %s | %s | %s |" % [r["status"], _md_escape(r["item"]), _md_escape(r["value"]),
				_md_escape(r["rule"]), _md_escape(r["fix"]) if r["status"] != "PASS" else ""])
	L.append("")
	L.append("## Cue table")
	L.append("")
	L.append("| Cue | Cat | Mode | In game | File | Vol dB | 3D dB | TP dBTP | Dur s | Lead / trail ms | Bands L/M/P/A % | Rate /min | Takes | Pitch | Source |")
	L.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
	for id: String in ctx["cues"]:
		var r: Dictionary = ctx["cues"][id]
		if r.get("error", "") != "":
			L.append("| %s | %s | - | error: %s |||||||||||| " % [id, r["category"], _md_escape(r["error"])])
			continue
		var m: Dictionary = r["m"]
		var b: Dictionary = m["bands"]
		L.append("| %s | %s | %s | %s | %s | %s | %s | %s | %.2f | %.0f / %.0f | %.0f/%.0f/%.0f/%.0f | %.0f%s | %d | %s | %s |" % [id,
			r["category"], r["meta"].get("mode", "-") if r["meta"].get("mode", "") != "" else "-", f1(r["level"]),
			f1(r["file_level"]), f1(r["meta"].get("volume_db", 0.0)), f1(r["att"]), f1(m["true_peak_dbtp"]),
			float(m["duration_s"]), float(m["lead_ms"]), float(m["trail_ms"]), 100.0 * float(b["low"]),
			100.0 * float(b["mid"]), 100.0 * float(b["presence"]), 100.0 * float(b["air"]), float(r.get("rate", 0.0)),
			"*" if r.get("frequent", false) else "", int(r.get("takes", 1)),
			("+-%.0f%%" % (100.0 * float(r["meta"].get("pitch", 0.0)))) if float(r["meta"].get("pitch", 0.0)) > 0.0 else "-",
			"generated" if str(r.get("generated", "")) != "" else "file"])
	L.append("")
	L.append("In game = file loudness (cue: 200 ms max; music / ambience: integrated) + the code's volume_db + 3D loss at %.0f m (default zoom), on 0 dB buses. `*` = frequent (>= %.0f plays / min). Rates are %s." % [Rules.REF_DISTANCE, Rules.FREQUENT_PER_MIN, "measured in a staged fight" if not ctx.get("fight", {}).is_empty() else "expected (lab table; `fight=1` measures them)"])
	L.append("")
	L.append("## Targets (lab_rules.gd LOUDNESS)")
	L.append("")
	L.append("| Category | Metric | In-game range LUFS | Frequent range | Why |")
	L.append("|---|---|---|---|---|")
	for cat: String in Rules.LOUDNESS:
		var t: Dictionary = Rules.LOUDNESS[cat]
		var fr := "%.0f..%.0f" % [float(t["lo"]) + Rules.FREQUENT_SHIFT, float(t["hi"]) + Rules.FREQUENT_SHIFT] if cat in ["ui", "unit"] else "-"
		L.append("| %s | %s | %.0f..%.0f | %s | %s |" % [cat, t["metric"], t["lo"], t["hi"], fr, t["why"]])
	L.append("")
	L.append("## What a real replacement needs")
	L.append("")
	var cats := {}
	var gen := 0
	for id: String in ctx["cues"]:
		cats[ctx["cues"][id]["category"]] = true
		if str(ctx["cues"][id].get("generated", "")) != "":
			gen += 1
	if gen > 0:
		L.append("%d / %d files are generated placeholders (sine / noise tones from a generator script). The numbers above judge the level, timing and routing they give the mix; a real sound must keep those and add:" % [gen, ctx["cues"].size()])
		L.append("")
	for cat: String in cats:
		L.append("- **%s**: %s" % [cat, Rules.REPLACEMENT_SPEC[cat]])
	L.append("- Every file: original or CC0 only (note the source in the file's folder), 16-bit WAV for SFX / Ogg for music, no clipping, trimmed start, faded end.")
	L.append("")
	L.append("## Limits")
	L.append("")
	L.append("- Loudness is a BS.1770 approximation on the 44.1 kHz decode (dual mono counted as 2 channels, as the game plays it); true peak is a 4x interpolation estimate.")
	L.append("- Masking uses 4 bands and a synthetic battle bed (%d unit cues at once), not a real mix; listen in the preview." % Rules.BED_VOICES)
	L.append("- Code facts come from patterns (DIR / DICT / PATH consts, `*.new()` players) and, for scene=, the live players; a sound played in an unusual way can be missed.")
	L.append("- Numbers can't judge taste, timbre or meaning: fill the listening sheet.")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(L) + "\n")
	f.close()


static func _write_sheet(ctx: Dictionary, path: String) -> void:
	var L: PackedStringArray = []
	L.append("# Listening sheet: %s" % ctx["name"])
	L.append("")
	L.append("Play: `godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=%s` (windowed). Keys: Right / Left = next / previous cue, Space = play again, A = auto-play all, B = battle bed on / off, M = music on / off, 1-3 = bed intensity. Each cue plays over its context: battle (staged fight around the camera), ui (menu music), map (ambience)." % path.get_base_dir().path_join("preview_cues.json"))
	L.append("")
	L.append("Mark each line: OK / too loud / too quiet / masked / annoying / wrong meaning, and write a note.")
	L.append("")
	L.append("| # | Cue | Cat | Context | When it plays | In game LUFS | Listen for | Verdict | Notes |")
	L.append("|---|---|---|---|---|---|---|---|---|")
	var i := 1
	for id: String in ctx["cues"]:
		var r: Dictionary = ctx["cues"][id]
		var trig: Array = r["meta"].get("triggers", [])
		L.append("| %d | %s | %s | %s | %s | %s | %s | | |" % [i, id, r["category"], Rules.CONTEXT[r["category"]],
			_md_escape(", ".join(trig) if not trig.is_empty() else ("not played by code" if r.get("orphan", false) else "-")),
			f1(r.get("level")), Rules.LISTEN_FOR[r["category"]]])
		i += 1
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(L) + "\n")
	f.close()


static func _write_preview(ctx: Dictionary, path: String) -> void:
	var arr := []
	for id: String in ctx["cues"]:
		var r: Dictionary = ctx["cues"][id]
		arr.append({"id": id, "path": r["path"], "category": r["category"], "context": Rules.CONTEXT[r["category"]],
			"mode": r["meta"].get("mode", "2d"), "volume_db": r["meta"].get("volume_db", 0.0), "pitch":
			r["meta"].get("pitch", 0.0), "bus": r["meta"].get("bus", "SFX"), "level": r.get("level"), "unit_size":
			r["meta"].get("unit_size"), "max_distance": r["meta"].get("max_distance")})
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(_jsonable({"name": ctx["name"], "cues": arr}), "\t"))
	f.close()


static func _append_log(ctx: Dictionary, res: Dictionary, out_dir: String) -> void:
	var abs_log := ProjectSettings.globalize_path(LOG_PATH)
	DirAccess.make_dir_recursive_absolute(abs_log.get_base_dir())
	var existing := ""
	if FileAccess.file_exists(LOG_PATH):
		var r := FileAccess.open(LOG_PATH, FileAccess.READ)
		existing = r.get_as_text()
		r.close()
	else:
		existing = "# Audio Lab improvement log\n\nEach run of tools/audio_lab/audio_lab.gd appends one entry (newest last): asset set, score, counts, top suggestions. Audio agents: compare before / after here.\n"
	var c: Dictionary = res["counts"]
	var L: PackedStringArray = []
	L.append("")
	L.append("## %s - %s (%s `%s`, kind %s)" % [Time.get_datetime_string_from_system(false, true), ctx["name"],
		ctx["mode"], ctx["target"], ctx["kind"]])
	L.append("")
	L.append("- Score **%d / 100** - PASS %d, WARN %d, FAIL %d, INFO %d; %d cues; scorecard `%s`" % [res["score"],
		c["PASS"], c["WARN"], c["FAIL"], c["INFO"], ctx["cues"].size(), out_dir.path_join("scorecard.md")])
	var i := 0
	for s: String in res["improve"]:
		L.append("- Next %d: %s" % [i + 1, s])
		i += 1
		if i >= 3:
			break
	var w := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	w.store_string(existing.strip_edges(false, true) + "\n" + "\n".join(L) + "\n")
	w.close()

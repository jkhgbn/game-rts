extends RefCounted
## Music Forge core (docs/design/music.md 5): reads a score (tools/music_forge/scores/<id>.json), turns it into
## humanised note events, renders every part, mixes, adds the room, folds the loop seam and masters the result.
##
## Score format (JSON):
##   meta: id, title, mood, bpm, meter [n, d], bars, key, mode, lead, loop (true; stings false), seed, excerpt_bar,
##         lufs (target, default -12), room {size, damp, wet_db}, sections [{name, bar, bars}], dyn [[bar, x], ...]
##   phrases: {name: "D4:1 A4:1 ..."}   reused in note strings as $name
##   parts: [{name, inst, gain_db, send (reverb), pad (support only, counted in pad share), gate, vel, transpose,
##            section / vowel / vowel_to / tremolo / muted / bright (instrument options), eq [[kind, fc, q, dB]],
##            kit {letter: [inst, vel, midi]} (drums), seq: [segment, ...]}]
##   segment: {bar, vel, vel_to, transpose, opt {...}, and ONE of:
##     notes: "D4:1 A4:1 G4:.5 | r:2 D4+F4:2"   (| = bar line, checked; r = rest; + = chord; suffix ! accent,
##            _ soft, ' staccato, ~ legato, * roll; prefix (E5) = 40 ms grace note), repeat
##     chords: "Dm:4 | Bb:2 C:2" + style arp {pattern, step} / hold {voicing} / strum {rhythm, voicing} /
##            bass {rhythm} / hits {grid, pattern, voicing}; oct = chord root octave
##     pattern / patterns (drum grid per bar, kit letters, upper case = accent, . = rest), bars, fill, fill_every}
## Durations are in beats of the meter's unit (quarter for x/4, eighth for x/8; 6/8 bpm = dotted quarter).

const Dsp := preload("res://tools/music_forge/dsp.gd")
const Instruments := preload("res://tools/music_forge/instruments.gd")
const Humanise := preload("res://tools/music_forge/humanise.gd")
const Reverb := preload("res://tools/music_forge/reverb.gd")

const RATE := 22050
const FORGE_VERSION := "mf1.0"
const DOC_KEYS := ["title", "use", "mood", "instruments", "listen_for", "excerpt_note", "sections"]
const PRE_S := 0.25
const TAIL_S := 7.0
const NOTE_NAMES := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const CHORD_IVS := {
	"": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10], "maj7": [0, 4, 7, 11],
	"sus2": [0, 2, 7], "sus4": [0, 5, 7], "dim": [0, 3, 6], "5": [0, 7], "add9": [0, 4, 7, 14], "madd9": [0, 3, 7, 14],
	"aug": [0, 4, 8],
}

var warnings: PackedStringArray = []


# ---------------------------------------------------------------- score

static func load_score(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if not (data is Dictionary):
		return {}
	var d: Dictionary = data
	# hash = the musical content only: doc fields (title, notes for the listening sheet) never force a re-render
	var music := d.duplicate(true)
	for k in DOC_KEYS:
		music.erase(k)
	d["_hash"] = (JSON.stringify(music, "", true) + FORGE_VERSION).md5_text()
	return d


static func meter_of(score: Dictionary) -> Vector2i:
	var m: Array = score.get("meter", [4, 4])
	return Vector2i(int(m[0]), int(m[1]))


## Seconds per beat unit.
static func spu(score: Dictionary) -> float:
	var m := meter_of(score)
	var s := 60.0 / float(score.get("bpm", 120))
	return s / 3.0 if m.y == 8 else s


static func length_samples(score: Dictionary) -> int:
	var m := meter_of(score)
	return int(round(float(score.get("bars", 1)) * m.x * spu(score) * RATE))


static func length_exact(score: Dictionary) -> bool:
	var m := meter_of(score)
	var v := float(score.get("bars", 1)) * m.x * spu(score) * RATE
	return absf(v - round(v)) < 1e-6


static func midi_of(name: String) -> int:
	var pc: int = NOTE_NAMES.get(name.substr(0, 1).to_upper(), 0)
	var i := 1
	while i < name.length() and (name[i] == "#" or name[i] == "b"):
		pc += 1 if name[i] == "#" else -1
		i += 1
	var octave := int(name.substr(i))
	return pc + 12 * (octave + 1)


func _expand(text: String, phrases: Dictionary) -> String:
	var out := text
	for _pass in 4:
		if not out.contains("$"):
			break
		var keys := phrases.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a).length() > str(b).length())
		for k in keys:
			out = out.replace("$" + str(k), " " + str(phrases[k]) + " ")
	return out


# ---------------------------------------------------------------- events

## Returns the list of events {beat, dur, midi (or -1 for drums), inst, vel, opt, gate_mul, drum, roll}.
func build_events(score: Dictionary, part: Dictionary, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var ev: Array[Dictionary] = []
	var m := meter_of(score)
	var bpb := float(m.x)
	var phrases: Dictionary = score.get("phrases", {})
	var pname := str(part.get("name", "?"))
	for s in part.get("seq", []):
		var seg: Dictionary = s
		var bar0 := float(seg.get("bar", 0))
		var base_vel := float(seg.get("vel", part.get("vel", 0.8)))
		var vel_to := float(seg.get("vel_to", base_vel))
		var transpose := int(seg.get("transpose", 0)) + int(part.get("transpose", 0))
		var opt: Dictionary = (part.get("opt", {}) as Dictionary).duplicate()
		opt.merge(seg.get("opt", {}), true)
		var raw: Array[Dictionary] = []
		if seg.has("notes"):
			raw = _parse_notes(_expand(str(seg["notes"]), phrases), int(seg.get("repeat", 1)), bpb, "%s@%s" % [pname, bar0])
		elif seg.has("chords"):
			if str(seg.get("pattern", "")).contains("$"):
				seg = seg.duplicate()
				seg["pattern"] = _expand(str(seg["pattern"]), phrases)
			raw = _parse_chords(_expand(str(seg["chords"]), phrases), seg, part, bpb)
		elif seg.has("pattern") or seg.has("patterns"):
			raw = _parse_drums(seg, part, bpb)
		var total := 0.0
		for r in raw:
			total = maxf(total, float(r["beat"]) + float(r["dur"]))
		for r in raw:
			var beat_abs := bar0 * bpb + float(r["beat"])
			var bar := int(floor(beat_abs / bpb + 0.0001))
			var in_bar := beat_abs - bar * bpb
			var prog := float(r["beat"]) / maxf(total, 0.001)
			var base := lerpf(base_vel, vel_to, prog) * float(r.get("acc", 1.0))
			var drum := bool(r.get("drum", false))
			var v := Humanise.velocity(rng, base, in_bar, bar, m, 0.4 if drum else 1.0)
			v *= _dyn(score, beat_abs / bpb)
			var e := {"beat": beat_abs, "dur": float(r["dur"]), "midi": int(r.get("midi", -1)) + (transpose if not drum else 0),
				"inst": str(r.get("inst", part.get("inst", "harp"))), "vel": v, "opt": opt,
				"gate_mul": float(r.get("gate_mul", part.get("gate", 0.95))), "drum": drum,
				"roll": bool(r.get("roll", false)), "strum_ms": float(r.get("strum_ms", 0.0)),
				"downbeat": absf(in_bar) < 0.01}
			e["after_grace"] = float(r.get("after_grace", 0.0))
			ev.append(e)
	ev.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["beat"]) < float(b["beat"]))
	var prev := -1.0
	for e in ev:
		e["vel"] = Humanise.no_repeat(float(e["vel"]), prev)
		prev = float(e["vel"])
	return ev


func _dyn(score: Dictionary, bar_pos: float) -> float:
	var d: Array = score.get("dyn", [])
	if d.is_empty():
		return 1.0
	var p0: Array = d[0]
	if bar_pos <= float(p0[0]):
		return float(p0[1])
	for i in range(1, d.size()):
		var a: Array = d[i - 1]
		var b: Array = d[i]
		if bar_pos <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (bar_pos - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0])))
	var last: Array = d[d.size() - 1]
	return float(last[1])


func _parse_notes(text: String, repeat: int, bpb: float, where: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cursor := 0.0
	for _r in repeat:
		var bar_start := cursor
		for tok in text.split(" ", false):
			var t := tok.strip_edges()
			if t == "":
				continue
			if t == "|":
				if absf(cursor - bar_start - bpb) > 0.001:
					warnings.append("%s: bar at beat %.2f holds %.2f beats" % [where, bar_start, cursor - bar_start])
				bar_start = cursor
				continue
			var grace := ""
			if t.begins_with("("):
				var close := t.find(")")
				grace = t.substr(1, close - 1)
				t = t.substr(close + 1)
			var acc := 1.0
			var gate_mul := -1.0
			var roll := false
			while t.length() > 0 and "!_'~*".contains(t[t.length() - 1]):
				var c := t[t.length() - 1]
				match c:
					"!": acc *= 1.22
					"_": acc *= 0.7
					"'": gate_mul = 0.45
					"~": gate_mul = 1.06
					"*": roll = true
				t = t.substr(0, t.length() - 1)
			var parts := t.split(":")
			if parts.size() != 2:
				warnings.append("%s: bad token %s" % [where, tok])
				continue
			var dur := float(parts[1])
			if parts[0] != "r":
				var g := 0.0
				if grace != "":
					out.append({"beat": cursor, "dur": 0.0, "midi": midi_of(grace), "acc": acc * 0.8, "gate_mul": 1.0, "grace": true})
					g = 1.0
				for p in parts[0].split("+"):
					var e := {"beat": cursor, "dur": dur, "midi": midi_of(p), "acc": acc, "roll": roll, "after_grace": g}
					if gate_mul > 0.0:
						e["gate_mul"] = gate_mul
					out.append(e)
			cursor += dur
		var tail := fmod(cursor - bar_start, bpb)
		if tail > 0.001 and absf(tail - bpb) > 0.001:
			warnings.append("%s: last bar holds %.2f beats" % [where, cursor - bar_start])
	return out


static func chord_tones(sym: String) -> Array[int]:
	var root: int = NOTE_NAMES.get(sym.substr(0, 1), 0)
	var i := 1
	if sym.length() > 1 and (sym[1] == "#" or sym[1] == "b"):
		root += 1 if sym[1] == "#" else -1
		i = 2
	var q := sym.substr(i)
	var ivs: Array = CHORD_IVS.get(q, [0, 4, 7])
	var r: Array[int] = []
	for v in ivs:
		r.append(posmod(root, 12) + int(v))
	return r


## Chord tone list from octave `oct` upward (index 0 = root at oct), 4 octaves.
static func _ext(tones: Array[int], oct: int) -> Array[int]:
	var ext: Array[int] = []
	for k in 5:
		for t in tones:
			ext.append(t + 12 * (oct + 1 + k))
	return ext


func _parse_chords(text: String, seg: Dictionary, part: Dictionary, bpb: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var style := str(seg.get("style", "hold"))
	var oct := int(seg.get("oct", 3))
	var cursor := 0.0
	var prev_voicing: Array[int] = []
	var down := true
	var voicing_idx: Array = _int_list(str(seg.get("voicing", "0 1 2")))
	for tok in text.split(" ", false):
		if tok == "|":
			continue
		var p := tok.split(":")
		var dur := float(p[1])
		if p[0] == "r":
			cursor += dur
			continue
		var tones := chord_tones(p[0])
		var ext := _ext(tones, oct)
		match style:
			"arp":
				var pat: Array = _int_list(str(seg.get("pattern", "0 1 2 3")))
				var step := float(seg.get("step", 0.5))
				var k := 0
				var b := 0.0
				while b < dur - 0.001:
					var idx: int = pat[k % pat.size()]
					if idx >= 0:
						out.append({"beat": cursor + b, "dur": step, "midi": ext[mini(idx, ext.size() - 1)]})
					k += 1
					b += step
			"hold":
				var notes := _voice(ext, tones.size(), voicing_idx, prev_voicing, bool(seg.get("lead_voices", true)))
				prev_voicing = notes
				for mn in notes:
					out.append({"beat": cursor, "dur": dur, "midi": mn, "gate_mul": float(seg.get("gate", 1.0))})
			"bass":
				var rh: Array = _float_list(str(seg.get("rhythm", str(dur))))
				var bb := 0.0
				var j := 0
				while bb < dur - 0.001:
					var d: float = rh[j % rh.size()]
					if d > 0.0:
						out.append({"beat": cursor + bb, "dur": d, "midi": ext[0] - (12 if bool(seg.get("low", false)) else 0)})
					bb += absf(d)
					j += 1
			"strum":
				var rh2: Array = _float_list(str(seg.get("rhythm", "1")))
				var bs := 0.0
				var j2 := 0
				var notes2 := _voice(ext, tones.size(), voicing_idx, prev_voicing, true)
				prev_voicing = notes2
				while bs < dur - 0.001:
					var d2: float = rh2[j2 % rh2.size()]
					if d2 > 0.0:
						var order: Array[int] = notes2.duplicate()
						if not down:
							order.reverse()
						for q in order.size():
							out.append({"beat": cursor + bs, "dur": d2, "midi": order[q], "strum_ms": 15.0 + q * 0.0 + 0.0,
								"strum_i": q, "gate_mul": float(seg.get("gate", 0.9)), "acc": 1.0 if down else 0.8})
						down = not down
					bs += absf(d2)
					j2 += 1
			"hits":
				var grid := str(seg.get("grid", "x...")).replace(" ", "")
				var hp: Array = _int_list(str(seg.get("pattern", "")))
				var stepg := bpb / grid.length()
				var notes3 := _voice(ext, tones.size(), voicing_idx, prev_voicing, true)
				prev_voicing = notes3
				var hb := 0.0
				var hk := 0
				while hb < dur - 0.001:
					var gi := int(round(hb / stepg)) % grid.length()
					var c := grid[gi]
					if c == "x" or c == "X":
						var length := stepg
						var look := gi + 1
						while look < grid.length() and grid[look] == "-":
							length += stepg
							look += 1
						var acc := 1.2 if c == "X" else 1.0
						if hp.is_empty():
							for mn3 in notes3:
								out.append({"beat": cursor + hb, "dur": length, "midi": mn3, "acc": acc, "gate_mul": float(seg.get("gate", 0.8))})
						else:
							var hi: int = hp[hk % hp.size()]
							out.append({"beat": cursor + hb, "dur": length, "midi": ext[mini(hi, ext.size() - 1)], "acc": acc,
								"gate_mul": float(seg.get("gate", 0.8))})
							hk += 1
					hb += stepg
		cursor += dur
	# strum offsets: 15-30 ms per string, stored as ms from the strum onset
	for e in out:
		if e.has("strum_i"):
			e["strum_ms"] = float(e["strum_i"]) * 20.0
	return out


## Picks the voicing (indices into the chord tones) closest to the previous chord (smooth voice leading).
func _voice(ext: Array[int], ntones: int, idx: Array, prev: Array[int], smooth: bool) -> Array[int]:
	var best: Array[int] = []
	var best_cost := INF
	var shifts := range(0, ntones * 2) if smooth and not prev.is_empty() else [0]
	for sh in shifts:
		var cand: Array[int] = []
		for i in idx:
			cand.append(ext[mini(int(i) + int(sh), ext.size() - 1)])
		if prev.is_empty():
			return cand
		var cost := 0.0
		for i in mini(cand.size(), prev.size()):
			cost += absf(cand[i] - prev[i])
		# stay near the written register
		cost += 0.35 * absf(cand[0] - ext[int(idx[0])])
		if cost < best_cost:
			best_cost = cost
			best = cand
	return best


func _parse_drums(seg: Dictionary, part: Dictionary, bpb: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var kit: Dictionary = part.get("kit", {})
	var pats: Array = seg.get("patterns", [seg.get("pattern", "")])
	var bars := int(seg.get("bars", 1))
	var fill := str(seg.get("fill", ""))
	var fill_every := int(seg.get("fill_every", 0))
	for b in bars:
		var pat := str(pats[b % pats.size()])
		if fill != "" and fill_every > 0 and (b + 1) % fill_every == 0:
			pat = fill
		pat = pat.replace(" ", "")
		var step := bpb / pat.length()
		for i in pat.length():
			var c := pat[i]
			if c == "." or c == "-":
				continue
			var key := c.to_lower()
			if not kit.has(key):
				warnings.append("%s: no kit letter %s" % [part.get("name", "?"), c])
				continue
			var k: Array = kit[key]
			var e := {"beat": b * bpb + i * step, "dur": step, "inst": str(k[0]), "acc": float(k[1]) * (1.25 if c != key else 1.0),
				"drum": true, "midi": int(k[2]) if k.size() > 2 else 45}
			out.append(e)
	return out


static func _int_list(s: String) -> Array:
	var r: Array = []
	for t in s.split(" ", false):
		r.append(int(t))
	return r


static func _float_list(s: String) -> Array:
	var r: Array = []
	for t in s.split(" ", false):
		r.append(float(t))
	return r


# ---------------------------------------------------------------- render

## Renders a score. Returns {samples: PackedFloat32Array, stats: {...}}.
func render(score: Dictionary, verbose: bool = true) -> Dictionary:
	var t_start := Time.get_ticks_msec()
	var n := length_samples(score)
	var loop := bool(score.get("loop", true))
	var pre := int(PRE_S * RATE)
	var ext_n := pre + n + int(TAIL_S * RATE)
	var sp := spu(score)
	var dry := PackedFloat32Array()
	dry.resize(ext_n)
	var send := PackedFloat32Array()
	send.resize(ext_n)
	var pad_parts: Array[PackedFloat32Array] = []
	var part_info: Array[Dictionary] = []
	var seed := int(score.get("seed", 1))
	var parts: Array = score.get("parts", [])
	for pi in parts.size():
		var part: Dictionary = parts[pi]
		var rng := RandomNumberGenerator.new()
		rng.seed = seed * 7919 + pi * 104729 + 17
		var ev := build_events(score, part, rng)
		var buf := PackedFloat32Array()
		buf.resize(ext_n)
		var t_part := Time.get_ticks_msec()
		var grace_t := 0.04
		for e in ev:
			var t := float(e["beat"]) * sp
			if float(e["after_grace"]) > 0.0:
				t += grace_t
			var j := Humanise.jitter(rng, bool(e["drum"]), bool(e["downbeat"]))
			if not bool(part.get("humanise", true)):
				j = 0.0
			t += j + float(e["strum_ms"]) * 0.001
			if t < 0.0 and not loop:
				t = 0.0
			if absf(float(e["beat"])) < 0.001 and loop:
				t = absf(t) + 0.004   # keep the very first attack off the loop seam
			var gate := float(e["dur"]) * sp * float(e["gate_mul"])
			if float(e["dur"]) == 0.0:
				gate = grace_t
			var vel := clampf(float(e["vel"]), 0.02, 1.4)
			var f := Dsp.midi_hz(float(e["midi"])) * Humanise.detune_ratio(rng)
			var inst := str(e["inst"])
			if bool(e["roll"]):
				var k := 0
				var rt := 0.0
				while rt < gate:
					var rv := vel * lerpf(0.3, 1.0, rt / maxf(gate, 0.01)) * (1.0 + rng.randf_range(-0.08, 0.08))
					_add(buf, Instruments.render(inst, f, 0.1, rv, rng, e["opt"]), pre + int((t + rt) * RATE))
					rt += 0.062 + rng.randf_range(-0.006, 0.006)
					k += 1
				continue
			var note := Instruments.render(inst, f, maxf(gate, 0.03), vel, rng, e["opt"])
			_add(buf, note, pre + int(round(t * RATE)))
		var eq: Array = part.get("eq", [])
		if not eq.is_empty():
			Dsp.run_eq(buf, eq)
		var g := Dsp.db2lin(float(part.get("gain_db", 0.0)))
		var sendv := float(part.get("send", 0.35))
		var e2 := 0.0
		for i in ext_n:
			var v := buf[i] * g
			buf[i] = v
			dry[i] += v
			send[i] += v * sendv
			e2 += v * v
		if bool(part.get("pad", false)):
			pad_parts.append(buf)
		part_info.append({"name": part.get("name", "?"), "inst": part.get("inst", "?"), "events": ev.size(),
			"rms": e2, "ms": Time.get_ticks_msec() - t_part})
	var t_rev := Time.get_ticks_msec()
	var room: Dictionary = score.get("room", {})
	# room input: gently darker than the dry mix
	Dsp.run_biquad(send, Dsp.biquad("lp", 5000.0, 0.7071))
	Dsp.run_biquad(send, Dsp.biquad("hp", 120.0, 0.7071))
	var wet := Reverb.process(send, float(room.get("size", 0.8)), float(room.get("damp", 0.4)), 0.025, float(room.get("wet_db", -10.0)))
	var rev_ms := Time.get_ticks_msec() - t_rev
	var mix := PackedFloat32Array()
	mix.resize(ext_n)
	var dry_e := 0.0
	for i in ext_n:
		mix[i] = dry[i] + wet[i]
		dry_e += dry[i] * dry[i]
	Dsp.run_biquad(mix, Dsp.biquad("hp", 32.0, 0.7071))
	var pad_e := 0.0
	for pb in pad_parts:
		for i in ext_n:
			pad_e += pb[i] * pb[i]
	var out := PackedFloat32Array()
	out.resize(n)
	if loop:
		for i in ext_n:
			out[posmod(i - pre, n)] += mix[i]
	else:
		for i in n:
			out[i] = mix[pre + i]
		var fo := int(float(score.get("fade_out_s", 1.0)) * RATE)
		for i in fo:
			var x := float(i) / fo
			out[n - fo + i] *= (1.0 - x) * (1.0 - x)
	# master: loudness to the target, look-ahead limiter at -1.2 dBFS
	var target := float(score.get("lufs", -12.0))
	var ceiling := Dsp.db2lin(-1.2)
	var gain := Dsp.db2lin(target - Dsp.lufs(out))
	var mastered := PackedFloat32Array()
	for it in 3:
		mastered = out.duplicate()
		for i in n:
			mastered[i] *= gain
		Dsp.limit(mastered, ceiling, 0.12, loop)
		var got := Dsp.lufs(mastered)
		if absf(got - target) < 0.2:
			break
		gain *= Dsp.db2lin(clampf(target - got, -6.0, 6.0))
	if not loop:
		var f50 := int(0.05 * RATE)
		for i in f50:
			mastered[n - f50 + i] *= 1.0 - float(i + 1) / f50
	var stats := {
		"id": score.get("id", "?"), "hash": score.get("_hash", ""), "samples": n, "length_s": float(n) / RATE,
		"peak_db": Dsp.peak_db(mastered), "rms_db": Dsp.rms_db(mastered), "lufs": Dsp.lufs(mastered),
		"pad_share": pad_e / maxf(dry_e, 1e-12), "hf_share": Dsp.hf_share(mastered), "loop": loop,
		"render_s": (Time.get_ticks_msec() - t_start) / 1000.0, "reverb_ms": rev_ms,
	}
	if loop:
		var s := Dsp.seam(mastered)
		stats["seam_step"] = s.x
		stats["seam_slope"] = s.y
	else:
		stats["end_db"] = Dsp.lin2db(absf(mastered[n - 1]) + absf(mastered[n - 2]))
	var tot_e := 0.0
	for p in part_info:
		tot_e += float(p["rms"])
	var plist: Array = []
	for p in part_info:
		plist.append({"name": p["name"], "inst": p["inst"], "events": p["events"], "ms": p["ms"],
			"share": float(p["rms"]) / maxf(tot_e, 1e-12)})
	stats["parts"] = plist
	if verbose:
		for p in plist:
			print("    part %-14s %-9s %4d notes  energy %5.1f %%  %5d ms" % [p["name"], p["inst"], p["events"], float(p["share"]) * 100.0, p["ms"]])
	return {"samples": mastered, "stats": stats}


static func _add(buf: PackedFloat32Array, note: PackedFloat32Array, at: int) -> void:
	var s := maxi(0, -at)
	var e := mini(note.size(), buf.size() - at)
	for i in range(s, e):
		buf[at + i] += note[i]

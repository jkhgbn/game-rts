extends RefCounted
## Music Forge sampler backend (phase 1b, 2026-10-13): plays the SAME scores with recorded instruments from the CC0
## VSCO 2 Community Edition library, which lives OUTSIDE the repo (never copied in; only rendered tracks are kept).
## Path: env FW_MUSIC_SAMPLES, else forge arg `samples=<dir>`, else DEFAULT_ROOT. Missing path = the forge stays on the
## synth instruments (CI / other PCs).
## No .sfz in the subset: the key / velocity map comes from the file names (note, `_vN` layer or pp..fff, `_rrN`).
## VSCO names notes one octave low (measured: "A2" sounds A3 = 220 Hz), except the harp (scientific); timpani drums
## have no note in the name, their measured principal pitches are in TIMPANI_ROOTS.
## A note = nearest sampled root (pitch shift by resampling, max +-12), velocity layer by note velocity, round-robin
## cycling, release fade after the gate (sustain sets) or the natural ring (one-shots). Brass / wind sections stack
## 2 takes (other round-robin, +-6 cents, 10-25 ms apart, panned apart). Instruments with no samples (claps, shaker,
## frame tek, tubular bells, mallet, pad) are rendered by the synth kit and upsampled, so a score always renders.

const Instruments := preload("res://tools/music_forge/instruments.gd")

const RATE := 44100
const DEFAULT_ROOT := "C:/Users/elzzo/Documents/four-wizards-samples/VSCO-2-CE"
const SAMPLER_VERSION := "smp1.0"
const LOAD_MAX_S := 6.5
const ONE_SHOT_MAX_S := 4.0
const TIMPANI_ROOTS := [41.4, 46.9, 49.7, 52.8, 54.9]   # Timpani1..5 principal tones (measured, MIDI)
const DYN_LAYERS := {"pppp": 1, "ppp": 2, "pp": 3, "p": 4, "mp": 5, "mf": 6, "f": 7, "ff": 8, "fff": 9}

## set id -> [folder, octave offset (semitones added to the named note), file filter, kind]
## kind: "sus" (gate + release), "one" (rings, ignores the gate), "roll" (sustained, fades in / out over the gate)
const SETS := {
	"vln_sus": ["Strings/Violin Section/susVib", 12, "", "sus"],
	"vln_spic": ["Strings/Violin Section/Spic", 12, "", "one"],
	"vln_trem": ["Strings/Violin Section/Trem", 12, "", "sus"],
	"vla_sus": ["Strings/Viola Section/susvib", 12, "", "sus"],
	"vla_spic": ["Strings/Viola Section/spic", 12, "", "one"],
	"vc_sus": ["Strings/Cello Section/susvib", 12, "", "sus"],
	"vc_spic": ["Strings/Cello Section/spic", 12, "", "one"],
	"harp": ["Strings/Harp", 0, "", "one"],
	"hn_sus": ["Brass/F Horn/sus", 12, "", "sus"],
	"hn_stac": ["Brass/F Horn/stac", 12, "", "one"],
	"tpt_sus": ["Brass/Trumpet/sus", 12, "", "sus"],
	"tpt_stac": ["Brass/Trumpet/stac", 12, "", "one"],
	"tbn_sus": ["Brass/Tenor Trombone/sus", 12, "", "sus"],
	"tbn_stac": ["Brass/Tenor Trombone/stac", 12, "", "one"],
	"tuba_sus": ["Brass/Tuba/sus", 12, "", "sus"],
	"fl_sus": ["Woodwinds/Flute/susvib", 12, "", "sus"],
	"fl_stac": ["Woodwinds/Flute/stac", 12, "", "one"],
	"ob_sus": ["Woodwinds/Oboe/Vib", 12, "", "sus"],
	"glock": ["Percussion/Glock", 12, "", "one"],
	"timp": ["Percussion/Timpani", 0, "_Hit_", "one"],
	"timp_roll": ["Percussion/Timpani/Rolls", 0, "_Roll_", "roll"],
	"bdrum": ["VSCO 1 Percussion/drums/bass", 0, "bdrum_", "one"],
	"bdrum_muted": ["VSCO 1 Percussion/drums/bass", 0, "bdrum_muted_", "one"],
	"snare": ["VSCO 1 Percussion/drums/snare/drum1", 0, "snare1_", "one"],
}
const RELEASE := {"vln_sus": 0.35, "vla_sus": 0.35, "vc_sus": 0.35, "vln_trem": 0.3, "hn_sus": 0.25, "tpt_sus": 0.22,
	"tbn_sus": 0.25, "tuba_sus": 0.25, "fl_sus": 0.2, "ob_sus": 0.18, "timp_roll": 0.5}
## One-shot ring caps (seconds) so long natural tails do not cost render time
const RING := {"harp": 3.2, "glock": 2.5, "timp": 3.0, "bdrum": 2.5, "bdrum_muted": 1.2, "snare": 0.8}
const STACKED := ["hn_sus", "hn_stac", "tpt_sus", "tpt_stac", "tbn_sus", "tbn_stac", "fl_sus", "fl_stac", "ob_sus"]
const DRUM_ROOT := 60.0   # unpitched sets: the kit midi only shifts toms (tom = muted bass drum up)

var root := ""
var zones := {}          # set id -> Array of {path, root, layer, rr}
var _cache := {}         # path -> [L, R] (peak-normalised to 0.5, at most LOAD_MAX_S)
var _rr := {}
var stats := {"files": 0, "load_ms": 0, "notes": 0, "fallback": 0}


static func sample_root(arg: String = "") -> String:
	var env := OS.get_environment("FW_MUSIC_SAMPLES")
	if env != "":
		return env.replace("\\", "/")
	if arg != "":
		return arg.replace("\\", "/")
	return DEFAULT_ROOT


static func available(dir: String) -> bool:
	return DirAccess.dir_exists_absolute(dir + "/Strings") and DirAccess.dir_exists_absolute(dir + "/Brass")


## Scans the library. Returns false when the folder is missing.
func setup(dir: String) -> bool:
	root = dir
	if not available(dir):
		return false
	var note_re := RegEx.create_from_string("_([A-G]#?)(-?\\d)(?=[_.])")
	var vel_re := RegEx.create_from_string("_v(\\d+)")
	var rr_re := RegEx.create_from_string("_(?:rr|RR)(\\d+)|_(\\d+)\\.wav$")
	var dyn_re := RegEx.create_from_string("_(pppp|ppp|pp|p|mp|mf|f|ff|fff)(?=[_.])")
	var drum_re := RegEx.create_from_string("^Timpani(\\d)_")
	for id in SETS:
		var def: Array = SETS[id]
		var folder := dir + "/" + str(def[0])
		var list: Array = []
		for f in DirAccess.get_files_at(folder):
			if not f.to_lower().ends_with(".wav"):
				continue
			if str(def[2]) != "" and not f.contains(str(def[2])):
				continue
			if id == "timp" and f.contains("_v1_"):
				continue   # the v1 hits peak near -60 dBFS: noise floor only
			if id == "bdrum" and (f.contains("muted") or f.contains("roll") or f.contains("special")):
				continue
			if id == "snare" and (f.contains("click") or f.contains("rim") or f.contains("nosnare") or f.contains("_snare")):
				continue
			var z := {"path": folder + "/" + f, "root": DRUM_ROOT, "layer": 1, "rr": 1}
			var m := note_re.search(f)
			if id.begins_with("timp"):
				var dm := drum_re.search(f)
				if dm == null:
					continue
				z["root"] = float(TIMPANI_ROOTS[clampi(int(dm.get_string(1)) - 1, 0, 4)])
			elif m != null:
				z["root"] = float(_midi(m.get_string(1), int(m.get_string(2))) + int(def[1]))
			elif not id.begins_with("bdrum") and id != "snare":
				continue
			var v := vel_re.search(f)
			if v != null:
				z["layer"] = int(v.get_string(1))
			else:
				var d := dyn_re.search(f)
				if d != null:
					z["layer"] = int(DYN_LAYERS[d.get_string(1)])
			var r := rr_re.search(f)
			if r != null:
				z["rr"] = int(r.get_string(1) if r.get_string(1) != "" else r.get_string(2))
			list.append(z)
		zones[id] = list
	return true


static func _midi(name: String, octave: int) -> int:
	var pcs := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	return int(pcs[name.substr(0, 1)]) + (1 if name.contains("#") else 0) + 12 * (octave + 1)


## Which sample set plays this score instrument ("" = synth fallback).
static func set_for(inst: String, gate_s: float, gate_mul: float, opt: Dictionary, midi: float) -> String:
	var short := gate_s < 0.3 or gate_mul < 0.6
	match inst:
		"violins", "strings":
			if bool(opt.get("tremolo", false)):
				return "vln_trem"
			return "vln_spic" if short else "vln_sus"
		"violas":
			return "vla_spic" if short else "vla_sus"
		"cellos", "basses":
			return "vc_spic" if short else "vc_sus"
		"horns", "brass", "choir":
			return "hn_stac" if short else "hn_sus"
		"trumpets":
			return "tpt_stac" if short else "tpt_sus"
		"trombones":
			if midi < 40.0:
				return "tuba_sus"
			return "tbn_stac" if short else "tbn_sus"
		"flute", "fife", "whistle":
			return "fl_stac" if short else "fl_sus"
		"shawm":
			return "ob_sus"
		"harp", "lute":
			return "harp"
		"celesta", "glass":
			return "glock"
		"timpani":
			return "timp"
		"taiko":
			return "bdrum"
		"frame_dum", "tom":
			return "bdrum_muted"
		"snare":
			return "snare"
	return ""


## Renders one note as [L, R] at 44.1 kHz. `midi` may be fractional (detune). Falls back to the synth kit.
func render(inst: String, midi: float, gate_s: float, vel: float, gate_mul: float, rng: RandomNumberGenerator,
		opt: Dictionary, roll: bool) -> Array:
	var sid := set_for(inst, gate_s, gate_mul, opt, midi)
	if roll and inst == "timpani":
		sid = "timp_roll"
	var list: Array = zones.get(sid, [])
	if sid == "" or list.is_empty():
		return _fallback(inst, midi, gate_s, vel, rng, opt)
	var target := midi
	var kind := str(SETS[sid][3])
	if sid.begins_with("bdrum") or sid == "snare":
		target = DRUM_ROOT + (12.0 if inst == "tom" else 0.0) + (midi - 47.0 if inst == "tom" else 0.0) * 0.5
	var z := _pick(sid, list, target, vel)
	if z.is_empty():
		return _fallback(inst, midi, gate_s, vel, rng, opt)
	stats["notes"] += 1
	var takes := 2 if STACKED.has(sid) and int(opt.get("section", 1)) >= 2 else 1
	var rel := float(RELEASE.get(sid, 0.3))
	var out_len := int((gate_s + rel) * RATE) if kind != "one" else int(float(RING.get(sid, ONE_SHOT_MAX_S)) * RATE)
	if sid == "harp" and inst == "harp":
		out_len = int(minf(gate_s + 1.6, 3.2) * RATE)   # like the synth harp ring (overlapping arpeggios)
	if inst == "lute":
		out_len = int((gate_s + 0.12) * RATE)
	var l := PackedFloat32Array()
	var r := PackedFloat32Array()
	var pad := int(0.03 * RATE)
	l.resize(out_len + pad)
	r.resize(out_len + pad)
	var amp := pow(clampf(vel, 0.05, 1.3), 1.35)
	for t in takes:
		var zt := z if t == 0 else _pick(sid, list, target, vel)
		var cents := 0.0 if t == 0 else rng.randf_range(4.0, 7.0) * (1.0 if rng.randf() < 0.5 else -1.0)
		var off := 0 if t == 0 else rng.randi_range(int(0.010 * RATE), int(0.025 * RATE))
		var pan := 0.0 if takes == 1 else (-0.3 if t == 0 else 0.3)
		_play(l, r, zt, target + cents / 100.0, gate_s, rel, kind, amp / sqrt(float(takes)), off, pan, inst == "lute", roll)
	return [l, r]


func _pick(sid: String, list: Array, target: float, vel: float) -> Dictionary:
	var best := INF
	for z in list:
		best = minf(best, absf(float(z["root"]) - target))
	if best > 12.5:
		return {}
	var near: Array = []
	var nearest_root := 0.0
	for z in list:
		if absf(float(z["root"]) - target) <= best + 0.01:
			nearest_root = float(z["root"])
			break
	for z in list:
		if absf(float(z["root"]) - nearest_root) < 0.01:
			near.append(z)
	var layer_list: Array = []
	for z in near:
		if not layer_list.has(int(z["layer"])):
			layer_list.append(int(z["layer"]))
	layer_list.sort()
	var li := clampi(int(clampf(vel, 0.0, 0.999) * layer_list.size()), 0, layer_list.size() - 1)
	var layer: int = layer_list[li]
	var takes: Array = []
	for z in near:
		if int(z["layer"]) == layer:
			takes.append(z)
	var key := "%s|%s|%d" % [sid, nearest_root, layer]
	var c: int = _rr.get(key, 0)
	_rr[key] = c + 1
	return takes[c % takes.size()]


func _play(l: PackedFloat32Array, r: PackedFloat32Array, z: Dictionary, target: float, gate_s: float, rel: float,
		kind: String, amp: float, off: int, pan: float, damp: bool, roll: bool) -> void:
	var src := _load(str(z["path"]))
	var sl: PackedFloat32Array = src[0]
	var sr: PackedFloat32Array = src[1]
	var ratio := pow(2.0, (target - float(z["root"])) / 12.0)
	var n := mini(l.size() - off, int((sl.size() - 2) / ratio))
	var ng := int(gate_s * RATE)
	var nr := maxi(1, int(rel * RATE))
	if kind == "one" and damp:
		nr = int(0.1 * RATE)
	elif kind == "one":
		ng = n   # rings to its natural end
	var gl := amp * (1.0 - maxf(0.0, pan))
	var gr := amp * (1.0 + minf(0.0, pan))
	var fade_in := int(0.25 * gate_s * RATE) if roll else 0
	var end_fade := int(0.03 * RATE)
	var pos := 0.0
	for i in n:
		var g := 1.0
		if i >= ng:
			var x := float(i - ng) / nr
			if x >= 1.0:
				break
			g = (1.0 - x) * (1.0 - x)
		if i < fade_in:
			g *= 0.35 + 0.65 * float(i) / fade_in
		if i > n - end_fade:
			g *= float(n - i) / end_fade
		var j := int(pos)
		var fr := pos - j
		var a := sl[j]
		var b := sr[j]
		l[off + i] += (a + (sl[j + 1] - a) * fr) * g * gl
		r[off + i] += (b + (sr[j + 1] - b) * fr) * g * gr
		pos += ratio


## Loads a sample (16 / 24-bit PCM, mono or stereo) into [L, R] floats at 44.1 kHz, peak-normalised to 0.5.
func _load(path: String) -> Array:
	if _cache.has(path):
		return _cache[path]
	var t0 := Time.get_ticks_msec()
	var bytes := FileAccess.get_file_as_bytes(path)
	var l := PackedFloat32Array()
	var r := PackedFloat32Array()
	var pos := 12
	var ch := 2
	var bits := 16
	while pos + 8 <= bytes.size():
		var id := bytes.decode_u32(pos)
		var sz := bytes.decode_u32(pos + 4)
		if id == 0x20746d66:
			ch = bytes.decode_u16(pos + 10)
			bits = bytes.decode_u16(pos + 22)
		elif id == 0x61746164:
			var bps := int(bits / 8)
			var frames := mini(int(sz / (bps * ch)), int(LOAD_MAX_S * RATE))
			l.resize(frames)
			r.resize(frames)
			var p0 := pos + 8
			var step := bps * ch
			var pk := 0.0
			for i in frames:
				var at := p0 + i * step
				var a := 0.0
				var b := 0.0
				if bps == 2:
					a = bytes.decode_s16(at) / 32768.0
					b = bytes.decode_s16(at + 2) / 32768.0 if ch == 2 else a
				else:
					a = (bytes.decode_s16(at + 1) * 256 + bytes[at]) / 8388608.0
					b = (bytes.decode_s16(at + 4) * 256 + bytes[at + 3]) / 8388608.0 if ch == 2 else a
				l[i] = a
				r[i] = b
				pk = maxf(pk, maxf(absf(a), absf(b)))
			if pk > 0.0:
				var g := minf(0.5 / pk, 8.0)   # soft layers stay softer (a big boost would raise their noise floor)
				for i in frames:
					l[i] *= g
					r[i] *= g
			break
		pos += 8 + sz + (sz & 1)
	if l.size() < 4:
		l.resize(4)
		r.resize(4)
	_cache[path] = [l, r]
	stats["files"] += 1
	stats["load_ms"] += Time.get_ticks_msec() - t0
	return _cache[path]


## Synth kit note (22 050 Hz mono) upsampled x2 to 44.1 kHz, same on both sides.
func _fallback(inst: String, midi: float, gate_s: float, vel: float, rng: RandomNumberGenerator, opt: Dictionary) -> Array:
	stats["fallback"] += 1
	var f := 440.0 * pow(2.0, (midi - 69.0) / 12.0)
	var m := Instruments.render(inst, f, gate_s, vel, rng, opt)
	var n := m.size()
	var l := PackedFloat32Array()
	l.resize(n * 2)
	for i in n:
		var a := m[i]
		var b := m[i + 1] if i + 1 < n else 0.0
		l[i * 2] = a
		l[i * 2 + 1] = (a + b) * 0.5
	return [l, l.duplicate()]

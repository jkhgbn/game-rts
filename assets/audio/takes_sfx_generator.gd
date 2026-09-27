extends SceneTree
## Extra takes for the most frequent combat cues (Audio Lab "Variation": a cue played 40-120 times a minute needs
## >= 3 takes). Each take is derived from the placeholder made by tools/generate_sfx.gd (read back from its .wav):
## resampled a few percent, its brightness tilted, and a fresh noise transient layered on the attack, then set to the
## same peak as the original. No samples, all original. GameAudio.TAKES lists them and picks one at random per play.
##   res://assets/audio/sfx/melee_hit_1.wav     melee_hit_2.wav
##   res://assets/audio/sfx/bolt_shot_1.wav     bolt_shot_2.wav
##   res://assets/audio/sfx/bolt_impact_1.wav   bolt_impact_2.wav
##   res://assets/audio/sfx/building_hit_1.wav  building_hit_2.wav
##   res://assets/audio/sfx/mine_tick_1.wav     mine_tick_2.wav
## Run AFTER tools/generate_sfx.gd: godot --headless --path . -s assets/audio/takes_sfx_generator.gd --quit-after 10
## then: godot --headless --path . --import
## Deterministic (fixed seed): running it again gives the same files.

const DIR := "res://assets/audio/sfx/"
## id -> per take [resample ratio (> 1 = higher), tilt (-1 darker .. +1 brighter), transient amount, peak scale].
## building_hit takes get a strong bright crack (the original is almost all bass).
const RECIPES := {
	"melee_hit": [[0.95, 0.35, 0.25, 0.88], [1.06, -0.25, 0.35, 0.92]],
	"bolt_shot": [[0.96, -0.3, 0.15, 1.0], [1.05, 0.3, 0.2, 0.95]],
	"bolt_impact": [[0.94, 0.3, 0.3, 1.0], [1.07, -0.2, 0.25, 0.95]],
	"building_hit": [[0.93, 0.9, 0.6, 0.85], [1.06, 1.1, 0.8, 0.85]],
	"mine_tick": [[0.92, -0.2, 0.2, 1.0], [1.08, 0.2, 0.25, 1.0]],
}

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 424242
	for id: String in RECIPES:
		var src := _read_wav(DIR + id + ".wav")
		if src.is_empty():
			push_error("takes_sfx_generator: cannot read %s.wav (run tools/generate_sfx.gd first)" % id)
			continue
		var rate := int(src["rate"])
		var base: PackedFloat32Array = src["samples"]
		var base_peak := 0.0
		for v in base:
			base_peak = maxf(base_peak, absf(v))
		var takes: Array = RECIPES[id]
		for i in takes.size():
			var r: Array = takes[i]
			var buf := _resample(base, float(r[0]))
			_tilt(buf, float(r[1]))
			_transient(buf, rate, float(r[2]))
			_fade_out(buf, rate)
			_save(DIR + "%s_%d.wav" % [id, i + 1], buf, rate, base_peak * float(r[3]))
	quit()


## {rate, samples} of a 16-bit mono PCM .wav, or {} when it cannot be read.
func _read_wav(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var bytes := f.get_buffer(f.get_length())
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return {}
	var rate := bytes.decode_u32(24)
	var bits := bytes.decode_u16(34)
	var channels := bytes.decode_u16(22)
	if bits != 16 or channels != 1:
		return {}
	var pos := 12
	while pos + 8 <= bytes.size():
		var tag := bytes.slice(pos, pos + 4).get_string_from_ascii()
		var size := bytes.decode_u32(pos + 4)
		if tag == "data":
			var out := PackedFloat32Array()
			var n := mini(size, bytes.size() - pos - 8) >> 1
			out.resize(n)
			for k in n:
				out[k] = float(bytes.decode_s16(pos + 8 + k * 2)) / 32768.0
			return {"rate": rate, "samples": out}
		pos += 8 + size + (size & 1)
	return {}


## Linear resampling: ratio > 1 = shorter and higher.
func _resample(src: PackedFloat32Array, ratio: float) -> PackedFloat32Array:
	var n := int(float(src.size()) / ratio)
	var out := PackedFloat32Array()
	out.resize(n)
	for k in n:
		var x := float(k) * ratio
		var i := int(x)
		var fr := x - float(i)
		var a := src[i] if i < src.size() else 0.0
		var b := src[i + 1] if i + 1 < src.size() else 0.0
		out[k] = lerpf(a, b, fr)
	return out


## Brightness tilt around a one-pole split (~1.5 kHz at 22 kHz): + boosts the highs, - keeps more of the lows.
func _tilt(buf: PackedFloat32Array, amount: float) -> void:
	var lp := 0.0
	for k in buf.size():
		lp += 0.35 * (buf[k] - lp)
		var hi := buf[k] - lp
		buf[k] = lp * (1.0 - 0.5 * maxf(amount, 0.0)) + hi * (1.0 + amount)


## A fresh 25 ms bright noise click on the attack (a different grain per take), relative to the take's peak.
func _transient(buf: PackedFloat32Array, rate: int, amount: float) -> void:
	var top := 0.0
	for v in buf:
		top = maxf(top, absf(v))
	var n := mini(int(0.025 * rate), buf.size())
	var lp := 0.0
	for k in n:
		var white := _rng.randf_range(-1.0, 1.0)
		lp += 0.5 * (white - lp)
		var env := exp(-6.0 * float(k) / float(n))
		if k < 22:
			env *= float(k) / 22.0
		buf[k] += (white - lp) * amount * top * env


func _fade_out(buf: PackedFloat32Array, rate: int) -> void:
	var n := mini(int(0.008 * rate), buf.size())
	for k in n:
		buf[buf.size() - 1 - k] *= float(k) / float(n)


func _save(path: String, buf: PackedFloat32Array, rate: int, peak: float) -> void:
	var top := 0.0
	for v in buf:
		top = maxf(top, absf(v))
	var gain := peak / top if top > 0.0 else 1.0
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i] * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	var err := wav.save_to_wav(path)
	if err != OK:
		push_error("takes_sfx_generator: could not save %s (%d)" % [path, err])
	else:
		print("  %s  %.2f s" % [path, float(buf.size()) / rate])

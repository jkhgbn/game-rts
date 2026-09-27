extends SceneTree
## Placeholder champion / alert sounds (Audio Lab fixes: "Champion ability cast" and "Your wizard has fallen" had no
## sound). Synthesised like trade_sfx_generator.gd (sine / noise / envelopes, no samples, all original) and saved as
## 16-bit mono .wav files in res://assets/audio/sfx/ (GameAudio loads them from SFX_DIR):
##   ability_cast.wav       0.45 s, a rising airy swell with two bright plucks (a champion casts an ability)
##   skill_hit.wav          0.28 s, a short thump with a metallic ring (a champion's class skill lands)
##   alert_wizard_fell.wav  1.4 s, a low toll and three falling notes (your wizard has fallen)
## Run: godot --headless --path . -s assets/audio/champion_sfx_generator.gd --quit-after 10
## then: godot --headless --path . --import
## Deterministic (fixed seed): running it again gives the same files.

const RATE := 22050
const DIR := "res://assets/audio/sfx/"
const SINE := 0
const TRI := 1
const SQUARE := 2
const SAW := 3

var _buf := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 90213
	# Ability cast: a short airy swell rising in pitch, then two bright plucks a fifth apart.
	_new(0.45)
	_noise(0.0, 0.3, 0.35, 0.12, 1.5, 0.3, 0.7, true)
	_tone(0.0, 0.3, 420.0, 900.0, 0.25, 1.2, TRI, 0.1)
	_tone(0.2, 0.2, 1175.0, 1175.0, 0.4, 5.0, TRI, 0.002)
	_tone(0.26, 0.19, 1760.0, 1760.0, 0.35, 5.0, TRI, 0.002)
	_tone(0.26, 0.19, 3520.0, 3520.0, 0.06, 8.0, SINE, 0.002)
	_save("ability_cast", 0.7)
	# Skill hit: a low thump (pitch drop), a noise crack and a short metallic ring.
	_new(0.28)
	_tone(0.0, 0.16, 180.0, 70.0, 0.6, 5.0, SINE, 0.002)
	_noise(0.0, 0.06, 0.5, 0.001, 5.0, 0.6, 0.3)
	_tone(0.005, 0.26, 1480.0, 1440.0, 0.22, 6.0, SINE, 0.002)
	_tone(0.005, 0.26, 2270.0, 2200.0, 0.12, 8.0, SINE, 0.002)
	_save("skill_hit", 0.75)
	# Wizard fell: a low toll (bell with a long tail) and three falling notes (falling = bad news).
	_new(1.4)
	_bell(0.0, 1.35, 196.0, 0.35, 2.2)
	_tone(0.0, 1.3, 98.0, 96.0, 0.25, 2.5, SAW, 0.01)
	var notes: Array[float] = [880.0, 740.0, 587.3]
	for i in notes.size():
		var t0 := 0.18 + 0.2 * float(i)
		_tone(t0, 0.5, notes[i], notes[i] * 0.985, 0.32, 3.0, TRI, 0.006, 5.0, 0.004)
		_tone(t0, 0.5, notes[i] * 2.0, notes[i] * 1.97, 0.08, 4.0, SINE, 0.006)
	_save("alert_wizard_fell", 0.75)
	quit()


func _new(duration: float) -> void:
	_buf = PackedFloat32Array()
	_buf.resize(int(duration * RATE))


func _tone(t0: float, dur: float, f0: float, f1: float, amp: float, decay: float, shape: int = SINE,
		attack: float = 0.004, vib_hz: float = 0.0, vib_depth: float = 0.0) -> void:
	var s0 := int(t0 * RATE)
	var count := mini(int(dur * RATE), _buf.size() - s0)
	var phase := 0.0
	for k in count:
		var x := float(k) / float(count)
		var t := float(k) / RATE
		var f := f0 * pow(f1 / f0, x)
		if vib_hz > 0.0:
			f *= 1.0 + vib_depth * sin(TAU * vib_hz * t)
		phase += TAU * f / RATE
		var v := 0.0
		match shape:
			SINE:
				v = sin(phase)
			TRI:
				v = sin(phase) - sin(3.0 * phase) / 9.0 + sin(5.0 * phase) / 25.0
			SQUARE:
				v = sin(phase) + sin(3.0 * phase) / 3.0 + sin(5.0 * phase) / 5.0
			SAW:
				v = sin(phase) + sin(2.0 * phase) / 2.0 + sin(3.0 * phase) / 3.0 + sin(4.0 * phase) / 4.0
		_buf[s0 + k] += v * amp * _env(t, dur, attack, decay)


func _noise(t0: float, dur: float, amp: float, attack: float, decay: float, lp0: float, lp1: float,
		high: bool = false) -> void:
	var s0 := int(t0 * RATE)
	var count := mini(int(dur * RATE), _buf.size() - s0)
	var lp := 0.0
	for k in count:
		var x := float(k) / float(count)
		var a := lerpf(lp0, lp1, x)
		var white := _rng.randf_range(-1.0, 1.0)
		lp += a * (white - lp)
		var v := (white - lp) if high else lp * (1.0 + 1.5 * (1.0 - a))
		_buf[s0 + k] += v * amp * _env(float(k) / RATE, dur, attack, decay)


func _bell(t0: float, dur: float, f: float, amp: float, decay: float = 5.0) -> void:
	_tone(t0, dur, f, f, amp, decay, SINE, 0.002)
	_tone(t0, dur, f * 2.76, f * 2.76, amp * 0.3, decay * 1.6, SINE, 0.002)
	_tone(t0, dur, f * 5.4, f * 5.4, amp * 0.12, decay * 2.4, SINE, 0.002)


func _env(t: float, dur: float, attack: float, decay: float) -> float:
	var e := exp(-decay * t / maxf(dur, 0.001))
	if attack > 0.0 and t < attack:
		e *= t / attack
	var tail := dur - t
	if tail < 0.005:
		e *= maxf(tail, 0.0) / 0.005
	return e


func _save(id: String, peak: float) -> void:
	var top := 0.0
	for v in _buf:
		top = maxf(top, absf(v))
	var gain := peak / top if top > 0.0 else 1.0
	# 10 ms fade-out so every file ends on silence (no click).
	var fade := mini(int(0.01 * RATE), _buf.size())
	for k in fade:
		_buf[_buf.size() - 1 - k] *= float(k) / float(fade)
	var bytes := PackedByteArray()
	bytes.resize(_buf.size() * 2)
	for i in _buf.size():
		bytes.encode_s16(i * 2, int(clampf(_buf[i] * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	var path := DIR + id + ".wav"
	var err := wav.save_to_wav(path)
	if err != OK:
		push_error("champion_sfx_generator: could not save %s (%d)" % [path, err])
	else:
		print("  %s  %.2f s" % [path, float(_buf.size()) / RATE])

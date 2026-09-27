extends SceneTree
## Placeholder map-fill sounds (task 12.C7, ui-mapfill.md 14), synthesised like trade_sfx_generator.gd (sine / noise /
## envelopes, no samples, all original) and saved as 16-bit mono .wav files next to this script:
##   mapfill_chime.wav   0.4 s, two rising bell notes (own capture)
##   mapfill_horn.wav    1.2 s, one low horn note with an echo (a Wayshrine wakes)
##   mapfill_bubble.wav  0.3 s, a soft bubble (an own well pays, on screen)
##   mapfill_drum.wav    0.6 s, two low drum hits (a camp cleared)
##   mapfill_stag.wav    1.0 s, a bellow (a Hollow Stag fight starts)
##   mapfill_roar.wav    1.5 s, a low-passed roar far away (an epic beast spawns)
##   mapfill_splash.wav  0.3 s, a small water splash (a unit starts to wade), soft-clipped (dense, loud for its peak)
## Run: godot --headless --path . -s assets/audio/mapfill_sfx_generator.gd --quit-after 10
## then: godot --headless --path . --import
## Deterministic (fixed seed): running it again gives the same files.

const RATE := 22050
const DIR := "res://assets/audio/"
const SINE := 0
const TRI := 1
const SQUARE := 2
const SAW := 3

var _buf := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 120712
	# Capture chime: two bell notes a fourth apart, rising.
	_new(0.4)
	_bell(0.0, 0.22, 1318.5, 0.5)
	_bell(0.12, 0.28, 1760.0, 0.5)
	_save("mapfill_chime", 0.55)
	# Distant horn: one low note with a soft swell, then a quieter echo.
	_new(1.2)
	_tone(0.0, 0.7, 98.0, 97.0, 0.6, 1.6, SAW, 0.12, 4.0, 0.004)
	_tone(0.0, 0.7, 196.0, 194.0, 0.2, 2.0, SQUARE, 0.12)
	_tone(0.45, 0.72, 98.0, 97.0, 0.22, 2.2, SAW, 0.15, 4.0, 0.004)
	_tone(0.45, 0.72, 196.0, 194.0, 0.07, 2.4, SQUARE, 0.15)
	_lowpass(0.25)
	_save("mapfill_horn", 0.6)
	# Soft bubble: a quick upward sine blip with a watery wobble.
	_new(0.3)
	_tone(0.0, 0.12, 380.0, 900.0, 0.5, 3.0, SINE, 0.005, 30.0, 0.04)
	_tone(0.13, 0.12, 460.0, 1050.0, 0.35, 3.5, SINE, 0.005, 30.0, 0.04)
	_save("mapfill_bubble", 0.45)
	# Drum: two low hits (pitch drop + a thump of noise).
	_new(0.6)
	for t0: float in [0.0, 0.22]:
		_tone(t0, 0.3, 130.0, 55.0, 0.8, 5.0, SINE, 0.002)
		_noise(t0, 0.08, 0.35, 0.001, 6.0, 0.2, 0.05)
	_save("mapfill_drum", 0.7)
	# Stag bellow: a rough rising-then-falling low call.
	_new(1.0)
	_tone(0.0, 0.95, 140.0, 105.0, 0.6, 1.2, SAW, 0.08, 6.0, 0.02)
	_tone(0.0, 0.95, 280.0, 210.0, 0.2, 1.5, SQUARE, 0.08, 6.0, 0.02)
	_noise(0.0, 0.9, 0.12, 0.1, 1.5, 0.3, 0.2)
	_lowpass(0.35)
	_save("mapfill_stag", 0.6)
	# Beast roar far away: a growl of noise + low saw, heavily low-passed.
	_new(1.5)
	_tone(0.0, 1.45, 72.0, 58.0, 0.6, 1.0, SAW, 0.2, 9.0, 0.03)
	_noise(0.0, 1.4, 0.5, 0.25, 1.2, 0.08, 0.04)
	_lowpass(0.12)
	_lowpass(0.12)
	_save("mapfill_roar", 0.55)
	# Splash: a dense burst of water noise (bright slap + a darker body), two droplets, soft-clipped so it is loud
	# for its peak (Audio Lab: the old file was about -44 LUFS in game at the default zoom). MapfillPopups plays it
	# at SPLASH_DB with +-6 % pitch.
	_new(0.3)
	_noise(0.0, 0.26, 0.9, 0.002, 2.6, 0.75, 0.25, true)
	_noise(0.0, 0.24, 0.7, 0.004, 2.2, 0.45, 0.2)
	_tone(0.03, 0.09, 1100.0, 520.0, 0.35, 3.0, SINE, 0.002)
	_tone(0.12, 0.08, 1400.0, 700.0, 0.25, 3.0, SINE, 0.002)
	_soft_clip(2.2)
	_save("mapfill_splash", 0.72)
	quit()


## tanh saturation (drive > 1 = denser, louder for the same peak).
func _soft_clip(drive: float) -> void:
	var top := 0.0
	for v in _buf:
		top = maxf(top, absf(v))
	if top <= 0.0:
		return
	for i in _buf.size():
		_buf[i] = tanh(_buf[i] / top * drive)


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


func _bell(t0: float, dur: float, f: float, amp: float) -> void:
	_tone(t0, dur, f, f, amp, 5.0, SINE, 0.002)
	_tone(t0, dur, f * 2.76, f * 2.76, amp * 0.3, 8.0, SINE, 0.002)
	_tone(t0, dur, f * 5.4, f * 5.4, amp * 0.12, 12.0, SINE, 0.002)


## One-pole low-pass over the whole buffer (0-1: lower = darker, "far away").
func _lowpass(a: float) -> void:
	var lp := 0.0
	for i in _buf.size():
		lp += a * (_buf[i] - lp)
		_buf[i] = lp


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
		push_error("mapfill_sfx_generator: could not save %s (%d)" % [path, err])
	else:
		print("  %s  %.2f s" % [path, float(_buf.size()) / RATE])

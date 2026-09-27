extends SceneTree
## Placeholder trade sounds (task 10.C8, ui-trade.md 14.5), synthesised like tools/generate_sfx.gd (sine / noise /
## envelopes, no samples, all original) and saved as 16-bit mono .wav files next to this script:
##   res://assets/audio/trade_coin.wav     0.25 s, two short metallic ticks (own delivery, own loot sack)
##   res://assets/audio/trade_whistle.wav  0.5 s, a two-note whistle rising then falling (a band strikes)
##   res://assets/audio/trade_horn.wav     0.8 s, one low horn note (a hunters' contract starts)
## Run: godot --headless --path . -s assets/audio/trade_sfx_generator.gd --quit-after 10
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
	_rng.seed = 100108
	# Coin clink: two bright, slightly detuned metallic ticks 0.09 s apart.
	_new(0.25)
	_bell(0.0, 0.12, 2637.0, 0.5)
	_noise(0.0, 0.015, 0.35, 0.0005, 8.0, 0.8, 0.8, true)
	_bell(0.09, 0.16, 3136.0, 0.45)
	_noise(0.09, 0.015, 0.3, 0.0005, 8.0, 0.8, 0.8, true)
	_save("trade_coin", 0.55)
	# Two-note whistle: a quick rise, then a fall (a thief's signal). Audio Lab fix: with triangle tones (odd
	# harmonics up to 8 kHz) the QOA import overshot to +1.4 dBTP (the decoded stream clipped although the file
	# peaked at -4.4 dBFS). Pure sine tones and a darker breath decode cleanly (about -4 dBTP).
	_new(0.5)
	_tone(0.0, 0.2, 1150.0, 1650.0, 0.55, 1.2, SINE, 0.02, 7.0, 0.01)
	_tone(0.24, 0.25, 1600.0, 1050.0, 0.55, 1.6, SINE, 0.02, 7.0, 0.01)
	_noise(0.0, 0.48, 0.05, 0.05, 1.5, 0.5, 0.5)
	_save("trade_whistle", 0.6)
	# Horn: one low note with a soft swell and a brassy edge.
	_new(0.8)
	_tone(0.0, 0.78, 110.0, 108.0, 0.6, 1.4, SAW, 0.09, 4.5, 0.004)
	_tone(0.0, 0.78, 220.0, 216.0, 0.25, 1.8, SQUARE, 0.09)
	_tone(0.0, 0.78, 165.0, 162.0, 0.12, 2.0, SINE, 0.12)
	_save("trade_horn", 0.7)
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


func _bell(t0: float, dur: float, f: float, amp: float) -> void:
	_tone(t0, dur, f, f, amp, 5.0, SINE, 0.002)
	_tone(t0, dur, f * 2.76, f * 2.76, amp * 0.3, 8.0, SINE, 0.002)
	_tone(t0, dur, f * 5.4, f * 5.4, amp * 0.12, 12.0, SINE, 0.002)


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
		push_error("trade_sfx_generator: could not save %s (%d)" % [path, err])
	else:
		print("  %s  %.2f s" % [path, float(_buf.size()) / RATE])

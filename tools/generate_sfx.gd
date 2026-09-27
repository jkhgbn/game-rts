extends SceneTree
## Placeholder sound generator (task 6.S1). Synthesises every game sound and the two music loops with code
## (sine / noise / envelopes, no samples, all original) and saves them as 16-bit mono .wav files:
##   res://assets/audio/sfx/<id>.wav     short effects (ids = GameAudio.SOUNDS)
##   res://assets/audio/music/<id>.wav   music_match (48 s loop), music_menu (40 s loop)
## Run: godot --headless --path . -s tools/generate_sfx.gd --quit-after 10
## then: godot --headless --path . --import
## Deterministic (fixed seed): running it again gives the same files.

const RATE := 22050
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const SINE := 0
const TRI := 1
const SQUARE := 2   # soft (3 odd harmonics)
const SAW := 3      # soft (4 harmonics)

var _buf := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	_rng.seed = 60601
	for dir in [SFX_DIR, MUSIC_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	_make_sfx()
	_make_music()
	print("generate_sfx: done in %d ms" % (Time.get_ticks_msec() - t0))
	quit()


# ---------------------------------------------------------------- effects

func _make_sfx() -> void:
	# Combat
	_new(0.2)
	_noise(0.0, 0.16, 0.9, 0.002, 9.0, 0.35, 0.08)
	_tone(0.0, 0.14, 150.0, 55.0, 0.9, 7.0)
	_save(SFX_DIR, "melee_hit")

	_new(0.24)
	_noise(0.0, 0.2, 0.45, 0.004, 6.0, 0.6, 0.6, true)
	_tone(0.0, 0.1, 950.0, 520.0, 0.35, 10.0, TRI)
	_save(SFX_DIR, "bolt_shot", 0.7)

	_new(0.14)
	_noise(0.0, 0.08, 0.8, 0.001, 10.0, 0.5, 0.15)
	_tone(0.0, 0.12, 320.0, 110.0, 0.7, 8.0)
	_save(SFX_DIR, "bolt_impact", 0.75)

	# Spells
	_new(0.55)
	_noise(0.0, 0.5, 0.8, 0.08, 3.0, 0.04, 0.35)
	_tone(0.0, 0.5, 180.0, 420.0, 0.35, 3.0, SAW)
	_crackle(0.05, 0.4, 14, 0.4)
	_save(SFX_DIR, "fireball_cast")

	_new(1.1)
	_noise(0.0, 1.05, 1.0, 0.003, 4.5, 0.25, 0.02)
	_tone(0.0, 0.8, 95.0, 32.0, 1.0, 4.0)
	_crackle(0.05, 0.8, 22, 0.35)
	_save(SFX_DIR, "fireball_explode", 0.95)

	_new(0.45)
	_noise(0.0, 0.3, 0.6, 0.12, 2.0, 0.05, 0.5, true)
	_tone(0.0, 0.3, 300.0, 1300.0, 0.4, 3.0, TRI)
	_tone(0.3, 0.14, 700.0, 200.0, 0.5, 8.0)
	_save(SFX_DIR, "spell_ember_step")

	_new(0.8)
	_crackle(0.0, 0.7, 30, 0.35)
	_tone(0.0, 0.75, 330.0, 440.0, 0.35, 2.5, TRI, 0.05)
	_tone(0.0, 0.75, 415.0, 554.0, 0.3, 2.5, TRI, 0.05)
	_noise(0.0, 0.6, 0.35, 0.1, 3.0, 0.08, 0.2)
	_save(SFX_DIR, "spell_kindle")

	_new(0.5)
	_tone(0.0, 0.45, 760.0, 140.0, 0.6, 4.0, SAW)
	_tone(0.0, 0.45, 770.0, 145.0, 0.4, 4.0, SQUARE)
	_noise(0.0, 0.3, 0.3, 0.003, 6.0, 0.4, 0.1)
	_save(SFX_DIR, "spell_shadow_lance")

	_new(1.1)
	_tone(0.0, 1.05, 220.0, 196.0, 0.4, 1.5, SINE, 0.25, 5.0, 0.02)
	_tone(0.0, 1.05, 233.0, 207.0, 0.4, 1.5, SINE, 0.25, 4.3, 0.02)
	_noise(0.0, 1.0, 0.35, 0.4, 2.0, 0.03, 0.08)
	_save(SFX_DIR, "spell_soul_siphon", 0.8)

	_new(0.9)
	_noise(0.0, 0.85, 0.8, 0.3, 2.0, 0.02, 0.06)
	_tone(0.0, 0.85, 110.0, 82.0, 0.6, 2.0, SINE, 0.2, 7.0, 0.04)
	_tone(0.0, 0.85, 164.0, 123.0, 0.25, 2.5, TRI, 0.2)
	_save(SFX_DIR, "spell_umbral_shroud", 0.8)

	# Deaths
	_new(0.65)
	_noise(0.0, 0.55, 0.7, 0.002, 4.0, 0.7, 0.4, true)
	_tone(0.0, 0.5, 420.0, 80.0, 0.6, 4.0, SAW)
	_crackle(0.0, 0.45, 12, 0.35)
	_save(SFX_DIR, "death_fire", 0.8)

	_new(0.8)
	_tone(0.0, 0.75, 520.0, 110.0, 0.45, 3.0, SINE, 0.01, 9.0, 0.03)
	_tone(0.0, 0.75, 540.0, 104.0, 0.35, 3.0, TRI, 0.01, 7.0, 0.03)
	_noise(0.0, 0.6, 0.3, 0.05, 3.0, 0.05, 0.02)
	_save(SFX_DIR, "death_shadow", 0.8)

	# Buildings
	_new(0.3)
	_tone(0.0, 0.25, 95.0, 50.0, 0.9, 6.0)
	_noise(0.0, 0.2, 0.7, 0.001, 8.0, 0.18, 0.05)
	_save(SFX_DIR, "building_hit", 0.8)

	_new(1.8)
	_noise(0.0, 1.75, 1.0, 0.02, 2.2, 0.06, 0.015)
	_tone(0.0, 1.4, 70.0, 30.0, 0.8, 2.0)
	for i in 14:
		var t := _rng.randf_range(0.05, 1.3)
		_noise(t, 0.12, _rng.randf_range(0.3, 0.6), 0.001, 9.0, 0.3, 0.1)
	_save(SFX_DIR, "building_collapse", 0.95)

	_new(0.75)
	_noise(0.0, 0.06, 0.6, 0.001, 9.0, 0.3, 0.2)
	_tone(0.0, 0.08, 260.0, 180.0, 0.5, 9.0)
	_noise(0.12, 0.06, 0.6, 0.001, 9.0, 0.3, 0.2)
	_tone(0.12, 0.08, 260.0, 180.0, 0.5, 9.0)
	_bell(0.26, 0.45, 523.25, 0.4)
	_bell(0.34, 0.4, 659.25, 0.4)
	_bell(0.42, 0.33, 783.99, 0.45)
	_save(SFX_DIR, "construction_done", 0.75)

	_new(0.45)
	_tone(0.0, 0.16, 196.0, 196.0, 0.5, 1.5, SQUARE, 0.01)
	_tone(0.16, 0.28, 261.63, 261.63, 0.55, 2.5, SQUARE, 0.01)
	_save(SFX_DIR, "unit_trained", 0.6)

	# Economy
	_new(0.1)
	_tone(0.0, 0.08, 2400.0, 2300.0, 0.5, 12.0)
	_tone(0.0, 0.06, 3620.0, 3500.0, 0.3, 14.0)
	_noise(0.0, 0.02, 0.4, 0.0005, 10.0, 0.8, 0.8, true)
	_save(SFX_DIR, "mine_tick", 0.45)

	_new(0.4)
	_bell(0.0, 0.18, 1318.5, 0.4)
	_bell(0.07, 0.18, 1760.0, 0.4)
	_bell(0.14, 0.25, 2637.0, 0.35)
	_save(SFX_DIR, "crystals_delivered", 0.5)

	# Progress, items, UI
	_new(0.95)
	var arp := [523.25, 659.25, 783.99, 1046.5]
	for i in arp.size():
		_bell(i * 0.09, 0.95 - i * 0.09, arp[i], 0.4)
	_tone(0.0, 0.9, 261.63, 261.63, 0.2, 2.0, TRI, 0.05)
	_save(SFX_DIR, "level_up", 0.8)

	_new(0.32)
	_bell(0.0, 0.12, 1480.0, 0.5)
	_bell(0.08, 0.24, 1975.5, 0.5)
	_save(SFX_DIR, "item_bought", 0.6)

	_new(0.4)
	_tone(0.0, 0.38, 600.0, 1250.0, 0.5, 2.5, SINE, 0.02, 18.0, 0.04)
	_noise(0.0, 0.35, 0.25, 0.05, 3.0, 0.6, 0.6, true)
	_save(SFX_DIR, "item_used", 0.6)

	_new(0.26)
	_tone(0.0, 0.12, 500.0, 1000.0, 0.6, 5.0, TRI)
	_bell(0.08, 0.18, 1500.0, 0.35)
	_save(SFX_DIR, "item_pickup", 0.6)

	_new(0.06)
	_tone(0.0, 0.05, 1100.0, 900.0, 0.6, 12.0, TRI)
	_save(SFX_DIR, "ui_click", 0.4)

	_new(0.3)
	_tone(0.0, 0.12, 185.0, 185.0, 0.5, 1.0, SQUARE, 0.003)
	_tone(0.13, 0.15, 147.0, 147.0, 0.5, 2.0, SQUARE, 0.003)
	_save(SFX_DIR, "ui_error", 0.5)

	# Stingers
	_new(1.4)
	var crown := [392.0, 493.88, 587.33, 783.99]
	for i in crown.size():
		_tone(i * 0.1, 1.3 - i * 0.1, crown[i], crown[i], 0.35, 2.0, SQUARE, 0.01)
		_bell(i * 0.1, 1.2 - i * 0.1, crown[i] * 2.0, 0.2)
	_save(SFX_DIR, "crown_claimed", 0.8)

	_new(2.8)
	var win := [261.63, 329.63, 392.0, 523.25]
	for i in win.size():
		_tone(i * 0.18, 0.3, win[i], win[i], 0.5, 2.0, SQUARE, 0.01)
	for f in [261.63, 329.63, 392.0, 523.25, 130.81]:
		_tone(0.75, 2.0, f, f, 0.3, 1.8, SQUARE, 0.02, 5.0, 0.004)
	_bell(0.75, 1.6, 1046.5, 0.25)
	_save(SFX_DIR, "victory", 0.85)

	_new(2.8)
	var lose := [392.0, 349.23, 311.13, 261.63]
	for i in lose.size():
		_tone(i * 0.35, 0.5 if i < 3 else 2.2, lose[i], lose[i] * (1.0 if i < 3 else 0.97), 0.45, 2.0, SAW, 0.02)
	_tone(1.05, 1.7, 130.81, 123.0, 0.4, 1.5, SINE, 0.05)
	_tone(1.05, 1.7, 155.56, 146.0, 0.3, 1.5, TRI, 0.05)
	_save(SFX_DIR, "defeat", 0.8)


# ---------------------------------------------------------------- music

func _make_music() -> void:
	# Match: A minor, Am - F - C - G, 80 BPM, 12 s per chord (4 bars), 48 s loop.
	_music("music_match", 48.0, 80.0,
			[[57, 60, 64], [53, 57, 60], [55, 60, 64], [55, 59, 62]],
			[45, 41, 48, 43], 1.0, 0.55, 1.0)
	# Menu: D minor, Dm - Bb - F - C, 60 BPM, 10 s per chord, 40 s loop, sparse and soft.
	_music("music_menu", 40.0, 60.0,
			[[62, 65, 69], [58, 62, 65], [60, 65, 69], [60, 64, 67]],
			[38, 34, 41, 36], 0.9, 0.3, 0.45)


## Loopable ambient track: pads that crossfade between chords, a soft bass drone and an eighth-note
## arpeggio. Every oscillator frequency is a multiple of 1/length so the end joins the start without a click;
## arpeggio tails that run past the end wrap to the start.
func _music(id: String, length: float, bpm: float, chords: Array, roots: Array, pad_amp: float,
		arp_amp: float, arp_density: float) -> void:
	var n := int(length * RATE)
	_buf = PackedFloat32Array()
	_buf.resize(n)
	var chord_len := length / chords.size()
	var fade := 1.5
	var tau := TAU / RATE
	var trem := 1.0 / length * 6.0   # 6 slow tremolo cycles per loop
	for ci in chords.size():
		var notes: Array = chords[ci]
		var freqs: Array[float] = []
		for m in notes:
			freqs.append(_snap(_hz(m), length))
		var bass := _snap(_hz(roots[ci]), length)
		var center := (ci + 0.5) * chord_len
		var reach := chord_len * 0.5 + fade
		var s0 := int((center - reach) * RATE)
		var s1 := int((center + reach) * RATE)
		for s in range(s0, s1):
			var i := posmod(s, n)
			var t := float(i) / RATE
			var d := absf(float(s) / RATE - center)
			var w := clampf((reach - d) / (2.0 * fade), 0.0, 1.0)
			if w <= 0.0:
				continue
			var v := 0.0
			for k in freqs.size():
				var f: float = freqs[k]
				var ph := tau * f * i
				v += sin(ph) + 0.25 * sin(2.0 * ph) + 0.08 * sin(3.0 * ph)
			v *= 0.16 * (0.85 + 0.15 * sin(TAU * trem * t))
			v += 0.3 * sin(tau * bass * i) + 0.08 * sin(tau * bass * 2.0 * i)
			_buf[i] += v * w * pad_amp
	# Arpeggio: eighth notes over the chord tones, an octave up.
	var step := 60.0 / bpm * 0.5
	var steps := int(round(length / step))
	var pattern := [0, 1, 2, 1, 0, 2, 1, 2]
	var decay_len := 0.9
	var dn := int(decay_len * RATE)
	for j in steps:
		if arp_density < 1.0 and _rng.randf() > arp_density:
			continue
		var t0 := j * step
		var ci := mini(int(t0 / chord_len), chords.size() - 1)
		var notes: Array = chords[ci]
		var m: int = notes[pattern[j % pattern.size()]] + 12
		if j % 16 == 15:
			m += 12   # a little lift at the end of each 2-bar phrase
		var f := _hz(m)
		var amp := arp_amp * (1.0 if j % 4 == 0 else 0.7)
		var start := int(t0 * RATE)
		for k in dn:
			var x := float(k) / RATE
			var env := exp(-x * 5.0) * minf(1.0, x / 0.004)
			var ph := TAU * f * x
			var v := (sin(ph) + 0.3 * sin(2.0 * ph) + 0.1 * sin(3.0 * ph)) * env * 0.18 * amp
			var i := (start + k) % n
			_buf[i] += v
	_save(MUSIC_DIR, id, 0.6)


# ---------------------------------------------------------------- building blocks

func _new(duration: float) -> void:
	_buf = PackedFloat32Array()
	_buf.resize(int(duration * RATE))


## Tone with an exponential pitch sweep f0 -> f1, a short attack and an exponential decay (`decay` = how many
## e-folds over `dur`). Optional vibrato (Hz, depth as a fraction of the frequency).
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


## Filtered noise: one-pole low-pass whose coefficient sweeps lp0 -> lp1 (0-1, higher = brighter);
## `high` keeps what the low-pass removes instead (hiss, whoosh).
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


## Random short clicks (fire crackle, debris).
func _crackle(t0: float, dur: float, count: int, amp: float) -> void:
	for i in count:
		var t := t0 + _rng.randf() * dur
		_noise(t, 0.012, amp * _rng.randf_range(0.4, 1.0), 0.0005, 6.0, 0.7, 0.5, true)


## Bell / chime: a few inharmonic sine partials.
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
		e *= maxf(tail, 0.0) / 0.005   # no click at the end
	return e


func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## Rounds a frequency so it completes a whole number of cycles over the loop.
func _snap(f: float, length: float) -> float:
	return round(f * length) / length


## Normalises _buf to `peak` and writes a 16-bit mono .wav.
func _save(dir: String, id: String, peak: float = 0.85) -> void:
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
	var path := dir + id + ".wav"
	var err := wav.save_to_wav(path)
	if err != OK:
		push_error("generate_sfx: could not save %s (%d)" % [path, err])
	else:
		print("  %s  %.2f s" % [path, float(_buf.size()) / RATE])

extends SceneTree
## Per-family unit SFX for the tiers wave units (bowmen, the 12 new units, the T3 units, the T3 helpers): attack / hit /
## death, synthesised with the same building blocks as tools/generate_sfx.gd (sine / noise / envelopes, no samples,
## all original), re-parameterised per family. GameAudio.UNIT_SFX_FAMILY maps a unit type id to a family:
##   res://assets/audio/sfx/atk_<family>.wav    the unit attacks (ranged: at the shot; melee: the swing)
##   res://assets/audio/sfx/hit_<family>.wav    the unit is hit
##   res://assets/audio/sfx/death_<family>.wav  the unit dies (joins the Audio Lab death_* family, 3 dB)
## Families: blade, heavy, whip, bow, bolt, siege, magic, storm, beast.
## Each cue also gets 2 takes (<id>_1.wav, <id>_2.wav, see TAKE_VARIANTS): 81 files. GameAudio picks one at random,
## never the same take twice in a row.
## Run: godot --headless --path . -s assets/audio/unit_sfx_generator.gd --quit-after 10, then --import.
## Deterministic (fixed seed).

const RATE := 22050
const DIR := "res://assets/audio/sfx/"
const SINE := 0
const TRI := 1
const SQUARE := 2
const SAW := 3
const FAMILIES: Array[String] = ["blade", "heavy", "whip", "bow", "bolt", "siege", "magic", "storm", "beast"]

## Takes (JS 2026-09-27 "triple the sound"): take 0 = the original <id>.wav, takes 1 / 2 = <id>_1.wav / <id>_2.wav, the
## same recipe re-rendered with another pitch / length / brightness (and fresh noise), loudness-matched to take 0
## (max 200 ms RMS) so a random pick never jumps out (Audio Lab TAKE_TOL 2 dB). [pitch mult, length mult, brightness].
const TAKE_VARIANTS := [[1.0, 1.0, 1.0], [0.91, 1.12, 0.82], [1.1, 0.9, 1.2]]
const TAKE_PEAK := 0.8   ## Takes never go above this (-1.9 dBFS: the QOA import adds up to ~0.6 dB) even when the loudness match asks for more.

var _buf := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()
var _take := 0
var _pm := 1.0        # pitch multiplier of the current take
var _lm := 1.0        # length multiplier
var _bright := 1.0    # noise low-pass coefficient multiplier (timbre)
var _ref := {}        # base id -> max 200 ms RMS of take 0 (after normalisation)
var _count := 0


func _initialize() -> void:
	_rng.seed = 270927
	for f in FAMILIES:
		call("_" + f)   # take 0: exactly the original files
	for t in [1, 2]:
		_set_take(t)
		for f in FAMILIES:
			call("_" + f)
	_set_take(0)
	print("unit_sfx_generator: %d files" % _count)
	quit()


func _set_take(t: int) -> void:
	_take = t
	_pm = float(TAKE_VARIANTS[t][0])
	_lm = float(TAKE_VARIANTS[t][1])
	_bright = float(TAKE_VARIANTS[t][2])


# ---------------------------------------------------------------- families

## Light melee (Scorchling, Rimeling, Barrow Ghoul, Ashveil Saboteur): a quick swish + a light slash.
func _blade() -> void:
	_new(0.2)
	_noise(0.0, 0.14, 0.7, 0.01, 4.0, 0.2, 0.7, true)
	_tone(0.06, 0.1, 900.0, 600.0, 0.25, 8.0, TRI)
	_save("atk_blade", 0.7)
	_new(0.18)
	_noise(0.0, 0.1, 0.9, 0.001, 9.0, 0.55, 0.2)
	_tone(0.0, 0.12, 260.0, 120.0, 0.6, 8.0)
	_save("hit_blade", 0.72)
	_new(0.55)
	_noise(0.0, 0.3, 0.5, 0.003, 5.0, 0.5, 0.1)
	_tone(0.0, 0.45, 330.0, 110.0, 0.55, 4.0, SAW)
	_save("death_blade", 0.75)


## Heavy melee (Oathsworn, Oathkeeper, Reaver, Shardguard, Old Vey): a slow heavy swing + a metal clang.
func _heavy() -> void:
	_new(0.3)
	_noise(0.0, 0.24, 0.8, 0.03, 3.0, 0.08, 0.45, true)
	_tone(0.14, 0.14, 140.0, 70.0, 0.7, 6.0)
	_save("atk_heavy", 0.72)
	_new(0.3)
	_noise(0.0, 0.06, 0.8, 0.001, 9.0, 0.6, 0.3)
	_bell(0.0, 0.28, 610.0, 0.35)
	_tone(0.0, 0.14, 180.0, 90.0, 0.6, 7.0)
	_save("hit_heavy", 0.72)
	_new(0.75)
	_noise(0.0, 0.5, 0.6, 0.002, 4.0, 0.3, 0.05)
	_tone(0.0, 0.6, 180.0, 60.0, 0.6, 3.0, SAW)
	for i in 5:
		_bell(0.15 + i * 0.08, 0.2, _rng.randf_range(700.0, 1100.0), 0.18)
	_save("death_heavy", 0.75)


## Vine / lash (Vinelasher): a crack of a whip + a rustle.
func _whip() -> void:
	_new(0.26)
	_noise(0.0, 0.14, 0.6, 0.02, 3.0, 0.1, 0.8, true)
	_noise(0.14, 0.05, 1.0, 0.0005, 9.0, 0.9, 0.7, true)
	_tone(0.14, 0.06, 1400.0, 700.0, 0.35, 9.0, TRI)
	_save("atk_whip", 0.7)
	_new(0.2)
	_noise(0.0, 0.16, 0.8, 0.002, 6.0, 0.4, 0.15)
	_crackle(0.0, 0.12, 8, 0.4)
	_tone(0.0, 0.1, 210.0, 110.0, 0.4, 8.0)
	_save("hit_whip", 0.7)
	_new(0.6)
	_noise(0.0, 0.55, 0.6, 0.02, 3.0, 0.3, 0.05)
	_crackle(0.05, 0.4, 14, 0.35)
	_tone(0.0, 0.5, 240.0, 90.0, 0.4, 3.0, TRI)
	_save("death_whip", 0.75)


## Bows (Hall bowmen, Thistle Darter, Magebow, Aldra): a string thrum + an arrow thunk.
func _bow() -> void:
	_new(0.24)
	_tone(0.0, 0.2, 180.0, 150.0, 0.45, 6.0, TRI)
	_tone(0.0, 0.08, 2300.0, 1700.0, 0.3, 8.0, TRI)   # the string's bright twang (not all-bass)
	_noise(0.0, 0.18, 0.5, 0.004, 5.0, 0.5, 0.8, true)
	_save("atk_bow", 0.68)
	_new(0.16)
	_noise(0.0, 0.06, 0.8, 0.001, 10.0, 0.45, 0.2)
	_tone(0.0, 0.12, 380.0, 160.0, 0.55, 8.0)
	_save("hit_bow", 0.7)
	_new(0.55)
	_noise(0.0, 0.35, 0.45, 0.003, 5.0, 0.6, 0.15)
	_tone(0.0, 0.5, 520.0, 140.0, 0.5, 4.0, TRI)
	_save("death_bow", 0.72)


## Heavy bolt (Cinder Arbalest): a crank click + a hard crossbow snap; a deep punch on hit.
func _bolt() -> void:
	_new(0.26)
	_noise(0.0, 0.03, 0.6, 0.0005, 8.0, 0.8, 0.8, true)
	_noise(0.06, 0.03, 0.6, 0.0005, 8.0, 0.8, 0.8, true)
	_tone(0.1, 0.14, 240.0, 120.0, 0.7, 7.0, SQUARE)
	_noise(0.1, 0.12, 0.5, 0.002, 6.0, 0.5, 0.3, true)
	_save("atk_bolt", 0.7)
	_new(0.2)
	_noise(0.0, 0.1, 0.9, 0.001, 9.0, 0.35, 0.1)
	_tone(0.0, 0.16, 200.0, 70.0, 0.8, 7.0)
	_save("hit_bolt", 0.72)
	_new(0.65)
	_noise(0.0, 0.4, 0.6, 0.002, 4.0, 0.4, 0.06)
	_tone(0.0, 0.55, 300.0, 80.0, 0.55, 3.5, SAW)
	_crackle(0.1, 0.3, 8, 0.3)
	_save("death_bolt", 0.75)


## Siege (Frost Mortar): a deep thump + hiss; a wide icy crump on hit; a wooden crack on death.
func _siege() -> void:
	_new(0.45)
	_tone(0.0, 0.35, 110.0, 45.0, 0.7, 5.0)
	_noise(0.0, 0.4, 0.9, 0.002, 4.0, 0.3, 0.8, true)
	_crackle(0.0, 0.2, 10, 0.5)   # frost vapour crackle (not all-bass)
	_save("atk_siege", 0.78)
	_new(0.4)
	_noise(0.0, 0.35, 0.9, 0.002, 5.0, 0.4, 0.08)
	_tone(0.0, 0.3, 160.0, 55.0, 0.6, 5.0)
	_crackle(0.02, 0.25, 10, 0.35)
	_save("hit_siege", 0.75)
	_new(0.9)
	_noise(0.0, 0.8, 0.8, 0.003, 3.0, 0.2, 0.03)
	_tone(0.0, 0.6, 90.0, 40.0, 0.6, 3.0)
	for i in 6:
		_noise(_rng.randf_range(0.05, 0.6), 0.08, _rng.randf_range(0.3, 0.6), 0.001, 9.0, 0.5, 0.2)
	_save("death_siege", 0.78)


## Casters (Pyre Adept, Hexweaver, Mother Hush, Maelis): a rising shimmer; a zap on hit; a falling chord on death.
func _magic() -> void:
	_new(0.4)
	_tone(0.0, 0.36, 330.0, 880.0, 0.4, 3.0, TRI, 0.03, 7.0, 0.02)
	_tone(0.0, 0.36, 495.0, 1320.0, 0.25, 3.5, SINE, 0.03)
	_noise(0.0, 0.3, 0.3, 0.05, 3.0, 0.1, 0.5, true)
	_save("atk_magic", 0.68)
	_new(0.24)
	_tone(0.0, 0.2, 900.0, 300.0, 0.5, 6.0, SAW)
	_noise(0.0, 0.12, 0.5, 0.001, 8.0, 0.5, 0.3)
	_save("hit_magic", 0.68)
	_new(0.8)
	_tone(0.0, 0.75, 660.0, 165.0, 0.4, 3.0, SINE, 0.01, 6.0, 0.03)
	_tone(0.0, 0.75, 440.0, 110.0, 0.35, 3.0, TRI, 0.01)
	_noise(0.0, 0.5, 0.3, 0.03, 3.0, 0.1, 0.02)
	_save("death_magic", 0.72)


## Storm (Stormbottle Genie): a crackling zap-bolt; thunder crack on hit; a swirling fade on death.
func _storm() -> void:
	_new(0.4)
	_crackle(0.0, 0.3, 24, 0.5)
	_tone(0.0, 0.3, 1600.0, 500.0, 0.35, 5.0, SQUARE)
	_noise(0.0, 0.35, 0.4, 0.003, 4.0, 0.7, 0.3, true)
	_save("atk_storm", 0.7)
	_new(0.35)
	_noise(0.0, 0.3, 0.9, 0.001, 5.0, 0.6, 0.05)
	_tone(0.0, 0.25, 120.0, 50.0, 0.5, 5.0)
	_crackle(0.0, 0.15, 10, 0.4)
	_save("hit_storm", 0.72)
	_new(0.9)
	_noise(0.0, 0.85, 0.6, 0.1, 2.5, 0.05, 0.4, true)
	_tone(0.0, 0.85, 200.0, 800.0, 0.3, 2.5, TRI, 0.05, 5.0, 0.05)
	_crackle(0.2, 0.5, 12, 0.3)
	_save("death_storm", 0.72)


## Beasts (Grave Hound-like summons: Spirit Wolf, Briar Roc): a snarl-bite; a yelp on hit; a falling howl on death.
func _beast() -> void:
	_new(0.3)
	_tone(0.0, 0.22, 170.0, 130.0, 0.6, 3.0, SAW, 0.01, 28.0, 0.08)
	_noise(0.0, 0.2, 0.5, 0.01, 4.0, 0.3, 0.2)
	_noise(0.2, 0.05, 0.8, 0.0005, 9.0, 0.6, 0.4)
	_save("atk_beast", 0.7)
	_new(0.22)
	_tone(0.0, 0.18, 700.0, 420.0, 0.5, 5.0, TRI, 0.005, 12.0, 0.03)
	_noise(0.0, 0.08, 0.6, 0.001, 9.0, 0.45, 0.2)
	_save("hit_beast", 0.68)
	_new(0.8)
	_tone(0.0, 0.75, 620.0, 210.0, 0.5, 2.5, SAW, 0.03, 6.0, 0.03)
	_noise(0.0, 0.5, 0.3, 0.05, 3.0, 0.2, 0.05)
	_save("death_beast", 0.72)


# ---------------------------------------------------------------- building blocks (as tools/generate_sfx.gd)

func _new(duration: float) -> void:
	_buf = PackedFloat32Array()
	_buf.resize(int(duration * _lm * RATE))


func _tone(t0: float, dur: float, f0: float, f1: float, amp: float, decay: float, shape: int = SINE,
		attack: float = 0.004, vib_hz: float = 0.0, vib_depth: float = 0.0) -> void:
	t0 *= _lm
	dur *= _lm
	f0 *= _pm
	f1 *= _pm
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
	t0 *= _lm
	dur *= _lm
	lp0 = clampf(lp0 * _bright, 0.0005, 0.98)
	lp1 = clampf(lp1 * _bright, 0.0005, 0.98)
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


func _crackle(t0: float, dur: float, count: int, amp: float) -> void:
	for i in count:
		var t := t0 + _rng.randf() * dur
		_noise(t, 0.012 / _lm, amp * _rng.randf_range(0.4, 1.0), 0.0005, 6.0, 0.7, 0.5, true)   # clicks keep 12 ms


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


## Normalises _buf to `peak` (take 0) or to take 0's loudness (takes 1 / 2, capped at TAKE_PEAK), fades the last
## 8 ms, writes a 16-bit mono .wav (<id>.wav, <id>_1.wav, <id>_2.wav).
func _save(id: String, peak: float) -> void:
	var n := mini(int(0.008 * RATE), _buf.size())
	for k in n:
		_buf[_buf.size() - 1 - k] *= float(k) / float(n)
	var top := 0.0
	for v in _buf:
		top = maxf(top, absf(v))
	var gain := peak / top if top > 0.0 else 1.0
	if _take == 0:
		_ref[id] = _window_rms() * gain
	elif _ref.has(id) and top > 0.0:
		gain = minf(float(_ref[id]) / maxf(_window_rms(), 1e-6), TAKE_PEAK / top)
		id = "%s_%d" % [id, _take]
	_count += 1
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
		push_error("unit_sfx_generator: could not save %s (%d)" % [path, err])
	else:
		print("  %s  %.2f s" % [path, float(_buf.size()) / RATE])


## Max RMS over 200 ms windows (50 ms hop) of _buf, before gain: what a take's loudness is matched on.
func _window_rms() -> float:
	var win := int(0.2 * RATE)
	var hop := int(0.05 * RATE)
	var best := 0.0
	var s := 0
	while true:
		var e := mini(s + win, _buf.size())
		var acc := 0.0
		for i in range(s, e):
			acc += _buf[i] * _buf[i]
		best = maxf(best, sqrt(acc / float(maxi(1, win))))
		if e >= _buf.size():
			break
		s += hop
	return best

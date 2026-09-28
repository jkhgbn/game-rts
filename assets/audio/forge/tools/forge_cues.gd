extends SceneTree
## E34-B: the music and sound cues of the Episode 3 / 4 openings (docs/design/episode3-4-opening.md 6.1), synthesised
## until Sound Forge (tool 9) exists. Deterministic (fixed seeds), 32 kHz 16-bit stereo WAVs:
##   music/ep3_opening.wav  91 s, 60 bpm, A minor: low choir drone A1 E2, Malrik's falling glass-bell motif A4 C5 B4 E4
##                          every 2 bars, the heart-stone thump from bar 13, war drums from bar 22 (the horns)
##   music/ep4_opening.wav  88 s, 60 bpm, A major: warm string drone, Ysolde's rising wooden-flute motif E4 A4 G#4 C#5
##                          (Malrik's, inverted) every 2 bars, larks, the same drums from bar 21 (the same horn)
##   sfx/*.wav              evenmead_amb (20 s loop), evenmead_horns (a low Shadow horn answered by a higher Nature
##                          horn), shovel_earth, army_armour, candle_pinch, knife_ring, stone_thump, obren_whisper,
##                          snow_step, ice_creak, sapling_creak
## Run: tools\godot_run.ps1 --headless --path . -s res://assets/audio/forge/tools/forge_cues.gd --quit-after 90000
##      [-- only=music|sfx] ; then --import

const SR := 32000
const OUT := "res://assets/audio/forge/"
const A4 := 440.0

var _seed := 1
var only := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5)
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "music"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "sfx"))
	if only == "" or only == "sfx":
		_sfx_all()
	if only == "" or only == "music":
		_music_ep3()
		_music_ep4()
	print("forge_cues: done")
	quit(0)


# ================================================================ basics

func seed_rng(s: int) -> void:
	_seed = s * 2654435761 + 12345


func rnd() -> float:
	_seed = (_seed * 1103515245 + 12345) & 0x7fffffff
	return float(_seed) / 2147483647.0


func nz() -> float:
	return rnd() * 2.0 - 1.0


static func note(name: String) -> float:
	# "A4", "C#5", "G#4" -> Hz
	var names := {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3, "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
	var n := name.substr(0, name.length() - 1)
	var o := int(name.substr(name.length() - 1))
	return A4 * pow(2.0, (float(names[n]) + (o - 4) * 12.0) / 12.0)


func buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * SR))
	return b


## Adds mono src into stereo L / R at t0 with gain and pan (-1 left .. 1 right).
static func mix(l: PackedFloat32Array, r: PackedFloat32Array, src: PackedFloat32Array, t0: float, gain: float, pan := 0.0) -> void:
	var o := int(t0 * SR)
	var gl := gain * sqrt(0.5 * (1.0 - pan))
	var gr := gain * sqrt(0.5 * (1.0 + pan))
	var n := mini(src.size(), l.size() - o)
	for i in n:
		if o + i < 0:
			continue
		l[o + i] += src[i] * gl
		r[o + i] += src[i] * gr


## Schroeder reverb (4 combs + 2 allpasses per side, different lengths left / right), wet added in place.
static func reverb(l: PackedFloat32Array, r: PackedFloat32Array, wet: float, size := 1.0, damp := 0.35) -> void:
	for side in 2:
		var x: PackedFloat32Array = l if side == 0 else r
		var src := x.duplicate()
		var combs := [1116, 1188, 1277, 1356] if side == 0 else [1139, 1211, 1300, 1379]
		var out := PackedFloat32Array()
		out.resize(src.size())
		for cl in combs:
			var ln := int(cl * size * SR / 44100.0)
			var line := PackedFloat32Array()
			line.resize(ln)
			var idx := 0
			var lp := 0.0
			var fb := 0.84
			for i in src.size():
				var y := line[idx]
				lp = y * (1.0 - damp) + lp * damp
				line[idx] = src[i] + lp * fb
				idx = (idx + 1) % ln
				out[i] += y * 0.25
		for al in ([556, 441] if side == 0 else [579, 464]):
			var ln := int(al * SR / 44100.0)
			var line := PackedFloat32Array()
			line.resize(ln)
			var idx := 0
			for i in out.size():
				var b := line[idx]
				var y := -out[i] + b
				line[idx] = out[i] + b * 0.5
				idx = (idx + 1) % ln
				out[i] = y
		for i in x.size():
			x[i] += out[i] * wet


static func lowpass(x: PackedFloat32Array, cutoff: float) -> void:
	var a := 1.0 - exp(-TAU * cutoff / SR)
	var y := 0.0
	for i in x.size():
		y += a * (x[i] - y)
		x[i] = y


static func highpass(x: PackedFloat32Array, cutoff: float) -> void:
	var a := 1.0 - exp(-TAU * cutoff / SR)
	var y := 0.0
	for i in x.size():
		y += a * (x[i] - y)
		x[i] = x[i] - y


## Two-pole resonant band-pass (state-variable filter) at freq, q.
static func bandpass(x: PackedFloat32Array, freq: float, q: float) -> void:
	var f := 2.0 * sin(PI * freq / SR)
	var lo := 0.0
	var bp := 0.0
	var damp := 1.0 / q
	for i in x.size():
		var hi := x[i] - lo - damp * bp
		bp += f * hi
		lo += f * bp
		x[i] = bp


func save(path: String, l: PackedFloat32Array, r: PackedFloat32Array, peak_db := -1.0, fade_in := 0.005, fade_out := 0.02, trim := true) -> void:
	if trim:   # a cue fires on the frame: cut the lead silence (keep 3 ms before the first sample over -40 dB of the peak)
		var pk0 := 0.0001
		for i in l.size():
			pk0 = maxf(pk0, maxf(absf(l[i]), absf(r[i])))
		var first := 0
		while first < l.size() - 1 and maxf(absf(l[first]), absf(r[first])) < pk0 * 0.01:
			first += 1
		first = maxi(0, first - int(0.003 * SR))
		if first > 0:
			l = l.slice(first)
			r = r.slice(first)
	var n := l.size()
	var fi := int(fade_in * SR)
	var fo := int(fade_out * SR)
	for i in mini(fi, n):
		var g := float(i) / fi
		l[i] *= g
		r[i] *= g
	for i in mini(fo, n):
		var g := float(i) / fo
		l[n - 1 - i] *= g
		r[n - 1 - i] *= g
	var pk := 0.0001
	for i in n:
		pk = maxf(pk, maxf(absf(l[i]), absf(r[i])))
	var gain := pow(10.0, peak_db / 20.0) / pk
	var data := PackedByteArray()
	data.resize(n * 4)
	for i in n:
		data.encode_s16(i * 4, int(clampf(l[i] * gain, -1.0, 1.0) * 32767.0))
		data.encode_s16(i * 4 + 2, int(clampf(r[i] * gain, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.stereo = true
	w.mix_rate = SR
	w.data = data
	var err := w.save_to_wav(OUT + path)
	print("forge_cues: %s  %.2f s  (%s)" % [path, float(n) / SR, error_string(err)])


# ================================================================ instruments (mono buffers)

## Glass bell: inharmonic partials with their own decays, a soft strike.
func bell(freq: float, dur: float, amp := 1.0) -> PackedFloat32Array:
	var b := buf(dur)
	var parts := [[1.0, 1.0, 2.2], [2.0, 0.45, 1.4], [2.76, 0.35, 1.0], [5.4, 0.18, 0.5], [8.93, 0.08, 0.28]]
	for p: Array in parts:
		var f: float = freq * float(p[0])
		if f > SR * 0.45:
			continue
		var a: float = float(p[1]) * amp
		var dec: float = float(p[2]) * dur * 0.5
		var ph := 0.0
		for i in b.size():
			var t := float(i) / SR
			ph += TAU * f / SR
			b[i] += sin(ph) * a * exp(-t / dec) * minf(1.0, t * 400.0)
	return b


## Wooden flute: sine + a little 2nd / 3rd harmonic, breath noise, delayed vibrato, soft attack and release.
func flute(freq: float, dur: float, amp := 1.0) -> PackedFloat32Array:
	var b := buf(dur + 0.4)
	var ph := 0.0
	var br := 0.0
	for i in b.size():
		var t := float(i) / SR
		var env := minf(1.0, t / 0.09) * (1.0 if t < dur else exp(-(t - dur) / 0.12))
		var vib := 1.0 + 0.006 * sin(TAU * 5.2 * t) * clampf((t - 0.25) / 0.4, 0.0, 1.0)
		ph += TAU * freq * vib / SR
		br += 0.2 * (nz() - br)
		b[i] = (sin(ph) + 0.18 * sin(2.0 * ph) + 0.06 * sin(3.0 * ph) + 0.12 * br * (0.4 + 0.6 * exp(-t / 0.15))) * env * amp
	return b


## Brass horn: harmonics whose brightness follows the envelope, vibrato, a lip "blat" at the attack.
func horn(freq: float, dur: float, amp := 1.0, bright := 1.0) -> PackedFloat32Array:
	var b := buf(dur + 0.6)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / SR
		var env := smoothstep(0.0, 0.35, t) * (1.0 if t < dur else exp(-(t - dur) / 0.25)) * (0.85 + 0.15 * sin(TAU * 0.7 * t))
		var vib := 1.0 + 0.004 * sin(TAU * 4.6 * t) * smoothstep(0.4, 1.0, t) - 0.03 * exp(-t / 0.06)
		ph += TAU * freq * vib / SR
		var s := 0.0
		var k := 1
		var roll := 1.9 - 0.9 * env * bright
		while k <= 18 and freq * k < SR * 0.42:
			s += sin(ph * k) / pow(float(k), roll)
			k += 1
		b[i] = s * env * amp * 0.5
	return b


## Low choir / string drone voice: harmonics with an "ah" formant (choir) or 1/k saw (strings), 3 detuned copies.
func drone(freq: float, dur: float, choir: bool, amp := 1.0, swell := 0.15) -> PackedFloat32Array:
	var b := buf(dur)
	var ks := 14
	var w := PackedFloat32Array()
	for k in range(1, ks + 1):
		var f := freq * k
		if choir:
			w.append((1.0 / k) * (0.4 + 1.6 * exp(-pow((f - 650.0) / 180.0, 2.0)) + 0.9 * exp(-pow((f - 1080.0) / 220.0, 2.0)) + 0.3 * exp(-pow((f - 2600.0) / 400.0, 2.0))))
		else:
			w.append((1.0 / k) * (1.0 if f < 2500.0 else 0.3))
	# one period as a wavetable (the harmonics are fixed), read with a drifting phase: cheap enough for 90 s
	var tn := 2048
	var tab := PackedFloat32Array()
	tab.resize(tn + 1)
	for j in tn + 1:
		var a := TAU * float(j) / tn
		var s := 0.0
		for k in ks:
			if freq * (k + 1) > SR * 0.42:
				break
			s += sin(a * (k + 1)) * w[k]
		tab[j] = s
	for d in [-0.0022, 0.0, 0.0019]:
		var ph := rnd()
		for i in b.size():
			var t := float(i) / SR
			ph += freq * (1.0 + d + 0.0012 * sin(TAU * 0.23 * t + d * 900.0)) / SR
			ph -= floor(ph)
			var x := ph * tn
			var j := int(x)
			b[i] += lerpf(tab[j], tab[j + 1], x - j) * amp * (1.0 - swell + swell * sin(TAU * 0.11 * t + d * 500.0)) / 3.0
	return b


## A low drum: pitch-dropping sine + a noise skin, long decay.
func drum(freq: float, amp := 1.0, dec := 0.55) -> PackedFloat32Array:
	var b := buf(dec * 4.0)
	var ph := 0.0
	var lp := 0.0
	for i in b.size():
		var t := float(i) / SR
		var f := freq * (1.0 + 1.6 * exp(-t / 0.03))
		ph += TAU * f / SR
		lp += 0.25 * (nz() - lp)
		b[i] = (sin(ph) * exp(-t / dec) + lp * 0.5 * exp(-t / 0.04)) * amp
	return b


## The heart-stone thump: a deep, dull double beat (lub-dub) with stone grit.
func thump(amp := 1.0) -> PackedFloat32Array:
	var b := buf(0.9)
	for hit in [[0.0, 1.0, 58.0], [0.24, 0.65, 50.0]]:
		var t0: float = hit[0]
		var ph := 0.0
		for i in range(int(t0 * SR), b.size()):
			var t := float(i) / SR - t0
			ph += TAU * float(hit[2]) * (1.0 + 0.8 * exp(-t / 0.025)) / SR
			b[i] += (sin(ph) * exp(-t / 0.16) + nz() * 0.08 * exp(-t / 0.015)) * float(hit[1]) * amp
	return b


func chirp_bird(amp := 1.0) -> PackedFloat32Array:
	# a lark phrase: 3-7 fast warbled notes, 2.5-5 kHz
	var notes := 3 + int(rnd() * 5.0)
	var b := buf(0.12 * notes + 0.2)
	var ph := 0.0
	for k in notes:
		var f0 := 2500.0 + rnd() * 2400.0
		var f1 := f0 * (0.8 + rnd() * 0.5)
		var t0 := k * 0.11
		for i in range(int(t0 * SR), int((t0 + 0.09) * SR)):
			var t := float(i) / SR - t0
			var f := lerpf(f0, f1, t / 0.09) * (1.0 + 0.04 * sin(TAU * 70.0 * t))
			ph += TAU * f / SR
			b[i] += sin(ph) * sin(PI * t / 0.09) * amp
	return b


func clink(freq: float, amp := 1.0) -> PackedFloat32Array:
	var b := buf(0.5)
	for p in [[1.0, 1.0, 0.12], [2.41, 0.6, 0.08], [3.9, 0.4, 0.05], [6.1, 0.25, 0.03]]:
		var f: float = freq * float(p[0])
		if f > SR * 0.45:
			continue
		for i in b.size():
			var t := float(i) / SR
			b[i] += sin(TAU * f * t) * float(p[1]) * exp(-t / float(p[2])) * amp
	return b


func noise_burst(dur: float, amp: float, attack := 0.002, decay := 0.1) -> PackedFloat32Array:
	var b := buf(dur)
	for i in b.size():
		var t := float(i) / SR
		b[i] = nz() * amp * minf(1.0, t / attack) * exp(-t / decay)
	return b


# ================================================================ music

func _music_ep3() -> void:
	seed_rng(301)
	var dur := 91.0
	var l := buf(dur)
	var r := buf(dur)
	# the bed: a low choir on A1 + E2, swelling in over 7 s
	var d1 := drone(note("A1"), dur, true, 1.0, 0.2)
	var d2 := drone(note("E2"), dur, true, 0.7, 0.2)
	var d3 := drone(note("A2"), dur, true, 0.35, 0.25)
	for i in d1.size():
		var t := float(i) / SR
		var g := smoothstep(0.0, 7.0, t) * (1.0 - smoothstep(dur - 1.5, dur, t))
		d1[i] *= g
		d2[i] *= g
		d3[i] *= g * (0.5 + 0.5 * smoothstep(40.0, 60.0, t))
	lowpass(d1, 1400.0)
	lowpass(d2, 1500.0)
	mix(l, r, d1, 0.0, 0.5, -0.2)
	mix(l, r, d2, 0.0, 0.4, 0.25)
	mix(l, r, d3, 0.0, 0.3, 0.0)
	# a minor third in the choir from the Master's vanishing on (G06 ~ 30 s): C3 enters, low
	var dc := drone(note("C3"), dur - 28.0, true, 0.25, 0.3)
	for i in dc.size():
		dc[i] *= smoothstep(0.0, 6.0, float(i) / SR) * (1.0 - smoothstep(dur - 30.0, dur - 28.0, float(i) / SR))
	lowpass(dc, 1800.0)
	mix(l, r, dc, 28.0, 0.3, -0.4)
	# Malrik's motif: glass bells A4 C5 B4 E4, one per beat, every 2 bars from bar 2 (4 s); softer in the valley shots
	var motif := ["A4", "C5", "B4", "E4"]
	var bar := 4
	var k := 0
	while bar * 4.0 < dur - 8.0:
		var t0 := bar * 4.0
		for j in 4:
			var bl := bell(note(motif[j]), 3.2, 1.0)
			mix(l, r, bl, t0 + j * 1.0, 0.22 - 0.02 * (k % 2), -0.35 + 0.23 * j)
		bar += 2
		k += 1
	# the heart-stone from bar 13 (48 s): "x..x...." = beats 0 and 1.5 s of every bar
	var t := 48.0
	while t < dur - 2.0:
		for off in [0.0, 1.5]:
			if t + off < dur - 2.0:
				mix(l, r, thump(1.0), t + off, 0.55 * (0.7 + 0.3 * smoothstep(48.0, 80.0, t)), 0.0)
		t += 4.0
	# war drums from bar 22 (84 s): "x...x.x." = 0, 2, 3 s
	t = 84.0
	while t < dur - 0.5:
		for off in [0.0, 2.0, 3.0]:
			if t + off < dur - 0.3:
				mix(l, r, drum(62.0, 1.0, 0.6), t + off, 0.8, -0.15)
				mix(l, r, drum(92.0, 0.5, 0.35), t + off + 0.01, 0.4, 0.2)
		t += 4.0
	reverb(l, r, 0.32, 1.25, 0.4)
	save("music/ep3_opening.wav", l, r, -2.0, 0.5, 1.2, false)


func _music_ep4() -> void:
	seed_rng(401)
	var dur := 88.0
	var l := buf(dur)
	var r := buf(dur)
	var d1 := drone(note("A1"), dur, false, 1.0, 0.15)
	var d2 := drone(note("E2"), dur, false, 0.75, 0.15)
	var p1 := drone(note("A3"), dur, false, 0.22, 0.3)
	var p2 := drone(note("C#4"), dur, false, 0.18, 0.3)
	var p3 := drone(note("E4"), dur, false, 0.16, 0.3)
	for i in d1.size():
		var t := float(i) / SR
		var g := smoothstep(0.0, 6.0, t) * (1.0 - smoothstep(dur - 1.5, dur, t))
		var gp := smoothstep(6.0, 16.0, t) * (1.0 - smoothstep(dur - 3.0, dur, t))
		d1[i] *= g
		d2[i] *= g
		p1[i] *= gp
		p2[i] *= gp
		p3[i] *= gp
	for x in [d1, d2]:
		lowpass(x, 900.0)
	for x in [p1, p2, p3]:
		lowpass(x, 1800.0)
	mix(l, r, d1, 0.0, 0.45, -0.2)
	mix(l, r, d2, 0.0, 0.38, 0.2)
	mix(l, r, p1, 0.0, 0.3, -0.45)
	mix(l, r, p2, 0.0, 0.3, 0.1)
	mix(l, r, p3, 0.0, 0.3, 0.45)
	# Ysolde's motif: a wooden flute E4 A4 G#4 C#5 (Malrik's shape, rising), every 2 bars from bar 2 (4 s)
	var motif := ["E4", "A4", "G#4", "C#5"]
	var bar := 1
	while bar * 4.0 < dur - 8.0:
		var t0 := bar * 4.0
		for j in 4:
			var fl := flute(note(motif[j]), 0.85 if j < 3 else 1.6, 1.0)
			mix(l, r, fl, t0 + j * 1.0, 0.2, 0.15)
		bar += 2
	# larks over the valley
	var t := 1.5
	while t < dur - 3.0:
		mix(l, r, chirp_bird(1.0), t, 0.05 + 0.04 * rnd(), nz() * 0.8)
		t += 1.2 + rnd() * 2.6
	# war drums from bar 21 (80 s): the same pattern as Episode 3, the same horn
	t = 80.0
	while t < dur - 0.5:
		for off in [0.0, 2.0, 3.0]:
			if t + off < dur - 0.3:
				mix(l, r, drum(62.0, 1.0, 0.6), t + off, 0.8, 0.15)
				mix(l, r, drum(92.0, 0.5, 0.35), t + off + 0.01, 0.4, -0.2)
		t += 4.0
	reverb(l, r, 0.3, 1.2, 0.35)
	save("music/ep4_opening.wav", l, r, -2.0, 0.5, 1.2, false)


# ================================================================ sfx

func _sfx_all() -> void:
	_sfx_amb()
	_sfx_horns()
	_sfx_simple()


func _sfx_amb() -> void:
	# 20 s loop: wind in the grass, the river, larks, far armour
	seed_rng(501)
	var dur := 20.0
	var l := buf(dur)
	var r := buf(dur)
	var wind := buf(dur)
	var lp := 0.0
	var lp2 := 0.0
	for i in wind.size():
		var t := float(i) / SR
		var cut := 0.02 + 0.015 * sin(TAU * t / 10.0) + 0.008 * sin(TAU * t / 3.3)
		lp += cut * (nz() - lp)
		lp2 += cut * (lp - lp2)
		wind[i] = lp2 * (0.6 + 0.4 * sin(TAU * t / 5.0 + 1.0) * sin(TAU * t / 20.0 * 2.0))
	mix(l, r, wind, 0.0, 3.0, -0.3)
	var river := buf(dur)
	for i in river.size():
		river[i] = nz()
	bandpass(river, 1400.0, 1.2)
	lowpass(river, 3000.0)
	mix(l, r, river, 0.0, 0.08, 0.35)
	var t := 0.6
	while t < dur - 1.0:
		mix(l, r, chirp_bird(1.0), t, 0.1 + 0.06 * rnd(), nz() * 0.9)
		t += 0.8 + rnd() * 2.2
	t = 2.0
	while t < dur - 1.0:
		mix(l, r, clink(1800.0 + rnd() * 1600.0, 1.0), t, 0.02, nz() * 0.5)
		t += 1.5 + rnd() * 3.0
	reverb(l, r, 0.15, 1.3)
	# make the loop seamless: crossfade the last 1 s into the first
	var n := l.size()
	var cf := SR
	for i in cf:
		var g := float(i) / cf
		l[i] = l[i] * g + l[n - cf + i] * (1.0 - g)
		r[i] = r[i] * g + r[n - cf + i] * (1.0 - g)
	l.resize(n - cf)
	r.resize(n - cf)
	save("sfx/evenmead_amb.wav", l, r, -6.0, 0.0, 0.0, false)


func _sfx_horns() -> void:
	# a low Shadow horn (A2, dark) answered by a higher Nature horn (E3 rising to A3), the valley echoing both
	seed_rng(502)
	var l := buf(6.4)
	var r := buf(6.4)
	var h1 := horn(note("A2"), 2.3, 1.0, 0.7)
	var h1b := horn(note("A2") * 1.5, 2.3, 0.35, 0.6)
	mix(l, r, h1, 0.0, 0.7, -0.45)
	mix(l, r, h1b, 0.02, 0.5, -0.45)
	var h2 := horn(note("E3"), 1.2, 0.9, 1.0)
	var h3 := horn(note("A3"), 1.5, 0.9, 1.0)
	mix(l, r, h2, 2.6, 0.55, 0.45)
	mix(l, r, h3, 3.75, 0.55, 0.45)
	# the valley's echo
	var el := l.duplicate()
	var er := r.duplicate()
	var d := int(0.42 * SR)
	for i in range(d, l.size()):
		l[i] += er[i - d] * 0.28
		r[i] += el[i - d] * 0.28
	reverb(l, r, 0.4, 1.5, 0.3)
	save("sfx/evenmead_horns.wav", l, r, -10.0, 0.01, 0.4)


func _sfx_simple() -> void:
	# shovel_earth: a spade bites into earth, a scrape, the clod thrown
	seed_rng(503)
	var l := buf(1.6)
	var r := buf(1.6)
	var bite := noise_burst(0.3, 1.0, 0.003, 0.06)
	lowpass(bite, 700.0)
	mix(l, r, bite, 0.05, 1.0)
	var scrape := buf(0.45)
	for i in scrape.size():
		var t := float(i) / SR
		scrape[i] = nz() * sin(PI * t / 0.45)
	bandpass(scrape, 2200.0, 2.0)
	mix(l, r, scrape, 0.12, 0.5, 0.2)
	var fall := noise_burst(0.6, 1.0, 0.02, 0.12)
	lowpass(fall, 500.0)
	mix(l, r, fall, 0.85, 0.7, -0.3)
	reverb(l, r, 0.18, 0.8)
	save("sfx/shovel_earth.wav", l, r, -3.0)
	# army_armour: a rank settling: many small clinks + boots shifting
	seed_rng(504)
	l = buf(2.8)
	r = buf(2.8)
	for k in 26:
		mix(l, r, clink(1400.0 + rnd() * 2600.0, 1.0), rnd() * 2.2, 0.12 + 0.1 * rnd(), nz() * 0.9)
	for k in 8:
		var st := noise_burst(0.2, 1.0, 0.01, 0.05)
		lowpass(st, 400.0)
		mix(l, r, st, rnd() * 2.2, 0.35, nz() * 0.7)
	reverb(l, r, 0.22, 1.2)
	save("sfx/army_armour.wav", l, r, -4.0)
	# candle_pinch: a flame snuffed: a soft breath and a tiny hiss
	seed_rng(505)
	l = buf(0.7)
	r = buf(0.7)
	var pf := noise_burst(0.25, 1.0, 0.02, 0.07)
	bandpass(pf, 900.0, 0.8)
	mix(l, r, pf, 0.0, 1.0)
	var hs := noise_burst(0.5, 1.0, 0.01, 0.15)
	highpass(hs, 4000.0)
	mix(l, r, hs, 0.05, 0.25)
	reverb(l, r, 0.25, 1.0)
	save("sfx/candle_pinch.wav", l, r, -6.0)
	# knife_ring: a blade drawn and ringing
	seed_rng(506)
	l = buf(2.4)
	r = buf(2.4)
	var sc := buf(0.35)
	for i in sc.size():
		var t := float(i) / SR
		sc[i] = nz() * sin(PI * t / 0.35)
	bandpass(sc, 3200.0 + 0.0, 3.0)
	mix(l, r, sc, 0.0, 0.5, -0.2)
	var ring := buf(2.0)
	for p in [[1760.0, 1.0, 0.9], [2893.0, 0.6, 0.6], [4410.0, 0.4, 0.4], [6120.0, 0.2, 0.25]]:
		for i in ring.size():
			var t := float(i) / SR
			ring[i] += sin(TAU * float(p[0]) * t * (1.0 + 0.0015 * sin(TAU * 6.0 * t))) * float(p[1]) * exp(-t / float(p[2]))
	mix(l, r, ring, 0.3, 0.35, 0.2)
	reverb(l, r, 0.3, 1.1)
	save("sfx/knife_ring.wav", l, r, -5.0)
	# stone_thump: the heart-stone beating once (lub-dub)
	seed_rng(507)
	l = buf(1.2)
	r = buf(1.2)
	mix(l, r, thump(1.0), 0.0, 1.0)
	reverb(l, r, 0.3, 1.0)
	save("sfx/stone_thump.wav", l, r, -3.0)
	# obren_whisper: breath and stone grit, no words (formant-swept noise)
	seed_rng(508)
	l = buf(2.8)
	r = buf(2.8)
	for v in 3:
		var w := buf(2.5)
		var f := 2.0 * sin(PI * 600.0 / SR)
		var lo := 0.0
		var bp := 0.0
		for i in w.size():
			var t := float(i) / SR
			var fc := 500.0 + 900.0 * (0.5 + 0.5 * sin(TAU * (0.7 + v * 0.3) * t + v))
			f = 2.0 * sin(PI * fc / SR)
			var hi := nz() - lo - 0.25 * bp
			bp += f * hi
			lo += f * bp
			w[i] = bp * sin(PI * t / 2.5) * (0.6 + 0.4 * sin(TAU * 1.7 * t + v * 2.0))
		mix(l, r, w, 0.1 + v * 0.07, 0.25, -0.6 + v * 0.6)
	for k in 40:
		var g := noise_burst(0.01, 1.0, 0.0005, 0.002)
		mix(l, r, g, 0.2 + rnd() * 2.3, 0.2 * rnd(), nz())
	reverb(l, r, 0.35, 1.3)
	save("sfx/obren_whisper.wav", l, r, -6.0)
	# snow_step: two small steps crunching in snow
	seed_rng(509)
	l = buf(1.4)
	r = buf(1.4)
	for s in 2:
		var cr := buf(0.3)
		for i in cr.size():
			if rnd() < 0.08:
				cr[i] = nz() * (1.0 - float(i) / cr.size())
		bandpass(cr, 2600.0, 0.9)
		mix(l, r, cr, 0.1 + s * 0.62, 1.0, -0.2 + s * 0.4)
	reverb(l, r, 0.12, 0.9)
	save("sfx/snow_step.wav", l, r, -6.0)
	# ice_creak: frozen ash and wood creaking (stick-slip pulses through a resonance), a small crack
	seed_rng(510)
	l = buf(2.4)
	r = buf(2.4)
	var ck := buf(1.8)
	var next := 0.0
	for i in ck.size():
		var t := float(i) / SR
		if t >= next:
			ck[i] = 1.0
			next = t + 1.0 / (70.0 + 50.0 * sin(PI * t / 1.8) + nz() * 8.0)
	bandpass(ck, 420.0, 6.0)
	for i in ck.size():
		ck[i] *= sin(PI * float(i) / ck.size())
	mix(l, r, ck, 0.1, 1.0, -0.2)
	var pop := noise_burst(0.2, 1.0, 0.0005, 0.02)
	highpass(pop, 1500.0)
	mix(l, r, pop, 1.7, 0.6, 0.4)
	reverb(l, r, 0.3, 1.2)
	save("sfx/ice_creak.wav", l, r, -5.0)
	# sapling_creak: soft green wood bending + a leaf rustle
	seed_rng(511)
	l = buf(1.6)
	r = buf(1.6)
	var sk := buf(1.0)
	next = 0.0
	for i in sk.size():
		var t := float(i) / SR
		if t >= next:
			sk[i] = 1.0
			next = t + 1.0 / (140.0 + 60.0 * t + nz() * 10.0)
	bandpass(sk, 900.0, 5.0)
	for i in sk.size():
		sk[i] *= sin(PI * float(i) / sk.size()) * 0.6
	mix(l, r, sk, 0.05, 1.0, 0.1)
	var rs := noise_burst(0.9, 1.0, 0.1, 0.3)
	highpass(rs, 3000.0)
	mix(l, r, rs, 0.4, 0.3, -0.3)
	reverb(l, r, 0.2, 1.0)
	save("sfx/sapling_creak.wav", l, r, -8.0)

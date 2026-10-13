extends RefCounted
## Music Forge instrument kit (docs/design/music.md 3). Every recipe renders ONE note (or one section playing it) to a
## mono buffer at 22 050 Hz, starting at the onset and including its release / ring tail.
## Orchestral sections (style target 2026-10-13): strings, brass, flutes and choir render `section` voices, each with
## its own detune, vibrato rate / phase / drift and a 0-15 ms entry offset, so a part sounds like several players.
## Oscillators are band-limited (PolyBLEP saws / pulses; FM index and additive partials capped below 10 kHz).

const RATE := 22050
const NYQ_SAFE := 10000.0
const CENT := 0.000577622650466   # ln(2) / 1200


static func render(inst: String, f: float, gate: float, vel: float, rng: RandomNumberGenerator, opt: Dictionary) -> PackedFloat32Array:
	match inst:
		"harp":
			return _pluck(f, gate, vel, rng, 0.997, false, opt)
		"lute":
			return _pluck(f, gate, vel, rng, 0.990, true, opt)
		"strings", "violins", "violas", "cellos", "basses":
			return _bowed(f, gate, vel, rng, opt)
		"horns", "trumpets", "trombones", "brass":
			return _brass(f, gate, vel, rng, inst, opt)
		"flute", "fife", "whistle":
			return _flute(f, gate, vel, rng, inst, opt)
		"shawm":
			return _shawm(f, gate, vel, rng, opt)
		"glass", "celesta":
			return _fm_bell(f, vel, rng, 3.5 if inst == "glass" else 4.0, opt)
		"toll", "tubular":
			return _toll(f, vel, rng, inst == "tubular")
		"mallet":
			return _mallet(f, vel, rng)
		"timpani", "tom", "taiko", "frame_dum":
			return _membrane(f, vel, rng, inst)
		"frame_tek", "snare", "clap", "shaker":
			return _noise_hit(vel, rng, inst)
		"choir":
			return _choir(f, gate, vel, rng, opt)
		"pad":
			return _pad(f, gate, vel, rng)
	push_error("music_forge: unknown instrument %s" % inst)
	return PackedFloat32Array()


# ---------------------------------------------------------------- shared building blocks

## Per-sample normalised frequency (f / RATE) with delayed vibrato and a slow random drift.
static func _freq_curve(n: int, f: float, rng: RandomNumberGenerator, vib_hz: float, vib_cents: float,
		vib_delay: float, drift_cents: float) -> PackedFloat32Array:
	var fr := PackedFloat32Array()
	fr.resize(n)
	var base := f / RATE
	var ph := rng.randf() * TAU
	var w := TAU * vib_hz / RATE
	var d0 := int(vib_delay * RATE)
	var ramp := maxf(1.0, 0.3 * RATE)
	var drift := 0.0
	var dtarget := rng.randf_range(-drift_cents, drift_cents)
	for i in n:
		if i % 2205 == 0:
			dtarget = rng.randf_range(-drift_cents, drift_cents)
		drift += (dtarget - drift) * 0.0004
		var depth := 0.0
		if i > d0:
			depth = vib_cents * minf(1.0, float(i - d0) / ramp)
		var cents := depth * sin(ph + w * i) + drift
		fr[i] = base * (1.0 + cents * CENT)
	return fr


## Adds a band-limited saw (PolyBLEP) following `fr` x `mul` into out[off + i].
static func _add_saw(out: PackedFloat32Array, off: int, fr: PackedFloat32Array, mul: float, amp: float, p0: float) -> void:
	var p := p0
	var n := mini(fr.size(), out.size() - off)
	for i in n:
		var dt := fr[i] * mul
		p += dt
		if p >= 1.0:
			p -= 1.0
		var v := 2.0 * p - 1.0
		if p < dt:
			var t := p / dt
			v -= t + t - t * t - 1.0
		elif p > 1.0 - dt:
			var t2 := (p - 1.0) / dt
			v -= t2 * t2 + t2 + t2 + 1.0
		out[off + i] += v * amp


## Adds a band-limited pulse of duty `duty` (difference of two PolyBLEP saws, zero mean).
static func _add_pulse(out: PackedFloat32Array, off: int, fr: PackedFloat32Array, mul: float, amp: float, duty: float, p0: float) -> void:
	var p := p0
	var q := fmod(p0 + 1.0 - duty, 1.0)
	var n := mini(fr.size(), out.size() - off)
	for i in n:
		var dt := fr[i] * mul
		p += dt
		if p >= 1.0:
			p -= 1.0
		q += dt
		if q >= 1.0:
			q -= 1.0
		var a := 2.0 * p - 1.0
		if p < dt:
			var t := p / dt
			a -= t + t - t * t - 1.0
		elif p > 1.0 - dt:
			var t2 := (p - 1.0) / dt
			a -= t2 * t2 + t2 + t2 + 1.0
		var b := 2.0 * q - 1.0
		if q < dt:
			var t3 := q / dt
			b -= t3 + t3 - t3 * t3 - 1.0
		elif q > 1.0 - dt:
			var t4 := (q - 1.0) / dt
			b -= t4 * t4 + t4 + t4 + 1.0
		out[off + i] += (a - b) * amp * 0.5


## 2-pole state-variable low-pass (TPT) with a cutoff curve (coefficients refreshed every 16 samples), in place.
## `mode` 0 = low-pass, 1 = band-pass (unity peak).
static func _svf_var(buf: PackedFloat32Array, cut: PackedFloat32Array, q: float, mode: int = 0) -> void:
	var k := 1.0 / q
	var ic1 := 0.0
	var ic2 := 0.0
	var a1 := 0.0
	var a2 := 0.0
	var a3 := 0.0
	var n := buf.size()
	var cn := cut.size()
	for i in n:
		if i % 16 == 0:
			var fc := clampf(cut[mini(i, cn - 1)], 20.0, RATE * 0.45)
			var g := tan(PI * fc / RATE)
			a1 = 1.0 / (1.0 + g * (g + k))
			a2 = g * a1
			a3 = g * a2
		var v0 := buf[i]
		var v3 := v0 - ic2
		var v1 := a1 * ic1 + a2 * v3
		var v2 := ic2 + a2 * ic1 + a3 * v3
		ic1 = 2.0 * v1 - ic1
		ic2 = 2.0 * v2 - ic2
		buf[i] = v2 if mode == 0 else v1 * k


static func _const_curve(n: int, v: float) -> PackedFloat32Array:
	var c := PackedFloat32Array()
	c.resize(n)
	c.fill(v)
	return c


## Attack (raised sine) / sustain / release envelope; `swell` > 0 adds a slow bow / breath swell on long notes.
static func _env(n: int, att: float, gate: float, rel: float, swell: float = 0.0) -> PackedFloat32Array:
	var e := PackedFloat32Array()
	e.resize(n)
	var na := maxi(1, int(att * RATE))
	var ng := int(gate * RATE)
	var nr := maxi(1, int(rel * RATE))
	var level := 0.0
	for i in n:
		if i < ng:
			if i < na:
				level = 0.5 - 0.5 * cos(PI * float(i) / na)
			else:
				var t := float(i - na) / RATE
				level = 1.0 + swell * (sin(minf(t / maxf(gate - att, 0.1), 1.0) * PI) * 0.5 - 0.15)
			e[i] = level
		else:
			var r := float(i - ng) / nr
			e[i] = level * maxf(0.0, 1.0 - r) * maxf(0.0, 1.0 - r) if r < 1.0 else 0.0
	return e


static func _noise(n: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(n)
	for i in n:
		b[i] = rng.randf_range(-1.0, 1.0)
	return b


static func _bp(buf: PackedFloat32Array, fc: float, q: float) -> void:
	_run(buf, "bp", fc, q)


static func _run(buf: PackedFloat32Array, kind: String, fc: float, q: float, gain_db: float = 0.0) -> void:
	var c := _biquad(kind, fc, q, gain_db)
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in buf.size():
		var x := buf[i]
		var y := c[0] * x + c[1] * x1 + c[2] * x2 - c[3] * y1 - c[4] * y2
		x2 = x1; x1 = x; y2 = y1; y1 = y
		buf[i] = y


static func _biquad(kind: String, fc: float, q: float, gain_db: float) -> PackedFloat64Array:
	var w0 := TAU * clampf(fc, 10.0, RATE * 0.49) / RATE
	var cw := cos(w0)
	var alpha := sin(w0) / (2.0 * q)
	var a := pow(10.0, gain_db / 40.0)
	var r := PackedFloat64Array([1, 0, 0, 0, 0])
	var a0 := 1.0 + alpha
	match kind:
		"lp":
			r = PackedFloat64Array([(1.0 - cw) * 0.5, 1.0 - cw, (1.0 - cw) * 0.5, -2.0 * cw, 1.0 - alpha])
		"hp":
			r = PackedFloat64Array([(1.0 + cw) * 0.5, -(1.0 + cw), (1.0 + cw) * 0.5, -2.0 * cw, 1.0 - alpha])
		"bp":
			r = PackedFloat64Array([alpha, 0.0, -alpha, -2.0 * cw, 1.0 - alpha])
		"peak":
			a0 = 1.0 + alpha / a
			r = PackedFloat64Array([1.0 + alpha * a, -2.0 * cw, 1.0 - alpha * a, -2.0 * cw, 1.0 - alpha / a])
	for j in 5:
		r[j] /= a0
	return r


# ---------------------------------------------------------------- plucked strings (Karplus-Strong)

static func _pluck(f: float, gate: float, vel: float, rng: RandomNumberGenerator, loss: float, lute: bool, opt: Dictionary) -> PackedFloat32Array:
	var ring := (gate + 0.08) if lute else maxf(gate, 0.5) + float(opt.get("ring", 1.6))
	var n := int((ring + 0.15) * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var strings := 2 if lute else 1
	for s in strings:
		var fs := f * (pow(2.0, 4.0 / 1200.0) if s == 1 else 1.0)
		_ks_string(out, fs, vel, rng, loss, int(gate * RATE) if lute else -1, 0.5 if lute else 1.0)
	if lute:
		var b1 := out.duplicate()
		_run(b1, "bp", 110.0, 3.0)
		var b2 := out.duplicate()
		_run(b2, "bp", 400.0, 2.5)
		for i in n:
			out[i] += b1[i] * 0.6 + b2[i] * 0.45
	# fade the ring tail
	var nf := int(0.15 * RATE)
	for i in nf:
		out[n - nf + i] *= 1.0 - float(i) / nf
	return out


static func _ks_string(out: PackedFloat32Array, f: float, vel: float, rng: RandomNumberGenerator, loss: float, damp_at: int, amp: float) -> void:
	var period := float(RATE) / f
	var tot := period - 0.5
	var d := int(floor(tot - 0.1))
	d = maxi(d, 2)
	var frac := tot - d
	var c := (1.0 - frac) / (1.0 + frac)
	var line := PackedFloat32Array()
	line.resize(d)
	# excitation: low-passed noise burst, brightness by velocity, zero mean; pluck-position comb (1/8)
	var bright := clampf(0.3 + 0.5 * vel, 0.3, 0.8)   # spec range; mapped to a one-pole coefficient (warm harp)
	var lpc := 0.04 + 0.26 * bright * bright
	var y := 0.0
	var mean := 0.0
	for i in d:
		y += lpc * (rng.randf_range(-1.0, 1.0) - y)
		line[i] = y
		mean += y
	mean /= d
	var pp := maxi(1, int(d / 8))
	var exc := line.duplicate()
	for i in d:
		line[i] = (exc[i] - mean) - 0.5 * (exc[(i + pp) % d] - mean)
	var idx := 0
	var last := 0.0
	var ax := 0.0
	var ay := 0.0
	var l := loss
	var n := out.size()
	for i in n:
		if i == damp_at:
			l = 0.88
		var a := line[idx]
		var lp := 0.5 * (a + last)
		last = a
		var ap := c * lp + ax - c * ay
		ax = lp
		ay = ap
		line[idx] = ap * l
		idx += 1
		if idx >= d:
			idx = 0
		out[i] += a * amp * vel


# ---------------------------------------------------------------- bowed strings (section)

static func _bowed(f: float, gate: float, vel: float, rng: RandomNumberGenerator, opt: Dictionary) -> PackedFloat32Array:
	var sec := int(opt.get("section", 3))
	var trem := bool(opt.get("tremolo", false))
	var bright := float(opt.get("bright", 1.0))
	var att := lerpf(0.15, 0.08, clampf(vel, 0.0, 1.0)) * float(opt.get("attack_mul", 1.0))
	var rel := 0.2 * float(opt.get("release_mul", 1.0))
	var nv := int((gate + rel) * RATE)
	var max_off := int(0.010 * RATE)
	var out := PackedFloat32Array()
	out.resize(nv + max_off + 1)
	var env := _env(nv, att, gate, rel, 0.25)
	var cut := PackedFloat32Array()
	cut.resize(nv)
	var top := (1200.0 + 1800.0 * clampf(vel, 0.2, 1.0)) * bright
	for i in nv:
		cut[i] = 500.0 + (top - 500.0) * env[i] + f * 1.5
	var nsaw := 3 if sec == 1 else 2
	var dets := [-7.0, 7.0] if nsaw == 2 else [-7.0, 0.0, 7.0]
	var amp := 1.0 / (nsaw * sqrt(float(sec)))
	for v in sec:
		var off := 0 if v == 0 else rng.randi_range(0, max_off)
		var vf := f * (1.0 + rng.randf_range(-4.0, 4.0) * CENT) if v > 0 else f
		var fr := _freq_curve(nv, vf, rng, rng.randf_range(5.1, 5.9), rng.randf_range(12.0, 20.0), 0.3, 3.0)
		var vb := PackedFloat32Array()
		vb.resize(nv)
		for dc in dets:
			_add_saw(vb, 0, fr, 1.0 + float(dc) * CENT, amp, rng.randf())
		for i in nv:
			out[off + i] += vb[i] * env[i]
	# one filter for the whole section (same cutoff curve; the voice offsets are <= 10 ms)
	_svf_var(out, cut, 0.75)
	# bow noise: band-passed 2-4 kHz at -26 dB under the tone
	var nb := _noise(nv, rng)
	_run(nb, "bp", 3000.0, 1.1)
	var bn := 0.012 * sqrt(float(sec))
	for i in nv:
		out[i] += nb[i] * env[i] * bn
	if trem:
		var w := TAU * 12.0 / RATE
		for i in out.size():
			out[i] *= 0.6 + 0.4 * sin(w * i)
	return out


# ---------------------------------------------------------------- brass (section)

static func _brass(f: float, gate: float, vel: float, rng: RandomNumberGenerator, inst: String, opt: Dictionary) -> PackedFloat32Array:
	var sec := int(opt.get("section", 3 if inst != "brass" else 1))
	var muted := bool(opt.get("muted", false))
	var bright := float(opt.get("bright", {"horns": 0.75, "trumpets": 1.25, "trombones": 0.95}.get(inst, 1.0)))
	var att := lerpf(0.06, 0.025, clampf(vel, 0.0, 1.0)) * float(opt.get("attack_mul", 1.0))
	var rel := 0.15 * float(opt.get("release_mul", 1.0))
	var nv := int((gate + rel) * RATE)
	var max_off := int(0.015 * RATE)
	var out := PackedFloat32Array()
	out.resize(nv + max_off + 1)
	var env := _env(nv, att, gate, rel, 0.15)
	var peak := (900.0 + 1600.0 * clampf(vel, 0.0, 1.0)) * bright
	if muted:
		peak = minf(peak, 900.0)
	var cut := PackedFloat32Array()
	cut.resize(nv)
	var sweep := 0.12 * RATE
	for i in nv:
		var s := minf(1.0, float(i) / sweep)
		var c := 400.0 + (peak - 400.0) * s * (1.0 - 0.15 * minf(1.0, float(i) / RATE))
		cut[i] = maxf(f * 1.2, c * minf(1.0, env[i] * 1.3))
	var amp := 1.0 / (2.0 * sqrt(float(sec)))
	var scoop := int(0.06 * RATE)
	for v in sec:
		var off := 0 if v == 0 else rng.randi_range(0, max_off)
		var vf := f * (1.0 + rng.randf_range(-3.0, 3.0) * CENT) if v > 0 else f
		var fr := _freq_curve(nv, vf, rng, rng.randf_range(4.6, 5.4), rng.randf_range(6.0, 10.0), 0.4, 2.0)
		for i in mini(scoop, nv):
			fr[i] *= 1.0 - 30.0 * CENT * (1.0 - float(i) / scoop)
		var vb := PackedFloat32Array()
		vb.resize(nv)
		_add_saw(vb, 0, fr, 1.0 - 4.0 * CENT, amp, rng.randf())
		_add_saw(vb, 0, fr, 1.0 + 4.0 * CENT, amp, rng.randf())
		for i in nv:
			out[off + i] += vb[i] * env[i]
	_svf_var(out, cut, 1.1)
	if muted:
		var nas := out.duplicate()
		_run(nas, "bp", 1500.0, 3.0)
		for i in out.size():
			out[i] = out[i] * 0.6 + nas[i] * 0.9
	# breath at the attack
	var nb := _noise(int(0.05 * RATE), rng)
	_run(nb, "bp", 1800.0, 1.0)
	for i in mini(nb.size(), out.size()):
		out[i] += nb[i] * 0.05 * vel * (1.0 - float(i) / nb.size())
	return out


# ---------------------------------------------------------------- flute / fife / whistle

static func _flute(f: float, gate: float, vel: float, rng: RandomNumberGenerator, inst: String, opt: Dictionary) -> PackedFloat32Array:
	var sec := int(opt.get("section", 1))
	var h2 := 0.15
	var h3 := 0.05
	var breath := 0.126   # -18 dB
	if inst == "fife":
		h2 = 0.24; h3 = 0.1; breath = 0.16
	elif inst == "whistle":
		h2 = 0.08; h3 = 0.03; breath = 0.2
	var att := lerpf(0.09, 0.045, clampf(vel, 0.0, 1.0))
	var rel := 0.09
	var nv := int((gate + rel) * RATE)
	var max_off := int(0.012 * RATE)
	var out := PackedFloat32Array()
	out.resize(nv + max_off + 1)
	var env := _env(nv, att, gate, rel, 0.2)
	for v in sec:
		var off := 0 if v == 0 else rng.randi_range(4, max_off)
		var vf := f * (1.0 + rng.randf_range(-4.0, 4.0) * CENT) if v > 0 else f
		var fr := _freq_curve(nv, vf, rng, rng.randf_range(4.7, 5.3), 10.0, 0.35, 2.0)
		var ph := rng.randf() * TAU
		var amp := 1.0 / sqrt(float(sec))
		var a2 := h2 if fr[0] * 2.0 * RATE < NYQ_SAFE else 0.0
		var a3 := h3 if fr[0] * 3.0 * RATE < NYQ_SAFE else 0.0
		for i in nv:
			ph += TAU * fr[i]
			if ph > TAU:
				ph -= TAU
			var s := sin(ph)
			var c := cos(ph)
			out[off + i] += (s + a2 * 2.0 * s * c + a3 * (3.0 * s - 4.0 * s * s * s)) * env[i] * amp
	# breath noise band-passed at f (Q 2), with a slow wobble
	var nb := _noise(nv, rng)
	_run(nb, "bp", f, 2.0)
	var nb2 := _noise(nv, rng)
	_run(nb2, "bp", minf(f * 3.0, 6000.0), 1.0)
	var w := TAU * rng.randf_range(0.3, 0.7) / RATE
	for i in nv:
		out[i] += (nb[i] * breath + nb2[i] * breath * 0.12) * env[i] * (0.8 + 0.2 * sin(w * i))
	# 30 ms chiff
	var nc := int(0.03 * RATE)
	var ch := _noise(nc, rng)
	_run(ch, "bp", minf(f * 2.0, 5000.0), 1.5)
	for i in mini(nc, out.size()):
		out[i] += ch[i] * 0.35 * vel * (1.0 - float(i) / nc)
	return out


# ---------------------------------------------------------------- double reed (shawm)

static func _shawm(f: float, gate: float, vel: float, rng: RandomNumberGenerator, opt: Dictionary) -> PackedFloat32Array:
	var sec := int(opt.get("section", 1))
	var att := 0.03
	var rel := 0.08
	var nv := int((gate + rel) * RATE)
	var out := PackedFloat32Array()
	out.resize(nv + 200)
	var env := _env(nv, att, gate, rel, 0.12)
	for v in sec:
		var off := 0 if v == 0 else rng.randi_range(40, 200)
		var vf := f * (1.0 + rng.randf_range(-5.0, 5.0) * CENT) if v > 0 else f
		var fr := _freq_curve(nv, vf, rng, 6.0, 15.0, 0.2, 3.0)
		var vb := PackedFloat32Array()
		vb.resize(nv)
		_add_pulse(vb, 0, fr, 1.0, 1.0 / sqrt(float(sec)), 0.3, rng.randf())
		for i in nv:
			out[off + i] += vb[i] * env[i]
	var cut := _const_curve(1, 1800.0 + 700.0 * clampf(vel, 0.0, 1.0))
	_svf_var(out, cut, 0.8)
	var form := out.duplicate()
	_run(form, "bp", 1200.0, 3.0)
	var low := out.duplicate()
	_run(low, "bp", 600.0, 2.0)
	for i in out.size():
		out[i] = out[i] * 0.55 + form[i] * 1.4 + low[i] * 0.3
	return out


# ---------------------------------------------------------------- bells and mallets

static func _fm_bell(f: float, vel: float, rng: RandomNumberGenerator, ratio: float, opt: Dictionary) -> PackedFloat32Array:
	var decay := clampf(3.0 - (f - 400.0) / 600.0, 1.2, 3.0) * float(opt.get("decay_mul", 1.0))
	var n := int(decay * 2.0 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var i_max := clampf(NYQ_SAFE / (ratio * f) - 1.5, 0.3, 3.0)
	var i_min := minf(0.5, i_max)
	var wc := TAU * f / RATE
	var wm := wc * ratio
	var wc2 := wc * 1.0016
	var k_amp := 3.0 / (decay * RATE)
	var k_idx := 3.0 / (decay * RATE * 0.6)
	var pm := rng.randf() * TAU
	for i in n:
		var idx := i_min + (i_max - i_min) * exp(-k_idx * i)
		var a := exp(-k_amp * i) * minf(1.0, i / 40.0)
		var m := idx * sin(wm * i + pm)
		out[i] = (sin(wc * i + m) * 0.75 + sin(wc2 * i + m * 0.6) * 0.25) * a * vel
	return out


static func _toll(f: float, vel: float, rng: RandomNumberGenerator, tubular: bool) -> PackedFloat32Array:
	var ratios := [0.5, 1.0, 1.0016, 2.76, 5.4, 8.9]
	var decays := [5.0, 4.0, 4.0, 2.0, 1.0, 0.5]
	var amps := [0.35, 0.6, 0.4, 0.5, 0.3, 0.2] if not tubular else [0.1, 0.55, 0.35, 0.6, 0.45, 0.25]
	var n := int(5.0 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for p in ratios.size():
		var fp := f * float(ratios[p])
		if fp > NYQ_SAFE:
			continue
		var w := TAU * fp / RATE
		var k := 6.9 / (float(decays[p]) * RATE)
		var a: float = amps[p] * vel
		var ph := rng.randf() * TAU
		for i in n:
			out[i] += sin(w * i + ph) * a * exp(-k * i)
	var nc := int(0.012 * RATE)
	var ns := _noise(nc, rng)
	_run(ns, "bp", minf(f * 4.0, 6000.0), 1.0)
	for i in nc:
		out[i] += ns[i] * 0.3 * vel * (1.0 - float(i) / nc)
	for i in 30:
		out[i] *= float(i) / 30.0
	return out


static func _mallet(f: float, vel: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var ratios := [1.0, 3.93, 9.2]
	var decays := [0.6, 0.15, 0.05]
	var amps := [1.0, 0.35, 0.15]
	var n := int(0.9 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for p in 3:
		var fp := f * float(ratios[p])
		if fp > NYQ_SAFE:
			continue
		var w := TAU * fp / RATE
		var k := 6.9 / (float(decays[p]) * RATE)
		var a: float = amps[p] * vel
		for i in n:
			out[i] += sin(w * i) * a * exp(-k * i)
	var nc := int(0.005 * RATE)
	for i in nc:
		out[i] += rng.randf_range(-1.0, 1.0) * 0.25 * vel * (1.0 - float(i) / nc)
	return out


# ---------------------------------------------------------------- drums

static func _membrane(f: float, vel: float, rng: RandomNumberGenerator, inst: String) -> PackedFloat32Array:
	var ratios := [1.0]
	var amps := [1.0]
	var decays := [0.4]
	var drop := 0.3
	var drop_t := 0.06
	var noise_amp := 0.3
	var noise_len := 0.01
	var noise_fc := 1500.0
	match inst:
		"timpani":
			ratios = [1.0, 1.5, 1.98, 2.44]; amps = [1.0, 0.55, 0.4, 0.25]
			decays = [1.5, 1.0, 0.7, 0.5]; drop = 0.03; drop_t = 0.07; noise_amp = 0.25; noise_fc = 900.0
		"tom":
			ratios = [1.0, 1.6]; amps = [1.0, 0.3]; decays = [0.45, 0.2]
		"taiko":
			ratios = [1.0, 1.52, 2.1]; amps = [1.0, 0.35, 0.15]; decays = [0.9, 0.4, 0.25]
			drop = 0.25; drop_t = 0.07; noise_amp = 0.45; noise_len = 0.015; noise_fc = 700.0
		"frame_dum":
			ratios = [1.0, 1.7]; amps = [1.0, 0.25]; decays = [0.45, 0.15]
			drop = 0.12; noise_amp = 0.35; noise_len = 0.02; noise_fc = 800.0
	var dscale := lerpf(0.6, 1.0, clampf(vel, 0.0, 1.0))
	var n := int((float(decays[0]) * dscale + 0.1) * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var kd := 1.0 / (drop_t * RATE / 3.0)
	for p in ratios.size():
		var fp := f * float(ratios[p])
		var k := 6.9 / (float(decays[p]) * dscale * RATE)
		var a: float = amps[p] * vel
		var ph := 0.0
		for i in n:
			ph += TAU * fp * (1.0 + drop * exp(-kd * i)) / RATE
			out[i] += sin(ph) * a * exp(-k * i)
	var nc := int(noise_len * RATE)
	var ns := _noise(nc, rng)
	_run(ns, "lp", noise_fc, 0.7)
	for i in nc:
		out[i] += ns[i] * noise_amp * vel * (1.0 - float(i) / nc)
	for i in mini(20, n):
		out[i] *= float(i) / 20.0
	var nf := int(0.05 * RATE)
	for i in nf:
		out[n - nf + i] *= 1.0 - float(i) / nf
	return out


static func _noise_hit(vel: float, rng: RandomNumberGenerator, inst: String) -> PackedFloat32Array:
	var n := int(0.25 * RATE)
	var out := PackedFloat32Array()
	match inst:
		"frame_tek":
			n = int(0.12 * RATE)
			out = _noise(n, rng)
			_run(out, "bp", 2500.0, 1.2)
			var w := TAU * 420.0 / RATE
			for i in n:
				var t := float(i) / RATE
				out[i] = out[i] * exp(-t / 0.02) * 0.9 + sin(w * i) * exp(-t / 0.018) * 0.5
		"snare":
			out = _noise(n, rng)
			_run(out, "bp", 3000.0, 0.7)
			var w2 := TAU * 190.0 / RATE
			for i in n:
				var t2 := float(i) / RATE
				out[i] = out[i] * exp(-t2 / 0.045) * 1.2 + sin(w2 * i) * exp(-t2 / 0.03) * 0.6
		"clap":
			out = _noise(n, rng)
			_run(out, "bp", 1300.0, 1.0)
			for i in n:
				var t3 := float(i) / RATE
				var e := 0.0
				for b in 3:
					var tb := t3 - b * 0.010
					if tb >= 0.0:
						e += exp(-tb / 0.004) * 0.8
				if t3 >= 0.030:
					e += exp(-(t3 - 0.030) / 0.05) * 0.7
				out[i] *= e
		"shaker":
			n = int(0.1 * RATE)
			out = _noise(n, rng)
			_run(out, "hp", 2000.0, 0.7)
			_run(out, "hp", 2000.0, 0.7)
			for i in n:
				var t4 := float(i) / RATE
				out[i] *= minf(1.0, t4 / 0.012) * exp(-maxf(0.0, t4 - 0.012) / 0.025) * 0.7
	for i in out.size():
		out[i] *= vel
	for i in mini(12, out.size()):
		out[i] *= float(i) / 12.0
	return out


# ---------------------------------------------------------------- choir (formant)

const VOWELS := {
	"ah": [730.0, 1090.0, 2440.0],
	"oh": [570.0, 840.0, 2410.0],
	"oo": [300.0, 870.0, 2240.0],
}
const FORMANT_GAINS := [1.0, 0.5, 0.25]   # 0 / -6 / -12 dB
const FORMANT_WIDTHS := [80.0, 90.0, 120.0]


static func _choir(f: float, gate: float, vel: float, rng: RandomNumberGenerator, opt: Dictionary) -> PackedFloat32Array:
	var voices := int(opt.get("section", 5))
	var va: Array = VOWELS.get(str(opt.get("vowel", "ah")), VOWELS["ah"])
	var vb: Array = VOWELS.get(str(opt.get("vowel_to", opt.get("vowel", "ah"))), va)
	var att := 0.2 * float(opt.get("attack_mul", 1.0))
	var rel := 0.35
	var nv := int((gate + rel) * RATE)
	var max_off := int(0.02 * RATE)
	var src := PackedFloat32Array()
	src.resize(nv + max_off + 1)
	var env := _env(nv, att, gate, rel, 0.3)
	for v in voices:
		var off := 0 if v == 0 else rng.randi_range(0, max_off)
		var vf := f * (1.0 + rng.randf_range(-9.0, 9.0) * CENT)
		var fr := _freq_curve(nv, vf, rng, rng.randf_range(4.6, 5.4), 20.0, 0.25, 7.0)
		var vbuf := PackedFloat32Array()
		vbuf.resize(nv)
		_add_pulse(vbuf, 0, fr, 1.0, 1.0 / sqrt(float(voices)), rng.randf_range(0.18, 0.28), rng.randf())
		for i in nv:
			src[off + i] += vbuf[i] * env[i]
	# glottal tilt
	var y := 0.0
	var a := 1.0 - exp(-TAU * 900.0 / RATE)
	for i in src.size():
		y += a * (src[i] - y)
		src[i] = y
	# breath noise, shaped by the same formants
	var nb := _noise(src.size(), rng)
	for i in nv:
		src[i] += nb[i] * env[i] * 0.03
	var out := PackedFloat32Array()
	out.resize(src.size())
	var widen := maxf(1.0, f / 220.0)   # sung high notes: harmonics are far apart, widen so the vowel still speaks
	for k in 3:
		var band := src.duplicate()
		var cut := PackedFloat32Array()
		cut.resize(src.size())
		var f0: float = va[k]
		var f1: float = vb[k]
		for i in src.size():
			cut[i] = lerpf(f0, f1, minf(1.0, float(i) / maxf(1.0, nv * 0.7)))
		var q := ((f0 + f1) * 0.5) / (float(FORMANT_WIDTHS[k]) * widen)
		_svf_var(band, cut, q, 1)
		var g: float = FORMANT_GAINS[k]
		for i in out.size():
			out[i] += band[i] * g
	var body := src.duplicate()
	_run(body, "lp", 380.0, 0.7)
	for i in out.size():
		out[i] = (out[i] * 2.2 + body[i] * 0.5) * vel
	return out


# ---------------------------------------------------------------- pad (support only)

static func _pad(f: float, gate: float, vel: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var rel := 1.5
	var n := int((gate + rel) * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var env := _env(n, minf(1.0, gate * 0.5), gate, rel)
	var hs := [1.0, 2.0, 3.0]
	var ams := [1.0, 0.25, 0.1]
	for d in [-5.0, 5.0]:
		for h in 3:
			var fp := f * float(hs[h]) * (1.0 + float(d) * CENT)
			if fp > NYQ_SAFE:
				continue
			var w := TAU * fp / RATE
			var ph := rng.randf() * TAU
			var am: float = ams[h] * 0.5
			for i in n:
				out[i] += sin(w * i + ph) * am * env[i]
	for i in n:
		out[i] *= vel
	return out

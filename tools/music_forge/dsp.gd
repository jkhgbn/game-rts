extends RefCounted
## Music Forge DSP helpers (docs/design/music.md 3 and 5): biquads, the master limiter, the 16-bit mono WAV reader /
## writer and the audio check numbers (peak, RMS, integrated loudness BS.1770, loop seam, pad share).
## Static functions only; tests/test_music_forge.gd uses the same checks on the rendered files.

const RATE := 22050
const LN2_1200 := 0.000577622650466   # ln(2) / 1200: cents -> frequency ratio (1 + c * this, small c)


static func db2lin(db: float) -> float:
	return pow(10.0, db / 20.0)


static func lin2db(v: float) -> float:
	return 20.0 * log(maxf(v, 1e-9)) / log(10.0)


static func midi_hz(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


# ---------------------------------------------------------------- biquads (RBJ cookbook)

## Returns [b0, b1, b2, a1, a2] normalised by a0.
static func biquad(kind: String, fc: float, q: float, gain_db: float = 0.0, rate: int = RATE) -> PackedFloat64Array:
	var w0 := TAU * clampf(fc, 10.0, rate * 0.49) / rate
	var cw := cos(w0)
	var alpha := sin(w0) / (2.0 * q)
	var a := pow(10.0, gain_db / 40.0)
	var b0 := 1.0
	var b1 := 0.0
	var b2 := 0.0
	var a0 := 1.0
	var a1 := 0.0
	var a2 := 0.0
	match kind:
		"lp":
			b0 = (1.0 - cw) * 0.5; b1 = 1.0 - cw; b2 = b0
			a0 = 1.0 + alpha; a1 = -2.0 * cw; a2 = 1.0 - alpha
		"hp":
			b0 = (1.0 + cw) * 0.5; b1 = -(1.0 + cw); b2 = b0
			a0 = 1.0 + alpha; a1 = -2.0 * cw; a2 = 1.0 - alpha
		"bp":   # 0 dB peak
			b0 = alpha; b1 = 0.0; b2 = -alpha
			a0 = 1.0 + alpha; a1 = -2.0 * cw; a2 = 1.0 - alpha
		"peak":
			b0 = 1.0 + alpha * a; b1 = -2.0 * cw; b2 = 1.0 - alpha * a
			a0 = 1.0 + alpha / a; a1 = -2.0 * cw; a2 = 1.0 - alpha / a
		"highshelf":
			var sa := 2.0 * sqrt(a) * alpha
			b0 = a * ((a + 1.0) + (a - 1.0) * cw + sa)
			b1 = -2.0 * a * ((a - 1.0) + (a + 1.0) * cw)
			b2 = a * ((a + 1.0) + (a - 1.0) * cw - sa)
			a0 = (a + 1.0) - (a - 1.0) * cw + sa
			a1 = 2.0 * ((a - 1.0) - (a + 1.0) * cw)
			a2 = (a + 1.0) - (a - 1.0) * cw - sa
		"lowshelf":
			var sb := 2.0 * sqrt(a) * alpha
			b0 = a * ((a + 1.0) - (a - 1.0) * cw + sb)
			b1 = 2.0 * a * ((a - 1.0) - (a + 1.0) * cw)
			b2 = a * ((a + 1.0) - (a - 1.0) * cw - sb)
			a0 = (a + 1.0) + (a - 1.0) * cw + sb
			a1 = -2.0 * ((a - 1.0) + (a + 1.0) * cw)
			a2 = (a + 1.0) + (a - 1.0) * cw - sb
	return PackedFloat64Array([b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0])


## Runs a biquad over buf in place (from rest).
static func run_biquad(buf: PackedFloat32Array, c: PackedFloat64Array) -> void:
	var b0 := c[0]
	var b1 := c[1]
	var b2 := c[2]
	var a1 := c[3]
	var a2 := c[4]
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in buf.size():
		var x := buf[i]
		var y := b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1; x1 = x; y2 = y1; y1 = y
		buf[i] = y


## Applies a list of EQ bands [[kind, fc, q, gain_db], ...] in place.
static func run_eq(buf: PackedFloat32Array, bands: Array, rate: int = RATE) -> void:
	for b in bands:
		var band: Array = b
		run_biquad(buf, biquad(str(band[0]), float(band[1]), float(band[2]), float(band[3]) if band.size() > 3 else 0.0, rate))


# ---------------------------------------------------------------- master limiter

## Look-ahead block limiter: gain never lets |x| exceed `ceiling`, release `release_s`. `circular` = the buffer is a
## loop: the gain state is warmed up on the end of the loop so the seam sees the same gain on both sides.
static func limit(buf: PackedFloat32Array, ceiling: float, release_s: float, circular: bool) -> void:
	limit_ch([buf], ceiling, release_s, circular, RATE)


## Linked look-ahead limiter over 1 or 2 channels.
static func limit_ch(chans: Array, ceiling: float, release_s: float, circular: bool, rate: int) -> void:
	var buf: PackedFloat32Array = chans[0]
	var bs := 32 if rate <= RATE else 64
	var nb := int(ceil(float(buf.size()) / bs))
	var req := PackedFloat32Array()
	req.resize(nb)
	for b in nb:
		var pk := 0.0
		var e := mini((b + 1) * bs, buf.size())
		for c in chans:
			var cb: PackedFloat32Array = c
			for i in range(b * bs, e):
				pk = maxf(pk, absf(cb[i]))
		req[b] = minf(1.0, ceiling / pk) if pk > 0.0 else 1.0
	var gr := PackedFloat32Array()
	gr.resize(nb)
	for b in nb:
		var p := b - 1
		var n := b + 1
		if circular:
			p = posmod(p, nb); n = posmod(n, nb)
		else:
			p = maxi(p, 0); n = mini(n, nb - 1)
		gr[b] = minf(req[b], minf(req[p], req[n]))
	var rel := 1.0 - exp(-float(bs) / (release_s * rate))
	var gs := PackedFloat32Array()
	gs.resize(nb)
	var g := 1.0
	if circular:   # warm-up pass over the last blocks of the loop
		var warm := mini(nb, int(3.0 * rate / bs))
		for b in range(nb - warm, nb):
			g = gr[b] if gr[b] < g else g + (gr[b] - g) * rel
	for b in nb:
		g = gr[b] if gr[b] < g else g + (gr[b] - g) * rel
		gs[b] = g
	for b in nb:
		var g0 := gs[b]
		var g1 := gs[posmod(b + 1, nb)] if circular else gs[mini(b + 1, nb - 1)]
		var e2 := mini((b + 1) * bs, buf.size())
		for c in chans:
			var cb2: PackedFloat32Array = c
			for i in range(b * bs, e2):
				var t := float(i - b * bs) / bs
				cb2[i] *= g0 + (g1 - g0) * t   # both ends <= this block's need (neighbour min)
	for c in chans:   # insurance only (should never act)
		var cb3: PackedFloat32Array = c
		for i in cb3.size():
			var v := cb3[i]
			if absf(v) > ceiling:
				cb3[i] = signf(v) * ceiling


# ---------------------------------------------------------------- WAV I/O (16-bit mono PCM)

## 16-bit stereo (or mono when r is empty) WAV at `rate`.
static func write_wav2(path: String, l: PackedFloat32Array, r: PackedFloat32Array, rate: int) -> bool:
	var ch := 1 if r.is_empty() else 2
	var n := l.size()
	var bytes := PackedByteArray()
	bytes.resize(44 + n * 2 * ch)
	bytes.encode_u32(0, 0x46464952)
	bytes.encode_u32(4, 36 + n * 2 * ch)
	bytes.encode_u32(8, 0x45564157)
	bytes.encode_u32(12, 0x20746d66)
	bytes.encode_u32(16, 16)
	bytes.encode_u16(20, 1)
	bytes.encode_u16(22, ch)
	bytes.encode_u32(24, rate)
	bytes.encode_u32(28, rate * 2 * ch)
	bytes.encode_u16(32, 2 * ch)
	bytes.encode_u16(34, 16)
	bytes.encode_u32(36, 0x61746164)
	bytes.encode_u32(40, n * 2 * ch)
	for i in n:
		bytes.encode_s16(44 + i * 2 * ch, int(round(clampf(l[i], -1.0, 1.0) * 32767.0)))
		if ch == 2:
			bytes.encode_s16(46 + i * 4, int(round(clampf(r[i], -1.0, 1.0) * 32767.0)))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.close()
	return true


static func write_wav(path: String, buf: PackedFloat32Array) -> bool:
	var n := buf.size()
	var bytes := PackedByteArray()
	bytes.resize(44 + n * 2)
	bytes.encode_u32(0, 0x46464952)    # RIFF
	bytes.encode_u32(4, 36 + n * 2)
	bytes.encode_u32(8, 0x45564157)    # WAVE
	bytes.encode_u32(12, 0x20746d66)   # fmt
	bytes.encode_u32(16, 16)
	bytes.encode_u16(20, 1)
	bytes.encode_u16(22, 1)
	bytes.encode_u32(24, RATE)
	bytes.encode_u32(28, RATE * 2)
	bytes.encode_u16(32, 2)
	bytes.encode_u16(34, 16)
	bytes.encode_u32(36, 0x61746164)   # data
	bytes.encode_u32(40, n * 2)
	for i in n:
		bytes.encode_s16(44 + i * 2, int(round(clampf(buf[i], -1.0, 1.0) * 32767.0)))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.close()
	return true


## Reads a 16-bit PCM WAV. Returns {rate, channels, bits, samples: PackedFloat32Array} or {} on failure.
static func read_wav(path: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 44 or bytes.decode_u32(0) != 0x46464952:
		return {}
	var pos := 12
	var rate := 0
	var ch := 0
	var bits := 0
	while pos + 8 <= bytes.size():
		var id := bytes.decode_u32(pos)
		var sz := bytes.decode_u32(pos + 4)
		if id == 0x20746d66:
			ch = bytes.decode_u16(pos + 10)
			rate = bytes.decode_u32(pos + 12)
			bits = bytes.decode_u16(pos + 22)
		elif id == 0x61746164:
			var bps := int(bits / 8)
			var frames := int(sz / (bps * ch))
			var out := PackedFloat32Array()
			out.resize(frames)
			var right := PackedFloat32Array()
			if ch == 2:
				right.resize(frames)
			var p0 := pos + 8
			for i in frames:
				var at := p0 + i * bps * ch
				if bps == 2:
					out[i] = bytes.decode_s16(at) / 32768.0
					if ch == 2:
						right[i] = bytes.decode_s16(at + 2) / 32768.0
				elif bps == 3:
					out[i] = (bytes.decode_s16(at + 1) * 256 + bytes[at]) / 8388608.0
					if ch == 2:
						right[i] = (bytes.decode_s16(at + 4) * 256 + bytes[at + 3]) / 8388608.0
			return {"rate": rate, "channels": ch, "bits": bits, "samples": out, "right": right}
		pos += 8 + sz + (sz & 1)
	return {}


# ---------------------------------------------------------------- audio check numbers

static func peak_db(buf: PackedFloat32Array) -> float:
	var pk := 0.0
	for v in buf:
		pk = maxf(pk, absf(v))
	return lin2db(pk)


static func rms_db(buf: PackedFloat32Array) -> float:
	var s := 0.0
	for v in buf:
		s += v * v
	return lin2db(sqrt(s / maxf(1.0, buf.size())))


## Integrated loudness (BS.1770-4: K-weighting, 400 ms blocks, 75 % overlap, -70 LUFS absolute and -10 LU relative gates).
static func lufs(buf: PackedFloat32Array) -> float:
	return lufs_ch([buf], RATE)


## Integrated loudness of 1 or 2 channels (channel powers summed, BS.1770 weights 1.0).
static func lufs_ch(chans: Array, rate: int) -> float:
	var n0: int = (chans[0] as PackedFloat32Array).size()
	var hop := int(0.1 * rate)
	var nh := int(n0 / hop)
	var hs := PackedFloat64Array()
	hs.resize(nh)
	for c in chans:
		var k: PackedFloat32Array = (c as PackedFloat32Array).duplicate()
		run_biquad(k, biquad("highshelf", 1500.0, 0.7071, 4.0, rate))
		run_biquad(k, biquad("hp", 38.0, 0.5, rate))
		for h in nh:
			var s := 0.0
			for i in range(h * hop, (h + 1) * hop):
				s += k[i] * k[i]
			hs[h] += s
	var blocks := PackedFloat64Array()
	for b in range(0, nh - 3):
		blocks.append((hs[b] + hs[b + 1] + hs[b + 2] + hs[b + 3]) / (4.0 * hop))
	if blocks.is_empty():
		return -70.0
	var abs_gate := pow(10.0, (-70.0 + 0.691) / 10.0)
	var s1 := 0.0
	var c1 := 0
	for z in blocks:
		if z > abs_gate:
			s1 += z; c1 += 1
	if c1 == 0:
		return -70.0
	var rel_gate := (s1 / c1) * 0.1
	var s2 := 0.0
	var c2 := 0
	for z in blocks:
		if z > abs_gate and z > rel_gate:
			s2 += z; c2 += 1
	return -0.691 + 10.0 * log(s2 / c2) / log(10.0)


## Loop seam: [|last - first|, |slope at the end - slope at the start|].
static func seam(buf: PackedFloat32Array) -> Vector2:
	var n := buf.size()
	var step := absf(buf[n - 1] - buf[0])
	var slope := absf((buf[1] - buf[0]) - (buf[n - 1] - buf[n - 2]))
	return Vector2(step, slope)


## Share of energy above ~6 kHz (ear-proxy for harsh / aliased highs).
static func hf_share(buf: PackedFloat32Array) -> float:
	var h := buf.duplicate()
	run_biquad(h, biquad("hp", 6000.0, 0.7071))
	run_biquad(h, biquad("hp", 6000.0, 0.7071))
	var eh := 0.0
	var et := 0.0
	for i in buf.size():
		eh += h[i] * h[i]
		et += buf[i] * buf[i]
	return eh / maxf(et, 1e-12)

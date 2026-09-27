extends RefCounted
## Audio Lab (docs/plan/audio-lab.md): measures one AudioStream without playing it.
## Headless runs use the Dummy audio driver, so the stream is decoded with AudioStreamPlayback.mix_audio() (the same
## decoder the game uses: PCM, IMA-ADPCM, QOA, Ogg Vorbis, MP3), at the AudioServer mix rate (44.1 kHz), as the
## stereo frames a 2D player would send to its bus at volume 0 dB. A mono file comes out as dual mono (L = R), which
## is also how the game hears it, so loudness numbers are "as heard in game" before the player's volume_db.
## Loudness follows ITU-R BS.1770 (K-weighting, 400 ms blocks, -70 / -10 LU gates); "LUFS" here means that
## approximation (no 48 kHz resampling, no channel weights beyond L + R). True peak = 4x Catmull-Rom oversampling
## near the sample peak (an estimate, within ~0.5 dB of a real meter).

const MAX_SECONDS := 600.0          ## Never decode more than this (looping or broken streams).
const SPECTRUM_SECONDS := 10.0      ## Band split on the first 10 s only (music): enough for a balance estimate.
const CHUNK := 8192
const LEAD_THRESHOLD := 0.00316     ## -50 dBFS: the sound has started.
const TRAIL_THRESHOLD := 0.001      ## -60 dBFS: the sound is over.
const CLIP_LEVEL := 0.999
const BAND_EDGES: Array[float] = [250.0, 2000.0, 6000.0]
const BAND_NAMES: Array[String] = ["low", "mid", "presence", "air"]   ## <250 / 250-2k / 2k-6k / >6k Hz


## Decodes `stream` to stereo float frames. Returns {frames: PackedVector2Array, rate: float, ok: bool, why: String}.
static func decode(stream: AudioStream) -> Dictionary:
	var out := {"frames": PackedVector2Array(), "rate": AudioServer.get_mix_rate(), "ok": false, "why": ""}
	if stream == null:
		out["why"] = "no stream"
		return out
	if stream is AudioStreamGenerator:
		out["why"] = "AudioStreamGenerator: filled by code at run time (listen in the preview scene)"
		return out
	var pb := stream.instantiate_playback()
	if pb == null or not pb.has_method(&"mix_audio"):
		out["why"] = "no playback / mix_audio for %s" % stream.get_class()
		return out
	var rate: float = AudioServer.get_mix_rate()
	var length := stream.get_length()
	var cap := int((length + 0.05) * rate) if length > 0.0 else int(60.0 * rate)
	cap = mini(cap, int(MAX_SECONDS * rate))
	pb.start(0.0)
	var frames := PackedVector2Array()
	var guard := 0
	while frames.size() < cap and guard < 100000:
		guard += 1
		var n := mini(CHUNK, cap - frames.size())
		var part: PackedVector2Array = pb.mix_audio(1.0, n)
		if part.is_empty():
			break
		frames.append_array(part)
		if not pb.is_playing():
			break
	pb.stop()
	# The mixer can pad the last chunk with zeros after the stream ended: cut to the stream length.
	if length > 0.0:
		var want := int(ceil(length * rate))
		if frames.size() > want:
			frames.resize(want)
	out["frames"] = frames
	out["rate"] = rate
	out["ok"] = frames.size() > 0
	if frames.is_empty():
		out["why"] = "decoded 0 frames"
	return out


static func db(x: float) -> float:
	return -INF if x <= 0.0 else 20.0 * log(x) / log(10.0)


static func pow_db(x: float) -> float:
	return -INF if x <= 0.0 else 10.0 * log(x) / log(10.0)


## Biquad coefficients [b0, b1, b2, a1, a2] (a0 normalised).
static func _lowpass(f: float, rate: float, q: float = 0.70710678) -> PackedFloat64Array:
	var w0 := TAU * f / rate
	var cw := cos(w0)
	var alpha := sin(w0) / (2.0 * q)
	var a0 := 1.0 + alpha
	return PackedFloat64Array([(1.0 - cw) * 0.5 / a0, (1.0 - cw) / a0, (1.0 - cw) * 0.5 / a0, -2.0 * cw / a0,
			(1.0 - alpha) / a0])


static func _highpass(f: float, rate: float, q: float = 0.70710678) -> PackedFloat64Array:
	var w0 := TAU * f / rate
	var cw := cos(w0)
	var alpha := sin(w0) / (2.0 * q)
	var a0 := 1.0 + alpha
	return PackedFloat64Array([(1.0 + cw) * 0.5 / a0, -(1.0 + cw) / a0, (1.0 + cw) * 0.5 / a0, -2.0 * cw / a0,
			(1.0 - alpha) / a0])


static func _filt(x: PackedFloat64Array, c: PackedFloat64Array) -> PackedFloat64Array:
	var y := PackedFloat64Array()
	y.resize(x.size())
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	var b0 := c[0]
	var b1 := c[1]
	var b2 := c[2]
	var a1 := c[3]
	var a2 := c[4]
	for i in x.size():
		var v := x[i]
		var o := b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = v
		y2 = y1
		y1 = o
		y[i] = o
	return y


static func _energy(x: PackedFloat64Array) -> float:
	var e := 0.0
	for v in x:
		e += v * v
	return e


## BS.1770 stage 1 (high shelf, +4 dB above ~1.7 kHz) for any rate (pyloudnorm's derivation).
static func _k_shelf(rate: float) -> PackedFloat64Array:
	var g := 3.999843853973347
	var q := 0.7071752369554196
	var fc := 1681.974450955533
	var a := pow(10.0, g / 40.0)
	var w0 := TAU * fc / rate
	var cw := cos(w0)
	var alpha := sin(w0) / (2.0 * q)
	var sa := 2.0 * sqrt(a) * alpha
	var a0 := (a + 1.0) - (a - 1.0) * cw + sa
	return PackedFloat64Array([
		a * ((a + 1.0) + (a - 1.0) * cw + sa) / a0,
		-2.0 * a * ((a - 1.0) + (a + 1.0) * cw) / a0,
		a * ((a + 1.0) + (a - 1.0) * cw - sa) / a0,
		2.0 * ((a - 1.0) - (a + 1.0) * cw) / a0,
		((a + 1.0) - (a - 1.0) * cw - sa) / a0])


## BS.1770 stage 2 (RLB high-pass, ~38 Hz).
static func _k_highpass(rate: float) -> PackedFloat64Array:
	var q := 0.5003270373238773
	var fc := 38.13547087602444
	var w0 := TAU * fc / rate
	var cw := cos(w0)
	var alpha := sin(w0) / (2.0 * q)
	var a0 := 1.0 + alpha
	return PackedFloat64Array([(1.0 + cw) * 0.5 / a0, -(1.0 + cw) / a0, (1.0 + cw) * 0.5 / a0, -2.0 * cw / a0,
			(1.0 - alpha) / a0])


## Every measure the checks need. `frames` from decode(). Keys (dB values are -INF for silence):
##   duration_s, rate, dual_mono, peak_dbfs, true_peak_dbtp, clipped (runs of >= 2 samples at full scale),
##   rms_dbfs, lufs_i (gated integrated), lufs_m_max (momentary max, 400 ms, zero-padded), lead_ms, trail_ms,
##   decay_ms (envelope max -> 30 dB down), end_db (RMS of the last 10 ms), first_abs, last_abs, dc,
##   bands {low, mid, presence, air} energy shares 0-1, seam_jump (|last - first| sample, for loops)
static func measure(frames: PackedVector2Array, rate: float) -> Dictionary:
	var n := frames.size()
	var m := {"duration_s": float(n) / rate, "rate": rate, "frames": n}
	if n == 0:
		return m
	# ---- pass 1: peaks, dual mono, DC, lead / trail, RMS
	var peak := 0.0
	var peak_i := 0
	var dual := true
	var sum_sq := 0.0
	var dc := 0.0
	var first_on := -1
	var last_on := -1
	var clipped := 0
	var run := 0
	for i in n:
		var f := frames[i]
		var al := absf(f.x)
		var ar := absf(f.y)
		var a := maxf(al, ar)
		if a > peak:
			peak = a
			peak_i = i
		if dual and absf(f.x - f.y) > 0.0001:
			dual = false
		sum_sq += f.x * f.x + f.y * f.y
		dc += f.x + f.y
		if a > LEAD_THRESHOLD and first_on < 0:
			first_on = i
		if a > TRAIL_THRESHOLD:
			last_on = i
		if a >= CLIP_LEVEL:
			run += 1
			if run == 2:
				clipped += 1
		else:
			run = 0
	m["dual_mono"] = dual
	m["peak_dbfs"] = db(peak)
	m["rms_dbfs"] = pow_db(sum_sq / (2.0 * n))
	m["dc"] = dc / (2.0 * n)
	m["clipped"] = clipped
	m["lead_ms"] = (float(first_on) / rate * 1000.0) if first_on >= 0 else m["duration_s"] * 1000.0
	m["trail_ms"] = (float(n - 1 - last_on) / rate * 1000.0) if last_on >= 0 else m["duration_s"] * 1000.0
	m["first_abs"] = maxf(absf(frames[0].x), absf(frames[0].y))
	m["last_abs"] = maxf(absf(frames[n - 1].x), absf(frames[n - 1].y))
	m["seam_jump"] = maxf(absf(frames[n - 1].x - frames[0].x), absf(frames[n - 1].y - frames[0].y))
	m["peak_at_s"] = float(peak_i) / rate
	# ---- true peak: 4x Catmull-Rom around the samples within 6 dB of the sample peak
	var tp := peak
	var near := peak * 0.5
	for ch in 2:
		for i in range(1, n - 2):
			var p1 := frames[i].x if ch == 0 else frames[i].y
			var p2 := frames[i + 1].x if ch == 0 else frames[i + 1].y
			if absf(p1) < near and absf(p2) < near:
				continue
			var p0 := frames[i - 1].x if ch == 0 else frames[i - 1].y
			var p3 := frames[i + 2].x if ch == 0 else frames[i + 2].y
			for k in 3:
				var t := 0.25 * float(k + 1)
				var t2 := t * t
				var v := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 \
						+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t2 * t)
				tp = maxf(tp, absf(v))
	m["true_peak_dbtp"] = db(tp)
	# ---- pass 2: K-weighted power per 100 ms block (both channels; dual mono = one channel x 2)
	var sh := _k_shelf(rate)
	var hp := _k_highpass(rate)
	var block := int(rate * 0.1)
	var blocks := PackedFloat64Array()
	var chans := 1 if dual else 2
	var acc := PackedFloat64Array()
	acc.resize(int(ceil(float(n) / block)))
	acc.fill(0.0)
	var gain := 2.0 if dual else 1.0
	for ch in chans:
		var x1 := 0.0
		var x2 := 0.0
		var y1 := 0.0
		var y2 := 0.0
		var u1 := 0.0
		var u2 := 0.0
		var z1 := 0.0
		var z2 := 0.0
		var bi := 0
		var bleft := block
		for i in n:
			var x := frames[i].x if ch == 0 else frames[i].y
			var y := sh[0] * x + sh[1] * x1 + sh[2] * x2 - sh[3] * y1 - sh[4] * y2
			x2 = x1
			x1 = x
			y2 = y1
			y1 = y
			var z := hp[0] * y + hp[1] * u1 + hp[2] * u2 - hp[3] * z1 - hp[4] * z2
			u2 = u1
			u1 = y
			z2 = z1
			z1 = z
			acc[bi] += z * z * gain
			bleft -= 1
			if bleft == 0:
				bleft = block
				bi += 1
	blocks = acc
	# 400 ms windows (4 blocks, BS.1770 momentary) and 200 ms windows (2 blocks, the lab's "cue loudness": short
	# sounds are heard over ~200 ms, a 400 ms window under-reads clicks by up to 6 dB), 100 ms hop, zero-padded.
	var nb := maxi(blocks.size(), 4)
	var win_power := PackedFloat64Array()
	var win_frames := float(block * 4)
	var smax := 0.0
	for s in range(0, nb - 3):
		var p := 0.0
		for k in 4:
			if s + k < blocks.size():
				p += blocks[s + k]
		win_power.append(p / win_frames)
	for s in range(0, maxi(blocks.size() - 1, 1)):
		var p2 := blocks[s] + (blocks[s + 1] if s + 1 < blocks.size() else 0.0)
		smax = maxf(smax, p2 / float(block * 2))
	var mmax := 0.0
	for p in win_power:
		mmax = maxf(mmax, p)
	m["lufs_m_max"] = -0.691 + pow_db(mmax) if mmax > 0.0 else -INF
	m["lufs_cue"] = -0.691 + pow_db(smax) if smax > 0.0 else -INF
	# Integrated: absolute gate -70, relative gate -10 LU.
	var abs_gate := pow(10.0, (-70.0 + 0.691) / 10.0)
	var sum1 := 0.0
	var c1 := 0
	for p in win_power:
		if p > abs_gate:
			sum1 += p
			c1 += 1
	if c1 == 0:
		m["lufs_i"] = -INF
	else:
		var rel := (sum1 / c1) * pow(10.0, -1.0)
		var sum2 := 0.0
		var c2 := 0
		for p in win_power:
			if p > abs_gate and p > rel:
				sum2 += p
				c2 += 1
		m["lufs_i"] = -0.691 + pow_db(sum2 / maxi(c2, 1))
	# ---- envelope: 10 ms RMS for decay and the end level
	var env_step := maxi(int(rate * 0.01), 1)
	var env := PackedFloat64Array()
	var e := 0.0
	var cnt := 0
	for i in n:
		var f := frames[i]
		e += (f.x * f.x + f.y * f.y) * 0.5
		cnt += 1
		if cnt == env_step or i == n - 1:
			env.append(e / cnt)
			e = 0.0
			cnt = 0
	var emax := 0.0
	var emax_i := 0
	for i in env.size():
		if env[i] > emax:
			emax = env[i]
			emax_i = i
	var decay_i := env.size() - 1
	var down := emax * 0.001   # -30 dB
	for i in range(emax_i, env.size()):
		if env[i] < down:
			decay_i = i
			break
	m["decay_ms"] = float(decay_i - emax_i) * env_step / rate * 1000.0
	m["end_db"] = pow_db(env[env.size() - 1])
	m["env_max_db"] = pow_db(emax)
	# ---- pass 3: band split on the mono sum (first SPECTRUM_SECONDS), 4th-order Linkwitz-Riley band-passes
	var ns := mini(n, int(SPECTRUM_SECONDS * rate))
	var mono := PackedFloat64Array()
	mono.resize(ns)
	for i in ns:
		mono[i] = (frames[i].x + frames[i].y) * 0.5
	var lp0 := _lowpass(BAND_EDGES[0], rate)
	var hp0 := _highpass(BAND_EDGES[0], rate)
	var lp1 := _lowpass(BAND_EDGES[1], rate)
	var hp1 := _highpass(BAND_EDGES[1], rate)
	var lp2 := _lowpass(BAND_EDGES[2], rate)
	var hp2 := _highpass(BAND_EDGES[2], rate)
	var en := PackedFloat64Array([
		_energy(_filt(_filt(mono, lp0), lp0)),
		_energy(_filt(_filt(_filt(_filt(mono, hp0), hp0), lp1), lp1)),
		_energy(_filt(_filt(_filt(_filt(mono, hp1), hp1), lp2), lp2)),
		_energy(_filt(_filt(mono, hp2), hp2))])
	var tot := en[0] + en[1] + en[2] + en[3]
	var bands := {}
	for b in 4:
		bands[BAND_NAMES[b]] = (en[b] / tot) if tot > 0.0 else 0.0
	m["bands"] = bands
	return m


## Sample peak (dBFS) of the SOURCE .wav (8 / 16 / 24-bit PCM, read from the file, not the imported stream).
## Compared with the decoded peak it shows what the import did (QOA overshoots up to ~7 dB on harmonic tones).
## Returns NAN when the file is not a PCM .wav this reader understands.
static func source_peak_dbfs(path: String) -> float:
	if path.get_extension().to_lower() != "wav":
		return NAN
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return NAN
	var buf := f.get_buffer(f.get_length())
	f.close()
	if buf.size() < 44 or buf.slice(0, 4).get_string_from_ascii() != "RIFF":
		return NAN
	var bits := 0
	var fmt_tag := 0
	var i := 12
	while i + 8 <= buf.size():
		var id := buf.slice(i, i + 4).get_string_from_ascii()
		var size := buf.decode_u32(i + 4)
		if id == "fmt ":
			fmt_tag = buf.decode_u16(i + 8)
			bits = buf.decode_u16(i + 22)
		elif id == "data":
			if fmt_tag != 1 and fmt_tag != 0xFFFE:
				return NAN
			var end := mini(i + 8 + size, buf.size())
			var peak := 0.0
			var j := i + 8
			match bits:
				16:
					while j + 1 < end:
						peak = maxf(peak, absf(float(buf.decode_s16(j))))
						j += 2
					peak /= 32768.0
				24:
					while j + 2 < end:
						var v := buf[j] | (buf[j + 1] << 8) | (buf[j + 2] << 16)
						if v & 0x800000:
							v -= 0x1000000
						peak = maxf(peak, absf(float(v)))
						j += 3
					peak /= 8388608.0
				8:
					while j < end:
						peak = maxf(peak, absf(float(buf[j]) - 128.0))
						j += 1
					peak /= 128.0
				_:
					return NAN
			return db(peak)
		i += 8 + size + (size & 1)
	return NAN


## Source-file facts that the decoded frames can't tell: format, rate, channels, bits, disk size, import options.
static func file_info(path: String, stream: AudioStream) -> Dictionary:
	var info := {"path": path, "ext": path.get_extension().to_lower(), "disk_bytes": 0, "src_rate": 0,
		"src_channels": 0, "src_bits": 0, "import": {}, "class": stream.get_class() if stream else "",
		"imported_format": ""}
	var f := FileAccess.open(path, FileAccess.READ)
	if f:
		info["disk_bytes"] = f.get_length()
		if info["ext"] == "wav":
			var hdr := f.get_buffer(mini(4096, f.get_length()))
			var i := 12
			while i + 8 <= hdr.size():
				var id := hdr.slice(i, i + 4).get_string_from_ascii()
				var size := hdr.decode_u32(i + 4)
				if id == "fmt ":
					info["src_channels"] = hdr.decode_u16(i + 10)
					info["src_rate"] = hdr.decode_u32(i + 12)
					info["src_bits"] = hdr.decode_u16(i + 22)
					break
				i += 8 + size + (size & 1)
		f.close()
	if stream is AudioStreamWAV:
		var w := stream as AudioStreamWAV
		info["imported_format"] = ["PCM8", "PCM16", "IMA-ADPCM", "QOA"][clampi(w.format, 0, 3)]
		info["imported_rate"] = w.mix_rate
		info["imported_stereo"] = w.stereo
		info["loop"] = w.loop_mode != AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamOggVorbis:
		info["imported_format"] = "Ogg Vorbis"
		info["loop"] = (stream as AudioStreamOggVorbis).loop
	elif stream is AudioStreamMP3:
		info["imported_format"] = "MP3"
		info["loop"] = (stream as AudioStreamMP3).loop
	var imp := path + ".import"
	if FileAccess.file_exists(imp):
		var cfg := ConfigFile.new()
		if cfg.load(imp) == OK and cfg.has_section("params"):
			for k in cfg.get_section_keys("params"):
				info["import"][k] = cfg.get_value("params", k)
	return info


## Rough memory once loaded (bytes): imported PCM / ADPCM / QOA size, or the Ogg / MP3 file size (streamed from RAM).
static func memory_bytes(info: Dictionary, duration_s: float) -> int:
	var fmt := str(info.get("imported_format", ""))
	var rate := float(info.get("imported_rate", info.get("src_rate", 44100)))
	var ch := 2 if bool(info.get("imported_stereo", int(info.get("src_channels", 1)) == 2)) else 1
	var samples := duration_s * rate * ch
	match fmt:
		"PCM8":
			return int(samples)
		"PCM16":
			return int(samples * 2.0)
		"IMA-ADPCM":
			return int(samples * 0.5)
		"QOA":
			return int(samples * 0.4)   # 3.2 bits per sample
	return int(info.get("disk_bytes", 0))

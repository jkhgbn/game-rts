extends RefCounted
## Music Forge room (music.md 3): Freeverb-style mono reverb, 8 damped combs in parallel then 4 all-passes in series,
## pre-delay. Runs comb by comb (one tight loop each) because GDScript is slow per call. The caller gives a buffer
## with room for the tail (the forge renders on a linear timeline and folds the loop afterwards).

const COMBS := [558, 594, 638, 678, 711, 745, 778, 808]
const ALLPASSES := [278, 220, 170, 112]
const RATE := 22050


## Returns the wet signal of `input` (same length), scaled so its RMS sits `wet_db` under the input's RMS.
## `rate` = the buffer's sample rate (only the pre-delay depends on it; the comb sizes are Freeverb's own, native at
## 44.1 kHz). `spread` adds samples to every delay: Freeverb's right channel uses 23.
static func process(input: PackedFloat32Array, room: float, damp: float, predelay_s: float, wet_db: float,
		rate: int = RATE, spread: int = 0) -> PackedFloat32Array:
	var n := input.size()
	var pre := int(predelay_s * rate)
	var feedback := room * 0.28 + 0.7
	var acc := PackedFloat32Array()
	acc.resize(n)
	for c in COMBS:
		var d: int = c + spread
		var line := PackedFloat32Array()
		line.resize(d)
		var idx := 0
		var store := 0.0
		for i in range(pre, n):
			var o := line[idx]
			store = o * (1.0 - damp) + store * damp
			line[idx] = input[i - pre] * 0.015 + store * feedback
			idx += 1
			if idx >= d:
				idx = 0
			acc[i] += o
	for a in ALLPASSES:
		var d2: int = a + spread
		var line2 := PackedFloat32Array()
		line2.resize(d2)
		var j := 0
		for i in n:
			var bo := line2[j]
			var x := acc[i]
			acc[i] = bo - x
			line2[j] = x + bo * 0.5
			j += 1
			if j >= d2:
				j = 0
	var si := 0.0
	var so := 0.0
	for i in n:
		si += input[i] * input[i]
		so += acc[i] * acc[i]
	if so <= 0.0:
		return acc
	var g := sqrt(si / so) * pow(10.0, wet_db / 20.0)
	for i in n:
		acc[i] *= g
	return acc

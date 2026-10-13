extends RefCounted
## Music Forge humanisation (music.md 3): onset jitter, velocity by beat weight and phrase curve, per-note detune.
## Every random draw comes from the caller's seeded RandomNumberGenerator (same score = same bytes).

const JITTER_SIGMA := 0.006
const JITTER_CLAMP := 0.015
const DRUM_DOWNBEAT_CLAMP := 0.003
const PHRASE_CURVE := [0.9, 0.95, 1.0, 0.9]   # rise to bar 3 of each 4-bar phrase, ease on the last bar


## Onset offset in seconds. Drums on a downbeat stay within +-3 ms.
static func jitter(rng: RandomNumberGenerator, drum: bool, downbeat: bool) -> float:
	var j := rng.randfn(0.0, JITTER_SIGMA * (0.6 if drum else 1.0))
	var c := DRUM_DOWNBEAT_CLAMP if drum and downbeat else JITTER_CLAMP
	return clampf(j, -c, c)


## Beat weight of an onset `beat_in_bar` (beats from the bar start). 4/4: 1 / .75 / .9 / .75; 3/4: 1 / .75 / .8;
## 6/8 (2 dotted beats, eighths counted as beats here): 1 .7 .72 .9 .7 .72; off-beats .7, smaller .62.
static func beat_weight(beat_in_bar: float, meter: Vector2i) -> float:
	var b := int(floor(beat_in_bar + 0.001))
	var on_beat := absf(beat_in_bar - round(beat_in_bar)) < 0.01
	if not on_beat:
		var half := absf(beat_in_bar - floor(beat_in_bar) - 0.5) < 0.01
		return 0.72 if half else 0.64
	if meter.y == 8:
		return [1.0, 0.7, 0.72, 0.9, 0.7, 0.72][b % 6]
	if meter.x == 3:
		return [1.0, 0.75, 0.8][b % 3]
	if meter.x == 5:
		return [1.0, 0.75, 0.8, 0.92, 0.75][b % 5]
	return [1.0, 0.75, 0.9, 0.75][b % 4]


static func phrase_curve(bar: int) -> float:
	return PHRASE_CURVE[posmod(bar, 4)]


## Velocity = base x beat weight x phrase curve x (1 +-0.06). `weight_amount` 1 = the full beat weight, smaller for
## parts that should stay even (drum patterns carry their own accents).
static func velocity(rng: RandomNumberGenerator, base: float, beat_in_bar: float, bar: int, meter: Vector2i,
		weight_amount: float = 1.0) -> float:
	var w := lerpf(1.0, beat_weight(beat_in_bar, meter), weight_amount)
	return base * w * phrase_curve(bar) * (1.0 + rng.randf_range(-0.06, 0.06))


## Never two consecutive identical velocities (rounded to 0.005).
static func no_repeat(v: float, previous: float) -> float:
	if absf(v - previous) < 0.005:
		return v * (0.985 if v > 0.5 else 1.015)
	return v


static func detune_ratio(rng: RandomNumberGenerator) -> float:
	return pow(2.0, rng.randf_range(-3.0, 3.0) / 1200.0)

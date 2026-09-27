extends RefCounted
## Perf Lab (docs/plan/perf-lab.md): small number helpers shared by the runner, the report and the test.
## Reached through preload (no class_name, so a stale class cache never breaks the lab):
##   const Stats := preload("res://tools/perf_lab/perf_stats.gd")


## Percentile (0-100) of `values` by linear interpolation between the two nearest ranks. Empty -> 0.
static func percentile(values: Array, p: float) -> float:
	if values.is_empty():
		return 0.0
	var s := values.duplicate()
	s.sort()
	if s.size() == 1:
		return float(s[0])
	var r := clampf(p, 0.0, 100.0) / 100.0 * float(s.size() - 1)
	var lo := int(floor(r))
	var hi := mini(lo + 1, s.size() - 1)
	return lerpf(float(s[lo]), float(s[hi]), r - float(lo))


static func median(values: Array) -> float:
	return percentile(values, 50.0)


static func mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var t := 0.0
	for v: Variant in values:
		t += float(v)
	return t / float(values.size())


static func max_of(values: Array) -> float:
	var m := 0.0
	var first := true
	for v: Variant in values:
		if first or float(v) > m:
			m = float(v)
			first = false
	return m


## Summary of frame times in ms: avg, p50, p95, p99, max, count, and the hitches over `hitch_ms`.
static func frame_summary(ms: Array, hitch_ms: float = 33.3) -> Dictionary:
	var hitches := 0
	for v: Variant in ms:
		if float(v) > hitch_ms:
			hitches += 1
	return {"avg": snappedf(mean(ms), 0.001), "p50": snappedf(percentile(ms, 50.0), 0.001),
		"p95": snappedf(percentile(ms, 95.0), 0.001), "p99": snappedf(percentile(ms, 99.0), 0.001),
		"max": snappedf(max_of(ms), 0.001), "frames": ms.size(), "hitches": hitches}


## Element-wise median of several run dictionaries: every numeric leaf present in at least one run becomes the median
## of the runs that have it; strings / bools / arrays come from the first run. Used to merge repeats.
static func median_merge(runs: Array) -> Dictionary:
	if runs.is_empty():
		return {}
	var out: Dictionary = (runs[0] as Dictionary).duplicate(true)
	_merge_into(out, runs)
	return out


static func _merge_into(out: Dictionary, runs: Array) -> void:
	for k: Variant in out.keys():
		var v: Variant = out[k]
		if v is Dictionary:
			var subs: Array = []
			for r: Variant in runs:
				if r is Dictionary and (r as Dictionary).has(k) and (r as Dictionary)[k] is Dictionary:
					subs.append((r as Dictionary)[k])
			_merge_into(v as Dictionary, subs)
		elif v is float or v is int:
			var nums: Array = []
			for r: Variant in runs:
				if r is Dictionary and (r as Dictionary).has(k):
					var x: Variant = (r as Dictionary)[k]
					if x is float or x is int:
						nums.append(float(x))
			if not nums.is_empty():
				var m := median(nums)
				out[k] = int(round(m)) if v is int else m


## Relative spread of a list (max - min) / median, used to tell a stable set of repeats from a noisy one.
static func spread(values: Array) -> float:
	if values.size() < 2:
		return 0.0
	var m := median(values)
	if m <= 0.0:
		return 0.0
	var lo := float(values[0])
	var hi := float(values[0])
	for v: Variant in values:
		lo = minf(lo, float(v))
		hi = maxf(hi, float(v))
	return (hi - lo) / m

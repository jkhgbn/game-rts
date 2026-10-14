extends SceneTree
## MU11 (docs/design/music.md 6): the audio check on every shipped music file in assets/audio/music/.
## Phase 2 format (JS 2026-10-14, docs/plan/decisions.md): 16-bit STEREO 22 050 Hz WAV rendered by the sampler backend.
## Per file prints `id length_s samples peak_db rms_db lufs seam slope pad_share` and checks:
## - format (22 050 Hz, 2 channels, 16 bit) and the exact length from the track list of music.md 2 (bars x beats x 60 /
##   bpm; 6/8 bpm = the dotted quarter; stings 8 s), the score agreeing with that table;
## - music.md 5 limits: peak <= -1 dBFS on both channels, integrated loudness -12 +-1.5 LUFS (drives -16 +-2), loop seams
##   |last - first| and the slope change <= 0.02 on both channels, stings fading to < -60 dBFS;
## - pad share <= 20 % (render report), the render up to date with its score (hash), no choir part in any shipped score
##   (no singing, JS 2026-10-14), rule 1.4 (no two tracks share lead + mode + tempo +-8 bpm + meter);
## - total size within the stereo budget (about 160 MB, cap TOTAL_MB_CAP).
## Run: & tools\godot_run.ps1 --headless --path . -s tests/test_music_check.gd --quit-after 400000
## Prints `MUSIC CHECK OK` (and PASS music_check) or the failures.

const TASK_ID := "music_check"
const Core := preload("res://tools/music_forge/forge_core.gd")
const Dsp := preload("res://tools/music_forge/dsp.gd")
const Forge := preload("res://tools/music_forge/music_forge.gd")
const RATE := 22050
const TOTAL_MB_CAP := 165.0
## music.md 2 track list: id -> [bpm, beats per bar, beat unit, bars] (stings: [0, 0, 0, seconds]).
const SPEC := {
	"theme_main": [84, 4, 4, 52], "campaign_map": [64, 4, 4, 32],
	"fire": [96, 4, 4, 64], "fire_drive": [96, 4, 4, 16],
	"ice": [72, 3, 4, 64], "ice_drive": [72, 3, 4, 16],
	"nature": [64, 6, 8, 80], "nature_drive": [64, 6, 8, 16],
	"shadow": [60, 4, 4, 40], "shadow_drive": [60, 4, 4, 8],
	"field": [100, 4, 4, 64], "field_drive": [100, 4, 4, 16],
	"wave_strike": [128, 4, 4, 64], "wave_strike_drive": [128, 4, 4, 16],
	"boss": [112, 5, 4, 56], "boss_drive": [112, 5, 4, 8],
	"tavern": [72, 6, 8, 54], "chant": [60, 4, 4, 24],
	"sting_victory": [0, 0, 0, 8], "sting_defeat": [0, 0, 0, 8],
}

var _fails: PackedStringArray = []


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	var tuples := {}
	var total_bytes := 0
	if Forge.GAME_TRACKS.size() != SPEC.size():
		_fails.append("forge GAME_TRACKS (%d) and the music.md track list (%d) differ" % [Forge.GAME_TRACKS.size(), SPEC.size()])
	print("id                 length_s   samples  peak_db  rms_db    lufs    seam   slope  pad_share")
	for id in SPEC:
		total_bytes += _check_track(str(id), tuples)
	if FileAccess.file_exists(Forge.game_path("choir_test")):
		_fails.append("choir_test must stay out of assets/audio/music (no singing)")
	var mb := float(total_bytes) / 1048576.0
	print("total %.1f MB for %d files (cap %.0f MB)" % [mb, SPEC.size(), TOTAL_MB_CAP])
	if mb > TOTAL_MB_CAP:
		_fails.append("total %.1f MB > %.0f MB" % [mb, TOTAL_MB_CAP])
	print("checked in %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	if _fails.is_empty():
		print("MUSIC CHECK OK")
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  " + f)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _fails.size()])
	quit.call_deferred(0 if _fails.is_empty() else 1)


## Expected sample count from the music.md 2 table alone (not from the score).
static func expected_samples(spec: Array) -> int:
	if int(spec[0]) == 0:
		return int(round(float(spec[3]) * RATE))
	var beat_s := 60.0 / float(spec[0])
	var beats_per_bar := float(spec[1]) if int(spec[2]) == 4 else float(spec[1]) / 3.0   # 6/8: 2 dotted beats
	return int(round(float(spec[3]) * beats_per_bar * beat_s * RATE))


## Returns the file size in bytes (0 when missing).
func _check_track(id: String, tuples: Dictionary) -> int:
	var spec: Array = SPEC[id]
	var score := Core.load_score("res://tools/music_forge/scores/%s.json" % id)
	if score.is_empty():
		_fails.append("%s: no score" % id)
		return 0
	var path := Forge.game_path(id)
	var w := Dsp.read_wav(path)
	if w.is_empty():
		_fails.append("%s: cannot read %s" % [id, path])
		return 0
	var l: PackedFloat32Array = w["samples"]
	var r: PackedFloat32Array = w["right"]
	if int(w["rate"]) != RATE or int(w["channels"]) != 2 or int(w["bits"]) != 16 or r.size() != l.size():
		_fails.append("%s: format %s Hz %s ch %s bit (needs 22050 Hz stereo 16 bit)" % [id, w["rate"], w["channels"], w["bits"]])
		return FileAccess.get_file_as_bytes(path).size()
	var drive := score.has("drive_of")
	var loop := bool(score.get("loop", true))
	var m := Core.meter_of(score)
	if int(spec[0]) > 0 and (float(score.get("bpm", 0)) != float(spec[0]) or m.x != int(spec[1]) or m.y != int(spec[2])
			or int(score.get("bars", 0)) != int(spec[3])):
		_fails.append("%s: score %s bpm %d/%d %d bars, music.md says %s bpm %d/%d %d bars" % [id, score.get("bpm"), m.x, m.y,
			int(score.get("bars", 0)), spec[0], spec[1], spec[2], spec[3]])
	if int(spec[0]) == 0 and loop:
		_fails.append("%s: a sting must not loop" % id)
	var expect := expected_samples(spec)
	if not Core.length_exact(score, RATE):
		_fails.append("%s: bars x beats x 60 / bpm is not a whole number of samples" % id)
	if l.size() != expect or Core.length_samples(score, RATE) != expect:
		_fails.append("%s: %d samples (score %d), expected %d from music.md 2" % [id, l.size(), Core.length_samples(score, RATE), expect])
	var peak := maxf(Dsp.peak_db(l), Dsp.peak_db(r))
	var rms := Dsp.lin2db(sqrt((pow(Dsp.db2lin(Dsp.rms_db(l)), 2.0) + pow(Dsp.db2lin(Dsp.rms_db(r)), 2.0)) * 0.5))
	var lufs := Dsp.lufs_ch([l, r], RATE)
	var seam := Vector2.ZERO
	if loop:
		var s1 := Dsp.seam(l)
		var s2 := Dsp.seam(r)
		seam = Vector2(maxf(s1.x, s2.x), maxf(s1.y, s2.y))
	var end_db := -200.0
	for i in range(l.size() - int(0.005 * RATE), l.size()):
		end_db = maxf(end_db, Dsp.lin2db(maxf(absf(l[i]), absf(r[i]))))
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tools/music_forge/renders/%s.json" % id))
	var pad := 1.0
	var fresh := false
	if meta is Dictionary:
		pad = float((meta as Dictionary).get("pad_share", 1.0))
		fresh = str((meta as Dictionary).get("hash", "")) == Forge.game_hash(score)
	print("%-18s %8.2f %9d %8.2f %7.2f %7.2f %7s %7s %9.1f%%" % [id, float(l.size()) / RATE, l.size(), peak, rms, lufs,
		("%.4f" % seam.x) if loop else "-", ("%.4f" % seam.y) if loop else ("end %.0f" % end_db), pad * 100.0])
	if peak > -1.0:
		_fails.append("%s: peak %.2f dBFS > -1" % [id, peak])
	var target := -16.0 if drive else -12.0
	var tol := 2.0 if drive else 1.5
	if absf(lufs - target) > tol:
		_fails.append("%s: loudness %.2f LUFS outside %.0f +-%.1f" % [id, lufs, target, tol])
	var rms_lo := -26.0 if drive else -22.0
	var rms_hi := -10.0 if drive else -8.0
	if rms < rms_lo or rms > rms_hi:
		_fails.append("%s: RMS %.2f dB outside [%.0f, %.0f]" % [id, rms, rms_lo, rms_hi])
	if loop and (seam.x > 0.02 or seam.y > 0.02):
		_fails.append("%s: loop seam step %.4f slope %.4f (max 0.02)" % [id, seam.x, seam.y])
	if not loop and end_db > -60.0:
		_fails.append("%s: end at %.1f dBFS (needs < -60)" % [id, end_db])
	if pad > 0.2:
		_fails.append("%s: pad share %.1f %% > 20 %%" % [id, pad * 100.0])
	if not fresh:
		_fails.append("%s: render is older than its score (hash differs): re-run the forge" % id)
	if Core.has_choir(score):   # every shipped id: no choir part (no singing, JS 2026-10-14)
		_fails.append("%s: the score has a choir part (no singing in shipped tracks)" % id)
	if not drive:
		var key := "%s|%s|%d/%d" % [score.get("lead", ""), score.get("mode", ""), m.x, m.y]
		for other in tuples.get(key, []):
			if absf(float(other) - float(score.get("bpm", 0))) <= 8.0:
				_fails.append("%s: shares lead / mode / meter / tempo +-8 with another track (rule 1.4)" % id)
		var lst: Array = tuples.get(key, [])
		lst.append(float(score.get("bpm", 0)))
		tuples[key] = lst
	return 44 + l.size() * 4

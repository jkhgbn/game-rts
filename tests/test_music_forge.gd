extends SceneTree
## Music Forge phase 1 audio check (docs/design/music.md 5 + MU1 / MU11 subset) on the rendered tracks:
## format (16-bit mono 22 050 Hz), exact length from the score (bars x beats x 60 / bpm), peak <= -1 dBFS,
## integrated loudness (music -12 +-1.5 LUFS, drives -16 +-2), RMS range, loop seam click-free (|last - first| and the
## slope change <= 0.02), stings fade to < -60 dBFS, pad share <= 20 %, the render is up to date with its score,
## rule 1.4 (no two tracks share lead + mode + tempo +-8 + meter), the listening excerpts exist, and a re-render of
## sting_victory gives the same bytes as the file (deterministic).
## Run: & tools\godot_run.ps1 --headless --path . -s tests/test_music_forge.gd --quit-after 100000
## Render first: & tools\godot_run.ps1 --headless --path . -s tools/music_forge/music_forge.gd --quit-after 2000000 -- track=all excerpts

const TASK_ID := "music_forge"
const Core := preload("res://tools/music_forge/forge_core.gd")
const Dsp := preload("res://tools/music_forge/dsp.gd")
const Forge := preload("res://tools/music_forge/music_forge.gd")
const TRACKS := ["theme_main", "fire", "fire_drive", "sting_victory", "choir_test"]
const LISTEN := ["01_theme_main", "02_fire", "03_fire_drive", "04_sting_victory", "05_choir_test"]

var _fails: PackedStringArray = []


func _initialize() -> void:
	var tuples := {}
	for id in TRACKS:
		_check_track(id, tuples)
	_check_determinism()
	for nm in LISTEN:
		if not FileAccess.file_exists("res://docs/audio/listening_2026-10-13/%s.wav" % nm):
			_fails.append("missing listening excerpt %s.wav" % nm)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  " + f)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _fails.size()])
	quit.call_deferred(0 if _fails.is_empty() else 1)


func _check_track(id: String, tuples: Dictionary) -> void:
	var score := Core.load_score("res://tools/music_forge/scores/%s.json" % id)
	if score.is_empty():
		_fails.append("%s: no score" % id)
		return
	var path := Forge.out_path(score)
	var w := Dsp.read_wav(path)
	if w.is_empty():
		_fails.append("%s: cannot read %s" % [id, path])
		return
	var buf: PackedFloat32Array = w["samples"]
	var drive := score.has("drive_of")
	var loop := bool(score.get("loop", true))
	var expect := Core.length_samples(score)
	var peak := Dsp.peak_db(buf)
	var rms := Dsp.rms_db(buf)
	var lufs := Dsp.lufs(buf)
	var seam := Dsp.seam(buf) if loop else Vector2.ZERO
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tools/music_forge/renders/%s.json" % id))
	var pad := 1.0
	var fresh := false
	if meta is Dictionary:
		pad = float((meta as Dictionary).get("pad_share", 1.0))
		fresh = str((meta as Dictionary).get("hash", "")) == str(score["_hash"])
	var end_db := -200.0
	for i in range(buf.size() - int(0.005 * Dsp.RATE), buf.size()):
		end_db = maxf(end_db, Dsp.lin2db(absf(buf[i])))
	print("%-14s length %.2f s  %d samples  peak %.2f dB  rms %.2f dB  %.2f LUFS  %s  pad %.1f %%" % [id,
		float(buf.size()) / Dsp.RATE, buf.size(), peak, rms, lufs,
		("seam %.4f slope %.4f" % [seam.x, seam.y]) if loop else ("end %.1f dBFS" % end_db), pad * 100.0])
	if int(w["rate"]) != 22050 or int(w["channels"]) != 1 or int(w["bits"]) != 16:
		_fails.append("%s: format %s Hz %s ch %s bit" % [id, w["rate"], w["channels"], w["bits"]])
	if not Core.length_exact(score):
		_fails.append("%s: bars x beats x 60 / bpm is not a whole number of samples" % id)
	if buf.size() != expect:
		_fails.append("%s: %d samples, expected %d" % [id, buf.size(), expect])
	if peak > -1.0:
		_fails.append("%s: peak %.2f dBFS > -1" % [id, peak])
	var target := -16.0 if drive else -12.0
	var tol := 2.0 if drive else 1.5
	if absf(lufs - target) > tol:
		_fails.append("%s: loudness %.2f LUFS outside %.0f +-%.1f" % [id, lufs, target, tol])
	var rms_lo := -24.0 if drive else -20.0
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
	if drive or str(score.get("out", "")) != "":
		return
	var m := Core.meter_of(score)
	var key := "%s|%s|%d/%d" % [score.get("lead", ""), score.get("mode", ""), m.x, m.y]
	for other in tuples.get(key, []):
		if absf(float(other) - float(score.get("bpm", 0))) <= 8.0:
			_fails.append("%s: shares lead / mode / meter / tempo +-8 with another track (rule 1.4)" % id)
	var lst: Array = tuples.get(key, [])
	lst.append(float(score.get("bpm", 0)))
	tuples[key] = lst


func _check_determinism() -> void:
	var score := Core.load_score("res://tools/music_forge/scores/sting_victory.json")
	var a: PackedFloat32Array = Core.new().render(score, false)["samples"]
	var b: PackedFloat32Array = Core.new().render(score, false)["samples"]
	var ha := _hash16(a)
	var hb := _hash16(b)
	var file := Dsp.read_wav(Forge.out_path(score))
	var hf := _hash16(file.get("samples", PackedFloat32Array()), 32768.0)
	print("determinism: render 1 %s  render 2 %s  file %s" % [ha.substr(0, 12), hb.substr(0, 12), hf.substr(0, 12)])
	if ha != hb:
		_fails.append("sting_victory: two renders differ")
	if ha != hf:
		_fails.append("sting_victory: render differs from the file on disk")


## Hash of the 16-bit samples as the WAV writer stores them.
static func _hash16(buf: PackedFloat32Array, scale: float = 32767.0) -> String:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(round(clampf(buf[i], -1.0, 1.0) * scale)))
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(bytes)
	return ctx.finish().hex_encode()

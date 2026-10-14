extends SceneTree
## Music Forge checks (docs/design/music.md 5, MU1 + phase 2). The per-file audio checks of the shipped tracks live in
## tests/test_music_check.gd (MU11); this test checks the forge itself:
## - determinism: the same score renders to the same bytes twice, and equal to the shipped file (sting_victory, game
##   format = sampler backend, stereo 22 050 Hz); without the sample library: the synth kit twice (SKIP for the file);
## - the sampler key map from the VSCO 2 CE file names (VSCO "A3" sounds A4; harp names are scientific) and every set
##   (incl. phase 2: cello pizzicato, tuba staccato, marching snare) has zones;
## - no shipped score holds a choir part (no singing, JS 2026-10-14); choir_test stays a listening-only score;
## - the listening sheet index.md (committed) lists every excerpt: phase 1 01-04 and phase 2 06-21 (the excerpt WAVs
##   themselves are not committed, so they are not needed here);
## - the game backend refuses a score with a choir part (renders nothing). Samples missing (FW_MUSIC_SAMPLES unset) = SKIP.
## Run: & tools\godot_run.ps1 --headless --path . -s tests/test_music_forge.gd --quit-after 100000

const TASK_ID := "music_forge"
const Core := preload("res://tools/music_forge/forge_core.gd")
const Dsp := preload("res://tools/music_forge/dsp.gd")
const Forge := preload("res://tools/music_forge/music_forge.gd")
const Sampler := preload("res://tools/music_forge/sampler.gd")
const LISTEN_PHASE1 := ["01_theme_main", "02_fire", "03_fire_drive", "04_sting_victory"]

var _fails: PackedStringArray = []


func _initialize() -> void:
	_check_scores()
	var root_dir := Sampler.sample_root()
	if Sampler.available(root_dir):
		var smp := Sampler.new()
		smp.setup(root_dir)
		_check_key_map(smp)
		_check_determinism_game(smp)
		_check_choir_refused(smp)
	else:
		print("SKIP sampler checks: no sample library at %s (set FW_MUSIC_SAMPLES)" % root_dir)
		_check_determinism_synth()
	_check_listening()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  " + f)
		print("FAIL %s: %d problem(s)" % [TASK_ID, _fails.size()])
	quit.call_deferred(0 if _fails.is_empty() else 1)


func _check_scores() -> void:
	for id in Forge.GAME_TRACKS:
		var score := Core.load_score("res://tools/music_forge/scores/%s.json" % id)
		if score.is_empty():
			_fails.append("%s: no score" % id)
			continue
		if str(score.get("out", "")) != "":
			_fails.append("%s: a game track must not have out = %s" % [id, score.get("out")])
		for p in score.get("parts", []):
			if str((p as Dictionary).get("inst", "")) == "choir":
				_fails.append("%s: choir part %s" % [id, (p as Dictionary).get("name", "?")])
	var ct := Core.load_score("res://tools/music_forge/scores/choir_test.json")
	if not ct.is_empty() and str(ct.get("out", "")) != "listen":
		_fails.append("choir_test must stay a listening-only score (out = listen)")


func _check_key_map(smp: Sampler) -> void:
	for sid in Sampler.SETS:
		if (smp.zones.get(sid, []) as Array).is_empty():
			_fails.append("sampler: set %s has no zones" % sid)
	var roots := {}
	for z in smp.zones.get("vln_sus", []):
		roots[float(z["root"])] = true
	if not roots.has(69.0):
		_fails.append("sampler: violin key map lost A4 (VlnEns_susVib_A3 = 440 Hz)")
	var harp := {}
	for z in smp.zones.get("harp", []):
		harp[float(z["root"])] = true
	if not harp.has(69.0):
		_fails.append("sampler: harp key map lost A4 (KSHarp_A4)")
	if Sampler.set_for("cellos", 0.5, 1.0, {"pizz": true}, 48.0) != "vc_pizz":
		_fails.append("sampler: pizz option does not pick the cello pizzicato set")
	if Sampler.set_for("snare", 0.1, 1.0, {"march": true}, 60.0) != "snare_march":
		_fails.append("sampler: march option does not pick the marching snare")


## Game format: two renders of sting_victory equal each other and the shipped file.
func _check_determinism_game(smp: Sampler) -> void:
	var score := Core.load_score("res://tools/music_forge/scores/sting_victory.json")
	var a: Dictionary = Core.new().render_b(score, smp, false, Core.RATE_GAME)
	var b: Dictionary = Core.new().render_b(score, smp, false, Core.RATE_GAME)
	var ha := _hash16(a["left"], a["right"])
	var hb := _hash16(b["left"], b["right"])
	var file := Dsp.read_wav(Forge.game_path("sting_victory"))
	var hf := _hash16(file.get("samples", PackedFloat32Array()), file.get("right", PackedFloat32Array()), 32768.0)
	print("determinism (game format): render 1 %s  render 2 %s  file %s" % [ha.substr(0, 12), hb.substr(0, 12), hf.substr(0, 12)])
	if ha != hb:
		_fails.append("sting_victory: two renders differ")
	if ha != hf:
		_fails.append("sting_victory: render differs from assets/audio/music/sting_victory.wav")


## The game format must refuse a choir score (choir_test) and render nothing.
func _check_choir_refused(smp: Sampler) -> void:
	var score := Core.load_score("res://tools/music_forge/scores/choir_test.json")
	if score.is_empty():
		return
	var res: Dictionary = Core.new().render_b(score, smp, false, Core.RATE_GAME)
	if not res.has("error") or res.has("left"):
		_fails.append("game backend rendered choir_test (a choir score must be refused)")


func _check_determinism_synth() -> void:
	var score := Core.load_score("res://tools/music_forge/scores/sting_victory.json")
	var a: PackedFloat32Array = Core.new().render(score, false)["samples"]
	var b: PackedFloat32Array = Core.new().render(score, false)["samples"]
	if _hash16(a, PackedFloat32Array()) != _hash16(b, PackedFloat32Array()):
		_fails.append("sting_victory (synth): two renders differ")


func _check_listening() -> void:
	var idx := FileAccess.get_file_as_string(Forge.LISTEN_DIR + "index.md")
	if not idx.contains(Forge.PHASE2_MARK) or not idx.contains("# Music Forge phase 1"):
		_fails.append("index.md: phase 1 sheet or the Phase 2 section is missing")
	for nm in LISTEN_PHASE1:
		if not idx.contains("`%s.wav`" % nm):
			_fails.append("index.md does not list %s.wav" % nm)
	for k in Forge.PHASE2_LISTEN.size():
		var nm := "%02d_%s.wav" % [Forge.PHASE2_FIRST + k, Forge.PHASE2_LISTEN[k]]
		if not idx.contains("`%s`" % nm):
			_fails.append("index.md does not list %s" % nm)


## Hash of the 16-bit samples as the WAV writer stores them (interleaved when `r` is not empty).
static func _hash16(l: PackedFloat32Array, r: PackedFloat32Array, scale: float = 32767.0) -> String:
	var ch := 1 if r.is_empty() else 2
	var bytes := PackedByteArray()
	bytes.resize(l.size() * 2 * ch)
	for i in l.size():
		bytes.encode_s16(i * 2 * ch, int(round(clampf(l[i], -1.0, 1.0) * scale)))
		if ch == 2:
			bytes.encode_s16(i * 4 + 2, int(round(clampf(r[i], -1.0, 1.0) * scale)))
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(bytes)
	return ctx.finish().hex_encode()

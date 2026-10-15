extends SceneTree
## G-F r2 ground fixes (docs/art/gf_r2_ground.md; review docs/art/gf_review2.md items 5, 14, 15).
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_gf_r2_ground.gd --fixed-fps 60 --quit-after 3000
## Checks:
##  - item 5: the Bramble Spire model draws the only spire pulse (draws_aura_pulse), every 6-8 s, rim-only texture
##    (centre alpha 0), peak alpha <= 0.3 and gone most of the period, colour capped (value pass); NatureVfx's fallback
##    pulse 6-8 s with no fill; titan_mark frost aura has no inner wash and 12 ticks; the rime mist is faint;
##  - item 14: ground.gdshader paints worn grass on road / lane crowns; butterflies (ambient + critters) ~60 %;
##  - item 15: MissionFlashRing is a rim-only additive ring with fog disabled that frees itself.

const TASK_ID := "gf_r2_ground"
const SPIRE := "res://art/buildings/nature_spire.tscn"

var _fails: Array[String] = []
var _frame := 0
var _spire: Node3D = null
var _flash: MeshInstance3D = null
var _max_a := 0.0
var _zero_frames := 0
var _samples := 0
var _holder: Node3D = null


func _initialize() -> void:
	_static_checks()
	_holder = Node3D.new()
	root.add_child(_holder)
	var ps := load(SPIRE) as PackedScene
	if ps == null:
		_fails.append("no spire scene")
		return
	_spire = ps.instantiate() as Node3D
	_holder.add_child(_spire)
	if _spire.has_method(&"set_construction_progress"):
		_spire.call(&"set_construction_progress", 1.0)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_flash = MissionFlashRing.play(_holder, Vector3(3, 0, 3), 2.5)
		if _flash == null:
			_fails.append("MissionFlashRing.play returned null")
		else:
			var m := _flash.material_override as StandardMaterial3D
			if m == null or not m.disable_fog or m.blend_mode != BaseMaterial3D.BLEND_MODE_ADD:
				_fails.append("flash ring: not additive with fog disabled")
			if _centre_alpha(m.albedo_texture if m else null) > 0.001:
				_fails.append("flash ring texture has a fill")
	if _spire and _frame > 10 and _frame <= 10 + 60 * 8:
		var mat: Variant = _spire.get(&"_ring_mat")
		if mat is StandardMaterial3D:
			var a := (mat as StandardMaterial3D).albedo_color.a
			_max_a = maxf(_max_a, a)
			_samples += 1
			if a <= 0.001:
				_zero_frames += 1
	if _frame == 2 + 90:
		if is_instance_valid(_flash):
			_fails.append("flash ring still alive 1.5 s later")
	if _frame >= 10 + 60 * 8 + 2:
		_finish()
		return true
	return false


func _finish() -> void:
	if _samples == 0:
		_fails.append("no spire ring material sampled")
	else:
		if _max_a > 0.31:
			_fails.append("spire ring peak alpha %.2f > 0.3" % _max_a)
		if _max_a < 0.05:
			_fails.append("spire ring never shows (peak %.3f)" % _max_a)
		if float(_zero_frames) / float(_samples) < 0.45:
			_fails.append("spire ring is on %.0f %% of the time (want a pulse, not continuous)"
					% (100.0 * (1.0 - float(_zero_frames) / float(_samples))))
	if _fails.is_empty():
		print("  spire ring peak alpha %.2f, off %.0f %% of 8 s" % [_max_a, 100.0 * float(_zero_frames) / float(_samples)])
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])


func _static_checks() -> void:
	# Spire.
	var sp := load("res://art/buildings/nature_spire.gd") as GDScript
	var c := sp.get_script_constant_map()
	var period := float(c.get("AURA_PERIOD", 0.0))
	if period < 6.0 or period > 8.0:
		_fails.append("spire AURA_PERIOD %.1f not 6-8 s" % period)
	if _centre_alpha(NatureSpireModel.rim_texture()) > 0.001:
		_fails.append("spire rim texture has a fill")
	for g: Color in [Color(0.75, 1.0, 0.4), Color(1.0, 0.3, 0.3), Color(0.9, 0.95, 1.0)]:
		var a := NatureSpireModel.aura_color(g)
		if a.s > 0.551 or a.v > 0.781:
			_fails.append("aura colour %s not capped (s %.2f v %.2f)" % [g, a.s, a.v])
	# NatureVfx fallback pulse.
	var nv := (load("res://art/vfx/nature_vfx.gd") as GDScript).get_script_constant_map()
	var sp_pulse := float(nv.get("SPIRE_PULSE", 0.0))
	if sp_pulse < 6.0 or sp_pulse > 8.0:
		_fails.append("NatureVfx SPIRE_PULSE %.1f not 6-8 s" % sp_pulse)
	if float(nv.get("SPIRE_RIM_A", 1.0)) > 0.5:
		_fails.append("NatureVfx spire rim alpha above 0.5")
	var nsrc := _src("res://art/vfx/nature_vfx.gd")
	if not nsrc.contains("SPIRE_RIM, 1.8, 0.03, 0.0, SPIRE_RIM_A"):
		_fails.append("NatureVfx spire pulse still has a fill")
	var spsrc := _src("res://art/buildings/nature_spire.gd")
	if not spsrc.contains("func draws_aura_pulse() -> bool:\n\treturn true"):
		_fails.append("spire model does not claim its aura pulse (two rings)")
	# Titan frost aura / grove pulse.
	var mark := _src("res://art/vfx/titan_mark.gdshader")
	var aura := mark.substr(mark.find("// ---- frost aura"), mark.find("// ---- grove pulse") - mark.find("// ---- frost aura"))
	if aura.contains("float wash") or not aura.contains("float nt = 12.0;"):
		_fails.append("frost aura still has a wash / dense teeth")
	var tg := _src("res://art/vfx/titan_ground_vfx.gd")
	if not tg.contains("Color(1, 1, 1, 0.12),"):
		_fails.append("rime mist alpha not lowered")
	# Item 14.
	var ground := _src("res://art/environment/ground.gdshader")
	if ground.count("worn_grass(") < 3:
		_fails.append("ground.gdshader: road / lane crowns do not use worn_grass")
	if ground.contains("grass * 0.95, 0.8)") or ground.contains("grass * 0.95, 0.75)"):
		_fails.append("ground.gdshader: a bright crown blob is left")
	var amb := _src("res://art/environment/ambient/ambient_life.gd")
	var wi := amb.find("&\"wings\":\n\t\t\tp.lifetime")
	var wblock := amb.substr(wi, 800) if wi >= 0 else ""
	var smax := _num_after(wblock, "pm.scale_max = ")
	if smax <= 0.0 or smax > 1.05:
		_fails.append("ambient butterfly scale_max %.2f (want <= 1.05)" % smax)
	var crit := _src("res://art/environment/critters/critter_system.gd")
	if not crit.contains("\"scale\": _rng.randf_range(0.72, 0.88),"):
		_fails.append("critter butterflies not scaled down")


func _src(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text().replace("\r\n", "\n") if f else ""


func _num_after(text: String, key: String) -> float:
	var i := text.find(key)
	if i < 0:
		return -1.0
	var rest := text.substr(i + key.length(), 12)
	return rest.split("\n")[0].to_float()


func _centre_alpha(tex: Texture2D) -> float:
	if tex == null:
		return 1.0
	var g := tex as GradientTexture2D
	if g and g.gradient:
		return g.gradient.sample(0.5).a   # half the radius: inside the ring
	return 1.0

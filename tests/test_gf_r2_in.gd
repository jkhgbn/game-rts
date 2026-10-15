extends SceneTree
## G-F round 2, Ice / Nature buildings (docs/art/gf_review2.md items 6 and 7, docs/art/gf_r2_buildings_in.md).
##  A  MoteCap: the mote quad is MIX (never additive) with a near-camera fade; cap() keeps a colour under VALUE_CAP;
##     ratio() follows the tier (Low 0, Medium 0.5, High / Ultra 1).
##  B  every ambient mote emitter of the Ice / Nature buildings (Ice keep SnowMotes + FrostSwirl, Frost Hall SnowMotes,
##     Frost Bazaar SnowMotes, Snow Lodge / Frost Forge Snowfall, Nature keep / hall / hollow Pollen, Fireflies) draws
##     alpha-blended with the near-camera fade (the MoteCap quad or the building's own faded soft dot), follows the tier (Low: hidden, amount_ratio 0; Medium: half) and its colour (ramp x
##     process colour) stays under the value cap; the Frost Hall motes start under the eaves (not above the roof).
##  C  Frost Hall roof: three tile shades of the team colour, all darker than the old single shade (x 0.65), crack
##     streaks at half strength, the shades follow set_team_color; in the merged Roof mesh snow covers a small share of
##     the up-facing area (it was a third of each slope plus drift "pillows").
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_gf_r2_in.gd --fixed-fps 60 --quit-after 3000 [-- --gfx=medium]

const TASK_ID := "gf_r2_in"
const SCENES := {
	"ice_keep": "res://art/buildings/ice_keep.tscn",
	"ice_hall": "res://art/buildings/ice_hall.tscn",
	"ice_lodge": "res://art/buildings/ice_lodge.tscn",
	"ice_market": "res://art/buildings/market/ice/market_ice.tscn",
	"ice_forge": "res://art/buildings/forge/ice/ice_forge.tscn",
	"nature_keep": "res://art/buildings/nature_keep.tscn",
	"nature_hall": "res://art/buildings/nature_hall.tscn",
	"nature_hollow": "res://art/buildings/nature_hollow.tscn",
}
## Emitters that must exist on every tier (Snowfall / Fireflies exist only at High / Ultra).
const ALWAYS := {
	"ice_keep": ["SnowMotes", "FrostSwirl"], "ice_hall": ["SnowMotes"], "ice_market": ["SnowMotes"],
	"nature_keep": ["Pollen"], "nature_hall": ["Pollen"], "nature_hollow": ["Pollen"],
}
const MOTE_NAMES := ["SnowMotes", "FrostSwirl", "Snowfall", "Pollen", "Fireflies"]

var _m := {}
var _frame := 0
var _fails: Array[String] = []


func _initialize() -> void:
	var x := 0.0
	for k: String in SCENES:
		var n := (load(SCENES[k]) as PackedScene).instantiate() as Node3D
		n.position = Vector3(x, 0, 0)
		x += 14.0
		root.add_child(n)
		_m[k] = n


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 4:
		_check_motecap()
		_check_emitters()
		_check_roof()
		if _fails.is_empty():
			print("PASS %s (tier %d)" % [TASK_ID, GameSettings.effective_graphics_quality()])
		else:
			for f: String in _fails:
				print("  ", f)
			print("FAIL %s: %s" % [TASK_ID, _fails[0]])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _expected_ratio() -> float:
	var q: int = GameSettings.effective_graphics_quality()
	return 0.0 if q <= 0 else (0.5 if q == 1 else 1.0)


# --- A
func _check_motecap() -> void:
	var q := MoteCap.quad(0.1)
	var m := q.material as StandardMaterial3D
	_check(m != null and MoteCap.is_mote_material(m), "MoteCap.quad has the mote material")
	if m:
		_check(m.blend_mode == BaseMaterial3D.BLEND_MODE_MIX, "mote material is MIX (never additive)")
		_check(m.distance_fade_mode == BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA, "mote material fades near the camera")
		_check(m.distance_fade_min_distance >= 3.0 and m.distance_fade_max_distance > m.distance_fade_min_distance,
			"near fade from >= 3 m (%.1f -> %.1f)" % [m.distance_fade_min_distance, m.distance_fade_max_distance])
		_check(m.albedo_color.r <= 1.0 and m.albedo_color.g <= 1.0 and m.albedo_color.b <= 1.0, "mote albedo not HDR")
	var c := MoteCap.cap(Color(0.95, 0.98, 1.0, 0.8))
	_check(maxf(c.r, maxf(c.g, c.b)) <= MoteCap.VALUE_CAP + 0.001 and is_equal_approx(c.a, 0.8), "cap() caps the value")
	_check(is_equal_approx(MoteCap.ratio(), _expected_ratio()), "ratio() follows the tier (%s)" % MoteCap.ratio())


# --- B
func _check_emitters() -> void:
	var want: float = _expected_ratio()
	var high: bool = GameSettings.effective_graphics_quality() >= 2
	for k: String in SCENES:
		var node: Node = _m[k]
		var found := {}
		for n: Node in node.find_children("*", "GPUParticles3D", true, false):
			var p := n as GPUParticles3D
			if not (String(p.name) in MOTE_NAMES):
				continue
			found[String(p.name)] = true
			var tag := "%s/%s" % [k, p.name]
			_check(MoteCap.is_mote_like(MoteCap.draw_material(p)), "%s draws MIX with the near-camera fade" % tag)
			_check(is_equal_approx(p.amount_ratio, want), "%s amount_ratio %s (want %s)" % [tag, p.amount_ratio, want])
			_check(p.visible == (want > 0.0), "%s visible = %s at this tier" % [tag, p.visible])
			var pm := p.process_material as ParticleProcessMaterial
			if pm and String(p.name) != "FrostSwirl":   # the swirl keeps its saturated blue ramp
				var v: float = _ramp_peak(pm)
				_check(v <= MoteCap.VALUE_CAP + 0.01, "%s colour value %.2f <= %.2f" % [tag, v, MoteCap.VALUE_CAP])
				# The world size lives in the quad (a billboard particle drops the process scale), the scale is relative.
				var qs: float = maxf(p.draw_pass_1.get_aabb().size.x, p.draw_pass_1.get_aabb().size.y)
				_check(qs <= 0.15, "%s quad %.3f m <= 0.15" % [tag, qs])
				_check(pm.scale_max <= 1.0 + 0.001, "%s process scale is relative (max %.2f)" % [tag, pm.scale_max])
		for nm: String in ALWAYS.get(k, []):
			_check(found.has(nm), "%s has %s" % [k, nm])
		if high and k in ["ice_lodge", "ice_forge"]:
			_check(found.has("Snowfall"), "%s has Snowfall at High" % k)
	var hall_motes := (_m["ice_hall"] as Node).find_child("SnowMotes", true, false) as GPUParticles3D
	if hall_motes:
		var top: float = hall_motes.global_position.y - (_m["ice_hall"] as Node3D).global_position.y
		_check(top < IceHallModel.R_EAVE, "Frost Hall motes start under the eaves (%.2f m)" % top)
	var keep_snow := (_m["ice_keep"] as Node).find_child("SnowMotes", true, false) as GPUParticles3D
	if keep_snow:
		_check(keep_snow.position.y <= 8.0, "Ice keep snow starts at <= 8 m (%.1f)" % keep_snow.position.y)
	# The Frost Hall's brazier flame: alpha-blended on a 0.3 m quad (it was additive on the 1 m hall quad: a white hex).
	var flame := (_m["ice_hall"] as Node).find_child("ColdFlame", true, false) as GPUParticles3D
	_check(flame != null, "Frost Hall has its ColdFlame")
	if flame:
		var fm := MoteCap.draw_material(flame) as BaseMaterial3D
		_check(fm != null and fm.blend_mode == BaseMaterial3D.BLEND_MODE_MIX, "ColdFlame is alpha-blended")
		_check(flame.draw_pass_1.get_aabb().size.x <= 0.35, "ColdFlame quad <= 0.35 m")


## The brightest colour channel a particle can show: ramp stops x the process colour (sRGB).
func _ramp_peak(pm: ParticleProcessMaterial) -> float:
	var tex := pm.color_ramp as GradientTexture1D
	var mult: Color = pm.color
	var peak: float = maxf(mult.r, maxf(mult.g, mult.b))
	if tex == null or tex.gradient == null:
		return peak
	var best: float = 0.0
	for c: Color in tex.gradient.colors:
		if c.a < 0.02:
			continue
		best = maxf(best, maxf(c.r * mult.r, maxf(c.g * mult.g, c.b * mult.b)))
	return best


# --- C
func _check_roof() -> void:
	var hall: Node = _m["ice_hall"]
	var mats: Array = hall.get(&"_roof_mats")
	_check(mats.size() == 3, "Frost Hall: 3 roof tile shades (%d)" % mats.size())
	var kc: Color = hall.get(&"kingdom_color")
	for i: int in mats.size():
		var k: float = IceHallModel.ROOF_MULTS[i]
		_check(k < 0.65, "roof shade %d darker than the old x0.65 (%.2f)" % [i, k])
	_check(IceHallModel.ROOF_CRACK <= 0.18, "roof crack streaks at half strength (%.2f)" % IceHallModel.ROOF_CRACK)
	hall.call(&"set_team_color", Color(0.85, 0.25, 0.25))
	for i: int in mats.size():
		var bc: Variant = (mats[i] as ShaderMaterial).get_shader_parameter(&"base_color")
		var want := Color(0.85 * IceHallModel.ROOF_MULTS[i], 0.25 * IceHallModel.ROOF_MULTS[i], 0.25 * IceHallModel.ROOF_MULTS[i])
		_check(bc is Color and (bc as Color).is_equal_approx(want), "roof shade %d follows the team colour (%s)" % [i, bc])
	hall.call(&"set_team_color", kc)
	var roof := hall.find_child("Roof", true, false) as MeshInstance3D
	_check(roof != null and roof.mesh != null, "Frost Hall has its Roof mesh")
	if roof == null or roof.mesh == null:
		return
	var up_area: float = 0.0
	var snow_area: float = 0.0
	var tiles: int = 0
	for s: int in roof.mesh.get_surface_count():
		var a: Array = roof.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var cols: Variant = a[Mesh.ARRAY_COLOR]
		var idx: Variant = a[Mesh.ARRAY_INDEX]
		if not (cols is PackedColorArray) or (cols as PackedColorArray).size() != v.size():
			continue
		var ia: PackedInt32Array = idx if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0 else PackedInt32Array(range(v.size()))
		for t: int in range(0, ia.size() - 2, 3):
			var p0: Vector3 = v[ia[t]]
			var cr: Vector3 = (v[ia[t + 1]] - p0).cross(v[ia[t + 2]] - p0)
			var area: float = cr.length() * 0.5
			if area < 0.0001 or cr.normalized().y < 0.35:
				continue
			up_area += area
			var c: Color = (cols as PackedColorArray)[ia[t]]
			if c.a < 0.5:
				tiles += 1
				continue
			var mx: float = maxf(c.r, maxf(c.g, c.b))
			var mn: float = minf(c.r, minf(c.g, c.b))
			if mx > 0.6 and (mx - mn) / maxf(mx, 0.001) < 0.27:
				snow_area += area
	_check(up_area > 0.0, "roof has up-facing area")
	if up_area > 0.0:
		var share: float = snow_area / up_area
		print("  roof: up-facing snow share %.2f, team (tile / crest) up-facing triangles %d" % [share, tiles])
		_check(share < 0.2, "roof snow share %.2f < 0.2" % share)
		_check(tiles >= 150, "roof is many tiles (%d up-facing team triangles)" % tiles)

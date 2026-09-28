extends Node3D
## Four corners, four moods: the Ep4 memory set has ONE LightingPreset, so this node re-tunes the LightingRig every frame
## from the viewport camera x (corners at x -30 / -10 / 10 / 30): winter overcast, golden spring, cold-amber hem
## pre-dawn, grey ash. Blends between neighbours with a plateau near each corner. Deterministic (a function of camera x).

const CORNER_X := [-30.0, -10.0, 10.0, 30.0]
## top, horizon, fog colour, fog density, ambient energy, exposure, saturation, contrast, sun colour, sun energy, sun rot, fill colour, fill energy
const MOODS := [
	{"top": Color(0.5, 0.58, 0.76), "hor": Color(0.88, 0.86, 0.9), "fog": Color(0.78, 0.82, 0.9), "fd": 0.018, "amb": 0.85, "exp": 1.0, "sat": 0.82, "con": 1.02,
		"sun": Color(0.86, 0.9, 1.0), "se": 0.6, "rot": Vector3(-13, -100, 0), "fill": Color(0.6, 0.7, 1.0), "fe": 0.4},
	{"top": Color(0.3, 0.55, 0.92), "hor": Color(1.0, 0.86, 0.55), "fog": Color(1.0, 0.88, 0.62), "fd": 0.008, "amb": 0.8, "exp": 1.05, "sat": 1.25, "con": 1.06,
		"sun": Color(1.0, 0.82, 0.5), "se": 1.8, "rot": Vector3(-14, 200, 0), "fill": Color(0.65, 0.78, 1.0), "fe": 0.3},
	{"top": Color(0.1, 0.14, 0.3), "hor": Color(0.62, 0.36, 0.28), "fog": Color(0.34, 0.27, 0.3), "fd": 0.015, "amb": 0.6, "exp": 1.0, "sat": 1.0, "con": 1.12,
		"sun": Color(0.95, 0.55, 0.33), "se": 0.55, "rot": Vector3(-7, -70, 0), "fill": Color(0.4, 0.55, 1.0), "fe": 0.55},
	{"top": Color(0.32, 0.34, 0.38), "hor": Color(0.5, 0.52, 0.56), "fog": Color(0.42, 0.44, 0.49), "fd": 0.03, "amb": 0.58, "exp": 0.9, "sat": 0.5, "con": 1.16,
		"sun": Color(0.8, 0.86, 0.97), "se": 0.5, "rot": Vector3(-33, 130, 0), "fill": Color(0.5, 0.56, 0.68), "fe": 0.3},
]

var _rig: LightingRig = null


func _find_rig(n: Node) -> LightingRig:
	if n is LightingRig:
		return n as LightingRig
	for c in n.get_children():
		var r := _find_rig(c)
		if r != null:
			return r
	return null


func _process(_dt: float) -> void:
	if _rig == null or not is_instance_valid(_rig):
		_rig = _find_rig(get_tree().root)
		if _rig == null or _rig.world_environment == null:
			_rig = null
			return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var x := cam.global_position.x
	var u := clampf((x - CORNER_X[0]) / 20.0, 0.0, 2.999)
	var i := int(floorf(u))
	var f := smoothstep(0.3, 0.7, u - float(i))
	var a: Dictionary = MOODS[i]
	var b: Dictionary = MOODS[i + 1]
	var env := _rig.world_environment.environment
	if env == null:
		return
	if env.sky != null and env.sky.sky_material is ProceduralSkyMaterial:
		var sm := env.sky.sky_material as ProceduralSkyMaterial
		sm.sky_top_color = (a["top"] as Color).lerp(b["top"] as Color, f)
		var hor := (a["hor"] as Color).lerp(b["hor"] as Color, f)
		sm.sky_horizon_color = hor
		sm.ground_horizon_color = hor.darkened(0.3)
		sm.ground_bottom_color = hor.darkened(0.6)
	env.fog_light_color = (a["fog"] as Color).lerp(b["fog"] as Color, f)
	env.fog_density = lerpf(a["fd"], b["fd"], f)
	env.ambient_light_energy = lerpf(a["amb"], b["amb"], f)
	env.tonemap_exposure = lerpf(a["exp"], b["exp"], f)
	env.adjustment_enabled = true
	env.adjustment_saturation = lerpf(a["sat"], b["sat"], f)
	env.adjustment_contrast = lerpf(a["con"], b["con"], f)
	_rig.sun.light_color = (a["sun"] as Color).lerp(b["sun"] as Color, f)
	_rig.sun.light_energy = lerpf(a["se"], b["se"], f)
	_rig.sun.rotation_degrees = (a["rot"] as Vector3).lerp(b["rot"] as Vector3, f)
	_rig.fill.light_color = (a["fill"] as Color).lerp(b["fill"] as Color, f)
	_rig.fill.light_energy = lerpf(a["fe"], b["fe"], f)

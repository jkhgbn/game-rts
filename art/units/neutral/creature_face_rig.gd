class_name CreatureFaceRig
extends FaceRig
## Eyes + a simple expression for beasts, mounts and creatures (faces pass 2026-09-28, champions / helpers / neutral):
## a FaceRig that works for any model (FlyerModel included: auto_any) and can draw INSIDE a merged pivot mesh instead
## of its own node ("host" mode): the face surface is appended to a copy of the host's merged mesh (one copy per
## expression, cached per type), so the model keeps its draw-instance count (mounts sit at the cavalry budget of 8,
## the Mirefang at 10). The face is still ONE extra surface (the shared unit_face material) = 1 draw call, like a FaceRig.
## The style is a normal FaceKit style (see beast_spec): the kit always paints a mouth, so beast_spec hides it where
## the muzzle covers it at a hair's width in the hide colour; the eyes and the brow ridges carry the expressions.
##
##   _face = CreatureFaceRig.attach(self, $Root/Mount/Head, "direwolf", CreatureFaceRig.beast_spec({...}))   # _build_parts
##   _face.set_host(_merged_nodes.get(P_MOUNT_HEAD))   # _after_ready (host mode; skip it to keep the own node)
##   _face.auto_any(self)                               # per frame (_extra_process / the flyer's tick)
## If something else swaps the host's mesh (mount barding), the next auto_any() notices and re-applies the face.

var _host: MeshInstance3D
var _host_off: Vector3 = Vector3.ZERO     # model space -> host pivot space
var _base: Mesh                           # the host's own mesh (last one we did not assign)
var _assigned: Mesh

static var _combo: Dictionary = {}
static var _styles: Dictionary = {}


## Adds the rig under `pivot` (model-space face mesh, like FaceKit.attach) with `spec` (a style_from spec or a style).
static func attach(model: Node3D, pivot: Node3D, key: String, spec: Dictionary) -> CreatureFaceRig:
	_style_of(key, spec)
	var rig := CreatureFaceRig.new()
	rig.name = "Face"
	var o := Vector3.ZERO
	var n: Node = pivot
	while n and n != model:
		o += (n as Node3D).position
		n = n.get_parent()
	rig.position = -o
	rig._host_off = -o
	rig.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rig.set_meta(&"keep_separate", true)
	pivot.add_child(rig)
	rig.setup(key, _styles[key])
	return rig


## Another style on the same rig (a variant: other eye colours), keeping the requested expression.
func switch(key: String, spec: Dictionary) -> void:
	var st := _style_of(key, spec)
	if key != _key:
		setup(key, st)
		if _host:
			for id: StringName in FaceKit.EXPRESSIONS:
				_combined(id)
			_combined(FaceKit.FAR)


## The style of `key` (built + warmed once per game from `spec`: a style_from spec, optionally with "lift", or a style).
static func _style_of(key: String, spec: Dictionary) -> Dictionary:
	if not _styles.has(key):
		var st: Dictionary = spec if spec.has("canvas") else FaceKit.style_from(spec)
		if spec.has("lift") and not spec.has("canvas"):
			# decals lifted off the canvas sphere (it only passes THROUGH the eyes; the real skull bulges around them)
			var r: float = spec["radius"]
			st["canvas"] = FaceKit.canvas(spec["center"], r, spec.get("head_mesh", CharacterModel.sphere(r, 12, 6)),
				spec.get("head_scale", Vector3.ONE), Vector3.INF, Basis.IDENTITY, float(spec["lift"]))
		_styles[key] = st
		FaceKit.warm(key, st)
	return _styles[key]


## Host mode: draw the face inside `host` (the merged MeshInstance3D of the pivot the rig was attached to).
func set_host(host: MeshInstance3D) -> void:
	if host == null or host.mesh == null:
		return
	_host = host
	_base = host.mesh
	mesh = null
	visible = false
	# every expression's combined mesh now (cached per type: later instances reuse them), none built in a fight
	for id: StringName in FaceKit.EXPRESSIONS:
		_combined(id)
	_combined(FaceKit.FAR)
	_shown = &""
	_show(_expr)


## A beast spec for FaceKit.style_from: eyes at `eye` (face 2D, +x side; side eyes: x = azimuth x radius), no blush, a
## hidden mouth at `mouth_at` (under the muzzle), the hide colour on lids / brows. Keys of `o` override / add (eye,
## brow, x, palette merged).
static func beast_spec(center: Vector3, radius: float, eye: Dictionary, hide: Color, iris: Color, glow: float,
		mouth_at: Vector2, o: Dictionary = {}) -> Dictionary:
	var pal := {"lip_line": hide.darkened(0.1), "lip": hide, "mouth_in": hide.darkened(0.2), "teeth": hide, "tongue": hide,
		"lash": hide.darkened(0.75), "brow": hide.darkened(0.5), "sclera": Color(0.16, 0.12, 0.10), "pupil": Color(0.03, 0.02, 0.02),
		"skin": hide, "blush": hide}
	if glow > 0.0:
		pal["sclera"] = FaceKit.glow(iris.lerp(Color(1, 1, 0.85), 0.35), glow * 0.55)
		pal["iris_in"] = FaceKit.glow(iris.lerp(Color(1, 1, 1), 0.45), glow)
		pal["iris_out"] = FaceKit.glow(iris, glow * 0.8)
		# FaceKit.eye() re-applies the glow from iris_glow (default 0): without it the irises came out painted (tests
		# 2026-09-28: the Tusker / Grizzlemaw / Moonpelt eyes had no glowing vertex; only a glowing sclera where kept).
		pal["iris_glow"] = glow
	var x := {}
	for id: StringName in FaceKit.EXPRESSIONS:
		x[id] = {"blush": 0.0, "lines": false}
	# animals rest with open eyes (no happy squint); the brows do the talking
	x[&"neutral"]["low"] = 0.12
	x[&"fierce"]["brow"] = [-0.024, -0.010, 0.012]
	x[&"worried"]["brow"] = [0.022, 0.010, -0.010]
	var spec := {"center": center, "radius": radius, "preset": &"plain", "detail": &"low", "skin": hide, "hair": hide,
		"eyes": iris, "ears": &"none", "eye": eye, "palette": pal, "x": x,
		"mouth": {"c": mouth_at, "hw": 0.004, "lip": 0.0005}}
	for k: String in o:
		if (k == "palette" or k == "eye" or k == "brow") and spec.has(k):
			var d: Dictionary = (spec[k] as Dictionary).duplicate()
			for kk: String in o[k]:
				d[kk] = o[k][kk]
			spec[k] = d
		elif k == "x":
			for id: StringName in o[k]:
				for kk: String in o[k][id]:
					x[id][kk] = o[k][id][kk]
		else:
			spec[k] = o[k]
	return spec


## FaceRig.auto for any model with the kit's state fields (CharacterModel, MountModel, FlyerModel): tier >= 1 = the
## bold far face; else dying = worried, level-up = smile, a cast = shout, an attack = fierce (`extra_mood` wins).
func auto_any(model: Node, extra_mood: StringName = &"") -> void:
	if _host and _host.mesh != _assigned:
		_shown = &""   # the host's mesh was swapped (barding): re-apply
	if int(_field(model, &"_tier", 0)) != 0:
		far()
		return
	var mood := extra_mood
	if mood == &"":
		var action := StringName(str(_field(model, &"_action", "")))
		var cast_id := str(_field(model, &"_cast_id", ""))
		if _field(model, &"_dead", false):
			mood = &"worried"
		elif float(_field(model, &"_level_t", 99.0)) < 1.6:
			mood = &"smile"
		elif action == &"cast" and not (cast_id.begins_with("_idle") or cast_id.begins_with("idle")):
			mood = &"shout"
		elif action == &"attack" or action == &"breath":
			mood = &"fierce"
	react(mood)


static func _field(model: Node, f: StringName, fallback: Variant) -> Variant:
	var v: Variant = model.get(f)
	return fallback if v == null else v


func _show(id: StringName) -> void:
	if _key == "":
		return
	if _host == null:
		super._show(id)
		return
	if id == _shown and _host.mesh == _assigned:
		return
	_shown = id
	if _host.mesh != _assigned and _host.mesh != null:
		_base = _host.mesh
	if _base == null:
		return
	var m := _combined(id)
	_assigned = m
	_host.mesh = m


## The host's current base mesh + the face of expression `id` (cached per base mesh, face key and expression).
func _combined(id: StringName) -> ArrayMesh:
	var ck := "%d|%s|%s" % [_base.get_instance_id(), _key, id]
	var m: ArrayMesh = _combo.get(ck)
	if m == null:
		m = _combine(_base, FaceKit.face_mesh(_key, _style, id), _host_off)
		_combo[ck] = m
	return m


## A copy of `base` (every surface + material) with the face surface appended (moved by `off`).
static func _combine(base: Mesh, face: ArrayMesh, off: Vector3) -> ArrayMesh:
	var m := ArrayMesh.new()
	var custom := 0   # keep the custom-channel formats (a shader reading CUSTOM0..3 would lose them otherwise)
	for i: int in 4:
		custom |= Mesh.ARRAY_FORMAT_CUSTOM_MASK << (Mesh.ARRAY_FORMAT_CUSTOM_BASE + i * Mesh.ARRAY_FORMAT_CUSTOM_BITS)
	for s: int in base.get_surface_count():
		var flags: int = (base as ArrayMesh).surface_get_format(s) & custom if base is ArrayMesh else 0
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, base.surface_get_arrays(s), [], {}, flags)
		m.surface_set_material(s, base.surface_get_material(s))
	for s: int in face.get_surface_count():
		var arr := face.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i: int in v.size():
			v[i] += off
		arr[Mesh.ARRAY_VERTEX] = v
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		m.surface_set_material(m.get_surface_count() - 1, face.surface_get_material(s))
	return m


## A beast spec for a pair of SIDE eyes (the head's midplane is x = 0): `eye` = the +x eye's centre on the head surface
## (model space), `out` = the way it looks (outward normal). The canvas is the sphere through both eyes centred on the
## midplane along `out`; the eye's face-2D centre, the brow ridge over it and the hidden mouth are placed from that.
## `size` = the eye's half width (m). `o` as beast_spec (eye / brow / palette / x merged).
static func side_eye_spec(eye: Vector3, out: Vector3, size: float, hide: Color, iris: Color, glow: float,
		o: Dictionary = {}) -> Dictionary:
	var d := out.normalized()
	var r := eye.x / maxf(d.x, 0.05)
	var c := eye - d * r
	c.x = 0.0
	var dd := (eye - c).normalized()
	var ec := Vector2(atan2(dd.x, dd.z) * r, asin(clampf(dd.y, -1.0, 1.0)) * r)
	var e := {"c": ec, "hw": size, "top": size * 0.72, "bot": size * 0.52, "tilt": 0.0, "ir": size * 0.55, "lash": 1.1,
		"flick": 0.0, "pupil": 0.55}
	var b := {"inner": ec + Vector2(-size * 0.95, size * 1.0), "mid": ec + Vector2(0.0, size * 1.28),
		"outer": ec + Vector2(size * 1.05, size * 1.0), "w": Vector3(size * 0.20, size * 0.24, size * 0.10)}
	var oo := o.duplicate()
	if oo.has("brow"):
		for k: String in oo["brow"]:
			b[k] = oo["brow"][k]
		oo.erase("brow")
	oo["brow"] = b
	var spec := beast_spec(c, r, e, hide, iris, glow, Vector2(0.0, -r * 0.35), oo)
	spec["head_mesh"] = CharacterModel.sphere(r, 14, 8)
	if not spec.has("lift"):
		spec["lift"] = size * 0.25
	return spec

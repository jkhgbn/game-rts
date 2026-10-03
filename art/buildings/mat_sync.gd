class_name MatSync
extends RefCounted
## Small helpers for the merged-material syncs (PaintedVC, NatureVC, BuildingPalette; review-art-faces.md M4):
## - put(): sets a shader parameter only when its value changed (a set_shader_parameter is a RenderingServer upload,
##   even with the same value; the material's own stored value is read back for free).
## - shader_default(): RenderingServer.shader_get_parameter_default, cached per shader + uniform (it was looked up on
##   every sync, 18 uniforms x 4 slots for the Nature card material).

static var _defaults: Dictionary = {}   # "shader rid|uniform" -> default Variant (null included)


## Sets `name` on `mat` unless it already holds an equal value (same type and ==). Returns true when it uploaded.
static func put(mat: ShaderMaterial, name: StringName, v: Variant) -> bool:
	var old: Variant = mat.get_shader_parameter(name)
	if old != null and typeof(old) == typeof(v) and old == v:
		return false
	mat.set_shader_parameter(name, v)
	return true


## The shader's default value of `name` (null = none), cached.
static func shader_default(shader: Shader, name: StringName) -> Variant:
	if shader == null:
		return null
	var key := "%d|%s" % [shader.get_rid().get_id(), name]
	if _defaults.has(key):
		return _defaults[key]
	var v: Variant = RenderingServer.shader_get_parameter_default(shader.get_rid(), name)
	_defaults[key] = v
	return v


## A material parameter, else its shader's (cached) default, else null.
static func param(mat: ShaderMaterial, name: StringName) -> Variant:
	if mat == null:
		return null
	var v: Variant = mat.get_shader_parameter(name)
	if v == null:
		v = shader_default(mat.shader, name)
	return v

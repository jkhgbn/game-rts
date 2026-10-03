class_name FaceRig
extends MeshInstance3D
## The face node FaceKit.attach() puts under a head pivot (face rework 2026-09-28): ONE MeshInstance3D whose mesh is a
## cached FaceKit mesh per expression (face + ears + hair + beard in one vertex-coloured surface), swapped by
## set_expression. No _process: the owner model calls react() / auto() from its per-frame code (cheap: a compare, and
## a mesh swap only when the shown expression changes). Hit / level-up flash and glow_boost are driven by the kit like
## any painted / glowing part (unit_face.gdshader declares both); set meta own_glow to drive glow_boost yourself.

## Seconds the face smiles after a level-up (read against CharacterModel.level_up_age(), which keeps running).
const SMILE_LEN := 1.6
## Camera distance (m) beyond which the face is not drawn (the kit's tier 2 starts at 45 m: the model freezes and the
## face is 1-3 px). Saves one draw call + depth prepass per unit at full RTS zoom-out.
const FACE_RANGE_END := 46.0
const FACE_RANGE_MARGIN := 2.0

var _key: String = ""
var _style: Dictionary = {}
var _expr: StringName = &"neutral"
var _shown: StringName = &""


func _init() -> void:
	# CharacterModel._collect adds nodes with this meta to the hit-flash targets (the face, hair and beard flash with
	# the head instead of keeping their colours for the 0.12 s white / cyan / lilac flash).
	set_meta(&"flash_hit", true)
	visibility_range_end = FACE_RANGE_END
	visibility_range_end_margin = FACE_RANGE_MARGIN


func setup(key: String, style: Dictionary) -> void:
	_key = key
	_style = style
	_shown = &""
	_show(_expr)


## The requested expression (FaceKit.EXPRESSIONS or an alias; unknown ids = neutral). Held until changed.
func set_expression(id: StringName) -> void:
	_expr = FaceKit.canonical(id)
	_show(_expr)


func get_expression() -> StringName:
	return _expr


## The expression on screen now (the requested one, or a reaction shown over a neutral request).
func shown_expression() -> StringName:
	return _shown


## A momentary reaction (&"" = none): shown only while the requested expression is neutral.
func react(mood: StringName) -> void:
	_show(FaceKit.canonical(mood) if _expr == &"neutral" and mood != &"" else _expr)


## Reaction from a CharacterModel's state (close camera only, tier 0): dying = worried, level-up = smile, a cast = shout
## (casts whose id starts with "_idle" / "idle" are fidgets: no change), an attack = fierce. `extra_mood` wins when set.
## At tier >= 1 (30 m+) it shows the bold FAR face instead (see far()).
## Typed reads only (CharacterModel.face_tier / face_mood): a renamed kit field fails to compile, never silently.
func auto(model: CharacterModel, extra_mood: StringName = &"") -> void:
	if model.face_tier() != 0:
		far()
		return
	react(extra_mood if extra_mood != &"" else model.face_mood())


## The RTS-distance face (FaceKit.FAR: bold features) while the requested expression is neutral; call it when the
## model's kit tier is >= 1 (30 m+). auto() does it.
func far() -> void:
	_show(FaceKit.FAR if _expr == &"neutral" else _expr)


## Forget the shown mesh (after a revive) and show the requested expression again.
func reset() -> void:
	_shown = &""
	_show(_expr)


func _show(id: StringName) -> void:
	if id == _shown or _key == "":
		return
	_shown = id
	mesh = FaceKit.face_mesh(_key, _style, id)

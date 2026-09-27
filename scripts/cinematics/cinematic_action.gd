class_name CinematicAction
extends Resource
## One timed action of a shot (docs/design/cinematics.md 2.4 + prologue 2.1 + tools-wave 2).
## FROZEN field list: scripts/cinematics/README.md (add only, never rename).
## Kinds (StringName): move, teleport, face, anim, clip, spawn, despawn, dormant, visible, vfx, call, fade, music,
## sfx, shake, title, set_shot. See the README for each kind's params and end state.

const KINDS: Array[StringName] = [&"move", &"teleport", &"face", &"anim", &"clip", &"spawn", &"despawn", &"dormant",
		&"visible", &"vfx", &"call", &"fade", &"music", &"sfx", &"shake", &"title", &"set_shot"]

## Seconds from the shot start.
@export var at: float = 0.0
## One of KINDS.
@export var kind: StringName = &""
## Actor tag (`vessa`, `malrik`...), "" when the kind needs none.
@export var actor: StringName = &""
## World position (move / teleport / spawn / vfx / face target).
@export var target: Vector3 = Vector3.ZERO
## Kind-specific parameters (README table).
@export var params: Dictionary = {}
## `call`: also run on skip / seek (state). Other kinds: their end state is always applied on skip.
@export var on_skip: bool = true


static func make(p_at: float, p_kind: StringName, p_actor: StringName = &"", p_target: Vector3 = Vector3.ZERO,
		p_params: Dictionary = {}) -> CinematicAction:
	var a := CinematicAction.new()
	a.at = p_at
	a.kind = p_kind
	a.actor = p_actor
	a.target = p_target
	a.params = p_params
	return a


static func is_known_kind(k: StringName) -> bool:
	return KINDS.has(k)

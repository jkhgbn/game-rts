class_name MountedDance
extends RefCounted
## Dances and the rank look for the two-model cavalry roots (Blaze Rider, Gloam Rider, Rimehorn Rider, Stagrunner,
## Glade Outrider and the Stables16 placeholders that wrap them). Stables16 / JS 2026-09-27 "make sure they have dance".
## The root's play_clip / stop_clip / current_clip / has_clip / can_dance / set_rank forward here; this plays the clip
## on BOTH kit models: the seated rider dances from the waist up (CharacterModel.can_dance allows a seated rider) and the
## mount prances / rears (victory), lowers its head (surrender) or trots in place (random) (MountModel._pose_dance).
## `root` must answer rider_model() and mount_model().

const CLIPS: Array[StringName] = [&"dance_victory", &"dance_surrender", &"dance_random"]
const RANK_NODE := "RankCrest"


static func _parts(root: Node) -> Array:
	var r: Variant = root.call(&"rider_model") if root.has_method(&"rider_model") else null
	var m: Variant = root.call(&"mount_model") if root.has_method(&"mount_model") else null
	return [r if r is Node and is_instance_valid(r) else null, m if m is Node and is_instance_valid(m) else null]


## True when at least one of the two models plays the clip (both normally).
static func play(root: Node, id: StringName) -> bool:
	if not CLIPS.has(id):
		return false
	var ok := false
	for n: Variant in _parts(root):
		if n != null and (n as Node).has_method(&"play_clip") and bool((n as Node).call(&"play_clip", id)):
			ok = true
	return ok


static func stop(root: Node) -> void:
	for n: Variant in _parts(root):
		if n != null and (n as Node).has_method(&"stop_clip"):
			(n as Node).call(&"stop_clip")


## The rider's clip (else the mount's); &"" = none.
static func current(root: Node) -> StringName:
	for n: Variant in _parts(root):
		if n != null and (n as Node).has_method(&"current_clip"):
			var c := StringName((n as Node).call(&"current_clip"))
			if c != &"":
				return c
	return &""


static func has(root: Node, id: StringName) -> bool:
	if not CLIPS.has(id):
		return false
	for n: Variant in _parts(root):
		if n != null and (n as Node).has_method(&"has_clip") and bool((n as Node).call(&"has_clip", id)):
			return true
	return false


static func can(root: Node) -> bool:
	for n: Variant in _parts(root):
		if n != null and (n as Node).has_method(&"can_dance") and bool((n as Node).call(&"can_dance")):
			return true
	return false


## Rank look hook (Stables16 rank-3 upgrade): PLACEHOLDER until the tech-artist adds a real one (a captain's plume /
## banner): rank >= 3 = a small gold crest ring over the rider's head. Idempotent.
static func set_rank(root: Node3D, rank: int) -> void:
	var crest := root.get_node_or_null(RANK_NODE) as MeshInstance3D
	var on := rank >= 3
	if on and crest == null:
		crest = MeshInstance3D.new()
		crest.name = RANK_NODE
		var torus := TorusMesh.new()
		torus.inner_radius = 0.16
		torus.outer_radius = 0.22
		torus.rings = 12
		torus.ring_segments = 6
		crest.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.82, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.2)
		mat.emission_energy_multiplier = 1.5
		crest.material_override = mat
		crest.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var h := float(root.get(&"body_height")) if root.get(&"body_height") != null else 2.0
		crest.position = Vector3(0, h + 0.55, 0)
		root.add_child(crest)
	if crest:
		crest.visible = on
	root.set_meta(&"rank", rank)

class_name LairArt
extends Node3D
## Epic-beast lair dressing (task 12.V32, docs/design/map-fill.md 5.5 + section 10). Draw-only: no collider, no light,
## no click, no logic beyond the look. One scene per beast kind, built by build_lairs.gd:
##   heath_wallow.tscn     West / East Heath (Tusker): churned mud wallow, tusk-gouged rubbing stones, ploughed turf
##   crag_nest.tscn        Colossus Crag (Roc): a stick nest on the crown of the Fallen Colossus's head, eggshells
##   greymane_hollow.tscn  Greymane Hollow (Direwolf): a bed of flattened ferns, a bone pile, a claw-scored log
##   old_wood_den.tscn     Old Wood Den (Grizzlemaw): a cave mouth dug under a boulder beside the aqueduct pier
##   icebound_barge.tscn   Icebound Barge (Frost Wyrm, 13c.V9, build_icebound_barge.gd): the Drowned Barge frozen over
##                         (icebound_barge.gd extends this class: freezes / thaws instead of a swap, snaps onto the
##                         barge landmark, no Model / Dormant)
## Place the scene at the lair centre (EpicBeasts lair "center"), rotation.y = yaw_for(lair_id): 0 on the west bank,
## PI on the east bank (the point mirror, like the landmarks), so the nest lands on the mirrored Colossus head and the den
## beside the mirrored pier.
## Children: "Model" (always drawn, casts shadows), "Active" (drawn while a beast lives here: fresh signs), "Dormant"
## (drawn while the lair is empty: dry / abandoned signs). Starts empty (beasts first spawn at 6:30+).
## Metadata: `lair_kind` (&"tusker" / &"roc" / &"direwolf" / &"grizzlemaw"), `beast_rest` (local Vector3 where the beast
## looks at home), `decor_clear` (PackedVector3Array of local (x, z, radius) circles where map decor should not grow).

const DIR := "res://art/environment/lairs/"
## EpicBeasts lair id -> scene file (the east lairs reuse the west scene, turned by PI).
const SCENES := {
	&"lair_heath_w": "heath_wallow.tscn", &"lair_heath_e": "heath_wallow.tscn",
	&"lair_crag_w": "crag_nest.tscn", &"lair_crag_e": "crag_nest.tscn",
	&"lair_hollow_w": "greymane_hollow.tscn", &"lair_hollow_e": "greymane_hollow.tscn",
	&"lair_den_w": "old_wood_den.tscn", &"lair_den_e": "old_wood_den.tscn",
	# Frost Wyrm (13c.V9, titans-2.md 7.2): the Icebound Barge overlay; it snaps onto the barge landmark by itself.
	&"wyrm_barge_s": "icebound_barge.tscn", &"wyrm_barge_n": "icebound_barge.tscn",
}
## Beast kind -> scene file, for maps with other lair ids (missions: EpicBeasts.add_lair).
const KIND_SCENES := {
	&"tusker": "heath_wallow.tscn", &"roc": "crag_nest.tscn", &"direwolf": "greymane_hollow.tscn",
	&"grizzlemaw": "old_wood_den.tscn", &"frost_wyrm": "icebound_barge.tscn", &"wyrm": "icebound_barge.tscn",
}

var _occupied := false


## The lair scene path for an EpicBeasts lair id ("" when unknown); falls back on the kind when given.
static func scene_path_for(lair_id: StringName, kind: StringName = &"") -> String:
	if SCENES.has(lair_id):
		return DIR + String(SCENES[lair_id])
	if KIND_SCENES.has(kind):
		return DIR + String(KIND_SCENES[kind])
	return ""


## The yaw to place a lair scene with: PI for the east-bank (mirrored) lairs, else 0.
static func yaw_for(lair_id: StringName) -> float:
	return PI if String(lair_id).ends_with("_e") else 0.0


func _ready() -> void:
	add_to_group(&"lairs")
	_apply()


## True while a beast lives here (Active signs shown), false when the lair is empty (Dormant signs shown).
func set_occupied(occupied: bool) -> void:
	_occupied = occupied
	_apply()


func is_occupied() -> bool:
	return _occupied


## The decor-free circles in world space: (x, z, radius) each (for MapDressingArt.clear_area).
func decor_clear_circles() -> PackedVector3Array:
	var out := PackedVector3Array()
	var local: Variant = get_meta(&"decor_clear", PackedVector3Array())
	if not (local is PackedVector3Array):
		return out
	var xf: Transform3D = global_transform if is_inside_tree() else transform
	for c: Vector3 in local:
		var w: Vector3 = xf * Vector3(c.x, 0.0, c.y)
		out.append(Vector3(w.x, w.z, c.z))
	return out


func _apply() -> void:
	var active := get_node_or_null(^"Active") as Node3D
	var dormant := get_node_or_null(^"Dormant") as Node3D
	if active:
		active.visible = _occupied
	if dormant:
		dormant.visible = not _occupied

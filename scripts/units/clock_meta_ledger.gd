class_name ClockMetaLedger
extends Node
## Saves the gameplay timers kept as absolute CasterKit.now_s() times in `_`-prefixed metas (never saved by
## SaveCodec.encode_metas): Powder Charge's building pause (T3Kit.META_PAUSED) and the Frostbow's Hamstring cooldown
## (BowmanKit.HAMSTRING_META). The save row keeps the TIME LEFT per unit / building; a load puts back now_s() + left
## (the clock itself is not saved). One node per match (group "saved_state", key "clock_metas"), made on first use.

const SAVE_KEY := "clock_metas"
const GROUP := &"clock_meta_ledger"
## The metas this ledger saves (absolute now_s() times).
const METAS: Array[StringName] = [&"_t3_paused_until", &"_bowman_hamstring_at"]


## The match's ledger (created under the current scene when missing), or null without a scene.
static func ensure() -> ClockMetaLedger:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(GROUP):
		if n is ClockMetaLedger and not n.is_queued_for_deletion():
			return n
	if tree.current_scene == null:
		return null
	var l := ClockMetaLedger.new()
	l.name = "ClockMetaLedger"
	tree.current_scene.add_child(l)
	return l


## SaveWorld (saved_state): the existing ledger, else a new one (added to the level by SaveWorld).
static func create_for_save(level: Node, key: String) -> Node:
	if key != SAVE_KEY:
		return null
	for n in level.get_tree().get_nodes_in_group(GROUP):
		if n is ClockMetaLedger and not n.is_queued_for_deletion():
			return n
	var l := ClockMetaLedger.new()
	l.name = "ClockMetaLedger"
	return l


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(&"saved_state")


func save_key() -> String:
	return SAVE_KEY


func save_state() -> Dictionary:
	var now := CasterKit.now_s()
	var rows: Array = []
	for group: StringName in [&"units", &"buildings"]:
		for n in get_tree().get_nodes_in_group(group):
			if not (n is Unit or n is Building):
				continue
			for m in METAS:
				if not n.has_meta(m):
					continue
				var left := float(n.get_meta(m)) - now
				if left > 0.0:
					rows.append({"node": n, "meta": String(m), "left": left})
	return {} if rows.is_empty() else {"rows": rows}


func load_state(d: Dictionary, _nodes: Dictionary) -> void:
	var now := CasterKit.now_s()
	for row: Variant in d.get("rows", []):
		if not row is Dictionary:
			continue
		var r := row as Dictionary
		var n: Variant = r.get("node")
		var meta := StringName(str(r.get("meta", "")))
		if n is Node and is_instance_valid(n) and METAS.has(meta):
			(n as Node).set_meta(meta, now + maxf(0.0, float(r.get("left", 0.0))))

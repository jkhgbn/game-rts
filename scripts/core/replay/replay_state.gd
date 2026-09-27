extends RefCounted
## Replay Lab (docs/plan/replay-lab.md): the match state hash. Order-independent (every per-entity number is rounded
## to an int before it is summed), so it only changes when the game really differs. Everything is read untyped
## (get / has_method) so this file never depends on gameplay class names.
## `summary(tree, frame, t)` -> Dictionary of small numbers (kept in the .replay so a divergence says WHAT differs);
## `hash_of(summary)` -> String (md5 of the canonical JSON).

const TEAMS := [0, 1, 2]   # PLAYER, ENEMY, NEUTRAL


static func summary(tree: SceneTree, frame: int, t: float) -> Dictionary:
	var units := [0, 0, 0]
	var px := [0, 0, 0]       # sum of round(x * 10) + round(z * 10) * 7 (0.1 m)
	var hp := [0, 0, 0]
	var types := [{}, {}, {}]
	for u in tree.get_nodes_in_group(&"units"):
		var team := _team(u)
		if team < 0 or not _alive(u):
			continue
		units[team] += 1
		var n3 := u as Node3D
		if n3 != null and n3.is_inside_tree():
			var p := n3.global_position
			px[team] += roundi(p.x * 10.0) + roundi(p.z * 10.0) * 7
		hp[team] += roundi(float(u.get(&"hp")) if u.get(&"hp") != null else 0.0)
		var ut: Variant = u.get(&"unit_type")
		var id := String(ut.get(&"id")) if ut != null and ut is Object else String(u.get_class())
		types[team][id] = int(types[team].get(id, 0)) + 1
	var buildings := [0, 0, 0]
	var bhp := [0, 0, 0]
	for b in tree.get_nodes_in_group(&"buildings"):
		var team := _team(b)
		if team < 0 or not _alive(b):
			continue
		buildings[team] += 1
		bhp[team] += roundi(float(b.get(&"hp")) if b.get(&"hp") != null else 0.0)
	var crystals := [0, 0]
	var pop := [0, 0]
	var gathered := [0, 0]
	for e in tree.get_nodes_in_group(&"economies"):
		var team := _team(e)
		if team == 0 or team == 1:
			crystals[team] = int(e.get(&"crystals"))
			pop[team] = int(e.get(&"pop_used"))
			gathered[team] = int(e.get(&"gathered_total")) if e.get(&"gathered_total") != null else 0
	var gold := [0, 0]
	for g in tree.get_nodes_in_group(&"gold_banks"):
		var team := _team(g)
		if (team == 0 or team == 1) and g.get(&"gold") != null:
			gold[team] = int(g.get(&"gold"))
	var essence := [0, 0]
	for eb in tree.get_nodes_in_group(&"essence_banks"):
		var team := _team(eb)
		if (team == 0 or team == 1) and eb.get(&"essence") != null:
			essence[team] = int(eb.get(&"essence"))
	var critters := 0
	for c in tree.get_nodes_in_group(&"game_critters"):
		if _alive(c):
			critters += 1
	var type_rows := []
	for team in TEAMS:
		var keys: Array = (types[team] as Dictionary).keys()
		keys.sort()
		var row := []
		for k in keys:
			row.append("%s=%d" % [k, types[team][k]])
		type_rows.append(",".join(PackedStringArray(row)))
	return {"f": frame, "t": snappedf(t, 0.01), "units": units, "pos": px, "hp": hp, "types": type_rows,
			"bld": buildings, "bhp": bhp, "cry": crystals, "pop": pop, "gath": gathered, "gold": gold,
			"ess": essence, "crit": critters}


static func hash_of(s: Dictionary) -> String:
	return JSON.stringify(s, "", true).md5_text()


## The keys whose values differ between two summaries (for the divergence report).
static func diff(a: Dictionary, b: Dictionary) -> Array[String]:
	var out: Array[String] = []
	# Same number format on both sides (a summary read back from a file has floats).
	a = JSON.parse_string(JSON.stringify(a))
	b = JSON.parse_string(JSON.stringify(b))
	for k in a.keys():
		if k == "f":
			continue
		if not b.has(k) or JSON.stringify(a[k]) != JSON.stringify(b[k]):
			out.append("%s: %s vs %s" % [k, JSON.stringify(a.get(k)), JSON.stringify(b.get(k))])
	return out


static func _team(n: Object) -> int:
	var t: Variant = n.get(&"team")
	if t == null:
		return -1
	var i := int(t)
	return i if i >= 0 and i <= 2 else -1


static func _alive(n: Object) -> bool:
	if not is_instance_valid(n):
		return false
	if n.has_method(&"is_alive"):
		return bool(n.call(&"is_alive"))
	return true

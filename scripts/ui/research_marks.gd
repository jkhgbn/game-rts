class_name ResearchMarks
extends RefCounted
## UR.U2 (ui-sc2-console.md 7.5): what research a unit carries, for the selection line, the portrait pips, the type
## tab mark and the grid tooltip. Counts the done unit-research rows that list its type (UnitResearch), its "+"
## (UnitUpgrades) and its Stables rank-3 (Stables16), for its own team (enemy units show theirs: the effects are seen).
## Per-frame safe (review 2026-10-14): the three per-team nodes are found once (SceneTree.node_added + one scan when the
## watch starts), never by a group scan per call; the per-type results are cached and keyed on a fingerprint of the
## team's done lists (a load that rewrites them without a signal still refreshes the marks).

const PIP_MAX := 5

static var _tree: SceneTree = null
static var _nodes: Dictionary = {}       # kind (0 research, 1 "+", 2 rank-3) x 8 + team -> Node
static var _done_cache: Dictionary = {}  # type instance id x 4 + team -> {fp, lang, list, names, tip}


## The team's UnitResearch / UnitUpgrades / Stables16 node (null when it does not exist yet). No group scan.
static func research_node(team: int) -> UnitResearch:
	return _node(0, team) as UnitResearch


static func plus_node(team: int) -> UnitUpgrades:
	return _node(1, team) as UnitUpgrades


static func rank_node(team: int) -> Stables16:
	return _node(2, team) as Stables16


static func _node(kind: int, team: int) -> Node:
	_watch()
	var n: Variant = _nodes.get(kind * 8 + team)
	if n != null and is_instance_valid(n) and (n as Node).is_inside_tree() and not (n as Node).is_queued_for_deletion():
		return n
	return null


static func _watch() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree == _tree:
		return
	_tree = tree
	_nodes.clear()
	_done_cache.clear()
	tree.node_added.connect(_on_node_added)
	for g: StringName in [&"unit_research", &"unit_upgrades", &"stables16"]:
		for n in tree.get_nodes_in_group(g):
			_on_node_added(n)


static func _on_node_added(n: Node) -> void:
	var kind := -1
	if n is UnitResearch:
		kind = 0
	elif n is UnitUpgrades:
		kind = 1
	elif n is Stables16:
		kind = 2
	else:
		return
	_nodes[kind * 8 + int(n.get(&"team"))] = n


## A hash of the team's done lists (research rows, "+", rank-3): changes whenever one is granted / loaded / cleared.
static func fingerprint(team: int) -> int:
	var r := research_node(team)
	var p := plus_node(team)
	var s := rank_node(team)
	return hash([r.done if r else [], p.researched if p else [], s.researched if s else [], UnitResearch.lab_off])


## True when the team has the "+" of `unit_id` / its rank-3 (registry reads, no scan).
static func plus_done(team: int, unit_id: StringName) -> bool:
	var p := plus_node(team)
	return p != null and p.researched.has(unit_id)


static func rank_done(team: int, unit_id: StringName) -> bool:
	var s := rank_node(team)
	return s != null and s.researched.has(unit_id)


## [{name, text}] in unit-page order ("+", rows, rank-3); empty for anything that is not a Unit. Cached: do not modify.
static func done_for(u: Node) -> Array:
	var e := _entry(u)
	return e["list"] if not e.is_empty() else []


static func count(u: Node) -> int:
	return done_for(u).size()


## "Kindled Mail · Flame Guard+" (names shown through Loc.sink), "" when none.
static func names_text(u: Node) -> String:
	var e := _entry(u)
	return str(e["names"]) if not e.is_empty() else ""


## One line per research: "Kindled Mail: +5 armor".
static func tooltip_text(u: Node) -> String:
	var e := _entry(u)
	return str(e["tip"]) if not e.is_empty() else ""


static func _entry(u: Node) -> Dictionary:
	var unit := u as Unit
	if unit == null or not is_instance_valid(unit) or unit.unit_type == null:
		return {}
	var t := int(unit.team)
	var key := unit.unit_type.get_instance_id() * 4 + t
	var fp := fingerprint(t)
	var e: Variant = _done_cache.get(key)
	if e != null and int((e as Dictionary)["fp"]) == fp and (e as Dictionary)["lang"] == Loc.language:
		return e
	var list: Array[Dictionary] = []
	var uid := unit.unit_type.id
	if UnitUpgrades.has_plus(uid) and plus_done(t, uid):
		list.append({"name": UnitUpgrades.display_name(uid), "text": UnitUpgrades.stats_text(uid)})
	if UnitResearch.ENABLED and not UnitResearch.lab_off:
		for id in UnitResearch.rows_for_unit(uid):
			if UnitResearch.team_has(t, id):
				var r := UnitResearch.row(id)
				list.append({"name": str(r["name"]), "text": str(r["text"])})
	if Stables16.has_rank_up(uid) and rank_done(t, uid):
		list.append({"name": Stables16.rank_name(uid),
				"text": str(Stables16.rank_stub(uid).get_meta(&"card_text", ""))})
	var names: PackedStringArray = []
	var lines: PackedStringArray = []
	for d: Dictionary in list:
		var nm := Loc.sink(str(d["name"]))
		names.append(nm)
		lines.append(Loc.t("{name}: {effect}", {"name": nm, "effect": Loc.sink(str(d["text"]))}))
	var out := {"fp": fp, "lang": Loc.language, "list": list, "names": " · ".join(names), "tip": "\n".join(lines)}
	_done_cache[key] = out
	return out


## An 8 x 8 (or `size`) GOLD diamond with a 1 px frame_dark edge, centred on `c`.
static func draw_pip(ci: CanvasItem, c: Vector2, size := 8.0) -> void:
	var h := size * 0.5
	var pts := PackedVector2Array([c + Vector2(0, -h), c + Vector2(h, 0), c + Vector2(0, h), c + Vector2(-h, 0)])
	ci.draw_colored_polygon(pts, UIStyle.GOLD)
	pts.append(pts[0])
	ci.draw_polyline(pts, UIStyle.token(&"frame_dark"), 1.0)

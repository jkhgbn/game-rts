class_name SaveWorld
extends RefCounted
## Captures a running level into a save Dictionary and puts it back into a freshly built level
## (docs/design/save-load.md). SaveGame owns the files and the launch; SaveRestorer calls apply_* in two phases.
## Everything here reaches the game through public hooks: Unit / Building save_snapshot + load_snapshot*,
## Skirmish / WaveStrikeLevel save_level_state, MissionBase save_state, EmberCrown, FogOfWar, the team banks.

const MATCH_RADIUS := 2.0   ## A saved building reuses a rebuilt one of its type and team within this distance.


# ---------------------------------------------------------------- capture

static func capture(level: Node) -> Dictionary:
	var tree := level.get_tree()
	var ids := {}
	var buildings: Array = []
	for n in tree.get_nodes_in_group(&"buildings"):
		var b := n as Building
		if b and b.is_alive() and not b.is_queued_for_deletion() and b.building_type != null:
			ids[b] = ids.size()
			buildings.append(b)
	var units: Array = []
	for n in _saved_units(tree):
		ids[n] = ids.size()
		units.append(n)
	var b_rows: Array = []
	for b: Building in buildings:
		var row := b.save_snapshot(ids)
		row["sid"] = ids[b]
		b_rows.append(row)
	var u_rows: Array = []
	for u: Unit in units:
		var row := u.save_snapshot(ids)
		row["sid"] = ids[u]
		row["kind"] = _kind_of(u)
		if row["kind"] == "champion" and u.has_method(&"get_save_state"):
			row["champion"] = u.call(&"get_save_state")
		var ht: Variant = u.get(&"helper_type")   # helpers (T3 / campaign): rebuilt from their HelperType
		if ht is Resource and &"id" in ht:
			row["helper"] = String(ht.get(&"id"))
		u_rows.append(row)
	var world := {
		"buildings": b_rows,
		"units": u_rows,
		"teams": _capture_teams(tree, ids),
		"nodes": _capture_crystal_nodes(tree),
	}
	var crown: Variant = level.get(&"crown")
	if crown is EmberCrown and is_instance_valid(crown):
		world["crown"] = (crown as EmberCrown).save_state(ids)
	var fog: Variant = level.get(&"fog")
	if fog is FogOfWar and is_instance_valid(fog):
		world["fog"] = {int(Unit.Team.PLAYER): (fog as FogOfWar).explored_cells(Unit.Team.PLAYER),
				int(Unit.Team.ENEMY): (fog as FogOfWar).explored_cells(Unit.Team.ENEMY)}
	if level.has_method(&"save_level_state"):
		world["level_state"] = level.call(&"save_level_state", ids)
	if level is MissionBase:
		world["mission"] = (level as MissionBase).save_state(ids)
	var cam: Variant = level.get(&"camera_rig")
	if cam is Node3D and is_instance_valid(cam):
		world["camera"] = (cam as Node3D).position
	return world


## Living units, every wizard (a dead one waits for its respawn) and every champion (fallen ones too). Units a
## mission put to sleep (set_dormant / hold_world) left the "units" group: they are found by walking the scene.
static func _saved_units(tree: SceneTree) -> Array:
	var out: Array = []
	var seen := {}
	var stack: Array[Node] = [tree.current_scene if tree.current_scene else tree.root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var u := n as Unit
		if u != null and not seen.has(u) and not u.is_queued_for_deletion() \
				and (u.is_alive() or u is Wizard or u.is_in_group(&"champions")):
			seen[u] = true
			out.append(u)
		stack.append_array(n.get_children())
	return out


## A hired champion (ChampionGuild); helpers extend Champion but are rebuilt from their HelperType.
static func _is_guild_champion(u: Unit) -> bool:
	return u is Champion and not (u.get(&"helper_type") is Resource)


static func _kind_of(u: Unit) -> String:
	if u is Wizard:
		return "wizard"
	if _is_guild_champion(u):
		return "champion"
	return "unit"


static func _capture_teams(tree: SceneTree, ids: Dictionary) -> Dictionary:
	var eco: Array = []
	for n in tree.get_nodes_in_group(&"economies"):
		var e := n as Economy
		if e:
			eco.append({"team": int(e.team), "crystals": e.crystals, "gathered": e.gathered_total})
	var ess: Array = []
	for n in tree.get_nodes_in_group(&"essence_banks"):
		if &"essence" in n:
			ess.append({"team": int(n.get(&"team")), "essence": int(n.get(&"essence"))})
	var gold: Array = []
	for n in tree.get_nodes_in_group(&"gold_banks"):
		var g := n as GoldBank
		if g:
			var wares: Array = []
			for w in g.owned_wares:
				wares.append(String(w))
			gold.append({"team": g.team, "gold": g.gold, "wares": wares})
	var forge: Array = []
	for n in tree.get_nodes_in_group(&"forge_upgrades"):
		var f := n as ForgeKit
		if f:
			forge.append({"team": f.team, "levels": f.levels.duplicate()})
	var plus: Array = []
	for n in tree.get_nodes_in_group(&"unit_upgrades"):
		var p := n as UnitUpgrades
		if p:
			var row := p.save_state(ids)
			row["team"] = p.team
			plus.append(row)
	return {"economies": eco, "essence": ess, "gold": gold, "forge": forge, "plus": plus}


static func _capture_crystal_nodes(tree: SceneTree) -> Array:
	var out: Array = []
	for n in tree.get_nodes_in_group(&"crystal_nodes"):
		var c := n as CrystalNode
		if c and not c.is_queued_for_deletion():
			out.append({"id": String(c.node_id), "left": c.crystals_left, "pos": c.global_position})
	return out


# ---------------------------------------------------------------- apply, phase 1: teams, buildings, units

## Rebuilds the saved world in `level` (its match is running). Returns the context phase 2 needs:
## {nodes: save id -> node, units: [[node, row]], buildings: [[node, row]], crystal_nodes: node_id -> node}.
static func apply_phase1(level: Node, world: Dictionary) -> Dictionary:
	var tree := level.get_tree()
	var ctx := {"nodes": {}, "units": [], "buildings": [], "crystal_nodes": {}}
	_apply_teams_before(tree, world.get("teams", {}))
	ctx["crystal_nodes"] = _apply_crystal_nodes(tree, world.get("nodes", []))
	_apply_buildings(level, world.get("buildings", []), ctx)
	_apply_units(level, world.get("units", []), ctx)
	var nodes: Dictionary = ctx["nodes"]
	for pair: Array in ctx["buildings"]:
		(pair[0] as Building).load_snapshot(pair[1], nodes)
	for pair: Array in ctx["units"]:
		(pair[0] as Unit).load_snapshot_base(pair[1], nodes)
	_apply_teams_after(tree, world.get("teams", {}), nodes)
	var crown: Variant = level.get(&"crown")
	if crown is EmberCrown and is_instance_valid(crown) and world.has("crown"):
		(crown as EmberCrown).load_state(world["crown"], nodes)
	var fog: Variant = level.get(&"fog")
	if fog is FogOfWar and is_instance_valid(fog):
		var f: Dictionary = world.get("fog", {})
		for team: Variant in f:
			(fog as FogOfWar).set_explored_cells(int(team), f[team])
	var grid: Variant = level.get(&"build_grid")
	if grid is BuildGrid and is_instance_valid(grid):
		(grid as BuildGrid).request_rebake()
	return ctx


## Phase 2 (a couple of frames later, once the upgrade / ware / Forge flushes ran): HP, mana, kept modifiers, orders,
## the level clock, the mission state, the camera and the selection.
static func apply_phase2(level: Node, world: Dictionary, ctx: Dictionary) -> void:
	var nodes: Dictionary = ctx["nodes"]
	for pair: Array in ctx["buildings"]:
		if is_instance_valid(pair[0]):
			(pair[0] as Building).load_snapshot_late(pair[1], nodes)
	for pair: Array in ctx["units"]:
		if is_instance_valid(pair[0]):
			(pair[0] as Unit).load_snapshot_late(pair[1], nodes, ctx["crystal_nodes"])
	if level.has_method(&"load_level_state") and world.has("level_state"):
		level.call(&"load_level_state", world["level_state"], nodes)
	if level is MissionBase and world.has("mission"):
		(level as MissionBase).load_state(world["mission"], nodes)
	var cam: Variant = level.get(&"camera_rig")
	if cam is RTSCamera and is_instance_valid(cam) and world.get("camera") is Vector3:
		(cam as RTSCamera).focus_on(world["camera"])
	var sel: Variant = level.get(&"selection")
	var hero: Variant = level.get(&"hero")
	if sel is SelectionManager and hero is Unit and is_instance_valid(hero) and (hero as Unit).is_alive():
		(sel as SelectionManager).select_units([hero])


static func _apply_teams_before(tree: SceneTree, teams: Dictionary) -> void:
	for row: Dictionary in teams.get("gold", []):
		var g := GoldBank.for_team(int(row["team"]))
		if g:
			g.gold = int(row.get("gold", g.gold))
			g.restore_wares(row.get("wares", []))
	for row: Dictionary in teams.get("forge", []):
		var f := ForgeKit.for_team(int(row["team"]))
		if f:
			var lv: Dictionary = row.get("levels", {})
			for line: Variant in lv:
				f.set_level(StringName(str(line)), int(lv[line]))
	for n in tree.get_nodes_in_group(&"essence_banks"):
		for row: Dictionary in teams.get("essence", []):
			if int(row["team"]) == int(n.get(&"team")):
				n.set(&"essence", int(row["essence"]))
				if n.has_signal(&"changed"):
					n.emit_signal(&"changed")


## After the buildings exist (halls of the "+" upgrades) and the units are placed: crystals, upgrades in progress.
static func _apply_teams_after(tree: SceneTree, teams: Dictionary, nodes: Dictionary) -> void:
	for row: Dictionary in teams.get("plus", []):
		var p := UnitUpgrades.for_team(int(row["team"]))
		if p:
			p.load_state(row, nodes)
	for n in tree.get_nodes_in_group(&"economies"):
		var e := n as Economy
		for row: Dictionary in teams.get("economies", []):
			if e and int(row["team"]) == int(e.team):
				e.crystals = int(row["crystals"])
				e.gathered_total = int(row.get("gathered", e.gathered_total))
				e.changed.emit()


static func _apply_crystal_nodes(tree: SceneTree, rows: Array) -> Dictionary:
	var saved := {}
	for row: Dictionary in rows:
		saved[StringName(str(row["id"]))] = row
	var out := {}
	for n in tree.get_nodes_in_group(&"crystal_nodes"):
		var c := n as CrystalNode
		if c == null or c.is_queued_for_deletion():
			continue
		out[c.node_id] = c
		if saved.has(c.node_id):
			var left := int((saved[c.node_id] as Dictionary)["left"])
			if left < c.crystals_left:
				c.take(c.crystals_left - left)   # the look shrinks the usual way
		elif c.crystals_left > 0 and not rows.is_empty():
			c.take(c.crystals_left)   # mined out before the save: it depletes the usual way
	return out


static func _apply_buildings(level: Node, rows: Array, ctx: Dictionary) -> void:
	var fresh: Array = []
	for n in level.get_tree().get_nodes_in_group(&"buildings"):
		var b := n as Building
		if b and b.is_alive() and b.building_type != null:
			fresh.append(b)
	var used := {}
	var grid: Variant = level.get(&"build_grid")
	for row: Dictionary in rows:
		var best: Building = null
		var best_d := MATCH_RADIUS
		for b: Building in fresh:
			if used.has(b) or String(b.building_type.id) != String(row["type"]) or int(b.team) != int(row["team"]):
				continue
			var d := b.global_position.distance_to(row["pos"])
			if d <= best_d:
				best_d = d
				best = b
		if best == null and grid is BuildGrid:
			var type := BuildingType.find(String(row["type"]))
			if type and float(row.get("progress", 1.0)) < 1.0:
				best = (grid as BuildGrid).spawn_site(type, row["pos"], int(row["team"]))   # review 2026-10-10 #5
			elif type:
				best = (grid as BuildGrid).spawn_complete(type, row["pos"], int(row["team"]))
		if best == null:
			push_warning("Save: building %s could not be rebuilt" % row["type"])
			continue
		used[best] = true
		(ctx["nodes"] as Dictionary)[row["sid"]] = best
		(ctx["buildings"] as Array).append([best, row])
	for b: Building in fresh:
		if not used.has(b):
			b.dispose_for_load()


static func _apply_units(level: Node, rows: Array, ctx: Dictionary) -> void:
	var tree := level.get_tree()
	var fresh_wizards: Array = []
	var fresh: Array = []
	for u: Unit in _saved_units(tree):
		if u is Wizard:
			fresh_wizards.append(u)
		elif not _is_guild_champion(u):
			fresh.append(u)
	var used := {}
	var nodes: Dictionary = ctx["nodes"]
	for row: Dictionary in rows:
		var u: Unit = null
		match String(row.get("kind", "unit")):
			"wizard":
				u = _match_wizard(fresh_wizards, row, used)
				if u == null:
					u = _spawn_unit(level, row)   # a story wizard the rebuilt start has not raised yet
			"champion":
				u = _spawn_champion(level, row)
			_:
				u = _match_unit(fresh, row, used)
				if u == null:
					u = _spawn_unit(level, row)
		if u == null:
			push_warning("Save: %s %s / %s / %s (team %d) could not be rebuilt" % [row.get("kind", "?"),
					row.get("type", "?"), row.get("name", "?"), row.get("script", "?"), int(row.get("team", -1))])
			continue
		used[u] = true
		nodes[row["sid"]] = u
		(ctx["units"] as Array).append([u, row])
	for u: Unit in fresh + fresh_wizards:
		if not used.has(u):
			var parent := u.get_parent()
			if parent:
				parent.remove_child(u)   # tree_exiting: the Economy gives its pop back, managers forget it
			u.queue_free()


## Same team and script; the same node name first (story wizards keep theirs), else the nearest.
static func _match_wizard(fresh: Array, row: Dictionary, used: Dictionary) -> Unit:
	var best: Unit = null
	var best_d := INF
	for w: Unit in fresh:
		if used.has(w) or int(w.team) != int(row["team"]) \
				or (w.get_script() as Script).resource_path != String(row.get("script", "")):
			continue
		if String(w.name) == String(row.get("name", "")):
			return w
		var d := w.global_position.distance_squared_to(row["pos"])
		if d < best_d:
			best_d = d
			best = w
	return best


static func _match_unit(fresh: Array, row: Dictionary, used: Dictionary) -> Unit:
	var best: Unit = null
	var best_d := INF
	var typeless := String(row.get("type", "")) == ""   # a scripted unit without UnitType: matched by its script
	for u: Unit in fresh:
		if used.has(u) or int(u.team) != int(row["team"]):
			continue
		if typeless:
			if u.unit_type != null or u.get_script() == null \
					or (u.get_script() as Script).resource_path != String(row.get("script", "")):
				continue
		elif u.unit_type == null or String(u.unit_type.id) != String(row["type"]):
			continue
		if typeless and String(u.name) == String(row.get("name", "")):
			return u   # a named story actor
		var d := u.global_position.distance_squared_to(row["pos"])
		if d < best_d:
			best_d = d
			best = u
	return best


static func _spawn_unit(level: Node, row: Dictionary) -> Unit:
	if level.has_method(&"save_spawn_unit"):
		var special: Variant = level.call(&"save_spawn_unit", row)
		if special is Unit:
			return special
	var u: Unit = null
	var type := UnitType.find(String(row.get("type", ""))) if String(row.get("type", "")) != "" else null
	if type != null:
		u = Worker.make_unit(type)
	else:
		u = _new_from_script(String(row.get("script", "")))   # a scripted unit (helper, actor): its defaults
		if u != null and row.has("helper") and u.has_method(&"apply_helper_type"):
			var ht := HelperType.find(StringName(str(row["helper"])))
			if ht:
				u.call(&"apply_helper_type", ht, int(row.get("level", 1)))
	if u == null:
		return null
	u.team = int(row["team"]) as Unit.Team
	level.add_child(u)
	u.global_position = row["pos"]
	u.command_stop()
	return u


## A Unit from its script when its _init takes no argument, else null.
static func _new_from_script(path: String) -> Unit:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var s := load(path) as Script
	if s == null or not s.can_instantiate():
		return null
	for m: Dictionary in s.get_script_method_list():
		if m["name"] == "_init" and (m["args"] as Array).size() > (m["default_args"] as Array).size():
			return null
	return s.new() as Unit


static func _spawn_champion(level: Node, row: Dictionary) -> Unit:
	var team := int(row["team"])
	var guild: Variant = level.call(&"guild_of", team) if level.has_method(&"guild_of") else ChampionGuild.for_team(team)
	var state: Dictionary = row.get("champion", {})
	if not guild is ChampionGuild or state.is_empty():
		return null
	var ch: Variant = (guild as ChampionGuild).add_companion(state, row["pos"])
	if not ch is Unit:
		return null
	if ch.has_method(&"apply_save_state"):
		ch.call(&"apply_save_state", state)
	if not bool(row.get("alive", true)) and (ch as Unit).is_alive():
		(ch as Unit).take_damage((ch as Unit).max_hp * 100.0, null)   # fallen: the guild's revive applies
	return ch

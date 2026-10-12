extends "../balance_lab/faster_games/fg_match.gd"
## Thornwater probe (docs/balance/thornwater_2026-10-11.md): one faster-games match (fg_match.gd, same flags) plus,
## in the JSON under "probe", where the fights happen. Lab only; nothing in the game reads it.
##   "deaths": [[t, team, x, z, victim kind, killer kind], ...]   every soldier / wizard / worker death of both sides
##             (x, z in world space; kind = worker / soldier / hero / champion; killer = hero / champion / soldier /
##             tower / building / neutral / other)
##   "groups": [[t, team, stage, x, z, n], ...]                   each bot's attack group every 5 s while it is out
## Run: godot_run.ps1 --headless --path . -s res://tools/map_lab/tw_probe.gd ... -- <fg_match.gd flags>

##   variant "spells": {"fireball": {"damage_by_rank": "x0.8", "radius": "x0.9"}}   lab-only spell overrides (in memory,
##             on the cached SpellType; a number field or every entry of a number array; nothing on disk is written)

var _probe_deaths: Array = []
var _held_spells: Array = []


func apply_variant(data: Dictionary) -> void:
	super.apply_variant(data)
	var sp: Variant = data.get("spells", {})
	if not (sp is Dictionary):
		return
	for id: String in sp:
		var t: Resource = SpellType.find(StringName(id))
		if t == null:
			variant_errors.append("spells.%s: no such spell" % id)
			continue
		_held_spells.append(t)
		var fields: Dictionary = sp[id]
		for f: String in fields:
			if not (StringName(f) in t):
				variant_errors.append("spells.%s.%s: no such field" % [id, f])
				continue
			var old: Variant = t.get(StringName(f))
			if old is Array:
				var arr: Array = (old as Array).duplicate()
				for i in arr.size():
					arr[i] = resolve_value(float(arr[i]), fields[f])
				t.set(StringName(f), arr)
			elif old is float or old is int:
				t.set(StringName(f), resolve_value(float(old), fields[f]))
			variant_applied.append({"kind": "spell", "id": id, "field": f, "from": old, "to": t.get(StringName(f))})
var _probe_groups: Array = []
var _probe_next := 0.0


func _on_match_started() -> void:
	super._on_match_started()
	var ev := root.get_node_or_null(^"Events")
	if ev != null and ev.has_signal(&"unit_died"):
		ev.connect(&"unit_died", _probe_died)


func _probe_died(u: Node) -> void:
	if u == null or not is_instance_valid(u) or not (u is Node3D):
		return
	var team := int(u.get(&"team"))
	if team != PLAYER and team != ENEMY:
		return
	var t: float = float(main.call(&"match_time")) if main != null and is_instance_valid(main) else 0.0
	var kind := "worker" if u.has_method(&"command_gather") else "hero" if (u.is_in_group(&"heroes") \
			or u.is_in_group(&"enemy_heroes") or u.has_method(&"command_cast")) else "champion" \
			if u.is_in_group(&"champions") else "soldier"
	var k: Variant = u.get(&"killer")
	var by := "other"
	if k is Node and is_instance_valid(k):
		var kn := k as Node
		if kn.is_in_group(&"heroes") or kn.is_in_group(&"enemy_heroes") or kn.has_method(&"command_cast"):
			by = "hero"
		elif kn.is_in_group(&"champions"):
			by = "champion"
		elif kn.is_in_group(&"buildings"):
			by = "tower" if kn.has_method(&"tower_range") or String(kn.name).to_lower().contains("tower") else "building"
		elif kn.is_in_group(&"units"):
			var kt: Variant = kn.get(&"team")
			by = "soldier" if kt != null and int(kt) == 1 - team else "neutral"
	var p := (u as Node3D).global_position
	_probe_deaths.append([int(t), team, snappedf(p.x, 0.5), snappedf(p.z, 0.5), kind, by])


func _process(delta: float) -> bool:
	var r := super._process(delta)
	if main == null or not is_instance_valid(main) or not main.has_method(&"match_time"):
		return r
	var t := float(main.call(&"match_time"))
	if t < _probe_next:
		return r
	_probe_next = t + 5.0
	for team in [PLAYER, ENEMY]:
		var bot: Node = bots[team]
		if bot == null or not is_instance_valid(bot):
			continue
		var st: Variant = bot.get(&"stage")
		if st == null or int(st) == 0:
			continue
		var g: Variant = bot.get(&"_group")
		if not (g is Array) or (g as Array).is_empty():
			continue
		var c := Vector3.ZERO
		var n := 0
		for u: Variant in g:
			if u is Node3D and is_instance_valid(u):
				c += (u as Node3D).global_position
				n += 1
		if n == 0:
			continue
		c /= float(n)
		_probe_groups.append([int(t), team, int(st), snappedf(c.x, 0.5), snappedf(c.z, 0.5), n])
	return r


func _finish(reason: String, winner: int, error: String) -> bool:
	var was_finished := _finished
	var r := super._finish(reason, winner, error)
	if was_finished or out_path == "":
		return r
	var f := FileAccess.open(out_path, FileAccess.READ)
	if f == null:
		return r
	var data: Variant = JSON.parse_string(f.get_line())
	f.close()
	if not (data is Dictionary):
		return r
	data["probe"] = {"deaths": _probe_deaths, "groups": _probe_groups}
	var w := FileAccess.open(out_path, FileAccess.WRITE)
	if w:
		w.store_line(JSON.stringify(data))
		w.close()
	return r

extends SceneTree
## Ice VFX readability capture (2026-10-12, trimmed copy of ingame_capture.gd): battle + hero fight only, no base build.
## Args after '--': --kp=ice --ke=nature --out=before|after

const SKIRMISH := "res://scenes/skirmish.tscn"
const OUT_ROOT := "res://docs/art/ingame_grade/ice_vfx_2026-10-12"
var OUT := OUT_ROOT
const TITANS := {"fire": "res://art/units/titans/cinder_dragon/cinder_dragon.tscn",
	"ice": "res://art/units/titans/war_mammoth/war_mammoth.tscn",
	"nature": "res://art/units/titans/elder_treant/elder_treant.tscn",
	"shadow": "res://art/units/titans/nightmare_knight/nightmare_knight.tscn"}

var args := {}
var main: Node = null
var kp := "fire"
var ke := "shadow"
var tag := "a"


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var wd := create_timer(420.0, true, false, true)
	wd.timeout.connect(func() -> void:
		print("CAP ERROR watchdog")
		quit(3))
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s.substr(0, eq) if eq >= 0 else s] = s.substr(eq + 1) if eq >= 0 else "1"
	kp = String(args.get("kp", "ice"))
	ke = String(args.get("ke", "nature"))
	tag = String(args.get("tag", "s"))
	OUT = OUT_ROOT + "/" + String(args.get("out", OS.get_environment("FW_CAP_OUT") if OS.get_environment("FW_CAP_OUT") != "" else "before"))
	seed(12345)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	for i in 4:
		await process_frame
	main = (load(SKIRMISH) as PackedScene).instantiate()
	main.set(&"player_kingdom", StringName(kp))
	main.set(&"enemy_kingdom", StringName(ke))
	main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	var waited := 0
	while not bool(main.get(&"match_started")):
		await process_frame
		waited += 1
		if waited > 20000:
			print("CAP ERROR never started")
			quit(2)
			return
	for i in 30:
		await process_frame
	for team in [0, 1]:
		var wz: Node = main.call(&"wizard_of", team)
		var pn: Node = wz.get_node_or_null(^"StrIntPath") if wz else null
		if pn == null and wz:
			for c in wz.get_children():
				if c.has_method(&"default_pick"):
					pn = c
		if pn and not bool(pn.call(&"is_locked")):
			print("CAP path ", pn.call(&"choose", pn.call(&"default_pick")))
	paused = false
	for i in 10:
		await process_frame
	var cam: Node = main.get(&"camera_rig")
	cam.set(&"edge_pan_enabled", false)
	Input.warp_mouse(Vector2(1598, 898))
	var fog: Variant = main.get(&"fog")
	if fog is Node:
		(fog as Node).set(&"enabled", false)
	# Tier 3 for both sides (keep look + T3 units allowed).
	var ts: Node = get_first_node_in_group(&"tier_systems")
	if ts:
		ts.call(&"set_tier", 0, 3)
		ts.call(&"set_tier", 1, 3)
	# Big battle.
	var bpos := _land_near([Vector3(-16, 0, 34), Vector3(-24, 0, 24), Vector3(-12, 0, 34), Vector3(-40, 0, 20)])
	print("CAP battle at ", bpos)
	var army := _spawn_armies(bpos)
	_titans(bpos)
	var sel: Variant = main.get(&"selection")
	if sel is Node:
		(sel as Node).call(&"select_units", army[0])
	for i in 50:
		await process_frame
	await _shot("battle_%s_%s_start" % [kp, ke], bpos, 30.0)
	await _wait(2.2)
	await _shot("battle_%s_%s_mid" % [kp, ke], bpos, 30.0)
	await _shot("battle_%s_%s_close" % [kp, ke], bpos, 18.0)
	await _shot("battle_%s_%s_zoom" % [kp, ke], bpos, 12.0)
	await _wait(1.5)
	await _shot("battle_%s_%s_far" % [kp, ke], bpos, 45.0)
	if sel is Node:
		(sel as Node).call(&"select_units", [])
	# Hero fight: wizards + champions away from the battle.
	var hpos := _land_near([Vector3(-8, 0, 46), Vector3(-40, 0, 44), Vector3(-30, 0, 46)])
	await _hero_fight(hpos)
	if String(args.get("biomes", "0")) == "1":
		for b: Array in [["biome_crown_isle", Vector3(0, 0, 0), 40.0], ["biome_old_wood", Vector3(-44, 0, -44), 34.0],
				["biome_heath", Vector3(-8, 0, -46), 34.0], ["biome_riverbank", Vector3(-12, 0, 8), 30.0],
				["biome_overview", Vector3(-6, 0, 6), 55.0], ["biome_enemy_side", Vector3(40, 0, -30), 45.0]]:
			await _shot(String(b[0]), b[1], float(b[2]))
	print("CAP done")
	quit(0)


func _wait(sec: float) -> void:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < int(sec * 1000.0):
		await process_frame


func _shot(id: String, at: Vector3, zoom: float) -> void:
	var cam: Node3D = main.get(&"camera_rig")
	cam.rotation = Vector3.ZERO
	cam.call(&"focus_on", at + Vector3(0, 0, zoom * 0.14))
	cam.set(&"_zoom", zoom)
	cam.set(&"_target_zoom", zoom)
	cam.call(&"_apply_zoom")
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var p := ProjectSettings.globalize_path("%s/%s_%s.png" % [OUT, tag, id])
	img.save_png(p)
	print("CAP shot ", p, " ", img.get_size())


func _is_land(p: Vector3) -> bool:
	var r: Node = get_first_node_in_group(&"river")
	if r == null or not r.has_method(&"is_water"):
		return true
	for dx in [-10, 0, 10]:
		for dz in [-10, 0, 10]:
			if bool(r.call(&"is_water", p + Vector3(dx, 0, dz))):
				return false
	return true


func _land_near(cands: Array) -> Vector3:
	for c: Vector3 in cands:
		if _is_land(c):
			return c
	return cands[0]


func _build_base(team: int, kingdom: String) -> void:
	var grid: Object = main.get(&"build_grid")
	var near: Vector3 = main.call(&"base_center", team)
	var ids: Array[String] = []
	for f: String in DirAccess.get_files_at("res://data/buildings/"):
		var fn := f.trim_suffix(".remap")
		if fn.ends_with(".tres") and fn.begins_with(kingdom + "_") and not fn.contains("keep"):
			ids.append(fn.get_basename())
	ids.sort()
	var dir: Vector3 = Vector3(1, 0, -1) if team == 0 else Vector3(-1, 0, 1)
	var i := 0
	for id in ids:
		var bt: Resource = load("res://data/buildings/%s.tres" % id)
		var target: Vector3 = near + dir * (8.0 + 3.0 * (i % 3)) + Vector3(dir.z, 0, -dir.x) * (-10.0 + 7.0 * float(i))
		var spot: Vector3 = grid.call(&"find_spot", bt, target, team, 14)
		if spot == Vector3.INF:
			print("CAP no spot for ", id)
			i += 1
			continue
		var b: Node = grid.call(&"spawn_complete", bt, spot, team)
		print("CAP built ", id, " at ", spot, " ok=", b != null)
		if id.ends_with("_wall") and b:   # a short wall run
			for j in 3:
				var bt2 := bt
				var s2: Vector3 = grid.call(&"find_spot", bt2, spot + Vector3(2.0 * (j + 1), 0, 0), team, 3)
				if s2 != Vector3.INF:
					grid.call(&"spawn_complete", bt2, s2, team)
		i += 1


func _kingdom_types(kingdom: String) -> Array[String]:
	var out: Array[String] = []
	var names: Array[String] = []
	for f: String in DirAccess.get_files_at("res://data/units/"):
		var fn := f.trim_suffix(".remap")
		if fn.ends_with(".tres"):
			names.append(fn.get_basename())
	names.sort()
	for id in names:
		var t: Resource = load("res://data/units/%s.tres" % id)
		if t == null or String(t.get(&"faction")) != kingdom:
			continue
		if bool(t.get(&"is_caravan")) or float(t.get(&"lifetime")) > 0.0 or bool(t.get(&"is_worker")):
			continue
		out.append(id)
	return out


func _spawn_armies(center: Vector3) -> Array:
	var res := [[], []]
	var axis := Vector3(1, 0, 1).normalized()      # front line direction
	var fwd := Vector3(1, 0, -1).normalized()      # player -> enemy
	for team in [0, 1]:
		var types := _kingdom_types(kp if team == 0 else ke)
		print("CAP team ", team, " types ", types)
		var n := types.size()
		for i in n:
			var u: Node = main.call(&"make_unit", types[i])
			if u == null:
				continue
			u.set(&"team", team)
			main.add_child(u)
			var row: int = i % 2
			var x: float = (float(i / 2) - float(n / 2 - 1) * 0.5) * 2.4
			var side: float = -1.0 if team == 0 else 1.0
			var p: Vector3 = center + axis * x + fwd * side * (4.0 + 2.0 * row)
			(u as Node3D).global_position = p
			u.call(&"command_stop")
			res[team].append(u)
	for team in [0, 1]:
		for u: Node in res[team]:
			var best: Node = null
			var bd := INF
			for e: Node in res[1 - team]:
				var d: float = (e as Node3D).global_position.distance_to((u as Node3D).global_position)
				if d < bd:
					bd = d
					best = e
			if best:
				u.call(&"command_attack", best)
	return res


func _titans(center: Vector3) -> void:
	var fwd := Vector3(1, 0, -1).normalized()
	for team in [0, 1]:
		var k: String = kp if team == 0 else ke
		var path: String = TITANS.get(k, "")
		if path == "" or not ResourceLoader.exists(path):
			continue
		var n: Node3D = (load(path) as PackedScene).instantiate() as Node3D
		main.add_child(n)
		var side: float = -1.0 if team == 0 else 1.0
		n.global_position = center + fwd * side * 11.0 + Vector3(1, 0, 1).normalized() * 7.0
		n.rotation.y = PI * 0.75 if team == 1 else -PI * 0.25
		if n.has_method(&"set_team_color"):
			pass
		print("CAP titan ", k)


func _hero_fight(center: Vector3) -> void:
	var fwd := Vector3(1, 0, -1).normalized()
	var wiz := [main.call(&"wizard_of", 0), main.call(&"wizard_of", 1)]
	var fighters := [[], []]
	var ctype: Script = load("res://scripts/units/champion_type.gd")
	var all: Array = ctype.call(&"all")
	var chscript: Script = load("res://scripts/units/champion.gd")
	var classes := [&"spear", &"sword_shield", &"two_hand", &"wizard"]
	for team in [0, 1]:
		var side: float = -1.0 if team == 0 else 1.0
		var w: Node3D = wiz[team]
		if w:
			w.global_position = center + fwd * side * 3.5
			w.call(&"command_stop")
			fighters[team].append(w)
			var sc: Node = w.get_node_or_null(^"SpellCaster")
			w.call(&"add_xp", 5000)
			w.set(&"spell_points", 10)
			for id: StringName in w.get(&"default_spell_ids"):
				print("CAP learn ", id, " '", w.call(&"learn_spell", id), "'")
			w.set(&"mana", 9999.0)
		for j in 2:
			var idx: int = (team * 2 + j) % maxi(1, all.size())
			var ch: Node3D = chscript.new() as Node3D
			ch.set(&"team", team)
			ch.call(&"apply_champion_type", all[idx], j)
			main.add_child(ch)
			ch.global_position = center + fwd * side * 6.0 + Vector3(1, 0, 1).normalized() * (3.0 if j == 0 else -3.0)
			ch.call(&"set_champion_class", classes[(team * 2 + j) % 4])
			ch.call(&"command_stop")
			fighters[team].append(ch)
			print("CAP champion ", all[idx].get(&"id"), " team ", team)
	for team in [0, 1]:
		for u: Node in fighters[team]:
			if not fighters[1 - team].is_empty():
				u.call(&"command_attack", fighters[1 - team][0])
	await _wait(0.8)
	for step in 3:
		for team in [0, 1]:
			var w: Node = wiz[team]
			if w == null or fighters[1 - team].is_empty():
				continue
			var ids: Array = w.get(&"default_spell_ids")
			if step < ids.size():
				var tgt: Node3D = wiz[1 - team] if wiz[1 - team] else fighters[1 - team][0]
				var r: Variant = w.call(&"command_cast", ids[step], tgt)
				if String(r) != "":
					r = w.call(&"command_cast", ids[step], tgt.global_position)
				print("CAP cast ", ids[step], " -> '", r, "'")
		await _wait(0.35)
		await _shot("hero_%s_%s_%d" % [kp, ke, step], center, 22.0)
		await _shot("hero_%s_%s_%d_zoom" % [kp, ke, step], center, 13.0)
		await _wait(0.6)
	await _shot("hero_%s_%s_rts" % [kp, ke], center, 30.0)

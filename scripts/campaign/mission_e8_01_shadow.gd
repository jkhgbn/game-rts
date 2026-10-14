class_name MissionE8_01Shadow
extends MissionE8_01
## e8m1_shadow "Put Down the Shovel" (docs/design/mission-e8-01.md B): Malrik lays the three Barrow Doors of Duskbarrow
## to rest, breaks the Stair Gate, lets Mother Hush go at 25 % and carries the stone up the Gravedigger's Stair. The
## Stone's Gift (a mission button) is strong and counted: every use adds 1 to `e8_stone_uses` (the King's HP in e8m3)
## and fails "Put down the shovel". Spotlight: the Hexweaver.
##
## Built deviations (2026-10-09): Duskbarrow is the generator map with crypt-block props (no lanes of width 6); the doors,
## the Stair Gate, the camp and the exit sit on the spec's positions. The Stone's Gift is a button panel (top right):
## +40 spell power for 10 s and 4 Barrow Ghouls for 25 s beside Malrik (no corpse rule). Story floor: the Stair Gate's
## ward fades only after the third door and 16:30 ("at moonset"), so the scripted run lands in the 18-22 min target.

const DOORS := {&"bd1": Vector3(-30.0, 0.0, -10.0), &"bd2": Vector3(10.0, 0.0, 10.0), &"bd3": Vector3(36.0, 0.0, 26.0)}
const DOOR_NAMES := {&"bd1": "The Old Ossuary", &"bd2": "Candle Row", &"bd3": "The Gravedigger's Yard"}
const STAIR_GATE := Vector3(38.0, 0.0, -36.0)
const GARRISON := Vector3(30.0, 0.0, -26.0)
const EXIT := Vector3(50.0, 0.0, -50.0)
const EXIT_R := 5.0
const CAMP := Vector3(48.0, 0.0, -12.0)
const CAPTAIN_POS := Vector3(-24.0, 0.0, 38.0)
const DOOR_R := 3.0
const DOOR_CLEAR := 8.0
const LAY_TIME: Array[float] = [4.0, 5.0, 6.0]
const RISEN_EVERY: Array[float] = [60.0, 45.0, 35.0]
const RISEN_MAX := 10
const HUSH_HP: Array[float] = [2400.0, 3200.0, 4200.0]
const WARD_FLOOR := 990.0
const GIFT_COOLDOWN := 40.0
const RAIDS := [[240.0, "R1", [["shade", 4], ["grave_hound", 2]]], [540.0, "R2", [["shade", 4], ["nightbolt", 2], ["shadow_knight", 1]]],
		[900.0, "R4", [["shade", 4], ["shadow_knight", 2], ["nightbolt", 2]]]]
const HINT_START := "Lay each Barrow Door to rest: Malrik within 3 m for 5 s, with the yard cleared."
const HINT_OFFER := "The stone offers. You can say no."
const MSG_CLEAR := "Clear the yard first"
const MSG_WARD := "The Stair Gate's amber ward holds until moonset"
const MSG_GATE_STANDS := "The Stair Gate still stands"
const MSG_GIFT_WAIT := "The stone is still warm"

## Read only.
var laid: Array[String] = []
var door_progress := {}
var door_next := {}
var risen := {}                    ## door id -> Array of living Risen
var stone_uses := 0
var gift_ready_at := 0.0
var gift_until := 0.0
var hush: Unit
var hush_state := 0                ## 0 waiting, 1 fighting, 2 fled
var hush_calls := 0
var stair: WardenGate
var tents: Array = []
var captain: Unit

var _gift_panel: Control


func _road() -> StringName:
	return &"shadow"


func _road_title() -> String:
	return "Put Down the Shovel"


func _road_army() -> Array:
	return [["shade", 6], ["nightbolt", 4], ["grave_hound", 2], ["shadow_knight", 1], ["hexweaver", 2], ["gloom_deacon", 1]]


func _map_seed() -> int:
	return 1812


func _clearings() -> Array:
	var out: Array = [[STAIR_GATE, 7.0], [GARRISON, 8.0], [EXIT, 6.0], [CAMP, 7.0], [CAPTAIN_POS, 4.0]]
	for id: StringName in DOORS:
		out.append([DOORS[id], 9.0])
	return out


func _lanes() -> Array:
	return [[KEEP_POS, DOORS[&"bd1"], 5.0], [KEEP_POS, DOORS[&"bd2"], 5.0], [DOORS[&"bd2"], DOORS[&"bd3"], 5.0],
			[DOORS[&"bd2"], STAIR_GATE, 5.0], [STAIR_GATE, EXIT, 5.0], [CAMP, STAIR_GATE, 4.0], [DOORS[&"bd1"], NODES[3][1], 4.0]]


func _init() -> void:
	super()
	define_objectives([[&"obj_doors", "primary"], [&"obj_hush", "primary"], [&"obj_stair", "primary"],
			[&"obj_malrik", "primary"], [&"obj_keep", "primary"], [&"sec_shovel", "secondary"], [&"sec_raids", "secondary"]])
	local_unit("shade", "captain_story", "Shade Captain", {"max_hp": 500.0, "commandable": false, "pop": 0, "kill_xp": 0})
	local_unit("mother_hush", "hush_boss", "Mother Hush, Stone-sworn", {"max_hp": 3200.0, "armor": 10.0,
			"attack_damage": 40.0, "attack_cooldown": 1.0, "move_speed": 5.4, "pop": 0, "kill_xp": 0, "cost": 900,
			"commandable": false, "aggro_range": 10.0, "neutral_leash": false})
	local_unit("barrow_ghoul", "gift_ghoul", "Risen Ghoul", {"pop": 0, "kill_xp": 0, "commandable": true})


func _mission_config() -> MissionConfig:
	var c := super()
	c.keep_lost_message = "The Bishop's Keep has fallen."
	c.spotlight = {"id": &"hexweaver", "trigger": &"manual", "key_hint": "Gloom Hall",
			"card": "Hexweaver. A curse for the big ones: heroes, knights and anything worth more than its friends."}
	return c


func _ready() -> void:
	super()
	tint_light(Color(0.75, 0.65, 0.95), 0.8, -30.0, Color(0.40, 0.36, 0.50), Color(0.16, 0.14, 0.26), Color(0.52, 0.40, 0.62))


func _variant_map() -> void:
	for id: StringName in DOORS:
		var p: Vector3 = DOORS[id]
		box_prop(p + Vector3(0.0, 0.0, -2.5), Vector3(5.0, 3.0, 2.0), Color(0.34, 0.32, 0.38))
		ground_disc(p, DOOR_R, Color(1.0, 0.72, 0.30, 0.40), 0.05)
	for i in 10:   # crypt blocks along the lanes' sides
		var a := float(i) * 2.1
		box_prop(Vector3(cos(a) * (20.0 + i * 3.0), 0.0, sin(a) * (20.0 + i * 3.0)), Vector3(3.0, 2.2, 3.0), Color(0.30, 0.28, 0.34), a)
	ground_disc(EXIT, EXIT_R, Color(0.85, 0.80, 0.95, 0.30), 0.05)
	stair = add_warden_gate(&"stair_gate", STAIR_GATE, GARRISON, 1800.0, 0.0, Callable())
	stair.display_name = "Stair Gate"
	stair.close_tide()
	stair.gate_down.connect(_on_stair_down)
	var tent_type := MissionE5Base.local_building("shadow_hovel", "stone_tent", "Stone-sworn Tent", 600.0)
	for off: Vector3 in [Vector3(-3.0, 0.0, 0.0), Vector3(3.0, 0.0, 2.0)]:
		var t := build_grid.spawn_complete(tent_type, CAMP + off, Unit.Team.ENEMY) if tent_type else null
		if t:
			tents.append(t)
			t.destroyed.connect(_on_tent_down)


func _variant_start() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for id: StringName in DOORS:
		door_progress[id] = 0.0
		door_next[id] = 45.0
		risen[id] = []
	host_guards([["barrow_ghoul", 4], ["barrow_knight", 1]], DOORS[&"bd1"], 5.0)
	host_guards([["barrow_ghoul", 4], ["hexweaver", 2], ["barrow_knight", 1]], DOORS[&"bd2"], 6.0)
	host_guards([["barrow_ghoul", 6], ["barrow_knight", 2]], DOORS[&"bd3"], 7.0)
	var g4: Array = [["shade", 6], ["nightbolt", 3], ["shadow_knight", 2], ["hexweaver", 2], ["gloom_deacon", 1]]
	if flag_on("e3m3_stone_used") or flag_int("shadow_stone_uses", 0) > 0:   # C6-10: Ep3 writes the track counter
		g4.append(["shade", 2])
	host_guards(g4, GARRISON, 6.0)
	local_type("hush_boss").max_hp = float(HUSH_HP[diff])
	hush = make_unit("hush_boss")
	_spawn(hush, Unit.Team.ENEMY, GARRISON + Vector3(2.0, 0.0, -2.0))
	mark_scripted(hush)
	set_dormant(hush, true)
	_guard_hush()
	captain = make_unit("captain_story")
	_spawn(captain, Unit.Team.PLAYER, CAPTAIN_POS)
	mark_scripted(captain)
	captain.set_meta(META_HOME, CAPTAIN_POS)
	_guards.append(captain)
	kneel_guard(captain, 8.0)
	for id: StringName in DOORS:
		fog.reveal(Unit.Team.PLAYER, DOORS[id], 7.0)


func _initial_objectives() -> Array:
	return [&"obj_doors", &"obj_malrik", &"obj_keep", &"sec_shovel", &"sec_raids"]


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e8m1_shadow_home", _home_end)


func _home_end() -> void:
	for id in ["L1", "L2", "L3", "L4"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 10.0)
	_build_gift_panel()
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


## The Stone's Gift button (the intro's end, and again after a load: C6-3).
func _build_gift_panel() -> void:
	if hud == null or (_gift_panel != null and is_instance_valid(_gift_panel)):
		return
	_gift_panel = mission_button_panel("GiftPanel", [[Loc.t("The Stone's Gift (40 s)"), func() -> void:
			var r := use_gift()
			if r != "" and hud:
				hud.show_message(Loc.sink(r), 2.5)]])


# ---------------------------------------------------------------- objectives

func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_doors":
			if with_counter:
				return Loc.t("Lay the dead of Duskbarrow to rest ({n} / 3)", {"n": laid.size()})
			return "Lay the dead of Duskbarrow to rest"
		&"obj_hush":
			return "Break the Stair Gate and face Mother Hush"
		&"obj_stair":
			return "Carry the stone up the Gravedigger's Stair"
		&"obj_malrik":
			return "Malrik must survive"
		&"obj_keep":
			return "The Bishop's Keep must stand"
		&"sec_shovel":
			return "Put down the shovel: never use the stone's power"
		&"sec_raids":
			return "Burn the Stone-sworn camp"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_doors":
			var pos: Array = []
			for d: StringName in DOORS:
				if not laid.has(String(d)):
					pos.append(DOORS[d])
			return {"counter": laid.size(), "goal": 3, "positions": pos}
		&"obj_hush":
			return {"positions": [STAIR_GATE]}
		&"obj_stair":
			return {"positions": [EXIT]}
		&"sec_raids":
			return {"positions": [CAMP]}
	return {}


# ---------------------------------------------------------------- Barrow Doors (B.4)

func _tick_doors(dt: float) -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for id: StringName in DOORS:
		if laid.has(String(id)):
			continue
		var p: Vector3 = DOORS[id]
		if hero_alive() and _flat(hero.global_position, p) < 18.0 and fire_once(&"E2"):
			say_l("L5")
			say_l("L6")
		if id == &"bd3" and hero_alive() and _flat(hero.global_position, p) < 10.0 and fire_once(&"E5"):
			play_cutscene(&"e8m1_shadow_father", _father_end)
		# Risen
		var alive: Array = (risen[id] as Array).filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
		risen[id] = alive
		door_next[id] = float(door_next[id]) - dt
		if float(door_next[id]) <= 0.0:
			door_next[id] = float(by_difficulty(RISEN_EVERY))
			if alive.size() < RISEN_MAX:
				var rows: Array = [["barrow_ghoul", 3]]
				if mission_time() >= (540.0 if diff == 0 else 360.0):
					rows.append(["barrow_knight", 1])
				var out := host_guards(rows, p + Vector3(0.0, 0.0, 2.0), 2.0)
				for v: Variant in out:
					(v as Unit).set_meta(&"door", String(id))
					order_wave(v as Unit, &"risen", p)
				alive.append_array(out)
		# lay to rest
		var before := float(door_progress[id])
		var need := float(by_difficulty(LAY_TIME))
		if hero_alive() and _flat(hero.global_position, p) <= DOOR_R and foe_near(p, DOOR_CLEAR) != null:
			if hud and fire_once(StringName("clear_%s" % id)):
				hud.show_message(MSG_CLEAR, 3.0)
			door_progress[id] = 0.0
		else:
			door_progress[id] = channel_step(before, p, DOOR_R, need, dt)
		if float(door_progress[id]) >= need:
			_lay(id)


func _refresh_e7_mode(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	if mode != &"risen":
		return false
	var home: Vector3 = u.get_meta(META_TARGET, u.global_position)
	if u.attack_target == null and not u.is_attack_moving():
		var near := _player_near(home, 25.0)
		if near:
			u.command_attack(near)
		elif _flat(u.global_position, home) > 4.0:
			u.command_attack_move(home)
	return true


func _lay(id: StringName) -> void:
	laid.append(String(id))
	flash_ring(DOORS[id], 5.0)
	for v: Variant in risen[id]:
		if is_instance_valid(v) and (v as Unit).is_alive():
			(v as Unit).leave_map()
	risen[id] = []
	set_objective(&"obj_doors", "active")
	if id == &"bd3":
		fire_once(&"E6")
		say_l("L11")
	elif fire_once(&"E4"):
		say_l("L9")
	if id == &"bd2" and fire_once(&"E7"):
		say_l("L12")
		waves_fired.append("R3")
		host_wave([["shade", 6], ["nightbolt", 2], ["hexweaver", 1]], CAMP, [], hero_pos())
	if laid.size() >= 3:
		set_objective(&"obj_doors", "done")


func _father_end() -> void:
	say_l("L10")
	say_l("L10b")
	if hud:
		hud.show_message(HINT_OFFER, 6.0)


func _tick_ward() -> void:
	if laid.size() < 3 or stair == null or not stair.is_alive() or stair.is_open:
		return
	if mission_time() < WARD_FLOOR:
		if fire_once(&"msg_ward") and hud:
			hud.show_message(MSG_WARD, 5.0)
		return
	if fire_once(&"E8"):
		stair.open()
		flash_ring(STAIR_GATE, 8.0)
		set_objective(&"obj_hush", "active")


# ---------------------------------------------------------------- the Stone's Gift (B.4)

## Uses the stone: "" or why not.
func use_gift() -> String:
	if not hero_alive() or is_ending():
		return "Dead"
	if mission_time() < gift_ready_at:
		return MSG_GIFT_WAIT
	gift_ready_at = mission_time() + GIFT_COOLDOWN
	gift_until = mission_time() + 10.0
	stone_uses += 1
	add_track_counter("e8_stone_uses", 1)
	hero.add_modifier(&"mission:stone_gift", {"spell_power": 40.0})
	for i in 4:
		var g := make_unit("gift_ghoul")
		_spawn(g, Unit.Team.PLAYER, hero.global_position + Vector3(cos(i * 1.6) * 2.0, 0.0, sin(i * 1.6) * 2.0))
		mark_scripted(g)
		leave_later(g, 25.0)
	if stone_uses == 1:
		fire_once(&"E3")
		say_l("L7")
		set_objective(&"sec_shovel", "failed")
	elif stone_uses == 2:
		say_l("L8")
	return ""


# ---------------------------------------------------------------- Hush (B.4)

## Boss music (music.md 4, MissionBase._boss_fight_active): while Mother Hush fights (hush_state 1, her boss bar).
func _boss_fight_active() -> bool:
	return hush_state == 1 and _is_boss_up(hush)


func _tick_hush() -> void:
	if hush == null or not is_instance_valid(hush) or hush_state == 2:
		return
	if hush_state == 0:
		if stair != null and has_fired(&"E8") and (not stair.is_alive() or (hero_alive() and _flat(hero.global_position, STAIR_GATE) < 20.0)):
			hush_state = 1
			set_dormant(hush, false)
			_guard_hush()
			fire_once(&"E9")
			say_l("L13")
			say_l("L14")
			order_wave(hush, &"hero", hero_pos())
		return
	var r := hush.hp / maxf(1.0, hush.max_hp)
	if r <= 0.75 and hush_calls == 0 or r <= 0.5 and hush_calls == 1:
		hush_calls += 1
		host_wave([["shade", 4]], GARRISON, [], hero_pos())
	if r <= 0.5 and fire_once(&"E10"):
		say_l("L15")
		say_l("L16")
	if r <= 0.25:
		_hush_flees()


## Hush never dies: at 0 HP she stays at 1 and flees.
func _guard_hush() -> void:
	if hush == null or not is_instance_valid(hush):
		return
	hush.death_guard = func(_a: Variant) -> bool:
		hush.hp = 1.0
		_hush_flees()
		return true


func _hush_flees() -> void:
	if hush_state == 2:
		return
	hush_state = 2
	fire_once(&"E11")
	set_truce([hush], true, Unit.TRUCE_ALL)
	_wave_units.erase(hush)
	play_cutscene(&"e8m1_shadow_hush", _hush_end)


func _hush_end() -> void:
	say_l("L17")
	say_l("L18")
	if hush and is_instance_valid(hush):
		hush.queue_free()
	hush = null
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and _flat(u.global_position, GARRISON) < 30.0 \
				and String(u.unit_type.id).begins_with("sworn_"):
			u.leave_map()
	set_objective(&"obj_hush", "done")
	set_objective(&"obj_stair", "active")


func _on_stair_down(_g: WardenGate) -> void:
	if is_ending():
		return
	fire_once(&"E12")
	say_l("L19")
	say_l("L20")


func _on_tent_down(_b: Building) -> void:
	for t: Variant in tents:
		if is_instance_valid(t) and (t as Building).is_alive():
			return
	set_objective(&"sec_raids", "done")


func _tick_raids() -> void:
	if objective_state("sec_raids") == "done":
		return
	for row: Array in RAIDS:
		if mission_time() >= float(row[0]) and fire_once(StringName(row[1])):
			if String(row[1]) != "R1" and objective_state("sec_raids") == "done":
				continue
			waves_fired.append(String(row[1]))
			host_wave(row[2], CAMP, [], NODES[0][1] if String(row[1]) == "R1" else (HALL_POS if String(row[1]) == "R2" else KEEP_POS))


# ---------------------------------------------------------------- the end

func _tick_exit() -> void:
	if objective_state("obj_stair") != "active" or not hero_alive() or _flat(hero.global_position, EXIT) > EXIT_R:
		return
	if stair and stair.is_alive():
		if fire_once(&"msg_gate_stands") and hud:
			hud.show_message(MSG_GATE_STANDS, 3.0)
		return
	if not fire_once(&"E13"):
		return
	set_objective(&"obj_stair", "done")
	set_objective(&"obj_malrik", "done")
	set_objective(&"obj_keep", "done")
	if objective_state("sec_shovel") == "active":
		set_objective(&"sec_shovel", "done")
	if objective_state("sec_raids") == "active":
		set_objective(&"sec_raids", "failed")
	set_mission_flag("e8m1_shadow_stone_uses", stone_uses)
	finish_road()
	if _gift_panel and is_instance_valid(_gift_panel):
		_gift_panel.queue_free()
	play_cutscene(&"e8m1_shadow_stair", _stair_end)


func _stair_end() -> void:
	say_l("L21")
	say_l("L22")
	if stone_uses == 0:
		say_l("L24")
		say_l("L25")
	win(1.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E14")
	say_l("L23")
	super()


func _variant_tick(dt: float) -> void:
	_tick_doors(dt)
	_tick_ward()
	_tick_hush()
	_tick_raids()
	_tick_exit()
	tick_kneelers([captain])
	if gift_until > 0.0 and mission_time() >= gift_until and hero_alive():
		gift_until = 0.0
		hero.remove_modifier(&"mission:stone_gift")


## After a load: the Gift panel is back until the stair is climbed (C6-3); Hush in her fight keeps her flee guard (the
## load's wake gives her the guard she had before her sleep, none: C6-4).
func _after_load(nodes: Dictionary) -> void:
	super(nodes)
	if has_fired(&"E1") and not has_fired(&"E13") and not is_ending():
		_build_gift_panel()
	if hush_state == 1:
		_guard_hush()


func save_block_reason() -> String:
	if hush_state == 2 and objective_state("obj_hush") != "done" or has_fired(&"E13"):
		return SAVE_REASON_SCRIPTED
	return super()

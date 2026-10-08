class_name WaveStrikeLevel
extends "res://scripts/world/main.gd"
## Wave Strike (docs/design/wave-strike.md; M1): one lane, 1v1, persistent cards that spawn at a shared horn, units
## that march and fight on their own, a Bastion per team. Scene: scenes/wave_strike.tscn.
## Built on main.gd (the slim base: environment, navmesh, camera, selection, HUD) instead of LayoutLevel / Skirmish:
## the design's fallback (wave-strike.md 8 "Risks"), because Skirmish's workers, nodes, taverns, trade, map fill,
## tiers, respawn and "no living building" defeat would all have to be switched off. The map is still a MapLayout
## (World Forge `.map` -> `_layout.tres`): keep = Bastion, start = wizard start, slot sub=gate = spawn pad, path lane_a.
## Systems: WaveDirector (horn clock), WaveBank + MusterRoster + LaneSpawner per seat (1v1: seat = team), LaneMarch on
## every lane unit, WaveBot for the bot seat(s), WaveStrikeHud. Full vision (no fog). Win = the enemy Bastion falls;
## at rules.time_limit the higher Bastion HP % wins (within 1 %: more value killed).

## The match is over: 0 / 1 = the winning seat, -1 = a draw (same name as Skirmish.match_ended; the Playtest Recorder
## listens to it).
signal match_ended(winner_team: int)

const DEFAULT_LAYOUT := "res://data/maps/ashwind_reach_layout.tres"
const KINGDOMS := {
	&"fire": {"keep": "fire_keep", "wizard": "res://scripts/units/wizard.gd", "name": "Fire", "hero": "Vessa"},
	&"shadow": {"keep": "shadow_keep", "wizard": "res://scripts/units/shadow_wizard.gd", "name": "Shadow", "hero": "Malrik"},
	# balance pass 2026-10-06: Ice / Nature get 4 cards each (data/wave_strike/card_prices.tres) for the 4-kingdom batches
	&"ice": {"keep": "ice_keep", "wizard": "res://scripts/units/ice_wizard.gd", "name": "Ice", "hero": "Torvald",
			"color": Color(0.45, 0.72, 0.95)},
	&"nature": {"keep": "nature_keep", "wizard": "res://scripts/units/nature_wizard.gd", "name": "Nature", "hero": "Ysolde",
			"color": Color(0.38, 0.68, 0.24)},
}
const HUD_SCRIPT := "res://scripts/ui/wave_strike/wave_strike_hud.gd"
const BOT_SCRIPT := "res://scripts/ai/wave_bot.gd"
const SEATS := 2

@export var layout_path := DEFAULT_LAYOUT
@export var layout: MapLayout
@export var rules: WaveStrikeRules
## The player's kingdom (any key of KINGDOMS; the lobby offers all 4 since balance pass 2) and the bot's.
@export var player_kingdom: StringName = &"fire"
@export var enemy_kingdom: StringName = &"shadow"
## Bot personalities per seat (WaveBot.PERSONALITIES); "" = the default (seat 1: steward).
@export var personalities: Array[String] = ["hammer", "steward"]
## Labs / tests: a WaveBot plays the player's seat too (and its wizard guards on its own).
@export var autopilot_player := false
## Labs / tests: no wizards at all.
@export var wizards_enabled := true

var table: WaveCardTable
var director: WaveDirector
var banks: Array[WaveBank] = []
var rosters: Array[MusterRoster] = []
var spawners: Array[LaneSpawner] = []
var bots: Array[Node] = [null, null]
var bastions: Array[Bastion] = [null, null]
var wizards: Array[Wizard] = [null, null]
var ws_hud: Node
var lane: PackedVector3Array = PackedVector3Array()   ## team 0's walking order
var result := {}                 ## {winner, reason, time, ratios} once the match ended
var stats: Array[Dictionary] = [{}, {}]   ## per team: spawned, lost, value_killed, bounty
var ward_x := 0.0                ## the wizards' leash line (x of the lane's mirror line)

var _keep_pos: Array[Vector3] = [Vector3(-122, 0, 0), Vector3(122, 0, 0)]
var _start_pos: Array[Vector3] = [Vector3(-114, 0, -6), Vector3(114, 0, 6)]
var _gate_pos: Array[Vector3] = [Vector3(-108, 0, 0), Vector3(108, 0, 0)]
var _lane_types := {}            ## id -> commandable = false copy of the UnitType
var _respawn_left: Array[float] = [0.0, 0.0]
var _guard_t := 0.0
var _cast_t := 0.0


func _ready() -> void:
	if rules == null:
		rules = WaveStrikeRules.load_default()
	table = WaveCardTable.load_default()
	if layout == null:
		layout = LayoutLevel.load_layout(layout_path)
	if layout == null:
		push_error("WaveStrikeLevel: no layout (%s)" % layout_path)
		layout = MapLayout.new()
		layout.size_x = 280.0
		layout.size_z = 100.0
	for k in [player_kingdom, enemy_kingdom]:
		if not KINGDOMS.has(k):
			push_warning("WaveStrikeLevel: kingdom %s has no cards, using fire / shadow" % k)
			player_kingdom = &"fire"
			enemy_kingdom = &"shadow"
	_read_layout()
	for i in personalities.size():
		if personalities[i] == "":
			personalities[i] = "steward"
	stats = [_new_stats(), _new_stats()]
	LaneMarch.reset_counters()
	super()
	fog.enabled = false   # full vision (wave-strike.md Q6)


static func _new_stats() -> Dictionary:
	return {"spawned": 0, "lost": 0, "value_killed": 0, "value_lost": 0, "held": 0}


func _read_layout() -> void:
	for team in SEATS:
		var k := layout.keep_of(team)
		if not k.is_empty():
			_keep_pos[team] = k["pos"]
		var near_start := INF
		for s: Dictionary in layout.spots_of("start"):
			var d: float = (s["pos"] as Vector3).distance_to(_keep_pos[team])
			if d < near_start:
				near_start = d
				_start_pos[team] = s["pos"]
		var near_gate := INF
		for s: Dictionary in layout.spots_of("slot"):
			if String(s.get("sub", "")) != "gate":
				continue
			var d: float = (s["pos"] as Vector3).distance_to(_keep_pos[team])
			if d < near_gate:
				near_gate = d
				_gate_pos[team] = s["pos"]
	lane = layout.path("lane_a")
	if lane.size() < 2:
		lane = PackedVector3Array([_gate_pos[0], _gate_pos[1]])
	ward_x = (_keep_pos[0].x + _keep_pos[1].x) * 0.5


## The lane in `team`'s walking order.
func lane_for(team: int) -> PackedVector3Array:
	if team == 0:
		return lane
	var out := PackedVector3Array()
	for i in range(lane.size() - 1, -1, -1):
		out.append(lane[i])
	return out


func kingdom_of(team: int) -> StringName:
	return player_kingdom if team == Unit.Team.PLAYER else enemy_kingdom


func gate_position(team: int) -> Vector3:
	return _gate_pos[team]


func start_position(team: int) -> Vector3:
	return _start_pos[team]


# ---------------------------------------------------------------- main.gd hooks

func _map_size() -> Vector2:
	return Vector2(layout.size_x, layout.size_z)


func _map_id() -> StringName:
	return layout.id


func _player_start() -> Vector3:
	return _start_pos[0]


func _lane_end() -> Vector3:
	return _start_pos[1]


func _use_map_dressing() -> bool:
	return false


func _ground_spots() -> Array[Vector4]:
	return [Vector4(_keep_pos[0].x, _keep_pos[0].z, 15.0, 1.0), Vector4(_keep_pos[1].x, _keep_pos[1].z, 15.0, 1.0),
			Vector4(ward_x, 0.0, 9.0, 0.0)]


func _objective_text() -> String:
	return "Wave Strike: %s\nDestroy the enemy Bastion. Every card you buy marches at each horn." % \
			(layout.title if layout.title != "" else "Ashwind Reach")


func _build_map() -> void:
	for b: Dictionary in layout.blocks:
		_add_ws_block(b)
	for team in SEATS:
		var type := BuildingType.find(String(KINGDOMS[kingdom_of(team)]["keep"]))
		var bas := Bastion.new()
		bas.building_type = type
		bas.name = "Bastion%d" % team
		bas.team = team as Unit.Team
		bas.team_color = KINGDOMS[kingdom_of(team)].get("color",
				FIRE_COLOR if kingdom_of(team) == &"fire" else SHADOW_COLOR)
		bas.front_toward = _gate_pos[team]
		bas.position = _keep_pos[team]
		nav_region.add_child(bas)
		bas.setup_bastion(rules)
		bas.destroyed.connect(_on_bastion_destroyed)
		bastions[team] = bas
	keep = bastions[0]


## A layout block: its collider (layer 1, before the bake); forest blocks are drawn as trees, rock / cliff ones as rocks.
func _add_ws_block(b: Dictionary) -> void:
	var shape := BoxShape3D.new()
	var hb: Vector3 = b["half"]
	var h := float(b.get("height", 3.0))
	shape.size = Vector3(hb.x * 2.0, h, hb.z * 2.0)
	var body := _static_obstacle(b["center"], shape, h * 0.5)
	body.name = "Block_%s" % String(b["id"]).validate_node_name()
	body.rotation.y = deg_to_rad(float(b.get("yaw", 0.0)))
	body.add_to_group(&"map_blocks")
	if _SIM.enabled:
		return
	var c: Vector3 = b["center"]
	var kind := String(b.get("kind", "rock"))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(b["id"]))
	if env_props == null:
		var box := BoxMesh.new()
		box.size = shape.size
		_mesh(body, box, Color(0.16, 0.3, 0.15) if kind == "forest" else Color(0.46, 0.44, 0.42), h * 0.5)
		return
	if kind == "forest":
		var step := 4.6
		var nx := int(hb.x * 2.0 / step)
		var nz := int(hb.z * 2.0 / step)
		for ix in nx + 1:
			for iz in nz + 1:
				var p := c + Vector3(-hb.x + ix * step + rng.randf_range(-1.6, 1.6), 0.0,
						-hb.z + iz * step + rng.randf_range(-1.6, 1.6))
				if absf(p.x) > MapInfo.half_x() - 1.0 or absf(p.z) > MapInfo.half_z() - 1.0:
					continue
				env_props.add_tree(p, rng.randf_range(0.9, 1.5))
		# rocks along the lane edge
		for i in int(hb.x / 6.0):
			var edge_z := c.z - hb.z if c.z > 0.0 else c.z + hb.z
			env_props.add_rock(Vector3(c.x - hb.x + rng.randf() * hb.x * 2.0, 0.0, edge_z), rng.randf_range(0.8, 1.8), rng.randf() * TAU)
	else:
		var n := maxi(2, int(hb.x * hb.z / 6.0))
		for i in n:
			var p := c + Vector3(rng.randf_range(-hb.x, hb.x) * 0.8, 0.0, rng.randf_range(-hb.z, hb.z) * 0.8)
			env_props.add_rock(p, rng.randf_range(1.2, 2.6) * (1.3 if kind == "cliff" else 1.0), rng.randf() * TAU)


func _on_navigation_ready() -> void:
	director = WaveDirector.new()
	director.setup(rules, self)
	add_child(director)
	for team in SEATS:
		var bank := WaveBank.new()
		bank.setup(team, team, rules, Economy.for_team(team))
		add_child(bank)
		var roster := MusterRoster.new()
		roster.setup(team, team, kingdom_of(team), rules, table, bank, director)
		add_child(roster)
		var sp := LaneSpawner.new()
		var path := lane_for(team)
		sp.setup(team, team, _gate_pos[team], path[1] - path[0], self, rules)
		add_child(sp)
		banks.append(bank)
		rosters.append(roster)
		spawners.append(sp)
		director.add_seat(bank, roster, sp)
	# wizards (the player's is the HUD's hero; main.gd's HUD needs one)
	for team in SEATS:
		if not wizards_enabled and team != 0:
			continue
		var wiz := _make_wizard(team)
		_spawn(wiz, team as Unit.Team, _start_pos[team])
		wizards[team] = wiz
		wiz.died.connect(_on_wizard_died.bind(team))
		_apply_wizard_rule(wiz, team)
		if team == 0 and not autopilot_player:
			wiz.remove_from_group(&"enemy_heroes")
			wiz.add_to_group(&"heroes")
			if &"ai_auto_cast" in wiz:
				wiz.set(&"ai_auto_cast", false)
		else:
			wiz.remove_from_group(&"heroes")
			wiz.add_to_group(&"enemy_heroes")
		ItemDrops.ensure_inventory(wiz)
	hero = wizards[0]
	if not wizards_enabled:
		hero.visible = false
		hero.process_mode = Node.PROCESS_MODE_DISABLED
		hero.global_position = _keep_pos[0] + Vector3(-8, 0, 0)
	# bots
	if ResourceLoader.exists(BOT_SCRIPT):
		var bot_script := load(BOT_SCRIPT) as GDScript
		for team in SEATS:
			if team == 0 and not autopilot_player:
				continue
			var bot: Node = bot_script.new()
			bot.name = "WaveBot%d" % team
			add_child(bot)
			bot.call(&"setup", team, rosters[team], banks[team], director,
					personalities[team] if team < personalities.size() else "steward")
			bots[team] = bot
	_setup_hud()
	if ResourceLoader.exists(HUD_SCRIPT):
		ws_hud = (load(HUD_SCRIPT) as GDScript).new()
		ws_hud.name = "WaveStrikeHud"
		add_child(ws_hud)
		ws_hud.call(&"setup", self, 0)
	camera_rig.focus_on(_start_pos[0] + Vector3(14.0, 0.0, 0.0))
	hud.show_message("Buy cards (Z X C V): they march at every horn. First horn at 0:30.", 8.0)
	director.running = true
	# Playtest Recorder (health-and-playtests.md): Wave Strike is not a Skirmish, so it starts the recorder itself
	# when Settings "Playtest data" is on (bot-vs-bot labs run with autopilot_player and never record).
	if _REPLAY.playtest_enabled and not autopilot_player:
		_REPLAY.start_playtest(self, "wave_strike")


func _make_wizard(team: int) -> Wizard:
	var path := String(KINGDOMS[kingdom_of(team)]["wizard"])
	var wiz: Wizard = null
	if ResourceLoader.exists(path):
		var script := load(path) as GDScript
		if script and script.can_instantiate():
			wiz = script.new() as Wizard
	if wiz == null:
		wiz = ShadowWizard.new() if kingdom_of(team) == &"shadow" else Wizard.new()
	return wiz


## The mode's wizard re-rule (rules.wizard_spell_power, balance pass 2): a flat spell_power modifier per kingdom.
func _apply_wizard_rule(wiz: Wizard, team: int) -> void:
	var k := kingdom_of(team)
	var mods: Dictionary = {}
	var sp := float(rules.wizard_spell_power.get(k, rules.wizard_spell_power.get(String(k), 0.0)))
	if sp != 0.0:
		mods["spell_power"] = sp
	var extra: Variant = rules.wizard_stats.get(k, rules.wizard_stats.get(String(k), {}))
	if extra is Dictionary:
		for s in extra:
			mods[String(s)] = float(extra[s])
	if not mods.is_empty():
		wiz.add_modifier(&"ws_rule", mods)
		wiz.hp = wiz.max_hp


# ---------------------------------------------------------------- lane units

## A lane unit of card `id` for `seat` at `pos` (LaneSpawner calls it): not commandable (inspect only), marching.
func spawn_lane_unit(seat: int, id: StringName, pos: Vector3, lateral: float) -> Unit:
	if game_over:
		return null
	var type := _lane_type(id)
	if type == null:
		return null
	var team := seat   # 1v1: seat = team
	if rules.field_cap > 0 and field_count(team) >= rules.field_cap:
		stats[team]["held"] = int(stats[team].get("held", 0)) + 1   # the field valve: this copy stays home this horn
		return null
	var u := Worker.make_unit(type)
	_spawn(u, team as Unit.Team, pos)
	u.set_meta(&"ws_card", id)
	u.set_meta(&"ws_seat", seat)
	# card rank (wave-strike.md 4.4): level 2 / 3 + the "+" (and Elite) modifier
	var rk := rosters[seat].rank(id) if seat < rosters.size() else 1
	if rk >= 2:
		u.add_xp(Unit.VETERANCY_XP[rk - 1])
		u.add_modifier(&"ws_rank", {"max_hp_pct": 0.1 * (rk - 1), "attack_damage_pct": 0.1 * (rk - 1),
			"armor": 1.0 if rk >= 3 else 0.0})
		u.hp = u.max_hp
	var leash := rules.leash_ranged if type.attack_range > 3.0 else rules.leash_melee
	var phase := float(stats[team]["spawned"] % 4) * LaneMarch.TICK * 0.25
	LaneMarch.attach(u, lane_for(team), lateral, leash, bastions[1 - team], phase)
	u.died.connect(_on_lane_unit_died.bind(seat, id))
	stats[team]["spawned"] += 1
	return u


func _lane_type(id: StringName) -> UnitType:
	if _lane_types.has(id):
		return _lane_types[id]
	var base := UnitType.find(String(id))
	if base == null:
		return null
	var t := base.duplicate() as UnitType
	t.commandable = false   # wave-strike.md 4.4: lane units are never ordered (selecting one = inspect)
	_lane_types[id] = t
	return t


## Kill bounty (wave-strike.md 4.2): rules.bounty_pct of the card price to the killing team, x defender mult when the
## kill is in that team's own third of the lane.
func _on_lane_unit_died(u: Unit, seat: int, id: StringName) -> void:
	var team := seat
	var price := table.price(id)
	stats[team]["lost"] += 1
	stats[team]["value_lost"] += price
	var k: Node3D = u.killer if is_instance_valid(u.killer) else null
	if k == null or not (&"team" in k):
		return
	var kt := int(k.get(&"team"))
	if kt == team or kt < 0 or kt >= SEATS:
		return
	stats[kt]["value_killed"] += price
	var mult := rules.defender_bounty_mult if lane_progress(u.global_position, kt) < 1.0 / 3.0 else 1.0
	if kt < banks.size():
		banks[kt].add_bounty(int(roundf(price * rules.bounty_pct * mult)))


## How far `pos` is along the lane from `team`'s gate (0) to the enemy gate (1).
func lane_progress(pos: Vector3, team: int) -> float:
	var a := _gate_pos[team]
	var b := _gate_pos[1 - team]
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var t := Vector2(pos.x - a.x, pos.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.001)
	return clampf(t, 0.0, 1.0)


func bastion_ratio(team: int) -> float:
	var b := bastions[team]
	if b == null or not is_instance_valid(b):
		return 0.0
	return b.hp_ratio() if b.is_alive() else 0.0


## Living lane units of `team` (O(1): spawned - lost; the field valve reads it at every spawn).
func field_count(team: int) -> int:
	return int(stats[team]["spawned"]) - int(stats[team]["lost"])


## Living lane units of `team` (perf / tests).
func lane_units(team: int = -1) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and u.has_node(^"LaneMarch") and (team < 0 or int(u.team) == team):
			out.append(u)
	return out


# ---------------------------------------------------------------- horns, wizards, the end

func on_horn(index: int) -> void:
	if director.is_last_horns():   # Last Horns (wave-strike.md 4.9): Bastion armour -25 %
		for b in bastions:
			if b and is_instance_valid(b):
				b.armor = rules.bastion_armor * (1.0 - rules.last_horns_armor_cut)
	for team in SEATS:
		var w := wizards[team]
		if w and is_instance_valid(w) and w.is_alive() and rules.wizard_horn_xp > 0:
			w.add_xp(rules.wizard_horn_xp)
		if w and is_instance_valid(w) and (team != 0 or autopilot_player):
			_bot_learn_spells(w)
	if index == 1 and hud:
		hud.show_message("Horn! Your cards march.", 2.5)


## A bot-run wizard spends its spell points (F / Q / E in turn, lowest rank first).
func _bot_learn_spells(w: Wizard) -> void:
	var guard := 0
	while w.spell_points > 0 and guard < 12:
		guard += 1
		var best: StringName = &""
		var best_rank := 99
		for id: StringName in w.default_spell_ids:
			if w.can_learn(id) == "" and w.spell_rank(id) < best_rank:
				best_rank = w.spell_rank(id)
				best = id
		if best == &"" or w.learn_spell(best) != "":
			break


func _physics_process(delta: float) -> void:
	if game_over or director == null:
		return
	_leash_wizards()
	_tick_respawns(delta)
	_guard_t -= delta
	if _guard_t <= 0.0:
		_guard_t = 1.0
		_guard_bot_wizards()
	_cast_t -= delta
	if _cast_t <= 0.0:
		_cast_t = 0.5
		_cast_for_bot_wizards()
	if rules.time_limit > 0.0 and director.time >= rules.time_limit:
		_end_on_time()


## The Ward Line (wave-strike.md 4.8): a wizard never crosses the lane's mirror line.
func _leash_wizards() -> void:
	for team in SEATS:
		var w := wizards[team]
		if w == null or not is_instance_valid(w) or not w.is_alive():
			continue
		var limit := ward_x - 1.0 if team == 0 else ward_x + 1.0
		var over := w.global_position.x > limit if team == 0 else w.global_position.x < limit
		if over:
			w.global_position.x = limit
			if w.has_move_order() or w.attack_target != null:
				w.command_stop()


## Bot wizards (and the player's on autopilot) stand guard 24 m in front of their gate, auto-aggro on.
func _guard_bot_wizards() -> void:
	for team in SEATS:
		if team == 0 and not autopilot_player:
			continue
		var w := wizards[team]
		if w == null or not is_instance_valid(w) or not w.is_alive():
			continue
		var path := lane_for(team)
		var fwd := (path[1] - path[0]).normalized()
		var post := _gate_pos[team] + fwd * 24.0
		if w.attack_target == null and not w.has_move_order() and w.global_position.distance_to(post) > 6.0:
			w.command_attack_move(post)


## Bot-run wizards that do not cast by themselves (balance pass 2026-10-06): the wizard scripts' own AI loop runs only
## for team != PLAYER and only Malrik / Torvald / Ysolde have one, so Vessa (any seat) and the autopilot seat 0 never
## cast. That made every lab batch seat-biased (east won 68 % of 72 games) and the Fire bot wizard spell-less.
## Here they cast what their SpellCaster suggests (spells.md bot rules), every 0.5 s like the wizards' own loops.
func _cast_for_bot_wizards() -> void:
	for team in SEATS:
		if team == 0 and not autopilot_player:
			continue   # the player casts
		var w := wizards[team]
		if w == null or not is_instance_valid(w) or not w.is_alive():
			continue
		if &"ai_auto_cast" in w and bool(w.get(&"ai_auto_cast")) and int(w.team) != Unit.Team.PLAYER:
			continue   # its own loop casts
		var sc: Node = w.spell_caster
		if sc == null or not sc.has_method(&"suggest_cast"):
			continue
		var s: Dictionary = {}
		if AICasts.is_vessa(w):
			# Vessa has no suggest_cast() rules: the skirmish Commander's AICasts.suggest_vessa (no engage dive: leash)
			var foes: Array[Unit] = []
			var allies: Array[Unit] = []
			for n in get_tree().get_nodes_in_group(&"units"):
				var u := n as Unit
				if u == null or u == w or not u.is_alive() \
						or u.global_position.distance_to(w.global_position) > AICasts.VESSA_WATCH:
					continue
				if int(u.team) == team:
					if not u is Wizard:
						allies.append(u)
				elif int(u.team) == 1 - team:
					foes.append(u)
			if foes.is_empty():
				continue
			s = AICasts.suggest_vessa(w, foes, allies, _start_pos[team], false)
		else:
			s = sc.call(&"suggest_cast")
		if s.is_empty():
			continue
		# like the wizards' own loops (_ai_cast_with_caster): a "retreat" rule also walks the wizard home. Without it the
		# autopilot seat 0 never retreated and its Malrik / Torvald / Ysolde died more (balance pass 2: east won 61 %).
		if w.command_cast(StringName(str(s.get("spell_id", ""))), s.get("target")) == "" and bool(s.get("retreat", false)):
			w.command_move(w.home_position())


func _on_wizard_died(_u: Unit, team: int) -> void:
	var w := wizards[team]
	_respawn_left[team] = rules.wizard_respawn_base + rules.wizard_respawn_per_level * (w.level if w else 1)
	if team == 0 and hud:
		hud.show_message("%s has fallen: back in %d s" % [KINGDOMS[kingdom_of(0)]["hero"], ceili(_respawn_left[0])], 3.0)


func _tick_respawns(delta: float) -> void:
	for team in SEATS:
		if _respawn_left[team] <= 0.0:
			continue
		_respawn_left[team] -= delta
		if _respawn_left[team] <= 0.0:
			_respawn_left[team] = 0.0
			var w := wizards[team]
			if w and is_instance_valid(w) and not w.is_alive() and w.has_method(&"respawn"):
				w.respawn(_start_pos[team])
				w.visible = true


func respawn_time_left(team: int) -> float:
	return _respawn_left[team]


func _on_bastion_destroyed(b: Building) -> void:
	_finish(1 - int(b.team), "bastion")


func _end_on_time() -> void:
	var r0 := bastion_ratio(0)
	var r1 := bastion_ratio(1)
	var winner := -1
	if absf(r0 - r1) > 0.01:
		winner = 0 if r0 > r1 else 1
	elif int(stats[0]["value_killed"]) != int(stats[1]["value_killed"]):
		winner = 0 if int(stats[0]["value_killed"]) > int(stats[1]["value_killed"]) else 1
	_finish(winner, "time")


func _finish(winner: int, reason: String) -> void:
	if game_over:
		return
	result = {"winner": winner, "reason": reason, "time": director.time if director else 0.0,
		"horns": director.horn_index if director else 0, "ratios": [bastion_ratio(0), bastion_ratio(1)]}
	if director:
		director.running = false
	game_over = true
	# The Playtest Recorder reads match_ended first (winner -1 = a time-limit draw -> outcome "draw", review
	# 2026-10-08 L3); mission_ended(false) right after no longer overwrites it.
	match_ended.emit(winner)
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.mission_ended.emit(winner == 0)
	var m := int(result["time"]) / 60
	var s := int(result["time"]) % 60
	var how := "Bastion destroyed" if reason == "bastion" else "time: Bastion HP %d %% vs %d %%" % [
		roundi(bastion_ratio(0) * 100.0), roundi(bastion_ratio(1) * 100.0)]
	if winner == 0:
		hud.show_banner("VICTORY\n%s (%d:%02d)" % [how, m, s], Color(1.0, 0.85, 0.3))
	elif winner == 1:
		hud.show_banner("DEFEAT\n%s (%d:%02d)" % [how, m, s], Color(0.9, 0.3, 0.3))
	else:
		hud.show_banner("DRAW\n%s" % how, Color(0.85, 0.85, 0.85))


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

## Director clock, banks, rosters, stats, wizard respawn timers (SaveWorld). Lane units are saved as units.
func save_level_state(_ids: Dictionary) -> Dictionary:
	var b: Array = []
	for bank in banks:
		b.append(bank.save_state())
	var r: Array = []
	for roster in rosters:
		r.append(roster.save_state())
	return {
		"time": director.time if director else 0.0,
		"horn_index": director.horn_index if director else 0,
		"last_wave_size": director.last_wave_size.duplicate() if director else [],
		"banks": b, "rosters": r, "stats": stats.duplicate(true), "respawn": _respawn_left.duplicate(),
	}


func load_level_state(d: Dictionary, _nodes: Dictionary) -> void:
	if director:
		director.time = float(d.get("time", director.time))
		director.horn_index = int(d.get("horn_index", director.horn_index))
		director.last_wave_size.assign(d.get("last_wave_size", []))
	var b: Array = d.get("banks", [])
	for i in mini(b.size(), banks.size()):
		banks[i].load_state(b[i])
	var r: Array = d.get("rosters", [])
	for i in mini(r.size(), rosters.size()):
		rosters[i].load_state(r[i])
	stats.assign((d.get("stats", stats) as Array).duplicate(true))
	_respawn_left.assign(d.get("respawn", [0.0, 0.0]))


## A saved lane unit comes back marching on its lane at its waypoint (SaveWorld asks the level first). Null = not a
## lane unit (the generic path builds it).
func save_spawn_unit(row: Dictionary) -> Unit:
	var metas: Dictionary = row.get("metas", {})
	if not metas.has("ws_card"):
		return null
	var seat := int(metas.get("ws_seat", row.get("team", 0)))
	var u := spawn_lane_unit(seat, StringName(str(metas["ws_card"])), row.get("pos", Vector3.ZERO),
			float(row.get("lane_lateral", 0.0)))
	if u:
		var march := u.get_node_or_null(^"LaneMarch")
		if march and row.has("lane_index"):
			march.set(&"index", int(row["lane_index"]))
	return u

extends SceneTree
## Regression checks for the world / economy findings of docs/reviews/review-2026-10-08.md (scenes/main.tscn):
## - M1 BuildGrid: an ALLY (2v2) unit in the footprint no longer blocks placement and is pushed out; an enemy still blocks;
## - M2 BuildingGun: a held target that turns non-hostile (seat switch) is dropped;
## - L1 UnitUpgrades "+" and Stables16 rank 3 reach a unit that joins the tree without a TrainingBuilding;
## - L2 Building.relation_color: own green, ally blue, enemy red;
## - L3 WaveStrikeLevel has match_ended (the recorder's draw path);
## - L4 Caravan loss lines: a pending line of the old level is dropped in a new one;
## - L5 AllyChannel reads Alt+clicks in _unhandled_input, not _input;
## - L6 Keep.tier_card_text still lists the unlocks;
## - L7 ForgeKit spot back-off after a failed search (a failure "in the future" = new match, ignored).
## Run:  godot --headless --path . -s tests/test_review_world.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "review_world"
const PLAYER := 0
const ENEMY := 1
const ALLY := 3

var main: Node
var _errors: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _physics(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while main.get(&"hero") == null:
		await process_frame
		if Time.get_ticks_msec() - t0 > 120000:
			_ok(false, "the map never got ready")
			_finish()
			return
	await _frames(5)
	await _check_build_grid()
	await _check_gun()
	await _check_upgrades()
	_check_colors()
	_check_static_bits()
	await _check_caravan()
	await _check_ally_channel()
	Teams.reset()
	_finish()


func _finish() -> void:
	Teams.reset()
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _checks])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit(0 if _errors.is_empty() else 1)


func _unit(id: StringName, team: int, pos: Vector3) -> Unit:
	var u: Unit = UnitType.find(String(id)).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	return u


# ---------------------------------------------------------------- M1

func _check_build_grid() -> void:
	var grid: BuildGrid = main.get(&"build_grid")
	var keep: Keep = main.get(&"keep")
	var type := BuildingType.find(&"fire_hearth")
	Economy.for_team(PLAYER).add(5000)
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var spot := grid.find_spot(type, keep.global_position + dir * 12.0, PLAYER)
	_ok(spot != Vector3.INF, "a free hearth spot near the keep")
	if spot == Vector3.INF:
		return
	Teams.configure({PLAYER: 0, ALLY: 0, ENEMY: 1})
	var ally := _unit(&"flame_guard", ALLY, spot)
	await _physics(1)
	ally.global_position = spot
	_ok(grid.check(type, spot, PLAYER) == "", "an allied unit on the spot does not block (%s)" % grid.check(type, spot, PLAYER))
	var foe := _unit(&"shade", ENEMY, spot)
	await _physics(1)
	foe.global_position = spot
	_ok(grid.check(type, spot, PLAYER) == BuildGrid.MSG_BLOCKED, "an enemy unit on the spot still blocks")
	foe.queue_free()
	await _physics(2)
	ally.global_position = spot
	var serial := ally.order_serial
	var site := grid.place(type, spot, PLAYER, [])
	_ok(site != null, "place() accepts the spot with the ally on it (%s)" % grid.last_reason)
	_ok(ally.order_serial > serial, "the allied unit is pushed out of the footprint")
	if site:
		site.queue_free()
	ally.queue_free()
	Teams.reset()
	await _physics(2)


# ---------------------------------------------------------------- M2

func _check_gun() -> void:
	var keep: Keep = main.get(&"keep")
	_ok(BuildingGun.can_shoot(keep.building_type), "the keep shoots")
	var foe := _unit(&"shadow_knight", ENEMY, keep.global_position + Vector3(4.0, 0.0, 4.0))
	foe.max_hp = 100000.0
	foe.hp = 100000.0
	await _physics(1)
	var gun := BuildingGun.new(keep, 3.0)
	for i in 60:
		gun.tick(0.05)
		if gun.target == foe:
			break
	_ok(gun.target == foe, "the gun picks the enemy unit")
	Teams.configure({PLAYER: 0, ENEMY: 0})   # the seat switches side: now an ally
	gun.tick(0.01)
	_ok(gun.target == null, "the held target is dropped once it is no longer hostile")
	Teams.reset()
	foe.queue_free()
	await _physics(2)


# ---------------------------------------------------------------- L1

func _check_upgrades() -> void:
	var keep: Keep = main.get(&"keep")
	var bank := UnitUpgrades.for_team(PLAYER)
	_ok(bank != null, "UnitUpgrades node for the player")
	if bank:
		bank.grant(&"flame_guard")
	var stables := Stables16.for_team(PLAYER)
	var rank_id: StringName = Stables16.rank_ids(&"fire")[0] if not Stables16.rank_ids(&"fire").is_empty() else &""
	if stables and rank_id != &"":
		stables.researched.append(rank_id)
	var fg := _unit(&"flame_guard", PLAYER, keep.global_position + Vector3(6.0, 0.0, 0.0))
	var other := _unit(&"flame_guard", ENEMY, keep.global_position + Vector3(-30.0, 0.0, 0.0))
	var rider: Unit = null
	if rank_id != &"":
		rider = _unit(rank_id, PLAYER, keep.global_position + Vector3(7.0, 0.0, 1.0))
	await _frames(2)
	_ok(fg.has_modifier(UnitUpgrades.MODIFIER) and bool(fg.get_meta(&"plus", false)),
			"a spawned (not trained) Flame Guard gets the team's \"+\"")
	_ok(not other.has_modifier(UnitUpgrades.MODIFIER), "the other team's Flame Guard does not")
	_ok(rank_id != &"" and rider != null and rider.has_modifier(Stables16.RANK_MODIFIER)
			and int(rider.get_meta(&"rank", 0)) == Stables16.RANK, "a spawned %s gets the Stables rank 3" % rank_id)
	fg.queue_free()
	other.queue_free()
	if rider:
		rider.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- L2

func _check_colors() -> void:
	Teams.configure({PLAYER: 0, ALLY: 0, ENEMY: 1})
	_ok(Building.relation_color(PLAYER, false) == Unit.team_color(PLAYER), "own building ring green")
	_ok(Building.relation_color(ALLY, false) == Unit.team_color(ALLY), "ally building ring ally blue (not red)")
	_ok(Building.relation_color(ALLY, true) == Unit.team_hp_color(ALLY), "ally building HP bar ally blue")
	_ok(Building.relation_color(ENEMY, false) == Unit.team_color(ENEMY), "enemy building ring red")
	_ok(Building.relation_color(ENEMY, true) == Unit.team_hp_color(ENEMY), "enemy building HP bar red")
	Teams.reset()
	_ok(Building.relation_color(ENEMY, false) == Unit.team_color(ENEMY), "1v1 enemy ring red")


# ---------------------------------------------------------------- L3 / L6 / L7

func _check_static_bits() -> void:
	var ws := load("res://scripts/world/wave_strike/wave_strike_level.gd") as Script
	var has_sig := false
	for s: Dictionary in ws.get_script_signal_list():
		if str(s.get("name", "")) == "match_ended":
			has_sig = true
	_ok(has_sig, "WaveStrikeLevel has match_ended (draw -> recorder outcome \"draw\")")
	var keep: Keep = main.get(&"keep")
	var txt := keep.tier_card_text(2)
	_ok(txt.begins_with("Upgrade the keep") and txt.contains("Opens:"), "tier card text still lists the unlocks")
	ForgeKit._bot_spot_failed[ENEMY] = 100.0
	_ok(ForgeKit.spot_backing_off(ENEMY, 120.0), "Forge bot backs off 20 s after a failed search")
	_ok(not ForgeKit.spot_backing_off(ENEMY, 100.0 + ForgeKit.BOT_SPOT_BACKOFF + 1.0), "back-off ends after BOT_SPOT_BACKOFF")
	_ok(not ForgeKit.spot_backing_off(ENEMY, 10.0), "a failure from an older match (clock restarted) is ignored")
	ForgeKit._bot_spot_failed.erase(ENEMY)


# ---------------------------------------------------------------- L4

func _check_caravan() -> void:
	Caravan._notify_summed(&"robbed", PLAYER, 5)
	Caravan._notify_summed(&"robbed", PLAYER, 7)   # within 10 s: held and summed
	var key := "robbed:%d" % PLAYER
	_ok(Caravan._msg_pending.has(key), "a second robbery within 10 s is held (summed)")
	var fresh := Node3D.new()
	root.add_child(fresh)
	current_scene = fresh   # F9 / a new skirmish
	Caravan._flush_summed(key, &"robbed")
	_ok(Caravan._msg_pending.is_empty() and Caravan._msg_last.is_empty(), "the held line of the old level is dropped")
	current_scene = main
	fresh.queue_free()
	await _frames(1)


# ---------------------------------------------------------------- L5

func _check_ally_channel() -> void:
	var ch := AllyChannel.instance(self, main)
	await _frames(1)
	_ok(ch != null and ch.is_processing_unhandled_input() and not ch.is_processing_input(),
			"AllyChannel reads clicks in _unhandled_input (HUD / minimap get them first)")
	if ch:
		ch.queue_free()

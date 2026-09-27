extends SceneTree
## Task 10.C9 (docs/design/market-trade.md 9 / 12 / 14, "Done when" 10.C9): the trade building models and
## their hooks. Checks:
## - the 4 `data/buildings/*_market.tres` name their Bazaar model in `model_scene` (and `model_path`); a
##   Bazaar of each kingdom shows that model, which answers `play_delivery()` (Ember: the scale tilts, Gloom:
##   the delivery plays);
## - Market: `play_delivery()` on its model once per delivery of one of ITS caravans: without a network on
##   the caravan's own `delivered`, with a network on `TradeNetwork.delivered` only (never both); another
##   Bazaar's caravan does nothing; TradeVfx `ware_bought` on its own GoldBank's `ware_bought` (a real
##   buy_ware), not on the enemy's; the GoldBank may appear after the Bazaar;
## - TradePost: `play_trade()` once when a caravan finishes trading there (cargo set while `trading` with
##   route_post = the post), not for another post, not while returning, not while the post is closed;
## - GuildHouse: the Den links ThievesGuild.band_sent when it opens (the guild made after the house); a band
##   Magpie leaving the map at its door plays `play_band_out()` (once per 1.5 s), one far away does not; the
##   Lodge's `play_contract()` raises the real model's horn flag;
## - LootSack: the art bobs itself, so the sack's own bob is off (Visual stays at y 0);
## - end to end: a real caravan from a Bazaar (spy model) to a TradePost (spy art) 22+ m away trades
##   (post `play_trade`) and delivers (Bazaar `play_delivery` through the network), once each.
## Stubs: the TradeNetwork (group "trade_network", `delivered` + `record_delivery`), the ThievesGuild (group
## "thieves_guild", `band_sent`, `bands()`), a band (`thieves`), stub caravans for the post checks and spy
## models / a spy TradeVfx that count calls. The GoldBank is the real one (load-guarded).
## Run:  godot --headless --path . -s tests/test_10_c9.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "10.C9"
const TIMEOUT_FRAMES := 3400
const SETUP_FRAME := 5
const P := 0
const E := 1
const N := 2
const KINGDOMS := ["fire", "shadow", "ice", "nature"]
const GOLD_BANK_PATH := "res://scripts/economy/gold_bank.gd"
const POST_PATH := "res://scripts/world/trade_post.gd"
const HOUSE_PATH := "res://scripts/world/guild_house.gd"
const SACK_PATH := "res://scripts/world/loot_sack.gd"

const SPY_SRC := """extends Node3D
var calls := {}
func _hit(m: String) -> void:
	calls[m] = int(calls.get(m, 0)) + 1
func count(m: String) -> int:
	return int(calls.get(m, 0))
func play_delivery() -> void:
	_hit("play_delivery")
func play_trade() -> void:
	_hit("play_trade")
func play_band_out() -> void:
	_hit("play_band_out")
func play_contract() -> void:
	_hit("play_contract")
"""
const VFX_SPY_SRC := """extends Node3D
var plays: Array = []
func play(id: StringName, at: Variant, target: Variant = null) -> void:
	plays.append([id, at, target])
"""
const NET_SRC := """extends Node
signal delivered(team: int, caravan: Node, amount: int, post: Node)
func record_delivery(team: int, amount: int, post: Node, caravan: Node) -> void:
	delivered.emit(team, caravan, amount, post)
"""
const GUILD_SRC := """extends Node
signal band_sent(band: Node)
var list: Array = []
func bands() -> Array:
	return list
"""
const BAND_SRC := """extends Node
var thieves: Array = []
"""
const CARAVAN_SRC := """extends Node3D
signal cargo_changed(caravan: Node, amount: int)
var team := 0
var trade_state: StringName = &"idle"
var route_post: Node3D = null
var home_market: Node3D = null
"""

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _log: Array[String] = []
var _step := 0
var _next := 0

var grid: BuildGrid
var free_type: BuildingType
var spy_script: GDScript
var real_markets: Array = []
var market: Market
var market_spy: Node3D
var post: Node3D
var post_spy: Node3D
var other_post: Node3D
var den: Node3D
var den_spy: Node3D
var lodge: Node3D
var sack: Node3D
var guild: Node
var band: Node
var magpies: Array = []
var net: Node
var bank0: Node
var bank1: Node
var real_vfx: Node
var vfx_spy: Node3D
var stub_a: Node3D
var stub_b: Node3D
var caravan: Node
var _loop_seen := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == SETUP_FRAME:
		_setup()
		_next = frame + 30
	elif frame > SETUP_FRAME and _errors.is_empty() and frame >= _next:
		_run_step()
	if not _errors.is_empty() or _step < 0:
		return _finish()
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out at step %d (post trades %d, deliveries %d, caravan %s)" % [_step,
				_count(post_spy, "play_trade"), _count(market_spy, "play_delivery"), _caravan_state()])
		return _finish()
	return false


# ---------------------------------------------------------------- setup

func _setup() -> void:
	grid = main.build_grid
	main.economy.crystals = 5000
	spy_script = _script(SPY_SRC)
	free_type = (BuildingType.find("fire_market")).duplicate() as BuildingType
	free_type.requires_kind = &""
	free_type.max_keep_distance = 0.0
	free_type.max_count = 0
	free_type.cost = 1   # is_buildable needs a cost
	if main.get_tree().get_first_node_in_group(&"trade_network") != null \
			or main.get_tree().get_first_node_in_group(&"gold_banks") != null:
		_errors.append("main.tscn already has a TradeNetwork / GoldBank: the no-network checks need none")
		return
	_check_data()
	if not _errors.is_empty():
		return
	_make_real_markets()
	_make_spy_market()
	_make_posts()
	_make_houses()
	_make_sack()
	# Banks after the Bazaar: the Bazaar must find them later (1 Hz link).
	if not ResourceLoader.exists(GOLD_BANK_PATH):
		_errors.append("no gold_bank.gd")
		return
	var bank_script: Script = load(GOLD_BANK_PATH)
	bank0 = bank_script.call(&"create", main, P)
	bank1 = bank_script.call(&"create", main, E)
	# The spy TradeVfx replaces the real one in the group.
	real_vfx = main.get_tree().get_first_node_in_group(&"trade_vfx")
	if real_vfx == null or not real_vfx.has_method(&"active_ids"):
		_errors.append("main.tscn has no TradeVfx")
		return
	real_vfx.remove_from_group(&"trade_vfx")
	vfx_spy = _script(VFX_SPY_SRC).new() as Node3D
	vfx_spy.name = "VfxSpy"
	main.add_child(vfx_spy)
	vfx_spy.add_to_group(&"trade_vfx")


## The 4 .tres: model_scene = the kingdom's Bazaar model (model_path too), a root with play_delivery().
func _check_data() -> void:
	for k: String in KINGDOMS:
		var path := "res://art/buildings/market/%s/market_%s.tscn" % [k, k]
		var t := BuildingType.find(StringName(k + "_market"))
		if t == null:
			_errors.append("%s_market.tres missing" % k)
			continue
		if t.model_scene == null or t.model_scene.resource_path != path:
			_errors.append("%s_market model_scene = %s, want %s" % [k,
					t.model_scene.resource_path if t.model_scene else "null", path])
		if t.model_path != path:
			_errors.append("%s_market model_path = %s" % [k, t.model_path])
		if t.get_model_scene() != t.model_scene:
			_errors.append("%s_market get_model_scene is not model_scene" % k)


## One completed Bazaar of each kingdom (team PLAYER, freed after the model checks).
func _make_real_markets() -> void:
	var anchor := Vector3(-48.0, 0.0, -8.0)
	for k: String in KINGDOMS:
		var t := BuildingType.find(StringName(k + "_market"))
		var s := grid.find_spot(free_type, anchor, P, 14)
		if s == Vector3.INF:
			_errors.append("no spot for the %s Bazaar" % k)
			return
		var b := grid.spawn_complete(t, s, P) as Market
		if b == null or not b.is_constructed():
			_errors.append("%s Bazaar is not a completed Market" % k)
			return
		var m := b.model()
		var want := "res://art/buildings/market/%s/market_%s.tscn" % [k, k]
		if m == null or m.scene_file_path != want:
			_errors.append("%s Bazaar model %s, want %s" % [k, m.scene_file_path if m else "null (placeholder)", want])
			return
		if not m.has_method(&"play_delivery"):
			_errors.append("%s Bazaar model has no play_delivery" % k)
			return
		b.play_delivery()
		real_markets.append(b)
	var shadow_model := (real_markets[1] as Market).model()
	if shadow_model.has_method(&"is_delivery_playing") and not bool(shadow_model.call(&"is_delivery_playing")):
		_errors.append("Gloom Bazaar: play_delivery did not start the delivery")


## The Bazaar under test: team PLAYER, its model swapped for a spy that counts the hook calls.
func _make_spy_market() -> void:
	var s := grid.find_spot(free_type, Vector3(-28.0, 0.0, 48.0), P, 10)
	if s == Vector3.INF:
		_errors.append("no spot for the spy Bazaar")
		return
	market = grid.spawn_complete(BuildingType.find("fire_market"), s, P) as Market
	grid.request_rebake()
	market_spy = spy_script.new() as Node3D
	market_spy.name = "ModelSpy"
	market.add_child(market_spy)
	market.set(&"_model", market_spy)
	if market.model() != market_spy:
		_errors.append("could not install the Bazaar spy model")
	_log.append("spy Bazaar at %s" % market.global_position)


## The post 22+ m in front of the spy Bazaar (door facing it), and a second post elsewhere.
func _make_posts() -> void:
	if market == null:
		return
	var target := market.global_position + Vector3(0.0, 0.0, -27.0)
	var s := grid.find_spot(free_type, target, P, 4)
	if s == Vector3.INF:
		_errors.append("no spot for the post near %s" % target)
		return
	var script: Script = load(POST_PATH)
	post = script.new() as Node3D
	post.set(&"post_id", &"test_post")
	post.name = "TestPost"
	var d := market.global_position - s
	post.rotation.y = atan2(d.x, d.z)   # local +Z (the door) toward the Bazaar
	main.add_child(post)
	post.global_position = s
	var real_art := post.call(&"model") as Node3D
	if real_art == null or real_art.scene_file_path != "res://art/buildings/trade_post/trade_post.tscn" \
			or not real_art.has_method(&"play_trade"):
		_errors.append("TradePost art %s has no play_trade" % [real_art.scene_file_path if real_art else "null"])
		return
	post_spy = spy_script.new() as Node3D
	post_spy.name = "ArtSpy"
	post.add_child(post_spy)
	post.set(&"_art", post_spy)
	post.call(&"set_open", true)
	var door: Vector3 = post.call(&"door_point")
	_log.append("post at %s, door %s, %.1f m from the Bazaar" % [s, door, _flat(door, market.global_position)])
	if market.set_route(post) != "":
		_errors.append("set_route(post): '%s'" % market.set_route(post))
	other_post = script.new() as Node3D
	other_post.set(&"post_id", &"other_post")
	other_post.name = "OtherPost"
	main.add_child(other_post)
	other_post.global_position = Vector3(-10.0, 0.0, 10.0)
	other_post.call(&"set_open", true)
	# Stub caravans: A trades at the post, B at the other post (both since now, so the posts' polls see them).
	stub_a = _stub_caravan(post, &"trading")
	stub_b = _stub_caravan(other_post, &"trading")


func _make_houses() -> void:
	var script: Script = load(HOUSE_PATH)
	den = script.new() as Node3D
	den.set(&"kind", &"den")
	den.name = "TestDen"
	main.add_child(den)
	den.global_position = Vector3(-52.0, 0.0, 18.0)
	var art := den.call(&"model") as Node3D
	if art == null or art.scene_file_path != "res://art/buildings/guilds/magpie_den/magpie_den.tscn":
		_errors.append("Den art %s" % [art.scene_file_path if art else "null"])
	den_spy = spy_script.new() as Node3D
	den_spy.name = "ArtSpy"
	den.add_child(den_spy)
	den.set(&"_art", den_spy)
	lodge = script.new() as Node3D
	lodge.set(&"kind", &"lodge")
	lodge.name = "TestLodge"
	main.add_child(lodge)
	lodge.global_position = Vector3(-8.0, 0.0, 54.0)
	var la := lodge.call(&"model") as Node3D
	if la == null or not la.has_method(&"is_contract_flag_up"):
		_errors.append("Lodge art %s has no is_contract_flag_up" % [la.scene_file_path if la else "null"])
		return
	lodge.call(&"set_open", true)
	lodge.call(&"play_contract")


func _make_sack() -> void:
	var script: Script = load(SACK_PATH)
	sack = script.call(&"spawn", main, Vector3(-54.0, 0.0, -30.0), 30)
	if sack == null:
		_errors.append("LootSack.spawn returned null")


# ---------------------------------------------------------------- steps

func _run_step() -> void:
	match _step:
		0:
			_step_models()
			_step_post_stubs()
			_step_den_link()
			_step_spawn_caravan()
			_next = frame + 100
		1:
			_step_wares()   # the 4 test Bazaars are gone now: only the spy Bazaar is the player's
			_step_no_network_delivery()
			_step_den_gap()
			net = _script(NET_SRC).new()
			net.name = "NetStub"
			net.add_to_group(&"trade_network")
			main.add_child(net)
			_next = frame + 75
		2:
			_step_network_delivery()
			_next = frame + 1
		3:
			# End to end: wait for the real caravan's natural trade (post) and delivery (Bazaar).
			if _count(post_spy, "play_trade") >= 2 and _count(market_spy, "play_delivery") >= 3:
				_log.append("caravan loop done at frame %d" % frame)
				_next = frame + 30
			else:
				return
		4:
			if _count(post_spy, "play_trade") != 2:
				_errors.append("post play_trade %d after the real trade, want 2" % _count(post_spy, "play_trade"))
			if _count(market_spy, "play_delivery") != 3:
				_errors.append("Bazaar play_delivery %d after the real delivery, want 3" % _count(market_spy,
						"play_delivery"))
			_step = -1
			return
	_step += 1


## Real models: the Ember scale tilts, the Lodge flag is up; then the 4 test Bazaars go. The sack's own bob
## is off (the art bobs).
func _step_models() -> void:
	var fire_model := (real_markets[0] as Market).model()
	if fire_model.has_method(&"get_scale_tilt") and is_zero_approx(float(fire_model.call(&"get_scale_tilt"))):
		_errors.append("Ember Bazaar: play_delivery did not tip the scale")
	for b: Market in real_markets:
		b.queue_free()
	real_markets.clear()
	var la := lodge.call(&"model") as Node3D
	if not bool(la.call(&"is_contract_flag_up")):
		_errors.append("Lodge: play_contract did not raise the horn flag")
	if sack == null or not is_instance_valid(sack):
		_errors.append("the loot sack is gone")
		return
	var art := sack.find_child("Art", true, false)
	if art == null or not art.has_method(&"bobs_itself"):
		_errors.append("loot sack art missing")
	var visual := sack.get_node_or_null("Visual") as Node3D
	if sack.is_processing() or visual == null or not is_zero_approx(visual.position.y):
		_errors.append("loot sack still bobs itself (processing %s, y %.3f)" % [sack.is_processing(),
				visual.position.y if visual else -1.0])


## TradePost: play_trade once when a caravan trading at it takes its cargo.
func _step_post_stubs() -> void:
	stub_a.emit_signal(&"cargo_changed", stub_a, 28)
	if _count(post_spy, "play_trade") != 1:
		_errors.append("post play_trade %d after a trade, want 1" % _count(post_spy, "play_trade"))
	stub_a.emit_signal(&"cargo_changed", stub_a, 0)
	stub_a.set(&"trade_state", &"returning")
	stub_a.emit_signal(&"cargo_changed", stub_a, 28)
	stub_b.emit_signal(&"cargo_changed", stub_b, 28)   # traded at the other post
	if _count(post_spy, "play_trade") != 1:
		_errors.append("post play_trade %d after cargo 0 / returning / another post, want 1" % _count(post_spy,
				"play_trade"))
	# A closed post stops listening.
	other_post.call(&"set_open", false)
	stub_a.set(&"trade_state", &"idle")
	stub_b.set(&"trade_state", &"idle")


## Den: the ThievesGuild (made after the Den) is linked when the Den opens; a band Magpie leaving at the
## door plays play_band_out, a far one does not, a second one at once does not (gap).
func _step_den_link() -> void:
	guild = _script(GUILD_SRC).new()
	guild.name = "ThievesGuildStub"
	guild.add_to_group(&"thieves_guild")
	main.add_child(guild)
	den.call(&"set_open", true)
	var type: UnitType = load("res://data/units/magpie.tres")
	var door: Vector3 = den.call(&"door_point")
	for ofs: Vector3 in [Vector3(1.0, 0, 0.5), Vector3(-1.0, 0, 0.8), Vector3(20.0, 0, 6.0), Vector3(0.5, 0, 1.5)]:
		var m := Worker.make_unit(type)
		m.team = Unit.Team.NEUTRAL
		main.add_child(m)
		m.global_position = door + ofs
		m.command_stop()
		magpies.append(m)
	band = _script(BAND_SRC).new()
	band.name = "BandStub"
	band.set(&"thieves", magpies.duplicate())
	guild.add_child(band)
	guild.emit_signal(&"band_sent", band)
	magpies[2].leave_map()   # 20 m away
	if _count(den_spy, "play_band_out") != 0:
		_errors.append("a Magpie leaving 20 m from the Den door swung it")
	magpies[0].leave_map()
	magpies[1].leave_map()
	if _count(den_spy, "play_band_out") != 1:
		_errors.append("Den play_band_out %d after two Magpies went home, want 1" % _count(den_spy, "play_band_out"))


## Wares: a real buy_ware of the player's bank -> one ware_bought pulse on the player's Bazaar; the enemy's
## bank -> nothing on it. Then the real TradeVfx plays it.
func _step_wares() -> void:
	bank0.call(&"add", 1000, &"trade")
	var reason := String(bank0.call(&"buy_ware", &"iron_axles"))
	if reason != "":
		_errors.append("buy_ware(iron_axles): '%s'" % reason)
		return
	var plays: Array = vfx_spy.get(&"plays")
	if plays.size() != 1:
		_errors.append("ware_bought plays %d, want 1: %s" % [plays.size(), plays])
		return
	var p: Array = plays[0]
	if p[0] != &"ware_bought" or p[2] != market or not (p[1] as Vector3).is_equal_approx(market.global_position):
		_errors.append("ware_bought play %s" % [p])
	bank1.emit_signal(&"ware_bought", &"iron_axles")
	if (vfx_spy.get(&"plays") as Array).size() != 1:
		_errors.append("the enemy's ware_bought pulsed the player's Bazaar")
	vfx_spy.remove_from_group(&"trade_vfx")
	real_vfx.add_to_group(&"trade_vfx")
	bank0.call(&"add", 1000, &"trade")
	reason = String(bank0.call(&"buy_ware", &"gambesons"))
	if reason != "" or not (real_vfx.call(&"active_ids") as Array).has(&"ware_bought"):
		_errors.append("real TradeVfx: ware_bought not playing (buy '%s', active %s)" % [reason,
				real_vfx.call(&"active_ids")])


## A real caravan of the spy Bazaar, trading on its route (the post).
func _step_spawn_caravan() -> void:
	var type: UnitType = load("res://data/units/caravan.tres")
	# The training path: a trained caravan knows its route at once and is watched (no network yet).
	var trained: Array = []
	market.unit_trained.connect(func(u: Unit) -> void: trained.append(u))
	market.call(&"_spawn", type)
	if trained.size() != 1:
		_errors.append("Market._spawn trained %d units" % trained.size())
		return
	var t: Unit = trained[0]
	if t.get(&"route_post") != post or t.get(&"home_market") != market \
			or not t.is_connected(&"delivered", Callable(market, &"_on_caravan_delivered")):
		_errors.append("trained caravan: route_post %s, home %s, watched %s" % [t.get(&"route_post"),
				t.get(&"home_market"), t.is_connected(&"delivered", Callable(market, &"_on_caravan_delivered"))])
	t.queue_free()
	caravan = Worker.make_unit(type)
	caravan.team = Unit.Team.PLAYER
	caravan.set(&"home_market", market)
	main.add_child(caravan)
	caravan.global_position = market.spawn_point()
	caravan.command_stop()
	var r := String(caravan.call(&"command_trade", market))
	if r != "":
		_errors.append("caravan command_trade(Bazaar): '%s'" % r)


## No network: the Bazaar heard its caravan's own `delivered` (linked by the 1 Hz tick).
func _step_no_network_delivery() -> void:
	if not caravan.is_connected(&"delivered", Callable(market, &"_on_caravan_delivered")):
		_errors.append("the Bazaar does not listen to its caravan without a network")
	caravan.emit_signal(&"delivered", caravan, 20)
	if _count(market_spy, "play_delivery") != 1:
		_errors.append("Bazaar play_delivery %d after a delivery (no network), want 1" % _count(market_spy,
				"play_delivery"))
	if _count(post_spy, "play_trade") != 1:
		_errors.append("post play_trade %d before the real trade, want 1" % _count(post_spy, "play_trade"))


func _step_den_gap() -> void:
	magpies[3].leave_map()   # > 1.5 s after the first one
	if _count(den_spy, "play_band_out") != 2:
		_errors.append("Den play_band_out %d after a later Magpie went home, want 2" % _count(den_spy,
				"play_band_out"))
	den.call(&"play_band_out")
	if _count(den_spy, "play_band_out") != 3:
		_errors.append("GuildHouse.play_band_out does not reach the model")


## With a network: TradeNetwork.delivered only (the caravan's own signal is ignored), own caravans only.
func _step_network_delivery() -> void:
	net.emit_signal(&"delivered", P, caravan, 28, post)
	if _count(market_spy, "play_delivery") != 2:
		_errors.append("Bazaar play_delivery %d after TradeNetwork.delivered, want 2" % _count(market_spy,
				"play_delivery"))
	caravan.emit_signal(&"delivered", caravan, 28)
	var stranger := _stub_caravan(post, &"idle")
	stranger.set(&"home_market", post)
	net.emit_signal(&"delivered", P, stranger, 28, post)
	if _count(market_spy, "play_delivery") != 2:
		_errors.append("Bazaar play_delivery %d: doubled with the network or another Bazaar's caravan" % _count(
				market_spy, "play_delivery"))
	stranger.queue_free()
	_log.append("caravan now %s" % _caravan_state())


# ---------------------------------------------------------------- helpers

func _script(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	var err := s.reload()
	if err != OK:
		_errors.append("stub script failed to compile (%d)" % err)
	return s


func _stub_caravan(at_post: Node3D, state: StringName) -> Node3D:
	var c := _script(CARAVAN_SRC).new() as Node3D
	c.name = "StubCaravan"
	c.set(&"trade_state", state)
	c.set(&"route_post", at_post)
	c.add_to_group(&"caravans")
	main.add_child(c)
	return c


func _count(spy: Node, method: String) -> int:
	if spy == null or not is_instance_valid(spy):
		return -1
	return int(spy.call(&"count", method))


func _caravan_state() -> String:
	if caravan == null or not is_instance_valid(caravan):
		return "gone"
	return "%s cargo %d at %s" % [caravan.get(&"trade_state"), int(caravan.get(&"cargo")),
			(caravan as Node3D).global_position]


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _finish() -> bool:
	for line in _log:
		print("  ", line)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	return true

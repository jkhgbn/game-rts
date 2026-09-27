class_name TradePopups
extends Node3D
## The trade listener (step 10, task 10.C8; spec: market-trade.md 8, layout: docs/design/ui-trade.md 12-14.5): one node
## in the level, group "trade_popups", made by `TradePopups.attach(hud)` (GameHUD._setup_trade).
## It owns, for the local player (team 0):
## - the floating texts: `+28` over the own Bazaar on a delivery, `+60` over a picked-up loot sack, `-119` over a
##   visible own caravan that was robbed (Label3D, a pool of 8: a 9th replaces the oldest);
## - the trade messages that no other system sends: `Magpies raid your miners at <node>!` (max once per 30 s),
##   `Picked up a loot sack: 60 gold`, `Bought <ware>`. The other lines of ui-trade.md 13 are sent by their owners
##   and never repeated here: posts open + Bazaar hint (skirmish, 10.C1), robbed / destroyed / held (Caravan, 10.C3),
##   `The Magpies are on the roads` (ThievesGuild), contracts hired and the Lodge reward (HuntersGuild), exchanges
##   (TradeWindow), `Not enough gold` (TopBar);
## - the sounds (bus SFX, 2D): coin clink (own delivery / sack, max 1 per 0.3 s), two-note whistle (a band strikes a
##   visible own caravan or own workers, max 1 per 5 s), horn (own contract started, max 1 per 2 s).
## Sources are found untyped and connected guarded (has_signal), retried every 0.5 s while missing: TradeNetwork
## (`delivered`, `caravan_robbed`, `workers_raided`, `loot_picked`), HuntersGuild (`contract_started`), the player's
## GoldBank (`ware_bought`). Without a network `loot_picked`, each LootSack's `picked` is used instead (2 Hz scan).

const GROUP := &"trade_popups"
const PLAYER_TEAM := 0
const POOL_SIZE := 8
const RISE := 1.5                 ## Metres a text rises over its life.
const LIFE := 1.0
const FADE := 0.4                 ## The last 0.4 s fade out.
const FONT_SIZE := 40
const PIXEL_SIZE := 0.006
const OUTLINE := 8
const TEXT_GOLD := Color(1.0, 0.85, 0.3)
const TEXT_WARN := Color(0.95, 0.35, 0.3)
const BAZAAR_OFFSET := Vector3(0.0, 5.3, 0.0)
const SACK_OFFSET := Vector3(0.0, 1.2, 0.0)
const CARAVAN_EXTRA := 1.1        ## Above the caravan's body_height.
const SCAN_TIME := 0.5
const RAID_MSG_INTERVAL := 30.0
const SOUNDS := {
	&"coin": {"path": "res://assets/audio/trade_coin.wav", "interval": 0.3, "db": -6.0},
	&"whistle": {"path": "res://assets/audio/trade_whistle.wav", "interval": 5.0, "db": 0.0},
	&"horn": {"path": "res://assets/audio/trade_horn.wav", "interval": 2.0, "db": 0.0},
}

var hud: Node
## Read only (tests): every message this node sent, and how many times each sound played.
var messages: Array[String] = []
var sound_counts := {&"coin": 0, &"whistle": 0, &"horn": 0}

var _labels: Array[Label3D] = []
var _ages: Array[float] = []      # per pool label: seconds since it started (-1 = free)
var _starts: Array[Vector3] = []
var _players := {}                # sound id -> AudioStreamPlayer
var _last_sound := {}             # sound id -> _clock of the last play
var _clock := 0.0
var _scan_left := 0.0
var _last_raid_msg := -1.0e9


## Adds the listener to the HUD's level once (a second call returns the same node).
static func attach(p_hud: Node) -> TradePopups:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		for n in tree.get_nodes_in_group(GROUP):
			if n is TradePopups and not n.is_queued_for_deletion():
				(n as TradePopups).hud = p_hud
				return n
	var p := TradePopups.new()
	p.name = "TradePopups"
	p.hud = p_hud
	var level: Node = p_hud.get_parent() if p_hud != null else null
	if level == null and tree != null:
		level = tree.current_scene
	if level != null:
		level.add_child(p)
	return p


func _init() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	for i in POOL_SIZE:
		var l := Label3D.new()
		l.font_size = FONT_SIZE
		l.pixel_size = PIXEL_SIZE
		l.outline_size = OUTLINE
		l.outline_modulate = Color.BLACK
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		l.visible = false
		add_child(l)
		_labels.append(l)
		_ages.append(-1.0)
		_starts.append(Vector3.ZERO)
	for id: StringName in SOUNDS:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		p.volume_db = float((SOUNDS[id] as Dictionary)["db"])
		var path := str((SOUNDS[id] as Dictionary)["path"])
		if ResourceLoader.exists(path):
			p.stream = load(path) as AudioStream
		add_child(p)
		_players[id] = p
	_scan()


func _process(delta: float) -> void:
	_clock += delta
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = SCAN_TIME
		_scan()
	for i in _labels.size():
		if _ages[i] < 0.0:
			continue
		_ages[i] += delta
		var t := _ages[i]
		var l := _labels[i]
		if t >= LIFE:
			_ages[i] = -1.0
			l.visible = false
			continue
		var k := t / LIFE
		var ease_out := 1.0 - (1.0 - k) * (1.0 - k)
		l.global_position = _starts[i] + Vector3(0.0, RISE * ease_out, 0.0)
		var a := clampf((LIFE - t) / FADE, 0.0, 1.0)
		l.modulate.a = a
		l.outline_modulate.a = a


# ---------------------------------------------------------------- sources

## Connects the sources that exist now (network, hunters' guild, the player's bank; sacks without a network signal).
func _scan() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var net := TradeWindow.trade_network_of(tree)
	if net != null:
		_hook(net, &"delivered", _on_delivered)
		_hook(net, &"caravan_robbed", _on_caravan_robbed)
		_hook(net, &"workers_raided", _on_workers_raided)
		_hook(net, &"loot_picked", _on_loot_picked)
	var guild := TradeWindow.hunters_guild_of(tree)
	if guild != null:
		_hook(guild, &"contract_started", _on_contract_started)
	var bank := TradeWindow.gold_bank_of(tree, PLAYER_TEAM)
	if bank != null:
		_hook(bank, &"ware_bought", _on_ware_bought)
	if net == null or not net.has_signal(&"loot_picked"):
		for sack in tree.get_nodes_in_group(&"loot_sacks"):   # 2 Hz, with the scan
			_hook(sack, &"picked", _on_sack_picked)


func _hook(obj: Object, sig: StringName, callback: Callable) -> void:
	if obj == null or not is_instance_valid(obj) or not obj.has_signal(sig) or obj.is_connected(sig, callback):
		return
	obj.connect(sig, callback)


# ---------------------------------------------------------------- handlers

## TradeNetwork.delivered: `+amount` over the own Bazaar + the coin clink.
func _on_delivered(team: int, caravan: Node, amount: int, _post: Node) -> void:
	if team != PLAYER_TEAM or amount <= 0:
		return
	var market: Node3D = null
	if caravan != null and is_instance_valid(caravan):
		var home: Variant = caravan.get(&"home_market")
		if is_instance_valid(home) and home is Node3D:
			market = home as Node3D
	if market == null:
		market = TradeWindow.market_of(get_tree(), PLAYER_TEAM)
	var at: Vector3
	if market != null:
		at = market.global_position + BAZAAR_OFFSET
	elif caravan is Node3D:
		at = (caravan as Node3D).global_position + Vector3(0.0, 2.5, 0.0)
	else:
		return
	popup("+" + TradeWindow.thousands(amount), at, TEXT_GOLD)
	play_sound(&"coin")


## TradeNetwork.caravan_robbed: `-amount` over a visible own caravan + the whistle. The message is the caravan's.
func _on_caravan_robbed(team: int, caravan: Node, amount: int, _thief: Node) -> void:
	if team != PLAYER_TEAM or caravan == null or not is_instance_valid(caravan) or not (caravan is Node3D):
		return
	var c := caravan as Node3D
	if not c.is_visible_in_tree():
		return
	var h: Variant = c.get(&"body_height")
	var height := float(h) if h != null else 1.2
	if amount > 0:
		popup("-" + TradeWindow.thousands(amount), c.global_position + Vector3(0.0, height + CARAVAN_EXTRA, 0.0),
				TEXT_WARN)
	play_sound(&"whistle")


## TradeNetwork.workers_raided: the message (max once per 30 s) + the whistle when the node is visible.
func _on_workers_raided(team: int, node: Node) -> void:
	if team != PLAYER_TEAM:
		return
	if _clock - _last_raid_msg >= RAID_MSG_INTERVAL:
		_last_raid_msg = _clock
		say("Magpies raid your miners at %s!" % node_name(node), 4.0)
	if node == null or not is_instance_valid(node) or not (node is Node3D) or (node as Node3D).is_visible_in_tree():
		play_sound(&"whistle")


## TradeNetwork.loot_picked (or LootSack.picked): `+amount` over the sack, the message, the clink.
func _on_loot_picked(team: int, amount: int, sack: Node) -> void:
	if team != PLAYER_TEAM or amount <= 0:
		return
	if sack != null and is_instance_valid(sack) and sack is Node3D:
		popup("+" + TradeWindow.thousands(amount), (sack as Node3D).global_position + SACK_OFFSET, TEXT_GOLD)
	say("Picked up a loot sack: %d gold" % amount, 2.0)
	play_sound(&"coin")


func _on_sack_picked(sack: Node, team: int, amount: int) -> void:
	_on_loot_picked(team, amount, sack)


## HuntersGuild.contract_started: the horn (the guild sends the message itself).
func _on_contract_started(team: int, _kind: StringName, _contract: Node) -> void:
	if team == PLAYER_TEAM:
		play_sound(&"horn")


## GoldBank.ware_bought (the player's bank): `Bought Masons' Charter`.
func _on_ware_bought(id: StringName) -> void:
	var info: Dictionary = TradeWindow.WARE_INFO.get(StringName(id), {})
	say("Bought %s" % str(info.get("name", String(id).capitalize())), 2.0)


## `the natural node` / `the rich node`: the node's display_name when it has one, else by its distance to the
## player's keep (the nearer remote node is the natural one).
func node_name(node: Node) -> String:
	if node != null and is_instance_valid(node):
		var dn: Variant = node.get(&"display_name")
		if dn != null and str(dn) != "":
			return str(dn)
		if node is Node3D:
			var keep := Keep.nearest(PLAYER_TEAM, (node as Node3D).global_position) if is_inside_tree() else null
			if keep != null:
				var d := keep.global_position.distance_to((node as Node3D).global_position)
				return "the natural node" if d < 45.0 else "the rich node"
	return "a remote node"


# ---------------------------------------------------------------- output

## Shows `text` on the HUD message line (and records it for tests).
func say(text: String, seconds: float) -> void:
	messages.append(text)
	if hud != null and is_instance_valid(hud) and hud.has_method(&"show_message"):
		hud.call(&"show_message", text, seconds)


## Starts a floating text at `at` (world): rises 1.5 m over 1 s, fades over the last 0.4 s. Uses a free pool label,
## else the oldest one. Returns the label.
func popup(text: String, at: Vector3, color: Color) -> Label3D:
	var best := 0
	var best_age := -2.0
	for i in _labels.size():
		if _ages[i] < 0.0:
			best = i
			break
		if _ages[i] > best_age:
			best_age = _ages[i]
			best = i
	var l := _labels[best]
	_ages[best] = 0.0
	_starts[best] = at
	l.text = text
	l.modulate = color
	l.outline_modulate = Color.BLACK
	l.visible = true
	l.global_position = at
	return l


## Floating texts in flight.
func active_count() -> int:
	var n := 0
	for a in _ages:
		if a >= 0.0:
			n += 1
	return n


## The texts in flight (tests).
func active_texts() -> PackedStringArray:
	var out: PackedStringArray = []
	for i in _labels.size():
		if _ages[i] >= 0.0:
			out.append(_labels[i].text)
	return out


func pool_size() -> int:
	return _labels.size()


## Plays a trade sound unless it played within its rate limit. True if it played.
func play_sound(id: StringName) -> bool:
	if not SOUNDS.has(id):
		return false
	var interval := float((SOUNDS[id] as Dictionary)["interval"])
	if _clock - float(_last_sound.get(id, -1.0e9)) < interval:
		return false
	_last_sound[id] = _clock
	sound_counts[id] = int(sound_counts.get(id, 0)) + 1
	var p: AudioStreamPlayer = _players.get(id)
	if p != null and p.stream != null and p.is_inside_tree():
		p.play()
	return true


## The player of a sound (tests: bus, stream).
func player_of(id: StringName) -> AudioStreamPlayer:
	return _players.get(id)

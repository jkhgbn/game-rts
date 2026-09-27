class_name ChampionBarks
extends Node
## Champion barks (champions.md 4.5, ui-champions.md 10) and the bounty flags' stake labels (ui-champions.md 8).
## One per scene (group "champion_barks"): the SelectionManager creates it, so no scene wiring is needed.
## Polls at 4 Hz (barks) / 2 Hz (labels): no per-frame cost.
## Barks: one Label3D line above the champion (y = body_height + 1.1, 0.6 m over its HP bar) for 3 s (fade over the
## last 0.5 s, pop 0.8 -> 1.0 in 0.1 s, then freed): white font 32, 2 px black outline, pixel_size 0.006, width 560,
## centred, growing upward. At most one per champion per 20 s; only while the champion is visible to the local team.
## Triggers (chances from ChampionType.BARK_CHANCES): hired 100 % (the champion appears), takes a bounty 30 % (its
## intent turns to a bounty one or changes flag), flees 50 % (intent `fleeing`), level up 100 %, buys an item 20 %
## (`Inventory.item_bought`). A champion that emits its own `bark_requested(trigger)` signal is followed instead.
## Lines: `champion_type.bark_for(trigger)`, else the 4.5 table below.
## Stake labels: every flag (group "bounties") shows its stake in gold (`Label3D` "Stake" made by bounty.gd, or a
## "StakeLabel" added here when a flag has none): `150`, Guard / Escort `150 · 1:20`, Hunt with the target lost
## `150 · 42 s` in WARN. Own flags always; enemy flags follow the flag's fog visibility.
## Messages (joins, fallen, bounty paid / refunded, hunt warnings, tithe) come from the guild, the board and the
## inventory themselves (ui-champions.md 11), not from here.

signal barked(champion: Node3D, trigger: StringName, text: String)

const GROUP := &"champion_barks"
const TRIGGERS: Array[StringName] = [&"hired", &"bounty", &"flee", &"level_up", &"buy"]
const CHANCES := {&"hired": 1.0, &"bounty": 0.3, &"flee": 0.5, &"level_up": 1.0, &"buy": 0.2}
## champions.md 4.5 (used when the ChampionType has no line for the trigger).
const FALLBACK_LINES := {
	&"wayfinder": {
		&"hired": "Maps are just rumours with lines. Let's draw some.",
		&"bounty": "A coin for a corner? I know a corner.",
		&"flee": "Nope. Mapping the way home!",
		&"level_up": "I've seen more. I am more.",
		&"buy": "New boots. Same blank map.",
	},
	&"oathwall": {
		&"hired": "Point me at a wall. I'll stand in front of it.",
		&"bounty": "Nobody touches this door. Nobody.",
		&"flee": "Tactical... leaning backwards!",
		&"level_up": "Heavier. Good.",
		&"buy": "Thicker is better.",
	},
	&"coin_cutter": {
		&"hired": "Pay me and I'll love you. Briefly.",
		&"bounty": "Now THAT is a pretty number.",
		&"flee": "Nothing's worth dying for. Except more coin. Not this coin.",
		&"level_up": "Richer AND better. Unfair, really.",
		&"buy": "Retail therapy.",
	},
	&"mender": {
		&"hired": "Try not to need me. You will.",
		&"bounty": "Stay close. I only reach so far.",
		&"flee": "Healer first, hero never!",
		&"level_up": "My hands remember more.",
		&"buy": "Every good bag needs a better bag.",
	},
}
const BARK_TIME := 3.0
const BARK_FADE := 0.5
const BARK_POP := 0.1
const BARK_COOLDOWN := 20.0
const FONT_SIZE := 32
const OUTLINE_SIZE := 2
const PIXEL_SIZE := 0.006
const WRAP_WIDTH := 560.0
const ABOVE_BODY := 1.1          ## body_height + 1.1 = 0.6 m above the HP bar (body_height + 0.5).
const LABEL_NAME := "BarkLabel"
const SCAN_INTERVAL := 0.25
const LABEL_INTERVAL := 0.5

const STAKE_NAMES: Array[String] = ["Stake", "StakeLabel"]
const STAKE_LABEL_NAME := "StakeLabel"
const STAKE_COLOR := Color(1.0, 0.85, 0.3)
const STAKE_Y := 2.3

var selection: Node
## The local team (barks only when visible to it; stake labels of its flags always shown).
var local_team: int = Unit.Team.PLAYER
var rng := RandomNumberGenerator.new()
## Tests: >= 0 replaces every trigger's chance.
var chance_override := -1.0
## Read only: every bark shown, [{champion, trigger, text}] (tests).
var bark_log: Array = []

var _clock := 0.0
var _scan_left := 0.0
var _label_left := 0.0
var _known := {}          # champion instance id -> {level, intent, target, last_bark, inv, own_signal}
var _duplicate := false


func _enter_tree() -> void:
	for other in get_tree().get_nodes_in_group(GROUP):
		if other != self and is_instance_valid(other) and not other.is_queued_for_deletion():
			_duplicate = true   # one barks node per scene
			queue_free()
			return
	add_to_group(GROUP)


func _ready() -> void:
	rng.randomize()
	var fog := FogOfWar.find()
	if fog != null:
		local_team = fog.local_team


func _process(delta: float) -> void:
	if _duplicate:
		return
	_clock += delta
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = SCAN_INTERVAL
		scan()
	_label_left -= delta
	if _label_left <= 0.0:
		_label_left = LABEL_INTERVAL
		update_stake_labels()


# ---------------------------------------------------------------- barks

## Shows `trigger`'s line above `champion` (chance, the 20 s cooldown and visibility apply unless `force`).
## Returns true when a line was shown.
func bark(champion: Node3D, trigger: StringName, force := false) -> bool:
	if champion == null or not is_instance_valid(champion) or not champion.is_inside_tree():
		return false
	var info := _info(champion)
	if not force:
		if _clock - float(info.get("last_bark", -1.0e9)) < BARK_COOLDOWN:
			return false
		if not visible_to_local(champion):
			return false
		var chance := chance_override if chance_override >= 0.0 else chance_of(champion, trigger)
		if rng.randf() >= chance:
			return false
	var text := line_for(champion, trigger)
	if text == "":
		return false
	info["last_bark"] = _clock
	_show_label(champion, text)
	bark_log.append({"champion": champion, "trigger": trigger, "text": text})
	barked.emit(champion, trigger, text)
	return true


## Seconds before `champion` may bark again (0 = now).
func cooldown_left(champion: Node) -> float:
	if champion == null or not _known.has(champion.get_instance_id()):
		return 0.0
	return maxf(0.0, BARK_COOLDOWN - (_clock - float(_known[champion.get_instance_id()].get("last_bark", -1.0e9))))


## Lets `champion` bark again at once (tests, and a champion coming back from the dead may use it).
func reset_cooldown(champion: Node) -> void:
	if champion != null and is_instance_valid(champion):
		_info(champion)["last_bark"] = -1.0e9


## The bark line of `champion` for `trigger` ("" = none).
static func line_for(champion: Node, trigger: StringName) -> String:
	var type: Variant = champion.get("champion_type") if champion != null else null
	if type is Object:
		if (type as Object).has_method(&"bark_for"):
			var s := str((type as Object).call(&"bark_for", trigger))
			if s != "":
				return s
		var barks: Variant = (type as Object).get("barks")
		if barks is Dictionary:
			var v: Variant = (barks as Dictionary).get(trigger, (barks as Dictionary).get(String(trigger), null))
			if v is Array and not (v as Array).is_empty():
				return str((v as Array)[0])
			if v != null and str(v) != "":
				return str(v)
		var id := StringName(str((type as Object).get("id")))
		if FALLBACK_LINES.has(id):
			return str((FALLBACK_LINES[id] as Dictionary).get(trigger, ""))
	return ""


## The chance of `trigger` (ChampionType.BARK_CHANCES when the type's script has it, else 4.5).
static func chance_of(champion: Node, trigger: StringName) -> float:
	var type: Variant = champion.get("champion_type") if champion != null else null
	if type is Object and (type as Object).get_script() != null:
		var consts: Dictionary = ((type as Object).get_script() as Script).get_script_constant_map()
		var table: Variant = consts.get("BARK_CHANCES", null)
		if table is Dictionary and (table as Dictionary).has(trigger):
			return float(table[trigger])
	return float(CHANCES.get(trigger, 0.0))


## True when the local team sees `champion` (own champions always while shown).
func visible_to_local(champion: Node3D) -> bool:
	if not champion.is_visible_in_tree():
		return false
	if champion.get("team") != null and int(champion.get("team")) == local_team:
		return true
	var fog := FogOfWar.find()
	if fog == null or not fog.enabled:
		return true
	return fog.is_visible(local_team, champion.global_position)


## The Label3D currently showing a bark above `champion`, or null.
static func label_of(champion: Node) -> Label3D:
	if champion == null or not is_instance_valid(champion):
		return null
	var l := champion.get_node_or_null(LABEL_NAME) as Label3D
	return l if l != null and not l.is_queued_for_deletion() else null


func _show_label(champion: Node3D, text: String) -> void:
	var old := label_of(champion)
	if old != null:
		old.name = "BarkLabelOld"   # a new bark replaces the old one at once
		old.queue_free()
	var label := Label3D.new()
	label.name = LABEL_NAME
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = false
	label.pixel_size = PIXEL_SIZE
	label.font_size = FONT_SIZE
	label.outline_size = OUTLINE_SIZE
	label.modulate = Color.WHITE
	label.outline_modulate = Color.BLACK
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = WRAP_WIDTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.render_priority = 3
	label.outline_render_priority = 2
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var h := 1.7
	if champion.get("body_height") != null:
		h = float(champion.get("body_height"))
	label.position = Vector3(0.0, h + ABOVE_BODY, 0.0)
	label.text = text
	label.scale = Vector3.ONE * 0.8
	champion.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector3.ONE, BARK_POP)
	tween.tween_interval(BARK_TIME - BARK_POP - BARK_FADE)
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, BARK_FADE)
	tween.tween_property(label, "outline_modulate:a", 0.0, BARK_FADE)
	tween.chain().tween_callback(label.queue_free)


# ---------------------------------------------------------------- polling

## One pass (4 Hz): new champions (hired), level / intent changes, inventories (item_bought).
func scan() -> void:
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group(&"champions"):
		var ch := node as Node3D
		if ch == null or not is_instance_valid(ch) or not ch.is_inside_tree() or ch.is_queued_for_deletion():
			continue
		if not _known.has(ch.get_instance_id()):
			_info(ch)
			_connect(ch)
			if not bool(_info(ch).get("own_signal", false)):
				bark(ch, &"hired")
			continue
		_check_champion(ch)


func _info(ch: Node) -> Dictionary:
	var id := ch.get_instance_id()
	if not _known.has(id):
		_known[id] = {"level": _level(ch), "intent": _intent_kind(ch), "target": _intent_target(ch),
				"last_bark": -1.0e9, "inv": 0, "own_signal": false}
	return _known[id]


func _check_champion(ch: Node3D) -> void:
	var info := _info(ch)
	_connect(ch)
	var own_signal := bool(info.get("own_signal", false))
	var level := _level(ch)
	if level > int(info["level"]) and level > 1 and not own_signal:
		bark(ch, &"level_up")
	info["level"] = level
	var kind := _intent_kind(ch)
	var target := _intent_target(ch)
	if not own_signal and (kind != info["intent"] or (kind == &"bounty" and target != info["target"])):
		if kind == &"flee" and info["intent"] != &"flee":
			bark(ch, &"flee")
		elif kind == &"bounty":
			bark(ch, &"bounty")
	info["intent"] = kind
	info["target"] = target


## &"flee", &"bounty" (hunting / scouting bounty, guarding, escorting) or &"" for an intent id or text.
static func intent_kind_of(intent: Variant) -> StringName:
	var s := str(intent).to_lower() if intent != null else ""
	if s.contains("flee"):
		return &"flee"
	if s.contains("bounty") or s.contains("guarding") or s.contains("escorting"):
		return &"bounty"
	return &""


func _intent_kind(ch: Node) -> StringName:
	return intent_kind_of(ch.get("intent"))


func _intent_target(ch: Node) -> int:
	var t: Variant = ch.get("intent_target")
	return (t as Object).get_instance_id() if is_instance_valid(t) and t is Object else 0   # validity first


func _level(ch: Node) -> int:
	var l: Variant = ch.get("level")
	return int(l) if l != null else 1


## The champion's own bark signal (if gameplay adds one) and its inventory's item_bought.
func _connect(ch: Node) -> void:
	var info := _info(ch)
	if not bool(info.get("own_signal", false)) and ch.has_signal(&"bark_requested"):
		ch.connect(&"bark_requested", _on_bark_requested.bind(ch))
		info["own_signal"] = true
	var inv: Variant = ch.get("inventory")
	if not inv is Object or not is_instance_valid(inv):
		inv = ch.get_node_or_null(^"Inventory")
	if inv == null or not (inv as Object).has_signal(&"item_bought"):
		return
	var inv_id := (inv as Object).get_instance_id()
	if int(info.get("inv", 0)) == inv_id:
		return
	info["inv"] = inv_id
	(inv as Object).connect(&"item_bought", _on_item_bought.bind(ch))


func _on_item_bought(_type: Variant, ch: Node3D) -> void:
	if is_instance_valid(ch) and not bool(_info(ch).get("own_signal", false)):
		bark(ch, &"buy")


func _on_bark_requested(trigger: Variant, ch: Node3D) -> void:
	if is_instance_valid(ch):
		bark(ch, StringName(str(trigger)))


# ---------------------------------------------------------------- stake labels

## Every flag shows its stake in gold (2 Hz): `150`, Guard / Escort `150 · 1:20`, a lost Hunt target `150 · 42 s`
## in WARN. bounty.gd's own "Stake" label is used when it has one (its fog visibility is left to it).
func update_stake_labels() -> void:
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group(&"bounties"):
		var flag := node as Node3D
		if flag == null or not flag.is_inside_tree() or flag.is_queued_for_deletion():
			continue
		var label: Label3D = stake_label_of(flag)
		var mine := false
		if label == null:
			label = make_stake_label()
			flag.add_child(label)
			mine = true
		elif label.name == STAKE_LABEL_NAME:
			mine = true
		var t := stake_text(flag)
		if label.text != t[0]:
			label.text = t[0]
		label.modulate = t[1]
		if mine:
			label.visible = BountyMode.flag_shown(flag, local_team)


## The flag's stake Label3D ("Stake" from bounty.gd or "StakeLabel" from here), or null.
static func stake_label_of(flag: Node) -> Label3D:
	for n in STAKE_NAMES:
		var l := flag.get_node_or_null(NodePath(n)) as Label3D
		if l != null:
			return l
	return null


## [text, colour] of a flag's stake label (ui-champions.md 8).
static func stake_text(flag: Node) -> Array:
	var stake := BountyMode.flag_stake(flag)
	var kind := BountyMode.flag_kind(flag)
	var left := BountyMode.flag_time_left(flag)
	if (kind == BountyMode.GUARD or kind == BountyMode.ESCORT) and left >= 0.0:
		var secs := ceili(left)
		return ["%d · %d:%02d" % [stake, secs / 60, secs % 60], STAKE_COLOR]
	if kind == BountyMode.HUNT and BountyMode.flag_target_lost(flag) and left >= 0.0:
		return ["%d · %d s" % [stake, ceili(left)], UIStyle.WARN]
	return [str(stake), STAKE_COLOR]


## A gold stake label for a flag that has none: font 40, pixel_size 0.006, outline 8, billboard, y 2.3.
static func make_stake_label() -> Label3D:
	var label := Label3D.new()
	label.name = STAKE_LABEL_NAME
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = false
	label.pixel_size = PIXEL_SIZE
	label.font_size = 40
	label.outline_size = 8
	label.modulate = STAKE_COLOR
	label.outline_modulate = Color.BLACK
	label.position = Vector3(0.0, STAKE_Y, 0.0)
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return label

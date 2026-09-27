class_name NextStepHint
extends PanelContainer
## Playtest fix (2026-09-27, "how do I get further? not clear"): a small "Next step" line under the skirmish
## objective (top left) that follows the player's progress: Hall -> soldiers -> Bazaar -> taverns -> push.
## Names and keys come from the kingdom's BuildingType data and KeyLabels (AZERTY shows its own letters).
## Click it to hide it (stays hidden for the session: `dismissed`). Skirmish only (the level has
## `player_kingdom`); attached by GameHUD.setup through attach_optional (load-guarded, no autoload).

const REFRESH := 0.5            ## Seconds between re-reads of the world.
const ARMY_GOAL := 3            ## Army units (not workers / wizard / champions / caravans) that end the "train" step.
const OPEN_TIME := 120.0        ## Taverns open at 2:00 (Tavern.OPEN_TIME).

## Steps, in order (the first one not done is shown).
const STEP_HALL := &"hall"
const STEP_TRAIN := &"train"
const STEP_HOUSE := &"house"
const STEP_BAZAAR := &"bazaar"
const STEP_CARAVAN := &"caravan"
const STEP_TAVERN := &"tavern"
const STEP_PUSH := &"push"

static var dismissed := false   ## Clicked away: stays hidden until the game is closed.

var team := 0                   ## Unit.Team.PLAYER
var kingdom: StringName = &"fire"
var level: Node
var step: StringName = &""      ## The step shown (read only).
var label: Label
var _left := 0.0
var _trained := 0               # units trained at a Hall (signal count)
var _hooked := {}               # TrainingBuilding instance id -> true


## Adds the hint under the objective panel of `hud` when its level is a skirmish; returns it (or null).
static func attach(hud: Node) -> NextStepHint:
	if hud == null:
		return null
	var lv := hud.get_parent()
	if lv == null or not (&"player_kingdom" in lv):
		return null   # missions have their own objectives
	var old := hud.find_child("NextStepHint", true, false) as NextStepHint
	if old != null and not old.is_queued_for_deletion():
		old.kingdom = StringName(str(lv.get(&"player_kingdom")))
		return old
	var h := NextStepHint.new()
	h.name = "NextStepHint"
	h.level = lv
	h.kingdom = StringName(str(lv.get(&"player_kingdom")))
	var obj: Variant = hud.call(&"objective_panel") if hud.has_method(&"objective_panel") else null
	var parent: Node = (obj as Control).get_parent() if obj is Control else hud
	parent.add_child(h)
	return h


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.slate_style())
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# No tooltip: a shown tooltip makes the Viewport take Esc (ui_cancel) to hide it, so Esc no longer closed the
	# build menu / placement while the mouse rested on the hint. "(click to hide)" below says it instead.
	position = Vector2(16, 64)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	label = UIStyle.panel_label("", 15)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", UIStyle.GOLD)
	box.add_child(label)
	var close := UIStyle.panel_label("(click to hide)", 11)
	close.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close.modulate = Color(1, 1, 1, 0.6)
	box.add_child(close)
	visible = not dismissed
	refresh()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		dismiss()
		accept_event()


## Hides the hint for the rest of the session.
func dismiss() -> void:
	dismissed = true
	visible = false


func _process(delta: float) -> void:
	if dismissed:
		visible = false
		return
	_left -= delta
	if _left > 0.0:
		return
	_left = REFRESH
	refresh()
	_place()


## Keeps the hint just under the objective panel (its height changes with the text).
func _place() -> void:
	var hud := get_parent()
	var obj: Variant = null
	while hud != null and not hud.has_method(&"objective_panel"):
		hud = hud.get_parent()
	if hud != null:
		obj = hud.call(&"objective_panel")
	if obj is Control and (obj as Control).visible:
		var o := obj as Control
		position = Vector2(o.position.x, o.position.y + o.size.y + 6.0)
	else:
		position = Vector2(16, 16)


## Re-reads the world and rewrites the line.
func refresh() -> void:
	if label == null:
		return
	var s := read_state()
	step = pick_step(s)
	var t := "Next: " + step_text(step, kingdom, s)
	if label.text != t:
		label.text = t
		reset_size()


## What the player has now: {hall, hall_site, army, pop_used, pop_cap, trade, market, caravans, guild, champions, time}.
func read_state() -> Dictionary:
	var s := {hall = false, hall_site = false, army = 0, pop_used = 0, pop_cap = 0, trade = false,
			market = false, caravans = 0, guild = false, champions = 0, time = 0.0, trained = _trained}
	var tree := get_tree()
	if tree == null:
		return s
	for node in tree.get_nodes_in_group(&"buildings"):
		var b := node as Building
		if b == null or int(b.team) != team or not b.is_alive() or b.building_type == null:
			continue
		match b.building_type.kind:
			&"barracks":
				if b.is_constructed():
					s.hall = true
					_hook(b)
				else:
					s.hall_site = true
			&"market":
				s.market = true
	for node in tree.get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or int(u.team) != team or not u.is_alive():
			continue
		if u.is_in_group(&"caravans"):
			s.caravans += 1
		elif u.is_in_group(&"champions"):
			s.champions += 1
		elif not u.is_in_group(&"heroes") and not u.has_method(&"command_gather") and u.is_commandable():
			s.army += 1
	var eco := Economy.for_team(team)
	if eco != null:
		s.pop_used = eco.pop_used
		s.pop_cap = eco.pop_cap
		s.pop_max = eco.max_pop_cap   # pop 200: no "build houses" hint once the hard cap is reached
	s.trade = BuildingType.trade_active()
	for g in tree.get_nodes_in_group(&"champion_guilds"):
		if int(g.get(&"team")) == team:
			s.guild = true
			if g.has_method(&"roster_size"):
				s.champions = maxi(int(s.champions), int(g.call(&"roster_size")))
	if level != null and is_instance_valid(level) and level.has_method(&"match_time"):
		s.time = float(level.call(&"match_time"))
	return s


func _hook(b: Building) -> void:
	var id := b.get_instance_id()
	if _hooked.has(id) or not b.has_signal(&"unit_trained"):
		return
	_hooked[id] = true
	b.connect(&"unit_trained", func(_u: Node) -> void: _trained += 1)


## The first step not done yet.
static func pick_step(s: Dictionary) -> StringName:
	if not bool(s.get("hall", false)):
		return STEP_HALL
	if int(s.get("trained", 0)) == 0 and int(s.get("army", 0)) < ARMY_GOAL:
		return STEP_TRAIN
	var cap := int(s.get("pop_cap", 0))
	if cap > 0 and int(s.get("pop_used", 0)) >= cap - 1 and cap < int(s.get("pop_max", 1 << 30)):
		return STEP_HOUSE
	if bool(s.get("trade", false)) and not bool(s.get("market", false)):
		return STEP_BAZAAR
	if bool(s.get("trade", false)) and int(s.get("caravans", 0)) == 0:
		return STEP_CARAVAN
	if bool(s.get("guild", false)) and int(s.get("champions", 0)) == 0:
		return STEP_TAVERN
	return STEP_PUSH


## The kingdom's building of `kind` (barracks / house / market / tower), or null.
static func building_of(kingdom_id: StringName, kind: StringName) -> BuildingType:
	for bid in BuildingType.ALL_IDS:
		var t := BuildingType.find(String(bid))
		if t != null and t.faction == kingdom_id and t.kind == kind:
			return t
	return null


## "an Ember Hall" / "a Frost Hall".
static func a_or_an(noun: String) -> String:
	return ("an " if noun != "" and "AEIOU".contains(noun.left(1).to_upper()) else "a ") + noun


## "B then X" on the player's keyboard for the build-menu entry of `t`.
static func build_keys(t: BuildingType) -> String:
	return "%s then %s" % [KeyLabels.of(KEY_B), KeyLabels.letter(t.hotkey_label)]


## The line for `which` (never mentions tiers: it describes the real next action).
static func step_text(which: StringName, kingdom_id: StringName, s: Dictionary) -> String:
	var hall := building_of(kingdom_id, &"barracks")
	var hall_name := hall.display_name if hall else "Hall"
	match which:
		STEP_HALL:
			if bool(s.get("hall_site", false)):
				return "your %s is being built (more workers build it faster)" % hall_name
			if hall == null:
				return "build a Hall with a worker"
			return "build %s: select a worker, press %s (%d crystals)" % [a_or_an(hall_name), build_keys(hall), hall.cost]
		STEP_TRAIN:
			var n := clampi(hall.trains.size() if hall else 4, 1, 5)
			var keys: Array = [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B].slice(0, n)
			return "train soldiers: select the %s, press %s" % [hall_name, KeyLabels.join(keys)]
		STEP_HOUSE:
			var house := building_of(kingdom_id, &"house")
			if house == null:
				return "you are near the population cap: build houses"
			return "population almost full: build %s (%s, %d crystals)" % [a_or_an(house.display_name), build_keys(house), house.cost]
		STEP_BAZAAR:
			var bazaar := building_of(kingdom_id, &"market")
			if bazaar == null:
				return "build a Bazaar to start trade"
			return "build %s to start trade: worker, %s (%d crystals, needs %s)" \
					% [a_or_an(bazaar.display_name), build_keys(bazaar), bazaar.cost, a_or_an(hall_name)]
		STEP_CARAVAN:
			return "select the Bazaar, press %s for a caravan, then right-click a trading post (gold)" % KeyLabels.of(KEY_Z)
		STEP_TAVERN:
			var t := float(s.get("time", 0.0))
			if t < OPEN_TIME:
				var left := int(ceil(OPEN_TIME - t))
				return "taverns open at 2:00 (in %d:%02d): then press %s to hire a champion" \
						% [left / 60, left % 60, KeyLabels.of(KEY_Y)]
			return "taverns are open: press %s to hire a champion" % KeyLabels.of(KEY_Y)
	var tower := building_of(kingdom_id, &"tower")
	var am := KeyLabels.of(KEY_X) if GameSettings.hero_wasd() else KeyLabels.of(KEY_A)
	var tower_part := ", guard your base with %s (%s)" % [a_or_an(tower.display_name), build_keys(tower)] if tower else ""
	return "grow your army%s, then attack: %s + click = attack-move. Destroy every enemy building to win" \
			% [tower_part, am]

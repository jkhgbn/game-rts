class_name NextStepHint
extends PanelContainer
## Playtest fix (2026-09-27, "how do I get further? not clear"): a small "Next step" line under the skirmish
## objective (top left) that follows the player's progress: Hall -> soldiers -> Stronghold / Citadel -> Bazaar ->
## taverns -> push. Names and keys come from the kingdom's BuildingType data and KeyLabels (AZERTY shows its own
## letters). Click it to hide it (stays hidden for the session: `dismissed`). Skirmish and the missions built on it
## (the level has `player_kingdom`); attached by GameHUD.setup through attach_optional (load-guarded, no autoload).
## Tiers (2026-09-30, JS: "not sure there is a way to tier up / get better units"): when the keep upgrade can start the
## hint says so with the key, price, time and the exact units it opens; a minute before it opens a second line warns;
## after it the hint names the new units and their keys until one is trained (or NEW_UNITS_TIME passes).

const REFRESH := 0.5            ## Seconds between re-reads of the world.
const ARMY_GOAL := 3            ## Army units (not workers / wizard / champions / caravans) that end the "train" step.
const OPEN_TIME := 120.0        ## Taverns open at 2:00 (Tavern.OPEN_TIME).
const SOON_TIME := 60.0         ## The "Soon: Stronghold at 3:30" line shows this long before the upgrade opens.
const NEW_UNITS_TIME := 90.0    ## The "train your new units" step lasts at most this long after a keep upgrade.

## Steps, in order (the first one not done is shown).
const STEP_HALL := &"hall"
const STEP_TRAIN := &"train"
const STEP_HOUSE := &"house"
const STEP_TIER := &"tier"             ## Stronghold / Citadel can start now (TierSystem.status reason "").
const STEP_NEW_UNITS := &"new_units"   ## Just upgraded: train one of the units it opened.
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
var _last_tier := 0             # the player's tier at the last read (0 = not read yet)
var _new_tier := 0              # the tier whose new units the hint names (0 = none)
var _new_until := 0.0           # match time the STEP_NEW_UNITS step ends at the latest


## Adds the hint under the objective panel of `hud` when its level is a skirmish; returns it (or null).
static func attach(hud: Node) -> NextStepHint:
	if hud == null:
		return null
	var lv := hud.get_parent()
	if lv == null or not (&"player_kingdom" in lv) or lv.has_method(&"objectives"):
		return null   # missions (Mission01 extends Skirmish) have their own objectives and hints
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
	# Under the objective panel at once: the match can start paused (STR / INT pick), and _process waits for it.
	_place.call_deferred()


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
	var t := Loc.t("Next: %s") % step_text(step, kingdom, s)
	var soon := soon_text(s)
	if soon != "" and step != STEP_TIER:
		t += "\n" + soon
	if label.text != t:
		label.text = t
		reset_size()


## What the player has now: {hall, hall_site, army, pop_used, pop_cap, trade, market, caravans, guild, champions, time,
## team, tier, tier_ready, new_units, new_tier}.
func read_state() -> Dictionary:
	var s := {hall = false, hall_site = false, army = 0, pop_used = 0, pop_cap = 0, trade = false,
			market = false, caravans = 0, guild = false, champions = 0, time = 0.0, trained = _trained, team = team}
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
	_read_tier(s)
	return s


## Keep tiers (TierSystem.status): s.tier (the status dictionary, {} without tiers), s.tier_ready (the next upgrade can
## start now), s.new_units (the list of the units the last upgrade opened, while that step lasts), s.new_tier.
func _read_tier(s: Dictionary) -> void:
	s.tier = {}
	s.tier_ready = false
	s.new_units = []
	s.new_tier = 0
	if TierSystem.instance() == null:
		return
	var st := TierSystem.status(team)
	if st.is_empty():
		return
	s.tier = st
	var now := float(s.get("time", 0.0))
	var tier := int(st["tier"])
	if _last_tier != 0 and tier > _last_tier:
		_new_tier = tier
		_new_until = now + NEW_UNITS_TIME
	_last_tier = tier
	s.tier_ready = int(st["next"]) > 0 and not bool(st["upgrading"]) and String(st["reason"]) == ""
	if _new_tier > 0 and _new_tier == tier and now <= _new_until and not _has_unit_of_tier(_new_tier):
		s.new_units = TierSystem.unlocks(team, _new_tier)
		s.new_tier = _new_tier
	elif _new_tier > 0:
		_new_tier = 0


## True when the team has a living (or queued) unit whose type needs `tier`: the "train your new units" step is done.
func _has_unit_of_tier(tier: int) -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	for node in tree.get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and int(u.team) == team and u.is_alive() and u.unit_type and u.unit_type.requires_tier >= tier:
			return true
	for node in tree.get_nodes_in_group(&"buildings"):
		var b := node as TrainingBuilding
		if b == null or int(b.team) != team or not b.is_alive():
			continue
		for t: UnitType in b.queue:
			if t and t.requires_tier >= tier and t.id != Keep.TIER_STUB_ID:
				return true
	return false


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
	if bool(s.get("tier_ready", false)):
		return STEP_TIER
	if not (s.get("new_units", []) as Array).is_empty():
		return STEP_NEW_UNITS
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
	if Loc.is_french():
		return noun   # the French templates carry no article before a proper name ("construisez Ember Hall")
	return ("an " if noun != "" and "AEIOU".contains(noun.left(1).to_upper()) else "a ") + noun


## "B then X" on the player's keyboard for the build-menu entry of `t`.
static func build_keys(t: BuildingType) -> String:
	return Loc.t("%s then %s") % [KeyLabels.of(KEY_B), KeyLabels.letter(t.hotkey_label)]


## The line for `which`: the real next action, with its keys (the keep upgrade is named "Stronghold" / "Citadel").
static func step_text(which: StringName, kingdom_id: StringName, s: Dictionary) -> String:
	var hall := building_of(kingdom_id, &"barracks")
	var hall_name := hall.display_name if hall else "Hall"
	match which:
		STEP_TIER:
			return tier_text(s)
		STEP_NEW_UNITS:
			return new_units_text(s.get("new_units", []), int(s.get("new_tier", 2)))
		STEP_HALL:
			if bool(s.get("hall_site", false)):
				return Loc.t("your %s is being built (more workers build it faster)") % hall_name
			if hall == null:
				return Loc.t("build a Hall with a worker")
			return Loc.t("build {a_hall}: select a worker, press {keys} ({cost} crystals)",
					{"a_hall": a_or_an(hall_name), "keys": build_keys(hall), "cost": hall.cost})
		STEP_TRAIN:
			var n := clampi(hall.trains.size() if hall else 4, 1, 5)
			var keys: Array = [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B].slice(0, n)
			return Loc.t("train soldiers: select the %s, press %s") % [hall_name, KeyLabels.join(keys)]
		STEP_HOUSE:
			var house := building_of(kingdom_id, &"house")
			if house == null:
				return Loc.t("you are near the population cap: build houses")
			return Loc.t("population almost full: build {a_house} ({keys}, {cost} crystals)",
					{"a_house": a_or_an(house.display_name), "keys": build_keys(house), "cost": house.cost})
		STEP_BAZAAR:
			var bazaar := building_of(kingdom_id, &"market")
			if bazaar == null:
				return Loc.t("build a Bazaar to start trade")
			return Loc.t("build {a_bazaar} to start trade: worker, {keys} ({cost} crystals, needs {a_hall})",
					{"a_bazaar": a_or_an(bazaar.display_name), "keys": build_keys(bazaar), "cost": bazaar.cost,
					"a_hall": a_or_an(hall_name)})
		STEP_CARAVAN:
			return Loc.t("select the Bazaar, press %s for a caravan, then right-click a trading post (gold)") % KeyLabels.of(KEY_Z)
		STEP_TAVERN:
			var t := float(s.get("time", 0.0))
			if t < OPEN_TIME:
				var left := int(ceil(OPEN_TIME - t))
				return Loc.t("taverns open at 2:00 (in %d:%02d): then press %s to hire a champion") \
						% [left / 60, left % 60, KeyLabels.of(KEY_Y)]
			return Loc.t("taverns are open: press %s to hire a champion") % KeyLabels.of(KEY_Y)
	var tower := building_of(kingdom_id, &"tower")
	var am := KeyLabels.of(GameSettings.attack_move_key())
	if tower:
		return Loc.t("grow your army, guard your base with {a_tower} ({keys}), then attack: {am} + click = attack-move. Destroy every enemy building to win",
				{"a_tower": a_or_an(tower.display_name), "keys": build_keys(tower), "am": am})
	return Loc.t("grow your army, then attack: %s + click = attack-move. Destroy every enemy building to win") % am


## STEP_TIER: "upgrade your Keep to a Stronghold: select it, press X (200 crystals, 60 s)" and, on a second line, the
## units it opens ("it opens Pyre Adept, Cinder Arbalest, Kilnwarden").
static func tier_text(s: Dictionary) -> String:
	var st: Dictionary = s.get("tier", {})
	var keep_name := "Keep"
	var k: Variant = st.get("keep")
	if k is Keep and is_instance_valid(k) and (k as Keep).building_type:
		keep_name = (k as Keep).building_type.display_name
	var money := Loc.t("%d crystals, %d s") % [int(st.get("crystals", 0)), roundi(float(st.get("time", 0.0)))]
	if bool(st.get("short_crystals", false)):
		money = Loc.t("save %d crystals; %d s") % [int(st.get("crystals", 0)), roundi(float(st.get("time", 0.0)))]
	var t := Loc.t("upgrade your {keep} to {a_tier}: select it, press {key} ({money})", {"keep": Loc.t(keep_name),
			"a_tier": a_or_an(Loc.t(String(st.get("name", "Stronghold")))), "key": KeyLabels.of(KEY_X), "money": money})
	var names := unit_names(TierSystem.unlocks(int(s.get("team", 0)), int(st.get("next", 2))))
	if not names.is_empty():
		t += "\n      " + Loc.t("it opens %s") % ", ".join(names)
	return t


## STEP_NEW_UNITS: "new units: select the Ember Hall, press C Pyre Adept, V Cinder Arbalest; the Keep: B Kilnwarden".
static func new_units_text(list: Array, tier: int) -> String:
	var parts: Array[String] = []
	var by_where := {}
	var order: Array[String] = []
	for d: Dictionary in list:
		var w := String(d["where"])
		if not by_where.has(w):
			by_where[w] = []
			order.append(w)
		var key := slot_key(d)
		var entry := String(d["name"]) if key == "" else "%s %s" % [key, d["name"]]
		if not (by_where[w] as Array).has(entry):
			(by_where[w] as Array).append(entry)
	for w in order:
		parts.append(Loc.t("the %s: %s") % [w, ", ".join(by_where[w])])
	return Loc.t("train your new %s units: select %s") % [Loc.t(TierSystem.tier_name(tier)), "; ".join(parts)]


## The training key of an unlock entry (TierSystem.unlocks) on its building's card, as printed on the player's keyboard
## ("" when its building is not built yet). Mirrors SelectionManager.train_slots(): the keep's caster sits on B, and at the
## Citadel the keep keeps its empty tier slot on X.
static func slot_key(d: Dictionary) -> String:
	var b: Variant = d.get("building")
	var i := int(d.get("index", -1))
	if not (b is TrainingBuilding) or not is_instance_valid(b) or i < 0:
		return ""
	if b is Keep:
		var keep := b as Keep
		if CasterKit.is_keep_caster(d.get("type")):
			i = SelectionManager.CASTER_KEEP_SLOT
		elif TierSystem.instance() != null and keep.tier >= 3 and not keep.is_upgrading() and i >= 1:
			i += 1
	if i >= SelectionManager.SLOT_LETTERS.length():
		return ""
	return KeyLabels.letter(SelectionManager.SLOT_LETTERS[i])


## Unique unit names of unlock entries, in order.
static func unit_names(list: Array) -> Array[String]:
	var out: Array[String] = []
	for d: Dictionary in list:
		if not out.has(String(d["name"])):
			out.append(String(d["name"]))
	return out


## A second line while the next keep upgrade opens within SOON_TIME: "Soon: Stronghold at 3:30 (in 0:40), 200 crystals,
## X on the Keep". "" otherwise.
static func soon_text(s: Dictionary) -> String:
	var st: Dictionary = s.get("tier", {})
	if st.is_empty() or int(st.get("next", 0)) == 0 or bool(st.get("upgrading", false)):
		return ""
	if not String(st.get("reason", "")).begins_with("Available at"):
		return ""
	var left := float(st.get("from", 0.0)) - float(s.get("time", 0.0))
	if left <= 0.0 or left > SOON_TIME:
		return ""
	var keep_name := "Keep"
	var k: Variant = st.get("keep")
	if k is Keep and is_instance_valid(k) and (k as Keep).building_type:
		keep_name = (k as Keep).building_type.display_name
	var secs := ceili(left)
	return Loc.t("Soon: %s at %s (in %d:%02d): %d crystals, %s on your %s") % [Loc.t(str(st.get("name", "Stronghold"))),
			TierSystem.clock(float(st.get("from", 0.0))), secs / 60, secs % 60, int(st.get("crystals", 0)),
			KeyLabels.of(KEY_X), Loc.t(keep_name)]

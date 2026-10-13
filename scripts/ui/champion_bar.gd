class_name ChampionBar
extends Control
## The champion bar (step 9, task 9.C7; spec: docs/design/champions.md 9, layout: docs/design/ui-champions.md 3).
## A column of three 240 x 72 slots at (16, 408 / 486 / 564), anchored bottom-left above the minimap. Slot k = roster
## slot k of the player's ChampionGuild (alive, reviving or fallen). Each slot: portrait 56 (icon or abbreviation),
## level medallion, name, F5 / F6 / F7 badge, HP bar, intent in its colour, purse. Fallen: greyed, `Fallen` /
## `Returns in 24 s`. Empty: `+`, `Hire a champion`, `Y · tavern`.
## Click on a living champion (or F5 / F6 / F7) = centre the camera on it: it never selects, never orders, never touches
## the selection. Click / key on a fallen, reviving or empty slot = the tavern window (`tavern_requested(slot)`).
## Y toggles the tavern window. Keys are physical keycodes, handled here (ui-champions.md 13.3).
## Hidden while the level has neither a guild for the player's team nor a tavern (missions 1-2).
##
## Champions, guilds and bounties (tasks 9.C1-9.C4) are duck-typed: groups, get(), has_method(). The static helpers
## (champion data, intent text / colour, names, ability texts) are shared with TavernWindow and SelectionPanel.
## Step 11 (11.C4, ui-champions.md 15): the 16 x 16 class badge at (6, 50) once a champion has a class (pops on
## `class_chosen`, not on a save load), the class in tooltip line 1, the class message (`announce_class`, once per
## champion: own always, enemy only while visible), and the class helpers / fallback tables (CLASSES, CLASS_WEIGHTS,
## the 12 class skills in ABILITIES, `class_tooltip`, `lean_tooltip`, `class_weights_for`, ClassBadge, TipLabel).

## A fallen / reviving / empty slot was clicked (or its F key pressed): open the tavern window for that slot.
signal tavern_requested(slot: int)

const SLOTS := 3
const BAR_POS := Vector2(16, 408)
const BAR_SIZE := Vector2(240, 228)
const SLOT_SIZE := Vector2(240, 72)
const SLOT_STEP := 78.0
const PORTRAIT_SIZE := 56.0
const KEYS: Array[Key] = [KEY_F5, KEY_F6, KEY_F7]
const KEY_NAMES: Array[String] = ["F5", "F6", "F7"]
const REFRESH_TIME := 0.1

## The 4 archetypes in tavern order (champions.md 4.1).
const IDS: Array[StringName] = [&"wayfinder", &"oathwall", &"coin_cutter", &"mender"]
const MAX_ROSTER := 3
const POP := 2
const OPENS_AT := "2:00"   ## Fallback only: the shown time comes from the taverns (opens_at_text; mission 3 opens at 0:30).
## Hire prices of the 1st / 2nd / 3rd champion (skills-rework.md 9.2), used when the guild has no hire_cost().
const FALLBACK_COSTS: Array[Vector2i] = [Vector2i(225, 75), Vector2i(275, 100), Vector2i(325, 125)]
## Revive price when the guild has no revive_cost(): REVIVE_BASE + REVIVE_PER_LEVEL x level essence.
const REVIVE_BASE := 80
const REVIVE_PER_LEVEL := 35
const CLASS_MESSAGE_TIME := 3.0
const CLASS_SCAN_TIME := 1.0

## The 4 classes in table order (skills-rework.md 3; ui-champions.md 15.6), used until / unless
## `data/champion_classes/<id>.tres` answers. `mods` = the class tooltip's line 3, `takes` = the class message's end.
const CLASS_IDS: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard"]
const CLASSES := {
	&"spear": {"display_name": "Spear", "ranged": false, "attack_damage": 13.0, "attack_cooldown": 0.95,
		"attack_range": 2.4, "mods": "+0.2 speed", "bounty_kind": &"explore", "takes": "the Spear",
		"ability_ids": [&"lunge", &"hobbling_javelin", &"skewer"], "unlock_levels": [2, 3, 5]},
	&"sword_shield": {"display_name": "Sword and Shield", "ranged": false, "attack_damage": 12.0, "attack_cooldown": 1.1,
		"attack_range": 1.8, "mods": "+10 armor · -0.2 speed", "bounty_kind": &"guard", "takes": "the Sword and Shield",
		"ability_ids": [&"riposte", &"second_wind", &"shield_throw"], "unlock_levels": [2, 3, 5]},
	&"two_hand": {"display_name": "Two-Hand Sword", "ranged": false, "attack_damage": 24.0, "attack_cooldown": 1.55,
		"attack_range": 2.1, "mods": "no stat change", "bounty_kind": &"hunt", "takes": "the Two-Hand Sword",
		"ability_ids": [&"cleave", &"crushing_blow", &"whirlwind"], "unlock_levels": [2, 3, 5]},
	&"wizard": {"display_name": "Wizard", "ranged": true, "attack_damage": 11.0, "attack_cooldown": 1.3,
		"attack_range": 7.5, "mods": "-10 % max HP", "bounty_kind": &"escort", "takes": "the Wizard's staff",
		"ability_ids": [&"arc_bolt", &"slipstep", &"starfall"], "unlock_levels": [2, 3, 5]},
}
## Archetype -> class -> base weight of the level-2 draw (skills-rework.md 2.1), used when the type has no class_weights.
const CLASS_WEIGHTS := {
	&"wayfinder": {&"spear": 50.0, &"sword_shield": 10.0, &"two_hand": 15.0, &"wizard": 25.0},
	&"oathwall": {&"spear": 15.0, &"sword_shield": 60.0, &"two_hand": 20.0, &"wizard": 5.0},
	&"coin_cutter": {&"spear": 25.0, &"sword_shield": 5.0, &"two_hand": 55.0, &"wizard": 15.0},
	&"mender": {&"spear": 15.0, &"sword_shield": 20.0, &"two_hand": 5.0, &"wizard": 60.0},
}
## Bounty lean of the draw: +20 weight per paid bounty of the class's kind, at most +40 per class.
## Unlock levels of the 3 class skills (skills-rework.md 4.1).
const CLASS_UNLOCKS: Array[int] = [2, 3, 5]
const LEAN_WEIGHT := 20.0
const LEAN_CAP := 40.0
const CLASS_SCRIPT := "res://scripts/units/champion_class.gd"
## The class-skill tooltip mark and the bounty hint line of the lean tooltip (ui-champions.md 15.5).
const CLASS_MARK := "  (class, level {n})"
const BOUNTY_HINT := "Your bounties before level 2 steer its class"
## The champion intent words (scripts/ai/champion_brain.gd, scripts/units/champion.gd): msgids for the French file,
## translated where shown (`Loc.sink`, target_text(..., true)).
const INTENT_MSGIDS: Array[String] = ["Idle", "Fallen", "Fleeing", "Resting", "Fighting", "Unpaid!", "Hunting bounty",
		"Scouting bounty", "Guarding", "Escorting", "Shopping", "Exploring", "Patrolling", "Raiding", "With the army",
		"Capturing", "Hunting big game", "Hunting game", "Returns in # s"]

## Tests: false = draw the code glyph even when `art/icons/classes/<id>.png` exists.
static var class_icons_enabled := true
## Tests: false = ignore ChampionClass / its .tres files and use the fallback tables above.
static var class_scripts_enabled := true

## Intent colours (ui-champions.md 13.1); keys are the lower-case intent words without "!". Others: white.
const INTENT_COLORS := {
	"fighting": Color(1.0, 0.55, 0.2),
	"fleeing": Color(0.95, 0.35, 0.3),
	"resting": Color(0.4, 0.9, 0.4),
	"hunting bounty": Color(1.0, 0.85, 0.4),
	"exploring": Color(0.45, 0.85, 1.0),
	"scouting bounty": Color(0.45, 0.85, 1.0),
	"guarding": Color(0.6, 0.75, 1.0),
	"escorting": Color(0.6, 0.75, 1.0),
	"shopping": Color(0.75, 0.45, 1.0),
	"unpaid": Color(0.6, 0.6, 0.6),
}
const FALLEN_EDGE := Color(0.45, 0.42, 0.35)
const FALLEN_TINT := Color(0.55, 0.55, 0.55)
const LOW_HP := Color(1.0, 0.45, 0.40)
const HEAL_FLASH := Color(0.5, 1.0, 0.5)

## Champion data used until / unless `data/champions/<id>.tres` answers (champions.md 4.1-4.3).
const FALLBACK := {
	&"wayfinder": {
		"names": ["Tamsin Farrow", "Tobin Farrow"], "title": "the Wayfinder", "role": "Scout, ranged",
		"max_hp": 260.0, "armor": 0.0, "attack_damage": 13.0, "attack_range": 8.0, "move_speed": 5.8,
		"sight_radius": 18.0, "growth_pct": 0.08,
		"ability_ids": [&"flare_arrow", &"snare_line", &"trailblaze"],
		"personality_line": "Goes where the map is blank.",
	},
	&"oathwall": {
		"names": ["Garran Stoneward", "Gerda Stoneward"], "title": "the Oathwall", "role": "Guardian, melee",
		"max_hp": 520.0, "armor": 20.0, "attack_damage": 15.0, "attack_range": 1.8, "move_speed": 4.3,
		"sight_radius": 11.0, "growth_pct": 0.08,
		"ability_ids": [&"oath_of_iron", &"shield_bash", &"bulwark_stand"],
		"personality_line": "Would rather stand at your door than walk to theirs.",
	},
	&"coin_cutter": {
		"names": ["Sable Quint", "Silas Quint"], "title": "the Coin-Cutter", "role": "Raider, melee",
		"max_hp": 300.0, "armor": 5.0, "attack_damage": 17.0, "attack_range": 1.6, "move_speed": 5.6,
		"sight_radius": 12.0, "growth_pct": 0.08,
		"ability_ids": [&"cutpurse", &"smoke_pouch", &"marked_for_coin"],
		"personality_line": "Loves a bounty more than a fair fight.",
	},
	&"mender": {
		"names": ["Orla Fenwick", "Osric Fenwick"], "title": "the Mender", "role": "Healer, ranged",
		"max_hp": 280.0, "armor": 5.0, "attack_damage": 9.0, "attack_range": 7.0, "move_speed": 4.8,
		"sight_radius": 12.0, "growth_pct": 0.08,
		"ability_ids": [&"mending_draught", &"soothing_circle", &"lifeline"],
		"personality_line": "Follows the army and keeps it standing.",
	},
}
## Ability texts (ui-champions.md 5.4): name, unlock level, cooldown, tavern short line, tooltip line 2, effect with
## `{n}` = a number that grows with the level, and the autocast trigger.
const ABILITIES := {
	&"flare_arrow": {"name": "Signal Flare", "unlock": 1, "cooldown": 18.0,
		"short": "20 dmg, reveals a spot 6 s", "info": "Cooldown 18 s · Range 20",
		"effect": "Hurls a flare up to 20 m: {20} damage around it, and the spot stays in sight for 6 s.",
		"when": "while exploring: ahead on its path; in a fight: where an enemy just vanished"},
	&"snare_line": {"name": "Snare Line", "unlock": 1, "cooldown": 14.0,
		"short": "15 dmg + roots 1.5 s", "info": "Cooldown 14 s · Range 8",
		"effect": "{15} damage and roots one enemy for 1.5 s.",
		"when": "when fleeing from a chaser, or when its hunt target runs"},
	&"trailblaze": {"name": "Trailblaze", "unlock": 4, "cooldown": 30.0,
		"short": "haste 5 s, allies 8 m", "info": "Cooldown 30 s · Self, radius 8",
		"effect": "Itself and own soldiers within 8 m get Haste for 5 s.",
		"when": "when fleeing, or walking more than 25 m to a flag"},
	&"oath_of_iron": {"name": "Oath of Iron", "unlock": 1, "cooldown": 16.0,
		"short": "taunts 3 s, +20 armor", "info": "Cooldown 16 s · Self, radius 6",
		"effect": "Enemies within 6 m must attack it for 3 s; it gains 20 armor for 3 s.",
		"when": "when 2+ enemies hit an ally, or 3+ target it"},
	&"shield_bash": {"name": "Shield Bash", "unlock": 1, "cooldown": 10.0,
		"short": "30 dmg + dazes 0.8 s", "info": "Cooldown 10 s · Range 2.2",
		"effect": "{30} damage and dazes the target 0.8 s (no move, no act).",
		"when": "on its target; prefers one hitting your building or wizard"},
	&"bulwark_stand": {"name": "Bulwark Stand", "unlock": 4, "cooldown": 40.0,
		"short": "braces allies 6 s", "info": "Cooldown 40 s · Self, radius 5",
		"effect": "Plants its shield 6 s: it cannot move; allies within 5 m take 30 % less damage.",
		"when": "when 3+ enemies are near while guarding or near a building"},
	&"cutpurse": {"name": "Cutpurse", "unlock": 1, "cooldown": 8.0,
		"short": "next hit +25 dmg, +15 purse", "info": "Cooldown 8 s · Melee",
		"effect": "Its next attack deals {25} extra damage; a kill adds 15 to its purse.",
		"when": "on a target below 50 % HP or a worker"},
	&"smoke_pouch": {"name": "Smoke Pouch", "unlock": 1, "cooldown": 25.0,
		"short": "shroud 3 s, drops targets", "info": "Cooldown 25 s · Self, radius 3",
		"effect": "Shroud 3 s (half damage, faster); enemies within 6 m lose it as a target.",
		"when": "when hurt near its flee point, or when 3+ enemies target it"},
	&"marked_for_coin": {"name": "Marked for Coin", "unlock": 4, "cooldown": 20.0,
		"short": "+15 % damage taken", "info": "Cooldown 20 s · Range 8",
		"effect": "Marks one enemy 6 s: it takes 15 % more damage from everything.",
		"when": "on its hunt or raid target"},
	&"mending_draught": {"name": "Mending Draught", "unlock": 1, "cooldown": 7.0,
		"short": "heals 50", "info": "Cooldown 7 s · Range 9",
		"effect": "Heals the most hurt ally within 9 m by {50}.",
		"when": "when an ally within 9 m is below 70 % HP"},
	&"soothing_circle": {"name": "Soothing Circle", "unlock": 1, "cooldown": 24.0,
		"short": "6 HP / s for 5 s", "info": "Cooldown 24 s · Range 9, radius 5",
		"effect": "A circle that heals allies inside by {6} HP / s for 5 s.",
		"when": "when 3+ allies stand together below 80 % HP"},
	&"lifeline": {"name": "Lifeline", "unlock": 4, "cooldown": 35.0,
		"short": "100 shield 5 s", "info": "Cooldown 35 s · Range 9",
		"effect": "A {100} shield for 5 s on one ally.",
		"when": "when the wizard or a champion is below 35 % HP"},
	# The 12 class skills (skills-rework.md 4.2, ui-champions.md 15.6); `class` = the class they belong to.
	&"lunge": {"name": "Lunge", "unlock": 2, "cooldown": 14.0, "class": &"spear",
		"short": "25 dmg + dazes 0.5 s", "info": "Cooldown 14 s · Range 6",
		"effect": "Darts to its target and strikes: {25} damage, dazed 0.5 s.",
		"when": "on a ranged enemy or caster 3-6 m away, or a hunt target slipping away"},
	&"hobbling_javelin": {"name": "Hobbling Javelin", "unlock": 3, "cooldown": 16.0, "class": &"spear",
		"short": "25 dmg + hobbles 3 s", "info": "Cooldown 16 s · Range 10",
		"effect": "A javelin: {25} damage and hobbles the target 3 s (-1.5 speed).",
		"when": "on an enemy below 60 % HP that runs, or its hunt target"},
	&"skewer": {"name": "Skewer", "unlock": 5, "cooldown": 25.0, "class": &"spear",
		"short": "40 dmg in a 5 m line", "info": "Cooldown 25 s · Line 5 m",
		"effect": "A thrust through a 5 m line: {40} damage to every enemy in it.",
		"when": "when 3+ enemies stand in a line"},
	&"riposte": {"name": "Riposte", "unlock": 2, "cooldown": 22.0, "class": &"sword_shield",
		"short": "returns 10 per hit, 4 s", "info": "Cooldown 22 s · Self, 4 s",
		"effect": "Melee attackers take {10} damage per hit.",
		"when": "when 2+ melee enemies attack it"},
	&"second_wind": {"name": "Second Wind", "unlock": 3, "cooldown": 45.0, "class": &"sword_shield",
		"short": "heals 20 % over 4 s", "info": "Cooldown 45 s · Self",
		"effect": "Heals itself 20 % of its max HP over 4 s.",
		"when": "below 50 % HP, hit in the last 2 s"},
	&"shield_throw": {"name": "Shield Throw", "unlock": 5, "cooldown": 20.0, "class": &"sword_shield",
		"short": "30 / 20 / 10, bounces", "info": "Cooldown 20 s · Range 8",
		"effect": "Throws its shield: {30} damage, then {20} and {10} to two more enemies within 4 m.",
		"when": "on a ranged enemy hitting an ally, or a target out of reach 3-8 m away"},
	&"cleave": {"name": "Cleave", "unlock": 2, "cooldown": 10.0, "class": &"two_hand",
		"short": "next hit splashes 2.5 m", "info": "Cooldown 10 s · Melee",
		"effect": "Its next attack also hits every enemy within 2.5 m of the target for full damage.",
		"when": "when its target has 2+ enemies beside it"},
	&"crushing_blow": {"name": "Crushing Blow", "unlock": 3, "cooldown": 20.0, "class": &"two_hand",
		"short": "30 dmg, -20 armor 6 s", "info": "Cooldown 20 s · Melee",
		"effect": "{30} damage; an enemy unit loses 20 armor for 6 s.",
		"when": "on an armored target (10+), a hero or a costly unit"},
	&"whirlwind": {"name": "Whirlwind", "unlock": 5, "cooldown": 30.0, "class": &"two_hand",
		"short": "12 dmg / 0.5 s for 2 s", "info": "Cooldown 30 s · Self, radius 3",
		"effect": "Spins 2 s: {12} damage every 0.5 s to every enemy within 3 m ({48} each).",
		"when": "when 3+ enemies are within 3 m"},
	&"arc_bolt": {"name": "Arc Bolt", "unlock": 2, "cooldown": 10.0, "class": &"wizard",
		"short": "40 dmg bolt", "info": "Cooldown 10 s · Range 12",
		"effect": "A bolt: {40} damage to one enemy.",
		"when": "on an enemy it can finish, else a hero, else the one hitting the most hurt ally"},
	&"slipstep": {"name": "Slipstep", "unlock": 3, "cooldown": 22.0, "class": &"wizard",
		"short": "blinks 8 m away", "info": "Cooldown 22 s · Self, 8 m",
		"effect": "Blinks up to 8 m away from the nearest melee enemy.",
		"when": "when a melee enemy closes in below 70 % HP, or while fleeing"},
	&"starfall": {"name": "Starfall", "unlock": 5, "cooldown": 35.0, "class": &"wizard",
		"short": "45 dmg in radius 3.5", "info": "Cooldown 35 s · Range 12, radius 3.5",
		"effect": "A star falls after 1 s: {45} damage to every enemy and building within 3.5 m.",
		"when": "on the enemy with the most neighbours (3+ within 3.5 m)"},
}

var hero: Node = null
var selection: SelectionManager = null
var tavern_window: Node = null        ## The HUD's TavernWindow (Y toggles it).
var team := 0
var slots: Array[Slot] = []           ## The 3 slot buttons (index = roster slot).
## Every class message this bar showed (`Garran Stoneward takes up the Sword and Shield`), oldest first (tests).
var messages_shown: Array[String] = []

var _refresh_left := 0.0
var _skin := -1
var _clock := 0.0
var _scan_left := 0.0
var _announced: Dictionary = {}       ## champion instance id -> class id already announced (one message each).

static var _info_cache: Dictionary = {}
static var _effect_re: RegEx = null   ## U3-9: ability_effect's {n} pattern, compiled once.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Anchored bottom-left like the minimap: offset_top -492, offset_bottom -264 at 1600 x 900.
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = BAR_POS.x
	offset_right = BAR_POS.x + BAR_SIZE.x
	offset_top = -(900.0 - BAR_POS.y)
	offset_bottom = offset_top + BAR_SIZE.y
	for i in SLOTS:
		var s := Slot.new()
		s.bar = self
		s.index = i
		s.position = Vector2(0, i * SLOT_STEP)
		s.pressed.connect(press_slot.bind(i))
		add_child(s)
		slots.append(s)
	visible = false


func setup(p_hero: Node, p_selection: SelectionManager) -> void:
	hero = p_hero
	selection = p_selection
	if hero != null and is_instance_valid(hero) and hero.get("team") != null:
		team = int(hero.get("team"))
	refresh()


func apply_skin() -> void:
	_skin = UIStyle.skin_version
	for s in slots:
		s.apply_skin()


func _process(delta: float) -> void:
	_clock += delta
	if _skin != UIStyle.skin_version:
		apply_skin()
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		refresh()
	_scan_left -= delta
	if _scan_left <= 0.0:
		scan_champions()
	if visible:
		for s in slots:
			s.tick(delta, _clock)


## Connects `class_chosen` of every champion (own and enemy, group "champions") once (1 Hz by itself; tests may
## call it). Own roster champions are also connected by refresh().
func scan_champions() -> void:
	_scan_left = CLASS_SCAN_TIME
	if not is_inside_tree():
		return
	for ch in get_tree().get_nodes_in_group(&"champions"):
		_watch_class(ch)


func _watch_class(ch: Node) -> void:
	if ch == null or not is_instance_valid(ch) or not ch.has_signal(&"class_chosen"):
		return
	if not ch.is_connected(&"class_chosen", _on_class_chosen):
		ch.connect(&"class_chosen", _on_class_chosen)


func _on_class_chosen(ch: Variant, cid: Variant = &"") -> void:
	if not (ch is Node) or not is_instance_valid(ch):
		return
	var id := StringName(str(cid)) if cid != null and str(cid) != "" else class_id_of(ch as Node)
	announce_class(ch as Node, id)
	refresh()   # the bar badge pops now, with the level-2 medallion ring


## The class message of ui-champions.md 15.7 for `ch` taking up class `cid`, shown once per champion: own champions
## always, enemy ones only while visible (`is_visible_in_tree()`). Returns true when it was shown now.
func announce_class(ch: Node, cid: StringName) -> bool:
	if ch == null or not is_instance_valid(ch) or cid == &"":
		return false
	var key := ch.get_instance_id()
	if _announced.has(key):
		return false
	var own := ch.get("team") == null or int(ch.get("team")) == team
	var seen := true
	if ch is Node3D:
		seen = (ch as Node3D).is_visible_in_tree()
	elif ch is CanvasItem:
		seen = (ch as CanvasItem).is_visible_in_tree()
	if not own and not seen:
		return false
	_announced[key] = cid
	var text := class_message(ch, cid)
	messages_shown.append(text)
	var hud := _message_hud()
	if hud != null:
		hud.call(&"show_message", text, CLASS_MESSAGE_TIME)
	return true


# The HUD that shows messages: the level's `hud` (ui-champions.md 11), else the first ancestor with show_message.
func _message_hud() -> Node:
	if not is_inside_tree():
		return null
	var scene := get_tree().current_scene
	var h: Variant = scene.get("hud") if scene != null else null
	if is_instance_valid(h) and h is Node and (h as Node).has_method(&"show_message"):
		return h as Node
	var p := get_parent()
	while p != null:
		if p.has_method(&"show_message"):
			return p
		p = p.get_parent()
	return null


## Re-reads the guild and the 3 champions (10 Hz by itself; tests may call it).
func refresh() -> void:
	_refresh_left = REFRESH_TIME
	if not is_inside_tree():
		return
	var guild := guild_for_team(get_tree(), team)
	visible = guild != null or not get_tree().get_nodes_in_group(&"taverns").is_empty()
	if not visible:
		return
	var list := roster(guild)
	var pending := pending_ids(guild)
	var open := guild_is_open(guild)
	for i in SLOTS:
		if i < list.size():
			_watch_class(list[i])
			slots[i].show_champion(list[i], guild)
		elif i - list.size() < pending.size():
			var id: StringName = pending[i - list.size()]
			slots[i].show_pending(id, hire_name(get_tree(), guild, id, team), hire_left(guild, id))
		else:
			slots[i].show_empty(open)


## The champion in slot `index` (0-2), or null.
func champion_at(index: int) -> Node:
	if index < 0 or index >= slots.size():
		return null
	var ch: Node = slots[index].champion
	return ch if ch != null and is_instance_valid(ch) else null


## A slot click / F5-F7 (also callable by tests): a living champion = centre the camera on it (never selects);
## fallen, reviving, arriving or empty = `tavern_requested(index)`.
func press_slot(index: int) -> void:
	refresh()
	var ch := champion_at(index)
	if ch != null and is_alive(ch):
		focus_on(ch)
	else:
		tavern_requested.emit(index)


## Centres the camera on `node` without touching the selection.
func focus_on(node: Node3D) -> void:
	if selection != null and is_instance_valid(selection):
		selection.centre_camera_on([node])


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed or key.shift_pressed \
			or key.meta_pressed or not visible:
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if code == KEY_Y and tavern_window != null and is_instance_valid(tavern_window):
		tavern_window.call(&"toggle")
		get_viewport().set_input_as_handled()
	elif KEYS.has(code):
		press_slot(KEYS.find(code))
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- shared helpers (static, duck-typed)

## The ChampionGuild of `team` (group "champion_guilds"), or null.
static func guild_for_team(tree: SceneTree, p_team: int) -> Node:
	if tree == null:
		return null
	for g in tree.get_nodes_in_group(&"champion_guilds"):
		if is_instance_valid(g) and not g.is_queued_for_deletion() and g.get("team") != null \
				and int(g.get("team")) == p_team:
			return g
	return null


## "m:ss" of the earliest tavern `open_time` in `from`'s tree (group "taverns": a mission may move it, mission 3 0:30);
## OPENS_AT when there is no tavern.
static func opens_at_text(from: Node) -> String:
	if from == null or not from.is_inside_tree():
		return OPENS_AT
	var best := INF
	for t: Node in from.get_tree().get_nodes_in_group(&"taverns"):
		var v: Variant = t.get(&"open_time")
		if v != null:
			best = minf(best, float(v))
	if best == INF:
		return OPENS_AT
	var s := int(ceilf(maxf(best, 0.0)))
	return "%d:%02d" % [s / 60, s % 60]


static func guild_is_open(guild: Node) -> bool:
	return guild != null and is_instance_valid(guild) and (not guild.has_method(&"is_open") or bool(guild.call(&"is_open")))


## The guild's roster (`champions`), valid nodes only, in slot order.
static func roster(guild: Node) -> Array:
	var out: Array = []
	if guild == null or not is_instance_valid(guild):
		return out
	var list: Variant = guild.get("champions")
	if list is Array:
		for ch: Variant in list:
			if is_instance_valid(ch) and ch is Node:
				out.append(ch)
	return out


## Archetypes hired but not out of the tavern yet (the guild's `pending_ids()`), in order.
static func pending_ids(guild: Node) -> Array:
	if guild == null or not is_instance_valid(guild) or not guild.has_method(&"pending_ids"):
		return []
	var out: Array = []
	for id: Variant in guild.call(&"pending_ids"):
		out.append(StringName(str(id)))
	return out


## Seconds until a pending hire walks out (the guild's `hire_time_left(id)`), 0 when unknown.
static func hire_left(guild: Node, id: StringName) -> float:
	if guild == null or not is_instance_valid(guild) or not guild.has_method(&"hire_time_left"):
		return 0.0
	return maxf(float(guild.call(&"hire_time_left", id)), 0.0)


## True for a champion (group "champions", or a unit that refuses orders and has a purse).
static func is_champion(n: Variant) -> bool:
	if not (n is Node) or not is_instance_valid(n):
		return false
	var node := n as Node
	if node.is_in_group(&"champions"):
		return true
	return node.has_method(&"is_commandable") and not bool(node.call(&"is_commandable")) \
			and node.get("purse") != null


static func is_alive(ch: Node) -> bool:
	if ch == null or not is_instance_valid(ch):
		return false
	return not ch.has_method(&"is_alive") or bool(ch.call(&"is_alive"))


## &"coin_cutter" etc. (`type_id()`, else `champion_type.id`, else `champion_id`), &"" when unknown.
static func champion_id(ch: Node) -> StringName:
	if ch == null or not is_instance_valid(ch):
		return &""
	if ch.has_method(&"type_id"):
		var tid := StringName(str(ch.call(&"type_id")))
		if tid != &"":
			return tid
	var t: Variant = ch.get("champion_type")
	if is_instance_valid(t) and t is Object and (t as Object).get("id") != null:
		return StringName(str((t as Object).get("id")))
	var id: Variant = ch.get("champion_id")
	return StringName(str(id)) if id != null else &""


## Data of an archetype: the FALLBACK table overlaid with `data/champions/<id>.tres` when it exists.
## Keys: id, names, title, role, max_hp, armor, attack_damage, attack_range, move_speed, sight_radius, growth_pct,
## ability_ids, personality_line.
static func type_info(id: StringName) -> Dictionary:
	if _info_cache.has(id):
		return _info_cache[id]
	var info: Dictionary = (FALLBACK.get(id, {}) as Dictionary).duplicate(true)
	info["id"] = id
	info["class_weights"] = (CLASS_WEIGHTS.get(id, {}) as Dictionary).duplicate()
	info["ability_names"] = {}
	var path := "res://data/champions/%s.tres" % id
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res != null:
			# Step 11: the draw weights and the per-archetype ability names (the Wayfinder's "Signal Flare").
			var cw: Variant = res.get("class_weights")
			if cw is Dictionary and not (cw as Dictionary).is_empty():
				var weights := {}
				for k: Variant in cw:
					weights[StringName(str(k))] = float(cw[k])
				info["class_weights"] = weights
			var an: Variant = res.get("ability_names")
			if an is Dictionary:
				var ability_names := {}
				for k: Variant in an:
					ability_names[StringName(str(k))] = str(an[k])
				info["ability_names"] = ability_names
			for key: String in ["title", "role", "max_hp", "armor", "attack_damage", "attack_range", "move_speed",
					"sight_radius", "growth_pct", "personality_line"]:
				var v: Variant = res.get(key)
				if v != null and str(v) != "":
					info[key] = v
			var names: Variant = res.get("names")
			if (names is PackedStringArray or names is Array) and names.size() >= 2:
				info["names"] = [str(names[0]), str(names[1])]
			var abilities: Variant = res.get("ability_ids")
			if (abilities is Array or abilities is PackedStringArray) and abilities.size() > 0:
				var ids: Array = []
				for a: Variant in abilities:
					ids.append(StringName(str(a)))
				info["ability_ids"] = ids
	var title := str(info.get("title", ""))
	if title != "" and not title.to_lower().begins_with("the "):
		info["title"] = "the " + title
	_info_cache[id] = info
	return info


## True when `data/champions/<id>.tres` exists for at least one archetype (else "Champions not available").
static func data_available() -> bool:
	for id in IDS:
		if ResourceLoader.exists("res://data/champions/%s.tres" % id):
			return true
	return false


## "Sable Quint" (the champion's `display_name`, else name A / B of its type, else its unit name).
static func display_name_of(ch: Node) -> String:
	if ch == null or not is_instance_valid(ch):
		return ""
	var n: Variant = ch.get("display_name")
	if n != null and str(n) != "":
		return str(n)
	var names: Array = type_info(champion_id(ch)).get("names", [])
	var variant := int(ch.get("variant")) if ch.get("variant") != null else 0
	if names.size() > variant:
		return str(names[variant])
	return str(ch.get("unit_name")) if ch.get("unit_name") != null else "Champion"


## "the Coin-Cutter" (the archetype's title).
static func title_of(ch_or_id: Variant) -> String:
	var id: StringName = ch_or_id if ch_or_id is StringName else champion_id(ch_or_id as Node)
	return str(type_info(id).get("title", ""))


## "Sable Quint, the Coin-Cutter".
static func full_name_of(ch: Node) -> String:
	var title := title_of(ch)
	var n := display_name_of(ch)
	return n if title == "" else "%s, %s" % [n, Loc.t(title)]


static func level_of(ch: Node) -> int:
	return int(ch.get("level")) if ch != null and ch.get("level") != null else 1


static func purse_of(ch: Node) -> int:
	return int(ch.get("purse")) if ch != null and ch.get("purse") != null else 0


static func max_hp_of(ch: Node) -> float:
	return maxf(float(ch.get("max_hp")) if ch != null and ch.get("max_hp") != null else 1.0, 1.0)


static func is_unpaid(ch: Node) -> bool:
	return ch != null and ch.get("is_unpaid") != null and bool(ch.get("is_unpaid"))


## Seconds until a reviving champion returns (the guild's `revive_time_left`), 0 when not reviving.
static func revive_left(guild: Node, ch: Node) -> float:
	if guild == null or not is_instance_valid(guild) or ch == null or not guild.has_method(&"revive_time_left"):
		return 0.0
	return maxf(float(guild.call(&"revive_time_left", ch)), 0.0)


## The intent as shown: `Fallen` / `Returns in 24 s` when dead, else the champion's intent in words
## (`&"hunting_bounty"` or `&"Hunting bounty"` -> "Hunting bounty"; unpaid -> "Unpaid!"; none -> "Idle").
static func intent_text(ch: Node, guild: Node = null) -> String:
	if ch == null or not is_instance_valid(ch):
		return ""
	if not is_alive(ch):
		var left := revive_left(guild, ch)
		return "Returns in %d s" % ceili(left) if left > 0.0 else "Fallen"
	if ch.has_method(&"intent_text"):
		return str(ch.call(&"intent_text"))
	return intent_words(ch.get("intent"))


## `&"hunting_bounty"` -> "Hunting bounty", `&"unpaid"` -> "Unpaid!", null / "" -> "Idle".
static func intent_words(intent: Variant) -> String:
	var s := str(intent) if intent != null else ""
	if s == "" or s == "<null>":
		return "Idle"
	s = s.replace("_", " ").strip_edges()
	if s == s.to_lower():
		s = s.left(1).to_upper() + s.substr(1)
	if s.to_lower() == "unpaid":
		s = "Unpaid!"
	return s


## Colour of an intent text (ui-champions.md 13.1): `Fallen` text_muted, `Returns in` WARN, table, else white.
static func intent_color(text: String) -> Color:
	var key := text.to_lower().replace("!", "").strip_edges()
	if key.contains(":"):
		key = key.get_slice(":", 0).strip_edges()
	if key == "fallen":
		return UIStyle.token(&"text_muted")
	if key.begins_with("returns in"):
		return UIStyle.WARN
	return INTENT_COLORS.get(key, Color.WHITE)


## Name of a node for texts: "Vessa", "Gloom Hall", "Shade".
static func node_name(n: Variant) -> String:
	if not (n is Object) or not is_instance_valid(n):
		return ""
	var o := n as Object
	var bt: Variant = o.get("building_type")
	if bt is Object and (bt as Object).get("display_name") != null:
		return str((bt as Object).get("display_name"))
	for key: String in ["display_name", "unit_name"]:
		var v: Variant = o.get(key)
		if v != null and str(v) != "":
			return str(v).get_slice(",", 0).strip_edges()
	return ""


## The intent with its target: "Hunting bounty: Gloom Hall (150)", "Guarding: Ember Hall (50)", "Fighting: Shade";
## the intent alone when there is nothing to name ("Fleeing", "Fallen", "Returns in 24 s").
## `loc` = the display text in the player's language (the English one stays the logic / colour key).
static func target_text(ch: Node, guild: Node = null, loc := false) -> String:
	var intent := intent_text(ch, guild)
	if loc:
		intent = Loc.sink(intent)
	if ch == null or not is_instance_valid(ch) or not is_alive(ch):
		return intent
	var t: Variant = ch.get("intent_target")
	if not is_instance_valid(t) or not (t is Object):   # validity first: `is` on a freed object errors
		return intent
	var o := t as Object
	if o.get("stake") != null:   # a Bounty flag
		var what := str(o.call(&"target_name")) if o.has_method(&"target_name") else node_name(o.get("target"))
		var args := {"intent": intent, "target": what, "stake": int(o.get("stake"))}
		# `loc` = the French template; else the English one (the logic / colour key stays English in every language).
		if what == "":   # an Explore flag: a point, no name
			return Loc.t("{intent} ({stake})", args) if loc else "{intent} ({stake})".format(args)
		return Loc.t("{intent}: {target} ({stake})", args) if loc else "{intent}: {target} ({stake})".format(args)
	var n := node_name(o)
	var a2 := {"intent": intent, "target": n}
	if n == "":
		return intent
	return Loc.t("{intent}: {target}", a2) if loc else "{intent}: {target}".format(a2)


## "XP  320 / 400" or "XP  MAX" ("" when the champion has no XP).
static func xp_text(ch: Node) -> String:
	if ch == null or ch.get("xp") == null:
		return ""
	var xp := int(ch.get("xp"))
	var next := int(ch.call(&"xp_to_next")) if ch.has_method(&"xp_to_next") else 0
	return "XP  MAX" if next <= 0 else "XP  %d / %d" % [xp, next]


## The 4 item slots of the champion's inventory: item types (or null for an empty slot).
static func item_types(ch: Node) -> Array:
	var out: Array = [null, null, null, null]
	var inv := InventoryBar.inventory_of(ch)
	for i in 4:
		out[i] = InventoryBar.type_of_entry(InventoryBar.slot_entry(inv, i))
	return out


## Stack counts of the 4 item slots (1 for a single item, 0 when empty).
static func item_counts(ch: Node) -> Array:
	var out: Array = [0, 0, 0, 0]
	var inv := InventoryBar.inventory_of(ch)
	for i in 4:
		var e: Variant = InventoryBar.slot_entry(inv, i)
		if e is Dictionary:
			out[i] = int((e as Dictionary).get("count", 1))
		elif e is Object and (e as Object).get(&"count") != null:
			out[i] = int((e as Object).get(&"count"))
		elif e != null:
			out[i] = 1
	return out


## "Items: Swiftsoles, Ember Draught x2" / "Items: none".
static func items_line(ch: Node) -> String:
	var parts: PackedStringArray = []
	var types := item_types(ch)
	var counts := item_counts(ch)
	for i in 4:
		if types[i] != null:
			var n := ItemTooltip.display_name(types[i])
			parts.append(n if int(counts[i]) <= 1 else "%s x%d" % [n, int(counts[i])])
	return Loc.t("Items: {list}", {"list": ", ".join(parts)}) if not parts.is_empty() else Loc.t("Items: none")


## The name the player's team would get for `id`: the guild's `name_for(id)` when it has one; else name B when
## another team already hired that archetype as name A (champions.md 1), else name A.
static func hire_name(tree: SceneTree, guild: Node, id: StringName, p_team: int) -> String:
	if guild != null and is_instance_valid(guild) and guild.has_method(&"name_for"):
		return str(guild.call(&"name_for", id))
	var names: Array = type_info(id).get("names", ["", ""])
	var variant := 0
	if tree != null:
		for ch in tree.get_nodes_in_group(&"champions"):
			if champion_id(ch) == id and ch.get("team") != null and int(ch.get("team")) != p_team \
					and (ch.get("variant") == null or int(ch.get("variant")) == 0):
				variant = 1
	return str(names[variant]) if names.size() > variant else str(id).capitalize()


## `hire_cost(id)` of the guild as Vector2i(crystals, essence); the champions.md 3.1 table otherwise.
static func hire_cost(guild: Node, id: StringName) -> Vector2i:
	if guild != null and is_instance_valid(guild) and guild.has_method(&"hire_cost"):
		var d: Variant = guild.call(&"hire_cost", id)
		if d is Dictionary:
			var c: Variant = d.get("crystals", d.get(&"crystals", 0))
			var e: Variant = d.get("essence", d.get(&"essence", 0))
			return Vector2i(int(c), int(e))
	var n := clampi(roster(guild).size() + pending_ids(guild).size(), 0, FALLBACK_COSTS.size() - 1)
	return FALLBACK_COSTS[n]


## Essence to revive `ch`: the guild's `revive_cost(ch)` when it has one, else 80 + 35 x level (skills-rework.md 9.2).
static func revive_cost(guild: Node, ch: Node) -> int:
	if guild != null and is_instance_valid(guild) and guild.has_method(&"revive_cost"):
		return int(guild.call(&"revive_cost", ch))
	return REVIVE_BASE + REVIVE_PER_LEVEL * level_of(ch)


## The archetype's icon (`art/icons/units/<id>.png`, variant B uses the same file), or null.
static func icon_of(id: StringName) -> Texture2D:
	if id == &"":
		return null
	return IconLibrary.icon_for(&"units", id)


## Ability data (ABILITIES entry, or a stub from the id).
static func ability_info(id: StringName) -> Dictionary:
	return ABILITIES.get(id, {"name": str(id).capitalize(), "unlock": 1, "cooldown": 0.0, "short": "", "info": "",
			"effect": "", "when": ""})


## The effect line with its `{n}` numbers grown to `level` (+ growth per level above 1) and `spell_power`.
static func ability_effect(id: StringName, level: int, growth := 0.08, spell_power := 0.0) -> String:
	var text := Loc.t(str(ability_info(id).get("effect", "")))   # the French keeps the same {n} marks
	var mult := (1.0 + growth * float(maxi(level, 1) - 1)) * (1.0 + spell_power / 100.0)
	if _effect_re == null:   # U3-9: compiled once (the tavern refreshes 4 x / s, one call per tooltip)
		_effect_re = RegEx.create_from_string("\\{(\\d+(?:\\.\\d+)?)\\}")
	var out := text
	for m in _effect_re.search_all(text):
		var v := float(m.get_string(1)) * mult
		out = out.replace(m.get_string(), str(roundi(v)) if absf(v - roundf(v)) < 0.05 or v >= 20.0 else Loc.num(v, 1))
	return out


## The name `id` shows for archetype `type_id`: the type's `ability_names` override (the Wayfinder's `flare_arrow` is
## "Signal Flare"), else the ABILITIES name.
static func ability_display_name(id: StringName, type_id: StringName = &"") -> String:
	if type_id != &"":
		var names: Dictionary = type_info(type_id).get("ability_names", {})
		if names.has(id) and str(names[id]) != "":
			return str(names[id])
	return str(ability_info(id).get("name", ""))


## True for the 12 class skills (ui-champions.md 15.6).
static func is_class_skill(id: StringName) -> bool:
	return str(ability_info(id).get("class", "")) != ""


## The ability tooltip (ui-champions.md 5.4): name (+ `Locked`), cooldown / range, effect, autocast, unlock line.
## A class skill's line 1 ends with `  (class, level n)` (15.5).
static func ability_tooltip(id: StringName, level := 1, growth := 0.08, spell_power := 0.0) -> String:
	var a := ability_info(id)
	var locked := level < int(a.get("unlock", 1))
	var first := str(a.get("name", "")) + ("  " + Loc.t("Locked") if locked else "")
	if is_class_skill(id):
		first += Loc.t(CLASS_MARK, {"n": int(a.get("unlock", 1))})
	var lines: PackedStringArray = [first]
	lines.append(Loc.t(str(a.get("info", ""))))
	lines.append(ability_effect(id, level, growth, spell_power))
	lines.append(Loc.t("Autocast: {when}", {"when": Loc.t(str(a.get("when", "")))}))
	if locked:
		lines.append(Loc.t("Unlocks at level {n}", {"n": int(a.get("unlock", 1))}))
	return "\n".join(lines)


## Section-8 tooltip (UIStyle.make_tooltip) with `Locked` / `Unlocks at level n` / `Unpaid:` lines in WARN.
## Step 11 (15.5): a line starting with `Your bounties` in GOLD; line 1's `Locked` in WARN and a class skill's
## `(class, level n)` right-aligned, font 12 `text_muted` (like `Rank n / m`).
static func styled_tooltip(text: String) -> Control:
	text = Loc.sink(text)   # an English tooltip_text (static literal) shows in the player's language
	var lines := text.split("\n")
	var first := lines[0] if lines.size() > 0 else ""
	var mark := ""
	var locked := false
	var locked_word := Loc.t("Locked")
	# `  (class, level 2)` in either language (CLASS_MARK translated).
	var mark_re := "\\s+" + _regex_escape(Loc.t(CLASS_MARK).strip_edges()).replace("\\{n\\}", "\\d+") + "$"
	var re := RegEx.create_from_string(mark_re)
	var m := re.search(first)
	if m != null:
		mark = m.get_string().strip_edges()
		first = first.substr(0, m.get_start())
	if first.ends_with("  " + locked_word):
		locked = true
		first = first.trim_suffix("  " + locked_word)
	if mark != "" or locked:
		lines[0] = first
	var unlocks := Loc.t("Unlocks at level {n}").get_slice("{", 0)
	var unpaid := Loc.t("Unpaid: ignores bounties").get_slice(":", 0)
	var hint := Loc.t(BOUNTY_HINT)
	var box := UIStyle.make_tooltip("\n".join(lines))
	for l: Label in box.find_children("*", "Label", true, false):
		if l.text.begins_with(unlocks) or l.text.begins_with(unpaid + ":") or l.text.strip_edges() == locked_word:
			l.add_theme_color_override("font_color", UIStyle.WARN)
		elif l.text == hint:
			l.add_theme_color_override("font_color", UIStyle.GOLD)
	if (mark != "" or locked) and box.get_child_count() > 0 and box.get_child(0) is HBoxContainer:
		var row := box.get_child(0) as HBoxContainer
		if locked:
			row.add_child(UIStyle.panel_label(locked_word, 13, UIStyle.WARN))
		if mark != "":
			var r := UIStyle.panel_label(mark, 12, UIStyle.token(&"text_muted"))
			r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(r)
	return box


static func _regex_escape(s: String) -> String:
	var out := ""
	for c in s:
		out += ("\\" + c) if "\\.^$|?*+()[]{}".contains(c) else c
	return out


## Two-letter placeholder: "Sable Quint" -> "SQ".
static func initials(text: String) -> String:
	return UIStyle.abbrev(text)


## Tooltip of a filled slot (ui-champions.md 3.4): name [key] title / level, XP, HP, purse / personality /
## intent with target / items.
static func tooltip_for(ch: Node, guild: Node, key_name := "") -> String:
	var lines: PackedStringArray = []
	var title := Loc.t(title_of(ch))
	var cls := class_name_of(ch)
	if cls != "":   # 15.2: the class rides on the muted title part after the `]`
		title = "%s · %s" % [title, cls] if title != "" else cls
	lines.append("%s  [%s]  %s" % [display_name_of(ch), key_name, title] if key_name != "" \
			else "%s  %s" % [display_name_of(ch), title])
	var alive := is_alive(ch)
	var xp := xp_text(ch).replace("  ", " ")
	var hp := ceili(float(ch.get("hp"))) if alive and ch.get("hp") != null else 0
	var args := {"level": level_of(ch), "xp": xp, "hp": hp, "max": int(max_hp_of(ch)), "purse": purse_of(ch)}
	lines.append(Loc.t("Level {level} · {xp} · HP {hp} / {max} · Purse {purse}", args) if xp != ""
			else Loc.t("Level {level} · HP {hp} / {max} · Purse {purse}", args))
	lines.append(Loc.t(str(type_info(champion_id(ch)).get("personality_line", ""))))
	lines.append(Loc.t("Unpaid: ignores bounties") if alive and is_unpaid(ch) else target_text(ch, guild, true))
	lines.append(items_line(ch))
	return "\n".join(lines)


# ---------------------------------------------------------------- classes (step 11, ui-champions.md 15)

## The champion's class id (`class_id()`, else `champion_class.id`), &"" before the level-2 choice.
static func class_id_of(ch: Node) -> StringName:
	if ch == null or not is_instance_valid(ch):
		return &""
	if ch.has_method(&"class_id"):
		var v: Variant = ch.call(&"class_id")
		return StringName(str(v)) if v != null else &""
	var c: Variant = ch.get("champion_class")
	if is_instance_valid(c) and c is Object and (c as Object).get("id") != null:
		return StringName(str((c as Object).get("id")))
	return &""


## Data of a class: the CLASSES table overlaid with `data/champion_classes/<id>.tres` when it exists. Keys: id,
## display_name, ranged, attack_damage, attack_cooldown, attack_range, mods, bounty_kind, takes, ability_ids,
## unlock_levels. {} for an unknown id.
static func class_info(id: StringName) -> Dictionary:
	if not CLASSES.has(id):
		return {}
	var key := "class|%s|%s" % [id, class_scripts_enabled]
	if _info_cache.has(key):
		return _info_cache[key]
	var info: Dictionary = (CLASSES[id] as Dictionary).duplicate(true)
	info["id"] = id
	var path := "res://data/champion_classes/%s.tres" % id
	if class_scripts_enabled and ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res != null:
			for k: String in ["display_name", "attack_damage", "attack_cooldown", "attack_range"]:
				var v: Variant = res.get(k)
				if v != null and str(v) != "":
					info[k] = v
			if res.get("is_ranged") != null:
				info["ranged"] = bool(res.get("is_ranged"))
			if res.get("bounty_kind") != null and str(res.get("bounty_kind")) != "":
				info["bounty_kind"] = StringName(str(res.get("bounty_kind")))
			var ids: Variant = res.get("ability_ids")
			if (ids is Array or ids is PackedStringArray) and ids.size() == 3:
				var out: Array = []
				for a: Variant in ids:
					out.append(StringName(str(a)))
				info["ability_ids"] = out
			var lv: Variant = res.get("unlock_levels")
			if (lv is Array or lv is PackedInt32Array) and lv.size() == 3:
				info["unlock_levels"] = [int(lv[0]), int(lv[1]), int(lv[2])]
	_info_cache[key] = info
	return info


## "Sword and Shield" (the class's display name), "" before the choice or for an unknown id.
static func class_display_name(id: StringName) -> String:
	return Loc.t(str(class_info(id).get("display_name", "")))


## The champion's class name ("Sword and Shield"), "" before level 2.
static func class_name_of(ch: Node) -> String:
	return class_display_name(class_id_of(ch))


## The class message of 15.7: `Garran Stoneward takes up the Sword and Shield` (`the Wizard's staff` for a wizard).
static func class_message(ch: Node, cid: StringName) -> String:
	var info := class_info(cid)
	return Loc.t("{name} takes up {weapon}", {"name": display_name_of(ch),
			"weapon": Loc.t(str(info.get("takes", "the " + str(info.get("display_name", "")))))})


## The class tooltip (15.5): name / weapon line / stat change / the 3 skills with unlock levels. `damage` >= 0 =
## the champion's current attack damage (else the class's level-1 number).
static func class_tooltip(id: StringName, damage := -1.0) -> String:
	var c := class_info(id)
	if c.is_empty():
		return ""
	var dmg := num_text(float(c.get("attack_damage", 0.0)) if damage < 0.0 else damage, 1)
	var cd := num_text(float(c.get("attack_cooldown", 1.0)), 2)
	var reach := num_text(float(c.get("attack_range", 0.0)), 1)
	var wargs := {"reach": reach, "dmg": dmg, "cd": cd}
	var weapon := Loc.t("ranged {reach} · {dmg} damage every {cd} s", wargs) if bool(c.get("ranged", false)) \
			else Loc.t("melee · {dmg} damage every {cd} s · reach {reach}", wargs)
	var skills: PackedStringArray = []
	var ids: Array = c.get("ability_ids", [])
	var levels: Array = c.get("unlock_levels", [2, 3, 5])
	for j in ids.size():
		skills.append("%s L%d" % [str(ability_info(ids[j]).get("name", "")), int(levels[j]) if j < levels.size() else 2])
	return "\n".join([class_display_name(id), weapon, Loc.t(str(c.get("mods", ""))), " · ".join(skills)])


## `12` for 12.0 / 11.96, else `decimals` digits without trailing zeros (`13.9`, `0.95`, `1.1`).
static func num_text(v: float, decimals: int) -> String:
	if absf(v - roundf(v)) < 0.49 * pow(10.0, -decimals):
		return str(roundi(v))
	return Loc.num(v, decimals)


## The class tooltip for a champion right now: its current attack damage (get_stat).
static func class_tooltip_for(ch: Node) -> String:
	var dmg := -1.0
	if ch != null and is_instance_valid(ch) and ch.has_method(&"get_stat"):
		dmg = float(ch.call(&"get_stat", &"attack_damage"))
	return class_tooltip(class_id_of(ch), dmg)


## Class id -> draw weight. A champion (own view, bounties included): `ChampionClass.weights_for` when the script
## exists and the champion has a type resource, else the archetype's base weights (type_info) + 20 per paid bounty
## of the leaning kind (`bounty_leans`, at most +40). An archetype id (StringName) = the base weights only.
static func class_weights_for(ch_or_id: Variant) -> Dictionary:
	var out := {}
	if ch_or_id is Node and is_instance_valid(ch_or_id):
		var ch := ch_or_id as Node
		if class_scripts_enabled and ResourceLoader.exists(CLASS_SCRIPT) and ch.get("champion_type") is Resource:
			var script: Variant = load(CLASS_SCRIPT)
			if script is Script and (script as Script).has_method(&"weights_for"):
				var w: Variant = (script as Script).call(&"weights_for", ch)
				if w is Dictionary and not (w as Dictionary).is_empty():
					for cid in CLASS_IDS:
						out[cid] = float((w as Dictionary).get(cid, (w as Dictionary).get(String(cid), 0.0)))
					return out
		out = class_weights_for(champion_id(ch))
		var leans: Variant = ch.get("bounty_leans")
		if leans is Dictionary:
			for cid in CLASS_IDS:
				var kind: StringName = class_info(cid).get("bounty_kind", &"")
				var n := int((leans as Dictionary).get(kind, (leans as Dictionary).get(String(kind), 0)))
				out[cid] = float(out[cid]) + minf(LEAN_CAP, LEAN_WEIGHT * float(maxi(n, 0)))
		return out
	var id := StringName(str(ch_or_id)) if ch_or_id != null else &""
	var base: Dictionary = type_info(id).get("class_weights", {}) if id != &"" else {}
	for cid in CLASS_IDS:
		out[cid] = float(base.get(cid, 25.0 if base.is_empty() else 0.0))
	return out


## The classes by weight, highest first (ties keep the table order): [[id, weight], ...].
static func ranked_classes(weights: Dictionary) -> Array:
	var out: Array = []
	for cid in CLASS_IDS:
		var w := float(weights.get(cid, 0.0))
		var at := out.size()
		for k in out.size():
			if w > float(out[k][1]):
				at = k
				break
		out.insert(at, [cid, w])
	return out


## The class an archetype usually takes (highest base weight; ties: table order), &"" when unknown.
static func usual_class(archetype_id: StringName) -> StringName:
	var ranked := ranked_classes(class_weights_for(archetype_id))
	return ranked[0][0] if not ranked.is_empty() else &""


## `Sword and Shield (71 %)`: the leading class of `weights` and its share.
static func lean_text(weights: Dictionary) -> String:
	var ranked := ranked_classes(weights)
	var total := 0.0
	for r: Array in ranked:
		total += float(r[1])
	if ranked.is_empty() or total <= 0.0:
		return ""
	return "%s (%d %%)" % [class_display_name(ranked[0][0]), roundi(100.0 * float(ranked[0][1]) / total)]


## The lean tooltip (15.5). `slot` 1-3 = a `?` class-skill slot (`Class skill n  Locked` + `Unlocks at level n`),
## 0 = the caption / tavern labels (`Class`). `own` adds the bounty hint (own champions, not-hired rows).
static func lean_tooltip(weights: Dictionary, slot := 0, own := true) -> String:
	var ranked := ranked_classes(weights)
	var total := 0.0
	for r: Array in ranked:
		total += float(r[1])
	var parts: PackedStringArray = []
	for r: Array in ranked:
		parts.append("%s %d %%" % [class_display_name(r[0]), roundi(100.0 * float(r[1]) / total) if total > 0.0 else 0])
	var lines: PackedStringArray = [Loc.t("Class skill {n}", {"n": slot}) + "  " + Loc.t("Locked") if slot > 0
			else Loc.t("Class")]
	lines.append(Loc.t("Chooses a class at level 2 · leans {lean}", {"lean": lean_text(weights)}))
	lines.append(" · ".join(parts))
	if own:
		lines.append(Loc.t(BOUNTY_HINT))
	if slot > 0:
		lines.append(Loc.t("Unlocks at level {n}", {"n": CLASS_UNLOCKS[clampi(slot - 1, 0, 2)]}))
	return "\n".join(lines)


## The class icon `art/icons/classes/<id>.png`, or null (the badge draws the code glyph then).
static func class_icon(id: StringName) -> Texture2D:
	if id == &"" or not class_icons_enabled:
		return null
	return IconLibrary.icon_for(&"classes", id)


## The code glyph of class `id` (15.1) in `text` colour, line 1.5, in a box of side `s` centred at `c`.
static func draw_class_glyph(ci: CanvasItem, id: StringName, c: Vector2, s: float) -> void:
	var r := 0.375 * s
	var col := UIStyle.token(&"text")
	match id:
		&"spear":
			ci.draw_line(c + Vector2(-0.8, 0.8) * r, c + Vector2(0.8, -0.8) * r, col, 1.5, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.95, -0.95) * r, c + Vector2(0.3, -0.65) * r,
					c + Vector2(0.65, -0.3) * r]), col)
		&"sword_shield":
			var shield := PackedVector2Array([c + Vector2(-0.5, -0.55) * r, c + Vector2(0.5, -0.55) * r,
					c + Vector2(0.5, 0.05) * r, c + Vector2(0, 0.6) * r, c + Vector2(-0.5, 0.05) * r])
			ci.draw_colored_polygon(shield, Color(col, 0.35))
			var closed := shield.duplicate()
			closed.append(shield[0])
			ci.draw_polyline(closed, col, 1.5, true)
			ci.draw_line(c + Vector2(-0.75, 0.75) * r, c + Vector2(0.75, -0.75) * r, col, 1.5, true)
		&"two_hand":
			ci.draw_line(c + Vector2(0, 0.5) * r, c + Vector2(0, -0.95) * r, col, 2.0, true)
			ci.draw_line(c + Vector2(-0.55, 0.35) * r, c + Vector2(0.55, 0.35) * r, col, 1.5, true)
			ci.draw_line(c + Vector2(0, 0.35) * r, c + Vector2(0, 0.85) * r, col, 1.5, true)
			ci.draw_circle(c + Vector2(0, 0.92) * r, 0.15 * r, col)
		&"wizard":
			ci.draw_line(c + Vector2(-0.3, 0.95) * r, c + Vector2(0.3, -0.45) * r, col, 1.5, true)
			var d := c + Vector2(0.4, -0.65) * r
			var k := 0.35 * r
			ci.draw_colored_polygon(PackedVector2Array([d + Vector2(0, -k), d + Vector2(k, 0), d + Vector2(0, k),
					d + Vector2(-k, 0)]), Color(0.6, 0.75, 1.0))


## The 16 x 16 class badge (ui-champions.md 15.1): bg (0, 0, 0, 0.75), 1 px `frame_dark` border (`trim_glow` while
## `hot`), radius 3; the class icon 14 x 14 inset 1, or the code glyph. `mouse_filter PASS` + the class tooltip, so a
## click still reaches the slot under it.
class ClassBadge extends Control:
	const SIDE := 16.0
	var class_id: StringName = &""
	var hot := false:
		set(v):
			if v != hot:
				hot = v
				queue_redraw()
	var _icon: Texture2D = null

	func _init() -> void:
		size = Vector2(SIDE, SIDE)
		custom_minimum_size = size
		pivot_offset = size * 0.5
		mouse_filter = Control.MOUSE_FILTER_PASS
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		visible = false

	## Shows class `id` (&"" hides the badge); `tip` = its tooltip text.
	func set_class(id: StringName, tip := "") -> void:
		var icon := ChampionBar.class_icon(id)
		if id != class_id or icon != _icon:
			class_id = id
			_icon = icon
			queue_redraw()
		visible = id != &""
		tooltip_text = tip

	## True when the PNG is drawn (false = the code glyph).
	func uses_icon() -> bool:
		return _icon != null

	## Scale pop 0 -> 1.25 -> 1.0 over 0.3 s (class chosen).
	func pop() -> void:
		scale = Vector2.ZERO
		var t := create_tween()
		t.tween_property(self, "scale", Vector2(1.25, 1.25), 0.15)
		t.tween_property(self, "scale", Vector2.ONE, 0.15)

	func _draw() -> void:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0, 0, 0, 0.75)
		s.border_color = UIStyle.token(&"trim_glow") if hot else UIStyle.token(&"frame_dark")
		s.set_border_width_all(1)
		s.set_corner_radius_all(3)
		draw_style_box(s, Rect2(Vector2.ZERO, size))
		if _icon != null:
			draw_texture_rect(_icon, Rect2(Vector2(1, 1), size - Vector2(2, 2)), false)
		else:
			ChampionBar.draw_class_glyph(self, class_id, size * 0.5, size.x)

	func _make_custom_tooltip(for_text: String) -> Object:
		return ChampionBar.styled_tooltip(for_text) if for_text != "" else null


## A Label with the section-8 tooltip (class / lean tooltips on the inspect title, captions and tavern lines).
class TipLabel extends Label:
	func _make_custom_tooltip(for_text: String) -> Object:
		return ChampionBar.styled_tooltip(for_text) if for_text != "" else null


# ---------------------------------------------------------------- slot

## One 240 x 72 slot (ui-champions.md 3.2): a Button (slot frame states) with the portrait, medallion, name, key
## badge, HP bar, intent and purse; the empty look; the 3.3 animations.
class Slot extends Button:
	var bar: ChampionBar
	var index := 0
	var champion: Node = null
	var state := &"empty"         ## &"empty", &"alive", &"fallen", &"reviving", &"arriving".
	var face: Face
	var medallion: Control
	var level_label: Label
	var name_label: Label
	var key_badge: Panel
	var key_label: Label
	var hp_bar: ProgressBar
	var hp_text: Label
	var intent_label: Label
	var purse_box: HBoxContainer
	var purse_label: Label
	var plus_label: Label
	var hire_label: Label
	var tavern_label: Label
	var fx: Control               ## Top overlay: the level-up ring.
	var class_badge: ClassBadge   ## 16 x 16 at (6, 50): the class, from level 2 (ui-champions.md 15.2).

	var _last_champion: Node = null
	var _last_class: StringName = &""
	var _class_pop_left := 0.0
	var _last_level := -1
	var _last_purse := -1
	var _last_hp := -1.0
	var _last_alive := true
	var _ring_t := -1.0
	var _flash_left := 0.0        ## HP bar white flash (level-up).
	var _heal_left := 0.0
	var _gold_left := 0.0         ## Purse number in GOLD.
	var _unpaid := false
	var _tip_key := ""                  ## U3-9: champion id | class | state the tooltips were built for...
	var _class_tip := ""                ## ...the class badge's tooltip then...
	var _tip_ms := -100000              ## ...and when (ms).
	const TIP_REFRESH_MS := 1000
	var _tween: Tween

	func _ready() -> void:
		custom_minimum_size = ChampionBar.SLOT_SIZE
		size = ChampionBar.SLOT_SIZE
		focus_mode = Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_STOP
		face = Face.new()
		face.inset = 2.0
		face.letter_size = 18
		face.position = Vector2(8, 8)
		face.size = Vector2(ChampionBar.PORTRAIT_SIZE, ChampionBar.PORTRAIT_SIZE)
		face.pivot_offset = face.size * 0.5
		add_child(face)
		plus_label = UIStyle.display_label("+", 26)
		_ignore(plus_label)
		plus_label.position = Vector2(8, 8)
		plus_label.size = Vector2(ChampionBar.PORTRAIT_SIZE, ChampionBar.PORTRAIT_SIZE)
		plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(plus_label)
		# Level medallion 22 x 22 centred at (60, 58).
		medallion = Control.new()
		_ignore(medallion)
		medallion.position = Vector2(49, 47)
		medallion.size = Vector2(22, 22)
		medallion.pivot_offset = Vector2(11, 11)
		medallion.draw.connect(_draw_medallion)
		add_child(medallion)
		# Class badge 16 x 16 at (6, 50): the portrait's lower-left corner (the medallion owns the lower-right).
		class_badge = ClassBadge.new()
		class_badge.position = Vector2(6, 50)
		add_child(class_badge)
		level_label = UIStyle.display_label("1", 11, UIStyle.GOLD)
		_ignore(level_label)
		level_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		medallion.add_child(level_label)
		name_label = UIStyle.display_label("", 15)
		_ignore(name_label)
		name_label.position = Vector2(72, 6)
		name_label.size = Vector2(132, 18)
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		add_child(name_label)
		key_badge = Panel.new()
		_ignore(key_badge)
		key_badge.position = Vector2(208, 7)
		key_badge.size = Vector2(24, 14)
		add_child(key_badge)
		key_label = UIStyle.panel_label(ChampionBar.KEY_NAMES[index], 10, UIStyle.GOLD)
		_ignore(key_label)
		key_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key_badge.add_child(key_label)
		var hp := UIStyle.bar(UIStyle.HP_COLOR, 14.0)
		hp_bar = hp[0]
		hp_text = hp[1]
		hp_text.add_theme_font_size_override("font_size", 10)
		hp_text.add_theme_constant_override("outline_size", 2)
		hp_bar.position = Vector2(72, 26)
		hp_bar.size = Vector2(160, 14)
		hp_bar.custom_minimum_size = Vector2(160, 14)
		add_child(hp_bar)
		intent_label = UIStyle.panel_label("", 12)
		_ignore(intent_label)
		intent_label.position = Vector2(72, 46)
		intent_label.size = Vector2(100, 17)
		intent_label.clip_text = true
		intent_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		add_child(intent_label)
		# Purse: flame 10 x 12 + 4 px + number, right edge at x 232, y 46, max width 56.
		purse_box = HBoxContainer.new()
		_ignore(purse_box)
		purse_box.alignment = BoxContainer.ALIGNMENT_END
		purse_box.add_theme_constant_override("separation", 4)
		purse_box.position = Vector2(176, 46)
		purse_box.size = Vector2(56, 17)
		add_child(purse_box)
		var flame := Control.new()
		_ignore(flame)
		flame.custom_minimum_size = Vector2(10, 12)
		flame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		flame.draw.connect(func() -> void: ChampionBar.draw_flame(flame, Vector2.ZERO, 10.0))
		purse_box.add_child(flame)
		purse_label = UIStyle.number_label("0", 12, UIStyle.ESSENCE_TEXT)
		_ignore(purse_label)
		purse_box.add_child(purse_label)
		hire_label = UIStyle.panel_label("Hire a champion", 12)
		_ignore(hire_label)
		hire_label.position = Vector2(72, 18)
		add_child(hire_label)
		tavern_label = UIStyle.panel_label("Y · tavern", 11, UIStyle.GOLD)
		_ignore(tavern_label)
		tavern_label.position = Vector2(72, 40)
		add_child(tavern_label)
		fx = Control.new()
		_ignore(fx)
		fx.set_anchors_preset(Control.PRESET_FULL_RECT)
		fx.draw.connect(_draw_fx)
		add_child(fx)
		mouse_entered.connect(_update_alpha)
		mouse_exited.connect(_update_alpha)
		apply_skin()
		show_empty(true)

	static func _ignore(c: Control) -> void:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	func apply_skin() -> void:
		UIStyle.style_button(self)
		plus_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
		hire_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		face.apply_skin()
		_style_badge()
		_style_name()
		medallion.queue_redraw()

	func _style_badge() -> void:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0, 0, 0, 0.75)
		s.border_color = UIStyle.WARN if _unpaid else UIStyle.token(&"frame_dark")
		s.set_border_width_all(1)
		s.set_corner_radius_all(2)
		key_badge.add_theme_stylebox_override("panel", s)

	func _style_name() -> void:
		var fallen := state == &"fallen" or state == &"reviving"
		name_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted") if fallen
				else UIStyle.token(&"title"))

	func _set_filled(filled: bool) -> void:
		for c: Control in [face, medallion, name_label, hp_bar, intent_label, purse_box]:
			c.visible = filled
		class_badge.visible = false   # show_champion shows it again when the champion has a class
		plus_label.visible = not filled
		hire_label.visible = not filled
		tavern_label.visible = not filled

	## The empty look: `+`, `Hire a champion`, `Y · tavern` (`Tavern opens at 2:00` while closed).
	func show_empty(open: bool) -> void:
		var was := champion
		champion = null
		if state != &"empty" and was != null:
			_fade_to_empty()
		state = &"empty"
		_last_champion = null
		_set_filled(false)
		var at := ChampionBar.opens_at_text(self)
		tavern_label.text = "Y · tavern" if open else Loc.t("Tavern opens at {time}", {"time": at})
		tavern_label.add_theme_color_override("font_color", UIStyle.GOLD if open else UIStyle.token(&"text_muted"))
		_tip_key = ""   # U3-9: the next champion view rebuilds its tooltip
		tooltip_text = Loc.t("Hire a champion  [Y]\nOpen the tavern (Y) or click a tavern.") + (
				"" if open else "\n" + Loc.t("Tavern opens at {time}", {"time": at}))
		_unpaid = false
		_style_badge()
		_update_alpha()

	## A hire on its way out of the tavern: portrait, name, `Arrives in 3 s` (HP full, level 1).
	func show_pending(id: StringName, display_name: String, left: float) -> void:
		champion = null
		state = &"arriving"
		_set_filled(true)
		purse_box.visible = false
		face.set_face(id, display_name, false)
		name_label.text = display_name
		_style_name()
		level_label.text = "1"
		hp_bar.max_value = 1.0
		hp_bar.value = 1.0
		hp_text.text = ""
		intent_label.text = Loc.t("Arrives in {n} s", {"n": ceili(left)})
		intent_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		_tip_key = ""   # U3-9: the next champion view rebuilds its tooltip
		tooltip_text = "%s  [%s]  %s\n" % [display_name, ChampionBar.KEY_NAMES[index], Loc.t(ChampionBar.title_of(id))] \
				+ Loc.t("Hired: walks out of the tavern in {n} s.", {"n": ceili(left)})
		_update_alpha()

	## Fills the slot with `ch` (alive, fallen or reviving); plays the hire / level / purse / fall animations.
	func show_champion(ch: Node, guild: Node) -> void:
		if ch == null or not is_instance_valid(ch):
			show_empty(ChampionBar.guild_is_open(guild))
			return
		champion = ch
		var alive := ChampionBar.is_alive(ch)
		var left := ChampionBar.revive_left(guild, ch)
		state = &"alive" if alive else (&"reviving" if left > 0.0 else &"fallen")
		_set_filled(true)
		var id := ChampionBar.champion_id(ch)
		var n := ChampionBar.display_name_of(ch)
		face.set_face(id, n, not alive)
		name_label.text = n
		_style_name()
		var level := ChampionBar.level_of(ch)
		level_label.text = str(level)
		level_label.add_theme_color_override("font_color", UIStyle.GOLD if alive else ChampionBar.FALLEN_EDGE)
		var purse := ChampionBar.purse_of(ch)
		purse_label.text = str(purse)
		var max_hp := ChampionBar.max_hp_of(ch)
		var hp := float(ch.get("hp")) if alive and ch.get("hp") != null else 0.0
		hp_bar.max_value = max_hp
		hp_bar.value = hp
		hp_text.text = "%d / %d" % [ceili(hp), int(max_hp)]
		var intent := ChampionBar.intent_text(ch, guild)
		intent_label.text = Loc.sink(intent)
		intent_label.add_theme_color_override("font_color", ChampionBar.intent_color(intent))
		var unpaid := alive and ChampionBar.is_unpaid(ch)
		if unpaid != _unpaid:
			_unpaid = unpaid
			_style_badge()
		# U3-9: the tooltips (long texts) are rebuilt at most once a second, or at once for another champion
		var cid := ChampionBar.class_id_of(ch)
		var now_ms := Time.get_ticks_msec()
		var tip_key := "%d|%s|%s" % [ch.get_instance_id(), cid, state]
		if tip_key != _tip_key or now_ms - _tip_ms >= TIP_REFRESH_MS or tooltip_text == "":
			_tip_key = tip_key
			_tip_ms = now_ms
			tooltip_text = ChampionBar.tooltip_for(ch, guild, ChampionBar.KEY_NAMES[index])
			_class_tip = ChampionBar.class_tooltip_for(ch) if cid != &"" else ""
		class_badge.set_class(cid, _class_tip)   # every refresh: other paths may have hidden the badge
		# 3.3 animations, from what changed since the last refresh.
		if ch != _last_champion:
			if _last_champion == null:
				_play_hired()
			_last_champion = ch
			_last_level = level
			_last_purse = purse
			_last_alive = alive
			_last_hp = hp
			_last_class = cid   # a class loaded from a save: no pop, no message
			face.modulate = Color.WHITE if alive else ChampionBar.FALLEN_TINT
		else:
			if cid != _last_class:
				_last_class = cid
				if cid != &"":
					_play_class_chosen()
					bar.announce_class(ch, cid)   # once per champion (also reached through class_chosen)
			if level > _last_level:
				_play_level_up()
			if purse > _last_purse:
				_play_purse_gain(purse - _last_purse)
			if alive != _last_alive:
				_play_tint(alive)
			if alive and _last_alive and hp > _last_hp + maxf(2.0, max_hp * 0.02):
				_heal_left = 0.15
			_last_level = level
			_last_purse = purse
			_last_alive = alive
			_last_hp = hp
		medallion.queue_redraw()
		_update_alpha()

	## Per frame: low-HP pulse, heal / level flashes, purse gold, ring.
	func tick(delta: float, clock: float) -> void:
		_heal_left = maxf(_heal_left - delta, 0.0)
		_flash_left = maxf(_flash_left - delta, 0.0)
		if _gold_left > 0.0:
			_gold_left -= delta
			if _gold_left <= 0.0:
				purse_label.add_theme_color_override("font_color", UIStyle.ESSENCE_TEXT)
		var fill := UIStyle.HP_COLOR
		if _flash_left > 0.0:
			fill = Color.WHITE
		elif _heal_left > 0.0:
			fill = ChampionBar.HEAL_FLASH
		elif state == &"alive" and hp_bar.value / maxf(hp_bar.max_value, 1.0) < 0.3:
			fill = UIStyle.HP_COLOR.lerp(ChampionBar.LOW_HP, 0.5 + 0.5 * sin(clock * TAU * 1.5))
		UIStyle.set_bar_color(hp_bar, fill)
		if class_badge.visible:
			class_badge.modulate = face.modulate   # fallen: greyed with the portrait
			class_badge.hot = is_hovered()         # hover: trim_glow border like the portrait's
		_class_pop_left = maxf(_class_pop_left - delta, 0.0)
		if _ring_t >= 0.0:
			_ring_t += delta / 0.5
			if _ring_t >= 1.0:
				_ring_t = -1.0
			fx.queue_redraw()

	func _update_alpha() -> void:
		var faded := state == &"empty" and not is_hovered()
		modulate.a = 0.6 if faded else 1.0

	func _play_hired() -> void:
		if _tween:
			_tween.kill()
		modulate.a = 0.0
		face.scale = Vector2.ONE
		_tween = create_tween().set_parallel(true)
		_tween.tween_property(self, "modulate:a", 1.0, 0.2)
		_pop_face()

	func _pop_face() -> void:
		var t := create_tween()
		t.tween_property(face, "scale", Vector2(1.08, 1.08), 0.1)
		t.tween_property(face, "scale", Vector2.ONE, 0.1)

	func _fade_to_empty() -> void:
		if _tween:
			_tween.kill()
		modulate.a = 1.0
		_tween = create_tween()
		_tween.tween_property(self, "modulate:a", 0.6, 0.3)

	func _play_level_up() -> void:
		medallion.scale = Vector2.ONE
		var t := create_tween()
		t.tween_property(medallion, "scale", Vector2(1.4, 1.4), 0.2)
		t.tween_property(medallion, "scale", Vector2.ONE, 0.2)
		_ring_t = 0.0
		_flash_left = 0.2

	func _play_purse_gain(amount: int) -> void:
		_gold_left = 0.3
		purse_label.add_theme_color_override("font_color", UIStyle.GOLD)
		var f := UIStyle.label("+%d" % amount, 11)
		f.add_theme_color_override("font_color", UIStyle.GOLD)
		f.add_theme_constant_override("outline_size", 2)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.position = Vector2(200, 38)
		fx.add_child(f)
		var t := create_tween().set_parallel(true)
		t.tween_property(f, "position:y", f.position.y - 12.0, 0.6)
		t.tween_property(f, "modulate:a", 0.0, 0.6)
		t.chain().tween_callback(f.queue_free)

	func _play_tint(alive: bool) -> void:
		var t := create_tween()
		t.tween_property(face, "modulate", Color.WHITE if alive else ChampionBar.FALLEN_TINT, 0.3)
		if alive:
			_pop_face()

	## Is the level-up ring playing (for tests)?
	func is_ring_playing() -> bool:
		return _ring_t >= 0.0

	## Class chosen (15.2): the badge pops 0 -> 1.25 -> 1.0 over 0.3 s.
	func _play_class_chosen() -> void:
		_class_pop_left = 0.3
		class_badge.pop()

	## Is the class badge pop playing (for tests)?
	func is_class_pop_playing() -> bool:
		return _class_pop_left > 0.0

	## Tooltip (3.4): lines 1-3 in the section-8 look, line 4 in the intent colour, line 5 = four item frames.
	func _make_custom_tooltip(for_text: String) -> Object:
		var lines := for_text.split("\n")
		if champion == null or not is_instance_valid(champion) or lines.size() < 5:
			return ChampionBar.styled_tooltip(for_text)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 3)
		box.add_child(UIStyle.make_tooltip("\n".join(lines.slice(0, 3))))
		var intent := UIStyle.panel_label(lines[3], 13)
		# Colour from the English intent (the line itself may be French).
		intent.add_theme_color_override("font_color", UIStyle.WARN if lines[3].begins_with("Unpaid:")
				or lines[3] == Loc.t("Unpaid: ignores bounties") else ChampionBar.intent_color(
				ChampionBar.intent_text(champion) if Loc.is_french() else lines[3]))
		box.add_child(intent)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var types := ChampionBar.item_types(champion)
		var counts := ChampionBar.item_counts(champion)
		for i in 4:
			row.add_child(ItemIcon.make(types[i], 28.0, int(counts[i])))
		box.add_child(row)
		return box

	func _draw_medallion() -> void:
		var alive := state == &"alive" or state == &"arriving"
		ChampionBar.draw_hex_badge(medallion, Vector2(11, 11), 11.0, UIStyle.GOLD if alive else ChampionBar.FALLEN_EDGE)

	func _draw_fx() -> void:
		if _ring_t < 0.0:
			return
		var c := medallion.position + Vector2(11, 11)
		fx.draw_arc(c, lerpf(12.0, 30.0, _ring_t), 0.0, TAU, 40, Color(UIStyle.GOLD, 1.0 - _ring_t), 3.0, true)


## The hexagonal level medallion (flat top): dark fill, 1.5 px `edge`, 1 px frame_light facet on the upper half.
static func draw_hex_badge(ci: CanvasItem, c: Vector2, r: float, edge: Color) -> void:
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(pts, Color(0.15, 0.12, 0.05))
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, edge, 1.5, true)
	var inner := PackedVector2Array()
	for i in [3, 4, 5, 0]:
		var a := deg_to_rad(60.0 * i)
		inner.append(c + Vector2(cos(a), sin(a)) * (r - 2.5))
	ci.draw_polyline(inner, UIStyle.token(&"frame_light"), 1.0, true)


## The two-tone essence flame (the top bar's), `h` px tall with its top-left at `at`.
static func draw_flame(ci: CanvasItem, at: Vector2, h: float) -> void:
	var s := h / 12.0
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(5, 0) * s, at + Vector2(9, 5.5) * s,
			at + Vector2(8.5, 10) * s, at + Vector2(5, 12) * s, at + Vector2(1.5, 10) * s, at + Vector2(1, 5.5) * s]),
			UIStyle.ESSENCE)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(5, 4.5) * s, at + Vector2(6.8, 8.5) * s,
			at + Vector2(5, 11) * s, at + Vector2(3.2, 8.5) * s]), Color(0.95, 0.80, 1.0))


## The crystal diamond (two-tone), `h` px tall with its top-left at `at`.
static func draw_crystal(ci: CanvasItem, at: Vector2, h: float) -> void:
	var c := at + Vector2(h, h) * 0.5
	var r := h * 0.5
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, 0), c + Vector2(0, r),
			c + Vector2(-r * 0.8, 0)]), UIStyle.CRYSTAL)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(0, 0), c + Vector2(-r * 0.8, 0)]),
			Color(0.75, 0.95, 1.0))


## Portrait tile: gradient background (trim_glow alpha 0.35 -> panel_inner), the champion icon or its initials, and
## a rim (a slot frame in `rim`, or a 1 px groove line when `rim` has alpha 0). Greyed while fallen.
class Face extends Control:
	var champion_id: StringName = &""
	var inset := 2.0
	var letter_size := 18
	var _bg: TextureRect
	var _icon: TextureRect
	var _letters: Label
	var _frame: Panel
	var _rim := Color(0, 0, 0, 0)
	var _key := ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		_bg = TextureRect.new()
		_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_bg.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(_bg)
		_icon = TextureRect.new()
		_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		_icon.offset_left = inset
		_icon.offset_top = inset
		_icon.offset_right = -inset
		_icon.offset_bottom = -inset
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(_icon)
		_letters = UIStyle.display_label("", letter_size)
		_letters.set_anchors_preset(Control.PRESET_FULL_RECT)
		_letters.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_letters.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_letters.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_letters)
		_frame = Panel.new()
		_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_frame)
		apply_skin()

	func apply_skin() -> void:
		if _frame == null:
			return
		var g := Gradient.new()
		var glow := UIStyle.token(&"trim_glow")
		g.set_color(0, Color(glow.r, glow.g, glow.b, 0.35))
		g.set_color(1, UIStyle.token(&"panel_inner"))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_bg.texture = t
		_letters.add_theme_color_override("font_color", UIStyle.token(&"title"))
		_apply_rim()

	## The frame: `rim` alpha 0 = a 1 px groove line (bar portrait), else a slot frame in that colour (tavern tile).
	func set_rim(rim: Color) -> void:
		if rim == _rim:
			return
		_rim = rim
		_apply_rim()

	func _apply_rim() -> void:
		if _rim.a <= 0.0:
			var s := StyleBoxFlat.new()
			s.draw_center = false
			s.border_color = UIStyle.token(&"groove")
			s.set_border_width_all(1)
			_frame.add_theme_stylebox_override("panel", s)
		else:
			var f := UIStyle.button_frame(&"normal", _rim)
			f.draw_center = false
			_frame.add_theme_stylebox_override("panel", f)

	## Shows archetype `id` (initials of `display_name` when there is no icon); `fallen` greys the content.
	func set_face(id: StringName, display_name: String, fallen: bool) -> void:
		var key := "%s|%s|%s" % [id, display_name, fallen]
		if key == _key:
			return
		_key = key
		champion_id = id
		_icon.texture = ChampionBar.icon_of(id)
		_letters.text = "" if _icon.texture != null else ChampionBar.initials(display_name)
		var tint := ChampionBar.FALLEN_TINT if fallen else Color.WHITE
		_icon.modulate = tint
		_letters.modulate = tint
		_bg.modulate = tint

	func is_placeholder() -> bool:
		return _icon.texture == null

	func letters() -> String:
		return _letters.text


## A read-only item slot (ui-style.md 6.3: tier rim, halo on top items, icon or abbreviation, stack count; the item
## tooltip); `type` null = empty (rim (0.3, 0.3, 0.3)).
class ItemIcon extends Panel:
	var item_type: Variant = null
	var count := 0
	var _label: Label
	var _icon: TextureRect
	var _count: Label

	static func make(type: Variant, px: float, n := 1) -> ItemIcon:
		var s := ItemIcon.new()
		s.custom_minimum_size = Vector2(px, px)
		s.size = Vector2(px, px)
		s.set_item(type, n)
		return s

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		_icon = TextureRect.new()
		_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		_icon.offset_left = 2
		_icon.offset_top = 2
		_icon.offset_right = -2
		_icon.offset_bottom = -2
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icon)
		_label = UIStyle.panel_label("", 11)
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)
		_count = UIStyle.label("", 10)
		_count.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_count.position = Vector2(2, -14)
		_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_count)
		draw.connect(_draw_halo)

	func set_item(type: Variant, n := 1) -> void:
		item_type = type
		count = n if type != null else 0
		var rim := ItemTooltip.tier_color(type)
		var frame := UIStyle.button_frame(&"normal", rim)
		if type == null:
			frame = UIStyle.button_frame(&"normal", ItemTooltip.EMPTY_COLOR)
		add_theme_stylebox_override("panel", frame)
		var id := str(ItemTooltip.field(type, &"id", ""))
		_icon.texture = ItemTooltip.HudSkin.icon("items", id) if type != null and id != "" else null
		_label.text = "" if type == null or _icon.texture != null else ItemTooltip.abbrev(type)
		_count.text = str(n) if type != null and n > 1 else ""
		tooltip_text = ItemTooltip.describe(type, "", maxi(n, 1)) if type != null else "Empty item slot"
		queue_redraw()

	func _draw_halo() -> void:
		if item_type == null:
			return
		var t := ItemTooltip.tier(item_type)
		if t == &"top" or t == &"artifact":
			draw_rect(Rect2(Vector2(-2, -2), size + Vector2(4, 4)), Color(ItemTooltip.tier_color(item_type), 0.35), false, 2.0)

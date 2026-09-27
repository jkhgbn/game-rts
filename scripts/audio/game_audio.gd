class_name GameAudio
extends Node3D
## Placeholder sound effects + music (task 6.S1). Add ONE of these to a level, like SpellVfx; it never edits
## gameplay code. Sounds are the .wav files made by tools/generate_sfx.gd (assets/audio/sfx|music/).
## Hooks (SceneTree.node_added, deferred, plus a 1 s rescan of the groups):
##   Unit        attack_landed -> melee_hit (melee) / bolt_impact (ranged) at the target
##               level_changed -> level_up (2D for the player's wizard)
##   Projectile  added -> bolt_shot at the shooter; splash projectiles (Fireball) -> fireball_explode when they end
##   SpellCaster spell_cast -> fireball_cast / spell_<id> at the wizard
##   Champion    ChampionAbilities ability_cast -> ability_cast at the champion, skill_hit -> skill_hit at the target
##               (not the Second Wind heal ticks); files from assets/audio/champion_sfx_generator.gd
##   Level       wizard_fell (Skirmish) of the player's wizard -> alert_wizard_fell (2D)
##   Events      unit_died -> death_fire / death_shadow; artifact_claimed -> crown_claimed; mission_ended -> stinger
##   Building    damaged -> building_hit, destroyed -> building_collapse; player's buildings:
##               construction_finished -> construction_done, unit_trained -> unit_trained
##   Economy     player's workers mining -> mine_tick (polled 2 Hz), gathered_total up -> crystals_delivered,
##               spend_failed -> ui_error (EssenceBank too)
##   Inventory   player's wizard: item_bought / item_used; ItemPickup picked_up -> item_pickup
##   BaseButton  pressed -> ui_click
##   Tiers wave units (UNIT_SFX_FAMILY, switch UNIT_SFX_ENABLED): atk_<family> / hit_<family> / death_<family>
##               replace bolt_shot / melee_hit / bolt_impact / death_* for those units
##               (assets/audio/unit_sfx_generator.gd). UnitVoice child (scripts/audio/unit_voice.gd): voice barks.
## Budget: MAX_VOICES pooled AudioStreamPlayer3D (bus SFX) + UI_VOICES AudioStreamPlayer (bus SFX) + 1 music
## player (bus Music). Each sound has a cooldown, so 50 archers firing at once play a handful of voices.
## When every voice is busy, PRIORITY sounds steal the oldest voice, others are dropped. Sounds from
## units hidden by fog (not visible) or farther than max_hear_distance from the camera are skipped.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const MAX_VOICES := 16
const UI_VOICES := 4
const RESCAN_INTERVAL := 1.0
const MINE_POLL := 0.5
const MINE_TICK_EVERY := 1.0
const MUSIC_DB := -10.0
const DEFAULT_COOLDOWN := 0.08
const META := &"game_audio"

const SOUNDS: Array[StringName] = [
	&"melee_hit", &"bolt_shot", &"bolt_impact", &"fireball_cast", &"fireball_explode",
	&"spell_ember_step", &"spell_kindle", &"spell_shadow_lance", &"spell_soul_siphon", &"spell_umbral_shroud",
	&"death_fire", &"death_shadow", &"building_hit", &"building_collapse", &"construction_done",
	&"unit_trained", &"mine_tick", &"crystals_delivered", &"level_up", &"item_bought", &"item_used",
	&"item_pickup", &"ui_click", &"ui_error", &"crown_claimed", &"victory", &"defeat",
	&"ability_cast", &"skill_hit", &"alert_wizard_fell",
	# Per-family unit SFX (assets/audio/unit_sfx_generator.gd), used through UNIT_SFX_FAMILY.
	&"atk_blade", &"hit_blade", &"death_blade", &"atk_heavy", &"hit_heavy", &"death_heavy",
	&"atk_whip", &"hit_whip", &"death_whip", &"atk_bow", &"hit_bow", &"death_bow",
	&"atk_bolt", &"hit_bolt", &"death_bolt", &"atk_siege", &"hit_siege", &"death_siege",
	&"atk_magic", &"hit_magic", &"death_magic", &"atk_storm", &"hit_storm", &"death_storm",
	&"atk_beast", &"hit_beast", &"death_beast",
]
## Tiers wave units (bowmen, new-units-12, T3 units, T3 helpers + summons): unit type id (or HelperType id) -> SFX
## family. The unit's attack plays atk_<family> (ranged: at the shot, melee: the swing at the attacker), a hit on it
## plays hit_<family> instead of the generic melee_hit / bolt_impact, its death death_<family>. Other units keep the
## generic cues. Switch: UNIT_SFX_ENABLED.
const UNIT_SFX_ENABLED := true
const UNIT_SFX_FAMILY := {
	&"scorchbow": &"bow", &"bleakbow": &"bow", &"frostbow": &"bow", &"wildwood_archer": &"bow",
	&"thistle_darter": &"bow", &"hoarlight_magebow": &"bow", &"helper_aldra": &"bow",
	&"scorchling": &"blade", &"rimeling": &"blade", &"barrow_ghoul": &"blade", &"ashveil_saboteur": &"blade",
	&"hollow_oathsworn": &"heavy", &"greenheart_oathkeeper": &"heavy", &"nightblood_reaver": &"heavy",
	&"shardguard": &"heavy", &"helper_vey": &"heavy",
	&"vinelasher": &"whip", &"cinder_arbalest": &"bolt", &"frost_mortar": &"siege",
	&"pyre_adept": &"magic", &"hexweaver": &"magic", &"helper_hush": &"magic", &"helper_maelis": &"magic",
	&"stormbottle_genie": &"storm", &"briar_roc": &"beast", &"spirit_wolf": &"beast",
}
## Unit voice barks (scripts/audio/unit_voice.gd, load-guarded): a UnitVoice child is added when this is true.
const UNIT_VOICE_SCRIPT := "res://scripts/audio/unit_voice.gd"
## Extra takes of the most frequent combat cues (assets/audio/takes_sfx_generator.gd): play_at picks the original or
## one of these at random (plus the +-7 % pitch), so 100 hits a minute do not sound like one machine gun.
const TAKES := {
	&"melee_hit": ["res://assets/audio/sfx/melee_hit_1.wav", "res://assets/audio/sfx/melee_hit_2.wav"],
	&"bolt_shot": ["res://assets/audio/sfx/bolt_shot_1.wav", "res://assets/audio/sfx/bolt_shot_2.wav"],
	&"bolt_impact": ["res://assets/audio/sfx/bolt_impact_1.wav", "res://assets/audio/sfx/bolt_impact_2.wav"],
	&"building_hit": ["res://assets/audio/sfx/building_hit_1.wav", "res://assets/audio/sfx/building_hit_2.wav"],
	&"mine_tick": ["res://assets/audio/sfx/mine_tick_1.wav", "res://assets/audio/sfx/mine_tick_2.wav"],
}
## Seconds before the same sound can play again (anything missing: DEFAULT_COOLDOWN).
const COOLDOWNS := {
	&"melee_hit": 0.06, &"bolt_shot": 0.07, &"bolt_impact": 0.07, &"building_hit": 0.2,
	&"death_fire": 0.1, &"death_shadow": 0.1, &"mine_tick": 0.15, &"crystals_delivered": 0.3,
	&"ui_click": 0.04, &"ui_error": 0.25, &"level_up": 0.3, &"building_collapse": 0.3,
	&"ability_cast": 0.25, &"skill_hit": 0.15, &"alert_wizard_fell": 2.0,
	&"atk_blade": 0.12, &"hit_blade": 0.12, &"death_blade": 0.15, &"atk_heavy": 0.15, &"hit_heavy": 0.15,
	&"death_heavy": 0.2, &"atk_whip": 0.15, &"hit_whip": 0.15, &"death_whip": 0.2, &"atk_bow": 0.12,
	&"hit_bow": 0.12, &"death_bow": 0.15, &"atk_bolt": 0.15, &"hit_bolt": 0.15, &"death_bolt": 0.2,
	&"atk_siege": 0.25, &"hit_siege": 0.25, &"death_siege": 0.3, &"atk_magic": 0.15, &"hit_magic": 0.15,
	&"death_magic": 0.2, &"atk_storm": 0.2, &"hit_storm": 0.2, &"death_storm": 0.3, &"atk_beast": 0.15,
	&"hit_beast": 0.15, &"death_beast": 0.2,
}
## Volume offsets in dB (loud or frequent sounds are pulled down). Tuned with the Audio Lab (docs/plan/audio-lab.md)
## to the in-game loudness targets of tools/audio_lab/lab_rules.gd.
const VOLUMES := {
	&"melee_hit": -4.0, &"bolt_shot": -8.0, &"bolt_impact": -7.0, &"mine_tick": -8.0,
	&"building_hit": -5.0, &"crystals_delivered": -10.0, &"ui_click": -8.0, &"ui_error": -4.0,
	&"death_fire": -3.0, &"death_shadow": -5.0, &"unit_trained": -4.0, &"item_bought": -4.0, &"item_used": -6.0,
	&"ability_cast": -8.0, &"skill_hit": -6.0,
	&"atk_blade": -6.0, &"hit_blade": -5.0, &"death_blade": -2.0, &"atk_heavy": -6.0, &"hit_heavy": -5.0,
	&"death_heavy": -3.0, &"atk_whip": -6.0, &"hit_whip": -5.0, &"death_whip": -3.5, &"atk_bow": -7.0,
	&"hit_bow": -3.0, &"death_bow": -3.0, &"atk_bolt": -6.0, &"hit_bolt": -5.0, &"death_bolt": -3.0,
	&"atk_siege": -6.0, &"hit_siege": -6.0, &"death_siege": -3.0, &"atk_magic": -6.0, &"hit_magic": -5.0,
	&"death_magic": -3.0, &"atk_storm": -6.0, &"hit_storm": -6.0, &"death_storm": -5.0, &"atk_beast": -6.0,
	&"hit_beast": -5.0, &"death_beast": -4.5,
}
## Class-skill hits that are heals over time (a tick every 0.5 s): no impact sound.
const SILENT_SKILL_HITS: Array[StringName] = [&"second_wind"]
## Sounds that may steal the oldest voice when all are busy.
const PRIORITY: Array[StringName] = [&"fireball_explode", &"fireball_cast", &"building_collapse", &"level_up",
		&"spell_ember_step", &"spell_kindle", &"spell_shadow_lance", &"spell_soul_siphon", &"spell_umbral_shroud"]

## "auto": match music when the scene has a `hero` property (a level), menu music otherwise.
@export_enum("auto", "match", "menu", "none") var music_mode: String = "auto"
## Positional sounds farther than this from the camera are not played at all.
@export var max_hear_distance := 75.0

var play_counts: Dictionary = {}   ## Read only (tests / debug): sound id -> times played.
var dropped := 0                   ## Read only: sounds skipped because every voice was busy.

var _streams: Dictionary = {}      # id -> AudioStream
var _takes: Dictionary = {}        # id -> Array of AudioStream (the original first), only for ids in TAKES
var _voices: Array[AudioStreamPlayer3D] = []
var _voice_until: Array[float] = []   # game time when each voice is free again
var _voice_start: Array[float] = []
var _ui: Array[AudioStreamPlayer] = []
var _ui_next := 0
var _music: AudioStreamPlayer
var _next_ok: Dictionary = {}      # id -> game time it may play again
var _now := 0.0
var _rescan_left := 0.0
var _mine_left := MINE_POLL
var _mine_next: Dictionary = {}    # worker -> game time of its next tick
var _gathered: Dictionary = {}     # player Economy -> last gathered_total
var _ended := false


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	process_mode = Node.PROCESS_MODE_ALWAYS   # UI clicks in the pause menu
	GameSettings.ensure_buses()
	_load_streams()
	_build_players()
	get_tree().node_added.connect(_on_node_added)
	var events := get_node_or_null(^"/root/Events")
	if events:
		if events.has_signal(&"unit_died"):
			events.connect(&"unit_died", _on_unit_died)
		if events.has_signal(&"artifact_claimed"):
			events.connect(&"artifact_claimed", _on_artifact_claimed)
		if events.has_signal(&"mission_ended"):
			events.connect(&"mission_ended", _on_mission_ended)
	_hook_buttons(get_tree().root)
	_rescan()
	_start_music.call_deferred()
	_add_unit_voice()


func _process(delta: float) -> void:
	_now += delta
	_rescan_left -= delta
	if _rescan_left <= 0.0:
		_rescan_left = RESCAN_INTERVAL
		_rescan()
	_mine_left -= delta
	if _mine_left <= 0.0:
		_mine_left = MINE_POLL
		_poll_mining()


# ---------------------------------------------------------------- public API

## Plays sound `id` at a world position (pooled 3D voice, bus SFX). Returns false when it was skipped
## (cooldown, too far, no free voice, missing file).
func play_at(id: StringName, pos: Vector3) -> bool:
	var stream: AudioStream = _streams.get(id)
	if stream == null or not _cooldown_ok(id):
		return false
	var cam: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam and cam.global_position.distance_to(pos) > max_hear_distance:
		return false
	var idx := _free_voice()
	if idx < 0:
		if not PRIORITY.has(id):
			dropped += 1
			return false
		idx = _oldest_voice()
	_next_ok[id] = _now + float(COOLDOWNS.get(id, DEFAULT_COOLDOWN))
	if _takes.has(id):
		stream = (_takes[id] as Array).pick_random()
	var v := _voices[idx]
	v.stop()
	v.stream = stream
	v.global_position = pos
	v.volume_db = float(VOLUMES.get(id, 0.0))
	v.pitch_scale = randf_range(0.93, 1.07)
	v.play()
	_voice_start[idx] = _now
	_voice_until[idx] = _now + stream.get_length() / v.pitch_scale
	_count(id)
	return true


## Plays sound `id` without position (UI, stingers, the player's own wizard). Returns false when skipped.
func play_ui(id: StringName) -> bool:
	var stream: AudioStream = _streams.get(id)
	if stream == null or not _cooldown_ok(id):
		return false
	_next_ok[id] = _now + float(COOLDOWNS.get(id, DEFAULT_COOLDOWN))
	var p := _ui[_ui_next]
	_ui_next = (_ui_next + 1) % _ui.size()
	p.stop()
	p.stream = stream
	p.volume_db = float(VOLUMES.get(id, 0.0))
	p.play()
	_count(id)
	return true


## The SFX family of a unit (UNIT_SFX_FAMILY), &"" = the generic cues.
static func unit_sfx_family(n: Node) -> StringName:
	if not UNIT_SFX_ENABLED or not is_instance_valid(n):
		return &""
	return UNIT_SFX_FAMILY.get(unit_type_id(n), &"")


## A unit's type id: its UnitType id, a Helper's HelperType id, else &"".
static func unit_type_id(n: Node) -> StringName:
	if not is_instance_valid(n):
		return &""
	for prop: StringName in [&"unit_type", &"helper_type"]:
		var t: Variant = n.get(prop)
		if t is Object and is_instance_valid(t):
			var id: Variant = (t as Object).get(&"id")
			if id != null:
				return StringName(id)
	return &""


## Voices (3D) playing right now.
func active_voice_count() -> int:
	var n := 0
	for t in _voice_until:
		if t > _now:
			n += 1
	return n


func voice_count() -> int:
	return _voices.size()


## Switches music: "match", "menu" or "none".
func set_music(mode: String) -> void:
	if _music == null:
		return
	if mode == "none":
		_music.stop()
		return
	var s: AudioStream = _streams.get(StringName("music_" + mode))
	if s == null:
		return
	if _music.stream == s and _music.playing:
		return
	_music.stream = s
	_music.volume_db = -40.0
	_music.play()
	create_tween().tween_property(_music, "volume_db", MUSIC_DB, 2.0)


# ---------------------------------------------------------------- hooking

func _on_node_added(node: Node) -> void:
	if node is Unit or node is Building or node is ItemPickup:
		_hook.call_deferred(node)
	elif node is Projectile:
		_hook_projectile.call_deferred(node)   # deferred: launch_* runs right after add_child
	elif node is BaseButton:
		_hook_button(node)
	elif node is Economy or node is EssenceBank:
		_hook.call_deferred(node)


func _rescan() -> void:
	var tree := get_tree()
	for group: StringName in [&"units", &"buildings", &"item_pickups", &"economies", &"essence_banks"]:
		for node in tree.get_nodes_in_group(group):
			if not node.has_meta(META):
				_hook(node)
	# Wizards whose SpellCaster / Inventory appeared after the first hook.
	for group: StringName in [&"heroes", &"enemy_heroes"]:
		for node in tree.get_nodes_in_group(group):
			_hook_wizard(node)
	for node in tree.get_nodes_in_group(&"champions"):
		_hook_champion(node)
	_hook_level()


func _hook(node: Variant) -> void:
	if not is_instance_valid(node):
		return
	var n := node as Node
	if n.has_meta(META):
		return
	n.set_meta(META, true)
	if n is Unit:
		n.connect(&"attack_landed", _on_attack_landed.bind(n))
		n.connect(&"level_changed", _on_level_changed)
		if n is Wizard:
			_hook_wizard(n)
		elif n.is_in_group(&"champions"):
			_hook_champion(n)
	elif n is Building:
		n.connect(&"damaged", _on_building_damaged.bind(n))
		n.connect(&"destroyed", _on_building_destroyed)
		n.connect(&"construction_finished", _on_construction_finished)
		if n.has_signal(&"unit_trained"):
			n.connect(&"unit_trained", _on_unit_trained.bind(n))
	elif n is ItemPickup:
		n.connect(&"picked_up", _on_picked_up)
	elif n is Economy:
		if int(n.get(&"team")) == Unit.Team.PLAYER:
			_gathered[n] = int(n.get(&"gathered_total"))
			n.connect(&"changed", _on_economy_changed.bind(n))
			n.connect(&"spend_failed", _on_spend_failed)
	elif n is EssenceBank:
		if int(n.get(&"team")) == Unit.Team.PLAYER:
			n.connect(&"spend_failed", _on_spend_failed)


func _hook_wizard(w: Node) -> void:
	if not is_instance_valid(w):
		return
	var caster := w.get_node_or_null(^"SpellCaster")
	if caster and caster.has_signal(&"spell_cast") and not caster.has_meta(META):
		caster.set_meta(META, true)
		caster.connect(&"spell_cast", _on_spell_cast.bind(w))
	if not w.is_in_group(&"heroes"):
		return
	var inv: Variant = w.get(&"inventory")
	if is_instance_valid(inv) and inv is Node and not (inv as Node).has_meta(META):
		var i := inv as Node
		i.set_meta(META, true)
		if i.has_signal(&"item_bought"):
			i.connect(&"item_bought", func(_t: Variant) -> void: play_ui(&"item_bought"))
		if i.has_signal(&"item_used"):
			i.connect(&"item_used", func(_s: int, _t: Variant) -> void: play_ui(&"item_used"))


## A champion's "ChampionAbilities" child (scripts/units/champion_abilities.gd): ability_cast -> ability_cast at the
## champion, skill_hit -> skill_hit at the target (heal ticks stay silent).
func _hook_champion(c: Node) -> void:
	if not is_instance_valid(c):
		return
	var ab := c.get_node_or_null(^"ChampionAbilities")
	if ab == null or ab.has_meta(META):
		return
	ab.set_meta(META, true)
	if ab.has_signal(&"ability_cast"):
		ab.connect(&"ability_cast", _on_ability_cast.bind(c))
	if ab.has_signal(&"skill_hit"):
		ab.connect(&"skill_hit", _on_skill_hit.bind(c))


## The level's "your wizard has fallen" event (Skirmish.wizard_fell(wizard, respawn_in)): GameAudio is a child of the
## level, else the current scene has it.
func _hook_level() -> void:
	var levels: Array[Node] = [get_parent(), get_tree().current_scene]
	for lvl in levels:
		if lvl != null and lvl.has_signal(&"wizard_fell") and not lvl.is_connected(&"wizard_fell", _on_wizard_fell):
			lvl.connect(&"wizard_fell", _on_wizard_fell)


func _hook_projectile(node: Variant) -> void:
	if not is_instance_valid(node) or not (node as Node).is_inside_tree():
		return
	var p := node as Projectile
	if p == null or p.has_meta(META):
		return
	p.set_meta(META, true)
	if p.splash_radius > 0.0:
		p.tree_exiting.connect(_on_splash_gone.bind(p), CONNECT_ONE_SHOT)
		return
	if p.has_meta(&"spell_vfx"):
		return   # a spell projectile (Shadow Lance): the spell_cast sound covers it
	var src: Variant = p.source
	if is_instance_valid(src) and _audible(src as Node3D):
		var fam := unit_sfx_family(src as Node)
		play_at(&"bolt_shot" if fam == &"" else StringName("atk_" + String(fam)), (src as Node3D).global_position + Vector3.UP)


func _hook_buttons(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node)
	for c in node.get_children():
		_hook_buttons(c)


func _hook_button(b: BaseButton) -> void:
	if not b.pressed.is_connected(_on_button_pressed):
		b.pressed.connect(_on_button_pressed)


# ---------------------------------------------------------------- events

func _on_attack_landed(target: Variant, _amount: float, attacker: Node3D) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	var t := target as Node3D
	if not _audible(attacker) and not _audible(t):
		return
	var range_v: Variant = attacker.get(&"attack_range")
	var ranged := range_v != null and float(range_v) > 3.0
	var atk_fam := unit_sfx_family(attacker)
	if atk_fam != &"" and not ranged and _audible(attacker):
		play_at(StringName("atk_" + String(atk_fam)), attacker.global_position + Vector3.UP)   # the swing
	var hit_fam := unit_sfx_family(t)
	if hit_fam != &"":
		play_at(StringName("hit_" + String(hit_fam)), t.global_position + Vector3.UP)
	elif atk_fam == &"" or ranged:
		play_at(&"bolt_impact" if ranged else &"melee_hit", t.global_position + Vector3.UP)


func _on_level_changed(unit: Variant, _level: int) -> void:
	if not is_instance_valid(unit):
		return
	var u := unit as Node3D
	if u.is_in_group(&"heroes"):
		play_ui(&"level_up")
	elif _audible(u):
		play_at(&"level_up", u.global_position)


func _on_spell_cast(id: StringName, w: Node3D) -> void:
	if not is_instance_valid(w):
		return
	var sid := &"fireball_cast" if id == &"fireball" else StringName("spell_" + String(id))
	if w.is_in_group(&"heroes") or _audible(w):
		play_at(sid, w.global_position + Vector3.UP)


func _on_ability_cast(_id: StringName, champion: Node3D) -> void:
	if is_instance_valid(champion) and _audible(champion):
		play_at(&"ability_cast", champion.global_position + Vector3.UP)


func _on_skill_hit(id: StringName, target: Variant, _amount: float, champion: Node3D) -> void:
	if SILENT_SKILL_HITS.has(id) or not is_instance_valid(target) or not (target is Node3D):
		return
	var t := target as Node3D
	if _audible(t) or (is_instance_valid(champion) and _audible(champion)):
		play_at(&"skill_hit", t.global_position + Vector3.UP)


## Only the local player's wizard: the enemy's fall is good news (its message is enough).
func _on_wizard_fell(wizard: Variant, _respawn_in: float) -> void:
	if is_instance_valid(wizard) and int((wizard as Node).get(&"team")) == Unit.Team.PLAYER:
		play_ui(&"alert_wizard_fell")


func _on_splash_gone(p: Projectile) -> void:
	if is_inside_tree() and not is_queued_for_deletion():
		play_at(&"fireball_explode", p.global_position)


func _on_unit_died(unit: Variant) -> void:
	if not is_instance_valid(unit):
		return
	var u := unit as Node3D
	var fam := unit_sfx_family(u)
	if fam != &"":
		play_at(StringName("death_" + String(fam)), u.global_position + Vector3.UP)
		return
	play_at(&"death_shadow" if _is_shadow(u) else &"death_fire", u.global_position + Vector3.UP)


func _on_building_damaged(_amount: float, _attacker: Variant, b: Node3D) -> void:
	if is_instance_valid(b) and _audible(b):
		play_at(&"building_hit", b.global_position + Vector3.UP * 1.5)


func _on_building_destroyed(b: Variant) -> void:
	if is_instance_valid(b):
		play_at(&"building_collapse", (b as Node3D).global_position)


func _on_construction_finished(b: Variant) -> void:
	if is_instance_valid(b) and int((b as Node).get(&"team")) == Unit.Team.PLAYER:
		play_at(&"construction_done", (b as Node3D).global_position)


func _on_unit_trained(unit: Variant, b: Node3D) -> void:
	if not is_instance_valid(b) or int(b.get(&"team")) != Unit.Team.PLAYER:
		return
	var pos := (unit as Node3D).global_position if is_instance_valid(unit) else b.global_position
	play_at(&"unit_trained", pos)


func _on_picked_up(_pickup: Variant, wizard: Variant, _type: Variant) -> void:
	if is_instance_valid(wizard):
		var w := wizard as Node3D
		if w.is_in_group(&"heroes"):
			play_ui(&"item_pickup")
		elif _audible(w):
			play_at(&"item_pickup", w.global_position)


func _on_economy_changed(eco: Node) -> void:
	if not is_instance_valid(eco):
		return
	var total := int(eco.get(&"gathered_total"))
	if total > int(_gathered.get(eco, total)):
		play_ui(&"crystals_delivered")
	_gathered[eco] = total


func _on_spend_failed() -> void:
	play_ui(&"ui_error")


func _on_button_pressed() -> void:
	play_ui(&"ui_click")


func _on_artifact_claimed(_artifact: Variant, _wizard: Variant) -> void:
	play_ui(&"crown_claimed")


func _on_mission_ended(victory: bool) -> void:
	if _ended:
		return
	_ended = true
	if _music and _music.playing:
		var tw := create_tween()
		tw.tween_property(_music, "volume_db", -40.0, 1.0)
		tw.tween_callback(_music.stop)
	play_ui(&"victory" if victory else &"defeat")


## Player's workers that are mining tick about once a second (each worker on its own clock).
func _poll_mining() -> void:
	for node in get_tree().get_nodes_in_group(&"units"):
		var w := node as Worker
		if w == null or w.team != Unit.Team.PLAYER:
			continue
		if w.gather_state != Worker.GatherState.MINING:
			_mine_next.erase(w)
			continue
		var next: float = _mine_next.get(w, _now + randf() * MINE_TICK_EVERY)
		if _now >= next:
			next = _now + MINE_TICK_EVERY
			play_at(&"mine_tick", w.global_position + Vector3.UP)
		_mine_next[w] = next
	for w in _mine_next.keys():
		if not is_instance_valid(w):
			_mine_next.erase(w)


# ---------------------------------------------------------------- helpers

func _cooldown_ok(id: StringName) -> bool:
	return _now >= float(_next_ok.get(id, -1.0))


func _free_voice() -> int:
	for i in _voices.size():
		if _voice_until[i] <= _now:
			return i
	return -1


func _oldest_voice() -> int:
	var best := 0
	for i in _voices.size():
		if _voice_start[i] < _voice_start[best]:
			best = i
	return best


func _count(id: StringName) -> void:
	play_counts[id] = int(play_counts.get(id, 0)) + 1


## Hidden by fog (or not in the tree) = silent, so sounds never give away enemies.
func _audible(n: Node3D) -> bool:
	return is_instance_valid(n) and n.is_inside_tree() and n.is_visible_in_tree()


func _is_shadow(n: Node) -> bool:
	var ut: Variant = n.get(&"unit_type")
	if ut != null and is_instance_valid(ut):
		return StringName((ut as Object).get(&"faction")) == &"shadow"
	var bc: Variant = n.get(&"body_color")
	return bc is Color and (bc as Color).b > (bc as Color).r


func _load_streams() -> void:
	for id in SOUNDS:
		var path := SFX_DIR + String(id) + ".wav"
		if ResourceLoader.exists(path):
			_streams[id] = load(path)
	for id: StringName in TAKES:
		if not _streams.has(id):
			continue
		var takes: Array = [_streams[id]]
		for p: String in TAKES[id]:
			if ResourceLoader.exists(p):
				takes.append(load(p))
		if takes.size() > 1:
			_takes[id] = takes
	for id: StringName in [&"music_match", &"music_menu"]:
		var path := MUSIC_DIR + String(id) + ".wav"
		if not ResourceLoader.exists(path):
			continue
		var s: AudioStream = load(path)
		if s is AudioStreamWAV:
			var wav := (s as AudioStreamWAV).duplicate() as AudioStreamWAV
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
			s = wav
		_streams[id] = s


func _build_players() -> void:
	for i in MAX_VOICES:
		var v := AudioStreamPlayer3D.new()
		v.bus = &"SFX"
		v.unit_size = 18.0
		v.max_distance = max_hear_distance
		v.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		v.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		add_child(v)
		_voices.append(v)
		_voice_until.append(-1.0)
		_voice_start.append(-1.0)
	for i in UI_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_ui.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.volume_db = MUSIC_DB
	add_child(_music)


## UnitVoice (scripts/audio/unit_voice.gd): load-guarded, a missing / broken script = no barks, never an error.
func _add_unit_voice() -> void:
	if not ResourceLoader.exists(UNIT_VOICE_SCRIPT):
		return
	var s := load(UNIT_VOICE_SCRIPT) as GDScript
	if s == null or not s.can_instantiate() or not bool(s.get_script_constant_map().get("ENABLED", false)):
		return
	var n := s.new() as Node
	if n:
		n.name = "UnitVoice"
		add_child(n)


func _start_music() -> void:
	var mode := music_mode
	if mode == "auto":
		var scene := get_tree().current_scene
		mode = "match" if scene != null and &"hero" in scene else "menu"
	set_music(mode)

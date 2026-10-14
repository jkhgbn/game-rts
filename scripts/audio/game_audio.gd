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
##   Tiers wave orders (docs/design/sound-plan.md, SOUND_PLAN; files assets/audio/order_sfx_generator.gd), all hooked
##               here through signals / public state (no gameplay edits): keep tier upgrade (polled), UnitUpgrades "+",
##               HelperRoster / HelperAbilities, StrIntPath, bowmen effects, new-units-12 / T3 ability counters
##               (polled), Tab building cycle (SelectionManager, polled), NextStepHint step, restart, caravans.
## Takes: every id with <id>_1.wav / <id>_2.wav next to it (TAKES + TAKE_IDS) picks one at random, never the same
## take twice in a row.
## Music (MU13 / MU14): MusicDirector (scripts/audio/music_director.gd, a child of /root) plays it; `set_music` maps to
## its contexts and this node feeds it the player's combat intensity every INTENSITY_POLL s (docs/design/music.md 4).
## Budget: MAX_VOICES pooled AudioStreamPlayer3D (bus SFX) + UI_VOICES AudioStreamPlayer (bus SFX). Each sound has a cooldown, so 50 archers firing at once play a handful of voices.
## When every voice is busy, PRIORITY sounds steal the oldest voice, others are dropped. Sounds from
## units hidden by fog (not visible) or farther than max_hear_distance from the camera are skipped.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const MAX_VOICES := 16
const UI_VOICES := 4
const RESCAN_INTERVAL := 1.0
const MINE_POLL := 0.5
const MINE_TICK_EVERY := 1.0
const MUSIC_DB := -10.0   ## MusicDirector.MUSIC_DB (the music level, kept for the Audio Lab scan)
## Combat intensity (music.md 4): enemy combat units within INTENSITY_BUILDING_R m of an own building or
## INTENSITY_WIZARD_R m of the own wizard, n / INTENSITY_FULL; INTENSITY_HIT for INTENSITY_HIT_S s after an own
## building / the wizard takes damage. Wave Strike: units within INTENSITY_BASTION_R m of the own bastion, or its damage.
const INTENSITY_POLL := 0.5
const INTENSITY_BUILDING_R := 20.0
const INTENSITY_WIZARD_R := 16.0
const INTENSITY_BASTION_R := 25.0
const INTENSITY_FULL := 12.0
const INTENSITY_HIT := 0.6
const INTENSITY_HIT_S := 4.0
const DEFAULT_COOLDOWN := 0.08
const META := &"_game_audio"   ## "_": never saved (a rebuilt node must be hooked again; review R5-2)

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
	# Tiers wave orders (assets/audio/order_sfx_generator.gd), see SOUND_PLAN.
	&"ui_tier_start", &"ui_tier_tick", &"alert_tier_stronghold", &"alert_tier_citadel", &"ui_upgrade_cancel",
	&"ui_plus_start", &"alert_plus_done",
	&"ui_helper_call", &"alert_helper_arrive", &"alert_helper_fall", &"alert_helper_revive", &"helper_cast",
	&"alert_path_str", &"alert_path_int", &"spell_vigor_on", &"spell_vigor_off", &"spell_snow_shield_on",
	&"spell_snow_shield_off",
	&"fx_chill", &"fx_burn", &"fx_bleed", &"fx_crit",
	&"ab_flashpoint", &"ab_flame_burst", &"ab_piercing_bolt", &"ab_grave_feast", &"ab_wither_hex", &"ab_unbroken_vow",
	&"ab_frost_needle", &"ab_frost_shell", &"ab_skitter", &"ab_snare_lash", &"ab_grove_oath",
	&"ab_sab_disguise", &"ab_sab_reveal", &"ab_sab_plant", &"ab_sab_armed", &"ab_sab_blast", &"ab_blood_frenzy",
	&"ab_hold_the_line", &"ab_challenge", &"ab_seed_storm", &"ab_genie_chain", &"ab_tempest_bolt",
	&"ui_tab", &"ui_hint", &"ui_restart", &"alert_caravan_trained",
]
## THE sound plan (docs/design/sound-plan.md): every order / action added on 2026-09-27 -> its cue and where it is
## hooked. tests/test_sound_plan.gd checks each cue has a file, is in SOUNDS and is played by this script.
const SOUND_PLAN := {
	&"ui_tier_start": "Keep.is_upgrading() false -> true (player keep, polled)",
	&"ui_tier_tick": "Keep.upgrade_progress() crosses 25 / 50 / 75 % (player keep, polled)",
	&"alert_tier_stronghold": "Keep.tier_changed(keep, 2) after an upgrade (player)",
	&"alert_tier_citadel": "Keep.tier_changed(keep, 3) after an upgrade (player)",
	&"ui_upgrade_cancel": "keep upgrade stopped without a new tier (polled) / UnitUpgrades.upgrade_cancelled (player)",
	&"ui_plus_start": "UnitUpgrades.upgrade_started (player)",
	&"alert_plus_done": "UnitUpgrades.upgrade_completed (player)",
	&"ui_helper_call": "HelperRoster.helper_called (player)",
	&"alert_helper_arrive": "HelperRoster.helper_ready (player)",
	&"alert_helper_fall": "HelperRoster.helper_fallen (player)",
	&"alert_helper_revive": "HelperRoster.helper_revived (player)",
	&"helper_cast": "HelperAbilities.ability_cast (any team, audible)",
	&"alert_path_str": "StrIntPath.path_chosen(&\"str\") (player wizard)",
	&"alert_path_int": "StrIntPath.path_chosen(&\"int\") (player wizard)",
	&"spell_vigor_on": "StrIntPath.ability_started(&\"str\")",
	&"spell_vigor_off": "StrIntPath.ability_ended(&\"str\")",
	&"spell_snow_shield_on": "StrIntPath.ability_started(&\"int\")",
	&"spell_snow_shield_off": "StrIntPath.ability_ended(&\"int\")",
	&"fx_chill": "attack_landed of a Frostbow / Rimeling on a unit (chill)",
	&"fx_burn": "attack_landed of a Scorchbow on a unit (burn)",
	&"fx_bleed": "attack_landed of a Bleakbow on a unit (bleed stack)",
	&"fx_crit": "Wildwood Archer shot whose crit accumulator wrapped (BowmanKit CRIT_META, at the projectile)",
	&"ab_flashpoint": "Scorchling death (Flashpoint burst)",
	&"ab_flame_burst": "NewUnitAbility.casts + 1 on a Pyre Adept (polled)",
	&"ab_piercing_bolt": "NewUnitAbility.casts + 1 on a Cinder Arbalest (polled)",
	&"ab_grave_feast": "NewUnitAbility.casts + 1 on a Barrow Ghoul (polled)",
	&"ab_wither_hex": "NewUnitAbility.casts + 1 on a Hexweaver (polled)",
	&"ab_unbroken_vow": "NewUnitAbility.casts + 1 on a Hollow Oathsworn (polled)",
	&"ab_frost_needle": "NewUnitAbility.casts + 1 on a Hoarlight Magebow (polled)",
	&"ab_frost_shell": "NewUnitAbility.casts + 1 on a Frost Mortar (splash, polled)",
	&"ab_skitter": "NewUnitAbility.casts + 1 on a Thistle Darter (polled)",
	&"ab_snare_lash": "NewUnitAbility.casts + 1 on a Vinelasher (polled)",
	&"ab_grove_oath": "NewUnitAbility.casts + 1 on a Greenheart Oathkeeper (taunt, polled)",
	&"ab_sab_disguise": "T3Ability.disguised false -> true (own Saboteur, polled)",
	&"ab_sab_reveal": "T3Ability.disguised true -> false (polled)",
	&"ab_sab_plant": "T3Ability.planting false -> true (polled)",
	&"ab_sab_armed": "T3Ability.casts[powder_charge] + 1 (polled)",
	&"ab_sab_blast": "powder charge armed + T3UnitAbility CHARGE fuse (5 s)",
	&"ab_blood_frenzy": "T3Ability.casts[blood_frenzy] + 1 (polled)",
	&"ab_hold_the_line": "T3Ability.casts[hold_the_line] + 1 (polled)",
	&"ab_challenge": "T3Ability.casts[challenge] + 1 (Shardguard taunt, polled)",
	&"ab_seed_storm": "T3Ability.casts[seed_storm] + 1 (polled)",
	&"ab_genie_chain": "attack_landed of a Stormbottle Genie (chain bolts)",
	&"ab_tempest_bolt": "T3Ability.casts[tempest_bolt] + 1 (polled)",
	&"ui_tab": "SelectionManager.selected_building changes inside the same 2+ building selection (Tab, polled)",
	&"ui_hint": "NextStepHint.step changes (polled)",
	&"ui_restart": "the same level scene reloads within RESTART_WINDOW_MS (F9 / Restart button)",
	&"alert_caravan_trained": "unit_trained of a caravan (UnitType.is_caravan, 0 supply)",
}
## New-units-12 ability cue per unit type id (the NewUnitAbility child's `casts` counter goes up). Scorchling: death.
const NU_ABILITY_CUE := {
	&"pyre_adept": &"ab_flame_burst", &"cinder_arbalest": &"ab_piercing_bolt", &"barrow_ghoul": &"ab_grave_feast",
	&"hexweaver": &"ab_wither_hex", &"hollow_oathsworn": &"ab_unbroken_vow", &"hoarlight_magebow": &"ab_frost_needle",
	&"frost_mortar": &"ab_frost_shell", &"thistle_darter": &"ab_skitter", &"vinelasher": &"ab_snare_lash",
	&"greenheart_oathkeeper": &"ab_grove_oath",
}
## T3 unit ability cue per ability id (the T3Ability child's `casts` dictionary).
const T3_ABILITY_CUE := {
	&"powder_charge": &"ab_sab_armed", &"blood_frenzy": &"ab_blood_frenzy", &"hold_the_line": &"ab_hold_the_line",
	&"challenge": &"ab_challenge", &"seed_storm": &"ab_seed_storm", &"tempest_bolt": &"ab_tempest_bolt",
}
## Bowman on-hit effect cue per attacker type id (plays at the victim, units only).
const HIT_FX_CUE := {&"frostbow": &"fx_chill", &"rimeling": &"fx_chill", &"scorchbow": &"fx_burn",
	&"bleakbow": &"fx_bleed"}
const CRIT_META := &"bowman_crit_acc"        ## BowmanKit.CRIT_META (read only).
const CHARGE_FUSE := 5.0                      ## T3UnitAbility.CHARGE["fuse"] (read when the class exists).
const ORDER_POLL := 0.1
const RESTART_WINDOW_MS := 6000
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
## Ids whose takes are SFX_DIR <id>_1.wav / <id>_2.wav (unit_sfx_generator.gd: the 27 family cues x 3 = 81 files;
## order_sfx_generator.gd TAKES). Missing files are skipped.
const TAKE_IDS: Array[StringName] = [
	&"atk_blade", &"hit_blade", &"death_blade", &"atk_heavy", &"hit_heavy", &"death_heavy",
	&"atk_whip", &"hit_whip", &"death_whip", &"atk_bow", &"hit_bow", &"death_bow",
	&"atk_bolt", &"hit_bolt", &"death_bolt", &"atk_siege", &"hit_siege", &"death_siege",
	&"atk_magic", &"hit_magic", &"death_magic", &"atk_storm", &"hit_storm", &"death_storm",
	&"atk_beast", &"hit_beast", &"death_beast",
	&"fx_chill", &"fx_burn", &"fx_bleed", &"fx_crit", &"ab_frost_shell", &"ab_skitter", &"ab_genie_chain",
	&"ab_piercing_bolt", &"helper_cast", &"ui_tab",
]
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
	&"ui_tier_tick": 0.2, &"ui_tab": 0.04, &"ui_hint": 0.5, &"ui_restart": 1.0, &"helper_cast": 0.2,
	&"fx_chill": 0.12, &"fx_burn": 0.12, &"fx_bleed": 0.12, &"fx_crit": 0.1, &"ab_flashpoint": 0.12,
	&"ab_piercing_bolt": 0.15, &"ab_grave_feast": 0.2, &"ab_frost_shell": 0.2, &"ab_skitter": 0.15,
	&"ab_genie_chain": 0.15, &"ab_flame_burst": 0.25, &"ab_wither_hex": 0.2, &"ab_unbroken_vow": 0.25,
	&"ab_frost_needle": 0.15, &"ab_snare_lash": 0.2, &"ab_grove_oath": 0.25, &"ab_blood_frenzy": 0.25,
	&"ab_hold_the_line": 0.25, &"ab_challenge": 0.25, &"ab_seed_storm": 0.25, &"ab_tempest_bolt": 0.25,
	&"ab_sab_blast": 0.3, &"alert_caravan_trained": 0.3, &"ab_sab_disguise": 0.3, &"ab_sab_reveal": 0.3,
	&"ab_sab_plant": 0.3, &"ab_sab_armed": 0.3, &"alert_tier_stronghold": 1.0, &"alert_tier_citadel": 1.0, &"alert_plus_done": 0.3,
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
	&"ui_tier_start": -6.0, &"ui_tier_tick": -4.0, &"alert_tier_stronghold": -3.0, &"alert_tier_citadel": -2.0,
	&"ui_upgrade_cancel": -6.0, &"ui_plus_start": -6.0, &"alert_plus_done": -4.0, &"ui_helper_call": -6.0,
	&"alert_helper_arrive": -2.0, &"alert_helper_fall": -4.0, &"alert_helper_revive": -2.0, &"helper_cast": -5.0,
	&"alert_path_str": -2.5, &"alert_path_int": -4.0,
	&"fx_chill": -6.0, &"fx_burn": -6.0, &"fx_bleed": -6.0, &"fx_crit": -6.0, &"ab_flashpoint": -5.0,
	&"ab_flame_burst": -4.0, &"ab_piercing_bolt": -6.0, &"ab_grave_feast": -5.0, &"ab_wither_hex": -5.0,
	&"ab_unbroken_vow": -5.0, &"ab_frost_needle": -6.0, &"ab_frost_shell": -6.0, &"ab_skitter": -7.0,
	&"ab_snare_lash": -5.0, &"ab_grove_oath": -5.0, &"ab_sab_disguise": -5.0, &"ab_sab_reveal": -5.0,
	&"ab_sab_plant": -5.0, &"ab_sab_armed": -5.0, &"ab_sab_blast": -4.0, &"ab_blood_frenzy": -5.0,
	&"ab_hold_the_line": -5.0, &"ab_challenge": -5.0, &"ab_seed_storm": -5.0, &"ab_genie_chain": -6.0,
	&"ab_tempest_bolt": -4.0, &"ui_tab": -4.0, &"ui_hint": -8.0, &"ui_restart": -8.0, &"alert_caravan_trained": -1.0,
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
## Own random numbers (pitch, takes, mine ticks): never the global RNG, which gameplay and seeded replays share.
var _rng := RandomNumberGenerator.new()
var _music: MusicDirector = null   # the shared director (made by MusicDirector.ensure)
var _intensity_left := INTENSITY_POLL
var _hit_until := -1.0             # game time until which an own building / the wizard was hit
var last_intensity := 0.0          ## Read only (tests): the raw intensity sent last.
var _next_ok: Dictionary = {}      # id -> game time it may play again
var _now := 0.0
var _rescan_left := 0.0
var _mine_left := MINE_POLL
var _mine_next: Dictionary = {}    # worker -> game time of its next tick
var _gathered: Dictionary = {}     # player Economy -> last gathered_total
var _ended := false
var _last_take: Dictionary = {}    # id -> index of the take played last (no immediate repeat)
var _order_left := ORDER_POLL
var _abilities: Array[Dictionary] = []   # {node, unit, kind: &"nu" / &"t3", last, disguised, planting}
var _keeps: Dictionary = {}        # player Keep -> {up: bool, quarter: int}
var _selection: Node = null        # SelectionManager (found by duck typing)
var _sel_active: Node = null
var _sel_sig := 0
var _hint: Node = null             # NextStepHint
var _hint_step: StringName = &""

## Restart detection: the scene a GameAudio left last and when (a reload of the same level = restart).
static var _left_scene := ""
static var _left_msec := -100000


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	process_mode = Node.PROCESS_MODE_ALWAYS   # UI clicks in the pause menu
	_rng.randomize()
	GameSettings.ensure_buses()
	_music = MusicDirector.ensure(get_tree())
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
	_order_left -= delta
	if _order_left <= 0.0:
		_order_left = ORDER_POLL
		_poll_orders()
	_intensity_left -= delta
	if _intensity_left <= 0.0:
		_intensity_left = INTENSITY_POLL
		_feed_intensity()


func _exit_tree() -> void:
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene != null and scene.scene_file_path != "":
		_left_scene = scene.scene_file_path
		_left_msec = Time.get_ticks_msec()


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
	stream = pick_take(id, stream)
	var v := _voices[idx]
	v.stop()
	v.stream = stream
	v.global_position = pos
	v.volume_db = float(VOLUMES.get(id, 0.0))
	v.pitch_scale = _rng.randf_range(0.93, 1.07)
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
	p.stream = pick_take(id, stream)
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


## Switches music: "match", "menu" or "none" (MusicDirector contexts; "match" reads the level's kingdoms / mode).
func set_music(mode: String) -> void:
	if _music == null:
		return
	if mode == "none":
		_music.set_music_context(&"none")
	elif mode == "menu":
		_music.set_music_context(&"menu")
	elif mode == "match":
		var scene := get_tree().current_scene if is_inside_tree() else null
		if scene != null and &"hero" in scene:
			_music.apply_scene(scene)
		else:
			_music.set_music_context(&"match")


## The raw combat intensity of the player's side now (0-1, before the director's rise / hold / fall).
func measure_intensity() -> float:
	var tree := get_tree()
	var level := tree.current_scene
	var ws := level != null and level.has_method(&"bastion_ratio")
	var centres: Array[Vector3] = []
	var radii: Array[float] = []
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for b in tree.get_nodes_in_group(&"buildings"):
		var bn := b as Node3D
		if bn == null or not (&"team" in bn) or int(bn.get(&"team")) != Unit.Team.PLAYER:
			continue
		if bn.has_method(&"is_alive") and not bool(bn.call(&"is_alive")):
			continue
		if ws and not (bn is Keep):
			continue
		var r := INTENSITY_BASTION_R if ws else INTENSITY_BUILDING_R
		centres.append(bn.global_position)
		radii.append(r)
	if not ws and level != null and &"hero" in level:
		var hero: Variant = level.get(&"hero")
		if hero is Unit and is_instance_valid(hero) and (hero as Unit).is_alive():
			centres.append((hero as Unit).global_position)
			radii.append(INTENSITY_WIZARD_R)
	for i in centres.size():
		lo = Vector2(minf(lo.x, centres[i].x - radii[i]), minf(lo.y, centres[i].z - radii[i]))
		hi = Vector2(maxf(hi.x, centres[i].x + radii[i]), maxf(hi.y, centres[i].z + radii[i]))
	var n := 0
	if not centres.is_empty():
		for node in tree.get_nodes_in_group(&"units"):
			var u := node as Unit
			if u == null or u.team == Unit.Team.PLAYER or not u.is_alive() or not _is_combat_unit(u):
				continue
			if u.team == Unit.Team.NEUTRAL and u.attack_target == null:
				continue   # neutral camps / beasts count only while they fight
			var p := u.global_position
			if p.x < lo.x or p.x > hi.x or p.z < lo.y or p.z > hi.y:
				continue
			for i in centres.size():
				var d := Vector2(p.x - centres[i].x, p.z - centres[i].z)
				if d.length_squared() <= radii[i] * radii[i]:
					n += 1
					break
			if n >= int(INTENSITY_FULL):
				break
	var v := clampf(float(n) / INTENSITY_FULL, 0.0, 1.0)
	if _now < _hit_until:
		v = maxf(v, INTENSITY_HIT)
	return v


static func _is_combat_unit(u: Unit) -> bool:
	if u.has_method(&"command_gather") or u.is_in_group(&"game_critters") or u.is_in_group(&"caravans"):
		return false
	var t: Variant = u.get(&"unit_type")
	if t is Object and is_instance_valid(t) and bool((t as Object).get(&"is_caravan")):
		return false
	return true


func _feed_intensity() -> void:
	if _music == null or _ended:
		return
	var level := get_tree().current_scene
	if level == null or not (&"hero" in level):
		return
	last_intensity = measure_intensity()
	_music.set_combat_intensity(last_intensity)


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
	_hook_orders()


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
		_hook_unit_orders(n)
	elif n is Building:
		if n.has_signal(&"tier_changed") and n.has_method(&"is_upgrading"):
			n.connect(&"tier_changed", _on_keep_tier_changed)
			if int(n.get(&"team")) == Unit.Team.PLAYER:
				_keeps[n] = {"up": bool(n.call(&"is_upgrading")), "quarter": 0}
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
	# STR / INT path (scripts/units/str_int_path.gd): pick, Vigor / Snow Shield on / off.
	var sip := w.get_node_or_null(^"StrIntPath")
	if sip and sip.has_signal(&"path_chosen") and not sip.has_meta(META):
		sip.set_meta(META, true)
		sip.connect(&"path_chosen", _on_path_chosen.bind(w))
		if sip.has_signal(&"ability_started"):
			sip.connect(&"ability_started", _on_path_ability.bind(w, true))
		if sip.has_signal(&"ability_ended"):
			sip.connect(&"ability_ended", _on_path_ability.bind(w, false))
	if not w.is_in_group(&"heroes"):
		return
	if int(w.get(&"team")) == Unit.Team.PLAYER and w.has_signal(&"damage_taken") \
			and not w.is_connected(&"damage_taken", _on_hero_damaged):
		w.connect(&"damage_taken", _on_hero_damaged)
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
		_check_crit(src as Node3D)


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
	# Bowmen / Rimeling on-hit effects and the Genie's chain bolts (units only, like BowmanKit.on_hit).
	if t is Unit and _audible(t):
		var aid := unit_type_id(attacker)
		var fx: StringName = HIT_FX_CUE.get(aid, &"")
		if fx != &"":
			play_at(fx, t.global_position + Vector3.UP * 1.2)
		elif aid == &"stormbottle_genie":
			play_at(&"ab_genie_chain", t.global_position + Vector3.UP * 1.2)


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
	if unit_type_id(u) == &"scorchling" and _audible(u):
		play_at(&"ab_flashpoint", u.global_position + Vector3.UP * 0.6)   # Flashpoint: bursts on death
	var fam := unit_sfx_family(u)
	if fam != &"":
		play_at(StringName("death_" + String(fam)), u.global_position + Vector3.UP)
		return
	play_at(&"death_shadow" if _is_shadow(u) else &"death_fire", u.global_position + Vector3.UP)


func _on_building_damaged(_amount: float, _attacker: Variant, b: Node3D) -> void:
	if is_instance_valid(b) and int(b.get(&"team")) == Unit.Team.PLAYER:
		var level := get_tree().current_scene
		if level == null or not level.has_method(&"bastion_ratio") or b is Keep:
			_hit_until = _now + INTENSITY_HIT_S   # combat intensity (Wave Strike: the bastion only)
	if is_instance_valid(b) and _audible(b):
		play_at(&"building_hit", b.global_position + Vector3.UP * 1.5)


## The player's wizard took damage: combat intensity INTENSITY_HIT for a while (not in Wave Strike: bastion only).
func _on_hero_damaged(amount: float, _attacker: Variant) -> void:
	var level := get_tree().current_scene if is_inside_tree() else null
	if amount > 0.0 and (level == null or not level.has_method(&"bastion_ratio")):
		_hit_until = _now + INTENSITY_HIT_S


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
	var ut: Variant = (unit as Node).get(&"unit_type") if is_instance_valid(unit) else null
	if ut is Object and is_instance_valid(ut) and bool((ut as Object).get(&"is_caravan")):
		play_at(&"alert_caravan_trained", pos)   # Bazaar caravan (0 supply): cart + coins
		return
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
	# MusicDirector fades the music and plays sting_victory / sting_defeat (it hears mission_ended itself); the old
	# victory / defeat SFX only when that sting file is missing.
	if not MusicDirector.has_track(&"sting_victory" if victory else &"sting_defeat"):
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
		var next: float = _mine_next.get(w, _now + _rng.randf() * MINE_TICK_EVERY)
		if _now >= next:
			next = _now + MINE_TICK_EVERY
			play_at(&"mine_tick", w.global_position + Vector3.UP)
		_mine_next[w] = next
	for w in _mine_next.keys():
		if not is_instance_valid(w):
			_mine_next.erase(w)


# ---------------------------------------------------------------- tiers wave orders (SOUND_PLAN)

## Team-wide order nodes (found by group, duck-typed so a broken / missing feature script never breaks audio):
## UnitUpgrades, HelperRoster, the SelectionManager and the NextStepHint.
func _hook_orders() -> void:
	var tree := get_tree()
	for n in tree.get_nodes_in_group(&"unit_upgrades"):
		if n.has_meta(META) or not n.has_signal(&"upgrade_started"):
			continue
		n.set_meta(META, true)
		n.connect(&"upgrade_started", _on_plus.bind(n, &"ui_plus_start"))
		if n.has_signal(&"upgrade_completed"):
			n.connect(&"upgrade_completed", _on_plus.bind(n, &"alert_plus_done"))
		if n.has_signal(&"upgrade_cancelled"):
			n.connect(&"upgrade_cancelled", func(_id: StringName, _refund: int) -> void:
				if is_instance_valid(n) and int(n.get(&"team")) == Unit.Team.PLAYER:
					play_ui(&"ui_upgrade_cancel"))
	# UR.U2 (ui-sc2-console.md 7.6): unit research (player): start = the "+" start cue, complete = the building-done
	# chime, cancel = the upgrade-cancel cue.
	for n in tree.get_nodes_in_group(&"unit_research"):
		if n.has_meta(META) or not n.has_signal(&"research_completed"):
			continue
		n.set_meta(META, true)
		var started := {}   # a load's granted rows were never started here: no chime
		for b in tree.get_nodes_in_group(&"buildings"):   # started before this hook found the node (the first buy)
			var wid: StringName = n.call(&"working_at", b)
			if wid != &"":
				started[wid] = true
		n.connect(&"research_started", func(id: StringName) -> void:
			started[id] = true
			if is_instance_valid(n) and int(n.get(&"team")) == Unit.Team.PLAYER:
				play_ui(&"ui_plus_start"))
		n.connect(&"research_completed", func(id: StringName) -> void:
			if started.has(id) and is_instance_valid(n) and int(n.get(&"team")) == Unit.Team.PLAYER:
				play_ui(&"construction_done"))
		n.connect(&"research_cancelled", func(_id: StringName, _refund: int) -> void:
			if is_instance_valid(n) and int(n.get(&"team")) == Unit.Team.PLAYER:
				play_ui(&"ui_upgrade_cancel"))
	for n in tree.get_nodes_in_group(&"helper_rosters"):
		if n.has_meta(META) or not n.has_signal(&"helper_ready"):
			continue
		n.set_meta(META, true)
		if n.has_signal(&"helper_called"):
			n.connect(&"helper_called", _on_helper_called)
		n.connect(&"helper_ready", _on_helper_event.bind(&"alert_helper_arrive"))
		if n.has_signal(&"helper_fallen"):
			n.connect(&"helper_fallen", _on_helper_event.bind(&"alert_helper_fall"))
		if n.has_signal(&"helper_revived"):
			n.connect(&"helper_revived", _on_helper_event.bind(&"alert_helper_revive"))
	for n in tree.get_nodes_in_group(&"helpers"):
		_hook_unit_orders(n)
	var scene := tree.current_scene
	if scene != null and not is_instance_valid(_selection):
		_selection = null
		for c in scene.get_children():
			if c.has_signal(&"groups_changed") and &"selected_buildings" in c and &"selected_building" in c:
				_selection = c
				break
	if scene != null and not is_instance_valid(_hint):
		_hint = scene.find_child("NextStepHint", true, false)
		if _hint != null:
			_hint_step = StringName(str(_hint.get(&"step")))


## A unit's ability children: NewUnitAbility (new-units-12, `casts` int), T3Ability (T3 units, `casts` dict,
## `disguised`, `planting`), HelperAbilities (signal ability_cast).
func _hook_unit_orders(u: Node) -> void:
	if not is_instance_valid(u):
		return
	for nm: String in ["NewUnitAbility", "T3Ability"]:
		var a := u.get_node_or_null(NodePath(nm))
		if a == null or a.has_meta(META) or not (&"casts" in a):
			continue
		a.set_meta(META, true)
		var nu := nm == "NewUnitAbility"
		var c: Variant = a.get(&"casts")
		_abilities.append({"node": a, "unit": u, "kind": &"nu" if nu else &"t3",
			"last": (c as Dictionary).duplicate() if c is Dictionary else int(c),
			"disguised": bool(a.get(&"disguised")) if &"disguised" in a else false,
			"planting": bool(a.get(&"planting")) if &"planting" in a else false})
	var ha := u.get_node_or_null(^"HelperAbilities")
	if ha and ha.has_signal(&"ability_cast") and not ha.has_meta(META):
		ha.set_meta(META, true)
		ha.connect(&"ability_cast", _on_helper_cast.bind(u))


## 10 Hz: ability counters, keep upgrades, the Tab cycle, the next-step hint.
func _poll_orders() -> void:
	var i := _abilities.size() - 1
	while i >= 0:
		var e: Dictionary = _abilities[i]
		if not is_instance_valid(e["node"]) or not is_instance_valid(e["unit"]):
			_abilities.remove_at(i)
		else:
			_poll_ability(e)
		i -= 1
	for k: Variant in _keeps.keys():
		if not is_instance_valid(k):
			_keeps.erase(k)
			continue
		var st: Dictionary = _keeps[k]
		var up := bool((k as Object).call(&"is_upgrading"))
		if up and not bool(st["up"]):
			play_ui(&"ui_tier_start")
			st["quarter"] = 0
		elif not up and bool(st["up"]) and not bool(st.get("done", false)):
			play_ui(&"ui_upgrade_cancel")   # stopped without reaching the new tier
		if up:
			var q := int(float((k as Object).call(&"upgrade_progress")) * 4.0)
			if q > int(st["quarter"]) and q < 4:
				play_ui(&"ui_tier_tick")
			st["quarter"] = maxi(q, int(st["quarter"]))
		st["up"] = up
		st["done"] = false
	_poll_selection()
	if is_instance_valid(_hint):
		var s := StringName(str(_hint.get(&"step")))
		if s != _hint_step:
			if _hint_step != &"" and s != &"" and (_hint as CanvasItem).is_visible_in_tree():
				play_ui(&"ui_hint")
			_hint_step = s


func _poll_ability(e: Dictionary) -> void:
	var a: Node = e["node"]
	var u := e["unit"] as Node3D
	var c: Variant = a.get(&"casts")
	if e["kind"] == &"nu":
		var n := int(c)
		if n > int(e["last"]):
			var cue: StringName = NU_ABILITY_CUE.get(unit_type_id(u), &"")
			if cue != &"" and _audible(u):
				play_at(cue, u.global_position + Vector3.UP)
		e["last"] = n
		return
	var d: Dictionary = c if c is Dictionary else {}
	var last: Dictionary = e["last"]
	for ab: StringName in d:
		if int(d[ab]) <= int(last.get(ab, 0)):
			continue
		var cue: StringName = T3_ABILITY_CUE.get(ab, &"")
		if cue != &"" and _audible(u):
			play_at(cue, u.global_position + Vector3.UP)
		if ab == &"powder_charge":
			_arm_blast(u.global_position)
	e["last"] = d.duplicate()
	var own := int(u.get(&"team")) == Unit.Team.PLAYER
	if &"disguised" in a:
		var dis := bool(a.get(&"disguised"))
		if dis != bool(e["disguised"]):
			if not dis and _audible(u):
				play_at(&"ab_sab_reveal", u.global_position + Vector3.UP)
			elif dis and own:
				play_at(&"ab_sab_disguise", u.global_position + Vector3.UP)   # never betrays an enemy one
			e["disguised"] = dis
	if &"planting" in a:
		var pl := bool(a.get(&"planting"))
		if pl and not bool(e["planting"]) and _audible(u):
			play_at(&"ab_sab_plant", u.global_position + Vector3.UP * 0.5)
		e["planting"] = pl


## The powder charge goes off CHARGE fuse seconds after it is armed (T3UnitAbility), where it was planted.
func _arm_blast(at: Vector3) -> void:
	var fuse := CHARGE_FUSE
	var t3: Variant = load("res://scripts/units/t3_unit_ability.gd") if ResourceLoader.exists("res://scripts/units/t3_unit_ability.gd") else null
	if t3 is Script:
		var ch: Variant = (t3 as Script).get_script_constant_map().get("CHARGE")
		if ch is Dictionary:
			fuse = float((ch as Dictionary).get("fuse", CHARGE_FUSE))
	get_tree().create_timer(fuse, false, true).timeout.connect(func() -> void:
		if is_inside_tree():
			play_at(&"ab_sab_blast", at + Vector3.UP))


## Tab / Shift+Tab: the active building changed while the same 2+ buildings stay selected.
func _poll_selection() -> void:
	if not is_instance_valid(_selection):
		return
	var list: Variant = _selection.get(&"selected_buildings")
	var active: Variant = _selection.get(&"selected_building")
	var sig := 0
	var count := 0
	if list is Array:
		count = (list as Array).size()
		for b: Variant in list:
			sig = hash([sig, (b as Object).get_instance_id() if is_instance_valid(b) else 0])
	var act: Node = active as Node if is_instance_valid(active) else null
	if count >= 2 and sig == _sel_sig and act != _sel_active and act != null:
		play_ui(&"ui_tab")
	_sel_sig = sig
	_sel_active = act


## Wildwood Archer crits: BowmanKit.shot_damage wraps the crit accumulator (CRIT_META) on a crit.
func _check_crit(src: Node3D) -> void:
	if unit_type_id(src) != &"wildwood_archer" or not src.has_meta(CRIT_META):
		return
	var acc := float(src.get_meta(CRIT_META))
	var before := float(src.get_meta(&"_game_audio_crit", 0.5))
	src.set_meta(&"_game_audio_crit", acc)
	if acc < before:
		play_at(&"fx_crit", src.global_position + Vector3.UP * 1.5)


func _on_keep_tier_changed(keep: Variant, tier: int) -> void:
	if not is_instance_valid(keep) or not _keeps.has(keep):
		return   # enemy keeps (and cheats on a keep that was not upgrading) stay silent
	var st: Dictionary = _keeps[keep]
	if not bool(st["up"]):
		return
	st["up"] = false
	st["done"] = true
	if tier >= 3:
		play_ui(&"alert_tier_citadel")
	elif tier == 2:
		play_ui(&"alert_tier_stronghold")


## (Literal ids in each play call: the Audio Lab reads 2D / 3D per cue from them.)
func _on_plus(_id: StringName, node: Node, cue: StringName) -> void:
	if not is_instance_valid(node) or int(node.get(&"team")) != Unit.Team.PLAYER:
		return
	if cue == &"alert_plus_done":
		play_ui(&"alert_plus_done")
	else:
		play_ui(&"ui_plus_start")


func _on_helper_called(team: int, _helper_id: StringName) -> void:
	if team == Unit.Team.PLAYER:
		play_ui(&"ui_helper_call")


func _on_helper_event(helper: Variant, cue: StringName) -> void:
	if not is_instance_valid(helper) or int((helper as Node).get(&"team")) != Unit.Team.PLAYER:
		return
	match cue:
		&"alert_helper_arrive":
			play_ui(&"alert_helper_arrive")
		&"alert_helper_fall":
			play_ui(&"alert_helper_fall")
		&"alert_helper_revive":
			play_ui(&"alert_helper_revive")


func _on_helper_cast(_id: StringName, helper: Node3D) -> void:
	if is_instance_valid(helper) and _audible(helper):
		play_at(&"helper_cast", helper.global_position + Vector3.UP)


func _on_path_chosen(path: StringName, w: Node3D) -> void:
	if not is_instance_valid(w) or not w.is_in_group(&"heroes"):
		return
	if path == &"str":
		play_ui(&"alert_path_str")
	elif path == &"int":
		play_ui(&"alert_path_int")


func _on_path_ability(path: StringName, w: Node3D, on: bool) -> void:
	if not is_instance_valid(w) or not (w.is_in_group(&"heroes") or _audible(w)):
		return
	var at := w.global_position + Vector3.UP
	if path == &"str":
		if on:
			play_at(&"spell_vigor_on", at)
		else:
			play_at(&"spell_vigor_off", at)
	elif path == &"int":
		if on:
			play_at(&"spell_snow_shield_on", at)
		else:
			play_at(&"spell_snow_shield_off", at)


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


## One of the id's takes at random, never the one played last (a single take: `stream` itself).
func pick_take(id: StringName, stream: AudioStream) -> AudioStream:
	var takes: Array = _takes.get(id, [])
	if takes.size() < 2:
		return stream
	var last := int(_last_take.get(id, -1))
	var i := _rng.randi() % (takes.size() - 1)
	if last >= 0 and i >= last:
		i += 1   # skip the last one: the others stay equally likely
	elif last < 0:
		i = _rng.randi() % takes.size()
	_last_take[id] = i
	return takes[i]


## Takes loaded for `id` (1 = no extra takes). Tests / debug.
func take_count(id: StringName) -> int:
	return maxi(1, (_takes.get(id, []) as Array).size()) if _streams.has(id) else 0


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
	for id: StringName in TAKE_IDS:
		if not _streams.has(id) or _takes.has(id):
			continue
		var takes: Array = [_streams[id]]
		for k in [1, 2]:
			var p := SFX_DIR + "%s_%d.wav" % [id, k]
			if ResourceLoader.exists(p):
				takes.append(load(p))
		if takes.size() > 1:
			_takes[id] = takes


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
	var cur := get_tree().current_scene
	if cur != null and cur.scene_file_path != "" and cur.scene_file_path == _left_scene \
			and Time.get_ticks_msec() - _left_msec <= RESTART_WINDOW_MS:
		_left_scene = ""
		play_ui(&"ui_restart")   # F9 / the end screen's Restart reloaded this level
	var mode := music_mode
	if mode == "auto":
		var scene := get_tree().current_scene
		mode = "match" if scene != null and &"hero" in scene else "menu"
	set_music(mode)

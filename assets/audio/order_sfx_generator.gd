extends "res://assets/audio/unit_sfx_generator.gd"
## Sounds for every order / action added on 2026-09-27 (tiers wave), docs/design/sound-plan.md. Same building blocks
## and take machinery as unit_sfx_generator.gd (sine / noise / envelopes, no samples, all original):
##   keep tier upgrade (start / progress tick / Stronghold / Citadel / cancel), "+" unit upgrade (start / done),
##   T3 helper (call / arrival / fall / revive / ability), STR / INT pick + Vigor / Snow Shield on / off,
##   bowmen effects (chill / burn / bleed / crit), new-units-12 + T3 unit abilities, building Tab cycle, next-step
##   hint, restart, caravan trained (0 supply).
## Frequent cues (TAKES) also get <id>_1.wav / <id>_2.wav, loudness-matched to take 0.
## Run: godot --headless --path . -s assets/audio/order_sfx_generator.gd --quit-after 10, then --import.
## Deterministic (fixed seed).

## Every cue this generator writes (GameAudio.SOUND_PLAN keys; tests/test_sound_plan.gd checks the files).
const CUES: Array[String] = [
	"ui_tier_start", "ui_tier_tick", "alert_tier_stronghold", "alert_tier_citadel", "ui_upgrade_cancel",
	"ui_plus_start", "alert_plus_done",
	"ui_helper_call", "alert_helper_arrive", "alert_helper_fall", "alert_helper_revive", "helper_cast",
	"alert_path_str", "alert_path_int", "spell_vigor_on", "spell_vigor_off", "spell_snow_shield_on",
	"spell_snow_shield_off",
	"fx_chill", "fx_burn", "fx_bleed", "fx_crit",
	"ab_flashpoint", "ab_flame_burst", "ab_piercing_bolt", "ab_grave_feast", "ab_wither_hex", "ab_unbroken_vow",
	"ab_frost_needle", "ab_frost_shell", "ab_skitter", "ab_snare_lash", "ab_grove_oath",
	"ab_sab_disguise", "ab_sab_reveal", "ab_sab_plant", "ab_sab_armed", "ab_sab_blast", "ab_blood_frenzy",
	"ab_hold_the_line", "ab_challenge", "ab_seed_storm", "ab_genie_chain", "ab_tempest_bolt",
	"ui_tab", "ui_hint", "ui_restart", "alert_caravan_trained",
]
## Frequent cues: 3 takes each.
const TAKES: Array[String] = ["fx_chill", "fx_burn", "fx_bleed", "fx_crit", "ab_frost_shell", "ab_skitter",
	"ab_genie_chain", "ab_piercing_bolt", "helper_cast", "ui_tab"]


func _initialize() -> void:
	_rng.seed = 270928
	for id in CUES:
		call("_" + id)
	for t in [1, 2]:
		_set_take(t)
		for id in TAKES:
			call("_" + id)
	_set_take(0)
	print("order_sfx_generator: %d files" % _count)
	quit()


# ---------------------------------------------------------------- keep tiers / "+" upgrades (UI, 2D)

## Stone and gears: a low mallet knock + a rising two-note chime (work begins).
func _ui_tier_start() -> void:
	_new(0.5)
	_noise(0.0, 0.08, 0.6, 0.001, 8.0, 0.4, 0.2)
	_tone(0.0, 0.1, 220.0, 160.0, 0.5, 7.0)
	_bell(0.1, 0.35, 784.0, 0.35)
	_bell(0.2, 0.3, 1046.5, 0.3)
	_save("ui_tier_start", 0.5)


## A soft hammer tick (each 25 % of the keep upgrade).
func _ui_tier_tick() -> void:
	_new(0.16)
	_noise(0.0, 0.05, 0.6, 0.0008, 9.0, 0.6, 0.3)
	_tone(0.0, 0.14, 1320.0, 1250.0, 0.35, 8.0, TRI)
	_save("ui_tier_tick", 0.4)


## Stronghold: a brass fanfare fifth + a bell (clear good news).
func _alert_tier_stronghold() -> void:
	_new(1.3)
	for f in [392.0, 587.33]:
		_tone(0.0, 0.3, f, f, 0.4, 2.0, SQUARE, 0.01)
	for f in [523.25, 659.25, 783.99]:
		_tone(0.28, 1.0, f, f, 0.35, 2.4, SQUARE, 0.015)
	_bell(0.28, 1.0, 1567.98, 0.3)
	_save("alert_tier_stronghold", 0.82)


## Citadel: a bigger chord that climbs a step higher, with a low drum.
func _alert_tier_citadel() -> void:
	_new(1.7)
	_tone(0.0, 0.3, 110.0, 70.0, 0.6, 5.0)
	_noise(0.0, 0.2, 0.5, 0.002, 6.0, 0.3, 0.1)
	for f in [392.0, 493.88, 587.33]:
		_tone(0.0, 0.35, f, f, 0.3, 2.0, SQUARE, 0.01)
	for f in [523.25, 659.25, 783.99, 1046.5]:
		_tone(0.33, 1.35, f, f, 0.3, 2.2, SQUARE, 0.015, 5.0, 0.004)
	_bell(0.33, 1.3, 2093.0, 0.25)
	_save("alert_tier_citadel", 0.82)


## Cancelled (keep upgrade or "+"): two falling soft notes.
func _ui_upgrade_cancel() -> void:
	_new(0.32)
	_tone(0.0, 0.14, 660.0, 640.0, 0.45, 3.0, TRI, 0.004)
	_tone(0.14, 0.18, 440.0, 420.0, 0.45, 4.0, TRI, 0.004)
	_bell(0.0, 0.14, 2640.0, 0.35)
	_bell(0.14, 0.18, 2349.3, 0.35)
	_save("ui_upgrade_cancel", 0.45)


## "+" research starts: a quill scratch + a rising pluck.
func _ui_plus_start() -> void:
	_new(0.34)
	_noise(0.0, 0.12, 0.35, 0.005, 4.0, 0.5, 0.8, true)
	_tone(0.06, 0.26, 700.0, 1400.0, 0.45, 5.0, TRI)
	_save("ui_plus_start", 0.45)


## "+" researched: a sparkling arpeggio upward (smaller than the tier fanfares).
func _alert_plus_done() -> void:
	_new(0.8)
	var arp := [659.25, 830.61, 987.77, 1318.5]
	for i in arp.size():
		_bell(i * 0.07, 0.7 - i * 0.07, arp[i], 0.4)
	_tone(0.0, 0.75, 329.63, 329.63, 0.2, 2.5, TRI, 0.03)
	_save("alert_plus_done", 0.75)


# ---------------------------------------------------------------- T3 helpers

## Call sent: a far horn call (short).
func _ui_helper_call() -> void:
	_new(0.6)
	_tone(0.0, 0.55, 294.0, 311.0, 0.5, 2.0, SAW, 0.05, 5.0, 0.01)
	_tone(0.0, 0.55, 440.0, 466.0, 0.25, 2.5, SAW, 0.05)
	_noise(0.0, 0.4, 0.15, 0.05, 3.0, 0.5, 0.8, true)
	_bell(0.0, 0.45, 2349.3, 0.4)   # presence: reads on small speakers
	_save("ui_helper_call", 0.5)


## Arrival: a whoosh that lands + a heroic interval.
func _alert_helper_arrive() -> void:
	_new(1.2)
	_noise(0.0, 0.4, 0.6, 0.2, 1.5, 0.05, 0.6, true)
	_tone(0.35, 0.2, 180.0, 90.0, 0.6, 5.0)
	for f in [440.0, 659.25, 880.0]:
		_tone(0.38, 0.8, f, f, 0.3, 2.4, SQUARE, 0.01)
	_bell(0.38, 0.8, 1760.0, 0.22)
	_save("alert_helper_arrive", 0.8)


## Fallen: a low falling minor call (bad news, not the wizard's alarm).
func _alert_helper_fall() -> void:
	_new(1.2)
	_tone(0.0, 0.4, 392.0, 380.0, 0.45, 2.0, SAW, 0.02)
	_tone(0.35, 0.8, 311.13, 290.0, 0.45, 2.5, SAW, 0.02)
	_tone(0.35, 0.8, 1244.5, 1160.0, 0.12, 4.0, TRI, 0.02)
	_tone(0.35, 0.8, 155.56, 146.0, 0.3, 2.0, SINE, 0.05)
	_save("alert_helper_fall", 0.8)


## Revived: a warm swell up into a major chord.
func _alert_helper_revive() -> void:
	_new(1.1)
	_noise(0.0, 0.5, 0.4, 0.3, 2.0, 0.05, 0.3)
	for f in [392.0, 493.88, 587.33]:
		_tone(0.0, 1.05, f * 0.5, f, 0.3, 2.0, TRI, 0.2)
	_bell(0.45, 0.6, 1174.66, 0.3)
	_save("alert_helper_revive", 0.8)


## A helper ability (any of the 12): a bright magic flare, short.
func _helper_cast() -> void:
	_new(0.45)
	_noise(0.0, 0.3, 0.5, 0.02, 3.0, 0.2, 0.7, true)
	_tone(0.0, 0.4, 440.0, 990.0, 0.45, 3.0, SAW, 0.02)
	_tone(0.0, 0.4, 660.0, 1320.0, 0.2, 3.5, SINE, 0.02)
	_save("helper_cast", 0.7)


# ---------------------------------------------------------------- STR / INT path

## STR picked: a war drum hit + a low horn fifth.
func _alert_path_str() -> void:
	_new(1.0)
	_tone(0.0, 0.3, 120.0, 60.0, 0.8, 5.0)
	_noise(0.0, 0.2, 0.6, 0.002, 6.0, 0.35, 0.1)
	_tone(0.1, 0.85, 196.0, 196.0, 0.35, 2.0, SAW, 0.03)
	_tone(0.1, 0.85, 293.66, 293.66, 0.3, 2.0, SAW, 0.03)
	_tone(0.1, 0.85, 1174.66, 1174.66, 0.08, 3.0, TRI, 0.03)
	_save("alert_path_str", 0.8)


## INT picked: shimmering crystal bells in a rising triad.
func _alert_path_int() -> void:
	_new(1.0)
	for i in 4:
		_bell(i * 0.08, 0.9 - i * 0.08, [659.25, 830.61, 987.77, 1318.5][i], 0.35)
	_tone(0.0, 0.9, 329.63, 329.63, 0.18, 2.0, SINE, 0.1, 5.0, 0.01)
	_save("alert_path_int", 0.8)


## Vigor on: a strong heartbeat + a rising warm roar.
func _spell_vigor_on() -> void:
	_new(0.8)
	_tone(0.0, 0.14, 90.0, 60.0, 0.8, 5.0)
	_tone(0.22, 0.14, 90.0, 60.0, 0.7, 5.0)
	_noise(0.0, 0.75, 0.5, 0.1, 2.5, 0.08, 0.35)
	_tone(0.0, 0.75, 220.0, 440.0, 0.3, 2.5, SAW, 0.08)
	_save("spell_vigor_on", 0.85)


## Vigor ends: a breath out (falling noise + low tone).
func _spell_vigor_off() -> void:
	_new(0.5)
	_noise(0.0, 0.45, 0.5, 0.03, 3.0, 0.3, 0.05)
	_tone(0.0, 0.45, 330.0, 165.0, 0.3, 3.0, TRI, 0.02)
	_save("spell_vigor_off", 0.7)


## Snow Shield on: frost crackle + a glassy ring.
func _spell_snow_shield_on() -> void:
	_new(0.9)
	_crackle(0.0, 0.3, 20, 0.45)
	_noise(0.0, 0.5, 0.35, 0.02, 3.0, 0.7, 0.9, true)
	_bell(0.05, 0.85, 1396.9, 0.4)
	_bell(0.12, 0.75, 2093.0, 0.3)
	_tone(0.0, 0.8, 349.23, 349.23, 0.25, 2.0, SINE, 0.05)
	_save("spell_snow_shield_on", 0.85)


## Snow Shield breaks / ends: an ice shatter.
func _spell_snow_shield_off() -> void:
	_new(0.6)
	_crackle(0.0, 0.25, 26, 0.55)
	_noise(0.0, 0.3, 0.5, 0.001, 6.0, 0.8, 0.9, true)
	_tone(0.0, 0.5, 2400.0, 1200.0, 0.25, 4.0, SINE, 0.002)
	_tone(0.0, 0.3, 400.0, 250.0, 0.3, 5.0, TRI, 0.002)
	_save("spell_snow_shield_off", 0.72)


# ---------------------------------------------------------------- bowmen effects (3D, frequent: 3 takes)

## Chill (Frostbow, Rimeling frostbite): a tiny frost crackle + a cold glassy tick.
func _fx_chill() -> void:
	_new(0.26)
	_crackle(0.0, 0.12, 10, 0.5)
	_tone(0.0, 0.24, 1800.0, 1500.0, 0.35, 5.0, SINE, 0.002)
	_noise(0.0, 0.2, 0.3, 0.003, 5.0, 0.7, 0.8, true)
	_save("fx_chill", 0.62)


## Burn (Scorchbow): a whoomp of flame catching + crackle.
func _fx_burn() -> void:
	_new(0.32)
	_noise(0.0, 0.3, 0.7, 0.02, 3.0, 0.1, 0.4)
	_crackle(0.02, 0.25, 12, 0.45)
	_tone(0.0, 0.2, 160.0, 280.0, 0.3, 4.0, SAW, 0.02)
	_save("fx_burn", 0.62)


## Bleed (Bleakbow, each stack): a wet slice + a dark low drip.
func _fx_bleed() -> void:
	_new(0.26)
	_noise(0.0, 0.08, 0.7, 0.001, 8.0, 0.6, 0.2, true)
	_tone(0.05, 0.2, 420.0, 180.0, 0.45, 5.0, SINE, 0.003, 14.0, 0.05)
	_save("fx_bleed", 0.62)


## Crit (Wildwood Archer): a sharp double crack with a bright ping.
func _fx_crit() -> void:
	_new(0.3)
	_noise(0.0, 0.04, 0.9, 0.0005, 9.0, 0.8, 0.6, true)
	_noise(0.05, 0.05, 0.8, 0.0005, 9.0, 0.5, 0.3)
	_tone(0.0, 0.28, 2200.0, 2000.0, 0.3, 5.0, SINE, 0.002)
	_tone(0.05, 0.15, 300.0, 120.0, 0.6, 7.0)
	_save("fx_crit", 0.7)


# ---------------------------------------------------------------- new units (12)

## Scorchling Flashpoint: a small fiery pop on death.
func _ab_flashpoint() -> void:
	_new(0.5)
	_noise(0.0, 0.45, 0.9, 0.002, 4.0, 0.4, 0.05)
	_tone(0.0, 0.3, 200.0, 70.0, 0.6, 5.0)
	_crackle(0.0, 0.35, 16, 0.45)
	_save("ab_flashpoint", 0.75)


## Pyre Adept Flame Burst: a roaring fire bloom.
func _ab_flame_burst() -> void:
	_new(0.8)
	_noise(0.0, 0.75, 1.0, 0.03, 3.0, 0.08, 0.35)
	_tone(0.0, 0.6, 110.0, 55.0, 0.6, 3.0)
	_tone(0.0, 0.5, 300.0, 600.0, 0.25, 3.0, SAW, 0.03)
	_crackle(0.05, 0.6, 24, 0.4)
	_save("ab_flame_burst", 0.8)


## Cinder Arbalest Piercing Bolt: a bolt tearing through (a zip + a second thunk).
func _ab_piercing_bolt() -> void:
	_new(0.3)
	_noise(0.0, 0.14, 0.6, 0.003, 4.0, 0.6, 0.9, true)
	_tone(0.0, 0.14, 1600.0, 700.0, 0.3, 5.0, TRI)
	_noise(0.14, 0.08, 0.8, 0.001, 9.0, 0.4, 0.2)
	_tone(0.14, 0.14, 260.0, 110.0, 0.55, 7.0)
	_save("ab_piercing_bolt", 0.68)


## Barrow Ghoul Grave Feast: a gulp + a hollow rising moan (heal).
func _ab_grave_feast() -> void:
	_new(0.6)
	_tone(0.0, 0.12, 180.0, 110.0, 0.6, 5.0, SINE, 0.005, 20.0, 0.1)
	_tone(0.12, 0.45, 220.0, 330.0, 0.35, 2.5, TRI, 0.05, 5.0, 0.03)
	_noise(0.12, 0.45, 0.25, 0.05, 3.0, 0.1, 0.2)
	_save("ab_grave_feast", 0.72)


## Hexweaver Wither Hex: a whispering dissonant curl.
func _ab_wither_hex() -> void:
	_new(0.7)
	_tone(0.0, 0.65, 587.0, 392.0, 0.35, 2.5, SINE, 0.05, 6.0, 0.03)
	_tone(0.0, 0.65, 622.0, 415.0, 0.3, 2.5, TRI, 0.05, 5.0, 0.03)
	_noise(0.0, 0.6, 0.35, 0.1, 2.5, 0.5, 0.8, true)
	_save("ab_wither_hex", 0.72)


## Hollow Oathsworn Unbroken Vow: an iron oath-bell + a low shield hum.
func _ab_unbroken_vow() -> void:
	_new(0.9)
	_bell(0.0, 0.85, 440.0, 0.45)
	_bell(0.0, 0.8, 659.25, 0.25)
	_tone(0.0, 0.85, 110.0, 110.0, 0.35, 2.0, SAW, 0.05, 4.0, 0.01)
	_save("ab_unbroken_vow", 0.78)


## Hoarlight Magebow Frost Needle: a thin icy zip.
func _ab_frost_needle() -> void:
	_new(0.32)
	_tone(0.0, 0.28, 2600.0, 1400.0, 0.4, 4.0, SINE, 0.002)
	_noise(0.0, 0.25, 0.4, 0.002, 4.0, 0.8, 0.9, true)
	_crackle(0.15, 0.12, 6, 0.35)
	_save("ab_frost_needle", 0.66)


## Frost Mortar Frost Shell splash: an icy burst (on top of hit_siege).
func _ab_frost_shell() -> void:
	_new(0.45)
	_crackle(0.0, 0.25, 22, 0.55)
	_noise(0.0, 0.4, 0.6, 0.002, 4.0, 0.6, 0.3, true)
	_tone(0.0, 0.3, 900.0, 500.0, 0.25, 4.0, SINE, 0.002)
	_save("ab_frost_shell", 0.66)


## Thistle Darter Skitter: a quick leafy scamper.
func _ab_skitter() -> void:
	_new(0.22)
	for i in 4:
		_noise(i * 0.045, 0.04, 0.6, 0.001, 7.0, 0.6, 0.5, true)
	_tone(0.0, 0.2, 900.0, 1300.0, 0.2, 4.0, TRI)
	_save("ab_skitter", 0.55)


## Vinelasher Snare Lash: a whip crack + creaking vines tightening.
func _ab_snare_lash() -> void:
	_new(0.6)
	_noise(0.0, 0.05, 1.0, 0.0005, 9.0, 0.9, 0.7, true)
	_tone(0.0, 0.06, 1500.0, 700.0, 0.35, 9.0, TRI)
	_tone(0.08, 0.5, 140.0, 110.0, 0.4, 2.5, SAW, 0.03, 18.0, 0.06)
	_crackle(0.08, 0.4, 14, 0.35)
	_save("ab_snare_lash", 0.74)


## Greenheart Oathkeeper Grove Oath (taunt): a deep wooden horn + a stomp.
func _ab_grove_oath() -> void:
	_new(0.9)
	_tone(0.0, 0.2, 100.0, 60.0, 0.7, 5.0)
	_noise(0.0, 0.15, 0.6, 0.002, 6.0, 0.3, 0.1)
	_tone(0.05, 0.8, 196.0, 185.0, 0.4, 2.0, SAW, 0.06, 4.0, 0.01)
	_tone(0.05, 0.8, 392.0, 370.0, 0.2, 2.2, TRI, 0.06)
	_tone(0.05, 0.8, 1568.0, 1480.0, 0.05, 3.0, SINE, 0.06)
	_save("ab_grove_oath", 0.8)


# ---------------------------------------------------------------- T3 units

## Saboteur disguise: a cloth rustle + a soft shimmer-out.
func _ab_sab_disguise() -> void:
	_new(0.5)
	_noise(0.0, 0.3, 0.5, 0.02, 3.0, 0.3, 0.6, true)
	_tone(0.0, 0.45, 1200.0, 600.0, 0.2, 3.0, SINE, 0.02, 9.0, 0.03)
	_save("ab_sab_disguise", 0.6)


## Saboteur revealed: the disguise burns away in embers (a flare + crackle).
func _ab_sab_reveal() -> void:
	_new(0.6)
	_noise(0.0, 0.5, 0.8, 0.01, 3.5, 0.15, 0.5)
	_crackle(0.0, 0.45, 20, 0.45)
	_tone(0.0, 0.3, 250.0, 500.0, 0.3, 3.0, SAW, 0.01)
	_save("ab_sab_reveal", 0.74)


## Saboteur starts planting: digging scrapes.
func _ab_sab_plant() -> void:
	_new(0.6)
	for i in 3:
		_noise(i * 0.18, 0.14, 0.7, 0.01, 4.0, 0.25, 0.5)
	_tone(0.0, 0.55, 700.0, 700.0, 0.08, 1.0, TRI, 0.01)
	_save("ab_sab_plant", 0.66)


## Powder charge armed: a fuse hiss + two metal ticks.
func _ab_sab_armed() -> void:
	_new(0.8)
	_noise(0.0, 0.75, 0.45, 0.02, 1.5, 0.8, 0.9, true)
	_bell(0.0, 0.2, 1760.0, 0.4)
	_bell(0.35, 0.2, 1760.0, 0.4)
	_save("ab_sab_armed", 0.68)


## Powder charge explodes (5 s later): a big blast with debris.
func _ab_sab_blast() -> void:
	_new(1.3)
	_noise(0.0, 1.25, 1.0, 0.002, 4.0, 0.3, 0.02)
	_tone(0.0, 0.9, 80.0, 30.0, 0.9, 3.5)
	_crackle(0.05, 1.0, 26, 0.35)
	for i in 8:
		_noise(_rng.randf_range(0.1, 0.9), 0.08, _rng.randf_range(0.25, 0.5), 0.001, 9.0, 0.6, 0.3)
	_save("ab_sab_blast", 0.8)


## Nightblood Reaver Blood Frenzy: a heartbeat + a feral snarl.
func _ab_blood_frenzy() -> void:
	_new(0.8)
	_tone(0.0, 0.12, 80.0, 55.0, 0.8, 5.0)
	_tone(0.18, 0.12, 80.0, 55.0, 0.8, 5.0)
	_tone(0.3, 0.45, 190.0, 150.0, 0.5, 3.0, SAW, 0.02, 30.0, 0.08)
	_noise(0.3, 0.45, 0.4, 0.02, 3.0, 0.3, 0.2)
	_save("ab_blood_frenzy", 0.8)


## Shardguard Hold the Line: a glaive planted + an ice lock (the charger freezes).
func _ab_hold_the_line() -> void:
	_new(0.7)
	_noise(0.0, 0.06, 0.9, 0.001, 9.0, 0.5, 0.3)
	_tone(0.0, 0.2, 150.0, 80.0, 0.7, 6.0)
	_crackle(0.05, 0.3, 18, 0.5)
	_bell(0.05, 0.6, 1318.5, 0.35)
	_save("ab_hold_the_line", 0.8)


## Shardguard Challenge (taunt): a shield bash + a short defiant horn.
func _ab_challenge() -> void:
	_new(0.7)
	_noise(0.0, 0.08, 0.9, 0.001, 8.0, 0.5, 0.2)
	_bell(0.0, 0.3, 587.33, 0.35)
	_tone(0.1, 0.55, 233.0, 247.0, 0.4, 2.2, SAW, 0.03)
	_tone(0.1, 0.55, 1244.5, 1318.5, 0.07, 3.0, TRI, 0.03)
	_save("ab_challenge", 0.6)   # QOA import adds ~2 dB on this one


## Briar Roc Seed Storm: a swoop + a rain of seed pops.
func _ab_seed_storm() -> void:
	_new(0.9)
	_noise(0.0, 0.4, 0.6, 0.15, 1.5, 0.05, 0.6, true)
	for i in 18:
		_noise(0.3 + _rng.randf() * 0.5, 0.02, _rng.randf_range(0.3, 0.6), 0.0005, 8.0, 0.6, 0.4)
	_tone(0.3, 0.3, 160.0, 90.0, 0.4, 5.0)
	_save("ab_seed_storm", 0.78)


## Stormbottle Genie chain (each bolt's jumps): a crackling arc hop.
func _ab_genie_chain() -> void:
	_new(0.3)
	_crackle(0.0, 0.25, 18, 0.55)
	_tone(0.0, 0.25, 2000.0, 900.0, 0.25, 4.0, SQUARE)
	_save("ab_genie_chain", 0.62)


## Stormbottle Genie Tempest Bolt: a thunderclap.
func _ab_tempest_bolt() -> void:
	_new(1.2)
	_noise(0.0, 0.08, 1.0, 0.0005, 5.0, 0.9, 0.7, true)
	_noise(0.0, 1.15, 0.9, 0.003, 3.5, 0.3, 0.02)
	_tone(0.0, 0.8, 70.0, 35.0, 0.7, 3.0)
	_crackle(0.0, 0.3, 24, 0.5)
	_save("ab_tempest_bolt", 0.9)


# ---------------------------------------------------------------- UI ticks

## Tab: the next selected building becomes active (a small wooden tick).
func _ui_tab() -> void:
	_new(0.07)
	_tone(0.0, 0.06, 1500.0, 1300.0, 0.5, 10.0, TRI)
	_noise(0.0, 0.015, 0.3, 0.0005, 10.0, 0.8, 0.8, true)
	_save("ui_tab", 0.4)


## Next-step hint changes: a gentle two-note "ding-dong" up.
func _ui_hint() -> void:
	_new(0.45)
	_bell(0.0, 0.2, 1046.5, 0.4)
	_bell(0.12, 0.33, 1567.98, 0.4)
	_save("ui_hint", 0.45)


## Restart (F9 / end screen): a quick rewind sweep + a start tick.
func _ui_restart() -> void:
	_new(0.5)
	_tone(0.0, 0.3, 1600.0, 400.0, 0.4, 2.0, TRI, 0.005)
	_noise(0.0, 0.3, 0.3, 0.01, 3.0, 0.7, 0.3, true)
	_bell(0.3, 0.2, 1318.5, 0.35)
	_save("ui_restart", 0.45)


## Caravan trained (Bazaar, 0 supply): cart wheels + a coin jingle.
func _alert_caravan_trained() -> void:
	_new(0.7)
	for i in 3:
		_noise(i * 0.09, 0.06, 0.6, 0.002, 6.0, 0.3, 0.2)
	_bell(0.25, 0.4, 2093.0, 0.4)
	_bell(0.32, 0.38, 2637.0, 0.35)
	_tone(0.0, 0.3, 196.0, 196.0, 0.35, 3.0, SQUARE, 0.01)
	_save("alert_caravan_trained", 0.62)

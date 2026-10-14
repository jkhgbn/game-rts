class_name WsUpgradeText
extends RefCounted
## Effect text of a Wave Strike upgrade, built from its data (ui-wave-strike.md 8.3 "Effect templates": never typed by
## hand per card): `mods` flat -> "+3 armour" / "+6 HP/s" / "+25 spell power", pct -> "+20 % HP"; `type_add` ->
## "+1.5 range"; `type_set` on-hit -> "marked 3 s on hit (+15 % damage taken)" / "chill 2 s on hit"; `type_mult` ->
## "on-hit lasts x1.5" / "support x1.4" / "interval x0.75"; `release` -> "haste 4 s at release" / "shield 150 for 10 s at
## release". Every part through Loc (one msgid per template); numbers as %g.


## The effect text of upgrade entry `u` (WaveUpgradeTable.upgrade / MusterRoster.upgrade_info).
static func effect(u: Dictionary) -> String:
	var parts: PackedStringArray = []
	var mods: Dictionary = u.get("mods", {})
	for k: Variant in mods:
		var t := _mod(String(k), float(mods[k]))
		if t != "":
			parts.append(t)
	var add: Dictionary = u.get("type_add", {})
	if add.has("attack_range"):
		parts.append(Loc.t("+%s range") % _g(float(add["attack_range"])))
	elif add.has("aggro_range"):
		parts.append(Loc.t("+%s sight") % _g(float(add["aggro_range"])))
	var set_: Dictionary = u.get("type_set", {})
	if set_.has("on_hit_status"):
		var st := String(set_["on_hit_status"])
		var dur := _g(float(set_.get("on_hit_duration", 0.0)))
		match st:
			"marked":
				parts.append(Loc.t("marked %s s on hit (+15 %% damage taken)") % dur)
			"chill":
				parts.append(Loc.t("chill %s s on hit") % dur)
			_:
				parts.append(Loc.t("%s %s s on hit") % [Loc.sink(st), dur])
	var mult: Dictionary = u.get("type_mult", {})
	for k: Variant in mult:
		var x := _g(float(mult[k]))
		match String(k):
			"on_hit_duration":
				parts.append(Loc.t("on-hit lasts x%s") % x)
			"support_amount":
				parts.append(Loc.t("support x%s") % x)
			"support_interval":
				parts.append(Loc.t("interval x%s") % x)
	for r: Variant in u.get("release", []):
		var d: Dictionary = r
		var secs := _g(float(d.get("duration", 0.0)))
		if d.has("shield"):
			parts.append(Loc.t("shield %s for %s s at release") % [_g(float(d["shield"])), secs])
			continue
		match String(d.get("status", "")):
			"haste":
				parts.append(Loc.t("haste %s s at release") % secs)
			"braced":
				parts.append(Loc.t("braced %s s at release") % secs)
			"shroud":
				parts.append(Loc.t("shroud %s s at release") % secs)
	return ", ".join(parts)


static func _mod(stat: String, v: float) -> String:
	match stat:
		"armor":
			return Loc.t("+%s armour") % _g(v)
		"hp_regen":
			return Loc.t("+%s HP/s") % _g(v)
		"spell_power":
			return Loc.t("+%s spell power") % _g(v)
		"attack_damage":
			return Loc.t("+%s damage") % _g(v)
		"move_speed":
			return Loc.t("+%s speed") % _g(v)
		"max_hp_pct":
			return Loc.t("+%s %% HP") % _g(v * 100.0)
		"max_mana_pct":
			return Loc.t("+%s %% mana") % _g(v * 100.0)
		"mana_regen_pct":
			return Loc.t("+%s %% regen") % _g(v * 100.0)
		"attack_damage_pct":
			return Loc.t("+%s %% damage") % _g(v * 100.0)
		"cooldown_reduction":
			return Loc.t("+%s %% cooldown reduction") % _g(v * 100.0)
	return ""


## %g: 3 -> "3", 1.5 -> "1.5", 0.75 -> "0.75" (French decimal comma).
static func _g(v: float) -> String:
	var s := str(snappedf(v, 0.01))
	if s.ends_with(".0"):
		s = s.substr(0, s.length() - 2)
	return s.replace(".", ",") if Loc.is_french() else s


## The upgrade's name in the current language.
static func name_of(u: Dictionary) -> String:
	return Loc.sink(String(u.get("name", "")))


## Roman numeral for Armoury levels 1-3 ("" at 0).
static func roman(level: int) -> String:
	return ["", "I", "II", "III", "IV"][clampi(level, 0, 4)]  # LOC_IGNORE


## Logic text the pad / upgrade UI shows through Loc.sink (MusterPad / MusterRoster reasons, WaveUpgradeTable names):
## listed here so the string extractor gives each one a French entry in ui_wave_strike.po. Never called.
static func _logic_msgids() -> PackedStringArray:
	return [Loc.t("No room on the pad"), Loc.t("Spot taken"), Loc.t("Off the pad"), Loc.t("No unit there"),
			Loc.t("Swap needs the same size"), Loc.t("Already bought"), Loc.t("Too late to cancel"), Loc.t("Not bought"),
			Loc.t("Upgrades off"), Loc.t("Unknown upgrade"), Loc.t("Armour"), Loc.t("Arcana"),
			Loc.t("Shield Drill"), Loc.t("War Cry"), Loc.t("Long Draw"), Loc.t("Spotter Marks"), Loc.t("Barding"),
			Loc.t("Flank Gallop"), Loc.t("Plate"), Loc.t("Brace"), Loc.t("Deep Wells"), Loc.t("Quick Hands"),
			Loc.t("Mana Font"), Loc.t("Focus"), Loc.t("Lingering"), Loc.t("Sunforged Charge"), Loc.t("Rime Mantle"),
			Loc.t("Shard Ward"), Loc.t("Thorned Pinions"), Loc.t("Far Sight"), Loc.t("Blood Feast"), Loc.t("Veil Ride")]

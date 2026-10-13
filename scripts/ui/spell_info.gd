class_name SpellInfo
extends RefCounted
## Read-only helpers the HUD uses to show a wizard's spells (spells.md, levels.md "HUD").
## Everything is guarded (has_method / get) so the UI still works while the spell framework
## (`SpellCaster`, `SpellType`, Wizard levels) is missing or partial: then only Fireball exists.

const SLOT_KEYS := ["F", "Q", "E"]
const DESCRIPTIONS := {
	&"fireball": "Burns everything in the circle.",
	&"ember_step": "Blink to a point. The ground you leave burns for 4 s.",
	&"kindle": "Nearby soldiers strike faster and run faster.",
	&"shadow_lance": "Heals Malrik for half the damage.",
	&"soul_siphon": "Drains everyone in the circle for 5 s.",
	&"umbral_shroud": "Half damage taken, faster movement.",
	&"rime_bolt": "Chills the target: slower attacks and movement.",
	&"flash_freeze": "Freezes every enemy in the circle.",
	&"rime_aegis": "Shields Torvald and nearby soldiers.",
	&"thornburst": "Thorns erupt and root enemies in place.",
	&"wild_bloom": "Heals friends in the circle over 5 s.",
	&"call_the_thicket": "Saplings fight for 25 s, then wither.",
}
const TARGETS := {&"fireball": &"point", &"ember_step": &"point", &"kindle": &"self",
		&"shadow_lance": &"unit", &"soul_siphon": &"area", &"umbral_shroud": &"self",
		&"rime_bolt": &"unit", &"flash_freeze": &"area", &"rime_aegis": &"self",
		&"thornburst": &"point", &"wild_bloom": &"area", &"call_the_thicket": &"point"}
## Self spells whose tooltip shows the radius instead of the duration (kingdom-ice.md 4.1).
const SELF_RADIUS := [&"rime_aegis"]
## Point spells whose line 2 is "damage · radius" even with a cooldown (kingdom-nature.md 3.1 Thornburst).
const DAMAGE_RADIUS := [&"thornburst"]

static var _types := {}


## The wizard's "SpellCaster" child, or null.
static func caster(wiz: Node) -> Node:
	if wiz == null or not is_instance_valid(wiz):
		return null
	return wiz.get_node_or_null(^"SpellCaster")


## Spell ids in slot order F / Q / E. Without a SpellCaster: Fireball only (wave 2 wizard).
static func ids(wiz: Node) -> Array[StringName]:
	var out: Array[StringName] = []
	var c := caster(wiz)
	if c != null and c.has_method(&"spell_ids"):
		for id in c.call(&"spell_ids"):
			out.append(StringName(id))
		return out
	if wiz != null and is_instance_valid(wiz) and wiz.has_method(&"command_fireball"):
		out.append(&"fireball")
	return out


## The SpellType resource (data/spells/<id>.tres), or null.
static func type_of(id: StringName) -> Resource:
	if _types.has(id):
		return _types[id]
	var path := "res://data/spells/%s.tres" % id
	var res: Resource = load(path) if ResourceLoader.exists(path) else null
	_types[id] = res
	return res


static func display_name(id: StringName) -> String:
	var t := type_of(id)
	if t != null and t.get("display_name") != null and str(t.get("display_name")) != "":
		return str(t.get("display_name"))
	return String(id).capitalize()


static func abbrev(id: StringName) -> String:
	var t := type_of(id)
	if t != null and t.get("icon_abbrev") != null and str(t.get("icon_abbrev")) != "":
		return str(t.get("icon_abbrev"))
	return UIStyle.abbrev(display_name(id))


## &"point", &"unit", &"area" or &"self".
static func target_type(id: StringName) -> StringName:
	var t := type_of(id)
	if t != null and t.get("target_type") != null:
		var v: Variant = t.get("target_type")
		if v is int:   # SpellType.TargetType { POINT, UNIT, SELF, AREA }
			return [&"point", &"unit", &"self", &"area"][clampi(v, 0, 3)]
		if v is String or v is StringName:
			return StringName(v)
	return TARGETS.get(id, &"point")


## Current rank (0 = not learned). Without the level system every known spell counts as rank 1.
static func rank(wiz: Node, id: StringName) -> int:
	if wiz != null and is_instance_valid(wiz) and wiz.has_method(&"spell_rank"):
		return int(wiz.call(&"spell_rank", id))
	var c := caster(wiz)
	if c != null and c.has_method(&"rank_of"):
		return int(c.call(&"rank_of", id))
	return 1


static func max_rank(id: StringName, slot: int) -> int:
	var t := type_of(id)
	if t != null and t.get("max_rank") != null:
		return maxi(1, int(t.get("max_rank")))
	return 2 if slot == 2 else 3


## A number of the spell at `at_rank` (the `<field>_by_rank` array, else the scalar field).
static func value(wiz: Node, id: StringName, field: String, at_rank: int) -> float:
	var t := type_of(id)
	if t != null:
		var arr: Variant = t.get(field + "_by_rank")
		if arr is Array and not (arr as Array).is_empty():
			return float(arr[clampi(at_rank - 1, 0, (arr as Array).size() - 1)])
		if t.get(field) != null:
			return float(t.get(field))
		if field == "range" and t.get("cast_range") != null:
			return float(t.get("cast_range"))
	if id == &"fireball" and wiz != null and is_instance_valid(wiz):
		var v: Variant = wiz.get("fireball_" + ("cost" if field == "mana_cost" else field))
		if v != null:
			return float(v)
	return 0.0


## U2-3: `value` as the wizard really gets it: damage x spell power, heal x the heal multiplier (spell power, Blossom),
## cooldown x cooldown reduction (SpellCaster's own multipliers when it has them, so the tooltip matches the cast).
static func live_value(wiz: Node, id: StringName, field: String, at_rank: int) -> float:
	var v := value(wiz, id, field, at_rank)
	var c := caster(wiz)
	if c == null or v == 0.0:
		return v
	match field:
		"damage":
			if c.has_method(&"spell_power_multiplier"):
				v *= float(c.call(&"spell_power_multiplier"))
		"heal":
			if c.has_method(&"heal_multiplier"):
				v *= float(c.call(&"heal_multiplier"))
		"cooldown":
			if wiz.has_method(&"get_stat"):
				v *= SpellCaster.cooldown_multiplier(float(wiz.call(&"get_stat", &"cooldown_reduction")))
	return v


static func mana_cost(wiz: Node, id: StringName) -> float:
	var c := caster(wiz)
	if c != null and c.has_method(&"mana_cost"):
		return float(c.call(&"mana_cost", id))
	return value(wiz, id, "mana_cost", maxi(1, rank(wiz, id)))


static func cooldown_left(wiz: Node, id: StringName) -> float:
	var c := caster(wiz)
	if c != null and c.has_method(&"cooldown_left"):
		return float(c.call(&"cooldown_left", id))
	return 0.0


static func cooldown_total(wiz: Node, id: StringName) -> float:
	var c := caster(wiz)
	if c != null and c.has_method(&"cooldown_total"):
		return float(c.call(&"cooldown_total", id))
	return value(wiz, id, "cooldown", maxi(1, rank(wiz, id)))


## Why the spell can't be cast now ("" = it can): Dead / Not learned / On cooldown / Not enough mana.
static func cast_reason(wiz: Node, id: StringName) -> String:
	if wiz == null or not is_instance_valid(wiz) or not bool(wiz.call(&"is_alive")):
		return "Dead"
	if wiz.has_method(&"can_act") and not bool(wiz.call(&"can_act")):
		return "Frozen"   # U2-2: same order as SpellCaster (right after "Dead")
	if rank(wiz, id) <= 0:
		return "Not learned"
	if cooldown_left(wiz, id) > 0.0:
		return "On cooldown"
	if float(wiz.get("mana")) < mana_cost(wiz, id):
		return "Not enough mana"
	return ""


## "" when `learn_spell` would work, else the reason ("Max rank", "Needs level 4", "No spell points").
static func learn_reason(wiz: Node, id: StringName) -> String:
	if wiz == null or not is_instance_valid(wiz) or not wiz.has_method(&"can_learn"):
		return "No spell points"
	return str(wiz.call(&"can_learn", id))


## Line 2 of the tooltip: `40 mana · 72 damage · radius 3.75` (numbers of rank `r`).
static func numbers_line(wiz: Node, id: StringName, r: int) -> String:
	# Each part is one translated list item (joined by " · ").
	var parts: Array[String] = [Loc.t("%s mana") % _num(mana_cost(wiz, id))]
	var tt := target_type(id)
	var dmg := live_value(wiz, id, "damage", r)
	var cd := live_value(wiz, id, "cooldown", r)
	var rad := live_value(wiz, id, "radius", r)
	var rng := live_value(wiz, id, "range", r)
	var dur := live_value(wiz, id, "duration", r)
	var summons := roundi(live_value(wiz, id, "summon_count", r))
	if summons > 0:
		# Summon spells (Call the Thicket): `60 mana · 45 s cooldown · 3 Saplings`.
		if cd > 0.0:
			parts.append(Loc.t("%s s cooldown") % _num(cd))
		parts.append("%d %s" % [summons, summon_name(id, summons)])
	elif dmg > 0.0 and (tt == &"unit" or (tt == &"point" and (cd <= 0.0 or id in DAMAGE_RADIUS))):
		parts.append(Loc.t("%s damage") % _num(dmg))
		if rad > 0.0 and tt == &"point":
			parts.append(Loc.t("radius %s") % _num(rad))
		elif rng > 0.0:
			parts.append(Loc.t("range %s") % _num(rng))
	else:
		if cd > 0.0:
			parts.append(Loc.t("%s s cooldown") % _num(cd))
		if tt == &"self":
			if id in SELF_RADIUS and rad > 0.0:
				parts.append(Loc.t("radius %s") % _num(rad))
			elif dur > 0.0:
				parts.append("%s s" % _num(dur))
		elif tt == &"area" and rad > 0.0:
			parts.append(Loc.t("radius %s") % _num(rad))
		elif rng > 0.0:
			parts.append(Loc.t("range %s") % _num(rng))
	return " · ".join(parts)


## Only what changes from rank r to r + 1: `rank 3 = 85 damage, radius 4.0`.
static func next_rank_line(wiz: Node, id: StringName, r: int) -> String:
	if r <= 0:
		return Loc.t("learn rank 1")
	var changes: Array[String] = []
	for f in [["damage", Loc.t("%s damage")], ["heal", Loc.t("%s heal")], ["summon_count", "%s " + summon_name(id, 2)],
			["radius", Loc.t("radius %s")], ["range", Loc.t("range %s")], ["duration", "%s s"],
			["cooldown", Loc.t("%s s cooldown")]]:
		var a := live_value(wiz, id, f[0], r)
		var b := live_value(wiz, id, f[0], r + 1)
		if not is_equal_approx(a, b):
			changes.append(str(f[1]) % _num(b))
	return Loc.t("rank %d = %s") % [r + 1, ", ".join(changes) if not changes.is_empty() else Loc.t("stronger")]


## The full tooltip (levels.md "Tooltip with ranks"); the card adds the disabled reason line.
static func tooltip(wiz: Node, id: StringName, slot: int) -> String:
	var key: String = SLOT_KEYS[slot] if slot < SLOT_KEYS.size() else ""
	var r := rank(wiz, id)
	var levels := wiz != null and is_instance_valid(wiz) and wiz.has_method(&"spell_rank")
	var desc: String = DESCRIPTIONS.get(id, "")
	if desc == "" and type_of(id) != null and type_of(id).get("tooltip") != null:
		desc = str(type_of(id).get("tooltip"))
	desc = Loc.t(desc) if desc != "" else desc   # the spell descriptions are msgids (spell_info / data/spells)
	if r <= 0:
		return Loc.t("%s  [%s]  Not learned\n%s\n%s") % [display_name(id), key, numbers_line(wiz, id, 1), desc]
	var head := "%s  [%s]" % [display_name(id), key]
	if levels:
		head = Loc.t("%s  [%s]  Rank %d / %d") % [display_name(id), key, r, max_rank(id, slot)]
	var tip := "%s\n%s\n%s" % [head, numbers_line(wiz, id, r), desc]
	if levels and learn_reason(wiz, id) == "":
		tip += "\n" + Loc.t("Ctrl+%s: %s") % [key, next_rank_line(wiz, id, r)]
	return tip


## "Sapling" / "Saplings": the summoned UnitType's display name (data/units/<summon_unit_id>.tres).
static func summon_name(id: StringName, count: int) -> String:
	var t := type_of(id)
	var unit_id := StringName(str(t.get("summon_unit_id"))) if t != null and t.get("summon_unit_id") != null else &""
	var n := String(unit_id).capitalize() if unit_id != &"" else "Summon"
	var path := "res://data/units/%s.tres" % unit_id
	if unit_id != &"" and ResourceLoader.exists(path):
		var ut: Resource = load(path)
		if ut != null and ut.get("display_name") != null and str(ut.get("display_name")) != "":
			n = str(ut.get("display_name"))
	# U2-7: the whole word (singular or English plural) is logic text shown through the sink ("Saplings" has its own
	# French entry); never a translated stem + "s".
	return Loc.sink(n if count == 1 else n + "s")


## 12 -> "12", 3.75 -> "3.75", 3.5 -> "3.5".
static func _num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(roundi(v))
	return Loc.num(v, 2)   # "3,75" in French

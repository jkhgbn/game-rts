class_name UnitGuideData
extends RefCounted
## The Unit Guide's data (docs/design/unit-guide.md): which units the guide lists, their numbers READ FROM THE GAME DATA
## at runtime (data/units, data/champions, data/helpers and the kits' tables), and the hand-written text of
## data/ui/unit_guide.json (role, class, pros / cons, tags, extra abilities). Static and cached; the screen
## (UnitGuide), the generator (tools/unit_guide/gen_guide.gd) and tests/test_unit_guide.gd all read it.

const JSON_PATH := "res://data/ui/unit_guide.json"
const ICON_DIR := "res://art/icons/units/"
const KINGDOMS: Array[StringName] = [&"fire", &"ice", &"nature", &"shadow"]
const NEUTRAL := &"neutral"
## Role filter ids (the guide's role dropdown order).
const ROLES: Array[String] = ["melee", "ranged", "cavalry", "caster", "siege", "support", "titan", "helper", "champion",
		"worker"]
const ROLE_NAMES := {"melee": "Melee", "ranged": "Ranged", "cavalry": "Cavalry", "caster": "Caster", "siege": "Siege",
		"support": "Support", "titan": "Titan", "helper": "Helper", "champion": "Champion", "worker": "Worker"}
## Kingdom display names (English msgids; the screen shows them through kingdom_label).
const KINGDOM_NAMES := {"fire": "Fire", "ice": "Ice", "nature": "Nature", "shadow": "Shadow", "neutral": "Neutral"}
## Text limits (characters), checked by the test and the generator.
const PRO_MAX := 80
const TAG_MAX := 24
const SUMMARY_MAX := 140
const TAVERN := "Tavern"

## Claim phrases the checker verifies (UnitGuideData.check_claims): phrase -> [stat, "max" | "min"].
const EXTREMES := {
	"highest hp": ["hp", "max"], "lowest hp": ["hp", "min"],
	"highest dps": ["dps", "max"], "lowest dps": ["dps", "min"],
	"hardest hitter": ["damage", "max"], "highest damage per hit": ["damage", "max"],
	"longest range": ["range", "max"],
	"fastest": ["speed", "max"], "slowest": ["speed", "min"],
	"most armour": ["armor", "max"], "longest sight": ["sight", "max"],
	"highest effective hp": ["ehp", "max"], "lowest effective hp": ["ehp", "min"],
	"best hp per crystal": ["hp_per_crystal", "max"], "worst hp per crystal": ["hp_per_crystal", "min"],
	"best dps per crystal": ["dps_per_crystal", "max"], "worst dps per crystal": ["dps_per_crystal", "min"],
	"cheapest": ["crystals", "min"], "most expensive": ["crystals", "max"],
}
## "Top 3 for <stat> in ..." (higher = better, except none).
const TOP_STATS := {"hp": "hp", "dps": "dps", "range": "range", "speed": "speed", "armour": "armor", "sight": "sight",
		"effective hp": "ehp", "hp per crystal": "hp_per_crystal", "dps per crystal": "dps_per_crystal",
		"damage per hit": "damage"}

static var _json: Dictionary = {}
static var _json_loaded := false
static var _entries: Array[Dictionary] = []
static var _by_id: Dictionary = {}
static var _icons: Dictionary = {}


## Forgets the caches (the generator rewrites the JSON; tests start clean).
static func reset() -> void:
	_json = {}
	_json_loaded = false
	_entries = []
	_by_id = {}


# ---------------------------------------------------------------- roster (from the game data)

## Every player-facing unit the guide must list, from the game's own tables: per kingdom the keep (worker, caster,
## tier-3 unit, helper), the Hall (its .tres list, the bowman, the 3 new units), the Stables; then the shared hires
## (Caravan, the 4 champions, the Stormbottle Genie, the Greywater Tracker). Each: {id, kind ("unit" / "champion" /
## "helper"), kingdom, building, card_key}.
static func roster() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	for k in KINGDOMS:
		var keep := BuildingType.find("%s_keep" % k)
		var hall := BuildingType.find("%s_barracks" % k)
		var stables := BuildingType.find("%s_stables" % k)
		var keep_name := keep.display_name if keep else "Keep"
		var hall_name := hall.display_name if hall else "Hall"
		var stables_name := stables.display_name if stables else "Stables"
		if keep:
			for t in keep.trains:
				if t:
					_add(out, seen, t.id, "unit", k, keep_name)
		if hall:
			for t in hall.trains:
				if t:
					_add(out, seen, t.id, "unit", k, hall_name)
		_add(out, seen, BowmanKit.HALL_BOWMAN.get(k, &""), "unit", k, hall_name)
		for id: StringName in NewUnits12.HALL_UNITS.get(k, []):
			_add(out, seen, id, "unit", k, hall_name)
		for id: StringName in Stables16.ROSTER.get(k, []):
			if seen.has(id):   # the Blaze Rider: Ember Hall and Ember Stables
				var e: Dictionary = out[seen[id]]
				e["building"] = "%s / %s" % [e["building"], stables_name]
				continue
			_add(out, seen, id, "unit", k, stables_name)
		_add(out, seen, CasterKit.BY_FACTION.get(k, &""), "unit", k, keep_name)
		_add(out, seen, T3Kit.KEEP_UNITS.get(k, &""), "unit", k, keep_name)
		var h := HelperType.for_kingdom(k)
		if h:
			_add(out, seen, h.id, "helper", k, "%s (Citadel)" % keep_name)
	_add(out, seen, &"caravan", "unit", NEUTRAL, "Bazaar (any kingdom)")
	for cid in ChampionType.IDS:
		_add(out, seen, cid, "champion", NEUTRAL, TAVERN)
	_add(out, seen, T3Kit.GENIE_ID, "unit", NEUTRAL, "%s (Wonders)" % TAVERN)
	_add(out, seen, StringName(HuntersGuild.TRACKER_TYPE_ID), "unit", NEUTRAL, "Greywater Lodge (contract)")
	return out


static func _add(out: Array[Dictionary], seen: Dictionary, id: StringName, kind: String, kingdom: StringName,
		building: String) -> void:
	if id == &"" or seen.has(id):
		return
	seen[id] = out.size()
	out.append({"id": id, "kind": kind, "kingdom": kingdom, "building": building})


# ---------------------------------------------------------------- the JSON

static func json() -> Dictionary:
	if not _json_loaded:
		_json_loaded = true
		_json = {}
		var f := FileAccess.open(JSON_PATH, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_json = parsed
	return _json


## The hand-written block of `id` ({} when missing).
static func text_of(id: StringName) -> Dictionary:
	var units: Dictionary = json().get("units", {})
	return units.get(String(id), {})


# ---------------------------------------------------------------- entries

## Every guide entry (roster order): the roster row + name, tier, stats, cost text, abilities and the JSON text.
static func entries() -> Array[Dictionary]:
	if _entries.is_empty():
		for row in roster():
			var e := _build(row)
			if not e.is_empty():
				_by_id[e["id"]] = _entries.size()
				_entries.append(e)
	return _entries


static func entry(id: StringName) -> Dictionary:
	entries()
	return _entries[_by_id[id]] if _by_id.has(id) else {}


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for e in entries():
		out.append(e["id"])
	return out


static func _build(row: Dictionary) -> Dictionary:
	var id: StringName = row["id"]
	var e := row.duplicate()
	var st := stats_of(id, String(row["kind"]))
	if st.is_empty():
		return {}
	e["stats"] = st
	e["name"] = st["name"]
	e["tier"] = int(st["tier"])
	e["card_key"] = st.get("card_key", "")
	var t := text_of(id)
	e["role"] = str(t.get("role", suggest_role(id, String(row["kind"]))))
	e["class"] = str(t.get("class", ""))
	e["summary"] = str(t.get("summary", "")) if str(t.get("summary", "")) != "" else code_summary(id)
	e["pros"] = _strings(t.get("pros", []))
	e["cons"] = _strings(t.get("cons", []))
	e["strong"] = _strings(t.get("strong_against", []))
	e["weak"] = _strings(t.get("weak_against", []))
	e["good_with"] = _strings(t.get("good_with", []))
	e["abilities"] = abilities_of(id, String(row["kind"]))
	e["cost_text"] = cost_text(e)
	e["search"] = ("%s %s %s %s %s %s" % [e["name"], e["class"], e["role"], e["kingdom"], e["building"],
			" ".join(PackedStringArray(e["strong"] + e["weak"] + e["good_with"]))]).to_lower()
	return e


static func _strings(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for s in v:
			out.append(str(s))
	return out


## The numbers of `id` straight from its resource: {name, tier, hp, damage, cooldown, dps, range, speed, armor, sight,
## ehp, crystals, essence, gold, pop, train_time, regen, on_hit, hp_per_crystal, dps_per_crystal}. {} = unknown id.
static func stats_of(id: StringName, kind: String = "unit") -> Dictionary:
	var s := {}
	match kind:
		"champion":
			var c := ChampionType.find(id)
			if c == null:
				return {}
			var hire: Dictionary = ChampionGuild.HIRE_COSTS[0]
			s = {"name": "The " + c.title.trim_prefix("the ").strip_edges() if c.title != "" else String(id).capitalize(),
				"tier": 1, "hp": c.max_hp, "damage": c.attack_damage, "cooldown": c.attack_cooldown,
				"range": c.attack_range, "speed": c.move_speed, "armor": c.armor, "sight": c.sight_radius,
				"crystals": int(hire["crystals"]), "essence": int(hire["essence"]), "gold": 0, "pop": ChampionGuild.POP,
				"train_time": ChampionGuild.HIRE_DELAY, "regen": 0.0, "on_hit": ""}
		"helper":
			var h := HelperType.find(id)
			if h == null:
				return {}
			s = {"name": h.display_name, "tier": 3, "hp": h.hp_base, "damage": h.damage_base,
				"cooldown": h.attack_cooldown, "range": h.attack_range, "speed": h.move_speed, "armor": h.armor,
				"sight": h.sight, "crystals": h.call_crystals, "essence": h.call_essence, "gold": 0, "pop": h.pop,
				"train_time": h.call_time, "regen": 0.0, "on_hit": ""}
		_:
			var u := UnitType.find(String(id))
			if u == null:
				return {}
			var sight := u.sight_radius if u.sight_radius > 0.0 \
					else float(FogOfWar.UNIT_SIGHT.get(u.id, FogOfWar.DEFAULT_UNIT_SIGHT))
			s = {"name": u.display_name, "tier": u.requires_tier, "hp": u.max_hp, "damage": u.attack_damage,
				"cooldown": u.attack_cooldown, "range": u.attack_range, "speed": u.move_speed, "armor": u.armor,
				"sight": sight, "crystals": u.cost, "essence": 0, "gold": 0, "pop": u.pop, "train_time": u.train_time,
				"regen": u.idle_regen_pct, "on_hit": String(u.on_hit_status), "card_key": u.card_key}
			if id == StringName(HuntersGuild.TRACKER_TYPE_ID):
				var lo := 1 << 30
				for kd: StringName in HuntersGuild.CONTRACTS:
					lo = mini(lo, int(HuntersGuild.CONTRACTS[kd]["cost"]))
				s["gold"] = lo
	var cd := maxf(0.05, float(s["cooldown"]))
	s["dps"] = float(s["damage"]) / cd
	s["ehp"] = float(s["hp"]) * (1.0 + float(s["armor"]) / 100.0)
	var price := float(s["crystals"])
	s["hp_per_crystal"] = float(s["hp"]) / price if price > 0.0 else 0.0
	s["dps_per_crystal"] = float(s["dps"]) / price * 100.0 if price > 0.0 else 0.0   # per 100 crystals
	return s


## The role the data points to (the generator's suggestion; the JSON `role` wins): helper / champion by kind, then
## worker, caster, titan (pop >= 6), cavalry (Stables), support (heals / shields / caravans), siege (range >= 12 or
## the casters' siege list), ranged (range > 3), melee.
static func suggest_role(id: StringName, kind: String = "unit") -> String:
	if kind == "helper" or kind == "champion":
		return kind
	var u := UnitType.find(String(id))
	if u == null:
		return "melee"
	if u.is_worker:
		return "worker"
	if CasterKit.is_caster(id):
		return "caster"
	if u.pop >= 6:
		return "titan"
	if Stables16.is_stables_unit(id):
		return "cavalry"
	if u.support_kind != &"" or u.is_caravan:
		return "support"
	if u.attack_range >= 12.0 or CasterAbility.SIEGE_IDS.has(id):
		return "siege"
	return "ranged" if u.attack_range > 3.0 else "melee"


## "180 crystals · 2 pop · 30 s" (champions / helpers add essence; the tracker: its gold contract).
## In the current language (the screen calls it each time it shows a unit).
static func cost_text(e: Dictionary) -> String:
	var s: Dictionary = e["stats"]
	if int(s["gold"]) > 0:
		return Loc.t("Contract from {gold} gold (Greywater Lodge)", {"gold": int(s["gold"])})
	var parts: Array[String] = []
	if int(s["crystals"]) > 0:
		parts.append(Loc.tn("{n} crystal", "{n} crystals", int(s["crystals"])))
	if int(s["essence"]) > 0:
		parts.append(Loc.t("{n} essence", {"n": int(s["essence"])}))
	parts.append(Loc.t("{n} pop", {"n": int(s["pop"])}))
	if float(s["train_time"]) > 0.0:
		parts.append("%d s" % int(round(float(s["train_time"]))))
	var t := " · ".join(parts)
	if e["kind"] == "champion":
		t = Loc.t("{cost} (first hire)", {"cost": t})
	return t


## The game's own one-line description of `id` (the command card / kit tables), "" if none.
static func code_summary(id: StringName) -> String:
	for line: String in [CasterKit.description(id) if CasterKit.is_caster(id) else "",
			NewUnits12.description(id) if NewUnits12.UNITS.has(id) else "",
			Stables16.description(id) if Stables16.is_stables_unit(id) else "",
			T3Kit.description(id) if T3Kit.UNIT_IDS.has(id) else "",
			str(CommandCard.TRAIN_DESCRIPTIONS.get(id, ""))]:
		if line != "":
			return line
	return ""


## Abilities: [{name, key, text}]. Casters, the 12 Hall units, Stables rank-ups and champions come from the game's
## tables (always current); the JSON `abilities` add the rest (bowmen, T3 units, helpers, worker notes...).
static func abilities_of(id: StringName, kind: String = "unit") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if CasterKit.is_caster(id):
		for sp in CasterKit.spells_of(id):
			var d := CasterKit.spell(sp)
			out.append(_templ({"name": str(d.get("name", sp)), "key": str(d.get("key", ""))},
				"{text} ({mana} mana)", {"text": str(d.get("text", "")), "mana": int(d.get("mana", 0))}))
		var p := CasterKit.passive_of(id)
		if p != &"" and CasterKit.PASSIVES.has(p):
			var pd: Dictionary = CasterKit.PASSIVES[p]
			out.append({"name": str(pd.get("name", p)), "key": "Passive",
				"text": str(pd.get("text", "")).trim_prefix(str(pd.get("name", "")) + ": ")})
	if NewUnits12.UNITS.has(id):
		var ab: StringName = NewUnits12.ABILITY_IDS.get(id, &"")
		var text := NewUnits12.description(id)
		var colon := text.find(": ")
		out.append({"name": String(ab).capitalize(), "key": "Auto",
			"text": text.substr(colon + 2) if colon >= 0 else text})
	if kind == "champion":
		var c := ChampionType.find(id)
		if c:
			for ab_id in c.ability_ids:
				var d: Dictionary = ChampionAbilities.ABILITIES.get(ab_id, {})
				var nm := c.ability_name(ab_id, str(d.get("name", String(ab_id).capitalize())))
				var tx := c.ability_text(ab_id, "")
				var lv := int(d.get("unlock", 1))
				if tx != "":
					out.append({"name": nm, "key": "Auto, L%d" % lv, "text": tx})
				else:
					out.append(_templ({"name": nm, "key": "Auto, L%d" % lv}, "Cooldown {n} s.",
						{"n": int(d.get("cooldown", 0))}))
	var t := text_of(id)
	for a in t.get("abilities", []):
		if a is Dictionary:
			out.append({"name": str(a.get("name", "")), "key": str(a.get("key", "Auto")), "text": str(a.get("text", ""))})
	if Stables16.has_rank_up(id):
		var bonus: Dictionary = Stables16.RANK_STATS
		var rk := _templ({"key": "Stables"},
			"Stables research once your keep is a Citadel ({price} crystals, {time} s): +{hp} % HP, +{dmg} % damage, +{armor} armour.",
			{"price": Stables16.rank_price(id), "time": int(Stables16.rank_time(id)),
				"hp": int(round(float(bonus[&"max_hp_pct"]) * 100.0)),
				"dmg": int(round(float(bonus[&"attack_damage_pct"]) * 100.0)), "armor": int(bonus[&"armor"])})
		rk["name_tmpl"] = "Rank 3: {name}"
		rk["name_args"] = {"name": Stables16.rank_name(id)}
		rk["name"] = String(rk["name_tmpl"]).format(rk["name_args"])
		out.append(rk)
	out.append_array(forge_abilities(id, kind))
	return out


## docs/design/unit-upgrades.md: the Forge research that touches a soldier: its kingdom's 3 generic lines, then its
## unit-specific line when it has one.
static func forge_abilities(id: StringName, kind: String = "unit") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if kind != "unit" or not ForgeKit.ENABLED:
		return out
	var t := UnitType.find(String(id))
	if t == null or t.is_worker or t.is_caravan or not ForgeKit.CARD.has(t.faction):
		return out
	var kl: StringName = ForgeKit.KINGDOM_LINE[t.faction]
	var g := _templ({"key": "Forge"},
		"Weapons +{dmg} % damage and Armor +{armor} armour per level; {line}: {text} per level. 3 levels each ({p1} / {p2} / {p3} crystals; level 2 needs a Stronghold, level 3 a Citadel).",
		{"dmg": int(round(float(ForgeKit.LINES[&"weapons"]["stats"][&"attack_damage_pct"]) * 100.0)),
			"armor": int(ForgeKit.LINES[&"armor"]["stats"][&"armor"]), "line": ForgeKit.line_name(kl),
			"text": ForgeKit.line_text(kl), "p1": ForgeKit.LEVEL_PRICE[0], "p2": ForgeKit.LEVEL_PRICE[1],
			"p3": ForgeKit.LEVEL_PRICE[2]})
	g["name_tmpl"] = "Forge upgrades"
	g["name_args"] = {}
	g["name"] = "Forge upgrades"
	out.append(g)
	var ul := ForgeKit.unit_line_of(id, t.faction)
	if ul != &"":
		var u := _templ({"key": "Forge", "name": ForgeKit.line_name(ul)},
			"Forge research once your keep is a Stronghold ({price} crystals, {time} s): {text}.",
			{"price": ForgeKit.UNIT_PRICE, "time": int(ForgeKit.UNIT_TIME), "text": ForgeKit.line_text(ul)})
		out.append(u)
	return out


## An ability whose text is a template: "text" = the English, "tmpl" / "args" let the screen show it in any language.
static func _templ(a: Dictionary, tmpl: String, args: Dictionary) -> Dictionary:
	a["tmpl"] = tmpl
	a["args"] = args
	a["text"] = tmpl.format(args)
	return a


## An ability's text in the current language (its "text" arg and plain texts go through Loc.sink).
static func ability_text(a: Dictionary) -> String:
	if a.has("tmpl"):
		var args: Dictionary = (a["args"] as Dictionary).duplicate()
		if args.has("text"):
			args["text"] = Loc.sink(String(args["text"]))
		return Loc.t(String(a["tmpl"]), args)
	return Loc.sink(String(a["text"]))


static func ability_name(a: Dictionary) -> String:
	if a.has("name_tmpl"):
		return Loc.t(String(a["name_tmpl"]), a["name_args"])
	return String(a["name"])


## The key badge ("Auto", "Passive", "Auto, L5", a hotkey letter, a building) in the current language.
static func key_label(k: String) -> String:
	if k.begins_with("Auto, L") and k.substr(7).is_valid_int():
		return Loc.t("Auto, L{n}", {"n": int(k.substr(7))})
	return Loc.t(k) if k.length() > 1 else k


# ---------------------------------------------------------------- portraits

## The unit's icon (art/icons/units/<id>.png) or null (the screen then draws its abbreviation tile). Cached.
static func icon_of(id: StringName) -> Texture2D:
	if _icons.has(id):
		return _icons[id]
	var path := ICON_DIR + String(id) + ".png"
	var tex: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_icons[id] = tex
	return tex


static func kingdom_name(k: StringName) -> String:
	return "Neutral" if k == NEUTRAL else String(k).capitalize()


## The kingdom name in the current language.
static func kingdom_label(k: StringName) -> String:
	return Loc.t(String(KINGDOM_NAMES.get(String(k), kingdom_name(k))))


## The role name in the current language.
static func role_label(role: String) -> String:
	return Loc.t(String(ROLE_NAMES.get(role, role)))


## Where the unit comes from, in the current language (building names stay English).
static func building_label(b: String) -> String:
	if b.ends_with(" (Citadel)"):
		return Loc.t("%s (Citadel)") % b.trim_suffix(" (Citadel)")
	if b.ends_with(" (Wonders)"):
		return Loc.t("%s (Wonders)") % b.trim_suffix(" (Wonders)")
	return Loc.t(b)


static func kingdom_color(k: StringName) -> Color:
	return Color(0.82, 0.76, 0.62) if k == NEUTRAL else UIStyle.kingdom_color(k)


# ---------------------------------------------------------------- filters

## The entries that match: kingdom (&"" = all), tier (0 = all), role ("" = all), search text (name, class, role,
## kingdom, building, tags; every word must match).
static func filter(kingdom: StringName, tier: int, role: String, search: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var words := search.strip_edges().to_lower().split(" ", false)
	for e in entries():
		if kingdom != &"" and e["kingdom"] != kingdom:
			continue
		if tier > 0 and int(e["tier"]) != tier:
			continue
		if role != "" and e["role"] != role:
			continue
		var ok := true
		var hay := _search_text(e) if not words.is_empty() else ""
		for w in words:
			if not hay.contains(w):
				ok = false
				break
		if ok:
			out.append(e)
	return out


## The search text of `e`: the English one, plus (another language) its translated class, role, kingdom and tags.
static func _search_text(e: Dictionary) -> String:
	if Loc.language == Loc.DEFAULT_LANG:
		return String(e["search"])
	var key := "search_" + Loc.language
	if not e.has(key):
		var parts: Array[String] = [String(e["search"]), Loc.t(String(e["class"])), role_label(String(e["role"])),
				kingdom_label(e["kingdom"]), building_label(String(e["building"]))]
		for f in ["strong", "weak", "good_with"]:
			for s: String in e[f]:
				parts.append(Loc.t(s))
		e[key] = " ".join(parts).to_lower()
	return String(e[key])


# ---------------------------------------------------------------- ranks and claims

## The comparison group of a scope: the units of one kingdom's army (workers out) or of any army (the 4 kingdoms).
static func group(scope_kingdom: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in entries():
		if e["kind"] == "helper" or e["role"] == "worker" or e["kingdom"] == NEUTRAL:
			continue
		if scope_kingdom == &"" or e["kingdom"] == scope_kingdom:
			out.append(e)
	return out


## 1-based rank of `id` for `stat` inside `scope_kingdom`'s army (&"" = any army); `best` "max" or "min".
## Ties share the best rank. 0 when the unit is not comparable.
static func rank(id: StringName, stat: String, scope_kingdom: StringName, best: String = "max") -> int:
	var me := entry(id)
	if me.is_empty():
		return 0
	var v := float(me["stats"][stat])
	var r := 1
	for e in group(scope_kingdom):
		var o := float(e["stats"][stat])
		if (best == "max" and o > v + 0.0005) or (best == "min" and o < v - 0.0005):
			r += 1
	return r


## Every rank claim in the unit's pros / cons / summary that is FALSE for today's numbers: ["<text>: <why>"].
## Phrases: EXTREMES ("Highest HP in the Fire army", "Cheapest unit in any army") and "Top N for <stat> in ...".
static func check_claims(id: StringName) -> Array[String]:
	var e := entry(id)
	var bad: Array[String] = []
	if e.is_empty():
		return bad
	var lines: Array[String] = []
	lines.append_array(e["pros"])
	lines.append_array(e["cons"])
	var phrases := "|".join(EXTREMES.keys())
	var rx := RegEx.create_from_string("(?i)\\b(" + phrases + ")\\b[^.;,]*?\\bin (the (fire|ice|nature|shadow) army|any army)")
	var rx_top := RegEx.create_from_string("(?i)\\btop (\\d+) for (" + "|".join(TOP_STATS.keys()) + ") in (the (fire|ice|nature|shadow) army|any army)")
	for line in lines:
		for m in rx.search_all(line):
			var spec: Array = EXTREMES[m.get_string(1).to_lower()]
			var scope := StringName(m.get_string(3).to_lower())
			var r := rank(id, spec[0], scope, spec[1])
			if r != 1:
				bad.append("%s: rank %d for %s in %s" % [line, r, spec[0], scope if scope != &"" else &"any army"])
		for m in rx_top.search_all(line):
			var n := int(m.get_string(1))
			var stat: String = TOP_STATS[m.get_string(2).to_lower()]
			var scope := StringName(m.get_string(4).to_lower())
			var r := rank(id, stat, scope, "max")
			if r > n:
				bad.append("%s: rank %d for %s" % [line, r, stat])
	return bad


## The claim lines that hold for `id` now (the generator's suggestions): extremes and top-3 in its army and any army.
static func suggest_claims(id: StringName) -> Array[String]:
	var e := entry(id)
	var out: Array[String] = []
	if e.is_empty() or e["kingdom"] == NEUTRAL or e["role"] == "worker" or e["kind"] == "helper":
		return out
	var k: StringName = e["kingdom"]
	for scope: StringName in [k, &""]:
		var where := "the %s army" % kingdom_name(k) if scope != &"" else "any army"
		for phrase: String in EXTREMES:
			var spec: Array = EXTREMES[phrase]
			if rank(id, spec[0], scope, spec[1]) == 1:
				out.append("%s in %s" % [phrase.capitalize(), where])
		for label: String in TOP_STATS:
			var r := rank(id, TOP_STATS[label], scope, "max")
			if r > 1 and r <= 3:
				out.append("Top 3 for %s in %s (rank %d)" % [label, where, r])
	return out


## Problems of the JSON text of `id`: missing / too long / unknown role ([] = fine).
static func lint(id: StringName) -> Array[String]:
	var e := entry(id)
	var out: Array[String] = []
	if e.is_empty():
		return ["unknown id"]
	if text_of(id).is_empty():
		out.append("no entry in %s" % JSON_PATH)
		return out
	if not ROLES.has(e["role"]):
		out.append("unknown role '%s'" % e["role"])
	if String(e["summary"]) == "":
		out.append("empty summary")
	if String(e["summary"]).length() > SUMMARY_MAX:
		out.append("summary longer than %d" % SUMMARY_MAX)
	if (e["pros"] as Array).size() != 3:
		out.append("%d pros (want 3)" % (e["pros"] as Array).size())
	if (e["cons"] as Array).size() < 2 or (e["cons"] as Array).size() > 3:
		out.append("%d cons (want 2-3)" % (e["cons"] as Array).size())
	for key in ["pros", "cons"]:
		for s: String in e[key]:
			if s.strip_edges() == "":
				out.append("empty line in %s" % key)
			elif s.length() > PRO_MAX:
				out.append("%s line longer than %d: %s" % [key, PRO_MAX, s])
	for key in ["strong", "weak", "good_with"]:
		if (e[key] as Array).is_empty():
			out.append("no %s tags" % key)
		for s: String in e[key]:
			if s.length() > TAG_MAX:
				out.append("tag longer than %d: %s" % [TAG_MAX, s])
	for a: Dictionary in e["abilities"]:
		if String(a["name"]) == "" or String(a["text"]) == "":
			out.append("ability without a name or text")
	return out

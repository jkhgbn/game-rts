extends RefCounted
## Unit Lab (docs/plan/unit-lab.md): the FIGHT SPEC. Parses a fight description (JSON file / Dictionary, a one-line
## text, a preset name, an equal-cost pair, a matrix) into one normalized Dictionary that the headless runner
## (tools/unit_lab/unit_lab_run.gd) and the sandbox (scenes/unit_lab.tscn) both play with UnitLabArena.
## Static functions only; reach it with preload("res://tools/unit_lab/unit_lab_spec.gd").
##
## Normalized spec:
##   {name, notes, arms: [{name, a: SIDE, b: SIDE}], seeds: [int], time_limit (s), tick, distance (m), arena (m),
##    variant ("" | path), checks: [..], matrix: {} (empty = no matrix), mode ("arms" | "matrix")}
## SIDE: {label, groups: [GROUP], order, focus, casters, formation, retreat_to: [x, z] | null, hero: {} }
##   order:     "attack_move" (default: attack-move at the enemy, idle units hunt the nearest enemy) | "hold" | "idle"
##              | "retreat" (move to retreat_to, fight nothing)
##   focus:     "none" (the game's own auto-aggro) | "lowest_hp" (every 0.5 s: the weakest enemy in reach)
##              | "casters" (Unit.prefer_casters, the bots' 8.2 rule)
##   casters:   "autocast" (the spells' default autocast flags), "on" (every spell autocast), "off" (no spell),
##              "bot" (the real AICasters bot brain, 8.2 positioning + 8.3 rules, through a stand-in commander)
##   formation: "auto" (melee in front, ranged / casters behind) | "line" | "block"
##   target:    [x, z] | null (the attack-move point; null = just past the enemy's start)
##   hunt:      true (default: idle attack-move units go for the nearest enemy every second) | false
##   bot_difficulty: 0-2 for "bot" casters (AICasters: easy / normal / hard rules), default 1
## GROUP: {id, count, level (1-4), plus (bool: the "+" upgrade), mods {stat: value} (Stats modifiers, e.g.
##   {"attack_damage_pct": 0.25}), statuses [[id, seconds]], hp_pct (0-1], mana (-1 = the game's start, else
##   the number; "full" = max), autocast (null = the side's casters rule, else bool), at [x, z] | null (absolute
##   centre; null = the side's spawn spot), bowman [upgrade ids] (BowmanUpgrades granted to the side's team)}
## Text line (one fight; see parse_text):
##   "6 flame_guard + 1 kilnwarden mana=full vs 7 rimeshield ; dist=20 seeds=10 limit=90"
##   "flame_guard ~ rimeshield @720"   (equal-cost: armies of ~720 crystals each)
##   "flame_guard ~ rimehorn_rider @720 ; basis=pop pop=8"   (equal supply; basis=both: both budgets, see equal_cost)

const PRESET_DIR := "res://tools/unit_lab/presets/"
const KINGDOMS: Array[String] = ["fire", "ice", "nature", "shadow"]
const ORDERS: Array[String] = ["attack_move", "hold", "idle", "retreat"]
const FOCUS: Array[String] = ["none", "lowest_hp", "casters"]
const CASTER_MODES: Array[String] = ["autocast", "on", "off", "bot"]
const FORMATIONS: Array[String] = ["auto", "line", "block"]
const DEFAULT_BUDGET := 720
## Equal-army bases (equal_cost): crystals, supply, or both budgets at once (whichever binds first).
const BASES: Array[String] = ["cost", "pop", "both"]
## Crystals per pop of the median trained T1 / T2 unit: the pop budget that matches a crystal budget (720 -> 8).
const CRYSTALS_PER_POP := 90.0
const DEFAULT_LIMIT := 120.0
const DEFAULT_DISTANCE := 20.0
const DEFAULT_ARENA := 80.0
## The kingdom's first-line unit (caster-units.md 7.2 controls): the filler of a caster entry in the matrix.
const LINE_UNIT := {"fire": "flame_guard", "ice": "rimeshield", "nature": "thornling", "shadow": "shade"}
const CASTER_IDS: Array[String] = ["kilnwarden", "rimecarver", "bramblesage", "gloom_deacon"]
## Group keys that are not Stats modifiers in the text format.
const GROUP_KEYS: Array[String] = ["level", "lv", "plus", "mana", "hp", "hp_pct", "autocast", "at", "bowman"]
const SIDE_KEYS: Array[String] = ["order", "focus", "casters", "formation", "retreat_to", "label", "hero"]


# ---------------------------------------------------------------- entry points

## Any input -> normalized spec. `src`: a Dictionary, a JSON file path (res:// or absolute), a preset name
## (tools/unit_lab/presets/<name>.json), or a text line (contains " vs " or " ~ "). `errors` gets the problems
## (an empty spec with no arms comes back when nothing could be read).
static func load_any(src: Variant, errors: Array) -> Dictionary:
	if src is Dictionary:
		return normalize(src as Dictionary, errors)
	var s := String(src).strip_edges()
	if s.contains(" vs ") or s.contains(" ~ "):
		return parse_text(s, errors)
	var path := s
	if not (s.ends_with(".json")):
		path = PRESET_DIR + s + ".json"
	var data: Variant = read_json(path)
	if not (data is Dictionary):
		errors.append("can't read spec %s" % path)
		return normalize({}, errors)
	return normalize(data as Dictionary, errors)


static func read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return data


## Preset names in tools/unit_lab/presets/ (without .json), sorted.
static func preset_names() -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(PRESET_DIR)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".json"):
			out.append(f.get_basename())
	out.sort()
	return out


# ---------------------------------------------------------------- normalize

## A raw spec Dictionary -> the normalized form (defaults filled, ids checked). Accepted shapes:
##   {"a": SIDE, "b": SIDE, ...}                       one arm named "main"
##   {"arms": [{"name", "a", "b"}], ...}               several arms (caster arm / control arm)
##   {"equal": {"a": id, "b": id, "budget": 720}, ...} equal-cost armies built by equal_cost()
##       (+ "basis": "cost" | "pop" | "both", "pop_budget": 8; the same two keys in "matrix")
##   {"matrix": {...}}                                  see matrix_entries()
static func normalize(raw: Dictionary, errors: Array) -> Dictionary:
	var spec := {
		"name": String(raw.get("name", "unnamed")),
		"notes": String(raw.get("notes", "")),
		"arms": [],
		"seeds": parse_seeds(raw.get("seeds", 10)),
		"time_limit": float(raw.get("time_limit", raw.get("limit", DEFAULT_LIMIT))),
		"tick": int(raw.get("tick", 60)),
		"distance": float(raw.get("distance", raw.get("dist", DEFAULT_DISTANCE))),
		"arena": float(raw.get("arena", DEFAULT_ARENA)),
		"variant": String(raw.get("variant", "")),
		"checks": raw.get("checks", []) if raw.get("checks", []) is Array else [],
		"matrix": {},
		"mode": "arms",
	}
	if raw.has("matrix") and raw["matrix"] is Dictionary:
		spec["matrix"] = normalize_matrix(raw["matrix"] as Dictionary, errors)
		spec["mode"] = "matrix"
		return spec
	if raw.has("equal") and raw["equal"] is Dictionary:
		spec["arms"].append(equal_arm(raw["equal"] as Dictionary, "equal", errors))
	if raw.has("a") and raw.has("b"):
		spec["arms"].append({"name": String(raw.get("arm", "main")),
				"a": normalize_side(raw["a"], errors), "b": normalize_side(raw["b"], errors)})
	for arm: Variant in raw.get("arms", []):
		if not (arm is Dictionary):
			errors.append("an arm must be an object")
			continue
		var ad: Dictionary = arm
		var arm_name := String(ad.get("name", "arm%d" % spec["arms"].size()))
		if ad.get("equal") is Dictionary:
			spec["arms"].append(equal_arm(ad["equal"] as Dictionary, arm_name, errors))
			continue
		var na := {"name": arm_name,
				"a": normalize_side(ad.get("a", {}), errors), "b": normalize_side(ad.get("b", {}), errors)}
		for s: String in ["a", "b"]:
			if ad.get("fill_" + s) is Dictionary:
				var fg := fill_groups(ad["fill_" + s] as Dictionary, errors)
				na[s]["groups"] = fg
				na[s]["label"] = side_label(na[s])
		spec["arms"].append(na)
	if spec["arms"].is_empty() and errors.is_empty():
		errors.append("the spec has no fight (a / b, arms, equal or matrix)")
	return spec


## {"a": entry, "b": entry, "budget", "basis", "pop_budget", "mana" (the fixed casters' start mana; default "full"),
##  "a_opts" / "b_opts" (side keys)} -> one normalized arm. Also accepted inside "arms" ({"name", "equal": {...}}), so
## one spec can hold several equal-cost duels (e.g. each caster entry vs its own line unit).
static func equal_arm(e: Dictionary, arm_name: String, errors: Array) -> Dictionary:
	var pair := equal_cost(String(e.get("a", "")), String(e.get("b", "")), int(e.get("budget", DEFAULT_BUDGET)),
			errors, String(e.get("basis", "cost")), int(e.get("pop_budget", 0)))
	if e.has("mana"):
		for sd: Dictionary in pair:
			for g: Dictionary in sd.get("groups", []):
				if CASTER_IDS.has(String(g.get("id", ""))):
					g["mana"] = e["mana"]
	var a := normalize_side(pair[0], errors)
	var b := normalize_side(pair[1], errors)
	_copy_side_opts(e.get("a_opts", {}), a, errors)
	_copy_side_opts(e.get("b_opts", {}), b, errors)
	return {"name": arm_name, "a": a, "b": b}


## An arm side's groups filled from an entry at a budget, against any fixed opponent: {"entry":
## "kilnwarden+flame_guard", "budget": 900, "basis": "cost" | "pop" | "both", "pop_budget", "mana"} -> the groups
## whose spend is nearest the budget (arms key "fill_a" / "fill_b"; the rest of that side's keys still apply). Built
## when the spec loads, so a variant's new costs re-size it (a caster arm and a control arm at the same budget).
static func fill_groups(f: Dictionary, errors: Array) -> Array:
	var parts := entry_parts(String(f.get("entry", "")), errors)
	if parts.is_empty():
		return []
	var budget := int(f.get("budget", DEFAULT_BUDGET))
	var basis := String(f.get("basis", "cost"))
	if not BASES.has(basis):
		errors.append("unknown basis '%s' (use %s)" % [basis, ", ".join(BASES)])
		basis = "cost"
	var pb := float(int(f.get("pop_budget", 0)) if int(f.get("pop_budget", 0)) > 0 else default_pop_budget(budget))
	var best := 1
	var best_d := INF
	for n in range(1, 61):
		var d := absf(entry_spend(parts, n, basis, budget, pb) - 1.0)
		if d < best_d:
			best_d = d
			best = n
	var groups: Array = []
	for g: Dictionary in entry_side(parts, best)["groups"]:
		if f.has("mana") and CASTER_IDS.has(String(g["id"])):
			g["mana"] = f["mana"]
		var ng := normalize_group(g, errors)
		if not ng.is_empty():
			groups.append(ng)
	return groups


static func _copy_side_opts(opts: Variant, side: Dictionary, errors: Array) -> void:
	if not (opts is Dictionary):
		return
	var tmp := normalize_side(opts, errors)
	for k: String in ["order", "focus", "casters", "formation", "retreat_to", "target", "hunt", "bot_difficulty"]:
		if (opts as Dictionary).has(k):
			side[k] = tmp[k]


## A side: a Dictionary {groups | units: [...], order...}, an Array of groups, or a text ("6 shade + 1 gloom_deacon").
static func normalize_side(raw: Variant, errors: Array) -> Dictionary:
	if raw is String:
		return parse_side_text(raw as String, errors)
	var side := {"label": "", "groups": [], "order": "attack_move", "focus": "none", "casters": "autocast",
			"formation": "auto", "retreat_to": null, "target": null, "hunt": true, "bot_difficulty": 1, "hero": {}}
	var d: Dictionary = {}
	if raw is Array:
		d = {"groups": raw}
	elif raw is Dictionary:
		d = raw
	else:
		errors.append("a side must be an object, a list or a text")
		return side
	var list: Variant = d.get("groups", d.get("units", []))
	if list is Array:
		for g: Variant in list:
			var ng := normalize_group(g, errors)
			if not ng.is_empty():
				side["groups"].append(ng)
	side["order"] = _pick(String(d.get("order", "attack_move")), ORDERS, "order", errors)
	side["focus"] = _pick(String(d.get("focus", "none")), FOCUS, "focus", errors)
	side["casters"] = _pick(String(d.get("casters", "autocast")), CASTER_MODES, "casters", errors)
	side["formation"] = _pick(String(d.get("formation", "auto")), FORMATIONS, "formation", errors)
	if d.get("retreat_to") is Array and (d["retreat_to"] as Array).size() >= 2:
		side["retreat_to"] = [float(d["retreat_to"][0]), float(d["retreat_to"][1])]
	if d.get("target") is Array and (d["target"] as Array).size() >= 2:
		side["target"] = [float(d["target"][0]), float(d["target"][1])]
	side["hunt"] = bool(d.get("hunt", true))
	side["bot_difficulty"] = clampi(int(d.get("bot_difficulty", 1)), 0, 2)
	if d.get("hero") is Dictionary:
		side["hero"] = d["hero"]
	elif d.get("hero") is String and String(d["hero"]) != "":
		side["hero"] = {"kingdom": String(d["hero"])}
	side["label"] = String(d.get("label", side_label(side)))
	return side


static func _pick(v: String, allowed: Array[String], what: String, errors: Array) -> String:
	if allowed.has(v):
		return v
	errors.append("unknown %s '%s' (use %s)" % [what, v, ", ".join(allowed)])
	return allowed[0]


## {"id": "flame_guard", "count": 6, ...} or "6 flame_guard" -> a normalized group ({} when the id is unknown).
static func normalize_group(raw: Variant, errors: Array) -> Dictionary:
	if raw is String:
		return parse_group_text(raw as String, errors)
	if not (raw is Dictionary):
		errors.append("a group must be an object or a text")
		return {}
	var d: Dictionary = raw
	var id := String(d.get("id", d.get("unit", "")))
	if UnitType.find(id) == null:
		errors.append("unknown unit id '%s'" % id)
		return {}
	var g := {"id": id, "count": maxi(1, int(d.get("count", 1))), "level": clampi(int(d.get("level", 1)), 1, 4),
			"plus": bool(d.get("plus", false)), "mods": {}, "statuses": [], "hp_pct": clampf(float(d.get("hp_pct",
			d.get("hp", 1.0))), 0.01, 1.0), "mana": -1.0, "autocast": null, "at": null, "bowman": []}
	if d.get("mods") is Dictionary:
		for k: Variant in d["mods"]:
			g["mods"][String(k)] = float(d["mods"][k])
	if d.get("statuses") is Array:
		for s: Variant in d["statuses"]:
			if s is Array and (s as Array).size() >= 2:
				g["statuses"].append([String(s[0]), float(s[1])])
			elif s is String:
				g["statuses"].append([String(s), 10.0])
	var mana: Variant = d.get("mana", -1.0)
	g["mana"] = 1.0e9 if (mana is String and String(mana) == "full") else float(mana)
	if d.has("autocast") and d["autocast"] != null:
		g["autocast"] = bool(d["autocast"])
	if d.get("at") is Array and (d["at"] as Array).size() >= 2:
		g["at"] = [float(d["at"][0]), float(d["at"][1])]
	if d.get("bowman") is Array:
		for b: Variant in d["bowman"]:
			g["bowman"].append(String(b))
	return g


# ---------------------------------------------------------------- text format

## "6 flame_guard + 1 kilnwarden mana=full vs 7 rimeshield order=hold ; dist=20 seeds=1-10 limit=90"
## "flame_guard ~ rimeshield @720 ; seeds=8"
## Sides split on " vs " (or " ~ " for equal cost); groups on " + " or ","; a group is "[N] id [key=value ...]"
## (keys: level, plus, mana=full|N, hp=0.4, autocast=on|off, at=x:z, any Stats key such as attack_damage_pct=0.25);
## side keys (order, focus, casters, formation, retreat_to=x:z) may sit in any group of that side. Options after ";":
## dist, seeds, limit, tick, arena, name.
static func parse_text(line: String, errors: Array) -> Dictionary:
	var main_part := line
	var opts := {}
	var semi := line.find(";")
	if semi < 0:
		semi = line.find("|")
	if semi >= 0:
		main_part = line.substr(0, semi)
		for tok in line.substr(semi + 1).strip_edges().split(" ", false):
			var kv := tok.split("=")
			if kv.size() == 2:
				opts[kv[0]] = kv[1]
	var raw := {"name": String(opts.get("name", "text"))}
	for k: String in ["dist", "seeds", "limit", "tick", "arena"]:
		if opts.has(k):
			raw[k] = opts[k] if k == "seeds" else float(opts[k])
	if main_part.contains(" ~ "):
		var parts := main_part.split(" ~ ")
		var budget := DEFAULT_BUDGET
		var b_text := parts[1].strip_edges()
		var at := b_text.find("@")
		if at >= 0:
			budget = b_text.substr(at + 1).strip_edges().to_int()
			b_text = b_text.substr(0, at).strip_edges()
		raw["equal"] = {"a": parts[0].strip_edges(), "b": b_text, "budget": budget,
				"basis": String(opts.get("basis", "cost")), "pop_budget": String(opts.get("pop", "0")).to_int()}
	else:
		var sides := main_part.split(" vs ")
		if sides.size() != 2:
			errors.append("a text fight needs exactly one ' vs ' (or ' ~ ')")
			return normalize({}, errors)
		raw["a"] = sides[0].strip_edges()
		raw["b"] = sides[1].strip_edges()
	return normalize(raw, errors)


static func parse_side_text(text: String, errors: Array) -> Dictionary:
	var side := normalize_side({}, errors)
	var groups: Array = []
	var cleaned := text.replace(" + ", ",")
	for part in cleaned.split(",", false):
		var p := part.strip_edges()
		if p == "":
			continue
		# side keys inside the group text
		var keep: Array[String] = []
		for tok in p.split(" ", false):
			var kv := tok.split("=")
			if kv.size() == 2 and SIDE_KEYS.has(kv[0]):
				if kv[0] == "retreat_to":
					var xz := kv[1].split(":")
					if xz.size() == 2:
						side["retreat_to"] = [xz[0].to_float(), xz[1].to_float()]
				elif kv[0] == "hero":
					side["hero"] = {"kingdom": kv[1]}
				else:
					side[kv[0]] = kv[1]
			else:
				keep.append(tok)
		if keep.is_empty():
			continue
		var g := parse_group_text(" ".join(keep), errors)
		if not g.is_empty():
			groups.append(g)
	side["groups"] = groups
	side["order"] = _pick(String(side["order"]), ORDERS, "order", errors)
	side["focus"] = _pick(String(side["focus"]), FOCUS, "focus", errors)
	side["casters"] = _pick(String(side["casters"]), CASTER_MODES, "casters", errors)
	side["formation"] = _pick(String(side["formation"]), FORMATIONS, "formation", errors)
	side["label"] = side_label(side)
	return side


## "6 flame_guard level=2 plus attack_damage_pct=0.25" -> group.
static func parse_group_text(text: String, errors: Array) -> Dictionary:
	var toks := text.strip_edges().split(" ", false)
	var d := {"count": 1, "mods": {}}
	for tok in toks:
		if tok.is_valid_int() and not d.has("id"):
			d["count"] = tok.to_int()
		elif tok.to_lower().ends_with("x") and tok.substr(0, tok.length() - 1).is_valid_int() and not d.has("id"):
			d["count"] = tok.substr(0, tok.length() - 1).to_int()
		elif not tok.contains("="):
			if tok == "plus" or tok == "+":
				d["plus"] = true
			elif not d.has("id"):
				d["id"] = tok
			else:
				errors.append("unexpected word '%s' in '%s'" % [tok, text])
		else:
			var kv := tok.split("=")
			var k := kv[0]
			var v := kv[1]
			match k:
				"level", "lv":
					d["level"] = v.to_int()
				"mana":
					d["mana"] = "full" if v == "full" else v.to_float()
				"hp", "hp_pct":
					d["hp_pct"] = v.to_float()
				"autocast":
					d["autocast"] = v in ["on", "1", "true", "yes"]
				"at":
					var xz := v.split(":")
					if xz.size() == 2:
						d["at"] = [xz[0].to_float(), xz[1].to_float()]
				"status":
					var sv := v.split(":")
					d["statuses"] = [[sv[0], sv[1].to_float() if sv.size() > 1 else 10.0]]
				"bowman":
					d["bowman"] = v.split(":")
				_:
					if v.is_valid_float():
						d["mods"][k] = v.to_float()
					else:
						errors.append("bad value %s=%s" % [k, v])
	return normalize_group(d, errors)


# ---------------------------------------------------------------- equal cost

## Two armies of about `budget` crystals each from two ids (cost-equal normaliser). Each entry may be a plain id
## ("rimeshield") or a caster entry "kilnwarden+flame_guard" (1 caster, the rest of the budget in the filler).
## Counts are picked so the two totals are as close as possible (ratio first, then nearness to the budget).
## `basis` (BASES): "cost" = equal crystals (default), "pop" = equal supply (`pop_budget`), "both" = each army is
## sized by whichever budget binds first (spend = max(crystals / budget, pop / pop_budget)), the armies' spends equal:
## the real-match limit when both the bank and the supply cap count. `pop_budget` <= 0 = budget / CRYSTALS_PER_POP.
## Returns [side_a_dict, side_b_dict] (raw sides, normalize_side them).
static func equal_cost(a: String, b: String, budget: int, errors: Array, basis: String = "cost",
		pop_budget: int = 0) -> Array:
	var ea := entry_parts(a, errors)
	var eb := entry_parts(b, errors)
	if ea.is_empty() or eb.is_empty():
		return [{}, {}]
	if not BASES.has(basis):
		errors.append("unknown basis '%s' (use %s)" % [basis, ", ".join(BASES)])
		basis = "cost"
	var pb := float(pop_budget if pop_budget > 0 else default_pop_budget(budget))
	var best := [1, 1]
	var best_score := INF
	for na in range(1, 61):
		var ta := entry_spend(ea, na, basis, budget, pb)
		if ta > 1.6:
			break
		# best nb for this na: scan from 1 up (spend grows with nb)
		for k in range(1, 61):
			var tb := entry_spend(eb, k, basis, budget, pb)
			var ratio := absf(ta / tb - 1.0)
			var near := absf((ta + tb) * 0.5 - 1.0)
			var score := ratio + 0.15 * near
			if score < best_score:
				best_score = score
				best = [na, k]
			if tb > ta * 1.5:
				break
	return [entry_side(ea, best[0]), entry_side(eb, best[1])]


## What an entry with `n` filler units spends, as a fraction of the budget (see equal_cost's `basis`).
static func entry_spend(parts: Dictionary, n: int, basis: String, budget: int, pop_budget: float) -> float:
	var c := (float(parts["fixed_cost"]) + float(parts["unit_cost"]) * n) / maxf(1.0, float(budget))
	var p := (float(parts["fixed_pop"]) + float(parts["unit_pop"]) * n) / maxf(1.0, pop_budget)
	match basis:
		"pop":
			return p
		"both":
			return maxf(c, p)
	return c


## The supply that matches a crystal budget (median trained T1 / T2 unit: ~90 crystals per pop; 720 -> 8 pop).
static func default_pop_budget(budget: int) -> int:
	return maxi(1, roundi(float(budget) / CRYSTALS_PER_POP))


## "kilnwarden+flame_guard" -> {fixed: [{id, count, mana}], unit: "flame_guard", unit_cost, fixed_cost}.
## A plain id -> {fixed: [], unit: id, unit_cost, fixed_cost 0}. {} when an id is unknown.
static func entry_parts(entry: String, errors: Array) -> Dictionary:
	var parts := entry.strip_edges().split("+")
	var fixed: Array = []
	var fixed_cost := 0
	var fixed_pop := 0
	var unit := parts[parts.size() - 1].strip_edges()
	for i in range(0, parts.size() - 1):
		var fid := parts[i].strip_edges()
		var ft := UnitType.find(fid)
		if ft == null:
			errors.append("unknown unit id '%s'" % fid)
			return {}
		fixed.append({"id": fid, "count": 1, "mana": "full" if CASTER_IDS.has(fid) else -1})
		fixed_cost += ft.cost
		fixed_pop += ft.pop
	var t := UnitType.find(unit)
	if t == null:
		errors.append("unknown unit id '%s'" % unit)
		return {}
	return {"fixed": fixed, "unit": unit, "unit_cost": maxi(1, t.cost), "fixed_cost": fixed_cost,
			"unit_pop": maxi(1, t.pop), "fixed_pop": fixed_pop, "entry": entry}


static func entry_side(parts: Dictionary, n: int) -> Dictionary:
	var groups: Array = []
	for f: Dictionary in parts["fixed"]:
		groups.append(f.duplicate())
	groups.append({"id": parts["unit"], "count": n})
	return {"groups": groups, "label": "%s x%d" % [parts["entry"], n]}


# ---------------------------------------------------------------- matrix

## {"kingdoms": ["fire", ...], "tiers": [1, 2], "casters": true, "ids": [...], "budget": 720, "cross": true}
## -> {entries: [entry text], budget, cross}. `ids` (explicit list) wins over kingdoms / tiers. Casters become
## "caster+line unit" entries (caster-units.md 7.1: a caster is judged inside its kingdom's line, full mana).
static func normalize_matrix(raw: Dictionary, errors: Array) -> Dictionary:
	var entries: Array[String] = []
	if raw.get("ids") is Array and not (raw["ids"] as Array).is_empty():
		for v: Variant in raw["ids"]:
			var s := String(v)
			if entry_parts(s, errors).is_empty():
				continue
			entries.append(s)
	else:
		var kingdoms: Array = raw.get("kingdoms", KINGDOMS)
		var tiers: Array = raw.get("tiers", [1, 2])
		var with_casters := bool(raw.get("casters", true))
		for k: Variant in kingdoms:
			for id in roster(String(k), tiers):
				entries.append(id)
			if with_casters:
				var c := String(CasterKit.caster_for(StringName(String(k))))
				if c != "" and LINE_UNIT.has(String(k)):
					entries.append("%s+%s" % [c, LINE_UNIT[String(k)]])
	var basis := String(raw.get("basis", "cost"))
	if not BASES.has(basis):
		errors.append("unknown basis '%s' (use %s)" % [basis, ", ".join(BASES)])
		basis = "cost"
	var budget := int(raw.get("budget", DEFAULT_BUDGET))
	var pop_budget := int(raw.get("pop_budget", 0))
	return {"entries": entries, "budget": budget, "basis": basis,
			"pop_budget": pop_budget if pop_budget > 0 else default_pop_budget(budget),
			"mirror": bool(raw.get("mirror", false)), "kingdom_of": _kingdom_map(entries)}


static func _kingdom_map(entries: Array[String]) -> Dictionary:
	var out := {}
	for e in entries:
		var parts := e.split("+")
		var t := UnitType.find(parts[parts.size() - 1])
		out[e] = String(t.faction) if t else ""
	return out


## The trained soldiers of a kingdom up to the given tiers (casters excluded: they enter as caster entries): every
## data/units/*.tres of that faction with cost > 0, not a worker / caravan / non-commandable unit / timed summon,
## requires_tier in `tiers`. Sorted by tier, then cost.
static func roster(kingdom: String, tiers: Array) -> Array[String]:
	var rows: Array = []
	var d := DirAccess.open(UnitType.DIR)
	if d == null:
		return []
	for f in d.get_files():
		if not f.ends_with(".tres"):
			continue
		var t := UnitType.find(f.get_basename())
		if t == null or String(t.faction) != kingdom or t.cost <= 0 or t.is_worker or t.is_caravan \
				or not t.commandable or t.lifetime > 0.0 or CASTER_IDS.has(String(t.id)):
			continue
		if not tiers.has(t.requires_tier) and not tiers.has(float(t.requires_tier)):
			continue
		rows.append([t.requires_tier, t.cost, String(t.id)])
	rows.sort()
	var out: Array[String] = []
	for r: Array in rows:
		out.append(r[2])
	return out


## Matrix pairs (i < j; plus i == i when `mirror`), in a stable order.
static func matrix_pairs(m: Dictionary) -> Array:
	var out: Array = []
	var e: Array = m["entries"]
	for i in e.size():
		for j in range(i if bool(m.get("mirror", false)) else i + 1, e.size()):
			out.append([e[i], e[j]])
	return out


## One matrix pair -> an arm (equal cost / pop / both at the matrix budgets, `basis`).
static func matrix_arm(m: Dictionary, a: String, b: String, errors: Array) -> Dictionary:
	var pair := equal_cost(a, b, int(m["budget"]), errors, String(m.get("basis", "cost")), int(m.get("pop_budget", 0)))
	return {"name": "%s|%s" % [a, b], "a": normalize_side(pair[0], errors), "b": normalize_side(pair[1], errors),
			"entry_a": a, "entry_b": b}


# ---------------------------------------------------------------- helpers

## "1-10" -> [1..10]; "1,3,5"; 10 -> [1..10]; [1, 2] as is.
static func parse_seeds(v: Variant) -> Array[int]:
	var out: Array[int] = []
	if v is Array:
		for x: Variant in v:
			out.append(int(x))
		return out
	if v is int or v is float:
		for i in range(1, int(v) + 1):
			out.append(i)
		return out
	var s := String(v).strip_edges()
	for part in s.split(",", false):
		if part.contains("-"):
			var ab := part.split("-")
			for i in range(ab[0].to_int(), ab[1].to_int() + 1):
				out.append(i)
		elif part.is_valid_int():
			out.append(part.to_int())
	return out


## "6 flame_guard + 1 kilnwarden".
static func side_label(side: Dictionary) -> String:
	var parts: Array[String] = []
	for g: Dictionary in side.get("groups", []):
		parts.append("%d %s%s" % [int(g["count"]), g["id"], "+" if bool(g.get("plus", false)) else ""])
	return " + ".join(parts) if not parts.is_empty() else "(empty)"


## Crystals and pop of a side.
static func side_cost(side: Dictionary) -> Vector2i:
	var c := 0
	var p := 0
	for g: Dictionary in side.get("groups", []):
		var t := UnitType.find(String(g["id"]))
		if t:
			c += t.cost * int(g["count"])
			p += t.pop * int(g["count"])
	return Vector2i(c, p)


## The spec as a JSON-ready Dictionary for one arm (what the sandbox saves; load_any reads it back).
static func arm_to_raw(spec: Dictionary, arm: Dictionary) -> Dictionary:
	return {"name": spec.get("name", "sandbox"), "a": arm["a"], "b": arm["b"], "seeds": spec.get("seeds", [1]),
			"time_limit": spec.get("time_limit", DEFAULT_LIMIT), "distance": spec.get("distance", DEFAULT_DISTANCE),
			"arena": spec.get("arena", DEFAULT_ARENA), "tick": spec.get("tick", 60)}

extends SceneTree
## Unit Guide generator (docs/design/unit-guide.md). Reads the game data through UnitGuideData and prints, per unit:
## its numbers with their rank in its kingdom's army and in any army, the rank claims that hold today (copy them into
## pros / cons), suggested role and tags, and the problems of its data/ui/unit_guide.json block (lint + false claims).
## Run:
##   & tools/godot_run.ps1 --headless --path . -s res://tools/unit_guide/gen_guide.gd --quit-after 2000
##   ... '--' write          also adds a skeleton block (role, suggested claims as pros, tags) for every roster id
##                           missing from the JSON; existing blocks are never touched
##   ... '--' only=<id,id>   print only these units
## Exit code: 0 = every entry clean, 1 = lint problems or false claims (the test fails on the same things).

const STATS: Array[String] = ["hp", "dps", "damage", "range", "speed", "armor", "sight", "ehp", "crystals",
		"hp_per_crystal", "dps_per_crystal"]


func _initialize() -> void:
	var write := false
	var only: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a == "write":
			write = true
		elif a.begins_with("only="):
			only.assign(a.substr(5).split(",", false))
	UnitGuideData.reset()
	var problems := 0
	var missing: Array[StringName] = []
	for e in UnitGuideData.entries():
		var id: StringName = e["id"]
		if UnitGuideData.text_of(id).is_empty():
			missing.append(id)
		if not only.is_empty() and not only.has(String(id)):
			continue
		var s: Dictionary = e["stats"]
		print("\n== %s (%s, %s, tier %d, %s) role=%s suggested=%s" % [e["name"], id, e["kingdom"], e["tier"],
				e["building"], e["role"], UnitGuideData.suggest_role(id, e["kind"])])
		var parts: Array[String] = []
		for st in STATS:
			var best := "min" if st == "crystals" else "max"
			var rk := UnitGuideData.rank(id, st, e["kingdom"], best) if e["kingdom"] != UnitGuideData.NEUTRAL else 0
			var rk_all := UnitGuideData.rank(id, st, &"", best)
			parts.append("%s %s (#%d/%d, all #%d)" % [st, _num(s[st]), rk, UnitGuideData.group(e["kingdom"]).size(), rk_all])
		print("   " + "  ".join(parts))
		for c in UnitGuideData.suggest_claims(id):
			print("   claim: " + c)
		print("   tags: strong %s | weak %s | good with %s" % suggest_tags(e))
		for p in UnitGuideData.lint(id) + UnitGuideData.check_claims(id):
			print("   PROBLEM: " + p)
			problems += 1
	if write and not missing.is_empty():
		_write_skeletons(missing)
	var stale: Array[String] = []
	var ids := UnitGuideData.ids()
	for key: String in (UnitGuideData.json().get("units", {}) as Dictionary):
		if not ids.has(StringName(key)):
			stale.append(key)
	print("\nUNIT GUIDE: %d units, %d without a JSON block%s, %d stale JSON ids %s, %d problems" % [ids.size(),
			missing.size(), " (skeletons written)" if write and not missing.is_empty() else "", stale.size(), stale,
			problems])
	quit(0 if problems == 0 and stale.is_empty() and (missing.is_empty() or write) else 1)


static func _num(v: Variant) -> String:
	return str(v) if v is int else ("%.1f" % float(v)).trim_suffix(".0")


## [strong, weak, good_with] tag suggestions from the role and the data (edit them by hand).
static func suggest_tags(e: Dictionary) -> Array:
	var s: Dictionary = e["stats"]
	var strong: Array[String] = []
	var weak: Array[String] = []
	var good: Array[String] = []
	match String(e["role"]):
		"ranged", "siege":
			strong.append("Slow melee")
			weak.append_array(["Cavalry", "Fast raiders"])
			good.append("Line infantry")
		"cavalry":
			strong.append_array(["Archers", "Siege", "Casters"])
			weak.append("Armoured line")
			good.append("Ranged support")
		"caster":
			weak.append_array(["Cavalry", "Mana burn"])
			good.append("Line infantry")
		"support":
			weak.append("Cavalry")
			good.append("Line infantry")
		_:
			strong.append("Ranged in reach")
			weak.append("Kiting archers")
			good.append("Healers")
	if float(s["armor"]) >= 15.0:
		strong.append("Ranged chip damage")
		weak.append("Armour shred")
	if String(s["on_hit"]) == "chill":
		strong.append("Cavalry")
	return [strong, weak, good]


func _write_skeletons(missing: Array[StringName]) -> void:
	var data := UnitGuideData.json().duplicate(true)
	if not data.has("units"):
		data["units"] = {}
	for id in missing:
		var e := UnitGuideData.entry(id)
		var tags := suggest_tags(e)
		var claims := UnitGuideData.suggest_claims(id)
		var pros: Array[String] = []
		for c in claims:
			if pros.size() < 3 and not c.begins_with("Top 3"):
				pros.append(c)
		while pros.size() < 3:
			pros.append("TODO")
		data["units"][String(id)] = {"role": UnitGuideData.suggest_role(id, e["kind"]), "class": "",
			"pros": pros, "cons": ["TODO", "TODO"], "strong_against": tags[0], "weak_against": tags[1],
			"good_with": tags[2]}
	var f := FileAccess.open(UnitGuideData.JSON_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t", false))
	f.close()
	UnitGuideData.reset()

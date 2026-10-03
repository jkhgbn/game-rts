extends RefCounted
## Spot spacing of a MapLayout (review H2, 2026-10-02): one rule set shared by World Forge L3 (FAIL), the `gen` grid
## score (candidates with a spacing FAIL are rejected) and Map Lab v2 R4. Thornwater shipped with two Magpie Dens
## 1.9 m apart, two Lodges 1.0 m apart and a shrine 2.3 m from the peddler: L3 was only a WARN and gen never scored it.
## Rules (slots and starts excepted; they are build sites / wizard starts, not objects):
## - any two spots closer than MIN_SPOT (3 m) are stacked: FAIL;
## - two structures (keep, tavern, peddler, trade post, guild house, capture point) closer than STRUCT_GAP (6 m):
##   their footprints / capture ring overlap: FAIL;
## - two guild houses of the same kind (den / lodge) in one symmetry image: a template already brings one: FAIL.
## No class_name on purpose (preloaded tool script).

const MIN_SPOT := 3.0
const STRUCT_GAP := 6.0
const STRUCTS: Array[String] = ["keep", "tavern", "peddler", "post", "guild", "point"]


## The guild kind of a guild spot ("den" / "lodge"), as LayoutLevel decides it.
static func guild_kind(s: Dictionary) -> String:
	var base := String(s.get("twin_of", s["id"])).to_lower()
	return "den" if String(s.get("sub", "")) == "den" or base.contains("den") or base.contains("magpie") else "lodge"


## Every spacing violation: [{a, b, d, need, rule, hint}] (a / b are spot ids; one entry per pair).
static func findings(lay: MapLayout) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var spots: Array[Dictionary] = []
	for s: Dictionary in lay.spots:
		if not String(s["kind"]) in ["slot", "start"]:
			spots.append(s)
	for i in spots.size():
		var a: Dictionary = spots[i]
		for j in range(i + 1, spots.size()):
			var b: Dictionary = spots[j]
			var d := Vector2((a["pos"] as Vector3).x - (b["pos"] as Vector3).x, (a["pos"] as Vector3).z - (b["pos"] as Vector3).z).length()
			var both := STRUCTS.has(String(a["kind"])) and STRUCTS.has(String(b["kind"]))
			var need := STRUCT_GAP if both else MIN_SPOT
			if d >= need:
				continue
			var hint := ""
			if String(a.get("twin_of", a["id"])) == String(b.get("twin_of", b["id"])):
				hint = "%s sits %.1f m from its own symmetry image: move it off the mirror axis (or exactly onto it, where it is placed once)" % [
					a.get("twin_of", a["id"]), d]
			elif a["kind"] == b["kind"] and d < MIN_SPOT:
				hint = "two %s spots stacked: a template already brings one (check the `use` lines: %s / %s); remove the duplicate statement" % [
					a["kind"], _origin(a), _origin(b)]
			else:
				hint = "move %s or %s apart (>= %.0f m; %s)" % [_origin(a), _origin(b), need,
					"footprints / capture rings overlap" if both else "spots stacked"]
			out.append({"a": String(a["id"]), "b": String(b["id"]), "d": d, "need": need, "rule": "gap", "hint": hint})
	# one den and one lodge per image
	var seen := {}
	for s: Dictionary in spots:
		if String(s["kind"]) != "guild":
			continue
		var key := "%s/%s" % [s.get("image", "identity"), guild_kind(s)]
		if seen.has(key):
			var o: Dictionary = seen[key]
			out.append({"a": String(o["id"]), "b": String(s["id"]), "d": (o["pos"] as Vector3).distance_to(s["pos"]), "need": 0.0, "rule": "duplicate",
				"hint": "two %s guild houses in one image (%s / %s): rich_pocket already brings a den and a lodge, so drop `use guild_pair` (or use rich_node)" % [
					guild_kind(s), _origin(o), _origin(s)]})
		else:
			seen[key] = s
	return out


static func _origin(s: Dictionary) -> String:
	var id := String(s.get("twin_of", s["id"]))
	return "%s (.map line %s)" % [id, str(s["line"])] if s.has("line") else id


## One line per finding (reports).
static func lines(found: Array) -> Array[String]:
	var out: Array[String] = []
	for f: Dictionary in found:
		if f["rule"] == "duplicate":
			out.append("%s-%s duplicate guild kind" % [f["a"], f["b"]])
		else:
			out.append("%s-%s %.1f m (< %.0f)" % [f["a"], f["b"], float(f["d"]), float(f["need"])])
	return out

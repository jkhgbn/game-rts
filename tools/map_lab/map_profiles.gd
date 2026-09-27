extends RefCounted
## Map Lab (docs/plan/map-lab.md): one profile per map. A profile says which scene to load, how big the map is, which
## transforms map the map onto itself (its symmetries) and which seats (team ids) play it. Everything else (the spots)
## is read from the live scene, so a new map only needs a profile here.
## No class_name on purpose (preloaded tool script).

## Half turn around the centre: (x, z) -> (-x, -z) (the 1v1 point mirror).
const HALF_TURN := Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3.ZERO)
## Mirror in x: (x, z) -> (-x, z).
const MIRROR_X := Transform3D(Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)), Vector3.ZERO)
## Mirror in z: (x, z) -> (x, -z).
const MIRROR_Z := Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)), Vector3.ZERO)


## The profile for a map name ("1v1" = Crown Hollow, "2v2" = Fourfold Hollow). {} when unknown.
## Keys: name, title, scene, half_size, symmetries [{name, xf}], seats [{team, name, side}], spec, settings (set on the
## level root before it enters the tree).
static func get_profile(map_name: String) -> Dictionary:
	match map_name:
		"1v1", "crown_hollow", "skirmish":
			return {
				"name": "1v1", "title": "Crown Hollow (1v1)", "scene": "res://scenes/skirmish.tscn", "half_size": 60.0,
				"symmetries": [{"name": "half turn (x, z) -> (-x, -z)", "xf": HALF_TURN}],
				"seats": [{"team": 0, "name": "player (south-west)", "side": 0},
					{"team": 1, "name": "enemy (north-east)", "side": 1}],
				"spec": "docs/design/skirmish-1v1.md, docs/design/map-fill.md",
				"settings": {"river_enabled": true, "points_enabled": true, "camps_enabled": true, "beasts_enabled": true,
					"trade_enabled": true, "tavern_enabled": true},
			}
		"2v2", "fourfold_hollow":
			# docs/design/map-2v2.md 2.1: 168 x 168 m, 4-way mirrored; seats PLAYER 0 (A1 south-west), ALLY 3 (A2
			# north-west), ENEMY 1 (B1 north-east), ENEMY_2 4 (B2 south-east). The scene is not built yet (step 20):
			# pass scene=<path> when it exists under another name.
			return {
				"name": "2v2", "title": "Fourfold Hollow (2v2)", "scene": "res://scenes/skirmish_2v2.tscn", "half_size": 84.0,
				"symmetries": [{"name": "mirror x (x, z) -> (-x, z)", "xf": MIRROR_X},
					{"name": "mirror z (x, z) -> (x, -z)", "xf": MIRROR_Z},
					{"name": "half turn (x, z) -> (-x, -z)", "xf": HALF_TURN}],
				"seats": [{"team": 0, "name": "player (A1 south-west)", "side": 0},
					{"team": 3, "name": "ally (A2 north-west)", "side": 0},
					{"team": 1, "name": "enemy (B1 north-east)", "side": 1},
					{"team": 4, "name": "enemy 2 (B2 south-east)", "side": 1}],
				"spec": "docs/design/map-2v2.md",
				"settings": {},
			}
	return {}


## World Forge: a profile from JSON (docs/tools/world_forge/out/<map>/map_profile.json); symmetries by name. {} if bad.
static func from_json(path: String) -> Dictionary:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not d is Dictionary:
		return {}
	var xfs := {"mirror_x": MIRROR_X, "mirror_z": MIRROR_Z, "half_turn": HALF_TURN}
	var syms: Array = []
	for n: Variant in d.get("symmetries", []):
		if xfs.has(String(n)):
			syms.append({"name": String(n), "xf": xfs[String(n)]})
	d["symmetries"] = syms
	for s: Dictionary in d.get("seats", []):
		s["team"] = int(s["team"])
		s["side"] = int(s["side"])
	d["half_size"] = float(d.get("half_size", 60.0))
	d["settings"] = d.get("settings", {})
	return d


static func names() -> Array[String]:
	return ["1v1", "2v2"]

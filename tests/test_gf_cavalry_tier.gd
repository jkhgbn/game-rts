extends SceneTree
## G-F cavalry tier (docs/art/gf_cavalry_tier.md): Art Lab's guess_tier gives a scene holding a mount AND its rider the
## summed `unit/cavalry_mounted` budget (cavalry 12 + mount 8 draws), and leaves every other scene on its old tier.
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_gf_cavalry_tier.gd --quit-after 600
## No level is loaded: guess_tier only reads the saved scenes.

const TASK_ID := "gf_cavalry_tier"

const MOUNTED: Array[String] = [
	"res://art/units/fire/blaze_rider.tscn",
	"res://art/units/fire/emberdart_harrier/emberdart_harrier.tscn",
	"res://art/units/fire/pyrehoof_lancer/pyrehoof_lancer.tscn",
	"res://art/units/fire/sunforge_cataphract/sunforge_cataphract.tscn",
	"res://art/units/ice/frostcrown_juggernaut/frostcrown_juggernaut.tscn",
	"res://art/units/ice/rimehorn_rider/rimehorn_rider.tscn",
	"res://art/units/ice/rime_harrier/rime_harrier.tscn",
	"res://art/units/ice/snowdrift_rider/snowdrift_rider.tscn",
	"res://art/units/nature/bramble_harrier/bramble_harrier.tscn",
	"res://art/units/nature/glade_outrider/glade_outrider.tscn",
	"res://art/units/nature/stagrunner/stagrunner.tscn",
	"res://art/units/nature/thornback_charger/thornback_charger.tscn",
	"res://art/units/shadow/barrow_knight/barrow_knight.tscn",
	"res://art/units/shadow/duskbolt_harrier/duskbolt_harrier.tscn",
	"res://art/units/shadow/gloam_rider/gloam_rider.tscn",
	"res://art/units/shadow/veilborn_dreadrider/veilborn_dreadrider.tscn",
]

## Not mounted: [scene, kind, unit data hint, expected tier] (the old tiers, unchanged by G-F).
const OTHERS: Array = [
	["res://art/units/fire/blaze_rider/blaze_rider_rider.tscn", &"unit", {}, &"cavalry"],   # rider alone
	["res://art/units/shadow/shade.tscn", &"unit", {}, &"soldier"],
	["res://art/units/shadow/shadow_knight.tscn", &"unit", {"body_height": 2.4}, &"heavy"],
	["res://art/units/mounts/dusk_steed/dusk_steed.tscn", &"mount", {}, &"mount"],
	["res://art/units/wizards/vessa.tscn", &"unit", {}, &"wizard"],
	["res://art/units/neutral/mirefang/mirefang.tscn", &"unit", {}, &"creature"],
]

var _fails: Array[String] = []


func _initialize() -> void:
	var row := ArtLabBudgets.row(&"unit", &"cavalry_mounted")
	_check(not row.is_empty(), "unit/cavalry_mounted row exists")
	var cav := ArtLabBudgets.row(&"unit", &"cavalry")
	var mnt := ArtLabBudgets.row(&"mount", &"mount")
	_check(int(row.get("draw", 0)) == int(cav["draw"]) + int(mnt["draw"]), "mounted draws = cavalry + mount (got %s)" % str(row.get("draw")))
	_check(int(row.get("meshes", 0)) == int(cav["meshes"]) + int(mnt["meshes"]), "mounted meshes = cavalry + mount")
	_check(int(row.get("systems", -1)) == int(cav["systems"]), "mounted particle systems = cavalry's")
	for p: String in MOUNTED:
		_check(ResourceLoader.exists(p), "scene exists: " + p)
		_check(ArtLabBudgets.is_mounted_scene(p), "is_mounted_scene " + p)
		var t := ArtLabBudgets.guess_tier(&"unit", p, {})
		_check(t == &"cavalry_mounted", "%s -> cavalry_mounted (got %s)" % [p.get_file(), t])
	for o: Array in OTHERS:
		var p: String = o[0]
		_check(ResourceLoader.exists(p), "scene exists: " + p)
		_check(not ArtLabBudgets.is_mounted_scene(p), "not mounted: " + p)
		var t := ArtLabBudgets.guess_tier(o[1], p, o[2])
		_check(t == o[3], "%s -> %s (got %s)" % [p.get_file(), o[3], t])
	# an explicit hint wins over the scene read (the runner's tier= / mounted= stay in control)
	_check(ArtLabBudgets.guess_tier(&"unit", MOUNTED[0], {"mounted": false}) == &"cavalry", "mounted=false hint -> old cavalry tier")
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  fail: " + what)

extends "res://tools/unit_lab/unit_lab_run.gd"
## Faster-games experiment B (docs/balance/faster_games_2026-10-06.md): the Unit Lab headless runner, unchanged, with
## the lab siege units of tools/balance_lab/faster_games/units/ known to UnitType.find (its static cache, lab only), so
## a matrix spec can list them by id (`ids` + `focus`). Same flags as tools/unit_lab/unit_lab_run.gd.

const FG_UNITS := ["res://tools/balance_lab/faster_games/units/grave_mangonel.tres",
		"res://tools/balance_lab/faster_games/units/stoneroot_hurler.tres"]


func _initialize() -> void:
	for p: String in FG_UNITS:
		var t := load(p) as UnitType
		if t != null:
			UnitType._cache[String(t.id)] = t
	super._initialize()

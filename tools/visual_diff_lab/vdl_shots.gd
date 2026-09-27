extends RefCounted
## Visual Diff Lab shot list (docs/plan/visual-diff-lab.md). Fixed: changing a shot means re-recording its golden
## (run_visual_diff_lab.ps1 -Golden -Shots <id>).
## kind:  menu     = scenes/ui/main_menu.tscn, MENU_SETTLE_FRAMES frames at time_scale 0 + MENU_RUN_FRAMES of game time
##        map      = the 1v1 skirmish (fire vs shadow), paused at match start, camera at `focus` / `zoom`
##        lineup   = every unit type of `kingdom` (sorted by id, workers included, summons / caravans not), standing
##                   in a row near the player start, other units hidden, HUD hidden
## focus: a Vector3, or "keep:0" / "keep:1" (that team's keep position)     fog: false = FogOfWar off for the shot
## pass_pct: PASS limit in % changed for this shot (default vdl_diff.gd PASS_PCT)
## ignore: Rect2i list in 1600x900 pixels, never compared (animated HUD numbers, tickers...). Pixels that change
##         between two captures of the same frozen frame are ignored automatically too (the "unstable" mask).

const WIDTH := 1600
const HEIGHT := 900
const MENU_SETTLE_FRAMES := 150     ## frames at time_scale 0 (loading)
const MENU_RUN_FRAMES := 0          ## then frames of game time before the freeze (0: the diorama at t = 0)
## Map shots: neutral creatures / tavern props keep a per-run idle phase (not frozen by the lab yet), ~0.05-0.3 %
## of the frame: PASS up to this % on map shots (a real lighting / shader / HUD regression is well above 1 %).
const MAP_PASS_PCT := 0.35
const LINEUP_CENTER := Vector3(-30.0, 0.0, 30.0)
const LINEUP_SPACING := 2.6
## The minimap (bottom-left): its camera frame is redrawn on a real-time throttle, so where it sits at the freeze
## differs run to run. The start-of-match Vessa (map_player_base, right of the keep) also turns a little run to run.
const MINIMAP := Rect2i(16, 646, 242, 234)

const SHOTS: Array[Dictionary] = [
	{"id": "menu_main", "kind": "menu", "what": "main menu with the 3D diorama", "ignore": []},
	{"id": "map_player_base", "kind": "map", "focus": "keep:0", "zoom": 30.0, "what": "player keep, workers, start units, HUD",
		"pass_pct": MAP_PASS_PCT, "ignore": [MINIMAP, Rect2i(960, 200, 100, 110)]},
	{"id": "map_centre", "kind": "map", "focus": Vector3(0.0, 0.0, 0.0), "zoom": 45.0, "fog": false, "what": "Crown isle, river, crossings, fog off",
		"pass_pct": MAP_PASS_PCT, "ignore": [MINIMAP]},
	{"id": "map_west_meadow", "kind": "map", "focus": Vector3(-24.0, 0.0, 18.0), "zoom": 40.0, "what": "west meadow toward the river, fog edge",
		"pass_pct": MAP_PASS_PCT, "ignore": [MINIMAP]},
	{"id": "map_overview", "kind": "map", "focus": Vector3(-6.0, 0.0, 6.0), "zoom": 55.0, "fog": false, "what": "max zoom over the whole west half, fog off",
		"pass_pct": MAP_PASS_PCT, "ignore": [MINIMAP]},
	{"id": "lineup_fire", "kind": "lineup", "kingdom": "fire", "what": "every Fire unit type", "ignore": []},
	{"id": "lineup_ice", "kind": "lineup", "kingdom": "ice", "what": "every Ice unit type", "ignore": []},
	{"id": "lineup_nature", "kind": "lineup", "kingdom": "nature", "what": "every Nature unit type", "ignore": []},
	{"id": "lineup_shadow", "kind": "lineup", "kingdom": "shadow", "what": "every Shadow unit type", "ignore": []},
]


static func ids() -> Array[String]:
	var out: Array[String] = []
	for s: Dictionary in SHOTS:
		out.append(String(s["id"]))
	return out


static func find(id: String) -> Dictionary:
	for s: Dictionary in SHOTS:
		if String(s["id"]) == id:
			return s
	return {}

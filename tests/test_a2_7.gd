extends SceneTree
## Task A2.7 (neutrals polish: Ruin Warden, Ruin Peddler, Lost Cache). Headless:
##   $GODOT --headless --path . -s tests/test_a2_7.gd --fixed-fps 60 --quit-after 900
## - the warden instantiates, drives every kit hook (walk, attack with its slam, hit, level-up, statuses, death,
##   revive) without errors, emits death_finished once at ~1 s, fades its body and restores it on revive,
##   stays inside the kit budgets (draw instances, no light);
## - the peddler art instantiates under a RuinPeddler with no real light and animates;
## - the Lost Cache art answers set_open / is_open / set_opened, and LostCache opens / hides / reappears with it.

const TASK_ID := "a2_7"
const WARDEN := "res://art/units/neutral/ruin_warden.tscn"
const PEDDLER := "res://art/environment/ruin_peddler.tscn"
const CACHE := "res://art/environment/lost_cache.tscn"

var fails: Array[String] = []
var frame := 0
var warden
var warden2
var deaths := 0
var peddler: Node3D
var cache_art
var cache: Node3D


func _initialize() -> void:
	for p: String in [WARDEN, PEDDLER, CACHE]:
		if not ResourceLoader.exists(p):
			fails.append("missing " + p)
	var holder := Node3D.new()
	root.add_child(holder)
	warden = (load(WARDEN) as PackedScene).instantiate()
	warden.set_team_color(Color(0.85, 0.30, 0.12))   # before _ready: must be a no-op
	holder.add_child(warden)
	warden.death_finished.connect(func() -> void: deaths += 1)
	warden2 = (load(WARDEN) as PackedScene).instantiate()   # second instance: merged-mesh cache path
	var h2 := Node3D.new()
	h2.position = Vector3(4, 0, 0)
	root.add_child(h2)
	h2.add_child(warden2)
	# Peddler: the real RuinPeddler body (it adds the art as "Art").
	var ped_script: Script = load("res://scripts/world/ruin_peddler.gd")
	peddler = ped_script.new()
	peddler.position = Vector3(0, 0, 12)
	root.add_child(peddler)
	# Cache art alone + a real LostCache.
	cache_art = (load(CACHE) as PackedScene).instantiate()
	cache_art.position = Vector3(-6, 0, 0)
	root.add_child(cache_art)
	var cache_script: Script = load("res://scripts/world/lost_cache.gd")
	cache = cache_script.new()
	cache.set(&"first_delay", 0.5)
	cache.set(&"reopen_delay", 1.0)
	cache.position = Vector3(-10, 0, 0)
	root.add_child(cache)


func _count_draws(n: Node) -> int:
	var c := 0
	for ch: Node in n.get_children():
		if ch is GeometryInstance3D and (ch as GeometryInstance3D).visible and not ch is GPUParticles3D:
			c += 1
		c += _count_draws(ch)
	return c


func _has_light(n: Node) -> bool:
	for ch: Node in n.find_children("*", "Light3D", true, false):
		return true
	return false


func _body_alpha(m) -> float:
	var n := m.get_node_or_null(^"Root/Chest/Merged") as GeometryInstance3D
	return n.transparency if n else -1.0


func _process(_delta: float) -> bool:
	frame += 1
	match frame:
		2:
			if warden.get(&"unit_kind") == &"" or not warden.has_method(&"glow_level"):
				fails.append("warden: unit_kind / glow_level missing")
			var draws := _count_draws(warden)
			if draws > 16:
				fails.append("warden: %d draw instances (> 16)" % draws)
			if _count_draws(warden2) != draws:
				fails.append("warden: second instance has %d draws, first %d" % [_count_draws(warden2), draws])
			if _has_light(warden) or _has_light(peddler) or _has_light(cache_art):
				fails.append("a real light in a neutral scene")
			if peddler.get_node_or_null(^"Art") == null:
				fails.append("peddler: no Art child")
			for m in [warden, warden2]:
				m.set_moving(float(m.stride_speed))
			print("warden draw instances: %d" % draws)
		60:
			warden.set_moving(float(warden.stride_speed) * 1.4)
		90:
			warden.set_moving(0.0)
			warden.play_attack()
			warden2.play_attack()
		120:
			warden.play_hit()
			warden.play_level_up()
			if not warden.set_status(&"haste", true):
				fails.append("warden: haste not handled")
			warden.set_status(&"shroud", true)
			cache_art.call(&"set_open", true)
			if not bool(cache_art.call(&"is_open")):
				fails.append("cache art: is_open false after set_open(true)")
		150:
			warden.set_status(&"haste", false)
			warden.play_death()
			cache_art.call(&"set_opened", false)
			if bool(cache_art.call(&"is_open")):
				fails.append("cache art: still open after set_opened(false)")
			cache_art.call(&"set_opened", true)
		200:
			if _body_alpha(warden) < 0.2:
				fails.append("warden: body not fading mid-death (%s)" % _body_alpha(warden))
		260:
			if deaths != 1:
				fails.append("warden: death_finished emitted %d times" % deaths)
			if _body_alpha(warden) < 0.95:
				fails.append("warden: body still visible after death (%s)" % _body_alpha(warden))
			warden.revive()
			cache_art.call(&"set_open", false)
		280:
			if absf(_body_alpha(warden)) > 0.001:
				fails.append("warden: revive did not restore the body (%s)" % _body_alpha(warden))
			if warden.glow_level() <= 0.0:
				fails.append("warden: glows off after revive")
			if not bool(cache.call(&"is_available")):
				fails.append("LostCache never appeared")
			# The opening look (no hero in this test, so no loot roll): the art must open.
			cache.call(&"_play_open")
			if not bool(cache.call(&"is_look_open")):
				fails.append("LostCache: art not open after _play_open")
		400:
			if fails.is_empty():
				print("PASS %s" % TASK_ID)
			else:
				print("FAIL %s: %s" % [TASK_ID, "; ".join(fails)])
			return true
	return false

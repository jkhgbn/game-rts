extends SceneTree
## Root-cause pass "graphics leak information through the fog of war" (2026-10-15; cases: grass cleared under unseen
## enemy buildings, building dressing copied into fog ghosts, spell VFX extras lit in unseen fog).
## A skirmish (scenes/skirmish.tscn, bot off) with the High / Ultra art forced on where a test hook exists:
##   SpellFxG.test_tier, GroundDetail.quality_override, WizardModel.aura_quality_override, and the global
##   GameSettings `gfx_test_override` static when it exists (handoff docs/handoff/for-ui-coder.md), else the
##   command line `-- --gfx=ultra` (without either, art that reads GameSettings itself, e.g. ShadowDress / Fire paint,
##   stays Low headless: the test prints which).
## In a spot the player has never explored it spawns enemy buildings of the four kingdoms (+ a construction site), enemy
## soldiers, the four casters and the four wizards, and neutral targets; every wizard casts each of its spells there,
## every caster both of its spells, the units fight, some units and a building die. Every VisualInstance3D
## (meshes, particles, decals, lights, labels, sprites) added under the level since the setup, plus every one that
## was hidden at setup (pools), is sampled every other frame: visible_in_tree at a point whose fog state for the
## player is UNEXPLORED = a leak. A node inside a Unit / Building the FogOfWar manages gets one fog cycle of grace
## (the fog hides new enemy units / buildings at its next 5 Hz pass; that flicker is reported as a NOTE); any other
## node (VFX, projectiles, decals, lights) fails at once. FAIL lines give the node path, class, script.
## Also: GroundDetail.clear_list() has no circle in unexplored fog (and does have one round a building the player saw),
## and fog ghosts (group "fog_ghosts") hold no mesh that sits under a `no_ghost` node of a building.
## Headless limits: GroundDetail builds no grass rings headless (only the clear list is checked); MultiMesh / shader
## output is not rendered; FogOfWar is fully simulated.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_fog_leak.gd --fixed-fps 60 --quit-after 9000 ++ --gfx=ultra
## (`++` = Godot's other user-args separator: PowerShell eats `--` on the way to the gate. The CI form without it
## still runs everything with the per-system hooks above.) ~25 s of script time, ~30-40 s per run.
# error_lab: quit-after=9000

const TASK_ID := "fog_leak"
const LOAD_TIMEOUT_FRAMES := 6000
const GRACE_FRAMES := 20            ## fog-managed unit / building parts: one 5 Hz fog cycle (12 frames) + margin
const SAMPLE_EVERY := 2
const GFX_HOOK := &"gfx_test_override"
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
const WIZARDS := {
	&"fire": "res://scripts/units/wizard.gd",
	&"shadow": "res://scripts/units/shadow_wizard.gd",
	&"ice": "res://scripts/units/ice_wizard.gd",
	&"nature": "res://scripts/units/nature_wizard.gd",
}
const ENEMY_SOLDIERS: Array[String] = ["flame_guard", "ember_archer", "shade", "nightbolt", "shardcaster",
		"wildwood_archer", "gloom_thrall"]
const ENEMY_CASTERS: Array[String] = ["kilnwarden", "rimecarver", "bramblesage", "gloom_deacon"]
const NEUTRAL_TARGETS: Array[String] = ["flame_guard", "shade", "shardguard", "flame_guard", "gloom_deacon",
		"kilnwarden"]
const ENEMY_BUILDINGS: Array[StringName] = [&"shadow_tower", &"shadow_hovel", &"shadow_barracks", &"fire_tower",
		&"ice_tower", &"nature_tower", &"fire_hearth"]

var main: Node
var fog: FogOfWar
var _fails: Array[String] = []
var _notes: Array[String] = []
var _frame := 0
var _done := false
var _started := false
var _sampling := false
var _baseline := {}                  # instance id -> true (every node under the level at setup)
var _watch: Array[VisualInstance3D] = []
var _leak_since := {}                # instance id -> first frame seen visible in unexplored fog
var _leaks := {}                     # key -> description (reported once)
var _g_live_max := 0                 # most SpellFxG pieces live at once (anywhere): the G layer did play
var _emit_frame := {}              # GPUParticles3D instance id -> last frame seen emitting
var _flicker := {}                 # node path -> frames (graced parts of fog-managed units / buildings)
var _spot := Vector3.INF             # the never-explored spot
var _ghost_spot := Vector3.INF       # a second unexplored spot, revealed once for the ghost check
var _gd: Node = null
var _casts: Array[String] = []
var _refused: Array[String] = []
var _t0 := 0
var _tier_note := ""


func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
	seed(4242)
	_force_tiers()
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	_frame += 1
	if not _started:
		if main.get(&"hero") != null and main.get(&"fog") != null and bool(main.get(&"match_started")):
			_started = true
			_run.call_deferred()
		elif _frame > LOAD_TIMEOUT_FRAMES:
			_fails.append("the skirmish never finished loading")
			_finish()
	if _sampling and _frame % SAMPLE_EVERY == 0:
		_sample()
	return _done


# ---------------------------------------------------------------- tiers

func _force_tiers() -> void:
	SpellFxG.test_tier = SpellFxG.TIER_ULTRA
	GroundDetail.quality_override = 3
	WizardModel.aura_quality_override = 3
	var gs := load(GAME_SETTINGS_PATH) as GDScript
	var hook := false
	if gs and gs.get(GFX_HOOK) != null:
		gs.set(GFX_HOOK, 3)
		hook = int(gs.get(GFX_HOOK)) == 3
	var q := GameSettings.effective_graphics_quality()
	if hook:
		_tier_note = "GameSettings.%s = Ultra (effective tier %d)" % [GFX_HOOK, q]
	elif GameSettings.gfx_override() >= 0:
		_tier_note = "-- --gfx (effective tier %d)" % q
	else:
		_tier_note = ("effective tier %d (Low): no GameSettings.%s hook and no -- --gfx=ultra, so art that reads " +
				"GameSettings itself (ShadowDress, Fire / Ice / Nature / neutral paint, wizard model) is built at Low; " +
				"SpellFxG / GroundDetail / wizard aura forced Ultra by their own hooks") % [q, GFX_HOOK]


func _reset_tiers() -> void:
	SpellFxG.test_tier = -1
	GroundDetail.quality_override = -1
	WizardModel.aura_quality_override = -1
	var gs := load(GAME_SETTINGS_PATH) as GDScript
	if gs and gs.get(GFX_HOOK) != null:
		gs.set(GFX_HOOK, -1)


# ---------------------------------------------------------------- scenario

func _run() -> void:
	fog = main.get(&"fog") as FogOfWar
	if fog == null or not fog.enabled:
		_fails.append("no FogOfWar active for the player")
		_finish()
		return
	await _secs(0.5)   # a few fog passes
	_spot = _pick_unexplored(8.0, Vector3.INF)
	_ghost_spot = _pick_unexplored(6.0, _spot)
	if _spot == Vector3.INF:
		var rows: Array[String] = []
		for z in range(-56, 57, 8):
			var row := ""
			for x in range(-56, 57, 8):
				row += str(fog.state_at(Unit.Team.PLAYER, Vector3(x, 0, z)))
			rows.append(row)
		_fails.append("no unexplored spot found for the player (fog rows z -56..56: %s)" % " ".join(rows))
		_finish()
		return
	# GroundDetail: the level's own (windowed) or one made here (headless: ensure() returns null there).
	_gd = root.get_tree().get_first_node_in_group(GroundDetail.GROUP)
	if _gd == null:
		_gd = GroundDetail.new()
		_gd.name = "GroundDetailTest"
		main.add_child(_gd)
	await _frames(2)
	# Baseline: every node under the level now; hidden visuals are watched too (pools that get shown later).
	_collect_baseline(main)
	node_added.connect(_on_node_added)
	_sampling = true
	var cam: Node = main.get(&"camera_rig")
	if cam and cam.has_method(&"focus_on"):
		cam.call(&"focus_on", _spot)   # the player pans over the black fog (VFX skip far-from-camera effects)

	# --- spawn
	var bg: BuildGrid = main.get(&"build_grid") as BuildGrid
	var buildings: Array[Building] = []
	var bi := 0
	for id: StringName in ENEMY_BUILDINGS:
		var t := BuildingType.find(id)
		if t == null:
			_notes.append("building type %s missing" % id)
			continue
		var ang := TAU * float(bi) / float(ENEMY_BUILDINGS.size())
		var near := _spot + Vector3(cos(ang), 0, sin(ang)) * 7.5
		var p := bg.find_spot(t, near, Unit.Team.ENEMY) if bg else Vector3.INF
		if p == Vector3.INF or fog.is_explored(Unit.Team.PLAYER, p):
			p = near
		buildings.append(bg.spawn_complete(t, p, Unit.Team.ENEMY))
		bi += 1
	var site_t := BuildingType.find(&"shadow_hovel")
	var site: Building = null
	if site_t and bg:
		var sp := bg.find_spot(site_t, _spot + Vector3(0, 0, 6), Unit.Team.ENEMY)
		if sp != Vector3.INF and not fog.is_explored(Unit.Team.PLAYER, sp):
			site = bg.spawn_site(site_t, sp, Unit.Team.ENEMY)
	var enemies: Array[Unit] = []
	var i := 0
	for id: String in ENEMY_SOLDIERS:
		enemies.append(_spawn_unit(id, Unit.Team.ENEMY, _ring(i, ENEMY_SOLDIERS.size(), 3.0, -2.5)))
		i += 1
	var casters: Array[Unit] = []
	i = 0
	for id: String in ENEMY_CASTERS:
		var c := _spawn_unit(id, Unit.Team.ENEMY, _ring(i, ENEMY_CASTERS.size(), 2.0, -4.5))
		casters.append(c)
		enemies.append(c)
		i += 1
	var neutrals: Array[Unit] = []
	i = 0
	for id: String in NEUTRAL_TARGETS:
		neutrals.append(_spawn_unit(id, Unit.Team.NEUTRAL, _ring(i, NEUTRAL_TARGETS.size(), 3.0, 3.0)))
		i += 1
	var wizards: Array[Wizard] = []
	i = 0
	for k: StringName in WIZARDS:
		var w := _spawn_wizard(String(WIZARDS[k]), _ring(i, WIZARDS.size(), 2.5, 0.0))
		if w:
			wizards.append(w)
		else:
			_notes.append("wizard %s could not be made" % k)
		i += 1
	enemies = enemies.filter(func(u: Unit) -> bool: return u != null)
	neutrals = neutrals.filter(func(u: Unit) -> bool: return u != null)
	await _secs(1.0)

	# --- positive control: the player's own wizard casts at home (seen: the G layer must play there)
	var hero := main.get(&"hero") as Wizard
	if hero and hero.spell_caster:
		hero.spell_caster.call(&"set_rank", &"fireball", 1)
		hero.mana = 9999.0
		var r := str(hero.spell_caster.call(&"cast", &"fireball", hero.global_position + Vector3(5, 0, 0)))
		if r != "":
			_notes.append("player control cast refused: %s" % r)
	# --- every wizard casts each of its spells, every caster both of its spells
	for round_i in 2:
		for w in wizards:
			_cast_all(w, neutrals, enemies)
		for c in casters:
			_caster_cast_all(c, neutrals, enemies)
		await _secs(1.4)
	for w in wizards:
		_cast_all(w, neutrals, enemies)
	# --- fights
	for u in enemies:
		var tgt := _nearest_alive(neutrals, u.global_position)
		if tgt and is_instance_valid(u) and u.is_alive():
			u.command_attack(tgt)
	await _secs(5.0)
	# --- deaths in the fog (units of both sides, a building, the site)
	var killed := 0
	for u in enemies.slice(0, 3) + neutrals.slice(0, 2):
		if is_instance_valid(u) and u.is_alive():
			u.take_damage(999999.0, null)
			killed += 1
	for b: Building in [buildings[3] if buildings.size() > 3 else null, site]:
		if b and is_instance_valid(b) and b.is_alive():
			b.take_damage(999999.0, null)
			killed += 1
	for w in wizards:
		_cast_all(w, neutrals, enemies)
	await _secs(5.0)
	_check_spot_still_unexplored()
	# --- grass clears: none round the never-seen buildings
	_check_clears(_spot, "the unseen buildings")

	# --- fog ghosts: enemy buildings at a second spot, seen once through a sight marker, then fogged again
	if _ghost_spot == Vector3.INF:
		_notes.append("no second unexplored spot: ghost / seen-clear checks skipped")
	else:
		var ghost_b: Array[Building] = []
		for id: StringName in [&"shadow_hovel", &"shadow_tower", &"fire_hearth", &"ice_tower", &"nature_tower"]:
			var t := BuildingType.find(id)
			if t == null or bg == null:
				continue
			var gp := bg.find_spot(t, _ghost_spot + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)), Unit.Team.ENEMY)
			if gp != Vector3.INF and gp.distance_to(_ghost_spot) < 9.0:
				ghost_b.append(bg.spawn_complete(t, gp, Unit.Team.ENEMY))
		await _secs(0.6)
		var marker := SightMarker.spawn(Unit.Team.PLAYER, _ghost_spot, 20.0, 1.2, main)
		await _secs(0.6)
		if _gd and _gd.has_method(&"refresh_clears"):
			_gd.call(&"refresh_clears", _ghost_spot, 40.0)   # seen now: GroundDetail may clear round them
		await _secs(2.0)
		if is_instance_valid(marker):
			_notes.append("sight marker still alive after its lifetime")
		_check_ghosts(ghost_b)
		_check_clears(_spot, "the unseen buildings (after the reveal)")
		_check_seen_clear(ghost_b)
	_sampling = false
	for u in root.get_tree().get_nodes_in_group(&"units"):
		var un := u as Unit
		if un and un.is_visible_in_tree() and un.team != Unit.Team.PLAYER \
				and fog.state_at(Unit.Team.PLAYER, un.global_position) == FogOfWar.UNEXPLORED:
			_fails.append("unit visible in unexplored fog at the end: %s team %d alive %s at %s" % [_short_path(un),
					un.team, un.is_alive(), un.global_position])
	_notes.append("spawned: %d buildings + site, %d enemy units, %d neutrals, %d wizards; %d killed" % [buildings.size(),
			enemies.size(), neutrals.size(), wizards.size(), killed])
	_notes.append("casts: %s" % ", ".join(_casts))
	if not _refused.is_empty():
		_notes.append("refused casts: %s" % ", ".join(_refused))
	_finish()


## The point (4 m grid, 10 m inside the map) with the widest never-explored disc round it (at least `min_r` m),
## preferring the far half of the map from the player's start; >= 35 m from `away_from`. INF when none.
func _pick_unexplored(min_r: float, away_from: Vector3) -> Vector3:
	var start: Vector3 = main.call(&"start_position", Unit.Team.PLAYER)
	var best := Vector3.INF
	var best_score := -INF
	var hx := int(MapInfo.half_x()) - 10
	var hz := int(MapInfo.half_z()) - 10
	for x in range(-hx, hx + 1, 4):
		for z in range(-hz, hz + 1, 4):
			var c := Vector3(x, 0, z)
			if away_from != Vector3.INF and c.distance_to(away_from) < 35.0:
				continue
			var r := _clear_radius(c, 20.0)
			if r < min_r:
				continue
			var score := minf(r, 14.0) * 4.0 + c.distance_to(start) * 0.1
			if score > best_score:
				best_score = score
				best = c
	if best != Vector3.INF:
		_notes.append("unexplored spot (%.0f, %.0f) clear radius %.0f m" % [best.x, best.z, _clear_radius(best, 20.0)])
	return best


## Distance from `c` to the nearest explored sample (rings every 1 m, 24 directions), capped at `cap`.
func _clear_radius(c: Vector3, cap: float) -> float:
	var r := 0.0
	while r <= cap:
		for a in 24:
			var p := c + Vector3(cos(TAU * a / 24.0), 0, sin(TAU * a / 24.0)) * r
			if fog.is_explored(Unit.Team.PLAYER, p):
				return r
		r += 1.0
	return cap


func _ring(i: int, n: int, r: float, dz: float) -> Vector3:
	var a := TAU * float(i) / float(maxi(n, 1))
	return _spot + Vector3(cos(a) * r, 0, sin(a) * r + dz)


func _spawn_unit(type_id: String, team: int, pos: Vector3) -> Unit:
	var u: Unit = main.call(&"make_unit", type_id)
	if u == null:
		_notes.append("unit type %s missing" % type_id)
		return null
	u.team = team as Unit.Team
	main.add_child(u)
	u.set_down(pos)
	u.command_stop()
	return u


func _spawn_wizard(path: String, pos: Vector3) -> Wizard:
	if not ResourceLoader.exists(path):
		return null
	var w := (load(path) as GDScript).new() as Wizard
	if w == null:
		return null
	w.team = Unit.Team.ENEMY
	main.add_child(w)
	w.remove_from_group(&"heroes")
	w.add_to_group(&"enemy_heroes")
	if &"ai_auto_cast" in w:
		w.set(&"ai_auto_cast", false)
	w.add_modifier(&"test:fog_leak", {"max_hp": 6000.0})
	w.set_down(pos)
	w.command_stop()
	return w


func _nearest_alive(list: Array[Unit], from: Vector3) -> Unit:
	var best: Unit = null
	var bd := INF
	for u in list:
		if u and is_instance_valid(u) and u.is_alive():
			var d := u.global_position.distance_to(from)
			if d < bd:
				bd = d
				best = u
	return best


func _cast_all(w: Wizard, neutrals: Array[Unit], allies: Array[Unit]) -> void:
	if not is_instance_valid(w) or not w.is_alive() or w.spell_caster == null:
		return
	var sc: Node = w.spell_caster
	for id: StringName in w.spell_ids():
		sc.call(&"set_rank", id, 1)
		w.mana = 9999.0
		var foe := _nearest_alive(neutrals, w.global_position)
		var friend := _nearest_alive(allies, w.global_position)
		var tries: Array = []
		if foe:
			tries.append(foe)
			tries.append(foe.global_position)
		if friend:
			tries.append(friend)
		tries.append(_spot)
		tries.append(null)
		var reason := "?"
		for t: Variant in tries:
			reason = str(sc.call(&"cast", id, t))
			if reason == "":
				break
		if reason == "":
			if not _casts.has(String(id)):
				_casts.append(String(id))
		elif reason != "Cooldown" and reason != "On cooldown":
			var r := "%s (%s)" % [id, reason]
			if not _refused.has(r) and not _casts.has(String(id)):
				_refused.append(r)


func _caster_cast_all(c: Unit, neutrals: Array[Unit], allies: Array[Unit]) -> void:
	if not is_instance_valid(c) or not c.is_alive():
		return
	var ab: Node = c.get_node_or_null(^"CasterAbility")
	if ab == null:
		_notes.append("%s has no CasterAbility" % c.name)
		return
	ab.call(&"add_mana", 9999.0)
	for id: StringName in ab.call(&"spell_ids"):
		var foe := _nearest_alive(neutrals, c.global_position)
		var friend: Unit = null
		for a in allies:
			if a and is_instance_valid(a) and a.is_alive() and a != c:
				friend = a
				break
		var tries: Array = []
		if foe:
			tries.append(foe)
			tries.append(foe.global_position)
		if friend:
			tries.append(friend)
		tries.append(_spot + Vector3(1, 0, 1))
		var reason := "?"
		for t: Variant in tries:
			reason = str(ab.call(&"order_cast", id, t))
			if reason == "":
				break
		if reason == "":
			if not _casts.has(String(id)):
				_casts.append(String(id))
		else:
			var r := "%s (%s)" % [id, reason]
			if not _refused.has(r) and not _casts.has(String(id)):
				_refused.append(r)


# ---------------------------------------------------------------- the leak sampler

func _collect_baseline(n: Node) -> void:
	_baseline[n.get_instance_id()] = true
	var vi := n as VisualInstance3D
	if vi and not vi.is_visible_in_tree():
		_watch.append(vi)
	for c in n.get_children():
		_collect_baseline(c)


func _on_node_added(n: Node) -> void:
	var vi := n as VisualInstance3D
	if vi and is_instance_valid(main) and main.is_ancestor_of(vi):
		_watch.append(vi)


func _sample() -> void:
	for g in root.get_tree().get_nodes_in_group(SpellFxG.GROUP):   # coverage: did the G layer play anything?
		_g_live_max = maxi(_g_live_max, (g as SpellFxG).live_count())
	var keep: Array[VisualInstance3D] = []
	for vi in _watch:
		if not is_instance_valid(vi) or not vi.is_inside_tree():
			continue
		keep.append(vi)
		var id := vi.get_instance_id()
		var leaking := vi.is_visible_in_tree() and _draws(vi) \
				and fog.state_at(Unit.Team.PLAYER, vi.global_position) == FogOfWar.UNEXPLORED
		if not leaking:
			if _leak_since.has(id):
				var owner_path := _managed_owner(vi)
				if owner_path != "":
					var frames := _frame - int(_leak_since[id])
					_flicker[owner_path] = maxi(int(_flicker.get(owner_path, 0)), frames)
				_leak_since.erase(id)
			continue
		if not _leak_since.has(id):
			_leak_since[id] = _frame
		var managed := _managed_owner(vi)
		if managed != "" and _frame - int(_leak_since[id]) <= GRACE_FRAMES:
			continue
		var key := _leak_key(vi)
		if not _leaks.has(key):
			_leaks[key] = "%s [%s] script %s at (%.1f, %.1f, %.1f)%s" % [_short_path(vi), vi.get_class(),
					_script_of(vi), vi.global_position.x, vi.global_position.y, vi.global_position.z,
					(" (part of fog-managed %s, visible > %d frames)" % [managed, GRACE_FRAMES]) if managed != "" else ""]
	_watch = keep


## False for a node that cannot draw anything now (a particle node that is not emitting and has no particles left
## is treated like a drawing one: Godot keeps showing its last particles until their lifetime ends).
func _draws(vi: VisualInstance3D) -> bool:
	if vi.get_viewport() != root:   # a SubViewport (HUD portrait) has its own world: not the map
		return false
	var gp := vi as GPUParticles3D
	if gp:
		var id := gp.get_instance_id()
		if gp.emitting:
			_emit_frame[id] = _frame
			return true
		# Stopped: its last particles live on for `lifetime` s (+ margin); never seen emitting = nothing drawn.
		return _emit_frame.has(id) and _frame - int(_emit_frame[id]) <= int(gp.lifetime * 60.0 / maxf(gp.speed_scale, 0.01)) + 6
	var cp := vi as CPUParticles3D
	if cp and not cp.emitting:
		return false
	var mi := vi as MeshInstance3D
	if mi and mi.mesh == null:
		return false
	var mm := vi as MultiMeshInstance3D
	if mm and (mm.multimesh == null or mm.multimesh.visible_instance_count == 0 or mm.multimesh.instance_count == 0):
		return false
	var l := vi as Light3D
	if l and l.light_energy <= 0.0:
		return false
	return true


## The path of the Unit / Building (the FogOfWar hides those at its next pass) that holds `n`, else "".
func _managed_owner(n: Node) -> String:
	var p := n
	while p and p != main:
		if p is Unit or p is Building:
			return _short_path(p)
		p = p.get_parent()
	return ""


## One report per script + class + parent name pattern (pools hold many identical slots).
func _leak_key(vi: VisualInstance3D) -> String:
	var par := vi.get_parent()
	var pname := String(par.name).rstrip("0123456789@_") if par else ""
	return "%s|%s|%s|%s" % [_script_of(vi).get_slice(" ", 0), vi.get_class(), pname,
			String(vi.name).rstrip("0123456789@_")]


func _script_of(n: Node) -> String:
	var p := n
	while p:
		var s := p.get_script() as Script
		if s and s.resource_path != "":
			return s.resource_path + ("" if p == n else " (on %s)" % p.name)
		p = p.get_parent()
	return "-"


func _short_path(n: Node) -> String:
	return str(main.get_path_to(n)) if is_instance_valid(main) and main.is_ancestor_of(n) else str(n.get_path())


# ---------------------------------------------------------------- other checks

func _check_spot_still_unexplored() -> void:
	if fog.is_explored(Unit.Team.PLAYER, _spot):
		_notes.append("the test spot became explored for the player (a player unit went there?): later samples there skip")


func _check_clears(around: Vector3, what: String) -> void:
	if _gd == null or not _gd.has_method(&"refresh_clears") or not _gd.has_method(&"clear_list"):
		_notes.append("GroundDetail has no public refresh_clears / clear_list: grass clear check skipped")
		return
	_gd.call(&"refresh_clears", around, 60.0)
	var bad: Array[String] = []
	for v: Vector4 in _gd.call(&"clear_list"):
		var p := Vector3(v.x, 0, v.y)
		if fog.state_at(Unit.Team.PLAYER, p) == FogOfWar.UNEXPLORED:
			bad.append("(%.1f, %.1f) r %.1f" % [v.x, v.y, v.z])
	if not bad.is_empty():
		_fails.append("GroundDetail clears grass in unexplored fog round %s: %s" % [what, ", ".join(bad)])


func _check_seen_clear(seen: Array[Building]) -> void:
	if _gd == null or not _gd.has_method(&"clear_list") or seen.is_empty():
		return
	_gd.call(&"refresh_clears", _ghost_spot, 60.0)
	var found := false
	for v: Vector4 in _gd.call(&"clear_list"):
		for b in seen:
			if is_instance_valid(b) and Vector2(v.x - b.global_position.x, v.y - b.global_position.z).length() < 0.6:
				found = true
	if not found:
		_fails.append("GroundDetail: no grass clear round the enemy buildings the player saw (positive control)")


func _check_ghosts(seen: Array[Building]) -> void:
	var ghosts := root.get_tree().get_nodes_in_group(&"fog_ghosts")
	if seen.is_empty():
		_notes.append("no building spawned at the ghost spot: ghost check skipped")
		return
	if ghosts.is_empty():
		_fails.append("no fog ghost after the enemy buildings were seen once and fogged again")
		return
	# Every mesh under a no_ghost node of any building (the dressing) must be absent from every ghost.
	var dress := {}
	var no_ghost_nodes := 0
	for b in root.get_tree().get_nodes_in_group(&"buildings"):
		no_ghost_nodes += _collect_no_ghost(b as Node, false, dress)
	var ghost_meshes := 0
	var bad: Array[String] = []
	for g in ghosts:
		for mi in (g as Node).find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).mesh
			ghost_meshes += 1
			if m and dress.has(m.get_instance_id()):
				var s := "%s (%s)" % [(g as Node).name, dress[m.get_instance_id()]]
				if not bad.has(s):
					bad.append(s)
	if not bad.is_empty():
		_fails.append("fog ghosts copy no_ghost dressing meshes: %s" % ", ".join(bad))
	_notes.append("ghosts: %d nodes, %d meshes; %d no_ghost nodes (%d meshes) under buildings" % [ghosts.size(),
			ghost_meshes, no_ghost_nodes, dress.size()])


func _collect_no_ghost(n: Node, inside: bool, into: Dictionary) -> int:
	var count := 0
	var here: bool = inside or n.get_meta(&"no_ghost", false) == true
	if here and not inside:
		count += 1
	var mi := n as MeshInstance3D
	if here and mi and mi.mesh:
		into[mi.mesh.get_instance_id()] = _short_path(mi)
	for c in n.get_children():
		count += _collect_no_ghost(c, here, into)
	return count


# ---------------------------------------------------------------- end

func _finish() -> void:
	_sampling = false
	_reset_tiers()
	for k: String in _leaks:
		_fails.append("visible in never-explored fog: " + String(_leaks[k]))
	print("fog_leak: tier: %s" % _tier_note)
	for n in _notes:
		print("  note: ", n)
	if not _flicker.is_empty():
		var parts: Array[String] = []
		for p: String in _flicker:
			parts.append("%s %df" % [p, int(_flicker[p])])
		print("  note: fog-managed parts visible in unexplored fog until the next fog pass (graced, <= %d frames): %s"
				% [GRACE_FRAMES, ", ".join(parts)])
	print("  note: SpellFxG layers %d, most pieces live at once %d (anywhere on the map)" % [
			root.get_tree().get_nodes_in_group(SpellFxG.GROUP).size(), _g_live_max])
	print("  note: watched %d visual nodes, %.1f s wall" % [_watch.size(), (Time.get_ticks_msec() - _t0) / 1000.0])
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in _fails:
			print("  - ", f)
		print("FAIL %s: %d leak(s); first: %s" % [TASK_ID, _fails.size(), _fails[0]])
	_done = true


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _secs(s: float) -> void:
	await create_timer(s).timeout

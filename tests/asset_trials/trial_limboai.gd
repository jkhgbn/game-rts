extends SceneTree
## Asset trial: LimboAI (GDExtension) vs plain GDScript for a T3 unit brain (Rime Colossus style: fight a target
## in reach, chase the nearest enemy inside aggro, walk home past the leash, else idle). Same decisions both ways,
## on stand-in agents (Node3D with the Unit command_* names), so only the decision layer is timed.
## Headless:  tools\godot_run.ps1 --headless --path . -s tests/asset_trials/trial_limboai.gd --quit-after 3000
## Prints ms / tick for 1 agent x 100 ticks and 200 agents x 100 ticks, and checks both brains agree.

const TICKS := 100
const CROWD := 200
const ATTACK_RANGE := 3.0
const AGGRO := 14.0
const LEASH := 25.0


## Stand-in unit: the Unit command names, counters instead of movement.
class Agent extends Node3D:
	var home := Vector3.ZERO
	var enemies: Array = []
	var moves := 0
	var attacks := 0
	var idles := 0
	var last := &""

	func command_move(p: Vector3) -> void:
		moves += 1
		last = &"move"
		position = position.move_toward(p, 0.6)

	func command_attack(_t: Node3D) -> void:
		attacks += 1
		last = &"attack"

	func command_stop() -> void:
		idles += 1
		last = &"idle"

	func nearest_enemy(r: float) -> Node3D:
		var best: Node3D = null
		var bd := r * r
		for e: Node3D in enemies:
			var d := position.distance_squared_to(e.position)
			if d < bd:
				bd = d
				best = e
		return best


# ---------------------------------------------------------------- LimboAI tasks
class TargetInReach extends BTCondition:
	func _tick(_dt: float) -> Status:
		var t: Node3D = blackboard.get_var(&"target", null)
		if t and is_instance_valid(t) and agent.position.distance_to(t.position) <= ATTACK_RANGE:
			return SUCCESS
		return FAILURE

class Attack extends BTAction:
	func _tick(_dt: float) -> Status:
		agent.command_attack(blackboard.get_var(&"target", null))
		return SUCCESS

class FindEnemy extends BTCondition:
	func _tick(_dt: float) -> Status:
		if agent.position.distance_to(agent.home) > LEASH:
			return FAILURE
		var e: Node3D = agent.nearest_enemy(AGGRO)
		blackboard.set_var(&"target", e)
		return SUCCESS if e else FAILURE

class Chase extends BTAction:
	func _tick(_dt: float) -> Status:
		var t: Node3D = blackboard.get_var(&"target", null)
		agent.command_move(t.position)
		return SUCCESS

class FarFromHome extends BTCondition:
	func _tick(_dt: float) -> Status:
		return SUCCESS if agent.position.distance_to(agent.home) > 1.5 else FAILURE

class GoHome extends BTAction:
	func _tick(_dt: float) -> Status:
		agent.command_move(agent.home)
		return SUCCESS

class Idle extends BTAction:
	func _tick(_dt: float) -> Status:
		agent.command_stop()
		return SUCCESS


func _build_tree() -> BehaviorTree:
	var sel := BTSelector.new()
	var fight := BTSequence.new()
	fight.add_child(TargetInReach.new())
	fight.add_child(Attack.new())
	var chase := BTSequence.new()
	chase.add_child(FindEnemy.new())
	chase.add_child(Chase.new())
	var ret := BTSequence.new()
	ret.add_child(FarFromHome.new())
	ret.add_child(GoHome.new())
	sel.add_child(fight)
	sel.add_child(chase)
	sel.add_child(ret)
	sel.add_child(Idle.new())
	var bt := BehaviorTree.new()
	bt.set_root_task(sel)
	return bt


# ---------------------------------------------------------------- the same brain in GDScript (BeastBrain style)
func _think(a: Agent, mem: Dictionary) -> void:
	var t: Node3D = mem.get(&"target")
	if t and a.position.distance_to(t.position) <= ATTACK_RANGE:
		a.command_attack(t)
		return
	if a.position.distance_to(a.home) <= LEASH:
		var e: Node3D = a.nearest_enemy(AGGRO)
		mem[&"target"] = e
		if e:
			a.command_move(e.position)
			return
	if a.position.distance_to(a.home) > 1.5:
		a.command_move(a.home)
		return
	a.command_stop()


# ---------------------------------------------------------------- world
func _make_world(n: int, seed_v: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var holder := Node3D.new()
	root.add_child(holder)
	var enemies: Array = []
	for i in 12:
		var e := Node3D.new()
		holder.add_child(e)
		e.position = Vector3(rng.randf_range(-30, 30), 0, rng.randf_range(-30, 30))
		enemies.append(e)
	var agents: Array = []
	for i in n:
		var a := Agent.new()
		holder.add_child(a)
		a.home = Vector3(rng.randf_range(-20, 20), 0, rng.randf_range(-20, 20))
		a.position = a.home
		a.enemies = enemies
		agents.append(a)
	return [holder, enemies, agents]


## Enemies walk a fixed pattern so targets enter / leave aggro (same for both runs).
func _step_enemies(enemies: Array, tick: int) -> void:
	for i in enemies.size():
		var e: Node3D = enemies[i]
		e.position += Vector3(sin(tick * 0.07 + i), 0, cos(tick * 0.05 + i * 2.0)) * 0.9


func _run_limbo(n: int) -> Dictionary:
	var w := _make_world(n, 7)
	var bt := _build_tree()
	var insts: Array = []
	var t0 := Time.get_ticks_usec()
	for a: Agent in w[2]:
		var bb := Blackboard.new()
		bb.set_var(&"target", null)   # get_var on a missing var logs an error every tick
		insts.append(bt.instantiate(a, bb, a, w[0]))   # a scene root is required
	var t_inst := Time.get_ticks_usec() - t0
	var total := 0
	for tick in TICKS:
		_step_enemies(w[1], tick)
		var s := Time.get_ticks_usec()
		for inst: BTInstance in insts:
			inst.update(0.5)
		total += Time.get_ticks_usec() - s
	var res := _tally(w[2])
	res["us"] = total
	res["inst_us"] = t_inst
	(w[0] as Node).free()
	return res


func _run_gd(n: int) -> Dictionary:
	var w := _make_world(n, 7)
	var mems: Array = []
	for a in w[2]:
		mems.append({})
	var total := 0
	for tick in TICKS:
		_step_enemies(w[1], tick)
		var s := Time.get_ticks_usec()
		var agents: Array = w[2]
		for i in agents.size():
			_think(agents[i], mems[i])
		total += Time.get_ticks_usec() - s
	var res := _tally(w[2])
	res["us"] = total
	(w[0] as Node).free()
	return res


func _tally(agents: Array) -> Dictionary:
	var m := 0
	var at := 0
	var idl := 0
	for a: Agent in agents:
		m += a.moves
		at += a.attacks
		idl += a.idles
	return {"moves": m, "attacks": at, "idles": idl}


func _initialize() -> void:
	if not ClassDB.class_exists("BehaviorTree"):
		print("FAIL limboai: extension not loaded")
		quit(1)
		return
	# warm-up (first-call costs), then measured runs
	_run_limbo(10)
	_run_gd(10)
	var ok := true
	for n: int in [1, CROWD]:
		var l := _run_limbo(n)
		var g := _run_gd(n)
		var ticks := float(n * TICKS)
		print("LIMBO n=%d: %.4f ms/tick-per-agent, %.3f ms per full think of all agents, decisions m/a/i=%d/%d/%d, instantiate %.2f ms" % [
			n, l.us / 1000.0 / ticks, l.us / 1000.0 / TICKS, l.moves, l.attacks, l.idles, l.inst_us / 1000.0])
		print("GDSCR n=%d: %.4f ms/tick-per-agent, %.3f ms per full think of all agents, decisions m/a/i=%d/%d/%d" % [
			n, g.us / 1000.0 / ticks, g.us / 1000.0 / TICKS, g.moves, g.attacks, g.idles])
		print("RATIO n=%d: limbo / gdscript = %.2fx" % [n, float(l.us) / maxf(1.0, float(g.us))])
		if l.moves != g.moves or l.attacks != g.attacks or l.idles != g.idles:
			ok = false
			print("MISMATCH n=%d: the two brains decided differently" % n)
	print("PASS limboai trial" if ok else "FAIL limboai trial: decisions differ")
	quit()

class_name SpellHot
extends Node
## A heal over time on a fixed list of units (Wild Bloom, kingdom-nature.md 3.1): every `tick_interval`
## seconds each target still alive heals `per_tick` (Unit.heal, capped at max HP). Ticks at 0.5, 1.0 ...
## duration: a 5 s bloom ticks 10 times. The list is taken at cast; walking out of the circle keeps
## the heal. Lives in the world (not under the caster), so it survives the caster's death.

## One tick healed `target` by `amount` (before the max-HP cap), for the "+" sparkle.
signal healed_target(target: Node3D, amount: float)
signal finished

var spell_id: StringName
var per_tick := 0.0
var tick_interval := 0.5
var duration := 5.0
var targets: Array[Node3D] = []

var _elapsed := 0.0
var _next_tick := 0.0


func setup(p_targets: Array[Node3D], total_heal: float, p_duration: float, p_interval: float) -> void:
	targets = p_targets.duplicate()
	duration = maxf(0.0, p_duration)
	tick_interval = maxf(0.05, p_interval)
	var ticks := maxi(1, roundi(duration / tick_interval))
	per_tick = total_heal / float(ticks)
	_next_tick = tick_interval


func _physics_process(delta: float) -> void:
	_elapsed += delta
	while _elapsed + 0.0001 >= _next_tick and _next_tick <= duration + 0.0001:
		_tick()
		_next_tick += tick_interval
	if _next_tick > duration + 0.0001 or targets.is_empty():
		set_physics_process(false)
		finished.emit()
		queue_free()


func _tick() -> void:
	for i in range(targets.size() - 1, -1, -1):
		var u := targets[i]
		if not SpellCaster.is_target_alive(u):
			targets.remove_at(i)
			continue
		u.call(&"heal", per_tick)
		healed_target.emit(u, per_tick)

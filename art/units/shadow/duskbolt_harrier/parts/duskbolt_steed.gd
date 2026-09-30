extends "res://art/units/mounts/dusk_steed/dusk_steed.gd"
## Duskbolt Steed: the Duskbolt Harrier's horse (stables.md 2, Shadow X, the tier-1 crossbow skirmisher). The shared
## 13.V3 Dusk Steed (anatomy, gait, charge, fidget, violet dissolve death, glowing eyes, tattered team caparison), unbarded
## and rigged light: a BOLT CASE on each flank behind the rider's knees (a team-dark case with a silver cap and a leather
## strap, a sheaf of bolts with violet-grey fletchings), a rolled dark blanket across the croup behind the cantle. Merged
## into the Dusk Steed's own Body pivot (0 extra draw instances; own type key = own caches).
## Scene: parts/duskbolt_steed.tscn (the Dusk Steed's pivots, a quicker lighter gait).


func _build_mount() -> void:
	super()
	add_sculpt($Root/Mount, _gear_sculpt)


func _gear_sculpt(s: Dictionary) -> void:
	var cdark := m("shadow_cloth_dark")
	var sil := m("shadow_silver")
	var lea := m("shadow_leather")
	var wood := m("shadow_iron")
	var fl := m("dusk_wisp")
	for sx: float in [-1.0, 1.0]:
		# the bolt case hanging on the flank, tilted back, its mouth up
		var mouth := Vector3(0.36 * sx, 1.36, -0.30)
		var axis := Vector3(0.08 * sx, 1.0, -0.35).normalized()
		var bottom := mouth - axis * 0.40
		var fb := frame(Vector3.ZERO, axis, Vector3(sx, 0, 0)).basis
		sculpt_add(s, cyl(0.075, 0.06, 0.40, 6), Transform3D(fb, bottom + axis * 0.20), cdark)
		sculpt_add(s, cyl(0.08, 0.08, 0.035, 6, false), Transform3D(fb, mouth), sil)
		sculpt_put(s, box(Vector3(0.025, 0.04, 0.26)), lea, mouth + Vector3(-0.03 * sx, -0.12, 0.13), Vector3(0, 0, -20.0 * sx))
		# the sheaf of bolts: short shafts with fletchings
		for k: int in 4:
			var a := TAU * float(k) / 4.0
			var o := fb * Vector3(cos(a) * 0.035, 0, sin(a) * 0.035)
			var base := mouth + o - axis * 0.10
			sculpt_add(s, cyl(0.009, 0.009, 0.26, 3), Transform3D(fb, base + axis * 0.13), wood)
			sculpt_add(s, box(Vector3(0.05, 0.08, 0.008)), Transform3D(fb * Basis(Vector3.UP, a), base + axis * 0.22), fl)
	# the rolled blanket across the croup behind the cantle, two straps
	sculpt_add(s, cyl(0.075, 0.075, 0.46, 8), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 1.70, -0.36)), cdark)
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, cyl(0.079, 0.079, 0.03, 8, false), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.12 * sx, 1.70, -0.36)),
			lea)

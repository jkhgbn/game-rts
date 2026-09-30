extends "res://art/units/mounts/ember_boar/ember_boar.gd"
## Emberdart Boar: the Emberdart Harrier's boar (stables.md 2, Fire X, the tier-1 javelin skirmisher). The shared 13.V2
## Ember Boar (anatomy, gait, charge, fidget, death, eyes, team caparison) rigged light for skirmishing: a JAVELIN QUIVER
## strapped on each flank behind the rider's knees (a team-dark tube with a bronze cap, three javelins fanning up and back,
## bronze heads, a little team streamer on the tallest one) and a leather breast strap with a bronze boss. Merged into the
## Ember Boar's own Body pivot (0 extra draw instances; own type key = own caches). No barding.
## Scene: parts/emberdart_boar.tscn (the Ember Boar's pivots, a lighter quicker gait tuning).

func _build_mount() -> void:
	super()
	add_sculpt($Root/Mount, _quiver_sculpt)


func _quiver_sculpt(s: Dictionary) -> void:
	var leather := m("fire_leather")
	var bronze := m("fire_bronze")
	var wood := m("fire_wood")
	var cloth := m("fire_cloth")
	for sx: float in [-1.0, 1.0]:
		# the quiver: a team-dark tube hanging on the flank, mouth up and back, a bronze cap and a leather strap
		var e := _bp(-0.36, 72.0 * sx, 0.10)
		var mouth: Vector3 = (e[0] as Vector3) + Vector3(0.02 * sx, 0.08, 0)
		var axis := Vector3(0.12 * sx, 1.0, -0.55).normalized()
		var bottom := mouth - axis * 0.46
		sculpt_add(s, tube_mesh("emberdart_quiver_v1", PackedVector3Array([Vector3.ZERO, Vector3(0, 0.46, 0)]),
			PackedFloat32Array([0.07, 0.085]), 6), Transform3D(frame(bottom, axis, Vector3(sx, 0, 0)).basis, bottom),
			m("fire_cloth_dark"))
		sculpt_add(s, cyl(0.075, 0.075, 0.04, 6), Transform3D(frame(bottom, axis, Vector3(sx, 0, 0)).basis, bottom), bronze)
		sculpt_put(s, box(Vector3(0.03, 0.05, 0.30)), leather, (e[0] as Vector3) + Vector3(0.0, -0.06, 0.1),
			Vector3(0, 0, -30.0 * sx))
		# three javelins fanning out of it, bronze heads, a team streamer on the tallest
		for k: int in 3:
			var f := float(k) - 1.0
			var jd := (axis + Vector3(0.10 * f * sx, 0.05 * f, 0.18 * f)).normalized()
			var base := mouth - axis * 0.30 + Vector3(0.012 * f * sx, 0, 0.02 * f)
			var ln: float = 0.95 + 0.12 * (1.0 - absf(f))
			sculpt_add(s, cyl(0.016, 0.016, ln, 4), Transform3D(frame(Vector3.ZERO, jd, Vector3(sx, 0, 0)).basis,
				base + jd * ln * 0.5), wood)
			sculpt_add(s, cyl(0.0, 0.034, 0.13, 4), Transform3D(frame(Vector3.ZERO, jd, Vector3(sx, 0, 0)).basis,
				base + jd * (ln + 0.05)), bronze)
			if k == 1:
				var tb := frame(Vector3.ZERO, jd, Vector3(sx, 0, 0)).basis
				sculpt_add(s, box(Vector3(0.012, 0.20, 0.07)), Transform3D(tb, base + jd * (ln - 0.12) - tb.z * 0.045), cloth)
	# a leather breast strap round the chest with a bronze boss
	var cb := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))
	sculpt_add(s, shell_mesh("emberdart_breast_v1", 0.37, 0.35, -62.0, 62.0, 0.0, 0.05, 0.02, 6, 1), Transform3D(cb,
		Vector3(0, 0.64, 0.58)), leather)
	sculpt_put(s, sphere(0.05, 6, 3), bronze, Vector3(0, 0.665, 0.935), Vector3.ZERO, Vector3(1.0, 1.0, 0.6))

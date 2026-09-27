extends "res://art/units/wizards/vessa.gd"
## MOCK-UP ONLY (hair redesign plan, direction "Vessa: ember-tipped swept locks under the hat"). The real model
## art/units/wizards/vessa.gd is untouched: this variant builds Vessa as usual, removes her two flat side slabs and
## adds swept locks from the prototype hair builder (hair_kit.gd):
##   - 2 long FRONT LOCKS: out from under the brim beside the cheeks, over the collar, lying on the front of the
##     mantle and curling out; ember-gold tips (the 25 m hook: dark strands on the orange mantle, gold points);
##   - 2 short SIDE LOCKS behind them (volume at 3/4, peek past the brim edge from the high camera);
##   - 1 FRINGE swoop under the brim, swept to her off side like the hat tip.
## Palette: fire_hair (body) + fire_sec_archer (tips), both existing kit entries; 1 extra surface on the Head pivot.

const HairKit := preload("res://docs/art/hair/mock/hair_kit.gd")


func _build_parts() -> void:
	super._build_parts()
	var head: Node3D = $Root/Chest/Head
	var slab := cyl(0.07, 0.08, 0.38, 6)
	# WizardModel batches static parts per pivot (_part_batch) before the kit merge: drop the two side slabs there.
	var items: Array = _part_batch.get(head, [])
	var kept: Array = []
	for it: Array in items:
		if it[0] != slab:
			kept.append(it)
	print("HAIR MOCK removed ", items.size() - kept.size(), " slabs")
	_part_batch[head] = kept
	var body := HairKit.begin()
	var tip := HairKit.begin()
	for sx: float in [-1.0, 1.0]:
		# front lock: root beside the cheek under the brim -> over the collar -> on the mantle -> tip curls out
		HairKit.lock(body, tip, [Vector3(0.20 * sx, 1.98, 0.0), Vector3(0.34 * sx, 1.72, 0.12),
			Vector3(0.19 * sx, 1.56, 0.42), Vector3(0.31 * sx, 1.37, 0.48)],
			Vector3(0.5 * sx, 0.2, 0.8).normalized(), 0.19, 0.07, 5, 0.55, -25.0 * sx)
		# temple lock: covers the temple the old slab hid, curls onto the cheek line (frames the face)
		HairKit.lock(body, tip, [Vector3(0.14 * sx, 2.00, 0.12), Vector3(0.24 * sx, 1.93, 0.19),
			Vector3(0.28 * sx, 1.80, 0.17), Vector3(0.27 * sx, 1.68, 0.14)],
			Vector3(0.7 * sx, 0.1, 0.7).normalized(), 0.14, 0.055, 4, 0.72, 10.0 * sx)
		# side lock: behind the front one, outward past the face, short
		HairKit.lock(body, tip, [Vector3(0.20 * sx, 1.97, -0.08), Vector3(0.34 * sx, 1.78, -0.06),
			Vector3(0.37 * sx, 1.62, -0.02), Vector3(0.43 * sx, 1.52, 0.02)],
			Vector3(sx, 0.1, 0.2).normalized(), 0.14, 0.06, 4, 0.7, 20.0 * sx)
	# fringe: from her right temple across the forehead under the brim, swept to her off side (-X, like the hat tip)
	HairKit.lock(body, tip, [Vector3(0.15, 1.99, 0.16), Vector3(0.05, 1.97, 0.27),
		Vector3(-0.10, 1.93, 0.27), Vector3(-0.23, 1.86, 0.20)],
		Vector3(0, 0.3, 1).normalized(), 0.12, 0.05, 4, 1.0, 0.0)
	var mesh := HairKit.finish(body, palette(&"fire_hair"), tip, palette(&"fire_sec_archer"))
	add_part(head, mesh, null, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false, "HairLocks")
	print("HAIR MOCK vessa locks verts=", mesh.surface_get_array_len(0) + mesh.surface_get_array_len(1))


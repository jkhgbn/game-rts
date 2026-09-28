extends RefCounted
## forge_evenmead layout shared by make_world.gd and bake_armies.gd (set-only tool helper): the river, the water
## level, the worn tracks to the ford, the heroes' spots, the camera focus points (grass / flower density) and the four
## hosts' formations. Set coordinates, metres, +z = south. No class_name on purpose.

const WL := -1.25  ## river water level (the valley bed is ~-2.6, the ford bar ~-1.6)
const SUN := Vector3(0.966, 0.259, 0.0)  ## toward the sun (preset_golden: rotation (-15, 90, 0))
const RIVER := [Vector2(-175, 12), Vector2(-120, 10), Vector2(-75, 6), Vector2(-44, -3), Vector2(-18, 4), Vector2(4, 0),
	Vector2(26, -7), Vector2(50, -2), Vector2(75, 5), Vector2(120, 2), Vector2(175, -4)]
const FORD := Vector2(4.0, 0.0)
const TRACK_N := [Vector2(0.5, -32.5), Vector2(2.5, -26), Vector2(5.5, -17), Vector2(5.2, -9), Vector2(4.3, -4)]
const TRACK_S := [Vector2(4.3, 4.5), Vector2(3.2, 11), Vector2(0.5, 18), Vector2(-2.5, 25), Vector2(-3.6, 31)]
const HEROES := {"malrik": Vector2(0, -36), "torvald": Vector2(-3.4, -37), "hush": Vector2(2.8, -37.5),
	"ysolde": Vector2(-5, 34), "vessa": Vector2(-1.6, 35), "vey": Vector2(-8.4, 35.5)}
const MASTER_TREE := Vector2(-16.0, 48.5)
## Where the cameras look from / at the ground closely: the grass and flowers are densest round these (x, z, radius).
const FOCUS := [
	Vector3(0, -36, 16), Vector3(-5, 34, 16),            # both crests (every Lens close shot)
	Vector3(-16, -22, 14), Vector3(12, 21, 14),           # N05 / S06 travelling foregrounds
	Vector3(40, 13, 12), Vector3(30, 6, 12),              # B01's crane end over the east slope
	Vector3(4, 0, 14), Vector3(12, 9, 10),                # the ford and its stones
	Vector3(-16.0, 48.5, 12),                             # the Master's tree
]

## The four hosts: blocks of real unit models, facing the valley. Each entry: [scene, centre (x, z), cols, rows, dx,
## dz, yaw deg, pose frame, seed, scale]. North faces south (yaw 0), south faces north (yaw 180).
const U := "res://art/units/"
const ARMIES := {
	"shadow": [
		[U + "shadow/shadow_knight.tscn", Vector2(-22.5, -29.0), 8, 3, 1.75, 1.9, 0.0, 6, 11, 1.0],
		[U + "shadow/shade.tscn", Vector2(-8.8, -28.6), 6, 3, 1.5, 1.7, 0.0, 9, 12, 1.0],
		[U + "shadow/shadow_knight.tscn", Vector2(10.0, -29.4), 7, 3, 1.75, 1.9, 0.0, 7, 13, 1.0],
		[U + "shadow/bleakbow/bleakbow.tscn", Vector2(-21.0, -33.6), 9, 2, 1.55, 1.6, 0.0, 10, 14, 1.0],
		[U + "shadow/bleakbow/bleakbow.tscn", Vector2(11.5, -34.0), 8, 2, 1.55, 1.6, 0.0, 12, 15, 1.0],
		[U + "shadow/hexweaver/hexweaver.tscn", Vector2(-31.5, -31.0), 2, 2, 2.0, 2.0, 12.0, 14, 16, 1.0],
		[U + "shadow/hexweaver/hexweaver.tscn", Vector2(20.5, -31.8), 2, 1, 2.0, 2.0, -10.0, 16, 17, 1.0],
		[U + "shadow/barrow_giant/barrow_giant.tscn", Vector2(-35.5, -27.0), 1, 1, 1.0, 1.0, 15.0, 8, 18, 1.0],
		[U + "shadow/barrow_giant/barrow_giant.tscn", Vector2(24.0, -28.0), 1, 1, 1.0, 1.0, -12.0, 10, 19, 1.0],
		[U + "shadow/grave_hound.tscn", Vector2(-19.0, -25.2), 4, 1, 1.9, 1.0, 5.0, 12, 20, 1.0],
	],
	"ice": [
		[U + "ice/rimeshield.tscn", Vector2(35.0, -28.0), 8, 2, 1.8, 1.9, -12.0, 6, 31, 1.0],
		[U + "ice/frostbow/frostbow.tscn", Vector2(36.0, -32.2), 7, 2, 1.6, 1.6, -12.0, 9, 32, 1.0],
		[U + "ice/frostrune_rifleman/frostrune_rifleman.tscn", Vector2(46.0, -27.5), 2, 3, 1.7, 1.7, -18.0, 11, 33, 1.0],
		[U + "ice/shardcaster.tscn", Vector2(28.0, -33.0), 2, 1, 2.0, 1.0, -8.0, 13, 34, 1.0],
		[U + "titans/war_mammoth/war_mammoth.tscn", Vector2(45.5, -35.5), 1, 1, 1.0, 1.0, -20.0, 8, 35, 1.0],
	],
	"nature": [
		[U + "nature/vinelasher/vinelasher.tscn", Vector2(-13.5, 23.2), 6, 2, 1.7, 1.8, 180.0, 6, 41, 1.0],
		[U + "nature/wildwood_archer/wildwood_archer.tscn", Vector2(-24.5, 24.2), 7, 3, 1.55, 1.7, 182.0, 9, 42, 1.0],
		[U + "nature/stagrunner/stagrunner.tscn", Vector2(-35.0, 23.5), 2, 2, 2.6, 2.8, 170.0, 11, 43, 1.0],
		[U + "nature/mossback/mossback.tscn", Vector2(-18.5, 28.5), 1, 1, 1.0, 1.0, 185.0, 8, 44, 1.0],
		[U + "nature/bramblehorn.tscn", Vector2(-29.5, 28.8), 1, 1, 1.0, 1.0, 178.0, 10, 45, 1.0],
		[U + "nature/thornling.tscn", Vector2(-8.5, 26.5), 3, 1, 1.4, 1.0, 175.0, 12, 46, 1.0],
	],
	"fire": [
		[U + "fire/flame_guard.tscn", Vector2(9.5, 23.4), 8, 3, 1.7, 1.9, 180.0, 6, 51, 1.0],
		[U + "fire/scorchbow/scorchbow.tscn", Vector2(10.5, 28.0), 8, 2, 1.55, 1.6, 182.0, 9, 52, 1.0],
		[U + "fire/blaze_rider.tscn", Vector2(24.5, 23.8), 3, 2, 2.6, 2.9, 190.0, 11, 53, 1.0],
		[U + "fire/ash_hurler.tscn", Vector2(-1.0, 27.8), 2, 1, 2.4, 1.0, 175.0, 13, 54, 1.15],
		[U + "fire/pyre_adept/pyre_adept.tscn", Vector2(19.0, 28.6), 3, 1, 1.8, 1.0, 185.0, 14, 55, 1.0],
	],
}
## Standards carried in the hosts (x, z, kingdom, height m) and the two hero standards (tagged places, separate parts).
const STANDARDS := [
	Vector3(-26.0, -31.6, 0), Vector3(-17.0, -31.2, 0), Vector3(-8.8, -31.4, 0), Vector3(5.0, -32.0, 0), Vector3(15.0, -32.2, 0),
	Vector3(31.0, -30.6, 1), Vector3(40.0, -30.4, 1),
	Vector3(-29.0, 27.2, 2), Vector3(-19.5, 26.8, 2), Vector3(-11.0, 25.6, 2),
	Vector3(4.0, 26.4, 3), Vector3(14.5, 26.6, 3), Vector3(24.0, 27.4, 3),
]
const BANNER_N := Vector2(-5.6, -25.6)   ## Malrik's great standard, before the Shade block (N05 subject)
const BANNER_S := Vector2(1.5, 21.5)     ## Ysolde's great standard, before the join of Nature and Fire (S06 subject)
const KINGDOMS := ["shadow", "ice", "nature", "fire"]


static func dist_poly(p: Vector2, poly: Array) -> float:
	var best := INF
	for i in range(poly.size() - 1):
		var q := Geometry2D.get_closest_point_to_segment(p, poly[i], poly[i + 1])
		best = minf(best, q.distance_to(p))
	return best


## Units of one host: [{scene, pos (x, z), yaw, frame, scale}] with hashed jitter (deterministic).
static func units_of(army: String) -> Array:
	var out: Array = []
	for blk: Array in ARMIES[army]:
		var cc: Vector2 = blk[1]
		var cols: int = blk[2]
		var rows: int = blk[3]
		var dx: float = blk[4]
		var dz: float = blk[5]
		var yaw: float = blk[6]
		var seed: int = blk[8]
		var b := Transform2D(deg_to_rad(-yaw), Vector2.ZERO)
		for r in rows:
			for k in cols:
				var lx := (k - (cols - 1) * 0.5) * dx + (0.25 * dx if r % 2 == 1 else 0.0)
				var lz := -(r - (rows - 1) * 0.5) * dz
				var j := Vector2((h01(k, r, seed) - 0.5) * 0.36, (h01(r, k, seed + 1) - 0.5) * 0.36)
				var p := cc + b.basis_xform(Vector2(lx, lz)) + j
				out.append({"scene": blk[0], "pos": p, "yaw": yaw + (h01(k + 3, r, seed + 2) - 0.5) * 10.0,
					"frame": int(blk[7]) + int(h01(k, r + 7, seed + 3) * 40.0), "scale": float(blk[9]) * (0.97 + 0.06 * h01(k, r, seed + 4))})
	return out


static func h01(a: float, b: float, s: int) -> float:
	var hh := int(floor(a * 97.0)) * 73856093 ^ int(floor(b * 89.0)) * 19349663 ^ s * 83492791
	hh = (hh ^ (hh >> 13)) * 1274126177
	return float((hh ^ (hh >> 16)) & 0xffff) / 65535.0

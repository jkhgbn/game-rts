class_name NatureKeepTiers
extends RefCounted
## G-B Nature: the Heartwood's tier looks (docs/art/gb_nature_buildings.md). Keep.set_tier_now / upgrade call the
## model's set_tier(t), set_upgrading(on), play_tier_up(); nature_keep.gd builds these nodes once per keep:
##   Tier2Stones  four leaning rune menhirs on the plinth corners (Stronghold and up)
##   Tier2Crown   five glowing blossoms opened on the canopy top (Stronghold and up)
##   Tier3Crown   four great blossoms between them + seed lights on the menhirs (Citadel)
##   Tier3Halo    a slowly turning ring of glowing feather-petals above the Crown Bloom (Citadel)
##   GrowthVines  four glowing vines that climb the rampart and the trunk while the keep upgrades (scale.y = progress)
## Meshes are built from code once per process (NatureKit.MB, cached) and drawn with the keep's own materials
## (surface overrides), so team colour, selection boost and damage follow for free. No lights, no particles here.

const CROWN_PIVOT := Vector3(0.0, 14.2, 0.0)
const HALO_Y := 18.05
const STONE_R := 2.95   ## the menhirs stand on the plinth's chamfered corners (diagonal, x = z = +-2.95)

static var _meshes: Dictionary = {}
static var _canopy_top: Dictionary = {}


## The mesh `key` ([ArrayMesh, keys]); `canopy` = the keep's canopy MeshInstance3D (for the crown's surface heights).
static func mesh(key: String, canopy: MeshInstance3D) -> Array:
	if _meshes.has(key):
		return _meshes[key]
	if _canopy_top.is_empty() and canopy != null:
		_sample_canopy(canopy)
	var mb := NatureKit.MB.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	match key:
		"stones2": _stones(mb, false)
		"crown2": _crown(mb, rng, 5, 2.85, 18.0, 0.42)
		"crown3": _crown3(mb, rng)
		"halo3": _halo(mb, rng)
		"vines": _vines(mb, rng)
	var res: Array = mb.commit()
	_meshes[key] = res
	return res


## Top of the canopy (model space y) above (x, z): highest canopy vertex within 0.7 m, else 15.
static func canopy_height(x: float, z: float) -> float:
	var best: float = -1.0
	var cell := Vector2i(roundi(x / 0.5), roundi(z / 0.5))
	for dx: int in range(-1, 2):
		for dz: int in range(-1, 2):
			best = maxf(best, float(_canopy_top.get(cell + Vector2i(dx, dz), -1.0)))
	return best if best > 0.0 else 15.0


static func _sample_canopy(canopy: MeshInstance3D) -> void:
	var xf: Transform3D = canopy.transform
	for s: int in canopy.mesh.get_surface_count():
		var arr: Array = canopy.mesh.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for v: Vector3 in vs:
			var p: Vector3 = xf * v
			var cell := Vector2i(roundi(p.x / 0.5), roundi(p.z / 0.5))
			_canopy_top[cell] = maxf(float(_canopy_top.get(cell, -1.0)), p.y)


## Four menhirs leaning out from the plinth's corners, runes facing out.
static func _stones(mb: NatureKit.MB, _tall: bool) -> void:
	for i: int in 4:
		var sx: float = 1.0 if (i & 1) != 0 else -1.0
		var sz: float = 1.0 if (i & 2) != 0 else -1.0
		var out := Vector3(sx, 0.0, sz).normalized()
		var base := Vector3(sx * STONE_R, -0.15, sz * STONE_R)
		NatureKit.menhir(mb, base, out, 1.75 + 0.15 * float(i % 2), 0.3, 9.0, true)
		# A moss collar and two ferny leaves at the foot.
		for k: int in 3:
			var a: float = TAU * float(k) / 3.0 + float(i)
			var d := Vector3(cos(a), 0.0, sin(a))
			var p0: Vector3 = base + d * 0.38 + Vector3(0.0, 0.12, 0.0)
			mb.strip("LeafCard", [p0, p0 + d * 0.35 + Vector3(0, 0.25, 0), p0 + d * 0.62 + Vector3(0, 0.12, 0)] as Array[Vector3],
				Vector3(-d.z, 0.0, d.x), 0.3, [Vector3.UP, Vector3.UP, Vector3.UP] as Array[Vector3], float(i * 3 + k) / 12.0, float(k) / 3.0)


## `n` blossoms around the bloom on the canopy top at radius `r` (first at `deg0`), each tilted outward.
static func _crown(mb: NatureKit.MB, rng: RandomNumberGenerator, n: int, r: float, deg0: float, size: float) -> void:
	for i: int in n:
		var a: float = deg_to_rad(deg0) + TAU * float(i) / float(n)
		var x: float = cos(a) * r
		var z: float = sin(a) * r
		var y: float = canopy_height(x, z) - 0.12
		var out := Vector3(cos(a), 0.0, sin(a))
		var up: Vector3 = (Vector3.UP + out * 0.45).normalized()
		var side: Vector3 = up.cross(out).normalized()
		var basis := Basis(side, up, side.cross(up).normalized()).rotated(up, rng.randf() * TAU)
		NatureKit.flower(mb, Vector3(x, y, z) - CROWN_PIVOT, basis, size * rng.randf_range(0.9, 1.1), 7, rng, 5, true)


static func _crown3(mb: NatureKit.MB, rng: RandomNumberGenerator) -> void:
	_crown(mb, rng, 4, 3.25, 63.0, 0.5)
	# Seed lights crowning the four menhirs (model space: this mesh sits at CROWN_PIVOT, so offset back down).
	for i: int in 4:
		var sx: float = 1.0 if (i & 1) != 0 else -1.0
		var sz: float = 1.0 if (i & 2) != 0 else -1.0
		var out := Vector3(sx, 0.0, sz).normalized()
		var h: float = 1.75 + 0.15 * float(i % 2)
		var top := Vector3(sx * STONE_R, -0.15, sz * STONE_R) + Vector3(0.0, h + 0.3 * 0.9 + 0.32, 0.0) \
			+ out * h * tan(deg_to_rad(9.0))
		mb.sphere("Gate", top - CROWN_PIVOT, 0.15, 1.2, 8, 5)   # rune glow: green, never blown to white


## Twelve curling rays of rune light in a ring floating above the Crown Bloom, a seed between each pair (Tier3Halo
## turns it): a crown of light that reads apart from the pink bloom.
static func _halo(mb: NatureKit.MB, rng: RandomNumberGenerator) -> void:
	var n: int = 12
	for i: int in n:
		var a: float = TAU * float(i) / float(n)
		var d := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-d.z, 0.0, d.x)
		var pts: Array[Vector3] = []
		var nrms: Array[Vector3] = []
		for s: int in 5:
			var t: float = float(s) / 4.0
			pts.append(d * (2.15 + t * 0.95) + Vector3(0.0, 0.25 * t + 0.35 * t * t + 0.08 * sin(a * 3.0), 0.0))
			nrms.append((Vector3.UP * 0.9 - d * 0.3).normalized())
		mb.strip("Gate", pts, side, 0.13 + 0.03 * rng.randf(), nrms, float(i) / float(n), rng.randf())
		# A tiny glowing seed between each pair of feathers.
		var sa: float = a + PI / float(n)
		mb.sphere("Heart", Vector3(cos(sa), 0.0, sin(sa)) * 2.55 + Vector3(0.0, 0.12, 0.0), 0.075, 1.0, 6, 4)


## Four glowing vines climbing from the plinth corners, spiralling onto the trunk up to ~8 m, leaves along them.
static func _vines(mb: NatureKit.MB, rng: RandomNumberGenerator) -> void:
	for i: int in 4:
		var a0: float = PI * 0.25 + PI * 0.5 * float(i)
		var pts: Array[Vector3] = []
		var radii: Array[float] = []
		var steps: int = 22
		for s: int in steps + 1:
			var t: float = float(s) / float(steps)
			var a: float = a0 + t * 1.9
			# Up the outside of the rampart and the roots (r ~3.8 to 6 m high), then in onto the trunk under the canopy.
			var r: float = lerpf(3.85, 3.6, t / 0.62) if t < 0.62 else lerpf(3.6, 1.45, smoothstep(0.62, 1.0, t))
			var y: float = lerpf(0.05, 8.3, t) + 0.12 * sin(t * 19.0 + float(i))
			pts.append(Vector3(cos(a) * r, y, sin(a) * r))
			radii.append(lerpf(0.13, 0.055, t))
		mb.tube("Gate", pts, radii, 5, 1.0, 0.0, 0.0, false, true)
		for s: int in range(2, steps, 3):
			var p: Vector3 = pts[s]
			var outward := Vector3(p.x, 0.0, p.z).normalized()
			var d: Vector3 = (outward + Vector3.UP * 0.6).normalized()
			mb.strip("LeafCard", [p, p + d * 0.28, p + d * 0.5 + Vector3(0, -0.06, 0)] as Array[Vector3],
				outward.cross(Vector3.UP).normalized(), 0.26, [d, d, d] as Array[Vector3], rng.randf(), rng.randf())

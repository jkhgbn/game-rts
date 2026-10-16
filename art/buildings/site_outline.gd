class_name SiteOutline
extends RefCounted
## G-F Shadow leftovers (docs/art/gf_shadow_leftovers.md): the glowing construction outline (art-keep 8.2: four
## emissive bars round the footprint) in a calm style (`outline_calm`; G-F round 3: the default of every hall / small
## building model, all kingdoms): thinner bars, a low steady emission, the team glow graded like the Dusk Keep lights
## (hue kept, saturation <= SAT, value <= VAL), so the site's pad and scaffold read before the outline. A model that
## sets `outline_calm = false` keeps the old style. Also the shared site pad (make_pad, below).

const ENERGY := 2.0         ## default outline energy (rune_glow `energy`)
const PULSE := TAU          ## default pulse speed (rad/s)
const CALM_ENERGY := 0.45   ## calm: albedo = c x (0.4 + 0.45 x pulse) ~ 0.8 c, never over the glow cap
const CALM_PULSE := 1.6     ## calm: a slow breath, not a 1 Hz blink
const CALM_WIDTH := 0.5     ## calm: bar width x this
const SAT := 0.4            ## calm: saturation cap (DuskKeepModel.LIGHT_SAT)
const VAL := 0.7            ## calm: value cap


static func energy(calm: bool) -> float:
	return CALM_ENERGY if calm else ENERGY


static func pulse(calm: bool) -> float:
	return CALM_PULSE if calm else PULSE


static func width(base: float, calm: bool) -> float:
	return base * CALM_WIDTH if calm else base


static func tint(glow: Color, calm: bool) -> Color:
	if not calm:
		return glow
	return Color.from_hsv(glow.h, minf(glow.s, SAT), minf(glow.v, VAL))


# --- G-F round 3 sites (docs/art/gf_r3_sites.md, gf_review3 top-6 item 4): one site look for every kingdom ---
# A worked-earth pad (value ~0.35-0.5, kingdom-tinted: Fire warm clay, Ice frosted stone, Nature turned earth, Shadow
# slate; lit painted_vc, never black), kingdom flags / furrows laid on it, layout stakes with cords (Halls), and a
# timber stack + a kingdom pile (bricks / stone blocks / planks / slates) by the +X side, every piece resting on the
# ground or on the piece under it. ONE mesh per kingdom / size, shared by every site (cached); one material per model
# (the team / Fire paint passes touch it: never shared between instances).

const PAINTED_VC: Shader = preload("res://art/shaders/painted_vc.gdshader")
const PAD_NOISE: Texture2D = preload("res://art/shaders/paint_noise.tres")
## [earth a, earth b, flag / detail, timber, pile] per kingdom (sRGB, every value >= 0.3).
const PALETTE := {
	&"fire": [Color(0.47, 0.34, 0.25), Color(0.42, 0.29, 0.21), Color(0.58, 0.42, 0.31), Color(0.50, 0.34, 0.20),
		Color(0.60, 0.36, 0.25)],
	&"ice": [Color(0.50, 0.53, 0.57), Color(0.44, 0.47, 0.52), Color(0.68, 0.73, 0.78), Color(0.47, 0.39, 0.31),
		Color(0.60, 0.65, 0.71)],
	&"nature": [Color(0.44, 0.33, 0.23), Color(0.37, 0.27, 0.18), Color(0.40, 0.44, 0.25), Color(0.50, 0.36, 0.21),
		Color(0.55, 0.42, 0.27)],
	&"shadow": [Color(0.42, 0.40, 0.47), Color(0.36, 0.35, 0.41), Color(0.50, 0.49, 0.57), Color(0.40, 0.32, 0.27),
		Color(0.38, 0.37, 0.45)],
}
const PAD_AO_BOTTOM := -0.6   ## instance ao_bottom: the pad sits in the lit band of the height gradient (no contact dark)
const PAD_AO_HEIGHT := 1.5

static var _pad_meshes: Dictionary = {}   ## "<kingdom>|<half>|<stakes>" -> ArrayMesh


## The kingdom a model's glow colour belongs to (hue bands of the four kingdom glows).
static func kingdom_of(glow: Color) -> StringName:
	var h: float = glow.h
	if glow.s < 0.15:
		return &"ice"
	if h < 0.13 or h > 0.93:
		return &"fire"
	if h < 0.45:
		return &"nature"
	if h < 0.68:
		return &"ice"
	return &"shadow"


## The kingdom's site timber (scaffold stand-in when a model has no wood material).
static func timber(kingdom: StringName) -> Color:
	return (PALETTE.get(kingdom, PALETTE[&"fire"]) as Array)[3]


## A new "SitePad" node (root child of the model, hidden; the model shows it while it is a site). `half` = footprint
## half size; `stakes` = corner layout stakes with cords (Halls; small buildings have their scaffold poles there).
static func make_pad(kingdom: StringName, half: float, stakes: bool) -> MeshInstance3D:
	if not PALETTE.has(kingdom):
		kingdom = &"fire"
	var key: String = "%s|%.2f|%s" % [kingdom, half, stakes]
	if not _pad_meshes.has(key):
		_pad_meshes[key] = _pad_mesh(kingdom, half, stakes)
	var m := ShaderMaterial.new()
	m.shader = PAINTED_VC
	m.set_shader_parameter(&"noise_tex", PAD_NOISE)
	m.set_shader_parameter(&"crack_strength", 0.0)
	m.set_shader_parameter(&"rim_strength", 0.06)
	m.set_shader_parameter(&"rim_color", (PALETTE[kingdom] as Array)[2])
	var mi := MeshInstance3D.new()
	mi.name = "SitePad"
	mi.mesh = _pad_meshes[key]
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_instance_shader_parameter(&"ao_bottom", PAD_AO_BOTTOM)
	mi.set_instance_shader_parameter(&"ao_height", PAD_AO_HEIGHT)
	mi.visible = false
	# G-F round 3 leftovers (docs/art/gf_r3_leftovers.md): the pad's grass-free rectangle (pad space: min x, min z,
	# max x, max z). GroundDetail clears the 3D grass blades over it while the pad shows (box clear).
	mi.set_meta(&"_grass_clear_rect", pad_rect(half, stakes))
	return mi


## The pad's footprint in pad space (min x, min z, max x, max z): the sunk, pushed-out earth edge (<= half + 0.35),
## the stakes (half + 0.26) and the timber stack / kingdom pile by the +X side (_pad_mesh layout), plus a 0.1 margin.
static func pad_rect(half: float, stakes: bool) -> Vector4:
	var s: float = clampf(half / 3.3, 0.5, 1.0)
	var px: float = half + 0.45 * s + (0.2 if stakes else 0.1)
	var e: float = half + 0.35
	var z: float = maxf(e, 1.95 * s) + 0.1
	return Vector4(-e - 0.1, -z, maxf(e, px + 0.5 * s) + 0.1, z)


static func _pad_mesh(kingdom: StringName, half: float, stakes: bool) -> ArrayMesh:
	var pal: Array = PALETTE[kingdom]
	var ea: Color = pal[0]
	var eb: Color = pal[1]
	var flag: Color = pal[2]
	var wood: Color = pal[3]
	var pile: Color = pal[4]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s%d" % [kingdom, int(half * 100.0)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: Array[int] = [0]
	# Earth: a jittered grid, the edge ring sunk under the ground and pushed out unevenly (melts in, never a square).
	var cells: int = clampi(int(round(half * 2.0 / 0.55)), 4, 12)
	var step: float = half * 2.0 / float(cells)
	var w: int = cells + 1
	var hs: Array[float] = []
	var ps: Array[Vector3] = []
	var cs: Array[Color] = []
	for j: int in w:
		for i: int in w:
			var p := Vector3(-half + step * float(i), 0.0, -half + step * float(j))
			if i == 0 or j == 0 or i == cells or j == cells:
				p += Vector3(p.x, 0.0, p.z).normalized() * rng.randf_range(0.05, 0.35)
				p.y = -0.03
			else:
				p += Vector3(rng.randf_range(-0.12, 0.12) * step, 0.0, rng.randf_range(-0.12, 0.12) * step)
				p.y = rng.randf_range(0.035, 0.065)
			ps.append(p)
			hs.append(p.y)
			cs.append(ea.lerp(eb, rng.randf()))
	for j: int in w:
		for i: int in w:
			var l: float = hs[j * w + maxi(i - 1, 0)]
			var r: float = hs[j * w + mini(i + 1, cells)]
			var d: float = hs[maxi(j - 1, 0) * w + i]
			var u: float = hs[mini(j + 1, cells) * w + i]
			st.set_normal(Vector3((l - r) / (2.0 * step), 1.0, (d - u) / (2.0 * step)).normalized())
			st.set_color(cs[j * w + i])
			st.add_vertex(ps[j * w + i])
	for j: int in cells:
		for i: int in cells:
			var a: int = j * w + i
			for t: int in [a, a + w + 1, a + w, a, a + 1, a + w + 1]:   # clockwise seen from above (front faces)
				st.add_index(t)
	n[0] = w * w
	var top: float = 0.035   # lowest inner pad height: things laid on the pad start here
	var inner: float = half - 0.15
	match kingdom:
		&"fire":   # clay tiles laid in courses over one corner, a few loose ones
			var tw: float = 0.5
			var td: float = 0.26
			var rows: int = int(inner * 1.1 / td)
			for r: int in rows:
				var z: float = -inner + td * (float(r) + 0.5)
				var cnt: int = int((inner * 1.2 - float(r) * 0.12) / tw)
				for c: int in maxi(cnt, 0):
					var x: float = -inner + tw * (float(c) + 0.5) + (0.25 * tw if r % 2 == 1 else 0.0)
					_box(st, n, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.04, 0.04)).scaled_local(Vector3(tw - 0.04, 0.06,
						td - 0.035)), Vector3(x, top + 0.03, z)), flag.lerp(pile, rng.randf() * 0.4))
			for k: int in 5:
				var p := Vector3(rng.randf_range(0.6, inner), top + 0.03, rng.randf_range(0.5, inner))
				_box(st, n, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled_local(Vector3(tw - 0.04, 0.06, td - 0.035)), p),
					flag.lerp(pile, 0.5))
		&"ice":   # frosted flagstones over most of the pad, gaps between
			var nc: int = maxi(int(inner * 2.0 / clampf(inner * 2.0 / 4.0, 0.6, 1.0)), 2)
			var cs2: float = inner * 2.0 / float(nc)
			for i: int in nc:
				for j: int in nc:
					if rng.randf() < 0.3:
						continue
					var p := Vector3(-inner + cs2 * (float(i) + 0.5) + rng.randf_range(-0.08, 0.08), top + 0.035,
						-inner + cs2 * (float(j) + 0.5) + rng.randf_range(-0.08, 0.08))
					_box(st, n, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.2, 0.2)).scaled_local(Vector3(cs2 * rng.randf_range(0.7,
						0.88), 0.07, cs2 * rng.randf_range(0.66, 0.86))), p), flag.lerp(pile, rng.randf() * 0.6))
		&"nature":   # turned-earth furrows, a few moss tufts between them
			var gap: float = 0.55
			var nr: int = maxi(int(inner * 2.0 / gap), 2)
			for r: int in nr:
				var x: float = -inner + gap * (float(r) + 0.5)
				var fl: float = inner * 2.0 * rng.randf_range(0.7, 0.92)
				_box(st, n, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.05, 0.05)).scaled_local(Vector3(0.24, 0.08, fl)),
					Vector3(x, top + 0.04, rng.randf_range(-0.2, 0.2))), eb.lerp(ea, 0.3).darkened(0.05))
			for k: int in int(inner * 3.0):
				_box(st, n, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled_local(Vector3(0.22, 0.07, 0.18)),
					Vector3(rng.randf_range(-inner, inner), top + 0.035, rng.randf_range(-inner, inner))), flag)
		_:   # shadow: slate flags in loose courses, gaps, two shades
			var nc: int = maxi(int(inner * 2.0 / clampf(inner * 2.0 / 5.0, 0.5, 0.8)), 2)
			var cs2: float = inner * 2.0 / float(nc)
			for i: int in nc:
				for j: int in nc:
					if rng.randf() < 0.25:
						continue
					var p := Vector3(-inner + cs2 * (float(i) + 0.5) + rng.randf_range(-0.06, 0.06), top + 0.025,
						-inner + cs2 * (float(j) + 0.5) + rng.randf_range(-0.06, 0.06))
					_box(st, n, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.25, 0.25)).scaled_local(Vector3(cs2 * 0.86, 0.05,
						cs2 * rng.randf_range(0.6, 0.84))), p), flag.lerp(ea, rng.randf() * 0.5))
	if stakes:   # layout stakes with cords (Halls)
		var sr: float = half + 0.2
		var corners: Array[Vector3] = [Vector3(-sr, 0, -sr), Vector3(sr, 0, -sr), Vector3(sr, 0, sr), Vector3(-sr, 0, sr)]
		for k: int in 4:
			_box(st, n, Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.12, 0.85, 0.12)), corners[k] + Vector3(0, 0.37, 0)), wood)
			var q: Vector3 = corners[(k + 1) % 4]
			var along: Vector3 = q - corners[k]
			_box(st, n, Transform3D(Basis(Vector3.UP, atan2(-along.z, along.x)).scaled_local(Vector3(along.length(), 0.025, 0.025)),
				(corners[k] + q) * 0.5 + Vector3(0, 0.66, 0)), flag.lerp(wood, 0.3))
	# Timber stack + kingdom pile beside the +X side (outside the footprint; scaled to the site).
	var s: float = clampf(half / 3.3, 0.5, 1.0)
	var px: float = half + 0.45 * s + (0.2 if stakes else 0.1)
	var bw: float = 0.2 * s
	var bl: float = 2.0 * s
	for b: int in 3:   # three beams side by side on the ground (along Z)
		_box(st, n, Transform3D(Basis.IDENTITY.scaled_local(Vector3(bw, bw, bl)), Vector3(px + (float(b) - 1.0) * (bw + 0.02),
			bw * 0.5, -0.9 * s)), wood.darkened(0.06 * float(b)))
	for b: int in 2:   # two across them
		_box(st, n, Transform3D(Basis(Vector3.UP, 0.08).scaled_local(Vector3(bw * 3.6, bw, bw)), Vector3(px, bw * 1.5,
			-0.9 * s + (float(b) - 0.5) * bl * 0.6)), wood.lightened(0.05))
	var pz: float = 0.9 * s
	match kingdom:
		&"fire":   # a pallet of bricks, three courses
			_box(st, n, Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.9 * s, 0.08, 0.7 * s)), Vector3(px, 0.04, pz)), wood)
			var bs := Vector3(0.26 * s, 0.11 * s, 0.13 * s)
			for c: int in 3:
				for i: int in 3:
					for j: int in 5:
						if c == 2 and (i + j) % 3 == 0:
							continue
						_box(st, n, Transform3D(Basis.IDENTITY.scaled_local(bs * Vector3(0.95, 1.0, 0.95)), Vector3(px + (float(i) - 1.0)
							* bs.x, 0.08 + bs.y * (float(c) + 0.5), pz + (float(j) - 2.0) * bs.z)), pile.lerp(flag, rng.randf() * 0.3))
		&"ice":   # cut stone blocks, two on the ground, one on top
			var bk: float = 0.42 * s
			for i: int in 2:
				_box(st, n, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.1, 0.1)).scaled_local(Vector3(bk, bk, bk * 1.2)),
					Vector3(px + (float(i) - 0.5) * (bk + 0.04), bk * 0.5, pz)), pile.lerp(flag, 0.3 * float(i)))
			_box(st, n, Transform3D(Basis(Vector3.UP, 0.3).scaled_local(Vector3(bk, bk * 0.8, bk)), Vector3(px, bk * 1.4, pz)), flag)
		&"nature":   # a bundle of planks on two bearers
			for i: int in 2:
				_box(st, n, Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.7 * s, 0.1, 0.12)), Vector3(px, 0.05,
					pz + (float(i) - 0.5) * 0.9 * s)), wood.darkened(0.1))
			for c: int in 3:
				for i: int in 3:
					_box(st, n, Transform3D(Basis.IDENTITY.scaled_local(Vector3(0.2 * s, 0.06, 1.5 * s)), Vector3(px + (float(i) - 1.0)
						* 0.21 * s, 0.13 + 0.065 * float(c), pz)), pile.lerp(wood, rng.randf() * 0.5))
		_:   # shadow: a stack of cut slates
			for c: int in 6:
				_box(st, n, Transform3D(Basis(Vector3.UP, rng.randf_range(-0.12, 0.12)).scaled_local(Vector3(0.6 * s, 0.05,
					0.42 * s)), Vector3(px, 0.025 + 0.052 * float(c), pz)), pile.lerp(flag, rng.randf() * 0.5))
			_box(st, n, Transform3D(Basis(Vector3.UP, 0.5).scaled_local(Vector3(0.5 * s, 0.05, 0.36 * s)), Vector3(px + 0.1,
				0.025, pz + 0.7 * s)), pile)
	return st.commit()


## A box (the unit cube under `xf`) with flat normals and one vertex colour, clockwise faces (Godot front faces).
## `n[0]` = the next vertex index (advanced).
static func _box(st: SurfaceTool, n: Array[int], xf: Transform3D, col: Color) -> void:
	var nb: Basis = xf.basis.inverse().transposed()
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	for a: int in 3:
		for sgn: float in [1.0, -1.0]:
			var nn: Vector3 = axes[a] * sgn
			var u: Vector3 = axes[(a + 1) % 3]
			var v: Vector3 = axes[(a + 2) % 3]
			if sgn < 0.0:
				var tmp: Vector3 = u
				u = v
				v = tmp
			var c: Vector3 = nn * 0.5
			var wn: Vector3 = (nb * nn).normalized()
			for p: Vector3 in [c - u * 0.5 - v * 0.5, c + u * 0.5 - v * 0.5, c + u * 0.5 + v * 0.5, c - u * 0.5 + v * 0.5]:
				st.set_normal(wn)
				st.set_color(col)
				st.add_vertex(xf * p)
			var b: int = n[0]
			for t: int in [0, 2, 1, 0, 3, 2]:
				st.add_index(b + t)
			n[0] = b + 4

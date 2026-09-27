extends Node3D
## Cine-only spell / story effects for the prologue (tools/cine/fx/, owner: cine). Every look is a pure function of the
## effect's age: CinePreview calls `set_cine_age(age)` each frame and for every still, so stills, seek and Movie Maker
## recordings show the same picture. 0 lights: emissive, additive meshes (the set's glow makes them bloom).
## Used from a .cine: `at 0.4 vfx pillar scene=res://tools/cine/fx/fire_pillar.tscn at=vessa life=2.6`
## (`to=` = where a streak / fireball flies, `scale=`, `yaw=`).

@export_enum("streak", "pillar", "ring", "dome", "orbs", "burst") var kind: String = "streak"
@export var color: Color = Color(1.0, 0.45, 0.12)
@export var color2: Color = Color(1.0, 0.85, 0.5)
@export var size: float = 1.0
@export var height: float = 24.0
@export var life: float = 3.0
@export var energy: float = 5.0
## streak: seconds to fly from `at` to `to`
@export var travel: float = 1.2

var _target := Vector3.ZERO
var _has_target := false
var _origin := Vector3.ZERO
var _meshes: Array[MeshInstance3D] = []
var _mats: Array[StandardMaterial3D] = []
var _built := false


func set_cine_target(p: Vector3) -> void:
	_target = p
	_has_target = true


func _ready() -> void:
	_origin = global_position
	_build()
	set_cine_age(0.0)


func _mat(c: Color, e: float, add: bool = true, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	e *= 0.5   # stills 13:40: glow blew the wizards out at full energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r * e, c.g * e, c.b * e, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if add else BaseMaterial3D.BLEND_MODE_MIX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	m.disable_receive_shadows = true
	_mats.append(m)
	return m


func _add(mesh: Mesh, m: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.top_level = true
	add_child(mi)
	_meshes.append(mi)
	return mi


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 24
	s.rings = 12
	return s


func _build() -> void:
	if _built:
		return
	_built = true
	# the meshes are top_level (posed in world space): the node's scale becomes the effect's size
	var sk := scale.x
	if absf(sk - 1.0) > 0.001:
		size *= sk
		height *= sk
	match kind:
		"streak":
			# head (hot core + halo) and a 14-bead tail
			_add(_sphere(0.55 * size), _mat(color2, energy * 1.4))
			_add(_sphere(1.1 * size), _mat(color, energy * 0.6, true, 0.55))
			for i: int in 14:
				var k := 1.0 - float(i) / 14.0
				_add(_sphere(0.8 * size * (0.35 + 0.65 * k)), _mat(color, energy * 0.5 * k, true, 0.5 * k))
		"pillar":
			var outer := CylinderMesh.new()
			outer.top_radius = 1.5 * size
			outer.bottom_radius = 2.2 * size
			outer.height = 1.0
			outer.radial_segments = 24
			outer.cap_top = false
			outer.cap_bottom = false
			_add(outer, _mat(color, energy * 0.45, true, 0.55))
			var core := CylinderMesh.new()
			core.top_radius = 0.6 * size
			core.bottom_radius = 0.9 * size
			core.height = 1.0
			core.radial_segments = 16
			_add(core, _mat(color2, energy * 0.8, true, 0.7))
			_add(_sphere(2.6 * size), _mat(color, energy * 0.5, true, 0.6))      # base flare
			for i2: int in 6:
				_add(_sphere(0.5 * size), _mat(color2, energy, true, 0.8))       # rising embers
		"ring":
			var tor := TorusMesh.new()
			tor.inner_radius = 0.92
			tor.outer_radius = 1.0
			tor.rings = 48
			tor.ring_segments = 8
			_add(tor, _mat(color2, energy, true, 0.9))
			var disc := CylinderMesh.new()
			disc.top_radius = 1.0
			disc.bottom_radius = 1.0
			disc.height = 0.04
			disc.radial_segments = 48
			_add(disc, _mat(color, energy * 0.35, true, 0.45))
		"dome":
			_add(_sphere(1.0), _mat(color, 1.0, false, 0.72))
			_add(_sphere(1.04), _mat(color2, energy * 0.5, true, 0.35))
			for i3: int in 8:
				_add(_sphere(0.35), _mat(color2, energy, true, 0.8))
		"orbs":
			var cols := [Color(1.0, 0.3, 0.1), Color(0.7, 0.3, 1.0), Color(0.35, 0.7, 1.0), Color(0.35, 1.0, 0.35)]
			for c: Color in cols:
				_add(_sphere(0.14 * size), _mat(c, energy * 1.2))
				_add(_sphere(0.34 * size), _mat(c, energy * 0.4, true, 0.5))
		"burst":
			_add(_sphere(1.0), _mat(color2, energy, true, 0.9))
			var tor2 := TorusMesh.new()
			tor2.inner_radius = 0.9
			tor2.outer_radius = 1.0
			_add(tor2, _mat(color, energy * 0.8, true, 0.8))
			for i4: int in 12:
				_add(_sphere(0.25 * size), _mat(color2, energy, true, 0.9))


static func _hash(i: int, salt: int) -> float:
	# deterministic 0..1 per index (no randf)
	return fposmod(sin(float(i * 127 + salt * 311) * 12.9898) * 43758.5453, 1.0)


func _fade(age: float, fin: float, fout: float) -> float:
	var a := clampf(age / maxf(0.01, fin), 0.0, 1.0)
	var b := clampf((life - age) / maxf(0.01, fout), 0.0, 1.0)
	return a * b


func _alpha(i: int, a: float) -> void:
	var m := _mats[i]
	var c := m.albedo_color
	m.albedo_color = Color(c.r, c.g, c.b, a)


## Poses the effect `age` seconds after it started.
func set_cine_age(age: float) -> void:
	if not _built:
		_origin = global_position
		_build()
	if is_inside_tree():
		_origin = global_position
	var o := _origin
	var basis_y := Basis(Vector3.UP, rotation.y)
	var vis := age >= 0.0 and age <= life
	for mi: MeshInstance3D in _meshes:
		mi.visible = vis
	if not vis:
		return
	var f := _fade(age, 0.15, 0.5)
	match kind:
		"streak":
			var to := _target if _has_target else o + Vector3(0, height, 0)
			var path := func(k: float) -> Vector3:
				var kk := clampf(k, 0.0, 1.0)
				var p := o.lerp(to, 1.0 - pow(1.0 - kk, 2.0))
				return p + Vector3(0, sin(kk * PI) * 0.12 * o.distance_to(to), 0)
			var k0 := age / maxf(0.05, travel)
			var head: Vector3 = path.call(k0)
			var hold := clampf((age - travel) / 0.4, 0.0, 1.0)   # after arrival: flash + fade
			_meshes[0].global_position = head
			_meshes[1].global_position = head
			_meshes[0].scale = Vector3.ONE * (1.0 + hold * 1.5)
			_meshes[1].scale = Vector3.ONE * (1.0 + hold * 3.0 + 0.15 * sin(age * 31.0))
			_alpha(0, f)
			_alpha(1, 0.55 * f * (1.0 - hold * 0.6))
			for i: int in 14:
				var kt := k0 - float(i + 1) * 0.035
				var mi2 := _meshes[2 + i]
				mi2.visible = kt > 0.0
				mi2.global_position = path.call(kt)
				_alpha(2 + i, 0.5 * (1.0 - float(i) / 14.0) * f * (1.0 - hold))
		"pillar":
			var grow := clampf(age / 0.45, 0.0, 1.0)
			grow = 1.0 - pow(1.0 - grow, 3.0)
			var h := height * grow
			var flick := 1.0 + 0.08 * sin(age * 23.0) + 0.05 * sin(age * 41.0 + 1.3)
			for j: int in 2:
				var mj := _meshes[j]
				mj.global_transform = Transform3D(basis_y.orthonormalized().scaled(Vector3(flick, h, flick)), o + Vector3(0, h * 0.5, 0))
			_alpha(0, 0.55 * f)
			_alpha(1, 0.7 * f)
			var fl := clampf(1.0 - age / 1.2, 0.25, 1.0)
			_meshes[2].global_position = o + Vector3(0, 0.8 * size, 0)
			_meshes[2].scale = Vector3.ONE * (0.6 + 0.8 * fl) * flick
			_alpha(2, 0.6 * f * fl)
			for e: int in 6:
				var ph := fposmod(age * (0.35 + 0.1 * _hash(e, 1)) + _hash(e, 2), 1.0)
				var ang := _hash(e, 3) * TAU + age * 1.5
				var r := (1.6 + 1.5 * _hash(e, 4)) * size
				_meshes[3 + e].global_position = o + Vector3(cos(ang) * r, ph * h, sin(ang) * r)
				_alpha(3 + e, 0.8 * f * (1.0 - ph))
		"ring":
			var k2 := clampf(age / maxf(0.1, life * 0.7), 0.0, 1.0)
			k2 = 1.0 - pow(1.0 - k2, 2.0)
			var r2 := maxf(0.05, size * k2)
			_meshes[0].global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(r2, 0.6 + r2 * 0.02, r2)), o + Vector3(0, 0.15, 0))
			_meshes[1].global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(r2, 1.0, r2)), o + Vector3(0, 0.06, 0))
			_alpha(0, 0.9 * f * (1.0 - 0.5 * k2))
			_alpha(1, 0.45 * f)
		"dome":
			var k3 := clampf(age / maxf(0.1, life * 0.5), 0.0, 1.0)
			k3 = 1.0 - pow(1.0 - k3, 3.0)
			var r3 := maxf(0.05, size * k3)
			for j2: int in 2:
				_meshes[j2].global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(r3, r3 * 0.7, r3)), o)
			_alpha(0, 0.72 * f)
			_alpha(1, 0.35 * f)
			for w: int in 8:
				var ang2 := float(w) / 8.0 * TAU + age * 0.8
				var ph2 := fposmod(age * 0.5 + _hash(w, 5), 1.0)
				_meshes[2 + w].global_position = o + Vector3(cos(ang2) * r3 * 0.9, ph2 * r3 * 0.7, sin(ang2) * r3 * 0.9)
				_alpha(2 + w, 0.8 * f * (1.0 - ph2))
		"orbs":
			for q: int in 4:
				var ang3 := float(q) / 4.0 * TAU + age * 1.6
				var p3 := o + Vector3(cos(ang3) * 0.55 * size, 0.18 * size * sin(age * 2.0 + q), sin(ang3) * 0.55 * size)
				var on := clampf((age - float(q) * 0.35 * (life / 6.0)) / 0.3, 0.0, 1.0) if life > 4.0 else 1.0
				_meshes[q * 2].global_position = p3
				_meshes[q * 2 + 1].global_position = p3
				_meshes[q * 2].scale = Vector3.ONE * maxf(0.01, on)
				_meshes[q * 2 + 1].scale = Vector3.ONE * maxf(0.01, on) * (1.0 + 0.1 * sin(age * 17.0 + q))
				_alpha(q * 2, f * on)
				_alpha(q * 2 + 1, 0.5 * f * on)
		"burst":
			var k4 := clampf(age / 0.6, 0.0, 1.0)
			k4 = 1.0 - pow(1.0 - k4, 2.0)
			_meshes[0].global_position = o
			_meshes[0].scale = Vector3.ONE * size * 0.5 * (0.3 + 0.7 * k4)
			# a long-lived burst (life > 4 s, e.g. the blossom) opens and stays; a short one pops and fades
			var keep := 0.6 if life > 4.0 else 0.0
			_alpha(0, 0.7 * f * maxf(1.0 - k4, keep))
			if keep > 0.0:
				_meshes[0].scale = Vector3.ONE * size * (0.6 + 0.4 * k4 + 0.05 * sin(age * 3.0))
			_meshes[1].global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size * (0.4 + 2.2 * k4)), o)
			_alpha(1, 0.8 * f * (1.0 - k4))
			for s: int in 12:
				var dir := Vector3(_hash(s, 7) - 0.5, _hash(s, 8) * 0.8, _hash(s, 9) - 0.5).normalized()
				_meshes[2 + s].global_position = o + dir * size * 3.0 * k4
				_alpha(2 + s, 0.9 * f * (1.0 - k4))

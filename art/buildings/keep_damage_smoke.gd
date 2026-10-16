class_name KeepDamageSmoke
extends RefCounted
## G-F round 3 item 9 (docs/art/gf_review3.md, docs/art/gf_r3_fire_keep.md): the keeps' damage smoke (Smoke1 / Smoke2,
## on below 50 % HP) was invisible in play: 2.6 m puffs at value 0.10-0.20 against the dark keep walls, 3.5 s lives.
## tune() makes each one a soft grey / dark column: ~3.4 m alpha-blended puffs (the keep's own MIX quad, resized with
## MoteCap.sized: no new material), 5 s lives rising ~8 m, a ramp at value 0.3-0.72 (MoteCap.VALUE_CAP) and alpha
## <= 0.55, the near-camera fade on the quad's material. Low keeps LOW_RATIO of the puffs, so its fill cost stays at
## the old one ((3.4 / 2.6)^2 x 0.55 ~ 0.94).
## Fire, Dusk (Shadow) and Nature keeps call it at the end of _ready (the Ice keep has its own smoke).

const SIZE := 3.4          ## puff quad size (m)
const LIFETIME := 5.0      ## s
const VEL_MIN := 1.45      ## m/s (x LIFETIME = the column's rise)
const VEL_MAX := 1.9
const SCALE_FROM := 0.35   ## puff size at birth (x SIZE), grows to 1
const LOW_RATIO := 0.55    ## share of the puffs at Low
const ALPHA := 0.5

## Switch (shots compare against the old smoke with it off; the game never turns it off).
static var enabled := true
static var _pms: Dictionary = {}   ## "<process material id>|<low>|<high>" -> the tuned copy (shared per keep scene)


## Turns `p` into a damage column: puffs from `low` (birth) to `high` (top), both capped to MoteCap.VALUE_CAP.
## Idempotent; the emitting flag stays the keep's business.
static func tune(p: GPUParticles3D, low: Color, high: Color, alpha: float = ALPHA) -> void:
	if p == null or not enabled:
		return
	var src := p.process_material as ParticleProcessMaterial
	if src == null:
		return
	var key: String = "%d|%s|%s" % [src.get_instance_id(), low.to_html(), high.to_html()]
	if src.has_meta(&"keep_damage_smoke"):
		key = ""   # already a tuned copy
	if key != "":
		if not _pms.has(key):
			_pms[key] = _tuned(src, low, high, alpha)
		p.process_material = _pms[key]
	p.lifetime = LIFETIME
	var mesh: Mesh = p.draw_pass_1
	if not (mesh != null and mesh.has_meta(&"keep_damage_smoke")):
		mesh = MoteCap.sized(mesh, SIZE)
		if mesh != null:
			mesh.set_meta(&"keep_damage_smoke", true)
		p.draw_pass_1 = mesh
	MoteCap.fade(MoteCap.draw_material(p))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-7.0, -3.0, -7.0), Vector3(14.0, 17.0, 14.0))
	p.amount_ratio = LOW_RATIO if GameSettings.effective_graphics_quality() <= 0 else 1.0


static func _tuned(src: ParticleProcessMaterial, low: Color, high: Color, alpha: float) -> ParticleProcessMaterial:
	var pm := src.duplicate() as ParticleProcessMaterial
	pm.set_meta(&"keep_damage_smoke", true)
	pm.direction = Vector3.UP
	pm.spread = 9.0
	pm.initial_velocity_min = VEL_MIN
	pm.initial_velocity_max = VEL_MAX
	pm.gravity = Vector3(0.22, 0.05, 0.08)   # a slight lean, still rising
	pm.damping_min = 0.0
	pm.damping_max = 0.0
	pm.scale_min = 0.8
	pm.scale_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, SCALE_FROM))
	curve.add_point(Vector2(0.45, 0.8))
	curve.add_point(Vector2(1.0, 1.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var lo: Color = MoteCap.cap(low)
	var hi: Color = MoteCap.cap(high)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.12, 0.6, 1.0])
	g.colors = PackedColorArray([Color(lo, 0.0), Color(lo, alpha), Color(lo.lerp(hi, 0.6), alpha * 0.75),
		Color(hi, 0.0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = g
	pm.color_ramp = ramp
	pm.color = Color.WHITE
	pm.angle_min = 0.0
	pm.angle_max = 360.0
	return pm

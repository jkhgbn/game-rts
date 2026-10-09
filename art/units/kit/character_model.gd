class_name CharacterModel
extends Node3D
## Shared root script of every character model (art-units.md 2.3, 6, 7, 8). How to build a unit: kit/README.md.
## Local +Z is the face / weapon side. The model never moves its own root; it animates the pivots below `Root`.
## Pivots (all optional, found once by path): Root, Root/Hips, Root/Hips/LegL, Root/Hips/LegR, Root/Chest,
## Root/Chest/Head, Root/Chest/ArmL, Root/Chest/ArmR, Root/Mount, Root/Mount/LegFL|LegFR|LegBL|LegBR, Root/Mount/Head,
## plus Shadow (blob, never animated) and Fx. All procedural in one _process; no Tween, no AnimationPlayer.
## Champion classes (task 11.V1, skills-rework.md 5): `set_weapon_class(class_id)` merges the shared class weapon
## (art/units/champions/weapons/) into the grip pivots' merged meshes and drops the parts tagged as archetype
## weapon; attack styles spear_thrust / sword_slash / great_cleave / staff_bolt; `play_cast` routes the 12 class
## skill ids to `_pose_class_skill` (generic poses here). Convention for models: kit/README.md "Champion weapons".
## Seated rider (task 13.V1b): `set_seated(on, mount)`, `play_mount`, `play_dismount`, `play_thrown` put any model on a
## MountModel's Seat (kit/README.md "Seated rider"); off by default, one bool check per frame when not seated.

signal death_finished
## Seated rider (13.V1b): a play_dismount() hop or a play_thrown() tumble has landed; the model stands on its own
## origin again (is_seated() is false from now on). Not emitted by set_seated(false) (instant).
signal dismount_finished

enum { P_ROOT, P_HIPS, P_LEG_L, P_LEG_R, P_CHEST, P_HEAD, P_ARM_L, P_ARM_R, P_MOUNT, P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR, P_MOUNT_HEAD }
const PIVOT_PATHS: Array[String] = ["Root", "Root/Hips", "Root/Hips/LegL", "Root/Hips/LegR", "Root/Chest",
	"Root/Chest/Head", "Root/Chest/ArmL", "Root/Chest/ArmR", "Root/Mount", "Root/Mount/LegFL", "Root/Mount/LegFR",
	"Root/Mount/LegBL", "Root/Mount/LegBR", "Root/Mount/Head"]
const NP: int = 14

const PAINTED_SHADER: Shader = preload("res://art/units/kit/unit_painted.gdshader")
const GLOW_SHADER: Shader = preload("res://art/units/kit/unit_glow.gdshader")
const BANNER_SHADER: Shader = preload("res://art/shaders/banner.gdshader")
const MAT_DIR := "res://art/units/kit/materials/"
const DEG := PI / 180.0
const HIT_LEN := 0.22
const DEATH_LEN := 1.0
const LEVEL_LEN := 0.4
## Level-up flash (A.17): a saturated gold at a moderate peak. The shaders add flash_color * hit_flash * 2 to
## EMISSION, so a pale gold at 1.0 blew every unit out to white; this reads as a warm golden pulse instead.
const GOLD := Vector3(1.0, 0.58, 0.08)
const LEVEL_FLASH_PEAK := 0.42
const LEVEL_FLASH_RISE := 0.05
const LEVEL_FLASH_FADE := 0.30
const WHITE := Vector3(1.0, 1.0, 1.0)
## Instance-uniform slot map of EVERY unit shader (task A.16, kit/README.md "Instance uniform slots"). Each shader
## declares these names with `: instance_index(N)`. Slot 0 stays free for banner.gdshader's implicit `phase` (capes).
const INSTANCE_SLOTS: Dictionary = {
	"ao_bottom": 1, "ao_height": 2, "hit_flash": 3, "flash_color": 4, "glow_boost": 5, "blob_color": 6,
}
## Champion class weapons (11.V1). The weapon kit is a plain static script (no nodes, no class_name use here).
const WEAPON_KIT := preload("res://art/units/champions/weapons/champion_weapon_kit.gd")
## The weapon's scale-in when a class is taken (skills-rework.md 5).
const WEAPON_POP_LEN := 0.3
## glow_boost of the class weapon's crystal at rest (energy 1.5 x 1.6 = a 2.4 halo; the pose flares add up to +2.2).
const WEAPON_GLOW_BASE := 1.6
## The 12 class skill ids (skills-rework.md 4.2) -> their class. play_cast routes them to _pose_class_skill.
const CLASS_SKILL_IDS: Dictionary = {
	&"lunge": &"spear", &"hobbling_javelin": &"spear", &"skewer": &"spear",
	&"riposte": &"sword_shield", &"second_wind": &"sword_shield", &"shield_throw": &"sword_shield",
	&"cleave": &"two_hand", &"crushing_blow": &"two_hand", &"whirlwind": &"two_hand",
	&"arc_bolt": &"wizard", &"slipstep": &"wizard", &"starfall": &"wizard",
}
## Weapon slot -> the pivot its pieces merge into.
const SLOT_PIVOT: Dictionary = {&"hand_r": P_ARM_R, &"hand_l": P_ARM_L, &"back": P_CHEST}
## Seated rider (13.V1b, cavalry-mounts.md 6.2 / 10): hop-on / hop-off length and the thrown-off tumble (s).
const MOUNT_HOP_LEN := 0.3
const THROWN_LEN := 0.5

## Visual top of the head (m). Sets ao_height on every painted part and the death sink depth.
@export var body_height: float = 1.6
## melee_swing, dual_slash, great_swing, lance_charge, bow_draw, caster_fire, sling_throw, bite, wizard_bolt, worker_pick;
## champion classes (set by set_weapon_class): spear_thrust, sword_slash, great_cleave, staff_bolt
@export var attack_style: StringName = &"melee_swing"
## Ranged release frame (s), read once by Unit._build_visual; <= 0.15. 0 = melee (damage at the trigger).
@export_range(0.0, 0.15, 0.01) var attack_windup: float = 0.0
## fall (Fire), sink (Shadow), crumble (warden)
@export var death_style: StringName = &"fall"
## Seconds per stride at rate 1.0 (bipeds 0.55, hound 0.40, rider 0.45, warden 0.80).
@export var stride_time: float = 0.55
## Speed (m/s) that plays the walk at rate 1.0. Gameplay may overwrite it with the type's base move_speed at spawn.
@export var stride_speed: float = 3.0
@export var idle_period: float = 3.0
@export var is_quadruped: bool = false
## Mount units: gallop (FL+FR / BL+BR) from this stride rate.
@export var gallop_rate: float = 1.3
## The colour this scene's *_cloth / *_cape materials already have (set_team_color with it = the authored materials).
@export var kingdom_color: Color = Color(0.85, 0.30, 0.12)
## Multiplies the attack-swing angles (warden 1.15).
@export var swing_scale: float = 1.0
## Leg swing amplitude in the walk (deg). Warden 18.
@export var leg_swing_deg: float = 28.0
## Walk bounce height (m).
@export var walk_bounce: float = 0.04
## Hit flinch pushes Root back instead of bending the chest (hound, mount, warden).
@export var flinch_push: bool = false
@export_group("Riding (13.V1b)")
## Seated rider (set_seated): offset (m) of this model's hip point from the mount's Seat, in the seat frame (+Y up,
## +Z forward). Per-model tweak for robes, big boots, crowns (13.V11 / 13.V12).
@export var seat_offset: Vector3 = Vector3.ZERO
## Legs astride: sideways splay (deg); 0 = measured from the mount's body mesh (clears its barrel).
@export var seat_leg_splay_deg: float = 0.0
## Legs astride: forward swing (deg) of both legs.
@export var seat_leg_forward_deg: float = 28.0
@export_group("")

# --- static caches (per unit type, never per unit) ---
static var _merged: Dictionary = {}       # "type|pivot" -> {"mesh": ArrayMesh, "glow": bool, "params": {name: value}} ({} = nothing to merge)
static var _shader_iu: Dictionary = {}    # Shader -> PackedStringArray of its instance uniform names (includes resolved)
static var _team_mats: Dictionary = {}    # "path|colour" -> Material
static var _mesh_cache: Dictionary = {}   # primitive key -> Mesh
static var _mat_cache: Dictionary = {}    # palette name -> Material
static var _wk_src: Dictionary = {}       # "type|pivot" -> {"common": Mesh|null, "tagged": [[mesh, xf, mats, classes]]} (tagged pivots only)
static var _wk_variants: Dictionary = {}  # "type|pivot index|class|pieces" -> Mesh or null (class variants of a merged pivot)
static var _wk_grips: Dictionary = {}     # "type|slot" -> Transform3D (auto grips)

var _piv: Array[Node3D] = []
var _pidx: PackedInt32Array = PackedInt32Array()   # indices of the pivots that exist
var _rest_pos := PackedVector3Array()
var _rest_rot := PackedVector3Array()
var _off_pos := PackedVector3Array()
var _off_rot := PackedVector3Array()
var _last_pos := PackedVector3Array()
var _last_rot := PackedVector3Array()
var _root_scale: Vector3 = Vector3.ONE
var _last_root_scale: Vector3 = Vector3.ONE
var _type_key: String = ""
var _ready_done: bool = false

var _shadow: GeometryInstance3D
var _merged_nodes: Dictionary = {}                 # pivot index -> MeshInstance3D
var _flash_hit_targets: Array[GeometryInstance3D] = []
var _flash_all_targets: Array[GeometryInstance3D] = []
var _glow_nodes: Array[GeometryInstance3D] = []
var _carry_nodes: Array[Node3D] = []
var _trim_nodes: Array[Node3D] = []
var _death_fx: Array[GPUParticles3D] = []
var _loop_fx: Array[GPUParticles3D] = []

# --- state ---
var _t: float = 0.0
var _phase_off: float = 0.0
var _speed: float = 0.0
var _walk_w: float = 0.0
var _walk_p: float = 0.0
var _acc: float = 0.0
var _tier: int = 0
var _tier_timer: float = 0.0
var _frozen: bool = false
var _force_write: bool = true
## Perf pass 2026-10-09: a model outside the game camera's view (+ OFFSCREEN_MARGIN m) stops animating like a tier-2
## one, but keeps its pose and walk phase (nobody sees it) and resumes seamlessly. On-screen models re-check every
## OFFSCREEN_CHECK s, frozen ones every frame (no frozen pose when the camera jumps). Only in the root viewport (the
## game); portraits, the menu diorama and labs in SubViewports never use it. Fix 2026-10-09: opt-in, only a model a Unit
## built (Unit._build_model sets offscreen_freeze); bare models in tests / labs / scenes animate as before.
const OFFSCREEN_MARGIN := 6.0
const OFFSCREEN_CHECK := 0.1
static var _fr_frame: int = -1
static var _fr_planes: Array[Plane] = []
## Set by Unit._build_model: this model may pause while off-camera (see OFFSCREEN_MARGIN). Default off.
var offscreen_freeze: bool = false
var _offscreen: bool = false
var _off_timer: float = 0.0

var _action: StringName = &""   # &"attack", &"cast", &"mine"
var _action_t: float = 0.0
var _cast_id: StringName = &""
var _mine_left: int = 0
var _hit_t: float = 99.0
var _last_hit_time: float = -1.0
var _level_t: float = 99.0
var _level_at: float = -99.0   # _t at the last play_level_up (level_up_age(); _level_t stops at LEVEL_LEN)
var _dead: bool = false
var _death_t: float = 0.0
var _death_emitted: bool = false
var _glows_off: bool = false
var _flash_v: float = 0.0
var _flash_gold: bool = false
## Hit flash look per model (in-game grade pass 2026-09-30): colour, strength (x the 0-1 flash curve) and fade time.
## The kit default is a white flash; Ice models use a half-strength, half-length cyan one (a white flash on pale ice
## armour read as a white puff the size of the unit mid-fight). The level-up gold flash is unchanged.
var hit_flash_color: Vector3 = WHITE
var hit_flash_scale: float = 1.0
var hit_flash_time: float = 0.12
var _carrying: bool = false
var _vet_boost: float = 1.0
var _haste: bool = false
var _glow_written: float = -1.0
var _team_pending: Variant = null
# --- champion class weapon (11.V1)
var _wk_class: StringName = &""
var _wk_pending: Variant = null
var _wk_arch_saved: bool = false
var _wk_arch_style: StringName = &""
var _wk_arch_windup: float = 0.0
var _wk_pieces: Array[StringName] = []        # pieces of the current class (after _weapon_pieces)
var _wk_applied: Dictionary = {}              # pivot index -> applied variant key ("base" = the archetype mesh)
var _wk_mask_applied: int = -1                # visible-piece bit mask the merged meshes show
var _wk_req: Dictionary = {}                  # this frame's pose requests: piece -> bool (show / hide)
var _wk_class_nodes: Array[Node3D] = []       # keep_separate nodes tagged weapon_classes
var _wk_pop_t: float = 99.0
var _wk_pop: Array = []                       # [[MeshInstance3D, Transform3D base, piece], ...] during the scale-in
var _wk_flare: float = 0.0
var _wk_flare_written: float = -1.0
var _wk_glow_added: Array[GeometryInstance3D] = []   # merged nodes whose only glow is the class weapon's
var _wk_team: Variant = null                  # colour of the last recolour (the weapon's team cloth follows it)
# --- seated rider (13.V1b). Everything below is idle while _rd_mount is null (the only check on the hot path).
static var _rd_splay_cache: Dictionary = {}   # "mesh id|hip x|leg len" -> measured leg splay (deg)
var _par_id: int = 0                          # tier-1 half-rate parity id (own id; the mount's while seated)
var _rd_on: bool = false                      # seated (hops included): the only check on the hot path
var _rd_mount: Node3D = null                  # the mount while seated (may be freed during a hop-off / thrown)
var _rd_act: StringName = &""                 # &"", &"mount", &"dismount", &"thrown"
var _rd_t: float = 0.0
var _rd_busy: bool = false
var _rd_pending: Variant = null               # [on, mount, act] before _ready
var _rd_prio: int = 0                         # process_priority before seating
var _rd_has_gait: bool = false
var _rd_has_seat: bool = false
var _rd_splay: float = 30.0                   # deg
var _rd_arm_w: float = 1.0                    # reins weight (drops while an attack / cast poses the arms)
var _rd_side: float = 1.0                     # thrown to +X (1) or -X (-1)
var _rd_seat_pitch: float = 0.0               # the seat's pitch this frame (deg, + = nose down)
var _rd_last_sf: Transform3D = Transform3D.IDENTITY   # last seat frame (a hop-off / thrown finishes on it)
# --- dances (play_clip, 2026-09-27 ideas-inbox "dance" rows). Idle while _dn_clip is &"" and _dn_w is 0 (two checks
# on the fast path, nothing else runs). Private members start with _dn_.
var _dn_clip: StringName = &""                # the looping clip playing (&"" = none / fading out)
var _dn_last: StringName = &""                # the clip being faded out after stop_clip()
var _dn_pending: StringName = &""             # play_clip before _ready
var _dn_t: float = 0.0                        # seconds since the clip started
var _dn_w: float = 0.0                        # blend weight 0-1 (DANCE_BLEND in / out)
var _dn_style: int = -1                       # 0 neutral, 1 fire, 2 ice, 3 nature, 4 shadow (lazy, from the script path)
var _dn_var: int = 0                          # dance_random variant 0-2
var _dn_count: int = 0
var _dn_leg: float = 0.7                      # hip height (m): the dips keep the feet on the ground with it
var _dn_tempo: float = 1.6                    # beats per second (style x per-instance jitter)
var _dn_ph: float = 0.0                       # per-instance phase (beats): crowds never move in sync
var _dn_sc: float = 1.0                       # body_height / 1.6


# ================================================================ lifecycle

func _ready() -> void:
	_type_key = scene_file_path if scene_file_path != "" else String(get_script().resource_path)
	_par_id = get_instance_id()
	_phase_off = float(hash(get_instance_id()) % 100) / 100.0 * idle_period
	_tier_timer = float(hash(get_instance_id()) % 50) / 100.0
	_piv.resize(NP)
	for a: PackedVector3Array in [_rest_pos, _rest_rot, _off_pos, _off_rot, _last_pos, _last_rot]:
		a.resize(NP)
	for i: int in NP:
		var n := get_node_or_null(PIVOT_PATHS[i]) as Node3D
		_piv[i] = n
		if n:
			_pidx.append(i)
			_rest_pos[i] = n.position
			_rest_rot[i] = n.rotation
	_shadow = get_node_or_null("Shadow") as GeometryInstance3D
	_build_parts()
	for i: int in _pidx:
		_merge_pivot(i)
	_collect(self)
	for gi: GeometryInstance3D in _flash_all_targets:
		gi.set_instance_shader_parameter(&"ao_height", body_height)
	for i: int in [P_CHEST, P_HEAD, P_ARM_R]:
		var m: MeshInstance3D = _merged_nodes.get(i)
		if m:
			_flash_hit_targets.append(m)
	_ready_done = true
	for c: Node3D in _carry_nodes:
		c.visible = _carrying
	_apply_glow(true)
	if _team_pending != null:
		set_team_color(_team_pending)
	_after_ready()
	if _wk_pending != null:
		set_weapon_class(_wk_pending, false)
	if _rd_pending != null:
		_rd_apply_pending()
	if _dn_pending != &"":
		var c := _dn_pending
		_dn_pending = &""
		play_clip(c)


## Subclass hook: build parts in code with add_part() (called every instance before the merge; add_part skips
## static parts once the type is cached). Scenes authored in the editor can leave it empty.
func _build_parts() -> void:
	pass


## Subclass hook: grab references to keep_separate parts (orb, light, flames...).
func _after_ready() -> void:
	pass


# ================================================================ hooks (art-units.md 6.1)

## Kingdom colour (not the green / red ring colour). Any number of calls in any order (mid-game recolour, mirror
## matches); the scene's own kingdom_color restores the authored cloth. A no-op while nothing was recoloured yet.
func set_team_color(c: Color) -> void:
	if not _ready_done:
		_team_pending = c
		return
	_team_pending = null
	_apply_team_color(c)


## The recolour behind set_team_color (after _ready). Subclasses whose set_team_color skips the base (a warden that
## still wears cloth) call it directly. Cloth surfaces take the kit's cached per-colour variants, nothing is created
## per call.
func _apply_team_color(c: Color) -> void:
	var tc: Variant = null if _is_kingdom_color(c) else c
	if tc == null and _wk_team == null:
		return   # still the authored colours (the common spawn-time call)
	_wk_team = tc
	_recolor(self, tc)


## True when c is this scene's own kingdom_color (within 0.01 per channel).
func _is_kingdom_color(c: Color) -> bool:
	return absf(c.r - kingdom_color.r) <= 0.01 and absf(c.g - kingdom_color.g) <= 0.01 \
		and absf(c.b - kingdom_color.b) <= 0.01


func set_moving(speed: float) -> void:
	_speed = speed
	if speed >= 0.3 and _action == &"mine":
		_action = &""


func play_attack() -> void:
	if _dead:
		return
	_action = &"attack"
	_action_t = 0.0
	_dn_clip = &""
	_on_action_event(&"attack_start")


func play_cast(spell_id: StringName) -> void:
	if _dead:
		return
	_action = &"cast"
	_dn_clip = &""
	_cast_id = spell_id
	_action_t = 0.0
	_on_action_event(&"cast_start")


func play_hit() -> void:
	if _dead or _t - _last_hit_time < 0.15:
		return
	_last_hit_time = _t
	_hit_t = 0.0
	_flash_gold = false


func play_death() -> void:
	if _dead:
		return
	_dead = true
	_death_t = 0.0
	_death_emitted = false
	_action = &""
	_dn_clip = &""
	_hit_t = 99.0
	_speed = 0.0
	_wk_end_pop()
	if _rd_on:
		_rd_on_death()
	set_process(true)


func play_level_up() -> void:
	if _dead:
		return
	_level_t = 0.0
	_level_at = _t
	_on_action_event(&"level_up")


## Seconds since the last play_level_up (keeps running, unlike the 0.4 s pose timer; huge before the first one and
## after a revive). The faces smile while it is below FaceRig.SMILE_LEN.
func level_up_age() -> float:
	return _t - _level_at


## The model's distance tier (0 < 30 m, 1 < 45 m, 2 beyond: frozen pose). Read by FaceRig.auto.
func face_tier() -> int:
	return _tier


## The face reaction of the model's state (FaceRig.auto): dying = worried, level-up (FaceRig.SMILE_LEN s) = smile,
## a cast = shout (casts whose id starts with "_idle" / "idle" are fidgets: &""), an attack = fierce, else &"".
func face_mood() -> StringName:
	if _dead:
		return &"worried"
	if level_up_age() < FaceRig.SMILE_LEN:
		return &"smile"
	if _action == &"cast":
		var cid := String(_cast_id)
		return &"" if cid.begins_with("_idle") or cid.begins_with("idle") else &"shout"
	if _action == &"attack":
		return &"fierce"
	return &""


func set_veterancy(level: int) -> void:
	_vet_boost = [1.0, 1.0, 1.25, 1.5, 1.8][clampi(level, 0, 4)]
	for n: Node3D in _trim_nodes:
		n.visible = level >= 4
	_apply_glow(false)


func set_carrying(on: bool) -> void:
	_carrying = on
	for c: Node3D in _carry_nodes:
		c.visible = on


func play_mine() -> void:
	if _dead:
		return
	_action = &"mine"
	_action_t = 0.0
	_dn_clip = &""
	_mine_left = 4


## Returns true for the ids the model shows itself (haste, shroud); false keeps the placeholder mark.
func set_status(id: StringName, on: bool) -> bool:
	match id:
		&"haste":
			_haste = on
			_apply_glow(false)
			return true
		&"shroud":
			return true
	return false


func revive() -> void:
	_dead = false
	_death_t = 0.0
	_death_emitted = false
	_action = &""
	_hit_t = 99.0
	_level_t = 99.0
	_level_at = _t - 99.0
	_speed = 0.0
	_walk_w = 0.0
	_dn_clip = &""
	_dn_w = 0.0
	_glows_off = false
	_root_scale = Vector3.ONE
	_force_write = true
	_set_flash(0.0)
	if _shadow:
		_shadow.transparency = 0.0
	_wk_flare = 0.0
	_wk_flare_written = -1.0
	_wk_req.clear()
	if _rd_on:
		_rd_clear(false)   # respawns on foot (cavalry-mounts.md 6.2)
	_apply_glow(true)
	_on_revive()
	set_process(true)
	_animate(0.0)


## Current per-unit glow multiplier (veterancy x haste; 0 while dead). Subclasses multiply their own boosts by it.
func glow_level() -> float:
	if _glows_off:
		return 0.0
	return _vet_boost * (1.3 if _haste else 1.0)


# ================================================================ dances (play_clip, ideas-inbox 2026-09-27)

## The dance clips every dancing model answers (cutscene versions must look like these: same moves / style).
const DANCE_CLIPS: Array[StringName] = [&"dance_victory", &"dance_surrender", &"dance_random"]
## Blend in / out of a dance (s).
const DANCE_BLEND := 0.3
const _DN_STYLES: Array[StringName] = [&"neutral", &"fire", &"ice", &"nature", &"shadow"]
## Beats per second per style (neutral, fire, ice, nature, shadow).
const _DN_TEMPO: Array[float] = [1.8, 2.2, 1.4, 1.1, 1.6]
const _DN_SLUMP: Array[float] = [1.0, 1.1, 0.45, 1.0, 1.25]
const _DN_KNEEL: Array[float] = [0.22, 0.22, 0.16, 0.2, 0.28]
const _DN_SHAKE: Array[float] = [10.0, 16.0, 5.0, 8.0, 10.0]
const _DN_AMP: Array[float] = [1.0, 1.25, 0.7, 1.0, 0.9]


## Plays a looping dance clip (DANCE_CLIPS): `dance_victory`, `dance_surrender` ("I give up": weapon dropped, kneel,
## hands up), `dance_random` (one of 3 emotes picked per call). Procedural on the pivots, blended in over DANCE_BLEND,
## flavoured by kingdom (Fire energetic, Ice stiff / proud, Nature swaying, Shadow sly), per-instance phase and tempo.
## Stops on stop_clip(), an attack / cast / mine / death; fades while walking. Returns false (nothing happens) for a
## model that can't dance (quadrupeds, mounts, seated riders, models without chest + arms) or an unknown id.
## Safe before _ready.
func play_clip(id: StringName) -> bool:
	if not DANCE_CLIPS.has(id):
		return false
	if not _ready_done:
		_dn_pending = id
		return true
	if _dead or not can_dance():
		return false
	if _dn_style < 0:
		_dn_init()
	if id != _dn_clip:
		_dn_t = 0.0
	_dn_clip = id
	_dn_count += 1
	_dn_var = absi(hash(get_instance_id()) + _dn_count) % 3
	_force_write = true
	set_process(true)
	return true


## Stops the dance (blends back to the idle over DANCE_BLEND).
func stop_clip() -> void:
	_dn_pending = &""
	if _dn_clip != &"":
		_dn_last = _dn_clip
	_dn_clip = &""


## The dance playing (&"" = none).
func current_clip() -> StringName:
	return _dn_clip if _ready_done else _dn_pending


## True when this model has the clip `id` (the dances: only a model that can dance).
func has_clip(id: StringName) -> bool:
	return DANCE_CLIPS.has(id) and (not _ready_done or can_dance())


## True for a biped with a chest and at least one arm (not a quadruped or a mount: MountModel has its own dances).
## A seated rider dances too (Stables16, JS 2026-09-27 "make sure they have dance"): the saddle keeps the hips and
## legs, the arms / chest / head dance and the reins let go; not during a hop-on / hop-off / thrown.
func can_dance() -> bool:
	if not _ready_done or is_quadruped or (_rd_on and _rd_act != &""):
		return false
	if _piv[P_MOUNT] != null or _piv[P_CHEST] == null or (_piv[P_ARM_L] == null and _piv[P_ARM_R] == null):
		return false
	return _can_dance()


## The dance flavour: &"neutral", &"fire", &"ice", &"nature", &"shadow" (from the model's folder / wizard name).
func dance_style() -> StringName:
	if _dn_style < 0:
		_dn_init()
	return _DN_STYLES[_dn_style]


## Subclass hook: return false to opt out of the dances.
func _can_dance() -> bool:
	return true


## Subclass hook: the dance pose (offsets with rot() / pos(), all weighted by `w`), called every animated frame while a
## clip plays or fades. `t` = seconds since the clip started. Override for a model's own version; call super for the
## others.
func _pose_dance(clip: StringName, t: float, w: float) -> void:
	match clip:
		&"dance_victory":
			_dn_victory(t, w)
		&"dance_surrender":
			_dn_surrender(t, w)
		&"dance_random":
			_dn_random(t, w)


# ================================================================ seated rider (13.V1b, cavalry-mounts.md 6.2 / 10)

## Seats this model on `mount` (a MountModel, or any Node3D: its seat_transform() / "Seat" child, else 1.2 m over
## its origin) or stands it back on its own origin (`on` false). Instant: no hop (play_mount / play_dismount animate).
## While seated the hips are locked to the mount's live Seat (bob, pitch, death roll; no frame lag: the rider
## processes after its mount), the legs sit astride (splay measured from the mount's barrel), the walk is off
## (set_moving is ignored), and the riding idle / rider bob follow the mount's gait_phase() / gallop_blend().
## Attacks, hits and level-ups still play on top (root motion damped). The rider's own blob hides (the mount's shows).
## Model placement: mount and rider share the unit's transform (siblings under the unit's visual), the mount's
## origin = the rider's origin. Safe before _ready. Nothing runs while not seated (one null check per frame).
func set_seated(on: bool, mount: Node3D = null) -> void:
	if not _ready_done:
		_rd_pending = [on, mount, &""]
		return
	if not on or mount == null or mount == self:
		if on:
			push_warning("CharacterModel.set_seated(true) needs a mount node")
		_rd_clear(false)
		return
	if mount != _rd_mount:
		if not _rd_on:
			_rd_prio = process_priority
		_rd_mount = mount
		_rd_on = true
		_rd_has_gait = mount.has_method(&"gait_phase") and mount.has_method(&"gallop_blend")
		_rd_has_seat = mount.has_method(&"seat_transform")
		process_priority = maxi(_rd_prio, mount.process_priority + 1)   # read the seat after the mount posed it
		_par_id = mount.get_instance_id()
		_rd_splay = _rd_measure_splay()
	_rd_act = &""
	_rd_t = 0.0
	_rd_arm_w = 0.0 if _action != &"" else 1.0
	_rd_busy = true
	_force_write = true
	set_process(true)


## True while seated on a mount (from set_seated(true) / during the hops, until a dismount or thrown landing).
func is_seated() -> bool:
	return _rd_on


## The mount this model sits on (null when not seated).
func seat_mount() -> Node3D:
	return _rd_mount if is_instance_valid(_rd_mount) else null


## The seated transition playing: &"" (none), &"mount", &"dismount", &"thrown".
func seat_action() -> StringName:
	return _rd_act


## Hop-on (MOUNT_HOP_LEN 0.3 s): from the ground by the mount's left flank up and over into the saddle. Call it right
## after set_seated(true, mount) (the model starts from its standing pose). No-op when not seated or dead.
func play_mount() -> void:
	if not _ready_done:
		if _rd_pending != null:
			_rd_pending[2] = &"mount"
		return
	if not _rd_on or _dead:
		return
	_rd_start(&"mount")


## Hop-off (MOUNT_HOP_LEN 0.3 s): out of the saddle over the left flank down onto the model's own origin; then the
## model is unseated (is_seated() false) and emits dismount_finished. Remove / puff the mount then. No-op when not
## seated.
func play_dismount() -> void:
	if not _ready_done:
		if _rd_pending != null:
			_rd_pending[2] = &"dismount"
		return
	if not _rd_on or _rd_act == &"thrown" or _rd_act == &"dismount":
		return
	_rd_start(&"dismount")


## Thrown off (THROWN_LEN 0.5 s): flung sideways out of the saddle, a tumbling roll to the ground, then back on the
## feet on the model's own origin; unseated at the end + dismount_finished. No-op when not seated. A rider that dies
## seated on a living mount is thrown the same way and stays down (the death pose plays on).
func play_thrown() -> void:
	if not _ready_done:
		if _rd_pending != null:
			_rd_pending[2] = &"thrown"
		return
	if not _rd_on or _rd_act == &"thrown":
		return
	_rd_side = 1.0 if (hash(get_instance_id() + int(_t * 10.0)) & 1) == 0 else -1.0
	_rd_start(&"thrown")


# ================================================================ champion class weapon (11.V1, skills-rework.md 5)

## Takes up the weapon of a champion class (`spear`, `sword_shield`, `two_hand`, `wizard`; &"" = back to the
## archetype weapon). Merges the class pieces into the grip pivots' merged meshes (no extra draw instance), drops the
## parts tagged `weapon_classes` that do not list this class, toggles the tagged keep_separate nodes, sets
## attack_style / attack_windup (restored with &""), then calls `_on_weapon_class(class_id)`. `pop`: the pieces scale
## in over WEAPON_POP_LEN (the class_chosen moment). Idempotent; safe before _ready (applied then, without the pop).
func set_weapon_class(class_id: StringName, pop: bool = true) -> void:
	if not _ready_done:
		_wk_pending = class_id
		return
	_wk_pending = null
	if class_id != &"" and not WEAPON_KIT.has_class(class_id):
		push_warning("CharacterModel: unknown weapon class '%s'" % class_id)
		return
	if class_id == _wk_class:
		return
	if not _wk_arch_saved:
		_wk_arch_saved = true
		_wk_arch_style = attack_style
		_wk_arch_windup = attack_windup
	_wk_class = class_id
	_wk_end_pop()
	_wk_req.clear()
	_wk_pieces.clear()
	if class_id != &"":
		_wk_pieces = _weapon_pieces(class_id)
		attack_style = WEAPON_KIT.attack_style_for(class_id)
		attack_windup = WEAPON_KIT.attack_windup_for(class_id)
	else:
		attack_style = _wk_arch_style
		attack_windup = _wk_arch_windup
	if _action == &"attack":
		_action = &""   # an attack of the old style would jump to the new timeline
	for n: Node3D in _wk_class_nodes:
		n.visible = PackedStringArray(n.get_meta(&"weapon_classes")).has(String(class_id))
	if pop and class_id != &"" and not _dead and is_inside_tree():
		_wk_start_pop()
	_wk_refresh()
	_force_write = true
	_on_weapon_class(class_id)
	set_process(true)


## The weapon class the model shows (&"" = its archetype weapon).
func weapon_class() -> StringName:
	return _wk_class


## The class pieces the model holds now (see ChampionWeaponKit), e.g. [spear, quiver, javelin].
func weapon_pieces() -> Array[StringName]:
	return _wk_pieces.duplicate()


## World position of the class weapon's working end (spear / sword tip, staff crystal...), or null without a class.
## A model's get_beam_origin() can return it for the Wizard class bolt.
func get_weapon_tip() -> Variant:
	if not _ready_done or _wk_class == &"" or _wk_pieces.is_empty() or not is_inside_tree():
		return null
	var p: StringName = _wk_pieces[0]
	var i: int = SLOT_PIVOT[WEAPON_KIT.slot_of(p)]
	if _piv[i] == null:
		return null
	return _piv[i].global_transform * (_wk_piece_xf(p, i) * WEAPON_KIT.piece_tip(p))


## Model-space frame of a weapon slot at rest (hand_r, hand_l: the fist centre; back: the quiver strap point).
## Identity before _ready (the generic grips are measured on the merged meshes).
func weapon_slot_xf(slot: StringName) -> Transform3D:
	return _weapon_slot(slot) if _ready_done else Transform3D.IDENTITY


## Model-space rest transform of a class piece (piece space -> model space). Identity before _ready.
func weapon_grip_xf(piece: StringName) -> Transform3D:
	return _weapon_grip(piece) if _ready_done else Transform3D.IDENTITY


## Pose helper (call it from a pose, every frame it applies): shows (true) or hides (false) a class piece this frame,
## e.g. the javelin during the Hobbling Javelin throw, the shield in flight during Shield Throw. Merged-mesh swap only
## when the visible set changes.
func show_weapon_piece(piece: StringName, on: bool) -> void:
	_wk_req[piece] = on


## Pose helper: flares the class weapon's glow (the staff crystal) to `amount` (0-1, decays over 0.35 s).
func weapon_flare(amount: float) -> void:
	_wk_flare = maxf(_wk_flare, amount)


## Tags an authored part for the class swap: it exists only while the weapon class is in `classes` (String or
## StringName ids; "" = before any class, i.e. the archetype look). Static parts: tag them in _build_parts (the
## part is left out of / merged into the class variants of its pivot). keep_separate nodes: shown / hidden.
## Null-safe (add_part returns null for static parts once the type is cached: that is fine, the tags are cached too).
static func mark_weapon_classes(part: Node, classes: Array) -> void:
	if part == null:
		return
	var ps := PackedStringArray()
	for c: Variant in classes:
		ps.append(String(c))
	part.set_meta(&"weapon_classes", ps)


## Shortcut: the part is the archetype weapon (hidden / left out once any class is taken).
static func mark_archetype_weapon(part: Node) -> void:
	mark_weapon_classes(part, [""])


## Subclass hook: which pieces this model holds for a class (default: all of ChampionWeaponKit.CLASS_PIECES, e.g. the
## Oathwall returns [&"sword"] for sword_shield: he keeps his door shield). Must not depend on the instance.
func _weapon_pieces(class_id: StringName) -> Array[StringName]:
	return WEAPON_KIT.pieces_for(class_id)


## Subclass hook: model-space frame of a slot at rest. Default: found from the merged arm meshes (the lowest point of
## the arm = the fist) / the chest mesh (just behind the back). Override to place the fist exactly (constant per scene).
func _weapon_slot(slot: StringName) -> Transform3D:
	return _wk_auto_slot(slot)


## Subclass hook: model-space rest transform of a piece. Default: `_weapon_slot(slot) * ChampionWeaponKit.piece_hold`.
## Override for per-weapon tweaks (constant per scene: the class variants are cached per scene type).
func _weapon_grip(piece: StringName) -> Transform3D:
	return _weapon_slot(WEAPON_KIT.slot_of(piece)) * WEAPON_KIT.piece_hold(piece)


## Subclass hook: called after every weapon class change (the kit swap is done): move identity props, re-grab nodes.
func _on_weapon_class(_class_id: StringName) -> void:
	pass


# ================================================================ subclass hooks (animation)

## Events: attack_start, release (at attack_windup or the strike frame), attack_end, cast_start, cast_end,
## mine_hit, level_up, death_glow_off.
func _on_action_event(_ev: StringName) -> void:
	pass


## Extra per-frame motion (orb bob, flames...). `dt` already respects the distance tiers. Called after the body pose.
func _extra_process(_dt: float) -> void:
	pass


## Cast pose: write offsets with rot()/pos(); return the cast length (s). Base: a generic two-arm raise.
func _pose_cast(_spell: StringName, t: float) -> float:
	var k := _k3(t, 0.0, 0.2, 0.35, 0.8, 1.0, 1.0)
	rot(P_ARM_L, Vector3(-80.0 * DEG * k, 0, 0))
	rot(P_ARM_R, Vector3(-80.0 * DEG * k, 0, 0))
	return 0.8


## Class skill pose (the 12 ids of CLASS_SKILL_IDS; play_cast routes them here, never to _pose_cast): write offsets,
## return the length (s). The kit's generic poses assume the class weapon of ChampionWeaponKit in the generic grips;
## a model overrides it for its own versions and calls super for the others.
func _pose_class_skill(ability_id: StringName, t: float) -> float:
	match ability_id:
		&"lunge":
			return _wk_pose_lunge(t)
		&"hobbling_javelin":
			return _wk_pose_javelin(t)
		&"skewer":
			return _wk_pose_skewer(t)
		&"riposte":
			return _wk_pose_riposte(t)
		&"second_wind":
			return _wk_pose_second_wind(t)
		&"shield_throw":
			return _wk_pose_shield_throw(t)
		&"cleave":
			return _wk_pose_cleave(t)
		&"crushing_blow":
			return _wk_pose_crushing_blow(t)
		&"whirlwind":
			return _wk_pose_whirlwind(t)
		&"arc_bolt":
			return _wk_pose_arc_bolt(t)
		&"slipstep":
			return _wk_pose_slipstep(t)
		&"starfall":
			return _wk_pose_starfall(t)
	return _pose_cast(ability_id, t)


## Mine pose (one 1.0 s swing); override for the Gloom Thrall lantern. The pick rests UP from the fist over the
## shoulder, so the head cocks back at -30 and comes over the shoulder into the node in front at +150.
func _pose_mine(t: float) -> void:
	rot(P_ARM_R, Vector3(DEG * _k3(t, 0.0, 0.35, 0.5, 1.0, -30.0, 150.0), 0, 0))
	pos(P_ROOT, Vector3(0, _k3(t, 0.35, 0.5, 0.5, 0.8, -0.03, -0.03), 0))


func _on_revive() -> void:
	pass


## Riding pose (seated, 13.V1b), called every animated frame while seated, after the kit placed the hips on the seat
## and the legs astride: add offsets with rot() / pos(), weighted by `w` (0 = standing, 1 = in the saddle; it blends
## through the hops). `gait` = the mount's gait phase 0-1 (0 = left-hind footfall), `gallop` 0-1, `moving` 0-1 (the
## mount's walk weight). Base: the upper body leans into the gait (more at the gallop) with a lagging pitch / sway and
## a soft vertical give (the rider bob), the head stays level, both hands on the reins (faded while an attack or cast
## poses the arms), the legs sway with the barrel. Override per model (staff hand, lantern pole, shield arm...) and
## call super() for the rest.
func _pose_seated(w: float, gait: float, gallop: float, moving: float) -> void:
	var p := gait
	var g := gallop
	var mv := moving
	var osc: float = lerpf(1.6 * sin(2.0 * TAU * p + 1.9), 6.0 * sin(TAU * (p - 0.33)), g) * mv
	var lean: float = 3.0 + lerpf(3.0, 12.0, g) * mv
	var sway: float = lerpf(2.4 * sin(TAU * p + 0.5), 1.0 * sin(TAU * p), g) * mv
	rot(P_CHEST, Vector3((lean + osc) * DEG * w, 0, sway * DEG * w))
	pos(P_CHEST, Vector3(0, lerpf(-0.012 * cos(2.0 * TAU * (p - 0.08)), 0.03 * cos(TAU * (p - 0.52)), g) * mv * w, 0))
	var look: float = 0.0
	if _tier == 0:
		look = 10.0 * sin((_t + _phase_off) * TAU / (idle_period * 2.3)) * (1.0 - mv)
	rot(P_HEAD, Vector3(-(lean + osc + _rd_seat_pitch) * 0.55 * DEG * w, look * DEG * w, -sway * 0.6 * DEG * w))
	var aw: float = w * _rd_arm_w
	var bounce: float = lerpf(2.0 * sin(2.0 * TAU * p), 6.0 * sin(TAU * (p - 0.4)), g) * mv
	rot(P_ARM_L, Vector3((-34.0 + bounce) * DEG * aw, 0, 10.0 * DEG * aw))
	rot(P_ARM_R, Vector3((-18.0 + bounce * 0.7) * DEG * aw, 0, -6.0 * DEG * aw))
	var ls: float = lerpf(3.0 * sin(TAU * p), 5.0 * sin(TAU * (p - 0.1)), g) * mv
	rot(P_LEG_L, Vector3(ls * DEG * w, 0, 0))
	rot(P_LEG_R, Vector3(-ls * DEG * w, 0, 0))


# ================================================================ per frame

func _process(delta: float) -> void:
	_t += delta
	_tier_timer -= delta
	if _tier_timer <= 0.0:
		_tier_timer = 0.5
		_update_tier()
	if _rd_on:
		_rd_sync()   # seated: tier, half-rate parity and freeze follow the mount
	if offscreen_freeze:
		_off_timer -= delta
		if _off_timer <= 0.0 or _offscreen:
			_off_timer = OFFSCREEN_CHECK
			_offscreen = _outside_view()
	elif _offscreen:
		_offscreen = false
	var busy: bool = _dead or _action != &"" or _hit_t < HIT_LEN or _level_t < LEVEL_LEN or _wk_pop_t < WEAPON_POP_LEN \
		or _rd_busy
	# A dance (victory / surrender emote) plays on even off-screen; only the far tier pauses it.
	if (_tier == 2 or (_offscreen and _dn_clip == &"" and _dn_w == 0.0)) and not busy:
		if not _frozen or (_tier == 2 and _walk_w != 0.0):
			_frozen = true
			_acc = 0.0
			if _tier == 2:   # far: settle into the idle pose (an off-screen model keeps its pose and phase)
				_walk_w = 0.0
				_animate(0.0)
		return
	_frozen = false
	_acc += delta
	if _tier >= 1 and ((Engine.get_process_frames() + _par_id) & 1) == 1:
		return
	var dt := _acc
	_acc = 0.0
	_animate(dt)


func _animate(dt: float) -> void:
	# Fast path: pure idle (writes Root.y, Chest.x, Head.y only).
	var target_w: float = 1.0 if _speed >= 0.3 and not _rd_on else 0.0
	if not _dead and _action == &"" and _hit_t >= HIT_LEN and _level_t >= LEVEL_LEN and _walk_w == 0.0 \
			and target_w == 0.0 and not _force_write and _flash_v == 0.0 and not _rd_on and _dn_w == 0.0 \
			and _dn_clip == &"":
		_idle_fast()
		_extra_process(dt)
		_wk_process(dt)
		return
	for i: int in _pidx:
		_off_pos[i] = Vector3.ZERO
		_off_rot[i] = Vector3.ZERO
	_root_scale = Vector3.ONE
	_walk_w = move_toward(_walk_w, 0.0 if _dead else target_w, dt / 0.15)
	if _dn_clip != &"" or _dn_w > 0.0:
		_dn_w = move_toward(_dn_w, 1.0 if _dn_clip != &"" and not _dead else 0.0, dt / DANCE_BLEND)
		if _dn_clip != &"":
			_dn_t += dt
			_dn_last = _dn_clip
		if _dn_w == 0.0:
			_force_write = true   # one full write back to the rest pose, then the fast idle path
	if _walk_w < 1.0:
		_pose_idle((1.0 - _walk_w) * (1.0 - _dn_w))
		if _dn_w > 0.0:
			_pose_dance(_dn_last, _dn_t, _dn_w * (1.0 - _walk_w))
	if _walk_w > 0.0:
		var rate: float = _speed / maxf(stride_speed, 0.1)
		if _carrying:
			rate *= 0.9
		_walk_p = fmod(_walk_p + dt * rate / maxf(stride_time, 0.05), 1.0)
		_pose_walk(_walk_w, rate)
	if _carrying:
		rot(P_CHEST, Vector3(10.0 * DEG, 0, 0))
	# actions
	if not _dead and _action != &"":
		var prev := _action_t
		_action_t += dt
		match _action:
			&"attack":
				if not _pose_attack(prev, _action_t):
					_action = &""
					_on_action_event(&"attack_end")
			&"cast":
				var cast_len: float = _pose_class_skill(_cast_id, _action_t) if CLASS_SKILL_IDS.has(_cast_id) \
					else _pose_cast(_cast_id, _action_t)
				if _action_t >= cast_len:
					_action = &""
					_on_action_event(&"cast_end")
			&"mine":
				if prev < 0.5 and _action_t >= 0.5:
					_on_action_event(&"mine_hit")
				if _action_t >= 1.0:
					_action_t -= 1.0
					_mine_left -= 1
					if _mine_left <= 0:
						_action = &""
				if _action != &"":
					_pose_mine(_action_t)
	# hit flinch + white flash
	if _hit_t < HIT_LEN:
		_hit_t += dt
		var k: float = clampf(_hit_t / 0.06, 0.0, 1.0) if _hit_t < 0.06 else clampf(1.0 - (_hit_t - 0.06) / 0.16, 0.0, 1.0)
		if flinch_push or is_quadruped:
			pos(P_ROOT, Vector3(0, 0, -0.10 * k))
		else:
			rot(P_CHEST, Vector3(-12.0 * DEG * k, 0, 0))
		_flash_gold = false
		_set_flash(clampf(1.0 - _hit_t / maxf(hit_flash_time, 0.01), 0.0, 1.0))
	# level-up
	if _level_t < LEVEL_LEN:
		_level_t += dt
		var u: float = clampf(_level_t / LEVEL_LEN, 0.0, 1.0)
		var s: float = 1.0 + 0.12 * sin(PI * u)
		_root_scale *= s
		rot(P_ARM_R, Vector3(-40.0 * DEG * clampf(sin(PI * clampf(_level_t / 0.3, 0.0, 1.0)) * 1.5, 0.0, 1.0), 0, 0))
		if _hit_t >= HIT_LEN:
			_flash_gold = true
			var lk: float = clampf(_level_t / LEVEL_FLASH_RISE, 0.0, 1.0) if _level_t < LEVEL_FLASH_RISE \
				else clampf(1.0 - (_level_t - LEVEL_FLASH_RISE) / LEVEL_FLASH_FADE, 0.0, 1.0)
			_set_flash(LEVEL_FLASH_PEAK * lk)
	if _hit_t >= HIT_LEN and _level_t >= LEVEL_LEN and _flash_v != 0.0:
		_set_flash(0.0)
	if _dead:
		_pose_death(dt)
	_extra_process(dt)
	if _rd_on:
		_rd_pose(dt)
	_wk_process(dt)
	_apply()


func _idle_fast() -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var s: float = sin(ph)
	if is_quadruped:
		_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.03 * s, 0))
		var h: int = P_MOUNT_HEAD if _piv[P_MOUNT_HEAD] else P_HEAD
		_write_rot(h, _rest_rot[h] + Vector3(5.0 * DEG * sin(1.3 * ph), 0, 0))
		return
	_write_pos(P_ROOT, _rest_pos[P_ROOT] + Vector3(0, 0.02 * s, 0))
	_write_rot(P_CHEST, _rest_rot[P_CHEST] + Vector3(1.5 * DEG * s, 0, 0))
	if _tier == 0:
		_write_rot(P_HEAD, _rest_rot[P_HEAD] + Vector3(0, 4.0 * DEG * sin(0.5 * ph + 1.0), 0))


func _pose_idle(w: float) -> void:
	var ph: float = (_t + _phase_off) * TAU / idle_period
	var s: float = sin(ph)
	if is_quadruped:
		pos(P_ROOT, Vector3(0, 0.03 * s * w, 0))
		rot(P_MOUNT_HEAD, Vector3(5.0 * DEG * sin(1.3 * ph) * w, 0, 0))
		rot(P_HEAD, Vector3(5.0 * DEG * sin(1.3 * ph) * w, 0, 0))
		return
	pos(P_ROOT, Vector3(0, 0.02 * s * w, 0))
	rot(P_CHEST, Vector3(1.5 * DEG * s * w, 0, 0))
	rot(P_HEAD, Vector3(0, 4.0 * DEG * sin(0.5 * ph + 1.0) * w, 0))


func _pose_walk(w: float, rate: float) -> void:
	var s: float = sin(TAU * _walk_p)
	var leg: float = (32.0 if _carrying else leg_swing_deg) * DEG * s * w
	rot(P_LEG_L, Vector3(leg, 0, 0))
	rot(P_LEG_R, Vector3(-leg, 0, 0))
	rot(P_ARM_L, Vector3(-18.0 * DEG * s * w, 0, 0))
	rot(P_ARM_R, Vector3(8.0 * DEG * s * w, 0, 0))
	pos(P_ROOT, Vector3(0, walk_bounce * absf(s) * w, 0))
	rot(P_CHEST, Vector3(0, 0, 3.0 * DEG * s * w))
	if _piv[P_MOUNT] or is_quadruped:
		var q: float = 32.0 * DEG * s * w
		if _piv[P_MOUNT] and _piv[P_CHEST] and rate >= gallop_rate:
			q = 38.0 * DEG * s * w
			rot(P_LEG_FL, Vector3(q, 0, 0)); rot(P_LEG_FR, Vector3(q, 0, 0))
			rot(P_LEG_BL, Vector3(-q, 0, 0)); rot(P_LEG_BR, Vector3(-q, 0, 0))
			pos(P_ROOT, Vector3(0, 0.04 * absf(s) * w, 0))
			rot(P_CHEST, Vector3(-6.0 * DEG * w, 0, 0))
		else:
			rot(P_LEG_FL, Vector3(q, 0, 0)); rot(P_LEG_BR, Vector3(q, 0, 0))
			rot(P_LEG_FR, Vector3(-q, 0, 0)); rot(P_LEG_BL, Vector3(-q, 0, 0))
		rot(P_ROOT, Vector3(4.0 * DEG * s * w, 0, 0))


## Attack timelines of art-units.md 6.4. Returns false when finished.
func _pose_attack(prev: float, t: float) -> bool:
	var sc := swing_scale * DEG
	var length: float = 0.4
	var release: float = attack_windup if attack_windup > 0.0 else 0.12
	match attack_style:
		# Arm rotation.x: negative swings a hanging arm toward +Z (the face). Weapons held forward-down from the
		# fist (sword, hammer, blades) chop with the arm raised overhead then brought down in front (big negative ->
		# small negative). Tools resting UP from the fist over the shoulder (pick, lantern pole, great sword) have
		# their head opposite the arm: the head comes over the shoulder to the front when the arm goes positive.
		&"melee_swing":
			rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.06, 0.12, 0.40, -140.0, -35.0) * sc, 0, 0))
			rot(P_CHEST, Vector3(0, _k3(t, 0.0, 0.06, 0.12, 0.40, 15.0, -25.0) * DEG, 0))
			pos(P_ROOT, Vector3(0, 0, _k3(t, 0.06, 0.12, 0.12, 0.40, 0.25, 0.25)))
		&"worker_pick":
			rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.06, 0.12, 0.40, -30.0, 125.0) * sc, 0, 0))
			rot(P_CHEST, Vector3(0, _k3(t, 0.0, 0.06, 0.12, 0.40, 15.0, -25.0) * DEG, 0))
			pos(P_ROOT, Vector3(0, 0, _k3(t, 0.06, 0.12, 0.12, 0.40, 0.25, 0.25)))
		&"dual_slash":
			length = 0.45
			rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.06, 0.12, 0.30, 50.0, -85.0) * sc, 0, 0))
			rot(P_ARM_L, Vector3(_k3(t, 0.10, 0.16, 0.22, 0.45, 50.0, -85.0) * sc, 0, 0))
			rot(P_CHEST, Vector3(0, _k3(t, 0.0, 0.08, 0.18, 0.45, 20.0, -20.0) * DEG, 0))
			pos(P_ROOT, Vector3(0, 0, _k3(t, 0.06, 0.12, 0.18, 0.45, 0.2, 0.2)))
		&"great_swing":
			length = 0.9
			release = 0.14
			var a := _k3(t, 0.0, 0.08, 0.14, 0.9, -25.0, 160.0) * sc
			rot(P_ARM_R, Vector3(a, 0, 0))
			rot(P_ARM_L, Vector3(a * 0.8, 0, 0))
			pos(P_ROOT, Vector3(0, _k3(t, 0.08, 0.14, 0.14, 0.9, -0.08, -0.08), 0))
		&"lance_charge":
			length = 0.55
			rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.06, 0.12, 0.55, 20.0, 20.0) * DEG, 0, 0))
			pos(P_ARM_R, Vector3(0, 0, _k3(t, 0.06, 0.12, 0.12, 0.55, 0.35, 0.35)))
			rot(P_MOUNT_HEAD, Vector3(_k3(t, 0.06, 0.12, 0.12, 0.55, 15.0, 15.0) * DEG, 0, 0))
		&"bow_draw":
			length = 0.45
			var d := _k3(t, 0.0, release, release, 0.45, 1.0, 1.0)
			rot(P_ARM_R, Vector3(-35.0 * DEG * d, 0, 0))
			pos(P_ARM_R, Vector3(0, 0, -0.30 * d))
			rot(P_CHEST, Vector3(0, -20.0 * DEG * d, 0))
		&"caster_fire":
			length = 0.5
			rot(P_ARM_R, Vector3(_k3(t, 0.0, release, release, 0.5, -25.0, -25.0) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, 0, _k3(t, release, release + 0.03, release + 0.03, 0.5, -0.06, -0.06)))
		&"sling_throw":
			length = 0.8
			# Pole up from the fist: ball whips from behind (-110) over the head to the front (+60), mid-whip at release.
			rot(P_ARM_R, Vector3(_k3(t, 0.0, release * 0.6, release + 0.1, 0.7, -110.0, 60.0) * DEG, 0, 0))
			rot(P_ROOT, Vector3(_k3(t, release, release + 0.08, release + 0.2, 0.7, 10.0, 10.0) * DEG, 0, 0))
		&"bite":
			var h: int = P_MOUNT_HEAD if _piv[P_MOUNT_HEAD] else P_HEAD
			pos(P_ROOT, Vector3(0, 0, _k3(t, 0.0, 0.06, 0.12, 0.40, 0.30, 0.20)))
			rot(h, Vector3(_k3(t, 0.0, 0.06, 0.12, 0.40, -20.0, 10.0) * DEG, 0, 0))
		&"wizard_bolt":
			length = 0.45
			rot(P_ARM_R, Vector3(_k3(t, 0.0, release, release, 0.45, -30.0, -30.0) * DEG, 0, 0))
		# ---- champion class styles (11.V1). Grips of ChampionWeaponKit.piece_hold: spear tip forward-up, sword
		# forward-down, greatsword and staff UP from the fist (their head moves forward when the arm goes positive).
		&"spear_thrust":
			# Cock back (0.07), thrust at 0.12: the arm drives forward along the shaft, the right shoulder follows.
			length = 0.5
			release = 0.12
			rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, 14.0, -4.0) * DEG, 0, _k3(t, 0.0, 0.07, 0.12, 0.5, 4.0, -5.0) * DEG))
			pos(P_ARM_R, Vector3(0, _k3(t, 0.0, 0.07, 0.12, 0.5, 0.0, 0.05), _k3(t, 0.0, 0.07, 0.12, 0.5, -0.14, 0.44)))
			rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, -22.0, 18.0) * DEG, 0, 0))
			rot(P_CHEST, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, -4.0, 12.0) * DEG, _k3(t, 0.0, 0.07, 0.12, 0.5, 20.0, -24.0) * DEG, 0))
			pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.07, 0.12, 0.5, -0.02, -0.05), _k3(t, 0.0, 0.07, 0.12, 0.5, -0.04, 0.20)))
			rot(P_LEG_L, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, -6.0, -26.0) * DEG, 0, 0))
			rot(P_LEG_R, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, 4.0, 18.0) * DEG, 0, 0))
		&"sword_slash":
			# Sword up over the right shoulder (0.07), a diagonal cut across to the left, strike at 0.12; the shield
			# arm comes up to guard.
			length = 0.5
			release = 0.12
			rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, -150.0, -38.0) * sc, 0,
				_k3(t, 0.0, 0.07, 0.12, 0.5, 28.0, -22.0) * DEG))
			rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, -34.0, -46.0) * DEG, 0, _k3(t, 0.0, 0.07, 0.12, 0.5, -6.0, 8.0) * DEG))
			rot(P_CHEST, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, -6.0, 12.0) * DEG, _k3(t, 0.0, 0.07, 0.12, 0.5, 22.0, -26.0) * DEG, 0))
			pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.07, 0.12, 0.5, 0.02, -0.04), _k3(t, 0.05, 0.12, 0.14, 0.5, 0.18, 0.18)))
			rot(P_LEG_L, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, -4.0, -20.0) * DEG, 0, 0))
			rot(P_LEG_R, Vector3(_k3(t, 0.0, 0.07, 0.12, 0.5, 2.0, 14.0) * DEG, 0, 0))
		&"great_cleave":
			# Overhead diagonal: the blade leans further back (0.10), comes over the right shoulder and down across
			# the front (strike 0.16), a heavy dip and a long recovery; both arms on the grip.
			length = 0.85
			release = 0.16
			var a := _k3(t, 0.0, 0.10, 0.16, 0.85, -35.0, 150.0) * sc
			rot(P_ARM_R, Vector3(a, 0, _k3(t, 0.0, 0.10, 0.16, 0.85, -10.0, 16.0) * DEG))
			rot(P_ARM_L, Vector3(a * 0.8, 0, _k3(t, 0.0, 0.10, 0.16, 0.85, 10.0, -14.0) * DEG))
			rot(P_CHEST, Vector3(_k3(t, 0.0, 0.10, 0.16, 0.85, -10.0, 22.0) * DEG, _k3(t, 0.0, 0.10, 0.16, 0.85, 22.0, -18.0) * DEG, 0))
			rot(P_HEAD, Vector3(_k3(t, 0.0, 0.10, 0.16, 0.85, -6.0, 8.0) * DEG, 0, 0))
			pos(P_ROOT, Vector3(0, _k3(t, 0.0, 0.10, 0.16, 0.85, 0.04, -0.12), _k3(t, 0.0, 0.10, 0.18, 0.85, -0.04, 0.20)))
			rot(P_LEG_L, Vector3(_k3(t, 0.0, 0.10, 0.16, 0.85, -6.0, -28.0) * DEG, 0, 0))
			rot(P_LEG_R, Vector3(_k3(t, 0.0, 0.10, 0.16, 0.85, 4.0, 22.0) * DEG, 0, 0))
		&"staff_bolt":
			# The crystal charges while the staff cocks back, then the staff snaps forward (its head toward the
			# target) with the free hand pushing: release at attack_windup (0.12), a crystal flare.
			length = 0.5
			rot(P_ARM_R, Vector3(_k3(t, 0.0, release * 0.8, release + 0.04, 0.5, -20.0, 32.0) * DEG, 0, 0))
			pos(P_ARM_R, Vector3(0, 0, _k3(t, 0.0, release * 0.8, release + 0.04, 0.5, -0.04, 0.22)))
			rot(P_ARM_L, Vector3(_k3(t, 0.0, release, release + 0.06, 0.5, -30.0, -64.0) * DEG, 0,
				_k3(t, 0.0, release, release + 0.06, 0.5, 0.0, 12.0) * DEG))
			rot(P_CHEST, Vector3(0, _k3(t, 0.0, release, release + 0.04, 0.5, 14.0, -12.0) * DEG, 0))
			pos(P_ROOT, Vector3(0, 0, _k3(t, release, release + 0.04, release + 0.08, 0.5, -0.05, -0.02)))
			if t < release:
				weapon_flare(0.6 * t / maxf(release, 0.01))
			elif prev < release:
				weapon_flare(1.0)
		_:
			rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.06, 0.12, 0.40, -140.0, -35.0) * sc, 0, 0))
	if prev < release and t >= release:
		_on_action_event(&"release")
	return t < length


func _pose_death(dt: float) -> void:
	_death_t += dt
	var t := _death_t
	var bh := body_height
	var buckle: float = _ease_out(clampf(t / 0.25, 0.0, 1.0))
	match death_style:
		&"sink":
			rot(P_CHEST, Vector3(35.0 * DEG * buckle, 0, 0))
			if is_quadruped:
				rot(P_LEG_FL, Vector3(0, 0, 40.0 * DEG * buckle)); rot(P_LEG_BL, Vector3(0, 0, 40.0 * DEG * buckle))
				rot(P_LEG_FR, Vector3(0, 0, -40.0 * DEG * buckle)); rot(P_LEG_BR, Vector3(0, 0, -40.0 * DEG * buckle))
			else:
				rot(P_LEG_L, Vector3(40.0 * DEG * buckle, 0, 0)); rot(P_LEG_R, Vector3(40.0 * DEG * buckle, 0, 0))
			var s: float = _ease_in(clampf((t - 0.25) / 0.75, 0.0, 1.0))
			pos(P_ROOT, Vector3(0, -0.15 * buckle - (bh - 0.15) * s, 0))
			_root_scale *= 1.0 - 0.2 * s
			if t >= 0.4:
				_glows_dead()
		&"crumble":
			pos(P_HEAD, Vector3(0, -0.06 * buckle, 0))
			_glows_dead()
			var c: float = _ease_in(clampf((t - 0.3) / 0.7, 0.0, 1.0))
			pos(P_ROOT, Vector3(0, -0.4 * c, 0))
			_root_scale *= Vector3(1.0, 1.0 - 0.4 * c, 1.0)
		_:  # fall
			rot(P_CHEST, Vector3(35.0 * DEG * buckle, 0, 0))
			rot(P_LEG_L, Vector3(40.0 * DEG * buckle, 0, 0)); rot(P_LEG_R, Vector3(40.0 * DEG * buckle, 0, 0))
			var f: float = _ease_in(clampf((t - 0.25) / 0.3, 0.0, 1.0))
			if _piv[P_MOUNT]:
				rot(P_ROOT, Vector3(0, 0, 70.0 * DEG * f))
			else:
				rot(P_ROOT, Vector3(80.0 * DEG * f, 0, 0))
			rot(P_ARM_R, Vector3(60.0 * DEG * f, 0, 0))
			if t >= 0.25:
				_glows_dead()
			var g: float = _ease_in(clampf((t - 0.55) / 0.45, 0.0, 1.0))
			pos(P_ROOT, Vector3(0, -0.25 * buckle - (0.6 * bh - 0.25) * g, 0))
	if _shadow:
		_shadow.transparency = clampf((t - 0.7) / 0.3, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


func _glows_dead() -> void:
	if _glows_off:
		return
	_glows_off = true
	_apply_glow(true)
	for p: GPUParticles3D in _death_fx:
		p.restart()
	_on_action_event(&"death_glow_off")


# ================================================================ pose helpers (subclasses use rot / pos)

## Adds a rotation offset (radians) to pivot i for this frame.
func rot(i: int, r: Vector3) -> void:
	if _piv[i]:
		_off_rot[i] += r


## Adds a position offset (m, pivot parent space) to pivot i for this frame.
func pos(i: int, p: Vector3) -> void:
	if _piv[i]:
		_off_pos[i] += p


## Keyframes 0 -> v1 (t0..t1) -> v2 (t1..t2) -> 0 (t2..t3), smooth.
static func _k3(t: float, t0: float, t1: float, t2: float, t3: float, v1: float, v2: float) -> float:
	if t <= t0 or t >= t3:
		return 0.0
	if t < t1:
		return v1 * _ease_out((t - t0) / maxf(t1 - t0, 0.0001))
	if t < t2:
		return lerpf(v1, v2, _ease_out((t - t1) / maxf(t2 - t1, 0.0001)))
	return v2 * (1.0 - smoothstep(0.0, 1.0, (t - t2) / maxf(t3 - t2, 0.0001)))


static func _ease_out(x: float) -> float:
	return 1.0 - (1.0 - x) * (1.0 - x)


static func _ease_in(x: float) -> float:
	return x * x


func _apply() -> void:
	for i: int in _pidx:
		_write_rot(i, _rest_rot[i] + _off_rot[i])
		_write_pos(i, _rest_pos[i] + _off_pos[i])
	var root := _piv[P_ROOT]
	if root and (_root_scale != _last_root_scale or _force_write):
		root.scale = _root_scale
		_last_root_scale = _root_scale
	_force_write = false


func _write_rot(i: int, r: Vector3) -> void:
	if _piv[i] == null:
		return
	if r != _last_rot[i] or _force_write:
		_last_rot[i] = r
		_piv[i].rotation = r


func _write_pos(i: int, p: Vector3) -> void:
	if _piv[i] == null:
		return
	if p != _last_pos[i] or _force_write:
		_last_pos[i] = p
		_piv[i].position = p


func _set_flash(v: float) -> void:
	if v == _flash_v:
		return
	_flash_v = v
	var col := GOLD if _flash_gold else hit_flash_color
	var w := v if _flash_gold else v * hit_flash_scale
	var targets := _flash_all_targets if _flash_gold else _flash_hit_targets
	if v == 0.0:
		targets = _flash_all_targets
	for gi: GeometryInstance3D in targets:
		gi.set_instance_shader_parameter(&"hit_flash", w)
		gi.set_instance_shader_parameter(&"flash_color", col)


func _apply_glow(force: bool) -> void:
	if not _ready_done:
		return
	var g := glow_level()
	if g == _glow_written and not force:
		return
	_glow_written = g
	for gi: GeometryInstance3D in _glow_nodes:
		gi.set_instance_shader_parameter(&"glow_boost", g)


## True when this model is outside the root viewport camera's frustum by more than OFFSCREEN_MARGIN m (planes cached
## once per frame for every model). False in SubViewports or without a camera.
func _outside_view() -> bool:
	if not is_inside_tree():
		return false
	var vp := get_viewport()
	if vp == null or vp != get_tree().root:
		return false
	var f := Engine.get_process_frames()
	if f != _fr_frame:
		_fr_frame = f
		var cam := vp.get_camera_3d()
		if cam != null:
			_fr_planes.assign(cam.get_frustum())
		else:
			_fr_planes.clear()
	var p := global_position
	for pl: Plane in _fr_planes:
		if pl.distance_to(p) > OFFSCREEN_MARGIN:
			return true
	return false


func _update_tier() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var nt: int = 1
	if cam:
		var d := cam.global_position.distance_to(global_position)
		nt = 0 if d < 30.0 else (1 if d < 45.0 else 2)
	if nt != _tier:
		_tier = nt
		for p: GPUParticles3D in _loop_fx:
			p.emitting = nt < 2


# ================================================================ building parts + merge (2.3)

## Creates a MeshInstance3D part under `pivot` at the MODEL-space position `model_pos` (feet origin, rest pose,
## pivots unrotated at rest). Static parts return null once the type's merged mesh is cached (they are not needed).
## keep_separate: toggled / animated / glowing-on-its-own parts. Returns the node (or null).
func add_part(pivot: Node3D, mesh: Mesh, mat: Material, model_pos: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, keep_separate: bool = false, part_name: String = "") -> MeshInstance3D:
	if not keep_separate and _merged.has(_type_key + "|" + _pivot_name(pivot)):
		return null
	var mi := MeshInstance3D.new()
	if part_name != "":
		mi.name = part_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = model_pos - model_origin(pivot)
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if keep_separate:
		mi.set_meta(&"keep_separate", true)
	pivot.add_child(mi)
	return mi


## Model-space rest position of a node (sum of positions up to this root; pivots are unrotated at rest).
func model_origin(n: Node3D) -> Vector3:
	var p := Vector3.ZERO
	var c: Node = n
	while c and c != self:
		p += (c as Node3D).position
		c = c.get_parent()
	return p


func _pivot_name(n: Node) -> String:
	return String(get_path_to(n))


func _merge_pivot(i: int) -> void:
	var p: Node3D = _piv[i]
	var key := _type_key + "|" + _pivot_name(p)
	var parts: Array[MeshInstance3D] = []
	var xforms: Array[Transform3D] = []
	_collect_static(p, Transform3D.IDENTITY, parts, xforms, true)
	var entry: Dictionary
	if _merged.has(key):
		entry = _merged[key]
	else:
		entry = _build_merged_split(key, parts, xforms)
		_merged[key] = entry
	for m: MeshInstance3D in parts:
		if m.get_child_count() == 0:
			m.get_parent().remove_child(m)
			m.queue_free()
		else:
			m.mesh = null
	if entry.is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.name = "Merged"
	mi.mesh = entry["mesh"]
	var casts: bool = i == P_CHEST or i == P_HEAD or i == P_ARM_R or i == P_MOUNT
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Instance uniforms authored on the parts (instance_shader_parameters/...) move to the merged node by NAME
	# (the slot of each name is the same in every unit shader, INSTANCE_SLOTS). The kit writes its own after this.
	var params: Dictionary = entry["params"]
	for nm: StringName in params:
		mi.set_instance_shader_parameter(nm, params[nm])
	p.add_child(mi)
	_merged_nodes[i] = mi


func _collect_static(n: Node, xf: Transform3D, parts: Array[MeshInstance3D], xforms: Array[Transform3D], top: bool) -> void:
	for c: Node in n.get_children():
		if not c is Node3D or c.has_meta(&"keep_separate") or _piv.has(c):
			continue
		if c is GPUParticles3D or c is Light3D or c is MultiMeshInstance3D:
			continue
		var cx: Transform3D = xf * (c as Node3D).transform
		if c is MeshInstance3D and (c as MeshInstance3D).mesh and (c as MeshInstance3D).visible:
			parts.append(c)
			xforms.append(cx)
		_collect_static(c, cx, parts, xforms, false)


## The archetype merge of a pivot (what _build_merged gives) when no part is tagged `weapon_classes`. With tagged
## parts (11.V1): the archetype mesh keeps the untagged parts + the parts tagged for "" (no class); the untagged merge
## and the tagged parts are kept in _wk_src for the class variants.
static func _build_merged_split(key: String, parts: Array[MeshInstance3D], xforms: Array[Transform3D]) -> Dictionary:
	var tagged: Array = []
	var base_parts: Array[MeshInstance3D] = []
	var base_x: Array[Transform3D] = []
	var common_parts: Array[MeshInstance3D] = []
	var common_x: Array[Transform3D] = []
	for k: int in parts.size():
		var mi := parts[k]
		if mi.has_meta(&"weapon_classes"):
			var cl := PackedStringArray(mi.get_meta(&"weapon_classes"))
			tagged.append([mi.mesh, xforms[k], _surface_mats(mi), cl])
			if cl.has(""):
				base_parts.append(mi)
				base_x.append(xforms[k])
		else:
			base_parts.append(mi)
			base_x.append(xforms[k])
			common_parts.append(mi)
			common_x.append(xforms[k])
	if tagged.is_empty():
		return _build_merged(parts, xforms)
	var common := _build_merged(common_parts, common_x)
	_wk_src[key] = {"common": common.get("mesh"), "tagged": tagged, "params": common.get("params", {})}
	return _build_merged(base_parts, base_x)


## The material each surface of a part draws with (material_override > surface override > the mesh's).
static func _surface_mats(mi: MeshInstance3D) -> Array:
	var out: Array = []
	for s: int in mi.mesh.get_surface_count():
		var mat: Material = mi.material_override
		if mat == null:
			mat = mi.get_surface_override_material(s)
		if mat == null:
			mat = mi.mesh.surface_get_material(s)
		out.append(mat)
	return out


static func _build_merged(parts: Array[MeshInstance3D], xforms: Array[Transform3D]) -> Dictionary:
	if parts.is_empty():
		return {}
	var by_mat: Dictionary = {}   # Material -> [verts, normals, tangents, uvs, indices]
	var order: Array = []
	var params: Dictionary = {}   # kit instance uniforms authored on the parts (first part wins)
	for k: int in parts.size():
		var mi := parts[k]
		for nm: String in INSTANCE_SLOTS:
			if not params.has(StringName(nm)):
				var val: Variant = mi.get_instance_shader_parameter(nm)
				if val != null:
					params[StringName(nm)] = val
		_merge_acc(by_mat, order, mi.mesh, xforms[k], _surface_mats(mi))
	var am := _merge_finish(by_mat, order)
	return {"mesh": am, "glow": _mesh_glows(am), "params": params}


## Appends every surface of `mesh` (transformed by xf; mats[s] replaces the surface material when not null) to the
## per-material accumulators of a merge.
static func _merge_acc(by_mat: Dictionary, order: Array, mesh: Mesh, xf: Transform3D, mats: Array) -> void:
	var nb := xf.basis.inverse().transposed()
	for s: int in mesh.get_surface_count():
		var mat: Material = mats[s] if s < mats.size() and mats[s] != null else mesh.surface_get_material(s)
		if not by_mat.has(mat):
			by_mat[mat] = [PackedVector3Array(), PackedVector3Array(), PackedFloat32Array(), PackedVector2Array(), PackedInt32Array()]
			order.append(mat)
		var acc: Array = by_mat[mat]
		var arr := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var tg: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT] if arr[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var base: int = (acc[0] as PackedVector3Array).size()
		for j: int in v.size():
			acc[0].append(xf * v[j])
			acc[1].append((nb * nr[j]).normalized() if j < nr.size() else Vector3.UP)
			if j * 4 + 3 < tg.size():
				var t3 := (xf.basis * Vector3(tg[j * 4], tg[j * 4 + 1], tg[j * 4 + 2])).normalized()
				acc[2].append_array(PackedFloat32Array([t3.x, t3.y, t3.z, tg[j * 4 + 3]]))
			else:
				acc[2].append_array(PackedFloat32Array([1.0, 0.0, 0.0, 1.0]))
			acc[3].append(uv[j] if j < uv.size() else Vector2.ZERO)
		if ix.is_empty():
			for j: int in v.size():
				acc[4].append(base + j)
		else:
			for j: int in ix.size():
				acc[4].append(base + ix[j])


static func _merge_finish(by_mat: Dictionary, order: Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	for mat: Material in order:
		var acc: Array = by_mat[mat]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = acc[0]
		arrays[Mesh.ARRAY_NORMAL] = acc[1]
		arrays[Mesh.ARRAY_TANGENT] = acc[2]
		arrays[Mesh.ARRAY_TEX_UV] = acc[3]
		arrays[Mesh.ARRAY_INDEX] = acc[4]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, mat)
	return am


## True when a surface of the mesh uses a shader with `glow_boost`.
static func _mesh_glows(m: Mesh) -> bool:
	if m == null:
		return false
	for s: int in m.get_surface_count():
		if instance_uniforms_of(m.surface_get_material(s)).has("glow_boost"):
			return true
	return false


## Merges [[mesh, xf, mats], ...] into one mesh (null when there is nothing).
static func _merge_items(items: Array) -> ArrayMesh:
	var by_mat: Dictionary = {}
	var order: Array = []
	for it: Array in items:
		if it[0] != null:
			_merge_acc(by_mat, order, it[0], it[1], it[2])
	if order.is_empty():
		return null
	return _merge_finish(by_mat, order)


## Names of the instance uniforms a material's shader declares (#include resolved; cached per shader). The kit picks
## its flash targets (`hit_flash`) and glow nodes (`glow_boost`) with it, so hero / army shaders (ice_crystal,
## torvald_frost, ysolde_grove...) are driven like unit_painted / unit_glow as long as they follow INSTANCE_SLOTS.
static func instance_uniforms_of(mat: Material) -> PackedStringArray:
	if not mat is ShaderMaterial or (mat as ShaderMaterial).shader == null:
		return PackedStringArray()
	var sh := (mat as ShaderMaterial).shader
	if _shader_iu.has(sh):
		return _shader_iu[sh]
	var names := PackedStringArray()
	_scan_instance_uniforms(sh.code, names, 0)
	_shader_iu[sh] = names
	return names


static func _scan_instance_uniforms(code: String, names: PackedStringArray, depth: int) -> void:
	for line: String in code.split("\n", false):
		var l := line.strip_edges()
		if l.begins_with("instance uniform "):
			var w := l.substr(17).split(" ", false)
			if w.size() >= 2:
				var nm: String = w[1]
				for sep: String in [":", "=", ";"]:
					nm = nm.get_slice(sep, 0)
				names.append(nm)
		elif l.begins_with("#include") and depth < 4:
			var q := l.split("\"")
			if q.size() >= 2:
				var inc := load(q[1]) as ShaderInclude
				if inc:
					_scan_instance_uniforms(inc.code, names, depth + 1)


func _collect(n: Node) -> void:
	for c: Node in n.get_children():
		if c.has_meta(&"carry"):
			_carry_nodes.append(c)
		if c.has_meta(&"vet_trim"):
			_trim_nodes.append(c)
			(c as Node3D).visible = false
		if c.has_meta(&"weapon_classes") and c is Node3D:
			_wk_class_nodes.append(c)
			(c as Node3D).visible = PackedStringArray(c.get_meta(&"weapon_classes")).has(String(_wk_class))
		if c is GPUParticles3D:
			var gp := c as GPUParticles3D
			if gp.one_shot:
				if gp.has_meta(&"death_fx"):
					_death_fx.append(gp)
			else:
				_loop_fx.append(gp)
		elif c is GeometryInstance3D and c != _shadow:
			var gi := c as GeometryInstance3D
			var painted := false
			var glowing := false
			for m: Material in _materials_of(gi):
				var iu := instance_uniforms_of(m)
				painted = painted or iu.has("hit_flash")
				glowing = glowing or iu.has("glow_boost")
			if painted:
				_flash_all_targets.append(gi)
				if gi.has_meta(&"flash_hit"):   # FaceRig (face + hair + beard): flashes on hits like the head
					_flash_hit_targets.append(gi)
			if glowing and not gi.has_meta(&"own_glow"):
				_glow_nodes.append(gi)
		_collect(c)


func _materials_of(gi: GeometryInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	if gi.material_override:
		out.append(gi.material_override)
		return out
	if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
		var mi := gi as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(s)
			if m == null:
				m = mi.mesh.surface_get_material(s)
			if m:
				out.append(m)
	elif gi is MultiMeshInstance3D:
		var mm := (gi as MultiMeshInstance3D).multimesh
		if mm and mm.mesh:
			for s: int in mm.mesh.get_surface_count():
				var m := mm.mesh.surface_get_material(s)
				if m:
					out.append(m)
	return out


# ================================================================ team colour (2.2)

## Recolours every cloth surface under n: c = the team colour, null = back to the authored materials. Always starts
## from the authored material (a team variant remembers it in meta "team_base"), so any sequence of calls ends right.
## into_models false: nested kit models (a howdah on a mammoth) are left to their own set_team_color.
func _recolor(n: Node, c: Variant, into_models: bool = true) -> void:
	for ch: Node in n.get_children():
		if not into_models and ch is CharacterModel:
			continue
		if ch is GeometryInstance3D:
			var gi := ch as GeometryInstance3D
			if gi.material_override:
				var base: Material = _team_base(gi.material_override)
				var want: Material = base if c == null else _team_variant(base, c)
				if want and want != gi.material_override:
					gi.material_override = want
			elif gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
				var mi := gi as MeshInstance3D
				for s: int in mi.mesh.get_surface_count():
					var own: Material = mi.mesh.surface_get_material(s)
					var cur: Material = mi.get_surface_override_material(s)
					if c == null:
						if cur and cur.has_meta(&"team_base"):
							var b: Material = _team_base(cur)
							mi.set_surface_override_material(s, null if b == own else b)
					else:
						var v := _team_variant(_team_base(cur) if cur else own, c)
						if v:
							mi.set_surface_override_material(s, v)
		_recolor(ch, c, into_models)


## The authored material behind a team variant (the material itself when it is not one).
static func _team_base(m: Material) -> Material:
	if m and m.has_meta(&"team_base"):
		return m.get_meta(&"team_base") as Material
	return m


static func _team_variant(m: Material, c: Color) -> Material:
	if m == null or m.resource_path == "":
		return null
	var nm := m.resource_path.get_file().get_basename()
	var is_cloth := nm.ends_with("_cloth") or nm.ends_with("_cloth_dark")
	var is_cape := nm.ends_with("_cape") or nm.ends_with("_cape_plain") or nm.ends_with("_pennon")
	if not is_cloth and not is_cape:
		return null
	var key := m.resource_path + "|" + c.to_html()
	if _team_mats.has(key):
		return _team_mats[key]
	var d := m.duplicate() as ShaderMaterial
	var dark := c.darkened(0.55)
	if is_cloth:
		d.set_shader_parameter(&"base_color", dark if nm.ends_with("_dark") else c)
	else:
		d.set_shader_parameter(&"cloth_color", c)
		d.set_shader_parameter(&"stripe_color", dark)
	d.set_meta(&"team_base", m)   # _recolor goes back to the authored material from any variant
	_team_mats[key] = d
	return d


# ================================================================ shared primitives + palette

## Palette material by name (art-units.md 2.2), e.g. palette(&"fire_cloth"). Loaded once, shared.
static func palette(name: StringName) -> Material:
	if not _mat_cache.has(name):
		_mat_cache[name] = load(MAT_DIR + String(name) + ".tres")
	return _mat_cache[name]


static func _cached(key: String, m: Mesh) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	_mesh_cache[key] = m
	return m


## Cylinder / cone (top_r 0). Total height h. caps false = open tube (collars, hoods).
static func cyl(top_r: float, bottom_r: float, h: float, seg: int = 8, caps: bool = true) -> Mesh:
	var key := "cyl%s_%s_%s_%d_%s" % [top_r, bottom_r, h, seg, caps]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bottom_r
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	m.cap_top = caps and top_r > 0.0
	m.cap_bottom = caps and bottom_r > 0.0
	return _cached(key, m)


static func sphere(r: float, radial: int = 10, rings: int = 5) -> Mesh:
	var key := "sph%s_%d_%d" % [r, radial, rings]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = radial
	m.rings = rings
	return _cached(key, m)


static func box(size: Vector3) -> Mesh:
	var key := "box%s" % size
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := BoxMesh.new()
	m.size = size
	return _cached(key, m)


## Capsule of radius r and TOTAL height h.
static func capsule(r: float, h: float) -> Mesh:
	var key := "cap%s_%s" % [r, h]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = 8
	m.rings = 4
	return _cached(key, m)


static func torus(inner: float, outer: float, rings: int = 16) -> Mesh:
	var key := "tor%s_%s_%d" % [inner, outer, rings]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = rings
	m.ring_segments = 6
	return _cached(key, m)


static func prism(size: Vector3) -> Mesh:
	var key := "pri%s" % size
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := PrismMesh.new()
	m.size = size
	return _cached(key, m)


## Cape plane (banner shader: vertical, facing +Z, UV.y 0 at the top edge).
static func cape(w: float, h: float) -> Mesh:
	var key := "cape%s_%s" % [w, h]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var m := PlaneMesh.new()
	m.size = Vector2(w, h)
	m.orientation = PlaneMesh.FACE_Z
	m.subdivide_depth = 6
	m.subdivide_width = 2
	return _cached(key, m)


## Adds the soft ground blob as node "Shadow" if the scene has none (size = radius x 2.6).
func ensure_shadow_blob(radius: float, tint: Color = Color(0.05, 0.03, 0.02, 0.45)) -> void:
	if _shadow == null:
		var mi := MeshInstance3D.new()
		mi.name = "Shadow"
		var pm := PlaneMesh.new()
		pm.size = Vector2.ONE
		mi.mesh = _cached("blob", pm)
		mi.material_override = palette(&"unit_shadow_blob")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(0, 0.02, 0)
		mi.scale = Vector3(radius * 2.6, 1.0, radius * 2.6)
		add_child(mi)
		_shadow = mi
	_shadow.set_instance_shader_parameter(&"blob_color", tint)


## Additive glowing mote particles (GPUParticles3D, pre-built). Shared process / draw resources per colour.
static func make_motes(color: Color, amount: int, lifetime: float, emit_radius: float, up_speed: float, size: float,
		ring: bool = false, one_shot: bool = false) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = one_shot
	p.emitting = not one_shot
	p.explosiveness = 0.9 if one_shot else 0.0
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-1.5, -1.5, -1.5), Vector3(3, 4, 3))
	var key := "motes%s_%s_%s_%s_%s" % [color.to_html(), emit_radius, up_speed, ring, one_shot]
	var pm: ParticleProcessMaterial = _mat_cache.get(key)
	if pm == null:
		pm = ParticleProcessMaterial.new()
		if ring:
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			pm.emission_ring_axis = Vector3.UP
			pm.emission_ring_radius = emit_radius
			pm.emission_ring_inner_radius = emit_radius * 0.8
			pm.emission_ring_height = 0.05
		else:
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = emit_radius
		pm.direction = Vector3.UP
		pm.spread = 25.0 if not one_shot else 180.0
		pm.initial_velocity_min = up_speed * 0.6
		pm.initial_velocity_max = up_speed
		pm.gravity = Vector3.ZERO
		var curve := CurveTexture.new()
		var cv := Curve.new()
		cv.add_point(Vector2(0, 1))
		cv.add_point(Vector2(1, 0.3))
		curve.curve = cv
		pm.scale_curve = curve
		_mat_cache[key] = pm
	p.process_material = pm
	var dkey := "motedraw%s_%s" % [color.to_html(), size]
	var q: QuadMesh = _mesh_cache.get(dkey)
	if q == null:
		q = QuadMesh.new()
		q.size = Vector2(size, size)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		# A.17: the scale curve only applies with keep_scale (Godot 4.7), and the round mask keeps the additive quad
		# from drawing as a hard white square.
		sm.billboard_keep_scale = true
		sm.albedo_texture = mote_texture()
		sm.albedo_color = Color(color.r * 2.0, color.g * 2.0, color.b * 2.0, 1.0)
		sm.vertex_color_use_as_albedo = false
		q.material = sm
		_mesh_cache[dkey] = q
	p.draw_pass_1 = q
	return p


## Soft round mote mask (bright core, smooth falloff, transparent corners), shared by every mote material.
static func mote_texture() -> Texture2D:
	var t: Texture2D = _mat_cache.get("mote_tex")
	if t == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(0, 0, 0, 0))
		g.add_point(0.25, Color(1, 1, 1, 0.9))
		g.add_point(0.6, Color(0.45, 0.45, 0.45, 0.35))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 32
		gt.height = 32
		t = gt
		_mat_cache["mote_tex"] = t
	return t


# ================================================================ champion class weapon: internals (11.V1)

# Keyframe tables of the generic class skill poses (times s, values deg / m; smooth between keys).
const _WK_JAV_T: Array[float] = [0.0, 0.14, 0.30, 0.40, 0.48, 0.80]
const _WK_JAV_LX: Array[float] = [0.0, -120.0, -170.0, -60.0, -45.0, 0.0]
const _WK_JAV_LZ: Array[float] = [0.0, 10.0, 18.0, -10.0, -6.0, 0.0]
const _WK_JAV_CY: Array[float] = [0.0, -10.0, -28.0, 22.0, 18.0, 0.0]
const _WK_JAV_CX: Array[float] = [0.0, 0.0, -8.0, 12.0, 8.0, 0.0]
const _WK_JAV_RX: Array[float] = [0.0, 0.0, 10.0, -10.0, -6.0, 0.0]
const _WK_JAV_GL: Array[float] = [0.0, 0.0, -4.0, 16.0, 12.0, 0.0]
const _WK_JAV_GR: Array[float] = [0.0, 0.0, 6.0, -24.0, -20.0, 0.0]
const _WK_JAV_BZ: Array[float] = [0.0, 0.0, -0.04, 0.12, 0.10, 0.0]
const _WK_SKW_T: Array[float] = [0.0, 0.18, 0.30, 0.52, 0.90]
const _WK_SKW_BZ: Array[float] = [0.0, -0.06, 0.40, 0.36, 0.0]
const _WK_SKW_BY: Array[float] = [0.0, -0.04, -0.10, -0.08, 0.0]
const _WK_SKW_RZ: Array[float] = [0.0, -0.16, 0.55, 0.50, 0.0]
const _WK_SKW_RX: Array[float] = [0.0, 14.0, -6.0, -6.0, 0.0]
const _WK_SKW_LX: Array[float] = [0.0, -40.0, -75.0, -70.0, 0.0]
const _WK_SKW_LP: Array[float] = [0.0, 0.0, 0.30, 0.28, 0.0]
const _WK_SKW_LZ: Array[float] = [0.0, 0.0, 18.0, 16.0, 0.0]
const _WK_SKW_CY: Array[float] = [0.0, 25.0, -18.0, -15.0, 0.0]
const _WK_SKW_CX: Array[float] = [0.0, -4.0, 14.0, 12.0, 0.0]
const _WK_SKW_GL: Array[float] = [0.0, -8.0, -40.0, -36.0, 0.0]
const _WK_SKW_GR: Array[float] = [0.0, 6.0, 30.0, 26.0, 0.0]
const _WK_SHT_T: Array[float] = [0.0, 0.18, 0.28, 0.40, 0.84, 0.92, 1.10]
const _WK_SHT_LX: Array[float] = [0.0, -55.0, -85.0, -70.0, -30.0, -70.0, 0.0]
const _WK_SHT_LZ: Array[float] = [0.0, 55.0, -60.0, -50.0, 0.0, -10.0, 0.0]
const _WK_SHT_CY: Array[float] = [0.0, 28.0, -30.0, -26.0, 0.0, -6.0, 0.0]
const _WK_SHT_BZ: Array[float] = [0.0, -0.03, 0.10, 0.08, 0.0, 0.02, 0.0]
const _WK_SHT_GL: Array[float] = [0.0, 0.0, -22.0, -18.0, 0.0, -4.0, 0.0]
const _WK_CLV_T: Array[float] = [0.0, 0.16, 0.30, 0.42, 0.80]
const _WK_CLV_RX: Array[float] = [0.0, 70.0, 95.0, 95.0, 0.0]
const _WK_CLV_CY: Array[float] = [0.0, 55.0, -65.0, -60.0, 0.0]
const _WK_CLV_BY: Array[float] = [0.0, -0.06, -0.10, -0.10, 0.0]
const _WK_CLV_GL: Array[float] = [0.0, -10.0, -22.0, -20.0, 0.0]
const _WK_CLV_GR: Array[float] = [0.0, 8.0, 18.0, 16.0, 0.0]
const _WK_CRB_T: Array[float] = [0.0, 0.28, 0.38, 0.55, 0.90]
const _WK_CRB_RX: Array[float] = [0.0, 60.0, 175.0, 170.0, 0.0]
const _WK_CRB_CX: Array[float] = [0.0, -14.0, 26.0, 22.0, 0.0]
const _WK_CRB_HX: Array[float] = [0.0, -12.0, 10.0, 8.0, 0.0]
const _WK_CRB_BY: Array[float] = [0.0, 0.05, -0.16, -0.14, 0.0]
const _WK_CRB_BZ: Array[float] = [0.0, -0.04, 0.16, 0.14, 0.0]
const _WK_CRB_GL: Array[float] = [0.0, -6.0, -30.0, -26.0, 0.0]
const _WK_CRB_GR: Array[float] = [0.0, 4.0, 24.0, 20.0, 0.0]
const _WK_ARC_T: Array[float] = [0.0, 0.14, 0.20, 0.30, 0.60]
const _WK_ARC_RX: Array[float] = [0.0, -24.0, 38.0, 34.0, 0.0]
const _WK_ARC_RP: Array[float] = [0.0, -0.06, 0.24, 0.22, 0.0]
const _WK_ARC_LX: Array[float] = [0.0, -30.0, -70.0, -65.0, 0.0]
const _WK_ARC_CY: Array[float] = [0.0, 18.0, -16.0, -14.0, 0.0]
const _WK_ARC_BZ: Array[float] = [0.0, -0.03, 0.08, 0.07, 0.0]
const _WK_HOLD4_T: Array[float] = [0.0, 0.25, 3.70, 4.00]
const _WK_HOLD_V: Array[float] = [0.0, 1.0, 1.0, 0.0]
const _WK_SW_T: Array[float] = [0.0, 0.25, 0.70, 1.00, 1.40]
const _WK_SW_B: Array[float] = [0.0, 0.3, 1.0, 1.0, 0.0]
const _WK_WW_T: Array[float] = [0.0, 0.15, 1.80, 2.00]
const _WK_SF_T: Array[float] = [0.0, 0.30, 0.95, 1.20]


## Smooth keyframes (smoothstep between keys), like the Coin-Cutter's tables.
static func _wk_kf(t: float, ts: Array[float], vs: Array[float]) -> float:
	var n := ts.size()
	if t <= ts[0]:
		return vs[0]
	for i: int in range(1, n):
		if t < ts[i]:
			var f := (t - ts[i - 1]) / maxf(ts[i] - ts[i - 1], 0.0001)
			return lerpf(vs[i - 1], vs[i], f * f * (3.0 - 2.0 * f))
	return vs[n - 1]


## Model-space rest origin of a node under this model (pivots at their rest position).
func _wk_rest_origin(n: Node) -> Vector3:
	var p := Vector3.ZERO
	var c: Node = n
	while c != null and c != self:
		var c3 := c as Node3D
		if c3:
			var k := _piv.find(c3)
			p += _rest_pos[k] if k >= 0 else c3.position
		c = c.get_parent()
	return p


## Piece space -> pivot i space (rest), from the model's grip.
func _wk_piece_xf(piece: StringName, i: int) -> Transform3D:
	return Transform3D(Basis.IDENTITY, -_wk_rest_origin(_piv[i])) * _weapon_grip(piece)


## Model-space vertices of a pivot's archetype merge without its tagged parts (the arm / chest alone).
func _wk_pivot_verts(i: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	if _piv[i] == null:
		return out
	var pkey := _type_key + "|" + _pivot_name(_piv[i])
	var src: Dictionary = _wk_src.get(pkey, {})
	var m: Mesh = null
	if src.is_empty():
		m = (_merged.get(pkey, {}) as Dictionary).get("mesh")
	else:
		m = src["common"]
	if m == null:
		return out
	var o := _wk_rest_origin(_piv[i])
	for s: int in m.get_surface_count():
		for v: Vector3 in (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			out.append(v + o)
	return out


## Generic grips, found once per scene type: the fist = the lowest point of the arm merge (+0.085 m), when plausible
## (else a body-height estimate); the back strap point = just behind the chest merge at shoulder height, right of centre.
func _wk_auto_slot(slot: StringName) -> Transform3D:
	var key := _type_key + "|" + String(slot)
	if _wk_grips.has(key):
		return _wk_grips[key]
	var o := Vector3.ZERO
	match slot:
		&"hand_r", &"hand_l":
			var side: float = 1.0 if slot == &"hand_r" else -1.0
			var i: int = P_ARM_R if side > 0.0 else P_ARM_L
			var sh: Vector3 = _wk_rest_origin(_piv[i]) if _piv[i] else Vector3(0.3 * side, 0.8 * body_height, 0.0)
			o = Vector3(sh.x + 0.06 * side, minf(sh.y - 0.3, 0.53 * body_height), 0.10)
			var verts := _wk_pivot_verts(i)
			if verts.size() > 0:
				var min_y := INF
				for v: Vector3 in verts:
					min_y = minf(min_y, v.y)
				var c := Vector3.ZERO
				var n := 0
				for v: Vector3 in verts:
					if v.y < min_y + 0.10:
						c += v
						n += 1
				c /= float(maxi(n, 1))
				var cand := Vector3(c.x, min_y + 0.085, c.z)
				if cand.y > 0.3 * body_height and cand.y < sh.y - 0.12 and absf(cand.x - sh.x) < 0.3 and absf(cand.z) < 0.4:
					o = cand
		&"back":
			var sy: float = _wk_rest_origin(_piv[P_ARM_R]).y if _piv[P_ARM_R] else 0.78 * body_height
			var z := -0.30
			var min_z := INF
			for v: Vector3 in _wk_pivot_verts(P_CHEST):
				if v.x > -0.05 and v.x < 0.32 and v.y > sy - 0.5 and v.y < sy + 0.05:
					min_z = minf(min_z, v.z)
			if min_z < INF:
				z = min_z - 0.07
			o = Vector3(0.12, sy - 0.2, z)
	var xf := Transform3D(Basis.IDENTITY, o)
	_wk_grips[key] = xf
	return xf


func _wk_popping(piece: StringName) -> bool:
	for e: Array in _wk_pop:
		if e[2] == piece:
			return true
	return false


## Bit k = piece k of _wk_pieces is merged now: its default (javelin hidden) or this frame's pose request; pieces
## scaling in are drawn by their own pop node instead.
func _wk_mask() -> int:
	var m := 0
	for k: int in _wk_pieces.size():
		var p: StringName = _wk_pieces[k]
		var on: bool = _wk_req.get(p, not WEAPON_KIT.is_hidden_by_default(p))
		if on and not _wk_popping(p):
			m |= 1 << k
	return m


## Puts every pivot's merged mesh in line with the class and the visible pieces (a swap only where the variant key
## changed; variants are built once per scene type and cached).
func _wk_refresh() -> void:
	var mask := _wk_mask()
	_wk_mask_applied = mask
	for i: int in _pidx:
		var on: Array[StringName] = []
		if _wk_class != &"":
			for k: int in _wk_pieces.size():
				if mask & (1 << k) and int(SLOT_PIVOT.get(WEAPON_KIT.slot_of(_wk_pieces[k]), -1)) == i:
					on.append(_wk_pieces[k])
		var pkey := _type_key + "|" + _pivot_name(_piv[i])
		var key := "base"
		if _wk_class != &"" and (not on.is_empty() or _wk_src.has(pkey)):
			key = "%s|%d|%s|%s" % [_type_key, i, _wk_class, ",".join(PackedStringArray(on))]
		if String(_wk_applied.get(i, "base")) == key:
			continue
		_wk_applied[i] = key
		var mesh: Mesh = null
		if key == "base":
			mesh = (_merged.get(pkey, {}) as Dictionary).get("mesh")
		elif _wk_variants.has(key):
			mesh = _wk_variants[key]
		else:
			mesh = _wk_build_variant(i, pkey, on)
			_wk_variants[key] = mesh
		_wk_set_pivot_mesh(i, pkey, mesh)


func _wk_build_variant(i: int, pkey: String, on: Array[StringName]) -> Mesh:
	var items: Array = []
	var src: Dictionary = _wk_src.get(pkey, {})
	if src.is_empty():
		var base: Mesh = (_merged.get(pkey, {}) as Dictionary).get("mesh")
		if base:
			items.append([base, Transform3D.IDENTITY, []])
	else:
		if src["common"] != null:
			items.append([src["common"], Transform3D.IDENTITY, []])
		for t: Array in src["tagged"]:
			if (t[3] as PackedStringArray).has(String(_wk_class)):
				items.append([t[0], t[1], t[2]])
	for p: StringName in on:
		items.append([WEAPON_KIT.piece_mesh(p), _wk_piece_xf(p, i), []])
	return _merge_items(items)


## Swaps pivot i's merged mesh: surface overrides reset and re-tinted, instance uniforms re-written, glow membership
## (a merged node whose only glow is the class weapon's crystal is driven here, with the pose flares).
func _wk_set_pivot_mesh(i: int, pkey: String, mesh: Mesh) -> void:
	var node: MeshInstance3D = _merged_nodes.get(i)
	if node == null:
		if mesh == null:
			return
		node = MeshInstance3D.new()
		node.name = "Merged"
		var casts: bool = i == P_CHEST or i == P_HEAD or i == P_ARM_R or i == P_MOUNT
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_piv[i].add_child(node)
		_merged_nodes[i] = node
		_flash_all_targets.append(node)
		if i == P_CHEST or i == P_HEAD or i == P_ARM_R:
			_flash_hit_targets.append(node)
	node.mesh = mesh
	for s: int in node.get_surface_override_material_count():
		node.set_surface_override_material(s, null)
	if mesh == null:
		return
	_wk_tint(node)
	var entry: Dictionary = _merged.get(pkey, {})
	var src: Dictionary = _wk_src.get(pkey, {})
	var params: Dictionary = entry.get("params", src.get("params", {}))
	for nm: StringName in params:
		node.set_instance_shader_parameter(nm, params[nm])
	var iu := PackedStringArray()
	for s: int in mesh.get_surface_count():
		iu.append_array(instance_uniforms_of(mesh.surface_get_material(s)))
	if iu.has("hit_flash"):
		node.set_instance_shader_parameter(&"ao_height", body_height)
		node.set_instance_shader_parameter(&"hit_flash", _flash_v if _flash_gold else _flash_v * hit_flash_scale)
		node.set_instance_shader_parameter(&"flash_color", GOLD if _flash_gold else hit_flash_color)
	# The crystal: a pivot whose archetype merge had no glow is driven here (own_glow: WEAPON_GLOW_BASE x the kit
	# level + the pose flares, in _wk_process); a pivot that already glowed stays with whoever drove it (kit or model).
	var base_glow: bool = entry.get("glow", false)
	if iu.has("glow_boost") and not base_glow and not _glow_nodes.has(node) and not _wk_glow_added.has(node):
		_wk_glow_added.append(node)
		node.set_meta(&"own_glow", true)
	elif not iu.has("glow_boost") and _wk_glow_added.has(node):
		_wk_glow_added.erase(node)
		node.remove_meta(&"own_glow")
	if _wk_glow_added.has(node):
		node.set_instance_shader_parameter(&"glow_boost", glow_level() * WEAPON_GLOW_BASE)
		_wk_flare_written = -1.0


## Team colour of the last recolour on the swapped surfaces (the weapon's team cloth: tassel, shield boss).
func _wk_tint(node: MeshInstance3D) -> void:
	if _wk_team == null or node.mesh == null:
		return
	for s: int in node.mesh.get_surface_count():
		var v := _team_variant(node.mesh.surface_get_material(s), _wk_team)
		if v:
			node.set_surface_override_material(s, v)


## The class_chosen scale-in: each default piece drawn by its own temporary node (0 -> 1.15 -> 1 over 0.3 s), then
## merged. Two nodes at most, once per champion.
func _wk_start_pop() -> void:
	_wk_end_pop()
	_wk_pop_t = 0.0
	for p: StringName in _wk_pieces:
		if WEAPON_KIT.is_hidden_by_default(p):
			continue
		var i: int = SLOT_PIVOT[WEAPON_KIT.slot_of(p)]
		if _piv[i] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = "WeaponPop"
		mi.mesh = WEAPON_KIT.piece_mesh(p)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var base := _wk_piece_xf(p, i)
		mi.transform = base.scaled_local(Vector3.ONE * 0.01)
		_piv[i].add_child(mi)
		_wk_tint(mi)
		mi.set_instance_shader_parameter(&"ao_height", body_height)
		mi.set_instance_shader_parameter(&"glow_boost", glow_level() * WEAPON_GLOW_BASE)
		_wk_pop.append([mi, base, p])


func _wk_end_pop() -> void:
	for e: Array in _wk_pop:
		var mi: MeshInstance3D = e[0]
		if is_instance_valid(mi):
			if mi.get_parent():
				mi.get_parent().remove_child(mi)
			mi.queue_free()
	_wk_pop.clear()
	_wk_pop_t = 99.0


## Per animated frame (after the poses and _extra_process): the scale-in, the piece requests of the poses, the flare.
func _wk_process(dt: float) -> void:
	if _wk_class == &"":
		if not _wk_req.is_empty():
			_wk_req.clear()
		return
	if not _wk_pop.is_empty():
		_wk_pop_t += dt
		var u := clampf(_wk_pop_t / WEAPON_POP_LEN, 0.0, 1.0)
		var s: float = 1.15 * _ease_out(u / 0.7) if u < 0.7 else lerpf(1.15, 1.0, smoothstep(0.0, 1.0, (u - 0.7) / 0.3))
		s = maxf(s, 0.01)
		for e: Array in _wk_pop:
			(e[0] as MeshInstance3D).transform = (e[1] as Transform3D).scaled_local(Vector3.ONE * s)
		if _wk_pop_t >= WEAPON_POP_LEN:
			_wk_end_pop()
	if _wk_mask() != _wk_mask_applied:
		_wk_refresh()
	_wk_req.clear()
	if not _wk_glow_added.is_empty():
		var g := glow_level() * (WEAPON_GLOW_BASE + 2.2 * _wk_flare)
		if g != _wk_flare_written:
			_wk_flare_written = g
			for n: GeometryInstance3D in _wk_glow_added:
				n.set_instance_shader_parameter(&"glow_boost", g)
	_wk_flare = maxf(0.0, _wk_flare - dt / 0.35)


# ---------------------------------------------------------------- generic class skill poses (11.V1)
# Per-champion versions come in 11.V2-11.V5 (override _pose_class_skill). Grips: ChampionWeaponKit.piece_hold.

## Lunge: coils low, then a dash-thrust (the gameplay moves the unit): deep lunge, spear driven forward at 0.20.
func _wk_pose_lunge(t: float) -> float:
	var c := _k3(t, 0.0, 0.10, 0.30, 0.60, 1.0, 1.0)
	pos(P_ROOT, Vector3(0, -0.14 * c, _k3(t, 0.0, 0.10, 0.20, 0.60, -0.06, 0.50)))
	rot(P_CHEST, Vector3(24.0 * DEG * c, _k3(t, 0.0, 0.10, 0.20, 0.60, 18.0, -24.0) * DEG, 0))
	rot(P_ARM_R, Vector3(_k3(t, 0.0, 0.10, 0.20, 0.60, 18.0, -20.0) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, 0, _k3(t, 0.0, 0.10, 0.20, 0.60, -0.12, 0.45)))
	rot(P_ARM_L, Vector3(_k3(t, 0.0, 0.10, 0.20, 0.60, 10.0, 35.0) * DEG, 0, -20.0 * DEG * c))
	rot(P_HEAD, Vector3(-18.0 * DEG * c, 0, 0))
	rot(P_LEG_L, Vector3(_k3(t, 0.0, 0.10, 0.20, 0.60, -10.0, -48.0) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_k3(t, 0.0, 0.10, 0.20, 0.60, 8.0, 36.0) * DEG, 0, 0))
	return 0.60


## Hobbling Javelin: the free hand pulls a javelin from the back quiver (shown 0.10-0.40), cocks it over the
## shoulder and throws overhand at 0.40 with a step.
func _wk_pose_javelin(t: float) -> float:
	rot(P_ARM_L, Vector3(_wk_kf(t, _WK_JAV_T, _WK_JAV_LX) * DEG, 0, _wk_kf(t, _WK_JAV_T, _WK_JAV_LZ) * DEG))
	rot(P_ARM_R, Vector3(_wk_kf(t, _WK_JAV_T, _WK_JAV_RX) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_wk_kf(t, _WK_JAV_T, _WK_JAV_CX) * DEG, _wk_kf(t, _WK_JAV_T, _WK_JAV_CY) * DEG, 0))
	rot(P_LEG_L, Vector3(_wk_kf(t, _WK_JAV_T, _WK_JAV_GL) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_wk_kf(t, _WK_JAV_T, _WK_JAV_GR) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, 0, _wk_kf(t, _WK_JAV_T, _WK_JAV_BZ)))
	if t >= 0.10 and t < 0.40:
		show_weapon_piece(&"javelin", true)
	return 0.80


## Skewer: a long two-hand thrust with a big step (0.30), held a beat, both arms along the shaft.
func _wk_pose_skewer(t: float) -> float:
	pos(P_ROOT, Vector3(0, _wk_kf(t, _WK_SKW_T, _WK_SKW_BY), _wk_kf(t, _WK_SKW_T, _WK_SKW_BZ)))
	rot(P_ARM_R, Vector3(_wk_kf(t, _WK_SKW_T, _WK_SKW_RX) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, 0, _wk_kf(t, _WK_SKW_T, _WK_SKW_RZ)))
	rot(P_ARM_L, Vector3(_wk_kf(t, _WK_SKW_T, _WK_SKW_LX) * DEG, 0, _wk_kf(t, _WK_SKW_T, _WK_SKW_LZ) * DEG))
	pos(P_ARM_L, Vector3(0, 0, _wk_kf(t, _WK_SKW_T, _WK_SKW_LP)))
	rot(P_CHEST, Vector3(_wk_kf(t, _WK_SKW_T, _WK_SKW_CX) * DEG, _wk_kf(t, _WK_SKW_T, _WK_SKW_CY) * DEG, 0))
	rot(P_LEG_L, Vector3(_wk_kf(t, _WK_SKW_T, _WK_SKW_GL) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_wk_kf(t, _WK_SKW_T, _WK_SKW_GR) * DEG, 0, 0))
	return 0.90


## Riposte: shield up across the chest, sword cocked high, knees braced; held 4 s (an attack or a cast ends it).
func _wk_pose_riposte(t: float) -> float:
	var k := _wk_kf(t, _WK_HOLD4_T, _WK_HOLD_V)
	var bob := 0.012 * sin(t * 6.0) * k
	rot(P_ARM_L, Vector3(-72.0 * DEG * k, 0, 14.0 * DEG * k))
	pos(P_ARM_L, Vector3(0.08 * k, 0.02 * k, 0.12 * k))
	rot(P_ARM_R, Vector3(-118.0 * DEG * k, 0, 22.0 * DEG * k))
	rot(P_CHEST, Vector3(4.0 * DEG * k, 12.0 * DEG * k, 0))
	pos(P_ROOT, Vector3(0, -0.06 * k + bob, 0))
	rot(P_LEG_L, Vector3(-14.0 * DEG * k, 0, 0))
	rot(P_LEG_R, Vector3(12.0 * DEG * k, 0, 0))
	return 4.0


## Second Wind: sword lowered point-down, a deep breath (shoulders and chest rise, head back), a slow exhale.
func _wk_pose_second_wind(t: float) -> float:
	var b := _wk_kf(t, _WK_SW_T, _WK_SW_B)
	rot(P_ARM_R, Vector3(16.0 * DEG * b, 0, 0))
	rot(P_ARM_L, Vector3(8.0 * DEG * b, 0, 0))
	pos(P_ARM_R, Vector3(0, 0.07 * b, 0))
	pos(P_ARM_L, Vector3(0, 0.07 * b, 0))
	rot(P_CHEST, Vector3(-9.0 * DEG * b, 0, 0))
	rot(P_HEAD, Vector3(-14.0 * DEG * b, 0, 0))
	pos(P_ROOT, Vector3(0, 0.03 * b, 0))
	return 1.40


## Shield Throw: winds the shield across the body, flings it flat (0.28: the shield leaves the arm, hidden while
## it flies), catches it 0.6 s later (0.88) with a small recoil.
func _wk_pose_shield_throw(t: float) -> float:
	rot(P_ARM_L, Vector3(_wk_kf(t, _WK_SHT_T, _WK_SHT_LX) * DEG, 0, _wk_kf(t, _WK_SHT_T, _WK_SHT_LZ) * DEG))
	rot(P_CHEST, Vector3(0, _wk_kf(t, _WK_SHT_T, _WK_SHT_CY) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _wk_kf(t, _WK_SHT_T, _WK_SHT_BZ)))
	rot(P_LEG_L, Vector3(_wk_kf(t, _WK_SHT_T, _WK_SHT_GL) * DEG, 0, 0))
	rot(P_ARM_R, Vector3(-20.0 * DEG * _k3(t, 0.0, 0.2, 0.9, 1.1, 1.0, 1.0), 0, 0))
	if t >= 0.28 and t < 0.88:
		show_weapon_piece(&"round_shield", false)
	return 1.10


## Cleave: the blade swings out level (arms back, blade forward) and sweeps wide from right to left at 0.30.
func _wk_pose_cleave(t: float) -> float:
	var a := _wk_kf(t, _WK_CLV_T, _WK_CLV_RX)
	rot(P_ARM_R, Vector3(a * DEG, 0, 0))
	rot(P_ARM_L, Vector3(a * 0.8 * DEG, 0, 0))
	rot(P_CHEST, Vector3(6.0 * DEG * a / 95.0, _wk_kf(t, _WK_CLV_T, _WK_CLV_CY) * DEG, 0))
	pos(P_ROOT, Vector3(0, _wk_kf(t, _WK_CLV_T, _WK_CLV_BY), 0))
	rot(P_LEG_L, Vector3(_wk_kf(t, _WK_CLV_T, _WK_CLV_GL) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_wk_kf(t, _WK_CLV_T, _WK_CLV_GR) * DEG, 0, 0))
	return 0.80


## Crushing Blow: the greatsword goes up over the head (0.28) and chops straight down in front (0.38), a deep dip.
func _wk_pose_crushing_blow(t: float) -> float:
	var a := _wk_kf(t, _WK_CRB_T, _WK_CRB_RX)
	rot(P_ARM_R, Vector3(a * DEG, 0, 0))
	rot(P_ARM_L, Vector3(a * 0.85 * DEG, 0, 0))
	rot(P_CHEST, Vector3(_wk_kf(t, _WK_CRB_T, _WK_CRB_CX) * DEG, 0, 0))
	rot(P_HEAD, Vector3(_wk_kf(t, _WK_CRB_T, _WK_CRB_HX) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _wk_kf(t, _WK_CRB_T, _WK_CRB_BY), _wk_kf(t, _WK_CRB_T, _WK_CRB_BZ)))
	rot(P_LEG_L, Vector3(_wk_kf(t, _WK_CRB_T, _WK_CRB_GL) * DEG, 0, 0))
	rot(P_LEG_R, Vector3(_wk_kf(t, _WK_CRB_T, _WK_CRB_GR) * DEG, 0, 0))
	return 0.90


## Whirlwind: 2 s, three full spins of the body with the blade held out level (it keeps moving; an attack ends it).
func _wk_pose_whirlwind(t: float) -> float:
	var k := _wk_kf(t, _WK_WW_T, _WK_HOLD_V)
	var spin := TAU * 3.0 * smoothstep(0.10, 1.90, t)
	rot(P_ROOT, Vector3(0, -spin, 0))
	rot(P_ARM_R, Vector3(95.0 * DEG * k, 0, 0))
	rot(P_ARM_L, Vector3(76.0 * DEG * k, 0, 0))
	rot(P_CHEST, Vector3(8.0 * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, -0.06 * k, 0))
	return 2.0


## Arc Bolt: the staff cocks back while the crystal charges, then thrusts (0.20: a bright flare) with the free hand.
func _wk_pose_arc_bolt(t: float) -> float:
	rot(P_ARM_R, Vector3(_wk_kf(t, _WK_ARC_T, _WK_ARC_RX) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, 0, _wk_kf(t, _WK_ARC_T, _WK_ARC_RP)))
	rot(P_ARM_L, Vector3(_wk_kf(t, _WK_ARC_T, _WK_ARC_LX) * DEG, 0, 0))
	rot(P_CHEST, Vector3(0, _wk_kf(t, _WK_ARC_T, _WK_ARC_CY) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _wk_kf(t, _WK_ARC_T, _WK_ARC_BZ)))
	weapon_flare(0.8 * clampf(t / 0.20, 0.0, 1.0) if t < 0.20 else (1.0 if t < 0.24 else 0.0))
	return 0.60


## Slipstep: fades out in 0.1 s (a thin sliver, a crystal flash), gone 0.1 s, reappears with a small overshoot.
func _wk_pose_slipstep(t: float) -> float:
	var s: float
	if t < 0.10:
		s = 1.0 - _ease_out(t / 0.10)
	elif t < 0.20:
		s = 0.0
	elif t < 0.34:
		s = 1.08 * _ease_out((t - 0.20) / 0.14)
	else:
		s = lerpf(1.08, 1.0, clampf((t - 0.34) / 0.16, 0.0, 1.0))
	s = maxf(s, 0.02)
	_root_scale *= Vector3(s, lerpf(1.3, 1.0, minf(s, 1.0)) * s, s)
	rot(P_ARM_L, Vector3(-10.0 * DEG, 0, 0))
	weapon_flare(1.0 if t < 0.1 or (t >= 0.2 and t < 0.3) else 0.0)
	return 0.50


## Starfall: the staff is lifted high (arm up and out, the crystal over the head), the free hand to the sky, head
## back; the crystal blazes 0.3-0.95.
func _wk_pose_starfall(t: float) -> float:
	var k := _wk_kf(t, _WK_SF_T, _WK_HOLD_V)
	rot(P_ARM_R, Vector3(-30.0 * DEG * k, 0, 12.0 * DEG * k))
	pos(P_ARM_R, Vector3(0, 0.20 * k, 0.06 * k))
	rot(P_ARM_L, Vector3(-150.0 * DEG * k, 0, -25.0 * DEG * k))
	rot(P_HEAD, Vector3(-22.0 * DEG * k, 0, 0))
	rot(P_CHEST, Vector3(-8.0 * DEG * k, 0, 0))
	pos(P_ROOT, Vector3(0, 0.04 * k, 0))
	weapon_flare(k)
	return 1.20


# ================================================================ dances: internals (play_clip)

func _dn_init() -> void:
	var path := (String(get_script().resource_path) + "|" + scene_file_path).to_lower()
	_dn_style = 0
	if path.contains("/fire/") or path.contains("vessa"):
		_dn_style = 1
	elif path.contains("/ice/") or path.contains("torvald"):
		_dn_style = 2
	elif path.contains("/nature/") or path.contains("ysolde"):
		_dn_style = 3
	elif path.contains("/shadow/") or path.contains("malrik"):
		_dn_style = 4
	var hsh: int = absi(hash(get_instance_id()))
	_dn_tempo = _DN_TEMPO[_dn_style] * (0.93 + 0.14 * float(hsh % 97) / 96.0)
	_dn_ph = float((hsh / 97) % 100) / 100.0 * 4.0
	_dn_sc = maxf(body_height, 0.4) / 1.6
	var hip: float = 0.0
	if _piv[P_LEG_L]:
		hip = (_rest_pos[P_ROOT] + _rest_pos[P_HIPS] + _rest_pos[P_LEG_L]).y
	elif _piv[P_LEG_R]:
		hip = (_rest_pos[P_ROOT] + _rest_pos[P_HIPS] + _rest_pos[P_LEG_R]).y
	_dn_leg = hip if hip > 0.1 else 0.45 * maxf(body_height, 0.4)


## rot() in degrees, weighted.
func _dr(i: int, x: float, y: float, z: float, w: float) -> void:
	if _piv[i]:
		_off_rot[i] += Vector3(x, y, z) * (DEG * w)


## Lowers the hips by `d` (m) with the feet kept on the ground (rigid legs): the legs splay sideways (a plie) or
## fore / aft (`fore`, a kneel-like lunge). Deepest bend 70 deg.
func _dn_dip(d: float, w: float, fore: bool) -> void:
	var c: float = clampf(1.0 - maxf(d, 0.0) / _dn_leg, 0.34, 1.0)
	var a: float = acos(c) * w
	if _piv[P_ROOT]:
		_off_pos[P_ROOT].y -= _dn_leg * (1.0 - c) * w
	if fore:
		if _piv[P_LEG_L]:
			_off_rot[P_LEG_L].x -= a
		if _piv[P_LEG_R]:
			_off_rot[P_LEG_R].x += a
	else:
		if _piv[P_LEG_L]:
			_off_rot[P_LEG_L].z -= a
		if _piv[P_LEG_R]:
			_off_rot[P_LEG_R].z += a


## Hop: the whole body leaves the ground by h (m), legs straight.
func _dn_hop(h: float, w: float) -> void:
	if _piv[P_ROOT]:
		_off_pos[P_ROOT].y += h * w


## Victory: Fire hops and pumps both fists with a spin every 8 beats; Ice stands tall, one arm raised in a salute,
## heel rises and stiff quarter turns; Nature sways like a tree, arms up as branches, soft knee dips; Shadow crouches,
## shoulder shimmy and finger snaps, a slow sly creep and spin; neutral cheers with arms up and hops.
func _dn_victory(t: float, w: float) -> void:
	var b: float = t * _dn_tempo + _dn_ph
	var s: float = sin(PI * b)
	var bo: float = absf(s)
	var sc: float = _dn_sc
	match _dn_style:
		1:  # fire
			_dn_hop(0.07 * sc * bo, w)
			_dr(P_ARM_L, -150.0 + 35.0 * s, 0.0, -22.0, w)
			_dr(P_ARM_R, -150.0 - 35.0 * s, 0.0, 22.0, w)
			_dr(P_CHEST, -4.0, 12.0 * s, 0.0, w)
			_dr(P_HEAD, 10.0 * sin(TAU * b), 0.0, 6.0 * s, w)
			_dr(P_LEG_L, -14.0 * maxf(s, 0.0), 0.0, 0.0, w)
			_dr(P_LEG_R, -14.0 * maxf(-s, 0.0), 0.0, 0.0, w)
			_dr(P_ROOT, 0.0, 360.0 * smoothstep(7.0, 8.0, fmod(b, 8.0)), 0.0, w)
		2:  # ice
			var turn: float = 28.0 * clampf(1.8 * sin(PI * b * 0.25), -1.0, 1.0)
			_dn_hop(0.035 * sc * maxf(s, 0.0), w)
			_dr(P_CHEST, -8.0, 0.0, 0.0, w)
			_dr(P_HEAD, -12.0, 0.0, 0.0, w)
			_dr(P_ARM_R, -168.0 + 10.0 * maxf(s, 0.0), 0.0, 8.0, w)
			_dr(P_ARM_L, 12.0, 0.0, -30.0, w)
			_dr(P_ROOT, 0.0, turn, 0.0, w)
		3:  # nature
			_dn_dip(0.045 * sc * (0.5 + 0.5 * sin(TAU * b)), w, false)
			_dr(P_CHEST, 0.0, 0.0, 14.0 * s, w)
			_dr(P_HIPS, 0.0, 0.0, -6.0 * s, w)
			_dr(P_HEAD, 0.0, 0.0, 8.0 * sin(PI * b + 0.6), w)
			_dr(P_ARM_L, -145.0 + 15.0 * sin(PI * b + 0.8), 0.0, -(35.0 + 15.0 * s), w)
			_dr(P_ARM_R, -145.0 + 15.0 * sin(PI * b + 0.8), 0.0, 35.0 - 15.0 * s, w)
			_dr(P_ROOT, 0.0, 25.0 * sin(PI * b * 0.25), 0.0, w)
			if _piv[P_ROOT]:
				_off_pos[P_ROOT].x += 0.05 * sc * s * w
		4:  # shadow
			_dn_dip((0.07 + 0.025 * bo) * sc, w, true)
			_dr(P_CHEST, 12.0, 14.0 * sin(TAU * b), 0.0, w)
			_dr(P_HEAD, -6.0, 15.0 * sin(PI * b * 0.5), 12.0, w)
			_dr(P_ARM_L, -60.0 + 18.0 * s, 0.0, -10.0, w)
			_dr(P_ARM_R, -60.0 - 18.0 * s, 0.0, 10.0, w)
			_dr(P_ROOT, 0.0, 360.0 * smoothstep(6.0, 8.0, fmod(b, 8.0)), 0.0, w)
			if _piv[P_ROOT]:
				_off_pos[P_ROOT].x += 0.10 * sc * sin(PI * b * 0.25) * w
		_:  # neutral
			_dn_hop(0.05 * sc * bo, w)
			_dr(P_ARM_L, -155.0 + 20.0 * s, 0.0, -30.0, w)
			_dr(P_ARM_R, -155.0 - 20.0 * s, 0.0, 30.0, w)
			_dr(P_HEAD, 10.0 * sin(TAU * b), 0.0, 0.0, w)
			_dr(P_CHEST, -5.0, 8.0 * s, 0.0, w)
			_dr(P_ROOT, 0.0, 180.0 * smoothstep(7.0, 8.0, fmod(b, 8.0)) + 180.0 * smoothstep(3.0, 4.0, fmod(b, 8.0)), 0.0, w)


## "I give up": the arms fling open (the weapon is let go), a kneel, then hands up with a slow white-flag sway, the
## head shaking; every 4 beats a sigh (arms sag, chest slumps). Ice keeps its chin up, Shadow sinks lowest, Fire
## shakes its head hardest, Nature sways.
func _dn_surrender(t: float, w: float) -> void:
	var b: float = t * _dn_tempo * 0.5 + _dn_ph
	var sw: float = sin(PI * b)
	var fl: float = sin(PI * clampf(t / 0.6, 0.0, 1.0))
	var k: float = _ease_out(clampf((t - 0.35) / 0.8, 0.0, 1.0))
	var cyc: float = fmod(b, 4.0)
	var sigh: float = sin(PI * clampf(cyc - 3.0, 0.0, 1.0))
	var slump: float = _DN_SLUMP[_dn_style]
	var kneel: float = _DN_KNEEL[_dn_style]
	var shake: float = _DN_SHAKE[_dn_style]
	_dr(P_ARM_L, 25.0 * fl, 0.0, -55.0 * fl, w)
	_dr(P_ARM_R, 25.0 * fl, 0.0, 55.0 * fl, w)
	_dn_dip(kneel * _dn_leg * k, w, true)
	var ax: float = -155.0 * k * (1.0 - 0.35 * sigh)
	_dr(P_ARM_L, ax, 0.0, -(22.0 + 8.0 * sw) * k, w)
	_dr(P_ARM_R, ax, 0.0, (22.0 - 8.0 * sw) * k, w)
	_dr(P_CHEST, (8.0 + 12.0 * sigh) * slump * k, 0.0, (4.0 + (6.0 if _dn_style == 3 else 0.0)) * sw * k, w)
	_dr(P_HEAD, ((14.0 + 10.0 * sigh) * slump - (10.0 if _dn_style == 2 else 0.0)) * k, shake * sin(TAU * b) * k, 0.0, w)


## Random emote: one of 3 per play_clip call (spin & clap, wave, stomp march), with the kingdom flavour on top.
func _dn_random(t: float, w: float) -> void:
	var b: float = t * _dn_tempo + _dn_ph
	var s: float = sin(PI * b)
	var sc: float = _dn_sc
	var amp: float = _DN_AMP[_dn_style]
	match _dn_var:
		0:  # spin & clap
			var c: float = 0.5 + 0.5 * sin(TAU * b)
			_dr(P_ARM_L, -75.0, 0.0, 12.0 + 16.0 * c * amp, w)
			_dr(P_ARM_R, -75.0, 0.0, -(12.0 + 16.0 * c * amp), w)
			_dn_hop(0.03 * sc * absf(s) * amp, w)
			_dr(P_HEAD, 8.0 * sin(TAU * b), 0.0, 0.0, w)
			_dr(P_ROOT, 0.0, 360.0 * fmod(b, 4.0) / 4.0, 0.0, w)
		1:  # wave
			_dr(P_ARM_R, -165.0, 0.0, 20.0 + 28.0 * sin(TAU * b) * amp, w)
			_dr(P_ARM_L, 12.0, 0.0, -30.0, w)
			_dr(P_CHEST, 0.0, 0.0, 8.0 * s * amp, w)
			_dr(P_HEAD, 8.0 * sin(TAU * b), 0.0, 6.0 * s, w)
			_dn_dip(0.03 * sc * (0.5 + 0.5 * sin(TAU * b)), w, false)
		_:  # stomp march
			_dr(P_LEG_L, -38.0 * maxf(s, 0.0) * amp, 0.0, 0.0, w)
			_dr(P_LEG_R, -38.0 * maxf(-s, 0.0) * amp, 0.0, 0.0, w)
			_dn_hop(0.03 * sc * absf(s), w)
			_dr(P_ARM_L, -20.0 + 45.0 * s * amp, 0.0, -8.0, w)
			_dr(P_ARM_R, -20.0 - 45.0 * s * amp, 0.0, 8.0, w)
			_dr(P_CHEST, 0.0, 10.0 * s, 0.0, w)
			_dr(P_HEAD, 0.0, 12.0 * sin(PI * b * 0.5), 0.0, w)
	match _dn_style:
		2:
			_dr(P_CHEST, -6.0, 0.0, 0.0, w)
			_dr(P_HEAD, -8.0, 0.0, 0.0, w)
		3:
			_dr(P_CHEST, 0.0, 0.0, 8.0 * sin(PI * b * 0.5), w)
		4:
			_dr(P_CHEST, 8.0, 0.0, 0.0, w)
			_dn_dip(0.03 * sc, w, true)


# ================================================================ seated rider: internals (13.V1b)
# Private members of this feature all start with _rd_ (don't reuse the prefix in a unit script).

func _rd_apply_pending() -> void:
	var p: Array = _rd_pending
	_rd_pending = null
	var m: Variant = p[1]
	if m != null and not is_instance_valid(m):
		m = null
	set_seated(bool(p[0]), m as Node3D)
	match StringName(p[2]):
		&"mount":
			play_mount()
		&"dismount":
			play_dismount()
		&"thrown":
			play_thrown()


func _rd_start(act: StringName) -> void:
	_rd_act = act
	_rd_t = 0.0
	_rd_busy = true
	set_process(true)


## Back on foot at once (the pose returns to the standing one on the next animated frame).
func _rd_clear(emit: bool) -> void:
	var was: bool = _rd_on or _rd_act != &""
	_rd_mount = null
	_rd_on = false
	_rd_act = &""
	_rd_t = 0.0
	_rd_busy = false
	_par_id = get_instance_id()
	if not was:
		return
	process_priority = _rd_prio
	if _shadow:
		_shadow.visible = true
	_force_write = true
	if emit:
		dismount_finished.emit()


## play_death while seated: on a dying mount the rider rides its fall (the seat rolls with it); on a living one it is
## thrown and stays down.
func _rd_on_death() -> void:
	if not is_instance_valid(_rd_mount):
		if _rd_act != &"thrown":
			_rd_clear(false)
		return
	var cm := _rd_mount as CharacterModel
	if cm != null and cm._dead:
		if _rd_act == &"mount":
			_rd_act = &""
	elif _rd_act == &"" or _rd_act == &"mount":
		_rd_side = 1.0 if (hash(get_instance_id()) & 1) == 0 else -1.0
		_rd_start(&"thrown")


## Seated, every frame before the tier / freeze decision: the rider uses its mount's tier and half-rate parity, and
## animates whenever the mount does (it freezes with it beyond 45 m).
func _rd_sync() -> void:
	if not is_instance_valid(_rd_mount):
		if _rd_leaving():
			_rd_busy = true   # the mount vanished mid hop-off / thrown: finish on its last seat
		else:
			_rd_clear(false)
		return
	var cm := _rd_mount as CharacterModel
	if cm == null:
		_rd_busy = true
		return
	if cm._tier != _tier:
		_tier = cm._tier
		for p: GPUParticles3D in _loop_fx:
			p.emitting = _tier < 2
	_rd_busy = _rd_act != &"" or not cm._frozen


## The mount's Seat in this model's space (live), or 1.2 m over the mount's origin without a seat_transform().
func _rd_seat_frame() -> Transform3D:
	var s := Transform3D(Basis.IDENTITY, Vector3(0, 1.2, 0))
	if _rd_has_seat:
		s = _rd_mount.call(&"seat_transform")
	if is_inside_tree() and _rd_mount.is_inside_tree():
		return global_transform.affine_inverse() * _rd_mount.global_transform * s
	return s


## Leg splay (deg) that clears the mount's barrel around the seat: for the body-mesh vertices in the band a leg
## sweeps (below the seat, within the leg length, near the seat along the body), the angle from the hip joint that
## passes outside them; 90th percentile (fur locks / flaps may clip), clamped 12-50. Cached per mesh + rider size.
## -1 while the mount is not ready (measured on the next frame).
func _rd_measure_splay() -> float:
	if seat_leg_splay_deg > 0.0:
		return seat_leg_splay_deg
	var cm := _rd_mount as CharacterModel
	var leg: Node3D = _piv[P_LEG_L]
	if cm == null or leg == null:
		return 30.0
	if not cm._ready_done:
		return -1.0
	var body: MeshInstance3D = cm._merged_nodes.get(P_MOUNT)
	var seat := cm.get_node_or_null(^"Root/Mount/Seat") as Node3D
	if body == null or body.mesh == null or seat == null:
		return 30.0
	var lo := model_origin(leg)
	var hx: float = absf(lo.x)
	var lg: float = maxf(lo.y, 0.3)
	var sc: float = 1.0
	if is_inside_tree() and cm.is_inside_tree():
		sc = (global_transform.affine_inverse() * cm.global_transform).basis.get_scale().x
	var key := "%d|%.2f|%.2f|%.2f" % [body.mesh.get_instance_id(), hx, lg, sc]
	if _rd_splay_cache.has(key):
		return _rd_splay_cache[key]
	var sp := seat.position   # the body mesh and the Seat are both in the Mount pivot's space
	var needs := PackedFloat32Array()
	for s: int in body.mesh.get_surface_count():
		var verts: PackedVector3Array = body.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
		for v: Vector3 in verts:
			var dy: float = (sp.y - v.y) * sc
			if dy < 0.12 or dy > lg * 0.9 or absf(v.z - sp.z) * sc > 0.4:
				continue
			needs.append(atan2(absf(v.x - sp.x) * sc + 0.07 - hx, dy))
	var a: float = 30.0
	if not needs.is_empty():
		needs.sort()
		a = clampf(rad_to_deg(needs[int(float(needs.size() - 1) * 0.9)]), 12.0, 50.0)
	_rd_splay_cache[key] = a
	return a


## A hop-off or thrown tumble is playing (it finishes even when the mount node is freed meanwhile).
func _rd_leaving() -> bool:
	return _rd_act == &"dismount" or _rd_act == &"thrown"


static func _rd_bezier(a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return a * (u * u) + b * (2.0 * u * t) + c * (t * t)


## The seated pose of this frame (after the kit's idle / actions / hit / death offsets): Root placed so the Hips
## pivot sits on the Seat in its live frame (own Root motion damped), legs astride, hips locked, the hop / thrown
## paths, then _pose_seated. Ends the dismount / thrown (unseats, dismount_finished).
func _rd_pose(dt: float) -> void:
	var valid: bool = is_instance_valid(_rd_mount)
	if not valid and not _rd_leaving():
		_rd_clear(false)
		return
	if _rd_splay < 0.0:
		_rd_splay = _rd_measure_splay() if valid else 30.0
	_rd_t += dt
	var sf: Transform3D = _rd_seat_frame() if valid else _rd_last_sf
	_rd_last_sf = sf
	var bs := sf.basis.orthonormalized()
	var hs: Vector3 = sf.origin + bs * seat_offset
	var hip: Vector3 = _rest_pos[P_HIPS] if _piv[P_HIPS] else Vector3(0, body_height * 0.5, 0)
	var h0: Vector3 = _rest_pos[P_ROOT] + hip
	var side: Vector3 = -bs.x   # the mount's left flank
	_rd_seat_pitch = rad_to_deg(bs.get_euler().x)
	var gp: float = 0.0
	var gb: float = 0.0
	var mv: float = 0.0
	if valid:
		if _rd_has_gait:
			gp = float(_rd_mount.call(&"gait_phase"))
			gb = float(_rd_mount.call(&"gallop_blend"))
		var cm := _rd_mount as CharacterModel
		if cm:
			mv = cm._walk_w
	_rd_arm_w = move_toward(_rd_arm_w, 0.0 if _action != &"" or _dn_w > 0.0 else 1.0, dt / 0.12)
	var h := hs
	var b := bs
	var sw: float = 1.0          # astride / in-the-saddle weight
	# Share of the pose's own Root motion kept in the saddle: half of an attack / cast / hit lunge; none of the idle
	# bob (hips locked) or of the death fall (the rider rides the mount's fall, or is thrown).
	var own: float = 0.5 if not _dead and (_action != &"" or _hit_t < HIT_LEN) else 0.0
	var over: float = 0.0        # the far (right) leg swinging over the saddle
	var reach: float = 0.0       # hands on the saddle / pushing off
	var flail: float = 0.0
	var done: bool = false
	var t := _rd_t
	match _rd_act:
		&"mount":
			own = 0.0
			var dip: float = -0.07 * sin(PI * clampf(t / 0.07, 0.0, 1.0))
			var u: float = clampf((t - 0.05) / (MOUNT_HOP_LEN - 0.05), 0.0, 1.0)
			var e: float = smoothstep(0.0, 1.0, u)
			var p1: Vector3 = (h0 + hs) * 0.5 + side * 0.55 + Vector3(0, 0.5, 0)
			h = _rd_bezier(h0 + Vector3(0, dip, 0), p1, hs, e)
			b = Basis.IDENTITY.slerp(bs, e)
			sw = e
			over = sin(PI * u)
			reach = sin(PI * clampf(t / MOUNT_HOP_LEN, 0.0, 1.0))
			if t >= MOUNT_HOP_LEN:
				_rd_act = &""
		&"dismount":
			own = 0.0
			var u: float = clampf(t / 0.26, 0.0, 1.0)
			var e: float = smoothstep(0.0, 1.0, u)
			var p1: Vector3 = (hs + h0) * 0.5 + side * 0.6 + Vector3(0, 0.45, 0)
			h = _rd_bezier(hs, p1, h0, e)
			h.y -= 0.07 * sin(PI * clampf((t - 0.24) / 0.06, 0.0, 1.0))
			b = bs.slerp(Basis.IDENTITY, e)
			sw = 1.0 - e
			over = sin(PI * u)
			reach = 0.6 * sin(PI * u)
			done = t >= MOUNT_HOP_LEN
		&"thrown":
			own = 0.0
			var s := _rd_side
			var lie := Vector3(s * 0.85, maxf(0.15 * body_height, 0.18), hs.z * 0.5)
			var fl: float = clampf(t / 0.30, 0.0, 1.0)
			var roll: float = 270.0
			var pitch: float = 0.0
			if t < 0.30:
				h = _rd_bezier(hs, hs + Vector3(s * 0.45, 0.55, -0.05), lie, fl)
				roll = 270.0 * _ease_out(fl)
				pitch = -25.0 * sin(PI * fl)
				flail = sin(PI * fl)
			elif _dead or t < 0.36:
				h = lie + Vector3(0, 0.0 if _dead else 0.05 * sin(PI * clampf((t - 0.30) / 0.06, 0.0, 1.0)), 0)
			else:
				var g: float = smoothstep(0.0, 1.0, (t - 0.36) / (THROWN_LEN - 0.36))
				h = lie.lerp(h0, g)
				roll = 270.0 + 90.0 * g
			b = bs.slerp(Basis.IDENTITY, clampf(fl * 1.5, 0.0, 1.0)) * Basis(Vector3(0, 0, 1), -s * roll * DEG) \
				* Basis(Vector3(1, 0, 0), pitch * DEG)
			sw = 1.0 - smoothstep(0.0, 0.45, fl)
			done = t >= THROWN_LEN and not _dead
	# Root: the Hips pivot on the (animated) seat point, in the seat frame; the pose's own Root motion damped. Root
	# scale pulses (level-up, ice shatter) scale about the hips.
	var rb: Basis = b * Basis.from_euler(_off_rot[P_ROOT] * own)
	var ro: Vector3 = h + b * (_off_pos[P_ROOT] * own) - rb * (hip * _root_scale)
	_off_rot[P_ROOT] = rb.get_euler() - _rest_rot[P_ROOT]
	_off_pos[P_ROOT] = ro - _rest_pos[P_ROOT]
	# Hips locked, legs astride (the pose's own leg motion mostly replaced).
	var keep: float = 1.0 - 0.85 * sw
	_off_rot[P_HIPS] *= keep
	_off_pos[P_HIPS] *= keep
	var fwd: float = seat_leg_forward_deg * DEG
	var spl: float = maxf(_rd_splay, 0.0) * DEG
	_off_rot[P_LEG_L] = _off_rot[P_LEG_L] * keep + Vector3(-fwd, 0, -spl) * sw
	_off_rot[P_LEG_R] = _off_rot[P_LEG_R] * keep + Vector3(-fwd, 0, spl) * sw
	if over > 0.0:
		rot(P_LEG_R, Vector3(-30.0 * DEG * over, 0, 55.0 * DEG * over))
		rot(P_CHEST, Vector3(20.0 * DEG * over, 0, 0))
	if reach > 0.0:
		rot(P_ARM_L, Vector3(-65.0 * DEG * reach, 0, 12.0 * DEG * reach))
		rot(P_ARM_R, Vector3(-40.0 * DEG * reach, 0, 0))
	if flail > 0.0:
		var f := sin(TAU * 4.0 * t)
		rot(P_ARM_L, Vector3((-120.0 + 30.0 * f) * DEG * flail, 0, -25.0 * DEG * flail))
		rot(P_ARM_R, Vector3((-120.0 - 30.0 * f) * DEG * flail, 0, 25.0 * DEG * flail))
		rot(P_LEG_L, Vector3(30.0 * f * DEG * flail, 0, -20.0 * DEG * flail))
		rot(P_LEG_R, Vector3(-30.0 * f * DEG * flail, 0, 20.0 * DEG * flail))
		rot(P_HEAD, Vector3(20.0 * DEG * flail, 0, 0))
	if sw > 0.0:
		_pose_seated(sw, gp, gb, mv)
	if _shadow:
		_shadow.visible = sw < 0.5
	if done:
		_rd_clear(true)

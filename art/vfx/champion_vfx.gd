class_name ChampionVfx
extends Node3D
## Champion ability effects (task 9.V5, champions.md 4.3 / 4.6). Add ONE of these to a level, next to SpellVfx /
## CombatVfx / IceVfx / NatureVfx; it never edits gameplay code. It is in group "champion_vfx"; callers do
##   get_tree().get_first_node_in_group(&"champion_vfx").play(ability_id, caster, target_or_point)
## where target_or_point is a Node3D (unit) or a Vector3 (point). Unknown ids are ignored.
##   flare_arrow      glowing amber arrow on an arc; at the point a burst, a blast ring (r 2), then a flare light-ball
##                    hanging 3 m up for 6 s over a warm light pool with a dashed rim at the vision radius (8 m).
##                    No real light.
##   snare_line       a leather rope whips out and snaps onto the target; two rope coils bind its feet (1.5 s).
##   trailblaze       a golden wind ring races out to 8 m; a golden trail follows the Wayfinder for the haste (5 s).
##   oath_of_iron     steel-blue shockwave to 6 m, a steel ward ring at the Oathwall's feet (armour, 3 s), a taunt
##                    badge over every enemy non-wizard unit within 6 m (3 s; dropped early if it is not taunted).
##   shield_bash      a steel impact star on the target + three daze stars circling its head (0.8 s).
##   bulwark_stand    the shield slams down: shockwave, then a planted riveted shield dome r 5 for 6 s.
##   cutpurse         gold coins and sparks burst from the hit.
##   smoke_pouch      a charcoal smoke puff filling r 3 for 3 s with a soot smudge; wisps trail the Coin-Cutter.
##   marked_for_coin  a flipped coin lands above the target and keeps spinning there for 6 s (gold ward at its feet).
##   mending_draught  a green splash on the healed unit, a "+", and motes rising around it.
##   soothing_circle  a green heal circle r 5 for 5 s (leaf ring, one pulse per heal tick) with rising motes.
##   lifeline         a green-gold light thread to the ally, then a shield bubble around it for 5 s (pops when the
##                    shield breaks).
## Class skills (task 11.V6, skills-rework.md 4.2; class colours: Spear teal, Sword and Shield brass, Two-Hand
## crimson, Wizard arcane blue (0.6, 0.75, 1.0)):
##   lunge            a teal speed streak from where the champion stood to the target (play() is called BEFORE the
##                    dash), a dust kick, an impact star, two daze stars (0.5 s, the `dazed` status).
##   hobbling_javelin a javelin flies on the Projectile's path (24 m/s, arc 0.35); on the hit sparks, a dust puff,
##                    then a scuffed hobble ring + dust at the target's feet while it has `smoulder` (3 s).
##   skewer           a thrust flash and a glowing ground line 5 m toward the point (or unit), sparks along it and
##                    on every enemy unit in the 5 x 1 m line.
##   riposte          a brass lattice shimmer around the champion for 4 s; counter sparks on each melee attacker it
##                    hits back (ChampionAbilities.skill_hit, else damage_taken from within 3.2 m).
##   second_wind      a pale wind ring at its feet, rising spiral wisps for 4 s and one breath pulse per heal tick.
##   shield_throw     a spinning shield flies to the target, bounces to up to 2 enemy units within 4 m (the same
##                    pick as the gameplay: nearest, not hit before) with sparks at each, then back to the hand.
##   cleave           a crimson blade crescent round the target (r 2.5), a shock ring, sparks on each splashed unit.
##   crushing_blow    radial ground cracks with glowing seams, dust, flying armor shards; on a unit a cracked-armor
##                    badge for 6 s (buildings: the impact only).
##   whirlwind        a band of spinning blade arcs r 3 around the champion + a whirl ring and dust for 2 s; sparks
##                    on each unit it hits.
##   arc_bolt         a crackling blue bolt on the Projectile's path (28 m/s, arc 0.3), sparks + shock ring on hit.
##   slipstep         a ghost column fading at the old spot with a sigil, a streak to the point (play() is called
##                    BEFORE the jump), a sigil + reappear flash there.
##   starfall         a warning ring r 3.5 with a closing ring (1.0 s, shown to whoever sees the spot), a star falls
##                    into it, impact at 1.0 s (flash, shockwave, sparks, dust), a starry scorch fading 1.4 s.
##   class_chosen     a 1 s ring of light in the class colour at the champion's feet, rising motes and the class
##                    emblem popping over its head (the class is read from caster.class_id()).
## The Mage Archer (task 13b.V8, tier3-extras.md 6.5 / 12; violet (0.70, 0.30, 1.00)): arcane_arrow, sable_shaft,
## grave_mark, eclipse_volley, unique_call, unique_revive. They live in art/vfx/champion_mage_archer_vfx.gd
## (ChampionMageArcherVfx, created here in _ready; its pools, bursts and streams are built with these), see its header.
## Effects on a unit follow it and end cleanly (0.25 s fade) when it dies or leaves the tree. Hidden units / points in
## the local team's fog show nothing. When the target Unit reports the status (`rooted`, `dazed`, `taunted`,
## `marked`, `shield`) the effect ends with it (a hero's halved root, a broken shield); nothing ever outlives its
## spec duration.
## Budget: everything is pre-built at _ready and pooled (ground discs, flares, icons, coins, domes, bubbles, ropes,
## arrows, class ground marks, class bolts / streaks, the thrown shield, shells, class badges, one-shot bursts
## restarted, continuous streams that stop at the effect's end). One material per shader, looks
## set with instance uniforms: no material, mesh or node is created after _ready. No lights, no shadows.

const GROUP := &"champion_vfx"
const ABILITIES: Array[StringName] = [&"flare_arrow", &"snare_line", &"trailblaze", &"oath_of_iron", &"shield_bash",
		&"bulwark_stand", &"cutpurse", &"smoke_pouch", &"marked_for_coin", &"mending_draught", &"soothing_circle",
		&"lifeline"]
## The 12 class skill ids (skills-rework.md 4.2) + the class-choice ring (task 11.V6).
const CLASS_ABILITIES: Array[StringName] = [&"lunge", &"hobbling_javelin", &"skewer", &"riposte", &"second_wind",
		&"shield_throw", &"cleave", &"crushing_blow", &"whirlwind", &"arc_bolt", &"slipstep", &"starfall",
		&"class_chosen"]

# Palette (champions.md 4.1 / 4.6), as they should look on screen.
const AMBER := Color(1.0, 0.8, 0.4)           # Wayfinder lantern / projectile
const STEEL := Color(0.6, 0.85, 1.0)          # Oathwall shield rune
const GOLD := Color(1.0, 0.85, 0.3)           # Coin-Cutter coin belt
const BRASS := Color(0.70, 0.55, 0.25)
const CHARCOAL := Color(0.16, 0.15, 0.17)
const BURGUNDY := Color(0.45, 0.12, 0.14)
const MEND := Color(0.5, 1.0, 0.6)            # Mender censer / projectile
const DAZE := Color(1.0, 0.9, 0.45)
# Class colours (task 11.V6).
const SPEAR_C := Color(0.5, 0.95, 0.85)       # Spear: keen teal wind
const SHIELD_C := Color(1.0, 0.84, 0.5)       # Sword and Shield: polished brass
const GREAT_C := Color(1.0, 0.42, 0.24)       # Two-Hand Sword: crimson-orange
const ARCANE := Color(0.6, 0.75, 1.0)         # Wizard: the staff crystal / bolt colour (skills-rework.md 5)
const BREATH := Color(0.88, 1.0, 0.82)        # Second Wind
const CLASS_COLORS := {&"spear": SPEAR_C, &"sword_shield": SHIELD_C, &"two_hand": GREAT_C, &"wizard": ARCANE}
const CLASS_ICONS := {&"spear": 0.0, &"sword_shield": 1.0, &"two_hand": 2.0, &"wizard": 3.0}

# Numbers from champions.md 4.3.
const FLARE_TIME := 6.0
const FLARE_SIGHT := 8.0
const FLARE_BLAST := 2.0
const ROOT_TIME := 1.5
const TRAIL_RADIUS := 8.0
const HASTE_TIME := 5.0
const OATH_RADIUS := 6.0
const TAUNT_TIME := 3.0
const DAZE_TIME := 0.8
const BULWARK_RADIUS := 5.0
const BULWARK_TIME := 6.0
const SMOKE_RADIUS := 3.0
const SMOKE_TIME := 3.0
const MARK_TIME := 6.0
const CIRCLE_RADIUS := 5.0
const CIRCLE_TIME := 5.0
const CIRCLE_SHOW := 0.7        # the lasting heal circle's radius vs CIRCLE_RADIUS (the cast ring shows the full reach)
const CIRCLE_ENERGY := 0.45     # its tint (was 1.4: a bright 5 m disc over the fight)
const LIFELINE_TIME := 5.0
# Numbers from skills-rework.md 4.2.
const LUNGE_GAP := 1.0
const LUNGE_DAZE := 0.5
const JAVELIN_SPEED := 24.0
const JAVELIN_ARC := 0.35
const HOBBLE_TIME := 3.0
const SKEWER_LENGTH := 5.0
const SKEWER_HALF_WIDTH := 0.5
const RIPOSTE_TIME := 4.0
const RIPOSTE_MELEE := 3.2
const SECOND_WIND_TIME := 4.0
const SECOND_WIND_TICKS := 8
const SHIELD_SPEED := 22.0
const SHIELD_BOUNCES := 2
const BOUNCE_RADIUS := 4.0
const CLEAVE_RADIUS := 2.5
const CRUSH_TIME := 6.0
const WHIRL_TIME := 2.0
const WHIRL_RADIUS := 3.0
const ARC_SPEED := 28.0
const ARC_ARC := 0.3
const STAR_DELAY := 1.0
const STAR_RADIUS := 3.5
const PROJECTILE_AIM := 1.0      # Projectile._target_offset on a unit: the flying pieces follow the same path
const MAX_HIT_SPARKS := 6

const MAX_TAUNT_MARKS := 12
const END_FADE := 0.25           # fade when the unit an effect sits on dies
const CHECK_INTERVAL := 0.25     # fog / status checks per effect
const STATUS_GRACE := 0.3        # the status may be applied just after play()
const FOG_RESCAN := 1.0

enum { A_POINT, A_TARGET, A_CASTER, A_ARROW, A_WORLD }
enum { VIS_TARGET, VIS_CASTER, VIS_POINT }
enum { G_SHOCK, G_WIND, G_HEAL, G_ROPE, G_GLOW, G_SOOT, G_WARD }

## Mesh pools (pre-built): pool -> size.
const POOL_SIZES := {&"disc": 34, &"flare": 28, &"icon": 36, &"dome": 3, &"bubble": 6, &"coin": 10, &"rope": 6,
		&"bolt": 6, &"cdisc": 22, &"cbolt": 12, &"shield": 3, &"shell": 6, &"cicon": 10}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness].
const BURSTS := {
	&"amber_cast": [14, 0.5, &"add_dot", 3, 0.9],
	&"amber_sparks": [28, 0.6, &"streak", 3, 0.95],
	&"amber_embers": [16, 1.3, &"add_dot", 3, 0.8],
	&"rope_dust": [10, 0.8, &"mix_dot", 3, 0.9],
	&"gold_wind": [40, 0.75, &"streak", 3, 0.95],
	&"gold_motes": [24, 1.1, &"add_star", 3, 0.7],
	&"stomp_dust": [20, 1.1, &"mix_dot", 4, 0.9],
	&"steel_sparks": [26, 0.5, &"streak", 4, 0.95],
	&"bash_sparks": [18, 0.4, &"streak", 4, 1.0],
	&"coins": [14, 1.1, &"mix_coin", 4, 0.95],
	&"gold_sparks": [16, 0.45, &"streak", 4, 1.0],
	&"smoke_big": [26, 3.0, &"mix_smoke", 3, 0.85],
	&"smoke_pop": [14, 1.0, &"mix_smoke", 3, 1.0],
	&"green_puff": [12, 0.6, &"add_dot", 5, 0.9],
	&"green_splash": [22, 0.85, &"add_drop", 4, 0.95],
	&"plus": [2, 0.9, &"add_plus", 6, 0.9],
	&"gg_sparkle": [16, 0.9, &"add_star", 4, 0.8],
	&"bubble_pop": [20, 0.5, &"add_dot", 3, 1.0],
	&"coin_glint": [10, 0.7, &"add_star", 6, 0.9],
	# Class skills (11.V6). Looks aimed with a direction use local -Z as "forward".
	&"dash_dust": [14, 0.8, &"mix_dot", 3, 0.95],
	&"wind_streaks": [22, 0.45, &"streak", 3, 0.9],
	&"teal_hit": [18, 0.4, &"streak", 8, 1.0],
	&"line_sparks": [34, 0.5, &"streak", 2, 0.9],
	&"hobble_dust": [12, 0.9, &"mix_dot", 3, 0.9],
	&"counter_sparks": [16, 0.35, &"streak", 6, 1.0],
	&"clash_glint": [3, 0.3, &"add_star", 6, 1.0],
	&"breath_ring": [18, 0.7, &"add_dot", 3, 0.95],
	&"breath_pulse": [8, 0.8, &"add_dot", 6, 0.9],
	&"great_sparks": [20, 0.45, &"streak", 8, 1.0],
	&"crack_dust": [18, 1.2, &"mix_dot", 3, 0.9],
	&"armor_shards": [12, 1.0, &"mix_shard", 3, 0.95],
	&"arc_sparks": [22, 0.45, &"streak", 4, 1.0],
	&"arc_motes": [18, 0.8, &"add_star", 5, 0.85],
	&"star_blast": [36, 0.7, &"streak", 2, 1.0],
	&"star_dust": [22, 1.4, &"mix_dot", 2, 0.9],
	&"cls_spear": [22, 1.1, &"add_dot", 2, 0.75],
	&"cls_sword_shield": [22, 1.1, &"add_dot", 2, 0.75],
	&"cls_two_hand": [22, 1.1, &"add_dot", 2, 0.75],
	&"cls_wizard": [22, 1.1, &"add_star", 2, 0.75],
}
## Continuous streams (pre-built, stopped at the effect's end): look -> [amount, lifetime, draw pass, cap, local].
const STREAMS := {
	&"amber_trail": [40, 0.45, &"add_dot", 6, false],
	&"flare_drip": [14, 1.6, &"add_star", 6, false],
	&"gold_trail": [18, 0.8, &"add_dot", 6, false],
	&"smoke_wisps": [10, 1.1, &"mix_smoke", 6, false],
	&"heal_motes": [14, 1.0, &"add_dot", 8, true],
	&"circle_motes": [34, 1.5, &"add_dot", 4, false],
	&"javelin_trail": [30, 0.3, &"add_dot", 4, false],
	&"hobble_feet": [8, 0.8, &"mix_dot", 6, false],
	&"rise_wisps": [16, 1.2, &"streak", 4, false],
	&"whirl_dust": [16, 0.7, &"mix_dot", 4, false],
	&"arc_trail": [36, 0.35, &"add_dot", 4, false],
	&"star_trail": [40, 0.5, &"add_star", 2, false],
	&"shield_trail": [24, 0.25, &"add_dot", 3, false],
}
## Emitters whose particles spread far from the emitter node (trails left behind, wide blasts): bigger culling box.
const WIDE_LOOKS: Array[StringName] = [&"smoke_big", &"circle_motes", &"amber_trail", &"gold_wind", &"line_sparks",
		&"star_blast", &"star_dust", &"whirl_dust", &"javelin_trail", &"arc_trail", &"star_trail", &"shield_trail",
		&"wind_streaks"]

const GROUND_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const ICON_SHADER := preload("res://art/vfx/champion_icon.gdshader")
const DOME_SHADER := preload("res://art/vfx/champion_dome.gdshader")
const COIN_SHADER := preload("res://art/vfx/champion_coin.gdshader")
const ROPE_SHADER := preload("res://art/vfx/champion_rope.gdshader")
const BOLT_SHADER := preload("res://art/vfx/champion_bolt.gdshader")
const STREAK_SHADER := preload("res://art/vfx/combat_streak.gdshader")
const CLASS_GROUND_SHADER := preload("res://art/vfx/champion_class_ground.gdshader")
const CLASS_BOLT_SHADER := preload("res://art/vfx/champion_class_bolt.gdshader")
const CLASS_SHIELD_SHADER := preload("res://art/vfx/champion_class_shield.gdshader")
const CLASS_SHELL_SHADER := preload("res://art/vfx/champion_class_shell.gdshader")
const CLASS_ICON_SHADER := preload("res://art/vfx/champion_class_icon.gdshader")

# Class ground patterns (champion_class_ground.gdshader).
enum { C_CRACK, C_WHIRL, C_STAR, C_CLASS, C_LINE, C_CRESCENT, C_SIGIL, C_HOBBLE, C_BURN }


## One running effect. Pieces are pooled meshes, streams pooled continuous emitters, bursts scheduled one-shots.
class Fx:
	extends RefCounted
	var id: StringName
	var t := 0.0
	var dur := 1.0
	var caster: Node3D
	var target: Node3D
	var has_target := false
	var cpos := Vector3.ZERO
	var tpos := Vector3.ZERO
	var point := Vector3.ZERO
	var team := -1
	var dep := 0                 # 1: ends when the target dies, 2: when the caster dies
	var vis := 0                 # VIS_TARGET / VIS_CASTER / VIS_POINT
	var status := &""            # status on the target that this effect shows
	var status_max := 0.0
	var tail := 0.2
	var pop_look := &""          # burst when it ends early
	var end_at := -1.0
	var shown := true
	var check_left := 0.0
	var pieces: Array[Piece] = []
	var streams: Array[Dictionary] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0
	var data: Dictionary = {}
	var dep_at := 0.0            # the death check (dep) only runs from this time on (after a flight)
	var status_at := 0.0         # the status check only runs from this time on (a status applied on landing)
	var hook_src: Object         # a signal this effect listens to (Riposte / Whirlwind hits), disconnected at the end
	var hook_sig := &""
	var hook_cb: Callable
	var hit_look := &""
	var hits_left := 0
	var ext: Callable            # (fx, delta) called at the start of each tick (effects that follow a bow, 13b.V8)
	var ext_end: Callable        # (fx) called when the effect ends early (a death while marked, 13b.V8)


## One pooled mesh of an effect: when it shows (on / off, off <= 0 = relative to the effect's end), where (anchor +
## offset lerped from o0), how it grows (s0 -> s1 over `grow`), how it fades, plus the fields of its motion mode.
class Piece:
	extends RefCounted
	var n: GeometryInstance3D
	var pool: StringName
	var is_disc := false
	var at := 0
	var ofs := Vector3.ZERO
	var o0 := Vector3.ZERO
	var on := 0.0
	var off := 0.0
	var fin := 0.0
	var fout := 0.0
	var s0 := Vector3.ONE
	var s1 := Vector3.ONE
	var grow := 0.0
	var back := false
	var mode := &""
	var lf := -1.0               # last fade sent
	var lr := -1.0               # last radius sent
	var ph := 0.0                # orbit / bob phase
	var orad := 0.3              # orbit radius
	var bh := 1.0                # rope: target end height
	var ext := 0.12              # rope: time to reach the target
	var wave := 0.0              # rope: whip amplitude (m)
	var width := 0.6             # rope: quad width (m)
	var a := Vector3.ZERO        # rope: last caster end
	var has_a := false
	var from := Vector3.ZERO     # toss: start
	var time := 0.3              # toss: flight time
	var rot := Basis.IDENTITY    # turn of a static piece (class ground lines, crescents)
	var ln := 1.0                # home: axial length (m)
	var pts: Array = []          # path: waypoints (Node3D or Vector3)
	var pfb: Array[Vector3] = [] # path: last known position of each waypoint
	var phs: Array[float] = []   # path: aim height of each waypoint
	var pts_t: Array[float] = [] # path: arrival time at each waypoint


var _fx: Array[Fx] = []
var _free: Dictionary = {}          # pool -> Array[GeometryInstance3D]
var _all: Dictionary = {}           # pool -> Array[GeometryInstance3D]
var _bursts: Dictionary = {}        # look -> Array[GPUParticles3D]
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []   # {p, left}
var _stream_free: Dictionary = {}   # look -> Array[GPUParticles3D]
var _cooling: Array[Dictionary] = []       # {e, look, left}
var _pmats: Dictionary = {}
var _passes: Dictionary = {}
var _fog: Node
var _fog_left := 0.0
var _layer := 0
var _unique: ChampionMageArcherVfx   # the Mage Archer's effects (13b.V8)


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true                  # effects are placed in world space
	global_transform = Transform3D.IDENTITY
	_unique = ChampionMageArcherVfx.new(self)
	_build_shared()


func _process(delta: float) -> void:
	_fog_left -= delta
	if _fog_left <= 0.0:
		_fog_left = FOG_RESCAN
		_fog = get_tree().get_first_node_in_group(&"fog")
	for i in range(_fx.size() - 1, -1, -1):
		var fx := _fx[i]
		if _tick(fx, delta):
			_finish(fx)
			_fx.remove_at(i)
	for i in range(_cooling.size() - 1, -1, -1):
		var c: Dictionary = _cooling[i]
		c["left"] = float(c["left"]) - delta
		if float(c["left"]) <= 0.0:
			var e: GPUParticles3D = c["e"]
			e.visible = false
			(_stream_free[c["look"]] as Array).append(e)
			_cooling.remove_at(i)
	for i in range(_live_bursts.size() - 1, -1, -1):
		var b: Dictionary = _live_bursts[i]
		b["left"] = float(b["left"]) - delta
		if float(b["left"]) <= 0.0:
			var p: GPUParticles3D = b["p"]
			p.emitting = false
			p.visible = false
			_live_bursts.remove_at(i)


# ---------------------------------------------------------------- public API

## Plays the effect of `ability_id` (champions.md 4.3, skills-rework.md 4.2, or `class_chosen`). `target_or_point`:
## a Node3D (unit) or a Vector3 (self abilities may pass the caster). For `class_chosen` it may also be the class id
## (StringName); by default the class is read from `caster.class_id()`.
func play(ability_id: StringName, caster: Node3D, target_or_point: Variant) -> void:
	if not is_node_ready() or not is_inside_tree() or not (ABILITIES.has(ability_id)
			or CLASS_ABILITIES.has(ability_id) or ChampionMageArcherVfx.IDS.has(ability_id)):
		return
	var c: Node3D = caster if is_instance_valid(caster) and caster.is_inside_tree() else null
	var t: Node3D = null
	if typeof(target_or_point) == TYPE_OBJECT and is_instance_valid(target_or_point) and target_or_point is Node3D:
		t = target_or_point as Node3D
		if not t.is_inside_tree():
			t = null
	var point: Vector3
	if t:
		point = t.global_position
	elif target_or_point is Vector3:
		point = target_or_point
	elif c:
		point = c.global_position
	else:
		return
	if t == c:
		t = null   # self abilities may pass the caster as the target
	var fx := _new_fx(ability_id, c, t, point)
	match ability_id:
		&"flare_arrow": _flare_arrow(fx)
		&"snare_line": _snare_line(fx)
		&"trailblaze": _trailblaze(fx)
		&"oath_of_iron": _oath_of_iron(fx)
		&"shield_bash": _shield_bash(fx)
		&"bulwark_stand": _bulwark_stand(fx)
		&"cutpurse": _cutpurse(fx)
		&"smoke_pouch": _smoke_pouch(fx)
		&"marked_for_coin": _marked_for_coin(fx)
		&"mending_draught": _mending_draught(fx)
		&"soothing_circle": _soothing_circle(fx)
		&"lifeline": _lifeline(fx)
		&"lunge": _lunge(fx)
		&"hobbling_javelin": _hobbling_javelin(fx)
		&"skewer": _skewer(fx)
		&"riposte": _riposte(fx)
		&"second_wind": _second_wind(fx)
		&"shield_throw": _shield_throw(fx)
		&"cleave": _cleave(fx)
		&"crushing_blow": _crushing_blow(fx)
		&"whirlwind": _whirlwind(fx)
		&"arc_bolt": _arc_bolt(fx)
		&"slipstep": _slipstep(fx)
		&"starfall": _starfall(fx)
		&"class_chosen":
			var cls := StringName(target_or_point) if target_or_point is StringName or target_or_point is String \
					else _class_of(c)
			_class_chosen(fx, cls)
		_:
			_unique.build(fx)
	_start(fx)


## Number of running effects (taunt badges count one each).
func active_count() -> int:
	return _fx.size()


## Ids of the running effects (taunt badges show as &"taunt_mark").
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pooled pieces still on screen + emitters still alive (0 once everything has ended).
func live_count() -> int:
	var n := _live_bursts.size() + _cooling.size()
	for fx in _fx:
		n += fx.streams.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	return n


# ---------------------------------------------------------------- the 12 effects

func _flare_arrow(fx: Fx) -> void:
	var p := fx.point
	var o := _hand(fx.caster, p, 1.0) if is_instance_valid(fx.caster) else p + Vector3(-3.0, 5.0, 3.0)
	var dist := o.distance_to(p)
	var ft := clampf(dist / 26.0, 0.25, 0.85)
	var apex := clampf(dist * 0.28, 1.0, 6.0)
	fx.data = {"o": o, "p": p, "ft": ft, "apex": apex, "arrow_pos": o}
	fx.dur = ft + FLARE_TIME
	fx.vis = VIS_POINT
	var up := Vector3.UP
	_sched(fx, &"amber_cast", 0.0, A_WORLD, o)
	var arrow := _piece(fx, &"bolt", A_ARROW, Vector3.ZERO, 0.0, ft, 0.0, 0.0)
	_mode(arrow, &"arrow")
	_params(arrow, {&"tint": _hdr(AMBER, 2.2)})
	_stream(fx, &"amber_trail", 0.0, ft + 0.02, A_ARROW, Vector3.ZERO)
	# Landing: blast ring (damage radius 2), star flash, sparks and embers.
	_sched(fx, &"amber_sparks", ft, A_POINT, up * 0.25)
	_sched(fx, &"amber_embers", ft, A_POINT, up * 0.4)
	_disc(fx, A_POINT, G_SHOCK, _hdr(AMBER, 1.8), 0.3, FLARE_BLAST * 1.1, 0.35, ft, ft + 0.55, 0.0, 0.3)
	_flare(fx, A_POINT, up * 0.8, _hdr(AMBER, 2.6), 2.0, 3.0, 0.25, ft, ft + 0.3, 0.0, 0.22, 1.0, 4.0)
	# The flare: shoots up to 3.2 m and burns there for 6 s over a warm pool the size of the vision radius.
	var ball := _flare(fx, A_POINT, up * 3.2, _hdr(AMBER, 2.6), 0.4, 2.1, 0.4, ft + 0.02, 0.0, 0.05, 0.8, 0.45, 6.0, 1.0)
	if ball:
		ball.o0 = up * 0.6
		ball.back = true
	_disc(fx, A_POINT, G_GLOW, _hdr(AMBER, 1.2), 2.0, FLARE_SIGHT, 0.5, ft + 0.02, 0.0, 0.2, 0.8)
	_stream(fx, &"flare_drip", ft + 0.35, -0.7, A_POINT, up * 3.1)


func _snare_line(fx: Fx) -> void:
	var h := _h(fx.target)
	var ext := 0.12
	fx.dep = 1 if fx.has_target else 0
	fx.dur = ext + ROOT_TIME
	fx.status = &"rooted"
	fx.status_max = fx.dur
	fx.tail = 0.25
	if is_instance_valid(fx.caster):
		var rope := _piece(fx, &"rope", A_TARGET, Vector3.ZERO, 0.0, 0.5, 0.0, 0.18)
		_mode(rope, &"rope", {"bh": h * 0.55, "ext": ext, "wave": 0.22, "width": 0.8})
		_params(rope, {&"tint": _hdr(AMBER, 1.6), &"style": 0.0})
	var rr := _r(fx.target) * 1.9 + 0.45
	_disc(fx, A_TARGET, G_ROPE, _hdr(AMBER, 1.5), rr * 1.6, rr, 0.14, ext, 0.0, 0.04, 0.25)
	_sched(fx, &"rope_dust", ext, A_TARGET, Vector3.UP * 0.1)
	_flare(fx, A_TARGET, Vector3.UP * h * 0.55, _hdr(AMBER, 2.2), 0.9, 1.3, 0.15, ext, ext + 0.22, 0.0, 0.15, 0.8, 4.0)


func _trailblaze(fx: Fx) -> void:
	var h := _h(fx.caster)
	fx.dep = 2 if is_instance_valid(fx.caster) else 0
	fx.dur = HASTE_TIME
	fx.vis = VIS_CASTER
	_disc(fx, A_POINT, G_WIND, _hdr(GOLD, 2.0), 0.8, TRAIL_RADIUS, 0.6, 0.0, 1.0, 0.0, 0.45)
	_disc(fx, A_POINT, G_SHOCK, _hdr(GOLD, 1.4), 0.4, 2.4, 0.3, 0.0, 0.5, 0.0, 0.3)
	_sched(fx, &"gold_wind", 0.0, A_POINT, Vector3.UP * 0.3)
	_sched(fx, &"gold_motes", 0.05, A_POINT, Vector3.UP * 0.2)
	_flare(fx, A_CASTER, Vector3.UP * h * 0.6, _hdr(GOLD, 2.4), 1.2, 1.8, 0.2, 0.0, 0.3, 0.0, 0.2, 0.8, 4.0)
	_stream(fx, &"gold_trail", 0.0, 0.0, A_CASTER, Vector3.UP * 0.12)


func _oath_of_iron(fx: Fx) -> void:
	var h := _h(fx.caster)
	var r := _r(fx.caster)
	fx.dep = 2 if is_instance_valid(fx.caster) else 0
	fx.dur = TAUNT_TIME
	fx.vis = VIS_CASTER
	fx.tail = 0.4
	_disc(fx, A_POINT, G_SHOCK, _hdr(STEEL, 1.7), 0.5, OATH_RADIUS, 0.45, 0.0, 0.8, 0.0, 0.35)
	_disc(fx, A_POINT, G_SHOCK, _hdr(STEEL, 0.9), 0.4, OATH_RADIUS * 0.7, 0.5, 0.12, 0.85, 0.0, 0.4)
	var ward := r * 2.0 + 0.6
	_disc(fx, A_CASTER, G_WARD, _hdr(STEEL, 1.2), ward * 1.4, ward, 0.2, 0.0, 0.0, 0.1, 0.4)
	_sched(fx, &"stomp_dust", 0.0, A_POINT, Vector3.UP * 0.15)
	_sched(fx, &"steel_sparks", 0.0, A_POINT, Vector3.UP * 0.25)
	_flare(fx, A_CASTER, Vector3.UP * h * 0.55, _hdr(STEEL, 2.6), 2.0, 2.8, 0.2, 0.0, 0.3, 0.0, 0.22, 1.0, 4.0)
	# Taunt badges: each is its own small effect on its unit (so it follows it and ends with it).
	if not is_instance_valid(fx.caster):
		return
	for u in _taunt_targets(fx.caster, fx.cpos):
		var m := _new_fx(&"taunt_mark", fx.caster, u, u.global_position)
		m.dep = 1
		m.dur = TAUNT_TIME
		m.status = &"taunted"
		m.status_max = TAUNT_TIME
		m.tail = 0.25
		var dd := u.global_position - fx.cpos
		dd.y = 0.0
		var delay := clampf(dd.length() / OATH_RADIUS, 0.0, 1.0) * 0.4   # pops when the shockwave reaches it
		var ic := _piece(m, &"icon", A_TARGET, Vector3.UP * (_h(u) + 0.95), delay, 0.0, 0.05, 0.25)
		_grow(ic, 0.2, 0.85, 0.2, true)
		_params(ic, {&"icon": 0.0, &"tint": _hdr(STEEL, 2.2), &"seed": randf() * 6.0})
		_start(m)


func _shield_bash(fx: Fx) -> void:
	var h := _h(fx.target)
	var r := _r(fx.target)
	fx.dep = 1 if fx.has_target else 0
	fx.dur = 0.05 + DAZE_TIME + 0.1
	fx.status = &"dazed"
	fx.status_max = fx.dur
	fx.tail = 0.15
	var hit := Vector3.UP * h * 0.55 + _toward(fx.tpos, fx.cpos) * r
	_flare(fx, A_TARGET, hit, _hdr(STEEL, 2.2), 1.0, 1.6, 0.12, 0.0, 0.28, 0.0, 0.2, 1.2, 4.0)
	_disc(fx, A_TARGET, G_SHOCK, _hdr(STEEL, 1.3), 0.3, r * 2.0 + 0.8, 0.25, 0.0, 0.4, 0.0, 0.25)
	_sched(fx, &"bash_sparks", 0.0, A_TARGET, hit)
	for i in 3:
		var st := _piece(fx, &"icon", A_TARGET, Vector3.UP * (h + 0.25), 0.05, 0.0, 0.08, 0.15)
		_grow(st, 0.14, 0.44, 0.12, true)
		_mode(st, &"orbit", {"ph": TAU * float(i) / 3.0, "orad": 0.28 + r * 0.25})
		_params(st, {&"icon": 1.0, &"tint": _hdr(DAZE, 1.8), &"seed": float(i) * 2.1})


func _bulwark_stand(fx: Fx) -> void:
	var h := _h(fx.caster)
	fx.dep = 2 if is_instance_valid(fx.caster) else 0
	fx.dur = BULWARK_TIME
	fx.vis = VIS_CASTER
	fx.tail = 0.5
	var big := BULWARK_RADIUS
	var dome := _piece(fx, &"dome", A_CASTER, Vector3.ZERO, 0.0, 0.0, 0.03, 0.5)
	_grow(dome, Vector3(1.0, 0.6, 1.0), Vector3(big, big * 0.62, big), 0.35, true)
	_params(dome, {&"style": 0.0, &"tint": _hdr(STEEL, 1.2), &"seed": randf()})
	_disc(fx, A_CASTER, G_WARD, _hdr(STEEL, 1.4), 1.0, big, 0.35, 0.0, 0.0, 0.05, 0.5)
	_disc(fx, A_POINT, G_SHOCK, _hdr(STEEL, 1.6), 0.5, big + 0.6, 0.35, 0.0, 0.6, 0.0, 0.3)
	_sched(fx, &"stomp_dust", 0.0, A_POINT, Vector3.UP * 0.15, 1.3)
	_sched(fx, &"steel_sparks", 0.0, A_POINT, Vector3.UP * 0.25)
	_flare(fx, A_CASTER, Vector3.UP * h * 0.5, _hdr(STEEL, 2.6), 2.2, 3.0, 0.2, 0.0, 0.3, 0.0, 0.22, 1.0, 4.0)


func _cutpurse(fx: Fx) -> void:
	var h := _h(fx.target)
	var hit := Vector3.UP * h * 0.55 + _toward(fx.tpos, fx.cpos) * _r(fx.target)
	fx.dur = 0.4                     # bursts only: a killing blow still shows its coins
	_sched(fx, &"coins", 0.0, A_TARGET, hit)
	_sched(fx, &"gold_sparks", 0.0, A_TARGET, hit)
	_flare(fx, A_TARGET, hit, _hdr(GOLD, 2.6), 1.2, 1.7, 0.1, 0.0, 0.25, 0.0, 0.18, 1.0, 4.0)


func _smoke_pouch(fx: Fx) -> void:
	fx.dur = SMOKE_TIME              # the smoke stays where the pouch burst, even if she dies
	fx.vis = VIS_CASTER
	_sched(fx, &"smoke_pop", 0.0, A_POINT, Vector3.UP * 0.8)
	_sched(fx, &"smoke_big", 0.02, A_POINT, Vector3.UP * 0.9)
	_disc(fx, A_POINT, G_SOOT, CHARCOAL.srgb_to_linear(), 1.2, SMOKE_RADIUS * 1.05, 0.45, 0.0, 0.0, 0.1, 0.9)
	_flare(fx, A_POINT, Vector3.UP * 0.9, Color(1.1, 1.05, 1.0), 1.0, 1.8, 0.12, 0.0, 0.18, 0.0, 0.12)
	_stream(fx, &"smoke_wisps", 0.1, -0.25, A_CASTER, Vector3.UP * 0.9)


func _marked_for_coin(fx: Fx) -> void:
	var h := _h(fx.target)
	var r := _r(fx.target)
	var mh := h + 0.95
	var toss := 0.3 if is_instance_valid(fx.caster) else 0.0
	fx.dep = 1 if fx.has_target else 0
	fx.dur = toss + MARK_TIME
	fx.status = &"marked"
	fx.status_max = fx.dur
	fx.tail = 0.3
	fx.pop_look = &"coin_glint"
	fx.data["pop_h"] = mh
	if toss > 0.0:
		var flip := _piece(fx, &"coin", A_TARGET, Vector3.UP * mh, 0.0, toss, 0.0, 0.0)
		_grow(flip, 0.18, 0.18, 0.0)
		_mode(flip, &"toss", {"from": _hand(fx.caster, fx.tpos), "time": toss})
		_params(flip, {&"spin": 26.0, &"energy": 1.6, &"phase": randf() * TAU})
	var ph := randf() * TAU
	var glow := _flare(fx, A_TARGET, Vector3.UP * mh, _hdr(GOLD, 1.0), 1.1, 1.1, 0.0, toss, 0.0, 0.1, 0.3, 0.35, 8.0, 0.3)
	_mode(glow, &"bob", {"ph": ph})
	var coin := _piece(fx, &"coin", A_TARGET, Vector3.UP * mh, toss, 0.0, 0.04, 0.3)
	_grow(coin, 0.12, 0.4, 0.22, true)
	_mode(coin, &"bob", {"ph": ph})
	_params(coin, {&"spin": 3.2, &"energy": 1.5, &"phase": randf() * TAU})
	var ward := r * 1.9 + 0.4
	_disc(fx, A_TARGET, G_WARD, _hdr(GOLD, 1.0), ward * 1.5, ward, 0.2, toss, 0.0, 0.15, 0.3)
	_sched(fx, &"coin_glint", toss, A_TARGET, Vector3.UP * mh)


func _mending_draught(fx: Fx) -> void:
	var h := _h(fx.target)
	fx.dep = 1 if fx.has_target else 0
	fx.dur = 1.3
	if is_instance_valid(fx.caster):
		_sched(fx, &"green_puff", 0.0, A_WORLD, _hand(fx.caster, fx.tpos))
	_sched(fx, &"green_splash", 0.0, A_TARGET, Vector3.UP * h * 0.55)
	_sched(fx, &"plus", 0.05, A_TARGET, Vector3.UP * (h + 0.25))
	_flare(fx, A_TARGET, Vector3.UP * h * 0.55, _hdr(MEND, 2.2), 1.3, 1.9, 0.15, 0.0, 0.28, 0.0, 0.2, 0.6, 4.0)
	_disc(fx, A_TARGET, G_SHOCK, _hdr(MEND, 1.4), 0.3, _r(fx.target) * 2.0 + 1.0, 0.3, 0.0, 0.45, 0.0, 0.3)
	_stream(fx, &"heal_motes", 0.0, 1.0, A_TARGET, Vector3.UP * 0.05, clampf(h / 1.6, 0.8, 2.0))


func _soothing_circle(fx: Fx) -> void:
	fx.dur = CIRCLE_TIME
	fx.vis = VIS_POINT
	# In-game grade 2026-09-30: the 5 m green disc hid the fight under it (Ice vs Nature). The cast ring still shows
	# the real reach (5 m: the heal lands on the allies inside it at the cast) for 0.6 s; the circle that stays for
	# the heal ticks is a soft 70 % marker under the bloom level (it only says "healing here").
	_disc(fx, A_POINT, G_HEAL, _hdr(MEND, CIRCLE_ENERGY), 0.5, CIRCLE_RADIUS * CIRCLE_SHOW, 0.35, 0.0, 0.0, 0.1, 0.6)
	_disc(fx, A_POINT, G_SHOCK, _hdr(MEND, 1.0), 0.4, CIRCLE_RADIUS + 0.3, 0.4, 0.0, 0.6, 0.0, 0.3)
	if is_instance_valid(fx.caster):
		_sched(fx, &"green_puff", 0.0, A_WORLD, _hand(fx.caster, fx.point))
	_sched(fx, &"green_puff", 0.05, A_POINT, Vector3.UP * 0.4, 2.5)
	_stream(fx, &"circle_motes", 0.1, -0.5, A_POINT, Vector3.UP * 0.1)


func _lifeline(fx: Fx) -> void:
	var h := _h(fx.target)
	var r := _r(fx.target)
	fx.dep = 1 if fx.has_target else 0
	fx.dur = LIFELINE_TIME
	fx.status = &"shield"
	fx.status_max = fx.dur
	fx.tail = 0.35
	fx.pop_look = &"bubble_pop"
	fx.data["pop_h"] = h * 0.5
	var gg := GOLD.lerp(MEND, 0.5)
	if is_instance_valid(fx.caster):
		var thread := _piece(fx, &"rope", A_TARGET, Vector3.ZERO, 0.0, 0.4, 0.0, 0.15)
		_mode(thread, &"rope", {"bh": h * 0.55, "ext": 0.1, "wave": 0.0, "width": 0.45})
		_params(thread, {&"tint": _hdr(gg, 2.2), &"style": 1.0})
	var s1 := Vector3(r * 2.1 + 0.5, h * 0.6 + 0.3, r * 2.1 + 0.5)
	var bub := _piece(fx, &"bubble", A_TARGET, Vector3.UP * h * 0.5, 0.08, 0.0, 0.03, 0.35)
	_grow(bub, s1 * 0.3, s1, 0.25, true)
	_params(bub, {&"style": 1.0, &"tint": _hdr(MEND, 1.2), &"tint2": _hdr(GOLD, 1.2), &"seed": randf()})
	_sched(fx, &"gg_sparkle", 0.08, A_TARGET, Vector3.UP * h * 0.5)
	_flare(fx, A_TARGET, Vector3.UP * h * 0.55, _hdr(gg, 2.0), 1.2, 1.8, 0.15, 0.08, 0.35, 0.0, 0.2, 0.6, 4.0)


## Enemy non-wizard units within the Oath radius (the gameplay taunts them; the badge drops if it did not).
func _taunt_targets(c: Node3D, center: Vector3) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var team: Variant = c.get(&"team")
	if team == null:
		return out
	var reach := OATH_RADIUS + 0.5
	for node in get_tree().get_nodes_in_group(&"units"):
		if node == c or not node is Node3D:
			continue
		var u := node as Node3D
		var ut: Variant = u.get(&"team")
		if ut == null or int(ut) == int(team):
			continue
		if u is Wizard or u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes") or not _alive(u):
			continue
		var d := u.global_position - center
		d.y = 0.0
		if d.length_squared() > reach * reach:
			continue
		out.append(u)
		if out.size() >= MAX_TAUNT_MARKS:
			break
	return out


# ---------------------------------------------------------------- the 12 class skills + class_chosen (11.V6)

## Lunge (play() comes BEFORE the dash): a teal speed streak from where it stood to where it strikes (the caster's
## new spot, else the predicted one 1 m before the target), a dust kick, an impact star, daze stars (0.5 s).
func _lunge(fx: Fx) -> void:
	var start := fx.cpos
	var ch := _h(fx.caster)
	var tp := fx.tpos
	var dir := _toward(start, tp)
	if dir == Vector3.ZERO:
		dir = _facing(fx.caster)
	var back := Vector3(start.x - tp.x, 0.0, start.z - tp.z)
	var gap := maxf(LUNGE_GAP, _r(fx.caster) + _r(fx.target) + 0.1)
	var end := start
	if back.length() > gap + 0.05:
		end = Vector3(tp.x, start.y, tp.z) + back.normalized() * gap
	var h := _h(fx.target)
	var tr := _r(fx.target)
	fx.dur = 0.2 + LUNGE_DAZE + 0.05
	fx.dep = 1 if fx.has_target else 0
	fx.dep_at = 0.3                  # the streak finishes even when the strike kills
	fx.status = &"dazed"
	fx.status_max = fx.dur
	fx.tail = 0.1
	var streak := _piece(fx, &"cbolt", A_WORLD, Vector3.ZERO, 0.0, 0.34, 0.0, 0.22)
	_mode(streak, &"dash", {"from": start + Vector3.UP * ch * 0.5, "a": end + Vector3.UP * ch * 0.5, "bh": ch * 0.5,
			"ext": 0.07, "width": 1.0, "has_a": true})
	_params(streak, {&"style": 2.0, &"tint": _hdr(SPEAR_C, 2.0), &"seed": randf() * 10.0})
	if start.distance_to(end) > 0.4:
		_line(fx, start, end + dir * 0.4, 0.45, C_LINE, _hdr(SPEAR_C, 1.3), 0.0, 0.6, 0.02, 0.4)
	_sched(fx, &"dash_dust", 0.0, A_WORLD, start + Vector3.UP * 0.1)
	_sched(fx, &"wind_streaks", 0.06, A_WORLD, end + Vector3.UP * ch * 0.5, 1.0, dir)
	var hit := Vector3.UP * h * 0.55 - dir * tr
	_flare(fx, A_TARGET, hit, _hdr(SPEAR_C.lerp(Color.WHITE, 0.3), 2.4), 0.9, 1.5, 0.1, 0.06, 0.3, 0.0, 0.18, 1.1, 4.0)
	_sched(fx, &"teal_hit", 0.07, A_TARGET, hit)
	for i in 2:
		var st := _piece(fx, &"icon", A_TARGET, Vector3.UP * (h + 0.25), 0.1, 0.0, 0.06, 0.12)
		_grow(st, 0.12, 0.38, 0.1, true)
		_mode(st, &"orbit", {"ph": PI * float(i), "orad": 0.25 + tr * 0.25})
		_params(st, {&"icon": 1.0, &"tint": _hdr(DAZE, 1.8), &"seed": float(i) * 2.7})


## Hobbling Javelin: a javelin on the Projectile's path (24 m/s, arc 0.35, aimed 1 m up the target); on the hit
## sparks and a dust puff, then the hobble (scuffed ring + dust at the feet) while the target has `smoulder`.
func _hobbling_javelin(fx: Fx) -> void:
	var from := _hand(fx.caster, fx.tpos, 0.75) if is_instance_valid(fx.caster) else fx.tpos + Vector3(-3.0, 3.0, 3.0)
	var aim := Vector3.UP * PROJECTILE_AIM
	var ft := maxf(0.15, from.distance_to(fx.tpos + aim) / JAVELIN_SPEED)
	var rr := _r(fx.target) * 1.7 + 0.45
	fx.dur = ft + HOBBLE_TIME
	fx.dep = 1 if fx.has_target else 0
	fx.dep_at = ft                   # a target that dies in flight: the javelin still lands where it was
	fx.status = &"smoulder"
	fx.status_at = ft
	fx.status_max = fx.dur
	fx.tail = 0.3
	var jav := _piece(fx, &"cbolt", A_TARGET, aim, 0.0, ft, 0.0, 0.0)
	_mode(jav, &"home", {"from": from, "time": ft, "wave": JAVELIN_ARC, "ln": 1.7, "width": 0.42})
	_params(jav, {&"style": 0.0, &"tint": _hdr(SPEAR_C, 1.8), &"seed": randf() * 10.0})
	_stream(fx, &"javelin_trail", 0.0, ft + 0.02, A_ARROW, Vector3.ZERO)
	_sched(fx, &"teal_hit", ft, A_TARGET, aim)
	_sched(fx, &"hobble_dust", ft, A_TARGET, Vector3.UP * 0.1)
	_flare(fx, A_TARGET, aim, _hdr(SPEAR_C, 2.2), 0.8, 1.3, 0.1, ft, ft + 0.25, 0.0, 0.15, 0.8, 4.0)
	_cdisc(fx, A_TARGET, Vector3.ZERO, C_HOBBLE, _hdr(SPEAR_C, 1.0), rr * 1.4, rr, 0.2, ft, 0.0, 0.1, 0.3)
	_stream(fx, &"hobble_feet", ft + 0.05, -0.3, A_TARGET, Vector3.UP * 0.05)


## Skewer: a thrust flash and a glowing ground line from the champion 5 m toward the point (or unit), sparks along
## the line and on every enemy unit in the 5 x 1 m line (the gameplay's own test: centre line, radius + 5 m).
func _skewer(fx: Fx) -> void:
	var c := fx.cpos
	var cr := _r(fx.caster)
	var ch := _h(fx.caster)
	var dir := _toward(c, fx.tpos)
	if dir == Vector3.ZERO:
		dir = _facing(fx.caster)
	var reach := cr + SKEWER_LENGTH
	var to := c + dir * reach
	fx.dur = 0.75
	fx.vis = VIS_CASTER
	_line(fx, c + dir * cr * 0.5, to, SKEWER_HALF_WIDTH + 0.1, C_LINE, _hdr(SPEAR_C, 1.6), 0.0, 0.75, 0.02, 0.5)
	var th := _piece(fx, &"cbolt", A_WORLD, Vector3.ZERO, 0.0, 0.4, 0.0, 0.25)
	_mode(th, &"dash", {"from": c + Vector3.UP * ch * 0.55, "a": to + Vector3.UP * ch * 0.45, "ext": 0.07,
			"width": 0.8})
	_params(th, {&"style": 3.0, &"tint": _hdr(SPEAR_C, 2.0), &"seed": randf() * 10.0})
	_sched(fx, &"line_sparks", 0.03, A_WORLD, (c + to) * 0.5 + Vector3.UP * 0.6, 1.0, dir)
	_flare(fx, A_WORLD, to + Vector3.UP * ch * 0.45, _hdr(SPEAR_C.lerp(Color.WHITE, 0.3), 2.4), 0.8, 1.4, 0.1, 0.06,
			0.3, 0.0, 0.18, 1.0, 4.0)
	var n := 0
	for node in get_tree().get_nodes_in_group(&"units"):
		if n >= MAX_HIT_SPARKS:
			break
		if node == fx.caster or not _is_enemy_of(node, fx.team):
			continue
		var u := node as Node3D
		var rel := u.global_position - c
		rel.y = 0.0
		var t := rel.dot(dir)
		if t < 0.0 or t > reach + _r(u) or (rel - dir * t).length() > SKEWER_HALF_WIDTH + _r(u):
			continue
		_sched(fx, &"teal_hit", 0.04 + t / 70.0, A_WORLD, u.global_position + Vector3.UP * _h(u) * 0.55)
		n += 1


## Riposte: a brass lattice shimmer round the champion for 4 s; counter sparks on each attacker it hits back.
func _riposte(fx: Fx) -> void:
	var h := _h(fx.caster)
	var r := _r(fx.caster)
	fx.dep = 2 if is_instance_valid(fx.caster) else 0
	fx.dur = RIPOSTE_TIME
	fx.vis = VIS_CASTER
	fx.tail = 0.35
	var s1 := Vector3(r * 2.2 + 0.35, h * 0.62 + 0.15, r * 2.2 + 0.35)
	var sh := _piece(fx, &"shell", A_CASTER, Vector3.UP * h * 0.5, 0.0, 0.0, 0.05, 0.35)
	_grow(sh, s1 * 0.6, s1, 0.18, true)
	_params(sh, {&"style": 0.0, &"tint": _hdr(SHIELD_C, 1.1), &"seed": randf() * 6.0})
	var ward := r * 1.9 + 0.5
	_disc(fx, A_CASTER, G_WARD, _hdr(SHIELD_C, 0.8), ward * 1.4, ward, 0.2, 0.0, 0.0, 0.1, 0.35)
	_disc(fx, A_POINT, G_SHOCK, _hdr(SHIELD_C, 1.4), 0.3, r * 2.0 + 1.6, 0.3, 0.0, 0.45, 0.0, 0.3)
	_flare(fx, A_CASTER, Vector3.UP * h * 0.6, _hdr(SHIELD_C, 2.4), 1.4, 2.1, 0.15, 0.0, 0.3, 0.0, 0.2, 1.2, 4.0)
	_sched(fx, &"clash_glint", 0.0, A_CASTER, Vector3.UP * h * 0.7)
	_hook_hits(fx, &"counter_sparks", true)


## Second Wind: a pale wind ring at its feet, spiral wisps rising for 4 s, a breath pulse per heal tick (8).
func _second_wind(fx: Fx) -> void:
	var h := _h(fx.caster)
	var r := _r(fx.caster)
	var sc := clampf(h / 1.6, 0.8, 2.0)
	fx.dep = 2 if is_instance_valid(fx.caster) else 0
	fx.dur = SECOND_WIND_TIME
	fx.vis = VIS_CASTER
	fx.tail = 0.4
	var rr := r * 2.0 + 1.0
	_disc(fx, A_CASTER, G_WIND, _hdr(BREATH, 1.3), rr * 0.4, rr, 0.4, 0.0, 0.0, 0.1, 0.5)
	_flare(fx, A_CASTER, Vector3.UP * h * 0.55, _hdr(BREATH, 2.0), 1.2, 2.0, 0.25, 0.0, 0.4, 0.0, 0.25, 0.6, 6.0)
	_sched(fx, &"breath_ring", 0.0, A_CASTER, Vector3.UP * 0.3)
	_stream(fx, &"rise_wisps", 0.05, -0.4, A_CASTER, Vector3.ZERO, sc)
	for i in SECOND_WIND_TICKS:
		_sched(fx, &"breath_pulse", SECOND_WIND_TIME / float(SECOND_WIND_TICKS) * (float(i) + 0.5), A_CASTER,
				Vector3.UP * 0.1, sc)


## Shield Throw: a spinning shield flies to the target, bounces to up to 2 enemy units within 4 m (nearest first,
## never twice), sparks at each, then flies back to the hand.
func _shield_throw(fx: Fx) -> void:
	var has_c := is_instance_valid(fx.caster)
	var from := _hand(fx.caster, fx.tpos, 0.7) if has_c else fx.point + Vector3(-3.0, 2.0, 3.0)
	var pts: Array = [from]
	var hs: Array[float] = [0.0]
	var hit: Array[Node3D] = []
	if fx.has_target:
		pts.append(fx.target)
		hs.append(_h(fx.target) * 0.55)
		hit.append(fx.target)
	else:
		pts.append(fx.point)
		hs.append(1.0)
	var last := fx.tpos
	for i in SHIELD_BOUNCES:
		var nxt := _nearest_enemy(last, BOUNCE_RADIUS, fx.team, hit, fx.caster)
		if nxt == null:
			break
		hit.append(nxt)
		pts.append(nxt)
		hs.append(_h(nxt) * 0.55)
		last = nxt.global_position
	var n_hits := pts.size() - 1
	if has_c:
		pts.append(fx.caster)
		hs.append(_h(fx.caster) * 0.6)
	var fb: Array[Vector3] = []
	for i in pts.size():
		fb.append(_pt_pos(pts[i], hs[i]))
	var times: Array[float] = [0.0]
	var total := 0.0
	for i in range(1, pts.size()):
		total += maxf(0.08, fb[i - 1].distance_to(fb[i]) / SHIELD_SPEED)
		times.append(total)
	fx.dur = total + 0.2
	var sh := _piece(fx, &"shield", A_WORLD, Vector3.ZERO, 0.0, total, 0.03, 0.08)
	if sh:
		sh.mode = &"path"
		sh.pts = pts
		sh.phs = hs
		sh.pfb = fb
		sh.pts_t = times
		_grow(sh, Vector3(0.55, 1.0, 0.55), Vector3(0.55, 1.0, 0.55), 0.0)
		_params(sh, {&"tint": _hdr(SHIELD_C, 1.5), &"spin": 3.2, &"seed": randf()})
	var glow := _flare(fx, A_WORLD, Vector3.ZERO, _hdr(SHIELD_C, 1.3), 1.5, 1.5, 0.0, 0.0, total, 0.03, 0.08, 0.6, 4.0)
	_mode(glow, &"ride")
	_stream(fx, &"shield_trail", 0.0, total, A_ARROW, Vector3.ZERO)
	for i in range(1, 1 + n_hits):
		_sched(fx, &"counter_sparks", times[i], A_WORLD, fb[i], 1.2)
		_sched(fx, &"clash_glint", times[i], A_WORLD, fb[i], 1.2)
	if has_c:
		_sched(fx, &"clash_glint", total, A_CASTER, Vector3.UP * _h(fx.caster) * 0.6, 0.7)


## Cleave (on the empowered hit): a crimson blade crescent round the target (r 2.5), a shock ring, sparks on the
## target and on each enemy unit within 2.5 m of it.
func _cleave(fx: Fx) -> void:
	var h := _h(fx.target)
	var r := _r(fx.target)
	var dir := _toward(fx.cpos, fx.tpos)
	if dir == Vector3.ZERO:
		dir = _facing(fx.caster)
	fx.dur = 0.6
	var big := CLEAVE_RADIUS + r
	var cres := _cdisc(fx, A_WORLD, fx.tpos + Vector3.UP * 0.75, C_CRESCENT, _hdr(GREAT_C, 2.0), big * 0.75, big, 0.14,
			0.0, 0.5, 0.0, 0.3)
	if cres:
		cres.rot = _yaw_basis(dir)
	_disc(fx, A_TARGET, G_SHOCK, _hdr(GREAT_C, 1.4), 0.4, big, 0.3, 0.02, 0.45, 0.0, 0.3)
	var hit := Vector3.UP * h * 0.55 - dir * r
	_flare(fx, A_TARGET, hit, _hdr(GREAT_C.lerp(Color.WHITE, 0.25), 2.4), 1.0, 1.7, 0.1, 0.0, 0.28, 0.0, 0.2, 1.2, 4.0)
	_sched(fx, &"great_sparks", 0.0, A_TARGET, hit)
	var n := 0
	for node in get_tree().get_nodes_in_group(&"units"):
		if n >= MAX_HIT_SPARKS:
			break
		if node == fx.target or node == fx.caster or not _is_enemy_of(node, fx.team):
			continue
		var u := node as Node3D
		var dd := u.global_position - fx.tpos
		dd.y = 0.0
		if dd.length() > CLEAVE_RADIUS + _r(u):
			continue
		_sched(fx, &"great_sparks", 0.05 + dd.length() * 0.02, A_WORLD, u.global_position + Vector3.UP * _h(u) * 0.55, 0.8)
		n += 1


## Crushing Blow: radial ground cracks with glowing seams, dust, an impact star; on a unit flying armor shards and
## a cracked-armor badge for the 6 s of `ability:crush` (a building: the impact only).
func _crushing_blow(fx: Fx) -> void:
	var h := _h(fx.target)
	var r := _r(fx.target)
	var is_unit := fx.has_target and fx.target.is_in_group(&"units") and not fx.target.is_in_group(&"buildings")
	var dir := _toward(fx.cpos, fx.tpos)
	fx.dur = 0.1 + CRUSH_TIME if is_unit else 1.4
	fx.dep = 1 if is_unit else 0
	fx.dep_at = 1.2                  # the cracks stay even if the blow kills
	fx.tail = 0.3
	var cr := r * 1.2 + 1.7
	_cdisc(fx, A_WORLD, fx.tpos, C_CRACK, _hdr(GREAT_C, 1.6), cr * 0.55, cr, 0.1, 0.0, 1.4, 0.0, 0.6)
	var hit := Vector3.UP * h * 0.5 - dir * r
	_flare(fx, A_TARGET, hit, _hdr(GREAT_C.lerp(Color.WHITE, 0.3), 2.6), 1.4, 2.4, 0.12, 0.0, 0.3, 0.0, 0.22, 1.3, 6.0)
	_disc(fx, A_TARGET, G_SHOCK, _hdr(GREAT_C, 0.7), 0.3, cr + 0.8, 0.25, 0.0, 0.35, 0.0, 0.25)
	_sched(fx, &"crack_dust", 0.0, A_TARGET, Vector3.UP * 0.15)
	_sched(fx, &"great_sparks", 0.0, A_TARGET, hit)
	if not is_unit:
		return
	_sched(fx, &"armor_shards", 0.02, A_TARGET, Vector3.UP * h * 0.6)
	var badge := _piece(fx, &"cicon", A_TARGET, Vector3.UP * (h + 0.8), 0.12, 0.0, 0.05, 0.3)
	_grow(badge, 0.2, 0.62, 0.22, true)
	_params(badge, {&"icon": 4.0, &"tint": _hdr(GREAT_C, 2.0), &"seed": randf() * 6.0})


## Whirlwind: a band of blade arcs spinning r 3 round the champion, a whirl ring and dust at its feet for 2 s,
## sparks on each unit it hits (ChampionAbilities.skill_hit).
func _whirlwind(fx: Fx) -> void:
	var h := _h(fx.caster)
	fx.dep = 2 if is_instance_valid(fx.caster) else 0
	fx.dur = WHIRL_TIME
	fx.vis = VIS_CASTER
	fx.tail = 0.3
	var band := _piece(fx, &"shell", A_CASTER, Vector3.UP * h * 0.45, 0.0, 0.0, 0.06, 0.25)
	_grow(band, Vector3(1.2, 0.3, 1.2), Vector3(WHIRL_RADIUS, 0.45, WHIRL_RADIUS), 0.15, false)
	_params(band, {&"style": 2.0, &"tint": _hdr(GREAT_C, 1.6), &"seed": randf()})
	_cdisc(fx, A_CASTER, Vector3.ZERO, C_WHIRL, _hdr(GREAT_C, 1.5), 1.0, WHIRL_RADIUS, 0.2, 0.0, 0.0, 0.06, 0.3)
	_disc(fx, A_POINT, G_SHOCK, _hdr(GREAT_C, 1.3), 0.4, WHIRL_RADIUS + 0.4, 0.3, 0.0, 0.45, 0.0, 0.3)
	_stream(fx, &"whirl_dust", 0.0, -0.2, A_CASTER, Vector3.UP * 0.1)
	_hook_hits(fx, &"great_sparks", false)


## Arc Bolt: a crackling blue bolt on the Projectile's path (28 m/s, arc 0.3), sparks and a shock ring on the hit.
func _arc_bolt(fx: Fx) -> void:
	var from := _hand(fx.caster, fx.tpos, 0.75) if is_instance_valid(fx.caster) else fx.tpos + Vector3(-3.0, 3.0, 3.0)
	var aim := Vector3.UP * PROJECTILE_AIM
	var ft := maxf(0.15, from.distance_to(fx.tpos + aim) / ARC_SPEED)
	var r := _r(fx.target)
	fx.dur = ft + 0.5
	var bolt := _piece(fx, &"cbolt", A_TARGET, aim, 0.0, ft, 0.0, 0.0)
	_mode(bolt, &"home", {"from": from, "time": ft, "wave": ARC_ARC, "ln": 1.2, "width": 0.6})
	_params(bolt, {&"style": 1.0, &"tint": _hdr(ARCANE, 2.0), &"seed": randf() * 10.0})
	_stream(fx, &"arc_trail", 0.0, ft + 0.02, A_ARROW, Vector3.ZERO)
	_sched(fx, &"arc_motes", 0.0, A_WORLD, from, 0.6)
	_flare(fx, A_WORLD, from, _hdr(ARCANE, 2.4), 0.6, 1.1, 0.1, 0.0, 0.22, 0.0, 0.15, 0.8, 4.0)
	_sched(fx, &"arc_sparks", ft, A_TARGET, aim)
	_sched(fx, &"arc_motes", ft, A_TARGET, aim, 0.8)
	_flare(fx, A_TARGET, aim, _hdr(ARCANE, 2.6), 1.1, 1.9, 0.12, ft, ft + 0.3, 0.0, 0.2, 1.2, 6.0)
	_disc(fx, A_TARGET, G_SHOCK, _hdr(ARCANE, 1.4), 0.3, r * 2.0 + 1.1, 0.3, ft, ft + 0.45, 0.0, 0.3)


## Slipstep (play() comes BEFORE the jump; target = the landing point): a ghost column fading where it stood over
## a sigil, a streak to the point, a sigil and a reappear flash there.
func _slipstep(fx: Fx) -> void:
	var start := fx.cpos
	var dest := fx.tpos
	var h := _h(fx.caster)
	var r := _r(fx.caster)
	fx.dur = 0.9
	fx.vis = VIS_POINT
	var col := Vector3(r * 1.6 + 0.3, h * 0.6 + 0.1, r * 1.6 + 0.3)
	var ghost := _piece(fx, &"shell", A_WORLD, start + Vector3.UP * h * 0.5, 0.0, 0.45, 0.0, 0.4)
	_grow(ghost, col, col * Vector3(0.6, 1.25, 0.6), 0.45, false)
	_params(ghost, {&"style": 1.0, &"tint": _hdr(ARCANE, 1.5), &"seed": randf()})
	_cdisc(fx, A_WORLD, start, C_SIGIL, _hdr(ARCANE, 1.6), 0.4, r * 2.0 + 0.8, 0.15, 0.0, 0.6, 0.0, 0.4)
	_sched(fx, &"arc_motes", 0.0, A_WORLD, start + Vector3.UP * h * 0.5)
	if start.distance_to(dest) > 0.5:
		var sk := _piece(fx, &"cbolt", A_WORLD, Vector3.ZERO, 0.02, 0.26, 0.0, 0.18)
		_mode(sk, &"dash", {"from": start + Vector3.UP * h * 0.5, "a": dest + Vector3.UP * h * 0.5, "ext": 0.08,
				"width": 0.7})
		_params(sk, {&"style": 2.0, &"tint": _hdr(ARCANE, 1.8), &"seed": randf() * 10.0})
	_cdisc(fx, A_POINT, Vector3.ZERO, C_SIGIL, _hdr(ARCANE, 1.6), 0.4, r * 2.0 + 0.8, 0.15, 0.05, 0.0, 0.0, 0.5)
	var app := _piece(fx, &"shell", A_POINT, Vector3.UP * h * 0.5, 0.05, 0.55, 0.06, 0.35)
	_grow(app, col * Vector3(1.4, 1.1, 1.4), col, 0.3, false)
	_params(app, {&"style": 1.0, &"tint": _hdr(ARCANE, 1.5), &"seed": randf()})
	_flare(fx, A_POINT, Vector3.UP * h * 0.5, _hdr(ARCANE, 2.4), 1.2, 2.0, 0.12, 0.05, 0.35, 0.0, 0.22, 1.0, 4.0)
	_sched(fx, &"arc_motes", 0.06, A_POINT, Vector3.UP * h * 0.5)


## Starfall: a warning ring r 3.5 with a ring closing on the centre over the 1.0 s delay, a star falling into it,
## the impact at 1.0 s (flash, shockwave, sparks, dust), then a starry scorch fading.
func _starfall(fx: Fx) -> void:
	var big := STAR_RADIUS
	fx.dur = STAR_DELAY + 1.4
	fx.vis = VIS_POINT
	_cdisc(fx, A_POINT, Vector3.ZERO, C_STAR, _hdr(ARCANE, 1.5), big * 0.6, big, 0.2, 0.0, STAR_DELAY + 0.05, 0.05, 0.1)
	var sky := fx.point + Vector3(2.5, 16.0, -5.0)
	var st := _piece(fx, &"cbolt", A_POINT, Vector3.UP * 0.4, 0.25, STAR_DELAY, 0.05, 0.0)
	_mode(st, &"home", {"from": sky, "time": STAR_DELAY - 0.25, "wave": 0.0, "ln": 4.5, "width": 1.1})
	_params(st, {&"style": 2.0, &"tint": _hdr(ARCANE, 2.4), &"seed": randf() * 10.0})
	var ball := _flare(fx, A_POINT, Vector3.UP * 0.4, _hdr(ARCANE.lerp(Color.WHITE, 0.4), 2.6), 1.3, 1.3, 0.0, 0.25,
			STAR_DELAY, 0.05, 0.0, 0.8, 4.0, 0.6)
	_mode(ball, &"ride")
	_stream(fx, &"star_trail", 0.27, STAR_DELAY, A_ARROW, Vector3.ZERO)
	var hit := STAR_DELAY
	_flare(fx, A_POINT, Vector3.UP * 0.8, _hdr(ARCANE.lerp(Color.WHITE, 0.3), 2.8), 3.0, 5.0, 0.15, hit, hit + 0.35, 0.0,
			0.25, 1.4, 8.0)
	_disc(fx, A_POINT, G_SHOCK, _hdr(ARCANE, 1.8), 0.5, big + 0.6, 0.35, hit, hit + 0.6, 0.0, 0.35)
	_cdisc(fx, A_POINT, Vector3.ZERO, C_BURN, _hdr(ARCANE, 1.2), big * 0.8, big, 0.2, hit, 0.0, 0.02, 1.0)
	_sched(fx, &"star_blast", hit, A_POINT, Vector3.UP * 0.3)
	_sched(fx, &"star_dust", hit, A_POINT, Vector3.UP * 0.2)
	_sched(fx, &"arc_motes", hit + 0.05, A_POINT, Vector3.UP * 0.5, 2.0)


## class_chosen: a 1 s ring of light in the class colour at the champion's feet, a shock ring, rising motes and
## the class emblem popping over its head.
func _class_chosen(fx: Fx, cls: StringName) -> void:
	var h := _h(fx.caster)
	var r := _r(fx.caster)
	var col: Color = CLASS_COLORS.get(cls, Color(1.0, 0.92, 0.7))
	fx.dep = 2 if is_instance_valid(fx.caster) else 0
	fx.dur = 1.0
	fx.vis = VIS_CASTER
	fx.tail = 0.3
	var rr := r * 2.0 + 1.1
	_cdisc(fx, A_CASTER, Vector3.ZERO, C_CLASS, _hdr(col, 1.5), 0.3, rr, 0.3, 0.0, 0.0, 0.04, 0.4)
	_disc(fx, A_POINT, G_SHOCK, _hdr(col, 0.55), 0.3, rr + 1.0, 0.35, 0.0, 0.4, 0.0, 0.25)
	_flare(fx, A_CASTER, Vector3.UP * h * 0.55, _hdr(col, 2.4), 1.5, 2.4, 0.2, 0.0, 0.35, 0.0, 0.22, 1.0, 4.0)
	var look := StringName("cls_%s" % cls)
	if _bursts.has(look):
		_sched(fx, look, 0.0, A_CASTER, Vector3.UP * 0.1, clampf(r / 0.45, 0.8, 1.6))
	if CLASS_ICONS.has(cls):
		var em := _piece(fx, &"cicon", A_CASTER, Vector3.UP * (h + 0.85), 0.05, 0.0, 0.05, 0.35)
		if em:
			em.o0 = Vector3.UP * (h + 0.35)
		_grow(em, 0.2, 0.75, 0.3, true)
		_params(em, {&"icon": CLASS_ICONS[cls], &"tint": _hdr(col, 2.0), &"seed": randf()})


# ---- class helpers

## The class id of a champion (duck-typed: `class_id()`, else `champion_class.id`), &"" if none.
func _class_of(c: Node3D) -> StringName:
	if not is_instance_valid(c):
		return &""
	if c.has_method(&"class_id"):
		return StringName(c.call(&"class_id"))
	var cls: Variant = c.get(&"champion_class")
	if typeof(cls) == TYPE_OBJECT and is_instance_valid(cls):
		var id: Variant = (cls as Object).get(&"id")
		if id != null:
			return StringName(id)
	return &""


## A living unit (or anything with a team) of another team than `team`.
func _is_enemy_of(node: Node, team: int) -> bool:
	if not node is Node3D or not node.is_inside_tree():
		return false
	var t: Variant = node.get(&"team")
	if t == null or int(t) == team:
		return false
	return _alive(node)


## Shield Throw's bounce pick, like the gameplay: the nearest enemy unit within `reach` (+ its radius) of `pos`.
func _nearest_enemy(pos: Vector3, reach: float, team: int, skip: Array[Node3D], caster: Node3D) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group(&"units"):
		if node == caster or skip.has(node) or not _is_enemy_of(node, team):
			continue
		var u := node as Node3D
		var d := Vector2(u.global_position.x - pos.x, u.global_position.z - pos.z).length()
		if d <= reach + _r(u) and d < best_d:
			best_d = d
			best = u
	return best


## Horizontal facing of a unit (+Z = front, as the models are turned with use_model_front).
func _facing(n: Variant) -> Vector3:
	if is_instance_valid(n):
		var f := (n as Node3D).global_basis.z
		f.y = 0.0
		if f.length() > 0.01:
			return f.normalized()
	return Vector3.FORWARD


## Basis turning local +Z along the horizontal `dir`.
func _yaw_basis(dir: Vector3) -> Basis:
	var f := Vector3(dir.x, 0.0, dir.z)
	if f.length_squared() < 0.0001:
		return Basis.IDENTITY
	return Basis.looking_at(-f.normalized(), Vector3.UP)


func _pt_pos(v: Variant, h: float) -> Vector3:
	if typeof(v) == TYPE_OBJECT:
		if is_instance_valid(v) and (v as Node).is_inside_tree():
			return (v as Node3D).global_position + Vector3.UP * h
		return Vector3.ZERO
	return (v as Vector3) + Vector3.UP * h


## Where the thrown shield is `lt` s after the throw (waypoints followed live, a small hop on each leg).
func _path_pos(d: Piece, lt: float) -> Vector3:
	var n := d.pts.size()
	if n == 0:
		return Vector3.ZERO
	for i in n:
		var v: Variant = d.pts[i]
		if typeof(v) == TYPE_OBJECT and is_instance_valid(v) and (v as Node).is_inside_tree():
			d.pfb[i] = (v as Node3D).global_position + Vector3.UP * d.phs[i]
	if n == 1:
		return d.pfb[0]
	var i := 0
	while i < n - 2 and lt > d.pts_t[i + 1]:
		i += 1
	var t0 := d.pts_t[i]
	var t1 := d.pts_t[i + 1]
	var u := clampf((lt - t0) / maxf(t1 - t0, 0.001), 0.0, 1.0)
	return d.pfb[i].lerp(d.pfb[i + 1], u) + Vector3.UP * 0.4 * sin(u * PI)


## Listens to the caster's ChampionAbilities.skill_hit(id, target, amount) while the effect runs and bursts `look`
## on each unit its skill hits (Riposte counters, Whirlwind ticks). Riposte falls back to the caster's
## damage_taken(amount, attacker) from a melee attacker when the abilities node has no skill_hit.
func _hook_hits(fx: Fx, look: StringName, fallback_damage: bool) -> void:
	if not is_instance_valid(fx.caster):
		return
	fx.hit_look = look
	fx.hits_left = 40
	var src: Object = null
	var ab: Variant = fx.caster.get(&"abilities")
	if typeof(ab) == TYPE_OBJECT and is_instance_valid(ab) and (ab as Object).has_signal(&"skill_hit"):
		src = ab
	else:
		var node := fx.caster.get_node_or_null(^"ChampionAbilities")
		if node and node.has_signal(&"skill_hit"):
			src = node
	if src:
		fx.hook_src = src
		fx.hook_sig = &"skill_hit"
		fx.hook_cb = _on_skill_hit.bind(src)
	elif fallback_damage and fx.caster.has_signal(&"damage_taken"):
		fx.hook_src = fx.caster
		fx.hook_sig = &"damage_taken"
		fx.hook_cb = _on_hit_taken.bind(fx.caster)
	else:
		return
	# One connection per source object, shared by every effect listening to it (bound callables of one method
	# count as the same connection).
	if not fx.hook_src.is_connected(fx.hook_sig, fx.hook_cb):
		fx.hook_src.connect(fx.hook_sig, fx.hook_cb)


## Disconnects `fx` from its source unless another running effect still listens to it.
func _unhook(fx: Fx) -> void:
	if fx.hook_sig == &"":
		return
	var shared := false
	for other in _fx:
		if other != fx and other.hook_src == fx.hook_src and other.hook_sig == fx.hook_sig:
			shared = true
			break
	if not shared and is_instance_valid(fx.hook_src) and fx.hook_src.is_connected(fx.hook_sig, fx.hook_cb):
		fx.hook_src.disconnect(fx.hook_sig, fx.hook_cb)
	fx.hook_src = null
	fx.hook_sig = &""
	fx.hook_cb = Callable()


func _on_skill_hit(id: StringName, target: Variant, _amount: float, src: Object) -> void:
	for fx in _fx:
		if fx.hook_src == src and fx.id == id:
			_hit_spark(fx, target)


func _on_hit_taken(_amount: float, attacker: Variant, src: Object) -> void:
	if not is_instance_valid(attacker) or not attacker is Node3D or attacker == src:
		return
	var a := attacker as Node3D
	var ar: Variant = a.get(&"attack_range")
	if ar != null and float(ar) > 3.0:
		return   # Riposte only answers melee hits
	for fx in _fx:
		if fx.hook_src != src or fx.hook_sig != &"damage_taken":
			continue
		var d := a.global_position - fx.cpos
		d.y = 0.0
		if d.length() <= RIPOSTE_MELEE + _r(a):
			_hit_spark(fx, a)


func _hit_spark(fx: Fx, target: Variant) -> void:
	if fx.end_at >= 0.0 or not fx.shown or fx.hits_left <= 0 or not _in_tree(target):
		return
	fx.hits_left -= 1
	var u := target as Node3D
	var p := u.global_position + Vector3.UP * _h(u) * 0.55 + _toward(u.global_position, fx.cpos) * _r(u)
	_burst(fx.hit_look, p)
	if fx.id == &"riposte":
		_burst(&"clash_glint", p)


## Class ground mark (champion_class_ground.gdshader) growing from radius r0 to r1; `ofs` from the anchor.
func _cdisc(fx: Fx, at: int, ofs: Vector3, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float,
		off: float, fin: float, fout: float) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"cdisc", at, ofs + Vector3.UP * (0.055 + 0.006 * float(_layer)), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow, false)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": randf() * 10.0})
	return d


## A class ground line (thrust line) from `from` to `to`, `half_w` metres each side.
func _line(fx: Fx, from: Vector3, to: Vector3, half_w: float, pattern: int, tint: Color, on: float, off: float,
		fin: float, fout: float) -> Piece:
	var mid := (from + to) * 0.5
	var half_l := Vector2(to.x - from.x, to.z - from.z).length() * 0.5
	var d := _cdisc(fx, A_WORLD, Vector3(mid.x, from.y, mid.z), pattern, tint, half_w, half_w, 0.0, on, off, fin, fout)
	if d:
		d.s0 = Vector3(half_w, 1.0, half_l)
		d.s1 = d.s0
		d.rot = _yaw_basis(to - from)
		_params(d, {&"length_m": half_l})
	return d


# ---------------------------------------------------------------- effect runtime

func _new_fx(id: StringName, c: Node3D, t: Node3D, point: Vector3) -> Fx:
	var fx := Fx.new()
	fx.id = id
	fx.caster = c
	fx.target = t
	fx.has_target = t != null
	fx.point = point
	fx.cpos = c.global_position if c else point
	fx.tpos = t.global_position if t else point
	fx.vis = VIS_TARGET if t else VIS_CASTER
	if c:
		var team: Variant = c.get(&"team")
		fx.team = int(team) if team != null else -1
	return fx


func _start(fx: Fx) -> void:
	_fx.append(fx)
	_refresh(fx)
	fx.check_left = CHECK_INTERVAL
	_tick(fx, 0.0)


## Advances one effect. Returns true when it is over.
func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	if is_instance_valid(fx.caster) and fx.caster.is_inside_tree():
		fx.cpos = fx.caster.global_position
	if fx.has_target and is_instance_valid(fx.target) and fx.target.is_inside_tree():
		fx.tpos = fx.target.global_position
	if fx.ext.is_valid() and fx.end_at < 0.0:
		fx.ext.call(fx, delta)
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		# 4 times per second: is_alive() (a unit playing its death stays in the tree), fog, status.
		fx.check_left += CHECK_INTERVAL
		if fx.end_at < 0.0 and fx.t >= fx.dep_at and ((fx.dep == 1 and not _alive(fx.target))
				or (fx.dep == 2 and not _alive(fx.caster))):
			_end_early(fx)
		_refresh(fx)
	elif fx.end_at < 0.0 and fx.t >= fx.dep_at and ((fx.dep == 1 and not _in_tree(fx.target))
			or (fx.dep == 2 and not _in_tree(fx.caster))):
		_end_early(fx)   # freed / removed: at once
	var ef := 1.0 if fx.end_at < 0.0 else clampf((fx.end_at - fx.t) / END_FADE, 0.0, 1.0)
	for d in fx.pieces:
		_tick_piece(fx, d, ef)
	for st in fx.streams:
		_tick_stream(fx, st)
	if fx.bursts_left > 0:
		for b in fx.bursts:
			if not b["done"] and fx.t >= float(b["on"]):
				b["done"] = true
				fx.bursts_left -= 1
				if fx.shown and fx.end_at < 0.0:
					_burst(b["look"], _anchor(fx, b["at"]) + (b["ofs"] as Vector3), b["size"], b["dir"])
	if fx.end_at >= 0.0:
		return fx.t >= fx.end_at
	return fx.t >= fx.dur


func _tick_piece(fx: Fx, d: Piece, ef: float) -> void:
	var n := d.n
	var off := d.off if d.off > 0.0 else fx.dur + d.off
	var lt := fx.t - d.on
	if lt < 0.0 or fx.t >= off:
		if n.visible:
			n.visible = false
		return
	# Settled: done growing, fully faded in, not fading out, past its first second. Continuous animation runs in
	# the shaders (TIME), so a settled piece costs nothing on a fixed spot (flare ball, circles) and one position
	# on a unit (bubble, dome, ward).
	if d.mode == &"" and ef >= 1.0 and lt > maxf(d.grow, 1.0) and lt > d.fin and off - fx.t > d.fout:
		if d.at != A_POINT and d.at != A_WORLD:
			var at := _anchor(fx, d.at) + d.ofs
			if not at.is_equal_approx(n.position):
				n.position = at
		if n.visible != fx.shown:
			n.visible = fx.shown
		return
	var f := ef
	if d.fin > 0.0:
		f = minf(f, lt / d.fin)
	if d.fout > 0.0:
		f = minf(f, (off - fx.t) / d.fout)
	f = clampf(f, 0.0, 1.0)
	var k := 1.0
	if d.grow > 0.0:
		k = _ease(clampf(lt / d.grow, 0.0, 1.0), d.back)
	var pos := _anchor(fx, d.at) + d.o0.lerp(d.ofs, k)
	var s := d.s0.lerp(d.s1, k)
	match d.mode:
		&"arrow":
			var o: Vector3 = fx.data["o"]
			var p: Vector3 = fx.data["p"]
			var apex: float = fx.data["apex"]
			var u := clampf(lt / float(fx.data["ft"]), 0.0, 1.0)
			var head := o.lerp(p, u) + Vector3.UP * apex * 4.0 * u * (1.0 - u)
			fx.data["arrow_pos"] = head
			_axial(n, head, (p - o) + Vector3.UP * apex * 4.0 * (1.0 - 2.0 * u), 1.5, 0.4)
		&"rope":
			if is_instance_valid(fx.caster) and fx.caster.is_inside_tree():
				d.a = _hand(fx.caster, fx.tpos)
				d.has_a = true
			elif not d.has_a:
				d.a = fx.cpos + Vector3.UP * 1.4
				d.has_a = true
			var tip := d.a.lerp(fx.tpos + Vector3.UP * d.bh, _ease(clampf(lt / d.ext, 0.0, 1.0), false))
			var length := d.a.distance_to(tip)
			if length < 0.05:
				n.visible = false
				return
			_axial(n, tip, tip - d.a, length, d.width)
			var w := 1.0 - clampf(lt / 0.35, 0.0, 1.0)
			n.set_instance_shader_parameter(&"length_m", length)
			n.set_instance_shader_parameter(&"width_m", d.width)
			n.set_instance_shader_parameter(&"wave", d.wave * w * w)
		&"toss":
			var u := clampf(lt / d.time, 0.0, 1.0)
			n.transform = Transform3D(Basis.from_scale(s), d.from.lerp(pos, u) + Vector3.UP * 1.4 * 4.0 * u * (1.0 - u))
		&"orbit":
			var a := d.ph + lt * TAU * 1.4
			n.transform = Transform3D(Basis.from_scale(s), pos + Vector3(cos(a) * d.orad, 0.07 * sin(a * 2.0), sin(a) * d.orad))
		&"bob":
			n.transform = Transform3D(Basis.from_scale(s), pos + Vector3.UP * 0.07 * sin(lt * 3.0 + d.ph))
		&"home":
			# A projectile on the Projectile's own path (lerp + sine arc), following its target.
			var u := clampf(lt / maxf(d.time, 0.01), 0.0, 1.0)
			var end := _anchor(fx, d.at) + d.ofs
			var head := d.from.lerp(end, u) + Vector3.UP * d.wave * sin(u * PI)
			fx.data["arrow_pos"] = head
			_axial(n, head, (end - d.from) + Vector3.UP * d.wave * PI * cos(u * PI), d.ln, d.width)
		&"dash":
			# A streak from `from` growing to the caster's new spot (or the predicted one `a`) in `ext` s.
			var end := d.a
			if d.has_a and is_instance_valid(fx.caster) and fx.caster.is_inside_tree():
				var cp := fx.caster.global_position
				if Vector2(cp.x - d.from.x, cp.z - d.from.z).length() > 0.3:
					end = cp + Vector3.UP * d.bh
			var head := d.from.lerp(end, _ease(clampf(lt / maxf(d.ext, 0.01), 0.0, 1.0), false))
			var length := d.from.distance_to(head)
			if length < 0.05:
				n.visible = false
				return
			_axial(n, head, head - d.from, length, d.width)
		&"path":
			var head := _path_pos(d, lt)
			fx.data["arrow_pos"] = head
			n.transform = Transform3D(Basis(Vector3.RIGHT, 0.22) * Basis.from_scale(s), head)
		&"ride":
			n.transform = Transform3D(Basis.from_scale(s), fx.data.get("arrow_pos", pos))
		_:
			var xf := Transform3D(d.rot * Basis.from_scale(s), pos)
			if not xf.is_equal_approx(n.transform):
				n.transform = xf
	# Only what changed goes to the RenderingServer (fade while fading, age during the first second, radius
	# while growing): pieces that follow a unit cost one transform per frame once they are settled.
	if absf(f - d.lf) > 0.003:
		d.lf = f
		n.set_instance_shader_parameter(&"fade", f)
	if lt <= 1.05:
		n.set_instance_shader_parameter(&"age", lt)
	if d.is_disc and absf(s.x - d.lr) > 0.001:
		d.lr = s.x
		n.set_instance_shader_parameter(&"radius", s.x)
	var vis := fx.shown and f > 0.002
	if n.visible != vis:
		n.visible = vis


func _tick_stream(fx: Fx, st: Dictionary) -> void:
	var state: int = st["state"]
	if state == 2:
		return
	var e: GPUParticles3D = st["e"]
	var off: float = st["off"] if float(st["off"]) > 0.0 else fx.dur + float(st["off"])
	var at: int = st["at"]
	var anchor_dead := (at == A_CASTER and not _in_tree(fx.caster)) \
			or (at == A_TARGET and fx.has_target and not _in_tree(fx.target))
	var pos := _anchor(fx, at) + (st["ofs"] as Vector3)
	if state == 0:
		if fx.t < float(st["on"]):
			return
		if fx.end_at >= 0.0 or anchor_dead or fx.t >= off:
			st["state"] = 2
			(_stream_free[st["look"]] as Array).append(e)
			return
		e.transform = Transform3D(Basis.from_scale(Vector3.ONE * float(st["sc"])), pos)
		e.visible = fx.shown
		e.emitting = true
		e.restart()
		st["state"] = 1
		return
	if fx.end_at >= 0.0 or anchor_dead or fx.t >= off:
		_stop_stream(st)
		return
	if at != A_POINT and at != A_WORLD:
		e.global_position = pos
	if e.visible != fx.shown:
		e.visible = fx.shown


func _stop_stream(st: Dictionary) -> void:
	var e: GPUParticles3D = st["e"]
	e.emitting = false
	st["state"] = 2
	_cooling.append({"e": e, "look": st["look"], "left": e.lifetime + 0.1})


func _end_early(fx: Fx) -> void:
	fx.end_at = fx.t + END_FADE
	if fx.pop_look != &"" and fx.shown:
		_burst(fx.pop_look, fx.tpos + Vector3.UP * float(fx.data.get("pop_h", 1.0)))
	if fx.ext_end.is_valid():
		fx.ext_end.call(fx)


func _finish(fx: Fx) -> void:
	_unhook(fx)
	for d in fx.pieces:
		d.n.visible = false
		d.n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[d.pool] as Array).append(d.n)
	fx.pieces.clear()
	for st in fx.streams:
		match int(st["state"]):
			0:
				(_stream_free[st["look"]] as Array).append(st["e"])
			1:
				_stop_stream(st)
	fx.streams.clear()


## Fog / hidden units (4 times per second) and the status the effect shows.
func _refresh(fx: Fx) -> void:
	if fx.vis == VIS_TARGET and fx.has_target and is_instance_valid(fx.target):
		fx.shown = fx.target.is_visible_in_tree()
	elif fx.vis == VIS_CASTER and is_instance_valid(fx.caster) and fx.caster.is_inside_tree():
		fx.shown = fx.caster.is_visible_in_tree()
	else:
		fx.shown = _fog_ok(fx.team, fx.point) or (fx.t < 0.6 and is_instance_valid(fx.caster)
				and fx.caster.is_inside_tree() and fx.caster.is_visible_in_tree())
	if fx.status == &"" or fx.end_at >= 0.0 or fx.t < fx.status_at + 0.1 or not fx.has_target \
			or not _alive(fx.target):
		return
	var u := fx.target
	if not u.has_method(&"has_status") or not (fx.status == &"shield" or Unit.STATUSES.has(fx.status)):
		return   # stand-ins and statuses the gameplay does not have yet: fixed spec durations
	if not bool(u.call(&"has_status", fx.status)):
		if fx.t >= fx.status_at + STATUS_GRACE:
			_end_early(fx)
	elif fx.status != &"shield" and u.has_method(&"status_time_left"):
		var left := float(u.call(&"status_time_left", fx.status))
		if left > 0.0:
			fx.dur = clampf(fx.t + left + fx.tail, fx.t, fx.status_max)


func _fog_ok(team: int, pos: Vector3) -> bool:
	if not is_instance_valid(_fog):
		return true
	if not bool(_fog.get(&"enabled")):
		return true
	var local: Variant = _fog.get(&"local_team")
	if local == null or int(local) == team or not _fog.has_method(&"is_visible"):
		return true
	return bool(_fog.call(&"is_visible", int(local), pos))


func _anchor(fx: Fx, at: int) -> Vector3:
	match at:
		A_TARGET:
			return fx.tpos
		A_CASTER:
			return fx.cpos
		A_ARROW:
			return fx.data.get("arrow_pos", fx.point)
		A_WORLD:
			return Vector3.ZERO
	return fx.point


# ---------------------------------------------------------------- piece helpers

func _piece(fx: Fx, pool: StringName, at: int, ofs: Vector3, on: float, off: float, fin: float,
		fout: float) -> Piece:
	var free: Array = _free[pool]
	if free.is_empty():
		return null   # pool exhausted: this piece is skipped (every helper accepts null)
	var d := Piece.new()
	d.n = free.pop_back()
	d.pool = pool
	d.is_disc = pool == &"disc" or pool == &"cdisc" or ChampionMageArcherVfx.DISC_POOLS.has(pool)
	d.at = at
	d.ofs = ofs
	d.o0 = ofs
	d.on = on
	d.off = off
	d.fin = fin
	d.fout = fout
	d.n.set_instance_shader_parameter(&"fade", 0.0)
	fx.pieces.append(d)
	return d


func _grow(d: Piece, s0: Variant, s1: Variant, time: float, back: bool = false) -> void:
	if d == null:
		return
	d.s0 = s0 if s0 is Vector3 else Vector3.ONE * float(s0)
	d.s1 = s1 if s1 is Vector3 else Vector3.ONE * float(s1)
	d.grow = time
	d.back = back


## Sets a motion mode and its fields (`ph`, `orad`, `bh`, `ext`, `wave`, `width`, `from`, `time`).
func _mode(d: Piece, mode: StringName, extra: Dictionary = {}) -> void:
	if d == null:
		return
	d.mode = mode
	for k: String in extra:
		d.set(k, extra[k])


func _params(d: Piece, params: Dictionary) -> void:
	if d == null:
		return
	for k: StringName in params:
		d.n.set_instance_shader_parameter(k, params[k])


## Ground mark (champion_ground.gdshader) growing from radius r0 to r1.
func _disc(fx: Fx, at: int, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float,
		fin: float, fout: float) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"disc", at, Vector3.UP * (0.05 + 0.006 * float(_layer)), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow, false)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": randf() * 10.0})
	return d


## Camera-facing glow (champion_flare.gdshader) growing from size s0 to s1 metres.
func _flare(fx: Fx, at: int, ofs: Vector3, tint: Color, s0: float, s1: float, grow: float, on: float, off: float,
		fin: float, fout: float, rays: float = 0.0, spikes: float = 4.0, pulse: float = 0.0) -> Piece:
	var d := _piece(fx, &"flare", at, ofs, on, off, fin, fout)
	_grow(d, s0, s1, grow, false)
	_params(d, {&"tint": tint, &"rays": rays, &"spikes": spikes, &"pulse": pulse, &"seed": randf() * 10.0})
	return d


func _stream(fx: Fx, look: StringName, on: float, off: float, at: int, ofs: Vector3, sc: float = 1.0) -> void:
	var free: Array = _stream_free[look]
	if free.is_empty():
		return
	fx.streams.append({"e": free.pop_back(), "look": look, "on": on, "off": off, "at": at, "ofs": ofs, "sc": sc,
			"state": 0})


## Schedules a one-shot burst. `dir` (horizontal or not): the emitter's -Z is turned that way (aimed looks).
func _sched(fx: Fx, look: StringName, on: float, at: int, ofs: Vector3, size: float = 1.0,
		dir: Vector3 = Vector3.ZERO) -> void:
	fx.bursts.append({"look": look, "on": on, "at": at, "ofs": ofs, "size": size, "dir": dir, "done": false})
	fx.bursts_left += 1


func _burst(look: StringName, pos: Vector3, size: float = 1.0, dir: Vector3 = Vector3.ZERO) -> void:
	var pool: Array = _bursts[look]
	var i: int = _burst_next[look]
	_burst_next[look] = (i + 1) % pool.size()
	var p: GPUParticles3D = pool[i]
	var aim := Basis.IDENTITY
	if dir.length_squared() > 0.0001:
		var up := Vector3.UP if absf(dir.normalized().dot(Vector3.UP)) < 0.98 else Vector3.RIGHT
		aim = Basis.looking_at(dir, up)
	p.transform = Transform3D(aim * Basis.from_scale(Vector3.ONE * clampf(size, 0.4, 3.0)), pos)
	p.visible = true
	p.restart()
	for b in _live_bursts:
		if b["p"] == p:
			b["left"] = p.lifetime + 0.1
			return
	_live_bursts.append({"p": p, "left": p.lifetime + 0.1})


## Axial billboard (bolt / rope shaders): +Y end at `head`, basis Y = dir x length, X = width.
func _axial(n: Node3D, head: Vector3, dir: Vector3, length: float, width: float) -> void:
	var dn := dir.normalized() if dir.length_squared() > 0.000001 else Vector3.UP
	var ref := Vector3.UP if absf(dn.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var side := dn.cross(ref).normalized()
	var fwd := side.cross(dn).normalized()
	n.transform = Transform3D(Basis(side * width, dn * length, fwd), head - dn * length * 0.5)


func _ease(k: float, back: bool) -> float:
	if back:
		var c1 := 1.70158
		var c3 := c1 + 1.0
		return 1.0 + c3 * pow(k - 1.0, 3.0) + c1 * pow(k - 1.0, 2.0)
	return 1.0 - pow(1.0 - k, 3.0)


func _in_tree(n: Variant) -> bool:
	return is_instance_valid(n) and (n as Node).is_inside_tree()


func _alive(n: Variant) -> bool:
	if not is_instance_valid(n) or not (n as Node).is_inside_tree():
		return false
	if (n as Object).has_method(&"is_alive"):
		return bool((n as Object).call(&"is_alive"))
	return true


func _h(n: Variant) -> float:
	if not is_instance_valid(n):
		return 1.6
	var h: Variant = (n as Object).get(&"body_height")
	return float(h) if h != null else 1.6


func _r(n: Variant) -> float:
	if not is_instance_valid(n):
		return 0.45
	var r: Variant = (n as Object).get(&"radius")
	return float(r) if r != null else 0.45


## Where a cast leaves the champion: the model's beam origin if it has one, else near the head, toward `toward`.
func _hand(n: Variant, toward: Vector3, frac: float = 0.85) -> Vector3:
	if not is_instance_valid(n):
		return toward + Vector3.UP * 1.4
	var c := n as Node3D
	var model: Variant = c.call(&"get_model") if c.has_method(&"get_model") else null
	if is_instance_valid(model) and (model as Object).has_method(&"get_beam_origin"):
		return (model as Object).call(&"get_beam_origin")
	var base := c.global_position + Vector3.UP * _h(c) * frac
	var dir := toward - base
	dir.y = 0.0
	return base + (dir.normalized() * _r(c) if dir.length() > 0.01 else Vector3.ZERO)


## Horizontal unit vector from `from` toward `to` (zero if they overlap).
func _toward(from: Vector3, to: Vector3) -> Vector3:
	var d := to - from
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.ZERO


## sRGB colour -> linear HDR (instance uniforms and particle colours are linear).
func _hdr(c: Color, energy: float, alpha: float = 1.0) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r * energy, l.g * energy, l.b * energy, alpha)


# ---------------------------------------------------------------- shared resources (built once)

func _build_shared() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var hemi := SphereMesh.new()
	hemi.radius = 1.0
	hemi.height = 1.0
	hemi.is_hemisphere = true
	hemi.radial_segments = 28
	hemi.rings = 10
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	var coin := CylinderMesh.new()
	coin.top_radius = 1.0
	coin.bottom_radius = 1.0
	coin.height = 0.12
	coin.radial_segments = 24
	coin.rings = 1
	var dome_mat := _shader_mat(DOME_SHADER)
	var meshes := {&"disc": plane, &"flare": quad, &"icon": quad, &"dome": hemi, &"bubble": sphere, &"coin": coin,
			&"rope": quad, &"bolt": quad, &"cdisc": plane, &"cbolt": quad, &"shield": coin, &"shell": sphere,
			&"cicon": quad}
	var mats := {&"disc": _shader_mat(GROUND_SHADER), &"flare": _shader_mat(FLARE_SHADER),
			&"icon": _shader_mat(ICON_SHADER), &"dome": dome_mat, &"bubble": dome_mat,
			&"coin": _shader_mat(COIN_SHADER), &"rope": _shader_mat(ROPE_SHADER), &"bolt": _shader_mat(BOLT_SHADER),
			&"cdisc": _shader_mat(CLASS_GROUND_SHADER), &"cbolt": _shader_mat(CLASS_BOLT_SHADER),
			&"shield": _shader_mat(CLASS_SHIELD_SHADER), &"shell": _shader_mat(CLASS_SHELL_SHADER),
			&"cicon": _shader_mat(CLASS_ICON_SHADER)}
	for pool: StringName in POOL_SIZES:
		var arr: Array = []
		for i in int(POOL_SIZES[pool]):
			var m := MeshInstance3D.new()
			m.name = "%s%d" % [String(pool).capitalize(), i]
			m.mesh = meshes[pool]
			m.material_override = mats[pool]
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			m.visible = false
			if pool != &"disc" and pool != &"dome" and pool != &"bubble" and pool != &"cdisc" and pool != &"shell":
				m.extra_cull_margin = 2.0   # billboards / axial quads / the standing coin leave their mesh AABB
			if pool == &"coin" or pool == &"shield":
				m.sorting_offset = 1.0      # drawn after its glow halo
			add_child(m)
			arr.append(m)
		_all[pool] = arr
		_free[pool] = arr.duplicate()
	# The Mage Archer's pools (13b.V8): one mesh and one material per pool, built once.
	for pool: StringName in ChampionMageArcherVfx.POOL_SIZES:
		var mesh := _unique.pool_mesh(pool)
		var mat := _unique.pool_material(pool)
		var margin := _unique.pool_cull_margin(pool)
		var arr: Array = []
		for i in int(ChampionMageArcherVfx.POOL_SIZES[pool]):
			var m := MeshInstance3D.new()
			m.name = "%s%d" % [String(pool).to_pascal_case(), i]
			m.mesh = mesh
			m.material_override = mat
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			m.visible = false
			m.extra_cull_margin = margin
			add_child(m)
			arr.append(m)
		_all[pool] = arr
		_free[pool] = arr.duplicate()
	_build_passes()
	_unique.add_passes(_passes)
	for table: Dictionary in [BURSTS, ChampionMageArcherVfx.BURSTS]:
		for look: StringName in table:
			var spec: Array = table[look]
			var arr: Array = []
			for i in int(spec[3]):
				var p := _emitter(look, int(spec[0]), float(spec[1]), spec[2], false)
				p.one_shot = true
				p.explosiveness = float(spec[4])
				add_child(p)
				arr.append(p)
			_bursts[look] = arr
			_burst_next[look] = 0
	for table: Dictionary in [STREAMS, ChampionMageArcherVfx.STREAMS]:
		for look: StringName in table:
			var spec: Array = table[look]
			var arr: Array = []
			for i in int(spec[3]):
				var p := _emitter(look, int(spec[0]), float(spec[1]), spec[2], bool(spec[4]))
				add_child(p)
				arr.append(p)
			_stream_free[look] = arr


func _shader_mat(shader: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	return m


func _emitter(look: StringName, amount: int, lifetime: float, pass_id: StringName, local: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "%s_%d" % [look, get_child_count()]
	p.process_material = _pmat(look)
	p.draw_pass_1 = _passes[pass_id]
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = local
	p.emitting = false
	p.visible = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var big := WIDE_LOOKS.has(look)
	var own := _unique.emitter_aabb(look)
	if own.size != Vector3.ZERO:
		p.visibility_aabb = own
	elif look == &"star_trail":
		p.visibility_aabb = AABB(Vector3(-9.0, -3.0, -9.0), Vector3(18.0, 22.0, 18.0))   # the fall is 16 m high
	else:
		p.visibility_aabb = AABB(Vector3(-9.0, -3.0, -9.0), Vector3(18.0, 12.0, 18.0)) if big \
				else AABB(Vector3(-5.0, -3.0, -5.0), Vector3(10.0, 9.0, 10.0))
	return p


## Draw passes: textured billboard quads (never a bare square: every one has a shape mask and keeps the particle
## scale, Godot 4.7) + velocity-aligned streaks (combat_streak.gdshader).
func _build_passes() -> void:
	var dot := _shape_tex(&"dot")
	var star := _shape_tex(&"star")
	_passes[&"add_dot"] = _particle_quad(dot, BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_dot"] = _particle_quad(dot, BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"add_star"] = _particle_quad(star, BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_coin"] = _particle_quad(_shape_tex(&"coin"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_smoke"] = _particle_quad(_shape_tex(&"smoke"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"add_drop"] = _particle_quad(_shape_tex(&"drop"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"add_plus"] = _particle_quad(_shape_tex(&"plus"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_shard"] = _particle_quad(_shape_tex(&"shard"), BaseMaterial3D.BLEND_MODE_MIX)
	# The heal + floats over the unit like combat text: never hidden behind helmets and shields.
	((_passes[&"add_plus"] as QuadMesh).material as StandardMaterial3D).no_depth_test = true
	var streak := QuadMesh.new()
	var sm := ShaderMaterial.new()
	sm.shader = STREAK_SHADER
	sm.set_shader_parameter(&"stretch", 4.0)
	streak.material = sm
	_passes[&"streak"] = streak


func _particle_quad(tex: Texture2D, blend: BaseMaterial3D.BlendMode) -> QuadMesh:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = blend
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true   # Godot 4.7: without it the particle scale (scale_min/max, curve) is ignored
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE   # 1 m: ParticleProcessMaterial scale_min / scale_max are the sizes in metres
	q.material = mat
	return q


## 64 x 64 white shape masks (alpha = shape, grey = shading), tinted by the particle colour. Built once.
func _shape_tex(kind: StringName) -> ImageTexture:
	var n := 64
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / float(n) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(n) * 2.0 - 1.0   # -1 = top of the quad
			var r := sqrt(u * u + v * v)
			var a := 0.0
			var shade := 1.0
			match kind:
				&"dot":
					a = clampf(1.0 - r, 0.0, 1.0)
					a = a * a * (3.0 - 2.0 * a)
				&"star":
					# Four-point sparkle: hot core + two thin rays, zero at the quad edge.
					var core := clampf(1.0 - r / 0.32, 0.0, 1.0)
					var ray := maxf(clampf(1.0 - absf(u) / 0.08, 0.0, 1.0) * clampf(1.0 - absf(v), 0.0, 1.0),
							clampf(1.0 - absf(v) / 0.08, 0.0, 1.0) * clampf(1.0 - absf(u), 0.0, 1.0))
					a = clampf(core * core * 1.2 + ray * ray, 0.0, 1.0) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
				&"coin":
					a = clampf((0.9 - r) / 0.07, 0.0, 1.0)
					var rim := clampf((r - 0.64) / 0.08, 0.0, 1.0)
					var groove := 1.0 - clampf(absf(r - 0.56) / 0.05, 0.0, 1.0)
					var hl := clampf(1.0 - Vector2(u + 0.28, v + 0.28).length() / 0.32, 0.0, 1.0)
					shade = clampf(0.72 + 0.22 * rim - 0.28 * groove + 0.3 * hl, 0.0, 1.0)
				&"smoke":
					var nse := _vn(u * 2.3 + 7.1, v * 2.3 + 3.3) * 0.6 + _vn(u * 5.1 + 1.7, v * 5.1 - 2.2) * 0.4
					a = clampf((1.0 - r) * 1.6 + (nse - 0.5) * 0.9 - 0.2, 0.0, 1.0)
					a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
					shade = clampf(0.82 + 0.14 * (0.5 - v * 0.5) + (nse - 0.5) * 0.25, 0.0, 1.0)
				&"drop":
					# Teardrop, tip up: round body low, pointed top.
					var cy := 0.35
					var body := clampf((0.5 - Vector2(u, v - cy).length()) / 0.06, 0.0, 1.0)
					var w := clampf((v + 0.92) / (cy + 0.92), 0.0, 1.0) * 0.5
					var tip := clampf((w - absf(u)) / 0.05, 0.0, 1.0) * (1.0 if v < cy and v > -0.92 else 0.0)
					a = maxf(body, tip)
					shade = clampf(0.72 + 0.35 * clampf(1.0 - Vector2(u + 0.16, v - 0.18).length() / 0.25, 0.0, 1.0), 0.0, 1.0)
				&"plus":
					var bar := maxf(clampf((0.17 - absf(u)) / 0.06, 0.0, 1.0) * clampf((0.78 - absf(v)) / 0.06, 0.0, 1.0),
							clampf((0.17 - absf(v)) / 0.06, 0.0, 1.0) * clampf((0.78 - absf(u)) / 0.06, 0.0, 1.0))
					var halo := clampf(1.0 - r, 0.0, 1.0) * 0.3
					a = maxf(bar, halo)
					shade = 0.6 + 0.4 * bar
				&"shard":
					# A skewed, chipped rhombus of armour plate: two facets (lit / shaded) and a bright edge.
					var su := u * 0.95 + v * 0.35
					var sv := v * 1.1 - u * 0.25
					var sd := absf(su) * 1.25 + absf(sv) * 0.9 + maxf(0.0, su + sv - 0.35) * 0.8
					a = clampf((0.82 - sd) / 0.06, 0.0, 1.0)
					var facet := 1.0 if su > sv * 0.4 else 0.62
					var edge := clampf(1.0 - absf(0.82 - sd) / 0.08, 0.0, 1.0)
					shade = clampf(facet * 0.85 + edge * 0.25, 0.0, 1.0)
			img.set_pixel(x, y, Color(shade, shade, shade, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _vn(x: float, y: float) -> float:
	var ix := floorf(x)
	var iy := floorf(y)
	var fx := x - ix
	var fy := y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	return lerpf(lerpf(_h2(ix, iy), _h2(ix + 1.0, iy), fx), lerpf(_h2(ix, iy + 1.0), _h2(ix + 1.0, iy + 1.0), fx), fy)


func _h2(x: float, y: float) -> float:
	return fposmod(sin(x * 127.1 + y * 311.7) * 43758.5453, 1.0)


## Particle process materials, one per look, shared by every emitter of that look.
func _pmat(key: StringName) -> ParticleProcessMaterial:
	if _pmats.has(key):
		return _pmats[key]
	var m := ParticleProcessMaterial.new()
	var amb_hot := _hdr(Color(1.0, 0.92, 0.7), 2.6)
	var amb := _hdr(AMBER, 2.0)
	var amb_end := _hdr(Color(1.0, 0.55, 0.2), 1.2, 0.0)
	var gold_hot := _hdr(Color(1.0, 0.95, 0.65), 2.6)
	var gold := _hdr(GOLD, 2.0)
	var gold_end := _hdr(BRASS, 1.2, 0.0)
	var steel_hot := _hdr(Color(0.9, 0.97, 1.0), 2.8)
	var steel := _hdr(STEEL, 2.2)
	var steel_end := _hdr(Color(0.35, 0.55, 0.85), 1.2, 0.0)
	var mend_hot := _hdr(Color(0.85, 1.0, 0.8), 2.4)
	var mend := _hdr(MEND, 1.9)
	var mend_end := _hdr(Color(0.3, 0.8, 0.4), 1.0, 0.0)
	match key:
		&"amber_cast":
			_shape_ring(m, 0.35, 0.05)
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 1.5
			m.initial_velocity_max = 3.0
			m.damping_min = 3.0
			m.damping_max = 4.0
			m.tangential_accel_min = 3.0
			m.tangential_accel_max = 5.0
			_size(m, 0.14, 0.24, &"shrink")
			m.color_ramp = _ramp([amb_hot, amb, amb_end])
		&"amber_sparks":
			_shape_sphere(m, 0.2)
			m.direction = Vector3.UP
			m.spread = 75.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 9.0
			m.gravity = Vector3(0, -14.0, 0)
			m.damping_min = 2.0
			m.damping_max = 4.0
			m.particle_flag_align_y = true
			_size(m, 0.07, 0.11, &"shrink")
			m.color_ramp = _ramp([amb_hot, amb, amb, amb_end])
		&"amber_embers":
			_shape_disc(m, 1.4)
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.8
			m.gravity = Vector3(0, 0.4, 0)
			m.damping_min = 0.5
			m.damping_max = 1.0
			_size(m, 0.1, 0.18, &"grow")
			m.color_ramp = _ramp([Color(amb, 0.0), amb_hot, amb, amb_end])
		&"rope_dust":
			_shape_ring(m, 0.55, 0.05)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.radial_velocity_min = 0.5
			m.radial_velocity_max = 1.2
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, 0.2, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.45, 0.75, &"grow")
			var dust := Color(0.45, 0.38, 0.28).srgb_to_linear()
			m.color_ramp = _ramp([Color(dust, 0.0), Color(dust, 0.45), Color(dust, 0.0)])
		&"gold_wind":
			_shape_ring(m, 1.2, 0.1)
			m.emission_ring_inner_radius = 1.0
			m.direction = Vector3.UP
			m.spread = 15.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.6
			m.radial_velocity_min = 7.0
			m.radial_velocity_max = 11.0
			m.tangential_accel_min = 10.0
			m.tangential_accel_max = 16.0
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.particle_flag_align_y = true
			_size(m, 0.07, 0.1, &"shrink")
			m.color_ramp = _ramp([gold_hot, gold, gold, gold_end])
		&"gold_motes":
			_shape_disc(m, 3.0)
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.8
			m.damping_min = 0.6
			m.damping_max = 1.0
			_size(m, 0.18, 0.3, &"grow")
			m.color_ramp = _ramp([Color(gold, 0.0), gold_hot, gold, gold_end])
		&"stomp_dust":
			_shape_ring(m, 1.0, 0.05)
			m.emission_ring_inner_radius = 0.6
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.6
			m.radial_velocity_min = 2.5
			m.radial_velocity_max = 4.5
			m.damping_min = 3.0
			m.damping_max = 4.0
			m.gravity = Vector3(0, 0.3, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.7, 1.2, &"grow")
			m.color_initial_ramp = _ramp(_lin([Color(0.50, 0.45, 0.38), Color(0.42, 0.38, 0.33), Color(0.56, 0.51, 0.45)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
		&"steel_sparks":
			_shape_ring(m, 0.6, 0.1)
			m.direction = Vector3.UP
			m.spread = 50.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 4.0
			m.radial_velocity_min = 5.0
			m.radial_velocity_max = 9.0
			m.gravity = Vector3(0, -12.0, 0)
			m.damping_min = 1.0
			m.damping_max = 2.0
			m.particle_flag_align_y = true
			_size(m, 0.07, 0.1, &"shrink")
			m.color_ramp = _ramp([steel_hot, steel, steel, steel_end])
		&"bash_sparks":
			_shape_sphere(m, 0.15)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 8.0
			m.gravity = Vector3(0, -10.0, 0)
			m.damping_min = 4.0
			m.damping_max = 6.0
			m.particle_flag_align_y = true
			_size(m, 0.07, 0.11, &"shrink")
			m.color_ramp = _ramp([steel_hot, steel_hot, steel, steel_end])
		&"coins":
			_shape_sphere(m, 0.2)
			m.direction = Vector3.UP
			m.spread = 40.0
			m.initial_velocity_min = 3.5
			m.initial_velocity_max = 6.0
			m.gravity = Vector3(0, -13.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -480.0
			m.angular_velocity_max = 480.0
			_size(m, 0.26, 0.34, &"hold")
			var coin := _hdr(GOLD, 1.35)
			m.color_ramp = _ramp([coin, coin, coin, Color(coin, 0.0)])
		&"gold_sparks":
			_shape_sphere(m, 0.15)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 7.0
			m.gravity = Vector3(0, -9.0, 0)
			m.damping_min = 3.0
			m.damping_max = 5.0
			m.particle_flag_align_y = true
			_size(m, 0.06, 0.09, &"shrink")
			m.color_ramp = _ramp([gold_hot, gold, gold_end])
		&"smoke_big":
			_shape_sphere(m, 2.1)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.3
			m.damping_min = 0.6
			m.damping_max = 1.0
			m.gravity = Vector3(0, 0.12, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -25.0
			m.angular_velocity_max = 25.0
			m.scale_min = 2.1
			m.scale_max = 3.1
			m.scale_curve = _curve([Vector2(0.0, 0.45), Vector2(0.25, 1.0), Vector2(1.0, 1.15)])
			m.color_initial_ramp = _ramp(_lin([CHARCOAL, Color(0.22, 0.20, 0.23), Color(0.21, 0.14, 0.16)]))
			m.color_ramp = _ramp_at([0.0, 0.08, 0.7, 1.0],
					[Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.88), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.0)])
		&"smoke_pop":
			_shape_sphere(m, 0.3)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 3.5
			m.initial_velocity_max = 6.0
			m.damping_min = 5.0
			m.damping_max = 7.0
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.8, 1.3, &"grow")
			m.color_initial_ramp = _ramp(_lin([Color(0.34, 0.32, 0.35), Color(0.24, 0.22, 0.25)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
		&"green_puff":
			_shape_sphere(m, 0.25)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.damping_min = 1.5
			m.damping_max = 2.0
			_size(m, 0.14, 0.24, &"shrink")
			m.color_ramp = _ramp([mend_hot, mend, mend_end])
		&"green_splash":
			_shape_sphere(m, 0.25)
			m.direction = Vector3.UP
			m.spread = 55.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 4.8
			m.gravity = Vector3(0, -11.0, 0)
			m.damping_min = 0.3
			m.damping_max = 0.6
			_size(m, 0.14, 0.24, &"shrink")
			m.color_ramp = _ramp([mend_hot, mend, mend, mend_end])
		&"plus":
			_shape_sphere(m, 0.25)
			m.direction = Vector3.UP
			m.spread = 15.0
			m.initial_velocity_min = 0.9
			m.initial_velocity_max = 1.4
			m.damping_min = 0.8
			m.damping_max = 1.2
			m.angle_min = -6.0
			m.angle_max = 6.0
			_size(m, 0.75, 0.9, &"pop")
			m.color_ramp = _ramp([mend_hot, mend, mend_end])
		&"gg_sparkle":
			_shape_sphere(m, 0.9)
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.3
			m.damping_min = 0.8
			m.damping_max = 1.0
			_size(m, 0.18, 0.3, &"grow")
			m.color_initial_ramp = _ramp([_hdr(MEND, 1.0), _hdr(GOLD, 1.0)])
			m.color_ramp = _ramp([Color(2.0, 2.0, 2.0, 0.0), Color(2.0, 2.0, 2.0, 1.0), Color(1.5, 1.5, 1.5, 0.0)])
		&"bubble_pop":
			_shape_sphere(m, 0.9)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 4.0
			m.damping_min = 4.0
			m.damping_max = 6.0
			_size(m, 0.1, 0.18, &"shrink")
			m.color_initial_ramp = _ramp([_hdr(MEND, 1.0), _hdr(GOLD, 1.0)])
			m.color_ramp = _ramp([Color(2.2, 2.2, 2.2, 1.0), Color(2.0, 2.0, 2.0, 1.0), Color(1.5, 1.5, 1.5, 0.0)])
		&"coin_glint":
			_shape_sphere(m, 0.35)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.2
			m.damping_min = 1.0
			m.damping_max = 1.5
			_size(m, 0.14, 0.24, &"grow")
			m.color_ramp = _ramp([gold_hot, gold, gold_end])
		&"amber_trail":
			_shape_sphere(m, 0.06)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.4
			m.gravity = Vector3(0, -0.5, 0)
			_size(m, 0.12, 0.22, &"shrink")
			m.color_ramp = _ramp([amb_hot, amb, amb_end])
		&"flare_drip":
			_shape_sphere(m, 0.35)
			m.direction = Vector3.DOWN
			m.spread = 180.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.6
			m.gravity = Vector3(0, -1.0, 0)
			m.damping_min = 0.3
			m.damping_max = 0.5
			_size(m, 0.12, 0.2, &"shrink")
			m.color_ramp = _ramp([amb_hot, amb, amb_end])
		&"gold_trail":
			_shape_ring(m, 0.35, 0.1)
			m.emission_ring_inner_radius = 0.2
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 0.9
			m.damping_min = 1.0
			m.damping_max = 1.2
			_size(m, 0.12, 0.2, &"shrink")
			m.color_ramp = _ramp([gold_hot, gold, gold_end])
		&"smoke_wisps":
			_shape_sphere(m, 0.35)
			m.direction = Vector3.UP
			m.spread = 40.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.7
			m.damping_min = 0.5
			m.damping_max = 0.8
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.5, 0.8, &"grow")
			m.color_initial_ramp = _ramp(_lin([CHARCOAL, Color(0.24, 0.22, 0.25)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
		&"heal_motes":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			m.emission_box_extents = Vector3(0.45, 0.55, 0.45)
			m.emission_shape_offset = Vector3(0.0, 0.6, 0.0)
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.4
			m.damping_min = 0.3
			m.damping_max = 0.5
			_size(m, 0.1, 0.18, &"grow")
			m.color_ramp = _ramp([Color(mend, 0.0), mend_hot, mend, mend_end])
		&"circle_motes":
			_shape_disc(m, CIRCLE_RADIUS * CIRCLE_SHOW - 0.1)
			m.direction = Vector3.UP
			m.spread = 12.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.3
			m.damping_min = 0.3
			m.damping_max = 0.5
			_size(m, 0.12, 0.22, &"grow")
			m.color_ramp = _ramp([Color(mend, 0.0), mend_hot, mend, mend_end])
		_:
			_class_pmat(m, key)
	_pmats[key] = m
	return m


## Process materials of the class-skill looks (task 11.V6).
func _class_pmat(m: ParticleProcessMaterial, key: StringName) -> void:
	var sp_hot := _hdr(Color(0.85, 1.0, 0.97), 2.6)
	var sp := _hdr(SPEAR_C, 2.0)
	var sp_end := _hdr(Color(0.2, 0.6, 0.55), 1.0, 0.0)
	var br_hot := _hdr(Color(1.0, 0.97, 0.85), 2.8)
	var br := _hdr(SHIELD_C, 2.1)
	var br_end := _hdr(BRASS, 1.1, 0.0)
	var gr_hot := _hdr(Color(1.0, 0.85, 0.6), 2.8)
	var gr := _hdr(GREAT_C, 2.2)
	var gr_end := _hdr(Color(0.6, 0.12, 0.08), 1.0, 0.0)
	var ar_hot := _hdr(Color(0.9, 0.95, 1.0), 2.8)
	var ar := _hdr(ARCANE, 2.2)
	var ar_end := _hdr(Color(0.3, 0.35, 0.9), 1.0, 0.0)
	var bh_hot := _hdr(Color(1.0, 1.0, 0.95), 2.2)
	var bh := _hdr(BREATH, 1.6)
	var bh_end := _hdr(Color(0.6, 0.85, 0.6), 0.8, 0.0)
	var dust := Color(0.47, 0.40, 0.31).srgb_to_linear()
	match key:
		&"dash_dust":
			_shape_ring(m, 0.3, 0.05)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.2
			m.radial_velocity_min = 1.0
			m.radial_velocity_max = 2.5
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.5, 0.9, &"grow")
			m.color_ramp = _ramp([Color(dust, 0.0), Color(dust, 0.5), Color(dust, 0.0)])
		&"wind_streaks":
			_shape_sphere(m, 0.45)
			m.direction = Vector3(0.0, 0.0, -1.0)
			m.spread = 14.0
			m.initial_velocity_min = 8.0
			m.initial_velocity_max = 14.0
			m.damping_min = 12.0
			m.damping_max = 16.0
			m.particle_flag_align_y = true
			_size(m, 0.05, 0.08, &"shrink")
			m.color_ramp = _ramp([sp_hot, sp, sp_end])
		&"teal_hit":
			_shape_sphere(m, 0.15)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 8.0
			m.gravity = Vector3(0, -10.0, 0)
			m.damping_min = 4.0
			m.damping_max = 6.0
			m.particle_flag_align_y = true
			_size(m, 0.06, 0.1, &"shrink")
			m.color_ramp = _ramp([sp_hot, sp_hot, sp, sp_end])
		&"line_sparks":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			m.emission_box_extents = Vector3(0.2, 0.15, 2.5)
			m.direction = Vector3(0.0, 0.5, -1.0)
			m.spread = 40.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 6.0
			m.gravity = Vector3(0, -9.0, 0)
			m.damping_min = 3.0
			m.damping_max = 4.0
			m.particle_flag_align_y = true
			_size(m, 0.06, 0.09, &"shrink")
			m.color_ramp = _ramp([sp_hot, sp, sp, sp_end])
		&"hobble_dust", &"hobble_feet":
			var feet := key == &"hobble_feet"
			_shape_ring(m, 0.4 if not feet else 0.3, 0.05)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.8 if not feet else 0.5
			m.radial_velocity_min = 0.8 if not feet else 0.3
			m.radial_velocity_max = 1.6 if not feet else 0.6
			m.damping_min = 1.5
			m.damping_max = 2.0
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.3 if feet else 0.4, 0.5 if feet else 0.7, &"grow")
			var dd := Color(0.40, 0.34, 0.27).srgb_to_linear()
			m.color_ramp = _ramp([Color(dd, 0.0), Color(dd, 0.55 if not feet else 0.45), Color(dd, 0.0)])
		&"counter_sparks", &"great_sparks":
			var great := key == &"great_sparks"
			_shape_sphere(m, 0.12 if not great else 0.2)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 5.0
			m.initial_velocity_max = 9.0 if not great else 10.0
			m.gravity = Vector3(0, -12.0, 0)
			m.damping_min = 5.0
			m.damping_max = 7.0
			m.particle_flag_align_y = true
			_size(m, 0.06, 0.1 if not great else 0.12, &"shrink")
			m.color_ramp = _ramp([br_hot, br_hot, br, br_end]) if not great else _ramp([gr_hot, gr, gr, gr_end])
		&"clash_glint":
			_shape_sphere(m, 0.1)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.4
			m.angle_min = -30.0
			m.angle_max = 30.0
			_size(m, 0.55, 0.85, &"pop")
			m.color_ramp = _ramp([br_hot, br, br_end])
		&"breath_ring":
			_shape_ring(m, 0.5, 0.05)
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.6
			m.radial_velocity_min = 3.0
			m.radial_velocity_max = 5.0
			m.damping_min = 3.0
			m.damping_max = 4.0
			_size(m, 0.15, 0.25, &"shrink")
			m.color_ramp = _ramp([bh_hot, bh, bh_end])
		&"breath_pulse":
			_shape_ring(m, 0.6, 0.1)
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.0
			m.damping_min = 1.0
			m.damping_max = 1.4
			_size(m, 0.1, 0.18, &"grow")
			m.color_ramp = _ramp([Color(bh, 0.0), bh_hot, bh, bh_end])
		&"crack_dust", &"star_dust":
			var star := key == &"star_dust"
			_shape_ring(m, 0.8 if not star else 1.2, 0.05)
			m.emission_ring_inner_radius = 0.4 if not star else 0.6
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.radial_velocity_min = 2.0 if not star else 3.0
			m.radial_velocity_max = 4.0 if not star else 5.5
			m.damping_min = 2.5
			m.damping_max = 3.5
			m.gravity = Vector3(0, 0.2, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 1.0 if star else 0.7, 1.6 if star else 1.2, &"grow")
			if star:
				m.color_initial_ramp = _ramp(_lin([Color(0.42, 0.42, 0.50), Color(0.36, 0.36, 0.44), Color(0.5, 0.48, 0.52)]))
			else:
				m.color_initial_ramp = _ramp(_lin([Color(0.50, 0.44, 0.36), Color(0.42, 0.37, 0.31), Color(0.55, 0.5, 0.43)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0)])
		&"armor_shards":
			_shape_sphere(m, 0.25)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 6.0
			m.gravity = Vector3(0, -14.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -600.0
			m.angular_velocity_max = 600.0
			_size(m, 0.16, 0.26, &"hold")
			m.color_initial_ramp = _ramp(_lin([Color(0.62, 0.64, 0.70), Color(0.45, 0.47, 0.52), Color(0.75, 0.72, 0.66)]))
			m.color_ramp = _ramp([Color(1.3, 1.3, 1.3, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
		&"arc_sparks", &"star_blast":
			var blast := key == &"star_blast"
			if blast:
				_shape_ring(m, 0.5, 0.1)
				m.radial_velocity_min = 8.0
				m.radial_velocity_max = 14.0
				m.initial_velocity_min = 2.0
				m.initial_velocity_max = 5.0
				m.spread = 40.0
				m.gravity = Vector3(0, -8.0, 0)
				m.damping_min = 2.0
				m.damping_max = 3.0
				_size(m, 0.08, 0.12, &"shrink")
			else:
				_shape_sphere(m, 0.15)
				m.spread = 180.0
				m.initial_velocity_min = 4.0
				m.initial_velocity_max = 8.0
				m.gravity = Vector3(0, -6.0, 0)
				m.damping_min = 5.0
				m.damping_max = 7.0
				_size(m, 0.06, 0.1, &"shrink")
			m.direction = Vector3.UP
			m.particle_flag_align_y = true
			m.color_ramp = _ramp([ar_hot, ar_hot, ar, ar_end])
		&"arc_motes":
			_shape_sphere(m, 0.5)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.2
			m.damping_min = 1.0
			m.damping_max = 1.5
			_size(m, 0.14, 0.24, &"grow")
			m.color_ramp = _ramp([Color(ar, 0.0), ar_hot, ar, ar_end])
		&"javelin_trail", &"arc_trail", &"shield_trail":
			_shape_sphere(m, 0.05)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.4
			match key:
				&"javelin_trail":
					_size(m, 0.08, 0.14, &"shrink")
					m.color_ramp = _ramp([sp_hot, sp, sp_end])
				&"arc_trail":
					m.initial_velocity_max = 0.7
					_size(m, 0.1, 0.2, &"shrink")
					m.color_ramp = _ramp([ar_hot, ar, ar_end])
				_:
					_size(m, 0.08, 0.14, &"shrink")
					m.color_ramp = _ramp([br_hot, br, br_end])
		&"rise_wisps":
			_shape_ring(m, 0.55, 0.3)
			m.emission_ring_inner_radius = 0.35
			m.emission_shape_offset = Vector3(0.0, 0.2, 0.0)
			m.direction = Vector3.UP
			m.spread = 8.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 1.8
			m.tangential_accel_min = 2.0
			m.tangential_accel_max = 4.0
			m.damping_min = 0.3
			m.damping_max = 0.6
			m.particle_flag_align_y = true
			_size(m, 0.06, 0.1, &"grow")
			m.color_ramp = _ramp([Color(bh, 0.0), bh_hot, bh, bh_end])
		&"whirl_dust":
			_shape_ring(m, 2.4, 0.05)
			m.emission_ring_inner_radius = 1.0
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.5
			m.tangential_accel_min = 8.0
			m.tangential_accel_max = 12.0
			m.damping_min = 1.0
			m.damping_max = 1.5
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.5, 0.9, &"grow")
			m.color_ramp = _ramp([Color(dust, 0.0), Color(dust, 0.4), Color(dust, 0.0)])
		&"star_trail":
			_shape_sphere(m, 0.15)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.8
			_size(m, 0.2, 0.35, &"shrink")
			m.color_ramp = _ramp([ar_hot, ar, ar_end])
		&"cls_spear", &"cls_sword_shield", &"cls_two_hand", &"cls_wizard":
			var col: Color = CLASS_COLORS[StringName(String(key).substr(4))]
			var c_hot := _hdr(col.lerp(Color.WHITE, 0.45), 2.6)
			var c := _hdr(col, 2.0)
			var c_end := _hdr(col.darkened(0.4), 1.0, 0.0)
			_shape_disc(m, 1.0)
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.4
			m.damping_min = 0.5
			m.damping_max = 0.8
			_size(m, 0.12, 0.2, &"grow")
			m.color_ramp = _ramp([Color(c, 0.0), c_hot, c, c_end])
		_:
			_unique.pmat(m, key)   # the Mage Archer's looks (13b.V8)


func _shape_ring(m: ParticleProcessMaterial, r: float, h: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = r * 0.85
	m.emission_ring_height = h


func _shape_disc(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = 0.0
	m.emission_ring_height = 0.1


func _shape_sphere(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = r


## Particle sizes in metres + a scale curve: shrink (sparks), grow (motes, dust), hold (coins), pop (the heal +).
func _size(m: ParticleProcessMaterial, lo: float, hi: float, kind: StringName) -> void:
	m.scale_min = lo
	m.scale_max = hi
	match kind:
		&"grow":
			m.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.3, 1.0), Vector2(1.0, 0.3)])
		&"hold":
			m.scale_curve = _curve([Vector2(0.0, 1.0), Vector2(0.8, 1.0), Vector2(1.0, 0.4)])
		&"pop":
			m.scale_curve = _curve([Vector2(0.0, 0.55), Vector2(0.12, 1.0), Vector2(1.0, 0.4)])
		_:
			m.scale_curve = _curve([Vector2(0.0, 1.0), Vector2(1.0, 0.15)])


func _curve(points: Array) -> CurveTexture:
	var c := Curve.new()
	for p: Vector2 in points:
		c.add_point(p)
	var ct := CurveTexture.new()
	ct.curve = c
	return ct


func _lin(colors: Array) -> Array:
	var out: Array = []
	for c: Color in colors:
		out.append(c.srgb_to_linear())
	return out


func _ramp(colors: Array) -> GradientTexture1D:
	var offsets: Array = []
	for i in colors.size():
		offsets.append(float(i) / float(colors.size() - 1))
	return _ramp_at(offsets, colors)


func _ramp_at(offsets: Array, colors: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	var t := GradientTexture1D.new()
	t.gradient = g
	t.use_hdr = true
	return t

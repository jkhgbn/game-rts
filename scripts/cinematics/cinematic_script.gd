class_name CinematicScript
extends Resource
## A whole cinematic (docs/design/cinematics.md 2.1 + prologue 2.1 `skip_locked_until`).
## FROZEN field list: scripts/cinematics/README.md (add only, never rename).

enum Kind { ENGINE, VIDEO }
enum WorldMode { STAGE, PAUSE, HOLD }

const DATA_DIR := "res://data/cinematics/"

@export var id: StringName = &""
@export var title: String = ""
@export var kind: Kind = Kind.ENGINE
@export var world_mode: WorldMode = WorldMode.STAGE
## STAGE: the scene StoryFlow loads (`missions/cinematics/<id>.tscn`, or `scenes/cinematics/<id>.tscn`).
@export var stage_scene: String = ""
## VIDEO: `res://art/cinematics/video/<id>.ogv`.
@export var video_path: String = ""
## ENGINE timeline (also used to stage a VIDEO).
@export var shots: Array[CinematicShot] = []
## VIDEO subtitle track (times from the video start).
@export var lines: Array[CinematicLine] = []
## Letterbox bars (overlay 6.1); 0 = no bars.
@export var letterbox_aspect: float = 2.39
## Music cue started at play (a `res://` audio path or a cue id resolved by the stage); &"" = none.
@export var music_cue: StringName = &""
@export var skippable: bool = true
## Seconds from the start during which skip presses are consumed and do nothing (prologue: 30.0).
@export var skip_locked_until: float = 0.0
## Shown as a text card when a VIDEO file is missing.
@export_multiline var fallback_text: String = ""
## In-mission: where the RTS camera looks when control returns (INF = the player's wizard).
@export var return_focus: Vector3 = Vector3.INF
## Camera-shake seed (recordings repeat exactly).
@export var shake_seed: int = 1
## Added 2026-09-27 (campaign prologue): volume of `music_cue` (`use music ... vol=`); it loops when shorter than the
## cinematic.
@export var music_volume_db: float = 0.0
## Speakers heard as a voice-over (a hidden cine cast, e.g. the Master narrating): subtitles show no name.
@export var voice_over: Array[StringName] = []
## cine rule: a line may run on over later cuts until the next line starts (else it is cut at its shot's end).
@export var lines_over_cuts: bool = false


## Sum of shot durations (branch shots included; the player drops those whose flag fails). VIDEO: last line's end.
func total_duration() -> float:
	var total := 0.0
	for s: CinematicShot in shots:
		if s != null:
			total += maxf(s.duration, 0.0)
	if kind == Kind.VIDEO and total <= 0.0:
		for l: CinematicLine in lines:
			if l != null:
				total = maxf(total, l.at + l.effective_duration())
	return total


## Index of the shot with that id, -1 if none.
func shot_index_of(shot_id: StringName) -> int:
	for i in shots.size():
		if shots[i] != null and shots[i].id == shot_id:
			return i
	return -1


## Loads `data/cinematics/<id>.tres` (null if missing).
static func find(p_id: StringName) -> CinematicScript:
	var path := DATA_DIR + String(p_id) + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as CinematicScript

class_name CinematicLine
extends Resource
## One subtitle line (docs/design/cinematics.md 2.3). Times are from the shot start (script-level `lines` of a
## VIDEO script: from the video start). FROZEN field list: scripts/cinematics/README.md (add only, never rename).

## Seconds from the shot start.
@export var at: float = 0.0
## Speaker id (`Speakers` table: `vessa`, `narrator`, `whisper`...).
@export var speaker: StringName = &""
## The text (writers: <= 2 lines of <= 48 characters).
@export_multiline var text: String = ""
## Seconds on screen; 0 = auto: max(2.5, 0.9 + 0.055 x characters), always cut at the shot's end.
@export var duration: float = 0.0
## Optional voice clip (`res://...wav|ogg`); "" = none (prologue 2.7: voices drop in later without code changes).
@export var voice: String = ""


## Seconds this line stays on screen before the shot-end cut (auto rule of 2.3 when `duration` is 0).
func effective_duration() -> float:
	if duration > 0.0:
		return duration
	return auto_duration(text)


static func auto_duration(t: String) -> float:
	return maxf(2.5, 0.9 + 0.055 * float(t.length()))


static func make(p_at: float, p_speaker: StringName, p_text: String, p_duration: float = 0.0) -> CinematicLine:
	var l := CinematicLine.new()
	l.at = p_at
	l.speaker = p_speaker
	l.text = p_text
	l.duration = p_duration
	return l

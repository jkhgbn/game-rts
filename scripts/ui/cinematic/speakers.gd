class_name Speakers
extends RefCounted
## Speaker ids -> shown name, colour, portrait (docs/design/story-episode-1.md section 2, cinematics.md 6.2 / 6.3).
## The Whisper shows as "???" in amber until `reveal_obren()` is called (the story reveal).

const TABLE := {
	&"vessa": ["Vessa", Color(1.0, 0.45, 0.1)],
	&"torren": ["Vey", Color(0.95, 0.95, 0.55)],
	&"vey": ["Vey", Color(0.95, 0.95, 0.55)],
	&"malrik": ["Malrik", Color(0.7, 0.3, 1.0)],
	&"hush": ["Mother Hush", Color(0.60, 0.50, 0.75)],
	&"torvald": ["Torvald", Color(0.55, 0.80, 1.00)],
	&"ysolde": ["Ysolde", Color(0.55, 0.90, 0.35)],
	&"whisper": ["???", Color(1.0, 0.80, 0.25)],
	&"obren": ["Obren", Color(1.0, 0.80, 0.25)],
	&"master": ["The Master", Color(0.95, 0.93, 0.85)],
	&"narrator": ["Narrator", Color(0.9, 0.85, 0.7)],
	&"ashby": ["Captain Ashby", Color(0.95, 0.60, 0.35)],
	&"pell": ["Pell", Color(0.85, 0.75, 0.5)],
	&"bettany": ["Bettany Crook", Color(0.80, 0.65, 0.45)],
	&"maelis": ["Maelis", Color(0.60, 0.85, 0.50)],
	&"aldra": ["Aldra", Color(0.62, 0.95, 0.88)],   # mission-02.md (M9.U1): Torvald's voice on the Glass Ridge
	# Minor voices of Ep2-Ep4 (mission-e3-02.md / e3-03.md / e4-01.md; episode2-opening.md).
	&"wren": ["Wren", Color(0.80, 0.92, 0.60)],
	&"messenger": ["Wren", Color(0.80, 0.92, 0.60)],   # alias: the messenger is Wren (mission-e4-01.md)
	&"shade": ["Shade Captain", Color(0.62, 0.58, 0.70)],
	&"reveler": ["Reveler", Color(0.95, 0.62, 0.38)],   # a Flame Guard at the Ep2 feast (Fire)
	&"dancer": ["Dancer", Color(1.00, 0.72, 0.55)],     # the Ember Archer at the Ep2 feast (Fire)
	# Ep5-Ep8 story speakers (mission-e5-01 / e5-03 / e6-02 / e7-01 / e7-03 specs; campaign-outline.md F7).
	&"gannet": ["Gannet", Color(0.62, 0.55, 0.40)],       # Gannet Rook, reiver chief
	&"reeve": ["The Reeve", Color(0.80, 0.70, 0.45)],     # Reeve Aldous Pike
	&"rider": ["Bren", Color(0.80, 0.82, 0.88)],          # Bren of Hearthwick (mission-e6-02.md: shown "Bren")
	&"ossavar": ["Ossavar", Color(0.95, 0.70, 0.30)],     # the gold-fire elder dragon
	&"herald": ["Herald", Color(0.85, 0.80, 0.60)],
	&"dacian": ["Dacian", Color(1.00, 0.80, 0.35)],       # Aurivane's Sunblade (gold)
	&"seraphine": ["Seraphine", Color(0.80, 0.88, 1.00)], # Adamarch's Diamond Wall (white-blue)
	&"brannet": ["Brannet", Color(0.75, 0.62, 0.45)],     # Outwall foreman
	&"diamond_archon": ["The Diamond Archon", Color(0.92, 0.94, 1.00)],   # Adamarch white
	&"child": ["Child", Color(1.00, 0.86, 0.78)],         # the Outwall girl of the ruined dome
}
const DEFAULT_COLOR := Color(0.92, 0.92, 0.92)
const PORTRAIT_DIR := "res://art/portraits/"

static var _obren_revealed := false


static func has(id: StringName) -> bool:
	return TABLE.has(id)


static func name_of(id: StringName) -> String:
	if id == &"whisper" and _obren_revealed:
		return "Obren"
	if TABLE.has(id):
		return String(TABLE[id][0])
	return String(id).capitalize()


static func color_of(id: StringName) -> Color:
	if TABLE.has(id):
		return TABLE[id][1]
	return DEFAULT_COLOR


## `art/portraits/<id>.png` (512 x 512), null when there is none.
static func portrait_of(id: StringName) -> Texture2D:
	var path := PORTRAIT_DIR + String(id) + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func reveal_obren(on: bool = true) -> void:
	_obren_revealed = on

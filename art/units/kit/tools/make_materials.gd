extends SceneTree
## Writes the closed character palette of art-units.md 2.2 as .tres files in art/units/kit/materials/.
## Run: $GODOT --headless --path . -s art/units/kit/tools/make_materials.gd --quit-after 60
## Re-running overwrites the files with the same values (safe). Never add a material by hand: add it here.

const DIR := "res://art/units/kit/materials/"
const PAINTED := "res://art/units/kit/unit_painted.gdshader"
const GLOW := "res://art/units/kit/unit_glow.gdshader"
const BANNER := "res://art/shaders/banner.gdshader"
const BLOB := "res://art/units/kit/unit_blob.gdshader"
const NOISE := "res://art/shaders/paint_noise.tres"
## G3b surface kinds (unit_paint.gdshaderinc: 0 plain, 1 cloth, 2 metal, 3 leather, 4 skin, 5 wood, 6 fur, 7 bone / stone);
## the same values tools/assign_surface_kinds.ps1 writes. Not listed = auto (spec -> metal, else plain).
const SURFACE_KINDS: Dictionary = {
	"fire_cloth": 1, "fire_cloth_dark": 1, "fire_skin": 4, "fire_bronze": 2, "fire_leather": 3, "fire_wood": 5,
	"fire_fur": 6, "fire_hair": 6, "fire_ash_ball": 0, "fire_sec_worker": 1, "fire_sec_archer": 1, "fire_sec_rider": 1,
	"fire_sec_hurler": 1, "shadow_cloth": 1, "shadow_cloth_dark": 1, "shadow_skin": 4, "shadow_silver": 2,
	"shadow_leather": 3, "shadow_iron": 2, "shadow_obsidian": 2, "shadow_bone": 7, "shadow_sec_worker": 1,
	"shadow_sec_bolt": 1, "warden_stone": 7, "warden_stone_dark": 7, "warden_moss": 0, "warden_metal": 2,
	"unit_eye_dark": 0, "unit_gold_trim": 2,
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var painted: Shader = load(PAINTED)
	var glow: Shader = load(GLOW)
	var banner: Shader = load(BANNER)
	var noise: Texture2D = load(NOISE)
	var n: int = 0
	# name, colour, spec, rim, crack strength, crack colour
	var p: Array = [
		# Fire (13 painted)
		["fire_cloth", Color(0.85, 0.30, 0.12), 0.0, 0.25, 0.0, Color()],
		["fire_cloth_dark", Color(0.55, 0.08, 0.05), 0.0, 0.25, 0.0, Color()],
		["fire_skin", Color(0.92, 0.72, 0.55), 0.0, 0.25, 0.0, Color()],
		["fire_bronze", Color(0.62, 0.40, 0.16), 0.35, 0.25, 0.0, Color()],
		["fire_leather", Color(0.22, 0.14, 0.10), 0.0, 0.25, 0.0, Color()],
		["fire_wood", Color(0.30, 0.16, 0.08), 0.0, 0.25, 0.0, Color()],
		["fire_fur", Color(0.35, 0.16, 0.08), 0.0, 0.25, 0.0, Color()],
		["fire_hair", Color(0.20, 0.06, 0.04), 0.0, 0.25, 0.0, Color()],
		["fire_ash_ball", Color(0.30, 0.28, 0.26), 0.0, 0.25, 0.8, Color(1.0, 0.55, 0.15)],
		["fire_sec_worker", Color(0.80, 0.60, 0.45), 0.0, 0.25, 0.0, Color()],
		["fire_sec_archer", Color(0.95, 0.55, 0.20), 0.0, 0.25, 0.0, Color()],
		["fire_sec_rider", Color(0.95, 0.40, 0.05), 0.0, 0.25, 0.0, Color()],
		["fire_sec_hurler", Color(0.60, 0.35, 0.25), 0.0, 0.25, 0.0, Color()],
		# Shadow (10 painted)
		["shadow_cloth", Color(0.42, 0.22, 0.60), 0.0, 0.25, 0.0, Color()],
		["shadow_cloth_dark", Color(0.18, 0.08, 0.28), 0.0, 0.3, 0.0, Color()],
		["shadow_skin", Color(0.62, 0.60, 0.70), 0.0, 0.25, 0.0, Color()],
		["shadow_silver", Color(0.55, 0.52, 0.66), 0.35, 0.25, 0.0, Color()],
		["shadow_leather", Color(0.12, 0.09, 0.16), 0.0, 0.3, 0.0, Color()],
		["shadow_iron", Color(0.17, 0.14, 0.24), 0.2, 0.4, 0.0, Color()],
		["shadow_obsidian", Color(0.13, 0.10, 0.19), 0.3, 0.6, 0.0, Color()],
		["shadow_bone", Color(0.80, 0.78, 0.70), 0.0, 0.25, 0.0, Color()],
		["shadow_sec_worker", Color(0.50, 0.45, 0.55), 0.0, 0.25, 0.0, Color()],
		["shadow_sec_bolt", Color(0.55, 0.30, 0.70), 0.0, 0.25, 0.0, Color()],
		# Neutral warden (4 painted)
		["warden_stone", Color(0.45, 0.50, 0.40), 0.0, 0.25, 0.6, Color(1.0, 0.85, 0.30)],
		["warden_stone_dark", Color(0.28, 0.32, 0.26), 0.0, 0.25, 0.0, Color()],
		["warden_moss", Color(0.30, 0.42, 0.20), 0.0, 0.25, 0.0, Color()],
		["warden_metal", Color(0.50, 0.48, 0.40), 0.3, 0.25, 0.0, Color()],
		# Shared (2 painted)
		["unit_eye_dark", Color(0.10, 0.08, 0.08), 0.0, 0.0, 0.0, Color()],
		["unit_gold_trim", Color(1.0, 0.85, 0.40), 0.4, 0.25, 0.0, Color()],
	]
	# Shadow darks (in-game grade 2026-09-30): a lilac rim + a lighter violet crown on the top-facing planes
	# (unit_painted top_color / top_lift) so black-and-violet units separate from each other at zoom 30.
	var lilac := Color(0.72, 0.55, 1.0)
	var tops := {"shadow_iron": [Color(0.46, 0.38, 0.64), 0.55], "shadow_obsidian": [Color(0.40, 0.32, 0.58), 0.45],
		"shadow_leather": [Color(0.34, 0.27, 0.46), 0.35], "shadow_cloth_dark": [Color(0.46, 0.28, 0.66), 0.4]}
	for e: Array in p:
		var m := ShaderMaterial.new()
		m.shader = painted
		if tops.has(e[0]):
			m.set_shader_parameter(&"rim_color", lilac)
			m.set_shader_parameter(&"top_color", tops[e[0]][0])
			m.set_shader_parameter(&"top_lift", tops[e[0]][1])
		m.set_shader_parameter(&"base_color", e[1])
		m.set_shader_parameter(&"noise_tex", noise)
		m.set_shader_parameter(&"spec_strength", e[2])
		m.set_shader_parameter(&"rim_strength", e[3])
		if e[4] > 0.0:
			m.set_shader_parameter(&"crack_strength", e[4])
			m.set_shader_parameter(&"crack_color", e[5])
		if SURFACE_KINDS.has(e[0]):
			m.set_shader_parameter(&"surface_kind", SURFACE_KINDS[e[0]])
		n += _save(m, e[0])
	# name, colour, energy, pulse_speed
	var g: Array = [
		["fire_glow", Color(1.0, 0.55, 0.15), 1.5, 2.0],
		["fire_glow_hero", Color(1.0, 0.50, 0.12), 3.0, 4.2],
		["fire_flame", Color(1.0, 0.55, 0.15), 2.5, 6.0],
		["shadow_glow", Color(0.70, 0.30, 1.00), 1.5, 2.0],
		["shadow_glow_hero", Color(0.70, 0.30, 1.00), 3.0, 3.1],
		["shadow_glow_mid", Color(0.70, 0.30, 1.00), 2.0, 2.5],
		["warden_glow", Color(1.0, 0.85, 0.30), 2.0, 1.6],
		["crystal_glow", Color(0.55, 0.85, 1.0), 2.0, 2.0],
	]
	for e: Array in g:
		var m := ShaderMaterial.new()
		m.shader = glow
		m.set_shader_parameter(&"glow_color", e[1])
		m.set_shader_parameter(&"energy", e[2])
		m.set_shader_parameter(&"pulse_speed", e[3])
		n += _save(m, e[0])
	# name, cloth, stripe, glyph colour, glyph energy, glyph shape
	var b: Array = [
		["fire_cape", Color(0.85, 0.30, 0.12), Color(0.55, 0.08, 0.05), Color(1.0, 0.75, 0.30), 0.6, 0],
		["fire_pennon", Color(0.85, 0.30, 0.12), Color(0.55, 0.08, 0.05), Color(0.85, 0.30, 0.12), 0.0, 0],
		["shadow_cape", Color(0.42, 0.22, 0.60), Color(0.18, 0.08, 0.28), Color(0.70, 0.30, 1.00), 0.6, 1],
		["shadow_cape_plain", Color(0.42, 0.22, 0.60), Color(0.18, 0.08, 0.28), Color(0.42, 0.22, 0.60), 0.0, 1],
	]
	for e: Array in b:
		var m := ShaderMaterial.new()
		m.shader = banner
		m.render_priority = 1
		m.set_shader_parameter(&"cloth_color", e[1])
		m.set_shader_parameter(&"stripe_color", e[2])
		m.set_shader_parameter(&"glyph_color", e[3])
		m.set_shader_parameter(&"glyph_energy", e[4])
		m.set_shader_parameter(&"glyph_shape", e[5])
		m.set_shader_parameter(&"amplitude", 0.10)
		m.set_shader_parameter(&"speed", 2.2)
		m.set_shader_parameter(&"unit_cloth", 1.0)   # G3b: unit cape look (gusts, folds, weave, sheen)
		n += _save(m, e[0])
	var blob := ShaderMaterial.new()
	blob.shader = load(BLOB)
	n += _save(blob, "unit_shadow_blob")
	print("make_materials: wrote ", n, " materials")
	quit()


func _save(m: Material, nm: String) -> int:
	m.resource_name = nm
	var err := ResourceSaver.save(m, DIR + nm + ".tres")
	if err != OK:
		push_error("make_materials: cannot save %s (%d)" % [nm, err])
		return 0
	return 1

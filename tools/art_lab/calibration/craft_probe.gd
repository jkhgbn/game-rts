extends SceneTree
## Art Lab v3.1 craft probe: prints ArtLabCheckCraft.measure_geometry for a list of scenes (headless OK), to calibrate
## the C1 / C2 numbers in ArtLabBudgets.CRAFT. Usage:
##   .\tools\godot_run.ps1 --headless --path . -s res://tools/art_lab/calibration/craft_probe.gd --quit-after 3000 '--' 'scenes=a.tscn,b.tscn'

const DEFAULT := ["res://art/units/_effort_trial/low/vinelasher.tscn", "res://art/units/_effort_trial/medium/vinelasher.tscn",
	"res://art/units/_effort_trial/high/vinelasher.tscn", "res://art/units/_effort_trial/xhigh/vinelasher.tscn",
	"res://art/units/shadow/shade.tscn", "res://art/units/mounts/dusk_steed/dusk_steed.tscn",
	"res://art/environment/landmarks/aqueduct.tscn", "res://art/units/neutral/critters/deer.tscn",
	"res://art/units/titans/frost_dragon/frost_dragon.tscn"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var list: Array = DEFAULT
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("scenes="):
			list = a.substr(7).split(",", false)
	for p: String in list:
		var ps := load(p) as PackedScene
		if ps == null:
			print("CRAFT %s: cannot load" % p)
			continue
		var h := Node3D.new()
		root.add_child(h)
		var inst := ps.instantiate() as Node3D
		h.add_child(inst)
		for i: int in 4:
			await process_frame
		var t0 := Time.get_ticks_msec()
		var g := ArtLabCheckCraft.measure_geometry(inst, h.global_transform, 0.0)
		print("CRAFT %-60s verts %5d islands %3d plain %.2f entropy %.3f area %.2f (%d ms) pivots %s" % [p, g["verts"],
			g["islands"], g["plain_share"], g["entropy"], g["area"], Time.get_ticks_msec() - t0, g["pivots"]])
		h.queue_free()
		await process_frame
	quit(0)

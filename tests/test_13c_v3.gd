extends SceneTree
## Task 13c.V3: the Barrow Giant model (art/units/shadow/barrow_giant/, titans-2.md 4 / 11), built on the Ruin Warden
## (WardenModel extends CharacterModel).
## Run:  $GODOT --headless --path . -s tests/test_13c_v3.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation without errors; it IS a WardenModel (kit hooks); attack_style boulder_throw; budgets
## (titan: <= 36 meshes, <= 20 draw instances, 0 lights, <= 2 particle systems, no looping emitter, materials only from
## the giant's folder + 2 kit palette entries + the blob; vertices / triangles printed); instance-uniform slot audit (kit
## map, no collision); size (~4.5 m, the gravestone is the highest point and sits over the head, both fists on it);
## hooks: set_team_color (shroud recolour, also before _ready, Shadow = no-op), set_moving (walk keeps both hands on the
## slab), play_attack (release at 0.6 s with boulder_released(origin), slab hidden then torn back from the ground,
## the core charges, the rune reignites, ends at 1.8 s), play_hit (flash, head knock), set_status, play_death (mound
## rises, body fades, glow out, death_finished once at ~1.6 s < 2.0 s), revive; the Ruin Warden beside it is unchanged
## (its own look, maul, slam and budget); the cost of 6 giants.
## Prints PASS 13c.v3 / FAIL 13c.v3: <reason>.

const TASK_ID := "13c.v3"
const SCENE := "res://art/units/shadow/barrow_giant/barrow_giant.tscn"
const WARDEN := "res://art/units/neutral/ruin_warden.tscn"
const OWN_DIR := "res://art/units/shadow/barrow_giant/"
const ALLOWED_KIT := ["res://art/units/kit/materials/unit_shadow_blob.tres",
	"res://art/units/kit/materials/shadow_silver.tres", "res://art/units/kit/materials/shadow_obsidian.tres"]
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const KIT_SLOTS := {"ao_bottom": 1, "ao_height": 2, "hit_flash": 3, "flash_color": 4, "glow_boost": 5, "blob_color": 6}
const DT := 1.0 / 60.0

var _fails: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  check failed: ", what)


func _frames(n: int) -> void:
	for _i: int in n:
		await process_frame


static func _surf_mat(mi: MeshInstance3D, s: int) -> Material:
	if mi.material_override:
		return mi.material_override
	var m := mi.get_surface_override_material(s)
	return m if m else mi.mesh.surface_get_material(s)


func _count_draws(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if (g as GeometryInstance3D).is_visible_in_tree() and not g is GPUParticles3D:
			c += 1
	return c


## World-space AABB of every visible mesh of a model (rest pose if called at rest).
func _world_aabb(m: Node3D, only: String = "") -> AABB:
	var box := AABB()
	var first := true
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or mi.name == "Shadow":
			continue
		if only != "" and mi.name != only:
			continue
		var b := mi.global_transform * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _run() -> void:
	var ps := load(SCENE) as PackedScene
	_check(ps != null, "scene loads")
	if ps == null:
		_finish()
		return
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()          # tier 0 (< 30 m) so the footfall dust runs
	cam.position = Vector3(0, 12, 14)
	world.add_child(cam)
	cam.make_current()
	var holder := Node3D.new()
	world.add_child(holder)
	var early: Node3D = ps.instantiate()
	early.call(&"set_team_color", FIRE)    # before _ready: cached, applied in _ready
	var m: Node3D = ps.instantiate()
	holder.add_child(m)
	var h2 := Node3D.new()
	h2.position = Vector3(8, 0, 0)
	world.add_child(h2)
	h2.add_child(early)
	var warden: Node3D = (load(WARDEN) as PackedScene).instantiate()
	var h3 := Node3D.new()
	h3.position = Vector3(-8, 0, 0)
	world.add_child(h3)
	h3.add_child(warden)
	await _frames(3)

	# ---- rig + hooks
	var scr: Script = m.get_script()
	var chain: PackedStringArray = PackedStringArray()
	while scr:
		chain.append(scr.get_global_name())
		scr = scr.get_base_script()
	print("script chain: ", " > ".join(chain))
	_check(chain.has("WardenModel") and chain.has("CharacterModel"), "built on WardenModel / CharacterModel")
	for hk: String in ["set_team_color", "set_moving", "play_attack", "play_hit", "play_death", "revive", "set_status",
			"play_cast", "play_level_up", "set_veterancy", "get_throw_origin", "get_throw_release", "glow_level"]:
		_check(m.has_method(hk), "hook %s" % hk)
	for sg: String in ["death_finished", "boulder_released"]:
		_check(m.has_signal(sg), "signal %s" % sg)
	_check(StringName(m.get(&"attack_style")) == &"boulder_throw", "attack_style boulder_throw")
	_check(float(m.get(&"attack_windup")) <= 0.15, "attack_windup <= 0.15")
	_check(absf(float(m.call(&"get_throw_release")) - 0.6) < 0.001, "throw release 0.6 s")
	_check(StringName(m.get(&"unit_kind")) == &"barrow_giant", "unit_kind barrow_giant")

	# ---- budgets
	var geo := m.find_children("*", "GeometryInstance3D", true, false)
	var meshes := 0
	var parts := 0
	var loops := 0
	for n: Node in geo:
		if n is GPUParticles3D:
			parts += 1
			if not (n as GPUParticles3D).one_shot:
				loops += 1
		elif n is MeshInstance3D or n is MultiMeshInstance3D:
			meshes += 1
	var draws := _count_draws(m)
	print("meshes (blob + hidden mound included) %d, particle systems %d (looping %d), draw instances in play %d, nodes %d"
		% [meshes, parts, loops, draws, geo.size()])
	_check(meshes <= 36, "meshes %d <= 36" % meshes)
	_check(geo.size() <= 20, "draw instances %d <= 20" % geo.size())
	_check(draws <= 12, "draw instances in play %d <= 12 (massable)" % draws)
	_check(parts <= 2, "particle systems %d <= 2" % parts)
	_check(loops == 0, "no looping emitter")
	_check(m.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	_check(_count_draws(early) == draws, "second instance (merge cache) has the same draws")
	var mats := {}
	var verts := 0
	var tris := 0
	var casters := PackedStringArray()
	for n: Node in geo:
		if n is GPUParticles3D:
			continue
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			casters.append(String(mi.get_parent().name) + "/" + String(mi.name))
		for s: int in mi.mesh.get_surface_count():
			var mat := _surf_mat(mi, s)
			mats[mat.resource_path if mat else "<none>"] = true
			var arr := mi.mesh.surface_get_arrays(s)
			var nv := (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			verts += nv
			var idx: Variant = arr[Mesh.ARRAY_INDEX]
			var ni: int = (idx as PackedInt32Array).size() if idx is PackedInt32Array else 0
			tris += (ni if ni > 0 else nv) / 3
	var own := 0
	for p: String in mats:
		if p.begins_with(OWN_DIR):
			own += 1
		else:
			_check(ALLOWED_KIT.has(p), "material outside the giant's folder / allowed kit list: '%s'" % p)
	print("materials: %d own + %d kit (%s)" % [own, mats.size() - own, ", ".join(PackedStringArray(mats.keys()))])
	print("triangles %d, vertices %d, shadow casters %s" % [tris, verts, ", ".join(casters)])
	_check(own <= 7, "own materials %d <= 7" % own)
	_check(verts <= 14000, "vertices %d <= 14000" % verts)
	_check(casters.size() <= 5, "shadow casters %d <= 5" % casters.size())

	# ---- instance-uniform slot audit
	var collisions := 0
	for n: Node in geo:
		var gi := n as MeshInstance3D
		if gi == null or gi.mesh == null:
			continue
		var by_slot := {}
		var seen := {}
		for s: int in gi.mesh.get_surface_count():
			var mat := _surf_mat(gi, s)
			if not mat is ShaderMaterial:
				continue
			for u: Array in _instance_uniforms((mat as ShaderMaterial).shader):
				if seen.has(u[0]):
					continue
				seen[u[0]] = true
				if KIT_SLOTS.has(u[0]) and int(u[1]) != int(KIT_SLOTS[u[0]]):
					_check(false, "%s on slot %d (map %d)" % [u[0], u[1], KIT_SLOTS[u[0]]])
				if by_slot.has(u[1]):
					collisions += 1
					print("  COLLISION %s slot %d: %s / %s" % [gi.name, u[1], by_slot[u[1]], u[0]])
				by_slot[u[1]] = u[0]
	_check(collisions == 0, "instance uniform slot collisions %d" % collisions)
	if collisions == 0:
		print("KITFIX AUDIT OK (barrow giant: slot map, no collision)")

	# ---- size at rest (world)
	var all := _world_aabb(m)
	var slab := _world_aabb(m, "Gravestone")
	var head := _world_aabb(m, "Merged") # placeholder, replaced below
	var head_node := m.get_node("Root/Chest/Head/Merged") as MeshInstance3D
	head = head_node.global_transform * head_node.mesh.get_aabb()
	var body_top := 0.0
	for pth: String in ["Root/Chest/Merged", "Root/Chest/Head/Merged"]:
		var mi := m.get_node(pth) as MeshInstance3D
		body_top = maxf(body_top, (mi.global_transform * mi.mesh.get_aabb()).end.y)
	print("rest extent: width %.2f, depth %.2f, height %.2f (y %.2f .. %.2f); slab %.2f x %.2f, y %.2f .. %.2f; body top %.2f; head top %.2f"
		% [all.size.x, all.size.z, all.end.y, all.position.y, all.end.y, slab.size.x, slab.size.y, slab.position.y,
		slab.end.y, body_top, head.end.y])
	_check(all.end.y > 4.4 and all.end.y < 5.4, "4.5 m class: slab top 4.4-5.4 m (%.2f)" % all.end.y)
	_check(body_top > 2.7 and body_top < 3.6, "the body itself (hump / standing stones) 2.7-3.6 m (%.2f)" % body_top)
	_check(absf(slab.end.y - all.end.y) < 0.01, "the gravestone is the highest point")
	_check(slab.position.y > head.end.y - 0.05, "the gravestone is overhead (slab bottom %.2f, head top %.2f)"
		% [slab.position.y, head.end.y])
	_check(slab.size.x > 1.3, "the slab reads big (%.2f m wide)" % slab.size.x)
	_check(all.position.y > -0.05, "nothing under the ground")
	_check(all.size.x < 3.6, "width < 3.6 m (%.2f)" % all.size.x)
	var blob := m.get_node_or_null("Shadow") as Node3D
	_check(blob != null, "ground blob")
	var stone := m.get_node("Root/Chest/ArmR/Gravestone") as MeshInstance3D
	var arm_l := m.get_node("Root/Chest/ArmL") as Node3D
	var arm_r := m.get_node("Root/Chest/ArmR") as Node3D
	var fist_gap := _fist_gap(m)
	print("fists vs slab at rest: %.3f m" % fist_gap)
	_check(fist_gap < 0.15, "both fists on the slab at rest (%.3f)" % fist_gap)

	# ---- team colour: shroud recolours, stone does not; Shadow colour = no-op; before _ready applied
	var chest_m := m.get_node("Root/Chest/Merged") as MeshInstance3D
	var n_before := _team_surfaces(chest_m, FIRE)
	m.call(&"set_team_color", SHADOW)
	_check(_team_surfaces(chest_m, FIRE) == 0 and n_before == 0, "Shadow colour: no recolour")
	m.call(&"set_team_color", FIRE)
	var tinted := _team_surfaces(chest_m, FIRE)
	var tinted_early := _team_surfaces(early.get_node("Root/Chest/Merged") as MeshInstance3D, FIRE)
	var hips_t := _team_surfaces(m.get_node("Root/Hips/Merged") as MeshInstance3D, FIRE)
	print("team colour: chest surfaces tinted %d (early instance %d), hip rag %d" % [tinted, tinted_early, hips_t])
	_check(tinted == 2, "set_team_color tints the shroud cape + cloth lump (%d)" % tinted)
	_check(tinted_early == 2, "set_team_color before _ready applied (%d)" % tinted_early)
	_check(hips_t == 1, "the hip rag takes the team colour")
	_check(_team_surfaces(stone, FIRE) == 0, "the gravestone never takes the team colour")
	m.call(&"set_team_color", SHADOW)

	# ---- walk: both fists stay on the slab, footfall dust
	var dust := m.get_node("Fx/Dust") as GPUParticles3D
	m.call(&"set_moving", 3.8)
	var worst := 0.0
	var dust_restarts := 0
	var last_dust_pos := dust.global_position
	for i: int in 120:
		await process_frame
		worst = maxf(worst, _fist_gap(m))
		if dust.global_position != last_dust_pos:
			dust_restarts += 1
			last_dust_pos = dust.global_position
	var arm_diff := absf(arm_l.rotation.x - arm_r.rotation.x)
	print("walk: worst fist gap %.3f m, footfall dust moves %d, arm rot diff %.4f" % [worst, dust_restarts, arm_diff])
	_check(worst < 0.15, "walking keeps both fists on the slab (%.3f)" % worst)
	_check(dust_restarts >= 2, "footfall dust at tier 0 (%d)" % dust_restarts)
	m.call(&"set_moving", 0.0)
	await _frames(30)

	# ---- boulder throw
	var core := m.get_node("Root/Chest/Core") as GeometryInstance3D
	var rel := [-1.0, Vector3.ZERO]
	var tt := [0.0]
	m.connect(&"boulder_released", func(o: Vector3) -> void:
		rel[0] = tt[0]
		rel[1] = o, CONNECT_ONE_SHOT)
	var slab_top0 := stone.global_position
	m.call(&"play_attack")
	var hidden_from := -1.0
	var shown_again := -1.0
	var core_max := 0.0
	var rune_after := 0.0
	var ended := -1.0
	var back_z := 99.0
	var low_y := 99.0
	var gap_max := 0.0
	for i: int in 130:
		await process_frame
		tt[0] = float(i + 1) * DT
		var t: float = tt[0]
		if stone.visible and stone.scale.is_equal_approx(Vector3.ONE):   # (the new slab grows out of the fists)
			gap_max = maxf(gap_max, _fist_gap(m))
		if not stone.visible and hidden_from < 0.0:
			hidden_from = t
		if hidden_from > 0.0 and stone.visible and shown_again < 0.0:
			shown_again = t
		core_max = maxf(core_max, float(core.get_instance_shader_parameter(&"glow_boost")))
		if t > 1.15 and t < 1.4:
			rune_after = maxf(rune_after, float(stone.get_instance_shader_parameter(&"glow_boost")))
		if t < 0.45:
			back_z = minf(back_z, m.to_local(stone.global_position).z)
		if t > 0.95 and t < 1.2:
			low_y = minf(low_y, stone.global_position.y)
		if ended < 0.0 and StringName(m.get(&"_action")) == &"":
			ended = t
	var o: Vector3 = rel[1]
	print("throw: released at %.2f s (origin y %.2f, %.2f m from the rest slab), hidden from %.2f to %.2f s, lowest slab %.2f m, wind-up z %.2f, core peak %.2f, rune reignites %.2f, ends %.2f s, worst fist gap %.3f"
		% [rel[0], o.y, o.distance_to(slab_top0), hidden_from, shown_again, low_y, back_z, core_max, rune_after, ended,
		gap_max])
	_check(absf(rel[0] - 0.6) < 0.04, "boulder_released at 0.6 s (%.2f)" % rel[0])
	_check(o.y > 2.5, "the release origin is up at the slab (%.2f)" % o.y)
	_check(absf(hidden_from - 0.6) < 0.04, "slab hidden at release (%.2f)" % hidden_from)
	_check(absf(shown_again - 1.08) < 0.05, "a new slab is torn from the ground at ~1.08 s (%.2f)" % shown_again)
	_check(low_y < 1.2, "the follow-through reaches the ground (%.2f)" % low_y)
	_check(back_z < -0.3, "the wind-up heaves the slab back (%.2f)" % back_z)
	_check(core_max > 1.8, "the core charges (%.2f)" % core_max)
	_check(rune_after > 1.8, "the new slab's rune ignites (%.2f)" % rune_after)
	_check(absf(ended - 1.8) < 0.06, "throw ends at 1.8 s (%.2f)" % ended)
	_check(stone.visible and stone.scale.is_equal_approx(Vector3.ONE), "slab back to rest after the throw")
	_check(gap_max < 0.2, "fists stay on the slab during the throw (%.3f)" % gap_max)

	# ---- hit
	var flashed := false
	var head_p := m.get_node("Root/Chest/Head") as Node3D
	var hr0 := head_p.rotation
	var knock := 0.0
	m.call(&"play_hit")
	for i: int in 8:
		await process_frame
		if float(chest_m.get_instance_shader_parameter(&"hit_flash")) > 0.5:
			flashed = true
		knock = maxf(knock, (head_p.rotation - hr0).length())
	_check(flashed, "play_hit flashes white")
	_check(knock > 0.05, "play_hit knocks the head (%.2f)" % knock)
	await _frames(30)
	_check(float(chest_m.get_instance_shader_parameter(&"hit_flash")) == 0.0, "flash ends")

	# ---- statuses, level-up, cast (hooks run, both arms keep the slab)
	_check(bool(m.call(&"set_status", &"haste", true)), "set_status haste -> true")
	m.call(&"set_status", &"haste", false)
	m.call(&"play_level_up")
	var lv_gap := 0.0
	for i: int in 30:
		await process_frame
		lv_gap = maxf(lv_gap, _fist_gap(m))
	_check(lv_gap < 0.15, "level-up keeps both fists on the slab (%.3f)" % lv_gap)
	m.call(&"play_cast", &"x")
	await _frames(60)

	# ---- death
	var deaths := [0]
	var fin_t := [-1.0]
	var dframes := [0]
	m.connect(&"death_finished", func() -> void:
		deaths[0] += 1
		fin_t[0] = float(dframes[0]) * DT)
	var mound := m.get_node("Fx/Mound") as GeometryInstance3D
	_check(not mound.visible, "mound hidden in play")
	m.call(&"play_death")
	var mound_seen := false
	var mound_top := 0.0
	var body_alpha_mid := 0.0
	var glow_mid := 99.0
	var mound_glow := 0.0
	for i: int in 130:
		await process_frame
		dframes[0] = i + 1
		var t := float(i + 1) * DT
		if mound.visible:
			mound_seen = true
			if t < 1.2:
				mound_top = maxf(mound_top, _world_aabb(m, "Mound").end.y)
			mound_glow = maxf(mound_glow, float(mound.get_instance_shader_parameter(&"glow_boost")))
		if absf(t - 1.1) < 0.01:
			body_alpha_mid = chest_m.transparency
			glow_mid = float(core.get_instance_shader_parameter(&"glow_boost"))
	print("death: finished %d time(s) at %.2f s, mound seen %s (top %.2f m, rune %.2f), body alpha at 1.1 s %.2f, core glow %.2f"
		% [deaths[0], fin_t[0], mound_seen, mound_top, mound_glow, body_alpha_mid, glow_mid])
	_check(deaths[0] == 1, "death_finished once (%d)" % deaths[0])
	_check(fin_t[0] > 1.5 and fin_t[0] < 1.75, "death lasts ~1.6 s (< 2.0 fallback) (%.2f)" % fin_t[0])
	_check(mound_seen and mound_top > 1.2, "a barrow mound with a headstone rises (%.2f)" % mound_top)
	_check(mound_glow > 1.5, "the mound's rune glows")
	_check(body_alpha_mid > 0.95, "the body is gone into the mound (%.2f)" % body_alpha_mid)
	_check(glow_mid <= 0.01, "the soul core goes out")
	_check(mound.transparency > 0.9, "the mound fades at the end (%.2f)" % mound.transparency)
	m.call(&"revive")
	await _frames(4)
	_check(absf(chest_m.transparency) < 0.001, "revive restores the body")
	_check(not mound.visible, "revive hides the mound")
	_check(stone.visible and float(core.get_instance_shader_parameter(&"glow_boost")) > 0.5, "revive: slab + glow back")
	_check(m.is_processing(), "revived model processes")
	m.call(&"play_attack")      # death mid-throw with the slab hidden: it comes back for the fall
	await _frames(45)
	m.call(&"play_death")
	await _frames(2)
	_check(stone.visible, "a death mid-throw shows the slab again")
	m.call(&"revive")
	await _frames(2)

	# ---- the Ruin Warden beside it is unchanged
	var w_draws := _count_draws(warden)
	_check(StringName(warden.get(&"unit_kind")) == &"warden", "warden unit_kind unchanged")
	# the maul rune is merged into ArmR since the B2 pass (2026-09-30): its slam flash drives the merged node
	_check(warden.get_node_or_null("Root/Chest/ArmR/Merged") != null, "warden keeps its maul (rune merged in ArmR)")
	_check(warden.get_node_or_null("Fx/SlamAt/SlamRing") != null, "warden keeps its slam ring")
	_check(w_draws <= 16, "warden draw instances %d <= 16" % w_draws)
	var wmats := {}
	for n: Node in warden.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				var mat := _surf_mat(mi, s)
				if mat:
					wmats[mat.resource_path] = true
	var leaked := false
	for p: String in wmats:
		if p.begins_with(OWN_DIR):
			leaked = true
	_check(not leaked, "no barrow material on the warden")
	warden.call(&"play_attack")
	await _frames(20)
	var ring := warden.get_node("Fx/SlamAt/SlamRing") as Node3D
	_check(ring.visible, "the warden still slams (ring)")
	print("warden: %d draw instances, %d materials" % [w_draws, wmats.size()])

	# ---- cost: 6 giants (a mass), half walking, half throwing (camera far: tier 1)
	cam.position = Vector3(0, 40, 60)
	var giants: Array[Node3D] = []
	for i: int in 6:
		var g: Node3D = ps.instantiate()
		g.position = Vector3(-10.0 + float(i) * 2.4, 0, 30.0)
		world.add_child(g)
		giants.append(g)
	await _frames(4)
	for i: int in 6:
		if i % 2 == 0:
			giants[i].call(&"set_moving", 3.8)
		else:
			giants[i].call(&"play_attack")
	var t0 := Time.get_ticks_usec()
	await _frames(60)
	print("6 giants: %.3f ms per frame (whole headless frame)" % (float(Time.get_ticks_usec() - t0) / 60.0 / 1000.0))
	world.queue_free()
	await _frames(2)
	_finish()


## Largest distance (m) between a fist centre and the slab's side, both fists (0 = touching / inside).
func _fist_gap(m: Node3D) -> float:
	var stone := m.get_node("Root/Chest/ArmR/Gravestone") as MeshInstance3D
	var inv := stone.global_transform.affine_inverse()
	var k: Dictionary = (m.get_script() as Script).get_script_constant_map()
	var fist: Vector3 = k["A_FIST"]
	var hw: float = float(k["SLAB_W"]) * 0.5
	var worst := 0.0
	for side: String in ["L", "R"]:
		var arm := m.get_node("Root/Chest/Arm" + side) as Node3D
		var sx := -1.0 if side == "L" else 1.0
		# fist centre in model space (A_FIST mirrored), carried by the arm pivot
		var rest_arm := Vector3(0.60 * sx, 1.36, -0.02)
		var fist_world := arm.global_transform * (Vector3(fist.x * sx, fist.y, fist.z) - rest_arm)
		var lp := inv * fist_world
		var dx := maxf(absf(lp.x) - hw - 0.13, 0.0)
		var dy := maxf(absf(lp.y) - 0.45, 0.0)
		var dz := maxf(absf(lp.z) - 0.25, 0.0)
		worst = maxf(worst, Vector3(dx, dy, dz).length() * 1.85)
	return worst


## Surfaces of a merged mesh that use a team-colour variant of colour c.
static func _team_surfaces(mi: MeshInstance3D, c: Color) -> int:
	var n := 0
	for s: int in mi.mesh.get_surface_count():
		var mat := _surf_mat(mi, s) as ShaderMaterial
		if mat == null:
			continue
		var v: Variant = mat.get_shader_parameter(&"cloth_color")
		if v == null:
			v = mat.get_shader_parameter(&"base_color")
		if v is Color and (v as Color).is_equal_approx(c):
			n += 1
		elif v is Vector3 and (v as Vector3).is_equal_approx(Vector3(c.r, c.g, c.b)):
			n += 1
	return n


static func _instance_uniforms(sh: Shader) -> Array:
	var out: Array = []
	if sh == null:
		return out
	var code := sh.code
	for line: String in sh.code.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("#include"):
			var q := l.split("\"")
			if q.size() >= 2:
				var inc := load(q[1]) as ShaderInclude
				if inc:
					code += "\n" + inc.code
	var re := RegEx.create_from_string("instance\\s+uniform\\s+\\w+\\s+(\\w+)\\s*(:[^=;]*)?[=;]")
	var idx_re := RegEx.create_from_string("instance_index\\s*\\(\\s*(\\d+)\\s*\\)")
	var implicit := 0
	for line: String in code.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("//"):
			continue
		var r := re.search(l)
		if r == null:
			continue
		var ir := idx_re.search(r.get_string(2))
		if ir:
			out.append([r.get_string(1), int(ir.get_string(1))])
		else:
			out.append([r.get_string(1), implicit])
			implicit += 1
	return out


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()

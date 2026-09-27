extends SceneTree
## Builds the `wade` ripple sprite for 12.V25 (task 12.V1): a painted, slightly broken ring with a faint inner
## ring, white with alpha, 128 x 128 with mipmaps, saved as an ImageTexture resource (no import step), plus its
## flat unshaded material. Re-run (headless is fine):
##   Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://art/environment/water/build_water_tex.gd --quit-after 30

const TEX_PATH := "res://art/environment/water/wade_ripple_tex.res"
const MAT_PATH := "res://art/environment/water/wade_ripple_mat.tres"
const SIZE := 128


func _initialize() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 41
	noise.frequency = 0.9
	var half: float = SIZE * 0.5
	for y in SIZE:
		for x in SIZE:
			var v := Vector2(x + 0.5 - half, y + 0.5 - half) / half   # -1..1
			var r: float = v.length()
			var ang: float = atan2(v.y, v.x)
			# Angular noise on a circle (seamless): breaks and thickness changes along the ring.
			var n: float = noise.get_noise_2d(cos(ang) * 3.0, sin(ang) * 3.0) * 0.5 + 0.5
			var n2: float = noise.get_noise_2d(cos(ang) * 6.0 + 11.0, sin(ang) * 6.0 - 4.0) * 0.5 + 0.5
			var wobble: float = (n - 0.5) * 0.05
			# Outer ring: crisp painted band with a soft trailing inside edge.
			var w_out: float = 0.045 + n2 * 0.04
			var d_out: float = r - (0.80 + wobble)
			var ring: float = 1.0 - smoothstep(w_out * 0.6, w_out, absf(d_out))
			if d_out < 0.0:   # a soft trailing glow inside the ring
				ring = maxf(ring, (1.0 - smoothstep(0.0, 0.16, -d_out)) * 0.28)
			ring *= smoothstep(0.28, 0.42, n)                          # gaps
			# Inner ring: thinner, fainter, broken elsewhere.
			var d_in: float = r - (0.52 - wobble * 0.6)
			var inner: float = (1.0 - smoothstep(0.02, 0.045, absf(d_in))) * 0.55 * smoothstep(0.35, 0.5, 1.0 - n2)
			var a: float = clampf(maxf(ring, inner), 0.0, 1.0) * (1.0 - smoothstep(0.93, 1.0, r))
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	var err := ResourceSaver.save(tex, TEX_PATH)
	print("wade ripple texture: %s (err %d)" % [TEX_PATH, err])
	var mat := StandardMaterial3D.new()
	mat.resource_name = "wade_ripple"
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true      # MultiMesh / instance colour fades each ripple
	mat.albedo_color = Color(0.86, 0.96, 0.92, 0.85)
	mat.albedo_texture = load(TEX_PATH) as Texture2D
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.disable_receive_shadows = true
	mat.render_priority = 1
	err = ResourceSaver.save(mat, MAT_PATH)
	print("wade ripple material: %s (err %d)" % [MAT_PATH, err])
	quit()

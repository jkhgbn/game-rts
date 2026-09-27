// unit_blob.gdshader - soft ground shadow blob under every character (art-units.md 1.5).
// One shared material (materials/unit_shadow_blob.tres); per-unit tint through the instance uniform blob_color
// (Malrik's violet mist stain). Radial gradient from blob_color to alpha 0. Fade it with GeometryInstance3D.transparency.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

instance uniform vec4 blob_color : instance_index(6) = vec4(0.05, 0.03, 0.02, 0.45);

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float a = 1.0 - smoothstep(0.25, 1.0, d);
	ALBEDO = blob_color.rgb;
	ALPHA = blob_color.a * a;
}

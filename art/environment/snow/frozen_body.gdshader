// frozen_body.gdshader - material_overlay on a frozen prisoner's model (FrozenBlockArt): multiplies what is already
// drawn by a cold tint so the soldier inside the ice reads as a dark, chilled silhouette that keeps its own colours
// (Fire red / bronze, dimmed), and his glow parts go dull. Height fade: the feet sink into the rime (darker).
shader_type spatial;
render_mode blend_mul, unshaded, cull_back, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 tint : source_color = vec3(0.44, 0.52, 0.66);
uniform float foot_dark = 0.7;
uniform float base_y = 0.0;   // world y of the block base (set per block)

varying float v_h;

void vertex() {
	v_h = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y - base_y;
}

void fragment() {
	float foot = 1.0 - smoothstep(0.0, 0.5, v_h);
	ALBEDO = tint * mix(1.0, foot_dark, foot);
}

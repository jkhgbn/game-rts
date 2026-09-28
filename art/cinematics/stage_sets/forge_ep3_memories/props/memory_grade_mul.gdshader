// memory_grade_mul.gdshader - E34 Ep3 (props/memory_grade.tscn, pass 2 of 2): full-screen multiply: a soft violet-warm
// tint and a heavy memory vignette (the edges of a remembered picture fall away), over everything, glows included.
shader_type spatial;
render_mode unshaded, blend_mul, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 tint : source_color = vec3(0.86, 0.82, 0.98);
uniform float vignette = 0.82;
uniform float inner = 0.3;
uniform float outer = 1.05;

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 0.5, 1.0);
}

void fragment() {
	vec2 q = (SCREEN_UV - 0.5) * vec2(1.0, 0.62) * 2.0;
	float v = 1.0 - vignette * smoothstep(inner, outer, length(q));
	ALBEDO = tint * v;
}

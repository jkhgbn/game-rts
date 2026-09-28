// ep4_ice.gdshader - Episode 4 memories (forge_ep4_memories): clear blue ice over the burned wood and on the frosted
// sapling. Translucent (the black ash / the frozen bodies show through), glassy specular, a fresnel edge that catches the
// low sun, a faint cold self-light so it still reads in shadow. No white "teeth": the body stays blue, only the rims
// and the sun glints go pale. Vertex COLOR.rgb tints, COLOR.a scales the opacity. TIME only for a slow shimmer.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec4 tint : source_color = vec4(0.46, 0.66, 0.86, 1.0);
uniform vec4 edge : source_color = vec4(0.85, 0.94, 1.0, 1.0);
uniform float opacity = 0.55;
uniform float edge_power = 2.5;
uniform float self_light = 0.12;
uniform float rough = 0.1;

void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), edge_power);
	vec3 base = tint.rgb * COLOR.rgb;
	ALBEDO = mix(base, edge.rgb, f * 0.7);
	ROUGHNESS = rough;
	SPECULAR = 0.9;
	METALLIC = 0.0;
	float shimmer = 0.9 + 0.1 * sin(TIME * 0.7 + VERTEX.x * 3.0 + VERTEX.y * 2.0);
	EMISSION = base * self_light * shimmer + edge.rgb * f * self_light;
	ALPHA = clamp(mix(opacity, 0.92, f) * COLOR.a, 0.0, 1.0);
}

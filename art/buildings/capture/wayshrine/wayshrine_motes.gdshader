// wayshrine_motes.gdshader - golden motes rising in the light column of an awake Wayshrine (task 12.V18).
// No particles node: a static mesh of camera-facing quads animated here (0 CPU, one draw call). Every vertex of a quad
// stores the same COLOR = (seed, spiral radius, speed, size); UV = the quad corner. Additive, unshaded.
// Instance uniforms: fx_color, fx_energy (0 = invisible; wayshrine.gd hides the node then).
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform float height = 7.0;
uniform float base_y = 0.25;
uniform float size = 0.14;

instance uniform vec4 fx_color = vec4(1.0, 0.72, 0.28, 1.0);
instance uniform float fx_energy = 0.0;

varying float v_fade;

void vertex() {
	float seed = COLOR.r;
	float t = fract(TIME * mix(0.05, 0.11, COLOR.b) + seed * 7.13);
	float a = seed * 18.85 + TIME * (0.35 + seed * 0.45);
	float rr = COLOR.g * (1.0 - t * 0.6);                  // they spiral into the column as they rise
	vec3 centre = vec3(cos(a) * rr, base_y + t * height, sin(a) * rr);
	vec4 vc = MODELVIEW_MATRIX * vec4(centre, 1.0);
	float s = size * (0.65 + COLOR.a * 0.7) * (1.0 - t * 0.45);
	vc.xy += (UV - 0.5) * s;
	POSITION = PROJECTION_MATRIX * vc;
	v_fade = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.5, 1.0, t)) * (0.75 + 0.25 * sin(TIME * 7.0 + seed * 40.0));
}

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float a = pow(max(1.0 - r, 0.0), 2.0);
	ALBEDO = fx_color.rgb * fx_energy * a * v_fade * 2.4;
}

// light_shaft.gdshader - G-E fixes C (docs/art/ge_fixes_c.md): soft sun shafts through the Sighing Wood canopy
// (ForestMood, High+ only). One MultiMesh of a unit QuadMesh (x -0.5..0.5, y 0..1 from the ground up). The instance
// basis Y is the shaft's axis (toward the sun, times its length); the quad turns round that axis to face the camera.
// INSTANCE_CUSTOM: r = phase seed, g = width (m), b = length (m), a = fog-of-war fade (0 hidden .. 1 shown; ForestMood
// sets it from VfxFog.ok, the shafts draw over the fog overlay like every transparent effect).
// Additive, unshaded, no depth write, no shadows, fog_disabled (no pale square at range: shader lint C).
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled, skip_vertex_transform;

uniform vec3 shaft_color : source_color = vec3(1.0, 0.93, 0.66);
uniform float strength = 0.32;
uniform float drift_speed = 0.35;

varying float v_fade;
varying float v_seed;

void vertex() {
	vec3 axis = MODEL_MATRIX[1].xyz;
	vec3 base = MODEL_MATRIX[3].xyz;
	float w = INSTANCE_CUSTOM.g;
	vec3 mid = base + axis * 0.5;
	vec3 to_cam = normalize(CAMERA_POSITION_WORLD - mid);
	vec3 right = cross(normalize(axis), to_cam);
	right = length(right) > 0.001 ? normalize(right) : vec3(1.0, 0.0, 0.0);
	vec3 wp = base + axis * VERTEX.y + right * (VERTEX.x * w * mix(0.55, 1.35, VERTEX.y));   // wider up high
	VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(to_cam, 0.0)).xyz);
	v_fade = INSTANCE_CUSTOM.a;
	v_seed = INSTANCE_CUSTOM.r;
}

void fragment() {
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	across = across * across * (3.0 - 2.0 * across);
	float along = 1.0 - UV.y;                                    // 0 at the ground, 1 at the canopy
	float foot = smoothstep(0.0, 0.3, along);
	float head = 1.0 - smoothstep(0.35, 1.0, along);
	float t = TIME * drift_speed + v_seed * 6.2831;
	float breath = 0.72 + 0.28 * sin(t * 0.9 + along * 2.4);
	float streak = 0.72 + 0.28 * sin(UV.x * 11.0 + v_seed * 19.0 + sin(t) * 0.8);
	ALBEDO = shaft_color;
	ALPHA = clamp(across * foot * head * breath * streak * strength * v_fade, 0.0, 1.0);
}

shader_type spatial;
// Verdant regen motes: ONE MultiMesh (QuadMesh 1 x 1) for every regenerating unit, 2 instances per unit.
// Instance origin = the unit's feet; INSTANCE_CUSTOM = (phase 0..1, unit radius, unit height, size 0..1).
// Each mote loops once per second (rate): pops out at a random spot around the body, drifts up in a small
// spiral and fades, so 2 instances = 2 tiny leaf sparkles per second. Everything is animated here: the CPU
// only moves the instance origins.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color : source_color = vec3(0.75, 1.00, 0.40);
uniform float energy = 2.2;
uniform float rate = 1.0;
uniform float mote_size = 0.42;

varying float life;
varying float vis;
varying vec2 q;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void vertex() {
	float t = TIME * rate + INSTANCE_CUSTOM.x;
	float cyc = floor(t);
	life = fract(t);
	float s = cyc * 7.13 + INSTANCE_CUSTOM.x * 91.7 + MODEL_MATRIX[3].x * 0.37 + MODEL_MATRIX[3].z * 0.71;
	float a = hash(s) * 6.2831853 + life * 2.2;
	float d = (0.55 + 0.45 * hash(s + 1.7)) * INSTANCE_CUSTOM.y;
	float h0 = INSTANCE_CUSTOM.z * (0.2 + 0.45 * hash(s + 3.1));
	vec3 off = vec3(cos(a) * d, h0 + INSTANCE_CUSTOM.z * 0.45 * life, sin(a) * d);
	vec3 world = MODEL_MATRIX[3].xyz + off;
	float size = mote_size * INSTANCE_CUSTOM.w * (0.5 + 0.5 * sin(life * 3.14159));
	vec3 right = INV_VIEW_MATRIX[0].xyz;
	vec3 up = INV_VIEW_MATRIX[1].xyz;
	vec3 pos = world + (right * VERTEX.x + up * VERTEX.y) * size;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(pos, 1.0);
	vis = INSTANCE_CUSTOM.w;
	q = VERTEX.xy * 2.0;
}

void fragment() {
	// A leaf-shaped (diamond) sparkle with a hot centre and a thin 4-point glint.
	float d = abs(q.x) * 1.7 + abs(q.y);
	float leaf = 1.0 - smoothstep(0.55, 0.95, d);
	float hot = 1.0 - smoothstep(0.0, 0.35, d);
	float glint = max(1.0 - smoothstep(0.0, 0.07, abs(q.x)), 1.0 - smoothstep(0.0, 0.07, abs(q.y)))
			* (1.0 - smoothstep(0.2, 1.0, length(q)));
	float shape = clamp(leaf * 0.7 + hot * 0.6 + glint * 0.6, 0.0, 1.0);
	float core = hot;
	float fade_in_out = smoothstep(0.0, 0.15, life) * (1.0 - smoothstep(0.6, 1.0, life));
	ALBEDO = mix(color, vec3(1.0, 1.0, 0.8), core * 0.5) * energy;
	ALPHA = shape * fade_in_out * vis;
}

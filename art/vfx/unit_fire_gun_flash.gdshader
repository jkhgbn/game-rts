shader_type spatial;
// Musket muzzle flash (UnitFireGunVfx, task 13b.V6): a cone of flame blasting out of the bell mouth.
// QuadMesh 1 x 1 drawn as an AXIAL billboard: the node basis Y = the barrel direction (its length = the flash length),
// X = the width; the quad turns around Y to face the camera (like combat_streak), and its bottom edge sits ON the node
// origin (the muzzle), so scaling Y shoots the flash forward. ONE material for every flash: instance uniforms only.
// Shape: a short fan of fire out of the bell (side petals), then a bulb that tapers to a ragged point; white-yellow
// core at the mouth -> orange -> deep red tongues. `age` (s) cools it; `fade` hides it. Premultiplied alpha with a
// little cover so the flame stays orange (not white) over bright ground.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

instance uniform vec4 hot = vec4(3.2, 2.5, 1.2, 1.0);     // linear HDR core
instance uniform vec4 tint = vec4(2.8, 0.95, 0.2, 1.0);   // body
instance uniform vec4 edge = vec4(1.3, 0.2, 0.03, 1.0);   // tongue edges
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

varying vec2 v_uv;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	vec3 origin = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 axis = (MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	float width = length((MODELVIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
	float al = length(axis);
	vec3 along = al > 0.00001 ? axis / al : vec3(0.0, 1.0, 0.0);
	vec3 to_cam = normalize(-(origin + axis * 0.5));
	vec3 side = cross(along, to_cam);
	float sl = length(side);
	side = sl > 0.00001 ? side / sl : vec3(1.0, 0.0, 0.0);
	// Seen along the barrel the flash keeps at least its width as a length (never a sliver).
	float len = max(al, width * 0.8);
	VERTEX = origin + along * (VERTEX.y + 0.5) * len + side * VERTEX.x * width;
	NORMAL = to_cam;
	v_uv = UV;
}

void fragment() {
	float s = clamp(1.0 - v_uv.y, 0.0, 1.0);   // 0 = the muzzle, 1 = the tip
	float x = (v_uv.x - 0.5) * 2.0;            // -1..1 across
	float t = TIME * 22.0 + seed * 17.0;
	float n = vnoise(vec2(s * 7.0 - t * 0.35, x * 2.2 + seed * 5.0));
	float n2 = vnoise(vec2(s * 15.0 - t * 0.6, x * 5.0 - seed * 3.0));
	// Main bulb (widest at a quarter of the length) with ragged tongues, plus the side petals out of the bell.
	float bulb = pow(s, 0.32) * pow(1.0 - s, 0.85) * 1.95 * (0.78 + 0.34 * n + 0.18 * (n2 - 0.5));
	float petal = exp(-pow((s - 0.06) / 0.05, 2.0)) * (0.95 + 0.25 * n2);
	float w = max(bulb, petal);
	float ax = abs(x);
	float body = 1.0 - smoothstep(w * 0.55, w + 0.02, ax);
	float core = (1.0 - smoothstep(0.0, w * 0.5 + 0.02, ax)) * (1.0 - smoothstep(0.05, 0.55, s));
	float cool = clamp(age / 0.13, 0.0, 1.0);
	float heat = clamp(core * (1.0 - cool * 0.7) + (1.0 - s) * 0.35 * (1.0 - cool), 0.0, 1.0);
	vec3 c = mix(edge.rgb, tint.rgb, smoothstep(0.1, 0.6, body * (1.0 - s * 0.6)));
	c = mix(c, hot.rgb, smoothstep(0.25, 0.9, heat));
	float a = clamp(body * fade, 0.0, 1.0);
	ALBEDO = c * a;
	ALPHA = a * 0.22;
}

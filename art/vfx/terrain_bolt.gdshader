shader_type spatial;
// Lightning bolt (TerrainVfx `lightning_strike`, task 12b.V4, docs/design/terrain.md 7.3). A jagged ribbon mesh built
// once by TerrainVfx (6 shapes, one per pooled node): the centre line of the bolt and its branches, from the cloud
// (y = 12 m) to the ground (y = 0), drawn as a camera-facing ribbon around that line (the combat_streak trick along a
// polyline). Per vertex: VERTEX = point on the centre line, NORMAL = the line's direction there, UV.x = -1 / +1 (the two
// edges), UV.y = 0 at the cloud .. 1 at the ground (branches continue past their fork), COLOR.r = width (1 trunk,
// ~0.45 branches), COLOR.g = brightness.
// The strike (driven by `age`, seconds): the leader races down in 0.05 s, full flash, a dim gap, a second stroke,
// then it dies in ~0.1 s. ONE material for every bolt; the look is in instance uniforms. Additive, no light.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

instance uniform vec4 tint = vec4(1.5, 1.8, 2.6, 1.0);   // halo colour (linear HDR), a = strength
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;
uniform float width = 1.5;          // ribbon width of the trunk in metres (the white core is ~1/6 of it)
uniform float descend = 0.05;       // seconds for the leader to reach the ground

varying vec2 v_uv;
varying vec2 v_c;

void vertex() {
	vec3 c = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 t = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	vec3 to_cam = normalize(-c);
	vec3 side = cross(t, to_cam);
	float sl = length(side);
	side = sl > 0.00001 ? side / sl : vec3(1.0, 0.0, 0.0);
	float sx = length(MODEL_MATRIX[0].xyz);
	VERTEX = c + side * UV.x * width * 0.5 * COLOR.r * sx;
	NORMAL = to_cam;
	v_uv = UV;
	v_c = COLOR.rg;
}

void fragment() {
	float x = abs(v_uv.x);
	float core = 1.0 - smoothstep(0.0, 0.17, x);
	float halo = pow(clamp(1.0 - x, 0.0, 1.0), 2.4);
	// The leader: only the part above the moving tip is drawn while it races down.
	float reach = age / max(descend, 0.001);
	float shown = 1.0 - smoothstep(reach - 0.06, reach, v_uv.y);
	// Stroke pattern: flash, dim gap, second stroke, quick death (+ a per-bolt shimmer along the channel).
	float fl = age < 0.07 ? 1.0 : (age < 0.11 ? 0.22 : (age < 0.18 ? 0.95 : exp(-(age - 0.18) * 18.0)));
	float wob = 0.85 + 0.15 * sin(v_uv.y * 40.0 + seed * 9.0 + TIME * 60.0);
	float bright = v_c.g * fl * wob * shown;
	vec3 col = tint.rgb * tint.a * halo * 0.8 + vec3(3.0, 3.1, 3.4) * core * core * 1.5;
	ALBEDO = col * bright * fade;
	ALPHA = 1.0;
}

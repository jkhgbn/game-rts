shader_type spatial;
// Titan projectiles (TitanGroundVfx, task 13.V19): the howdah's ice bolt, the Treant's thorns and their light trails.
// ONE material for all of them; the look is picked per instance (`pattern`):
//   0 ice bolt   (crystal mesh, +Z = the flight, UV.y 0 tail .. 1 tip): a deep-blue faceted crystal, bright rim and a
//                white-hot tip (premultiplied: the body hides what is behind it, the glow adds on top)
//   1 thorn      (curved bark spike, UV.y 0 base .. 1 tip): dark bark, fake-lit facets, a glowing green tip
//   2 streak     (1 x 1 QuadMesh; node basis Y = head - tail (its length), X = width): turns around its own axis to face
//                the camera (as combat_streak.gdshader); head (+Y) bright, the tail fades. Pure additive.
// Unshaded, fake light from a fixed direction so the solid shapes read round without a real light.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

instance uniform float pattern = 0.0;
instance uniform vec4 tint = vec4(0.6, 1.3, 2.4, 1.0);     // glow colour (linear HDR), a = strength
instance uniform vec4 body = vec4(0.05, 0.14, 0.3, 0.85);  // solid colour (linear), a = opacity
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;

varying vec2 v_uv;

void vertex() {
	if (int(pattern + 0.5) == 2) {
		vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		vec3 axis = (MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
		float wd = length((MODELVIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
		vec3 to_cam = normalize(-center);
		vec3 side = cross(axis, to_cam);
		float sl = length(side);
		side = sl > 0.00001 ? side / sl : vec3(1.0, 0.0, 0.0);
		float al = length(axis);
		vec3 along = al > 0.00001 ? axis / al : vec3(0.0, 1.0, 0.0);
		VERTEX = center + along * VERTEX.y * max(al, wd) + side * VERTEX.x * wd;
		NORMAL = to_cam;
	} else {
		VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	}
	v_uv = UV;
}

void fragment() {
	int pat = int(pattern + 0.5);
	if (pat == 2) {
		float x = abs(v_uv.x - 0.5) * 2.0;
		float y = clamp(v_uv.y, 0.0, 1.0);          // 0 head (+Y), 1 tail
		float across = 1.0 - smoothstep(0.22, 1.0, x);
		across *= across;
		float along = pow(1.0 - y, 1.5) * smoothstep(0.0, 0.08, y);
		float hot = (1.0 - smoothstep(0.0, 0.25, x)) * 0.7;
		ALBEDO = tint.rgb * tint.a * (1.0 + hot) * across * along * fade;
		ALPHA = 0.0;
	} else {
		vec3 n = normalize(NORMAL);
		vec3 l = normalize((VIEW_MATRIX * vec4(0.35, 0.85, 0.4, 0.0)).xyz);
		float lit = clamp(dot(n, l) * 0.5 + 0.5, 0.0, 1.0);
		float fres = 1.0 - clamp(abs(dot(n, VIEW)), 0.0, 1.0);
		float y = clamp(v_uv.y, 0.0, 1.0);
		vec3 solid;
		vec3 emit;
		if (pat == 0) {
			solid = body.rgb * (0.45 + 0.9 * lit);
			float spark = 0.8 + 0.2 * sin(TIME * 23.0 + seed * 9.0);
			emit = tint.rgb * tint.a * (pow(fres, 2.0) * 1.3 + pow(y, 4.0) * 1.6 * spark + 0.18 + step(0.93, lit) * 0.5);
		} else {
			float stripe = 0.85 + 0.15 * sin(y * 40.0 + seed * 7.0);
			solid = body.rgb * (0.35 + 0.95 * lit) * stripe;
			float tip = smoothstep(0.68, 1.0, y);
			solid = mix(solid, tint.rgb * 0.25, tip * 0.6);
			emit = tint.rgb * tint.a * (tip * tip * 1.7 + pow(fres, 3.0) * 0.25);
		}
		float a = body.a * fade;
		ALBEDO = solid * a + emit * fade;
		ALPHA = a;
	}
}

shader_type spatial;
// Black-powder smoke puffs (UnitFireGunVfx, task 13b.V6): EVERY puff of every powder cloud and muzzle wisp is one
// MultiMesh instance with this ONE material (one draw call per MultiMesh). The script writes an instance ONCE when the
// puff is born; the shader animates it from `now` (the script's clock, one uniform per frame), so live puffs cost no
// per-frame CPU work. Camera-facing billboard.
//   instance transform: origin = where the puff is born, basis X = (size, 0, 0) full width in metres,
//                       basis Y = drift over its life (world metres, rise included), basis Z unused.
//   COLOR            = smoke colour (linear), a = peak opacity (0 = hidden: fog of war).
//   INSTANCE_CUSTOM  = (birth time, duration s, fade_start_pct + seed fraction, warm glow 0-1 at birth).
// Look: billowing rim (3 rolling lobe waves, no texture, no noise grid), fake round shading lit from the game's sun, a warm powder
// glow in its first ~0.3 s, soft where it meets the ground and bodies (depth fade), thins out after fade_start.
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

uniform float now = 0.0;
uniform vec3 light_dir = vec3(-0.44, 0.77, 0.46);        // world, toward the sun (set by the script)
uniform vec3 shadow_tint = vec3(0.64, 0.65, 0.73);       // the unlit side (cool, the ambient of world_env)
uniform vec3 glow_color = vec3(2.6, 0.95, 0.22);         // powder flash inside the smoke (linear HDR)
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying vec2 v_uv;
varying float v_k;
varying float v_age;
varying float v_fade_start;
varying float v_seed;
varying float v_glow;
varying vec3 v_light;

void vertex() {
	float dur = max(INSTANCE_CUSTOM.y, 0.001);
	float k = (now - INSTANCE_CUSTOM.x) / dur;
	float kk = clamp(k, 0.0, 1.0);
	vec3 origin = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float size = length((MODELVIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
	vec3 drift = (MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	// Pushed out fast, then it hangs; it swells to full size in its first third and keeps growing slowly.
	vec3 center = origin + drift * (1.0 - pow(1.0 - kk, 2.4));
	float grow = (0.42 + 0.58 * (1.0 - pow(1.0 - min(kk * 3.2, 1.0), 3.0))) * (1.0 + 0.28 * kk);
	if (k < 0.0 || k >= 1.0) {
		size = 0.0;   // not born yet / over: collapse to nothing
	}
	VERTEX = center + vec3(VERTEX.xy * size * grow, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_uv = UV;
	v_k = kk;
	v_age = kk * dur;
	v_fade_start = floor(INSTANCE_CUSTOM.z) * 0.01;
	v_seed = fract(INSTANCE_CUSTOM.z);
	v_glow = INSTANCE_CUSTOM.w;
	v_light = normalize((VIEW_MATRIX * vec4(light_dir, 0.0)).xyz);
}

void fragment() {
	vec2 p = v_uv * 2.0 - 1.0;
	p.y = -p.y;                                   // +y = up on screen
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	// Billowing, cauliflower edge: integer-frequency lobes around the rim (smooth, no noise-grid creases), slowly
	// rolling; eaten away a little as the puff thins.
	float th = atan(p.y, p.x);
	float s = v_seed * 6.2831853;
	float roll = v_k * (v_seed - 0.5) * 2.4;
	float lobes = 0.075 * sin(th * 2.0 + s + roll) + 0.05 * sin(th * 3.0 - s * 1.7 - roll * 1.3)
			+ 0.028 * sin(th * 5.0 + s * 2.3 + roll * 0.7);
	float edge = 0.8 + lobes - v_k * 0.06;
	float dens = 1.0 - smoothstep(edge - 0.5, edge, r);
	// Soft inner bulges (mottling) so overlapping puffs do not read as flat discs.
	float mott = 0.5 + 0.5 * sin(p.x * 3.3 + s * 3.0 + v_k * 1.5) * sin(p.y * 2.9 - s * 2.0 + v_k);
	dens *= 0.78 + 0.22 * mott;
	float n = 0.5 + lobes * 2.5;
	float n2 = mott;
	float life = smoothstep(0.0, 0.07, v_k) * (1.0 - smoothstep(v_fade_start, 1.0, v_k));
	// Soft contact with the ground and the bodies inside the cloud.
	float scene_depth = texture(depth_tex, SCREEN_UV).r;
	vec4 sp = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, scene_depth, 1.0);
	float touch = clamp((VERTEX.z - sp.z / sp.w) / 0.9, 0.0, 1.0);
	float a = clamp(dens * life * COLOR.a * touch, 0.0, 1.0);
	// Round, lumpy shading from the sun: bright top, cool underside.
	vec3 nrm = normalize(vec3(p.x + (n2 - 0.5) * 0.7, p.y + (n - 0.5) * 0.7, sqrt(max(0.0, 1.0 - r * r)) + 0.35));
	float lit = clamp(dot(nrm, v_light) * 0.5 + 0.5, 0.0, 1.0);
	vec3 col = COLOR.rgb * mix(shadow_tint, vec3(1.1), smoothstep(0.2, 0.92, lit));
	float warm = v_glow * exp(-v_age * 6.0) * (1.0 - smoothstep(0.1, 0.85, r)) * (0.55 + 0.9 * n);
	ALBEDO = col * a + glow_color * warm * life * (COLOR.a > 0.001 ? 1.0 : 0.0) * touch;
	ALPHA = a;
}

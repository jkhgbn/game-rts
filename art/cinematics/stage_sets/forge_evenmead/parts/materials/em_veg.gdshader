shader_type spatial;
// forge_evenmead vegetation: grass tufts, wildflowers, reeds, shrubs, tree crowns and bark (make_world.gd). Used by
// plain world meshes (at the origin) and by MultiMeshes (per-instance data in INSTANCE_CUSTOM). 0 lights, no textures.
//   COLOR.rgb  sRGB colour block (crowns carry a baked sun / shade side)
//   COLOR.a    variant mask (bits 0-7 as 1..254 / 255; 255 = always drawn): the instance draws only the parts of its
//              variant (INSTANCE_CUSTOM.w * 8), the other parts collapse to a point (zero-area, never rasterised)
//   UV.x       wind weight (0 = anchored root, 1 = free tip)
//   UV.y       kind: 0 grass / reeds / stems, 1 flower head, 2 leaves (crowns, shrubs), 3 bark (rigid)
//   UV2.x      per-part random 0..1, UV2.y height gradient 0 (root / crown underside) .. 1 (tip / crown top)
//   INSTANCE_CUSTOM  x random, y sun-dried amount 0..1 (the same field as the ground skin), z value jitter -1..1, w variant
// Grass normals lean to the sky (the meadow shades as one soft surface); thin blades, petals and leaves glow when the
// low sun is behind them (BACKLIGHT); a slow gust wave rolls across the valley.
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert_wrap, specular_schlick_ggx;

uniform vec2 wind_dir = vec2(-0.86, -0.5);
uniform float sway = 0.13;
uniform float sway_speed = 1.25;
uniform float gust_scale = 0.06;
uniform float gust_speed = 0.8;
uniform float leaf_flutter = 0.025;
uniform float ao_floor = 0.36;
uniform float translucency = 0.5;
uniform vec3 dry_tint : source_color = vec3(0.86, 0.72, 0.4);
uniform float dry_amount = 0.55;
uniform float glow = 0.0;

varying vec3 v_col;
varying float v_kind;
varying float v_ao;
varying float v_tip;

float hash1(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash1(i), hash1(i + vec2(1.0, 0.0)), f.x), mix(hash1(i + vec2(0.0, 1.0)), hash1(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	float mask = floor(COLOR.a * 255.0 + 0.5);
	bool hidden = false;
	if (mask > 0.5 && mask < 254.5) {
		float variant = floor(clamp(INSTANCE_CUSTOM.w, 0.0, 0.999) * 8.0);
		if (mod(floor(mask / exp2(variant)), 2.0) < 0.5) {
			VERTEX = vec3(0.0);
			hidden = true;
		}
	}
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w = UV.x;
	float kind = UV.y;
	float r = fract(UV2.x + INSTANCE_CUSTOM.x);
	v_kind = kind;
	v_ao = UV2.y;
	v_tip = w;
	vec3 col = pow(COLOR.rgb, vec3(2.2));
	bool green = kind < 0.5 || (kind > 1.5 && kind < 2.5);
	if (green) {
		// sun-dried swathes (the ground skin's own field) + per-tuft hue / value
		float dry = clamp(INSTANCE_CUSTOM.y, 0.0, 1.0) * dry_amount * (kind < 0.5 ? 1.0 : 0.35);
		vec3 dry_c = pow(dry_tint, vec3(2.2)) * dot(col, vec3(0.3, 0.59, 0.11)) * 2.2;
		col = mix(col, dry_c, dry * (0.35 + 0.65 * w));
		col *= mix(vec3(0.94, 1.0, 1.05), vec3(1.06, 1.02, 0.9), r);
	}
	col *= 1.0 + 0.12 * clamp(INSTANCE_CUSTOM.z, -1.0, 1.0);
	v_col = col;
	// wind: world-space sway, stronger at the tips, travelling gusts
	if (w > 0.0 && !hidden) {
		vec2 wd = normalize(wind_dir);
		float gust = 0.55 + 0.45 * sin(dot(wp.xz, wd) * gust_scale - TIME * gust_speed + vnoise(wp.xz * 0.02) * 4.0);
		float ph = r * 6.2831 + dot(wp.xz, vec2(0.23, 0.31));
		float s = (sin(TIME * sway_speed + ph) * 0.6 + sin(TIME * sway_speed * 2.3 + ph * 1.7) * 0.2 + 0.45) * gust;
		float amt = kind > 2.5 ? 0.25 : (kind > 1.5 ? 0.45 : 1.0);
		vec3 off_w = vec3(wd.x, 0.0, wd.y) * s * sway * w * w * amt;
		mat3 b = mat3(MODEL_MATRIX);
		vec3 off_l = inverse(b) * off_w;
		VERTEX += off_l;
		VERTEX.y -= dot(off_l, off_l) * 0.6;
		if (kind > 1.5 && kind < 2.5) {
			VERTEX += NORMAL * sin(TIME * 3.3 + dot(wp, vec3(4.1, 3.3, 5.7))) * leaf_flutter * w;
		}
	}
	if (kind < 0.5) {
		NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.72));
	} else if (kind < 1.5) {
		NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.35));
	}
}

void fragment() {
	float ao = mix(ao_floor, 1.0, smoothstep(0.0, 0.85, v_ao));
	vec3 col = v_col * ao;
	ALBEDO = col;
	ROUGHNESS = v_kind > 2.5 ? 0.9 : 0.74;
	SPECULAR = (v_kind > 0.5 && v_kind < 1.5) ? 0.35 : 0.2;
	if (v_kind > 0.5 && !FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	if (v_kind < 2.5) {
		BACKLIGHT = col * translucency * (0.35 + 0.65 * v_tip);
	}
	if (glow > 0.0 && v_kind > 1.5 && v_kind < 2.5) {
		EMISSION = col * glow * (0.4 + 0.6 * v_ao);
	}
}

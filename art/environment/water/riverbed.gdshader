// riverbed.gdshader - trench walls and bed under the Hollowmere river and the Crown Isle moat (task 12.V1).
// Pure world space (no UV / vertex colour needs): works on any trench mesh RiverSystem builds.
// Height layers from the bank lip (top_y, ground level 0) down to the bed:
//   lip      a dark mossy / grassy fringe hanging over the edge (ties the cut to the ground)
//   earth    dark soil with hanging roots
//   rock     chunky painted rock blocks in rough strata, darker and wetter toward the water
//   waterline a pale scum line just above water_y, then near-black wet rock under it
//   bed      (faces pointing up, deep down) mud and pebbles
// Opaque, no textures but the shared paint noise, same toon light ramp as the ground and props.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 rock_light : source_color = vec3(0.44, 0.40, 0.34);
uniform vec3 rock_dark : source_color = vec3(0.22, 0.20, 0.18);
uniform vec3 earth_color : source_color = vec3(0.27, 0.19, 0.12);
uniform vec3 moss_color : source_color = vec3(0.15, 0.27, 0.11);
uniform vec3 root_color : source_color = vec3(0.30, 0.20, 0.12);
uniform vec3 wet_color : source_color = vec3(0.07, 0.10, 0.10);
uniform vec3 scum_color : source_color = vec3(0.52, 0.58, 0.50);
uniform vec3 mud_color : source_color = vec3(0.13, 0.15, 0.11);
uniform float top_y = 0.0;         // ground / bank lip
uniform float water_y = -0.35;     // RiverSystem.WATER_Y
uniform float root_amount = 1.0;   // 0 = no roots
uniform vec2 sun_dir = vec2(0.57, 0.82);

varying vec3 v_wp;
varying vec3 v_wn;

void vertex() {
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float nz(vec2 p) {
	return texture(noise_tex, p).r;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float poster(float x, float n) {
	float f = x * n;
	float i = floor(f);
	float fr = f - i;
	float w = clamp(fwidth(f), 0.001, 0.5);
	return (i + smoothstep(0.5 - w, 0.5 + w, fr)) / n;
}

// Painted wall in one projection: u = metres along the wall, y = world height. Returns the colour.
vec3 wall(float u, float y, float h, float px, out float root_m) {
	float aa = px * 0.8;
	float n1 = nz(vec2(u * 0.35, y * 0.9));
	float n2 = nz(vec2(u * 1.3 + 3.1, y * 2.6 + 1.7));
	// Rock blocks: staggered rows ~0.16 m high, 0.3-0.6 m long, each its own value.
	float row_h = 0.16;
	float yy = y + (n1 - 0.5) * 0.08;
	float row = floor(yy / row_h);
	float uu = u / (0.42 + hash(vec2(row, 1.7)) * 0.2) + hash(vec2(row, 9.1)) * 3.0;
	float cell = floor(uu);
	float hb = hash(vec2(cell, row));
	float bu = min(fract(uu), 1.0 - fract(uu)) * 0.45;
	float bv = min(fract(yy / row_h), 1.0 - fract(yy / row_h)) * row_h;
	float joint = smoothstep(0.0, 0.025 + aa, min(bu, bv));
	vec3 rock = mix(rock_dark, rock_light, poster(clamp(0.25 + hb * 0.55 + (n2 - 0.5) * 0.35, 0.0, 1.0), 3.0));
	rock *= 0.78 + 0.22 * smoothstep(0.0, 0.05, bv);        // top of each block lit, underside dark
	rock = mix(rock * 0.45, rock, joint);
	// Earth band under the lip, rock below it (wavy border).
	float earth_t = 1.0 - smoothstep(-0.17, -0.12, h + (n1 - 0.5) * 0.12);
	vec3 c = mix(earth_color * (0.8 + n2 * 0.4), rock, earth_t);
	// Hanging roots: thin wiggly dark lines from the lip, a lit edge on one side.
	root_m = 0.0;
	if (root_amount > 0.0) {
		float rc = 0.38;
		float gid = floor(u / rc);
		float hr = hash(vec2(gid, 4.4));
		if (hr < 0.62 * root_amount) {
			float len = 0.12 + hash(vec2(gid, 8.2)) * 0.22;
			float x0 = (hr / 0.62 - 0.5) * rc * 0.6;
			float wig = sin(h * 22.0 + hr * 30.0) * 0.025 + (n2 - 0.5) * 0.03;
			float du = fract(u / rc) * rc - rc * 0.5 - x0 - wig;
			float taper = clamp(1.0 + h / len, 0.0, 1.0);
			float w = 0.012 + 0.016 * taper;
			float m = (1.0 - smoothstep(w - aa, w + aa, abs(du))) * step(-len, h);
			root_m = m;
			vec3 rcol = root_color * (0.8 + 0.4 * smoothstep(-w, w, du));
			c = mix(c * (1.0 - 0.35 * (1.0 - smoothstep(w, w * 3.0, abs(du + 0.02))) * step(-len, h)), rcol, m);
		}
	}
	// Mossy fringe at the lip, broken.
	float moss = 1.0 - smoothstep(-0.07, -0.03, h + (n2 - 0.5) * 0.06);
	moss = max(moss, (1.0 - smoothstep(-0.12, -0.08, h)) * smoothstep(0.62, 0.66, n2));
	c = mix(c, moss_color * (0.8 + n1 * 0.45), moss);
	return c;
}

void fragment() {
	vec3 p = v_wp;
	vec3 n = normalize(v_wn);
	float px = max(length(fwidth(p)), 0.0005);
	float h = p.y - top_y;
	// Sharp triplanar between the two vertical projections (roots must not double up).
	vec2 w2 = pow(abs(n.xz), vec2(8.0));
	w2 /= (w2.x + w2.y + 0.0001);
	float rm_a;
	float rm_b;
	vec3 wall_col;
	if (w2.y >= w2.x) {
		wall_col = wall(p.x, p.y, h, px, rm_a);
	} else {
		wall_col = wall(p.z + 13.7, p.y, h, px, rm_b);
	}
	// Wet darkening toward the water, pale scum line just above it, near black under it.
	float above = p.y - water_y;
	vec3 c = wall_col;
	c = mix(c, c * 0.62 + wet_color * 0.3, 1.0 - smoothstep(0.03, 0.2, above));
	float scum_n = nz(p.xz * 0.9 + vec2(p.y * 3.0, 0.0));
	float scum = (1.0 - smoothstep(0.0, 0.02 + px, abs(above - 0.035 - (scum_n - 0.5) * 0.03))) * step(0.35, scum_n);
	c = mix(c, scum_color, scum * 0.7);
	c = mix(c, wet_color, smoothstep(0.02, -0.04, above));
	// Bed: faces pointing up below the water line (and bank ledges): mud with pebbles.
	float up = smoothstep(0.55, 0.85, n.y);
	vec2 g = p.xz / 0.3;
	vec2 id = floor(g);
	float hp = hash(id);
	float peb = step(0.6, hp) * (1.0 - smoothstep(0.07, 0.09 + px, length(fract(g) - 0.5) * 0.3));
	vec3 bed = mud_color * (0.8 + nz(p.xz * 0.5) * 0.4);
	bed = mix(bed, rock_light * 0.6 * (0.8 + hp * 0.4), peb);
	c = mix(c, bed, up * (1.0 - smoothstep(-0.05, 0.05, h)));
	// Top-light and bottom AO like the painted props (lighter near the lip).
	c *= mix(0.72, 1.06, smoothstep(water_y - 0.3, top_y, p.y));
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += (0.35 + 0.65 * ramp) * ATTENUATION * LIGHT_COLOR / PI;
}

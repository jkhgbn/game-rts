// grass_blades.gdshader - the 3D grass field of GroundDetail (task G2a, docs/art/g2a_ground.md).
// One MultiMesh of grass clumps per LOD ring, centred on the camera and snapped to the clump grid, so every clump sits
// at a fixed world spot (no swimming). Per clump (vertex shader, world space):
//   - jitter, yaw, size from a hash of its grid cell;
//   - the ground's own colour and mask from GroundDetail's top-down bake of ground.gdshader (bake_mode 1 / 2): blades
//     only grow where the ground paints grass (no dirt, roads, plazas, banks, water, border), take the exact painted
//     grass colour at their root (biomes, warm / cool patches) and grow taller on the heath / riverbank;
//   - flattened and bent away round units (pushers, only units the player can see: no fog leak) and gone round
//     buildings (clears), so feet, selection rings and footprints always read;
//   - wind: a slow gust wave across the map (the trees' nature_painted wind direction) + a small flutter;
//   - fades in / out over the ring's band (lod_band) so the LOD rings and the field edge never draw a line.
// Lighting: the ground's painted ramp on a near-up normal, so a blade root is the same value as the ground under it;
// the tips catch a warm light (sun side) and the roots darken a little (contact). No shadow casting (the node).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, world_vertex_coords;

uniform sampler2D ground_col : source_color, filter_linear, repeat_disable;
uniform sampler2D ground_mask : filter_linear, repeat_disable;
uniform vec2 map_half = vec2(60.0);          // half extents (x, z) the bake covers
uniform vec2 wind_dir = vec2(0.8, 0.6);
uniform float wind_strength = 0.22;
uniform float gust_scale = 0.06;
uniform float gust_speed = 0.9;
uniform float blade_height = 0.30;
uniform float density = 0.85;                // share of grass cells that get a clump
uniform vec3 tip_tint : source_color = vec3(1.0, 0.95, 0.62);
uniform float tip_light = 0.30;
uniform float root_dark = 0.36;
uniform vec3 flower_a : source_color = vec3(0.96, 0.94, 0.86);
uniform vec3 flower_b : source_color = vec3(1.00, 0.84, 0.26);
uniform vec3 flower_c : source_color = vec3(0.72, 0.56, 0.92);
uniform vec4 pushers[48];                    // (x, z, radius, 0) visible units
uniform int pusher_count = 0;
uniform vec4 clears[32];                     // (x, z, radius, 0) buildings, crystal nodes
uniform int clear_count = 0;
uniform vec3 field_center = vec3(0.0);
// Camera-distance fade (m): blades shrink to nothing between x and y, so a far view never rasterises micro-blades
// (1-2 px wide blades under MSAA cost far more than they show; the painted 2D tufts carry the look there).
uniform vec2 cam_fade = vec2(30.0, 44.0);
instance uniform float spacing = 0.33;
instance uniform float lod_scale = 1.0;      // clump size multiplier (the far ring: bigger, sparser clumps)
instance uniform vec4 lod_band = vec4(-1.0, 0.0, 20.0, 26.0);   // fade in r0..r1, fade out r2..r3 (metres)

varying vec3 v_col;
varying float v_h;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 local = VERTEX - origin;            // clump space (the instance transform is a pure translation)
	float h = UV.y;                          // 0 root .. 1 tip
	vec2 cell = floor(origin.xz / spacing + 0.5);
	vec2 hj = hash22(cell);
	vec2 wp = origin.xz + (hj - 0.5) * spacing * 0.95;
	vec2 uv = (wp + map_half) / (2.0 * map_half);
	float r = hash12(cell + vec2(3.17, 9.71));
	float dist = length(wp - field_center.xz);
	float band = smoothstep(lod_band.x, lod_band.y, dist) * (1.0 - smoothstep(lod_band.z, lod_band.w, dist));
	float dcam = length(CAMERA_POSITION_WORLD - vec3(wp.x, 0.0, wp.y));
	band *= 1.0 - smoothstep(cam_fade.x, cam_fade.y, dcam);
	// Cheap early out (no texture read, no loops) for clumps outside the ring / too far from the camera.
	vec4 m = vec4(0.0);
	if (band > 0.0 && r < density) {
		m = textureLod(ground_mask, uv, 0.0);
	}
	float grass = smoothstep(0.30, 0.75, m.r);
	float present = step(r, density * (0.35 + 0.65 * grass)) * grass;
	float s = present * band * mix(0.7, 1.25, hj.y) * clamp(m.b * 2.0, 0.3, 1.6);
	vec2 push = vec2(0.0);
	if (s > 0.0) {
		// Buildings / crystal nodes: no grass in their footprint.
		for (int i = 0; i < 32; i++) {
			if (i >= clear_count) {
				break;
			}
			vec4 c = clears[i];
			s *= smoothstep(c.z, c.z + 0.7, length(wp - c.xy));
		}
		// Units: blades flatten and lean away (feet and selection rings stay clear).
		float flat_k = 0.0;
		for (int i = 0; i < 48; i++) {
			if (i >= pusher_count) {
				break;
			}
			vec4 pu = pushers[i];
			vec2 d = wp - pu.xy;
			float l = length(d);
			float f = 1.0 - smoothstep(pu.z * 0.75, pu.z * 1.6, l);
			if (f > 0.0) {
				flat_k = max(flat_k, f);
				push += d / max(l, 0.05) * f;
			}
		}
		s *= 1.0 - flat_k * 0.8;
	}
	float height = blade_height * s;
	if (height < 0.01) {
		VERTEX = vec3(origin.x, -8.0, origin.z);   // every vertex of the clump on one point: never rasterised
	} else {
		float yaw = r * 6.2832 + hj.x * 3.0;
		float cy = cos(yaw);
		float sy = sin(yaw);
		vec2 lxz = vec2(local.x * cy - local.z * sy, local.x * sy + local.z * cy) * lod_scale * mix(0.8, 1.2, hj.x);
		float ly = local.y * height;
		// Wind: a gust wave travelling across the map + a per-clump flutter; bend grows with height squared.
		vec2 wd = normalize(wind_dir);
		float gust = 0.55 + 0.45 * sin(dot(wp, wd) * gust_scale - TIME * gust_speed);
		float sway = (sin(TIME * 1.7 + dot(wp, vec2(0.71, 0.37)) + hj.x * 6.0) * 0.5 + 0.6) * gust;
		float flutter = sin(TIME * 4.3 + hj.y * 20.0 + local.x * 9.0) * 0.08;
		vec2 bend = (wd * (sway * wind_strength + flutter * 0.3) + push * 0.9) * h * h * height * 2.2;
		vec3 wpos = vec3(wp.x + lxz.x + bend.x, ly, wp.y + lxz.y + bend.y);
		wpos.y -= dot(bend, bend) * 0.5;
		VERTEX = wpos;
	}
	vec3 base = height < 0.01 ? vec3(0.0) : textureLod(ground_col, uv, 0.0).rgb;
	// Per clump: value and a warm (yellow-green) / cool (blue-green) shift; per blade a little more value.
	float v = mix(0.86, 1.12, hj.y) * mix(0.94, 1.08, fract(UV.x * 5.31 + r));
	vec3 col = base * v;
	col *= mix(vec3(0.94, 1.0, 1.06), vec3(1.08, 1.04, 0.86), fract(r * 3.7));
	col *= mix(1.0 - root_dark, 1.0, smoothstep(0.0, 0.45, h));
	col = mix(col, col * tip_tint * (1.0 + tip_light * 2.0), smoothstep(0.55, 1.0, h) * tip_light * 2.5);
	// Flower heads: in the ground's flower patches a few clumps carry a coloured tip.
	if (m.g > 0.5 && fract(r * 7.13) < 0.22 && UV.x > 0.85) {
		float pick = fract(r * 13.7);
		vec3 fc = pick < 0.45 ? flower_a : (pick < 0.75 ? flower_b : flower_c);
		col = mix(col, fc, smoothstep(0.8, 0.95, h));
	}
	v_col = col;
	v_h = h;
}

void fragment() {
	ALBEDO = v_col;
	// Both faces light like the flat ground (a back face would otherwise get a flipped, dark normal).
	NORMAL = normalize(mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0));
	ROUGHNESS = 1.0;
	SPECULAR = 0.3;
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
	DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
}

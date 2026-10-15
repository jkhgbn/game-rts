// unit_painted.gdshader - CHARACTER copy of art/shaders/painted.gdshader (art-units.md 2.4) + 2 instance uniforms:
//   hit_flash (0-1) and flash_color (vec3, white = hit, gold = level-up): EMISSION += flash_color * hit_flash * 2.0.
// Keep the rest identical to painted.gdshader (that file is not edited so the keeps' look cannot change).
//
// Uniforms:
//   base_color      vec3   flat colour block (no albedo textures)
//   noise_tex       sampler2D  seamless noise (use res://art/shaders/paint_noise.tres), sampled triplanar in world space
//   noise_scale_a   float  UV per metre of the fine paint blotches (tint +-10 %)
//   noise_scale_b   float  UV per metre of the broad paint blotches (tint +-6 %)
//   spec_strength   float  0 = stone, 0.25-0.4 = metal / obsidian
//   rim_color       vec3   soft rim light colour (selection: team colour)
//   rim_strength    float  0.25 idle, 0.9 selected
//   crack_strength  float  0 = no glowing cracks
//   crack_color     vec3   crack glow colour
//   crack_speed     float  crack pulse speed
//   crack_scale     float  metres per crack cell (0.8)
//   damage          float  0-1, widens cracks and darkens (soot)
//   top_color       vec3   colour the top-facing planes lean to (helmets, shoulders, hoods seen from the RTS camera)
//   top_lift        float  0 = off (default: every existing material unchanged); 0.3-0.6 = a lighter crown that
//                          separates dark units from each other at zoom 30 (Shadow army, in-game grade 2026-09-30)
// Instance uniforms (per MeshInstance3D / MultiMeshInstance3D, "instance_shader_parameters/..."):
//   ao_bottom       float  world y of the part's bottom (contact band starts here)
//   ao_height       float  height of the gradient (use the whole building's height for a building)
//   (G3b, unit_paint.gdshaderinc) surface_kind, detail_strength, sheen_strength, shade_tint, crease_tint, env_strength,
//   light_rim: the painted-PBR layer (soft wrap light, per-surface sheen / spec, procedural cloth / metal / leather
//   detail, metal fake reflection); instance uniform kit_detail (slot 12) = the cost tier the kit writes.
// Every instance uniform has an explicit instance_index(N) from the kit slot map (kit/README.md, task A.16): one
// merged mesh mixes painted, glow and banner surfaces, and they must never share a slot.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 base_color : source_color = vec3(0.30, 0.26, 0.24);
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float noise_scale_a = 0.5;
uniform float noise_scale_b = 0.12;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 rim_color : source_color = vec3(0.55, 0.65, 0.85);
uniform float rim_strength = 0.25;
uniform float crack_strength = 0.0;
uniform vec3 crack_color : source_color = vec3(1.0, 0.55, 0.15);
uniform float crack_speed = 1.2;
uniform float crack_scale = 0.8;
uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform vec3 top_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float top_lift : hint_range(0.0, 1.0) = 0.0;

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 10.0;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float kit_detail : instance_index(12) = 2.0;

#include "res://art/units/kit/unit_paint.gdshaderinc"

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_local_pos;
varying vec3 v_local_normal;
varying vec3 v_mat;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_local_pos = VERTEX;
	v_local_normal = NORMAL;
}

float triplanar(vec3 p, vec3 n, float scale) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z + 0.0001);
	float x = texture(noise_tex, p.zy * scale).r;
	float y = texture(noise_tex, p.xz * scale).r;
	float z = texture(noise_tex, p.xy * scale).r;
	return x * w.x + y * w.y + z * w.z;
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	float na = triplanar(v_world_pos, n, noise_scale_a);
	float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 albedo = base_color * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
	if (top_lift > 0.0) {
		albedo = mix(albedo, top_color * (1.0 + (na - 0.5) * 0.20), top_lift * smoothstep(0.35, 0.9, n.y));
	}

	// G3b painted-PBR layer (sky catch, crease tint, per-surface detail, metal reflection).
	int kind = up_kind(spec_strength);
	float bump_h = 0.0;
	vec3 env_emit = vec3(0.0);
	float px = length(fwidth(v_local_pos));
	albedo = up_albedo(albedo, kind, kit_detail, v_local_pos, normalize(v_local_normal), n, na, nb, px,
			v_world_pos, CAMERA_POSITION_WORLD, noise_tex, bump_h, env_emit);
	v_mat = vec3(spec_strength, float(kind), kit_detail);

	// Height gradient (fake sky light + AO) and dark contact band.
	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));
	// G3b: a stronger top-to-bottom value read (light crowns, darker legs) from Medium up; zoom-30 readability.
	if (kit_detail > 0.5) {
		albedo *= mix(0.84, 1.07, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	}

	// Glowing cracks / veins (ridged noise).
	vec3 emission = env_emit;
	if (crack_strength > 0.0) {
		float rn = triplanar(v_world_pos + vec3(3.1, 0.0, 7.7), n, 1.0 / (crack_scale * 8.0));
		float ridged = 1.0 - abs(rn * 2.0 - 1.0);
		// Thin lines, only inside patches of the broad noise (damage widens both).
		float c = smoothstep(0.95 - damage * 0.06, 0.985, ridged)
			* smoothstep(0.52 - damage * 0.35, 0.62, nb) * crack_strength;
		emission += crack_color * c * (2.0 + 1.0 * sin(TIME * crack_speed + v_world_pos.y * 1.7));
		albedo = mix(albedo, crack_color * 0.3, c * 0.5);
	}
	albedo *= 1.0 - damage * 0.35;

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	// G3b: the rim fades on the undersides (from the RTS camera a full ring made units look cut out and floating).
	emission += rim * rim_color * rim_strength * mix(0.55, 1.15, smoothstep(-0.4, 0.6, n.y));
	if (kit_detail > 1.5 && kind != UK_PLAIN && kind != UK_SKIN) {
		NORMAL = up_bump(NORMAL, VERTEX, bump_h);   // uniform branch: the derivatives stay defined
	}

	// A.17: the gold level-up flash (low blue, mid green: hit white, Ice freeze blue, Fire ember are untouched) also tints
	// the surface, so pale and blue parts turn gold instead of adding up to white.
	float warm = clamp(hit_flash * 2.4, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.4, flash_color.b))
		* smoothstep(0.42, 0.5, flash_color.g);
	vec3 tint = mix(vec3(1.0), flash_color, warm);
	ALBEDO = albedo * tint;
	EMISSION = emission * tint + flash_color * hit_flash * 2.0;
	ROUGHNESS = 1.0;
}

void light() {
	vec3 dl = vec3(0.0);
	vec3 sl = vec3(0.0);
	up_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, ALBEDO, v_mat, dl, sl);
	DIFFUSE_LIGHT += dl;
	SPECULAR_LIGHT += sl;
}

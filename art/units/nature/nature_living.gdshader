// nature_living.gdshader - the Nature army's living-wood variant of art/units/kit/unit_painted.gdshader (G-C Nature
// units, docs/art/gc_nature_units.md). Same uniforms, paint noise, G3b painted-PBR layer (unit_paint.gdshaderinc),
// height gradient, rim, hit / level-up flash and the SAME instance uniforms on the same kit slots (kit/README.md), so
// the kit drives it exactly like unit_painted (flash targets, kit_detail, team colour duplicates). It adds, per part:
//   leaves   (mesh UV.x in -3..-2, UV.y base 0 .. tip 1, written by NatureModel.leaf_mesh): a pale midrib + side veins,
//            lighter rim / tip, a darker base, silver-sage undersides, light through the leaf when the sun is behind it
//   thorns   (mesh UV.x in -5..-4, NatureModel.thorn_cone): dark at the root, pale bone at the tip, a glint on the point
//   bark     (uniform `bark`): long wavy furrows wrapped round the pivot's vertical axis (as on Ysolde's gown), plates
//            between them lighter, furrows bend the normal close up
//   sap      (uniform `sap`): glowing sap in some furrows, pulsing upward; only below ~22 m (zoom 10, portraits):
//            emission on the unit's own mesh, so the fog of war hides it with the unit
//   lichen   (uniform `lichen`): pale silver-green lichen on the upward planes (shoulders, crowns): a value step on top
//            that keeps the unit off the green grass at zoom 30-40
// Every pattern is sampled in MESH space (the merged pivot mesh): nothing swims when the unit walks.
// Cost tiers (kit_detail, written by the kit; defaults to 0 = Low here per the shader-tier rule):
//   0 Low: leaf two-tone / rim, thorn tip gradient, bark plates (one texture read) - ALU only otherwise
//   1 Medium: + leaf veins, leaf translucency, lichen, the G3b sky catch / folds
//   2 High / Ultra: + sap glow near the camera, furrow bump
// Derivatives (fwidth, dFdx / dFdy for the bark textureGrad) are taken at the top of fragment(); the per-part branches
// (UV tags) read no texture; the bark reads use textureGrad (no mip seam where the atan angle wraps).
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
uniform float dye_sat : hint_range(0.0, 1.5) = 1.0;   // G-E value pass: base_color grade, as in unit_painted
uniform float dye_val : hint_range(0.0, 1.5) = 1.0;

// Nature layers (0 = off: an untouched copy of a unit_painted material looks the same as before).
uniform float bark : hint_range(0.0, 1.0) = 0.0;
uniform float bark_density = 7.0;      // furrow tiles round the axis (integer: no seam)
uniform float bark_stretch = 0.6;      // noise tiles per metre along the axis (small = long furrows)
uniform float sap : hint_range(0.0, 1.0) = 0.0;
uniform vec3 sap_color : source_color = vec3(0.75, 1.00, 0.40);
uniform float sap_energy = 1.4;
uniform float lichen : hint_range(0.0, 1.0) = 0.0;
uniform vec3 lichen_color : source_color = vec3(0.88, 0.82, 0.66);   // G-E value pass: pale warm bone (was silver-green)
uniform float leaf_detail : hint_range(0.0, 1.0) = 1.0;     // veins / rim on UV-tagged leaves
uniform vec3 leaf_under : source_color = vec3(0.78, 0.84, 0.74);   // silver-sage underside (mixed with the colour)
uniform vec3 leaf_rim : source_color = vec3(0.98, 0.84, 0.50);     // pale rim / tip tint (G-E value pass: warmer gold)
uniform float leaf_glow : hint_range(0.0, 1.0) = 0.45;      // light through the leaf (Medium+)
uniform vec3 thorn_tip : source_color = vec3(0.93, 0.88, 0.74);    // pale bone point of UV-tagged thorns
uniform float thorn_tip_mix : hint_range(0.0, 1.0) = 0.85;

instance uniform float ao_bottom : instance_index(1) = 0.0;
instance uniform float ao_height : instance_index(2) = 10.0;
instance uniform float hit_flash : instance_index(3) = 0.0;
instance uniform vec3 flash_color : instance_index(4) = vec3(1.0, 1.0, 1.0);
instance uniform float kit_detail : instance_index(12) = 0.0;

#include "res://art/units/kit/unit_paint.gdshaderinc"

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_local_pos;
varying vec3 v_local_normal;
varying vec3 v_mat;
varying float v_leaf;

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
	// Derivatives first (shader-tier rule: never inside a branch on a per-fragment value).
	float px = length(fwidth(v_local_pos));
	// Screen gradients of the bark UV (angle round the pivot axis, height), from the UNWRAPPED inputs: the atan angle
	// jumps by 1 where it wraps, its analytic derivative does not, so textureGrad picks the right mip there (no seam).
	vec3 dpx = dFdx(v_local_pos);
	vec3 dpy = dFdy(v_local_pos);
	vec2 dang = vec2(-v_local_pos.z, v_local_pos.x) / (6.2831853 * max(dot(v_local_pos.xz, v_local_pos.xz), 1e-6));
	vec2 bark_gx = vec2(dot(dang, dpx.xz) * bark_density, dpx.y * bark_stretch);
	vec2 bark_gy = vec2(dot(dang, dpy.xz) * bark_density, dpy.y * bark_stretch);
	float na = triplanar(v_world_pos, n, noise_scale_a);
	float nb = triplanar(v_world_pos + vec3(17.3, 5.1, 9.7), n, noise_scale_b);
	vec3 bc = base_color;
	if (dye_sat != 1.0 || dye_val != 1.0) {
		vec3 dg = sqrt(max(bc, vec3(0.0)));   // graded in a perceptual (gamma 2) space: hue kept
		dg = mix(vec3(dot(dg, vec3(0.2126, 0.7152, 0.0722))), dg, dye_sat) * dye_val;
		bc = dg * dg;
	}
	vec3 albedo = bc * (1.0 + (na - 0.5) * 0.20) * (1.0 + (nb - 0.5) * 0.12);
	if (top_lift > 0.0) {
		albedo = mix(albedo, top_color * (1.0 + (na - 0.5) * 0.20), top_lift * smoothstep(0.35, 0.9, n.y));
	}
	vec3 emission = vec3(0.0);
	float dist = length(VERTEX);
	float bark_bump = 0.0;
	float leaf = 0.0;

	// ---- Per-part looks from the mesh UV tag (leaves -3..-2, thorns -5..-4; kit primitives, lathes, tubes stay >= 0).
	float tag = UV.x;
	if (tag < -1.5 && tag > -3.5) {
		leaf = 1.0;
		float u = clamp(tag + 3.0, 0.0, 1.0);
		float v = clamp(UV.y, 0.0, 1.0);
		float wprof = max(sin(3.14159 * pow(max(v, 0.001), 0.8)), 0.08);
		float e = clamp(abs(u - 0.5) * 2.0 / wprof, 0.0, 1.0);   // 0 midrib .. 1 edge
		// Two-tone: darker at the stalk, lighter toward the tip; a pale rim.
		albedo *= mix(0.78, 1.12, smoothstep(0.0, 0.85, v));
		albedo = mix(albedo, leaf_rim * dot(albedo, vec3(0.45)) * 2.0, smoothstep(0.62, 1.0, e) * 0.30 * leaf_detail);
		// Undersides (the planes turned to the ground: drooping leaves, skirts) go silver-sage.
		float under = smoothstep(-0.05, -0.55, n.y);
		albedo = mix(albedo, leaf_under * dot(albedo, vec3(0.6, 0.9, 0.3)) * 1.25, under * 0.55);
		if (kit_detail > 0.5) {
			// Midrib + side veins (fade out before they shimmer: veins ~4 cm apart on a 30 cm leaf).
			float vf = up_fade(0.035, px) * leaf_detail;
			float rib = (1.0 - smoothstep(0.04, 0.13, e)) * smoothstep(0.02, 0.10, v) * (1.0 - smoothstep(0.85, 1.0, v));
			float s = fract(v * 6.0 - e * 1.4);
			float side = smoothstep(0.84, 0.95, s) * (1.0 - smoothstep(0.92, 0.99, s)) * smoothstep(0.08, 0.2, e)
				* (1.0 - smoothstep(0.75, 0.95, e)) * vf;
			albedo = mix(albedo, leaf_rim * dot(albedo, vec3(0.5)) * 1.9, clamp(rib * 0.55 * leaf_detail + side * 0.35, 0.0, 1.0));
		}
	} else if (tag < -3.5 && tag > -5.5) {
		// Thorn: v 0 = tip, 1 = root. Dark root (it grows out of the bark), pale bone point.
		float v = clamp(UV.y, 0.0, 1.0);
		float tip = 1.0 - smoothstep(0.05, 0.75, v);
		albedo = mix(albedo * 0.75, thorn_tip * (0.9 + 0.2 * na), tip * thorn_tip_mix);
		emission += thorn_tip * 0.06 * smoothstep(0.85, 1.0, 1.0 - v);
	}

	// ---- Bark furrows (+ sap) round the pivot's vertical axis, in mesh space.
	if (bark > 0.0) {
		float ang = atan(v_local_pos.z, v_local_pos.x) / 6.2831853;
		vec2 buv = vec2(ang * bark_density, v_local_pos.y * bark_stretch);
		float f = textureGrad(noise_tex, buv, bark_gx, bark_gy).r;   // gradients from the top of fragment()
		float ridged = 1.0 - abs(f * 2.0 - 1.0);
		float furrow = smoothstep(0.76, 0.95, ridged);
		// Furrows and plates fade out past ~15-25 m (zoom 30-40 keeps clean value blocks: Art Lab P4 detail density).
		float nf = 1.0 - smoothstep(0.012, 0.028, px);
		albedo *= 1.0 + (f - 0.5) * 0.30 * bark * (0.35 + 0.65 * nf);
		albedo *= 1.0 - 0.42 * furrow * bark * nf;
		bark_bump = -furrow * 0.004 * bark;
		if (sap > 0.0 && kit_detail > 1.5) {
			float near = 1.0 - smoothstep(14.0, 22.0, dist);
			if (near > 0.0) {
				float mask = smoothstep(0.62, 0.74, textureGrad(noise_tex, buv * vec2(0.5, 0.37) + vec2(0.31, 0.57),
					bark_gx * vec2(0.5, 0.37), bark_gy * vec2(0.5, 0.37)).r);
				float core = smoothstep(0.93, 0.99, ridged) * mask;
				float flow = 0.5 + 0.5 * sin(v_local_pos.y * 5.0 - TIME * 3.0 + ang * 37.0);
				emission += sap_color * sap_energy * sap * core * (0.35 + 0.65 * flow) * near;
				albedo = mix(albedo, sap_color * 0.45, core * sap * 0.6 * near);
			}
		}
	}

	// ---- Lichen on the upward planes (pale value step on top), Medium+.
	if (lichen > 0.0 && kit_detail > 0.5) {
		float ln = texture(noise_tex, v_local_pos.xz * 4.2 + v_local_pos.y * 1.3).r;
		// Close: patches; far (~25 m+): an even, lighter wash on the tops (no speckle at zoom 30-40).
		float lf = 1.0 - smoothstep(0.012, 0.028, px);
		float m = smoothstep(0.30, 0.75, n.y) * mix(0.30, smoothstep(0.50, 0.66, ln), lf) * lichen;
		albedo = mix(albedo, lichen_color * (0.85 + 0.3 * ln), m);
	}

	// G3b painted-PBR layer (sky catch, crease tint, per-surface detail, metal reflection).
	int kind = up_kind(spec_strength);
	float bump_h = 0.0;
	vec3 env_emit = vec3(0.0);
	albedo = up_albedo(albedo, kind, kit_detail, v_local_pos, normalize(v_local_normal), n, na, nb, px,
			v_world_pos, CAMERA_POSITION_WORLD, noise_tex, bump_h, env_emit);
	bump_h += bark_bump * up_fade(0.08, px);
	v_mat = vec3(spec_strength, float(kind), kit_detail);
	v_leaf = leaf;

	// Height gradient (fake sky light + AO) and dark contact band.
	float h = v_world_pos.y - ao_bottom;
	albedo *= mix(0.72, 1.08, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	albedo *= mix(0.55, 1.0, smoothstep(0.0, 0.35, h));
	if (kit_detail > 0.5) {
		albedo *= mix(0.84, 1.07, smoothstep(0.0, 1.0, h / max(ao_height, 0.01)));
	}

	// Glowing cracks / veins (ridged noise), as in unit_painted.
	emission += env_emit;
	if (crack_strength > 0.0) {
		float rn = triplanar(v_world_pos + vec3(3.1, 0.0, 7.7), n, 1.0 / (crack_scale * 8.0));
		float ridged2 = 1.0 - abs(rn * 2.0 - 1.0);
		float c = smoothstep(0.95 - damage * 0.06, 0.985, ridged2)
			* smoothstep(0.52 - damage * 0.35, 0.62, nb) * crack_strength;
		emission += crack_color * c * (2.0 + 1.0 * sin(TIME * crack_speed + v_world_pos.y * 1.7));
		albedo = mix(albedo, crack_color * 0.3, c * 0.5);
	}
	albedo *= 1.0 - damage * 0.35;

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emission += rim * rim_color * rim_strength * mix(0.55, 1.15, smoothstep(-0.4, 0.6, n.y));
	if (kit_detail > 1.5 && (bark > 0.0 || (kind != UK_PLAIN && kind != UK_SKIN))) {
		NORMAL = up_bump(NORMAL, VERTEX, bump_h);   // uniform branch: the derivatives stay defined
	}

	// A.17: the gold level-up flash tints the surface (see unit_painted.gdshader).
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
	// Leaves: the sun through the leaf on its turned-away side (warm-green glow, Medium+).
	if (v_mat.z > 0.5 && v_leaf > 0.5) {
		float back = clamp(-dot(NORMAL, LIGHT), 0.0, 1.0);
		dl += LIGHT_COLOR * ATTENUATION / PI * up_hue(ALBEDO) * vec3(1.0, 1.0, 0.75) * back * leaf_glow;
	}
	DIFFUSE_LIGHT += dl;
	SPECULAR_LIGHT += sl;
}

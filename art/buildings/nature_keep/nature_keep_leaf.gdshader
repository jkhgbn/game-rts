// nature_keep_leaf.gdshader - the Heartwood's cut-out cards (task A2.5): leaves that fringe the canopy clumps,
// blossoms on its top, and the petals of the Crown Bloom. One merged mesh per group; per card data in UV2:
//   UV   0..1 on the card, y = 0 at the attached end (stem / petal base), y = 1 at the free tip
//   UV2  x = the card's random id (0..1), y = its sway phase
//   COLOR.r baked occlusion (1 = open)
// Shapes: 0 leaf (pointed oval, midrib, lit tip), 1 blossom (five round petals, glowing heart),
//         2 bloom petal (long rounded petal, glowing base fading to a pale tip).
// The cards sway from their free end. `drop` removes a fraction of the cards (damage), `wither` browns them.
// Lighting uses the mesh normal (soft, pointing out of the clump) on BOTH sides of a card; toon ramp like
// the painted shader, so the cards melt into the clump bodies.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform int shape = 0;
uniform vec3 base_color : source_color = vec3(0.35, 0.70, 0.25);
uniform vec3 tip_tint = vec3(1.25, 1.2, 0.72); // multiplier (linear)
uniform vec3 edge_color : source_color = vec3(1.0, 0.92, 0.95);
uniform vec3 glow_color : source_color = vec3(0.75, 1.00, 0.40);
uniform float glow_energy = 2.2;
uniform float boost = 1.0;
uniform float leaf_value = 0.8;  // leaves sit darker than the light team colour (matches the foliage clumps)
uniform float sway = 0.08;
uniform float sway_speed = 1.6;
uniform float drop : hint_range(0.0, 1.0) = 0.0;
uniform float wither : hint_range(0.0, 1.0) = 0.0;
uniform vec3 wither_color : source_color = vec3(0.56, 0.42, 0.17);
uniform vec3 rim_color : source_color = vec3(0.72, 0.88, 0.55);
uniform float rim_strength = 0.2;
uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform float ao_low = 8.5;     // world y where the cards are darkest (under the canopy)
uniform float ao_span = 7.0;

varying vec3 v_world_pos;

#include "res://art/buildings/nature/nature_paint.gdshaderinc"

void vertex() {
	float w = UV.y;
	float ph = UV2.y * 6.2831853;
	vec3 wv = vec3(sin(TIME * sway_speed + ph), 0.35 * sin(TIME * sway_speed * 1.37 + ph * 1.7),
		cos(TIME * sway_speed * 0.83 + ph * 0.6));
	VERTEX += wv * sway * w * w;
	if (gfx_detail >= 1) {
		VERTEX += nv_wind_local(MODEL_MATRIX, VERTEX, TIME);   // G-B: move with the clump they fringe
	}
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash11(float x) {
	return fract(sin(x * 91.713 + 7.1) * 43758.5453);
}

void fragment() {
	float id = UV2.x;
	if (hash11(id * 13.7) < drop) {
		discard;
	}
	vec3 col = base_color;
	vec3 emission = vec3(0.0);
	float x = (UV.x - 0.5) * 2.0;
	float y = UV.y;
	if (shape == 0) {
		// Pointed oval: widest at 45 %, both ends pointed.
		float half_w = pow(sin(3.14159 * clamp(y, 0.0, 1.0)), 0.75) * (0.92 - 0.25 * y);
		if (abs(x) > half_w || y > 0.99) {
			discard;
		}
		float rib = 1.0 - smoothstep(0.03, 0.09, abs(x));
		float veins = smoothstep(0.75, 0.95, sin((y * 9.0 - abs(x) * 5.0) * 3.14159)) * (1.0 - rib) * 0.5;
		col *= leaf_value * (1.0 + (hash11(id * 3.3) - 0.5) * 0.22);
		col = mix(col, col * tip_tint, smoothstep(0.35, 1.0, y) * 0.8);
		col *= mix(1.0, 0.72, rib) * (1.0 - veins * 0.18);
		col *= mix(0.9, 1.05, smoothstep(0.0, half_w, half_w - abs(x)));
		float wm = step(hash11(id * 7.9 + 1.3), wither);
		col = mix(col, wither_color * (0.8 + 0.4 * hash11(id * 5.1)), wm);
	} else if (shape == 1) {
		vec2 p = vec2(x, (y - 0.5) * 2.0);
		float r = length(p);
		float a = atan(p.y, p.x) + id * 6.2831853;
		float petal_r = 0.62 + 0.36 * pow(abs(cos(a * 2.5)), 0.7);
		if (r > petal_r) {
			discard;
		}
		float k = r / petal_r;
		col = mix(col * 0.82, edge_color, smoothstep(0.55, 1.0, k) * 0.55);
		col *= 1.0 - (1.0 - smoothstep(0.0, 0.2, abs(sin(a * 2.5)))) * 0.12 * step(0.3, k);
		float heart = 1.0 - smoothstep(0.16, 0.3, r);
		col = mix(col, glow_color, heart);
		emission += glow_color * glow_energy * boost * heart;
		emission += col * 0.12;
	} else {
		// Bloom petal: rounded tip, narrow base, glow rising from the base.
		float half_w = sin(3.14159 * clamp(y * 0.62 + 0.12, 0.0, 1.0)) * 0.95;
		float tip = y > 0.8 ? sqrt(max(1.0 - pow((y - 0.8) / 0.2, 2.0), 0.0)) : 1.0;
		half_w *= tip;
		if (abs(x) > half_w || y > 0.995) {
			discard;
		}
		float base_glow = 1.0 - smoothstep(0.0, 0.55, y);
		col = mix(col, edge_color, smoothstep(0.55, 1.0, y) * 0.5 + smoothstep(0.7, 1.0, abs(x) / max(half_w, 0.01)) * 0.3);
		col *= 1.0 - (1.0 - smoothstep(0.02, 0.08, abs(x))) * 0.12;
		col = mix(col, glow_color, base_glow * 0.8);
		emission += glow_color * glow_energy * boost * base_glow * base_glow;
		emission += col * 0.15;
	}
	// Baked occlusion from the builder (COLOR.r), height shade (darker deep under the canopy), damage soot.
	col *= mix(shape == 0 ? 0.4 : 0.65, 1.0, COLOR.r);
	col *= mix(0.7, 1.08, smoothstep(0.0, 1.0, (v_world_pos.y - ao_low) / max(ao_span, 0.01)));
	col *= 1.0 - damage * 0.25;
	// Godot flips NORMAL on back faces of cull_disabled materials: undo it, so both sides of a card use the
	// soft "out of the clump" normal of the mesh (a leaf seen from behind is lit like the clump, not dark).
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	ALBEDO = col;
	EMISSION = emission + rim * rim_color * rim_strength;
	ROUGHNESS = 1.0;
}

void light() {
	// Thin cards: a little light passes through (never fully dark); G-B Medium+ adds translucency (nature_paint).
	nv_light(NORMAL, LIGHT, VIEW, LIGHT_COLOR, ATTENUATION, ALBEDO, 0.0, 4, 0.0, DIFFUSE_LIGHT, SPECULAR_LIGHT);
}

// essence_well_essence.gdshader - the glowing essence of the well (task 12.V19): the brimming pool in the shaft, the
// violet crystals growing out of the cracked stones and the small spill by the tipped bucket. ONE shared material
// (essence_well_essence_mat.tres), unshaded (it is the light source of the scene; no real light). The essence is always
// violet (the colour of the Essence resource), whoever owns the well: the owner colour lives on the rim runes.
// Baked by build_essence_well.gd:
//   UV2.x  mode: 0 pool surface, 1 crystal, 2 spill puddle
//   UV     pool / spill: local position / radius (-1..1); crystal: (facet index, 0 at the base -> 1 at the tip)
// Instance uniforms (essence_well.gd): flare (income pulse / capture flash, 0-1), brim (0 = drained look, 1 = brimming).
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 deep : source_color = vec3(0.20, 0.06, 0.40);
uniform vec3 bright : source_color = vec3(0.74, 0.42, 1.0);
uniform vec3 core : source_color = vec3(0.98, 0.84, 1.0);
uniform float energy = 2.6;
uniform float swirl_speed = 0.32;

instance uniform float flare = 0.0;
instance uniform float brim = 1.0;

varying vec2 v_uv;
varying flat float v_mode;
varying vec3 v_wn;

void vertex() {
	v_uv = UV;
	v_mode = UV2.x;
	v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	if (UV2.x < 0.5) {
		// A slow swell on the pool (the rim hides the edge).
		float r = length(UV);
		VERTEX.y += sin(TIME * 1.3 + dot(VERTEX.xz, vec2(5.1, 3.7))) * 0.012 * (1.0 - r * r);
	}
}

void fragment() {
	vec3 col;
	float boost = (1.0 + flare * 1.3) * mix(0.35, 1.0, brim);
	if (v_mode < 0.5 || v_mode > 1.5) {
		// Pool / spill: a painted swirl (noise in a rotating, twisting frame), bright streaks over deep violet, a hot core
		// and a bright meniscus where it meets the stone.
		vec2 p = v_uv;
		float r = length(p);
		float spill = step(1.5, v_mode);
		float a = atan(p.y, p.x) + (1.0 - r) * 2.4 * (1.0 - spill) + TIME * swirl_speed * (1.0 - spill * 0.8);
		vec2 q = vec2(cos(a), sin(a)) * r;
		float n1 = texture(noise_tex, q * 0.85 + vec2(TIME * 0.02, 0.0)).r;
		float n2 = texture(noise_tex, q * 2.2 + vec2(3.1, -TIME * 0.045)).r;
		float v = n1 * 0.62 + n2 * 0.38;
		float streak = mix(smoothstep(0.50, 0.70, v), 0.55 + (v - 0.5) * 0.8, spill * 0.6);
		col = mix(deep, bright, streak * 0.85 + 0.1);
		col *= 0.55 + energy * (0.18 + 0.42 * streak);
		col += core * pow(max(1.0 - r, 0.0), 3.0) * energy * 0.32 * (1.0 - spill);
		col += bright * smoothstep(0.80, 0.97, r) * energy * 0.35 * (1.0 - spill);
		// The spill fades into the ground at its ragged edge (dark wet stain first).
		col *= mix(1.0, 0.25 + smoothstep(1.0, 0.5, r) * 0.75, spill);
	} else {
		// Crystal: faceted (a fixed painted light from the upper left), brighter toward the tip, slow shimmer.
		float facet = dot(normalize(v_wn), normalize(vec3(-0.45, 0.75, 0.5))) * 0.5 + 0.5;
		float h = v_uv.y;
		col = mix(deep * 1.6, bright, smoothstep(0.15, 0.95, facet));
		float shimmer = 0.85 + 0.15 * sin(TIME * 1.7 + h * 3.0 + v_uv.x * 1.3);
		col *= (0.7 + h * energy * 0.55) * shimmer;
	}
	ALBEDO = col * boost;
}

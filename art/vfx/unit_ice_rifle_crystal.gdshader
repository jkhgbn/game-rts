shader_type spatial;
// Rime Lock freeze spikes (UnitIceRifleVfx, task 13b.V7): a MultiMesh of hexagonal ice spikes (a CylinderMesh cone,
// height 1 centred on 0) that erupt around the frozen target. ONE material; per set `fade` (instance uniform) melts
// the spikes from the tip down (a ragged dissolve, so they shatter rather than fade), `age` (s) flashes them white-blue
// as they erupt. Lit (the sun shapes the facets) + bright facet edges and fresnel so they read as ice at 40 m.
render_mode blend_mix, depth_draw_opaque, cull_back, shadows_disabled, specular_schlick_ggx;

uniform vec3 ice_color : source_color = vec3(0.62, 0.84, 1.00);
uniform vec3 deep_color : source_color = vec3(0.20, 0.42, 0.76);
uniform vec3 edge_color : source_color = vec3(0.80, 0.96, 1.00);
instance uniform float fade = 1.0;
instance uniform float age = 0.0;
instance uniform float seed = 0.0;

varying vec3 lp;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float h = clamp(lp.y + 0.5, 0.0, 1.0);            // 0 base, 1 tip
	float ang = atan(lp.z, lp.x);
	float n = hash(vec2(floor(ang * 3.0 + 10.0), floor(h * 7.0) + seed * 13.0));
	float cut = fade * 1.15 - 0.1 + (n - 0.5) * 0.18;
	if (h > cut) {
		discard;
	}
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float facet = abs(fract(ang / 1.0471976) - 0.5) * 2.0;   // 1 on the hex edges
	float edges = smoothstep(0.8, 0.98, facet);
	float melt_edge = 1.0 - smoothstep(0.0, 0.06, cut - h);  // glowing rim where it dissolves
	float flash = exp(-age * 6.0);
	vec3 base = mix(deep_color, ice_color, smoothstep(0.0, 0.8, h));
	ALBEDO = base;
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
	EMISSION = base * 0.35 + edge_color * (edges * 0.8 + fres * 0.9 + melt_edge * (fade < 0.999 ? 1.8 : 0.0)
			+ smoothstep(0.75, 1.0, h) * 0.6) + edge_color * flash * 2.5;
	ALPHA = clamp(0.72 + edges * 0.2 + fres * 0.2, 0.0, 0.95);
}

// selection_ring.gdshader - the in-world selection ring of a unit (graphics week G-D, scripts/units/fx/unit_fx.gd).
// A flat ground quad (PlaneMesh, local XZ in metres, centred on the unit). ONE shared material per team colour / tier /
// "own" flag (UnitFx.ring_material), never one per unit; the unit's size is an instance uniform.
// Instance uniform slots (the ring is its own MeshInstance3D, so they never meet the model kit's slots):
//   0 ring_radius  the unit's `radius` (m); the band runs from radius + 0.20 to radius + 0.32 (the old torus).
//   1 ring_alpha   overall alpha (1 = the selection ring; the G-E team ring sets Unit.TEAM_RING_ALPHA).
// ring_style 1 = the G-E always-on team ring (UnitFx.team_ring_material): a thin faint band (radius + 0.12 .. + 0.19)
// with soft edges, plus at High+ a very light inner wash; no dashes, no breathing.
// Big radii (buildings, 4-7 m): the pull and the inner glow width are capped in metres (units up to radius 1.5 unchanged).
// Tiers: gfx_tier 0-1 = a plain anti-aliased band (the old ring's cost); 2+ = soft inner glow, outer fade, a thin
// brighter rim and, on the player's own units (dash_count > 0), 4 slow dashes turning outside the band.
// Sits on the ground: depth tested, pulled toward the camera in view space (decal-like) so slopes never cut it.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

uniform vec4 ring_color : source_color = vec4(0.3, 1.0, 0.4, 1.0);
uniform int gfx_tier = 0;
uniform float dash_count = 0.0;
uniform float dash_speed = 0.35;
uniform int ring_style = 0;


instance uniform float ring_radius : instance_index(0) = 0.5;
instance uniform float ring_alpha : instance_index(1) = 1.0;

varying vec2 v_xz;

void vertex() {
	v_xz = VERTEX.xz;
	// Pull the quad toward the camera (same pixels on screen, nearer depth): a slope up to ~25 deg under a big unit
	// stays visible, the unit's body still hides the far half of the ring.
	vec4 vp = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float dist = max(length(vp.xyz), 0.001);
	float pull = min(0.25 + min(ring_radius, 1.5) * 0.4, dist * 0.5);   // capped: big building rings stay on the ground
	vp.xyz *= (dist - pull) / dist;
	POSITION = PROJECTION_MATRIX * vp;
}

void fragment() {
	float d = length(v_xz);
	float aa = max(fwidth(d), 0.002);
	if (ring_style == 1) {
		float t0 = ring_radius + 0.12;
		float t1 = ring_radius + 0.19;
		float s = max(aa, 0.025);
		float tb = smoothstep(t0 - s, t0 + s, d) * (1.0 - smoothstep(t1 - s, t1 + s, d));
		float ta = tb;
		if (gfx_tier >= 2) {
			float wash = smoothstep(max(ring_radius * 0.3, t0 - 0.8), t0, d) * (1.0 - smoothstep(t0 - s, t0 + s, d));
			ta = max(tb, wash * wash * 0.22);
		}
		ALBEDO = ring_color.rgb;
		ALPHA = ta * ring_alpha;
	} else {
		float r0 = ring_radius + 0.2;
		float r1 = ring_radius + 0.32;
		float band = smoothstep(r0 - aa, r0 + aa, d) * (1.0 - smoothstep(r1 - aa, r1 + aa, d));
		vec3 col = ring_color.rgb;
		float a = band * 0.95;
		if (gfx_tier >= 2) {
			// Thin brighter rim on the outer edge of the band.
			float rim = smoothstep(r1 - 0.07, r1 - 0.03, d) * (1.0 - smoothstep(r1 - aa, r1 + aa, d));
			// Soft inner glow under the unit, breathing gently; a short fade just outside the band.
			float breathe = 0.85 + 0.15 * sin(TIME * 2.1);
			float inner = smoothstep(max(ring_radius * 0.55, r0 - 0.9), r0, d) * (1.0 - smoothstep(r0 - aa, r0 + aa, d));
			float outer = (1.0 - smoothstep(r1, r1 + 0.12, d)) * smoothstep(r1 - aa, r1 + aa, d);
			float glow = (inner * inner * 0.32 + outer * 0.22) * breathe;
			// Own selection: dashes on a thin outer track, turning slowly.
			float dash = 0.0;
			if (dash_count > 0.0) {
				float ang = atan(v_xz.y, v_xz.x) / 6.2831853 + 0.5;
				float seg = fract(ang * dash_count + TIME * dash_speed);
				float on = smoothstep(0.0, 0.04, seg) * (1.0 - smoothstep(0.38, 0.42, seg));
				float track = smoothstep(r1 + 0.05 - aa, r1 + 0.05 + aa, d) * (1.0 - smoothstep(r1 + 0.09 - aa, r1 + 0.09 + aa, d));
				dash = on * track;
			}
			col = mix(col, vec3(1.0), rim * 0.55 + dash * 0.25);
			col *= 1.0 + band * 0.15;
			a = clamp(band * 0.92 + rim * 0.08 + glow + dash * 0.8, 0.0, 1.0);
		}
		ALBEDO = col;
		ALPHA = a * ring_alpha;
	}
}

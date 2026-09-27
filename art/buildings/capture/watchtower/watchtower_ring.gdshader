// watchtower_ring.gdshader - the capture progress ring round the watchtower's foot (task 12.V17), shared
// (watchtower_ring_mat.tres). Mesh: WatchtowerMesh.ring(): an annulus, UV.x = signed angle from the front / PI (-1..1),
// UV.y = 0 inner -> 1 outer. The ring fills symmetrically from the front (camera side) round to the back, so the part the
// tower hides fills last; 24 segments, a bright leading edge. burst (0..1) = the captured pulse: the whole ring flares
// and fades while the node grows. Per tower (instance uniforms): ring_color, ratio, fade (show / hide), burst.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float segments = 24.0;
uniform float energy = 1.9;
uniform vec3 track_color : source_color = vec3(0.05, 0.045, 0.04);

instance uniform vec3 ring_color : source_color = vec3(1.0, 0.55, 0.15);
instance uniform float ratio = 0.0;
instance uniform float fade = 1.0;
instance uniform float burst = 0.0;

void fragment() {
	float a = abs(UV.x);
	float r = UV.y;
	float edge = smoothstep(0.0, 0.2, r) * (1.0 - smoothstep(0.8, 1.0, r));
	float segf = fract((UV.x * 0.5 + 0.5) * segments);
	float px = fwidth(UV.x) * segments * 0.5;
	float gap = smoothstep(0.0, 0.06 + px, segf) * (1.0 - smoothstep(0.94 - px, 1.0, segf));
	float filled = 1.0 - smoothstep(ratio - 0.004, ratio + 0.004, a);
	vec3 col = mix(track_color, ring_color * energy, filled);
	float alpha = edge * mix(0.4, 0.95, filled) * mix(1.0, gap, 0.85);
	float lead = (1.0 - smoothstep(0.0, 0.035, abs(a - ratio))) * step(0.002, ratio) * step(ratio, 0.998);
	col += mix(ring_color, vec3(1.0, 0.95, 0.85), 0.5) * lead * 1.6;
	alpha = max(alpha, lead * edge);
	// Captured pulse: a solid bright ring fading out.
	col = mix(col, ring_color * energy * 1.5 + vec3(0.25), burst);
	alpha = mix(alpha, edge * burst, step(0.001, burst));
	ALBEDO = col;
	ALPHA = clamp(alpha * fade, 0.0, 1.0);
}

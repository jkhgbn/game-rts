shader_type spatial;
// Thornburst thorn cones (MultiMesh of CylinderMesh cones, height 1, local y -0.5..0.5).
// Dark bark at the base, green shaft, glowing lime tip. `fade` 1 -> 0 crumbles the thorn from the tip down
// with a glowing edge (instance uniform: one value for the whole MultiMeshInstance3D).
render_mode cull_back, shadows_disabled;

uniform vec3 bark_color : source_color = vec3(0.20, 0.13, 0.07);
uniform vec3 thorn_color : source_color = vec3(0.30, 0.50, 0.13);
uniform vec3 glow_color : source_color = vec3(0.75, 1.00, 0.40);
uniform float glow_energy = 3.0;
instance uniform float fade = 1.0;

varying float h;
varying vec3 lp;

void vertex() {
	h = VERTEX.y + 0.5;
	lp = VERTEX;
}

float hash3(vec3 p) {
	return fract(sin(dot(floor(p), vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void fragment() {
	float n = hash3(lp * vec3(22.0, 9.0, 22.0));
	float cut = fade * 1.25 - 0.1;            // fade 1 -> nothing cut; 0 -> all gone
	float d = cut - (h * 0.8 + n * 0.2);
	if (d < 0.0) {
		discard;
	}
	float streak = 0.5 + 0.5 * sin(atan(lp.x, lp.z) * 5.0 + h * 6.0);
	vec3 col = mix(bark_color, thorn_color, smoothstep(0.08, 0.55, h));
	col *= 0.8 + 0.3 * streak;
	ALBEDO = col;
	ROUGHNESS = 0.7;
	SPECULAR = 0.3;
	float tip = smoothstep(0.62, 1.0, h);
	float edge = (1.0 - smoothstep(0.0, 0.06, d)) * step(fade, 0.995);
	EMISSION = glow_color * glow_energy * (tip * tip + edge * 1.5);
	RIM = 0.4;
	RIM_TINT = 0.6;
}

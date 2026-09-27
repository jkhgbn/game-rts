shader_type spatial;
// Heal beam (Bloomtender autocast) on a CylinderMesh of height 1 stretched between caster and target:
// a bright core with two vines twisting around it and leaf pulses flowing toward the target (UV.y 0 -> 1).
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 color : source_color = vec3(0.75, 1.00, 0.40);
uniform float energy = 2.6;
instance uniform float fade = 1.0;

void fragment() {
	float v = 1.0 - UV.y;   // CylinderMesh UV.y is 0 at the top (+Y = the target end): v 0 = caster, 1 = target
	float ends = smoothstep(0.0, 0.06, v) * smoothstep(1.0, 0.9, v);
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float core = pow(facing, 2.0);
	float vine1 = pow(0.5 + 0.5 * sin((UV.x * 2.0 + v * 5.0 - TIME * 3.0) * 6.2831853), 10.0);
	float vine2 = pow(0.5 + 0.5 * sin((UV.x * 2.0 - v * 5.0 - TIME * 3.0) * 6.2831853 + 3.14), 10.0);
	float flow = pow(0.5 + 0.5 * sin((v * 4.0 - TIME * 5.0) * 6.2831853), 4.0);
	float b = core * (0.55 + 0.6 * flow) + (vine1 + vine2) * 0.8;
	ALBEDO = mix(color, vec3(1.0, 1.0, 0.85), core * flow * 0.4) * energy;
	ALPHA = clamp(b, 0.0, 1.0) * ends * fade;
}

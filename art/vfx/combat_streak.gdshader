shader_type spatial;
// Velocity-aligned glowing streak (CombatVfx, task A.12). A 1 x 1 QuadMesh drawn as a billboard that turns
// only around its own Y axis: Y = the direction of motion, X = faces the camera.
//  - GPU particles: ParticleProcessMaterial.particle_flag_align_y = true puts the velocity in the particle's Y;
//    the particle scale is the streak WIDTH and `stretch` x scale its length (sparks, embers).
//  - MultiMesh (projectile trails): the instance basis Y = head - tail (length included), X = width.
// Colour = particle / instance COLOR (HDR allowed, alpha fades it). Head (+Y) bright, tail fades.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform, fog_disabled;

uniform float stretch = 1.0;       // length / width for particles (trails pass 1.0: their length is in the basis)
uniform float core_width = 0.25;   // 0-1: hard hot core across the width
uniform float tail_power = 1.4;    // higher = shorter bright part

varying vec2 v_uv;

void vertex() {
	vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 axis = (MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz * stretch;
	float width = length((MODELVIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
	vec3 to_cam = normalize(-center);
	vec3 side = cross(axis, to_cam);
	float sl = length(side);
	side = sl > 0.00001 ? side / sl : vec3(1.0, 0.0, 0.0);
	// Seen end-on the streak keeps at least its width as a length, so it never vanishes.
	float al = length(axis);
	vec3 along = al > 0.00001 ? axis / al : vec3(0.0, 1.0, 0.0);
	float len = max(al, width);
	VERTEX = center + along * VERTEX.y * len + side * VERTEX.x * width;
	NORMAL = to_cam;
	v_uv = UV;
}

void fragment() {
	float x = abs(v_uv.x - 0.5) * 2.0;           // 0 centre line, 1 edge
	float y = clamp(v_uv.y, 0.0, 1.0);           // 0 head (+Y), 1 tail
	float across = 1.0 - smoothstep(core_width, 1.0, x);
	across *= across;
	float head_cap = smoothstep(0.0, 0.1, y);     // soft rounded head
	float along = pow(1.0 - y, tail_power) * head_cap;
	float hot = (1.0 - smoothstep(0.0, core_width, x)) * 0.6;   // white-hot core
	ALBEDO = COLOR.rgb * (1.0 + hot);
	ALPHA = clamp(COLOR.a * across * along, 0.0, 1.0);
}

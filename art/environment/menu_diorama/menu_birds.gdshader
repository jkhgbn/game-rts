// menu_birds.gdshader - a few dark birds wheeling in the dusk sky over the menu diorama (G-D menu).
// One MultiMesh, one draw call, no CPU work: every bird flies its own circle in the vertex shader.
// Mesh: a flat "M" glider (body on the local Z axis, wings along X, see MenuDiorama._bird_mesh).
// Per instance (INSTANCE_CUSTOM): x = circle radius (m), y = angular speed (rad/s, sign = direction),
// z = phase (rad), w = height wobble (m). The instance transform puts the circle centre in the world.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque;

uniform vec3 color : source_color = vec3(0.10, 0.07, 0.10);
uniform float flap_speed = 5.5;
uniform float flap_amount = 0.55;
// Seconds, driven by the diorama (stops while it is paused).
uniform float anim_time = 0.0;

void vertex() {
	float t = anim_time;
	float r = INSTANCE_CUSTOM.x;
	float w = INSTANCE_CUSTOM.y;
	float ph = INSTANCE_CUSTOM.z;
	float a = t * w + ph;
	// Wing beat: the outer wing (|x| large) goes up and down; glides now and then (a slow on / off envelope).
	float glide = smoothstep(-0.2, 0.6, sin(t * 0.37 + ph * 2.1));
	float beat = sin(t * flap_speed + ph * 3.0) * flap_amount * (1.0 - glide * 0.85);
	vec3 v = VERTEX;
	v.y += abs(v.x) * beat;
	// Bank into the turn, then face the flight direction (the tangent of the circle).
	float bank = 0.35 * sign(w);
	float cb = cos(bank);
	float sb = sin(bank);
	v = vec3(v.x * cb - v.y * sb, v.x * sb + v.y * cb, v.z);
	vec3 pos = vec3(cos(a) * r, sin(t * 0.6 + ph) * INSTANCE_CUSTOM.w, sin(a) * r);
	vec3 fwd = normalize(vec3(-sin(a), 0.0, cos(a)) * sign(w));
	vec3 side = normalize(cross(vec3(0.0, 1.0, 0.0), fwd));
	VERTEX = pos + side * v.x + vec3(0.0, 1.0, 0.0) * v.y + fwd * v.z;
}

void fragment() {
	ALBEDO = color;
}

// ground.gdshader - painted ground for Crown Hollow (and any map). Everything is computed from WORLD x/z, so it
// works on a PlaneMesh of any size. Layers (A.10):
//   grass    posterised warm / cool / dry colour blocks, directional brush strokes, painted grass tufts (tiny
//            clumps with a lit top and a cast shadow), flower patches (white / yellow / lilac / pink dots),
//            darker clover patches;
//   lane     a meandering dirt road from lane_a to lane_b with wheel ruts, a grassy crown and pebbles;
//   spots    (x, z, radius, kind): kind 0 = trodden dirt, kind 1 = a ruined round plaza (rings of flagstones,
//            a carved centre disc with faint ember grooves, stones missing toward the rim);
//   border   outside the map square (|x| or |z| > map_half): scree at the cliff foot, then a painted rock rim and
//            a dark forest canopy fading into haze, so the map never ends in a hard cut. With `expand_edge` the
//            map's 120 m PlaneMesh is stretched to +-expand_to in the vertex shader (only its outer vertices move;
//            colliders are untouched), so the border exists even without art/environment/map_dressing.tscn.
//   roads    (task 10.V10) up to 16 straight segments road_segs[i] = vec4(x0, z0, x1, z1) (world x/z), the first
//            road_count used: worn trade roads road_width metres wide (default 3) with soft noisy edges, two wheel
//            ruts, a grassy crown between them, pebbles and stretches of old half-buried cobbles (road_cobble).
//            Segments sharing an end point join smoothly (the gentle meander is 0 at every segment end).
//            road_count = 0 (default) skips the whole layer: the map looks exactly as before.
// Tweak lane, spots and roads per map through the material parameters (EnvProps.ground_material does it).
// MAP.P1 polish (readability first: units must pop off the ground): a calmer, slightly less saturated grass whose
// light / dark patches have less contrast at unit scale (patch_contrast), a greyer umber dirt so red / orange
// units read on the base clearings, crisp painted dirt / road edges with a grass-lip shadow and a lit blade lip
// (edge_soft, edge_lip) instead of the old 1 m blur, a soft cool occlusion at the foot of the map-edge cliffs
// (cliff_ao, taller cliffs reach further) and a slightly darker, cooler outer ring (outer_cool) that frames the
// play space. Pure ALU, no extra texture reads.
// 12.V2 (map-fill.md 2.1 / 3.1 / 10) river cut, banks and biome tints, all OFF by default (missions and the menu
// diorama look exactly as before):
//   river    the ground is cut open (discard) where the analytic distance to the river segments (river_segs /
//            river_count, counted only outside the moat's centre line so their round ends never bite into the
//            Crown Isle) or to the moat ring is below its half width, except inside the ford / Crown Steps circles
//            (fords); the cut is exactly at the half width (12.V1's trench walls start there). A wet bank band
//            (bank_width, noisy painted edge) runs along every edge: dark wet earth and pebbles at the lip, damp
//            earth, then sand with grass islands; roads and the lane stay dirt, only darker near the water.
//   biomes   biome_amount > 0: zones built analytically from mirrored features (no mask texture: the one-sampler
//            budget stays), first match wins, noisy borders blended over biome_blend metres: Crown Isle ruins /
//            landmarks (biome_ruins circles: dry ember-scorched grass), riverbank (within biome_bank_reach of the
//            water: lush cool grass), Hearth Meadow (biome_hubs: bright lawn, clover, more flowers), Old Wood
//            (biome_woods: dark needle litter, moss, few tufts), Heath (|x| or |z| > biome_heath_edge: warm dry
//            grass with purple heather and yellow gorse blotches), Wildflower Glade = today's lawn. biome_tints =
//            the biome sets' GROUND_TINT (meadow, heath, old wood, riverbank), applied in a square-root space so
//            the painted patches keep their contrast.
// Uniform values for Crown Hollow: art/environment/ground_params.gd (skirmish_river(), skirmish_biomes(), apply()).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
// Grass palette.
uniform vec3 grass_dark : source_color = vec3(0.21, 0.315, 0.165);
uniform vec3 grass_light : source_color = vec3(0.32, 0.43, 0.20);
uniform vec3 grass_warm : source_color = vec3(0.45, 0.46, 0.22);
uniform vec3 grass_cool : source_color = vec3(0.14, 0.28, 0.21);
uniform vec3 grass_dry : source_color = vec3(0.50, 0.46, 0.30);
uniform float patch_contrast = 0.58;   // value contrast of the big light / dark grass patches (1 = the A.10 look)
uniform vec3 clover_color : source_color = vec3(0.12, 0.28, 0.13);
uniform vec3 flower_a : source_color = vec3(0.96, 0.94, 0.86);
uniform vec3 flower_b : source_color = vec3(1.00, 0.84, 0.26);
uniform vec3 flower_c : source_color = vec3(0.72, 0.56, 0.92);
uniform vec3 flower_d : source_color = vec3(0.95, 0.58, 0.66);
uniform float tuft_density = 0.55;
uniform float flower_amount = 1.0;
// Dirt and stone.
uniform vec3 dirt_color : source_color = vec3(0.48, 0.405, 0.30);
uniform vec3 dirt_dark : source_color = vec3(0.31, 0.255, 0.19);
uniform float edge_soft = 0.08;      // half width (m) of the painted dirt / road / plaza edge (A.10: ~0.5-0.8)
uniform float edge_lip = 1.0;         // grass-lip shadow just inside dirt edges + lit blades just outside (0 = off)
uniform vec3 pebble_color : source_color = vec3(0.47, 0.44, 0.40);
uniform vec3 paving_color : source_color = vec3(0.56, 0.54, 0.50);
uniform vec3 groove_glow : source_color = vec3(1.0, 0.45, 0.12);
uniform float groove_energy = 0.9;
// Lane (dirt road) from lane_a to lane_b, world x/z.
uniform vec2 lane_a = vec2(-36.0, 36.0);
uniform vec2 lane_b = vec2(36.0, -36.0);
uniform float lane_half_width = 2.6;
uniform float lane_meander = 1.5;
// Spots: (x, z, radius, kind) with kind 0 = trodden dirt, 1 = ruined plaza. radius 0 = off.
uniform vec4 spot_0 = vec4(-36.0, 36.0, 11.0, 0.0);
uniform vec4 spot_1 = vec4(36.0, -36.0, 11.0, 0.0);
uniform vec4 spot_2 = vec4(0.0, 0.0, 9.5, 1.0);
uniform vec4 spot_3 = vec4(0.0, 0.0, 0.0, 0.0);
uniform float edge_noise = 2.4;
uniform float paving_cell = 1.25;
// Trade roads (10.V10): segments vec4(x0, z0, x1, z1) in world x/z; only the first road_count are drawn.
uniform vec4 road_segs[16];
uniform int road_count = 0;
uniform float road_width = 3.0;       // full width in metres (soft edge +-0.35 m around it)
uniform float road_meander = 0.45;    // metres of gentle sideways wander (0 at segment ends)
uniform float road_cobble = 0.25;     // 0 = pure dirt, 1 = mostly old cobbles
uniform vec3 road_color : source_color = vec3(0.56, 0.47, 0.35);
uniform vec3 road_dark : source_color = vec3(0.36, 0.295, 0.215);
uniform vec3 cobble_color : source_color = vec3(0.55, 0.52, 0.47);
// Border outside the map square.
uniform float map_half = 60.0;
// Per-axis half size (x, z) of a non-120 m map (MapInfo halves; main.gd _build_ground sets it). (0, 0), the default,
// means "square, use map_half" so the old materials (menu diorama, plateau) keep their look.
uniform vec2 map_half_xz = vec2(0.0);
uniform bool expand_edge = true;
uniform float expand_to = 260.0;
uniform float border_mode = 1.0;      // 1 = scree + rock rim + canopy outside map_half, 0 = plain grass everywhere
uniform float forest_floor = 0.0;     // 1 = plateau material of map_dressing (dark forest floor, canopy further out)
uniform float canopy_start = 5.5;     // metres outside map_half where the painted canopy starts
uniform vec3 canopy_dark : source_color = vec3(0.06, 0.15, 0.10);
uniform vec3 canopy_light : source_color = vec3(0.20, 0.36, 0.17);
uniform vec3 rock_color : source_color = vec3(0.36, 0.34, 0.33);
uniform vec3 haze_color : source_color = vec3(0.42, 0.50, 0.52);
// Map-edge framing (MAP.P1), inside the map square only.
uniform float cliff_ao = 0.38;       // cool darkening at the cliff foot (0 = off); scaled by each side's cliff height
uniform float cliff_ao_width = 6.0;   // metres it reaches into the map below the tallest (north, 10 m) cliff
uniform float outer_cool = 1.0;       // outer ring (last ~20 m) a little darker / cooler (0 = off)
// Direction TO the sun on the ground plane (preset_warm sun: yaw 40, pitch -52), for painted highlights and
// tuft / flower / pebble shadows.
uniform vec2 sun_dir = vec2(0.64, 0.77);
// River cut + wet banks (12.V2). river_count 0 and moat radius 0 (the defaults) skip the whole layer.
uniform vec4 river_segs[16];           // river centre-line segments vec4(ax, az, bx, bz), world x/z
uniform int river_count = 0;           // how many river_segs are used (0 = no river)
uniform float river_half_width = 2.5;  // metres either side of the centre line (map-fill: 5 m of water)
uniform vec4 moat = vec4(0.0);         // ring: (centre x, centre z, centre-line radius, half width); radius 0 = none
uniform vec4 fords[4];                 // circles (x, z, r, 0) left uncut (fords, Crown Steps); r 0 = unused slot
// Perf only: (min x, min z, max x, max z) of the river segments grown by every reach the look needs (ground_params.gd
// river() fills it); outside it the segment loop is skipped. All 0 (the default) = always run the loop.
uniform vec4 river_box = vec4(0.0);
uniform float bank_width = 2.5;        // wet bank band from the water edge (noisy, +-1 m)
uniform vec3 bank_wet : source_color = vec3(0.17, 0.14, 0.11);
uniform vec3 bank_damp : source_color = vec3(0.33, 0.28, 0.20);
uniform vec3 bank_sand : source_color = vec3(0.55, 0.50, 0.37);
// Biome tints (12.V2). biome_amount 0 (the default) = today's lawn everywhere.
uniform float biome_amount = 0.0;
// Meadow, heath, old wood, riverbank (sRGB, e.g. a PackedColorArray of the sets' GROUND_TINT). Godot has no
// defaults for uniform arrays: a slot left black uses the built-in tint (tint_factor(), vertex()).
uniform vec3 biome_tints[4] : source_color;
uniform float biome_tint_strength = 0.62;
uniform vec4 biome_hubs = vec4(-36.0, 36.0, 36.0, -36.0);   // Hearth Meadow centres (a.x, a.z, b.x, b.z)
uniform float biome_hub_radius = 22.0;
uniform vec4 biome_woods = vec4(-50.0, -50.0, 50.0, 50.0);  // Old Wood centres (a.x, a.z, b.x, b.z)
uniform float biome_wood_radius = 28.0;
uniform float biome_heath_edge = 44.0;    // heath where |x| or |z| is beyond it (0 = no heath)
uniform float biome_bank_reach = 6.0;     // riverbank biome: land within this distance of the water
uniform vec4 biome_ruins[8];              // ruins circles (x, z, r, 0): the Crown Isle and 3 m around landmarks
uniform int biome_ruin_count = 0;
uniform float biome_blend = 4.0;          // metres of blend at every biome border
uniform vec3 heather_color : source_color = vec3(0.43, 0.32, 0.42);
uniform vec3 gorse_color : source_color = vec3(0.55, 0.51, 0.24);
uniform vec3 blossom_color : source_color = vec3(0.93, 0.80, 0.30);
uniform vec3 needle_color : source_color = vec3(0.25, 0.22, 0.14);
uniform vec3 moss_color : source_color = vec3(0.17, 0.28, 0.11);
uniform vec3 scorch_color : source_color = vec3(0.29, 0.25, 0.21);
// Perf (12.V2): the plane is left out of the sun's shadow pass (see vertex()). It shadows nothing (it is the lowest
// surface), but with the river discard every shadow cascade would run this fragment shader over the whole 520 m
// plane (+1.3 ms on a GTX 1660, even with the river off). false = the old behaviour.
uniform bool skip_sun_shadow = true;
// G2a (docs/art/g2a_ground.md). Both default to today's look.
// bake_mode: 0 = the game; 1 = unlit grass colour (EMISSION, no tufts / flowers / dirt) and 2 = unlit grass mask
// (R grass amount, G flower patches, B blade height x 0.5) for GroundDetail's top-down bake (the 3D grass field).
uniform int bake_mode = 0;
// Painted relief (High / Ultra): dirt sits a little below the grass, ruts and the river banks dip, plaza stones stand
// proud of their joints; the light ramp is then shaded by that relief (lit lips facing the sun, cool ones away).
// 0 = off (flat normal, the old light exactly). Fades out when a pixel is wider than ~0.12 m.
uniform float relief = 0.0;
// G-E fixes B (docs/art/ge_fixes_b.md): frozen maps, set by FrozenLook (art/environment/snow/frozen_look.gd).
// snow_mode 0 = off (every other map: one uniform test). 1 = wind-carved sastrugi and blue-grey drift shading on the
// ground, snow-laden firs on the painted border canopy, no grass in the G2a mask (no 3D blades on snow).
// snow_sparkle: glints that twinkle with time and the camera (FrozenLook: 0 at Low).
uniform float snow_mode = 0.0;
uniform float snow_sparkle = 0.0;
uniform vec2 snow_wind = vec2(0.82, 0.57);
uniform vec3 snow_shade : source_color = vec3(0.62, 0.70, 0.86);

varying vec3 v_wp;
// 12.V2 biome tint factors (per-draw constants, computed once per vertex instead of once per pixel).
varying flat vec3 v_tint0;
varying flat vec3 v_tint1;
varying flat vec3 v_tint2;
varying flat vec3 v_tint3;

// biome_tints[i] (already linear), or the built-in sRGB tint `srgb` when the slot was never set; returned as the
// square-root-space factor against the mean grass colour `ref` (sqrt space too).
vec3 tint_factor(vec3 t, vec3 srgb, vec3 ref) {
	vec3 lin = t;
	if (dot(t, t) <= 0.0) {
		lin = mix(srgb / 12.92, pow((srgb + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), srgb));
	}
	return sqrt(lin) / ref;
}

// The map's half extents (x, z): map_half_xz when set, else the square map_half.
vec2 halves() {
	return map_half_xz.x > 0.0 ? map_half_xz : vec2(map_half);
}

void vertex() {
	if (expand_edge) {
		// Only the outer vertices of the map plane (|v| == the map's half size on that axis) move out.
		vec2 hh = halves();
		if (abs(VERTEX.x) > hh.x - 0.05) {
			VERTEX.x = sign(VERTEX.x) * expand_to;
		}
		if (abs(VERTEX.z) > hh.y - 0.05) {
			VERTEX.z = sign(VERTEX.z) * expand_to;
		}
	}
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 ref = sqrt(max(mix(grass_dark, grass_light, 0.5), vec3(0.0001)));
	v_tint0 = tint_factor(biome_tints[0], vec3(0.40, 0.56, 0.20), ref);   // Hearth Meadow
	v_tint1 = tint_factor(biome_tints[1], vec3(0.50, 0.46, 0.26), ref);   // Heath
	v_tint2 = tint_factor(biome_tints[2], vec3(0.18, 0.22, 0.13), ref);   // Old Wood
	v_tint3 = tint_factor(biome_tints[3], vec3(0.17, 0.32, 0.18), ref);   // Riverbank
	// The sun's shadow pass = an orthographic projection looking from the sun (its view +Z points up toward the
	// painted sun direction; both lighting presets' suns are within 0.97 of sun_dir): collapse the plane to one
	// point there, so it is never rasterised. Perspective views (the game, the menu) and orthographic cameras from
	// any other side (preview strips) are untouched.
	if (skip_sun_shadow && PROJECTION_MATRIX[3][3] > 0.5) {
		vec3 back = INV_VIEW_MATRIX[2].xyz;
		float h = length(back.xz);   // sun 30-70 degrees high: 0.34-0.87 (a straight-down map view: 0, kept)
		if (back.y > 0.2 && h > 0.3 && dot(back.xz / h, normalize(sun_dir)) > 0.8) {
			VERTEX = vec3(0.0);
		}
	}
}

float nz(vec2 p) {
	return texture(noise_tex, p).r;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

// Rounds x to n steps with an anti-aliased step (crisp painted colour blocks).
float poster(float x, float n) {
	float f = x * n;
	float i = floor(f);
	float fr = f - i;
	float w = clamp(fwidth(f), 0.001, 0.5);
	return (i + smoothstep(0.5 - w, 0.5 + w, fr)) / n;
}

// poster() with the screen width of x given: fw = fwidth(x), taken in fragment() before any per-pixel branch (shader
// lint B: derivatives inside a branch whose condition changes within a 2x2 pixel quad are undefined). Same result,
// since fwidth(x * n) = n * fwidth(x).
float poster_w(float x, float n, float fw) {
	float f = x * n;
	float i = floor(f);
	float fr = f - i;
	float w = clamp(fw * n, 0.001, 0.5);
	return (i + smoothstep(0.5 - w, 0.5 + w, fr)) / n;
}

// Anti-aliased "inside a disc of radius r at distance d" (1 inside).
float disc(float d, float r, float aa) {
	return 1.0 - smoothstep(r - aa, r + aa, d);
}

// One scatter layer of small round things (tufts, flowers, pebbles) on a jittered grid.
// Returns x = body mask, y = cast-shadow mask, z = lit-side mask, w = random id.
vec4 scatter(vec2 p, float cell, float prob, float rmin, float rmax, float aa, vec2 shadow_off) {
	vec2 g = p / cell;
	vec2 id = floor(g);
	vec2 h = hash2(id);
	if (h.x > prob) {
		return vec4(0.0, 0.0, 0.0, h.y);
	}
	vec2 o = (hash2(id + 7.31) - 0.5) * 0.3;
	vec2 q = (fract(g) - 0.5 - o) * cell;
	float r = mix(rmin, rmax, h.y);
	float body = disc(length(q * vec2(1.0, 1.15)), r, aa);
	float shadow = disc(length((q - shadow_off) * vec2(1.0, 1.15)), r * 1.05, aa) * (1.0 - body);
	float lit = body * smoothstep(-0.2, 0.6, dot(normalize(q + 0.0001), sun_dir)) * smoothstep(r * 0.2, r * 0.8, length(q));
	return vec4(body, shadow, lit, h.y);
}

// Distance-based mask of a thin tapered blade from the origin along `dir` (length l, base half width w).
// Returns x = mask, y = position along the blade (0 base .. 1 tip).
vec2 blade(vec2 q, vec2 dir, float l, float w, float aa) {
	float t = clamp(dot(q, dir) / l, 0.0, 1.0);
	float perp = length(q - dir * t * l);
	return vec2(disc(perp, w * (1.0 - t * 0.85), aa), t);
}

// Painted grass tufts: fans of 3 blades rising "up" the screen (world -z, as vertical blades seen from the RTS
// camera), with a soft shadow thrown away from the sun. x = body, y = shadow, z = tip light, w = id.
vec4 tufts(vec2 p, float cell, float prob, float lmin, float lmax, float aa, vec2 shadow_off) {
	vec2 g = p / cell;
	vec2 id = floor(g);
	vec2 h = hash2(id);
	if (h.x > prob) {
		return vec4(0.0, 0.0, 0.0, h.y);
	}
	vec2 o = (hash2(id + 7.31) - 0.5) * 0.35;
	vec2 q = (fract(g) - 0.5 - o) * cell;
	q.y -= cell * 0.18;   // base a little below the cell centre so the fan stays inside the cell
	float l = mix(lmin, lmax, h.y);
	float w = 0.028 + h.y * 0.012;
	float body = 0.0;
	float tip = 0.0;
	float shadow = 0.0;
	float spread = 0.45 + hash(id + 3.3) * 0.25;
	for (int k = -1; k <= 1; k++) {
		float a = float(k) * spread + (hash(id + float(k) * 1.7) - 0.5) * 0.35;
		vec2 dir = vec2(sin(a), -cos(a));
		float lk = l * (k == 0 ? 1.0 : 0.78);
		vec2 b = blade(q, dir, lk, w, aa);
		body = max(body, b.x);
		tip = max(tip, b.x * b.y);
		// A vertical blade's shadow lies on the ground away from the sun (sun ~50 degrees high: ~0.8 x its height).
		shadow = max(shadow, blade(q - shadow_off * 0.3, normalize(-sun_dir + vec2(dir.x, 0.0) * 0.6), lk * 0.8, w * 1.3, aa).x);
	}
	return vec4(body, shadow * (1.0 - body), tip, h.y);
}

float seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
	return length(pa - ba * h);
}

// Signed distance (m, noisy) to the edge of a spot: < 0 inside. Radius 0 = off (far outside).
float spot_edge(vec4 s, vec2 p, float edge) {
	if (s.z <= 0.0) {
		return 1e4;
	}
	return length(p - s.xy) + edge * 1.4 - (s.z - 0.4);
}

// Crisp painted mask from a signed edge distance: 1 inside, 0 outside, edge_soft wide (+ one pixel of AA).
float edge_mask(float e, float aa) {
	return 1.0 - smoothstep(-edge_soft - aa, edge_soft + aa, e);
}

vec3 grass_color(vec2 p, float px) {
	float big = nz(p * 0.010);
	float mid = nz(p * 0.040 + vec2(3.7, 1.9));
	float fine = nz(p * 0.20 + vec2(11.3, 4.2));
	float warmth = nz(p * 0.006 + vec2(0.41, 0.77));
	// Directional brush strokes (rotated ~30 degrees, stretched).
	vec2 sp = vec2(p.x * 0.866 + p.y * 0.5, p.y * 0.866 - p.x * 0.5);
	float stroke = nz(sp * vec2(0.22, 0.045) + vec2(7.1, 2.3));
	float stroke2 = nz(sp * vec2(0.55, 0.11) + vec2(1.3, 8.8));

	float g = smoothstep(0.26, 0.76, big * 0.55 + mid * 0.45);
	g = poster(g, 5.0) * 0.55 + g * 0.45;
	g = 0.5 + (g - 0.5) * patch_contrast;
	vec3 base = mix(grass_dark, grass_light, g);
	// Warm (yellow-green, sunny meadows) against cool (blue-green, damp hollows).
	float w = smoothstep(0.30, 0.72, warmth);
	w = poster(w, 3.0) * 0.6 + w * 0.4;
	// (MAP.P1: a little more hue than A.10 at this very large scale, where it adds mood without busy-ness.)
	base = mix(base, grass_cool, (1.0 - w) * 0.36);
	base = mix(base, grass_warm, w * smoothstep(0.40, 0.80, mid) * 0.34);
	// Dry patches (small, crisp edge).
	float dry = smoothstep(0.69, 0.73, mid * 0.7 + big * 0.3 + (fine - 0.5) * 0.14);
	base = mix(base, grass_dry, dry * 0.24);
	// Clover patches (dark, crisp edges).
	float clover = smoothstep(0.68, 0.71, nz(p * 0.075 + vec2(5.5, 9.1)) + (fine - 0.5) * 0.18);
	base = mix(base, clover_color, clover * 0.30);
	// Brush strokes.
	base *= 0.90 + poster(stroke, 4.0) * 0.18;
	base *= 0.95 + stroke2 * 0.10;
	return base;
}

// Painted grass tufts and flowers on top of the grass colour `col`.
vec3 grass_details(vec2 p, vec3 col, float px, float amount, float flower_mask) {
	float aa = px * 0.75;
	float fade_t = (1.0 - smoothstep(0.10, 0.22, px)) * amount;
	vec2 so = -sun_dir * 0.055;
	if (fade_t > 0.0) {
		vec4 t1 = tufts(p, 0.62, tuft_density * 0.65, 0.16, 0.28, aa, so);
		vec4 t2 = tufts(p + vec2(0.23, 0.41), 0.95, tuft_density * 0.5, 0.20, 0.34, aa, so * 1.2);
		float shadow = max(t1.y, t2.y);
		float body = max(t1.x, t2.x);
		float tip = max(t1.z, t2.z);
		col = mix(col, col * 0.72, shadow * 0.7 * fade_t);
		vec3 tuft = col * mix(0.82, 0.95, max(t1.w, t2.w));
		tuft = mix(tuft, col * 1.32 + vec3(0.035, 0.035, 0.0), smoothstep(0.25, 0.9, tip));
		col = mix(col, tuft, body * fade_t);
	}
	float fade_f = (1.0 - smoothstep(0.08, 0.16, px)) * flower_mask * flower_amount;
	if (fade_f > 0.0) {
		vec4 f = scatter(p + vec2(0.11, 0.07), 0.42, 0.27, 0.035, 0.06, aa, so * 0.5);
		float pick = hash(floor(p / 5.0) + floor(f.w * 3.0) * 13.0);
		vec3 fc = pick < 0.35 ? flower_a : (pick < 0.60 ? flower_b : (pick < 0.82 ? flower_c : flower_d));
		col = mix(col, col * 0.7, f.y * 0.6 * fade_f);
		col = mix(col, fc * mix(0.85, 1.05, f.z), f.x * fade_f);
	}
	return col;
}

// Pebbles on dirt.
vec3 pebbles(vec2 p, vec3 col, float px, float amount) {
	float fade = (1.0 - smoothstep(0.05, 0.12, px)) * amount;
	if (fade <= 0.0) {
		return col;
	}
	vec4 s = scatter(p + vec2(0.3, 0.9), 0.36, 0.20, 0.025, 0.06, px * 0.75, -sun_dir * 0.025);
	col = mix(col, col * 0.65, s.y * 0.7 * fade);
	vec3 pc = pebble_color * mix(0.75, 1.1, s.w) * mix(0.85, 1.15, s.z);
	return mix(col, pc, s.x * fade);
}

// Ruined round plaza around `c` (radius R), fades with `m`. Returns the paved colour mixed over `under`.
vec3 plaza(vec2 p, vec2 c, float R, float m, vec3 under, float px, float mid, float fine, inout vec3 emit,
		inout float hgt) {
	vec2 v = p - c;
	float r = length(v);
	float ang = atan(v.y, v.x);
	float aa = px * 0.8;
	float ring_w = 1.05;
	float ri = floor(r / ring_w);
	float fr = fract(r / ring_w);
	float n = max(6.0, floor(6.2832 * (ri + 0.5) * ring_w / 1.3));
	float a = (ang / 6.2832 + 0.5) * n + hash(vec2(ri, 3.0)) * 7.0;
	float seg = mod(floor(a), n);
	float fa = fract(a);
	float b_rad = min(fr, 1.0 - fr) * ring_w;
	float b_tan = min(fa, 1.0 - fa) * 6.2832 * max(r, 0.5) / n;
	float border = min(b_rad, b_tan);
	if (r < ring_w * 3.0) {
		border = abs(r - ring_w * 3.0) + 0.2;   // one big carved centre disc
		seg = 0.0;
		ri = 0.0;
	}
	vec2 cell = vec2(ri, seg);
	float h = hash(cell + 3.1);
	float h2 = hash(cell + 17.0);
	float gap = smoothstep(0.035 - aa * 0.5, 0.075 + aa * 0.5, border);
	// Stones go missing toward the rim and in noisy patches; the rim ring (kerb) stays more complete.
	float edge_t = smoothstep(R * 0.45, R, r);
	float kerb = step(R - ring_w * 1.6, r) * step(r, R - ring_w * 0.6);
	float present = step(0.12 + edge_t * 0.55 - kerb * 0.35, h + (mid - 0.5) * 0.7 + (fine - 0.5) * 0.25);
	present = max(present, step(r, ring_w * 3.0));
	present *= step(r, R - 0.2 + (fine - 0.5) * 1.5);
	vec3 stone = paving_color * (0.74 + h * 0.28) * mix(vec3(1.0), vec3(1.05, 1.0, 0.92), h2);
	stone = mix(stone, stone * 0.82, kerb);
	// Bevel: dark lip at the joint, light band just inside.
	stone *= 1.0 - (1.0 - smoothstep(0.05, 0.11, border)) * 0.22;
	stone *= 1.0 + smoothstep(0.08, 0.12, border) * (1.0 - smoothstep(0.14, 0.2, border)) * 0.10;
	// Cracks across some stones.
	float crack_line = abs(dot(v, vec2(cos(h * 6.28), sin(h * 6.28))) - (h2 - 0.5) * 4.0);
	stone *= 1.0 - step(0.6, h2) * step(ring_w * 3.0, r) * (1.0 - smoothstep(0.0, 0.03 + aa, crack_line)) * 0.35;
	// Moss creeping in.
	stone = mix(stone, clover_color * 1.6, smoothstep(0.62, 0.8, fine + h2 * 0.25) * 0.45);
	// Carved sigil on the centre disc: groove rings at 1.45 m and 2.62 m, 8 spokes between them and 24 ticks
	// outside, with a faint ember glow deep in the grooves.
	float groove = 0.0;
	groove = max(groove, disc(abs(r - 2.62), 0.05, aa));
	groove = max(groove, disc(abs(r - 1.45), 0.04, aa));
	float spoke_a = fract((ang / 6.2832) * 8.0 + 0.5) - 0.5;
	groove = max(groove, disc(abs(spoke_a) * 6.2832 / 8.0 * r, 0.045, aa) * step(1.45, r) * step(r, 2.62));
	float tick_a = fract((ang / 6.2832) * 24.0) - 0.5;
	groove = max(groove, disc(abs(tick_a) * 6.2832 / 24.0 * r, 0.035, aa) * step(2.62, r) * step(r, 2.95));
	groove *= step(r, 3.0);
	stone = mix(stone, stone * 0.35, groove);
	emit += groove_glow * groove * groove_energy * m * (0.7 + 0.3 * sin(TIME * 1.3 + r * 2.0));
	vec3 gap_col = mix(under * 0.7, under, smoothstep(0.45, 0.65, fine));
	vec3 pc = mix(gap_col, stone, gap * present);
	// Relief: stones stand ~proud of the joints (bevelled), grooves cut in.
	float sh = smoothstep(0.03, 0.12, border) * present * 0.28 - groove * 0.12;
	hgt = mix(hgt, hgt + 0.35 + sh, smoothstep(0.15, 0.6, m));
	return mix(under, pc, smoothstep(0.15, 0.6, m));
}

// Nearest trade road (10.V10) closer than `cutoff`: x = distance to its gently meandering centre line (cutoff when
// none is that close), y = signed sideways offset, z = distance along the segment from its start (unclamped),
// w = segment length; `sid` = segment index. Pure ALU, no texture reads: far from every road a segment costs one
// point-to-segment distance; the meander (two sines) is only evaluated for segments within cutoff + road_meander.
vec4 road_nearest(vec2 p, float cutoff, out float sid) {
	vec4 best = vec4(cutoff, 0.0, 0.0, 1.0);
	sid = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= road_count) {
			break;
		}
		vec4 s = road_segs[i];
		vec2 ba = s.zw - s.xy;
		float L2 = dot(ba, ba);
		if (L2 < 0.0001) {
			continue;
		}
		vec2 pa = p - s.xy;
		// Scaled by L2 (no division): q0 = (pa - ba * t01) * L2.
		vec2 q0 = pa * L2 - ba * clamp(dot(pa, ba), 0.0, L2);
		float reach = (best.x + road_meander) * L2;
		if (dot(q0, q0) > reach * reach) {
			continue;
		}
		float L = sqrt(L2);
		vec2 dir = ba / L;
		vec2 nrm = vec2(-dir.y, dir.x);
		float t = dot(pa, dir);
		float tc = clamp(t, 0.0, L);
		float taper = smoothstep(0.0, 9.0, tc) * smoothstep(0.0, 9.0, L - tc);
		float ph = float(i) * 1.93;
		float off = (sin(tc * 0.085 + ph) * 0.65 + sin(tc * 0.21 + ph * 2.3) * 0.35) * road_meander * taper;
		vec2 q = p - s.xy - dir * tc - nrm * off;
		float d = length(q);
		if (d < best.x) {
			best = vec4(d, dot(q, nrm), t, L);
			sid = float(i);
		}
	}
	return best;
}

// G-F r2 item 14 (docs/art/gf_r2_ground.md): grass that survives on a road / lane crown is worn: darker, greyer and
// half dirt, never the flat bright meadow green (it read as paint blobs on the dirt).
vec3 worn_grass(vec3 grass, vec3 dirt_c, float micro) {
	vec3 g = grass * vec3(0.80, 0.82, 0.70);
	float l = dot(g, vec3(0.299, 0.587, 0.114));
	g = mix(vec3(l), g, 0.68);
	return mix(g, dirt_c, 0.26 + 0.22 * micro);
}

// Painted trade road: trodden dust lighter in the middle, streaks along the way, two wheel ruts with a lit lip,
// a broken grassy crown, pebbles and stretches of old half-buried cobbles. `grass` = the plain grass colour here.
// The road's dust streaks along the segment (road space).
float road_streak(vec4 r, float sid, float micro) {
	float lat = r.y + (micro - 0.5) * 0.08;
	return nz(vec2(r.z * 0.09 + sid * 0.37, lat * 0.55 + 0.21));
}

// tone / streak: the two posterised values (road_tone(), road_streak()) and their fwidth, taken by fragment() before
// the per-pixel `road > 0` branch (shader lint B).
vec3 road_paint(vec2 p, vec4 r, float sid, vec3 grass, float px, float mid, float fine, float micro, vec2 tone,
		vec2 streak) {
	float aa = px * 0.8;
	float hw = road_width * 0.5;
	float lat = r.y + (micro - 0.5) * 0.08;
	float alat = abs(lat);
	float on = step(0.0, r.z) * step(r.z, r.w);
	// Dust: posterised light / dark blocks, lighter where the traffic runs, streaks along the road.
	vec3 c = mix(road_dark, road_color, 0.35 + 0.65 * (poster_w(tone.x, 3.0, tone.y)
			* 0.7 + smoothstep(0.25, 0.75, fine) * 0.3));
	c *= 0.92 + micro * 0.16;
	c *= 1.0 + 0.08 * (1.0 - smoothstep(0.2, hw, alat));
	c *= 0.93 + poster_w(streak.x, 3.0, streak.y) * 0.12;
	// Old cobbles in stretches along the road (road space: rows across, staggered stones along).
	float stretch_n = nz(vec2(r.z * 0.016 + sid * 0.713, 0.29 + sid * 0.17)) * 0.8 + fine * 0.2;
	float stretch = smoothstep(0.64 - road_cobble * 0.3, 0.72 - road_cobble * 0.3, stretch_n) * step(0.001, road_cobble);
	// No cobbles near the segment ends: joints (different segments, different stone grids) are always dirt.
	stretch *= smoothstep(1.5, 6.0, r.z) * smoothstep(1.5, 6.0, r.w - r.z);
	float detail = 1.0 - smoothstep(0.10, 0.22, px);
	if (stretch > 0.0) {
		vec2 cs = vec2(0.48, 0.40);
		float row = floor(lat / cs.y);
		float cu = r.z / cs.x + row * 0.5;
		vec2 id = vec2(floor(cu), row);
		float h = hash(id + sid * 13.1);
		vec2 f = (vec2(fract(cu), fract(lat / cs.y)) - 0.5) * cs;
		f += (hash2(id + 4.7) - 0.5) * 0.06;
		vec2 e = max(abs(f) - vec2(0.15, 0.12), vec2(0.0));
		float sd = length(e) - 0.055;
		float stone = 1.0 - smoothstep(-aa, aa + 0.02, sd);
		// Stones are lost toward the edges and where the stretch thins out.
		float present = step(h * 0.55 + 0.25, stretch + (fine - 0.5) * 0.35) * (1.0 - smoothstep(hw - 0.7, hw - 0.2, alat));
		vec3 sc = cobble_color * (0.76 + h * 0.3) * mix(vec3(1.0), vec3(1.06, 1.0, 0.9), hash(id + 2.3));
		sc *= 1.0 + smoothstep(0.02, -0.05, sd) * dot(normalize(f + 0.0001), sun_dir) * 0.12;   // lit side
		sc = mix(sc, clover_color * 1.5, smoothstep(0.7, 0.85, micro + h * 0.2) * 0.35);          // moss in cracks
		vec3 gap = c * 0.72;
		vec3 paved = mix(gap, sc, stone);
		// Far away the pattern fades to its average so it never shimmers.
		vec3 avg = mix(c * 0.8, cobble_color * 0.86, 0.55);
		c = mix(c, mix(avg, paved, detail), present * stretch);
	}
	// Wheel ruts (1.45 m track) with a lighter lip, only along the segment itself.
	float rd = abs(alat - 0.72);
	float rut = disc(rd, 0.16, aa + 0.04) * on;
	float lip = disc(abs(rd - 0.23), 0.05, aa + 0.02) * on * (1.0 - rut);
	c *= 1.0 - rut * 0.26;
	c *= 1.0 + lip * 0.10 * detail;
	// Grassy crown between the ruts, broken into tufts: worn grass with soft, ragged edges (G-F r2 item 14).
	float crown = disc(alat + (micro - 0.5) * 0.14, 0.23, aa + 0.15) * on
			* smoothstep(0.47, 0.72, fine + (micro - 0.5) * 0.6) * (1.0 - stretch * 0.7);
	c = mix(c, worn_grass(grass, c, micro), crown * 0.8);
	return pebbles(p + vec2(sid * 3.1, 0.0), c, px, 0.8);
}

// Painted canopy seen from above: overlapping round crowns with a lit sun side.
// canopy_crown: the crown over p as (shade value before posterising, inside 0 / 1, crown hash); `grad` = d value / d p
// (analytic, inside the winning crown; 0 where the value is clamped).
vec3 canopy_crown(vec2 p, out vec2 grad) {
	float cs = 3.4;
	vec2 g = p / cs;
	vec2 id = floor(g);
	float best = 9.0;
	float lit = 0.0;
	float hid = 0.0;
	float height = -1.0;
	vec2 wpos = p;
	float wr = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 cid = id + vec2(float(x), float(y));
			vec2 h = hash2(cid);
			vec2 cpos = (cid + 0.5 + (h - 0.5) * 0.7) * cs;
			float r = 1.7 + h.x * 1.3;
			float d = length(p - cpos) / r;
			// The crown whose surface is "highest" here wins (dome height minus distance), so crowns overlap.
			float top = (1.0 - d * d) * r + h.y * 0.6;
			if (d < 1.0 && top > height) {
				height = top;
				best = d;
				lit = dot((p - cpos) / r, sun_dir);
				hid = h.y;
				wpos = cpos;
				wr = r;
			}
		}
	}
	float raw = 0.5 + lit * 0.55 + (hid - 0.5) * 0.25 - best * best * 0.25;
	vec2 rel = p - wpos;
	float rl = length(rel);
	vec2 unit = rl > 1e-5 ? rel / rl : vec2(0.0);
	grad = (sun_dir * 0.55 - unit * (0.5 * best)) / wr * step(0.0, raw) * step(raw, 1.0) * step(0.0, height);
	return vec3(clamp(raw, 0.0, 1.0), step(0.0, height), hid);
}

// Colour of the crown k (canopy_crown) with its posterised shade vp and the stand noise `stand`.
vec3 canopy_paint(vec3 k, float vp, float stand) {
	vec3 c = mix(canopy_dark, canopy_light, vp);
	c = mix(c, c * vec3(1.18, 1.08, 0.72), step(0.86, k.z) * 0.55);   // a few yellowing crowns
	c = mix(c, c * vec3(0.8, 0.95, 1.12), step(k.z, 0.12) * 0.5);    // and a few blue-green firs
	c *= 0.8 + stand * 0.4;                                           // large light / dark stands
	if (snow_mode > 0.5) {
		// G-E fixes B: a dark evergreen frame. Needle crowns shaded by the sun side, a soft snow dusting on the lit
		// tops only (no crisp pale crescents: the old pale crowns read as fish scales round the snow map).
		float sn = smoothstep(0.55, 0.95, vp + (k.z - 0.5) * 0.3);
		c = mix(canopy_dark * (0.7 + vp * 0.9), canopy_light, sn * 0.4);
	}
	return mix(canopy_dark * 0.45, c, k.y);
}

// Uniform-branch callers only (takes derivatives).
vec3 canopy(vec2 p, float px) {
	vec2 grad;
	vec3 k = canopy_crown(p, grad);
	return canopy_paint(k, poster(k.x, 4.0), nz(p * 0.018 + vec2(4.4, 1.7)));
}

// Per-pixel-branch callers: no derivative here; dpx / dpy = dFdx / dFdy of p taken before the branch (shader lint B).
// The shade's width comes from the chain rule, the stand noise from textureGrad (same mip as the implicit read).
vec3 canopy_grad(vec2 p, vec2 dpx, vec2 dpy) {
	vec2 grad;
	vec3 k = canopy_crown(p, grad);
	float fw = abs(dot(grad, dpx)) + abs(dot(grad, dpy));
	float stand = textureGrad(noise_tex, p * 0.018 + vec2(4.4, 1.7), dpx * 0.018, dpy * 0.018).r;
	return canopy_paint(k, poster_w(k.x, 4.0, fw), stand);
}

// ------------------------------------------------------------------ 12.V2 river cut, banks, biomes

// Signed distance (m) from p to the edge of the deep water (< 0 in the water): the moat ring and the river
// segments, the river only outside the moat's centre line (its round ends at the mouths reach r 10.25 otherwise).
// The ford circles are not subtracted here (their banks get the wet band too): see ford_sd().
float water_sd(vec2 p) {
	float sd = 1e4;
	bool count_river = true;
	if (moat.z > 0.0) {
		float mr = length(p - moat.xy);
		sd = abs(mr - moat.z) - moat.w;
		count_river = mr > moat.z;
	}
	bool in_box = river_box.z <= river_box.x
			|| (p.x > river_box.x && p.y > river_box.y && p.x < river_box.z && p.y < river_box.w);
	if (count_river && river_count > 0 && in_box) {
		float best = 1e8;
		for (int i = 0; i < 16; i++) {
			if (i >= river_count) {
				break;
			}
			vec4 s = river_segs[i];
			vec2 pa = p - s.xy;
			vec2 ba = s.zw - s.xy;
			vec2 q = pa - ba * clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
			best = min(best, dot(q, q));
		}
		sd = min(sd, sqrt(best) - river_half_width);
	}
	return sd;
}

// Signed distance to the nearest ford / Crown Steps circle (< 0 inside, 1e4 when there is none).
float ford_sd(vec2 p) {
	float d = 1e4;
	for (int i = 0; i < 4; i++) {
		if (fords[i].z > 0.0) {
			d = min(d, length(p - fords[i].xy) - fords[i].z);
		}
	}
	return d;
}

// Soft "inside" weight of a disc border at signed distance e (blend over 2 * bl metres).
float zone_in(float e, float bl) {
	return 1.0 - smoothstep(-bl, bl, e);
}

// Biome weights at p (map-fill.md 3.1, first match wins, borders jittered by `jit` and blended over biome_blend):
// x Hearth Meadow, y Heath, z Old Wood, w Riverbank; `ruin` = Crown Isle ruins / landmarks. Glade = the rest.
vec4 biome_weights(vec2 p, float wsd, float jit, out float ruin) {
	float bl = max(biome_blend, 0.01) * 0.5;
	ruin = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= biome_ruin_count) {
			break;
		}
		vec4 r = biome_ruins[i];
		vec2 d = p - r.xy;
		float reach = r.z + bl + 2.3;   // + the border jitter (at most 2.15 m)
		if (r.z > 0.0 && dot(d, d) < reach * reach) {
			ruin = max(ruin, zone_in(length(d) - r.z + jit, bl));
		}
	}
	float bank = wsd < 1e3 ? zone_in(wsd - biome_bank_reach + jit, bl) : 0.0;
	float meadow = 0.0;
	if (biome_hub_radius > 0.0) {
		meadow = zone_in(min(length(p - biome_hubs.xy), length(p - biome_hubs.zw)) - biome_hub_radius + jit, bl);
	}
	float wood = 0.0;
	if (biome_wood_radius > 0.0) {
		wood = zone_in(min(length(p - biome_woods.xy), length(p - biome_woods.zw)) - biome_wood_radius + jit, bl);
	}
	float heath = biome_heath_edge > 0.0 ? 1.0 - zone_in(max(abs(p.x), abs(p.y)) - biome_heath_edge + jit, bl) : 0.0;
	float left = 1.0 - ruin;
	bank *= left;
	left -= bank;
	meadow *= left;
	left -= meadow;
	wood *= left;
	left -= wood;
	heath *= left;
	return vec4(meadow, heath, wood, bank);
}

// Biome look on the plain grass colour: the tint factor `f` (square-root space, from the vertex shader), then each
// biome's painted layer. Also returns how many grass tufts stay (tuft_amt), extra flower patches (flower_boost) and
// how much of today's flowers go (flower_cut). Perf: 3 extra noise reads at most (heath 1, Old Wood 2); the other
// layers reuse the fragment's mid / fine / micro noise.
vec3 biome_paint(vec2 p, vec3 grass, vec3 f, vec4 w, float ruin, float px, float mid, float fine, float micro,
		inout float tuft_amt, inout float flower_boost, inout float flower_cut) {
	// Tints in a square-root space (close to sRGB): the painted light / dark patches keep their contrast.
	// (sqrt(grass) * f)^2 = grass * f^2: no per-pixel square roots.
	grass *= f * f;
	float detail = 1.0 - smoothstep(0.10, 0.22, px);
	float nw = 0.012 + px * 0.06;   // half width of the painted blotch edges (wider when far: no shimmer)
	// Hearth Meadow: extra clover mats and more daisy / dandelion patches.
	if (w.x > 0.001) {
		float cl = smoothstep(0.66 - nw, 0.66 + nw, (1.0 - fine) * 0.8 + mid * 0.2 + (micro - 0.5) * 0.12);
		grass = mix(grass, clover_color * (1.15 + micro * 0.2), cl * 0.30 * w.x);
		flower_boost = max(flower_boost, w.x * smoothstep(0.55, 0.60, mid * 0.55 + fine * 0.45));
	}
	// Heath: crisp purple heather (high noise) and yellow gorse (low noise) blotches speckled with blossoms.
	if (w.y > 0.001) {
		float hn = nz(p * 0.085 + vec2(2.7, 6.3)) + (fine - 0.5) * 0.24;
		float heather = smoothstep(0.685 - nw, 0.685 + nw, hn);
		float gorse = smoothstep(0.30 + nw, 0.30 - nw, hn);
		vec4 dots = scatter(p + vec2(0.4, 0.8), 0.26, 0.5, 0.028, 0.05, px * 0.75, -sun_dir * 0.03);
		vec3 hc = heather_color * (0.80 + micro * 0.28);
		hc = mix(hc, hc * 0.72, dots.y * detail * 0.6);
		hc = mix(hc, heather_color * 1.45 + vec3(0.04, 0.02, 0.05), dots.x * detail);
		vec3 gc = gorse_color * (0.78 + micro * 0.28);
		gc = mix(gc, gc * 0.72, dots.y * detail * 0.6);
		gc = mix(gc, blossom_color, dots.x * detail);
		grass = mix(grass, hc, heather * w.y * 0.75);
		grass = mix(grass, gc, gorse * w.y * 0.70);
		tuft_amt -= (heather + gorse) * w.y * 0.6;
		flower_cut = max(flower_cut, w.y * 0.7);
	}
	// Old Wood: dark needle litter in two crossing stroke directions, moss cushions; few tufts, no flowers.
	// The needle strokes are read before the per-pixel w.z branch: poster() takes a derivative (shader lint B).
	vec2 q = vec2(p.x * 0.8 + p.y * 0.6, p.y * 0.8 - p.x * 0.6);
	float n1 = nz(q * vec2(1.3, 0.22) + vec2(3.3, 7.7));   // needle strokes (the only extra read here)
	float lit = poster(smoothstep(0.30, 0.72, n1 * 0.8 + micro * 0.2), 3.0);
	if (w.z > 0.001) {
		// Needle litter over the dark tinted grass (forest shade), not bare earth: the lane and roads stay lighter.
		vec3 fl = mix(grass, needle_color, 0.6) * mix(0.82, 1.12, mix(0.5, lit, detail)) * (0.93 + micro * 0.14);
		float moss = smoothstep(0.62 - nw, 0.62 + nw, fine + (micro - 0.5) * 0.3);
		fl = mix(fl, moss_color * (0.9 + micro * 0.25), moss * 0.6);
		grass = mix(grass, fl, w.z * 0.8);
		tuft_amt -= w.z * (0.7 - moss * 0.35);
		flower_cut = max(flower_cut, w.z);
	}
	// Crown Isle ruins / landmarks: dry, ember-scorched grass with charred rims.
	if (ruin > 0.001) {
		float sn = (1.0 - fine) * 0.75 + (1.0 - mid) * 0.25 + (micro - 0.5) * 0.25;
		float scorch = smoothstep(0.64 - nw, 0.64 + nw, sn);
		float rim = smoothstep(0.59 - nw, 0.59 + nw, sn) * (1.0 - scorch);
		vec3 sc = mix(grass, grass_dry * 0.85, 0.38);
		sc = mix(sc, scorch_color * (0.85 + micro * 0.3), scorch * 0.75);
		sc *= 1.0 - rim * 0.14;
		grass = mix(grass, sc, ruin);
		tuft_amt -= ruin * (0.2 + scorch * 0.6);
		flower_cut = max(flower_cut, ruin * 0.7);
	}
	tuft_amt = clamp(tuft_amt, 0.0, 1.0);
	return grass;
}

// Wet bank band over the finished ground colour `col` at signed water distance wsd (< 0: a ford / Crown Steps bed
// under the 12.V1 film): dark wet earth and pebbles at the lip, damp earth, then sand with grass islands and the
// same painted lips as the dirt edges. Roads and the lane (`dirt`) stay dirt, only darker toward the water.
// tone = (smoothstep(0.3, 0.7, fine), its fwidth), taken before the per-pixel bank branch (shader lint B).
vec3 bank_paint(vec2 p, vec3 col, float wsd, float dirt, float px, float mid, float fine, float micro, vec2 tone) {
	float aa = px;
	float pf = 1.0 - smoothstep(0.06, 0.14, px);   // pebble detail fades when far
	if (wsd < 0.0) {
		vec3 bed = bank_wet * (0.8 + micro * 0.3);
		vec4 s = scatter(p + vec2(0.7, 0.2), 0.34, 0.5, 0.04, 0.09, aa * 0.75, -sun_dir * 0.03);
		bed = mix(bed, bed * 0.7, s.y * 0.6 * pf);
		return mix(bed, pebble_color * mix(0.55, 0.85, s.w), s.x * pf);
	}
	// Width varies along the bank (sand bars, then stretches where the grass comes down to the mud); the Crown
	// Isle side of the moat keeps only the mud and damp earth (its ruins meet the water).
	float along = smoothstep(0.30, 0.70, nz(p * 0.045 + vec2(7.3, 1.1)));
	float bw = bank_width * mix(0.34, 1.15, along) + (fine - 0.5) * 0.6 + (micro - 0.5) * 0.2;
	if (moat.z > 0.0 && length(p - moat.xy) < moat.z) {
		bw = min(bw, 1.0 + (fine - 0.5) * 0.4);
	}
	bw = max(bw, 0.55);
	float e = wsd - bw;                       // band edge, < 0 inside
	float band = edge_mask(e, aa);
	if (band <= 0.0 && e > 0.3) {
		return col;
	}
	float t = clamp(wsd / bw, 0.0, 1.0);
	float sw = 0.02 + px * 0.5;
	// Painted steps from the lip: wet mud (~0.45 m) -> damp earth (~0.5 m) -> sand where the band is wide.
	float mud_w = 0.42 + (fine - 0.5) * 0.35 + (micro - 0.5) * 0.12;
	float damp_w = mud_w + 0.5 + (mid - 0.5) * 0.5;
	vec3 bc = mix(bank_wet, bank_damp, smoothstep(mud_w - sw, mud_w + sw, wsd));
	bc = mix(bc, bank_sand, smoothstep(damp_w - sw, damp_w + sw, wsd));
	bc *= 0.90 + micro * 0.2;
	bc *= 0.95 + poster_w(tone.x, 3.0, tone.y) * 0.10;
	// A pale wet glint along the lip (sky in the mud) and the darkest line right at the edge.
	float glint = disc(abs(wsd - 0.17 - (micro - 0.5) * 0.08), 0.035, aa) * (1.0 - smoothstep(0.1, 0.25, px));
	bc = mix(bc, bc * 1.5 + vec3(0.03, 0.04, 0.045), glint * 0.45);
	bc *= mix(0.62, 1.0, smoothstep(0.0, 0.12, wsd));
	// Pebbles at the lip, a few on the damp earth.
	vec4 s = scatter(p + vec2(1.7, 0.3), 0.32, 0.42, 0.028, 0.07, aa * 0.75, -sun_dir * 0.03);
	float pm = (1.0 - smoothstep(mud_w * 0.6, damp_w, wsd)) * pf;
	bc = mix(bc, bc * 0.62, s.y * 0.7 * pm);
	vec3 pc = mix(pebble_color * 0.66, pebble_color * 0.95, s.w) * mix(0.8, 1.2, s.z);
	bc = mix(bc, pc, s.x * pm);
	// Grass islands in the outer sand.
	band *= 1.0 - smoothstep(0.62, 0.66, mid + (fine - 0.5) * 0.3) * smoothstep(0.55, 0.85, t) * step(damp_w, wsd);
	// Painted lips at the band edge: grass-overhang shadow inside, lit blade tips outside (not on dirt).
	float lipf = edge_lip * (1.0 - smoothstep(0.12, 0.3, px));
	bc *= 1.0 - 0.18 * lipf * smoothstep(-0.30 - aa, -0.24 + aa, e) * (1.0 - smoothstep(0.0, 0.2, e));
	vec3 outc = col * (1.0 + 0.10 * lipf * (1.0 - dirt) * (1.0 - smoothstep(0.20 - aa, 0.26 + aa, e)) * step(0.0, e));
	vec3 wet_dirt = col * mix(0.62, 1.0, smoothstep(0.0, 1.4, wsd));
	return mix(outc, mix(bc, wet_dirt, dirt), band);
}

void fragment() {
	vec2 p = v_wp.xz;
	float px = length(fwidth(p));
	float aa = px;
	vec3 grass = grass_color(p, px);
	float mid = nz(p * 0.040 + vec2(3.7, 1.9));
	float fine = nz(p * 0.20 + vec2(11.3, 4.2));
	float micro = nz(p * 0.9 + vec2(2.2, 6.1));
	// Shader lint B: every derivative the per-pixel branches below need is taken here, in uniform control flow.
	vec2 dpx2 = dFdx(p);
	vec2 dpy2 = dFdy(p);
	float fw_fine = fwidth(fine);
	float bank_tone = smoothstep(0.3, 0.7, fine);
	vec2 bank_t = vec2(bank_tone, fwidth(bank_tone));
	float road_tone = smoothstep(0.25, 0.75, fine * 0.6 + mid * 0.4);
	vec2 road_t = vec2(road_tone, fwidth(road_tone));
	float edge = (mid - 0.5) * edge_noise + (fine - 0.5) * 0.9 + (micro - 0.5) * 0.35;
	// Area harmony: the outer ring of the map (last ~20 m before the cliffs) turns a little darker and cooler,
	// a painted frame that keeps the eye on the play space; the plaza and the bases stay in the warm light.
	vec2 inside = halves() - abs(p);
	float in_map = step(0.0, min(inside.x, inside.y));
	float outer = (1.0 - smoothstep(3.0, 22.0, min(inside.x, inside.y) + (mid - 0.5) * 7.0)) * in_map * outer_cool;
	grass = mix(grass, grass * vec3(0.86, 0.93, 1.0), outer);

	// River cut (12.V2): skipped entirely without river and moat (the defaults). The discard itself happens at the
	// end, after every derivative (fwidth) of this pixel was taken.
	bool river_on = river_count > 0 || moat.z > 0.0;
	float wsd = 1e4;
	bool cut = false;
	if (river_on) {
		wsd = water_sd(p);
		cut = wsd < 0.0 && ford_sd(p) > 0.0;
	}
	// Biome tints (12.V2): skipped when biome_amount is 0 (the default).
	float tuft_amt = 1.0;
	float flower_boost = 0.0;
	float flower_cut = 0.0;
	if (biome_amount > 0.0) {
		float ruin = 0.0;
		vec4 bw = biome_weights(p, wsd, (mid - 0.5) * 3.2 + (fine - 0.5) * 1.1, ruin) * biome_amount;
		vec3 f = vec3(1.0) + bw.x * (v_tint0 - 1.0) + bw.y * (v_tint1 - 1.0) + bw.z * (v_tint2 - 1.0)
				+ bw.w * (v_tint3 - 1.0);
		f = mix(vec3(1.0), f, biome_tint_strength);
		grass = biome_paint(p, grass, f, bw, ruin * biome_amount, px, mid, fine, micro, tuft_amt, flower_boost,
				flower_cut);
	}

	// Dirt lane: meanders around the straight line between lane_a and lane_b.
	vec2 ba = lane_b - lane_a;
	float L = max(length(ba), 0.001);
	vec2 dir = ba / L;
	vec2 nrm = vec2(-dir.y, dir.x);
	float t = dot(p - lane_a, dir);
	float taper = smoothstep(0.0, 12.0, t) * smoothstep(0.0, 12.0, L - t);
	float off = (nz(vec2(t * 0.0045, 0.37)) - 0.5) * 3.2 * lane_meander * taper;
	float lat = dot(p - lane_a, nrm) - off;
	float d = (t >= 0.0 && t <= L) ? abs(lat) : seg_dist(p, lane_a, lane_b);
	// Every dirt shape is a noisy signed edge distance (< 0 inside); dirt_e keeps the nearest one for the lips.
	float dirt = 0.0;
	float dirt_e = 1e4;
	if (lane_half_width > 0.0) {
		float e_lane = d + edge * 0.8 - lane_half_width;
		dirt = edge_mask(e_lane, aa);
		dirt_e = e_lane;
	}
	float trod = 0.0;
	float pave = 0.0;
	vec4 pave_spot = vec4(0.0);
	vec4 spots[4] = { spot_0, spot_1, spot_2, spot_3 };
	for (int i = 0; i < 4; i++) {
		float e_spot = spot_edge(spots[i], p, edge);
		float m = edge_mask(e_spot, aa);
		dirt_e = min(dirt_e, e_spot);
		if (spots[i].w > 0.5) {
			if (m > pave) {
				pave = m;
				pave_spot = spots[i];
			}
			dirt = max(dirt, m);
		} else {
			trod = max(trod, m);
		}
	}
	// Trodden spots keep a few grass islands.
	// G-F r2 item 14: softer, raggeder island edges (micro noise, wider ramp) and thinner grass (a worn patch).
	dirt = max(dirt, trod * (0.92 - smoothstep(0.62, 0.72, mid + (fine - 0.5) * 0.3 + (micro - 0.5) * 0.14) * 0.36));

	// Trade roads (10.V10): skipped entirely when road_count is 0.
	float road = 0.0;
	vec4 rn = vec4(1e4, 0.0, 0.0, 1.0);
	float road_id = 0.0;
	vec2 road_s = vec2(0.0);
	if (road_count > 0) {
		float rhw = road_width * 0.5;
		rn = road_nearest(p, rhw + 1.5, road_id);
		float streak = road_streak(rn, road_id, micro);
		road_s = vec2(streak, fwidth(streak));   // before the per-pixel `road > 0` branch (shader lint B)
		if (rn.x < rhw + 1.5) {
			float e_road = rn.x + edge * 0.55 - rhw + 0.02;
			road = edge_mask(e_road, aa);
			dirt_e = min(dirt_e, e_road);
		}
	}

	// Dirt colour: posterised light / dark (calmer than A.10 so units read on it) with ruts along the lane and a
	// grassy crown between them.
	vec3 dcol = mix(dirt_dark, dirt_color, 0.45 + 0.55 * (poster(smoothstep(0.25, 0.75, fine * 0.55 + mid * 0.45), 3.0)
			* 0.7 + smoothstep(0.25, 0.75, fine) * 0.3));
	dcol *= 0.92 + micro * 0.16;
	float on_lane = step(d, lane_half_width + 0.3) * step(0.001, lane_half_width) * step(0.0, t) * step(t, L);
	float rut = disc(abs(abs(lat) - 0.95), 0.22, aa + 0.05) * on_lane;
	dcol *= 1.0 - rut * 0.22;
	float crown = disc(abs(lat) + (micro - 0.5) * 0.14, 0.25, aa + 0.15) * on_lane
			* smoothstep(0.48, 0.72, fine + (micro - 0.5) * 0.6);
	dcol = mix(dcol, worn_grass(grass, dcol, micro), crown * (1.0 - trod) * 0.8);
	dcol = pebbles(p, dcol, px, 1.0);
	if (road > 0.0) {
		dcol = mix(dcol, road_paint(p, rn, road_id, grass, px, mid, fine, micro, road_t, road_s), road);
		dirt = max(dirt, road);
	}

	// Grass details (flowers only in patches away from paths).
	float flower_mask = smoothstep(0.69, 0.74, nz(p * 0.05 + vec2(8.3, 0.7)) + (fine - 0.5) * 0.2);
	flower_mask = max(flower_mask * (1.0 - flower_cut), flower_boost);   // biomes (no change by default)
	flower_mask *= 1.0 - smoothstep(0.0, 0.3, dirt + pave);
	vec3 gcol = grass_details(p, grass, px, tuft_amt, flower_mask);
	// Painted edge lips: the grass overhangs the dirt (a thin cool shadow just inside the edge) and its blade tips
	// catch the light just outside it. Fades out when a pixel gets wider than the lip.
	float lip_fade = edge_lip * (1.0 - smoothstep(0.12, 0.3, px));
	float lip_aa = px * 0.8;
	dcol *= 1.0 - 0.22 * lip_fade * smoothstep(-0.30 - lip_aa, -0.24 + lip_aa, dirt_e) * (1.0 - smoothstep(0.0, 0.2, dirt_e));
	gcol *= 1.0 + 0.10 * lip_fade * (1.0 - smoothstep(0.20 - lip_aa, 0.26 + lip_aa, dirt_e)) * step(0.0, dirt_e);
	vec3 col = mix(gcol, dcol, dirt);
	// Far away (lips faded) keep a faint dark seam so the edge still reads.
	col *= 1.0 - 0.12 * clamp(dirt * (1.0 - dirt) * 4.0, 0.0, 1.0);
	// G2a relief height (metres-ish, only its gradient matters): dirt below the grass, ruts below the dirt.
	float hgt = -0.30 * dirt - 0.10 * rut * dirt;
	// Wet bank band along the river and moat (12.V2), under the plaza flagstones.
	if (river_on && wsd < bank_width + 1.6) {
		col = bank_paint(p, col, wsd, dirt, px, mid, fine, micro, bank_t);
		hgt -= (1.0 - smoothstep(0.0, bank_width + 0.8, wsd)) * 0.45;
	}
	vec3 emit = vec3(0.0);
	if (pave > 0.0) {
		col = plaza(p, pave_spot.xy, pave_spot.z, pave, col, px, mid, fine, emit, hgt);
	}

	// Cliff-foot occlusion (map_dressing cliffs: north 10 m, west 8.5, east 7.5, south 3): a cool painted shade
	// that reaches further under the taller walls, broken by the ground noise so it never draws a ruler line.
	if (cliff_ao > 0.0 && in_map > 0.5) {
		float jit = (mid - 0.5) * 2.4 + (fine - 0.5) * 0.8;
		float hx = p.x < 0.0 ? 0.85 : 0.75;
		float hz = p.y < 0.0 ? 1.0 : 0.3;
		float ao = max(hx * (1.0 - smoothstep(0.0, cliff_ao_width * hx, inside.x + jit)),
				hz * (1.0 - smoothstep(0.0, cliff_ao_width * hz, inside.y + jit)));
		col = mix(col, col * vec3(0.62, 0.68, 0.80), min(ao * ao * cliff_ao * 2.0, 1.0));
	}

	// G-E fixes B: snow (uniform branch; texture reads only, no derivative calls). Big blue-grey drift shading, then
	// sastrugi: wind ridges across `snow_wind` in patches, a cool lee shadow and a lit crest, faded out when a pixel
	// gets wider than the ridges (no shimmer at max zoom). Sparkle: rare glints on a 0.2 m grid that twinkle with time
	// and the camera position (unlit EMISSION, a touch only).
	if (snow_mode > 0.5) {
		float drift = smoothstep(0.30, 0.78, mid + (fine - 0.5) * 0.35);
		col *= mix(vec3(1.0), snow_shade * 1.12, drift * 0.42 * in_map);
		vec2 wd = normalize(snow_wind);
		vec2 wq = vec2(dot(p, wd), dot(p, vec2(-wd.y, wd.x)));
		float wpatch = smoothstep(0.42, 0.66, nz(vec2(wq.x * 0.025, wq.y * 0.012) + vec2(5.1, 2.4)));
		float wob = nz(vec2(wq.x * 0.05, wq.y * 0.11) + vec2(1.3, 7.7));
		float sf = fract(wq.x * 0.42 + (wob - 0.5) * 2.6);
		float sfade = (1.0 - smoothstep(0.06, 0.16, px)) * wpatch * in_map;
		float brk = smoothstep(0.4, 0.6, nz(vec2(wq.x * 0.08, wq.y * 0.5) + vec2(9.2, 3.1)));   // short ridges, not contours
		float lee = (1.0 - smoothstep(0.0, 0.16, sf)) * sfade * brk;
		float crest = smoothstep(0.80, 0.97, sf) * sfade * brk;
		col = mix(col, col * snow_shade, lee * 0.4);
		col += vec3(0.035, 0.04, 0.045) * crest;
		vec2 sg = p * 5.0;
		vec2 sid = floor(sg);
		float sh = hash(sid);
		float phase = sh * 40.0 + TIME * 1.6 + dot(CAMERA_POSITION_WORLD.xz, vec2(0.9, 0.6)) * 0.6;
		float spark = step(0.965, hash(sid + 3.7)) * pow(max(sin(phase), 0.0), 10.0);
		spark *= disc(length(fract(sg) - 0.5), 0.16, 0.12) * (1.0 - smoothstep(0.05, 0.12, px));
		emit += vec3(0.85, 0.92, 1.0) * spark * snow_sparkle * in_map * (1.0 - dirt);
	}

	// Border outside the map square.
	vec2 outv = max(abs(p) - halves(), vec2(0.0));
	float od = length(outv);
	od += (edge * 0.6) * smoothstep(0.0, 0.5, od);
	if (forest_floor > 0.5) {
		// Plateau of map_dressing: dark forest floor under the tree band, painted canopy further out.
		// (MAP.P1: darker and cooler than the play space so the map reads as a lit hollow in a shady forest.)
		vec3 floor_c = mix(grass * 0.55, clover_color, 0.35) * vec3(0.90, 0.95, 1.0);
		floor_c = grass_details(p, floor_c, px, 0.8, 0.0);
		float cz = smoothstep(canopy_start - 1.0, canopy_start + 1.0, od + (mid - 0.5) * 6.0);
		col = mix(floor_c, canopy(p, px), cz);
		col = mix(col, haze_color, smoothstep(canopy_start + 10.0, canopy_start + 90.0, od) * 0.75);
	} else if (border_mode > 0.5 && od > 0.0) {
		float scree_t = smoothstep(0.0, 0.6, od);
		vec3 scree = mix(dirt_dark, rock_color, 0.55) * (0.85 + micro * 0.3);
		scree = pebbles(p * 1.3, scree, px, 1.0);
		col = mix(col, scree, scree_t);
		float rock_t = smoothstep(2.0, 2.6, od + (micro - 0.5) * 0.8);
		vec3 rock = rock_color * (0.55 + poster_w(fine, 3.0, fw_fine) * 0.35);
		rock *= 0.8 + 0.2 * step(0.5, fract((p.x + p.y) * 0.9 + fine * 2.0));
		col = mix(col, rock, rock_t);
		float can_t = smoothstep(canopy_start - 0.5, canopy_start + 0.5, od + (mid - 0.5) * 4.0);
		col = mix(col, canopy_grad(p, dpx2, dpy2), can_t);
		col = mix(col, haze_color, smoothstep(canopy_start + 10.0, canopy_start + 90.0, od) * 0.75);
	}

	// G2a relief: a world-space normal from the screen-space gradient of hgt (cheap; derivatives taken before the
	// discard). Fades out when a pixel is wider than the features (no shimmer at max zoom).
	vec3 relief_n = vec3(0.0, 1.0, 0.0);
	float rk = relief * (1.0 - smoothstep(0.07, 0.14, px));
	// The four derivatives are taken before the branch: rk fades with px, so it can change inside a pixel quad.
	vec3 dpx = dFdx(v_wp);
	vec3 dpy = dFdy(v_wp);
	float hx = dFdx(hgt);
	float hy = dFdy(hgt);
	if (rk > 0.0 && bake_mode == 0) {
		float det = dpx.x * dpy.z - dpx.z * dpy.x;
		if (abs(det) > 1e-9) {
			vec2 g = vec2(hx * dpy.z - hy * dpx.z, dpx.x * hy - dpy.x * hx) / det;
			g = clamp(g * rk, vec2(-1.5), vec2(1.5));
			relief_n = normalize(vec3(-g.x, 1.0, -g.y));
		}
	}

	// 12.V2: open the ground over deep water (the 12.V1 trench and water show through).
	if (cut) {
		discard;
	}
	if (bake_mode == 1) {
		// G2a colour bake: the plain (biome-tinted, framed) grass colour; blades add their own detail.
		vec3 gb = grass;
		if (cliff_ao > 0.0 && in_map > 0.5) {
			float hx2 = p.x < 0.0 ? 0.85 : 0.75;
			float hz2 = p.y < 0.0 ? 1.0 : 0.3;
			float ao2 = max(hx2 * (1.0 - smoothstep(0.0, cliff_ao_width * hx2, inside.x)),
					hz2 * (1.0 - smoothstep(0.0, cliff_ao_width * hz2, inside.y)));
			gb = mix(gb, gb * vec3(0.62, 0.68, 0.80), min(ao2 * ao2 * cliff_ao * 2.0, 1.0));
		}
		ALBEDO = vec3(0.0);
		EMISSION = gb;
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
	} else if (bake_mode == 2) {
		// G2a mask bake: R = grass (no dirt, paving, bank band, border), G = flower patches, B = blade height x 0.5.
		float bank_free = river_on ? smoothstep(bank_width * 0.7, bank_width + 1.2, wsd) : 1.0;
		float g_amt = (1.0 - dirt) * (1.0 - smoothstep(0.0, 0.3, pave)) * bank_free * in_map;
		g_amt *= mix(1.0, tuft_amt, 0.55);
		g_amt *= 1.0 - step(0.5, snow_mode);   // G-E fixes B: no grass blades on snow
		float hmul = 1.0;
		if (biome_amount > 0.0) {
			// Taller on the heath and the riverbank, short in the Old Wood shade (tuft_amt already thins it).
			hmul = mix(1.0, 0.75, 1.0 - tuft_amt) * (1.0 + 0.25 * flower_cut);
		}
		ALBEDO = vec3(0.0);
		// The bake viewport stores sRGB: emit the linear value that encodes back to the mask value.
		vec3 mk = clamp(vec3(g_amt, flower_mask, hmul * 0.5), 0.0, 1.0);
		EMISSION = mix(mk / 12.92, pow((mk + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), mk));
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
	} else {
		ALBEDO = col;
		EMISSION = emit;
		ROUGHNESS = 1.0;
		if (rk > 0.0) {
			NORMAL = normalize(mat3(VIEW_MATRIX) * relief_n);
		}
	}
}

void light() {
	if (relief > 0.0) {
		// G2a: the painted ramp from the flat ground (same look), shaded by the relief normal.
		vec3 up = normalize(mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0));
		float fl = dot(up, LIGHT);
		float d0 = fl * 0.5 + 0.5;
		float ramp0 = smoothstep(0.32, 0.42, d0) * 0.55 + smoothstep(0.58, 0.68, d0) * 0.45;
		float rel = clamp(1.0 + (dot(NORMAL, LIGHT) - fl) / max(fl, 0.3) * 0.9, 0.55, 1.35);
		DIFFUSE_LIGHT += ramp0 * rel * ATTENUATION * LIGHT_COLOR / PI;
	} else {
		float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
		float ramp = smoothstep(0.32, 0.42, d) * 0.55 + smoothstep(0.58, 0.68, d) * 0.45;
		DIFFUSE_LIGHT += ramp * ATTENUATION * LIGHT_COLOR / PI;
	}
}

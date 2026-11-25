shader_type canvas_item;

uniform vec4 col_a : source_color = vec4(0.055, 0.09, 0.145, 1.0);
uniform vec4 col_b : source_color = vec4(0.085, 0.155, 0.225, 1.0);
uniform vec4 col_accent : source_color = vec4(0.12, 0.24, 0.31, 1.0);
uniform float speed : hint_range(0.0, 1.0) = 0.18;
uniform float pixel_grid : hint_range(1.0, 8.0) = 3.0;

float bayer4(vec2 p) {
	ivec2 ip = ivec2(mod(p, 4.0));
	int idx = ip.y * 4 + ip.x;
	if (idx == 0) return 0.0 / 16.0;
	if (idx == 1) return 8.0 / 16.0;
	if (idx == 2) return 2.0 / 16.0;
	if (idx == 3) return 10.0 / 16.0;
	if (idx == 4) return 12.0 / 16.0;
	if (idx == 5) return 4.0 / 16.0;
	if (idx == 6) return 14.0 / 16.0;
	if (idx == 7) return 6.0 / 16.0;
	if (idx == 8) return 3.0 / 16.0;
	if (idx == 9) return 11.0 / 16.0;
	if (idx == 10) return 1.0 / 16.0;
	if (idx == 11) return 9.0 / 16.0;
	if (idx == 12) return 15.0 / 16.0;
	if (idx == 13) return 7.0 / 16.0;
	if (idx == 14) return 13.0 / 16.0;
	return 5.0 / 16.0;
}

void fragment() {
	vec2 frag_cell = floor(FRAGCOORD.xy / pixel_grid);
	vec2 uv = frag_cell * pixel_grid * SCREEN_PIXEL_SIZE;
	float t = TIME * speed;

	vec2 warp = uv * 3.2;
	warp.x += sin(warp.y * 1.9 + t * 1.7) * 0.45;
	warp.y += cos(warp.x * 1.6 - t * 1.3) * 0.45;
	float wave = 0.5 + 0.5 * sin(warp.x + warp.y + sin(t));
	float dither = bayer4(frag_cell) - 0.5;
	float stepped = floor((wave + dither * 0.22) * 4.0) / 4.0;

	vec3 c = mix(col_a.rgb, col_b.rgb, clamp(stepped, 0.0, 1.0));
	if (stepped > 0.72) {
		c = mix(c, col_accent.rgb, 0.35);
	}
	COLOR = vec4(c, 1.0);
}

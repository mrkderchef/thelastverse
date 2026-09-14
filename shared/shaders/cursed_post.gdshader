shader_type canvas_item;
// Degraded early-2000s CGI look: low virtual resolution, oversharpening, blocky
// compression, lens warp, colour fringing, crushed grade, grain, and look smear.
// `strength` is the player's visual distortion setting; `dread` rises with progress.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float dread : hint_range(0.0, 1.0) = 0.0;
uniform vec2 smear = vec2(0.0);
uniform float virtual_height = 600.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 grab(vec2 uv) {
	return texture(screen_tex, clamp(uv, vec2(0.001), vec2(0.999))).rgb;
}

void fragment() {
	float s = strength;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 centered = SCREEN_UV - 0.5;
	// Barrel warp, scaled so the corners stay on screen.
	float r2 = dot(centered * vec2(aspect, 1.0), centered * vec2(aspect, 1.0));
	vec2 uv = 0.5 + centered * (1.0 - 0.05 * s + r2 * 0.06 * s);

	// Rare torn scanline bands; more frequent as dread builds. No brightness flashes.
	float band = floor(uv.y * 30.0);
	float tick = floor(TIME * 9.0);
	float tear = step(0.985 - 0.035 * dread, hash(vec2(band, tick)));
	uv.x += tear * (hash(vec2(tick, band)) - 0.5) * 0.05 * s;

	vec2 vres = vec2(virtual_height * aspect, virtual_height);
	vec2 texel = 1.0 / vres;
	vec2 puv = mix(uv, (floor(uv * vres) + 0.5) / vres, s);

	vec3 col = vec3(0.0);
	for (int i = 0; i < 5; i++) {
		col += grab(puv + smear * (float(i) / 4.0 - 0.5) * s);
	}
	col /= 5.0;

	vec2 fringe = centered * (0.0012 + 0.002 * dread) * s;
	col.r = mix(col.r, grab(puv + fringe).r, s);
	col.b = mix(col.b, grab(puv - fringe).b, s);

	vec3 blur = (grab(puv + vec2(texel.x, 0.0)) + grab(puv - vec2(texel.x, 0.0))
		+ grab(puv + vec2(0.0, texel.y)) + grab(puv - vec2(0.0, texel.y))) * 0.25;
	col += (col - blur) * 0.45 * s;

	// Compression: chroma smeared across 8x8 blocks and quantized, luma kept sharp.
	vec3 block = grab((floor(uv * vres / 8.0) + 0.5) * 8.0 / vres);
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 chroma = mix(col, block, 0.25 * s) - dot(mix(col, block, 0.25 * s), vec3(0.299, 0.587, 0.114));
	chroma = mix(chroma, floor(chroma * 14.0 + 0.5) / 14.0, s);
	col = vec3(luma) + chroma;

	// Grade: punchy but neutral saturation, lifted mids, cool shadows, barely warm highlights.
	luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(luma), col, 1.0 + 0.25 * s);
	col = mix(col, pow(max(col, vec3(0.0)), vec3(0.93)) * 1.02, s);
	col = mix(col, col * vec3(0.9, 0.95, 1.1), (1.0 - smoothstep(0.0, 0.3, luma)) * 0.3 * s);
	col = mix(col, col * vec3(1.03, 1.0, 0.96), smoothstep(0.5, 1.0, luma) * 0.3 * s);
	col = mix(col, floor(col * 40.0) / 40.0, s);

	float grain = hash(floor(SCREEN_UV / SCREEN_PIXEL_SIZE / 2.0) + fract(TIME * 13.0) * 97.0) - 0.5;
	col += grain * (0.012 + 0.018 * dread) * s;
	float vignette = smoothstep(0.95, 0.2, length(centered * vec2(aspect * 0.8, 1.0)));
	col *= mix(1.0, vignette, 0.5 * s);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}

shader_type sky;
// A cheerful, over-saturated early-3D daytime sky: deep blue, crunchy pixelated clouds,
// and a sun with a star-shaped lens burst.

uniform vec3 zenith : source_color = vec3(0.05, 0.22, 0.85);
uniform vec3 horizon : source_color = vec3(0.55, 0.78, 1.0);
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.75);
uniform vec3 sun_direction = vec3(-0.35, 0.55, -0.75);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.55;
	for (int i = 0; i < 5; i++) {
		value += noise(p) * amplitude;
		p = p * 2.03 + vec2(1.7, 9.2);
		amplitude *= 0.5;
	}
	return value;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float up = max(d.y, 0.0);
	vec3 col = mix(horizon, zenith, smoothstep(0.0, 0.55, up));
	vec2 plane = floor(d.xz / (d.y + 0.15) * 2.2 * 56.0) / 56.0;
	float clouds = fbm(plane + vec2(TIME * 0.012, TIME * 0.004));
	float mask = smoothstep(0.5, 0.72, clouds) * smoothstep(0.0, 0.15, d.y + 0.02);
	vec3 cloud_col = mix(vec3(0.78, 0.84, 0.95), vec3(1.0), smoothstep(0.6, 0.9, clouds));
	col = mix(col, cloud_col, mask);
	vec3 s = normalize(sun_direction);
	float c = dot(d, s);
	vec3 side = normalize(cross(s, vec3(0.0, 1.0, 0.0)));
	vec3 lift = cross(side, s);
	float angle = atan(dot(d, lift), dot(d, side));
	float star = pow(abs(cos(angle * 4.0)), 60.0) * smoothstep(0.93, 0.9995, c);
	col += sun_color * (smoothstep(0.9985, 0.9992, c) * 6.0 + pow(max(c, 0.0), 180.0) * 1.5 + star * 3.0);
	float below = max(-d.y, 0.0);
	col = mix(col, horizon * 0.8, smoothstep(0.0, 0.1, below));
	COLOR = col;
}

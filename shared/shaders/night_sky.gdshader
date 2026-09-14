shader_type sky;
// Crunchy pixelated storm clouds over a burning horizon with a blood moon.

uniform vec3 zenith : source_color = vec3(0.01, 0.012, 0.04);
uniform vec3 cloud_light : source_color = vec3(0.34, 0.26, 0.42);
uniform vec3 fire : source_color = vec3(0.9, 0.22, 0.05);
uniform vec3 moon_color : source_color = vec3(1.0, 0.25, 0.12);
uniform vec3 moon_direction = vec3(0.25, 0.32, -1.0);

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
	vec3 col = mix(fire * 0.16, zenith, smoothstep(0.0, 0.3, up));
	// Pixelated cloud plane.
	vec2 plane = d.xz / (d.y + 0.12) * 2.0;
	plane = floor(plane * 48.0) / 48.0;
	float clouds = fbm(plane + vec2(TIME * 0.02, TIME * 0.008));
	float mask = smoothstep(0.42, 0.78, clouds) * smoothstep(0.0, 0.12, d.y + 0.02);
	vec3 cloud_col = mix(cloud_light * 0.25, cloud_light, smoothstep(0.55, 0.9, clouds));
	cloud_col = mix(cloud_col, fire * 0.4, (1.0 - smoothstep(0.0, 0.2, up)) * 0.6);
	col = mix(col, cloud_col, mask);
	// Moon disc, halo, and eight-point star.
	vec3 m = normalize(moon_direction);
	float c = dot(d, m);
	float disc = smoothstep(0.9990, 0.9994, c);
	vec3 side = normalize(cross(m, vec3(0.0, 1.0, 0.0)));
	vec3 lift = cross(side, m);
	vec2 local = vec2(dot(d, side), dot(d, lift));
	float angle = atan(local.y, local.x);
	float star = pow(abs(cos(angle * 4.0)), 80.0) * smoothstep(0.9, 0.9993, c);
	col += moon_color * (disc * 4.0 + pow(max(c, 0.0), 400.0) * 1.2 + star * 2.5) * (1.0 - mask * 0.6);
	// Sparse stars peeking between clouds.
	vec2 cell = floor(d.xz / (d.y + 0.2) * 90.0);
	col += vec3(0.8, 0.85, 1.0) * step(0.9975, hash(cell)) * (1.0 - mask) * smoothstep(0.1, 0.4, up);
	// Below the horizon, the city burns.
	float below = max(-d.y, 0.0);
	col = mix(col, fire * (0.3 + 0.7 * fbm(d.xz * 20.0 + TIME * 0.3)) * 0.22, smoothstep(0.0, 0.08, below));
	COLOR = col;
}

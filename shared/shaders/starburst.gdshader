shader_type spatial;
// Camera-facing cheap lens star for candles, sigils, and windows.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.8, 0.55, 1.0);
uniform float spikes = 8.0;
uniform float seed = 0.0;
uniform float intensity = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	// Pull toward the camera so the flame's own mesh does not cut the star.
	MODELVIEW_MATRIX[3].xyz -= normalize(MODELVIEW_MATRIX[3].xyz) * 0.12;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float angle = atan(p.y, p.x) + TIME * 0.12 + seed;
	float twinkle = 0.7 + 0.3 * sin(TIME * (2.0 + fract(seed) * 3.0) + seed * 11.0);
	float long_rays = pow(abs(cos(angle * spikes * 0.5)), 90.0);
	float short_rays = pow(abs(cos(angle * spikes * 0.5 + 1.5708)), 160.0) * 0.45;
	float rays = (long_rays + short_rays) * pow(max(1.0 - r, 0.0), 1.6) * twinkle;
	float core = exp(-r * r * 60.0) * 3.0 + exp(-r * 7.0) * 0.4;
	float value = (rays + core) * smoothstep(1.0, 0.75, r) * intensity;
	ALBEDO = tint.rgb * value * 2.5;
	ALPHA = clamp(value, 0.0, 1.0);
}

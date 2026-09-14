shader_type spatial;
render_mode cull_disabled;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = world_pos.xz;
	float ripples = sin(p.y * 13.0 + p.x * 8.0 + TIME * 2.4);
	float cross_wave = sin(p.x * 21.0 - p.y * 5.0 + TIME * 1.7);
	float eddy = sin(p.y * 2.5 + sin(p.x * 7.0) + TIME * 0.5);
	float foam = smoothstep(0.91, 1.0, sin(p.y * 8.0 + sin(p.x * 17.0) + TIME));
	float edge = smoothstep(0.85, 1.14, abs(p.x));
	ALBEDO = mix(vec3(0.025, 0.065, 0.06), vec3(0.10, 0.16, 0.105), eddy * 0.5 + 0.5);
	ALBEDO += vec3(0.19, 0.20, 0.135) * foam * edge * 0.6;
	NORMAL_MAP = vec3(0.5 + ripples * 0.075, 0.5 + cross_wave * 0.065, 1.0);
	ROUGHNESS = 0.22 + foam * edge * 0.2;
	METALLIC = 0.3;
	SPECULAR = 0.7;
}

shader_type sky;
// A quiet, blue night behind the six authored and countable constellation meshes.
void sky() {
	vec3 d = normalize(EYEDIR);
	float high = smoothstep(0.0, 0.9, max(d.y, 0.0));
	vec3 color = mix(vec3(0.035, 0.055, 0.10), vec3(0.004, 0.009, 0.028), high);
	float veil = sin(d.x * 7.0 + d.z * 5.0) * sin(d.y * 9.0 - d.z * 4.0);
	color += vec3(0.005, 0.008, 0.014) * (veil * 0.5 + 0.5);
	COLOR = color;
}

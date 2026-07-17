shader_type canvas_item;

uniform float pulse_strength : hint_range(0.0, 0.15) = 0.05;
uniform float shimmer_strength : hint_range(0.0, 0.2) = 0.08;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));

	// Parpadeo suave en ventanas y faroles (zonas brillantes).
	float bright = smoothstep(0.42, 0.82, lum);
	float flicker = sin(TIME * 3.1 + UV.x * 48.0) * sin(TIME * 2.4 + UV.y * 41.0 + 1.7);
	col.rgb *= 1.0 + bright * flicker * pulse_strength;

	// Brillo sutil en agua oscura (puerto / costa).
	float water_mask = smoothstep(0.04, 0.22, lum) * (1.0 - smoothstep(0.22, 0.38, lum));
	float water_tint = step(col.b, col.r * 0.92) * step(col.b * 0.95, col.g);
	float shimmer = sin(TIME * 1.35 + UV.x * 90.0 + UV.y * 70.0) * 0.5 + 0.5;
	col.rgb += vec3(0.02, 0.05, 0.12) * water_mask * water_tint * shimmer * shimmer_strength;

	COLOR = col;
}

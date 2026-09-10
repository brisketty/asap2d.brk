shader_type canvas_item;

// Cheap full-screen biome wash: a flat tint plus a faint vertical shimmer so
// the overlay reads as "atmosphere" rather than a dead colour fill.

uniform vec4 tint : source_color = vec4(0.2, 0.4, 0.8, 0.22);
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.35;
uniform float shimmer_speed = 2.0;

void fragment() {
	float shimmer = sin((UV.y * 42.0) + (TIME * shimmer_speed)) * shimmer_strength;
	COLOR = vec4(tint.rgb, clamp(tint.a + shimmer * 0.05, 0.0, 1.0));
}

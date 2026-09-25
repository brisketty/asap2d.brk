shader_type canvas_item;

// State grade: a pulsing coloured vignette for "hurt" / "low health". Drawn on a
// full-screen ColorRect, so UV is 0..1 across the screen.

uniform vec4 edge_color : source_color = vec4(0.7, 0.0, 0.05, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.6;
uniform float pulse_speed = 3.0;

void fragment() {
	float d = distance(UV, vec2(0.5));
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	float v = smoothstep(0.25, 0.8, d) * intensity * pulse;
	COLOR = vec4(edge_color.rgb, v);
}

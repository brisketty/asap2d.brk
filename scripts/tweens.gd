class_name Tweens
## Reusable tween recipes for UI polish. Each takes the node to animate (which
## must already be inside the tree) and returns the `Tween` so callers can
## `await` it or chain more steps. Standalone - any scene can use these without
## the HUD subsystem.

static func pop(p_control: Control, p_overshoot: float = 1.25, p_seconds: float = 0.22) -> Tween:
	var base := p_control.scale
	p_control.pivot_offset = p_control.size * 0.5
	var tween := p_control.create_tween()
	tween.tween_property(p_control, "scale", base * p_overshoot, p_seconds * 0.35)
	tween.tween_property(p_control, "scale", base, p_seconds * 0.65) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return tween


static func fade_out(p_canvas_item: CanvasItem, p_seconds: float = 0.3) -> Tween:
	var tween := p_canvas_item.create_tween()
	tween.tween_property(p_canvas_item, "modulate:a", 0.0, p_seconds)
	return tween


static func rise_and_fade(p_node: Node2D, p_rise: float = 48.0, p_seconds: float = 0.7) -> Tween:
	var start := p_node.position
	var tween := p_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(p_node, "position", start + Vector2(0.0, -p_rise), p_seconds) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(p_node, "modulate:a", 0.0, p_seconds).set_delay(p_seconds * 0.35)
	return tween


static func shake(p_control: Control, p_pixels: float = 6.0, p_seconds: float = 0.3) -> Tween:
	var base := p_control.position
	var tween := p_control.create_tween()
	var steps := 5
	for i: int in steps:
		var sign_value := 1.0 if i % 2 == 0 else -1.0
		var falloff := 1.0 - float(i) / float(steps)
		tween.tween_property(p_control, "position", base + Vector2(p_pixels * sign_value * falloff, 0.0), p_seconds / float(steps))
	tween.tween_property(p_control, "position", base, p_seconds / float(steps))
	return tween

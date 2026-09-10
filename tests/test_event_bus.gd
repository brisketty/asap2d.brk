extends SceneTree

const EventBusScript := preload("res://autoloads/event_bus.gd")


func _initialize() -> void:
	var failure_count := 0

	var bus: Node = EventBusScript.new()

	var received: Array[Dictionary] = []
	var listener_a := func(p_id: StringName, p_context: Dictionary) -> void:
		received.append({&"who": &"a", &"id": p_id, &"context": p_context})
	var listener_b := func(p_id: StringName, p_context: Dictionary) -> void:
		received.append({&"who": &"b", &"id": p_id, &"context": p_context})
	bus.semantic_event_emitted.connect(listener_a)
	bus.semantic_event_emitted.connect(listener_b)

	var context := Utility.make_spatial_context(Vector2(3, 4), Vector2.RIGHT, 2.5, &"cannon")
	bus.emit_semantic_event(&"impact.basic", context)

	failure_count += expect_int("both listeners fire once", received.size(), 2)
	failure_count += expect_true("id round-trips", received[0][&"id"] == &"impact.basic")
	failure_count += expect_true(
		"position round-trips",
		(received[0][&"context"] as Dictionary).get(Utility.CONTEXT_POSITION_KEY) == Vector2(3, 4),
	)
	failure_count += expect_true(
		"magnitude round-trips",
		is_equal_approx((received[1][&"context"] as Dictionary).get(Utility.CONTEXT_MAGNITUDE_KEY), 2.5),
	)

	bus.free()

	if failure_count > 0:
		push_error("%d event-bus test(s) failed." % failure_count)
		quit(1)
		return
	print("All event-bus tests passed.")
	quit(0)


func expect_int(p_label: String, p_actual: int, p_expected: int) -> int:
	if p_actual == p_expected:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s (expected %d, got %d)" % [p_label, p_expected, p_actual])
	return 1


func expect_true(p_label: String, p_actual: bool) -> int:
	if p_actual:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s" % p_label)
	return 1

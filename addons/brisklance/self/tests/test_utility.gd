extends SceneTree


func _initialize() -> void:
	var failure_count := 0

	failure_count += expect_true("null is invalid", not Utility.is_object_valid(null))

	var live_ref := RefCounted.new()
	failure_count += expect_true("live RefCounted is valid", Utility.is_object_valid(live_ref))

	var live_node := Node.new()
	failure_count += expect_true("live Node is valid", Utility.is_object_valid(live_node))

	var freed_node := Node.new()
	freed_node.free()
	failure_count += expect_true("freed Node is invalid", not Utility.is_object_valid(freed_node))

	var queued_node := Node.new()
	get_root().add_child(queued_node)
	queued_node.queue_free()
	failure_count += expect_true("queued-for-deletion Node is invalid", not Utility.is_object_valid(queued_node))

	live_node.free()

	var context := Utility.make_spatial_context(Vector2(1, 2), Vector2.DOWN, 7.0, &"trap")
	failure_count += expect_true("context position", context[Utility.CONTEXT_POSITION_KEY] == Vector2(1, 2))
	failure_count += expect_true("context direction", context[Utility.CONTEXT_DIRECTION_KEY] == Vector2.DOWN)
	failure_count += expect_true("context magnitude", is_equal_approx(context[Utility.CONTEXT_MAGNITUDE_KEY], 7.0))
	failure_count += expect_true("context source id", context[Utility.CONTEXT_SOURCE_ID_KEY] == &"trap")

	var defaulted := Utility.make_spatial_context(Vector2.ZERO)
	failure_count += expect_true("context defaults direction to zero", defaulted[Utility.CONTEXT_DIRECTION_KEY] == Vector2.ZERO)
	failure_count += expect_true("context defaults source id to empty", defaulted[Utility.CONTEXT_SOURCE_ID_KEY] == &"")

	if failure_count > 0:
		push_error("%d utility test(s) failed." % failure_count)
		quit(1)
		return
	print("All utility tests passed.")
	quit(0)


func expect_true(p_label: String, p_actual: bool) -> int:
	if p_actual:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s" % p_label)
	return 1

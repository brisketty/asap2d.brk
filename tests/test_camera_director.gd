extends SceneTree
## Covers CameraTranslation (pure). The subsystem Node references the EventBus /
## ThemeManager autoloads (absent in a --script run), so its wiring and the
## CameraRig are verified via the demo scene / a smoke instead.


func _initialize() -> void:
	var failure_count := 0

	# --- trauma accumulation / decay / clamp ---
	failure_count += expect_true("trauma clamps to 1.0",
		is_equal_approx(CameraTranslation.add_trauma(0.6, 0.7), 1.0))
	failure_count += expect_true("trauma clamps to 0.0",
		is_equal_approx(CameraTranslation.add_trauma(0.1, -0.5), 0.0))
	failure_count += expect_true("trauma adds",
		is_equal_approx(CameraTranslation.add_trauma(0.2, 0.3), 0.5))
	failure_count += expect_true("decay subtracts rate * delta",
		is_equal_approx(CameraTranslation.decay_trauma(0.5, 1.0, 0.1), 0.4))
	failure_count += expect_true("decay floors at zero",
		is_equal_approx(CameraTranslation.decay_trauma(0.05, 1.0, 0.1), 0.0))

	# --- shake curve ---
	failure_count += expect_true("shake is trauma squared",
		is_equal_approx(CameraTranslation.shake_amount(0.5), 0.25))
	failure_count += expect_true("no shake at zero trauma",
		is_equal_approx(CameraTranslation.shake_amount(0.0), 0.0))
	failure_count += expect_true("zero trauma -> zero offset",
		CameraTranslation.compute_offset(0.0, Vector2(10, 10), 1.0, 1.0) == Vector2.ZERO)
	failure_count += expect_true("offset scales by amount, max and noise",
		CameraTranslation.compute_offset(1.0, Vector2(10, 20), 0.5, -1.0) == Vector2(5, -20))
	failure_count += expect_true("rotation scales by amount, max roll and noise",
		is_equal_approx(CameraTranslation.compute_rotation(1.0, 0.1, 0.5), 0.05))
	failure_count += expect_true("zero trauma -> zero rotation",
		is_equal_approx(CameraTranslation.compute_rotation(0.0, 0.1, 1.0), 0.0))

	# --- event -> trauma table ---
	var lookup := CameraTranslation.build_lookup(CameraTranslation.build_default_trauma_table())
	failure_count += expect_true("crit has more trauma than heavy",
		CameraTranslation.resolve_trauma(lookup, &"impact.crit") > CameraTranslation.resolve_trauma(lookup, &"impact.heavy"))
	failure_count += expect_true("unlisted event -> zero trauma",
		is_equal_approx(CameraTranslation.resolve_trauma(lookup, &"impact.basic"), 0.0))

	var custom := CameraTranslation.make_trauma(&"camera.custom", 0.9)
	var with_invalid: Array[CameraTrauma] = [null, custom]
	var custom_lookup := CameraTranslation.build_lookup(with_invalid)
	failure_count += expect_int("build_lookup skips invalid rows", custom_lookup.size(), 1)
	failure_count += expect_true("custom row resolves",
		is_equal_approx(CameraTranslation.resolve_trauma(custom_lookup, &"camera.custom"), 0.9))

	if failure_count > 0:
		push_error("%d camera-director test(s) failed." % failure_count)
		quit(1)
		return
	print("All camera-director tests passed.")
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

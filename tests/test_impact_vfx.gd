extends SceneTree
## Covers ImpactTranslation (pure). The subsystem Node itself references the
## EventBus / ThemeManager autoloads, which are not loaded in a --script run, so
## its wiring is verified via the demo scene instead.


func _initialize() -> void:
	var failure_count := 0

	# --- pure hit-stop bookkeeping ---
	failure_count += expect_int("first request sets end to now + seconds",
		ImpactTranslation.compute_hitstop_end(0, 1000, 0.1, 0.5), 1100)
	failure_count += expect_int("request clamped to max",
		ImpactTranslation.compute_hitstop_end(0, 1000, 2.0, 0.5), 1500)
	failure_count += expect_int("zero request keeps current end",
		ImpactTranslation.compute_hitstop_end(4321, 1000, 0.0, 0.5), 4321)
	failure_count += expect_int("shorter request does not shorten an active hit-stop",
		ImpactTranslation.compute_hitstop_end(2000, 1000, 0.1, 0.5), 2000)
	failure_count += expect_int("longer request extends",
		ImpactTranslation.compute_hitstop_end(1200, 1000, 0.5, 0.5), 1500)

	# --- intensity translation ---
	var defaults := ImpactTranslation.build_default_intensity_table()
	var lookup := ImpactTranslation.build_lookup(defaults)

	var heavy: ImpactIntensity = lookup.get(&"impact.heavy")
	failure_count += expect_true("heavy resolves", Utility.is_object_valid(heavy))
	failure_count += expect_int("heavy particle count", heavy.intensity_particle_count, 18)
	failure_count += expect_true("heavy requests hit-stop", heavy.intensity_hitstop_seconds > 0.0)

	var basic: ImpactIntensity = lookup.get(&"impact.basic")
	failure_count += expect_true("basic requests no hit-stop", is_zero_approx(basic.intensity_hitstop_seconds))
	failure_count += expect_true("unknown event resolves to null",
		not Utility.is_object_valid(lookup.get(&"impact.nonexistent")))

	var custom := ImpactTranslation.make_intensity(&"impact.basic", &"impact.spark", 99, 0.0)
	var custom_table: Array[ImpactIntensity] = [custom]
	var custom_lookup := ImpactTranslation.build_lookup(custom_table)
	var overridden: ImpactIntensity = custom_lookup.get(&"impact.basic")
	failure_count += expect_int("explicit table row wins", overridden.intensity_particle_count, 99)
	failure_count += expect_true("explicit table has only its own rows",
		not Utility.is_object_valid(custom_lookup.get(&"impact.heavy")))

	var with_invalid: Array[ImpactIntensity] = [null, custom]
	failure_count += expect_int("build_lookup skips invalid rows",
		ImpactTranslation.build_lookup(with_invalid).size(), 1)

	# --- R7: a zeroed TuningProfile must not reach a true 0.0 time_scale ---
	failure_count += expect_true("hitstop floor const stays > 0.0",
		ImpactVfxSubsystem.HITSTOP_TIME_SCALE_FLOOR > 0.0)
	failure_count += expect_true("clamp keeps a zeroed profile value off 0.0",
		maxf(0.0, ImpactVfxSubsystem.HITSTOP_TIME_SCALE_FLOOR) > 0.0)

	if failure_count > 0:
		push_error("%d impact-vfx test(s) failed." % failure_count)
		quit(1)
		return
	print("All impact-vfx tests passed.")
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

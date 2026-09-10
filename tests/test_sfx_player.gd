extends SceneTree
## Covers SfxTranslation (pure). Voice pooling / bus routing use the autoloads,
## verified via the demo scene / a smoke.


func _initialize() -> void:
	var failure_count := 0

	# --- pitch randomisation ---
	failure_count += expect_true("zero unit -> unity pitch",
		is_equal_approx(SfxTranslation.random_pitch_scale(2.0, 0.0), 1.0))
	failure_count += expect_true("+1 octave range at +1 unit doubles pitch",
		is_equal_approx(SfxTranslation.random_pitch_scale(12.0, 1.0), 2.0))
	failure_count += expect_true("-1 octave range at -1 unit halves pitch",
		is_equal_approx(SfxTranslation.random_pitch_scale(12.0, -1.0), 0.5))
	var pitch := SfxTranslation.random_pitch_scale(2.0, 0.5)
	failure_count += expect_true("pitch stays within the semitone band", pitch > 1.0 and pitch < 1.123)

	# --- volume randomisation ---
	failure_count += expect_true("+1 unit -> +range dB",
		is_equal_approx(SfxTranslation.random_volume_db(3.0, 1.0), 3.0))
	failure_count += expect_true("half unit scales linearly",
		is_equal_approx(SfxTranslation.random_volume_db(3.0, -0.5), -1.5))
	failure_count += expect_true("zero unit -> 0 dB",
		is_equal_approx(SfxTranslation.random_volume_db(3.0, 0.0), 0.0))

	# --- route table ---
	var lookup := SfxTranslation.build_lookup(SfxTranslation.build_default_route_table())
	var impact: SfxRoute = SfxTranslation.resolve_route(lookup, &"impact.basic")
	failure_count += expect_true("impact route resolves", Utility.is_object_valid(impact))
	failure_count += expect_true("impact route is spatialized", impact.route_spatialized)
	var hover: SfxRoute = SfxTranslation.resolve_route(lookup, &"ui.hover")
	failure_count += expect_true("ui route is not spatialized", not hover.route_spatialized)
	failure_count += expect_true("unrouted event -> null",
		not Utility.is_object_valid(SfxTranslation.resolve_route(lookup, &"impact.nonexistent")))

	var transient := SfxTranslation.make_route(&"footstep", &"sfx.step", true, 1.0, 1.0)
	transient.route_stop_on_scene_change = true
	failure_count += expect_true("transient route is cut on scene change",
		not SfxTranslation.should_keep_on_scene_change(transient))
	failure_count += expect_true("normal route plays through a scene change",
		SfxTranslation.should_keep_on_scene_change(impact))
	failure_count += expect_true("null route defaults to keep",
		SfxTranslation.should_keep_on_scene_change(null))

	var with_invalid: Array[SfxRoute] = [null, transient]
	failure_count += expect_int("build_lookup skips invalid rows",
		SfxTranslation.build_lookup(with_invalid).size(), 1)

	if failure_count > 0:
		push_error("%d sfx-player test(s) failed." % failure_count)
		quit(1)
		return
	print("All sfx-player tests passed.")
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

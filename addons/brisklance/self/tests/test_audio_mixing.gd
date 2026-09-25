extends SceneTree
## Covers AudioMixingTranslation (pure). AudioServer bus tweens / the reverb
## install use the autoload, verified via the demo scene / a smoke.


func _initialize() -> void:
	var failure_count := 0

	# --- neutral profile ---
	var neutral := AudioMixingTranslation.neutral_profile()
	failure_count += expect_true("neutral id", neutral.profile_id == &"neutral")
	failure_count += expect_true("neutral is flat and dry",
		is_zero_approx(neutral.bus_music_db) and is_zero_approx(neutral.bus_sfx_db) and is_zero_approx(neutral.reverb_wet))

	# --- make_profile ---
	var cave := AudioMixingTranslation.make_profile(&"cave", -2.0, 3.0, 1.0, 0.45, 0.8)
	failure_count += expect_true("make_profile keeps its fields",
		is_equal_approx(cave.bus_ambience_db, 3.0) and is_equal_approx(cave.reverb_room_size, 0.8))

	# --- bus targets (never includes UI) ---
	var targets := AudioMixingTranslation.bus_targets(cave)
	failure_count += expect_int("three trimmable buses", targets.size(), 3)
	failure_count += expect_true("music target carried", is_equal_approx(targets[&"Music"], -2.0))
	failure_count += expect_true("UI is never a target", not targets.has(&"UI"))
	failure_count += expect_int("null profile -> no targets", AudioMixingTranslation.bus_targets(null).size(), 0)

	# --- dry-bus rule ---
	failure_count += expect_true("UI is a dry bus", AudioMixingTranslation.is_dry_bus(&"UI"))
	failure_count += expect_true("SFX is not a dry bus", not AudioMixingTranslation.is_dry_bus(&"SFX"))

	# --- reverb clamping ---
	var loud := AudioMixingTranslation.make_profile(&"loud", 0.0, 0.0, 0.0, 1.7, -0.4)
	failure_count += expect_true("reverb wet clamps to 1.0", is_equal_approx(AudioMixingTranslation.reverb_wet_for(loud), 1.0))
	failure_count += expect_true("reverb room clamps to 0.0", is_zero_approx(AudioMixingTranslation.reverb_room_size_for(loud)))
	failure_count += expect_true("reverb wet passes through in range", is_equal_approx(AudioMixingTranslation.reverb_wet_for(cave), 0.45))
	failure_count += expect_true("null profile -> zero wet", is_zero_approx(AudioMixingTranslation.reverb_wet_for(null)))

	if failure_count > 0:
		push_error("%d audio-mixing test(s) failed." % failure_count)
		quit(1)
		return
	print("All audio-mixing tests passed.")
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

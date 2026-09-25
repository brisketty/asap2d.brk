extends SceneTree
## Covers MusicTranslation (pure). Stem players / crossfade tweens use the
## autoloads, verified via the demo scene / a smoke.

class StubThemeManager:
	extends RefCounted
	var requested: Array[StringName] = []

	func resolve_music(p_asset_id: StringName) -> AudioStream:
		requested.append(p_asset_id)
		return AudioStreamWAV.new()


func _initialize() -> void:
	var failure_count := 0

	# --- stem id derivation ---
	failure_count += expect_true("stem id is <theme>.<index>",
		MusicTranslation.stem_asset_id(&"forest", 2) == &"forest.2")

	# --- stem activation curve ---
	failure_count += expect_true("stem 0 off at zero intensity",
		is_equal_approx(MusicTranslation.stem_activation(0, 0.0, 3), 0.0))
	failure_count += expect_true("stem 0 full at max intensity",
		is_equal_approx(MusicTranslation.stem_activation(0, 1.0, 3), 1.0))
	failure_count += expect_true("half intensity of 4 -> stems 0,1 full",
		is_equal_approx(MusicTranslation.stem_activation(1, 0.5, 4), 1.0))
	failure_count += expect_true("half intensity of 4 -> stem 2 off",
		is_equal_approx(MusicTranslation.stem_activation(2, 0.5, 4), 0.0))
	failure_count += expect_true("stem 2 half-in at 0.625 intensity of 4",
		is_equal_approx(MusicTranslation.stem_activation(2, 0.625, 4), 0.5))

	# --- stem volume ---
	failure_count += expect_true("off stem sits at the floor",
		is_equal_approx(MusicTranslation.stem_volume_db(0, 0.0, 3, -40.0), -40.0))
	failure_count += expect_true("full stem sits at 0 dB",
		is_equal_approx(MusicTranslation.stem_volume_db(0, 1.0, 3, -40.0), 0.0))
	failure_count += expect_true("lower stems are never quieter than higher ones",
		MusicTranslation.stem_volume_db(0, 0.5, 4, -40.0) >= MusicTranslation.stem_volume_db(2, 0.5, 4, -40.0))

	# --- state intensity floor ---
	failure_count += expect_true("effective intensity is the louder of the two",
		is_equal_approx(MusicTranslation.effective_intensity(0.3, 0.8), 0.8))
	failure_count += expect_true("tension wins when it is higher",
		is_equal_approx(MusicTranslation.effective_intensity(0.9, 0.5), 0.9))
	failure_count += expect_true("effective intensity clamps",
		is_equal_approx(MusicTranslation.effective_intensity(1.4, -0.2), 1.0))
	var state_lookup := MusicTranslation.build_default_state_tension()
	failure_count += expect_true("low health lifts intensity more than hurt",
		MusicTranslation.state_tension(state_lookup, &"state.lowhealth") > MusicTranslation.state_tension(state_lookup, &"state.hurt"))
	failure_count += expect_true("an unmapped state imposes no floor",
		is_zero_approx(MusicTranslation.state_tension(state_lookup, &"state.paused")))

	# --- crossfade ---
	var start := MusicTranslation.crossfade_volumes(0.0, -30.0)
	failure_count += expect_true("crossfade start: old full, new floored",
		is_equal_approx(start[&"out_db"], 0.0) and is_equal_approx(start[&"in_db"], -30.0))
	var mid := MusicTranslation.crossfade_volumes(0.5, -30.0)
	failure_count += expect_true("crossfade midpoint: both at -15 dB",
		is_equal_approx(mid[&"out_db"], -15.0) and is_equal_approx(mid[&"in_db"], -15.0))
	var done := MusicTranslation.crossfade_volumes(1.0, -30.0)
	failure_count += expect_true("crossfade end: old floored, new full",
		is_equal_approx(done[&"out_db"], -30.0) and is_equal_approx(done[&"in_db"], 0.0))

	# --- stem stream resolution ---
	var stub := StubThemeManager.new()
	var streams := MusicTranslation.resolve_stem_streams(stub, &"cave", 3)
	failure_count += expect_int("one stream per stem", streams.size(), 3)
	failure_count += expect_true("resolves <theme>.0.. in order",
		stub.requested == ([&"cave.0", &"cave.1", &"cave.2"] as Array[StringName]))
	failure_count += expect_true("invalid theme manager -> no streams",
		MusicTranslation.resolve_stem_streams(null, &"cave", 3).is_empty())

	if failure_count > 0:
		push_error("%d music-director test(s) failed." % failure_count)
		quit(1)
		return
	print("All music-director tests passed.")
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

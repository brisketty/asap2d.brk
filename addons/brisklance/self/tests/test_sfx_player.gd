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

	# --- camera effect routes (momentary, same treatment as impact) ---
	var shake_route: SfxRoute = SfxTranslation.resolve_route(lookup, &"camera.shake")
	failure_count += expect_true("camera.shake route resolves", Utility.is_object_valid(shake_route))
	var zoom_route: SfxRoute = SfxTranslation.resolve_route(lookup, &"camera.zoom")
	failure_count += expect_true("camera.zoom route resolves", Utility.is_object_valid(zoom_route))

	# --- variation picking ---
	var ids: Array[StringName] = [&"a", &"b", &"c"]
	failure_count += expect_true("empty ids -> fallback",
		SfxTranslation.pick_variation_id([], &"fallback", 0.5) == &"fallback")
	failure_count += expect_true("unit 0.0 -> first id",
		SfxTranslation.pick_variation_id(ids, &"fallback", 0.0) == &"a")
	failure_count += expect_true("unit near 1.0 -> last id",
		SfxTranslation.pick_variation_id(ids, &"fallback", 0.999) == &"c")

	# --- state sfx table ---
	var state_lookup := SfxTranslation.build_state_sfx_lookup(SfxTranslation.build_default_state_sfx_table())
	var hurt_sfx: StateSfxSet = SfxTranslation.resolve_state_sfx(state_lookup, &"state.hurt")
	failure_count += expect_true("state.hurt row exists by default", Utility.is_object_valid(hurt_sfx))
	failure_count += expect_true("default state sfx starts silent (opt-in)",
		hurt_sfx.enter_audio_variation_ids.is_empty() and hurt_sfx.loop_audio_variation_ids.is_empty())
	failure_count += expect_true("unmapped state -> null",
		not Utility.is_object_valid(SfxTranslation.resolve_state_sfx(state_lookup, &"state.nonexistent")))

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

extends SceneTree
## Covers TuningProfile defaults and Tuning's profile-swap bookkeeping. `_ready()`'s
## profile_available -> active_profile fallback needs a live scene tree (it
## never fires under `--script` - see STATE.md H1), so it's verified via the
## demo scenes instead.

const TuningScript := preload("res://autoloads/tuning.gd")


func _initialize() -> void:
	var failure_count := 0

	var defaults := TuningProfile.new()
	failure_count += expect_true("default profile_id is 'default'", defaults.profile_id == &"default")
	failure_count += expect_true("camera_zoom_tween_seconds default",
		is_equal_approx(defaults.camera_zoom_tween_seconds, 0.35))
	failure_count += expect_true("camera_focus_tween_seconds default",
		is_equal_approx(defaults.camera_focus_tween_seconds, 0.5))
	failure_count += expect_true("camera_post_fx_fade_seconds default",
		is_equal_approx(defaults.camera_post_fx_fade_seconds, 0.4))
	failure_count += expect_true("vfx_hitstop_time_scale default",
		is_equal_approx(defaults.vfx_hitstop_time_scale, 0.0001))
	failure_count += expect_true("audio_mix_tween_seconds default",
		is_equal_approx(defaults.audio_mix_tween_seconds, 1.5))
	failure_count += expect_true("ui_pop_seconds default",
		is_equal_approx(defaults.ui_pop_seconds, 0.22))
	failure_count += expect_true("camera_shake_intensity_scale default",
		is_equal_approx(defaults.camera_shake_intensity_scale, 1.0))
	failure_count += expect_true("audio_spatial_max_distance default",
		is_equal_approx(defaults.audio_spatial_max_distance, 2000.0))
	failure_count += expect_true("audio_music_crossfade_seconds default",
		is_equal_approx(defaults.audio_music_crossfade_seconds, 2.0))
	failure_count += expect_true("vfx_knockback_strength default",
		is_equal_approx(defaults.vfx_knockback_strength, 1.0))

	var manager: Node = TuningScript.new()
	var changed_ids: Array[StringName] = []
	manager.active_profile_changed.connect(func(p_id: StringName) -> void: changed_ids.append(p_id))

	var fast := TuningProfile.new()
	fast.profile_id = &"fast"
	fast.camera_zoom_tween_seconds = 0.1
	var available: Array[TuningProfile] = [fast]
	manager.profile_available = available

	manager.set_active_profile_by_id(&"fast")
	failure_count += expect_true("known id swaps active_profile", manager.active_profile == fast)
	failure_count += expect_true("profile-changed signal fired", changed_ids == ([&"fast"] as Array[StringName]))

	manager.set_active_profile_by_id(&"nope")
	failure_count += expect_true("unknown id leaves active_profile unchanged", manager.active_profile == fast)

	manager.free()

	if failure_count > 0:
		push_error("%d tuning test(s) failed." % failure_count)
		quit(1)
		return
	print("All tuning tests passed.")
	quit(0)


func expect_true(p_label: String, p_actual: bool) -> int:
	if p_actual:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s" % p_label)
	return 1

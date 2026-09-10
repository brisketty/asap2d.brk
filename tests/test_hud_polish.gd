extends SceneTree
## Covers HudTranslation (pure). Floating-text pooling / catch-up-bar rendering
## use the EventBus / autoloads, verified via the demo scene / a smoke.


func _initialize() -> void:
	var failure_count := 0

	# --- damage number formatting ---
	failure_count += expect_str("damage rounds down", HudTranslation.damage_text(12.4, &"damage.dealt"), "12")
	failure_count += expect_str("damage rounds up", HudTranslation.damage_text(4.6, &"damage.dealt"), "5")
	failure_count += expect_str("heal is signed", HudTranslation.damage_text(5.0, &"damage.healed"), "+5")
	failure_count += expect_str("negative magnitude is absolute", HudTranslation.damage_text(-9.0, &"damage.dealt"), "9")

	# --- colour tiers ---
	failure_count += expect_true("light hit -> light colour",
		HudTranslation.damage_color(5.0, &"damage.dealt") == HudTranslation.COLOR_LIGHT)
	failure_count += expect_true("mid hit -> heavy colour",
		HudTranslation.damage_color(15.0, &"damage.dealt") == HudTranslation.COLOR_HEAVY)
	failure_count += expect_true("big hit -> severe colour",
		HudTranslation.damage_color(40.0, &"damage.dealt") == HudTranslation.COLOR_SEVERE)
	failure_count += expect_true("heal -> heal colour, ignoring magnitude",
		HudTranslation.damage_color(40.0, &"damage.healed") == HudTranslation.COLOR_HEAL)

	# --- catch-up lerp step ---
	failure_count += expect_true("steps toward target by speed*delta",
		is_equal_approx(HudTranslation.catch_up_step(0.5, 1.0, 2.0, 0.1), 0.7))
	failure_count += expect_true("snaps when within one step",
		is_equal_approx(HudTranslation.catch_up_step(0.9, 1.0, 2.0, 0.1), 1.0))
	failure_count += expect_true("steps downward too",
		is_equal_approx(HudTranslation.catch_up_step(1.0, 0.5, 2.0, 0.1), 0.8))
	failure_count += expect_true("large step lands exactly on target",
		is_equal_approx(HudTranslation.catch_up_step(1.0, 0.3, 10.0, 0.1), 0.3))
	failure_count += expect_true("already at target is a no-op",
		is_equal_approx(HudTranslation.catch_up_step(0.42, 0.42, 5.0, 0.1), 0.42))

	failure_count += expect_true("is_heal true for damage.healed", HudTranslation.is_heal(&"damage.healed"))
	failure_count += expect_true("is_heal false for damage.dealt", not HudTranslation.is_heal(&"damage.dealt"))

	if failure_count > 0:
		push_error("%d hud-polish test(s) failed." % failure_count)
		quit(1)
		return
	print("All hud-polish tests passed.")
	quit(0)


func expect_str(p_label: String, p_actual: String, p_expected: String) -> int:
	if p_actual == p_expected:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s (expected '%s', got '%s')" % [p_label, p_expected, p_actual])
	return 1


func expect_true(p_label: String, p_actual: bool) -> int:
	if p_actual:
		print("  ok: %s" % p_label)
		return 0
	push_error("  FAIL: %s" % p_label)
	return 1

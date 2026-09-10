extends SceneTree
## Covers WorldTranslation (pure). The subsystem Node references the EventBus /
## ThemeManager autoloads, which are absent in a --script run, so its wiring is
## verified via the demo scene instead.

class StubThemeManager:
	extends RefCounted
	var resolved: Array[StringName] = []

	func resolve_sprite(p_asset_id: StringName) -> Texture2D:
		resolved.append(p_asset_id)
		var texture := PlaceholderTexture2D.new()
		texture.size = Vector2(float(resolved.size()), 1.0)
		return texture


func _initialize() -> void:
	var failure_count := 0

	# --- scroll-scale distribution ---
	failure_count += expect_true("zero layers -> empty",
		WorldTranslation.build_scroll_scales(0, 0.2, 1.0).is_empty())

	var one := WorldTranslation.build_scroll_scales(1, 0.2, 1.0)
	failure_count += expect_int("one layer -> single entry", one.size(), 1)
	failure_count += expect_true("one layer scrolls at max", is_equal_approx(one[0], 1.0))

	var three := WorldTranslation.build_scroll_scales(3, 0.2, 1.0)
	failure_count += expect_int("three layers -> three scales", three.size(), 3)
	failure_count += expect_true("far layer at min", is_equal_approx(three[0], 0.2))
	failure_count += expect_true("near layer at max", is_equal_approx(three[2], 1.0))
	failure_count += expect_true("mid layer interpolated", is_equal_approx(three[1], 0.6))
	failure_count += expect_true("scales strictly increasing", three[0] < three[1] and three[1] < three[2])

	# --- layer texture resolution ---
	var stub := StubThemeManager.new()
	var ids := PackedStringArray(["world.parallax.far", "world.parallax.mid", "world.parallax.near"])
	var textures := WorldTranslation.resolve_layer_textures(stub, ids)
	failure_count += expect_int("one texture per id", textures.size(), 3)
	failure_count += expect_true("resolution order preserved",
		stub.resolved == ([&"world.parallax.far", &"world.parallax.mid", &"world.parallax.near"] as Array[StringName]))
	failure_count += expect_true("no null textures", Utility.is_object_valid(textures[0]) and Utility.is_object_valid(textures[2]))
	failure_count += expect_true("invalid theme manager -> empty",
		WorldTranslation.resolve_layer_textures(null, ids).is_empty())

	# --- profile switch decision ---
	failure_count += expect_true("switch to a different biome", WorldTranslation.should_switch_profile(&"forest", &"cave"))
	failure_count += expect_true("no switch to the same biome", not WorldTranslation.should_switch_profile(&"cave", &"cave"))
	failure_count += expect_true("no switch on empty biome id", not WorldTranslation.should_switch_profile(&"cave", &""))

	if failure_count > 0:
		push_error("%d world-environment test(s) failed." % failure_count)
		quit(1)
		return
	print("All world-environment tests passed.")
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

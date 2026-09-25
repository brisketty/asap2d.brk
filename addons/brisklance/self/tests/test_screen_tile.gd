extends SceneTree
## Covers ScreenTileTranslation (pure). The Node wrapper (ScreenTileBorder)
## references the viewport / builds Sprite2D children, verified via the demo
## scene instead (per STATE.md gotcha H1).


func _initialize() -> void:
	var failure_count := 0

	# --- border-cell coverage ---
	failure_count += expect_int("non-positive thickness -> no tiles",
		ScreenTileTranslation.compute_border_tile_positions(Vector2(256, 256), Vector2i(64, 64), 0).size(), 0)
	failure_count += expect_int("zero tile axis -> no tiles",
		ScreenTileTranslation.compute_border_tile_positions(Vector2(256, 256), Vector2i(0, 64), 1).size(), 0)

	# 256x256 viewport, 64x64 tiles -> a 4x4 grid; a 1-tile border covers every
	# cell except the 2x2 interior -> 16 - 4 = 12 tiles.
	var border := ScreenTileTranslation.compute_border_tile_positions(Vector2(256, 256), Vector2i(64, 64), 1)
	failure_count += expect_int("1-tile border on a 4x4 grid", border.size(), 12)
	failure_count += expect_true("top-left corner included", border.has(Vector2(0, 0)))
	failure_count += expect_true("bottom-right corner included", border.has(Vector2(192, 192)))
	failure_count += expect_true("interior cell excluded", not border.has(Vector2(64, 64)))

	# A thickness covering the whole grid -> every cell, no gaps.
	var full := ScreenTileTranslation.compute_border_tile_positions(Vector2(128, 128), Vector2i(64, 64), 2)
	failure_count += expect_int("thickness >= half the grid -> full coverage", full.size(), 4)

	# --- variation picking ---
	failure_count += expect_int("no variations -> -1", ScreenTileTranslation.pick_variation_index(0, 0.5), -1)
	failure_count += expect_int("unit 0.0 -> first variation", ScreenTileTranslation.pick_variation_index(3, 0.0), 0)
	failure_count += expect_int("unit near 1.0 -> last variation", ScreenTileTranslation.pick_variation_index(3, 0.999), 2)
	failure_count += expect_int("mid unit -> mid variation", ScreenTileTranslation.pick_variation_index(3, 0.5), 1)
	failure_count += expect_int("out-of-range unit clamps low", ScreenTileTranslation.pick_variation_index(3, -1.0), 0)
	failure_count += expect_int("out-of-range unit clamps high", ScreenTileTranslation.pick_variation_index(3, 5.0), 2)

	if failure_count > 0:
		push_error("%d screen-tile test(s) failed." % failure_count)
		quit(1)
		return
	print("All screen-tile tests passed.")
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

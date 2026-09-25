extends SceneTree
## Covers TilemapDecoratorTranslation (pure). The Node wrapper
## (TileMapDecorator) references TileMapLayer nodes and the editor tree,
## verified via manual editor use instead (per STATE.md gotcha H1).


func _initialize() -> void:
	var failure_count := 0

	# --- edge classification: a single isolated cell -> every edge true ---
	var isolated: Dictionary = {Vector2i(0, 0): true}
	failure_count += expect_true("isolated cell: top edge", TilemapDecoratorTranslation.is_top_edge(isolated, Vector2i(0, 0)))
	failure_count += expect_true("isolated cell: bottom edge", TilemapDecoratorTranslation.is_bottom_edge(isolated, Vector2i(0, 0)))
	failure_count += expect_true("isolated cell: left edge", TilemapDecoratorTranslation.is_left_edge(isolated, Vector2i(0, 0)))
	failure_count += expect_true("isolated cell: right edge", TilemapDecoratorTranslation.is_right_edge(isolated, Vector2i(0, 0)))
	failure_count += expect_true("isolated cell: not interior", not TilemapDecoratorTranslation.is_interior(isolated, Vector2i(0, 0)))

	# --- edge classification: a 3x3 block ---
	var block: Dictionary = {}
	for x: int in range(3):
		for y: int in range(3):
			block[Vector2i(x, y)] = true
	failure_count += expect_true("3x3 block center: interior", TilemapDecoratorTranslation.is_interior(block, Vector2i(1, 1)))
	failure_count += expect_true("3x3 block center: no top edge", not TilemapDecoratorTranslation.is_top_edge(block, Vector2i(1, 1)))
	failure_count += expect_true("3x3 block top-left: top edge", TilemapDecoratorTranslation.is_top_edge(block, Vector2i(0, 0)))
	failure_count += expect_true("3x3 block top-left: left edge", TilemapDecoratorTranslation.is_left_edge(block, Vector2i(0, 0)))
	failure_count += expect_true("3x3 block top-left: not bottom edge", not TilemapDecoratorTranslation.is_bottom_edge(block, Vector2i(0, 0)))
	failure_count += expect_true("3x3 block top-left: not right edge", not TilemapDecoratorTranslation.is_right_edge(block, Vector2i(0, 0)))
	failure_count += expect_true("3x3 block top-left: not interior", not TilemapDecoratorTranslation.is_interior(block, Vector2i(0, 0)))

	# --- outside-cell offsets: decorations frame the region from outside ---
	failure_count += expect_true("top outside cell is one row above",
		TilemapDecoratorTranslation.top_outside_cell(Vector2i(3, 3)) == Vector2i(3, 2))
	failure_count += expect_true("bottom outside cell is one row below",
		TilemapDecoratorTranslation.bottom_outside_cell(Vector2i(3, 3)) == Vector2i(3, 4))
	failure_count += expect_true("left outside cell is one column left",
		TilemapDecoratorTranslation.left_outside_cell(Vector2i(3, 3)) == Vector2i(2, 3))
	failure_count += expect_true("right outside cell is one column right",
		TilemapDecoratorTranslation.right_outside_cell(Vector2i(3, 3)) == Vector2i(4, 3))

	# --- weighted picking ---
	var empty_weights: Array[float] = []
	failure_count += expect_int("no options -> -1", TilemapDecoratorTranslation.pick_weighted_index(empty_weights, 0.5), -1)

	var zero_weights: Array[float] = [0.0, 0.0]
	failure_count += expect_int("all-zero weights -> -1", TilemapDecoratorTranslation.pick_weighted_index(zero_weights, 0.5), -1)

	var single_weight: Array[float] = [1.0]
	failure_count += expect_int("single option -> always 0 (low unit)", TilemapDecoratorTranslation.pick_weighted_index(single_weight, 0.0), 0)
	failure_count += expect_int("single option -> always 0 (high unit)", TilemapDecoratorTranslation.pick_weighted_index(single_weight, 0.999), 0)

	var uneven_weights: Array[float] = [1.0, 3.0]
	failure_count += expect_int("uneven weights: low unit -> first bucket", TilemapDecoratorTranslation.pick_weighted_index(uneven_weights, 0.0), 0)
	failure_count += expect_int("uneven weights: just past first bucket -> second", TilemapDecoratorTranslation.pick_weighted_index(uneven_weights, 0.26), 1)
	failure_count += expect_int("uneven weights: high unit -> second bucket", TilemapDecoratorTranslation.pick_weighted_index(uneven_weights, 0.999), 1)

	# --- tile candidate enumeration ---
	failure_count += expect_int("null tileset -> no candidates",
		TilemapDecoratorTranslation.collect_tile_candidates(null).size(), 0)

	var empty_tileset := TileSet.new()
	failure_count += expect_int("empty tileset -> no candidates",
		TilemapDecoratorTranslation.collect_tile_candidates(empty_tileset).size(), 0)

	var tileset := TileSet.new()
	var source := TileSetAtlasSource.new()
	var image := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(64, 64)
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))
	source.get_tile_data(Vector2i(0, 0), 0).probability = 0.7
	source.get_tile_data(Vector2i(1, 0), 0).probability = 0.3
	tileset.add_source(source, 0)

	var candidates := TilemapDecoratorTranslation.collect_tile_candidates(tileset)
	failure_count += expect_int("2-tile tileset -> 2 candidates", candidates.size(), 2)
	failure_count += expect_true("first candidate is source 0 at (0,0)",
		candidates[0]["source_id"] == 0 and candidates[0]["atlas_coords"] == Vector2i(0, 0))
	failure_count += expect_true("first candidate keeps its probability",
		is_equal_approx(candidates[0]["probability"] as float, 0.7))
	failure_count += expect_true("second candidate keeps its probability",
		is_equal_approx(candidates[1]["probability"] as float, 0.3))

	var weights := TilemapDecoratorTranslation.candidate_weights(candidates)
	failure_count += expect_int("candidate_weights: low unit -> first candidate",
		TilemapDecoratorTranslation.pick_weighted_index(weights, 0.0), 0)
	failure_count += expect_int("candidate_weights: high unit -> second candidate",
		TilemapDecoratorTranslation.pick_weighted_index(weights, 0.999), 1)

	# --- sparseness ---
	failure_count += expect_true("sparseness 0 -> never skip (low unit)",
		not TilemapDecoratorTranslation.should_skip_for_sparseness(0.0, 0.0))
	failure_count += expect_true("sparseness 0 -> never skip (high unit)",
		not TilemapDecoratorTranslation.should_skip_for_sparseness(0.0, 0.999))
	failure_count += expect_true("sparseness 1 -> always skip (low unit)",
		TilemapDecoratorTranslation.should_skip_for_sparseness(1.0, 0.0))
	failure_count += expect_true("sparseness 1 -> always skip (high unit, still < 1)",
		TilemapDecoratorTranslation.should_skip_for_sparseness(1.0, 0.999))
	failure_count += expect_true("sparseness 0.3: unit below threshold skips",
		TilemapDecoratorTranslation.should_skip_for_sparseness(0.3, 0.1))
	failure_count += expect_true("sparseness 0.3: unit above threshold fills",
		not TilemapDecoratorTranslation.should_skip_for_sparseness(0.3, 0.5))
	failure_count += expect_true("out-of-range sparseness clamps high",
		TilemapDecoratorTranslation.should_skip_for_sparseness(5.0, 0.999))
	failure_count += expect_true("out-of-range sparseness clamps low",
		not TilemapDecoratorTranslation.should_skip_for_sparseness(-5.0, 0.0))

	if failure_count > 0:
		push_error("%d tilemap-decorator test(s) failed." % failure_count)
		quit(1)
		return
	print("All tilemap-decorator tests passed.")
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

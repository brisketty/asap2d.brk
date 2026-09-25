class_name TilemapDecoratorTranslation
## Pure logic for the TileMap Decorator: edge classification of a painted
## region mask, weighted picks, and TileSet candidate enumeration. Touches
## only Resource-level engine types (TileSet/TileSetAtlasSource/TileData),
## never autoloads or the scene tree, so it is still unit-tested headless
## (STATE.md gotcha H1).

## True when p_cell is present in p_mask (a Dictionary[Vector2i, bool] built
## from a TileMapLayer's get_used_cells()).
static func has_cell(p_mask: Dictionary, p_cell: Vector2i) -> bool:
	return p_mask.has(p_cell)


## Four-directional (N/S/E/W) edge classification against p_mask. Callers
## only classify cells that are themselves in p_mask.
static func is_top_edge(p_mask: Dictionary, p_cell: Vector2i) -> bool:
	return not has_cell(p_mask, p_cell + Vector2i(0, -1))


static func is_bottom_edge(p_mask: Dictionary, p_cell: Vector2i) -> bool:
	return not has_cell(p_mask, p_cell + Vector2i(0, 1))


static func is_left_edge(p_mask: Dictionary, p_cell: Vector2i) -> bool:
	return not has_cell(p_mask, p_cell + Vector2i(-1, 0))


static func is_right_edge(p_mask: Dictionary, p_cell: Vector2i) -> bool:
	return not has_cell(p_mask, p_cell + Vector2i(1, 0))


## The cell just outside p_cell on the given side - where that side's edge
## decoration is painted, framing the region from outside rather than
## sitting on the boundary cell itself (a cliff-top tuft belongs above the
## cliff, not on its last inch of ground).
static func top_outside_cell(p_cell: Vector2i) -> Vector2i:
	return p_cell + Vector2i(0, -1)


static func bottom_outside_cell(p_cell: Vector2i) -> Vector2i:
	return p_cell + Vector2i(0, 1)


static func left_outside_cell(p_cell: Vector2i) -> Vector2i:
	return p_cell + Vector2i(-1, 0)


static func right_outside_cell(p_cell: Vector2i) -> Vector2i:
	return p_cell + Vector2i(1, 0)


## True when all 4 neighbors are present (none of the 4 edge checks trip).
static func is_interior(p_mask: Dictionary, p_cell: Vector2i) -> bool:
	return (
		not is_top_edge(p_mask, p_cell)
		and not is_bottom_edge(p_mask, p_cell)
		and not is_left_edge(p_mask, p_cell)
		and not is_right_edge(p_mask, p_cell)
	)


## Cumulative-weight pick over p_weights given a p_unit draw in [0, 1).
## -1 when p_weights is empty or every weight is non-positive.
static func pick_weighted_index(p_weights: Array[float], p_unit: float) -> int:
	var total := 0.0
	for weight: float in p_weights:
		total += maxf(weight, 0.0)
	if total <= 0.0:
		return -1
	var target := clampf(p_unit, 0.0, 0.999999) * total
	var cumulative := 0.0
	for index: int in p_weights.size():
		cumulative += maxf(p_weights[index], 0.0)
		if target < cumulative:
			return index
	return p_weights.size() - 1


## Every (source_id, atlas_coords, alternative_id, probability) tile in
## p_tileset, flattened for weighted picking - reuses each tile's own
## `TileData.probability` ("Scattering" in the Tile inspector) as its pick
## weight instead of a separate authored weight. TileSetScenesCollectionSource
## entries are skipped (no TileData/probability there); null/invalid
## p_tileset yields no candidates.
static func collect_tile_candidates(p_tileset: TileSet) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if not Utility.is_object_valid(p_tileset):
		return candidates
	for source_index: int in p_tileset.get_source_count():
		var source_id := p_tileset.get_source_id(source_index)
		var atlas_source := p_tileset.get_source(source_id) as TileSetAtlasSource
		if not Utility.is_object_valid(atlas_source):
			continue
		for tile_index: int in atlas_source.get_tiles_count():
			var atlas_coords := atlas_source.get_tile_id(tile_index)
			for alternative_index: int in atlas_source.get_alternative_tiles_count(atlas_coords):
				var alternative_id := atlas_source.get_alternative_tile_id(atlas_coords, alternative_index)
				var tile_data := atlas_source.get_tile_data(atlas_coords, alternative_id)
				if not Utility.is_object_valid(tile_data):
					continue
				candidates.append({
					"source_id": source_id,
					"atlas_coords": atlas_coords,
					"alternative_id": alternative_id,
					"probability": tile_data.probability,
				})
	return candidates


## p_candidates' `probability` values, in order - pair with
## pick_weighted_index to pick one of p_candidates.
static func candidate_weights(p_candidates: Array[Dictionary]) -> Array[float]:
	var weights: Array[float] = []
	for candidate: Dictionary in p_candidates:
		weights.append(candidate["probability"] as float)
	return weights


## True when a cell should be left empty for this generation pass, given a
## p_unit draw in [0, 1) and a per-layer p_sparseness in [0, 1] (0 = always
## fill, 1 = never fill). Kept independent of tile-weight math on purpose -
## which tile gets picked (candidate_weights/pick_weighted_index, relative,
## self-normalizing) and whether a tile gets picked at all (this, one flat
## per-layer knob) are two separate questions; an author tuning per-tile
## probabilities never has to also account for a target sum.
static func should_skip_for_sparseness(p_sparseness: float, p_unit: float) -> bool:
	return p_unit < clampf(p_sparseness, 0.0, 1.0)

class_name ScreenTileTranslation
## Pure logic for the screen-tile border overlay: which tile-corner positions
## cover the four screen edges, and which variation a tile at a given random
## draw should use. No engine state, so it is unit-tested headless.


## Top-left corner of every tile in the `border_thickness_tiles`-deep strip
## around all four edges of a `p_viewport_size` grid of `p_tile_size` cells.
## The interior is skipped; corner tiles are never duplicated. A non-positive
## thickness or a zero/negative tile axis yields an empty border (no tiles).
static func compute_border_tile_positions(
	p_viewport_size: Vector2,
	p_tile_size: Vector2i,
	p_thickness_tiles: int,
) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if p_thickness_tiles <= 0 or p_tile_size.x <= 0 or p_tile_size.y <= 0:
		return positions
	var columns := int(ceil(p_viewport_size.x / float(p_tile_size.x)))
	var rows := int(ceil(p_viewport_size.y / float(p_tile_size.y)))
	for row: int in rows:
		for column: int in columns:
			if not is_border_cell(row, column, rows, columns, p_thickness_tiles):
				continue
			positions.append(Vector2(column * p_tile_size.x, row * p_tile_size.y))
	return positions


static func is_border_cell(p_row: int, p_column: int, p_rows: int, p_columns: int, p_thickness_tiles: int) -> bool:
	return (
		p_row < p_thickness_tiles
		or p_row >= p_rows - p_thickness_tiles
		or p_column < p_thickness_tiles
		or p_column >= p_columns - p_thickness_tiles
	)


## Deterministic pick from a variation count given a `p_unit` draw in [0, 1).
## -1 when there is nothing to pick from.
static func pick_variation_index(p_variation_count: int, p_unit: float) -> int:
	if p_variation_count <= 0:
		return -1
	return clampi(int(floor(clampf(p_unit, 0.0, 0.999999) * p_variation_count)), 0, p_variation_count - 1)

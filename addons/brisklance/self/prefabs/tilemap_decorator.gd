@tool
class_name TileMapDecorator
extends Node2D
## Mask & override workflow for procedural TileMapLayer decoration, expanded
## past the original 11-layer spec to 19: Top/Bottom/Left/Right each get
## their own Gen_*/Overrider pair (rather than one shared Horizontal/Vertical
## pair) since a TileMapLayer can only paint from one `tile_set` - distinct
## per-edge art needs a distinct layer, not just a distinct tile pool.
## Paint the region on node_region_definition and (optionally) manual
## overrides on the 8 edge *_overrider layers + node_cover_overrider. Assign
## each category's TileSet once via the `tileset_*` exports (every tile in
## it is a candidate, weighted by that tile's own `probability` - no
## separate ruleset resource); each Gen_* layer also gets its own
## `sparseness_*` knob (0..1) controlling how often a cell is left empty,
## independent of which tile gets picked among the candidates. Then use the
## inspector buttons: "Prepare Layers" creates any missing child
## TileMapLayers with correct z_index stacking and copies each populated
## `tileset_*` export onto its category's Gen_/Overrider pair (and
## `tileset_region_definition` onto node_region_definition); "Generate
## Decorations" clears and rebuilds the 9 Gen_* layers, skipping any cell a
## matching overrider already covers. The 8 edge categories frame the region
## from *outside* - a top-edge tile is written one cell above the region's
## top row, not on the top row itself (a cliff-top tuft belongs above the
## cliff) - while Cover fills the region's own surface. Re-running
## generation never touches node_region_definition or the overrider layers -
## only the Gen_* layers are cleared and rewritten.

## {property: node_<x> export name, name: created node name (always
## PascalCase, no spaces/underscores), z_index: stacking order (STATE.md R10
## - explicit layer, not tree-order dependent, so this prefab's layers
## interleave correctly around an external Main Terrain TileMapLayer that is
## not one of this prefab's children), visible: initial visibility on
## creation}. RegionDefinition defaults visible - it's the basis every other
## layer is generated from, so it needs to be seen while painting it.
const LAYER_SPECS: Array[Dictionary] = [
	{"property": "node_region_definition", "name": "RegionDefinition", "z_index": 0, "visible": true},
	{"property": "node_gen_back_top", "name": "GenBackTop", "z_index": -9, "visible": true},
	{"property": "node_gen_back_bottom", "name": "GenBackBottom", "z_index": -8, "visible": true},
	{"property": "node_gen_back_left", "name": "GenBackLeft", "z_index": -7, "visible": true},
	{"property": "node_gen_back_right", "name": "GenBackRight", "z_index": -6, "visible": true},
	{"property": "node_back_top_overrider", "name": "BackTopOverrider", "z_index": -5, "visible": true},
	{"property": "node_back_bottom_overrider", "name": "BackBottomOverrider", "z_index": -4, "visible": true},
	{"property": "node_back_left_overrider", "name": "BackLeftOverrider", "z_index": -3, "visible": true},
	{"property": "node_back_right_overrider", "name": "BackRightOverrider", "z_index": -2, "visible": true},
	{"property": "node_gen_front_top", "name": "GenFrontTop", "z_index": 1, "visible": true},
	{"property": "node_gen_front_bottom", "name": "GenFrontBottom", "z_index": 2, "visible": true},
	{"property": "node_gen_front_left", "name": "GenFrontLeft", "z_index": 3, "visible": true},
	{"property": "node_gen_front_right", "name": "GenFrontRight", "z_index": 4, "visible": true},
	{"property": "node_front_top_overrider", "name": "FrontTopOverrider", "z_index": 5, "visible": true},
	{"property": "node_front_bottom_overrider", "name": "FrontBottomOverrider", "z_index": 6, "visible": true},
	{"property": "node_front_left_overrider", "name": "FrontLeftOverrider", "z_index": 7, "visible": true},
	{"property": "node_front_right_overrider", "name": "FrontRightOverrider", "z_index": 8, "visible": true},
	{"property": "node_gen_cover", "name": "GenCover", "z_index": 9, "visible": true},
	{"property": "node_cover_overrider", "name": "CoverOverrider", "z_index": 10, "visible": true},
]

## {tileset_property: tileset_<x> export name, targets: the node_<x> export
## names "Prepare Layers" copies that tileset into - a category's Gen_ layer
## and its *_overrider layer, kept in sync so an override paints from the
## same tile vocabulary generation does. RegionDefinition has no Gen_/
## Overrider pair - just itself, since its tileset is only ever a paint
## mask, never generated from}.
const TILESET_ASSIGNMENTS: Array[Dictionary] = [
	{"tileset_property": "tileset_region_definition", "targets": ["node_region_definition"]},
	{"tileset_property": "tileset_back_top", "targets": ["node_gen_back_top", "node_back_top_overrider"]},
	{"tileset_property": "tileset_back_bottom", "targets": ["node_gen_back_bottom", "node_back_bottom_overrider"]},
	{"tileset_property": "tileset_back_left", "targets": ["node_gen_back_left", "node_back_left_overrider"]},
	{"tileset_property": "tileset_back_right", "targets": ["node_gen_back_right", "node_back_right_overrider"]},
	{"tileset_property": "tileset_front_top", "targets": ["node_gen_front_top", "node_front_top_overrider"]},
	{"tileset_property": "tileset_front_bottom", "targets": ["node_gen_front_bottom", "node_front_bottom_overrider"]},
	{"tileset_property": "tileset_front_left", "targets": ["node_gen_front_left", "node_front_left_overrider"]},
	{"tileset_property": "tileset_front_right", "targets": ["node_gen_front_right", "node_front_right_overrider"]},
	{"tileset_property": "tileset_cover", "targets": ["node_gen_cover", "node_cover_overrider"]},
]

@export_group("Nodes", "node_")
@export var node_region_definition: TileMapLayer
@export var node_back_top_overrider: TileMapLayer
@export var node_back_bottom_overrider: TileMapLayer
@export var node_back_left_overrider: TileMapLayer
@export var node_back_right_overrider: TileMapLayer
@export var node_front_top_overrider: TileMapLayer
@export var node_front_bottom_overrider: TileMapLayer
@export var node_front_left_overrider: TileMapLayer
@export var node_front_right_overrider: TileMapLayer
@export var node_cover_overrider: TileMapLayer
@export var node_gen_back_top: TileMapLayer
@export var node_gen_back_bottom: TileMapLayer
@export var node_gen_back_left: TileMapLayer
@export var node_gen_back_right: TileMapLayer
@export var node_gen_front_top: TileMapLayer
@export var node_gen_front_bottom: TileMapLayer
@export var node_gen_front_left: TileMapLayer
@export var node_gen_front_right: TileMapLayer
@export var node_gen_cover: TileMapLayer

## One TileSet per generation category, plus one for RegionDefinition's paint
## mask. "Prepare Layers" assigns each of these onto its matching layer(s)'
## own `tile_set` (STATE.md R1-adjacent convenience - a category's Gen_*
## layer and its *_overrider layer must share a tile_set for an override to
## use the same tile vocabulary as generation), so you only pick a tileset
## here once instead of dragging it onto each TileMapLayer node by hand.
## Leave a slot empty to assign that layer's tile_set manually instead -
## Prepare Layers never touches a layer whose export is unset.
@export_group("Tilesets", "tileset_")
@export var tileset_region_definition: TileSet
@export var tileset_back_top: TileSet
@export var tileset_back_bottom: TileSet
@export var tileset_back_left: TileSet
@export var tileset_back_right: TileSet
@export var tileset_front_top: TileSet
@export var tileset_front_bottom: TileSet
@export var tileset_front_left: TileSet
@export var tileset_front_right: TileSet
@export var tileset_cover: TileSet

## Chance (0 = always fill, 1 = never fill) that a given Gen_* layer's cell is
## left empty this generation pass - independent of which tile gets picked
## among a layer's own tile_set candidates (that's each tile's own
## `probability`/"Scattering", a relative weight that self-normalizes with no
## sum to tune). Defaults to 0 (always fill), matching pre-sparseness behavior.
@export_group("Sparseness", "sparseness_")
@export_range(0.0, 1.0, 0.01) var sparseness_back_top: float = 0.0
@export_range(0.0, 1.0, 0.01) var sparseness_back_bottom: float = 0.0
@export_range(0.0, 1.0, 0.01) var sparseness_back_left: float = 0.0
@export_range(0.0, 1.0, 0.01) var sparseness_back_right: float = 0.0
@export_range(0.0, 1.0, 0.01) var sparseness_front_top: float = 0.0
@export_range(0.0, 1.0, 0.01) var sparseness_front_bottom: float = 0.0
@export_range(0.0, 1.0, 0.01) var sparseness_front_left: float = 0.0
@export_range(0.0, 1.0, 0.01) var sparseness_front_right: float = 0.0
@export_range(0.0, 1.0, 0.01) var sparseness_cover: float = 0.0

@export_group("Generation", "generation_")
## 0 draws a fresh RNG seed each run (non-deterministic); any other value
## reproduces the same generated layout every time.
@export var generation_random_seed: int = 0

@export_tool_button("Prepare Layers") var prepare_layers_action: Callable = prepare_layers
@export_tool_button("Generate Decorations") var generate_decorations_action: Callable = generate_decorations


static func get_packed_scene() -> PackedScene:
	return load("res://addons/brisklance/self/prefabs/tilemap_decorator.tscn") as PackedScene


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# RegionDefinition is a paint mask only - never meant to render in-game.
	if Utility.is_object_valid(node_region_definition):
		node_region_definition.visible = false


## Instantiates any of the 19 layer slots that are still unset, wires the
## node_<x> export to the new node, gives it the stacking z_index from
## LAYER_SPECS, and syncs each populated tileset_* export onto its category's
## Gen_/Overrider pair. Save the scene afterward so the wiring serializes
## (STATE.md gotcha R1).
func prepare_layers() -> void:
	if not Engine.is_editor_hint():
		return
	for spec: Dictionary in LAYER_SPECS:
		var property_name := spec["property"] as String
		if Utility.is_object_valid(get(property_name)):
			continue
		var node_name := spec["name"] as String
		# The export can go stale (e.g. an editor reload dropping its
		# NodePath override) while the node itself still exists - reuse it by
		# name instead of creating a same-named duplicate.
		var layer := find_child(node_name, false, false) as TileMapLayer
		if not Utility.is_object_valid(layer):
			layer = TileMapLayer.new()
			layer.name = node_name
			layer.z_index = spec["z_index"] as int
			layer.visible = spec["visible"] as bool
			# force_readable_name = true: if a same-named sibling still
			# collides for some other reason, Godot appends a readable
			# "Name 2" suffix instead of its anonymous internal unique name.
			add_child(layer, true)
			if Utility.is_object_valid(get_tree()):
				layer.owner = get_tree().edited_scene_root
		set(property_name, layer)

	for assignment: Dictionary in TILESET_ASSIGNMENTS:
		var tileset := get(assignment["tileset_property"] as String) as TileSet
		if not Utility.is_object_valid(tileset):
			continue
		for target_property: String in (assignment["targets"] as Array):
			var layer := get(target_property) as TileMapLayer
			if Utility.is_object_valid(layer):
				layer.tile_set = tileset


## Clears and rebuilds only the 9 Gen_* layers. node_region_definition and
## the 8 edge *_overrider layers + node_cover_overrider are read, never
## written.
func generate_decorations() -> void:
	if not Utility.is_object_valid(node_region_definition):
		return
	if (
		not Utility.is_object_valid(node_gen_back_top)
		or not Utility.is_object_valid(node_gen_back_bottom)
		or not Utility.is_object_valid(node_gen_back_left)
		or not Utility.is_object_valid(node_gen_back_right)
		or not Utility.is_object_valid(node_gen_front_top)
		or not Utility.is_object_valid(node_gen_front_bottom)
		or not Utility.is_object_valid(node_gen_front_left)
		or not Utility.is_object_valid(node_gen_front_right)
		or not Utility.is_object_valid(node_gen_cover)
	):
		return

	var mask: Dictionary = {}
	for cell: Vector2i in node_region_definition.get_used_cells():
		mask[cell] = true

	node_gen_back_top.clear()
	node_gen_back_bottom.clear()
	node_gen_back_left.clear()
	node_gen_back_right.clear()
	node_gen_front_top.clear()
	node_gen_front_bottom.clear()
	node_gen_front_left.clear()
	node_gen_front_right.clear()
	node_gen_cover.clear()

	var rng := RandomNumberGenerator.new()
	if generation_random_seed == 0:
		rng.randomize()
	else:
		rng.seed = generation_random_seed

	# Enumerated once per Gen_ layer (not per cell) - each Gen_* layer's own
	# assigned tile_set is the full candidate pool for every cell it applies
	# to, weighted by each tile's own `probability`.
	var back_top_pool := TilemapDecoratorTranslation.collect_tile_candidates(node_gen_back_top.tile_set)
	var back_bottom_pool := TilemapDecoratorTranslation.collect_tile_candidates(node_gen_back_bottom.tile_set)
	var back_left_pool := TilemapDecoratorTranslation.collect_tile_candidates(node_gen_back_left.tile_set)
	var back_right_pool := TilemapDecoratorTranslation.collect_tile_candidates(node_gen_back_right.tile_set)
	var front_top_pool := TilemapDecoratorTranslation.collect_tile_candidates(node_gen_front_top.tile_set)
	var front_bottom_pool := TilemapDecoratorTranslation.collect_tile_candidates(node_gen_front_bottom.tile_set)
	var front_left_pool := TilemapDecoratorTranslation.collect_tile_candidates(node_gen_front_left.tile_set)
	var front_right_pool := TilemapDecoratorTranslation.collect_tile_candidates(node_gen_front_right.tile_set)
	var cover_pool := TilemapDecoratorTranslation.collect_tile_candidates(node_gen_cover.tile_set)

	for cell: Vector2i in mask.keys():
		# Edge decorations frame the region from outside (a cliff-top tuft sits
		# above the cliff, not on its last inch of ground) - written at the
		# cell just outside the boundary, not the boundary cell itself.
		if TilemapDecoratorTranslation.is_top_edge(mask, cell):
			var outside_cell := TilemapDecoratorTranslation.top_outside_cell(cell)
			write_random_tile(outside_cell, node_back_top_overrider, node_gen_back_top, back_top_pool, sparseness_back_top, rng)
			write_random_tile(outside_cell, node_front_top_overrider, node_gen_front_top, front_top_pool, sparseness_front_top, rng)
		if TilemapDecoratorTranslation.is_bottom_edge(mask, cell):
			var outside_cell := TilemapDecoratorTranslation.bottom_outside_cell(cell)
			write_random_tile(outside_cell, node_back_bottom_overrider, node_gen_back_bottom, back_bottom_pool, sparseness_back_bottom, rng)
			write_random_tile(outside_cell, node_front_bottom_overrider, node_gen_front_bottom, front_bottom_pool, sparseness_front_bottom, rng)
		if TilemapDecoratorTranslation.is_left_edge(mask, cell):
			var outside_cell := TilemapDecoratorTranslation.left_outside_cell(cell)
			write_random_tile(outside_cell, node_back_left_overrider, node_gen_back_left, back_left_pool, sparseness_back_left, rng)
			write_random_tile(outside_cell, node_front_left_overrider, node_gen_front_left, front_left_pool, sparseness_front_left, rng)
		if TilemapDecoratorTranslation.is_right_edge(mask, cell):
			var outside_cell := TilemapDecoratorTranslation.right_outside_cell(cell)
			write_random_tile(outside_cell, node_back_right_overrider, node_gen_back_right, back_right_pool, sparseness_back_right, rng)
			write_random_tile(outside_cell, node_front_right_overrider, node_gen_front_right, front_right_pool, sparseness_front_right, rng)
		write_random_tile(cell, node_cover_overrider, node_gen_cover, cover_pool, sparseness_cover, rng)


## Writes one weighted-random p_pool candidate to p_gen_layer at p_cell,
## unless p_overrider already has a manual tile there or a p_sparseness roll
## leaves this cell empty.
func write_random_tile(
	p_cell: Vector2i,
	p_overrider: TileMapLayer,
	p_gen_layer: TileMapLayer,
	p_pool: Array[Dictionary],
	p_sparseness: float,
	p_rng: RandomNumberGenerator,
) -> void:
	if p_pool.is_empty():
		return
	if Utility.is_object_valid(p_overrider) and p_overrider.get_cell_source_id(p_cell) != -1:
		return
	if TilemapDecoratorTranslation.should_skip_for_sparseness(p_sparseness, p_rng.randf()):
		return
	var weights := TilemapDecoratorTranslation.candidate_weights(p_pool)
	var picked_index := TilemapDecoratorTranslation.pick_weighted_index(weights, p_rng.randf())
	if picked_index < 0:
		return
	var picked := p_pool[picked_index]
	p_gen_layer.set_cell(p_cell, picked["source_id"] as int, picked["atlas_coords"] as Vector2i, picked["alternative_id"] as int)

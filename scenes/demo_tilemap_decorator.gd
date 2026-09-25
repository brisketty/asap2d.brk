class_name TilemapDecoratorDemo
extends Node2D
## Visual harness for TileMapDecorator. The framework ships no tile art, so
## each of the 8 edge categories (Back/Front x Top/Bottom/Left/Right) plus
## Cover gets its own distinct code-built two-tone TileSet - the color
## identifies which Gen_ layer a tile came from, and each shade's own
## `TileData.probability` (70%/30%) shows the weighted pick in action. No
## ruleset resource is involved: TileMapDecorator reads candidates straight
## from each Gen_ layer's own assigned tile_set. A 10x6 region is painted on
## RegionDefinition and two cells are hand-placed on Overrider layers to
## demonstrate the non-destructive skip.

const TILE_SIZE := 64
const REGION_SIZE := Vector2i(10, 6)
const REGION_ORIGIN := Vector2i(-5, -3)
const OVERRIDE_MARKER_COLOR := Color(0.95, 0.10, 0.10)
const REGION_MARKER_COLOR := Color(0.5, 0.5, 0.5, 0.25)
const PRIMARY_SHADE_PROBABILITY := 0.7
const SECONDARY_SHADE_PROBABILITY := 0.3

## Two shades per category: [primary (70% weight), secondary (30% weight)].
## The color identifies the Gen_ layer; the two shades make the weighted pick
## visible across repeated "Generate Decorations" clicks.
const CATEGORY_COLORS := {
	"back_top": [Color(0.20, 0.45, 0.20), Color(0.14, 0.34, 0.14)],
	"back_bottom": [Color(0.45, 0.38, 0.15), Color(0.34, 0.28, 0.10)],
	"back_left": [Color(0.20, 0.30, 0.55), Color(0.14, 0.22, 0.42)],
	"back_right": [Color(0.15, 0.50, 0.48), Color(0.10, 0.38, 0.36)],
	"front_top": [Color(0.55, 0.75, 0.25), Color(0.42, 0.58, 0.18)],
	"front_bottom": [Color(0.75, 0.50, 0.20), Color(0.58, 0.38, 0.14)],
	"front_left": [Color(0.45, 0.20, 0.55), Color(0.34, 0.14, 0.42)],
	"front_right": [Color(0.75, 0.25, 0.55), Color(0.58, 0.18, 0.42)],
	"cover": [Color(0.85, 0.75, 0.20), Color(0.68, 0.58, 0.12)],
}

@export_group("Nodes", "node_")
@export var node_decorator: TileMapDecorator
@export var node_generate_button: BaseButton
@export var node_status_label: Label


static func get_packed_scene() -> PackedScene:
	return load("res://scenes/demo_tilemap_decorator.tscn") as PackedScene


func _ready() -> void:
	inject_demo_tilesets()
	paint_region_mask()
	paint_manual_overrides()
	node_generate_button.pressed.connect(handle_node_generate_button_pressed)
	generate_and_refresh()


## RegionDefinition and the 9 Overrider layers just need *a* tile to mark a
## cell occupied - a flat marker color is enough. Each Gen_ layer gets its
## own two-tone TileSet so its category and the weighted pick both read.
func inject_demo_tilesets() -> void:
	node_decorator.node_region_definition.tile_set = build_solid_tileset(REGION_MARKER_COLOR)
	node_decorator.node_back_top_overrider.tile_set = build_solid_tileset(OVERRIDE_MARKER_COLOR)
	node_decorator.node_back_bottom_overrider.tile_set = build_solid_tileset(OVERRIDE_MARKER_COLOR)
	node_decorator.node_back_left_overrider.tile_set = build_solid_tileset(OVERRIDE_MARKER_COLOR)
	node_decorator.node_back_right_overrider.tile_set = build_solid_tileset(OVERRIDE_MARKER_COLOR)
	node_decorator.node_front_top_overrider.tile_set = build_solid_tileset(OVERRIDE_MARKER_COLOR)
	node_decorator.node_front_bottom_overrider.tile_set = build_solid_tileset(OVERRIDE_MARKER_COLOR)
	node_decorator.node_front_left_overrider.tile_set = build_solid_tileset(OVERRIDE_MARKER_COLOR)
	node_decorator.node_front_right_overrider.tile_set = build_solid_tileset(OVERRIDE_MARKER_COLOR)
	node_decorator.node_cover_overrider.tile_set = build_solid_tileset(OVERRIDE_MARKER_COLOR)
	node_decorator.node_gen_back_top.tile_set = build_category_tileset("back_top")
	node_decorator.node_gen_back_bottom.tile_set = build_category_tileset("back_bottom")
	node_decorator.node_gen_back_left.tile_set = build_category_tileset("back_left")
	node_decorator.node_gen_back_right.tile_set = build_category_tileset("back_right")
	node_decorator.node_gen_front_top.tile_set = build_category_tileset("front_top")
	node_decorator.node_gen_front_bottom.tile_set = build_category_tileset("front_bottom")
	node_decorator.node_gen_front_left.tile_set = build_category_tileset("front_left")
	node_decorator.node_gen_front_right.tile_set = build_category_tileset("front_right")
	node_decorator.node_gen_cover.tile_set = build_category_tileset("cover")


func build_category_tileset(p_category: String) -> TileSet:
	var shades: Array = CATEGORY_COLORS[p_category]
	return build_two_tone_tileset(shades[0], shades[1])


func build_solid_tileset(p_color: Color) -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(p_color)
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(Vector2i(0, 0))
	tileset.add_source(source, 0)
	return tileset


## Each shade's TileData.probability is what TileMapDecorator's weighted pick
## actually reads - no ruleset resource involved.
func build_two_tone_tileset(p_color_a: Color, p_color_b: Color) -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	var image := Image.create(TILE_SIZE * 2, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(Vector2i(0, 0), Vector2i(TILE_SIZE, TILE_SIZE)), p_color_a)
	image.fill_rect(Rect2i(Vector2i(TILE_SIZE, 0), Vector2i(TILE_SIZE, TILE_SIZE)), p_color_b)
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))
	source.get_tile_data(Vector2i(0, 0), 0).probability = PRIMARY_SHADE_PROBABILITY
	source.get_tile_data(Vector2i(1, 0), 0).probability = SECONDARY_SHADE_PROBABILITY
	tileset.add_source(source, 0)
	return tileset


func paint_region_mask() -> void:
	var layer := node_decorator.node_region_definition
	for x: int in REGION_SIZE.x:
		for y: int in REGION_SIZE.y:
			layer.set_cell(REGION_ORIGIN + Vector2i(x, y), 0, Vector2i(0, 0))


## One cell just outside the top edge, and one interior cell, keep a
## hand-placed marker tile instead of a generated one - "Generate
## Decorations" must never touch them. Edge decorations write one cell
## outside the region (see TileMapDecorator's class doc), so the override
## has to sit there too to actually intercept generation.
func paint_manual_overrides() -> void:
	var top_outside_cell := REGION_ORIGIN + Vector2i(REGION_SIZE.x / 2, -1)
	node_decorator.node_front_top_overrider.set_cell(top_outside_cell, 0, Vector2i(0, 0))
	var interior_cell := REGION_ORIGIN + Vector2i(REGION_SIZE.x / 2, REGION_SIZE.y / 2)
	node_decorator.node_cover_overrider.set_cell(interior_cell, 0, Vector2i(0, 0))


func handle_node_generate_button_pressed() -> void:
	generate_and_refresh()


func generate_and_refresh() -> void:
	node_decorator.generate_decorations()
	refresh_status()


func refresh_status() -> void:
	if not Utility.is_object_valid(node_status_label):
		return
	node_status_label.text = "Gen — back T%d B%d L%d R%d | front T%d B%d L%d R%d | cover %d" % [
		node_decorator.node_gen_back_top.get_used_cells().size(),
		node_decorator.node_gen_back_bottom.get_used_cells().size(),
		node_decorator.node_gen_back_left.get_used_cells().size(),
		node_decorator.node_gen_back_right.get_used_cells().size(),
		node_decorator.node_gen_front_top.get_used_cells().size(),
		node_decorator.node_gen_front_bottom.get_used_cells().size(),
		node_decorator.node_gen_front_left.get_used_cells().size(),
		node_decorator.node_gen_front_right.get_used_cells().size(),
		node_decorator.node_gen_cover.get_used_cells().size(),
	]

class_name WorldDemo
extends Node2D
## Visual harness for the World & Environment subsystem. Buttons emit abstract
## biome.entered / biome.exited events; the subsystem swaps the active
## ThemeProfile and rebuilds its parallax rig, ambient particles and shader
## overlay from the biome-mapped asset ids. An AnimatedTileDriver swaps the
## ground TileSet the same way. The camera pans so parallax is visible.

const CAMERA_PAN_SPEED := 40.0
const TILE_SIZE := 64
const FLOOR_ROW := 6
const FLOOR_SPAN := 24

@export_group("Profiles", "profile_")
@export var profile_available: Array[ThemeProfile] = []

@export_group("Nodes", "node_")
@export var node_camera: Camera2D
@export var node_tilemap_layer: TileMapLayer
@export var node_forest_button: BaseButton
@export var node_cave_button: BaseButton
@export var node_exit_button: BaseButton


static func get_packed_scene() -> PackedScene:
	return load("res://scenes/demo_world.tscn") as PackedScene


func _ready() -> void:
	inject_demo_tilesets()
	ThemeManager.profile_available = profile_available
	node_forest_button.pressed.connect(handle_node_forest_button_pressed)
	node_cave_button.pressed.connect(handle_node_cave_button_pressed)
	node_exit_button.pressed.connect(handle_node_exit_button_pressed)


## The framework has no shipped tiles; give each biome profile a code-built
## TileSet keyed by `world.tiles` so the AnimatedTileDriver has something to swap.
func inject_demo_tilesets() -> void:
	var atlas_by_profile := {&"forest": Vector2i(0, 0), &"cave": Vector2i(1, 1)}
	for profile: ThemeProfile in profile_available:
		if not Utility.is_object_valid(profile):
			continue
		var atlas_coords: Vector2i = atlas_by_profile.get(profile.profile_id, Vector2i.ZERO)
		var tilesets := profile.tileset_assets
		tilesets[&"world.tiles"] = build_tileset(atlas_coords)
		profile.tileset_assets = tilesets


func build_tileset(p_tile_coords: Vector2i) -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = load("res://icon.svg")
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(p_tile_coords)
	tileset.add_source(source, 0)
	tileset.set_meta(&"demo_tile_coords", p_tile_coords)
	return tileset


func paint_floor() -> void:
	if not Utility.is_object_valid(node_tilemap_layer.tile_set):
		return
	var coords: Vector2i = node_tilemap_layer.tile_set.get_meta(&"demo_tile_coords", Vector2i.ZERO)
	for x: int in FLOOR_SPAN:
		node_tilemap_layer.set_cell(Vector2i(x - FLOOR_SPAN / 2, FLOOR_ROW), 0, coords)


func _process(p_delta: float) -> void:
	node_camera.position.x += CAMERA_PAN_SPEED * p_delta


func enter_biome(p_biome_id: StringName) -> void:
	EventBus.emit_semantic_event(
		EventIds.BIOME_ENTERED,
		Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.0, p_biome_id),
	)
	repaint_floor_for_active_tileset()


func repaint_floor_for_active_tileset() -> void:
	node_tilemap_layer.clear()
	paint_floor()


func handle_node_forest_button_pressed() -> void:
	enter_biome(&"forest")


func handle_node_cave_button_pressed() -> void:
	enter_biome(&"cave")


func handle_node_exit_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.BIOME_EXITED, {})

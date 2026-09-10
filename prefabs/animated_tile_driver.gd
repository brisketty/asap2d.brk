class_name AnimatedTileDriver
extends Node
## Opt-in per-biome tiles. Add as a child of a level scene, point
## `node_tilemap_layer` at a `TileMapLayer` and leave `tiles_tileset_asset_id`
## at its abstract default. Whenever the active ThemeProfile changes (a biome
## swap drives this via WorldEnvironment2D), the layer's `TileSet` is re-resolved
## and swapped - the cells stay, the look changes. Per-tile animation is defined
## in the `TileSet` itself; the engine advances it.

@export_group("Assets", "tiles_")
@export var tiles_tileset_asset_id: StringName = &"world.tiles"

@export_group("Nodes", "node_")
@export var node_tilemap_layer: TileMapLayer


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/animated_tile_driver.tscn") as PackedScene


func _ready() -> void:
	ThemeManager.active_profile_changed.connect(handle_active_profile_changed)
	apply_tileset()


func handle_active_profile_changed(_p_profile_id: StringName) -> void:
	apply_tileset()


func apply_tileset() -> void:
	if not Utility.is_object_valid(node_tilemap_layer):
		return
	var tileset := ThemeManager.resolve_tileset(tiles_tileset_asset_id)
	# Defensive: a missing tileset leaves the current one in place rather than
	# wiping the map.
	if Utility.is_object_valid(tileset):
		node_tilemap_layer.tile_set = tileset

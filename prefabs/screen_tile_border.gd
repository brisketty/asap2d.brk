class_name ScreenTileBorder
extends CanvasLayer
## A rebuildable border of tiled `Sprite2D`s around the four screen edges.
## `configure()` throws away the current tiles and rebuilds from a
## `ScreenTileSet` (null/empty -> no border, the defensive default). Driven by
## the Camera & Post-Processing subsystem, one instance below the state-grade
## shader and one above it (see `prefabs/camera_rig.tscn`).

var active_tile_set: ScreenTileSet
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/screen_tile_border.tscn") as PackedScene


func _ready() -> void:
	rng.randomize()
	get_viewport().size_changed.connect(handle_viewport_size_changed)


func configure(p_tile_set: ScreenTileSet) -> void:
	active_tile_set = p_tile_set
	rebuild()


func handle_viewport_size_changed() -> void:
	rebuild()


func rebuild() -> void:
	for child: Node in get_children():
		child.queue_free()
	if not Utility.is_object_valid(active_tile_set) or active_tile_set.tile_variations.is_empty():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var positions := ScreenTileTranslation.compute_border_tile_positions(
		viewport_size, active_tile_set.tile_size, active_tile_set.border_thickness_tiles
	)
	for position: Vector2 in positions:
		add_child(build_tile(position))


func build_tile(p_position: Vector2) -> Sprite2D:
	var variation_index := ScreenTileTranslation.pick_variation_index(
		active_tile_set.tile_variations.size(), rng.randf()
	)
	var texture := active_tile_set.tile_variations[variation_index]
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = p_position
	var texture_size := texture.get_size()
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		sprite.scale = Vector2(active_tile_set.tile_size) / texture_size
	return sprite

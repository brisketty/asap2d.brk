class_name ScreenTileBorder
extends CanvasLayer
## A rebuildable border of tiled `Sprite2D`s around the four screen edges.
## `configure()` swaps instantly; `fade_to()` alpha-crossfades via `node_root`'s
## modulate, same spirit as `ScreenShaderOverlay`. A null/empty `ScreenTileSet`
## is the defensive default (no border). Driven by the Camera & Post-Processing
## subsystem, one instance below the state-grade shader and one above it (see
## `prefabs/camera_rig.tscn`).

const DEFAULT_FADE_SECONDS := 0.35

@export_group("Nodes", "node_")
## Tiles are built under this node (not the `CanvasLayer` itself) because
## `CanvasLayer` has no `modulate` to fade.
@export var node_root: Node2D

var active_tile_set: ScreenTileSet
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var fade_tween: Tween


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/screen_tile_border.tscn") as PackedScene


func _ready() -> void:
	rng.randomize()
	get_viewport().size_changed.connect(handle_viewport_size_changed)


func configure(p_tile_set: ScreenTileSet) -> void:
	kill_fade()
	active_tile_set = p_tile_set
	if Utility.is_object_valid(node_root):
		node_root.modulate.a = 1.0
	rebuild()


## Alpha-crossfades to `p_tile_set` over `p_seconds`: the new set's tiles
## build immediately but fade in from transparent; a null/empty set fades the
## current tiles out, then clears them.
func fade_to(p_tile_set: ScreenTileSet, p_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	kill_fade()
	if not Utility.is_object_valid(node_root):
		return
	if not Utility.is_object_valid(p_tile_set) or p_tile_set.tile_variations.is_empty():
		fade_tween = create_tween()
		fade_tween.tween_property(node_root, "modulate:a", 0.0, p_seconds)
		fade_tween.tween_callback(clear_tiles)
		return
	active_tile_set = p_tile_set
	rebuild()
	node_root.modulate.a = 0.0
	fade_tween = create_tween()
	fade_tween.tween_property(node_root, "modulate:a", 1.0, p_seconds)


func clear_tiles() -> void:
	active_tile_set = null
	rebuild()


func handle_viewport_size_changed() -> void:
	rebuild()


func rebuild() -> void:
	if not Utility.is_object_valid(node_root):
		return
	for child: Node in node_root.get_children():
		child.queue_free()
	if not Utility.is_object_valid(active_tile_set) or active_tile_set.tile_variations.is_empty():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var positions := ScreenTileTranslation.compute_border_tile_positions(
		viewport_size, active_tile_set.tile_size, active_tile_set.border_thickness_tiles
	)
	for position: Vector2 in positions:
		node_root.add_child(build_tile(position))


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


func kill_fade() -> void:
	if Utility.is_object_valid(fade_tween):
		fade_tween.kill()

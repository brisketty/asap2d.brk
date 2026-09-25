class_name ParallaxRig
extends ParallaxBackground
## A rebuildable stack of parallax layers. `configure()` throws away the current
## layers and builds one `ParallaxLayer` (with a tiling `Sprite2D`) per supplied
## texture, farthest first. Driven by the World & Environment subsystem.

## `ParallaxLayer.motion_mirroring` only wraps a single sprite's position - it
## does not duplicate content - so the sprite itself must already cover an area
## at least as large as the viewport or gaps show through everywhere the single
## wrapped copy isn't. Repeat-tile each (typically much smaller) source texture
## across a region comfortably bigger than any expected viewport instead.
const MIN_TILE_COVERAGE := Vector2(2048.0, 2048.0)


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/parallax_rig.tscn") as PackedScene


func configure(p_textures: Array[Texture2D], p_scroll_scales: PackedFloat32Array) -> void:
	for child: Node in get_children():
		child.queue_free()
	for index: int in p_textures.size():
		var texture := p_textures[index]
		if not Utility.is_object_valid(texture):
			continue
		var scale_value := p_scroll_scales[index] if index < p_scroll_scales.size() else 1.0
		add_child(build_layer(texture, scale_value))


func build_layer(p_texture: Texture2D, p_scroll_scale: float) -> ParallaxLayer:
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(p_scroll_scale, p_scroll_scale)
	var coverage_size := build_coverage_size(p_texture.get_size())
	layer.motion_mirroring = coverage_size
	var sprite := Sprite2D.new()
	sprite.texture = p_texture
	sprite.centered = false
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, coverage_size)
	layer.add_child(sprite)
	return layer


## Rounds up to the nearest exact multiple of `p_tile_size` in each axis so the
## repeated texture tiles evenly across the coverage region - an inexact
## multiple would crop the last tile at the region's edge, and that crop would
## scroll into view every time `motion_mirroring` wraps the layer back through it.
func build_coverage_size(p_tile_size: Vector2) -> Vector2:
	return Vector2(
		ceilf(MIN_TILE_COVERAGE.x / p_tile_size.x) * p_tile_size.x,
		ceilf(MIN_TILE_COVERAGE.y / p_tile_size.y) * p_tile_size.y,
	)

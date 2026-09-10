class_name ParallaxRig
extends ParallaxBackground
## A rebuildable stack of parallax layers. `configure()` throws away the current
## layers and builds one `ParallaxLayer` (with a tiling `Sprite2D`) per supplied
## texture, farthest first. Driven by the World & Environment subsystem.


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
	layer.motion_mirroring = p_texture.get_size()
	var sprite := Sprite2D.new()
	sprite.texture = p_texture
	sprite.centered = false
	layer.add_child(sprite)
	return layer

class_name ScreenShaderOverlay
extends CanvasLayer
## A full-screen ShaderMaterial pass for god rays / heat haze / colour grade.
## `configure()` assigns the material and shows the rect; a null material hides
## it entirely (defensive defaulting).

@export_group("Nodes", "node_")
@export var node_rect: ColorRect


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/screen_shader_overlay.tscn") as PackedScene


func configure(p_shader_material: ShaderMaterial) -> void:
	if not Utility.is_object_valid(node_rect):
		return
	var has_material := Utility.is_object_valid(p_shader_material)
	node_rect.material = p_shader_material
	node_rect.visible = has_material

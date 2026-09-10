class_name ScreenShaderOverlay
extends CanvasLayer
## A full-screen ShaderMaterial pass for god rays / heat haze / colour grade /
## state vignette. `configure()` swaps instantly; `fade_to()` crossfades via the
## rect's alpha. A null material hides the rect entirely (defensive defaulting).

const DEFAULT_FADE_SECONDS := 0.35

@export_group("Nodes", "node_")
@export var node_rect: ColorRect

var fade_tween: Tween


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/screen_shader_overlay.tscn") as PackedScene


func configure(p_shader_material: ShaderMaterial) -> void:
	if not Utility.is_object_valid(node_rect):
		return
	kill_fade()
	var has_material := Utility.is_object_valid(p_shader_material)
	node_rect.material = p_shader_material
	node_rect.modulate.a = 1.0
	node_rect.visible = has_material


func fade_to(p_shader_material: ShaderMaterial, p_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	if not Utility.is_object_valid(node_rect):
		return
	kill_fade()
	if not Utility.is_object_valid(p_shader_material):
		fade_tween = create_tween()
		fade_tween.tween_property(node_rect, "modulate:a", 0.0, p_seconds)
		fade_tween.tween_callback(clear_material)
		return
	node_rect.material = p_shader_material
	node_rect.visible = true
	node_rect.modulate.a = 0.0
	fade_tween = create_tween()
	fade_tween.tween_property(node_rect, "modulate:a", 1.0, p_seconds)


func clear_material() -> void:
	if not Utility.is_object_valid(node_rect):
		return
	node_rect.visible = false
	node_rect.material = null


func kill_fade() -> void:
	if Utility.is_object_valid(fade_tween):
		fade_tween.kill()

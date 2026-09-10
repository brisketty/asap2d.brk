class_name CameraRig
extends Node2D
## The framework's camera. Owns the actual `Camera2D`, a trauma-driven shake, a
## zoom tween and a full-screen post-FX overlay. Gameplay registers what it
## follows via `CameraDirector.set_followed(node)`; the rig never discovers
## targets itself. Shake math lives in `CameraTranslation`.

@export_group("Shake", "shake_")
@export var shake_decay_per_second: float = 1.2
@export var shake_max_offset: Vector2 = Vector2(24.0, 16.0)
@export var shake_max_roll: float = 0.06
@export var shake_noise_speed: float = 34.0

@export_group("Nodes", "node_")
@export var node_camera: Camera2D
@export var node_post_fx: ScreenShaderOverlay

var followed: Node2D
var trauma: float = 0.0
var noise: FastNoiseLite = FastNoiseLite.new()
var noise_time: float = 0.0
var zoom_tween: Tween
var focus_tween: Tween
var is_focused: bool = false


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/camera_rig.tscn") as PackedScene


func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	set_process(true)


func _process(p_delta: float) -> void:
	if Utility.is_object_valid(followed) and not is_focused:
		global_position = followed.global_position
	apply_shake(p_delta)


func apply_shake(p_delta: float) -> void:
	if not Utility.is_object_valid(node_camera):
		return
	if trauma <= 0.0:
		node_camera.offset = Vector2.ZERO
		node_camera.rotation = 0.0
		return
	noise_time += p_delta * shake_noise_speed
	trauma = CameraTranslation.decay_trauma(trauma, shake_decay_per_second, p_delta)
	var noise_x := noise.get_noise_2d(noise_time, 0.0)
	var noise_y := noise.get_noise_2d(0.0, noise_time)
	var noise_r := noise.get_noise_2d(noise_time, noise_time)
	node_camera.offset = CameraTranslation.compute_offset(trauma, shake_max_offset, noise_x, noise_y)
	node_camera.rotation = CameraTranslation.compute_rotation(trauma, shake_max_roll, noise_r)


func add_trauma(p_amount: float) -> void:
	trauma = CameraTranslation.add_trauma(trauma, p_amount)


func set_followed(p_node: Node2D) -> void:
	followed = p_node
	if Utility.is_object_valid(p_node) and Utility.is_object_valid(node_camera):
		global_position = p_node.global_position
		node_camera.make_current()


func zoom_to(p_factor: float, p_seconds: float) -> void:
	if not Utility.is_object_valid(node_camera):
		return
	if Utility.is_object_valid(zoom_tween):
		zoom_tween.kill()
	var target := Vector2(p_factor, p_factor)
	zoom_tween = create_tween()
	zoom_tween.tween_property(node_camera, "zoom", target, p_seconds)


func focus_on(p_global_position: Vector2, p_seconds: float) -> void:
	is_focused = true
	if Utility.is_object_valid(focus_tween):
		focus_tween.kill()
	focus_tween = create_tween()
	focus_tween.tween_property(self, "global_position", p_global_position, p_seconds)


func clear_focus() -> void:
	is_focused = false


func set_post_fx(p_material: ShaderMaterial, p_seconds: float) -> void:
	if Utility.is_object_valid(node_post_fx):
		node_post_fx.fade_to(p_material, p_seconds)

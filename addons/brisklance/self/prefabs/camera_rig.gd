class_name CameraRig
extends Node2D
## The framework's camera. Owns the actual `Camera2D`, a trauma-driven shake, a
## zoom tween and a full-screen post-FX overlay. Gameplay registers what it
## follows via `CameraDirector.set_followed(node)`; the rig never discovers
## targets itself. Shake math lives in `CameraTranslation`.

@export_group("Nodes", "node_")
@export var node_camera: Camera2D
@export var node_post_fx: ScreenShaderOverlay
@export var node_tile_under: ScreenTileBorder
@export var node_tile_over: ScreenTileBorder

var followed: Node2D
var trauma: float = 0.0
var noise: FastNoiseLite = FastNoiseLite.new()
var noise_time: float = 0.0
var zoom_tween: Tween
var focus_tween: Tween
var is_focused: bool = false


static func get_packed_scene() -> PackedScene:
	return load("res://addons/brisklance/self/prefabs/camera_rig.tscn") as PackedScene


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
	noise_time += p_delta * Tuning.active_profile.camera_shake_noise_speed
	trauma = CameraTranslation.decay_trauma(trauma, Tuning.active_profile.camera_shake_decay_per_second, p_delta)
	var noise_x := noise.get_noise_2d(noise_time, 0.0)
	var noise_y := noise.get_noise_2d(0.0, noise_time)
	var noise_r := noise.get_noise_2d(noise_time, noise_time)
	node_camera.offset = CameraTranslation.compute_offset(
		trauma, Tuning.active_profile.camera_shake_max_offset, noise_x, noise_y, Tuning.active_profile.camera_shake_intensity_scale
	)
	node_camera.rotation = CameraTranslation.compute_rotation(
		trauma, Tuning.active_profile.camera_shake_max_roll, noise_r, Tuning.active_profile.camera_shake_intensity_scale
	)


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


## Pan to `p_global_position` and zoom to fit `p_region_size` (world-space)
## per `p_fit_mode` - the "show the boss arena" focus. Owns both the position
## and zoom tweens so it never fights `zoom_to`/`focus_on` (R4).
func focus_on_region(
	p_global_position: Vector2,
	p_region_size: Vector2,
	p_seconds: float,
	p_fit_mode: CameraTranslation.FocusFitMode = CameraTranslation.FocusFitMode.CENTERED,
) -> void:
	is_focused = true
	if Utility.is_object_valid(focus_tween):
		focus_tween.kill()
	if Utility.is_object_valid(zoom_tween):
		zoom_tween.kill()
	focus_tween = create_tween()
	focus_tween.set_parallel(true)
	focus_tween.tween_property(self, "global_position", p_global_position, p_seconds)
	if Utility.is_object_valid(node_camera):
		var target_zoom := CameraTranslation.compute_fit_zoom(
			get_viewport_rect().size, p_region_size, Tuning.active_profile.camera_fit_zoom_margin, p_fit_mode
		)
		focus_tween.tween_property(node_camera, "zoom", Vector2(target_zoom, target_zoom), p_seconds)


## Release back to following the registered target and tween the zoom back to
## normal - the counterpart to `focus_on_region`. Position releases with a hard
## snap next `_process` (same as the pre-existing point-focus release).
func clear_focus(p_seconds: float) -> void:
	is_focused = false
	if Utility.is_object_valid(focus_tween):
		focus_tween.kill()
	if Utility.is_object_valid(zoom_tween):
		zoom_tween.kill()
	if not Utility.is_object_valid(node_camera):
		return
	zoom_tween = create_tween()
	zoom_tween.tween_property(node_camera, "zoom", Vector2.ONE, p_seconds)


func set_post_fx(p_material: ShaderMaterial, p_seconds: float) -> void:
	if Utility.is_object_valid(node_post_fx):
		node_post_fx.fade_to(p_material, p_seconds)


## Optional tiled border art either side of the shader grade, alpha-crossfaded
## in/out over `p_seconds`. `null` clears a layer (the defensive default - no
## tiles).
func set_tile_border(p_under: ScreenTileSet, p_over: ScreenTileSet, p_seconds: float) -> void:
	if Utility.is_object_valid(node_tile_under):
		node_tile_under.fade_to(p_under, p_seconds)
	if Utility.is_object_valid(node_tile_over):
		node_tile_over.fade_to(p_over, p_seconds)

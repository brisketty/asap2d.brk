class_name CameraDemo
extends Node2D
## Visual harness for the Camera & Post-Processing subsystem. A wandering player
## is registered as the camera target; buttons emit the events that drive trauma
## shake, zoom and the state post-FX grade.

const WANDER_RADIUS := 140.0
const WANDER_SPEED := 1.1
const PLAYER_SOURCE_ID := &"player"

@export_group("Profiles", "profile_")
@export var profile_available: Array[ThemeProfile] = []

@export_group("Nodes", "node_")
@export var node_player: Node2D
@export var node_crit_button: BaseButton
@export var node_shake_button: BaseButton
@export var node_hurt_button: BaseButton
@export var node_clear_button: BaseButton
@export var node_zoom_in_button: BaseButton
@export var node_zoom_out_button: BaseButton

var wander_time: float = 0.0
var player_origin: Vector2


static func get_packed_scene() -> PackedScene:
	return load("res://scenes/demo_camera.tscn") as PackedScene


func _ready() -> void:
	ThemeManager.profile_available = profile_available
	if not profile_available.is_empty():
		ThemeManager.set_active_profile_by_id(profile_available[0].profile_id)
	player_origin = node_player.position
	CameraDirector.set_followed(node_player)
	node_crit_button.pressed.connect(handle_node_crit_button_pressed)
	node_shake_button.pressed.connect(handle_node_shake_button_pressed)
	node_hurt_button.pressed.connect(handle_node_hurt_button_pressed)
	node_clear_button.pressed.connect(handle_node_clear_button_pressed)
	node_zoom_in_button.pressed.connect(handle_node_zoom_in_button_pressed)
	node_zoom_out_button.pressed.connect(handle_node_zoom_out_button_pressed)


func _process(p_delta: float) -> void:
	wander_time += p_delta * WANDER_SPEED
	node_player.position = player_origin + Vector2(cos(wander_time), sin(wander_time * 0.7)) * WANDER_RADIUS


func handle_node_crit_button_pressed() -> void:
	EventBus.emit_semantic_event(
		EventIds.IMPACT_CRIT,
		Utility.make_spatial_context(node_player.global_position, Vector2.ZERO, 0.0, PLAYER_SOURCE_ID),
	)


func handle_node_shake_button_pressed() -> void:
	EventBus.emit_semantic_event(
		EventIds.CAMERA_SHAKE,
		Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.7),
	)


func handle_node_hurt_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.STATE_HURT, {})


func handle_node_clear_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.STATE_CLEAR, {})


func handle_node_zoom_in_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.CAMERA_ZOOM, Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 1.6))


func handle_node_zoom_out_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.CAMERA_ZOOM, Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 1.0))

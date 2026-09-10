class_name WorldDemo
extends Node2D
## Visual harness for the World & Environment subsystem. Buttons emit abstract
## biome.entered / biome.exited events; the subsystem swaps the active
## ThemeProfile and rebuilds its parallax rig, ambient particles and shader
## overlay from the biome-mapped asset ids. The camera pans so parallax is
## visible.

const CAMERA_PAN_SPEED := 40.0

@export_group("Profiles", "profile_")
@export var profile_available: Array[ThemeProfile] = []

@export_group("Nodes", "node_")
@export var node_camera: Camera2D
@export var node_forest_button: BaseButton
@export var node_cave_button: BaseButton
@export var node_exit_button: BaseButton


static func get_packed_scene() -> PackedScene:
	return load("res://scenes/demo_world.tscn") as PackedScene


func _ready() -> void:
	ThemeManager.profile_available = profile_available
	node_forest_button.pressed.connect(handle_node_forest_button_pressed)
	node_cave_button.pressed.connect(handle_node_cave_button_pressed)
	node_exit_button.pressed.connect(handle_node_exit_button_pressed)


func _process(p_delta: float) -> void:
	node_camera.position.x += CAMERA_PAN_SPEED * p_delta


func enter_biome(p_biome_id: StringName) -> void:
	EventBus.emit_semantic_event(
		EventIds.BIOME_ENTERED,
		Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.0, p_biome_id),
	)


func handle_node_forest_button_pressed() -> void:
	enter_biome(&"forest")


func handle_node_cave_button_pressed() -> void:
	enter_biome(&"cave")


func handle_node_exit_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.BIOME_EXITED, {})

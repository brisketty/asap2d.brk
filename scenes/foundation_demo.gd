class_name FoundationDemo
extends Node2D
## Visual harness for the A.S.A.P. foundation. Emits an abstract semantic event
## on a timer (and on click) and lets you swap ThemeProfiles at runtime to see
## the ThemeManager fallback ladder take over when art is missing.

const COMPLETE_PROFILE_ID := &"complete"
const SPARSE_PROFILE_ID := &"sparse"

@export_group("Profiles", "profile_")
@export var profile_available: Array[ThemeProfile] = []

@export_group("Nodes", "node_")
@export var node_emit_timer: Timer
@export var node_profile_button: BaseButton
@export var node_presenter: DemoImpactPresenter

var is_using_sparse_profile := false


static func get_packed_scene() -> PackedScene:
	return load("res://scenes/foundation_demo.tscn") as PackedScene


func _ready() -> void:
	node_emit_timer.timeout.connect(handle_node_emit_timer_timeout)
	node_profile_button.pressed.connect(handle_node_profile_button_pressed)
	ThemeManager.profile_available = profile_available
	ThemeManager.set_active_profile_by_id(COMPLETE_PROFILE_ID)


func _unhandled_input(p_event: InputEvent) -> void:
	var button_event := p_event as InputEventMouseButton
	if button_event == null or not button_event.pressed:
		return
	emit_impact(get_global_mouse_position())


func handle_node_emit_timer_timeout() -> void:
	emit_impact(get_global_mouse_position())


func handle_node_profile_button_pressed() -> void:
	is_using_sparse_profile = not is_using_sparse_profile
	var profile_id := SPARSE_PROFILE_ID if is_using_sparse_profile else COMPLETE_PROFILE_ID
	ThemeManager.set_active_profile_by_id(profile_id)
	node_profile_button.text = "Profile: %s" % profile_id


func emit_impact(p_global_position: Vector2) -> void:
	EventBus.emit_semantic_event(
		EventIds.IMPACT_BASIC,
		Utility.make_spatial_context(p_global_position),
	)

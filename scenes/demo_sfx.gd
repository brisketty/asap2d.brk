class_name SfxDemo
extends Node2D
## Visual harness for the Polyphonic Audio subsystem. Builds a code-only
## ThemeProfile of procedural tones for the default SFX route ids, then buttons
## emit the events. Rapid presses show the pool going polyphonic with per-voice
## pitch / volume randomisation.

@export_group("Nodes", "node_")
@export var node_light_button: BaseButton
@export var node_heavy_button: BaseButton
@export var node_hover_button: BaseButton
@export var node_burst_button: BaseButton


static func get_packed_scene() -> PackedScene:
	return load("res://scenes/demo_sfx.tscn") as PackedScene


func _ready() -> void:
	ThemeManager.profile_available = [build_tone_profile()]
	ThemeManager.set_active_profile_by_id(&"sfx_demo")
	node_light_button.pressed.connect(handle_node_light_button_pressed)
	node_heavy_button.pressed.connect(handle_node_heavy_button_pressed)
	node_hover_button.pressed.connect(handle_node_hover_button_pressed)
	node_burst_button.pressed.connect(handle_node_burst_button_pressed)


func build_tone_profile() -> ThemeProfile:
	var profile := ThemeProfile.new()
	profile.profile_id = &"sfx_demo"
	profile.audio_assets = {
		&"sfx.impact.light": ToneStream.make(720.0, 0.12),
		&"sfx.impact.heavy": ToneStream.make(180.0, 0.28),
		&"sfx.impact.crit": ToneStream.make(960.0, 0.16),
		&"sfx.ui.hover": ToneStream.make(1200.0, 0.05, 0.25),
		&"sfx.ui.confirm": ToneStream.make(880.0, 0.09, 0.3),
		&"sfx.ui.cancel": ToneStream.make(300.0, 0.09, 0.3),
	}
	return profile


func emit_at_random_point(p_event_id: StringName) -> void:
	var point := Vector2(randf_range(200.0, 950.0), randf_range(150.0, 500.0))
	EventBus.emit_semantic_event(p_event_id, Utility.make_spatial_context(point))


func handle_node_light_button_pressed() -> void:
	emit_at_random_point(EventIds.IMPACT_BASIC)


func handle_node_heavy_button_pressed() -> void:
	emit_at_random_point(EventIds.IMPACT_HEAVY)


func handle_node_hover_button_pressed() -> void:
	EventBus.emit_semantic_event(EventIds.UI_HOVER, {})


func handle_node_burst_button_pressed() -> void:
	for i: int in 8:
		emit_at_random_point(EventIds.IMPACT_BASIC)

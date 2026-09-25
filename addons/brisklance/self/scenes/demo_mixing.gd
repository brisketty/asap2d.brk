class_name MixingDemo
extends Node2D
## Visual harness for the Audio Bus / Mixing subsystem. "Play SFX" fires a
## repeating tone on the SFX bus; the biome buttons emit `biome.entered` so
## AudioMixing tweens that bus's reverb (and gains) toward a BusProfile. The UI
## click of the buttons themselves stays dry.

@export_group("Nodes", "node_")
@export var node_play_button: BaseButton
@export var node_cave_button: BaseButton
@export var node_hall_button: BaseButton
@export var node_dry_button: BaseButton
@export var node_hurt_button: BaseButton
@export var node_state_clear_button: BaseButton
@export var node_sfx_timer: Timer

var is_playing_sfx: bool = false


static func get_packed_scene() -> PackedScene:
	return load("res://addons/brisklance/self/scenes/demo_mixing.tscn") as PackedScene


func _ready() -> void:
	ThemeManager.profile_available = [build_profile()]
	ThemeManager.set_active_profile_by_id(&"mixing_demo")
	node_play_button.pressed.connect(handle_node_play_button_pressed)
	node_cave_button.pressed.connect(func() -> void: enter_biome(&"cave"))
	node_hall_button.pressed.connect(func() -> void: enter_biome(&"hall"))
	node_dry_button.pressed.connect(func() -> void: EventBus.emit_semantic_event(EventIds.BIOME_EXITED, {}))
	node_hurt_button.pressed.connect(func() -> void: EventBus.emit_semantic_event(EventIds.STATE_HURT, {}))
	node_state_clear_button.pressed.connect(func() -> void: EventBus.emit_semantic_event(EventIds.STATE_CLEAR, {}))
	node_sfx_timer.timeout.connect(handle_node_sfx_timer_timeout)


func build_profile() -> ThemeProfile:
	var profile := ThemeProfile.new()
	profile.profile_id = &"mixing_demo"
	profile.audio_assets = {&"sfx.impact.light": ToneStream.make(660.0, 0.14)}
	profile.bus_profile_assets = {
		&"cave": AudioMixingTranslation.make_profile(&"cave", -1.0, 0.0, 0.0, 0.4, 0.65),
		&"hall": AudioMixingTranslation.make_profile(&"hall", -2.0, 0.0, 1.0, 0.7, 0.95),
		&"state.hurt": AudioMixingTranslation.make_profile(&"state.hurt", -10.0, 0.0, 3.0, 0.1, 0.2),
	}
	return profile


func enter_biome(p_biome_id: StringName) -> void:
	EventBus.emit_semantic_event(
		EventIds.BIOME_ENTERED,
		Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.0, p_biome_id),
	)


func handle_node_play_button_pressed() -> void:
	is_playing_sfx = not is_playing_sfx
	if is_playing_sfx:
		node_sfx_timer.start()
	else:
		node_sfx_timer.stop()
	node_play_button.text = "Stop SFX" if is_playing_sfx else "Play SFX (loop)"


func handle_node_sfx_timer_timeout() -> void:
	var point := Vector2(randf_range(300.0, 850.0), randf_range(200.0, 450.0))
	EventBus.emit_semantic_event(EventIds.IMPACT_BASIC, Utility.make_spatial_context(point))

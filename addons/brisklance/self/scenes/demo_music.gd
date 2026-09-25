class_name MusicDemo
extends Node2D
## Visual harness for the BGM & Ambience subsystem. Buttons emit music.* /
## biome.* events; a code-built ThemeProfile supplies looping procedural tones
## for each theme's stems, the biome ambience beds and a stinger.

@export_group("Nodes", "node_")
@export var node_forest_button: BaseButton
@export var node_cave_button: BaseButton
@export var node_tension_slider: Range
@export var node_stinger_button: BaseButton
@export var node_forest_ambience_button: BaseButton
@export var node_stop_ambience_button: BaseButton
@export var node_lowhealth_button: BaseButton
@export var node_state_clear_button: BaseButton


static func get_packed_scene() -> PackedScene:
	return load("res://addons/brisklance/self/scenes/demo_music.tscn") as PackedScene


func _ready() -> void:
	ThemeManager.profile_available = [build_score_profile()]
	ThemeManager.set_active_profile_by_id(&"score_demo")
	node_forest_button.pressed.connect(func() -> void: emit_theme(&"forest"))
	node_cave_button.pressed.connect(func() -> void: emit_theme(&"cave"))
	node_tension_slider.value_changed.connect(handle_tension_changed)
	node_stinger_button.pressed.connect(func() -> void: emit_stinger(&"reveal"))
	node_forest_ambience_button.pressed.connect(func() -> void: emit_biome(&"forest"))
	node_stop_ambience_button.pressed.connect(func() -> void: EventBus.emit_semantic_event(EventIds.BIOME_EXITED, {}))
	node_lowhealth_button.pressed.connect(func() -> void: EventBus.emit_semantic_event(EventIds.STATE_LOWHEALTH, {}))
	node_state_clear_button.pressed.connect(func() -> void: EventBus.emit_semantic_event(EventIds.STATE_CLEAR, {}))


func build_score_profile() -> ThemeProfile:
	var profile := ThemeProfile.new()
	profile.profile_id = &"score_demo"
	profile.music_assets = {
		&"forest.0": ToneStream.make(110.0, 2.0, 0.4, true),
		&"forest.1": ToneStream.make(220.0, 2.0, 0.3, true),
		&"forest.2": ToneStream.make(330.0, 2.0, 0.22, true),
		&"cave.0": ToneStream.make(82.0, 2.0, 0.45, true),
		&"cave.1": ToneStream.make(146.0, 2.0, 0.3, true),
		&"cave.2": ToneStream.make(196.0, 2.0, 0.22, true),
		&"ambience.forest": ToneStream.make(60.0, 2.0, 0.15, true),
		&"stinger.reveal": ToneStream.make(880.0, 0.4, 0.4),
	}
	return profile


func emit_theme(p_theme_id: StringName) -> void:
	EventBus.emit_semantic_event(EventIds.MUSIC_THEME, Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.0, p_theme_id))


func emit_stinger(p_stinger_id: StringName) -> void:
	EventBus.emit_semantic_event(EventIds.MUSIC_STINGER, Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.0, p_stinger_id))


func emit_biome(p_biome_id: StringName) -> void:
	EventBus.emit_semantic_event(EventIds.BIOME_ENTERED, Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, 0.0, p_biome_id))


func handle_tension_changed(p_value: float) -> void:
	EventBus.emit_semantic_event(EventIds.MUSIC_TENSION, Utility.make_spatial_context(Vector2.ZERO, Vector2.ZERO, p_value))

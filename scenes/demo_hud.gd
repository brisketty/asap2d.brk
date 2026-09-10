class_name HudDemo
extends Node2D
## Visual harness for the UI & HUD Polish subsystem. Damage buttons emit
## `damage.*` events (pooled floating numbers appear near the focus point); bar
## buttons push ratios to a CatchUpBar; the crit button carries a HoverPop.

const PLAYER_BAR_ID := &"player_hp"

@export_group("Profiles", "profile_")
@export var profile_available: Array[ThemeProfile] = []

@export_group("Nodes", "node_")
@export var node_focus: Node2D
@export var node_bar: CatchUpBar
@export var node_hit_button: BaseButton
@export var node_crit_button: BaseButton
@export var node_heal_button: BaseButton
@export var node_bar_hit_button: BaseButton
@export var node_bar_heal_button: BaseButton

var bar_ratio: float = 1.0


static func get_packed_scene() -> PackedScene:
	return load("res://scenes/demo_hud.tscn") as PackedScene


func _ready() -> void:
	ThemeManager.profile_available = profile_available
	if not profile_available.is_empty():
		ThemeManager.set_active_profile_by_id(profile_available[0].profile_id)
	CameraDirector.set_followed(node_focus)
	HudPolish.register_bar(PLAYER_BAR_ID, node_bar)
	node_hit_button.pressed.connect(handle_node_hit_button_pressed)
	node_crit_button.pressed.connect(handle_node_crit_button_pressed)
	node_heal_button.pressed.connect(handle_node_heal_button_pressed)
	node_bar_hit_button.pressed.connect(handle_node_bar_hit_button_pressed)
	node_bar_heal_button.pressed.connect(handle_node_bar_heal_button_pressed)


func emit_damage(p_event_id: StringName, p_magnitude: float) -> void:
	var jitter := Vector2(randf_range(-48.0, 48.0), randf_range(-24.0, 24.0))
	EventBus.emit_semantic_event(
		p_event_id,
		Utility.make_spatial_context(node_focus.global_position + jitter, Vector2.ZERO, p_magnitude),
	)


func handle_node_hit_button_pressed() -> void:
	emit_damage(EventIds.DAMAGE_DEALT, 8.0)


func handle_node_crit_button_pressed() -> void:
	emit_damage(EventIds.DAMAGE_DEALT, 33.0)


func handle_node_heal_button_pressed() -> void:
	emit_damage(EventIds.DAMAGE_HEALED, 12.0)


func handle_node_bar_hit_button_pressed() -> void:
	bar_ratio = maxf(bar_ratio - 0.2, 0.0)
	node_bar.set_ratio(bar_ratio)


func handle_node_bar_heal_button_pressed() -> void:
	bar_ratio = minf(bar_ratio + 0.15, 1.0)
	node_bar.set_ratio(bar_ratio)

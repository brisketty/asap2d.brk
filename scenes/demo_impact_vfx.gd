class_name ImpactVfxDemo
extends Node2D
## Visual harness for the Impact & Combat VFX subsystem. Buttons emit abstract
## impact.* / combat.knockback events at a dummy target that carries opt-in
## HitFlash, SquashStretch and KnockbackReceiver components. The subsystem
## autoload turns the same events into pooled particle bursts and hit-stop.

const TARGET_SOURCE_ID := &"dummy"

@export_group("Profiles", "profile_")
@export var profile_available: Array[ThemeProfile] = []

@export_group("Nodes", "node_")
@export var node_target: Node2D
@export var node_basic_button: BaseButton
@export var node_heavy_button: BaseButton
@export var node_crit_button: BaseButton
@export var node_knockback_button: BaseButton


static func get_packed_scene() -> PackedScene:
	return load("res://scenes/demo_impact_vfx.tscn") as PackedScene


func _ready() -> void:
	ThemeManager.profile_available = profile_available
	if not profile_available.is_empty():
		ThemeManager.set_active_profile_by_id(profile_available[0].profile_id)
	node_basic_button.pressed.connect(handle_node_basic_button_pressed)
	node_heavy_button.pressed.connect(handle_node_heavy_button_pressed)
	node_crit_button.pressed.connect(handle_node_crit_button_pressed)
	node_knockback_button.pressed.connect(handle_node_knockback_button_pressed)
	CameraDirector.set_followed(node_target)


func emit_impact(p_event_id: StringName, p_magnitude: float) -> void:
	var context := Utility.make_spatial_context(
		node_target.global_position,
		Vector2.from_angle(randf() * TAU),
		p_magnitude,
		TARGET_SOURCE_ID,
	)
	EventBus.emit_semantic_event(p_event_id, context)


func handle_node_basic_button_pressed() -> void:
	emit_impact(EventIds.IMPACT_BASIC, 6.0)


func handle_node_heavy_button_pressed() -> void:
	emit_impact(EventIds.IMPACT_HEAVY, 14.0)


func handle_node_crit_button_pressed() -> void:
	emit_impact(EventIds.IMPACT_CRIT, 24.0)


func handle_node_knockback_button_pressed() -> void:
	emit_impact(EventIds.COMBAT_KNOCKBACK, 64.0)

class_name KnockbackReceiver
extends Node
## Opt-in knockback. Add as a child of an entity scene, point `node_target` at
## the Node2D to shove and set `knockback_source_id` to the entity's abstract id.
## On a `combat.knockback` event whose context `source_id` matches, the target
## lurches along `context.direction` by `context.magnitude` and eases back.
##
## Logic code stays pure: it emits the abstract knockback intent; this component
## is one way to render it. Entity movement code may instead read the same
## context and apply real velocity.

@export_group("Knockback", "knockback_")
@export var knockback_source_id: StringName

@export_group("Nodes", "node_")
@export var node_target: Node2D

var knockback_tween: Tween


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/knockback_receiver.tscn") as PackedScene


func _ready() -> void:
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	if p_event_id != EventIds.COMBAT_KNOCKBACK:
		return
	if p_context.get(Utility.CONTEXT_SOURCE_ID_KEY, &"") != knockback_source_id:
		return
	if not Utility.is_object_valid(node_target):
		return
	var direction: Vector2 = p_context.get(Utility.CONTEXT_DIRECTION_KEY, Vector2.ZERO)
	var magnitude: float = p_context.get(Utility.CONTEXT_MAGNITUDE_KEY, 0.0)
	apply_knockback(direction * magnitude * Tuning.active_profile.vfx_knockback_strength)


func apply_knockback(p_offset: Vector2) -> void:
	if Utility.is_object_valid(knockback_tween):
		knockback_tween.kill()
	var origin := node_target.position
	knockback_tween = create_tween()
	knockback_tween.tween_property(node_target, "position", origin + p_offset, Tuning.active_profile.vfx_knockback_lurch_seconds)
	knockback_tween.tween_property(node_target, "position", origin, Tuning.active_profile.vfx_knockback_recover_seconds) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

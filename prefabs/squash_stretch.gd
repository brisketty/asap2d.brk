class_name SquashStretch
extends Node
## Opt-in squash & stretch. Add as a child of an entity scene, point
## `node_target` at the Node2D to deform and set `squash_source_id`. On a
## matching `impact.*` or `combat.knockback` event the target squashes wide-and-
## flat, then springs back to its original scale.

@export_group("Squash", "squash_")
@export var squash_source_id: StringName
@export var squash_event_prefixes: PackedStringArray = ["impact.", "combat.knockback"]
## 0.25 => squashes to 125% wide, 75% tall.
@export var squash_amount: float = 0.25
@export var squash_in_seconds: float = 0.06
@export var squash_out_seconds: float = 0.22

@export_group("Nodes", "node_")
@export var node_target: Node2D

var base_scale: Vector2 = Vector2.ONE
var squash_tween: Tween


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/squash_stretch.tscn") as PackedScene


func _ready() -> void:
	if Utility.is_object_valid(node_target):
		base_scale = node_target.scale
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	if not event_id_matches(p_event_id):
		return
	if p_context.get(Utility.CONTEXT_SOURCE_ID_KEY, &"") != squash_source_id:
		return
	squash()


func event_id_matches(p_event_id: StringName) -> bool:
	var event_id := String(p_event_id)
	for prefix: String in squash_event_prefixes:
		if event_id.begins_with(prefix):
			return true
	return false


func squash() -> void:
	if not Utility.is_object_valid(node_target):
		return
	if Utility.is_object_valid(squash_tween):
		squash_tween.kill()
	var squashed := Vector2(base_scale.x * (1.0 + squash_amount), base_scale.y * (1.0 - squash_amount))
	squash_tween = create_tween()
	squash_tween.tween_property(node_target, "scale", squashed, squash_in_seconds)
	squash_tween.tween_property(node_target, "scale", base_scale, squash_out_seconds) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

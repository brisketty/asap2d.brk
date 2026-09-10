class_name HoverPop
extends Node
## Opt-in hover feedback. Add as a child of a Control, point `node_target` at it
## (or a parent), and it pops on mouse-enter and emits a `ui.hover` semantic
## event. Standalone - no HUD subsystem needed for the pop itself.

@export_group("Hover", "hover_")
## Emitted on the Event Bus when the target is hovered (for SFX etc.). Empty to
## stay silent.
@export var hover_event_id: StringName = &"ui.hover"

@export_group("Nodes", "node_")
@export var node_target: Control


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/hover_pop.tscn") as PackedScene


func _ready() -> void:
	if not Utility.is_object_valid(node_target):
		return
	node_target.mouse_entered.connect(handle_target_mouse_entered)


func handle_target_mouse_entered() -> void:
	if not Utility.is_object_valid(node_target):
		return
	Tweens.pop(node_target)
	if hover_event_id != &"":
		EventBus.emit_semantic_event(hover_event_id, {})

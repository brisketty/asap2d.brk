class_name HitFlash
extends Node
## Opt-in hit-flash. Add as a child of an entity scene, point `node_target` at a
## CanvasItem and set `flash_source_id` to the entity's abstract id. On any
## `impact.*` event whose context `source_id` matches, the target briefly
## brightens.
##
## Phase 1 uses a `modulate` pulse (always works, no shader). A shader-material
## flash via `flash_shader_asset_id` + ThemeManager.resolve_shader is a Phase 2
## upgrade; a missing shader will stay a no-op over the modulate fallback.

const IMPACT_NAMESPACE := "impact."
const FLASH_MODULATE := Color(3.0, 3.0, 3.0, 1.0)

@export_group("Flash", "flash_")
@export var flash_source_id: StringName
@export var flash_duration: float = 0.12
@export var flash_shader_asset_id: StringName

@export_group("Nodes", "node_")
@export var node_target: CanvasItem

var base_modulate: Color = Color.WHITE
var flash_tween: Tween


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/hit_flash.tscn") as PackedScene


func _ready() -> void:
	if Utility.is_object_valid(node_target):
		base_modulate = node_target.modulate
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	if not String(p_event_id).begins_with(IMPACT_NAMESPACE):
		return
	if p_context.get(Utility.CONTEXT_SOURCE_ID_KEY, &"") != flash_source_id:
		return
	flash()


func flash() -> void:
	if not Utility.is_object_valid(node_target):
		return
	if Utility.is_object_valid(flash_tween):
		flash_tween.kill()
	node_target.modulate = FLASH_MODULATE
	flash_tween = create_tween()
	flash_tween.tween_property(node_target, "modulate", base_modulate, flash_duration)

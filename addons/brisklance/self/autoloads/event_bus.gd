extends Node
## The Global Event Bus. Registered as the `EventBus` autoload singleton (no
## `class_name` so it does not collide with the autoload identifier). Pure logic communicates ONLY through this node by
## broadcasting abstract string ids plus spatial data - it never references
## visual nodes, audio streams, or UI. Presentation managers connect to
## `semantic_event_emitted` in their `_ready()` and translate.
##
## The `p_context` Dictionary follows `Utility.make_spatial_context`:
##   position:  Vector2   - where the event happened (global space)
##   direction: Vector2   - unit direction, e.g. knockback / facing
##   magnitude: float     - abstract intensity (damage, force, ...)
##   source_id: StringName - abstract id of the emitter
## Additional keys are allowed; consumers must tolerate their absence.

signal semantic_event_emitted(p_event_id: StringName, p_context: Dictionary)


## Broadcast an abstract semantic event. `p_event_id` is a namespaced string id
## such as `&"impact.basic"` or `&"biome.entered"`.
func emit_semantic_event(p_event_id: StringName, p_context: Dictionary = {}) -> void:
	assert(p_event_id != &"", "EventBus semantic events require a non-empty id.")
	semantic_event_emitted.emit(p_event_id, p_context)

class_name Utility
## Standalone helpers for the A.S.A.P. Framework. Does not extend Node.

## Reserved keys carried by every EventBus semantic-event context Dictionary.
const CONTEXT_POSITION_KEY := &"position"
const CONTEXT_DIRECTION_KEY := &"direction"
const CONTEXT_MAGNITUDE_KEY := &"magnitude"
const CONTEXT_SOURCE_ID_KEY := &"source_id"
## World-space extents of a region of interest (e.g. `camera.focus` zoom-to-fit).
const CONTEXT_SIZE_KEY := &"size"


## Objects can be freed or queued for deletion while remaining non-null, so a
## bare null check is never enough (see CLAUDE.md 2B). The parameter is Variant,
## not Object, so a dangling reference can be passed in without tripping the
## runtime argument type check.
static func is_object_valid(p_object: Variant) -> bool:
	if not (p_object is Object):
		return false
	var object := p_object as Object
	if not is_instance_valid(object):
		return false
	if object is Node and (object as Node).is_queued_for_deletion():
		return false
	return true


## Canonical shape of an EventBus semantic-event context. Pure logic fills this
## with abstract spatial data; presentation managers read it back.
static func make_spatial_context(
	p_position: Vector2,
	p_direction: Vector2 = Vector2.ZERO,
	p_magnitude: float = 0.0,
	p_source_id: StringName = &"",
) -> Dictionary:
	return {
		CONTEXT_POSITION_KEY: p_position,
		CONTEXT_DIRECTION_KEY: p_direction,
		CONTEXT_MAGNITUDE_KEY: p_magnitude,
		CONTEXT_SOURCE_ID_KEY: p_source_id,
	}


## Context shape for a "frame this whole area" request (`camera.focus` with a
## size, driving `CameraRig.focus_on_region`'s zoom-to-fit).
static func make_region_context(
	p_position: Vector2,
	p_size: Vector2,
	p_source_id: StringName = &"",
) -> Dictionary:
	return {
		CONTEXT_POSITION_KEY: p_position,
		CONTEXT_SIZE_KEY: p_size,
		CONTEXT_SOURCE_ID_KEY: p_source_id,
	}

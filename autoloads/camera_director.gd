class_name CameraDirectorSubsystem
extends Node
## Camera & Post-Processing. Registered as the `CameraDirector` autoload.
##
## Owns a `CameraRig` (the framework's `Camera2D` + shake + zoom + post-FX
## overlay). Gameplay calls `CameraDirector.set_followed(node)` to say what the
## camera tracks. Semantic events drive trauma shake, zoom, focus and
## state-driven post-processing grades.
##
## Pure math / table lookup lives in `CameraTranslation`.

const ZOOM_TWEEN_SECONDS := 0.35
const FOCUS_TWEEN_SECONDS := 0.5
const POST_FX_FADE_SECONDS := 0.4

@export_group("Trauma", "trauma_")
## Leave empty to use `CameraTranslation.build_default_trauma_table()`.
@export var trauma_table: Array[CameraTrauma] = []

var camera_rig: CameraRig
var trauma_by_event_id: Dictionary = {}
var active_state_id: StringName = &""


func _ready() -> void:
	rebuild_trauma_lookup()
	camera_rig = CameraRig.get_packed_scene().instantiate()
	add_child(camera_rig)
	EventBus.semantic_event_emitted.connect(handle_semantic_event_emitted)


func rebuild_trauma_lookup() -> void:
	var table := trauma_table
	if table.is_empty():
		table = CameraTranslation.build_default_trauma_table()
	trauma_by_event_id = CameraTranslation.build_lookup(table)


## Register the node the camera should track. `null` stops following.
func set_followed(p_node: Node2D) -> void:
	if Utility.is_object_valid(camera_rig):
		camera_rig.set_followed(p_node)


func handle_semantic_event_emitted(p_event_id: StringName, p_context: Dictionary) -> void:
	if not Utility.is_object_valid(camera_rig):
		return

	var table_trauma := CameraTranslation.resolve_trauma(trauma_by_event_id, p_event_id)
	if table_trauma > 0.0:
		camera_rig.add_trauma(table_trauma)

	match p_event_id:
		EventIds.CAMERA_SHAKE:
			camera_rig.add_trauma(float(p_context.get(Utility.CONTEXT_MAGNITUDE_KEY, 0.0)))
		EventIds.CAMERA_ZOOM:
			camera_rig.zoom_to(float(p_context.get(Utility.CONTEXT_MAGNITUDE_KEY, 1.0)), ZOOM_TWEEN_SECONDS)
		EventIds.CAMERA_FOCUS:
			handle_camera_focus(p_context)
		EventIds.STATE_CLEAR:
			active_state_id = &""
			camera_rig.set_post_fx(null, POST_FX_FADE_SECONDS)
			camera_rig.set_tile_border(null, null)
		EventIds.STATE_HURT, EventIds.STATE_LOWHEALTH, EventIds.STATE_PAUSED:
			active_state_id = p_event_id
			camera_rig.set_post_fx(ThemeManager.resolve_post_fx(p_event_id), POST_FX_FADE_SECONDS)
			camera_rig.set_tile_border(
				ThemeManager.resolve_screen_tile(p_event_id),
				ThemeManager.resolve_screen_tile(StringName(String(p_event_id) + ".over")),
			)


func handle_camera_focus(p_context: Dictionary) -> void:
	if p_context.has(Utility.CONTEXT_SIZE_KEY):
		camera_rig.focus_on_region(
			p_context[Utility.CONTEXT_POSITION_KEY],
			p_context[Utility.CONTEXT_SIZE_KEY],
			FOCUS_TWEEN_SECONDS,
		)
		return
	if p_context.has(Utility.CONTEXT_POSITION_KEY):
		camera_rig.focus_on(p_context[Utility.CONTEXT_POSITION_KEY], FOCUS_TWEEN_SECONDS)
		return
	camera_rig.clear_focus(FOCUS_TWEEN_SECONDS)

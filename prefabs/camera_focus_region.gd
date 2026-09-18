class_name CameraFocusRegion
extends Node2D
## Marks a region of interest in a scene - e.g. a boss arena. When
## `node_watched` (usually the followed player) enters the rectangle centered
## on this node and sized `region_size`, it emits `camera.focus` with a
## region context so `CameraDirector` tweens the camera to frame the whole
## area; leaving the rectangle releases the focus back to following
## `node_watched` at normal zoom.
##
## Detection is a plain position check (`CameraTranslation.is_point_in_region`)
## against `node_watched.global_position` - no physics bodies or collision
## layers required, consistent with the rest of the framework.

const IDLE_COLOR := Color(0.3, 0.75, 1.0, 0.6)
const ACTIVE_COLOR := Color(1.0, 0.65, 0.15, 0.9)
const BORDER_WIDTH := 3.0

@export_group("Region", "region_")
@export var region_size: Vector2 = Vector2(640.0, 360.0)
## Draw the region's bounds as an outline - handy for a boss arena laid out in
## the editor. Purely visual; detection works either way.
@export var region_debug_draw: bool = true

@export_group("Nodes", "node_")
@export var node_watched: Node2D

var is_watched_inside: bool = false


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/camera_focus_region.tscn") as PackedScene


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(p_delta: float) -> void:
	if not Utility.is_object_valid(node_watched):
		return
	var inside := CameraTranslation.is_point_in_region(node_watched.global_position, global_position, region_size)
	if inside == is_watched_inside:
		return
	is_watched_inside = inside
	queue_redraw()
	if inside:
		EventBus.emit_semantic_event(EventIds.CAMERA_FOCUS, Utility.make_region_context(global_position, region_size))
		return
	EventBus.emit_semantic_event(EventIds.CAMERA_FOCUS, {})


func _draw() -> void:
	if not region_debug_draw:
		return
	var rect := Rect2(-region_size * 0.5, region_size)
	var color := ACTIVE_COLOR if is_watched_inside else IDLE_COLOR
	draw_rect(rect, color, false, BORDER_WIDTH)

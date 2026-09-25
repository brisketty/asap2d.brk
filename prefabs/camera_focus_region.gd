class_name CameraFocusRegion
extends Node2D
## Marks a region of interest in a scene - e.g. a boss arena. When
## `node_watched` (usually the followed player) enters the rectangle read from
## `node_shape` (a `RectangleShape2D`, centered on this node), it emits
## `camera.focus` with a region context so `CameraDirector` tweens the camera
## to frame the whole area; leaving the rectangle releases the focus back to
## following `node_watched` at normal zoom.
##
## The rectangle's extent is authored visually: `node_shape` is a
## `CollisionShape2D` under a non-monitoring `Area2D` child (`prefabs/
## camera_focus_region.tscn`'s "Region"/"Shape" nodes) purely to get Godot's
## built-in rectangle-shape editor gizmo (drag handles in the 2D viewport). No
## physics query runs - detection is still a plain position check
## (`CameraTranslation.is_point_in_region`) against `node_watched.global_position`.

@export_group("Region", "region_")
## Draw the region's bounds as an outline - handy for a boss arena laid out in
## the editor. Purely visual; detection works either way.
@export var region_debug_draw: bool = true

@export_group("Nodes", "node_")
@export var node_watched: Node2D
## The `CollisionShape2D` (holding a `RectangleShape2D`) whose gizmo defines
## the region's extent. Never queried for physics - shape data only.
@export var node_shape: CollisionShape2D

var is_watched_inside: bool = false


static func get_packed_scene() -> PackedScene:
	return load("res://prefabs/camera_focus_region.tscn") as PackedScene


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(p_delta: float) -> void:
	if not Utility.is_object_valid(node_watched):
		return
	var region_size := get_region_size()
	var inside := CameraTranslation.is_point_in_region(node_watched.global_position, global_position, region_size)
	if inside == is_watched_inside:
		return
	is_watched_inside = inside
	queue_redraw()
	if inside:
		EventBus.emit_semantic_event(EventIds.CAMERA_FOCUS, Utility.make_region_context(global_position, region_size))
		return
	EventBus.emit_semantic_event(EventIds.CAMERA_FOCUS, {})


## World-space size of the region rectangle, read from `node_shape`'s
## `RectangleShape2D` (falls back to `Tuning.active_profile.camera_focus_default_region_size` if unwired).
func get_region_size() -> Vector2:
	if not Utility.is_object_valid(node_shape):
		return Tuning.active_profile.camera_focus_default_region_size
	var rectangle_shape := node_shape.shape as RectangleShape2D
	if not Utility.is_object_valid(rectangle_shape):
		return Tuning.active_profile.camera_focus_default_region_size
	return rectangle_shape.size * node_shape.scale


func _draw() -> void:
	if not region_debug_draw:
		return
	var region_size := get_region_size()
	var rect := Rect2(-region_size * 0.5, region_size)
	var color := Tuning.active_profile.camera_focus_active_color if is_watched_inside else Tuning.active_profile.camera_focus_idle_color
	draw_rect(rect, color, false, Tuning.active_profile.camera_focus_border_width)
